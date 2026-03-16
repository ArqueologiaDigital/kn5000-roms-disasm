; naka_accomp7_widgets.s — Accompaniment screen 7 widget descriptors
;
; 27 widgets for the accompaniment parameter editing screen.
; Two CONTAINER groups (0x35) with MENU_ITEM children, plus
; SEPARATOR (0x28), LIST (0x64), and SCROLLBAR (0x62) widgets.
; ROM address: 0xE1A73E (1050 bytes)

NakaNode_Accomp7_Widget01:
	.incbin "includes/generated/naka_accomp7_widgets.bin"
	.equ NakaNode_Accomp7_Widget02, NakaNode_Accomp7_Widget01 + 0x24
	.equ NakaNode_Accomp7_Widget03, NakaNode_Accomp7_Widget01 + 0x40
	.equ NakaNode_Accomp7_Widget04, NakaNode_Accomp7_Widget01 + 0x5C
	.equ NakaNode_Accomp7_Widget05, NakaNode_Accomp7_Widget01 + 0x76
	.equ NakaNode_Accomp7_Widget06, NakaNode_Accomp7_Widget01 + 0x8E
	.equ NakaNode_Accomp7_Widget07, NakaNode_Accomp7_Widget01 + 0xB2
	.equ NakaNode_Accomp7_Widget08, NakaNode_Accomp7_Widget01 + 0xDE
	.equ NakaNode_Accomp7_Widget09, NakaNode_Accomp7_Widget01 + 0x10A
	.equ NakaNode_Accomp7_Widget10, NakaNode_Accomp7_Widget01 + 0x136
	.equ NakaNode_Accomp7_Widget11, NakaNode_Accomp7_Widget01 + 0x162
	.equ NakaNode_Accomp7_Widget12, NakaNode_Accomp7_Widget01 + 0x18E
	.equ NakaNode_Accomp7_Widget13, NakaNode_Accomp7_Widget01 + 0x1BA
	.equ NakaNode_Accomp7_Widget14, NakaNode_Accomp7_Widget01 + 0x1E6
	.equ NakaNode_Accomp7_Widget15, NakaNode_Accomp7_Widget01 + 0x212
	.equ NakaNode_Accomp7_Widget16, NakaNode_Accomp7_Widget01 + 0x23E
	.equ NakaNode_Accomp7_Widget17, NakaNode_Accomp7_Widget01 + 0x26A
	.equ NakaNode_Accomp7_Widget18, NakaNode_Accomp7_Widget01 + 0x28E
	.equ NakaNode_Accomp7_Widget19, NakaNode_Accomp7_Widget01 + 0x2BA
	.equ NakaNode_Accomp7_Widget20, NakaNode_Accomp7_Widget01 + 0x2E6
	.equ NakaNode_Accomp7_Widget21, NakaNode_Accomp7_Widget01 + 0x312
	.equ NakaNode_Accomp7_Widget22, NakaNode_Accomp7_Widget01 + 0x33E
	.equ NakaNode_Accomp7_Widget23, NakaNode_Accomp7_Widget01 + 0x36A
	.equ NakaNode_Accomp7_Widget24, NakaNode_Accomp7_Widget01 + 0x396
	.equ NakaNode_Accomp7_Widget25, NakaNode_Accomp7_Widget01 + 0x3C2
	.equ NakaNode_Accomp7_Widget26, NakaNode_Accomp7_Widget01 + 0x3EE
