; =============================================================================
; file_io/single_load.asm - Single File Load Operations
; =============================================================================
; Single file load mode with source/destination selection.
;
; Key routines:
;   SingleLoadModeFunc               - Single load mode entry
;   SingleLoadDstBankFunc            - Destination bank selection
;   SingleLoadDstMemFunc             - Destination memory selection
;   SingleLoadSrcBankFunc            - Source bank selection
;   SingleLoadSrcMemFunc             - Source memory selection
;   SingleLoadSrcFunc                - Source file selection
;   SingleLoadDstFunc                - Destination selection
;   CmpSingleLoadSrcFunc             - Composer single load source
;   CmpSingleLoadDstFunc             - Composer single load destination
;   CmpSingleLoadFileFunc            - Composer single load file
;   FmmCmpSingleLoadFunc             - Composer single load handler
; =============================================================================

SingleLoadModeFunc:
	CP XBC, 01c0000bh
	JR Z, LABEL_F8EF70
	CP XBC, 01e50004h
	JR NZ, LABEL_F8EF90
	LD (81B6h), XDE
	JR T, LABEL_F8EF90

LABEL_F8EF70:
	LD A, (89F8h)
	EXTZ WA
	SLA 002h, WA
	LDA XBC, 0EA0598h
	LD XDE, (XBC + WA)
	LD XWA, (81B6h)
	LD XBC, 01c0000fh
	CALL ApPostEvent

LABEL_F8EF90:
	LD XHL, 0
	RET

SingleLoadDstBankFunc:
	CP XBC, 01c0000bh
	JR Z, LABEL_F8EFA9
	CP XBC, 01e50004h
	JR NZ, LABEL_F8EFC9
	LD (81BAh), XDE
	JR T, LABEL_F8EFC9

LABEL_F8EFA9:
	LD A, (89F8h)
	EXTZ WA
	SLA 002h, WA
	LDA XBC, 0EA05F2h
	LD XDE, (XBC + WA)
	LD XWA, (81BAh)
	LD XBC, 01c0000fh
	CALL ApPostEvent

LABEL_F8EFC9:
	LD XHL, 0
	RET

SingleLoadDstMemFunc:
	CP XBC, 01c0000bh
	JR Z, LABEL_F8EFE2
	CP XBC, 01e50004h
	JR NZ, LABEL_F8F01A
	LD (81BEh), XDE
	JR T, LABEL_F8F01A

LABEL_F8EFE2:
	LD XWA, (81BEh)
	LDA XDE, 0EA0624h
	CP (89FAh), 000h
	JR Z, LABEL_F8F003
	CP (89F8h), 001h
	JR Z, LABEL_F8F003
	LD XDE, (XDE + 010h)
	LD XBC, 01c0000fh
	JR T, LABEL_F8F016

LABEL_F8F003:
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LD XDE, (XDE + BC)
	LD XBC, 01c0000fh

LABEL_F8F016:
	CALL ApPostEvent

LABEL_F8F01A:
	LD XHL, 0
	RET

SingleLoadSrcBankFunc:
	CP XBC, 01c0000bh
	JR Z, LABEL_F8F033
	CP XBC, 01e50004h
	JR NZ, LABEL_F8F068
	LD (81C2h), XDE
	JR T, LABEL_F8F068

LABEL_F8F033:
	LD XWA, (81C2h)
	LDA XDE, 0EA05F2h
	LD C, (89F8h)
	CP C, 0
	JR NZ, LABEL_F8F055
	CP (8A0Ah), 000h
	JR Z, LABEL_F8F055
	LD XDE, (XDE + 010h)
	LD XBC, 01c0000fh
	JR T, LABEL_F8F064

LABEL_F8F055:
	EXTZ BC
	SLA 002h, BC
	LD XDE, (XDE + BC)
	LD XBC, 01c0000fh

LABEL_F8F064:
	CALL ApPostEvent

LABEL_F8F068:
	LD XHL, 0
	RET

SingleLoadSrcMemFunc:
	CP XBC, 01c0000bh
	JR Z, LABEL_F8F081
	CP XBC, 01e50004h
	JR NZ, LABEL_F8F0B6
	LD (81C6h), XDE
	JR T, LABEL_F8F0B6

LABEL_F8F081:
	LD XWA, (81C6h)
	LDA XDE, 0EA0624h
	LD C, (89F8h)
	CP C, 1
	JR Z, LABEL_F8F099
	CP (89FAh), 000h
	JR Z, LABEL_F8F0A3

LABEL_F8F099:
	LD XDE, (XDE + 010h)
	LD XBC, 01c0000fh
	JR T, LABEL_F8F0B2

LABEL_F8F0A3:
	EXTZ BC
	SLA 002h, BC
	LD XDE, (XDE + BC)
	LD XBC, 01c0000fh

LABEL_F8F0B2:
	CALL ApPostEvent

LABEL_F8F0B6:
	LD XHL, 0
	RET

