
; Performance & Style screen widgets (477 widgets, 29164 bytes)
; Source: maincpu/ui_widgets/naka_perf_style.c (C struct with named fields)
NAKA_PerfReg_Container_Root:
	.incbin "includes/generated/naka_perf_style.bin"

; NAKA_UIObjectTable is at offset 0x4ADA within the binary blob above.
; Referenced from flash_floppy_handlers.s (RegisterObjectTable call).
	.equ NAKA_UIObjectTable, NAKA_PerfReg_Container_Root + 0x4ADA
