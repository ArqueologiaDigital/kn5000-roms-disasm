; StyleUI_ParamBlock_AltD: Style UI parameter block (AltD)
; Total: 80 bytes, 9 commands
; Source: e0b99d_e0b9ec.bin
;
; Screen elements:
;   Labeled REFs: 'YES', 'NO'
;   Messages: 'Are You Sure?'
;   Selection RECTs: 4 (inner/outer pairs)

; [0] MESSAGE "Are You Sure?" at (56,17)
	.byte 0x08                                     ; .opcode  = MESSAGE
	.byte 0x11                                     ; .length  = 17
	.byte 0x38, 0x11                               ; .x, .y   = (56, 17)
	.byte 0x41, 0x72, 0x65, 0x20, 0x59, 0x6f, 0x75, 0x20, 0x53, 0x75, 0x72, 0x65, 0x3f ; .text    = "Are You Sure?"
; [1] LABELED_REF "YES"
	.byte 0x06                                     ; .opcode  = LABELED_REF
	.byte 0x07                                     ; .length  = 7
	.byte 0x1b, 0x0d                               ; .addr    = 0x0D1B
	.byte 0x59, 0x45, 0x53                         ; .label   = "YES"
; [2] SHORT_REF
	.byte 0x07                                     ; .opcode  = SHORT_REF
	.byte 0x05                                     ; .length  = 5
	.byte 0xf7, 0x0c, 0x11                         ; .data    = [f7 0c 11]
; [3] RECT (277,80)-(307,95)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x15, 0x01, 0x50, 0x00                   ; .x1, .y1 = (277, 80)
	.byte 0x33, 0x01, 0x5f, 0x00                   ; .x2, .y2 = (307, 95)
; [4] RECT (275,78)-(309,97)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x13, 0x01, 0x4e, 0x00                   ; .x1, .y1 = (275, 78)
	.byte 0x35, 0x01, 0x61, 0x00                   ; .x2, .y2 = (309, 97)
; [5] LABELED_REF "NO"
	.byte 0x06                                     ; .opcode  = LABELED_REF
	.byte 0x06                                     ; .length  = 6
	.byte 0x5b, 0x13                               ; .addr    = 0x135B
	.byte 0x4e, 0x4f                               ; .label   = "NO"
; [6] SHORT_REF
	.byte 0x07                                     ; .opcode  = SHORT_REF
	.byte 0x05                                     ; .length  = 5
	.byte 0x37, 0x13, 0x11                         ; .data    = [37 13 11]
; [7] RECT (277,120)-(307,135)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x15, 0x01, 0x78, 0x00                   ; .x1, .y1 = (277, 120)
	.byte 0x33, 0x01, 0x87, 0x00                   ; .x2, .y2 = (307, 135)
; [8] RECT (275,118)-(309,137)
	.byte 0x09                                     ; .opcode  = RECT
	.byte 0x0a                                     ; .length  = 10
	.byte 0x13, 0x01, 0x76, 0x00                   ; .x1, .y1 = (275, 118)
	.byte 0x35, 0x01, 0x89, 0x00                   ; .x2, .y2 = (309, 137)