LABEL_F8F0B9:
	db 0EFh, 06Eh, 03Eh, 0BFh, 004h, 043h, 0BFh, 006h
	db 060h, 0F1h, 04Eh, 089h, 030h, 0F5h, 0E0h, 000h
	db 000h, 0C1h, 0F8h, 089h, 023h, 0D9h, 012h, 0D9h
	db 0ECh, 002h, 0F2h, 0F2h, 005h, 0EAh, 032h, 0E3h
	db 007h, 0E8h, 0E4h, 021h, 0E9h, 061h, 01Dh, 0DCh
	db 090h, 0F8h, 0F1h, 04Fh, 089h, 030h, 041h, 038h
	db 009h, 0EAh, 000h, 01Dh, 013h, 091h, 0F8h, 0F1h
	db 04Fh, 089h, 036h, 0C1h, 0FCh, 089h, 021h, 0D8h
	db 012h, 08Fh, 004h, 051h, 0C9h, 061h, 0D8h, 012h
	db 0D9h, 0A8h, 01Eh, 079h, 0C5h, 0EBh, 089h, 0EEh
	db 088h, 01Dh, 013h, 091h, 0F8h, 0F1h, 04Fh, 089h
	db 030h, 031h, 010h, 000h, 01Eh, 07Eh, 0EEh, 0AFh
	db 006h, 020h, 041h, 00Fh, 000h, 0C0h, 001h, 042h
	db 04Eh, 089h, 000h, 000h, 01Dh, 058h, 09Dh, 0FAh
	db 05Eh, 0EFh, 066h, 00Eh, 0EFh, 06Ch, 03Eh, 0BFh
	db 004h, 060h, 0F1h, 04Eh, 089h, 030h, 0B8h, 015h
	db 000h, 001h, 0B8h, 016h, 036h, 0C1h, 0FCh, 089h
	db 021h, 0D8h, 012h, 0CBh, 051h, 0D8h, 012h, 01Dh
	db 00Eh, 0A1h, 0F8h, 0EBh, 089h, 0EEh, 088h, 01Dh
	db 0DCh, 090h, 0F8h, 0F1h, 064h, 089h, 030h, 031h
	db 010h, 000h, 01Eh, 038h, 0EEh, 0F1h, 063h, 089h
	db 032h, 0AFh, 004h, 020h, 041h, 00Fh, 000h, 0C0h
	db 001h, 01Dh, 058h, 09Dh, 0FAh, 05Eh, 0EFh, 064h
	db 00Eh, 0EFh, 06Eh, 03Eh, 0BFh, 004h, 043h, 0BFh
	db 006h, 060h, 0F1h, 04Eh, 089h, 030h, 0B8h, 02Ah
	db 000h, 002h, 0B8h, 02Bh, 030h, 0C1h, 0F8h, 089h
	db 023h, 0D9h, 012h, 0D9h, 0ECh, 002h, 0F2h, 024h
	db 006h, 0EAh, 032h, 0E3h, 007h, 0E8h, 0E4h, 021h
	db 0E9h, 061h, 01Dh, 0DCh, 090h, 0F8h, 0F1h, 079h
	db 089h, 030h, 041h, 03Ch, 009h, 0EAh, 000h, 01Dh
	db 013h, 091h, 0F8h, 0C1h, 0FAh, 089h, 03Fh, 000h
	db 06Eh, 020h, 0F1h, 079h, 089h, 036h, 0C1h, 0FCh
	db 089h, 021h, 0D8h, 012h, 08Fh, 004h, 051h, 0C8h
	db 089h, 0C9h, 061h, 0D8h, 012h, 0D9h, 0A8h, 01Eh
	db 0B4h, 0C4h, 0EBh, 089h, 0EEh, 088h, 01Dh, 013h
	db 091h, 0F8h, 0F1h, 079h, 089h, 030h, 031h, 010h
	db 000h, 01Eh, 0B9h, 0EDh, 0F1h, 078h, 089h, 032h
	db 0AFh, 006h, 020h, 041h, 00Fh, 000h, 0C0h, 001h
	db 01Dh, 058h, 09Dh, 0FAh, 0C1h, 0FAh, 089h, 03Fh
	db 000h, 066h, 024h, 0F1h, 04Eh, 089h, 030h, 0B8h
	db 03Fh, 000h, 003h, 0B8h, 040h, 030h, 041h, 040h
	db 009h, 0EAh, 000h, 01Dh, 0DCh, 090h, 0F8h, 0F1h
	db 08Dh, 089h, 032h, 0AFh, 006h, 020h, 041h, 00Fh
	db 000h, 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh, 05Eh
	db 0EFh, 066h, 00Eh, 0EFh, 06Ch, 03Eh, 0BFh, 004h
	db 060h, 0C1h, 0FAh, 089h, 03Fh, 000h, 06Eh, 037h
	db 0F1h, 04Eh, 089h, 030h, 0B8h, 03Fh, 000h, 003h
	db 0B8h, 040h, 036h, 0C1h, 0FCh, 089h, 021h, 0D8h
	db 012h, 01Dh, 088h, 0A1h, 0F8h, 0EBh, 089h, 0EEh
	db 088h, 01Dh, 0DCh, 090h, 0F8h, 0F1h, 08Eh, 089h
	db 030h, 031h, 010h, 000h, 01Eh, 046h, 0EDh, 0F1h
	db 08Dh, 089h, 032h, 0AFh, 004h, 020h, 041h, 00Fh
	db 000h, 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh, 05Eh
	db 0EFh, 064h, 00Eh, 0EFh, 06Ch, 03Eh, 0BFh, 004h
	db 062h, 0E8h, 08Eh, 0E9h, 0CFh, 018h, 000h, 0C0h
	db 001h, 066h, 062h, 0E9h, 0CFh, 017h, 000h, 0C0h
	db 001h, 066h, 05Ah, 0E9h, 0CFh, 00Bh, 000h, 0C0h
	db 001h, 07Eh, 016h, 002h, 0C1h, 00Ah, 08Ah, 03Fh
	db 000h, 066h, 00Fh, 0C1h, 0FCh, 089h, 021h, 0D8h
	db 012h, 0C2h, 052h, 009h, 0EAh, 051h, 0F1h, 0FCh
	db 089h, 040h, 0C2h, 052h, 009h, 0EAh, 023h, 0EEh
	db 088h, 01Eh, 014h, 0FEh, 0C2h, 052h, 009h, 0EAh
	db 023h, 0EEh, 088h, 01Eh, 0C3h, 0FEh, 0C2h, 052h
	db 009h, 0EAh, 023h, 0EEh, 088h, 01Eh, 074h, 0FEh
	db 0C2h, 052h, 009h, 0EAh, 023h, 0EEh, 088h, 01Eh
	db 059h, 0FFh, 0E8h, 0A8h, 0F1h, 0CAh, 081h, 060h
	db 0F1h, 0CEh, 081h, 000h, 000h, 0F1h, 0D0h, 081h
	db 000h, 000h, 078h, 0C5h, 001h, 0C1h, 0FCh, 089h
	db 025h, 0AFh, 004h, 020h, 0E8h, 0CFh, 005h, 000h
	db 000h, 000h, 07Eh, 09Ah, 000h, 0C1h, 00Ah, 08Ah
	db 03Fh, 000h, 06Eh, 06Ch, 0E9h, 08Ch, 0E9h, 0CFh
	db 017h, 000h, 0C0h, 001h, 06Eh, 02Bh, 0C2h, 052h
	db 009h, 0EAh, 027h, 0CFh, 089h, 0CDh, 08Bh, 0CDh
	db 081h, 0C2h, 054h, 009h, 0EAh, 0F1h, 06Fh, 019h
	db 0CFh, 083h, 0F1h, 0FCh, 089h, 043h, 0C2h, 052h
	db 009h, 0EAh, 023h, 0EEh, 088h, 01Eh, 0A0h, 0FDh
	db 0C2h, 052h, 009h, 0EAh, 023h, 0EEh, 088h, 068h
	db 02Ah, 0ECh, 0CFh, 018h, 000h, 0C0h, 001h, 06Eh
	db 02Fh, 0CDh, 089h, 0C2h, 052h, 009h, 0EAh, 023h
	db 0CBh, 0F5h, 067h, 024h, 0CBh, 0A1h, 0F1h, 0FCh
	db 089h, 041h, 0C2h, 052h, 009h, 0EAh, 023h, 0EEh
	db 088h, 01Eh, 074h, 0FDh, 0C2h, 052h, 009h, 0EAh
	db 023h, 0EEh, 088h, 01Eh, 023h, 0FEh, 0F1h, 0D0h
	db 081h, 000h, 001h, 0F1h, 0CEh, 081h, 000h, 001h
	db 0E1h, 0CAh, 081h, 020h, 0AFh, 004h, 0F0h, 076h
	db 038h, 001h, 0F1h, 063h, 089h, 032h, 0EEh, 088h
	db 041h, 00Fh, 000h, 0C0h, 001h, 01Dh, 058h, 09Dh
	db 0FAh, 0F1h, 08Dh, 089h, 032h, 0EEh, 088h, 041h
	db 00Fh, 000h, 0C0h, 001h, 078h, 0D7h, 000h, 0AFh
	db 004h, 020h, 0E8h, 0CFh, 006h, 000h, 000h, 000h
	db 07Eh, 095h, 000h, 0E9h, 08Bh, 0E9h, 0CFh, 017h
	db 000h, 0C0h, 001h, 06Eh, 031h, 0CDh, 08Bh, 0CDh
	db 089h, 0C9h, 061h, 0C2h, 054h, 009h, 0EAh, 0F1h
	db 06Fh, 024h, 0C2h, 052h, 009h, 0EAh, 025h, 0CDh
	db 08Fh, 0CBh, 089h, 0D8h, 012h, 0CFh, 051h, 0C8h
	db 089h, 0C9h, 061h, 0CDh, 0F1h, 06Fh, 043h, 0CBh
	db 061h, 0F1h, 0FCh, 089h, 043h, 0C2h, 052h, 009h
	db 0EAh, 023h, 0EEh, 088h, 068h, 02Ch, 0EBh, 0CFh
	db 018h, 000h, 0C0h, 001h, 06Eh, 02Ch, 0CDh, 08Bh
	db 0CDh, 0D8h, 066h, 026h, 0C2h, 052h, 009h, 0EAh
	db 025h, 0CBh, 089h, 0D8h, 012h, 0CDh, 051h, 0C8h
	db 089h, 0C9h, 0D8h, 066h, 015h, 0CBh, 069h, 0F1h
	db 0FCh, 089h, 043h, 0C2h, 052h, 009h, 0EAh, 023h
	db 0EEh, 088h, 01Eh, 07Ch, 0FDh, 0F1h, 0CEh, 081h
	db 000h, 001h, 0E1h, 0CAh, 081h, 020h, 0AFh, 004h
	db 0F0h, 076h, 096h, 000h, 0F1h, 063h, 089h, 032h
	db 0EEh, 088h, 041h, 00Fh, 000h, 0C0h, 001h, 01Dh
	db 058h, 09Dh, 0FAh, 0F1h, 08Dh, 089h, 032h, 0EEh
	db 088h, 041h, 00Fh, 000h, 0C0h, 001h, 068h, 036h
	db 0AFh, 004h, 020h, 0E8h, 0CFh, 007h, 000h, 000h
	db 000h, 066h, 008h, 0E8h, 0CFh, 008h, 000h, 000h
	db 000h, 06Eh, 030h, 0E1h, 0CAh, 081h, 020h, 0AFh
	db 004h, 0F0h, 066h, 05Eh, 0F1h, 063h, 089h, 032h
	db 0EEh, 088h, 041h, 00Fh, 000h, 0C0h, 001h, 01Dh
	db 058h, 09Dh, 0FAh, 0F1h, 08Dh, 089h, 032h, 0EEh
	db 088h, 041h, 00Fh, 000h, 0C0h, 001h, 01Dh, 058h
	db 09Dh, 0FAh, 0AFh, 004h, 020h, 0F1h, 0CAh, 081h
	db 060h, 068h, 037h, 0AFh, 004h, 020h, 0E8h, 0CFh
	db 028h, 000h, 000h, 000h, 06Eh, 02Ch, 0C1h, 0D0h
	db 081h, 03Fh, 000h, 066h, 00Fh, 0C2h, 052h, 009h
	db 0EAh, 023h, 0EEh, 088h, 01Eh, 0ADh, 0FCh, 0F1h
	db 0D0h, 081h, 000h, 000h, 0C1h, 0CEh, 081h, 03Fh
	db 000h, 066h, 00Fh, 0C2h, 052h, 009h, 0EAh, 023h
	db 0EEh, 088h, 01Eh, 086h, 0FDh, 0F1h, 0CEh, 081h
	db 000h, 000h, 0EBh, 0A8h, 05Eh, 0EFh, 064h, 00Eh
	db 0EFh, 06Ch, 03Eh, 0BFh, 004h, 060h, 0E9h, 0CFh
	db 00Bh, 000h, 0C0h, 001h, 07Eh, 0C4h, 000h, 0F1h
	db 04Eh, 089h, 030h, 0F5h, 0E0h, 000h, 000h, 0B0h
	db 000h, 000h, 031h, 010h, 000h, 01Eh, 0D5h, 0EAh
	db 0F1h, 04Eh, 089h, 030h, 0B8h, 015h, 000h, 001h
	db 0B8h, 016h, 030h, 0C1h, 0F8h, 089h, 023h, 0D9h
	db 012h, 0D9h, 0ECh, 002h, 0F2h, 024h, 006h, 0EAh
	db 032h, 0E3h, 007h, 0E8h, 0E4h, 021h, 0E9h, 061h
	db 01Dh, 0DCh, 090h, 0F8h, 0F1h, 064h, 089h, 030h
	db 041h, 058h, 009h, 0EAh, 000h, 01Dh, 013h, 091h
	db 0F8h, 0F1h, 064h, 089h, 030h, 031h, 010h, 000h
	db 01Eh, 09Ah, 0EAh, 0F1h, 04Eh, 089h, 030h, 0B8h
	db 02Ah, 000h, 002h, 0B8h, 02Bh, 036h, 0D8h, 0A8h
	db 01Dh, 01Bh, 0A2h, 0F8h, 0EBh, 089h, 0EEh, 088h
	db 01Dh, 0DCh, 090h, 0F8h, 0F1h, 079h, 089h, 030h
	db 031h, 010h, 000h, 01Eh, 077h, 0EAh, 0F1h, 04Eh
	db 089h, 030h, 0B8h, 03Fh, 000h, 003h, 0B8h, 040h
	db 030h, 0B0h, 000h, 000h, 031h, 010h, 000h, 01Eh
	db 063h, 0EAh, 0AFh, 004h, 020h, 041h, 00Fh, 000h
	db 0C0h, 001h, 042h, 04Eh, 089h, 000h, 000h, 01Dh
	db 058h, 09Dh, 0FAh, 0F1h, 063h, 089h, 032h, 0AFh
	db 004h, 020h, 041h, 00Fh, 000h, 0C0h, 001h, 01Dh
	db 058h, 09Dh, 0FAh, 0F1h, 078h, 089h, 032h, 0AFh
	db 004h, 020h, 041h, 00Fh, 000h, 0C0h, 001h, 01Dh
	db 058h, 09Dh, 0FAh, 0F1h, 08Dh, 089h, 032h, 0AFh
	db 004h, 020h, 041h, 00Fh, 000h, 0C0h, 001h, 01Dh
	db 058h, 09Dh, 0FAh, 0EBh, 0A8h, 05Eh, 0EFh, 064h
	db 00Eh, 0EFh, 06Ah, 03Eh, 0BFh, 004h, 043h, 0E8h
	db 08Eh, 0F1h, 04Eh, 089h, 030h, 0F5h, 0E0h, 000h
	db 000h, 0C1h, 0F8h, 089h, 023h, 0D9h, 012h, 0D9h
	db 0ECh, 002h, 0F2h, 0F2h, 005h, 0EAh, 032h, 0E3h
	db 007h, 0E8h, 0E4h, 021h, 0E9h, 061h, 01Dh, 0DCh
	db 090h, 0F8h, 0F1h, 04Fh, 089h, 030h, 041h, 05Ah
	db 009h, 0EAh, 000h, 01Dh, 013h, 091h, 0F8h, 0F1h
	db 04Fh, 089h, 030h, 031h, 010h, 000h, 01Eh, 0DCh
	db 0E9h, 0F1h, 063h, 089h, 030h, 0C1h, 0FEh, 089h
	db 023h, 0D9h, 012h, 08Fh, 004h, 053h, 0D9h, 012h
	db 0DAh, 0A9h, 01Eh, 062h, 0F8h, 0EEh, 088h, 041h
	db 00Fh, 000h, 0C0h, 001h, 042h, 04Eh, 089h, 000h
	db 000h, 01Dh, 058h, 09Dh, 0FAh, 0F1h, 063h, 089h
	db 032h, 0EEh, 088h, 041h, 00Fh, 000h, 0C0h, 001h
	db 01Dh, 058h, 09Dh, 0FAh, 05Eh, 0EFh, 062h, 00Eh
	db 0EFh, 068h, 03Eh, 0BFh, 006h, 043h, 0BFh, 008h
	db 060h, 0C1h, 0FEh, 089h, 021h, 0D8h, 012h, 08Fh
	db 006h, 051h, 0C8h, 089h, 0D8h, 012h, 0BFh, 004h
	db 050h, 0F1h, 04Eh, 089h, 030h, 0B8h, 02Ah, 000h
	db 002h, 0B8h, 02Bh, 030h, 0C1h, 0F8h, 089h, 023h
	db 0D9h, 012h, 0D9h, 0ECh, 002h, 0F2h, 024h, 006h
	db 0EAh, 032h, 0E3h, 007h, 0E8h, 0E4h, 021h, 0E9h
	db 061h, 01Dh, 0DCh, 090h, 0F8h, 0F1h, 079h, 089h
	db 030h, 041h, 05Eh, 009h, 0EAh, 000h, 01Dh, 013h
	db 091h, 0F8h, 0C1h, 0FAh, 089h, 03Fh, 000h, 06Eh
	db 012h, 0F1h, 079h, 089h, 036h, 09Fh, 004h, 020h
	db 01Eh, 00Ah, 0F8h, 0EBh, 089h, 0EEh, 088h, 01Dh
	db 013h, 091h, 0F8h, 0F1h, 079h, 089h, 030h, 031h
	db 010h, 000h, 01Eh, 038h, 0E9h, 0F1h, 078h, 089h
	db 032h, 0AFh, 008h, 020h, 041h, 00Fh, 000h, 0C0h
	db 001h, 01Dh, 058h, 09Dh, 0FAh, 0F1h, 04Eh, 089h
	db 031h, 0B9h, 03Fh, 030h, 0C1h, 0FAh, 089h, 03Fh
	db 000h, 066h, 01Dh, 0B0h, 000h, 003h, 0B9h, 040h
	db 030h, 041h, 062h, 009h, 0EAh, 000h, 01Dh, 0DCh
	db 090h, 0F8h, 0F1h, 08Dh, 089h, 032h, 0AFh, 008h
	db 020h, 041h, 00Fh, 000h, 0C0h, 001h, 068h, 027h
	db 09Fh, 004h, 03Fh, 004h, 000h, 067h, 024h, 0C1h
	db 0FEh, 089h, 023h, 0D9h, 012h, 08Fh, 006h, 053h
	db 0D9h, 012h, 00Bh, 003h, 000h, 09Fh, 006h, 022h
	db 01Eh, 0B1h, 0F7h, 0F1h, 08Dh, 089h, 032h, 0AFh
	db 008h, 020h, 041h, 00Fh, 000h, 0C0h, 001h, 01Dh
	db 058h, 09Dh, 0FAh, 05Eh, 0EFh, 060h, 00Eh, 0EFh
	db 06Ch, 03Eh, 0CBh, 08Dh, 0BFh, 004h, 060h, 0C1h
	db 0FEh, 089h, 021h, 0D8h, 012h, 0CDh, 051h, 0C8h
	db 08Bh, 0D9h, 012h, 0C1h, 0FAh, 089h, 03Fh, 000h
	db 06Eh, 03Fh, 0D9h, 0DCh, 06Fh, 03Bh, 0F1h, 04Eh
	db 089h, 030h, 0B8h, 03Fh, 000h, 003h, 0B8h, 040h
	db 036h, 0C1h, 0FEh, 089h, 021h, 0D8h, 012h, 0CDh
	db 051h, 0D8h, 012h, 01Dh, 095h, 0A2h, 0F8h, 0EBh
	db 089h, 0EEh, 088h, 01Dh, 0DCh, 090h, 0F8h, 0F1h
	db 08Eh, 089h, 030h, 031h, 010h, 000h, 01Eh, 084h
	db 0E8h, 0F1h, 08Dh, 089h, 032h, 0AFh, 004h, 020h
	db 041h, 00Fh, 000h, 0C0h, 001h, 01Dh, 058h, 09Dh
	db 0FAh, 05Eh, 0EFh, 064h, 00Eh, 0EFh, 06Ch, 03Eh
	db 0BFh, 004h, 062h, 0E9h, 08Ah, 0E8h, 08Eh, 0C2h
	db 074h, 009h, 0EAh, 023h, 0EAh, 0CFh, 018h, 000h
	db 0C0h, 001h, 066h, 033h, 0EAh, 0CFh, 017h, 000h
	db 0C0h, 001h, 066h, 02Bh, 0EAh, 0CFh, 00Bh, 000h
	db 0C0h, 001h, 07Eh, 0BFh, 001h, 0EEh, 088h, 01Eh
	db 09Eh, 0FEh, 0C2h, 074h, 009h, 0EAh, 023h, 0EEh
	db 088h, 01Eh, 01Dh, 0FEh, 0C2h, 074h, 009h, 0EAh
	db 023h, 0EEh, 088h, 01Eh, 061h, 0FFh, 0E8h, 0A8h
	db 0F1h, 0D2h, 081h, 060h, 078h, 098h, 001h, 0C1h
	db 0FEh, 089h, 027h, 0AFh, 004h, 020h, 0E8h, 0CFh
	db 005h, 000h, 000h, 000h, 07Eh, 08Eh, 000h, 0EAh
	db 08Ch, 0EAh, 0CFh, 017h, 000h, 0C0h, 001h, 06Eh
	db 02Bh, 0C2h, 074h, 009h, 0EAh, 025h, 0CDh, 089h
	db 0CFh, 08Bh, 0CFh, 081h, 0C2h, 076h, 009h, 0EAh
	db 0F1h, 06Fh, 019h, 0CDh, 083h, 0F1h, 0FEh, 089h
	db 043h, 0C2h, 074h, 009h, 0EAh, 023h, 0EEh, 088h
	db 01Eh, 0CEh, 0FDh, 0C2h, 074h, 009h, 0EAh, 023h
	db 0EEh, 088h, 068h, 02Ah, 0ECh, 0CFh, 018h, 000h
	db 0C0h, 001h, 06Eh, 02Ah, 0CFh, 089h, 0C2h, 074h
	db 009h, 0EAh, 023h, 0CBh, 0F7h, 067h, 01Fh, 0CBh
	db 0A1h, 0F1h, 0FEh, 089h, 041h, 0C2h, 074h, 009h
	db 0EAh, 023h, 0EEh, 088h, 01Eh, 0A2h, 0FDh, 0C2h
	db 074h, 009h, 0EAh, 023h, 0EEh, 088h, 01Eh, 00Fh
	db 0FEh, 0F1h, 0D6h, 081h, 000h, 001h, 0E1h, 0D2h
	db 081h, 020h, 0AFh, 004h, 0F0h, 076h, 01Ch, 001h
	db 0F1h, 063h, 089h, 032h, 0EEh, 088h, 041h, 00Fh
	db 000h, 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh, 0F1h
	db 08Dh, 089h, 032h, 0EEh, 088h, 041h, 00Fh, 000h
	db 0C0h, 001h, 078h, 0D6h, 000h, 0AFh, 004h, 020h
	db 0E8h, 0CFh, 006h, 000h, 000h, 000h, 07Eh, 094h
	db 000h, 0EAh, 08Ch, 0EAh, 0CFh, 017h, 000h, 0C0h
	db 001h, 06Eh, 031h, 0CFh, 08Bh, 0CFh, 089h, 0C9h
	db 061h, 0C2h, 076h, 009h, 0EAh, 0F1h, 06Fh, 024h
	db 0C2h, 074h, 009h, 0EAh, 025h, 0CDh, 08Fh, 0CBh
	db 089h, 0D8h, 012h, 0CFh, 051h, 0C8h, 089h, 0C9h
	db 061h, 0CDh, 0F1h, 06Fh, 043h, 0CBh, 061h, 0F1h
	db 0FEh, 089h, 043h, 0C2h, 074h, 009h, 0EAh, 023h
	db 0EEh, 088h, 068h, 02Ch, 0ECh, 0CFh, 018h, 000h
	db 0C0h, 001h, 06Eh, 02Ch, 0CFh, 08Bh, 0CFh, 0D8h
	db 066h, 026h, 0C2h, 074h, 009h, 0EAh, 025h, 0CBh
	db 089h, 0D8h, 012h, 0CDh, 051h, 0C8h, 089h, 0C9h
	db 0D8h, 066h, 015h, 0CBh, 069h, 0F1h, 0FEh, 089h
	db 043h, 0C2h, 074h, 009h, 0EAh, 023h, 0EEh, 088h
	db 01Eh, 06Dh, 0FDh, 0F1h, 0D6h, 081h, 000h, 001h
	db 0E1h, 0D2h, 081h, 020h, 0AFh, 004h, 0F0h, 066h
	db 07Bh, 0F1h, 063h, 089h, 032h, 0EEh, 088h, 041h
	db 00Fh, 000h, 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh
	db 0F1h, 08Dh, 089h, 032h, 0EEh, 088h, 041h, 00Fh
	db 000h, 0C0h, 001h, 068h, 036h, 0AFh, 004h, 020h
	db 0E8h, 0CFh, 007h, 000h, 000h, 000h, 066h, 008h
	db 0E8h, 0CFh, 008h, 000h, 000h, 000h, 06Eh, 030h
	db 0E1h, 0D2h, 081h, 020h, 0AFh, 004h, 0F0h, 066h
	db 043h, 0F1h, 063h, 089h, 032h, 0EEh, 088h, 041h
	db 00Fh, 000h, 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh
	db 0F1h, 08Dh, 089h, 032h, 0EEh, 088h, 041h, 00Fh
	db 000h, 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh, 0AFh
	db 004h, 020h, 0F1h, 0D2h, 081h, 060h, 068h, 01Ch
	db 0AFh, 004h, 020h, 0E8h, 0CFh, 028h, 000h, 000h
	db 000h, 06Eh, 011h, 0C1h, 0D6h, 081h, 03Fh, 000h
	db 066h, 00Ah, 0EEh, 088h, 01Eh, 0C0h, 0FDh, 0F1h
	db 0D6h, 081h, 000h, 000h, 0EBh, 0A8h, 05Eh, 0EFh
	db 064h, 00Eh, 0AFh, 004h, 024h, 0CBh, 08Fh, 0CBh
	db 087h, 082h, 0FFh, 06Fh, 004h, 084h, 0FFh, 067h
	db 04Ah, 082h, 0FFh, 067h, 004h, 084h, 0FFh, 06Fh
	db 042h, 0E8h, 0CFh, 008h, 000h, 000h, 000h, 066h
	db 02Ah, 0E8h, 0CFh, 007h, 000h, 000h, 000h, 066h
	db 022h, 0E8h, 0CFh, 006h, 000h, 000h, 000h, 066h
	db 008h, 0E8h, 0CFh, 005h, 000h, 000h, 000h, 06Eh
	db 022h, 082h, 021h, 0B4h, 041h, 0E8h, 0A8h, 041h
	db 00Fh, 000h, 0C0h, 001h, 0EAh, 0A8h, 01Eh, 065h
	db 014h, 068h, 010h, 084h, 021h, 0B2h, 041h, 0E8h
	db 0A8h, 041h, 00Bh, 000h, 0C0h, 001h, 0EAh, 0A8h
	db 01Eh, 037h, 005h, 00Fh, 004h, 000h, 0EFh, 06Eh
	db 0B7h, 043h, 0BFh, 002h, 060h, 0F1h, 04Eh, 089h
	db 030h, 0F5h, 0E0h, 000h, 000h, 0C1h, 0F8h, 089h
	db 023h, 0D9h, 012h, 0D9h, 0ECh, 002h, 0F2h, 0F2h
	db 005h, 0EAh, 032h, 0E3h, 007h, 0E8h, 0E4h, 021h
	db 0E9h, 061h, 01Dh, 0DCh, 090h, 0F8h, 0F1h, 04Fh
	db 089h, 030h, 041h, 078h, 009h, 0EAh, 000h, 01Dh
	db 013h, 091h, 0F8h, 0F1h, 04Fh, 089h, 030h, 031h
	db 010h, 000h, 01Eh, 0E8h, 0E5h, 0AFh, 002h, 020h
	db 041h, 00Fh, 000h, 0C0h, 001h, 042h, 04Eh, 089h
	db 000h, 000h, 01Dh, 058h, 09Dh, 0FAh, 087h, 021h
	db 087h, 081h, 0C1h, 000h, 08Ah, 023h, 0C9h, 0F3h
	db 06Fh, 01Fh, 0F1h, 063h, 089h, 030h, 0D9h, 012h
	db 087h, 053h, 0D9h, 012h, 0DAh, 0A9h, 01Eh, 0DBh
	db 0F4h, 0F1h, 063h, 089h, 032h, 0AFh, 002h, 020h
	db 041h, 00Fh, 000h, 0C0h, 001h, 01Dh, 058h, 09Dh
	db 0FAh, 0EFh, 066h, 00Eh, 0EFh, 06Ch, 03Eh, 0BFh
	db 004h, 060h, 0CBh, 089h, 0CBh, 081h, 0C1h, 000h
	db 08Ah, 0F9h, 067h, 031h, 0F1h, 04Eh, 089h, 030h
	db 0B8h, 015h, 000h, 001h, 0B8h, 016h, 036h, 01Dh
	db 094h, 0A3h, 0F8h, 0EBh, 089h, 0EEh, 088h, 01Dh
	db 0DCh, 090h, 0F8h, 0F1h, 064h, 089h, 030h, 031h
	db 010h, 000h, 01Eh, 078h, 0E5h, 0F1h, 063h, 089h
	db 032h, 0AFh, 004h, 020h, 041h, 00Fh, 000h, 0C0h
	db 001h, 01Dh, 058h, 09Dh, 0FAh, 05Eh, 0EFh, 064h
	db 00Eh, 0EFh, 06Eh, 03Eh, 0BFh, 004h, 043h, 0BFh
	db 006h, 060h, 0F1h, 04Eh, 089h, 030h, 0B8h, 02Ah
	db 000h, 002h, 0B8h, 02Bh, 030h, 0C1h, 0F8h, 089h
	db 023h, 0D9h, 012h, 0D9h, 0ECh, 002h, 0F2h, 024h
	db 006h, 0EAh, 032h, 0E3h, 007h, 0E8h, 0E4h, 021h
	db 0E9h, 061h, 01Dh, 0DCh, 090h, 0F8h, 0F1h, 079h
	db 089h, 030h, 041h, 07Ch, 009h, 0EAh, 000h, 01Dh
	db 013h, 091h, 0F8h, 0C1h, 0FAh, 089h, 03Fh, 000h
	db 06Eh, 041h, 08Fh, 004h, 025h, 08Fh, 004h, 085h
	db 0C1h, 000h, 08Ah, 023h, 0F1h, 079h, 089h, 030h
	db 0CDh, 0F3h, 067h, 015h, 0E8h, 08Eh, 0CDh, 0A3h
	db 0CBh, 061h, 0D9h, 012h, 0D9h, 088h, 0D9h, 0A8h
	db 01Eh, 0EBh, 0BBh, 0EBh, 089h, 0EEh, 088h, 068h
	db 016h, 0E8h, 08Eh, 0D9h, 012h, 08Fh, 004h, 053h
	db 0CAh, 089h, 0C9h, 061h, 0D8h, 012h, 0D9h, 0A8h
	db 01Eh, 0D3h, 0BBh, 0EBh, 089h, 0EEh, 088h, 01Dh
	db 013h, 091h, 0F8h, 0F1h, 079h, 089h, 030h, 031h
	db 010h, 000h, 01Eh, 0D8h, 0E4h, 0F1h, 078h, 089h
	db 032h, 0AFh, 006h, 020h, 041h, 00Fh, 000h, 0C0h
	db 001h, 01Dh, 058h, 09Dh, 0FAh, 0C1h, 0FAh, 089h
	db 03Fh, 000h, 066h, 024h, 0F1h, 04Eh, 089h, 030h
	db 0B8h, 03Fh, 000h, 003h, 0B8h, 040h, 030h, 041h
	dd LABEL_EA0980
	db 01Dh, 0DCh, 090h, 0F8h
	db 0F1h, 08Dh, 089h, 032h, 0AFh, 006h, 020h, 041h
	db 00Fh, 000h, 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh
	db 05Eh, 0EFh, 066h, 00Eh, 0EFh, 06Ch, 03Eh, 0BFh
	db 004h, 060h, 0C1h, 0FAh, 089h, 03Fh, 000h, 06Eh
	db 04Dh, 0F1h, 04Eh, 089h, 030h, 0B8h, 03Fh, 000h
	db 003h, 0CBh, 08Dh, 0CBh, 085h, 0B8h, 040h, 036h
	db 0C1h, 000h, 08Ah, 021h, 0CDh, 0F1h, 067h, 00Eh
	db 0CDh, 0A1h, 0D8h, 012h, 01Dh, 004h, 0A4h, 0F8h
	db 0EBh, 089h, 0EEh, 088h, 068h, 00Ah, 0D8h, 012h
	db 01Dh, 019h, 0A3h, 0F8h, 0EBh, 089h, 0EEh, 088h
	db 01Dh, 0DCh, 090h, 0F8h, 0F1h, 08Eh, 089h, 030h
	db 031h, 010h, 000h, 01Eh, 04Fh, 0E4h, 0F1h, 08Dh
	db 089h, 032h, 0AFh, 004h, 020h, 041h, 00Fh, 000h
	db 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh, 05Eh, 0EFh
	db 064h, 00Eh, 0EFh, 06Ch, 03Eh, 0BFh, 004h, 062h
	db 0E8h, 08Eh, 0C2h, 092h, 009h, 0EAh, 025h, 0E9h
	db 0CFh, 018h, 000h, 0C0h, 001h, 066h, 049h, 0E9h
	db 0CFh, 017h, 000h, 0C0h, 001h, 066h, 041h, 0E9h
	db 0CFh, 00Bh, 000h, 0C0h, 001h, 07Eh, 0C0h, 002h
	db 0EEh, 088h, 0CDh, 08Bh, 01Eh, 0E7h, 0FDh, 0C2h
	db 092h, 009h, 0EAh, 023h, 0EEh, 088h, 01Eh, 0A0h
	db 0FEh, 0C2h, 092h, 009h, 0EAh, 023h, 0EEh, 088h
	db 01Eh, 051h, 0FEh, 0C2h, 092h, 009h, 0EAh, 023h
	db 0EEh, 088h, 01Eh, 057h, 0FFh, 0E8h, 0A8h, 0F1h
	db 0D8h, 081h, 060h, 0F1h, 0DCh, 081h, 000h, 000h
	db 0F1h, 0DEh, 081h, 000h, 000h, 078h, 088h, 002h
	db 0C1h, 000h, 08Ah, 027h, 0AFh, 004h, 020h, 0E8h
	db 0CFh, 005h, 000h, 000h, 000h, 07Eh, 0D4h, 000h
	db 0E9h, 08Ah, 0E9h, 0CFh, 017h, 000h, 0C0h, 001h
	db 06Eh, 048h, 0C2h, 092h, 009h, 0EAh, 023h, 0CBh
	db 088h, 0CBh, 080h, 0CFh, 089h, 0C8h, 0F7h, 06Fh
	db 039h, 0CBh, 0F1h, 06Fh, 008h, 0CBh, 081h, 0F1h
	db 000h, 08Ah, 041h, 068h, 004h, 0F1h, 000h, 08Ah
	db 040h, 0C2h, 092h, 009h, 0EAh, 023h, 0EEh, 088h
	db 01Eh, 073h, 0FDh, 0C2h, 092h, 009h, 0EAh, 023h
	db 0EEh, 088h, 01Eh, 02Ch, 0FEh, 0C2h, 092h, 009h
	db 0EAh, 023h, 00Bh, 000h, 000h, 00Bh, 008h, 08Ah
	db 0AFh, 008h, 020h, 042h, 000h, 08Ah, 000h, 000h
	db 068h, 04Eh, 0EAh, 0CFh, 018h, 000h, 0C0h, 001h
	db 06Eh, 053h, 0CFh, 08Bh, 0C2h, 092h, 009h, 0EAh
	db 025h, 0CDh, 0F7h, 067h, 048h, 0CDh, 089h, 0CDh
	db 081h, 0C9h, 0F3h, 06Fh, 008h, 0CDh, 0A3h, 0F1h
	db 000h, 08Ah, 043h, 068h, 004h, 0F1h, 000h, 08Ah
	db 045h, 0C2h, 092h, 009h, 0EAh, 023h, 0EEh, 088h
	db 01Eh, 023h, 0FDh, 0C2h, 092h, 009h, 0EAh, 023h
	db 0EEh, 088h, 01Eh, 0DCh, 0FDh, 0C2h, 092h, 009h
	db 0EAh, 023h, 00Bh, 000h, 000h, 00Bh, 008h, 08Ah
	db 0AFh, 008h, 020h, 042h, 000h, 08Ah, 000h, 000h
	db 01Eh, 0A7h, 0FCh, 0F1h, 0DEh, 081h, 000h, 001h
	db 0F1h, 0DCh, 081h, 000h, 001h, 0E1h, 0D8h, 081h
	db 020h, 0AFh, 004h, 0F0h, 076h, 0C1h, 001h, 0F1h
	db 063h, 089h, 032h, 0EEh, 088h, 041h, 00Fh, 000h
	db 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh, 0F1h, 08Dh
	db 089h, 032h, 0EEh, 088h, 041h, 00Fh, 000h, 0C0h
	db 001h, 078h, 063h, 001h, 0AFh, 004h, 020h, 0E8h
	db 0CFh, 006h, 000h, 000h, 000h, 07Eh, 021h, 001h
	db 0E9h, 08Ah, 0E9h, 0CFh, 017h, 000h, 0C0h, 001h
	db 06Eh, 076h, 0CFh, 08Bh, 0CFh, 089h, 0C9h, 061h
	db 0C2h, 094h, 009h, 0EAh, 0F1h, 06Fh, 069h, 0C2h
	db 092h, 009h, 0EAh, 025h, 0CDh, 089h, 0CDh, 081h
	db 0C9h, 0F3h, 06Fh, 037h, 0CDh, 08Fh, 0CBh, 089h
	db 0D8h, 012h, 0CFh, 051h, 0C8h, 089h, 0C9h, 061h
	db 0CDh, 0F1h, 07Fh, 0C6h, 000h, 0CBh, 061h, 0F1h
	db 000h, 08Ah, 043h, 0C2h, 092h, 009h, 0EAh, 023h
	db 0EEh, 088h, 01Eh, 044h, 0FDh, 0C2h, 092h, 009h
	db 0EAh, 023h, 00Bh, 000h, 000h, 00Bh, 008h, 08Ah
	db 0AFh, 008h, 020h, 042h, 000h, 08Ah, 000h, 000h
	db 078h, 098h, 000h, 0CBh, 061h, 0F1h, 000h, 08Ah
	db 043h, 0C2h, 092h, 009h, 0EAh, 023h, 0EEh, 088h
	db 01Eh, 01Eh, 0FDh, 0C2h, 092h, 009h, 0EAh, 023h
	db 00Bh, 000h, 000h, 00Bh, 008h, 08Ah, 0AFh, 008h
	db 020h, 042h, 000h, 08Ah, 000h, 000h, 068h, 073h
	db 0EAh, 0CFh, 018h, 000h, 0C0h, 001h, 06Eh, 073h
	db 0CFh, 08Bh, 0CFh, 0D8h, 066h, 06Dh, 0C2h, 092h
	db 009h, 0EAh, 025h, 0CDh, 089h, 0CDh, 081h, 0C9h
	db 0F3h, 06Fh, 031h, 0CBh, 089h, 0D8h, 012h, 0CDh
	db 051h, 0C8h, 089h, 0C9h, 0D8h, 066h, 054h, 0CBh
	db 069h, 0F1h, 000h, 08Ah, 043h, 0C2h, 092h, 009h
	db 0EAh, 023h, 0EEh, 088h, 01Eh, 0D2h, 0FCh, 0C2h
	db 092h, 009h, 0EAh, 023h, 00Bh, 000h, 000h, 00Bh
	db 008h, 08Ah, 0AFh, 008h, 020h, 042h, 000h, 08Ah
	db 000h, 000h, 068h, 027h, 0C9h, 0F3h, 063h, 02Bh
	db 0CBh, 069h, 0F1h, 000h, 08Ah, 043h, 0C2h, 092h
	db 009h, 0EAh, 023h, 0EEh, 088h, 01Eh, 0A9h, 0FCh
	db 0C2h, 092h, 009h, 0EAh, 023h, 00Bh, 000h, 000h
	db 00Bh, 008h, 08Ah, 0AFh, 008h, 020h, 042h, 000h
	db 08Ah, 000h, 000h, 01Eh, 074h, 0FBh, 0F1h, 0DCh
	db 081h, 000h, 001h, 0E1h, 0D8h, 081h, 020h, 0AFh
	db 004h, 0F0h, 076h, 093h, 000h, 0F1h, 063h, 089h
	db 032h, 0EEh, 088h, 041h, 00Fh, 000h, 0C0h, 001h
	db 01Dh, 058h, 09Dh, 0FAh, 0F1h, 08Dh, 089h, 032h
	db 0EEh, 088h, 041h, 00Fh, 000h, 0C0h, 001h, 068h
	db 036h, 0AFh, 004h, 020h, 0E8h, 0CFh, 007h, 000h
	db 000h, 000h, 066h, 008h, 0E8h, 0CFh, 008h, 000h
	db 000h, 000h, 06Eh, 030h, 0E1h, 0D8h, 081h, 020h
	db 0AFh, 004h, 0F0h, 066h, 05Bh, 0F1h, 063h, 089h
	db 032h, 0EEh, 088h, 041h, 00Fh, 000h, 0C0h, 001h
	db 01Dh, 058h, 09Dh, 0FAh, 0F1h, 08Dh, 089h, 032h
	db 0EEh, 088h, 041h, 00Fh, 000h, 0C0h, 001h, 01Dh
	db 058h, 09Dh, 0FAh, 0AFh, 004h, 020h, 0F1h, 0D8h
	db 081h, 060h, 068h, 034h, 0AFh, 004h, 020h, 0E8h
	db 0CFh, 028h, 000h, 000h, 000h, 06Eh, 029h, 0C1h
	db 0DEh, 081h, 03Fh, 000h, 066h, 00Ch, 0EEh, 088h
	db 0CDh, 08Bh, 01Eh, 0C7h, 0FBh, 0F1h, 0DEh, 081h
	db 000h, 000h, 0C1h, 0DCh, 081h, 03Fh, 000h, 066h
	db 00Fh, 0C2h, 092h, 009h, 0EAh, 023h, 0EEh, 088h
	db 01Eh, 0C1h, 0FCh, 0F1h, 0DCh, 081h, 000h, 000h
	db 0EBh, 0A8h, 05Eh, 0EFh, 064h, 00Eh, 0EFh, 06Ch
	db 02Eh, 0BFh, 002h, 060h, 0E9h, 0CFh, 00Bh, 000h
	db 0C0h, 001h, 06Eh, 048h, 0DEh, 0A8h, 0DEh, 08Ah
	db 0DAh, 008h, 015h, 000h, 0F1h, 04Eh, 089h, 031h
	db 0DAh, 08Bh, 0EBh, 012h, 0E9h, 083h, 0C7h, 0F8h
	db 089h, 0B3h, 041h, 0D8h, 0A9h, 0DAh, 080h, 0E8h
	db 012h, 0E9h, 080h, 0B0h, 000h, 000h, 031h, 010h
	db 000h, 01Eh, 019h, 0E1h, 0DEh, 08Ah, 0DAh, 008h
	db 015h, 000h, 0F1h, 04Eh, 089h, 030h, 0EAh, 012h
	db 0E8h, 082h, 0AFh, 002h, 020h, 041h, 00Fh, 000h
	db 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh, 0DEh, 061h
	db 0DEh, 0DCh, 067h, 0BAh, 0EBh, 0A8h, 04Eh, 0EFh
	db 064h, 00Eh

