; =============================================================================
; password_slot_routines.asm - Password Slot Management Routines
; =============================================================================
; These routines manage password slots for file protection.
; Each song/file can have a password stored in one of 10 slots.
;
; Memory locations:
;   0x8942: Password value 1
;   0x8944: Password value 2
;   0x8504: Slot limit 1
;   0x8506: Slot limit 2
;   0x8508: Slot limit 3
;   0x09480E: External password slot storage
;   0x0AB000 + slot*0x800 + 0x1C: Password data per slot
;
; Key routines:
;   LABEL_F92C0E   - Get password value 1
;   LABEL_F92C13   - Get password value 2
;   LABEL_F92C21   - Navigate password slots (mode 1)
;   LABEL_F92C70   - Navigate password slots (mode 2)
;   LABEL_F92CAC   - Navigate password slots (mode 3)
;   LABEL_F94193   - Store password to slot
;   LABEL_F941C8   - Get password from slot
;   LABEL_F941F9   - Find first empty slot
;   LABEL_F9420F   - Store password to all slots
;   LABEL_F94229   - Find empty and store to all
;   LABEL_F94236   - Check if slot matches password
;   LABEL_F94242   - Check if any slot has password
;   LABEL_F9424A   - Set external password slot
;   LABEL_F94250   - Get external password slot
;   LABEL_F94256   - Check if external matches
;   LABEL_F94262   - Check if external has value
; =============================================================================

; Forward declarations for labels within the binary sections.
; Using EQU instead of ORG+label to avoid creating segment boundaries
; that would cut through preceding code (medley.asm extends past F92C0E).

LABEL_F92C0E	equ	0F92C0Eh
LABEL_F92C13	equ	0F92C13h
LABEL_F92C21	equ	0F92C21h
LABEL_F92C70	equ	0F92C70h
LABEL_F92CAC	equ	0F92CACh
LABEL_F94193	equ	0F94193h
LABEL_F941C8	equ	0F941C8h
LABEL_F941E5	equ	0F941E5h
LABEL_F941ED	equ	0F941EDh
LABEL_F941F9	equ	0F941F9h
LABEL_F9420F	equ	0F9420Fh
LABEL_F94229	equ	0F94229h
LABEL_F94236	equ	0F94236h
LABEL_F94242	equ	0F94242h
LABEL_F9424A	equ	0F9424Ah
LABEL_F94250	equ	0F94250h
LABEL_F94256	equ	0F94256h
LABEL_F94262	equ	0F94262h

; =============================================================================
; Password slot navigation routines (F92C0E - F92CE7)
; =============================================================================

	ORG 0F92C0Eh
	binclude "includes/f92c0e_f92ce7.bin"

; =============================================================================
; Password slot storage routines (F94193 - F94269)
; =============================================================================

	ORG 0F94193h
	binclude "includes/f94193_f94269.bin"

; =============================================================================
; Gap between password routines and misc_ui.asm (F9426A - F95082)
; TODO: Disassemble this region
; =============================================================================

	ORG 0F9426Ah
	binclude "includes/f9426a_f95082.bin"

