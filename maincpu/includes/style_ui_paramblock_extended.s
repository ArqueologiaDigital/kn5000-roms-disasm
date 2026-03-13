; StyleUI_ParamBlock_Extended: Style UI parameter block (Extended)
; Total: 183 bytes, 23 commands
; Source: e0b6cd_e0b783.bin
;
; Screen elements:
;   Labeled REFs: 'BAL', 'YES', 'NO'
;   Labels: "MEAS" (25,31), "CURSOR" (56,31)
;   Up/Down arrows: 1 up, 1 down
;   Navigation: "<" / ">" arrows
;   Selection RECTs: 6 (inner/outer pairs)
;   FILLED_RECTs: 4
;   HLINEs: 1

; [0] STRING "MEAS" at (25,31)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x08                                     ; .length  = 8
	.byte 0x19, 0x1f                               ; .x, .y   = (25, 31)
	.byte 0x4d, 0x45, 0x41, 0x53                   ; .text    = "MEAS"
; [1] STRING "CURSOR" at (56,31)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x0a                                     ; .length  = 10
	.byte 0x38, 0x1f                               ; .x, .y   = (56, 31)
	.byte 0x43, 0x55, 0x52, 0x53, 0x4f, 0x52       ; .text    = "CURSOR"
; [2] STRING "|" at (210,32)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xd2, 0x20                               ; .x, .y   = (210, 32)
	.byte 0x8d                                     ; .text    = "|"
; [3] STRING "~" at (218,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xda, 0x22                               ; .x, .y   = (218, 34)
	.byte 0x8e                                     ; .text    = "~"
; [4] STRING "<" at (48,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0x30, 0x22                               ; .x, .y   = (48, 34)
	.byte 0x3c                                     ; .text    = "<"
; [5] STRING ">" at (53,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0x35, 0x22                               ; .x, .y   = (53, 34)
	.byte 0x3e                                     ; .text    = ">"
; [6] FILLED_RECT (5,210)-(35,236)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x05, 0x00, 0xd2, 0x00                   ; .x1, .y1 = (5, 210)
	.byte 0x23, 0x00, 0xec, 0x00                   ; .x2, .y2 = (35, 236)
; [7] FILLED_RECT (245,210)-(275,236)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0xf5, 0x00, 0xd2, 0x00                   ; .x1, .y1 = (245, 210)
	.byte 0x13, 0x01, 0xec, 0x00                   ; .x2, .y2 = (275, 236)
; [8] FILLED_RECT (285,210)-(315,236)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x1d, 0x01, 0xd2, 0x00                   ; .x1, .y1 = (285, 210)
	.byte 0x3b, 0x01, 0xec, 0x00                   ; .x2, .y2 = (315, 236)
; [9] HLINE (5,223)-(35,223)
	.byte 0x01                                     ; .opcode  = HLINE
	.byte 0x0a                                     ; .length  = 10
	.byte 0x05, 0x00, 0xdf, 0x00                   ; .x1, .y1 = (5, 223)
	.byte 0x23, 0x00, 0xdf, 0x00                   ; .x2, .y2 = (35, 223)
; [10] LABELED_REF "BAL"
	.byte 0x06                                     ; .opcode  = LABELED_REF
	.byte 0x07                                     ; .length  = 7
	.byte 0xdb, 0x06                               ; .addr    = 0x06DB
	.byte 0x42, 0x41, 0x4c                         ; .label   = "BAL"
; [11] SHORT_REF
	.byte 0x07                                     ; .opcode  = SHORT_REF
	.byte 0x05                                     ; .length  = 5
	.byte 0xb7, 0x06, 0x11                         ; .data    = [b7 06 11]
; [12] RECT (277,40)-(307,55)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x15, 0x01, 0x28, 0x00                   ; .x1, .y1 = (277, 40)
	.byte 0x33, 0x01, 0x37, 0x00                   ; .x2, .y2 = (307, 55)
; [13] RECT (275,38)-(309,57)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x13, 0x01, 0x26, 0x00                   ; .x1, .y1 = (275, 38)
	.byte 0x35, 0x01, 0x39, 0x00                   ; .x2, .y2 = (309, 57)
; [14] LABELED_REF "YES"
	.byte 0x06                                     ; .opcode  = LABELED_REF
	.byte 0x07                                     ; .length  = 7
	.byte 0x5b, 0x13                               ; .addr    = 0x135B
	.byte 0x59, 0x45, 0x53                         ; .label   = "YES"
; [15] SHORT_REF
	.byte 0x07                                     ; .opcode  = SHORT_REF
	.byte 0x05                                     ; .length  = 5
	.byte 0x37, 0x13, 0x11                         ; .data    = [37 13 11]
; [16] RECT (277,120)-(307,135)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x15, 0x01, 0x78, 0x00                   ; .x1, .y1 = (277, 120)
	.byte 0x33, 0x01, 0x87, 0x00                   ; .x2, .y2 = (307, 135)
; [17] RECT (275,118)-(309,137)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x13, 0x01, 0x76, 0x00                   ; .x1, .y1 = (275, 118)
	.byte 0x35, 0x01, 0x89, 0x00                   ; .x2, .y2 = (309, 137)
; [18] LABELED_REF "NO"
	.byte 0x06                                     ; .opcode  = LABELED_REF
	.byte 0x06                                     ; .length  = 6
	.byte 0x9b, 0x19                               ; .addr    = 0x199B
	.byte 0x4e, 0x4f                               ; .label   = "NO"
; [19] SHORT_REF
	.byte 0x07                                     ; .opcode  = SHORT_REF
	.byte 0x05                                     ; .length  = 5
	.byte 0x77, 0x19, 0x11                         ; .data    = [77 19 11]
; [20] RECT (277,160)-(307,175)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x15, 0x01, 0xa0, 0x00                   ; .x1, .y1 = (277, 160)
	.byte 0x33, 0x01, 0xaf, 0x00                   ; .x2, .y2 = (307, 175)
; [21] RECT (275,158)-(309,177)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x13, 0x01, 0x9e, 0x00                   ; .x1, .y1 = (275, 158)
	.byte 0x35, 0x01, 0xb1, 0x00                   ; .x2, .y2 = (309, 177)
; [22] FILLED_RECT (5,175)-(250,195)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x05, 0x00, 0xaf, 0x00                   ; .x1, .y1 = (5, 175)
	.byte 0xfa, 0x00, 0xc3, 0x00                   ; .x2, .y2 = (250, 195)

