	cpu	96c141	; Actual CPU is 94c241f
	page	0
	maxmode	on
	include "../tmp94c241.inc"

	ORG 0800000h
LABEL_800000:
	db 0 ;	TODO: figure out what's here.

	ORG 87FFF0h

hkst_55:
	db "hkst_55.ssf", 0
	dd 00000000h
	dd LABEL_88000C
	dd Feature_Demo_XML
	dd FeatureDemo_FileEntry1

LABEL_88000C:
	dw 0000h

Feature_Demo_XML:	; 88000E
	binclude "includes/hkst_55.ssf"
	db 00h

	ORG 880418h
Feature_Bitmap_1:	; 880418
	binclude "images/FTBMP01.BMP"

	ORG 89344Eh
Feature_Bitmap_2:	; 89344E
	binclude "images/FTBMP02.BMP"

	ORG 89DB04h
Feature_Bitmap_3:	; 89DB04
	binclude "images/FTBMP03.BMP"

	ORG 8A753Ah
Feature_Bitmap_4:	; 8A753A
	binclude "images/FTBMP04.BMP"

	ORG 8B0F70h
Feature_Bitmap_5:	; 8B0F70
	binclude "images/FTBMP05.BMP"

	ORG 8BAFE6h
Feature_Bitmap_6:	; 8BAFE6
	binclude "images/FTBMP06.BMP"


	ORG 08CE01Ch

FeatureDemo_FileEntry1:
	db "FTBMP01.BMP", 0
	dd 00000000h
	dd Feature_Bitmap_1
	dd 436 + (320 * 240)

FeatureDemo_FileEntry2:
	db "FTBMP02.BMP", 0
	dd 00000000h
	dd Feature_Bitmap_2
	dd 436 + (320 * 130)

FeatureDemo_FileEntry3:
	db "FTBMP03.BMP", 0
	dd 00000000h
	dd Feature_Bitmap_3
	dd 436 + (320 * 120)

FeatureDemo_FileEntry4:
	db "FTBMP04.BMP", 0
	dd 00000000h
	dd Feature_Bitmap_4
	dd 436 + (320 * 120)

FeatureDemo_FileEntry5:
	db "FTBMP05.BMP", 0
	dd 00000000h
	dd Feature_Bitmap_5
	dd 436 + (320 * 125)

FeatureDemo_FileEntry6:
	db "FTBMP06.BMP", 0
	dd 00000000h
	dd Feature_Bitmap_6
	dd 436 + (320 * 240)

	db 30 dup (000h)

	; Unused ROM space:
	; db 011F36h dup (0ffh)


	ORG 08E0000h

Compressed_data:
	; I think this is probably the subprogram rom compressed using
	; the LZSS algorithm, as described at
	; https://github.com/felipesanches/kn5000_homebrew/blob/main/kn5000_extract.py
	db "SLIDE4K", 000h, 000h, 095h, 000h, 07Dh, 05Ah, 0EEh, 0F0h
	; etc...


	ORG 09FFFD0h
	db 030h dup (0ffh)

