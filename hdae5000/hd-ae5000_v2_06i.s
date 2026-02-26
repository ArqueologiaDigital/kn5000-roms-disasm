
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
	; Input: A = byte to transfer. Returns: L = 0x00 on match, 0xFF on mismatch
	; --- Low nibble phase ---
	ld l, a				; save original byte
	and a, 0x0f			; mask low nibble
	set 4, a			; set bit 4 (data strobe)
	sll a, 3			; shift left 3
	stda8_24 1441794, a		; ld (0x160002), A — PPI port B
	ld c, a				; save port B value
	srl c, 6			; shift right 6 for port C
	stda8_24 1441796, c		; ld (0x160004), C — PPI port C
	res 7, a			; clear bit 7 (handshake low)
	srl a, 6			; shift right 6
	stda8_24 1441796, a		; ld (0x160004), A — PPI port C
	ld xwa, 0x000003E8		; timeout counter (1000)
.Lppi_wait_high:
	bitda_24 4, 1441792		; bit 4, (0x160000) — check ACK
	jr z, .Lppi_wait_high		; wait until bit 4 set
	ldda8_24 a, 1441792		; ld A, (0x160000) — read port A
	and a, 0x0f			; mask low nibble
	ld e, a				; save low nibble in E
	; --- High nibble phase ---
	ld a, l				; restore original byte
	srl a, 1			; shift right 1
	res 7, a			; clear bit 7
	stda8_24 1441794, a		; ld (0x160002), A — PPI port B
	ld c, a				; save port B value
	srl c, 6			; shift right 6 for port C
	stda8_24 1441796, c		; ld (0x160004), C — PPI port C
	set 7, a			; set bit 7 (handshake high)
	srl a, 6			; shift right 6
	stda8_24 1441796, a		; ld (0x160004), A — PPI port C
	ld xwa, 0x000003E8		; timeout counter (1000)
.Lppi_wait_low:
	bitda_24 4, 1441792		; bit 4, (0x160000) — check ACK
	jr nz, .Lppi_wait_low		; wait until bit 4 clear
	; --- Reassemble and verify ---
	ld c, e				; C = low nibble
	ldda8_24 a, 1441792		; ld A, (0x160000) — read port A
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
	ldada_24 xde, 3023530		; 0x2E22AA
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
	ldada_24 xwa, 3023494		; 0x2E2286
	calr HDAE5000_Event_Handler
	ldada_24 xwa, 3023496		; 0x2E2288
	calr HDAE5000_Event_Handler
	jr t, .Lpws_done
.Lpws_error:
	ldada_24 xwa, 3023512		; 0x2E2298
	calr HDAE5000_Event_Handler
.Lpws_done:
	lda xsp, (xsp + 124)		; deallocate stack frame
	ret

HDAE5000_PPI_Read_Sector:	; 0x282D2E (270 bytes)
	; Read a sector of data from HD via PPI
	; Registers PPI device handlers for read operations via workspace dispatch
	; Copy 14 bytes: source table → PPI buffer
	pushw 0x000E			; count = 14
	ldada_24 xwa, 3022054		; 0x2E1CE6
	push xwa			; source
	ldada_24 xwa, 2271900		; 0x22AA9C
	push xwa			; dest
	call HDAE5000_MemCopy
	lda xsp, (xsp + 10)		; pop args
	; Register PPI device: first handler pair (0xDE)
	ldada_24 xwa, 2271900		; 0x22AA9C - buffer ptr
	ld xde, xwa
	ldda32_24 xwa, 2335138		; workspace ptr (0x23A1A2)
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; (XWA + 0x0E0A)
	ld_sril3 xhl, 0xE1, 0x24, 0x01	; (XWA + 0x0124)
	ld xwa, 0x007F00DE
	ld xbc, 0x01EA000A
	call (xhl)
	; Register second handler (0xDE, different params)
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x24, 0x01
	ld xwa, 0x007F00DE
	ld xbc, 0x01C0000F
	ld xde, 0xFFFFFFFF
	call (xhl)
	; Copy 241 bytes: second table → PPI buffer
	pushw 0x00F1			; count = 241
	ldada_24 xwa, 3022068		; 0x2E1CF4
	push xwa			; source
	ldada_24 xwa, 2271914		; 0x22AAAA
	push xwa			; dest
	call HDAE5000_MemCopy
	lda xsp, (xsp + 10)		; pop args
	; Register PPI device: second handler pair (0xD7)
	ldada_24 xwa, 2271914		; 0x22AAAA
	ld xde, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x24, 0x01
	ld xwa, 0x007F00D7
	ld xbc, 0x01EA000A
	call (xhl)
	; Second handler (0xD7, different params)
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x24, 0x01
	ld xwa, 0x007F00D7
	ld xbc, 0x01C0000F
	ld xde, 0xFFFFFFFF
	call (xhl)
	; Register third handler (0xD9)
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x24, 0x01
	ld xwa, 0x007F00D9
	ld xbc, 0x01C0000D
	lds32 xde, 0
	call (xhl)
	; Register fourth handler (0xD8)
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x24, 0x01
	ld xwa, 0x007F00D8
	ld xbc, 0x01C0000D
	lds32 xde, 0
	call (xhl)
	; Clear two 20-byte buffers
	pushw 0x0014			; count = 20
	pushw 0x0000			; fill = 0
	ldada_24 xwa, 2272156		; 0x22AB9C
	push xwa
	call HDAE5000_MemFill
	pushw 0x0014			; count = 20
	pushw 0x0000			; fill = 0
	ldada_24 xwa, 2272176		; 0x22ABB0
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
	; Part 1: Display error message (0x284DE9)
	; XWA = string address. Validates length, copies to buffer, displays.
	push xiz
	ld xiz, xwa			; save string address
	ld xwa, xiz
	push xwa
	call HDAE5000_Display_Buffer_Validate
	inc 4, xsp			; cleanup arg
	cp hl, 0x0019			; cap length at 25
	jr ule, .Lhec_len_ok
	ldw hl, 0x0019
.Lhec_len_ok:
	pushw hl			; push length
	ld xwa, xiz
	push xwa			; push source
	ldada_24 xwa, 2272203		; 0x22ABCB — dest buffer
	push xwa
	call HDAE5000_MemCopy_Reverse
	lda xsp, (xsp + 10)		; cleanup 10 bytes of args
	; Display error string
	ldada_24 xwa, 2272196		; 0x22ABC4 — display buffer
	ld xde, xwa
	ldda32_24 xwa, 2335138		; (0x23A1A2)
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; (XWA+0x0E0A)
	ld_sril3 xhl, 0xE1, 0x00, 0x01	; (XWA+0x0100) — display handler
	ld xwa, 0x007F0068		; display params
	ld xbc, 0x01EA000A		; color/position
	call (xhl)
	; Clear display line
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x00, 0x01
	ld xwa, 0x007F0068
	ld xbc, 0x01C0000F
	ld xde, 0xFFFFFFFF
	call (xhl)
	pop xiz
	ret
	; Part 2: Error handler dispatcher (0x284E53)
	; XWA = original params, XBC = error code, XDE = extra data
	dec 0, xsp
	push xiz
	ld (xsp + 4), xde		; save extra data
	ld xiz, xbc			; XIZ = error code
	ld (xsp + 8), xwa		; save original params
	; Dispatch on error code
	ld xwa, xiz
	cp xwa, 0x01C00007		; error 7 (command failed)?
	jr z, .Lhd_err7
	cp xwa, 0x01C0000D		; error 13 (retry)?
	jr z, .Lhd_err13
	cp xwa, 0x01E00085		; error 0x85 (fatal)?
	jrl nz, .Lhd_cleanup
	lds32 xhl, 1			; return 1 (fatal)
	jrl .Lhd_exit
.Lhd_err13:
	; Error 13: retry — call callback, copy buffer, redisplay
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	ldda32_24 xhl, 2335138
	ld_sril3 xhl, 0xED, 0x0A, 0x0E	; (XHL+0x0E0A)
	ld_sril3 xhl, 0xED, 0xDC, 0x00	; (XHL+0x00DC) — callback
	call (xhl)
	ldada_24 xwa, 3024648		; 0x2E2708 — status buffer
	ld xbc, xwa
	ld xwa, (xsp + 8)
	ld xde, xbc
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x0A, 0x0E	; (XBC+0x0E0A)
	ld_sril3 xhl, 0xE5, 0x00, 0x01	; (XBC+0x0100) — display handler
	ld xbc, 0x01C0000F
	call (xhl)
	lds32 xhl, 0			; return 0 (retry ok)
	jrl .Lhd_exit
.Lhd_err7:
	; Error 7: command failed — check sub-code
	ld xde, (xsp + 4)
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xix, 0xE1, 0x00, 0x01	; XIX = display handler
	ld xwa, 0x02600024
	ld xbc, 0x01E00029
	call (xix)
	cp xhl, 0x00000007		; sub-code 7?
	jr z, .Lhd_err7_display
	cp xhl, 0x00000006		; sub-code 6?
	jr z, .Lhd_err7_display
	cp xhl, 0x00000001		; sub-code 1?
	jr z, .Lhd_err7_minor
	or xhl, xhl			; sub-code 0?
	jr nz, .Lhd_cleanup
.Lhd_err7_minor:
	ldada_24 xwa, 3024654		; 0x2E270E — error string
	calr HDAE5000_HD_Error_Check	; recursive: display error
	call HDAE5000_PPORT_Init_Main
	jr .Lhd_cleanup
.Lhd_err7_display:
	call HDAE5000_PPORT_Reset
	ldada_24 xwa, 3024670		; 0x2E271E — error string
	calr HDAE5000_HD_Error_Check	; recursive: display error
	; Reinit display handler
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x04, 0x01	; (XWA+0x0104) — init handler
	ld xwa, 0x007F0013
	ld xbc, 0x01C00001
	lds32 xde, 0
	call (xhl)
.Lhd_cleanup:
	; Final cleanup: call error callback
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	ldda32_24 xhl, 2335138
	ld_sril3 xhl, 0xED, 0x0A, 0x0E
	ld_sril3 xix, 0xED, 0xDC, 0x00	; XIX = callback
	call (xix)
.Lhd_exit:
	pop xiz
	inc 0, xsp
	ret

HDAE5000_HD_Wait_Ready:	; 0x284F4C (138 bytes)
	; Set up two parameter blocks on stack from template data, then call
	; workspace handler +0x0114 twice. Validates A < 16, L <= 1, E <= 2.
	; Input: A = register index, L = bank, E = mode
	dec 0, xsp			; allocate 8 bytes on stack
	ld l, c				; save C in L
	ld xiy, 0x002E272E		; source template address (first block)
	lda xix, (xsp + 4)		; XIX = destination: stack+4
	ldiw				; copy word (XIY→XIX, both advance)
	ldiw				; copy second word
	ld xiy, 0x002E2732		; source template address (second block)
	ld xix, xsp			; XIX = destination: stack base
	ldiw				; copy word
	ldiw				; copy second word
	; --- Parameter validation ---
	cp a, 0x10			; A must be < 16
	jr nc, .Lwr_exit		; if A >= 16, bail out
	cps l, 1			; L must be <= 1
	jr ugt, .Lwr_exit		; if L > 1, bail out
	cps e, 2			; E must be <= 2
	jr ugt, .Lwr_exit		; if E > 2, bail out
	; --- Fill parameter blocks ---
	ld (xsp + 5), a			; store register index at offset 5
	ld (xsp + 1), a			; store register index at offset 1
	cps l, 0			; check bank
	jr nz, .Lwr_bank1
	ldmi8 (xsp + 7), 0x01		; bank 0: store 0x01 at offset 7
	jr t, .Lwr_mode
.Lwr_bank1:
	ldmi8 (xsp + 7), 0x20		; bank 1: store 0x20 at offset 7
.Lwr_mode:
	cps e, 0			; check mode
	jr nz, .Lwr_mode1
	ldmi8 (xsp + 3), 0x00		; mode 0: store 0x00 at offset 3
	jr t, .Lwr_call
.Lwr_mode1:
	cps e, 1			; mode 1?
	jr nz, .Lwr_mode2
	ldmi8 (xsp + 3), 0x01		; mode 1: store 0x01 at offset 3
	jr t, .Lwr_call
.Lwr_mode2:
	ldmi8 (xsp + 3), 0x02		; mode 2: store 0x02 at offset 3
.Lwr_call:
	; --- First workspace call (stack+4 block) ---
	lda xwa, (xsp + 4)		; XWA = pointer to first param block
	ld xde, xwa			; XDE = param block ptr
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; ld XWA, (XWA + 0x0E88)
	ld_sril3 xhl, 0xE1, 0x14, 0x01	; ld XHL, (XWA + 0x0114)
	lds wa, 0			; WA = 0
	lds bc, 4			; BC = 4 (param count)
	call (xhl)			; call handler
	; --- Second workspace call (stack base block) ---
	lda xwa, (xsp)			; XWA = pointer to second param block
	ld xde, xwa			; XDE = param block ptr
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; ld XWA, (XWA + 0x0E88)
	ld_sril3 xhl, 0xE1, 0x14, 0x01	; ld XHL, (XWA + 0x0114)
	lds wa, 0			; WA = 0
	lds bc, 4			; BC = 4
	call (xhl)			; call handler
.Lwr_exit:
	inc 0, xsp			; deallocate 8 bytes
	ret

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
	; Sub-routine 1: Build bit flags from partition status array
	; Input: XWA = pointer to buffer (byte 0-1 = output flags, bytes 2-10 = status)
	; Sets bit N in (XWA) for each partition N whose status byte == 2
	ldmw (xwa + 0), 0x0000		; clear output flags
	cpmi8 (xwa + 2), 0x02
	jr nz, .Lhbi_skip0
	ldmw (xwa + 0), 0x0001		; set bit 0
.Lhbi_skip0:
	cpmi8 (xwa + 3), 0x02
	jr nz, .Lhbi_skip1
	ormi16 (xwa + 0), 0x0002	; set bit 1
.Lhbi_skip1:
	cpmi8 (xwa + 4), 0x02
	jr nz, .Lhbi_skip2
	ormi16 (xwa + 0), 0x0004	; set bit 2
.Lhbi_skip2:
	cpmi8 (xwa + 5), 0x02
	jr nz, .Lhbi_skip3
	ormi16 (xwa + 0), 0x0008	; set bit 3
.Lhbi_skip3:
	cpmi8 (xwa + 6), 0x02
	jr nz, .Lhbi_skip4
	ormi16 (xwa + 0), 0x0010	; set bit 4
.Lhbi_skip4:
	cpmi8 (xwa + 7), 0x02
	jr nz, .Lhbi_skip5
	ormi16 (xwa + 0), 0x0020	; set bit 5
.Lhbi_skip5:
	cpmi8 (xwa + 8), 0x02
	jr nz, .Lhbi_skip6
	ormi16 (xwa + 0), 0x0040	; set bit 6
.Lhbi_skip6:
	cpmi8 (xwa + 9), 0x02
	jr nz, .Lhbi_skip7
	ormi16 (xwa + 0), 0x0080	; set bit 7
.Lhbi_skip7:
	cpmi8 (xwa + 10), 0x02
	ret nz
	ormi16 (xwa + 0), 0x0100	; set bit 8
	ret
	; Sub-routine 2: Command dispatcher with computed jump table
	; Input: XWA = context pointer (saved as XIZ), XBC = command ID
	; Returns XHL = result
	push xiz
	ld xiz, xwa			; save context
	ld xwa, xbc			; command → XWA
	cp xwa, 0x01E00082		; special command?
	jr z, .Lhbi_special
	sub xwa, 0x01E0003E		; normalize to index 0-9
	cp xwa, 0x00000000
	jr lt, .Lhbi_default
	cp xwa, 0x00000009
	jr gt, .Lhbi_default
	add xwa, xwa			; index * 2 (table has 16-bit entries)
	add xwa, 0x002E293E		; jump table base
	ld wa, (xwa + 0)		; load offset from table
	ldada_24 xix, 2642902		; base of case handlers (0x2853D6)
	jp_dri 8, 0x07, 0xF0, 0xE0	; jp T, XIX+WA
.Lhbi_case0:
	; Case 0: PPI block copy from device
	pushw 0x0023
	pushw 0xA04E
	pushw 0x002E
	pushw 0x293A
	ld xwa, (xde + 18)
	push xwa
	call HDAE5000_PPI_Block_Copy
	lda xsp, (xsp + 12)		; pop args
	ld xhl, xiz			; return context ptr
	jr t, .Lhbi_exit
.Lhbi_case1:
	lds32 xhl, 1
	jr t, .Lhbi_exit
.Lhbi_case2:
	lds32 xhl, 1
	jr t, .Lhbi_exit
.Lhbi_case3:
	lds32 xhl, 0
	jr t, .Lhbi_exit
.Lhbi_case4:
	lds32 xhl, 0
	jr t, .Lhbi_exit
.Lhbi_case5:
	ldada_24 xhl, 2271831		; 0x22AA57
	jr t, .Lhbi_exit
.Lhbi_case6:
	lds32 xhl, 1
	jr t, .Lhbi_exit
.Lhbi_special:
	; Command 0x01E00082: init buffer then return 0
	ldada_24 xwa, 2271820		; 0x22AA4C
	calr HDAE5000_HD_Buffer_Init
	lds32 xhl, 0
	jr t, .Lhbi_exit
.Lhbi_default:
	lds32 xhl, 0
.Lhbi_exit:
	pop xiz
	ret

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
	; Register menu handler (variant B) — two sub-routines
	; First sub-routine: register with 0x01C00015
	dec 2, xsp			; allocate local space
	ld (xsp), a			; save menu index
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; ld XWA, (XWA + 0x0E0A) — menu table
	ld_sril3 xhl, 0xE1, 0x34, 0x05	; ld XHL, (XWA + 0x0534) — register fn
	ld xwa, 0xFFFFFFFF		; param: all bits set
	ld xbc, 0x01C00015		; param: menu geometry
	call (xhl)			; register first entry
	lds32 xwa, 0			; clear XWA
	ld a, (xsp)			; restore menu index
	add xwa, 0x01A00000		; construct entry ID
	ld xde, xwa			; XDE = entry ID
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; ld XWA, (XWA + 0x0E0A) — menu table
	ld_sril3 xhl, 0xE1, 0x24, 0x01	; ld XHL, (XWA + 0x0124) — alternate fn
	ld xwa, 0xFFFFFFFF		; param: all bits set
	ld xbc, 0x01C00015		; param: menu geometry
	call (xhl)			; register second entry
	inc 2, xsp			; deallocate local space
	ret
	; Second sub-routine: register with 0x01C00016
	dec 2, xsp			; allocate local space
	ld (xsp), a			; save menu index
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; ld XWA, (XWA + 0x0E0A) — menu table
	ld_sril3 xhl, 0xE1, 0x34, 0x05	; ld XHL, (XWA + 0x0534) — register fn
	ld xwa, 0xFFFFFFFF		; param: all bits set
	ld xbc, 0x01C00016		; param: menu geometry
	call (xhl)			; register first entry
	lds32 xwa, 0			; clear XWA
	ld a, (xsp)			; restore menu index
	add xwa, 0x01A00000		; construct entry ID
	ld xde, xwa			; XDE = entry ID
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; ld XWA, (XWA + 0x0E0A) — menu table
	ld_sril3 xhl, 0xE1, 0x24, 0x01	; ld XHL, (XWA + 0x0124) — alternate fn
	ld xwa, 0xFFFFFFFF		; param: all bits set
	ld xbc, 0x01C00016		; param: menu geometry
	call (xhl)			; register second entry
	inc 2, xsp			; deallocate local space
	ret

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
	; Handle menu events: copy params, register handler, dispatch callback
	; Input: WA = menu ID, XBC = param block, XDE = context
	lda xsp, (xsp - 22)		; allocate 22 bytes on stack
	pushw iz
	ld (xsp + 20), xde		; save context
	ld iz, wa			; IZ = menu ID
	pushw 0x0010			; param: size 16
	push xbc			; param: source block
	lda xwa, (xsp + 8)		; XWA = destination (stack buffer)
	push xwa
	call HDAE5000_MemCopy_Reverse	; copy param block to stack
	lda xsp, (xsp + 10)		; pop 3 args (10 bytes)
	ldmi8 (xsp + 18), 0x00		; clear status byte
	; --- Register menu handler ---
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; ld XWA, (XWA + 0x0E0A)
	ld_sril3 xhl, 0xE1, 0x00, 0x01	; ld XHL, (XWA + 0x0100)
	ld xwa, 0x007F02C1		; handler ID
	ld xbc, 0x01C00001		; param
	lds32 xde, 3			; mode = 3
	call (xhl)
	calr HDAE5000_Wait_Callback_Loop
	; --- Copy to table ---
	lda xwa, (xsp + 2)		; XWA = stack buffer ptr
	ld xbc, xwa			; XBC = buffer
	ld wa, iz			; WA = menu ID
	lds de, 0			; DE = 0
	call HDAE5000_Copy_To_Table
	cp hl, 0xFFFF			; check if copy failed
	jr z, .Lmh_alt			; if failed, try alternate path
	; --- Direct dispatch ---
	ld xwa, (xsp + 20)		; reload context
	ldda32_24 xbc, 2335138		; ld XBC, (0x23A1A2)
	ld_sril3 xbc, 0xE5, 0x0A, 0x0E	; ld XBC, (XBC + 0x0E0A)
	ld_sril3 xhl, 0xE5, 0x04, 0x01	; ld XHL, (XBC + 0x0104)
	ld xbc, 0x01C00001		; param
	lds32 xde, 0			; mode = 0
	call (xhl)
	jr t, .Lmh_finish
.Lmh_alt:
	; --- Alternate handler ---
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x00, 0x01	; ld XHL, (XWA + 0x0100)
	ld xwa, 0x007F0297		; alternate handler ID
	ld xbc, 0x01C00001
	lds32 xde, 0
	call (xhl)
	ld xbc, (xsp + 20)		; XBC = context
	ld xwa, 0x007F0298		; event ID
	calr HDAE5000_UI_Main_Handler
	; --- Register display handlers ---
	ld xwa, 0x01CA0002		; display param
	push xwa
	ld xwa, (xsp + 24)		; reload context (+4 for push)
	push xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x18, 0x04	; ld XHL, (XWA + 0x0418)
	ld xwa, 0x0000014D		; display handler ID
	ld xbc, 0x007F0299		; event ID
	ld xde, 0xFFFFFFFF		; param
	call (xhl)
	ld xwa, 0x01CA0002		; display param
	push xwa
	ld xwa, (xsp + 24)		; reload context (+4 for push)
	push xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x10, 0x04	; ld XHL, (XWA + 0x0410)
	ld xwa, 0x0000014D
	ld xbc, 0x007F0299
	ld xde, 0xFFFFFFFF
	call (xhl)
.Lmh_finish:
	ldada_24 xwa, 2272242		; lda XWA, 0x22ABF2
	lda xbc, (xsp + 2)		; XBC = stack buffer
	calr HDAE5000_Get_Table_Entry
	popw iz
	lda xsp, (xsp + 22)		; deallocate stack
	ret

HDAE5000_Menu_Callback:	; 0x28AE40 (248 bytes)
	; Menu callback processor: same structure as Menu_Handler with different
	; call target (Copy_Display_Cell_90) and table address (0x22AD0A)
	lda xsp, (xsp - 22)		; allocate 22 bytes on stack
	pushw iz
	ld (xsp + 20), xde		; save context
	ld iz, wa			; IZ = menu ID
	pushw 0x0010			; param: size 16
	push xbc			; param: source block
	lda xwa, (xsp + 8)		; XWA = destination (stack buffer)
	push xwa
	call HDAE5000_MemCopy_Reverse	; copy param block to stack
	lda xsp, (xsp + 10)		; pop 3 args
	ldmi8 (xsp + 18), 0x00		; clear status byte
	; --- Register menu handler ---
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2)
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; ld XWA, (XWA + 0x0E0A)
	ld_sril3 xhl, 0xE1, 0x00, 0x01	; ld XHL, (XWA + 0x0100)
	ld xwa, 0x007F02C1
	ld xbc, 0x01C00001
	lds32 xde, 3
	call (xhl)
	calr HDAE5000_Wait_Callback_Loop
	; --- Copy display cell ---
	lda xwa, (xsp + 2)
	ld xbc, xwa
	ld wa, iz
	lds de, 0
	call HDAE5000_Copy_Display_Cell_90
	cp hl, 0xFFFF
	jr z, .Lmc_alt
	; --- Direct dispatch ---
	ld xwa, (xsp + 20)
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x0A, 0x0E
	ld_sril3 xhl, 0xE5, 0x04, 0x01	; ld XHL, (XBC + 0x0104)
	ld xbc, 0x01C00001
	lds32 xde, 0
	call (xhl)
	jr t, .Lmc_finish
