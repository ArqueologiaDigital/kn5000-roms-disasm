; StyleUI_ParamBlock_Medium: Style UI parameter block (Medium)
; Total: 191 bytes, 24 commands
; Source: e0b784_e0b842.bin
;
; Screen elements:
;   Labeled REFs: 'BAL', 'ERS'
;   Labels: "MEAS" (25,31), "CURSOR" (56,31), "VALUE" (44,31)
;   Up/Down arrows: 2 up, 2 down
;   Navigation: "<" / ">" arrows
;   Selection RECTs: 4 (inner/outer pairs)
;   FILLED_RECTs: 5
;   HLINEs: 2

; [0] LABELED_REF "BAL"
	.byte 0x06                                     ; .opcode  = LABELED_REF
	.byte 0x07                                     ; .length  = 7
	.byte 0xdb, 0x06                               ; .addr    = 0x06DB
	.byte 0x42, 0x41, 0x4c                         ; .label   = "BAL"
; [1] SHORT_REF
	.byte 0x07                                     ; .opcode  = SHORT_REF
	.byte 0x05                                     ; .length  = 5
	.byte 0xb7, 0x06, 0x11                         ; .data    = [b7 06 11]
; [2] RECT (277,40)-(307,55)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x15, 0x01, 0x28, 0x00                   ; .x1, .y1 = (277, 40)
	.byte 0x33, 0x01, 0x37, 0x00                   ; .x2, .y2 = (307, 55)
; [3] RECT (275,38)-(309,57)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x13, 0x01, 0x26, 0x00                   ; .x1, .y1 = (275, 38)
	.byte 0x35, 0x01, 0x39, 0x00                   ; .x2, .y2 = (309, 57)
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
; [8] STRING "MEAS" at (25,31)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x08                                     ; .length  = 8
	.byte 0x19, 0x1f                               ; .x, .y   = (25, 31)
	.byte 0x4d, 0x45, 0x41, 0x53                   ; .text    = "MEAS"
; [9] STRING "CURSOR" at (56,31)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x0a                                     ; .length  = 10
	.byte 0x38, 0x1f                               ; .x, .y   = (56, 31)
	.byte 0x43, 0x55, 0x52, 0x53, 0x4f, 0x52       ; .text    = "CURSOR"
; [10] STRING "|" at (210,32)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xd2, 0x20                               ; .x, .y   = (210, 32)
	.byte 0x8d                                     ; .text    = "|"
; [11] STRING "~" at (218,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xda, 0x22                               ; .x, .y   = (218, 34)
	.byte 0x8e                                     ; .text    = "~"
; [12] STRING "VALUE" at (44,31)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x09                                     ; .length  = 9
	.byte 0x2c, 0x1f                               ; .x, .y   = (44, 31)
	.byte 0x56, 0x41, 0x4c, 0x55, 0x45             ; .text    = "VALUE"
; [13] STRING "|" at (230,32)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xe6, 0x20                               ; .x, .y   = (230, 32)
	.byte 0x8d                                     ; .text    = "|"
; [14] STRING "~" at (238,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xee, 0x22                               ; .x, .y   = (238, 34)
	.byte 0x8e                                     ; .text    = "~"
; [15] STRING "<" at (48,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0x30, 0x22                               ; .x, .y   = (48, 34)
	.byte 0x3c                                     ; .text    = "<"
; [16] STRING ">" at (53,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0x35, 0x22                               ; .x, .y   = (53, 34)
	.byte 0x3e                                     ; .text    = ">"
; [17] FILLED_RECT (5,210)-(35,236)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x05, 0x00, 0xd2, 0x00                   ; .x1, .y1 = (5, 210)
	.byte 0x23, 0x00, 0xec, 0x00                   ; .x2, .y2 = (35, 236)
; [18] HLINE (5,223)-(35,223)
	.byte 0x01                                     ; .opcode  = HLINE
	.byte 0x0a                                     ; .length  = 10
	.byte 0x05, 0x00, 0xdf, 0x00                   ; .x1, .y1 = (5, 223)
	.byte 0x23, 0x00, 0xdf, 0x00                   ; .x2, .y2 = (35, 223)
; [19] FILLED_RECT (165,210)-(195,236)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0xa5, 0x00, 0xd2, 0x00                   ; .x1, .y1 = (165, 210)
	.byte 0xc3, 0x00, 0xec, 0x00                   ; .x2, .y2 = (195, 236)
; [20] HLINE (165,223)-(195,223)
	.byte 0x01                                     ; .opcode  = HLINE
	.byte 0x0a                                     ; .length  = 10
	.byte 0xa5, 0x00, 0xdf, 0x00                   ; .x1, .y1 = (165, 223)
	.byte 0xc3, 0x00, 0xdf, 0x00                   ; .x2, .y2 = (195, 223)
; [21] FILLED_RECT (245,210)-(275,236)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0xf5, 0x00, 0xd2, 0x00                   ; .x1, .y1 = (245, 210)
	.byte 0x13, 0x01, 0xec, 0x00                   ; .x2, .y2 = (275, 236)
; [22] FILLED_RECT (285,210)-(315,236)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x1d, 0x01, 0xd2, 0x00                   ; .x1, .y1 = (285, 210)
	.byte 0x3b, 0x01, 0xec, 0x00                   ; .x2, .y2 = (315, 236)
; [23] FILLED_RECT (5,175)-(250,195)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x05, 0x00, 0xaf, 0x00                   ; .x1, .y1 = (5, 175)
	.byte 0xfa, 0x00, 0xc3, 0x00                   ; .x2, .y2 = (250, 195)

