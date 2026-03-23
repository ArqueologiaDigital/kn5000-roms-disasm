; =============================================================================
; Audio Control Engine
; =============================================================================
;
; MIDI stream processing, control panel LED management, voice/tone
; parameter control, and sound preset dispatch. This is the main
; bridge between the UI layer and the SubCPU audio engine.
; =============================================================================

	ld a, e
	and a, 0xf
	jr z, FileIO_ShiftD
	srla d

FileIO_ShiftD:
	ld a, e
	and a, 0xf
	jr z, FileIO_CallbackHandler
	srla l

; File I/O callback handler
FileIO_CallbackHandler:
	cps l, 0
	jr z, FileIO_AdvancePointer
	ld a, (xiz + 1)
	ld (xbc + 1), a
	ld (xbc + 2), d
	ld (xbc + 3), l
	ld xhl, (xiz + 4)
	ld xwa, xbc
	call (xhl)

FileIO_AdvancePointer:
	inc 8, xiz

FileIO_MainLoop:
	ldada xbc, 36476
	ld a, (xiz)
	ld (xbc), a
	cp a, 0xff
	jr nz, FileIO_ProcessMaskAndShift
	pop xiz
	ret

FileIO_BytecodeData:
	.byte 0x80, 0x3f, 0xff, 0xb0, 0xf6, 0xc1, 0x8e, 0x8e
	.byte 0x23, 0xcb, 0xcf, 0x0f, 0x6b, 0x1f, 0xcb, 0x8d
	.byte 0xcb, 0x61, 0xf1, 0x8e, 0x8e, 0x43, 0xcd, 0x8b
	.byte 0xd9, 0x12, 0xd9, 0xee, 0x02, 0xf1, 0x39, 0xc0
	.byte 0x32, 0xd9, 0x8c, 0xec, 0x12, 0xea, 0x84, 0xe8
	.byte 0x8d, 0x95, 0x10, 0x95, 0x10, 0xb0, 0x00, 0xff
	.byte 0x0e, 0x3e, 0xe8, 0x8e, 0xc1, 0x34, 0x8d, 0x3f
	.byte 0x13, 0x66, 0x11, 0xee, 0x88, 0x1e, 0x9c, 0x0a
	.byte 0xee, 0x88, 0x1e, 0xbb, 0xff, 0xee, 0x64, 0xee
	.byte 0x88, 0x1e, 0xb4, 0xff, 0x5e, 0x0e, 0x3e, 0xe8
	.byte 0x8e, 0xc1, 0x34, 0x8d, 0x3f, 0x13, 0x66, 0x1e
	.byte 0x40, 0xc0, 0x00, 0x00, 0x00, 0x1d, 0x37, 0xd4
	.byte 0xfc, 0xdb, 0xd9, 0x66, 0x11, 0xee, 0x88, 0x1e
	.byte 0x72, 0x0a, 0xee, 0x88, 0x1e, 0x91, 0xff, 0xee
	.byte 0x64, 0xee, 0x88, 0x1e, 0x8a, 0xff, 0x5e, 0x0e
	.byte 0x3e, 0xe8, 0x8e, 0xc1, 0x34, 0x8d, 0x21, 0xc9
	.byte 0xcf, 0x0e, 0x66, 0x12, 0xc9, 0xcf, 0x13, 0x66
	.byte 0x0d, 0x40, 0xc0, 0x00, 0x00, 0x00, 0x1d, 0x37
	.byte 0xd4, 0xfc, 0xdb, 0xd9, 0x6e, 0x02, 0x68, 0x11
	.byte 0xee, 0x88, 0x1e, 0x3f, 0x0a, 0xee, 0x88, 0x1e
	.byte 0x5e, 0xff, 0xee, 0x64, 0xee, 0x88, 0x1e, 0x57
	.byte 0xff, 0x5e, 0x0e, 0x3e, 0xe8, 0x8e, 0xee, 0x88
	.byte 0x1e, 0x4d, 0xff, 0xee, 0x64, 0xee, 0x88, 0x1e
	.byte 0x46, 0xff, 0x5e, 0x0e, 0x3e, 0xe8, 0x8e, 0xbe
	.byte 0x02, 0x31, 0x81, 0x21, 0xc9, 0xd8, 0x6e, 0x15
	.byte 0xb1, 0x00, 0x00, 0xbe, 0x03, 0x00, 0xff, 0xee
	.byte 0x88, 0x1e, 0x77, 0x00, 0x86, 0x3f, 0xff, 0x6e
	.byte 0x64, 0xee, 0x88, 0x68, 0x69, 0x20, 0x00, 0xe8
	.byte 0x12, 0x1d, 0x33, 0x7c, 0xfc, 0xbe, 0x02, 0x32
	.byte 0xb2, 0x47, 0xc1, 0x90, 0x8e, 0x21, 0xdb, 0x12
	.byte 0xc9, 0xcf, 0x15, 0x66, 0x3a, 0xc9, 0xcf, 0x10
	.byte 0x66, 0x2e, 0xc9, 0xcf, 0x0f, 0x66, 0x22, 0xc9
	.byte 0xcf, 0x0a, 0x66, 0x16, 0xc9, 0xdb, 0x66, 0x0b
	cps	a, 1
	.ascii "n=@.í"
	nop
	.ascii "h!@0"
	.byte 0x9d, 0xed, 0x00
	.byte 0x68, 0x1a, 0x40, 0x32, 0x9d, 0xed, 0x00, 0x68
	.byte 0x13, 0x40, 0x34, 0x9d, 0xed, 0x00, 0x68, 0x0c
	.byte 0x40, 0x36, 0x9d, 0xed, 0x00, 0x68, 0x05, 0x40
	.byte 0x38, 0x9d, 0xed, 0x00
	.byte 0xc3, 0x07, 0xe0, 0xec
	.byte 0x21, 0xb2, 0x41, 0x68, 0x8e, 0xee, 0x88, 0x1e
	.byte 0xbe, 0xfe, 0xee, 0x64, 0xee, 0x88, 0x1e, 0xb7
	.byte 0xfe, 0x5e, 0x0e, 0x3e, 0xe8, 0x8e, 0xc1, 0x34
	.byte 0x8d, 0x3f, 0x13, 0x6e, 0x0f, 0x8e, 0x02, 0x21
	.byte 0xc9, 0xcf, 0x13, 0x66, 0x07, 0xc9, 0xd8, 0x66
	.byte 0x03, 0xb6, 0x00, 0xff, 0x40, 0xc0, 0x00, 0x00
	.byte 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0xd9, 0x6e
	.byte 0x1f, 0x8e, 0x02, 0x21, 0xc9, 0xcf, 0x0f, 0x66
	.byte 0x14, 0xc9, 0xcf, 0x11, 0x66, 0x0f, 0xc9, 0xcf
	.byte 0x13, 0x66, 0x0a, 0xc9, 0xcf, 0x09, 0x66, 0x05
	.byte 0xc9, 0xcf, 0x0e, 0x6e, 0x03, 0xb6, 0x00, 0xff
	.byte 0x1d, 0x7a, 0xbf, 0xfe, 0xdb, 0xcc, 0x07, 0x00
	.byte 0x66, 0x09, 0x8e, 0x02, 0x3f, 0x07, 0x6e, 0x03
	.byte 0xb6, 0x00, 0xff, 0xbe, 0x02, 0x30, 0x80, 0x3f
	.byte 0x09, 0x6e, 0x0c, 0xc1, 0xfc, 0x26, 0x3f, 0x01
	.byte 0x6e, 0x05, 0xb0, 0x00, 0x08, 0x68, 0x05, 0x80
	.byte 0x3f, 0x08, 0x6e, 0x09, 0xf1, 0x6a, 0x26, 0xc8
	.byte 0x66, 0x03, 0xb0, 0x00, 0x0a, 0xd1, 0xa8, 0x28
	.byte 0x3f, 0x00, 0x00, 0x66, 0x11, 0x80, 0x21, 0xc9
	.byte 0xcf, 0x13, 0x66, 0x05, 0xc9, 0xcf, 0x14, 0x6e
	.byte 0x05, 0xb6, 0x00, 0xff, 0x68, 0x04, 0xf1, 0x6a
	.byte 0x26, 0xb0, 0x5e, 0x0e, 0x3e, 0xe8, 0x8e, 0xbe
	.byte 0x02, 0x31, 0x81, 0x21, 0xc9, 0xd8, 0x66, 0x7a
	.byte 0xc1, 0x34, 0x8d, 0x21, 0xc9, 0xcf, 0x13, 0x66
	.byte 0x71, 0xf1, 0x21, 0x04, 0xca, 0x6e, 0x51, 0xc1
	.byte 0xa5, 0x28, 0x21, 0xc9, 0xcd, 0x01, 0xf1, 0xa5
	.byte 0x28, 0x41, 0xc1, 0x34, 0x8d, 0x23, 0xcb, 0xcf
	.byte 0x0d, 0x6b, 0x24, 0xcb, 0xcf, 0x08, 0x67, 0x1f
	.byte 0xee, 0x88, 0x1e
	sub	(xsp+182), xbc
	.byte 0xbe, 0x01, 0x00, 0x20, 0xbe, 0x02, 0x00, 0x0a
	.byte 0xbe, 0x03, 0x00, 0xff, 0xee, 0x88, 0x1e, 0xcf
	.byte 0xfd, 0xee, 0x64, 0xee, 0x88, 0x68, 0x30, 0xc9
	.byte 0x33, 0x00, 0x6e, 0xdc, 0xcb, 0xcf, 0x0e, 0x66
	.byte 0xd7, 0x1d, 0x5c, 0x36, 0xf4, 0xee, 0x88, 0x1e
	.byte 0xb6, 0xfd, 0xee, 0x64, 0xee, 0x88, 0x68, 0x17
	.byte 0xb6, 0x00, 0xa9, 0xbe, 0x01, 0x00, 0x20, 0xb1
	.byte 0x00, 0x0a, 0xbe, 0x03, 0x00, 0xff, 0xee, 0x88
	.byte 0x1e, 0x9d, 0xfd, 0xee, 0x64, 0xee, 0x88, 0x1e
	.byte 0x96, 0xfd, 0x5e, 0x0e, 0x3e, 0xe8, 0x8e, 0x8e
	.byte 0x01, 0x21, 0xc9, 0xcf, 0x0e, 0x6e, 0x07, 0xc1
	.byte 0x34, 0x8d, 0x3f, 0x13, 0x66, 0x35, 0xd8, 0x12
	.byte 0x1d, 0x23, 0x7c, 0xfc, 0xbe, 0x02, 0x31, 0x81
	.byte 0x3f, 0x00, 0x66, 0x06, 0xe1, 0x84, 0x8e, 0xeb
	.byte 0x68, 0x0b, 0xeb, 0x88, 0xd8, 0x06, 0xd7, 0xe2
	.byte 0x06, 0xe1, 0x84, 0x8e, 0xc8, 0xe1, 0x88, 0x8e
	.byte 0x20, 0xeb, 0xc0, 0x66, 0x02, 0xb1, 0xb9, 0xee
	.byte 0x88, 0x1e, 0x54, 0xfd, 0xee, 0x64, 0xee, 0x88
	.byte 0x1e, 0x4d, 0xfd, 0x5e, 0x0e, 0x3e, 0xe8, 0x8e
	.byte 0x8e, 0x01, 0x21, 0xc9, 0xcf, 0x0e, 0x6e, 0x07
	.byte 0xc1, 0x34, 0x8d, 0x3f, 0x13, 0x66, 0x35, 0xd8
	.byte 0x12, 0x1d, 0x23, 0x7c, 0xfc, 0xbe, 0x02, 0x31
	.byte 0x81, 0x3f, 0x00, 0x66, 0x06, 0xe1, 0x88, 0x8e
	.byte 0xeb, 0x68, 0x0b, 0xeb, 0x88, 0xd8, 0x06, 0xd7
	.byte 0xe2, 0x06, 0xe1, 0x88, 0x8e, 0xc8, 0xe1, 0x84
	.byte 0x8e, 0x20, 0xeb, 0xc0, 0x66, 0x02, 0xb1, 0xb8
	.byte 0xee, 0x88, 0x1e, 0x0b, 0xfd, 0xee, 0x64, 0xee
	.byte 0x88, 0x1e, 0x04, 0xfd, 0x5e, 0x0e, 0x3e, 0xe8
	.byte 0x8e, 0xc1, 0x34, 0x8d, 0x3f, 0x13, 0x6e, 0x07
	.byte 0xb6, 0x00, 0xa8, 0xbe, 0x01, 0x00, 0x01, 0xee
	.byte 0x88, 0x1e, 0xec, 0xfc, 0xee, 0x64, 0xee, 0x88
	.byte 0x1e, 0xe5, 0xfc, 0x5e, 0x0e, 0x3e, 0xe8, 0x8e
	.byte 0xc1, 0x34, 0x8d, 0x21, 0xc9, 0xcf, 0x10, 0x66
	.byte 0x11, 0xc9, 0xcf, 0x13, 0x66, 0x0c, 0xee, 0x88
	.byte 0x1e, 0xcd, 0xfc, 0xee, 0x64, 0xee, 0x88, 0x1e
	.byte 0xc6, 0xfc, 0x5e, 0x0e, 0xef, 0x6c, 0xd7, 0xfa
	.byte 0x04, 0xbf, 0x02, 0x60, 0xaf, 0x02, 0x20, 0x88
	.byte 0x02, 0x23, 0xcb, 0xd8, 0x76, 0x09, 0x01, 0xc1
	.byte 0x34, 0x8d, 0x21, 0xc9, 0xcf, 0x0e, 0x66, 0x0c
	.byte 0xc9, 0xdb, 0x66, 0x05, 0xc9, 0xcf, 0x13, 0x6e
	.byte 0x0e, 0x78, 0xf4, 0x00, 0xc2, 0x9b, 0x37, 0x00
	.byte 0x21, 0xc9, 0xcc, 0x1f, 0x76, 0xe9, 0x00, 0x22
	.byte 0x00, 0xe9, 0x12, 0xe9, 0x88, 0x1d, 0x33, 0x7c
	.byte 0xfc, 0xaf, 0x02, 0x20, 0xb8, 0x02, 0x32, 0xb2
	.byte 0x47, 0xc1, 0x90, 0x8e, 0x21, 0xdb, 0x12, 0xc9
	.byte 0xcf, 0x14, 0x66, 0x26, 0xc9, 0xcf, 0x0d, 0x66
	.byte 0x1a, 0xc9, 0xcf, 0x0c, 0x7e, 0xc1, 0x00, 0x40
	.byte 0x3c, 0x9d, 0xed, 0x00
	.byte 0xc3, 0x07, 0xe0, 0xec
	.byte 0x21, 0xb2, 0x41, 0xc9, 0xcf, 0x11, 0x63, 0x11
	.byte 0x78, 0xad, 0x00, 0x40, 0x44, 0x9d, 0xed, 0x00
	.byte 0x68, 0xea, 0x40, 0x4c, 0x9d, 0xed, 0x00, 0x68
	.byte 0xe3, 0xd8, 0x12, 0x1d, 0xa7, 0xe4, 0xfe, 0xcf
	.byte 0xcf, 0xff, 0x76, 0x93, 0x00, 0x1d, 0x5e, 0x94
	.byte 0xf9, 0xc7, 0xfb, 0x9f, 0xaf, 0x02, 0x20, 0xe8
	.byte 0x62, 0xc7, 0xfb, 0xda, 0x63, 0x05, 0x80, 0x3f
	.byte 0x0c, 0x66, 0x7d, 0xc7, 0xfb, 0xcf, 0x0f, 0x66
	.byte 0x06, 0xc7, 0xfb, 0xcf, 0x14, 0x6e, 0x05, 0x80
	.byte 0x3f, 0x0f, 0x6e, 0x6c, 0xc7, 0xfb, 0xcf, 0x10
	.byte 0x67, 0x0f, 0xc7, 0xfb, 0xcf, 0x13, 0x6b, 0x09
	.byte 0xaf, 0x02, 0x20, 0x88, 0x02, 0x3f, 0x0f, 0x66
	.byte 0x57, 0x40, 0xc0, 0x00, 0x00, 0x00, 0x1d, 0x37
	.byte 0xd4, 0xfc, 0xdb, 0xd9, 0x6e, 0x1d, 0xaf, 0x02
	.byte 0x20, 0x88, 0x02, 0x21, 0xc9, 0xcf, 0x11, 0x66
	.byte 0x05, 0xc9, 0xcf, 0x10, 0x6e, 0x02, 0x68, 0x38
	.byte 0xc7, 0xfb, 0xcf, 0x0e, 0x6b, 0x05, 0xc9, 0xcf
	.byte 0x0f, 0x66, 0x2d, 0xaf, 0x02, 0x20, 0x1e, 0xab
	.byte 0x06, 0xaf, 0x02, 0x21, 0x81, 0x21, 0xd8, 0x12
	.byte 0x89, 0x02, 0x23, 0xd9, 0x12, 0x1d, 0x41, 0x9d
	.byte 0xfc, 0xaf, 0x02, 0x20, 0xb8, 0x03, 0x47, 0xaf
	.byte 0x02, 0x20, 0x1e, 0xb3, 0xfb, 0xe8, 0xac, 0xaf
	.byte 0x02, 0x88, 0xaf, 0x02, 0x20, 0x1e, 0xa8, 0xfb
	.byte 0xd7, 0xfa, 0x05, 0xef, 0x64, 0x0e, 0x3e, 0xe8
	.byte 0x8e, 0x8e, 0x02, 0x23, 0xcb, 0xd8, 0x76, 0x99
	.byte 0x00, 0xc1, 0x34, 0x8d, 0x21, 0xc9, 0xcf, 0x13
	.byte 0x76, 0x8f, 0x00, 0xf1, 0xd3, 0x33, 0xc8, 0x7e
	.byte 0x88, 0x00, 0xc9, 0xcf, 0x0e, 0x6e, 0x1b, 0xc1
	.byte 0x36, 0x8d, 0x21, 0xc9, 0xcf, 0xb8, 0x66, 0x12
	.byte 0xc9, 0xcf, 0xb4, 0x6e, 0x75, 0xf1, 0xd3, 0x34
	.byte 0xc8, 0x6e, 0x6f, 0xc1, 0xd6, 0x34, 0x3f, 0x0c
	.byte 0x6f, 0x68, 0x22, 0x00, 0xe9, 0x12, 0xe9, 0x88
	.byte 0x1d, 0x33, 0x7c, 0xfc, 0xbe, 0x02, 0x32, 0xb2
	.byte 0x47, 0xc1, 0x90, 0x8e, 0x21, 0xdb, 0x12, 0xc9
	.byte 0xde, 0x66, 0x24, 0xc9, 0xd9, 0x66, 0x19, 0xc9
	.byte 0xd8
	.ascii "nG@N"
	.byte 0x9d, 0xed, 0x00
	.byte 0xc3, 0x07, 0xe0, 0xec, 0x21, 0xb2, 0x41, 0xc9
	.byte 0x8b, 0xcb, 0xcf, 0x0f, 0x63, 0x10, 0x68, 0x32
	.byte 0x40, 0x56, 0x9d, 0xed, 0x00, 0x68, 0xe9, 0x40
	.byte 0x58, 0x9d, 0xed, 0x00
	.byte 0x68, 0xe2, 0xc1, 0x36
	.byte 0x8d, 0x3f, 0xb8, 0x6e, 0x05, 0xcb, 0xcf, 0x0e
	.byte 0x66, 0x18, 0xd9, 0x12, 0x30, 0x48, 0x00, 0x1d
	.byte 0x41, 0x9d, 0xfc, 0xbe, 0x03, 0x47, 0xee, 0x88
	.byte 0x1e, 0x05, 0xfb, 0xee, 0x64, 0xee, 0x88, 0x1e
	.byte 0xfe, 0xfa, 0x5e, 0x0e, 0xef, 0x6a, 0x3e, 0xe8
	.byte 0x8e, 0xc1, 0x34, 0x8d, 0x21, 0xc9, 0xcf, 0x10
	.byte 0x66, 0x18, 0xc9, 0xcf, 0x0f, 0x66, 0x13, 0xc9
	.byte 0xcf, 0x0e, 0x66, 0x0e, 0xc9, 0xcf, 0x11, 0x66
	.byte 0x09, 0xc9, 0xdb, 0x66, 0x05, 0xc9, 0xcf, 0x13
	.byte 0x6e, 0x02, 0x68, 0x4e, 0xc1, 0x38, 0x8d, 0x21
	.byte 0xc9, 0xcf, 0xd3, 0x66, 0x12, 0xc9, 0xcf, 0xd2
	.byte 0x66, 0x0d, 0x40, 0xc0, 0x00, 0x00, 0x00, 0x1d
	.byte 0x37, 0xd4, 0xfc, 0xdb, 0xd9, 0x6e, 0x02, 0x68
	.byte 0x31, 0x8e, 0x02, 0x3f, 0x00, 0x66, 0x24, 0x1d
	.byte 0x19, 0x60, 0xfb, 0xcf, 0xee, 0x03, 0xbf, 0x04
	.byte 0x47, 0xe8, 0xa8, 0x8e, 0x02, 0x21, 0x1d, 0x33
	.byte 0x7c, 0xfc, 0xcf, 0x61, 0x8f, 0x04, 0x87, 0xbe
	.byte 0x02, 0x47, 0xbe, 0x03, 0x00, 0x7f, 0xee, 0x88
	.byte 0x1e, 0x8d, 0xfa, 0xee, 0x64, 0xee, 0x88, 0x1e
	.byte 0x86, 0xfa, 0x5e, 0xef, 0x62, 0x0e, 0x3e, 0xe8
	.byte 0x8e, 0x8e, 0x02, 0x3f, 0x00, 0x66, 0x4c, 0xc1
	.byte 0x34, 0x8d, 0x21, 0xc9, 0xcf, 0x10, 0x66, 0x18
	.byte 0xc9, 0xcf, 0x0f, 0x66, 0x13, 0xc9, 0xcf, 0x0e
	.byte 0x66, 0x0e, 0xc9, 0xcf, 0x11, 0x66, 0x09, 0xc9
	.byte 0xdb, 0x66, 0x05, 0xc9, 0xcf, 0x13, 0x6e, 0x02
	.byte 0x68, 0x29, 0xc1, 0x38, 0x8d, 0x21, 0xc9, 0xcf
	.byte 0xd3, 0x66, 0x12, 0xc9, 0xcf, 0xd2, 0x66, 0x0d
	.byte 0x40, 0xc0, 0x00, 0x00, 0x00, 0x1d, 0x37, 0xd4
	.byte 0xfc, 0xdb, 0xd9, 0x6e, 0x02, 0x68, 0x0c, 0xee
	.byte 0x88, 0x1e, 0x34, 0xfa, 0xee, 0x64, 0xee, 0x88
	.byte 0x1e, 0x2d, 0xfa, 0x5e, 0x0e, 0x3e, 0xe8, 0x8e
	.byte 0xc1, 0x34, 0x8d, 0x3f, 0x13, 0x66, 0x0c, 0xee
	.byte 0x88, 0x1e, 0x1c, 0xfa, 0xee, 0x64, 0xee, 0x88
	.byte 0x1e, 0x15, 0xfa, 0x5e, 0x0e, 0x3e, 0xe8, 0x8e
	.byte 0xc1, 0x34, 0x8d, 0x3f, 0x13, 0x66, 0x2f, 0xee
	.byte 0x88, 0x1e, 0x04, 0xfa, 0xb6, 0x00, 0xa8, 0xbe
	.byte 0x01, 0x00, 0x05, 0xbe, 0x02, 0x31, 0xbe, 0x03
	.byte 0x32, 0x82, 0x21, 0x81, 0xc1, 0x66, 0x05, 0xb1
	.byte 0x00, 0x40, 0x68, 0x03, 0xb1, 0x00, 0x00, 0xb2
	.byte 0x00, 0x40, 0xee, 0x88, 0x1e, 0xe1, 0xf9, 0xee
	.byte 0x64, 0xee, 0x88, 0x1e, 0xda, 0xf9, 0x5e, 0x0e
	.byte 0x3e, 0xe8, 0x8e, 0x8e, 0x02, 0x3f, 0x00, 0x66
	.byte 0x4b, 0xc1, 0x34, 0x8d, 0x3f, 0x13, 0x66, 0x44
	.byte 0x40, 0xc0, 0x00, 0x00, 0x00, 0x1d, 0x37, 0xd4
	.byte 0xfc, 0xdb, 0xd9, 0x66, 0x37, 0xee, 0x88, 0x1e
	.byte 0xb6, 0xf9, 0xf1, 0x1e, 0x04, 0xca, 0x66, 0x0d
	.byte 0x40, 0x80, 0x80, 0x02, 0x00, 0x1d, 0x37, 0xd4
	.byte 0xfc, 0xdb, 0xd8, 0x6e, 0x18, 0xb6, 0x00, 0x48
	.byte 0xbe, 0x01, 0x00, 0x03, 0xc2, 0xc8, 0xff, 0x00
	.byte 0x21, 0xbe, 0x02, 0x41, 0xbe, 0x03, 0x00, 0x07
	.byte 0xee, 0x88, 0x1e, 0x8b, 0xf9, 0xee, 0x64, 0xee
	.byte 0x88, 0x1e, 0x84, 0xf9, 0x5e, 0x0e, 0x3e, 0xe8
	.byte 0x8e, 0x8e, 0x02, 0x21, 0xc9, 0xd8, 0x66, 0x56
	.byte 0xc1, 0x34, 0x8d, 0x23, 0xcb, 0xcf, 0x10, 0x66
	.byte 0x1a, 0xcb, 0xcf, 0x0f, 0x66, 0x15, 0xcb, 0xcf
	.byte 0x0e, 0x66, 0x10, 0xcb, 0xdb, 0x66, 0x0c, 0xcb
	.byte 0xcf, 0x13, 0x66, 0x07, 0xc1, 0x36, 0x8d, 0x3f
	.byte 0x51, 0x6e, 0x02, 0x68, 0x31, 0xf1, 0xe2, 0x26
	.byte 0xc8, 0x6e, 0x2b, 0x20, 0x00, 0xe8, 0x12, 0x1d
	.byte 0x33, 0x7c, 0xfc, 0xdb, 0x12, 0xf2, 0x60, 0x9d
	.byte 0xed, 0x31, 0xc3, 0x07, 0xe4, 0xec, 0x21, 0xbe
	.byte 0x02, 0x41, 0xf1, 0x3a, 0x8d, 0x41, 0xbe, 0x03
	.byte 0x00, 0xff, 0xee, 0x88, 0x1e, 0x29, 0xf9, 0xee
	.byte 0x64, 0xee, 0x88, 0x1e, 0x22, 0xf9, 0x5e, 0x0e
	.byte 0x3e, 0xe8, 0x8e, 0xc1, 0x34, 0x8d, 0x21, 0xc9
	.byte 0xcf, 0x10, 0x66, 0x1f, 0xc9, 0xcf, 0x0f, 0x66
	.byte 0x1a, 0xc9, 0xcf, 0x0e, 0x66, 0x15, 0xc9, 0xdb
	.byte 0x66, 0x11, 0xc9, 0xcf, 0x13, 0x66, 0x0c, 0xee
	.byte 0x88, 0x1e, 0xfc, 0xf8, 0xee, 0x64, 0xee, 0x88
	.byte 0x1e, 0xf5, 0xf8, 0x5e, 0x0e, 0x3e, 0xe8, 0x8e
	.byte 0xc1, 0x34, 0x8d, 0x3f, 0x13, 0x66, 0x1e, 0x1e
	.byte 0xd2, 0x03, 0x83, 0x3f, 0x0f, 0x66, 0x16, 0x83
	.byte 0x3f, 0x0c, 0x66, 0x11, 0xee, 0x88, 0x1e, 0xb3
	.byte 0x03, 0xee, 0x88, 0x1e, 0xd2, 0xf8, 0xee, 0x64
	.byte 0xee, 0x88, 0x1e, 0xcb, 0xf8, 0x5e, 0x0e, 0x3e
	.byte 0xe8, 0x8e, 0xc1, 0x34, 0x8d, 0x21, 0xc9, 0xcf
	.byte 0x11, 0x66, 0x13, 0xc9, 0xcf, 0x0e, 0x66, 0x0e
	.byte 0xc9, 0xcf, 0x13, 0x66, 0x09, 0xc1, 0x3a, 0x8d
	.byte 0x21, 0xc9, 0xcf, 0x0f, 0x63, 0x02, 0x68, 0x60
	.byte 0xbe, 0x02, 0x31, 0x81, 0x21, 0xc9, 0xd8, 0x66
	.byte 0x3b, 0xf1, 0x92, 0x8e, 0xbd, 0xc1, 0x3a, 0x8d
	.byte 0x21, 0xd8, 0x12, 0x31, 0x5d, 0x00, 0x1d, 0xf7
	.byte 0xd4, 0xfc, 0xdb, 0xcc, 0x7f, 0x00, 0xbe, 0x03
	.byte 0x32, 0xbe, 0x02, 0x31, 0xdb, 0xd8, 0x66, 0x05
	.byte 0xb1, 0x00, 0x00, 0x68, 0x12, 0xc1, 0x3a, 0x8d
	.byte 0x21, 0xd8, 0x12, 0xf1, 0x8d, 0x91, 0x33, 0xe8
	.byte 0x12, 0xeb, 0x80, 0x80, 0x21, 0xb1, 0x41, 0xb2
	.byte 0x00, 0x7f, 0x68, 0x0b, 0xf1, 0x92, 0x8e, 0xb5
	.byte 0xb1, 0x00, 0x00, 0xbe, 0x03, 0x00, 0x00, 0xee
	.byte 0x88, 0x1e, 0x30, 0x03, 0xee, 0x88, 0x1e, 0x4f
	.byte 0xf8, 0xee, 0x64, 0xee, 0x88, 0x1e, 0x48, 0xf8
	.byte 0x5e, 0x0e, 0x3e, 0xe8, 0x8e, 0xc1, 0x34, 0x8d
	.byte 0x21, 0xc9, 0xcf, 0x11, 0x66, 0x11, 0xc9, 0xcf
	.byte 0x13, 0x66, 0x0c, 0xee, 0x88, 0x1e, 0x30, 0xf8
	.byte 0xee, 0x64, 0xee, 0x88, 0x1e, 0x29, 0xf8, 0x5e
	.byte 0x0e, 0x3e, 0xe8, 0x8e, 0xf1, 0xcd, 0x34, 0xcb
	.byte 0x6e, 0x2d, 0xc1, 0x34, 0x8d, 0x21, 0xc9, 0xcf
	.byte 0x11, 0x66, 0x0d, 0xc9, 0xcf, 0x13, 0x66, 0x08
	.byte 0x1e, 0xf9, 0x02, 0x83, 0x3f, 0x0f, 0x6e, 0x02
	.byte 0x68, 0x15, 0xf1, 0xf9, 0x90, 0xb1, 0xee, 0x88
	.byte 0x1e, 0xd9, 0x02, 0xee, 0x88, 0x1e, 0xf8, 0xf7
	.byte 0xee, 0x64, 0xee, 0x88, 0x1e, 0xf1, 0xf7, 0x5e
	.byte 0x0e, 0x3e, 0xe8, 0x8e, 0xc1, 0x34, 0x8d, 0x3f
	.byte 0x13, 0x66, 0x23, 0x40, 0xc0, 0x00, 0x00, 0x00
	.byte 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0xd9, 0x66, 0x16
	.byte 0x8e, 0x02, 0x3f, 0x00, 0x66, 0x04, 0xf1, 0x52
	.byte 0x8d, 0xbb, 0xee, 0x88, 0x1e, 0xc9, 0xf7, 0xee
	.byte 0x64, 0xee, 0x88, 0x1e, 0xc2, 0xf7, 0x5e, 0x0e
	.byte 0xef, 0x6c, 0xd7, 0xfa, 0x04, 0xbf, 0x02, 0x60
	.byte 0xc1, 0x34, 0x8d, 0x3f, 0x13, 0x76, 0x88, 0x00
	.byte 0x40, 0xc0, 0x00, 0x00, 0x00, 0x1d, 0x37, 0xd4
	.byte 0xfc, 0xdb, 0xd9, 0x66, 0x7b, 0xaf, 0x02, 0x20
	.byte 0x88, 0x03, 0x21, 0xd8, 0x12, 0xe8, 0x12, 0x1d
	.byte 0x33, 0x7c, 0xfc, 0xc7, 0xfb, 0x9f, 0x40, 0x00
	.byte 0x88, 0x02, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xc7
	.byte 0xfb, 0x8b, 0xd9, 0x12, 0xd9, 0x88, 0xd8, 0xec
	.byte 0x02, 0xdb, 0xcf, 0x12, 0x00, 0x66, 0x23, 0xdb
	.byte 0xcf, 0x11, 0x00, 0x6e, 0x3a, 0xf2, 0x7c, 0x9d
	.byte 0xed, 0x32, 0xc3, 0x07, 0xe8, 0xe4, 0x23, 0xf2
	.byte 0x64, 0x9d, 0xed, 0x32, 0xf3, 0x07, 0xe8, 0xe0
	.byte 0x32, 0xaf, 0x02, 0x20, 0xa2, 0x23, 0xb3, 0xe8
	.byte 0x68, 0x23, 0xf2, 0x9a, 0x9d, 0xed, 0x32, 0xc3
	.byte 0x07, 0xe8, 0xe4, 0x23, 0xf2, 0x82, 0x9d, 0xed
	.byte 0x32, 0xf3, 0x07, 0xe8, 0xe0, 0x32, 0xaf, 0x02
	.byte 0x20, 0xa2, 0x23, 0xb3, 0xe8, 0x68, 0x06, 0xaf
	.byte 0x02, 0x20, 0x1e, 0x33, 0xf7, 0xe8, 0xac, 0xaf
	.byte 0x02, 0x88, 0xaf, 0x02, 0x20, 0x1e, 0x28, 0xf7
	.byte 0xd7, 0xfa, 0x05, 0xef, 0x64, 0x0e, 0xbf, 0xf6
	.byte 0x37, 0xd7, 0xfa, 0x04, 0xbf, 0x08, 0x60, 0xaf
	.byte 0x08, 0x20, 0x88, 0x02, 0x21, 0xc7, 0xfb, 0x99
	.byte 0xc7, 0xfb, 0xd8, 0x76, 0xa4, 0x00, 0xc1, 0x34
	.byte 0x8d, 0x21, 0xc9, 0xcf, 0x0e, 0x66, 0x5f, 0xc9
	.byte 0xcf, 0x13, 0x66, 0x5a, 0xe8, 0xa8, 0xc7, 0xfb
	.byte 0x89, 0x1d, 0x33, 0x7c, 0xfc, 0xc7, 0xfb, 0x9f
	.byte 0xbf, 0x04, 0x00, 0x48, 0x40, 0x00, 0x80, 0x02
	.byte 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xbf, 0x05, 0x47
	.byte 0x40, 0x01, 0x80, 0x02, 0x00, 0x1d, 0x37, 0xd4
	.byte 0xfc, 0xbf, 0x02, 0x30, 0xb8, 0x04, 0x47, 0x1d
	.byte 0x55, 0x9b, 0xfc, 0xbf, 0x02, 0x33, 0xaf, 0x08
	.byte 0x20, 0xb8, 0x02, 0x31, 0xb8, 0x03, 0x32, 0x83
	.byte 0x3f, 0x0e, 0x6f, 0x1c, 0xc7, 0xfb, 0x89, 0xd8
	.byte 0x12, 0xf2, 0xa0, 0x9d, 0xed, 0x33, 0xc3, 0x07
	.byte 0xec, 0xe0, 0x21, 0xb1, 0x41, 0xb2, 0x00, 0x30
	.byte 0xf1, 0x52, 0x8d, 0xbb
	.ascii "h+h:"
	.byte 0xaf, 0x08, 0x20, 0xb8, 0x01, 0x00, 0x00, 0x83
	.byte 0x21, 0xb1, 0x41, 0x8b, 0x01, 0x21, 0xc9, 0xef
	.byte 0x02, 0xc9, 0xee, 0x02, 0xc7, 0xfb, 0x81, 0xc9
	.byte 0x8f, 0xb2, 0x47, 0x81, 0x21, 0xd8, 0x12, 0xf1
	.byte 0x92, 0xff, 0x31, 0xe8, 0x12, 0xe9, 0x80, 0xb0
	.byte 0x47, 0xaf, 0x08, 0x20, 0x1e, 0x71, 0xf6, 0xe8
	.byte 0xac, 0xaf, 0x08, 0x88, 0xaf, 0x08, 0x20, 0x1e
	.byte 0x66, 0xf6, 0xd7, 0xfa, 0x05, 0xbf, 0x0a, 0x37
	.byte 0x0e, 0x3e, 0xe8, 0x8e, 0xc1, 0x34, 0x8d, 0x3f
	.byte 0x13, 0x66, 0x12, 0x40, 0x86, 0x28, 0x00, 0x00
	.byte 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0x12, 0xee, 0x88
	.byte 0xdb, 0x89, 0x1e, 0x89, 0x01, 0x5e, 0x0e, 0x3e
	.byte 0xe8, 0x8e, 0xc1, 0x34, 0x8d, 0x3f, 0x13, 0x66
	.byte 0x12, 0x40, 0x88, 0x28, 0x00, 0x00, 0x1d, 0x37
	.byte 0xd4, 0xfc, 0xdb, 0x12, 0xee, 0x88, 0xdb, 0x89
	.byte 0x1e, 0x6b, 0x01, 0x5e, 0x0e, 0x3e, 0xe8, 0x8e
	.byte 0xc1, 0x34, 0x8d, 0x3f, 0x13, 0x66, 0x12, 0x40
	.byte 0x8a, 0x28, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc
	.byte 0xdb, 0x12, 0xee, 0x88, 0xdb, 0x89, 0x1e, 0x4d
	.byte 0x01, 0x5e, 0x0e, 0x3e, 0xe8, 0x8e, 0xc1, 0x34
	.byte 0x8d, 0x3f, 0x13, 0x66, 0x12, 0x40, 0x8c, 0x28
	.byte 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0x12
	.byte 0xee, 0x88, 0xdb, 0x89, 0x1e, 0x2f, 0x01, 0x5e
	.byte 0x0e, 0x3e, 0xe8, 0x8e, 0xc1, 0x34, 0x8d, 0x3f
	.byte 0x13, 0x66, 0x12, 0x40, 0x8e, 0x28, 0x00, 0x00
	.byte 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0x12, 0xee, 0x88
	.byte 0xdb, 0x89, 0x1e, 0x11, 0x01, 0x5e, 0x0e, 0x3e
	.byte 0xe8, 0x8e, 0xc1, 0x34, 0x8d, 0x3f, 0x13, 0x66
	.byte 0x12, 0x40, 0x90, 0x28, 0x00, 0x00, 0x1d, 0x37
	.byte 0xd4, 0xfc, 0xdb, 0x12, 0xee, 0x88, 0xdb, 0x89
	.byte 0x1e, 0xf3, 0x00, 0x5e, 0x0e, 0xc1, 0x34, 0x8d
	.byte 0x3f, 0x13, 0xb0, 0xf6, 0xb8, 0x02, 0x33, 0xb8
	.byte 0x03, 0x34, 0x83, 0x25, 0xcd, 0xcf, 0xff, 0x6e
	.byte 0x08, 0xb3, 0x00, 0x7f, 0xb4, 0x00, 0x7f, 0x68
	.byte 0x0f, 0xcd, 0x8b, 0xcb, 0xcc, 0x01, 0xcb, 0xee
	.byte 0x06, 0xb3, 0x43, 0xcd, 0xef, 0x01, 0xb4, 0x45
	.byte 0x78, 0x7d, 0xf5, 0x3e, 0xe8, 0x8e, 0x40, 0x80
	.byte 0x28, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb
	.byte 0xcf, 0xb7, 0x00, 0x66, 0x0a, 0xdb, 0xcf, 0xb6
	.byte 0x00, 0x6e, 0x17, 0xee, 0x88, 0x68, 0x10, 0xc1
	.byte 0x34, 0x8d, 0x3f, 0x13, 0x66, 0x0c, 0xb6, 0x00
	.byte 0xb3, 0xbe, 0x01, 0x00, 0x00, 0xee, 0x88, 0x1e
	.byte 0x4e, 0xf5, 0x5e, 0x0e, 0xc1, 0x34, 0x8d, 0x3f
	.byte 0x13, 0xb0, 0xf6, 0x78, 0x42, 0xf5, 0x3e, 0xe8
	.byte 0x8e, 0xc1, 0x34, 0x8d, 0x3f, 0x13, 0x66, 0x12
	.byte 0x40, 0x04, 0x01, 0x00, 0x00, 0x1d, 0x37, 0xd4
	.byte 0xfc, 0xdb, 0xd8, 0x66, 0x05, 0xee, 0x88, 0x1e
	.byte 0x26, 0xf5, 0x5e, 0x0e, 0x80, 0x3f, 0x00, 0xb0
	.byte 0xfe, 0x88, 0x01, 0x3f, 0x03, 0xb0, 0xf6, 0xb0
	.byte 0x14, 0x3a, 0x8d, 0x0e, 0xef, 0x6e, 0xc1, 0x3a
	.byte 0x8d, 0x21, 0xd8, 0x12, 0xd9, 0xa8, 0x1d, 0xf7
	.byte 0xd4, 0xfc, 0xbf, 0x03, 0x47, 0xc1, 0x3a, 0x8d
	.byte 0x21, 0xd8, 0x12, 0x31, 0x20, 0x00, 0x1d, 0xf7
	.byte 0xd4, 0xfc, 0xb7, 0x30, 0xb8, 0x04, 0x47, 0xb8
	.byte 0x02, 0x14, 0x3a, 0x8d, 0x1d, 0x55, 0x9b, 0xfc
	.byte 0xb7, 0x33, 0xef, 0x66, 0x0e, 0xef, 0x6e, 0x40
	.byte 0x00, 0x80, 0x02, 0x00, 0x1d, 0x37, 0xd4, 0xfc
	.byte 0xbf, 0x03, 0x47, 0x40, 0x01, 0x80, 0x02, 0x00
	.byte 0x1d, 0x37, 0xd4, 0xfc, 0xb7, 0x30, 0xb8, 0x04
	.byte 0x47, 0xb8, 0x02, 0x00, 0x48, 0x1d, 0x55, 0x9b
	.byte 0xfc, 0xb7, 0x33, 0xef, 0x66, 0x0e, 0xd9, 0x12
	.byte 0xf2, 0xa4, 0x9d, 0xed, 0x32, 0xc3, 0x07, 0xe8
	.byte 0xe4, 0x25, 0xcd, 0xcf, 0x16, 0xb0, 0xfb, 0xda
	.byte 0x12, 0xda, 0xec, 0x02, 0xf2, 0xa4, 0x9e, 0xed
	.byte 0x33, 0xea, 0x13, 0xeb, 0x82, 0xa2, 0x23, 0xb3
	.byte 0xe8, 0x0e, 0xef, 0x6c, 0x3e, 0xe8, 0x8e, 0xc1
	.byte 0x34, 0x8d, 0x3f, 0x11, 0x66, 0x6c, 0xf1, 0xcd
	.byte 0x34, 0xcb, 0x6e, 0x66, 0xf1, 0xf9, 0x90, 0xb9
	.byte 0x8e, 0x03, 0x21, 0x8e, 0x02, 0xc1, 0xbf, 0x04
	.byte 0x00, 0x00, 0xc9, 0xd8, 0x66, 0x04, 0xbf, 0x04
	.byte 0x00, 0x08, 0xbf, 0x06, 0x02, 0x00, 0x00, 0xf1
	.byte 0xfb, 0x90, 0x31, 0x9f, 0x06, 0x20, 0xe8, 0x12
	.byte 0xe9, 0x80, 0x80, 0x21, 0xc9, 0xcf, 0xff, 0x66
	.byte 0x39, 0xd8, 0x12, 0x31, 0x01, 0x06, 0x1d, 0xf7
	.byte 0xd4, 0xfc, 0xdb, 0xd9, 0x6e, 0x22, 0xf1, 0xfb
	.byte 0x90, 0x30, 0x9f, 0x06, 0x21, 0xe9, 0x12, 0xe8
	.byte 0x81, 0x81, 0x21, 0xb6, 0x41, 0xbe, 0x01, 0x00
	.byte 0x04, 0x8f, 0x04, 0x21, 0xbe, 0x02, 0x41, 0xbe
	.byte 0x03, 0x00, 0x08, 0xee, 0x88, 0x1e, 0x28, 0xf4
	.byte 0x9f, 0x06, 0x61, 0x9f, 0x06, 0x3f, 0x10, 0x00
	.byte 0x67, 0xb5, 0x5e, 0xef, 0x64, 0x0e, 0xf1, 0xf9
	.byte 0x90, 0xb9, 0xb0, 0x00, 0x48, 0xb8, 0x01, 0x00
	.byte 0x05, 0xb8, 0x02, 0x32, 0xb8, 0x03, 0x33, 0x83
	.byte 0x23, 0x82, 0xc3, 0x66, 0x05, 0xb2, 0x00, 0x01
	.byte 0x68, 0x03, 0xb2, 0x00, 0x00, 0xb3, 0x00, 0x01
	.byte 0x78, 0xf5, 0xf3, 0x3e, 0xe8, 0x8e, 0xc1, 0x34
	.byte 0x8d, 0x21, 0xc9, 0xcf, 0x10, 0x66, 0x18, 0xc9
	.byte 0xcf, 0x0f, 0x66, 0x13, 0xc9, 0xcf, 0x0e, 0x66
	.byte 0x0e, 0xc9, 0xcf, 0x11, 0x66, 0x09, 0xc9, 0xdb
	.byte 0x66, 0x05, 0xc9, 0xcf, 0x13, 0x6e, 0x02, 0x68
	.byte 0x43, 0x40, 0xc0, 0x00, 0x00, 0x00, 0x1d, 0x37
	.byte 0xd4, 0xfc, 0xdb, 0xd9, 0x66, 0x36, 0x8e, 0x03
	.byte 0x21, 0x8e, 0x02, 0xc1, 0x66, 0x2e, 0xf1, 0xf9
	.byte 0x90, 0xb9, 0xb6, 0x00, 0x98, 0xbe, 0x01, 0x00
	.byte 0x01, 0x40, 0x00, 0x03, 0x00, 0x00, 0x1d, 0x37
	.byte 0xd4, 0xfc, 0xbe, 0x02, 0x30, 0xcf, 0xcf, 0x50
	.byte 0x67, 0x05, 0xb0, 0x00, 0x01, 0x68, 0x04, 0xcf
	.byte 0x61, 0xb0, 0x47, 0xbe, 0x03, 0x00, 0x7f, 0xee
	.byte 0x88, 0x1e, 0x8c, 0xf3, 0x5e, 0x0e, 0x3e, 0xe8
	.byte 0x8e, 0xc1, 0x34, 0x8d, 0x21, 0xc9, 0xcf, 0x10
	.byte 0x66, 0x18, 0xc9, 0xcf, 0x0f, 0x66, 0x13, 0xc9
	.byte 0xcf, 0x0e, 0x66, 0x0e, 0xc9, 0xcf, 0x11, 0x66
	.byte 0x09, 0xc9, 0xdb, 0x66, 0x05, 0xc9, 0xcf, 0x13
	.byte 0x6e, 0x02, 0x68, 0x42, 0x40, 0xc0, 0x00, 0x00
	.byte 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0xd9, 0x66
	.byte 0x35, 0x8e, 0x03, 0x21, 0x8e, 0x02, 0xc1, 0x66
	.byte 0x2d, 0xf1, 0xf9, 0x90, 0xb9, 0xb6, 0x00, 0x98
	.byte 0xbe, 0x01, 0x00, 0x01, 0x40, 0x00, 0x03, 0x00
	.byte 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xbe, 0x02, 0x30
	.byte 0xcf, 0xd9, 0x6b, 0x05, 0xb0, 0x00, 0x50, 0x68
	.byte 0x04, 0xcf, 0x69, 0xb0, 0x47, 0xbe, 0x03, 0x00
	.byte 0x7f, 0xee, 0x88, 0x1e, 0x22, 0xf3, 0x5e, 0x0e
ExtDev_SndParam_Block48_Var40:
	setda	1, 37113
	ld	(xwa), 72
	ld	(xwa+1), 5
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 64
	jr	3
	ld	(xde), 0
	ld	(xhl), 64
	jrl	-3333
ExtDev_SndParam_Block48_Var80:
	setda	1, 37113
	ld	(xwa), 72
	ld	(xwa+1), 5
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 128
	jr	3
	ld	(xde), 0
	ld	(xhl), 128
	jrl	-3370
ExtDev_SndParam_Block48_Var04:
	setda	1, 37113
	ld	(xwa), 72
	ld	(xwa+1), 5
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 4
	jr	3
	ld	(xde), 0
	ld	(xhl), 4
	jrl	-3407
ExtDev_SndParam_Block48_Var04_B:
	setda	1, 37113
	ld	(xwa), 72
	ld	(xwa+1), 6
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 4
	jr	3
	ld	(xde), 0
	ld	(xhl), 4
	jrl	-3444
ExtDev_SndParam_Write98_Block:
	push	xiz
	ld	xiz, xwa
	ldda8	a, 36154
	extz	wa
	ldw	bc, 1539
	call	SndParam_LookupViaEncode
	cps	hl, 1
	jr	nz, 39
	.byte 0xf1
	swi	1
	.byte 0x90
	ld	(xbc-74), 152
	ld	(xiz+1), 2
	lda	xbc, (xiz+2)
	lda	xde, (xiz+3)
	ld	a, (xde)
	.byte 0x81, 0xc1
	jr	z, 5
	ld	(xbc), 128
	jr	3
	ld	(xbc), 0
	ld	(xde), 128
	ld	xwa, xiz
	calr	62033
	pop	xiz
	ret
ExtDev_SndParam_Block98_Var40:
	setda	1, 37113
	ld	(xwa), 152
	ld	(xwa+1), 2
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 64
	jr	3
	ld	(xde), 0
	ld	(xhl), 64
	jrl	-3542
ExtDev_SndParam_BlockA9_Var02:
	.byte 0xc1
	ldw	iz, 16269
	.byte 0x87
	ret	nz
	.byte 0xf1
	swi	1
	.byte 0x90
	ld	(xbc-80), 169
	ld	(xwa+1), 10
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	.byte 0x82, 0xc3
	jr	z, 5
	ld	(xde), 2
	jr	3
	ld	(xde), 0
	ld	(xhl), 2
	calr	61950
	ret
ExtDev_SndParam_Block98_Var80:
	setda	1, 37113
	ld	(xwa), 152
	ld	(xwa+1), 11
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 128
	jr	3
	ld	(xde), 0
	ld	(xhl), 128
	jrl	-3624
ExtDev_SndParam_Block98_Var40_B:
	setda	1, 37113
	ld	(xwa), 152
	ld	(xwa+1), 11
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 64
	jr	3
	ld	(xde), 0
	ld	(xhl), 64
	jrl	-3661
ExtDev_SndParam_ConfigAndWrite:
	push	xiz
	ld	xiz, xwa
	ld	a, (xiz+3)
	.byte 0x8e
	push_sr
	.byte 0xc1
	jr	z, 64
	.byte 0xf1
	swi	1
	.byte 0x90, 0xb9, 0xb6
	push_a
	push	xde
	.byte 0x8d
	ld	(xiz+1), 5
	ldda8	a, 36154
	extz	wa
	ldw	bc, 93
	call	SndParam_LookupViaEncode
	lda	xbc, (xiz+2)
	cps	hl, 0
	jr	nz, 20
	ldda8	a, 36154
	extz	wa
	ldada	xde, 37261
	extz	xwa
	add	xwa, xde
	ld	a, (xwa)
	ld	(xbc), a
	jr	3
	ld	(xbc), 0
	ld	(xiz+3), 127
	ld	xwa, xiz
	calr	61800
	pop	xiz
	ret
ExtDev_SndParam_Block14_Dual:
	lda	xhl, (xwa+2)
	lda	xix, (xwa+3)
	ld	e, (xhl)
	ld	c, (xix)
	and	c, e
	ret	z
	.byte 0xf1
	swi	1
	.byte 0x90, 0xb9, 0xb0
	push_a
	push	xde
	.byte 0x8d
	ld	(xwa+1), 4
	ld	(xhl), 64
	ld	(xix), 64
	calr	61763
	ret
ExtDev_SndParam_Write48_Block:
	push	xiz
	ld	xiz, xwa
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cps	hl, 0
	jr	nz, 39
	.byte 0xf1
	swi	1
	.byte 0x90
	ld	(xbc-74), 72
	ld	(xiz+1), 4
	lda	xbc, (xiz+2)
	lda	xde, (xiz+3)
	ld	a, (xde)
	.byte 0x81, 0xc1
	jr	z, 5
	ld	(xbc), 64
	jr	3
	ld	(xbc), 0
	ld	(xde), 64
	ld	xwa, xiz
	calr	61707
	pop	xiz
	ret
ExtDev_SndParam_Block48_Var02:
	cpdi8	36148, 16
	ret	z
	setda	1, 37113
	ld	(xwa), 72
	ld	(xwa+1), 5
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 2
	jr	3
	ld	(xde), 0
	ld	(xhl), 2
	jrl	-3875
ExtDev_SndParam_Block70_Var04:
	setda	1, 37113
	ld	(xwa), 112
	ld	(xwa+1), 0
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 4
	jr	3
	ld	(xde), 0
	ld	(xhl), 4
	jrl	-3912
ExtDev_SndParam_DispatchAndWriteA8:
	push	xiz
	ld	xiz, xwa
	ldda8	a, 36148
	cp	a, 16
	jr	z, 24
	cp	a, 15
	jr	z, 19
	cp	a, 14
	jr	z, 14
	cp	a, 17
	jr	z, 9
	cps	a, 3
	jr	z, 5
	cp	a, 19
	jr	nz, 2
	jr	49
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cps	hl, 1
	jr	z, 36
	.byte 0xf1
	swi	1
	.byte 0x90
	ld	(xbc-74), 168
	ld	(xiz+1), 4
	lda	xde, (xiz+2)
	lda	xhl, (xiz+3)
	ld	c, (xde)
	ld	a, (xhl)
	and	a, c
	jr	z, 11
	ld	(xde), 2
	ld	(xhl), 2
	ld	xwa, xiz
	calr	61537
	pop	xiz
	ret
ExtDev_SndParam_DispatchAndWriteA8_Alt:
	push	xiz
	ld	xiz, xwa
	ldda8	a, 36148
	cp	a, 16
	jr	z, 24
	cp	a, 15
	jr	z, 19
	cp	a, 14
	jr	z, 14
	cp	a, 17
	jr	z, 9
	cps	a, 3
	jr	z, 5
	cp	a, 19
	jr	nz, 2
	jr	49
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cps	hl, 1
	jr	z, 36
	.byte 0xf1
	swi	1
	.byte 0x90
	ld	(xbc-74), 168
	ld	(xiz+1), 4
	lda	xde, (xiz+2)
	lda	xhl, (xiz+3)
	ld	c, (xde)
	ld	a, (xhl)
	and	a, c
	jr	z, 11
	ld	(xde), 1
	ld	(xhl), 1
	ld	xwa, xiz
	calr	61448
	pop	xiz
	ret
ExtDev_SndParam_MultiReg_Iterate:
	setda	1, 37113
	lda	xix, (xwa+2)
	ld	l, (xwa+3)
	ld	d, (xix)
	ld	e, l
	and	e, d
	extz	bc
	cps	e, 0
	jrl	nz, -1030
	or	d, l
	ld	(xix), d
	jrl	-930
ExtDev_SndParam_DispatchComplex:
	dec	2, xsp
	push	xiz
	ld	(xsp+4), c
	ld	xiz, xwa
	ldda8	a, 36148
	cp	a, 16
	jr	z, 24
	cp	a, 15
	jr	z, 19
	cp	a, 14
	jr	z, 14
	cp	a, 17
	jr	z, 9
	cps	a, 3
	jr	z, 5
	cp	a, 19
	jr	nz, 2
	jr	59
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cps	hl, 1
	jr	z, 46
	ld	a, (xiz+3)
	.byte 0x8e
	push_sr
	.byte 0xc1
	jr	z, 38
	.byte 0xf1
	swi	1
	.byte 0x90
	ld	(xbc-74), 152
	ld	(xiz+1), 1
	call	BitMapOut_PrepareRender_CheckBit1
	sll	l, 3
	ld	w, (xsp+4)
	sub	w, 191
	add	w, l
	ld	(xiz+2), w
	ld	(xiz+3), 127
	ld	xwa, xiz
	calr	61314
	pop	xiz
	inc	2, xsp
	ret
	push	xiz
	ld	xiz, xwa
	ld	a, (xiz+2)
	cps	a, 0
	jr	z, 59
	ldb	w, 0
	extz	xwa
	call	Util_FindLowestSetBit
	lda	xbc, (xiz+2)
	ld	(xbc), l
	ldda8	a, 36496
	extz	wa
	sla	wa, 2
	lda_24	xde, 15572900
	.byte 0xe3
	reti
	or	xwa, xwa
	ldb	b, 234
	.byte 0xe2
	jr	z, 23
	extz	hl
	.byte 0xc3
	reti
	sla	xwa, 33
	ld	(xbc), a
	cp	a, 255
	jr	z, 9
	ld	(xiz+3), 255
	ld	xwa, xiz
	calr	61241
	pop	xiz
	ret

VoiceEntry_FindMasterVolume:
	ldada xde, 49209
	lds32 xbc, 0
	lds wa, 0
	jr VoiceEntry_CheckTerminator

VoiceEntry_CheckMatch:
	cp (xde), 0x98
	jr nz, VoiceEntryLoop_Continue
	cp (xde + 1), 0x1
	jr nz, VoiceEntryLoop_Continue
	cp (xde + 3), 0x7f
	jr nz, VoiceEntryLoop_Continue
	or xbc, xbc
	jr z, VoiceEntry_SaveMatch
	ld (xbc + 3), 0x0

VoiceEntry_SaveMatch:
	ld xbc, xde

VoiceEntryLoop_Continue:
	inc 1, wa
	inc 4, xde
	cp wa, 0xf
	ret nc

VoiceEntry_CheckTerminator:
	cp (xde), 0xff
	jr nz, VoiceEntry_CheckMatch
	ret

Audio_CopyStateFromROM:
	calr MidiCC_ResetState
	lda_24 xbc, 0xeda020
	ld xwa, xbc
	ldada xde, 36534
	lda xhl, (xbc + 12)

AudioCopy_TransferLoop:
	ld xiy, xwa
	ld xix, xde
	ldiw
	ldiw
	inc 4, xwa
	inc 4, xde
	cp xwa, xhl
	jr c, AudioCopy_TransferLoop
	ret

Audio_NullHandler_A:
	ret

Audio_NullHandler_B:
	ret

Audio_NullHandler_C:
	ret

Encoder_TimingAndOutput:
	incdi8 1, 36550
	ldda16 xwa, 36552
	cps wa, 0
	jr z, Encoder_CheckTimerDelta
	dec 1, wa
	stda16 36552, xwa

Encoder_CheckTimerDelta:
	ldda16 xwa, 1033
	subda16 xwa, 36546
	cp wa, 0x10
	jr c, Encoder_CheckBitAndProcess
	stdi8 36550, 0
	jr Encoder_ProcessUpdate

Encoder_CheckBitAndProcess:
	bitda 0, 36550
	jr nz, Encoder_IncrementAndDispatch

Encoder_ProcessUpdate:
	calr Audio_PeriodicUpdate

Encoder_IncrementAndDispatch:
	call Audio_IncrementUpdateCounter
	push_sr
	ei 6
	call MidiOut_SerializeAndSend
	pop_sr
	jp CompIface_ProcessInput

Audio_PeriodicUpdate:
	ldmm16 36546, 1033
	cpdi8 36150, 247
	ret z
	calr Audio_ProcessVoiceQueue
	calr MIDI_ProcessVoiceAssignment
	calr MIDI_ProcessControlChange
	ret

Audio_ProcessVoiceQueue:
	push xiz
	ldada xiz, 36530
	cpdi8 36548, 7
	jr nc, VoiceQueue_Done

VoiceQueue_ParseNextEntry:
	ld xwa, xiz
	calr MIDI_ParseThreeByteParams
	cp l, 0xff
	jr z, VoiceQueue_Done
	ld xwa, xiz
	calr Voice_SetupFromData
	cpdi8 36548, 7
	jr c, VoiceQueue_ParseNextEntry

VoiceQueue_Done:
	pop xiz
	ret

MIDI_ParseThreeByteParams:
	dec 2, xsp
	push xiz
	ld xiz, xwa
	ld (xsp + 4), 0xff
	call Seq_DataHandler
	cp hl, 0xffff
	jr z, MidiParseThreeByte_Done
	extz hl
	ld wa, hl
	calr MidiCC_LookupHandler
	ld (xiz), l
	call Seq_DataHandler
	cp hl, 0xffff
	jr z, MidiParseThreeByte_Done
	ld (xiz + 1), l
	call Seq_DataHandler
	cp hl, 0xffff
	jr z, MidiParseThreeByte_Done
	ld (xiz + 2), l
	ld (xsp + 4), 0x0

MidiParseThreeByte_Done:
	ld l, (xsp + 4)
	pop xiz
	inc 2, xsp
	ret

MIDI_ProcessVoiceAssignment:
	ld_sd8b A, 0x40
	and a, 0xc
	srl a, 2
	ld c, a
	ld xwa, 0x8eb6
	calr MIDI_WriteParamByte
	ld_sd8b A, 0x40
	and a, 0xf0
	srl a, 4
	cp a, 0xf
	jr nz, MIDI_ValidateParam
	stdi16 36552, 500
	jr MIDI_WriteSecondByte

MIDI_ValidateParam:
	cpdi16 36552, 0
	jr nz, MIDI_WriteSecondByte
	ldada xwa, 36538
	ld_sd8b C, 0x40
	and c, 0xf0
	srl c, 4
	calr MIDI_WriteParamByte

MIDI_WriteSecondByte:
	ldada xwa, 36542
	ldcf_dd8 6, 0x34
	scc8 c, c
	jr MIDI_WriteParamByte

MIDI_WriteParamByte:
	lda xsp, (xsp - 10)
	push xiz
	lda xhl, (xwa + 1)
	cp (xwa), 0x1d
	jr nz, MIDI_ChannelSetup_Skip
	ld e, c
	and e, 0xf
	cp e, 0xf
	jr nz, MIDI_ChannelSetup_Skip
	xor c, 0xf
	ld (xhl), c
	jr MIDI_ChannelSetup_Store

MIDI_ChannelSetup_Skip:
	ld (xhl), c

MIDI_ChannelSetup_Store:
	cpdi8 36548, 7
	jr nc, VoiceData_Setup_Ret
	lda xbc, (xwa + 1)
	ld (xsp + 8), xbc
	ld b, (xbc)
	cps b, 0
	jr nz, MIDI_ChannelSetup_Init
	cp (xwa + 3), 0x0
	jr z, VoiceData_Setup_Ret

MIDI_ChannelSetup_Init:
	ldada xiz, 36530
	ld (xsp + 4), xiz
	lda xiy, (xwa + 3)
	ld e, (xiy)
	ld (xsp + 12), e
	lda xix, (xwa + 2)
	ld l, (xix)
	ld d, l
	xor d, b
	and d, e
	and l, b
	or l, d
	ld (xiy), l
	ld xbc, (xsp + 8)
	ld c, (xbc)
	ld (xix), c
	cp l, e
	jr z, VoiceData_Setup_Ret
	ld a, (xwa)
	ld (xiz), a
	ld (xiz + 1), l
	ld a, (xsp + 12)
	xor a, l
	ld (xiz + 2), a
	ld xwa, (xsp + 4)
	calr Voice_SetupFromData

VoiceData_Setup_Ret:
	pop xiz
	lda xsp, (xsp + 10)
	ret

MIDI_ProcessControlChange:
	push xiz
	ldada xiz, 36530
	cpdi8 36548, 7
	jr nc, MidiCC_ProcessParam
	ldada xbc, 36624
	lda xwa, (xbc + 1)
	bitm 7, (xwa)
	jr z, MidiCC_ProcessParam
	resm 7, (xwa)
	ld (xiz), 0x1a
	ld a, (xbc)
	ld (xiz + 1), a
	ld (xiz + 2), 0x7f
	ld xwa, xiz
	calr Voice_SetupFromData

MidiCC_ProcessParam:
	cpdi8 36548, 7
	jr nc, MidiCC_SkipEntry
	ldada xbc, 36630
	lda xwa, (xbc + 1)
	bitm 7, (xwa)
	jr z, MidiCC_SkipEntry
	resm 7, (xwa)
	ld (xiz), 0x1b
	ld a, (xbc)
	ld (xiz + 1), a
	ld (xiz + 2), 0x7f
	ld xwa, xiz
	calr Voice_SetupFromData

MidiCC_SkipEntry:
	pop xiz
	ret

MidiCC_LookupHandler:
	ld c, a
	and c, 0x1f
	and a, 0xc0
	srl a, 1
	or a, c
	extz wa
	lda_24 xbc, 0xeda03c
	ld_srib3 L, 0x07, 0xe4, 0xe0
	ret

Voice_SetupFromData:
	push xiz
	ld xiz, xwa
	ldda8 c, 36548
	ld a, c
	extz wa
	muls wa, 0x3
	ldada xde, 36500
	exts xwa
	add xwa, xde
	cpdi8 36150, 251
	jrl nz, MidiCC_ReturnClean
	cp (xiz), 0x3
	jr nz, MidiCC_ValidateRange
	cp (xiz + 2), 0x1
	jr nz, MidiCC_ValidateRange
	ldda8 c, 36224
	res 0, c
	stda8 36224, c
	ld a, (xiz + 2)
	and a, 0x1
	and a, (xiz + 1)
	bit 0, a
	jr z, MidiCC_Return
	set 0, c
	stda8 36224, c
	jr MIDI_PopIzRet

MidiCC_ValidateRange:
	cp (xiz), 0x19
	jr nz, MidiCC_StoreAndDispatch
	ld a, (xiz + 2)
	and a, 0x1
	and a, (xiz + 1)
	bit 0, a
	jr z, MidiCC_Return
	ldw wa, 0x10
	call MIDI_SendSysExCmd
	jr MIDI_PopIzRet

MidiCC_StoreAndDispatch:
	cp (xiz), 0x15
	jr ugt, MidiCC_Finalize
	ld a, (xiz + 2)
	and a, (xiz + 1)
	jr z, MidiCC_CheckOverflow
	ldw wa, 0x10
	call MIDI_SendSysExCmd

MidiCC_CheckOverflow:
	ld xwa, xiz
	call EffectMode_MidiSetLEDs
	jr MIDI_PopIzRet

MidiCC_Finalize:
	inc 1, c
	stda8 36548, c
	ld xiy, xiz
	ld xix, xwa
	ldi85
	ldiw
	ldda8 a, 36548
	extz wa
	muls wa, 0x3
	stib_dri 0x07, 0xe8, 0xe0, 0xff

MidiCC_Return:
	jr MIDI_PopIzRet

MidiCC_ReturnClean:
	inc 1, c
	stda8 36548, c
	ld xiy, xiz
	ld xix, xwa
	ldi85
	ldiw
	ldda8 a, 36548
	extz wa
	muls wa, 0x3
	stib_dri 0x07, 0xe8, 0xe0, 0xff
	call SeqStep_TimerDispatchC

MIDI_PopIzRet:
	pop xiz
	ret

MidiCC_SyncForceResync:
	ldada xhl, 36500
	ret

MidiCC_ResetState:
	stdi8 36500, 255
	stdi8 36548, 0
	ret

	.include "midi/midi_encoder_routines.s"

MidiParam_ForceResync:
	stdi8 297, 131
	stdi8 296, 7
	lds wa, 0
	calr MidiChannel_GetParamByIndex
	ld a, l
	lds bc, 2
	call CPanel_EncoderDispatch
	ldda8 a, 36580
	cpl a
	stda8 36580, a
	lds wa, 0
	calr MidiChannel_GetParamByIndex
	ld a, l
	lds bc, 2
	call CPanel_EncoderDispatch
	ldada xwa, 36624
	ld (xwa), l
	setm 7, (xwa + 1)
	lds wa, 1
	calr MidiChannel_GetParamByIndex
	ld a, l
	lds bc, 5
	call CPanel_EncoderDispatch
	ldda8 a, 36596
	cpl a
	stda8 36596, a
	lds wa, 1
	calr MidiChannel_GetParamByIndex
	ld a, l
	lds bc, 5
	call CPanel_EncoderDispatch
	ldada xwa, 36630
	ld (xwa), l
	setm 7, (xwa + 1)
	ret

MidiChannel_GetParamByIndex:
	cps a, 3
	jr z, MidiChannel_GetParam3
	cps a, 2
	jr z, MidiChannel_GetParam2
	cps a, 1
	jr z, MidiChannel_GetParam1
	cps a, 0
	jr nz, MidiChannel_GetParamReturn
	ldada xbc, 288
	jr MidiChannel_GetParamReturn

MidiChannel_GetParam1:
	ldada xbc, 290
	jr MidiChannel_GetParamReturn

MidiChannel_GetParam2:
	ldada xbc, 292
	jr MidiChannel_GetParamReturn

MidiChannel_GetParam3:
	ldada xbc, 294

MidiChannel_GetParamReturn:
	ld l, (xbc + 1)
	ret

MidiParam_ProcessDeltas:
	ld xwa, 0x8f10
	calr MidiParam_ProcessChannel0
	ld xwa, 0x8f16
	jr MidiParam_ProcessChannel1

MidiParam_ProcessChannel0:
	dec 4, xsp
	push_werp 0xfa
	ld (xsp + 2), xwa
	lds wa, 0
	calr MidiChannel_GetParamByIndex
	ldfr_berp L, 0xfb
	ldto_berp A, 0xfb
	extz wa
	ldda8 c, 36604
	extz bc
	ld xde, 0x8f04
	calr MIDI_ComputeParamDelta
	ldada xwa, 36612
	bitm 3, (xwa)
	jr z, MidiParam_Ch0_Done
	resm 3, (xwa)
	ldto_berp A, 0xfb
	stda8 36604, a
	ldto_berp A, 0xfb
	extz wa
	lds bc, 2
	call CPanel_EncoderDispatch
	cp hl, 0xffff
	jr z, MidiParam_Ch0_Done
	ld xwa, (xsp + 2)
	ld (xwa), l
	setm 7, (xwa + 1)

MidiParam_Ch0_Done:
	pop_werp 0xfa
	inc 4, xsp
	ret

MidiParam_ProcessChannel1:
	dec 4, xsp
	push_werp 0xfa
	ld (xsp + 2), xwa
	lds wa, 1
	calr MidiChannel_GetParamByIndex
	ldfr_berp L, 0xfb
	ldto_berp A, 0xfb
	extz wa
	ldda8 c, 36606
	extz bc
	ld xde, 0x8f06
	calr MIDI_ComputeParamDelta
	ldada xwa, 36614
	bitm 3, (xwa)
	jr z, MidiParam_Ch1_Done
	resm 3, (xwa)
	ldto_berp A, 0xfb
	stda8 36606, a
	ldto_berp A, 0xfb
	extz wa
	lds bc, 5
	call CPanel_EncoderDispatch
	cp hl, 0xffff
	jr z, MidiParam_Ch1_Done
	ld xwa, (xsp + 2)
	ld (xwa), l
	setm 7, (xwa + 1)

MidiParam_Ch1_Done:
	pop_werp 0xfa
	inc 4, xsp
	ret

MIDI_ComputeParamDelta:
	dec 8, xsp
	ld (xsp), xde
	ld (xsp + 4), c
	ld (xsp + 6), a
	ld c, (xsp + 4)
	extz bc
	ld a, (xsp + 6)
	extz wa
	sub wa, bc
	pushw wa
	call Math_AbsInt16
	inc 2, xsp
	cps hl, 2
	jr le, MidiParam_DeltaTooSmall
	ld c, (xsp + 4)
	extz bc
	ld a, (xsp + 6)
	extz wa
	sub wa, bc
	pushw wa
	call Math_AbsInt16
	inc 2, xsp
	cps hl, 6
	jr le, MidiParam_DeltaMedium
	ld xwa, (xsp)
	ld a, (xwa)
	and a, 0x3
	xor a, 0x3
	jr z, MidiParam_DeltaConfirmed
	ld xbc, (xsp)
	ld a, (xbc)
	and a, 0x3
	inc 1, a
	and a, 0x3
	andmi8 (xbc), 0xfc
	or (xbc), a
	jr MidiParam_DeltaClearActive

MidiParam_DeltaMedium:
	ld xwa, (xsp)
	bitm 2, (xwa)
	jr z, MidiParam_DeltaStartDebounce

MidiParam_DeltaConfirmed:
	ld xwa, (xsp)
	andmi8 (xwa), 0xfc
	resm 2, (xwa)
	setm 3, (xwa)
	jr MidiParam_DeltaDone

MidiParam_DeltaStartDebounce:
	ld xwa, (xsp)
	setm 2, (xwa)
	jr MidiParam_DeltaDone

MidiParam_DeltaTooSmall:
	ld xwa, (xsp)
	andmi8 (xwa), 0xfc

MidiParam_DeltaClearActive:
	ld xwa, (xsp)
	resm 2, (xwa)

MidiParam_DeltaDone:
	inc 8, xsp
	ret

Audio_UpdateLEDsAndChannels:
	calr Audio_InitChannelTimers
	ordi16 36674, 2
	ret

MIDI_ProcessChangedChannels:
	cpdi8 36150, 251
	ret z
	calr Audio_CheckAndFlagChanges
	ldda16 xwa, 36668
	cpl wa
	andda16 xwa, 36666
	jr z, MidiChanged_ProcessGroup2
	ld xbc, 0xeda502
	calr DispatchBitmaskHandlers
	stdi16 36666, 0

MidiChanged_ProcessGroup2:
	ldda16 xwa, 36672
	cpl wa
	andda16 xwa, 36670
	jr z, MidiChanged_ProcessGroup3
	ld xbc, 0xeda538
	calr DispatchBitmaskHandlers
	stdi16 36670, 0

MidiChanged_ProcessGroup3:
	ldda16 xwa, 36676
	cpl wa
	andda16 xwa, 36674
	jr z, MidiChanged_ProcessGroup4
	ld xbc, 0xeda57a
	calr DispatchBitmaskHandlers
	stdi16 36674, 0

MidiChanged_ProcessGroup4:
	ldda16 xwa, 36680
	cpl wa
	andda16 xwa, 36678
	ret z
	ld xbc, 0xeda5c8
	calr DispatchBitmaskHandlers
	stdi16 36678, 0
	ret

MidiChannel_DispatchChanged:
	cpdi8 36150, 251
	ret z
	ldda16 xwa, 36668
	cps wa, 0
	jr z, MidiDispatch_CheckGroup2
	ld xbc, 0xeda5da
	calr DispatchBitmaskHandlers

MidiDispatch_CheckGroup2:
	ldda16 xwa, 36672
	cps wa, 0
	jr z, MidiDispatch_CheckGroup3
	ld xbc, 0xeda5e0
	calr DispatchBitmaskHandlers

MidiDispatch_CheckGroup3:
	ldda16 xwa, 36676
	cps wa, 0
	jr z, MidiDispatch_CheckGroup4
	ld xbc, 0xeda5f8
	calr DispatchBitmaskHandlers

MidiDispatch_CheckGroup4:
	ldda16 xwa, 36680
	cps wa, 0
	jr z, MidiDispatch_UpdateLEDs
	ld xbc, 0xeda610
	calr DispatchBitmaskHandlers

MidiDispatch_UpdateLEDs:
	jrl CtrlPanel_UpdateLEDState

Audio_InitChannelTimers:
	stdi8 36684, 5
	stdi8 36686, 5
	stdi8 36688, 5
	stdi8 36690, 5
	stdi8 36692, 5
	stdi8 36694, 5
	ret

Audio_IncrementUpdateCounter:
	incdi8 1, 36682
	ret

Audio_CheckAndFlagChanges:
	call GetDialEnableState
	cpda8 l, 36702
	jr z, AudioChange_CheckSelectionState
	ordi16 36674, 64
	stda8 36702, l

AudioChange_CheckSelectionState:
	call CtrlPanel_GetSelectionState
	cpda8 l, 36704
	ret z
	cps l, 2
	jr nz, AudioChange_UpdatePreviousSelect
	ordi16 36676, 4

AudioChange_UpdatePreviousSelect:
	cpdi8 36704, 2
	jr nz, AudioChange_SetChannelFlag
	anddi16 36676, 65531

AudioChange_SetChannelFlag:
	ordi16 36674, 4
	stda8 36704, l
	ret

DispatchBitmaskHandlers:
	dec 2, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), wa
	cpw (xiz), 0xffff
	jr z, BitmaskDispatch_Return

; Bitmask dispatch loop handler
BitmaskDispatch_LoopHandler:
	ld wa, (xsp + 4)
	and wa, (xiz)
	jr z, BitmaskDispatch_NextEntry
	ld xhl, (xiz + 2)
	call (xhl)

BitmaskDispatch_NextEntry:
	inc 6, xiz
	cpw (xiz), 0xffff
	jr nz, BitmaskDispatch_LoopHandler

BitmaskDispatch_Return:
	pop xiz
	inc 2, xsp
	ret


; This routine seems to set the LEDs of the control panel
; I'm not sure yet if this is initialization, or if it
; also serves to update the LEDs later on.
CtrlPanel_UpdateLEDState:
	dec 8, xsp
	push_werp 0xfa
	ldada xwa, 36632
	ld (xsp + 2), xwa
	ldada xwa, 36648
	ld (xsp + 6), xwa
	cpdi8 36150, 247
	jr z, LEDUpdate_Cleanup
	ldi_berp 0xfb, 0

LEDUpdate_ProcessChannel:
	ldto_berp A, 0xfb
	extz wa
	ld xbc, (xsp + 2)
	ld_srib3 C, 0x07, 0xe4, 0xe0
	ldfr_berp C, 0xfa
	ld xbc, (xsp + 6)
	ld_srib3 C, 0x07, 0xe4, 0xe0
	cp_berp C, 0xfa
	jr z, LEDUpdate_NextChannel
	ldto_berp C, 0xfa
	extz bc
	calr Set_LEDs
	ldto_berp E, 0xfb
	extz de
	ld xwa, (xsp + 6)
	ldto_berp C, 0xfa
	lda_dri3 XHL, 0x07, 0xe0, 0xe8

LEDUpdate_NextChannel:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x0f
	jr c, LEDUpdate_ProcessChannel

LEDUpdate_Cleanup:
	pop_werp 0xfa
	inc 8, xsp
	ret


Set_LEDs:
	; Input: WA: row of LEDs
	;         C: LED pattern
	ld e, a
	cp e, 0xf
	ret ugt
	ldada xwa, 36664
	extz de
	lda_24 xhl, 0xeda616
	ld_srib3 E, 0x07, 0xec, 0xe8
	ld (xwa), e
	ld (xwa + 1), c
	calr LED_WriteToPanel
	ret

LED_WriteToPanel:
	push xiz
	ld xiz, xwa
	ld a, (xiz)
	extz wa
	pushw wa
	call Seq_TimerEventLoop
	inc 2, xsp
	cp hl, 0xffff
	jr nz, LED_WriteSecondByte
	push xde
	push xhl
	push xix
	push xiz
	call CPanel_Poll
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, xiz
	jr LED_WriteThirdByte

LED_WriteSecondByte:
	ld a, (xiz + 1)
	extz wa
	pushw wa
	call Seq_TimerEventLoop
	inc 2, xsp
	cp hl, 0xffff
	jr nz, LED_WriteDone
	push xde
	push xhl
	push xix
	push xiz
	call CPanel_Poll
	pop xiz
	pop xix
	pop xhl
	pop xde
	lda xwa, (xiz + 1)

LED_WriteThirdByte:
	ld a, (xwa)
	extz wa
	pushw wa
	call Seq_TimerEventLoop
	inc 2, xsp

LED_WriteDone:
	pop xiz
	ret


SndParam_SetResBit0_Via028100:
	; --- Routine 1: call FCD437(0x028100), set/res bit 0 at (xwa) (29 bytes) ---
	push xiz
	ldada	xiz, 36632
	ld xwa, 0x00028100
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+4)
	cps	hl, 1
	jr nz, SndParam028100_ResBit0
	setm	0, (xwa)
	jr t, SndParam028100_Done
SndParam028100_ResBit0:
	.byte 0xb0, 0xb0				; res 0, (xwa)  [not in LLVM]
SndParam028100_Done:
	pop xiz
	ret
SndParam_SetResBit1_ViaRegs0100_0101:
	; --- Routine 2: 2x FCD437, set/res bit 1 at (xiz+4) (41 bytes) ---
	push xiz
	ldada	xiz, 36632
	ld xwa, 0x00028100
	call SndParam_LookupReadOnly
	cps	hl, 2
	jr z, SndParam028101_SetBit1
	ld xwa, 0x00028101
	call SndParam_LookupReadOnly
	cps	hl, 1
	jr nz, SndParam028101_ResBit1
SndParam028101_SetBit1:
	setm	1, (xiz+4)
	jr t, SndParam028101_Done
SndParam028101_ResBit1:
	.byte 0xbe, 0x04, 0xb1				; res 1, (xiz+4)  [not in LLVM]
SndParam028101_Done:
	pop xiz
	ret
SndParam_SetResBit2_ViaRegs0101_0102:
	; --- Routine 3: 2x FCD437, set/res bit 2 at (xiz+4) (41 bytes) ---
	push xiz
	ldada	xiz, 36632
	ld xwa, 0x00028101
	call SndParam_LookupReadOnly
	cps	hl, 2
	jr z, SndParam028102_SetBit2
	ld xwa, 0x00028102
	call SndParam_LookupReadOnly
	cps	hl, 1
	jr nz, SndParam028102_ResBit2
SndParam028102_SetBit2:
	setm	2, (xiz+4)
	jr t, SndParam028102_Done
SndParam028102_ResBit2:
	.byte 0xbe, 0x04, 0xb2				; res 2, (xiz+4)  [not in LLVM]
SndParam028102_Done:
	pop xiz
	ret


SndParam_SetResBit3_ViaRegs0101_0102:
	; --- Routine 1: 2x FCD437, set/res bit 3 at (xiz+4) (41 bytes) ---
	push xiz
	ldada	xiz, 36632
	ld xwa, 0x00028101
	call SndParam_LookupReadOnly
	cps	hl, 3
	jr z, SndParam028102_SetBit3
	ld xwa, 0x00028102
	call SndParam_LookupReadOnly
	cps	hl, 2
	jr nz, SndParam028102_ResBit3
SndParam028102_SetBit3:
	setm	3, (xiz+4)
	jr t, SndParam028102_Done2
SndParam028102_ResBit3:
	.byte 0xbe, 0x04, 0xb3				; res 3, (xiz+4)  [not in LLVM]
SndParam028102_Done2:
	pop xiz
	ret
SndParam_SetResBit3_Via4002:
	; --- Routine 2: FCD437(0x4002), set/res bit 3 at (xwa) via xiz+6 (29 bytes) ---
	push xiz
	ldada	xiz, 36632
	ld xwa, 0x00004002
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+6)
	cps	hl, 0
	jr z, SndParam4002_ResBit3
	setm	3, (xwa)
	jr t, SndParam4002_Done
SndParam4002_ResBit3:
	.byte 0xb0, 0xb3				; res 3, (xwa)  [not in LLVM]
SndParam4002_Done:
	pop xiz
	ret
SndParam_SetResBit4_Via4004:
	; --- Routine 3: FCD437(0x4004), set/res bit 4 at (xwa) via xiz+6 (29 bytes) ---
	push xiz
	ldada	xiz, 36632
	ld xwa, 0x00004004
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+6)
	cps	hl, 0
	jr z, SndParam4004_ResBit4
	setm	4, (xwa)
	jr t, SndParam4004_Done
SndParam4004_ResBit4:
	.byte 0xb0, 0xb4				; res 4, (xwa)  [not in LLVM]
SndParam4004_Done:
	pop xiz
	ret


SndParam_TableLookup_Via4100:
	; --- Routine 1: FCD437(0x4100), table lookup at 0xeda626, nibble merge (39 bytes) ---
	push xiz
	ldada	xiz, 36632
	ld xwa, 0x00004100
	call SndParam_LookupReadOnly
	lda_24 xwa, 0xeda626
	ld_rrb	a, xwa, hl
	and a, 0x07
	sla	a, 4
	andmi8	(xiz+10), 143
	or	(xiz+10), a
	pop xiz
	ret
SndParam_SetResBit1_ViaPartCC5E:
	; --- Routine 2: F9945E+FCD4F7(0x5e), set/res bit 1 at (xwa) via xiz+6 (37 bytes) ---
	push xiz
	ldada	xiz, 36632
	call GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	ldw bc, 0x005e
	call SndParam_LookupViaEncode
	lda	xwa, (xiz+6)
	cp hl, 0x007f
	jr nz, SndParamCC5E_ResBit1
	setm	1, (xwa)
	jr t, SndParamCC5E_Done
SndParamCC5E_ResBit1:
	.byte 0xb0, 0xb1				; res 1, (xwa)  [not in LLVM]
SndParamCC5E_Done:
	pop xiz
	ret


SndParam_SetResBit2_ViaPartCC5D:
	; --- Routine 1: 2x F9945E+FCD4F7(0x5d), set/res bit 2 at (xiz+6) (55 bytes) ---
	push xiz
	ldada	xiz, 36632
	call GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	ldw bc, 0x005d
	call SndParam_LookupViaEncode
	cps	hl, 0
	jr z, SndParamCC5D_ResBit2
	call GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	ldw bc, 0x005d
	call SndParam_LookupViaEncode
	cp hl, 0xffff
	jr nz, SndParamCC5D_SetBit2
SndParamCC5D_ResBit2:
	resm	2, (xiz+6)
	jr t, SndParamCC5D_Done
SndParamCC5D_SetBit2:
	.byte 0xbe, 0x06, 0xba				; set 2, (xiz+6)  [not in LLVM]
SndParamCC5D_Done:
	pop xiz
	ret
SndParam_SetResBit0_ViaPartCC40:
	; --- Routine 2: F9945E+FCD4F7(0x40), cp 0x7f, set/res bit 0 at (xwa) (37 bytes) ---
	push xiz
	ldada	xiz, 36632
	call GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	ldw bc, 0x0040
	call SndParam_LookupViaEncode
	lda	xwa, (xiz+6)
	cp hl, 0x007f
	jr nz, SndParamCC40_ResBit0
	setm	0, (xwa)
	jr t, SndParamCC40_Done
SndParamCC40_ResBit0:
	.byte 0xb0, 0xb0				; res 0, (xwa)  [not in LLVM]
SndParamCC40_Done:
	pop xiz
	ret
SndParam_GuardedNibbleSet_ViaReg0103:
	; --- Routine 3: complex bit checks, and (xiz+0x0e), set 0 in A (59 bytes) ---
	push xiz
	ldada	xiz, 36632
	bitda	2, 1054
	jr nz, MidiCtrl_PopIzRet
	ld xwa, 0x00028103
	call SndParam_LookupReadOnly
	cps	hl, 0
	jr nz, MidiCtrl_PopIzRet
	andmi8	(xiz+14), 240
	bitda	2, 1057
	jr z, MidiCtrl_PopIzRet
	lds32	xwa, 1
	call SndParam_LookupReadOnly
	cps	hl, 1
	jr nz, MidiCtrl_PopIzRet
	lda	xbc, (xiz+14)
	ld a, (xbc)
	and a, 0xf0
	set 0, a
	ld (xbc), a
MidiCtrl_PopIzRet:
	pop xiz
	ret
SndParam_SetResBit0_Via028103:
	; --- Routine 4: FCD437(0x028103), set/res bit 0 at (xwa) via xiz+0x0d (29 bytes) ---
	push xiz
	ldada	xiz, 36632
	ld xwa, 0x00028103
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+13)
	cps	hl, 1
	jr nz, SndParam028103_ResBit0
	setm	0, (xwa)
	jr t, SndParam028103_Done
SndParam028103_ResBit0:
	.byte 0xb0, 0xb0				; res 0, (xwa)  [not in LLVM]
SndParam028103_Done:
	pop xiz
	ret
SndParam_SetResBit5_Via028080:
	; --- Routine 5: FCD437(0x028080), set/res bit 5 at (xwa) via xiz+3 (29 bytes) ---
	push xiz
	ldada	xiz, 36632
	ld xwa, 0x00028080
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+3)
	cps	hl, 0
	jr nz, SndParam028080_SetBit5
	resm	5, (xwa)
	jr t, SndParam028080_Done
SndParam028080_SetBit5:
	.byte 0xb0, 0xbd				; set 5, (xwa)  [not in LLVM]
SndParam028080_Done:
	pop xiz
	ret


SndParam_VoiceEntryLookup_ViaReg8000:
	; --- Routine 1: stack frame, 3x FCD437 lookup, nibble merge (91 bytes) ---
	dec 6, xsp
	push xiz
	ldada	xiz, 36632
	ld (xsp+6), 0x48
	ld xwa, 0x00028000
	call SndParam_LookupReadOnly
	ld (xsp+7), l
	ld xwa, 0x00028001
	call SndParam_LookupReadOnly
	lda	xwa, (xsp+4)
	ld (xwa+4), l
	call SndParam_ResolveVoiceEntry
	lda	xwa, (xsp+4)
	cp (xwa), 0x0e
	jr nc, SndParam028000_GetBankBit
	ld xwa, 0x00028002
	call SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	jr t, SndParam028000_LookupAndMerge
SndParam028000_GetBankBit:
	ld a, (xwa+1)
	and a, 0x03
	extz wa
SndParam028000_LookupAndMerge:
	call CtrlPanel_LookupIndicatorEntry
	and l, 0x0f
	andmi8	(xiz+3), 240
	or (xiz+3), l
	pop xiz
	inc 6, xsp
	ret
SndParam_SetResBit7_Via4200:
	; --- Routine 2: FCD437(0x4200), set/res bit 7 at (xwa) via xiz+0x0a (29 bytes) ---
	push xiz
	ldada	xiz, 36632
	ld xwa, 0x00004200
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+10)
	cps	hl, 1
	jr nz, SndParam4200_ResBit7
	setm	7, (xwa)
	jr t, SndParam4200_Done
SndParam4200_ResBit7:
	.byte 0xb0, 0xb7				; res 7, (xwa)  [not in LLVM]
SndParam4200_Done:
	pop xiz
	ret
SndParam_MaskShiftMerge_8F58:
	; --- Routine 3: read (0x8f58), mask+shift, merge into (0x8f1c) (20 bytes) ---
	ldda8	a, 36696
	and a, 0x07
	sla	a, 4
	anddi8	36636, 143
	orddm8	36636, a
	ret
SndParam_DecrLookup_Via0300:
	; --- Routine 4: FCD437(0x300), decrement+mask+lookup via FC7C23 (40 bytes) ---
	push xiz
	ldada	xiz, 36632
	ld xwa, 0x00000300
	call SndParam_LookupReadOnly
	cps	hl, 0
	jr nz, SndParam0300_DecrAndMask
	ldb l, 0x00
	jr t, SndParam0300_StoreLookup
SndParam0300_DecrAndMask:
	dec 1, l
	and l, 0x07
	extz	hl
	ld	wa, hl
	call CtrlPanel_LookupIndicatorEntry
SndParam0300_StoreLookup:
	ld (xiz+9), l
	pop xiz
	ret


SndParam_SetResBit4_Via0400:
	; --- Routine 1: call FCD437, set/res bit 4 based on HL (29 bytes) ---
	push xiz
	ldada	xiz, 36632
	ld xwa, 0x00000400
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+3)
	cps	hl, 1
	jr nz, SndParam0400_ResBit4
	setm	4, (xwa)
	jr t, SndParam0400_Done
SndParam0400_ResBit4:
	.byte 0xb0, 0xb4				; res 4, (xwa)  [not in LLVM]
SndParam0400_Done:
	pop xiz
	ret
SndParam_SetResBit7_ViaSelection:
	; --- Routine 2: call F99439, 3-way cp HL, set/res bit 7 (29 bytes) ---
	push xiz
	ldada	xiz, 36632
	call CtrlPanel_GetSelectionState
	cps	hl, 2
	jr z, CtrlPanel_SetResBit7_Ret
	cps	hl, 1
	jr z, SndParamSelect_SetBit7
	cps	hl, 0
	jr nz, CtrlPanel_SetResBit7_Ret
	resm	7, (xiz)
	jr t, CtrlPanel_SetResBit7_Ret
SndParamSelect_SetBit7:
	.byte 0xb6, 0xbf				; set 7, (xiz)  [not in LLVM]
CtrlPanel_SetResBit7_Ret:
	pop xiz
	ret
SndParam_SetResBit7_ViaF9A541:
	; --- Routine 3: call F9A541, set/res bit 7 based on HL (24 bytes) ---
	push xiz
	ldada	xiz, 36632
	call GetDialEnableState
	lda	xwa, (xiz+4)
	cps	hl, 0
	jr z, SndParamF9A541_ResBit7
	setm	7, (xwa)
	jr t, SndParamF9A541_Done
SndParamF9A541_ResBit7:
	.byte 0xb0, 0xb7				; res 7, (xwa)  [not in LLVM]
SndParamF9A541_Done:
	pop xiz
	ret


ExtData_VoiceParam_DispatchBytecode:
	push	xiz
	ldada	xiz, 36632
	lda	xbc, (xiz+2)
	.byte 0xb1, 0xb7, 0xb6, 0xb1, 0xb6, 0xb2, 0xb6, 0xb4
	lda	xhl, (xiz+10)
	.byte 0xb3, 0xb3
	lda	xde, (xiz+6)
	.byte 0xb2, 0xb6, 0xb2, 0xb7
	lda	xiy, (xiz+11)
	.byte 0xb5, 0xb0, 0xb5, 0xb1, 0xb5, 0xb2, 0xb5, 0xb3
	ldda8	a, 36148
	extz	wa
	dec	2, wa
	cps	wa, 0
	jr	lt, 88
	cp	wa, 16
	jr	gt, 82
	add	wa, wa
	lda_24	xix, 15574572
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	w, 242
	jr	117
	swi	4
	ldw	ix, 2035
	.byte 0xf0, 0xe0
	sbc	bc, wa
	.byte 0xbf
	jr	56
	ldb	a, 1
	jr	49
	ldb	a, 2
	jr	45
	.byte 0xb2, 0xbf
	jr	44
	ld	xwa, xde
	.byte 0xb2, 0xbf, 0xc1
	swi	4
	ldb	h, 63
	.byte 0x01
	jr	nz, 33
	.byte 0xb0, 0xbe
	jr	29
	.byte 0xb2, 0xbe
	jr	25
	.byte 0xb5, 0xb8
	jr	21
	.byte 0xb5, 0xba
	jr	17
	.byte 0xb5, 0xb9
	jr	13
	.byte 0xb5, 0xbb
	jr	9
	.byte 0xb3, 0xbb
	jr	5
	ldb	a, 4
	scf
	.byte 0xb6
	pushw	ix
	pop	xiz
	ret
	ldada	xwa, 36632
	.byte 0xc1, 0x90
	ldw	hl, 63
	jr	z, 3
	.byte 0xb0, 0xbb
	ret
	.byte 0xb0, 0xb3
	ret
	ldada	xwa, 36638
	.byte 0xb0, 0xb5, 0xf1, 0xa5
	pushw	wa
	sbc	w, w
	.byte 0xf6
	ldda8	c, 36148
	cp	c, 13
	ret	z
	cp	c, 12
	ret	z
	cp	c, 11
	ret	z
	cp	c, 9
	ret	z
	cp	c, 8
	ret	z
	.byte 0xb0, 0xbd
	ret
	lda	xsp, (xsp-10)
	push	xiz
	ldada	xwa, 36632
	ld	(xsp+4), xwa
	ld	(xwa+7), 0
	ld	xwa, (xsp+4)
	ld	(xwa+8), 0
	.byte 0x88
	incf
	push	xix
	swi	4
	call	GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	lds	bc, 0
	call	SndParam_LookupViaEncode
	ld	(xsp+11), l
	call	GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	ldw	bc, 32
	call	SndParam_LookupViaEncode
	ld	(xsp+12), l
	call	GetCurrentPartSelect
	lda	xwa, (xsp+8)
	ld	(xwa+2), l
	call	SndParam_ResolveVoiceEntry
	lda	xwa, (xsp+8)
	.byte 0x80
	push	xsp
	reti
	jr	ugt, 8
	ld	a, (xwa)
	extz	wa
	lds32	xiz, 7
	jr	16
	.byte 0x80
	push	xsp
	retd	6251
	ld	a, (xwa)
	dec	8, a
	extz	wa
	ld	xiz, 8
	call	CtrlPanel_LookupIndicatorEntry
	ld	xwa, (xsp+4)
	add	xwa, xiz
	ld	(xwa), l
	jr	38
	.byte 0x80
	push	xsp
	scf
	jr	ugt, 26
	ld	a, (xwa)
	sub	a, 16
	extz	wa
	call	CtrlPanel_LookupIndicatorEntry
	ld	xwa, (xsp+4)
	and	l, 3
	.byte 0x88
	incf
	push	xix
	swi	4
	or	(xwa+12), l
	jr	7
	ld	xwa, (xsp+4)
	ld	(xwa+7), 1
	pop	xiz
	lda	xsp, (xsp+10)
	ret
	dec	6, xsp
	push	xiz
	ldada	xiz, 36632
	.byte 0xb6, 0xb0
	ld	(xiz+1), 0
	.byte 0x8e
	push_sr
	push	xix
	.byte 0x80
	ld	xwa, 163840
	call	SndParam_LookupReadOnly
	ld	(xsp+7), l
	ld	xwa, 163841
	call	SndParam_LookupReadOnly
	lda	xwa, (xsp+4)
	ld	(xwa+4), l
	ld	(xwa+2), 72
	call	SndParam_ResolveVoiceEntry
	lda	xwa, (xsp+4)
	.byte 0x80
	push	xsp
	.byte 0x06
	jr	ugt, 20
	ld	a, (xwa)
	extz	wa
	call	CtrlPanel_LookupIndicatorEntry
	res	7, l
	.byte 0x8e
	push_sr
	push	xix
	add	(xwa), h
	push_sr
	dec	8, xsp
	pushw	de
	.byte 0x80
	push	xsp
	ret
	jr	ugt, 15
	ld	a, (xwa)
	dec	7, a
	extz	wa
	call	CtrlPanel_LookupIndicatorEntry
	ld	(xiz+1), l
	jr	22
	.byte 0x80
	push	xsp
	retd	1134
	.byte 0xb6, 0xb8
	jr	13
	lda	xbc, (xiz+2)
	ld	a, (xbc)
	and	a, 128
	set	0, a
	ld	(xbc), a
	pop	xiz
	inc	6, xsp
	ret
	push	xiz
	ldada	xiz, 36632
	call	GetCurrentPartSelect
	lda	xbc, (xiz+10)
	ld	a, (xbc)
	cps	l, 2
	jr	z, 28
	cps	l, 1
	jr	z, 14
	cps	l, 0
	jr	nz, 30
	and	a, 248
	set	2, a
	ld	(xbc), a
	jr	23
	and	a, 248
	set	1, a
	ld	(xbc), a
	jr	13
	and	a, 248
	set	0, a
	ld	(xbc), a
	jr	3
	.byte 0x81
	push	xix
	swi	0
	pop	xiz
	ret
	push	xiz
	ldada	xiz, 36632
	ld	xwa, 16576
	call	SndParam_LookupReadOnly
	cps	hl, 1
	jr	nz, 4
	.byte 0xb6, 0xbd
	jr	2
	.byte 0xb6, 0xb5
	pop	xiz
	ret
CtrlPanel_SetResBit6_ViaLookup:
	; --- Sub 1: set/res bit 6 of (XIZ) via FCD437 lookup (26 bytes) ---
	push xiz
	ldada	xiz, 36632
	ld xwa, 0x000040c1
	call SndParam_LookupReadOnly
	cps	hl, 1
	jr nz, CtrlPanel_ResBit6
	setm	6, (xiz)
	jr t, CtrlPanel_Bit6Done
CtrlPanel_ResBit6:
	.byte 0xb6, 0xb6				; res 6, (xiz)  [not in LLVM]
CtrlPanel_Bit6Done:
	pop xiz
	ret
CtrlPanel_MultiWayBitManip_ViaE0:
	; --- Sub 2: multi-way HL compare, and/set bits at (XBC+0x0d) (74 bytes) ---
	push xiz
	ldada	xiz, 36632
	ld xwa, 0x000040e0
	call SndParam_LookupReadOnly
	lda	xbc, (xiz+13)
	ld a, (xbc)
	cp hl, 0x0058
	jr z, CtrlPanel_SetBit2
	cp hl, 0x004c
	jr z, CtrlPanel_SetBit2
	cp hl, 0x0040
	jr z, CtrlPanel_ClearBits1_2
	cp hl, 0x0034
	jr z, CtrlPanel_SetBit1
	cp hl, 0x0028
	jr nz, CtrlPanel_BitManip_Ret
CtrlPanel_SetBit1:
	and a, 0xf9
	set 1, a
	ld (xbc), a
	jr t, CtrlPanel_BitManip_Ret
CtrlPanel_ClearBits1_2:
	andmi8	(xbc), 249
	jr t, CtrlPanel_BitManip_Ret
CtrlPanel_SetBit2:
	and a, 0xf9
	set 2, a
	ld (xbc), a
CtrlPanel_BitManip_Ret:
	pop xiz
	ret
CtrlPanel_SyncBit0_From8F5C:
	; --- Sub 3: set/res bit 0 at (0x8f1d) based on bit 0 of (0x8f5c) (16 bytes) ---
	ldada	xwa, 36637
	bitda	0, 36700
	jr z, CtrlPanel_ResBit0_8F5C
	setm	0, (xwa)
	ret
CtrlPanel_ResBit0_8F5C:
	resm	0, (xwa)
	ret
CtrlPanel_SetBit3_OnStyleD0D3:
	; --- Sub 4: conditionally set bit 3 at (0x8f25) based on (0x8d38) (33 bytes) ---
	ldada	xwa, 36645
	resm	3, (xwa)
	ldda8	c, 36152
	cp c, 0xd3
	jr z, CtrlPanel_SetBit3
	cp c, 0xd2
	jr z, CtrlPanel_SetBit3
	cp c, 0xd1
	jr z, CtrlPanel_SetBit3
	cp c, 0xd0
	ret nz
CtrlPanel_SetBit3:
	setm	3, (xwa)
	ret
CtrlPanel_SetResBit0_ViaLookup4:
	; --- Sub 5: set/res bit 0 at (XIZ+4) via FC7C23 + (0x8f54) lookup (34 bytes) ---
	push xiz
	ldada	xiz, 36632
	ldda8	a, 36692
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	andda8	l, 36682
	lda	xwa, (xiz+4)
	cps	l, 0
	jr z, CtrlPanelLookup4_ResBit0
	setm	0, (xwa)
	jr t, CtrlPanelLookup4_Done
CtrlPanelLookup4_ResBit0:
	.byte 0xb0, 0xb0				; res 0, (xwa)  [not in LLVM]
CtrlPanelLookup4_Done:
	pop xiz
	ret
CtrlPanel_SetResBit1_ViaLookup56:
	; --- Sub 6: set/res bit 1 at (XIZ+4) via FC7C23 + (0x8f56) lookup (34 bytes) ---
	push xiz
	ldada	xiz, 36632
	ldda8	a, 36694
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	andda8	l, 36682
	lda	xwa, (xiz+4)
	cps	l, 0
	jr z, CtrlPanelLookup56_ResBit1
	setm	1, (xwa)
	jr t, CtrlPanelLookup56_Done
CtrlPanelLookup56_ResBit1:
	.byte 0xb0, 0xb1				; res 1, (xwa)  [not in LLVM]
CtrlPanelLookup56_Done:
	pop xiz
	ret
CtrlPanel_SetResBit2_ViaLookup50:
	; --- Sub 7: set/res bit 2 at (XIZ+4) via FC7C23 + (0x8f50) lookup (34 bytes) ---
	push xiz
	ldada	xiz, 36632
	ldda8	a, 36688
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	andda8	l, 36682
	lda	xwa, (xiz+4)
	cps	l, 0
	jr z, CtrlPanelLookup50_ResBit2
	setm	2, (xwa)
	jr t, CtrlPanelLookup50_Done
CtrlPanelLookup50_ResBit2:
	.byte 0xb0, 0xb2				; res 2, (xwa)  [not in LLVM]
CtrlPanelLookup50_Done:
	pop xiz
	ret
CtrlPanel_SetResBit3_ViaLookup52:
	; --- Sub 8: set/res bit 3 at (XIZ+4) via FC7C23 + (0x8f52) lookup (34 bytes) ---
	push xiz
	ldada	xiz, 36632
	ldda8	a, 36690
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	andda8	l, 36682
	lda	xwa, (xiz+4)
	cps	l, 0
	jr z, CtrlPanelLookup52_ResBit3
	setm	3, (xwa)
	jr t, CtrlPanelLookup52_Done
CtrlPanelLookup52_ResBit3:
	.byte 0xb0, 0xb3				; res 3, (xwa)  [not in LLVM]
CtrlPanelLookup52_Done:
	pop xiz
	ret
CtrlPanel_GuardedNibbleSet_8F4E:
	; --- Sub 9: guarded nibble set/res at (XIZ+0x0e) via (0x8f4e) lookup (76 bytes) ---
	push xiz
	ldada	xiz, 36632
	bitda	2, 1054
	jr nz, CtrlPanel_BitOp_Cleanup
	ld xwa, 0x00028103
	call SndParam_LookupReadOnly
	cps	hl, 0
	jr z, CtrlPanelGuard_PassedCheck
	cpdi8	36148, 19
	jr z, CtrlPanelGuard_PassedCheck
	cpdi8	32523, 0
	jr z, CtrlPanel_BitOp_Cleanup
CtrlPanelGuard_PassedCheck:
	ldda8	a, 36686
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	andda8	l, 36682
	lda	xwa, (xiz+14)
	cps	l, 0
	jr z, CtrlPanelGuard_ClearNibble
	ld c, (xwa)
	and c, 0xf0
	set 0, c
	ld (xwa), c
	jr t, CtrlPanel_BitOp_Cleanup
CtrlPanelGuard_ClearNibble:
	.byte 0x80
	push	xix
	.byte 0xf0
CtrlPanel_BitOp_Cleanup:
	pop xiz
	ret
CtrlPanel_SetResBit0_ViaLookup4C:
	; --- Sub 10: set/res bit 0 at (XIZ+0x0d) via FC7C23 + (0x8f4c) lookup (34 bytes) ---
	push xiz
	ldada	xiz, 36632
	ldda8	a, 36684
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	andda8	l, 36682
	lda	xwa, (xiz+13)
	cps	l, 0
	jr z, CtrlPanelLookup4C_ResBit0
	setm	0, (xwa)
	jr t, CtrlPanelLookup4C_Done
CtrlPanelLookup4C_ResBit0:
	.byte 0xb0, 0xb0				; res 0, (xwa)  [not in LLVM]
CtrlPanelLookup4C_Done:
	pop xiz
	ret
CtrlPanel_SetResBit7_ViaLookup4C:
	; --- Sub 11: set/res bit 7 of (XIZ) via FC7C23 + (0x8f4c) lookup (29 bytes) ---
	push xiz
	ldada	xiz, 36632
	ldda8	a, 36684
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	andda8	l, 36682
	jr z, CtrlPanelBit7_Res
	setm	7, (xiz)
	jr t, CtrlPanelBit7_Done
CtrlPanelBit7_Res:
	.byte 0xb6, 0xb7				; res 7, (xiz)  [not in LLVM]
CtrlPanelBit7_Done:
	pop xiz
	ret
CtrlPanel_SetResBit5_ViaLookup4C:
	; --- Sub 12: set/res bit 5 of (XIZ) via FC7C23 + (0x8f4c) lookup (29 bytes) ---
	push xiz
	ldada	xiz, 36632
	ldda8	a, 36684
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	andda8	l, 36682
	jr z, CtrlPanelBit5_Res
	setm	5, (xiz)
	jr t, CtrlPanelBit5_Done
CtrlPanelBit5_Res:
	.byte 0xb6, 0xb5				; res 5, (xiz)  [not in LLVM]
CtrlPanelBit5_Done:
	pop xiz
	ret
CtrlPanel_SetResBit6_ViaLookup4C:
	; --- Sub 13: set/res bit 6 of (XIZ) via FC7C23 + (0x8f4c) lookup (29 bytes) ---
	push xiz
	ldada	xiz, 36632
	ldda8	a, 36684
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	andda8	l, 36682
	jr z, CtrlPanelBit6_Res
	setm	6, (xiz)
	jr t, CtrlPanelBit6_Done
CtrlPanelBit6_Res:
	.byte 0xb6, 0xb6				; res 6, (xiz)  [not in LLVM]
CtrlPanelBit6_Done:
	pop xiz
	ret


; ============================================================================
; CtrlPanel_SetIndicatorBit - Set a control panel LED indicator bit
; ============================================================================
; Input:  A = key code (upper nibble=group, lower nibble=bit index)
; Output: ORs bitmask into panel LED register (36666/36670/36674/36678)
; Looks up bitmask from table at 0xeda66c.
; ============================================================================
CtrlPanel_SetIndicatorBit:
	push_werp 0xfa
	ld c, a
	and c, 0xf0
	ldfr_berp C, 0xfb
	and a, 0xf
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	cp_erpb 0xfb, 0x60
	jr z, CtrlPanel_SetIndicator_Group4
	cp_erpb 0xfb, 0x40
	jr z, CtrlPanel_SetIndicator_Group3
	cp_erpb 0xfb, 0x20
	jr z, CtrlPanel_SetIndicator_Group2
	cpi_berp 0xfb, 0
	jr nz, CtrlPanel_PopRetFA
	orddm16 36666, xhl
	jr CtrlPanel_PopRetFA

CtrlPanel_SetIndicator_Group2:
	orddm16 36670, xhl
	jr CtrlPanel_PopRetFA

CtrlPanel_SetIndicator_Group3:
	orddm16 36674, xhl
	jr CtrlPanel_PopRetFA

CtrlPanel_SetIndicator_Group4:
	orddm16 36678, xhl

CtrlPanel_PopRetFA:
	pop_werp 0xfa
	ret

CtrlPanel_IndicatorDispatch:
	push_werp 0xfa
	ld c, a
	and c, 0xf0
	ldfr_berp C, 0xfb
	and a, 0xf
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	cp_erpb 0xfb, 0x60
	jr z, CtrlPanel_DispIndicator_Group4
	cp_erpb 0xfb, 0x40
	jr z, CtrlPanel_DispIndicator_Group3
	cp_erpb 0xfb, 0x20
	jr z, CtrlPanel_DispIndicator_Group2
	cpi_berp 0xfb, 0
	jr nz, CtrlPanel_PopRetFA2
	orddm16 36668, xhl
	jr CtrlPanel_PopRetFA2

CtrlPanel_DispIndicator_Group2:
	orddm16 36672, xhl
	jr CtrlPanel_PopRetFA2

CtrlPanel_DispIndicator_Group3:
	orddm16 36676, xhl
	jr CtrlPanel_PopRetFA2

CtrlPanel_DispIndicator_Group4:
	orddm16 36680, xhl

CtrlPanel_PopRetFA2:
	pop_werp 0xfa
	ret

CtrlPanel_SetIndicatorLED:
	push_werp 0xfa
	ld c, a
	and c, 0xf0
	ldfr_berp C, 0xfb
	and a, 0xf
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	ld wa, hl
	cpl wa
	cp_erpb 0xfb, 0x40
	jr z, CtrlPanel_SetLED_Group3
	cp_erpb 0xfb, 0x20
	jr z, CtrlPanel_SetLED_Group2
	cpi_berp 0xfb, 0
	jr nz, MidiChOutState_Return
	anddm16 36668, xwa
	orddm16 36666, xhl
	jr MidiChOutState_Return

CtrlPanel_SetLED_Group2:
	anddm16 36672, xwa
	orddm16 36670, xhl
	jr MidiChOutState_Return

CtrlPanel_SetLED_Group3:
	anddm16 36676, xwa
	orddm16 36674, xhl

MidiChOutState_Return:
	pop_werp 0xfa
	ret

MidiChannel_ProcessOutputState:
	push xiz
	ldada xiz, 36632
	calr MidiChOut_DetectChanges
	lda xde, (xiz + 14)
	ldda8 c, 36470
	bitda 2, 1054
	jr nz, MidiChOut_CheckHWState
	ld a, c
	bit 1, c
	jr z, MidiChannel_CleanupRet
	res 1, a
	stda8 36470, a
	jr MidiChOut_ClearLowNibble

MidiChOut_CheckHWState:
	ldda8 l, 1046
	ldda8 a, 1045
	and a, 0x60
	jr nz, MidiChOut_CheckBit1Clear
	setda 1, 36470
	ldda8 a, 1075
	cps a, 6
	jr z, MidiChOut_Mode6or3_Mask7
	cps a, 3
	jr nz, MidiChOut_OtherMode_Mask3

MidiChOut_Mode6or3_Mask7:
	and l, 0x7
	ld xwa, 0xeda64e
	jr MidiChOut_TableLookup

MidiChOut_OtherMode_Mask3:
	and l, 0x3
	ld xwa, 0xeda654

MidiChOut_TableLookup:
	extz hl
	ld_srib3 A, 0x07, 0xe0, 0xec
	and a, 0xf
	andmi8 (xde), 0xf0
	or (xde), a
	jr MidiChannel_CleanupRet

MidiChOut_CheckBit1Clear:
	ld a, c
	bit 1, c
	jr z, MidiChannel_CleanupRet
	res 1, a
	stda8 36470, a

MidiChOut_ClearLowNibble:
	andmi8 (xde), 0xf0

MidiChannel_CleanupRet:
	pop xiz
	ret

MidiChOut_DetectChanges:
	bitda 2, 1054
	ret nz
	ldda8 a, 1056
	xorda8 a, 13435
	bit 2, a
	ret z
	ordi16 36670, 4
	ldmm8 13435, 1056
	ret

MidiChannel_ScanPending:
	push xiz
	ldada xiz, 36632
	ldda16 xwa, 36672
	bit 2, wa
	jr nz, MidiScan_PopIzRet
	ldda8 a, 36682
	and a, 0x3
	jr nz, MidiScan_PopIzRet
	bitda 2, 1054
	jr nz, MidiScan_PopIzRet
	bitda 2, 10407
	jr nz, MidiScan_AltPathCheck
	ld xwa, 0x28103
	call SndParam_LookupReadOnly
	lda xbc, (xiz + 14)
	cps hl, 1
	jr nz, MidiScan_CheckBit2InAddr1057
	ldda16 xwa, 1039
	bit 6, wa
	jr nz, MidiScan_ClearAndReturn
	ld a, (xbc)
	and a, 0xf0
	set 0, a
	ld (xbc), a
	jr MidiScan_PopIzRet

MidiScan_CheckBit2InAddr1057:
	bitda 2, 1057
	jr nz, MidiScan_PopIzRet

MidiScan_ClearAndReturn:
	andmi8 (xbc), 0xf0
	jr MidiScan_PopIzRet

MidiScan_AltPathCheck:
	bitda 2, 1057
	jr nz, MidiScan_PopIzRet
	andmi8 (xiz + 14), 0xf0

MidiScan_PopIzRet:
	pop xiz
	ret

; ============================================================================
; UIState_UpdateControlBits - Update UI state control bit flags
; ============================================================================
; Input:  Control parameters from caller
; Output: Updated control bit state
; Modifies the UI state control flags that govern which UI elements are
; active and which input modes are enabled.
; ============================================================================
UIState_UpdateControlBits:
	ldda8	a, 49277
	cps	a, 5
	jr	z, 22
	cps	a, 4
	jr	z, 11
	cps	a, 0
	ret	nz
	.byte 0xd1
	push	xde
	decm8	1, (xsp+62)
	nop
	ret
	.byte 0xd1
	push	xde
	.byte 0x8f
	push	xiz
	pushw	wa
	nop
	ret
	.byte 0xd1
	push	xde
	.byte 0x8f
	push	xiz
	.byte 0x40
	nop
	ret
UIState_SwitchOnDisplayMode:
	; --- Switch on A = (0xc07d): or bits into (0x8f3a)/(0x8f42) (53 bytes) ---
	ldda8	a, 49277
	cps	a, 4
	jr z, UIState_Mode4
	cps	a, 3
	jr z, UIState_Mode3
	cps	a, 1
	jr z, UIState_Mode0or1
	cps	a, 0
	jr z, UIState_Mode0or1
	cp a, 0x10
	ret nz
	ordi16	36666, 107
	ret
UIState_Mode0or1:
	ordi16	36666, 111
	ret
UIState_Mode3:
	ordi16	36674, 512
	ret
UIState_Mode4:
	ordi16	36674, 32768
	ret


UIState_ProcessExtendedMode:
	ldda8	a, 49277
	extz	wa
	cps	wa, 0
	ret	mi
	cps	wa, 7
	ret	gt
	add	wa, wa
	lda_24	xix, 15574620
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	w, 242
	.byte 0x85
	jrl	ugt, 13564
	.byte 0xf3
	reti
	.byte 0xf0, 0xe0
	xor	bc, wa
	push	xiz
	.byte 0x8f
	push	xiz
	pop_sr
	push_sr
	ret
	.byte 0xd1
	push	xiz
	cp	(xsp+62), d
	nop
	ret
	ld	xwa, 163968
	call	SndParam_LookupReadOnly
	cps	l, 0
	jr	z, 5
	st8_24	65480, l
	.byte 0xd1
	push	xiz
	.byte 0x8f
	push	xiz
	nop
	.byte 0x01
	ret
	.byte 0xd1
	ld	xde, 1064591
	ret
	.byte 0xd1
	push	xiz
	.byte 0x8f
	push	xiz
	nop
	push_sr
	ret
UIStateEvt_NullHandler:
	ret
UIState_SwitchForMidiFlags:
	; --- Switch on A = (0xc07d): or bits into (0x8f42) (51 bytes) ---
	ldda8	a, 49277
	cp a, 0x14
	jr z, UIState_MidiMode14
	cps	a, 4
	jr z, UIState_MidiMode4
	cp a, 0x3f
	jr z, UIState_MidiMode3F
	cps	a, 6
	ret nz
UIState_MidiMode6:
	ordi16	36674, 1024
	ret
UIState_MidiMode3F:
	ordi16	36674, 2048
	ret
UIState_MidiMode4:
	ordi16	36674, 2
	ret
UIState_MidiMode14:
	ordi16	36674, 4096
	ret
UIState_NullReturn:
	ret


UIState_ProcessAltMode:
	ldda8	a, 49277
	cp	a, 11
	jr	z, 22
	cps	a, 3
	jr	z, 11
	cps	a, 1
	ret	nz
	.byte 0xd1
	ld	xde, 212623
	ret
	.byte 0xd1
	ld	xde, 540303
	ret
	.byte 0xd1
	ld	xde, 1610628751
	ret
UIState_ProcessSimpleMode:
	ldda8	a, 49277
	cps	a, 1
	ret	nz
	.byte 0xd1
	push	xde
	.byte 0x8f
	push	xiz
	.byte 0x90
	nop
	ret

CtrlPanel_LookupIndicatorEntry:
	extz wa
	sla wa, 2
	lda_24 xbc, 0xeda66c
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	ret

Util_FindLowestSetBit:
	lds hl, 0
	or xwa, xwa
	ret z
	bit 0, wa
	ret nz

FindBit_ShiftLoop:
	srl xwa, 1
	inc 1, hl
	bit 0, wa
	jr z, FindBit_ShiftLoop
	ret

Audio_InitAllDefaults:
	stdi8 49209, 255
	stdi8 48444, 255
	stdi16 37086, 0
	stdi16 37088, 0
	stdi8 48953, 255
	stdi16 37090, 0
	stdi16 37171, 0
	stdi8 37115, 255
	stdi8 37293, 255
	stdi8 37301, 255
	stdi8 37330, 255
	stdi8 37112, 127
	stdi8 36707, 255
	lda_24 xwa, 0xedae64
	stda32 37106, xwa
	lda_24 xwa, 0xedb264
	stda32 37250, xwa
	ldada xbc, 37261
	ld xwa, xbc
	lda xbc, (xbc + 31)

AudioInit_FillLoop:
	stib_dpi 0xe0, 0x50
	cp xwa, xbc
	jr ule, AudioInit_FillLoop
	call ToneGen_FlashVerify
	jp DSPCfg_Param_CaseB

Audio_ResetAfterPayloadError:
	call SubCPU_Payload_GetErrorFlag
	cp hl, 0xffff
	jr nz, Audio_ReinitToneGen
	cpdi8 36150, 65
	jr nz, Audio_ReinitDisplay
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, Audio_ReinitDisplay
	ld xwa, 0xc0
	lds bc, 0
	lds de, 1
	call SoundParam_NotifyChange
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	pop xix
	pop xhl
	pop xde

Audio_ReinitDisplay:
	calr Display_SetupAndPrepareRender
	calr Display_CopyAndRenderBitmaps
	call MainTitle_SetBootFlag

Audio_ReinitToneGen:
	push xde
	push xhl
	push xix
	push xiz
	call ToneGen_ApplyMaskTable
	call ToneGen_Config_InitAndChannels
	call ToneGen_InitAllChannelEntries_Skip
	call ToneGen_DSPCfg_Initialize
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr MidiMsg_ParseChannelStream
	calr Audio_InitAllChannelParams
	call SeqTimer_UpdateTempoReg
	calr Audio_FillParamBuffer
	jp CompIface_SetMax

Audio_FillParamBuffer:
	ldada xbc, 37261
	ld xwa, xbc
	lda xbc, (xbc + 31)

AudioFill_Loop:
	stib_dpi 0xe0, 0x50
	cp xwa, xbc
	jr ule, AudioFill_Loop
	ret

Audio_JumpTrampoline:
	jr	t, 0x82

Audio_ReinitToneGenAndOutput:
	push xde
	push xhl
	push xix
	push xiz
	call ToneGen_ApplyMaskTable
	call ToneGen_Config_InitAndChannels
	call ToneGen_InitAllChannelEntries_Skip
	call ToneGen_DSPCfg_Initialize
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr MidiMsg_ParseChannelStream
	cpdi8 64818, 182
	jr z, Audio_UpdateTempoAndReturn
	pushw 0x7f
	ldw wa, 0xb0
	lds bc, 1
	ldw de, 0x7f
	calr MIDI_WriteCommandToBuffer
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde

Audio_UpdateTempoAndReturn:
	call SeqTimer_UpdateTempoReg
	jp CompIface_SetMax

Audio_FullReinitWithPreset:
	lda_24 xwa, 0xedae64
	stda32 37106, xwa
	lda_24 xwa, 0xedb264
	stda32 37250, xwa
	call Sys_CheckPowerStableFlag
	cps hl, 0
	jr nz, Audio_CheckAndReinitReverb
	ld xwa, 0xc0
	lds bc, 0
	lds de, 1
	call SoundParam_NotifyChange
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	pop xix
	pop xhl
	pop xde

Audio_CheckAndReinitReverb:
	ld xwa, 0x2880
	call SndParam_LookupReadOnly
	cp hl, 0xb7
	ret nz
	ld xwa, 0x4001
	ldw bc, 0x7f
	lds de, 2
	call SoundParam_NotifyChange
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

VoiceData_InitAndCopyParams:
	dec 2, xsp
	push xiz
	ld (xsp + 4), wa
	cpw (xsp + 4), 0x50
	jrl nc, VoiceData_InitDone
	pushw 0x3c0
	pushw 0x0
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 4
	sub xbc, xwa
	sll xbc, 6
	ld xwa, 0x1ed400
	add xwa, xbc
	push xwa
	call Memset
	inc 8, xsp
	ld iz, (xsp + 4)
	extz xiz
	ld xwa, xiz
	ld xbc, 0x2a2
	call Math_MultiplyAccumulate
	add xhl, 0x99eca0
	ld xwa, xiz
	sll xwa, 4
	sub xwa, xiz
	sll xwa, 6
	lda_24 xiz, 0x1ed400
	add xiz, xwa
	pushw 0x7c
	push xhl
	push xiz
	call Mem_Copy
	lda_24 xwa, 0xedb3fc
	add xwa, 0x7c
	lda xiz, (xiz + 124)
	pushw 0x11e
	push xwa
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 20)
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x2a2
	call Math_MultiplyAccumulate
	add xhl, 0x99eca0
	add xhl, 0x7c
	st_dri3b W, 0xf9, 0x1e, 0x01
	pushw 0x226
	push xhl
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)

VoiceData_InitDone:
	pop xiz
	inc 2, xsp
	ret

VoiceData_ExtendedParamSetup:
	cp	wa, 10
	ret	nc
	sll	wa, 4
	extz	xwa
	ld	xde, xwa
	add	xde, 10087424
	lda_24	xbc, 2020192
	add	xbc, xwa
	pushw	16
	push	xde
	push	xbc
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ret
	calr	753
	call	ToneGen_Config_InitAllEntries
	call	Voice_InitAllChannelEntries
	call	ToneGen_DSPCfg_ResetAll
	calr	651
	call	MainTitle_SetBootFlag
	jrl	-415
	dec	8, xsp
	pushw	iz
	lda_24	xwa, 15578108
	ld	(xsp+2), xwa
	ldada	xwa, 63904
	ld	(xsp+6), xwa
	lds	iz, 0
	ld	wa, iz
	extz	xwa
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 20
	ld	xbc, xhl
	.byte 0xaf
	push_sr
	add	(xbc), a
	.byte 0x01
	ldb	a, 216
	ccf
	pushw	wa
	lda	xwa, (xbc+2)
	push	xwa
	.byte 0xaf
	incf
	.byte 0x83
	lda	xwa, (xhl+2)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ld	wa, iz
	extz	xwa
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 20
	.byte 0xaf, 0x06
	or	(xhl), c
	and	(xwa+30), c
	pop_sr
	inc	1, iz
	cp	iz, 24
	jr	c, -83
	call	Voice_InitAllChannelEntries
	popw	iz
	inc	8, xsp
	ret
	lda	xsp, (xsp-10)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda_24	xwa, 15578108
	ld	(xsp+4), xwa
	ldada	xwa, 63904
	ld	(xsp+8), xwa
	ld	(xsp+2), 0
	ld	a, (xsp+2)
	extz	wa
	muls	wa, 26
	ld	ix, wa
	add	ix, 20
	ld	xwa, (xsp+8)
	.byte 0xf3
	reti
	.byte 0xe0, 0xf0
	ldw	hl, 3771
	ldw	de, 9090
	and	c, 248
	ld	(xde), c
	ld	xwa, (xsp+4)
	.byte 0xf3
	reti
	.byte 0xe0, 0xf0
	ldw	wa, 3720
	ldb	a, 201
	neg	d
	or	c, a
	ld	(xde), c
	ld	a, (xhl)
	extz	wa
	ld	e, c
	extz	de
	pushw	7
	ldw	bc, 12
	calr	1032
	pushw	9
	ld	a, (xsp+4)
	extz	wa
	muls	wa, 26
	ld	bc, wa
	add	bc, 20
	ld	xwa, (xsp+6)
	.byte 0xf3
	reti
	.byte 0xe0, 0xe4
	ldw	wa, 4024
	ldw	wa, 44856
	ret
	ldb	w, 243
	reti
	.byte 0xe0, 0xe4
	ldw	wa, 4024
	ldw	wa, 7480
	.byte 0x8b
	decf
	swi	7
	lda	xsp, (xsp+10)
	.byte 0xc7
	swi	3
	pop_sr
	decf
	ld	a, (xsp+2)
	extz	wa
	muls	wa, 26
	ld	hl, wa
	ld	bc, hl
	add	bc, 20
	ld	xde, (xsp+8)
	.byte 0xc3
	reti
	or	xix, xwa
	ldb	a, 216
	ccf
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	add	hl, bc
	.byte 0xf3
	reti
	sla	xwa, 50
	ld	e, (xde+22)
	extz	de
	pushw	255
	calr	929
	.byte 0xc7
	swi	3
	jr	lt, -57
	swi	3
	.byte 0xcf
	pop_a
	jr	ule, -59
	incm8	1, (xsp+2)
	.byte 0x8f
	push_sr
	push	xsp
	push_f
	jrl	c, -190
	.byte 0xf2, 0xc0
	swi	7
	nop
	.byte 0xb9
	pushw	14
	ld	xwa, (xsp+6)
	lda	xwa, (xwa+944)
	push	xwa
	ld	xwa, (xsp+14)
	lda	xwa, (xwa+944)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ld	(xsp+2), 0
	ld	c, (xsp+2)
	extz	bc
	ld	de, bc
	add	de, 944
	ld	xwa, (xsp+8)
	.byte 0xc3
	reti
	.byte 0xe0, 0xe8
	ldb	e, 218
	ccf
	pushw	255
	ldw	wa, 128
	calr	843
	incm8	1, (xsp+2)
	.byte 0x8f
	push_sr
	push	xsp
	ret
	jr	c, -39
	ld	xwa, (xsp+8)
	.byte 0xf3, 0xe1
	decf
	.byte 0x04
	ldw	bc, 8577
	bit	2, a
	jr	z, 20
	res	2, a
	ld	(xbc), a
	ld	e, a
	extz	de
	pushw	4
	ldw	wa, 145
	lds	bc, 3
	calr	799
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SwbtWr_ReinitOutputBank
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	(xsp+2), 0
	lda_24	xwa, 15578108
	ld	(xsp+4), xwa
	lds32	xwa, 0
	ld	a, (xsp+2)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	ld	xwa, 2020352
	add	xwa, xbc
	ld	(xsp+8), xwa
	.byte 0xc7
	swi	3
	cp	(xwa-57), xhl
	.byte 0x89
	extz	wa
	muls	wa, 26
	ld	hl, wa
	add	hl, 20
	ld	xwa, (xsp+8)
	.byte 0xf3
	reti
	.byte 0xe0, 0xec
	ldw	ix, 3772
	ldw	de, 9090
	and	c, 248
	ld	(xde), c
	ld	xwa, (xsp+4)
	exts	xhl
	add	xhl, xwa
	ld	a, (xhl+14)
	and	a, 7
	or	c, a
	ld	(xde), c
	pushw	9
	lda	xwa, (xhl+15)
	push	xwa
	lda	xwa, (xix+15)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	.byte 0xc7
	swi	3
	jr	lt, -57
	swi	3
	.byte 0xcf
	push_f
	jr	c, -77
	pushw	14
	ld	xwa, (xsp+6)
	.byte 0xf3, 0xe1, 0xb0
	pop_sr
	ldw	wa, 44856
	ret
	ldb	w, 243
	.byte 0xe1, 0xb0
	pop_sr
	ldw	wa, 7480
	.byte 0x8b
	decf
	swi	7
	lda	xsp, (xsp+10)
	incm8	1, (xsp+2)
	.byte 0x8f
	push_sr
	push	xsp
	.byte 0x50
	jrl	c, -151
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+10)
	ret
	calr	117
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	ToneGen_Config_InitAndChannels
	call	ToneGen_InitAllChannelEntries_Skip
	call	ToneGen_DSPCfg_Initialize
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	7
	calr	173
	jp	SeqTimer_UpdateTempoReg

MidiMsg_ParseChannelStream:
	push xiz
	ldada xiz, 63904
	jr MidiMsg_LoopAndFlush

MidiMsg_CheckTerminator:
	cp (xiz), 0xff
	jr nz, MidiMsg_CheckMsgType
	inc 2, xiz
	jr MidiMsg_LoopAndFlush

MidiMsg_CheckMsgType:
	cp (xiz), 0x1f
	jr ule, MidiMsg_WriteMultiByte
	cp (xiz), 0x48
	jr nz, MidiMsg_CheckControlChange

MidiMsg_WriteMultiByte:
	ld xwa, xiz
	calr MIDI_WriteMultiByteWithHeader
	jr MidiChannelMsg_WriteOutput

MidiMsg_CheckControlChange:
	cp (xiz), 0xc0
	jr c, MidiMsg_WriteDefaultMsg
	cp (xiz), 0xdf
	jr ule, MidiChannelMsg_WriteOutput

MidiMsg_WriteDefaultMsg:
	cp (xiz), 0x49
	jr z, MidiChannelMsg_WriteOutput
	ld xwa, xiz
	calr MIDI_WriteMultiByteNoHeader

MidiChannelMsg_WriteOutput:
	ld a, (xiz + 1)
	inc 2, a
	extz wa
	st_dri3b H, 0x07, 0xf8, 0xe0

MidiMsg_LoopAndFlush:
	cp xiz, 0xffbe
	jr c, MidiMsg_CheckTerminator
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	pop xiz
	ret

Display_SetupAndPrepareRender:
	pushw 0x20
	pushw 0xed
	pushw 0xb3dc
	pushw 0x0
	pushw 0xf980
	call Mem_Copy
	pushw 0x620
	pushw 0xed
	pushw 0xb3fc
	pushw 0x0
	pushw 0xf9a0
	call Mem_Copy
	lda xsp, (xsp + 20)
	resda_24 0, 65474
	setda_24 1, 65472
	call Get_Region_Code
	cps l, 2
	jr nz, Display_SetRegionNon2
	sti8_24 0x00ffc8, 0x01
	jr Display_RegionDone

Display_SetRegionNon2:
	sti8_24 0x00ffc8, 0x02

Display_RegionDone:
	lds wa, 0
	call BitMapOut_PrepareRender_CheckBit2
	jrl Audio_FillParamBuffer

Display_CopyAndRenderBitmaps:
	pushw iz
	pushw 0x10
	pushw 0xed
	pushw 0xba1c
	pushw 0x1e
	pushw 0xd350
	call Mem_Copy
	pushw 0xa0
	ld xwa, 0x99ec00
	push xwa
	pushw 0x1e
	pushw 0xd360
	call Mem_Copy
	lda xsp, (xsp + 20)
	lds iz, 0

DisplayRender_Loop:
	ld wa, iz
	calr VoiceData_InitAndCopyParams
	inc 1, iz
	cp iz, 0x50
	jr c, DisplayRender_Loop
	calr Display_ProcessBitmapTable
	popw iz
	ret

Display_ProcessBitmapTable:
	dec 2, xsp
	push xiz
	ldw (xsp + 4), 0x0

BitmapTable_ProcessEntry:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	lda_24 xwa, 0xedb2f6
	add xwa, xbc
	ld a, (xwa)
	calr VoiceData_LookupPtrByIndex
	ld xiz, xhl
	sub xiz, 0xf9a0
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	ld xwa, 0xedb2f4
	add xwa, xbc
	lda_24 xbc, 0x1ed400
	lda xde, (xwa + 3)
	lda xhl, (xwa + 4)
	lda xix, (xwa + 5)
	cpw (xwa), 0x50
	jr nz, BitmapTable_CheckOffset
	lds iy, 0
	ld e, (xde)
	ld d, (xix)
	ld l, (xhl)
	add xbc, xiz
	ld xix, xbc

BitmapTable_RenderLine:
	ld a, e
	extz wa
	st_dri3b A, 0x07, 0xf0, 0xe0
	ld a, d
	cpl a
	and (xbc), a
	or (xbc), l
	inc 1, iy
	add xix, 0x3c0
	cp iy, 0x50
	jr c, BitmapTable_RenderLine
	jr BitmapTable_NextEntry

BitmapTable_CheckOffset:
	cpw (xwa), 0x50
	jr ge, BitmapTable_NextEntry
	ld wa, (xwa)
	exts xwa
	ld xiy, xwa
	sll xiy, 4
	sub xiy, xwa
	sll xiy, 6
	add xbc, xiy
	ld xiy, xbc
	add xiy, xiz
	ld c, (xde)
	extz bc
	ld a, (xix)
	cpl a
	and_srib_mr A, 0x07, 0xf4, 0xe4
	ld c, (xde)
	extz bc
	ld a, (xhl)
	or_srib_mr A, 0x07, 0xf4, 0xe4

BitmapTable_NextEntry:
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x1
	jrl c, BitmapTable_ProcessEntry
	pop xiz
	inc 2, xsp
	ret

MIDI_WriteMultiByteWithHeader:
	dec 6, xsp
	push xiz
	ld xiz, xwa
	ld_spib A, 0xf8
	ld (xsp + 4), a
	ld_spib A, 0xf8
	ld (xsp + 6), a
	ld a, (xsp + 4)
	extz wa
	ld e, (xiz + 1)
	extz de
	pushw 0xff
	lds bc, 1
	calr MIDI_WriteCommandToBuffer
	ld a, (xsp + 4)
	extz wa
	ld e, (xiz)
	extz de
	pushw 0xff
	lds bc, 0
	calr MIDI_WriteCommandToBuffer
	decm8 2, (xsp + 6)
	ld (xsp + 8), 0x2
	inc 2, xiz
	cp (xsp + 6), 0x0
	jr z, MidiMultiByte_Done

MidiMultiByte_WriteLoop:
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 8)
	extz bc
	ld e, (xiz)
	extz de
	pushw 0xff
	calr MIDI_WriteCommandToBuffer
	decm8 1, (xsp + 6)
	incm8 1, (xsp + 8)
	inc 1, xiz
	cp (xsp + 6), 0x0
	jr nz, MidiMultiByte_WriteLoop

MidiMultiByte_Done:
	pop xiz
	inc 6, xsp
	ret

MIDI_WriteMultiByteNoHeader:
	dec 6, xsp
	push xiz
	ld xiz, xwa
	ld_spib A, 0xf8
	ld (xsp + 4), a
	ld_spib A, 0xf8
	ld (xsp + 6), a
	ld (xsp + 8), 0x0
	cp (xsp + 6), 0x0
	jr z, MidiNoHeader_Done

MidiNoHeader_WriteLoop:
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 8)
	extz bc
	ld e, (xiz)
	extz de
	pushw 0xff
	calr MIDI_WriteCommandToBuffer
	decm8 1, (xsp + 6)
	incm8 1, (xsp + 8)
	inc 1, xiz
	cp (xsp + 6), 0x0
	jr nz, MidiNoHeader_WriteLoop

MidiNoHeader_Done:
	pop xiz
	inc 6, xsp
	ret

MIDI_WriteCommandToBuffer:
	ldda16 xhl, 37086
	ld ix, hl
	inc 1, hl
	stda16 37086, xhl
	ldada xhl, 48444
	extz xix
	add xix, xhl
	ld (xix), a
	ldda16 xwa, 37086
	ld ix, wa
	inc 1, wa
	stda16 37086, xwa
	ld wa, ix
	extz xwa
	add xwa, xhl
	ld (xwa), c
	ldda16 xwa, 37086
	ld bc, wa
	inc 1, wa
	stda16 37086, xwa
	extz xbc
	add xbc, xhl
	ld (xbc), e
	ldda16 xwa, 37086
	ld bc, wa
	inc 1, wa
	stda16 37086, xwa
	extz xbc
	add xbc, xhl
	ld a, (xsp + 4)
	ld (xbc), a
	ldda16 xwa, 37086
	extz xwa
	add xwa, xhl
	ld (xwa), 0xff
	cpdi16 37086, 508
	jr c, MidiWrite_ReturnDiscard
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	stdi16 37086, 0

MidiWrite_ReturnDiscard:
	retd 0x2

Audio_InitAllChannelParams:
	push_werp 0xfa
	ldi_berp 0xfb, 0

AudioParamInit_Loop:
	ldto_berp A, 0xfb
	extz wa
	calr Audio_InitSingleChannelParams
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x0f
	jr ule, AudioParamInit_Loop
	pop_werp 0xfa
	ret

Audio_InitSingleChannelParams:
	dec 2, xsp
	ld (xsp), a
	stdi8 37159, 177
	mrib4 0x87, 0x19, 0x28, 0x91
	stdi8 37161, 0
	stdi8 37162, 64
	calr SwbtWr_WriteParamBlock
	stdi8 37159, 178
	mrib4 0x87, 0x19, 0x28, 0x91
	stdi8 37161, 0
	stdi8 37162, 127
	calr SwbtWr_WriteParamBlock
	stdi8 37159, 179
	mrib4 0x87, 0x19, 0x28, 0x91
	stdi8 37161, 127
	stdi8 37162, 127
	calr SwbtWr_WriteParamBlock
	mrib4 0x87, 0x19, 0x7e, 0x91
	stdi8 37247, 4
	stdi8 37248, 0
	stdi8 37249, 8
	call MIDI_WriteVoiceParamFromBuffer
	mrib4 0x87, 0x19, 0x27, 0x91
	stdi8 37160, 4
	stdi8 37161, 0
	stdi8 37162, 8
	calr SwbtWr_WriteParamBlock
	inc 2, xsp
	ret

Audio_MainPeriodicUpdate:
	cpdi8 49209, 255
	ret z
	resda 0, 37221
	lda_24 xwa, 0xedae64
	stda32 37106, xwa
	calr Audio_SyncBufferPositions
	push xde
	push xhl
	push xix
	push xiz
	call MidiStream_ProcessEventBuffer
	call MidiStream_ProcessSeqBuffer
	call MIDI_SelectTempoExpressionSource
	call MidiStream_ProcessTempoRingBuf
	call MidiStream_ProcessRxBuffer
	call MidiPkt_ProcessEventQueue
	pop xiz
	pop xix
	pop xhl
	pop xde
	resda 1, 37113
	ret

Audio_SyncBufferPositions:
	stdi16 37171, 0
	ldmm16 37088, 37086
	jr FileIO_ProcessRemainingOps

; File I/O operation dispatch
FileIO_OperationDispatch:
	calr SndParam_FetchSequencerParams
	ldda8 a, 37159
	extz wa
	sla wa, 2
	lda_24 xbc, 0xedaa64
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	call (xhl)
	cpdi16 37086, 508
	jr c, FileIO_ProcessRemainingOps
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	pop xix
	pop xhl
	pop xde
	stdi16 37088, 0

FileIO_ProcessRemainingOps:
	ldada xbc, 49209
	ldda16 xwa, 37171
	extz xwa
	add xwa, xbc
	cp (xwa), 0xff
	jr nz, FileIO_OperationDispatch
	ldada xbc, 48444
	ldda16 xwa, 37086
	extz xwa
	add xwa, xbc
	ld (xwa), 0xff
	stdi8 37112, 127
	ret

ExtData_ToneParam_DispatchHandler:
	calr	4351
	ldda8	a, 37167
	cp	a, 22
	jr	z, 63
	extz	wa
	cps	wa, 0
	ret	mi
	cp	wa, 11
	ret	gt
	add	wa, wa
	lda_24	xix, 15577850
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	w, 242
	jrl	f, -891
	ldw	ix, 2035
	.byte 0xf0, 0xe0
	dec	8, wa
	.byte 0x1f
	jrl	179
	jrl	191
	jrl	372
	jrl	378
	jrl	390
	jrl	396
	jrl	402
	jrl	408
	jrl	414
	calr	420
	ret
	dec	6, xsp
	lda	xwa, (xsp)
	.byte 0xb0
	push_a
	ldw	wa, 47249
	.byte 0x01
	push_a
	ldw	bc, 47249
	push_sr
	push_a
	ldb	l, 145
	call	SndParam_ApplyProgramChange
	ldda8	a, 37159
	extz	wa
	calr	6212
	cp	xhl, 4294967295
	jr	z, 109
	lda	xde, (xsp)
	.byte 0x82
	push	xsp
	incf
	jr	nz, 25
	ld	a, (xhl)
	.byte 0x8a
	pop_sr
	.byte 0xf1
	jr	nz, 18
	ld	a, (xhl+1)
	res	7, a
	.byte 0x8a, 0x04, 0xf1
	jr	nz, 7
	.byte 0xc1
	ldw	ix, 16269
	decf
	jr	nz, 77
	ld	a, (xde+3)
	.byte 0xf5, 0xec
	ld	xbc, 3435864963
	.byte 0x80
	ld	(xhl), c
	inc	4, xde
	ld	a, (xde)
	or	c, a
	ld	(xhl), c
	stdi8	37160, 1
	.byte 0x82
	pop_f
	pushw	bc
	.byte 0x91
	stdi8	37162, 127
	calr	4197
	stdi8	37160, 0
	.byte 0x8f
	pop_sr
	pop_f
	pushw	bc
	.byte 0x91
	stdi8	37162, 255
	calr	4179
	ldda8	a, 37159
	extz	wa
	lda	xde, (xsp)
	ld	c, (xde+3)
	extz	bc
	ld	e, (xde+4)
	extz	de
	calr	5727
	inc	6, xsp
	ret
	ldw	wa, 128
	calr	4420
	ldw	wa, 127
	calr	4414
	jrl	4140
	dec	6, xsp
	ldda8	a, 37159
	extz	wa
	calr	6066
	cp	xhl, 4294967295
	jrl	z, 161
	lda	xwa, (xsp)
	.byte 0xb8
	push_sr
	push_a
	ldb	l, 145
	ld	c, (xhl)
	ld	(xwa+3), c
	ld	c, (xhl+1)
	res	7, c
	ld	(xwa+4), c
	call	SndParam_FetchOscTableEntry
	lda	xwa, (xsp)
	.byte 0x80
	push	xsp
	retd	2670
	.byte 0xc1
	ldw	wa, 15505
	.byte 0xb7, 0xc1
	ldw	bc, 15505
	.byte 0xb7, 0x80
	push	xsp
	incf
	jr	nz, 8
	.byte 0xf1
	ldw	wa, 46737
	.byte 0xf1
	ldw	bc, 46737
	.byte 0xf1
	swi	1
	and	(xwa), bc
	jr	z, 11
	ldw	wa, 8
	calr	4682
	ldw	wa, 96
	jr	3
	ldw	wa, 104
	calr	4137
	ldda8	c, 37169
	ld	a, c
	and	a, 7
	cps	a, 7
	jr	nz, 7
	lds	wa, 7
	calr	4295
	jr	60
	and	c, 3
	jr	z, 55
	ldda8	a, 37168
	cps	a, 2
	jr	nz, 21
	stdi8	37203, 1
	stdi8	37204, 8
	stdi8	37205, 7
	lds	wa, 2
	lds	bc, 7
	jr	23
	cps	a, 1
	jr	nz, 22
	stdi8	37203, 255
	stdi8	37204, 255
	stdi8	37205, 0
	lds	wa, 1
	lds	bc, 7
	calr	4482
	calr	3959
	inc	6, xsp
	ret
	ldw	wa, 127
	calr	4221
	jrl	3947
	ldw	wa, 127
	calr	4212
	ldw	wa, 128
	calr	4030
	jrl	3932
	ldw	wa, 127
	calr	4197
	jrl	3923
	ldw	wa, 127
	calr	4188
	jrl	3914
	ldw	wa, 127
	calr	4179
	jrl	3905
	ldw	wa, 255
	calr	4170
	jrl	3896
	ldw	wa, 127
	calr	4161
	jrl	3887
	lds	wa, 1
	calr	3977
	jrl	3879
FileIO_AllocBuffer:
	ret
ExtData_ToneParam_CheckMode:
	calr	3844
	ldda8	a, 37167
	cps	a, 1
	jr	z, 6
	cps	a, 0
	ret	nz
	jr	4
	calr	10
	ret
	ldw	wa, 128
	calr	4122
	jrl	3848
	ldw	wa, 128
	calr	4113
	ldw	wa, 127
	calr	4107
	jrl	3833
ExtData_ToneParam_AltDispatch:
	calr	3799
	ldda8	a, 37167
	extz	wa
	cps	wa, 0
	ret	mi
	cp	wa, 8
	ret	gt
	add	wa, wa
	lda_24	xix, 15577874
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	w, 242
	.byte 0x93
	cp	(xsp), d
	ldw	ix, 2035
	.byte 0xf0, 0xe0
	dec	8, wa
	ldio	104, 15
	jr	28
	calr	40
	ret
	ldw	wa, 255
	calr	4047
	jrl	3773
	ldw	wa, 15
	calr	4038
	ldw	wa, 240
	calr	4032
	jrl	3758
	ldw	wa, 15
	calr	4023
	ldw	wa, 240
	calr	4017
	jrl	3743
	ldw	wa, 15
	calr	4008
	ldw	wa, 48
	calr	3826
	jrl	3728
ExtData_ToneParam_AltEntry:
	ret
ExtData_ToneParam_AltBody:
	calr	3693
	ldda8	a, 37167
	extz	wa
	cps	wa, 0
	ret	mi
	cp	wa, 8
	ret	gt
	add	wa, wa
	lda_24	xix, 15577892
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	w, 242
	swi	5
	cp	(xsp), d
	ldw	ix, 2035
	.byte 0xf0, 0xe0
	dec	8, wa
	retd	28776
	jrl	143
	jrl	149
	jrl	161
	calr	167
	ret
	ldada	xwa, 37098
	.byte 0xb0
	push_a
	ldw	wa, 47249
	.byte 0x01
	push_a
	ldw	bc, 47249
	push_sr
	push_a
	ldb	l, 145
	call	Rhythm_LookupTempoVelocity_Wrap
	ldda8	a, 37159
	extz	wa
	calr	5575
	cp	xhl, 4294967295
	ret	z
	ldada	xde, 37102
	.byte 0xc5, 0xe8
	ldb	a, 245
	.byte 0xec
	ld	xbc, 3435864963
	.byte 0x80
	ld	(xhl), c
	ld	a, (xde)
	or	c, a
	ld	(xhl), c
	stdi8	37160, 1
	.byte 0x82
	pop_f
	pushw	bc
	.byte 0x91
	stdi8	37162, 127
	calr	3590
	stdi8	37160, 0
	.byte 0xc1
	adc	xwa, xiz
	pop_f
	pushw	bc
	.byte 0x91
	stdi8	37162, 255
	calr	3571
	ret
	lds	wa, 7
	calr	4004
	ldw	wa, 8
	calr	3654
	ldda8	a, 37162
	and	a, 7
	jr	z, 8
	call	ToneGen_DispatchByMode
	.byte 0xf1
	swi	1
	.byte 0x90, 0xb8
	calr	3539
	jrl	516
	ldw	wa, 80
	calr	3625
	jrl	3527
	.byte 0xc1
	ldw	wa, 6545
	pushw	bc
	.byte 0x91, 0xc1
	ldw	bc, 6545
	pushw	de
	.byte 0x91
	jrl	3512
	ldw	wa, 48
	calr	3777
	jrl	3503
	push	xiz
	ldada	xiz, 64602
	lda	xbc, (xiz+8)
	lda	xhl, (xiz+9)
	ldda8	e, 37168
	cp	(xbc), e
	jr	nz, 8
	ld	a, (xhl)
	.byte 0xc1
	ldw	bc, 61841
	jr	z, 40
	ld	(xbc), e
	.byte 0xb3
	push_a
	ldw	bc, 33169
	pop_f
	pushw	bc
	.byte 0x91
	stdi8	37162, 255
	calr	3458
	stdi8	37160, 9
	.byte 0x8e
	push	25
	pushw	bc
	.byte 0x91
	stdi8	37162, 1
	calr	3440
	call	SeqTimer_UpdateTempoReg
	pop	xiz
	ret
ExtData_ToneParam_MultiChannel:
	calr	3400
	ldda8	a, 37167
	cp	a, 16
	jr	z, 20
	cps	a, 4
	jr	z, 20
	cps	a, 3
	jrl	z, 577
	cps	a, 1
	jr	z, 4
	cps	a, 0
	ret	nz
	jrl	129
	calr	620
	ret
	ldda8	c, 37169
	ld	a, c
	and	a, 255
	cp	a, 255
	jr	nz, 6
	ldw	wa, 255
	jrl	3649
	and	c, 3
	ret	z
	ldda8	c, 37168
	and	c, 3
	ldada	xwa, 64618
	cps	c, 3
	jr	z, 59
	cps	c, 1
	jr	z, 29
	cps	c, 2
	jr	nz, 73
	stdi8	37203, 12
	stdi8	37204, 89
	stdi8	37205, 88
	lds	wa, 2
	ldw	bc, 255
	calr	3847
	jr	48
	ld	xbc, xwa
	ld	a, (xwa)
	ld	e, a
	cp	a, 40
	jr	ule, 3
	sub	e, 12
	cp	e, a
	ret	z
	ld	(xbc), e
	stda8	37161, e
	jr	17
	ld	xbc, xwa
	ld	a, (xwa)
	cp	a, 64
	ret	z
	ld	(xbc), 64
	stdi8	37161, 64
	stdi8	37162, 255
	calr	3274
	ret
	ldada	xbc, 64614
	ld	e, (xbc+1)
	extz	de
	sll	de, 8
	ld	a, (xbc)
	extz	wa
	add	wa, de
	stda16	37219, wa
	ldda8	a, 64605
	and	a, 7
	cps	a, 2
	jr	z, 32
	cps	a, 0
	jr	z, 28
	cps	a, 3
	jr	z, 9
	cps	a, 1
	ret	nz
	.byte 0xb9
	pop_sr
	dec	6, w
	retd	12225
	.byte 0x91
	push	xsp
	.byte 0x01
	jr	nz, 8
	.byte 0xf1
	ldw	wa, 45457
	.byte 0xf1
	ldw	bc, 45457
	.byte 0xc1
	pushw	sp
	.byte 0x91
	push	xsp
	.byte 0x01
	jr	nz, 29
	lds	wa, 2
	calr	3291
	.byte 0xf1
	pushw	de
	and	(xbc), bc
	jr	nz, 1
	ret
	.byte 0xf1
	swi	1
	.byte 0x90
	lda	xwa, (xwa-15)
	.byte 0x91, 0xb1, 0xf1
	ldw	bc, 45457
	stdi8	37162, 0
	calr	7
	call	ToneGen_DispatchByMode
	jrl	142
	ldda8	c, 37169
	cps	c, 0
	ret	z
	ldada	xix, 37215
	ldada	xhl, 37217
	ldda8	e, 37167
	extz	de
	ldda8	a, 37168
	and	a, c
	.byte 0xc3
	reti
	.byte 0xf0, 0xe8
	and	xbc, xbc
	pushw	sp
	ld	hl, (xbc)
	extz	bc
	ldda8	a, 37169
	cpl	a
	.byte 0xc3
	reti
	or	xix, xix
	and	a, a
	pushw	sp
	ld	hl, (xbc)
	extz	bc
	ldda8	a, 37168
	andda8	a, 37169
	.byte 0xc3
	reti
	or	xix, xix
	add	xhl, xbc
	ldb	c, 203
	dec	6, wa
	ret
	.byte 0x8b, 0x01
	push	xsp
	nop
	jr	nz, 8
	ld	(xix), 0
	ld	(xix+1), 0
	ret
	ld	a, (xix)
	and	a, 3
	jr	nz, 5
	bit	1, c
	ret	z
	ldada	xde, 64614
	extz	wa
	lda_24	xbc, 15577910
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	ldb	c, 178
	ld	xhl, 3374383498
	.byte 0xee
	ldio	216, 18
	extz	bc
	add	bc, wa
	.byte 0xd1
	jr	ule, -111
	.byte 0xf1
	ret	z
	.byte 0xf1
	swi	1
	.byte 0x90, 0xb8
	ret

MIDI_WriteResetSequence:
	ldda8 a, 37113
	bit 0, a
	ret z
	ldda16 xwa, 37086
	ld de, wa
	inc 1, wa
	stda16 37086, xwa
	ldada xbc, 48444
	extz xde
	add xde, xbc
	ld (xde), 0x90
	ldda16 xwa, 37086
	ld de, wa
	inc 1, wa
	stda16 37086, xwa
	extz xde
	add xde, xbc
	ld (xde), 0x0
	ldda16 xwa, 37086
	ld hl, wa
	inc 1, wa
	stda16 37086, xwa
	extz xhl
	add xhl, xbc
	ldada xde, 64614
	ld a, (xde)
	ld (xhl), a
	ldda16 xwa, 37086
	ld hl, wa
	inc 1, wa
	stda16 37086, xwa
	extz xhl
	add xhl, xbc
	ld (xhl), 0x1f
	ldda16 xwa, 37086
	ld hl, wa
	inc 1, wa
	stda16 37086, xwa
	extz xhl
	add xhl, xbc
	ld (xhl), 0x90
	ldda16 xwa, 37086
	ld hl, wa
	inc 1, wa
	stda16 37086, xwa
	extz xhl
	add xhl, xbc
	ld (xhl), 0x1
	ldda16 xwa, 37086
	ld hl, wa
	inc 1, wa
	stda16 37086, xwa
	extz xhl
	add xhl, xbc
	ld a, (xde + 1)
	ld (xhl), a
	ldda16 xwa, 37086
	ld de, wa
	inc 1, wa
	stda16 37086, xwa
	extz xde
	add xde, xbc
	ld (xde), 0x1f
	ldda8 a, 37113
	res 0, a
	stda8 37113, a
	ret

ExtData_Voice_UpdateFlags:
	lds	wa, 2
	calr	2926
	lds	wa, 1
	calr	3097
	calr	2823
	ldada	xbc, 64614
	.byte 0xb9
	pop_sr
	sbc	w, w
	swi	6
	ldda8	a, 64605
	and	a, 7
	cps	a, 1
	ret	nz
	inc	1, xbc
	ld	a, (xbc)
	bit	1, a
	ret	z
	.byte 0xf1
	swi	1
	.byte 0x90, 0xb8
	ld	a, (xbc)
	res	1, a
	ld	(xbc), a
	calr	65296
	ret
	.byte 0xc1
	ldw	wa, 6545
	pushw	bc
	.byte 0x91, 0xc1
	ldw	bc, 6545
	pushw	de
	.byte 0x91
	jrl	2764
ExtData_Voice_CheckMode:
	calr	2730
	ldda8	a, 37167
	cps	a, 1
	ret	nz
	calr	1
	ret
	ldw	wa, 192
	calr	2838
	jrl	2740
ExtData_Voice_RetEntry:
	ret
ExtData_Voice_MixedHandler:
	calr	2705
	ldda8	a, 37167
	cps	a, 2
	jr	z, 6
	cps	a, 0
	ret	nz
	jr	4
	calr	90
	ret
	lds	wa, 4
	calr	2808
	calr	2710
	stdi8	37203, 1
	stdi8	37204, 4
	stdi8	37205, 0
	lds	wa, 1
	lds	bc, 3
	calr	3208
	calr	2685
	.byte 0xc1
	and	e, w
	push	xsp
	swi	7
	ret	nz
	ldda8	a, 37168
	andda8	a, 37169
	bit	0, a
	jr	z, 23
	ldda8	a, 64770
	and	a, 3
	extz	wa
	lda_24	xbc, 15577914
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	pop_f
	pop	xwa
	.byte 0x8f
	jr	5
	stdi8	36696, 0
	ldw	wa, 69
	call	CtrlPanel_SetIndicatorBit
	ret
	ldda8	c, 37169
	ld	a, c
	and	a, 255
	cp	a, 255
	jr	nz, 8
	ldw	wa, 255
	calr	2880
	jr	96
	.byte 0xf1, 0xe2, 0xe3
	dec	6, a
	pop	xde
	and	c, 3
	jr	z, 85
	ldda8	a, 37168
	and	a, 3
	cps	a, 1
	jr	z, 26
	cps	a, 2
	jr	nz, 47
	stdi8	37203, 1
	stdi8	37204, 12
	stdi8	37205, 11
	lds	wa, 2
	ldw	bc, 255
	jr	20
	stdi8	37203, 255
	stdi8	37204, 255
	stdi8	37205, 0
	lds	wa, 1
	ldw	bc, 255
	calr	3056
	jr	23
	ldada	xbc, 64772
	ld	a, (xbc)
	cps	a, 5
	ret	z
	ld	(xbc), 5
	stdi8	37161, 5
	stdi8	37162, 255
	.byte 0xc1
	pushw	bc
	.byte 0x91
	push	xsp
	halt
	jr	nz, 5
	stdi8	36156, 24
	jrl	2496
ExtData_Voice_CheckMode3:
	calr	2462
	ldda8	a, 37167
	cps	a, 3
	ret	nz
	calr	63863
	ret
ExtData_Voice_RetEntry2:
	ret
ExtData_Voice_FullHandler:
	calr	2446
	ldda8	a, 37167
	cp	a, 11
	jr	z, 19
	cps	a, 2
	jr	z, 58
	cps	a, 4
	jrl	z, -1696
	cps	a, 3
	jr	z, 30
	cps	a, 1
	ret	nz
	jr	4
	calr	59
	ret
	ldw	wa, 128
	calr	3068
	.byte 0xc1
	ldw	de, 15505
	.byte 0x80
	ldw	wa, 127
	calr	2612
	jrl	2425
	ldda8	a, 37168
	andda8	a, 37169
	ret	z
	lds	wa, 1
	calr	2505
	calr	2407
	ret
	.byte 0xf1
	swi	1
	.byte 0x90
	lda	xwa, (xbc)
	ld	xwa, 198254080
	ldw	wa, 128
	calr	3019
	jrl	2387
	.byte 0xd7
	swi	2
	.byte 0x04
	ldda8	a, 64929
	and	a, 192
	.byte 0xc7
	swi	3
	.byte 0x99
	ldw	wa, 128
	calr	2463
	ldw	wa, 64
	calr	2457
	ldada	xde, 64929
	ld	c, (xde)
	ld	a, c
	and	a, 192
	cp	a, 192
	jr	nz, 16
	.byte 0xf1
	pushw	de
	.byte 0x91
	inc	6, l
	halt
	res	6, c
	jr	3
	res	7, c
	ld	(xde), c
	.byte 0x82
	pop_f
	pushw	bc
	ld	hl, (xbc)
	nop
	stdi8	37162, 0
	ld	l, (xde)
	and	l, 128
	.byte 0xc7
	swi	3
	and	(xbc-55), d
	and	(xwa), l
	.byte 0xf1
	jr	z, 7
	set	7, c
	stda8	37162, c
	ld	c, (xde)
	and	c, 64
	.byte 0xc7
	swi	3
	and	(xbc-55), d
	ld	xwa, 73855435
	.byte 0xf1
	pushw	de
	.byte 0x91, 0xbe
	calr	2275
	.byte 0xd7
	swi	2
	halt
	ret
ExtData_Voice_CopyAndJump:
	.byte 0xc1
	ldw	wa, 6545
	pushw	bc
	.byte 0x91, 0xc1
	ldw	bc, 6545
	pushw	de
	.byte 0x91
	jrl	2256
ExtData_Voice_CompareAndDispatch:
	ldda8	a, 37167
	cps	a, 0
	jr	z, 7
	cps	a, 1
	ret	nz
	jrl	140
	calr	1
	ret
	ldda8	a, 36582
	set	7, a
	stda8	36578, a
	calr	3135
	stdi8	37246, 176
	stdi8	37247, 0
	.byte 0xc1
	ldw	wa, 6545
	.byte 0x80, 0x91, 0xc1
	ldw	bc, 6545
	.byte 0x81, 0x91
	jp	MIDI_LoadParamsAndDispatchCC

MidiChannel_ResetAndConfigure:
	resda 7, 10414
	ldda8 a, 36580
	set 7, a
	stda8 36576, a
	bitda 7, 36580
	ret z
	calr Audio_FlushPendingBankSelects
	stdi8 37159, 176
	stdi8 37160, 1
	ldda8 a, 36580
	res 7, a
	stda8 37161, a
	stdi8 37162, 127
	ldda8 e, 37161
	extz de
	pushw 0x7f
	ldw wa, 0xb0
	lds bc, 1
	call AddswbWr
	ldmm8 37246, 37159
	ldmm8 37247, 37160
	ldmm8 37248, 37161
	stdi8 37249, 127
	call MIDI_LoadParamsAndDispatchCC
	ret

MidiCh_ConfigVoiceAndParts:
	ldda8	a, 36576
	res	7, a
	stda8	36576, a
	ldda8	c, 36580
	cp	c, a
	ret	z
	ldda8	a, 10414
	bit	7, a
	jr	z, 37
	stda8	9828, c
	ldda8	e, 10414
	ld	l, e
	res	7, l
	cp	l, c
	jr	ule, 6
	sub	l, c
	ld	c, l
	jr	2
	sub	c, l
	cp	c, 16
	jr	c, 17
	res	7, e
	stda8	10414, e
	.byte 0xc1, 0xe4, 0x8e
	pop_f
	.byte 0xe0, 0x8e, 0xf1, 0xe4, 0x8e, 0xbf, 0xf1, 0xe4
	.byte 0x8e
	sbc	w, l
	.byte 0xf6
	calr	2929
	stdi8	37159, 176
	stdi8	37160, 1
	ldda8	a, 36580
	res	7, a
	stda8	37161, a
	stdi8	37162, 127
	calr	1988
	.byte 0xc1
	ldb	l, 145
	pop_f
	jrl	nz, -15983
	pushw	wa
	.byte 0x91
	pop_f
	jrl	nc, -15983
	ldw	wa, 6545
	.byte 0x80, 0x91, 0xc1
	ldw	bc, 6545
	.byte 0x81, 0x91
	call	MIDI_LoadParamsAndDispatchCC
	ret
MidiCh_IterateVolume_Forward:
	pushw	iz
	ldda8	a, 37169
	res	7, a
	cps	a, 0
	jr	z, 114
	lds	iz, 0
	ldada	xde, 37115
	ld	bc, iz
	extz	xbc
	add	xbc, xde
	ld	a, (xbc)
	cp	a, 255
	jr	z, 95
	cps	a, 2
	jr	nz, 6
	.byte 0x8a, 0x01
	push	xsp
	swi	7
	jr	nz, 77
	.byte 0xc1
	ldb	l, 145
	pop_f
	jrl	nz, -32367
	pop_f
	jrl	nc, -15983
	ldw	wa, 6545
	.byte 0x80, 0x91, 0xc1
	ldw	bc, 6545
	.byte 0x81, 0x91
	call	MIDI_LoadParamsAndDispatchCC
	ldada	xwa, 37115
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	a, (xbc)
	extz	wa
	calr	3812
	.byte 0xbb
	decf
	dec	6, e
	call	9501681
	ldw	wa, 35294
	extz	xbc
	add	xbc, xwa
	.byte 0x81
	pop_f
	pushw	wa
	.byte 0x91, 0xc1
	ldw	wa, 6545
	pushw	bc
	.byte 0x91, 0xc1
	ldw	bc, 6545
	pushw	de
	.byte 0x91
	calr	1841
	inc	1, iz
	cp	iz, 32
	jr	c, -112
	popw	iz
	ret
MidiCh_IterateVolume_Reverse:
	pushw	iz
	lds	iz, 0
	ldada	xde, 37115
	ld	bc, iz
	extz	xbc
	add	xbc, xde
	ld	a, (xbc)
	cp	a, 255
	jr	z, 95
	cps	a, 2
	jr	nz, 6
	.byte 0x8a, 0x01
	push	xsp
	swi	7
	jr	nz, 77
	.byte 0xc1
	ldb	l, 145
	pop_f
	jrl	nz, -32367
	pop_f
	jrl	nc, -15983
	ldw	wa, 6545
	.byte 0x80, 0x91, 0xc1
	ldw	bc, 6545
	.byte 0x81, 0x91
	call	MIDI_LoadParamsAndDispatchCC
	ldada	xwa, 37115
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	a, (xbc)
	extz	wa
	calr	3695
	.byte 0xbb
	decf
	dec	6, e
	call	9501681
	ldw	wa, 35294
	extz	xbc
	add	xbc, xwa
	.byte 0x81
	pop_f
	pushw	wa
	.byte 0x91, 0xc1
	ldw	wa, 6545
	pushw	bc
	.byte 0x91, 0xc1
	ldw	bc, 6545
	pushw	de
	.byte 0x91
	calr	1761
	inc	1, iz
	cp	iz, 32
	jr	c, -112
	popw	iz
	ret
MidiCh_IteratePan_Forward:
	pushw	iz
	ldda8	a, 37169
	res	7, a
	cps	a, 0
	jrl	z, 135
	lds	iz, 0
	ldada	xbc, 37115
	ld	wa, iz
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, 255
	jr	z, 116
	cps	a, 2
	jr	nz, 6
	.byte 0x89, 0x01
	push	xsp
	swi	7
	jr	nz, 97
	extz	wa
	calr	3604
	.byte 0xbb
	incf
	inc	6, d
	.byte 0x57, 0xc1
	ldb	l, 145
	pop_f
	jrl	nz, -3695
	swi	3
	.byte 0x90
	ldw	wa, 35294
	extz	xbc
	add	xbc, xwa
	.byte 0x81
	pop_f
	jrl	nc, -15983
	ldw	wa, 6545
	.byte 0x80, 0x91, 0xc1
	ldw	bc, 6545
	.byte 0x81, 0x91
	call	MIDI_LoadParamsAndDispatchCC
	ldada	xwa, 37115
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	a, (xbc)
	extz	wa
	calr	3546
	.byte 0xbb
	decf
	dec	6, e
	call	9501681
	ldw	wa, 35294
	extz	xbc
	add	xbc, xwa
	.byte 0x81
	pop_f
	pushw	wa
	.byte 0x91, 0xc1
	ldw	wa, 6545
	pushw	bc
	.byte 0x91, 0xc1
	ldw	bc, 6545
	pushw	de
	.byte 0x91
	calr	1575
	inc	1, iz
	cp	iz, 32
	jrl	c, -133
	popw	iz
	ret
MidiCh_IterateExpression:
	dec	2, xsp
	push	xiz
	ldda8	a, 37169
	res	7, a
	cps	a, 0
	jr	z, 125
	.byte 0xbf, 0x04
	push_sr
	nop
	nop
	ldada	xbc, 37115
	ld	wa, (xsp+4)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, 255
	jr	z, 102
	extz	wa
	calr	3459
	ld	xiz, xhl
	cp	xiz, 4294967295
	jr	z, 77
	.byte 0xbe, 0x04
	inc	6, e
	popw	wa
	.byte 0xc1
	ldb	l, 145
	pop_f
	jrl	nz, -3695
	swi	3
	.byte 0x90
	ldw	wa, 1183
	ldb	a, 233
	ccf
	add	xbc, xwa
	.byte 0x81
	pop_f
	jrl	nc, -15983
	ldw	wa, 6545
	.byte 0x80, 0x91, 0xc1
	ldw	bc, 6545
	.byte 0x81, 0x91
	call	MIDI_LoadParamsAndDispatchCC
	.byte 0xbe
	decf
	dec	6, e
	calr	64497
	.byte 0x90
	ldw	wa, 1183
	ldb	a, 233
	ccf
	add	xbc, xwa
	.byte 0x81
	pop_f
	pushw	wa
	.byte 0x91, 0xc1
	ldw	wa, 6545
	pushw	bc
	.byte 0x91, 0xc1
	ldw	bc, 6545
	pushw	de
	.byte 0x91
	calr	1435
	incm	1, (xsp+4)
	.byte 0x9f, 0x04
	push	xsp
	ldb	w, 0
	jr	c, -120
	pop	xiz
	inc	2, xsp
	ret

CtrlPanel_RefreshIndicatorState:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	ld xbc, 0x8f62
	calr CtrlPanel_CompareAndUpdateIndicators
	ld xwa, xiz
	calr CtrlPanel_BuildIndicatorBitmask
	ld xwa, xhl
	calr Part_BitmaskToIndexList
	ld xiy, xiz
	ld xix, 0x8f62
	ldw bc, 0xb3
	ldirw
	pop xiz
	ret

CtrlPanel_CompareAndUpdateIndicators:
	st_dri3b L, 0xfd, 0x8e, 0xfe
	push xiz
	st_dri3l XBC, 0xfd, 0x6e, 0x01
	st_dri3l XWA, 0xfd, 0x72, 0x01
	ld_sril XWA, (xsp + 0x0172)
	calr CtrlPanel_BuildIndicatorBitmask
	ld (xsp + 4), xhl
	ld_sril XWA, (xsp + 0x016e)
	calr CtrlPanel_BuildIndicatorBitmask
	ld xiz, xhl
	ld xwa, (xsp + 4)
	xor xwa, xiz
	and xwa, xiz
	calr Part_BitmaskToIndexList
	ld_sril XWA, (xsp + 0x016e)
	ld c, (xwa + 1)
	extz bc
	ldw wa, 0x80
	calr Audio_IteratePartsWithExpression
	ld_sril XWA, (xsp + 0x016e)
	ld c, (xwa + 1)
	extz bc
	lds wa, 0
	calr Audio_IteratePartsWithVolume
	ld_sril XWA, (xsp + 0x016e)
	ld c, (xwa + 1)
	extz bc
	lds wa, 0
	calr Audio_IteratePartsWithPan
	ld_sril XWA, (xsp + 0x016e)
	ld c, (xwa + 1)
	cp c, 0xff
	jr z, CtrlPanelRefresh_ProcessRemoved
	extz bc
	ldw wa, 0x7f
	calr MIDI_DispatchVoiceParamCC

CtrlPanelRefresh_ProcessRemoved:
	ld xwa, (xsp + 4)
	xor xwa, xiz
	and xwa, (xsp + 4)
	calr Part_BitmaskToIndexList
	ldda8 a, 36584
	extz wa
	ld_sril XBC, (xsp + 0x0172)
	ld c, (xbc + 1)
	extz bc
	calr Audio_IteratePartsWithExpression
	ldda8 a, 36586
	res 7, a
	extz wa
	ld_sril XBC, (xsp + 0x0172)
	ld c, (xbc + 1)
	extz bc
	calr Audio_IteratePartsWithVolume
	ldda8 a, 36596
	extz wa
	ld_sril XBC, (xsp + 0x0172)
	ld c, (xbc + 1)
	extz bc
	calr Audio_IteratePartsWithPan
	ld_sril XWA, (xsp + 0x0172)
	lda xbc, (xwa + 1)
	ld_sril XWA, (xsp + 0x016e)
	cp (xwa + 1), 0xff
	jr nz, CtrlPanelRefresh_DispatchVoiceCC
	cp (xbc), 0xff
	jr nz, CtrlPanelRefresh_CheckMigration

CtrlPanelRefresh_DispatchVoiceCC:
	ldda8 a, 36580
	res 7, a
	extz wa
	ld c, (xbc)
	extz bc
	calr MIDI_DispatchVoiceParamCC

CtrlPanelRefresh_CheckMigration:
	ld_sril XBC, (xsp + 0x016e)
	cp (xbc + 1), 0xff
	jr nz, CtrlPanelRefresh_Done
	ld_sril XWA, (xsp + 0x0172)
	cp (xwa + 1), 0xff
	jr z, CtrlPanelRefresh_Done
	ld xiy, xbc
	lda xix, (xsp + 8)
	ldw bc, 0xb3
	ldirw
	lda xwa, (xsp + 8)
	ormi8 (xwa), 0x7
	calr CtrlPanel_BuildIndicatorBitmask
	ld xiz, xhl
	ld xwa, (xsp + 4)
	xor xwa, xiz
	and xwa, xiz
	calr Part_BitmaskToIndexList
	ld_sril XWA, (xsp + 0x0172)
	ld c, (xwa + 1)
	extz bc
	ldw wa, 0x7f
	calr MIDI_DispatchVoiceParamCC
	ld xwa, (xsp + 4)
	xor xwa, xiz
	and xwa, (xsp + 4)
	calr Part_BitmaskToIndexList
	ldda8 a, 36580
	res 7, a
	extz wa
	ld_sril XBC, (xsp + 0x0172)
	ld c, (xbc + 1)
	extz bc
	calr MIDI_DispatchVoiceParamCC

CtrlPanelRefresh_Done:
	pop xiz
	st_dri3b L, 0xfd, 0x72, 0x01
	ret

CtrlPanel_BuildIndicatorBitmask:
	push xiz
	lds32 xiz, 0
	lda_24 xde, 0xedb33e
	ld c, (xwa + 1)
	cp c, 0xff
	jr nz, IndBitmask_LookupByChannel
	ld c, (xwa)
	lds32 xiz, 0
	ldfr_berp C, 0xf8
	and xiz, 0x7
	ld_srib A, (xwa + 0x00be)
	cp a, 0xff
	jr z, IndBitmask_ReturnResult
	extz wa
	ld_srib3 A, 0x07, 0xe8, 0xe0
	jr IndBitmask_ApplyResult

IndBitmask_LookupByChannel:
	extz bc
	ld_srib3 A, 0x07, 0xe8, 0xe4

IndBitmask_ApplyResult:
	call CtrlPanel_LookupIndicatorEntry
	or xiz, xhl

IndBitmask_ReturnResult:
	ld xhl, xiz
	pop xiz
	ret

Part_BitmaskToIndexList:
	lds iy, 0
	ldada xde, 37115
	ld (xde), 0xff
	lds hl, 0

BitmaskToIndex_ScanLoop:
	or xwa, xwa
	jr z, BitmaskToIndex_Terminate
	bit 0, wa
	jr z, BitmaskToIndex_ShiftAndAdvance
	ld bc, iy
	inc 1, iy
	ld ix, bc
	extz xix
	add xix, xde
	ld c, l
	ld (xix), c

BitmaskToIndex_ShiftAndAdvance:
	srl xwa, 1
	inc 1, hl
	cp hl, 0x20
	jr c, BitmaskToIndex_ScanLoop

BitmaskToIndex_Terminate:
	ld wa, iy
	extz xwa
	add xwa, xde
	ld (xwa), 0xff
	ret

Audio_IteratePartsWithVolume:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), c
	ld (xsp + 4), a
	lds iz, 0

VolumeIter_NextPart:
	ldada xwa, 37115
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	cp a, 0xff
	jr z, VolumeIter_Done
	cps a, 2
	jr nz, VolumeIter_ApplyParam
	cp (xsp + 2), 0x2
	jr nz, VolumeIter_AdvancePart

VolumeIter_ApplyParam:
	stdi8 37246, 178
	mrib4 0x81, 0x19, 0x7f, 0x91
	mrdb5 0x8f, 0x04, 0x19, 0x80, 0x91
	stdi8 37249, 127
	call MIDI_LoadParamsAndDispatchCC
	ldada xwa, 37115
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	calr VoiceData_LookupPtrByIndex
	bitm 5, (xhl + 13)
	jr nz, VolumeIter_AdvancePart
	ldda8 a, 37246
	extz wa
	ldda8 c, 37247
	extz bc
	ldda8 e, 37248
	extz de
	ldda8 l, 37249
	extz hl
	pushw hl
	call AddswbWr

VolumeIter_AdvancePart:
	inc 1, iz
	cp iz, 0x20
	jr c, VolumeIter_NextPart

VolumeIter_Done:
	popw iz
	inc 4, xsp
	ret

Audio_IteratePartsWithExpression:
	dec 2, xsp
	push xiz
	ld (xsp + 4), c
	ld c, a
	sll c, 6
	and c, 0x40
	ldfr_berp C, 0xfa
	srl a, 1
	ldfr_berp A, 0xfb
	res_erpb 0xfb, 0x07
	ldto_berp C, 0xfb
	extz bc
	sll bc, 8
	ldto_berp A, 0xfa
	extz wa
	add wa, bc
	cp wa, 0x7f40
	jr c, ExprIter_Start
	ldi_erpb 0xfb, 0x7f
	ldi_erpb 0xfa, 0x7f

ExprIter_Start:
	lds iz, 0

ExprIter_NextPart:
	ldada xwa, 37115
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	cp a, 0xff
	jr z, ExprIter_Done
	cps a, 2
	jr nz, ExprIter_ApplyParam
	cp (xsp + 4), 0x2
	jr nz, ExprIter_AdvancePart

ExprIter_ApplyParam:
	stdi8 37246, 177
	mrib4 0x81, 0x19, 0x7f, 0x91
	ldto_berp A, 0xfa
	stda8 37248, a
	ldto_berp A, 0xfb
	stda8 37249, a
	call MIDI_LoadParamsAndDispatchCC
	ldada xwa, 37115
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	calr VoiceData_LookupPtrByIndex
	bitm 5, (xhl + 13)
	jr nz, ExprIter_AdvancePart
	ldda8 a, 37246
	extz wa
	ldda8 c, 37247
	extz bc
	ldda8 e, 37248
	extz de
	ldda8 l, 37249
	extz hl
	pushw hl
	call AddswbWr

ExprIter_AdvancePart:
	inc 1, iz
	cp iz, 0x20
	jr c, ExprIter_NextPart

ExprIter_Done:
	pop xiz
	inc 2, xsp
	ret

Audio_IteratePartsWithPan:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), c
	ld (xsp + 4), a
	lds iz, 0

PanIter_NextPart:
	ldada xbc, 37115
	ld wa, iz
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xff
	jr z, PanIter_Done
	cps a, 2
	jr nz, PanIter_ApplyParam
	cp (xsp + 2), 0x2
	jr nz, MidiLoadParams_ContinueLoop

PanIter_ApplyParam:
	extz wa
	calr VoiceData_LookupPtrByIndex
	bitm 4, (xhl + 12)
	jr z, MidiLoadParams_ContinueLoop
	stdi8 37246, 180
	ldada xwa, 37115
	ld bc, iz
	extz xbc
	add xbc, xwa
	mrib4 0x81, 0x19, 0x7f, 0x91
	mrdb5 0x8f, 0x04, 0x19, 0x80, 0x91
	stdi8 37249, 255
	call MIDI_LoadParamsAndDispatchCC
	ldada xwa, 37115
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	calr VoiceData_LookupPtrByIndex
	bitm 5, (xhl + 13)
	jr nz, MidiLoadParams_ContinueLoop
	ldda8 a, 37246
	extz wa
	ldda8 c, 37247
	extz bc
	ldda8 e, 37248
	extz de
	ldda8 l, 37249
	extz hl
	pushw hl
	call AddswbWr

MidiLoadParams_ContinueLoop:
	inc 1, iz
	cp iz, 0x20
	jrl c, PanIter_NextPart

PanIter_Done:
	popw iz
	inc 4, xsp
	ret

MIDI_DispatchVoiceParamCC:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), a
	cpdi8 64818, 183
	jr nz, VoiceParamCC_Done
	lds iz, 0

VoiceParamCC_NextPart:
	ldada xbc, 37115
	ld wa, iz
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xff
	jr z, VoiceParamCC_Done
	extz wa
	calr VoiceData_LookupPtrByIndex
	bitm 5, (xhl + 4)
	jr z, VoiceParamCC_AdvancePart
	stdi8 37246, 179
	ldada xwa, 37115
	ld bc, iz
	extz xbc
	add xbc, xwa
	mrib4 0x81, 0x19, 0x7f, 0x91
	mrdb5 0x8f, 0x02, 0x19, 0x80, 0x91
	stdi8 37249, 127
	call MIDI_LoadParamsAndDispatchCC
	ldada xwa, 37115
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	calr VoiceData_LookupPtrByIndex
	bitm 5, (xhl + 13)
	jr nz, VoiceParamCC_AdvancePart
	ldda8 a, 37246
	extz wa
	ldda8 c, 37247
	extz bc
	ldda8 e, 37248
	extz de
	ldda8 l, 37249
	extz hl
	pushw hl
	call AddswbWr

VoiceParamCC_AdvancePart:
	inc 1, iz
	cp iz, 0x20
	jr c, VoiceParamCC_NextPart

VoiceParamCC_Done:
	popw iz
	inc 2, xsp
	ret

UIState_CheckAndRenderBitmap:
	pushw	iz
	.byte 0xc1
	jrl	pl, 16320
	push_sr
	jr	nz, 67
	ldda8	a, 49279
	and	a, 255
	jr	z, 58
	ldda8	a, 49278
	and	a, 255
	cp	a, 183
	jr	z, 32
	cp	a, 182
	jr	nz, 41
	lds	iz, 0
	pushw	3
	ld	wa, iz
	ldw	bc, 11
	ldw	de, 127
	call	SndParam_NotifyAndReturn
	inc	1, iz
	cp	iz, 15
	jr	ule, -23
	jr	14
	ld	xwa, 16385
	ldw	bc, 127
	lds	de, 3
	call	SoundParam_NotifyChange
	popw	iz
	ret
UIState_RenderBitmapData:
	.byte 0xc1
	jrl	pl, 16320
	halt
	jr	nz, 38
	ldda8	a, 49279
	res	7, a
	cps	a, 0
	jr	z, 27
	ldda8	c, 49278
	res	7, c
	cps	c, 0
	jr	z, 16
	ldda8	a, 49280
	extz	wa
	ldada	xde, 37261
	extz	xwa
	add	xwa, xde
	ld	(xwa), c
	.byte 0xc1
	jrl	pl, 16320
	incf
	jr	nz, 30
	.byte 0xf1
	jrl	nc, -13120
	jr	z, 24
	.byte 0xf1
	jrl	nz, -13120
	jr	nz, 18
	ldda8	a, 49280
	extz	wa
	pushw	3
	ldw	bc, 434
	lds	de, 0
	call	SndParam_NotifyAndReturn
	.byte 0xc1
	jrl	pl, 16320
	.byte 0x04
	ret	nz
	.byte 0xf1
	jrl	nc, -12864
	ret	z
	.byte 0xf1
	jrl	nz, -12864
	ret	nz
	ldda8	a, 49280
	extz	wa
	pushw	3
	ldw	bc, 11
	ldw	de, 127
	call	SndParam_NotifyAndReturn
	ret
ToshiCmd_DefaultHandler_Ret:
	ret

SndParam_FetchSequencerParams:
	ldda16 xwa, 37171
	ld bc, wa
	inc 1, wa
	stda16 37171, xwa
	ldada xwa, 49209
	extz xbc
	add xbc, xwa
	mrib4 0x81, 0x19, 0x27, 0x91
	ldda8 a, 37159
	extz wa
	calr VoiceData_LookupPtrByIndex
	stda32 37163, xhl
	ldda16 xwa, 37171
	ld de, wa
	inc 1, wa
	stda16 37171, xwa
	ldada xbc, 49209
	extz xde
	add xde, xbc
	ld a, (xde)
	stda8 37160, a
	stda8 37167, a
	ldda16 xwa, 37171
	ld de, wa
	inc 1, wa
	stda16 37171, xwa
	extz xde
	add xde, xbc
	mrib4 0x82, 0x19, 0x30, 0x91
	stdi8 37161, 0
	ldda16 xwa, 37171
	ld de, wa
	inc 1, wa
	stda16 37171, xwa
	extz xde
	add xde, xbc
	mrib4 0x82, 0x19, 0x31, 0x91
	stdi8 37162, 0
	ret

SndParam_WriteLookupAndStore:
	ldda8	a, 37159
	extz	wa
	calr	1959
	cp	xhl, 4294967295
	ret	z
	ldda8	a, 37167
	extz	wa
	.byte 0xc3
	reti
	or	xwa, xix
	pop_f
	ldw	de, 3729

SwbtWr_FlushAndAppendParams:
	cpdi8 37162, 0
	ret z
	cpdi16 37086, 508
	jr c, SwbtWr_FlushDone
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	pop xix
	pop xhl
	pop xde
	stdi16 37086, 0

SwbtWr_FlushDone:
	calr SwbtWr_AppendFixedParamBlock
	ret

SwbtWr_CheckBufferOverflow:
	cpdi16	37086, 508
	jr	c, 18
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SwbtWr_ReinitBothBanks
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	stdi16	37086, 0
	jrl	1770

SwbtWr_WriteParamBlock:
	cpdi16 37086, 508
	jr c, SwbtWr_WriteParamBlock_Body
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	stdi16 37086, 0

SwbtWr_WriteParamBlock_Body:
	jrl SwbtWr_AppendFixedParamBlock
	dec 2, xsp
	ld (xsp), a
	ldda8 c, 37169
	ld a, c
	and a, (xsp)
	jr z, Voice_Update_Return
	ldda8 a, 37168
	and a, c
	jr z, Voice_Update_Return
	ldda8 a, 37159
	extz wa
	calr VoiceData_LookupPtrByIndex
	cp xhl, 0xffffffff
	jr z, Voice_Update_Return
	ldda8 a, 37167
	extz wa
	st_dri3b C, 0x07, 0xec, 0xe0
	ldda8 a, 37168
	andda8 a, 37169
	xor (xhl), a
	ldda8 c, 37170
	cp (xhl), c
	jr z, Voice_Update_Return
	ld a, (xhl)
	xor a, c
	and a, (xsp)
	orddm8 37162, a
	mrib4 0x83, 0x19, 0x32, 0x91
	mrib4 0x83, 0x19, 0x29, 0x91

Voice_Update_Return:
	inc 2, xsp
	ret

VoiceParam_CompareAndUpdate:
	dec	2, xsp
	ld	(xsp), a
	ldda8	a, 37169
	.byte 0x87
	andda8	a, 18534
	ldw	wa, 8593
	.byte 0x87
	andda8	a, 16486
	ldb	l, 145
	ldb	a, 216
	ccf
	calr	1724
	cp	xhl, 4294967295
	jr	z, 47
	ldda8	a, 37167
	extz	wa
	.byte 0xf3
	reti
	or	xwa, xix
	ldw	hl, 8583
	cpl	a
	.byte 0x83, 0xc1
	orda8	a, 37168
	ld	c, a
	ldda8	a, 37170
	cp	c, a
	jr	z, 16
	ld	(xhl), c
	stda8	37170, c
	stda8	37161, c
	ld	a, (xsp)
	orddm8	37162, a
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ldda8	a, 37169
	.byte 0x87
	andda8	a, 16486
	ldb	l, 145
	ldb	a, 216
	ccf
	calr	1645
	cp	xhl, 4294967295
	jr	z, 47
	ldda8	a, 37167
	extz	wa
	.byte 0xf3
	reti
	or	xwa, xix
	ldw	hl, 8583
	cpl	a
	.byte 0x83, 0xc1
	orda8	a, 37168
	ld	c, a
	ldda8	a, 37170
	cp	c, a
	jr	z, 16
	ld	(xhl), c
	stda8	37170, c
	stda8	37161, c
	ld	a, (xsp)
	orddm8	37162, a
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ldda8	a, 37169
	.byte 0x87
	andda8	a, 19046
	ldw	wa, 8593
	.byte 0x87
	andda8	a, 16998
	ldb	l, 145
	ldb	a, 216
	ccf
	calr	1558
	cp	xhl, 4294967295
	jr	z, 49
	ldda8	a, 37167
	extz	wa
	.byte 0xf3
	reti
	or	xwa, xix
	ldw	hl, 9095
	cpl	c
	ld	e, c
	.byte 0x83, 0xc5
	orda8	e, 37168
	ldda8	a, 37170
	cp	e, a
	jr	nz, 2
	and	e, c
	ld	(xhl), e
	stda8	37170, e
	stda8	37161, e
	ld	a, (xsp)
	orddm8	37162, a
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ldda8	a, 37169
	.byte 0x87
	andda8	a, 16998
	ldb	l, 145
	ldb	a, 216
	ccf
	calr	1477
	cp	xhl, 4294967295
	jr	z, 49
	ldda8	a, 37167
	extz	wa
	.byte 0xf3
	reti
	or	xwa, xix
	ldw	hl, 9095
	cpl	c
	ld	e, c
	.byte 0x83, 0xc5
	orda8	e, 37168
	ldda8	a, 37170
	cp	e, a
	jr	nz, 2
	and	e, c
	ld	(xhl), e
	stda8	37170, e
	stda8	37161, e
	ld	a, (xsp)
	orddm8	37162, a
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), c
	ldda8	c, 37169
	and	c, a
	jr	z, 94
	ldda8	c, 37168
	and	c, a
	jr	z, 86
	ldda8	a, 37159
	extz	wa
	calr	1388
	cp	xhl, 4294967295
	jr	z, 69
	ldda8	a, 37167
	extz	wa
	.byte 0xf3
	reti
	or	xwa, xix
	ldw	hl, 9603
	.byte 0x87, 0xc5
	ldda8	c, 37203
	ld	a, e
	add	a, c
	.byte 0xc1, 0x54, 0x91, 0xf1
	jr	nc, 4
	add	e, c
	jr	4
	ldda8	e, 37205
	ld	a, (xsp)
	cpl	a
	.byte 0x83
	andda8	a, 58825
	ldw	de, 8593
	cp	e, a
	jr	z, 16
	ld	(xhl), e
	stda8	37170, e
	stda8	37161, e
	ld	a, (xsp)
	orddm8	37162, a
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ldda8	a, 37169
	.byte 0x87
	andda8	a, 15462
	ldb	l, 145
	ldb	a, 216
	ccf
	calr	1287
	cp	xhl, 4294967295
	jr	z, 43
	ldda8	a, 37167
	extz	wa
	.byte 0xf3
	reti
	or	xwa, xix
	ldw	hl, 8583
	cpl	a
	.byte 0x83
	andda8	a, 35785
	ldw	wa, 8593
	.byte 0x87, 0xc1
	or	a, c
	ld	(xhl), a
	stda8	37170, a
	stda8	37161, a
	ld	a, (xsp)
	orddm8	37162, a
	inc	2, xsp
	ret

ToneGen_ApplyVoiceParams:
	dec 6, xsp
	ld (xsp), e
	ld (xsp + 2), c
	ld (xsp + 4), a
	cp (xsp + 10), 0x0
	jr z, ToneGen_DispatchStartVoice
	ld a, (xsp + 4)
	extz wa
	calr VoiceData_LookupPtrByIndex
	cp xhl, 0xffffffff
	jr z, ToneGen_DispatchStartVoice
	ld a, (xsp + 2)
	extz wa
	st_dri3b C, 0x07, 0xec, 0xe0
	ld c, (xhl)
	stda8 37170, c
	ld e, (xsp)
	and e, (xsp + 10)
	ld a, (xsp + 10)
	cpl a
	and a, c
	or a, e
	ld e, a
	xor a, c
	and a, (xsp + 10)
	jr z, ToneGen_DispatchStartVoice
	ld (xhl), e
	mrdb5 0x8f, 0x04, 0x19, 0x27, 0x91
	mrdb5 0x8f, 0x02, 0x19, 0x28, 0x91
	stda8 37161, e
	stda8 37162, a

ToneGen_DispatchStartVoice:
	inc 6, xsp
	retd 0x2
	dec 6, xsp
	push_werp 0xfa
	cpdi8 49277, 3
	jr nz, ToneGen_Dispatch_Return
	bitda 0, 49279
	jr z, ToneGen_Dispatch_Return
	ldw wa, 0x90
	calr VoiceData_LookupPtrByIndex
	ld (xsp + 2), xhl
	ld xbc, (xsp + 2)
	ld a, (xbc)
	ldfr_berp A, 0xfb
	ld a, (xbc + 1)
	ld (xsp + 6), a
	call ToneGen_DispatchByMode
	ldto_berp C, 0xfb
	ld xwa, (xsp + 2)
	xor c, (xwa)
	and c, 0x3
	jr z, ToneGen_Dispatch_Return
	ld c, (xsp + 6)
	xor c, (xwa + 1)
	bit 1, c
	jr z, ToneGen_Dispatch_Return
	ld e, (xwa)
	extz de
	pushw 0x1f
	ldw wa, 0x90
	lds bc, 0
	call AddswbWr
	ld xwa, (xsp + 2)
	ld e, (xwa + 1)
	extz de
	pushw 0x1f
	ldw wa, 0x90
	lds bc, 1
	call AddswbWr

ToneGen_Dispatch_Return:
	pop_werp 0xfa
	inc 6, xsp
	ret

SwbtWr_NullRet:
	ret

Audio_FlushPendingBankSelects:
	ldda8 a, 36578
	bit 7, a
	jr z, BankFlush_CheckChannel1
	res 7, a
	stda8 36578, a
	stdi8 37159, 176
	stdi8 37160, 0
	stda8 37161, a
	stdi8 37162, 127
	calr SwbtWr_FlushAndAppendParams

BankFlush_CheckChannel1:
	ldda8 a, 36576
	bit 7, a
	ret z
	res 7, a
	stda8 36576, a
	stdi8 37159, 176
	stdi8 37160, 1
	stda8 37161, a
	stdi8 37162, 127
	calr SwbtWr_FlushAndAppendParams
	ret

UIWidget_MidiStreamControl:
	.byte 0xc1
	jrl	pl, 16320
	nop
	ret	nz
	ldda8	a, 49279
	and	a, 3
	.byte 0xf2
	jr	nov, -102
	swi	4
	cp	xbc, xiz
	jrl	nc, -13632
	ret	z
	.byte 0xf1
	jrl	nz, -13632
	ret	nz
	.byte 0xf1
	swi	1
	.byte 0x90, 0xbc
	call	SeqTimer_UpdateTempoReg
	.byte 0xf1
	swi	1
	.byte 0x90, 0xb4
	ret
	lds	wa, 0
	ldada	xbc, 37842
	.byte 0xf5, 0xe4
	nop
	nop
	.byte 0xf5, 0xe4
	nop
	nop
	inc	1, wa
	cp	wa, 32
	jr	c, -16
	lds	wa, 0
	ldada	xbc, 37906
	.byte 0xf5, 0xe4
	nop
	nop
	inc	1, wa
	cp	wa, 32
	jr	c, -12
	ret

SndParam_ApplyAndFetch:
	dec 6, xsp
	lda xwa, (xsp)
	ldada xde, 37098
	ld c, (xde)
	ld (xwa), c
	ld c, (xde + 1)
	ld (xwa + 1), c
	ld c, (xde + 2)
	ld (xwa + 2), c
	cp c, 0x1f
	jr ugt, SndParam_CheckRhythm
	call SndParam_ApplyProgramChange
	ldada xde, 37102
	lda xbc, (xsp)
	ld a, (xbc + 3)
	ld (xde), a
	ld a, (xbc + 4)
	ld (xde + 1), a
	jr SndParam_ApplyDone

SndParam_CheckRhythm:
	cp c, 0x48
	call_24 z, 0xf53302

SndParam_ApplyDone:
	inc 6, xsp
	ret

SndParam_ApplyFromPointer:
	push	xiz
	ld	xiz, xwa
	lda	xde, (xiz+2)
	ld	a, (xde)
	cp	a, 31
	jr	ugt, 8
	ld	xwa, xiz
	call	SndParam_ApplyProgramChange
	jr	43
	cp	a, 72
	jr	nz, 38
	ldada	xbc, 37098
	ld	a, (xiz)
	ld	(xbc), a
	ld	a, (xiz+1)
	ld	(xbc+1), a
	ld	a, (xde)
	ld	(xbc+2), a
	call	Rhythm_LookupTempoVelocity_Wrap
	ldada	xbc, 37102
	ld	a, (xbc)
	ld	(xiz+3), a
	ld	a, (xbc+1)
	ld	(xiz+4), a
	pop xiz
	ret

SndParam_FetchAndStore:
	dec 6, xsp
	lda xwa, (xsp)
	ldada xde, 37098
	ld c, (xde)
	ld (xwa + 3), c
	ld c, (xde + 1)
	ld (xwa + 4), c
	ld c, (xde + 2)
	ld (xwa + 2), c
	cp c, 0x1f
	jr ugt, SndParam_FetchCheckRhythm
	call SndParam_FetchOscTableEntry
	ldada xde, 37102
	lda xbc, (xsp)
	ld a, (xbc)
	ld (xde), a
	ld a, (xbc + 1)
	ld (xde + 1), a
	jr SndParam_FetchDone

SndParam_FetchCheckRhythm:
	cp c, 0x48
	call_24 z, 0xf53309

SndParam_FetchDone:
	inc 6, xsp
	ret

SndParam_ResolveVoiceEntry:
	push xiz
	ld xiz, xwa
	lda xde, (xiz + 2)
	ld a, (xde)
	cp a, 0x1f
	jr ugt, SndParamResolve_CheckRhythm
	ld xwa, xiz
	call SndParam_FetchOscTableEntry
	jr SndParamResolve_Done

SndParamResolve_CheckRhythm:
	cp a, 0x48
	jr nz, SndParamResolve_Done
	ldada xbc, 37098
	ld a, (xiz + 3)
	ld (xbc), a
	ld a, (xiz + 4)
	ld (xbc + 1), a
	ld a, (xde)
	ld (xbc + 2), a
	call Rhythm_DispatchNote_Finalize
	ldada xbc, 37102
	ld a, (xbc)
	ld (xiz), a
	ld a, (xbc + 1)
	ld (xiz + 1), a

SndParamResolve_Done:
	pop xiz
	ret

SndBuf_WriteParamEntries:
	dec	6, xsp
	lda	xwa, (xsp)
	ldada	xde, 37098
	ld	c, (xde)
	ld	(xwa), c
	ld	c, (xde+1)
	ld	(xwa+1), c
	ld	c, (xde+2)
	ld	(xwa+2), c
	ld	c, (xde+3)
	ld	(xwa+5), c
	call	SndParam_CheckAndApplyMode
	ldada	xde, 37102
	lda	xbc, (xsp)
	ld	a, (xbc+3)
	ld	(xde), a
	ld	a, (xbc+4)
	ld	(xde+1), a
	inc	6, xsp
	ret
	dec	6, xsp
	lda	xwa, (xsp)
	ldada	xde, 37098
	ld	c, (xde)
	ld	(xwa+3), c
	ld	c, (xde+1)
	ld	(xwa+4), c
	ld	c, (xde+2)
	ld	(xwa+5), c
	call	SndParam_ComputeVoiceIndex
	ldada	xde, 37102
	lda	xbc, (xsp)
	ld	a, (xbc)
	ld	(xde), a
	ld	a, (xbc+1)
	ld	(xde+1), a
	ld	a, (xbc+2)
	ld	(xde+2), a
	inc	6, xsp
	ret
	dec	6, xsp
	ldda8	a, 37111
	ldada	xbc, 37231
	lda	xde, (xbc+1)
	cp	a, 31
	jr	ugt, 48
	lda	xwa, (xsp)
	ld	c, (xbc)
	ld	(xwa+3), c
	ld	c, (xde)
	ld	(xwa+4), c
	.byte 0xb8
	push_sr
	push_a
	ldx
	.byte 0x90
	call	16705512
	ldada	xbc, 37102
	lda	xwa, (xsp)
	ld	l, (xwa)
	ld	(xbc), l
	ldada	xde, 37227
	ld	(xde), l
	ld	a, (xwa+1)
	ld	(xbc+1), a
	ld	(xde+1), a
	jr	36
	cp	a, 72
	jr	nz, 31
	ldada	xhl, 37098
	ld	a, (xbc)
	ld	(xhl), a
	ld	a, (xde)
	ld	(xhl+1), a
	.byte 0xbb
	push_sr
	push_a
	ldx
	.byte 0x90
	nop
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	Rhythm_DispatchNote_Finalize
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ldada	xde, 37235
	ldada	xbc, 37102
	ld	a, (xbc)
	ld	(xde), a
	ld	a, (xbc+1)
	ld	(xde+1), a
	ld	a, (xbc+3)
	ld	(xde+2), a
	inc	6, xsp
	ret

SndParam_UpdateVoiceEntry:
	dec 8, xsp
	push_werp 0xfa
	ld (xsp + 4), e
	ld (xsp + 6), c
	ld (xsp + 8), a
	cp (xsp + 8), 0x1f
	jr ugt, SndParamUpdate_Done
	ld a, (xsp + 6)
	extz wa
	ld c, (xsp + 4)
	extz bc
	call ApplyProgramChangeAs_Prologue
	ldi_berp 0xfb, 0
	cps l, 0
	jr z, SndParamUpdate_SetResBit6
	ldi_erpb 0xfb, 0x40

SndParamUpdate_SetResBit6:
	ld (xsp + 2), 0x40
	ld c, (xsp + 4)
	extz bc
	sll bc, 8
	ld a, (xsp + 6)
	extz wa
	add wa, bc
	call MIDI_ParamValidate_CheckBit2
	cps hl, 0
	jr z, SndParamUpdate_DispatchWrite
	ldi_berp 0xfb, 0
	setm 3, (xsp + 2)

SndParamUpdate_DispatchWrite:
	ld a, (xsp + 8)
	extz wa
	ldto_berp E, 0xfb
	extz de
	ld c, (xsp + 2)
	extz bc
	pushw bc
	lds bc, 4
	calr ToneGen_ApplyVoiceParams
	ldda8 a, 37162
	and a, 0x48
	call_24 nz, 0xfc9663

SndParamUpdate_Done:
	pop_werp 0xfa
	inc 8, xsp
	ret

MIDI_DistributeParamToChannels:
	dec 8, xsp
	ld (xsp + 2), e
	ld (xsp + 4), c
	ld (xsp + 6), a
	cp (xsp + 6), 0x1f
	jr ugt, MidiDistribute_CheckRhythm
	call ApplyProgramChangeAs_DoLookupRe
	ld (xsp), l

MidiDistribute_LookupAndWrite:
	ld a, (xsp + 6)
	extz wa
	calr VoiceData_LookupPtrByChannel
	cp xhl, 0xffffffff
	jr z, MidiDistribute_Fallthrough
	ld c, (xsp + 4)
	cp c, (xsp)
	jr ugt, MidiDistribute_Fallthrough
	extz bc
	ld a, (xsp + 2)
	lda_dri3 XBC, 0x07, 0xec, 0xe4

MidiDistribute_Fallthrough:
	jr MidiDistribute_Done

MidiDistribute_CheckRhythm:
	cp (xsp + 6), 0x48
	jr nz, MidiDistribute_Done
	ld (xsp), 0xf
	jr MidiDistribute_LookupAndWrite

MidiDistribute_Done:
	inc 8, xsp
	ret

VoiceData_DistributeToChannels:
	dec	8, xsp
	ld	(xsp+4), c
	ld	(xsp+6), a
	ld	(xsp+2), 0
	.byte 0x8f, 0x06
	push	xsp
	.byte 0x1f
	jr	ugt, 44
	call	ApplyProgramChangeAs_DoLookupRe
	ld	(xsp), l
	ld	a, (xsp+6)
	extz	wa
	calr	163
	cp	xhl, 4294967295
	jr	z, 17
	ld	a, (xsp+4)
	.byte 0x87, 0xf1
	jr	ugt, 10
	extz	wa
	.byte 0xc3
	reti
	or	xwa, xix
	ldb	a, 191
	push_sr
	ld	xbc, 1747387023
	decf
	.byte 0x8f, 0x06
	push	xsp
	popw	wa
	jr	nz, 5
	ld	(xsp), 15
	jr	-49
	ldb	l, 0
	inc	8, xsp
	ret

SwbtWr_AppendFixedParamBlock:
	ldda16 xwa, 37086
	ld de, wa
	inc 1, wa
	stda16 37086, xwa
	ldada xbc, 48444
	extz xde
	add xde, xbc
	ldmi16 (xde), 0x9127
	ldda16 xwa, 37086
	ld de, wa
	inc 1, wa
	stda16 37086, xwa
	extz xde
	add xde, xbc
	ldmi16 (xde), 0x9128
	ldda16 xwa, 37086
	ld de, wa
	inc 1, wa
	stda16 37086, xwa
	extz xde
	add xde, xbc
	ldmi16 (xde), 0x9129
	ldda16 xwa, 37086
	ld de, wa
	inc 1, wa
	stda16 37086, xwa
	extz xde
	add xde, xbc
	ldmi16 (xde), 0x912a
	ldda16 xwa, 37086
	extz xwa
	add xwa, xbc
	ld (xwa), 0xff
	stdi8 37162, 0
	ret

VoiceData_LookupPtrByIndex:
	extz wa
	sla wa, 2
	lda_24 xbc, 0xedae64
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	ret

VoiceData_LookupPtrByChannel:
	cp a, 0x1f
	jr ugt, VoiceLookup_CheckRhythm
	extz wa
	sla wa, 2
	lda_24 xbc, 0xedb264
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	ret

VoiceLookup_CheckRhythm:
	cp a, 0x48
	jr nz, VoiceLookup_ReturnInvalid
	ldada xhl, 65426
	ret

VoiceLookup_ReturnInvalid:
	ld xhl, 0xffffffff
	ret

VoiceChannels_InitPanFromPreset:
	push xiz
	ldda16 xiz, 62096
	ldi_werp 0xfa, 0

VoicePanInit_Loop:
	ldada xwa, 37070
	ldto_werp BC, 0xfa
	extz xbc
	add xbc, xwa
	ld (xbc), 0x10
	bit 0, iz
	jr z, ToneGen_IncrementAndExit
	ldada xwa, 61856
	ldto_werp BC, 0xfa
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	lda_24 xbc, 0xedb358
	ld_srib3 A, 0x07, 0xe4, 0xe0
	calr VoiceData_LookupPtrByIndex
	cp xhl, 0xffffffff
	jr z, ToneGen_IncrementAndExit
	ld c, (xhl + 13)
	ld a, c
	and a, 0xc0
	jr nz, ToneGen_IncrementAndExit
	ldada xwa, 37070
	ldto_werp DE, 0xfa
	extz xde
	add xde, xwa
	and c, 0xf
	ld (xde), c

ToneGen_IncrementAndExit:
	srl iz, 1
	inc1_werp 0xfa
	cp_erpw 0xfa, 0x10, 0x00
	jr c, VoicePanInit_Loop
	pop xiz
	ret

; =============================================================================
; SoundPreset_FindMatch -- Find matching preset in ROM tables
; =============================================================================
; Compares current params against all presets to find active one.
; Args: a = type (0/1/2), bc = search params
; Returns: hl = matched index, or 0xffff if no match
SoundPreset_FindMatch:
	cps a, 2
	jrl z, SoundPreset_FindMatch_Combined
	cps a, 1
	jr z, EQPreset_FindMatch
	cps a, 0
	jr z, SoundPreset_FindMatch_Reverb
	ldw hl, 0xffff
	ret

SoundPreset_FindMatch_Reverb:
	pushw iz
	lds iz, 0

ReverbPreset_SearchLoop:
	pushw 0x18
	pushw 0x0
	pushw 0xfc8e
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, 0xedb36c
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	call Mem_Compare
	add xsp, 0xa
	cps hl, 0
	jr nz, ReverbPreset_NextEntry
	ld hl, iz
	jr ReverbPreset_SearchDone

ReverbPreset_NextEntry:
	inc 1, iz
	cp iz, 0xa
	jr c, ReverbPreset_SearchLoop
	ldw hl, 0xffff

ReverbPreset_SearchDone:
	popw iz
	ret

EQPreset_FindMatch:
	pushw iz
	lds iz, 0

EQPreset_SearchLoop:
	pushw 0x18
	pushw 0x0
	pushw 0xfca8
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, 0xedb394
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	call Mem_Compare
	add xsp, 0xa
	cps hl, 0
	jr nz, EQPreset_NextEntry
	ld hl, iz
	jr EQPreset_SearchDone

EQPreset_NextEntry:
	inc 1, iz
	cp iz, 0x9
	jr c, EQPreset_SearchLoop
	ldw hl, 0xffff

EQPreset_SearchDone:
	popw iz
	ret

SoundPreset_FindMatch_Combined:
	pushw iz
	lds iz, 0

CombinedPreset_SearchLoop:
	pushw 0x18
	pushw 0x0
	pushw 0xfc8e
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, 0xedb3b8
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	call Mem_Compare
	add xsp, 0xa
	cps hl, 0
	jr nz, CombinedPreset_NextEntry
	pushw 0x18
	pushw 0x0
	pushw 0xfca8
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, 0xedb3b8
	add xbc, xwa
	ld xwa, (xbc)
	lda xwa, (xwa + 24)
	push xwa
	call Mem_Compare
	add xsp, 0xa
	cps hl, 0
	jr nz, CombinedPreset_NextEntry
	ld hl, iz
	jr SoundPreset_ReturnResult

CombinedPreset_NextEntry:
	inc 1, iz
	cp iz, 0x9
	jr c, CombinedPreset_SearchLoop
	ldw hl, 0xffff

SoundPreset_ReturnResult:
	popw iz
	ret

; =============================================================================
; SoundPreset_Dispatch -- Route preset load by type (reverb/EQ/combined)
; =============================================================================
; Dispatches to the appropriate preset loader based on the type parameter:
;   type 0 -> ReverbPreset_Load (reverb-only, 24 bytes via cmd 0x63)
;   type 1 -> EQPreset_Load (EQ-only, 24 bytes via cmd 0x64)
;   type 2 -> CombinedPreset_Load (reverb+EQ, 48 bytes)
; Args: a = preset type (0/1/2), bc = preset index
; Called from: MainRevEqPresetLoad
SoundPreset_Dispatch:
	ld e, a
	extz bc
	cps e, 2
	jr z, SoundPreset_Dispatch_Combined
	cps e, 1
	jr z, SoundPreset_Dispatch_EQ
	cps e, 0
	ret nz
	ld wa, bc
	jr ReverbPreset_Load

SoundPreset_Dispatch_EQ:
	ld wa, bc
	jr EQPreset_Load

SoundPreset_Dispatch_Combined:
	ld wa, bc
	calr CombinedPreset_Load
	ret

; =============================================================================
; ReverbPreset_Load -- Load and send a reverb preset to the Sub CPU
; =============================================================================
; Reads 24-byte reverb preset from ROM table at 0xedb36c, copies to 0xfc8e,
; then sends all 24 bytes via cmd 0x63 to the Sub CPU DSP ring buffer.
; Preset: B0=algo_id, B1=REV_TIME, B3=PRE_DLY, B4=HI_DAMP, B5=ER_LVL, B22=99
; Args: wa = preset index (0-9)
ReverbPreset_Load:
	pushw iz
	extz wa
	sla wa, 2
	lda_24 xbc, 0xedb36c
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	pushw 0x18
	push xwa
	pushw 0x0
	pushw 0xfc8e
	call Mem_Copy
	lda xsp, (xsp + 10)
	lds iz, 0

ReverbPreset_SendLoop:
	ldto_berp C, 0xf8
	extz bc
	ldada xwa, 64654
	ld de, iz
	extz xde
	add xde, xwa
	ld e, (xde)
	extz de
	pushw 0xff
	ldw wa, 0x63
	call AssswbWr
	inc 1, iz
	cp iz, 0x18
	jr c, ReverbPreset_SendLoop
	ld xwa, 0x4002
	ldw bc, 0x7f
	lds de, 1
	call SoundParam_NotifyChange
	popw iz
	ret

; =============================================================================
; EQPreset_Load -- Load and send an EQ preset to the Sub CPU
; =============================================================================
; Reads 24-byte EQ preset from ROM table at 0xedb394, copies to 0xfca8,
; sends via cmd 0x64. EQ uses algo 0x4f with 4 big-endian 16-bit frequencies.
; Args: wa = preset index (0-8)
EQPreset_Load:
	pushw iz
	extz wa
	sla wa, 2
	lda_24 xbc, 0xedb394
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	pushw 0x18
	push xwa
	pushw 0x0
	pushw 0xfca8
	call Mem_Copy
	lda xsp, (xsp + 10)
	lds iz, 0

EQPreset_SendLoop:
	ldto_berp C, 0xf8
	extz bc
	ldada xwa, 64680
	ld de, iz
	extz xde
	add xde, xwa
	ld e, (xde)
	extz de
	pushw 0xff
	ldw wa, 0x64
	call AssswbWr
	inc 1, iz
	cp iz, 0x18
	jr c, EQPreset_SendLoop
	ld xwa, 0x4006
	lds bc, 1
	lds de, 1
	call SoundParam_NotifyChange
	popw iz
	ret

; =============================================================================
; CombinedPreset_Load -- Load combined reverb+EQ preset (48 bytes)
; =============================================================================
; Reads 48 bytes (24 reverb + 24 EQ) from ROM table at 0xedb3b8.
; Sends reverb with cmd 0x63, EQ (at offset +24) with cmd 0x64.
; Args: wa = preset index (0-8)
CombinedPreset_Load:
	dec 4, xsp
	pushw iz
	extz wa
	sla wa, 2
	lda_24 xbc, 0xedb3b8
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xsp + 2), xwa
	pushw 0x18
	ld xwa, (xsp + 4)
	push xwa
	pushw 0x0
	pushw 0xfc8e
	call Mem_Copy
	lda xsp, (xsp + 10)
	lds iz, 0

CombinedPreset_SendReverbLoop:
	ldto_berp C, 0xf8
	extz bc
	ldada xwa, 64654
	ld de, iz
	extz xde
	add xde, xwa
	ld e, (xde)
	extz de
	pushw 0xff
	ldw wa, 0x63
	call AssswbWr
	inc 1, iz
	cp iz, 0x18
	jr c, CombinedPreset_SendReverbLoop
	pushw 0x18
	ld xwa, (xsp + 4)
	lda xwa, (xwa + 24)
	push xwa
	pushw 0x0
	pushw 0xfca8
	call Mem_Copy
	lda xsp, (xsp + 10)
	lds iz, 0

CombinedPreset_SendEQLoop:
	ldto_berp C, 0xf8
	extz bc
	ldada xwa, 64680
	ld de, iz
	extz xde
	add xde, xwa
	ld e, (xde)
	extz de
	pushw 0xff
	ldw wa, 0x64
	call AssswbWr
	inc 1, iz
	cp iz, 0x18
	jr c, CombinedPreset_SendEQLoop
	ld xwa, 0x4002
	ldw bc, 0x7f
	lds de, 1
	call SoundParam_NotifyChange
	ld xwa, 0x4006
	lds bc, 1
	lds de, 1
	call SoundParam_NotifyChange
	popw iz
	inc 4, xsp
	ret

MIDI_MapCCToIndex:
	cp	a, 102
	jr	z, 36
	cp	a, 101
	jr	z, 28
	cp	a, 100
	jr	z, 20
	cp	a, 99
	jr	z, 12
	cp	a, 97
	jr	z, 4
	ldw	hl, 65535
	ret
	lds	hl, 0
	ret
	lds	hl, 1
	ret
	lds	hl, 4
	ret
	lds	hl, 2
	ret
	lds	hl, 3
	ret
	cps	a, 4
	jr	z, 36
	cps	a, 3
	jr	z, 28
	cps	a, 2
	jr	z, 20
	cps	a, 1
	jr	z, 12
	cps	a, 0
	jr	z, 4
	ldw	hl, 65535
	ret
	ldw	hl, 97
	ret
	ldw	hl, 99
	ret
	ldw	hl, 101
	ret
	ldw	hl, 102
	ret
	ldw	hl, 100
	ret

SwbtWr_WriteVoiceParam_PreserveRegs:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	call SwbtWr_FlushAndAppendParams
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

AudioCtrl_PreserveRegs_PopEpilogue:	.ascii "89:;<=>"
	.byte 0x1d
	cp	(xwa-106), d
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	ret

SwbtWr_WriteParamBlockSafe:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	call SwbtWr_WriteParamBlock
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

SndParam_ApplyProgramChange_Safe:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	stda16 37098, xhl
	ldda8 a, 37110
	stda8 37100, a
	call SndParam_ApplyAndFetch
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ldda16 xhl, 37102
	ret

PartCtrl_WriteProgramChange:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	stda16 37098, xhl
	ldda8 a, 37111
	stda8 37100, a
	call SndParam_FetchAndStore
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ldda16 xhl, 37102
	ret

SndParam_UpdateVoiceEntry_Safe:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld a, c
	extz wa
	ld c, e
	extz bc
	ld e, d
	extz de
	call SndParam_UpdateVoiceEntry
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

MIDI_LoadParamsAndDispatchCC:
	ldda16 xbc, 37246
	ldda16 xde, 37248
	call MIDI_ClearGuardAndDispatchCC
	ret

MIDI_ClearGuardAndDispatchCC:
	stdi8 37093, 0

MIDI_DispatchCC_Guarded:
	bitda 0, 47079
	jr nz, MidiGuarded_Return
	bitda 4, 64848
	jr nz, MidiGuarded_Return
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	call MIDI_DispatchCC
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa

MidiGuarded_Return:
	ret

MIDI_WriteVoiceParamCC:
	push xix
	pushw wa
	push xhl
	cps d, 0
	jr z, MidiWriteVoice_Done
	xor h, h
	ld l, c
	sla hl, 2
	ldda32 xix, 37106
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	cp xix, 0x9166
	jr z, MidiWriteVoice_Done
	xor h, h
	ld l, b
	ld_srib3 A, 0x07, 0xf0, 0xec
	ld w, d
	xor w, 0xff
	and a, w
	and e, d
	or e, a
	lda_dri3 XIY, 0x07, 0xf0, 0xec
	stda16 37159, xbc
	stda16 37161, xde

MidiWriteVoice_Done:
	pop xhl
	popw wa
	pop xix
	ret

MIDI_WriteVoiceParamFromBuffer:
	ldda8 c, 37246
	ldda8 b, 37247
	ldda8 e, 37248
	ldda8 d, 37249

MIDI_WriteVoiceParamDirect:
	push xix
	pushw wa
	pushw hl
	cps d, 0
	jr z, MidiWriteDirect_Done
	xor h, h
	ld l, c
	sla hl, 2
	ldda32 xix, 37106
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	cp xix, 0x9166
	jr z, MidiWriteDirect_Done
	xor h, h
	ld l, b
	ld_srib3 A, 0x07, 0xf0, 0xec
	ld w, d
	xor w, 0xff
	and a, w
	and e, d
	or e, a
	lda_dri3 XIY, 0x07, 0xf0, 0xec
	stda16 37159, xbc
	stda16 37161, xde

MidiWriteDirect_Done:
	popw hl
	popw wa
	pop xix
	ret

MIDI_SetupChannelParams:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld a, c
	extz wa
	ld c, l
	extz bc
	ld e, h
	extz de
	call MIDI_DistributeParamToChannels
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

Audio_WriteBankSelectParams:
	pushw de
	bitda 7, 36578
	jr z, BankSelect_CheckChannel1
	anddi8 36578, 127
	stdi16 37159, 176
	ldda8 e, 36578
	ldb d, 0x7f
	stda16 37161, xde
	calr SwbtWr_WriteVoiceParam_PreserveRegs

BankSelect_CheckChannel1:
	bitda 7, 36576
	jr z, BankSelect_Done
	anddi8 36576, 127
	stdi16 37159, 432
	ldda8 e, 36576
	ldb d, 0x7f
	stda16 37161, xde
	calr SwbtWr_WriteVoiceParam_PreserveRegs

BankSelect_Done:
	popw de
	ret

SeqTimer_UpdateTempoReg:
	bitda 2, 64848
	jr nz, SeqTimer_Return
	push xiz
	push xwa
	push xbc
	push xde
	push xhl
	ld xde, 0xfc5a
	ld wa, (xde + 8)
	and wa, 0x1ff
	cp wa, 0x28
	jr c, SeqTimer_ClampToDefault
	cp wa, 0x12c
	jr ule, SeqTimer_ComputeRegValue

SeqTimer_ClampToDefault:
	andmi16 (xde + 8), 0xfe00
	ldw wa, 0x78
	ld (xde + 8), a

SeqTimer_ComputeRegValue:
	stda16 48442, xwa
	ldw de, 0x40
	mul xwa, xde
	ld xde, 0x4c4b400
	call Boot_ReadFDCStatus
	cps l, 4
	jr nz, SeqTimer_AdjustForMode4
	ld xde, 0x3938700

SeqTimer_AdjustForMode4:
	div xde, xwa
	ld xbc, xde
	srl xbc, 0
	srl wa, 1
	cp bc, wa
	jr c, SeqTimer_RoundUp
	inc 1, de

SeqTimer_RoundUp:
	stda16 146, xde	; LD (TREG5L), DE
	bitda 4, 64848
	jr nz, SeqTimer_ClearFlag
	bitda 4, 37113
	jr nz, SeqTimer_ClearFlag
	call SeqData_DispatchLoop_Done

SeqTimer_ClearFlag:
	anddi8 37113, 239
	pop xhl
	pop xde
	pop xbc
	pop xwa
	pop xiz

SeqTimer_Return:
	ret

ToneGen_DispatchByMode:
	pushw wa
	pushw hl
	push xix
	ldda16 xwa, 64614
	and wa, 0x203
	cps a, 0
	jr nz, RegBitManip_Dispatch
	ldb a, 0x1

; Register bit manipulation dispatch
; Index: DRAM[64605] & 0x7 (0-7), entries: 8
; 32-bit function pointers, call (xhl)
RegBitManip_Dispatch:
	extz xhl
	xor h, h
	ldda8 l, 64605
	and l, 0x7
	sla hl, 2
	ld xix, 0xfca3bb
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	jp (xix)
RegisterBit_Manipulate_Table:
	.long RegBitManip_Handler_0
	.long RegBitManip_Handler_1
	.long RegBitManip_Handler_0
	.long RegBitManip_Handler_3
	.long RegBitManip_Handler_4
	.long RegBitManip_Handler_4
	.long RegBitManip_Handler_4
	.long RegBitManip_Handler_4
RegBitManip_Handler_1:
	bitda	0, 64617
	jr	nz, 3
RegBitManip_Handler_3:
	and	w, 0xfd
RegBitManip_Handler_0:
	pushw	wa
	and	wa, 515
	popw	wa
	jr	nz, 2
	lds	wa, 1
RegBitManip_Handler_4:
	stda16	64614, wa
	pop	xix
	popw	hl
	popw	wa
	ret
	push	xwa
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	push	xiz
	call	16554957
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	ret
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	push	xiz
	push	xwa
	call	CharMap_ActivePreamb_Prologue2
	pop	xwa
	ld	a, l
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	ret
	push	xwa
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	push	xiz
	call	SndBuf_WriteParamEntries
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	ret
	.byte 0xf1
	jr	nc, -111
	.ascii "S89:;<=>"
	call	16555011
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	ldda16	hl, 37235
	ldda8	w, 37237
	ret

MIDI_ParamValidate_CheckBit2:
	xor hl, hl
	bitda 2, 64941
	jr nz, MidiParamValid_CheckW78
	cp a, 0xf0
	jr nc, MidiParamValid_SetInvalid
	jr MidiParamValid_Return

MidiParamValid_CheckW78:
	cp w, 0x78
	jr nz, MidiParamValid_Return

MidiParamValid_SetInvalid:
	inc 1, hl

MidiParamValid_Return:
	ret

MidiStream_ProcessEventBuffer:
	push xiz
	ldda8 a, 14235
	and a, 0xf
	jrl z, MidiStream_Return
	calr MidiStream_InitFromLookup
	ei 6
	ordi8 1113, 1
	ldda8 a, 1045
	stda8 37321, a
	ei 0
	ld xix, 0xbd3c
	extz xwa
	ldda16 xwa, 37088
	add xix, xwa
	stda32 37313, xix

MidiStream_NextEvent:
	ldda32 xix, 37313
	ld_spiw WA, 0xf1
	cp a, 0xff
	jr z, MidiStream_BufferDone
	stda16 37309, xwa
	ld_spiw WA, 0xf1
	stda32 37313, xix
	stda16 37311, xwa
	ldda16 xbc, 37309
	ldda16 xde, 37311
	ld xix, 0x91d2

MidiStream_ScanForMatch:
	ld_spiw WA, 0xf1
	cp a, 0xff
	jr z, MidiStream_NextEvent
	cp wa, bc
	jr z, MidiStream_FoundMatch
	inc 2, xix
	jr MidiStream_ScanForMatch

MidiStream_FoundMatch:
	ld_spiw WA, 0xf1
	cp c, 0xb1
	jr z, MidiStream_ProcessorDispatch
	and d, a
	jr z, MidiStream_ScanForMatch

; MIDI stream processor dispatch A
; Index: w & 0x7 (0-7), entries: 8
; 32-bit function pointers, call (xhl)
MidiStream_ProcessorDispatch:
	and w, 0x7
	sll w, 2
	ld xix, 0xfca4f9
	ld_sril3 XIX, 0x03, 0xf0, 0xe1
	call (xix)
	jr MidiStream_NextEvent

MidiStream_BufferDone:
	call TempoRingBuf_Consume
	resda 0, 1113

MidiStream_Return:
	pop xiz
	ret


MidiStream_Processor_Table:
	.long MidiStream_ProcessHandler_0
	.long MidiStream_ProcessHandler_1
	.long MidiStream_ProcessHandler_2
	.long MidiStream_ProcessHandler_3
	.long MidiStream_ProcessHandler_4
	.long MidiStream_ProcessHandler_5
	.long MidiStream_ProcessHandler_5
	.long MidiStream_ProcessHandler_5
MidiStream_ProcessHandler_5:
	ret

MidiStream_InitFromLookup:
	stdi8 37330, 255
	extz hl
	ldda8 l, 14235
	and l, 0xf
	sll hl, 2
	ld xiy, 0xfcc497
	ld_sril3 XIY, 0x07, 0xf4, 0xec
	cp xiy, 0xffffffff
	jr z, MidiStreamInit_Done
	ld xix, 0x91d2

MidiStreamInit_CopyLoop:
	ld_spiw WA, 0xf5
	st_dpiw WA, 0xf1
	ld_spiw WA, 0xf5
	st_dpiw WA, 0xf1
	cp a, 0xff
	jr nz, MidiStreamInit_CopyLoop

MidiStreamInit_Done:
	ret

MidiStream_ProcessHandler_0:
	ld	xix, 37293
	ldb	a, 209
	ldda8	w, 37321
	.byte 0xf5, 0xf1, 0x50
	ldda8	a, 37311
	ldb	w, 255
	ld	(xix), wa
	stdi8	37322, 3
	calr	1517
	ret
MidiStream_ProcessHandler_1:
	ld	xix, 37293
	ldb	a, 210
	ldda8	w, 37321
	.byte 0xf5, 0xf1, 0x50
	ldda8	a, 37312
	ldb	w, 255
	ld	(xix), wa
	stdi8	37322, 3
	calr	1486
	ret
MidiStream_ProcessHandler_2:
	ld	xix, 37293
	ldb	a, 211
	ldda8	w, 37321
	.byte 0xf5, 0xf1, 0x50
	ldda8	a, 37311
	ldb	w, 255
	ld	(xix), wa
	stdi8	37322, 3
	calr	1455
	ret
MidiStream_ProcessHandler_3:
	ld	xix, 37293
	ldb	a, 212
	ldda8	w, 37321
	.byte 0xf5
	stdi8	8528, 241
	.byte 0xbf
	and	(xbc), hl
	jr	z, 2
	ldb	a, 127
	ldb	w, 255
	ld	(xix), wa
	stdi8	37322, 3
	calr	1418
	ret
MidiStream_ProcessHandler_4:
	ld	xix, 37293
	ldb	a, 213
	ldda8	w, 37321
	.byte 0xf5, 0xf1, 0x50
	ldda8	a, 37311
	ldb	w, 255
	ld	(xix), wa
	stdi8	37322, 3
	calr	1387
	ret

MidiStream_ProcessSeqBuffer:
	push xiz
	cpdi8 36150, 201
	jrl nz, MidiSeqBuf_Return
	cpdi8 32523, 0
	jrl z, MidiSeqBuf_Return
	ei 6
	setda 0, 1113
	ldda8 a, 1130
	stda8 37321, a
	ei 0
	ld xix, 0xbd3c
	extz xwa
	ldda16 xwa, 37088
	add xix, xwa
	stda32 37313, xix

MidiSeqBuf_NextEvent:
	ldda32 xix, 37313
	ld_spiw WA, 0xf1
	cp a, 0xff
	jr z, MidiSeqBuf_Done
	stda16 37309, xwa
	ld_spiw WA, 0xf1
	stda32 37313, xix
	stda16 37311, xwa
	calr MidiSeqBuf_InitFromTable
	ldda16 xbc, 37309
	ldda8 d, 37312
	ld xix, 0x91d2

MidiSeqBuf_ScanForMatch:
	ld_spiw WA, 0xf1
	cp a, 0xff
	jr z, MidiSeqBuf_NextEvent
	cp wa, bc
	jr z, MidiSeqBuf_FoundMatch
	inc 2, xix
	jr MidiSeqBuf_ScanForMatch

MidiSeqBuf_FoundMatch:
	ld_spiw WA, 0xf1
	cp c, 0xb1
	jr z, MidiStream_ProcessorDispatchB
	and d, a
	jr z, MidiSeqBuf_ScanForMatch

; MIDI stream processor dispatch B
; Index: w & 0x7 (0-7), entries: 8
; 32-bit function pointers, call (xhl)
MidiStream_ProcessorDispatchB:
	stdi8 37319, 0
	and w, 0x7
	sll w, 2
	ld xix, 0xfca697
	ld_sril3 XIX, 0x03, 0xf0, 0xe1
	call (xix)
	stdi8 37330, 255
	jr MidiSeqBuf_NextEvent

MidiSeqBuf_Done:
	call TempoRingBuf_Consume
	resda 0, 1113

MidiSeqBuf_Return:
	pop xiz
	ret

MidiSeqBuf_ProcessorTable:
	.byte 0xff, 0x24, 0xa9, 0xfc, 0x00, 0x76, 0xa9, 0xfc
	.byte 0x00, 0xc8, 0xa9, 0xfc, 0x00, 0xf3, 0xa9, 0xfc
	.byte 0x00, 0x18, 0xaa, 0xfc, 0x00, 0xb7, 0xa6, 0xfc
	.byte 0x00, 0xb7, 0xa6, 0xfc, 0x00, 0xb7, 0xa6, 0xfc
	.byte 0x00, 0x0e

MidiSeqBuf_InitFromTable:
	stdi8 37330, 255
	ld xiy, 0xfcb9df
	ld xix, 0x91d2

MidiSeqBufInit_CopyLoop:
	ld_spiw WA, 0xf5
	st_dpiw WA, 0xf1
	cp a, 0xff
	jr z, MidiSeqBufInit_Done
	ld_spiw WA, 0xf5
	st_dpiw WA, 0xf1
	jr MidiSeqBufInit_CopyLoop

MidiSeqBufInit_Done:
	ret

Tempo_ProcessExpressionChange:
	pushw wa
	calr MIDI_SelectTempoExpressionSource
	cpdi16 37317, 0
	jr z, TempoExpr_Done
	xor l, l
	ld xix, 0xf1a0

TempoExpr_FindActivePart:
	cp_srib_im 0x03, 0xf0, 0xec, 0x0f
	jr z, TempoExpr_StorePartIndex
	inc 1, l
	cp l, 0x10
	jr c, TempoExpr_FindActivePart

TempoExpr_StorePartIndex:
	stda8 37319, l
	ei 6
	setda 0, 1113
	ldda8 a, 1051
	stda8 37321, a
	ei 0
	ld xix, 0x91ad
	ldb a, 0xc0
	ldda8 w, 37321
	st_dpiw WA, 0xf1
	stiw_dpi 0xf1, 0x17, 0x00
	ld wa, (xsp)
	bit 7, a
	jr z, TempoExpr_CheckHighBitW
	res 7, a
	setda 0, 37293

TempoExpr_CheckHighBitW:
	bit 7, w
	jr z, TempoExpr_WriteAndProcess
	res 7, w
	setda 1, 37293

TempoExpr_WriteAndProcess:
	st_dpiw WA, 0xf1
	ldda8 a, 37319
	ldb w, 0xff
	st_dpiw WA, 0xf1
	stdi8 37322, 7
	calr TempoRingBuf_ProcessEntry
	call TempoRingBuf_Consume
	resda 0, 1113

TempoExpr_Done:
	inc 2, xsp
	ret

Audio_ProcessAllMidiStreams:
	stdi16 37088, 0
	calr MidiStream_ProcessEventBuffer
	calr MidiStream_ProcessSeqBuffer
	calr Mod_SelectExpressionSource
	calr MidiStream_ProcessTempoRingBuf
	ret

MIDI_SelectTempoExpressionSource:
	push xiz
	xor wa, wa
	ldda8 e, 36148
	cp e, 0xb
	jr z, TempoSrc_CheckAutoPlay
	cp e, 0xd
	jr z, TempoSrc_DirectTempoMode
	ldda8 d, 36150
	cp d, 0x87
	jr z, Tempo_Expression_Bypass
	cp d, 0x88
	jr z, Tempo_Expression_Bypass
	anddi8 37113, 243
	jr Tempo_ExpressionStore

TempoSrc_CheckAutoPlay:
	bitda 2, 1057
	jr z, Tempo_ExpressionStore
	ldda16 xwa, 10408
	setda 2, 37113
	jr Tempo_ExpressionStore

Tempo_Expression_Bypass:
	bitda 0, 10437
	jr z, Tempo_ExpressionStore
	ldda16 xwa, 10410
	jr Tempo_ExpressionStore

TempoSrc_DirectTempoMode:
	ldda16 xwa, 3407
	setda 3, 37113

Tempo_ExpressionStore:
	stda16 37317, xwa
	pop xiz
	ret

Mod_SelectExpressionSource:
	xor wa, wa
	ldda8 e, 36148
	cp e, 0xb
	jr z, ModExpr_CheckAutoPlay
	cp e, 0xd
	jr z, ModExpr_DirectMode
	ldda8 d, 36150
	cp d, 0x87
	jr z, Tempo_Expression_Bypass
	cp d, 0x88
	jr z, Tempo_Expression_Bypass
	anddi8 37113, 243
	jr Mod_ExpressionStore

ModExpr_CheckAutoPlay:
	cpdi16 10408, 0
	jr z, Mod_ExpressionStore
	ldda16 xwa, 10408
	setda 2, 37113
	jr Mod_ExpressionStore
	bitda 0, 10437
	jr z, Mod_ExpressionStore
	ldda16 xwa, 10410
	jr Mod_ExpressionStore

ModExpr_DirectMode:
	ldda16 xwa, 3407
	setda 3, 37113

Mod_ExpressionStore:
	stda16 37317, xwa
	ret

MidiStream_ProcessTempoRingBuf:
	push xiz
	cpdi16 37317, 0
	jrl z, TempoRing_Return
	ei 6
	setda 0, 1113
	ldda8 a, 1051
	stda8 37321, a
	ei 0
	ld xix, 0xbd3c
	extz xwa
	ldda16 xwa, 37088
	add xix, xwa
	stda32 37313, xix

TempoRing_NextEvent:
	ldda32 xix, 37313
	ld_spiw WA, 0xf1
	cp a, 0xff
	jr z, TempoRing_Done
	stda16 37309, xwa
	ld_spiw WA, 0xf1
	stda32 37313, xix
	stda16 37311, xwa
	calr TempoRing_ValidateState
	stdi8 37319, 0

TempoRing_InitAndScan:
	calr TempoRing_InitPartStream
	ldda16 xbc, 37309
	ldda8 d, 37312
	ld xix, 0x91d2

TempoRing_ScanForMatch:
	ld_spiw WA, 0xf1
	cp a, 0xff
	jr z, TempoRing_UpdateAndContinue
	cp wa, bc
	jr z, TempoRing_FoundMatch
	inc 2, xix
	jr TempoRing_ScanForMatch

TempoRing_FoundMatch:
	ld_spiw WA, 0xf1
	cp c, 0xb1
	jr z, MidiStream_ProcessorDispatchC
	and d, a
	jr z, TempoRing_ScanForMatch

; MIDI stream processor dispatch C
; Index: w & 0xf (0-15), entries: 16
; 32-bit function pointers, call (xhl)
MidiStream_ProcessorDispatchC:
	and w, 0xf
	sll w, 2
	ld xix, 0xfca8b9
	ld_sril3 XIX, 0x03, 0xf0, 0xe1
	call (xix)

TempoRing_UpdateAndContinue:
	stdi8 37330, 255
	incdi8 1, 37319
	cpdi8 37319, 15
	jr ule, TempoRing_InitAndScan
	jr TempoRing_NextEvent

TempoRing_Done:
	call TempoRingBuf_Consume
	resda 0, 1113

TempoRing_Return:
	pop xiz
	ret

TempoRing_ProcessorTable:
	.byte 0xff, 0x24, 0xa9, 0xfc, 0x00, 0x76, 0xa9, 0xfc
	.byte 0x00, 0x69, 0xaa, 0xfc, 0x00, 0xc8, 0xa9, 0xfc
	.byte 0x00, 0xf3, 0xa9, 0xfc, 0x00, 0x18, 0xaa, 0xfc
	.byte 0x00, 0x3d, 0xaa, 0xfc, 0x00, 0xf9, 0xa8, 0xfc
	.byte 0x00, 0xf9, 0xa8, 0xfc, 0x00, 0xf9, 0xa8, 0xfc
	.byte 0x00, 0xf9, 0xa8, 0xfc, 0x00, 0xf9, 0xa8, 0xfc
	.byte 0x00, 0xf9, 0xa8, 0xfc, 0x00, 0xf9, 0xa8, 0xfc
	.byte 0x00, 0xf9, 0xa8, 0xfc, 0x00, 0xf9, 0xa8, 0xfc
	.byte 0x00, 0x0e

TempoRing_ValidateState:
	ldda32 xix, 37313
	cp xix, 0xbd40
	jr z, MIDI_ParamValidation_ReturnNoOp
	ldda16 xbc, 37309
	cp c, 0x1f
	jr ugt, MIDI_ParamValidation_ReturnNoOp
	cps b, 4
	jr nz, MIDI_ParamValidation_ReturnNoOp
	cp c, (xix - 8)
	jr nz, MIDI_ParamValidation_ReturnNoOp
	cp (xix - 7), 0x0
	jr nz, MIDI_ParamValidation_ReturnNoOp
	anddi8 37312, 183

MIDI_ParamValidation_ReturnNoOp:
	ret

TempoCC_TransmitBytecodeBlock:
	ld	xix, 37293
	ldb	a, 192
	ldda8	w, 37321
	.byte 0xf5, 0xf1, 0x50
	ldda16	wa, 37309
	.byte 0xf5, 0xf1, 0x50
	ldda32	xiy, 37106
	extz	wa
	sll	wa, 2
	.byte 0xe3
	reti
	.byte 0xf4, 0xe0
	ldb	e, 149
	ldb	w, 201
	ldw	hl, 26119
	reti
	res	7, a
	.byte 0xf1, 0xad, 0x91
	lda	xhl, (xwa-56)
	reti
	jr	z, 7
	res	7, w
	.byte 0xf1, 0xad, 0x91, 0xb9, 0xf5, 0xf1, 0x50
	ldda8	a, 37319
	ldb	w, 255
	.byte 0xf5, 0xf1, 0x50
	stdi8	37322, 7
	calr	490
	ret
	ld	xix, 37293
	ldb	a, 176
	ldda8	w, 37321
	.byte 0xf5, 0xf1, 0x50
	ldda16	wa, 37309
	bit	7, a
	jr	z, 7
	res	7, a
	.byte 0xf1, 0xad, 0x91, 0xba, 0xf5, 0xf1, 0x50
	ldda16	wa, 37311
	bit	7, a
	jr	z, 7
	res	7, a
	.byte 0xf1, 0xad, 0x91
	lda	xhl, (xwa-56)
	reti
	jr	z, 7
	res	7, w
	.byte 0xf1, 0xad, 0x91, 0xb9, 0xf5, 0xf1, 0x50
	ldda8	a, 37319
	ldb	w, 255
	.byte 0xf5, 0xf1, 0x50
	stdi8	37322, 7
	calr	408
	ret
	ld	xix, 37293
	ldb	a, 210
	ldda8	w, 37321
	.byte 0xf5, 0xf1, 0x50
	ldda16	wa, 37311
	and	wa, 32639
	.byte 0xf5, 0xf1, 0x50
	ldda8	a, 37319
	ldb	w, 255
	.byte 0xf5, 0xf1, 0x50
	stdi8	37322, 37
	calr	365
	ret
	ld	xix, 37293
	ldb	a, 209
	ldda8	w, 37321
	.byte 0xf5, 0xf1, 0x50
	ldda8	a, 37311
	ldda8	w, 37319
	.byte 0xf5
	stdi8	46160, 255
	stdi8	37322, 20
	calr	328
	ret
	ld	xix, 37293
	ldb	a, 211
	ldda8	w, 37321
	.byte 0xf5, 0xf1, 0x50
	ldda8	a, 37311
	ldda8	w, 37319
	.byte 0xf5
	stdi8	46160, 255
	stdi8	37322, 4
	calr	291
	ret
	.byte 0xf2
	incdi8_24	6, 13107455
	ldb	d, 68
	.byte 0xad, 0x91
	nop
	nop
	ldb	a, 208
	ldda8	w, 37321
	.byte 0xf5, 0xf1, 0x50
	ldda8	a, 37311
	ldda8	w, 37319
	.byte 0xf5
	stdi8	46160, 255
	stdi8	37322, 4
	calr	247
	ret
	ld	xix, 37293
	ldb	a, 128
	ldda8	w, 37321
	.byte 0xf5
	stda32	53584, xde
	swi	4
	ldb	w, 216
	.byte 0xcc
	swi	7
	.byte 0x01
	sll	w, 1
	bit	7, a
	jr	z, 3
	set	0, w
	res	7, a
	.byte 0xf5
	stdi8	46160, 255
	stdi8	37322, 4
	calr	196
	ret

MIDI_TransmitTempoCC:
	stda16 37309, xbc
	stda16 37311, xde
	calr MIDI_SelectTempoExpressionSource
	cpdi16 37317, 0
	jr z, TempoCC_Return
	ei 6
	setda 0, 1113
	ldda8 a, 1051
	stda8 37321, a
	ei 0
	ld xix, 0x91ad
	ldb a, 0xb0
	ldda8 w, 37321
	st_dpiw WA, 0xf1
	ldda16 xwa, 37309
	st_dpiw WA, 0xf1
	ldda16 xwa, 37311
	bit 7, a
	jr z, TempoCC_CheckHighBitW
	res 7, a
	setda 0, 37293

TempoCC_CheckHighBitW:
	bit 7, w
	jr z, TempoCC_WriteAndProcess
	res 7, w
	setda 1, 37293

TempoCC_WriteAndProcess:
	st_dpiw WA, 0xf1
	ldw wa, 0xff7f
	ld (xix), wa
	stdi8 37322, 135
	calr TempoRingBuf_ProcessEntry
	call TempoRingBuf_Consume
	resda 0, 1113

TempoCC_Return:
	ret

TempoRing_InitPartStream:
	stdi8 37330, 255
	ldda8 c, 37319
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ldda16 xde, 37317
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3e
	ldto_berp A, 0x3c
	jr c, TempoPartStream_Done
	extz hl
	ldda8 l, 37319
	ld xix, 0xf1a0
	ld_srib3 L, 0x07, 0xf0, 0xec
	sll hl, 2
	ld xix, 0xfcba47
	ld_sril3 XIY, 0x07, 0xf0, 0xec
	ld xix, 0x91d2

TempoPartStream_CopyLoop:
	ld_spiw WA, 0xf5
	st_dpiw WA, 0xf1
	cp a, 0xff
	jr z, TempoPartStream_Done
	ld_spiw WA, 0xf5
	st_dpiw WA, 0xf1
	jr TempoPartStream_CopyLoop

TempoPartStream_Done:
	ret

TempoRingBuf_ProcessEntry:
	cpdi8 37293, 255
	jr z, TempoRingBuf_EntryDone
	ld xix, 0x91ad
	push xix
	extz wa
	ldda8 a, 37322
	and a, 0x7
	pushw wa
	ei 6
	call TempoRingBuf_WriteBytes
	inc 6, xsp
	ei 0
	cpdi8 37112, 255
	jr nz, TempoRingBuf_ClearEntryType
	call AudioCtrl_SaveAllRegs
	call SeqPlay_CheckAndStartPlayback
	call AudioCtrl_RestoreAllRegs
	jr TempoRingBuf_ClearEntryType

TempoRingBuf_ClearEntryType:
	stdi8 37322, 0

TempoRingBuf_EntryDone:
	ret

Audio_ProcessPartExpressions:
	push xiz
	calr MIDI_SelectTempoExpressionSource
	cpdi16 37317, 0
	jrl z, PartExpr_Done
	ei 6
	setda 0, 1113
	ldda8 a, 1051
	stda8 37321, a
	ei 0
	xor c, c

PartExpr_ProcessNextBit:
	ldda16 xwa, 37317
	srl wa, 1
	stda16 37317, xwa
	jr nc, PartExpr_AdvanceBit
	ld l, c
	ld xix, 0xf1a0
	ld_srib3 A, 0x03, 0xf0, 0xec
	cps a, 0
	jr z, PartExpr_WriteToBuffer
	cps a, 2
	jr z, PartExpr_WriteToBuffer
	cps a, 1
	jr nz, PartExpr_AdvanceBit

PartExpr_WriteToBuffer:
	ld xix, 0x91ad
	ldb a, 0xb2
	ldda8 w, 37321
	st_dpiw WA, 0xf1
	ldb a, 0x9a
	bit 7, a
	jr z, PartExpr_AddPartIndex
	setda 2, 37293
	res 7, a

PartExpr_AddPartIndex:
	ld w, c
	add w, 0x4
	st_dpiw WA, 0xf1
	ldda8 a, 50600
	bit 7, a
	jr z, PartExpr_ReadCurrentValue
	setda 0, 37293
	res 7, a

PartExpr_ReadCurrentValue:
	ldb w, 0x7f
	st_dpiw WA, 0xf1
	ld a, c
	ldb w, 0xff
	st_dpiw WA, 0xf1
	stdi8 37322, 7
	pushw bc
	calr TempoRingBuf_ProcessEntry
	popw bc

PartExpr_AdvanceBit:
	inc 1, c
	cp c, 0x10
	jr c, PartExpr_ProcessNextBit
	call TempoRingBuf_Consume
	resda 0, 1113

PartExpr_Done:
	pop xiz
	ret

Part_ReinitAllActive:
	push xiz
	stdi8 37320, 0

PartReinit_ProcessNextPart:
	ldda8 c, 37320
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ldda16 xde, 61854
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3e
	ldto_berp A, 0x3c
	jr c, PartReinit_AdvancePart
	extz hl
	ld l, c
	ld xix, 0xf1a0
	ld_srib3 A, 0x07, 0xf0, 0xec
	stda8 37325, a
	calr PartReinit_SendD0Command
	calr PartReinit_SendB0Command
	calr PartReinit_SendD2Command
	calr PartReinit_SendD1Command
	calr PartReinit_SendD0Command
	calr PartReinit_CheckSpecialPart15

PartReinit_AdvancePart:
	incdi8 1, 37320
	cpdi8 37320, 16
	jr c, PartReinit_ProcessNextPart
	calr PendingParam_ScanAllTables
	call SwbtWr_ReinitOutputBank
	pop xiz
	ret

PartReinit_SendD2Command:
	ld xix, 0x91b5
	ldw wa, 0xd2
	st_dpiw WA, 0xf1
	xor a, a
	ldb w, 0x40
	st_dpiw WA, 0xf1
	ldda8 a, 37320
	ldb w, 0xff
	ld (xix), wa
	calr VoiceParam_DispatchByMode
	ret

PartReinit_SendD1Command:
	ld xix, 0x91b5
	ldw wa, 0xd1
	st_dpiw WA, 0xf1
	ldb a, 0x0
	ldda8 w, 37320
	st_dpiw WA, 0xf1
	ld (xix), 0xff
	calr VoiceParam_DispatchByMode
	ret

PartReinit_SendD0Command:
	ld xix, 0x91b5
	ldw wa, 0xd0
	st_dpiw WA, 0xf1
	ldb a, 0x0
	ldda8 w, 37320
	st_dpiw WA, 0xf1
	ld (xix), 0xff
	calr VoiceParam_DispatchByMode
	ret

PartReinit_SendB0Command:
	ld xix, 0x91b5
	ldw wa, 0xb0
	st_dpiw WA, 0xf1
	extz hl
	ldda8 l, 37320
	ld xiy, 0xf1a0
	ld_srib3 L, 0x07, 0xf4, 0xec
	ld xiy, 0xfcba03
	ld_srib3 A, 0x07, 0xf4, 0xec
	ldb w, 0x4
	st_dpiw WA, 0xf1
	ldw wa, 0x800
	st_dpiw WA, 0xf1
	ldda8 a, 37320
	ldb w, 0xff
	ld (xix), wa
	calr VoiceMode_ParamHandler_3
	ret

PartReinit_CheckSpecialPart15:
	cpdi8 37325, 15
	jr nz, PartReinit_SpecialDone
	ldw bc, 0x298
	ldw de, 0x8000
	call MIDI_WriteVoiceParamDirect
	call SwbtWr_WriteVoiceParam_PreserveRegs

PartReinit_SpecialDone:
	ret

Audio_ReinitAndProcessEvents:
	calr Audio_SyncAndProcessSequencer
	calr PendingParam_ScanAllTables
	call MidiPkt_ProcessEventQueue
	ret

Audio_SyncAndProcessSequencer:
	ldda16 xwa, 37086
	stda16 37088, xwa
	call SeqBuf_SaveReadPos

AudioSeq_CheckEventPending:
	ld xix, 0x1e549
	ld hl, (xix - 10)
	cp hl, (xix - 6)
	jr z, AudioSeq_FlushAndTerminate
	ld xiy, 0x91b5

AudioSeq_ReadNextEvent:
	pushw hl
	call SeqBuf_ReadAlternate
	lda_dpi XSP, 0xf4
	popw hl
	ld hl, (xix - 10)
	cp hl, (xix - 6)
	jr z, VoiceMode_ParamDispatch
	ld_srib3 A, 0x07, 0xf0, 0xec
	bit 7, a
	jr z, AudioSeq_ReadNextEvent

; Voice mode parameter dispatch
; Index: DRAM[37301] bits [6:4] (0-7), entries: 8
; 32-bit function pointers, call (xhl)
VoiceMode_ParamDispatch:
	ld (xiy), 0xff
	ldda8 a, 37302
	stda8 37112, a
	extz hl
	ldda8 l, 37301
	and l, 0x70
	srl hl, 2
	ld xiy, 0xfcada3
	ld_sril3 XIY, 0x07, 0xf4, 0xec
	call (xiy)
	jr AudioSeq_CheckEventPending

VoiceMode_ParamDispatch_Sentinel:
	swi	7


VoiceMode_ParamDispatch_Table:
	.long VoiceMode_ParamHandler_0
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_3
	.long VoiceMode_ParamHandler_4
	.long VoiceParam_DispatchByMode
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_1

VoiceMode_ParamHandler_1:
	ret

AudioSeq_FlushAndTerminate:
	ld xix, 0xbd3c
	ldda16 xhl, 37086
	stib_dri 0x07, 0xf0, 0xec, 0xff
	ret

VoiceMode_ParamHandler_4:
	calr VoiceMode_CheckPendingFlags
	cpdi8 37301, 255
	jrl z, MidiCtrl_NullRet
	ld xix, 0x91b7
	ld_spiw BC, 0xf1
	ld_spiw DE, 0xf1
	ld a, (xix)
	stda8 37320, a
	extz hl
	ld l, c
	sll hl, 2
	ldda32 xix, 37106
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	cp xix, 0xffffffff
	jrl z, MidiCtrl_NullRet
	stda16 37211, xbc
	stda16 37213, xde
	stda8 37111, c
	ld hl, de
	call PartCtrl_WriteProgramChange
	stda16 37327, xhl
	call PartCtrl_CheckBitmaskBit
	jr nc, VoiceMode4_CheckPart0
	cpdi8 37211, 23
	jr nz, VoiceMode4_SetupChannelAndWrite
	ld hl, de
	call AccompSeq_ManualMidiEntry2
	ret

VoiceMode4_SetupChannelAndWrite:
	call MIDI_SetupChannelParams
	andmi8 (xix + 1), 0x80
	ldda8 a, 37214
	or (xix + 1), a
	ldda8 a, 37213
	ld (xix), a
	ldda8 a, 37211
	ldb w, 0x1
	stda16 37159, xwa
	ldda8 a, 37214
	ldb w, 0x7f
	stda16 37161, xwa
	call SwbtWr_WriteVoiceParam_PreserveRegs
	ldda8 a, 37211
	ldb w, 0x0
	stda16 37159, xwa
	ldda8 a, 37213
	ldb w, 0xff
	stda16 37161, xwa
	call SwbtWr_WriteVoiceParam_PreserveRegs
	ldda16 xbc, 37211
	ldda16 xde, 37213
	call SndParam_UpdateVoiceEntry_Safe

VoiceMode4_CheckPart0:
	cpdi8 37211, 0
	jr nz, MidiCtrl_DispatchHandler
	bitda 3, 64848
	jrl nz, MidiCtrl_NullRet

; MIDI controller dispatch handler
MidiCtrl_DispatchHandler:
	xor h, h
	ldda8 l, 37320
	ld xix, 0xf1a0
	ld_srib3 A, 0x07, 0xf0, 0xec
	cp a, 0xd
	jrl z, MidiCtrl_NullRet
	cp a, 0xe
	jrl z, MidiCtrl_NullRet
	cp a, 0xf
	jrl z, MidiCtrl_NullRet
	cp a, 0x10
	jrl z, MidiCtrl_NullRet
	ld xix, 0x90ce
	ld_srib3 A, 0x07, 0xf0, 0xec
	cp a, 0x10
	jrl z, MidiCtrl_NullRet
	set 7, a
	stda8 37093, a
	extz hl
	ldda8 l, 64848
	and l, 0x3
	sll hl, 2
	ld xix, 0xfcaee9
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	jp (xix)
MidiCtrl_ModeDispatch_Table:
	.byte 0xf9, 0xae, 0xfc, 0x00, 0x31, 0xaf, 0xfc, 0x00
	.byte 0xd1, 0xaf, 0xfc, 0x00, 0x78, 0xaf, 0xfc, 0x00
	.byte 0x23, 0x81, 0xc1, 0x5b, 0x91, 0x22, 0xc1, 0xd0
	.byte 0x91, 0x25, 0xcc, 0xd4, 0x1d, 0x03, 0xa2, 0xfc
	.byte 0xce, 0xd6, 0xc1, 0xc8, 0x91, 0x27, 0x44, 0xce
	.byte 0x90, 0x00, 0x00, 0xc3, 0x07, 0xf0, 0xec, 0x21
	.byte 0xc9, 0x31, 0x07, 0xf1, 0xe5, 0x90, 0x41, 0xd1
	.byte 0x5b, 0x91, 0x21, 0xc1, 0xcf, 0x91, 0x25, 0x24
	.byte 0xff, 0x1d, 0x03, 0xa2, 0xfc, 0x78, 0xa0, 0x00
	.byte 0xc1, 0x5b, 0x91, 0x22, 0x23, 0x81, 0xcc, 0xd4
	.byte 0xf1, 0x5d, 0x91, 0xcf, 0x66, 0x02, 0x24, 0x01
	.byte 0xc1, 0x5e, 0x91, 0x25, 0xcd, 0xee, 0x04, 0x1d
	.byte 0x03, 0xa2, 0xfc, 0xdb, 0x12, 0xc1, 0xc8, 0x91
	.byte 0x27, 0x44, 0xce, 0x90, 0x00, 0x00, 0xc3, 0x07
	.byte 0xf0, 0xec, 0x21, 0xc9, 0x31, 0x07, 0xf1, 0xe5
	.byte 0x90, 0x41, 0xc1, 0x5b, 0x91, 0x23, 0x22, 0x00
	.byte 0xc1, 0x5d, 0x91, 0x25, 0xcd, 0x30, 0x07, 0x24
	.byte 0xff, 0x1d, 0x03, 0xa2, 0xfc, 0x68, 0x59, 0xd1
	.byte 0x5d, 0x91, 0x20, 0xf1, 0xea, 0x90, 0x50, 0xc1
	.byte 0x5b, 0x91, 0x21, 0xf1, 0xec, 0x90, 0x41, 0x1d
	.byte 0xf6, 0xa3, 0xfc, 0x28, 0x2b, 0xd1, 0x5d, 0x91
	.byte 0x20, 0x1d, 0x50, 0xa4, 0xfc, 0xdb, 0xe3, 0x4b
	.byte 0x48, 0x6e, 0x0e, 0xc1, 0x5b, 0x91, 0x22, 0x23
	.byte 0x81, 0xd1, 0xee, 0x90, 0x22, 0x1d, 0x03, 0xa2
	.byte 0xfc, 0xdb, 0x12, 0xc1, 0xc8, 0x91, 0x27, 0x44
	.byte 0xce, 0x90, 0x00, 0x00, 0xc3, 0x07, 0xf0, 0xec
	.byte 0x21, 0xc9, 0x31, 0x07, 0xf1, 0xe5, 0x90, 0x41
	.byte 0xc1, 0x5b, 0x91, 0x23, 0xca, 0xd2, 0xc1, 0xf0
	.byte 0x90, 0x25, 0x24, 0xff, 0x1d, 0x03, 0xa2, 0xfc

MidiCtrl_NullRet:
	ret

VoiceMode_CheckPendingFlags:
	ld xix, 0x91b5
	bitm 0, (xix)
	jr z, VoiceMode_CheckFlag1
	setm 7, (xix + 4)

VoiceMode_CheckFlag1:
	bitm 1, (xix)
	jr z, VoiceMode_CheckPart15Validate
	setm 7, (xix + 5)

VoiceMode_CheckPart15Validate:
	cp (xix + 2), 0xf
	jr nz, VoiceMode_FlagCheckDone
	pushw wa
	pushw hl
	ld a, (xix + 4)
	ld w, (xix + 5)
	call MIDI_ParamValidate_CheckBit2
	or hl, hl
	popw hl
	popw wa
	jr nz, VoiceMode_FlagCheckDone
	ld (xix), 0xff

VoiceMode_FlagCheckDone:
	ret

VoiceMode_ParamHandler_3:
	calr VoiceMode3_InitChannelMatch
	cpdi8 37301, 255
	jr z, VoiceMode3_Done
	extz hl
	ldda8 l, 37329
	and l, 0xf
	sll hl, 2
	ld xix, 0xfcb025
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	call (xix)

VoiceMode3_Done:
	ret

VoiceMode3_DispatchTable:
	.byte 0xff, 0x65, 0xb0, 0xfc, 0x00, 0x2a, 0xb2, 0xfc
	.byte 0x00, 0x82, 0xb2, 0xfc, 0x00, 0xd6, 0xb2, 0xfc
	.byte 0x00, 0x26, 0xb3, 0xfc, 0x00, 0x8b, 0xb1, 0xfc
	.byte 0x00, 0xf2, 0xb0, 0xfc, 0x00, 0xc3, 0xad, 0xfc
	.byte 0x00, 0xc3, 0xad, 0xfc, 0x00, 0xc3, 0xad, 0xfc
	.byte 0x00, 0xc3, 0xad, 0xfc, 0x00, 0xc3, 0xad, 0xfc
	.byte 0x00, 0xc3, 0xad, 0xfc, 0x00, 0xc3, 0xad, 0xfc
	.byte 0x00, 0xc3, 0xad, 0xfc, 0x00, 0xc3, 0xad, 0xfc
	.byte 0x00, 0x1d, 0x90, 0xb9, 0xfc, 0x6f, 0x45, 0xc1
	.byte 0xba, 0x91, 0x21, 0xc9, 0xcc, 0x07, 0x66, 0x29
	.byte 0xd1, 0xb7, 0x91, 0x21, 0xdb, 0x12, 0xc1, 0xc8
	.byte 0x91, 0x27, 0x44, 0xa0, 0xf1, 0x00, 0x00, 0xc3
	.byte 0x07, 0xf0, 0xec, 0x21, 0xc9, 0xcf, 0x0e, 0x6e
	.byte 0x02, 0x22, 0x04, 0xc1, 0xb9, 0x91, 0x25, 0x24
	.byte 0x07, 0x1d, 0x22, 0xa2, 0xfc, 0x1d, 0x53, 0xa1
	.byte 0xfc, 0xd1, 0xb7, 0x91, 0x21, 0xd1, 0xb9, 0x91
	.byte 0x22, 0xcc, 0xcc, 0xf8, 0x1d, 0x76, 0xa2, 0xfc
	.byte 0x1d, 0x53, 0xa1, 0xfc, 0xc1, 0xba, 0x91, 0x21
	.byte 0xc9, 0xcc, 0x07, 0x66, 0x38, 0xdb, 0x12, 0xc1
	.byte 0xbb, 0x91, 0x27, 0x44, 0xa0, 0xf1, 0x00, 0x00
	.byte 0xc3, 0x07, 0xf0, 0xec, 0x3f, 0x0f, 0x6e, 0x25
	.byte 0x44, 0xce, 0x90, 0x00, 0x00, 0xc3, 0x07, 0xf0
	.byte 0xec, 0x21, 0xc9, 0xcf, 0x10, 0x66, 0x16, 0xc9
	.byte 0x31, 0x07, 0xf1, 0xe5, 0x90, 0x41, 0xd1, 0xb7
	.byte 0x91, 0x21, 0xd1, 0xb9, 0x91, 0x22, 0xcc, 0xcc
	.byte 0x07, 0x1d, 0x03, 0xa2, 0xfc, 0x0e, 0x1d, 0x90
	.byte 0xb9, 0xfc, 0x6f, 0x51, 0xd1, 0xb7, 0x91, 0x21
	.byte 0xd1, 0xb9, 0x91, 0x22, 0xdb, 0x12, 0xcb, 0x8f
	.byte 0xdb, 0xee, 0x02, 0xe1, 0xf2, 0x90, 0x24, 0xe3
	.byte 0x07, 0xf0, 0xec, 0x24, 0xec, 0xcf, 0xff, 0xff
	.byte 0xff, 0xff, 0x66, 0x72, 0xdb, 0x12, 0xca, 0x8f
	.byte 0xc3, 0x07, 0xf0, 0xec, 0x21, 0xcc, 0x88, 0xc8
	.byte 0xcd, 0xff, 0xc8, 0xc1, 0xcc, 0xc5, 0xc9, 0xe5
	.byte 0xf3, 0x07, 0xf0, 0xec, 0x45, 0xf1, 0x27, 0x91
	.byte 0x51, 0xf1, 0x29, 0x91, 0x52, 0x1d, 0x53, 0xa1
	.byte 0xfc, 0xd1, 0xb7, 0x91, 0x3f, 0x98, 0x03, 0x6e
	.byte 0x04, 0xf1, 0x52, 0x8d, 0xbb, 0xdb, 0x12, 0xc1
	.byte 0xc8, 0x91, 0x27, 0x44, 0xa0, 0xf1, 0x00, 0x00
	.byte 0xc3, 0x07, 0xf0, 0xec, 0x21, 0xc9, 0xcf, 0x0f
	.byte 0x66, 0x2c, 0xc9, 0xcf, 0x0e, 0x66, 0x27, 0xc9
	.byte 0xcf, 0x0d, 0x66, 0x22, 0x44, 0xce, 0x90, 0x00
	.byte 0x00, 0xc3, 0x07, 0xf0, 0xec, 0x21, 0xc9, 0xcf
	.byte 0x10, 0x66, 0x13, 0xc9, 0x31, 0x07, 0xf1, 0xe5
	.byte 0x90, 0x41, 0xd1, 0xb7, 0x91, 0x21, 0xd1, 0xb9
	.byte 0x91, 0x22, 0x1d, 0x03, 0xa2, 0xfc, 0x0e, 0xd1
	.byte 0xb7, 0x91, 0x21, 0xd1, 0xb9, 0x91, 0x22, 0xcc
	.byte 0x33, 0x07, 0x6e, 0x47, 0xdb, 0x12, 0xc1, 0xc8
	.byte 0x91, 0x27, 0x44, 0xa0, 0xf1, 0x00, 0x00, 0xc3
	.byte 0x07, 0xf0, 0xec, 0x3f, 0x0f, 0x66, 0x34, 0xcd
	.byte 0x31, 0x07, 0x44, 0xb2, 0x94, 0x00, 0x00, 0xf3
	.byte 0x07, 0xf0, 0xec, 0x45, 0x0e

MidiPartCC_WriteAndDispatch:
	extz hl
	ldda8 l, 37320
	ld xix, 0xf1a0
	ld_srib3 L, 0x07, 0xf0, 0xec
	ld xix, 0xfcba03
	ld_srib3 C, 0x07, 0xf0, 0xec
	ldb b, 0x3
	stda16 37211, xbc
	ldb d, 0x7f
	stda16 37213, xde
	call PartCtrl_CheckBitmaskBit
	jr nc, MidiPartCC_CheckAndGuard
	call MIDI_WriteVoiceParamCC
	call SwbtWr_WriteVoiceParam_PreserveRegs

MidiPartCC_CheckAndGuard:
	extz hl
	ldda8 l, 37320
	ld xix, 0xf1a0
	ld_srib3 A, 0x07, 0xf0, 0xec
	cp a, 0xe
	jr z, MIDI_PartCC_DispatchExit
	cp a, 0xd
	jr z, MIDI_PartCC_DispatchExit
	ld xix, 0x90ce
	ld_srib3 A, 0x07, 0xf0, 0xec
	cp a, 0x10
	jr z, MIDI_PartCC_DispatchExit
	set 7, a
	stda8 37093, a
	ldda16 xbc, 37211
	ldda16 xde, 37213
	call MIDI_DispatchCC_Guarded

MIDI_PartCC_DispatchExit:
	ret

MidiVoice_DataBlockHandler:
	ld	xiy, 37303
	stdi8	37092, 0
	call	PartCtrl_CheckBitmaskBit
	jr	nc, 18
	.byte 0xc1, 0xe4, 0x90
	push	xiz
	ldb	w, 149
	ldb	w, 241
	ldb	l, 145
	.byte 0x50
	ld	wa, (xiy+2)
	stda16	37161, wa
	extz	hl
	ldda8	l, 37320
	ld	xix, 37070
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	a, 201
	.byte 0xcf
	rcf
	jr	z, 28
	.byte 0xf1, 0x50
	swi	5
	dec	6, d
	ex_ff
	orddm8	37092, a
	.byte 0xc1, 0xe4, 0x90
	push	xiz
	ld_sd8b	w, 149
	stda16	37159, wa
	ld	wa, (xiy+2)
	stda16	37161, wa
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	extz	hl
	ldda8	l, 37320
	ld	xix, 61856
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	push	xsp
	retd	16494
	call	PartCtrl_CheckBitmaskBit
	jr	nc, 17
	ldw	bc, 664
	ldda8	e, 37305
	ldb	d, 128
	call	MIDI_WriteVoiceParamDirect
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	extz	hl
	ldda8	l, 37320
	ld	xix, 37070
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	a, 201
	.byte 0xcf
	rcf
	jr	z, 20
	set	7, a
	stda8	37093, a
	ldw	bc, 664
	ldda8	e, 37305
	ldb	d, 128
	call	MIDI_DispatchCC_Guarded
	ret
	call	PartCtrl_CheckBitmaskBit
	jr	nc, 33
	ldb	a, 0
	stda8	38468, a
	ldda16	wa, 37303
	stda16	38468, wa
	ldw	wa, 32512
	stda16	38470, wa
	call	16565921
	ldda8	a, 37302
	stda8	37112, a
	extz	hl
	ldda8	l, 37320
	ld	xix, 37070
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	a, 201
	.byte 0xcf
	rcf
	jr	z, 19
	set	7, a
	stda8	37093, a
	ldda16	bc, 37303
	ldda16	de, 37305
	call	MIDI_DispatchCC_Guarded
	ret
	call	PartCtrl_CheckBitmaskBit
	jr	nc, 20
	ldda16	wa, 37303
	stda16	37159, wa
	ldda16	wa, 37305
	stda16	37161, wa
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	extz	hl
	ldda8	l, 37320
	ld	xix, 37070
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	a, 201
	.byte 0xcf
	rcf
	jr	z, 19
	set	7, a
	stda8	37093, a
	ldda16	bc, 37303
	ldda16	de, 37305
	call	MIDI_DispatchCC_Guarded
	ret

VoiceMode3_InitChannelMatch:
	ldda8 a, 37307
	stda8 37320, a
	calr VoiceMode3_BuildChannelTable
	cpdi8 37330, 255
	jr z, VoiceMode3_NoMatch
	ld xix, 0x91b7
	ld bc, (xix)
	ld de, (xix + 2)
	ld a, (xix - 2)
	bit 2, a
	jr z, VoiceMode3_CheckBit0
	set 7, c

VoiceMode3_CheckBit0:
	bit 0, a
	jr z, VoiceMode3_CheckBit1
	set 7, e

VoiceMode3_CheckBit1:
	bit 1, a
	jr z, VoiceMode3_StoreAndScan
	set 7, d

VoiceMode3_StoreAndScan:
	ld (xix), bc
	ld (xix + 2), de
	ld xiy, 0x91d2

VoiceMode3_ScanLoop:
	ld_spiw WA, 0xf5
	cp a, 0xff
	jr z, VoiceMode3_NoMatch
	cp wa, bc
	jr z, VoiceMode3_FoundMatch
	inc 2, xiy
	jr VoiceMode3_ScanLoop

VoiceMode3_FoundMatch:
	ld_spiw WA, 0xf5
	and d, a
	ld (xix + 2), de
	jr nz, VoiceMode3_StoreSubMode

VoiceMode3_NoMatch:
	stdi8 37301, 255
	jr VoiceMode3_ScanDone

VoiceMode3_StoreSubMode:
	stda8 37329, w

VoiceMode3_ScanDone:
	ret

VoiceMode3_BuildChannelTable:
	stdi8 37330, 255
	extz hl
	ldda8 l, 37320
	ld xix, 0xf1a0
	ld_srib3 L, 0x07, 0xf0, 0xec
	sll hl, 2
	ld xix, 0xfcbfa3
	ld_sril3 XIY, 0x07, 0xf0, 0xec
	ld xix, 0x91d2

VoiceMode3_CopyTableEntry:
	ld_spiw WA, 0xf5
	st_dpiw WA, 0xf1
	cp a, 0xff
	jr z, VoiceMode3_TableCopyDone
	ld_spiw WA, 0xf5
	st_dpiw WA, 0xf1
	jr VoiceMode3_CopyTableEntry

VoiceMode3_TableCopyDone:
	ret

VoiceMode_ParamHandler_0:
	cpdi8 37301, 128
	jr nz, VoiceMode0_Done
	ldda8 a, 37305
	stda8 37320, a
	call PartCtrl_CheckBitmaskBit
	jr nc, VoiceMode0_Done
	ldda16 xwa, 37303
	srl w, 1
	jr nc, VoiceMode0_UpdateTempoAndWrite
	set 7, a

VoiceMode0_UpdateTempoAndWrite:
	ldda32 xix, 64610
	and w, 0x1
	andmi16 (xix), 0xfe00
	or (xix), wa
	ldb w, 0xff
	call SeqTimer_UpdateTempoReg
	stda16 37161, xwa
	stdi16 37159, 2120
	call SwbtWr_WriteVoiceParam_PreserveRegs

VoiceMode0_Done:
	ret

VoiceParam_DispatchByMode:
	calr MidiVoiceNote_Dispatch
	cpdi8 37301, 255
	jr z, VoiceParam_DispatchDone
	ldda8 a, 37301
	and a, 0x3
	sll a, 2
	ld xix, 0xfcb46f
	ld_sril3 XIX, 0x03, 0xf0, 0xe0
	call (xix)

VoiceParam_DispatchDone:
	ret

VoiceParam_ModeDispatch_Table:
	.byte 0x7f, 0xb4, 0xfc, 0x00, 0x09, 0xb5, 0xfc, 0x00
	.byte 0x93, 0xb5, 0xfc, 0x00, 0x26, 0xb6, 0xfc, 0x00

VoiceParam_StoreExpression:
	extz hl
	ldda8 l, 37320
	ld xix, 0x94d2
	ldda8 a, 37303
	set 7, a
	lda_dri3 XBC, 0x07, 0xf0, 0xec
	ret

VoiceParam_WriteExpression:
	ldb c, 0xb4
	ld xix, 0xf1a0
	ldda8 l, 37320
	ld_srib3 L, 0x03, 0xf0, 0xec
	ld xix, 0xfcba03
	ld_srib3 B, 0x03, 0xf0, 0xec
	stda16 37211, xbc
	ldb d, 0x7f
	stda16 37213, xde
	call PartCtrl_CheckBitmaskBit
	jr nc, VoiceParam_ExprCheckGuard
	ldda16 xwa, 37211
	stda16 37159, xwa
	ldda16 xwa, 37213
	stda16 37161, xwa
	call SwbtWr_WriteVoiceParam_PreserveRegs

VoiceParam_ExprCheckGuard:
	ldda8 l, 37320
	ld xix, 0xf1a0
	cp_srib_im 0x03, 0xf0, 0xec, 0x0f
	jr z, VoiceParam_ExprDone
	ld xix, 0x90ce
	ld_srib3 A, 0x03, 0xf0, 0xec
	cp a, 0x10
	jr z, VoiceParam_ExprDone
	set 7, a
	stda8 37093, a
	ldda16 xbc, 37211
	ldda16 xde, 37213
	call MIDI_DispatchCC_Guarded

VoiceParam_ExprDone:
	ret

VoiceParam_StoreVolume:
	extz hl
	ldda8 l, 37320
	ld xix, 0x9452
	ldda8 a, 37303
	set 7, a
	lda_dri3 XBC, 0x07, 0xf0, 0xec
	ret

VoiceParam_WriteVolume:
	ldb c, 0xb2
	ld xix, 0xf1a0
	ldda8 l, 37320
	ld_srib3 L, 0x03, 0xf0, 0xec
	ld xix, 0xfcba03
	ld_srib3 B, 0x03, 0xf0, 0xec
	stda16 37211, xbc
	ldb d, 0x7f
	stda16 37213, xde
	call PartCtrl_CheckBitmaskBit
	jr nc, VoiceParam_VolCheckGuard
	ldda16 xwa, 37211
	stda16 37159, xwa
	ldda16 xwa, 37213
	stda16 37161, xwa
	call SwbtWr_WriteVoiceParam_PreserveRegs

VoiceParam_VolCheckGuard:
	ldda8 l, 37320
	ld xix, 0xf1a0
	cp_srib_im 0x03, 0xf0, 0xec, 0x0f
	jr z, VoiceParam_VolDone
	ld xix, 0x90ce
	ld_srib3 A, 0x03, 0xf0, 0xec
	cp a, 0x10
	jr z, VoiceParam_VolDone
	set 7, a
	stda8 37093, a
	ldda16 xbc, 37211
	ldda16 xde, 37213
	call MIDI_DispatchCC_Guarded

VoiceParam_VolDone:
	ret

VoiceParam_StorePan:
	extz hl
	ldda8 l, 37320
	sll l, 1
	ld xix, 0x9472
	ldda16 xwa, 37303
	and wa, 0x7f7f
	set 7, a
	st_dri3w WA, 0x07, 0xf0, 0xec
	ret

VoiceParam_WritePan:
	ldb c, 0xb1
	ld xix, 0xf1a0
	ldda8 l, 37320
	ld_srib3 L, 0x03, 0xf0, 0xec
	ld xix, 0xfcba03
	ld_srib3 B, 0x03, 0xf0, 0xec
	stda16 37211, xbc
	and de, 0x7f7f
	stda16 37213, xde
	call PartCtrl_CheckBitmaskBit
	jr nc, VoiceParam_PanCheckGuard
	ldda16 xwa, 37211
	stda16 37159, xwa
	ldda16 xwa, 37213
	stda16 37161, xwa
	call SwbtWr_WriteParamBlockSafe

VoiceParam_PanCheckGuard:
	ldda8 l, 37320
	ld xix, 0xf1a0
	cp_srib_im 0x03, 0xf0, 0xec, 0x0f
	jr z, VoiceParam_PanDone
	ld xix, 0x90ce
	ld_srib3 A, 0x03, 0xf0, 0xec
	cp a, 0x10
	jr z, VoiceParam_PanDone
	set 7, a
	stda8 37093, a
	ldda16 xbc, 37211
	ldda16 xde, 37213
	call MIDI_DispatchCC_Guarded

VoiceParam_PanDone:
	ret

VoiceNote_StoreBankSelect:

	ldda8 e, 37303
	extz hl
	ldda8 l, 37320
	bitda 7, 10413

	; LD SP, (XBC)
	; BIT 7, (28ADh)

	jr nz, VoiceNote_WriteBankAndCC
	set 7, e
	ld xix, 0x9432
	lda_dri3 XIY, 0x07, 0xf0, 0xec
	ret

VoiceNote_WriteBankAndCC:
	ldw bc, 0x1b0
	extz hl
	ldda8 l, 37320
	ld xix, 0xf1a0
	ld_srib3 A, 0x07, 0xf0, 0xec
	cp a, 0xf
	jr z, VoiceNote_SetupCCParams
	ldb c, 0xb3
	ld xix, 0xfcba03
	ld_srib3 B, 0x03, 0xf0, 0xe0

VoiceNote_SetupCCParams:
	stda16 37211, xbc
	ldb d, 0x7f
	stda16 37213, xde
	call PartCtrl_CheckBitmaskBit
	jr nc, MIDI_VoiceNote_CtrlExit
	cpdi8 37211, 176
	jr z, VoiceNote_CheckBankSelect
	ldda16 xwa, 37211
	stda16 37159, xwa
	ldda16 xwa, 37213
	stda16 37161, xwa
	call SwbtWr_WriteVoiceParam_PreserveRegs
	jr MIDI_VoiceNote_CtrlExit

VoiceNote_CheckBankSelect:
	bitda 7, 10413
	jr nz, VoiceNote_ApplyBankSelect
	bitda 7, 10414
	jr z, VoiceNote_CtrlDone

VoiceNote_ApplyBankSelect:
	ldda8 a, 37213
	set 7, a
	stda8 36576, a
	call Audio_WriteBankSelectParams
	bitda 7, 10413
	jr z, MIDI_VoiceNote_CtrlExit
	resda 7, 10413

MIDI_VoiceNote_CtrlExit:
	extz hl
	ldda8 l, 37320
	ld xix, 0x90ce
	ld_srib3 A, 0x07, 0xf0, 0xec
	cp a, 0x10
	jr z, VoiceNote_CtrlDone
	set 7, a
	stda8 37093, a
	ldda16 xbc, 37211
	ldda16 xde, 37213
	call MIDI_DispatchCC_Guarded

VoiceNote_CtrlDone:
	ret

; MIDI voice note dispatch
MidiVoiceNote_Dispatch:
	ldda8 l, 37301
	and l, 0x3
	sll l, 2
	ld xix, 0xfcb6f9
	ld_sril3 XIX, 0x03, 0xf0, 0xec
	jp (xix)
MidiVoiceNote_Dispatch_Table:
	.byte 0x09, 0xb7, 0xfc, 0x00, 0x19, 0xb7, 0xfc, 0x00
	.byte 0x29, 0xb7, 0xfc, 0x00, 0x39, 0xb7, 0xfc, 0x00

MidiVoiceNote_LookupMode0:
	ld xiy, 0xfcba26
	ld xbc, 0xf
	ldda8 l, 37304
	jr MidiPart_FindChannelInTable

MidiVoiceNote_LookupMode1:
	ld xiy, 0xfcba17
	ld xbc, 0xf
	ldda8 l, 37304
	jr MidiPart_FindChannelInTable

MidiVoiceNote_LookupMode2:
	ld xiy, 0xfcba17
	ld xbc, 0xf
	ldda8 l, 37305
	jr MidiPart_FindChannelInTable

MidiVoiceNote_LookupMode3:
	ld xiy, 0xfcba35
	ld xbc, 0x11
	ldda8 l, 37304

MidiPart_FindChannelInTable:
	cp xbc, 0x0
	jr z, MidiPart_NoChannelFound
	stda8 37320, l
	ld xix, 0xf1a0
	ld_srib3 W, 0x07, 0xf0, 0xec
	stda8 37325, w

MidiPart_ScanNextEntry:
	ld_spib A, 0xf4
	cp a, w
	jr z, MidiPart_ScanDone
	djnz xbc, MidiPart_ScanNextEntry

MidiPart_NoChannelFound:
	stdi8 37301, 255

MidiPart_ScanDone:
	ret

MidiNote_RhythmPartDispatch:
	cp bc, 0x48
	jrl nz, MidiNoteVel_Handler_2
	stda16 37211, xbc
	stda16 37213, xde
	stda8 37320, a
	stda8 37111, c
	ld hl, de
	call PartCtrl_WriteProgramChange
	stda16 37327, xhl
	call PartCtrl_CheckBitmaskBit
	jr nc, MidiPart_ChannelDispatch
	ld xix, 0xfc5a
	call MIDI_SetupChannelParams
	ldda16 xwa, 37213
	ld (xix), a
	andmi8 (xix + 1), 0x80
	or (xix + 1), w
	pushw hl
	ldda8 a, 37214
	ldb w, 0x7f
	ldw de, 0x148
	call SwbtWr_QueuePostEvent
	ldda8 a, 37213
	ldb w, 0xff
	ldw de, 0x48
	call SwbtWr_QueuePostEvent
	popw hl

; MIDI part channel dispatch
MidiPart_ChannelDispatch:
	extz hl
	ldda8 l, 37320
	ld xix, 0xf1a0
	cp_srib_im 0x07, 0xf0, 0xec, 0x10
	jrl nz, MidiNoteVel_Handler_2
	ld xix, 0x90ce
	ld_srib3 A, 0x07, 0xf0, 0xec
	cp a, 0x10
	jrl nz, MidiNoteVel_Handler_2
	set 7, a
	stda8 37093, a
	xor h, h
	ldda8 l, 64848
	and l, 0x3
	sll hl, 2
	ld xix, 0xfcb80d
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	jp (xix)


MidiNote_VelocityHandler_Table:
	.long MidiNoteVel_Handler_0
	.long MidiNoteVel_Handler_1
	.long MidiNoteVel_Handler_2
	.long MidiNoteVel_Handler_2

MidiNoteVel_Handler_0:
	ldw	bc, 5249
	xor	de, de
	bitda	7, 37327
	jr	z, 2
	inc	1, e
	call	MIDI_DispatchCC_Guarded
	xor	h, h
	ldda8	l, 37320
	ld	xix, 37070
	ld_rrb	a, xix, hl
	set	7, a
	stda8	37093, a
	ldw	bc, 20
	ldda8	e, 37327
	res	7, e
	ldb	d, 255
	call	MIDI_DispatchCC_Guarded
	jr	t, 0x3f

MidiNoteVel_Handler_1:
	ldw	bc, 5249
	xor	d, d
	bitda	7, 37213
	jr	z, 2
	ldb	d, 1
	ldda8	e, 37214
	sll	e, 4
	call	MIDI_DispatchCC_Guarded
	extz	hl
	ldda8	l, 37320
	ld	xix, 37070
	ld_rrb	a, xix, hl
	set	7, a
	stda8	37093, a
	ldw	bc, 20
	ldda8	e, 37213
	res	7, e
	ldb	d, 255
	call	MIDI_DispatchCC_Guarded

MidiNoteVel_Handler_2:
	ret

SeqVoice_UpdateTempoParam:
	cp bc, 0x748
	jr nz, SeqVoice_TempoDone
	stda8 37320, a
	call PartCtrl_CheckBitmaskBit
	jr nc, SeqVoice_TempoDone
	and d, 0x30
	call MIDI_WriteVoiceParamCC
	ldda16 xde, 37159
	ldda16 xwa, 37161
	stdi8 37162, 0
	call SwbtWr_QueuePostEvent
	setda 3, 36178

SeqVoice_TempoDone:
	ret

PendingParam_ScanAllTables:
	ld xiy, 0x94d2
	ldw bc, 0x10

PendingExpr_ScanEntry:
	bitm 7, (xiy)
	jr z, PendingExpr_NextEntry
	resm 7, (xiy)
	ld e, (xiy)
	ld xhl, xiy
	sub xhl, 0x94d2
	stda8 37320, l
	pushw bc
	push xiy
	calr VoiceParam_WriteExpression
	pop xiy
	popw bc

PendingExpr_NextEntry:
	inc 1, xiy
	djnz xbc, PendingExpr_ScanEntry
	ld xiy, 0x9452
	ldw bc, 0x10

PendingVol_ScanEntry:
	bitm 7, (xiy)
	jr z, PendingVol_NextEntry
	resm 7, (xiy)
	ld e, (xiy)
	ld xhl, xiy
	sub xhl, 0x9452
	stda8 37320, l
	pushw bc
	push xiy
	calr VoiceParam_WriteVolume
	pop xiy
	popw bc

PendingVol_NextEntry:
	inc 1, xiy
	djnz xbc, PendingVol_ScanEntry
	ld xiy, 0x9472
	ldw bc, 0x10

PendingPan_ScanEntry:
	bitm 7, (xiy)
	jr z, PendingPan_NextEntry
	resm 7, (xiy)
	ld de, (xiy)
	ld xhl, xiy
	sub xhl, 0x9472
	srl l, 1
	stda8 37320, l
	pushw bc
	push xiy
	calr VoiceParam_WritePan
	pop xiy
	popw bc

PendingPan_NextEntry:
	inc 2, xiy
	djnz xbc, PendingPan_ScanEntry
	ld xiy, 0x9432
	ldw bc, 0x10

PendingBank_ScanEntry:
	bitm 7, (xiy)
	jr z, PendingBank_NextEntry
	resm 7, (xiy)
	ld e, (xiy)
	ld xhl, xiy
	sub xhl, 0x9432
	stda8 37320, l
	pushw bc
	push xiy
	calr VoiceNote_WriteBankAndCC
	pop xiy
	popw bc

PendingBank_NextEntry:
	inc 1, xiy
	djnz xbc, PendingBank_ScanEntry
	ld xiy, 0x94b2
	ldw bc, 0x10

PendingPartCC_ScanEntry:
	bitm 7, (xiy)
	jr z, PendingPartCC_NextEntry
	resm 7, (xiy)
	ld e, (xiy)
	ld hl, iy
	sub xhl, 0x94b2
	stda8 37320, l
	pushw bc
	push xiy
	calr MidiPartCC_WriteAndDispatch
	pop xiy
	popw bc

PendingPartCC_NextEntry:
	inc 1, xiy
	djnz xbc, PendingPartCC_ScanEntry
	ret

PartCtrl_CheckBitmaskBit:
	pushw wa
	pushw bc
	ldda16 xwa, 61904
	ldda8 c, 37320
	inc 1, c

PartCtrl_ShiftBitmask:
	srl wa, 1
	djnz8 c, PartCtrl_ShiftBitmask
	popw bc
	popw wa
	ret

AudioCtrl_SaveAllRegs:
	stda32 37175, xwa
	stda32 37179, xbc
	stda32 37183, xde
	stda32 37187, xhl
	stda32 37191, xix
	stda32 37195, xiy
	stda32 37199, xiz
	ret

AudioCtrl_RestoreAllRegs:
	ldda32 xwa, 37175
	ldda32 xbc, 37179
	ldda32 xde, 37183
	ldda32 xhl, 37187
	ldda32 xix, 37191
	ldda32 xiy, 37195
	ldda32 xiz, 37199
	ret

VoiceMode_ParamConfigTables:
	.byte 0xb1, 0x17, 0x7f, 0x02, 0xb2, 0x17, 0x7f, 0x03
	.byte 0xb3, 0x17, 0x7f, 0x04, 0xb0, 0x01, 0x7f, 0x04
	.byte 0x17, 0x00, 0xff, 0x00, 0x17, 0x04, 0x48, 0x01
	.byte 0x17, 0x08, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x00, 0x02, 0x01, 0x07
	.byte 0x08, 0x09, 0x0a, 0x0b, 0x04, 0x05, 0x06, 0x03
	.byte 0x0f, 0x15, 0x15, 0x00, 0x00, 0x0c, 0x0d, 0x0e
	.byte 0x00, 0x02, 0x01, 0x08, 0x09, 0x0a, 0x0b, 0x03
	.byte 0x04, 0x05, 0x06, 0x07, 0x11, 0x12, 0x13, 0x00
	.byte 0x02, 0x01, 0x08, 0x09, 0x0a, 0x0b, 0x03, 0x04
	.byte 0x05, 0x06, 0x07, 0x11, 0x12, 0x13, 0x00, 0x02
	.byte 0x01, 0x08, 0x09, 0x0a, 0x0b, 0x03, 0x04, 0x05
	.byte 0x06, 0x07, 0x11, 0x12, 0x13, 0x0c, 0x0f, 0xff
	.byte 0x97, 0xba, 0xfc, 0x00, 0x47, 0xbb, 0xfc, 0x00
	.byte 0xef, 0xba, 0xfc, 0x00, 0xaf, 0xbc, 0xfc, 0x00
	.byte 0xf3, 0xbc, 0xfc, 0x00, 0x37, 0xbd, 0xfc, 0x00
	.byte 0x7b, 0xbd, 0xfc, 0x00, 0xbf, 0xbd, 0xfc, 0x00
	.byte 0xe3, 0xbb, 0xfc, 0x00, 0x27, 0xbc, 0xfc, 0x00
	.byte 0x6b, 0xbc, 0xfc, 0x00, 0x9f, 0xbb, 0xfc, 0x00
	.byte 0xcf, 0xbe, 0xfc, 0x00, 0xf7, 0xbe, 0xfc, 0x00
	.byte 0xff, 0xbe, 0xfc, 0x00, 0x37, 0xbf, 0xfc, 0x00
	.byte 0x23, 0xbf, 0xfc, 0x00, 0x03, 0xbe, 0xfc, 0x00
	.byte 0x47, 0xbe, 0xfc, 0x00, 0x8b, 0xbe, 0xfc, 0x00
	.byte 0xb4, 0x00, 0x7f, 0x06, 0xb1, 0x00, 0x7f, 0x03
	.byte 0xb2, 0x00, 0x7f, 0x04, 0xb3, 0x00, 0x7f, 0x05
	.byte 0x00, 0x00, 0xff, 0x00, 0x00, 0x03, 0xff, 0x01
	.byte 0x00, 0x04, 0x48, 0x01, 0x00, 0x05, 0x7f, 0x01
	.byte 0x00, 0x07, 0x7f, 0x01, 0x00, 0x08, 0x7f, 0x01
	.byte 0x00, 0x0b, 0x7f, 0x01, 0x00, 0x0a, 0xff, 0x01
	.byte 0x00, 0x09, 0x7f, 0x01, 0x44, 0x03, 0xff, 0x01
	.byte 0x44, 0x04, 0xff, 0x01, 0x44, 0x05, 0xff, 0x01
	.byte 0x44, 0x06, 0xff, 0x01, 0x44, 0x07, 0x3f, 0x01
	.byte 0xad, 0x00, 0x7f, 0x01, 0xae, 0x00, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x01, 0x7f, 0x06, 0xb1, 0x01, 0x7f, 0x03
	.byte 0xb2, 0x01, 0x7f, 0x04, 0xb3, 0x01, 0x7f, 0x05
	.byte 0x01, 0x00, 0xff, 0x00, 0x01, 0x03, 0xff, 0x01
	.byte 0x01, 0x04, 0x48, 0x01, 0x01, 0x05, 0x7f, 0x01
	.byte 0x01, 0x07, 0x7f, 0x01, 0x01, 0x08, 0x7f, 0x01
	.byte 0x01, 0x0b, 0x7f, 0x01, 0x01, 0x0a, 0xff, 0x01
	.byte 0x01, 0x09, 0x7f, 0x01, 0x45, 0x03, 0xff, 0x01
	.byte 0x45, 0x04, 0xff, 0x01, 0x45, 0x05, 0xff, 0x01
	.byte 0x45, 0x06, 0xff, 0x01, 0x45, 0x07, 0x3f, 0x01
	.byte 0xad, 0x01, 0x7f, 0x01, 0xae, 0x01, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x02, 0x7f, 0x06, 0xb1, 0x02, 0x7f, 0x03
	.byte 0xb2, 0x02, 0x7f, 0x04, 0xb3, 0x02, 0x7f, 0x05
	.byte 0x02, 0x00, 0xff, 0x00, 0x02, 0x03, 0xff, 0x01
	.byte 0x02, 0x04, 0x48, 0x01, 0x02, 0x05, 0x7f, 0x01
	.byte 0x02, 0x07, 0x7f, 0x01, 0x02, 0x08, 0x7f, 0x01
	.byte 0x02, 0x0b, 0x7f, 0x01, 0x02, 0x0a, 0xff, 0x01
	.byte 0x02, 0x09, 0x7f, 0x01, 0x46, 0x03, 0xff, 0x01
	.byte 0x46, 0x04, 0xff, 0x01, 0x46, 0x05, 0xff, 0x01
	.byte 0x46, 0x06, 0xff, 0x01, 0x46, 0x07, 0x3f, 0x01
	.byte 0xad, 0x02, 0x7f, 0x01, 0xae, 0x02, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x03, 0x7f, 0x06, 0xb1, 0x03, 0x7f, 0x03
	.byte 0xb2, 0x03, 0x7f, 0x04, 0xb3, 0x03, 0x7f, 0x05
	.byte 0x03, 0x00, 0xff, 0x00, 0x03, 0x03, 0xff, 0x01
	.byte 0x03, 0x04, 0x48, 0x01, 0x03, 0x05, 0x7f, 0x01
	.byte 0x03, 0x07, 0x7f, 0x01, 0x03, 0x08, 0x7f, 0x01
	.byte 0x03, 0x0b, 0x7f, 0x01, 0x03, 0x0a, 0xff, 0x01
	.byte 0x03, 0x09, 0x7f, 0x01, 0xad, 0x03, 0x7f, 0x01
	.byte 0xae, 0x03, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x04, 0x7f, 0x06
	.byte 0xb1, 0x04, 0x7f, 0x03, 0xb2, 0x04, 0x7f, 0x04
	.byte 0xb3, 0x04, 0x7f, 0x05, 0x04, 0x00, 0xff, 0x00
	.byte 0x04, 0x03, 0xff, 0x01, 0x04, 0x04, 0x48, 0x01
	.byte 0x04, 0x05, 0x7f, 0x01, 0x04, 0x07, 0x7f, 0x01
	.byte 0x04, 0x08, 0x7f, 0x01, 0x04, 0x0b, 0x7f, 0x01
	.byte 0x04, 0x0a, 0xff, 0x01, 0x04, 0x09, 0x7f, 0x01
	.byte 0xad, 0x04, 0x7f, 0x01, 0xae, 0x04, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x05, 0x7f, 0x06, 0xb1, 0x05, 0x7f, 0x03
	.byte 0xb2, 0x05, 0x7f, 0x04, 0xb3, 0x05, 0x7f, 0x05
	.byte 0x05, 0x00, 0xff, 0x00, 0x05, 0x03, 0xff, 0x01
	.byte 0x05, 0x04, 0x48, 0x01, 0x05, 0x05, 0x7f, 0x01
	.byte 0x05, 0x07, 0x7f, 0x01, 0x05, 0x08, 0x7f, 0x01
	.byte 0x05, 0x0b, 0x7f, 0x01, 0x05, 0x0a, 0xff, 0x01
	.byte 0x05, 0x09, 0x7f, 0x01, 0xad, 0x05, 0x7f, 0x01
	.byte 0xae, 0x05, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x06, 0x7f, 0x06
	.byte 0xb1, 0x06, 0x7f, 0x03, 0xb2, 0x06, 0x7f, 0x04
	.byte 0xb3, 0x06, 0x7f, 0x05, 0x06, 0x00, 0xff, 0x00
	.byte 0x06, 0x03, 0xff, 0x01, 0x06, 0x04, 0x48, 0x01
	.byte 0x06, 0x05, 0x7f, 0x01, 0x06, 0x07, 0x7f, 0x01
	.byte 0x06, 0x08, 0x7f, 0x01, 0x06, 0x0b, 0x7f, 0x01
	.byte 0x06, 0x0a, 0xff, 0x01, 0x06, 0x09, 0x7f, 0x01
	.byte 0xad, 0x06, 0x7f, 0x01, 0xae, 0x06, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x07, 0x7f, 0x06, 0xb1, 0x07, 0x7f, 0x03
	.byte 0xb2, 0x07, 0x7f, 0x04, 0xb3, 0x07, 0x7f, 0x05
	.byte 0x07, 0x00, 0xff, 0x00, 0x07, 0x03, 0xff, 0x01
	.byte 0x07, 0x04, 0x48, 0x01, 0x07, 0x05, 0x7f, 0x01
	.byte 0x07, 0x07, 0x7f, 0x01, 0x07, 0x08, 0x7f, 0x01
	.byte 0x07, 0x0b, 0x7f, 0x01, 0x07, 0x0a, 0xff, 0x01
	.byte 0x07, 0x09, 0x7f, 0x01, 0xad, 0x07, 0x7f, 0x01
	.byte 0xae, 0x07, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x08, 0x7f, 0x06
	.byte 0xb1, 0x08, 0x7f, 0x03, 0xb2, 0x08, 0x7f, 0x04
	.byte 0xb3, 0x08, 0x7f, 0x05, 0x08, 0x00, 0xff, 0x00
	.byte 0x08, 0x03, 0xff, 0x01, 0x08, 0x04, 0x48, 0x01
	.byte 0x08, 0x05, 0x7f, 0x01, 0x08, 0x07, 0x7f, 0x01
	.byte 0x08, 0x08, 0x7f, 0x01, 0x08, 0x0b, 0x7f, 0x01
	.byte 0x08, 0x0a, 0xff, 0x01, 0x08, 0x09, 0x7f, 0x01
	.byte 0xad, 0x08, 0x7f, 0x01, 0xae, 0x08, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x09, 0x7f, 0x06, 0xb1, 0x09, 0x7f, 0x03
	.byte 0xb2, 0x09, 0x7f, 0x04, 0xb3, 0x09, 0x7f, 0x05
	.byte 0x09, 0x00, 0xff, 0x00, 0x09, 0x03, 0xff, 0x01
	.byte 0x09, 0x04, 0x48, 0x01, 0x09, 0x05, 0x7f, 0x01
	.byte 0x09, 0x07, 0x7f, 0x01, 0x09, 0x08, 0x7f, 0x01
	.byte 0x09, 0x0b, 0x7f, 0x01, 0x09, 0x0a, 0xff, 0x01
	.byte 0x09, 0x09, 0x7f, 0x01, 0xad, 0x09, 0x7f, 0x01
	.byte 0xae, 0x09, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x0a, 0x7f, 0x06
	.byte 0xb1, 0x0a, 0x7f, 0x03, 0xb2, 0x0a, 0x7f, 0x04
	.byte 0xb3, 0x0a, 0x7f, 0x05, 0x0a, 0x00, 0xff, 0x00
	.byte 0x0a, 0x03, 0xff, 0x01, 0x0a, 0x04, 0x48, 0x01
	.byte 0x0a, 0x05, 0x7f, 0x01, 0x0a, 0x07, 0x7f, 0x01
	.byte 0x0a, 0x08, 0x7f, 0x01, 0x0a, 0x0b, 0x7f, 0x01
	.byte 0x0a, 0x0a, 0xff, 0x01, 0x0a, 0x09, 0x7f, 0x01
	.byte 0xad, 0x0a, 0x7f, 0x01, 0xae, 0x0a, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x0b, 0x7f, 0x06, 0xb1, 0x0b, 0x7f, 0x03
	.byte 0xb2, 0x0b, 0x7f, 0x04, 0xb3, 0x0b, 0x7f, 0x05
	.byte 0x0b, 0x00, 0xff, 0x00, 0x0b, 0x03, 0xff, 0x01
	.byte 0x0b, 0x04, 0x48, 0x01, 0x0b, 0x05, 0x7f, 0x01
	.byte 0x0b, 0x07, 0x7f, 0x01, 0x0b, 0x08, 0x7f, 0x01
	.byte 0x0b, 0x0b, 0x7f, 0x01, 0x0b, 0x0a, 0xff, 0x01
	.byte 0x0b, 0x09, 0x7f, 0x01, 0xad, 0x0b, 0x7f, 0x01
	.byte 0xae, 0x0b, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x0c, 0x7f, 0x06
	.byte 0xb1, 0x0c, 0x7f, 0x03, 0xb2, 0x0c, 0x7f, 0x04
	.byte 0xb3, 0x0c, 0x7f, 0x05, 0x0c, 0x00, 0xff, 0x00
	.byte 0x0c, 0x03, 0xff, 0x01, 0x0c, 0x04, 0x48, 0x01
	.byte 0x0c, 0x05, 0x7f, 0x01, 0x0c, 0x07, 0x7f, 0x01
	.byte 0x0c, 0x08, 0x7f, 0x01, 0x0c, 0x0b, 0x7f, 0x01
	.byte 0x0c, 0x0a, 0xff, 0x01, 0x0c, 0x09, 0x7f, 0x01
	.byte 0xad, 0x0c, 0x7f, 0x01, 0xae, 0x0c, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x0d, 0x7f, 0x06, 0xb1, 0x0d, 0x7f, 0x03
	.byte 0xb2, 0x0d, 0x7f, 0x04, 0xb3, 0x0d, 0x7f, 0x05
	.byte 0x0d, 0x00, 0xff, 0x00, 0x0d, 0x03, 0xff, 0x01
	.byte 0x0d, 0x04, 0x48, 0x01, 0x0d, 0x05, 0x7f, 0x01
	.byte 0x0d, 0x07, 0x7f, 0x01, 0x0d, 0x08, 0x7f, 0x01
	.byte 0x0d, 0x0b, 0x7f, 0x01, 0x0d, 0x0a, 0xff, 0x01
	.byte 0x0d, 0x09, 0x7f, 0x01, 0xad, 0x0d, 0x7f, 0x01
	.byte 0xae, 0x0d, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x0e, 0x7f, 0x06
	.byte 0xb1, 0x0e, 0x7f, 0x03, 0xb2, 0x0e, 0x7f, 0x04
	.byte 0xb3, 0x0e, 0x7f, 0x05, 0x0e, 0x00, 0xff, 0x00
	.byte 0x0e, 0x03, 0xff, 0x01, 0x0e, 0x04, 0x48, 0x01
	.byte 0x0e, 0x05, 0x7f, 0x01, 0x0e, 0x07, 0x7f, 0x01
	.byte 0x0e, 0x08, 0x7f, 0x01, 0x0e, 0x0b, 0x7f, 0x01
	.byte 0x0e, 0x0a, 0xff, 0x01, 0x0e, 0x09, 0x7f, 0x01
	.byte 0xad, 0x0e, 0x7f, 0x01, 0xae, 0x0e, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb3, 0x0f, 0x7f, 0x05, 0x0f, 0x00, 0xff, 0x00
	.byte 0x0f, 0x03, 0xff, 0x01, 0x0f, 0x04, 0x48, 0x01
	.byte 0x0f, 0x05, 0x7f, 0x01, 0x0f, 0x07, 0x7f, 0x01
	.byte 0xad, 0x0f, 0x7f, 0x01, 0xae, 0x0f, 0x7f, 0x01
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0x48, 0x03, 0x0f, 0x01, 0x90, 0x03, 0x02, 0x01
	.byte 0x10, 0x03, 0xff, 0x01, 0x11, 0x03, 0xff, 0x01
	.byte 0x12, 0x03, 0xff, 0x01, 0x13, 0x03, 0xff, 0x01
	.byte 0x14, 0x03, 0xff, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x48, 0x00, 0xff, 0x00
	.byte 0x48, 0x08, 0xff, 0x02, 0x48, 0x07, 0x30, 0x01
	.fill 8, 1, 0xff
	.byte 0x48, 0x03, 0x0f, 0x01, 0x48, 0x04, 0x50, 0x01
	.byte 0x48, 0x00, 0xff, 0x00, 0x48, 0x07, 0x30, 0x01
	.byte 0x48, 0x08, 0xff, 0x02, 0x90, 0x00, 0x1f, 0x01
	.byte 0x90, 0x01, 0x1f, 0x01, 0x90, 0x03, 0x02, 0x01
	.byte 0x60, 0x01, 0xc0, 0x01, 0x70, 0x00, 0x07, 0x01
	.byte 0x70, 0x02, 0xff, 0x01, 0x98, 0x0b, 0xc0, 0x01
	.byte 0x98, 0x01, 0x7f, 0x01, 0x98, 0x02, 0x80, 0x01
	.byte 0x98, 0x03, 0x01, 0x01, 0xb0, 0x01, 0x7f, 0x05
	.byte 0x10, 0x03, 0xff, 0x01, 0x11, 0x03, 0xff, 0x01
	.byte 0x12, 0x03, 0xff, 0x01, 0x13, 0x03, 0xff, 0x01
	.byte 0x14, 0x03, 0xff, 0x01, 0x72, 0x03, 0xff, 0x01
	.byte 0x72, 0x07, 0x7f, 0x06, 0xff, 0xff, 0xff, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xf3, 0xbf, 0xfc, 0x00
	.byte 0xfb, 0xc0, 0xfc, 0x00, 0x77, 0xc0, 0xfc, 0x00
	.byte 0x3f, 0xc2, 0xfc, 0x00, 0x6f, 0xc2, 0xfc, 0x00
	.byte 0x9f, 0xc2, 0xfc, 0x00, 0xcf, 0xc2, 0xfc, 0x00
	.byte 0xff, 0xc2, 0xfc, 0x00, 0xaf, 0xc1, 0xfc, 0x00
	.byte 0xdf, 0xc1, 0xfc, 0x00, 0x0f, 0xc2, 0xfc, 0x00
	.byte 0x7f, 0xc1, 0xfc, 0x00, 0xbf, 0xc3, 0xfc, 0x00
	.byte 0xdf, 0xc3, 0xfc, 0x00, 0xef, 0xc3, 0xfc, 0x00
	.byte 0x2f, 0xc4, 0xfc, 0x00, 0x1b, 0xc4, 0xfc, 0x00
	.byte 0x2f, 0xc3, 0xfc, 0x00, 0x5f, 0xc3, 0xfc, 0x00
	.byte 0x8f, 0xc3, 0xfc, 0x00, 0x00, 0x03, 0xff, 0x05
	.byte 0x00, 0x04, 0x48, 0x06, 0x00, 0x05, 0x7f, 0x06
	.byte 0x00, 0x07, 0x7f, 0x06, 0x00, 0x08, 0x7f, 0x06
	.byte 0x00, 0x0b, 0x7f, 0x06, 0x00, 0x0a, 0xff, 0x06
	.byte 0x00, 0x09, 0x7f, 0x06, 0x44, 0x03, 0xff, 0x06
	.byte 0x44, 0x04, 0xff, 0x06, 0x44, 0x05, 0xff, 0x06
	.byte 0x44, 0x06, 0xff, 0x06, 0x44, 0x07, 0x3f, 0x06
	.byte 0xad, 0x00, 0x7f, 0x03, 0xae, 0x00, 0x7f, 0x04
	.byte 0x9a, 0x04, 0xff, 0x06, 0x9a, 0x05, 0xff, 0x06
	.byte 0x9a, 0x06, 0xff, 0x06, 0x9a, 0x07, 0xff, 0x06
	.byte 0x9a, 0x08, 0xff, 0x06, 0x9a, 0x09, 0xff, 0x06
	.byte 0x9a, 0x0a, 0xff, 0x06, 0x9a, 0x0b, 0xff, 0x06
	.byte 0x9a, 0x0c, 0xff, 0x06, 0x9a, 0x0d, 0xff, 0x06
	.byte 0x9a, 0x0e, 0xff, 0x06, 0x9a, 0x0f, 0xff, 0x06
	.byte 0x9a, 0x10, 0xff, 0x06, 0x9a, 0x11, 0xff, 0x06
	.byte 0x9a, 0x12, 0xff, 0x06, 0x9a, 0x13, 0xff, 0x06
	.fill 8, 1, 0xff
	.byte 0x01, 0x03, 0xff, 0x05, 0x01, 0x04, 0x48, 0x06
	.byte 0x01, 0x05, 0x7f, 0x06, 0x01, 0x07, 0x7f, 0x06
	.byte 0x01, 0x08, 0x7f, 0x06, 0x01, 0x0b, 0x7f, 0x06
	.byte 0x01, 0x0a, 0xff, 0x06, 0x01, 0x09, 0x7f, 0x06
	.byte 0x45, 0x03, 0xff, 0x06, 0x45, 0x04, 0xff, 0x06
	.byte 0x45, 0x05, 0xff, 0x06, 0x45, 0x06, 0xff, 0x06
	.byte 0x45, 0x07, 0x3f, 0x06, 0xad, 0x01, 0x7f, 0x03
	.byte 0xae, 0x01, 0x7f, 0x04, 0x9a, 0x04, 0xff, 0x06
	.byte 0x9a, 0x05, 0xff, 0x06, 0x9a, 0x06, 0xff, 0x06
	.byte 0x9a, 0x07, 0xff, 0x06, 0x9a, 0x08, 0xff, 0x06
	.byte 0x9a, 0x09, 0xff, 0x06, 0x9a, 0x0a, 0xff, 0x06
	.byte 0x9a, 0x0b, 0xff, 0x06, 0x9a, 0x0c, 0xff, 0x06
	.byte 0x9a, 0x0d, 0xff, 0x06, 0x9a, 0x0e, 0xff, 0x06
	.byte 0x9a, 0x0f, 0xff, 0x06, 0x9a, 0x10, 0xff, 0x06
	.byte 0x9a, 0x11, 0xff, 0x06, 0x9a, 0x12, 0xff, 0x06
	.byte 0x9a, 0x13, 0xff, 0x06, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x02, 0x03, 0xff, 0x05
	.byte 0x02, 0x04, 0x48, 0x06, 0x02, 0x05, 0x7f, 0x06
	.byte 0x02, 0x07, 0x7f, 0x06, 0x02, 0x08, 0x7f, 0x06
	.byte 0x02, 0x0b, 0x7f, 0x06, 0x02, 0x0a, 0xff, 0x06
	.byte 0x02, 0x09, 0x7f, 0x06, 0x46, 0x03, 0xff, 0x06
	.byte 0x46, 0x04, 0xff, 0x06, 0x46, 0x05, 0xff, 0x06
	.byte 0x46, 0x06, 0xff, 0x06, 0x46, 0x07, 0x3f, 0x06
	.byte 0xad, 0x02, 0x7f, 0x03, 0xae, 0x02, 0x7f, 0x04
	.byte 0x9a, 0x04, 0xff, 0x06, 0x9a, 0x05, 0xff, 0x06
	.byte 0x9a, 0x06, 0xff, 0x06, 0x9a, 0x07, 0xff, 0x06
	.byte 0x9a, 0x08, 0xff, 0x06, 0x9a, 0x09, 0xff, 0x06
	.byte 0x9a, 0x0a, 0xff, 0x06, 0x9a, 0x0b, 0xff, 0x06
	.byte 0x9a, 0x0c, 0xff, 0x06, 0x9a, 0x0d, 0xff, 0x06
	.byte 0x9a, 0x0e, 0xff, 0x06, 0x9a, 0x0f, 0xff, 0x06
	.byte 0x9a, 0x10, 0xff, 0x06, 0x9a, 0x11, 0xff, 0x06
	.byte 0x9a, 0x12, 0xff, 0x06, 0x9a, 0x13, 0xff, 0x06
	.fill 8, 1, 0xff
	.byte 0x03, 0x03, 0xff, 0x05, 0x03, 0x04, 0x48, 0x06
	.byte 0x03, 0x05, 0x7f, 0x06, 0x03, 0x07, 0x7f, 0x06
	.byte 0x03, 0x08, 0x7f, 0x06, 0x03, 0x0b, 0x7f, 0x06
	.byte 0x03, 0x0a, 0xff, 0x06, 0x03, 0x09, 0x7f, 0x06
	.byte 0xad, 0x03, 0x7f, 0x03, 0xae, 0x03, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x04, 0x03, 0xff, 0x05, 0x04, 0x04, 0x48, 0x06
	.byte 0x04, 0x05, 0x7f, 0x06, 0x04, 0x07, 0x7f, 0x06
	.byte 0x04, 0x08, 0x7f, 0x06, 0x04, 0x0b, 0x7f, 0x06
	.byte 0x04, 0x0a, 0xff, 0x06, 0x04, 0x09, 0x7f, 0x06
	.byte 0xad, 0x04, 0x7f, 0x03, 0xae, 0x04, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x05, 0x03, 0xff, 0x05, 0x05, 0x04, 0x48, 0x06
	.byte 0x05, 0x05, 0x7f, 0x06, 0x05, 0x07, 0x7f, 0x06
	.byte 0x05, 0x08, 0x7f, 0x06, 0x05, 0x0b, 0x7f, 0x06
	.byte 0x05, 0x0a, 0xff, 0x06, 0x05, 0x09, 0x7f, 0x06
	.byte 0xad, 0x05, 0x7f, 0x03, 0xae, 0x05, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x06, 0x03, 0xff, 0x05, 0x06, 0x04, 0x48, 0x06
	.byte 0x06, 0x05, 0x7f, 0x06, 0x06, 0x07, 0x7f, 0x06
	.byte 0x06, 0x08, 0x7f, 0x06, 0x06, 0x0b, 0x7f, 0x06
	.byte 0x06, 0x0a, 0xff, 0x06, 0x06, 0x09, 0x7f, 0x06
	.byte 0xad, 0x06, 0x7f, 0x03, 0xae, 0x06, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x07, 0x03, 0xff, 0x05, 0x07, 0x04, 0x48, 0x06
	.byte 0x07, 0x05, 0x7f, 0x06, 0x07, 0x07, 0x7f, 0x06
	.byte 0x07, 0x08, 0x7f, 0x06, 0x07, 0x0b, 0x7f, 0x06
	.byte 0x07, 0x0a, 0xff, 0x06, 0x07, 0x09, 0x7f, 0x06
	.byte 0xad, 0x07, 0x7f, 0x03, 0xae, 0x07, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x08, 0x03, 0xff, 0x05, 0x08, 0x04, 0x48, 0x06
	.byte 0x08, 0x05, 0x7f, 0x06, 0x08, 0x07, 0x7f, 0x06
	.byte 0x08, 0x08, 0x7f, 0x06, 0x08, 0x0b, 0x7f, 0x06
	.byte 0x08, 0x0a, 0xff, 0x06, 0x08, 0x09, 0x7f, 0x06
	.byte 0xad, 0x08, 0x7f, 0x03, 0xae, 0x08, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x09, 0x03, 0xff, 0x05, 0x09, 0x04, 0x48, 0x06
	.byte 0x09, 0x05, 0x7f, 0x06, 0x09, 0x07, 0x7f, 0x06
	.byte 0x09, 0x08, 0x7f, 0x06, 0x09, 0x0b, 0x7f, 0x06
	.byte 0x09, 0x0a, 0xff, 0x06, 0x09, 0x09, 0x7f, 0x06
	.byte 0xad, 0x09, 0x7f, 0x03, 0xae, 0x09, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0a, 0x03, 0xff, 0x05, 0x0a, 0x04, 0x48, 0x06
	.byte 0x0a, 0x05, 0x7f, 0x06, 0x0a, 0x07, 0x7f, 0x06
	.byte 0x0a, 0x08, 0x7f, 0x06, 0x0a, 0x0b, 0x7f, 0x06
	.byte 0x0a, 0x0a, 0xff, 0x06, 0x0a, 0x09, 0x7f, 0x06
	.byte 0xad, 0x0a, 0x7f, 0x03, 0xae, 0x0a, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0b, 0x03, 0xff, 0x05, 0x0b, 0x04, 0x48, 0x06
	.byte 0x0b, 0x05, 0x7f, 0x06, 0x0b, 0x07, 0x7f, 0x06
	.byte 0x0b, 0x08, 0x7f, 0x06, 0x0b, 0x0b, 0x7f, 0x06
	.byte 0x0b, 0x0a, 0xff, 0x06, 0x0b, 0x09, 0x7f, 0x06
	.byte 0xad, 0x0b, 0x7f, 0x03, 0xae, 0x0b, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0c, 0x03, 0xff, 0x05, 0x0c, 0x04, 0x48, 0x06
	.byte 0x0c, 0x05, 0x7f, 0x06, 0x0c, 0x07, 0x7f, 0x06
	.byte 0x0c, 0x08, 0x7f, 0x06, 0x0c, 0x0b, 0x7f, 0x06
	.byte 0x0c, 0x0a, 0xff, 0x06, 0x0c, 0x09, 0x7f, 0x06
	.byte 0xad, 0x0c, 0x7f, 0x03, 0xae, 0x0c, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0d, 0x03, 0xff, 0x05, 0x0d, 0x04, 0x48, 0x06
	.byte 0x0d, 0x05, 0x7f, 0x06, 0x0d, 0x07, 0x7f, 0x06
	.byte 0x0d, 0x08, 0x7f, 0x06, 0x0d, 0x0b, 0x7f, 0x06
	.byte 0x0d, 0x0a, 0xff, 0x06, 0x0d, 0x09, 0x7f, 0x06
	.byte 0xad, 0x0d, 0x7f, 0x03, 0xae, 0x0d, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0e, 0x03, 0xff, 0x05, 0x0e, 0x04, 0x48, 0x06
	.byte 0x0e, 0x05, 0x7f, 0x06, 0x0e, 0x07, 0x7f, 0x06
	.byte 0x0e, 0x08, 0x7f, 0x06, 0x0e, 0x0b, 0x7f, 0x06
	.byte 0x0e, 0x0a, 0xff, 0x06, 0x0e, 0x09, 0x7f, 0x06
	.byte 0xad, 0x0e, 0x7f, 0x03, 0xae, 0x0e, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0f, 0x03, 0xff, 0x05, 0x0f, 0x04, 0x48, 0x06
	.byte 0x0f, 0x05, 0x7f, 0x06, 0x0f, 0x07, 0x7f, 0x06
	.byte 0xad, 0x0f, 0x7f, 0x03, 0xae, 0x0f, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x48, 0x05, 0xfc, 0x01, 0x48, 0x06, 0xfc, 0x01
	.fill 8, 1, 0xff
	.byte 0x48, 0x05, 0xfc, 0x01, 0x48, 0x06, 0xfc, 0x01
	.byte 0x48, 0x03, 0x0f, 0x00, 0x90, 0x03, 0x02, 0x06
	.byte 0x10, 0x03, 0xff, 0x06, 0x11, 0x03, 0xff, 0x06
	.byte 0x12, 0x03, 0xff, 0x06, 0x13, 0x03, 0xff, 0x06
	.byte 0x14, 0x03, 0xff, 0x06, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x48, 0x05, 0xfc, 0x01
	.byte 0x48, 0x06, 0xfc, 0x01, 0x48, 0x07, 0x30, 0x06
	.fill 8, 1, 0xff
	.byte 0x48, 0x05, 0xfc, 0x01, 0x48, 0x06, 0xfc, 0x01
	.byte 0x48, 0x03, 0x0f, 0x00, 0x48, 0x04, 0x50, 0x06
	.byte 0x48, 0x07, 0x30, 0x06, 0x90, 0x00, 0x1f, 0x06
	.byte 0x90, 0x01, 0x1f, 0x06, 0x90, 0x03, 0x02, 0x06
	.byte 0x60, 0x01, 0xc0, 0x06, 0x70, 0x00, 0x07, 0x06
	.byte 0x70, 0x02, 0xff, 0x06, 0x98, 0x0b, 0xc0, 0x06
	.byte 0x98, 0x01, 0x7f, 0x06, 0x98, 0x02, 0x80, 0x06
	.byte 0x98, 0x03, 0x01, 0x06, 0x10, 0x03, 0xff, 0x06
	.byte 0x11, 0x03, 0xff, 0x06, 0x12, 0x03, 0xff, 0x06
	.byte 0x13, 0x03, 0xff, 0x06, 0x14, 0x03, 0xff, 0x06
	.byte 0x72, 0x03, 0xff, 0x06, 0x72, 0x07, 0x7f, 0x06
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xd7, 0xc4, 0xfc, 0x00
	.byte 0xf3, 0xc4, 0xfc, 0x00, 0xff, 0xff, 0xff, 0xff
	.byte 0x0f, 0xc5, 0xfc, 0x00, 0xff, 0xff, 0xff, 0xff
	.fill 8, 1, 0xff
	.byte 0x2b, 0xc5, 0xfc, 0x00, 0xff, 0xff, 0xff, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xb1, 0x10, 0x7f, 0x01, 0xb2, 0x10, 0x7f, 0x00
	.byte 0xb3, 0x10, 0x7f, 0x02, 0x10, 0x04, 0x08, 0x03
	.byte 0x10, 0x08, 0x7f, 0x04, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb1, 0x11, 0x7f, 0x01
	.byte 0xb2, 0x11, 0x7f, 0x00, 0xb3, 0x11, 0x7f, 0x02
	.byte 0x11, 0x04, 0x08, 0x03, 0x11, 0x08, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0xb1, 0x12, 0x7f, 0x01, 0xb2, 0x12, 0x7f, 0x00
	.byte 0xb3, 0x12, 0x7f, 0x02, 0x12, 0x04, 0x08, 0x03
	.byte 0x12, 0x08, 0x7f, 0x04, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb1, 0x13, 0x7f, 0x01
	.byte 0xb2, 0x13, 0x7f, 0x00, 0xb3, 0x13, 0x7f, 0x02
	.byte 0x13, 0x04, 0x08, 0x03, 0x13, 0x08, 0x7f, 0x04
	.fill 8, 1, 0xff
	stdi8	37112, 255
	ldda8	a, 64929
	and	a, 63
	ld	w, e
	and	w, 192
	or	a, w
	stda8	64929, a
	ld	e, a
	stda16	37159, bc
	stda16	37161, de
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	stdi8	37112, 255
	stda16	37159, bc
	stda16	37161, de
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	1434
	ret

MidiStream_ApplyPendingParams:
	cpdi8 36148, 14
	jr z, MidiStream_ApplyDone
	stdi8 37112, 255
	and d, 0x7
	jr z, MidiStream_ApplyDone
	call MIDI_WriteVoiceParamCC
	ldda8 a, 37162
	and a, 0x7
	jr z, MidiStream_CallFilterAndAudio
	call ToneGen_DispatchByMode
	ordi8 37113, 1

MidiStream_CallFilterAndAudio:
	call SwbtWr_WriteVoiceParam_PreserveRegs
	call MIDI_WriteResetSequence

MidiStream_ApplyDone:
	ret

MidiStream_DispatchData:
	calr	1382
	ret
	stdi8	37112, 255
	call	MIDI_WriteVoiceParamDirect
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	1364
	ret
	cp	bc, 176
	jr	z, 20
	cp	c, 31
	jr	ugt, 28
	set	7, e
	ld	xix, 38066
	.byte 0xf3
	pop_sr
	.byte 0xf0, 0xe4
	ld	xiy, 4176547176
	.byte 0x90
	nop
	swi	7
	stda8	36578, e
	call	Audio_WriteBankSelectParams
	ret
	calr	1320
	ret
	cp	c, 176
	jr	nz, 9
	set	7, e
	stda8	38130, e
	jr	18
	cp	b, 31
	jr	ugt, 13
	set	7, e
	ld	xix, 37938
	.byte 0xf3
	pop_sr
	.byte 0xf0, 0xe5
	ld	xiy, 84090382
	ret
	cp	b, 31
	jr	ugt, -10
	set	7, e
	ld	xix, 38002
	sll	b, 1
	.byte 0xf3
	pop_sr
	.byte 0xf0, 0xe5, 0x52
	ret
	calr	1257
	ret
	cp	b, 31
	jr	ugt, -36
	set	7, e
	ld	xix, 37970
	.byte 0xf3
	pop_sr
	.byte 0xf0, 0xe5
	ld	xiy, 80879118
	ret
	stdi8	37112, 255
	ldda16	bc, 38468
	ldda16	de, 38470
	call	MIDI_WriteVoiceParamCC
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	1208
	ret
	stdi8	37112, 255
	ldda16	wa, 38468
	stda16	37159, wa
	ldda16	wa, 38470
	stda16	37161, wa
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	1178
	ret
	stdi8	37112, 255
	ldda16	wa, 38468
	stda16	37159, wa
	ldda16	wa, 38470
	stda16	37161, wa
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	1148
	ret
	ldda16	bc, 38468
	ldda16	de, 38470
	stdi8	37112, 255
	stda16	37159, bc
	stda16	37161, de
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ldb	e, 177
	ldda8	d, 38469
	ldw	wa, 16384
	call	SwbtWr_QueuePostEvent
	ldb	e, 180
	ldda8	d, 38469
	ldw	wa, 32512
	call	SwbtWr_QueuePostEvent
	ldb	e, 178
	ldda8	d, 38469
	ldw	wa, 32512
	call	SwbtWr_QueuePostEvent
	ldb	e, 179
	ldda8	d, 38469
	ldw	wa, 32639
	call	SwbtWr_QueuePostEvent
	ldda8	c, 38469
	ldb	b, 4
	ldw	de, 2048
	call	MIDI_WriteVoiceParamDirect
	ldda16	de, 37159
	ldda16	wa, 37161
	call	SwbtWr_QueuePostEvent
	stdi8	37162, 0
	xor	h, h
	ldda8	l, 38469
	sla	hl, 1
	ld	xix, 38516
	.byte 0xf3
	reti
	.byte 0xf0, 0xec
	push_sr
	jrl	nc, 3711
	calr	1015
	ret
	ldda16	bc, 38468
	ldda16	de, 38470
	stdi8	37112, 255
	stda16	37159, bc
	stda16	37161, de
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	985
	ret
	stdi8	37112, 255
	ldda16	bc, 38468
	ldda16	de, 38470
	call	MIDI_WriteVoiceParamCC
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	959
	ret

MidiStream_LoadAllPresets:
	ld xiy, 0x9432
	ldb w, 0xb3
	calr MidiStream_LoadVoicePreset
	calr MidiStream_LoadBankSelect
	ld xiy, 0x9452
	ldb w, 0xb2
	calr MidiStream_LoadVoicePreset
	calr MidiStream_LoadMultiPartPreset
	calr MidiStream_LoadPedalPreset
	ret

MidiStream_LoadVoicePreset:
	xor hl, hl

MidiStream_LoadVoiceLoop:
	ld_srib3 A, 0x07, 0xf4, 0xec
	bit 7, a
	jr z, MidiStream_LoadVoiceNext
	res 7, a
	lda_dri3 XBC, 0x07, 0xf4, 0xec
	stdi8 37112, 255
	stda8 37159, w
	stda8 37160, l
	stda8 37161, a
	stdi8 37162, 127
	call SwbtWr_WriteVoiceParam_PreserveRegs

MidiStream_LoadVoiceNext:
	inc 1, hl
	cp l, 0x1f
	jr ule, MidiStream_LoadVoiceLoop
	ret

MidiStream_LoadBankSelect:
	ld xiy, 0x94f2
	ld a, (xiy)
	bit 7, a
	jr z, MidiStream_LoadBankDone
	res 7, a
	ld (xiy), a
	stda8 36576, a
	call Audio_WriteBankSelectParams
	stdi8 37112, 255
	stdi8 37159, 176
	stdi8 37160, 1
	stda8 37161, a
	stdi8 37162, 127
	call SwbtWr_WriteVoiceParam_PreserveRegs

MidiStream_LoadBankDone:
	ret

MidiStream_LoadMultiPartPreset:
	ld xiy, 0x9472
	xor hl, hl
	xor bc, bc

MidiStream_LoadMultiLoop:
	ld_sriw3 WA, 0x07, 0xf4, 0xec
	bit 7, a
	jr z, MidiStream_LoadMultiNext
	res 7, a
	st_dri3w WA, 0x07, 0xf4, 0xec
	stdi8 37112, 255
	ldb c, 0xb1
	stda16 37159, xbc
	stda16 37161, xwa
	call SwbtWr_WriteParamBlockSafe

MidiStream_LoadMultiNext:
	inc 1, b
	inc 2, hl
	cp b, 0x1f
	jr ule, MidiStream_LoadMultiLoop
	ret

MidiStream_LoadPedalPreset:
	ld xiy, 0x94b2
	xor hl, hl

MidiStream_LoadPedalLoop:
	ld_srib3 A, 0x07, 0xf4, 0xec
	bit 7, a
	jr z, MidiStream_LoadPedalNext
	res 7, a
	lda_dri3 XBC, 0x07, 0xf4, 0xec
	stdi8 37112, 255
	ld c, l
	ldb b, 0x3
	ld e, a
	ldb d, 0x7f
	call MIDI_WriteVoiceParamCC
	call SwbtWr_WriteVoiceParam_PreserveRegs

MidiStream_LoadPedalNext:
	inc 1, hl
	cp l, 0x1f
	jr ule, MidiStream_LoadPedalLoop
	ret

MidiStream_ProcessRxBuffer:
	bitda 0, 47079
	jr nz, MidiStream_ProcessDone
	bitda 4, 64848
	jr nz, MidiStream_ProcessDone
	stdi16 37171, 0

MidiStream_DispatchLoop:
	ld xix, 0xc039
	ldda16 xhl, 37171
	ld_srib3 A, 0x07, 0xf0, 0xec
	cp a, 0xff
	jr z, MidiStream_ProcessDone
	cp a, 0xbf
	jr ugt, MidiStream_AdvanceRxPtr
	extz wa
	sll wa, 2
	ld xiy, 0xfccf01
	ld_sril3 XIY, 0x07, 0xf4, 0xe0
	cp xiy, 0xffffffff
	jr z, MidiStream_AdvanceRxPtr
	ld_sriw3 BC, 0x07, 0xf0, 0xec
	inc 2, hl
	stda16 37211, xbc
	ld_sriw3 DE, 0x07, 0xf0, 0xec
	stda16 37213, xde
	call (xiy)

MidiStream_AdvanceRxPtr:
	incdi8 4, 37171
	jr MidiStream_DispatchLoop

MidiStream_ProcessDone:
	ret

MidiStream_StatusPrecheck:
	extz	hl
	ld	l, b
	cp	l, 11
	jr	ugt, 63
	sll	hl, 2
	ld	xix, 16566476
	ld_rrl	xix, xix, hl
	jp	(xix)


MidiStream_StatusJumpTable:
	.long MidiStream_HandleRunningStatus
	.long MidiStream_HandleNoteCC
	.long MidiStream_HandleNoteCC
	.long MidiStream_HandlePgmChange
	.long MidiStream_HandleChanPressure
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
MidiStream_HandleNoteCC:
	ret
	; --- Indexed dispatch: table lookup, conditional call paths (76 bytes) ---
	cp c, 0x48
	jr z, MidiStream_HandleNoteCC_Ret
	extz	hl
	ld l, c
	sll	hl, 2
	ldda32	xix, 37106
	ld_rrl	xix, xix, hl
	ld wa, (xix)
	stda16	37098, wa
	pushw wa
	stda8	37100, c
	call 0xfca3f6
	popw wa
	pushw hl
	call MIDI_ParamValidate_CheckBit2
	or	hl, hl
	popw hl
	jr nz, MidiStream_PostNoteCC
	ld b, c
	ldb c, 0x81
	ldda16	de, 37102
	call MIDI_ClearGuardAndDispatchCC
MidiStream_PostNoteCC:
	ldda8	c, 37211
	xor b, b
	ldda8	e, 37104
	ldb d, 0xff
	call MIDI_ClearGuardAndDispatchCC
MidiStream_HandleNoteCC_Ret:
	ret


MidiStream_HandlePgmChange:
	ld	a, d
	and	a, 127
	jr	z, 32
	extz	hl
	ld	l, c
	sll	hl, 2
	ldda32	xix, 37106
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 202
	.byte 0x8f, 0xc3
	pop_sr
	.byte 0xf0, 0xec
	ldb	e, 205
	scc8	nc, d
	ldb	d, 127
	call	MIDI_ClearGuardAndDispatchCC
	ret
MidiStream_HandleChanPressure:
	and	de, 18504
	and	e, d
	bit	3, d
	jr	z, 9
	.byte 0xf1
	swi	1
	and	(xwa), bc
	jr	z, 3
	or	e, 8
	ld	a, e
	and	e, 72
	jr	z, 30
	extz	hl
	ld	l, c
	sll	hl, 2
	ldda32	xix, 37106
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 202
	.byte 0x8f, 0xc3
	pop_sr
	.byte 0xf0, 0xec
	ldb	e, 204
	muls8rr	w, d
	call	MIDI_ClearGuardAndDispatchCC
	ret
MidiStream_HandleSysMsg:
	cps	d, 0
	jr	z, 27
	extz	hl
	ld	l, c
	sll	hl, 2
	ldda32	xix, 37106
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 202
	.byte 0x8f, 0xc3
	pop_sr
	.byte 0xf0, 0xec
	ldb	e, 29
	swi	6
	cp	(xbc), xix
	ret
	extz	hl
	ld	l, b
	cps	l, 3
	jr	ugt, 31
	sll	hl, 2
	ld	xix, 16566754
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 180
	.byte 0xd8


MidiStream_SysExJumpTable:
	.long MidiStream_HandleRunningStatus
	.long MidiStream_SysExNop
	.long MidiStream_SysExNop
	.long MidiStream_SysExData
MidiStream_SysExNop:
	ret
MidiStream_SysExData:
	.byte 0xc1
	ldw	ix, 16269
	ret
	jr	z, 18
	and	d, 7
	jr	z, 13
	ldda8	e, 64605
	and	e, 7
	ldb	d, 7
	call	MIDI_ClearGuardAndDispatchCC
	ret
	extz	hl
	ld	l, b
	cps	l, 1
	jr	ugt, 23
	sll	hl, 2
	ld	xix, 16566820
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 180
	.byte 0xd8
MidiStream_CtrlJumpTable:
	.long MidiStream_CtrlNop
	.long MidiStream_CtrlData
MidiStream_CtrlNop:
	ret
MidiStream_CtrlData:
	bit	7, d
	jr	z, 18
	bit	7, e
	jr	z, 13
	ldda8	e, 64623
	and	e, 128
	ldb	d, 128
	call	MIDI_ClearGuardAndDispatchCC
	ret
	extz	hl
	ld	l, b
	cp	l, 11
	jr	ugt, 63
	sll	hl, 2
	ld	xix, 16566877
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 180
	.byte 0xd8
MidiStream_CmdJumpTable:
	.long MidiStream_CmdNop
	.long MidiStream_CmdPedalNotify
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdMaskedNotify
MidiStream_CmdNop:
	ret
MidiStream_CmdMaskedNotify:
	; --- Routine 1: D/E bit masking, call FCA1FE (23 bytes) ---
	and d, 0xc0
	jr z, MidiStream_CmdMaskedDone
	and e, d
	jr z, MidiStream_CmdMaskedDone
	ldda8	e, 64929
	and e, 0xc0
	ldb d, 0xc0
	call MIDI_ClearGuardAndDispatchCC
MidiStream_CmdMaskedDone:
	ret
MidiStream_CmdPedalNotify:
	; --- Routine 2: conditional E/D setup, dec E, call FCA1FE (36 bytes) ---
	cpdi8	36148, 14
	jr z, MidiStream_CmdPedalDone
	bitda	3, 64848
	jr z, MidiStream_CmdPedalDone
	and e, 0x7f
	jr z, MidiStream_CmdPedalDone
	lds	bc, 0
	ldda8	e, 64919
	and e, 0x7f
	dec 1, e
	ldb d, 0x7f
	call MIDI_ClearGuardAndDispatchCC
MidiStream_CmdPedalDone:
	ret


MidiStream_HandlePartSelect:
	cp a, 0x48
	jr z, MidiStream_PartSelectDone
	and w, 0xf
	or w, 0x80
	pushw wa
	ld wa, (xsp)
	stda8 37093, w
	ld c, a
	ldb b, 0x4
	ldw de, 0x800
	call MIDI_DispatchCC_Guarded
	ld wa, (xsp)
	stda8 37093, w
	ldb c, 0xb1
	ld b, a
	ldw de, 0x4000
	call MIDI_DispatchCC_Guarded
	ld wa, (xsp)
	stda8 37093, w
	ldb c, 0xb2
	ld b, a
	ldw de, 0x7f00
	call MIDI_DispatchCC_Guarded
	ld wa, (xsp)
	stda8 37093, w
	ldb c, 0xb4
	ld b, a
	ldw de, 0x7f00
	call MIDI_DispatchCC_Guarded
	inc 2, xsp

MidiStream_PartSelectDone:
	ret

MidiStream_ExtendedDispatch:
	ret
	.byte 0xc1
	ld	xix, 1846820758
	reti
	stdi8	38468, 72
	ldb	c, 72
	.byte 0xc1
	ldw	ix, 16269
	ret
	jr	z, 7
	.byte 0xc1
	ldw	ix, 16269
	scf
	jr	nz, 5
	cp	c, 72
	jr	z, 49
	stdi8	37112, 255
	cps	c, 0
	jr	nz, 45
	.byte 0xf1, 0x50
	swi	5
	inc	6, c
	ldb	l, 193
	ldw	ix, 16269
	ret
	jr	z, 27
	.byte 0xc1
	ldw	ix, 16269
	scf
	jr	z, 20
	cp	e, 80
	jr	nc, 15
	inc	1, e
	ldw	bc, 408
	ldb	d, 127
	call	MIDI_WriteVoiceParamCC
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	65449
	ret
	ldda8	l, 64848
	and	l, 3
	sla	l, 2
	ld	xix, 16567183
	.byte 0xe3
	pop_sr
	.byte 0xf0, 0xec
	ldb	d, 180
	.byte 0xe8
	ret
	calr	65422
	ret
	cp	(xsp-53), ix
	nop
	ccf
	.byte 0xcc
	swi	4
	nop
	cp	(xde-53), d
	nop
	pop	xiz
	.byte 0xcc
	swi	4
	nop
	ldda16	bc, 38468
	ldda16	de, 38470
	stda8	37110, c
	xor	h, h
	ld	l, c
	sll	hl, 2
	ldda32	xix, 37106
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 78
	ldb	a, 17
	cp	c, 72
	jr	nz, 2
	ldb	a, 15
	cp	e, a
	jr	ugt, 65
	cp	c, 72
	jr	nz, 10
	ld	l, e
	call	AccVoice_GetChannelCount_Direct
	ld	a, l
	jr	10
	ld	a, e
	pushw	bc
	ld	b, c
	call	16557065
	popw	bc
	extz	hl
	ld	l, c
	cp	c, 72
	jr	nz, 2
	ldb	l, 20
	ld	xiy, 37906
	.byte 0xc3
	reti
	.byte 0xf4, 0xec
	ldb	h, 201
	.byte 0xf6
	jr	ugt, 15
	ld	l, e
	call	SndParam_ApplyProgramChange_Safe
	ld	b, h
	ld	e, l
	ldb	d, 255
	calr	162
	ret
	ldda16	bc, 38468
	ldda16	de, 38470
	stda8	37111, c
	extz	hl
	ld	l, c
	sll	hl, 2
	ldda32	xix, 37106
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 39
	extz	hl
	ld	l, c
	cp	c, 72
	jr	nz, 2
	ldb	l, 20
	ld	xiy, 37906
	.byte 0xc3
	reti
	.byte 0xf4, 0xec
	ldb	d, 204
	ldw	hl, 26119
	.byte 0x06
	res	7, d
	set	7, e
	ld	b, d
	ldb	d, 255
	calr	86
	ret
	ldda16	bc, 38468
	cp	c, 72
	jr	z, 75
	ldda16	de, 38470
	extz	hl
	ld	l, c
	sll	hl, 2
	ldda32	xix, 37106
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 47
	extz	hl
	ld	l, c
	ld	d, c
	sll	hl, 1
	ld	xiy, 37842
	.byte 0xd3
	reti
	.byte 0xf4, 0xec
	ldb	w, 241
	adc	xwa, xde
	.byte 0x50
	stda16	37100, de
	call	16557086
	ldda16	de, 37102
	ldda8	c, 38468
	ld	b, d
	ldb	d, 255
	call	16567475
	ret
	push	xix
	pushw	hl
	pushw	bc
	pushw	de
	.byte 0xf1
	swi	2
	.byte 0x90, 0xb8
	calr	105
	.byte 0xf1
	swi	2
	and	(xwa), bc
	jr	nz, 94
	stda8	37111, c
	xor	h, h
	ld	l, c
	sll	hl, 2
	ldda32	xix, 37106
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 180
	ld	xiy, 2151416204
	or	(xix+1), b
	ld	h, b
	ld	l, e
	call	PartCtrl_WriteProgramChange
	call	MIDI_SetupChannelParams
	ld	a, c
	ldb	w, 1
	stda16	37159, wa
	ld	a, b
	ldb	w, 127
	stda16	37161, wa
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ld	a, c
	ldb	w, 0
	stda16	37159, wa
	ld	a, e
	ldb	w, 255
	stda16	37161, wa
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	cp	c, 72
	jr	z, 8
	ld	d, b
	ldb	b, 0
	call	SndParam_UpdateVoiceEntry_Safe
	popw	de
	popw	bc
	popw	hl
	pop	xix
	ret
	push	xix
	pushw	hl
	pushw	bc
	pushw	de
	.byte 0xc1
	swi	2
	.byte 0x90
	push	xix
	swi	5
	.byte 0xf1
	swi	2
	and	(xwa), wa
	jr	z, 38
	.byte 0xc1
	swi	2
	.byte 0x90
	push	xix
	swi	6
	stda8	37111, c
	ld	l, e
	ld	h, b
	ld	xix, 16557105
	ldda8	e, 64848
	and	e, 3
	cps	e, 1
	jr	z, 5
	ld	xix, 16556463
	call	(xix)
	ld	e, l
	cp	c, 15
	jr	z, 43
	cp	c, 20
	jr	z, 38
	cp	c, 16
	jr	z, 25
	cp	c, 17
	jr	z, 20
	cp	c, 18
	jr	z, 15
	cp	c, 19
	jr	z, 10
	cp	c, 21
	jr	z, 5
	cp	c, 22
	jr	nz, 34
	call	16567723
	jr	c, 24
	jr	11
	call	16567723
	jr	nc, 16
	cp	c, 15
	jr	z, 15
	push_a
	ldda8	a, 14235
	and	a, 31
	pop_a
	jr	nz, 4
	.byte 0xf1
	swi	2
	sbc	(xwa), bc
	popw	de
	popw	bc
	popw	hl
	pop	xix
	ret
	cp	e, 15
	jr	nz, 2
	scf
	ret
	rcf
	ret
	.byte 0xc1
	ld	xix, 1850228630
	decf
	stdi8	38468, 20
	.byte 0xc1
	ldw	ix, 16269
	ret
	jrl	z, 156
	ldda16	bc, 38468
	ldda16	de, 38470
	ld	xix, 37842
	ld	xiz, 37906
	extz	hl
	ld	l, c
	sll	hl, 1
	cp	e, 255
	jr	z, 10
	res	7, e
	.byte 0xf3
	reti
	.byte 0xf0, 0xec
	ld	xiy, 818678888
	reti
	inc	1, xix
	.byte 0xf3
	reti
	.byte 0xf0, 0xec
	ld	xix, 131295724
	.byte 0xf0, 0xec
	ldb	w, 216
	scc8	nc, d
	jrl	nc, 2035
	.byte 0xf0, 0xec, 0x50
	srl	hl, 1
	ldda8	b, 64848
	and	b, 3
	sll	b, 2
	ld	xiy, 16567843
	.byte 0xe3
	pop_sr
	.byte 0xf4, 0xe5
	ldb	e, 181
	.byte 0xd8
	ldw	hl, 64718
	nop
	ldw	iy, 64718
	nop
	ldw	hl, 64718
	nop
	pop	xix
	.byte 0xce
	swi	4
	nop
	jr	42
	bit	0, w
	jr	z, 26
	srl	a, 4
	and	a, 15
	cp	c, 20
	jr	z, 10
	cps	a, 2
	jr	c, 6
	cps	a, 6
	jr	nc, 2
	xor	a, a
	set	7, a
	jr	11
	srl	a, 4
	and	a, 15
	jr	3
	srl	wa, 8
	.byte 0xf3
	reti
	swi	0
	.byte 0xec
	ld	xbc, 4239662606
	ret
MidiStream_HandleRunningStatus:
	.byte 0xf1, 0x50
	swi	5
	inc	6, c
	.byte 0x04
	cps	c, 0
	jr	z, 22
	ldda8	l, 64848
	and	l, 3
	sll	hl, 2
	ld	xix, 16567946
	.byte 0xe3
	pop_sr
	.byte 0xf0, 0xec
	ldb	d, 180
	.byte 0xd8
	ret
	cp	(xde-50), ix
	nop
	.byte 0xb8, 0xce
	swi	4
	nop
	cp	(xbc-50), d
	nop
	swi	5
	.byte 0xc8
	swi	4
	nop
	cp	c, 72
	jr	nz, 2
	ldb	c, 20
	pushw	bc
	pushw	de
	ld	e, d
	xor	d, d
	ld	b, c
	ldb	c, 129
	call	MIDI_ClearGuardAndDispatchCC
	popw	de
	popw	bc
	ldb	d, 255
	call	MIDI_ClearGuardAndDispatchCC
	ret
	cp	c, 72
	jr	nz, 2
	ldb	c, 20
	extz	hl
	ldda8	l, 37211
	sll	hl, 2
	ldda32	xix, 37106
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 38
	ld	e, (xix)
	pushw	bc
	pushw	de
	xor	d, d
	bit	7, e
	jr	z, 2
	ldb	d, 1
	ld	e, (xix+1)
	sll	e, 4
	ld	b, c
	ldb	c, 129
	call	MIDI_ClearGuardAndDispatchCC
	popw	de
	popw	bc
	res	7, e
	ldb	d, 255
	call	MIDI_ClearGuardAndDispatchCC
	ret
	swi	7
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
