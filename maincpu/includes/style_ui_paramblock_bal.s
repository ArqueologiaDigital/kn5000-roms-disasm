; StyleUI_ParamBlock_BAL: Style UI parameter block (BAL)
; Total: 250 bytes, 32 commands
; Source: e0b4ed_e0b5e6.bin
;
; Screen elements:
;   Labeled REFs: 'BAL', 'ERS', 'REST'
;   Labels: "CTL" (91,19), "MEAS NOTE VEL   LENGTH   PHRS  CURSOR" (25,31)
;   Up/Down arrows: 6 up, 6 down
;   Navigation: "<" / ">" arrows
;   Selection RECTs: 8 (inner/outer pairs)
;   FILLED_RECTs: 1

; [0] LABELED_REF "BAL"
	.byte 0x06                                     ; .opcode  = LABELED_REF
	.byte 0x07                                     ; .length  = 7
	.byte 0xdb, 0x06                               ; .addr    = 0x06DB
	.byte 0x42, 0x41, 0x4c                         ; .label   = "BAL"
; [1] RECT (277,40)-(307,55)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x15, 0x01, 0x28, 0x00                   ; .x1, .y1 = (277, 40)
	.byte 0x33, 0x01, 0x37, 0x00                   ; .x2, .y2 = (307, 55)
; [2] RECT (275,38)-(309,57)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x13, 0x01, 0x26, 0x00                   ; .x1, .y1 = (275, 38)
	.byte 0x35, 0x01, 0x39, 0x00                   ; .x2, .y2 = (309, 57)
; [3] SHORT_REF
	.byte 0x07                                     ; .opcode  = SHORT_REF
	.byte 0x05                                     ; .length  = 5
	.byte 0xb7, 0x06, 0x11                         ; .data    = [b7 06 11]
; [4] LABELED_REF "ERS"
	.byte 0x06                                     ; .opcode  = LABELED_REF
	.byte 0x07                                     ; .length  = 7
	.byte 0x1b, 0x0d                               ; .addr    = 0x0D1B
	.byte 0x45, 0x52, 0x53                         ; .label   = "ERS"
; [5] RECT (277,80)-(307,95)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x15, 0x01, 0x50, 0x00                   ; .x1, .y1 = (277, 80)
	.byte 0x33, 0x01, 0x5f, 0x00                   ; .x2, .y2 = (307, 95)
; [6] RECT (275,78)-(309,97)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x13, 0x01, 0x4e, 0x00                   ; .x1, .y1 = (275, 78)
	.byte 0x35, 0x01, 0x61, 0x00                   ; .x2, .y2 = (309, 97)
; [7] SHORT_REF
	.byte 0x07                                     ; .opcode  = SHORT_REF
	.byte 0x05                                     ; .length  = 5
	.byte 0xf7, 0x0c, 0x11                         ; .data    = [f7 0c 11]
; [8] STRING "CTL" at (91,19)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x07                                     ; .length  = 7
	.byte 0x5b, 0x13                               ; .x, .y   = (91, 19)
	.byte 0x43, 0x54, 0x4c                         ; .text    = "CTL"
; [9] SHORT_REF
	.byte 0x07                                     ; .opcode  = SHORT_REF
	.byte 0x05                                     ; .length  = 5
	.byte 0x37, 0x13, 0x11                         ; .data    = [37 13 11]
; [10] RECT (277,120)-(307,135)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x15, 0x01, 0x78, 0x00                   ; .x1, .y1 = (277, 120)
	.byte 0x33, 0x01, 0x87, 0x00                   ; .x2, .y2 = (307, 135)
; [11] RECT (275,118)-(309,137)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x13, 0x01, 0x76, 0x00                   ; .x1, .y1 = (275, 118)
	.byte 0x35, 0x01, 0x89, 0x00                   ; .x2, .y2 = (309, 137)
; [12] LABELED_REF "REST"
	.byte 0x06                                     ; .opcode  = LABELED_REF
	.byte 0x08                                     ; .length  = 8
	.byte 0x9a, 0x19                               ; .addr    = 0x199A
	.byte 0x52, 0x45, 0x53, 0x54                   ; .label   = "REST"
