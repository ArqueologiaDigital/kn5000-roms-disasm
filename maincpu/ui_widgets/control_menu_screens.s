
; Control Menu header widgets (9 widgets: CONTAINER + 7 MENU_ITEMs + TYPE_0x48)
; Source: maincpu/ui_widgets/control_menu_header.c (C struct with named fields)
	.incbin "includes/generated/naka_control_menu_header.bin"

; Control Menu body widgets (184 widgets across all sub-screens)
; Source: maincpu/ui_widgets/naka_ctrl_menu_body.c (C struct with named fields)
	.incbin "includes/generated/naka_ctrl_menu_body.bin"


; ===========================================================================
; CPU Data Transmission Error Dialog Widgets (Screen Group 7)
; ===========================================================================
; These widgets form the error dialog displayed when Sub-CPU payload
; transfer fails during boot. The dialog shows a severe hardware error
; that typically requires service center attention.
;
; Widget format:
;   Byte 0-1: Entry length (low byte) + 0x00
;   Byte 2-3: Widget type = 0x0160 (text widget)
;   Byte 4-5: Screen group ID (0x07 = error dialogs)
;   Byte 6-7: Flags (0xFFFF = default)
;   Byte 8-9: Widget index within screen group
;   Remaining: Widget-specific data (position, font, text)
; ===========================================================================

; ---------------------------------------------------------------------------
; Widget 9: CAUTION!! Header
; Screen group 7, index 9
; ---------------------------------------------------------------------------
ErrorDialog_CautionHeader:
	.byte 0x2b, 0x00	; Entry length: 43 bytes