.Lmc_alt:
	; --- Alternate handler ---
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x00, 0x01
	ld xwa, 0x007F0297
	ld xbc, 0x01C00001
	lds32 xde, 0
	call (xhl)
	ld xbc, (xsp + 20)
	ld xwa, 0x007F0298
	calr HDAE5000_UI_Main_Handler
	; --- Register display handlers ---
	ld xwa, 0x01CA0002
	push xwa
	ld xwa, (xsp + 24)
	push xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x18, 0x04	; ld XHL, (XWA + 0x0418)
	ld xwa, 0x0000014D
	ld xbc, 0x007F0299
	ld xde, 0xFFFFFFFF
	call (xhl)
	ld xwa, 0x01CA0002
	push xwa
	ld xwa, (xsp + 24)
	push xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x10, 0x04	; ld XHL, (XWA + 0x0410)
	ld xwa, 0x0000014D
	ld xbc, 0x007F0299
	ld xde, 0xFFFFFFFF
	call (xhl)
.Lmc_finish:
	ldada_24 xwa, 2272522		; lda XWA, 0x22AD0A
	lda xbc, (xsp + 2)
	calr HDAE5000_Get_Table_Entry
	popw iz
	lda xsp, (xsp + 22)
	ret

HDAE5000_Display_Manager:	; 0x28AF38 (441 bytes)
	; Manage display state; accesses 0x229DAB
	.incbin "includes/code_2803c2_28f542.bin", 43894, 441

HDAE5000_Display_Scroll:	; 0x28B0F1 (271 bytes)
	; Handle display scroll: register handler, copy data, dispatch callback
	; Input: WA = index, BC = param, DE = context ptr
	lda xsp, (xsp - 34)		; allocate 34 bytes on stack (0xDE = -34)
	pushw iz
	ld iz, de			; IZ = context ptr
	ld (xsp + 32), bc		; save BC param at offset 0x20
	ld (xsp + 34), wa		; save WA index at offset 0x22
	; --- Register handler via workspace ---
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2)
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; ld XWA, (XWA + 0x0E0A)
	ld_sril3 xhl, 0xE1, 0x00, 0x01	; ld XHL, (XWA + 0x0100)
	ld xwa, 0x007F02C1
	ld xbc, 0x01C00001
	lds32 xde, 0
	call (xhl)
	; --- Copy data to stack buffer ---
	pushw 0x001A			; param: size 26
	ld xwa, (xsp + 48)		; reload source (+2 for pushw) = XSP+0x30
	push xwa
	lda xwa, (xsp + 10)		; destination (stack buffer at +0x0A)
	push xwa
	call HDAE5000_MemCopy_Reverse
	lda xsp, (xsp + 10)		; pop 3 args
	ldmi8 (xsp + 30), 0x00		; clear status byte at offset 0x1E
	; --- Prepare and call 0x291140 ---
	lda xwa, (xsp + 4)		; XWA = buffer ptr at stack+4
	ld xde, xwa			; XDE = buffer
	pushw iz			; push context ptr
	pushm (xsp + 46)		; push word from (XSP+0x2E)
	pushw 0x0000			; push 0
	ld wa, (xsp + 40)		; WA = saved index (XSP+0x28)
	ld bc, (xsp + 38)		; BC = saved param (XSP+0x26)
	call 0x291140			; call scroll handler
	ld (xsp + 2), hl		; save result at offset 2
	; --- Check result ---
	ld wa, (xsp + 2)		; reload result
	cp wa, 0xFFFF			; check for failure
	jr z, .Lds_alt			; if failed, try alternate
	; --- Direct dispatch ---
	ld xwa, (xsp + 40)		; load context (XSP+0x28)
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x0A, 0x0E
	ld_sril3 xhl, 0xE5, 0x04, 0x01
	ld xbc, 0x01C00001
	lds32 xde, 0
	call (xhl)
	jr t, .Lds_finish
.Lds_alt:
	; --- Alternate handler ---
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x00, 0x01
	ld xwa, 0x007F0297
	ld xbc, 0x01C00001
	lds32 xde, 0
	call (xhl)
	ld xbc, (xsp + 40)		; XBC = context (XSP+0x28)
	ld xwa, 0x007F0298
	calr HDAE5000_UI_Main_Handler
	; --- Register display handlers ---
	ld xwa, 0x01CA0002
	push xwa
	ld xwa, (xsp + 44)		; XSP+0x2C
	push xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x18, 0x04	; +0x0418
	ld xwa, 0x0000014D
	ld xbc, 0x007F0299
	ld xde, 0xFFFFFFFF
	call (xhl)
	ld xwa, 0x01CA0002
	push xwa
	ld xwa, (xsp + 44)		; XSP+0x2C
	push xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x10, 0x04	; +0x0410
	ld xwa, 0x0000014D
	ld xbc, 0x007F0299
	ld xde, 0xFFFFFFFF
	call (xhl)
.Lds_finish:
	ldada_24 xwa, 2272382		; lda XWA, 0x22AC7E
	lda xbc, (xsp + 4)
	calr HDAE5000_Get_Table_Entry
	ld hl, (xsp + 2)		; restore result to HL
	popw iz
	lda xsp, (xsp + 34)		; deallocate stack
	retd 0x000A			; return and pop 10 bytes

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
	; Set visibility for 9 menu items via workspace callback +0x0294
	; Input: A = 0 → show (IZ=1), A != 0 → hide (IZ=0)
	pushw iz
	cps a, 0
	jr nz, .Lsmv_hide
	lds iz, 1			; show mode
	jr t, .Lsmv_start
.Lsmv_hide:
	lds iz, 0			; hide mode
.Lsmv_start:
	ld bc, iz			; BC = visibility flag
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2)
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; ld XWA, (XWA + 0x0E0A)
	ld_sril3 xhl, 0xE1, 0x94, 0x02	; ld XHL, (XWA + 0x0294)
	ld xwa, 0x007F002C		; menu item 1
	call (xhl)
	ld bc, iz
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x94, 0x02
	ld xwa, 0x007F0100		; menu item 2
	call (xhl)
	ld bc, iz
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x94, 0x02
	ld xwa, 0x007F010A		; menu item 3
	call (xhl)
	ld bc, iz
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x94, 0x02
	ld xwa, 0x007F00F9		; menu item 4
	call (xhl)
	ld bc, iz
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x94, 0x02
	ld xwa, 0x007F013E		; menu item 5
	call (xhl)
	ld bc, iz
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x94, 0x02
	ld xwa, 0x007F010D		; menu item 6
	call (xhl)
	ld bc, iz
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x94, 0x02
	ld xwa, 0x007F00DA		; menu item 7
	call (xhl)
	ld bc, iz
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x94, 0x02
	ld xwa, 0x007F00DC		; menu item 8
	call (xhl)
	ld bc, iz
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x94, 0x02
	ld xwa, 0x007F0080		; menu item 9
	call (xhl)
	popw iz
	ret

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
	; Four sub-routines for error display and device initialization
	; Sub-routine 1: Clear display buffer at 0x22B430, reset state
	pushw 0x5000			; param: size 0x5000
	pushw 0x0000			; param: fill value 0
	ldada_24 xwa, 2274352		; lda XWA, 0x22B430 — buffer base
	push xwa
	call HDAE5000_MemFill		; clear buffer
	inc 0, xsp			; deallocate 8 bytes
	lds32 xwa, 0			; clear XWA
	stda32_24 2295026, xwa		; ld (0x2304F2), XWA — clear state ptr
	stdi8_24 2335132, 0x00		; ld (0x23A19C), 0x00 — clear flag
	ret
	; Sub-routine 2: Validate and setup display
.Lde_validate:
	calr HDAE5000_Display_Notify	; validate notification
	or xhl, xhl			; check result
	jr nz, .Lde_err2		; if nonzero, error
	calr HDAE5000_Display_Progress	; show progress
	or xhl, xhl			; check result
	jr nz, .Lde_err1		; if nonzero, error
	stdi8_24 2335132, 0x01		; ld (0x23A19C), 0x01 — set flag
	lds32 xhl, 0			; return success
	ret
.Lde_err1:
	ld xhl, 0xFFFFFFFF		; return -1
	ret
.Lde_err2:
	ld xhl, 0xFFFFFFFE		; return -2
	ret
	; Sub-routine 3: Check device status via workspace
.Lde_devcheck:
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; ld XWA, (XWA + 0x0E88)
	ld xix, (xwa + 8)		; XIX = device status callback
	call (xix)			; call device check
	cps l, 3			; check if result == 3
	jr z, .Lde_ready		; if so, device ready
	cps l, 2			; check if result == 2
	jr z, .Lde_ready		; if so, device ready
	ld xhl, 0xFFFFFFFF		; return -1 (not ready)
	ret
	; Sub-routine 4: Full initialization with workspace callbacks
.Lde_ready:
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; ld XWA, (XWA + 0x0E0A)
	ld_sril3 xhl, 0xE1, 0x38, 0x05	; ld XHL, (XWA + 0x0538)
	call (xhl)
	ldada_24 xwa, 3038180		; lda XWA, 0x2E5BE4
	ldada_24 xbc, 3038176		; lda XBC, 0x2E5BE0
	ldda32_24 xde, 2335138		; ld XDE, (0x23A1A2)
	ld_sril3 xde, 0xE9, 0x88, 0x0E	; ld XDE, (XDE + 0x0E88)
	ld_sril3 xhl, 0xE9, 0xA0, 0x00	; ld XHL, (XDE + 0x00A0)
	call (xhl)
	ldada_24 xwa, 2274352		; lda XWA, 0x22B430
	ldda32_24 xbc, 2335138		; ld XBC, (0x23A1A2)
	ld_sril3 xbc, 0xE5, 0x88, 0x0E	; ld XBC, (XBC + 0x0E88)
	ld_sril3 xhl, 0xE5, 0xA8, 0x00	; ld XHL, (XBC + 0x00A8)
	ld xbc, 0x00005000		; size = 0x5000
	call (xhl)
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0xAC, 0x00	; ld XHL, (XWA + 0x00AC)
	call (xhl)
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x3C, 0x05	; ld XHL, (XWA + 0x053C)
	call (xhl)
	lds32 xhl, 0			; return success
	ret

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
	; Input: DE = file count (negative = special), C = partition, A = operation type
	; Caller passes 32-bit argument on stack (accessed at xsp+14)
	; Returns XHL = result offset or 0xFFFFFFFF on error
	dec 0, xsp			; allocate 8 bytes
	pushw iz
	ld (xsp + 4), de		; save file count
	ld (xsp + 6), c		; save partition
	ld (xsp + 8), a		; save operation type
	cpmi16 (xsp + 4), 0x0000
	jrl lt, .Lfr_negative		; negative count → special handler
	; Positive count: iterate and accumulate
	ldmw (xsp + 2), 0x0000		; counter = 0
	lds32 xwa, 0
	stda32_24 2294848, xwa		; clear 0x230440
	lds iz, 0
	cp iz, (xsp + 4)
	jr ge, .Lfr_loop_done
.Lfr_loop_start:
	ld bc, (xsp + 2)		; load counter
	lds wa, 0
	calr HDAE5000_File_Format
	ld wa, hl
	add (xsp + 2), wa		; accumulate
	cps hl, 0
	jr nz, .Lfr_loop_next
	ld xhl, 0xFFFFFFFF		; format returned 0 → error
	jrl .Lfr_exit
.Lfr_loop_next:
	inc 1, iz
	cp iz, (xsp + 4)
	jr lt, .Lfr_loop_start
.Lfr_loop_done:
	cpmi8 (xsp + 8), 0x7c		; check operation type
	jr nz, .Lfr_search_pos
	; Operation 0x7C: single format call, compute offset
	ld a, (xsp + 6)
	extz wa
	ld bc, (xsp + 2)
	calr HDAE5000_File_Format
	ld wa, hl
	cps wa, 0
	jr z, .Lfr_7c_error
	ld wa, (xsp + 2)
	extz xwa
	ld bc, hl
	extz xbc
	ld xhl, xbc
	add xhl, xwa			; result = format_result + counter
	jrl .Lfr_exit
.Lfr_7c_error:
	ld xhl, 0xFFFFFFFF
	jrl .Lfr_exit
.Lfr_search_pos:
	; Not 0x7C: search loop until match or exhausted
	ld a, (xsp + 6)
	extz wa
	ld bc, (xsp + 2)
	calr HDAE5000_File_Format
	ld wa, hl
	add (xsp + 2), wa
	cps hl, 0
	jr z, .Lfr_search_pos_check
	ld a, (xsp + 8)
	extz wa
	cpda16_24 xwa, 2294832		; compare with (0x230430)
	jr nz, .Lfr_search_pos		; loop until match
.Lfr_search_pos_check:
	cps hl, 0
	jr z, .Lfr_search_pos_err
	ld hl, (xsp + 2)
	extz xhl
	jr t, .Lfr_exit
.Lfr_search_pos_err:
	ld xhl, 0xFFFFFFFF
	jr t, .Lfr_exit
.Lfr_negative:
	; DE < 0: check special values
	cpmi16 (xsp + 4), 0xFFFF	; DE == -1?
	jr nz, .Lfr_check_fffe
	ld xhl, 0xFFFFFFFF
	jr t, .Lfr_exit
.Lfr_check_fffe:
	cpmi16 (xsp + 4), 0xFFFE	; DE == -2?
	jr nz, .Lfr_return_zero
	cpmi8 (xsp + 8), 0x7c
	jr nz, .Lfr_fffe_search
	; DE==-2, op==0x7C: use caller's stack arg
	ld a, (xsp + 6)
	ld e, a
	extz de
	ld xwa, (xsp + 14)		; caller's 32-bit argument
	ld bc, wa
	ld wa, de
	calr HDAE5000_File_Format
	extz xhl
	jr t, .Lfr_exit
.Lfr_fffe_search:
	; DE==-2, op!=0x7C: search loop with caller's arg
	ld xwa, (xsp + 14)
	ld (xsp + 2), wa		; use lower 16 bits as counter
.Lfr_fffe_loop:
	ld a, (xsp + 6)
	extz wa
	ld bc, (xsp + 2)
	calr HDAE5000_File_Format
	ld wa, hl
	add (xsp + 2), wa
	cps hl, 0
	jr z, .Lfr_fffe_check
	ld a, (xsp + 8)
	extz wa
	cpda16_24 xwa, 2294832		; compare with (0x230430)
	jr nz, .Lfr_fffe_loop
.Lfr_fffe_check:
	cps hl, 0
	jr z, .Lfr_fffe_error
	ld hl, (xsp + 2)
	extz xhl
	jr t, .Lfr_exit
.Lfr_fffe_error:
	ld xhl, 0xFFFFFFFF
	jr t, .Lfr_exit
.Lfr_return_zero:
	lds32 xhl, 0
.Lfr_exit:
	popw iz
	inc 0, xsp			; deallocate 8 bytes
	retd 0x0004

HDAE5000_File_Format:	; 0x28E187 (772 bytes)
	; Format HD or partition
	.incbin "includes/code_2803c2_28f542.bin", 56773, 772

HDAE5000_Calc_Disk_Space:	; 0x28E48B (178 bytes)
	; First sub-routine: scan 4 entries, accumulate free space in XHL
	; Input: WA = base index. Returns XHL = free space or -1 on overflow
	lds32 xhl, 0			; XHL = 0 (accumulator)
	lds ix, 0			; IX = 0 (loop index)
	cps ix, 4			; check IX < 4
	jr nc, .Lcds_overflow		; if IX >= 4, overflow
.Lcds_loop:
	ld bc, wa			; BC = base index
	add bc, ix			; BC = base + loop index
	extz xbc			; zero-extend to 32-bit
	add xbc, 0x00000016		; add offset 22
	ld xde, 0x0022B430		; XDE = table base address
	add xde, xbc			; XDE = table entry pointer
	ld c, (xde)			; C = entry byte
	res 7, c			; clear bit 7 (status flag)
	ldb b, 0x00			; B = 0 (extend C to 16-bit BC)
	extz xbc			; zero-extend BC to XBC
	add xhl, xbc			; accumulate into XHL
	ld bc, wa			; BC = base index (again)
	add bc, ix			; BC = base + loop index
	extz xbc			; zero-extend
	add xbc, 0x00000016		; add offset 22
	ld xde, 0x0022B430		; table base
	add xde, xbc			; entry pointer
	cpmi8 (xde), 0x80		; check if entry >= 0x80
	jr nc, .Lcds_continue		; if >= 0x80, skip to continue loop
	; Entry < 0x80: found valid entry — store index and return
	ld wa, ix			; WA = found index
	inc 1, wa			; WA = index + 1
	stda16_24 2295902, xwa		; ld (0x23085E), WA
	ret
.Lcds_continue:
	sll xhl, 7			; shift accumulator left 7
	inc 1, ix			; IX++
	cps ix, 4			; check IX < 4
	jr c, .Lcds_loop		; loop while IX < 4
.Lcds_overflow:
	ld xhl, 0xFFFFFFFF		; return -1
	ret
	; Second sub-routine: find highest set bit position in XWA
	; Input: XWA = bitmap, XBC = buffer base. Returns HL = 0xFFFF
.Lcds_find:
	ld xde, xwa			; XDE = bitmap copy
	lds hl, 1			; HL = 1 (bit position counter)
	cps hl, 5			; check HL < 5
	jr nc, .Lcds_apply		; if >= 5, skip search
.Lcds_search:
	srl xde, 7			; shift right 7
	jr nz, .Lcds_next		; if nonzero, continue
	ld ix, hl			; IX = current position
	jr t, .Lcds_apply		; done searching
.Lcds_next:
	inc 1, hl			; HL++
	cps hl, 5			; check HL < 5
	jr c, .Lcds_search		; loop while HL < 5
.Lcds_apply:
	ld xde, xwa			; XDE = bitmap (fresh copy)
	ld hl, ix			; HL = position from search
	cps hl, 0			; check if zero
	jr z, .Lcds_done		; if zero, nothing to do
.Lcds_apply_loop:
	ld wa, hl			; WA = current position
	dec 1, wa			; WA = position - 1
	extz xwa			; zero-extend
	ld xix, xwa			; XIX = index
	add xix, xbc			; XIX = buffer + index
	ld a, e				; A = low byte of XDE
	res 7, a			; clear bit 7
	ld (xix), a			; store to buffer
	srl xde, 7			; shift bitmap right 7
	cp xde, 0x0000007F		; check if remaining fits in 7 bits
	ret ule				; if <= 127, done (conditional return)
	ld wa, hl			; WA = current position
	dec 1, wa			; WA = position - 1
	extz xwa			; zero-extend
	ld xix, xwa			; XIX = index
	add xix, xbc			; XIX = buffer + index
	ld wa, hl			; WA = current position
	dec 1, wa			; WA = position - 1
	extz xwa			; zero-extend
	add xwa, xbc			; XWA = buffer + index
	ld a, (xwa)			; read existing byte
	set 7, a			; set bit 7 (overflow flag)
	ld (xix), a			; write back
	djnz16 hl, .Lcds_apply_loop	; decrement HL, loop if nonzero
.Lcds_done:
	ldw hl, 0xFFFF			; return 0xFFFF
	ret

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
	; Byte-swap helper: swap high/low bytes of WA, return in HL
	; Input: WA = 16-bit value
	; Output: HL = byte-swapped result
	ld hl, wa			; HL = WA
	ldb h, 0x00			; clear H (keep L = low byte of WA)
	srl wa, 8			; WA >>= 8 (high byte to low)
	sll hl, 8			; HL <<= 8 (low byte to high)
	ldb w, 0x00			; clear W
	add hl, wa			; HL = (orig_low << 8) + orig_high
	ret
.Lec_main:				; 0x28F447 — extension check entry
	push xiz
	ld xiz, xwa			; save parameter in XIZ
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2) — workspace ptr
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; ld XWA, (XWA+0x0E88) — handler table
	ld xix, (xwa + 8)		; ld XIX, (XWA+0x08)
	call (xix)			; call validation handler
	cps l, 3			; check result == 3?
	jr z, .Lec_process		; if so, process extension
	cps l, 2			; check result == 2?
	jr nz, .Lec_finish		; if neither 2 nor 3, skip to end
.Lec_process:
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2)
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; ld XWA, (XWA+0x0E0A) — sub-handler table
	ld_sril3 xhl, 0xE1, 0x38, 0x05	; ld XHL, (XWA+0x0538)
	call (xhl)
	ld xwa, xiz			; restore parameter
	ldada_24 xbc, 3038666		; lda XBC, 0x2E5DCA — extension data ptr
	ldda32_24 xde, 2335138		; ld XDE, (0x23A1A2)
	ld_sril3 xde, 0xE9, 0x88, 0x0E	; ld XDE, (XDE+0x0E88)
	ld_sril3 xhl, 0xE9, 0xA0, 0x00	; ld XHL, (XDE+0x00A0)
	call (xhl)
	ldada_24 xwa, 2297516		; lda XWA, 0x230EAC
	ldda32_24 xbc, 2335138		; ld XBC, (0x23A1A2)
	ld_sril3 xbc, 0xE5, 0x88, 0x0E	; ld XBC, (XBC+0x0E88)
	ld_sril3 xhl, 0xE5, 0xA8, 0x00	; ld XHL, (XBC+0x00A8)
	ld xbc, 0x0000000E		; count = 14
	call (xhl)
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2)
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; ld XWA, (XWA+0x0E88)
	ld_sril3 xhl, 0xE1, 0xAC, 0x00	; ld XHL, (XWA+0x00AC)
	call (xhl)
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2)
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; ld XWA, (XWA+0x0E0A)
	ld_sril3 xhl, 0xE1, 0x3C, 0x05	; ld XHL, (XWA+0x053C)
	call (xhl)
.Lec_finish:
	ldada_24 xwa, 2297516		; lda XWA, 0x230EAC
	calr HDAE5000_Config_Init	; validate config
	pop xiz
	ret

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
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; ld XWA, (XWA+0x0E88) — display handler table
	ld_sril3 xhl, 0xE1, 0xE8, 0x00	; ld XHL, (XWA+0x00E8) — init callback
	lds wa, 1			; WA = 1
	call (xhl)			; call init callback
	cps iz, 1			; mode == 1?
	jr nz, .Ldi_skip1		; skip sub-handler if not
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2)
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; ld XWA, (XWA+0x0E0A) — sub-handler table
	ld_sril3 xhl, 0xE1, 0x38, 0x05	; ld XHL, (XWA+0x0538) — sub-handler callback
	call (xhl)			; call sub-handler
.Ldi_skip1:
	call HDAE5000_Display_String_Render
	ld (xsp + 2), hl		; save result on stack
	cps iz, 1			; mode == 1?
	jr nz, .Ldi_skip2		; skip sub-handler if not
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2)
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; ld XWA, (XWA+0x0E0A)
	ld_sril3 xhl, 0xE1, 0x3C, 0x05	; ld XHL, (XWA+0x053C) — post-render callback
	call (xhl)			; call post-render sub-handler
.Ldi_skip2:
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2)
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; ld XWA, (XWA+0x0E88)
	ld_sril3 xhl, 0xE1, 0xEC, 0x00	; ld XHL, (XWA+0x00EC) — cleanup callback
	call (xhl)			; call cleanup
	ldda32_24 xwa, 2335138		; ld XWA, (0x23A1A2)
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; ld XWA, (XWA+0x0E88)
	ld_sril3 xhl, 0xE1, 0xF0, 0x00	; ld XHL, (XWA+0x00F0) — final callback
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
	; Check 9 table slots for availability (-1 = free)
	; WA = row index, BC = column index
	; Returns HL=0 if any slot occupied, HL=0xFFFF if all free
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc		; save column
	ld (xsp + 6), wa		; save row
	; --- Slot 0: base 0x201656 ---
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl			; XIZ = column * 0x4C
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780		; + base offset
	add xhl, xiz			; + column offset
	ldada_24 xwa, 2102870		; 0x201656
	add xwa, xhl
	ld xwa, (xwa)			; load slot value
	cp xwa, 0xFFFFFFFF		; free?
	jr z, .Ltco_slot1
	lds hl, 0			; occupied → return 0
	jrl .Ltco_exit
	; --- Slot 1: base 0x20165A ---
.Ltco_slot1:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	ldada_24 xwa, 2102874		; 0x20165A
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot2
	lds hl, 0
	jrl .Ltco_exit
	; --- Slot 2: base 0x20165E ---
.Ltco_slot2:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	ldada_24 xwa, 2102878		; 0x20165E
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot3
	lds hl, 0
	jrl .Ltco_exit
	; --- Slot 3: base 0x201662 ---
.Ltco_slot3:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	ldada_24 xwa, 2102882		; 0x201662
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot4
	lds hl, 0
	jrl .Ltco_exit
	; --- Slot 4: base 0x201666 ---
.Ltco_slot4:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	ldada_24 xwa, 2102886		; 0x201666
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot5
	lds hl, 0
	jrl .Ltco_exit
	; --- Slot 5: base 0x20166A ---
.Ltco_slot5:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	ldada_24 xwa, 2102890		; 0x20166A
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot6
	lds hl, 0
	jrl .Ltco_exit
	; --- Slot 6: base 0x20166E ---
.Ltco_slot6:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	ldada_24 xwa, 2102894		; 0x20166E
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot7
	lds hl, 0
	jr .Ltco_exit
	; --- Slot 7: base 0x201672 ---
