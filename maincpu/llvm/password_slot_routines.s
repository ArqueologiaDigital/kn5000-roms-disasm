; NOTE: 19 segments reordered for forward-only ORGs

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

; Forward declarations for labels within the binary sections
; These allow external code to reference these routines by name

	.org 0xF92C0E - 0xE00000, 0xFF
LABEL_F92C0E:

	.org 0xF92C0E - 0xE00000, 0xFF
	.incbin "../includes/f92c0e_f92ce7.bin"

; =============================================================================
; Password slot storage routines (F94193 - F94269)
; =============================================================================

	.org 0xF92C13 - 0xE00000, 0xFF
LABEL_F92C13:

	.org 0xF92C21 - 0xE00000, 0xFF
LABEL_F92C21:

	.org 0xF92C70 - 0xE00000, 0xFF
LABEL_F92C70:

	.org 0xF92CAC - 0xE00000, 0xFF
LABEL_F92CAC:

	.org 0xF94193 - 0xE00000, 0xFF
LABEL_F94193:

	.org 0xF94193 - 0xE00000, 0xFF
	.incbin "../includes/f94193_f94269.bin"

; =============================================================================
; Gap between password routines and misc_ui.asm (F9426A - F95082)
; TODO: Disassemble this region
; =============================================================================

	.org 0xF941C8 - 0xE00000, 0xFF
LABEL_F941C8:

	.org 0xF941E5 - 0xE00000, 0xFF
LABEL_F941E5:

	.org 0xF941ED - 0xE00000, 0xFF
LABEL_F941ED:

	.org 0xF941F9 - 0xE00000, 0xFF
LABEL_F941F9:

	.org 0xF9420F - 0xE00000, 0xFF
LABEL_F9420F:

	.org 0xF94229 - 0xE00000, 0xFF
LABEL_F94229:

	.org 0xF94236 - 0xE00000, 0xFF
LABEL_F94236:

	.org 0xF94242 - 0xE00000, 0xFF
LABEL_F94242:

	.org 0xF9424A - 0xE00000, 0xFF
LABEL_F9424A:

	.org 0xF94250 - 0xE00000, 0xFF
LABEL_F94250:

	.org 0xF94256 - 0xE00000, 0xFF
LABEL_F94256:

	.org 0xF94262 - 0xE00000, 0xFF
LABEL_F94262:

; =============================================================================
; Password slot navigation routines (F92C0E - F92CE7)
; =============================================================================

	.org 0xF9426A - 0xE00000, 0xFF
	.incbin "../includes/f9426a_f95082.bin"

