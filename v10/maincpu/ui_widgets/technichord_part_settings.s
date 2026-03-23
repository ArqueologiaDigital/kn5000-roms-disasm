
; Technichord Part Settings screen widgets (221 widgets, 17024 bytes)
; Source: maincpu/ui_widgets/naka_technichord_part.c (C struct with named fields)
NakaInst_TECHNI_CHORD:
	.incbin "includes/generated/naka_technichord_part.bin"

; External label offsets within the binary blob above.
	.equ Naka_KeyScaling_NavTrail, NakaInst_TECHNI_CHORD + 0x1132