.Ltco_slot7:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	ldada_24 xwa, 2102898		; 0x201672
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_slot8
	lds hl, 0
	jr .Ltco_exit
	; --- Slot 8: base 0x201676 ---
.Ltco_slot8:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	ldada_24 xwa, 2102902		; 0x201676
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltco_all_free
	lds hl, 0
	jr .Ltco_exit
.Ltco_all_free:
	ldw hl, 0xFFFF			; all slots free
.Ltco_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Table_Lookup:	; 0x2903B3 (928 bytes)
	; Part 1: Build occupied-slot bitmask (bits 0-8)
	; WA = row, BC = column. Returns HL = bitmask or 0xFFFF if all free.
	dec 6, xsp
	push xiz
	ld (xsp + 6), bc		; save column
	ld (xsp + 8), wa		; save row
	ldmw (xsp + 4), 0x0000		; init bitmask = 0
	; First check if ALL slots are free (call Table_Calc_Offset)
	ld wa, (xsp + 8)
	ld bc, (xsp + 6)
	calr HDAE5000_Table_Calc_Offset
	cp hl, 0xFFFF
	jrl z, .Ltl_all_free
	; --- Check slot 0: 0x201656 ---
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	ldada_24 xwa, 2102870		; 0x201656
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_chk1
	setm 0, (xsp + 4)		; bit 0
	; --- Check slot 1: 0x20165A ---
.Ltl_chk1:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	ldada_24 xwa, 2102874		; 0x20165A
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_chk2
	setm 1, (xsp + 4)		; bit 1
	; --- Check slot 2: 0x20165E ---
.Ltl_chk2:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	ldada_24 xwa, 2102878		; 0x20165E
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_chk3
	setm 2, (xsp + 4)		; bit 2
	; --- Check slot 3: 0x201662 ---
.Ltl_chk3:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	ldada_24 xwa, 2102882		; 0x201662
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_chk4
	setm 3, (xsp + 4)		; bit 3
	; --- Check slot 4: 0x201666 ---
.Ltl_chk4:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	ldada_24 xwa, 2102886		; 0x201666
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_chk5
	setm 4, (xsp + 4)		; bit 4
	; --- Check slot 5: 0x20166A ---
.Ltl_chk5:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	ldada_24 xwa, 2102890		; 0x20166A
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_chk6
	setm 5, (xsp + 4)		; bit 5
	; --- Check slot 6: 0x20166E ---
.Ltl_chk6:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	ldada_24 xwa, 2102894		; 0x20166E
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_chk7
	setm 6, (xsp + 4)		; bit 6
	; --- Check slot 7: 0x201672 ---
.Ltl_chk7:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	ldada_24 xwa, 2102898		; 0x201672
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_chk8
	setm 7, (xsp + 4)		; bit 7
	; --- Check slot 8: 0x201676 ---
.Ltl_chk8:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x0000004C
	call HDAE5000_Multiply
	ld xiz, xhl
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x000004C0
	call HDAE5000_Multiply
	add xhl, 0x00000780
	add xhl, xiz
	ldada_24 xwa, 2102902		; 0x201676
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jr z, .Ltl_bitmask_done
	setm 0, (xsp + 5)		; bit 8 (high byte)
	jr .Ltl_bitmask_done
.Ltl_all_free:
	ldmw (xsp + 4), 0xFFFF		; all free marker
.Ltl_bitmask_done:
	ld hl, (xsp + 4)		; return bitmask
	pop xiz
	inc 6, xsp
	ret
	; Part 2: Entry setup handler (0x2905E9)
	; Uses bitmask in WA, dispatches Cell_Render routines per bit
	; IZ = entry ID, DE = param, BC = flags
	dec 4, xsp
	push xiz
	ld (xsp + 4), de		; save DE
	ld (xsp + 6), bc		; save BC (flags)
	ld iz, wa			; IZ = bitmask
	; Workspace handler init
	ldda32_24 xwa, 2335138		; (0x23A1A2)
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; XWA = (XWA+0x0E88)
	ld_sril3 xhl, 0xE1, 0xE8, 0x00	; XHL = (XWA+0x00E8)
	lds wa, 1
	call (xhl)
	; Conditional extra handler (if BC == 1)
	cpmi16 (xsp + 14), 0x0001
	jr nz, .Ltl2_skip_extra
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x38, 0x05
	call (xhl)
.Ltl2_skip_extra:
	call 0x297466
	; Test bits 0-8, calling Cell_Render subroutines
	ld wa, (xsp + 4)		; reload DE (bitmask param)
	; --- Bit 0 ---
	bit 0, wa
	jr z, .Ltl2_bit1
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_Table_Sub_290753
	.byte 0xD7, 0xFA, 0x9B		; ld QIZ, HL (previous-bank store)
	; --- Bit 1 ---
.Ltl2_bit1:
	.byte 0xD7, 0xFA, 0xCF, 0xFF, 0xFF	; cp QIZ, 0xFFFF
	jr z, .Ltl2_bit2
	ld wa, (xsp + 4)
	bit 1, wa
	jr z, .Ltl2_bit2
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_Table_Sub_2908B1
	.byte 0xD7, 0xFA, 0x9B		; ld QIZ, HL
	; --- Bit 2 ---
.Ltl2_bit2:
	.byte 0xD7, 0xFA, 0xCF, 0xFF, 0xFF	; cp QIZ, 0xFFFF
	jr z, .Ltl2_bit3
	ld wa, (xsp + 4)
	bit 2, wa
	jr z, .Ltl2_bit3
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_Table_Sub_290A00
	.byte 0xD7, 0xFA, 0x9B		; ld QIZ, HL
	; --- Bit 3 ---
.Ltl2_bit3:
	.byte 0xD7, 0xFA, 0xCF, 0xFF, 0xFF	; cp QIZ, 0xFFFF
	jr z, .Ltl2_bit4
	ld wa, (xsp + 4)
	bit 3, wa
	jr z, .Ltl2_bit4
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_Table_Sub_290B86
	.byte 0xD7, 0xFA, 0x9B		; ld QIZ, HL
	; --- Bit 4 ---
.Ltl2_bit4:
	.byte 0xD7, 0xFA, 0xCF, 0xFF, 0xFF	; cp QIZ, 0xFFFF
	jr z, .Ltl2_bit5
	ld wa, (xsp + 4)
	bit 4, wa
	jr z, .Ltl2_bit5
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_Table_Sub_290CB5
	.byte 0xD7, 0xFA, 0x9B		; ld QIZ, HL
	; --- Bit 5 ---
.Ltl2_bit5:
	.byte 0xD7, 0xFA, 0xCF, 0xFF, 0xFF	; cp QIZ, 0xFFFF
	jr z, .Ltl2_bit6
	ld wa, (xsp + 4)
	bit 5, wa
	jr z, .Ltl2_bit6
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_Table_Sub_290D91
	.byte 0xD7, 0xFA, 0x9B		; ld QIZ, HL
	; --- Bit 6 ---
.Ltl2_bit6:
	.byte 0xD7, 0xFA, 0xCF, 0xFF, 0xFF	; cp QIZ, 0xFFFF
	jr z, .Ltl2_bit7
	ld wa, (xsp + 4)
	bit 6, wa
	jr z, .Ltl2_bit7
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_Table_Sub_290EC0
	.byte 0xD7, 0xFA, 0x9B		; ld QIZ, HL
	; --- Bit 7 ---
.Ltl2_bit7:
	.byte 0xD7, 0xFA, 0xCF, 0xFF, 0xFF	; cp QIZ, 0xFFFF
	jr z, .Ltl2_bit8
	ld wa, (xsp + 4)
	bit 7, wa
	jr z, .Ltl2_bit8
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_Table_Sub_290F45
	.byte 0xD7, 0xFA, 0x9B		; ld QIZ, HL
	; --- Bit 8 ---
.Ltl2_bit8:
	.byte 0xD7, 0xFA, 0xCF, 0xFF, 0xFF	; cp QIZ, 0xFFFF
	jr z, .Ltl2_final
	ld wa, (xsp + 4)
	bit 8, wa
	jr z, .Ltl2_final
	ld wa, iz
	ld bc, (xsp + 6)
	calr HDAE5000_Table_Sub_29103D
	.byte 0xD7, 0xFA, 0x9B		; ld QIZ, HL
	; --- Final workspace cleanup ---
.Ltl2_final:
	cpmi16 (xsp + 12), 0x0001	; check param
	callcc_24 14, 2716853		; call nz, 0x2974B5
	cpmi16 (xsp + 14), 0x0001	; check BC == 1?
	jr nz, .Ltl2_skip_final
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x3C, 0x05
	call (xhl)
.Ltl2_skip_final:
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0xEC, 0x00
	call (xhl)
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0xF0, 0x00
	call (xhl)
	.byte 0xD7, 0xFA, 0x8B		; ld HL, QIZ (load from previous-bank)
	pop xiz
	inc 4, xsp
	retd 4

HDAE5000_Table_Sub_290753:	; 0x290753 (350 bytes)
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 28), bc	; save file number
	ld (xsp + 30), wa	; save partition
	ldmw (xsp + 10), 0x0000	; init result = 0
	; First multiply: compute table offset
	ld wa, (xsp + 28)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	; Check if entry exists
	ldada_24 xwa, 2102870	; 0x201656 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts907_load	; entry doesn't exist, result stays 0
	; Workspace dispatch with WA=0 (buffer at xsp+20)
	lda xwa, (xsp + 20)
	ld xbc, xwa
	ldda32_24 xwa, 2335138	; 0x23A1A2
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 0
	call (xhl)
	; Workspace dispatch with WA=1 (buffer at xsp+12)
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 1
	call (xhl)
	; Compute arg and call Cell_Get_Params
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 4), xhl
	; Workspace dispatch (d8 displacement 0x0C)
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld xhl, (xwa + 12)	; (XWA+0x0C)
	call (xhl)
	; Save workspace ptr
	ldada_24 xwa, 2297628	; 0x230F1C
	ld (xsp + 8), xwa
	; Second multiply: compute table offset
	ld wa, (xsp + 28)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	; Table lookup via 0x29811C
	ldada_24 xwa, 2102870	; 0x201656
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	call 0x29811C
	ld (xsp + 10), hl	; save result
	; Call 0x29AE9F with args (first)
	ld xwa, (xsp + 24)
	pushw wa
	ldada_24 xwa, 2297628	; 0x230F1C
	push xwa
	ld xwa, (xsp + 26)
	push xwa
	call 0x29AE9F
	; Call 0x29AE9F with args (second)
	ld xwa, (xsp + 26)
	pushw wa
	ldada_24 xwa, 2297628	; 0x230F1C
	add xwa, (xsp + 36)
	push xwa
	ld xwa, (xsp + 28)
	push xwa
	call 0x29AE9F
	lda xsp, (xsp + 20)	; clean up pushed args
	; Read metadata FROM table and store to globals
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	ld xbc, 0x00230F1C
	add xbc, xwa
	ld a, (xbc)
	stda8_24 2274036, a	; (0x22B2F4)
	; Read at offset+1
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	inc 1, xwa
	ld xbc, 0x00230F1C
	add xbc, xwa
	ld a, (xbc)
	stda8_24 2334880, a	; (0x23A0A0)
	; Read at offset+2
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	inc 2, xwa
	ld xbc, 0x00230F1C
	add xbc, xwa
	ld a, (xbc)
	stda8_24 2334878, a	; (0x23A09E)
	; Call 0x284FD6
	call 0x284FD6
	; Final workspace dispatch
	ld wa, (xsp + 10)
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld xhl, (xbc + 16)	; (XBC+0x10)
	call (xhl)
.Lts907_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 28)
	ret

HDAE5000_Table_Sub_2908B1:	; 0x2908B1 (335 bytes)
	lda xsp, (xsp - 38)
	push xiz
	ld (xsp + 38), bc	; save file number
	ld (xsp + 40), wa	; save partition
	ldmw (xsp + 12), 0x0000	; init result = 0
	ldmw (xsp + 4), 0x0000	; init flag = 0
	; First multiply: compute table offset
	ld wa, (xsp + 38)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 40)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	; Check if entry exists
	ldada_24 xwa, 2102874	; 0x20165A (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts8b1_load	; entry doesn't exist
	; Workspace dispatch with WA=2 (buffer at xsp+30)
	lda xwa, (xsp + 30)
	ld xbc, xwa
	ldda32_24 xwa, 2335138	; 0x23A1A2
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 2
	call (xhl)
	; Save cell_params ptr
	lda xwa, (xsp + 14)
	ld (xsp + 10), xwa
	; Second multiply: compute table offset
	ld wa, (xsp + 38)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 40)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	; Table lookup via 0x29811C
	ldada_24 xwa, 2102874	; 0x20165A
	add xwa, xhl
	ld xbc, xwa
	ld xwa, (xsp + 10)
	ld xde, xbc
	ld xbc, 0x00000010
	call 0x29811C
	ld (xsp + 12), hl	; save result
	; Check workspace byte
	cpmi8 (xsp + 29), 0x08
	jr nz, .Lts8b1_skip
	; Set flag and override
	ldmw (xsp + 4), 0x0001
	ld xwa, 0x00001EB0
	ld (xsp + 34), xwa
.Lts8b1_skip:
	; Workspace dispatch (d8 0x1C)
	ldda32_24 xwa, 2335138	; 0x23A1A2
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld xhl, (xwa + 28)	; (XWA+0x1C)
	call (xhl)
	; Save workspace and params ptrs
	lda xwa, (xsp + 30)
	ld (xsp + 6), xwa
	lda xwa, (xsp + 34)
	ld (xsp + 10), xwa
	; Third multiply: compute table offset
	ld wa, (xsp + 38)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 40)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	; Table update via 0x29811C (with double dereference)
	ldada_24 xwa, 2102874	; 0x20165A
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa)
	ld xbc, (xsp + 10)
	ld xbc, (xbc)
	call 0x29811C
	ld (xsp + 12), hl	; save result
	; Check flag
	cpmi16 (xsp + 4), 0x0001
	jr nz, .Lts8b1_final
	; Conditional: store 0x50 and call 0x29AE9F
	ldmi8 (xsp + 29), 0x50
	pushw 0x0010
	lda xwa, (xsp + 16)
	push xwa
	ld xwa, (xsp + 36)
	push xwa
	call 0x29AE9F
	lda xsp, (xsp + 10)	; cleanup pushed args
.Lts8b1_final:
	; Final workspace dispatch
	ld wa, (xsp + 12)
	ldda32_24 xbc, 2335138	; 0x23A1A2
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld xhl, (xbc + 32)	; (XBC+0x20)
	call (xhl)
.Lts8b1_load:
	ld hl, (xsp + 12)
	pop xiz
	lda xsp, (xsp + 38)
	ret

HDAE5000_Table_Sub_290A00:	; 0x290A00 (390 bytes)
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 28), bc	; save file number
	ld (xsp + 30), wa	; save partition
	ldmw (xsp + 10), 0x0000	; init result = 0
	; First multiply: compute table offset
	ld wa, (xsp + 28)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	; Check if entry exists
	ldada_24 xwa, 2102878	; 0x20165E (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts0a0_load	; entry doesn't exist
	; Workspace dispatch WA=3 (buffer at xsp+20)
	lda xwa, (xsp + 20)
	ld xbc, xwa
	ldda32_24 xwa, 2335138	; 0x23A1A2
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 3
	call (xhl)
	; Workspace dispatch WA=4 (buffer at xsp+12)
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 4
	call (xhl)
	; Save workspace ptr
	ldada_24 xwa, 2297628	; 0x230F1C
	ld (xsp + 8), xwa
	; Second multiply: compute table offset
	ld wa, (xsp + 28)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	; Table lookup via 0x29811C
	ldada_24 xwa, 2102878	; 0x20165E
	add xwa, xhl
	ld xbc, xwa
	ld xwa, (xsp + 8)
	ld xde, xbc
	ld xbc, 0x00005000
	call 0x29811C
	; Check result
	cp hl, 0xFFFF
	jr nz, .Lts0a0_process
	ldw hl, 0xFFFF
	jrl .Lts0a0_exit	; skip result load
.Lts0a0_process:
	; Compute slot address from workspace data
	ldada_24 xwa, 2297628	; 0x230F1C
	ld_srib3 e, 0xE1, 0xC7, 0x00	; ld E, (XWA+0x00C7)
	ldada_24 xwa, 2297628	; 0x230F1C
	ld xbc, xwa
	ld a, e
	extz wa
	sla wa, 10
	exts xwa
	add xwa, xwa
	add xbc, xwa
	lda xwa, (xbc + 78)	; XBC + 0x4E
	ld xbc, xwa
	ld wa, (xbc)
	extz xwa
	ld (xsp + 4), xwa
	sll xwa, 4
	ld (xsp + 4), xwa
	ld xwa, (xsp + 24)
	add (xsp + 4), xwa	; add workspace value to slot
	; Workspace dispatch (d8 0x2C)
	ldda32_24 xwa, 2335138	; 0x23A1A2
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld xhl, (xwa + 44)	; (XWA+0x2C)
	call (xhl)
	; Save ptr
	lda xwa, (xsp + 20)
	ld (xsp + 8), xwa
	; Third multiply: compute table offset
	ld wa, (xsp + 28)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	; Table update via 0x29811C
	ldada_24 xwa, 2102878	; 0x20165E
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xwa, (xwa)
	ld xbc, (xsp + 4)
	call 0x29811C
	ld (xsp + 10), hl	; save result
	; Final workspace dispatch at (XBC+0x30)
	ld wa, (xsp + 10)
	ldda32_24 xbc, 2335138	; 0x23A1A2
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld xhl, (xbc + 48)	; (XBC+0x30)
	call (xhl)
	; Extra function call via workspace chain
	ldda32_24 xwa, 2335138	; 0x23A1A2
	ld_sril3 xwa, 0xE1, 0xFA, 0x11	; ld XWA, (XWA+0x11FA)
	ld xhl, (xwa + 24)	; (XWA+0x18)
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x01C00013
	lds32 xde, 0
	call (xhl)
.Lts0a0_load:
	ld hl, (xsp + 10)
.Lts0a0_exit:
	pop xiz
	lda xsp, (xsp + 28)
	ret

HDAE5000_Table_Sub_290B86:	; 0x290B86 (303 bytes)
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), bc	; save file number
	ld (xsp + 22), wa	; save partition
	ldmw (xsp + 10), 0x0000	; init result = 0
	; 1st multiply: check entry existence
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102882	; 0x201662 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts90b_load
	; Workspace dispatch with WA=5
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldda32_24 xwa, 2335138	; workspace ptr
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00	; (XWA+0x0080)
	lds wa, 5
	call (xhl)
	ldada_24 xwa, 2297628	; 0x230F1C
	ld (xsp + 8), xwa
	; 2nd multiply: table lookup
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102882	; 0x201662
	add xwa, xhl
	ld xbc, xwa
	ld xwa, (xsp + 8)
	ld xde, xbc
	ld xbc, 0x00000200
	call 0x29811C
	cp hl, 0xFFFF
	jr nz, .Lts90b_ok
	ldw hl, 0xFFFF
	jr .Lts90b_exit
.Lts90b_ok:
	; Load workspace param and shift
	ldada_24 xwa, 2297628	; 0x230F1C
	ld wa, (xwa + 46)	; workspace offset 0x2E
	extz xwa
	ld (xsp + 4), xwa
	sll xwa, 4
	ld (xsp + 4), xwa
	; Dispatch workspace handler
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld xhl, (xwa + 60)	; handler at offset 0x3C
	call (xhl)
	; 3rd multiply: final table lookup
	lda xwa, (xsp + 12)
	ld (xsp + 8), xwa
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102882	; 0x201662
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xwa, (xwa)
	ld xbc, (xsp + 4)
	call 0x29811C
	ld (xsp + 10), hl
	; Post-processing dispatch
	ld wa, (xsp + 10)
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld xhl, (xbc + 64)	; post offset 0x40
	call (xhl)
.Lts90b_load:
	ld hl, (xsp + 10)	; load result
.Lts90b_exit:
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_Table_Sub_290CB5:	; 0x290CB5 (220 bytes)
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), bc
	ld (xsp + 22), wa
	ldmw (xsp + 10), 0x0000	; init result = 0
	; Check if table entry exists
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102886	; 0x201666
	add xwa, xhl
	ld xwa, (xwa)		; load table entry
	cp xwa, 0xFFFFFFFF	; empty?
	jrl z, .Lts90c_exit	; skip all if -1
	; Workspace dispatch 1
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 6
	call (xhl)
	ld xwa, 0x000072AA
	ld (xsp + 16), xwa
	; Workspace dispatch 2
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld xhl, (xwa + 76)	; (XWA+0x4C)
	call (xhl)
	; Table lookup
	lda xwa, (xsp + 12)
	ld (xsp + 4), xwa
	lda xwa, (xsp + 16)
	ld (xsp + 8), xwa
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102886	; 0x201666
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)
	call 0x29811C		; write entry
	ld (xsp + 10), hl	; save result
	; Post-processing
	ld wa, (xsp + 10)
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld xhl, (xbc + 80)	; (XBC+0x50)
	call (xhl)
.Lts90c_exit:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_Table_Sub_290D91:	; 0x290D91 (303 bytes)
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), bc
	ld (xsp + 22), wa
	ldmw (xsp + 10), 0x0000
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102890	; 0x20166A (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts90d_load
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 7
	call (xhl)
	ldada_24 xwa, 2297628
	ld (xsp + 8), xwa
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102890	; 0x20166A
	add xwa, xhl
	ld xbc, xwa
	ld xwa, (xsp + 8)
	ld xde, xbc
	ld xbc, 0x00000200
	call 0x29811C
	cp hl, 0xFFFF
	jr nz, .Lts90d_ok
	ldw hl, 0xFFFF
	jr .Lts90d_exit
.Lts90d_ok:
	ldada_24 xwa, 2297628
	ld wa, (xwa + 28)	; workspace offset 0x1C
	extz xwa
	ld (xsp + 4), xwa
	sll xwa, 4
	ld (xsp + 4), xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld xhl, (xwa + 92)	; handler at offset 0x5C
	call (xhl)
	lda xwa, (xsp + 12)
	ld (xsp + 8), xwa
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102890	; 0x20166A
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xwa, (xwa)
	ld xbc, (xsp + 4)
	call 0x29811C
	ld (xsp + 10), hl
	ld wa, (xsp + 10)
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld xhl, (xbc + 96)	; post offset 0x60
	call (xhl)
.Lts90d_load:
	ld hl, (xsp + 10)
.Lts90d_exit:
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_Table_Sub_290EC0:	; 0x290EC0 (133 bytes)
	dec 4, xsp		; allocate 4 bytes on stack
	push xiz		; save XIZ
	ld (xsp + 4), bc	; save BC (file number param)
	ld (xsp + 6), wa	; save WA (partition param)
	ld wa, (xsp + 4)	; WA = file number
	extz xwa		; zero-extend to 32-bit
	ld xbc, 0x0000004C	; multiplier = 76
	call 0x29B72D		; multiply XWA * XBC
	ld xiz, xhl		; XIZ = file_number * 76
	ld wa, (xsp + 6)	; WA = partition
	extz xwa		; zero-extend to 32-bit
	ld xbc, 0x000004C0	; multiplier = 1216
	call 0x29B72D		; multiply XWA * XBC
	add xhl, 0x780		; XHL += 1920 (header offset)
	add xhl, xiz		; XHL += file_number * 76
	ldada_24 xwa, 2102894	; XWA = 0x20166E (table base)
	add xwa, xhl		; XWA = base + computed offset
	ld xwa, (xwa)		; XWA = table entry value
	cp xwa, 0xFFFFFFFF	; empty entry?
	jr z, .Lts290_exit	; skip if -1
	ld xiy, 0x002F8DD8	; destination for ldirw
	ld xix, 0x00238F1C	; source for ldirw
	lds bc, 4		; count = 4 words (8 bytes)
	mriw2 0x95, 0x11	; ldirw — copy from XIX to XIY
	ld wa, (xsp + 6)	; reload partition
	stda16_24 2330398, xwa	; ld (0x238F1E), WA
	ld wa, (xsp + 4)	; reload file number
	stda16_24 2330400, xwa	; ld (0x238F20), WA
	ldada_24 xwa, 2703254	; XWA = 0x293F96 (function ptr 1)
	ld xde, xwa		; XDE = function ptr 1
	ldada_24 xwa, 2703692	; XWA = 0x29414C (function ptr 2)
	ld xbc, xwa		; XBC = function ptr 2
	ld xwa, xde		; XWA = function ptr 1
	ldda32_24 xde, 2335138	; XDE = (0x23A1A2) workspace ptr
	ld_sril3 xde, 0xE9, 0x88, 0x0E	; XDE = (XDE+0x0E88)
	ld_sril3 xhl, 0xE9, 0xB0, 0x00	; XHL = (XDE+0x00B0) handler
	call (xhl)		; dispatch handler
.Lts290_exit:
	lds hl, 0		; return 0
	pop xiz			; restore XIZ
	inc 4, xsp		; deallocate 4 bytes
	ret

HDAE5000_Table_Sub_290F45:	; 0x290F45 (248 bytes)
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), bc	; save file number
	ld (xsp + 22), wa	; save partition
	ldmw (xsp + 10), 0x0000	; init result = 0
	; First multiply: compute table offset
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	; Check if entry exists
	ldada_24 xwa, 2102898	; 0x201672 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lts90f_load	; entry doesn't exist, result stays 0
	; Workspace dispatch with WA=9
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldda32_24 xwa, 2335138	; 0x23A1A2
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; (XWA+0x0E88)
	ld_sril3 xhl, 0xE1, 0x80, 0x00	; (XWA+0x0080)
	ldw wa, 0x0009
	call (xhl)
	; Another workspace dispatch (d8 displacement)
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld xhl, (xwa + 108)	; (XWA+0x6C)
	call (xhl)
	; Save workspace ptr and buffer ptr
	ldada_24 xwa, 2297628	; 0x230F1C
	ld (xsp + 4), xwa
	lda xwa, (xsp + 16)
	ld (xsp + 8), xwa
	; Second multiply: compute table offset
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	; Table lookup via 0x29811C
	ldada_24 xwa, 2102898	; 0x201672
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)		; dereference buffer ptr
	call 0x29811C
	ld (xsp + 10), hl	; save result
	; Post-processing: push arg and dispatch
	ldada_24 xwa, 2297628	; 0x230F1C
	ld xbc, xwa
	ld xwa, (xsp + 16)
	ld de, wa
	ld xwa, 0x003D3000
	push xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld xhl, (xwa + 124)	; (XWA+0x7C)
	lds wa, 1
	call (xhl)
	; Read result and call final handler
	ld wa, (xsp + 10)
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld xhl, (xbc + 112)	; (XBC+0x70)
	call (xhl)
