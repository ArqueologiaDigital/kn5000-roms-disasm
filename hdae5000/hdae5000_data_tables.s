HDAE5000_UI_Config:	; 0x29BFE0
	; UI configuration strings
	.asciz "adraw"
	.asciz "auto_inc"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "dial"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "sel_num"
	.asciz "row"
	.asciz "column"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "str_adr"
	.asciz "main_func"
	.asciz "fontcolor"
	.asciz "font"
	.zero 3
	.asciz "fontcolor"
	.asciz "color"
	.zero 6
	.asciz "func"
	.zero 15
	.asciz "infocolor"
	.asciz "infofont"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "reversecolor"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "fontcolor"
	.asciz "font"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "pEnable"
	.zero 2
	.asciz "sel_pos"
	.asciz "sel_num"
	.asciz "dial"
	.byte 0x00

HDAE5000_RECORD_TABLE:	; 0x29C0AA
	; Record/entry data table -- CONFIRMED DATA, not code.
; ============================================================================
; HDAE5000_RECORD_TABLE  (0x29C0AA - 0x29D97D, 6,356 bytes)
; ============================================================================
; This span was previously disassembled as ~6,150 lines of TLCS-900 instruction
; mnemonics.  It is DATA.  The only reference to this address
; (hd-ae5000_v2_06i.s:312, `lda_24 xwa, (0x29c0aa)`) loads it as an ADDRESS for the
; "DISK MENU / UI" handler registration (see the Handler Registration Table just
; above HDAE5000_Handler_Registration in hd-ae5000_v2_06i.s); there is no call or
; jump site anywhere in the tree.  hdae5000_init_data.s:23 already documents the
; record layout below from the RAM-image side; this header confirms it against the
; raw ROM bytes and extends it to the full 6,356-byte span.
;
; DECOMPOSITION (confirmed byte-exact, see EVIDENCE below):
;   0x29C0AA-0x29C1E1   312 B   the 13 x 24-byte record array itself
;   0x29C1E2-0x29D8A9 5,832 B   all-zero reserved gap (verified, every byte 0x00)
;   0x29D8AA-0x29D97D   212 B   packed pool of the 26 NUL-terminated strings the
;                              records above point at (13 class names + 13
;                              parameter type-signature strings, in reverse record
;                              order, several signatures empty)
;
; RECORD LAYOUT (24 bytes), matching hdae5000_init_data.s:23-28:
;   +0x00  .long  ProcPtr        class procedure entry point (ROM); matches an
;                                already-named *Proc routine in this tree for all
;                                13 records (e.g. record 7 -> HDAE5000_TtlScreenR3Proc
;                                at 0x280645, byte-identical address)
;   +0x04  .short Field_04       varies per record (0x11-0x6a); UNDECODED
;   +0x06  .short Field_06       0x0160 in all 13 records; UNDECODED.  [INFERENCE]
;                                matches the high half of 0x01600004, the class id
;                                (ClassProc) this whole table is registered under in
;                                HDAE5000_Handler_Registration -- not traced further
;   +0x08  .short Field_08       varies per record (0x1a-0x3c); UNDECODED
;   +0x0A  .short Field_0A       varies per record (0x00-0x20); UNDECODED
;   +0x0C  .long  NamePtr        -> class name string, in the pool below
;   +0x10  .long  SigPtr         -> parameter type-signature string (may be empty);
;                                signature length == parameter count, matching
;                                hdae5000_init_data.s:26-28 exactly for all 13
;                                records (11,2,0,0,1,0,0,0,0,0,0,6,3)
;   +0x14  .long  ParamListPtr   RAM address of this class's parameter-name list,
;                                confirmed against hdae5000_init_data.s's own table:
;                                record 0's 0x23975A == the documented
;                                "0x2f96e2 -> 0x23975a, 13 lists" first entry
;
; EVIDENCE.  Every claim above is checked by the committed probe
; hdae5000/tools/verify_record_table.py, run from the repo root; it reads
; original_ROMs/hd-ae5000_v2_06i.ic4 at load base 0x280000 and nothing else:
;  * all 13 ProcPtr values land exactly on an already-named *Proc label's address
;  * the reserved gap (0x29C1E2-0x29D8A9) is 5,832 bytes of 0x00, no exception
;  * the string pool (0x29D8AA-0x29D97D) decomposes into exactly 26 NUL-terminated
;    runs with zero leftover bytes, and every NamePtr/SigPtr in the record array
;    resolves to the start of one of those runs
;  * SigPtr string length equals the parameter count already published in
;    hdae5000_init_data.s, for all 13 records with no exception
; ============================================================================

HDAE5000_Record_SelectList:	; 0x29C0AA  class 'SelectList'
	.long 0x2807d9                     ; +0x00 ProcPtr (== named routine in this tree)
	.short 0x11, 0x160                 ; +0x04 Field_04, +0x06 Field_06 (UNDECODED, see header)
	.short 0x3c, 0x20                 ; +0x08 Field_08, +0x0A Field_0A (UNDECODED, see header)
	.long 0x29d972                     ; +0x0C NamePtr  -> 'SelectList'
	.long 0x29d966                     ; +0x10 SigPtr   -> 'c^ksAAnGGmA' (11 params)
	.long 0x23975a                     ; +0x14 ParamListPtr (RAM)

HDAE5000_Record_DbMemoCl:	; 0x29C0C2  class 'DbMemoCl'
	.long 0x28122a                     ; +0x00 ProcPtr (== named routine in this tree)
	.short 0x46, 0x160                 ; +0x04 Field_04, +0x06 Field_06 (UNDECODED, see header)
	.short 0x1a, 0x4                 ; +0x08 Field_08, +0x0A Field_0A (UNDECODED, see header)
	.long 0x29d95c                     ; +0x0C NamePtr  -> 'DbMemoCl'
	.long 0x29d958                     ; +0x10 SigPtr   -> '^^' (2 params)
	.long 0x23978a                     ; +0x14 ParamListPtr (RAM)

HDAE5000_Record_TtlScreenR:	; 0x29C0DA  class 'TtlScreenR'
	.long 0x280489                     ; +0x00 ProcPtr (== named routine in this tree)
	.short 0x34, 0x160                 ; +0x04 Field_04, +0x06 Field_06 (UNDECODED, see header)
	.short 0x2a, 0x0                 ; +0x08 Field_08, +0x0A Field_0A (UNDECODED, see header)
	.long 0x29d94c                     ; +0x0C NamePtr  -> 'TtlScreenR'
	.long 0x29d94a                     ; +0x10 SigPtr   -> '' (0 params)
	.long 0x239796                     ; +0x14 ParamListPtr (RAM)

HDAE5000_Record_AcHddNamingWindow:	; 0x29C0F2  class 'AcHddNamingWindow'
	.long 0x281411                     ; +0x00 ProcPtr (== named routine in this tree)
	.short 0x35, 0x160                 ; +0x04 Field_04, +0x06 Field_06 (UNDECODED, see header)
	.short 0x24, 0x0                 ; +0x08 Field_08, +0x0A Field_0A (UNDECODED, see header)
	.long 0x29d938                     ; +0x0C NamePtr  -> 'AcHddNamingWindow'
	.long 0x29d936                     ; +0x10 SigPtr   -> '' (0 params)
	.long 0x23979a                     ; +0x14 ParamListPtr (RAM)

HDAE5000_Record_IvHddNaming:	; 0x29C10A  class 'IvHddNaming'
	.long 0x282681                     ; +0x00 ProcPtr (== named routine in this tree)
	.short 0x27, 0x160                 ; +0x04 Field_04, +0x06 Field_06 (UNDECODED, see header)
	.short 0x1a, 0x4                 ; +0x08 Field_08, +0x0A Field_0A (UNDECODED, see header)
	.long 0x29d92a                     ; +0x0C NamePtr  -> 'IvHddNaming'
	.long 0x29d928                     ; +0x10 SigPtr   -> 'j' (1 params)
	.long 0x23979e                     ; +0x14 ParamListPtr (RAM)

HDAE5000_Record_HDTitleMenu:	; 0x29C122  class 'HDTitleMenu'
	.long 0x2827a8                     ; +0x00 ProcPtr (== named routine in this tree)
	.short 0x1d, 0x160                 ; +0x04 Field_04, +0x06 Field_06 (UNDECODED, see header)
	.short 0x36, 0x0                 ; +0x08 Field_08, +0x0A Field_0A (UNDECODED, see header)
	.long 0x29d91c                     ; +0x0C NamePtr  -> 'HDTitleMenu'
	.long 0x29d91a                     ; +0x10 SigPtr   -> '' (0 params)
	.long 0x2397a6                     ; +0x14 ParamListPtr (RAM)

HDAE5000_Record_TtlScreenR2:	; 0x29C13A  class 'TtlScreenR2'
	.long 0x280567                     ; +0x00 ProcPtr (== named routine in this tree)
	.short 0x34, 0x160                 ; +0x04 Field_04, +0x06 Field_06 (UNDECODED, see header)
	.short 0x2a, 0x0                 ; +0x08 Field_08, +0x0A Field_0A (UNDECODED, see header)
	.long 0x29d90e                     ; +0x0C NamePtr  -> 'TtlScreenR2'
	.long 0x29d90c                     ; +0x10 SigPtr   -> '' (0 params)
	.long 0x2397aa                     ; +0x14 ParamListPtr (RAM)

HDAE5000_Record_TtlScreenR3:	; 0x29C152  class 'TtlScreenR3'
	.long 0x280645                     ; +0x00 ProcPtr (== named routine in this tree)
	.short 0x34, 0x160                 ; +0x04 Field_04, +0x06 Field_06 (UNDECODED, see header)
	.short 0x2a, 0x0                 ; +0x08 Field_08, +0x0A Field_0A (UNDECODED, see header)
	.long 0x29d900                     ; +0x0C NamePtr  -> 'TtlScreenR3'
	.long 0x29d8fe                     ; +0x10 SigPtr   -> '' (0 params)
	.long 0x2397ae                     ; +0x14 ParamListPtr (RAM)

HDAE5000_Record_AcWindowPage1:	; 0x29C16A  class 'AcWindowPage1'
	.long 0x28043c                     ; +0x00 ProcPtr (== named routine in this tree)
	.short 0x25, 0x160                 ; +0x04 Field_04, +0x06 Field_06 (UNDECODED, see header)
	.short 0x24, 0x0                 ; +0x08 Field_08, +0x0A Field_0A (UNDECODED, see header)
	.long 0x29d8f0                     ; +0x0C NamePtr  -> 'AcWindowPage1'
	.long 0x29d8ee                     ; +0x10 SigPtr   -> '' (0 params)
	.long 0x2397b2                     ; +0x14 ParamListPtr (RAM)

HDAE5000_Record_IvScreenR2:	; 0x29C182  class 'IvScreenR2'
	.long 0x280723                     ; +0x00 ProcPtr (== named routine in this tree)
	.short 0x6a, 0x160                 ; +0x04 Field_04, +0x06 Field_06 (UNDECODED, see header)
	.short 0x22, 0x0                 ; +0x08 Field_08, +0x0A Field_0A (UNDECODED, see header)
	.long 0x29d8e2                     ; +0x0C NamePtr  -> 'IvScreenR2'
	.long 0x29d8e0                     ; +0x10 SigPtr   -> '' (0 params)
	.long 0x2397b6                     ; +0x14 ParamListPtr (RAM)

HDAE5000_Record_AcLanguageText1:	; 0x29C19A  class 'AcLanguageText1'
	.long 0x28b554                     ; +0x00 ProcPtr (== named routine in this tree)
	.short 0x66, 0x160                 ; +0x04 Field_04, +0x06 Field_06 (UNDECODED, see header)
	.short 0x2a, 0x0                 ; +0x08 Field_08, +0x0A Field_0A (UNDECODED, see header)
	.long 0x29d8d0                     ; +0x0C NamePtr  -> 'AcLanguageText1'
	.long 0x29d8ce                     ; +0x10 SigPtr   -> '' (0 params)
	.long 0x2397ba                     ; +0x14 ParamListPtr (RAM)

HDAE5000_Record_LyricBox:	; 0x29C1B2  class 'LyricBox'
	.long 0x28cd08                     ; +0x00 ProcPtr (== named routine in this tree)
	.short 0x11, 0x160                 ; +0x04 Field_04, +0x06 Field_06 (UNDECODED, see header)
	.short 0x2e, 0x12                 ; +0x08 Field_08, +0x0A Field_0A (UNDECODED, see header)
	.long 0x29d8c4                     ; +0x0C NamePtr  -> 'LyricBox'
	.long 0x29d8bc                     ; +0x10 SigPtr   -> 'mc^^c^' (6 params)
	.long 0x2397be                     ; +0x14 ParamListPtr (RAM)

HDAE5000_Record_FDFileSelect:	; 0x29C1CA  class 'FDFileSelect'
	.long 0x28e61b                     ; +0x00 ProcPtr (== named routine in this tree)
	.short 0x27, 0x160                 ; +0x04 Field_04, +0x06 Field_06 (UNDECODED, see header)
	.short 0x20, 0xa                 ; +0x08 Field_08, +0x0A Field_0A (UNDECODED, see header)
	.long 0x29d8ae                     ; +0x0C NamePtr  -> 'FDFileSelect'
	.long 0x29d8aa                     ; +0x10 SigPtr   -> 'Gnn' (3 params)
	.long 0x2397da                     ; +0x14 ParamListPtr (RAM)

; ---------------------------------------------------------------------------
; reserved gap: 5832 bytes, all 0x00 (verified above)
; ---------------------------------------------------------------------------
.zero 5832

; ---------------------------------------------------------------------------
; string pool referenced by NamePtr/SigPtr above, in reverse record order
; ---------------------------------------------------------------------------
	.asciz "Gnn"			; 0x29D8AA
	.asciz "FDFileSelect"			; 0x29D8AE
	.zero 1			; 0x29D8BB (unreferenced pad)
	.asciz "mc^^c^"			; 0x29D8BC
	.zero 1			; 0x29D8C3 (unreferenced pad)
	.asciz "LyricBox"			; 0x29D8C4
	.zero 1			; 0x29D8CD (unreferenced pad)
	.byte 0x00			; 0x29D8CE (SigPtr target of AcLanguageText1, empty signature)
	.zero 1			; 0x29D8CF (unreferenced pad)
	.asciz "AcLanguageText1"			; 0x29D8D0
	.byte 0x00			; 0x29D8E0 (SigPtr target of IvScreenR2, empty signature)
	.zero 1			; 0x29D8E1 (unreferenced pad)
	.asciz "IvScreenR2"			; 0x29D8E2
	.zero 1			; 0x29D8ED (unreferenced pad)
	.byte 0x00			; 0x29D8EE (SigPtr target of AcWindowPage1, empty signature)
	.zero 1			; 0x29D8EF (unreferenced pad)
	.asciz "AcWindowPage1"			; 0x29D8F0
	.byte 0x00			; 0x29D8FE (SigPtr target of TtlScreenR3, empty signature)
	.zero 1			; 0x29D8FF (unreferenced pad)
	.asciz "TtlScreenR3"			; 0x29D900
	.byte 0x00			; 0x29D90C (SigPtr target of TtlScreenR2, empty signature)
	.zero 1			; 0x29D90D (unreferenced pad)
	.asciz "TtlScreenR2"			; 0x29D90E
	.byte 0x00			; 0x29D91A (SigPtr target of HDTitleMenu, empty signature)
	.zero 1			; 0x29D91B (unreferenced pad)
	.asciz "HDTitleMenu"			; 0x29D91C
	.asciz "j"			; 0x29D928
	.asciz "IvHddNaming"			; 0x29D92A
	.byte 0x00			; 0x29D936 (SigPtr target of AcHddNamingWindow, empty signature)
	.zero 1			; 0x29D937 (unreferenced pad)
	.asciz "AcHddNamingWindow"			; 0x29D938
	.byte 0x00			; 0x29D94A (SigPtr target of TtlScreenR, empty signature)
	.zero 1			; 0x29D94B (unreferenced pad)
	.asciz "TtlScreenR"			; 0x29D94C
	.zero 1			; 0x29D957 (unreferenced pad)
	.asciz "^^"			; 0x29D958
	.zero 1			; 0x29D95B (unreferenced pad)
	.asciz "DbMemoCl"			; 0x29D95C
	.zero 1			; 0x29D965 (unreferenced pad)
	.asciz "c^ksAAnGGmA"			; 0x29D966
	.asciz "SelectList"			; 0x29D972
	.zero 1			; 0x29D97D (unreferenced pad)
HDAE5000_RECORD_COUNT:	; 0x29D97E
	; Record count data
	.byte 0x0d, 0x00                       ; u16 count = 13 (LE); matches HDAE5000_RECORD_TABLE's 13
	                                       ; records and the 13 UI class procedures/names
	                                       ; hdae5000_init_data.s documents at 0x2f97fa/0x2f9832.
	                                       ; hd-ae5000_v2_06i.s:310 `ldw_da xwa, (0x29d97e)` reads
	                                       ; this exact word -- NOT alignment padding, real data;
	                                       ; it also happens to word-align the string pool below.
	.asciz "EV_DrawFDText"
	.asciz "EV_InitFDFileSelect"
	.asciz "EV_Scrollline"
	.asciz "EV_Drawsyllable"
	.asciz "EV_Alldraw"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "EV_Initlyrics"
	.asciz "EV_SETPOSITION"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "EV_BEATMESSAGE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "EV_TICKS"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "EV_INITLYRICPARAM"
	.asciz "EV_TimerBack"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "EV_AfterLoad"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "EV_SeqStop"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MT_FdSaveLyric"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MT_FdLoadLyric"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MT_FdInfo"
	.asciz "MT_FdFreshUp"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MT_SelectDelFile"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MT_SelectDEL"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MT_LOOP"
	.asciz "MT_SetStrAdr"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MT_SelectAll"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MT_SelectSAVE"
	.asciz "MT_SelectOK2"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MT_SelectOK"
	.asciz "MT_AckSelNum"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MT_ReqSelNum"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MT_SetSelNum"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MT_ChangeSelNum"
	.asciz "MT_UnderFlow"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MT_OverFlow"
	.zero 2
	.asciz "FDFileSelectProc"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LyricBoxProc"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "AcLanguageText1Proc"
	.asciz "IvScreenR2Proc"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "AcWindowPage1Proc"
	.asciz "TtlScreenR3Proc"
	.asciz "TtlScreenR2Proc"
	.asciz "HDTitleMenuProc"
	.asciz "IvHddNamingProc"
	.asciz "AcHddNamingWindowProc"
	.asciz "TtlScreenRProc"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "DbMemoClProc"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SelectListProc"
	.balign 2, 0x00                       ; word-align pad to the pool boundary 0x29DC12 (see the
	                                       ; "HD-AE5000 UI OBJECT DESCRIPTOR POOL" header just below)

; =============================================================================
; HD-AE5000 UI OBJECT DESCRIPTOR POOL  (0x29DC12 - 0x2A5D2B, 33,050 bytes)
; =============================================================================
; ONE array of 769 variable-length records.  It is not five tables.  The five
; labels that cut it up - HDAE5000_UI_Descriptors just below, and
; _UI_Page_Titles / _Panel_Save_UI / _Credits / _Demo_Data further down - each
; land 0x02 to 0x3A bytes INSIDE a record, and the last four land on that
; record's inline caption string.  All five are kept as MISNOMERS for
; cross-reference (they are the names the ASL mirror,
; symbols/hdae5000_symbols_reference.txt and seven .set bases in
; hdae5000_init_data.s already use); see the retraction note at each one.
; (Since 2026-09-25 the five are `.set` symbols defined right after the
; record they point into, so nothing cuts the pool any more.)
;
; TYPED RECORDS (2026-09-25).  Everything from the "POOL START" note to the
; end of the pool is GENERATED by scripts/generators/gen_hdae5000_ui_pool.py
; (`--write`), which refuses unless its byte model of the text equals the
; ROM; edit this header or the generator, not the records.  Each record is
; `HdaeUiObj_NNN` (NNN = its index in HDAE5000_UiObject_PtrTable), preceded by
; a two-line note (resource name, class, length, parent, box) and typed as:
;   .long class id / .short parent, first child, next, previous (indices,
;   0xffff = none) / .short attribute word / .short x1, y1, x2, y2 /
;   class body as .short words (UNDECODED), except
;     - the 329 caption slots -> `.long HdaeUiObj_NNN_CapXX`, the label on
;       the caption string at the end of the same record, and
;     - 318 "RAM address" slots: body offsets where EVERY record of the
;       class holds a value in 0x200000-0x23FFFF (e.g. +0x1E of all 24
;       016A:0002 records, +0x26 of all 16 0160:0041 records) -> .long;
;   captions -> .asciz, each word-aligned with at most one 0x00 pad.
; Corroboration that the 0x0160 classes are the host's widget types: the
; KN5000 main CPU's widget records start with the same four bytes
; `TT 00 60 01` (naka_header in v10/maincpu/shared/macros.s, i.e. the .long
; 0x016000TT here), and for type 0x2B the main CPU's naka_label_t
; (v10/maincpu/ui_widgets/naka_types.h) puts its string pointer at +22 =
; +0x16 -- exactly the caption slot of all 97 HDAE records of class
; 0160:002B.  The body fields otherwise stay undecoded: naka_types.h names
; the words at +6/+8/+10 differently from type to type, and none of its
; orders is the parent / first child / next / previous order proven below
; for this pool, so its layouts are not imported here.
;
; BOUNDARIES.  Record i begins at HDAE5000_UiObject_PtrTable[i] (0x2A5D2C) and
; ends where the next pool pointer begins; the 769th ends at 0x2A5D2C itself,
; so the pool is exactly the gap between the class-name strings above and that
; table, and the 769 lengths sum to exactly 33,050 bytes with nothing over.
; Those 769 addresses are the ONLY legal places for a label inside this pool.
; The pointer table has 789 entries plus a NULL; the other 20 objects keep
; their descriptor in sub-CPU work RAM at 0x239CC4-0x239FD1, initialised from
; HDAE5000_WindowGeometry_Init (ROM 0x2F9C4C) in this same record format.
;
; STRIDE.  There is none.  Lengths run 22..82 bytes in 26 distinct values, all
; even (42 B x178, 26 B x125, 40 B x105, 36 B x58, 60 B x46, 38 B x39,
; 44 B x38).  A record is a fixed 22-byte header, a class-specific body whose
; length is constant per class, and an optional inline caption arena:
;
;   +0x00  .long   class id.  High half 0x016A = a class defined by THIS ROM,
;                  low half = index into HDAE5000_ClassName_Table (0x2F9832).
;                  [INFERENCE] high half 0x0160 = a class of the host KN5000
;                  widget library - this ROM carries no name table for it, and
;                  its 29 low halves (up to 0x0069) cannot index the 13-entry
;                  ClassName_Table.  41 distinct ids: 12 of 0x016A, 29 of 0x0160.
;   +0x04  .short  parent object index,           or 0xFFFF
;   +0x06  .short  first-child object index,      or 0xFFFF
;   +0x08  .short  next-sibling object index,     or 0xFFFF
;   +0x0A  .short  previous-sibling object index, or 0xFFFF
;   +0x0C  .short  0x0008 (622 records) / 0x000A (62) / 0x0018 (85), constant
;                  per class.  NOT decoded; [INFERENCE] an object-kind or
;                  attribute word - no code path was traced to it.
;   +0x0E  .short  x1  \
;   +0x10  .short  y1   |  bounding box, absolute screen pixels; the whole
;   +0x12  .short  x2   |  pool fits inside 0,0 - 321,239
;   +0x14  .short  y2  /
;   +0x16  ...     class-specific body, constant length per class, UNDECODED
;   tail           inline NUL-terminated captions for the classes that have
;                  caption slots, word-aligned with at most one 0x00 pad byte
;
; F below is the 22-byte header plus the class body, i.e. the record length
; before the caption arena starts.
;
;   class       n    F  captions      class       n    F  captions
;   0160:0010    1   22  -            0160:0012   11   36  -
;   0160:001B   50   58  +0x1C        0160:001C    1   42  -
;   0160:001F   77   40  -            0160:0020   11   44  -
;   0160:0022   19   42  -            0160:0026    4   40  +0x1E,+0x1A
;   0160:0028    8   28  -            0160:0029   10   26  -  (see note 1)
;   0160:002B   97   32  +0x16        0160:002D    3   26  -
;   0160:002E   37   26  -            0160:0030    6   40  +0x16
;   0160:0033    1   34  -            0160:0035   13   36  -
;   0160:0036   43   40  +0x1A        0160:0037   16   38  +0x1A
;   0160:003D    2   50  +0x2A        0160:003E   25   44  +0x28
;   0160:003F   16   46  +0x2A        0160:0041   16   54  +0x2A
;   0160:0046    2   22  -            0160:0049   34   26  -
;   0160:004B    2   36  -            0160:004C    1   64  -  (see note 2)
;   0160:004D    4   26  -            0160:0052   27   26  -
;   0160:0069    9   26  -            016A:0000   31   60  -
;   016A:0001    1   26  -            016A:0002   24   42  +0x22
;   016A:0003    1   36  -            016A:0004    1   26  -
;   016A:0006   25   42  +0x22        016A:0007    1   42  +0x22
;   016A:0008    4   36  -            016A:0009   11   34  -
;   016A:000A  122   42  -            016A:000B    1   46  -
;   016A:000C    1   32  -
;
; EVIDENCE.  Every number in this block is printed by the committed probe
; analysis/wave7-probes/verify_hdae5000_ui_pool.py, run from the repo root; it
; reads original_ROMs/hd-ae5000_v2_06i.ic4 at load base 0x280000 and nothing
; else.
;  * Link fields, over the pairs whose both ends are ROM descriptors: next/prev
;    symmetric 498/498, and a first child's parent is its owner 173/173, with no
;    exception.  CONTROL: the same four .shorts read at every other offset from
;    +0x00 to +0x16 collapse - but not independently, because sliding the
;    quartet by 4 bytes re-reads the same pair under different names, which is
;    why +0x08 still scores 498/498 on "child/parent" and +0x00 scores 173/679
;    on "next/prev".  +0x04 is the only offset where BOTH tests pass on their
;    full populations.
;  * 78 records have parent == 0xFFFF.  77 of them are named in
;    HDAE5000_UiObjectName_PtrTable (HDDMENU, SETUPS_TOOLS, SELECT_FILE,
;    SELECT_DIR, FD_FILE_SELECT, HARD_TEST, PC_DATA_LINK, LOAD_BY_NUM, ...);
;    object #385 is not.  Root-ness is not the same as named-ness: 82 named
;    objects are NOT roots.
;  * The bounding box satisfies x1<=x2<=321 and y1<=y2<=239 for 769/769 records
;    at +0x0E and at NO other offset (next best +0x1C with 478 violations, then
;    +0x0C with 524, then +0x10 with 739).  Record #0 is 0,0-319,239: the full
;    screen.
;  * The class id decodes against HDAE5000_ClassName_Table[0..12] (13 pointers,
;    an empty 14th entry, then 0xFFFFFFFF), with four exact hits and no
;    counter-example: 016A:0003 is the single object named HddNamingWindow and
;    [3] is "AcHddNamingWindowProc"; 016A:0009 contains the object named
;    IV_HDDMENU and [9] is "IvScreenR2Proc"; 016A:000B is a child of
;    Tech_lyrics and [11] is "LyricBoxProc"; 016A:000C is a child of
;    LoadLyricFD and [12] is "FDFileSelectProc".  Consistent with that:
;    016A:0000 = [0] "SelectListProc" holds SEL_DIR / LBN_*_BOX / CP_FD_LIST /
;    SEL_FLS, and 016A:0002 / 0006 / 0007 = the TtlScreenRProc / R2 / R3
;    titled screens.  016A:0005 ("HDTitleMenuProc") has no static descriptor.
;  * 13 of the 41 classes carry a .long caption pointer at a fixed body offset
;    - 329 slots in 325 records.  All 329 point INSIDE their own record, and
;    the last caption of a record runs to the record end bar at most one pad
;    byte.  Classes 0160:0026 (pool) and 0160:004E (RAM image only) carry TWO:
;    a toggle soft key whose two states each have a caption - object 73
;    RUN_STOP is +0x1E "RUN" / +0x1A "STOP"; objects 75/76/77 PPORT_SW / FD_SW
;    / HDD_SW hold two separate copies of the same word.
;  * Body length is constant per class for 40 of the 41 classes (note 1).
;    Byte accounting: 30,252 B of header+body + 2,616 B of inline strings +
;    182 pad bytes = 33,050 B.  That assigns every byte to a record and to a
;    role; it does NOT decode them.  13,334 B (30,252 - 769 x 22) of
;    class-specific body remain UNDECODED.
;  * Independent confirmation of the layout: HDAE5000_WindowGeometry_Init (ROM
;    0x2F9C4C-0x2F9F59) holds the 20 run-time descriptors in this same format.
;    Their record lengths equal the RAM address deltas in the pointer table,
;    and every link field they carry agrees with the ROM tree, 33/33.
;
; NOTE 1: object #127 (class 0160:0029, under SETUP_TOOLS_P2) is the only
; record longer than its class body - it has "! HD FORMAT !" bolted on at
; +0x1A with no pointer of its own.  That string is the caption of the RAM
; object #128 SW_HD_FORMAT and is cited from the init image instead; it is
; HDAE5000_Str_Alert_HDFormat in hdae5000_init_data.s.
; NOTE 2: object #442 "HddNamingCursorBox" (class 0160:004C) ends with six
; 4-byte literals "ABC" "ABC" "abc" "abc" "!#$" "!#$" at +0x28..+0x3C.  Those
; are the captions of the RAM objects #443/444/445 HddNamingABC/abc/Symbol and
; are HDAE5000_Str_CharSet_* in hdae5000_init_data.s.
;
; The 769 records below are split exactly at the .long values of
; HDAE5000_UiObject_PtrTable (which now names them), nothing else.
; =============================================================================

	; 0x29DC12  POOL START = HDAE5000_UiObject_PtrTable[0] = record #0,
	;           "HDDMENU", class 016A:0002 TtlScreenRProc, 52 bytes,
	;           box 0,0-319,239, caption "HD-AE5000" at +0x2A.
	; [#0] "HDDMENU"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 52 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_000:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 1, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0060, 0x01a0	; +0x16 class body
	.long	0x002398e2				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_000_Cap22			; +0x22 caption pointer
	.short	0x0083, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_000: the record's +0x22 caption pointer names this string
HdaeUiObj_000_Cap22:	.asciz	"HD-AE5000"
	.set	HDAE5000_UI_Descriptors, HdaeUiObj_000 + 0x02	; 0x29DC14
	; MISNOMER retained for cross-reference: this is NOT the start of
	; "UI page descriptors and config", and not a record boundary at all.
	; 0x29DC14 is byte +0x02 of record #0 above, which splits that
	; record's .long class id in half.  The pool starts two bytes lower,
	; at 0x29DC12; see the header block above.

	; [#1] (unnamed)  class 0160:0041 = KN5000 widget type 0x41, 70 bytes, parent #0 HDDMENU,
	; box 8,72-156,97.  Record layout and evidence: pool header above.
HdaeUiObj_001:
	.long	0x01600041				; +0x00 class id
	.short	0, 0xffff, 2, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 72, 156, 97			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000, 0x0089	; +0x16 class body
	.long	0x002398e6				; +0x26 RAM address (every 0160:0041 record)
	.long	HdaeUiObj_001_Cap2A			; +0x2A caption pointer
	.short	0x0013, 0x007f, 0x0008, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_001: the record's +0x2A caption pointer names this string
HdaeUiObj_001_Cap2A:	.asciz	"SETUP & TOOLS  "

	; [#2] (unnamed)  class 0160:0041 = KN5000 widget type 0x41, 56 bytes, parent #0 HDDMENU,
	; box 163,114-311,139.  Record layout and evidence: pool header above.
HdaeUiObj_002:
	.long	0x01600041				; +0x00 class id
	.short	0, 3, 4, 1	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	163, 114, 311, 139			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000, 0x000a	; +0x16 class body
	.long	0x002398e8				; +0x26 RAM address (every 0160:0041 record)
	.long	HdaeUiObj_002_Cap2A			; +0x2A caption pointer
	.short	0x008f, 0x007f, 0x00ae, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_002: the record's +0x2A caption pointer names this string
HdaeUiObj_002_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#3] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #2,
	; box 170,114-281,145.  Record layout and evidence: pool header above.
HdaeUiObj_003:
	.long	0x016a000a				; +0x00 class id
	.short	2, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	170, 114, 281, 145			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0006, 0x0000, 0x0000, 0x00ff, 0x0001, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#4] (unnamed)  class 0160:0041 = KN5000 widget type 0x41, 56 bytes, parent #0 HDDMENU,
	; box 163,156-311,181.  Record layout and evidence: pool header above.
HdaeUiObj_004:
	.long	0x01600041				; +0x00 class id
	.short	0, 5, 6, 2	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	163, 156, 311, 181			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0002, 0x000b	; +0x16 class body
	.long	0x002398ea				; +0x26 RAM address (every 0160:0041 record)
	.long	HdaeUiObj_004_Cap2A			; +0x2A caption pointer
	.short	0x00f0, 0x007f, 0x00af, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_004: the record's +0x2A caption pointer names this string
HdaeUiObj_004_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#5] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #4,
	; box 170,156-281,187.  Record layout and evidence: pool header above.
HdaeUiObj_005:
	.long	0x016a000a				; +0x00 class id
	.short	4, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	170, 156, 281, 187			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0007, 0x0000, 0x0000, 0x00ff, 0x0001, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#6] (unnamed)  class 0160:0041 = KN5000 widget type 0x41, 56 bytes, parent #0 HDDMENU,
	; box 8,114-156,139.  Record layout and evidence: pool header above.
HdaeUiObj_006:
	.long	0x01600041				; +0x00 class id
	.short	0, 7, 8, 4	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 114, 156, 139			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000, 0x008a	; +0x16 class body
	.long	0x002398ec				; +0x26 RAM address (every 0160:0041 record)
	.long	HdaeUiObj_006_Cap2A			; +0x2A caption pointer
	.short	0xffff, 0xffff, 0x0073, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_006: the record's +0x2A caption pointer names this string
HdaeUiObj_006_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#7] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #6,
	; box 36,114-160,145.  Record layout and evidence: pool header above.
HdaeUiObj_007:
	.long	0x016a000a				; +0x00 class id
	.short	6, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	36, 114, 160, 145			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0003, 0x0000, 0x0000, 0x00ff, 0x0001, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#8] (unnamed)  class 0160:0041 = KN5000 widget type 0x41, 56 bytes, parent #0 HDDMENU,
	; box 8,156-156,181.  Record layout and evidence: pool header above.
HdaeUiObj_008:
	.long	0x01600041				; +0x00 class id
	.short	0, 9, 10, 6	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 156, 156, 181			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000, 0x008b	; +0x16 class body
	.long	0x002398ee				; +0x26 RAM address (every 0160:0041 record)
	.long	HdaeUiObj_008_Cap2A			; +0x2A caption pointer
	.short	0x0085, 0x007f, 0x0021, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_008: the record's +0x2A caption pointer names this string
HdaeUiObj_008_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#9] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #8,
	; box 36,156-160,187.  Record layout and evidence: pool header above.
HdaeUiObj_009:
	.long	0x016a000a				; +0x00 class id
	.short	8, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	36, 156, 160, 187			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0004, 0x0000, 0x0000, 0x00ff, 0x0001, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#10] "HARD_DISK_OPT"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #0 HDDMENU,
	; box 8,188-309,237.  Record layout and evidence: pool header above.
HdaeUiObj_010:
	.long	0x016a0000				; +0x00 class id
	.short	0, 0xffff, 11, 8	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 188, 309, 237			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0x0064, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0140	; +0x16 class body
	.long	0x002398f0				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0003	; +0x2A class body
	.long	0x002398f4				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x002398f6				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#11] (unnamed)  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #0 HDDMENU,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_011:
	.long	0x01600052				; +0x00 class id
	.short	0, 0xffff, 12, 10	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0016, 0x012a	; +0x16 class body

	; [#12] (unnamed)  class 0160:0029 = KN5000 widget type 0x29, 26 bytes, parent #0 HDDMENU,
	; box 32,0-63,31.  Record layout and evidence: pool header above.
HdaeUiObj_012:
	.long	0x01600029				; +0x00 class id
	.short	0, 0xffff, 13, 11	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	32, 0, 63, 31			; +0x0E box x1, y1, x2, y2
	.short	0x000c, 0x014a	; +0x16 class body

	; [#13] (unnamed)  class 0160:0069 = KN5000 widget type 0x69, 26 bytes, parent #0 HDDMENU,
	; box 93,1-119,27.  Record layout and evidence: pool header above.
HdaeUiObj_013:
	.long	0x01600069				; +0x00 class id
	.short	0, 0xffff, 14, 12	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	93, 1, 119, 27			; +0x0E box x1, y1, x2, y2
	.short	0x0027, 0x012a	; +0x16 class body

	; [#14] (unnamed)  class 0160:0041 = KN5000 widget type 0x41, 56 bytes, parent #0 HDDMENU,
	; box 163,72-311,97.  Record layout and evidence: pool header above.
HdaeUiObj_014:
	.long	0x01600041				; +0x00 class id
	.short	0, 15, 17, 13	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	163, 72, 311, 97			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0001, 0x0009	; +0x16 class body
	.long	0x002398f8				; +0x26 RAM address (every 0160:0041 record)
	.long	HdaeUiObj_014_Cap2A			; +0x2A caption pointer
	.short	0x0022, 0x007f, 0x00ad, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_014: the record's +0x2A caption pointer names this string
HdaeUiObj_014_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#15] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #14,
	; box 170,72-281,103.  Record layout and evidence: pool header above.
HdaeUiObj_015:
	.long	0x016a000a				; +0x00 class id
	.short	14, 16, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	170, 72, 281, 103			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0005, 0x0000, 0x0000, 0x00ff, 0x0001, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#16] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #15,
	; box 170,72-281,103.  Record layout and evidence: pool header above.
HdaeUiObj_016:
	.long	0x016a000a				; +0x00 class id
	.short	15, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	170, 72, 281, 103			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0005, 0x0000, 0x0000, 0x00ff, 0x0001, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#17] (unnamed)  class 0160:0041 = KN5000 widget type 0x41, 56 bytes, parent #0 HDDMENU,
	; box 163,30-311,55.  Record layout and evidence: pool header above.
HdaeUiObj_017:
	.long	0x01600041				; +0x00 class id
	.short	0, 0xffff, 18, 14	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	163, 30, 311, 55			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0001, 0x0008	; +0x16 class body
	.long	0x002398fa				; +0x26 RAM address (every 0160:0041 record)
	.long	HdaeUiObj_017_Cap2A			; +0x2A caption pointer
	.short	0x02f0, 0x007f, 0x003c, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_017: the record's +0x2A caption pointer names this string
HdaeUiObj_017_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#18] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 54 bytes, parent #0 HDDMENU,
	; box 170,30-229,61.  Record layout and evidence: pool header above.
HdaeUiObj_018:
	.long	0x01600036				; +0x00 class id
	.short	0, 0xffff, 0xffff, 17	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	170, 30, 229, 61			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000	; +0x16 class body
	.long	HdaeUiObj_018_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0002	; +0x1E class body
	; caption of HdaeUiObj_018: the record's +0x1A caption pointer names this string
HdaeUiObj_018_Cap1A:	.asciz	"LYRICS WINDOW"
	.set	HDAE5000_UI_Page_Titles, HdaeUiObj_018_Cap1A	; 0x29DF8A
	; MISNOMER retained for cross-reference (the ASL mirror, the symbols
	; reference and a .set base in hdae5000_init_data.s use this name).
	; RETRACTED: "UI page title strings".  There is no table of page titles
	; here.  0x29DF8A is byte +0x28 of object #18 (record 0x29DF62-0x29DF97,
	; 54 bytes, class 0160:0036, a child of HDDMENU) - it is that ONE
	; object's inline caption, named by the .long at +0x1A of the record.
	; The nearest record boundary is 0x28 bytes ABOVE this label.  See the
	; pool header at HDAE5000_UI_Descriptors.

	; [#19] "SETUPS_TOOLS"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 58 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_019:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 20, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x007f, 0x01a0	; +0x16 class body
	.long	0x002398fc				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_019_Cap22			; +0x22 caption pointer
	.short	0x0008, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_019: the record's +0x22 caption pointer names this string
HdaeUiObj_019_Cap22:	.asciz	" SETUP & TOOLS "

	; [#20] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #19 SETUPS_TOOLS,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_020:
	.long	0x01600049				; +0x00 class id
	.short	19, 0xffff, 21, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x007f	; +0x16 class body

	; [#21] (unnamed)  class 0160:0028 = KN5000 widget type 0x28, 28 bytes, parent #19 SETUPS_TOOLS,
	; box 31,30-62,61.  Record layout and evidence: pool header above.
HdaeUiObj_021:
	.long	0x01600028				; +0x00 class id
	.short	19, 0xffff, 22, 20	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	31, 30, 62, 61			; +0x0E box x1, y1, x2, y2
	.short	0x0002, 0x007a, 0x007f	; +0x16 class body

	; [#22] (unnamed)  class 0160:0028 = KN5000 widget type 0x28, 28 bytes, parent #19 SETUPS_TOOLS,
	; box 0,31-31,62.  Record layout and evidence: pool header above.
HdaeUiObj_022:
	.long	0x01600028				; +0x00 class id
	.short	19, 0xffff, 23, 21	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 31, 31, 62			; +0x0E box x1, y1, x2, y2
	.short	0x0001, 0x006e, 0x007f	; +0x16 class body

	; [#23] (unnamed)  class 016A:0008 = ClassName_Table[8] "AcWindowPage1Proc", 36 bytes, parent #19 SETUPS_TOOLS,
	; box 245,6-315,23.  Record layout and evidence: pool header above.
HdaeUiObj_023:
	.long	0x016a0008				; +0x00 class id
	.short	19, 0xffff, 0xffff, 22	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	245, 6, 315, 23			; +0x0E box x1, y1, x2, y2
	.short	0x00f3, 0x00c1, 0xffff	; +0x16 class body
	.long	0x00239900				; +0x1C RAM address (every 016A:0008 record)
	.short	0x0001, 0x0002	; +0x20 class body

	; [#24] "SELECT_FILE"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_024:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 25, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x007f, 0x01a0	; +0x16 class body
	.long	0x00239902				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_024_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_024: the record's +0x22 caption pointer names this string
HdaeUiObj_024_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#25] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #24 SELECT_FILE,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_025:
	.long	0x01600049				; +0x00 class id
	.short	24, 0xffff, 26, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0022, 0x007f	; +0x16 class body

	; [#26] "HD_FILE_LOAD"  class 0160:0028 = KN5000 widget type 0x28, 28 bytes, parent #24 SELECT_FILE,
	; box 0,32-31,63.  Record layout and evidence: pool header above.
HdaeUiObj_026:
	.long	0x01600028				; +0x00 class id
	.short	24, 0xffff, 27, 25	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 32, 31, 63			; +0x0E box x1, y1, x2, y2
	.short	0x0001, 0x00ff, 0x007f	; +0x16 class body

	; [#27] "HD_LOAD_OPTION"  class 0160:0028 = KN5000 widget type 0x28, 28 bytes, parent #24 SELECT_FILE,
	; box 0,64-31,95.  Record layout and evidence: pool header above.
HdaeUiObj_027:
	.long	0x01600028				; +0x00 class id
	.short	24, 0xffff, 28, 26	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 64, 31, 95			; +0x0E box x1, y1, x2, y2
	.short	0x0002, 0x0110, 0x007f	; +0x16 class body

	; [#28] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #24 SELECT_FILE,
	; box 265,36-311,61.  Record layout and evidence: pool header above.
HdaeUiObj_028:
	.long	0x0160001f				; +0x00 class id
	.short	24, 29, 30, 27	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	265, 36, 311, 61			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0008	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#29] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #28,
	; box 270,40-305,58.  Record layout and evidence: pool header above.
HdaeUiObj_029:
	.long	0x0160002b				; +0x00 class id
	.short	28, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	270, 40, 305, 58			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_029_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_029: the record's +0x16 caption pointer names this string
HdaeUiObj_029_Cap16:	.asciz	"LOAD"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#30] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #24 SELECT_FILE,
	; box 313,40-313,79.  Record layout and evidence: pool header above.
HdaeUiObj_030:
	.long	0x0160002e				; +0x00 class id
	.short	24, 0xffff, 31, 28	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	313, 40, 313, 79			; +0x0E box x1, y1, x2, y2
	.short	0x00f4, 0x0001	; +0x16 class body

	; [#31] (unnamed)  class 0160:0030 = KN5000 widget type 0x30, 44 bytes, parent #24 SELECT_FILE,
	; box 310,77-319,93.  Record layout and evidence: pool header above.
HdaeUiObj_031:
	.long	0x01600030				; +0x00 class id
	.short	24, 0xffff, 32, 30	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	310, 77, 319, 93			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_031_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x00f4, 0x0009, 0x0000, 0x0120, 0xffff	; +0x1A class body
	; caption of HdaeUiObj_031: the record's +0x16 caption pointer names this string
HdaeUiObj_031_Cap16:	.asciz	"~80"

	; [#32] (unnamed)  class 0160:0029 = KN5000 widget type 0x29, 26 bytes, parent #24 SELECT_FILE,
	; box 0,96-31,127.  Record layout and evidence: pool header above.
HdaeUiObj_032:
	.long	0x01600029				; +0x00 class id
	.short	24, 0xffff, 33, 31	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 96, 31, 127			; +0x0E box x1, y1, x2, y2
	.short	0x000d, 0x014a	; +0x16 class body

	; [#33] (unnamed)  class 016A:0008 = ClassName_Table[8] "AcWindowPage1Proc", 36 bytes, parent #24 SELECT_FILE,
	; box 245,6-315,23.  Record layout and evidence: pool header above.
HdaeUiObj_033:
	.long	0x016a0008				; +0x00 class id
	.short	24, 0xffff, 0xffff, 32	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	245, 6, 315, 23			; +0x0E box x1, y1, x2, y2
	.short	0x00f3, 0x00c1, 0xffff	; +0x16 class body
	.long	0x00239906				; +0x1C RAM address (every 016A:0008 record)
	.short	0x0001, 0x0002	; +0x20 class body

	; [#34] "SELECT_DIR"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 56 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_034:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 35, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239908				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_034_Cap22			; +0x22 caption pointer
	.short	0x00ad, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_034: the record's +0x22 caption pointer names this string
HdaeUiObj_034_Cap22:	.asciz	"HD DIR SELECT"

	; [#35] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #34 SELECT_DIR,
	; box 84,222-195,239.  Record layout and evidence: pool header above.
HdaeUiObj_035:
	.long	0x01600022				; +0x00 class id
	.short	34, 0xffff, 36, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	84, 222, 195, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0004, 0x0003	; +0x26 class body

	; [#36] (unnamed)  class 0160:0029 = KN5000 widget type 0x29, 26 bytes, parent #34 SELECT_DIR,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_036:
	.long	0x01600029				; +0x00 class id
	.short	34, 0xffff, 37, 35	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0001, 0x014a	; +0x16 class body

	; [#37] "SEL_DIR"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #34 SELECT_DIR,
	; box 8,35-263,210.  Record layout and evidence: pool header above.
HdaeUiObj_037:
	.long	0x016a0000				; +0x00 class id
	.short	34, 0xffff, 38, 36	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 35, 263, 210			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0x0000, 0x0003, 0x0000, 0x00ff, 0x0001, 0x014a	; +0x16 class body
	.long	0x0023990c				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0002, 0x000c	; +0x2A class body
	.long	0x00239910				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x32 class body
	.long	0x00239912				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#38] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 52 bytes, parent #34 SELECT_DIR,
	; box 281,222-318,239.  Record layout and evidence: pool header above.
HdaeUiObj_038:
	.long	0x0160003e				; +0x00 class id
	.short	34, 0xffff, 39, 37	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	281, 222, 318, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0007	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_038_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_038: the record's +0x28 caption pointer names this string
HdaeUiObj_038_Cap28:	.asciz	"97-120"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#39] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #34 SELECT_DIR,
	; box 1,222-38,239.  Record layout and evidence: pool header above.
HdaeUiObj_039:
	.long	0x0160003e				; +0x00 class id
	.short	34, 0xffff, 40, 38	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	1, 222, 38, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0000	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_039_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_039: the record's +0x28 caption pointer names this string
HdaeUiObj_039_Cap28:	.asciz	"01-24"

	; [#40] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #34 SELECT_DIR,
	; box 43,222-80,239.  Record layout and evidence: pool header above.
HdaeUiObj_040:
	.long	0x0160003e				; +0x00 class id
	.short	34, 0xffff, 41, 39	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	43, 222, 80, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0007	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_040_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_040: the record's +0x28 caption pointer names this string
HdaeUiObj_040_Cap28:	.asciz	"25-48"

	; [#41] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #34 SELECT_DIR,
	; box 199,222-236,239.  Record layout and evidence: pool header above.
HdaeUiObj_041:
	.long	0x0160003e				; +0x00 class id
	.short	34, 0xffff, 42, 40	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	199, 222, 236, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0007	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_041_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_041: the record's +0x28 caption pointer names this string
HdaeUiObj_041_Cap28:	.asciz	"49-72"

	; [#42] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #34 SELECT_DIR,
	; box 240,222-277,239.  Record layout and evidence: pool header above.
HdaeUiObj_042:
	.long	0x0160003e				; +0x00 class id
	.short	34, 0xffff, 43, 41	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	240, 222, 277, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0007	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_042_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_042: the record's +0x28 caption pointer names this string
HdaeUiObj_042_Cap28:	.asciz	"73-96"

	; [#43] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #34 SELECT_DIR,
	; box 265,36-311,61.  Record layout and evidence: pool header above.
HdaeUiObj_043:
	.long	0x0160001f				; +0x00 class id
	.short	34, 0xffff, 44, 42	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	265, 36, 311, 61			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000, 0x0008	; +0x16 class body
	.short	0x0006	; +0x26 class body

	; [#45] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #44 SELECT_DIR_SW_EDIT,
	; box 271,202-306,220.  Record layout and evidence: pool header above.
HdaeUiObj_045:
	.long	0x0160002b				; +0x00 class id
	.short	44, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	271, 202, 306, 220			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_045_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_045: the record's +0x16 caption pointer names this string
HdaeUiObj_045_Cap16:	.asciz	"EDIT"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#46] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #34 SELECT_DIR,
	; box 32,0-63,31.  Record layout and evidence: pool header above.
HdaeUiObj_046:
	.long	0x01600049				; +0x00 class id
	.short	34, 0xffff, 47, 44	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	32, 0, 63, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x007f	; +0x16 class body

	; [#47] (unnamed)  class 0160:0030 = KN5000 widget type 0x30, 44 bytes, parent #34 SELECT_DIR,
	; box 310,77-319,95.  Record layout and evidence: pool header above.
HdaeUiObj_047:
	.long	0x01600030				; +0x00 class id
	.short	34, 0xffff, 48, 46	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	310, 77, 319, 95			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_047_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x00f4, 0x0009, 0x0000, 0x0120, 0x0006	; +0x1A class body
	; caption of HdaeUiObj_047: the record's +0x16 caption pointer names this string
HdaeUiObj_047_Cap16:	.asciz	"~80"

	; [#48] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #34 SELECT_DIR,
	; box 313,40-313,79.  Record layout and evidence: pool header above.
HdaeUiObj_048:
	.long	0x0160002e				; +0x00 class id
	.short	34, 0xffff, 0xffff, 47	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	313, 40, 313, 79			; +0x0E box x1, y1, x2, y2
	.short	0x00f4, 0x0001	; +0x16 class body

	; [#49] "SELECT_DIR2"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 64 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_049:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 50, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239914				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_049_Cap22			; +0x22 caption pointer
	.short	0x0083, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_049: the record's +0x22 caption pointer names this string
HdaeUiObj_049_Cap22:	.asciz	" DIRECTORY SELECT   "
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#50] (unnamed)  class 0160:0041 = KN5000 widget type 0x41, 56 bytes, parent #49 SELECT_DIR2,
	; box 266,38-311,61.  Record layout and evidence: pool header above.
HdaeUiObj_050:
	.long	0x01600041				; +0x00 class id
	.short	49, 51, 52, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	266, 38, 311, 61			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000, 0x0008	; +0x16 class body
	.long	0x00239918				; +0x26 RAM address (every 0160:0041 record)
	.long	HdaeUiObj_050_Cap2A			; +0x2A caption pointer
	.short	0x0018, 0x007f, 0x0000, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_050: the record's +0x2A caption pointer names this string
HdaeUiObj_050_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#51] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #50,
	; box 278,42-297,60.  Record layout and evidence: pool header above.
HdaeUiObj_051:
	.long	0x0160002b				; +0x00 class id
	.short	50, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	278, 42, 297, 60			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_051_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_051: the record's +0x16 caption pointer names this string
HdaeUiObj_051_Cap16:	.asciz	"OK"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#52] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #49 SELECT_DIR2,
	; box 84,220-195,237.  Record layout and evidence: pool header above.
HdaeUiObj_052:
	.long	0x01600022				; +0x00 class id
	.short	49, 0xffff, 53, 50	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	84, 220, 195, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0004, 0x0003	; +0x26 class body

	; [#53] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #49 SELECT_DIR2,
	; box 44,220-75,237.  Record layout and evidence: pool header above.
HdaeUiObj_053:
	.long	0x0160001f				; +0x00 class id
	.short	49, 0xffff, 54, 52	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 220, 75, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x000f	; +0x26 class body

	; [#54] (unnamed)  class 0160:0041 = KN5000 widget type 0x41, 56 bytes, parent #49 SELECT_DIR2,
	; box 266,77-305,108.  Record layout and evidence: pool header above.
HdaeUiObj_054:
	.long	0x01600041				; +0x00 class id
	.short	49, 55, 56, 53	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	266, 77, 305, 108			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000, 0x0009	; +0x16 class body
	.long	0x0023991a				; +0x26 RAM address (every 0160:0041 record)
	.long	HdaeUiObj_054_Cap2A			; +0x2A caption pointer
	.short	0x0018, 0x007f, 0x0000, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_054: the record's +0x2A caption pointer names this string
HdaeUiObj_054_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#55] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #54,
	; box 278,42-297,60.  Record layout and evidence: pool header above.
HdaeUiObj_055:
	.long	0x0160002b				; +0x00 class id
	.short	54, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	278, 42, 297, 60			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_055_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_055: the record's +0x16 caption pointer names this string
HdaeUiObj_055_Cap16:	.asciz	"OK"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#56] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #49 SELECT_DIR2,
	; box 313,44-313,83.  Record layout and evidence: pool header above.
HdaeUiObj_056:
	.long	0x0160002e				; +0x00 class id
	.short	49, 0xffff, 57, 54	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	313, 44, 313, 83			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#57] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #49 SELECT_DIR2,
	; box 204,220-235,237.  Record layout and evidence: pool header above.
HdaeUiObj_057:
	.long	0x0160001f				; +0x00 class id
	.short	49, 0xffff, 0xffff, 56	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	204, 220, 235, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0002, 0x0000, 0x0000, 0x0000, 0x0000, 0x0005	; +0x16 class body
	.short	0x0010	; +0x26 class body

	; [#58] "FD_FILE_SELECT"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 62 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_058:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 59, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x007f, 0x01a0	; +0x16 class body
	.long	0x0023991c				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_058_Cap22			; +0x22 caption pointer
	.short	0x0083, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_058: the record's +0x22 caption pointer names this string
HdaeUiObj_058_Cap22:	.asciz	" FD FILE SELECT   "
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#59] (unnamed)  class 0160:0041 = KN5000 widget type 0x41, 56 bytes, parent #58 FD_FILE_SELECT,
	; box 266,38-311,61.  Record layout and evidence: pool header above.
HdaeUiObj_059:
	.long	0x01600041				; +0x00 class id
	.short	58, 60, 61, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	266, 38, 311, 61			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000, 0x0008	; +0x16 class body
	.long	0x00239920				; +0x26 RAM address (every 0160:0041 record)
	.long	HdaeUiObj_059_Cap2A			; +0x2A caption pointer
	.short	0x0018, 0x007f, 0x0000, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_059: the record's +0x2A caption pointer names this string
HdaeUiObj_059_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#60] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #59,
	; box 270,41-305,59.  Record layout and evidence: pool header above.
HdaeUiObj_060:
	.long	0x0160002b				; +0x00 class id
	.short	59, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	270, 41, 305, 59			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_060_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_060: the record's +0x16 caption pointer names this string
HdaeUiObj_060_Cap16:	.asciz	"COPY"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#61] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #58 FD_FILE_SELECT,
	; box 84,220-195,237.  Record layout and evidence: pool header above.
HdaeUiObj_061:
	.long	0x01600022				; +0x00 class id
	.short	58, 0xffff, 62, 59	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	84, 220, 195, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0004, 0x0003	; +0x26 class body

	; [#62] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #58 FD_FILE_SELECT,
	; box 44,220-75,237.  Record layout and evidence: pool header above.
HdaeUiObj_062:
	.long	0x0160001f				; +0x00 class id
	.short	58, 0xffff, 63, 61	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 220, 75, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x000f	; +0x26 class body

	; [#63] (unnamed)  class 0160:0041 = KN5000 widget type 0x41, 56 bytes, parent #58 FD_FILE_SELECT,
	; box 266,77-305,108.  Record layout and evidence: pool header above.
HdaeUiObj_063:
	.long	0x01600041				; +0x00 class id
	.short	58, 0xffff, 64, 62	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	266, 77, 305, 108			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000, 0x0009	; +0x16 class body
	.long	0x00239922				; +0x26 RAM address (every 0160:0041 record)
	.long	HdaeUiObj_063_Cap2A			; +0x2A caption pointer
	.short	0x0018, 0x007f, 0x0000, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_063: the record's +0x2A caption pointer names this string
HdaeUiObj_063_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#64] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #58 FD_FILE_SELECT,
	; box 313,44-313,83.  Record layout and evidence: pool header above.
HdaeUiObj_064:
	.long	0x0160002e				; +0x00 class id
	.short	58, 0xffff, 65, 63	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	313, 44, 313, 83			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#65] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #58 FD_FILE_SELECT,
	; box 204,220-235,237.  Record layout and evidence: pool header above.
HdaeUiObj_065:
	.long	0x0160001f				; +0x00 class id
	.short	58, 0xffff, 66, 64	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	204, 220, 235, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0002, 0x0000, 0x0000, 0x0000, 0x0000, 0x0005	; +0x16 class body
	.short	0x0010	; +0x26 class body

	; [#66] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #58 FD_FILE_SELECT,
	; box 244,220-315,237.  Record layout and evidence: pool header above.
HdaeUiObj_066:
	.long	0x01600022				; +0x00 class id
	.short	58, 67, 68, 65	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 220, 315, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0004, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0007, 0x0000	; +0x26 class body

	; [#67] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 40 bytes, parent #66,
	; box 254,221-305,239.  Record layout and evidence: pool header above.
HdaeUiObj_067:
	.long	0x0160002b				; +0x00 class id
	.short	66, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	254, 221, 305, 239			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_067_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_067: the record's +0x16 caption pointer names this string
HdaeUiObj_067_Cap16:	.asciz	"SELECT"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#68] (unnamed)  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #58 FD_FILE_SELECT,
	; box 40,52-239,207.  Record layout and evidence: pool header above.
HdaeUiObj_068:
	.long	0x016a0000				; +0x00 class id
	.short	58, 0xffff, 0xffff, 66	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 52, 239, 207			; +0x0E box x1, y1, x2, y2
	.short	0x0002, 0x00c1, 0x0001, 0x0000, 0x0000, 0x00ff, 0x0000, 0x0140	; +0x16 class body
	.long	0x00239924				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0002, 0x000a	; +0x2A class body
	.long	0x00239928				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x0023992a				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#69] "HARD_TEST"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 56 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_069:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 70, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x0023992c				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_069_Cap22			; +0x22 caption pointer
	.short	0x0083, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_069: the record's +0x22 caption pointer names this string
HdaeUiObj_069_Cap22:	.asciz	"HARDWARE TEST"

	; [#70] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #69 HARD_TEST,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_070:
	.long	0x01600049				; +0x00 class id
	.short	69, 71, 72, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x007f	; +0x16 class body

	; [#71] (unnamed)  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #70,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_071:
	.long	0x01600052				; +0x00 class id
	.short	70, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x012a	; +0x16 class body

	; [#72] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #69 HARD_TEST,
	; box 32,0-63,31.  Record layout and evidence: pool header above.
HdaeUiObj_072:
	.long	0x01600049				; +0x00 class id
	.short	69, 0xffff, 73, 70	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	32, 0, 63, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x007f	; +0x16 class body

	; [#73] "RUN_STOP"  class 0160:0026 = KN5000 widget type 0x26, 50 bytes, parent #69 HARD_TEST,
	; box 265,202-311,219.  Record layout and evidence: pool header above.
HdaeUiObj_073:
	.long	0x01600026				; +0x00 class id
	.short	69, 0xffff, 74, 72	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	265, 202, 311, 219			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x0000	; +0x16 class body
	.long	HdaeUiObj_073_Cap1A			; +0x1A caption pointer
	.long	HdaeUiObj_073_Cap1E			; +0x1E caption pointer
	.long	0x00239930				; +0x22 RAM address (every 0160:0026 record)
	.short	0x000c	; +0x26 class body
	; caption of HdaeUiObj_073: the record's +0x1E caption pointer names this string
HdaeUiObj_073_Cap1E:	.asciz	"RUN"
	; caption of HdaeUiObj_073: the record's +0x1A caption pointer names this string
HdaeUiObj_073_Cap1A:	.asciz	"STOP"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#74] (unnamed)  class 016A:0001 = ClassName_Table[1] "DbMemoClProc", 26 bytes, parent #69 HARD_TEST,
	; box 0,32-230,239.  Record layout and evidence: pool header above.
HdaeUiObj_074:
	.long	0x016a0001				; +0x00 class id
	.short	69, 0xffff, 75, 73	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	0, 32, 230, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x00ff	; +0x16 class body

	; [#75] "PPORT_SW"  class 0160:0026 = KN5000 widget type 0x26, 52 bytes, parent #69 HARD_TEST,
	; box 265,76-311,93.  Record layout and evidence: pool header above.
HdaeUiObj_075:
	.long	0x01600026				; +0x00 class id
	.short	69, 0xffff, 76, 74	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	265, 76, 311, 93			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x0000	; +0x16 class body
	.long	HdaeUiObj_075_Cap1A			; +0x1A caption pointer
	.long	HdaeUiObj_075_Cap1E			; +0x1E caption pointer
	.long	0x00239932				; +0x22 RAM address (every 0160:0026 record)
	.short	0x0009	; +0x26 class body
	; caption of HdaeUiObj_075: the record's +0x1E caption pointer names this string
HdaeUiObj_075_Cap1E:	.asciz	"PPORT"
	; caption of HdaeUiObj_075: the record's +0x1A caption pointer names this string
HdaeUiObj_075_Cap1A:	.asciz	"PPORT"

	; [#76] "FD_SW"  class 0160:0026 = KN5000 widget type 0x26, 48 bytes, parent #69 HARD_TEST,
	; box 281,160-311,177.  Record layout and evidence: pool header above.
HdaeUiObj_076:
	.long	0x01600026				; +0x00 class id
	.short	69, 0xffff, 77, 75	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	281, 160, 311, 177			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x0000	; +0x16 class body
	.long	HdaeUiObj_076_Cap1A			; +0x1A caption pointer
	.long	HdaeUiObj_076_Cap1E			; +0x1E caption pointer
	.long	0x00239934				; +0x22 RAM address (every 0160:0026 record)
	.short	0x000b	; +0x26 class body
	; caption of HdaeUiObj_076: the record's +0x1E caption pointer names this string
HdaeUiObj_076_Cap1E:	.asciz	"FD"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)
	; caption of HdaeUiObj_076: the record's +0x1A caption pointer names this string
HdaeUiObj_076_Cap1A:	.asciz	"FD"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#77] "HDD_SW"  class 0160:0026 = KN5000 widget type 0x26, 48 bytes, parent #69 HARD_TEST,
	; box 281,118-311,135.  Record layout and evidence: pool header above.
HdaeUiObj_077:
	.long	0x01600026				; +0x00 class id
	.short	69, 0xffff, 0xffff, 76	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	281, 118, 311, 135			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x0000	; +0x16 class body
	.long	HdaeUiObj_077_Cap1A			; +0x1A caption pointer
	.long	HdaeUiObj_077_Cap1E			; +0x1E caption pointer
	.long	0x00239936				; +0x22 RAM address (every 0160:0026 record)
	.short	0x000a	; +0x26 class body
	; caption of HdaeUiObj_077: the record's +0x1E caption pointer names this string
HdaeUiObj_077_Cap1E:	.asciz	"HDD"
	; caption of HdaeUiObj_077: the record's +0x1A caption pointer names this string
HdaeUiObj_077_Cap1A:	.asciz	"HDD"

	; [#78] "HDD_FILE_NAMING"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 58 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_078:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 79, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x007f, 0x01a0	; +0x16 class body
	.long	0x00239938				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_078_Cap22			; +0x22 caption pointer
	.short	0x00ad, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_078: the record's +0x22 caption pointer names this string
HdaeUiObj_078_Cap22:	.asciz	"EDIT FILE NAME"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#79] (unnamed)  class 0160:0029 = KN5000 widget type 0x29, 26 bytes, parent #78 HDD_FILE_NAMING,
	; box 32,0-63,31.  Record layout and evidence: pool header above.
HdaeUiObj_079:
	.long	0x01600029				; +0x00 class id
	.short	78, 0xffff, 80, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	32, 0, 63, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0003, 0x014a	; +0x16 class body

	; [#80] (unnamed)  class 0160:0020 = KN5000 widget type 0x20, 44 bytes, parent #78 HDD_FILE_NAMING,
	; box 281,160-311,177.  Record layout and evidence: pool header above.
HdaeUiObj_080:
	.long	0x01600020				; +0x00 class id
	.short	78, 0xffff, 81, 79	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	281, 160, 311, 177			; +0x0E box x1, y1, x2, y2
	.short	0x00f2, 0x00c1, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x000b	; +0x16 class body
	.short	0x0006, 0x0001, 0x012a	; +0x26 class body

	; [#81] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #78 HDD_FILE_NAMING,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_081:
	.long	0x01600049				; +0x00 class id
	.short	78, 0xffff, 82, 80	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0018, 0x007f	; +0x16 class body

	; [#82] (unnamed)  class 0160:0020 = KN5000 widget type 0x20, 44 bytes, parent #78 HDD_FILE_NAMING,
	; box 281,118-311,135.  Record layout and evidence: pool header above.
HdaeUiObj_082:
	.long	0x01600020				; +0x00 class id
	.short	78, 83, 84, 81	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	281, 118, 311, 135			; +0x0E box x1, y1, x2, y2
	.short	0x00f2, 0x00c1, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x000a	; +0x16 class body
	.short	0x0000, 0x0001, 0x012a	; +0x26 class body

	; [#83] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #82,
	; box 282,119-309,137.  Record layout and evidence: pool header above.
HdaeUiObj_083:
	.long	0x0160002b				; +0x00 class id
	.short	82, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	282, 119, 309, 137			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_083_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_083: the record's +0x16 caption pointer names this string
HdaeUiObj_083_Cap16:	.asciz	"OPT"

	; [#84] (unnamed)  class 016A:0004 = ClassName_Table[4] "IvHddNamingProc", 26 bytes, parent #78 HDD_FILE_NAMING,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_084:
	.long	0x016a0004				; +0x00 class id
	.short	78, 0xffff, 85, 82	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0001, 0x012a	; +0x16 class body

	; [#85] (unnamed)  class 0160:0020 = KN5000 widget type 0x20, 44 bytes, parent #78 HDD_FILE_NAMING,
	; box 8,118-38,135.  Record layout and evidence: pool header above.
HdaeUiObj_085:
	.long	0x01600020				; +0x00 class id
	.short	78, 86, 0xffff, 84	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 118, 38, 135			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c1, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x008a	; +0x16 class body
	.short	0x0000, 0x0001, 0x012a	; +0x26 class body

	; [#86] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #85,
	; box 9,119-36,137.  Record layout and evidence: pool header above.
HdaeUiObj_086:
	.long	0x0160002b				; +0x00 class id
	.short	85, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	9, 119, 36, 137			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_086_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x00f9	; +0x1A class body
	; caption of HdaeUiObj_086: the record's +0x16 caption pointer names this string
HdaeUiObj_086_Cap16:	.asciz	"LST"

	; [#87] "HD_FILE_NAME"  class 0160:004B = KN5000 widget type 0x4B, 36 bytes, parent none (root),
	; box 40,96-267,199.  Record layout and evidence: pool header above.
HdaeUiObj_087:
	.long	0x0160004b				; +0x00 class id
	.short	0xffff, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 96, 267, 199			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c1, 0x0000	; +0x16 class body
	.long	0x0023993c				; +0x1C RAM address (every 0160:004B record)
	.long	0x00239940				; +0x20 RAM address (every 0160:004B record)

	; [#88] "HDD_DIR_NAMING"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 62 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_088:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 89, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x007f, 0x01a0	; +0x16 class body
	.long	0x00239944				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_088_Cap22			; +0x22 caption pointer
	.short	0x00ad, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_088: the record's +0x22 caption pointer names this string
HdaeUiObj_088_Cap22:	.asciz	"EDIT DIRECTORY NAME"

	; [#89] (unnamed)  class 0160:004D = KN5000 widget type 0x4D, 26 bytes, parent #88 HDD_DIR_NAMING,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_089:
	.long	0x0160004d				; +0x00 class id
	.short	88, 0xffff, 90, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0002, 0x012a	; +0x16 class body

	; [#90] (unnamed)  class 0160:0020 = KN5000 widget type 0x20, 44 bytes, parent #88 HDD_DIR_NAMING,
	; box 281,160-311,177.  Record layout and evidence: pool header above.
HdaeUiObj_090:
	.long	0x01600020				; +0x00 class id
	.short	88, 0xffff, 91, 89	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	281, 160, 311, 177			; +0x0E box x1, y1, x2, y2
	.short	0x00f2, 0x00c1, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x000b	; +0x16 class body
	.short	0x0006, 0x0002, 0x012a	; +0x26 class body

	; [#91] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #88 HDD_DIR_NAMING,
	; box 0,32-31,63.  Record layout and evidence: pool header above.
HdaeUiObj_091:
	.long	0x01600049				; +0x00 class id
	.short	88, 0xffff, 92, 90	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 32, 31, 63			; +0x0E box x1, y1, x2, y2
	.short	0x0022, 0x007f	; +0x16 class body

	; [#92] (unnamed)  class 0160:0020 = KN5000 widget type 0x20, 44 bytes, parent #88 HDD_DIR_NAMING,
	; box 8,118-38,135.  Record layout and evidence: pool header above.
HdaeUiObj_092:
	.long	0x01600020				; +0x00 class id
	.short	88, 93, 0xffff, 91	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 118, 38, 135			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c1, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x008a	; +0x16 class body
	.short	0x0000, 0x0002, 0x012a	; +0x26 class body

	; [#93] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #92,
	; box 9,119-36,137.  Record layout and evidence: pool header above.
HdaeUiObj_093:
	.long	0x0160002b				; +0x00 class id
	.short	92, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	9, 119, 36, 137			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_093_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x00f9	; +0x1A class body
	; caption of HdaeUiObj_093: the record's +0x16 caption pointer names this string
HdaeUiObj_093_Cap16:	.asciz	"LST"

	; [#94] "HD_PLEASE_WIN"  class 0160:0035 = KN5000 widget type 0x35, 36 bytes, parent none (root),
	; box 60,84-259,131.  Record layout and evidence: pool header above.
HdaeUiObj_094:
	.long	0x01600035				; +0x00 class id
	.short	0xffff, 95, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	60, 84, 259, 131			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c1, 0x0000	; +0x16 class body
	.long	0x00239948				; +0x1C RAM address (every 0160:0035 record)
	.long	0x0023994c				; +0x20 RAM address (every 0160:0035 record)

	; [#95] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 46 bytes, parent #94 HD_PLEASE_WIN,
	; box 110,98-209,116.  Record layout and evidence: pool header above.
HdaeUiObj_095:
	.long	0x0160002b				; +0x00 class id
	.short	94, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	110, 98, 209, 116			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_095_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_095: the record's +0x16 caption pointer names this string
HdaeUiObj_095_Cap16:	.asciz	"PLEASE WAIT!"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#96] "HD_UTIL"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 54 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_096:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 97, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239950				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_096_Cap22			; +0x22 caption pointer
	.short	0x0083, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_096: the record's +0x22 caption pointer names this string
HdaeUiObj_096_Cap22:	.asciz	"HD UTILITY"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#97] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #96 HD_UTIL,
	; box 32,0-63,31.  Record layout and evidence: pool header above.
HdaeUiObj_097:
	.long	0x01600049				; +0x00 class id
	.short	96, 0xffff, 98, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	32, 0, 63, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0013, 0x007f	; +0x16 class body

	; [#98] (unnamed)  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #96 HD_UTIL,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_098:
	.long	0x01600052				; +0x00 class id
	.short	96, 0xffff, 99, 97	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0003, 0x012a	; +0x16 class body

	; [#99] (unnamed)  class 0160:0046 = KN5000 widget type 0x46, 22 bytes, parent #96 HD_UTIL,
	; box 0,32-170,239.  Record layout and evidence: pool header above.
HdaeUiObj_099:
	.long	0x01600046				; +0x00 class id
	.short	96, 0xffff, 100, 98	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	0, 32, 170, 239			; +0x0E box x1, y1, x2, y2

	; [#100] (unnamed)  class 0160:003D = KN5000 widget type 0x3D, 58 bytes, parent #96 HD_UTIL,
	; box 163,72-311,97.  Record layout and evidence: pool header above.
HdaeUiObj_100:
	.long	0x0160003d				; +0x00 class id
	.short	96, 0xffff, 101, 99	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	163, 72, 311, 97			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000, 0x0009	; +0x16 class body
	.long	0x00239954				; +0x26 RAM address (every 0160:003D record)
	.long	HdaeUiObj_100_Cap2A			; +0x2A caption pointer
	.short	0x0083, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_100: the record's +0x2A caption pointer names this string
HdaeUiObj_100_Cap2A:	.asciz	"FORMAT"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#101] (unnamed)  class 0160:003D = KN5000 widget type 0x3D, 58 bytes, parent #96 HD_UTIL,
	; box 163,156-311,181.  Record layout and evidence: pool header above.
HdaeUiObj_101:
	.long	0x0160003d				; +0x00 class id
	.short	96, 0xffff, 0xffff, 100	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	163, 156, 311, 181			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000, 0x000b	; +0x16 class body
	.long	0x00239956				; +0x26 RAM address (every 0160:003D record)
	.long	HdaeUiObj_101_Cap2A			; +0x2A caption pointer
	.short	0x0083, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_101: the record's +0x2A caption pointer names this string
HdaeUiObj_101_Cap2A:	.asciz	"READ ID"

	; [#102] "PC_DATA_LINK"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 58 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_102:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 103, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239958				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_102_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_102: the record's +0x22 caption pointer names this string
HdaeUiObj_102_Cap22:	.asciz	"   PC DATA LINK"

	; [#103] (unnamed)  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #102 PC_DATA_LINK,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_103:
	.long	0x01600052				; +0x00 class id
	.short	102, 0xffff, 104, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0004, 0x012a	; +0x16 class body

	; [#104] "PP_STATUS"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #102 PC_DATA_LINK,
	; box 20,84-299,131.  Record layout and evidence: pool header above.
HdaeUiObj_104:
	.long	0x016a0000				; +0x00 class id
	.short	102, 0xffff, 105, 103	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	20, 84, 299, 131			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000, 0x0140	; +0x16 class body
	.long	0x0023995c				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x2A class body
	.long	0x00239960				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x00239962				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#105] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #102 PC_DATA_LINK,
	; box 244,216-315,238.  Record layout and evidence: pool header above.
HdaeUiObj_105:
	.long	0x01600022				; +0x00 class id
	.short	102, 106, 107, 104	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 216, 315, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0007, 0x0000	; +0x26 class body

	; [#106] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 40 bytes, parent #105,
	; box 254,219-305,237.  Record layout and evidence: pool header above.
HdaeUiObj_106:
	.long	0x0160002b				; +0x00 class id
	.short	105, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	254, 219, 305, 237			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_106_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_106: the record's +0x16 caption pointer names this string
HdaeUiObj_106_Cap16:	.asciz	"CANCEL"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#107] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #102 PC_DATA_LINK,
	; box 4,216-75,238.  Record layout and evidence: pool header above.
HdaeUiObj_107:
	.long	0x01600022				; +0x00 class id
	.short	102, 108, 109, 105	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 216, 75, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000	; +0x16 class body
	.short	0x0001, 0x0000	; +0x26 class body

	; [#108] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #107,
	; box 18,219-61,237.  Record layout and evidence: pool header above.
HdaeUiObj_108:
	.long	0x0160002b				; +0x00 class id
	.short	107, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	18, 219, 61, 237			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_108_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_108: the record's +0x16 caption pointer names this string
HdaeUiObj_108_Cap16:	.asciz	"START"

	; [#109] (unnamed)  class 0160:0069 = KN5000 widget type 0x69, 26 bytes, parent #102 PC_DATA_LINK,
	; box 76,1-102,27.  Record layout and evidence: pool header above.
HdaeUiObj_109:
	.long	0x01600069				; +0x00 class id
	.short	102, 0xffff, 0xffff, 107	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	76, 1, 102, 27			; +0x0E box x1, y1, x2, y2
	.short	0x0027, 0x012a	; +0x16 class body

	; [#110] "SETUP_TOOLS_P1"  class 0160:0035 = KN5000 widget type 0x35, 36 bytes, parent none (root),
	; box 64,90-282,189.  Record layout and evidence: pool header above.
HdaeUiObj_110:
	.long	0x01600035				; +0x00 class id
	.short	0xffff, 111, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	64, 90, 282, 189			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0000	; +0x16 class body
	.long	0x00239964				; +0x1C RAM address (every 0160:0035 record)
	.long	0x00239968				; +0x20 RAM address (every 0160:0035 record)

	; [#111] (unnamed)  class 0160:0041 = KN5000 widget type 0x41, 68 bytes, parent #110 SETUP_TOOLS_P1,
	; box 163,156-311,181.  Record layout and evidence: pool header above.
HdaeUiObj_111:
	.long	0x01600041				; +0x00 class id
	.short	110, 112, 113, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	163, 156, 311, 181			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000, 0x000b	; +0x16 class body
	.long	0x0023996c				; +0x26 RAM address (every 0160:0041 record)
	.long	HdaeUiObj_111_Cap2A			; +0x2A caption pointer
	.short	0x0066, 0x007f, 0x0083, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_111: the record's +0x2A caption pointer names this string
HdaeUiObj_111_Cap2A:	.asciz	"PC DATA LINK"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#112] (unnamed)  class 0160:0069 = KN5000 widget type 0x69, 26 bytes, parent #111,
	; box 283,155-309,181.  Record layout and evidence: pool header above.
HdaeUiObj_112:
	.long	0x01600069				; +0x00 class id
	.short	111, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	283, 155, 309, 181			; +0x0E box x1, y1, x2, y2
	.short	0x0027, 0x012a	; +0x16 class body

	; [#113] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #110 SETUP_TOOLS_P1,
	; box 244,216-315,238.  Record layout and evidence: pool header above.
HdaeUiObj_113:
	.long	0x01600022				; +0x00 class id
	.short	110, 0xffff, 114, 111	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 216, 315, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0007, 0x0003	; +0x26 class body

	; [#114] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 60 bytes, parent #110 SETUP_TOOLS_P1,
	; box 8,72-163,97.  Record layout and evidence: pool header above.
HdaeUiObj_114:
	.long	0x0160001b				; +0x00 class id
	.short	110, 115, 116, 113	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 72, 163, 97			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0000	; +0x16 class body
	.long	HdaeUiObj_114_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0002, 0x0004, 0x0089, 0x0001	; +0x20 class body
	.long	0x0023996e				; +0x2E RAM address (every 0160:001B record)
	.short	0x0011, 0x012a	; +0x32 class body
	.long	0x00239970				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_114: the record's +0x1C caption pointer names this string
HdaeUiObj_114_Cap1C:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#115] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #114,
	; box 8,72-128,103.  Record layout and evidence: pool header above.
HdaeUiObj_115:
	.long	0x016a000a				; +0x00 class id
	.short	114, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 72, 128, 103			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0008, 0x0000, 0x0000, 0x00ff, 0x0001, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#116] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 74 bytes, parent #110 SETUP_TOOLS_P1,
	; box 8,156-156,181.  Record layout and evidence: pool header above.
HdaeUiObj_116:
	.long	0x0160001b				; +0x00 class id
	.short	110, 0xffff, 117, 114	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 156, 156, 181			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0000	; +0x16 class body
	.long	HdaeUiObj_116_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0002, 0x008b, 0x0001	; +0x20 class body
	.long	0x00239974				; +0x2E RAM address (every 0160:001B record)
	.short	0x0013, 0x012a	; +0x32 class body
	.long	0x00239976				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_116: the record's +0x1C caption pointer names this string
HdaeUiObj_116_Cap1C:	.asciz	"QUICK LD MODE:"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#117] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 74 bytes, parent #110 SETUP_TOOLS_P1,
	; box 163,72-311,97.  Record layout and evidence: pool header above.
HdaeUiObj_117:
	.long	0x0160001b				; +0x00 class id
	.short	110, 0xffff, 118, 116	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	163, 72, 311, 97			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0000	; +0x16 class body
	.long	HdaeUiObj_117_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0002, 0x0009, 0x0001	; +0x20 class body
	.long	0x0023997a				; +0x2E RAM address (every 0160:001B record)
	.short	0x0015, 0x012a	; +0x32 class body
	.long	0x0023997c				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_117: the record's +0x1C caption pointer names this string
HdaeUiObj_117_Cap1C:	.asciz	"JUMP AFTER LD.:"

	; [#118] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 60 bytes, parent #110 SETUP_TOOLS_P1,
	; box 8,114-163,139.  Record layout and evidence: pool header above.
HdaeUiObj_118:
	.long	0x0160001b				; +0x00 class id
	.short	110, 119, 120, 117	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 114, 163, 139			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0000	; +0x16 class body
	.long	HdaeUiObj_118_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0002, 0x0004, 0x008a, 0x0001	; +0x20 class body
	.long	0x00239980				; +0x2E RAM address (every 0160:001B record)
	.short	0x0012, 0x012a	; +0x32 class body
	.long	0x00239982				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_118: the record's +0x1C caption pointer names this string
HdaeUiObj_118_Cap1C:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#119] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #118,
	; box 8,114-128,145.  Record layout and evidence: pool header above.
HdaeUiObj_119:
	.long	0x016a000a				; +0x00 class id
	.short	118, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 114, 128, 145			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0009, 0x0000, 0x0000, 0x00ff, 0x0001, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#120] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 74 bytes, parent #110 SETUP_TOOLS_P1,
	; box 8,198-156,223.  Record layout and evidence: pool header above.
HdaeUiObj_120:
	.long	0x0160001b				; +0x00 class id
	.short	110, 0xffff, 121, 118	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 198, 156, 223			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0000	; +0x16 class body
	.long	HdaeUiObj_120_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0002, 0x008c, 0x0001	; +0x20 class body
	.long	0x00239986				; +0x2E RAM address (every 0160:001B record)
	.short	0x0014, 0x012a	; +0x32 class body
	.long	0x00239988				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_120: the record's +0x1C caption pointer names this string
HdaeUiObj_120_Cap1C:	.asciz	"LD BY NUM. M.:"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#121] (unnamed)  class 0160:0041 = KN5000 widget type 0x41, 70 bytes, parent #110 SETUP_TOOLS_P1,
	; box 163,114-311,139.  Record layout and evidence: pool header above.
HdaeUiObj_121:
	.long	0x01600041				; +0x00 class id
	.short	110, 0xffff, 0xffff, 120	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	163, 114, 311, 139			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000, 0x000a	; +0x16 class body
	.long	0x0023998c				; +0x26 RAM address (every 0160:0041 record)
	.long	HdaeUiObj_121_Cap2A			; +0x2A caption pointer
	.short	0x030c, 0x007f, 0x003c, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_121: the record's +0x2A caption pointer names this string
HdaeUiObj_121_Cap2A:	.asciz	"LYRICS OPTIONS"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#122] "SETUP_TOOLS_P2"  class 0160:0035 = KN5000 widget type 0x35, 36 bytes, parent none (root),
	; box 60,84-259,131.  Record layout and evidence: pool header above.
HdaeUiObj_122:
	.long	0x01600035				; +0x00 class id
	.short	0xffff, 123, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	60, 84, 259, 131			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0000	; +0x16 class body
	.long	0x0023998e				; +0x1C RAM address (every 0160:0035 record)
	.long	0x00239992				; +0x20 RAM address (every 0160:0035 record)

	; [#123] (unnamed)  class 0160:0041 = KN5000 widget type 0x41, 56 bytes, parent #122 SETUP_TOOLS_P2,
	; box 8,198-127,223.  Record layout and evidence: pool header above.
HdaeUiObj_123:
	.long	0x01600041				; +0x00 class id
	.short	122, 124, 125, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 198, 127, 223			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x008c	; +0x16 class body
	.long	0x00239996				; +0x26 RAM address (every 0160:0041 record)
	.long	HdaeUiObj_123_Cap2A			; +0x2A caption pointer
	.short	0xffff, 0xffff, 0x0000, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_123: the record's +0x2A caption pointer names this string
HdaeUiObj_123_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#124] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #123,
	; box 6,198-129,229.  Record layout and evidence: pool header above.
HdaeUiObj_124:
	.long	0x016a000a				; +0x00 class id
	.short	123, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	6, 198, 129, 229			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x000b, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#125] (unnamed)  class 0160:0041 = KN5000 widget type 0x41, 68 bytes, parent #122 SETUP_TOOLS_P2,
	; box 163,198-311,223.  Record layout and evidence: pool header above.
HdaeUiObj_125:
	.long	0x01600041				; +0x00 class id
	.short	122, 126, 127, 123	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	163, 198, 311, 223			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000, 0x000c	; +0x16 class body
	.long	0x00239998				; +0x26 RAM address (every 0160:0041 record)
	.long	HdaeUiObj_125_Cap2A			; +0x2A caption pointer
	.short	0xffff, 0xffff, 0x0001, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_125: the record's +0x2A caption pointer names this string
HdaeUiObj_125_Cap2A:	.asciz	"HD-AE INFOS  "

	; [#126] (unnamed)  class 0160:0069 = KN5000 widget type 0x69, 26 bytes, parent #125,
	; box 283,197-309,223.  Record layout and evidence: pool header above.
HdaeUiObj_126:
	.long	0x01600069				; +0x00 class id
	.short	125, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	283, 197, 309, 223			; +0x0E box x1, y1, x2, y2
	.short	0x0027, 0x012a	; +0x16 class body

	; [#127] (unnamed)  class 0160:0029 = KN5000 widget type 0x29, 40 bytes, parent #122 SETUP_TOOLS_P2,
	; box 0,64-31,95.  Record layout and evidence: pool header above.
HdaeUiObj_127:
	.long	0x01600029				; +0x00 class id
	.short	122, 0xffff, 128, 125	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 64, 31, 95			; +0x0E box x1, y1, x2, y2
	.short	0x0004, 0x014a	; +0x16 class body
HdaeUiObj_127_Str1A:	.asciz	"! HD FORMAT !"

	; [#129] (unnamed)  class 0160:0069 = KN5000 widget type 0x69, 26 bytes, parent #128 SW_HD_FORMAT,
	; box 283,71-309,97.  Record layout and evidence: pool header above.
HdaeUiObj_129:
	.long	0x01600069				; +0x00 class id
	.short	128, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	283, 71, 309, 97			; +0x0E box x1, y1, x2, y2
	.short	0x0027, 0x012a	; +0x16 class body

	; [#130] (unnamed)  class 0160:0041 = KN5000 widget type 0x41, 56 bytes, parent #122 SETUP_TOOLS_P2,
	; box 163,156-311,181.  Record layout and evidence: pool header above.
HdaeUiObj_130:
	.long	0x01600041				; +0x00 class id
	.short	122, 131, 0xffff, 128	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	163, 156, 311, 181			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000, 0x000b	; +0x16 class body
	.long	0x0023999c				; +0x26 RAM address (every 0160:0041 record)
	.long	HdaeUiObj_130_Cap2A			; +0x2A caption pointer
	.short	0x0281, 0x007f, 0x0001, 0x0000	; +0x2E class body
	; caption of HdaeUiObj_130: the record's +0x2A caption pointer names this string
HdaeUiObj_130_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#131] (unnamed)  class 0160:0069 = KN5000 widget type 0x69, 26 bytes, parent #130,
	; box 283,155-309,181.  Record layout and evidence: pool header above.
HdaeUiObj_131:
	.long	0x01600069				; +0x00 class id
	.short	130, 0xffff, 132, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	283, 155, 309, 181			; +0x0E box x1, y1, x2, y2
	.short	0x0027, 0x012a	; +0x16 class body

	; [#132] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #130,
	; box 169,156-293,187.  Record layout and evidence: pool header above.
HdaeUiObj_132:
	.long	0x016a000a				; +0x00 class id
	.short	130, 0xffff, 0xffff, 131	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	169, 156, 293, 187			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x000a, 0x0000, 0x0000, 0x00ff, 0x0001, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#133] "OUTPUT_SETTING"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 58 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_133:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 134, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x0023999e				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_133_Cap22			; +0x22 caption pointer
	.short	0x0021, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_133: the record's +0x22 caption pointer names this string
HdaeUiObj_133_Cap22:	.asciz	"OUTPUT SETTING"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#134] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #133 OUTPUT_SETTING,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_134:
	.long	0x01600049				; +0x00 class id
	.short	133, 0xffff, 135, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x007f	; +0x16 class body

	; [#135] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #133 OUTPUT_SETTING,
	; box 244,216-315,238.  Record layout and evidence: pool header above.
HdaeUiObj_135:
	.long	0x01600022				; +0x00 class id
	.short	133, 0xffff, 136, 134	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 216, 315, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0007, 0x0003	; +0x26 class body

	; [#136] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 60 bytes, parent #133 OUTPUT_SETTING,
	; box 12,72-311,97.  Record layout and evidence: pool header above.
HdaeUiObj_136:
	.long	0x0160001b				; +0x00 class id
	.short	133, 0xffff, 137, 135	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	12, 72, 311, 97			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0000	; +0x16 class body
	.long	HdaeUiObj_136_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0002, 0x0010, 0x0089, 0x0001	; +0x20 class body
	.long	0x002399a2				; +0x2E RAM address (every 0160:001B record)
	.short	0x0005, 0x012a	; +0x32 class body
	.long	0x002399a4				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_136: the record's +0x1C caption pointer names this string
HdaeUiObj_136_Cap1C:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#137] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 60 bytes, parent #133 OUTPUT_SETTING,
	; box 12,114-311,139.  Record layout and evidence: pool header above.
HdaeUiObj_137:
	.long	0x0160001b				; +0x00 class id
	.short	133, 0xffff, 138, 136	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	12, 114, 311, 139			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0000	; +0x16 class body
	.long	HdaeUiObj_137_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0002, 0x0006, 0x008a, 0x0001	; +0x20 class body
	.long	0x002399a8				; +0x2E RAM address (every 0160:001B record)
	.short	0x003c, 0x012a	; +0x32 class body
	.long	0x002399aa				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_137: the record's +0x1C caption pointer names this string
HdaeUiObj_137_Cap1C:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#138] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 60 bytes, parent #133 OUTPUT_SETTING,
	; box 12,156-311,181.  Record layout and evidence: pool header above.
HdaeUiObj_138:
	.long	0x0160001b				; +0x00 class id
	.short	133, 0xffff, 139, 137	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	12, 156, 311, 181			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0000	; +0x16 class body
	.long	HdaeUiObj_138_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0002, 0x0006, 0x008b, 0x0001	; +0x20 class body
	.long	0x002399ae				; +0x2E RAM address (every 0160:001B record)
	.short	0x003d, 0x012a	; +0x32 class body
	.long	0x002399b0				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_138: the record's +0x1C caption pointer names this string
HdaeUiObj_138_Cap1C:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#139] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #133 OUTPUT_SETTING,
	; box 12,72-201,103.  Record layout and evidence: pool header above.
HdaeUiObj_139:
	.long	0x016a000a				; +0x00 class id
	.short	133, 0xffff, 140, 138	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	12, 72, 201, 103			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x000d, 0x0000, 0x0000, 0x00ff, 0x0001, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#140] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #133 OUTPUT_SETTING,
	; box 12,114-263,145.  Record layout and evidence: pool header above.
HdaeUiObj_140:
	.long	0x016a000a				; +0x00 class id
	.short	133, 0xffff, 141, 139	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	12, 114, 263, 145			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x000e, 0x0000, 0x0000, 0x00ff, 0x0001, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#141] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #133 OUTPUT_SETTING,
	; box 12,156-263,187.  Record layout and evidence: pool header above.
HdaeUiObj_141:
	.long	0x016a000a				; +0x00 class id
	.short	133, 0xffff, 142, 140	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	12, 156, 263, 187			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x000f, 0x0000, 0x0000, 0x00ff, 0x0001, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#142] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #133 OUTPUT_SETTING,
	; box 6,184-230,237.  Record layout and evidence: pool header above.
HdaeUiObj_142:
	.long	0x016a000a				; +0x00 class id
	.short	133, 0xffff, 0xffff, 141	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	6, 184, 230, 237			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0010, 0x0007, 0x0000, 0x00f1, 0x0001, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#143] "LOAD_BY_NUM"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 58 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_143:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 144, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x002399b4				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_143_Cap22			; +0x22 caption pointer
	.short	0x00ae, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_143: the record's +0x22 caption pointer names this string
HdaeUiObj_143_Cap22:	.asciz	"LOAD BY NUMBER"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#144] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #143 LOAD_BY_NUM,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_144:
	.long	0x01600049				; +0x00 class id
	.short	143, 0xffff, 145, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x007f	; +0x16 class body

	; [#145] (unnamed)  class 0160:0028 = KN5000 widget type 0x28, 28 bytes, parent #143 LOAD_BY_NUM,
	; box 0,32-31,63.  Record layout and evidence: pool header above.
HdaeUiObj_145:
	.long	0x01600028				; +0x00 class id
	.short	143, 0xffff, 146, 144	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 32, 31, 63			; +0x0E box x1, y1, x2, y2
	.short	0x0001, 0x0095, 0x007f	; +0x16 class body

	; [#146] (unnamed)  class 0160:0028 = KN5000 widget type 0x28, 28 bytes, parent #143 LOAD_BY_NUM,
	; box 32,32-63,63.  Record layout and evidence: pool header above.
HdaeUiObj_146:
	.long	0x01600028				; +0x00 class id
	.short	143, 0xffff, 147, 145	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	32, 32, 63, 63			; +0x0E box x1, y1, x2, y2
	.short	0x0002, 0x00af, 0x007f	; +0x16 class body

	; [#147] (unnamed)  class 016A:0008 = ClassName_Table[8] "AcWindowPage1Proc", 36 bytes, parent #143 LOAD_BY_NUM,
	; box 245,6-315,23.  Record layout and evidence: pool header above.
HdaeUiObj_147:
	.long	0x016a0008				; +0x00 class id
	.short	143, 0xffff, 148, 146	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	245, 6, 315, 23			; +0x0E box x1, y1, x2, y2
	.short	0x00f3, 0x00c1, 0xffff	; +0x16 class body
	.long	0x002399b8				; +0x1C RAM address (every 016A:0008 record)
	.short	0x0001, 0x0002	; +0x20 class body

	; [#148] (unnamed)  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #143 LOAD_BY_NUM,
	; box 64,32-95,63.  Record layout and evidence: pool header above.
HdaeUiObj_148:
	.long	0x01600052				; +0x00 class id
	.short	143, 0xffff, 0xffff, 147	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	64, 32, 95, 63			; +0x0E box x1, y1, x2, y2
	.short	0x0029, 0x012a	; +0x16 class body

	; [#149] "LBN_P1"  class 0160:0035 = KN5000 widget type 0x35, 36 bytes, parent none (root),
	; box 60,84-259,131.  Record layout and evidence: pool header above.
HdaeUiObj_149:
	.long	0x01600035				; +0x00 class id
	.short	0xffff, 150, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	60, 84, 259, 131			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0000	; +0x16 class body
	.long	0x002399ba				; +0x1C RAM address (every 0160:0035 record)
	.long	0x002399be				; +0x20 RAM address (every 0160:0035 record)

	; [#150] (unnamed)  class 0160:001C = KN5000 widget type 0x1C, 42 bytes, parent #149 LBN_P1,
	; box 263,203-311,220.  Record layout and evidence: pool header above.
HdaeUiObj_150:
	.long	0x0160001c				; +0x00 class id
	.short	149, 151, 152, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	263, 203, 311, 220			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x000c	; +0x16 class body
	.long	0x002399c2				; +0x26 RAM address (every 0160:001C record)

	; [#151] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #150,
	; box 265,204-308,222.  Record layout and evidence: pool header above.
HdaeUiObj_151:
	.long	0x0160002b				; +0x00 class id
	.short	150, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	265, 204, 308, 222			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_151_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_151: the record's +0x16 caption pointer names this string
HdaeUiObj_151_Cap16:	.asciz	"CLEAR"

	; [#152] "LBN_OPTION"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #149 LBN_P1,
	; box 236,91-319,201.  Record layout and evidence: pool header above.
HdaeUiObj_152:
	.long	0x016a0000				; +0x00 class id
	.short	149, 0xffff, 153, 150	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	236, 91, 319, 201			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0x0064, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0140	; +0x16 class body
	.long	0x002399c4				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0009	; +0x2A class body
	.long	0x002399c8				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x002399ca				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#153] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #149 LBN_P1,
	; box 265,36-311,61.  Record layout and evidence: pool header above.
HdaeUiObj_153:
	.long	0x0160001f				; +0x00 class id
	.short	149, 154, 155, 152	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	265, 36, 311, 61			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0008	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#154] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #153,
	; box 270,41-305,59.  Record layout and evidence: pool header above.
HdaeUiObj_154:
	.long	0x0160002b				; +0x00 class id
	.short	153, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	270, 41, 305, 59			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_154_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_154: the record's +0x16 caption pointer names this string
HdaeUiObj_154_Cap16:	.asciz	"LOAD"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#155] (unnamed)  class 0160:0030 = KN5000 widget type 0x30, 44 bytes, parent #149 LBN_P1,
	; box 310,77-319,93.  Record layout and evidence: pool header above.
HdaeUiObj_155:
	.long	0x01600030				; +0x00 class id
	.short	149, 0xffff, 156, 153	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	310, 77, 319, 93			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_155_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x00f4, 0x0009, 0x0000, 0x0120, 0xffff	; +0x1A class body
	; caption of HdaeUiObj_155: the record's +0x16 caption pointer names this string
HdaeUiObj_155_Cap16:	.asciz	"~80"

	; [#156] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #149 LBN_P1,
	; box 313,40-313,79.  Record layout and evidence: pool header above.
HdaeUiObj_156:
	.long	0x0160002e				; +0x00 class id
	.short	149, 0xffff, 157, 155	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	313, 40, 313, 79			; +0x0E box x1, y1, x2, y2
	.short	0x00f4, 0x0001	; +0x16 class body

	; [#157] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #149 LBN_P1,
	; box 4,174-199,238.  Record layout and evidence: pool header above.
HdaeUiObj_157:
	.long	0x01600036				; +0x00 class id
	.short	149, 158, 160, 156	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 174, 199, 238			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_157_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0001, 0x0003	; +0x1E class body
	; caption of HdaeUiObj_157: the record's +0x1A caption pointer names this string
HdaeUiObj_157_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#158] (unnamed)  class 0160:0037 = KN5000 widget type 0x37, 40 bytes, parent #157,
	; box 8,210-34,235.  Record layout and evidence: pool header above.
HdaeUiObj_158:
	.long	0x01600037				; +0x00 class id
	.short	157, 0xffff, 159, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 210, 34, 235			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_158_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0000	; +0x1E class body
	; caption of HdaeUiObj_158: the record's +0x1A caption pointer names this string
HdaeUiObj_158_Cap1A:	.asciz	"0"

	; [#159] (unnamed)  class 0160:0037 = KN5000 widget type 0x37, 40 bytes, parent #157,
	; box 8,179-34,204.  Record layout and evidence: pool header above.
HdaeUiObj_159:
	.long	0x01600037				; +0x00 class id
	.short	157, 0xffff, 0xffff, 158	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 179, 34, 204			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_159_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0000	; +0x1E class body
	; caption of HdaeUiObj_159: the record's +0x1A caption pointer names this string
HdaeUiObj_159_Cap1A:	.asciz	"1"

	; [#160] (unnamed)  class 0160:0037 = KN5000 widget type 0x37, 40 bytes, parent #149 LBN_P1,
	; box 48,210-74,235.  Record layout and evidence: pool header above.
HdaeUiObj_160:
	.long	0x01600037				; +0x00 class id
	.short	149, 0xffff, 161, 157	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 210, 74, 235			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_160_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0000	; +0x1E class body
	; caption of HdaeUiObj_160: the record's +0x1A caption pointer names this string
HdaeUiObj_160_Cap1A:	.asciz	"2"

	; [#161] (unnamed)  class 0160:0037 = KN5000 widget type 0x37, 40 bytes, parent #149 LBN_P1,
	; box 48,179-74,204.  Record layout and evidence: pool header above.
HdaeUiObj_161:
	.long	0x01600037				; +0x00 class id
	.short	149, 0xffff, 162, 160	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 179, 74, 204			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_161_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0000	; +0x1E class body
	; caption of HdaeUiObj_161: the record's +0x1A caption pointer names this string
HdaeUiObj_161_Cap1A:	.asciz	"3"

	; [#162] (unnamed)  class 0160:0037 = KN5000 widget type 0x37, 40 bytes, parent #149 LBN_P1,
	; box 88,210-114,235.  Record layout and evidence: pool header above.
HdaeUiObj_162:
	.long	0x01600037				; +0x00 class id
	.short	149, 0xffff, 163, 161	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	88, 210, 114, 235			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_162_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0000	; +0x1E class body
	; caption of HdaeUiObj_162: the record's +0x1A caption pointer names this string
HdaeUiObj_162_Cap1A:	.asciz	"4"

	; [#163] (unnamed)  class 0160:0037 = KN5000 widget type 0x37, 40 bytes, parent #149 LBN_P1,
	; box 88,179-114,204.  Record layout and evidence: pool header above.
HdaeUiObj_163:
	.long	0x01600037				; +0x00 class id
	.short	149, 0xffff, 164, 162	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	88, 179, 114, 204			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_163_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0000	; +0x1E class body
	; caption of HdaeUiObj_163: the record's +0x1A caption pointer names this string
HdaeUiObj_163_Cap1A:	.asciz	"5"

	; [#164] (unnamed)  class 0160:0037 = KN5000 widget type 0x37, 40 bytes, parent #149 LBN_P1,
	; box 128,210-154,235.  Record layout and evidence: pool header above.
HdaeUiObj_164:
	.long	0x01600037				; +0x00 class id
	.short	149, 0xffff, 165, 163	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	128, 210, 154, 235			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_164_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0000	; +0x1E class body
	; caption of HdaeUiObj_164: the record's +0x1A caption pointer names this string
HdaeUiObj_164_Cap1A:	.asciz	"6"

	; [#165] (unnamed)  class 0160:0037 = KN5000 widget type 0x37, 40 bytes, parent #149 LBN_P1,
	; box 128,179-154,204.  Record layout and evidence: pool header above.
HdaeUiObj_165:
	.long	0x01600037				; +0x00 class id
	.short	149, 0xffff, 166, 164	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	128, 179, 154, 204			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_165_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0000	; +0x1E class body
	; caption of HdaeUiObj_165: the record's +0x1A caption pointer names this string
HdaeUiObj_165_Cap1A:	.asciz	"7"

	; [#166] (unnamed)  class 0160:0037 = KN5000 widget type 0x37, 40 bytes, parent #149 LBN_P1,
	; box 168,210-194,235.  Record layout and evidence: pool header above.
HdaeUiObj_166:
	.long	0x01600037				; +0x00 class id
	.short	149, 0xffff, 167, 165	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	168, 210, 194, 235			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_166_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0000	; +0x1E class body
	; caption of HdaeUiObj_166: the record's +0x1A caption pointer names this string
HdaeUiObj_166_Cap1A:	.asciz	"8"

	; [#167] (unnamed)  class 0160:0037 = KN5000 widget type 0x37, 40 bytes, parent #149 LBN_P1,
	; box 168,179-194,204.  Record layout and evidence: pool header above.
HdaeUiObj_167:
	.long	0x01600037				; +0x00 class id
	.short	149, 0xffff, 168, 166	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	168, 179, 194, 204			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_167_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0000	; +0x1E class body
	; caption of HdaeUiObj_167: the record's +0x1A caption pointer names this string
HdaeUiObj_167_Cap1A:	.asciz	"9"

	; [#168] "LBN_DIRNO_BOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #149 LBN_P1,
	; box 6,45-35,66.  Record layout and evidence: pool header above.
HdaeUiObj_168:
	.long	0x016a0000				; +0x00 class id
	.short	149, 0xffff, 169, 167	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	6, 45, 35, 66			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0x0064, 0x0000, 0x0000, 0x00ff, 0x0000, 0x0140	; +0x16 class body
	.long	0x002399cc				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x2A class body
	.long	0x002399d0				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x002399d2				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#169] "LBN_DIRNAME_BOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #149 LBN_P1,
	; box 34,45-249,66.  Record layout and evidence: pool header above.
HdaeUiObj_169:
	.long	0x016a0000				; +0x00 class id
	.short	149, 0xffff, 170, 168	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	34, 45, 249, 66			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0x0064, 0x0000, 0x0000, 0x00ff, 0x0000, 0x0140	; +0x16 class body
	.long	0x002399d4				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x2A class body
	.long	0x002399d8				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x002399da				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#170] "LBN_FILENO_BOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #149 LBN_P1,
	; box 6,68-35,89.  Record layout and evidence: pool header above.
HdaeUiObj_170:
	.long	0x016a0000				; +0x00 class id
	.short	149, 0xffff, 171, 169	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	6, 68, 35, 89			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0x0064, 0x0000, 0x0000, 0x00ff, 0x0000, 0x0140	; +0x16 class body
	.long	0x002399dc				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x2A class body
	.long	0x002399e0				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x002399e2				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#171] "LBN_FILENAME_BOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #149 LBN_P1,
	; box 34,68-249,89.  Record layout and evidence: pool header above.
HdaeUiObj_171:
	.long	0x016a0000				; +0x00 class id
	.short	149, 0xffff, 172, 170	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	34, 68, 249, 89			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0x0064, 0x0000, 0x0000, 0x00f2, 0x0000, 0x0140	; +0x16 class body
	.long	0x002399e4				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x2A class body
	.long	0x002399e8				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x002399ea				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#172] (unnamed)  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #149 LBN_P1,
	; box 0,96-31,127.  Record layout and evidence: pool header above.
HdaeUiObj_172:
	.long	0x01600052				; +0x00 class id
	.short	149, 0xffff, 173, 171	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 96, 31, 127			; +0x0E box x1, y1, x2, y2
	.short	0x0028, 0x012a	; +0x16 class body

	; [#173] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #149 LBN_P1,
	; box 204,221-315,239.  Record layout and evidence: pool header above.
HdaeUiObj_173:
	.long	0x01600022				; +0x00 class id
	.short	149, 0xffff, 174, 172	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	204, 221, 315, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0005	; +0x16 class body
	.short	0x0007, 0x0003	; +0x26 class body

	; [#174] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #149 LBN_P1,
	; box 2,116-211,169.  Record layout and evidence: pool header above.
HdaeUiObj_174:
	.long	0x016a000a				; +0x00 class id
	.short	149, 0xffff, 0xffff, 173	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	2, 116, 211, 169			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0015, 0x0007, 0x0000, 0x00f1, 0x0001, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#175] "LBN_P2"  class 0160:0035 = KN5000 widget type 0x35, 36 bytes, parent none (root),
	; box 8,104-31,155.  Record layout and evidence: pool header above.
HdaeUiObj_175:
	.long	0x01600035				; +0x00 class id
	.short	0xffff, 176, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 104, 31, 155			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0000	; +0x16 class body
	.long	0x002399ec				; +0x1C RAM address (every 0160:0035 record)
	.long	0x002399f0				; +0x20 RAM address (every 0160:0035 record)

	; [#176] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 60 bytes, parent #175 LBN_P2,
	; box 40,47-263,72.  Record layout and evidence: pool header above.
HdaeUiObj_176:
	.long	0x0160001b				; +0x00 class id
	.short	175, 0xffff, 177, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 47, 263, 72			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c1, 0xffff	; +0x16 class body
	.long	HdaeUiObj_176_Cap1C			; +0x1C caption pointer
	.short	0x0005, 0x0000, 0x00ff, 0x0001, 0x0004, 0x00ff, 0x0000	; +0x20 class body
	.long	0x002399f4				; +0x2E RAM address (every 0160:001B record)
	.short	0x002a, 0x012a	; +0x32 class body
	.long	0x002399f6				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_176: the record's +0x1C caption pointer names this string
HdaeUiObj_176_Cap1C:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#177] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #175 LBN_P2,
	; box 48,76-259,91.  Record layout and evidence: pool header above.
HdaeUiObj_177:
	.long	0x0160001b				; +0x00 class id
	.short	175, 0xffff, 178, 176	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 76, 259, 91			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0001	; +0x16 class body
	.long	HdaeUiObj_177_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x002399fa				; +0x2E RAM address (every 0160:001B record)
	.short	0x002b, 0x012a	; +0x32 class body
	.long	0x002399fc				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_177: the record's +0x1C caption pointer names this string
HdaeUiObj_177_Cap1C:	.asciz	"CURRENT PANEL          "
	.set	HDAE5000_Panel_Save_UI, HdaeUiObj_177_Cap1C	; 0x29F9B2
	; MISNOMER retained for cross-reference (the ASL mirror, the symbols
	; reference and six .set bases in hdae5000_init_data.s use this name).
	; RETRACTED: "Panel memory save/load UI strings".  0x29F9B2 is byte
	; +0x3A of object #177 (record 0x29F978-0x29F9C9, 82 bytes, class
	; 0160:001B, a child of object #175 LBN_P2) - it is that ONE object's
	; inline caption, named by the .long at +0x1C of the record, and the
	; nearest record boundary is 0x3A bytes ABOVE this label.  LBN_P2 is a
	; root screen that carries no title of its own; [INFERENCE] "LOAD BY
	; NUMBER page 2", from the abbreviation and from the separate object
	; #143 LOAD_BY_NUM titled "LOAD BY NUMBER".  The six
	; HDAE5000_Str_CharSet_* symbols expressed as offsets from this label
	; are unrelated to it: they live at +0x28..+0x3C of object #442, 0x2CA4
	; bytes further on.  See the pool header at HDAE5000_UI_Descriptors.

	; [#178] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #175 LBN_P2,
	; box 48,91-259,106.  Record layout and evidence: pool header above.
HdaeUiObj_178:
	.long	0x0160001b				; +0x00 class id
	.short	175, 179, 180, 177	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 91, 259, 106			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0002	; +0x16 class body
	.long	HdaeUiObj_178_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239a00				; +0x2E RAM address (every 0160:001B record)
	.short	0x002c, 0x012a	; +0x32 class body
	.long	0x00239a02				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_178: the record's +0x1C caption pointer names this string
HdaeUiObj_178_Cap1C:	.asciz	"PANEL MEMORY           "

	; [#179] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #178,
	; box 40,74-40,198.  Record layout and evidence: pool header above.
HdaeUiObj_179:
	.long	0x0160002e				; +0x00 class id
	.short	178, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 74, 40, 198			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#180] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #175 LBN_P2,
	; box 48,106-259,121.  Record layout and evidence: pool header above.
HdaeUiObj_180:
	.long	0x0160001b				; +0x00 class id
	.short	175, 0xffff, 181, 178	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 106, 259, 121			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0003	; +0x16 class body
	.long	HdaeUiObj_180_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239a06				; +0x2E RAM address (every 0160:001B record)
	.short	0x002d, 0x012a	; +0x32 class body
	.long	0x00239a08				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_180: the record's +0x1C caption pointer names this string
HdaeUiObj_180_Cap1C:	.asciz	"SEQUENCER              "

	; [#181] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #175 LBN_P2,
	; box 48,121-259,136.  Record layout and evidence: pool header above.
HdaeUiObj_181:
	.long	0x0160001b				; +0x00 class id
	.short	175, 0xffff, 182, 180	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 121, 259, 136			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0004	; +0x16 class body
	.long	HdaeUiObj_181_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239a0c				; +0x2E RAM address (every 0160:001B record)
	.short	0x002e, 0x012a	; +0x32 class body
	.long	0x00239a0e				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_181: the record's +0x1C caption pointer names this string
HdaeUiObj_181_Cap1C:	.asciz	"COMPOSER               "

	; [#182] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #175 LBN_P2,
	; box 48,136-259,151.  Record layout and evidence: pool header above.
HdaeUiObj_182:
	.long	0x0160001b				; +0x00 class id
	.short	175, 0xffff, 183, 181	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 136, 259, 151			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0005	; +0x16 class body
	.long	HdaeUiObj_182_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239a12				; +0x2E RAM address (every 0160:001B record)
	.short	0x002f, 0x012a	; +0x32 class body
	.long	0x00239a14				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_182: the record's +0x1C caption pointer names this string
HdaeUiObj_182_Cap1C:	.asciz	"SOUND MEMORY           "

	; [#183] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #175 LBN_P2,
	; box 48,151-259,166.  Record layout and evidence: pool header above.
HdaeUiObj_183:
	.long	0x0160001b				; +0x00 class id
	.short	175, 0xffff, 184, 182	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 151, 259, 166			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0006	; +0x16 class body
	.long	HdaeUiObj_183_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239a18				; +0x2E RAM address (every 0160:001B record)
	.short	0x0030, 0x012a	; +0x32 class body
	.long	0x00239a1a				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_183: the record's +0x1C caption pointer names this string
HdaeUiObj_183_Cap1C:	.asciz	"MSP                    "

	; [#184] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #175 LBN_P2,
	; box 48,166-259,181.  Record layout and evidence: pool header above.
HdaeUiObj_184:
	.long	0x0160001b				; +0x00 class id
	.short	175, 0xffff, 185, 183	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 166, 259, 181			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0007	; +0x16 class body
	.long	HdaeUiObj_184_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239a1e				; +0x2E RAM address (every 0160:001B record)
	.short	0x0031, 0x012a	; +0x32 class body
	.long	0x00239a20				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_184: the record's +0x1C caption pointer names this string
HdaeUiObj_184_Cap1C:	.asciz	"RHYTHM CUSTOM          "

	; [#185] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #175 LBN_P2,
	; box 48,181-259,196.  Record layout and evidence: pool header above.
HdaeUiObj_185:
	.long	0x0160001b				; +0x00 class id
	.short	175, 0xffff, 186, 184	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 181, 259, 196			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0008	; +0x16 class body
	.long	HdaeUiObj_185_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239a24				; +0x2E RAM address (every 0160:001B record)
	.short	0x0032, 0x012a	; +0x32 class body
	.long	0x00239a26				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_185: the record's +0x1C caption pointer names this string
HdaeUiObj_185_Cap1C:	.asciz	"USER MIDI SETTINGS     "

	; [#186] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #175 LBN_P2,
	; box 40,74-263,74.  Record layout and evidence: pool header above.
HdaeUiObj_186:
	.long	0x0160002e				; +0x00 class id
	.short	175, 0xffff, 187, 185	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 74, 263, 74			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#187] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #175 LBN_P2,
	; box 263,74-263,198.  Record layout and evidence: pool header above.
HdaeUiObj_187:
	.long	0x0160002e				; +0x00 class id
	.short	175, 0xffff, 188, 186	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	263, 74, 263, 198			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#188] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #175 LBN_P2,
	; box 40,198-263,198.  Record layout and evidence: pool header above.
HdaeUiObj_188:
	.long	0x0160002e				; +0x00 class id
	.short	175, 0xffff, 189, 187	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 198, 263, 198			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#189] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #175 LBN_P2,
	; box 4,216-35,238.  Record layout and evidence: pool header above.
HdaeUiObj_189:
	.long	0x0160001f				; +0x00 class id
	.short	175, 0xffff, 190, 188	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 216, 35, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#190] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #175 LBN_P2,
	; box 44,216-75,238.  Record layout and evidence: pool header above.
HdaeUiObj_190:
	.long	0x0160001f				; +0x00 class id
	.short	175, 0xffff, 191, 189	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 216, 75, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0002, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#191] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #175 LBN_P2,
	; box 84,216-115,238.  Record layout and evidence: pool header above.
HdaeUiObj_191:
	.long	0x0160001f				; +0x00 class id
	.short	175, 0xffff, 192, 190	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	84, 216, 115, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#192] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #175 LBN_P2,
	; box 124,216-155,238.  Record layout and evidence: pool header above.
HdaeUiObj_192:
	.long	0x0160001f				; +0x00 class id
	.short	175, 0xffff, 193, 191	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	124, 216, 155, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0004, 0x0000, 0x0000, 0x0000, 0x0000, 0x0003	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#193] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #175 LBN_P2,
	; box 164,216-195,238.  Record layout and evidence: pool header above.
HdaeUiObj_193:
	.long	0x0160001f				; +0x00 class id
	.short	175, 0xffff, 194, 192	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	164, 216, 195, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0005, 0x0000, 0x0000, 0x0000, 0x0000, 0x0004	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#194] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #175 LBN_P2,
	; box 244,216-275,238.  Record layout and evidence: pool header above.
HdaeUiObj_194:
	.long	0x0160001f				; +0x00 class id
	.short	175, 0xffff, 195, 193	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 216, 275, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0007, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#195] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #175 LBN_P2,
	; box 284,216-315,238.  Record layout and evidence: pool header above.
HdaeUiObj_195:
	.long	0x0160001f				; +0x00 class id
	.short	175, 0xffff, 196, 194	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	284, 216, 315, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0008, 0x0000, 0x0000, 0x0000, 0x0000, 0x0007	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#196] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #175 LBN_P2,
	; box 204,216-235,238.  Record layout and evidence: pool header above.
HdaeUiObj_196:
	.long	0x0160001f				; +0x00 class id
	.short	175, 0xffff, 197, 195	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	204, 216, 235, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0006, 0x0000, 0x0000, 0x0000, 0x0000, 0x0005	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#197] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #175 LBN_P2,
	; box 9,202-30,212.  Record layout and evidence: pool header above.
HdaeUiObj_197:
	.long	0x0160002b				; +0x00 class id
	.short	175, 0xffff, 198, 196	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	9, 202, 30, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_197_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_197: the record's +0x16 caption pointer names this string
HdaeUiObj_197_Cap16:	.asciz	"PNL"

	; [#198] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #175 LBN_P2,
	; box 42,202-75,212.  Record layout and evidence: pool header above.
HdaeUiObj_198:
	.long	0x0160002b				; +0x00 class id
	.short	175, 0xffff, 199, 197	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	42, 202, 75, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_198_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_198: the record's +0x16 caption pointer names this string
HdaeUiObj_198_Cap16:	.asciz	"P.MEM"

	; [#199] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #175 LBN_P2,
	; box 88,202-109,212.  Record layout and evidence: pool header above.
HdaeUiObj_199:
	.long	0x0160002b				; +0x00 class id
	.short	175, 0xffff, 200, 198	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	88, 202, 109, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_199_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_199: the record's +0x16 caption pointer names this string
HdaeUiObj_199_Cap16:	.asciz	"SEQ"

	; [#200] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #175 LBN_P2,
	; box 126,202-153,212.  Record layout and evidence: pool header above.
HdaeUiObj_200:
	.long	0x0160002b				; +0x00 class id
	.short	175, 0xffff, 201, 199	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	126, 202, 153, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_200_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_200: the record's +0x16 caption pointer names this string
HdaeUiObj_200_Cap16:	.asciz	"COMP"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#201] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #175 LBN_P2,
	; box 162,202-195,212.  Record layout and evidence: pool header above.
HdaeUiObj_201:
	.long	0x0160002b				; +0x00 class id
	.short	175, 0xffff, 202, 200	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	162, 202, 195, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_201_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_201: the record's +0x16 caption pointer names this string
HdaeUiObj_201_Cap16:	.asciz	"SOUND"

	; [#202] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #175 LBN_P2,
	; box 209,202-230,212.  Record layout and evidence: pool header above.
HdaeUiObj_202:
	.long	0x0160002b				; +0x00 class id
	.short	175, 0xffff, 203, 201	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	209, 202, 230, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_202_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_202: the record's +0x16 caption pointer names this string
HdaeUiObj_202_Cap16:	.asciz	"MSP"

	; [#203] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 40 bytes, parent #175 LBN_P2,
	; box 239,202-278,212.  Record layout and evidence: pool header above.
HdaeUiObj_203:
	.long	0x0160002b				; +0x00 class id
	.short	175, 0xffff, 204, 202	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	239, 202, 278, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_203_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_203: the record's +0x16 caption pointer names this string
HdaeUiObj_203_Cap16:	.asciz	"CUSTOM"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#204] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #175 LBN_P2,
	; box 286,202-313,212.  Record layout and evidence: pool header above.
HdaeUiObj_204:
	.long	0x0160002b				; +0x00 class id
	.short	175, 0xffff, 205, 203	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	286, 202, 313, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_204_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_204: the record's +0x16 caption pointer names this string
HdaeUiObj_204_Cap16:	.asciz	"MIDI"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#205] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #175 LBN_P2,
	; box 215,74-215,197.  Record layout and evidence: pool header above.
HdaeUiObj_205:
	.long	0x0160002e				; +0x00 class id
	.short	175, 0xffff, 206, 204	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	215, 74, 215, 197			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#206] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #175 LBN_P2,
	; box 265,36-311,61.  Record layout and evidence: pool header above.
HdaeUiObj_206:
	.long	0x0160001f				; +0x00 class id
	.short	175, 207, 208, 205	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	265, 36, 311, 61			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0008	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#207] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #206,
	; box 270,41-305,59.  Record layout and evidence: pool header above.
HdaeUiObj_207:
	.long	0x0160002b				; +0x00 class id
	.short	206, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	270, 41, 305, 59			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_207_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_207: the record's +0x16 caption pointer names this string
HdaeUiObj_207_Cap16:	.asciz	"LOAD"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#208] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #175 LBN_P2,
	; box 313,40-313,79.  Record layout and evidence: pool header above.
HdaeUiObj_208:
	.long	0x0160002e				; +0x00 class id
	.short	175, 0xffff, 209, 206	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	313, 40, 313, 79			; +0x0E box x1, y1, x2, y2
	.short	0x00f4, 0x0001	; +0x16 class body

	; [#209] (unnamed)  class 0160:0030 = KN5000 widget type 0x30, 44 bytes, parent #175 LBN_P2,
	; box 310,77-319,93.  Record layout and evidence: pool header above.
HdaeUiObj_209:
	.long	0x01600030				; +0x00 class id
	.short	175, 0xffff, 0xffff, 208	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	310, 77, 319, 93			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_209_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x00f4, 0x0009, 0x0000, 0x0120, 0xffff	; +0x1A class body
	; caption of HdaeUiObj_209: the record's +0x16 caption pointer names this string
HdaeUiObj_209_Cap16:	.asciz	"~80"

	; [#210] "CP_FD"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 58 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_210:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 211, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239a2a				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_210_Cap22			; +0x22 caption pointer
	.short	0x0073, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_210: the record's +0x22 caption pointer names this string
HdaeUiObj_210_Cap22:	.asciz	"COPY TECH TO HD"

	; [#211] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #210 CP_FD,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_211:
	.long	0x01600049				; +0x00 class id
	.short	210, 0xffff, 212, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x007f	; +0x16 class body

	; [#212] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #210 CP_FD,
	; box 204,216-235,238.  Record layout and evidence: pool header above.
HdaeUiObj_212:
	.long	0x0160001f				; +0x00 class id
	.short	210, 0xffff, 213, 211	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	204, 216, 235, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0005	; +0x16 class body
	.short	0x0010	; +0x26 class body

	; [#213] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #210 CP_FD,
	; box 44,216-75,238.  Record layout and evidence: pool header above.
HdaeUiObj_213:
	.long	0x0160001f				; +0x00 class id
	.short	210, 0xffff, 214, 212	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 216, 75, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0002, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x000f	; +0x26 class body

	; [#214] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #210 CP_FD,
	; box 84,216-195,238.  Record layout and evidence: pool header above.
HdaeUiObj_214:
	.long	0x01600022				; +0x00 class id
	.short	210, 0xffff, 215, 213	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	84, 216, 195, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0004, 0x0003	; +0x26 class body

	; [#215] "CP_FD_LIST"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #210 CP_FD,
	; box 40,58-239,214.  Record layout and evidence: pool header above.
HdaeUiObj_215:
	.long	0x016a0000				; +0x00 class id
	.short	210, 0xffff, 216, 214	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 58, 239, 214			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0x0000, 0x0000, 0x0000, 0x0000, 0x000a, 0x014a	; +0x16 class body
	.long	0x00239a2e				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0002, 0x000a	; +0x2A class body
	.long	0x00239a32				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x32 class body
	.long	0x00239a34				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0001	; +0x3A class body

	; [#216] "CP_FD_LINE2"  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #210 CP_FD,
	; box 215,60-215,211.  Record layout and evidence: pool header above.
HdaeUiObj_216:
	.long	0x0160002e				; +0x00 class id
	.short	210, 0xffff, 217, 215	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	215, 60, 215, 211			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#217] "CP_FD_LINE1"  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #210 CP_FD,
	; box 118,60-118,212.  Record layout and evidence: pool header above.
HdaeUiObj_217:
	.long	0x0160002e				; +0x00 class id
	.short	210, 0xffff, 218, 216	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	118, 60, 118, 212			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#219] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #218 CP_FD_HDSWTO,
	; box 272,35-307,53.  Record layout and evidence: pool header above.
HdaeUiObj_219:
	.long	0x0160002b				; +0x00 class id
	.short	218, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	272, 35, 307, 53			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_219_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_219: the record's +0x16 caption pointer names this string
HdaeUiObj_219_Cap16:	.asciz	"* TO"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#221] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 40 bytes, parent #220 CP_FD_HDSWSEL,
	; box 267,207-306,217.  Record layout and evidence: pool header above.
HdaeUiObj_221:
	.long	0x0160002b				; +0x00 class id
	.short	220, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	267, 207, 306, 217			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_221_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_221: the record's +0x16 caption pointer names this string
HdaeUiObj_221_Cap16:	.asciz	"SELECT"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#222] "CP_FD_VOLLABEL"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #210 CP_FD,
	; box 142,38-235,53.  Record layout and evidence: pool header above.
HdaeUiObj_222:
	.long	0x016a0000				; +0x00 class id
	.short	210, 0xffff, 223, 220	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	142, 38, 235, 53			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x0000, 0x0064, 0x0000, 0x0000, 0x00f2, 0x0000, 0x0140	; +0x16 class body
	.long	0x00239a36				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x2A class body
	.long	0x00239a3a				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x00239a3c				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#223] (unnamed)  class 0160:0037 = KN5000 widget type 0x37, 48 bytes, parent #210 CP_FD,
	; box 40,36-239,55.  Record layout and evidence: pool header above.
HdaeUiObj_223:
	.long	0x01600037				; +0x00 class id
	.short	210, 0xffff, 224, 222	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 36, 239, 55			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_223_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0001	; +0x1E class body
	; caption of HdaeUiObj_223: the record's +0x1A caption pointer names this string
HdaeUiObj_223_Cap1A:	.asciz	"StringBox"

	; [#225] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 40 bytes, parent #224 CP_FD_HDALLSEL,
	; box 264,165-309,175.  Record layout and evidence: pool header above.
HdaeUiObj_225:
	.long	0x0160002b				; +0x00 class id
	.short	224, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	264, 165, 309, 175			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_225_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_225: the record's +0x16 caption pointer names this string
HdaeUiObj_225_Cap16:	.asciz	"SEL ALL"

	; [#226] "CP_FD_DIRSEL"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 56 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_226:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 227, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239a3e				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_226_Cap22			; +0x22 caption pointer
	.short	0x0073, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_226: the record's +0x22 caption pointer names this string
HdaeUiObj_226_Cap22:	.asciz	"HD DIR SELECT"

	; [#227] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #226 CP_FD_DIRSEL,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_227:
	.long	0x01600049				; +0x00 class id
	.short	226, 0xffff, 228, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x00d2, 0x007f	; +0x16 class body

	; [#228] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #226 CP_FD_DIRSEL,
	; box 269,30-311,55.  Record layout and evidence: pool header above.
HdaeUiObj_228:
	.long	0x0160001f				; +0x00 class id
	.short	226, 229, 230, 227	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	269, 30, 311, 55			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000, 0x0008	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#229] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #228,
	; box 272,35-307,53.  Record layout and evidence: pool header above.
HdaeUiObj_229:
	.long	0x0160002b				; +0x00 class id
	.short	228, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	272, 35, 307, 53			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_229_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_229: the record's +0x16 caption pointer names this string
HdaeUiObj_229_Cap16:	.asciz	"COPY"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#230] "CP_FD_DIRBOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #226 CP_FD_DIRSEL,
	; box 8,35-263,210.  Record layout and evidence: pool header above.
HdaeUiObj_230:
	.long	0x016a0000				; +0x00 class id
	.short	226, 0xffff, 231, 228	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 35, 263, 210			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c1, 0x0000, 0x0003, 0x0000, 0x00ff, 0x000b, 0x014a	; +0x16 class body
	.long	0x00239a42				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0002, 0x000c	; +0x2A class body
	.long	0x00239a46				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x32 class body
	.long	0x00239a48				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#231] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #226 CP_FD_DIRSEL,
	; box 1,222-38,239.  Record layout and evidence: pool header above.
HdaeUiObj_231:
	.long	0x0160003e				; +0x00 class id
	.short	226, 0xffff, 232, 230	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	1, 222, 38, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0000	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_231_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_231: the record's +0x28 caption pointer names this string
HdaeUiObj_231_Cap28:	.asciz	"01-24"

	; [#232] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #226 CP_FD_DIRSEL,
	; box 43,222-80,239.  Record layout and evidence: pool header above.
HdaeUiObj_232:
	.long	0x0160003e				; +0x00 class id
	.short	226, 0xffff, 233, 231	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	43, 222, 80, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0007	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_232_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_232: the record's +0x28 caption pointer names this string
HdaeUiObj_232_Cap28:	.asciz	"25-48"

	; [#233] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #226 CP_FD_DIRSEL,
	; box 84,222-195,239.  Record layout and evidence: pool header above.
HdaeUiObj_233:
	.long	0x01600022				; +0x00 class id
	.short	226, 0xffff, 234, 232	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	84, 222, 195, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0004, 0x0003	; +0x26 class body

	; [#234] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #226 CP_FD_DIRSEL,
	; box 199,222-236,239.  Record layout and evidence: pool header above.
HdaeUiObj_234:
	.long	0x0160003e				; +0x00 class id
	.short	226, 0xffff, 235, 233	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	199, 222, 236, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0007	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_234_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_234: the record's +0x28 caption pointer names this string
HdaeUiObj_234_Cap28:	.asciz	"49-72"

	; [#235] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #226 CP_FD_DIRSEL,
	; box 240,222-277,239.  Record layout and evidence: pool header above.
HdaeUiObj_235:
	.long	0x0160003e				; +0x00 class id
	.short	226, 0xffff, 236, 234	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	240, 222, 277, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0007	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_235_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_235: the record's +0x28 caption pointer names this string
HdaeUiObj_235_Cap28:	.asciz	"73-96"

	; [#236] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 52 bytes, parent #226 CP_FD_DIRSEL,
	; box 281,222-318,239.  Record layout and evidence: pool header above.
HdaeUiObj_236:
	.long	0x0160003e				; +0x00 class id
	.short	226, 0xffff, 237, 235	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	281, 222, 318, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0007	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_236_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_236: the record's +0x28 caption pointer names this string
HdaeUiObj_236_Cap28:	.asciz	"97-120"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#237] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #226 CP_FD_DIRSEL,
	; box 269,194-311,219.  Record layout and evidence: pool header above.
HdaeUiObj_237:
	.long	0x0160001f				; +0x00 class id
	.short	226, 238, 239, 236	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	269, 194, 311, 219			; +0x0E box x1, y1, x2, y2
	.short	0x00f2, 0x00c0, 0x0004, 0x0000, 0x0000, 0x0000, 0x0000, 0x000c	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#238] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #237,
	; box 273,199-308,217.  Record layout and evidence: pool header above.
HdaeUiObj_238:
	.long	0x0160002b				; +0x00 class id
	.short	237, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	273, 199, 308, 217			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_238_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_238: the record's +0x16 caption pointer names this string
HdaeUiObj_238_Cap16:	.asciz	"EDIT"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#239] (unnamed)  class 0160:0029 = KN5000 widget type 0x29, 26 bytes, parent #226 CP_FD_DIRSEL,
	; box 32,0-63,31.  Record layout and evidence: pool header above.
HdaeUiObj_239:
	.long	0x01600029				; +0x00 class id
	.short	226, 0xffff, 0xffff, 237	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	32, 0, 63, 31			; +0x0E box x1, y1, x2, y2
	.short	0x000b, 0x014a	; +0x16 class body

	; [#240] "FLS_SELECT"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 58 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_240:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 241, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239a4a				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_240_Cap22			; +0x22 caption pointer
	.short	0x00af, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_240: the record's +0x22 caption pointer names this string
HdaeUiObj_240_Cap22:	.asciz	" F.L.S. SELECT"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#241] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #240 FLS_SELECT,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_241:
	.long	0x01600049				; +0x00 class id
	.short	240, 0xffff, 242, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x007f	; +0x16 class body

	; [#242] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #240 FLS_SELECT,
	; box 1,222-38,239.  Record layout and evidence: pool header above.
HdaeUiObj_242:
	.long	0x0160003e				; +0x00 class id
	.short	240, 0xffff, 243, 241	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	1, 222, 38, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0000	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_242_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_242: the record's +0x28 caption pointer names this string
HdaeUiObj_242_Cap28:	.asciz	"01-24"

	; [#243] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #240 FLS_SELECT,
	; box 43,222-80,239.  Record layout and evidence: pool header above.
HdaeUiObj_243:
	.long	0x0160003e				; +0x00 class id
	.short	240, 0xffff, 244, 242	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	43, 222, 80, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0007	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_243_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_243: the record's +0x28 caption pointer names this string
HdaeUiObj_243_Cap28:	.asciz	"25-48"

	; [#244] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #240 FLS_SELECT,
	; box 84,222-195,239.  Record layout and evidence: pool header above.
HdaeUiObj_244:
	.long	0x01600022				; +0x00 class id
	.short	240, 0xffff, 245, 243	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	84, 222, 195, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0004, 0x0003	; +0x26 class body

	; [#245] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #240 FLS_SELECT,
	; box 199,222-236,239.  Record layout and evidence: pool header above.
HdaeUiObj_245:
	.long	0x0160003e				; +0x00 class id
	.short	240, 0xffff, 246, 244	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	199, 222, 236, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0007	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_245_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_245: the record's +0x28 caption pointer names this string
HdaeUiObj_245_Cap28:	.asciz	"49-72"

	; [#246] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #240 FLS_SELECT,
	; box 240,222-277,239.  Record layout and evidence: pool header above.
HdaeUiObj_246:
	.long	0x0160003e				; +0x00 class id
	.short	240, 0xffff, 247, 245	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	240, 222, 277, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0007	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_246_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_246: the record's +0x28 caption pointer names this string
HdaeUiObj_246_Cap28:	.asciz	"73-96"

	; [#247] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 52 bytes, parent #240 FLS_SELECT,
	; box 281,222-318,239.  Record layout and evidence: pool header above.
HdaeUiObj_247:
	.long	0x0160003e				; +0x00 class id
	.short	240, 0xffff, 248, 246	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	281, 222, 318, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0007	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_247_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_247: the record's +0x28 caption pointer names this string
HdaeUiObj_247_Cap28:	.asciz	"97-120"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#248] "FLS_SEL"  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #240 FLS_SELECT,
	; box 265,35-311,60.  Record layout and evidence: pool header above.
HdaeUiObj_248:
	.long	0x0160001f				; +0x00 class id
	.short	240, 0xffff, 249, 247	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	265, 35, 311, 60			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000, 0x0008	; +0x16 class body
	.short	0x0006	; +0x26 class body

	; [#250] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #249 FLS_SELECT_SW_EDIT,
	; box 270,202-305,220.  Record layout and evidence: pool header above.
HdaeUiObj_250:
	.long	0x0160002b				; +0x00 class id
	.short	249, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	270, 202, 305, 220			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_250_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_250: the record's +0x16 caption pointer names this string
HdaeUiObj_250_Cap16:	.asciz	"EDIT"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#251] "SEL_FLS"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #240 FLS_SELECT,
	; box 2,34-255,217.  Record layout and evidence: pool header above.
HdaeUiObj_251:
	.long	0x016a0000				; +0x00 class id
	.short	240, 0xffff, 252, 249	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	2, 34, 255, 217			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0x0000, 0x0003, 0x0000, 0x00ff, 0x0005, 0x014a	; +0x16 class body
	.long	0x00239a4e				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0002, 0x000c	; +0x2A class body
	.long	0x00239a52				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x32 class body
	.long	0x00239a54				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#252] (unnamed)  class 0160:0029 = KN5000 widget type 0x29, 26 bytes, parent #240 FLS_SELECT,
	; box 32,0-63,31.  Record layout and evidence: pool header above.
HdaeUiObj_252:
	.long	0x01600029				; +0x00 class id
	.short	240, 0xffff, 253, 251	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	32, 0, 63, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0005, 0x014a	; +0x16 class body

	; [#253] (unnamed)  class 0160:0030 = KN5000 widget type 0x30, 44 bytes, parent #240 FLS_SELECT,
	; box 310,77-321,95.  Record layout and evidence: pool header above.
HdaeUiObj_253:
	.long	0x01600030				; +0x00 class id
	.short	240, 0xffff, 254, 252	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	310, 77, 321, 95			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_253_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x00f4, 0x0009, 0x0000, 0x0120, 0x0006	; +0x1A class body
	; caption of HdaeUiObj_253: the record's +0x16 caption pointer names this string
HdaeUiObj_253_Cap16:	.asciz	"~80"

	; [#254] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #240 FLS_SELECT,
	; box 313,40-313,79.  Record layout and evidence: pool header above.
HdaeUiObj_254:
	.long	0x0160002e				; +0x00 class id
	.short	240, 0xffff, 0xffff, 253	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	313, 40, 313, 79			; +0x0E box x1, y1, x2, y2
	.short	0x00f4, 0x0001	; +0x16 class body

	; [#255] "HD_FILE_LOAD_P1"  class 0160:0035 = KN5000 widget type 0x35, 36 bytes, parent none (root),
	; box 60,80-235,123.  Record layout and evidence: pool header above.
HdaeUiObj_255:
	.long	0x01600035				; +0x00 class id
	.short	0xffff, 256, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	60, 80, 235, 123			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c1, 0x0000	; +0x16 class body
	.long	0x00239a56				; +0x1C RAM address (every 0160:0035 record)
	.long	0x00239a5a				; +0x20 RAM address (every 0160:0035 record)

	; [#257] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #256 HD_FILE_LOAD_SW_SAVE,
	; box 270,204-305,222.  Record layout and evidence: pool header above.
HdaeUiObj_257:
	.long	0x0160002b				; +0x00 class id
	.short	256, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	270, 204, 305, 222			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_257_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_257: the record's +0x16 caption pointer names this string
HdaeUiObj_257_Cap16:	.asciz	"SAVE"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#258] "HD_FILE_OPTION"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #255 HD_FILE_LOAD_P1,
	; box 236,95-320,197.  Record layout and evidence: pool header above.
HdaeUiObj_258:
	.long	0x016a0000				; +0x00 class id
	.short	255, 0xffff, 259, 256	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	236, 95, 320, 197			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0x0064, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0140	; +0x16 class body
	.long	0x00239a5e				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0009	; +0x2A class body
	.long	0x00239a62				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x00239a64				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#259] "HD_FILE_LIST"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #255 HD_FILE_LOAD_P1,
	; box 44,52-235,215.  Record layout and evidence: pool header above.
HdaeUiObj_259:
	.long	0x016a0000				; +0x00 class id
	.short	255, 0xffff, 260, 258	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 52, 235, 215			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0x0000, 0x0003, 0x0000, 0x00ff, 0x0002, 0x014a	; +0x16 class body
	.long	0x00239a66				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0010	; +0x2A class body
	.long	0x00239a6a				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x32 class body
	.long	0x00239a6c				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#260] "FILE_LOAD_DIRBOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #255 HD_FILE_LOAD_P1,
	; box 44,35-235,50.  Record layout and evidence: pool header above.
HdaeUiObj_260:
	.long	0x016a0000				; +0x00 class id
	.short	255, 0xffff, 261, 259	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 35, 235, 50			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0x0064, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0140	; +0x16 class body
	.long	0x00239a6e				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x2A class body
	.long	0x00239a72				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x00239a74				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#261] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #255 HD_FILE_LOAD_P1,
	; box 44,220-75,237.  Record layout and evidence: pool header above.
HdaeUiObj_261:
	.long	0x0160001f				; +0x00 class id
	.short	255, 0xffff, 262, 260	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 220, 75, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0002, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x000f	; +0x26 class body

	; [#262] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #255 HD_FILE_LOAD_P1,
	; box 84,220-195,237.  Record layout and evidence: pool header above.
HdaeUiObj_262:
	.long	0x01600022				; +0x00 class id
	.short	255, 0xffff, 263, 261	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	84, 220, 195, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0004, 0x0003	; +0x26 class body

	; [#263] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #255 HD_FILE_LOAD_P1,
	; box 204,220-235,237.  Record layout and evidence: pool header above.
HdaeUiObj_263:
	.long	0x0160001f				; +0x00 class id
	.short	255, 0xffff, 264, 262	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	204, 220, 235, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0005	; +0x16 class body
	.short	0x0010	; +0x26 class body

	; [#264] (unnamed)  class 0160:002D = KN5000 widget type 0x2D, 26 bytes, parent #255 HD_FILE_LOAD_P1,
	; box 44,0-71,27.  Record layout and evidence: pool header above.
HdaeUiObj_264:
	.long	0x0160002d				; +0x00 class id
	.short	255, 0xffff, 265, 263	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 0, 71, 27			; +0x0E box x1, y1, x2, y2
	.short	0x00ad, 0x0000	; +0x16 class body

	; [#265] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 48 bytes, parent #255 HD_FILE_LOAD_P1,
	; box 78,6-235,24.  Record layout and evidence: pool header above.
HdaeUiObj_265:
	.long	0x0160002b				; +0x00 class id
	.short	255, 0xffff, 266, 264	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	78, 6, 235, 24			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_265_Cap16			; +0x16 caption pointer
	.short	0x0004, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_265: the record's +0x16 caption pointer names this string
HdaeUiObj_265_Cap16:	.asciz	"HD FILE SELECT"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#267] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #266 HD_FILE_LOAD_SW_DEL,
	; box 11,33-32,43.  Record layout and evidence: pool header above.
HdaeUiObj_267:
	.long	0x0160002b				; +0x00 class id
	.short	266, 0xffff, 268, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	11, 33, 32, 43			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_267_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_267: the record's +0x16 caption pointer names this string
HdaeUiObj_267_Cap16:	.asciz	"DEL"

	; [#268] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #266 HD_FILE_LOAD_SW_DEL,
	; box 11,43-32,53.  Record layout and evidence: pool header above.
HdaeUiObj_268:
	.long	0x0160002b				; +0x00 class id
	.short	266, 0xffff, 0xffff, 267	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	11, 43, 32, 53			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_268_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_268: the record's +0x16 caption pointer names this string
HdaeUiObj_268_Cap16:	.asciz	"DIR"

	; [#270] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #269 HD_FILE_LOAD_SW_DELFILE,
	; box 10,117-31,127.  Record layout and evidence: pool header above.
HdaeUiObj_270:
	.long	0x0160002b				; +0x00 class id
	.short	269, 0xffff, 271, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	10, 117, 31, 127			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_270_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_270: the record's +0x16 caption pointer names this string
HdaeUiObj_270_Cap16:	.asciz	"DEL"

	; [#271] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #269 HD_FILE_LOAD_SW_DELFILE,
	; box 10,127-37,137.  Record layout and evidence: pool header above.
HdaeUiObj_271:
	.long	0x0160002b				; +0x00 class id
	.short	269, 0xffff, 0xffff, 270	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	10, 127, 37, 137			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_271_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_271: the record's +0x16 caption pointer names this string
HdaeUiObj_271_Cap16:	.asciz	"FILE"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#272] "HD_FILE_LOAD_P2"  class 0160:0035 = KN5000 widget type 0x35, 36 bytes, parent none (root),
	; box 70,80-249,127.  Record layout and evidence: pool header above.
HdaeUiObj_272:
	.long	0x01600035				; +0x00 class id
	.short	0xffff, 273, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	70, 80, 249, 127			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c1, 0x0000	; +0x16 class body
	.long	0x00239a76				; +0x1C RAM address (every 0160:0035 record)
	.long	0x00239a7a				; +0x20 RAM address (every 0160:0035 record)

	; [#273] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 48 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 78,6-235,24.  Record layout and evidence: pool header above.
HdaeUiObj_273:
	.long	0x0160002b				; +0x00 class id
	.short	272, 0xffff, 274, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	78, 6, 235, 24			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_273_Cap16			; +0x16 caption pointer
	.short	0x0004, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_273: the record's +0x16 caption pointer names this string
HdaeUiObj_273_Cap16:	.asciz	"HD LOAD OPTION"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#274] (unnamed)  class 0160:002D = KN5000 widget type 0x2D, 26 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 44,0-71,27.  Record layout and evidence: pool header above.
HdaeUiObj_274:
	.long	0x0160002d				; +0x00 class id
	.short	272, 0xffff, 275, 273	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 0, 71, 27			; +0x0E box x1, y1, x2, y2
	.short	0x00ad, 0x0000	; +0x16 class body

	; [#275] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 48,52-259,67.  Record layout and evidence: pool header above.
HdaeUiObj_275:
	.long	0x0160001b				; +0x00 class id
	.short	272, 0xffff, 276, 274	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 52, 259, 67			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0001	; +0x16 class body
	.long	HdaeUiObj_275_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239a7e				; +0x2E RAM address (every 0160:001B record)
	.short	0x0008, 0x012a	; +0x32 class body
	.long	0x00239a80				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_275: the record's +0x1C caption pointer names this string
HdaeUiObj_275_Cap1C:	.asciz	"CURRENT PANEL          "

	; [#276] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 4,216-35,238.  Record layout and evidence: pool header above.
HdaeUiObj_276:
	.long	0x0160001f				; +0x00 class id
	.short	272, 0xffff, 277, 275	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 216, 35, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#277] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 9,202-30,212.  Record layout and evidence: pool header above.
HdaeUiObj_277:
	.long	0x0160002b				; +0x00 class id
	.short	272, 0xffff, 278, 276	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	9, 202, 30, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_277_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_277: the record's +0x16 caption pointer names this string
HdaeUiObj_277_Cap16:	.asciz	"PNL"

	; [#278] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 44,216-75,238.  Record layout and evidence: pool header above.
HdaeUiObj_278:
	.long	0x0160001f				; +0x00 class id
	.short	272, 0xffff, 279, 277	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 216, 75, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0002, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#279] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 84,216-115,238.  Record layout and evidence: pool header above.
HdaeUiObj_279:
	.long	0x0160001f				; +0x00 class id
	.short	272, 0xffff, 280, 278	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	84, 216, 115, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#280] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 124,216-155,238.  Record layout and evidence: pool header above.
HdaeUiObj_280:
	.long	0x0160001f				; +0x00 class id
	.short	272, 0xffff, 281, 279	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	124, 216, 155, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0004, 0x0000, 0x0000, 0x0000, 0x0000, 0x0003	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#281] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 164,216-195,238.  Record layout and evidence: pool header above.
HdaeUiObj_281:
	.long	0x0160001f				; +0x00 class id
	.short	272, 0xffff, 282, 280	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	164, 216, 195, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0005, 0x0000, 0x0000, 0x0000, 0x0000, 0x0004	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#282] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 204,216-235,238.  Record layout and evidence: pool header above.
HdaeUiObj_282:
	.long	0x0160001f				; +0x00 class id
	.short	272, 0xffff, 283, 281	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	204, 216, 235, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0006, 0x0000, 0x0000, 0x0000, 0x0000, 0x0005	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#283] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 244,216-275,238.  Record layout and evidence: pool header above.
HdaeUiObj_283:
	.long	0x0160001f				; +0x00 class id
	.short	272, 0xffff, 284, 282	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 216, 275, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0007, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#284] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 284,216-315,238.  Record layout and evidence: pool header above.
HdaeUiObj_284:
	.long	0x0160001f				; +0x00 class id
	.short	272, 0xffff, 285, 283	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	284, 216, 315, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0008, 0x0000, 0x0000, 0x0000, 0x0000, 0x0007	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#285] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 42,202-75,212.  Record layout and evidence: pool header above.
HdaeUiObj_285:
	.long	0x0160002b				; +0x00 class id
	.short	272, 0xffff, 286, 284	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	42, 202, 75, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_285_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_285: the record's +0x16 caption pointer names this string
HdaeUiObj_285_Cap16:	.asciz	"P.MEM"

	; [#286] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 88,202-109,212.  Record layout and evidence: pool header above.
HdaeUiObj_286:
	.long	0x0160002b				; +0x00 class id
	.short	272, 0xffff, 287, 285	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	88, 202, 109, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_286_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_286: the record's +0x16 caption pointer names this string
HdaeUiObj_286_Cap16:	.asciz	"SEQ"

	; [#287] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 126,202-153,212.  Record layout and evidence: pool header above.
HdaeUiObj_287:
	.long	0x0160002b				; +0x00 class id
	.short	272, 0xffff, 288, 286	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	126, 202, 153, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_287_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_287: the record's +0x16 caption pointer names this string
HdaeUiObj_287_Cap16:	.asciz	"COMP"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#288] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 162,202-195,212.  Record layout and evidence: pool header above.
HdaeUiObj_288:
	.long	0x0160002b				; +0x00 class id
	.short	272, 0xffff, 289, 287	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	162, 202, 195, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_288_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_288: the record's +0x16 caption pointer names this string
HdaeUiObj_288_Cap16:	.asciz	"SOUND"

	; [#289] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 209,202-230,212.  Record layout and evidence: pool header above.
HdaeUiObj_289:
	.long	0x0160002b				; +0x00 class id
	.short	272, 0xffff, 290, 288	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	209, 202, 230, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_289_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_289: the record's +0x16 caption pointer names this string
HdaeUiObj_289_Cap16:	.asciz	"MSP"

	; [#290] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 40 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 239,202-278,212.  Record layout and evidence: pool header above.
HdaeUiObj_290:
	.long	0x0160002b				; +0x00 class id
	.short	272, 0xffff, 291, 289	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	239, 202, 278, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_290_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_290: the record's +0x16 caption pointer names this string
HdaeUiObj_290_Cap16:	.asciz	"CUSTOM"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#291] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 286,202-313,212.  Record layout and evidence: pool header above.
HdaeUiObj_291:
	.long	0x0160002b				; +0x00 class id
	.short	272, 0xffff, 292, 290	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	286, 202, 313, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_291_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_291: the record's +0x16 caption pointer names this string
HdaeUiObj_291_Cap16:	.asciz	"MIDI"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#292] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 48,84-259,99.  Record layout and evidence: pool header above.
HdaeUiObj_292:
	.long	0x0160001b				; +0x00 class id
	.short	272, 0xffff, 293, 291	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 84, 259, 99			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0003	; +0x16 class body
	.long	HdaeUiObj_292_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239a84				; +0x2E RAM address (every 0160:001B record)
	.short	0x000a, 0x012a	; +0x32 class body
	.long	0x00239a86				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_292: the record's +0x1C caption pointer names this string
HdaeUiObj_292_Cap1C:	.asciz	"SEQUENCER              "

	; [#293] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 48,100-259,115.  Record layout and evidence: pool header above.
HdaeUiObj_293:
	.long	0x0160001b				; +0x00 class id
	.short	272, 0xffff, 294, 292	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 100, 259, 115			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0004	; +0x16 class body
	.long	HdaeUiObj_293_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239a8a				; +0x2E RAM address (every 0160:001B record)
	.short	0x000b, 0x012a	; +0x32 class body
	.long	0x00239a8c				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_293: the record's +0x1C caption pointer names this string
HdaeUiObj_293_Cap1C:	.asciz	"COMPOSER               "

	; [#294] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 48,116-259,131.  Record layout and evidence: pool header above.
HdaeUiObj_294:
	.long	0x0160001b				; +0x00 class id
	.short	272, 0xffff, 295, 293	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 116, 259, 131			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0005	; +0x16 class body
	.long	HdaeUiObj_294_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239a90				; +0x2E RAM address (every 0160:001B record)
	.short	0x000c, 0x012a	; +0x32 class body
	.long	0x00239a92				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_294: the record's +0x1C caption pointer names this string
HdaeUiObj_294_Cap1C:	.asciz	"SOUND MEMORY           "

	; [#295] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 48,132-259,147.  Record layout and evidence: pool header above.
HdaeUiObj_295:
	.long	0x0160001b				; +0x00 class id
	.short	272, 0xffff, 296, 294	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 132, 259, 147			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0006	; +0x16 class body
	.long	HdaeUiObj_295_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239a96				; +0x2E RAM address (every 0160:001B record)
	.short	0x000d, 0x012a	; +0x32 class body
	.long	0x00239a98				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_295: the record's +0x1C caption pointer names this string
HdaeUiObj_295_Cap1C:	.asciz	"MSP                    "

	; [#296] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 48,148-259,163.  Record layout and evidence: pool header above.
HdaeUiObj_296:
	.long	0x0160001b				; +0x00 class id
	.short	272, 0xffff, 297, 295	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 148, 259, 163			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0007	; +0x16 class body
	.long	HdaeUiObj_296_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239a9c				; +0x2E RAM address (every 0160:001B record)
	.short	0x000e, 0x012a	; +0x32 class body
	.long	0x00239a9e				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_296: the record's +0x1C caption pointer names this string
HdaeUiObj_296_Cap1C:	.asciz	"RHYTHM CUSTOM          "

	; [#297] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 48,180-259,195.  Record layout and evidence: pool header above.
HdaeUiObj_297:
	.long	0x0160001b				; +0x00 class id
	.short	272, 0xffff, 298, 296	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 180, 259, 195			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0009	; +0x16 class body
	.long	HdaeUiObj_297_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239aa2				; +0x2E RAM address (every 0160:001B record)
	.short	0x0010, 0x012a	; +0x32 class body
	.long	0x00239aa4				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_297: the record's +0x1C caption pointer names this string
HdaeUiObj_297_Cap1C:	.asciz	"TECHNICS LYRICS        "

	; [#298] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 42,198-263,198.  Record layout and evidence: pool header above.
HdaeUiObj_298:
	.long	0x0160002e				; +0x00 class id
	.short	272, 0xffff, 299, 297	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	42, 198, 263, 198			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#299] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 60 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 42,24-263,49.  Record layout and evidence: pool header above.
HdaeUiObj_299:
	.long	0x0160001b				; +0x00 class id
	.short	272, 0xffff, 300, 298	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	42, 24, 263, 49			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0xffff	; +0x16 class body
	.long	HdaeUiObj_299_Cap1C			; +0x1C caption pointer
	.short	0x0005, 0x0000, 0x00ff, 0x0001, 0x0004, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239aa8				; +0x2E RAM address (every 0160:001B record)
	.short	0x0007, 0x012a	; +0x32 class body
	.long	0x00239aaa				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_299: the record's +0x1C caption pointer names this string
HdaeUiObj_299_Cap1C:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#300] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 48,68-259,83.  Record layout and evidence: pool header above.
HdaeUiObj_300:
	.long	0x0160001b				; +0x00 class id
	.short	272, 0xffff, 301, 299	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 68, 259, 83			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0002	; +0x16 class body
	.long	HdaeUiObj_300_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239aae				; +0x2E RAM address (every 0160:001B record)
	.short	0x0009, 0x012a	; +0x32 class body
	.long	0x00239ab0				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_300: the record's +0x1C caption pointer names this string
HdaeUiObj_300_Cap1C:	.asciz	"PANEL MEMORY           "

	; [#301] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 263,50-263,197.  Record layout and evidence: pool header above.
HdaeUiObj_301:
	.long	0x0160002e				; +0x00 class id
	.short	272, 0xffff, 302, 300	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	263, 50, 263, 197			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#303] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 6,148-39,158.  Record layout and evidence: pool header above.
HdaeUiObj_303:
	.long	0x0160002b				; +0x00 class id
	.short	272, 0xffff, 304, 302	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	6, 148, 39, 158			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_303_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_303: the record's +0x16 caption pointer names this string
HdaeUiObj_303_Cap16:	.asciz	"LYRIC"

	; [#304] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 48,164-259,179.  Record layout and evidence: pool header above.
HdaeUiObj_304:
	.long	0x0160001b				; +0x00 class id
	.short	272, 0xffff, 305, 303	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 164, 259, 179			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0008	; +0x16 class body
	.long	HdaeUiObj_304_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239ab4				; +0x2E RAM address (every 0160:001B record)
	.short	0x000f, 0x012a	; +0x32 class body
	.long	0x00239ab6				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_304: the record's +0x1C caption pointer names this string
HdaeUiObj_304_Cap1C:	.asciz	"USER MIDI SETTINGS     "

	; [#305] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 213,50-213,197.  Record layout and evidence: pool header above.
HdaeUiObj_305:
	.long	0x0160002e				; +0x00 class id
	.short	272, 0xffff, 306, 304	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	213, 50, 213, 197			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#306] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 42,50-42,197.  Record layout and evidence: pool header above.
HdaeUiObj_306:
	.long	0x0160002e				; +0x00 class id
	.short	272, 0xffff, 307, 305	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	42, 50, 42, 197			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#307] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #272 HD_FILE_LOAD_P2,
	; box 42,50-263,50.  Record layout and evidence: pool header above.
HdaeUiObj_307:
	.long	0x0160002e				; +0x00 class id
	.short	272, 0xffff, 0xffff, 306	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	42, 50, 263, 50			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#308] "HDD_FLS_NAMING"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 56 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_308:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 309, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239aba				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_308_Cap22			; +0x22 caption pointer
	.short	0x00af, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_308: the record's +0x22 caption pointer names this string
HdaeUiObj_308_Cap22:	.asciz	"EDIT FLS NAME"

	; [#309] (unnamed)  class 0160:004D = KN5000 widget type 0x4D, 26 bytes, parent #308 HDD_FLS_NAMING,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_309:
	.long	0x0160004d				; +0x00 class id
	.short	308, 0xffff, 310, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0017, 0x012a	; +0x16 class body

	; [#310] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #308 HDD_FLS_NAMING,
	; box 32,0-63,31.  Record layout and evidence: pool header above.
HdaeUiObj_310:
	.long	0x01600049				; +0x00 class id
	.short	308, 0xffff, 311, 309	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	32, 0, 63, 31			; +0x0E box x1, y1, x2, y2
	.short	0x00f0, 0x007f	; +0x16 class body

	; [#311] (unnamed)  class 0160:0020 = KN5000 widget type 0x20, 44 bytes, parent #308 HDD_FLS_NAMING,
	; box 281,160-311,177.  Record layout and evidence: pool header above.
HdaeUiObj_311:
	.long	0x01600020				; +0x00 class id
	.short	308, 0xffff, 312, 310	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	281, 160, 311, 177			; +0x0E box x1, y1, x2, y2
	.short	0x00f2, 0x00c1, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x000b	; +0x16 class body
	.short	0x0006, 0x0017, 0x012a	; +0x26 class body

	; [#312] (unnamed)  class 0160:0020 = KN5000 widget type 0x20, 44 bytes, parent #308 HDD_FLS_NAMING,
	; box 8,118-38,135.  Record layout and evidence: pool header above.
HdaeUiObj_312:
	.long	0x01600020				; +0x00 class id
	.short	308, 313, 0xffff, 311	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 118, 38, 135			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c1, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x008a	; +0x16 class body
	.short	0x0000, 0x0017, 0x012a	; +0x26 class body

	; [#313] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #312,
	; box 9,119-36,137.  Record layout and evidence: pool header above.
HdaeUiObj_313:
	.long	0x0160002b				; +0x00 class id
	.short	312, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	9, 119, 36, 137			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_313_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x00f9	; +0x1A class body
	; caption of HdaeUiObj_313: the record's +0x16 caption pointer names this string
HdaeUiObj_313_Cap16:	.asciz	"LST"

	; [#314] "FLS_FILE_LOAD"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 60 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_314:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 315, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239abe				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_314_Cap22			; +0x22 caption pointer
	.short	0x00af, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_314: the record's +0x22 caption pointer names this string
HdaeUiObj_314_Cap22:	.asciz	"F.L.S. FILE LOAD"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#315] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #314 FLS_FILE_LOAD,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_315:
	.long	0x01600049				; +0x00 class id
	.short	314, 0xffff, 316, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x00f0, 0x007f	; +0x16 class body

	; [#316] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #314 FLS_FILE_LOAD,
	; box 266,32-311,55.  Record layout and evidence: pool header above.
HdaeUiObj_316:
	.long	0x0160001f				; +0x00 class id
	.short	314, 317, 318, 315	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	266, 32, 311, 55			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000, 0x0008	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#317] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #316,
	; box 270,36-305,54.  Record layout and evidence: pool header above.
HdaeUiObj_317:
	.long	0x0160002b				; +0x00 class id
	.short	316, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	270, 36, 305, 54			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_317_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_317: the record's +0x16 caption pointer names this string
HdaeUiObj_317_Cap16:	.asciz	"LOAD"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#319] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #318 FLS_FILE_LOAD_SW_EDIT,
	; box 270,202-305,220.  Record layout and evidence: pool header above.
HdaeUiObj_319:
	.long	0x0160002b				; +0x00 class id
	.short	318, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	270, 202, 305, 220			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_319_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_319: the record's +0x16 caption pointer names this string
HdaeUiObj_319_Cap16:	.asciz	"EDIT"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#320] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #314 FLS_FILE_LOAD,
	; box 84,220-195,237.  Record layout and evidence: pool header above.
HdaeUiObj_320:
	.long	0x01600022				; +0x00 class id
	.short	314, 0xffff, 321, 318	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	84, 220, 195, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0004, 0x0003	; +0x26 class body

	; [#321] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #314 FLS_FILE_LOAD,
	; box 44,220-75,237.  Record layout and evidence: pool header above.
HdaeUiObj_321:
	.long	0x0160001f				; +0x00 class id
	.short	314, 0xffff, 322, 320	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 220, 75, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0002, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x000f	; +0x26 class body

	; [#322] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #314 FLS_FILE_LOAD,
	; box 204,220-235,237.  Record layout and evidence: pool header above.
HdaeUiObj_322:
	.long	0x0160001f				; +0x00 class id
	.short	314, 0xffff, 323, 321	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	204, 220, 235, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0005	; +0x16 class body
	.short	0x0010	; +0x26 class body

	; [#323] "FLS_OPT_BOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #314 FLS_FILE_LOAD,
	; box 236,80-319,191.  Record layout and evidence: pool header above.
HdaeUiObj_323:
	.long	0x016a0000				; +0x00 class id
	.short	314, 0xffff, 324, 322	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	236, 80, 319, 191			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0x0064, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0140	; +0x16 class body
	.long	0x00239ac2				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0009	; +0x2A class body
	.long	0x00239ac6				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x00239ac8				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#324] "FLS_LOC_BOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #314 FLS_FILE_LOAD,
	; box 236,58-319,75.  Record layout and evidence: pool header above.
HdaeUiObj_324:
	.long	0x016a0000				; +0x00 class id
	.short	314, 0xffff, 325, 323	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	236, 58, 319, 75			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0x0064, 0x0003, 0x0000, 0x000a, 0x0000, 0x0140	; +0x16 class body
	.long	0x00239aca				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x2A class body
	.long	0x00239ace				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x00239ad0				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#325] "FLS_NAME_BOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #314 FLS_FILE_LOAD,
	; box 8,32-197,49.  Record layout and evidence: pool header above.
HdaeUiObj_325:
	.long	0x016a0000				; +0x00 class id
	.short	314, 326, 328, 324	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 32, 197, 49			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0x0064, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0140	; +0x16 class body
	.long	0x00239ad2				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x2A class body
	.long	0x00239ad6				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x00239ad8				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#326] (unnamed)  class 0160:0037 = KN5000 widget type 0x37, 42 bytes, parent #325 FLS_NAME_BOX,
	; box 197,32-214,49.  Record layout and evidence: pool header above.
HdaeUiObj_326:
	.long	0x01600037				; +0x00 class id
	.short	325, 0xffff, 327, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	197, 32, 214, 49			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_326_Cap1A			; +0x1A caption pointer
	.short	0x0003, 0x0000, 0x00ff, 0x0000	; +0x1E class body
	; caption of HdaeUiObj_326: the record's +0x1A caption pointer names this string
HdaeUiObj_326_Cap1A:	.asciz	"AS"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#327] (unnamed)  class 0160:0037 = KN5000 widget type 0x37, 42 bytes, parent #325 FLS_NAME_BOX,
	; box 214,32-232,49.  Record layout and evidence: pool header above.
HdaeUiObj_327:
	.long	0x01600037				; +0x00 class id
	.short	325, 0xffff, 0xffff, 326	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	214, 32, 232, 49			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_327_Cap1A			; +0x1A caption pointer
	.short	0x0003, 0x0000, 0x00ff, 0x0000	; +0x1E class body
	; caption of HdaeUiObj_327: the record's +0x1A caption pointer names this string
HdaeUiObj_327_Cap1A:	.asciz	"AL"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#328] "FLS_FILE_BOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #314 FLS_FILE_LOAD,
	; box 8,52-232,216.  Record layout and evidence: pool header above.
HdaeUiObj_328:
	.long	0x016a0000				; +0x00 class id
	.short	314, 329, 331, 325	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 52, 232, 216			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0x0000, 0x0003, 0x0000, 0x00ff, 0x0006, 0x014a	; +0x16 class body
	.long	0x00239ada				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0010	; +0x2A class body
	.long	0x00239ade				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x32 class body
	.long	0x00239ae0				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#329] "FLS_LOAD_LINE1"  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #328 FLS_FILE_BOX,
	; box 197,52-197,216.  Record layout and evidence: pool header above.
HdaeUiObj_329:
	.long	0x0160002e				; +0x00 class id
	.short	328, 0xffff, 330, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	197, 52, 197, 216			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#330] "FLS_LOAD_LINE2"  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #328 FLS_FILE_BOX,
	; box 214,52-214,216.  Record layout and evidence: pool header above.
HdaeUiObj_330:
	.long	0x0160002e				; +0x00 class id
	.short	328, 0xffff, 0xffff, 329	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	214, 52, 214, 216			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#331] (unnamed)  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #314 FLS_FILE_LOAD,
	; box 288,0-319,31.  Record layout and evidence: pool header above.
HdaeUiObj_331:
	.long	0x01600052				; +0x00 class id
	.short	314, 0xffff, 332, 328	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	288, 0, 319, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0033, 0x012a	; +0x16 class body

	; [#332] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #314 FLS_FILE_LOAD,
	; box 244,220-315,237.  Record layout and evidence: pool header above.
HdaeUiObj_332:
	.long	0x01600022				; +0x00 class id
	.short	314, 333, 0xffff, 331	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 220, 315, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x0009, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0007, 0x0000	; +0x26 class body

	; [#333] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #332,
	; box 258,221-301,239.  Record layout and evidence: pool header above.
HdaeUiObj_333:
	.long	0x0160002b				; +0x00 class id
	.short	332, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	258, 221, 301, 239			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_333_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x00f9	; +0x1A class body
	; caption of HdaeUiObj_333: the record's +0x16 caption pointer names this string
HdaeUiObj_333_Cap16:	.asciz	"PANIC"

	; [#334] "FLS_DIR_SEL"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 60 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_334:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 335, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239ae2				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_334_Cap22			; +0x22 caption pointer
	.short	0x00af, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_334: the record's +0x22 caption pointer names this string
HdaeUiObj_334_Cap22:	.asciz	"F.L.S. DIR SELECT"

	; [#335] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #334 FLS_DIR_SEL,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_335:
	.long	0x01600049				; +0x00 class id
	.short	334, 0xffff, 336, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x013a, 0x007f	; +0x16 class body

	; [#336] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #334 FLS_DIR_SEL,
	; box 269,30-311,55.  Record layout and evidence: pool header above.
HdaeUiObj_336:
	.long	0x0160001f				; +0x00 class id
	.short	334, 0xffff, 337, 335	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	269, 30, 311, 55			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000, 0x0008	; +0x16 class body
	.short	0x0006	; +0x26 class body

	; [#337] "FLS_DIR_BOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #334 FLS_DIR_SEL,
	; box 8,35-263,210.  Record layout and evidence: pool header above.
HdaeUiObj_337:
	.long	0x016a0000				; +0x00 class id
	.short	334, 0xffff, 338, 336	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 35, 263, 210			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c1, 0x0000, 0x0003, 0x0000, 0x00ff, 0x0008, 0x014a	; +0x16 class body
	.long	0x00239ae6				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0002, 0x000c	; +0x2A class body
	.long	0x00239aea				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x32 class body
	.long	0x00239aec				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#338] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #334 FLS_DIR_SEL,
	; box 1,222-38,239.  Record layout and evidence: pool header above.
HdaeUiObj_338:
	.long	0x0160003e				; +0x00 class id
	.short	334, 0xffff, 339, 337	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	1, 222, 38, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0000	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_338_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_338: the record's +0x28 caption pointer names this string
HdaeUiObj_338_Cap28:	.asciz	"01-24"

	; [#339] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #334 FLS_DIR_SEL,
	; box 43,222-80,239.  Record layout and evidence: pool header above.
HdaeUiObj_339:
	.long	0x0160003e				; +0x00 class id
	.short	334, 0xffff, 340, 338	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	43, 222, 80, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0007	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_339_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_339: the record's +0x28 caption pointer names this string
HdaeUiObj_339_Cap28:	.asciz	"25-48"

	; [#340] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #334 FLS_DIR_SEL,
	; box 84,222-195,239.  Record layout and evidence: pool header above.
HdaeUiObj_340:
	.long	0x01600022				; +0x00 class id
	.short	334, 0xffff, 341, 339	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	84, 222, 195, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0004, 0x0003	; +0x26 class body

	; [#341] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #334 FLS_DIR_SEL,
	; box 199,222-236,239.  Record layout and evidence: pool header above.
HdaeUiObj_341:
	.long	0x0160003e				; +0x00 class id
	.short	334, 0xffff, 342, 340	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	199, 222, 236, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0007	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_341_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_341: the record's +0x28 caption pointer names this string
HdaeUiObj_341_Cap28:	.asciz	"49-72"

	; [#342] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #334 FLS_DIR_SEL,
	; box 240,222-277,239.  Record layout and evidence: pool header above.
HdaeUiObj_342:
	.long	0x0160003e				; +0x00 class id
	.short	334, 0xffff, 343, 341	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	240, 222, 277, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0007	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_342_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_342: the record's +0x28 caption pointer names this string
HdaeUiObj_342_Cap28:	.asciz	"73-96"

	; [#343] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 52 bytes, parent #334 FLS_DIR_SEL,
	; box 281,222-318,239.  Record layout and evidence: pool header above.
HdaeUiObj_343:
	.long	0x0160003e				; +0x00 class id
	.short	334, 0xffff, 344, 342	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	281, 222, 318, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0007	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_343_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_343: the record's +0x28 caption pointer names this string
HdaeUiObj_343_Cap28:	.asciz	"97-120"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#344] (unnamed)  class 0160:0029 = KN5000 widget type 0x29, 26 bytes, parent #334 FLS_DIR_SEL,
	; box 28,0-59,31.  Record layout and evidence: pool header above.
HdaeUiObj_344:
	.long	0x01600029				; +0x00 class id
	.short	334, 0xffff, 0xffff, 343	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	28, 0, 59, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x014a	; +0x16 class body

	; [#345] "FLS_FILE_SEL"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 62 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_345:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 346, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239aee				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_345_Cap22			; +0x22 caption pointer
	.short	0x00af, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_345: the record's +0x22 caption pointer names this string
HdaeUiObj_345_Cap22:	.asciz	"F.L.S. FILE SELECT"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#346] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #345 FLS_FILE_SEL,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_346:
	.long	0x01600049				; +0x00 class id
	.short	345, 0xffff, 347, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x014e, 0x007f	; +0x16 class body

	; [#347] "FLS_FILE_SEL_DIRBOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #345 FLS_FILE_SEL,
	; box 44,32-235,47.  Record layout and evidence: pool header above.
HdaeUiObj_347:
	.long	0x016a0000				; +0x00 class id
	.short	345, 0xffff, 348, 346	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 32, 235, 47			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0x0064, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0140	; +0x16 class body
	.long	0x00239af2				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x2A class body
	.long	0x00239af6				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x00239af8				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#348] "FLS_FILE_SEL_LISTBOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #345 FLS_FILE_SEL,
	; box 44,48-235,215.  Record layout and evidence: pool header above.
HdaeUiObj_348:
	.long	0x016a0000				; +0x00 class id
	.short	345, 0xffff, 349, 347	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 48, 235, 215			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0x0000, 0x0003, 0x0000, 0x00ff, 0x0009, 0x014a	; +0x16 class body
	.long	0x00239afa				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0010	; +0x2A class body
	.long	0x00239afe				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x32 class body
	.long	0x00239b00				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#349] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #345 FLS_FILE_SEL,
	; box 84,220-195,237.  Record layout and evidence: pool header above.
HdaeUiObj_349:
	.long	0x01600022				; +0x00 class id
	.short	345, 0xffff, 350, 348	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	84, 220, 195, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0004, 0x0003	; +0x26 class body

	; [#350] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #345 FLS_FILE_SEL,
	; box 44,220-75,237.  Record layout and evidence: pool header above.
HdaeUiObj_350:
	.long	0x0160001f				; +0x00 class id
	.short	345, 0xffff, 351, 349	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 220, 75, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0002, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x000f	; +0x26 class body

	; [#351] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #345 FLS_FILE_SEL,
	; box 204,220-235,237.  Record layout and evidence: pool header above.
HdaeUiObj_351:
	.long	0x0160001f				; +0x00 class id
	.short	345, 0xffff, 352, 350	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	204, 220, 235, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0005	; +0x16 class body
	.short	0x0010	; +0x26 class body

	; [#352] "FLS_FILE_SEL_OPTBOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #345 FLS_FILE_SEL,
	; box 236,68-319,187.  Record layout and evidence: pool header above.
HdaeUiObj_352:
	.long	0x016a0000				; +0x00 class id
	.short	345, 0xffff, 353, 351	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	236, 68, 319, 187			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0x0064, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0140	; +0x16 class body
	.long	0x00239b02				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0009	; +0x2A class body
	.long	0x00239b06				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x00239b08				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#353] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #345 FLS_FILE_SEL,
	; box 258,30-311,55.  Record layout and evidence: pool header above.
HdaeUiObj_353:
	.long	0x0160001f				; +0x00 class id
	.short	345, 354, 0xffff, 352	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	258, 30, 311, 55			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000, 0x0008	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#354] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 40 bytes, parent #353,
	; box 259,35-310,53.  Record layout and evidence: pool header above.
HdaeUiObj_354:
	.long	0x0160002b				; +0x00 class id
	.short	353, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	259, 35, 310, 53			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_354_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_354: the record's +0x16 caption pointer names this string
HdaeUiObj_354_Cap16:	.asciz	"SELECT"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#355] "FLS_EDIT"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 54 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_355:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 356, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239b0a				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_355_Cap22			; +0x22 caption pointer
	.short	0x00af, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_355: the record's +0x22 caption pointer names this string
HdaeUiObj_355_Cap22:	.asciz	"F.L.S. EDIT"

	; [#356] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #355 FLS_EDIT,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_356:
	.long	0x01600049				; +0x00 class id
	.short	355, 0xffff, 357, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x013a, 0x007f	; +0x16 class body

	; [#357] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #355 FLS_EDIT,
	; box 84,222-195,239.  Record layout and evidence: pool header above.
HdaeUiObj_357:
	.long	0x01600022				; +0x00 class id
	.short	355, 0xffff, 358, 356	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	84, 222, 195, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0004, 0x0003	; +0x26 class body

	; [#358] "FLS_EDIT_NAME_BOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #355 FLS_EDIT,
	; box 8,32-197,49.  Record layout and evidence: pool header above.
HdaeUiObj_358:
	.long	0x016a0000				; +0x00 class id
	.short	355, 359, 361, 357	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 32, 197, 49			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0x0064, 0x0003, 0x0000, 0x0000, 0x0000, 0x0140	; +0x16 class body
	.long	0x00239b0e				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x2A class body
	.long	0x00239b12				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x00239b14				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#359] (unnamed)  class 0160:0037 = KN5000 widget type 0x37, 42 bytes, parent #358 FLS_EDIT_NAME_BOX,
	; box 198,32-214,49.  Record layout and evidence: pool header above.
HdaeUiObj_359:
	.long	0x01600037				; +0x00 class id
	.short	358, 0xffff, 360, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	198, 32, 214, 49			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_359_Cap1A			; +0x1A caption pointer
	.short	0x0003, 0x0000, 0x0000, 0x0000	; +0x1E class body
	; caption of HdaeUiObj_359: the record's +0x1A caption pointer names this string
HdaeUiObj_359_Cap1A:	.asciz	"AS"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#360] (unnamed)  class 0160:0037 = KN5000 widget type 0x37, 42 bytes, parent #358 FLS_EDIT_NAME_BOX,
	; box 215,32-232,49.  Record layout and evidence: pool header above.
HdaeUiObj_360:
	.long	0x01600037				; +0x00 class id
	.short	358, 0xffff, 0xffff, 359	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	215, 32, 232, 49			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_360_Cap1A			; +0x1A caption pointer
	.short	0x0003, 0x0000, 0x0000, 0x0000	; +0x1E class body
	; caption of HdaeUiObj_360: the record's +0x1A caption pointer names this string
HdaeUiObj_360_Cap1A:	.asciz	"AL"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#361] "FLS_EDIT_LIST_BOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #355 FLS_EDIT,
	; box 8,52-232,216.  Record layout and evidence: pool header above.
HdaeUiObj_361:
	.long	0x016a0000				; +0x00 class id
	.short	355, 362, 364, 358	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 52, 232, 216			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0x0000, 0x0003, 0x0000, 0x0000, 0x0007, 0x014a	; +0x16 class body
	.long	0x00239b16				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0010	; +0x2A class body
	.long	0x00239b1a				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x32 class body
	.long	0x00239b1c				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#362] "FLS_EDIT_LINE2"  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #361 FLS_EDIT_LIST_BOX,
	; box 214,52-214,215.  Record layout and evidence: pool header above.
HdaeUiObj_362:
	.long	0x0160002e				; +0x00 class id
	.short	361, 0xffff, 363, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	214, 52, 214, 215			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x0001	; +0x16 class body

	; [#363] "FLS_EDIT_LINE1"  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #361 FLS_EDIT_LIST_BOX,
	; box 197,52-197,215.  Record layout and evidence: pool header above.
HdaeUiObj_363:
	.long	0x0160002e				; +0x00 class id
	.short	361, 0xffff, 0xffff, 362	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	197, 52, 197, 215			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x0001	; +0x16 class body

	; [#364] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #355 FLS_EDIT,
	; box 255,30-311,55.  Record layout and evidence: pool header above.
HdaeUiObj_364:
	.long	0x0160001f				; +0x00 class id
	.short	355, 365, 366, 361	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	255, 30, 311, 55			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000, 0x0008	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#365] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 40 bytes, parent #364,
	; box 257,35-308,53.  Record layout and evidence: pool header above.
HdaeUiObj_365:
	.long	0x0160002b				; +0x00 class id
	.short	364, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	257, 35, 308, 53			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_365_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_365: the record's +0x16 caption pointer names this string
HdaeUiObj_365_Cap16:	.asciz	"SEARCH"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#366] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #355 FLS_EDIT,
	; box 256,192-310,217.  Record layout and evidence: pool header above.
HdaeUiObj_366:
	.long	0x0160001f				; +0x00 class id
	.short	355, 367, 369, 364	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	256, 192, 310, 217			; +0x0E box x1, y1, x2, y2
	.short	0x00f2, 0x00c0, 0x0004, 0x0000, 0x0000, 0x0000, 0x0000, 0x000c	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#367] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #366,
	; box 268,195-295,205.  Record layout and evidence: pool header above.
HdaeUiObj_367:
	.long	0x0160002b				; +0x00 class id
	.short	366, 0xffff, 368, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	268, 195, 295, 205			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_367_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_367: the record's +0x16 caption pointer names this string
HdaeUiObj_367_Cap16:	.asciz	"SAVE"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#368] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 40 bytes, parent #366,
	; box 266,206-305,216.  Record layout and evidence: pool header above.
HdaeUiObj_368:
	.long	0x0160002b				; +0x00 class id
	.short	366, 0xffff, 0xffff, 367	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	266, 206, 305, 216			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_368_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_368: the record's +0x16 caption pointer names this string
HdaeUiObj_368_Cap16:	.asciz	"F.L.S."
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#369] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #355 FLS_EDIT,
	; box 4,222-35,239.  Record layout and evidence: pool header above.
HdaeUiObj_369:
	.long	0x0160003e				; +0x00 class id
	.short	355, 0xffff, 370, 366	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 222, 35, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0000	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_369_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_369: the record's +0x28 caption pointer names this string
HdaeUiObj_369_Cap28:	.asciz	"DEL1"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#370] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #355 FLS_EDIT,
	; box 44,222-76,239.  Record layout and evidence: pool header above.
HdaeUiObj_370:
	.long	0x0160003e				; +0x00 class id
	.short	355, 0xffff, 371, 369	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 222, 76, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0001	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_370_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_370: the record's +0x28 caption pointer names this string
HdaeUiObj_370_Cap28:	.asciz	"DEL2"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#371] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 48 bytes, parent #355 FLS_EDIT,
	; box 204,222-236,239.  Record layout and evidence: pool header above.
HdaeUiObj_371:
	.long	0x0160003e				; +0x00 class id
	.short	355, 0xffff, 372, 370	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	204, 222, 236, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0005	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_371_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_371: the record's +0x28 caption pointer names this string
HdaeUiObj_371_Cap28:	.asciz	"INS"

	; [#372] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #355 FLS_EDIT,
	; box 244,222-275,239.  Record layout and evidence: pool header above.
HdaeUiObj_372:
	.long	0x0160003e				; +0x00 class id
	.short	355, 0xffff, 373, 371	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 222, 275, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0006	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_372_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_372: the record's +0x28 caption pointer names this string
HdaeUiObj_372_Cap28:	.asciz	"A.S."
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#373] (unnamed)  class 0160:003E = KN5000 widget type 0x3E, 50 bytes, parent #355 FLS_EDIT,
	; box 284,222-315,239.  Record layout and evidence: pool header above.
HdaeUiObj_373:
	.long	0x0160003e				; +0x00 class id
	.short	355, 0xffff, 374, 372	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	284, 222, 315, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0007	; +0x16 class body
	.short	0x0000	; +0x26 class body
	.long	HdaeUiObj_373_Cap28			; +0x28 caption pointer
	; caption of HdaeUiObj_373: the record's +0x28 caption pointer names this string
HdaeUiObj_373_Cap28:	.asciz	"A.L."
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#374] "FLS_EDIT_LOC_BOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #355 FLS_EDIT,
	; box 236,58-319,75.  Record layout and evidence: pool header above.
HdaeUiObj_374:
	.long	0x016a0000				; +0x00 class id
	.short	355, 0xffff, 375, 373	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	236, 58, 319, 75			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0x0064, 0x0003, 0x0000, 0x00f2, 0x0000, 0x0140	; +0x16 class body
	.long	0x00239b1e				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x2A class body
	.long	0x00239b22				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x00239b24				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#375] "FLS_EDIT_OPT_BOX"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #355 FLS_EDIT,
	; box 236,78-319,188.  Record layout and evidence: pool header above.
HdaeUiObj_375:
	.long	0x016a0000				; +0x00 class id
	.short	355, 0xffff, 376, 374	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	236, 78, 319, 188			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0x0064, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0140	; +0x16 class body
	.long	0x00239b26				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0009	; +0x2A class body
	.long	0x00239b2a				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x00239b2c				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#376] (unnamed)  class 0160:0029 = KN5000 widget type 0x29, 26 bytes, parent #355 FLS_EDIT,
	; box 32,0-63,31.  Record layout and evidence: pool header above.
HdaeUiObj_376:
	.long	0x01600029				; +0x00 class id
	.short	355, 0xffff, 377, 375	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	32, 0, 63, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x014a	; +0x16 class body

	; [#377] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #355 FLS_EDIT,
	; box 214,32-214,48.  Record layout and evidence: pool header above.
HdaeUiObj_377:
	.long	0x0160002e				; +0x00 class id
	.short	355, 0xffff, 378, 376	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	214, 32, 214, 48			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x0001	; +0x16 class body

	; [#378] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #355 FLS_EDIT,
	; box 197,32-197,48.  Record layout and evidence: pool header above.
HdaeUiObj_378:
	.long	0x0160002e				; +0x00 class id
	.short	355, 0xffff, 0xffff, 377	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	197, 32, 197, 48			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x0001	; +0x16 class body

	; [#379] "CP_FD_DIR_NAMING"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 62 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_379:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 380, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239b2e				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_379_Cap22			; +0x22 caption pointer
	.short	0x0073, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_379: the record's +0x22 caption pointer names this string
HdaeUiObj_379_Cap22:	.asciz	"EDIT DIRECTORY NAME"

	; [#380] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #379 CP_FD_DIR_NAMING,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_380:
	.long	0x01600049				; +0x00 class id
	.short	379, 0xffff, 381, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x00e2, 0x007f	; +0x16 class body

	; [#381] (unnamed)  class 0160:004D = KN5000 widget type 0x4D, 26 bytes, parent #379 CP_FD_DIR_NAMING,
	; box 0,32-31,63.  Record layout and evidence: pool header above.
HdaeUiObj_381:
	.long	0x0160004d				; +0x00 class id
	.short	379, 0xffff, 382, 380	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 32, 31, 63			; +0x0E box x1, y1, x2, y2
	.short	0x0019, 0x012a	; +0x16 class body

	; [#382] (unnamed)  class 0160:0020 = KN5000 widget type 0x20, 44 bytes, parent #379 CP_FD_DIR_NAMING,
	; box 281,160-311,177.  Record layout and evidence: pool header above.
HdaeUiObj_382:
	.long	0x01600020				; +0x00 class id
	.short	379, 0xffff, 383, 381	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	281, 160, 311, 177			; +0x0E box x1, y1, x2, y2
	.short	0x00f2, 0x00c1, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x000b	; +0x16 class body
	.short	0x0006, 0x0019, 0x012a	; +0x26 class body

	; [#383] (unnamed)  class 0160:0020 = KN5000 widget type 0x20, 44 bytes, parent #379 CP_FD_DIR_NAMING,
	; box 8,118-38,135.  Record layout and evidence: pool header above.
HdaeUiObj_383:
	.long	0x01600020				; +0x00 class id
	.short	379, 0xffff, 384, 382	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 118, 38, 135			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c1, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x008a	; +0x16 class body
	.short	0x0000, 0x0019, 0x012a	; +0x26 class body

	; [#384] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #379 CP_FD_DIR_NAMING,
	; box 9,119-36,137.  Record layout and evidence: pool header above.
HdaeUiObj_384:
	.long	0x0160002b				; +0x00 class id
	.short	379, 0xffff, 0xffff, 383	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	9, 119, 36, 137			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_384_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x00f9	; +0x1A class body
	; caption of HdaeUiObj_384: the record's +0x16 caption pointer names this string
HdaeUiObj_384_Cap16:	.asciz	"LST"

	; [#385] (unnamed)  class 0160:004B = KN5000 widget type 0x4B, 36 bytes, parent none (root),
	; box 60,84-259,131.  Record layout and evidence: pool header above.
HdaeUiObj_385:
	.long	0x0160004b				; +0x00 class id
	.short	0xffff, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	60, 84, 259, 131			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c1, 0x0000	; +0x16 class body
	.long	0x00239b32				; +0x1C RAM address (every 0160:004B record)
	.long	0x00239b36				; +0x20 RAM address (every 0160:004B record)

	; [#386] "SAVE_OPT_SCREEN"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 54 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_386:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 387, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239b3a				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_386_Cap22			; +0x22 caption pointer
	.short	0x00ad, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_386: the record's +0x22 caption pointer names this string
HdaeUiObj_386_Cap22:	.asciz	"SAVE OPTION"

	; [#387] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_387:
	.long	0x01600049				; +0x00 class id
	.short	386, 0xffff, 388, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x004e, 0x007f	; +0x16 class body

	; [#388] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 4,216-35,238.  Record layout and evidence: pool header above.
HdaeUiObj_388:
	.long	0x0160001f				; +0x00 class id
	.short	386, 0xffff, 389, 387	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 216, 35, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#389] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 44,216-75,238.  Record layout and evidence: pool header above.
HdaeUiObj_389:
	.long	0x0160001f				; +0x00 class id
	.short	386, 0xffff, 390, 388	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 216, 75, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0002, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#390] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 84,216-115,238.  Record layout and evidence: pool header above.
HdaeUiObj_390:
	.long	0x0160001f				; +0x00 class id
	.short	386, 0xffff, 391, 389	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	84, 216, 115, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#391] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 124,216-155,238.  Record layout and evidence: pool header above.
HdaeUiObj_391:
	.long	0x0160001f				; +0x00 class id
	.short	386, 0xffff, 392, 390	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	124, 216, 155, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0004, 0x0000, 0x0000, 0x0000, 0x0000, 0x0003	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#392] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 164,216-195,238.  Record layout and evidence: pool header above.
HdaeUiObj_392:
	.long	0x0160001f				; +0x00 class id
	.short	386, 0xffff, 393, 391	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	164, 216, 195, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0005, 0x0000, 0x0000, 0x0000, 0x0000, 0x0004	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#393] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 204,216-235,238.  Record layout and evidence: pool header above.
HdaeUiObj_393:
	.long	0x0160001f				; +0x00 class id
	.short	386, 0xffff, 394, 392	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	204, 216, 235, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0006, 0x0000, 0x0000, 0x0000, 0x0000, 0x0005	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#394] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 244,216-275,238.  Record layout and evidence: pool header above.
HdaeUiObj_394:
	.long	0x0160001f				; +0x00 class id
	.short	386, 0xffff, 395, 393	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 216, 275, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0007, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#395] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 284,216-315,238.  Record layout and evidence: pool header above.
HdaeUiObj_395:
	.long	0x0160001f				; +0x00 class id
	.short	386, 0xffff, 396, 394	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	284, 216, 315, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0008, 0x0000, 0x0000, 0x0000, 0x0000, 0x0007	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#396] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 9,202-30,212.  Record layout and evidence: pool header above.
HdaeUiObj_396:
	.long	0x0160002b				; +0x00 class id
	.short	386, 0xffff, 397, 395	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	9, 202, 30, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_396_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_396: the record's +0x16 caption pointer names this string
HdaeUiObj_396_Cap16:	.asciz	"PNL"

	; [#397] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 42,202-75,212.  Record layout and evidence: pool header above.
HdaeUiObj_397:
	.long	0x0160002b				; +0x00 class id
	.short	386, 0xffff, 398, 396	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	42, 202, 75, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_397_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_397: the record's +0x16 caption pointer names this string
HdaeUiObj_397_Cap16:	.asciz	"P.MEM"

	; [#398] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 88,202-109,212.  Record layout and evidence: pool header above.
HdaeUiObj_398:
	.long	0x0160002b				; +0x00 class id
	.short	386, 0xffff, 399, 397	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	88, 202, 109, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_398_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_398: the record's +0x16 caption pointer names this string
HdaeUiObj_398_Cap16:	.asciz	"SEQ"

	; [#399] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 126,202-153,212.  Record layout and evidence: pool header above.
HdaeUiObj_399:
	.long	0x0160002b				; +0x00 class id
	.short	386, 0xffff, 400, 398	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	126, 202, 153, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_399_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_399: the record's +0x16 caption pointer names this string
HdaeUiObj_399_Cap16:	.asciz	"COMP"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#400] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 162,202-195,212.  Record layout and evidence: pool header above.
HdaeUiObj_400:
	.long	0x0160002b				; +0x00 class id
	.short	386, 0xffff, 401, 399	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	162, 202, 195, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_400_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_400: the record's +0x16 caption pointer names this string
HdaeUiObj_400_Cap16:	.asciz	"SOUND"

	; [#401] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 209,202-230,212.  Record layout and evidence: pool header above.
HdaeUiObj_401:
	.long	0x0160002b				; +0x00 class id
	.short	386, 0xffff, 402, 400	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	209, 202, 230, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_401_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_401: the record's +0x16 caption pointer names this string
HdaeUiObj_401_Cap16:	.asciz	"MSP"

	; [#402] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 40 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 239,202-278,212.  Record layout and evidence: pool header above.
HdaeUiObj_402:
	.long	0x0160002b				; +0x00 class id
	.short	386, 0xffff, 403, 401	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	239, 202, 278, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_402_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_402: the record's +0x16 caption pointer names this string
HdaeUiObj_402_Cap16:	.asciz	"CUSTOM"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#403] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 286,202-313,212.  Record layout and evidence: pool header above.
HdaeUiObj_403:
	.long	0x0160002b				; +0x00 class id
	.short	386, 0xffff, 404, 402	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	286, 202, 313, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_403_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_403: the record's +0x16 caption pointer names this string
HdaeUiObj_403_Cap16:	.asciz	"MIDI"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#404] "RAM_EDIT_CMP"  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 44,106-255,121.  Record layout and evidence: pool header above.
HdaeUiObj_404:
	.long	0x0160001b				; +0x00 class id
	.short	386, 0xffff, 405, 403	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 106, 255, 121			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0004	; +0x16 class body
	.long	HdaeUiObj_404_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239b3e				; +0x2E RAM address (every 0160:001B record)
	.short	0x000b, 0x012a	; +0x32 class body
	.long	0x00239b40				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_404: the record's +0x1C caption pointer names this string
HdaeUiObj_404_Cap1C:	.asciz	"COMPOSER               "

	; [#405] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 60 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 40,31-259,56.  Record layout and evidence: pool header above.
HdaeUiObj_405:
	.long	0x0160001b				; +0x00 class id
	.short	386, 0xffff, 406, 404	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 31, 259, 56			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0xffff	; +0x16 class body
	.long	HdaeUiObj_405_Cap1C			; +0x1C caption pointer
	.short	0x0005, 0x0000, 0x00ff, 0x0001, 0x0004, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239b44				; +0x2E RAM address (every 0160:001B record)
	.short	0x0006, 0x012a	; +0x32 class body
	.long	0x00239b46				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_405: the record's +0x1C caption pointer names this string
HdaeUiObj_405_Cap1C:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#406] "RAM_EDIT_LSW"  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 44,61-255,76.  Record layout and evidence: pool header above.
HdaeUiObj_406:
	.long	0x0160001b				; +0x00 class id
	.short	386, 0xffff, 407, 405	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 61, 255, 76			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0001	; +0x16 class body
	.long	HdaeUiObj_406_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239b4a				; +0x2E RAM address (every 0160:001B record)
	.short	0x0008, 0x012a	; +0x32 class body
	.long	0x00239b4c				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_406: the record's +0x1C caption pointer names this string
HdaeUiObj_406_Cap1C:	.asciz	"CURRENT PANEL          "

	; [#407] "RAM_EDIT_PMT"  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 44,76-255,91.  Record layout and evidence: pool header above.
HdaeUiObj_407:
	.long	0x0160001b				; +0x00 class id
	.short	386, 0xffff, 408, 406	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 76, 255, 91			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0002	; +0x16 class body
	.long	HdaeUiObj_407_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239b50				; +0x2E RAM address (every 0160:001B record)
	.short	0x0009, 0x012a	; +0x32 class body
	.long	0x00239b52				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_407: the record's +0x1C caption pointer names this string
HdaeUiObj_407_Cap1C:	.asciz	"PANEL MEMORY           "

	; [#408] "RAM_EDIT_SQT"  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 44,91-255,106.  Record layout and evidence: pool header above.
HdaeUiObj_408:
	.long	0x0160001b				; +0x00 class id
	.short	386, 0xffff, 409, 407	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 91, 255, 106			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0003	; +0x16 class body
	.long	HdaeUiObj_408_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239b56				; +0x2E RAM address (every 0160:001B record)
	.short	0x000a, 0x012a	; +0x32 class body
	.long	0x00239b58				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_408: the record's +0x1C caption pointer names this string
HdaeUiObj_408_Cap1C:	.asciz	"SEQUENCER              "

	; [#409] "RAM_EDIT_TM"  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 44,121-255,136.  Record layout and evidence: pool header above.
HdaeUiObj_409:
	.long	0x0160001b				; +0x00 class id
	.short	386, 0xffff, 410, 408	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 121, 255, 136			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0005	; +0x16 class body
	.long	HdaeUiObj_409_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239b5c				; +0x2E RAM address (every 0160:001B record)
	.short	0x000c, 0x012a	; +0x32 class body
	.long	0x00239b5e				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_409: the record's +0x1C caption pointer names this string
HdaeUiObj_409_Cap1C:	.asciz	"SOUND MEMORY           "

	; [#410] "RAM_EDIT_MSP"  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 44,136-255,151.  Record layout and evidence: pool header above.
HdaeUiObj_410:
	.long	0x0160001b				; +0x00 class id
	.short	386, 0xffff, 411, 409	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 136, 255, 151			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0006	; +0x16 class body
	.long	HdaeUiObj_410_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239b62				; +0x2E RAM address (every 0160:001B record)
	.short	0x000d, 0x012a	; +0x32 class body
	.long	0x00239b64				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_410: the record's +0x1C caption pointer names this string
HdaeUiObj_410_Cap1C:	.asciz	"MSP                    "

	; [#411] "RAM_EDIT_RCM"  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 44,151-255,166.  Record layout and evidence: pool header above.
HdaeUiObj_411:
	.long	0x0160001b				; +0x00 class id
	.short	386, 0xffff, 412, 410	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 151, 255, 166			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0007	; +0x16 class body
	.long	HdaeUiObj_411_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239b68				; +0x2E RAM address (every 0160:001B record)
	.short	0x000e, 0x012a	; +0x32 class body
	.long	0x00239b6a				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_411: the record's +0x1C caption pointer names this string
HdaeUiObj_411_Cap1C:	.asciz	"RHYTHM CUSTOM          "

	; [#412] "RAM_EDIT_MD"  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 44,166-255,181.  Record layout and evidence: pool header above.
HdaeUiObj_412:
	.long	0x0160001b				; +0x00 class id
	.short	386, 0xffff, 413, 411	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 166, 255, 181			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0008	; +0x16 class body
	.long	HdaeUiObj_412_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239b6e				; +0x2E RAM address (every 0160:001B record)
	.short	0x000f, 0x012a	; +0x32 class body
	.long	0x00239b70				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_412: the record's +0x1C caption pointer names this string
HdaeUiObj_412_Cap1C:	.asciz	"USER MIDI SETTINGS     "

	; [#413] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 40,198-259,198.  Record layout and evidence: pool header above.
HdaeUiObj_413:
	.long	0x0160002e				; +0x00 class id
	.short	386, 0xffff, 414, 412	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 198, 259, 198			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#414] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 40,58-259,58.  Record layout and evidence: pool header above.
HdaeUiObj_414:
	.long	0x0160002e				; +0x00 class id
	.short	386, 0xffff, 415, 413	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 58, 259, 58			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#415] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 259,58-259,198.  Record layout and evidence: pool header above.
HdaeUiObj_415:
	.long	0x0160002e				; +0x00 class id
	.short	386, 0xffff, 416, 414	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	259, 58, 259, 198			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#416] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 40,58-40,198.  Record layout and evidence: pool header above.
HdaeUiObj_416:
	.long	0x0160002e				; +0x00 class id
	.short	386, 0xffff, 417, 415	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 58, 40, 198			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#417] (unnamed)  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 32,0-63,31.  Record layout and evidence: pool header above.
HdaeUiObj_417:
	.long	0x01600052				; +0x00 class id
	.short	386, 0xffff, 418, 416	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	32, 0, 63, 31			; +0x0E box x1, y1, x2, y2
	.short	0x001b, 0x012a	; +0x16 class body

	; [#418] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 269,30-311,55.  Record layout and evidence: pool header above.
HdaeUiObj_418:
	.long	0x0160001f				; +0x00 class id
	.short	386, 419, 420, 417	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	269, 30, 311, 55			; +0x0E box x1, y1, x2, y2
	.short	0x00f2, 0x00c0, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0008	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#419] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #418,
	; box 272,35-307,53.  Record layout and evidence: pool header above.
HdaeUiObj_419:
	.long	0x0160002b				; +0x00 class id
	.short	418, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	272, 35, 307, 53			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_419_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_419: the record's +0x16 caption pointer names this string
HdaeUiObj_419_Cap16:	.asciz	"SAVE"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#420] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 263,76-311,93.  Record layout and evidence: pool header above.
HdaeUiObj_420:
	.long	0x0160001f				; +0x00 class id
	.short	386, 421, 422, 418	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	263, 76, 311, 93			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0009	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#421] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 40 bytes, parent #420,
	; box 265,80-310,90.  Record layout and evidence: pool header above.
HdaeUiObj_421:
	.long	0x0160002b				; +0x00 class id
	.short	420, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	265, 80, 310, 90			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_421_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_421: the record's +0x16 caption pointer names this string
HdaeUiObj_421_Cap16:	.asciz	"PERFORM"

	; [#422] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 263,160-311,177.  Record layout and evidence: pool header above.
HdaeUiObj_422:
	.long	0x0160001f				; +0x00 class id
	.short	386, 423, 424, 420	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	263, 160, 311, 177			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x000b	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#423] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 40 bytes, parent #422,
	; box 265,164-310,174.  Record layout and evidence: pool header above.
HdaeUiObj_423:
	.long	0x0160002b				; +0x00 class id
	.short	422, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	265, 164, 310, 174			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_423_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_423: the record's +0x16 caption pointer names this string
HdaeUiObj_423_Cap16:	.asciz	"ALL OFF"

	; [#424] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 263,118-311,135.  Record layout and evidence: pool header above.
HdaeUiObj_424:
	.long	0x0160001f				; +0x00 class id
	.short	386, 425, 426, 422	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	263, 118, 311, 135			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x000a	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#425] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 40 bytes, parent #424,
	; box 265,122-304,132.  Record layout and evidence: pool header above.
HdaeUiObj_425:
	.long	0x0160002b				; +0x00 class id
	.short	424, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	265, 122, 304, 132			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_425_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_425: the record's +0x16 caption pointer names this string
HdaeUiObj_425_Cap16:	.asciz	"BACKUP"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#426] "RAM_EDIT_TLX"  class 0160:001B = KN5000 widget type 0x1B, 82 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 44,181-255,196.  Record layout and evidence: pool header above.
HdaeUiObj_426:
	.long	0x0160001b				; +0x00 class id
	.short	386, 0xffff, 427, 424	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 181, 255, 196			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0009	; +0x16 class body
	.long	HdaeUiObj_426_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239b74				; +0x2E RAM address (every 0160:001B record)
	.short	0x0010, 0x012a	; +0x32 class body
	.long	0x00239b76				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_426: the record's +0x1C caption pointer names this string
HdaeUiObj_426_Cap1C:	.asciz	"TECHNICS LYRICS        "

	; [#427] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 8,158-39,179.  Record layout and evidence: pool header above.
HdaeUiObj_427:
	.long	0x0160001f				; +0x00 class id
	.short	386, 0xffff, 428, 426	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 158, 39, 179			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0009, 0x0000, 0x0000, 0x0000, 0x0000, 0x008b	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#428] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 6,147-39,157.  Record layout and evidence: pool header above.
HdaeUiObj_428:
	.long	0x0160002b				; +0x00 class id
	.short	386, 0xffff, 429, 427	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	6, 147, 39, 157			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_428_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_428: the record's +0x16 caption pointer names this string
HdaeUiObj_428_Cap16:	.asciz	"LYRIC"

	; [#429] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #386 SAVE_OPT_SCREEN,
	; box 209,58-209,198.  Record layout and evidence: pool header above.
HdaeUiObj_429:
	.long	0x0160002e				; +0x00 class id
	.short	386, 0xffff, 0xffff, 428	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	209, 58, 209, 198			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#430] "HddNamingWindow"  class 016A:0003 = ClassName_Table[3] "AcHddNamingWindowProc", 36 bytes, parent none (root),
	; box 44,108-275,195.  Record layout and evidence: pool header above.
HdaeUiObj_430:
	.long	0x016a0003				; +0x00 class id
	.short	0xffff, 431, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 108, 275, 195			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0x0000	; +0x16 class body
	.long	0x00239b7a				; +0x1C RAM address (every 016A:0003 record)
	.long	0x00239b7e				; +0x20 RAM address (every 016A:0003 record)

	; [#431] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #430 HddNamingWindow,
	; box 8,76-38,93.  Record layout and evidence: pool header above.
HdaeUiObj_431:
	.long	0x0160001f				; +0x00 class id
	.short	430, 432, 433, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 76, 38, 93			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c1, 0x0007, 0x0000, 0x0000, 0x0000, 0x0000, 0x0089	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#432] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #431,
	; box 9,77-36,95.  Record layout and evidence: pool header above.
HdaeUiObj_432:
	.long	0x0160002b				; +0x00 class id
	.short	431, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	9, 77, 36, 95			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_432_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_432: the record's +0x16 caption pointer names this string
HdaeUiObj_432_Cap16:	.asciz	"DEL"

	; [#433] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #430 HddNamingWindow,
	; box 8,34-38,51.  Record layout and evidence: pool header above.
HdaeUiObj_433:
	.long	0x0160001f				; +0x00 class id
	.short	430, 434, 435, 431	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 34, 38, 51			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c1, 0x0006, 0x0000, 0x0000, 0x0000, 0x0000, 0x0088	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#434] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #433,
	; box 9,35-36,53.  Record layout and evidence: pool header above.
HdaeUiObj_434:
	.long	0x0160002b				; +0x00 class id
	.short	433, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	9, 35, 36, 53			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_434_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_434: the record's +0x16 caption pointer names this string
HdaeUiObj_434_Cap16:	.asciz	"INS"

	; [#435] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #430 HddNamingWindow,
	; box 281,34-311,51.  Record layout and evidence: pool header above.
HdaeUiObj_435:
	.long	0x0160001f				; +0x00 class id
	.short	430, 436, 437, 433	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	281, 34, 311, 51			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c1, 0x0009, 0x0000, 0x0000, 0x0000, 0x0000, 0x0008	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#436] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #435,
	; box 282,35-309,53.  Record layout and evidence: pool header above.
HdaeUiObj_436:
	.long	0x0160002b				; +0x00 class id
	.short	435, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	282, 35, 309, 53			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_436_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_436: the record's +0x16 caption pointer names this string
HdaeUiObj_436_Cap16:	.asciz	"CLR"

	; [#437] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #430 HddNamingWindow,
	; box 281,76-311,93.  Record layout and evidence: pool header above.
HdaeUiObj_437:
	.long	0x0160001f				; +0x00 class id
	.short	430, 438, 439, 435	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	281, 76, 311, 93			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c1, 0x0008, 0x0000, 0x0000, 0x0000, 0x0000, 0x0009	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#438] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 40 bytes, parent #437,
	; box 282,77-309,95.  Record layout and evidence: pool header above.
HdaeUiObj_438:
	.long	0x0160002b				; +0x00 class id
	.short	437, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	282, 77, 309, 95			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_438_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_438: the record's +0x16 caption pointer names this string
HdaeUiObj_438_Cap16:	.asciz	"~8d ~8b"

	; [#439] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #430 HddNamingWindow,
	; box 4,216-35,238.  Record layout and evidence: pool header above.
HdaeUiObj_439:
	.long	0x0160001f				; +0x00 class id
	.short	430, 0xffff, 440, 437	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 216, 35, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000	; +0x16 class body
	.short	0x000f	; +0x26 class body

	; [#440] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #430 HddNamingWindow,
	; box 44,216-75,238.  Record layout and evidence: pool header above.
HdaeUiObj_440:
	.long	0x0160001f				; +0x00 class id
	.short	430, 0xffff, 441, 439	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 216, 75, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0002, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0010	; +0x26 class body

	; [#441] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 42 bytes, parent #430 HddNamingWindow,
	; box 6,201-73,219.  Record layout and evidence: pool header above.
HdaeUiObj_441:
	.long	0x0160002b				; +0x00 class id
	.short	430, 0xffff, 442, 440	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	6, 201, 73, 219			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_441_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_441: the record's +0x16 caption pointer names this string
HdaeUiObj_441_Cap16:	.asciz	"POSITION"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#442] "HddNamingCursorBox"  class 0160:004C = KN5000 widget type 0x4C, 64 bytes, parent #430 HddNamingWindow,
	; box 44,72-275,103.  Record layout and evidence: pool header above.
HdaeUiObj_442:
	.long	0x0160004c				; +0x00 class id
	.short	430, 0xffff, 443, 441	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 72, 275, 103			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000	; +0x16 class body
	.long	0x00239b82				; +0x24 RAM address (every 0160:004C record)
	.ascii	"ABC\000"				; +0x28 HDAE5000_Str_CharSet_Upper_1 (hdae5000_init_data.s)
	.ascii	"ABC\000"				; +0x2C HDAE5000_Str_CharSet_Upper_2 (hdae5000_init_data.s)
	.ascii	"abc\000"				; +0x30 HDAE5000_Str_CharSet_Lower_1 (hdae5000_init_data.s)
	.ascii	"abc\000"				; +0x34 HDAE5000_Str_CharSet_Lower_2 (hdae5000_init_data.s)
	.ascii	"!#$\000"				; +0x38 HDAE5000_Str_CharSet_Symbol_1 (hdae5000_init_data.s)
	.ascii	"!#$\000"				; +0x3C HDAE5000_Str_CharSet_Symbol_2 (hdae5000_init_data.s)

	; [#446] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #430 HddNamingWindow,
	; box 204,216-235,238.  Record layout and evidence: pool header above.
HdaeUiObj_446:
	.long	0x0160001f				; +0x00 class id
	.short	430, 0xffff, 447, 445	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	204, 216, 235, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000, 0x0005	; +0x16 class body
	.short	0x000f	; +0x26 class body

	; [#447] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #430 HddNamingWindow,
	; box 244,216-275,238.  Record layout and evidence: pool header above.
HdaeUiObj_447:
	.long	0x0160001f				; +0x00 class id
	.short	430, 0xffff, 448, 446	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 216, 275, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0004, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x000e	; +0x26 class body

	; [#448] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #430 HddNamingWindow,
	; box 284,216-315,238.  Record layout and evidence: pool header above.
HdaeUiObj_448:
	.long	0x0160001f				; +0x00 class id
	.short	430, 0xffff, 449, 447	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	284, 216, 315, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0005, 0x0000, 0x0000, 0x0000, 0x0000, 0x0007	; +0x16 class body
	.short	0x0010	; +0x26 class body

	; [#449] "HddNamingLabel"  class 0160:0012 = KN5000 widget type 0x12, 36 bytes, parent #430 HddNamingWindow,
	; box 204,201-315,215.  Record layout and evidence: pool header above.
HdaeUiObj_449:
	.long	0x01600012				; +0x00 class id
	.short	430, 0xffff, 0xffff, 448	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	204, 201, 315, 215			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000	; +0x16 class body

	; [#450] "FILE_DEL_SCREEN"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 58 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_450:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 451, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239b8a				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_450_Cap22			; +0x22 caption pointer
	.short	0x00ad, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_450: the record's +0x22 caption pointer names this string
HdaeUiObj_450_Cap22:	.asciz	"HD FILE DELETE"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#451] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #450 FILE_DEL_SCREEN,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_451:
	.long	0x01600049				; +0x00 class id
	.short	450, 0xffff, 452, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0018, 0x007f	; +0x16 class body

	; [#452] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #450 FILE_DEL_SCREEN,
	; box 9,202-30,212.  Record layout and evidence: pool header above.
HdaeUiObj_452:
	.long	0x0160002b				; +0x00 class id
	.short	450, 0xffff, 453, 451	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	9, 202, 30, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_452_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_452: the record's +0x16 caption pointer names this string
HdaeUiObj_452_Cap16:	.asciz	"PNL"

	; [#453] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #450 FILE_DEL_SCREEN,
	; box 42,202-75,212.  Record layout and evidence: pool header above.
HdaeUiObj_453:
	.long	0x0160002b				; +0x00 class id
	.short	450, 0xffff, 454, 452	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	42, 202, 75, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_453_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_453: the record's +0x16 caption pointer names this string
HdaeUiObj_453_Cap16:	.asciz	"P.MEM"

	; [#454] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #450 FILE_DEL_SCREEN,
	; box 88,202-109,212.  Record layout and evidence: pool header above.
HdaeUiObj_454:
	.long	0x0160002b				; +0x00 class id
	.short	450, 0xffff, 455, 453	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	88, 202, 109, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_454_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_454: the record's +0x16 caption pointer names this string
HdaeUiObj_454_Cap16:	.asciz	"SEQ"

	; [#455] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #450 FILE_DEL_SCREEN,
	; box 126,202-153,212.  Record layout and evidence: pool header above.
HdaeUiObj_455:
	.long	0x0160002b				; +0x00 class id
	.short	450, 0xffff, 456, 454	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	126, 202, 153, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_455_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_455: the record's +0x16 caption pointer names this string
HdaeUiObj_455_Cap16:	.asciz	"COMP"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#456] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #450 FILE_DEL_SCREEN,
	; box 162,202-195,212.  Record layout and evidence: pool header above.
HdaeUiObj_456:
	.long	0x0160002b				; +0x00 class id
	.short	450, 0xffff, 457, 455	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	162, 202, 195, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_456_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_456: the record's +0x16 caption pointer names this string
HdaeUiObj_456_Cap16:	.asciz	"SOUND"

	; [#457] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #450 FILE_DEL_SCREEN,
	; box 209,202-230,212.  Record layout and evidence: pool header above.
HdaeUiObj_457:
	.long	0x0160002b				; +0x00 class id
	.short	450, 0xffff, 458, 456	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	209, 202, 230, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_457_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_457: the record's +0x16 caption pointer names this string
HdaeUiObj_457_Cap16:	.asciz	"MSP"

	; [#458] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 40 bytes, parent #450 FILE_DEL_SCREEN,
	; box 239,202-278,212.  Record layout and evidence: pool header above.
HdaeUiObj_458:
	.long	0x0160002b				; +0x00 class id
	.short	450, 0xffff, 459, 457	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	239, 202, 278, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_458_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_458: the record's +0x16 caption pointer names this string
HdaeUiObj_458_Cap16:	.asciz	"CUSTOM"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#459] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #450 FILE_DEL_SCREEN,
	; box 286,202-313,212.  Record layout and evidence: pool header above.
HdaeUiObj_459:
	.long	0x0160002b				; +0x00 class id
	.short	450, 0xffff, 460, 458	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	286, 202, 313, 212			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_459_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_459: the record's +0x16 caption pointer names this string
HdaeUiObj_459_Cap16:	.asciz	"MIDI"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#460] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #450 FILE_DEL_SCREEN,
	; box 43,59-43,198.  Record layout and evidence: pool header above.
HdaeUiObj_460:
	.long	0x0160002e				; +0x00 class id
	.short	450, 0xffff, 461, 459	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	43, 59, 43, 198			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#461] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #450 FILE_DEL_SCREEN,
	; box 43,58-250,58.  Record layout and evidence: pool header above.
HdaeUiObj_461:
	.long	0x0160002e				; +0x00 class id
	.short	450, 0xffff, 462, 460	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	43, 58, 250, 58			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#462] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #450 FILE_DEL_SCREEN,
	; box 43,198-250,198.  Record layout and evidence: pool header above.
HdaeUiObj_462:
	.long	0x0160002e				; +0x00 class id
	.short	450, 0xffff, 463, 461	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	43, 198, 250, 198			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#463] "DEL_EDIT_LSW"  class 0160:001B = KN5000 widget type 0x1B, 78 bytes, parent #450 FILE_DEL_SCREEN,
	; box 48,59-257,74.  Record layout and evidence: pool header above.
HdaeUiObj_463:
	.long	0x0160001b				; +0x00 class id
	.short	450, 0xffff, 464, 462	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 59, 257, 74			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0001	; +0x16 class body
	.long	HdaeUiObj_463_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239b8e				; +0x2E RAM address (every 0160:001B record)
	.short	0x001e, 0x012a	; +0x32 class body
	.long	0x00239b90				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_463: the record's +0x1C caption pointer names this string
HdaeUiObj_463_Cap1C:	.asciz	"CURRENT PANEL     "
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#464] "DEL_EDIT_PMT"  class 0160:001B = KN5000 widget type 0x1B, 78 bytes, parent #450 FILE_DEL_SCREEN,
	; box 48,76-257,91.  Record layout and evidence: pool header above.
HdaeUiObj_464:
	.long	0x0160001b				; +0x00 class id
	.short	450, 0xffff, 465, 463	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 76, 257, 91			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0002	; +0x16 class body
	.long	HdaeUiObj_464_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239b94				; +0x2E RAM address (every 0160:001B record)
	.short	0x001f, 0x012a	; +0x32 class body
	.long	0x00239b96				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_464: the record's +0x1C caption pointer names this string
HdaeUiObj_464_Cap1C:	.asciz	"PANEL MEMORY      "
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#465] "DEL_EDIT_SQT"  class 0160:001B = KN5000 widget type 0x1B, 78 bytes, parent #450 FILE_DEL_SCREEN,
	; box 48,91-257,106.  Record layout and evidence: pool header above.
HdaeUiObj_465:
	.long	0x0160001b				; +0x00 class id
	.short	450, 0xffff, 466, 464	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 91, 257, 106			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0003	; +0x16 class body
	.long	HdaeUiObj_465_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239b9a				; +0x2E RAM address (every 0160:001B record)
	.short	0x0020, 0x012a	; +0x32 class body
	.long	0x00239b9c				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_465: the record's +0x1C caption pointer names this string
HdaeUiObj_465_Cap1C:	.asciz	"SEQUENCER         "
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#466] "DEL_EDIT_CMP"  class 0160:001B = KN5000 widget type 0x1B, 78 bytes, parent #450 FILE_DEL_SCREEN,
	; box 48,106-257,121.  Record layout and evidence: pool header above.
HdaeUiObj_466:
	.long	0x0160001b				; +0x00 class id
	.short	450, 0xffff, 467, 465	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 106, 257, 121			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0004	; +0x16 class body
	.long	HdaeUiObj_466_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239ba0				; +0x2E RAM address (every 0160:001B record)
	.short	0x0021, 0x012a	; +0x32 class body
	.long	0x00239ba2				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_466: the record's +0x1C caption pointer names this string
HdaeUiObj_466_Cap1C:	.asciz	"COMPOSER          "
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#467] "DEL_EDIT_TM"  class 0160:001B = KN5000 widget type 0x1B, 78 bytes, parent #450 FILE_DEL_SCREEN,
	; box 48,121-257,136.  Record layout and evidence: pool header above.
HdaeUiObj_467:
	.long	0x0160001b				; +0x00 class id
	.short	450, 0xffff, 468, 466	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 121, 257, 136			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0005	; +0x16 class body
	.long	HdaeUiObj_467_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239ba6				; +0x2E RAM address (every 0160:001B record)
	.short	0x0022, 0x012a	; +0x32 class body
	.long	0x00239ba8				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_467: the record's +0x1C caption pointer names this string
HdaeUiObj_467_Cap1C:	.asciz	"SOUND MEMORY      "
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#468] "DEL_EDIT_MSP"  class 0160:001B = KN5000 widget type 0x1B, 78 bytes, parent #450 FILE_DEL_SCREEN,
	; box 48,136-257,151.  Record layout and evidence: pool header above.
HdaeUiObj_468:
	.long	0x0160001b				; +0x00 class id
	.short	450, 0xffff, 469, 467	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 136, 257, 151			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0006	; +0x16 class body
	.long	HdaeUiObj_468_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239bac				; +0x2E RAM address (every 0160:001B record)
	.short	0x0023, 0x012a	; +0x32 class body
	.long	0x00239bae				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_468: the record's +0x1C caption pointer names this string
HdaeUiObj_468_Cap1C:	.asciz	"MSP               "
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#469] "DEL_EDIT_RCM"  class 0160:001B = KN5000 widget type 0x1B, 78 bytes, parent #450 FILE_DEL_SCREEN,
	; box 48,151-257,166.  Record layout and evidence: pool header above.
HdaeUiObj_469:
	.long	0x0160001b				; +0x00 class id
	.short	450, 0xffff, 470, 468	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 151, 257, 166			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0007	; +0x16 class body
	.long	HdaeUiObj_469_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239bb2				; +0x2E RAM address (every 0160:001B record)
	.short	0x0024, 0x012a	; +0x32 class body
	.long	0x00239bb4				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_469: the record's +0x1C caption pointer names this string
HdaeUiObj_469_Cap1C:	.asciz	"RHYTHM CUSTOM     "
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#470] "DEL_EDIT_MD"  class 0160:001B = KN5000 widget type 0x1B, 78 bytes, parent #450 FILE_DEL_SCREEN,
	; box 48,166-257,181.  Record layout and evidence: pool header above.
HdaeUiObj_470:
	.long	0x0160001b				; +0x00 class id
	.short	450, 0xffff, 471, 469	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 166, 257, 181			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0008	; +0x16 class body
	.long	HdaeUiObj_470_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239bb8				; +0x2E RAM address (every 0160:001B record)
	.short	0x0025, 0x012a	; +0x32 class body
	.long	0x00239bba				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_470: the record's +0x1C caption pointer names this string
HdaeUiObj_470_Cap1C:	.asciz	"USER MIDI SETTINGS"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#471] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #450 FILE_DEL_SCREEN,
	; box 4,216-35,238.  Record layout and evidence: pool header above.
HdaeUiObj_471:
	.long	0x0160001f				; +0x00 class id
	.short	450, 0xffff, 472, 470	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 216, 35, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#472] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #450 FILE_DEL_SCREEN,
	; box 44,216-75,238.  Record layout and evidence: pool header above.
HdaeUiObj_472:
	.long	0x0160001f				; +0x00 class id
	.short	450, 0xffff, 473, 471	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 216, 75, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0002, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#473] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #450 FILE_DEL_SCREEN,
	; box 84,216-115,238.  Record layout and evidence: pool header above.
HdaeUiObj_473:
	.long	0x0160001f				; +0x00 class id
	.short	450, 0xffff, 474, 472	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	84, 216, 115, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#474] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #450 FILE_DEL_SCREEN,
	; box 124,216-155,238.  Record layout and evidence: pool header above.
HdaeUiObj_474:
	.long	0x0160001f				; +0x00 class id
	.short	450, 0xffff, 475, 473	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	124, 216, 155, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0004, 0x0000, 0x0000, 0x0000, 0x0000, 0x0003	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#475] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #450 FILE_DEL_SCREEN,
	; box 164,216-195,238.  Record layout and evidence: pool header above.
HdaeUiObj_475:
	.long	0x0160001f				; +0x00 class id
	.short	450, 0xffff, 476, 474	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	164, 216, 195, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0005, 0x0000, 0x0000, 0x0000, 0x0000, 0x0004	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#476] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #450 FILE_DEL_SCREEN,
	; box 204,216-235,238.  Record layout and evidence: pool header above.
HdaeUiObj_476:
	.long	0x0160001f				; +0x00 class id
	.short	450, 0xffff, 477, 475	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	204, 216, 235, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0006, 0x0000, 0x0000, 0x0000, 0x0000, 0x0005	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#477] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #450 FILE_DEL_SCREEN,
	; box 244,216-275,238.  Record layout and evidence: pool header above.
HdaeUiObj_477:
	.long	0x0160001f				; +0x00 class id
	.short	450, 0xffff, 478, 476	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 216, 275, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0007, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#478] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #450 FILE_DEL_SCREEN,
	; box 284,216-315,238.  Record layout and evidence: pool header above.
HdaeUiObj_478:
	.long	0x0160001f				; +0x00 class id
	.short	450, 0xffff, 479, 477	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	284, 216, 315, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0008, 0x0000, 0x0000, 0x0000, 0x0000, 0x0007	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#479] (unnamed)  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #450 FILE_DEL_SCREEN,
	; box 32,0-63,31.  Record layout and evidence: pool header above.
HdaeUiObj_479:
	.long	0x01600052				; +0x00 class id
	.short	450, 0xffff, 480, 478	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	32, 0, 63, 31			; +0x0E box x1, y1, x2, y2
	.short	0x001c, 0x012a	; +0x16 class body

	; [#480] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #450 FILE_DEL_SCREEN,
	; box 269,30-311,55.  Record layout and evidence: pool header above.
HdaeUiObj_480:
	.long	0x0160001f				; +0x00 class id
	.short	450, 481, 482, 479	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	269, 30, 311, 55			; +0x0E box x1, y1, x2, y2
	.short	0x00f2, 0x00c0, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0008	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#481] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #480,
	; box 276,35-303,53.  Record layout and evidence: pool header above.
HdaeUiObj_481:
	.long	0x0160002b				; +0x00 class id
	.short	480, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	276, 35, 303, 53			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_481_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_481: the record's +0x16 caption pointer names this string
HdaeUiObj_481_Cap16:	.asciz	"DEL"

	; [#482] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #450 FILE_DEL_SCREEN,
	; box 253,118-311,135.  Record layout and evidence: pool header above.
HdaeUiObj_482:
	.long	0x0160001f				; +0x00 class id
	.short	450, 483, 484, 480	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	253, 118, 311, 135			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x000a	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#483] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 40 bytes, parent #482,
	; box 253,119-312,137.  Record layout and evidence: pool header above.
HdaeUiObj_483:
	.long	0x0160002b				; +0x00 class id
	.short	482, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	253, 119, 312, 137			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_483_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_483: the record's +0x16 caption pointer names this string
HdaeUiObj_483_Cap16:	.asciz	"ALL DEL"

	; [#484] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #450 FILE_DEL_SCREEN,
	; box 253,160-311,177.  Record layout and evidence: pool header above.
HdaeUiObj_484:
	.long	0x0160001f				; +0x00 class id
	.short	450, 485, 486, 482	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	253, 160, 311, 177			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x000b	; +0x16 class body
	.short	0x0000	; +0x26 class body

	; [#485] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 40 bytes, parent #484,
	; box 253,161-312,179.  Record layout and evidence: pool header above.
HdaeUiObj_485:
	.long	0x0160002b				; +0x00 class id
	.short	484, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	253, 161, 312, 179			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_485_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_485: the record's +0x16 caption pointer names this string
HdaeUiObj_485_Cap16:	.asciz	"ALL OFF"

	; [#486] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 60 bytes, parent #450 FILE_DEL_SCREEN,
	; box 42,32-252,57.  Record layout and evidence: pool header above.
HdaeUiObj_486:
	.long	0x0160001b				; +0x00 class id
	.short	450, 0xffff, 487, 484	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	42, 32, 252, 57			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c1, 0xffff	; +0x16 class body
	.long	HdaeUiObj_486_Cap1C			; +0x1C caption pointer
	.short	0x0005, 0x0000, 0x00ff, 0x0001, 0x0004, 0x00ff, 0x0001	; +0x20 class body
	.long	0x00239bbe				; +0x2E RAM address (every 0160:001B record)
	.short	0x001d, 0x012a	; +0x32 class body
	.long	0x00239bc0				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_486: the record's +0x1C caption pointer names this string
HdaeUiObj_486_Cap1C:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#487] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #450 FILE_DEL_SCREEN,
	; box 8,158-39,179.  Record layout and evidence: pool header above.
HdaeUiObj_487:
	.long	0x0160001f				; +0x00 class id
	.short	450, 0xffff, 488, 486	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 158, 39, 179			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0009, 0x0000, 0x0000, 0x0000, 0x0000, 0x008b	; +0x16 class body
	.short	0x0003	; +0x26 class body

	; [#488] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #450 FILE_DEL_SCREEN,
	; box 6,147-39,157.  Record layout and evidence: pool header above.
HdaeUiObj_488:
	.long	0x0160002b				; +0x00 class id
	.short	450, 0xffff, 489, 487	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	6, 147, 39, 157			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_488_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_488: the record's +0x16 caption pointer names this string
HdaeUiObj_488_Cap16:	.asciz	"LYRIC"

	; [#489] "DEL_EDIT_TLX"  class 0160:001B = KN5000 widget type 0x1B, 78 bytes, parent #450 FILE_DEL_SCREEN,
	; box 48,181-257,196.  Record layout and evidence: pool header above.
HdaeUiObj_489:
	.long	0x0160001b				; +0x00 class id
	.short	450, 0xffff, 490, 488	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	48, 181, 257, 196			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0009	; +0x16 class body
	.long	HdaeUiObj_489_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0005, 0x00ff, 0x0000	; +0x20 class body
	.long	0x00239bc4				; +0x2E RAM address (every 0160:001B record)
	.short	0x0026, 0x012a	; +0x32 class body
	.long	0x00239bc6				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_489: the record's +0x1C caption pointer names this string
HdaeUiObj_489_Cap1C:	.asciz	"TECHNICS LYRICS   "
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#490] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #450 FILE_DEL_SCREEN,
	; box 205,59-205,198.  Record layout and evidence: pool header above.
HdaeUiObj_490:
	.long	0x0160002e				; +0x00 class id
	.short	450, 0xffff, 491, 489	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	205, 59, 205, 198			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#491] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #450 FILE_DEL_SCREEN,
	; box 250,59-250,198.  Record layout and evidence: pool header above.
HdaeUiObj_491:
	.long	0x0160002e				; +0x00 class id
	.short	450, 0xffff, 0xffff, 490	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	250, 59, 250, 198			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#492] "HDD_ICON_DISPLAY"  class 0160:0033 = KN5000 widget type 0x33, 34 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_492:
	.long	0x01600033				; +0x00 class id
	.short	0xffff, 493, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239bca				; +0x1E RAM address (every 0160:0033 record)

	; [#493] "HD_MENU_BMP"  class 0160:0069 = KN5000 widget type 0x69, 26 bytes, parent #492 HDD_ICON_DISPLAY,
	; box 282,197-308,223.  Record layout and evidence: pool header above.
HdaeUiObj_493:
	.long	0x01600069				; +0x00 class id
	.short	492, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	282, 197, 308, 223			; +0x0E box x1, y1, x2, y2
	.short	0x0027, 0x012a	; +0x16 class body

	; [#494] "IV_HDDMENU"  class 016A:0009 = ClassName_Table[9] "IvScreenR2Proc", 34 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_494:
	.long	0x016a0009				; +0x00 class id
	.short	0xffff, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239bce				; +0x1E RAM address (every 016A:0009 record)

	; [#495] "ATTEN_DEL_DIR"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_495:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 496, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239bd2				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_495_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_495: the record's +0x22 caption pointer names this string
HdaeUiObj_495_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#496] (unnamed)  class 0160:003F = KN5000 widget type 0x3F, 48 bytes, parent #495 ATTEN_DEL_DIR,
	; box 4,216-75,238.  Record layout and evidence: pool header above.
HdaeUiObj_496:
	.long	0x0160003f				; +0x00 class id
	.short	495, 497, 498, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 216, 75, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000	; +0x16 class body
	.short	0x0001, 0x0000	; +0x26 class body
	.long	HdaeUiObj_496_Cap2A			; +0x2A caption pointer
	; caption of HdaeUiObj_496: the record's +0x2A caption pointer names this string
HdaeUiObj_496_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#497] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #496,
	; box 4,220-75,239.  Record layout and evidence: pool header above.
HdaeUiObj_497:
	.long	0x016a000a				; +0x00 class id
	.short	496, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 220, 75, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00c8, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#498] (unnamed)  class 0160:003F = KN5000 widget type 0x3F, 48 bytes, parent #495 ATTEN_DEL_DIR,
	; box 244,216-315,238.  Record layout and evidence: pool header above.
HdaeUiObj_498:
	.long	0x0160003f				; +0x00 class id
	.short	495, 499, 500, 496	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 216, 315, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0007, 0x0000	; +0x26 class body
	.long	HdaeUiObj_498_Cap2A			; +0x2A caption pointer
	; caption of HdaeUiObj_498: the record's +0x2A caption pointer names this string
HdaeUiObj_498_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#499] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #498,
	; box 248,220-315,239.  Record layout and evidence: pool header above.
HdaeUiObj_499:
	.long	0x016a000a				; +0x00 class id
	.short	498, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	248, 220, 315, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00c9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#500] (unnamed)  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #495 ATTEN_DEL_DIR,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_500:
	.long	0x01600052				; +0x00 class id
	.short	495, 0xffff, 501, 498	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0034, 0x012a	; +0x16 class body

	; [#501] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #495 ATTEN_DEL_DIR,
	; box 40,76-279,205.  Record layout and evidence: pool header above.
HdaeUiObj_501:
	.long	0x016a000a				; +0x00 class id
	.short	495, 502, 0xffff, 500	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 76, 279, 205			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x00d2, 0x0002, 0x0000, 0x0000, 0x0000, 0x0004	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#502] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #501,
	; box 44,155-275,204.  Record layout and evidence: pool header above.
HdaeUiObj_502:
	.long	0x016a000a				; +0x00 class id
	.short	501, 0xffff, 503, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 155, 275, 204			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d3, 0x0007, 0x0000, 0x0000, 0x0000, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#503] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #501,
	; box 44,108-275,155.  Record layout and evidence: pool header above.
HdaeUiObj_503:
	.long	0x016a000a				; +0x00 class id
	.short	501, 0xffff, 0xffff, 502	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 108, 275, 155			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0001, 0x0007, 0x0000, 0x000a, 0x0000, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#504] "WAIT_DEL_DIR"  class 0160:0035 = KN5000 widget type 0x35, 36 bytes, parent none (root),
	; box 26,30-293,81.  Record layout and evidence: pool header above.
HdaeUiObj_504:
	.long	0x01600035				; +0x00 class id
	.short	0xffff, 505, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	26, 30, 293, 81			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0x0000	; +0x16 class body
	.long	0x00239bd6				; +0x1C RAM address (every 0160:0035 record)
	.long	0x00239bda				; +0x20 RAM address (every 0160:0035 record)

	; [#505] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 66 bytes, parent #504 WAIT_DEL_DIR,
	; box 30,32-289,50.  Record layout and evidence: pool header above.
HdaeUiObj_505:
	.long	0x0160002b				; +0x00 class id
	.short	504, 0xffff, 506, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	30, 32, 289, 50			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_505_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_505: the record's +0x16 caption pointer names this string
HdaeUiObj_505_Cap16:	.asciz	"DELETE DIRECTORY FROM HARD DISK:"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#506] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 48 bytes, parent #504 WAIT_DEL_DIR,
	; box 30,54-273,72.  Record layout and evidence: pool header above.
HdaeUiObj_506:
	.long	0x0160002b				; +0x00 class id
	.short	504, 0xffff, 0xffff, 505	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	30, 54, 273, 72			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_506_Cap16			; +0x16 caption pointer
	.short	0x0002, 0x0000, 0x000a	; +0x1A class body
	; caption of HdaeUiObj_506: the record's +0x16 caption pointer names this string
HdaeUiObj_506_Cap16:	.asciz	"PLEASE WAIT ..."

	; [#507] "ATTEN_DEL_FILE"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_507:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 508, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239bde				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_507_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_507: the record's +0x22 caption pointer names this string
HdaeUiObj_507_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#508] (unnamed)  class 0160:003F = KN5000 widget type 0x3F, 48 bytes, parent #507 ATTEN_DEL_FILE,
	; box 4,216-75,238.  Record layout and evidence: pool header above.
HdaeUiObj_508:
	.long	0x0160003f				; +0x00 class id
	.short	507, 0xffff, 509, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 216, 75, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000	; +0x16 class body
	.short	0x0001, 0x0000	; +0x26 class body
	.long	HdaeUiObj_508_Cap2A			; +0x2A caption pointer
	; caption of HdaeUiObj_508: the record's +0x2A caption pointer names this string
HdaeUiObj_508_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#509] (unnamed)  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #507 ATTEN_DEL_FILE,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_509:
	.long	0x01600052				; +0x00 class id
	.short	507, 0xffff, 510, 508	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0035, 0x012a	; +0x16 class body

	; [#510] (unnamed)  class 0160:003F = KN5000 widget type 0x3F, 48 bytes, parent #507 ATTEN_DEL_FILE,
	; box 244,216-315,238.  Record layout and evidence: pool header above.
HdaeUiObj_510:
	.long	0x0160003f				; +0x00 class id
	.short	507, 0xffff, 511, 509	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 216, 315, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0007, 0x0000	; +0x26 class body
	.long	HdaeUiObj_510_Cap2A			; +0x2A caption pointer
	; caption of HdaeUiObj_510: the record's +0x2A caption pointer names this string
HdaeUiObj_510_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#511] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #507 ATTEN_DEL_FILE,
	; box 40,76-279,205.  Record layout and evidence: pool header above.
HdaeUiObj_511:
	.long	0x016a000a				; +0x00 class id
	.short	507, 512, 514, 510	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 76, 279, 205			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x00d2, 0x0002, 0x0000, 0x0000, 0x0000, 0x0004	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#512] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #511,
	; box 44,155-275,204.  Record layout and evidence: pool header above.
HdaeUiObj_512:
	.long	0x016a000a				; +0x00 class id
	.short	511, 0xffff, 513, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 155, 275, 204			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d3, 0x0007, 0x0000, 0x0000, 0x0000, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#513] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #511,
	; box 44,108-275,155.  Record layout and evidence: pool header above.
HdaeUiObj_513:
	.long	0x016a000a				; +0x00 class id
	.short	511, 0xffff, 0xffff, 512	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 108, 275, 155			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0002, 0x0007, 0x0000, 0x000a, 0x0000, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#514] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #507 ATTEN_DEL_FILE,
	; box 4,220-75,239.  Record layout and evidence: pool header above.
HdaeUiObj_514:
	.long	0x016a000a				; +0x00 class id
	.short	507, 0xffff, 515, 511	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 220, 75, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00c8, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#515] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #507 ATTEN_DEL_FILE,
	; box 248,220-315,239.  Record layout and evidence: pool header above.
HdaeUiObj_515:
	.long	0x016a000a				; +0x00 class id
	.short	507, 0xffff, 0xffff, 514	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	248, 220, 315, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00c9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#516] "ATTEN_OVER_FLS"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_516:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 517, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239be2				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_516_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_516: the record's +0x22 caption pointer names this string
HdaeUiObj_516_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#517] (unnamed)  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #516 ATTEN_OVER_FLS,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_517:
	.long	0x01600052				; +0x00 class id
	.short	516, 0xffff, 518, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x003b, 0x012a	; +0x16 class body

	; [#518] (unnamed)  class 0160:003F = KN5000 widget type 0x3F, 48 bytes, parent #516 ATTEN_OVER_FLS,
	; box 4,216-75,238.  Record layout and evidence: pool header above.
HdaeUiObj_518:
	.long	0x0160003f				; +0x00 class id
	.short	516, 519, 520, 517	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 216, 75, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000	; +0x16 class body
	.short	0x0001, 0x0000	; +0x26 class body
	.long	HdaeUiObj_518_Cap2A			; +0x2A caption pointer
	; caption of HdaeUiObj_518: the record's +0x2A caption pointer names this string
HdaeUiObj_518_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#519] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #518,
	; box 4,220-75,239.  Record layout and evidence: pool header above.
HdaeUiObj_519:
	.long	0x016a000a				; +0x00 class id
	.short	518, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 220, 75, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00c8, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#520] (unnamed)  class 0160:003F = KN5000 widget type 0x3F, 48 bytes, parent #516 ATTEN_OVER_FLS,
	; box 244,216-315,238.  Record layout and evidence: pool header above.
HdaeUiObj_520:
	.long	0x0160003f				; +0x00 class id
	.short	516, 521, 522, 518	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 216, 315, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0007, 0x0000	; +0x26 class body
	.long	HdaeUiObj_520_Cap2A			; +0x2A caption pointer
	; caption of HdaeUiObj_520: the record's +0x2A caption pointer names this string
HdaeUiObj_520_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#521] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #520,
	; box 248,220-315,239.  Record layout and evidence: pool header above.
HdaeUiObj_521:
	.long	0x016a000a				; +0x00 class id
	.short	520, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	248, 220, 315, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00c9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#522] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #516 ATTEN_OVER_FLS,
	; box 40,76-279,205.  Record layout and evidence: pool header above.
HdaeUiObj_522:
	.long	0x016a000a				; +0x00 class id
	.short	516, 523, 0xffff, 520	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 76, 279, 205			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x00d2, 0x0002, 0x0000, 0x0000, 0x0000, 0x0004	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#523] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #522,
	; box 44,155-275,204.  Record layout and evidence: pool header above.
HdaeUiObj_523:
	.long	0x016a000a				; +0x00 class id
	.short	522, 0xffff, 524, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 155, 275, 204			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d3, 0x0007, 0x0000, 0x0000, 0x0000, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#524] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #522,
	; box 44,108-275,155.  Record layout and evidence: pool header above.
HdaeUiObj_524:
	.long	0x016a000a				; +0x00 class id
	.short	522, 0xffff, 0xffff, 523	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 108, 275, 155			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x001c, 0x0007, 0x0000, 0x000a, 0x0000, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#525] "ATTEN_DEL_FLS2"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_525:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 526, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239be6				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_525_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_525: the record's +0x22 caption pointer names this string
HdaeUiObj_525_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#526] (unnamed)  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #525 ATTEN_DEL_FLS2,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_526:
	.long	0x01600052				; +0x00 class id
	.short	525, 0xffff, 527, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x003a, 0x012a	; +0x16 class body

	; [#527] (unnamed)  class 0160:003F = KN5000 widget type 0x3F, 48 bytes, parent #525 ATTEN_DEL_FLS2,
	; box 4,216-75,238.  Record layout and evidence: pool header above.
HdaeUiObj_527:
	.long	0x0160003f				; +0x00 class id
	.short	525, 528, 529, 526	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 216, 75, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000	; +0x16 class body
	.short	0x0001, 0x0000	; +0x26 class body
	.long	HdaeUiObj_527_Cap2A			; +0x2A caption pointer
	; caption of HdaeUiObj_527: the record's +0x2A caption pointer names this string
HdaeUiObj_527_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#528] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #527,
	; box 4,220-75,239.  Record layout and evidence: pool header above.
HdaeUiObj_528:
	.long	0x016a000a				; +0x00 class id
	.short	527, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 220, 75, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00c8, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#529] (unnamed)  class 0160:003F = KN5000 widget type 0x3F, 48 bytes, parent #525 ATTEN_DEL_FLS2,
	; box 244,216-315,238.  Record layout and evidence: pool header above.
HdaeUiObj_529:
	.long	0x0160003f				; +0x00 class id
	.short	525, 530, 531, 527	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 216, 315, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0007, 0x0000	; +0x26 class body
	.long	HdaeUiObj_529_Cap2A			; +0x2A caption pointer
	; caption of HdaeUiObj_529: the record's +0x2A caption pointer names this string
HdaeUiObj_529_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#530] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #529,
	; box 248,220-315,239.  Record layout and evidence: pool header above.
HdaeUiObj_530:
	.long	0x016a000a				; +0x00 class id
	.short	529, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	248, 220, 315, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00c9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#531] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #525 ATTEN_DEL_FLS2,
	; box 40,44-279,209.  Record layout and evidence: pool header above.
HdaeUiObj_531:
	.long	0x016a000a				; +0x00 class id
	.short	525, 532, 0xffff, 529	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 44, 279, 209			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x00d2, 0x0002, 0x0000, 0x0000, 0x0000, 0x0005	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#532] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #531,
	; box 44,160-275,209.  Record layout and evidence: pool header above.
HdaeUiObj_532:
	.long	0x016a000a				; +0x00 class id
	.short	531, 0xffff, 533, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 160, 275, 209			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d3, 0x0007, 0x0000, 0x0000, 0x0000, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#533] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #531,
	; box 44,76-275,123.  Record layout and evidence: pool header above.
HdaeUiObj_533:
	.long	0x016a000a				; +0x00 class id
	.short	531, 0xffff, 534, 532	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 76, 275, 123			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x001b, 0x0007, 0x0000, 0x000a, 0x0000, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#534] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #531,
	; box 44,124-275,159.  Record layout and evidence: pool header above.
HdaeUiObj_534:
	.long	0x016a000a				; +0x00 class id
	.short	531, 0xffff, 0xffff, 533	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 124, 275, 159			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x003d, 0x0007, 0x0000, 0x00fb, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#535] "WAIT_DEL_FILE"  class 0160:0035 = KN5000 widget type 0x35, 36 bytes, parent none (root),
	; box 26,30-293,85.  Record layout and evidence: pool header above.
HdaeUiObj_535:
	.long	0x01600035				; +0x00 class id
	.short	0xffff, 536, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	26, 30, 293, 85			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0000	; +0x16 class body
	.long	0x00239bea				; +0x1C RAM address (every 0160:0035 record)
	.long	0x00239bee				; +0x20 RAM address (every 0160:0035 record)

	; [#536] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #535 WAIT_DEL_FILE,
	; box 40,34-279,57.  Record layout and evidence: pool header above.
HdaeUiObj_536:
	.long	0x016a000a				; +0x00 class id
	.short	535, 0xffff, 537, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 34, 279, 57			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0038, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#537] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #535 WAIT_DEL_FILE,
	; box 32,56-291,79.  Record layout and evidence: pool header above.
HdaeUiObj_537:
	.long	0x016a000a				; +0x00 class id
	.short	535, 0xffff, 0xffff, 536	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	32, 56, 291, 79			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0031, 0x0002, 0x0000, 0x00f9, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#538] "ATTEN_HD_FORMAT"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 56 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_538:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 539, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239bf2				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_538_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_538: the record's +0x22 caption pointer names this string
HdaeUiObj_538_Cap22:	.asciz	"   HD FORMAT"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#539] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #538 ATTEN_HD_FORMAT,
	; box 36,38-283,213.  Record layout and evidence: pool header above.
HdaeUiObj_539:
	.long	0x01600036				; +0x00 class id
	.short	538, 540, 544, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	36, 38, 283, 213			; +0x0E box x1, y1, x2, y2
	.short	0x00f9, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_539_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0005	; +0x1E class body
	; caption of HdaeUiObj_539: the record's +0x1A caption pointer names this string
HdaeUiObj_539_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#540] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #539,
	; box 38,70-281,103.  Record layout and evidence: pool header above.
HdaeUiObj_540:
	.long	0x016a000a				; +0x00 class id
	.short	539, 0xffff, 541, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	38, 70, 281, 103			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0018, 0x0007, 0x0000, 0x00f1, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#541] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #539,
	; box 38,164-281,211.  Record layout and evidence: pool header above.
HdaeUiObj_541:
	.long	0x016a000a				; +0x00 class id
	.short	539, 0xffff, 542, 540	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	38, 164, 281, 211			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x001a, 0x0007, 0x0000, 0x00f1, 0x0000, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#542] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #539,
	; box 38,104-281,167.  Record layout and evidence: pool header above.
HdaeUiObj_542:
	.long	0x016a000a				; +0x00 class id
	.short	539, 0xffff, 543, 541	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	38, 104, 281, 167			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0019, 0x0007, 0x0000, 0x0000, 0x0000, 0x0004	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#543] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #539,
	; box 38,46-281,69.  Record layout and evidence: pool header above.
HdaeUiObj_543:
	.long	0x016a000a				; +0x00 class id
	.short	539, 0xffff, 0xffff, 542	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	38, 46, 281, 69			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d2, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#544] (unnamed)  class 0160:0069 = KN5000 widget type 0x69, 26 bytes, parent #538 ATTEN_HD_FORMAT,
	; box 93,1-119,27.  Record layout and evidence: pool header above.
HdaeUiObj_544:
	.long	0x01600069				; +0x00 class id
	.short	538, 0xffff, 545, 539	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	93, 1, 119, 27			; +0x0E box x1, y1, x2, y2
	.short	0x0027, 0x012a	; +0x16 class body

	; [#545] (unnamed)  class 0160:003F = KN5000 widget type 0x3F, 54 bytes, parent #538 ATTEN_HD_FORMAT,
	; box 244,216-315,238.  Record layout and evidence: pool header above.
HdaeUiObj_545:
	.long	0x0160003f				; +0x00 class id
	.short	538, 0xffff, 546, 544	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 216, 315, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0007, 0x0000	; +0x26 class body
	.long	HdaeUiObj_545_Cap2A			; +0x2A caption pointer
	; caption of HdaeUiObj_545: the record's +0x2A caption pointer names this string
HdaeUiObj_545_Cap2A:	.asciz	"CANCEL"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#546] "HD_FORMAT_CATCH"  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #538 ATTEN_HD_FORMAT,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_546:
	.long	0x01600052				; +0x00 class id
	.short	538, 0xffff, 0xffff, 545	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0036, 0x012a	; +0x16 class body

	; [#547] "WAIT_HD_FORMAT"  class 0160:0035 = KN5000 widget type 0x35, 36 bytes, parent none (root),
	; box 26,30-293,213.  Record layout and evidence: pool header above.
HdaeUiObj_547:
	.long	0x01600035				; +0x00 class id
	.short	0xffff, 548, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	26, 30, 293, 213			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0000	; +0x16 class body
	.long	0x00239bf6				; +0x1C RAM address (every 0160:0035 record)
	.long	0x00239bfa				; +0x20 RAM address (every 0160:0035 record)

	; [#548] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #547 WAIT_HD_FORMAT,
	; box 32,38-287,93.  Record layout and evidence: pool header above.
HdaeUiObj_548:
	.long	0x016a000a				; +0x00 class id
	.short	547, 0xffff, 549, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	32, 38, 287, 93			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0039, 0x0000, 0x0000, 0x0000, 0x0001, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#549] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #547 WAIT_HD_FORMAT,
	; box 32,98-287,153.  Record layout and evidence: pool header above.
HdaeUiObj_549:
	.long	0x016a000a				; +0x00 class id
	.short	547, 0xffff, 550, 548	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	32, 98, 287, 153			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x003a, 0x0000, 0x0000, 0x0000, 0x0001, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#550] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #547 WAIT_HD_FORMAT,
	; box 32,154-291,201.  Record layout and evidence: pool header above.
HdaeUiObj_550:
	.long	0x016a000a				; +0x00 class id
	.short	547, 0xffff, 0xffff, 549	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	32, 154, 291, 201			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0031, 0x0002, 0x0000, 0x00f9, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#551] "SETUP_HDINFO"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_551:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 552, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239bfe				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_551_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_551: the record's +0x22 caption pointer names this string
HdaeUiObj_551_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#552] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #551 SETUP_HDINFO,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_552:
	.long	0x01600049				; +0x00 class id
	.short	551, 0xffff, 553, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0013, 0x007f	; +0x16 class body

	; [#553] (unnamed)  class 0160:0037 = KN5000 widget type 0x37, 46 bytes, parent #551 SETUP_HDINFO,
	; box 100,12-219,51.  Record layout and evidence: pool header above.
HdaeUiObj_553:
	.long	0x01600037				; +0x00 class id
	.short	551, 0xffff, 554, 552	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	100, 12, 219, 51			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c1	; +0x16 class body
	.long	HdaeUiObj_553_Cap1A			; +0x1A caption pointer
	.short	0x0004, 0x0000, 0x00ff, 0x0000	; +0x1E class body
	; caption of HdaeUiObj_553: the record's +0x1A caption pointer names this string
HdaeUiObj_553_Cap1A:	.asciz	"HD-INFO"

	; [#554] "HD_INFO_LIST"  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #551 SETUP_HDINFO,
	; box 3,72-316,221.  Record layout and evidence: pool header above.
HdaeUiObj_554:
	.long	0x016a0000				; +0x00 class id
	.short	551, 555, 0xffff, 553	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	3, 72, 316, 221			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x00c0, 0xffff, 0x0000, 0x0000, 0x00ff, 0x0000, 0x0140	; +0x16 class body
	.long	0x00239c02				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0008	; +0x2A class body
	.long	0x00239c06				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x00239c08				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#555] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #554 HD_INFO_LIST,
	; box 3,199-316,199.  Record layout and evidence: pool header above.
HdaeUiObj_555:
	.long	0x0160002e				; +0x00 class id
	.short	554, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	3, 199, 316, 199			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0001	; +0x16 class body

	; [#556] "DBG_MEMO_SCREEN"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 60 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_556:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 557, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c0a				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_556_Cap22			; +0x22 caption pointer
	.short	0x0001, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_556: the record's +0x22 caption pointer names this string
HdaeUiObj_556_Cap22:	.asciz	"DEBUG MEMO SCREEN"

	; [#557] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #556 DBG_MEMO_SCREEN,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_557:
	.long	0x01600049				; +0x00 class id
	.short	556, 0xffff, 558, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x007f	; +0x16 class body

	; [#558] (unnamed)  class 0160:0046 = KN5000 widget type 0x46, 22 bytes, parent #556 DBG_MEMO_SCREEN,
	; box 10,40-308,229.  Record layout and evidence: pool header above.
HdaeUiObj_558:
	.long	0x01600046				; +0x00 class id
	.short	556, 0xffff, 0xffff, 557	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	10, 40, 308, 229			; +0x0E box x1, y1, x2, y2

	; [#559] "ATTEN_DEL_FLS1"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_559:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 560, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c0e				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_559_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_559: the record's +0x22 caption pointer names this string
HdaeUiObj_559_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#560] (unnamed)  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #559 ATTEN_DEL_FLS1,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_560:
	.long	0x01600052				; +0x00 class id
	.short	559, 0xffff, 561, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0039, 0x012a	; +0x16 class body

	; [#561] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #559 ATTEN_DEL_FLS1,
	; box 40,44-279,209.  Record layout and evidence: pool header above.
HdaeUiObj_561:
	.long	0x016a000a				; +0x00 class id
	.short	559, 562, 565, 560	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 44, 279, 209			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x00d2, 0x0002, 0x0000, 0x0000, 0x0000, 0x0005	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#562] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #561,
	; box 44,158-275,207.  Record layout and evidence: pool header above.
HdaeUiObj_562:
	.long	0x016a000a				; +0x00 class id
	.short	561, 0xffff, 563, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 158, 275, 207			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d3, 0x0007, 0x0000, 0x0000, 0x0000, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#563] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #561,
	; box 44,76-275,123.  Record layout and evidence: pool header above.
HdaeUiObj_563:
	.long	0x016a000a				; +0x00 class id
	.short	561, 0xffff, 564, 562	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 76, 275, 123			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x001b, 0x0007, 0x0000, 0x000a, 0x0000, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#564] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #561,
	; box 44,124-275,159.  Record layout and evidence: pool header above.
HdaeUiObj_564:
	.long	0x016a000a				; +0x00 class id
	.short	561, 0xffff, 0xffff, 563	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 124, 275, 159			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x003c, 0x0007, 0x0000, 0x00fb, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#565] (unnamed)  class 0160:003F = KN5000 widget type 0x3F, 48 bytes, parent #559 ATTEN_DEL_FLS1,
	; box 4,216-75,238.  Record layout and evidence: pool header above.
HdaeUiObj_565:
	.long	0x0160003f				; +0x00 class id
	.short	559, 566, 567, 561	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 216, 75, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000	; +0x16 class body
	.short	0x0001, 0x0000	; +0x26 class body
	.long	HdaeUiObj_565_Cap2A			; +0x2A caption pointer
	; caption of HdaeUiObj_565: the record's +0x2A caption pointer names this string
HdaeUiObj_565_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#566] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #565,
	; box 4,220-75,239.  Record layout and evidence: pool header above.
HdaeUiObj_566:
	.long	0x016a000a				; +0x00 class id
	.short	565, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 220, 75, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00c8, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#567] (unnamed)  class 0160:003F = KN5000 widget type 0x3F, 48 bytes, parent #559 ATTEN_DEL_FLS1,
	; box 4,216-75,238.  Record layout and evidence: pool header above.
HdaeUiObj_567:
	.long	0x0160003f				; +0x00 class id
	.short	559, 568, 569, 565	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 216, 75, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000	; +0x16 class body
	.short	0x0001, 0x0000	; +0x26 class body
	.long	HdaeUiObj_567_Cap2A			; +0x2A caption pointer
	; caption of HdaeUiObj_567: the record's +0x2A caption pointer names this string
HdaeUiObj_567_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#568] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #567,
	; box 4,220-75,239.  Record layout and evidence: pool header above.
HdaeUiObj_568:
	.long	0x016a000a				; +0x00 class id
	.short	567, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 220, 75, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00c8, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#569] (unnamed)  class 0160:003F = KN5000 widget type 0x3F, 48 bytes, parent #559 ATTEN_DEL_FLS1,
	; box 244,216-315,238.  Record layout and evidence: pool header above.
HdaeUiObj_569:
	.long	0x0160003f				; +0x00 class id
	.short	559, 570, 0xffff, 567	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 216, 315, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0007, 0x0000	; +0x26 class body
	.long	HdaeUiObj_569_Cap2A			; +0x2A caption pointer
	; caption of HdaeUiObj_569: the record's +0x2A caption pointer names this string
HdaeUiObj_569_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#570] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #569,
	; box 248,220-315,239.  Record layout and evidence: pool header above.
HdaeUiObj_570:
	.long	0x016a000a				; +0x00 class id
	.short	569, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	248, 220, 315, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00c9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#571] "ATTEN_OVER_FILE"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_571:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 572, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c12				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_571_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_571: the record's +0x22 caption pointer names this string
HdaeUiObj_571_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#572] (unnamed)  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #571 ATTEN_OVER_FILE,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_572:
	.long	0x01600052				; +0x00 class id
	.short	571, 0xffff, 573, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x001a, 0x012a	; +0x16 class body

	; [#573] (unnamed)  class 0160:003F = KN5000 widget type 0x3F, 48 bytes, parent #571 ATTEN_OVER_FILE,
	; box 4,216-75,238.  Record layout and evidence: pool header above.
HdaeUiObj_573:
	.long	0x0160003f				; +0x00 class id
	.short	571, 574, 575, 572	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 216, 75, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000	; +0x16 class body
	.short	0x0001, 0x0000	; +0x26 class body
	.long	HdaeUiObj_573_Cap2A			; +0x2A caption pointer
	; caption of HdaeUiObj_573: the record's +0x2A caption pointer names this string
HdaeUiObj_573_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#574] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #573,
	; box 4,220-75,239.  Record layout and evidence: pool header above.
HdaeUiObj_574:
	.long	0x016a000a				; +0x00 class id
	.short	573, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	4, 220, 75, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00c8, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#575] (unnamed)  class 0160:003F = KN5000 widget type 0x3F, 48 bytes, parent #571 ATTEN_OVER_FILE,
	; box 244,216-315,238.  Record layout and evidence: pool header above.
HdaeUiObj_575:
	.long	0x0160003f				; +0x00 class id
	.short	571, 0xffff, 576, 573	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 216, 315, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0007, 0x0000	; +0x26 class body
	.long	HdaeUiObj_575_Cap2A			; +0x2A caption pointer
	; caption of HdaeUiObj_575: the record's +0x2A caption pointer names this string
HdaeUiObj_575_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#576] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #571 ATTEN_OVER_FILE,
	; box 248,220-315,239.  Record layout and evidence: pool header above.
HdaeUiObj_576:
	.long	0x016a000a				; +0x00 class id
	.short	571, 0xffff, 577, 575	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	248, 220, 315, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00c9, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#577] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #571 ATTEN_OVER_FILE,
	; box 40,52-279,205.  Record layout and evidence: pool header above.
HdaeUiObj_577:
	.long	0x016a000a				; +0x00 class id
	.short	571, 578, 0xffff, 576	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 52, 279, 205			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x00d2, 0x0002, 0x0000, 0x0000, 0x0000, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#578] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #577,
	; box 40,92-279,151.  Record layout and evidence: pool header above.
HdaeUiObj_578:
	.long	0x016a000a				; +0x00 class id
	.short	577, 0xffff, 579, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 92, 279, 151			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0043, 0x0007, 0x0000, 0x000a, 0x0000, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#579] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #577,
	; box 40,156-279,205.  Record layout and evidence: pool header above.
HdaeUiObj_579:
	.long	0x016a000a				; +0x00 class id
	.short	577, 0xffff, 0xffff, 578	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 156, 279, 205			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d3, 0x0007, 0x0000, 0x0000, 0x0000, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#580] "HDD_FLS_NAMING2"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 56 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_580:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 581, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c16				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_580_Cap22			; +0x22 caption pointer
	.short	0x00af, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_580: the record's +0x22 caption pointer names this string
HdaeUiObj_580_Cap22:	.asciz	"EDIT FLS NAME"

	; [#581] (unnamed)  class 0160:004D = KN5000 widget type 0x4D, 26 bytes, parent #580 HDD_FLS_NAMING2,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_581:
	.long	0x0160004d				; +0x00 class id
	.short	580, 0xffff, 582, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0018, 0x012a	; +0x16 class body

	; [#582] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #580 HDD_FLS_NAMING2,
	; box 32,0-63,31.  Record layout and evidence: pool header above.
HdaeUiObj_582:
	.long	0x01600049				; +0x00 class id
	.short	580, 0xffff, 583, 581	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	32, 0, 63, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0163, 0x007f	; +0x16 class body

	; [#583] (unnamed)  class 0160:0020 = KN5000 widget type 0x20, 44 bytes, parent #580 HDD_FLS_NAMING2,
	; box 281,160-311,177.  Record layout and evidence: pool header above.
HdaeUiObj_583:
	.long	0x01600020				; +0x00 class id
	.short	580, 0xffff, 584, 582	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	281, 160, 311, 177			; +0x0E box x1, y1, x2, y2
	.short	0x00f2, 0x00c1, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x000b	; +0x16 class body
	.short	0x0006, 0x0017, 0x012a	; +0x26 class body

	; [#584] (unnamed)  class 0160:0020 = KN5000 widget type 0x20, 44 bytes, parent #580 HDD_FLS_NAMING2,
	; box 8,118-38,135.  Record layout and evidence: pool header above.
HdaeUiObj_584:
	.long	0x01600020				; +0x00 class id
	.short	580, 585, 0xffff, 583	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 118, 38, 135			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c1, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x008a	; +0x16 class body
	.short	0x0000, 0x0017, 0x012a	; +0x26 class body

	; [#585] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 36 bytes, parent #584,
	; box 9,119-36,137.  Record layout and evidence: pool header above.
HdaeUiObj_585:
	.long	0x0160002b				; +0x00 class id
	.short	584, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	9, 119, 36, 137			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_585_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x00f9	; +0x1A class body
	; caption of HdaeUiObj_585: the record's +0x16 caption pointer names this string
HdaeUiObj_585_Cap16:	.asciz	"LST"

	; [#586] "ATTEN_CPHD_WR"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_586:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 587, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c1a				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_586_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_586: the record's +0x22 caption pointer names this string
HdaeUiObj_586_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#587] (unnamed)  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #586 ATTEN_CPHD_WR,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_587:
	.long	0x01600052				; +0x00 class id
	.short	586, 0xffff, 588, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0037, 0x012a	; +0x16 class body

	; [#588] (unnamed)  class 0160:003F = KN5000 widget type 0x3F, 48 bytes, parent #586 ATTEN_CPHD_WR,
	; box 244,216-315,238.  Record layout and evidence: pool header above.
HdaeUiObj_588:
	.long	0x0160003f				; +0x00 class id
	.short	586, 0xffff, 589, 587	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 216, 315, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0007, 0x0000	; +0x26 class body
	.long	HdaeUiObj_588_Cap2A			; +0x2A caption pointer
	; caption of HdaeUiObj_588: the record's +0x2A caption pointer names this string
HdaeUiObj_588_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#589] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #586 ATTEN_CPHD_WR,
	; box 40,84-279,199.  Record layout and evidence: pool header above.
HdaeUiObj_589:
	.long	0x01600036				; +0x00 class id
	.short	586, 590, 592, 588	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 84, 279, 199			; +0x0E box x1, y1, x2, y2
	.short	0x00f0, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_589_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0003	; +0x1E class body
	; caption of HdaeUiObj_589: the record's +0x1A caption pointer names this string
HdaeUiObj_589_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#590] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #589,
	; box 42,120-285,157.  Record layout and evidence: pool header above.
HdaeUiObj_590:
	.long	0x016a000a				; +0x00 class id
	.short	589, 0xffff, 591, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	42, 120, 285, 157			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x001d, 0x0007, 0x0000, 0x00f9, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#591] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #589,
	; box 40,160-279,197.  Record layout and evidence: pool header above.
HdaeUiObj_591:
	.long	0x016a000a				; +0x00 class id
	.short	589, 0xffff, 0xffff, 590	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 160, 279, 197			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x001e, 0x0007, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#592] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #586 ATTEN_CPHD_WR,
	; box 40,94-279,117.  Record layout and evidence: pool header above.
HdaeUiObj_592:
	.long	0x016a000a				; +0x00 class id
	.short	586, 0xffff, 593, 589	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 94, 279, 117			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d2, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#593] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #586 ATTEN_CPHD_WR,
	; box 248,220-315,239.  Record layout and evidence: pool header above.
HdaeUiObj_593:
	.long	0x016a000a				; +0x00 class id
	.short	586, 0xffff, 0xffff, 592	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	248, 220, 315, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00cb, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#594] "ERR_HD_NOT_FMT"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_594:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 595, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c1e				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_594_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_594: the record's +0x22 caption pointer names this string
HdaeUiObj_594_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#595] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #594 ERR_HD_NOT_FMT,
	; box 36,84-283,203.  Record layout and evidence: pool header above.
HdaeUiObj_595:
	.long	0x01600036				; +0x00 class id
	.short	594, 596, 597, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	36, 84, 283, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f9, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_595_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0003	; +0x1E class body
	; caption of HdaeUiObj_595: the record's +0x1A caption pointer names this string
HdaeUiObj_595_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#596] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #595,
	; box 38,124-281,163.  Record layout and evidence: pool header above.
HdaeUiObj_596:
	.long	0x016a000a				; +0x00 class id
	.short	595, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	38, 124, 281, 163			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x001f, 0x0007, 0x0000, 0x00fb, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#597] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #594 ERR_HD_NOT_FMT,
	; box 39,94-282,117.  Record layout and evidence: pool header above.
HdaeUiObj_597:
	.long	0x016a000a				; +0x00 class id
	.short	594, 0xffff, 598, 595	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	39, 94, 282, 117			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d1, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#598] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #594 ERR_HD_NOT_FMT,
	; box 40,164-279,203.  Record layout and evidence: pool header above.
HdaeUiObj_598:
	.long	0x016a000a				; +0x00 class id
	.short	594, 0xffff, 0xffff, 597	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 164, 279, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d4, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#599] "ERR_HD_SRAM"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_599:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 600, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c22				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_599_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_599: the record's +0x22 caption pointer names this string
HdaeUiObj_599_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#600] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #599 ERR_HD_SRAM,
	; box 36,84-283,203.  Record layout and evidence: pool header above.
HdaeUiObj_600:
	.long	0x01600036				; +0x00 class id
	.short	599, 0xffff, 601, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	36, 84, 283, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f9, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_600_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0003	; +0x1E class body
	; caption of HdaeUiObj_600: the record's +0x1A caption pointer names this string
HdaeUiObj_600_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#601] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #599 ERR_HD_SRAM,
	; box 40,122-279,161.  Record layout and evidence: pool header above.
HdaeUiObj_601:
	.long	0x016a000a				; +0x00 class id
	.short	599, 0xffff, 602, 600	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 122, 279, 161			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0020, 0x0000, 0x0000, 0x00fb, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#602] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #599 ERR_HD_SRAM,
	; box 39,94-282,117.  Record layout and evidence: pool header above.
HdaeUiObj_602:
	.long	0x016a000a				; +0x00 class id
	.short	599, 0xffff, 603, 601	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	39, 94, 282, 117			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d1, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#603] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #599 ERR_HD_SRAM,
	; box 40,164-279,203.  Record layout and evidence: pool header above.
HdaeUiObj_603:
	.long	0x016a000a				; +0x00 class id
	.short	599, 0xffff, 0xffff, 602	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 164, 279, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d4, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#604] "ERR_HD_RESET"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_604:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 605, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c26				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_604_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_604: the record's +0x22 caption pointer names this string
HdaeUiObj_604_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#605] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #604 ERR_HD_RESET,
	; box 36,84-283,203.  Record layout and evidence: pool header above.
HdaeUiObj_605:
	.long	0x01600036				; +0x00 class id
	.short	604, 0xffff, 606, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	36, 84, 283, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f9, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_605_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0003	; +0x1E class body
	; caption of HdaeUiObj_605: the record's +0x1A caption pointer names this string
HdaeUiObj_605_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#606] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #604 ERR_HD_RESET,
	; box 40,122-279,161.  Record layout and evidence: pool header above.
HdaeUiObj_606:
	.long	0x016a000a				; +0x00 class id
	.short	604, 0xffff, 607, 605	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 122, 279, 161			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0021, 0x0000, 0x0000, 0x00fb, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#607] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #604 ERR_HD_RESET,
	; box 39,94-282,117.  Record layout and evidence: pool header above.
HdaeUiObj_607:
	.long	0x016a000a				; +0x00 class id
	.short	604, 0xffff, 608, 606	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	39, 94, 282, 117			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d1, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#608] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #604 ERR_HD_RESET,
	; box 40,164-279,203.  Record layout and evidence: pool header above.
HdaeUiObj_608:
	.long	0x016a000a				; +0x00 class id
	.short	604, 0xffff, 0xffff, 607	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 164, 279, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d4, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#609] "ERR_HD_READ"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_609:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 610, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c2a				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_609_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_609: the record's +0x22 caption pointer names this string
HdaeUiObj_609_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#610] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #609 ERR_HD_READ,
	; box 36,84-283,203.  Record layout and evidence: pool header above.
HdaeUiObj_610:
	.long	0x01600036				; +0x00 class id
	.short	609, 611, 612, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	36, 84, 283, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f9, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_610_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0003	; +0x1E class body
	; caption of HdaeUiObj_610: the record's +0x1A caption pointer names this string
HdaeUiObj_610_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#611] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #610,
	; box 34,124-277,161.  Record layout and evidence: pool header above.
HdaeUiObj_611:
	.long	0x016a000a				; +0x00 class id
	.short	610, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	34, 124, 277, 161			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0022, 0x0007, 0x0000, 0x00fb, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#612] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #609 ERR_HD_READ,
	; box 39,94-282,117.  Record layout and evidence: pool header above.
HdaeUiObj_612:
	.long	0x016a000a				; +0x00 class id
	.short	609, 0xffff, 613, 610	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	39, 94, 282, 117			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d1, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#613] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #609 ERR_HD_READ,
	; box 40,164-279,203.  Record layout and evidence: pool header above.
HdaeUiObj_613:
	.long	0x016a000a				; +0x00 class id
	.short	609, 0xffff, 0xffff, 612	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 164, 279, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d4, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#614] "ERR_HD_ID_READ"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_614:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 615, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c2e				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_614_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_614: the record's +0x22 caption pointer names this string
HdaeUiObj_614_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#615] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #614 ERR_HD_ID_READ,
	; box 36,84-283,203.  Record layout and evidence: pool header above.
HdaeUiObj_615:
	.long	0x01600036				; +0x00 class id
	.short	614, 616, 617, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	36, 84, 283, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f9, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_615_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0003	; +0x1E class body
	; caption of HdaeUiObj_615: the record's +0x1A caption pointer names this string
HdaeUiObj_615_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#616] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #615,
	; box 38,124-281,161.  Record layout and evidence: pool header above.
HdaeUiObj_616:
	.long	0x016a000a				; +0x00 class id
	.short	615, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	38, 124, 281, 161			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0023, 0x0007, 0x0000, 0x00fb, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#617] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #614 ERR_HD_ID_READ,
	; box 39,94-282,117.  Record layout and evidence: pool header above.
HdaeUiObj_617:
	.long	0x016a000a				; +0x00 class id
	.short	614, 0xffff, 618, 615	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	39, 94, 282, 117			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d1, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#618] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #614 ERR_HD_ID_READ,
	; box 40,164-279,203.  Record layout and evidence: pool header above.
HdaeUiObj_618:
	.long	0x016a000a				; +0x00 class id
	.short	614, 0xffff, 0xffff, 617	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 164, 279, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d4, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#619] "ERR_HD_TRACK_0"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_619:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 620, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c32				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_619_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_619: the record's +0x22 caption pointer names this string
HdaeUiObj_619_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#620] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #619 ERR_HD_TRACK_0,
	; box 36,84-283,203.  Record layout and evidence: pool header above.
HdaeUiObj_620:
	.long	0x01600036				; +0x00 class id
	.short	619, 621, 622, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	36, 84, 283, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f9, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_620_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0003	; +0x1E class body
	; caption of HdaeUiObj_620: the record's +0x1A caption pointer names this string
HdaeUiObj_620_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#621] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #620,
	; box 38,120-281,157.  Record layout and evidence: pool header above.
HdaeUiObj_621:
	.long	0x016a000a				; +0x00 class id
	.short	620, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	38, 120, 281, 157			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0024, 0x0007, 0x0000, 0x00fb, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#622] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #619 ERR_HD_TRACK_0,
	; box 39,94-282,117.  Record layout and evidence: pool header above.
HdaeUiObj_622:
	.long	0x016a000a				; +0x00 class id
	.short	619, 0xffff, 623, 620	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	39, 94, 282, 117			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d1, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#623] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #619 ERR_HD_TRACK_0,
	; box 40,164-279,203.  Record layout and evidence: pool header above.
HdaeUiObj_623:
	.long	0x016a000a				; +0x00 class id
	.short	619, 0xffff, 0xffff, 622	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 164, 279, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d4, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#624] "ERR_HD_FAT"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_624:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 625, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c36				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_624_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_624: the record's +0x22 caption pointer names this string
HdaeUiObj_624_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#625] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #624 ERR_HD_FAT,
	; box 36,84-283,203.  Record layout and evidence: pool header above.
HdaeUiObj_625:
	.long	0x01600036				; +0x00 class id
	.short	624, 626, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	36, 84, 283, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f9, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_625_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0003	; +0x1E class body
	; caption of HdaeUiObj_625: the record's +0x1A caption pointer names this string
HdaeUiObj_625_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#626] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #625,
	; box 39,94-282,117.  Record layout and evidence: pool header above.
HdaeUiObj_626:
	.long	0x016a000a				; +0x00 class id
	.short	625, 0xffff, 627, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	39, 94, 282, 117			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d1, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#627] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #625,
	; box 40,164-279,203.  Record layout and evidence: pool header above.
HdaeUiObj_627:
	.long	0x016a000a				; +0x00 class id
	.short	625, 0xffff, 628, 626	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 164, 279, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d4, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#628] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #625,
	; box 38,120-281,157.  Record layout and evidence: pool header above.
HdaeUiObj_628:
	.long	0x016a000a				; +0x00 class id
	.short	625, 0xffff, 0xffff, 627	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	38, 120, 281, 157			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0025, 0x0007, 0x0000, 0x00fb, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#629] "ERR_HD_FSB"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_629:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 630, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c3a				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_629_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_629: the record's +0x22 caption pointer names this string
HdaeUiObj_629_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#630] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #629 ERR_HD_FSB,
	; box 36,84-283,203.  Record layout and evidence: pool header above.
HdaeUiObj_630:
	.long	0x01600036				; +0x00 class id
	.short	629, 631, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	36, 84, 283, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f9, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_630_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0003	; +0x1E class body
	; caption of HdaeUiObj_630: the record's +0x1A caption pointer names this string
HdaeUiObj_630_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#631] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #630,
	; box 40,164-279,203.  Record layout and evidence: pool header above.
HdaeUiObj_631:
	.long	0x016a000a				; +0x00 class id
	.short	630, 0xffff, 632, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 164, 279, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d4, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#632] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #630,
	; box 39,94-282,117.  Record layout and evidence: pool header above.
HdaeUiObj_632:
	.long	0x016a000a				; +0x00 class id
	.short	630, 0xffff, 633, 631	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	39, 94, 282, 117			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d1, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#633] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #630,
	; box 38,120-281,157.  Record layout and evidence: pool header above.
HdaeUiObj_633:
	.long	0x016a000a				; +0x00 class id
	.short	630, 0xffff, 0xffff, 632	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	38, 120, 281, 157			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0026, 0x0007, 0x0000, 0x00fb, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#634] "ATTEN_CPFD_MARK"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_634:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 635, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c3e				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_634_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_634: the record's +0x22 caption pointer names this string
HdaeUiObj_634_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#635] (unnamed)  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #634 ATTEN_CPFD_MARK,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_635:
	.long	0x01600052				; +0x00 class id
	.short	634, 0xffff, 636, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0038, 0x012a	; +0x16 class body

	; [#636] (unnamed)  class 0160:003F = KN5000 widget type 0x3F, 48 bytes, parent #634 ATTEN_CPFD_MARK,
	; box 244,216-315,238.  Record layout and evidence: pool header above.
HdaeUiObj_636:
	.long	0x0160003f				; +0x00 class id
	.short	634, 637, 638, 635	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	244, 216, 315, 238			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0006	; +0x16 class body
	.short	0x0007, 0x0000	; +0x26 class body
	.long	HdaeUiObj_636_Cap2A			; +0x2A caption pointer
	; caption of HdaeUiObj_636: the record's +0x2A caption pointer names this string
HdaeUiObj_636_Cap2A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#637] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #636,
	; box 248,220-315,239.  Record layout and evidence: pool header above.
HdaeUiObj_637:
	.long	0x016a000a				; +0x00 class id
	.short	636, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	248, 220, 315, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00cb, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#638] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #634 ATTEN_CPFD_MARK,
	; box 40,84-279,168.  Record layout and evidence: pool header above.
HdaeUiObj_638:
	.long	0x01600036				; +0x00 class id
	.short	634, 639, 0xffff, 636	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 84, 279, 168			; +0x0E box x1, y1, x2, y2
	.short	0x00f0, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_638_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0002	; +0x1E class body
	; caption of HdaeUiObj_638: the record's +0x1A caption pointer names this string
HdaeUiObj_638_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#639] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #638,
	; box 40,94-279,117.  Record layout and evidence: pool header above.
HdaeUiObj_639:
	.long	0x016a000a				; +0x00 class id
	.short	638, 0xffff, 640, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 94, 279, 117			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d2, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#640] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #638,
	; box 40,122-279,159.  Record layout and evidence: pool header above.
HdaeUiObj_640:
	.long	0x016a000a				; +0x00 class id
	.short	638, 0xffff, 0xffff, 639	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 122, 279, 159			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0027, 0x0007, 0x0000, 0x00f9, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#641] "ABOUT_HELP"  class 016A:0002 = ClassName_Table[2] "TtlScreenRProc", 56 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_641:
	.long	0x016a0002				; +0x00 class id
	.short	0xffff, 642, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c42				; +0x1E RAM address (every 016A:0002 record)
	.long	HdaeUiObj_641_Cap22			; +0x22 caption pointer
	.short	0x0001, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_641: the record's +0x22 caption pointer names this string
HdaeUiObj_641_Cap22:	.asciz	"            "
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#642] (unnamed)  class 0160:0069 = KN5000 widget type 0x69, 26 bytes, parent #641 ABOUT_HELP,
	; box 76,1-102,27.  Record layout and evidence: pool header above.
HdaeUiObj_642:
	.long	0x01600069				; +0x00 class id
	.short	641, 0xffff, 643, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	76, 1, 102, 27			; +0x0E box x1, y1, x2, y2
	.short	0x0027, 0x012a	; +0x16 class body

	; [#643] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #641 ABOUT_HELP,
	; box 25,68-294,119.  Record layout and evidence: pool header above.
HdaeUiObj_643:
	.long	0x01600036				; +0x00 class id
	.short	641, 644, 648, 642	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	25, 68, 294, 119			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_643_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0001, 0x0003	; +0x1E class body
	; caption of HdaeUiObj_643: the record's +0x1A caption pointer names this string
HdaeUiObj_643_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#644] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 34 bytes, parent #643,
	; box 29,69-32,79.  Record layout and evidence: pool header above.
HdaeUiObj_644:
	.long	0x0160002b				; +0x00 class id
	.short	643, 0xffff, 645, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	29, 69, 32, 79			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_644_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_644: the record's +0x16 caption pointer names this string
HdaeUiObj_644_Cap16:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#645] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 58 bytes, parent #643,
	; box 29,84-232,102.  Record layout and evidence: pool header above.
HdaeUiObj_645:
	.long	0x0160002b				; +0x00 class id
	.short	643, 0xffff, 646, 644	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	29, 84, 232, 102			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_645_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_645: the record's +0x16 caption pointer names this string
HdaeUiObj_645_Cap16:	.asciz	"Technosoft, CH-Samstagern"
	.set	HDAE5000_Credits, HdaeUiObj_645_Cap16	; 0x2A477C
	; MISNOMER retained for cross-reference: this is not a credits block,
	; it is one caption.  0x2A477C is byte +0x20 of object #645 (record
	; 0x2A475C-0x2A4795, 58 bytes, class 0160:002B, under ABOUT_HELP via
	; object #643) - that ONE object's inline caption, named by the .long at
	; +0x16 of the record; the nearest record boundary is 0x20 bytes ABOVE
	; this label.  The credit text is SIX separate objects under ABOUT_HELP,
	; in three sibling groups: #645 "Technosoft, CH-Samstagern" and #646
	; "Pointstyle, CH-Buttisholz" under #643; #649 "KEY SOFT SERVICE,
	; CH-Schenkon", #650 "Fax.  +41-41-922 03 15" and #651
	; "email:keysoftservice@bluewin.ch" under #648; and #656 "Mr.
	; T.Hamaguchi and Mr. M.Kitajima" under #655.

	; [#646] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 58 bytes, parent #643,
	; box 29,100-232,118.  Record layout and evidence: pool header above.
HdaeUiObj_646:
	.long	0x0160002b				; +0x00 class id
	.short	643, 0xffff, 647, 645	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	29, 100, 232, 118			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_646_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_646: the record's +0x16 caption pointer names this string
HdaeUiObj_646_Cap16:	.asciz	"Pointstyle, CH-Buttisholz"

	; [#647] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #643,
	; box 27,69-286,84.  Record layout and evidence: pool header above.
HdaeUiObj_647:
	.long	0x016a000a				; +0x00 class id
	.short	643, 0xffff, 0xffff, 646	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	27, 69, 286, 84			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0011, 0x0003, 0x0000, 0x0000, 0x0001, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#648] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #641 ABOUT_HELP,
	; box 25,120-294,179.  Record layout and evidence: pool header above.
HdaeUiObj_648:
	.long	0x01600036				; +0x00 class id
	.short	641, 649, 653, 643	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	25, 120, 294, 179			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_648_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0001, 0x0003	; +0x1E class body
	; caption of HdaeUiObj_648: the record's +0x1A caption pointer names this string
HdaeUiObj_648_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#649] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 62 bytes, parent #648,
	; box 29,137-264,155.  Record layout and evidence: pool header above.
HdaeUiObj_649:
	.long	0x0160002b				; +0x00 class id
	.short	648, 0xffff, 650, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	29, 137, 264, 155			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_649_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_649: the record's +0x16 caption pointer names this string
HdaeUiObj_649_Cap16:	.asciz	"KEY SOFT SERVICE, CH-Schenkon"

	; [#650] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 56 bytes, parent #648,
	; box 29,154-164,164.  Record layout and evidence: pool header above.
HdaeUiObj_650:
	.long	0x0160002b				; +0x00 class id
	.short	648, 0xffff, 651, 649	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	29, 154, 164, 164			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_650_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_650: the record's +0x16 caption pointer names this string
HdaeUiObj_650_Cap16:	.asciz	"Fax.  +41-41-922 03 15"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#651] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 64 bytes, parent #648,
	; box 29,165-218,175.  Record layout and evidence: pool header above.
HdaeUiObj_651:
	.long	0x0160002b				; +0x00 class id
	.short	648, 0xffff, 652, 650	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	29, 165, 218, 175			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_651_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_651: the record's +0x16 caption pointer names this string
HdaeUiObj_651_Cap16:	.asciz	"email:keysoftservice@bluewin.ch"

	; [#652] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #648,
	; box 27,122-286,137.  Record layout and evidence: pool header above.
HdaeUiObj_652:
	.long	0x016a000a				; +0x00 class id
	.short	648, 0xffff, 0xffff, 651	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	27, 122, 286, 137			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0012, 0x0003, 0x0000, 0x0000, 0x0001, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#653] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #641 ABOUT_HELP,
	; box 25,180-294,199.  Record layout and evidence: pool header above.
HdaeUiObj_653:
	.long	0x01600036				; +0x00 class id
	.short	641, 654, 655, 648	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	25, 180, 294, 199			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_653_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0001, 0x0003	; +0x1E class body
	; caption of HdaeUiObj_653: the record's +0x1A caption pointer names this string
HdaeUiObj_653_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#654] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #653,
	; box 27,182-294,197.  Record layout and evidence: pool header above.
HdaeUiObj_654:
	.long	0x016a000a				; +0x00 class id
	.short	653, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	27, 182, 294, 197			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0013, 0x0003, 0x0000, 0x0000, 0x0001, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#655] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #641 ABOUT_HELP,
	; box 25,205-294,237.  Record layout and evidence: pool header above.
HdaeUiObj_655:
	.long	0x01600036				; +0x00 class id
	.short	641, 656, 658, 653	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	25, 205, 294, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_655_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0001, 0x0003	; +0x1E class body
	; caption of HdaeUiObj_655: the record's +0x1A caption pointer names this string
HdaeUiObj_655_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#656] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 68 bytes, parent #655,
	; box 29,218-289,236.  Record layout and evidence: pool header above.
HdaeUiObj_656:
	.long	0x0160002b				; +0x00 class id
	.short	655, 0xffff, 657, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	29, 218, 289, 236			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_656_Cap16			; +0x16 caption pointer
	.short	0x0005, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_656: the record's +0x16 caption pointer names this string
HdaeUiObj_656_Cap16:	.asciz	"Mr. T.Hamaguchi and Mr. M.Kitajima"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#657] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #655,
	; box 27,206-226,221.  Record layout and evidence: pool header above.
HdaeUiObj_657:
	.long	0x016a000a				; +0x00 class id
	.short	655, 0xffff, 0xffff, 656	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	27, 206, 226, 221			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0014, 0x0003, 0x0000, 0x0000, 0x0001, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#658] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #641 ABOUT_HELP,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_658:
	.long	0x01600049				; +0x00 class id
	.short	641, 0xffff, 659, 655	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0013, 0x007f	; +0x16 class body

	; [#659] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #641 ABOUT_HELP,
	; box 101,0-280,31.  Record layout and evidence: pool header above.
HdaeUiObj_659:
	.long	0x016a000a				; +0x00 class id
	.short	641, 0xffff, 0xffff, 658	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	101, 0, 280, 31			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x000a, 0x0009, 0x0000, 0x00ff, 0x0001, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#660] "WAIT_TR0_RECOVER"  class 0160:0035 = KN5000 widget type 0x35, 36 bytes, parent none (root),
	; box 26,30-293,89.  Record layout and evidence: pool header above.
HdaeUiObj_660:
	.long	0x01600035				; +0x00 class id
	.short	0xffff, 661, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	26, 30, 293, 89			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0000	; +0x16 class body
	.long	0x00239c46				; +0x1C RAM address (every 0160:0035 record)
	.long	0x00239c4a				; +0x20 RAM address (every 0160:0035 record)

	; [#661] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #660 WAIT_TR0_RECOVER,
	; box 40,34-279,57.  Record layout and evidence: pool header above.
HdaeUiObj_661:
	.long	0x016a000a				; +0x00 class id
	.short	660, 0xffff, 662, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 34, 279, 57			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x003b, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#662] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #660 WAIT_TR0_RECOVER,
	; box 32,58-291,81.  Record layout and evidence: pool header above.
HdaeUiObj_662:
	.long	0x016a000a				; +0x00 class id
	.short	660, 0xffff, 0xffff, 661	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	32, 58, 291, 81			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0031, 0x0002, 0x0000, 0x00f9, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#663] "ERR_SAVE"  class 016A:0009 = ClassName_Table[9] "IvScreenR2Proc", 34 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_663:
	.long	0x016a0009				; +0x00 class id
	.short	0xffff, 664, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c4e				; +0x1E RAM address (every 016A:0009 record)

	; [#665] "ERR_SAVE_CATCH"  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #663 ERR_SAVE,
	; box 0,32-31,63.  Record layout and evidence: pool header above.
HdaeUiObj_665:
	.long	0x01600052				; +0x00 class id
	.short	663, 0xffff, 666, 664	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 32, 31, 63			; +0x0E box x1, y1, x2, y2
	.short	0x003e, 0x012a	; +0x16 class body

	; [#666] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #663 ERR_SAVE,
	; box 40,84-279,193.  Record layout and evidence: pool header above.
HdaeUiObj_666:
	.long	0x01600036				; +0x00 class id
	.short	663, 667, 668, 665	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 84, 279, 193			; +0x0E box x1, y1, x2, y2
	.short	0x00f9, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_666_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0003	; +0x1E class body
	; caption of HdaeUiObj_666: the record's +0x1A caption pointer names this string
HdaeUiObj_666_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#667] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #666,
	; box 40,120-279,191.  Record layout and evidence: pool header above.
HdaeUiObj_667:
	.long	0x016a000a				; +0x00 class id
	.short	666, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 120, 279, 191			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0029, 0x0007, 0x0000, 0x00fb, 0x0000, 0x0004	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#668] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #663 ERR_SAVE,
	; box 40,94-279,117.  Record layout and evidence: pool header above.
HdaeUiObj_668:
	.long	0x016a000a				; +0x00 class id
	.short	663, 0xffff, 0xffff, 666	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 94, 279, 117			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d2, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#669] "ERR_LOAD"  class 016A:0009 = ClassName_Table[9] "IvScreenR2Proc", 34 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_669:
	.long	0x016a0009				; +0x00 class id
	.short	0xffff, 670, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c52				; +0x1E RAM address (every 016A:0009 record)

	; [#671] "ERR_LOAD_CATCH"  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #669 ERR_LOAD,
	; box 0,36-31,67.  Record layout and evidence: pool header above.
HdaeUiObj_671:
	.long	0x01600052				; +0x00 class id
	.short	669, 0xffff, 672, 670	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 36, 31, 67			; +0x0E box x1, y1, x2, y2
	.short	0x003e, 0x012a	; +0x16 class body

	; [#672] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #669 ERR_LOAD,
	; box 40,84-279,193.  Record layout and evidence: pool header above.
HdaeUiObj_672:
	.long	0x01600036				; +0x00 class id
	.short	669, 673, 674, 671	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 84, 279, 193			; +0x0E box x1, y1, x2, y2
	.short	0x00f9, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_672_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0003	; +0x1E class body
	; caption of HdaeUiObj_672: the record's +0x1A caption pointer names this string
HdaeUiObj_672_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#673] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #672,
	; box 40,94-279,117.  Record layout and evidence: pool header above.
HdaeUiObj_673:
	.long	0x016a000a				; +0x00 class id
	.short	672, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 94, 279, 117			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d2, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#674] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #669 ERR_LOAD,
	; box 40,120-279,191.  Record layout and evidence: pool header above.
HdaeUiObj_674:
	.long	0x016a000a				; +0x00 class id
	.short	669, 0xffff, 0xffff, 672	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 120, 279, 191			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0029, 0x0007, 0x0000, 0x00fb, 0x0000, 0x0004	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#675] "ERR_NO_HK_DATA"  class 016A:0009 = ClassName_Table[9] "IvScreenR2Proc", 34 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_675:
	.long	0x016a0009				; +0x00 class id
	.short	0xffff, 676, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c56				; +0x1E RAM address (every 016A:0009 record)

	; [#676] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #675 ERR_NO_HK_DATA,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_676:
	.long	0x01600049				; +0x00 class id
	.short	675, 0xffff, 677, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x00d2, 0x007f	; +0x16 class body

	; [#677] "ERR_NO_HK_DATA_CATCH"  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #675 ERR_NO_HK_DATA,
	; box 0,32-31,63.  Record layout and evidence: pool header above.
HdaeUiObj_677:
	.long	0x01600052				; +0x00 class id
	.short	675, 0xffff, 678, 676	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 32, 31, 63			; +0x0E box x1, y1, x2, y2
	.short	0x003e, 0x012a	; +0x16 class body

	; [#678] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #675 ERR_NO_HK_DATA,
	; box 40,84-279,203.  Record layout and evidence: pool header above.
HdaeUiObj_678:
	.long	0x01600036				; +0x00 class id
	.short	675, 679, 0xffff, 677	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 84, 279, 203			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_678_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0000, 0x0005	; +0x1E class body
	; caption of HdaeUiObj_678: the record's +0x1A caption pointer names this string
HdaeUiObj_678_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#679] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #678,
	; box 40,94-279,117.  Record layout and evidence: pool header above.
HdaeUiObj_679:
	.long	0x016a000a				; +0x00 class id
	.short	678, 0xffff, 680, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 94, 279, 117			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d2, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#680] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #678,
	; box 40,124-279,195.  Record layout and evidence: pool header above.
HdaeUiObj_680:
	.long	0x016a000a				; +0x00 class id
	.short	678, 0xffff, 0xffff, 679	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 124, 279, 195			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x002a, 0x0007, 0x0000, 0x00f9, 0x0000, 0x0004	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#681] "ATTEN_FULL_DIR"  class 016A:0009 = ClassName_Table[9] "IvScreenR2Proc", 34 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_681:
	.long	0x016a0009				; +0x00 class id
	.short	0xffff, 682, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c5a				; +0x1E RAM address (every 016A:0009 record)

	; [#682] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #681 ATTEN_FULL_DIR,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_682:
	.long	0x01600049				; +0x00 class id
	.short	681, 0xffff, 683, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x00e2, 0x007f	; +0x16 class body

	; [#683] "ATTEN_FULL_DIR_CATCH"  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #681 ATTEN_FULL_DIR,
	; box 0,32-31,63.  Record layout and evidence: pool header above.
HdaeUiObj_683:
	.long	0x01600052				; +0x00 class id
	.short	681, 0xffff, 684, 682	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 32, 31, 63			; +0x0E box x1, y1, x2, y2
	.short	0x003e, 0x012a	; +0x16 class body

	; [#684] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #681 ATTEN_FULL_DIR,
	; box 40,50-279,209.  Record layout and evidence: pool header above.
HdaeUiObj_684:
	.long	0x01600036				; +0x00 class id
	.short	681, 685, 0xffff, 683	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 50, 279, 209			; +0x0E box x1, y1, x2, y2
	.short	0x00f0, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_684_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0004	; +0x1E class body
	; caption of HdaeUiObj_684: the record's +0x1A caption pointer names this string
HdaeUiObj_684_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#685] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #684,
	; box 40,56-279,79.  Record layout and evidence: pool header above.
HdaeUiObj_685:
	.long	0x016a000a				; +0x00 class id
	.short	684, 0xffff, 686, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 56, 279, 79			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d2, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#686] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #684,
	; box 40,82-279,153.  Record layout and evidence: pool header above.
HdaeUiObj_686:
	.long	0x016a000a				; +0x00 class id
	.short	684, 0xffff, 687, 685	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 82, 279, 153			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x002b, 0x0007, 0x0000, 0x00f9, 0x0000, 0x0004	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#687] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #684,
	; box 40,152-279,203.  Record layout and evidence: pool header above.
HdaeUiObj_687:
	.long	0x016a000a				; +0x00 class id
	.short	684, 0xffff, 0xffff, 686	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 152, 279, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x002c, 0x0007, 0x0000, 0x00fb, 0x0000, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#688] "ATTEN_CP_UNNAMED"  class 016A:0009 = ClassName_Table[9] "IvScreenR2Proc", 34 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_688:
	.long	0x016a0009				; +0x00 class id
	.short	0xffff, 689, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c5e				; +0x1E RAM address (every 016A:0009 record)

	; [#689] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #688 ATTEN_CP_UNNAMED,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_689:
	.long	0x01600049				; +0x00 class id
	.short	688, 0xffff, 690, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x00e2, 0x007f	; +0x16 class body

	; [#690] "ATTEN_CP_UNNAMED_CATCH"  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #688 ATTEN_CP_UNNAMED,
	; box 0,32-31,63.  Record layout and evidence: pool header above.
HdaeUiObj_690:
	.long	0x01600052				; +0x00 class id
	.short	688, 0xffff, 691, 689	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 32, 31, 63			; +0x0E box x1, y1, x2, y2
	.short	0x003e, 0x012a	; +0x16 class body

	; [#691] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #688 ATTEN_CP_UNNAMED,
	; box 40,50-279,209.  Record layout and evidence: pool header above.
HdaeUiObj_691:
	.long	0x01600036				; +0x00 class id
	.short	688, 692, 0xffff, 690	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 50, 279, 209			; +0x0E box x1, y1, x2, y2
	.short	0x00f0, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_691_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0004	; +0x1E class body
	; caption of HdaeUiObj_691: the record's +0x1A caption pointer names this string
HdaeUiObj_691_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#692] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #691,
	; box 40,140-279,207.  Record layout and evidence: pool header above.
HdaeUiObj_692:
	.long	0x016a000a				; +0x00 class id
	.short	691, 0xffff, 693, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 140, 279, 207			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x002e, 0x0000, 0x0000, 0x0000, 0x0000, 0x0004	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#693] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #691,
	; box 40,56-279,79.  Record layout and evidence: pool header above.
HdaeUiObj_693:
	.long	0x016a000a				; +0x00 class id
	.short	691, 0xffff, 694, 692	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 56, 279, 79			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d2, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#694] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #691,
	; box 40,84-279,135.  Record layout and evidence: pool header above.
HdaeUiObj_694:
	.long	0x016a000a				; +0x00 class id
	.short	691, 0xffff, 0xffff, 693	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 84, 279, 135			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x002d, 0x0007, 0x0000, 0x00f9, 0x0000, 0x0003	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#695] "DIR_OUT_RANGE"  class 016A:0009 = ClassName_Table[9] "IvScreenR2Proc", 34 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_695:
	.long	0x016a0009				; +0x00 class id
	.short	0xffff, 696, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c62				; +0x1E RAM address (every 016A:0009 record)

	; [#696] "DIR_OUT_RANGE_CATCH"  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #695 DIR_OUT_RANGE,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_696:
	.long	0x01600052				; +0x00 class id
	.short	695, 0xffff, 697, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x003f, 0x012a	; +0x16 class body

	; [#697] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #695 DIR_OUT_RANGE,
	; box 40,84-279,163.  Record layout and evidence: pool header above.
HdaeUiObj_697:
	.long	0x01600036				; +0x00 class id
	.short	695, 698, 699, 696	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 84, 279, 163			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_697_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0002	; +0x1E class body
	; caption of HdaeUiObj_697: the record's +0x1A caption pointer names this string
HdaeUiObj_697_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#698] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #697,
	; box 40,120-279,159.  Record layout and evidence: pool header above.
HdaeUiObj_698:
	.long	0x016a000a				; +0x00 class id
	.short	697, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 120, 279, 159			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x002f, 0x0007, 0x0000, 0x00f9, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#699] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #695 DIR_OUT_RANGE,
	; box 40,92-279,115.  Record layout and evidence: pool header above.
HdaeUiObj_699:
	.long	0x016a000a				; +0x00 class id
	.short	695, 0xffff, 0xffff, 697	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 92, 279, 115			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d2, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#700] "FILE_OUT_RANGE"  class 016A:0009 = ClassName_Table[9] "IvScreenR2Proc", 34 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_700:
	.long	0x016a0009				; +0x00 class id
	.short	0xffff, 701, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c66				; +0x1E RAM address (every 016A:0009 record)

	; [#701] "FILE_OUT_RANGE_CATCH"  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #700 FILE_OUT_RANGE,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_701:
	.long	0x01600052				; +0x00 class id
	.short	700, 0xffff, 702, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x003f, 0x012a	; +0x16 class body

	; [#702] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #700 FILE_OUT_RANGE,
	; box 40,84-279,163.  Record layout and evidence: pool header above.
HdaeUiObj_702:
	.long	0x01600036				; +0x00 class id
	.short	700, 703, 704, 701	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 84, 279, 163			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_702_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0002	; +0x1E class body
	; caption of HdaeUiObj_702: the record's +0x1A caption pointer names this string
HdaeUiObj_702_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#703] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #702,
	; box 40,92-279,115.  Record layout and evidence: pool header above.
HdaeUiObj_703:
	.long	0x016a000a				; +0x00 class id
	.short	702, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 92, 279, 115			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x00d2, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#704] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #700 FILE_OUT_RANGE,
	; box 44,120-273,159.  Record layout and evidence: pool header above.
HdaeUiObj_704:
	.long	0x016a000a				; +0x00 class id
	.short	700, 0xffff, 0xffff, 702	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 120, 273, 159			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0030, 0x0007, 0x0000, 0x00f9, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#705] "HD_PLEASE"  class 016A:0009 = ClassName_Table[9] "IvScreenR2Proc", 34 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_705:
	.long	0x016a0009				; +0x00 class id
	.short	0xffff, 706, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c6a				; +0x1E RAM address (every 016A:0009 record)

	; [#706] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #705 HD_PLEASE,
	; box 60,84-259,131.  Record layout and evidence: pool header above.
HdaeUiObj_706:
	.long	0x01600036				; +0x00 class id
	.short	705, 707, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	60, 84, 259, 131			; +0x0E box x1, y1, x2, y2
	.short	0x0009, 0x00c1	; +0x16 class body
	.long	HdaeUiObj_706_Cap1A			; +0x1A caption pointer
	.short	0x0001, 0x0000, 0x0000, 0x0000, 0x0001	; +0x1E class body
	; caption of HdaeUiObj_706: the record's +0x1A caption pointer names this string
HdaeUiObj_706_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#707] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #706,
	; box 72,98-241,121.  Record layout and evidence: pool header above.
HdaeUiObj_707:
	.long	0x016a000a				; +0x00 class id
	.short	706, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	72, 98, 241, 121			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0031, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#708] "ERR_HD_FORMAT"  class 016A:0009 = ClassName_Table[9] "IvScreenR2Proc", 34 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_708:
	.long	0x016a0009				; +0x00 class id
	.short	0xffff, 709, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c6e				; +0x1E RAM address (every 016A:0009 record)

	; [#709] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #708 ERR_HD_FORMAT,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_709:
	.long	0x01600049				; +0x00 class id
	.short	708, 0xffff, 710, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x021a, 0x007f	; +0x16 class body

	; [#710] "ERR_HD_FORMAT_CATCH"  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #708 ERR_HD_FORMAT,
	; box 0,32-31,63.  Record layout and evidence: pool header above.
HdaeUiObj_710:
	.long	0x01600052				; +0x00 class id
	.short	708, 0xffff, 711, 709	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 32, 31, 63			; +0x0E box x1, y1, x2, y2
	.short	0x003e, 0x012a	; +0x16 class body

	; [#711] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #708 ERR_HD_FORMAT,
	; box 32,78-287,227.  Record layout and evidence: pool header above.
HdaeUiObj_711:
	.long	0x01600036				; +0x00 class id
	.short	708, 712, 0xffff, 710	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	32, 78, 287, 227			; +0x0E box x1, y1, x2, y2
	.short	0x00f9, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_711_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0005	; +0x1E class body
	; caption of HdaeUiObj_711: the record's +0x1A caption pointer names this string
HdaeUiObj_711_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#712] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #711,
	; box 40,116-279,151.  Record layout and evidence: pool header above.
HdaeUiObj_712:
	.long	0x016a000a				; +0x00 class id
	.short	711, 0xffff, 713, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 116, 279, 151			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0033, 0x0000, 0x0000, 0x00fb, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#713] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #711,
	; box 30,80-289,115.  Record layout and evidence: pool header above.
HdaeUiObj_713:
	.long	0x016a000a				; +0x00 class id
	.short	711, 0xffff, 714, 712	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	30, 80, 289, 115			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0032, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#714] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #711,
	; box 40,156-279,227.  Record layout and evidence: pool header above.
HdaeUiObj_714:
	.long	0x016a000a				; +0x00 class id
	.short	711, 0xffff, 0xffff, 713	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 156, 279, 227			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0034, 0x0007, 0x0000, 0x0000, 0x0000, 0x0004	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#715] "AGAIN_HD_FORMAT"  class 016A:0009 = ClassName_Table[9] "IvScreenR2Proc", 34 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_715:
	.long	0x016a0009				; +0x00 class id
	.short	0xffff, 716, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c72				; +0x1E RAM address (every 016A:0009 record)

	; [#716] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #715 AGAIN_HD_FORMAT,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_716:
	.long	0x01600049				; +0x00 class id
	.short	715, 0xffff, 717, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x021a, 0x007f	; +0x16 class body

	; [#717] "AGAIN_HD_FORMAT_CATCH"  class 0160:0052 = KN5000 widget type 0x52, 26 bytes, parent #715 AGAIN_HD_FORMAT,
	; box 0,32-31,63.  Record layout and evidence: pool header above.
HdaeUiObj_717:
	.long	0x01600052				; +0x00 class id
	.short	715, 0xffff, 718, 716	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 32, 31, 63			; +0x0E box x1, y1, x2, y2
	.short	0x003e, 0x012a	; +0x16 class body

	; [#718] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #715 AGAIN_HD_FORMAT,
	; box 32,78-287,227.  Record layout and evidence: pool header above.
HdaeUiObj_718:
	.long	0x01600036				; +0x00 class id
	.short	715, 719, 0xffff, 717	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	32, 78, 287, 227			; +0x0E box x1, y1, x2, y2
	.short	0x00f9, 0x00c9	; +0x16 class body
	.long	HdaeUiObj_718_Cap1A			; +0x1A caption pointer
	.short	0x0002, 0x0000, 0x0000, 0x0000, 0x0005	; +0x1E class body
	; caption of HdaeUiObj_718: the record's +0x1A caption pointer names this string
HdaeUiObj_718_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#719] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #718,
	; box 34,80-293,115.  Record layout and evidence: pool header above.
HdaeUiObj_719:
	.long	0x016a000a				; +0x00 class id
	.short	718, 0xffff, 720, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	34, 80, 293, 115			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0035, 0x0002, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#720] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #718,
	; box 40,116-279,151.  Record layout and evidence: pool header above.
HdaeUiObj_720:
	.long	0x016a000a				; +0x00 class id
	.short	718, 0xffff, 721, 719	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 116, 279, 151			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0036, 0x0000, 0x0000, 0x00fb, 0x0000, 0x0002	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#721] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #718,
	; box 40,152-279,223.  Record layout and evidence: pool header above.
HdaeUiObj_721:
	.long	0x016a000a				; +0x00 class id
	.short	718, 0xffff, 0xffff, 720	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 152, 279, 223			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0037, 0x0007, 0x0000, 0x0000, 0x0000, 0x0004	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#722] "SELECT_FILE_A_Z"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_722:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 723, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c76				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_722_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_722: the record's +0x22 caption pointer names this string
HdaeUiObj_722_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#723] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #722 SELECT_FILE_A_Z,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_723:
	.long	0x01600049				; +0x00 class id
	.short	722, 0xffff, 724, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0022, 0x007f	; +0x16 class body

	; [#724] (unnamed)  class 0160:0028 = KN5000 widget type 0x28, 28 bytes, parent #722 SELECT_FILE_A_Z,
	; box 0,32-31,63.  Record layout and evidence: pool header above.
HdaeUiObj_724:
	.long	0x01600028				; +0x00 class id
	.short	722, 0xffff, 725, 723	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 32, 31, 63			; +0x0E box x1, y1, x2, y2
	.short	0x0001, 0x02d8, 0x007f	; +0x16 class body

	; [#725] (unnamed)  class 0160:0028 = KN5000 widget type 0x28, 28 bytes, parent #722 SELECT_FILE_A_Z,
	; box 0,64-31,95.  Record layout and evidence: pool header above.
HdaeUiObj_725:
	.long	0x01600028				; +0x00 class id
	.short	722, 0xffff, 726, 724	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 64, 31, 95			; +0x0E box x1, y1, x2, y2
	.short	0x0002, 0x0110, 0x007f	; +0x16 class body

	; [#726] (unnamed)  class 0160:0029 = KN5000 widget type 0x29, 26 bytes, parent #722 SELECT_FILE_A_Z,
	; box 0,96-31,127.  Record layout and evidence: pool header above.
HdaeUiObj_726:
	.long	0x01600029				; +0x00 class id
	.short	722, 0xffff, 727, 725	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 96, 31, 127			; +0x0E box x1, y1, x2, y2
	.short	0x000d, 0x014a	; +0x16 class body

	; [#727] (unnamed)  class 016A:0008 = ClassName_Table[8] "AcWindowPage1Proc", 36 bytes, parent #722 SELECT_FILE_A_Z,
	; box 245,6-315,23.  Record layout and evidence: pool header above.
HdaeUiObj_727:
	.long	0x016a0008				; +0x00 class id
	.short	722, 0xffff, 0xffff, 726	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	245, 6, 315, 23			; +0x0E box x1, y1, x2, y2
	.short	0x00f3, 0x00c0, 0xffff	; +0x16 class body
	.long	0x00239c7a				; +0x1C RAM address (every 016A:0008 record)
	.short	0x0001, 0x0002	; +0x20 class body

	; [#728] "FILE_LOAD_A_Z"  class 0160:0035 = KN5000 widget type 0x35, 36 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_728:
	.long	0x01600035				; +0x00 class id
	.short	0xffff, 729, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0000	; +0x16 class body
	.long	0x00239c7c				; +0x1C RAM address (every 0160:0035 record)
	.long	0x00239c80				; +0x20 RAM address (every 0160:0035 record)

	; [#729] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #728 FILE_LOAD_A_Z,
	; box 44,220-75,237.  Record layout and evidence: pool header above.
HdaeUiObj_729:
	.long	0x0160001f				; +0x00 class id
	.short	728, 0xffff, 730, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 220, 75, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0002, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0007	; +0x26 class body

	; [#730] (unnamed)  class 0160:0022 = KN5000 widget type 0x22, 42 bytes, parent #728 FILE_LOAD_A_Z,
	; box 84,220-195,237.  Record layout and evidence: pool header above.
HdaeUiObj_730:
	.long	0x01600022				; +0x00 class id
	.short	728, 0xffff, 731, 729	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	84, 220, 195, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0002	; +0x16 class body
	.short	0x0004, 0x0003	; +0x26 class body

	; [#731] (unnamed)  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #728 FILE_LOAD_A_Z,
	; box 44,52-235,215.  Record layout and evidence: pool header above.
HdaeUiObj_731:
	.long	0x016a0000				; +0x00 class id
	.short	728, 0xffff, 732, 730	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 52, 235, 215			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0140	; +0x16 class body
	.long	0x00239c84				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0010	; +0x2A class body
	.long	0x00239c88				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x00239c8a				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#732] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #728 FILE_LOAD_A_Z,
	; box 204,220-235,237.  Record layout and evidence: pool header above.
HdaeUiObj_732:
	.long	0x0160001f				; +0x00 class id
	.short	728, 0xffff, 733, 731	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	204, 220, 235, 237			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c9, 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0005	; +0x16 class body
	.short	0x0008	; +0x26 class body

	; [#733] (unnamed)  class 0160:002D = KN5000 widget type 0x2D, 26 bytes, parent #728 FILE_LOAD_A_Z,
	; box 42,0-69,27.  Record layout and evidence: pool header above.
HdaeUiObj_733:
	.long	0x0160002d				; +0x00 class id
	.short	728, 0xffff, 734, 732	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	42, 0, 69, 27			; +0x0E box x1, y1, x2, y2
	.short	0x00ad, 0x0000	; +0x16 class body

	; [#734] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 48 bytes, parent #728 FILE_LOAD_A_Z,
	; box 70,7-238,25.  Record layout and evidence: pool header above.
HdaeUiObj_734:
	.long	0x0160002b				; +0x00 class id
	.short	728, 0xffff, 735, 733	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	70, 7, 238, 25			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_734_Cap16			; +0x16 caption pointer
	.short	0x0004, 0x0000, 0x00ff	; +0x1A class body
	; caption of HdaeUiObj_734: the record's +0x16 caption pointer names this string
HdaeUiObj_734_Cap16:	.asciz	"FILE SELECT A-Z"

	; [#735] (unnamed)  class 0160:001F = KN5000 widget type 0x1F, 40 bytes, parent #728 FILE_LOAD_A_Z,
	; box 265,36-311,61.  Record layout and evidence: pool header above.
HdaeUiObj_735:
	.long	0x0160001f				; +0x00 class id
	.short	728, 0xffff, 736, 734	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	265, 36, 311, 61			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c0, 0x0003, 0x0000, 0x0000, 0x0000, 0x0000, 0x0008	; +0x16 class body
	.short	0x0006	; +0x26 class body

	; [#736] (unnamed)  class 0160:0030 = KN5000 widget type 0x30, 44 bytes, parent #728 FILE_LOAD_A_Z,
	; box 310,77-319,95.  Record layout and evidence: pool header above.
HdaeUiObj_736:
	.long	0x01600030				; +0x00 class id
	.short	728, 0xffff, 737, 735	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	310, 77, 319, 95			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_736_Cap16			; +0x16 caption pointer
	.short	0x0000, 0x0000, 0x00f4, 0x0009, 0x0000, 0x0120, 0x0006	; +0x1A class body
	; caption of HdaeUiObj_736: the record's +0x16 caption pointer names this string
HdaeUiObj_736_Cap16:	.asciz	"~80"

	; [#737] (unnamed)  class 0160:002E = KN5000 widget type 0x2E, 26 bytes, parent #728 FILE_LOAD_A_Z,
	; box 313,40-313,79.  Record layout and evidence: pool header above.
HdaeUiObj_737:
	.long	0x0160002e				; +0x00 class id
	.short	728, 0xffff, 738, 736	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	313, 40, 313, 79			; +0x0E box x1, y1, x2, y2
	.short	0x00f4, 0x0001	; +0x16 class body

	; [#738] (unnamed)  class 016A:0000 = ClassName_Table[0] "SelectListProc", 60 bytes, parent #728 FILE_LOAD_A_Z,
	; box 44,30-235,47.  Record layout and evidence: pool header above.
HdaeUiObj_738:
	.long	0x016a0000				; +0x00 class id
	.short	728, 739, 741, 737	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 30, 235, 47			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0, 0x0064, 0x0003, 0x0000, 0x00ff, 0x0000, 0x0140	; +0x16 class body
	.long	0x00239c8c				; +0x26 RAM address (every 016A:0000 record)
	.short	0x0001, 0x0001	; +0x2A class body
	.long	0x00239c90				; +0x2E RAM address (every 016A:0000 record)
	.short	0x0000, 0x0000	; +0x32 class body
	.long	0x00239c92				; +0x36 RAM address (every 016A:0000 record)
	.short	0x0000	; +0x3A class body

	; [#739] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 62 bytes, parent #738,
	; box 78,32-237,47.  Record layout and evidence: pool header above.
HdaeUiObj_739:
	.long	0x01600036				; +0x00 class id
	.short	738, 740, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	78, 32, 237, 47			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x0000	; +0x16 class body
	.long	HdaeUiObj_739_Cap1A			; +0x1A caption pointer
	.short	0x0003, 0x0000, 0x00f9, 0x0001, 0x0001	; +0x1E class body
	; caption of HdaeUiObj_739: the record's +0x1A caption pointer names this string
HdaeUiObj_739_Cap1A:	.asciz	"Evergreens slow / 12"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#740] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 46 bytes, parent #739,
	; box 44,32-127,47.  Record layout and evidence: pool header above.
HdaeUiObj_740:
	.long	0x01600036				; +0x00 class id
	.short	739, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	44, 32, 127, 47			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000	; +0x16 class body
	.long	HdaeUiObj_740_Cap1A			; +0x1A caption pointer
	.short	0x0003, 0x0000, 0x00ff, 0x0001, 0x0001	; +0x1E class body
	; caption of HdaeUiObj_740: the record's +0x1A caption pointer names this string
HdaeUiObj_740_Cap1A:	.asciz	"LOC.:"

	; [#741] (unnamed)  class 0160:0010 = KN5000 widget type 0x10, 22 bytes, parent #728 FILE_LOAD_A_Z,
	; box 60,84-259,131.  Record layout and evidence: pool header above.
HdaeUiObj_741:
	.long	0x01600010				; +0x00 class id
	.short	728, 0xffff, 742, 738	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	60, 84, 259, 131			; +0x0E box x1, y1, x2, y2

	; [#742] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #728 FILE_LOAD_A_Z,
	; box 236,100-319,215.  Record layout and evidence: pool header above.
HdaeUiObj_742:
	.long	0x01600036				; +0x00 class id
	.short	728, 743, 0xffff, 741	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	236, 100, 319, 215			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_742_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0001, 0x0003	; +0x1E class body
	; caption of HdaeUiObj_742: the record's +0x1A caption pointer names this string
HdaeUiObj_742_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#743] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 54 bytes, parent #742,
	; box 236,174-319,191.  Record layout and evidence: pool header above.
HdaeUiObj_743:
	.long	0x01600036				; +0x00 class id
	.short	742, 0xffff, 744, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	236, 174, 319, 191			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000	; +0x16 class body
	.long	HdaeUiObj_743_Cap1A			; +0x1A caption pointer
	.short	0x0003, 0x0000, 0x00ff, 0x0000, 0x0001	; +0x1E class body
	; caption of HdaeUiObj_743: the record's +0x1A caption pointer names this string
HdaeUiObj_743_Cap1A:	.asciz	"RHYTHM CUSTOM"
	.set	HDAE5000_Demo_Data, HdaeUiObj_743_Cap1A	; 0x2A5634
	; MISNOMER retained for cross-reference.  RETRACTED: "Demo song data and
	; rhythm custom UI".  There is NO demo song data anywhere in this pool -
	; it is 769 UI object descriptors and nothing else, every byte of it
	; assigned to a record by the header at HDAE5000_UI_Descriptors.
	; 0x2A5634 is byte +0x28 of object #743 (record 0x2A560C-0x2A5641, 54
	; bytes, class 0160:0036, under FILE_LOAD_A_Z via object #742) - that
	; ONE object's inline caption, named by the .long at +0x1A of the
	; record.  The nearest record boundary is 0x28 bytes ABOVE this label.

	; [#744] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 50 bytes, parent #742,
	; box 236,186-319,203.  Record layout and evidence: pool header above.
HdaeUiObj_744:
	.long	0x01600036				; +0x00 class id
	.short	742, 0xffff, 745, 743	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	236, 186, 319, 203			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000	; +0x16 class body
	.long	HdaeUiObj_744_Cap1A			; +0x1A caption pointer
	.short	0x0003, 0x0000, 0x00ff, 0x0000, 0x0001	; +0x1E class body
	; caption of HdaeUiObj_744: the record's +0x1A caption pointer names this string
HdaeUiObj_744_Cap1A:	.asciz	"USER MIDI"

	; [#745] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 52 bytes, parent #742,
	; box 236,198-319,215.  Record layout and evidence: pool header above.
HdaeUiObj_745:
	.long	0x01600036				; +0x00 class id
	.short	742, 0xffff, 746, 744	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	236, 198, 319, 215			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000	; +0x16 class body
	.long	HdaeUiObj_745_Cap1A			; +0x1A caption pointer
	.short	0x0003, 0x0000, 0x000d, 0x0000, 0x0001	; +0x1E class body
	; caption of HdaeUiObj_745: the record's +0x1A caption pointer names this string
HdaeUiObj_745_Cap1A:	.asciz	"TECH LYRICS"

	; [#746] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 44 bytes, parent #742,
	; box 236,162-319,179.  Record layout and evidence: pool header above.
HdaeUiObj_746:
	.long	0x01600036				; +0x00 class id
	.short	742, 0xffff, 747, 745	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	236, 162, 319, 179			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000	; +0x16 class body
	.long	HdaeUiObj_746_Cap1A			; +0x1A caption pointer
	.short	0x0003, 0x0000, 0x00ff, 0x0000, 0x0001	; +0x1E class body
	; caption of HdaeUiObj_746: the record's +0x1A caption pointer names this string
HdaeUiObj_746_Cap1A:	.asciz	"MSP"

	; [#747] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 54 bytes, parent #742,
	; box 236,150-319,167.  Record layout and evidence: pool header above.
HdaeUiObj_747:
	.long	0x01600036				; +0x00 class id
	.short	742, 748, 749, 746	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	236, 150, 319, 167			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000	; +0x16 class body
	.long	HdaeUiObj_747_Cap1A			; +0x1A caption pointer
	.short	0x0003, 0x0000, 0x00ff, 0x0000, 0x0001	; +0x1E class body
	; caption of HdaeUiObj_747: the record's +0x1A caption pointer names this string
HdaeUiObj_747_Cap1A:	.asciz	"SOUND MEMORY"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#748] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 50 bytes, parent #747,
	; box 236,138-319,155.  Record layout and evidence: pool header above.
HdaeUiObj_748:
	.long	0x01600036				; +0x00 class id
	.short	747, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	236, 138, 319, 155			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000	; +0x16 class body
	.long	HdaeUiObj_748_Cap1A			; +0x1A caption pointer
	.short	0x0003, 0x0000, 0x00ff, 0x0000, 0x0001	; +0x1E class body
	; caption of HdaeUiObj_748: the record's +0x1A caption pointer names this string
HdaeUiObj_748_Cap1A:	.asciz	"COMPOSER"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#749] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 50 bytes, parent #742,
	; box 236,126-319,143.  Record layout and evidence: pool header above.
HdaeUiObj_749:
	.long	0x01600036				; +0x00 class id
	.short	742, 0xffff, 750, 747	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	236, 126, 319, 143			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000	; +0x16 class body
	.long	HdaeUiObj_749_Cap1A			; +0x1A caption pointer
	.short	0x0003, 0x0000, 0x00ff, 0x0000, 0x0001	; +0x1E class body
	; caption of HdaeUiObj_749: the record's +0x1A caption pointer names this string
HdaeUiObj_749_Cap1A:	.asciz	"SEQUENCER"

	; [#750] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 54 bytes, parent #742,
	; box 236,114-319,131.  Record layout and evidence: pool header above.
HdaeUiObj_750:
	.long	0x01600036				; +0x00 class id
	.short	742, 0xffff, 751, 749	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	236, 114, 319, 131			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000	; +0x16 class body
	.long	HdaeUiObj_750_Cap1A			; +0x1A caption pointer
	.short	0x0003, 0x0000, 0x00ff, 0x0000, 0x0001	; +0x1E class body
	; caption of HdaeUiObj_750: the record's +0x1A caption pointer names this string
HdaeUiObj_750_Cap1A:	.asciz	"PANEL MEMORY"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#751] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 54 bytes, parent #742,
	; box 236,102-319,119.  Record layout and evidence: pool header above.
HdaeUiObj_751:
	.long	0x01600036				; +0x00 class id
	.short	742, 0xffff, 0xffff, 750	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	236, 102, 319, 119			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000	; +0x16 class body
	.long	HdaeUiObj_751_Cap1A			; +0x1A caption pointer
	.short	0x0003, 0x0000, 0x00ff, 0x0000, 0x0001	; +0x1E class body
	; caption of HdaeUiObj_751: the record's +0x1A caption pointer names this string
HdaeUiObj_751_Cap1A:	.asciz	"CURRENT PANEL"

	; [#752] "Tech_lyrics"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 54 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_752:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 753, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c94				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_752_Cap22			; +0x22 caption pointer
	.short	0x003c, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_752: the record's +0x22 caption pointer names this string
HdaeUiObj_752_Cap22:	.asciz	"TECH LYRICS"

	; [#753] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #752 Tech_lyrics,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_753:
	.long	0x01600049				; +0x00 class id
	.short	752, 0xffff, 754, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x007f	; +0x16 class body

	; [#754] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #752 Tech_lyrics,
	; box 0,33-319,56.  Record layout and evidence: pool header above.
HdaeUiObj_754:
	.long	0x01600036				; +0x00 class id
	.short	752, 755, 756, 753	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	0, 33, 319, 56			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_754_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0001	; +0x1E class body
	; caption of HdaeUiObj_754: the record's +0x1A caption pointer names this string
HdaeUiObj_754_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#755] "SongTitle"  class 0160:0012 = KN5000 widget type 0x12, 36 bytes, parent #754,
	; box 3,34-319,55.  Record layout and evidence: pool header above.
HdaeUiObj_755:
	.long	0x01600012				; +0x00 class id
	.short	754, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	3, 34, 319, 55			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0005, 0x0000, 0x00ff, 0x0000	; +0x16 class body

	; [#756] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #752 Tech_lyrics,
	; box 0,56-319,73.  Record layout and evidence: pool header above.
HdaeUiObj_756:
	.long	0x01600036				; +0x00 class id
	.short	752, 757, 758, 754	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	0, 56, 319, 73			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_756_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0001, 0x0001	; +0x1E class body
	; caption of HdaeUiObj_756: the record's +0x1A caption pointer names this string
HdaeUiObj_756_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#757] "Conductor"  class 0160:0012 = KN5000 widget type 0x12, 36 bytes, parent #756,
	; box 3,57-319,71.  Record layout and evidence: pool header above.
HdaeUiObj_757:
	.long	0x01600012				; +0x00 class id
	.short	756, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	3, 57, 319, 71			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000	; +0x16 class body

	; [#758] "bottom01"  class 0160:0012 = KN5000 widget type 0x12, 36 bytes, parent #752 Tech_lyrics,
	; box 0,224-39,239.  Record layout and evidence: pool header above.
HdaeUiObj_758:
	.long	0x01600012				; +0x00 class id
	.short	752, 0xffff, 759, 756	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	0, 224, 39, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000	; +0x16 class body

	; [#759] "bottom02"  class 0160:0012 = KN5000 widget type 0x12, 36 bytes, parent #752 Tech_lyrics,
	; box 40,224-79,239.  Record layout and evidence: pool header above.
HdaeUiObj_759:
	.long	0x01600012				; +0x00 class id
	.short	752, 0xffff, 760, 758	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	40, 224, 79, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000	; +0x16 class body

	; [#760] "bottom03"  class 0160:0012 = KN5000 widget type 0x12, 36 bytes, parent #752 Tech_lyrics,
	; box 80,224-119,239.  Record layout and evidence: pool header above.
HdaeUiObj_760:
	.long	0x01600012				; +0x00 class id
	.short	752, 0xffff, 761, 759	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	80, 224, 119, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000	; +0x16 class body

	; [#761] "bottom04"  class 0160:0012 = KN5000 widget type 0x12, 36 bytes, parent #752 Tech_lyrics,
	; box 120,224-159,239.  Record layout and evidence: pool header above.
HdaeUiObj_761:
	.long	0x01600012				; +0x00 class id
	.short	752, 0xffff, 762, 760	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	120, 224, 159, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000	; +0x16 class body

	; [#762] "bottom05"  class 0160:0012 = KN5000 widget type 0x12, 36 bytes, parent #752 Tech_lyrics,
	; box 160,224-199,239.  Record layout and evidence: pool header above.
HdaeUiObj_762:
	.long	0x01600012				; +0x00 class id
	.short	752, 0xffff, 763, 761	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	160, 224, 199, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000	; +0x16 class body

	; [#763] "bottom06"  class 0160:0012 = KN5000 widget type 0x12, 36 bytes, parent #752 Tech_lyrics,
	; box 200,224-239,239.  Record layout and evidence: pool header above.
HdaeUiObj_763:
	.long	0x01600012				; +0x00 class id
	.short	752, 0xffff, 764, 762	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	200, 224, 239, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000	; +0x16 class body

	; [#764] "bottom07"  class 0160:0012 = KN5000 widget type 0x12, 36 bytes, parent #752 Tech_lyrics,
	; box 240,224-279,239.  Record layout and evidence: pool header above.
HdaeUiObj_764:
	.long	0x01600012				; +0x00 class id
	.short	752, 0xffff, 765, 763	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	240, 224, 279, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000	; +0x16 class body

	; [#765] "bottom08"  class 0160:0012 = KN5000 widget type 0x12, 36 bytes, parent #752 Tech_lyrics,
	; box 280,224-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_765:
	.long	0x01600012				; +0x00 class id
	.short	752, 0xffff, 766, 764	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	280, 224, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0xffff, 0x0003, 0x0000, 0x00ff, 0x0000	; +0x16 class body

	; [#766] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #752 Tech_lyrics,
	; box 0,209-319,224.  Record layout and evidence: pool header above.
HdaeUiObj_766:
	.long	0x01600036				; +0x00 class id
	.short	752, 767, 771, 765	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	0, 209, 319, 224			; +0x0E box x1, y1, x2, y2
	.short	0x0008, 0x00c0	; +0x16 class body
	.long	HdaeUiObj_766_Cap1A			; +0x1A caption pointer
	.short	0x0000, 0x0000, 0x0000, 0x0001, 0x0001	; +0x1E class body
	; caption of HdaeUiObj_766: the record's +0x1A caption pointer names this string
HdaeUiObj_766_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#771] (unnamed)  class 016A:000B = ClassName_Table[11] "LyricBoxProc", 46 bytes, parent #752 Tech_lyrics,
	; box 0,75-319,206.  Record layout and evidence: pool header above.
HdaeUiObj_771:
	.long	0x016a000b				; +0x00 class id
	.short	752, 0xffff, 0xffff, 766	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	0, 75, 319, 206			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0005, 0xffff	; +0x16 class body
	.long	0x00239c98				; +0x1C RAM address (every 016A:000B record)
	.short	0x0007, 0x0000, 0x00fc, 0x000d, 0x0003, 0x0000, 0x00f9	; +0x20 class body

	; [#772] "LoadLyricFD"  class 016A:0007 = ClassName_Table[7] "TtlScreenR3Proc", 62 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_772:
	.long	0x016a0007				; +0x00 class id
	.short	0xffff, 773, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x0000, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239c9a				; +0x1E RAM address (every 016A:0007 record)
	.long	HdaeUiObj_772_Cap22			; +0x22 caption pointer
	.short	0x0027, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_772: the record's +0x22 caption pointer names this string
HdaeUiObj_772_Cap22:	.asciz	"LOAD LYRICS FROM FD"

	; [#773] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #772 LoadLyricFD,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_773:
	.long	0x01600049				; +0x00 class id
	.short	772, 0xffff, 774, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x02f0, 0x007f	; +0x16 class body

	; [#774] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #772 LoadLyricFD,
	; box 28,225-55,235.  Record layout and evidence: pool header above.
HdaeUiObj_774:
	.long	0x0160002b				; +0x00 class id
	.short	772, 0xffff, 775, 773	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	28, 225, 55, 235			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_774_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_774: the record's +0x16 caption pointer names this string
HdaeUiObj_774_Cap16:	.asciz	"Info"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#775] (unnamed)  class 0160:002B = KN5000 widget type 0x2B, 38 bytes, parent #772 LoadLyricFD,
	; box 262,225-289,235.  Record layout and evidence: pool header above.
HdaeUiObj_775:
	.long	0x0160002b				; +0x00 class id
	.short	772, 0xffff, 776, 774	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	262, 225, 289, 235			; +0x0E box x1, y1, x2, y2
	.long	HdaeUiObj_775_Cap16			; +0x16 caption pointer
	.short	0x0003, 0x0000, 0x0000	; +0x1A class body
	; caption of HdaeUiObj_775: the record's +0x16 caption pointer names this string
HdaeUiObj_775_Cap16:	.asciz	"Load"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#776] (unnamed)  class 016A:000C = ClassName_Table[12] "FDFileSelectProc", 32 bytes, parent #772 LoadLyricFD,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_776:
	.long	0x016a000c				; +0x00 class id
	.short	772, 0xffff, 0xffff, 775	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0000	; +0x16 class body
	.long	0x00239c9e				; +0x18 RAM address (every 016A:000C record)
	.long	0x00239ca0				; +0x1C RAM address (every 016A:000C record)

	; [#777] "FD_PLEASE"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 44 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_777:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 778, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239ca2				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_777_Cap22			; +0x22 caption pointer
	.short	0x0000, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_777: the record's +0x22 caption pointer names this string
HdaeUiObj_777_Cap22:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#778] (unnamed)  class 0160:0036 = KN5000 widget type 0x36, 42 bytes, parent #777 FD_PLEASE,
	; box 60,84-259,131.  Record layout and evidence: pool header above.
HdaeUiObj_778:
	.long	0x01600036				; +0x00 class id
	.short	777, 779, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	60, 84, 259, 131			; +0x0E box x1, y1, x2, y2
	.short	0x0009, 0x00c1	; +0x16 class body
	.long	HdaeUiObj_778_Cap1A			; +0x1A caption pointer
	.short	0x0001, 0x0000, 0x0000, 0x0000, 0x0001	; +0x1E class body
	; caption of HdaeUiObj_778: the record's +0x1A caption pointer names this string
HdaeUiObj_778_Cap1A:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#779] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #778,
	; box 72,98-241,121.  Record layout and evidence: pool header above.
HdaeUiObj_779:
	.long	0x016a000a				; +0x00 class id
	.short	778, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	72, 98, 241, 121			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0031, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#780] "LyrSettings"  class 016A:0006 = ClassName_Table[6] "TtlScreenR2Proc", 58 bytes, parent none (root),
	; box 0,0-319,239.  Record layout and evidence: pool header above.
HdaeUiObj_780:
	.long	0x016a0006				; +0x00 class id
	.short	0xffff, 781, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x000a					; +0x0C attribute word
	.short	0, 0, 319, 239			; +0x0E box x1, y1, x2, y2
	.short	0x00ff, 0x0000, 0x0000, 0x01a0	; +0x16 class body
	.long	0x00239ca6				; +0x1E RAM address (every 016A:0006 record)
	.long	HdaeUiObj_780_Cap22			; +0x22 caption pointer
	.short	0x003c, 0x0000	; +0x26 class body
	; caption of HdaeUiObj_780: the record's +0x22 caption pointer names this string
HdaeUiObj_780_Cap22:	.asciz	"LYRICS OPTIONS"
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#781] (unnamed)  class 0160:0049 = KN5000 widget type 0x49, 26 bytes, parent #780 LyrSettings,
	; box 0,0-31,31.  Record layout and evidence: pool header above.
HdaeUiObj_781:
	.long	0x01600049				; +0x00 class id
	.short	780, 0xffff, 782, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0018					; +0x0C attribute word
	.short	0, 0, 31, 31			; +0x0E box x1, y1, x2, y2
	.short	0x0013, 0x007f	; +0x16 class body

	; [#782] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 60 bytes, parent #780 LyrSettings,
	; box 8,72-197,97.  Record layout and evidence: pool header above.
HdaeUiObj_782:
	.long	0x0160001b				; +0x00 class id
	.short	780, 783, 784, 781	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 72, 197, 97			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0000	; +0x16 class body
	.long	HdaeUiObj_782_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0002, 0x0004, 0x0089, 0x0001	; +0x20 class body
	.long	0x00239caa				; +0x2E RAM address (every 0160:001B record)
	.short	0x0042, 0x012a	; +0x32 class body
	.long	0x00239cac				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_782: the record's +0x1C caption pointer names this string
HdaeUiObj_782_Cap1C:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#783] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #782,
	; box 8,72-142,103.  Record layout and evidence: pool header above.
HdaeUiObj_783:
	.long	0x016a000a				; +0x00 class id
	.short	782, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 72, 142, 103			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0040, 0x0000, 0x0000, 0x00ff, 0x0001, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#784] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 60 bytes, parent #780 LyrSettings,
	; box 8,114-197,139.  Record layout and evidence: pool header above.
HdaeUiObj_784:
	.long	0x0160001b				; +0x00 class id
	.short	780, 785, 786, 782	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 114, 197, 139			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0000	; +0x16 class body
	.long	HdaeUiObj_784_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0002, 0x0004, 0x008a, 0x0001	; +0x20 class body
	.long	0x00239cb0				; +0x2E RAM address (every 0160:001B record)
	.short	0x0043, 0x012a	; +0x32 class body
	.long	0x00239cb2				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_784: the record's +0x1C caption pointer names this string
HdaeUiObj_784_Cap1C:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#785] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #784,
	; box 8,114-142,145.  Record layout and evidence: pool header above.
HdaeUiObj_785:
	.long	0x016a000a				; +0x00 class id
	.short	784, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 114, 142, 145			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0041, 0x0000, 0x0000, 0x00ff, 0x0001, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#786] (unnamed)  class 0160:001B = KN5000 widget type 0x1B, 60 bytes, parent #780 LyrSettings,
	; box 8,156-197,181.  Record layout and evidence: pool header above.
HdaeUiObj_786:
	.long	0x0160001b				; +0x00 class id
	.short	780, 0xffff, 787, 784	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 156, 197, 181			; +0x0E box x1, y1, x2, y2
	.short	0x00f5, 0x0000, 0x0000	; +0x16 class body
	.long	HdaeUiObj_786_Cap1C			; +0x1C caption pointer
	.short	0x0000, 0x0000, 0x00ff, 0x0002, 0x0004, 0x008b, 0x0001	; +0x20 class body
	.long	0x00239cb6				; +0x2E RAM address (every 0160:001B record)
	.short	0x0044, 0x012a	; +0x32 class body
	.long	0x00239cb8				; +0x36 RAM address (every 0160:001B record)
	; caption of HdaeUiObj_786: the record's +0x1C caption pointer names this string
HdaeUiObj_786_Cap1C:	.asciz	""
	.balign	2, 0x00					; word-align pad (proven: see convert_align_pads.py header)

	; [#787] (unnamed)  class 016A:000A = ClassName_Table[10] "AcLanguageText1Proc", 42 bytes, parent #780 LyrSettings,
	; box 8,156-142,187.  Record layout and evidence: pool header above.
HdaeUiObj_787:
	.long	0x016a000a				; +0x00 class id
	.short	780, 0xffff, 0xffff, 786	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	8, 156, 142, 187			; +0x0E box x1, y1, x2, y2
	.short	0x00f7, 0x0000, 0x0042, 0x0000, 0x0000, 0x00ff, 0x0001, 0x0001	; +0x16 class body
	.short	0x0040, 0x012a	; +0x26 class body

	; [#788] "WriteIn"  class 0160:0035 = KN5000 widget type 0x35, 36 bytes, parent none (root),
	; box 16,112-307,223.  Record layout and evidence: pool header above.
HdaeUiObj_788:
	.long	0x01600035				; +0x00 class id
	.short	0xffff, 0xffff, 0xffff, 0xffff	; +0x04 parent, first child, next, previous
	.short	0x0008					; +0x0C attribute word
	.short	16, 112, 307, 223			; +0x0E box x1, y1, x2, y2
	.short	0x0007, 0x00c1, 0x0000	; +0x16 class body
	.long	0x00239cbc				; +0x1C RAM address (every 0160:0035 record)
	.long	0x00239cc0				; +0x20 RAM address (every 0160:0035 record)


; =============================================================================
; HD-AE5000 UI OBJECT TABLE (0x2A5D2C - 0x2A6983)
; =============================================================================
; 789 pointers to UI object descriptors plus a NULL end-of-table marker: 790
; .long entries, no code.  Registered at boot by HDAE5000_Handler_Registration
; (hd-ae5000_v2_06i.s) as object table 0x7F: class id 0x01600010, proc
; RootFn_ViewableProc, entry count 0x315 = 789, table pointer 0x2A5D2C, handed
; to RootFn_RegisterObjectTable.
;
; This block used to be disassembled as instructions under the label
; HDAE5000_GFX_DATA_1 ("graphics data block 1").  It is not code and it is not
; graphics: all 3160 bytes group into valid little-endian 32-bit pointers - 769
; into the UI descriptor pool at 0x29DC12-0x2A5D2B (strictly ascending), 20 into
; sub-CPU work RAM 0x239CC4-0x239FAE for the objects whose descriptor is built at
; run time, and one 0x00000000 terminator.
;
; The table is INDEX-PARALLEL with HDAE5000_UiObjectName_PtrTable (0x2A6984):
; entry i here is the descriptor of the object entry i there names.  48 named
; entries also carry an on-screen title inside the descriptor, and ALL 48 agree
; with the name - no counter-example - e.g.
;   [  0] HDDMENU         <-> "HD-AE5000"       [ 19] SETUPS_TOOLS  <-> "SETUP & TOOLS"
;   [ 69] HARD_TEST       <-> "HARDWARE TEST"   [102] PC_DATA_LINK  <-> "PC DATA LINK"
;   [143] LOAD_BY_NUM     <-> "LOAD BY NUMBER"  [345] FLS_FILE_SEL  <-> "F.L.S. FILE SELECT"
;   [210] CP_FD           <-> "COPY TECH TO HD" [556] DBG_MEMO_SCREEN <-> "DEBUG MEMO SCREEN"
; and, decisively, the two 9-object families that enumerate the KN5000 data
; types in the same order under two different prefixes:
;   RAM_EDIT_{LSW,PMT,SQT,CMP,TM,MSP,RCM,MD,TLX} = objects 406-412,426
;   DEL_EDIT_{LSW,PMT,SQT,CMP,TM,MSP,RCM,MD,TLX} = objects 463-470,489
;   both spelling out CURRENT PANEL / PANEL MEMORY / SEQUENCER / COMPOSER /
;   SOUND MEMORY / MSP / RHYTHM CUSTOM / USER MIDI SETTINGS / TECHNICS LYRICS.
; The 20 RAM-descriptor entries are all soft-key or tab objects
; (HddNamingABC/abc/Symbol, *_SW_EDIT, CP_FD_HDSW*, *_EXIT, *inLyric).
;
; The 769 pool entries are symbolic since 2026-09-25 (`.long HdaeUiObj_NNN`,
; written by scripts/generators/gen_hdae5000_ui_pool.py); the 20 RAM entries
; stay numeric.  Before that the targets were absolute because the pool was
; decoded as byte noise and the
; labels HDAE5000_UI_Descriptors (0x29DC14) / _UI_Page_Titles / _Panel_Save_UI /
; _Credits / _Demo_Data cut that one contiguous pool into five arbitrary pieces -
; none of them a descriptor boundary; the pool really starts at 0x29DC12, two
; bytes below the first of those labels.  The record format, the 769 boundaries
; and where each of those five labels actually falls are now documented in the
; header block at HDAE5000_UI_Descriptors: they are +0x02 of record #0 and
; +0x28 / +0x3A / +0x20 / +0x28 of records #18 / #177 / #645 / #743, the last
; four sitting on that record's inline caption string.  The names are kept as
; misnomers because the ASL mirror, the symbols reference and seven .set bases
; in hdae5000_init_data.s use them.  The records are split only at the .long
; values of this table.
; =============================================================================

HDAE5000_UiObject_PtrTable:	; 0x2A5D2C
	.long	HdaeUiObj_000        ; [  0] HDDMENU
	.long	HdaeUiObj_001        ; [  1] (unnamed)
	.long	HdaeUiObj_002        ; [  2] (unnamed)
	.long	HdaeUiObj_003        ; [  3] (unnamed)
	.long	HdaeUiObj_004        ; [  4] (unnamed)
	.long	HdaeUiObj_005        ; [  5] (unnamed)
	.long	HdaeUiObj_006        ; [  6] (unnamed)
	.long	HdaeUiObj_007        ; [  7] (unnamed)
	.long	HdaeUiObj_008        ; [  8] (unnamed)
	.long	HdaeUiObj_009        ; [  9] (unnamed)
	.long	HdaeUiObj_010        ; [ 10] HARD_DISK_OPT
	.long	HdaeUiObj_011        ; [ 11] (unnamed)
	.long	HdaeUiObj_012        ; [ 12] (unnamed)
	.long	HdaeUiObj_013        ; [ 13] (unnamed)
	.long	HdaeUiObj_014        ; [ 14] (unnamed)
	.long	HdaeUiObj_015        ; [ 15] (unnamed)
	.long	HdaeUiObj_016        ; [ 16] (unnamed)
	.long	HdaeUiObj_017        ; [ 17] (unnamed)
	.long	HdaeUiObj_018        ; [ 18] (unnamed)
	.long	HdaeUiObj_019        ; [ 19] SETUPS_TOOLS
	.long	HdaeUiObj_020        ; [ 20] (unnamed)
	.long	HdaeUiObj_021        ; [ 21] (unnamed)
	.long	HdaeUiObj_022        ; [ 22] (unnamed)
	.long	HdaeUiObj_023        ; [ 23] (unnamed)
	.long	HdaeUiObj_024        ; [ 24] SELECT_FILE
	.long	HdaeUiObj_025        ; [ 25] (unnamed)
	.long	HdaeUiObj_026        ; [ 26] HD_FILE_LOAD
	.long	HdaeUiObj_027        ; [ 27] HD_LOAD_OPTION
	.long	HdaeUiObj_028        ; [ 28] (unnamed)
	.long	HdaeUiObj_029        ; [ 29] (unnamed)
	.long	HdaeUiObj_030        ; [ 30] (unnamed)
	.long	HdaeUiObj_031        ; [ 31] (unnamed)
	.long	HdaeUiObj_032        ; [ 32] (unnamed)
	.long	HdaeUiObj_033        ; [ 33] (unnamed)
	.long	HdaeUiObj_034        ; [ 34] SELECT_DIR
	.long	HdaeUiObj_035        ; [ 35] (unnamed)
	.long	HdaeUiObj_036        ; [ 36] (unnamed)
	.long	HdaeUiObj_037        ; [ 37] SEL_DIR
	.long	HdaeUiObj_038        ; [ 38] (unnamed)
	.long	HdaeUiObj_039        ; [ 39] (unnamed)
	.long	HdaeUiObj_040        ; [ 40] (unnamed)
	.long	HdaeUiObj_041        ; [ 41] (unnamed)
	.long	HdaeUiObj_042        ; [ 42] (unnamed)
	.long	HdaeUiObj_043        ; [ 43] (unnamed)
	.long	0x00239CC4        ; [ 44] SELECT_DIR_SW_EDIT  -- RAM descriptor
	.long	HdaeUiObj_045        ; [ 45] (unnamed)
	.long	HdaeUiObj_046        ; [ 46] (unnamed)
	.long	HdaeUiObj_047        ; [ 47] (unnamed)
	.long	HdaeUiObj_048        ; [ 48] (unnamed)
	.long	HdaeUiObj_049        ; [ 49] SELECT_DIR2
	.long	HdaeUiObj_050        ; [ 50] (unnamed)
	.long	HdaeUiObj_051        ; [ 51] (unnamed)
	.long	HdaeUiObj_052        ; [ 52] (unnamed)
	.long	HdaeUiObj_053        ; [ 53] (unnamed)
	.long	HdaeUiObj_054        ; [ 54] (unnamed)
	.long	HdaeUiObj_055        ; [ 55] (unnamed)
	.long	HdaeUiObj_056        ; [ 56] (unnamed)
	.long	HdaeUiObj_057        ; [ 57] (unnamed)
	.long	HdaeUiObj_058        ; [ 58] FD_FILE_SELECT
	.long	HdaeUiObj_059        ; [ 59] (unnamed)
	.long	HdaeUiObj_060        ; [ 60] (unnamed)
	.long	HdaeUiObj_061        ; [ 61] (unnamed)
	.long	HdaeUiObj_062        ; [ 62] (unnamed)
	.long	HdaeUiObj_063        ; [ 63] (unnamed)
	.long	HdaeUiObj_064        ; [ 64] (unnamed)
	.long	HdaeUiObj_065        ; [ 65] (unnamed)
	.long	HdaeUiObj_066        ; [ 66] (unnamed)
	.long	HdaeUiObj_067        ; [ 67] (unnamed)
	.long	HdaeUiObj_068        ; [ 68] (unnamed)
	.long	HdaeUiObj_069        ; [ 69] HARD_TEST
	.long	HdaeUiObj_070        ; [ 70] (unnamed)
	.long	HdaeUiObj_071        ; [ 71] (unnamed)
	.long	HdaeUiObj_072        ; [ 72] (unnamed)
	.long	HdaeUiObj_073        ; [ 73] RUN_STOP
	.long	HdaeUiObj_074        ; [ 74] (unnamed)
	.long	HdaeUiObj_075        ; [ 75] PPORT_SW
	.long	HdaeUiObj_076        ; [ 76] FD_SW
	.long	HdaeUiObj_077        ; [ 77] HDD_SW
	.long	HdaeUiObj_078        ; [ 78] HDD_FILE_NAMING
	.long	HdaeUiObj_079        ; [ 79] (unnamed)
	.long	HdaeUiObj_080        ; [ 80] (unnamed)
	.long	HdaeUiObj_081        ; [ 81] (unnamed)
	.long	HdaeUiObj_082        ; [ 82] (unnamed)
	.long	HdaeUiObj_083        ; [ 83] (unnamed)
	.long	HdaeUiObj_084        ; [ 84] (unnamed)
	.long	HdaeUiObj_085        ; [ 85] (unnamed)
	.long	HdaeUiObj_086        ; [ 86] (unnamed)
	.long	HdaeUiObj_087        ; [ 87] HD_FILE_NAME
	.long	HdaeUiObj_088        ; [ 88] HDD_DIR_NAMING
	.long	HdaeUiObj_089        ; [ 89] (unnamed)
	.long	HdaeUiObj_090        ; [ 90] (unnamed)
	.long	HdaeUiObj_091        ; [ 91] (unnamed)
	.long	HdaeUiObj_092        ; [ 92] (unnamed)
	.long	HdaeUiObj_093        ; [ 93] (unnamed)
	.long	HdaeUiObj_094        ; [ 94] HD_PLEASE_WIN
	.long	HdaeUiObj_095        ; [ 95] (unnamed)
	.long	HdaeUiObj_096        ; [ 96] HD_UTIL
	.long	HdaeUiObj_097        ; [ 97] (unnamed)
	.long	HdaeUiObj_098        ; [ 98] (unnamed)
	.long	HdaeUiObj_099        ; [ 99] (unnamed)
	.long	HdaeUiObj_100        ; [100] (unnamed)
	.long	HdaeUiObj_101        ; [101] (unnamed)
	.long	HdaeUiObj_102        ; [102] PC_DATA_LINK
	.long	HdaeUiObj_103        ; [103] (unnamed)
	.long	HdaeUiObj_104        ; [104] PP_STATUS
	.long	HdaeUiObj_105        ; [105] (unnamed)
	.long	HdaeUiObj_106        ; [106] (unnamed)
	.long	HdaeUiObj_107        ; [107] (unnamed)
	.long	HdaeUiObj_108        ; [108] (unnamed)
	.long	HdaeUiObj_109        ; [109] (unnamed)
	.long	HdaeUiObj_110        ; [110] SETUP_TOOLS_P1
	.long	HdaeUiObj_111        ; [111] (unnamed)
	.long	HdaeUiObj_112        ; [112] (unnamed)
	.long	HdaeUiObj_113        ; [113] (unnamed)
	.long	HdaeUiObj_114        ; [114] (unnamed)
	.long	HdaeUiObj_115        ; [115] (unnamed)
	.long	HdaeUiObj_116        ; [116] (unnamed)
	.long	HdaeUiObj_117        ; [117] (unnamed)
	.long	HdaeUiObj_118        ; [118] (unnamed)
	.long	HdaeUiObj_119        ; [119] (unnamed)
	.long	HdaeUiObj_120        ; [120] (unnamed)
	.long	HdaeUiObj_121        ; [121] (unnamed)
	.long	HdaeUiObj_122        ; [122] SETUP_TOOLS_P2
	.long	HdaeUiObj_123        ; [123] (unnamed)
	.long	HdaeUiObj_124        ; [124] (unnamed)
	.long	HdaeUiObj_125        ; [125] (unnamed)
	.long	HdaeUiObj_126        ; [126] (unnamed)
	.long	HdaeUiObj_127        ; [127] (unnamed)
	.long	0x00239CEC        ; [128] SW_HD_FORMAT  -- RAM descriptor
	.long	HdaeUiObj_129        ; [129] (unnamed)
	.long	HdaeUiObj_130        ; [130] (unnamed)
	.long	HdaeUiObj_131        ; [131] (unnamed)
	.long	HdaeUiObj_132        ; [132] (unnamed)
	.long	HdaeUiObj_133        ; [133] OUTPUT_SETTING
	.long	HdaeUiObj_134        ; [134] (unnamed)
	.long	HdaeUiObj_135        ; [135] (unnamed)
	.long	HdaeUiObj_136        ; [136] (unnamed)
	.long	HdaeUiObj_137        ; [137] (unnamed)
	.long	HdaeUiObj_138        ; [138] (unnamed)
	.long	HdaeUiObj_139        ; [139] (unnamed)
	.long	HdaeUiObj_140        ; [140] (unnamed)
	.long	HdaeUiObj_141        ; [141] (unnamed)
	.long	HdaeUiObj_142        ; [142] (unnamed)
	.long	HdaeUiObj_143        ; [143] LOAD_BY_NUM
	.long	HdaeUiObj_144        ; [144] (unnamed)
	.long	HdaeUiObj_145        ; [145] (unnamed)
	.long	HdaeUiObj_146        ; [146] (unnamed)
	.long	HdaeUiObj_147        ; [147] (unnamed)
	.long	HdaeUiObj_148        ; [148] (unnamed)
	.long	HdaeUiObj_149        ; [149] LBN_P1
	.long	HdaeUiObj_150        ; [150] (unnamed)
	.long	HdaeUiObj_151        ; [151] (unnamed)
	.long	HdaeUiObj_152        ; [152] LBN_OPTION
	.long	HdaeUiObj_153        ; [153] (unnamed)
	.long	HdaeUiObj_154        ; [154] (unnamed)
	.long	HdaeUiObj_155        ; [155] (unnamed)
	.long	HdaeUiObj_156        ; [156] (unnamed)
	.long	HdaeUiObj_157        ; [157] (unnamed)
	.long	HdaeUiObj_158        ; [158] (unnamed)
	.long	HdaeUiObj_159        ; [159] (unnamed)
	.long	HdaeUiObj_160        ; [160] (unnamed)
	.long	HdaeUiObj_161        ; [161] (unnamed)
	.long	HdaeUiObj_162        ; [162] (unnamed)
	.long	HdaeUiObj_163        ; [163] (unnamed)
	.long	HdaeUiObj_164        ; [164] (unnamed)
	.long	HdaeUiObj_165        ; [165] (unnamed)
	.long	HdaeUiObj_166        ; [166] (unnamed)
	.long	HdaeUiObj_167        ; [167] (unnamed)
	.long	HdaeUiObj_168        ; [168] LBN_DIRNO_BOX
	.long	HdaeUiObj_169        ; [169] LBN_DIRNAME_BOX
	.long	HdaeUiObj_170        ; [170] LBN_FILENO_BOX
	.long	HdaeUiObj_171        ; [171] LBN_FILENAME_BOX
	.long	HdaeUiObj_172        ; [172] (unnamed)
	.long	HdaeUiObj_173        ; [173] (unnamed)
	.long	HdaeUiObj_174        ; [174] (unnamed)
	.long	HdaeUiObj_175        ; [175] LBN_P2
	.long	HdaeUiObj_176        ; [176] (unnamed)
	.long	HdaeUiObj_177        ; [177] (unnamed)
	.long	HdaeUiObj_178        ; [178] (unnamed)
	.long	HdaeUiObj_179        ; [179] (unnamed)
	.long	HdaeUiObj_180        ; [180] (unnamed)
	.long	HdaeUiObj_181        ; [181] (unnamed)
	.long	HdaeUiObj_182        ; [182] (unnamed)
	.long	HdaeUiObj_183        ; [183] (unnamed)
	.long	HdaeUiObj_184        ; [184] (unnamed)
	.long	HdaeUiObj_185        ; [185] (unnamed)
	.long	HdaeUiObj_186        ; [186] (unnamed)
	.long	HdaeUiObj_187        ; [187] (unnamed)
	.long	HdaeUiObj_188        ; [188] (unnamed)
	.long	HdaeUiObj_189        ; [189] (unnamed)
	.long	HdaeUiObj_190        ; [190] (unnamed)
	.long	HdaeUiObj_191        ; [191] (unnamed)
	.long	HdaeUiObj_192        ; [192] (unnamed)
	.long	HdaeUiObj_193        ; [193] (unnamed)
	.long	HdaeUiObj_194        ; [194] (unnamed)
	.long	HdaeUiObj_195        ; [195] (unnamed)
	.long	HdaeUiObj_196        ; [196] (unnamed)
	.long	HdaeUiObj_197        ; [197] (unnamed)
	.long	HdaeUiObj_198        ; [198] (unnamed)
	.long	HdaeUiObj_199        ; [199] (unnamed)
	.long	HdaeUiObj_200        ; [200] (unnamed)
	.long	HdaeUiObj_201        ; [201] (unnamed)
	.long	HdaeUiObj_202        ; [202] (unnamed)
	.long	HdaeUiObj_203        ; [203] (unnamed)
	.long	HdaeUiObj_204        ; [204] (unnamed)
	.long	HdaeUiObj_205        ; [205] (unnamed)
	.long	HdaeUiObj_206        ; [206] (unnamed)
	.long	HdaeUiObj_207        ; [207] (unnamed)
	.long	HdaeUiObj_208        ; [208] (unnamed)
	.long	HdaeUiObj_209        ; [209] (unnamed)
	.long	HdaeUiObj_210        ; [210] CP_FD
	.long	HdaeUiObj_211        ; [211] (unnamed)
	.long	HdaeUiObj_212        ; [212] (unnamed)
	.long	HdaeUiObj_213        ; [213] (unnamed)
	.long	HdaeUiObj_214        ; [214] (unnamed)
	.long	HdaeUiObj_215        ; [215] CP_FD_LIST
	.long	HdaeUiObj_216        ; [216] CP_FD_LINE2
	.long	HdaeUiObj_217        ; [217] CP_FD_LINE1
	.long	0x00239D22        ; [218] CP_FD_HDSWTO  -- RAM descriptor
	.long	HdaeUiObj_219        ; [219] (unnamed)
	.long	0x00239D4A        ; [220] CP_FD_HDSWSEL  -- RAM descriptor
	.long	HdaeUiObj_221        ; [221] (unnamed)
	.long	HdaeUiObj_222        ; [222] CP_FD_VOLLABEL
	.long	HdaeUiObj_223        ; [223] (unnamed)
	.long	0x00239D72        ; [224] CP_FD_HDALLSEL  -- RAM descriptor
	.long	HdaeUiObj_225        ; [225] (unnamed)
	.long	HdaeUiObj_226        ; [226] CP_FD_DIRSEL
	.long	HdaeUiObj_227        ; [227] (unnamed)
	.long	HdaeUiObj_228        ; [228] (unnamed)
	.long	HdaeUiObj_229        ; [229] (unnamed)
	.long	HdaeUiObj_230        ; [230] CP_FD_DIRBOX
	.long	HdaeUiObj_231        ; [231] (unnamed)
	.long	HdaeUiObj_232        ; [232] (unnamed)
	.long	HdaeUiObj_233        ; [233] (unnamed)
	.long	HdaeUiObj_234        ; [234] (unnamed)
	.long	HdaeUiObj_235        ; [235] (unnamed)
	.long	HdaeUiObj_236        ; [236] (unnamed)
	.long	HdaeUiObj_237        ; [237] (unnamed)
	.long	HdaeUiObj_238        ; [238] (unnamed)
	.long	HdaeUiObj_239        ; [239] (unnamed)
	.long	HdaeUiObj_240        ; [240] FLS_SELECT
	.long	HdaeUiObj_241        ; [241] (unnamed)
	.long	HdaeUiObj_242        ; [242] (unnamed)
	.long	HdaeUiObj_243        ; [243] (unnamed)
	.long	HdaeUiObj_244        ; [244] (unnamed)
	.long	HdaeUiObj_245        ; [245] (unnamed)
	.long	HdaeUiObj_246        ; [246] (unnamed)
	.long	HdaeUiObj_247        ; [247] (unnamed)
	.long	HdaeUiObj_248        ; [248] FLS_SEL
	.long	0x00239D9A        ; [249] FLS_SELECT_SW_EDIT  -- RAM descriptor
	.long	HdaeUiObj_250        ; [250] (unnamed)
	.long	HdaeUiObj_251        ; [251] SEL_FLS
	.long	HdaeUiObj_252        ; [252] (unnamed)
	.long	HdaeUiObj_253        ; [253] (unnamed)
	.long	HdaeUiObj_254        ; [254] (unnamed)
	.long	HdaeUiObj_255        ; [255] HD_FILE_LOAD_P1
	.long	0x00239DC2        ; [256] HD_FILE_LOAD_SW_SAVE  -- RAM descriptor
	.long	HdaeUiObj_257        ; [257] (unnamed)
	.long	HdaeUiObj_258        ; [258] HD_FILE_OPTION
	.long	HdaeUiObj_259        ; [259] HD_FILE_LIST
	.long	HdaeUiObj_260        ; [260] FILE_LOAD_DIRBOX
	.long	HdaeUiObj_261        ; [261] (unnamed)
	.long	HdaeUiObj_262        ; [262] (unnamed)
	.long	HdaeUiObj_263        ; [263] (unnamed)
	.long	HdaeUiObj_264        ; [264] (unnamed)
	.long	HdaeUiObj_265        ; [265] (unnamed)
	.long	0x00239DEA        ; [266] HD_FILE_LOAD_SW_DEL  -- RAM descriptor
	.long	HdaeUiObj_267        ; [267] (unnamed)
	.long	HdaeUiObj_268        ; [268] (unnamed)
	.long	0x00239E12        ; [269] HD_FILE_LOAD_SW_DELFILE  -- RAM descriptor
	.long	HdaeUiObj_270        ; [270] (unnamed)
	.long	HdaeUiObj_271        ; [271] (unnamed)
	.long	HdaeUiObj_272        ; [272] HD_FILE_LOAD_P2
	.long	HdaeUiObj_273        ; [273] (unnamed)
	.long	HdaeUiObj_274        ; [274] (unnamed)
	.long	HdaeUiObj_275        ; [275] (unnamed)
	.long	HdaeUiObj_276        ; [276] (unnamed)
	.long	HdaeUiObj_277        ; [277] (unnamed)
	.long	HdaeUiObj_278        ; [278] (unnamed)
	.long	HdaeUiObj_279        ; [279] (unnamed)
	.long	HdaeUiObj_280        ; [280] (unnamed)
	.long	HdaeUiObj_281        ; [281] (unnamed)
	.long	HdaeUiObj_282        ; [282] (unnamed)
	.long	HdaeUiObj_283        ; [283] (unnamed)
	.long	HdaeUiObj_284        ; [284] (unnamed)
	.long	HdaeUiObj_285        ; [285] (unnamed)
	.long	HdaeUiObj_286        ; [286] (unnamed)
	.long	HdaeUiObj_287        ; [287] (unnamed)
	.long	HdaeUiObj_288        ; [288] (unnamed)
	.long	HdaeUiObj_289        ; [289] (unnamed)
	.long	HdaeUiObj_290        ; [290] (unnamed)
	.long	HdaeUiObj_291        ; [291] (unnamed)
	.long	HdaeUiObj_292        ; [292] (unnamed)
	.long	HdaeUiObj_293        ; [293] (unnamed)
	.long	HdaeUiObj_294        ; [294] (unnamed)
	.long	HdaeUiObj_295        ; [295] (unnamed)
	.long	HdaeUiObj_296        ; [296] (unnamed)
	.long	HdaeUiObj_297        ; [297] (unnamed)
	.long	HdaeUiObj_298        ; [298] (unnamed)
	.long	HdaeUiObj_299        ; [299] (unnamed)
	.long	HdaeUiObj_300        ; [300] (unnamed)
	.long	HdaeUiObj_301        ; [301] (unnamed)
	.long	0x00239E3A        ; [302] (unnamed)  -- RAM descriptor
	.long	HdaeUiObj_303        ; [303] (unnamed)
	.long	HdaeUiObj_304        ; [304] (unnamed)
	.long	HdaeUiObj_305        ; [305] (unnamed)
	.long	HdaeUiObj_306        ; [306] (unnamed)
	.long	HdaeUiObj_307        ; [307] (unnamed)
	.long	HdaeUiObj_308        ; [308] HDD_FLS_NAMING
	.long	HdaeUiObj_309        ; [309] (unnamed)
	.long	HdaeUiObj_310        ; [310] (unnamed)
	.long	HdaeUiObj_311        ; [311] (unnamed)
	.long	HdaeUiObj_312        ; [312] (unnamed)
	.long	HdaeUiObj_313        ; [313] (unnamed)
	.long	HdaeUiObj_314        ; [314] FLS_FILE_LOAD
	.long	HdaeUiObj_315        ; [315] (unnamed)
	.long	HdaeUiObj_316        ; [316] (unnamed)
	.long	HdaeUiObj_317        ; [317] (unnamed)
	.long	0x00239E62        ; [318] FLS_FILE_LOAD_SW_EDIT  -- RAM descriptor
	.long	HdaeUiObj_319        ; [319] (unnamed)
	.long	HdaeUiObj_320        ; [320] (unnamed)
	.long	HdaeUiObj_321        ; [321] (unnamed)
	.long	HdaeUiObj_322        ; [322] (unnamed)
	.long	HdaeUiObj_323        ; [323] FLS_OPT_BOX
	.long	HdaeUiObj_324        ; [324] FLS_LOC_BOX
	.long	HdaeUiObj_325        ; [325] FLS_NAME_BOX
	.long	HdaeUiObj_326        ; [326] (unnamed)
	.long	HdaeUiObj_327        ; [327] (unnamed)
	.long	HdaeUiObj_328        ; [328] FLS_FILE_BOX
	.long	HdaeUiObj_329        ; [329] FLS_LOAD_LINE1
	.long	HdaeUiObj_330        ; [330] FLS_LOAD_LINE2
	.long	HdaeUiObj_331        ; [331] (unnamed)
	.long	HdaeUiObj_332        ; [332] (unnamed)
	.long	HdaeUiObj_333        ; [333] (unnamed)
	.long	HdaeUiObj_334        ; [334] FLS_DIR_SEL
	.long	HdaeUiObj_335        ; [335] (unnamed)
	.long	HdaeUiObj_336        ; [336] (unnamed)
	.long	HdaeUiObj_337        ; [337] FLS_DIR_BOX
	.long	HdaeUiObj_338        ; [338] (unnamed)
	.long	HdaeUiObj_339        ; [339] (unnamed)
	.long	HdaeUiObj_340        ; [340] (unnamed)
	.long	HdaeUiObj_341        ; [341] (unnamed)
	.long	HdaeUiObj_342        ; [342] (unnamed)
	.long	HdaeUiObj_343        ; [343] (unnamed)
	.long	HdaeUiObj_344        ; [344] (unnamed)
	.long	HdaeUiObj_345        ; [345] FLS_FILE_SEL
	.long	HdaeUiObj_346        ; [346] (unnamed)
	.long	HdaeUiObj_347        ; [347] FLS_FILE_SEL_DIRBOX
	.long	HdaeUiObj_348        ; [348] FLS_FILE_SEL_LISTBOX
	.long	HdaeUiObj_349        ; [349] (unnamed)
	.long	HdaeUiObj_350        ; [350] (unnamed)
	.long	HdaeUiObj_351        ; [351] (unnamed)
	.long	HdaeUiObj_352        ; [352] FLS_FILE_SEL_OPTBOX
	.long	HdaeUiObj_353        ; [353] (unnamed)
	.long	HdaeUiObj_354        ; [354] (unnamed)
	.long	HdaeUiObj_355        ; [355] FLS_EDIT
	.long	HdaeUiObj_356        ; [356] (unnamed)
	.long	HdaeUiObj_357        ; [357] (unnamed)
	.long	HdaeUiObj_358        ; [358] FLS_EDIT_NAME_BOX
	.long	HdaeUiObj_359        ; [359] (unnamed)
	.long	HdaeUiObj_360        ; [360] (unnamed)
	.long	HdaeUiObj_361        ; [361] FLS_EDIT_LIST_BOX
	.long	HdaeUiObj_362        ; [362] FLS_EDIT_LINE2
	.long	HdaeUiObj_363        ; [363] FLS_EDIT_LINE1
	.long	HdaeUiObj_364        ; [364] (unnamed)
	.long	HdaeUiObj_365        ; [365] (unnamed)
	.long	HdaeUiObj_366        ; [366] (unnamed)
	.long	HdaeUiObj_367        ; [367] (unnamed)
	.long	HdaeUiObj_368        ; [368] (unnamed)
	.long	HdaeUiObj_369        ; [369] (unnamed)
	.long	HdaeUiObj_370        ; [370] (unnamed)
	.long	HdaeUiObj_371        ; [371] (unnamed)
	.long	HdaeUiObj_372        ; [372] (unnamed)
	.long	HdaeUiObj_373        ; [373] (unnamed)
	.long	HdaeUiObj_374        ; [374] FLS_EDIT_LOC_BOX
	.long	HdaeUiObj_375        ; [375] FLS_EDIT_OPT_BOX
	.long	HdaeUiObj_376        ; [376] (unnamed)
	.long	HdaeUiObj_377        ; [377] (unnamed)
	.long	HdaeUiObj_378        ; [378] (unnamed)
	.long	HdaeUiObj_379        ; [379] CP_FD_DIR_NAMING
	.long	HdaeUiObj_380        ; [380] (unnamed)
	.long	HdaeUiObj_381        ; [381] (unnamed)
	.long	HdaeUiObj_382        ; [382] (unnamed)
	.long	HdaeUiObj_383        ; [383] (unnamed)
	.long	HdaeUiObj_384        ; [384] (unnamed)
	.long	HdaeUiObj_385        ; [385] (unnamed)
	.long	HdaeUiObj_386        ; [386] SAVE_OPT_SCREEN
	.long	HdaeUiObj_387        ; [387] (unnamed)
	.long	HdaeUiObj_388        ; [388] (unnamed)
	.long	HdaeUiObj_389        ; [389] (unnamed)
	.long	HdaeUiObj_390        ; [390] (unnamed)
	.long	HdaeUiObj_391        ; [391] (unnamed)
	.long	HdaeUiObj_392        ; [392] (unnamed)
	.long	HdaeUiObj_393        ; [393] (unnamed)
	.long	HdaeUiObj_394        ; [394] (unnamed)
	.long	HdaeUiObj_395        ; [395] (unnamed)
	.long	HdaeUiObj_396        ; [396] (unnamed)
	.long	HdaeUiObj_397        ; [397] (unnamed)
	.long	HdaeUiObj_398        ; [398] (unnamed)
	.long	HdaeUiObj_399        ; [399] (unnamed)
	.long	HdaeUiObj_400        ; [400] (unnamed)
	.long	HdaeUiObj_401        ; [401] (unnamed)
	.long	HdaeUiObj_402        ; [402] (unnamed)
	.long	HdaeUiObj_403        ; [403] (unnamed)
	.long	HdaeUiObj_404        ; [404] RAM_EDIT_CMP
	.long	HdaeUiObj_405        ; [405] (unnamed)
	.long	HdaeUiObj_406        ; [406] RAM_EDIT_LSW
	.long	HdaeUiObj_407        ; [407] RAM_EDIT_PMT
	.long	HdaeUiObj_408        ; [408] RAM_EDIT_SQT
	.long	HdaeUiObj_409        ; [409] RAM_EDIT_TM
	.long	HdaeUiObj_410        ; [410] RAM_EDIT_MSP
	.long	HdaeUiObj_411        ; [411] RAM_EDIT_RCM
	.long	HdaeUiObj_412        ; [412] RAM_EDIT_MD
	.long	HdaeUiObj_413        ; [413] (unnamed)
	.long	HdaeUiObj_414        ; [414] (unnamed)
	.long	HdaeUiObj_415        ; [415] (unnamed)
	.long	HdaeUiObj_416        ; [416] (unnamed)
	.long	HdaeUiObj_417        ; [417] (unnamed)
	.long	HdaeUiObj_418        ; [418] (unnamed)
	.long	HdaeUiObj_419        ; [419] (unnamed)
	.long	HdaeUiObj_420        ; [420] (unnamed)
	.long	HdaeUiObj_421        ; [421] (unnamed)
	.long	HdaeUiObj_422        ; [422] (unnamed)
	.long	HdaeUiObj_423        ; [423] (unnamed)
	.long	HdaeUiObj_424        ; [424] (unnamed)
	.long	HdaeUiObj_425        ; [425] (unnamed)
	.long	HdaeUiObj_426        ; [426] RAM_EDIT_TLX
	.long	HdaeUiObj_427        ; [427] (unnamed)
	.long	HdaeUiObj_428        ; [428] (unnamed)
	.long	HdaeUiObj_429        ; [429] (unnamed)
	.long	HdaeUiObj_430        ; [430] HddNamingWindow
	.long	HdaeUiObj_431        ; [431] (unnamed)
	.long	HdaeUiObj_432        ; [432] (unnamed)
	.long	HdaeUiObj_433        ; [433] (unnamed)
	.long	HdaeUiObj_434        ; [434] (unnamed)
	.long	HdaeUiObj_435        ; [435] (unnamed)
	.long	HdaeUiObj_436        ; [436] (unnamed)
	.long	HdaeUiObj_437        ; [437] (unnamed)
	.long	HdaeUiObj_438        ; [438] (unnamed)
	.long	HdaeUiObj_439        ; [439] (unnamed)
	.long	HdaeUiObj_440        ; [440] (unnamed)
	.long	HdaeUiObj_441        ; [441] (unnamed)
	.long	HdaeUiObj_442        ; [442] HddNamingCursorBox
	.long	0x00239E8A        ; [443] HddNamingABC  -- RAM descriptor
	.long	0x00239EB6        ; [444] HddNamingabc  -- RAM descriptor
	.long	0x00239EE2        ; [445] HddNamingSymbol  -- RAM descriptor
	.long	HdaeUiObj_446        ; [446] (unnamed)
	.long	HdaeUiObj_447        ; [447] (unnamed)
	.long	HdaeUiObj_448        ; [448] (unnamed)
	.long	HdaeUiObj_449        ; [449] HddNamingLabel
	.long	HdaeUiObj_450        ; [450] FILE_DEL_SCREEN
	.long	HdaeUiObj_451        ; [451] (unnamed)
	.long	HdaeUiObj_452        ; [452] (unnamed)
	.long	HdaeUiObj_453        ; [453] (unnamed)
	.long	HdaeUiObj_454        ; [454] (unnamed)
	.long	HdaeUiObj_455        ; [455] (unnamed)
	.long	HdaeUiObj_456        ; [456] (unnamed)
	.long	HdaeUiObj_457        ; [457] (unnamed)
	.long	HdaeUiObj_458        ; [458] (unnamed)
	.long	HdaeUiObj_459        ; [459] (unnamed)
	.long	HdaeUiObj_460        ; [460] (unnamed)
	.long	HdaeUiObj_461        ; [461] (unnamed)
	.long	HdaeUiObj_462        ; [462] (unnamed)
	.long	HdaeUiObj_463        ; [463] DEL_EDIT_LSW
	.long	HdaeUiObj_464        ; [464] DEL_EDIT_PMT
	.long	HdaeUiObj_465        ; [465] DEL_EDIT_SQT
	.long	HdaeUiObj_466        ; [466] DEL_EDIT_CMP
	.long	HdaeUiObj_467        ; [467] DEL_EDIT_TM
	.long	HdaeUiObj_468        ; [468] DEL_EDIT_MSP
	.long	HdaeUiObj_469        ; [469] DEL_EDIT_RCM
	.long	HdaeUiObj_470        ; [470] DEL_EDIT_MD
	.long	HdaeUiObj_471        ; [471] (unnamed)
	.long	HdaeUiObj_472        ; [472] (unnamed)
	.long	HdaeUiObj_473        ; [473] (unnamed)
	.long	HdaeUiObj_474        ; [474] (unnamed)
	.long	HdaeUiObj_475        ; [475] (unnamed)
	.long	HdaeUiObj_476        ; [476] (unnamed)
	.long	HdaeUiObj_477        ; [477] (unnamed)
	.long	HdaeUiObj_478        ; [478] (unnamed)
	.long	HdaeUiObj_479        ; [479] (unnamed)
	.long	HdaeUiObj_480        ; [480] (unnamed)
	.long	HdaeUiObj_481        ; [481] (unnamed)
	.long	HdaeUiObj_482        ; [482] (unnamed)
	.long	HdaeUiObj_483        ; [483] (unnamed)
	.long	HdaeUiObj_484        ; [484] (unnamed)
	.long	HdaeUiObj_485        ; [485] (unnamed)
	.long	HdaeUiObj_486        ; [486] (unnamed)
	.long	HdaeUiObj_487        ; [487] (unnamed)
	.long	HdaeUiObj_488        ; [488] (unnamed)
	.long	HdaeUiObj_489        ; [489] DEL_EDIT_TLX
	.long	HdaeUiObj_490        ; [490] (unnamed)
	.long	HdaeUiObj_491        ; [491] (unnamed)
	.long	HdaeUiObj_492        ; [492] HDD_ICON_DISPLAY
	.long	HdaeUiObj_493        ; [493] HD_MENU_BMP
	.long	HdaeUiObj_494        ; [494] IV_HDDMENU
	.long	HdaeUiObj_495        ; [495] ATTEN_DEL_DIR
	.long	HdaeUiObj_496        ; [496] (unnamed)
	.long	HdaeUiObj_497        ; [497] (unnamed)
	.long	HdaeUiObj_498        ; [498] (unnamed)
	.long	HdaeUiObj_499        ; [499] (unnamed)
	.long	HdaeUiObj_500        ; [500] (unnamed)
	.long	HdaeUiObj_501        ; [501] (unnamed)
	.long	HdaeUiObj_502        ; [502] (unnamed)
	.long	HdaeUiObj_503        ; [503] (unnamed)
	.long	HdaeUiObj_504        ; [504] WAIT_DEL_DIR
	.long	HdaeUiObj_505        ; [505] (unnamed)
	.long	HdaeUiObj_506        ; [506] (unnamed)
	.long	HdaeUiObj_507        ; [507] ATTEN_DEL_FILE
	.long	HdaeUiObj_508        ; [508] (unnamed)
	.long	HdaeUiObj_509        ; [509] (unnamed)
	.long	HdaeUiObj_510        ; [510] (unnamed)
	.long	HdaeUiObj_511        ; [511] (unnamed)
	.long	HdaeUiObj_512        ; [512] (unnamed)
	.long	HdaeUiObj_513        ; [513] (unnamed)
	.long	HdaeUiObj_514        ; [514] (unnamed)
	.long	HdaeUiObj_515        ; [515] (unnamed)
	.long	HdaeUiObj_516        ; [516] ATTEN_OVER_FLS
	.long	HdaeUiObj_517        ; [517] (unnamed)
	.long	HdaeUiObj_518        ; [518] (unnamed)
	.long	HdaeUiObj_519        ; [519] (unnamed)
	.long	HdaeUiObj_520        ; [520] (unnamed)
	.long	HdaeUiObj_521        ; [521] (unnamed)
	.long	HdaeUiObj_522        ; [522] (unnamed)
	.long	HdaeUiObj_523        ; [523] (unnamed)
	.long	HdaeUiObj_524        ; [524] (unnamed)
	.long	HdaeUiObj_525        ; [525] ATTEN_DEL_FLS2
	.long	HdaeUiObj_526        ; [526] (unnamed)
	.long	HdaeUiObj_527        ; [527] (unnamed)
	.long	HdaeUiObj_528        ; [528] (unnamed)
	.long	HdaeUiObj_529        ; [529] (unnamed)
	.long	HdaeUiObj_530        ; [530] (unnamed)
	.long	HdaeUiObj_531        ; [531] (unnamed)
	.long	HdaeUiObj_532        ; [532] (unnamed)
	.long	HdaeUiObj_533        ; [533] (unnamed)
	.long	HdaeUiObj_534        ; [534] (unnamed)
	.long	HdaeUiObj_535        ; [535] WAIT_DEL_FILE
	.long	HdaeUiObj_536        ; [536] (unnamed)
	.long	HdaeUiObj_537        ; [537] (unnamed)
	.long	HdaeUiObj_538        ; [538] ATTEN_HD_FORMAT
	.long	HdaeUiObj_539        ; [539] (unnamed)
	.long	HdaeUiObj_540        ; [540] (unnamed)
	.long	HdaeUiObj_541        ; [541] (unnamed)
	.long	HdaeUiObj_542        ; [542] (unnamed)
	.long	HdaeUiObj_543        ; [543] (unnamed)
	.long	HdaeUiObj_544        ; [544] (unnamed)
	.long	HdaeUiObj_545        ; [545] (unnamed)
	.long	HdaeUiObj_546        ; [546] HD_FORMAT_CATCH
	.long	HdaeUiObj_547        ; [547] WAIT_HD_FORMAT
	.long	HdaeUiObj_548        ; [548] (unnamed)
	.long	HdaeUiObj_549        ; [549] (unnamed)
	.long	HdaeUiObj_550        ; [550] (unnamed)
	.long	HdaeUiObj_551        ; [551] SETUP_HDINFO
	.long	HdaeUiObj_552        ; [552] (unnamed)
	.long	HdaeUiObj_553        ; [553] (unnamed)
	.long	HdaeUiObj_554        ; [554] HD_INFO_LIST
	.long	HdaeUiObj_555        ; [555] (unnamed)
	.long	HdaeUiObj_556        ; [556] DBG_MEMO_SCREEN
	.long	HdaeUiObj_557        ; [557] (unnamed)
	.long	HdaeUiObj_558        ; [558] (unnamed)
	.long	HdaeUiObj_559        ; [559] ATTEN_DEL_FLS1
	.long	HdaeUiObj_560        ; [560] (unnamed)
	.long	HdaeUiObj_561        ; [561] (unnamed)
	.long	HdaeUiObj_562        ; [562] (unnamed)
	.long	HdaeUiObj_563        ; [563] (unnamed)
	.long	HdaeUiObj_564        ; [564] (unnamed)
	.long	HdaeUiObj_565        ; [565] (unnamed)
	.long	HdaeUiObj_566        ; [566] (unnamed)
	.long	HdaeUiObj_567        ; [567] (unnamed)
	.long	HdaeUiObj_568        ; [568] (unnamed)
	.long	HdaeUiObj_569        ; [569] (unnamed)
	.long	HdaeUiObj_570        ; [570] (unnamed)
	.long	HdaeUiObj_571        ; [571] ATTEN_OVER_FILE
	.long	HdaeUiObj_572        ; [572] (unnamed)
	.long	HdaeUiObj_573        ; [573] (unnamed)
	.long	HdaeUiObj_574        ; [574] (unnamed)
	.long	HdaeUiObj_575        ; [575] (unnamed)
	.long	HdaeUiObj_576        ; [576] (unnamed)
	.long	HdaeUiObj_577        ; [577] (unnamed)
	.long	HdaeUiObj_578        ; [578] (unnamed)
	.long	HdaeUiObj_579        ; [579] (unnamed)
	.long	HdaeUiObj_580        ; [580] HDD_FLS_NAMING2
	.long	HdaeUiObj_581        ; [581] (unnamed)
	.long	HdaeUiObj_582        ; [582] (unnamed)
	.long	HdaeUiObj_583        ; [583] (unnamed)
	.long	HdaeUiObj_584        ; [584] (unnamed)
	.long	HdaeUiObj_585        ; [585] (unnamed)
	.long	HdaeUiObj_586        ; [586] ATTEN_CPHD_WR
	.long	HdaeUiObj_587        ; [587] (unnamed)
	.long	HdaeUiObj_588        ; [588] (unnamed)
	.long	HdaeUiObj_589        ; [589] (unnamed)
	.long	HdaeUiObj_590        ; [590] (unnamed)
	.long	HdaeUiObj_591        ; [591] (unnamed)
	.long	HdaeUiObj_592        ; [592] (unnamed)
	.long	HdaeUiObj_593        ; [593] (unnamed)
	.long	HdaeUiObj_594        ; [594] ERR_HD_NOT_FMT
	.long	HdaeUiObj_595        ; [595] (unnamed)
	.long	HdaeUiObj_596        ; [596] (unnamed)
	.long	HdaeUiObj_597        ; [597] (unnamed)
	.long	HdaeUiObj_598        ; [598] (unnamed)
	.long	HdaeUiObj_599        ; [599] ERR_HD_SRAM
	.long	HdaeUiObj_600        ; [600] (unnamed)
	.long	HdaeUiObj_601        ; [601] (unnamed)
	.long	HdaeUiObj_602        ; [602] (unnamed)
	.long	HdaeUiObj_603        ; [603] (unnamed)
	.long	HdaeUiObj_604        ; [604] ERR_HD_RESET
	.long	HdaeUiObj_605        ; [605] (unnamed)
	.long	HdaeUiObj_606        ; [606] (unnamed)
	.long	HdaeUiObj_607        ; [607] (unnamed)
	.long	HdaeUiObj_608        ; [608] (unnamed)
	.long	HdaeUiObj_609        ; [609] ERR_HD_READ
	.long	HdaeUiObj_610        ; [610] (unnamed)
	.long	HdaeUiObj_611        ; [611] (unnamed)
	.long	HdaeUiObj_612        ; [612] (unnamed)
	.long	HdaeUiObj_613        ; [613] (unnamed)
	.long	HdaeUiObj_614        ; [614] ERR_HD_ID_READ
	.long	HdaeUiObj_615        ; [615] (unnamed)
	.long	HdaeUiObj_616        ; [616] (unnamed)
	.long	HdaeUiObj_617        ; [617] (unnamed)
	.long	HdaeUiObj_618        ; [618] (unnamed)
	.long	HdaeUiObj_619        ; [619] ERR_HD_TRACK_0
	.long	HdaeUiObj_620        ; [620] (unnamed)
	.long	HdaeUiObj_621        ; [621] (unnamed)
	.long	HdaeUiObj_622        ; [622] (unnamed)
	.long	HdaeUiObj_623        ; [623] (unnamed)
	.long	HdaeUiObj_624        ; [624] ERR_HD_FAT
	.long	HdaeUiObj_625        ; [625] (unnamed)
	.long	HdaeUiObj_626        ; [626] (unnamed)
	.long	HdaeUiObj_627        ; [627] (unnamed)
	.long	HdaeUiObj_628        ; [628] (unnamed)
	.long	HdaeUiObj_629        ; [629] ERR_HD_FSB
	.long	HdaeUiObj_630        ; [630] (unnamed)
	.long	HdaeUiObj_631        ; [631] (unnamed)
	.long	HdaeUiObj_632        ; [632] (unnamed)
	.long	HdaeUiObj_633        ; [633] (unnamed)
	.long	HdaeUiObj_634        ; [634] ATTEN_CPFD_MARK
	.long	HdaeUiObj_635        ; [635] (unnamed)
	.long	HdaeUiObj_636        ; [636] (unnamed)
	.long	HdaeUiObj_637        ; [637] (unnamed)
	.long	HdaeUiObj_638        ; [638] (unnamed)
	.long	HdaeUiObj_639        ; [639] (unnamed)
	.long	HdaeUiObj_640        ; [640] (unnamed)
	.long	HdaeUiObj_641        ; [641] ABOUT_HELP
	.long	HdaeUiObj_642        ; [642] (unnamed)
	.long	HdaeUiObj_643        ; [643] (unnamed)
	.long	HdaeUiObj_644        ; [644] (unnamed)
	.long	HdaeUiObj_645        ; [645] (unnamed)
	.long	HdaeUiObj_646        ; [646] (unnamed)
	.long	HdaeUiObj_647        ; [647] (unnamed)
	.long	HdaeUiObj_648        ; [648] (unnamed)
	.long	HdaeUiObj_649        ; [649] (unnamed)
	.long	HdaeUiObj_650        ; [650] (unnamed)
	.long	HdaeUiObj_651        ; [651] (unnamed)
	.long	HdaeUiObj_652        ; [652] (unnamed)
	.long	HdaeUiObj_653        ; [653] (unnamed)
	.long	HdaeUiObj_654        ; [654] (unnamed)
	.long	HdaeUiObj_655        ; [655] (unnamed)
	.long	HdaeUiObj_656        ; [656] (unnamed)
	.long	HdaeUiObj_657        ; [657] (unnamed)
	.long	HdaeUiObj_658        ; [658] (unnamed)
	.long	HdaeUiObj_659        ; [659] (unnamed)
	.long	HdaeUiObj_660        ; [660] WAIT_TR0_RECOVER
	.long	HdaeUiObj_661        ; [661] (unnamed)
	.long	HdaeUiObj_662        ; [662] (unnamed)
	.long	HdaeUiObj_663        ; [663] ERR_SAVE
	.long	0x00239F0E        ; [664] ERR_SAVE_EXIT  -- RAM descriptor
	.long	HdaeUiObj_665        ; [665] ERR_SAVE_CATCH
	.long	HdaeUiObj_666        ; [666] (unnamed)
	.long	HdaeUiObj_667        ; [667] (unnamed)
	.long	HdaeUiObj_668        ; [668] (unnamed)
	.long	HdaeUiObj_669        ; [669] ERR_LOAD
	.long	0x00239F28        ; [670] ERR_LOAD_EXIT  -- RAM descriptor
	.long	HdaeUiObj_671        ; [671] ERR_LOAD_CATCH
	.long	HdaeUiObj_672        ; [672] (unnamed)
	.long	HdaeUiObj_673        ; [673] (unnamed)
	.long	HdaeUiObj_674        ; [674] (unnamed)
	.long	HdaeUiObj_675        ; [675] ERR_NO_HK_DATA
	.long	HdaeUiObj_676        ; [676] (unnamed)
	.long	HdaeUiObj_677        ; [677] ERR_NO_HK_DATA_CATCH
	.long	HdaeUiObj_678        ; [678] (unnamed)
	.long	HdaeUiObj_679        ; [679] (unnamed)
	.long	HdaeUiObj_680        ; [680] (unnamed)
	.long	HdaeUiObj_681        ; [681] ATTEN_FULL_DIR
	.long	HdaeUiObj_682        ; [682] (unnamed)
	.long	HdaeUiObj_683        ; [683] ATTEN_FULL_DIR_CATCH
	.long	HdaeUiObj_684        ; [684] (unnamed)
	.long	HdaeUiObj_685        ; [685] (unnamed)
	.long	HdaeUiObj_686        ; [686] (unnamed)
	.long	HdaeUiObj_687        ; [687] (unnamed)
	.long	HdaeUiObj_688        ; [688] ATTEN_CP_UNNAMED
	.long	HdaeUiObj_689        ; [689] (unnamed)
	.long	HdaeUiObj_690        ; [690] ATTEN_CP_UNNAMED_CATCH
	.long	HdaeUiObj_691        ; [691] (unnamed)
	.long	HdaeUiObj_692        ; [692] (unnamed)
	.long	HdaeUiObj_693        ; [693] (unnamed)
	.long	HdaeUiObj_694        ; [694] (unnamed)
	.long	HdaeUiObj_695        ; [695] DIR_OUT_RANGE
	.long	HdaeUiObj_696        ; [696] DIR_OUT_RANGE_CATCH
	.long	HdaeUiObj_697        ; [697] (unnamed)
	.long	HdaeUiObj_698        ; [698] (unnamed)
	.long	HdaeUiObj_699        ; [699] (unnamed)
	.long	HdaeUiObj_700        ; [700] FILE_OUT_RANGE
	.long	HdaeUiObj_701        ; [701] FILE_OUT_RANGE_CATCH
	.long	HdaeUiObj_702        ; [702] (unnamed)
	.long	HdaeUiObj_703        ; [703] (unnamed)
	.long	HdaeUiObj_704        ; [704] (unnamed)
	.long	HdaeUiObj_705        ; [705] HD_PLEASE
	.long	HdaeUiObj_706        ; [706] (unnamed)
	.long	HdaeUiObj_707        ; [707] (unnamed)
	.long	HdaeUiObj_708        ; [708] ERR_HD_FORMAT
	.long	HdaeUiObj_709        ; [709] (unnamed)
	.long	HdaeUiObj_710        ; [710] ERR_HD_FORMAT_CATCH
	.long	HdaeUiObj_711        ; [711] (unnamed)
	.long	HdaeUiObj_712        ; [712] (unnamed)
	.long	HdaeUiObj_713        ; [713] (unnamed)
	.long	HdaeUiObj_714        ; [714] (unnamed)
	.long	HdaeUiObj_715        ; [715] AGAIN_HD_FORMAT
	.long	HdaeUiObj_716        ; [716] (unnamed)
	.long	HdaeUiObj_717        ; [717] AGAIN_HD_FORMAT_CATCH
	.long	HdaeUiObj_718        ; [718] (unnamed)
	.long	HdaeUiObj_719        ; [719] (unnamed)
	.long	HdaeUiObj_720        ; [720] (unnamed)
	.long	HdaeUiObj_721        ; [721] (unnamed)
	.long	HdaeUiObj_722        ; [722] SELECT_FILE_A_Z
	.long	HdaeUiObj_723        ; [723] (unnamed)
	.long	HdaeUiObj_724        ; [724] (unnamed)
	.long	HdaeUiObj_725        ; [725] (unnamed)
	.long	HdaeUiObj_726        ; [726] (unnamed)
	.long	HdaeUiObj_727        ; [727] (unnamed)
	.long	HdaeUiObj_728        ; [728] FILE_LOAD_A_Z
	.long	HdaeUiObj_729        ; [729] (unnamed)
	.long	HdaeUiObj_730        ; [730] (unnamed)
	.long	HdaeUiObj_731        ; [731] (unnamed)
	.long	HdaeUiObj_732        ; [732] (unnamed)
	.long	HdaeUiObj_733        ; [733] (unnamed)
	.long	HdaeUiObj_734        ; [734] (unnamed)
	.long	HdaeUiObj_735        ; [735] (unnamed)
	.long	HdaeUiObj_736        ; [736] (unnamed)
	.long	HdaeUiObj_737        ; [737] (unnamed)
	.long	HdaeUiObj_738        ; [738] (unnamed)
	.long	HdaeUiObj_739        ; [739] (unnamed)
	.long	HdaeUiObj_740        ; [740] (unnamed)
	.long	HdaeUiObj_741        ; [741] (unnamed)
	.long	HdaeUiObj_742        ; [742] (unnamed)
	.long	HdaeUiObj_743        ; [743] (unnamed)
	.long	HdaeUiObj_744        ; [744] (unnamed)
	.long	HdaeUiObj_745        ; [745] (unnamed)
	.long	HdaeUiObj_746        ; [746] (unnamed)
	.long	HdaeUiObj_747        ; [747] (unnamed)
	.long	HdaeUiObj_748        ; [748] (unnamed)
	.long	HdaeUiObj_749        ; [749] (unnamed)
	.long	HdaeUiObj_750        ; [750] (unnamed)
	.long	HdaeUiObj_751        ; [751] (unnamed)
	.long	HdaeUiObj_752        ; [752] Tech_lyrics
	.long	HdaeUiObj_753        ; [753] (unnamed)
	.long	HdaeUiObj_754        ; [754] (unnamed)
	.long	HdaeUiObj_755        ; [755] SongTitle
	.long	HdaeUiObj_756        ; [756] (unnamed)
	.long	HdaeUiObj_757        ; [757] Conductor
	.long	HdaeUiObj_758        ; [758] bottom01
	.long	HdaeUiObj_759        ; [759] bottom02
	.long	HdaeUiObj_760        ; [760] bottom03
	.long	HdaeUiObj_761        ; [761] bottom04
	.long	HdaeUiObj_762        ; [762] bottom05
	.long	HdaeUiObj_763        ; [763] bottom06
	.long	HdaeUiObj_764        ; [764] bottom07
	.long	HdaeUiObj_765        ; [765] bottom08
	.long	HdaeUiObj_766        ; [766] (unnamed)
	.long	0x00239F42        ; [767] ChordinLyric  -- RAM descriptor
	.long	0x00239F66        ; [768] TempoinLyric  -- RAM descriptor
	.long	0x00239F8A        ; [769] MeasureinLyric  -- RAM descriptor
	.long	0x00239FAE        ; [770] TimeSigInLyric  -- RAM descriptor
	.long	HdaeUiObj_771        ; [771] (unnamed)
	.long	HdaeUiObj_772        ; [772] LoadLyricFD
	.long	HdaeUiObj_773        ; [773] (unnamed)
	.long	HdaeUiObj_774        ; [774] (unnamed)
	.long	HdaeUiObj_775        ; [775] (unnamed)
	.long	HdaeUiObj_776        ; [776] (unnamed)
	.long	HdaeUiObj_777        ; [777] FD_PLEASE
	.long	HdaeUiObj_778        ; [778] (unnamed)
	.long	HdaeUiObj_779        ; [779] (unnamed)
	.long	HdaeUiObj_780        ; [780] LyrSettings
	.long	HdaeUiObj_781        ; [781] (unnamed)
	.long	HdaeUiObj_782        ; [782] (unnamed)
	.long	HdaeUiObj_783        ; [783] (unnamed)
	.long	HdaeUiObj_784        ; [784] (unnamed)
	.long	HdaeUiObj_785        ; [785] (unnamed)
	.long	HdaeUiObj_786        ; [786] (unnamed)
	.long	HdaeUiObj_787        ; [787] (unnamed)
	.long	HdaeUiObj_788        ; [788] WriteIn
	.long	0x00000000        ; [789] end-of-table marker


;
; UI object ids: the main CPU knows each HD-AE5000 UI object as 0x007F0000 + n,
; n = its index in HDAE5000_UiObject_PtrTable.  One constant per object that
; HDAE5000_UiObjectName_PtrTable names (178 of them), named after that string;
; generated from the table rows by scripts/converters/hdae5000_symbolize_ui_objects.py.
;
	.equ HDAE5000_OBJ_HDDMENU, 0x007f0000
	.equ HDAE5000_OBJ_HARD_DISK_OPT, 0x007f000a
	.equ HDAE5000_OBJ_SETUPS_TOOLS, 0x007f0013
	.equ HDAE5000_OBJ_SELECT_FILE, 0x007f0018
	.equ HDAE5000_OBJ_HD_FILE_LOAD, 0x007f001a
	.equ HDAE5000_OBJ_HD_LOAD_OPTION, 0x007f001b
	.equ HDAE5000_OBJ_SELECT_DIR, 0x007f0022
	.equ HDAE5000_OBJ_SEL_DIR, 0x007f0025
	.equ HDAE5000_OBJ_SELECT_DIR_SW_EDIT, 0x007f002c
	.equ HDAE5000_OBJ_SELECT_DIR2, 0x007f0031
	.equ HDAE5000_OBJ_FD_FILE_SELECT, 0x007f003a
	.equ HDAE5000_OBJ_HARD_TEST, 0x007f0045
	.equ HDAE5000_OBJ_RUN_STOP, 0x007f0049
	.equ HDAE5000_OBJ_PPORT_SW, 0x007f004b
	.equ HDAE5000_OBJ_FD_SW, 0x007f004c
	.equ HDAE5000_OBJ_HDD_SW, 0x007f004d
	.equ HDAE5000_OBJ_HDD_FILE_NAMING, 0x007f004e
	.equ HDAE5000_OBJ_HD_FILE_NAME, 0x007f0057
	.equ HDAE5000_OBJ_HDD_DIR_NAMING, 0x007f0058
	.equ HDAE5000_OBJ_HD_PLEASE_WIN, 0x007f005e
	.equ HDAE5000_OBJ_HD_UTIL, 0x007f0060
	.equ HDAE5000_OBJ_PC_DATA_LINK, 0x007f0066
	.equ HDAE5000_OBJ_PP_STATUS, 0x007f0068
	.equ HDAE5000_OBJ_SETUP_TOOLS_P1, 0x007f006e
	.equ HDAE5000_OBJ_SETUP_TOOLS_P2, 0x007f007a
	.equ HDAE5000_OBJ_SW_HD_FORMAT, 0x007f0080
	.equ HDAE5000_OBJ_OUTPUT_SETTING, 0x007f0085
	.equ HDAE5000_OBJ_LOAD_BY_NUM, 0x007f008f
	.equ HDAE5000_OBJ_LBN_P1, 0x007f0095
	.equ HDAE5000_OBJ_LBN_OPTION, 0x007f0098
	.equ HDAE5000_OBJ_LBN_DIRNO_BOX, 0x007f00a8
	.equ HDAE5000_OBJ_LBN_DIRNAME_BOX, 0x007f00a9
	.equ HDAE5000_OBJ_LBN_FILENO_BOX, 0x007f00aa
	.equ HDAE5000_OBJ_LBN_FILENAME_BOX, 0x007f00ab
	.equ HDAE5000_OBJ_LBN_P2, 0x007f00af
	.equ HDAE5000_OBJ_CP_FD, 0x007f00d2
	.equ HDAE5000_OBJ_CP_FD_LIST, 0x007f00d7
	.equ HDAE5000_OBJ_CP_FD_LINE2, 0x007f00d8
	.equ HDAE5000_OBJ_CP_FD_LINE1, 0x007f00d9
	.equ HDAE5000_OBJ_CP_FD_HDSWTO, 0x007f00da
	.equ HDAE5000_OBJ_CP_FD_HDSWSEL, 0x007f00dc
	.equ HDAE5000_OBJ_CP_FD_VOLLABEL, 0x007f00de
	.equ HDAE5000_OBJ_CP_FD_HDALLSEL, 0x007f00e0
	.equ HDAE5000_OBJ_CP_FD_DIRSEL, 0x007f00e2
	.equ HDAE5000_OBJ_CP_FD_DIRBOX, 0x007f00e6
	.equ HDAE5000_OBJ_FLS_SELECT, 0x007f00f0
	.equ HDAE5000_OBJ_FLS_SEL, 0x007f00f8
	.equ HDAE5000_OBJ_FLS_SELECT_SW_EDIT, 0x007f00f9
	.equ HDAE5000_OBJ_SEL_FLS, 0x007f00fb
	.equ HDAE5000_OBJ_HD_FILE_LOAD_P1, 0x007f00ff
	.equ HDAE5000_OBJ_HD_FILE_LOAD_SW_SAVE, 0x007f0100
	.equ HDAE5000_OBJ_HD_FILE_OPTION, 0x007f0102
	.equ HDAE5000_OBJ_HD_FILE_LIST, 0x007f0103
	.equ HDAE5000_OBJ_FILE_LOAD_DIRBOX, 0x007f0104
	.equ HDAE5000_OBJ_HD_FILE_LOAD_SW_DEL, 0x007f010a
	.equ HDAE5000_OBJ_HD_FILE_LOAD_SW_DELFILE, 0x007f010d
	.equ HDAE5000_OBJ_HD_FILE_LOAD_P2, 0x007f0110
	.equ HDAE5000_OBJ_HDD_FLS_NAMING, 0x007f0134
	.equ HDAE5000_OBJ_FLS_FILE_LOAD, 0x007f013a
	.equ HDAE5000_OBJ_FLS_FILE_LOAD_SW_EDIT, 0x007f013e
	.equ HDAE5000_OBJ_FLS_OPT_BOX, 0x007f0143
	.equ HDAE5000_OBJ_FLS_LOC_BOX, 0x007f0144
	.equ HDAE5000_OBJ_FLS_NAME_BOX, 0x007f0145
	.equ HDAE5000_OBJ_FLS_FILE_BOX, 0x007f0148
	.equ HDAE5000_OBJ_FLS_LOAD_LINE1, 0x007f0149
	.equ HDAE5000_OBJ_FLS_LOAD_LINE2, 0x007f014a
	.equ HDAE5000_OBJ_FLS_DIR_SEL, 0x007f014e
	.equ HDAE5000_OBJ_FLS_DIR_BOX, 0x007f0151
	.equ HDAE5000_OBJ_FLS_FILE_SEL, 0x007f0159
	.equ HDAE5000_OBJ_FLS_FILE_SEL_DIRBOX, 0x007f015b
	.equ HDAE5000_OBJ_FLS_FILE_SEL_LISTBOX, 0x007f015c
	.equ HDAE5000_OBJ_FLS_FILE_SEL_OPTBOX, 0x007f0160
	.equ HDAE5000_OBJ_FLS_EDIT, 0x007f0163
	.equ HDAE5000_OBJ_FLS_EDIT_NAME_BOX, 0x007f0166
	.equ HDAE5000_OBJ_FLS_EDIT_LIST_BOX, 0x007f0169
	.equ HDAE5000_OBJ_FLS_EDIT_LINE2, 0x007f016a
	.equ HDAE5000_OBJ_FLS_EDIT_LINE1, 0x007f016b
	.equ HDAE5000_OBJ_FLS_EDIT_LOC_BOX, 0x007f0176
	.equ HDAE5000_OBJ_FLS_EDIT_OPT_BOX, 0x007f0177
	.equ HDAE5000_OBJ_CP_FD_DIR_NAMING, 0x007f017b
	.equ HDAE5000_OBJ_SAVE_OPT_SCREEN, 0x007f0182
	.equ HDAE5000_OBJ_RAM_EDIT_CMP, 0x007f0194
	.equ HDAE5000_OBJ_RAM_EDIT_LSW, 0x007f0196
	.equ HDAE5000_OBJ_RAM_EDIT_PMT, 0x007f0197
	.equ HDAE5000_OBJ_RAM_EDIT_SQT, 0x007f0198
	.equ HDAE5000_OBJ_RAM_EDIT_TM, 0x007f0199
	.equ HDAE5000_OBJ_RAM_EDIT_MSP, 0x007f019a
	.equ HDAE5000_OBJ_RAM_EDIT_RCM, 0x007f019b
	.equ HDAE5000_OBJ_RAM_EDIT_MD, 0x007f019c
	.equ HDAE5000_OBJ_RAM_EDIT_TLX, 0x007f01aa
	.equ HDAE5000_OBJ_HddNamingWindow, 0x007f01ae
	.equ HDAE5000_OBJ_HddNamingCursorBox, 0x007f01ba
	.equ HDAE5000_OBJ_HddNamingABC, 0x007f01bb
	.equ HDAE5000_OBJ_HddNamingabc, 0x007f01bc
	.equ HDAE5000_OBJ_HddNamingSymbol, 0x007f01bd
	.equ HDAE5000_OBJ_HddNamingLabel, 0x007f01c1
	.equ HDAE5000_OBJ_FILE_DEL_SCREEN, 0x007f01c2
	.equ HDAE5000_OBJ_DEL_EDIT_LSW, 0x007f01cf
	.equ HDAE5000_OBJ_DEL_EDIT_PMT, 0x007f01d0
	.equ HDAE5000_OBJ_DEL_EDIT_SQT, 0x007f01d1
	.equ HDAE5000_OBJ_DEL_EDIT_CMP, 0x007f01d2
	.equ HDAE5000_OBJ_DEL_EDIT_TM, 0x007f01d3
	.equ HDAE5000_OBJ_DEL_EDIT_MSP, 0x007f01d4
	.equ HDAE5000_OBJ_DEL_EDIT_RCM, 0x007f01d5
	.equ HDAE5000_OBJ_DEL_EDIT_MD, 0x007f01d6
	.equ HDAE5000_OBJ_DEL_EDIT_TLX, 0x007f01e9
	.equ HDAE5000_OBJ_HDD_ICON_DISPLAY, 0x007f01ec
	.equ HDAE5000_OBJ_HD_MENU_BMP, 0x007f01ed
	.equ HDAE5000_OBJ_IV_HDDMENU, 0x007f01ee
	.equ HDAE5000_OBJ_ATTEN_DEL_DIR, 0x007f01ef
	.equ HDAE5000_OBJ_WAIT_DEL_DIR, 0x007f01f8
	.equ HDAE5000_OBJ_ATTEN_DEL_FILE, 0x007f01fb
	.equ HDAE5000_OBJ_ATTEN_OVER_FLS, 0x007f0204
	.equ HDAE5000_OBJ_ATTEN_DEL_FLS2, 0x007f020d
	.equ HDAE5000_OBJ_WAIT_DEL_FILE, 0x007f0217
	.equ HDAE5000_OBJ_ATTEN_HD_FORMAT, 0x007f021a
	.equ HDAE5000_OBJ_HD_FORMAT_CATCH, 0x007f0222
	.equ HDAE5000_OBJ_WAIT_HD_FORMAT, 0x007f0223
	.equ HDAE5000_OBJ_SETUP_HDINFO, 0x007f0227
	.equ HDAE5000_OBJ_HD_INFO_LIST, 0x007f022a
	.equ HDAE5000_OBJ_DBG_MEMO_SCREEN, 0x007f022c
	.equ HDAE5000_OBJ_ATTEN_DEL_FLS1, 0x007f022f
	.equ HDAE5000_OBJ_ATTEN_OVER_FILE, 0x007f023b
	.equ HDAE5000_OBJ_HDD_FLS_NAMING2, 0x007f0244
	.equ HDAE5000_OBJ_ATTEN_CPHD_WR, 0x007f024a
	.equ HDAE5000_OBJ_ERR_HD_NOT_FMT, 0x007f0252
	.equ HDAE5000_OBJ_ERR_HD_SRAM, 0x007f0257
	.equ HDAE5000_OBJ_ERR_HD_RESET, 0x007f025c
	.equ HDAE5000_OBJ_ERR_HD_READ, 0x007f0261
	.equ HDAE5000_OBJ_ERR_HD_ID_READ, 0x007f0266
	.equ HDAE5000_OBJ_ERR_HD_TRACK_0, 0x007f026b
	.equ HDAE5000_OBJ_ERR_HD_FAT, 0x007f0270
	.equ HDAE5000_OBJ_ERR_HD_FSB, 0x007f0275
	.equ HDAE5000_OBJ_ATTEN_CPFD_MARK, 0x007f027a
	.equ HDAE5000_OBJ_ABOUT_HELP, 0x007f0281
	.equ HDAE5000_OBJ_WAIT_TR0_RECOVER, 0x007f0294
	.equ HDAE5000_OBJ_ERR_SAVE, 0x007f0297
	.equ HDAE5000_OBJ_ERR_SAVE_EXIT, 0x007f0298
	.equ HDAE5000_OBJ_ERR_SAVE_CATCH, 0x007f0299
	.equ HDAE5000_OBJ_ERR_LOAD, 0x007f029d
	.equ HDAE5000_OBJ_ERR_LOAD_EXIT, 0x007f029e
	.equ HDAE5000_OBJ_ERR_LOAD_CATCH, 0x007f029f
	.equ HDAE5000_OBJ_ERR_NO_HK_DATA, 0x007f02a3
	.equ HDAE5000_OBJ_ERR_NO_HK_DATA_CATCH, 0x007f02a5
	.equ HDAE5000_OBJ_ATTEN_FULL_DIR, 0x007f02a9
	.equ HDAE5000_OBJ_ATTEN_FULL_DIR_CATCH, 0x007f02ab
	.equ HDAE5000_OBJ_ATTEN_CP_UNNAMED, 0x007f02b0
	.equ HDAE5000_OBJ_ATTEN_CP_UNNAMED_CATCH, 0x007f02b2
	.equ HDAE5000_OBJ_DIR_OUT_RANGE, 0x007f02b7
	.equ HDAE5000_OBJ_DIR_OUT_RANGE_CATCH, 0x007f02b8
	.equ HDAE5000_OBJ_FILE_OUT_RANGE, 0x007f02bc
	.equ HDAE5000_OBJ_FILE_OUT_RANGE_CATCH, 0x007f02bd
	.equ HDAE5000_OBJ_HD_PLEASE, 0x007f02c1
	.equ HDAE5000_OBJ_ERR_HD_FORMAT, 0x007f02c4
	.equ HDAE5000_OBJ_ERR_HD_FORMAT_CATCH, 0x007f02c6
	.equ HDAE5000_OBJ_AGAIN_HD_FORMAT, 0x007f02cb
	.equ HDAE5000_OBJ_AGAIN_HD_FORMAT_CATCH, 0x007f02cd
	.equ HDAE5000_OBJ_SELECT_FILE_A_Z, 0x007f02d2
	.equ HDAE5000_OBJ_FILE_LOAD_A_Z, 0x007f02d8
	.equ HDAE5000_OBJ_Tech_lyrics, 0x007f02f0
	.equ HDAE5000_OBJ_SongTitle, 0x007f02f3
	.equ HDAE5000_OBJ_Conductor, 0x007f02f5
	.equ HDAE5000_OBJ_bottom01, 0x007f02f6
	.equ HDAE5000_OBJ_bottom02, 0x007f02f7
	.equ HDAE5000_OBJ_bottom03, 0x007f02f8
	.equ HDAE5000_OBJ_bottom04, 0x007f02f9
	.equ HDAE5000_OBJ_bottom05, 0x007f02fa
	.equ HDAE5000_OBJ_bottom06, 0x007f02fb
	.equ HDAE5000_OBJ_bottom07, 0x007f02fc
	.equ HDAE5000_OBJ_bottom08, 0x007f02fd
	.equ HDAE5000_OBJ_ChordinLyric, 0x007f02ff
	.equ HDAE5000_OBJ_TempoinLyric, 0x007f0300
	.equ HDAE5000_OBJ_MeasureinLyric, 0x007f0301
	.equ HDAE5000_OBJ_TimeSigInLyric, 0x007f0302
	.equ HDAE5000_OBJ_LoadLyricFD, 0x007f0304
	.equ HDAE5000_OBJ_FD_PLEASE, 0x007f0309
	.equ HDAE5000_OBJ_LyrSettings, 0x007f030c
	.equ HDAE5000_OBJ_WriteIn, 0x007f0314

; =============================================================================
; HD-AE5000 UI OBJECT NAME TABLE (0x2A6984 - 0x2A75DB)
; =============================================================================
; 790 .long pointers into HDAE5000_UiObjectName_Pool below - the symbolic name
; of every UI object in HDAE5000_UiObject_PtrTable, same index.  Registered by
; HDAE5000_Handler_Registration (hd-ae5000_v2_06i.s) as object table 0x37F,
; class id 0x0160000F, proc RootFn_ResNameProc, entry count 0x315 = 789,
; table pointer 0x2A6984.
;
; 178 of the 789 objects carry a name; the remaining 611 point at an empty
; string, as does the 790th slot that pairs with the NULL table terminator.
; The names are the developer's resource identifiers, not user-visible text:
; screens (HDDMENU, HARD_DISK_OPT, SETUPS_TOOLS, PC_DATA_LINK, HARD_TEST),
; dialogs (ERR_*, ATTEN_*, WAIT_*, AGAIN_*, *_CATCH, *_EXIT), widgets
; (FLS_EDIT_NAME_BOX, LBN_DIRNO_BOX, HddNamingCursorBox, bottom01..bottom08)
; and the Technics-Lyrics objects (SongTitle, Conductor, Tech_lyrics,
; TempoinLyric, ChordinLyric).  They are the only surviving trace of the
; original HD-AE5000 UI sources.
;
; Was disassembled as instructions under HDAE5000_GFX_DATA_2 ("graphics data
; block 2"); the pool behind it produced the runs of "nop" (its 0x00 padding)
; and operands such as "ld xiy,0x5443454c" (ASCII "LECT").
; =============================================================================

HDAE5000_UiObjectName_PtrTable:	; 0x2A6984
	.long	HdaeUiName_000                    ; [  0] "HDDMENU"
	.long	HdaeUiName_001                    ; [  1] (unnamed)
	.long	HdaeUiName_002                    ; [  2] (unnamed)
	.long	HdaeUiName_003                    ; [  3] (unnamed)
	.long	HdaeUiName_004                    ; [  4] (unnamed)
	.long	HdaeUiName_005                    ; [  5] (unnamed)
	.long	HdaeUiName_006                    ; [  6] (unnamed)
	.long	HdaeUiName_007                    ; [  7] (unnamed)
	.long	HdaeUiName_008                    ; [  8] (unnamed)
	.long	HdaeUiName_009                    ; [  9] (unnamed)
	.long	HdaeUiName_010                    ; [ 10] "HARD_DISK_OPT"
	.long	HdaeUiName_011                    ; [ 11] (unnamed)
	.long	HdaeUiName_012                    ; [ 12] (unnamed)
	.long	HdaeUiName_013                    ; [ 13] (unnamed)
	.long	HdaeUiName_014                    ; [ 14] (unnamed)
	.long	HdaeUiName_015                    ; [ 15] (unnamed)
	.long	HdaeUiName_016                    ; [ 16] (unnamed)
	.long	HdaeUiName_017                    ; [ 17] (unnamed)
	.long	HdaeUiName_018                    ; [ 18] (unnamed)
	.long	HdaeUiName_019                    ; [ 19] "SETUPS_TOOLS"
	.long	HdaeUiName_020                    ; [ 20] (unnamed)
	.long	HdaeUiName_021                    ; [ 21] (unnamed)
	.long	HdaeUiName_022                    ; [ 22] (unnamed)
	.long	HdaeUiName_023                    ; [ 23] (unnamed)
	.long	HdaeUiName_024                    ; [ 24] "SELECT_FILE"
	.long	HdaeUiName_025                    ; [ 25] (unnamed)
	.long	HdaeUiName_026                    ; [ 26] "HD_FILE_LOAD"
	.long	HdaeUiName_027                    ; [ 27] "HD_LOAD_OPTION"
	.long	HdaeUiName_028                    ; [ 28] (unnamed)
	.long	HdaeUiName_029                    ; [ 29] (unnamed)
	.long	HdaeUiName_030                    ; [ 30] (unnamed)
	.long	HdaeUiName_031                    ; [ 31] (unnamed)
	.long	HdaeUiName_032                    ; [ 32] (unnamed)
	.long	HdaeUiName_033                    ; [ 33] (unnamed)
	.long	HdaeUiName_034                    ; [ 34] "SELECT_DIR"
	.long	HdaeUiName_035                    ; [ 35] (unnamed)
	.long	HdaeUiName_036                    ; [ 36] (unnamed)
	.long	HdaeUiName_037                    ; [ 37] "SEL_DIR"
	.long	HdaeUiName_038                    ; [ 38] (unnamed)
	.long	HdaeUiName_039                    ; [ 39] (unnamed)
	.long	HdaeUiName_040                    ; [ 40] (unnamed)
	.long	HdaeUiName_041                    ; [ 41] (unnamed)
	.long	HdaeUiName_042                    ; [ 42] (unnamed)
	.long	HdaeUiName_043                    ; [ 43] (unnamed)
	.long	HdaeUiName_044                    ; [ 44] "SELECT_DIR_SW_EDIT"
	.long	HdaeUiName_045                    ; [ 45] (unnamed)
	.long	HdaeUiName_046                    ; [ 46] (unnamed)
	.long	HdaeUiName_047                    ; [ 47] (unnamed)
	.long	HdaeUiName_048                    ; [ 48] (unnamed)
	.long	HdaeUiName_049                    ; [ 49] "SELECT_DIR2"
	.long	HdaeUiName_050                    ; [ 50] (unnamed)
	.long	HdaeUiName_051                    ; [ 51] (unnamed)
	.long	HdaeUiName_052                    ; [ 52] (unnamed)
	.long	HdaeUiName_053                    ; [ 53] (unnamed)
	.long	HdaeUiName_054                    ; [ 54] (unnamed)
	.long	HdaeUiName_055                    ; [ 55] (unnamed)
	.long	HdaeUiName_056                    ; [ 56] (unnamed)
	.long	HdaeUiName_057                    ; [ 57] (unnamed)
	.long	HdaeUiName_058                    ; [ 58] "FD_FILE_SELECT"
	.long	HdaeUiName_059                    ; [ 59] (unnamed)
	.long	HdaeUiName_060                    ; [ 60] (unnamed)
	.long	HdaeUiName_061                    ; [ 61] (unnamed)
	.long	HdaeUiName_062                    ; [ 62] (unnamed)
	.long	HdaeUiName_063                    ; [ 63] (unnamed)
	.long	HdaeUiName_064                    ; [ 64] (unnamed)
	.long	HdaeUiName_065                    ; [ 65] (unnamed)
	.long	HdaeUiName_066                    ; [ 66] (unnamed)
	.long	HdaeUiName_067                    ; [ 67] (unnamed)
	.long	HdaeUiName_068                    ; [ 68] (unnamed)
	.long	HdaeUiName_069                    ; [ 69] "HARD_TEST"
	.long	HdaeUiName_070                    ; [ 70] (unnamed)
	.long	HdaeUiName_071                    ; [ 71] (unnamed)
	.long	HdaeUiName_072                    ; [ 72] (unnamed)
	.long	HdaeUiName_073                    ; [ 73] "RUN_STOP"
	.long	HdaeUiName_074                    ; [ 74] (unnamed)
	.long	HdaeUiName_075                    ; [ 75] "PPORT_SW"
	.long	HdaeUiName_076                    ; [ 76] "FD_SW"
	.long	HdaeUiName_077                    ; [ 77] "HDD_SW"
	.long	HdaeUiName_078                    ; [ 78] "HDD_FILE_NAMING"
	.long	HdaeUiName_079                    ; [ 79] (unnamed)
	.long	HdaeUiName_080                    ; [ 80] (unnamed)
	.long	HdaeUiName_081                    ; [ 81] (unnamed)
	.long	HdaeUiName_082                    ; [ 82] (unnamed)
	.long	HdaeUiName_083                    ; [ 83] (unnamed)
	.long	HdaeUiName_084                    ; [ 84] (unnamed)
	.long	HdaeUiName_085                    ; [ 85] (unnamed)
	.long	HdaeUiName_086                    ; [ 86] (unnamed)
	.long	HdaeUiName_087                    ; [ 87] "HD_FILE_NAME"
	.long	HdaeUiName_088                    ; [ 88] "HDD_DIR_NAMING"
	.long	HdaeUiName_089                    ; [ 89] (unnamed)
	.long	HdaeUiName_090                    ; [ 90] (unnamed)
	.long	HdaeUiName_091                    ; [ 91] (unnamed)
	.long	HdaeUiName_092                    ; [ 92] (unnamed)
	.long	HdaeUiName_093                    ; [ 93] (unnamed)
	.long	HdaeUiName_094                    ; [ 94] "HD_PLEASE_WIN"
	.long	HdaeUiName_095                    ; [ 95] (unnamed)
	.long	HdaeUiName_096                    ; [ 96] "HD_UTIL"
	.long	HdaeUiName_097                    ; [ 97] (unnamed)
	.long	HdaeUiName_098                    ; [ 98] (unnamed)
	.long	HdaeUiName_099                    ; [ 99] (unnamed)
	.long	HdaeUiName_100                    ; [100] (unnamed)
	.long	HdaeUiName_101                    ; [101] (unnamed)
	.long	HdaeUiName_102                    ; [102] "PC_DATA_LINK"
	.long	HdaeUiName_103                    ; [103] (unnamed)
	.long	HdaeUiName_104                    ; [104] "PP_STATUS"
	.long	HdaeUiName_105                    ; [105] (unnamed)
	.long	HdaeUiName_106                    ; [106] (unnamed)
	.long	HdaeUiName_107                    ; [107] (unnamed)
	.long	HdaeUiName_108                    ; [108] (unnamed)
	.long	HdaeUiName_109                    ; [109] (unnamed)
	.long	HdaeUiName_110                    ; [110] "SETUP_TOOLS_P1"
	.long	HdaeUiName_111                    ; [111] (unnamed)
	.long	HdaeUiName_112                    ; [112] (unnamed)
	.long	HdaeUiName_113                    ; [113] (unnamed)
	.long	HdaeUiName_114                    ; [114] (unnamed)
	.long	HdaeUiName_115                    ; [115] (unnamed)
	.long	HdaeUiName_116                    ; [116] (unnamed)
	.long	HdaeUiName_117                    ; [117] (unnamed)
	.long	HdaeUiName_118                    ; [118] (unnamed)
	.long	HdaeUiName_119                    ; [119] (unnamed)
	.long	HdaeUiName_120                    ; [120] (unnamed)
	.long	HdaeUiName_121                    ; [121] (unnamed)
	.long	HdaeUiName_122                    ; [122] "SETUP_TOOLS_P2"
	.long	HdaeUiName_123                    ; [123] (unnamed)
	.long	HdaeUiName_124                    ; [124] (unnamed)
	.long	HdaeUiName_125                    ; [125] (unnamed)
	.long	HdaeUiName_126                    ; [126] (unnamed)
	.long	HdaeUiName_127                    ; [127] (unnamed)
	.long	HdaeUiName_128                    ; [128] "SW_HD_FORMAT"
	.long	HdaeUiName_129                    ; [129] (unnamed)
	.long	HdaeUiName_130                    ; [130] (unnamed)
	.long	HdaeUiName_131                    ; [131] (unnamed)
	.long	HdaeUiName_132                    ; [132] (unnamed)
	.long	HdaeUiName_133                    ; [133] "OUTPUT_SETTING"
	.long	HdaeUiName_134                    ; [134] (unnamed)
	.long	HdaeUiName_135                    ; [135] (unnamed)
	.long	HdaeUiName_136                    ; [136] (unnamed)
	.long	HdaeUiName_137                    ; [137] (unnamed)
	.long	HdaeUiName_138                    ; [138] (unnamed)
	.long	HdaeUiName_139                    ; [139] (unnamed)
	.long	HdaeUiName_140                    ; [140] (unnamed)
	.long	HdaeUiName_141                    ; [141] (unnamed)
	.long	HdaeUiName_142                    ; [142] (unnamed)
	.long	HdaeUiName_143                    ; [143] "LOAD_BY_NUM"
	.long	HdaeUiName_144                    ; [144] (unnamed)
	.long	HdaeUiName_145                    ; [145] (unnamed)
	.long	HdaeUiName_146                    ; [146] (unnamed)
	.long	HdaeUiName_147                    ; [147] (unnamed)
	.long	HdaeUiName_148                    ; [148] (unnamed)
	.long	HdaeUiName_149                    ; [149] "LBN_P1"
	.long	HdaeUiName_150                    ; [150] (unnamed)
	.long	HdaeUiName_151                    ; [151] (unnamed)
	.long	HdaeUiName_152                    ; [152] "LBN_OPTION"
	.long	HdaeUiName_153                    ; [153] (unnamed)
	.long	HdaeUiName_154                    ; [154] (unnamed)
	.long	HdaeUiName_155                    ; [155] (unnamed)
	.long	HdaeUiName_156                    ; [156] (unnamed)
	.long	HdaeUiName_157                    ; [157] (unnamed)
	.long	HdaeUiName_158                    ; [158] (unnamed)
	.long	HdaeUiName_159                    ; [159] (unnamed)
	.long	HdaeUiName_160                    ; [160] (unnamed)
	.long	HdaeUiName_161                    ; [161] (unnamed)
	.long	HdaeUiName_162                    ; [162] (unnamed)
	.long	HdaeUiName_163                    ; [163] (unnamed)
	.long	HdaeUiName_164                    ; [164] (unnamed)
	.long	HdaeUiName_165                    ; [165] (unnamed)
	.long	HdaeUiName_166                    ; [166] (unnamed)
	.long	HdaeUiName_167                    ; [167] (unnamed)
	.long	HdaeUiName_168                    ; [168] "LBN_DIRNO_BOX"
	.long	HdaeUiName_169                    ; [169] "LBN_DIRNAME_BOX"
	.long	HdaeUiName_170                    ; [170] "LBN_FILENO_BOX"
	.long	HdaeUiName_171                    ; [171] "LBN_FILENAME_BOX"
	.long	HdaeUiName_172                    ; [172] (unnamed)
	.long	HdaeUiName_173                    ; [173] (unnamed)
	.long	HdaeUiName_174                    ; [174] (unnamed)
	.long	HdaeUiName_175                    ; [175] "LBN_P2"
	.long	HdaeUiName_176                    ; [176] (unnamed)
	.long	HdaeUiName_177                    ; [177] (unnamed)
	.long	HdaeUiName_178                    ; [178] (unnamed)
	.long	HdaeUiName_179                    ; [179] (unnamed)
	.long	HdaeUiName_180                    ; [180] (unnamed)
	.long	HdaeUiName_181                    ; [181] (unnamed)
	.long	HdaeUiName_182                    ; [182] (unnamed)
	.long	HdaeUiName_183                    ; [183] (unnamed)
	.long	HdaeUiName_184                    ; [184] (unnamed)
	.long	HdaeUiName_185                    ; [185] (unnamed)
	.long	HdaeUiName_186                    ; [186] (unnamed)
	.long	HdaeUiName_187                    ; [187] (unnamed)
	.long	HdaeUiName_188                    ; [188] (unnamed)
	.long	HdaeUiName_189                    ; [189] (unnamed)
	.long	HdaeUiName_190                    ; [190] (unnamed)
	.long	HdaeUiName_191                    ; [191] (unnamed)
	.long	HdaeUiName_192                    ; [192] (unnamed)
	.long	HdaeUiName_193                    ; [193] (unnamed)
	.long	HdaeUiName_194                    ; [194] (unnamed)
	.long	HdaeUiName_195                    ; [195] (unnamed)
	.long	HdaeUiName_196                    ; [196] (unnamed)
	.long	HdaeUiName_197                    ; [197] (unnamed)
	.long	HdaeUiName_198                    ; [198] (unnamed)
	.long	HdaeUiName_199                    ; [199] (unnamed)
	.long	HdaeUiName_200                    ; [200] (unnamed)
	.long	HdaeUiName_201                    ; [201] (unnamed)
	.long	HdaeUiName_202                    ; [202] (unnamed)
	.long	HdaeUiName_203                    ; [203] (unnamed)
	.long	HdaeUiName_204                    ; [204] (unnamed)
	.long	HdaeUiName_205                    ; [205] (unnamed)
	.long	HdaeUiName_206                    ; [206] (unnamed)
	.long	HdaeUiName_207                    ; [207] (unnamed)
	.long	HdaeUiName_208                    ; [208] (unnamed)
	.long	HdaeUiName_209                    ; [209] (unnamed)
	.long	HdaeUiName_210                    ; [210] "CP_FD"
	.long	HdaeUiName_211                    ; [211] (unnamed)
	.long	HdaeUiName_212                    ; [212] (unnamed)
	.long	HdaeUiName_213                    ; [213] (unnamed)
	.long	HdaeUiName_214                    ; [214] (unnamed)
	.long	HdaeUiName_215                    ; [215] "CP_FD_LIST"
	.long	HdaeUiName_216                    ; [216] "CP_FD_LINE2"
	.long	HdaeUiName_217                    ; [217] "CP_FD_LINE1"
	.long	HdaeUiName_218                    ; [218] "CP_FD_HDSWTO"
	.long	HdaeUiName_219                    ; [219] (unnamed)
	.long	HdaeUiName_220                    ; [220] "CP_FD_HDSWSEL"
	.long	HdaeUiName_221                    ; [221] (unnamed)
	.long	HdaeUiName_222                    ; [222] "CP_FD_VOLLABEL"
	.long	HdaeUiName_223                    ; [223] (unnamed)
	.long	HdaeUiName_224                    ; [224] "CP_FD_HDALLSEL"
	.long	HdaeUiName_225                    ; [225] (unnamed)
	.long	HdaeUiName_226                    ; [226] "CP_FD_DIRSEL"
	.long	HdaeUiName_227                    ; [227] (unnamed)
	.long	HdaeUiName_228                    ; [228] (unnamed)
	.long	HdaeUiName_229                    ; [229] (unnamed)
	.long	HdaeUiName_230                    ; [230] "CP_FD_DIRBOX"
	.long	HdaeUiName_231                    ; [231] (unnamed)
	.long	HdaeUiName_232                    ; [232] (unnamed)
	.long	HdaeUiName_233                    ; [233] (unnamed)
	.long	HdaeUiName_234                    ; [234] (unnamed)
	.long	HdaeUiName_235                    ; [235] (unnamed)
	.long	HdaeUiName_236                    ; [236] (unnamed)
	.long	HdaeUiName_237                    ; [237] (unnamed)
	.long	HdaeUiName_238                    ; [238] (unnamed)
	.long	HdaeUiName_239                    ; [239] (unnamed)
	.long	HdaeUiName_240                    ; [240] "FLS_SELECT"
	.long	HdaeUiName_241                    ; [241] (unnamed)
	.long	HdaeUiName_242                    ; [242] (unnamed)
	.long	HdaeUiName_243                    ; [243] (unnamed)
	.long	HdaeUiName_244                    ; [244] (unnamed)
	.long	HdaeUiName_245                    ; [245] (unnamed)
	.long	HdaeUiName_246                    ; [246] (unnamed)
	.long	HdaeUiName_247                    ; [247] (unnamed)
	.long	HdaeUiName_248                    ; [248] "FLS_SEL"
	.long	HdaeUiName_249                    ; [249] "FLS_SELECT_SW_EDIT"
	.long	HdaeUiName_250                    ; [250] (unnamed)
	.long	HdaeUiName_251                    ; [251] "SEL_FLS"
	.long	HdaeUiName_252                    ; [252] (unnamed)
	.long	HdaeUiName_253                    ; [253] (unnamed)
	.long	HdaeUiName_254                    ; [254] (unnamed)
	.long	HdaeUiName_255                    ; [255] "HD_FILE_LOAD_P1"
	.long	HdaeUiName_256                    ; [256] "HD_FILE_LOAD_SW_SAVE"
	.long	HdaeUiName_257                    ; [257] (unnamed)
	.long	HdaeUiName_258                    ; [258] "HD_FILE_OPTION"
	.long	HdaeUiName_259                    ; [259] "HD_FILE_LIST"
	.long	HdaeUiName_260                    ; [260] "FILE_LOAD_DIRBOX"
	.long	HdaeUiName_261                    ; [261] (unnamed)
	.long	HdaeUiName_262                    ; [262] (unnamed)
	.long	HdaeUiName_263                    ; [263] (unnamed)
	.long	HdaeUiName_264                    ; [264] (unnamed)
	.long	HdaeUiName_265                    ; [265] (unnamed)
	.long	HdaeUiName_266                    ; [266] "HD_FILE_LOAD_SW_DEL"
	.long	HdaeUiName_267                    ; [267] (unnamed)
	.long	HdaeUiName_268                    ; [268] (unnamed)
	.long	HdaeUiName_269                    ; [269] "HD_FILE_LOAD_SW_DELFILE"
	.long	HdaeUiName_270                    ; [270] (unnamed)
	.long	HdaeUiName_271                    ; [271] (unnamed)
	.long	HdaeUiName_272                    ; [272] "HD_FILE_LOAD_P2"
	.long	HdaeUiName_273                    ; [273] (unnamed)
	.long	HdaeUiName_274                    ; [274] (unnamed)
	.long	HdaeUiName_275                    ; [275] (unnamed)
	.long	HdaeUiName_276                    ; [276] (unnamed)
	.long	HdaeUiName_277                    ; [277] (unnamed)
	.long	HdaeUiName_278                    ; [278] (unnamed)
	.long	HdaeUiName_279                    ; [279] (unnamed)
	.long	HdaeUiName_280                    ; [280] (unnamed)
	.long	HdaeUiName_281                    ; [281] (unnamed)
	.long	HdaeUiName_282                    ; [282] (unnamed)
	.long	HdaeUiName_283                    ; [283] (unnamed)
	.long	HdaeUiName_284                    ; [284] (unnamed)
	.long	HdaeUiName_285                    ; [285] (unnamed)
	.long	HdaeUiName_286                    ; [286] (unnamed)
	.long	HdaeUiName_287                    ; [287] (unnamed)
	.long	HdaeUiName_288                    ; [288] (unnamed)
	.long	HdaeUiName_289                    ; [289] (unnamed)
	.long	HdaeUiName_290                    ; [290] (unnamed)
	.long	HdaeUiName_291                    ; [291] (unnamed)
	.long	HdaeUiName_292                    ; [292] (unnamed)
	.long	HdaeUiName_293                    ; [293] (unnamed)
	.long	HdaeUiName_294                    ; [294] (unnamed)
	.long	HdaeUiName_295                    ; [295] (unnamed)
	.long	HdaeUiName_296                    ; [296] (unnamed)
	.long	HdaeUiName_297                    ; [297] (unnamed)
	.long	HdaeUiName_298                    ; [298] (unnamed)
	.long	HdaeUiName_299                    ; [299] (unnamed)
	.long	HdaeUiName_300                    ; [300] (unnamed)
	.long	HdaeUiName_301                    ; [301] (unnamed)
	.long	HdaeUiName_302                    ; [302] (unnamed)
	.long	HdaeUiName_303                    ; [303] (unnamed)
	.long	HdaeUiName_304                    ; [304] (unnamed)
	.long	HdaeUiName_305                    ; [305] (unnamed)
	.long	HdaeUiName_306                    ; [306] (unnamed)
	.long	HdaeUiName_307                    ; [307] (unnamed)
	.long	HdaeUiName_308                    ; [308] "HDD_FLS_NAMING"
	.long	HdaeUiName_309                    ; [309] (unnamed)
	.long	HdaeUiName_310                    ; [310] (unnamed)
	.long	HdaeUiName_311                    ; [311] (unnamed)
	.long	HdaeUiName_312                    ; [312] (unnamed)
	.long	HdaeUiName_313                    ; [313] (unnamed)
	.long	HdaeUiName_314                    ; [314] "FLS_FILE_LOAD"
	.long	HdaeUiName_315                    ; [315] (unnamed)
	.long	HdaeUiName_316                    ; [316] (unnamed)
	.long	HdaeUiName_317                    ; [317] (unnamed)
	.long	HdaeUiName_318                    ; [318] "FLS_FILE_LOAD_SW_EDIT"
	.long	HdaeUiName_319                    ; [319] (unnamed)
	.long	HdaeUiName_320                    ; [320] (unnamed)
	.long	HdaeUiName_321                    ; [321] (unnamed)
	.long	HdaeUiName_322                    ; [322] (unnamed)
	.long	HdaeUiName_323                    ; [323] "FLS_OPT_BOX"
	.long	HdaeUiName_324                    ; [324] "FLS_LOC_BOX"
	.long	HdaeUiName_325                    ; [325] "FLS_NAME_BOX"
	.long	HdaeUiName_326                    ; [326] (unnamed)
	.long	HdaeUiName_327                    ; [327] (unnamed)
	.long	HdaeUiName_328                    ; [328] "FLS_FILE_BOX"
	.long	HdaeUiName_329                    ; [329] "FLS_LOAD_LINE1"
	.long	HdaeUiName_330                    ; [330] "FLS_LOAD_LINE2"
	.long	HdaeUiName_331                    ; [331] (unnamed)
	.long	HdaeUiName_332                    ; [332] (unnamed)
	.long	HdaeUiName_333                    ; [333] (unnamed)
	.long	HdaeUiName_334                    ; [334] "FLS_DIR_SEL"
	.long	HdaeUiName_335                    ; [335] (unnamed)
	.long	HdaeUiName_336                    ; [336] (unnamed)
	.long	HdaeUiName_337                    ; [337] "FLS_DIR_BOX"
	.long	HdaeUiName_338                    ; [338] (unnamed)
	.long	HdaeUiName_339                    ; [339] (unnamed)
	.long	HdaeUiName_340                    ; [340] (unnamed)
	.long	HdaeUiName_341                    ; [341] (unnamed)
	.long	HdaeUiName_342                    ; [342] (unnamed)
	.long	HdaeUiName_343                    ; [343] (unnamed)
	.long	HdaeUiName_344                    ; [344] (unnamed)
	.long	HdaeUiName_345                    ; [345] "FLS_FILE_SEL"
	.long	HdaeUiName_346                    ; [346] (unnamed)
	.long	HdaeUiName_347                    ; [347] "FLS_FILE_SEL_DIRBOX"
	.long	HdaeUiName_348                    ; [348] "FLS_FILE_SEL_LISTBOX"
	.long	HdaeUiName_349                    ; [349] (unnamed)
	.long	HdaeUiName_350                    ; [350] (unnamed)
	.long	HdaeUiName_351                    ; [351] (unnamed)
	.long	HdaeUiName_352                    ; [352] "FLS_FILE_SEL_OPTBOX"
	.long	HdaeUiName_353                    ; [353] (unnamed)
	.long	HdaeUiName_354                    ; [354] (unnamed)
	.long	HdaeUiName_355                    ; [355] "FLS_EDIT"
	.long	HdaeUiName_356                    ; [356] (unnamed)
	.long	HdaeUiName_357                    ; [357] (unnamed)
	.long	HdaeUiName_358                    ; [358] "FLS_EDIT_NAME_BOX"
	.long	HdaeUiName_359                    ; [359] (unnamed)
	.long	HdaeUiName_360                    ; [360] (unnamed)
	.long	HdaeUiName_361                    ; [361] "FLS_EDIT_LIST_BOX"
	.long	HdaeUiName_362                    ; [362] "FLS_EDIT_LINE2"
	.long	HdaeUiName_363                    ; [363] "FLS_EDIT_LINE1"
	.long	HdaeUiName_364                    ; [364] (unnamed)
	.long	HdaeUiName_365                    ; [365] (unnamed)
	.long	HdaeUiName_366                    ; [366] (unnamed)
	.long	HdaeUiName_367                    ; [367] (unnamed)
	.long	HdaeUiName_368                    ; [368] (unnamed)
	.long	HdaeUiName_369                    ; [369] (unnamed)
	.long	HdaeUiName_370                    ; [370] (unnamed)
	.long	HdaeUiName_371                    ; [371] (unnamed)
	.long	HdaeUiName_372                    ; [372] (unnamed)
	.long	HdaeUiName_373                    ; [373] (unnamed)
	.long	HdaeUiName_374                    ; [374] "FLS_EDIT_LOC_BOX"
	.long	HdaeUiName_375                    ; [375] "FLS_EDIT_OPT_BOX"
	.long	HdaeUiName_376                    ; [376] (unnamed)
	.long	HdaeUiName_377                    ; [377] (unnamed)
	.long	HdaeUiName_378                    ; [378] (unnamed)
	.long	HdaeUiName_379                    ; [379] "CP_FD_DIR_NAMING"
	.long	HdaeUiName_380                    ; [380] (unnamed)
	.long	HdaeUiName_381                    ; [381] (unnamed)
	.long	HdaeUiName_382                    ; [382] (unnamed)
	.long	HdaeUiName_383                    ; [383] (unnamed)
	.long	HdaeUiName_384                    ; [384] (unnamed)
	.long	HdaeUiName_385                    ; [385] (unnamed)
	.long	HdaeUiName_386                    ; [386] "SAVE_OPT_SCREEN"
	.long	HdaeUiName_387                    ; [387] (unnamed)
	.long	HdaeUiName_388                    ; [388] (unnamed)
	.long	HdaeUiName_389                    ; [389] (unnamed)
	.long	HdaeUiName_390                    ; [390] (unnamed)
	.long	HdaeUiName_391                    ; [391] (unnamed)
	.long	HdaeUiName_392                    ; [392] (unnamed)
	.long	HdaeUiName_393                    ; [393] (unnamed)
	.long	HdaeUiName_394                    ; [394] (unnamed)
	.long	HdaeUiName_395                    ; [395] (unnamed)
	.long	HdaeUiName_396                    ; [396] (unnamed)
	.long	HdaeUiName_397                    ; [397] (unnamed)
	.long	HdaeUiName_398                    ; [398] (unnamed)
	.long	HdaeUiName_399                    ; [399] (unnamed)
	.long	HdaeUiName_400                    ; [400] (unnamed)
	.long	HdaeUiName_401                    ; [401] (unnamed)
	.long	HdaeUiName_402                    ; [402] (unnamed)
	.long	HdaeUiName_403                    ; [403] (unnamed)
	.long	HdaeUiName_404                    ; [404] "RAM_EDIT_CMP"
	.long	HdaeUiName_405                    ; [405] (unnamed)
	.long	HdaeUiName_406                    ; [406] "RAM_EDIT_LSW"
	.long	HdaeUiName_407                    ; [407] "RAM_EDIT_PMT"
	.long	HdaeUiName_408                    ; [408] "RAM_EDIT_SQT"
	.long	HdaeUiName_409                    ; [409] "RAM_EDIT_TM"
	.long	HdaeUiName_410                    ; [410] "RAM_EDIT_MSP"
	.long	HdaeUiName_411                    ; [411] "RAM_EDIT_RCM"
	.long	HdaeUiName_412                    ; [412] "RAM_EDIT_MD"
	.long	HdaeUiName_413                    ; [413] (unnamed)
	.long	HdaeUiName_414                    ; [414] (unnamed)
	.long	HdaeUiName_415                    ; [415] (unnamed)
	.long	HdaeUiName_416                    ; [416] (unnamed)
	.long	HdaeUiName_417                    ; [417] (unnamed)
	.long	HdaeUiName_418                    ; [418] (unnamed)
	.long	HdaeUiName_419                    ; [419] (unnamed)
	.long	HdaeUiName_420                    ; [420] (unnamed)
	.long	HdaeUiName_421                    ; [421] (unnamed)
	.long	HdaeUiName_422                    ; [422] (unnamed)
	.long	HdaeUiName_423                    ; [423] (unnamed)
	.long	HdaeUiName_424                    ; [424] (unnamed)
	.long	HdaeUiName_425                    ; [425] (unnamed)
	.long	HdaeUiName_426                    ; [426] "RAM_EDIT_TLX"
	.long	HdaeUiName_427                    ; [427] (unnamed)
	.long	HdaeUiName_428                    ; [428] (unnamed)
	.long	HdaeUiName_429                    ; [429] (unnamed)
	.long	HdaeUiName_430                    ; [430] "HddNamingWindow"
	.long	HdaeUiName_431                    ; [431] (unnamed)
	.long	HdaeUiName_432                    ; [432] (unnamed)
	.long	HdaeUiName_433                    ; [433] (unnamed)
	.long	HdaeUiName_434                    ; [434] (unnamed)
	.long	HdaeUiName_435                    ; [435] (unnamed)
	.long	HdaeUiName_436                    ; [436] (unnamed)
	.long	HdaeUiName_437                    ; [437] (unnamed)
	.long	HdaeUiName_438                    ; [438] (unnamed)
	.long	HdaeUiName_439                    ; [439] (unnamed)
	.long	HdaeUiName_440                    ; [440] (unnamed)
	.long	HdaeUiName_441                    ; [441] (unnamed)
	.long	HdaeUiName_442                    ; [442] "HddNamingCursorBox"
	.long	HdaeUiName_443                    ; [443] "HddNamingABC"
	.long	HdaeUiName_444                    ; [444] "HddNamingabc"
	.long	HdaeUiName_445                    ; [445] "HddNamingSymbol"
	.long	HdaeUiName_446                    ; [446] (unnamed)
	.long	HdaeUiName_447                    ; [447] (unnamed)
	.long	HdaeUiName_448                    ; [448] (unnamed)
	.long	HdaeUiName_449                    ; [449] "HddNamingLabel"
	.long	HdaeUiName_450                    ; [450] "FILE_DEL_SCREEN"
	.long	HdaeUiName_451                    ; [451] (unnamed)
	.long	HdaeUiName_452                    ; [452] (unnamed)
	.long	HdaeUiName_453                    ; [453] (unnamed)
	.long	HdaeUiName_454                    ; [454] (unnamed)
	.long	HdaeUiName_455                    ; [455] (unnamed)
	.long	HdaeUiName_456                    ; [456] (unnamed)
	.long	HdaeUiName_457                    ; [457] (unnamed)
	.long	HdaeUiName_458                    ; [458] (unnamed)
	.long	HdaeUiName_459                    ; [459] (unnamed)
	.long	HdaeUiName_460                    ; [460] (unnamed)
	.long	HdaeUiName_461                    ; [461] (unnamed)
	.long	HdaeUiName_462                    ; [462] (unnamed)
	.long	HdaeUiName_463                    ; [463] "DEL_EDIT_LSW"
	.long	HdaeUiName_464                    ; [464] "DEL_EDIT_PMT"
	.long	HdaeUiName_465                    ; [465] "DEL_EDIT_SQT"
	.long	HdaeUiName_466                    ; [466] "DEL_EDIT_CMP"
	.long	HdaeUiName_467                    ; [467] "DEL_EDIT_TM"
	.long	HdaeUiName_468                    ; [468] "DEL_EDIT_MSP"
	.long	HdaeUiName_469                    ; [469] "DEL_EDIT_RCM"
	.long	HdaeUiName_470                    ; [470] "DEL_EDIT_MD"
	.long	HdaeUiName_471                    ; [471] (unnamed)
	.long	HdaeUiName_472                    ; [472] (unnamed)
	.long	HdaeUiName_473                    ; [473] (unnamed)
	.long	HdaeUiName_474                    ; [474] (unnamed)
	.long	HdaeUiName_475                    ; [475] (unnamed)
	.long	HdaeUiName_476                    ; [476] (unnamed)
	.long	HdaeUiName_477                    ; [477] (unnamed)
	.long	HdaeUiName_478                    ; [478] (unnamed)
	.long	HdaeUiName_479                    ; [479] (unnamed)
	.long	HdaeUiName_480                    ; [480] (unnamed)
	.long	HdaeUiName_481                    ; [481] (unnamed)
	.long	HdaeUiName_482                    ; [482] (unnamed)
	.long	HdaeUiName_483                    ; [483] (unnamed)
	.long	HdaeUiName_484                    ; [484] (unnamed)
	.long	HdaeUiName_485                    ; [485] (unnamed)
	.long	HdaeUiName_486                    ; [486] (unnamed)
	.long	HdaeUiName_487                    ; [487] (unnamed)
	.long	HdaeUiName_488                    ; [488] (unnamed)
	.long	HdaeUiName_489                    ; [489] "DEL_EDIT_TLX"
	.long	HdaeUiName_490                    ; [490] (unnamed)
	.long	HdaeUiName_491                    ; [491] (unnamed)
	.long	HdaeUiName_492                    ; [492] "HDD_ICON_DISPLAY"
	.long	HdaeUiName_493                    ; [493] "HD_MENU_BMP"
	.long	HdaeUiName_494                    ; [494] "IV_HDDMENU"
	.long	HdaeUiName_495                    ; [495] "ATTEN_DEL_DIR"
	.long	HdaeUiName_496                    ; [496] (unnamed)
	.long	HdaeUiName_497                    ; [497] (unnamed)
	.long	HdaeUiName_498                    ; [498] (unnamed)
	.long	HdaeUiName_499                    ; [499] (unnamed)
	.long	HdaeUiName_500                    ; [500] (unnamed)
	.long	HdaeUiName_501                    ; [501] (unnamed)
	.long	HdaeUiName_502                    ; [502] (unnamed)
	.long	HdaeUiName_503                    ; [503] (unnamed)
	.long	HdaeUiName_504                    ; [504] "WAIT_DEL_DIR"
	.long	HdaeUiName_505                    ; [505] (unnamed)
	.long	HdaeUiName_506                    ; [506] (unnamed)
	.long	HdaeUiName_507                    ; [507] "ATTEN_DEL_FILE"
	.long	HdaeUiName_508                    ; [508] (unnamed)
	.long	HdaeUiName_509                    ; [509] (unnamed)
	.long	HdaeUiName_510                    ; [510] (unnamed)
	.long	HdaeUiName_511                    ; [511] (unnamed)
	.long	HdaeUiName_512                    ; [512] (unnamed)
	.long	HdaeUiName_513                    ; [513] (unnamed)
	.long	HdaeUiName_514                    ; [514] (unnamed)
	.long	HdaeUiName_515                    ; [515] (unnamed)
	.long	HdaeUiName_516                    ; [516] "ATTEN_OVER_FLS"
	.long	HdaeUiName_517                    ; [517] (unnamed)
	.long	HdaeUiName_518                    ; [518] (unnamed)
	.long	HdaeUiName_519                    ; [519] (unnamed)
	.long	HdaeUiName_520                    ; [520] (unnamed)
	.long	HdaeUiName_521                    ; [521] (unnamed)
	.long	HdaeUiName_522                    ; [522] (unnamed)
	.long	HdaeUiName_523                    ; [523] (unnamed)
	.long	HdaeUiName_524                    ; [524] (unnamed)
	.long	HdaeUiName_525                    ; [525] "ATTEN_DEL_FLS2"
	.long	HdaeUiName_526                    ; [526] (unnamed)
	.long	HdaeUiName_527                    ; [527] (unnamed)
	.long	HdaeUiName_528                    ; [528] (unnamed)
	.long	HdaeUiName_529                    ; [529] (unnamed)
	.long	HdaeUiName_530                    ; [530] (unnamed)
	.long	HdaeUiName_531                    ; [531] (unnamed)
	.long	HdaeUiName_532                    ; [532] (unnamed)
	.long	HdaeUiName_533                    ; [533] (unnamed)
	.long	HdaeUiName_534                    ; [534] (unnamed)
	.long	HdaeUiName_535                    ; [535] "WAIT_DEL_FILE"
	.long	HdaeUiName_536                    ; [536] (unnamed)
	.long	HdaeUiName_537                    ; [537] (unnamed)
	.long	HdaeUiName_538                    ; [538] "ATTEN_HD_FORMAT"
	.long	HdaeUiName_539                    ; [539] (unnamed)
	.long	HdaeUiName_540                    ; [540] (unnamed)
	.long	HdaeUiName_541                    ; [541] (unnamed)
	.long	HdaeUiName_542                    ; [542] (unnamed)
	.long	HdaeUiName_543                    ; [543] (unnamed)
	.long	HdaeUiName_544                    ; [544] (unnamed)
	.long	HdaeUiName_545                    ; [545] (unnamed)
	.long	HdaeUiName_546                    ; [546] "HD_FORMAT_CATCH"
	.long	HdaeUiName_547                    ; [547] "WAIT_HD_FORMAT"
	.long	HdaeUiName_548                    ; [548] (unnamed)
	.long	HdaeUiName_549                    ; [549] (unnamed)
	.long	HdaeUiName_550                    ; [550] (unnamed)
	.long	HdaeUiName_551                    ; [551] "SETUP_HDINFO"
	.long	HdaeUiName_552                    ; [552] (unnamed)
	.long	HdaeUiName_553                    ; [553] (unnamed)
	.long	HdaeUiName_554                    ; [554] "HD_INFO_LIST"
	.long	HdaeUiName_555                    ; [555] (unnamed)
	.long	HdaeUiName_556                    ; [556] "DBG_MEMO_SCREEN"
	.long	HdaeUiName_557                    ; [557] (unnamed)
	.long	HdaeUiName_558                    ; [558] (unnamed)
	.long	HdaeUiName_559                    ; [559] "ATTEN_DEL_FLS1"
	.long	HdaeUiName_560                    ; [560] (unnamed)
	.long	HdaeUiName_561                    ; [561] (unnamed)
	.long	HdaeUiName_562                    ; [562] (unnamed)
	.long	HdaeUiName_563                    ; [563] (unnamed)
	.long	HdaeUiName_564                    ; [564] (unnamed)
	.long	HdaeUiName_565                    ; [565] (unnamed)
	.long	HdaeUiName_566                    ; [566] (unnamed)
	.long	HdaeUiName_567                    ; [567] (unnamed)
	.long	HdaeUiName_568                    ; [568] (unnamed)
	.long	HdaeUiName_569                    ; [569] (unnamed)
	.long	HdaeUiName_570                    ; [570] (unnamed)
	.long	HdaeUiName_571                    ; [571] "ATTEN_OVER_FILE"
	.long	HdaeUiName_572                    ; [572] (unnamed)
	.long	HdaeUiName_573                    ; [573] (unnamed)
	.long	HdaeUiName_574                    ; [574] (unnamed)
	.long	HdaeUiName_575                    ; [575] (unnamed)
	.long	HdaeUiName_576                    ; [576] (unnamed)
	.long	HdaeUiName_577                    ; [577] (unnamed)
	.long	HdaeUiName_578                    ; [578] (unnamed)
	.long	HdaeUiName_579                    ; [579] (unnamed)
	.long	HdaeUiName_580                    ; [580] "HDD_FLS_NAMING2"
	.long	HdaeUiName_581                    ; [581] (unnamed)
	.long	HdaeUiName_582                    ; [582] (unnamed)
	.long	HdaeUiName_583                    ; [583] (unnamed)
	.long	HdaeUiName_584                    ; [584] (unnamed)
	.long	HdaeUiName_585                    ; [585] (unnamed)
	.long	HdaeUiName_586                    ; [586] "ATTEN_CPHD_WR"
	.long	HdaeUiName_587                    ; [587] (unnamed)
	.long	HdaeUiName_588                    ; [588] (unnamed)
	.long	HdaeUiName_589                    ; [589] (unnamed)
	.long	HdaeUiName_590                    ; [590] (unnamed)
	.long	HdaeUiName_591                    ; [591] (unnamed)
	.long	HdaeUiName_592                    ; [592] (unnamed)
	.long	HdaeUiName_593                    ; [593] (unnamed)
	.long	HdaeUiName_594                    ; [594] "ERR_HD_NOT_FMT"
	.long	HdaeUiName_595                    ; [595] (unnamed)
	.long	HdaeUiName_596                    ; [596] (unnamed)
	.long	HdaeUiName_597                    ; [597] (unnamed)
	.long	HdaeUiName_598                    ; [598] (unnamed)
	.long	HdaeUiName_599                    ; [599] "ERR_HD_SRAM"
	.long	HdaeUiName_600                    ; [600] (unnamed)
	.long	HdaeUiName_601                    ; [601] (unnamed)
	.long	HdaeUiName_602                    ; [602] (unnamed)
	.long	HdaeUiName_603                    ; [603] (unnamed)
	.long	HdaeUiName_604                    ; [604] "ERR_HD_RESET"
	.long	HdaeUiName_605                    ; [605] (unnamed)
	.long	HdaeUiName_606                    ; [606] (unnamed)
	.long	HdaeUiName_607                    ; [607] (unnamed)
	.long	HdaeUiName_608                    ; [608] (unnamed)
	.long	HdaeUiName_609                    ; [609] "ERR_HD_READ"
	.long	HdaeUiName_610                    ; [610] (unnamed)
	.long	HdaeUiName_611                    ; [611] (unnamed)
	.long	HdaeUiName_612                    ; [612] (unnamed)
	.long	HdaeUiName_613                    ; [613] (unnamed)
	.long	HdaeUiName_614                    ; [614] "ERR_HD_ID_READ"
	.long	HdaeUiName_615                    ; [615] (unnamed)
	.long	HdaeUiName_616                    ; [616] (unnamed)
	.long	HdaeUiName_617                    ; [617] (unnamed)
	.long	HdaeUiName_618                    ; [618] (unnamed)
	.long	HdaeUiName_619                    ; [619] "ERR_HD_TRACK_0"
	.long	HdaeUiName_620                    ; [620] (unnamed)
	.long	HdaeUiName_621                    ; [621] (unnamed)
	.long	HdaeUiName_622                    ; [622] (unnamed)
	.long	HdaeUiName_623                    ; [623] (unnamed)
	.long	HdaeUiName_624                    ; [624] "ERR_HD_FAT"
	.long	HdaeUiName_625                    ; [625] (unnamed)
	.long	HdaeUiName_626                    ; [626] (unnamed)
	.long	HdaeUiName_627                    ; [627] (unnamed)
	.long	HdaeUiName_628                    ; [628] (unnamed)
	.long	HdaeUiName_629                    ; [629] "ERR_HD_FSB"
	.long	HdaeUiName_630                    ; [630] (unnamed)
	.long	HdaeUiName_631                    ; [631] (unnamed)
	.long	HdaeUiName_632                    ; [632] (unnamed)
	.long	HdaeUiName_633                    ; [633] (unnamed)
	.long	HdaeUiName_634                    ; [634] "ATTEN_CPFD_MARK"
	.long	HdaeUiName_635                    ; [635] (unnamed)
	.long	HdaeUiName_636                    ; [636] (unnamed)
	.long	HdaeUiName_637                    ; [637] (unnamed)
	.long	HdaeUiName_638                    ; [638] (unnamed)
	.long	HdaeUiName_639                    ; [639] (unnamed)
	.long	HdaeUiName_640                    ; [640] (unnamed)
	.long	HdaeUiName_641                    ; [641] "ABOUT_HELP"
	.long	HdaeUiName_642                    ; [642] (unnamed)
	.long	HdaeUiName_643                    ; [643] (unnamed)
	.long	HdaeUiName_644                    ; [644] (unnamed)
	.long	HdaeUiName_645                    ; [645] (unnamed)
	.long	HdaeUiName_646                    ; [646] (unnamed)
	.long	HdaeUiName_647                    ; [647] (unnamed)
	.long	HdaeUiName_648                    ; [648] (unnamed)
	.long	HdaeUiName_649                    ; [649] (unnamed)
	.long	HdaeUiName_650                    ; [650] (unnamed)
	.long	HdaeUiName_651                    ; [651] (unnamed)
	.long	HdaeUiName_652                    ; [652] (unnamed)
	.long	HdaeUiName_653                    ; [653] (unnamed)
	.long	HdaeUiName_654                    ; [654] (unnamed)
	.long	HdaeUiName_655                    ; [655] (unnamed)
	.long	HdaeUiName_656                    ; [656] (unnamed)
	.long	HdaeUiName_657                    ; [657] (unnamed)
	.long	HdaeUiName_658                    ; [658] (unnamed)
	.long	HdaeUiName_659                    ; [659] (unnamed)
	.long	HdaeUiName_660                    ; [660] "WAIT_TR0_RECOVER"
	.long	HdaeUiName_661                    ; [661] (unnamed)
	.long	HdaeUiName_662                    ; [662] (unnamed)
	.long	HdaeUiName_663                    ; [663] "ERR_SAVE"
	.long	HdaeUiName_664                    ; [664] "ERR_SAVE_EXIT"
	.long	HdaeUiName_665                    ; [665] "ERR_SAVE_CATCH"
	.long	HdaeUiName_666                    ; [666] (unnamed)
	.long	HdaeUiName_667                    ; [667] (unnamed)
	.long	HdaeUiName_668                    ; [668] (unnamed)
	.long	HdaeUiName_669                    ; [669] "ERR_LOAD"
	.long	HdaeUiName_670                    ; [670] "ERR_LOAD_EXIT"
	.long	HdaeUiName_671                    ; [671] "ERR_LOAD_CATCH"
	.long	HdaeUiName_672                    ; [672] (unnamed)
	.long	HdaeUiName_673                    ; [673] (unnamed)
	.long	HdaeUiName_674                    ; [674] (unnamed)
	.long	HdaeUiName_675                    ; [675] "ERR_NO_HK_DATA"
	.long	HdaeUiName_676                    ; [676] (unnamed)
	.long	HdaeUiName_677                    ; [677] "ERR_NO_HK_DATA_CATCH"
	.long	HdaeUiName_678                    ; [678] (unnamed)
	.long	HdaeUiName_679                    ; [679] (unnamed)
	.long	HdaeUiName_680                    ; [680] (unnamed)
	.long	HdaeUiName_681                    ; [681] "ATTEN_FULL_DIR"
	.long	HdaeUiName_682                    ; [682] (unnamed)
	.long	HdaeUiName_683                    ; [683] "ATTEN_FULL_DIR_CATCH"
	.long	HdaeUiName_684                    ; [684] (unnamed)
	.long	HdaeUiName_685                    ; [685] (unnamed)
	.long	HdaeUiName_686                    ; [686] (unnamed)
	.long	HdaeUiName_687                    ; [687] (unnamed)
	.long	HdaeUiName_688                    ; [688] "ATTEN_CP_UNNAMED"
	.long	HdaeUiName_689                    ; [689] (unnamed)
	.long	HdaeUiName_690                    ; [690] "ATTEN_CP_UNNAMED_CATCH"
	.long	HdaeUiName_691                    ; [691] (unnamed)
	.long	HdaeUiName_692                    ; [692] (unnamed)
	.long	HdaeUiName_693                    ; [693] (unnamed)
	.long	HdaeUiName_694                    ; [694] (unnamed)
	.long	HdaeUiName_695                    ; [695] "DIR_OUT_RANGE"
	.long	HdaeUiName_696                    ; [696] "DIR_OUT_RANGE_CATCH"
	.long	HdaeUiName_697                    ; [697] (unnamed)
	.long	HdaeUiName_698                    ; [698] (unnamed)
	.long	HdaeUiName_699                    ; [699] (unnamed)
	.long	HdaeUiName_700                    ; [700] "FILE_OUT_RANGE"
	.long	HdaeUiName_701                    ; [701] "FILE_OUT_RANGE_CATCH"
	.long	HdaeUiName_702                    ; [702] (unnamed)
	.long	HdaeUiName_703                    ; [703] (unnamed)
	.long	HdaeUiName_704                    ; [704] (unnamed)
	.long	HdaeUiName_705                    ; [705] "HD_PLEASE"
	.long	HdaeUiName_706                    ; [706] (unnamed)
	.long	HdaeUiName_707                    ; [707] (unnamed)
	.long	HdaeUiName_708                    ; [708] "ERR_HD_FORMAT"
	.long	HdaeUiName_709                    ; [709] (unnamed)
	.long	HdaeUiName_710                    ; [710] "ERR_HD_FORMAT_CATCH"
	.long	HdaeUiName_711                    ; [711] (unnamed)
	.long	HdaeUiName_712                    ; [712] (unnamed)
	.long	HdaeUiName_713                    ; [713] (unnamed)
	.long	HdaeUiName_714                    ; [714] (unnamed)
	.long	HdaeUiName_715                    ; [715] "AGAIN_HD_FORMAT"
	.long	HdaeUiName_716                    ; [716] (unnamed)
	.long	HdaeUiName_717                    ; [717] "AGAIN_HD_FORMAT_CATCH"
	.long	HdaeUiName_718                    ; [718] (unnamed)
	.long	HdaeUiName_719                    ; [719] (unnamed)
	.long	HdaeUiName_720                    ; [720] (unnamed)
	.long	HdaeUiName_721                    ; [721] (unnamed)
	.long	HdaeUiName_722                    ; [722] "SELECT_FILE_A_Z"
	.long	HdaeUiName_723                    ; [723] (unnamed)
	.long	HdaeUiName_724                    ; [724] (unnamed)
	.long	HdaeUiName_725                    ; [725] (unnamed)
	.long	HdaeUiName_726                    ; [726] (unnamed)
	.long	HdaeUiName_727                    ; [727] (unnamed)
	.long	HdaeUiName_728                    ; [728] "FILE_LOAD_A_Z"
	.long	HdaeUiName_729                    ; [729] (unnamed)
	.long	HdaeUiName_730                    ; [730] (unnamed)
	.long	HdaeUiName_731                    ; [731] (unnamed)
	.long	HdaeUiName_732                    ; [732] (unnamed)
	.long	HdaeUiName_733                    ; [733] (unnamed)
	.long	HdaeUiName_734                    ; [734] (unnamed)
	.long	HdaeUiName_735                    ; [735] (unnamed)
	.long	HdaeUiName_736                    ; [736] (unnamed)
	.long	HdaeUiName_737                    ; [737] (unnamed)
	.long	HdaeUiName_738                    ; [738] (unnamed)
	.long	HdaeUiName_739                    ; [739] (unnamed)
	.long	HdaeUiName_740                    ; [740] (unnamed)
	.long	HdaeUiName_741                    ; [741] (unnamed)
	.long	HdaeUiName_742                    ; [742] (unnamed)
	.long	HdaeUiName_743                    ; [743] (unnamed)
	.long	HdaeUiName_744                    ; [744] (unnamed)
	.long	HdaeUiName_745                    ; [745] (unnamed)
	.long	HdaeUiName_746                    ; [746] (unnamed)
	.long	HdaeUiName_747                    ; [747] (unnamed)
	.long	HdaeUiName_748                    ; [748] (unnamed)
	.long	HdaeUiName_749                    ; [749] (unnamed)
	.long	HdaeUiName_750                    ; [750] (unnamed)
	.long	HdaeUiName_751                    ; [751] (unnamed)
	.long	HdaeUiName_752                    ; [752] "Tech_lyrics"
	.long	HdaeUiName_753                    ; [753] (unnamed)
	.long	HdaeUiName_754                    ; [754] (unnamed)
	.long	HdaeUiName_755                    ; [755] "SongTitle"
	.long	HdaeUiName_756                    ; [756] (unnamed)
	.long	HdaeUiName_757                    ; [757] "Conductor"
	.long	HdaeUiName_758                    ; [758] "bottom01"
	.long	HdaeUiName_759                    ; [759] "bottom02"
	.long	HdaeUiName_760                    ; [760] "bottom03"
	.long	HdaeUiName_761                    ; [761] "bottom04"
	.long	HdaeUiName_762                    ; [762] "bottom05"
	.long	HdaeUiName_763                    ; [763] "bottom06"
	.long	HdaeUiName_764                    ; [764] "bottom07"
	.long	HdaeUiName_765                    ; [765] "bottom08"
	.long	HdaeUiName_766                    ; [766] (unnamed)
	.long	HdaeUiName_767                    ; [767] "ChordinLyric"
	.long	HdaeUiName_768                    ; [768] "TempoinLyric"
	.long	HdaeUiName_769                    ; [769] "MeasureinLyric"
	.long	HdaeUiName_770                    ; [770] "TimeSigInLyric"
	.long	HdaeUiName_771                    ; [771] (unnamed)
	.long	HdaeUiName_772                    ; [772] "LoadLyricFD"
	.long	HdaeUiName_773                    ; [773] (unnamed)
	.long	HdaeUiName_774                    ; [774] (unnamed)
	.long	HdaeUiName_775                    ; [775] (unnamed)
	.long	HdaeUiName_776                    ; [776] (unnamed)
	.long	HdaeUiName_777                    ; [777] "FD_PLEASE"
	.long	HdaeUiName_778                    ; [778] (unnamed)
	.long	HdaeUiName_779                    ; [779] (unnamed)
	.long	HdaeUiName_780                    ; [780] "LyrSettings"
	.long	HdaeUiName_781                    ; [781] (unnamed)
	.long	HdaeUiName_782                    ; [782] (unnamed)
	.long	HdaeUiName_783                    ; [783] (unnamed)
	.long	HdaeUiName_784                    ; [784] (unnamed)
	.long	HdaeUiName_785                    ; [785] (unnamed)
	.long	HdaeUiName_786                    ; [786] (unnamed)
	.long	HdaeUiName_787                    ; [787] (unnamed)
	.long	HdaeUiName_788                    ; [788] "WriteIn"
	.long	HdaeUiName_789                    ; [789] (unnamed)

; =============================================================================
; HD-AE5000 UI OBJECT NAME POOL (0x2A75DC - 0x2A8499)
; =============================================================================
; The strings HDAE5000_UiObjectName_PtrTable points at, NUL-terminated and
; padded to a 2-byte boundary.  Nothing else in the ROM points into this pool.
; Listed in ascending address order, which is DESCENDING object index: the
; original toolchain emitted the literals in reverse order of declaration, so
; HdaeUiName_789 (the terminator slot) is first and HdaeUiName_000 ("HDDMENU",
; the top-level HD-AE5000 menu) is last and ends exactly at 0x2A849A.
; =============================================================================

HDAE5000_UiObjectName_Pool:	; 0x2A75DC
HdaeUiName_789:	.zero	2                               ; 0x2A75DC  [789] (unnamed)
HdaeUiName_788:	.asciz	"WriteIn"                       ; 0x2A75DE  [788]
HdaeUiName_787:	.zero	2                               ; 0x2A75E6  [787] (unnamed)
HdaeUiName_786:	.zero	2                               ; 0x2A75E8  [786] (unnamed)
HdaeUiName_785:	.zero	2                               ; 0x2A75EA  [785] (unnamed)
HdaeUiName_784:	.zero	2                               ; 0x2A75EC  [784] (unnamed)
HdaeUiName_783:	.zero	2                               ; 0x2A75EE  [783] (unnamed)
HdaeUiName_782:	.zero	2                               ; 0x2A75F0  [782] (unnamed)
HdaeUiName_781:	.zero	2                               ; 0x2A75F2  [781] (unnamed)
HdaeUiName_780:	.asciz	"LyrSettings"                   ; 0x2A75F4  [780]
HdaeUiName_779:	.zero	2                               ; 0x2A7600  [779] (unnamed)
HdaeUiName_778:	.zero	2                               ; 0x2A7602  [778] (unnamed)
HdaeUiName_777:	.asciz	"FD_PLEASE"                     ; 0x2A7604  [777]
HdaeUiName_776:	.zero	2                               ; 0x2A760E  [776] (unnamed)
HdaeUiName_775:	.zero	2                               ; 0x2A7610  [775] (unnamed)
HdaeUiName_774:	.zero	2                               ; 0x2A7612  [774] (unnamed)
HdaeUiName_773:	.zero	2                               ; 0x2A7614  [773] (unnamed)
HdaeUiName_772:	.asciz	"LoadLyricFD"                   ; 0x2A7616  [772]
HdaeUiName_771:	.zero	2                               ; 0x2A7622  [771] (unnamed)
HdaeUiName_770:	.ascii	"TimeSigInLyric\0\0"            ; 0x2A7624  [770]
HdaeUiName_769:	.ascii	"MeasureinLyric\0\0"            ; 0x2A7634  [769]
HdaeUiName_768:	.ascii	"TempoinLyric\0\0"              ; 0x2A7644  [768]
HdaeUiName_767:	.ascii	"ChordinLyric\0\0"              ; 0x2A7652  [767]
HdaeUiName_766:	.zero	2                               ; 0x2A7660  [766] (unnamed)
HdaeUiName_765:	.ascii	"bottom08\0\0"                  ; 0x2A7662  [765]
HdaeUiName_764:	.ascii	"bottom07\0\0"                  ; 0x2A766C  [764]
HdaeUiName_763:	.ascii	"bottom06\0\0"                  ; 0x2A7676  [763]
HdaeUiName_762:	.ascii	"bottom05\0\0"                  ; 0x2A7680  [762]
HdaeUiName_761:	.ascii	"bottom04\0\0"                  ; 0x2A768A  [761]
HdaeUiName_760:	.ascii	"bottom03\0\0"                  ; 0x2A7694  [760]
HdaeUiName_759:	.ascii	"bottom02\0\0"                  ; 0x2A769E  [759]
HdaeUiName_758:	.ascii	"bottom01\0\0"                  ; 0x2A76A8  [758]
HdaeUiName_757:	.asciz	"Conductor"                     ; 0x2A76B2  [757]
HdaeUiName_756:	.zero	2                               ; 0x2A76BC  [756] (unnamed)
HdaeUiName_755:	.asciz	"SongTitle"                     ; 0x2A76BE  [755]
HdaeUiName_754:	.zero	2                               ; 0x2A76C8  [754] (unnamed)
HdaeUiName_753:	.zero	2                               ; 0x2A76CA  [753] (unnamed)
HdaeUiName_752:	.asciz	"Tech_lyrics"                   ; 0x2A76CC  [752]
HdaeUiName_751:	.zero	2                               ; 0x2A76D8  [751] (unnamed)
HdaeUiName_750:	.zero	2                               ; 0x2A76DA  [750] (unnamed)
HdaeUiName_749:	.zero	2                               ; 0x2A76DC  [749] (unnamed)
HdaeUiName_748:	.zero	2                               ; 0x2A76DE  [748] (unnamed)
HdaeUiName_747:	.zero	2                               ; 0x2A76E0  [747] (unnamed)
HdaeUiName_746:	.zero	2                               ; 0x2A76E2  [746] (unnamed)
HdaeUiName_745:	.zero	2                               ; 0x2A76E4  [745] (unnamed)
HdaeUiName_744:	.zero	2                               ; 0x2A76E6  [744] (unnamed)
HdaeUiName_743:	.zero	2                               ; 0x2A76E8  [743] (unnamed)
HdaeUiName_742:	.zero	2                               ; 0x2A76EA  [742] (unnamed)
HdaeUiName_741:	.zero	2                               ; 0x2A76EC  [741] (unnamed)
HdaeUiName_740:	.zero	2                               ; 0x2A76EE  [740] (unnamed)
HdaeUiName_739:	.zero	2                               ; 0x2A76F0  [739] (unnamed)
HdaeUiName_738:	.zero	2                               ; 0x2A76F2  [738] (unnamed)
HdaeUiName_737:	.zero	2                               ; 0x2A76F4  [737] (unnamed)
HdaeUiName_736:	.zero	2                               ; 0x2A76F6  [736] (unnamed)
HdaeUiName_735:	.zero	2                               ; 0x2A76F8  [735] (unnamed)
HdaeUiName_734:	.zero	2                               ; 0x2A76FA  [734] (unnamed)
HdaeUiName_733:	.zero	2                               ; 0x2A76FC  [733] (unnamed)
HdaeUiName_732:	.zero	2                               ; 0x2A76FE  [732] (unnamed)
HdaeUiName_731:	.zero	2                               ; 0x2A7700  [731] (unnamed)
HdaeUiName_730:	.zero	2                               ; 0x2A7702  [730] (unnamed)
HdaeUiName_729:	.zero	2                               ; 0x2A7704  [729] (unnamed)
HdaeUiName_728:	.asciz	"FILE_LOAD_A_Z"                 ; 0x2A7706  [728]
HdaeUiName_727:	.zero	2                               ; 0x2A7714  [727] (unnamed)
HdaeUiName_726:	.zero	2                               ; 0x2A7716  [726] (unnamed)
HdaeUiName_725:	.zero	2                               ; 0x2A7718  [725] (unnamed)
HdaeUiName_724:	.zero	2                               ; 0x2A771A  [724] (unnamed)
HdaeUiName_723:	.zero	2                               ; 0x2A771C  [723] (unnamed)
HdaeUiName_722:	.asciz	"SELECT_FILE_A_Z"               ; 0x2A771E  [722]
HdaeUiName_721:	.zero	2                               ; 0x2A772E  [721] (unnamed)
HdaeUiName_720:	.zero	2                               ; 0x2A7730  [720] (unnamed)
HdaeUiName_719:	.zero	2                               ; 0x2A7732  [719] (unnamed)
HdaeUiName_718:	.zero	2                               ; 0x2A7734  [718] (unnamed)
HdaeUiName_717:	.asciz	"AGAIN_HD_FORMAT_CATCH"         ; 0x2A7736  [717]
HdaeUiName_716:	.zero	2                               ; 0x2A774C  [716] (unnamed)
HdaeUiName_715:	.asciz	"AGAIN_HD_FORMAT"               ; 0x2A774E  [715]
HdaeUiName_714:	.zero	2                               ; 0x2A775E  [714] (unnamed)
HdaeUiName_713:	.zero	2                               ; 0x2A7760  [713] (unnamed)
HdaeUiName_712:	.zero	2                               ; 0x2A7762  [712] (unnamed)
HdaeUiName_711:	.zero	2                               ; 0x2A7764  [711] (unnamed)
HdaeUiName_710:	.asciz	"ERR_HD_FORMAT_CATCH"           ; 0x2A7766  [710]
HdaeUiName_709:	.zero	2                               ; 0x2A777A  [709] (unnamed)
HdaeUiName_708:	.asciz	"ERR_HD_FORMAT"                 ; 0x2A777C  [708]
HdaeUiName_707:	.zero	2                               ; 0x2A778A  [707] (unnamed)
HdaeUiName_706:	.zero	2                               ; 0x2A778C  [706] (unnamed)
HdaeUiName_705:	.asciz	"HD_PLEASE"                     ; 0x2A778E  [705]
HdaeUiName_704:	.zero	2                               ; 0x2A7798  [704] (unnamed)
HdaeUiName_703:	.zero	2                               ; 0x2A779A  [703] (unnamed)
HdaeUiName_702:	.zero	2                               ; 0x2A779C  [702] (unnamed)
HdaeUiName_701:	.ascii	"FILE_OUT_RANGE_CATCH\0\0"      ; 0x2A779E  [701]
HdaeUiName_700:	.ascii	"FILE_OUT_RANGE\0\0"            ; 0x2A77B4  [700]
HdaeUiName_699:	.zero	2                               ; 0x2A77C4  [699] (unnamed)
HdaeUiName_698:	.zero	2                               ; 0x2A77C6  [698] (unnamed)
HdaeUiName_697:	.zero	2                               ; 0x2A77C8  [697] (unnamed)
HdaeUiName_696:	.asciz	"DIR_OUT_RANGE_CATCH"           ; 0x2A77CA  [696]
HdaeUiName_695:	.asciz	"DIR_OUT_RANGE"                 ; 0x2A77DE  [695]
HdaeUiName_694:	.zero	2                               ; 0x2A77EC  [694] (unnamed)
HdaeUiName_693:	.zero	2                               ; 0x2A77EE  [693] (unnamed)
HdaeUiName_692:	.zero	2                               ; 0x2A77F0  [692] (unnamed)
HdaeUiName_691:	.zero	2                               ; 0x2A77F2  [691] (unnamed)
HdaeUiName_690:	.ascii	"ATTEN_CP_UNNAMED_CATCH\0\0"    ; 0x2A77F4  [690]
HdaeUiName_689:	.zero	2                               ; 0x2A780C  [689] (unnamed)
HdaeUiName_688:	.ascii	"ATTEN_CP_UNNAMED\0\0"          ; 0x2A780E  [688]
HdaeUiName_687:	.zero	2                               ; 0x2A7820  [687] (unnamed)
HdaeUiName_686:	.zero	2                               ; 0x2A7822  [686] (unnamed)
HdaeUiName_685:	.zero	2                               ; 0x2A7824  [685] (unnamed)
HdaeUiName_684:	.zero	2                               ; 0x2A7826  [684] (unnamed)
HdaeUiName_683:	.ascii	"ATTEN_FULL_DIR_CATCH\0\0"      ; 0x2A7828  [683]
HdaeUiName_682:	.zero	2                               ; 0x2A783E  [682] (unnamed)
HdaeUiName_681:	.ascii	"ATTEN_FULL_DIR\0\0"            ; 0x2A7840  [681]
HdaeUiName_680:	.zero	2                               ; 0x2A7850  [680] (unnamed)
HdaeUiName_679:	.zero	2                               ; 0x2A7852  [679] (unnamed)
HdaeUiName_678:	.zero	2                               ; 0x2A7854  [678] (unnamed)
HdaeUiName_677:	.ascii	"ERR_NO_HK_DATA_CATCH\0\0"      ; 0x2A7856  [677]
HdaeUiName_676:	.zero	2                               ; 0x2A786C  [676] (unnamed)
HdaeUiName_675:	.ascii	"ERR_NO_HK_DATA\0\0"            ; 0x2A786E  [675]
HdaeUiName_674:	.zero	2                               ; 0x2A787E  [674] (unnamed)
HdaeUiName_673:	.zero	2                               ; 0x2A7880  [673] (unnamed)
HdaeUiName_672:	.zero	2                               ; 0x2A7882  [672] (unnamed)
HdaeUiName_671:	.ascii	"ERR_LOAD_CATCH\0\0"            ; 0x2A7884  [671]
HdaeUiName_670:	.asciz	"ERR_LOAD_EXIT"                 ; 0x2A7894  [670]
HdaeUiName_669:	.ascii	"ERR_LOAD\0\0"                  ; 0x2A78A2  [669]
HdaeUiName_668:	.zero	2                               ; 0x2A78AC  [668] (unnamed)
HdaeUiName_667:	.zero	2                               ; 0x2A78AE  [667] (unnamed)
HdaeUiName_666:	.zero	2                               ; 0x2A78B0  [666] (unnamed)
HdaeUiName_665:	.ascii	"ERR_SAVE_CATCH\0\0"            ; 0x2A78B2  [665]
HdaeUiName_664:	.asciz	"ERR_SAVE_EXIT"                 ; 0x2A78C2  [664]
HdaeUiName_663:	.ascii	"ERR_SAVE\0\0"                  ; 0x2A78D0  [663]
HdaeUiName_662:	.zero	2                               ; 0x2A78DA  [662] (unnamed)
HdaeUiName_661:	.zero	2                               ; 0x2A78DC  [661] (unnamed)
HdaeUiName_660:	.ascii	"WAIT_TR0_RECOVER\0\0"          ; 0x2A78DE  [660]
HdaeUiName_659:	.zero	2                               ; 0x2A78F0  [659] (unnamed)
HdaeUiName_658:	.zero	2                               ; 0x2A78F2  [658] (unnamed)
HdaeUiName_657:	.zero	2                               ; 0x2A78F4  [657] (unnamed)
HdaeUiName_656:	.zero	2                               ; 0x2A78F6  [656] (unnamed)
HdaeUiName_655:	.zero	2                               ; 0x2A78F8  [655] (unnamed)
HdaeUiName_654:	.zero	2                               ; 0x2A78FA  [654] (unnamed)
HdaeUiName_653:	.zero	2                               ; 0x2A78FC  [653] (unnamed)
HdaeUiName_652:	.zero	2                               ; 0x2A78FE  [652] (unnamed)
HdaeUiName_651:	.zero	2                               ; 0x2A7900  [651] (unnamed)
HdaeUiName_650:	.zero	2                               ; 0x2A7902  [650] (unnamed)
HdaeUiName_649:	.zero	2                               ; 0x2A7904  [649] (unnamed)
HdaeUiName_648:	.zero	2                               ; 0x2A7906  [648] (unnamed)
HdaeUiName_647:	.zero	2                               ; 0x2A7908  [647] (unnamed)
HdaeUiName_646:	.zero	2                               ; 0x2A790A  [646] (unnamed)
HdaeUiName_645:	.zero	2                               ; 0x2A790C  [645] (unnamed)
HdaeUiName_644:	.zero	2                               ; 0x2A790E  [644] (unnamed)
HdaeUiName_643:	.zero	2                               ; 0x2A7910  [643] (unnamed)
HdaeUiName_642:	.zero	2                               ; 0x2A7912  [642] (unnamed)
HdaeUiName_641:	.ascii	"ABOUT_HELP\0\0"                ; 0x2A7914  [641]
HdaeUiName_640:	.zero	2                               ; 0x2A7920  [640] (unnamed)
HdaeUiName_639:	.zero	2                               ; 0x2A7922  [639] (unnamed)
HdaeUiName_638:	.zero	2                               ; 0x2A7924  [638] (unnamed)
HdaeUiName_637:	.zero	2                               ; 0x2A7926  [637] (unnamed)
HdaeUiName_636:	.zero	2                               ; 0x2A7928  [636] (unnamed)
HdaeUiName_635:	.zero	2                               ; 0x2A792A  [635] (unnamed)
HdaeUiName_634:	.asciz	"ATTEN_CPFD_MARK"               ; 0x2A792C  [634]
HdaeUiName_633:	.zero	2                               ; 0x2A793C  [633] (unnamed)
HdaeUiName_632:	.zero	2                               ; 0x2A793E  [632] (unnamed)
HdaeUiName_631:	.zero	2                               ; 0x2A7940  [631] (unnamed)
HdaeUiName_630:	.zero	2                               ; 0x2A7942  [630] (unnamed)
HdaeUiName_629:	.ascii	"ERR_HD_FSB\0\0"                ; 0x2A7944  [629]
HdaeUiName_628:	.zero	2                               ; 0x2A7950  [628] (unnamed)
HdaeUiName_627:	.zero	2                               ; 0x2A7952  [627] (unnamed)
HdaeUiName_626:	.zero	2                               ; 0x2A7954  [626] (unnamed)
HdaeUiName_625:	.zero	2                               ; 0x2A7956  [625] (unnamed)
HdaeUiName_624:	.ascii	"ERR_HD_FAT\0\0"                ; 0x2A7958  [624]
HdaeUiName_623:	.zero	2                               ; 0x2A7964  [623] (unnamed)
HdaeUiName_622:	.zero	2                               ; 0x2A7966  [622] (unnamed)
HdaeUiName_621:	.zero	2                               ; 0x2A7968  [621] (unnamed)
HdaeUiName_620:	.zero	2                               ; 0x2A796A  [620] (unnamed)
HdaeUiName_619:	.ascii	"ERR_HD_TRACK_0\0\0"            ; 0x2A796C  [619]
HdaeUiName_618:	.zero	2                               ; 0x2A797C  [618] (unnamed)
HdaeUiName_617:	.zero	2                               ; 0x2A797E  [617] (unnamed)
HdaeUiName_616:	.zero	2                               ; 0x2A7980  [616] (unnamed)
HdaeUiName_615:	.zero	2                               ; 0x2A7982  [615] (unnamed)
HdaeUiName_614:	.ascii	"ERR_HD_ID_READ\0\0"            ; 0x2A7984  [614]
HdaeUiName_613:	.zero	2                               ; 0x2A7994  [613] (unnamed)
HdaeUiName_612:	.zero	2                               ; 0x2A7996  [612] (unnamed)
HdaeUiName_611:	.zero	2                               ; 0x2A7998  [611] (unnamed)
HdaeUiName_610:	.zero	2                               ; 0x2A799A  [610] (unnamed)
HdaeUiName_609:	.asciz	"ERR_HD_READ"                   ; 0x2A799C  [609]
HdaeUiName_608:	.zero	2                               ; 0x2A79A8  [608] (unnamed)
HdaeUiName_607:	.zero	2                               ; 0x2A79AA  [607] (unnamed)
HdaeUiName_606:	.zero	2                               ; 0x2A79AC  [606] (unnamed)
HdaeUiName_605:	.zero	2                               ; 0x2A79AE  [605] (unnamed)
HdaeUiName_604:	.ascii	"ERR_HD_RESET\0\0"              ; 0x2A79B0  [604]
HdaeUiName_603:	.zero	2                               ; 0x2A79BE  [603] (unnamed)
HdaeUiName_602:	.zero	2                               ; 0x2A79C0  [602] (unnamed)
HdaeUiName_601:	.zero	2                               ; 0x2A79C2  [601] (unnamed)
HdaeUiName_600:	.zero	2                               ; 0x2A79C4  [600] (unnamed)
HdaeUiName_599:	.asciz	"ERR_HD_SRAM"                   ; 0x2A79C6  [599]
HdaeUiName_598:	.zero	2                               ; 0x2A79D2  [598] (unnamed)
HdaeUiName_597:	.zero	2                               ; 0x2A79D4  [597] (unnamed)
HdaeUiName_596:	.zero	2                               ; 0x2A79D6  [596] (unnamed)
HdaeUiName_595:	.zero	2                               ; 0x2A79D8  [595] (unnamed)
HdaeUiName_594:	.ascii	"ERR_HD_NOT_FMT\0\0"            ; 0x2A79DA  [594]
HdaeUiName_593:	.zero	2                               ; 0x2A79EA  [593] (unnamed)
HdaeUiName_592:	.zero	2                               ; 0x2A79EC  [592] (unnamed)
HdaeUiName_591:	.zero	2                               ; 0x2A79EE  [591] (unnamed)
HdaeUiName_590:	.zero	2                               ; 0x2A79F0  [590] (unnamed)
HdaeUiName_589:	.zero	2                               ; 0x2A79F2  [589] (unnamed)
HdaeUiName_588:	.zero	2                               ; 0x2A79F4  [588] (unnamed)
HdaeUiName_587:	.zero	2                               ; 0x2A79F6  [587] (unnamed)
HdaeUiName_586:	.asciz	"ATTEN_CPHD_WR"                 ; 0x2A79F8  [586]
HdaeUiName_585:	.zero	2                               ; 0x2A7A06  [585] (unnamed)
HdaeUiName_584:	.zero	2                               ; 0x2A7A08  [584] (unnamed)
HdaeUiName_583:	.zero	2                               ; 0x2A7A0A  [583] (unnamed)
HdaeUiName_582:	.zero	2                               ; 0x2A7A0C  [582] (unnamed)
HdaeUiName_581:	.zero	2                               ; 0x2A7A0E  [581] (unnamed)
HdaeUiName_580:	.asciz	"HDD_FLS_NAMING2"               ; 0x2A7A10  [580]
HdaeUiName_579:	.zero	2                               ; 0x2A7A20  [579] (unnamed)
HdaeUiName_578:	.zero	2                               ; 0x2A7A22  [578] (unnamed)
HdaeUiName_577:	.zero	2                               ; 0x2A7A24  [577] (unnamed)
HdaeUiName_576:	.zero	2                               ; 0x2A7A26  [576] (unnamed)
HdaeUiName_575:	.zero	2                               ; 0x2A7A28  [575] (unnamed)
HdaeUiName_574:	.zero	2                               ; 0x2A7A2A  [574] (unnamed)
HdaeUiName_573:	.zero	2                               ; 0x2A7A2C  [573] (unnamed)
HdaeUiName_572:	.zero	2                               ; 0x2A7A2E  [572] (unnamed)
HdaeUiName_571:	.asciz	"ATTEN_OVER_FILE"               ; 0x2A7A30  [571]
HdaeUiName_570:	.zero	2                               ; 0x2A7A40  [570] (unnamed)
HdaeUiName_569:	.zero	2                               ; 0x2A7A42  [569] (unnamed)
HdaeUiName_568:	.zero	2                               ; 0x2A7A44  [568] (unnamed)
HdaeUiName_567:	.zero	2                               ; 0x2A7A46  [567] (unnamed)
HdaeUiName_566:	.zero	2                               ; 0x2A7A48  [566] (unnamed)
HdaeUiName_565:	.zero	2                               ; 0x2A7A4A  [565] (unnamed)
HdaeUiName_564:	.zero	2                               ; 0x2A7A4C  [564] (unnamed)
HdaeUiName_563:	.zero	2                               ; 0x2A7A4E  [563] (unnamed)
HdaeUiName_562:	.zero	2                               ; 0x2A7A50  [562] (unnamed)
HdaeUiName_561:	.zero	2                               ; 0x2A7A52  [561] (unnamed)
HdaeUiName_560:	.zero	2                               ; 0x2A7A54  [560] (unnamed)
HdaeUiName_559:	.ascii	"ATTEN_DEL_FLS1\0\0"            ; 0x2A7A56  [559]
HdaeUiName_558:	.zero	2                               ; 0x2A7A66  [558] (unnamed)
HdaeUiName_557:	.zero	2                               ; 0x2A7A68  [557] (unnamed)
HdaeUiName_556:	.asciz	"DBG_MEMO_SCREEN"               ; 0x2A7A6A  [556]
HdaeUiName_555:	.zero	2                               ; 0x2A7A7A  [555] (unnamed)
HdaeUiName_554:	.ascii	"HD_INFO_LIST\0\0"              ; 0x2A7A7C  [554]
HdaeUiName_553:	.zero	2                               ; 0x2A7A8A  [553] (unnamed)
HdaeUiName_552:	.zero	2                               ; 0x2A7A8C  [552] (unnamed)
HdaeUiName_551:	.ascii	"SETUP_HDINFO\0\0"              ; 0x2A7A8E  [551]
HdaeUiName_550:	.zero	2                               ; 0x2A7A9C  [550] (unnamed)
HdaeUiName_549:	.zero	2                               ; 0x2A7A9E  [549] (unnamed)
HdaeUiName_548:	.zero	2                               ; 0x2A7AA0  [548] (unnamed)
HdaeUiName_547:	.ascii	"WAIT_HD_FORMAT\0\0"            ; 0x2A7AA2  [547]
HdaeUiName_546:	.asciz	"HD_FORMAT_CATCH"               ; 0x2A7AB2  [546]
HdaeUiName_545:	.zero	2                               ; 0x2A7AC2  [545] (unnamed)
HdaeUiName_544:	.zero	2                               ; 0x2A7AC4  [544] (unnamed)
HdaeUiName_543:	.zero	2                               ; 0x2A7AC6  [543] (unnamed)
HdaeUiName_542:	.zero	2                               ; 0x2A7AC8  [542] (unnamed)
HdaeUiName_541:	.zero	2                               ; 0x2A7ACA  [541] (unnamed)
HdaeUiName_540:	.zero	2                               ; 0x2A7ACC  [540] (unnamed)
HdaeUiName_539:	.zero	2                               ; 0x2A7ACE  [539] (unnamed)
HdaeUiName_538:	.asciz	"ATTEN_HD_FORMAT"               ; 0x2A7AD0  [538]
HdaeUiName_537:	.zero	2                               ; 0x2A7AE0  [537] (unnamed)
HdaeUiName_536:	.zero	2                               ; 0x2A7AE2  [536] (unnamed)
HdaeUiName_535:	.asciz	"WAIT_DEL_FILE"                 ; 0x2A7AE4  [535]
HdaeUiName_534:	.zero	2                               ; 0x2A7AF2  [534] (unnamed)
HdaeUiName_533:	.zero	2                               ; 0x2A7AF4  [533] (unnamed)
HdaeUiName_532:	.zero	2                               ; 0x2A7AF6  [532] (unnamed)
HdaeUiName_531:	.zero	2                               ; 0x2A7AF8  [531] (unnamed)
HdaeUiName_530:	.zero	2                               ; 0x2A7AFA  [530] (unnamed)
HdaeUiName_529:	.zero	2                               ; 0x2A7AFC  [529] (unnamed)
HdaeUiName_528:	.zero	2                               ; 0x2A7AFE  [528] (unnamed)
HdaeUiName_527:	.zero	2                               ; 0x2A7B00  [527] (unnamed)
HdaeUiName_526:	.zero	2                               ; 0x2A7B02  [526] (unnamed)
HdaeUiName_525:	.ascii	"ATTEN_DEL_FLS2\0\0"            ; 0x2A7B04  [525]
HdaeUiName_524:	.zero	2                               ; 0x2A7B14  [524] (unnamed)
HdaeUiName_523:	.zero	2                               ; 0x2A7B16  [523] (unnamed)
HdaeUiName_522:	.zero	2                               ; 0x2A7B18  [522] (unnamed)
HdaeUiName_521:	.zero	2                               ; 0x2A7B1A  [521] (unnamed)
HdaeUiName_520:	.zero	2                               ; 0x2A7B1C  [520] (unnamed)
HdaeUiName_519:	.zero	2                               ; 0x2A7B1E  [519] (unnamed)
HdaeUiName_518:	.zero	2                               ; 0x2A7B20  [518] (unnamed)
HdaeUiName_517:	.zero	2                               ; 0x2A7B22  [517] (unnamed)
HdaeUiName_516:	.ascii	"ATTEN_OVER_FLS\0\0"            ; 0x2A7B24  [516]
HdaeUiName_515:	.zero	2                               ; 0x2A7B34  [515] (unnamed)
HdaeUiName_514:	.zero	2                               ; 0x2A7B36  [514] (unnamed)
HdaeUiName_513:	.zero	2                               ; 0x2A7B38  [513] (unnamed)
HdaeUiName_512:	.zero	2                               ; 0x2A7B3A  [512] (unnamed)
HdaeUiName_511:	.zero	2                               ; 0x2A7B3C  [511] (unnamed)
HdaeUiName_510:	.zero	2                               ; 0x2A7B3E  [510] (unnamed)
HdaeUiName_509:	.zero	2                               ; 0x2A7B40  [509] (unnamed)
HdaeUiName_508:	.zero	2                               ; 0x2A7B42  [508] (unnamed)
HdaeUiName_507:	.ascii	"ATTEN_DEL_FILE\0\0"            ; 0x2A7B44  [507]
HdaeUiName_506:	.zero	2                               ; 0x2A7B54  [506] (unnamed)
HdaeUiName_505:	.zero	2                               ; 0x2A7B56  [505] (unnamed)
HdaeUiName_504:	.ascii	"WAIT_DEL_DIR\0\0"              ; 0x2A7B58  [504]
HdaeUiName_503:	.zero	2                               ; 0x2A7B66  [503] (unnamed)
HdaeUiName_502:	.zero	2                               ; 0x2A7B68  [502] (unnamed)
HdaeUiName_501:	.zero	2                               ; 0x2A7B6A  [501] (unnamed)
HdaeUiName_500:	.zero	2                               ; 0x2A7B6C  [500] (unnamed)
HdaeUiName_499:	.zero	2                               ; 0x2A7B6E  [499] (unnamed)
HdaeUiName_498:	.zero	2                               ; 0x2A7B70  [498] (unnamed)
HdaeUiName_497:	.zero	2                               ; 0x2A7B72  [497] (unnamed)
HdaeUiName_496:	.zero	2                               ; 0x2A7B74  [496] (unnamed)
HdaeUiName_495:	.asciz	"ATTEN_DEL_DIR"                 ; 0x2A7B76  [495]
HdaeUiName_494:	.ascii	"IV_HDDMENU\0\0"                ; 0x2A7B84  [494]
HdaeUiName_493:	.asciz	"HD_MENU_BMP"                   ; 0x2A7B90  [493]
HdaeUiName_492:	.ascii	"HDD_ICON_DISPLAY\0\0"          ; 0x2A7B9C  [492]
HdaeUiName_491:	.zero	2                               ; 0x2A7BAE  [491] (unnamed)
HdaeUiName_490:	.zero	2                               ; 0x2A7BB0  [490] (unnamed)
HdaeUiName_489:	.ascii	"DEL_EDIT_TLX\0\0"              ; 0x2A7BB2  [489]
HdaeUiName_488:	.zero	2                               ; 0x2A7BC0  [488] (unnamed)
HdaeUiName_487:	.zero	2                               ; 0x2A7BC2  [487] (unnamed)
HdaeUiName_486:	.zero	2                               ; 0x2A7BC4  [486] (unnamed)
HdaeUiName_485:	.zero	2                               ; 0x2A7BC6  [485] (unnamed)
HdaeUiName_484:	.zero	2                               ; 0x2A7BC8  [484] (unnamed)
HdaeUiName_483:	.zero	2                               ; 0x2A7BCA  [483] (unnamed)
HdaeUiName_482:	.zero	2                               ; 0x2A7BCC  [482] (unnamed)
HdaeUiName_481:	.zero	2                               ; 0x2A7BCE  [481] (unnamed)
HdaeUiName_480:	.zero	2                               ; 0x2A7BD0  [480] (unnamed)
HdaeUiName_479:	.zero	2                               ; 0x2A7BD2  [479] (unnamed)
HdaeUiName_478:	.zero	2                               ; 0x2A7BD4  [478] (unnamed)
HdaeUiName_477:	.zero	2                               ; 0x2A7BD6  [477] (unnamed)
HdaeUiName_476:	.zero	2                               ; 0x2A7BD8  [476] (unnamed)
HdaeUiName_475:	.zero	2                               ; 0x2A7BDA  [475] (unnamed)
HdaeUiName_474:	.zero	2                               ; 0x2A7BDC  [474] (unnamed)
HdaeUiName_473:	.zero	2                               ; 0x2A7BDE  [473] (unnamed)
HdaeUiName_472:	.zero	2                               ; 0x2A7BE0  [472] (unnamed)
HdaeUiName_471:	.zero	2                               ; 0x2A7BE2  [471] (unnamed)
HdaeUiName_470:	.asciz	"DEL_EDIT_MD"                   ; 0x2A7BE4  [470]
HdaeUiName_469:	.ascii	"DEL_EDIT_RCM\0\0"              ; 0x2A7BF0  [469]
HdaeUiName_468:	.ascii	"DEL_EDIT_MSP\0\0"              ; 0x2A7BFE  [468]
HdaeUiName_467:	.asciz	"DEL_EDIT_TM"                   ; 0x2A7C0C  [467]
HdaeUiName_466:	.ascii	"DEL_EDIT_CMP\0\0"              ; 0x2A7C18  [466]
HdaeUiName_465:	.ascii	"DEL_EDIT_SQT\0\0"              ; 0x2A7C26  [465]
HdaeUiName_464:	.ascii	"DEL_EDIT_PMT\0\0"              ; 0x2A7C34  [464]
HdaeUiName_463:	.ascii	"DEL_EDIT_LSW\0\0"              ; 0x2A7C42  [463]
HdaeUiName_462:	.zero	2                               ; 0x2A7C50  [462] (unnamed)
HdaeUiName_461:	.zero	2                               ; 0x2A7C52  [461] (unnamed)
HdaeUiName_460:	.zero	2                               ; 0x2A7C54  [460] (unnamed)
HdaeUiName_459:	.zero	2                               ; 0x2A7C56  [459] (unnamed)
HdaeUiName_458:	.zero	2                               ; 0x2A7C58  [458] (unnamed)
HdaeUiName_457:	.zero	2                               ; 0x2A7C5A  [457] (unnamed)
HdaeUiName_456:	.zero	2                               ; 0x2A7C5C  [456] (unnamed)
HdaeUiName_455:	.zero	2                               ; 0x2A7C5E  [455] (unnamed)
HdaeUiName_454:	.zero	2                               ; 0x2A7C60  [454] (unnamed)
HdaeUiName_453:	.zero	2                               ; 0x2A7C62  [453] (unnamed)
HdaeUiName_452:	.zero	2                               ; 0x2A7C64  [452] (unnamed)
HdaeUiName_451:	.zero	2                               ; 0x2A7C66  [451] (unnamed)
HdaeUiName_450:	.asciz	"FILE_DEL_SCREEN"               ; 0x2A7C68  [450]
HdaeUiName_449:	.ascii	"HddNamingLabel\0\0"            ; 0x2A7C78  [449]
HdaeUiName_448:	.zero	2                               ; 0x2A7C88  [448] (unnamed)
HdaeUiName_447:	.zero	2                               ; 0x2A7C8A  [447] (unnamed)
HdaeUiName_446:	.zero	2                               ; 0x2A7C8C  [446] (unnamed)
HdaeUiName_445:	.asciz	"HddNamingSymbol"               ; 0x2A7C8E  [445]
HdaeUiName_444:	.ascii	"HddNamingabc\0\0"              ; 0x2A7C9E  [444]
HdaeUiName_443:	.ascii	"HddNamingABC\0\0"              ; 0x2A7CAC  [443]
HdaeUiName_442:	.ascii	"HddNamingCursorBox\0\0"        ; 0x2A7CBA  [442]
HdaeUiName_441:	.zero	2                               ; 0x2A7CCE  [441] (unnamed)
HdaeUiName_440:	.zero	2                               ; 0x2A7CD0  [440] (unnamed)
HdaeUiName_439:	.zero	2                               ; 0x2A7CD2  [439] (unnamed)
HdaeUiName_438:	.zero	2                               ; 0x2A7CD4  [438] (unnamed)
HdaeUiName_437:	.zero	2                               ; 0x2A7CD6  [437] (unnamed)
HdaeUiName_436:	.zero	2                               ; 0x2A7CD8  [436] (unnamed)
HdaeUiName_435:	.zero	2                               ; 0x2A7CDA  [435] (unnamed)
HdaeUiName_434:	.zero	2                               ; 0x2A7CDC  [434] (unnamed)
HdaeUiName_433:	.zero	2                               ; 0x2A7CDE  [433] (unnamed)
HdaeUiName_432:	.zero	2                               ; 0x2A7CE0  [432] (unnamed)
HdaeUiName_431:	.zero	2                               ; 0x2A7CE2  [431] (unnamed)
HdaeUiName_430:	.asciz	"HddNamingWindow"               ; 0x2A7CE4  [430]
HdaeUiName_429:	.zero	2                               ; 0x2A7CF4  [429] (unnamed)
HdaeUiName_428:	.zero	2                               ; 0x2A7CF6  [428] (unnamed)
HdaeUiName_427:	.zero	2                               ; 0x2A7CF8  [427] (unnamed)
HdaeUiName_426:	.ascii	"RAM_EDIT_TLX\0\0"              ; 0x2A7CFA  [426]
HdaeUiName_425:	.zero	2                               ; 0x2A7D08  [425] (unnamed)
HdaeUiName_424:	.zero	2                               ; 0x2A7D0A  [424] (unnamed)
HdaeUiName_423:	.zero	2                               ; 0x2A7D0C  [423] (unnamed)
HdaeUiName_422:	.zero	2                               ; 0x2A7D0E  [422] (unnamed)
HdaeUiName_421:	.zero	2                               ; 0x2A7D10  [421] (unnamed)
HdaeUiName_420:	.zero	2                               ; 0x2A7D12  [420] (unnamed)
HdaeUiName_419:	.zero	2                               ; 0x2A7D14  [419] (unnamed)
HdaeUiName_418:	.zero	2                               ; 0x2A7D16  [418] (unnamed)
HdaeUiName_417:	.zero	2                               ; 0x2A7D18  [417] (unnamed)
HdaeUiName_416:	.zero	2                               ; 0x2A7D1A  [416] (unnamed)
HdaeUiName_415:	.zero	2                               ; 0x2A7D1C  [415] (unnamed)
HdaeUiName_414:	.zero	2                               ; 0x2A7D1E  [414] (unnamed)
HdaeUiName_413:	.zero	2                               ; 0x2A7D20  [413] (unnamed)
HdaeUiName_412:	.asciz	"RAM_EDIT_MD"                   ; 0x2A7D22  [412]
HdaeUiName_411:	.ascii	"RAM_EDIT_RCM\0\0"              ; 0x2A7D2E  [411]
HdaeUiName_410:	.ascii	"RAM_EDIT_MSP\0\0"              ; 0x2A7D3C  [410]
HdaeUiName_409:	.asciz	"RAM_EDIT_TM"                   ; 0x2A7D4A  [409]
HdaeUiName_408:	.ascii	"RAM_EDIT_SQT\0\0"              ; 0x2A7D56  [408]
HdaeUiName_407:	.ascii	"RAM_EDIT_PMT\0\0"              ; 0x2A7D64  [407]
HdaeUiName_406:	.ascii	"RAM_EDIT_LSW\0\0"              ; 0x2A7D72  [406]
HdaeUiName_405:	.zero	2                               ; 0x2A7D80  [405] (unnamed)
HdaeUiName_404:	.ascii	"RAM_EDIT_CMP\0\0"              ; 0x2A7D82  [404]
HdaeUiName_403:	.zero	2                               ; 0x2A7D90  [403] (unnamed)
HdaeUiName_402:	.zero	2                               ; 0x2A7D92  [402] (unnamed)
HdaeUiName_401:	.zero	2                               ; 0x2A7D94  [401] (unnamed)
HdaeUiName_400:	.zero	2                               ; 0x2A7D96  [400] (unnamed)
HdaeUiName_399:	.zero	2                               ; 0x2A7D98  [399] (unnamed)
HdaeUiName_398:	.zero	2                               ; 0x2A7D9A  [398] (unnamed)
HdaeUiName_397:	.zero	2                               ; 0x2A7D9C  [397] (unnamed)
HdaeUiName_396:	.zero	2                               ; 0x2A7D9E  [396] (unnamed)
HdaeUiName_395:	.zero	2                               ; 0x2A7DA0  [395] (unnamed)
HdaeUiName_394:	.zero	2                               ; 0x2A7DA2  [394] (unnamed)
HdaeUiName_393:	.zero	2                               ; 0x2A7DA4  [393] (unnamed)
HdaeUiName_392:	.zero	2                               ; 0x2A7DA6  [392] (unnamed)
HdaeUiName_391:	.zero	2                               ; 0x2A7DA8  [391] (unnamed)
HdaeUiName_390:	.zero	2                               ; 0x2A7DAA  [390] (unnamed)
HdaeUiName_389:	.zero	2                               ; 0x2A7DAC  [389] (unnamed)
HdaeUiName_388:	.zero	2                               ; 0x2A7DAE  [388] (unnamed)
HdaeUiName_387:	.zero	2                               ; 0x2A7DB0  [387] (unnamed)
HdaeUiName_386:	.asciz	"SAVE_OPT_SCREEN"               ; 0x2A7DB2  [386]
HdaeUiName_385:	.zero	2                               ; 0x2A7DC2  [385] (unnamed)
HdaeUiName_384:	.zero	2                               ; 0x2A7DC4  [384] (unnamed)
HdaeUiName_383:	.zero	2                               ; 0x2A7DC6  [383] (unnamed)
HdaeUiName_382:	.zero	2                               ; 0x2A7DC8  [382] (unnamed)
HdaeUiName_381:	.zero	2                               ; 0x2A7DCA  [381] (unnamed)
HdaeUiName_380:	.zero	2                               ; 0x2A7DCC  [380] (unnamed)
HdaeUiName_379:	.ascii	"CP_FD_DIR_NAMING\0\0"          ; 0x2A7DCE  [379]
HdaeUiName_378:	.zero	2                               ; 0x2A7DE0  [378] (unnamed)
HdaeUiName_377:	.zero	2                               ; 0x2A7DE2  [377] (unnamed)
HdaeUiName_376:	.zero	2                               ; 0x2A7DE4  [376] (unnamed)
HdaeUiName_375:	.ascii	"FLS_EDIT_OPT_BOX\0\0"          ; 0x2A7DE6  [375]
HdaeUiName_374:	.ascii	"FLS_EDIT_LOC_BOX\0\0"          ; 0x2A7DF8  [374]
HdaeUiName_373:	.zero	2                               ; 0x2A7E0A  [373] (unnamed)
HdaeUiName_372:	.zero	2                               ; 0x2A7E0C  [372] (unnamed)
HdaeUiName_371:	.zero	2                               ; 0x2A7E0E  [371] (unnamed)
HdaeUiName_370:	.zero	2                               ; 0x2A7E10  [370] (unnamed)
HdaeUiName_369:	.zero	2                               ; 0x2A7E12  [369] (unnamed)
HdaeUiName_368:	.zero	2                               ; 0x2A7E14  [368] (unnamed)
HdaeUiName_367:	.zero	2                               ; 0x2A7E16  [367] (unnamed)
HdaeUiName_366:	.zero	2                               ; 0x2A7E18  [366] (unnamed)
HdaeUiName_365:	.zero	2                               ; 0x2A7E1A  [365] (unnamed)
HdaeUiName_364:	.zero	2                               ; 0x2A7E1C  [364] (unnamed)
HdaeUiName_363:	.ascii	"FLS_EDIT_LINE1\0\0"            ; 0x2A7E1E  [363]
HdaeUiName_362:	.ascii	"FLS_EDIT_LINE2\0\0"            ; 0x2A7E2E  [362]
HdaeUiName_361:	.asciz	"FLS_EDIT_LIST_BOX"             ; 0x2A7E3E  [361]
HdaeUiName_360:	.zero	2                               ; 0x2A7E50  [360] (unnamed)
HdaeUiName_359:	.zero	2                               ; 0x2A7E52  [359] (unnamed)
HdaeUiName_358:	.asciz	"FLS_EDIT_NAME_BOX"             ; 0x2A7E54  [358]
HdaeUiName_357:	.zero	2                               ; 0x2A7E66  [357] (unnamed)
HdaeUiName_356:	.zero	2                               ; 0x2A7E68  [356] (unnamed)
HdaeUiName_355:	.ascii	"FLS_EDIT\0\0"                  ; 0x2A7E6A  [355]
HdaeUiName_354:	.zero	2                               ; 0x2A7E74  [354] (unnamed)
HdaeUiName_353:	.zero	2                               ; 0x2A7E76  [353] (unnamed)
HdaeUiName_352:	.asciz	"FLS_FILE_SEL_OPTBOX"           ; 0x2A7E78  [352]
HdaeUiName_351:	.zero	2                               ; 0x2A7E8C  [351] (unnamed)
HdaeUiName_350:	.zero	2                               ; 0x2A7E8E  [350] (unnamed)
HdaeUiName_349:	.zero	2                               ; 0x2A7E90  [349] (unnamed)
HdaeUiName_348:	.ascii	"FLS_FILE_SEL_LISTBOX\0\0"      ; 0x2A7E92  [348]
HdaeUiName_347:	.asciz	"FLS_FILE_SEL_DIRBOX"           ; 0x2A7EA8  [347]
HdaeUiName_346:	.zero	2                               ; 0x2A7EBC  [346] (unnamed)
HdaeUiName_345:	.ascii	"FLS_FILE_SEL\0\0"              ; 0x2A7EBE  [345]
HdaeUiName_344:	.zero	2                               ; 0x2A7ECC  [344] (unnamed)
HdaeUiName_343:	.zero	2                               ; 0x2A7ECE  [343] (unnamed)
HdaeUiName_342:	.zero	2                               ; 0x2A7ED0  [342] (unnamed)
HdaeUiName_341:	.zero	2                               ; 0x2A7ED2  [341] (unnamed)
HdaeUiName_340:	.zero	2                               ; 0x2A7ED4  [340] (unnamed)
HdaeUiName_339:	.zero	2                               ; 0x2A7ED6  [339] (unnamed)
HdaeUiName_338:	.zero	2                               ; 0x2A7ED8  [338] (unnamed)
HdaeUiName_337:	.asciz	"FLS_DIR_BOX"                   ; 0x2A7EDA  [337]
HdaeUiName_336:	.zero	2                               ; 0x2A7EE6  [336] (unnamed)
HdaeUiName_335:	.zero	2                               ; 0x2A7EE8  [335] (unnamed)
HdaeUiName_334:	.asciz	"FLS_DIR_SEL"                   ; 0x2A7EEA  [334]
HdaeUiName_333:	.zero	2                               ; 0x2A7EF6  [333] (unnamed)
HdaeUiName_332:	.zero	2                               ; 0x2A7EF8  [332] (unnamed)
HdaeUiName_331:	.zero	2                               ; 0x2A7EFA  [331] (unnamed)
HdaeUiName_330:	.ascii	"FLS_LOAD_LINE2\0\0"            ; 0x2A7EFC  [330]
HdaeUiName_329:	.ascii	"FLS_LOAD_LINE1\0\0"            ; 0x2A7F0C  [329]
HdaeUiName_328:	.ascii	"FLS_FILE_BOX\0\0"              ; 0x2A7F1C  [328]
HdaeUiName_327:	.zero	2                               ; 0x2A7F2A  [327] (unnamed)
HdaeUiName_326:	.zero	2                               ; 0x2A7F2C  [326] (unnamed)
HdaeUiName_325:	.ascii	"FLS_NAME_BOX\0\0"              ; 0x2A7F2E  [325]
HdaeUiName_324:	.asciz	"FLS_LOC_BOX"                   ; 0x2A7F3C  [324]
HdaeUiName_323:	.asciz	"FLS_OPT_BOX"                   ; 0x2A7F48  [323]
HdaeUiName_322:	.zero	2                               ; 0x2A7F54  [322] (unnamed)
HdaeUiName_321:	.zero	2                               ; 0x2A7F56  [321] (unnamed)
HdaeUiName_320:	.zero	2                               ; 0x2A7F58  [320] (unnamed)
HdaeUiName_319:	.zero	2                               ; 0x2A7F5A  [319] (unnamed)
HdaeUiName_318:	.asciz	"FLS_FILE_LOAD_SW_EDIT"         ; 0x2A7F5C  [318]
HdaeUiName_317:	.zero	2                               ; 0x2A7F72  [317] (unnamed)
HdaeUiName_316:	.zero	2                               ; 0x2A7F74  [316] (unnamed)
HdaeUiName_315:	.zero	2                               ; 0x2A7F76  [315] (unnamed)
HdaeUiName_314:	.asciz	"FLS_FILE_LOAD"                 ; 0x2A7F78  [314]
HdaeUiName_313:	.zero	2                               ; 0x2A7F86  [313] (unnamed)
HdaeUiName_312:	.zero	2                               ; 0x2A7F88  [312] (unnamed)
HdaeUiName_311:	.zero	2                               ; 0x2A7F8A  [311] (unnamed)
HdaeUiName_310:	.zero	2                               ; 0x2A7F8C  [310] (unnamed)
HdaeUiName_309:	.zero	2                               ; 0x2A7F8E  [309] (unnamed)
HdaeUiName_308:	.ascii	"HDD_FLS_NAMING\0\0"            ; 0x2A7F90  [308]
HdaeUiName_307:	.zero	2                               ; 0x2A7FA0  [307] (unnamed)
HdaeUiName_306:	.zero	2                               ; 0x2A7FA2  [306] (unnamed)
HdaeUiName_305:	.zero	2                               ; 0x2A7FA4  [305] (unnamed)
HdaeUiName_304:	.zero	2                               ; 0x2A7FA6  [304] (unnamed)
HdaeUiName_303:	.zero	2                               ; 0x2A7FA8  [303] (unnamed)
HdaeUiName_302:	.zero	2                               ; 0x2A7FAA  [302] (unnamed)
HdaeUiName_301:	.zero	2                               ; 0x2A7FAC  [301] (unnamed)
HdaeUiName_300:	.zero	2                               ; 0x2A7FAE  [300] (unnamed)
HdaeUiName_299:	.zero	2                               ; 0x2A7FB0  [299] (unnamed)
HdaeUiName_298:	.zero	2                               ; 0x2A7FB2  [298] (unnamed)
HdaeUiName_297:	.zero	2                               ; 0x2A7FB4  [297] (unnamed)
HdaeUiName_296:	.zero	2                               ; 0x2A7FB6  [296] (unnamed)
HdaeUiName_295:	.zero	2                               ; 0x2A7FB8  [295] (unnamed)
HdaeUiName_294:	.zero	2                               ; 0x2A7FBA  [294] (unnamed)
HdaeUiName_293:	.zero	2                               ; 0x2A7FBC  [293] (unnamed)
HdaeUiName_292:	.zero	2                               ; 0x2A7FBE  [292] (unnamed)
HdaeUiName_291:	.zero	2                               ; 0x2A7FC0  [291] (unnamed)
HdaeUiName_290:	.zero	2                               ; 0x2A7FC2  [290] (unnamed)
HdaeUiName_289:	.zero	2                               ; 0x2A7FC4  [289] (unnamed)
HdaeUiName_288:	.zero	2                               ; 0x2A7FC6  [288] (unnamed)
HdaeUiName_287:	.zero	2                               ; 0x2A7FC8  [287] (unnamed)
HdaeUiName_286:	.zero	2                               ; 0x2A7FCA  [286] (unnamed)
HdaeUiName_285:	.zero	2                               ; 0x2A7FCC  [285] (unnamed)
HdaeUiName_284:	.zero	2                               ; 0x2A7FCE  [284] (unnamed)
HdaeUiName_283:	.zero	2                               ; 0x2A7FD0  [283] (unnamed)
HdaeUiName_282:	.zero	2                               ; 0x2A7FD2  [282] (unnamed)
HdaeUiName_281:	.zero	2                               ; 0x2A7FD4  [281] (unnamed)
HdaeUiName_280:	.zero	2                               ; 0x2A7FD6  [280] (unnamed)
HdaeUiName_279:	.zero	2                               ; 0x2A7FD8  [279] (unnamed)
HdaeUiName_278:	.zero	2                               ; 0x2A7FDA  [278] (unnamed)
HdaeUiName_277:	.zero	2                               ; 0x2A7FDC  [277] (unnamed)
HdaeUiName_276:	.zero	2                               ; 0x2A7FDE  [276] (unnamed)
HdaeUiName_275:	.zero	2                               ; 0x2A7FE0  [275] (unnamed)
HdaeUiName_274:	.zero	2                               ; 0x2A7FE2  [274] (unnamed)
HdaeUiName_273:	.zero	2                               ; 0x2A7FE4  [273] (unnamed)
HdaeUiName_272:	.asciz	"HD_FILE_LOAD_P2"               ; 0x2A7FE6  [272]
HdaeUiName_271:	.zero	2                               ; 0x2A7FF6  [271] (unnamed)
HdaeUiName_270:	.zero	2                               ; 0x2A7FF8  [270] (unnamed)
HdaeUiName_269:	.asciz	"HD_FILE_LOAD_SW_DELFILE"       ; 0x2A7FFA  [269]
HdaeUiName_268:	.zero	2                               ; 0x2A8012  [268] (unnamed)
HdaeUiName_267:	.zero	2                               ; 0x2A8014  [267] (unnamed)
HdaeUiName_266:	.asciz	"HD_FILE_LOAD_SW_DEL"           ; 0x2A8016  [266]
HdaeUiName_265:	.zero	2                               ; 0x2A802A  [265] (unnamed)
HdaeUiName_264:	.zero	2                               ; 0x2A802C  [264] (unnamed)
HdaeUiName_263:	.zero	2                               ; 0x2A802E  [263] (unnamed)
HdaeUiName_262:	.zero	2                               ; 0x2A8030  [262] (unnamed)
HdaeUiName_261:	.zero	2                               ; 0x2A8032  [261] (unnamed)
HdaeUiName_260:	.ascii	"FILE_LOAD_DIRBOX\0\0"          ; 0x2A8034  [260]
HdaeUiName_259:	.ascii	"HD_FILE_LIST\0\0"              ; 0x2A8046  [259]
HdaeUiName_258:	.ascii	"HD_FILE_OPTION\0\0"            ; 0x2A8054  [258]
HdaeUiName_257:	.zero	2                               ; 0x2A8064  [257] (unnamed)
HdaeUiName_256:	.ascii	"HD_FILE_LOAD_SW_SAVE\0\0"      ; 0x2A8066  [256]
HdaeUiName_255:	.asciz	"HD_FILE_LOAD_P1"               ; 0x2A807C  [255]
HdaeUiName_254:	.zero	2                               ; 0x2A808C  [254] (unnamed)
HdaeUiName_253:	.zero	2                               ; 0x2A808E  [253] (unnamed)
HdaeUiName_252:	.zero	2                               ; 0x2A8090  [252] (unnamed)
HdaeUiName_251:	.asciz	"SEL_FLS"                       ; 0x2A8092  [251]
HdaeUiName_250:	.zero	2                               ; 0x2A809A  [250] (unnamed)
HdaeUiName_249:	.ascii	"FLS_SELECT_SW_EDIT\0\0"        ; 0x2A809C  [249]
HdaeUiName_248:	.asciz	"FLS_SEL"                       ; 0x2A80B0  [248]
HdaeUiName_247:	.zero	2                               ; 0x2A80B8  [247] (unnamed)
HdaeUiName_246:	.zero	2                               ; 0x2A80BA  [246] (unnamed)
HdaeUiName_245:	.zero	2                               ; 0x2A80BC  [245] (unnamed)
HdaeUiName_244:	.zero	2                               ; 0x2A80BE  [244] (unnamed)
HdaeUiName_243:	.zero	2                               ; 0x2A80C0  [243] (unnamed)
HdaeUiName_242:	.zero	2                               ; 0x2A80C2  [242] (unnamed)
HdaeUiName_241:	.zero	2                               ; 0x2A80C4  [241] (unnamed)
HdaeUiName_240:	.ascii	"FLS_SELECT\0\0"                ; 0x2A80C6  [240]
HdaeUiName_239:	.zero	2                               ; 0x2A80D2  [239] (unnamed)
HdaeUiName_238:	.zero	2                               ; 0x2A80D4  [238] (unnamed)
HdaeUiName_237:	.zero	2                               ; 0x2A80D6  [237] (unnamed)
HdaeUiName_236:	.zero	2                               ; 0x2A80D8  [236] (unnamed)
HdaeUiName_235:	.zero	2                               ; 0x2A80DA  [235] (unnamed)
HdaeUiName_234:	.zero	2                               ; 0x2A80DC  [234] (unnamed)
HdaeUiName_233:	.zero	2                               ; 0x2A80DE  [233] (unnamed)
HdaeUiName_232:	.zero	2                               ; 0x2A80E0  [232] (unnamed)
HdaeUiName_231:	.zero	2                               ; 0x2A80E2  [231] (unnamed)
HdaeUiName_230:	.ascii	"CP_FD_DIRBOX\0\0"              ; 0x2A80E4  [230]
HdaeUiName_229:	.zero	2                               ; 0x2A80F2  [229] (unnamed)
HdaeUiName_228:	.zero	2                               ; 0x2A80F4  [228] (unnamed)
HdaeUiName_227:	.zero	2                               ; 0x2A80F6  [227] (unnamed)
HdaeUiName_226:	.ascii	"CP_FD_DIRSEL\0\0"              ; 0x2A80F8  [226]
HdaeUiName_225:	.zero	2                               ; 0x2A8106  [225] (unnamed)
HdaeUiName_224:	.ascii	"CP_FD_HDALLSEL\0\0"            ; 0x2A8108  [224]
HdaeUiName_223:	.zero	2                               ; 0x2A8118  [223] (unnamed)
HdaeUiName_222:	.ascii	"CP_FD_VOLLABEL\0\0"            ; 0x2A811A  [222]
HdaeUiName_221:	.zero	2                               ; 0x2A812A  [221] (unnamed)
HdaeUiName_220:	.asciz	"CP_FD_HDSWSEL"                 ; 0x2A812C  [220]
HdaeUiName_219:	.zero	2                               ; 0x2A813A  [219] (unnamed)
HdaeUiName_218:	.ascii	"CP_FD_HDSWTO\0\0"              ; 0x2A813C  [218]
HdaeUiName_217:	.asciz	"CP_FD_LINE1"                   ; 0x2A814A  [217]
HdaeUiName_216:	.asciz	"CP_FD_LINE2"                   ; 0x2A8156  [216]
HdaeUiName_215:	.ascii	"CP_FD_LIST\0\0"                ; 0x2A8162  [215]
HdaeUiName_214:	.zero	2                               ; 0x2A816E  [214] (unnamed)
HdaeUiName_213:	.zero	2                               ; 0x2A8170  [213] (unnamed)
HdaeUiName_212:	.zero	2                               ; 0x2A8172  [212] (unnamed)
HdaeUiName_211:	.zero	2                               ; 0x2A8174  [211] (unnamed)
HdaeUiName_210:	.asciz	"CP_FD"                         ; 0x2A8176  [210]
HdaeUiName_209:	.zero	2                               ; 0x2A817C  [209] (unnamed)
HdaeUiName_208:	.zero	2                               ; 0x2A817E  [208] (unnamed)
HdaeUiName_207:	.zero	2                               ; 0x2A8180  [207] (unnamed)
HdaeUiName_206:	.zero	2                               ; 0x2A8182  [206] (unnamed)
HdaeUiName_205:	.zero	2                               ; 0x2A8184  [205] (unnamed)
HdaeUiName_204:	.zero	2                               ; 0x2A8186  [204] (unnamed)
HdaeUiName_203:	.zero	2                               ; 0x2A8188  [203] (unnamed)
HdaeUiName_202:	.zero	2                               ; 0x2A818A  [202] (unnamed)
HdaeUiName_201:	.zero	2                               ; 0x2A818C  [201] (unnamed)
HdaeUiName_200:	.zero	2                               ; 0x2A818E  [200] (unnamed)
HdaeUiName_199:	.zero	2                               ; 0x2A8190  [199] (unnamed)
HdaeUiName_198:	.zero	2                               ; 0x2A8192  [198] (unnamed)
HdaeUiName_197:	.zero	2                               ; 0x2A8194  [197] (unnamed)
HdaeUiName_196:	.zero	2                               ; 0x2A8196  [196] (unnamed)
HdaeUiName_195:	.zero	2                               ; 0x2A8198  [195] (unnamed)
HdaeUiName_194:	.zero	2                               ; 0x2A819A  [194] (unnamed)
HdaeUiName_193:	.zero	2                               ; 0x2A819C  [193] (unnamed)
HdaeUiName_192:	.zero	2                               ; 0x2A819E  [192] (unnamed)
HdaeUiName_191:	.zero	2                               ; 0x2A81A0  [191] (unnamed)
HdaeUiName_190:	.zero	2                               ; 0x2A81A2  [190] (unnamed)
HdaeUiName_189:	.zero	2                               ; 0x2A81A4  [189] (unnamed)
HdaeUiName_188:	.zero	2                               ; 0x2A81A6  [188] (unnamed)
HdaeUiName_187:	.zero	2                               ; 0x2A81A8  [187] (unnamed)
HdaeUiName_186:	.zero	2                               ; 0x2A81AA  [186] (unnamed)
HdaeUiName_185:	.zero	2                               ; 0x2A81AC  [185] (unnamed)
HdaeUiName_184:	.zero	2                               ; 0x2A81AE  [184] (unnamed)
HdaeUiName_183:	.zero	2                               ; 0x2A81B0  [183] (unnamed)
HdaeUiName_182:	.zero	2                               ; 0x2A81B2  [182] (unnamed)
HdaeUiName_181:	.zero	2                               ; 0x2A81B4  [181] (unnamed)
HdaeUiName_180:	.zero	2                               ; 0x2A81B6  [180] (unnamed)
HdaeUiName_179:	.zero	2                               ; 0x2A81B8  [179] (unnamed)
HdaeUiName_178:	.zero	2                               ; 0x2A81BA  [178] (unnamed)
HdaeUiName_177:	.zero	2                               ; 0x2A81BC  [177] (unnamed)
HdaeUiName_176:	.zero	2                               ; 0x2A81BE  [176] (unnamed)
HdaeUiName_175:	.ascii	"LBN_P2\0\0"                    ; 0x2A81C0  [175]
HdaeUiName_174:	.zero	2                               ; 0x2A81C8  [174] (unnamed)
HdaeUiName_173:	.zero	2                               ; 0x2A81CA  [173] (unnamed)
HdaeUiName_172:	.zero	2                               ; 0x2A81CC  [172] (unnamed)
HdaeUiName_171:	.ascii	"LBN_FILENAME_BOX\0\0"          ; 0x2A81CE  [171]
HdaeUiName_170:	.ascii	"LBN_FILENO_BOX\0\0"            ; 0x2A81E0  [170]
HdaeUiName_169:	.asciz	"LBN_DIRNAME_BOX"               ; 0x2A81F0  [169]
HdaeUiName_168:	.asciz	"LBN_DIRNO_BOX"                 ; 0x2A8200  [168]
HdaeUiName_167:	.zero	2                               ; 0x2A820E  [167] (unnamed)
HdaeUiName_166:	.zero	2                               ; 0x2A8210  [166] (unnamed)
HdaeUiName_165:	.zero	2                               ; 0x2A8212  [165] (unnamed)
HdaeUiName_164:	.zero	2                               ; 0x2A8214  [164] (unnamed)
HdaeUiName_163:	.zero	2                               ; 0x2A8216  [163] (unnamed)
HdaeUiName_162:	.zero	2                               ; 0x2A8218  [162] (unnamed)
HdaeUiName_161:	.zero	2                               ; 0x2A821A  [161] (unnamed)
HdaeUiName_160:	.zero	2                               ; 0x2A821C  [160] (unnamed)
HdaeUiName_159:	.zero	2                               ; 0x2A821E  [159] (unnamed)
HdaeUiName_158:	.zero	2                               ; 0x2A8220  [158] (unnamed)
HdaeUiName_157:	.zero	2                               ; 0x2A8222  [157] (unnamed)
HdaeUiName_156:	.zero	2                               ; 0x2A8224  [156] (unnamed)
HdaeUiName_155:	.zero	2                               ; 0x2A8226  [155] (unnamed)
HdaeUiName_154:	.zero	2                               ; 0x2A8228  [154] (unnamed)
HdaeUiName_153:	.zero	2                               ; 0x2A822A  [153] (unnamed)
HdaeUiName_152:	.ascii	"LBN_OPTION\0\0"                ; 0x2A822C  [152]
HdaeUiName_151:	.zero	2                               ; 0x2A8238  [151] (unnamed)
HdaeUiName_150:	.zero	2                               ; 0x2A823A  [150] (unnamed)
HdaeUiName_149:	.ascii	"LBN_P1\0\0"                    ; 0x2A823C  [149]
HdaeUiName_148:	.zero	2                               ; 0x2A8244  [148] (unnamed)
HdaeUiName_147:	.zero	2                               ; 0x2A8246  [147] (unnamed)
HdaeUiName_146:	.zero	2                               ; 0x2A8248  [146] (unnamed)
HdaeUiName_145:	.zero	2                               ; 0x2A824A  [145] (unnamed)
HdaeUiName_144:	.zero	2                               ; 0x2A824C  [144] (unnamed)
HdaeUiName_143:	.asciz	"LOAD_BY_NUM"                   ; 0x2A824E  [143]
HdaeUiName_142:	.zero	2                               ; 0x2A825A  [142] (unnamed)
HdaeUiName_141:	.zero	2                               ; 0x2A825C  [141] (unnamed)
HdaeUiName_140:	.zero	2                               ; 0x2A825E  [140] (unnamed)
HdaeUiName_139:	.zero	2                               ; 0x2A8260  [139] (unnamed)
HdaeUiName_138:	.zero	2                               ; 0x2A8262  [138] (unnamed)
HdaeUiName_137:	.zero	2                               ; 0x2A8264  [137] (unnamed)
HdaeUiName_136:	.zero	2                               ; 0x2A8266  [136] (unnamed)
HdaeUiName_135:	.zero	2                               ; 0x2A8268  [135] (unnamed)
HdaeUiName_134:	.zero	2                               ; 0x2A826A  [134] (unnamed)
HdaeUiName_133:	.ascii	"OUTPUT_SETTING\0\0"            ; 0x2A826C  [133]
HdaeUiName_132:	.zero	2                               ; 0x2A827C  [132] (unnamed)
HdaeUiName_131:	.zero	2                               ; 0x2A827E  [131] (unnamed)
HdaeUiName_130:	.zero	2                               ; 0x2A8280  [130] (unnamed)
HdaeUiName_129:	.zero	2                               ; 0x2A8282  [129] (unnamed)
HdaeUiName_128:	.ascii	"SW_HD_FORMAT\0\0"              ; 0x2A8284  [128]
HdaeUiName_127:	.zero	2                               ; 0x2A8292  [127] (unnamed)
HdaeUiName_126:	.zero	2                               ; 0x2A8294  [126] (unnamed)
HdaeUiName_125:	.zero	2                               ; 0x2A8296  [125] (unnamed)
HdaeUiName_124:	.zero	2                               ; 0x2A8298  [124] (unnamed)
HdaeUiName_123:	.zero	2                               ; 0x2A829A  [123] (unnamed)
HdaeUiName_122:	.ascii	"SETUP_TOOLS_P2\0\0"            ; 0x2A829C  [122]
HdaeUiName_121:	.zero	2                               ; 0x2A82AC  [121] (unnamed)
HdaeUiName_120:	.zero	2                               ; 0x2A82AE  [120] (unnamed)
HdaeUiName_119:	.zero	2                               ; 0x2A82B0  [119] (unnamed)
HdaeUiName_118:	.zero	2                               ; 0x2A82B2  [118] (unnamed)
HdaeUiName_117:	.zero	2                               ; 0x2A82B4  [117] (unnamed)
HdaeUiName_116:	.zero	2                               ; 0x2A82B6  [116] (unnamed)
HdaeUiName_115:	.zero	2                               ; 0x2A82B8  [115] (unnamed)
HdaeUiName_114:	.zero	2                               ; 0x2A82BA  [114] (unnamed)
HdaeUiName_113:	.zero	2                               ; 0x2A82BC  [113] (unnamed)
HdaeUiName_112:	.zero	2                               ; 0x2A82BE  [112] (unnamed)
HdaeUiName_111:	.zero	2                               ; 0x2A82C0  [111] (unnamed)
HdaeUiName_110:	.ascii	"SETUP_TOOLS_P1\0\0"            ; 0x2A82C2  [110]
HdaeUiName_109:	.zero	2                               ; 0x2A82D2  [109] (unnamed)
HdaeUiName_108:	.zero	2                               ; 0x2A82D4  [108] (unnamed)
HdaeUiName_107:	.zero	2                               ; 0x2A82D6  [107] (unnamed)
HdaeUiName_106:	.zero	2                               ; 0x2A82D8  [106] (unnamed)
HdaeUiName_105:	.zero	2                               ; 0x2A82DA  [105] (unnamed)
HdaeUiName_104:	.asciz	"PP_STATUS"                     ; 0x2A82DC  [104]
HdaeUiName_103:	.zero	2                               ; 0x2A82E6  [103] (unnamed)
HdaeUiName_102:	.ascii	"PC_DATA_LINK\0\0"              ; 0x2A82E8  [102]
HdaeUiName_101:	.zero	2                               ; 0x2A82F6  [101] (unnamed)
HdaeUiName_100:	.zero	2                               ; 0x2A82F8  [100] (unnamed)
HdaeUiName_099:	.zero	2                               ; 0x2A82FA  [ 99] (unnamed)
HdaeUiName_098:	.zero	2                               ; 0x2A82FC  [ 98] (unnamed)
HdaeUiName_097:	.zero	2                               ; 0x2A82FE  [ 97] (unnamed)
HdaeUiName_096:	.asciz	"HD_UTIL"                       ; 0x2A8300  [ 96]
HdaeUiName_095:	.zero	2                               ; 0x2A8308  [ 95] (unnamed)
HdaeUiName_094:	.asciz	"HD_PLEASE_WIN"                 ; 0x2A830A  [ 94]
HdaeUiName_093:	.zero	2                               ; 0x2A8318  [ 93] (unnamed)
HdaeUiName_092:	.zero	2                               ; 0x2A831A  [ 92] (unnamed)
HdaeUiName_091:	.zero	2                               ; 0x2A831C  [ 91] (unnamed)
HdaeUiName_090:	.zero	2                               ; 0x2A831E  [ 90] (unnamed)
HdaeUiName_089:	.zero	2                               ; 0x2A8320  [ 89] (unnamed)
HdaeUiName_088:	.ascii	"HDD_DIR_NAMING\0\0"            ; 0x2A8322  [ 88]
HdaeUiName_087:	.ascii	"HD_FILE_NAME\0\0"              ; 0x2A8332  [ 87]
HdaeUiName_086:	.zero	2                               ; 0x2A8340  [ 86] (unnamed)
HdaeUiName_085:	.zero	2                               ; 0x2A8342  [ 85] (unnamed)
HdaeUiName_084:	.zero	2                               ; 0x2A8344  [ 84] (unnamed)
HdaeUiName_083:	.zero	2                               ; 0x2A8346  [ 83] (unnamed)
HdaeUiName_082:	.zero	2                               ; 0x2A8348  [ 82] (unnamed)
HdaeUiName_081:	.zero	2                               ; 0x2A834A  [ 81] (unnamed)
HdaeUiName_080:	.zero	2                               ; 0x2A834C  [ 80] (unnamed)
HdaeUiName_079:	.zero	2                               ; 0x2A834E  [ 79] (unnamed)
HdaeUiName_078:	.asciz	"HDD_FILE_NAMING"               ; 0x2A8350  [ 78]
HdaeUiName_077:	.ascii	"HDD_SW\0\0"                    ; 0x2A8360  [ 77]
HdaeUiName_076:	.asciz	"FD_SW"                         ; 0x2A8368  [ 76]
HdaeUiName_075:	.ascii	"PPORT_SW\0\0"                  ; 0x2A836E  [ 75]
HdaeUiName_074:	.zero	2                               ; 0x2A8378  [ 74] (unnamed)
HdaeUiName_073:	.ascii	"RUN_STOP\0\0"                  ; 0x2A837A  [ 73]
HdaeUiName_072:	.zero	2                               ; 0x2A8384  [ 72] (unnamed)
HdaeUiName_071:	.zero	2                               ; 0x2A8386  [ 71] (unnamed)
HdaeUiName_070:	.zero	2                               ; 0x2A8388  [ 70] (unnamed)
HdaeUiName_069:	.asciz	"HARD_TEST"                     ; 0x2A838A  [ 69]
HdaeUiName_068:	.zero	2                               ; 0x2A8394  [ 68] (unnamed)
HdaeUiName_067:	.zero	2                               ; 0x2A8396  [ 67] (unnamed)
HdaeUiName_066:	.zero	2                               ; 0x2A8398  [ 66] (unnamed)
HdaeUiName_065:	.zero	2                               ; 0x2A839A  [ 65] (unnamed)
HdaeUiName_064:	.zero	2                               ; 0x2A839C  [ 64] (unnamed)
HdaeUiName_063:	.zero	2                               ; 0x2A839E  [ 63] (unnamed)
HdaeUiName_062:	.zero	2                               ; 0x2A83A0  [ 62] (unnamed)
HdaeUiName_061:	.zero	2                               ; 0x2A83A2  [ 61] (unnamed)
HdaeUiName_060:	.zero	2                               ; 0x2A83A4  [ 60] (unnamed)
HdaeUiName_059:	.zero	2                               ; 0x2A83A6  [ 59] (unnamed)
HdaeUiName_058:	.ascii	"FD_FILE_SELECT\0\0"            ; 0x2A83A8  [ 58]
HdaeUiName_057:	.zero	2                               ; 0x2A83B8  [ 57] (unnamed)
HdaeUiName_056:	.zero	2                               ; 0x2A83BA  [ 56] (unnamed)
HdaeUiName_055:	.zero	2                               ; 0x2A83BC  [ 55] (unnamed)
HdaeUiName_054:	.zero	2                               ; 0x2A83BE  [ 54] (unnamed)
HdaeUiName_053:	.zero	2                               ; 0x2A83C0  [ 53] (unnamed)
HdaeUiName_052:	.zero	2                               ; 0x2A83C2  [ 52] (unnamed)
HdaeUiName_051:	.zero	2                               ; 0x2A83C4  [ 51] (unnamed)
HdaeUiName_050:	.zero	2                               ; 0x2A83C6  [ 50] (unnamed)
HdaeUiName_049:	.asciz	"SELECT_DIR2"                   ; 0x2A83C8  [ 49]
HdaeUiName_048:	.zero	2                               ; 0x2A83D4  [ 48] (unnamed)
HdaeUiName_047:	.zero	2                               ; 0x2A83D6  [ 47] (unnamed)
HdaeUiName_046:	.zero	2                               ; 0x2A83D8  [ 46] (unnamed)
HdaeUiName_045:	.zero	2                               ; 0x2A83DA  [ 45] (unnamed)
HdaeUiName_044:	.ascii	"SELECT_DIR_SW_EDIT\0\0"        ; 0x2A83DC  [ 44]
HdaeUiName_043:	.zero	2                               ; 0x2A83F0  [ 43] (unnamed)
HdaeUiName_042:	.zero	2                               ; 0x2A83F2  [ 42] (unnamed)
HdaeUiName_041:	.zero	2                               ; 0x2A83F4  [ 41] (unnamed)
HdaeUiName_040:	.zero	2                               ; 0x2A83F6  [ 40] (unnamed)
HdaeUiName_039:	.zero	2                               ; 0x2A83F8  [ 39] (unnamed)
HdaeUiName_038:	.zero	2                               ; 0x2A83FA  [ 38] (unnamed)
HdaeUiName_037:	.asciz	"SEL_DIR"                       ; 0x2A83FC  [ 37]
HdaeUiName_036:	.zero	2                               ; 0x2A8404  [ 36] (unnamed)
HdaeUiName_035:	.zero	2                               ; 0x2A8406  [ 35] (unnamed)
HdaeUiName_034:	.ascii	"SELECT_DIR\0\0"                ; 0x2A8408  [ 34]
HdaeUiName_033:	.zero	2                               ; 0x2A8414  [ 33] (unnamed)
HdaeUiName_032:	.zero	2                               ; 0x2A8416  [ 32] (unnamed)
HdaeUiName_031:	.zero	2                               ; 0x2A8418  [ 31] (unnamed)
HdaeUiName_030:	.zero	2                               ; 0x2A841A  [ 30] (unnamed)
HdaeUiName_029:	.zero	2                               ; 0x2A841C  [ 29] (unnamed)
HdaeUiName_028:	.zero	2                               ; 0x2A841E  [ 28] (unnamed)
HdaeUiName_027:	.ascii	"HD_LOAD_OPTION\0\0"            ; 0x2A8420  [ 27]
HdaeUiName_026:	.ascii	"HD_FILE_LOAD\0\0"              ; 0x2A8430  [ 26]
HdaeUiName_025:	.zero	2                               ; 0x2A843E  [ 25] (unnamed)
HdaeUiName_024:	.asciz	"SELECT_FILE"                   ; 0x2A8440  [ 24]
HdaeUiName_023:	.zero	2                               ; 0x2A844C  [ 23] (unnamed)
HdaeUiName_022:	.zero	2                               ; 0x2A844E  [ 22] (unnamed)
HdaeUiName_021:	.zero	2                               ; 0x2A8450  [ 21] (unnamed)
HdaeUiName_020:	.zero	2                               ; 0x2A8452  [ 20] (unnamed)
HdaeUiName_019:	.ascii	"SETUPS_TOOLS\0\0"              ; 0x2A8454  [ 19]
HdaeUiName_018:	.zero	2                               ; 0x2A8462  [ 18] (unnamed)
HdaeUiName_017:	.zero	2                               ; 0x2A8464  [ 17] (unnamed)
HdaeUiName_016:	.zero	2                               ; 0x2A8466  [ 16] (unnamed)
HdaeUiName_015:	.zero	2                               ; 0x2A8468  [ 15] (unnamed)
HdaeUiName_014:	.zero	2                               ; 0x2A846A  [ 14] (unnamed)
HdaeUiName_013:	.zero	2                               ; 0x2A846C  [ 13] (unnamed)
HdaeUiName_012:	.zero	2                               ; 0x2A846E  [ 12] (unnamed)
HdaeUiName_011:	.zero	2                               ; 0x2A8470  [ 11] (unnamed)
HdaeUiName_010:	.asciz	"HARD_DISK_OPT"                 ; 0x2A8472  [ 10]
HdaeUiName_009:	.zero	2                               ; 0x2A8480  [  9] (unnamed)
HdaeUiName_008:	.zero	2                               ; 0x2A8482  [  8] (unnamed)
HdaeUiName_007:	.zero	2                               ; 0x2A8484  [  7] (unnamed)
HdaeUiName_006:	.zero	2                               ; 0x2A8486  [  6] (unnamed)
HdaeUiName_005:	.zero	2                               ; 0x2A8488  [  5] (unnamed)
HdaeUiName_004:	.zero	2                               ; 0x2A848A  [  4] (unnamed)
HdaeUiName_003:	.zero	2                               ; 0x2A848C  [  3] (unnamed)
HdaeUiName_002:	.zero	2                               ; 0x2A848E  [  2] (unnamed)
HdaeUiName_001:	.zero	2                               ; 0x2A8490  [  1] (unnamed)
HdaeUiName_000:	.asciz	"HDDMENU"                       ; 0x2A8492  [  0]


; ============================================================================
; HD-AE5000 GRAPHICS BANK -- 256-colour palettes and 8bpp indexed bitmaps
; ROM 0x2A849A - 0x2E1C81.  (A fifth palette/bitmap pair, the boot splash,
; sits further down at 0x2E5DCE - 0x2F8DCD under HDAE5000_Palette_Data.)
;
; Layout rule, taken from the copy code inside HDAE5000_UiState_Reset and
; [the addresses below (0x2804BB..) are in the title-screen procedures
;  HDAE5000_TtlScreenRProc / _TtlScreenR2Proc / _TtlScreenR3Proc, which sat in
;  the conversion region once labelled Register_Frame -- now the small
;  HDAE5000_UiState_Reset]
; confirmed byte-wise over the whole region: every bitmap is immediately
; preceded by its own palette, with no padding between the two.
;   * a palette is 0x400 bytes = 256 RGBX entries.  Byte 3 of every entry is
;     0x00 in all five palettes of this ROM (checked exhaustively, 5 x 256).
;   * a full-screen bitmap is 0x12C00 bytes = 320 x 240 at 8 bits per pixel.
;
; The firmware never moves a full-screen bitmap in one go.  It issues two
; 0x9600-byte MemCopy calls (top half -> 0x056800, bottom half -> 0x05FE00)
; and then a 0x400-byte copy of the palette -> 0x069400.  Those hard-coded
; source addresses are the primary evidence for the boundaries below:
;
;   0x2804BB  lda XWA,0x2A898E   0x9600 -> 0x056800   ] bitmap 1, top half
;   0x2804CE  lda XWA,0x2B1F8E   0x9600 -> 0x05FE00   ] bitmap 1, bottom half
;   0x2804E1  lda XWA,0x2A858E   0x0400 -> 0x069400   ] palette 1
;   0x280599 / 0x2805AC / 0x2805BF   same shape: bitmap 2 halves + palette 2
;   0x280677 / 0x28068A / 0x28069D   same shape: bitmap 3 halves + palette 3
;   0x280753  reloads palette 2 on its own (0x400 -> 0x069400)
;
; The lookup routines hand the same bases, plus the dimensions, to the main
; CPU (request type A1 = base address, A2 = width, A3 = height):
;
;   0x28032A  HDAE5000_Alloc_Memory_1 -> 0x2A898E, 0x140 (320) x 0xF0 (240)
;   0x280357  HDAE5000_Alloc_Memory_2 -> 0x2BB98E, 0x140 x 0xF0
;   0x280384  HDAE5000_Alloc_Memory_3 -> 0x2CE98E, 0x140 x 0xF0
;   0x2803B1  HDAE5000_BitmapHdd_icon -> 0x2E198E, 0x1B (27) x 0x1B (27)
;   0x28F55F  HDAE5000_Alloc_Memory   -> 0x2E61CE, 0x140 x 0xF0 (boot splash)
;
; Only the fourth of these carries a name from the firmware: it is entry 39 of
; HDAE5000_ObjHandler_Table and the parallel HDAE5000_ObjName_Table entry reads
; "BitmapHdd_icon".  The other four appear in no registry table, so they keep
; the Alloc_Memory_* labels for now -- they allocate nothing either.
;
; RETIRED LABEL -- HDAE5000_Font_Data, "Font bitmap data (large block)",
; formerly covering 0x2BA1A6-0x2E1C81.  It was wrong twice over: the region
; holds no font data at all (it is three palette+bitmap pairs and an icon),
; and 0x2BA1A6 falls 0x11818 bytes INSIDE bitmap 1, so the old slice cut a
; picture in half and the following slice began mid-picture.  The old name is
; kept in this comment only, so that greps for it still land here.
; ============================================================================

HDAE5000_GFX_INIT_PARAMS:	; 0x2A849A
	; MISNOMER retained for cross-reference (it is the name the ASL mirror
	; and symbols/hdae5000_symbols_reference.txt already use).  This is not
	; a graphics parameter block: it is the NUL-terminated name table for
	; the HD-AE5000 screens and switch-catch handlers.  "TT_HDDEXT" is
	; passed by the lda at 0x2802E4; the other fourteen names are reached
	; through the descending 32-bit pointer table at 0x2F9F96..0x2F9FD1,
	; inside HDAE5000_Init_Data.  Pointer -> string:
	;   0x2F9F96 -> 0x2A8580   0x2F9F9A -> 0x2A8570   0x2F9F9E -> 0x2A855E
	;   0x2F9FA2 -> 0x2A854A   0x2F9FA6 -> 0x2A853A   0x2F9FAA -> 0x2A852A
	;   0x2F9FAE -> 0x2A851C   0x2F9FB2 -> 0x2A850E   0x2F9FB6 -> 0x2A84FE
	;   0x2F9FBA -> 0x2A84EC   0x2F9FBE -> 0x2A84DC   0x2F9FC2 -> 0x2A84C6
	;   0x2F9FC6 -> 0x2A84B6   0x2F9FCA -> 0x2A84A6   0x2F9FCE -> 0x2A84A4
	.asciz "TT_HDDEXT"		; 0x2A849A  (from 0x2802E4)
	.byte 0x00			; 0x2A84A4  empty name, target of 0x2F9FCE
	.byte 0x00			; 0x2A84A5  pad
	.asciz "FileLoadSwCatch"	; 0x2A84A6
	.asciz "HDDTitleSwCatch"	; 0x2A84B6
	.asciz "CopyToHDDirSelScreen"	; 0x2A84C6
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "CopyToHDScreen"	; 0x2A84DC
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "FlsFileSelScreen"	; 0x2A84EC
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "FlsDirSelScreen"	; 0x2A84FE
	.asciz "FlsEditScreen"		; 0x2A850E
	.asciz "FlsLoadScreen"		; 0x2A851C
	.asciz "SelectFlsScreen"	; 0x2A852A
	.asciz "SetupP2SwCatch"	; 0x2A853A
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "FILE_Naming_Screen"	; 0x2A854A
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "FILE_LOAD_Screen"	; 0x2A855E
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SEL_DIR_Screen"	; 0x2A8570
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "HDAETitleFunc"		; 0x2A8580

HDAE5000_Palette_TitleLogo:	; 0x2A858E
	; 0x400 B = 256 RGBX entries, 205 distinct colours.  Copied to 0x069400
	; by the lda at 0x2804E1.  Byte-identical to HDAE5000_Palette_DriveMech
	; (0x2BB58E) -- the two title frames share one palette.
	; Built from images/HDAE5000_Palette_Logo.txt by scripts/build/hdae5000_images.py.
	; Was: .incbin "includes/code_29af2d_2fffff.bin", 54881, 1024
	.incbin "includes/generated/HDAE5000_Palette_Logo.bin"

HDAE5000_Bitmap_TitleLogo:	; 0x2A898E
	; 320 x 240 @ 8bpp = 0x12C00 B.  The "HD-AE5000" wordmark embossed over
	; a photograph of a bare hard-disk mechanism.  Moved as two halves,
	; 0x2A898E -> 0x056800 and 0x2B1F8E -> 0x05FE00.  Already extracted as
	; hdae5000/images/HDAE5000_Logo.bin (byte-identical to this slice).
	; Built from images/HDAE5000_Logo.png by scripts/build/hdae5000_images.py.
	; Was: .incbin "includes/code_29af2d_2fffff.bin", 55905, 76800
	.incbin "includes/generated/HDAE5000_Logo.bin"

HDAE5000_Palette_DriveMech:	; 0x2BB58E
	; 0x400 B = 256 RGBX entries.  Copied to 0x069400 by 0x2805BF, and again
	; on its own by 0x280753.  Byte-identical to HDAE5000_Palette_TitleLogo.
	; Built from images/HDAE5000_Palette_Hands.txt by scripts/build/hdae5000_images.py.
	; Was: .incbin "includes/code_29af2d_2fffff.bin", 132705, 1024
	.incbin "includes/generated/HDAE5000_Palette_Hands.bin"

HDAE5000_Bitmap_DriveMech:	; 0x2BB98E
	; 320 x 240 @ 8bpp.  The same drive-mechanism photograph WITHOUT the
	; wordmark -- the second frame of the title sequence.  Halves at
	; 0x2BB98E and 0x2C4F8E.  Extracted as images/HDAE5000_Hands.bin, whose
	; "Hands operating HD-AE5000 unit" caption is wrong: no hands appear in
	; the picture (see the hdae-docs / gallery follow-up).
	; Built from images/HDAE5000_Hands.png by scripts/build/hdae5000_images.py.
	; Was: .incbin "includes/code_29af2d_2fffff.bin", 133729, 76800
	.incbin "includes/generated/HDAE5000_Hands.bin"

HDAE5000_Palette_FilePanel:	; 0x2CE58E
	; 0x400 B = 256 RGBX entries but only 110 distinct colours: a long grey
	; ramp plus the blue stone texture used by the panel.  Copied to
	; 0x069400 by 0x28069D.
	; Built from images/HDAE5000_Palette_FilePanel.txt by scripts/build/hdae5000_images.py.
	; Was: .incbin "includes/code_29af2d_2fffff.bin", 210529, 1024
	.incbin "includes/generated/HDAE5000_Palette_FilePanel.bin"

HDAE5000_Bitmap_FilePanel:	; 0x2CE98E
	; 320 x 240 @ 8bpp.  The file-selection panel background: three sunken
	; list wells over a blue stone fill, with the grey scroll strip along
	; the bottom.  Halves at 0x2CE98E and 0x2D7F8E.  Already extracted as
	; images/HDAE5000_FilePanel.bin.
	; Built from images/HDAE5000_FilePanel.png by scripts/build/hdae5000_images.py.
	; Was: .incbin "includes/code_29af2d_2fffff.bin", 211553, 76800
	.incbin "includes/generated/HDAE5000_FilePanel.bin"

HDAE5000_Palette_HddIcon:	; 0x2E158E
	; 0x400 B = 256 RGBX entries, all 256 distinct -- the Windows halftone
	; palette.  It has no lda site of its own in this ROM; it pairs with the
	; icon that follows by the same "palette immediately before the bitmap"
	; rule as the four pairs above, and the pairing is visually decisive:
	; the icon uses only indices 0/1/3/7/248/251/252/255 (the Windows
	; reserved entries at both ends) and is legible with this palette only.
	; Extracted as images/HDAE5000_Palette.bin.
	; Built from images/HDAE5000_Palette_Icon.txt by scripts/build/hdae5000_images.py.
	; Was: .incbin "includes/code_29af2d_2fffff.bin", 288353, 1024
	.incbin "includes/generated/HDAE5000_Palette_Icon.bin"

HDAE5000_Bitmap_HddIcon:	; 0x2E198E
	; 27 x 27 @ 8bpp with a 28-byte row stride (one 0x00 pad byte at the end
	; of every row) = 756 B: the hard-disk-platter-and-head icon.  The
	; 27 x 27 geometry is HDAE5000_BitmapHdd_icon (0x2803B1) returning 0x1B
	; for BOTH the A2 (width) and A3 (height) requests.
	; NOTE hdae5000/images/HDAE5000_Icon.bin is 784 B: its extraction
	; assumed 28 x 28 and over-reads 28 bytes into HDAE5000_Config_Strings.
	; Built from images/HDAE5000_Icon.png by scripts/build/hdae5000_images.py.
	; Was: .incbin "includes/code_29af2d_2fffff.bin", 289377, 756
	.incbin "includes/generated/HDAE5000_Icon.bin"

; ============================================================================
; HD-AE5000 PROGRAM .RODATA, 0x2E1C82-0x2E3703 (the C program's read-only data)
; Rebuilt object by object by scripts/generators/gen_hdae5000_rodata.py: every
; object starts at an address the code names (lda / ld # / ld (mem) / add #
; operands and pushw 0x002e/low pairs) or that a pointer table here points
; at, and its note names the routines that read it.  String-pointer tables
; are `.long <label>`; the compiled `switch` tables (their own headers) are
; kept from scripts/converters/hdae5000_switch_tables.py.  This replaces six
; coarse blocks named by guess (HDAE5000_Config_Strings, _Test_Strings,
; _Dir_Strings, _Char_Tables, _Path_Strings, _UI_Icons) whose bytes were
; typed as text throughout.
; ============================================================================
HDAE5000_Str_V206i:	; 0x2E1C82
	; read by CopyVersionString at 0x28B20D (ld #, pushed operand)
	.asciz "V2.06i"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_TypeSel_TemplateAllNo:	; 0x2E1C8A
	; read by FILE_LOAD_Screen, HDDNamingCheck, SaveOptSwEventCatch at 0x283E0A (lda operand)
	; a part-selection record template (HDAE5000_TypeSel_Init copies 12 bytes: u16 mask, nine part flags, pad): mask 0, every flag 1 ("NO ")
	.byte 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00
HDAE5000_TypeSel_TemplateBlank:	; 0x2E1C96
	; read by FILE_LOAD_Screen, FlsFileSelScreen, LBNLoadSwCatch, Lbn_StepDigit, Lbn_TypeDigit, UiState_Reset at 0x2803E5 (ld #, lda operand)
	; a part-selection record template: mask 0, every flag 0 ("---")
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
HDAE5000_Lbn_BlockTemplate:	; 0x2E1CA2
	; read by UiState_Reset at 0x2803D7 (ld # operand)
	; the 10-byte load-by-number block copied to 0x22AA58 by HDAE5000_UiState_Reset (5 words, all 0)
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
HDAE5000_Str_Blank3Tab:	; 0x2E1CAC
	; read by Lbn_ShowEntry at 0x287104 (lda operand)
	.asciz "   \t"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Blank16Tab:	; 0x2E1CB2
	; read by Lbn_ShowEntry at 0x287117 (lda operand)
	.asciz "                \t"
HDAE5000_Str_Blank3Tab_Lbn_ShowEntry:	; 0x2E1CC4
	; read by Lbn_ShowEntry at 0x28712A (lda operand)
	.asciz "   \t"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Blank26Tab:	; 0x2E1CCA
	; read by Lbn_ShowEntry at 0x287140 (lda operand)
	.asciz "                          \t"
HDAE5000_Str_Blank12Tab:	; 0x2E1CE6
	; read by FdList_Clear at 0x282D31 (lda operand)
	.asciz "            \t"
HDAE5000_FdList_RowsTemplate:	; 0x2E1CF4
	; read by FdList_Clear at 0x282D89 (lda operand)
	.asciz "01:        \t02:        \t03:        \t04:        \t05:        \t06:        \t07:        \t08:        \t09:        \t10:        \t11:        \t12:        \t13:        \t14:        \t15:        \t16:        \t17:        \t18:        \t19:        \t20:        \t"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_STATUS:	; 0x2E1DE6
	; read by HDAETitleFunc at 0x2835EB (lda operand)
	.asciz "STATUS:                        \t"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_DelOpt_TemplateBlank:	; 0x2E1E08
	; read by DelOptSwEventCatch, DelOpt_InitFromSong at 0x28A577 (lda operand)
	; the delete-option record template: mask 0, every flag 0 ("---")
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
HDAE5000_TextPtrs_Chr2D2D2D_OFF_DEL:	; 0x2E1E14, 3 x .long -> string
	; read by DelCmpEditCheck, DelLswEditCheck, DelMdEditCheck, DelMspEditCheck, DelOpt_ShowFlags, DelPmtEditCheck, DelRcmEditCheck, DelSqtEditCheck, DelTlxEditCheck, DelTmEditCheck at 0x28A2FA (ld #, lda operand); 3 string pointers, 4 bytes each, entry i at +4*i
	.long	HDAE5000_Str_Chr2D2D2D
	.long	HDAE5000_Str_OFF
	.long	HDAE5000_Str_DEL
HDAE5000_Str_DEL:	; 0x2E1E20
	; pointed at by entry 2 of HDAE5000_TextPtrs_Chr2D2D2D_OFF_DEL, a table read by DelCmpEditCheck, DelLswEditCheck, DelMdEditCheck, DelMspEditCheck, DelOpt_ShowFlags, DelPmtEditCheck, DelRcmEditCheck, DelSqtEditCheck, DelTlxEditCheck, DelTmEditCheck
	.asciz "DEL"
HDAE5000_Str_OFF:	; 0x2E1E24
	; pointed at by entry 1 of HDAE5000_TextPtrs_Chr2D2D2D_OFF_DEL, a table read by DelCmpEditCheck, DelLswEditCheck, DelMdEditCheck, DelMspEditCheck, DelOpt_ShowFlags, DelPmtEditCheck, DelRcmEditCheck, DelSqtEditCheck, DelTlxEditCheck, DelTmEditCheck
	.asciz "OFF"
HDAE5000_Str_Chr2D2D2D:	; 0x2E1E28
	; pointed at by entry 0 of HDAE5000_TextPtrs_Chr2D2D2D_OFF_DEL, a table read by DelCmpEditCheck, DelLswEditCheck, DelMdEditCheck, DelMspEditCheck, DelOpt_ShowFlags, DelPmtEditCheck, DelRcmEditCheck, DelSqtEditCheck, DelTlxEditCheck, DelTmEditCheck
	.asciz "---"
HDAE5000_Str_050354:	; 0x2E1E2C
	; read by FormatDialog_CodeDigit at 0x286617 (pushed operand)
	.asciz "050354"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_965768:	; 0x2E1E34
	; read by FormatDialog_CodeDigit at 0x286631 (pushed operand)
	.asciz "965768"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_TextPtrs_OFF_ON:	; 0x2E1E3C, 2 x .long -> string
	; read by TitleInfo_Build, WriteConfirmEditCheck, WriteProtectEditCheck at 0x283313 (ld #, lda operand); 2 string pointers, 4 bytes each, entry i at +4*i
	.long	HDAE5000_Str_OFF_2
	.long	HDAE5000_Str_ON
HDAE5000_Str_ON:	; 0x2E1E44
	; pointed at by entry 1 of HDAE5000_TextPtrs_OFF_ON, a table read by TitleInfo_Build, WriteConfirmEditCheck, WriteProtectEditCheck
	.asciz "ON "
HDAE5000_Str_OFF_2:	; 0x2E1E48
	; pointed at by entry 0 of HDAE5000_TextPtrs_OFF_ON, a table read by TitleInfo_Build, WriteConfirmEditCheck, WriteProtectEditCheck
	.asciz "OFF"
HDAE5000_TextPtrs_01Selectlist0203040506070809:	; 0x2E1E4C, 1 x .long -> string
	; read by SelectListProc at 0x280AB3 (ld (mem) operand); 1 string pointer, 4 bytes each, entry i at +4*i
	.long	HDAE5000_SelectList_Text
HDAE5000_SelectList_Text:	; 0x2E1E50
	; pointed at by entry 0 of HDAE5000_TextPtrs_01Selectlist0203040506070809, a table read by SelectListProc
	.asciz "01:SelectList\t02\t03\t04\t05\t06\t07\t08\t09\t10\t11\t12\t13\t14\t15\t16\t17\t18\t19\t20\t21\t22\t23\t24\t25\t26\t27\t28\t29\t30"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_DebugTime:	; 0x2E1EB6
	; read by DbMemoClProc at 0x2812CA (lda operand)
	.asciz "Debug Time!"
HDAE5000_TextPtrs_ABC123_Abc123_Chr202123242526:	; 0x2E1EC2, 3 x .long -> string
	; read by AcHddNamingWindowProc at 0x28228E (ld # operand); 3 string pointers, 4 bytes each, entry i at +4*i
	.long	HDAE5000_Str_ABC123
	.long	HDAE5000_Str_Abc123
	.long	HDAE5000_Str_Chr202123242526
HDAE5000_Str_Chr202123242526:	; 0x2E1ECE
	; pointed at by entry 2 of HDAE5000_TextPtrs_ABC123_Abc123_Chr202123242526, a table read by AcHddNamingWindowProc
	.asciz " !#$%&?.... "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Abc123:	; 0x2E1EDC
	; pointed at by entry 1 of HDAE5000_TextPtrs_ABC123_Abc123_Chr202123242526, a table read by AcHddNamingWindowProc
	.asciz "abc...123..."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_ABC123:	; 0x2E1EEA
	; pointed at by entry 0 of HDAE5000_TextPtrs_ABC123_Abc123_Chr202123242526, a table read by AcHddNamingWindowProc
	.asciz "ABC...123..."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_TextPtrs_A_to_SPC:	; 0x2E1EF8, 38 x .long -> string
	; pointed at by entry 0 of HDAE5000_TablePtrs_AcHddNamingWindowProc, a table read by AcHddNamingWindowProc; 38 string pointers, 4 bytes each, entry i at +4*i
	.long	HDAE5000_Str_A
	.long	HDAE5000_Str_B
	.long	HDAE5000_Str_C
	.long	HDAE5000_Str_D
	.long	HDAE5000_Str_E
	.long	HDAE5000_Str_F
	.long	HDAE5000_Str_G
	.long	HDAE5000_Str_H
	.long	HDAE5000_Str_I
	.long	HDAE5000_Str_J
	.long	HDAE5000_Str_K
	.long	HDAE5000_Str_L
	.long	HDAE5000_Str_M
	.long	HDAE5000_Str_N
	.long	HDAE5000_Str_O
	.long	HDAE5000_Str_P
	.long	HDAE5000_Str_Q
	.long	HDAE5000_Str_R
	.long	HDAE5000_Str_S
	.long	HDAE5000_Str_T
	.long	HDAE5000_Str_U
	.long	HDAE5000_Str_V
	.long	HDAE5000_Str_W
	.long	HDAE5000_Str_X
	.long	HDAE5000_Str_Y
	.long	HDAE5000_Str_Z
	.long	HDAE5000_Str_Chr5F
	.long	HDAE5000_Str_0
	.long	HDAE5000_Str_1
	.long	HDAE5000_Str_2
	.long	HDAE5000_Str_3
	.long	HDAE5000_Str_4
	.long	HDAE5000_Str_5
	.long	HDAE5000_Str_6
	.long	HDAE5000_Str_7
	.long	HDAE5000_Str_8
	.long	HDAE5000_Str_9
	.long	HDAE5000_Str_SPC
	.byte 0x94, 0x1f
	.asciz "."
	.zero 2
HDAE5000_Str_SPC:	; 0x2E1F96
	; pointed at by entry 37 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "SPC"
HDAE5000_Str_9:	; 0x2E1F9A
	; pointed at by entry 36 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "9"
HDAE5000_Str_8:	; 0x2E1F9C
	; pointed at by entry 35 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "8"
HDAE5000_Str_7:	; 0x2E1F9E
	; pointed at by entry 34 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "7"
HDAE5000_Str_6:	; 0x2E1FA0
	; pointed at by entry 33 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "6"
HDAE5000_Str_5:	; 0x2E1FA2
	; pointed at by entry 32 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "5"
HDAE5000_Str_4:	; 0x2E1FA4
	; pointed at by entry 31 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "4"
HDAE5000_Str_3:	; 0x2E1FA6
	; pointed at by entry 30 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "3"
HDAE5000_Str_2:	; 0x2E1FA8
	; pointed at by entry 29 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "2"
HDAE5000_Str_1:	; 0x2E1FAA
	; pointed at by entry 28 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "1"
HDAE5000_Str_0:	; 0x2E1FAC
	; pointed at by entry 27 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "0"
HDAE5000_Str_Chr5F:	; 0x2E1FAE
	; pointed at by entry 26 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "_"
HDAE5000_Str_Z:	; 0x2E1FB0
	; pointed at by entry 25 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "Z"
HDAE5000_Str_Y:	; 0x2E1FB2
	; pointed at by entry 24 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "Y"
HDAE5000_Str_X:	; 0x2E1FB4
	; pointed at by entry 23 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "X"
HDAE5000_Str_W:	; 0x2E1FB6
	; pointed at by entry 22 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "W"
HDAE5000_Str_V:	; 0x2E1FB8
	; pointed at by entry 21 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "V"
HDAE5000_Str_U:	; 0x2E1FBA
	; pointed at by entry 20 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "U"
HDAE5000_Str_T:	; 0x2E1FBC
	; pointed at by entry 19 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "T"
HDAE5000_Str_S:	; 0x2E1FBE
	; pointed at by entry 18 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "S"
HDAE5000_Str_R:	; 0x2E1FC0
	; pointed at by entry 17 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "R"
HDAE5000_Str_Q:	; 0x2E1FC2
	; pointed at by entry 16 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "Q"
HDAE5000_Str_P:	; 0x2E1FC4
	; pointed at by entry 15 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "P"
HDAE5000_Str_O:	; 0x2E1FC6
	; pointed at by entry 14 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "O"
HDAE5000_Str_N:	; 0x2E1FC8
	; pointed at by entry 13 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "N"
HDAE5000_Str_M:	; 0x2E1FCA
	; pointed at by entry 12 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "M"
HDAE5000_Str_L:	; 0x2E1FCC
	; pointed at by entry 11 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "L"
HDAE5000_Str_K:	; 0x2E1FCE
	; pointed at by entry 10 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "K"
HDAE5000_Str_J:	; 0x2E1FD0
	; pointed at by entry 9 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "J"
HDAE5000_Str_I:	; 0x2E1FD2
	; pointed at by entry 8 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "I"
HDAE5000_Str_H:	; 0x2E1FD4
	; pointed at by entry 7 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "H"
HDAE5000_Str_G:	; 0x2E1FD6
	; pointed at by entry 6 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "G"
HDAE5000_Str_F:	; 0x2E1FD8
	; pointed at by entry 5 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "F"
HDAE5000_Str_E:	; 0x2E1FDA
	; pointed at by entry 4 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "E"
HDAE5000_Str_D:	; 0x2E1FDC
	; pointed at by entry 3 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "D"
HDAE5000_Str_C:	; 0x2E1FDE
	; pointed at by entry 2 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "C"
HDAE5000_Str_B:	; 0x2E1FE0
	; pointed at by entry 1 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "B"
HDAE5000_Str_A:	; 0x2E1FE2
	; pointed at by entry 0 of HDAE5000_TextPtrs_A_to_SPC
	.asciz "A"
HDAE5000_TextPtrs_A_to_SPC_2:	; 0x2E1FE4, 38 x .long -> string
	; pointed at by entry 1 of HDAE5000_TablePtrs_AcHddNamingWindowProc, a table read by AcHddNamingWindowProc; 38 string pointers, 4 bytes each, entry i at +4*i
	.long	HDAE5000_Str_A_2
	.long	HDAE5000_Str_B_2
	.long	HDAE5000_Str_C_2
	.long	HDAE5000_Str_D_2
	.long	HDAE5000_Str_E_2
	.long	HDAE5000_Str_F_2
	.long	HDAE5000_Str_G_2
	.long	HDAE5000_Str_H_2
	.long	HDAE5000_Str_I_2
	.long	HDAE5000_Str_J_2
	.long	HDAE5000_Str_K_2
	.long	HDAE5000_Str_L_2
	.long	HDAE5000_Str_M_2
	.long	HDAE5000_Str_N_2
	.long	HDAE5000_Str_O_2
	.long	HDAE5000_Str_P_2
	.long	HDAE5000_Str_Q_2
	.long	HDAE5000_Str_R_2
	.long	HDAE5000_Str_S_2
	.long	HDAE5000_Str_T_2
	.long	HDAE5000_Str_U_2
	.long	HDAE5000_Str_V_2
	.long	HDAE5000_Str_W_2
	.long	HDAE5000_Str_X_2
	.long	HDAE5000_Str_Y_2
	.long	HDAE5000_Str_Z_2
	.long	HDAE5000_Str_Chr5F_2
	.long	HDAE5000_Str_0_2
	.long	HDAE5000_Str_1_2
	.long	HDAE5000_Str_2_2
	.long	HDAE5000_Str_3_2
	.long	HDAE5000_Str_4_2
	.long	HDAE5000_Str_5_2
	.long	HDAE5000_Str_6_2
	.long	HDAE5000_Str_7_2
	.long	HDAE5000_Str_8_2
	.long	HDAE5000_Str_9_2
	.long	HDAE5000_Str_SPC_2
	.byte 0x80
	.asciz " ."
	.zero 2
HDAE5000_Str_SPC_2:	; 0x2E2082
	; pointed at by entry 37 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "SPC"
HDAE5000_Str_9_2:	; 0x2E2086
	; pointed at by entry 36 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "9"
HDAE5000_Str_8_2:	; 0x2E2088
	; pointed at by entry 35 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "8"
HDAE5000_Str_7_2:	; 0x2E208A
	; pointed at by entry 34 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "7"
HDAE5000_Str_6_2:	; 0x2E208C
	; pointed at by entry 33 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "6"
HDAE5000_Str_5_2:	; 0x2E208E
	; pointed at by entry 32 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "5"
HDAE5000_Str_4_2:	; 0x2E2090
	; pointed at by entry 31 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "4"
HDAE5000_Str_3_2:	; 0x2E2092
	; pointed at by entry 30 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "3"
HDAE5000_Str_2_2:	; 0x2E2094
	; pointed at by entry 29 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "2"
HDAE5000_Str_1_2:	; 0x2E2096
	; pointed at by entry 28 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "1"
HDAE5000_Str_0_2:	; 0x2E2098
	; pointed at by entry 27 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "0"
HDAE5000_Str_Chr5F_2:	; 0x2E209A
	; pointed at by entry 26 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "_"
HDAE5000_Str_Z_2:	; 0x2E209C
	; pointed at by entry 25 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "z"
HDAE5000_Str_Y_2:	; 0x2E209E
	; pointed at by entry 24 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "y"
HDAE5000_Str_X_2:	; 0x2E20A0
	; pointed at by entry 23 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "x"
HDAE5000_Str_W_2:	; 0x2E20A2
	; pointed at by entry 22 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "w"
HDAE5000_Str_V_2:	; 0x2E20A4
	; pointed at by entry 21 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "v"
HDAE5000_Str_U_2:	; 0x2E20A6
	; pointed at by entry 20 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "u"
HDAE5000_Str_T_2:	; 0x2E20A8
	; pointed at by entry 19 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "t"
HDAE5000_Str_S_2:	; 0x2E20AA
	; pointed at by entry 18 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "s"
HDAE5000_Str_R_2:	; 0x2E20AC
	; pointed at by entry 17 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "r"
HDAE5000_Str_Q_2:	; 0x2E20AE
	; pointed at by entry 16 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "q"
HDAE5000_Str_P_2:	; 0x2E20B0
	; pointed at by entry 15 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "p"
HDAE5000_Str_O_2:	; 0x2E20B2
	; pointed at by entry 14 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "o"
HDAE5000_Str_N_2:	; 0x2E20B4
	; pointed at by entry 13 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "n"
HDAE5000_Str_M_2:	; 0x2E20B6
	; pointed at by entry 12 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "m"
HDAE5000_Str_L_2:	; 0x2E20B8
	; pointed at by entry 11 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "l"
HDAE5000_Str_K_2:	; 0x2E20BA
	; pointed at by entry 10 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "k"
HDAE5000_Str_J_2:	; 0x2E20BC
	; pointed at by entry 9 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "j"
HDAE5000_Str_I_2:	; 0x2E20BE
	; pointed at by entry 8 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "i"
HDAE5000_Str_H_2:	; 0x2E20C0
	; pointed at by entry 7 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "h"
HDAE5000_Str_G_2:	; 0x2E20C2
	; pointed at by entry 6 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "g"
HDAE5000_Str_F_2:	; 0x2E20C4
	; pointed at by entry 5 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "f"
HDAE5000_Str_E_2:	; 0x2E20C6
	; pointed at by entry 4 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "e"
HDAE5000_Str_D_2:	; 0x2E20C8
	; pointed at by entry 3 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "d"
HDAE5000_Str_C_2:	; 0x2E20CA
	; pointed at by entry 2 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "c"
HDAE5000_Str_B_2:	; 0x2E20CC
	; pointed at by entry 1 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "b"
HDAE5000_Str_A_2:	; 0x2E20CE
	; pointed at by entry 0 of HDAE5000_TextPtrs_A_to_SPC_2
	.asciz "a"
HDAE5000_TextPtrs_Chr21_to_Chr7D:	; 0x2E20D0, 32 x .long -> string
	; pointed at by entry 2 of HDAE5000_TablePtrs_AcHddNamingWindowProc, a table read by AcHddNamingWindowProc; also read by AcHddNamingWindowProc at 0x282435 (lda operand); 32 string pointers, 4 bytes each, entry i at +4*i
	.long	HDAE5000_Str_Chr21
	.long	HDAE5000_Str_Chr23
	.long	HDAE5000_Str_Chr24
	.long	HDAE5000_Str_Chr25
	.long	HDAE5000_Str_Chr26
	.long	HDAE5000_Str_Chr3F
	.long	HDAE5000_Str_40
	.long	HDAE5000_Str_5c
	.long	HDAE5000_Str_Chr5E
	.long	HDAE5000_Str_Chr7C
	.long	HDAE5000_Str_22
	.long	HDAE5000_Str_27
	.long	HDAE5000_Str_Chr60
	.long	HDAE5000_Str_Chr2C
	.long	HDAE5000_Str_Chr2E
	.long	HDAE5000_Str_Chr3A
	.long	HDAE5000_Str_Chr3B
	.long	HDAE5000_Str_Chr2B
	.long	HDAE5000_Str_Chr2D
	.long	HDAE5000_Str_Chr2A
	.long	HDAE5000_Str_Chr2F
	.long	HDAE5000_Str_Chr3D
	.long	HDAE5000_Str_8b
	.long	HDAE5000_Str_8d
	.long	HDAE5000_Str_Chr28
	.long	HDAE5000_Str_Chr29
	.long	HDAE5000_Str_Chr3C
	.long	HDAE5000_Str_Chr3E
	.long	HDAE5000_Str_Chr5B
	.long	HDAE5000_Str_Chr5D
	.long	HDAE5000_Str_Chr7B
	.long	HDAE5000_Str_Chr7D
	.asciz "T!."
	.zero 2
HDAE5000_Str_Chr7D:	; 0x2E2156
	; pointed at by entry 31 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "}"
HDAE5000_Str_Chr7B:	; 0x2E2158
	; pointed at by entry 30 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "{"
HDAE5000_Str_Chr5D:	; 0x2E215A
	; pointed at by entry 29 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "]"
HDAE5000_Str_Chr5B:	; 0x2E215C
	; pointed at by entry 28 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "["
HDAE5000_Str_Chr3E:	; 0x2E215E
	; pointed at by entry 27 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz ">"
HDAE5000_Str_Chr3C:	; 0x2E2160
	; pointed at by entry 26 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "<"
HDAE5000_Str_Chr29:	; 0x2E2162
	; pointed at by entry 25 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz ")"
HDAE5000_Str_Chr28:	; 0x2E2164
	; pointed at by entry 24 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "("
HDAE5000_Str_8d:	; 0x2E2166
	; pointed at by entry 23 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "~8d"
HDAE5000_Str_8b:	; 0x2E216A
	; pointed at by entry 22 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "~8b"
HDAE5000_Str_Chr3D:	; 0x2E216E
	; pointed at by entry 21 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "="
HDAE5000_Str_Chr2F:	; 0x2E2170
	; pointed at by entry 20 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "/"
HDAE5000_Str_Chr2A:	; 0x2E2172
	; pointed at by entry 19 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "*"
HDAE5000_Str_Chr2D:	; 0x2E2174
	; pointed at by entry 18 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "-"
HDAE5000_Str_Chr2B:	; 0x2E2176
	; pointed at by entry 17 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "+"
HDAE5000_Str_Chr3B:	; 0x2E2178
	; pointed at by entry 16 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz ";"
HDAE5000_Str_Chr3A:	; 0x2E217A
	; pointed at by entry 15 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz ":"
HDAE5000_Str_Chr2E:	; 0x2E217C
	; pointed at by entry 14 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "."
HDAE5000_Str_Chr2C:	; 0x2E217E
	; pointed at by entry 13 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz ","
HDAE5000_Str_Chr60:	; 0x2E2180
	; pointed at by entry 12 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "`"
HDAE5000_Str_27:	; 0x2E2182
	; pointed at by entry 11 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "~27"
HDAE5000_Str_22:	; 0x2E2186
	; pointed at by entry 10 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "~22"
HDAE5000_Str_Chr7C:	; 0x2E218A
	; pointed at by entry 9 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "|"
HDAE5000_Str_Chr5E:	; 0x2E218C
	; pointed at by entry 8 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "^"
HDAE5000_Str_5c:	; 0x2E218E
	; pointed at by entry 7 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "~5c"
HDAE5000_Str_40:	; 0x2E2192
	; pointed at by entry 6 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "~40"
HDAE5000_Str_Chr3F:	; 0x2E2196
	; pointed at by entry 5 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "?"
HDAE5000_Str_Chr26:	; 0x2E2198
	; pointed at by entry 4 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "&"
HDAE5000_Str_Chr25:	; 0x2E219A
	; pointed at by entry 3 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "%"
HDAE5000_Str_Chr24:	; 0x2E219C
	; pointed at by entry 2 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "$"
HDAE5000_Str_Chr23:	; 0x2E219E
	; pointed at by entry 1 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "#"
HDAE5000_Str_Chr21:	; 0x2E21A0
	; pointed at by entry 0 of HDAE5000_TextPtrs_Chr21_to_Chr7D, a table read by AcHddNamingWindowProc
	.asciz "!"
HDAE5000_TablePtrs_AcHddNamingWindowProc:	; 0x2E21A2, 3 x .long -> string
	; read by AcHddNamingWindowProc at 0x281764 (ld # operand); 3 string pointers, 4 bytes each, entry i at +4*i
	.long	HDAE5000_TextPtrs_A_to_SPC
	.long	HDAE5000_TextPtrs_A_to_SPC_2
	.long	HDAE5000_TextPtrs_Chr21_to_Chr7D
HDAE5000_Str_Chr25_AcHddNamingWindowProc:	; 0x2E21AE
	; read by AcHddNamingWindowProc at 0x28199F (ld # operand)
	; u16 x 6, indexed by (0x22A032 * 3 + 0x22A02A) * 2 and compared with the column (`cp iz,(xbc)`) by HDAE5000_AcHddNamingWindowProc: the last column of each name-editor character page
	.short 37, 37, 31, 36, 36, 31
HDAE5000_TextPtrs_Blank1_Chr5F:	; 0x2E21BA, 2 x .long -> string
	; read by AcHddNamingWindowProc at 0x281557 (ld # operand); 2 string pointers, 4 bytes each, entry i at +4*i
	.long	HDAE5000_Str_Blank1
	.long	HDAE5000_Str_Chr5F_3
HDAE5000_Str_Chr5F_3:	; 0x2E21C2
	; pointed at by entry 1 of HDAE5000_TextPtrs_Blank1_Chr5F, a table read by AcHddNamingWindowProc
	.asciz "_"
HDAE5000_Str_Blank1:	; 0x2E21C4
	; pointed at by entry 0 of HDAE5000_TextPtrs_Blank1_Chr5F, a table read by AcHddNamingWindowProc
	.asciz " "
;
; HDAE5000_AcHddNamingWindowProc_CaseTable (0x2E21C6, 9 x u16): the switch of HDAE5000_AcHddNamingWindowProc
; (dispatch at 0x2819FA, hd-ae5000_v2_06i.s:2472: `dec 1,xwa`, bound `cp xwa,8`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_AcHddNamingWindowProc_Case1)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_AcHddNamingWindowProc_Case1 of the case for value 1+i; 9 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_AcHddNamingWindowProc_CaseTable:
	.short	HDAE5000_AcHddNamingWindowProc_Case1 - HDAE5000_AcHddNamingWindowProc_Case1	; 1
	.short	HDAE5000_AcHddNamingWindowProc_Case2 - HDAE5000_AcHddNamingWindowProc_Case1	; 2
	.short	HDAE5000_AcHddNamingWindowProc_Case3 - HDAE5000_AcHddNamingWindowProc_Case1	; 3
	.short	HDAE5000_AcHddNamingWindowProc_Case4 - HDAE5000_AcHddNamingWindowProc_Case1	; 4
	.short	HDAE5000_AcHddNamingWindowProc_Case5 - HDAE5000_AcHddNamingWindowProc_Case1	; 5
	.short	HDAE5000_AcHddNamingWindowProc_Case6 - HDAE5000_AcHddNamingWindowProc_Case1	; 6
	.short	HDAE5000_AcHddNamingWindowProc_Case7 - HDAE5000_AcHddNamingWindowProc_Case1	; 7
	.short	HDAE5000_AcHddNamingWindowProc_Case8 - HDAE5000_AcHddNamingWindowProc_Case1	; 8
	.short	HDAE5000_AcHddNamingWindowProc_Case9 - HDAE5000_AcHddNamingWindowProc_Case1	; 9
HDAE5000_Str_Name:	; 0x2E21D8
	; read by IvHddNamingProc at 0x2826DD (lda operand)
	.asciz "Name"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Test:	; 0x2E21DE
	; read by HardTestPage at 0x282856 (lda operand)
	.asciz "Test"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_PPORTTEST:	; 0x2E21E4
	; read by HardTestPage at 0x2828D5 (lda operand)
	.asciz "PPORT TEST"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_HDDIDREAD:	; 0x2E21F0
	; read by HardTestPage at 0x282981 (lda operand)
	.asciz "HDD ID READ"
HDAE5000_Str_FDTEST:	; 0x2E21FC
	; read by HardTestPage at 0x282A2D (lda operand)
	.asciz "FD TEST"
HDAE5000_Str_OK:	; 0x2E2204
	; read by HardTestPage at 0x282A5F (lda operand)
	.asciz "OK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_ERROR:	; 0x2E2208
	; read by HardTestPage at 0x282A69 (lda operand)
	.asciz "ERROR"
HDAE5000_Str_ERROR_HardTestPage:	; 0x2E220E
	; read by HardTestPage at 0x282A73 (lda operand)
	.asciz "ERROR"
HDAE5000_Str_STOPTESTLOOP:	; 0x2E2214
	; read by HardTestPage at 0x282B2C (lda operand)
	.asciz "STOP TEST LOOP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_STARTTESTLOOP:	; 0x2E2224
	; read by HardTestPage at 0x282B53 (lda operand)
	.asciz "START TEST LOOP"
HDAE5000_Str_PortTestOK:	; 0x2E2234
	; read by HardTest_PortTest at 0x282C58 (lda operand)
	.asciz "=======> Port Test OK"
HDAE5000_Str_PortTestError:	; 0x2E224A
	; read by HardTest_PortTest at 0x282C62 (lda operand)
	.asciz "=======> Port Test Error"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_HDTYPE:	; 0x2E2264
	; read by HardTest_HddIdRead at 0x282C94 (pushed operand)
	.asciz "HD-TYPE : "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_Fre_Capa_3_1f_MB:	; 0x2E2270
	; read by HardTest_HddIdRead at 0x282CFC (pushed operand)
	.asciz "Fre Capa: %3.1f [MB]"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Empty:	; 0x2E2286
	; read by HardTest_HddIdRead at 0x282D10 (lda operand)
	.zero 2
HDAE5000_Str_HDDOK:	; 0x2E2288
	; read by HardTest_HddIdRead at 0x282D18 (lda operand)
	.asciz "=======> HDD OK"
HDAE5000_Str_HDDNG:	; 0x2E2298
	; read by HardTest_HddIdRead at 0x282D22 (lda operand)
	.asciz "=======> HDD NG!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Float_100_HddIdRead:	; 0x2E22AA
	; read by HardTest_HddIdRead at 0x282CD9 (lda operand)
	; IEEE single 100.0 (0x42C80000): the divisor HDAE5000_HardTest_HddIdRead passes to HDAE5000_FloatDiv to turn the free space (units of 10,000 bytes) into MB for "Fre Capa: %3.1f [MB]"
	.long 0x42c80000		; 100.0f
HDAE5000_Fmt_2_2d:	; 0x2E22AE
	; read by FdName_SongNumber at 0x282E4E (pushed operand)
	.asciz "%2.2d"
HDAE5000_Str_AllFilesPattern:	; 0x2E22B4
	; read by FdList_Scan at 0x282F46 (lda operand)
	.asciz "*.*"
HDAE5000_Str_Cphd:	; 0x2E22B8
	; read by AttenCpToHDSwCatch at 0x2831C6 (lda operand)
	.asciz "CpHD"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Cphd_AttenCpToMarkSwCatch:	; 0x2E22BE
	; read by AttenCpToMarkSwCatch at 0x283282 (lda operand)
	.asciz "CpHD"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_TitleInfo_Template:	; 0x2E22C4
	; read by TitleInfo_Build at 0x2832F9 (lda operand)
	.asciz "WRITE PROTECTION   :ON     QUICK LOAD MODE:     1\tWRITE CONFIRM      :OFF    JUMP AFTER LOAD:     2\tLOAD BY NUMBER MODE:  1    FREE HDD SPACE :1251MB\t"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_s:	; 0x2E235C
	; read by TitleInfo_Build at 0x283321 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_s_TitleInfo_Build:	; 0x2E2360
	; read by TitleInfo_Build at 0x28335E (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_d:	; 0x2E2364
	; read by TitleInfo_Build at 0x28338E (pushed operand)
	.asciz "  %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_d_TitleInfo_Build:	; 0x2E236A
	; read by TitleInfo_Build at 0x2833BE (pushed operand)
	.asciz "     %d"
HDAE5000_Fmt_d_TitleInfo_Build_2:	; 0x2E2372
	; read by TitleInfo_Build at 0x2833EE (pushed operand)
	.asciz "     %d"
HDAE5000_Fmt_4ldMB:	; 0x2E237A
	; read by TitleInfo_Build at 0x28342D (pushed operand)
	.asciz "%4ldMB"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_HDAE:	; 0x2E2382
	; read by HdTitleEventCatch at 0x2834F0 (lda operand)
	.asciz "HDAE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_HDAETitleFunc_ObjIds:	; 0x2E2388
	; read by HDAETitleFunc at 0x2836FC (lda operand); UI object ids (0x007F0000 + index into HDAE5000_UiObjectName_PtrTable), 4 bytes each
	.long HDAE5000_OBJ_HDDMENU		; UI object 0 "HDDMENU"
	.long HDAE5000_OBJ_ERR_HD_NOT_FMT		; UI object 594 "ERR_HD_NOT_FMT"
	.long HDAE5000_OBJ_ERR_HD_SRAM		; UI object 599 "ERR_HD_SRAM"
	.long HDAE5000_OBJ_ERR_HD_RESET		; UI object 604 "ERR_HD_RESET"
	.long HDAE5000_OBJ_ERR_HD_READ		; UI object 609 "ERR_HD_READ"
	.long HDAE5000_OBJ_ERR_HD_ID_READ		; UI object 614 "ERR_HD_ID_READ"
	.long HDAE5000_OBJ_ERR_HD_TRACK_0		; UI object 619 "ERR_HD_TRACK_0"
	.long HDAE5000_OBJ_ERR_HD_FAT		; UI object 624 "ERR_HD_FAT"
	.long HDAE5000_OBJ_ERR_HD_FSB		; UI object 629 "ERR_HD_FSB"
;
; HDAE5000_HDAETitleFunc_CaseTable (0x2E23AC, 8 x u16): the switch of HDAE5000_HDAETitleFunc
; (dispatch at 0x283546, hdae5000_hd_driver.s:629: `dec 2,xwa`, bound `cp xwa,7`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(.Lri_jt_base)`, `jp T,XIX+WA`).  Entry i is the offset from
; .Lri_jt_base of the case for value 2+i; 8 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_HDAETitleFunc_CaseTable:
	.short	.Lri_jt_base - .Lri_jt_base	; 2
	.short	.Lri_done - .Lri_jt_base	; 3 (default)
	.short	.Lri_done - .Lri_jt_base	; 4 (default)
	.short	.Lri_done - .Lri_jt_base	; 5 (default)
	.short	.Lri_case6 - .Lri_jt_base	; 6
	.short	.Lri_done - .Lri_jt_base	; 7 (default)
	.short	.Lri_case8 - .Lri_jt_base	; 8
	.short	.Lri_case9 - .Lri_jt_base	; 9
HDAE5000_Str_Chr2020203A2020:	; 0x2E23BC
	; read by DirList_BuildPage at 0x283732 (lda operand)
	.asciz "   :                \t"
HDAE5000_Fmt_3_3d:	; 0x2E23D2
	; read by DirList_BuildPage at 0x283758 (pushed operand)
	.asciz "%3.3d"
HDAE5000_PartNames_Text:	; 0x2E23D8
	; read by PartList_Build at 0x2839FD (lda operand)
	.asciz "CURRENT PANEL\t PANEL MEMORY\t  SEQUENCER  \t  COMPOSER   \t SOUND MEMORY\t     MSP     \tRHYTHM CUSTOM\t  USER MIDI  \t    LYRICS   \t"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PartNames_BlankText:	; 0x2E2458
	; read by PartList_Build at 0x2839E4 (lda operand)
	.asciz "             \t             \t             \t             \t             \t             \t             \t             \t             \t"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PartName_Blank:	; 0x2E24D8
	; read by PartList_Build at 0x283A1F (lda operand)
	.asciz "             \t"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_SongScreen_Refresh_ObjIds:	; 0x2E24E8
	; read by SongScreen_Refresh at 0x283C05 (lda operand); UI object ids (0x007F0000 + index into HDAE5000_UiObjectName_PtrTable), 4 bytes each
	.long HDAE5000_OBJ_FILE_LOAD_DIRBOX		; UI object 260 "FILE_LOAD_DIRBOX"
	.long HDAE5000_OBJ_FLS_FILE_SEL_DIRBOX		; UI object 347 "FLS_FILE_SEL_DIRBOX"
HDAE5000_SongScreen_Refresh_ObjIds_2:	; 0x2E24F0
	; read by SongScreen_Refresh at 0x283CED (lda operand); UI object ids (0x007F0000 + index into HDAE5000_UiObjectName_PtrTable), 4 bytes each
	.long HDAE5000_OBJ_HD_FILE_LIST		; UI object 259 "HD_FILE_LIST"
	.long HDAE5000_OBJ_FLS_FILE_SEL_LISTBOX		; UI object 348 "FLS_FILE_SEL_LISTBOX"
HDAE5000_SongScreen_Refresh_ObjIds_3:	; 0x2E24F8
	; read by SongScreen_Refresh at 0x283D63 (lda operand); UI object ids (0x007F0000 + index into HDAE5000_UiObjectName_PtrTable), 4 bytes each
	.long HDAE5000_OBJ_HD_FILE_OPTION		; UI object 258 "HD_FILE_OPTION"
	.long HDAE5000_OBJ_FLS_FILE_SEL_OPTBOX		; UI object 352 "FLS_FILE_SEL_OPTBOX"
HDAE5000_Str_DIRECTORY:	; 0x2E2500
	; read by SongScreen_Refresh at 0x283B8C (pushed operand)
	.asciz "DIRECTORY "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_2_2d_SongScreen_Refresh:	; 0x2E250C
	; read by SongScreen_Refresh at 0x283BA4 (pushed operand)
	.asciz "%2.2d"
HDAE5000_Str_Chr3A_SongScreen_Refresh:	; 0x2E2512
	; read by SongScreen_Refresh at 0x283BC3 (pushed operand)
	.asciz ":"
HDAE5000_Str_Blank0Tab:	; 0x2E2514
	; read by SongScreen_Refresh at 0x283BED (pushed operand)
	.asciz "\t"
HDAE5000_Str_Chr3A2020202020:	; 0x2E2516
	; read by SongScreen_Refresh at 0x283C6F (lda operand)
	.asciz ":                          \t"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_2_2d_SongScreen_Refresh_2:	; 0x2E2534
	; read by SongScreen_Refresh at 0x283C90 (pushed operand)
	.asciz "%2.2d"
;
; HDAE5000_FILE_LOAD_Screen_CaseTable (0x2E253A, 14 x u16): the switch of HDAE5000_FILE_LOAD_Screen
; (dispatch at 0x283DDD, hdae5000_hd_driver.s:1447: `sub xwa,0x01ea0000`, bound `cp xwa,13`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_FILE_LOAD_Screen_Ev01C00001)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_FILE_LOAD_Screen_Ev01C00001 of the case for event 0x01EA0000+i; 14 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_FILE_LOAD_Screen_CaseTable:
	.short	HDAE5000_FILE_LOAD_Screen_Ev01EA0000 - HDAE5000_FILE_LOAD_Screen_Ev01C00001	; 0x01EA0000
	.short	HDAE5000_FILE_LOAD_Screen_Ev01EA0001 - HDAE5000_FILE_LOAD_Screen_Ev01C00001	; 0x01EA0001
	.short	HDAE5000_FILE_LOAD_Screen_Ev01EA0002 - HDAE5000_FILE_LOAD_Screen_Ev01C00001	; 0x01EA0002
	.short	HDAE5000_FILE_LOAD_Screen_Default - HDAE5000_FILE_LOAD_Screen_Ev01C00001	; 0x01EA0003 (default)
	.short	HDAE5000_FILE_LOAD_Screen_Default - HDAE5000_FILE_LOAD_Screen_Ev01C00001	; 0x01EA0004 (default)
	.short	HDAE5000_FILE_LOAD_Screen_Default - HDAE5000_FILE_LOAD_Screen_Ev01C00001	; 0x01EA0005 (default)
	.short	HDAE5000_FILE_LOAD_Screen_Default - HDAE5000_FILE_LOAD_Screen_Ev01C00001	; 0x01EA0006 (default)
	.short	HDAE5000_FILE_LOAD_Screen_Default - HDAE5000_FILE_LOAD_Screen_Ev01C00001	; 0x01EA0007 (default)
	.short	HDAE5000_FILE_LOAD_Screen_Ev01EA0008 - HDAE5000_FILE_LOAD_Screen_Ev01C00001	; 0x01EA0008
	.short	HDAE5000_FILE_LOAD_Screen_Default - HDAE5000_FILE_LOAD_Screen_Ev01C00001	; 0x01EA0009 (default)
	.short	HDAE5000_FILE_LOAD_Screen_Default - HDAE5000_FILE_LOAD_Screen_Ev01C00001	; 0x01EA000A (default)
	.short	HDAE5000_FILE_LOAD_Screen_Default - HDAE5000_FILE_LOAD_Screen_Ev01C00001	; 0x01EA000B (default)
	.short	HDAE5000_FILE_LOAD_Screen_Ev01EA000C - HDAE5000_FILE_LOAD_Screen_Ev01C00001	; 0x01EA000C
	.short	HDAE5000_FILE_LOAD_Screen_Ev01EA000D - HDAE5000_FILE_LOAD_Screen_Ev01C00001	; 0x01EA000D
HDAE5000_Str_DELD:	; 0x2E2556
	; read by AttenDelDirSwCatch at 0x283FCA (lda operand)
	.asciz "DELD"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_DELF:	; 0x2E255C
	; read by AttenDelFileSwCatch at 0x2840EE (lda operand)
	.asciz "DELF"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_UTIL:	; 0x2E2562
	; read by HDD_UTIL_PAGE at 0x2845DB (lda operand)
	.asciz "UTIL"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_LSWFileInfo:	; 0x2E2568
	; read by HDD_UTIL_PAGE at 0x28463A (pushed operand)
	.asciz "---[ LSW File Info. ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Adr:	; 0x2E2582
	; read by HDD_UTIL_PAGE at 0x28465F (pushed operand)
	.asciz "adr  : "
HDAE5000_Str_Size:	; 0x2E258A
	; read by HDD_UTIL_PAGE at 0x28469E (pushed operand)
	.asciz "size : "
HDAE5000_Str_SDAFileInfo:	; 0x2E2592
	; read by HDD_UTIL_PAGE at 0x2846F5 (pushed operand)
	.asciz "---[ SDA File Info. ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Adr_HDD_UTIL_PAGE:	; 0x2E25AC
	; read by HDD_UTIL_PAGE at 0x28471A (pushed operand)
	.asciz "adr  : "
HDAE5000_Str_Size_HDD_UTIL_PAGE:	; 0x2E25B4
	; read by HDD_UTIL_PAGE at 0x284759 (pushed operand)
	.asciz "size : "
HDAE5000_Str_PMTFileInfo:	; 0x2E25BC
	; read by HDD_UTIL_PAGE at 0x2847B0 (pushed operand)
	.asciz "---[ PMT File Info. ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Adr_HDD_UTIL_PAGE_2:	; 0x2E25D6
	; read by HDD_UTIL_PAGE at 0x2847D5 (pushed operand)
	.asciz "adr  : "
HDAE5000_Str_Size_HDD_UTIL_PAGE_2:	; 0x2E25DE
	; read by HDD_UTIL_PAGE at 0x284814 (pushed operand)
	.asciz "size : "
HDAE5000_Str_SQFFileInfo:	; 0x2E25E6
	; read by HDD_UTIL_PAGE at 0x28486B (pushed operand)
	.asciz "---[ SQF File Info. ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Adr_HDD_UTIL_PAGE_3:	; 0x2E2600
	; read by HDD_UTIL_PAGE at 0x284890 (pushed operand)
	.asciz "adr  : "
HDAE5000_Str_Size_HDD_UTIL_PAGE_3:	; 0x2E2608
	; read by HDD_UTIL_PAGE at 0x2848CF (pushed operand)
	.asciz "size : "
HDAE5000_Str_SEQFileInfo:	; 0x2E2610
	; read by HDD_UTIL_PAGE at 0x284926 (pushed operand)
	.asciz "---[ SEQ File Info. ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Adr_HDD_UTIL_PAGE_4:	; 0x2E262A
	; read by HDD_UTIL_PAGE at 0x28494B (pushed operand)
	.asciz "adr  : "
HDAE5000_Str_Size_HDD_UTIL_PAGE_4:	; 0x2E2632
	; read by HDD_UTIL_PAGE at 0x28498A (pushed operand)
	.asciz "size : "
HDAE5000_Str_CMPFileInfo:	; 0x2E263A
	; read by HDD_UTIL_PAGE at 0x2849E1 (pushed operand)
	.asciz "---[ CMP File Info. ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Adr_HDD_UTIL_PAGE_5:	; 0x2E2654
	; read by HDD_UTIL_PAGE at 0x284A06 (pushed operand)
	.asciz "adr  : "
HDAE5000_Str_Size_HDD_UTIL_PAGE_5:	; 0x2E265C
	; read by HDD_UTIL_PAGE at 0x284A45 (pushed operand)
	.asciz "size : "
HDAE5000_Str_TMFileInfo:	; 0x2E2664
	; read by HDD_UTIL_PAGE at 0x284A9C (pushed operand)
	.asciz "---[ TM File Info. ]---"
HDAE5000_Str_Adr_HDD_UTIL_PAGE_6:	; 0x2E267C
	; read by HDD_UTIL_PAGE at 0x284AC1 (pushed operand)
	.asciz "adr  : "
HDAE5000_Str_Size_HDD_UTIL_PAGE_6:	; 0x2E2684
	; read by HDD_UTIL_PAGE at 0x284B00 (pushed operand)
	.asciz "size : "
HDAE5000_Str_MSPFileInfo:	; 0x2E268C
	; read by HDD_UTIL_PAGE at 0x284B57 (pushed operand)
	.asciz "---[ MSP File Info. ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Adr_HDD_UTIL_PAGE_7:	; 0x2E26A6
	; read by HDD_UTIL_PAGE at 0x284B7C (pushed operand)
	.asciz "adr  : "
HDAE5000_Str_Size_HDD_UTIL_PAGE_7:	; 0x2E26AE
	; read by HDD_UTIL_PAGE at 0x284BBB (pushed operand)
	.asciz "size : "
HDAE5000_Str_RCMFileInfo:	; 0x2E26B6
	; read by HDD_UTIL_PAGE at 0x284C13 (pushed operand)
	.asciz "---[ RCM File Info. ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Adr_HDD_UTIL_PAGE_8:	; 0x2E26D0
	; read by HDD_UTIL_PAGE at 0x284C38 (pushed operand)
	.asciz "adr  : "
HDAE5000_Str_Size_HDD_UTIL_PAGE_8:	; 0x2E26D8
	; read by HDD_UTIL_PAGE at 0x284C77 (pushed operand)
	.asciz "size : "
HDAE5000_Str_MDFileInfo:	; 0x2E26E0
	; read by HDD_UTIL_PAGE at 0x284CCF (pushed operand)
	.asciz "---[ MD File Info. ]---"
HDAE5000_Str_Adr_HDD_UTIL_PAGE_9:	; 0x2E26F8
	; read by HDD_UTIL_PAGE at 0x284CF4 (pushed operand)
	.asciz "adr  : "
HDAE5000_Str_Size_HDD_UTIL_PAGE_9:	; 0x2E2700
	; read by HDD_UTIL_PAGE at 0x284D33 (pushed operand)
	.asciz "size : "
HDAE5000_Str_PCLK:	; 0x2E2708
	; read by PC_DATA_LINK_PAGE at 0x284E97 (lda operand)
	.asciz "PCLK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_PORTISACTIVE:	; 0x2E270E
	; read by PC_DATA_LINK_PAGE at 0x284EF8 (lda operand)
	.asciz "PORT IS ACTIVE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Blank14:	; 0x2E271E
	; read by PC_DATA_LINK_PAGE at 0x284F0A (lda operand)
	.asciz "              "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_SeparateOutput_SendPartMsg_Data:	; 0x2E272E
	; read by SeparateOutput_SendPartMsg at 0x284F50 (ld # operand)
	.byte 0xb0
	.zero 1
	.byte 0x9b
	.zero 1
HDAE5000_SeparateOutput_SendPartMsg_Data_2:	; 0x2E2732
	; read by SeparateOutput_SendPartMsg at 0x284F5C (ld # operand)
	.byte 0xb0
	.zero 1
	.byte 0x9d
	.zero 1
HDAE5000_TextPtrs_OFF_DRUMSLR_BASSDRUMSMIX_BASSDRUMSMONO:	; 0x2E2736, 4 x .long -> string
	; read by SeparateOutputModeCheck at 0x28512B (ld # operand); 4 string pointers, 4 bytes each, entry i at +4*i
	.long	HDAE5000_Str_OFF_3
	.long	HDAE5000_Str_DRUMSLR
	.long	HDAE5000_Str_BASSDRUMSMIX
	.long	HDAE5000_Str_BASSDRUMSMONO
HDAE5000_Str_BASSDRUMSMONO:	; 0x2E2746
	; pointed at by entry 3 of HDAE5000_TextPtrs_OFF_DRUMSLR_BASSDRUMSMIX_BASSDRUMSMONO, a table read by SeparateOutputModeCheck
	.asciz "BASS/DRUMS MONO"
HDAE5000_Str_BASSDRUMSMIX:	; 0x2E2756
	; pointed at by entry 2 of HDAE5000_TextPtrs_OFF_DRUMSLR_BASSDRUMSMIX_BASSDRUMSMONO, a table read by SeparateOutputModeCheck
	.asciz "BASS+DRUMS MIX "
HDAE5000_Str_DRUMSLR:	; 0x2E2766
	; pointed at by entry 1 of HDAE5000_TextPtrs_OFF_DRUMSLR_BASSDRUMSMIX_BASSDRUMSMONO, a table read by SeparateOutputModeCheck
	.asciz "   DRUMS L/R   "
HDAE5000_Str_OFF_3:	; 0x2E2776
	; pointed at by entry 0 of HDAE5000_TextPtrs_OFF_DRUMSLR_BASSDRUMSMIX_BASSDRUMSMONO, a table read by SeparateOutputModeCheck
	.asciz "      OFF      "
HDAE5000_Fmt_s_SeparateOutputModeCheck:	; 0x2E2786
	; read by SeparateOutputModeCheck at 0x285138 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_SeparateOutputModeCheck_CaseTable (0x2E278A, 10 x u16): the switch of HDAE5000_SeparateOutputModeCheck
; (dispatch at 0x285120, hdae5000_hd_driver.s:3139: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(.LHD_SC__h1_case9)`, `jp T,XIX+WA`).  Entry i is the offset from
; .LHD_SC__h1_case9 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_SeparateOutputModeCheck_CaseTable:
	.short	.LHD_SC__h1_case0 - .LHD_SC__h1_case9	; 0x01E0003E
	.short	.LHD_SC__h1_case1 - .LHD_SC__h1_case9	; 0x01E0003F
	.short	.LHD_SC__h1_default - .LHD_SC__h1_case9	; 0x01E00040 (default)
	.short	.LHD_SC__h1_default - .LHD_SC__h1_case9	; 0x01E00041 (default)
	.short	.LHD_SC__h1_default - .LHD_SC__h1_case9	; 0x01E00042 (default)
	.short	.LHD_SC__h1_case5 - .LHD_SC__h1_case9	; 0x01E00043
	.short	.LHD_SC__h1_case6 - .LHD_SC__h1_case9	; 0x01E00044
	.short	.LHD_SC__h1_case7 - .LHD_SC__h1_case9	; 0x01E00045
	.short	.LHD_SC__h1_case8 - .LHD_SC__h1_case9	; 0x01E00046
	.short	.LHD_SC__h1_case9 - .LHD_SC__h1_case9	; 0x01E00047
HDAE5000_TextPtrs_NONE_to_16:	; 0x2E279E, 17 x .long -> string
	; read by SeparateDrumPartCheck at 0x2851D1 (ld # operand); 17 string pointers, 4 bytes each, entry i at +4*i
	.long	HDAE5000_Str_NONE
	.long	HDAE5000_Str_1_3
	.long	HDAE5000_Str_2_3
	.long	HDAE5000_Str_3_3
	.long	HDAE5000_Str_4_3
	.long	HDAE5000_Str_5_3
	.long	HDAE5000_Str_6_3
	.long	HDAE5000_Str_7_3
	.long	HDAE5000_Str_8_3
	.long	HDAE5000_Str_9_3
	.long	HDAE5000_Str_10
	.long	HDAE5000_Str_11
	.long	HDAE5000_Str_12
	.long	HDAE5000_Str_13
	.long	HDAE5000_Str_14
	.long	HDAE5000_Str_15
	.long	HDAE5000_Str_16
HDAE5000_Str_16:	; 0x2E27E2
	; pointed at by entry 16 of HDAE5000_TextPtrs_NONE_to_16, a table read by SeparateDrumPartCheck
	.asciz " 16 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_15:	; 0x2E27E8
	; pointed at by entry 15 of HDAE5000_TextPtrs_NONE_to_16, a table read by SeparateDrumPartCheck
	.asciz " 15 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_14:	; 0x2E27EE
	; pointed at by entry 14 of HDAE5000_TextPtrs_NONE_to_16, a table read by SeparateDrumPartCheck
	.asciz " 14 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_13:	; 0x2E27F4
	; pointed at by entry 13 of HDAE5000_TextPtrs_NONE_to_16, a table read by SeparateDrumPartCheck
	.asciz " 13 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_12:	; 0x2E27FA
	; pointed at by entry 12 of HDAE5000_TextPtrs_NONE_to_16, a table read by SeparateDrumPartCheck
	.asciz " 12 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_11:	; 0x2E2800
	; pointed at by entry 11 of HDAE5000_TextPtrs_NONE_to_16, a table read by SeparateDrumPartCheck
	.asciz " 11 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_10:	; 0x2E2806
	; pointed at by entry 10 of HDAE5000_TextPtrs_NONE_to_16, a table read by SeparateDrumPartCheck
	.asciz " 10 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_9_3:	; 0x2E280C
	; pointed at by entry 9 of HDAE5000_TextPtrs_NONE_to_16, a table read by SeparateDrumPartCheck
	.asciz "  9 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_8_3:	; 0x2E2812
	; pointed at by entry 8 of HDAE5000_TextPtrs_NONE_to_16, a table read by SeparateDrumPartCheck
	.asciz "  8 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_7_3:	; 0x2E2818
	; pointed at by entry 7 of HDAE5000_TextPtrs_NONE_to_16, a table read by SeparateDrumPartCheck
	.asciz "  7 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_6_3:	; 0x2E281E
	; pointed at by entry 6 of HDAE5000_TextPtrs_NONE_to_16, a table read by SeparateDrumPartCheck
	.asciz "  6 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_5_3:	; 0x2E2824
	; pointed at by entry 5 of HDAE5000_TextPtrs_NONE_to_16, a table read by SeparateDrumPartCheck
	.asciz "  5 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_4_3:	; 0x2E282A
	; pointed at by entry 4 of HDAE5000_TextPtrs_NONE_to_16, a table read by SeparateDrumPartCheck
	.asciz "  4 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_3_3:	; 0x2E2830
	; pointed at by entry 3 of HDAE5000_TextPtrs_NONE_to_16, a table read by SeparateDrumPartCheck
	.asciz "  3 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_2_3:	; 0x2E2836
	; pointed at by entry 2 of HDAE5000_TextPtrs_NONE_to_16, a table read by SeparateDrumPartCheck
	.asciz "  2 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_1_3:	; 0x2E283C
	; pointed at by entry 1 of HDAE5000_TextPtrs_NONE_to_16, a table read by SeparateDrumPartCheck
	.asciz "  1 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_NONE:	; 0x2E2842
	; pointed at by entry 0 of HDAE5000_TextPtrs_NONE_to_16, a table read by SeparateDrumPartCheck
	.asciz "NONE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_s_SeparateDrumPartCheck:	; 0x2E2848
	; read by SeparateDrumPartCheck at 0x2851DE (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_SeparateDrumPartCheck_CaseTable (0x2E284C, 10 x u16): the switch of HDAE5000_SeparateDrumPartCheck
; (dispatch at 0x2851C6, hdae5000_hd_driver.s:3208: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(.LHD_SC__h2_case9)`, `jp T,XIX+WA`).  Entry i is the offset from
; .LHD_SC__h2_case9 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_SeparateDrumPartCheck_CaseTable:
	.short	.LHD_SC__h2_case0 - .LHD_SC__h2_case9	; 0x01E0003E
	.short	.LHD_SC__h2_case1 - .LHD_SC__h2_case9	; 0x01E0003F
	.short	.LHD_SC__h2_default - .LHD_SC__h2_case9	; 0x01E00040 (default)
	.short	.LHD_SC__h2_default - .LHD_SC__h2_case9	; 0x01E00041 (default)
	.short	.LHD_SC__h2_default - .LHD_SC__h2_case9	; 0x01E00042 (default)
	.short	.LHD_SC__h2_case5 - .LHD_SC__h2_case9	; 0x01E00043
	.short	.LHD_SC__h2_case6 - .LHD_SC__h2_case9	; 0x01E00044
	.short	.LHD_SC__h2_case7 - .LHD_SC__h2_case9	; 0x01E00045
	.short	.LHD_SC__h2_case8 - .LHD_SC__h2_case9	; 0x01E00046
	.short	.LHD_SC__h2_case9 - .LHD_SC__h2_case9	; 0x01E00047
HDAE5000_TextPtrs_NONE_to_16_2:	; 0x2E2860, 17 x .long -> string
	; read by SeparateBassPartCheck at 0x28527A (ld # operand); 17 string pointers, 4 bytes each, entry i at +4*i
	.long	HDAE5000_Str_NONE_2
	.long	HDAE5000_Str_1_4
	.long	HDAE5000_Str_2_4
	.long	HDAE5000_Str_3_4
	.long	HDAE5000_Str_4_4
	.long	HDAE5000_Str_5_4
	.long	HDAE5000_Str_6_4
	.long	HDAE5000_Str_7_4
	.long	HDAE5000_Str_8_4
	.long	HDAE5000_Str_9_4
	.long	HDAE5000_Str_10_2
	.long	HDAE5000_Str_11_2
	.long	HDAE5000_Str_12_2
	.long	HDAE5000_Str_13_2
	.long	HDAE5000_Str_14_2
	.long	HDAE5000_Str_15_2
	.long	HDAE5000_Str_16_2
HDAE5000_Str_16_2:	; 0x2E28A4
	; pointed at by entry 16 of HDAE5000_TextPtrs_NONE_to_16_2, a table read by SeparateBassPartCheck
	.asciz " 16 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_15_2:	; 0x2E28AA
	; pointed at by entry 15 of HDAE5000_TextPtrs_NONE_to_16_2, a table read by SeparateBassPartCheck
	.asciz " 15 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_14_2:	; 0x2E28B0
	; pointed at by entry 14 of HDAE5000_TextPtrs_NONE_to_16_2, a table read by SeparateBassPartCheck
	.asciz " 14 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_13_2:	; 0x2E28B6
	; pointed at by entry 13 of HDAE5000_TextPtrs_NONE_to_16_2, a table read by SeparateBassPartCheck
	.asciz " 13 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_12_2:	; 0x2E28BC
	; pointed at by entry 12 of HDAE5000_TextPtrs_NONE_to_16_2, a table read by SeparateBassPartCheck
	.asciz " 12 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_11_2:	; 0x2E28C2
	; pointed at by entry 11 of HDAE5000_TextPtrs_NONE_to_16_2, a table read by SeparateBassPartCheck
	.asciz " 11 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_10_2:	; 0x2E28C8
	; pointed at by entry 10 of HDAE5000_TextPtrs_NONE_to_16_2, a table read by SeparateBassPartCheck
	.asciz " 10 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_9_4:	; 0x2E28CE
	; pointed at by entry 9 of HDAE5000_TextPtrs_NONE_to_16_2, a table read by SeparateBassPartCheck
	.asciz "  9 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_8_4:	; 0x2E28D4
	; pointed at by entry 8 of HDAE5000_TextPtrs_NONE_to_16_2, a table read by SeparateBassPartCheck
	.asciz "  8 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_7_4:	; 0x2E28DA
	; pointed at by entry 7 of HDAE5000_TextPtrs_NONE_to_16_2, a table read by SeparateBassPartCheck
	.asciz "  7 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_6_4:	; 0x2E28E0
	; pointed at by entry 6 of HDAE5000_TextPtrs_NONE_to_16_2, a table read by SeparateBassPartCheck
	.asciz "  6 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_5_4:	; 0x2E28E6
	; pointed at by entry 5 of HDAE5000_TextPtrs_NONE_to_16_2, a table read by SeparateBassPartCheck
	.asciz "  5 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_4_4:	; 0x2E28EC
	; pointed at by entry 4 of HDAE5000_TextPtrs_NONE_to_16_2, a table read by SeparateBassPartCheck
	.asciz "  4 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_3_4:	; 0x2E28F2
	; pointed at by entry 3 of HDAE5000_TextPtrs_NONE_to_16_2, a table read by SeparateBassPartCheck
	.asciz "  3 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_2_4:	; 0x2E28F8
	; pointed at by entry 2 of HDAE5000_TextPtrs_NONE_to_16_2, a table read by SeparateBassPartCheck
	.asciz "  2 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_1_4:	; 0x2E28FE
	; pointed at by entry 1 of HDAE5000_TextPtrs_NONE_to_16_2, a table read by SeparateBassPartCheck
	.asciz "  1 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_NONE_2:	; 0x2E2904
	; pointed at by entry 0 of HDAE5000_TextPtrs_NONE_to_16_2, a table read by SeparateBassPartCheck
	.asciz "NONE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_s_SeparateBassPartCheck:	; 0x2E290A
	; read by SeparateBassPartCheck at 0x285287 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_SeparateBassPartCheck_CaseTable (0x2E290E, 10 x u16): the switch of HDAE5000_SeparateBassPartCheck
; (dispatch at 0x28526F, hdae5000_hd_driver.s:3277: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(.LHD_SC__h3_case9)`, `jp T,XIX+WA`).  Entry i is the offset from
; .LHD_SC__h3_case9 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_SeparateBassPartCheck_CaseTable:
	.short	.LHD_SC__h3_case0 - .LHD_SC__h3_case9	; 0x01E0003E
	.short	.LHD_SC__h3_case1 - .LHD_SC__h3_case9	; 0x01E0003F
	.short	.LHD_SC__h3_default - .LHD_SC__h3_case9	; 0x01E00040 (default)
	.short	.LHD_SC__h3_default - .LHD_SC__h3_case9	; 0x01E00041 (default)
	.short	.LHD_SC__h3_default - .LHD_SC__h3_case9	; 0x01E00042 (default)
	.short	.LHD_SC__h3_case5 - .LHD_SC__h3_case9	; 0x01E00043
	.short	.LHD_SC__h3_case6 - .LHD_SC__h3_case9	; 0x01E00044
	.short	.LHD_SC__h3_case7 - .LHD_SC__h3_case9	; 0x01E00045
	.short	.LHD_SC__h3_case8 - .LHD_SC__h3_case9	; 0x01E00046
	.short	.LHD_SC__h3_case9 - .LHD_SC__h3_case9	; 0x01E00047
HDAE5000_TextPtrs_Chr2D2D2D_NO_YES:	; 0x2E2922, 3 x .long -> string
	; read by LBNCmpBitCheck, LBNLswBitCheck, LBNMdBitCheck, LBNMspBitCheck, LBNPmtBitCheck, LBNRcmBitCheck, LBNSqtBitCheck, LBNTlxBitCheck_Unregistered, LBNTmBitCheck, SfxCmpBitCheck, SfxLswBitCheck, SfxMdBitCheck, SfxMspBitCheck, SfxPmtBitCheck, SfxRcmBitCheck, SfxSqtBitCheck, SfxTlxBitCheck, SfxTmBitCheck, TypeSel_ShowSaveFlags at 0x285426 (ld #, ld (mem), lda operand); 3 string pointers, 4 bytes each, entry i at +4*i
	.long	HDAE5000_Str_Chr2D2D2D_2
	.long	HDAE5000_Str_NO
	.long	HDAE5000_Str_YES
HDAE5000_Str_YES:	; 0x2E292E
	; pointed at by entry 2 of HDAE5000_TextPtrs_Chr2D2D2D_NO_YES, a table read by LBNCmpBitCheck, LBNLswBitCheck, LBNMdBitCheck, LBNMspBitCheck, LBNPmtBitCheck, LBNRcmBitCheck, LBNSqtBitCheck, LBNTlxBitCheck_Unregistered, LBNTmBitCheck, SfxCmpBitCheck, SfxLswBitCheck, SfxMdBitCheck, SfxMspBitCheck, SfxPmtBitCheck, SfxRcmBitCheck, SfxSqtBitCheck, SfxTlxBitCheck, SfxTmBitCheck, TypeSel_ShowSaveFlags
	.asciz "YES"
HDAE5000_Str_NO:	; 0x2E2932
	; pointed at by entry 1 of HDAE5000_TextPtrs_Chr2D2D2D_NO_YES, a table read by LBNCmpBitCheck, LBNLswBitCheck, LBNMdBitCheck, LBNMspBitCheck, LBNPmtBitCheck, LBNRcmBitCheck, LBNSqtBitCheck, LBNTlxBitCheck_Unregistered, LBNTmBitCheck, SfxCmpBitCheck, SfxLswBitCheck, SfxMdBitCheck, SfxMspBitCheck, SfxPmtBitCheck, SfxRcmBitCheck, SfxSqtBitCheck, SfxTlxBitCheck, SfxTmBitCheck, TypeSel_ShowSaveFlags
	.asciz "NO "
HDAE5000_Str_Chr2D2D2D_2:	; 0x2E2936
	; pointed at by entry 0 of HDAE5000_TextPtrs_Chr2D2D2D_NO_YES, a table read by LBNCmpBitCheck, LBNLswBitCheck, LBNMdBitCheck, LBNMspBitCheck, LBNPmtBitCheck, LBNRcmBitCheck, LBNSqtBitCheck, LBNTlxBitCheck_Unregistered, LBNTmBitCheck, SfxCmpBitCheck, SfxLswBitCheck, SfxMdBitCheck, SfxMspBitCheck, SfxPmtBitCheck, SfxRcmBitCheck, SfxSqtBitCheck, SfxTlxBitCheck, SfxTmBitCheck, TypeSel_ShowSaveFlags
	.asciz "---"
HDAE5000_Fmt_s_SaveOptNameCheck:	; 0x2E293A
	; read by SaveOptNameCheck at 0x2853DF (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_SaveOptNameCheck_CaseTable (0x2E293E, 10 x u16): the switch of HDAE5000_SaveOptNameCheck
; (dispatch at 0x2853D1, hdae5000_hd_driver.s:3440: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(.Lhbi_case0)`, `jp T,XIX+WA`).  Entry i is the offset from
; .Lhbi_case0 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_SaveOptNameCheck_CaseTable:
	.short	.Lhbi_case1 - .Lhbi_case0	; 0x01E0003E
	.short	.Lhbi_case2 - .Lhbi_case0	; 0x01E0003F
	.short	.Lhbi_default - .Lhbi_case0	; 0x01E00040 (default)
	.short	.Lhbi_default - .Lhbi_case0	; 0x01E00041 (default)
	.short	.Lhbi_default - .Lhbi_case0	; 0x01E00042 (default)
	.short	.Lhbi_case3 - .Lhbi_case0	; 0x01E00043
	.short	.Lhbi_case4 - .Lhbi_case0	; 0x01E00044
	.short	.Lhbi_case5 - .Lhbi_case0	; 0x01E00045
	.short	.Lhbi_case6 - .Lhbi_case0	; 0x01E00046
	.short	.Lhbi_case0 - .Lhbi_case0	; 0x01E00047
HDAE5000_Str_SVOP:	; 0x2E2952
	; read by SaveOptSwEventCatch at 0x28560E (lda operand)
	.asciz "SVOP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_s_FileOptNameCheck:	; 0x2E2958
	; read by FileOptNameCheck at 0x2857CA (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_FileOptNameCheck_CaseTable (0x2E295C, 10 x u16): the switch of HDAE5000_FileOptNameCheck
; (dispatch at 0x2857B1, hdae5000_hd_driver.s:3742: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_FileOptNameCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_FileOptNameCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_FileOptNameCheck_CaseTable:
	.short	HDAE5000_FileOptNameCheck_Ev01E0003E - HDAE5000_FileOptNameCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_FileOptNameCheck_Ev01E0003F - HDAE5000_FileOptNameCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_FileOptNameCheck_Default - HDAE5000_FileOptNameCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_FileOptNameCheck_Default - HDAE5000_FileOptNameCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_FileOptNameCheck_Default - HDAE5000_FileOptNameCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_FileOptNameCheck_Ev01E00043 - HDAE5000_FileOptNameCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_FileOptNameCheck_Ev01E00044 - HDAE5000_FileOptNameCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_FileOptNameCheck_Ev01E00045 - HDAE5000_FileOptNameCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_FileOptNameCheck_Ev01E00046 - HDAE5000_FileOptNameCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_FileOptNameCheck_Ev01E00047 - HDAE5000_FileOptNameCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_SfxLswBitCheck:	; 0x2E2970
	; read by SfxLswBitCheck at 0x28584F (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_SfxLswBitCheck_CaseTable (0x2E2974, 10 x u16): the switch of HDAE5000_SfxLswBitCheck
; (dispatch at 0x285837, hdae5000_hd_driver.s:3794: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_SfxLswBitCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_SfxLswBitCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_SfxLswBitCheck_CaseTable:
	.short	HDAE5000_SfxLswBitCheck_Ev01E0003E - HDAE5000_SfxLswBitCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_SfxLswBitCheck_Ev01E0003F - HDAE5000_SfxLswBitCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_SfxLswBitCheck_Default - HDAE5000_SfxLswBitCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_SfxLswBitCheck_Default - HDAE5000_SfxLswBitCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_SfxLswBitCheck_Default - HDAE5000_SfxLswBitCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_SfxLswBitCheck_Ev01E00043 - HDAE5000_SfxLswBitCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_SfxLswBitCheck_Ev01E00044 - HDAE5000_SfxLswBitCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_SfxLswBitCheck_Ev01E00045 - HDAE5000_SfxLswBitCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_SfxLswBitCheck_Ev01E00046 - HDAE5000_SfxLswBitCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_SfxLswBitCheck_Ev01E00047 - HDAE5000_SfxLswBitCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_SfxPmtBitCheck:	; 0x2E2988
	; read by SfxPmtBitCheck at 0x285905 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_SfxPmtBitCheck_CaseTable (0x2E298C, 10 x u16): the switch of HDAE5000_SfxPmtBitCheck
; (dispatch at 0x2858ED, hdae5000_hd_driver.s:3862: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_SfxPmtBitCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_SfxPmtBitCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_SfxPmtBitCheck_CaseTable:
	.short	HDAE5000_SfxPmtBitCheck_Ev01E0003E - HDAE5000_SfxPmtBitCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_SfxPmtBitCheck_Ev01E0003F - HDAE5000_SfxPmtBitCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_SfxPmtBitCheck_Default - HDAE5000_SfxPmtBitCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_SfxPmtBitCheck_Default - HDAE5000_SfxPmtBitCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_SfxPmtBitCheck_Default - HDAE5000_SfxPmtBitCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_SfxPmtBitCheck_Ev01E00043 - HDAE5000_SfxPmtBitCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_SfxPmtBitCheck_Ev01E00044 - HDAE5000_SfxPmtBitCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_SfxPmtBitCheck_Ev01E00045 - HDAE5000_SfxPmtBitCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_SfxPmtBitCheck_Ev01E00046 - HDAE5000_SfxPmtBitCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_SfxPmtBitCheck_Ev01E00047 - HDAE5000_SfxPmtBitCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_SfxSqtBitCheck:	; 0x2E29A0
	; read by SfxSqtBitCheck at 0x2859BB (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_SfxSqtBitCheck_CaseTable (0x2E29A4, 10 x u16): the switch of HDAE5000_SfxSqtBitCheck
; (dispatch at 0x2859A3, hdae5000_hd_driver.s:3930: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_SfxSqtBitCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_SfxSqtBitCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_SfxSqtBitCheck_CaseTable:
	.short	HDAE5000_SfxSqtBitCheck_Ev01E0003E - HDAE5000_SfxSqtBitCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_SfxSqtBitCheck_Ev01E0003F - HDAE5000_SfxSqtBitCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_SfxSqtBitCheck_Default - HDAE5000_SfxSqtBitCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_SfxSqtBitCheck_Default - HDAE5000_SfxSqtBitCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_SfxSqtBitCheck_Default - HDAE5000_SfxSqtBitCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_SfxSqtBitCheck_Ev01E00043 - HDAE5000_SfxSqtBitCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_SfxSqtBitCheck_Ev01E00044 - HDAE5000_SfxSqtBitCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_SfxSqtBitCheck_Ev01E00045 - HDAE5000_SfxSqtBitCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_SfxSqtBitCheck_Ev01E00046 - HDAE5000_SfxSqtBitCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_SfxSqtBitCheck_Ev01E00047 - HDAE5000_SfxSqtBitCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_SfxCmpBitCheck:	; 0x2E29B8
	; read by SfxCmpBitCheck at 0x285A71 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_SfxCmpBitCheck_CaseTable (0x2E29BC, 10 x u16): the switch of HDAE5000_SfxCmpBitCheck
; (dispatch at 0x285A59, hdae5000_hd_driver.s:3998: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_SfxCmpBitCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_SfxCmpBitCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_SfxCmpBitCheck_CaseTable:
	.short	HDAE5000_SfxCmpBitCheck_Ev01E0003E - HDAE5000_SfxCmpBitCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_SfxCmpBitCheck_Ev01E0003F - HDAE5000_SfxCmpBitCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_SfxCmpBitCheck_Default - HDAE5000_SfxCmpBitCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_SfxCmpBitCheck_Default - HDAE5000_SfxCmpBitCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_SfxCmpBitCheck_Default - HDAE5000_SfxCmpBitCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_SfxCmpBitCheck_Ev01E00043 - HDAE5000_SfxCmpBitCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_SfxCmpBitCheck_Ev01E00044 - HDAE5000_SfxCmpBitCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_SfxCmpBitCheck_Ev01E00045 - HDAE5000_SfxCmpBitCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_SfxCmpBitCheck_Ev01E00046 - HDAE5000_SfxCmpBitCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_SfxCmpBitCheck_Ev01E00047 - HDAE5000_SfxCmpBitCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_SfxTmBitCheck:	; 0x2E29D0
	; read by SfxTmBitCheck at 0x285B27 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_SfxTmBitCheck_CaseTable (0x2E29D4, 10 x u16): the switch of HDAE5000_SfxTmBitCheck
; (dispatch at 0x285B0F, hdae5000_hd_driver.s:4066: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_SfxTmBitCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_SfxTmBitCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_SfxTmBitCheck_CaseTable:
	.short	HDAE5000_SfxTmBitCheck_Ev01E0003E - HDAE5000_SfxTmBitCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_SfxTmBitCheck_Ev01E0003F - HDAE5000_SfxTmBitCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_SfxTmBitCheck_Default - HDAE5000_SfxTmBitCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_SfxTmBitCheck_Default - HDAE5000_SfxTmBitCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_SfxTmBitCheck_Default - HDAE5000_SfxTmBitCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_SfxTmBitCheck_Ev01E00043 - HDAE5000_SfxTmBitCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_SfxTmBitCheck_Ev01E00044 - HDAE5000_SfxTmBitCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_SfxTmBitCheck_Ev01E00045 - HDAE5000_SfxTmBitCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_SfxTmBitCheck_Ev01E00046 - HDAE5000_SfxTmBitCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_SfxTmBitCheck_Ev01E00047 - HDAE5000_SfxTmBitCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_SfxMspBitCheck:	; 0x2E29E8
	; read by SfxMspBitCheck at 0x285BDD (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_SfxMspBitCheck_CaseTable (0x2E29EC, 10 x u16): the switch of HDAE5000_SfxMspBitCheck
; (dispatch at 0x285BC5, hdae5000_hd_driver.s:4134: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_SfxMspBitCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_SfxMspBitCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_SfxMspBitCheck_CaseTable:
	.short	HDAE5000_SfxMspBitCheck_Ev01E0003E - HDAE5000_SfxMspBitCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_SfxMspBitCheck_Ev01E0003F - HDAE5000_SfxMspBitCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_SfxMspBitCheck_Default - HDAE5000_SfxMspBitCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_SfxMspBitCheck_Default - HDAE5000_SfxMspBitCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_SfxMspBitCheck_Default - HDAE5000_SfxMspBitCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_SfxMspBitCheck_Ev01E00043 - HDAE5000_SfxMspBitCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_SfxMspBitCheck_Ev01E00044 - HDAE5000_SfxMspBitCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_SfxMspBitCheck_Ev01E00045 - HDAE5000_SfxMspBitCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_SfxMspBitCheck_Ev01E00046 - HDAE5000_SfxMspBitCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_SfxMspBitCheck_Ev01E00047 - HDAE5000_SfxMspBitCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_SfxRcmBitCheck:	; 0x2E2A00
	; read by SfxRcmBitCheck at 0x285C93 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_SfxRcmBitCheck_CaseTable (0x2E2A04, 10 x u16): the switch of HDAE5000_SfxRcmBitCheck
; (dispatch at 0x285C7B, hdae5000_hd_driver.s:4202: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_SfxRcmBitCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_SfxRcmBitCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_SfxRcmBitCheck_CaseTable:
	.short	HDAE5000_SfxRcmBitCheck_Ev01E0003E - HDAE5000_SfxRcmBitCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_SfxRcmBitCheck_Ev01E0003F - HDAE5000_SfxRcmBitCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_SfxRcmBitCheck_Default - HDAE5000_SfxRcmBitCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_SfxRcmBitCheck_Default - HDAE5000_SfxRcmBitCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_SfxRcmBitCheck_Default - HDAE5000_SfxRcmBitCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_SfxRcmBitCheck_Ev01E00043 - HDAE5000_SfxRcmBitCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_SfxRcmBitCheck_Ev01E00044 - HDAE5000_SfxRcmBitCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_SfxRcmBitCheck_Ev01E00045 - HDAE5000_SfxRcmBitCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_SfxRcmBitCheck_Ev01E00046 - HDAE5000_SfxRcmBitCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_SfxRcmBitCheck_Ev01E00047 - HDAE5000_SfxRcmBitCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_SfxMdBitCheck:	; 0x2E2A18
	; read by SfxMdBitCheck at 0x285D49 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_SfxMdBitCheck_CaseTable (0x2E2A1C, 10 x u16): the switch of HDAE5000_SfxMdBitCheck
; (dispatch at 0x285D31, hdae5000_hd_driver.s:4270: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_SfxMdBitCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_SfxMdBitCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_SfxMdBitCheck_CaseTable:
	.short	HDAE5000_SfxMdBitCheck_Ev01E0003E - HDAE5000_SfxMdBitCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_SfxMdBitCheck_Ev01E0003F - HDAE5000_SfxMdBitCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_SfxMdBitCheck_Default - HDAE5000_SfxMdBitCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_SfxMdBitCheck_Default - HDAE5000_SfxMdBitCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_SfxMdBitCheck_Default - HDAE5000_SfxMdBitCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_SfxMdBitCheck_Ev01E00043 - HDAE5000_SfxMdBitCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_SfxMdBitCheck_Ev01E00044 - HDAE5000_SfxMdBitCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_SfxMdBitCheck_Ev01E00045 - HDAE5000_SfxMdBitCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_SfxMdBitCheck_Ev01E00046 - HDAE5000_SfxMdBitCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_SfxMdBitCheck_Ev01E00047 - HDAE5000_SfxMdBitCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_SfxTlxBitCheck:	; 0x2E2A30
	; read by SfxTlxBitCheck at 0x285E04 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_SfxTlxBitCheck_CaseTable (0x2E2A34, 10 x u16): the switch of HDAE5000_SfxTlxBitCheck
; (dispatch at 0x285DEA, hdae5000_hd_driver.s:4339: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_SfxTlxBitCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_SfxTlxBitCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_SfxTlxBitCheck_CaseTable:
	.short	HDAE5000_SfxTlxBitCheck_Ev01E0003E - HDAE5000_SfxTlxBitCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_SfxTlxBitCheck_Ev01E0003F - HDAE5000_SfxTlxBitCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_SfxTlxBitCheck_Default - HDAE5000_SfxTlxBitCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_SfxTlxBitCheck_Default - HDAE5000_SfxTlxBitCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_SfxTlxBitCheck_Default - HDAE5000_SfxTlxBitCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_SfxTlxBitCheck_Ev01E00043 - HDAE5000_SfxTlxBitCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_SfxTlxBitCheck_Ev01E00044 - HDAE5000_SfxTlxBitCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_SfxTlxBitCheck_Ev01E00045 - HDAE5000_SfxTlxBitCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_SfxTlxBitCheck_Ev01E00046 - HDAE5000_SfxTlxBitCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_SfxTlxBitCheck_Ev01E00047 - HDAE5000_SfxTlxBitCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_WriteProtectEditCheck:	; 0x2E2A48
	; read by WriteProtectEditCheck at 0x285EE1 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_WriteProtectEditCheck_CaseTable (0x2E2A4C, 10 x u16): the switch of HDAE5000_WriteProtectEditCheck
; (dispatch at 0x285EC9, hdae5000_hd_driver.s:4422: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_WriteProtectEditCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_WriteProtectEditCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_WriteProtectEditCheck_CaseTable:
	.short	HDAE5000_WriteProtectEditCheck_Ev01E0003E - HDAE5000_WriteProtectEditCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_WriteProtectEditCheck_Ev01E0003E - HDAE5000_WriteProtectEditCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_WriteProtectEditCheck_Default - HDAE5000_WriteProtectEditCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_WriteProtectEditCheck_Default - HDAE5000_WriteProtectEditCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_WriteProtectEditCheck_Default - HDAE5000_WriteProtectEditCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_WriteProtectEditCheck_Ev01E00043 - HDAE5000_WriteProtectEditCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_WriteProtectEditCheck_Ev01E00044 - HDAE5000_WriteProtectEditCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_WriteProtectEditCheck_Ev01E00045 - HDAE5000_WriteProtectEditCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_WriteProtectEditCheck_Ev01E00046 - HDAE5000_WriteProtectEditCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_WriteProtectEditCheck_Ev01E00047 - HDAE5000_WriteProtectEditCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_1d:	; 0x2E2A60
	; read by LyricJumpEditCheck at 0x285F5A (pushed operand)
	.asciz "%1d"
;
; HDAE5000_LyricJumpEditCheck_CaseTable (0x2E2A64, 10 x u16): the switch of HDAE5000_LyricJumpEditCheck
; (dispatch at 0x285F4E, hdae5000_hd_driver.s:4475: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_LyricJumpEditCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_LyricJumpEditCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_LyricJumpEditCheck_CaseTable:
	.short	HDAE5000_LyricJumpEditCheck_Ev01E0003E - HDAE5000_LyricJumpEditCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_LyricJumpEditCheck_Ev01E0003E - HDAE5000_LyricJumpEditCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_LyricJumpEditCheck_Default - HDAE5000_LyricJumpEditCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_LyricJumpEditCheck_Default - HDAE5000_LyricJumpEditCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_LyricJumpEditCheck_Default - HDAE5000_LyricJumpEditCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_LyricJumpEditCheck_Ev01E00043 - HDAE5000_LyricJumpEditCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_LyricJumpEditCheck_Ev01E00044 - HDAE5000_LyricJumpEditCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_LyricJumpEditCheck_Ev01E00045 - HDAE5000_LyricJumpEditCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_LyricJumpEditCheck_Ev01E00046 - HDAE5000_LyricJumpEditCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_LyricJumpEditCheck_Ev01E00047 - HDAE5000_LyricJumpEditCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_1d_LyricJumpEditCheck:	; 0x2E2A78
	; read by LyricJumpEditCheck at 0x285FAD (pushed operand)
	.asciz "%1d"
HDAE5000_TextPtrs_RED_to_YELLOW:	; 0x2E2A7C, 5 x .long -> string
	; read by LyricForeColorCheck at 0x286023 (ld # operand); 5 string pointers, 4 bytes each, entry i at +4*i
	.long	HDAE5000_Str_RED
	.long	HDAE5000_Str_GREEN
	.long	HDAE5000_Str_BLUE
	.long	HDAE5000_Str_BLACK
	.long	HDAE5000_Str_YELLOW
HDAE5000_Str_YELLOW:	; 0x2E2A90
	; pointed at by entry 4 of HDAE5000_TextPtrs_RED_to_YELLOW, a table read by LyricForeColorCheck
	.asciz " YELLOW"
HDAE5000_Str_BLACK:	; 0x2E2A98
	; pointed at by entry 3 of HDAE5000_TextPtrs_RED_to_YELLOW, a table read by LyricForeColorCheck
	.asciz " BLACK "
HDAE5000_Str_BLUE:	; 0x2E2AA0
	; pointed at by entry 2 of HDAE5000_TextPtrs_RED_to_YELLOW, a table read by LyricForeColorCheck
	.asciz " BLUE  "
HDAE5000_Str_GREEN:	; 0x2E2AA8
	; pointed at by entry 1 of HDAE5000_TextPtrs_RED_to_YELLOW, a table read by LyricForeColorCheck
	.asciz " GREEN "
HDAE5000_Str_RED:	; 0x2E2AB0
	; pointed at by entry 0 of HDAE5000_TextPtrs_RED_to_YELLOW, a table read by LyricForeColorCheck
	.asciz " RED   "
HDAE5000_Fmt_s_LyricForeColorCheck:	; 0x2E2AB8
	; read by LyricForeColorCheck at 0x286030 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_LyricForeColorCheck_CaseTable (0x2E2ABC, 10 x u16): the switch of HDAE5000_LyricForeColorCheck
; (dispatch at 0x286018, hdae5000_hd_driver.s:4557: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_LyricForeColorCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_LyricForeColorCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_LyricForeColorCheck_CaseTable:
	.short	HDAE5000_LyricForeColorCheck_Ev01E0003E - HDAE5000_LyricForeColorCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_LyricForeColorCheck_Ev01E0003F - HDAE5000_LyricForeColorCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_LyricForeColorCheck_Default - HDAE5000_LyricForeColorCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_LyricForeColorCheck_Default - HDAE5000_LyricForeColorCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_LyricForeColorCheck_Default - HDAE5000_LyricForeColorCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_LyricForeColorCheck_Ev01E00043 - HDAE5000_LyricForeColorCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_LyricForeColorCheck_Ev01E00044 - HDAE5000_LyricForeColorCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_LyricForeColorCheck_Ev01E00045 - HDAE5000_LyricForeColorCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_LyricForeColorCheck_Ev01E00046 - HDAE5000_LyricForeColorCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_LyricForeColorCheck_Ev01E00047 - HDAE5000_LyricForeColorCheck_Ev01E00047	; 0x01E00047
HDAE5000_TextPtrs_RED_to_YELLOW_2:	; 0x2E2AD0, 5 x .long -> string
	; read by LyricBackColorCheck at 0x2860A2 (ld # operand); 5 string pointers, 4 bytes each, entry i at +4*i
	.long	HDAE5000_Str_RED_2
	.long	HDAE5000_Str_GREEN_2
	.long	HDAE5000_Str_BLUE_2
	.long	HDAE5000_Str_BLACK_2
	.long	HDAE5000_Str_YELLOW_2
HDAE5000_Str_YELLOW_2:	; 0x2E2AE4
	; pointed at by entry 4 of HDAE5000_TextPtrs_RED_to_YELLOW_2, a table read by LyricBackColorCheck
	.asciz " YELLOW"
HDAE5000_Str_BLACK_2:	; 0x2E2AEC
	; pointed at by entry 3 of HDAE5000_TextPtrs_RED_to_YELLOW_2, a table read by LyricBackColorCheck
	.asciz " BLACK "
HDAE5000_Str_BLUE_2:	; 0x2E2AF4
	; pointed at by entry 2 of HDAE5000_TextPtrs_RED_to_YELLOW_2, a table read by LyricBackColorCheck
	.asciz " BLUE  "
HDAE5000_Str_GREEN_2:	; 0x2E2AFC
	; pointed at by entry 1 of HDAE5000_TextPtrs_RED_to_YELLOW_2, a table read by LyricBackColorCheck
	.asciz " GREEN "
HDAE5000_Str_RED_2:	; 0x2E2B04
	; pointed at by entry 0 of HDAE5000_TextPtrs_RED_to_YELLOW_2, a table read by LyricBackColorCheck
	.asciz " RED   "
HDAE5000_Fmt_s_LyricBackColorCheck:	; 0x2E2B0C
	; read by LyricBackColorCheck at 0x2860AF (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_LyricBackColorCheck_CaseTable (0x2E2B10, 10 x u16): the switch of HDAE5000_LyricBackColorCheck
; (dispatch at 0x286097, hdae5000_hd_driver.s:4609: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_LyricBackColorCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_LyricBackColorCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_LyricBackColorCheck_CaseTable:
	.short	HDAE5000_LyricBackColorCheck_Ev01E0003E - HDAE5000_LyricBackColorCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_LyricBackColorCheck_Ev01E0003F - HDAE5000_LyricBackColorCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_LyricBackColorCheck_Default - HDAE5000_LyricBackColorCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_LyricBackColorCheck_Default - HDAE5000_LyricBackColorCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_LyricBackColorCheck_Default - HDAE5000_LyricBackColorCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_LyricBackColorCheck_Ev01E00043 - HDAE5000_LyricBackColorCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_LyricBackColorCheck_Ev01E00044 - HDAE5000_LyricBackColorCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_LyricBackColorCheck_Ev01E00045 - HDAE5000_LyricBackColorCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_LyricBackColorCheck_Ev01E00046 - HDAE5000_LyricBackColorCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_LyricBackColorCheck_Ev01E00047 - HDAE5000_LyricBackColorCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_WriteConfirmEditCheck:	; 0x2E2B24
	; read by WriteConfirmEditCheck at 0x28612E (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_WriteConfirmEditCheck_CaseTable (0x2E2B28, 10 x u16): the switch of HDAE5000_WriteConfirmEditCheck
; (dispatch at 0x286116, hdae5000_hd_driver.s:4661: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_WriteConfirmEditCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_WriteConfirmEditCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_WriteConfirmEditCheck_CaseTable:
	.short	HDAE5000_WriteConfirmEditCheck_Ev01E0003E - HDAE5000_WriteConfirmEditCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_WriteConfirmEditCheck_Ev01E0003E - HDAE5000_WriteConfirmEditCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_WriteConfirmEditCheck_Default - HDAE5000_WriteConfirmEditCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_WriteConfirmEditCheck_Default - HDAE5000_WriteConfirmEditCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_WriteConfirmEditCheck_Default - HDAE5000_WriteConfirmEditCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_WriteConfirmEditCheck_Ev01E00043 - HDAE5000_WriteConfirmEditCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_WriteConfirmEditCheck_Ev01E00044 - HDAE5000_WriteConfirmEditCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_WriteConfirmEditCheck_Ev01E00045 - HDAE5000_WriteConfirmEditCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_WriteConfirmEditCheck_Ev01E00046 - HDAE5000_WriteConfirmEditCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_WriteConfirmEditCheck_Ev01E00047 - HDAE5000_WriteConfirmEditCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_1d_QuickLoadModeEditCheck:	; 0x2E2B3C
	; read by QuickLoadModeEditCheck at 0x28619D (pushed operand)
	.asciz "%1d"
;
; HDAE5000_QuickLoadModeEditCheck_CaseTable (0x2E2B40, 10 x u16): the switch of HDAE5000_QuickLoadModeEditCheck
; (dispatch at 0x286191, hdae5000_hd_driver.s:4711: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_QuickLoadModeEditCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_QuickLoadModeEditCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_QuickLoadModeEditCheck_CaseTable:
	.short	HDAE5000_QuickLoadModeEditCheck_Ev01E0003E - HDAE5000_QuickLoadModeEditCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_QuickLoadModeEditCheck_Ev01E0003E - HDAE5000_QuickLoadModeEditCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_QuickLoadModeEditCheck_Default - HDAE5000_QuickLoadModeEditCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_QuickLoadModeEditCheck_Default - HDAE5000_QuickLoadModeEditCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_QuickLoadModeEditCheck_Default - HDAE5000_QuickLoadModeEditCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_QuickLoadModeEditCheck_Ev01E00043 - HDAE5000_QuickLoadModeEditCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_QuickLoadModeEditCheck_Ev01E00044 - HDAE5000_QuickLoadModeEditCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_QuickLoadModeEditCheck_Ev01E00045 - HDAE5000_QuickLoadModeEditCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_QuickLoadModeEditCheck_Ev01E00046 - HDAE5000_QuickLoadModeEditCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_QuickLoadModeEditCheck_Ev01E00047 - HDAE5000_QuickLoadModeEditCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_1d_LoadByNumberModeEditCheck:	; 0x2E2B54
	; read by LoadByNumberModeEditCheck at 0x28620C (pushed operand)
	.asciz "%1d"
;
; HDAE5000_LoadByNumberModeEditCheck_CaseTable (0x2E2B58, 10 x u16): the switch of HDAE5000_LoadByNumberModeEditCheck
; (dispatch at 0x286200, hdae5000_hd_driver.s:4757: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_LoadByNumberModeEditCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_LoadByNumberModeEditCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_LoadByNumberModeEditCheck_CaseTable:
	.short	HDAE5000_LoadByNumberModeEditCheck_Ev01E0003E - HDAE5000_LoadByNumberModeEditCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_LoadByNumberModeEditCheck_Ev01E0003E - HDAE5000_LoadByNumberModeEditCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_LoadByNumberModeEditCheck_Default - HDAE5000_LoadByNumberModeEditCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_LoadByNumberModeEditCheck_Default - HDAE5000_LoadByNumberModeEditCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_LoadByNumberModeEditCheck_Default - HDAE5000_LoadByNumberModeEditCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_LoadByNumberModeEditCheck_Ev01E00043 - HDAE5000_LoadByNumberModeEditCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_LoadByNumberModeEditCheck_Ev01E00044 - HDAE5000_LoadByNumberModeEditCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_LoadByNumberModeEditCheck_Ev01E00045 - HDAE5000_LoadByNumberModeEditCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_LoadByNumberModeEditCheck_Ev01E00046 - HDAE5000_LoadByNumberModeEditCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_LoadByNumberModeEditCheck_Ev01E00047 - HDAE5000_LoadByNumberModeEditCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_1d_JumpAfterLoadModeEditCheck:	; 0x2E2B6C
	; read by JumpAfterLoadModeEditCheck at 0x28627B (pushed operand)
	.asciz "%1d"
;
; HDAE5000_JumpAfterLoadModeEditCheck_CaseTable (0x2E2B70, 10 x u16): the switch of HDAE5000_JumpAfterLoadModeEditCheck
; (dispatch at 0x28626F, hdae5000_hd_driver.s:4803: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_JumpAfterLoadModeEditCheck_CaseTable:
	.short	HDAE5000_JumpAfterLoadModeEditCheck_Ev01E0003E - HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_JumpAfterLoadModeEditCheck_Ev01E0003E - HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_JumpAfterLoadModeEditCheck_Default - HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_JumpAfterLoadModeEditCheck_Default - HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_JumpAfterLoadModeEditCheck_Default - HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00043 - HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00044 - HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00045 - HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00046 - HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00047 - HDAE5000_JumpAfterLoadModeEditCheck_Ev01E00047	; 0x01E00047
HDAE5000_DriveInfo_Template:	; 0x2E2B84
	; read by SetupPage_BuildDriveInfo at 0x2862B2 (lda operand)
	.asciz "HD-TYPE             :                 \tTRACKS              :                 \tHEADS               :                 \tSECTORS PER TRACK   :                 \tTOTAL HD       (MB) :                 \tUSED BY SYSTEM (MB) :                 \tFREE FOR USE   (MB) :                 \tSOFTWARE RELEASE    :                 \t"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_6_1f:	; 0x2E2CBE
	; read by SetupPage_BuildDriveInfo at 0x28639D (pushed operand)
	.asciz "%6.1f"
HDAE5000_Fmt_6_1f_SetupPage_BuildDriveInfo:	; 0x2E2CC4
	; read by SetupPage_BuildDriveInfo at 0x286403 (pushed operand)
	.asciz "%6.1f"
HDAE5000_Fmt_6_1f_SetupPage_BuildDriveInfo_2:	; 0x2E2CCA
	; read by SetupPage_BuildDriveInfo at 0x286466 (pushed operand)
	.asciz "%6.1f"
HDAE5000_Float_100_DriveInfo:	; 0x2E2CD0
	; read by SetupPage_BuildDriveInfo at 0x28637A (lda operand)
	; IEEE single 100.0: a divisor of HDAE5000_SetupPage_BuildDriveInfo (10,000-byte units -> MB)
	.long 0x42c80000		; 100.0f
HDAE5000_Float_100_DriveInfo_2:	; 0x2E2CD4
	; read by SetupPage_BuildDriveInfo at 0x2863E0 (lda operand)
	; IEEE single 100.0: a divisor of HDAE5000_SetupPage_BuildDriveInfo
	.long 0x42c80000		; 100.0f
HDAE5000_Float_100_DriveInfo_3:	; 0x2E2CD8
	; read by SetupPage_BuildDriveInfo at 0x286443 (lda operand)
	; IEEE single 100.0: a divisor of HDAE5000_SetupPage_BuildDriveInfo
	.long 0x42c80000		; 100.0f
HDAE5000_Str_FMT:	; 0x2E2CDC
	; read by AttenHDFormatSwCatch at 0x2866C5 (lda operand)
	.asciz "FMT!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_AttenHDFormatSwCatch_CaseTable (0x2E2CE2, 8 x u16): the switch of HDAE5000_AttenHDFormatSwCatch
; (dispatch at 0x286728, hdae5000_hd_driver.s:5233: bound `cp xwa,7`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_AttenHDFormatSwCatch_Case0)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_AttenHDFormatSwCatch_Case0 of the case for value 0+i; 8 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_AttenHDFormatSwCatch_CaseTable:
	.short	HDAE5000_AttenHDFormatSwCatch_Case0 - HDAE5000_AttenHDFormatSwCatch_Case0	; 0
	.short	HDAE5000_AttenHDFormatSwCatch_Case1 - HDAE5000_AttenHDFormatSwCatch_Case0	; 1
	.short	HDAE5000_AttenHDFormatSwCatch_Case2 - HDAE5000_AttenHDFormatSwCatch_Case0	; 2
	.short	HDAE5000_AttenHDFormatSwCatch_Case3 - HDAE5000_AttenHDFormatSwCatch_Case0	; 3
	.short	HDAE5000_AttenHDFormatSwCatch_Case4 - HDAE5000_AttenHDFormatSwCatch_Case0	; 4
	.short	.LCHSC__post_switch - HDAE5000_AttenHDFormatSwCatch_Case0	; 5 (default)
	.short	HDAE5000_AttenHDFormatSwCatch_Case6 - HDAE5000_AttenHDFormatSwCatch_Case0	; 6
	.short	HDAE5000_AttenHDFormatSwCatch_Case6 - HDAE5000_AttenHDFormatSwCatch_Case0	; 7
;
; HDAE5000_Lbn_StepDigit_CaseTable (0x2E2CF2, 6 x u16): the switch of HDAE5000_Lbn_StepDigit
; (dispatch at 0x286A49, hdae5000_hd_driver.s:5493: bound `cp xwa,5`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_Lbn_StepDigit_Case0)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_Lbn_StepDigit_Case0 of the case for value 0+i; 6 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_Lbn_StepDigit_CaseTable:
	.short	HDAE5000_Lbn_StepDigit_Case0 - HDAE5000_Lbn_StepDigit_Case0	; 0
	.short	HDAE5000_Lbn_StepDigit_Case1 - HDAE5000_Lbn_StepDigit_Case0	; 1
	.short	HDAE5000_Lbn_StepDigit_Case2 - HDAE5000_Lbn_StepDigit_Case0	; 2
	.short	HDAE5000_Lbn_StepDigit_Case3 - HDAE5000_Lbn_StepDigit_Case0	; 3
	.short	HDAE5000_Lbn_StepDigit_Case4 - HDAE5000_Lbn_StepDigit_Case0	; 4
	.short	HDAE5000_Lbn_StepDigit_Case5 - HDAE5000_Lbn_StepDigit_Case0	; 5
HDAE5000_Str_LBNS:	; 0x2E2CFE
	; read by LBNPage1SwCatch at 0x286BB7 (lda operand)
	.asciz "LBNS"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_LBNPage1SwCatch_CaseTable (0x2E2D04, 13 x u16): the switch of HDAE5000_LBNPage1SwCatch
; (dispatch at 0x286C15, hdae5000_hd_driver.s:5660: bound `cp xwa,12`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_LBNPage1SwCatch_Case12)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_LBNPage1SwCatch_Case12 of the case for value 0+i; 13 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_LBNPage1SwCatch_CaseTable:
	.short	HDAE5000_LBNPage1SwCatch_Case0 - HDAE5000_LBNPage1SwCatch_Case12	; 0
	.short	HDAE5000_LBNPage1SwCatch_Case1 - HDAE5000_LBNPage1SwCatch_Case12	; 1
	.short	HDAE5000_LBNPage1SwCatch_Case2 - HDAE5000_LBNPage1SwCatch_Case12	; 2
	.short	HDAE5000_LBNPage1SwCatch_Case3 - HDAE5000_LBNPage1SwCatch_Case12	; 3
	.short	HDAE5000_LBNPage1SwCatch_Case4 - HDAE5000_LBNPage1SwCatch_Case12	; 4
	.short	HDAE5000_LBNPage1SwCatch_Case5 - HDAE5000_LBNPage1SwCatch_Case12	; 5
	.short	HDAE5000_LBNPage1SwCatch_Case5 - HDAE5000_LBNPage1SwCatch_Case12	; 6
	.short	HDAE5000_LBNPage1SwCatch_Case5 - HDAE5000_LBNPage1SwCatch_Case12	; 7
	.short	.LHD_SR__a_exit - HDAE5000_LBNPage1SwCatch_Case12	; 8 (default)
	.short	.LHD_SR__a_exit - HDAE5000_LBNPage1SwCatch_Case12	; 9 (default)
	.short	.LHD_SR__a_exit - HDAE5000_LBNPage1SwCatch_Case12	; 10 (default)
	.short	.LHD_SR__a_exit - HDAE5000_LBNPage1SwCatch_Case12	; 11 (default)
	.short	HDAE5000_LBNPage1SwCatch_Case12 - HDAE5000_LBNPage1SwCatch_Case12	; 12
HDAE5000_Str_LBN:	; 0x2E2D1E
	; read by LBNLoadSwCatch at 0x286D7A (lda operand)
	.asciz "LBN!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_1_1d:	; 0x2E2D24
	; read by Lbn_ShowEntry at 0x287162 (pushed operand)
	.asciz "%1.1d"
HDAE5000_Fmt_2_2d_Lbn_ShowEntry:	; 0x2E2D2A
	; read by Lbn_ShowEntry at 0x287196 (pushed operand)
	.asciz "%2.2d"
HDAE5000_Fmt_3_3d_Lbn_ShowEntry:	; 0x2E2D30
	; read by Lbn_ShowEntry at 0x2871C2 (pushed operand)
	.asciz "%3.3d"
HDAE5000_Fmt_1_1d_Lbn_ShowEntry:	; 0x2E2D36
	; read by Lbn_ShowEntry at 0x287222 (pushed operand)
	.asciz " %1.1d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_2_2d_Lbn_ShowEntry_2:	; 0x2E2D3E
	; read by Lbn_ShowEntry at 0x287250 (pushed operand)
	.asciz " %2.2d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_Lbn_ShowEntry_CaseTable (0x2E2D46, 7 x u16): the switch of HDAE5000_Lbn_ShowEntry
; (dispatch at 0x2870FC, hdae5000_filesystem.s:17: bound `cp xwa,6`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_Lbn_ShowEntry_Case0)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_Lbn_ShowEntry_Case0 of the case for value 0+i; 7 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_Lbn_ShowEntry_CaseTable:
	.short	HDAE5000_Lbn_ShowEntry_Case0 - HDAE5000_Lbn_ShowEntry_Case0	; 0
	.short	HDAE5000_Lbn_ShowEntry_Case1 - HDAE5000_Lbn_ShowEntry_Case0	; 1
	.short	HDAE5000_Lbn_ShowEntry_Case2 - HDAE5000_Lbn_ShowEntry_Case0	; 2
	.short	HDAE5000_Lbn_ShowEntry_Case3 - HDAE5000_Lbn_ShowEntry_Case0	; 3
	.short	HDAE5000_Lbn_ShowEntry_Case4 - HDAE5000_Lbn_ShowEntry_Case0	; 4
	.short	HDAE5000_Lbn_ShowEntry_Case5 - HDAE5000_Lbn_ShowEntry_Case0	; 5
	.short	HDAE5000_Lbn_ShowEntry_Case6 - HDAE5000_Lbn_ShowEntry_Case0	; 6
HDAE5000_Str_Blank26:	; 0x2E2D54
	; read by FileLBNNameCheck at 0x2875C4 (pushed operand)
	.asciz "                          "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_s_FileLBNNameCheck:	; 0x2E2D70
	; read by FileLBNNameCheck at 0x2875B1 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_FileLBNNameCheck_CaseTable (0x2E2D74, 10 x u16): the switch of HDAE5000_FileLBNNameCheck
; (dispatch at 0x28758F, hdae5000_filesystem.s:362: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_FileLBNNameCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_FileLBNNameCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_FileLBNNameCheck_CaseTable:
	.short	HDAE5000_FileLBNNameCheck_Ev01E0003E - HDAE5000_FileLBNNameCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_FileLBNNameCheck_Ev01E0003F - HDAE5000_FileLBNNameCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_FileLBNNameCheck_Default - HDAE5000_FileLBNNameCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_FileLBNNameCheck_Default - HDAE5000_FileLBNNameCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_FileLBNNameCheck_Default - HDAE5000_FileLBNNameCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_FileLBNNameCheck_Ev01E00043 - HDAE5000_FileLBNNameCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_FileLBNNameCheck_Ev01E00044 - HDAE5000_FileLBNNameCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_FileLBNNameCheck_Ev01E00045 - HDAE5000_FileLBNNameCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_FileLBNNameCheck_Ev01E00046 - HDAE5000_FileLBNNameCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_FileLBNNameCheck_Ev01E00047 - HDAE5000_FileLBNNameCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_LBNLswBitCheck:	; 0x2E2D88
	; read by LBNLswBitCheck at 0x287651 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_LBNLswBitCheck_CaseTable (0x2E2D8C, 10 x u16): the switch of HDAE5000_LBNLswBitCheck
; (dispatch at 0x287630, hdae5000_filesystem.s:425: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_LBNLswBitCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_LBNLswBitCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_LBNLswBitCheck_CaseTable:
	.short	HDAE5000_LBNLswBitCheck_Ev01E0003E - HDAE5000_LBNLswBitCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_LBNLswBitCheck_Ev01E0003F - HDAE5000_LBNLswBitCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_LBNLswBitCheck_Default - HDAE5000_LBNLswBitCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_LBNLswBitCheck_Default - HDAE5000_LBNLswBitCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_LBNLswBitCheck_Default - HDAE5000_LBNLswBitCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_LBNLswBitCheck_Ev01E00043 - HDAE5000_LBNLswBitCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_LBNLswBitCheck_Ev01E00044 - HDAE5000_LBNLswBitCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_LBNLswBitCheck_Ev01E00045 - HDAE5000_LBNLswBitCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_LBNLswBitCheck_Ev01E00046 - HDAE5000_LBNLswBitCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_LBNLswBitCheck_Ev01E00047 - HDAE5000_LBNLswBitCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_LBNPmtBitCheck:	; 0x2E2DA0
	; read by LBNPmtBitCheck at 0x28775B (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_LBNPmtBitCheck_CaseTable (0x2E2DA4, 10 x u16): the switch of HDAE5000_LBNPmtBitCheck
; (dispatch at 0x28773A, hdae5000_filesystem.s:524: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_LBNPmtBitCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_LBNPmtBitCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_LBNPmtBitCheck_CaseTable:
	.short	HDAE5000_LBNPmtBitCheck_Ev01E0003E - HDAE5000_LBNPmtBitCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_LBNPmtBitCheck_Ev01E0003F - HDAE5000_LBNPmtBitCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_LBNPmtBitCheck_Default - HDAE5000_LBNPmtBitCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_LBNPmtBitCheck_Default - HDAE5000_LBNPmtBitCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_LBNPmtBitCheck_Default - HDAE5000_LBNPmtBitCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_LBNPmtBitCheck_Ev01E00043 - HDAE5000_LBNPmtBitCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_LBNPmtBitCheck_Ev01E00044 - HDAE5000_LBNPmtBitCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_LBNPmtBitCheck_Ev01E00045 - HDAE5000_LBNPmtBitCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_LBNPmtBitCheck_Ev01E00046 - HDAE5000_LBNPmtBitCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_LBNPmtBitCheck_Ev01E00047 - HDAE5000_LBNPmtBitCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_LBNSqtBitCheck:	; 0x2E2DB8
	; read by LBNSqtBitCheck at 0x287865 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_LBNSqtBitCheck_CaseTable (0x2E2DBC, 10 x u16): the switch of HDAE5000_LBNSqtBitCheck
; (dispatch at 0x287844, hdae5000_filesystem.s:623: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_LBNSqtBitCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_LBNSqtBitCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_LBNSqtBitCheck_CaseTable:
	.short	HDAE5000_LBNSqtBitCheck_Ev01E0003E - HDAE5000_LBNSqtBitCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_LBNSqtBitCheck_Ev01E0003F - HDAE5000_LBNSqtBitCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_LBNSqtBitCheck_Default - HDAE5000_LBNSqtBitCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_LBNSqtBitCheck_Default - HDAE5000_LBNSqtBitCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_LBNSqtBitCheck_Default - HDAE5000_LBNSqtBitCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_LBNSqtBitCheck_Ev01E00043 - HDAE5000_LBNSqtBitCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_LBNSqtBitCheck_Ev01E00044 - HDAE5000_LBNSqtBitCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_LBNSqtBitCheck_Ev01E00045 - HDAE5000_LBNSqtBitCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_LBNSqtBitCheck_Ev01E00046 - HDAE5000_LBNSqtBitCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_LBNSqtBitCheck_Ev01E00047 - HDAE5000_LBNSqtBitCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_LBNCmpBitCheck:	; 0x2E2DD0
	; read by LBNCmpBitCheck at 0x28796F (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_LBNCmpBitCheck_CaseTable (0x2E2DD4, 10 x u16): the switch of HDAE5000_LBNCmpBitCheck
; (dispatch at 0x28794E, hdae5000_filesystem.s:722: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_LBNCmpBitCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_LBNCmpBitCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_LBNCmpBitCheck_CaseTable:
	.short	HDAE5000_LBNCmpBitCheck_Ev01E0003E - HDAE5000_LBNCmpBitCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_LBNCmpBitCheck_Ev01E0003F - HDAE5000_LBNCmpBitCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_LBNCmpBitCheck_Default - HDAE5000_LBNCmpBitCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_LBNCmpBitCheck_Default - HDAE5000_LBNCmpBitCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_LBNCmpBitCheck_Default - HDAE5000_LBNCmpBitCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_LBNCmpBitCheck_Ev01E00043 - HDAE5000_LBNCmpBitCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_LBNCmpBitCheck_Ev01E00044 - HDAE5000_LBNCmpBitCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_LBNCmpBitCheck_Ev01E00045 - HDAE5000_LBNCmpBitCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_LBNCmpBitCheck_Ev01E00046 - HDAE5000_LBNCmpBitCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_LBNCmpBitCheck_Ev01E00047 - HDAE5000_LBNCmpBitCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_LBNTmBitCheck:	; 0x2E2DE8
	; read by LBNTmBitCheck at 0x287A79 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_LBNTmBitCheck_CaseTable (0x2E2DEC, 10 x u16): the switch of HDAE5000_LBNTmBitCheck
; (dispatch at 0x287A58, hdae5000_filesystem.s:821: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_LBNTmBitCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_LBNTmBitCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_LBNTmBitCheck_CaseTable:
	.short	HDAE5000_LBNTmBitCheck_Ev01E0003E - HDAE5000_LBNTmBitCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_LBNTmBitCheck_Ev01E0003F - HDAE5000_LBNTmBitCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_LBNTmBitCheck_Default - HDAE5000_LBNTmBitCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_LBNTmBitCheck_Default - HDAE5000_LBNTmBitCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_LBNTmBitCheck_Default - HDAE5000_LBNTmBitCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_LBNTmBitCheck_Ev01E00043 - HDAE5000_LBNTmBitCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_LBNTmBitCheck_Ev01E00044 - HDAE5000_LBNTmBitCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_LBNTmBitCheck_Ev01E00045 - HDAE5000_LBNTmBitCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_LBNTmBitCheck_Ev01E00046 - HDAE5000_LBNTmBitCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_LBNTmBitCheck_Ev01E00047 - HDAE5000_LBNTmBitCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_LBNMspBitCheck:	; 0x2E2E00
	; read by LBNMspBitCheck at 0x287B83 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_LBNMspBitCheck_CaseTable (0x2E2E04, 10 x u16): the switch of HDAE5000_LBNMspBitCheck
; (dispatch at 0x287B62, hdae5000_filesystem.s:920: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_LBNMspBitCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_LBNMspBitCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_LBNMspBitCheck_CaseTable:
	.short	HDAE5000_LBNMspBitCheck_Ev01E0003E - HDAE5000_LBNMspBitCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_LBNMspBitCheck_Ev01E0003F - HDAE5000_LBNMspBitCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_LBNMspBitCheck_Default - HDAE5000_LBNMspBitCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_LBNMspBitCheck_Default - HDAE5000_LBNMspBitCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_LBNMspBitCheck_Default - HDAE5000_LBNMspBitCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_LBNMspBitCheck_Ev01E00043 - HDAE5000_LBNMspBitCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_LBNMspBitCheck_Ev01E00044 - HDAE5000_LBNMspBitCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_LBNMspBitCheck_Ev01E00045 - HDAE5000_LBNMspBitCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_LBNMspBitCheck_Ev01E00046 - HDAE5000_LBNMspBitCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_LBNMspBitCheck_Ev01E00047 - HDAE5000_LBNMspBitCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_LBNRcmBitCheck:	; 0x2E2E18
	; read by LBNRcmBitCheck at 0x287C8D (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_LBNRcmBitCheck_CaseTable (0x2E2E1C, 10 x u16): the switch of HDAE5000_LBNRcmBitCheck
; (dispatch at 0x287C6C, hdae5000_filesystem.s:1019: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_LBNRcmBitCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_LBNRcmBitCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_LBNRcmBitCheck_CaseTable:
	.short	HDAE5000_LBNRcmBitCheck_Ev01E0003E - HDAE5000_LBNRcmBitCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_LBNRcmBitCheck_Ev01E0003F - HDAE5000_LBNRcmBitCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_LBNRcmBitCheck_Default - HDAE5000_LBNRcmBitCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_LBNRcmBitCheck_Default - HDAE5000_LBNRcmBitCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_LBNRcmBitCheck_Default - HDAE5000_LBNRcmBitCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_LBNRcmBitCheck_Ev01E00043 - HDAE5000_LBNRcmBitCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_LBNRcmBitCheck_Ev01E00044 - HDAE5000_LBNRcmBitCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_LBNRcmBitCheck_Ev01E00045 - HDAE5000_LBNRcmBitCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_LBNRcmBitCheck_Ev01E00046 - HDAE5000_LBNRcmBitCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_LBNRcmBitCheck_Ev01E00047 - HDAE5000_LBNRcmBitCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_LBNMdBitCheck:	; 0x2E2E30
	; read by LBNMdBitCheck at 0x287D97 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_LBNMdBitCheck_CaseTable (0x2E2E34, 10 x u16): the switch of HDAE5000_LBNMdBitCheck
; (dispatch at 0x287D76, hdae5000_filesystem.s:1118: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_LBNMdBitCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_LBNMdBitCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_LBNMdBitCheck_CaseTable:
	.short	HDAE5000_LBNMdBitCheck_Ev01E0003E - HDAE5000_LBNMdBitCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_LBNMdBitCheck_Ev01E0003F - HDAE5000_LBNMdBitCheck_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_LBNMdBitCheck_Default - HDAE5000_LBNMdBitCheck_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_LBNMdBitCheck_Default - HDAE5000_LBNMdBitCheck_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_LBNMdBitCheck_Default - HDAE5000_LBNMdBitCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_LBNMdBitCheck_Ev01E00043 - HDAE5000_LBNMdBitCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_LBNMdBitCheck_Ev01E00044 - HDAE5000_LBNMdBitCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_LBNMdBitCheck_Ev01E00045 - HDAE5000_LBNMdBitCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_LBNMdBitCheck_Ev01E00046 - HDAE5000_LBNMdBitCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_LBNMdBitCheck_Ev01E00047 - HDAE5000_LBNMdBitCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_LBNTlxBitCheck_Unregistered:	; 0x2E2E48
	; read by LBNTlxBitCheck_Unregistered at 0x287EA1 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_LBNTlxBitCheck_Unregistered_CaseTable (0x2E2E4C, 10 x u16): the switch of HDAE5000_LBNTlxBitCheck_Unregistered
; (dispatch at 0x287E80, hdae5000_filesystem.s:1222: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_LBNTlxBitCheck_Unregistered_CaseTable:
	.short	HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E0003E - HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E0003F - HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E00047	; 0x01E0003F
	.short	HDAE5000_LBNTlxBitCheck_Unregistered_Default - HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E00047	; 0x01E00040 (default)
	.short	HDAE5000_LBNTlxBitCheck_Unregistered_Default - HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E00047	; 0x01E00041 (default)
	.short	HDAE5000_LBNTlxBitCheck_Unregistered_Default - HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E00043 - HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E00047	; 0x01E00043
	.short	HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E00044 - HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E00047	; 0x01E00044
	.short	HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E00045 - HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E00047	; 0x01E00045
	.short	HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E00046 - HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E00047	; 0x01E00046
	.short	HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E00047 - HDAE5000_LBNTlxBitCheck_Unregistered_Ev01E00047	; 0x01E00047
HDAE5000_Str_Chr2020203A2020_FlsList_BuildPage:	; 0x2E2E60
	; read by FlsList_BuildPage at 0x287F77 (lda operand)
	.asciz "   :                \t"
HDAE5000_Fmt_3_3d_FlsList_BuildPage:	; 0x2E2E76
	; read by FlsList_BuildPage at 0x287F9B (pushed operand)
	.asciz "%3.3d"
HDAE5000_FlsScreen_Refresh_ObjIds:	; 0x2E2E7C
	; read by FlsScreen_Refresh at 0x288338 (lda operand); UI object ids (0x007F0000 + index into HDAE5000_UiObjectName_PtrTable), 4 bytes each
	.long HDAE5000_OBJ_FLS_NAME_BOX		; UI object 325 "FLS_NAME_BOX"
	.long HDAE5000_OBJ_FLS_EDIT_NAME_BOX		; UI object 358 "FLS_EDIT_NAME_BOX"
HDAE5000_FlsScreen_Refresh_ObjIds_2:	; 0x2E2E84
	; read by FlsScreen_Refresh at 0x28848E (lda operand); UI object ids (0x007F0000 + index into HDAE5000_UiObjectName_PtrTable), 4 bytes each
	.long HDAE5000_OBJ_FLS_FILE_BOX		; UI object 328 "FLS_FILE_BOX"
	.long HDAE5000_OBJ_FLS_EDIT_LIST_BOX		; UI object 361 "FLS_EDIT_LIST_BOX"
HDAE5000_FlsScreen_Refresh_ObjIds_3:	; 0x2E2E8C
	; read by FlsScreen_Refresh at 0x288566 (lda operand); UI object ids (0x007F0000 + index into HDAE5000_UiObjectName_PtrTable), 4 bytes each
	.long HDAE5000_OBJ_FLS_LOC_BOX		; UI object 324 "FLS_LOC_BOX"
	.long HDAE5000_OBJ_FLS_EDIT_LOC_BOX		; UI object 374 "FLS_EDIT_LOC_BOX"
HDAE5000_FlsScreen_Refresh_ObjIds_4:	; 0x2E2E94
	; read by FlsScreen_Refresh at 0x2885D8 (lda operand); UI object ids (0x007F0000 + index into HDAE5000_UiObjectName_PtrTable), 4 bytes each
	.long HDAE5000_OBJ_FLS_OPT_BOX		; UI object 323 "FLS_OPT_BOX"
	.long HDAE5000_OBJ_FLS_EDIT_OPT_BOX		; UI object 375 "FLS_EDIT_OPT_BOX"
HDAE5000_FlsScreen_Refresh_ObjIds_5:	; 0x2E2E9C
	; read by FlsScreen_Refresh at 0x28861A (lda operand); UI object ids (0x007F0000 + index into HDAE5000_UiObjectName_PtrTable), 4 bytes each
	.long HDAE5000_OBJ_FLS_LOAD_LINE1		; UI object 329 "FLS_LOAD_LINE1"
	.long HDAE5000_OBJ_FLS_EDIT_LINE1		; UI object 363 "FLS_EDIT_LINE1"
HDAE5000_FlsScreen_Refresh_ObjIds_6:	; 0x2E2EA4
	; read by FlsScreen_Refresh at 0x288644 (lda operand); UI object ids (0x007F0000 + index into HDAE5000_UiObjectName_PtrTable), 4 bytes each
	.long HDAE5000_OBJ_FLS_LOAD_LINE2		; UI object 330 "FLS_LOAD_LINE2"
	.long HDAE5000_OBJ_FLS_EDIT_LINE2		; UI object 362 "FLS_EDIT_LINE2"
HDAE5000_Str_FLSNAME:	; 0x2E2EAC
	; read by FlsScreen_Refresh at 0x2882BF (pushed operand)
	.asciz "FLS NAME "
HDAE5000_Fmt_2_2d_FlsScreen_Refresh:	; 0x2E2EB6
	; read by FlsScreen_Refresh at 0x2882D7 (pushed operand)
	.asciz "%2.2d"
HDAE5000_Str_Chr3A_FlsScreen_Refresh:	; 0x2E2EBC
	; read by FlsScreen_Refresh at 0x2882F6 (pushed operand)
	.asciz ":"
HDAE5000_Str_Blank0Tab_FlsScreen_Refresh:	; 0x2E2EBE
	; read by FlsScreen_Refresh at 0x288320 (pushed operand)
	.asciz "\t"
HDAE5000_Str_Chr3A2020202020_FlsScreen_Refresh:	; 0x2E2EC0
	; read by FlsScreen_Refresh at 0x2883A9 (lda operand)
	.asciz ":                                 \t"
HDAE5000_Fmt_2_2d_FlsScreen_Refresh_2:	; 0x2E2EE4
	; read by FlsScreen_Refresh at 0x2883D1 (pushed operand)
	.asciz "%2.2d"
HDAE5000_Fmt_LOC_3_3d_2_2d:	; 0x2E2EEA
	; read by FlsScreen_Refresh at 0x288524 (pushed operand)
	.asciz " LOC. %3.3d/%2.2d\t"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_LOC00000:	; 0x2E2EFE
	; read by FlsScreen_Refresh at 0x288537 (pushed operand)
	.asciz " LOC. 000/00\t"
HDAE5000_Str_FLS:	; 0x2E2F0C
	; read by FlsFileLoadSwCatch at 0x288C64 (lda operand)
	.asciz "FLS!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_DEL1:	; 0x2E2F12
	; read by FlsDel1SwCatch at 0x289038 (lda operand)
	.asciz "DEL1"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_DEL2:	; 0x2E2F18
	; read by FlsDel2SwCatch at 0x289135 (lda operand)
	.asciz "DEL2"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_OVWR:	; 0x2E2F1E
	; read by FlsOverWrSwCatch at 0x289579 (lda operand)
	.asciz "OVWR"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_2_2d_CopyToHd_Execute:	; 0x2E2F24
	; read by CopyToHd_Execute at 0x2898D2 (pushed operand)
	.asciz "%2.2d"
HDAE5000_Str_LSW:	; 0x2E2F2A
	; read by CopyToHd_Execute at 0x28996D (pushed operand)
	.asciz ".LSW"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_PMT:	; 0x2E2F30
	; read by CopyToHd_Execute at 0x2899BA (pushed operand)
	.asciz ".PMT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_SQT:	; 0x2E2F36
	; read by CopyToHd_Execute at 0x289A08 (pushed operand)
	.asciz ".SQT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_CMP:	; 0x2E2F3C
	; read by CopyToHd_Execute at 0x289A56 (pushed operand)
	.asciz ".CMP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_TM:	; 0x2E2F42
	; read by CopyToHd_Execute at 0x289AA4 (pushed operand)
	.asciz ".TM"
HDAE5000_Str_MSP:	; 0x2E2F46
	; read by CopyToHd_Execute at 0x289AF2 (pushed operand)
	.asciz ".MSP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_RCM:	; 0x2E2F4C
	; read by CopyToHd_Execute at 0x289B40 (pushed operand)
	.asciz ".RCM"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_MD:	; 0x2E2F52
	; read by CopyToHd_Execute at 0x289B8E (pushed operand)
	.asciz ".MD"
HDAE5000_Str_TLX:	; 0x2E2F56
	; read by CopyToHd_Execute at 0x289BDC (pushed operand)
	.asciz ".TLX"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Wrcn:	; 0x2E2F5C
	; read by WrConfirmEventCatch at 0x28A1EB (lda operand)
	.asciz "WrCn"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_DEL_DelOptSwEventCatch:	; 0x2E2F62
	; read by DelOptSwEventCatch at 0x28A4DB (lda operand)
	.asciz "DEL!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_s_DelOptNameCheck:	; 0x2E2F68
	; read by DelOptNameCheck at 0x28A665 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_DelOptNameCheck_CaseTable (0x2E2F6C, 10 x u16): the switch of HDAE5000_DelOptNameCheck
; (dispatch at 0x28A64C, hdae5000_filesystem.s:4440: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_DelOptNameCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_DelOptNameCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_DelOptNameCheck_CaseTable:
	.short	HDAE5000_DelOptNameCheck_Ev01E0003E - HDAE5000_DelOptNameCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_DelOptNameCheck_Ev01E0003F - HDAE5000_DelOptNameCheck_Ev01E00047	; 0x01E0003F
	.short	.LDUO__hA_default - HDAE5000_DelOptNameCheck_Ev01E00047	; 0x01E00040 (default)
	.short	.LDUO__hA_default - HDAE5000_DelOptNameCheck_Ev01E00047	; 0x01E00041 (default)
	.short	.LDUO__hA_default - HDAE5000_DelOptNameCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_DelOptNameCheck_Ev01E00043 - HDAE5000_DelOptNameCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_DelOptNameCheck_Ev01E00044 - HDAE5000_DelOptNameCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_DelOptNameCheck_Ev01E00045 - HDAE5000_DelOptNameCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_DelOptNameCheck_Ev01E00046 - HDAE5000_DelOptNameCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_DelOptNameCheck_Ev01E00047 - HDAE5000_DelOptNameCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_DelLswEditCheck:	; 0x2E2F80
	; read by DelLswEditCheck at 0x28A6E7 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_DelLswEditCheck_CaseTable (0x2E2F84, 10 x u16): the switch of HDAE5000_DelLswEditCheck
; (dispatch at 0x28A6CF, hdae5000_filesystem.s:4500: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_DelLswEditCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_DelLswEditCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_DelLswEditCheck_CaseTable:
	.short	HDAE5000_DelLswEditCheck_Ev01E0003E - HDAE5000_DelLswEditCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_DelLswEditCheck_Ev01E0003F - HDAE5000_DelLswEditCheck_Ev01E00047	; 0x01E0003F
	.short	.LDUO__hB_default - HDAE5000_DelLswEditCheck_Ev01E00047	; 0x01E00040 (default)
	.short	.LDUO__hB_default - HDAE5000_DelLswEditCheck_Ev01E00047	; 0x01E00041 (default)
	.short	.LDUO__hB_default - HDAE5000_DelLswEditCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_DelLswEditCheck_Ev01E00043 - HDAE5000_DelLswEditCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_DelLswEditCheck_Ev01E00044 - HDAE5000_DelLswEditCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_DelLswEditCheck_Ev01E00045 - HDAE5000_DelLswEditCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_DelLswEditCheck_Ev01E00046 - HDAE5000_DelLswEditCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_DelLswEditCheck_Ev01E00047 - HDAE5000_DelLswEditCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_DelPmtEditCheck:	; 0x2E2F98
	; read by DelPmtEditCheck at 0x28A782 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_DelPmtEditCheck_CaseTable (0x2E2F9C, 10 x u16): the switch of HDAE5000_DelPmtEditCheck
; (dispatch at 0x28A76A, hdae5000_filesystem.s:4570: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_DelPmtEditCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_DelPmtEditCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_DelPmtEditCheck_CaseTable:
	.short	HDAE5000_DelPmtEditCheck_Ev01E0003E - HDAE5000_DelPmtEditCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_DelPmtEditCheck_Ev01E0003F - HDAE5000_DelPmtEditCheck_Ev01E00047	; 0x01E0003F
	.short	.LDUO__hC_default - HDAE5000_DelPmtEditCheck_Ev01E00047	; 0x01E00040 (default)
	.short	.LDUO__hC_default - HDAE5000_DelPmtEditCheck_Ev01E00047	; 0x01E00041 (default)
	.short	.LDUO__hC_default - HDAE5000_DelPmtEditCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_DelPmtEditCheck_Ev01E00043 - HDAE5000_DelPmtEditCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_DelPmtEditCheck_Ev01E00044 - HDAE5000_DelPmtEditCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_DelPmtEditCheck_Ev01E00045 - HDAE5000_DelPmtEditCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_DelPmtEditCheck_Ev01E00046 - HDAE5000_DelPmtEditCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_DelPmtEditCheck_Ev01E00047 - HDAE5000_DelPmtEditCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_DelSqtEditCheck:	; 0x2E2FB0
	; read by DelSqtEditCheck at 0x28A81D (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_DelSqtEditCheck_CaseTable (0x2E2FB4, 10 x u16): the switch of HDAE5000_DelSqtEditCheck
; (dispatch at 0x28A805, hdae5000_filesystem.s:4640: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_DelSqtEditCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_DelSqtEditCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_DelSqtEditCheck_CaseTable:
	.short	HDAE5000_DelSqtEditCheck_Ev01E0003E - HDAE5000_DelSqtEditCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_DelSqtEditCheck_Ev01E0003F - HDAE5000_DelSqtEditCheck_Ev01E00047	; 0x01E0003F
	.short	.LDUO__hD_default - HDAE5000_DelSqtEditCheck_Ev01E00047	; 0x01E00040 (default)
	.short	.LDUO__hD_default - HDAE5000_DelSqtEditCheck_Ev01E00047	; 0x01E00041 (default)
	.short	.LDUO__hD_default - HDAE5000_DelSqtEditCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_DelSqtEditCheck_Ev01E00043 - HDAE5000_DelSqtEditCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_DelSqtEditCheck_Ev01E00044 - HDAE5000_DelSqtEditCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_DelSqtEditCheck_Ev01E00045 - HDAE5000_DelSqtEditCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_DelSqtEditCheck_Ev01E00046 - HDAE5000_DelSqtEditCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_DelSqtEditCheck_Ev01E00047 - HDAE5000_DelSqtEditCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_DelCmpEditCheck:	; 0x2E2FC8
	; read by DelCmpEditCheck at 0x28A8B8 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_DelCmpEditCheck_CaseTable (0x2E2FCC, 10 x u16): the switch of HDAE5000_DelCmpEditCheck
; (dispatch at 0x28A8A0, hdae5000_filesystem.s:4710: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_DelCmpEditCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_DelCmpEditCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_DelCmpEditCheck_CaseTable:
	.short	HDAE5000_DelCmpEditCheck_Ev01E0003E - HDAE5000_DelCmpEditCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_DelCmpEditCheck_Ev01E0003F - HDAE5000_DelCmpEditCheck_Ev01E00047	; 0x01E0003F
	.short	.LDUO__hE_default - HDAE5000_DelCmpEditCheck_Ev01E00047	; 0x01E00040 (default)
	.short	.LDUO__hE_default - HDAE5000_DelCmpEditCheck_Ev01E00047	; 0x01E00041 (default)
	.short	.LDUO__hE_default - HDAE5000_DelCmpEditCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_DelCmpEditCheck_Ev01E00043 - HDAE5000_DelCmpEditCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_DelCmpEditCheck_Ev01E00044 - HDAE5000_DelCmpEditCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_DelCmpEditCheck_Ev01E00045 - HDAE5000_DelCmpEditCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_DelCmpEditCheck_Ev01E00046 - HDAE5000_DelCmpEditCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_DelCmpEditCheck_Ev01E00047 - HDAE5000_DelCmpEditCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_DelTmEditCheck:	; 0x2E2FE0
	; read by DelTmEditCheck at 0x28A953 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_DelTmEditCheck_CaseTable (0x2E2FE4, 10 x u16): the switch of HDAE5000_DelTmEditCheck
; (dispatch at 0x28A93B, hdae5000_filesystem.s:4780: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_DelTmEditCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_DelTmEditCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_DelTmEditCheck_CaseTable:
	.short	HDAE5000_DelTmEditCheck_Ev01E0003E - HDAE5000_DelTmEditCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_DelTmEditCheck_Ev01E0003F - HDAE5000_DelTmEditCheck_Ev01E00047	; 0x01E0003F
	.short	.LDUO__hF_default - HDAE5000_DelTmEditCheck_Ev01E00047	; 0x01E00040 (default)
	.short	.LDUO__hF_default - HDAE5000_DelTmEditCheck_Ev01E00047	; 0x01E00041 (default)
	.short	.LDUO__hF_default - HDAE5000_DelTmEditCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_DelTmEditCheck_Ev01E00043 - HDAE5000_DelTmEditCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_DelTmEditCheck_Ev01E00044 - HDAE5000_DelTmEditCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_DelTmEditCheck_Ev01E00045 - HDAE5000_DelTmEditCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_DelTmEditCheck_Ev01E00046 - HDAE5000_DelTmEditCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_DelTmEditCheck_Ev01E00047 - HDAE5000_DelTmEditCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_DelMspEditCheck:	; 0x2E2FF8
	; read by DelMspEditCheck at 0x28A9EE (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_DelMspEditCheck_CaseTable (0x2E2FFC, 10 x u16): the switch of HDAE5000_DelMspEditCheck
; (dispatch at 0x28A9D6, hdae5000_filesystem.s:4850: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_DelMspEditCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_DelMspEditCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_DelMspEditCheck_CaseTable:
	.short	HDAE5000_DelMspEditCheck_Ev01E0003E - HDAE5000_DelMspEditCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_DelMspEditCheck_Ev01E0003F - HDAE5000_DelMspEditCheck_Ev01E00047	; 0x01E0003F
	.short	.LDUO__hG_default - HDAE5000_DelMspEditCheck_Ev01E00047	; 0x01E00040 (default)
	.short	.LDUO__hG_default - HDAE5000_DelMspEditCheck_Ev01E00047	; 0x01E00041 (default)
	.short	.LDUO__hG_default - HDAE5000_DelMspEditCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_DelMspEditCheck_Ev01E00043 - HDAE5000_DelMspEditCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_DelMspEditCheck_Ev01E00044 - HDAE5000_DelMspEditCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_DelMspEditCheck_Ev01E00045 - HDAE5000_DelMspEditCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_DelMspEditCheck_Ev01E00046 - HDAE5000_DelMspEditCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_DelMspEditCheck_Ev01E00047 - HDAE5000_DelMspEditCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_DelRcmEditCheck:	; 0x2E3010
	; read by DelRcmEditCheck at 0x28AA89 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_DelRcmEditCheck_CaseTable (0x2E3014, 10 x u16): the switch of HDAE5000_DelRcmEditCheck
; (dispatch at 0x28AA71, hdae5000_filesystem.s:4920: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_DelRcmEditCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_DelRcmEditCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_DelRcmEditCheck_CaseTable:
	.short	HDAE5000_DelRcmEditCheck_Ev01E0003E - HDAE5000_DelRcmEditCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_DelRcmEditCheck_Ev01E0003F - HDAE5000_DelRcmEditCheck_Ev01E00047	; 0x01E0003F
	.short	.LDUO__hH_default - HDAE5000_DelRcmEditCheck_Ev01E00047	; 0x01E00040 (default)
	.short	.LDUO__hH_default - HDAE5000_DelRcmEditCheck_Ev01E00047	; 0x01E00041 (default)
	.short	.LDUO__hH_default - HDAE5000_DelRcmEditCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_DelRcmEditCheck_Ev01E00043 - HDAE5000_DelRcmEditCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_DelRcmEditCheck_Ev01E00044 - HDAE5000_DelRcmEditCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_DelRcmEditCheck_Ev01E00045 - HDAE5000_DelRcmEditCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_DelRcmEditCheck_Ev01E00046 - HDAE5000_DelRcmEditCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_DelRcmEditCheck_Ev01E00047 - HDAE5000_DelRcmEditCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_DelMdEditCheck:	; 0x2E3028
	; read by DelMdEditCheck at 0x28AB24 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_DelMdEditCheck_CaseTable (0x2E302C, 10 x u16): the switch of HDAE5000_DelMdEditCheck
; (dispatch at 0x28AB0C, hdae5000_filesystem.s:4990: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_DelMdEditCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_DelMdEditCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_DelMdEditCheck_CaseTable:
	.short	HDAE5000_DelMdEditCheck_Ev01E0003E - HDAE5000_DelMdEditCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_DelMdEditCheck_Ev01E0003F - HDAE5000_DelMdEditCheck_Ev01E00047	; 0x01E0003F
	.short	.LDUO__hI_default - HDAE5000_DelMdEditCheck_Ev01E00047	; 0x01E00040 (default)
	.short	.LDUO__hI_default - HDAE5000_DelMdEditCheck_Ev01E00047	; 0x01E00041 (default)
	.short	.LDUO__hI_default - HDAE5000_DelMdEditCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_DelMdEditCheck_Ev01E00043 - HDAE5000_DelMdEditCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_DelMdEditCheck_Ev01E00044 - HDAE5000_DelMdEditCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_DelMdEditCheck_Ev01E00045 - HDAE5000_DelMdEditCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_DelMdEditCheck_Ev01E00046 - HDAE5000_DelMdEditCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_DelMdEditCheck_Ev01E00047 - HDAE5000_DelMdEditCheck_Ev01E00047	; 0x01E00047
HDAE5000_Fmt_s_DelTlxEditCheck:	; 0x2E3040
	; read by DelTlxEditCheck at 0x28ABC2 (pushed operand)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_DelTlxEditCheck_CaseTable (0x2E3044, 10 x u16): the switch of HDAE5000_DelTlxEditCheck
; (dispatch at 0x28ABAA, hdae5000_filesystem.s:5060: `sub xwa,0x01e0003e`, bound `cp xwa,9`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_DelTlxEditCheck_Ev01E00047)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_DelTlxEditCheck_Ev01E00047 of the case for event 0x01E0003E+i; 10 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_DelTlxEditCheck_CaseTable:
	.short	HDAE5000_DelTlxEditCheck_Ev01E0003E - HDAE5000_DelTlxEditCheck_Ev01E00047	; 0x01E0003E
	.short	HDAE5000_DelTlxEditCheck_Ev01E0003F - HDAE5000_DelTlxEditCheck_Ev01E00047	; 0x01E0003F
	.short	.LDUO__hJ_default - HDAE5000_DelTlxEditCheck_Ev01E00047	; 0x01E00040 (default)
	.short	.LDUO__hJ_default - HDAE5000_DelTlxEditCheck_Ev01E00047	; 0x01E00041 (default)
	.short	.LDUO__hJ_default - HDAE5000_DelTlxEditCheck_Ev01E00047	; 0x01E00042 (default)
	.short	HDAE5000_DelTlxEditCheck_Ev01E00043 - HDAE5000_DelTlxEditCheck_Ev01E00047	; 0x01E00043
	.short	HDAE5000_DelTlxEditCheck_Ev01E00044 - HDAE5000_DelTlxEditCheck_Ev01E00047	; 0x01E00044
	.short	HDAE5000_DelTlxEditCheck_Ev01E00045 - HDAE5000_DelTlxEditCheck_Ev01E00047	; 0x01E00045
	.short	HDAE5000_DelTlxEditCheck_Ev01E00046 - HDAE5000_DelTlxEditCheck_Ev01E00047	; 0x01E00046
	.short	HDAE5000_DelTlxEditCheck_Ev01E00047 - HDAE5000_DelTlxEditCheck_Ev01E00047	; 0x01E00047
HDAE5000_Str_Timb:	; 0x2E3058
	; read by ErrMsgTimerCatch at 0x28B44C (lda operand)
	.asciz "TimB"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_TLBN:	; 0x2E305E
	; read by ErrMsgTimerCatchLBN at 0x28B4D8 (lda operand)
	.asciz "TLBN"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_Palette_Button01 (0x2E3064, 1024 B): 256 RGBX entries, entry i =
; (i, i, i, 0) -- a grey ramp -- placed, as everywhere in this ROM's
; graphics bank, immediately before its bitmap (HDAE5000_Bitmap_Button01).
; No code in this ROM reads it; whether the main CPU does (at the bitmap
; pointer - 0x400) is not established.
;
HDAE5000_Palette_Button01:
	.byte 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x00, 0x02, 0x02, 0x02, 0x00, 0x03, 0x03, 0x03, 0x00
	.byte 0x04, 0x04, 0x04, 0x00, 0x05, 0x05, 0x05, 0x00, 0x06, 0x06, 0x06, 0x00, 0x07, 0x07, 0x07, 0x00
	.byte 0x08, 0x08, 0x08, 0x00, 0x09, 0x09, 0x09, 0x00, 0x0a, 0x0a, 0x0a, 0x00, 0x0b, 0x0b, 0x0b, 0x00
	.byte 0x0c, 0x0c, 0x0c, 0x00, 0x0d, 0x0d, 0x0d, 0x00, 0x0e, 0x0e, 0x0e, 0x00, 0x0f, 0x0f, 0x0f, 0x00
	.byte 0x10, 0x10, 0x10, 0x00, 0x11, 0x11, 0x11, 0x00, 0x12, 0x12, 0x12, 0x00, 0x13, 0x13, 0x13, 0x00
	.byte 0x14, 0x14, 0x14, 0x00, 0x15, 0x15, 0x15, 0x00, 0x16, 0x16, 0x16, 0x00, 0x17, 0x17, 0x17, 0x00
	.byte 0x18, 0x18, 0x18, 0x00, 0x19, 0x19, 0x19, 0x00, 0x1a, 0x1a, 0x1a, 0x00, 0x1b, 0x1b, 0x1b, 0x00
	.byte 0x1c, 0x1c, 0x1c, 0x00, 0x1d, 0x1d, 0x1d, 0x00, 0x1e, 0x1e, 0x1e, 0x00, 0x1f, 0x1f, 0x1f, 0x00
	.byte 0x20, 0x20, 0x20, 0x00, 0x21, 0x21, 0x21, 0x00, 0x22, 0x22, 0x22, 0x00, 0x23, 0x23, 0x23, 0x00
	.byte 0x24, 0x24, 0x24, 0x00, 0x25, 0x25, 0x25, 0x00, 0x26, 0x26, 0x26, 0x00, 0x27, 0x27, 0x27, 0x00
	.byte 0x28, 0x28, 0x28, 0x00, 0x29, 0x29, 0x29, 0x00, 0x2a, 0x2a, 0x2a, 0x00, 0x2b, 0x2b, 0x2b, 0x00
	.byte 0x2c, 0x2c, 0x2c, 0x00, 0x2d, 0x2d, 0x2d, 0x00, 0x2e, 0x2e, 0x2e, 0x00, 0x2f, 0x2f, 0x2f, 0x00
	.byte 0x30, 0x30, 0x30, 0x00, 0x31, 0x31, 0x31, 0x00, 0x32, 0x32, 0x32, 0x00, 0x33, 0x33, 0x33, 0x00
	.byte 0x34, 0x34, 0x34, 0x00, 0x35, 0x35, 0x35, 0x00, 0x36, 0x36, 0x36, 0x00, 0x37, 0x37, 0x37, 0x00
	.byte 0x38, 0x38, 0x38, 0x00, 0x39, 0x39, 0x39, 0x00, 0x3a, 0x3a, 0x3a, 0x00, 0x3b, 0x3b, 0x3b, 0x00
	.byte 0x3c, 0x3c, 0x3c, 0x00, 0x3d, 0x3d, 0x3d, 0x00, 0x3e, 0x3e, 0x3e, 0x00, 0x3f, 0x3f, 0x3f, 0x00
	.byte 0x40, 0x40, 0x40, 0x00, 0x41, 0x41, 0x41, 0x00, 0x42, 0x42, 0x42, 0x00, 0x43, 0x43, 0x43, 0x00
	.byte 0x44, 0x44, 0x44, 0x00, 0x45, 0x45, 0x45, 0x00, 0x46, 0x46, 0x46, 0x00, 0x47, 0x47, 0x47, 0x00
	.byte 0x48, 0x48, 0x48, 0x00, 0x49, 0x49, 0x49, 0x00, 0x4a, 0x4a, 0x4a, 0x00, 0x4b, 0x4b, 0x4b, 0x00
	.byte 0x4c, 0x4c, 0x4c, 0x00, 0x4d, 0x4d, 0x4d, 0x00, 0x4e, 0x4e, 0x4e, 0x00, 0x4f, 0x4f, 0x4f, 0x00
	.byte 0x50, 0x50, 0x50, 0x00, 0x51, 0x51, 0x51, 0x00, 0x52, 0x52, 0x52, 0x00, 0x53, 0x53, 0x53, 0x00
	.byte 0x54, 0x54, 0x54, 0x00, 0x55, 0x55, 0x55, 0x00, 0x56, 0x56, 0x56, 0x00, 0x57, 0x57, 0x57, 0x00
	.byte 0x58, 0x58, 0x58, 0x00, 0x59, 0x59, 0x59, 0x00, 0x5a, 0x5a, 0x5a, 0x00, 0x5b, 0x5b, 0x5b, 0x00
	.byte 0x5c, 0x5c, 0x5c, 0x00, 0x5d, 0x5d, 0x5d, 0x00, 0x5e, 0x5e, 0x5e, 0x00, 0x5f, 0x5f, 0x5f, 0x00
	.byte 0x60, 0x60, 0x60, 0x00, 0x61, 0x61, 0x61, 0x00, 0x62, 0x62, 0x62, 0x00, 0x63, 0x63, 0x63, 0x00
	.byte 0x64, 0x64, 0x64, 0x00, 0x65, 0x65, 0x65, 0x00, 0x66, 0x66, 0x66, 0x00, 0x67, 0x67, 0x67, 0x00
	.byte 0x68, 0x68, 0x68, 0x00, 0x69, 0x69, 0x69, 0x00, 0x6a, 0x6a, 0x6a, 0x00, 0x6b, 0x6b, 0x6b, 0x00
	.byte 0x6c, 0x6c, 0x6c, 0x00, 0x6d, 0x6d, 0x6d, 0x00, 0x6e, 0x6e, 0x6e, 0x00, 0x6f, 0x6f, 0x6f, 0x00
	.byte 0x70, 0x70, 0x70, 0x00, 0x71, 0x71, 0x71, 0x00, 0x72, 0x72, 0x72, 0x00, 0x73, 0x73, 0x73, 0x00
	.byte 0x74, 0x74, 0x74, 0x00, 0x75, 0x75, 0x75, 0x00, 0x76, 0x76, 0x76, 0x00, 0x77, 0x77, 0x77, 0x00
	.byte 0x78, 0x78, 0x78, 0x00, 0x79, 0x79, 0x79, 0x00, 0x7a, 0x7a, 0x7a, 0x00, 0x7b, 0x7b, 0x7b, 0x00
	.byte 0x7c, 0x7c, 0x7c, 0x00, 0x7d, 0x7d, 0x7d, 0x00, 0x7e, 0x7e, 0x7e, 0x00, 0x7f, 0x7f, 0x7f, 0x00
	.byte 0x80, 0x80, 0x80, 0x00, 0x81, 0x81, 0x81, 0x00, 0x82, 0x82, 0x82, 0x00, 0x83, 0x83, 0x83, 0x00
	.byte 0x84, 0x84, 0x84, 0x00, 0x85, 0x85, 0x85, 0x00, 0x86, 0x86, 0x86, 0x00, 0x87, 0x87, 0x87, 0x00
	.byte 0x88, 0x88, 0x88, 0x00, 0x89, 0x89, 0x89, 0x00, 0x8a, 0x8a, 0x8a, 0x00, 0x8b, 0x8b, 0x8b, 0x00
	.byte 0x8c, 0x8c, 0x8c, 0x00, 0x8d, 0x8d, 0x8d, 0x00, 0x8e, 0x8e, 0x8e, 0x00, 0x8f, 0x8f, 0x8f, 0x00
	.byte 0x90, 0x90, 0x90, 0x00, 0x91, 0x91, 0x91, 0x00, 0x92, 0x92, 0x92, 0x00, 0x93, 0x93, 0x93, 0x00
	.byte 0x94, 0x94, 0x94, 0x00, 0x95, 0x95, 0x95, 0x00, 0x96, 0x96, 0x96, 0x00, 0x97, 0x97, 0x97, 0x00
	.byte 0x98, 0x98, 0x98, 0x00, 0x99, 0x99, 0x99, 0x00, 0x9a, 0x9a, 0x9a, 0x00, 0x9b, 0x9b, 0x9b, 0x00
	.byte 0x9c, 0x9c, 0x9c, 0x00, 0x9d, 0x9d, 0x9d, 0x00, 0x9e, 0x9e, 0x9e, 0x00, 0x9f, 0x9f, 0x9f, 0x00
	.byte 0xa0, 0xa0, 0xa0, 0x00, 0xa1, 0xa1, 0xa1, 0x00, 0xa2, 0xa2, 0xa2, 0x00, 0xa3, 0xa3, 0xa3, 0x00
	.byte 0xa4, 0xa4, 0xa4, 0x00, 0xa5, 0xa5, 0xa5, 0x00, 0xa6, 0xa6, 0xa6, 0x00, 0xa7, 0xa7, 0xa7, 0x00
	.byte 0xa8, 0xa8, 0xa8, 0x00, 0xa9, 0xa9, 0xa9, 0x00, 0xaa, 0xaa, 0xaa, 0x00, 0xab, 0xab, 0xab, 0x00
	.byte 0xac, 0xac, 0xac, 0x00, 0xad, 0xad, 0xad, 0x00, 0xae, 0xae, 0xae, 0x00, 0xaf, 0xaf, 0xaf, 0x00
	.byte 0xb0, 0xb0, 0xb0, 0x00, 0xb1, 0xb1, 0xb1, 0x00, 0xb2, 0xb2, 0xb2, 0x00, 0xb3, 0xb3, 0xb3, 0x00
	.byte 0xb4, 0xb4, 0xb4, 0x00, 0xb5, 0xb5, 0xb5, 0x00, 0xb6, 0xb6, 0xb6, 0x00, 0xb7, 0xb7, 0xb7, 0x00
	.byte 0xb8, 0xb8, 0xb8, 0x00, 0xb9, 0xb9, 0xb9, 0x00, 0xba, 0xba, 0xba, 0x00, 0xbb, 0xbb, 0xbb, 0x00
	.byte 0xbc, 0xbc, 0xbc, 0x00, 0xbd, 0xbd, 0xbd, 0x00, 0xbe, 0xbe, 0xbe, 0x00, 0xbf, 0xbf, 0xbf, 0x00
	.byte 0xc0, 0xc0, 0xc0, 0x00, 0xc1, 0xc1, 0xc1, 0x00, 0xc2, 0xc2, 0xc2, 0x00, 0xc3, 0xc3, 0xc3, 0x00
	.byte 0xc4, 0xc4, 0xc4, 0x00, 0xc5, 0xc5, 0xc5, 0x00, 0xc6, 0xc6, 0xc6, 0x00, 0xc7, 0xc7, 0xc7, 0x00
	.byte 0xc8, 0xc8, 0xc8, 0x00, 0xc9, 0xc9, 0xc9, 0x00, 0xca, 0xca, 0xca, 0x00, 0xcb, 0xcb, 0xcb, 0x00
	.byte 0xcc, 0xcc, 0xcc, 0x00, 0xcd, 0xcd, 0xcd, 0x00, 0xce, 0xce, 0xce, 0x00, 0xcf, 0xcf, 0xcf, 0x00
	.byte 0xd0, 0xd0, 0xd0, 0x00, 0xd1, 0xd1, 0xd1, 0x00, 0xd2, 0xd2, 0xd2, 0x00, 0xd3, 0xd3, 0xd3, 0x00
	.byte 0xd4, 0xd4, 0xd4, 0x00, 0xd5, 0xd5, 0xd5, 0x00, 0xd6, 0xd6, 0xd6, 0x00, 0xd7, 0xd7, 0xd7, 0x00
	.byte 0xd8, 0xd8, 0xd8, 0x00, 0xd9, 0xd9, 0xd9, 0x00, 0xda, 0xda, 0xda, 0x00, 0xdb, 0xdb, 0xdb, 0x00
	.byte 0xdc, 0xdc, 0xdc, 0x00, 0xdd, 0xdd, 0xdd, 0x00, 0xde, 0xde, 0xde, 0x00, 0xdf, 0xdf, 0xdf, 0x00
	.byte 0xe0, 0xe0, 0xe0, 0x00, 0xe1, 0xe1, 0xe1, 0x00, 0xe2, 0xe2, 0xe2, 0x00, 0xe3, 0xe3, 0xe3, 0x00
	.byte 0xe4, 0xe4, 0xe4, 0x00, 0xe5, 0xe5, 0xe5, 0x00, 0xe6, 0xe6, 0xe6, 0x00, 0xe7, 0xe7, 0xe7, 0x00
	.byte 0xe8, 0xe8, 0xe8, 0x00, 0xe9, 0xe9, 0xe9, 0x00, 0xea, 0xea, 0xea, 0x00, 0xeb, 0xeb, 0xeb, 0x00
	.byte 0xec, 0xec, 0xec, 0x00, 0xed, 0xed, 0xed, 0x00, 0xee, 0xee, 0xee, 0x00, 0xef, 0xef, 0xef, 0x00
	.byte 0xf0, 0xf0, 0xf0, 0x00, 0xf1, 0xf1, 0xf1, 0x00, 0xf2, 0xf2, 0xf2, 0x00, 0xf3, 0xf3, 0xf3, 0x00
	.byte 0xf4, 0xf4, 0xf4, 0x00, 0xf5, 0xf5, 0xf5, 0x00, 0xf6, 0xf6, 0xf6, 0x00, 0xf7, 0xf7, 0xf7, 0x00
	.byte 0xf8, 0xf8, 0xf8, 0x00, 0xf9, 0xf9, 0xf9, 0x00, 0xfa, 0xfa, 0xfa, 0x00, 0xfb, 0xfb, 0xfb, 0x00
	.byte 0xfc, 0xfc, 0xfc, 0x00, 0xfd, 0xfd, 0xfd, 0x00, 0xfe, 0xfe, 0xfe, 0x00, 0xff, 0xff, 0xff, 0x00
;
; HDAE5000_Bitmap_Button01 (0x2E3464, 42 x 15 = 630 B, 8 bpp, one row per
; line): the image of UI object "BitmapButt01".  Its handler
; HDAE5000_BitmapButt01 (0x28B527) answers EVT_GET_BITMAP_DATA 0x01E000A1 with
; this address, EVT_GET_BITMAP_WIDTH 0x01E000A2 with 42 and EVT_GET_BITMAP_HEIGHT
; 0x01E000A3 with 15 (the same protocol the main CPU's bitmap objects use).
;
HDAE5000_Bitmap_Button01:
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x29, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x29
	.byte 0x00, 0x42, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x42
	.byte 0x00, 0x42, 0x5a, 0x7b, 0x7b, 0x7b, 0x7b, 0x00, 0x00, 0x00, 0x7b, 0x7b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7b, 0x7b, 0x00, 0x00, 0x00, 0x7b, 0x7b, 0x7b, 0x00, 0x00, 0x00, 0x00, 0x7b, 0x7b, 0x7b, 0x00, 0x00, 0x00, 0x00, 0x7b, 0x7b, 0x7b, 0x7b, 0x5a, 0x42
	.byte 0x00, 0x42, 0x5a, 0x9c, 0xad, 0xad, 0x00, 0xf7, 0xf7, 0xf7, 0x00, 0xad, 0xf7, 0xf7, 0x00, 0xf7, 0xf7, 0xad, 0x00, 0xf7, 0xf7, 0xf7, 0x00, 0xad, 0xad, 0x00, 0xf7, 0xf7, 0xf7, 0x00, 0xad, 0xad, 0x00, 0xf7, 0xf7, 0xf7, 0xad, 0xad, 0xad, 0x7b, 0x6b, 0x42
	.byte 0x00, 0x42, 0x5a, 0x7b, 0xc6, 0xc6, 0x00, 0xc6, 0xc6, 0xc6, 0xf7, 0xc6, 0xc6, 0xc6, 0x00, 0xc6, 0xc6, 0xc6, 0x00, 0xc6, 0xc6, 0xc6, 0x00, 0xc6, 0xc6, 0x00, 0xc6, 0xc6, 0xc6, 0x00, 0xc6, 0xc6, 0x00, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xb5, 0x7b, 0x5a, 0x42
	.byte 0x00, 0x42, 0x5a, 0x7b, 0xde, 0xde, 0xf7, 0x00, 0x00, 0x00, 0xde, 0xde, 0xde, 0xde, 0x00, 0xde, 0xde, 0xde, 0x00, 0xde, 0xde, 0xde, 0x00, 0xde, 0xde, 0x00, 0xde, 0xde, 0xde, 0x00, 0xde, 0xde, 0x00, 0x00, 0x00, 0xde, 0xde, 0xde, 0xc6, 0x7b, 0x5a, 0x42
	.byte 0x00, 0x42, 0x5a, 0x7b, 0xef, 0xef, 0xef, 0xf7, 0xf7, 0xf7, 0x00, 0xef, 0xef, 0xef, 0x00, 0xef, 0xef, 0xef, 0x00, 0xef, 0xef, 0xef, 0x00, 0xef, 0xef, 0x00, 0x00, 0x00, 0x00, 0xf7, 0xef, 0xef, 0x00, 0xf7, 0xf7, 0xef, 0xef, 0xef, 0xc6, 0x7b, 0x5a, 0x42
	.byte 0x00, 0x29, 0x5a, 0x7b, 0xd6, 0xd6, 0xd6, 0xd6, 0xd6, 0xd6, 0x00, 0xd6, 0xd6, 0xd6, 0x00, 0xd6, 0xd6, 0xd6, 0x00, 0xd6, 0xd6, 0xd6, 0x00, 0xd6, 0xd6, 0x00, 0xf7, 0x00, 0xf7, 0xd6, 0xd6, 0xd6, 0x00, 0xd6, 0xd6, 0xd6, 0xd6, 0xd6, 0xc6, 0x7b, 0x6b, 0x29
	.byte 0x00, 0x42, 0x5a, 0x6b, 0xc6, 0xc6, 0x00, 0xc6, 0xc6, 0xc6, 0x00, 0xc6, 0xc6, 0xc6, 0x00, 0xc6, 0xc6, 0xc6, 0x00, 0xc6, 0xc6, 0xc6, 0x00, 0xc6, 0xc6, 0x00, 0xc6, 0xf7, 0x00, 0xc6, 0xc6, 0xc6, 0x00, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xb5, 0x7b, 0x5a, 0x29
	.byte 0x00, 0x29, 0x5a, 0x7b, 0xad, 0xad, 0xf7, 0x00, 0x00, 0x00, 0xf7, 0xad, 0xad, 0xad, 0x00, 0xad, 0xad, 0xad, 0xf7, 0x00, 0x00, 0x00, 0xf7, 0xad, 0xad, 0x00, 0xad, 0xad, 0xf7, 0x00, 0xad, 0xad, 0x00, 0x00, 0x00, 0x00, 0xad, 0xad, 0xad, 0x7b, 0x5a, 0x29
	.byte 0x00, 0x29, 0x5a, 0x7b, 0x9c, 0x9c, 0x9c, 0xf7, 0xf7, 0xf7, 0x9c, 0x9c, 0x9c, 0x9c, 0xf7, 0x9c, 0x9c, 0x9c, 0x9c, 0xf7, 0xf7, 0xf7, 0x9c, 0x9c, 0x9c, 0xf7, 0x9c, 0x9c, 0x9c, 0xf7, 0x9c, 0x9c, 0xf7, 0xf7, 0xf7, 0xf7, 0x9c, 0x9c, 0x8c, 0x7b, 0x5a, 0x29
	.byte 0x00, 0x29, 0x42, 0x6b, 0x6b, 0x7b, 0x7b, 0x7b, 0x6b, 0x6b, 0x7b, 0x6b, 0x7b, 0x7b, 0x6b, 0x6b, 0x6b, 0x7b, 0x7b, 0x6b, 0x6b, 0x6b, 0x7b, 0x7b, 0x6b, 0x6b, 0x6b, 0x6b, 0x7b, 0x7b, 0x6b, 0x6b, 0x7b, 0x6b, 0x6b, 0x6b, 0x6b, 0x6b, 0x6b, 0x6b, 0x42, 0x29
	.byte 0x00, 0x29, 0x42, 0x29, 0x42, 0x29, 0x29, 0x29, 0x29, 0x29, 0x29, 0x42, 0x29, 0x42, 0x29, 0x42, 0x29, 0x29, 0x29, 0x29, 0x42, 0x29, 0x42, 0x42, 0x29, 0x42, 0x42, 0x29, 0x42, 0x29, 0x29, 0x29, 0x42, 0x29, 0x42, 0x29, 0x42, 0x42, 0x29, 0x29, 0x29, 0x42
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
HDAE5000_Str_Aclanguage1:	; 0x2E36DA
	; read by AcLanguageText1Proc at 0x28B5A1 (lda operand)
	.asciz "AcLanguage1"
HDAE5000_Str_LANENG00:	; 0x2E36E6
	; read by AcLanguageText1Proc at 0x28B60B (pushed operand)
	.asciz "LANENG00"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_LANDEU00:	; 0x2E36F0
	; read by AcLanguageText1Proc at 0x28B62A (pushed operand)
	.asciz "LANDEU00"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_LANFRA00:	; 0x2E36FA
	; read by AcLanguageText1Proc at 0x28B649 (pushed operand)
	.asciz "LANFRA00"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)

; ----------------------------------------------------------------------------
; HDAE5000_Multilingual_Messages (0x2E3704-0x2E5ADF, 9,180 bytes): the texts of
; UI class 016A:000A ("AcLanguageText1Proc", 122 objects in the UI pool), 232
; NUL-terminated strings, word-aligned.
; READER: HDAE5000_AcLanguageText1Proc (0x28B554).  It takes a message number
; N from its object (+0x1A of the descriptor it fetches), switches through
; HDAE5000_LangText_CaseTable (below, after the strings), and each case copies
; one of three strings -- by the language word at (xsp+4): 1 English, 2
; German, 3 French -- into its buffer with HDAE5000_StrCpy.  The pointer is
; pushed as two halves (`pushw 0x002e` / `pushw 0xLLLL`; the low-half line
; names the string label).  N = 1..67 and 200..212; 63, 204, 205 and any
; out-of-range N print "No Message".  Every string here is used by exactly the
; cases found (scripts/converters/hdae5000_label_langtext.py asserts it and
; prints the counts); each carries a label HDAE5000_LangMsg_<N>_<EN|DE|FR>.
; This block label and the first string's label mark the same byte.
; ----------------------------------------------------------------------------
HDAE5000_Multilingual_Messages:	; 0x2E3704
	; Trilingual UI messages (EN/DE/FR)
HDAE5000_LangMsg_001_EN:
	; message 1, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Would you really delete the selected directory?"
HDAE5000_LangMsg_001_DE:
	; message 1, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Moechten Sie das angewaehlte Verzeichnis wirklich loeschen?"
HDAE5000_LangMsg_001_FR:
	; message 1, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Voulez-vous effacer ce r"
	.byte 0xe9  ; "é"
	.asciz "pertoir?"
HDAE5000_LangMsg_002_EN:
	; message 2, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Would you really delete the selected title?"
HDAE5000_LangMsg_002_DE:
	; message 2, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Moechten Sie den angewaehlten Titel wirklich loeschen?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_002_FR:
	; message 2, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Voulez-vous effacer ce titre?"
HDAE5000_LangMsg_003_EN:
	; message 3, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "COPY FD TO HARD DISK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_003_DE:
	; message 3, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "COPY FD TO HARD DISK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_003_FR:
	; message 3, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "COPY FD TO HARD DISK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_004_EN:
	; message 4, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "OUTPUT SETTING"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_004_DE:
	; message 4, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "OUTPUT SETTING"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_004_FR:
	; message 4, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "OUTPUT SETTING"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_005_EN:
	; message 5, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "SELECT BY   NAME    "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_005_DE:
	; message 5, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "SELECT BY   NAME    "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_005_FR:
	; message 5, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "SELECT BY   NAME    "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_006_EN:
	; message 6, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "LOAD BY     NUMBER"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_006_DE:
	; message 6, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "LOAD BY     NUMBER"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_006_FR:
	; message 6, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "LOAD BY     NUMBER"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_007_EN:
	; message 7, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "SELECT FILE LOAD SCRIPT"
HDAE5000_LangMsg_007_DE:
	; message 7, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "SELECT FILE LOAD SCRIPT"
HDAE5000_LangMsg_007_FR:
	; message 7, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "SELECT FILE LOAD SCRIPT"
HDAE5000_LangMsg_008_EN:
	; message 8, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "WRITE PROTECT: "
HDAE5000_LangMsg_008_DE:
	; message 8, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "WRITE PROTECT: "
HDAE5000_LangMsg_008_FR:
	; message 8, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "WRITE PROTECT: "
HDAE5000_LangMsg_009_EN:
	; message 9, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "WRITE CONFIRM: "
HDAE5000_LangMsg_009_DE:
	; message 9, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "WRITE CONFIRM: "
HDAE5000_LangMsg_009_FR:
	; message 9, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "WRITE CONFIRM: "
HDAE5000_LangMsg_010_EN:
	; message 10, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "ABOUT & HELP "
HDAE5000_LangMsg_010_DE:
	; message 10, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "ABOUT & HELP "
HDAE5000_LangMsg_010_FR:
	; message 10, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "ABOUT & HELP "
HDAE5000_LangMsg_011_EN:
	; message 11, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "SAVE SETUP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_011_DE:
	; message 11, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "SAVE SETUP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_011_FR:
	; message 11, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "SAVE SETUP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_012_EN:
	; message 12, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "OUTPUT SETTING"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_012_DE:
	; message 12, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "OUTPUT SETTING"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_012_FR:
	; message 12, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "OUTPUT SETTING"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_013_EN:
	; message 13, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "SEPARATE OUTPUT MODE:"
HDAE5000_LangMsg_013_DE:
	; message 13, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "SEPARATE OUTPUT MODE:"
HDAE5000_LangMsg_013_FR:
	; message 13, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "SEPARATE OUTPUT MODE:"
HDAE5000_LangMsg_014_EN:
	; message 14, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "PART SELECT FOR SEQ.DRUMS OUT:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_014_DE:
	; message 14, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "PART SELECT FOR SEQ.DRUMS OUT:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_014_FR:
	; message 14, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "PART SELECT FOR SEQ.DRUMS OUT:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_015_EN:
	; message 15, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "PART SELECT FOR SEQ.BASS  OUT:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_015_DE:
	; message 15, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "PART SELECT FOR SEQ.BASS  OUT:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_015_FR:
	; message 15, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "PART SELECT FOR SEQ.BASS  OUT:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_016_EN:
	; message 16, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "! The separate outputs cannot be controlled by the internal volume control."
HDAE5000_LangMsg_016_DE:
	; message 16, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "! Die separaten Ausgaenge werden nicht durch Volumen am Keyboard kontrolliert."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_016_FR:
	; message 16, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "! Les sortie s"
	.byte 0xe9  ; "é"
	.ascii "par"
	.byte 0xe9  ; "é"
	.ascii "es ne peuvent pas "
	.byte 0xea  ; "ê"
	.ascii "tre control"
	.byte 0xe9  ; "é"
	.asciz "es par les volume du calvier."
HDAE5000_LangMsg_017_EN:
	; message 17, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Hardware and software developement:"
HDAE5000_LangMsg_017_DE:
	; message 17, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Hardware und Software Entwicklung:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_017_FR:
	; message 17, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Hardware et Software developement:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_018_EN:
	; message 18, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Conception, marketing, sales and service:"
HDAE5000_LangMsg_018_DE:
	; message 18, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Konzeption, Marketing, Verkauf und Service:"
HDAE5000_LangMsg_018_FR:
	; message 18, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Conception, Marketing, Vente et Service:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_019_EN:
	; message 19, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "All rigths reserved by the called companies"
HDAE5000_LangMsg_019_DE:
	; message 19, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Alle Rechte bei den obengenannten Firmen"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_019_FR:
	; message 19, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "All rigths reserved by the called companies"
HDAE5000_LangMsg_020_EN:
	; message 20, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Special thanks to:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_020_DE:
	; message 20, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Spezieller Dank an:"
HDAE5000_LangMsg_020_FR:
	; message 20, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Special thanks to:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_021_EN:
	; message 21, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Press 3 digits for directory and 2 digits for the file."
HDAE5000_LangMsg_021_DE:
	; message 21, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Geben Sie 3 Ziffern fuer das Verzeichnis und 2 Ziffern fuer den Titel ein."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_021_FR:
	; message 21, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Introduisez 3 chiffres pour le r"
	.byte 0xe9  ; "é"
	.asciz "pertoir at 2 chiffres pour le titre."
HDAE5000_LangMsg_022_EN:
	; message 22, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Do you really want to overwrite this FLS entry?"
HDAE5000_LangMsg_022_DE:
	; message 22, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Wollen Sie den bestehenden FLS Eintrag wirklich ueberschreiben?"
HDAE5000_LangMsg_022_FR:
	; message 22, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Voulez-vous vraiment "
	.byte 0xe9  ; "é"
	.asciz "crire par dessus le FLS?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_023_EN:
	; message 23, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Do you really want to delete this FLS entry?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_023_DE:
	; message 23, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Wollen Sie den bestehenden FLS Eintrag wirklich loeschen?"
HDAE5000_LangMsg_023_FR:
	; message 23, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Voulez-vous vraiment effacer ce FLS?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_024_EN:
	; message 24, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "HD FORMAT will erase all files at once."
HDAE5000_LangMsg_024_DE:
	; message 24, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "HD FORMAT loescht alle Daten auf der Festplatte."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_024_FR:
	; message 24, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "HD-FORMAT effacera toutes les donn"
	.byte 0xe9  ; "é"
	.asciz "es de votre disque dur."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_025_EN:
	; message 25, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Therefore you need a 6-digit key code. Please refer your owners manual chapter SETUP & TOOLS."
HDAE5000_LangMsg_025_DE:
	; message 25, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Geben Sie auf dieser Seite den 6-stelligen Code ein. Schauen Sie in der Anleitung unter SETUP & TOOLS nach."
HDAE5000_LangMsg_025_FR:
	; message 25, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Indroduisez le code "
	.byte 0xe0  ; "à"
	.ascii " 6 chiffres et r"
	.byte 0xe9  ; "é"
	.ascii "f"
	.byte 0xe9  ; "é"
	.ascii "rez-vous "
	.byte 0xe0  ; "à"
	.asciz " votre manuel dans (SETUP & TOOLS)."
HDAE5000_LangMsg_026_EN:
	; message 26, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "After your code input all data will be deleted irrevocable!"
HDAE5000_LangMsg_026_DE:
	; message 26, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Nach der Codeeingabe werden alle Daten unwiderruflich geloescht!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_026_FR:
	; message 26, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Apr"
	.byte 0xe8  ; "è"
	.ascii "s l'introduction du code, toutes les donn"
	.byte 0xe9  ; "é"
	.ascii "es seront effac"
	.byte 0xe9  ; "é"
	.asciz "es."
HDAE5000_LangMsg_027_EN:
	; message 27, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "You are going to delete a FLS entry. Are you sure?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_027_DE:
	; message 27, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Sie haben einen FLS Eintrag zum Loeschen markiert. Sind Sie sicher?"
HDAE5000_LangMsg_027_FR:
	; message 27, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Vous avez marquer un FLS connection pour effacer. Vous ait sure?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_028_EN:
	; message 28, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "You are going to overwrite a FLS entry. Are you sure?"
HDAE5000_LangMsg_028_DE:
	; message 28, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Sie ueberschreiben eine bestehenden FLS Eintrag. Sind Sie sicher?"
HDAE5000_LangMsg_028_FR:
	; message 28, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Voulez-vous vraiment transcrire ce FLS enregistration?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_029_EN:
	; message 29, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "The hard disk is write protected!"
HDAE5000_LangMsg_029_DE:
	; message 29, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.ascii "Die Festplatte ist schreibgesch"
	.byte 0xfc  ; "ü"
	.asciz "tzt!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_029_FR:
	; message 29, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Le disque dur est prot"
	.byte 0xe9  ; "é"
	.ascii "ger contre l'"
	.byte 0xe9  ; "é"
	.asciz "ctriture!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_030_EN:
	; message 30, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Please set the write protect mode to OFF."
HDAE5000_LangMsg_030_DE:
	; message 30, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Schalten Sie WRITE PROTECT im SETUP & TOOLS auf OFF."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_030_FR:
	; message 30, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Pour "
	.byte 0xe9  ; "é"
	.asciz "crire mettez la protection sur OFF."
HDAE5000_LangMsg_031_EN:
	; message 31, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "The hard disk is not formatted!"
HDAE5000_LangMsg_031_DE:
	; message 31, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Die Festplatte ist nicht formatiert!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_031_FR:
	; message 31, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Le disque dur n'est pas format"
	.byte 0xe9  ; "é"
	.asciz "."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_032_EN:
	; message 32, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Hard disk SRAM error."
HDAE5000_LangMsg_032_DE:
	; message 32, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Im HD-AE5000 SRAM ist ein Fehler aufgetreten."
HDAE5000_LangMsg_032_FR:
	; message 32, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Il y a un problem avec le SRAM de HD-AE5000."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_033_EN:
	; message 33, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Hard disk reset error."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_033_DE:
	; message 33, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Die Festplatte konnte nicht initialisiert werden."
HDAE5000_LangMsg_033_FR:
	; message 33, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Votre disque dur n'est pas reconnu."
HDAE5000_LangMsg_034_EN:
	; message 34, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Hard disk read error."
HDAE5000_LangMsg_034_DE:
	; message 34, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Beim Lesen der Festplatte ist ein Fehler aufgetreten."
HDAE5000_LangMsg_034_FR:
	; message 34, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Il y a un probl"
	.byte 0xe9  ; "é"
	.asciz "me de leture du disque."
HDAE5000_LangMsg_035_EN:
	; message 35, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Hard disk ID read error."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_035_DE:
	; message 35, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Die ID der Festplatte konnte nicht gelesen werden."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_035_FR:
	; message 35, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "L'ID du disque dur n'a pas pu "
	.byte 0xea  ; "ê"
	.asciz "tre lue."
HDAE5000_LangMsg_036_EN:
	; message 36, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Hard disk track 0 error."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_036_DE:
	; message 36, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Track O der Festplatte konnte nicht gelesen werden."
HDAE5000_LangMsg_036_FR:
	; message 36, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "La piste 0 du disque dur n'a pas pu "
	.byte 0xea  ; "ê"
	.asciz "tre lue."
HDAE5000_LangMsg_037_EN:
	; message 37, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Hard disk FAT read error."
HDAE5000_LangMsg_037_DE:
	; message 37, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Die FAT der Festplatte konnte nicht gelesen werden."
HDAE5000_LangMsg_037_FR:
	; message 37, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Le FAT du disque dur n'a pas pu "
	.byte 0xea  ; "ê"
	.asciz "tre lue."
HDAE5000_LangMsg_038_EN:
	; message 38, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Hard disk FSB read error."
HDAE5000_LangMsg_038_DE:
	; message 38, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Der FSB der Festplatte konnte nicht gelesen werden."
HDAE5000_LangMsg_038_FR:
	; message 38, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Le FSB du disque dur n'a pas pu "
	.byte 0xea  ; "ê"
	.asciz "tre lue."
HDAE5000_LangMsg_039_EN:
	; message 39, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "There are no files marked for copy to HD!"
HDAE5000_LangMsg_039_DE:
	; message 39, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Es wurden keine Titel zum Kopieren gefunden."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_039_FR:
	; message 39, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Aucun titre n'a "
	.byte 0xe9  ; "é"
	.ascii "t"
	.byte 0xe9  ; "é"
	.ascii " marqu"
	.byte 0xe9  ; "é"
	.asciz " pour faire des copies."
HDAE5000_LangMsg_040_EN:
	; message 40, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Please make a safety backup of your data and call your service center."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_040_DE:
	; message 40, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Sichern Sie alle Ihre Daten auf Diskette oder den PC und rufen Sie Ihre Service-Stelle an."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_040_FR:
	; message 40, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Sauvez vos donn"
	.byte 0xe9  ; "é"
	.asciz "e sur disquette ou l'ordinateur et contactez votre service assistance."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_041_EN:
	; message 41, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Please make a safety backup of your data and call your service center."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_041_DE:
	; message 41, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Sichern Sie alle Ihre Daten auf Diskette oder den PC und rufen Sie Ihre Service-Stelle an."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_041_FR:
	; message 41, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Sauvez vos donn"
	.byte 0xe9  ; "é"
	.asciz "e sur disquette ou l'ordinateur et contactez votre service assistance."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_042_EN:
	; message 42, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "The data on the disk you would like to copy to HD has no KN5000 format or some data are corrupted."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_042_DE:
	; message 42, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Die Daten auf der Diskette die Sie kopieren moechten, haben keine KN5000 ID oder sind fehlerhaft."
HDAE5000_LangMsg_042_FR:
	; message 42, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Les donn"
	.byte 0xe9  ; "é"
	.ascii "es que vous voulez charger ne sont pas du KN5000 format ou ont des d"
	.byte 0xe9  ; "é"
	.asciz "faults."
HDAE5000_LangMsg_043_EN:
	; message 43, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "The number or marked songs cannot fit in the free space of the selected directory."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_043_DE:
	; message 43, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Im gewuenschten Verzeichnis sind nicht genuegend freie Plaetze fuer die Anzahl markierter Titel."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_043_FR:
	; message 43, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Le r"
	.byte 0xe9  ; "é"
	.ascii "pertoir est satur"
	.byte 0xe9  ; "é"
	.ascii ", il n'y "
	.byte 0xe0  ; "à"
	.asciz " plus de place pour d'autres titre."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_044_EN:
	; message 44, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Reduce the number of selected songs or find a free directory."
HDAE5000_LangMsg_044_DE:
	; message 44, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Reduzieren Sie die Zahl der Titel oder waehlen Sie ein anderes Verzeichnis."
HDAE5000_LangMsg_044_FR:
	; message 44, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Changer de r"
	.byte 0xe9  ; "é"
	.asciz "pertoire ou supprimez des titres."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_045_EN:
	; message 45, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "You cannot copy files/songs to an unnamed directory."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_045_DE:
	; message 45, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Kopieren Sie keine Titel in ein nicht beschriftetes Verzeichnis."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_045_FR:
	; message 45, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Vous ne pouvez pas copier des titres dans un r"
	.byte 0xe9  ; "é"
	.ascii "pertoire pas pr"
	.byte 0xe9  ; "é"
	.ascii "par"
	.byte 0xe9  ; "é"
	.asciz "."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_046_EN:
	; message 46, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Please use a named directory or create the new directory with EDIT first."
HDAE5000_LangMsg_046_DE:
	; message 46, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Waehlen Sie ein bereits beschriftetes Verzeichnis oder benennen Sie es zuvor mit EDIT."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_046_FR:
	; message 46, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Nommez-le d'abord par example avec EDIT."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_047_EN:
	; message 47, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "The DIR number is out of range."
HDAE5000_LangMsg_047_DE:
	; message 47, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Sie haben eine ungueltige Verzeichnis Nummer eingegeben."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_047_FR:
	; message 47, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Le r"
	.byte 0xe9  ; "é"
	.asciz "pertoire choisi n'existe pas."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_048_EN:
	; message 48, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "The file number is out of range."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_048_DE:
	; message 48, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Die eingegebene Nummer existiert nicht."
HDAE5000_LangMsg_048_FR:
	; message 48, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Le titre choisi n'existe pas."
HDAE5000_LangMsg_049_EN:
	; message 49, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Please wait ..."
HDAE5000_LangMsg_049_DE:
	; message 49, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Bitte warten ..."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_049_FR:
	; message 49, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Attendre S.V.P."
HDAE5000_LangMsg_050_EN:
	; message 50, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "!FORMAT ERROR!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_050_DE:
	; message 50, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "!FORMAT FEHLER!"
HDAE5000_LangMsg_050_FR:
	; message 50, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "!FORMAT ERREUR!"
HDAE5000_LangMsg_051_EN:
	; message 51, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "The automatic HD format was not successful!"
HDAE5000_LangMsg_051_DE:
	; message 51, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Die Formatierung war nicht erfolgreich!"
HDAE5000_LangMsg_051_FR:
	; message 51, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Le formatage du disque dur n'a pas pu se faire correctement!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_052_EN:
	; message 52, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Please try once more, refer your owners manual or ask your dealer/service center."
HDAE5000_LangMsg_052_DE:
	; message 52, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Versuchen Sie es nochmals, schauen Sie in der Anleitung nach oder rufen Sie Ihre Service-Stelle an."
HDAE5000_LangMsg_052_FR:
	; message 52, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "R"
	.byte 0xe9  ; "é"
	.ascii "p"
	.byte 0xe9  ; "é"
	.ascii "tez l'operation en vous r"
	.byte 0xe9  ; "é"
	.ascii "f"
	.byte 0xe9  ; "é"
	.ascii "rent au manuel ou en cas d'"
	.byte 0xe9  ; "é"
	.asciz "chec, contactez votre service assistance."
HDAE5000_LangMsg_053_EN:
	; message 53, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Input error!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_053_DE:
	; message 53, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Eingabe-Fehler!"
HDAE5000_LangMsg_053_FR:
	; message 53, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Erreur d'operation!"
HDAE5000_LangMsg_054_EN:
	; message 54, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "The key code input was wrong!"
HDAE5000_LangMsg_054_DE:
	; message 54, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Die Nummerneingabe war falsch!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_054_FR:
	; message 54, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Le cocde n'est pas correct!"
HDAE5000_LangMsg_055_EN:
	; message 55, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Please try once more, refer your owners manual or ask your dealer/service center."
HDAE5000_LangMsg_055_DE:
	; message 55, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Versuchen Sie es nochmals, schauen Sie in der Anleitung nach oder rufen Sie Ihre Service-Stelle an."
HDAE5000_LangMsg_055_FR:
	; message 55, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Veuillez r"
	.byte 0xe9  ; "é"
	.ascii "p"
	.byte 0xe9  ; "é"
	.ascii "ter l'ex"
	.byte 0xe9  ; "é"
	.ascii "cution et vous r"
	.byte 0xe9  ; "é"
	.ascii "f"
	.byte 0xe9  ; "é"
	.asciz "rez au manuel ou contactez votre service assistance."
HDAE5000_LangMsg_056_EN:
	; message 56, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Delete file from hard disk:"
HDAE5000_LangMsg_056_DE:
	; message 56, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Loesche Titel von Festplatte:"
HDAE5000_LangMsg_056_FR:
	; message 56, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Effacer titre du disque dur:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_057_EN:
	; message 57, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "The hard disk will now be formatted. This procedure can take about 2-3 minutes."
HDAE5000_LangMsg_057_DE:
	; message 57, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Die Festplatte wird nun neu formatiert. Dieser Vorgang dauert ca. 2-3 Minuten."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_057_FR:
	; message 57, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "The hard disk will now be formatted. This procedure can take about 2-3 minutes."
HDAE5000_LangMsg_058_EN:
	; message 58, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "We recommend to turn ON and OFF again the power after the complete format."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_058_DE:
	; message 58, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Wir empfehlen, nach der Formatierung das Keyboard aus und wieder einzuschalten."
HDAE5000_LangMsg_058_FR:
	; message 58, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "We recommend to turn ON and OFF again the power after the complete format."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_059_EN:
	; message 59, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Track O will be recovered:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_059_DE:
	; message 59, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Track 0 wird kontrolliert:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_059_FR:
	; message 59, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Track O will be recovered:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_060_EN:
	; message 60, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "The FLS entry remains free."
HDAE5000_LangMsg_060_DE:
	; message 60, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Der FLS Eintrag bleibt frei."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_060_FR:
	; message 60, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Ce FLS registartion reste libre."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_061_EN:
	; message 61, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "All following entries will be moved."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_061_DE:
	; message 61, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Alle nachfolgenden Eintraege werden nachgeschoben."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_061_FR:
	; message 61, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Tous les registartion suivant seront d"
	.byte 0xe9  ; "é"
	.asciz "placer."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_062_EN:
	; message 62, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Evaluation 01-01-99"
HDAE5000_LangMsg_062_DE:
	; message 62, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Test-Version 01-01-99"
HDAE5000_LangMsg_062_FR:
	; message 62, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.ascii "Version d'"
	.byte 0xe9  ; "é"
	.asciz "valuation"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_064_EN:
	; message 64, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "LYRICS LOAD MODE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_064_DE:
	; message 64, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "LYRICS LOAD MODE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_064_FR:
	; message 64, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "LYRICS LOAD MODE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_065_EN:
	; message 65, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "COLOR ACTIV"
HDAE5000_LangMsg_065_DE:
	; message 65, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "AKTIVE FARBE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_065_FR:
	; message 65, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "COLOUR ACTIVE"
HDAE5000_LangMsg_066_EN:
	; message 66, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "COLOR PASSIV"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_066_DE:
	; message 66, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "PASSIVE FARBE"
HDAE5000_LangMsg_066_FR:
	; message 66, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "COLOUR PASSIVE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_067_EN:
	; message 67, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "You are going to overwrite an existing entry. Are you sure?"
HDAE5000_LangMsg_067_DE:
	; message 67, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Sie ueberschreiben einen bestehenden Eintrag. Sind Sie sicher?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_067_FR:
	; message 67, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Vous etes en train de modifier un titre existant. Etes-vous sur?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_200_EN:
	; message 200, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "YES"
HDAE5000_LangMsg_200_DE:
	; message 200, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "JA"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_200_FR:
	; message 200, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "OUI"
HDAE5000_LangMsg_201_EN:
	; message 201, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "NO"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_201_DE:
	; message 201, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "NEIN"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_201_FR:
	; message 201, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "NON"
HDAE5000_LangMsg_202_EN:
	; message 202, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "OK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_202_DE:
	; message 202, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "OK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_202_FR:
	; message 202, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "OK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_203_EN:
	; message 203, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "CANCEL"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_203_DE:
	; message 203, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Abbruch"
HDAE5000_LangMsg_203_FR:
	; message 203, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "CANCEL"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_206_EN:
	; message 206, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Operation error!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_206_DE:
	; message 206, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Bedienungsfehler!"
HDAE5000_LangMsg_206_FR:
	; message 206, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Error d'operation!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_207_EN:
	; message 207, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "!SAVE ERROR!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_207_DE:
	; message 207, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "!SAVE-FEHLER!"
HDAE5000_LangMsg_207_FR:
	; message 207, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "!SAVE ERREUR!"
HDAE5000_LangMsg_208_EN:
	; message 208, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "!LOAD ERROR!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_208_DE:
	; message 208, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "!LOAD-FEHLER!"
HDAE5000_LangMsg_208_FR:
	; message 208, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "!LOAD ERREUR!"
HDAE5000_LangMsg_209_EN:
	; message 209, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "!SYSTEM ERROR!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_209_DE:
	; message 209, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "!SYSTEM-FEHLER!"
HDAE5000_LangMsg_209_FR:
	; message 209, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "!SYSTEM ERREUR!"
HDAE5000_LangMsg_210_EN:
	; message 210, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "!ATTENTION!"
HDAE5000_LangMsg_210_DE:
	; message 210, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "!ACHTUNG!"
HDAE5000_LangMsg_210_FR:
	; message 210, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "!ATTENTION!"
HDAE5000_LangMsg_211_EN:
	; message 211, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Press YES for confirmation, NO to abort."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_211_DE:
	; message 211, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Bestaetigen Sie den Vorgang mit JA oder druecken Sie die NEIN Taste."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_211_FR:
	; message 211, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Pressez OUI pour confirmer ou NON pour annuler."
HDAE5000_LangMsg_212_EN:
	; message 212, language 1 (English): read by HDAE5000_AcLanguageText1Proc
	.asciz "Please call your dealer or service center."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_LangMsg_212_DE:
	; message 212, language 2 (German): read by HDAE5000_AcLanguageText1Proc
	.asciz "Bitte rufen Sie Ihre Service-Stelle an."
HDAE5000_LangMsg_212_FR:
	; message 212, language 3 (French): read by HDAE5000_AcLanguageText1Proc
	.asciz "Contactez votre service assistance."
HDAE5000_LangMsg_NoMessage:
	; the default text, all three languages: read by HDAE5000_AcLanguageText1Proc
	.asciz "No Message"
	.balign 2, 0x00					; pad after "No Message"
;
; HDAE5000_LangText_CaseTable (0x2E5AE0, 80 x u16): the message switch of
; HDAE5000_AcLanguageText1Proc.  Entry i serves message i+1 (i <= 0x42) or
; i+0x85 (i >= 0x43, the `sub wa,0x84` range); each value is an offset
; from HDAE5000_AcLanguageText1Proc_Msg001, the first case, and the reader
; jumps there (`jp T,XIX+WA`).  Three entries (messages 63, 204, 205) and
; every out-of-range number share the _NoMessage case.  Evidence and the
; extraction: scripts/converters/hdae5000_label_langtext.py.
;
HDAE5000_LangText_CaseTable:
	.short	HDAE5000_AcLanguageText1Proc_Msg001 - HDAE5000_AcLanguageText1Proc_Msg001	; message 1
	.short	HDAE5000_AcLanguageText1Proc_Msg002 - HDAE5000_AcLanguageText1Proc_Msg001	; message 2
	.short	HDAE5000_AcLanguageText1Proc_Msg003 - HDAE5000_AcLanguageText1Proc_Msg001	; message 3
	.short	HDAE5000_AcLanguageText1Proc_Msg004 - HDAE5000_AcLanguageText1Proc_Msg001	; message 4
	.short	HDAE5000_AcLanguageText1Proc_Msg005 - HDAE5000_AcLanguageText1Proc_Msg001	; message 5
	.short	HDAE5000_AcLanguageText1Proc_Msg006 - HDAE5000_AcLanguageText1Proc_Msg001	; message 6
	.short	HDAE5000_AcLanguageText1Proc_Msg007 - HDAE5000_AcLanguageText1Proc_Msg001	; message 7
	.short	HDAE5000_AcLanguageText1Proc_Msg008 - HDAE5000_AcLanguageText1Proc_Msg001	; message 8
	.short	HDAE5000_AcLanguageText1Proc_Msg009 - HDAE5000_AcLanguageText1Proc_Msg001	; message 9
	.short	HDAE5000_AcLanguageText1Proc_Msg010 - HDAE5000_AcLanguageText1Proc_Msg001	; message 10
	.short	HDAE5000_AcLanguageText1Proc_Msg011 - HDAE5000_AcLanguageText1Proc_Msg001	; message 11
	.short	HDAE5000_AcLanguageText1Proc_Msg012 - HDAE5000_AcLanguageText1Proc_Msg001	; message 12
	.short	HDAE5000_AcLanguageText1Proc_Msg013 - HDAE5000_AcLanguageText1Proc_Msg001	; message 13
	.short	HDAE5000_AcLanguageText1Proc_Msg014 - HDAE5000_AcLanguageText1Proc_Msg001	; message 14
	.short	HDAE5000_AcLanguageText1Proc_Msg015 - HDAE5000_AcLanguageText1Proc_Msg001	; message 15
	.short	HDAE5000_AcLanguageText1Proc_Msg016 - HDAE5000_AcLanguageText1Proc_Msg001	; message 16
	.short	HDAE5000_AcLanguageText1Proc_Msg017 - HDAE5000_AcLanguageText1Proc_Msg001	; message 17
	.short	HDAE5000_AcLanguageText1Proc_Msg018 - HDAE5000_AcLanguageText1Proc_Msg001	; message 18
	.short	HDAE5000_AcLanguageText1Proc_Msg019 - HDAE5000_AcLanguageText1Proc_Msg001	; message 19
	.short	HDAE5000_AcLanguageText1Proc_Msg020 - HDAE5000_AcLanguageText1Proc_Msg001	; message 20
	.short	HDAE5000_AcLanguageText1Proc_Msg021 - HDAE5000_AcLanguageText1Proc_Msg001	; message 21
	.short	HDAE5000_AcLanguageText1Proc_Msg022 - HDAE5000_AcLanguageText1Proc_Msg001	; message 22
	.short	HDAE5000_AcLanguageText1Proc_Msg023 - HDAE5000_AcLanguageText1Proc_Msg001	; message 23
	.short	HDAE5000_AcLanguageText1Proc_Msg024 - HDAE5000_AcLanguageText1Proc_Msg001	; message 24
	.short	HDAE5000_AcLanguageText1Proc_Msg025 - HDAE5000_AcLanguageText1Proc_Msg001	; message 25
	.short	HDAE5000_AcLanguageText1Proc_Msg026 - HDAE5000_AcLanguageText1Proc_Msg001	; message 26
	.short	HDAE5000_AcLanguageText1Proc_Msg027 - HDAE5000_AcLanguageText1Proc_Msg001	; message 27
	.short	HDAE5000_AcLanguageText1Proc_Msg028 - HDAE5000_AcLanguageText1Proc_Msg001	; message 28
	.short	HDAE5000_AcLanguageText1Proc_Msg029 - HDAE5000_AcLanguageText1Proc_Msg001	; message 29
	.short	HDAE5000_AcLanguageText1Proc_Msg030 - HDAE5000_AcLanguageText1Proc_Msg001	; message 30
	.short	HDAE5000_AcLanguageText1Proc_Msg031 - HDAE5000_AcLanguageText1Proc_Msg001	; message 31
	.short	HDAE5000_AcLanguageText1Proc_Msg032 - HDAE5000_AcLanguageText1Proc_Msg001	; message 32
	.short	HDAE5000_AcLanguageText1Proc_Msg033 - HDAE5000_AcLanguageText1Proc_Msg001	; message 33
	.short	HDAE5000_AcLanguageText1Proc_Msg034 - HDAE5000_AcLanguageText1Proc_Msg001	; message 34
	.short	HDAE5000_AcLanguageText1Proc_Msg035 - HDAE5000_AcLanguageText1Proc_Msg001	; message 35
	.short	HDAE5000_AcLanguageText1Proc_Msg036 - HDAE5000_AcLanguageText1Proc_Msg001	; message 36
	.short	HDAE5000_AcLanguageText1Proc_Msg037 - HDAE5000_AcLanguageText1Proc_Msg001	; message 37
	.short	HDAE5000_AcLanguageText1Proc_Msg038 - HDAE5000_AcLanguageText1Proc_Msg001	; message 38
	.short	HDAE5000_AcLanguageText1Proc_Msg039 - HDAE5000_AcLanguageText1Proc_Msg001	; message 39
	.short	HDAE5000_AcLanguageText1Proc_Msg040 - HDAE5000_AcLanguageText1Proc_Msg001	; message 40
	.short	HDAE5000_AcLanguageText1Proc_Msg041 - HDAE5000_AcLanguageText1Proc_Msg001	; message 41
	.short	HDAE5000_AcLanguageText1Proc_Msg042 - HDAE5000_AcLanguageText1Proc_Msg001	; message 42
	.short	HDAE5000_AcLanguageText1Proc_Msg043 - HDAE5000_AcLanguageText1Proc_Msg001	; message 43
	.short	HDAE5000_AcLanguageText1Proc_Msg044 - HDAE5000_AcLanguageText1Proc_Msg001	; message 44
	.short	HDAE5000_AcLanguageText1Proc_Msg045 - HDAE5000_AcLanguageText1Proc_Msg001	; message 45
	.short	HDAE5000_AcLanguageText1Proc_Msg046 - HDAE5000_AcLanguageText1Proc_Msg001	; message 46
	.short	HDAE5000_AcLanguageText1Proc_Msg047 - HDAE5000_AcLanguageText1Proc_Msg001	; message 47
	.short	HDAE5000_AcLanguageText1Proc_Msg048 - HDAE5000_AcLanguageText1Proc_Msg001	; message 48
	.short	HDAE5000_AcLanguageText1Proc_Msg049 - HDAE5000_AcLanguageText1Proc_Msg001	; message 49
	.short	HDAE5000_AcLanguageText1Proc_Msg050 - HDAE5000_AcLanguageText1Proc_Msg001	; message 50
	.short	HDAE5000_AcLanguageText1Proc_Msg051 - HDAE5000_AcLanguageText1Proc_Msg001	; message 51
	.short	HDAE5000_AcLanguageText1Proc_Msg052 - HDAE5000_AcLanguageText1Proc_Msg001	; message 52
	.short	HDAE5000_AcLanguageText1Proc_Msg053 - HDAE5000_AcLanguageText1Proc_Msg001	; message 53
	.short	HDAE5000_AcLanguageText1Proc_Msg054 - HDAE5000_AcLanguageText1Proc_Msg001	; message 54
	.short	HDAE5000_AcLanguageText1Proc_Msg055 - HDAE5000_AcLanguageText1Proc_Msg001	; message 55
	.short	HDAE5000_AcLanguageText1Proc_Msg056 - HDAE5000_AcLanguageText1Proc_Msg001	; message 56
	.short	HDAE5000_AcLanguageText1Proc_Msg057 - HDAE5000_AcLanguageText1Proc_Msg001	; message 57
	.short	HDAE5000_AcLanguageText1Proc_Msg058 - HDAE5000_AcLanguageText1Proc_Msg001	; message 58
	.short	HDAE5000_AcLanguageText1Proc_Msg059 - HDAE5000_AcLanguageText1Proc_Msg001	; message 59
	.short	HDAE5000_AcLanguageText1Proc_Msg060 - HDAE5000_AcLanguageText1Proc_Msg001	; message 60
	.short	HDAE5000_AcLanguageText1Proc_Msg061 - HDAE5000_AcLanguageText1Proc_Msg001	; message 61
	.short	HDAE5000_AcLanguageText1Proc_Msg062 - HDAE5000_AcLanguageText1Proc_Msg001	; message 62
	.short	HDAE5000_AcLanguageText1Proc_NoMessage - HDAE5000_AcLanguageText1Proc_Msg001	; message 63
	.short	HDAE5000_AcLanguageText1Proc_Msg064 - HDAE5000_AcLanguageText1Proc_Msg001	; message 64
	.short	HDAE5000_AcLanguageText1Proc_Msg065 - HDAE5000_AcLanguageText1Proc_Msg001	; message 65
	.short	HDAE5000_AcLanguageText1Proc_Msg066 - HDAE5000_AcLanguageText1Proc_Msg001	; message 66
	.short	HDAE5000_AcLanguageText1Proc_Msg067 - HDAE5000_AcLanguageText1Proc_Msg001	; message 67
	.short	HDAE5000_AcLanguageText1Proc_Msg200 - HDAE5000_AcLanguageText1Proc_Msg001	; message 200
	.short	HDAE5000_AcLanguageText1Proc_Msg201 - HDAE5000_AcLanguageText1Proc_Msg001	; message 201
	.short	HDAE5000_AcLanguageText1Proc_Msg202 - HDAE5000_AcLanguageText1Proc_Msg001	; message 202
	.short	HDAE5000_AcLanguageText1Proc_Msg203 - HDAE5000_AcLanguageText1Proc_Msg001	; message 203
	.short	HDAE5000_AcLanguageText1Proc_NoMessage - HDAE5000_AcLanguageText1Proc_Msg001	; message 204
	.short	HDAE5000_AcLanguageText1Proc_NoMessage - HDAE5000_AcLanguageText1Proc_Msg001	; message 205
	.short	HDAE5000_AcLanguageText1Proc_Msg206 - HDAE5000_AcLanguageText1Proc_Msg001	; message 206
	.short	HDAE5000_AcLanguageText1Proc_Msg207 - HDAE5000_AcLanguageText1Proc_Msg001	; message 207
	.short	HDAE5000_AcLanguageText1Proc_Msg208 - HDAE5000_AcLanguageText1Proc_Msg001	; message 208
	.short	HDAE5000_AcLanguageText1Proc_Msg209 - HDAE5000_AcLanguageText1Proc_Msg001	; message 209
	.short	HDAE5000_AcLanguageText1Proc_Msg210 - HDAE5000_AcLanguageText1Proc_Msg001	; message 210
	.short	HDAE5000_AcLanguageText1Proc_Msg211 - HDAE5000_AcLanguageText1Proc_Msg001	; message 211
	.short	HDAE5000_AcLanguageText1Proc_Msg212 - HDAE5000_AcLanguageText1Proc_Msg001	; message 212

; ============================================================================
; LYRICS MODULE .RODATA, 0x2E5B80-0x2E5DCD: the read-only data of the code
; around HDAE5000_LyricBoxProc and HDAE5000_FDFileSelectProc (lyric files
; "TLhd"/"TLtr", ".TLX"/".TTX"/".MID", the lyric messages), laid out
; after the trilingual message block.  Rebuilt object by object by
; scripts/generators/gen_hdae5000_rodata.py --block2, as the main .rodata
; block above: every object starts where the code names it, and its note
; names the readers; the switch tables keep their own headers.
; ============================================================================
HDAE5000_Str_Blank40:	; 0x2E5B80
	; read by LyricBoxProc at 0x28D0A5 (lda operand)
	.asciz "                                        "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Reset:	; 0x2E5BAA
	; read by LyricBoxProc at 0x28D261 (lda operand)
	.asciz "Reset"
HDAE5000_Str_Load:	; 0x2E5BB0
	; read by LyricBoxProc at 0x28D283 (lda operand)
	.asciz "Load"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_03i_i:	; 0x2E5BB6
	; read by LyricBoxProc at 0x28D4B7 (pushed operand)
	.asciz "%03i - %i "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_LyricBoxProc_CaseTable2 (0x2E5BC2, 8 x u16): the switch of HDAE5000_LyricBoxProc
; (dispatch at 0x28D57C, hdae5000_ui_display.s:3786: bound `cp xwa,7`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_LyricBoxProc_Case0_2)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_LyricBoxProc_Case0_2 of the case for value 0+i; 8 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_LyricBoxProc_CaseTable2:
	.short	HDAE5000_LyricBoxProc_Case0_2 - HDAE5000_LyricBoxProc_Case0_2	; 0
	.short	HDAE5000_LyricBoxProc_Default2 - HDAE5000_LyricBoxProc_Case0_2	; 1 (default)
	.short	HDAE5000_LyricBoxProc_Default2 - HDAE5000_LyricBoxProc_Case0_2	; 2 (default)
	.short	HDAE5000_LyricBoxProc_Default2 - HDAE5000_LyricBoxProc_Case0_2	; 3 (default)
	.short	HDAE5000_LyricBoxProc_Default2 - HDAE5000_LyricBoxProc_Case0_2	; 4 (default)
	.short	HDAE5000_LyricBoxProc_Default2 - HDAE5000_LyricBoxProc_Case0_2	; 5 (default)
	.short	HDAE5000_LyricBoxProc_Default2 - HDAE5000_LyricBoxProc_Case0_2	; 6 (default)
	.short	HDAE5000_LyricBoxProc_Case7_2 - HDAE5000_LyricBoxProc_Case0_2	; 7
;
; HDAE5000_LyricBoxProc_CaseTable1 (0x2E5BD2, 7 x u16): the switch of HDAE5000_LyricBoxProc
; (dispatch at 0x28CD6A, hdae5000_ui_display.s:3194: `sub xwa,0x01ca0003`, bound `cp xwa,6`, `add xwa,xwa`, `ld wa,(<table>+2i)`,
; `lda xix,(HDAE5000_LyricBoxProc_Ev01C0000D)`, `jp T,XIX+WA`).  Entry i is the offset from
; HDAE5000_LyricBoxProc_Ev01C0000D of the case for event 0x01CA0003+i; 7 entries, pinned by the bound
; compare.  Asserted and written by scripts/converters/hdae5000_switch_tables.py.
;
HDAE5000_LyricBoxProc_CaseTable1:
	.short	HDAE5000_LyricBoxProc_Ev01CA0003 - HDAE5000_LyricBoxProc_Ev01C0000D	; 0x01CA0003
	.short	HDAE5000_LyricBoxProc_Ev01CA0004 - HDAE5000_LyricBoxProc_Ev01C0000D	; 0x01CA0004
	.short	HDAE5000_LyricBoxProc_Ev01CA0005 - HDAE5000_LyricBoxProc_Ev01C0000D	; 0x01CA0005
	.short	HDAE5000_LyricBoxProc_Default1 - HDAE5000_LyricBoxProc_Ev01C0000D	; 0x01CA0006 (default)
	.short	HDAE5000_LyricBoxProc_Ev01CA0007 - HDAE5000_LyricBoxProc_Ev01C0000D	; 0x01CA0007
	.short	HDAE5000_LyricBoxProc_Ev01CA0008 - HDAE5000_LyricBoxProc_Ev01C0000D	; 0x01CA0008
	.short	HDAE5000_LyricBoxProc_Ev01CA0009 - HDAE5000_LyricBoxProc_Ev01C0000D	; 0x01CA0009
HDAE5000_Str_Rb:	; 0x2E5BE0
	; read by Display_Error at 0x28D67B (lda operand)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_TESTTESTTLX:	; 0x2E5BE4
	; read by Display_Error at 0x28D676 (lda operand)
	.asciz "TESTTEST.TLX"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fmt_Fault_No_Lyrics_loaded_o:	; 0x2E5BF2
	; read by File_Operation at 0x28D78B (pushed operand)
	.asciz "Fault : No Lyrics loaded or corrupt Data - Code %i %i %i     "
HDAE5000_Fmt_i_i:	; 0x2E5C30
	; read by File_Operation at 0x28D9F3 (pushed operand)
	.asciz " %i/%i "
HDAE5000_Fmt_Chord_s:	; 0x2E5C38
	; read by File_Operation at 0x28DA35 (pushed operand)
	.asciz "Chord : %s               "
HDAE5000_Str_Info:	; 0x2E5C52
	; read by File_Save at 0x28DB2F (pushed operand)
	.asciz "Info :                            "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_NoCopyrightInfo:	; 0x2E5C76
	; read by File_Load at 0x28DC63 (pushed operand)
	.asciz "No Copyright Info"
HDAE5000_Str_NoSongTitle:	; 0x2E5C88
	; read by File_Load at 0x28DCDD (pushed operand)
	.asciz "No Song Title"
HDAE5000_Fmt_i_i_File_Load:	; 0x2E5C96
	; read by File_Load at 0x28DDB7 (pushed operand)
	.asciz " %i/%i "
HDAE5000_Str_Empty_File_Delete:	; 0x2E5C9E
	; read by File_Delete at 0x28DF7B (pushed operand)
	.zero 2
HDAE5000_Str_Empty_File_Delete_2:	; 0x2E5CA0
	; read by File_Delete at 0x28DFF0 (pushed operand)
	.zero 2
HDAE5000_Str_Tlhd:	; 0x2E5CA2
	; read by Display_Notify at 0x28E540 (lda operand)
	.asciz "TLhd"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Tltr:	; 0x2E5CA8
	; read by Display_Progress at 0x28E5B1 (lda operand)
	.asciz "TLtr"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Empty_FDFileSelectProc:	; 0x2E5CAE
	; read by FDFileSelectProc at 0x28E78D (pushed operand)
	.zero 2
HDAE5000_Str_Blank27:	; 0x2E5CB0
	; read by FDFileSelectProc at 0x28E85E (lda operand)
	.asciz "                           "
HDAE5000_Str_Blank27_FDFileSelectProc:	; 0x2E5CCC
	; read by FDFileSelectProc at 0x28E917 (lda operand)
	.asciz "                           "
HDAE5000_Str_Mid:	; 0x2E5CE8
	; read by FDFileSelectProc at 0x28E9EA (lda operand)
	.asciz "mid"
HDAE5000_Str_Blank3:	; 0x2E5CEC
	; read by FDFileSelectProc at 0x28EA19 (lda operand)
	.asciz "   "
HDAE5000_Str_Blank49:	; 0x2E5CF0
	; read by FDFileSelectProc at 0x28EB62 (lda operand)
	.asciz "                                                 "
HDAE5000_Fmt_s_s:	; 0x2E5D22
	; read by FDFileSelectProc at 0x28EBC8 (pushed operand)
	.asciz "%s %s"
HDAE5000_Fmt_s_s_FDFileSelectProc:	; 0x2E5D28
	; read by FDFileSelectProc at 0x28EBF7 (pushed operand)
	.asciz "%s %s"
HDAE5000_Str_TLX_FDFileSelectProc:	; 0x2E5D2E
	; read by FDFileSelectProc at 0x28EEE1 (pushed operand)
	.asciz ".TLX"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Rb_FDFileSelectProc:	; 0x2E5D34
	; read by FDFileSelectProc at 0x28EEF2 (lda operand)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
;
; HDAE5000_FDFileSelectProc_KeyCaseMap (0x2E5D38, 16 bytes) and
; HDAE5000_FDFileSelectProc_KeyCaseTable (0x2E5D48, 4 x u16): the two-level
; switch of HDAE5000_FDFileSelectProc's event 0x01C00007 (dispatch at
; 0x28ED74): a key code k = 0..7, or 0x80..0x87 folded to 8..15 by `sub
; xwa,0x78`, indexes the byte map (`add xwa,<map>`, `ld wa,(xwa)`, `extz wa`);
; that case number, doubled, indexes the u16 table (`ld xix,<table>`, `ld
; WA,(XIX+WA)`), whose entries are offsets from .Lsc_07_btn_down (`lda
; xix,(.Lsc_07_btn_down)`, `jp T,XIX+WA`).  Case 0 (k 0,1,8,9) returns 0,
; case 1 (k 10..13) = .Lsc_07_btn_up, case 2 (k 6,7,14,15) =
; .Lsc_07_btn_enter, case 3 (k 2..5) = .Lsc_07_btn_down.  16 map bytes and 4
; entries, pinned by the range checks and the largest map value.
;
HDAE5000_FDFileSelectProc_KeyCaseMap:
	.byte 0, 0, 3, 3, 3, 3, 2, 2		; key codes 0..7
	.byte 0, 0, 1, 1, 1, 1, 2, 2		; key codes 0x80..0x87
HDAE5000_FDFileSelectProc_KeyCaseTable:
	.short	.Lsc_ret0 - .Lsc_07_btn_down	; case 0
	.short	.Lsc_07_btn_up - .Lsc_07_btn_down	; case 1
	.short	.Lsc_07_btn_enter - .Lsc_07_btn_down	; case 2
	.short	.Lsc_07_btn_down - .Lsc_07_btn_down	; case 3
HDAE5000_Str_Chr202D3E:	; 0x2E5D50
	; read by FdLyricList_Scan at 0x28EFF1 (pushed operand)
	.asciz " ->"
HDAE5000_Str_Chr2A2E2A:	; 0x2E5D54
	; read by FdLyricList_Scan at 0x28F000 (lda operand)
	.asciz "*.*"
HDAE5000_Str_TTX:	; 0x2E5D58
	; read by FdLyricList_Scan at 0x28F08E (pushed operand)
	.asciz ".TTX"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Rb_FdLyricTtx:	; 0x2E5D5E
	; read by FdLyricList_Scan at 0x28F0A3 (lda operand)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_MID:	; 0x2E5D62
	; read by FdLyricList_Scan at 0x28F114 (pushed operand)
	.asciz ".MID"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_Rb_FdLyricMid:	; 0x2E5D68
	; read by FdLyricList_Scan at 0x28F129 (lda operand)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Str_XLT:	; 0x2E5D6C
	; read by FdLyricList_AddTlx at 0x28F1BA (pushed operand)
	.asciz "XLT."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_TextPtrs_LANENG001_to_LANENG006:	; 0x2E5D72, 6 x .long -> string
	; read by LanguageTextReturn at 0x28F2FF (lda operand); 6 string pointers, 4 bytes each, entry i at +4*i
	.long	HDAE5000_Str_LANENG001
	.long	HDAE5000_Str_LANDEU002
	.long	HDAE5000_Str_LANFRA003
	.long	HDAE5000_Str_LANENG004
	.long	HDAE5000_Str_LANENG005
	.long	HDAE5000_Str_LANENG006
HDAE5000_Str_LANENG006:	; 0x2E5D8A
	; pointed at by entry 5 of HDAE5000_TextPtrs_LANENG001_to_LANENG006, a table read by LanguageTextReturn
	.asciz "LANENG006"
HDAE5000_Str_LANENG005:	; 0x2E5D94
	; pointed at by entry 4 of HDAE5000_TextPtrs_LANENG001_to_LANENG006, a table read by LanguageTextReturn
	.asciz "LANENG005"
HDAE5000_Str_LANENG004:	; 0x2E5D9E
	; pointed at by entry 3 of HDAE5000_TextPtrs_LANENG001_to_LANENG006, a table read by LanguageTextReturn
	.asciz "LANENG004"
HDAE5000_Str_LANFRA003:	; 0x2E5DA8
	; pointed at by entry 2 of HDAE5000_TextPtrs_LANENG001_to_LANENG006, a table read by LanguageTextReturn
	.asciz "LANFRA003"
HDAE5000_Str_LANDEU002:	; 0x2E5DB2
	; pointed at by entry 1 of HDAE5000_TextPtrs_LANENG001_to_LANENG006, a table read by LanguageTextReturn
	.asciz "LANDEU002"
HDAE5000_Str_LANENG001:	; 0x2E5DBC
	; pointed at by entry 0 of HDAE5000_TextPtrs_LANENG001_to_LANENG006, a table read by LanguageTextReturn
	.asciz "LANENG001"
HDAE5000_Str_XAP:	; 0x2E5DC6
	; read by PPORT_Svc28_FlashXapFile at 0x28F314 (pushed operand)
	.asciz "XAP"
HDAE5000_Str_Rb_Extension_Check:	; 0x2E5DCA
	; read by Extension_Check at 0x28F474 (lda operand)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)

HDAE5000_Palette_Data:	; 0x2E5DCE
	; Boot-splash palette: 0x400 B = 256 RGBX entries (202 distinct colours).
	; Loaded by HDAE5000_Boot_Init, which does `lda XWA,0x2E5DCE` at 0x28F586
	; and calls HDAE5000_Load_Palette.  The name is kept as-is because it is
	; the only one of the five palettes referenced by name from the ASL
	; mirror (archive/asl/hdae5000/hd-ae5000_v2_06i.asm) and from
	; hdae5000_ui_display.s.  Extracted as images/HDAE5000_Palette_0x65dce.bin.
	;
	; The old slice here claimed "VGA palette data (256 entries)" but ran for
	; 0x13000 bytes -- 0x400 of palette followed by a whole 320 x 240 bitmap
	; that had never been identified.  They are now separated.
	; Built from images/HDAE5000_Palette_Splash.txt by scripts/build/hdae5000_images.py.
	; Was: .incbin "includes/code_29af2d_2fffff.bin", 306849, 1024
	.incbin "includes/generated/HDAE5000_Palette_Splash.bin"

HDAE5000_Bitmap_BootSplash:	; 0x2E61CE
	; 320 x 240 @ 8bpp = 0x12C00 B -- the HD-AE5000 start-up screen: a red
	; "HD-AE5000" wordmark over a photograph of an open disk platter, with
	; "Version 2" beneath it and "Start-up !  Please wait . . ." below that.
	; Rendered with HDAE5000_Palette_Data (0x2E5DCE) it is unambiguous.
	;
	; HDAE5000_Boot_Init obtains this base from HDAE5000_Alloc_Memory
	; (request A1, the lda at 0x28F55F, with A2 = 0x140 and A3 = 0xF0) and
	; copies it into VRAM as two 0x9600-byte halves, to 0x1A0000 and
	; 0x1A9600.  0x2E61CE + 0x12C00 = 0x2F8DCE = HDAE5000_Display_Params,
	; so the bitmap tiles the gap exactly.
	; Not yet extracted to hdae5000/images/ -- see the hdae-splash package.
	; Built from images/HDAE5000_SplashScreen.png by scripts/build/hdae5000_images.py.
	; Was: .incbin "includes/code_29af2d_2fffff.bin", 307873, 76800
	.incbin "includes/generated/HDAE5000_SplashScreen.bin"

HDAE5000_Display_Params:	; 0x2F8DCE
	; Display configuration parameters
	.asciz "HD-AE5000"
	.zero 8
HDAE5000_Dir_IsBlankName_Str_Blank16:	.asciz "                "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_Fls_IsBlankName_Str_Blank16:	.asciz "                "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FlsItem_SongRecord_Str_Blank26:	.asciz "                          "
	.byte 0x00
	.byte 0x98, 0x8e
	.asciz "/"
	.byte 0x04
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x94, 0x8e
	.asciz "/"
	.zero 2
	.byte 0x02
	.byte 0x00
	.byte 0x90, 0x8e
	.asciz "/"
	.byte 0x05
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x8c, 0x8e
	.asciz "/"
	.zero 2
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "z"
	.byte 0x8e
	.asciz "/"
	.zero 2
	.byte 0x10
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "v"
	.byte 0x8e
	.asciz "/"
	.zero 2
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "r"
	.byte 0x8e
	.asciz "/"
	.zero 2
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "n"
	.byte 0x8e
	.asciz "/"
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "h"
	.byte 0x8e
	.asciz "/"
	.zero 2
	.byte 0x04
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "TLhd"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "HK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "H"
	.asciz "K"
	.asciz "H"
	.asciz "K"
	.asciz "KN5000 SOUND RAM"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "H"
	.asciz "K"
	.byte 0x01, 0x08
	.zero 2
	.asciz "HK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "HK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_SEQ:	.asciz ".SEQ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_SQF:	.asciz ".SQF"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_LSW:	.asciz ".LSW"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_rb:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_PMT:	.asciz ".PMT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_rb_2:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_SQT:	.asciz ".SQT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_rb_3:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_CMP:	.asciz ".CMP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_rb_4:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_TM:	.asciz ".TM"
HDAE5000_FdSong_CheckFiles_Str_rb_5:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_MSP:	.asciz ".MSP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_rb_6:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_RCM:	.asciz ".RCM"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_rb_7:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_MD:	.asciz ".MD"
HDAE5000_FdSong_CheckFiles_Str_rb_8:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_TLX:	.asciz ".TLX"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_FdSong_CheckFiles_Str_rb_9:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Str_TTX:	.asciz ".TTX"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Str_rb:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Lsw_Str_LSW:	.asciz ".LSW"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Lsw_Str_rb:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Pmt_Str_PMT:	.asciz ".PMT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Pmt_Str_rb:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Sqt_Str_SQT:	.asciz ".SQT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Sqt_Str_rb:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Cmp_Str_CMP:	.asciz ".CMP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Cmp_Str_rb:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Tm_Str_TM:	.asciz ".TM"
HDAE5000_CopyFdSongToHd_Tm_Str_rb:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Msp_Str_MSP:	.asciz ".MSP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Msp_Str_rb:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Rcm_Str_RCM:	.asciz ".RCM"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Rcm_Str_rb:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Md_Str_MD:	.asciz ".MD"
HDAE5000_CopyFdSongToHd_Md_Str_rb:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Tlx_Str_TLX:	.asciz ".TLX"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_CopyFdSongToHd_Tlx_Str_rb:	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc01_GetInfoBlockPointer_Str_GetInfoBlockPointer:	.asciz "---[ GetInfoBlockPointer ]---"
HDAE5000_PPORT_Svc01_GetInfoBlockPointer_Str_ppib_adr_Fmtx:		.asciz "ppib adr = %lx"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc01_GetInfoBlockPointer_Str_Blank1:	.asciz " "
HDAE5000_PPORT_Svc02_TurnHdMotorOff_Str_TurnHdMotorOff:	.asciz "---[ TurnHdMotorOff ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc02_TurnHdMotorOff_Str_Blank1:			.asciz " "
HDAE5000_PPORT_Svc03_SendInfosAboutHd_Str_SendInfosAboutHd:	.asciz "---[ SendInfosAboutHd ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc03_SendInfosAboutHd_Str_hddname:	.asciz "hddname : "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc03_SendInfosAboutHd_Str_hddtrck_Fmtd:	.asciz "hddtrck : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc03_SendInfosAboutHd_Str_hddhead_Fmtd:	.asciz "hddhead : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc03_SendInfosAboutHd_Str_hddsctr_Fmtd:	.asciz "hddsctr : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc03_SendInfosAboutHd_Str_hddscby_Fmtd:	.asciz "hddscby : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc03_SendInfosAboutHd_Str_Blank1:			.asciz " "
HDAE5000_PPORT_Svc04_SendInfosAboutDirBlock_Str_SendInfosAboutDirBlock:	.asciz "---[ SendInfosAboutDirBlock ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc04_SendInfosAboutDirBlock_Str_FGB_ptr_Fmtx:	.asciz "FGB ptr : %lx"
HDAE5000_PPORT_Svc04_SendInfosAboutDirBlock_Str_FGB_wid_Fmtd:	.asciz "FGB wid : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc04_SendInfosAboutDirBlock_Str_FGB_num_Fmtd:	.asciz "FGB num : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc04_SendInfosAboutDirBlock_Str_Blank1:					.asciz " "
HDAE5000_PPORT_Svc05_SendInfosAboutFileSystemBlock_Str_SendInfosAboutFileSystemBlock:	.asciz "---[ SendInfosAboutFileSystemBlock ]---"
HDAE5000_PPORT_Svc05_SendInfosAboutFileSystemBlock_Str_FEB_ptr_Fmtx:			.asciz "FEB ptr : %lx"
HDAE5000_PPORT_Svc05_SendInfosAboutFileSystemBlock_Str_FEB_wid_Fmtd:			.asciz "FEB wid : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc05_SendInfosAboutFileSystemBlock_Str_FEB_num_Fmtd:	.asciz "FEB num : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc05_SendInfosAboutFileSystemBlock_Str_Blank1:		.asciz " "
HDAE5000_PPORT_Svc06_SendInfosAboutFlsBlock_Str_SendInfosAboutFlsBlock:	.asciz "---[ SendInfosAboutFlsBlock ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc06_SendInfosAboutFlsBlock_Str_FLS_ptr_Fmtx:	.asciz "FLS ptr : %lx"
HDAE5000_PPORT_Svc06_SendInfosAboutFlsBlock_Str_FLS_wid_Fmtd:	.asciz "FLS wid : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc06_SendInfosAboutFlsBlock_Str_FLS_num_Fmtd:	.asciz "FLS num : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc06_SendInfosAboutFlsBlock_Str_FLS_ent_Fmtd:	.asciz "FLS ent : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc06_SendInfosAboutFlsBlock_Str_Blank1:		.asciz " "
HDAE5000_PPORT_Svc07_ReadDirBlockFromHd_Str_ReadDirBlockFromHd:	.asciz "---[ ReadDirBlockFromHd ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc07_ReadDirBlockFromHd_Str_Blank1:			.asciz " "
HDAE5000_PPORT_Svc08_ReadFileBlockFromHd_Str_ReadFileBlockFromHd:	.asciz "---[ ReadFileBlockFromHd ]---"
HDAE5000_PPORT_Svc08_ReadFileBlockFromHd_Str_Blank1:			.asciz " "
HDAE5000_PPORT_Svc09_ReadFlsBlockFromHd_Str_ReadFlsBlockFromHd:		.asciz "---[ ReadFlsBlockFromHd ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc09_ReadFlsBlockFromHd_Str_Blank1:				.asciz " "
HDAE5000_PPORT_Svc10_WriteDirBlockToHd_Str_WriteDirBlockToHd:			.asciz "---[ WriteDirBlockToHd ]---"
HDAE5000_PPORT_Svc10_WriteDirBlockToHd_Str_Blank1:				.asciz " "
HDAE5000_PPORT_Svc11_WriteFileSystemBlockToHd_Str_WriteFileSystemBlockToHd:	.asciz "---[ WriteFileSystemBlockToHd ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc11_WriteFileSystemBlockToHd_Str_Blank1:	.asciz " "
HDAE5000_PPORT_Svc12_WriteFlsBlockToHd_Str_WriteFlsBlockToHd:	.asciz "---[ WriteFlsBlockToHd ]---"
HDAE5000_PPORT_Svc12_WriteFlsBlockToHd_Str_Blank1:		.asciz " "
HDAE5000_PPORT_Svc13_SendInfosAboutSong_Str_SendInfosAboutSong:	.asciz "---[ SendInfosAboutSong ]--- "
HDAE5000_PPORT_Svc13_SendInfosAboutSong_Str_dirname_Fmts:	.asciz "dirname : %s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc13_SendInfosAboutSong_Str_sngname_Fmts:	.asciz "sngname : %s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc13_SendInfosAboutSong_Str_Blank1:			.asciz " "
HDAE5000_PPORT_Svc14_LoadSongFromHdToMemory_Str_LoadSongFromHdToMemory:	.asciz "---[ LoadSongFromHdToMemory ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc14_LoadSongFromHdToMemory_Str_Blank1:			.asciz " "
HDAE5000_PPORT_Svc15_SaveSongInMemoryToHd_Str_SaveSongInMemoryToHd:	.asciz "---[ SaveSongInMemoryToHd ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc15_SaveSongInMemoryToHd_Str_Blank1:			.asciz " "
HDAE5000_PPORT_Svc16_InitWholeSongInMemory_Str_InitWholeSongInMemory:	.asciz "---[ InitWholeSongInMemory ]---"
HDAE5000_PPORT_Svc16_InitWholeSongInMemory_Str_Blank1:			.asciz " "
HDAE5000_PPORT_Svc17_FormatHd_Str_FormatHd:				.asciz "---[ FormatHd ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc17_FormatHd_Str_Blank1:						.asciz " "
HDAE5000_PPORT_Svc19_SendPointerToFreeBufferSpace_Str_SendPointerToFreeBufferSpace:	.asciz "---[ SendPointerToFreeBufferSpace ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc19_SendPointerToFreeBufferSpace_Str_work_adr_Fmtx:	.asciz "work adr : %lx"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc19_SendPointerToFreeBufferSpace_Str_Blank1:		.asciz " "
HDAE5000_PPORT_Svc20_PreWholeSongInMemory_Str_PreWholeSongInMemory:	.asciz "---[ PreWholeSongInMemory ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc20_PreWholeSongInMemory_Str_Blank1:	.asciz " "
HDAE5000_PPORT_Svc21_WriteOpenHD_Str_WriteOpenHD:	.asciz "---[ WriteOpenHD ]--- "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc21_WriteOpenHD_Str_SUFFIX_Fmtd:	.asciz "SUFFIX : %d"
HDAE5000_PPORT_Svc22_WriteCloseHD_Str_WriteCloseHD:	.asciz "---[ WriteCloseHD ]--- "
HDAE5000_PPORT_Svc23_WriteFileHD_Str_WriteFileHD:	.asciz "---[ WriteFileHD ]--- "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_PPORT_Svc24_ReadOpenHD_Str_ReadOpenHD:	.asciz "---[ ReadOpenHD ]--- "
HDAE5000_PPORT_Svc25_ReadFileHD_Str_ReadFileHD:	.asciz "---[ ReadFileHD ]--- "

; ----------------------------------------------------------------------------
; HDAE5000_CType_Table  (0x2F9362 - 0x2F9461, 256 bytes): the C library's
; character-class table, indexed by the unsigned char itself (entry 0 = NUL).
; Bit meanings, and the reader that tests each:
;   bit 0  upper case       hd-ae5000_v2_06i.s near 0x2823xx (`bit 0,(XBC+WA)`)
;   bit 1  lower case       HDAE5000_StrUpr, HDAE5000_FormatFloat_Fixed/_Exp
;                           (toupper of the conversion letter), and 0x2823xx
;   bit 2  decimal digit    HDAE5000_DoPrintf width/precision parsing, 0x2823xx
;   bit 3  white space, bit 4 punctuation, bit 5 control, bit 6 the space
;   character, bit 7 hex digit: no reader in this ROM (searched every
;   `lda ..,(HDAE5000_CType_Table:24)` site: they test bits 0-2 only); meanings read off
;   the contents -- '0'-'9' = 0x84, 'A'-'F' = 0x81, 'a'-'f' = 0x82, TAB..CR =
;   0x28, ' ' = 0x48, DEL = 0x20, 0x80-0xFF = 0.
; Was written as `.ascii "         (((((..."` plus loose .byte rows.
; ----------------------------------------------------------------------------
HDAE5000_CType_Table:
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x28, 0x28, 0x28, 0x28, 0x28, 0x20, 0x20	; 0x00-0x0F 0x00..0x0F
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20	; 0x10-0x1F 0x10..0x1F
	.byte 0x48, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10	; 0x20-0x2F ' '..'/'
	.byte 0x84, 0x84, 0x84, 0x84, 0x84, 0x84, 0x84, 0x84, 0x84, 0x84, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10	; 0x30-0x3F '0'..'?'
	.byte 0x10, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01	; 0x40-0x4F '@'..'O'
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x10, 0x10, 0x10, 0x10, 0x10	; 0x50-0x5F 'P'..'_'
	.byte 0x10, 0x82, 0x82, 0x82, 0x82, 0x82, 0x82, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02	; 0x60-0x6F '`'..'o'
	.byte 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x10, 0x10, 0x10, 0x10, 0x20	; 0x70-0x7F 'p'..0x7F
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0x80-0x8F 0x80..0x8F
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0x90-0x9F 0x90..0x9F
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0xA0-0xAF 0xA0..0xAF
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0xB0-0xBF 0xB0..0xBF
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0xC0-0xCF 0xC0..0xCF
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0xD0-0xDF 0xD0..0xDF
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0xE0-0xEF 0xE0..0xEF
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0xF0-0xFF 0xF0..0xFF

; ----------------------------------------------------------------------------
; HDAE5000_DoPrintf_ConvTable  (0x2F9462 - 0x2F948D, 22 x u16)
; Conversion-letter jump table of HDAE5000_DoPrintf: it computes
; WA = letter - 'c', refuses WA < 0 or WA > 0x15 (22 entries, 'c'..'x'),
; loads WA = table[WA] (`ld WA,(XIX+WA)` after `add wa,wa`) and jumps to
; HDAE5000_DoPrintf_Case_Char + WA (`jp T,XIX+WA`).  Each entry is therefore
; an offset from that base, written below as a label difference; every one
; lands on an instruction boundary of HDAE5000_DoPrintf (checked against the
; line map).  Letters with no conversion go to HDAE5000_DoPrintf_NextChar.
; ----------------------------------------------------------------------------
HDAE5000_DoPrintf_ConvTable:
	.short	HDAE5000_DoPrintf_Case_Char - HDAE5000_DoPrintf_Case_Char	; 'c'
	.short	HDAE5000_DoPrintf_Case_Int - HDAE5000_DoPrintf_Case_Char	; 'd'
	.short	HDAE5000_DoPrintf_Case_Float - HDAE5000_DoPrintf_Case_Char	; 'e'
	.short	HDAE5000_DoPrintf_Case_Float - HDAE5000_DoPrintf_Case_Char	; 'f'
	.short	HDAE5000_DoPrintf_Case_Float - HDAE5000_DoPrintf_Case_Char	; 'g'
	.short	HDAE5000_DoPrintf_NextChar - HDAE5000_DoPrintf_Case_Char	; 'h'
	.short	HDAE5000_DoPrintf_Case_Int - HDAE5000_DoPrintf_Case_Char	; 'i'
	.short	HDAE5000_DoPrintf_NextChar - HDAE5000_DoPrintf_Case_Char	; 'j'
	.short	HDAE5000_DoPrintf_NextChar - HDAE5000_DoPrintf_Case_Char	; 'k'
	.short	HDAE5000_DoPrintf_NextChar - HDAE5000_DoPrintf_Case_Char	; 'l'
	.short	HDAE5000_DoPrintf_NextChar - HDAE5000_DoPrintf_Case_Char	; 'm'
	.short	HDAE5000_DoPrintf_Case_Count - HDAE5000_DoPrintf_Case_Char	; 'n'
	.short	HDAE5000_DoPrintf_Case_Octal - HDAE5000_DoPrintf_Case_Char	; 'o'
	.short	HDAE5000_DoPrintf_Case_Pointer - HDAE5000_DoPrintf_Case_Char	; 'p'
	.short	HDAE5000_DoPrintf_NextChar - HDAE5000_DoPrintf_Case_Char	; 'q'
	.short	HDAE5000_DoPrintf_NextChar - HDAE5000_DoPrintf_Case_Char	; 'r'
	.short	HDAE5000_DoPrintf_Case_String - HDAE5000_DoPrintf_Case_Char	; 's'
	.short	HDAE5000_DoPrintf_NextChar - HDAE5000_DoPrintf_Case_Char	; 't'
	.short	HDAE5000_DoPrintf_Case_Unsigned - HDAE5000_DoPrintf_Case_Char	; 'u'
	.short	HDAE5000_DoPrintf_NextChar - HDAE5000_DoPrintf_Case_Char	; 'v'
	.short	HDAE5000_DoPrintf_NextChar - HDAE5000_DoPrintf_Case_Char	; 'w'
	.short	HDAE5000_DoPrintf_Case_Hex - HDAE5000_DoPrintf_Case_Char	; 'x'

; Hex digit strings.  HDAE5000_Int_To_Hex_String loads _Upper by default and
; _Lower when the conversion letter is 'x' (`cpw (xsp+12),0x0078`).
HDAE5000_HexDigits_Lower:
	.asciz "0123456789abcdef"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
HDAE5000_HexDigits_Upper:
	.asciz "0123456789ABCDEF"
	.byte 0x00

	.include "hdae5000_init_data.s"

; ============================================================================
; END OF ROM (0x300000)
; ============================================================================

end:

; Labels emitted as .set (exact addresses from ORG/name)
