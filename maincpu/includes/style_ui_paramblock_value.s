; StyleUI_ParamBlock_VALUE: Style UI parameter block (VALUE)
; Total: 39 bytes, 5 commands
; Source: e0b5e7_e0b60d.bin
;
; Screen elements:
;   Labels: "VALUE" (44,31)
;   Up/Down arrows: 1 up, 1 down
;   FILLED_RECTs: 1
;   HLINEs: 1

; [0] STRING "VALUE" at (44,31)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x09                                     ; .length  = 9
	.byte 0x2c, 0x1f                               ; .x, .y   = (44, 31)
	.byte 0x56, 0x41, 0x4c, 0x55, 0x45             ; .text    = "VALUE"
; [1] STRING "|" at (230,32)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xe6, 0x20                               ; .x, .y   = (230, 32)
	.byte 0x8d                                     ; .text    = "|"
; [2] STRING "~" at (238,34)
	.byte 0x20                                     ; .opcode  = STRING
	.byte 0x05                                     ; .length  = 5
	.byte 0xee, 0x22                               ; .x, .y   = (238, 34)
	.byte 0x8e                                     ; .text    = "~"
; [3] FILLED_RECT (165,210)-(195,236)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0xa5, 0x00, 0xd2, 0x00                   ; .x1, .y1 = (165, 210)
	.byte 0xc3, 0x00, 0xec, 0x00                   ; .x2, .y2 = (195, 236)
; [4] HLINE (165,223)-(195,223)
	.byte 0x01                                     ; .opcode  = HLINE
	.byte 0x0a                                     ; .length  = 10
	.byte 0xa5, 0x00, 0xdf, 0x00                   ; .x1, .y1 = (165, 223)
	.byte 0xc3, 0x00, 0xdf, 0x00                   ; .x2, .y2 = (195, 223)

