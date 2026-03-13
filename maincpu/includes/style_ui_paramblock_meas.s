; StyleUI_ParamBlock_MEAS: Style UI parameter block (MEAS)
; Total: 155 bytes, 19 commands
; Source: e0b843_e0b8dd.bin
;
; Screen elements:
;   Labeled REFs: 'REP', 'END', 'ERS', 'CLR'
;   Labels: "MEAS" (25,31), "TRACK" (26,23)
;   Up/Down arrows: 1 up, 1 down
;   Selection RECTs: 4 (inner/outer pairs)
;   FILLED_RECTs: 4
;   HLINEs: 1

; [0] STRING "MEAS" at (25,31)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x08                                     ; .length  = 8
	.byte 0x19, 0x1f                               ; .x, .y   = (25, 31)
	.byte 0x4d, 0x45, 0x41, 0x53                   ; .text    = "MEAS"
; [1] STRING "|" at (210,32)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xd2, 0x20                               ; .x, .y   = (210, 32)
	.byte 0x8d                                     ; .text    = "|"
; [2] STRING "~" at (218,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xda, 0x22                               ; .x, .y   = (218, 34)
	.byte 0x8e                                     ; .text    = "~"
; [3] FILLED_RECT (5,210)-(35,236)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x05, 0x00, 0xd2, 0x00                   ; .x1, .y1 = (5, 210)
	.byte 0x23, 0x00, 0xec, 0x00                   ; .x2, .y2 = (35, 236)
; [4] HLINE (5,223)-(35,223)
	.byte 0x01                                     ; .opcode  = HLINE
	.byte 0x0a                                     ; .length  = 10
	.byte 0x05, 0x00, 0xdf, 0x00                   ; .x1, .y1 = (5, 223)
	.byte 0x23, 0x00, 0xdf, 0x00                   ; .x2, .y2 = (35, 223)
; [5] LABELED_REF "REP"
	.byte 0x06                                     ; .opcode  = LABELED_REF
	.byte 0x07                                     ; .length  = 7
	.byte 0x2a, 0x22                               ; .addr    = 0x222A
	.byte 0x52, 0x45, 0x50                         ; .label   = "REP"
; [6] LABELED_REF "END"
	.byte 0x06                                     ; .opcode  = LABELED_REF
	.byte 0x07                                     ; .length  = 7
	.byte 0x2f, 0x22                               ; .addr    = 0x222F
	.byte 0x45, 0x4e, 0x44                         ; .label   = "END"
; [7] FILLED_RECT (205,210)-(235,236)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0xcd, 0x00, 0xd2, 0x00                   ; .x1, .y1 = (205, 210)
	.byte 0xeb, 0x00, 0xec, 0x00                   ; .x2, .y2 = (235, 236)
; [8] FILLED_RECT (245,210)-(275,236)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0xf5, 0x00, 0xd2, 0x00                   ; .x1, .y1 = (245, 210)
	.byte 0x13, 0x01, 0xec, 0x00                   ; .x2, .y2 = (275, 236)
; [9] LABELED_REF "ERS"
	.byte 0x06                                     ; .opcode  = LABELED_REF
	.byte 0x07                                     ; .length  = 7
	.byte 0x1b, 0x0d                               ; .addr    = 0x0D1B
	.byte 0x45, 0x52, 0x53                         ; .label   = "ERS"
; [10] RECT (277,80)-(307,95)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x15, 0x01, 0x50, 0x00                   ; .x1, .y1 = (277, 80)
	.byte 0x33, 0x01, 0x5f, 0x00                   ; .x2, .y2 = (307, 95)
; [11] RECT (275,78)-(309,97)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x13, 0x01, 0x4e, 0x00                   ; .x1, .y1 = (275, 78)
	.byte 0x35, 0x01, 0x61, 0x00                   ; .x2, .y2 = (309, 97)
; [12] SHORT_REF
	.byte 0x07                                     ; .opcode  = SHORT_REF
	.byte 0x05                                     ; .length  = 5
	.byte 0xf7, 0x0c, 0x11                         ; .data    = [f7 0c 11]
; [13] STRING "TRACK" at (26,23)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x09                                     ; .length  = 9
	.byte 0x1a, 0x17                               ; .x, .y   = (26, 23)
	.byte 0x54, 0x52, 0x41, 0x43, 0x4b             ; .text    = "TRACK"
; [14] LABELED_REF "CLR"
	.byte 0x06                                     ; .opcode  = LABELED_REF
	.byte 0x07                                     ; .length  = 7
	.byte 0x9b, 0x19                               ; .addr    = 0x199B
	.byte 0x43, 0x4c, 0x52                         ; .label   = "CLR"
; [15] RECT (277,160)-(307,175)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x15, 0x01, 0xa0, 0x00                   ; .x1, .y1 = (277, 160)
	.byte 0x33, 0x01, 0xaf, 0x00                   ; .x2, .y2 = (307, 175)
; [16] RECT (275,158)-(309,177)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x13, 0x01, 0x9e, 0x00                   ; .x1, .y1 = (275, 158)
	.byte 0x35, 0x01, 0xb1, 0x00                   ; .x2, .y2 = (309, 177)
; [17] SHORT_REF
	.byte 0x07                                     ; .opcode  = SHORT_REF
	.byte 0x05                                     ; .length  = 5
	.byte 0x77, 0x19, 0x11                         ; .data    = [77 19 11]
; [18] FILLED_RECT (5,175)-(250,195)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x05, 0x00, 0xaf, 0x00                   ; .x1, .y1 = (5, 175)
	.byte 0xfa, 0x00, 0xc3, 0x00                   ; .x2, .y2 = (250, 195)