; [13] RECT (269,160)-(307,175)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x0d, 0x01, 0xa0, 0x00                   ; .x1, .y1 = (269, 160)
	.byte 0x33, 0x01, 0xaf, 0x00                   ; .x2, .y2 = (307, 175)
; [14] RECT (267,158)-(309,177)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x0b, 0x01, 0x9e, 0x00                   ; .x1, .y1 = (267, 158)
	.byte 0x35, 0x01, 0xb1, 0x00                   ; .x2, .y2 = (309, 177)
; [15] SHORT_REF
	.byte 0x07                                     ; .opcode  = SHORT_REF
	.byte 0x05                                     ; .length  = 5
	.byte 0x77, 0x19, 0x11                         ; .data    = [77 19 11]
; [16] STRING "MEAS NOTE VEL   LENGTH   PHRS  CURSOR" at (25,31)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x29                                     ; .length  = 41
	.byte 0x19, 0x1f                               ; .x, .y   = (25, 31)
	.byte 0x4d, 0x45, 0x41, 0x53, 0x20, 0x4e, 0x4f, 0x54, 0x45, 0x20, 0x56, 0x45, 0x4c, 0x20, 0x20, 0x20, 0x4c, 0x45, 0x4e, 0x47, 0x54, 0x48, 0x20, 0x20, 0x20, 0x50, 0x48, 0x52, 0x53, 0x20, 0x20, 0x43, 0x55, 0x52, 0x53, 0x4f, 0x52 ; .text    = "MEAS NOTE VEL   LENGTH   PHRS  CURSOR"
; [17] STRING "|" at (210,32)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xd2, 0x20                               ; .x, .y   = (210, 32)
	.byte 0x8d                                     ; .text    = "|"
; [18] STRING "~" at (218,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xda, 0x22                               ; .x, .y   = (218, 34)
	.byte 0x8e                                     ; .text    = "~"
; [19] STRING "|" at (215,32)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xd7, 0x20                               ; .x, .y   = (215, 32)
	.byte 0x8d                                     ; .text    = "|"
; [20] STRING "~" at (223,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xdf, 0x22                               ; .x, .y   = (223, 34)
	.byte 0x8e                                     ; .text    = "~"
; [21] STRING "|" at (220,32)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xdc, 0x20                               ; .x, .y   = (220, 32)
	.byte 0x8d                                     ; .text    = "|"
; [22] STRING "~" at (228,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xe4, 0x22                               ; .x, .y   = (228, 34)
	.byte 0x8e                                     ; .text    = "~"
; [23] STRING "|" at (225,32)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xe1, 0x20                               ; .x, .y   = (225, 32)
	.byte 0x8d                                     ; .text    = "|"
; [24] STRING "~" at (233,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xe9, 0x22                               ; .x, .y   = (233, 34)
	.byte 0x8e                                     ; .text    = "~"
; [25] STRING "|" at (230,32)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xe6, 0x20                               ; .x, .y   = (230, 32)
	.byte 0x8d                                     ; .text    = "|"
; [26] STRING "~" at (238,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xee, 0x22                               ; .x, .y   = (238, 34)
	.byte 0x8e                                     ; .text    = "~"
; [27] STRING "|" at (235,32)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xeb, 0x20                               ; .x, .y   = (235, 32)
	.byte 0x8d                                     ; .text    = "|"
; [28] STRING "~" at (243,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xf3, 0x22                               ; .x, .y   = (243, 34)
	.byte 0x8e                                     ; .text    = "~"
; [29] STRING "<" at (48,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0x30, 0x22                               ; .x, .y   = (48, 34)
	.byte 0x3c                                     ; .text    = "<"
; [30] STRING ">" at (53,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0x35, 0x22                               ; .x, .y   = (53, 34)
	.byte 0x3e                                     ; .text    = ">"
; [31] FILLED_RECT (5,175)-(250,195)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x05, 0x00, 0xaf, 0x00                   ; .x1, .y1 = (5, 175)
	.byte 0xfa, 0x00, 0xc3, 0x00                   ; .x2, .y2 = (250, 195)