SingleLoadSrcFunc:
	DEC 4, XSP
	PUSH XIZ
	LD XIZ, XDE
	LD (XSP + 004h), XBC
	LD XWA, (XSP + 004h)
	CP XWA, 01e50003h
	JRL Z, LABEL_F9006C
	CP XWA, 01c00018h
	JR Z, LABEL_F8FF27
	CP XWA, 01c00017h
	JR Z, LABEL_F8FF27
	CP XWA, 01c0000bh
	JR Z, LABEL_F8FEEF
	CP XWA, 01e50004h
	JRL NZ, LABEL_F90068
	LD XWA, XIZ
	LD (81E0h), XWA
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	JRL T, LABEL_F90068

LABEL_F8FEEF:
	LD XWA, (81E0h)
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, (81E0h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0996h
	LDA XHL, XDE + BC
	LD XBC, (XSP + 004h)
	LD XDE, XIZ
	LD XHL, (XHL)
	CALL T, XHL
	CALR SignalProgressUpdate
	JRL T, LABEL_F90068

LABEL_F8FF27:
	CP XIZ, 00000005h
	JR NZ, LABEL_F8FF78
	CP (89F8h), 001h
	JR Z, LABEL_F8FF43
	LD XWA, (81E0h)
	LD XBC, 01e50002h
	LD XDE, 1
	JR T, LABEL_F8FF51

LABEL_F8FF43:
	LD XWA, (81E0h)
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh

LABEL_F8FF51:
	CALL ApPostEvent
	LD XWA, (81E0h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0996h
	LDA XHL, XDE + BC
	LD XBC, (XSP + 004h)
	LD XDE, XIZ
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F90068

LABEL_F8FF78:
	CP XIZ, 00000006h
	JR NZ, LABEL_F8FFD0
	CP (89F8h), 001h
	JR Z, LABEL_F8FF9B
	CP (89FAh), 000h
	JR NZ, LABEL_F8FF9B
	LD XWA, (81E0h)
	LD XBC, 01e50002h
	LD XDE, 3
	JR T, LABEL_F8FFA9

LABEL_F8FF9B:
	LD XWA, (81E0h)
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh

LABEL_F8FFA9:
	CALL ApPostEvent
	LD XWA, (81E0h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0996h
	LDA XHL, XDE + BC
	LD XBC, (XSP + 004h)
	LD XDE, XIZ
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F90068

LABEL_F8FFD0:
	LD XWA, (81E0h)
	CP XIZ, 00000007h
	JR NZ, LABEL_F9000C
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, (81E0h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0996h
	LDA XHL, XDE + BC
	LD XBC, (XSP + 004h)
	LD XDE, XIZ
	LD XHL, (XHL)
	CALL T, XHL
	JR T, LABEL_F90068

LABEL_F9000C:
	CP XIZ, 00000008h
	JR NZ, LABEL_F90044
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, (81E0h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0996h
	LDA XHL, XDE + BC
	LD XBC, (XSP + 004h)
	LD XDE, XIZ
	LD XHL, (XHL)
	CALL T, XHL
	JR T, LABEL_F90068

LABEL_F90044:
	CP XIZ, 00000028h
	JR NZ, LABEL_F90068
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0996h
	LDA XHL, XDE + BC
	LD XBC, (XSP + 004h)
	LD XDE, XIZ
	LD XHL, (XHL)
	CALL T, XHL

LABEL_F90068:
	LD XHL, 0
	JR T, LABEL_F90071

LABEL_F9006C:
	LD XHL, 0ffffffffh

LABEL_F90071:
	POP XIZ
	INC 4, XSP
	RET

LABEL_F90075:
	db 0EFh, 06Eh, 03Eh, 0BFh, 004h, 043h, 0BFh, 006h
	db 060h, 0F1h, 0A2h, 089h, 030h, 0F5h, 0E0h, 000h
	db 000h, 0C1h, 0F8h, 089h, 023h, 0D9h, 012h, 0D9h
	db 0ECh, 002h, 0F2h, 0F2h, 005h, 0EAh, 032h, 0E3h
	db 007h, 0E8h, 0E4h, 021h, 0E9h, 061h, 01Dh, 0DCh
	db 090h, 0F8h, 0F1h, 0A3h, 089h, 030h, 041h, 0AAh
	db 009h, 0EAh, 000h, 01Dh, 013h, 091h, 0F8h, 0F1h
	db 0A3h, 089h, 036h, 0C1h, 002h, 08Ah, 021h, 0D8h
	db 012h, 08Fh, 004h, 051h, 0C9h, 061h, 0D8h, 012h
	db 0D9h, 0A8h, 01Eh, 0BDh, 0B5h, 0EBh, 089h, 0EEh
	db 088h, 01Dh, 013h, 091h, 0F8h, 0F1h, 0A3h, 089h
	db 030h, 031h, 010h, 000h, 01Eh, 0C2h, 0DEh, 0F1h
	db 0B7h, 089h, 030h, 0C1h, 002h, 08Ah, 023h, 0D9h
	db 012h, 08Fh, 004h, 053h, 0D9h, 012h, 0DAh, 0A9h
	db 01Eh, 0EAh, 0ECh, 0F1h, 0B8h, 089h, 030h, 031h
	db 010h, 000h, 01Eh, 0A4h, 0DEh, 0AFh, 006h, 020h
	db 041h, 00Fh, 000h, 0C0h, 001h, 042h, 0A2h, 089h
	db 000h, 000h, 01Dh, 058h, 09Dh, 0FAh, 0F1h, 0B7h
	db 089h, 032h, 0AFh, 006h, 020h, 041h, 00Fh, 000h
	db 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh, 05Eh, 0EFh
	db 066h, 00Eh, 0EFh, 06Eh, 03Eh, 0BFh, 004h, 043h
	db 0BFh, 006h, 060h, 0F1h, 0A2h, 089h, 032h, 0BAh
	db 02Ah, 000h, 002h, 0BAh, 03Fh, 000h, 003h, 0C1h
	db 0F8h, 089h, 021h, 0D8h, 012h, 0F2h, 024h, 006h
	db 0EAh, 033h, 0D8h, 089h, 0D9h, 0ECh, 002h, 0BAh
	db 02Bh, 030h, 0E3h, 007h, 0ECh, 0E4h, 021h, 0E9h
	db 061h, 0C1h, 0FAh, 089h, 03Fh, 000h, 066h, 02Ah
	db 01Dh, 0DCh, 090h, 0F8h, 0F1h, 0CDh, 089h, 030h
	db 041h, 0AEh, 009h, 0EAh, 000h, 01Dh, 013h, 091h
	db 0F8h, 0F1h, 0CDh, 089h, 030h, 031h, 010h, 000h
	db 01Eh, 02Eh, 0DEh, 0F1h, 0E2h, 089h, 030h, 041h
	dd LABEL_EA09B2
	db 01Dh, 0DCh, 090h, 0F8h
	db 068h, 04Ah, 01Dh, 0DCh, 090h, 0F8h, 0F1h, 0CDh
	db 089h, 030h, 041h, 0C4h, 009h, 0EAh, 000h, 01Dh
	db 013h, 091h, 0F8h, 0F1h, 0CDh, 089h, 036h, 0C1h
	db 002h, 08Ah, 021h, 0D8h, 012h, 08Fh, 004h, 051h
	db 0C8h, 089h, 0C9h, 061h, 0D8h, 012h, 0D9h, 0A8h
	db 01Eh, 0DFh, 0B4h, 0EBh, 089h, 0EEh, 088h, 01Dh
	db 013h, 091h, 0F8h, 0F1h, 0CDh, 089h, 030h, 031h
	db 010h, 000h, 01Eh, 0E4h, 0DDh, 0F1h, 0E1h, 089h
	db 030h, 0C1h, 002h, 08Ah, 023h, 0D9h, 012h, 0DAh
	db 0ABh, 01Eh, 03Fh, 0ECh, 0F1h, 0CCh, 089h, 032h
	db 0AFh, 006h, 020h, 041h, 00Fh, 000h, 0C0h, 001h
	db 01Dh, 058h, 09Dh, 0FAh, 0F1h, 0E1h, 089h, 032h
	db 0AFh, 006h, 020h, 041h, 00Fh, 000h, 0C0h, 001h
	db 01Dh, 058h, 09Dh, 0FAh, 05Eh, 0EFh, 066h, 00Eh
	db 0EFh, 06Ch, 03Eh, 0BFh, 004h, 062h, 0E9h, 08Ah
	db 0E8h, 08Eh, 0C2h, 0C8h, 009h, 0EAh, 023h, 0EAh
	db 0CFh, 018h, 000h, 0C0h, 001h, 066h, 029h, 0EAh
	db 0CFh, 017h, 000h, 0C0h, 001h, 066h, 021h, 0EAh
	db 0CFh, 00Bh, 000h, 0C0h, 001h, 07Eh, 0B8h, 000h
	db 0EEh, 088h, 01Eh, 063h, 0FEh, 0C2h, 0C8h, 009h
	db 0EAh, 023h, 0EEh, 088h, 01Eh, 0FBh, 0FEh, 0E8h
	db 0A8h, 0F1h, 0E4h, 081h, 060h, 078h, 0A0h, 000h
	db 0C1h, 002h, 08Ah, 027h, 0AFh, 004h, 020h, 0E8h
	db 0CFh, 007h, 000h, 000h, 000h, 07Eh, 095h, 000h
	db 0EAh, 08Ch, 0EAh, 0CFh, 017h, 000h, 0C0h, 001h
	db 06Eh, 02Bh, 0C2h, 0C8h, 009h, 0EAh, 025h, 0CDh
	db 089h, 0CFh, 08Bh, 0CFh, 081h, 0C2h, 0CAh, 009h
	db 0EAh, 0F1h, 06Fh, 019h, 0CDh, 083h, 0F1h, 002h
	db 08Ah, 043h, 0C2h, 0C8h, 009h, 0EAh, 023h, 0EEh
	db 088h, 01Eh, 014h, 0FEh, 0C2h, 0C8h, 009h, 0EAh
	db 023h, 0EEh, 088h, 068h, 02Ah, 0ECh, 0CFh, 018h
	db 000h, 0C0h, 001h, 06Eh, 025h, 0CFh, 089h, 0C2h
	db 0C8h, 009h, 0EAh, 023h, 0CBh, 0F7h, 067h, 01Ah
	db 0CBh, 0A1h, 0F1h, 002h, 08Ah, 041h, 0C2h, 0C8h
	db 009h, 0EAh, 023h, 0EEh, 088h, 01Eh, 0E8h, 0FDh
	db 0C2h, 0C8h, 009h, 0EAh, 023h, 0EEh, 088h, 01Eh
	db 080h, 0FEh, 0E1h, 0E4h, 081h, 020h, 0AFh, 004h
	db 0F0h, 066h, 025h, 0F1h, 0B7h, 089h, 032h, 0EEh
	db 088h, 041h, 00Fh, 000h, 0C0h, 001h, 01Dh, 058h
	db 09Dh, 0FAh, 0F1h, 0E1h, 089h, 032h, 0EEh, 088h
	db 041h, 00Fh, 000h, 0C0h, 001h, 01Dh, 058h, 09Dh
	db 0FAh, 0AFh, 004h, 020h, 0F1h, 0E4h, 081h, 060h
	db 0EBh, 0A8h, 078h, 01Ah, 001h, 0AFh, 004h, 020h
	db 0E8h, 0CFh, 008h, 000h, 000h, 000h, 07Eh, 091h
	db 000h, 0EAh, 08Ch, 0EAh, 0CFh, 017h, 000h, 0C0h
	db 001h, 06Eh, 031h, 0CFh, 08Bh, 0CFh, 089h, 0C9h
	db 061h, 0C2h, 0CAh, 009h, 0EAh, 0F1h, 06Fh, 024h
	db 0C2h, 0C8h, 009h, 0EAh, 025h, 0CDh, 08Fh, 0CBh
	db 089h, 0D8h, 012h, 0CFh, 051h, 0C8h, 089h, 0C9h
	db 061h, 0CDh, 0F1h, 06Fh, 03Eh, 0CBh, 061h, 0F1h
	db 002h, 08Ah, 043h, 0C2h, 0C8h, 009h, 0EAh, 023h
	db 0EEh, 088h, 068h, 02Ch, 0ECh, 0CFh, 018h, 000h
	db 0C0h, 001h, 06Eh, 027h, 0CFh, 08Bh, 0CFh, 0D8h
	db 066h, 021h, 0C2h, 0C8h, 009h, 0EAh, 025h, 0CBh
	db 089h, 0D8h, 012h, 0CDh, 051h, 0C8h, 089h, 0C9h
	db 0D8h, 066h, 010h, 0CBh, 069h, 0F1h, 002h, 08Ah
	db 043h, 0C2h, 0C8h, 009h, 0EAh, 023h, 0EEh, 088h
	db 01Eh, 0D7h, 0FDh, 0E1h, 0E4h, 081h, 020h, 0AFh
	db 004h, 0F0h, 076h, 07Bh, 0FFh, 0F1h, 0B7h, 089h
	db 032h, 0EEh, 088h, 041h, 00Fh, 000h, 0C0h, 001h
	db 01Dh, 058h, 09Dh, 0FAh, 0F1h, 0E1h, 089h, 032h
	db 0EEh, 088h, 041h, 00Fh, 000h, 0C0h, 001h, 078h
	db 053h, 0FFh, 0AFh, 004h, 020h, 0E8h, 0CFh, 005h
	db 000h, 000h, 000h, 066h, 008h, 0E8h, 0CFh, 006h
	db 000h, 000h, 000h, 06Eh, 027h, 0E1h, 0E4h, 081h
	db 020h, 0AFh, 004h, 0F0h, 076h, 041h, 0FFh, 0F1h
	db 0B7h, 089h, 032h, 0EEh, 088h, 041h, 00Fh, 000h
	db 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh, 0F1h, 0E1h
	db 089h, 032h, 0EEh, 088h, 041h, 00Fh, 000h, 0C0h
	db 001h, 078h, 019h, 0FFh, 0AFh, 004h, 020h, 0E8h
	db 0CFh, 00Ah, 000h, 000h, 000h, 07Eh, 018h, 0FFh
	db 0C1h, 0FAh, 089h, 03Fh, 000h, 066h, 01Eh, 0C1h
	db 0FCh, 089h, 021h, 0D8h, 012h, 0CBh, 051h, 0D8h
	db 012h, 0C1h, 002h, 08Ah, 025h, 0DAh, 012h, 0CBh
	db 055h, 0DAh, 012h, 0DAh, 089h, 01Dh, 056h, 082h
	db 0F8h, 0EBh, 013h, 068h, 012h, 0C1h, 0FCh, 089h
	db 021h, 0D8h, 012h, 0C1h, 002h, 08Ah, 023h, 0D9h
	db 012h, 01Dh, 07Eh, 081h, 0F8h, 0EBh, 013h, 05Eh
	db 0EFh, 064h, 00Eh, 0EFh, 06Ch, 03Eh, 0BFh, 004h
	db 060h, 0F1h, 0A2h, 089h, 030h, 0B8h, 015h, 000h
	db 001h, 0B8h, 016h, 030h, 0C1h, 0F8h, 089h, 023h
	db 0D9h, 012h, 0D9h, 0ECh, 002h, 0F2h, 024h, 006h
	db 0EAh, 032h, 0E3h, 007h, 0E8h, 0E4h, 021h, 0E9h
	db 061h, 01Dh, 0DCh, 090h, 0F8h, 0F1h, 0B8h, 089h
	db 030h, 041h, 0CCh, 009h, 0EAh, 000h, 01Dh, 013h
	db 091h, 0F8h, 0F1h, 0B8h, 089h, 036h, 0C1h, 004h
	db 08Ah, 021h, 0C9h, 061h, 0D8h, 012h, 0D9h, 0A8h
	db 01Eh, 04Fh, 0B2h, 0EBh, 089h, 0EEh, 088h, 01Dh
	db 013h, 091h, 0F8h, 0F1h, 0B8h, 089h, 030h, 031h
	db 010h, 000h, 01Eh, 054h, 0DBh, 0F1h, 0CCh, 089h
	db 036h, 0C1h, 004h, 08Ah, 021h, 0D8h, 012h, 0D9h
	db 0AAh, 0DAh, 0A8h, 01Eh, 090h, 015h, 0EBh, 089h
	db 0EEh, 088h, 01Dh, 0DCh, 090h, 0F8h, 0F1h, 0B7h
	db 089h, 032h, 0AFh, 004h, 020h, 041h, 00Fh, 000h
	db 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh, 0F1h, 0CCh
	db 089h, 032h, 0AFh, 004h, 020h, 041h, 00Fh, 000h
	db 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh, 05Eh, 0EFh
	db 064h, 00Eh, 03Eh, 0E8h, 08Eh, 0E9h, 0CFh, 018h
	db 000h, 0C0h, 001h, 066h, 058h, 0E9h, 0CFh, 017h
	db 000h, 0C0h, 001h, 066h, 050h, 0E9h, 0CFh, 00Bh
	db 000h, 0C0h, 001h, 06Eh, 07Ah, 0F1h, 0A2h, 089h
	db 030h, 0F5h, 0E0h, 000h, 000h, 0B0h, 000h, 000h
	db 031h, 010h, 000h, 01Eh, 0EBh, 0DAh, 0F1h, 0A2h
	db 089h, 030h, 0B8h, 03Fh, 000h, 003h, 0B8h, 040h
	db 030h, 0B0h, 000h, 000h, 031h, 010h, 000h, 01Eh
	db 0D7h, 0DAh, 0EEh, 088h, 041h, 00Fh, 000h, 0C0h
	db 001h, 042h, 0A2h, 089h, 000h, 000h, 01Dh, 058h
	db 09Dh, 0FAh, 0F1h, 0E1h, 089h, 032h, 0EEh, 088h
	db 041h, 00Fh, 000h, 0C0h, 001h, 01Dh, 058h, 09Dh
	db 0FAh, 0EEh, 088h, 068h, 02Fh, 0C1h, 004h, 08Ah
	db 020h, 0F1h, 0CCh, 089h, 033h, 0EAh, 0CFh, 008h
	db 000h, 000h, 000h, 06Eh, 049h, 0E9h, 08Ah, 0EAh
	db 0CFh, 017h, 000h, 0C0h, 001h, 06Eh, 01Ch, 0C8h
	db 08Bh, 0C8h, 089h, 0C9h, 061h, 0C2h, 0D0h, 009h
	db 0EAh, 0F1h, 06Fh, 00Fh, 0CBh, 061h, 0F1h, 004h
	db 08Ah, 043h, 0EEh, 088h, 01Eh, 0D4h, 0FEh, 0EBh
	db 0A8h, 068h, 056h, 0EAh, 0CFh, 018h, 000h, 0C0h
	db 001h, 06Eh, 010h, 0C8h, 089h, 0C8h, 0D8h, 066h
	db 00Ah, 0C9h, 069h, 0F1h, 004h, 08Ah, 041h, 0EEh
	db 088h, 068h, 0E1h, 0EEh, 088h, 041h, 00Fh, 000h
	db 0C0h, 001h, 0EBh, 08Ah, 068h, 019h, 0EAh, 0CFh
	db 005h, 000h, 000h, 000h, 067h, 017h, 0EAh, 0CFh
	db 007h, 000h, 000h, 000h, 06Bh, 00Fh, 0EEh, 088h
	db 041h, 00Fh, 000h, 0C0h, 001h, 0EBh, 08Ah, 01Dh
	db 058h, 09Dh, 0FAh, 068h, 0BAh, 0EAh, 0CFh, 00Ah
	db 000h, 000h, 000h, 06Eh, 0B2h, 0C1h, 004h, 08Ah
	db 021h, 0D8h, 012h, 01Dh, 076h, 083h, 0F8h, 0EBh
	db 013h, 05Eh, 00Eh, 0EFh, 06Ah, 03Eh, 0BFh, 004h
	db 043h, 0E8h, 08Eh, 0F1h, 0A2h, 089h, 030h, 0F5h
	db 0E0h, 000h, 000h, 0C1h, 0F8h, 089h, 023h, 0D9h
	db 012h, 0D9h, 0ECh, 002h, 0F2h, 0F2h, 005h, 0EAh
	db 032h, 0E3h, 007h, 0E8h, 0E4h, 021h, 0E9h, 061h
	db 01Dh, 0DCh, 090h, 0F8h, 0F1h, 0A3h, 089h, 030h
	db 041h, 0D2h, 009h, 0EAh, 000h, 01Dh, 013h, 091h
	db 0F8h, 0F1h, 0A3h, 089h, 030h, 031h, 010h, 000h
	db 01Eh, 0E6h, 0D9h, 0F1h, 0B7h, 089h, 030h, 0C1h
	db 006h, 08Ah, 023h, 0D9h, 012h, 08Fh, 004h, 053h
	db 0D9h, 012h, 0DAh, 0A9h, 01Eh, 06Ch, 0E8h, 0EEh
	db 088h, 041h, 00Fh, 000h, 0C0h, 001h, 042h, 0A2h
	db 089h, 000h, 000h, 01Dh, 058h, 09Dh, 0FAh, 0F1h
	db 0B7h, 089h, 032h, 0EEh, 088h, 041h, 00Fh, 000h
	db 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh, 05Eh, 0EFh
	db 062h, 00Eh, 0EFh, 06Eh, 03Eh, 0BFh, 004h, 043h
	db 0BFh, 006h, 060h, 0F1h, 0A2h, 089h, 030h, 0B8h
	db 02Ah, 000h, 002h, 0B8h, 02Bh, 030h, 0C1h, 0F8h
	db 089h, 023h, 0D9h, 012h, 0D9h, 0ECh, 002h, 0F2h
	db 024h, 006h, 0EAh, 032h, 0E3h, 007h, 0E8h, 0E4h
	db 021h, 0E9h, 061h, 01Dh, 0DCh, 090h, 0F8h, 0F1h
	db 0CDh, 089h, 030h, 041h, 0D6h, 009h, 0EAh, 000h
	db 01Dh, 013h, 091h, 0F8h, 0C1h, 0FAh, 089h, 03Fh
	db 000h, 06Eh, 01Ch, 0F1h, 0CDh, 089h, 036h, 0C1h
	db 006h, 08Ah, 021h, 0D8h, 012h, 08Fh, 004h, 051h
	db 0C8h, 089h, 0D8h, 012h, 01Eh, 01Ah, 0E8h, 0EBh
	db 089h, 0EEh, 088h, 01Dh, 013h, 091h, 0F8h, 0F1h
	db 0CDh, 089h, 030h, 031h, 010h, 000h, 01Eh, 048h
	db 0D9h, 0F1h, 0A2h, 089h, 031h, 0B9h, 03Fh, 030h
	db 0C1h, 0FAh, 089h, 03Fh, 000h, 066h, 011h, 0B0h
	db 000h, 003h, 0B9h, 040h, 030h, 041h, 0DAh, 009h
	db 0EAh, 000h, 01Dh, 0DCh, 090h, 0F8h, 068h, 01Ch
	db 0C1h, 006h, 08Ah, 025h, 0CDh, 08Bh, 0D9h, 012h
	db 08Fh, 004h, 053h, 0D9h, 012h, 0DAh, 012h, 08Fh
	db 004h, 055h, 0CCh, 08Dh, 0DAh, 012h, 00Bh, 003h
	db 000h, 01Eh, 0DCh, 0E7h, 0F1h, 0CCh, 089h, 032h
	db 0AFh, 006h, 020h, 041h, 00Fh, 000h, 0C0h, 001h
	db 01Dh, 058h, 09Dh, 0FAh, 0F1h, 0E1h, 089h, 032h
	db 0AFh, 006h, 020h, 041h, 00Fh, 000h, 0C0h, 001h
	db 01Dh, 058h, 09Dh, 0FAh, 05Eh, 0EFh, 066h, 00Eh
	db 0EFh, 06Ch, 03Eh, 0BFh, 004h, 062h, 0E9h, 08Ah
	db 0E8h, 08Eh, 0C2h, 0ECh, 009h, 0EAh, 023h, 0EAh
	db 0CFh, 018h, 000h, 0C0h, 001h, 066h, 029h, 0EAh
	db 0CFh, 017h, 000h, 0C0h, 001h, 066h, 021h, 0EAh
	db 0CFh, 00Bh, 000h, 0C0h, 001h, 07Eh, 0B8h, 000h
	db 0EEh, 088h, 01Eh, 096h, 0FEh, 0C2h, 0ECh, 009h
	db 0EAh, 023h, 0EEh, 088h, 01Eh, 003h, 0FFh, 0E8h
	db 0A8h, 0F1h, 0E8h, 081h, 060h, 078h, 0A0h, 000h
	db 0C1h, 006h, 08Ah, 027h, 0AFh, 004h, 020h, 0E8h
	db 0CFh, 007h, 000h, 000h, 000h, 07Eh, 095h, 000h
	db 0EAh, 08Ch, 0EAh, 0CFh, 017h, 000h, 0C0h, 001h
	db 06Eh, 02Bh, 0C2h, 0ECh, 009h, 0EAh, 025h, 0CDh
	db 089h, 0CFh, 08Bh, 0CFh, 081h, 0C2h, 0EEh, 009h
	db 0EAh, 0F1h, 06Fh, 019h, 0CDh, 083h, 0F1h, 006h
	db 08Ah, 043h, 0C2h, 0ECh, 009h, 0EAh, 023h, 0EEh
	db 088h, 01Eh, 047h, 0FEh, 0C2h, 0ECh, 009h, 0EAh
	db 023h, 0EEh, 088h, 068h, 02Ah, 0ECh, 0CFh, 018h
	db 000h, 0C0h, 001h, 06Eh, 025h, 0CFh, 089h, 0C2h
	db 0ECh, 009h, 0EAh, 023h, 0CBh, 0F7h, 067h, 01Ah
	db 0CBh, 0A1h, 0F1h, 006h, 08Ah, 041h, 0C2h, 0ECh
	db 009h, 0EAh, 023h, 0EEh, 088h, 01Eh, 01Bh, 0FEh
	db 0C2h, 0ECh, 009h, 0EAh, 023h, 0EEh, 088h, 01Eh
	db 088h, 0FEh, 0E1h, 0E8h, 081h, 020h, 0AFh, 004h
	db 0F0h, 066h, 025h, 0F1h, 0B7h, 089h, 032h, 0EEh
	db 088h, 041h, 00Fh, 000h, 0C0h, 001h, 01Dh, 058h
	db 09Dh, 0FAh, 0F1h, 0E1h, 089h, 032h, 0EEh, 088h
	db 041h, 00Fh, 000h, 0C0h, 001h, 01Dh, 058h, 09Dh
	db 0FAh, 0AFh, 004h, 020h, 0F1h, 0E8h, 081h, 060h
	db 0EBh, 0A8h, 078h, 01Ah, 001h, 0AFh, 004h, 020h
	db 0E8h, 0CFh, 008h, 000h, 000h, 000h, 07Eh, 091h
	db 000h, 0EAh, 08Ch, 0EAh, 0CFh, 017h, 000h, 0C0h
	db 001h, 06Eh, 031h, 0CFh, 08Bh, 0CFh, 089h, 0C9h
	db 061h, 0C2h, 0EEh, 009h, 0EAh, 0F1h, 06Fh, 024h
	db 0C2h, 0ECh, 009h, 0EAh, 025h, 0CDh, 08Fh, 0CBh
	db 089h, 0D8h, 012h, 0CFh, 051h, 0C8h, 089h, 0C9h
	db 061h, 0CDh, 0F1h, 06Fh, 03Eh, 0CBh, 061h, 0F1h
	db 006h, 08Ah, 043h, 0C2h, 0ECh, 009h, 0EAh, 023h
	db 0EEh, 088h, 068h, 02Ch, 0ECh, 0CFh, 018h, 000h
	db 0C0h, 001h, 06Eh, 027h, 0CFh, 08Bh, 0CFh, 0D8h
	db 066h, 021h, 0C2h, 0ECh, 009h, 0EAh, 025h, 0CBh
	db 089h, 0D8h, 012h, 0CDh, 051h, 0C8h, 089h, 0C9h
	db 0D8h, 066h, 010h, 0CBh, 069h, 0F1h, 006h, 08Ah
	db 043h, 0C2h, 0ECh, 009h, 0EAh, 023h, 0EEh, 088h
	db 01Eh, 0DFh, 0FDh, 0E1h, 0E8h, 081h, 020h, 0AFh
	db 004h, 0F0h, 076h, 07Bh, 0FFh, 0F1h, 0B7h, 089h
	db 032h, 0EEh, 088h, 041h, 00Fh, 000h, 0C0h, 001h
	db 01Dh, 058h, 09Dh, 0FAh, 0F1h, 0E1h, 089h, 032h
	db 0EEh, 088h, 041h, 00Fh, 000h, 0C0h, 001h, 078h
	db 053h, 0FFh, 0AFh, 004h, 020h, 0E8h, 0CFh, 005h
	db 000h, 000h, 000h, 066h, 008h, 0E8h, 0CFh, 006h
	db 000h, 000h, 000h, 06Eh, 027h, 0E1h, 0E8h, 081h
	db 020h, 0AFh, 004h, 0F0h, 076h, 041h, 0FFh, 0F1h
	db 0B7h, 089h, 032h, 0EEh, 088h, 041h, 00Fh, 000h
	db 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh, 0F1h, 0E1h
	db 089h, 032h, 0EEh, 088h, 041h, 00Fh, 000h, 0C0h
	db 001h, 078h, 019h, 0FFh, 0AFh, 004h, 020h, 0E8h
	db 0CFh, 00Ah, 000h, 000h, 000h, 07Eh, 018h, 0FFh
	db 0C1h, 0FAh, 089h, 03Fh, 000h, 066h, 01Eh, 0C1h
	db 0FEh, 089h, 021h, 0D8h, 012h, 0CBh, 051h, 0C9h
	db 0C8h, 01Eh, 0D8h, 012h, 0C1h, 006h, 08Ah, 025h
	db 0DAh, 012h, 0CBh, 055h, 0CDh, 0C8h, 01Eh, 0DAh
	db 012h, 0DAh, 089h, 068h, 00Ch, 0C1h, 0FEh, 089h
	db 021h, 0D8h, 012h, 0C1h, 006h, 08Ah, 023h, 0D9h
	db 012h, 01Dh, 05Ch, 084h, 0F8h, 0EBh, 013h, 05Eh
	db 0EFh, 064h, 00Eh, 0EFh, 06Eh, 0B7h, 043h, 0BFh
	db 002h, 060h, 0F1h, 0A2h, 089h, 030h, 0F5h, 0E0h
	db 000h, 000h, 0C1h, 0F8h, 089h, 023h, 0D9h, 012h
	db 0D9h, 0ECh, 002h, 0F2h, 0F2h, 005h, 0EAh, 032h
	db 0E3h, 007h, 0E8h, 0E4h, 021h, 0E9h, 061h, 01Dh
	db 0DCh, 090h, 0F8h, 0F1h, 0A3h, 089h, 030h, 041h
	dd LABEL_EA09F0
	db 01Dh, 013h, 091h, 0F8h
	db 0F1h, 0A3h, 089h, 030h, 031h, 010h, 000h, 01Eh
	db 0A7h, 0D6h, 087h, 025h, 087h, 085h, 0C1h, 008h
	db 08Ah, 023h, 0F1h, 0B7h, 089h, 030h, 0CDh, 0F3h
	db 06Fh, 00Dh, 0D9h, 012h, 087h, 053h, 0D9h, 012h
	db 0DAh, 0A9h, 01Eh, 0ABh, 0E5h, 068h, 005h, 0D9h
	db 0A9h, 01Eh, 0F7h, 0E5h, 0AFh, 002h, 020h, 041h
	db 00Fh, 000h, 0C0h, 001h, 042h, 0A2h, 089h, 000h
	db 000h, 01Dh, 058h, 09Dh, 0FAh, 0F1h, 0B7h, 089h
	db 032h, 0AFh, 002h, 020h, 041h, 00Fh, 000h, 0C0h
	db 001h, 01Dh, 058h, 09Dh, 0FAh, 0EFh, 066h, 00Eh
	db 0EFh, 06Eh, 03Eh, 0BFh, 004h, 043h, 0BFh, 006h
	db 060h, 0F2h, 024h, 006h, 0EAh, 032h, 0C1h, 0FAh
	db 089h, 03Fh, 000h, 066h, 04Dh, 0F1h, 0A2h, 089h
	db 030h, 0B8h, 02Ah, 000h, 002h, 0B8h, 02Bh, 030h
	db 0C1h, 0F8h, 089h, 023h, 0D9h, 012h, 0D9h, 0ECh
	db 002h, 0E3h, 007h, 0E8h, 0E4h, 021h, 0E9h, 061h
	db 01Dh, 0DCh, 090h, 0F8h, 0F1h, 0CDh, 089h, 030h
	db 041h, 0F4h, 009h, 0EAh, 000h, 01Dh, 013h, 091h
	db 0F8h, 0F1h, 0CDh, 089h, 030h, 031h, 010h, 000h
	db 01Eh, 016h, 0D6h, 0F1h, 0A2h, 089h, 030h, 0B8h
	db 03Fh, 000h, 003h, 0B8h, 040h, 030h, 041h, 0F8h
	db 009h, 0EAh, 000h, 01Dh, 0DCh, 090h, 0F8h, 078h
	db 0D6h, 000h, 08Fh, 004h, 027h, 08Fh, 004h, 087h
	db 0F1h, 0A2h, 089h, 031h, 0B9h, 02Bh, 030h, 0B9h
	db 02Ah, 000h, 002h, 0C1h, 008h, 08Ah, 0FFh, 067h
	db 065h, 0C1h, 0F8h, 089h, 023h, 0D9h, 012h, 0D9h
	db 0ECh, 002h, 0E3h, 007h, 0E8h, 0E4h, 021h, 0E9h
	db 061h, 01Dh, 0DCh, 090h, 0F8h, 0F1h, 0CDh, 089h
	db 030h, 041h, 00Ah, 00Ah, 0EAh, 000h, 01Dh, 013h
	db 091h, 0F8h, 0F1h, 0CDh, 089h, 036h, 08Fh, 004h
	db 023h, 08Fh, 004h, 083h, 0C1h, 008h, 08Ah, 021h
	db 0CBh, 0A1h, 0C9h, 061h, 0D8h, 012h, 0D9h, 0A8h
	db 01Eh, 097h, 0ACh, 0EBh, 089h, 0EEh, 088h, 01Dh
	db 013h, 091h, 0F8h, 0F1h, 0CDh, 089h, 030h, 031h
	db 010h, 000h, 01Eh, 09Ch, 0D5h, 0F1h, 0E1h, 089h
	db 030h, 08Fh, 004h, 025h, 08Fh, 004h, 085h, 0C1h
	db 008h, 08Ah, 023h, 0CDh, 0A3h, 0D9h, 012h, 0DAh
	db 0ABh, 01Eh, 01Bh, 0E5h, 068h, 05Ah, 0C1h, 0F8h
	db 089h, 023h, 0D9h, 012h, 0D9h, 0ECh, 002h, 0E3h
	db 007h, 0E8h, 0E4h, 021h, 0E9h, 061h, 01Dh, 0DCh
	db 090h, 0F8h, 0F1h, 0CDh, 089h, 030h, 041h, 00Eh
	db 00Ah, 0EAh, 000h, 01Dh, 013h, 091h, 0F8h, 0F1h
	db 0CDh, 089h, 036h, 0C1h, 008h, 08Ah, 021h, 0D8h
	db 012h, 08Fh, 004h, 051h, 0C8h, 089h, 0C9h, 061h
	db 0D8h, 012h, 0D9h, 0A8h, 01Eh, 033h, 0ACh, 0EBh
	db 089h, 0EEh, 088h, 01Dh, 013h, 091h, 0F8h, 0F1h
	db 0CDh, 089h, 030h, 031h, 010h, 000h, 01Eh, 038h
	db 0D5h, 0F1h, 0E1h, 089h, 030h, 0C1h, 008h, 08Ah
	db 023h, 0D9h, 012h, 0DAh, 0ABh, 01Eh, 06Eh, 0E4h
	db 0F1h, 0CCh, 089h, 032h, 0AFh, 006h, 020h, 041h
	db 00Fh, 000h, 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh
	db 0F1h, 0E1h, 089h, 032h, 0AFh, 006h, 020h, 041h
	db 00Fh, 000h, 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh
	db 05Eh, 0EFh, 066h, 00Eh, 0EFh, 06Ch, 03Eh, 0BFh
	db 004h, 062h, 0E8h, 08Eh, 0C2h, 012h, 00Ah, 0EAh
	db 025h, 0E9h, 0CFh, 018h, 000h, 0C0h, 001h, 066h
	db 02Bh, 0E9h, 0CFh, 017h, 000h, 0C0h, 001h, 066h
	db 023h, 0E9h, 0CFh, 00Bh, 000h, 0C0h, 001h, 07Eh
	db 0FFh, 000h, 0EEh, 088h, 0CDh, 08Bh, 01Eh, 0F2h
	db 0FDh, 0C2h, 012h, 00Ah, 0EAh, 023h, 0EEh, 088h
	db 01Eh, 06Dh, 0FEh, 0E8h, 0A8h, 0F1h, 0ECh, 081h
	dd LABEL_E57860
	db 0C1h, 008h, 08Ah, 027h
	db 0AFh, 004h, 020h, 0E8h, 0CFh, 007h, 000h, 000h
	db 000h, 07Eh, 0DAh, 000h, 0E9h, 08Ah, 0E9h, 0CFh
	db 017h, 000h, 0C0h, 001h, 06Eh, 048h, 0C2h, 012h
	db 00Ah, 0EAh, 023h, 0CBh, 088h, 0CBh, 080h, 0CFh
	db 089h, 0C8h, 0F7h, 06Fh, 039h, 0CBh, 0F1h, 06Fh
	db 008h, 0CBh, 081h, 0F1h, 008h, 08Ah, 041h, 068h
	db 004h, 0F1h, 008h, 08Ah, 040h, 0C2h, 012h, 00Ah
	db 0EAh, 023h, 0EEh, 088h, 01Eh, 09Ch, 0FDh, 0C2h
	db 012h, 00Ah, 0EAh, 023h, 0EEh, 088h, 01Eh, 017h
	db 0FEh, 0C2h, 012h, 00Ah, 0EAh, 023h, 00Bh, 000h
	db 000h, 00Bh, 008h, 08Ah, 0AFh, 008h, 020h, 042h
	db 000h, 08Ah, 000h, 000h, 068h, 052h, 0EAh, 0CFh
	db 018h, 000h, 0C0h, 001h, 06Eh, 04Dh, 0CFh, 08Bh
	db 0C2h, 012h, 00Ah, 0EAh, 025h, 0CDh, 0F7h, 067h
	db 042h, 0CDh, 089h, 0CDh, 081h, 0C9h, 0F3h, 06Fh
	db 008h, 0CDh, 0A3h, 0F1h, 008h, 08Ah, 043h, 068h
	db 008h, 0C9h, 0F3h, 067h, 004h, 0F1h, 008h, 08Ah
	db 045h, 0C2h, 012h, 00Ah, 0EAh, 023h, 0EEh, 088h
	db 01Eh, 048h, 0FDh, 0C2h, 012h, 00Ah, 0EAh, 023h
	db 0EEh, 088h, 01Eh, 0C3h, 0FDh, 0C2h, 012h, 00Ah
	db 0EAh, 023h, 00Bh, 000h, 000h, 00Bh, 008h, 08Ah
	db 0AFh, 008h, 020h, 042h, 000h, 08Ah, 000h, 000h
	db 01Eh, 08Bh, 0EDh, 0E1h, 0ECh, 081h, 020h, 0AFh
	db 004h, 0F0h, 066h, 025h, 0F1h, 0B7h, 089h, 032h
	db 0EEh, 088h, 041h, 00Fh, 000h, 0C0h, 001h, 01Dh
	db 058h, 09Dh, 0FAh, 0F1h, 0E1h, 089h, 032h, 0EEh
	db 088h, 041h, 00Fh, 000h, 0C0h, 001h, 01Dh, 058h
	db 09Dh, 0FAh, 0AFh, 004h, 020h, 0F1h, 0ECh, 081h
	db 060h, 0EBh, 0A8h, 078h, 0A4h, 001h, 0AFh, 004h
	db 020h, 0E8h, 0CFh, 008h, 000h, 000h, 000h, 07Eh
	db 01Dh, 001h, 0E9h, 08Ah, 0E9h, 0CFh, 017h, 000h
	db 0C0h, 001h, 06Eh, 076h, 0CFh, 08Bh, 0CFh, 089h
	db 0C9h, 061h, 0C2h, 014h, 00Ah, 0EAh, 0F1h, 06Fh
	db 069h, 0C2h, 012h, 00Ah, 0EAh, 025h, 0CDh, 089h
	db 0CDh, 081h, 0C9h, 0F3h, 06Fh, 037h, 0CDh, 08Fh
	db 0CBh, 089h, 0D8h, 012h, 0CFh, 051h, 0C8h, 089h
	db 0C9h, 061h, 0CDh, 0F1h, 07Fh, 0C1h, 000h, 0CBh
	db 061h, 0F1h, 008h, 08Ah, 043h, 0C2h, 012h, 00Ah
	db 0EAh, 023h, 0EEh, 088h, 01Eh, 029h, 0FDh, 0C2h
	db 012h, 00Ah, 0EAh, 023h, 00Bh, 000h, 000h, 00Bh
	db 008h, 08Ah, 0AFh, 008h, 020h, 042h, 000h, 08Ah
	db 000h, 000h, 078h, 098h, 000h, 0CBh, 061h, 0F1h
	db 008h, 08Ah, 043h, 0C2h, 012h, 00Ah, 0EAh, 023h
	db 0EEh, 088h, 01Eh, 003h, 0FDh, 0C2h, 012h, 00Ah
	db 0EAh, 023h, 00Bh, 000h, 000h, 00Bh, 008h, 08Ah
	db 0AFh, 008h, 020h, 042h, 000h, 08Ah, 000h, 000h
	db 068h, 073h, 0EAh, 0CFh, 018h, 000h, 0C0h, 001h
	db 06Eh, 06Eh, 0CFh, 08Bh, 0CFh, 0D8h, 066h, 068h
	db 0C2h, 012h, 00Ah, 0EAh, 025h, 0CDh, 089h, 0CDh
	db 081h, 0C9h, 0F3h, 06Fh, 031h, 0CBh, 089h, 0D8h
	db 012h, 0CDh, 051h, 0C8h, 089h, 0C9h, 0D8h, 066h
	db 04Fh, 0CBh, 069h, 0F1h, 008h, 08Ah, 043h, 0C2h
	db 012h, 00Ah, 0EAh, 023h, 0EEh, 088h, 01Eh, 0B7h
	db 0FCh, 0C2h, 012h, 00Ah, 0EAh, 023h, 00Bh, 000h
	db 000h, 00Bh, 008h, 08Ah, 0AFh, 008h, 020h, 042h
	db 000h, 08Ah, 000h, 000h, 068h, 027h, 0C9h, 0F3h
	db 063h, 026h, 0CBh, 069h, 0F1h, 008h, 08Ah, 043h
	db 0C2h, 012h, 00Ah, 0EAh, 023h, 0EEh, 088h, 01Eh
	db 08Eh, 0FCh, 0C2h, 012h, 00Ah, 0EAh, 023h, 00Bh
	db 000h, 000h, 00Bh, 008h, 08Ah, 0AFh, 008h, 020h
	db 042h, 000h, 08Ah, 000h, 000h, 01Eh, 056h, 0ECh
	db 0E1h, 0ECh, 081h, 020h, 0AFh, 004h, 0F0h, 076h
	db 0EFh, 0FEh, 0F1h, 0B7h, 089h, 032h, 0EEh, 088h
	db 041h, 00Fh, 000h, 0C0h, 001h, 01Dh, 058h, 09Dh
	db 0FAh, 0F1h, 0E1h, 089h, 032h, 0EEh, 088h, 041h
	db 00Fh, 000h, 0C0h, 001h, 078h, 0C7h, 0FEh, 0AFh
	db 004h, 020h, 0E8h, 0CFh, 005h, 000h, 000h, 000h
	db 066h, 008h, 0E8h, 0CFh, 006h, 000h, 000h, 000h
	db 06Eh, 027h, 0E1h, 0ECh, 081h, 020h, 0AFh, 004h
	db 0F0h, 076h, 0B5h, 0FEh, 0F1h, 0B7h, 089h, 032h
	db 0EEh, 088h, 041h, 00Fh, 000h, 0C0h, 001h, 01Dh
	db 058h, 09Dh, 0FAh, 0F1h, 0E1h, 089h, 032h, 0EEh
	db 088h, 041h, 00Fh, 000h, 0C0h, 001h, 078h, 08Dh
	db 0FEh, 0AFh, 004h, 020h, 0E8h, 0CFh, 00Ah, 000h
	db 000h, 000h, 07Eh, 08Ch, 0FEh, 0C1h, 0FAh, 089h
	db 03Fh, 000h, 066h, 01Ch, 0C1h, 000h, 08Ah, 021h
	db 0D8h, 012h, 0CDh, 051h, 0D8h, 012h, 0C1h, 008h
	db 08Ah, 023h, 0D9h, 012h, 0CDh, 053h, 0D9h, 012h
	db 01Dh, 02Ah, 086h, 0F8h, 0EBh, 013h, 068h, 012h
	db 0C1h, 000h, 08Ah, 021h, 0D8h, 012h, 0C1h, 008h
	db 08Ah, 023h, 0D9h, 012h, 01Dh, 0D4h, 084h, 0F8h
	db 0EBh, 013h, 05Eh, 0EFh, 064h, 00Eh, 0EFh, 06Ch
	db 02Eh, 0BFh, 002h, 060h, 0E9h, 0CFh, 00Bh, 000h
	db 0C0h, 001h, 06Eh, 048h, 0DEh, 0A8h, 0DEh, 08Ah
	db 0DAh, 008h, 015h, 000h, 0F1h, 0A2h, 089h, 031h
	db 0DAh, 08Bh, 0EBh, 012h, 0E9h, 083h, 0C7h, 0F8h
	db 089h, 0B3h, 041h, 0D8h, 0A9h, 0DAh, 080h, 0E8h
	db 012h, 0E9h, 080h, 0B0h, 000h, 000h, 031h, 010h
	db 000h, 01Eh, 0FDh, 0D1h, 0DEh, 08Ah, 0DAh, 008h
	db 015h, 000h, 0F1h, 0A2h, 089h, 030h, 0EAh, 012h
	db 0E8h, 082h, 0AFh, 002h, 020h, 041h, 00Fh, 000h
	db 0C0h, 001h, 01Dh, 058h, 09Dh, 0FAh, 0DEh, 061h
	db 0DEh, 0DCh, 067h, 0BAh, 0EBh, 0A8h, 04Eh, 0EFh
	db 064h, 00Eh

SingleLoadDstFunc:
	DEC 8, XSP
	PUSH XIZ
	LD (XSP + 004h), XDE
	LD (XSP + 008h), XBC
	LD XIZ, XWA
	LD XWA, (XSP + 008h)
	CP XWA, 01e50003h
	JRL Z, LABEL_F91283
	CP XWA, 01c00018h
	JRL Z, LABEL_F90F21
	CP XWA, 01c00017h
	JRL Z, LABEL_F90F21
	CP XWA, 01c0000fh
	JRL Z, LABEL_F90EEA
	CP XWA, 01c0000bh
	JR Z, LABEL_F90E6D
	CP XWA, 01e50004h
	JR NZ, LABEL_F90E68
	LD XWA, (XSP + 004h)
	LD (81F0h), XWA
	LD WA, 0
	CALR InitializeOperationState
	CALR SignalProgressUpdate
	CALR LABEL_F8ECB3
	CALR SignalProgressUpdate
	CP (89F8h), 001h
	JR Z, LABEL_F90E2B
	LD XWA, 0061004ah
	LD XBC, 01e0009ch
	LD XDE, 1
	JR T, LABEL_F90E37

LABEL_F90E2B:
	LD XWA, 0061004ah
	LD XBC, 01e0009ch
	LD XDE, 0

LABEL_F90E37:
	CALL ApPostEvent
	LD XWA, (81F0h)
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	CP (89F8h), 000h
	JR NZ, LABEL_F90E63
	CALL LABEL_F873ED
	CP HL, 0
	JR Z, LABEL_F90E63
	LD (8A0Ah), 001h
	JR T, LABEL_F90E68

LABEL_F90E63:
	LD (8A0Ah), 000h

LABEL_F90E68:
	LD XHL, 0
	JRL T, LABEL_F91288

LABEL_F90E6D:
	LD XWA, XIZ
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	CALR SingleLoadModeFunc
	LD XWA, XIZ
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	CALR SingleLoadSrcBankFunc
	LD XWA, XIZ
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	CALR SingleLoadSrcMemFunc
	LD XWA, XIZ
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	CALR SingleLoadDstBankFunc
	LD XWA, XIZ
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	CALR SingleLoadDstMemFunc
	LD XWA, (81F0h)
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, 00610036h
	LD XBC, 01e0003bh
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, (81F0h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A16h
	LDA XHL, XDE + BC
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F90E68

LABEL_F90EEA:
	LD XWA, (81F0h)
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, (81F0h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A16h
	LDA XHL, XDE + BC
	LD XBC, 01c0000bh
	LD XDE, 0
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F90E68

LABEL_F90F21:
	LD XWA, (XSP + 004h)
	CP XWA, 00000003h
	JR NZ, LABEL_F90FAA
	CP (89F8h), 001h
	JR Z, LABEL_F90FAA
	LD XWA, (XSP + 008h)
	CP XWA, 01c00017h
	SCC Z, A
	LD (89FAh), A
	LD XWA, XIZ
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR SingleLoadSrcMemFunc
	LD XWA, XIZ
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR SingleLoadDstMemFunc
	LD XWA, (81F0h)
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, 00610036h
	LD XBC, 01e0003bh
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, (81F0h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A16h
	LDA XHL, XDE + BC
	LD XBC, 01c0000bh
	LD XDE, 0
	LD XHL, (XHL)
	CALL T, XHL
	LD XWA, XIZ
	LD XBC, 01c0000bh
	LD XDE, 0
	JRL T, LABEL_F9106C

LABEL_F90FAA:
	LD XWA, (XSP + 004h)
	CP XWA, 00000004h
	JRL NZ, LABEL_F91072
	CALR LABEL_F8ED83
	CP L, 0
	JRL Z, LABEL_F90E68
	CP (89F8h), 001h
	JR Z, LABEL_F90FD3
	LD XWA, 0061004ah
	LD XBC, 01e0009ch
	LD XDE, 1
	JR T, LABEL_F90FDF

LABEL_F90FD3:
	LD XWA, 0061004ah
	LD XBC, 01e0009ch
	LD XDE, 0

LABEL_F90FDF:
	CALL ApPostEvent
	LD XWA, XIZ
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR SingleLoadModeFunc
	LD XWA, XIZ
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR SingleLoadSrcBankFunc
	LD XWA, XIZ
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR SingleLoadSrcMemFunc
	LD XWA, XIZ
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR SingleLoadDstBankFunc
	LD XWA, XIZ
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR SingleLoadDstMemFunc
	LD XWA, (81F0h)
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, 00610036h
	LD XBC, 01e0003bh
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, (81F0h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A16h
	LDA XHL, XDE + BC
	LD XBC, 01c0000bh
	LD XDE, 0
	LD XHL, (XHL)
	CALL T, XHL
	LD XWA, XIZ
	LD XBC, 01c0000bh
	LD XDE, 0

LABEL_F9106C:
	CALR SingleLoadSrcFunc
	JRL T, LABEL_F90E68

LABEL_F91072:
	LD XWA, (XSP + 004h)
	CP XWA, 0000000ah
	JR NZ, LABEL_F910DF
	CP (89F8h), 004h
	JR Z, LABEL_F910DF
	LD XWA, 00600026h
	LD XBC, 01c00001h
	LD XDE, 5
	CALL ApPostEvent
	LD WA, 0
	CALR InitializeOperationState
	LD XWA, (81F0h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A16h
	LDA XHL, XDE + BC
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	LD XIX, (XHL)
	CALL T, XIX
	LD WA, HL
	LD BC, 1
	CALR LABEL_F8B48E
	LD (7F42h), L
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 00eeh
	CALL LABEL_F994BD
	JRL T, LABEL_F90E68

LABEL_F910DF:
	LD XWA, (XSP + 004h)
	CP XWA, 00000007h
	JR NZ, LABEL_F9115A
	CP (89F8h), 001h
	JR Z, LABEL_F91124
	LD XWA, (81F0h)
	LD XBC, 01e50002h
	LD XDE, 1
	CALL ApPostEvent
	LD XWA, (81F0h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A16h
	LDA XHL, XDE + BC
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F90E68

LABEL_F91124:
	LD XWA, (81F0h)
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, (81F0h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A16h
	LDA XHL, XDE + BC
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F90E68

LABEL_F9115A:
	LD XWA, (81F0h)
	LD XBC, (XSP + 004h)
	CP XBC, 00000008h
	JRL NZ, LABEL_F91208
	CP (89F8h), 001h
	JR NZ, LABEL_F911A0
	LD XBC, 01e50002h
	LD XDE, 2
	CALL ApPostEvent
	LD XWA, (81F0h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A16h
	LDA XHL, XDE + BC
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F90E68

LABEL_F911A0:
	CP (89FAh), 000h
	JR NZ, LABEL_F911D6
	LD XBC, 01e50002h
	LD XDE, 3
	CALL ApPostEvent
	LD XWA, (81F0h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A16h
	LDA XHL, XDE + BC
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F90E68

LABEL_F911D6:
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, (81F0h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A16h
	LDA XHL, XDE + BC
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F90E68

LABEL_F91208:
	LD XBC, (XSP + 004h)
	CP XBC, 00000005h
	JR NZ, LABEL_F91245
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, (81F0h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A16h
	LDA XHL, XDE + BC
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F90E68

LABEL_F91245:
	LD XBC, (XSP + 004h)
	CP XBC, 00000006h
	JRL NZ, LABEL_F90E68
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, (81F0h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A16h
	LDA XHL, XDE + BC
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F90E68

LABEL_F91283:
	LD XHL, 0ffffffffh

LABEL_F91288:
	POP XIZ
	INC 8, XSP
	RET

CmpSingleLoadSrcFunc:
	DEC 4, XSP
	PUSH XIZ
	LD (XSP + 004h), XDE
	LD XIZ, XBC
	CP XIZ, 01e50003h
	JRL Z, LABEL_F9146D
	CP XIZ, 01c00018h
	JR Z, LABEL_F9130B
	CP XIZ, 01c00017h
	JR Z, LABEL_F9130B
	CP XIZ, 01c0000bh
	JR Z, LABEL_F912D6
	CP XIZ, 01e50004h
	JRL NZ, LABEL_F91469
	LD XWA, (XSP + 004h)
	LD (81F4h), XWA
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	JRL T, LABEL_F91469

LABEL_F912D6:
	LD XWA, (81F4h)
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, (81F4h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A2Ah
	LDA XHL, XDE + BC
	LD XBC, XIZ
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F91469

LABEL_F9130B:
	LD XWA, (XSP + 004h)
	CP XWA, 00000005h
	JR NZ, LABEL_F91348
	LD XWA, (81F4h)
	LD XBC, 01e50002h
	LD XDE, 1
	CALL ApPostEvent
	LD XWA, (81F4h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A2Ah
	LDA XHL, XDE + BC
	LD XBC, XIZ
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F91469

LABEL_F91348:
	LD XWA, (XSP + 004h)
	CP XWA, 00000006h
	JR NZ, LABEL_F913C1
	CP (89FAh), 000h
	JR NZ, LABEL_F9138C
	LD XWA, (81F4h)
	LD XBC, 01e50002h
	LD XDE, 3
	CALL ApPostEvent
	LD XWA, (81F4h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A2Ah
	LDA XHL, XDE + BC
	LD XBC, XIZ
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F91469

LABEL_F9138C:
	LD XWA, (81F4h)
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, (81F4h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A2Ah
	LDA XHL, XDE + BC
	LD XBC, XIZ
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F91469

LABEL_F913C1:
	LD XWA, (81F4h)
	LD XBC, (XSP + 004h)
	CP XBC, 00000007h
	JR NZ, LABEL_F91400
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, (81F4h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A2Ah
	LDA XHL, XDE + BC
	LD XBC, XIZ
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JR T, LABEL_F91469

LABEL_F91400:
	LD XBC, (XSP + 004h)
	CP XBC, 00000008h
	JR NZ, LABEL_F91442
	CP (89FAh), 000h
	JR NZ, LABEL_F91442
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, (81F4h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A2Ah
	LDA XHL, XDE + BC
	LD XBC, XIZ
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JR T, LABEL_F91469

LABEL_F91442:
	LD XBC, (XSP + 004h)
	CP XBC, 00000028h
	JR NZ, LABEL_F91469
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A2Ah
	LDA XHL, XDE + BC
	LD XBC, XIZ
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL

LABEL_F91469:
	LD XHL, 0
	JR T, LABEL_F91472

LABEL_F9146D:
	LD XHL, 0ffffffffh

LABEL_F91472:
	POP XIZ
	INC 4, XSP
	RET

CmpSingleLoadDstFunc:
	DEC 8, XSP
	PUSH XIZ
	LD (XSP + 004h), XDE
	LD (XSP + 008h), XBC
	LD XIZ, XWA
	LD XWA, (XSP + 008h)
	CP XWA, 01e50003h
	JRL Z, LABEL_F91761
	CP XWA, 01c00018h
	JRL Z, LABEL_F9153A
	CP XWA, 01c00017h
	JRL Z, LABEL_F9153A
	CP XWA, 01c0000bh
	JR Z, LABEL_F914C8
	CP XWA, 01e50004h
	JRL NZ, LABEL_F9175D
	LD XWA, (XSP + 004h)
	LD (81F8h), XWA
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	JRL T, LABEL_F9175D

LABEL_F914C8:
	LD XWA, XIZ
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	CALR SingleLoadSrcMemFunc
	LD XWA, XIZ
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	CALR SingleLoadSrcBankFunc
	LD XWA, XIZ
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	CALR SingleLoadDstMemFunc
	LD XWA, XIZ
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	CALR SingleLoadDstBankFunc
	LD XWA, (81F8h)
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, 0061007eh
	LD XBC, 01e0003bh
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, (81F8h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A3Eh
	LDA XHL, XDE + BC
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F9175D

LABEL_F9153A:
	LD XWA, (XSP + 004h)
	CP XWA, 00000003h
	JR NZ, LABEL_F915BF
	LD XWA, (XSP + 008h)
	CP XWA, 01c00017h
	SCC Z, A
	LD (89FAh), A
	LD XWA, XIZ
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR SingleLoadSrcMemFunc
	LD XWA, XIZ
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR SingleLoadDstMemFunc
	LD XWA, (81F8h)
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, 0061007eh
	LD XBC, 01e0003bh
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, (81F8h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A3Eh
	LDA XHL, XDE + BC
	LD XBC, 01c0000bh
	LD XDE, 0
	LD XHL, (XHL)
	CALL T, XHL
	LD XWA, XIZ
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR CmpSingleLoadSrcFunc
	JRL T, LABEL_F9175D

LABEL_F915BF:
	LD XWA, (XSP + 004h)
	CP XWA, 0000000ah
	JR NZ, LABEL_F9162C
	CP (89F8h), 004h
	JR Z, LABEL_F9162C
	LD XWA, 00600026h
	LD XBC, 01c00001h
	LD XDE, 5
	CALL ApPostEvent
	LD WA, 0
	CALR InitializeOperationState
	LD XWA, (81F8h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A3Eh
	LDA XHL, XDE + BC
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	LD XIX, (XHL)
	CALL T, XIX
	LD WA, HL
	LD BC, 1
	CALR LABEL_F8B48E
	LD (7F42h), L
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 00eeh
	CALL LABEL_F994BD
	JRL T, LABEL_F9175D

LABEL_F9162C:
	LD XWA, (XSP + 004h)
	CP XWA, 00000007h
	JR NZ, LABEL_F9166A
	LD XWA, (81F8h)
	LD XBC, 01e50002h
	LD XDE, 1
	CALL ApPostEvent
	LD XWA, (81F8h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A3Eh
	LDA XHL, XDE + BC
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F9175D

LABEL_F9166A:
	LD XWA, (81F8h)
	LD XBC, (XSP + 004h)
	CP XBC, 00000008h
	JR NZ, LABEL_F916E0
	CP (89FAh), 000h
	JR NZ, LABEL_F916AF
	LD XBC, 01e50002h
	LD XDE, 3
	CALL ApPostEvent
	LD XWA, (81F8h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A3Eh
	LDA XHL, XDE + BC
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JRL T, LABEL_F9175D

LABEL_F916AF:
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, (81F8h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A3Eh
	LDA XHL, XDE + BC
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JR T, LABEL_F9175D

LABEL_F916E0:
	LD XBC, (XSP + 004h)
	CP XBC, 00000005h
	JR NZ, LABEL_F9171C
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, (81F8h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A3Eh
	LDA XHL, XDE + BC
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL
	JR T, LABEL_F9175D

LABEL_F9171C:
	LD XBC, (XSP + 004h)
	CP XBC, 00000006h
	JR NZ, LABEL_F9175D
	CP (89FAh), 000h
	JR NZ, LABEL_F9175D
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	CALL ApPostEvent
	LD XWA, (81F8h)
	LD C, (89F8h)
	EXTZ BC
	SLA 002h, BC
	LDA XDE, 0EA0A3Eh
	LDA XHL, XDE + BC
	LD XBC, (XSP + 008h)
	LD XDE, (XSP + 004h)
	LD XHL, (XHL)
	CALL T, XHL

LABEL_F9175D:
	LD XHL, 0
	JR T, LABEL_F91766

LABEL_F91761:
	LD XHL, 0ffffffffh

LABEL_F91766:
	POP XIZ
	INC 8, XSP
	RET

CmpSingleLoadFileFunc:
	DEC 4, XSP
	PUSH XIZ
	LD (XSP + 004h), XWA
	CP XBC, 01c00018h
	JRL Z, LABEL_F91800
	CP XBC, 01c00017h
	JR Z, LABEL_F91800
	CP XBC, 01c0000bh
	JR Z, LABEL_F917B8
	CP XBC, 01e50004h
	JRL NZ, LABEL_F918A8
	LD (81FCh), XDE
	CALL GetCurrentFileIndex
	LD (8200h), HL
	CP HL, 0
	JR GE, LABEL_F917A8
	LDW (8200h), 0000h

LABEL_F917A8:
	LD XWA, (81FCh)
	LD XBC, 01e50002h
	LD XDE, 0ffffffffh
	JR T, LABEL_F917F9

LABEL_F917B8:
	LD (8870h), 000h
	CP (89F8h), 002h
	JR NZ, LABEL_F917D0
	LD WA, (8200h)
	CALL LABEL_F89623
	LD XIZ, XHL
	JR T, LABEL_F917D5

LABEL_F917D0:
	LDA XIZ, 0EA0A52h

LABEL_F917D5:
	LDA XWA, 8871h
	LD DE, (8200h)
	INC 1, DE
	PUSHW 0006h
	PUSHW 0000h
	LD XBC, XIZ
	CALL LABEL_F891DD
	LD XWA, (81FCh)
	LD XBC, 01c0000fh
	LD XDE, 00008870h

LABEL_F917F9:
	CALL ApPostEvent
	JRL T, LABEL_F918A8

LABEL_F91800:
	LD WA, (8200h)
	LD HL, WA
	OR XDE, XDE
	JR NZ, LABEL_F91818
	LD BC, WA
	INC 1, BC
	CP BC, 0014h
	JR GE, LABEL_F9182A
	INC 1, WA
	JR T, LABEL_F91826

LABEL_F91818:
	CP XDE, 00000001h
	JR NZ, LABEL_F9182A
	CP WA, 0
	JR LE, LABEL_F9182A
	DEC 1, WA

LABEL_F91826:
	LD (8200h), WA

LABEL_F9182A:
	LD WA, (8200h)
	CP WA, HL
	JR Z, LABEL_F918A8
	CALL NotifyUIOfSelectionChange
	LD (8870h), 000h
	LDA XIZ, 0EA0A52h
	LD (89F8h), 004h
	LD WA, 3
	CALL LABEL_F893D1
	CP L, 0
	JR Z, LABEL_F91866
	CALL LABEL_F872E5
	CP HL, 0
	JR Z, LABEL_F91866
	LD (89F8h), 002h
	LD WA, (8200h)
	CALL LABEL_F89623
	LD XIZ, XHL

LABEL_F91866:
	LDA XWA, 8871h
	LD DE, (8200h)
	INC 1, DE
	PUSHW 0006h
	PUSHW 0000h
	LD XBC, XIZ
	CALL LABEL_F891DD
	LD XWA, (81FCh)
	LD XBC, 01c0000fh
	LD XDE, 00008870h
	CALL ApPostEvent
	LD XWA, (XSP + 004h)
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR CmpSingleLoadSrcFunc
	LD XWA, (XSP + 004h)
	LD XBC, 01c0000bh
	LD XDE, 0
	CALR CmpSingleLoadDstFunc

LABEL_F918A8:
	LD XHL, 0
	POP XIZ
	INC 4, XSP
	RET

FmmCmpSingleLoadFunc:
	CP XBC, 01c00013h
	JRL NZ, LABEL_F919E0
	CP XDE, 00000003h
	JRL Z, LABEL_F919DD
	CP XDE, 00000002h
	JRL NZ, LABEL_F919E0
	LD WA, 1
	CALR InitializeOperationState
	LD XWA, 0061004ah
	LD XBC, 01e0009ch
	LD XDE, 1
	CALL ApPostEvent
	LD XWA, 00600026h
	LD XBC, 01c00001h
	LD XDE, 5
	CALL ApPostEvent
	CPW (8500h), 0000h
	JR GE, LABEL_F91903
	CALL GetDiskSizeInfo
	EXTZ HL
	LD (8500h), HL
	CALR SignalProgressUpdate

LABEL_F91903:
	LD WA, (8500h)
	CP WA, 1
	JRL Z, LABEL_F919B5
	CP WA, 0
	JRL Z, LABEL_F9199C
	CP WA, 5
	JR Z, LABEL_F9197B
	CPW (8502h), 0000h
	JR GE, LABEL_F91930
	CALL GetEncodedFileSizeData
	LD (8502h), HL
	CALL LABEL_F8958D
	CALL GetEncodedFreeSpaceData
	CALR SignalProgressUpdate

LABEL_F91930:
	LD (89F8h), 004h
	LD WA, 3
	CALL LABEL_F893D1
	CP L, 0
	JR Z, LABEL_F9194F
	CALL LABEL_F872E5
	CP HL, 0
	JR Z, LABEL_F9194C
	LD (89F8h), 002h

LABEL_F9194C:
	CALR SignalProgressUpdate

LABEL_F9194F:
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD XWA, 0ffffffffh
	LD XBC, 01c0000ah
	LD XDE, 0
	CALL ApPostEvent
	LD (89FEh), 000h
	LD (8A06h), 000h
	JR T, LABEL_F919E0

LABEL_F9197B:
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 00b0h
	CALL UI_PostModeChangeEvent
	LD (7F42h), 000h
	LD WA, 00eeh
	JR T, LABEL_F919D7

LABEL_F9199C:
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 007dh
	CALL UI_PostModeChangeEvent
	JR T, LABEL_F919E0

LABEL_F919B5:
	CALR ResetProgressIndication
	LD XWA, 00600026h
	LD XBC, 01c00002h
	LD XDE, 0
	CALL ApPostEvent
	LD WA, 00b0h
	CALL UI_PostModeChangeEvent
	LD (7F42h), 002h
	LD WA, 00eeh

LABEL_F919D7:
	CALL LABEL_F994BD
	JR T, LABEL_F919E0

LABEL_F919DD:
	CALR CancelOperationCleanup

LABEL_F919E0:
	LD XHL, 0
	RET

LABEL_F919E3:
	DEC 2, XSP
	PUSH XIZ
	LD HL, BC
	LD (XSP + 004h), WA
	LDA XBC, 0AB000h
	LD WA, (XSP + 004h)
	EXTZ XWA
	SLL 11, XWA
	ADD XBC, XWA
	LDA XBC, XBC + 0100h
	LD WA, (XSP + 004h)
	MULW_WA 0015h
	LDA XIX, 8202h
	LD IZ, WA
	EXTZ XIZ
	ADD XIZ, XIX
	LD (XIZ+), L
	CP E, 0
	JR Z, LABEL_F91A39
	CPW (XSP + 004h), 0009h
	JR NZ, LABEL_F91A27
	LD (XIZ+), 031h
	LD (XIZ), 030h
	JR T, LABEL_F91A33

LABEL_F91A27:
	LD (XIZ+), 020h
	LD WA, (XSP + 004h)
	ADD A, 031h
	LD (XIZ), A

LABEL_F91A33:
	INC 1, XIZ
	LD (XIZ+), 03ah

LABEL_F91A39:
	LD XWA, XIZ
	LD DE, 0010h
	CALL LABEL_F890F2
	LD (XIZ + 010h), 000h
	LD WA, (XSP + 004h)
	MULW_WA 0015h
	LDA XBC, 8202h
	EXTZ XWA
	ADD XWA, XBC
	LD XHL, XWA
	POP XIZ
	INC 2, XSP
	RET