.Lts90f_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_Table_Sub_29103D:	; 0x29103D (1023 bytes)
	.incbin "includes/code_28f90c_2953e1.bin", 5937, 1023

HDAE5000_Table_Init_Entry:	; 0x29143C (359 bytes)
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 28), bc	; save file number
	ld (xsp + 30), wa	; save partition
	; Workspace dispatch with WA=0 (buffer at xsp+20)
	lda xwa, (xsp + 20)
	ld xbc, xwa
	ldda32_24 xwa, 2335138	; 0x23A1A2
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; (XWA+0x0E88)
	ld_sril3 xhl, 0xE1, 0x80, 0x00	; (XWA+0x0080)
	lds wa, 0
	call (xhl)
	; Workspace dispatch with WA=1 (buffer at xsp+12)
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 1
	call (xhl)
	; Compute arg and call Cell_Get_Params
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 4), xhl
	; Workspace dispatch (d8 displacement 0x14)
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld xhl, (xwa + 20)	; (XWA+0x14)
	call (xhl)
	; Call 0x29AEC7 with args
	ld xwa, (xsp + 4)
	pushw wa
	pushw 0x0000
	ldada_24 xwa, 2297628	; 0x230F1C
	push xwa
	call 0x29AEC7
	; Call 0x29AE9F with args (first)
	ld xwa, (xsp + 32)
	pushw wa
	ld xwa, (xsp + 30)
	push xwa
	ldada_24 xwa, 2297628	; 0x230F1C
	push xwa
	call 0x29AE9F
	; Call 0x29AE9F with args (second)
	ld xwa, (xsp + 34)
	pushw wa
	ld xwa, (xsp + 32)
	push xwa
	ldada_24 xwa, 2297628	; 0x230F1C
	add xwa, (xsp + 48)
	push xwa
	call 0x29AE9F
	lda xsp, (xsp + 28)	; clean up pushed args
	; Store metadata at 0x230F1C + offset
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	ld xbc, 0x00230F1C
	add xbc, xwa
	ldda8_24 a, 2274036	; 0x22B2F4
	ld (xbc), a
	; Store at offset+1
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	inc 1, xwa
	ld xbc, 0x00230F1C
	add xbc, xwa
	ldda8_24 a, 2334880	; 0x23A0A0
	ld (xbc), a
	; Store at offset+2
	ld xwa, (xsp + 16)
	add xwa, (xsp + 24)
	inc 2, xwa
	ld xbc, 0x00230F1C
	add xbc, xwa
	ldda8_24 a, 2334878	; 0x23A09E
	ld (xbc), a
	; Save workspace ptr
	ldada_24 xwa, 2297628	; 0x230F1C
	ld (xsp + 8), xwa
	; Multiply: compute table offset
	ld wa, (xsp + 28)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	; Table lookup
	ldada_24 xwa, 2102870	; 0x201656 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	call 0x297E16
	ld (xsp + 10), hl	; save result
	ld wa, (xsp + 10)
	cp wa, 0xFFFF
	jr z, .Lti914_flag_done
	; Set flag
	ld wa, (xsp + 28)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102860	; 0x20164C (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x01
.Lti914_flag_done:
	; Final workspace dispatch
	ld wa, (xsp + 10)
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld xhl, (xbc + 24)	; (XBC+0x18)
	call (xhl)
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 28)
	ret

HDAE5000_Table_Sub_2915A3:	; 0x2915A3 (217 bytes)
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), bc
	ld (xsp + 22), wa
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 2		; operation code = 2
	call (xhl)
	ld xwa, (xsp + 16)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 16), xhl	; save result
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld xhl, (xwa + 36)	; (XWA+0x24)
	call (xhl)
	lda xwa, (xsp + 12)
	ld (xsp + 4), xwa
	lda xwa, (xsp + 16)
	ld (xsp + 8), xwa
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102874	; 0x20165A
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)
	call 0x297E16
	ld (xsp + 10), hl
	ld wa, (xsp + 10)
	cp wa, 0xFFFF
	jr z, .Lts915_post
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102861	; 0x20164D
	add xwa, xhl
	ldmi8 (xwa), 0x01
.Lts915_post:
	ld wa, (xsp + 10)
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld xhl, (xbc + 40)	; (XBC+0x28)
	call (xhl)
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_Table_Sub_29167C:	; 0x29167C (226 bytes)
	lda xsp, (xsp - 30)	; larger stack frame
	push xiz
	ld (xsp + 30), bc	; save file number
	ld (xsp + 32), wa	; save partition
	; Workspace dispatch 1: buffer at XSP+22
	lda xwa, (xsp + 22)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 3		; operation code = 3
	call (xhl)
	; Workspace dispatch 2: buffer at XSP+14
	lda xwa, (xsp + 14)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 4		; operation code = 4
	call (xhl)
	; Workspace dispatch 3: compute address
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld xix, (xwa + 52)	; (XWA+0x34)
	call (xix)
	ld xwa, (xsp + 26)	; load base value
	add xwa, xhl		; add dispatch result
	ld (xsp + 6), xwa	; save computed address
	; Setup pointers
	lda xwa, (xsp + 22)
	ld (xsp + 10), xwa
	; Table lookup
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102878	; 0x20165E
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xwa, (xwa)
	ld xbc, (xsp + 6)
	call 0x297E16
	cp hl, 0xFFFF		; check result (HL, not WA)
	jr z, .Lts916_post	; skip flag if failed
	; Recompute for flag table
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102862	; 0x20164E
	add xwa, xhl
	ldmi8 (xwa), 0x01
.Lts916_post:
	ld wa, (xsp + 4)	; WA = result param
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld xhl, (xbc + 56)	; (XBC+0x38)
	call (xhl)
	ld hl, (xsp + 4)	; HL = result
	pop xiz
	lda xsp, (xsp + 30)	; deallocate 30 bytes
	ret

HDAE5000_Table_Sub_29175E:	; 0x29175E (211 bytes)
	lda xsp, (xsp - 20)	; allocate 20 bytes
	push xiz
	ld (xsp + 20), bc	; save file number
	ld (xsp + 22), wa	; save partition
	lda xwa, (xsp + 12)
	ld xbc, xwa		; XBC = buffer addr
	ldda32_24 xwa, 2335138	; workspace ptr
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 5		; operation code = 5
	call (xhl)
	ldda32_24 xwa, 2335138	; reload workspace
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld xix, (xwa + 68)	; (XWA+0x44)
	call (xix)
	ld (xsp + 16), xhl	; save dispatch result
	lda xwa, (xsp + 12)
	ld (xsp + 4), xwa
	lda xwa, (xsp + 16)
	ld (xsp + 8), xwa
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102882	; 0x201662
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)
	call 0x297E16
	ld (xsp + 10), hl
	ld wa, (xsp + 10)
	cp wa, 0xFFFF
	jr z, .Lts917_post
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102863	; 0x20164F
	add xwa, xhl
	ldmi8 (xwa), 0x01
.Lts917_post:
	ld wa, (xsp + 10)
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld xhl, (xbc + 72)	; (XBC+0x48)
	call (xhl)
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_Table_Sub_291831:	; 0x291831 (216 bytes)
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 20), bc
	ld (xsp + 22), wa
	lda xwa, (xsp + 12)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 6		; operation code = 6
	call (xhl)
	ld xwa, 0x000072AA	; constant for XSP+16
	ld (xsp + 16), xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld xhl, (xwa + 84)	; (XWA+0x54)
	call (xhl)
	lda xwa, (xsp + 12)
	ld (xsp + 4), xwa
	lda xwa, (xsp + 16)
	ld (xsp + 8), xwa
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102886	; 0x201666
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)
	call 0x297E16
	ld (xsp + 10), hl
	ld wa, (xsp + 10)
	cp wa, 0xFFFF
	jr z, .Lts918_post
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102864	; 0x201650
	add xwa, xhl
	ldmi8 (xwa), 0x01
.Lts918_post:
	ld wa, (xsp + 10)
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld xhl, (xbc + 88)	; (XBC+0x58)
	call (xhl)
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_Table_Sub_291909:	; 0x291909 (211 bytes)
	lda xsp, (xsp - 20)	; allocate 20 bytes
	push xiz
	ld (xsp + 20), bc	; save file number
	ld (xsp + 22), wa	; save partition
	lda xwa, (xsp + 12)
	ld xbc, xwa		; XBC = buffer addr
	ldda32_24 xwa, 2335138	; workspace ptr
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 7		; operation code = 7
	call (xhl)
	ldda32_24 xwa, 2335138	; reload workspace
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld xix, (xwa + 100)	; (XWA+0x64)
	call (xix)
	ld (xsp + 16), xhl	; save dispatch result
	lda xwa, (xsp + 12)
	ld (xsp + 4), xwa
	lda xwa, (xsp + 16)
	ld (xsp + 8), xwa
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102890	; 0x20166A
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)
	call 0x297E16
	ld (xsp + 10), hl
	ld wa, (xsp + 10)
	cp wa, 0xFFFF
	jr z, .Lts919b_post
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102865	; 0x201651
	add xwa, xhl
	ldmi8 (xwa), 0x01
.Lts919b_post:
	ld wa, (xsp + 10)
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld xhl, (xbc + 104)	; (XBC+0x68)
	call (xhl)
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 20)
	ret

HDAE5000_Table_Sub_2919DC:	; 0x2919DC (134 bytes)
	push xiz		; save XIZ
	ld de, bc		; DE = BC (file number param)
	lds hl, 0		; HL = 0
	ld xiy, 0x002F8DD8	; destination for ldirw
	ld xix, 0x00238F1C	; source for ldirw
	lds bc, 4		; count = 4 words
	mriw2 0x95, 0x11	; ldirw — copy from XIX to XIY
	stda16_24 2330398, xwa	; ld (0x238F1E), WA — partition
	stda16_24 2330400, xde	; ld (0x238F20), DE — file number
	ldda16_24 xwa, 2330400	; WA = (0x238F20) file number
	extz xwa		; zero-extend to 32-bit
	ld xbc, 0x0000004C	; multiplier = 76
	call 0x29B72D		; multiply
	ld xiz, xhl		; XIZ = file_number * 76
	ldda16_24 xwa, 2330398	; WA = (0x238F1E) partition
	extz xwa		; zero-extend to 32-bit
	ld xbc, 0x000004C0	; multiplier = 1216
	call 0x29B72D		; multiply
	add xhl, 0x780		; XHL += 1920 (header offset)
	add xhl, xiz		; XHL += file_number * 76
	ldada_24 xwa, 2102894	; XWA = 0x20166E (table base)
	add xwa, xhl		; XWA = base + computed offset
	calr HDAE5000_Display_Sub_294273
	ld wa, hl		; WA = result
	cp wa, 0xFFFF		; check for failure
	jr z, .Lts919_exit	; skip if failed
	ldada_24 xwa, 2703698	; XWA = 0x294152
	ld xhl, xwa		; XHL = handler 1
	ldada_24 xwa, 2703465	; XWA = 0x294069
	ld xbc, xwa		; XBC = handler 2
	ldada_24 xwa, 2703692	; XWA = 0x29414C
	ld xde, xwa		; XDE = handler 3
	ld xwa, xhl		; XWA = handler 1
	ldda32_24 xhl, 2335138	; XHL = (0x23A1A2) workspace ptr
	ld_sril3 xhl, 0xED, 0x88, 0x0E	; XHL = (XHL+0x0E88)
	ld_sril3 xix, 0xED, 0xB4, 0x00	; XIX = (XHL+0x00B4)
	call (xix)		; dispatch handler
	calr HDAE5000_Display_Sub_29429E
.Lts919_exit:
	pop xiz			; restore XIZ
	ret

HDAE5000_Table_Sub_291A62:	; 0x291A62 (209 bytes)
	lda xsp, (xsp - 20)	; allocate 20 bytes on stack
	push xiz		; save XIZ
	ld (xsp + 20), bc	; save BC param (file number)
	ld (xsp + 22), wa	; save WA param (partition)
	lda xwa, (xsp + 12)	; XWA = addr of local buffer
	ld xbc, xwa		; XBC = buffer address
	ldda32_24 xwa, 2335138	; XWA = (0x23A1A2) workspace ptr
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; XWA = (XWA+0x0E88)
	ld_sril3 xhl, 0xE1, 0x80, 0x00	; XHL = (XWA+0x0080) handler
	ldw wa, 0x0009		; WA = 9 (operation code)
	call (xhl)		; dispatch
	ldda32_24 xwa, 2335138	; reload workspace ptr
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; XWA = (XWA+0x0E88)
	ld xhl, (xwa + 116)	; XHL = (XWA+0x74) handler
	call (xhl)		; dispatch
	lda xwa, (xsp + 12)	; XWA = addr of local buffer
	ld (xsp + 4), xwa	; store buffer ptr
	lda xwa, (xsp + 16)	; XWA = addr of result area
	ld (xsp + 8), xwa	; store result ptr
	ld wa, (xsp + 20)	; WA = file number
	extz xwa
	ld xbc, 0x0000004C	; multiplier = 76
	call 0x29B72D		; multiply
	ld xiz, xhl		; XIZ = file_number * 76
	ld wa, (xsp + 22)	; WA = partition
	extz xwa
	ld xbc, 0x000004C0	; multiplier = 1216
	call 0x29B72D		; multiply
	add xhl, 0x780		; XHL += 1920
	add xhl, xiz		; XHL += file_number * 76
	ldada_24 xwa, 2102898	; XWA = 0x201672 (table base)
	add xwa, xhl		; XWA = base + offset
	ld xde, xwa		; XDE = table address
	ld xwa, (xsp + 4)	; XWA = buffer ptr
	ld xwa, (xwa)		; dereference
	ld xbc, (xsp + 8)	; XBC = result ptr
	ld xbc, (xbc)		; dereference
	call 0x297E16		; compare/process
	ld (xsp + 10), hl	; save HL result
	ld wa, (xsp + 10)	; WA = result
	cp wa, 0xFFFF		; check for failure
	jr z, .Lts91a_post	; skip if failed
	ld wa, (xsp + 20)	; WA = file number (reload)
	extz xwa
	ld xbc, 0x0000004C	; multiplier = 76
	call 0x29B72D		; multiply
	ld xiz, xhl		; XIZ = file_number * 76
	ld wa, (xsp + 22)	; WA = partition (reload)
	extz xwa
	ld xbc, 0x000004C0	; multiplier = 1216
	call 0x29B72D		; multiply
	add xhl, 0x780		; XHL += 1920
	add xhl, xiz		; XHL += file_number * 76
	ldada_24 xwa, 2102867	; XWA = 0x201653 (flag table)
	add xwa, xhl		; XWA = base + offset
	ldmi8 (xwa), 0x01	; set flag byte to 1
.Lts91a_post:
	ld wa, (xsp + 10)	; WA = result (param for handler)
	ldda32_24 xbc, 2335138	; XBC = (0x23A1A2) workspace ptr
	ld_sril3 xbc, 0xE5, 0x88, 0x0E	; XBC = (XBC+0x0E88)
	ld xhl, (xbc + 120)	; XHL = (XBC+0x78) handler
	call (xhl)		; dispatch
	ld hl, (xsp + 10)	; HL = result
	pop xiz			; restore XIZ
	lda xsp, (xsp + 20)	; deallocate 20 bytes
	ret

HDAE5000_Table_Sub_291B33:	; 0x291B33 (171 bytes)
	lda xsp, (xsp - 20)	; allocate 20 bytes on stack
	push xiz		; save XIZ
	ld (xsp + 20), bc	; save BC param (file number)
	ld (xsp + 22), wa	; save WA param (partition)
	lda xwa, (xsp + 12)	; XWA = addr of local buffer
	ld xbc, xwa		; XBC = buffer address
	ldw wa, 0x000A		; WA = 10 (string length)
	calr HDAE5000_Table_Sub_291BDE	; init table entry
	ld xwa, (xsp + 16)	; XWA = param block
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 16), xhl	; save result XHL
	lda xwa, (xsp + 12)	; XWA = addr of local buffer
	ld (xsp + 4), xwa	; store buffer ptr
	lda xwa, (xsp + 16)	; XWA = addr of result
	ld (xsp + 8), xwa	; store result ptr
	ld wa, (xsp + 20)	; WA = file number
	extz xwa
	ld xbc, 0x0000004C	; multiplier = 76
	call 0x29B72D		; multiply
	ld xiz, xhl		; XIZ = file_number * 76
	ld wa, (xsp + 22)	; WA = partition
	extz xwa
	ld xbc, 0x000004C0	; multiplier = 1216
	call 0x29B72D		; multiply
	add xhl, 0x780		; XHL += 1920
	add xhl, xiz		; XHL += file_number * 76
	ldada_24 xwa, 2102902	; XWA = 0x201676 (table base)
	add xwa, xhl		; XWA = base + offset
	ld xde, xwa		; XDE = table address
	ld xwa, (xsp + 4)	; XWA = buffer ptr
	ld xwa, (xwa)		; dereference
	ld xbc, (xsp + 8)	; XBC = result ptr
	ld xbc, (xbc)		; dereference
	call 0x297E16		; compare/process
	ld (xsp + 10), hl	; save HL result
	ld wa, (xsp + 10)	; WA = result
	cp wa, 0xFFFF		; check for failure
	jr z, .Lts91b_exit	; skip if failed
	ld wa, (xsp + 20)	; WA = file number (reload)
	extz xwa
	ld xbc, 0x0000004C	; multiplier = 76
	call 0x29B72D		; multiply
	ld xiz, xhl		; XIZ = file_number * 76
	ld wa, (xsp + 22)	; WA = partition (reload)
	extz xwa
	ld xbc, 0x000004C0	; multiplier = 1216
	call 0x29B72D		; multiply
	add xhl, 0x780		; XHL += 1920
	add xhl, xiz		; XHL += file_number * 76
	ldada_24 xwa, 2102868	; XWA = 0x201654 (flag table)
	add xwa, xhl		; XWA = base + offset
	ldmi8 (xwa), 0x01	; set flag byte to 1
.Lts91b_exit:
	ld hl, (xsp + 10)	; HL = result
	pop xiz			; restore XIZ
	lda xsp, (xsp + 20)	; deallocate 20 bytes
	ret

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
	lda xsp, (xsp - 42)
	push xiz
	ld (xsp + 42), bc	; save file number
	ld (xsp + 44), wa	; save partition
	ldmw (xsp + 10), 0x0000	; init result = 0
	; Call 0x29AE9F with args
	pushw 0x0008
	push xde
	lda xwa, (xsp + 18)
	push xwa
	call 0x29AE9F
	; Call 0x29AF45 with args
	pushw 0x002F
	pushw 0x8F08
	lda xwa, (xsp + 34)
	push xwa
	call 0x29AF45
	lda xsp, (xsp + 18)	; cleanup 18 bytes
	; Workspace dispatch WA=0 (buffer at xsp+34)
	lda xwa, (xsp + 34)
	ld xbc, xwa
	ldda32_24 xwa, 2335138	; 0x23A1A2
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 0
	call (xhl)
	; Workspace dispatch WA=1 (buffer at xsp+26)
	lda xwa, (xsp + 26)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 1
	call (xhl)
	; Cell_Get_Params
	ld xwa, (xsp + 30)
	add xwa, (xsp + 38)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 4), xhl
	; Call workspace handler via XIX chain
	lda xwa, (xsp + 12)
	ldada_24 xbc, 3116814	; 0x2F8F0E
	ldda32_24 xde, 2335138	; 0x23A1A2
	ld_sril3 xde, 0xE9, 0x88, 0x0E
	ld_sril3 xix, 0xE9, 0xA0, 0x00
	call (xix)
	; Check if result < 0
	cps hl, 0
	jrl lt, .Lts488_error
	; Workspace dispatch via XDE chain at 0xA8
	ldada_24 xwa, 2297628	; 0x230F1C
	ld xbc, (xsp + 4)
	ldda32_24 xde, 2335138
	ld_sril3 xde, 0xE9, 0x88, 0x0E
	ld_sril3 xhl, 0xE9, 0xA8, 0x00
	call (xhl)
	; Write metadata: store 0x00, 0x10, 0x00 at workspace+offset
	ld xwa, (xsp + 30)
	add xwa, (xsp + 38)
	ld xbc, 0x00230F1C
	add xbc, xwa
	ldmi8 (xbc), 0x00
	; offset+1: store 0x10
	ld xwa, (xsp + 30)
	add xwa, (xsp + 38)
	inc 1, xwa
	ld xbc, 0x00230F1C
	add xbc, xwa
	ldmi8 (xbc), 0x10
	; offset+2: store 0x00
	ld xwa, (xsp + 30)
	add xwa, (xsp + 38)
	inc 2, xwa
	ld xbc, 0x00230F1C
	add xbc, xwa
	ldmi8 (xbc), 0x00
	; Save workspace ptr
	ldada_24 xwa, 2297628	; 0x230F1C
	ld (xsp + 8), xwa
	; First multiply: compute table offset
	ld wa, (xsp + 42)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 44)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	; Table write via 0x297E16
	ldada_24 xwa, 2102870	; 0x201656 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	call 0x297E16
	ld (xsp + 10), hl	; save result
	; Second multiply: compute table offset
	ld wa, (xsp + 42)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 44)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	; Set flag byte to 1
	ldada_24 xwa, 2102860	; 0x20164C (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x01
	; Final workspace dispatch at 0xAC
	ldda32_24 xwa, 2335138	; 0x23A1A2
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0xAC, 0x00
	call (xhl)
	jr .Lts488_done
.Lts488_error:
	ldmw (xsp + 10), 0xFFFF
.Lts488_done:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 42)
	ret

HDAE5000_Table_Sub_2925EF:	; 0x2925EF (425 bytes)
	lda xsp, (xsp - 30)
	push xiz
	ld (xsp + 30), bc	; save file number
	ld (xsp + 32), wa	; save partition
	ldmw (xsp + 14), 0x0000	; init result = 0
	; Call 0x29AE9F with args
	pushw 0x0008
	push xde
	lda xwa, (xsp + 22)
	push xwa
	call 0x29AE9F
	; Call 0x29AF45 with args
	pushw 0x002F
	pushw 0x8F12
	lda xwa, (xsp + 38)
	push xwa
	call 0x29AF45
	lda xsp, (xsp + 18)	; clean up pushed args
	; First workspace dispatch
	lda xwa, (xsp + 16)
	ldada_24 xbc, 3116824	; 0x2F8F18
	ldda32_24 xde, 2335138	; workspace ptr (0x23A1A2)
	ld_sril3 xde, 0xE9, 0x88, 0x0E	; (XDE+0x0E88)
	ld_sril3 xix, 0xE9, 0xA0, 0x00	; (XDE+0x00A0)
	call (xix)
	; Check result
	cps hl, 0
	jr ge, .Lts925_1
	ldw hl, 0xFFFF
	jrl .Lts925_exit
