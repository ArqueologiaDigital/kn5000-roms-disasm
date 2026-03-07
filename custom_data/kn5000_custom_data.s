
	.text

; =============================================================================
; CUSTOM DATA FLASH ROM — Structure Overview
; =============================================================================
; Hardware: AMD AM29LV800B (8Mbit / 1MB) at IC19
; Address range: 0x300000 - 0x3FFFFF (1MB)
;
; User-writable flash programmed from the "initial data disk" at factory setup.
; The firmware identifies this chip via Flash_IdentifyChip (EF3723) using the
; AMD flash command protocol (0xAAAA/0x5555 unlock sequence).
; Device IDs checked: 0x2223 (AM29LV800B-T) and 0x22AB (AM29LV800B-B).
;
; CONTENTS:
;   - Custom accompaniment styles (8 sections, "HK" header format)
;   - LCD wallpaper/screenshot storage (76,800 + 1,024 bytes)
;   - Registration memory (3 banks + config, 4KB)
;   - SubCPU payload staging area (for firmware updates)
;
; ROM LAYOUT:
;
;   0x300000-0x316FFF   92KB  Section 0: Custom Style Data
;   0x317000-0x318FFF    8KB  [erased boot block sector gap]
;   0x319000-0x346FFF  184KB  Sections 1-2: Custom Style Data
;   0x347000-0x348FFF    8KB  [erased sector gap]
;   0x349000-0x376FFF  184KB  Sections 3-4: Custom Style Data
;   0x377000-0x378FFF    8KB  [erased sector gap]
;   0x379000-0x3A6FFF  184KB  Sections 5-6: Custom Style Data
;   0x3A7000-0x3AFFFF   36KB  [unused erased area]
;   0x3B0000-0x3B0FFF    4KB  Section 7: SubCPU Performance Data
;   0x3B1000-0x3BFFFF   60KB  [erased]
;   0x3C0000-0x3D2FFF   78KB  LCD Wallpaper/Screenshot Storage
;   0x3D3000-0x3D3FFF    4KB  Registration Memory
;   0x3D4000-0x3DFFFF   48KB  [erased]
;   0x3E0000-0x3FFFFF  128KB  SubCPU Payload Staging Area
;
; SECTION POINTER TABLE (computed at runtime by LABEL_F16A57):
;   Section 0: 0x300000  (RAM 0x0C76)   Section 4: 0x360000  (RAM 0x0C86)
;   Section 1: 0x319800  (RAM 0x0C7A)   Section 5: 0x379800  (RAM 0x0C8A)
;   Section 2: 0x330000  (RAM 0x0C7E)   Section 6: 0x390000  (RAM 0x0C8E)
;   Section 3: 0x349800  (RAM 0x0C82)   Section 7: 0x3B0000  (RAM 0x0C92)
;
; "HK" HEADER FORMAT (style sections 0-7):
;   +0x00: word 0x0048 ('H')     +0x08: style parameter data
;   +0x02: word 0x004B ('K')     Sections contain style names, MIDI patterns,
;   +0x04: 4 bytes flags/config  and accompaniment arrangement data.
;
; REGISTRATION MEMORY FORMAT (0x3D3000):
;   +0x00: "HK " (ASCII, 4 bytes)
;   +0x04: config header (12 bytes, includes bank count)
;   +0x10: Bank 0 data (pointer table + parameters)
;   Pointer entries: 6 bytes each (2-byte offset + 4-byte data)
; =============================================================================

	.org 0x300000 - 0x300000, 0xFF

; ============================================================
; Section 0: Custom Accompaniment Style Data
; Firmware pointer: RAM (0C76h) = 0x300000
; Starts with "HK" header (48 00 4B 00)
; Contains style names like "Bolero puro", etc.
; ============================================================
CustomData_Section_0:
	.incbin "includes/section_0.bin"	; 0x300000-0x316FFF (92KB)

; 8KB erased boot block sector gap
	.space 0x2000, 0xFF	; 0x317000-0x318FFF

; ============================================================
; Sections 1-2: Custom Accompaniment Style Data (continuous)
; Section 1 pointer: RAM (0C7Ah) = 0x319800
; Section 2 pointer: RAM (0C7Eh) = 0x330000
; Both start with "HK" header at their respective offsets
; ============================================================
CustomData_Sections_1_2:
	.incbin "includes/section_1_2.bin"	; 0x319000-0x346FFF (184KB)

; 8KB erased sector gap
	.space 0x2000, 0xFF	; 0x347000-0x348FFF

; ============================================================
; Sections 3-4: Custom Accompaniment Style Data (continuous)
; Section 3 pointer: RAM (0C82h) = 0x349800
; Section 4 pointer: RAM (0C86h) = 0x360000
; ============================================================
CustomData_Sections_3_4:
	.incbin "includes/section_3_4.bin"	; 0x349000-0x376FFF (184KB)

; 8KB erased sector gap
	.space 0x2000, 0xFF	; 0x377000-0x378FFF

; ============================================================
; Sections 5-6: Custom Accompaniment Style Data (continuous)
; Section 5 pointer: RAM (0C8Ah) = 0x379800
; Section 6 pointer: RAM (0C8Eh) = 0x390000
; ============================================================
CustomData_Sections_5_6:
	.incbin "includes/section_5_6.bin"	; 0x379000-0x3A6FFF (184KB)

; 36KB erased (unused style area)
	.space 0x9000, 0xFF	; 0x3A7000-0x3AFFFF

; ============================================================
; Section 7: SubCPU Performance Data
; Pointer: RAM (0C92h) = 0x3B0000
; Starts with "HK" header but mostly empty (minimal data)
; ============================================================
CustomData_Section_7:
	.incbin "includes/section_7.bin"	; 0x3B0000-0x3B0FFF (4KB)

; 60KB erased
	.space 0xF000, 0xFF	; 0x3B1000-0x3BFFFF

; ============================================================
; LCD Wallpaper / Screenshot Storage
; Address: 0x3C0000 - 0x3D2FFF (77,824 bytes)
; Written by CaptureLcd firmware routine.
; Format: 320x240 8bpp = 76,800 bytes of pixel data,
;         followed by 1,024 bytes of metadata/padding.
; Zero-filled in factory-programmed state.
; ============================================================
CustomData_LCD_Wallpaper:
	.zero 77824	; 0x3C0000-0x3D2FFF: zero-filled in factory state


; ============================================================
; Registration Memory — 3 banks + config
; Base address: 0x3D3000
; Written by firmware registration save routines
; Bank 0: 0x3D3010 (234 bytes)
; Bank 1: 0x3D3110 (234 bytes)
; Bank 2: 0x3D3210 (234 bytes)
; Config: 0x3D3400 (80 bytes + sub-blocks)
; ============================================================
CustomData_Registration_Memory:
	.incbin "includes/registration.bin"	; 0x3D3000-0x3D3FFF (4KB)

; ============================================================
; Erased region — includes SubCPU payload staging at 0x3E0000
; The compressed SubCPU payload is written here during firmware
; updates and read back by the SubCPU transfer routine.
; Empty in factory-programmed state.
; ============================================================
	.space 0x2BFFF, 0xFF	; 0x3D4000-0x3FFFFE (176KB - 1 byte)
	.byte 0xff	; 0x3FFFFF (anchor last byte for p2bin)
