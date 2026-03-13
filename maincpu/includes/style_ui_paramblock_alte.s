; StyleUI_ParamBlock_AltE: Style UI parameter block (AltE)
; Total: 115 bytes, 13 commands
; Source: e0b9ed_e0ba5f.bin
;
; Screen elements:
;   Labeled REFs: 'TRACK:', 'CLR'
;   Labels: "TRACK" (26,23), "MEAS" (25,31)
;   Up/Down arrows: 1 up, 1 down
;   Selection RECTs: 2 (inner/outer pairs)
;   FILLED_RECTs: 2
;   HLINEs: 1

; [0] SHORT_REF "STEP RECORD:" at (51,0)
	.byte 0x07                                     ; .opcode  = SHORT_REF
	.byte 0x10                                     ; .length  = 16
	.byte 0x33, 0x00                               ; .x, .y   = (51, 0)
	.byte 0x53, 0x54, 0x45, 0x50, 0x20, 0x52, 0x45, 0x43, 0x4f, 0x52, 0x44, 0x3a ; .text    = "STEP RECORD:"
; [1] LABELED_REF "TRACK:"
	.byte 0x06                                     ; .opcode  = LABELED_REF
	.byte 0x0a                                     ; .length  = 10
	.byte 0x8f, 0x02                               ; .addr    = 0x028F
	.byte 0x54, 0x52, 0x41, 0x43, 0x4b, 0x3a       ; .label   = "TRACK:"
; [2] STRING "TRACK" at (26,23)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x09                                     ; .length  = 9
	.byte 0x1a, 0x17                               ; .x, .y   = (26, 23)
	.byte 0x54, 0x52, 0x41, 0x43, 0x4b             ; .text    = "TRACK"
; [3] LABELED_REF "CLR"
	.byte 0x06                                     ; .opcode  = LABELED_REF
	.byte 0x07                                     ; .length  = 7
	.byte 0x9b, 0x19                               ; .addr    = 0x199B
	.byte 0x43, 0x4c, 0x52                         ; .label   = "CLR"
; [4] RECT (277,160)-(307,175)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x15, 0x01, 0xa0, 0x00                   ; .x1, .y1 = (277, 160)
	.byte 0x33, 0x01, 0xaf, 0x00                   ; .x2, .y2 = (307, 175)
; [5] RECT (275,158)-(309,177)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x13, 0x01, 0x9e, 0x00                   ; .x1, .y1 = (275, 158)
	.byte 0x35, 0x01, 0xb1, 0x00                   ; .x2, .y2 = (309, 177)
; [6] SHORT_REF
	.byte 0x07                                     ; .opcode  = SHORT_REF
	.byte 0x05                                     ; .length  = 5
	.byte 0x77, 0x19, 0x11                         ; .data    = [77 19 11]
; [7] FILLED_RECT (5,175)-(250,195)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x05, 0x00, 0xaf, 0x00                   ; .x1, .y1 = (5, 175)
	.byte 0xfa, 0x00, 0xc3, 0x00                   ; .x2, .y2 = (250, 195)
; [8] STRING "MEAS" at (25,31)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x08                                     ; .length  = 8
	.byte 0x19, 0x1f                               ; .x, .y   = (25, 31)
	.byte 0x4d, 0x45, 0x41, 0x53                   ; .text    = "MEAS"
; [9] STRING "|" at (210,32)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xd2, 0x20                               ; .x, .y   = (210, 32)
	.byte 0x8d                                     ; .text    = "|"
; [10] STRING "~" at (218,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xda, 0x22                               ; .x, .y   = (218, 34)
	.byte 0x8e                                     ; .text    = "~"
; [11] FILLED_RECT (5,210)-(35,236)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x05, 0x00, 0xd2, 0x00                   ; .x1, .y1 = (5, 210)
	.byte 0x23, 0x00, 0xec, 0x00                   ; .x2, .y2 = (35, 236)
; [12] HLINE (5,223)-(35,223)
	.byte 0x01                                     ; .opcode  = HLINE
	.byte 0x0a                                     ; .length  = 10
	.byte 0x05, 0x00, 0xdf, 0x00                   ; .x1, .y1 = (5, 223)
	.byte 0x23, 0x00, 0xdf, 0x00                   ; .x2, .y2 = (35, 223)

