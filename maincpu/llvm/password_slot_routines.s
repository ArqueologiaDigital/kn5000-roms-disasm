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

; All password slot labels (LABEL_F92C0E through LABEL_F94262) are now
; positioned labels in medley.asm. The binclude regions that previously
; covered F92C0E-F92CE7, F94193-F94269, and F9426A-F95082 have been
; removed since medley.asm produces the same bytes.
