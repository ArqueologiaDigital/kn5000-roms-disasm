; =============================================================================
; boot_routines.asm - Common Boot Routines (Shared)
; =============================================================================
; This file contains boot routines that are structurally identical between
; the Main CPU ROM (maincpu) and Table Data ROM (table_data), differing only
; in RAM addresses and routine call targets.
;
; In maincpu: Located at 0xEF083E-0xEF08A0
; In table_data: Located at 0x9FB6D9-0x9FB738
;
; Required definitions before including this file:
;   REGION_CODE_VAR     - RAM address for region code storage
;                         (maincpu: 0x0408, table_data: 0x0C06)
;   BOOT_ENTRY_POINT    - Entry point for watchdog reset jump
;                         (maincpu: RESET_HANDLER, table_data: Boot_Init)
;   INDIRECT_CALL_HELPER - Address of indirect call routine
;                         (maincpu: 0xEF183D, table_data: 0xFFFA75)
;   INIT_HANDLER_TABLE  - Address of initialization handler table
;                         (maincpu: 0xFFFEF0, table_data: 0xFFFEF0)
;   INIT_FLAG_ADDR      - Address of init flag to check
;                         (maincpu: 0xFFFEEE, table_data: 0xFFFEEE)
;   CP_INIT_FLAG_ENCODING - Byte sequence for CP (INIT_FLAG_ADDR) comparison
;                         (maincpu uses 1-byte 0xFF, table_data uses 2-byte 0xFFFF)
;
; =============================================================================

; -----------------------------------------------------------------------------
; Detect_Region_Code - Detect region code from hardware switches
;
; Reads Port H bits 1 and 2 to determine the region:
;   PH.2=1, PH.1=1 -> Region 1
;   PH.2=1, PH.1=0 -> Region 2
;   PH.2=0, PH.1=1 -> Region 3
;   PH.2=0, PH.1=0 -> Region 4
;
; Entry: None
; Exit:  (REGION_CODE_VAR) = 1-4
; -----------------------------------------------------------------------------
Detect_Region_Code:
	bit_dd8 2, 0x44
	jr z, Detect_Region_Code__check_bit1_only
	bit_dd8 1, 0x44
	jr z, Detect_Region_Code__mode2
	stdi8 (3078), 1; Region 1
	ret
Detect_Region_Code__mode2:
	stdi8 (3078), 2; Region 2
	ret
Detect_Region_Code__check_bit1_only:
	bit_dd8 1, 0x44
	jr z, Detect_Region_Code__mode4
	stdi8 (3078), 3; Region 3
	ret
Detect_Region_Code__mode4:
	stdi8 (3078), 4; Region 4
	ret

; -----------------------------------------------------------------------------
; Get_Region_Code - Get stored region code value
;
; Entry: None
; Exit:  L = region code (1-4)
; -----------------------------------------------------------------------------
Get_Region_Code:
	ldb_d8 l, (3078)
	ret

; -----------------------------------------------------------------------------
; Empty_Handler - Empty interrupt handler
;
; Simply returns from interrupt without any processing.
; Used for unused interrupt vectors.
; -----------------------------------------------------------------------------
Empty_Handler:
	reti

; -----------------------------------------------------------------------------
; Watchdog_Reset_Handler - Watchdog interrupt handler
;
; Jumps back to boot entry point to restart initialization.
; This handles the case where the watchdog timer triggers during boot.
; -----------------------------------------------------------------------------
Watchdog_Reset_Handler:
	jrl Boot_Init
	reti	; Never reached

; End of shared boot routines