.Lts925_1:
	; Second workspace dispatch
	ldada_24 xwa, 2297628	; 0x230F1C
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E	; (XBC+0x0E88)
	ld_sril3 xhl, 0xE5, 0xA8, 0x00	; (XBC+0x00A8)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 4), xhl
	ldada_24 xwa, 2297628	; 0x230F1C
	ld (xsp + 8), xwa
	ld xwa, (xsp + 4)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 12), xhl
	; Multiply: compute table offset
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	; Table lookup
	ldada_24 xwa, 2102874	; 0x20165A (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 12)
	call 0x297E16
	ld (xsp + 14), hl	; store result
	ld wa, (xsp + 14)	; reload for compare
	cp wa, 0xFFFF
	jr nz, .Lts925_2
	ldw hl, 0xFFFF
	jrl .Lts925_exit
.Lts925_2:
	; Check if dispatch returned 0x8000
	ld xwa, (xsp + 4)
	cp xwa, 0x00008000
	jrl nz, .Lts925_5
.Lts925_loop:
	; Re-dispatch
	ldada_24 xwa, 2297628	; 0x230F1C
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld_sril3 xhl, 0xE5, 0xA8, 0x00
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	cp xwa, 0x00000000
	jr le, .Lts925_4
	; Retry with new params
	ldada_24 xwa, 2297628	; 0x230F1C
	ld (xsp + 8), xwa
	ld xwa, (xsp + 4)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 12), xhl
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102874	; 0x20165A
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 12)
	call 0x297FD1
	ld (xsp + 14), hl
	ld wa, (xsp + 14)
	cp wa, 0xFFFF
	jr z, .Lts925_5
.Lts925_4:
	ld xwa, (xsp + 4)
	cp xwa, 0x00008000
	jrl z, .Lts925_loop
.Lts925_5:
	; Post-processing: set flag
	ld wa, (xsp + 30)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102861	; 0x20164D (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x01
	; Final workspace dispatch
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; (XWA+0x0E88)
	ld_sril3 xhl, 0xE1, 0xAC, 0x00	; (XWA+0x00AC)
	call (xhl)
	ld hl, (xsp + 14)	; normal exit: load result
.Lts925_exit:			; error exit: HL already set
	pop xiz
	lda xsp, (xsp + 30)
	ret

HDAE5000_Table_Sub_292798:	; 0x292798 (419 bytes)
	lda xsp, (xsp - 32)
	push xiz
	ld (xsp + 32), bc	; save file number
	ld (xsp + 34), wa	; save partition
	ldmw (xsp + 4), 0x0000	; init result = 0
	; Call 0x29AE9F with args
	pushw 0x0008
	push xde
	lda xwa, (xsp + 24)
	push xwa
	call 0x29AE9F
	; Call 0x29AF45 with args
	pushw 0x002F
	pushw 0x8F1C
	lda xwa, (xsp + 40)
	push xwa
	call 0x29AF45
	lda xsp, (xsp + 18)	; clean up pushed args
	; First workspace dispatch
	lda xwa, (xsp + 18)
	ldada_24 xbc, 3116834	; 0x2F8F22
	ldda32_24 xde, 2335138	; workspace ptr (0x23A1A2)
	ld_sril3 xde, 0xE9, 0x88, 0x0E	; (XDE+0x0E88)
	ld_sril3 xix, 0xE9, 0xA0, 0x00	; (XDE+0x00A0)
	call (xix)
	; Check result
	cps hl, 0
	jr ge, .Lts927_1
	ldw hl, 0xFFFF
	jrl .Lts927_exit
.Lts927_1:
	; Second workspace dispatch
	ldada_24 xwa, 2297628	; 0x230F1C
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E	; (XBC+0x0E88)
	ld_sril3 xhl, 0xE5, 0xA8, 0x00	; (XBC+0x00A8)
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	ldada_24 xwa, 2297628	; 0x230F1C
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 14), xhl
	; Multiply: compute table offset
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	; Table lookup
	ldada_24 xwa, 2102878	; 0x20165E (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call 0x297E16
	cp hl, 0xFFFF
	jr nz, .Lts927_2
	ldw hl, 0xFFFF
	jrl .Lts927_exit
.Lts927_2:
	; Check if dispatch returned 0x8000
	ld xwa, (xsp + 6)
	cp xwa, 0x00008000
	jrl nz, .Lts927_5
.Lts927_loop:
	; Re-dispatch
	ldada_24 xwa, 2297628	; 0x230F1C
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld_sril3 xhl, 0xE5, 0xA8, 0x00
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	cp xwa, 0x00000000
	jr le, .Lts927_4
	; Retry with new params
	ldada_24 xwa, 2297628	; 0x230F1C
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 14), xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102878	; 0x20165E
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call 0x297FD1
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	cp wa, 0xFFFF
	jr z, .Lts927_5
.Lts927_4:
	ld xwa, (xsp + 6)
	cp xwa, 0x00008000
	jrl z, .Lts927_loop
.Lts927_5:
	; Post-processing: set flag
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102862	; 0x20164E (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x01
	; Final workspace dispatch
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; (XWA+0x0E88)
	ld_sril3 xhl, 0xE1, 0xAC, 0x00	; (XWA+0x00AC)
	call (xhl)
	ld hl, (xsp + 4)	; normal exit: load result
.Lts927_exit:			; error exit: HL already set
	pop xiz
	lda xsp, (xsp + 32)
	ret

HDAE5000_Table_Sub_29293B:	; 0x29293B (419 bytes)
	lda xsp, (xsp - 32)
	push xiz
	ld (xsp + 32), bc
	ld (xsp + 34), wa
	ldmw (xsp + 4), 0x0000
	pushw 0x0008
	push xde
	lda xwa, (xsp + 24)
	push xwa
	call 0x29AE9F
	pushw 0x002F
	pushw 0x8F26
	lda xwa, (xsp + 40)
	push xwa
	call 0x29AF45
	lda xsp, (xsp + 18)
	lda xwa, (xsp + 18)
	ldada_24 xbc, 3116844	; 0x2F8F2C
	ldda32_24 xde, 2335138
	ld_sril3 xde, 0xE9, 0x88, 0x0E
	ld_sril3 xix, 0xE9, 0xA0, 0x00
	call (xix)
	cps hl, 0
	jr ge, .Lts929_1
	ldw hl, 0xFFFF
	jrl .Lts929_exit
.Lts929_1:
	ldada_24 xwa, 2297628	; 0x230F1C
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld_sril3 xhl, 0xE5, 0xA8, 0x00
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	ldada_24 xwa, 2297628
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 14), xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102882	; 0x201662 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call 0x297E16
	cp hl, 0xFFFF
	jr nz, .Lts929_2
	ldw hl, 0xFFFF
	jrl .Lts929_exit
.Lts929_2:
	ld xwa, (xsp + 6)
	cp xwa, 0x00008000
	jrl nz, .Lts929_5
.Lts929_loop:
	ldada_24 xwa, 2297628
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld_sril3 xhl, 0xE5, 0xA8, 0x00
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	cp xwa, 0x00000000
	jr le, .Lts929_4
	ldada_24 xwa, 2297628
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 14), xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102882	; 0x201662
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call 0x297FD1
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	cp wa, 0xFFFF
	jr z, .Lts929_5
.Lts929_4:
	ld xwa, (xsp + 6)
	cp xwa, 0x00008000
	jrl z, .Lts929_loop
.Lts929_5:
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102863	; 0x20164F (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x01
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0xAC, 0x00
	call (xhl)
	ld hl, (xsp + 4)
.Lts929_exit:
	pop xiz
	lda xsp, (xsp + 32)
	ret

HDAE5000_Table_Sub_292ADE:	; 0x292ADE (288 bytes)
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 34), bc	; save file number
	ld (xsp + 36), wa	; save partition
	ldmw (xsp + 10), 0x0000	; init result = 0
	; Call 0x29AE9F with args
	pushw 0x0008
	push xde
	lda xwa, (xsp + 18)
	push xwa
	call 0x29AE9F
	; Call 0x29AF45 with args
	pushw 0x002F
	pushw 0x8F30
	lda xwa, (xsp + 34)
	push xwa
	call 0x29AF45
	lda xsp, (xsp + 18)	; clean up pushed args
	; Workspace dispatch with WA=6
	lda xwa, (xsp + 26)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00	; (XWA+0x0080)
	lds wa, 6
	call (xhl)
	; Load constant and save
	ld xwa, 0x000072AA
	ld (xsp + 30), xwa
	; Second dispatch via XIX
	lda xwa, (xsp + 12)
	ldada_24 xbc, 3116852	; 0x2F8F34
	ldda32_24 xde, 2335138
	ld_sril3 xde, 0xE9, 0x88, 0x0E
	ld_sril3 xix, 0xE9, 0xA0, 0x00
	call (xix)
	cps hl, 0
	jrl lt, .Lts92a_error
	; Workspace dispatch: get handler
	ldada_24 xwa, 2297628	; 0x230F1C
	ld xbc, (xsp + 30)
	ldda32_24 xde, 2335138
	ld_sril3 xde, 0xE9, 0x88, 0x0E
	ld_sril3 xhl, 0xE9, 0xA8, 0x00	; (XDE+0x00A8)
	call (xhl)
	; Save workspace base and get cell params
	ldada_24 xwa, 2297628
	ld (xsp + 4), xwa
	ld xwa, (xsp + 30)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 8), xhl
	; Multiply: compute table offset
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 36)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	; Table lookup
	ldada_24 xwa, 2102886	; 0x201666 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xsp + 8)
	call 0x297E16
	ld (xsp + 10), hl
	; Set flag
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 36)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102864	; 0x201650 (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x01
	; Final workspace dispatch
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0xAC, 0x00	; (XWA+0x00AC)
	call (xhl)
	jr .Lts92a_load
.Lts92a_error:
	ldmw (xsp + 10), 0xFFFF	; error: result = -1
.Lts92a_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 34)
	ret

HDAE5000_Table_Sub_292BFE:	; 0x292BFE (280 bytes)
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 34), bc
	ld (xsp + 36), wa
	ldmw (xsp + 10), 0x0000
	pushw 0x0008
	push xde
	lda xwa, (xsp + 18)
	push xwa
	call 0x29AE9F
	pushw 0x002F
	pushw 0x8F38
	lda xwa, (xsp + 34)
	push xwa
	call 0x29AF45
	lda xsp, (xsp + 18)
	; Workspace dispatch with WA=7
	lda xwa, (xsp + 26)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 7
	call (xhl)
	; Second dispatch via XIX (no constant store)
	lda xwa, (xsp + 12)
	ldada_24 xbc, 3116862	; 0x2F8F3E
	ldda32_24 xde, 2335138
	ld_sril3 xde, 0xE9, 0x88, 0x0E
	ld_sril3 xix, 0xE9, 0xA0, 0x00
	call (xix)
	cps hl, 0
	jrl lt, .Lts92b_error
	ldada_24 xwa, 2297628
	ld xbc, (xsp + 30)
	ldda32_24 xde, 2335138
	ld_sril3 xde, 0xE9, 0x88, 0x0E
	ld_sril3 xhl, 0xE9, 0xA8, 0x00
	call (xhl)
	ldada_24 xwa, 2297628
	ld (xsp + 4), xwa
	ld xwa, (xsp + 30)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 8), xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 36)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102890	; 0x20166A (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xsp + 8)
	call 0x297E16
	ld (xsp + 10), hl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 36)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102865	; 0x201651 (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x01
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0xAC, 0x00
	call (xhl)
	jr .Lts92b_load
.Lts92b_error:
	ldmw (xsp + 10), 0xFFFF
.Lts92b_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 34)
	ret

HDAE5000_Table_Sub_292D16:	; 0x292D16 (419 bytes)
	lda xsp, (xsp - 32)
	push xiz
	ld (xsp + 32), bc
	ld (xsp + 34), wa
	ldmw (xsp + 4), 0x0000
	pushw 0x0008
	push xde
	lda xwa, (xsp + 24)
	push xwa
	call 0x29AE9F
	pushw 0x002F
	pushw 0x8F42
	lda xwa, (xsp + 40)
	push xwa
	call 0x29AF45
	lda xsp, (xsp + 18)
	lda xwa, (xsp + 18)
	ldada_24 xbc, 3116872	; 0x2F8F48
	ldda32_24 xde, 2335138
	ld_sril3 xde, 0xE9, 0x88, 0x0E
	ld_sril3 xix, 0xE9, 0xA0, 0x00
	call (xix)
	cps hl, 0
	jr ge, .Lts92d_1
	ldw hl, 0xFFFF
	jrl .Lts92d_exit
.Lts92d_1:
	ldada_24 xwa, 2297628	; 0x230F1C
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld_sril3 xhl, 0xE5, 0xA8, 0x00
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	ldada_24 xwa, 2297628
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 14), xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102894	; 0x20166E (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call 0x297E16
	cp hl, 0xFFFF
	jr nz, .Lts92d_2
	ldw hl, 0xFFFF
	jrl .Lts92d_exit
.Lts92d_2:
	ld xwa, (xsp + 6)
	cp xwa, 0x00008000
	jrl nz, .Lts92d_5
.Lts92d_loop:
	ldada_24 xwa, 2297628
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld_sril3 xhl, 0xE5, 0xA8, 0x00
	ld xbc, 0x00008000
	call (xhl)
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	cp xwa, 0x00000000
	jr le, .Lts92d_4
	ldada_24 xwa, 2297628
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 14), xhl
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102894	; 0x20166E
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call 0x297FD1
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	cp wa, 0xFFFF
	jr z, .Lts92d_5
.Lts92d_4:
	ld xwa, (xsp + 6)
	cp xwa, 0x00008000
	jrl z, .Lts92d_loop
.Lts92d_5:
	ld wa, (xsp + 32)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102866	; 0x201652 (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x01
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0xAC, 0x00
	call (xhl)
	ld hl, (xsp + 4)
.Lts92d_exit:
	pop xiz
	lda xsp, (xsp + 32)
	ret

HDAE5000_Table_Sub_292EB9:	; 0x292EB9 (281 bytes)
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 34), bc
	ld (xsp + 36), wa
	ldmw (xsp + 10), 0x0000
	pushw 0x0008
	push xde
	lda xwa, (xsp + 18)
	push xwa
	call 0x29AE9F
	pushw 0x002F
	pushw 0x8F4C
	lda xwa, (xsp + 34)
	push xwa
	call 0x29AF45
	lda xsp, (xsp + 18)
	; Workspace dispatch with WA=9
	lda xwa, (xsp + 26)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	ldw wa, 0x0009
	call (xhl)
	; Second dispatch via XIX
	lda xwa, (xsp + 12)
	ldada_24 xbc, 3116880	; 0x2F8F50
	ldda32_24 xde, 2335138
	ld_sril3 xde, 0xE9, 0x88, 0x0E
	ld_sril3 xix, 0xE9, 0xA0, 0x00
	call (xix)
	cps hl, 0
	jrl lt, .Lts92e_error
	ldada_24 xwa, 2297628
	ld xbc, (xsp + 30)
	ldda32_24 xde, 2335138
	ld_sril3 xde, 0xE9, 0x88, 0x0E
	ld_sril3 xhl, 0xE9, 0xA8, 0x00
	call (xhl)
	ldada_24 xwa, 2297628
	ld (xsp + 4), xwa
	ld xwa, (xsp + 30)
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 8), xhl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 36)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102898	; 0x201672 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xsp + 8)
	call 0x297E16
	ld (xsp + 10), hl
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 36)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102867	; 0x201653 (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x01
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0xAC, 0x00
	call (xhl)
	jr .Lts92e_load
.Lts92e_error:
	ldmw (xsp + 10), 0xFFFF
.Lts92e_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 34)
	ret

