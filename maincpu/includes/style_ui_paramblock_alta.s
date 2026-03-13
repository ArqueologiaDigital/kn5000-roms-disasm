; StyleUI_ParamBlock_AltA: Style UI parameter block (AltA)
; Total: 39 bytes, 5 commands
; Source: e0b8de_e0b904.bin
;
; Screen elements:
;   Labels: "VALUE" (39,31)
;   Up/Down arrows: 1 up, 1 down
;   FILLED_RECTs: 1
;   HLINEs: 1

; [0] STRING "VALUE" at (39,31)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x09                                     ; .length  = 9
	.byte 0x27, 0x1f                               ; .x, .y   = (39, 31)
	.byte 0x56, 0x41, 0x4c, 0x55, 0x45             ; .text    = "VALUE"
; [1] STRING "|" at (225,32)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xe1, 0x20                               ; .x, .y   = (225, 32)
	.byte 0x8d                                     ; .text    = "|"
; [2] STRING "~" at (233,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xe9, 0x22                               ; .x, .y   = (233, 34)
	.byte 0x8e                                     ; .text    = "~"
; [3] FILLED_RECT (125,210)-(155,236)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x7d, 0x00, 0xd2, 0x00                   ; .x1, .y1 = (125, 210)
	.byte 0x9b, 0x00, 0xec, 0x00                   ; .x2, .y2 = (155, 236)
; [4] HLINE (125,223)-(155,223)
	.byte 0x01                                     ; .opcode  = HLINE
	.byte 0x0a                                     ; .length  = 10
	.byte 0x7d, 0x00, 0xdf, 0x00                   ; .x1, .y1 = (125, 223)
	.byte 0x9b, 0x00, 0xdf, 0x00                   ; .x2, .y2 = (155, 223)

