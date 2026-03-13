; StyleUI_ParamBlock_AltB: Style UI parameter block (AltB)
; Total: 41 bytes, 4 commands
; Source: e0b905_e0b92d.bin
;
; Screen elements:
;   Labeled REFs: 'TRACK:'
;   FILLED_RECTs: 1

; [0] UNKNOWN_23
	.byte 0x23                                     ; .opcode  = UNKNOWN_23
	.byte 0x05                                     ; .length  = 5
	.byte 0x34, 0x2d, 0x00                         ; .data    = [34 2d 00]
; [1] SHORT_REF "STEP RECORD:" at (51,0)
	.byte 0x07                                     ; .opcode  = SHORT_REF
	.byte 0x10                                     ; .length  = 16
	.byte 0x33, 0x00                               ; .x, .y   = (51, 0)
	.byte 0x53, 0x54, 0x45, 0x50, 0x20, 0x52, 0x45, 0x43, 0x4f, 0x52, 0x44, 0x3a ; .text    = "STEP RECORD:"
; [2] LABELED_REF "TRACK:"
	.byte 0x06                                     ; .opcode  = LABELED_REF
	.byte 0x0a                                     ; .length  = 10
	.byte 0x8f, 0x02                               ; .addr    = 0x028F
	.byte 0x54, 0x52, 0x41, 0x43, 0x4b, 0x3a       ; .label   = "TRACK:"
; [3] FILLED_RECT (5,175)-(250,195)
	.byte 0x0a                                     ; .opcode  = FILLED_RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x05, 0x00, 0xaf, 0x00                   ; .x1, .y1 = (5, 175)
	.byte 0xfa, 0x00, 0xc3, 0x00                   ; .x2, .y2 = (250, 195)