HDAE5000_Table_Sub_292FD2:	; 0x292FD2 (329 bytes)
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 34), bc
	ld (xsp + 36), wa
	ldmw (xsp + 10), 0x0000
	pushw 0x0008
	push xde
	lda xwa, (xsp + 18)
	push xwa
	call 0x29AE9F
	pushw 0x002F
	pushw 0x8F54
	lda xwa, (xsp + 34)
	push xwa
	call 0x29AF45
	lda xsp, (xsp + 18)
	; Dispatch via XIX
	lda xwa, (xsp + 12)
	ldada_24 xbc, 3116890	; 0x2F8F5A
	ldda32_24 xde, 2335138
	ld_sril3 xde, 0xE9, 0x88, 0x0E
	ld_sril3 xix, 0xE9, 0xA0, 0x00
	call (xix)
	cps hl, 0
	jrl lt, .Lts92f_error
	; Call 0x29AEC7 with args (8 bytes pushed, cleaned by inc 0)
	pushw 0x8000
	pushw 0x0000
	ldada_24 xwa, 2297628	; 0x230F1C
	push xwa
	call 0x29AEC7
	inc 0, xsp		; clean up 8 bytes
	; Workspace dispatch with XBC=0x16
	ldada_24 xwa, 2297628
	ldda32_24 xbc, 2335138
	ld_sril3 xbc, 0xE5, 0x88, 0x0E
	ld_sril3 xhl, 0xE5, 0xA8, 0x00
	ld xbc, 0x00000016
	call (xhl)
	; Load param, call 0x28E5E9, sign extend result
	ldada_24 xwa, 2297628
	ld xwa, (xwa + 18)	; offset 0x12
	call 0x28E5E9
	ld iz, hl		; 16-bit result to IZ
	exts xiz		; sign extend to 32-bit
	ld xwa, xiz
	add xwa, 0x00000016
	calr HDAE5000_Cell_Get_Params
	ld (xsp + 30), xhl
	; Dispatch with XIZ as XBC param
	ldada_24 xwa, 2297650	; 0x230F32
	ld xbc, xiz
	ldda32_24 xde, 2335138
	ld_sril3 xde, 0xE9, 0x88, 0x0E
	ld_sril3 xhl, 0xE9, 0xA8, 0x00
	call (xhl)
	; Table lookup
	ldada_24 xwa, 2297628
	ld (xsp + 4), xwa
	lda xwa, (xsp + 30)
	ld (xsp + 8), xwa
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 36)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102902	; 0x201676 (table base)
	add xwa, xhl
	ld xde, xwa
	ld xwa, (xsp + 4)
	ld xbc, (xsp + 8)
	ld xbc, (xbc)		; double dereference
	call 0x297E16
	ld (xsp + 10), hl
	; Set flag
	ld wa, (xsp + 34)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 36)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102868	; 0x201654 (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x01
	; Final workspace dispatch
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0xAC, 0x00
	call (xhl)
	jr .Lts92f_load
.Lts92f_error:
	ldmw (xsp + 10), 0xFFFF
.Lts92f_load:
	ld hl, (xsp + 10)
	pop xiz
	lda xsp, (xsp + 34)
	ret

HDAE5000_Workspace_Handler:	; 0x29311B (592 bytes)
	; Part 1: Clear matching entries in workspace tables
	; Nested loop: IZ = 0..119, IY = 0..31
	; For each (IZ,IY), computes table index = IZ*9*16 + IY
	; If table[index] matches WA+1 AND table[index+0x20] matches BC+1,
	; clears 4 related entries at offsets 0xC2, 0xE2, 0x02, 0x22
	pushw iz
	lds iz, 0			; IZ = 0 (outer counter)
	cp iz, 0x0078
	jrl nc, .Lwh_outer_done		; skip if IZ >= 120
.Lwh_outer_loop:
	lds iy, 0			; IY = 0 (inner counter)
	cp iy, 0x0020
	jrl nc, .Lwh_inner_done		; skip if IY >= 32
.Lwh_inner_loop:
	; Compute table index: XIX = IZ * 144 + IY
	ld hl, iy
	extz xhl
	ld de, iz
	extz xde
	ld xix, xde
	sll xix, 3			; XIX = IZ * 8
	add xix, xde			; XIX = IZ * 9
	sll xix, 4			; XIX = IZ * 144
	add xix, xhl			; XIX = IZ * 144 + IY
	; Check WA match at base 0x2257C2
	ldada_24 xde, 2250690		; XDE = 0x2257C2
	add xde, xix
	ld e, (xde)			; E = table entry
	ld l, e
	extz hl
	ld de, wa			; DE = WA
	inc 1, de			; DE = WA + 1
	cp de, hl			; match?
	jrl nz, .Lwh_next_inner
	; Check BC match at base 0x2257E2
	ld hl, iy
	extz xhl
	ld de, iz
	extz xde
	ld xix, xde
	sll xix, 3
	add xix, xde
	sll xix, 4
	add xix, xhl
	ldada_24 xde, 2250722		; XDE = 0x2257E2
	add xde, xix
	ld e, (xde)
	ld l, e
	extz hl
	ld de, bc			; DE = BC
	inc 1, de			; DE = BC + 1
	cp de, hl
	jr nz, .Lwh_next_inner
	; Both match — clear 4 table entries
	; Clear entry at base 0x2257C2
	ld hl, iy
	extz xhl
	ld de, iz
	extz xde
	ld xix, xde
	sll xix, 3
	add xix, xde
	sll xix, 4
	add xix, xhl
	ldada_24 xde, 2250690		; 0x2257C2
	add xde, xix
	ldmi8 (xde), 0x00
	; Clear entry at base 0x2257E2
	ld hl, iy
	extz xhl
	ld de, iz
	extz xde
	ld xix, xde
	sll xix, 3
	add xix, xde
	sll xix, 4
	add xix, xhl
	ldada_24 xde, 2250722		; 0x2257E2
	add xde, xix
	ldmi8 (xde), 0x00
	; Clear entry at base 0x225802
	ld hl, iy
	extz xhl
	ld de, iz
	extz xde
	ld xix, xde
	sll xix, 3
	add xix, xde
	sll xix, 4
	add xix, xhl
	ldada_24 xde, 2250754		; 0x225802
	add xde, xix
	ldmi8 (xde), 0x00
	; Clear entry at base 0x225822
	ld hl, iy
	extz xhl
	ld de, iz
	extz xde
	ld xix, xde
	sll xix, 3
	add xix, xde
	sll xix, 4
	add xix, xhl
	ldada_24 xde, 2250786		; 0x225822
	add xde, xix
	ldmi8 (xde), 0x00
.Lwh_next_inner:
	inc 1, iy
	cp iy, 0x0020
	jrl c, .Lwh_inner_loop
.Lwh_inner_done:
	inc 1, iz
	cp iz, 0x0078
	jrl c, .Lwh_outer_loop
.Lwh_outer_done:
	popw iz
	ret
	; Part 2: Main workspace handler entry (0x29320D)
	; Called by firmware — saves regs, dispatches through handler chain
	dec 0, xsp			; callee cleanup placeholder
	push xiz
	ld (xsp + 6), de		; save DE (param)
	ld (xsp + 8), bc		; save BC (param)
	ld (xsp + 10), wa		; save WA (param)
	; Get handler through workspace chain
	ldda32_24 xwa, 2335138		; (0x23A1A2) — workspace ptr
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; XWA = (XWA+0x0E88)
	ld_sril3 xhl, 0xE1, 0xE8, 0x00	; XHL = (XWA+0x00E8) — handler
	lds wa, 1			; param = 1
	call (xhl)
	; Conditional: if BC == 1, call extra handler
	cpmi16 (xsp + 8), 0x0001
	jr nz, .Lwh_skip_extra
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; XWA = (XWA+0x0E0A)
	ld_sril3 xhl, 0xE1, 0x38, 0x05	; XHL = (XWA+0x0538)
	call (xhl)
.Lwh_skip_extra:
	call 0x297466
	ldmw (xsp + 4), 0x0000		; slot counter = 0
	; Loop over 16 slots
	cpmi16 (xsp + 4), 0x0010
	jrl nc, .Lwh_loop_done
.Lwh_slot_loop:
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Table_Calc_Offset
	cp hl, 0xFFFF
	jr z, .Lwh_slot_fill
	; Process slot — call all 10 render types
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type0
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type1
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type2
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type3
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type4
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type5
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type6
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type7
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type8
	ld wa, (xsp + 10)
	ld bc, (xsp + 4)
	calr HDAE5000_Workspace_Handler	; recursive call (clear matching)
.Lwh_slot_fill:
	; Compute fill address and call MemFill
	pushw 0x001A			; fill count
	pushw 0x0020			; fill value/params
	ld wa, (xsp + 8)		; BC (adjusted for pushes)
	extz xwa
	ld xbc, 0x0000004C		; stride
	call HDAE5000_Multiply
	ld xiz, xhl			; save offset
	ld wa, (xsp + 14)		; WA (adjusted)
	extz xwa
	ld xbc, 0x000004C0		; stride
	call HDAE5000_Multiply
	add xhl, 0x00000780		; base offset
	add xhl, xiz			; total offset
	ld xwa, 0x00201632		; table base address
	add xwa, xhl			; absolute address
	push xwa			; push fill dest
	call HDAE5000_MemFill
	inc 0, xsp			; stack cleanup (no-op)
	incm 1, (xsp + 4)		; slot counter++
	cpmi16 (xsp + 4), 0x0010
	jrl c, .Lwh_slot_loop
.Lwh_loop_done:
	; Post-loop: fill final block
	pushw 0x0010			; block count
	pushw 0x0020			; block params
	ld wa, (xsp + 14)		; WA (adjusted)
	extz xwa
	sll xwa, 4			; * 16
	ld xbc, 0x00201632		; table base
	add xbc, xwa
	push xbc			; push fill dest
	call HDAE5000_MemFill
	inc 0, xsp			; stack cleanup
	; Final handler calls
	call 0x297A78
	cpmi16 (xsp + 6), 0x0001	; DE == 1?
	callcc_24 14, 2716853		; call nz, 0x2974B5
	cpmi16 (xsp + 8), 0x0001	; BC == 1?
	jr nz, .Lwh_skip_final
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E	; XWA = (XWA+0x0E0A)
	ld_sril3 xhl, 0xE1, 0x3C, 0x05	; XHL = (XWA+0x053C)
	call (xhl)
.Lwh_skip_final:
	; Workspace cleanup calls
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0xEC, 0x00	; XHL = (XWA+0x00EC)
	call (xhl)
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0xF0, 0x00	; XHL = (XWA+0x00F0)
	call (xhl)
	pop xiz
	inc 0, xsp			; stack cleanup
	ret

HDAE5000_Workspace_Sub_29336B:	; 0x29336B (349 bytes)
	dec 4, xsp
	push xiz
	ld iz, de
	ld (xsp + 4), bc	; save file number
	ld (xsp + 6), wa	; save partition
	cps iz, 0
	jrl z, .Lws36b_exit	; nothing to do
	; Workspace dispatch at 0xE8
	ldda32_24 xwa, 2335138	; 0x23A1A2
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0xE8, 0x00
	lds wa, 1
	call (xhl)
	; Check workspace flag at (xsp+14)
	cpmi16 (xsp + 14), 0x0001
	jr nz, .Lws36b_skip1
	; Workspace dispatch at 0x0538
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x38, 0x05
	call (xhl)
.Lws36b_skip1:
	call 0x297466
	; Bitmask dispatch: test bits of IZ, call corresponding renderers
	bit 0, iz
	jr z, .Lws36b_bit1
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type0
.Lws36b_bit1:
	bit 1, iz
	jr z, .Lws36b_bit2
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type1
.Lws36b_bit2:
	bit 2, iz
	jr z, .Lws36b_bit3
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type2
.Lws36b_bit3:
	bit 3, iz
	jr z, .Lws36b_bit4
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type3
.Lws36b_bit4:
	bit 4, iz
	jr z, .Lws36b_bit5
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type4
.Lws36b_bit5:
	bit 5, iz
	jr z, .Lws36b_bit6
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type5
.Lws36b_bit6:
	bit 6, iz
	jr z, .Lws36b_bit7
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type6
.Lws36b_bit7:
	bit 7, iz
	jr z, .Lws36b_bit8
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type7
.Lws36b_bit8:
	bit 8, iz
	jr z, .Lws36b_calc
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Cell_Render_Type8
.Lws36b_calc:
	; Calculate table offset
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Table_Calc_Offset
	cp hl, 0xFFFF
	jr nz, .Lws36b_post
	; Push args and call 0x29AEC7
	pushw 0x001A
	pushw 0x0020
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ld xwa, 0x00201632
	add xwa, xhl
	push xwa
	call 0x29AEC7
	inc 0, xsp
	; Call workspace handler
	ld wa, (xsp + 6)
	ld bc, (xsp + 4)
	calr HDAE5000_Workspace_Handler
.Lws36b_post:
	call 0x297A78
	; Conditional call NZ to 0x2974B5
	cpmi16 (xsp + 12), 0x0001
	callcc_24 14, 2716853	; call nz, 0x2974B5
	; Check workspace flag at (xsp+14)
	cpmi16 (xsp + 14), 0x0001
	jr nz, .Lws36b_skip2
	; Workspace dispatch at 0x053C
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x0A, 0x0E
	ld_sril3 xhl, 0xE1, 0x3C, 0x05
	call (xhl)
.Lws36b_skip2:
	; Workspace dispatch at 0xEC
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0xEC, 0x00
	call (xhl)
	; Workspace dispatch at 0xF0
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0xF0, 0x00
	call (xhl)
.Lws36b_exit:
	pop xiz
	inc 4, xsp
	retd 4

; --- UI Cell Renderers (9 x 222 bytes each) ---
; Delete table entry: check existence, call handler, clear entry (-1), clear flag (0)
HDAE5000_Cell_Render_Type0:	; 0x2934C8 (222 bytes)
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc	; save file number
	ld (xsp + 6), wa	; save partition
	; --- Check if entry exists ---
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C	; multiplier = 76
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0	; multiplier = 1216
	call 0x29B72D
	add xhl, 0x780		; += 1920
	add xhl, xiz
	ldada_24 xwa, 2102870	; 0x201656 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr0_exit
	; --- Get entry value and call handler ---
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102870	; 0x201656
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
	; --- Clear entry (store -1) ---
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102870	; 0x201656
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	; --- Clear flag (store 0) ---
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102860	; 0x20164C (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x00
.Lcr0_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Render_Type1:	; 0x2935A6 (222 bytes)
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102874	; 0x20165A (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr1_exit
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102874	; 0x20165A
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102874	; 0x20165A
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102861	; 0x20164D (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x00
.Lcr1_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Render_Type2:	; 0x293684 (222 bytes)
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102878	; 0x20165E (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr2_exit
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102878	; 0x20165E
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102878	; 0x20165E
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102862	; 0x20164E (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x00
.Lcr2_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Render_Type3:	; 0x293762 (222 bytes)
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102882	; 0x201662 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr3_exit
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102882	; 0x201662
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102882	; 0x201662
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102863	; 0x20164F (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x00
.Lcr3_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Render_Type4:	; 0x293840 (222 bytes)
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102886	; 0x201666 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr4_exit
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102886	; 0x201666
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102886	; 0x201666
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102864	; 0x201650 (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x00
.Lcr4_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Render_Type5:	; 0x29391E (222 bytes)
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102890	; 0x20166A (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr5_exit
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102890	; 0x20166A
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102890	; 0x20166A
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102865	; 0x201651 (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x00
.Lcr5_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Render_Type6:	; 0x2939FC (222 bytes)
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102894	; 0x20166E (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr6_exit
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102894	; 0x20166E
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102894	; 0x20166E
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102866	; 0x201652 (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x00
.Lcr6_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Render_Type7:	; 0x293ADA (222 bytes)
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102898	; 0x201672 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr7_exit
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102898	; 0x201672
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102898	; 0x201672
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102867	; 0x201653 (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x00
.Lcr7_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Render_Type8:	; 0x293BB8 (222 bytes)
	dec 4, xsp
	push xiz
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102902	; 0x201676 (table base)
	add xwa, xhl
	ld xwa, (xwa)
	cp xwa, 0xFFFFFFFF
	jrl z, .Lcr8_exit
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102902	; 0x201676
	add xwa, xhl
	ld xwa, (xwa)
	call 0x298590
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102902	; 0x201676
	ld xbc, xwa
	add xbc, xhl
	ld xwa, 0xFFFFFFFF
	ld (xbc), xwa
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x0000004C
	call 0x29B72D
	ld xiz, xhl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0x000004C0
	call 0x29B72D
	add xhl, 0x780
	add xhl, xiz
	ldada_24 xwa, 2102868	; 0x201654 (flag base)
	add xwa, xhl
	ldmi8 (xwa), 0x00
.Lcr8_exit:
	pop xiz
	inc 4, xsp
	ret

HDAE5000_Cell_Validate:	; 0x293C96 (347 bytes)
	; Validate cell rendering — tests bits 0-8, accumulates sizes in XIZ
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 14), wa		; save bitmask
	ldmw (xsp + 4), 0x0000		; init result = 0
	lds32 xiz, 0			; accumulator = 0
	; --- Bit 0: call handler(0) and handler(1) ---
	ld wa, (xsp + 14)
	bit 0, wa
	jr z, .Lcv_bit1
	lda xwa, (xsp + 6)		; XWA = scratch buffer address
	ld xbc, xwa
	ldda32_24 xwa, 2335138		; (0x23A1A2) — workspace ptr
	ld_sril3 xwa, 0xE1, 0x88, 0x0E	; XWA = (XWA+0x0E88)
	ld_sril3 xhl, 0xE1, 0x80, 0x00	; XHL = (XWA+0x0080) — handler
	lds wa, 0			; param = 0
	call (xhl)
	add xiz, (xsp + 10)		; accumulate size
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 1			; param = 1
	call (xhl)
	add xiz, (xsp + 10)
	; --- Bit 1: call handler(2) ---
.Lcv_bit1:
	ld wa, (xsp + 14)
	bit 1, wa
	jr z, .Lcv_bit2
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 2			; param = 2
	call (xhl)
	add xiz, (xsp + 10)
	; --- Bit 2: call handler(3) + extra handler at +0x34 ---
.Lcv_bit2:
	ld wa, (xsp + 14)
	bit 2, wa
	jr z, .Lcv_bit3
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	lds wa, 3			; param = 3
	call (xhl)
	add xiz, (xsp + 10)
	; Extra handler at +0x34
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld xix, (xwa + 0x34)
	call (xix)
	add xiz, xhl
	; --- Bit 3: handler at +0x44 ---
.Lcv_bit3:
	ld wa, (xsp + 14)
	bit 3, wa
	jr z, .Lcv_bit4
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld xix, (xwa + 0x44)
	call (xix)
	add xiz, xhl
	; --- Bit 4: fixed constant 0x72AA ---
.Lcv_bit4:
	ld wa, (xsp + 14)
	bit 4, wa
	jr z, .Lcv_bit5
	ld xwa, 0x000072AA
	ld (xsp + 10), xwa
	add xiz, (xsp + 10)
	; --- Bit 5: handler at +0x64 ---
.Lcv_bit5:
	ld wa, (xsp + 14)
	bit 5, wa
	jr z, .Lcv_bit6
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld xix, (xwa + 0x64)
	call (xix)
	add xiz, xhl
	; --- Bit 6: call handler(8) ---
.Lcv_bit6:
	ld wa, (xsp + 14)
	bit 6, wa
	jr z, .Lcv_bit7
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	ldw wa, 8			; param = 8
	call (xhl)
	add xiz, (xsp + 10)
	; --- Bit 7: call handler(9) ---
.Lcv_bit7:
	ld wa, (xsp + 14)
	bit 7, wa
	jr z, .Lcv_bit8
	lda xwa, (xsp + 6)
	ld xbc, xwa
	ldda32_24 xwa, 2335138
	ld_sril3 xwa, 0xE1, 0x88, 0x0E
	ld_sril3 xhl, 0xE1, 0x80, 0x00
	ldw wa, 9			; param = 9
	call (xhl)
	add xiz, (xsp + 10)
	; --- Bit 8: fixed constant 0x5000 ---
.Lcv_bit8:
	ld wa, (xsp + 14)
	bit 8, wa
	jr z, .Lcv_final
	add xiz, 0x00005000
	; --- Final validation ---
.Lcv_final:
	ld xwa, xiz			; total accumulated size
	call 0x298C7D			; validate total
	ld xiz, xhl			; save result
	call 0x297D35			; get available space
	cp xhl, xiz			; available > needed?
	jr ugt, .Lcv_done
	ldmw (xsp + 4), 0xFFFF		; set error flag
.Lcv_done:
	ld hl, (xsp + 4)
	pop xiz
	lda xsp, (xsp + 12)
	ret

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
	lda xsp, (xsp - 14)
	push xiz
	ld (xsp + 10), xbc		; save arg1
	ld (xsp + 14), xwa		; save arg0
	ldmw (xsp + 8), 0x0000		; init result = 0
	ldda8_24 a, 2330412		; load active flag (0x238F2C)
	cps a, 2
	jr z, .Lds301_mode2
	cps a, 1
	jr nz, .Lds301_err1
.Lds301_mode2:
	ld xwa, (xsp + 10)		; reload arg1
	or xwa, xwa			; test if zero
	jr nz, .Lds301_compute
	ldw hl, 0xFFFF
	jrl .Lds301_exit
.Lds301_err1:
	ldw hl, 0xFFFF
	jrl .Lds301_exit
.Lds301_compute:
	ldada_24 xwa, 2330396		; XWA = 0x238F1C (base address)
	subda32_24 xwa, 2330404	; XWA -= (0x238F24) => remaining space
	ld (xsp + 4), xwa		; save remaining
	ld xwa, (xsp + 10)		; reload arg1 (requested size)
	cp xwa, (xsp + 4)		; compare requested vs remaining
	jr ugt, .Lds301_use_remaining
	ld xiz, (xsp + 10)		; XIZ = requested (fits)
	jr .Lds301_check_limit
.Lds301_use_remaining:
	ld xiz, (xsp + 4)		; XIZ = remaining (capped)
.Lds301_check_limit:
	cp xiz, 0x0000FFFF		; compare with 0xFFFF
	jr ule, .Lds301_small
	; Large transfer: split into two calls
	pushw 0xFFFF			; count = 0xFFFF
	ld xwa, (xsp + 16)		; reload arg0 (adjusted for push)
	push xwa			; push source
	ldda32_24 xwa, 2330404		; XWA = current position
	push xwa			; push dest
	call 0x29AE9F
	ld xwa, xiz			; XWA = total size
	sub xwa, 0x0000FFFF		; remainder after first chunk
	pushw wa			; push remainder count
	ld xwa, (xsp + 26)		; reload arg0 (deep stack)
	add xwa, 0x0000FFFF		; advance source by 0xFFFF
	push xwa			; push adjusted source
	ldda32_24 xwa, 2330404		; reload current position
	add xwa, 0x0000FFFF		; advance dest by 0xFFFF
	push xwa			; push adjusted dest
	call 0x29AE9F
	lda xsp, (xsp + 20)		; cleanup 20 bytes of args
	jr .Lds301_update
.Lds301_small:
	ld wa, iz			; WA = count (16-bit)
	pushw wa			; push count
	ld xwa, (xsp + 16)		; reload arg0
	push xwa			; push source
	ldda32_24 xwa, 2330404		; current position
	push xwa			; push dest
	call 0x29AE9F
	lda xsp, (xsp + 10)		; cleanup 10 bytes of args
.Lds301_update:
	add (xsp + 14), xiz		; advance arg0 by transferred size
	adddm32_24 2330404, xiz	; advance current position
	sub (xsp + 4), xiz		; decrease remaining
	ld xwa, (xsp + 4)		; check if remaining > 0
	or xwa, xwa
	jr nz, .Lds301_finalize
	; Remaining exhausted — handle based on active flag
	cpdi8_24 2330412, 1		; active flag == 1?
	jr nz, .Lds301_flag2
	ldada_24 xwa, 2297628		; 0x230F1C
	ldda32_24 xde, 2330408		; XDE = callback
	ld xbc, 0x00008000
	call 0x297E16
	ld (xsp + 8), hl		; save result
	stdi8_24 2330412, 2		; set active flag = 2
	jr .Lds301_check_result
.Lds301_flag2:
	ldada_24 xwa, 2297628		; 0x230F1C
	ldda32_24 xde, 2330408		; XDE = callback
	ld xbc, 0x00008000
	call 0x297FD1
	ld (xsp + 8), hl		; save result
.Lds301_check_result:
	cpmi16 (xsp + 8), 0x0000	; result == 0?
	jr nz, .Lds301_exit_result
	ldada_24 xwa, 2297628		; 0x230F1C — reset position
	stda32_24 2330404, xwa		; store to current position
.Lds301_finalize:
	sub (xsp + 10), xiz		; decrease arg1 by transferred
	ld xwa, (xsp + 10)		; check if arg1 > 0
	or xwa, xwa
	jrl nz, .Lds301_compute	; loop if more to transfer
.Lds301_exit_result:
	ld hl, (xsp + 8)		; load result
.Lds301_exit:
	pop xiz
	lda xsp, (xsp + 14)
	ret

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

HDAE5000_PPORT_Setup:	; 0x29511C (442 bytes)
	; PPORT command dispatcher — WA = command ID (1-30)
	cps wa, 0
	jr le, .Lpps_error		; WA <= 0 → error
	cp wa, 0x001E
	jr gt, .Lpps_error		; WA > 30 → error
	push xhl
	nop
	ld hl, wa			; HL = command number
	sla xhl, 2			; XHL *= 4 (table offset)
	nop
	extz xhl			; zero-extend
	ld xix, 0x00295146		; table base
	nop
	ld_sril3 xhl, 0x07, 0xF0, 0xEC	; XHL = (XIX + HL) — load handler addr
	nop
	call (xhl)			; call handler
	pop xhl
	nop
	ret
	nop
.Lpps_error:
	lds wa, 1			; return 1 (error)
	ret
	nop
.Lpps_jump_table:
	; 31-entry jump table (entry 0 unused, entries 1-30 = commands)
	.long 0x002951C2		; entry 0 (unused)
	.long 0x002951C4		; entry 1
	.long 0x002951CC		; entry 2
	.long 0x002951D4		; entry 3
	.long 0x002951DC		; entry 4
	.long 0x002951E2		; entry 5
	.long 0x002951E8		; entry 6
	.long 0x002951EE		; entry 7
	.long 0x002951F6		; entry 8
	.long 0x002951FE		; entry 9
	.long 0x00295206		; entry 10
	.long 0x0029520E		; entry 11
	.long 0x00295216		; entry 12
	.long 0x0029521E		; entry 13
	.long 0x0029522A		; entry 14
	.long 0x00295236		; entry 15
	.long 0x00295242		; entry 16
	.long 0x00295248		; entry 17
	.long 0x00295250		; entry 18
	.long 0x00295256		; entry 19
	.long 0x0029525E		; entry 20
	.long 0x00295264		; entry 21
	.long 0x00295270		; entry 22
	.long 0x00295278		; entry 23
	.long 0x00295284		; entry 24
	.long 0x00295290		; entry 25
	.long 0x0029529C		; entry 26
	.long 0x002952A6		; entry 27
	.long 0x002952B2		; entry 28
	.long 0x002952BE		; entry 29
	.long 0x002952CA		; entry 30
	; --- Handler stubs (commands 0-30) ---
.Lpps_handler_0:			; 0x2951C2
	ret
	nop
.Lpps_handler_1:			; 0x2951C4
	call 0x294416
	ld xix, xhl
	ret
	nop
.Lpps_handler_2:			; 0x2951CC
	call 0x29444E
	ld wa, hl
	ret
	nop
.Lpps_handler_3:			; 0x2951D4
	call 0x294471
	ld wa, hl
	ret
	nop
.Lpps_handler_4:			; 0x2951DC
	call 0x29456E
	ret
	nop
.Lpps_handler_5:			; 0x2951E2
	call 0x2945FA
	ret
	nop
.Lpps_handler_6:			; 0x2951E8
	call 0x294686
	ret
	nop
.Lpps_handler_7:			; 0x2951EE
	call 0x294735
	ld wa, hl
	ret
	nop
.Lpps_handler_8:			; 0x2951F6
	call 0x29475A
	ld wa, hl
	ret
	nop
.Lpps_handler_9:			; 0x2951FE
	call 0x29477F
	ld wa, hl
	ret
	nop
.Lpps_handler_10:			; 0x295206
	call 0x2947A4
	ld wa, hl
	ret
	nop
.Lpps_handler_11:			; 0x29520E
	call 0x2947C9
	ld wa, hl
	ret
	nop
.Lpps_handler_12:			; 0x295216
	call 0x2947EE
	ld wa, hl
	ret
	nop
.Lpps_handler_13:			; 0x29521E
	ld wa, bc			; shuffle args
	ld bc, de
	call 0x294813
	ld wa, hl
	ret
	nop
.Lpps_handler_14:			; 0x29522A
	ld wa, bc
	ld bc, de
	call 0x294B21
	ld wa, hl
	ret
	nop
.Lpps_handler_15:			; 0x295236
	ld wa, bc
	ld bc, de
	call 0x294B4F
	ld wa, hl
	ret
	nop
.Lpps_handler_16:			; 0x295242
	call 0x294B82
	ret
	nop
.Lpps_handler_17:			; 0x295248
	call 0x294C6A
	ld wa, hl
	ret
	nop
.Lpps_handler_18:			; 0x295250
	call 0x294C8D
	ret
	nop
.Lpps_handler_19:			; 0x295256
	call 0x294CAD
	ld xix, xhl
	ret
	nop
.Lpps_handler_20:			; 0x29525E
	call 0x294CE2
	ret
	nop
.Lpps_handler_21:			; 0x295264
	ld wa, bc
	ld bc, de
	call 0x294DA1
	ld wa, hl
	ret
	nop
.Lpps_handler_22:			; 0x295270
	call 0x294EC8
	ld wa, hl
	ret
	nop
.Lpps_handler_23:			; 0x295278
	ld xwa, xbc			; 32-bit arg shuffle
	ld xbc, xde
	call 0x294EEF
	ld wa, hl
	ret
	nop
.Lpps_handler_24:			; 0x295284
	ld wa, bc
	ld bc, de
	call 0x294F0A
	ld wa, hl
	ret
	nop
.Lpps_handler_25:			; 0x295290
	ld xwa, xbc
	ld xbc, xde
	call 0x294F9B
	ld wa, hl
	ret
	nop
.Lpps_handler_26:			; 0x29529C
	ld xwa, xbc
	call 0x284D7F
	lds wa, 0
	ret
	nop
.Lpps_handler_27:			; 0x2952A6
	ld wa, bc
	ld bc, de
	call 0x295009
	ld wa, hl
	ret
	nop
.Lpps_handler_28:			; 0x2952B2
	ld xwa, xbc
	ld xbc, xde
	call 0x28F308
	ld wa, hl
	ret
	nop
.Lpps_handler_29:			; 0x2952BE
	ld xwa, xbc
	ld xbc, xde
	call 0x28F343
	ld wa, hl
	ret
	nop
.Lpps_handler_30:			; 0x2952CA
	ld xwa, xbc
	ld xbc, xde
	call 0x28F357
	ld wa, hl
	ret
	nop

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

HDAE5000_PPORT_Execute:	; 0x2952F8 (234 bytes)
	; Execute PPORT command — dispatch on A register (command ID 0-7)
	and a, 0x7F			; mask high bit
	nop
	cps a, 0
	jr nz, .Lppe_cmd1
	jp .Lppe_read_exec		; cmd 0 → read/execute
.Lppe_cmd1:
	cps a, 1
	jr nz, .Lppe_cmd2
	jp .Lppe_read_exec		; cmd 1 → read/execute
.Lppe_cmd2:
	cps a, 2
	jr nz, .Lppe_cmd3
	jp .Lppe_simple_ret		; cmd 2 → simple ret
.Lppe_cmd3:
	cps a, 3
	jr nz, .Lppe_cmd4
	jp .Lppe_simple_ret		; cmd 3 → simple ret
.Lppe_cmd4:
	cps a, 4
	jr nz, .Lppe_cmd5
	jp .Lppe_simple_ret		; cmd 4 → simple ret
.Lppe_cmd5:
	cps a, 5
	jr nz, .Lppe_cmd6
	jp .Lppe_simple_ret		; cmd 5 → simple ret
.Lppe_cmd6:
	cps a, 6
	jr nz, .Lppe_cmd7
	jp .Lppe_simple_ret		; cmd 6 → simple ret
.Lppe_cmd7:
	cps a, 7
	jr nz, .Lppe_default
	jp .Lppe_simple_ret		; cmd 7 → simple ret
.Lppe_default:
	jp .Lppe_simple_ret		; unknown → simple ret
.Lppe_simple_ret:
	ret
	; Padding (17 bytes)
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
	nop
	nop
	nop
	nop
	nop
.Lppe_write_setup:
	; Write I/O registers and clear flag
	ldb a, 0x89
	stda8_24 1441798, a		; (0x160006) = 0x89
	nop
	ldb a, 0x28
	stda8_24 1441794, a		; (0x160002) = 0x28
	nop
	stdi8_24 2330836, 0x00		; (0x2390D4) = 0
	ret
	nop
.Lppe_read_exec:
	; Read/execute with polling loop
	ei 0x07				; enable interrupts
	ldb a, 0x89
	stda8_24 1441798, a		; (0x160006) = 0x89
	nop
.Lppe_poll:
	lds wa, 0			; WA = 0
	call HDAE5000_Display_String	; 0x2950F8
	ldda8_24 a, 1441796		; read (0x160004)
	nop
	and a, 0x04			; test bit 2
	nop
	cps a, 4			; bit 2 set?
	jr nz, .Lppe_poll		; keep polling if not
	ldb a, 0x18
	stda8_24 1441794, a		; (0x160002) = 0x18
	nop
	stdi8_24 2330836, 0x00		; (0x2390D4) = 0
	call 0x296814
	cpdi8_24 2330836, 1		; (0x2390D4) == 1?
	jpcc_24 6, 2708340		; if Z, go back to polling (0x295374)
	nop
	ldada_24 xix, 2330984		; XIX = 0x239168
	nop
	xor xwa, xwa			; XWA = 0
	ld a, (xix)			; A = command index
	cp xwa, 0x00000014		; compare with 20
	jpcc_24 11, 2708340		; if UGT 20, invalid → repoll (0x295374)
	nop
	dec 1, xwa			; XWA = index - 1
	sll xwa, 2			; XWA *= 4 (table entry size)
	nop
	ldada_24 xix, 2708430		; XIX = jump table base (0x2953CE)
	nop
	add xix, xwa			; XIX += offset
	ld xiy, (xix)			; XIY = handler address
	jp (xiy)			; jump to handler
.Lppe_jump_table:
	; 5-entry jump table (4 bytes each)
	.long 0x00295642		; entry 0
	.long 0x002956CC		; entry 1
	.long 0x002956F2		; entry 2
	.long 0x0029572E		; entry 3
	.long 0x00295802		; entry 4

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

HDAE5000_Cmd02_Exit:	; 0x295914 (226 bytes)
	; Handler: Exit PPORT — display status, render, read sector/head masks,
	; AND with data bytes, write back, sum buffer, check results
	ldw wa, 0x001A				; display command
	nop
	ldada_24 xbc, 2708654			; lda XBC, 0x2954AE — status string
	nop
	call HDAE5000_Display_String
	call HDAE5000_Render_Display_Region
	call HDAE5000_Render_Display_Region2
	call 2713602				; call 0x296802 — register XIX
	call HDAE5000_PPORT_Ready_Check
	lds bc, 0				; BC = 0
	ldw hl, 0x00C8				; HL = 200
	nop
	call 2714308				; call 0x296AC4 — utility
	ldada_24 xix, 2330984			; lda XIX, 0x239168
	nop
	ld a, (xix)				; read byte 0 from PPORT data
	stda8_24 2330846, a			; st (0x2390DE), A — save sector byte
	nop
	ldda8_24 w, 2330842			; ld W, (0x2390DA) — sector mask
	nop
	and w, a				; W = mask AND data
	stda8_24 2330850, w			; st (0x2390E2), W — masked sector
	nop
	ld a, (xix + 1)			; read byte 1 from PPORT data
	nop
	stda8_24 2330848, a			; st (0x2390E0), A — save head byte
	nop
	ldda8_24 w, 2330844			; ld W, (0x2390DC) — head mask
	nop
	and w, a				; W = mask AND data
	stda8_24 2330852, w			; st (0x2390E4), W — masked head
	nop
	ld (xix), w				; write masked head to PPORT[0]
	call HDAE5000_PPORT_Sum_Buffer
	cpdi8_24 2330836, 0x01			; cp (0x2390D4), 1 — error?
	jpcc_24 6, 2708340			; jp Z, 0x295374 — abort
	nop
	cpdi8_24 2330850, 0x00			; cp (0x2390E2), 0 — masked sector=0?
	jpcc_24 6, 2710002			; jp Z, 0x2959F2 — skip to end
	nop
	jp .Lce_continue
.Lce_check_head:			; 0x295992
	cpdi8_24 2330852, 0x00			; cp (0x2390E4), 0 — masked head=0?
	jpcc_24 6, 2710002			; jp Z, 0x2959F2 — skip to end
	nop
.Lce_continue:				; 0x29599E
	call HDAE5000_PPORT_Ready_Check
	ldda32_24 xix, 2330880			; ld XIX, (0x239100) — data source ptr
	nop
	ldda8_24 a, 2330850			; ld A, (0x2390E2) — masked sector
	nop
	ld (xix), a				; write sector to buffer[0]
	ldda8_24 a, 2330852			; ld A, (0x2390E4) — masked head
	nop
	ld (xix + 1), a			; write head to buffer[1]
	nop
	xor xbc, xbc
	xor xde, xde
	ldda8_24 c, 2330838			; ld C, (0x2390D6)
	nop
	ldda8_24 e, 2330840			; ld E, (0x2390D8)
	nop
	ldw wa, 0x000E				; display command
	nop
	di
	call HDAE5000_Display_String
	ei 7
	cps wa, 0				; check result
	jpcc_24 6, 2709986			; jp Z, 0x2959E2 — skip cleanup
	nop
	call HDAE5000_PPORT_Cleanup
.Lce_final_sum:				; 0x2959E2
	call HDAE5000_PPORT_Sum_Buffer
	cpdi8_24 2330836, 0x01			; cp (0x2390D4), 1 — error?
	jpcc_24 6, 2708340			; jp Z, 0x295374 — abort
	nop
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_Cmd03_ReadFSB:	; 0x2959F6
	; Handler: Read FSB from HD
	.incbin "includes/code_295642_2971a2.bin", 948, 838

HDAE5000_Cmd04_SendFSB:	; 0x295D3C
	; Handler: Send FSB to PC
	.incbin "includes/code_295642_2971a2.bin", 1786, 798

HDAE5000_Cmd05_RcvFSB:	; 0x29605A
	; Handler: Receive FSB from PC
	.incbin "includes/code_295642_2971a2.bin", 2584, 570

HDAE5000_Cmd06_WriteFSB:	; 0x296294 (150 bytes)
	; Handler: Write FSB (File System Block) to HD
	; Displays "Write FSB" status, calls render, copies PPORT data to XIX buffer,
	; loads sector/head params, calls Display_String with result, sums and cleans up.
	ldw wa, 0x001A			; display row/column
	nop
	ldada_24 xbc, 2708750		; 0x29550E - "Write FSB" string
	nop
	call HDAE5000_Display_String
	call HDAE5000_Render_Display_Region
	lds wa, 1			; WA = 1
	ei 0x00				; disable interrupts
	call HDAE5000_Display_String
	ei 0x07				; enable interrupts
	xor wa, wa			; WA = 0
	ldda8_24 a, 2330842		; A = [0x2390DA] (FSB byte 0)
	nop
	ld (xix), a			; store to buffer[0]
	ldda8_24 a, 2330844		; A = [0x2390DC] (FSB byte 1)
	nop
	ld (xix + 1), a			; store to buffer[1]
	nop
	add xix, 0x00000002		; advance buffer pointer past header
	lds bc, 0			; BC = 0 (loop counter)
	ldada_24 xiy, 2330984		; XIY = 0x239168 (PPORT command area)
	nop
	add xiy, 0x00000005		; skip 5-byte header
.Lwfsb_copy_loop:
	cp bc, 0x001A			; copied 26 bytes?
	jr z, .Lwfsb_done_copy		; yes, done
	ld_srib3 a, 0x07, 0xF4, 0xE4	; A = (XIY + BC) — read from PPORT data
	nop
	lda_dri3 xbc, 0x07, 0xF0, 0xE4	; (XIX + BC) = A — write to buffer
	nop
	inc 1, bc			; BC++
	jr t, .Lwfsb_copy_loop		; always loop
.Lwfsb_done_copy:
	xor xbc, xbc			; XBC = 0
	xor xde, xde			; XDE = 0
	ldda8_24 c, 2330838		; C = [0x2390D6] (sector)
	nop
	ldda8_24 e, 2330840		; E = [0x2390D8] (head)
	nop
	ldw wa, 0x000F			; WA = 0x0F (command code)
	nop
	ei 0x00				; disable interrupts
	call HDAE5000_Display_String
	ei 0x07				; enable interrupts
	cps wa, 0			; result == 0?
	jpcc_24 6, 2712342		; jp Z, skip error handling (0x296316)
	nop
	call HDAE5000_PPORT_Cleanup
.Lwfsb_after_error:			; 0x296316
	call HDAE5000_PPORT_Sum_Buffer
	cpdi8_24 2330836, 1		; [0x2390D4] == 1? (status check)
	jpcc_24 6, 2708340		; jp Z, exit to PPORT finish (0x295374)
	nop
	jp HDAE5000_PPORT_Cmd_Done

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

HDAE5000_PPORT_Cmd_SendFileList:	; 0x2964A6 (226 bytes)
	; Send file list to PC - displays status, builds transfer buffer
	; with disk info from 0x23910C-0x239150, then sends via PPORT.
	ldw wa, 0x001A			; display row/column
	nop
	ldada_24 xbc, 2708822		; 0x295556 - "Send File List" string
	nop
	call HDAE5000_Display_String
	call HDAE5000_Render_Display_Region
	call HDAE5000_Render_Display_Region2
	call 2713602			; call 0x296802 (prepare file list)
	ldda32_24 xix, 2330880		; XIX = [0x239100] (data source ptr)
	nop
	ld a, (xix)			; A = first byte
	stda8_24 2330850, a		; [0x2390E2] = first byte
	nop
	ld a, (xix + 1)			; A = second byte
	nop
	stda8_24 2330852, a		; [0x2390E4] = second byte
	nop
	call 2715144			; call 0x296E08 (process file list)
	call HDAE5000_Render_Display_Region2
	call HDAE5000_PPORT_Ready_Check
	lds bc, 0			; BC = 0 (offset)
	ldw hl, 0x002C			; HL = 44 (block size)
	nop
	call 2714308			; call 0x296AC4 (transfer setup)
	cpdi8_24 2330854, 0x00		; [0x2390E6] == 0? (error check)
	jpcc_24 6, 2712830		; jp Z, skip cleanup (0x2964FE)
	nop
	call HDAE5000_PPORT_Cleanup
.Lsfl_build_buffer:			; 0x2964FE
	ldada_24 xix, 2330984		; XIX = 0x239168 (PPORT cmd area)
	nop
	ldda8_24 a, 2330850		; A = [0x2390E2]
	nop
	ld (xix), a			; store to cmd[0]
	ldda8_24 a, 2330852		; A = [0x2390E4]
	nop
	ld (xix + 1), a			; store to cmd[1]
	nop
	add xix, 0x0000002C		; advance past header (44 bytes)
	; Copy 9 disk info fields (32-bit each) from 0x23910C-0x239150
	ldda32_24 xwa, 2330892		; [0x23910C]
	nop
	ld (xix), xwa
	inc 4, xix
	ldda32_24 xwa, 2330908		; [0x23911C]
	nop
	ld (xix), xwa
	inc 4, xix
	ldda32_24 xwa, 2330916		; [0x239124]
	nop
	ld (xix), xwa
	inc 4, xix
	ldda32_24 xwa, 2330924		; [0x23912C]
	nop
	ld (xix), xwa
	inc 4, xix
	ldda32_24 xwa, 2330932		; [0x239134]
	nop
	ld (xix), xwa
	inc 4, xix
	ldda32_24 xwa, 2330940		; [0x23913C]
	nop
	ld (xix), xwa
	inc 4, xix
	ldda32_24 xwa, 2330944		; [0x239140]
	nop
	ld (xix), xwa
	inc 4, xix
	ldda32_24 xwa, 2330952		; [0x239148]
	nop
	ld (xix), xwa
	inc 4, xix
	ldda32_24 xwa, 2330960		; [0x239150]
	nop
	ld (xix), xwa
	call HDAE5000_PPORT_Sum_Buffer
	cpdi8_24 2330836, 1		; [0x2390D4] == 1? (status check)
	jpcc_24 6, 2708340		; jp Z, exit to PPORT finish (0x295374)
	nop
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_PPORT_Cmd_ReceiveDataBlock:	; 0x296588
	; Receive data from PC - display status and finish
	ldw wa, 0x001A			; display row/column
	nop
	ldada_24 xbc, 2708846		; 0x29556E - "Receive Data" string
	nop
	call HDAE5000_Display_String
	jp HDAE5000_PPORT_Cmd_Done

HDAE5000_PPORT_Cmd_WriteMemoryToHD:	; 0x29659A (230 bytes)
	; Save memory to HD with sector/head masking and multi-step transfer.
	ldw wa, 0x001A			; display row/column
	nop
	ldada_24 xbc, 2708870		; 0x295586 - "Write Memory" string
	nop
	call HDAE5000_Display_String
	call HDAE5000_Render_Display_Region
	call HDAE5000_Render_Display_Region2
	call 2713602			; call 0x296802 (prepare data)
	call HDAE5000_PPORT_Ready_Check
	lds bc, 0			; BC = 0
	ldw hl, 0x00C8			; HL = 200 (block size)
	nop
	call 2714308			; call 0x296AC4 (transfer setup)
	ldada_24 xix, 2330984		; XIX = 0x239168 (PPORT cmd area)
	nop
	ld a, (xix)			; A = cmd[0]
	stda8_24 2330846, a		; [0x2390DE] = cmd[0] (raw sector byte)
	nop
	ldda8_24 w, 2330842		; W = [0x2390DA] (sector mask)
	nop
	and w, a			; W = cmd[0] AND sector_mask
	stda8_24 2330850, w		; [0x2390E2] = masked sector
	nop
	ld (xix), w			; update cmd[0] with masked value
	ld a, (xix + 1)			; A = cmd[1]
	nop
	stda8_24 2330848, a		; [0x2390E0] = cmd[1] (raw head byte)
	nop
	ldda8_24 w, 2330844		; W = [0x2390DC] (head mask)
	nop
	and w, a			; W = cmd[1] AND head_mask
	stda8_24 2330852, w		; [0x2390E4] = masked head
	nop
	ld (xix + 1), w			; update cmd[1] with masked value
	nop
	call HDAE5000_PPORT_Sum_Buffer
	cpdi8_24 2330836, 1		; [0x2390D4] == 1? (status check)
	jpcc_24 6, 2708340		; jp Z → exit to PPORT finish (0x295374)
	nop
	cpdi8_24 2330850, 0x00		; masked sector == 0?
	jpcc_24 6, 2713116		; jp Z → check head (0x29661C)
	nop
	jp 2713128			; jp → do write (0x296628)
.Lwmhd_check_head:			; 0x29661C
	cpdi8_24 2330852, 0x00		; masked head == 0?
	jpcc_24 6, 2713212		; jp Z → done (0x29667C)
	nop
.Lwmhd_do_write:			; 0x296628
	call HDAE5000_PPORT_Ready_Check
	ldda32_24 xix, 2330880		; XIX = [0x239100] (data source ptr)
	nop
	ldda8_24 a, 2330850		; A = masked sector
	nop
	ld (xix), a			; store to data[0]
	ldda8_24 a, 2330852		; A = masked head
	nop
	ld (xix + 1), a			; store to data[1]
	nop
	xor xbc, xbc			; XBC = 0
	xor xde, xde			; XDE = 0
	ldda8_24 c, 2330838		; C = [0x2390D6] (sector param)
	nop
	ldda8_24 e, 2330840		; E = [0x2390D8] (head param)
	nop
	ldw wa, 0x001B			; WA = 0x1B (write command)
	nop
	ei 0x00				; disable interrupts
	call HDAE5000_Display_String
	ei 0x07				; enable interrupts
	cps wa, 0			; result == 0?
	jpcc_24 6, 2713196		; jp Z → skip error (0x29666C)
	nop
	call HDAE5000_PPORT_Cleanup
.Lwmhd_after_write:			; 0x29666C
	call HDAE5000_PPORT_Sum_Buffer
	cpdi8_24 2330836, 1		; [0x2390D4] == 1?
	jpcc_24 6, 2708340		; jp Z → exit (0x295374)
	nop
.Lwmhd_done:				; 0x29667C
	jp HDAE5000_PPORT_Cmd_Done

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
	; PPORT utility routine 3 — display string, read PPORT data, execute,
	; check status, display result string (success or error)
	ldw wa, 0x001A				; display command
	nop
	ldada_24 xbc, 2708966			; lda XBC, 0x2955E6 — string pointer
	nop
	call HDAE5000_Display_String
	lds32 xbc, 0
	lds32 xde, 0
	ldw wa, 0x001D				; display command
	nop
	call HDAE5000_Display_String
	ei 7					; enable interrupts
	ldada_24 xix, 2330984			; lda XIX, 0x239168 — PPORT command area
	nop
	ld xwa, (xix + 2)			; read 32-bit parameter
	nop
	stda32_24 2330884, xwa			; st (0x239104), XWA — store parameter
	nop
	ld xiy, 0x00010000			; block size 64KB
	nop
	ldda32_24 xde, 2330884			; ld XDE, (0x239104)
	nop
	call 2714494				; call 0x296B7E — execute operation
	cpdi8_24 2330836, 0x01			; cp (0x2390D4), 1 — check status flag
	jpcc_24 6, 2708340			; jp Z, 0x295374 — abort if status=1
	nop
	ld xbc, 0x00010000			; block size
	nop
	ld xde, 0x00239104			; data address (immediate)
	nop
	ldw wa, 0x001C				; display command
	nop
	call HDAE5000_Display_String
	stda16_24 2330874, xwa			; st (0x2390FA), WA — save result
	nop
	di					; disable interrupts
	lds32 xbc, 0
	lds32 xde, 0
	ldw wa, 0x001E				; display command
	nop
	call HDAE5000_Display_String
	ldda16_24 xwa, 2330874			; ld WA, (0x2390FA) — reload result
	nop
	cp wa, 0x0058				; check result value
	jpcc_24 6, 2713502			; jp Z, 0x29679E — jump if success
	nop
	; Error path
	ldw wa, 0x001A				; display command
	nop
	ldada_24 xbc, 2709012			; lda XBC, 0x295614 — error string
	nop
	call HDAE5000_Display_String
	jp HDAE5000_PPORT_Cmd_Done
.Lpu3_success:
	; Success path
	ldw wa, 0x001A				; display command
	nop
	ldada_24 xbc, 2708990			; lda XBC, 0x2955FE — success string
	nop
	call HDAE5000_Display_String
	jp HDAE5000_PPORT_Cmd_Done

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

HDAE5000_Render_Display_Region2:	; 0x2967E4 (166 bytes)
	; Display region rendering 2 — load display params and call Display_String
	xor xbc, xbc				; clear XBC
	xor xde, xde				; clear XDE
	ldda8_24 c, 2330838			; ld C, (0x2390D6) — column
	nop
	ldda8_24 e, 2330840			; ld E, (0x2390D8) — row
	nop
	ldw wa, 0x000D				; display command
	nop
	di					; disable interrupts
	call HDAE5000_Display_String
	ei 7					; enable interrupts
	ret
	nop
.Lrdr2_register:			; 0x296802
	; Set WA=1, call Display_String, store XIX to data source ptr
	lds wa, 1
	di
	call HDAE5000_Display_String
	ei 7
	stda32_24 2330880, xix			; st (0x239100), XIX — data source ptr
	nop
	ret
	nop
.Lrdr2_main:				; 0x296814
	; Buffer read loop: read 256 bytes via I/O, accumulate 32-bit checksum,
	; then send 4 checksum bytes, finalize
	xor xwa, xwa
	stda32_24 2330876, xwa			; st (0x2390FC), XWA — clear checksum
	nop
	lds bc, 0				; counter = 0
	ldada_24 xix, 2330984			; lda XIX, 0x239168
	nop
.Lrdr2_loop1:				; 0x296824
	cp bc, 0x0100				; 256 iterations?
	jpcc_24 6, 2713682			; jp Z, 0x296852 — exit loop
	nop
	call 2713856				; call 0x296900 — read one byte → W
	cpdi8_24 2330836, 0x01			; cp (0x2390D4), 1 — error check
	jpcc_24 6, 2713736			; jp Z, 0x296888 — exit on error
	nop
	lda_dri3 xwa, 0x07, 0xF0, 0xE4		; ld (XIX+BC), W — store byte to buffer
	nop
	xor xhl, xhl				; XHL = 0
	ld l, w					; L = W (zero-extend byte to 32-bit)
	adddm32_24 2330876, xhl		; add (0x2390FC), XHL — accumulate checksum
	nop
	inc 1, bc				; BC++
	jr t, .Lrdr2_loop1			; loop
.Lrdr2_send_checksum:			; 0x296852
	; Send 4 checksum bytes
	lds bc, 0				; counter = 0
	ldada_24 xix, 2330876			; lda XIX, 0x2390FC — checksum
	nop
.Lrdr2_loop2:				; 0x29685A
	cps bc, 4				; 4 bytes?
	jpcc_24 6, 2713724			; jp Z, 0x29687C — exit loop
	nop
	ld_srib3 w, 0x07, 0xF0, 0xE4		; ld W, (XIX+BC) — load checksum byte
	nop
	call 2714016				; call 0x2969A0 — send one byte
	cpdi8_24 2330836, 0x01			; cp (0x2390D4), 1 — error check
	jpcc_24 6, 2713736			; jp Z, 0x296888 — exit on error
	nop
	inc 1, bc				; BC++
	jr t, .Lrdr2_loop2			; loop
.Lrdr2_finalize:			; 0x29687C
	call 2714160				; call 0x296A30 — finalize transfer
	cps w, 0				; check result
	jr z, .Lrdr2_exit			; exit if done
	jp .Lrdr2_main				; retry main loop
.Lrdr2_exit:				; 0x296888
	ret
	nop

HDAE5000_PPORT_Sum_Buffer:	; 0x29688A (530 bytes)
	; Sum 256 bytes from buffer, send checksum, then send buffer bytes;
	; retry on success, return on error. Uses PPORT I/O read/write sub-routines.
	xor xwa, xwa
	stda32_24 2330876, xwa			; st (0x2390FC), XWA — clear 32-bit checksum
	nop
	lds bc, 0				; counter = 0
	ldada_24 xix, 2330984			; lda XIX, 0x239168
	nop
.Lpsb_loop1:				; 0x29689A — send buffer bytes and accumulate checksum
	cp bc, 0x0100				; 256 iterations?
	jpcc_24 6, 2713800			; jp Z, 0x2968C8 — done, send checksum
	nop
	ld_srib3 w, 0x07, 0xF0, 0xE4		; ld W, (XIX+BC) — read buffer byte
	nop
	xor xhl, xhl
	ld l, w					; L = W (zero-extend to 32-bit)
	adddm32_24 2330876, xhl		; add (0x2390FC), XHL — accumulate
	nop
	call .Lpsb_write_byte			; send byte via PPORT
	cpdi8_24 2330836, 0x01			; cp (0x2390D4), 1 — error?
	jpcc_24 6, 2713854			; jp Z, 0x2968FE — exit on error
	nop
	inc 1, bc
	jr t, .Lpsb_loop1
.Lpsb_send_checksum:			; 0x2968C8
	lds bc, 0
	ldada_24 xix, 2330876			; lda XIX, 0x2390FC — checksum bytes
	nop
.Lpsb_loop2:				; 0x2968D0 — send 4 checksum bytes
	cps bc, 4
	jpcc_24 6, 2713842			; jp Z, 0x2968F2 — done
	nop
	ld_srib3 w, 0x07, 0xF0, 0xE4		; ld W, (XIX+BC) — checksum byte
	nop
	call .Lpsb_write_byte			; send byte
	cpdi8_24 2330836, 0x01			; error check
	jpcc_24 6, 2713854			; jp Z, 0x2968FE — exit on error
	nop
	inc 1, bc
	jr t, .Lpsb_loop2
.Lpsb_finalize:				; 0x2968F2
	call .Lpsb_finish			; finalize transfer
	cps w, 0				; check result
	jr z, .Lpsb_exit
	jp HDAE5000_PPORT_Sum_Buffer		; retry
.Lpsb_exit:				; 0x2968FE
	ret
	nop
.Lpsb_read_byte:			; 0x296900 — Read one byte from parallel port → W
	; Handshake: wait for BUSY=1 (bit2=1), then DATA_READY (bit0=1),
	; read data, acknowledge, wait for completion
	ldda8_24 a, 1441796			; ld A, (0x160004) — read status
	nop
	ld l, a
	and l, 0x04				; test bit 2
	nop
	cps l, 4				; BUSY?
	jpcc_24 14, 2714008			; jp NZ, 0x296998 — error if not busy
	nop
	and a, 0x01				; test bit 0
	nop
	cps a, 1				; DATA_READY?
	jpcc_24 14, 2713856			; jp NZ, 0x296900 — retry
	nop
.Lpsb_read_phase2:			; 0x296920
	ldda8_24 a, 1441796			; ld A, (0x160004)
	nop
	ld l, a
	and l, 0x04
	nop
	cps l, 4
	jpcc_24 14, 2714008			; jp NZ, error
	nop
	and a, 0x02				; test bit 1
	nop
	cps a, 0				; wait for bit1=0
	jpcc_24 14, 2713888			; jp NZ, 0x296920 — retry
	nop
	ldb a, 0x99				; command byte — request read
	stda8_24 1441798, a			; st (0x160006), A — send command
	nop
	ldda8_24 a, 1441794			; ld A, (0x160002) — control register
	nop
	and a, 0xF7				; clear bit 3
	nop
	stda8_24 1441794, a			; st (0x160002), A
	nop
.Lpsb_read_phase3:			; 0x296958
	ldda8_24 a, 1441796			; ld A, (0x160004) — status
	nop
	ld l, a
	and l, 0x04
	nop
	cps l, 4
	jpcc_24 14, 2714008			; jp NZ, error
	nop
	and a, 0x02
	nop
	cps a, 2				; wait for bit1=1
	jpcc_24 14, 2713944			; jp NZ, 0x296958 — retry
	nop
	ldda8_24 w, 1441792			; ld W, (0x160000) — read data byte
	nop
	ldb a, 0x89				; acknowledge byte
	stda8_24 1441798, a			; st (0x160006), A
	nop
	ldda8_24 a, 1441794			; ld A, (0x160002)
	nop
	or a, 0x08				; set bit 3
	nop
	stda8_24 1441794, a			; st (0x160002), A
	nop
	ret
	nop
.Lpsb_read_error:			; 0x296998
	stdi8_24 2330836, 0x01			; st (0x2390D4), 1 — set error flag
	ret
	nop
.Lpsb_write_byte:			; 0x2969A0 — Write byte W to parallel port
	; Handshake: wait for BUSY=1 (bit2=1), then READY (bit0=0),
	; write data, signal, wait for ack
	ldda8_24 a, 1441796			; ld A, (0x160004) — status
	nop
	ld l, a
	and l, 0x04
	nop
	cps l, 4
	jpcc_24 14, 2714152			; jp NZ, 0x296A28 — error
	nop
	and a, 0x01
	nop
	cps a, 0				; wait for bit0=0
	jpcc_24 14, 2714016			; jp NZ, 0x2969A0 — retry
	nop
	stda8_24 1441792, w			; st (0x160000), W — write data
	nop
	ldda8_24 a, 1441794			; ld A, (0x160002)
	nop
	and a, 0xF7				; clear bit 3
	nop
	stda8_24 1441794, a			; st (0x160002), A
	nop
.Lpsb_write_phase2:			; 0x2969D6
	ldda8_24 a, 1441796			; ld A, (0x160004)
	nop
	ld l, a
	and l, 0x04
	nop
	cps l, 4
	jpcc_24 14, 2714152			; jp NZ, error
	nop
	and a, 0x02
	nop
	cps a, 0				; wait for bit1=0
	jpcc_24 14, 2714070			; jp NZ, 0x2969D6 — retry
	nop
	ldda8_24 a, 1441794			; ld A, (0x160002)
	nop
	or a, 0x08				; set bit 3
	nop
	stda8_24 1441794, a			; st (0x160002), A
	nop
.Lpsb_write_phase3:			; 0x296A06
	ldda8_24 a, 1441796			; ld A, (0x160004)
	nop
	ld l, a
	and l, 0x04
	nop
	cps l, 4
	jpcc_24 14, 2714152			; jp NZ, error
	nop
	and a, 0x02
	nop
	cps a, 2				; wait for bit1=1
	jpcc_24 14, 2714118			; jp NZ, 0x296A06 — retry
	nop
	ret
	nop
.Lpsb_write_error:			; 0x296A28
	stdi8_24 2330836, 0x01			; st (0x2390D4), 1 — set error flag
	ret
	nop
.Lpsb_finish:				; 0x296A30 — Finalize parallel port transfer
	; Deassert, wait for completion, read final status bit
	ldda8_24 a, 1441794			; ld A, (0x160002)
	nop
	and a, 0xF7				; clear bit 3
	nop
	stda8_24 1441794, a			; st (0x160002), A
	nop
.Lpsb_fin_wait1:			; 0x296A40
	ldda8_24 a, 1441796			; ld A, (0x160004)
	nop
	ld l, a
	and l, 0x04
	nop
	cps l, 4
	jpcc_24 14, 2714260			; jp NZ, 0x296A94 — error
	nop
	and a, 0x02
	nop
	cps a, 0				; wait for bit1=0
	jr nz, .Lpsb_fin_wait1			; retry
	ldda8_24 w, 1441796			; ld W, (0x160004) — final status
	nop
	and w, 0x01				; extract bit 0 → result
	nop
	ldda8_24 a, 1441794			; ld A, (0x160002)
	nop
	or a, 0x08				; set bit 3
	nop
	stda8_24 1441794, a			; st (0x160002), A
	nop
.Lpsb_fin_wait2:			; 0x296A76
	ldda8_24 a, 1441796			; ld A, (0x160004)
	nop
	ld l, a
	and l, 0x04
	nop
	cps l, 4
	jpcc_24 14, 2714260			; jp NZ, error
	nop
	and a, 0x02
	nop
	cps a, 2				; wait for bit1=1
	jr nz, .Lpsb_fin_wait2			; retry
	ret
	nop
.Lpsb_fin_error:			; 0x296A94
	stdi8_24 2330836, 0x01			; st (0x2390D4), 1 — set error flag
	ret
	nop

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
	; sprintf-like formatter entry point (handles %e, %E, %f, %F, %g, %G)
	; Allocates 26-byte stack frame, dispatches to String_Format_Core or
	; String_Format_Output based on format specifier character in C register.
	lda xsp, (xsp - 26)		; allocate 26-byte stack frame
	push xiz			; save XIZ
	ldmw (xsp + 4), 0x0000		; clear local variable
	lda xwa, (xsp + 6)		; XWA = &local[2]
	push xwa			; push output buffer ptr
	lda xwa, (xsp + 8)		; XWA = &local[4] (adjusted)
	push xwa			; push another ptr
	pushm (xsp + 0x34)		; push caller param
	lda xwa, (xsp + 0x12)		; XWA = &local[14]
	push xwa			; push ptr
	ld xwa, (xsp + 0x36)		; load caller's 32-bit param
	push xwa			; push value
	call 2732154			; call 0x29B07A (setup utility)
	lda xsp, (xsp + 0x12)		; deallocate 18 bytes of args
	stdi16_24 2331784, 0x0000	; [0x239488] = 0 (clear format state)
	lda xde, (xsp + 8)		; XDE = &local[4]
	ld xiy, xde			; XIY = format output ptr
	ld c, (xsp + 0x22)		; C = format specifier char
	ld xiz, (xsp + 0x24)		; XIZ = caller param
	ld ix, (xsp + 0x2E)		; IX = precision
	ld hl, (xsp + 0x30)		; HL = width
	ld a, c				; A = specifier char
	exts wa				; sign-extend A to WA
	cp c, 0x65			; specifier == 'e'?
	jr z, .Lsf_e_format
	cp c, 0x45			; specifier == 'E'?
	jr nz, .Lsf_not_eE
.Lsf_e_format:
	pushm (xsp + 0x06)		; push param
	pushm (xsp + 0x06)		; push param
	push xiy			; push output ptr
	pushw hl			; push width
	pushw ix			; push precision
	pushm (xsp + 0x38)		; push caller param
	push xiz			; push XIZ
	pushw wa			; push specifier
	jr t, .Lsf_call_output		; always → String_Format_Output
.Lsf_not_eE:
	cp c, 0x66			; specifier == 'f'?
	jr z, .Lsf_f_format
	cp c, 0x46			; specifier == 'F'?
	jr nz, .Lsf_not_fF
.Lsf_f_format:
	pushm (xsp + 0x06)		; push param
	pushm (xsp + 0x06)		; push param
	push xiy			; push output ptr
	pushw hl			; push width
	pushw ix			; push precision
	pushm (xsp + 0x38)		; push caller param
	push xiz			; push XIZ
	pushw wa			; push specifier
.Lsf_call_core:
	calr HDAE5000_String_Format_Core
	lda xsp, (xsp + 0x14)		; deallocate 20 bytes of args
	jr t, .Lsf_cleanup		; always → cleanup
.Lsf_not_fF:				; g/G format handling
	ld wa, (xsp + 0x2C)		; WA = flags
	bit 4, wa			; bit 4 set?
	jr nz, .Lsf_have_precision
	lds hl, 6			; default precision = 6
	setm 4, (xsp + 0x2C)		; set precision flag
.Lsf_have_precision:
	exts bc				; sign-extend C to BC
	pushm (xsp + 0x06)		; push param
	pushm (xsp + 0x06)		; push param
	push xde			; push XDE
	pushw hl			; push width
	pushw ix			; push precision
	pushm (xsp + 0x38)		; push caller param
	push xiz			; push XIZ
	pushw bc			; push specifier (extended)
	cpmi16 (xsp + 0x18), 0xFFFC	; compare local with -4?
	jr le, .Lsf_call_output		; if LE → output
	cp (xsp + 0x18), hl		; compare local with width
	jr le, .Lsf_call_core		; if LE → use Core formatter
.Lsf_call_output:
	calr HDAE5000_String_Format_Output
	lda xsp, (xsp + 0x14)		; deallocate 20 bytes of args
.Lsf_cleanup:
	pop xiz				; restore XIZ
	lda xsp, (xsp + 0x1A)		; deallocate 26-byte stack frame
	ret

HDAE5000_String_Format_Core:	; 0x29A563 (805 bytes)
	; Core string format engine - processes format specifiers
	.incbin "includes/code_2971b7_29ae9e.bin", 13228, 805

HDAE5000_String_Format_Output:	; 0x29A888 (848 bytes)
	; Output handler for string formatter
	.incbin "includes/code_2971b7_29ae9e.bin", 14033, 848

HDAE5000_PPI_Block_Copy:	; 0x29ABD8 (237 bytes)
	; PPI block copy/transfer with callback-based byte output.
	; Contains 4 sub-routines: 2 setup variants, 1 callback, 1 int-to-string converter.
	;
	; --- Sub 1: Setup variant 1 (with extra stack param) ---
	; Stack: [+0x08] = buffer ptr, [+0x10] = params, [+0x14] = format data
	dec 4, xsp			; allocate 4 bytes
	ld xwa, (xsp + 8)		; XWA = buffer ptr
	stda32_24 2331778, xwa		; [0x239482] = buffer ptr
	ldmi8 (xwa), 0x00		; null-terminate buffer
	lda xwa, (xsp + 0x10)		; XWA = &param area
	ld (xsp), xwa			; save to local
	pushw 0x0029			; push callback addr high word
	pushw 0xAC21			; push callback addr low (→ 0x0029AC21)
	lda xwa, (xsp + 4)		; XWA = &callback addr on stack
	push xwa			; push callback ptr
	ld xwa, (xsp + 0x14)		; XWA = format data
	push xwa			; push
	call 2726631			; call 0x299AE7 (PPI transfer engine)
	lda xsp, (xsp + 0x10)		; cleanup 16 bytes
	ret
	;
	; --- Sub 2: Setup variant 2 (simpler) ---
	ld xwa, (xsp + 4)		; XWA = buffer ptr
	stda32_24 2331778, xwa		; [0x239482] = buffer ptr
	ldmi8 (xwa), 0x00		; null-terminate buffer
	pushw 0x0029			; push callback addr high word
	pushw 0xAC21			; push callback addr low
	lda xwa, (xsp + 0x10)		; XWA = &callback addr on stack
	push xwa			; push callback ptr
	ld xwa, (xsp + 0x10)		; XWA = format data
	push xwa			; push
	call 2726631			; call 0x299AE7
	lda xsp, (xsp + 0x0C)		; cleanup 12 bytes
	ret
	;
	; --- Sub 3: Byte-write callback (called by PPI engine) ---
	; Appends one byte to buffer at [0x239482], advances pointer, null-terminates.
.Lppi_callback:				; 0x29AC21
	ldda32_24 xbc, 2331778		; XBC = [0x239482] (current buffer ptr)
	lds32 xwa, 1			; XWA = 1
	adddm32_24 2331778, xwa	; [0x239482]++ (advance ptr)
	ld wa, (xsp + 4)		; WA = character to write
	ld (xbc), a			; store character at buffer
	ldda32_24 xwa, 2331778		; XWA = new buffer ptr
	ldmi8 (xwa), 0x00		; null-terminate
	ret
	;
	; --- Sub 4: Integer to base-N string converter ---
	; Stack: [+0x1A] = value, [+0x1C] = output ptr, [+0x20] = radix
	; Handles signed decimal (radix 10), validates radix 2-36.
	; Uses QBC (previous register bank) to hold the working value.
	lda xsp, (xsp - 18)		; allocate 18-byte frame
	push xiz			; save XIZ
	ld xhl, (xsp + 0x1C)		; XHL = output buffer ptr
	lds ix, 0			; IX = 0 (sign = positive)
	ld bc, (xsp + 0x20)		; BC = radix
	cps bc, 2			; radix < 2?
	jr lt, .Lppi_empty		; → invalid, output empty string
	cp bc, 0x0024			; radix > 36?
	jr le, .Lppi_convert		; → valid, start conversion
.Lppi_empty:
	ldmi8 (xhl), 0x00		; *output = '\0'
	jr t, .Lppi_done		; → exit
.Lppi_convert:
	ld wa, (xsp + 0x1A)		; WA = value to convert
	.byte 0xD7, 0xE6, 0x98		; ld QBC, WA (save value in prev bank)
	lda xiz, (xsp + 4)		; XIZ = &local scratch buffer
	ldmi8 (xiz + 0x11), 0x00	; null-terminate scratch[17]
	lda xiy, (xiz + 0x10)		; XIY = scratch end pointer
	cp bc, 0x000A			; radix == 10? (decimal)
	jr nz, .Lppi_div_loop		; → unsigned for other radixes
	.byte 0xD7, 0xE6, 0x88		; ld WA, QBC (reload value)
	cps wa, 0			; value < 0? (signed check)
	jr ge, .Lppi_div_loop		; → non-negative
	lds ix, 1			; IX = 1 (negative flag)
	.byte 0xD7, 0xE6, 0x88		; ld WA, QBC (reload value)
	neg wa				; negate (make positive)
	.byte 0xD7, 0xE6, 0x98		; ld QBC, WA (save positive value)
.Lppi_div_loop:
	ld de, bc			; DE = radix (divisor)
	.byte 0xD7, 0xE6, 0x88		; ld WA, QBC (current value)
	extz xwa			; zero-extend WA to XWA
	div xwa, xde			; XWA = WA / DE (quot in WA, rem in high)
	.byte 0xD7, 0xE2, 0x88		; ld WA, QWA (get remainder)
	add a, 0x30			; convert to ASCII '0'-'9'
	ld (xiy), a			; store digit
	cpmi8 (xiy), 0x39		; digit > '9'?
	jr le, .Lppi_digit_ok		; → it's 0-9
	addmi8 (xiy), 0x27		; adjust for 'a'-'z' (0x30+0x27=0x57→'W'+n)
.Lppi_digit_ok:
	.byte 0xD7, 0xE6, 0x88		; ld WA, QBC (reload quotient)
	extz xwa			; zero-extend
	div xwa, xde			; divide again to get next quotient
	.byte 0xD7, 0xE6, 0x98		; ld QBC, WA (save new quotient)
	.byte 0xD7, 0xE6, 0xD8		; cp QBC, 0 (quotient == 0?)
	jr z, .Lppi_digits_done		; → all digits extracted
	dec 1, xiy			; move digit pointer back
	jr t, .Lppi_div_loop		; → next digit
.Lppi_digits_done:
	cps ix, 0			; negative flag set?
	jr z, .Lppi_copy_digits		; → no sign needed
	stib_dpd 0xF4, 0x2D		; ld (-XIY), '-' (pre-decrement, store minus sign)
.Lppi_copy_digits:
	lda xwa, (xiz + 0x12)		; XWA = &scratch[18] (past null-terminator)
	sub xwa, xiy			; XWA = string length (including null)
	pushw wa			; push length
	push xiy			; push source ptr
	push xhl			; push destination ptr
	call HDAE5000_MemCopy		; copy digit string to output
	lda xsp, (xsp + 0x0A)		; cleanup 10 bytes
.Lppi_done:
	pop xiz				; restore XIZ
	lda xsp, (xsp + 0x12)		; deallocate 18-byte frame
	ret

HDAE5000_Cell_Copy_Buffer:	; 0x29ACC5 (263 bytes)
	; Cell buffer copy + integer-to-string conversion (3 sub-routines).
	;
	; --- Sub 1: Cell copy buffer (0x29ACC5-0x29AD07, 67 bytes) ---
	; Calls multiply/divide utilities, copies 8 bytes via LDIRW.
	lda xsp, (xsp - 16)		; allocate 16-byte frame
	push xiz			; save XIZ
	ld xwa, (xsp + 0x20)		; XWA = param (format ptr?)
	or xwa, xwa			; zero check
	jr z, .Lccb_copy		; skip if null
	lda xwa, (xsp + 0x0C)		; XWA = &local[12]
	ld (xsp + 8), xwa		; save ptr A
	ld (xsp + 4), xwa		; save ptr B
	ld xiz, (xsp + 0x1C)		; XIZ = source data ptr
	ld xwa, xiz			; XWA = source ptr
	ld xbc, (xsp + 0x20)		; XBC = format param
	call 2734267			; call 0x29B8BB (multiply variant 1)
	ld xwa, (xsp + 4)		; reload ptr B
	ld (xwa), xhl			; store result to local
	ld xwa, xiz			; XWA = source ptr
	ld xbc, (xsp + 0x20)		; XBC = format param
	call 2734263			; call 0x29B8B7 (multiply variant 2)
	ld xwa, (xsp + 8)		; reload ptr A
	ld (xwa + 4), xhl		; store result to local+4
.Lccb_copy:
	ld xix, (xsp + 0x18)		; XIX = destination ptr
	lda xiy, (xsp + 0x0C)		; XIY = &local[12] (source)
	lds bc, 4			; BC = 4 (copy 4 words = 8 bytes)
	ldirw				; block copy 16-bit × 4
	pop xiz				; restore XIZ
	lda xsp, (xsp + 0x10)		; deallocate 16-byte frame
	ret
	;
	; --- Sub 2: Signed number format handler (0x29AD08-0x29AD43, 60 bytes) ---
	; Prepends '-' for negative values when radix==10, then calls Sub 3.
.Lccb_sign_handler:			; 0x29AD08
	ld xbc, (xsp + 8)		; XBC = output buffer ptr
	ld xde, (xsp + 4)		; XDE = value to convert
	ld wa, (xsp + 0x0C)		; WA = radix
	cp wa, 0x000A			; radix == 10? (decimal)
	jr nz, .Lccb_unsigned		; → unsigned conversion
	cp xde, 0x00000000		; value < 0? (signed check)
	jr ge, .Lccb_unsigned		; → non-negative
	; Negative decimal: prepend '-' and negate
	ldmi8 (xbc), 0x2D		; store '-' at buffer start
	pushw wa			; push radix
	lda xwa, (xbc + 1)		; XWA = buffer+1 (past '-')
	push xwa			; push output ptr
	cpl de				; complement DE (bitwise NOT)
	.byte 0xD7, 0xEA, 0x06		; cpl QDE (complement high word)
	inc 1, xde			; +1 → two's complement negate
	push xde			; push negated value
	call .Lccb_converter		; call base-N converter
	lda xsp, (xsp + 0x0A)		; cleanup 10 bytes
	dec 1, xhl			; adjust string length for '-'
	ret
.Lccb_unsigned:
	pushw wa			; push radix
	push xbc			; push output ptr
	push xde			; push value
	call .Lccb_converter		; call base-N converter
	lda xsp, (xsp + 0x0A)		; cleanup 10 bytes
	ret
	;
	; --- Sub 3: General base-N string converter (0x29AD44-0x29ADCB, 136 bytes) ---
	; Converts integer to string with radix 2-36.
	; Stack: [+0x36] = value, [+0x3A] = output ptr, [+0x3E] = radix
.Lccb_converter:			; 0x29AD44
	lda xsp, (xsp - 46)		; allocate 46-byte frame
	push xiz			; save XIZ
	cpmi16 (xsp + 0x3E), 0x0002	; radix < 2?
	jr lt, .Lccb_invalid		; → invalid
	cpmi16 (xsp + 0x3E), 0x0024	; radix > 36?
	jr le, .Lccb_start		; → valid
.Lccb_invalid:
	ld xwa, (xsp + 0x3A)		; XWA = output buffer
	ldmi8 (xwa), 0x00		; output empty string
	jr t, .Lccb_conv_done		; → exit
.Lccb_start:
	lda xwa, (xsp + 0x10)		; XWA = &local scratch
	ld (xsp + 8), xwa		; save scratch base ptr
	ldmi8 (xwa + 0x20), 0x00	; null-terminate scratch[32]
	ld xwa, (xsp + 8)		; reload scratch ptr
	lda xwa, (xwa + 0x1F)		; XWA = &scratch[31] (digit fill ptr)
	ld (xsp + 4), xwa		; save digit ptr
	ld xiz, (xsp + 0x36)		; XIZ = value to convert
.Lccb_digit_loop:
	ld wa, (xsp + 0x3E)		; WA = radix
	exts xwa			; sign-extend radix to XWA
	ld (xsp + 0x0C), xwa		; save 32-bit radix
	ld xwa, xiz			; XWA = current value
	ld xbc, (xsp + 0x0C)		; XBC = radix
	call HDAE5000_Divide_Unsigned	; XHL = quotient, XDE = remainder
	add l, 0x30			; convert remainder to ASCII '0'-'9'
	ld xwa, (xsp + 4)		; reload digit ptr
	ld (xwa), l			; store digit char
	cpmi8 (xwa), 0x39		; digit > '9'?
	jr le, .Lccb_digit_ok		; → it's 0-9
	addmi8 (xwa), 0x27		; adjust for 'a'-'f' (+0x27)
.Lccb_digit_ok:
	ld xwa, xiz			; XWA = current value
	ld xbc, (xsp + 0x0C)		; XBC = radix
	call HDAE5000_Divide_Signed	; XHL = quotient
	ld xiz, xhl			; XIZ = new quotient
	or xiz, xiz			; quotient == 0?
	jr z, .Lccb_copy_result	; → all digits extracted
	lds32 xwa, 1			; XWA = 1
	sub (xsp + 4), xwa		; digit ptr-- (move backward)
	jr t, .Lccb_digit_loop		; → next digit
.Lccb_copy_result:
	ld xwa, (xsp + 8)		; reload scratch base
	lda xwa, (xwa + 0x21)		; XWA = &scratch[33] (past null-terminator)
	sub xwa, (xsp + 4)		; XWA = string length
	push xwa			; push length
	ld xwa, (xsp + 8)		; reload digit ptr
	push xwa			; push source
	ld xwa, (xsp + 0x42)		; XWA = output buffer (deep stack offset)
	push xwa			; push destination
	call HDAE5000_MemCopy		; copy digits to output
	lda xsp, (xsp + 0x0C)		; cleanup 12 bytes
.Lccb_conv_done:
	ld xhl, (xsp + 0x3A)		; XHL = output buffer (return value)
	pop xiz				; restore XIZ
	lda xsp, (xsp + 0x2E)		; deallocate 46-byte frame
	ret

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
	; Memory comparison (memcmp-like): compares BC bytes at XIX vs XIY
	; Stack: [+0x04] ptr1, [+0x08] ptr2, [+0x0C] length
	; Returns: HL = 0 if equal, HL = signed byte difference if not
	; Optimized: aligns to 4-byte boundary, then compares 32-bit words
	ld bc, (xsp + 12)		; BC = length
	lds hl, 0			; result = 0 (equal)
	cps bc, 0			; length == 0?
	ret z				; return if zero length
	ld xix, (xsp + 4)		; XIX = ptr1
	ld xiy, (xsp + 8)		; XIY = ptr2
	cp xix, xiy			; same pointer?
	ret z				; return if same
	ld de, ix			; DE = low 16 bits of ptr1
	neg de				; negate
	and de, 0x0003			; DE = bytes to 4-byte alignment
	jr z, .Lfr_aligned		; skip if already aligned
.Lfr_byte_loop1:
	ld_spib l, 0xF0			; L = *(XIX++)
	extz hl				; zero-extend L to HL
	ld_spib a, 0xF4			; A = *(XIY++)
	extz wa				; zero-extend A to WA
	sub hl, wa			; compare
	ret nz				; return if different
	sub bc, 0x0001			; decrement length
	ret z				; return if done
	djnz16 de, .Lfr_byte_loop1	; loop for alignment bytes
.Lfr_aligned:
	ld de, bc			; save remaining length
	srl bc, 2			; BC = number of 32-bit words
	jr z, .Lfr_remainder		; skip if no full words
.Lfr_word_loop:
	ld_spil xhl, 0xF2		; XHL = *(XIX++) (32-bit)
	ld_spil xwa, 0xF6		; XWA = *(XIY++) (32-bit)
	cp xhl, xwa			; compare 32-bit words
	jr z, .Lfr_word_next		; skip if equal
	; Words differ — find which byte differs
	cp hl, wa			; compare low 16 bits
	jr nz, .Lfr_check_byte		; if low halves differ
	.byte 0xD7, 0xEE, 0x8B		; ld hl, qhl (high word from prev bank)
	.byte 0xD7, 0xE2, 0x88		; ld wa, qwa (high word from prev bank)
.Lfr_check_byte:
	cp l, a				; compare low bytes
	jr nz, .Lfr_found_diff		; if different
	ld l, h				; move high byte to L
	ld a, w				; move high byte to A
.Lfr_found_diff:
	extz hl				; zero-extend L to HL
	extz wa				; zero-extend A to WA
	sub hl, wa			; HL = difference
	ret				; return
.Lfr_word_next:
	djnz16 bc, .Lfr_word_loop	; loop for remaining words
	lds hl, 0			; clear result (equal so far)
.Lfr_remainder:
	and de, 0x0003			; DE = remaining bytes
	ret z				; return if none
.Lfr_byte_loop2:
	ld_spib l, 0xF0			; L = *(XIX++)
	extz hl				; zero-extend L to HL
	ld_spib a, 0xF4			; A = *(XIY++)
	extz wa				; zero-extend A to WA
	sub hl, wa			; compare
	ret nz				; return if different
	djnz16 de, .Lfr_byte_loop2	; loop for remaining
	ret				; return (HL = 0, equal)

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
