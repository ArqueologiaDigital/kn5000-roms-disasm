; KN5000 Custom Data Flash ROM — IC19 (AMD AM29LV800B)
; 1MB mapped at 0x300000-0x3FFFFF
;
; User-writable flash programmed from the "initial data disk" at factory setup.
; Contains: custom accompaniment styles (8 sections with "HK" headers),
;           registration memory (3 banks + config), LCD wallpaper/screenshot
;           storage, and compressed SubCPU payload staging area.
;
; The firmware computes 8 section pointers at LABEL_F16A57 (maincpu line 164083):
;   Section 0: 0x300000   Section 4: 0x360000
;   Section 1: 0x319800   Section 5: 0x379800
;   Section 2: 0x330000   Section 6: 0x390000
;   Section 3: 0x349800   Section 7: 0x3B0000

	cpu	96c141	; Actual CPU is TMP94C241F (ASL only supports TMP96C141)
	page	0
	maxmode	on
	include	"../tmp94c241.inc"
	org	300000h

; ============================================================
; Section 0: Custom Accompaniment Style Data
; Firmware pointer: RAM (0C76h) = 0x300000
; Starts with "HK" header (48 00 4B 00)
; Contains style names like "Bolero puro", etc.
; ============================================================
CustomData_Section_0:
	binclude "includes/section_0.bin"		; 0x300000-0x316FFF (92KB)

; 8KB erased boot block sector gap
	ds	2000h					; 0x317000-0x318FFF

; ============================================================
; Sections 1-2: Custom Accompaniment Style Data (continuous)
; Section 1 pointer: RAM (0C7Ah) = 0x319800
; Section 2 pointer: RAM (0C7Eh) = 0x330000
; Both start with "HK" header at their respective offsets
; ============================================================
CustomData_Sections_1_2:
	binclude "includes/section_1_2.bin"		; 0x319000-0x346FFF (184KB)

; 8KB erased sector gap
	ds	2000h					; 0x347000-0x348FFF

; ============================================================
; Sections 3-4: Custom Accompaniment Style Data (continuous)
; Section 3 pointer: RAM (0C82h) = 0x349800
; Section 4 pointer: RAM (0C86h) = 0x360000
; ============================================================
CustomData_Sections_3_4:
	binclude "includes/section_3_4.bin"		; 0x349000-0x376FFF (184KB)

; 8KB erased sector gap
	ds	2000h					; 0x377000-0x378FFF

; ============================================================
; Sections 5-6: Custom Accompaniment Style Data (continuous)
; Section 5 pointer: RAM (0C8Ah) = 0x379800
; Section 6 pointer: RAM (0C8Eh) = 0x390000
; ============================================================
CustomData_Sections_5_6:
	binclude "includes/section_5_6.bin"		; 0x379000-0x3A6FFF (184KB)

; 36KB erased (unused style area)
	ds	9000h					; 0x3A7000-0x3AFFFF

; ============================================================
; Section 7: SubCPU Performance Data
; Pointer: RAM (0C92h) = 0x3B0000
; Starts with "HK" header but mostly empty (minimal data)
; ============================================================
CustomData_Section_7:
	binclude "includes/section_7.bin"		; 0x3B0000-0x3B0FFF (4KB)

; 60KB erased
	ds	0F000h					; 0x3B1000-0x3BFFFF

; ============================================================
; LCD Wallpaper / Screenshot Storage
; Written by CaptureLcd firmware routine
; Zero-filled in factory-programmed state
; ============================================================
CustomData_LCD_Wallpaper:
	rept	13000h
	db	0
	endm						; 0x3C0000-0x3D2FFF (76KB, zero-filled)

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
	binclude "includes/registration.bin"		; 0x3D3000-0x3D3FFF (4KB)

; ============================================================
; Erased region — includes SubCPU payload staging at 0x3E0000
; The compressed SubCPU payload is written here during firmware
; updates and read back by the SubCPU transfer routine.
; Empty in factory-programmed state.
; ============================================================
	ds	2BFFFh					; 0x3D4000-0x3FFFFE (176KB - 1 byte)
	db	0FFh					; 0x3FFFFF (anchor last byte for p2bin)
