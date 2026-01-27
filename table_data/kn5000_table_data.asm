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
	db 08000h dup (0ffh)
	db 08000h dup (0ffh)
	db 01F36h dup (0ffh)


	ORG 08E0000h

Compressed_data:
	; I think this is probably the subprogram rom compressed using
	; the LZSS algorithm, as described at
	; https://github.com/felipesanches/kn5000_homebrew/blob/main/kn5000_extract.py
	db "SLIDE4K", 000h, 000h, 095h, 000h, "}Z", 0EEh, 0F0h
	; etc...



	ORG 9FA000h
LABEL_9FA000:
	db "SLIDE", 000h
	db "Technics KN5000 Program  DATA FILE 1/2", 000h, 0ffh		; 9FA007
	db "Technics KN5000 Program  DATA FILE 2/2", 000h, 0ffh		; 9FA02F
	db "Technics KN5000 Program  DATA FILE PCK", 000h, 0ffh		; 9FA057
	db "Technics KN5000 Table    DATA FILE 1/2", 000h, 0ffh		; 9FA07F
	db "Technics KN5000 Table    DATA FILE 2/2", 000h, 0ffh		; 9FA0A7
	db "Technics KN5000 Table    DATA FILE PCK", 000h, 0ffh		; 9FA1CF
	db "Technics KN5000 CMPCUSTOMDATA FILE    ", 000h, 0ffh		; 9FA0F7
	db "Technics KN5000 HD-AEPRG DATA FILE    ", 000h, 0ffh		; 9FA11F

;HANDLE_UPDATE_BASE_ADDR		EQU HANDLE_UPDATE_FILE_TYPE_ID_001h
;
;HANDLE_UPDATE_OFFSETS:			; E00178
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_001h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 ;Program DATA FILE 1/2"
;	dw (SHOW_ILLEGAL_DISK_MESSAGE - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 Program DATA FILE 2/2"
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_003h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 Table DATA FILE 1/2"
;	dw (SHOW_ILLEGAL_DISK_MESSAGE - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 Table DATA FILE 2/2"
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_005h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 CMPCUSTOMDATA FILE"
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_006h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 HD-AEPRG DATA FILE"
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_007h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 Program DATA FILE PCK"
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_008h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 Table DATA FILE PCK"


	ORG 9FA150h

LABEL_9FA150:
	db "SLIDE", 000h

Bitmap_1bit_Flash_Memory_Update:	; 9FA156
	binclude "../maincpu/images/Bitmap_1bit_Flash_Memory_Update.bin"

Bitmap_1bit_Now_Erasing:		;
	binclude "../maincpu/images/Bitmap_1bit_Now_Erasing.bin"

Bitmap_1bit_FD_to_Flash_Memory:		;
	binclude "../maincpu/images/Bitmap_1bit_FD_to_Flash_Memory.bin"

Bitmap_1bit_Completed:			;
	binclude "../maincpu/images/Bitmap_1bit_Completed.bin"

Bitmap_1bit_Please_Wait:		;
	binclude "../maincpu/images/Bitmap_1bit_Please_Wait.bin"

Bitmap_1bit_Change_FD_2_of_2:		;
	binclude "../maincpu/images/Bitmap_1bit_Change_FD_2_of_2.bin"

Bitmap_1bit_Illegal_Disk:		;
	binclude "../maincpu/images/Bitmap_1bit_Illegal_Disk.bin"

Bitmap_1bit_Turn_On_AGAIN:		;
	binclude "../maincpu/images/Bitmap_1bit_Turn_On_AGAIN.bin"


	ORG 09FB705h
EMPTY_HANDLER:
	RETI

	ORG 09FFEE0h
RESET_HANDLER:
	JP 0FFB4E8h

	ORG 09fb7fbh
NMI_HANDLER:

	ORG 09feab2h
INT4_HANDLER:

	ORG 09ff229h
INTA_HANDLER:

	ORG 09fb7f2h
INTT1_HANDLER:

	ORG 09ff2d0h
INTRX1_HANDLER:

	ORG 09ff2aeh
INTTX1_HANDLER:

	ORG 09fea9dh
INTTC3_HANDLER:



	ORG 09FFF00h

; TMP94C241C Interrupt Vector Table:

	dd RESET_HANDLER

	dd EMPTY_HANDLER	; "SWI 1" instruction
	dd EMPTY_HANDLER	; "SWI 2" instruction
	dd EMPTY_HANDLER	; "SWI 3" instruction
	dd EMPTY_HANDLER	; "SWI 4" instruction
	dd EMPTY_HANDLER	; "SWI 5" instruction
	dd EMPTY_HANDLER	; "SWI 6" instruction
	dd EMPTY_HANDLER	; "SWI 7" instruction

	dd NMI_HANDLER

	dd EMPTY_HANDLER	; INTWD (watchdog)
	dd EMPTY_HANDLER	; INT0 Pin

	dd INT4_HANDLER

	dd EMPTY_HANDLER	; INT5 Pin
	dd EMPTY_HANDLER	; INT6 Pin
	dd EMPTY_HANDLER	; INT7 Pin
	dd EMPTY_HANDLER	; (RESERVED)
	dd EMPTY_HANDLER	; INT8 Pin
	dd EMPTY_HANDLER	; INT9 Pin

	dd INTA_HANDLER

	dd EMPTY_HANDLER	; INTB Pin
	dd EMPTY_HANDLER	; INTT0

	dd INTT1_HANDLER

	dd EMPTY_HANDLER	; INTT2_HANDLER
	dd EMPTY_HANDLER	; INTT3_HANDLER
	dd EMPTY_HANDLER	; INTTR4_HANDLER
	dd EMPTY_HANDLER 	; INTTR5
	dd EMPTY_HANDLER 	; INTTR6
	dd EMPTY_HANDLER	; INTTR7
	dd EMPTY_HANDLER 	; INTTR8
	dd EMPTY_HANDLER 	; INTTR9
	dd EMPTY_HANDLER 	; INTTRA
	dd EMPTY_HANDLER 	; INTTRB
	dd EMPTY_HANDLER	; INTRX0_HANDLER
	dd EMPTY_HANDLER	; INTTX0_HANDLER

	dd INTRX1_HANDLER
	dd INTTX1_HANDLER

	dd EMPTY_HANDLER 	; INTAD
	dd EMPTY_HANDLER	; INTTC0
	dd EMPTY_HANDLER 	; INTTC1
	dd EMPTY_HANDLER	; INTTC2

	dd INTTC3_HANDLER

	dd EMPTY_HANDLER 	; INTTC4
	dd EMPTY_HANDLER 	; INTTC5
	dd EMPTY_HANDLER 	; INTTC6
	dd EMPTY_HANDLER 	; INTTC7

; RESERVED:
	db 12 dup (0FFh)
	db "hkt_87.ssf", 0
	db 5 dup (0)
; RESERVED:
	db 030h dup (0FFh)
