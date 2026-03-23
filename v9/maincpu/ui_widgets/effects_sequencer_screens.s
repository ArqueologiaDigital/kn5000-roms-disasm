
; Effects & Sequencer screen widgets (555 widgets, 36540 bytes)
; Source: maincpu/ui_widgets/naka_effects_seq.c (C struct with named fields)
Naka_ReverbScreen_EmptyStr:
	.incbin "includes/generated/naka_effects_seq.bin"

; External label offsets within the binary blob above.
	.equ NakaInst_FADE_IN_OUT_SETTING, Naka_ReverbScreen_EmptyStr + 0x5BF2
	.equ Naka_Help_563_E300C0, Naka_ReverbScreen_EmptyStr + 0x811C
	.equ Naka_Help_564_E300C7, Naka_ReverbScreen_EmptyStr + 0x8123
	.equ Naka_Help_565_E300CC, Naka_ReverbScreen_EmptyStr + 0x8128
	.equ Naka_Help_566_E300E3, Naka_ReverbScreen_EmptyStr + 0x813F
	.equ Naka_Help_567_E300EC, Naka_ReverbScreen_EmptyStr + 0x8148
	.equ Naka_Help_569_E30113, Naka_ReverbScreen_EmptyStr + 0x816F
