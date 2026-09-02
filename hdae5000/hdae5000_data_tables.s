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
;                                matches the high half of port 0x01600004, the PPI
;                                port this whole table is registered under in
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
;
; CAUTION: the pool is still partly disassembled AS INSTRUCTIONS - 721
; instruction lines remain interleaved with the data directives below.  They
; are data, not code; re-carving them is a follow-up package.
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
; Symbolising the 769 records is still a follow-up package; the boundaries it
; must use are the .long values of HDAE5000_UiObject_PtrTable, nothing else.
; =============================================================================

	; 0x29DC12  POOL START = HDAE5000_UiObject_PtrTable[0] = record #0,
	;           "HDDMENU", class 016A:0002 TtlScreenRProc, 52 bytes,
	;           box 0,0-319,239, caption "HD-AE5000" at +0x2A.
	.byte 0x02
	.byte 0x00

HDAE5000_UI_Descriptors:	; 0x29DC14
	; MISNOMER retained for cross-reference: this is NOT the start of
	; "UI page descriptors and config", and not a record boundary at all.
	; 0x29DC14 is byte +0x02 of record #0 above, which splits that
	; record's .long class id in half.  The pool starts two bytes lower,
	; at 0x29DC12; see the header block above.
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x01
	.byte 0x00
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.asciz "`"
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xe2, 0x98  ; "â"
	.asciz "#"
	.ascii "<"
	.byte 0xdc  ; "Ü"
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "HD-AE5000"
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x02
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "H"
	.byte 0x9c  ; ""
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "a"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0xe6, 0x98  ; "æ"
	.asciz "#"
	.ascii "|"
	.byte 0xdc  ; "Ü"
	.asciz ")"
	.byte 0x13
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x08
	.zero 3
	.asciz "SETUP & TOOLS  "
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.byte 0x03
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "r"
	.ascii "7"
	.byte 0x01
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0a
	.byte 0x00
	.byte 0xe8, 0x98  ; "è"
	.asciz "#"
	.byte 0xc2, 0xdc  ; "ÂÜ"
	.asciz ")"
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0xae  ; "®"
	.byte 0x00
	.zero 4
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x02
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xaa  ; "ª"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "r"
	.byte 0x19, 0x01
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x06
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.byte 0x05
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x0b
	.byte 0x00
	.byte 0xea, 0x98  ; "ê"
	.asciz "#"
	.ascii "$"
	.byte 0xdd  ; "Ý"
	.asciz ")"
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 4
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x04
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xaa  ; "ª"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x07
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.byte 0x07
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "r"
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0xec, 0x98  ; "ì"
	.asciz "#"
	xor	(xiz), e
	.asciz ")"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "s"
	.zero 4
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x06
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "$"
	.asciz "r"
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.byte 0x09
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xee, 0x98  ; "î"
	.asciz "#"
	cps	xwa, 5
	.asciz ")"
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "!"
	.zero 4
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x08
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "$"
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x04
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.zero 2
	.ascii "j"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x0b
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xbc  ; "¼"
	.byte 0x00
	.byte 0x35
	.byte 0x01
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xf0, 0x98  ; "ð"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0xf4, 0x98  ; "ô"
	.asciz "#"
	.zero 4
	.byte 0xf6, 0x98  ; "ö"
	.asciz "#"
	.zero 2
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x0c
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.byte 0x18
	.zero 5
	.byte 0x1f
	nop
	.byte 0x1f
	nop
	ex_ff
	nop
	pushw de
	normal
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x0d
	.byte 0x00
	.byte 0x0b
	.byte 0x00
	.byte 0x18
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	nop
	incf
	nop
	popw de
	normal
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x0e
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "]"
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "w"
	.byte 0x1b
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.byte 0x0f
	.byte 0x00
	.byte 0x11
	.byte 0x00
	.byte 0x0d
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "H"
	.ascii "7"
	.byte 0x01
	.asciz "a"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xf8, 0x98  ; "ø"
	.asciz "#"
	.byte 0xd4, 0xde  ; "ÔÞ"
	.asciz ")"
	.asciz "\""
	.byte 0x7f
	.byte 0x00
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 4
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x0e
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xaa  ; "ª"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "H"
	.byte 0x19, 0x01
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x05
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x0f
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xaa  ; "ª"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "H"
	.byte 0x19, 0x01
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x05
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x12
	.byte 0x00
	.byte 0x0e
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xfa, 0x98  ; "ú"
	.asciz "#"
	.ascii "`"
	.byte 0xdf  ; "ß"
	.asciz ")"
	.byte 0xf0  ; "ð"
	.byte 0x02, 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "<"
	.zero 4
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 4, 1, 0xff
	.byte 0x11
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xaa  ; "ª"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0xe5  ; "å"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "="
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x8a, 0xdf  ; "ß"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00

HDAE5000_UI_Page_Titles:	; 0x29DF8A
	; MISNOMER retained for cross-reference (the ASL mirror, the symbols
	; reference and a .set base in hdae5000_init_data.s use this name).
	; RETRACTED: "UI page title strings".  There is no table of page titles
	; here.  0x29DF8A is byte +0x28 of object #18 (record 0x29DF62-0x29DF97,
	; 54 bytes, class 0160:0036, a child of HDDMENU) - it is that ONE
	; object's inline caption, named by the .long at +0x1A of the record.
	; The nearest record boundary is 0x28 bytes ABOVE this label.  See the
	; pool header at HDAE5000_UI_Descriptors.
	.asciz "LYRICS WINDOW"
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x14
	.byte 0x00
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xfc, 0x98  ; "ü"
	.asciz "#"
	.byte 0xc2, 0xdf  ; "Âß"
	.asciz ")"
	.byte 0x08
	.zero 3
	.asciz " SETUP & TOOLS "
	.asciz "I"
	.ascii "`"
	.byte 0x01, 0x13
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x15
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.ascii "`"
	.byte 0x01, 0x13
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x16
	.byte 0x00
	.byte 0x14
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x1e
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ">"
	.asciz "="
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "z"
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.ascii "`"
	.byte 0x01, 0x13
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x17
	.byte 0x00
	.byte 0x15
	.byte 0x00
	.byte 0x18
	.zero 3
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ">"
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "n"
	.byte 0x7f
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x13
	.byte 0x00
	.fill 4, 1, 0xff
	.byte 0x16
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x3b
	.byte 0x01, 0x17
	.byte 0x00
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x00
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x19
	.byte 0x00
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x01, 0x02
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "r"
	.byte 0xe0  ; "à"
	.asciz ")"
	.zero 6
	.asciz "I"
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x1a
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x1b
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.byte 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "?"
	.byte 0x01
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x1c
	.byte 0x00
	.byte 0x1a
	.byte 0x00
	.byte 0x18
	.zero 3
	.asciz "@"
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "_"
	.byte 0x02
	.byte 0x00
	.byte 0x10, 0x01, 0x7f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x18
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "$"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x1c
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz "("
	.ascii "1"
	.byte 0x01
	.asciz ":"
	.byte 0x0e
	.byte 0xe1  ; "á"
	.asciz ")"
	.zero 6
	.asciz "LOAD"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x1f
	.byte 0x00
	.byte 0x1c
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.asciz " "
	.byte 0x1e
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "?"
	.byte 0x01
	.asciz "]"
	.ascii "V"
	.byte 0xe1  ; "á"
	.asciz ")"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "~80"
	.asciz ")"
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.asciz "!"
	.byte 0x1f
	.byte 0x00
	.byte 0x18
	.zero 3
	.asciz "`"
	.byte 0x1f
	nop
	jrl	nc, 3328
	nop
	popw de
	normal
	.byte 0x08, 0x00
	.ascii "j"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 4, 1, 0xff
	.asciz " "
	.byte 0x08
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x3b
	.byte 0x01, 0x17
	.byte 0x00
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x06
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "#"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x08
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xc2, 0xe1  ; "Âá"
	.asciz ")"
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "HD DIR SELECT"
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "$"
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "%"
	.asciz "#"
	.byte 0x18
	.zero 5
	.byte 0x1f
	nop
	.byte 0x1f
	nop
	normal
	nop
	popw de
	normal
	.zero 2
	.ascii "j"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "&"
	.asciz "$"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "#"
	.byte 0x07, 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	swi	7
	nop
	normal
	nop
	popw de
	normal
	incf
	.byte 0x99
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x10
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x12
	.byte 0x99  ; ""
	.asciz "#"
	.zero 2
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "'"
	.asciz "%"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x3e
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "|"
	.byte 0xe2  ; "â"
	.asciz ")"
	.asciz "97-120"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "("
	.asciz "&"
	.byte 0x08
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xde  ; "Þ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 7
	.byte 0xb0, 0xe2  ; "°â"
	.asciz ")"
	.asciz "01-24"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz ")"
	.asciz "'"
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.byte 0xde  ; "Þ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "P"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0xe2, 0xe2  ; "ââ"
	.asciz ")"
	.asciz "25-48"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "*"
	.asciz "("
	.byte 0x08
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0x14
	.byte 0xe3  ; "ã"
	.asciz ")"
	.asciz "49-72"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "+"
	.asciz ")"
	.byte 0x08
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x15, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "F"
	.byte 0xe3  ; "ã"
	.asciz ")"
	.asciz "73-96"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz ","
	.asciz "*"
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "$"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz ","
	.byte 0xff
	.fill 5, 1, 0xff
	ldio	0, 15
	normal
	.byte 0xca, 0x00
	ldw	de, 56321
	nop
	or	hl, (xix)
	.asciz ")"
	.zero 6
	.asciz "EDIT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "/"
	.asciz ","
	.byte 0x18
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "0"
	.asciz "."
	.byte 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "?"
	.byte 0x01
	.asciz "_"
	or	hl, ix
	.asciz ")"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01, 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "~80"
	.asciz "."
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "/"
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "2"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x14
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "$"
	.byte 0xe4  ; "ä"
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz " DIRECTORY SELECT   "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "1"
	.asciz "3"
	.asciz "4"
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.asciz "&"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x08
	.byte 0x00
	.byte 0x18
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "p"
	.byte 0xe4  ; "ä"
	.asciz ")"
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.zero 7
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "2"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x16, 0x01
	.asciz "*"
	.ascii ")"
	.byte 0x01
	.asciz "<"
	or	ix, (xde)
	.asciz ")"
	.zero 6
	.asciz "OK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz "1"
	.byte 0xff
	.byte 0xff
	.asciz "5"
	.asciz "2"
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "1"
	.byte 0xff
	.byte 0xff
	.asciz "6"
	.asciz "4"
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0xdc  ; "Ü"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x0f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "1"
	.asciz "7"
	.asciz "8"
	.asciz "5"
	.byte 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.asciz "M"
	.ascii "1"
	.byte 0x01
	.asciz "l"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x09
	.byte 0x00
	.byte 0x1a
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x1e
	.byte 0xe5  ; "å"
	.asciz ")"
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.zero 7
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "6"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x16, 0x01
	.asciz "*"
	.ascii ")"
	.byte 0x01
	.asciz "<"
	.ascii "@"
	.byte 0xe5  ; "å"
	.asciz ")"
	.zero 6
	.asciz "OK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01
	.asciz "1"
	.byte 0xff
	.byte 0xff
	.asciz "9"
	.asciz "6"
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz ","
	.ascii "9"
	.byte 0x01
	.asciz "S"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "1"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "8"
	.byte 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz ";"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x01, 0x1c
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xb0, 0xe5  ; "°å"
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz " FD FILE SELECT   "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz ":"
	.asciz "<"
	.asciz "="
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.asciz "&"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii " "
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xfa, 0xe5  ; "úå"
	.asciz ")"
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.zero 7
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz ";"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz ")"
	.ascii "1"
	.byte 0x01
	.asciz ";"
	.byte 0x1c
	.byte 0xe6  ; "æ"
	.asciz ")"
	.zero 6
	.asciz "COPY"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.byte 0xff
	.asciz ">"
	.asciz ";"
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.byte 0xff
	.asciz "?"
	.asciz "="
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0xdc  ; "Ü"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x0f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.byte 0xff
	.asciz "@"
	.asciz ">"
	.byte 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.asciz "M"
	.ascii "1"
	.byte 0x01
	.asciz "l"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x09
	.byte 0x00
	.byte 0x22
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xaa, 0xe6  ; "ªæ"
	.asciz ")"
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.zero 7
	.asciz "."
	.ascii "`"
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.byte 0xff
	.asciz "A"
	.asciz "?"
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz ","
	.ascii "9"
	.byte 0x01
	.asciz "S"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.byte 0xff
	.asciz "B"
	.asciz "@"
	.byte 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz ":"
	.asciz "C"
	.asciz "D"
	.asciz "A"
	.byte 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "B"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xfe  ; "þ"
	.byte 0x00
	.byte 0xdd  ; "Ý"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x38
	.byte 0xe7  ; "ç"
	.asciz ")"
	.zero 6
	.asciz "SELECT"
	.zero 3
	.ascii "j"
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "B"
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "4"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xcf  ; "Ï"
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x01
	.zero 5
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0x24
	.byte 0x99  ; ""
	.asciz "#"
	push	sr
	nop
	.byte 0x0a, 0x00
	pushw wa
	.byte 0x99  ; ""
	.asciz "#"
	.zero 4
	.ascii "*"
	.byte 0x99  ; ""
	.asciz "#"
	.zero 2
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "F"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	pushw ix
	.byte 0x99  ; ""
	.asciz "#"
	or	xsp, (xiz)
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "HARDWARE TEST"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.asciz "G"
	.asciz "H"
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.asciz "F"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.ascii "*"
	.byte 0x01
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.byte 0xff
	.asciz "I"
	.asciz "F"
	.byte 0x18
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.byte 0xff
	.asciz "J"
	.asciz "H"
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xdb  ; "Û"
	.byte 0x00
	.zero 4
	.ascii "."
	.byte 0xe8  ; "è"
	.asciz ")"
	.ascii "*"
	.byte 0xe8  ; "è"
	.asciz ")"
	.ascii "0"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x0c
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "RUN"
	.asciz "STOP"
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.byte 0xff
	.asciz "K"
	.asciz "I"
	.byte 0x08
	.zero 3
	.asciz " "
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.zero 2
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.byte 0xff
	.asciz "L"
	.asciz "J"
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "L"
	.ascii "7"
	.byte 0x01
	.asciz "]"
	.zero 4
	.ascii "|"
	.byte 0xe8  ; "è"
	.asciz ")"
	.ascii "v"
	.byte 0xe8  ; "è"
	.asciz ")"
	.ascii "2"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "PPORT"
	.asciz "PPORT"
	.asciz "&"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.byte 0xff
	.asciz "M"
	.asciz "K"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.zero 4
	.byte 0xae, 0xe8  ; "®è"
	.asciz ")"
	.byte 0xaa, 0xe8  ; "ªè"
	.asciz ")"
	.ascii "4"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x0b
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "FD"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "FD"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "L"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.asciz "v"
	.ascii "7"
	.byte 0x01
	.byte 0x87  ; ""
	.byte 0x00
	.zero 4
	.byte 0xde, 0xe8  ; "Þè"
	.asciz ")"
	.byte 0xda, 0xe8  ; "Úè"
	.asciz ")"
	.ascii "6"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "HDD"
	.asciz "HDD"
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "O"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x38
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x0c
	.byte 0xe9  ; "é"
	.asciz ")"
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "EDIT FILE NAME"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.asciz "N"
	.byte 0xff
	.byte 0xff
	.asciz "P"
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	nop
	pop	sr
	nop
	popw de
	normal
	.asciz " "
	.ascii "`"
	.byte 0x01
	.asciz "N"
	.byte 0xff
	.byte 0xff
	.asciz "Q"
	.asciz "O"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	pushw 1536
	nop
	normal
	nop
	pushw de
	normal
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "N"
	.byte 0xff
	.byte 0xff
	.asciz "R"
	.asciz "P"
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.ascii "`"
	.byte 0x01
	.asciz "N"
	.asciz "S"
	.asciz "T"
	.asciz "Q"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.asciz "v"
	.ascii "7"
	.byte 0x01
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0a
	.zero 3
	normal
	nop
	pushw de
	normal
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "R"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a, 0x01
	.asciz "w"
	.ascii "5"
	.byte 0x01
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0xc8, 0xe9  ; "Èé"
	.asciz ")"
	.zero 6
	.asciz "OPT"
	.byte 0x04
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.asciz "N"
	.byte 0xff
	.byte 0xff
	.asciz "U"
	.asciz "R"
	.byte 0x18
	.zero 5
	.byte 0x1f
	nop
	.byte 0x1f
	nop
	normal
	nop
	pushw de
	normal
	.asciz " "
	.ascii "`"
	.byte 0x01
	.asciz "N"
	.asciz "V"
	.byte 0xff
	.byte 0xff
	.asciz "T"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "v"
	.asciz "&"
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8a  ; ""
	.byte 0x00
	.zero 2
	normal
	nop
	pushw de
	normal
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "U"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "w"
	.asciz "$"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x32
	.byte 0xea  ; "ê"
	.asciz ")"
	.zero 4
	.byte 0xf9  ; "ù"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LST"
	.asciz "K"
	.ascii "`"
	.byte 0x01
	.fill 8, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "`"
	.byte 0x0b, 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.ascii "<"
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "@"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "Y"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x44
	.byte 0x99  ; ""
	.asciz "#"
	or	(xix), b
	.asciz ")"
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "EDIT DIRECTORY NAME"
	.asciz "M"
	.ascii "`"
	.byte 0x01
	.asciz "X"
	.byte 0xff
	.byte 0xff
	.asciz "Z"
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	nop
	.byte 0x1f
	nop
	push	sr
	nop
	pushw de
	normal
	.asciz " "
	.ascii "`"
	.byte 0x01
	.asciz "X"
	.byte 0xff
	.byte 0xff
	.asciz "["
	.asciz "Y"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	pushw 1536
	nop
	push	sr
	nop
	pushw de
	normal
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "X"
	.byte 0xff
	.byte 0xff
	.asciz "\\"
	.asciz "Z"
	.byte 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "?"
	.asciz "\""
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.ascii "`"
	.byte 0x01
	.asciz "X"
	.asciz "]"
	.byte 0xff
	.byte 0xff
	.asciz "["
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "v"
	.asciz "&"
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8a  ; ""
	.byte 0x00
	.zero 2
	push	sr
	nop
	pushw de
	normal
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "\\"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "w"
	.asciz "$"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x44
	.byte 0xeb  ; "ë"
	.asciz ")"
	.zero 4
	.byte 0xf9  ; "ù"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LST"
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "_"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.ascii "H"
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "L"
	.byte 0x99  ; ""
	.asciz "#"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "^"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "n"
	.asciz "b"
	.byte 0xd1  ; "Ñ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "t"
	.byte 0x8c, 0xeb  ; "ë"
	.asciz ")"
	.zero 6
	.asciz "PLEASE WAIT!"
	.byte 0x00
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "a"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x50
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xc4, 0xeb  ; "Äë"
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "HD UTILITY"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "`"
	.byte 0xff
	.byte 0xff
	.asciz "b"
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0x13
	.byte 0x00
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.asciz "`"
	.byte 0xff
	.byte 0xff
	.asciz "c"
	.asciz "a"
	.byte 0x18
	.zero 5
	.byte 0x1f
	nop
	.byte 0x1f
	nop
	pop	sr
	nop
	pushw de
	normal
	.asciz "F"
	.ascii "`"
	.byte 0x01
	.asciz "`"
	.byte 0xff
	.byte 0xff
	.asciz "d"
	.asciz "b"
	.byte 0x08
	.zero 3
	.asciz " "
	.byte 0xaa  ; "ª"
	.byte 0x00
	.byte 0xef  ; "ï"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "="
	.ascii "`"
	.byte 0x01
	.asciz "`"
	.byte 0xff
	.byte 0xff
	.asciz "e"
	.asciz "c"
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "H"
	.ascii "7"
	.byte 0x01
	.asciz "a"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x09
	.byte 0x00
	.byte 0x54
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "L"
	.byte 0xec  ; "ì"
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "FORMAT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "="
	.ascii "`"
	.byte 0x01
	.asciz "`"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "d"
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0b
	.byte 0x00
	.byte 0x56
	.byte 0x99  ; ""
	.asciz "#"
	or	(xiz), d
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "READ ID"
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "g"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	pop xwa
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xb8, 0xec  ; "¸ì"
	.asciz ")"
	.zero 4
	.asciz "   PC DATA LINK"
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.asciz "f"
	.byte 0xff
	.byte 0xff
	.asciz "h"
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	nop
	.byte 0x1f
	nop
	max
	nop
	pushw de
	normal
	.zero 2
	.ascii "j"
	.byte 0x01
	.asciz "f"
	.byte 0xff
	.byte 0xff
	.asciz "i"
	.asciz "g"
	.byte 0x08
	.byte 0x00
	.byte 0x14
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T"
	.ascii "+"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.ascii "@"
	normal
	pop xix
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x60
	.byte 0x99  ; ""
	.asciz "#"
	.zero 4
	.ascii "b"
	.byte 0x99  ; ""
	.asciz "#"
	.zero 2
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz "f"
	.asciz "j"
	.asciz "k"
	.asciz "h"
	.byte 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "i"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xfe  ; "þ"
	.byte 0x00
	.byte 0xdb  ; "Û"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xed  ; "í"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "h"
	.byte 0xed  ; "í"
	.asciz ")"
	.zero 6
	.asciz "CANCEL"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz "f"
	.asciz "l"
	.asciz "m"
	.asciz "i"
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "k"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x12
	.byte 0x00
	.byte 0xdb  ; "Û"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "="
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0xba, 0xed  ; "ºí"
	.asciz ")"
	.zero 6
	.asciz "START"
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.asciz "f"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "k"
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "L"
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "f"
	.byte 0x1b
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "o"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.asciz "Z"
	.byte 0x1a, 0x01
	.byte 0xbd  ; "½"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 4
	.ascii "d"
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "h"
	.byte 0x99  ; ""
	.asciz "#"
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "n"
	.asciz "p"
	.asciz "q"
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0b
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "l"
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "4"
	.byte 0xee  ; "î"
	.asciz ")"
	.asciz "f"
	.byte 0x7f
	.byte 0x00
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "PC DATA LINK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.asciz "o"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1b, 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x35
	.byte 0x01
	.byte 0xb5  ; "µ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz "n"
	.byte 0xff
	.byte 0xff
	.asciz "r"
	.asciz "o"
	.byte 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "n"
	.asciz "s"
	.asciz "t"
	.asciz "q"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "H"
	.byte 0xa3  ; "£"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "a"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0xc0, 0xee  ; "Àî"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "n"
	.byte 0x99  ; ""
	.asciz "#"
	scf
	nop
	pushw de
	normal
	.ascii "p"
	.byte 0x99  ; ""
	.asciz "#"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.asciz "r"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "H"
	.byte 0x80  ; ""
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x08
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "n"
	.byte 0xff
	.byte 0xff
	.asciz "u"
	.asciz "r"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.ascii "&"
	.byte 0xef  ; "ï"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "t"
	.byte 0x99  ; ""
	.asciz "#"
	zcf
	nop
	pushw de
	normal
	.ascii "v"
	.byte 0x99  ; ""
	.asciz "#"
	.asciz "QUICK LD MODE:"
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "n"
	.byte 0xff
	.byte 0xff
	.asciz "v"
	.asciz "t"
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "H"
	.ascii "7"
	.byte 0x01
	.asciz "a"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.ascii "p"
	.byte 0xef  ; "ï"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "z"
	.byte 0x99  ; ""
	.asciz "#"
	pop_a
	nop
	pushw de
	normal
	.byte 0x7c, 0x99
	.asciz "#"
	.asciz "JUMP AFTER LD.:"
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "n"
	.asciz "w"
	.asciz "x"
	.asciz "u"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "r"
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0xba, 0xef  ; "ºï"
	.asciz ")"
	.zero 4
	swi	7
	nop
	push	sr
	nop
	max
	nop
	.byte 0x8a, 0x00, 0x01
	nop
	adc	(xwa), a
	.asciz "#"
	ccf
	nop
	pushw de
	normal
	adc	(xde), a
	.asciz "#"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.asciz "v"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "r"
	.byte 0x80  ; ""
	.byte 0x00
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x09
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "n"
	.byte 0xff
	.byte 0xff
	.asciz "y"
	.asciz "v"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.ascii " "
	.byte 0xf0  ; "ð"
	.asciz ")"
	.zero 4
	swi	7
	nop
	normal
	nop
	push	sr
	nop
	.byte 0x8c, 0x00, 0x01
	nop
	adc	(xiz), a
	.asciz "#"
	push_a
	nop
	pushw de
	normal
	.byte 0x88, 0x99
	.asciz "#"
	.asciz "LD BY NUM. M.:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "n"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "x"
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "r"
	.ascii "7"
	.byte 0x01
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0a
	.byte 0x00
	.byte 0x8c, 0x99  ; ""
	.asciz "#"
	.ascii "f"
	.byte 0xf0  ; "ð"
	.asciz ")"
	.byte 0x0c, 0x03, 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "<"
	.zero 2
	.asciz "LYRICS OPTIONS"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "{"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 4
	.byte 0x8e, 0x99  ; ""
	.asciz "#"
	adc	(xde), bc
	.asciz "#"
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "z"
	.asciz "|"
	.asciz "}"
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8c  ; ""
	.byte 0x00
	adc	(xiz), bc
	.asciz "#"
	.byte 0xd0, 0xf0  ; "Ðð"
	.asciz ")"
	.byte 0xff
	.fill 3, 1, 0xff
	.zero 6
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.asciz "{"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0xe5  ; "å"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0b
	.zero 9
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "z"
	.asciz "~"
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "{"
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0c
	.byte 0x00
	.byte 0x98, 0x99  ; ""
	.asciz "#"
	.ascii "2"
	.byte 0xf1  ; "ñ"
	.asciz ")"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x01
	.zero 3
	.asciz "HD-AE INFOS  "
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.asciz "}"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1b, 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0x35
	.byte 0x01
	.byte 0xdf  ; "ß"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.asciz "z"
	.byte 0xff
	.byte 0xff
	.byte 0x80  ; ""
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "}"
	.byte 0x18
	.zero 3
	.asciz "@"
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "_"
	max
	nop
	popw de
	normal
	.asciz "! HD FORMAT !"
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.byte 0x80  ; ""
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1b, 0x01
	.asciz "G"
	.ascii "5"
	.byte 0x01
	.asciz "a"
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "z"
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x80  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0b
	.byte 0x00
	.byte 0x9c, 0x99  ; ""
	.asciz "#"
	.byte 0xd2, 0xf1  ; "Òñ"
	.asciz ")"
	.byte 0x81  ; ""
	.byte 0x02, 0x7f
	.byte 0x00
	.byte 0x01
	.zero 5
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x84  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1b, 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x35
	.byte 0x01
	.byte 0xb5  ; "µ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa9  ; "©"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x25
	.byte 0x01
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0a
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x86  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x9e, 0x99  ; ""
	.asciz "#"
	.ascii "B"
	.byte 0xf2  ; "ò"
	.asciz ")"
	.asciz "!"
	.zero 2
	.asciz "OUTPUT SETTING"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0x86  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "H"
	.ascii "7"
	.byte 0x01
	.asciz "a"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0xd0, 0xf2  ; "Ðò"
	.asciz ")"
	.zero 4
	swi	7
	nop
	push	sr
	nop
	rcf
	nop
	.byte 0x89, 0x00, 0x01
	nop
	adc	(xde), xbc
	.asciz "#"
	halt
	nop
	pushw de
	normal
	adc	(xix), xbc
	.asciz "#"
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "r"
	.ascii "7"
	.byte 0x01
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0x0c
	.byte 0xf3  ; "ó"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xa8, 0x99  ; "¨"
	.asciz "#"
	.asciz "<"
	.ascii "*"
	.byte 0x01
	.byte 0xaa, 0x99  ; "ª"
	.asciz "#"
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.ascii "H"
	.byte 0xf3  ; "ó"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xae, 0x99  ; "®"
	.asciz "#"
	.asciz "="
	.ascii "*"
	normal
	ldcfm	1, (xwa)
	.asciz "#"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x8c  ; ""
	.byte 0x00
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "H"
	.byte 0xc9  ; "É"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0d
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x8d  ; ""
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "r"
	.byte 0x07, 0x01
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0e
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x8e  ; ""
	.byte 0x00
	.byte 0x8c  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x07, 0x01
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0f
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x8d  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0xb8  ; "¸"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x10
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x90  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	ldcfm	1, (xix)
	.asciz "#"
	.byte 0x1c
	.byte 0xf4  ; "ô"
	.asciz ")"
	.byte 0xae  ; "®"
	.byte 0x00
	.zero 2
	.asciz "LOAD BY NUMBER"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.ascii "`"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x92  ; ""
	.byte 0x00
	.byte 0x90  ; ""
	.byte 0x00
	.byte 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "?"
	.byte 0x01
	.byte 0x00
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.ascii "`"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x93  ; ""
	.byte 0x00
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0x18
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz " "
	.asciz "?"
	.asciz "?"
	.byte 0x02
	.byte 0x00
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x94  ; ""
	.byte 0x00
	.byte 0x92  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x3b
	.byte 0x01, 0x17
	.byte 0x00
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb8, 0x99  ; "¸"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x93  ; ""
	.byte 0x00
	.byte 0x18
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.asciz " "
	.asciz "_"
	.asciz "?"
	.asciz ")"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x96  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 4
	.byte 0xba, 0x99  ; "º"
	.asciz "#"
	.byte 0xbe, 0x99  ; "¾"
	.asciz "#"
	.byte 0x1c
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0x98  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x07, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0c
	.byte 0x00
	.byte 0xc2, 0x99  ; "Â"
	.asciz "#"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x96  ; ""
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	ldio	0, 9
	normal
	.byte 0xcc, 0x00
	ldw	ix, 56833
	nop
	pushw de
	.byte 0xf5  ; "õ"
	.asciz ")"
	.zero 6
	.asciz "CLEAR"
	.zero 2
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0x96  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "["
	.ascii "?"
	.byte 0x01
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xc4, 0x99  ; "Ä"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xc8, 0x99  ; "È"
	.asciz "#"
	.zero 4
	.byte 0xca, 0x99  ; "Ê"
	.asciz "#"
	.zero 2
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0x9a  ; ""
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x98  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "$"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz ")"
	.ascii "1"
	.byte 0x01
	.asciz ";"
	.byte 0xb4, 0xf5  ; "´õ"
	.asciz ")"
	.zero 6
	.asciz "LOAD"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "?"
	.byte 0x01
	.asciz "]"
	.byte 0xe2, 0xf5  ; "âõ"
	.asciz ")"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "~80"
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "6"
	.ascii "`"
	normal
	.byte 0x95, 0x00, 0x9e, 0x00, 0xa0
	nop
	.byte 0x9c, 0x00, 0x08
	nop
	max
	nop
	.byte 0xae, 0x00, 0xc7
	nop
	.byte 0xee, 0x00, 0xf5, 0x00, 0xc0
	nop
	pushw wa
	.byte 0xf6  ; "ö"
	.asciz ")"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x50
	.byte 0xf6  ; "ö"
	.asciz ")"
	.zero 8
	.asciz "0"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x9e  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xb3  ; "³"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "x"
	.byte 0xf6  ; "ö"
	.asciz ")"
	.zero 8
	.asciz "1"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.byte 0xd2  ; "Ò"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "J"
	.byte 0xeb, 0x00
	reti
	nop
	.byte 0xc0, 0x00
	cp	xiz, (xwa)
	.asciz ")"
	.zero 8
	.asciz "2"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.byte 0xb3  ; "³"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "J"
	.byte 0xcc, 0x00
	reti
	nop
	.byte 0xc0, 0x00
	cp	h, w
	.asciz ")"
	.zero 8
	.asciz "3"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "X"
	.byte 0xd2  ; "Ò"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "r"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xf0, 0xf6  ; "ðö"
	.asciz ")"
	.zero 8
	.asciz "4"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "X"
	.byte 0xb3  ; "³"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "r"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x18
	.byte 0xf7  ; "÷"
	.asciz ")"
	.zero 8
	.asciz "5"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa5  ; "¥"
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x80  ; ""
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x9a  ; ""
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x40
	.byte 0xf7  ; "÷"
	.asciz ")"
	.zero 8
	.asciz "6"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x80  ; ""
	.byte 0x00
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0x9a  ; ""
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "h"
	.byte 0xf7  ; "÷"
	.asciz ")"
	.zero 8
	.asciz "7"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa7  ; "§"
	.byte 0x00
	.byte 0xa5  ; "¥"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa8  ; "¨"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xc2  ; "Â"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x90, 0xf7  ; "÷"
	.asciz ")"
	.zero 8
	.asciz "8"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa8  ; "¨"
	.byte 0x00
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa8  ; "¨"
	.byte 0x00
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0xc2  ; "Â"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xb8, 0xf7  ; "¸÷"
	.asciz ")"
	.zero 8
	.asciz "9"
	.zero 2
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa9  ; "©"
	.byte 0x00
	.byte 0xa7  ; "§"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "-"
	.asciz "#"
	.asciz "B"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.zero 4
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xcc, 0x99  ; "Ì"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xd0, 0x99  ; "Ð"
	.asciz "#"
	.zero 4
	.byte 0xd2, 0x99  ; "Ò"
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xaa  ; "ª"
	.byte 0x00
	.byte 0xa8  ; "¨"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.asciz "-"
	.byte 0xf9  ; "ù"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "B"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.zero 4
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xd4, 0x99  ; "Ô"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xd8, 0x99  ; "Ø"
	.asciz "#"
	.zero 4
	.byte 0xda, 0x99  ; "Ú"
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xab  ; "«"
	.byte 0x00
	.byte 0xa9  ; "©"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "D"
	.asciz "#"
	.asciz "Y"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.zero 4
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xdc, 0x99  ; "Ü"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xe0, 0x99  ; "à"
	.asciz "#"
	.zero 4
	.byte 0xe2, 0x99  ; "â"
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xac  ; "¬"
	.byte 0x00
	.byte 0xaa  ; "ª"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.asciz "D"
	.byte 0xf9  ; "ù"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Y"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.zero 4
	.byte 0xf2  ; "ò"
	.byte 0x00
	.zero 2
	.ascii "@"
	.byte 0x01
	.byte 0xe4, 0x99  ; "ä"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xe8, 0x99  ; "è"
	.asciz "#"
	.zero 4
	.byte 0xea, 0x99  ; "ê"
	.asciz "#"
	.zero 2
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xad  ; "­"
	.byte 0x00
	.byte 0xab  ; "«"
	.byte 0x00
	.byte 0x18
	.zero 3
	.asciz "`"
	.byte 0x1f
	.byte 0x00
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.ascii "*"
	.byte 0x01
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xae  ; "®"
	.byte 0x00
	.byte 0xac  ; "¬"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdd  ; "Ý"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x05
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0xad  ; "­"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "t"
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0xa9  ; "©"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x15
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xb0  ; "°"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "h"
	.byte 0x1f
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 4
	.byte 0xec, 0x99  ; "ì"
	.asciz "#"
	.byte 0xf0, 0x99  ; "ð"
	.asciz "#"
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "/"
	.byte 0x07, 0x01
	.asciz "H"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.ascii "v"
	.byte 0xf9  ; "ù"
	.asciz ")"
	.byte 0x05
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xf4, 0x99  ; "ô"
	.asciz "#"
	.asciz "*"
	.ascii "*"
	.byte 0x01
	.byte 0xf6, 0x99  ; "ö"
	.asciz "#"
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb2  ; "²"
	.byte 0x00
	.byte 0xb0  ; "°"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.asciz "L"
	.byte 0x03, 0x01
	.asciz "["
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0xb2, 0xf9  ; "²ù"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xfa, 0x99  ; "ú"
	.asciz "#"
	.asciz "+"
	.ascii "*"
	.byte 0x01
	.byte 0xfc, 0x99  ; "ü"
	.asciz "#"

HDAE5000_Panel_Save_UI:	; 0x29F9B2
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
	.asciz "CURRENT PANEL          "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0xb4  ; "´"
	.byte 0x00
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.asciz "["
	.byte 0x03, 0x01
	.asciz "j"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0xfa  ; "ú"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 4
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz ","
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "PANEL MEMORY           "
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xb2  ; "²"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "J"
	.asciz "("
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xb2  ; "²"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.asciz "j"
	.byte 0x03, 0x01
	.asciz "y"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "p"
	.byte 0xfa  ; "ú"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x06
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "-"
	.ascii "*"
	.byte 0x01, 0x08
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "SEQUENCER              "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0xb4  ; "´"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.asciz "y"
	.byte 0x03, 0x01
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.byte 0xc2, 0xfa  ; "Âú"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x0c
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "."
	.ascii "*"
	.byte 0x01, 0x0e
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "COMPOSER               "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb7  ; "·"
	.byte 0x00
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x05
	.byte 0x00
	.byte 0x14
	.byte 0xfb  ; "û"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "/"
	.ascii "*"
	.byte 0x01, 0x14
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "SOUND MEMORY           "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb8  ; "¸"
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "f"
	.byte 0xfb  ; "û"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x18
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "0"
	.ascii "*"
	.byte 0x01, 0x1a
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "MSP                    "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb9  ; "¹"
	.byte 0x00
	.byte 0xb7  ; "·"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x07
	.byte 0x00
	.byte 0xb8, 0xfb  ; "¸û"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x1e
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "1"
	.ascii "*"
	.byte 0x01
	.ascii " "
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "RHYTHM CUSTOM          "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xba  ; "º"
	.byte 0x00
	.byte 0xb8  ; "¸"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x08
	.byte 0x00
	.byte 0x0a
	.byte 0xfc  ; "ü"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "$"
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "2"
	.ascii "*"
	.byte 0x01
	.byte 0x26
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "USER MIDI SETTINGS     "
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xb9  ; "¹"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "J"
	.byte 0x07, 0x01
	.asciz "J"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xbc  ; "¼"
	.byte 0x00
	.byte 0xba  ; "º"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x07, 0x01
	.asciz "J"
	.byte 0x07, 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xbd  ; "½"
	.byte 0x00
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x07, 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xbe  ; "¾"
	.byte 0x00
	.byte 0xbc  ; "¼"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "#"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 11
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0xbd  ; "½"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xbe  ; "¾"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T"
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "s"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "|"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x03
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc2  ; "Â"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x05
	.zero 9
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x07
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc4  ; "Ä"
	.byte 0x00
	.byte 0xc2  ; "Â"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x08
	.zero 9
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x06
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xc4  ; "Ä"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xd0, 0xfd  ; "Ðý"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "PNL"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "*"
	.byte 0xca  ; "Ê"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xf4, 0xfd  ; "ôý"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "P.MEM"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc8  ; "È"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "X"
	.byte 0xca  ; "Ê"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "m"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x1a
	.byte 0xfe  ; "þ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SEQ"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "~"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x3e
	.byte 0xfe  ; "þ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "COMP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xc8  ; "È"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "d"
	.byte 0xfe  ; "þ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SOUND"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x8a, 0xfe  ; "þ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MSP"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x16, 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xae, 0xfe  ; "®þ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "CUSTOM"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x1e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xd6, 0xfe  ; "Öþ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MIDI"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xd7  ; "×"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "J"
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xcf  ; "Ï"
	.byte 0x00
	.byte 0xd0  ; "Ð"
	.byte 0x00
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "$"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz ")"
	.ascii "1"
	.byte 0x01
	.asciz ";"
	.ascii ">"
	.byte 0xff
	.asciz ")"
	.zero 6
	.asciz "LOAD"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0xd0  ; "Ð"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "?"
	.byte 0x01
	.asciz "]"
	.byte 0x86  ; ""
	.byte 0xff
	.asciz ")"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "~80"
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	pushw de
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0xb4  ; "´"
	.byte 0xff
	.asciz ")"
	.asciz "s"
	.zero 2
	.asciz "COPY TECH TO HD"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd5  ; "Õ"
	.byte 0x00
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x0f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0xd5  ; "Õ"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz ":"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 8
	.byte 0x0a
	.byte 0x00
	popw de
	normal
	pushw iz
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.byte 0x32
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x34
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd9  ; "Ù"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xd7  ; "×"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "<"
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xda  ; "Ú"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "v"
	.asciz "<"
	.asciz "v"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xda  ; "Ú"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x10, 0x01
	.asciz "#"
	.ascii "3"
	.byte 0x01
	.asciz "5"
	.byte 0xe8  ; "è"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "*"
	.zero 6
	.asciz "* TO"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0b, 0x01
	.byte 0xcf  ; "Ï"
	.byte 0x00
	.byte 0x32
	.byte 0x01
	.byte 0xd9  ; "Ù"
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SELECT"
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x8e  ; ""
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&"
	.byte 0xeb  ; "ë"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "5"
	.byte 0x07
	.zero 3
	.asciz "d"
	.zero 4
	.byte 0xf2  ; "ò"
	.byte 0x00
	.zero 2
	.ascii "@"
	.byte 0x01
	.byte 0x36
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x3a
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 4
	.ascii "<"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 2
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "$"
	.byte 0xef  ; "ï"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "x"
	.byte 0x01
	.asciz "*"
	.zero 6
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "StringBox"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08, 0x01
	.byte 0xa5  ; "¥"
	.byte 0x00
	.byte 0x35
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x01
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SEL ALL"
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xe3  ; "ã"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x3e
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0xd4  ; "Ô"
	.byte 0x01
	.asciz "*"
	.asciz "s"
	.zero 2
	.asciz "HD DIR SELECT"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xe4  ; "ä"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xe5  ; "å"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xe3  ; "ã"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0d, 0x01, 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xe4  ; "ä"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x10, 0x01
	.asciz "#"
	.ascii "3"
	.byte 0x01
	.asciz "5"
	.ascii "D"
	.byte 0x02
	.asciz "*"
	.zero 6
	.asciz "COPY"
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xe7  ; "ç"
	.byte 0x00
	.byte 0xe4  ; "ä"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "#"
	.byte 0x07, 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	swi	7
	nop
	.byte 0x0b, 0x00
	popw de
	normal
	.byte 0x42, 0x9a
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x46
	.byte 0x9a  ; ""
	.asciz "#"
	normal
	nop
	normal
	nop
	popw wa
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 2
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xe8  ; "è"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xde  ; "Þ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 7
	.byte 0xb2  ; "²"
	.byte 0x02
	.asciz "*"
	.asciz "01-24"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xe9  ; "é"
	.byte 0x00
	.byte 0xe7  ; "ç"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.byte 0xde  ; "Þ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "P"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0xe4  ; "ä"
	.byte 0x02
	.asciz "*"
	.asciz "25-48"
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xea  ; "ê"
	.byte 0x00
	.byte 0xe8  ; "è"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xe9  ; "é"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "@"
	.byte 0x03
	.asciz "*"
	.asciz "49-72"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xea  ; "ê"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x15, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "r"
	.byte 0x03
	.asciz "*"
	.asciz "73-96"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x3e
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0xa4  ; "¤"
	.byte 0x03
	.asciz "*"
	.asciz "97-120"
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0d, 0x01
	.byte 0xc2  ; "Â"
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xdb  ; "Û"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x0c
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x11, 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0x34
	.byte 0x01
	.byte 0xd9  ; "Ù"
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x03
	.asciz "*"
	.zero 6
	.asciz "EDIT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x18
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	nop
	.byte 0x0b, 0x00
	popw de
	normal
	ei	0
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	popw de
	.byte 0x9a  ; ""
	.asciz "#"
	.ascii ">"
	.byte 0x04
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz " F.L.S. SELECT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xde  ; "Þ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 7
	.byte 0x94  ; ""
	.byte 0x04
	.asciz "*"
	.asciz "01-24"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.byte 0xde  ; "Þ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "P"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0xc6  ; "Æ"
	.byte 0x04
	.asciz "*"
	.asciz "25-48"
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf6  ; "ö"
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "\""
	.byte 0x05
	.asciz "*"
	.asciz "49-72"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf7  ; "÷"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x15, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "T"
	.byte 0x05
	.asciz "*"
	.asciz "73-96"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xf6  ; "ö"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x3e
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0x86  ; ""
	.byte 0x05
	.asciz "*"
	.asciz "97-120"
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "#"
	.ascii "7"
	.byte 0x01
	.asciz "<"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x05
	.asciz "*"
	.zero 6
	.asciz "EDIT"
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xfc  ; "ü"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.byte 0xff
	.byte 0x00
	.byte 0xd9  ; "Ù"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	swi	7
	nop
	halt
	nop
	popw de
	normal
	popw iz
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x52
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x54
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 2
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xfd  ; "ý"
	.byte 0x00
	.byte 0xfb  ; "û"
	.byte 0x00
	.byte 0x18
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	nop
	halt
	nop
	popw de
	normal
	.asciz "0"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xfe  ; "þ"
	.byte 0x00
	.byte 0xfc  ; "ü"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "A"
	.byte 0x01
	.asciz "_"
	.ascii "Z"
	.byte 0x06
	.asciz "*"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01, 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "~80"
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0xfd  ; "ý"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x00
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "<"
	.asciz "P"
	.byte 0xeb  ; "ë"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "{"
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.ascii "V"
	.byte 0x9a  ; ""
	.asciz "#"
	.ascii "Z"
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xbc  ; "¼"
	.byte 0x06
	.asciz "*"
	.zero 6
	.asciz "SAVE"
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x03, 0x01
	.byte 0x00
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "_"
	.ascii "@"
	.byte 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	normal
	pop xiz
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "b"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 4
	.ascii "d"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x04, 0x01, 0x02, 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz "4"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	swi	7
	nop
	push	sr
	nop
	popw de
	normal
	.ascii "f"
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "l"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x05, 0x01, 0x03, 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz "#"
	.byte 0xeb  ; "ë"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "2"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.ascii "n"
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "r"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 4
	.ascii "t"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 2
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x06, 0x01, 0x04, 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0xdc  ; "Ü"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x0f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x07, 0x01, 0x05, 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x08, 0x01, 0x06, 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "-"
	.ascii "`"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x09, 0x01, 0x07, 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.zero 2
	.asciz "G"
	.byte 0x1b
	.byte 0x00
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x0a, 0x01, 0x08, 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "N"
	ei	0
	.byte 0xeb, 0x00
	push_f
	nop
	pushw de
	.byte 0x08
	.asciz "*"
	.byte 0x04
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "HD FILE SELECT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x0a, 0x01
	.fill 2, 1, 0xff
	.byte 0x0c, 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0b
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "!"
	.asciz " "
	.asciz "+"
	.ascii "Z"
	.byte 0x08
	.asciz "*"
	.byte 0x03
	.zero 5
	.asciz "DEL"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x0a, 0x01
	.fill 4, 1, 0xff
	pushw 0x0801
	nop
	.byte 0x0b, 0x00
	.asciz "+"
	.asciz " "
	.asciz "5"
	.ascii "~"
	.byte 0x08
	.asciz "*"
	.byte 0x03
	.zero 5
	.asciz "DIR"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x0d, 0x01
	.fill 2, 1, 0xff
	.byte 0x0f, 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "u"
	.byte 0x1f
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x08
	.asciz "*"
	.byte 0x03
	.zero 5
	.asciz "DEL"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x0d, 0x01
	.fill 4, 1, 0xff
	.byte 0x0e, 0x01, 0x08
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x08
	.asciz "*"
	.byte 0x03
	.zero 5
	.asciz "FILE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x11, 0x01
	.fill 4, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "F"
	.asciz "P"
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.ascii "v"
	.byte 0x9a  ; ""
	.asciz "#"
	.ascii "z"
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x12, 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "N"
	.byte 0x06
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.byte 0x10, 0x09
	.asciz "*"
	.byte 0x04
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "HD LOAD OPTION"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "-"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x13, 0x01, 0x11, 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.zero 2
	.asciz "G"
	.byte 0x1b
	.byte 0x00
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x14, 0x01, 0x12, 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.asciz "4"
	.byte 0x03, 0x01
	.asciz "C"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "t"
	.byte 0x09
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "~"
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x08
	.byte 0x00
	pushw de
	normal
	adc	(xwa), b
	.asciz "#"
	.asciz "CURRENT PANEL          "
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x15, 0x01, 0x13, 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "#"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 11
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x16, 0x01, 0x14, 0x01, 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x09
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "PNL"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x17, 0x01, 0x15, 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x18, 0x01, 0x16, 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T"
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "s"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x19, 0x01, 0x17, 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "|"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x03
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1a, 0x01, 0x18, 0x01, 0x08
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x05
	.zero 9
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1b, 0x01, 0x19, 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x06
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1c, 0x01, 0x1a, 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x07
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1d, 0x01, 0x1b, 0x01, 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x08
	.zero 9
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1e, 0x01, 0x1c, 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "*"
	.byte 0xca  ; "Ê"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x10, 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "P.MEM"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1f, 0x01, 0x1d, 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "X"
	.byte 0xca  ; "Ê"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "m"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x36
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SEQ"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii " "
	.byte 0x01, 0x1e, 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "~"
	.byte 0xca, 0x00, 0x99, 0x00, 0xd4
	nop
	pop xde
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "COMP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "!"
	.byte 0x01, 0x1f, 0x01, 0x08
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x80  ; ""
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SOUND"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "\""
	.byte 0x01
	.ascii " "
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xa6  ; "¦"
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MSP"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "#"
	.byte 0x01
	.byte 0x21
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x16, 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "CUSTOM"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "$"
	.byte 0x01
	.byte 0x22
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MIDI"
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "%"
	.byte 0x01
	.byte 0x23
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.asciz "T"
	.byte 0x03, 0x01
	.asciz "c"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x03
	.byte 0x00
	.byte 0x32
	.byte 0x0c
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	adc	(xix), b
	.asciz "#"
	.byte 0x0a
	.byte 0x00
	pushw de
	normal
	adc	(xiz), b
	.asciz "#"
	.asciz "SEQUENCER              "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "&"
	.byte 0x01
	.byte 0x24
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.asciz "d"
	.byte 0x03, 0x01
	.asciz "s"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.byte 0x84  ; ""
	.byte 0x0c
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x8a, 0x9a  ; ""
	.asciz "#"
	.byte 0x0b
	.byte 0x00
	pushw de
	normal
	.byte 0x8c, 0x9a
	.asciz "#"
	.asciz "COMPOSER               "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "'"
	.byte 0x01
	.byte 0x25
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.asciz "t"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x05
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x0c
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	adc	(xwa), de
	.asciz "#"
	incf
	nop
	pushw de
	normal
	adc	(xde), de
	.asciz "#"
	.asciz "SOUND MEMORY           "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "("
	.byte 0x01
	.byte 0x26
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.byte 0x84  ; ""
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0x93  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	ei	0
	pushw wa
	.byte 0x0d
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	adc	(xiz), de
	.asciz "#"
	decf
	nop
	pushw de
	normal
	.byte 0x98, 0x9a
	.asciz "#"
	.asciz "MSP                    "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii ")"
	.byte 0x01
	.byte 0x27
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.byte 0x94  ; ""
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x07
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "z"
	.byte 0x0d
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x9c, 0x9a  ; ""
	.asciz "#"
	ret
	nop
	pushw de
	normal
	.byte 0x9e, 0x9a
	.asciz "#"
	.asciz "RHYTHM CUSTOM          "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "*"
	normal
	pushw wa
	normal
	.byte 0x08, 0x00
	.asciz "0"
	.byte 0xb4  ; "´"
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x09
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x0d
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	adc	(xde), xde
	.asciz "#"
	rcf
	nop
	pushw de
	normal
	adc	(xix), xde
	.asciz "#"
	.asciz "TECHNICS LYRICS        "
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "+"
	normal
	pushw bc
	normal
	.byte 0x08, 0x00
	.asciz "*"
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x07, 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii ","
	normal
	pushw de
	normal
	.byte 0x08, 0x00
	.asciz "*"
	.byte 0x18
	.byte 0x00
	.byte 0x07, 0x01
	.asciz "1"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x38
	.byte 0x0e
	.asciz "*"
	.byte 0x05
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xa8, 0x9a  ; "¨"
	.asciz "#"
	reti
	nop
	pushw de
	normal
	.byte 0xaa, 0x9a
	.asciz "#"
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "-"
	normal
	pushw hl
	normal
	.byte 0x08, 0x00
	.asciz "0"
	.asciz "D"
	.byte 0x03, 0x01
	.asciz "S"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "t"
	.byte 0x0e
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xae, 0x9a  ; "®"
	.asciz "#"
	push 0
	pushw de
	normal
	ldcfm	2, (xwa)
	.asciz "#"
	.asciz "PANEL MEMORY           "
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "."
	normal
	pushw ix
	normal
	ldio	0, 7
	normal
	.asciz "2"
	.byte 0x07, 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "0"
	normal
	pushw iz
	normal
	ldio	0, 6
	nop
	.byte 0x94, 0x00
	.asciz "'"
	.byte 0x9e  ; ""
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x0e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LYRIC"
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "1"
	.byte 0x01
	.byte 0x2f
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x08
	.byte 0x00
	.byte 0x06, 0x0f
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	ldcfm	2, (xix)
	.asciz "#"
	.byte 0x0f
	.byte 0x00
	pushw de
	normal
	ldcfm	2, (xiz)
	.asciz "#"
	.asciz "USER MIDI SETTINGS     "
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "2"
	.byte 0x01
	.byte 0x30
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd5  ; "Õ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "2"
	.byte 0xd5  ; "Õ"
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "3"
	.byte 0x01
	.byte 0x31
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "*"
	.asciz "2"
	.asciz "*"
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 4, 1, 0xff
	.ascii "2"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "*"
	.asciz "2"
	.byte 0x07, 0x01
	.asciz "2"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "5"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xba, 0x9a  ; "º"
	.asciz "#"
	.byte 0x96  ; ""
	.byte 0x0f
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "EDIT FLS NAME"
	.asciz "M"
	.ascii "`"
	.byte 0x01
	.byte 0x34
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "6"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	nop
	.byte 0x1f
	nop
	ldf	0
	pushw de
	normal
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x34
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "7"
	.byte 0x01
	.byte 0x35
	.byte 0x01, 0x18
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.ascii "`"
	.byte 0x01
	.byte 0x34
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "8"
	.byte 0x01
	.byte 0x36
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	pushw 1536
	nop
	ldf	0
	pushw de
	normal
	.asciz " "
	.ascii "`"
	.byte 0x01
	.byte 0x34
	.byte 0x01
	.byte 0x39
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "7"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "v"
	.asciz "&"
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8a  ; ""
	.byte 0x00
	.zero 2
	ldf	0
	pushw de
	normal
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x38
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "w"
	.asciz "$"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x50
	.byte 0x10
	.asciz "*"
	.zero 4
	.byte 0xf9  ; "ù"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LST"
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii ";"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xbe, 0x9a  ; "¾"
	.asciz "#"
	.ascii "~"
	.byte 0x10
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "F.L.S. FILE LOAD"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "<"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.byte 0x3d
	.byte 0x01
	.byte 0x3e
	.byte 0x01
	.byte 0x3b
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.asciz " "
	.ascii "7"
	.byte 0x01
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x3c
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz "$"
	.ascii "1"
	.byte 0x01
	.asciz "6"
	.byte 0xf2  ; "ò"
	.byte 0x10
	.asciz "*"
	.zero 6
	.asciz "LOAD"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x3e
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x18, 0x11
	.asciz "*"
	.zero 6
	.asciz "EDIT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "A"
	.byte 0x01
	.byte 0x3e
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "B"
	.byte 0x01
	.byte 0x40
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0xdc  ; "Ü"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "C"
	.byte 0x01
	.byte 0x41
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "D"
	.byte 0x01
	.byte 0x42
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "P"
	.ascii "?"
	.byte 0x01
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xc2, 0x9a  ; "Â"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xc6, 0x9a  ; "Æ"
	.asciz "#"
	.zero 4
	.byte 0xc8, 0x9a  ; "È"
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "E"
	.byte 0x01
	.byte 0x43
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ":"
	.ascii "?"
	.byte 0x01
	.asciz "K"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0x0a
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xca, 0x9a  ; "Ê"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xce, 0x9a  ; "Î"
	.asciz "#"
	.zero 4
	.byte 0xd0, 0x9a  ; "Ð"
	.asciz "#"
	.zero 4
	.ascii "j"
	normal
	push xde
	normal
	.byte 0x46, 0x01
	popw wa
	normal
	ld	xix, 134219777
	nop
	.asciz " "
	.byte 0xc5  ; "Å"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "1"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xd2, 0x9a  ; "Ò"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xd6, 0x9a  ; "Ö"
	.asciz "#"
	.zero 4
	.byte 0xd8, 0x9a  ; "Ø"
	.asciz "#"
	.zero 2
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x45
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "G"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xc5  ; "Å"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.byte 0xd6  ; "Ö"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "1"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "r"
	.byte 0x12
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.asciz "AS"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x45
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "F"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.byte 0xe8  ; "è"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "1"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x12
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.asciz "AL"
	.zero 3
	.ascii "j"
	normal
	push xde
	normal
	popw bc
	normal
	popw hl
	normal
	ld	xiy, 134219777
	nop
	.asciz "4"
	.byte 0xe8  ; "è"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	swi	7
	nop
	ei	0
	popw de
	normal
	.byte 0xda, 0x9a
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0xde, 0x9a  ; "Þ"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xe0, 0x9a  ; "à"
	.asciz "#"
	.zero 2
	.asciz "."
	.ascii "`"
	normal
	popw wa
	normal
	.fill 2, 1, 0xff
	.ascii "J"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xc5  ; "Å"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "4"
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	normal
	popw wa
	normal
	.fill 4, 1, 0xff
	.ascii "I"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "4"
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "L"
	normal
	popw wa
	normal
	push_f
	nop
	.ascii " "
	.byte 0x01
	.zero 2
	.ascii "?"
	.byte 0x01, 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "3"
	.ascii "*"
	.byte 0x01
	.asciz "\""
	.ascii "`"
	normal
	push xde
	normal
	popw iy
	normal
	.fill 2, 1, 0xff
	.ascii "K"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.fill 2, 1, 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "+"
	.ascii "`"
	normal
	popw ix
	normal
	.fill 6, 1, 0xff
	ldio	0, 2
	normal
	.byte 0xdd, 0x00
	pushw iy
	normal
	.byte 0xef, 0x00
	.ascii "t"
	.byte 0x13
	.asciz "*"
	.zero 4
	.byte 0xf9  ; "ù"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "PANIC"
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "O"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xe2, 0x9a  ; "â"
	.asciz "#"
	.byte 0xa4  ; "¤"
	.byte 0x13
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "F.L.S. DIR SELECT"
	.asciz "I"
	.ascii "`"
	normal
	popw iz
	normal
	.fill 2, 1, 0xff
	.ascii "P"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	nop
	.byte 0x1f
	nop
	push xde
	normal
	jrl	nc, 7936
	nop
	jr	f, 1
	popw iz
	normal
	.fill 2, 1, 0xff
	.ascii "Q"
	.byte 0x01
	.byte 0x4f
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x0d, 0x01, 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.zero 3
	.ascii "j"
	normal
	popw iz
	normal
	.fill 2, 1, 0xff
	.ascii "R"
	.byte 0x01
	.byte 0x50
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "#"
	.byte 0x07, 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	swi	7
	nop
	.byte 0x08, 0x00
	popw de
	normal
	.byte 0xe6, 0x9a
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0xea, 0x9a  ; "ê"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xec, 0x9a  ; "ì"
	.asciz "#"
	.zero 2
	.asciz ">"
	.ascii "`"
	normal
	popw iz
	normal
	.fill 2, 1, 0xff
	.ascii "S"
	.byte 0x01
	.byte 0x51
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xde  ; "Þ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 7
	.ascii "`"
	.byte 0x14
	.asciz "*"
	.asciz "01-24"
	.asciz ">"
	.ascii "`"
	normal
	popw iz
	normal
	.fill 2, 1, 0xff
	.ascii "T"
	.byte 0x01
	.byte 0x52
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.byte 0xde  ; "Þ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "P"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0x92  ; ""
	.byte 0x14
	.asciz "*"
	.asciz "25-48"
	.asciz "\""
	.ascii "`"
	normal
	popw iz
	normal
	.fill 2, 1, 0xff
	.ascii "U"
	.byte 0x01
	.byte 0x53
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ">"
	.ascii "`"
	normal
	popw iz
	normal
	.fill 2, 1, 0xff
	.ascii "V"
	.byte 0x01
	.byte 0x54
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0xee  ; "î"
	.byte 0x14
	.asciz "*"
	.asciz "49-72"
	.asciz ">"
	.ascii "`"
	normal
	popw iz
	normal
	.fill 2, 1, 0xff
	.ascii "W"
	.byte 0x01
	.byte 0x55
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x15, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii " "
	.byte 0x15
	.asciz "*"
	.asciz "73-96"
	.asciz ">"
	.ascii "`"
	normal
	popw iz
	normal
	.fill 2, 1, 0xff
	.ascii "X"
	.byte 0x01
	.byte 0x56
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x3e
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "R"
	.byte 0x15
	.asciz "*"
	.asciz "97-120"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ")"
	.ascii "`"
	normal
	popw iz
	normal
	.fill 4, 1, 0xff
	.ascii "W"
	.byte 0x01, 0x18
	.byte 0x00
	.byte 0x1c
	.zero 3
	.asciz ";"
	.byte 0x1f
	nop
	.byte 0x08, 0x00
	popw de
	normal
	ei	0
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "Z"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xee, 0x9a  ; "î"
	.asciz "#"
	.byte 0x9e  ; ""
	.byte 0x15
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "F.L.S. FILE SELECT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "I"
	.ascii "`"
	normal
	pop xbc
	normal
	.fill 2, 1, 0xff
	.ascii "["
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	nop
	.byte 0x1f
	nop
	popw iz
	normal
	.byte 0x7f
	.zero 3
	.ascii "j"
	normal
	pop xbc
	normal
	.fill 2, 1, 0xff
	.ascii "\\"
	normal
	pop xde
	normal
	.byte 0x08, 0x00
	.asciz ","
	.asciz " "
	.byte 0xeb  ; "ë"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "/"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xf2, 0x9a  ; "ò"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xf6, 0x9a  ; "ö"
	.asciz "#"
	.zero 4
	.byte 0xf8, 0x9a  ; "ø"
	.asciz "#"
	.zero 4
	.ascii "j"
	normal
	pop xbc
	normal
	.fill 2, 1, 0xff
	.ascii "]"
	normal
	pop xhl
	normal
	.byte 0x08, 0x00
	.asciz ","
	.asciz "0"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	swi	7
	nop
	push 0
	popw de
	normal
	swi	2
	.byte 0x9a
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0xfe, 0x9a  ; "þ"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.zero 2
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 2
	.asciz "\""
	.ascii "`"
	normal
	pop xbc
	normal
	.fill 2, 1, 0xff
	.ascii "^"
	normal
	pop xix
	normal
	.byte 0x08, 0x00
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	push	sr
	nop
	max
	nop
	pop	sr
	nop
	.byte 0x1f
	nop
	jr	f, 1
	pop xbc
	normal
	.fill 2, 1, 0xff
	.ascii "_"
	normal
	pop xiy
	normal
	.byte 0x08, 0x00
	.asciz ","
	.byte 0xdc  ; "Ü"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	normal
	nop
	retd	7936
	nop
	jr	f, 1
	pop xbc
	normal
	.fill 2, 1, 0xff
	.ascii "`"
	normal
	pop xiz
	normal
	ldio	0, 204
	nop
	.byte 0xdc, 0x00, 0xeb, 0x00, 0xed, 0x00
	reti
	nop
	.byte 0xc9, 0x00
	normal
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.zero 3
	.ascii "j"
	normal
	pop xbc
	normal
	.fill 2, 1, 0xff
	.ascii "a"
	normal
	pop xsp
	normal
	ldio	0, 236
	nop
	.asciz "D"
	.ascii "?"
	.byte 0x01
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01, 0x02
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0x06
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 4
	.byte 0x08
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 2
	.byte 0x1f
	nop
	jr	f, 1
	pop xbc
	normal
	.ascii "b"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "`"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x02, 0x01, 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.ascii "a"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x03, 0x01
	.asciz "#"
	.ascii "6"
	.byte 0x01
	.asciz "5"
	.ascii "B"
	.byte 0x17
	.asciz "*"
	.zero 6
	.asciz "SELECT"
	.byte 0x00
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "d"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x0a
	.byte 0x9b  ; ""
	.asciz "#"
	.ascii "t"
	.byte 0x17
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "F.L.S. EDIT"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "e"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x3a
	.byte 0x01, 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "f"
	.byte 0x01
	.ascii "d"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.zero 3
	.ascii "j"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.ascii "g"
	.byte 0x01
	.ascii "i"
	.byte 0x01
	.ascii "e"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.byte 0xc5  ; "Å"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "1"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.byte 0x03
	.zero 7
	.ascii "@"
	.byte 0x01, 0x0e
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x12
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 4
	.byte 0x14
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 2
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.ascii "f"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "h"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.byte 0xd6  ; "Ö"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "1"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x26
	.byte 0x18
	.asciz "*"
	.byte 0x03
	.zero 7
	.asciz "AS"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.ascii "f"
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "g"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd7  ; "×"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.byte 0xe8  ; "è"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "1"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x50
	.byte 0x18
	.asciz "*"
	.byte 0x03
	.zero 7
	.asciz "AL"
	.zero 3
	.ascii "j"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.ascii "j"
	.byte 0x01
	.ascii "l"
	.byte 0x01
	.ascii "f"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "4"
	.byte 0xe8  ; "è"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 5
	reti
	nop
	popw de
	normal
	ex_ff
	.byte 0x9b
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0x1a
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1c
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 2
	.asciz "."
	.ascii "`"
	.byte 0x01
	.ascii "i"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "k"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "4"
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.zero 2
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01
	.ascii "i"
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "j"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xc5  ; "Å"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "4"
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.ascii "m"
	.byte 0x01
	.ascii "n"
	.byte 0x01
	.ascii "i"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.ascii "l"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x01, 0x01
	.asciz "#"
	.ascii "4"
	.byte 0x01
	.asciz "5"
	.byte 0x0c, 0x19
	.asciz "*"
	.zero 6
	.asciz "SEARCH"
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.ascii "o"
	.byte 0x01
	.ascii "q"
	.byte 0x01
	.ascii "l"
	.byte 0x01, 0x08
	.zero 2
	.byte 0x01
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.byte 0xd9  ; "Ù"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x0c
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.ascii "n"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "p"
	.byte 0x01
	.fill 2, 1, 0xff
	ldio	0, 12
	normal
	.byte 0xc3, 0x00, 0x27
	normal
	.byte 0xcd, 0x00
	pop xix
	pop_f
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SAVE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.ascii "n"
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "o"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x82  ; ""
	.byte 0x19
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "F.L.S."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "r"
	.byte 0x01
	.ascii "n"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xde  ; "Þ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "#"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 7
	.byte 0xb6  ; "¶"
	.byte 0x19
	.asciz "*"
	.asciz "DEL1"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "s"
	.byte 0x01
	.ascii "q"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0xde  ; "Þ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "L"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.zero 3
	.byte 0xe8  ; "è"
	.byte 0x19
	.asciz "*"
	.asciz "DEL2"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "t"
	.byte 0x01
	.ascii "r"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x05
	.zero 3
	.byte 0x1a, 0x1a
	.asciz "*"
	.asciz "INS"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "u"
	.byte 0x01
	.ascii "s"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x06
	.zero 3
	.ascii "J"
	.byte 0x1a
	.asciz "*"
	.asciz "A.S."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "v"
	.byte 0x01
	.ascii "t"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "|"
	.byte 0x1a
	.asciz "*"
	.asciz "A.L."
	.zero 3
	.ascii "j"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "w"
	.byte 0x01
	.ascii "u"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ":"
	.ascii "?"
	.byte 0x01
	.asciz "K"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xf2  ; "ò"
	.byte 0x00
	.zero 2
	.ascii "@"
	.byte 0x01, 0x1e
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x22
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 4
	.ascii "$"
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "x"
	.byte 0x01
	.ascii "v"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "N"
	.ascii "?"
	.byte 0x01
	.byte 0xbc  ; "¼"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0x26
	.byte 0x9b  ; ""
	.asciz "#"
	normal
	nop
	push 0
	pushw de
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 4
	.ascii ","
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 2
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "y"
	.byte 0x01
	.ascii "w"
	.byte 0x01, 0x18
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	nop
	reti
	nop
	popw de
	normal
	.asciz "."
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "z"
	.byte 0x01
	.ascii "x"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.byte 0xd6  ; "Ö"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.zero 2
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "y"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xc5  ; "Å"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.byte 0xc5  ; "Å"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "|"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	pushw iz
	.byte 0x9b  ; ""
	.asciz "#"
	.ascii "r"
	.byte 0x1b
	.asciz "*"
	.asciz "s"
	.zero 2
	.asciz "EDIT DIRECTORY NAME"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x7b
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "}"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "M"
	.ascii "`"
	.byte 0x01
	.byte 0x7b
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "~"
	.byte 0x01
	.byte 0x7c
	.byte 0x01, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "?"
	pop_f
	nop
	pushw de
	normal
	.asciz " "
	.ascii "`"
	.byte 0x01
	.byte 0x7b
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x7f, 0x01
	.byte 0x7d
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	pushw 1536
	nop
	pop_f
	nop
	pushw de
	normal
	.asciz " "
	.ascii "`"
	.byte 0x01
	.byte 0x7b
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x80  ; ""
	.byte 0x01
	.byte 0x7e
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "v"
	.asciz "&"
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8a  ; ""
	.byte 0x00
	.zero 2
	pop_f
	nop
	pushw de
	normal
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x7b
	.byte 0x01
	.fill 4, 1, 0xff
	jrl	nc, 0x0801
	nop
	push 0
	.asciz "w"
	.asciz "$"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x32
	.byte 0x1c
	.asciz "*"
	.zero 4
	.byte 0xf9  ; "ù"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LST"
	.asciz "K"
	.ascii "`"
	.byte 0x01
	.fill 8, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.ascii "2"
	.byte 0x9b  ; ""
	.asciz "#"
	.ascii "6"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x83  ; ""
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x3a
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x84  ; ""
	.byte 0x1c
	.asciz "*"
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "SAVE OPTION"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x84  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "N"
	.byte 0x7f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x85  ; ""
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "#"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 11
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x86  ; ""
	.byte 0x01
	.byte 0x84  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x87  ; ""
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T"
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "s"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x88  ; ""
	.byte 0x01
	.byte 0x86  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "|"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x03
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x89  ; ""
	.byte 0x01
	.byte 0x87  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x05
	.zero 9
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8a  ; ""
	.byte 0x01
	.byte 0x88  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x06
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8b  ; ""
	.byte 0x01
	.byte 0x89  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x07
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8c  ; ""
	.byte 0x01
	.byte 0x8a  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x08
	.zero 9
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8d  ; ""
	.byte 0x01
	.byte 0x8b  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x0a, 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "PNL"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8e  ; ""
	.byte 0x01
	.byte 0x8c  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "*"
	.byte 0xca  ; "Ê"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	pushw iz
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "P.MEM"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8f  ; ""
	.byte 0x01
	.byte 0x8d  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "X"
	.byte 0xca  ; "Ê"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "m"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x54
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SEQ"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x90  ; ""
	.byte 0x01
	.byte 0x8e  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "~"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "x"
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "COMP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x91  ; ""
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x9e  ; ""
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SOUND"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x92  ; ""
	.byte 0x01
	.byte 0x90  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xc4  ; "Ä"
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MSP"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x93  ; ""
	.byte 0x01
	.byte 0x91  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x16, 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xe8  ; "è"
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "CUSTOM"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x94  ; ""
	.byte 0x01
	.byte 0x92  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x10, 0x1f
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MIDI"
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x95  ; ""
	.byte 0x01
	.byte 0x93  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz "j"
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "y"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.byte 0x50
	.byte 0x1f
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii ">"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x0b
	.byte 0x00
	pushw de
	normal
	.byte 0x40, 0x9b
	.asciz "#"
	.asciz "COMPOSER               "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x96  ; ""
	.byte 0x01
	.byte 0x94  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0x1f
	.byte 0x00
	.byte 0x03, 0x01
	.asciz "8"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa2  ; "¢"
	.byte 0x1f
	.asciz "*"
	.byte 0x05
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "D"
	.byte 0x9b  ; ""
	.asciz "#"
	ei	0
	pushw de
	normal
	.byte 0x46, 0x9b
	.asciz "#"
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x97  ; ""
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz "="
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "L"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x1f
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "J"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x08
	.byte 0x00
	pushw de
	normal
	popw ix
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "CURRENT PANEL          "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x98  ; ""
	.byte 0x01
	.byte 0x96  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz "L"
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "["
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0 *"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "P"
	.byte 0x9b  ; ""
	.asciz "#"
	push 0
	pushw de
	normal
	.byte 0x52, 0x9b
	.asciz "#"
	.asciz "PANEL MEMORY           "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x97  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz "["
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "j"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x03
	.byte 0x00
	.byte 0x82  ; ""
	.asciz " *"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "V"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x0a
	.byte 0x00
	pushw de
	normal
	pop xwa
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "SEQUENCER              "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9a  ; ""
	.byte 0x01
	.byte 0x98  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz "y"
	.byte 0xff
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x05
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.asciz " *"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "\\"
	.byte 0x9b  ; ""
	.asciz "#"
	incf
	nop
	pushw de
	normal
	pop xiz
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "SOUND MEMORY           "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9b  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&!*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "b"
	.byte 0x9b  ; ""
	.asciz "#"
	decf
	nop
	pushw de
	normal
	.ascii "d"
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "MSP                    "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9c  ; ""
	.byte 0x01
	.byte 0x9a  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x07
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "x!*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "h"
	.byte 0x9b  ; ""
	.asciz "#"
	ret
	nop
	pushw de
	normal
	.ascii "j"
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "RHYTHM CUSTOM          "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9d  ; ""
	.byte 0x01
	.byte 0x9b  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x08
	.byte 0x00
	.byte 0xca  ; "Ê"
	.asciz "!*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "n"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x0f
	.byte 0x00
	pushw de
	normal
	.ascii "p"
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "USER MIDI SETTINGS     "
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9e  ; ""
	.byte 0x01
	.byte 0x9c  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9f  ; ""
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz ":"
	.byte 0x03, 0x01
	.asciz ":"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x9e  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x03, 0x01
	.asciz ":"
	.byte 0x03, 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xa1  ; "¡"
	.byte 0x01
	.byte 0x9f  ; ""
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz ":"
	.asciz "("
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xa2  ; "¢"
	.byte 0x01
	.byte 0xa0  ; " "
	.byte 0x01, 0x18
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	nop
	.byte 0x1b, 0x00
	pushw de
	normal
	.byte 0x1f
	nop
	jr	f, 1
	.byte 0x82, 0x01, 0xa3, 0x01, 0xa4, 0x01, 0xa1, 0x01
	ldio	0, 13
	normal
	.byte 0x1e, 0x00, 0x37
	normal
	.asciz "7"
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xa2  ; "¢"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x10, 0x01
	.asciz "#"
	.ascii "3"
	.byte 0x01
	.asciz "5"
	.byte 0xac  ; "¬"
	.asciz "\"*"
	.zero 6
	.asciz "SAVE"
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.byte 0xa5  ; "¥"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x01
	.byte 0xa2  ; "¢"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x07, 0x01
	.asciz "L"
	.ascii "7"
	.byte 0x01
	.asciz "]"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x09
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xa4  ; "¤"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "P"
	.ascii "6"
	.byte 0x01
	.asciz "Z"
	.byte 0xfa  ; "ú"
	.asciz "\"*"
	.byte 0x03
	.zero 5
	.asciz "PERFORM"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.byte 0xa7  ; "§"
	.byte 0x01
	.byte 0xa8  ; "¨"
	.byte 0x01
	.byte 0xa4  ; "¤"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x07, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0b
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.byte 0xae  ; "®"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "J#*"
	.byte 0x03
	.zero 5
	.asciz "ALL OFF"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.byte 0xa9  ; "©"
	.byte 0x01
	.byte 0xaa  ; "ª"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x07, 0x01
	.asciz "v"
	.ascii "7"
	.byte 0x01
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0a
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xa8  ; "¨"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "z"
	.ascii "0"
	.byte 0x01
	.byte 0x84  ; ""
	.byte 0x00
	.byte 0x9a  ; ""
	.asciz "#*"
	.byte 0x03
	.zero 5
	.asciz "BACKUP"
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xab  ; "«"
	.byte 0x01
	.byte 0xa8  ; "¨"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0xc4  ; "Ä"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x09
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.asciz "#*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "t"
	.byte 0x9b  ; ""
	.asciz "#"
	rcf
	nop
	pushw de
	normal
	.ascii "v"
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "TECHNICS LYRICS        "
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xac  ; "¬"
	.byte 0x01
	.byte 0xaa  ; "ª"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9e  ; ""
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x09
	.zero 9
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xad  ; "­"
	.byte 0x01
	.byte 0xab  ; "«"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x93  ; ""
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.byte 0x9d  ; ""
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "<$*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LYRIC"
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0xac  ; "¬"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd1  ; "Ñ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ":"
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xaf  ; "¯"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz "l"
	.byte 0x13, 0x01
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.ascii "z"
	.byte 0x9b  ; ""
	.asciz "#"
	.ascii "~"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.byte 0xb0  ; "°"
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "L"
	.asciz "&"
	.asciz "]"
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x07
	.zero 9
	.byte 0x89  ; ""
	.byte 0x00
	.zero 2
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "M"
	.asciz "$"
	.asciz "_"
	.byte 0xc8  ; "È"
	.asciz "$*"
	.zero 6
	.asciz "DEL"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.byte 0xb2  ; "²"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.asciz "&"
	.asciz "3"
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x06
	.zero 9
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "#"
	.asciz "$"
	.asciz "5"
	.byte 0x14
	.asciz "%*"
	.zero 6
	.asciz "INS"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.byte 0xb4  ; "´"
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.asciz "\""
	.ascii "7"
	.byte 0x01
	.asciz "3"
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x09
	.zero 9
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a, 0x01
	.asciz "#"
	.ascii "5"
	.byte 0x01
	.asciz "5"
	.asciz "`%*"
	.zero 6
	.asciz "CLR"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.byte 0xb6  ; "¶"
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.asciz "L"
	.ascii "7"
	.byte 0x01
	.asciz "]"
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x08
	.zero 9
	.byte 0x09
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a, 0x01
	.asciz "M"
	.ascii "5"
	.byte 0x01
	.asciz "_"
	.byte 0xac  ; "¬"
	.asciz "%*"
	.zero 6
	.asciz "~8d ~8b"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xb8  ; "¸"
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "#"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 11
	.byte 0x0f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xb9  ; "¹"
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xba  ; "º"
	.byte 0x01
	.byte 0xb8  ; "¸"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0xc9  ; "É"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "I"
	.byte 0xdb  ; "Û"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "$&*"
	.zero 4
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "POSITION"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "L"
	.ascii "`"
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xbb  ; "»"
	.byte 0x01
	.byte 0xb9  ; "¹"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz "H"
	.byte 0x13, 0x01
	.asciz "g"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 4
	.byte 0xff
	.zero 3
	adc	(xde), c
	.asciz "#"
	.asciz "ABC"
	.asciz "ABC"
	.asciz "abc"
	.asciz "abc"
	.asciz "!#$"
	.asciz "!#$"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xbf  ; "¿"
	.byte 0x01
	.byte 0xbd  ; "½"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc0  ; "À"
	.byte 0x01
	.byte 0xbe  ; "¾"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x0e
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc1  ; "Á"
	.byte 0x01
	.byte 0xbf  ; "¿"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x05
	.zero 9
	.byte 0x07
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0xc0  ; "À"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc3  ; "Ã"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x8a, 0x9b  ; ""
	.asciz "#"
	.asciz "4'*"
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "HD FILE DELETE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc4  ; "Ä"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc5  ; "Å"
	.byte 0x01
	.byte 0xc3  ; "Ã"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "~'*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "PNL"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc6  ; "Æ"
	.byte 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "*"
	.byte 0xca  ; "Ê"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.asciz "'*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "P.MEM"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc7  ; "Ç"
	.byte 0x01
	.byte 0xc5  ; "Å"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "X"
	.byte 0xca  ; "Ê"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "m"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xc8  ; "È"
	.asciz "'*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SEQ"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc8  ; "È"
	.byte 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "~"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xec  ; "ì"
	.asciz "'*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "COMP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc9  ; "É"
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x12
	.asciz "(*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SOUND"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xca  ; "Ê"
	.byte 0x01
	.byte 0xc8  ; "È"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "8(*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MSP"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xcb  ; "Ë"
	.byte 0x01
	.byte 0xc9  ; "É"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x16, 0x01
	.byte 0xd4  ; "Ô"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\\(*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "CUSTOM"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xcc  ; "Ì"
	.byte 0x01
	.byte 0xca  ; "Ê"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x84  ; ""
	.asciz "(*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MIDI"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xcd  ; "Í"
	.byte 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.asciz ";"
	.asciz "+"
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xce  ; "Î"
	.byte 0x01
	.byte 0xcc  ; "Ì"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.asciz ":"
	.byte 0xfa  ; "ú"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ":"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xcf  ; "Ï"
	.byte 0x01
	.byte 0xcd  ; "Í"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xfa  ; "ú"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd0  ; "Ð"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.asciz ";"
	.byte 0x01, 0x01
	.asciz "J"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0x12
	.asciz ")*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x8e, 0x9b  ; ""
	.asciz "#"
	.byte 0x1e
	.byte 0x00
	pushw de
	normal
	adc	(xwa), hl
	.asciz "#"
	.asciz "CURRENT PANEL     "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd1  ; "Ñ"
	.byte 0x01
	.byte 0xcf  ; "Ï"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.asciz "L"
	.byte 0x01, 0x01
	.asciz "["
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "`)*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	adc	(xix), hl
	.asciz "#"
	.byte 0x1f
	nop
	pushw de
	normal
	adc	(xiz), hl
	.asciz "#"
	.asciz "PANEL MEMORY      "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd2  ; "Ò"
	.byte 0x01
	.byte 0xd0  ; "Ð"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.asciz "["
	.byte 0x01, 0x01
	.asciz "j"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x03
	.byte 0x00
	.byte 0xae  ; "®"
	.asciz ")*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x9a, 0x9b  ; ""
	.asciz "#"
	.asciz " "
	.ascii "*"
	.byte 0x01
	.byte 0x9c, 0x9b  ; ""
	.asciz "#"
	.asciz "SEQUENCER         "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd3  ; "Ó"
	.byte 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.asciz "j"
	.byte 0x01, 0x01
	.asciz "y"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.byte 0xfc  ; "ü"
	.asciz ")*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	adc	(xwa), xhl
	.asciz "#"
	.asciz "!"
	.ascii "*"
	normal
	adc	(xde), xhl
	.asciz "#"
	.asciz "COMPOSER          "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd4  ; "Ô"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.asciz "y"
	.byte 0x01, 0x01
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x05
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "J**"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	adc	(xiz), xhl
	.asciz "#"
	.asciz "\""
	.ascii "*"
	.byte 0x01
	.byte 0xa8, 0x9b  ; "¨"
	.asciz "#"
	.asciz "SOUND MEMORY      "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd5  ; "Õ"
	.byte 0x01
	.byte 0xd3  ; "Ó"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0x01, 0x01
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x06
	.byte 0x00
	.byte 0x98  ; ""
	.asciz "**"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xac, 0x9b  ; "¬"
	.asciz "#"
	.asciz "#"
	.ascii "*"
	.byte 0x01
	.byte 0xae, 0x9b  ; "®"
	.asciz "#"
	.asciz "MSP               "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd6  ; "Ö"
	.byte 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0x01, 0x01
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x07
	.byte 0x00
	.byte 0xe6  ; "æ"
	.asciz "**"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	ldcfm	3, (xde)
	.asciz "#"
	.asciz "$"
	.ascii "*"
	normal
	ldcfm	3, (xix)
	.asciz "#"
	.asciz "RHYTHM CUSTOM     "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd7  ; "×"
	.byte 0x01
	.byte 0xd5  ; "Õ"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0x01, 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "4+*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xb8, 0x9b  ; "¸"
	.asciz "#"
	.asciz "%"
	.ascii "*"
	.byte 0x01
	.byte 0xba, 0x9b  ; "º"
	.asciz "#"
	.asciz "USER MIDI SETTINGS"
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd8  ; "Ø"
	.byte 0x01
	.byte 0xd6  ; "Ö"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "#"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 11
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd9  ; "Ù"
	.byte 0x01
	.byte 0xd7  ; "×"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xda  ; "Ú"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T"
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "s"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xdb  ; "Û"
	.byte 0x01
	.byte 0xd9  ; "Ù"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "|"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x03
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xdc  ; "Ü"
	.byte 0x01
	.byte 0xda  ; "Ú"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x05
	.zero 9
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xdd  ; "Ý"
	.byte 0x01
	.byte 0xdb  ; "Û"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x06
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xde  ; "Þ"
	.byte 0x01
	.byte 0xdc  ; "Ü"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x07
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xdf  ; "ß"
	.byte 0x01
	.byte 0xdd  ; "Ý"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x08
	.zero 9
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xe0  ; "à"
	.byte 0x01
	.byte 0xde  ; "Þ"
	.byte 0x01, 0x18
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	nop
	.byte 0x1c, 0x00
	pushw de
	normal
	.byte 0x1f
	nop
	jr	f, 1
	orda8_24	b, 123137
	normal
	.byte 0xdf, 0x01
	ldio	0, 13
	normal
	.byte 0x1e, 0x00, 0x37
	normal
	.asciz "7"
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xe0  ; "à"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x14, 0x01
	.asciz "#"
	.ascii "/"
	.byte 0x01
	.asciz "5"
	.byte 0xea  ; "ê"
	.asciz ",*"
	.zero 6
	.asciz "DEL"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.byte 0xe3  ; "ã"
	.byte 0x01
	.byte 0xe4  ; "ä"
	.byte 0x01
	.byte 0xe0  ; "à"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xfd  ; "ý"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "v"
	.ascii "7"
	.byte 0x01
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0a
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xfd  ; "ý"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "w"
	.ascii "8"
	.byte 0x01
	.byte 0x89  ; ""
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "6-*"
	.zero 6
	.asciz "ALL DEL"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.byte 0xe5  ; "å"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xfd  ; "ý"
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0b
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xe4  ; "ä"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xfd  ; "ý"
	.byte 0x00
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0x38
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0x86  ; ""
	.asciz "-*"
	.zero 6
	.asciz "ALL OFF"
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xe7  ; "ç"
	.byte 0x01
	.byte 0xe4  ; "ä"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "*"
	.asciz " "
	.byte 0xfc  ; "ü"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "9"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc8  ; "È"
	.asciz "-*"
	.byte 0x05
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xbe, 0x9b  ; "¾"
	.asciz "#"
	.byte 0x1d
	.byte 0x00
	pushw de
	normal
	.byte 0xc0, 0x9b
	.asciz "#"
	.zero 2
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xe8  ; "è"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9e  ; ""
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x09
	.zero 9
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xe9  ; "é"
	.byte 0x01
	.byte 0xe7  ; "ç"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x93  ; ""
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0x12
	.asciz ".*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LYRIC"
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xea  ; "ê"
	.byte 0x01
	.byte 0xe8  ; "è"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0x01, 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "R.*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xc4, 0x9b  ; "Ä"
	.asciz "#"
	.asciz "&"
	.ascii "*"
	.byte 0x01
	.byte 0xc6, 0x9b  ; "Æ"
	.asciz "#"
	.asciz "TECHNICS LYRICS   "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xeb  ; "ë"
	.byte 0x01
	.byte 0xe9  ; "é"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcd  ; "Í"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ";"
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0xea  ; "ê"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xfa  ; "ú"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ";"
	.byte 0xfa  ; "ú"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "3"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xed  ; "í"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xca, 0x9b  ; "Ê"
	.asciz "#"
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.byte 0xec  ; "ì"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a, 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0x34
	.byte 0x01
	.byte 0xdf  ; "ß"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.ascii "*"
	.byte 0x01, 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 8, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xce, 0x9b  ; "Î"
	.asciz "#"
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf0  ; "ð"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xd2, 0x9b  ; "Ò"
	.asciz "#"
	.asciz "\"/*"
	.zero 6
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x01
	.byte 0xf1  ; "ñ"
	.byte 0x01
	.byte 0xf2  ; "ò"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.asciz "R/*"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x01
	.byte 0xf3  ; "ó"
	.byte 0x01
	.byte 0xf4  ; "ô"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xac  ; "¬"
	.asciz "/*"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xf2  ; "ò"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf5  ; "õ"
	.byte 0x01
	.byte 0xf2  ; "ò"
	.byte 0x01, 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "4"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x01
	.byte 0xf6  ; "ö"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf4  ; "ô"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "L"
	.byte 0x17, 0x01
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x04
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xf5  ; "õ"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf7  ; "÷"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xf5  ; "õ"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0xf6  ; "ö"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz "l"
	.byte 0x13, 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf9  ; "ù"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x25
	.byte 0x01
	.asciz "Q"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0xd6, 0x9b  ; "Ö"
	.asciz "#"
	.byte 0xda, 0x9b  ; "Ú"
	.asciz "#"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xf8  ; "ø"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xfa  ; "ú"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1e
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.ascii "!"
	.byte 0x01
	.asciz "2"
	.byte 0xb4  ; "´"
	.asciz "0*"
	.zero 6
	.asciz "DELETE DIRECTORY FROM HARD DISK:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xf8  ; "ø"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0xf9  ; "ù"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1e
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "6"
	.byte 0x11, 0x01
	.asciz "H"
	.byte 0xf6  ; "ö"
	.asciz "0*"
	.byte 0x02
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "PLEASE WAIT ..."
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xfc  ; "ü"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xde, 0x9b  ; "Þ"
	.asciz "#"
	.asciz "01*"
	.zero 6
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xfd  ; "ý"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.asciz "`1*"
	.zero 2
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xfe  ; "þ"
	.byte 0x01
	.byte 0xfc  ; "ü"
	.byte 0x01, 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "5"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.fill 3, 1, 0xff
	.byte 0x01
	.byte 0xfd  ; "ý"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xaa  ; "ª"
	.asciz "1*"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.byte 0x00
	.byte 0x02, 0x02, 0x02
	.byte 0xfe  ; "þ"
	.byte 0x01, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "L"
	.byte 0x17, 0x01
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x04
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xff
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x01, 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xff
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x00
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz "l"
	.byte 0x13, 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x03, 0x02
	.byte 0xff
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x02, 0x02, 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x05, 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xe2, 0x9b  ; "â"
	.asciz "#"
	.byte 0xa8  ; "¨"
	.asciz "2*"
	.zero 6
	.asciz "R"
	.ascii "`"
	.byte 0x01, 0x04, 0x02
	.fill 2, 1, 0xff
	.byte 0x06, 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ";"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01, 0x04, 0x02, 0x07, 0x02, 0x08, 0x02, 0x05, 0x02, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.byte 0xf2  ; "ò"
	.asciz "2*"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x06, 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01, 0x04, 0x02, 0x09, 0x02, 0x0a, 0x02, 0x06, 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "L3*"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x08, 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x04, 0x02, 0x0b, 0x02
	.fill 2, 1, 0xff
	.byte 0x08, 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "L"
	.byte 0x17, 0x01
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x04
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x0a, 0x02
	.fill 2, 1, 0xff
	.byte 0x0c, 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x0a, 0x02
	.fill 4, 1, 0xff
	pushw 0x0802
	nop
	.asciz ","
	.asciz "l"
	.byte 0x13, 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1c
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x0e, 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xe6, 0x9b  ; "æ"
	.asciz "#"
	.asciz " 4*"
	.zero 6
	.asciz "R"
	.ascii "`"
	.byte 0x01, 0x0d, 0x02
	.fill 2, 1, 0xff
	.byte 0x0f, 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ":"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01, 0x0d, 0x02, 0x10, 0x02, 0x11, 0x02, 0x0e, 0x02, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.asciz "j4*"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x0f, 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01, 0x0d, 0x02, 0x12, 0x02, 0x13, 0x02, 0x0f, 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xc4  ; "Ä"
	.asciz "4*"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x11, 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x0d, 0x02, 0x14, 0x02
	.fill 2, 1, 0xff
	.byte 0x11, 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz ","
	.byte 0x17, 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x05
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x13, 0x02
	.fill 2, 1, 0xff
	.byte 0x15, 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x13, 0x02
	.fill 2, 1, 0xff
	.byte 0x16, 0x02, 0x14, 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz "L"
	.byte 0x13, 0x01
	.asciz "{"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x13, 0x02
	.fill 4, 1, 0xff
	.byte 0x15, 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz "|"
	.byte 0x13, 0x01
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "="
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18, 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x25
	.byte 0x01
	.asciz "U"
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 2
	.byte 0xea, 0x9b  ; "ê"
	.asciz "#"
	.byte 0xee, 0x9b  ; "î"
	.asciz "#"
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x17, 0x02
	.fill 2, 1, 0xff
	.byte 0x19, 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "\""
	.byte 0x17, 0x01
	.asciz "9"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "8"
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x17, 0x02
	.fill 4, 1, 0xff
	.byte 0x18, 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "8"
	.ascii "#"
	.byte 0x01
	.asciz "O"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "1"
	.byte 0x02
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x1b, 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xf2, 0x9b  ; "ò"
	.asciz "#"
	.asciz ":6*"
	.zero 4
	.asciz "   HD FORMAT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "6"
	.ascii "`"
	.byte 0x01, 0x1a, 0x02, 0x1c, 0x02
	.ascii " "
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "$"
	.asciz "&"
	.byte 0x1b, 0x01
	.byte 0xd5  ; "Õ"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "p6*"
	.byte 0x02
	.zero 7
	.byte 0x05
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x1b, 0x02
	.fill 2, 1, 0xff
	.byte 0x1d, 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&"
	.asciz "F"
	.byte 0x19, 0x01
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x18
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x1b, 0x02
	.fill 2, 1, 0xff
	.byte 0x1e, 0x02, 0x1c, 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&"
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1a
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.zero 2
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x1b, 0x02
	.fill 2, 1, 0xff
	.byte 0x1f, 0x02, 0x1d, 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&"
	.asciz "h"
	.byte 0x19, 0x01
	.byte 0xa7  ; "§"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x19
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x04
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x1b, 0x02
	.fill 4, 1, 0xff
	calr	0x0802
	nop
	.asciz "&"
	.asciz "."
	.byte 0x19, 0x01
	.asciz "E"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "i"
	.ascii "`"
	.byte 0x01, 0x1a, 0x02
	.fill 2, 1, 0xff
	.ascii "!"
	.byte 0x02, 0x1b, 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "]"
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "w"
	.byte 0x1b
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01, 0x1a, 0x02
	.fill 2, 1, 0xff
	.ascii "\""
	.byte 0x02
	.ascii " "
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "b7*"
	.asciz "CANCEL"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "R"
	.ascii "`"
	.byte 0x01, 0x1a, 0x02
	.fill 4, 1, 0xff
	.ascii "!"
	.byte 0x02, 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "6"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "$"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x25
	.byte 0x01
	.byte 0xd5  ; "Õ"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 2
	.byte 0xf6, 0x9b  ; "ö"
	.asciz "#"
	.byte 0xfa, 0x9b  ; "ú"
	.asciz "#"
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x23
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "%"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "&"
	.byte 0x1f, 0x01
	.asciz "]"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "9"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x23
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "&"
	.byte 0x02
	.byte 0x24
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "b"
	.byte 0x1f, 0x01
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz ":"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x23
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "%"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.byte 0x9a  ; ""
	.byte 0x00
	.byte 0x23
	.byte 0x01
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "1"
	.byte 0x02
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "("
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xfe, 0x9b  ; "þ"
	.asciz "#"
	.asciz "P8*"
	.zero 6
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x27
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii ")"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x13
	.byte 0x00
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x27
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "*"
	push	sr
	pushw wa
	push	sr
	.byte 0x08, 0x00
	.asciz "d"
	.byte 0x0c
	.byte 0x00
	.byte 0xdb  ; "Û"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "3"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x92  ; ""
	.asciz "8*"
	.byte 0x04
	.zero 3
	.byte 0xff
	.zero 3
	.asciz "HD-INFO"
	.zero 2
	.ascii "j"
	normal
	ldb	l, 2
	pushw hl
	push	sr
	.fill 2, 1, 0xff
	.ascii ")"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "H"
	.ascii "<"
	.byte 0x01
	.byte 0xdd  ; "Ý"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01, 0x02
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x9c  ; ""
	.asciz "#"
	.zero 4
	.byte 0x08
	.byte 0x9c  ; ""
	.asciz "#"
	.zero 2
	.asciz "."
	.ascii "`"
	normal
	pushw de
	push	sr
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0x3c
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "-"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x0a
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x1a
	.asciz "9*"
	.byte 0x01
	.zero 3
	.asciz "DEBUG MEMO SCREEN"
	.asciz "I"
	.ascii "`"
	normal
	pushw ix
	push	sr
	.fill 2, 1, 0xff
	.ascii "."
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "F"
	.ascii "`"
	normal
	pushw ix
	push	sr
	.fill 4, 1, 0xff
	.ascii "-"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.ascii "4"
	.byte 0x01
	.byte 0xe5  ; "å"
	.byte 0x00
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "0"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x0e
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x86  ; ""
	.asciz "9*"
	.zero 6
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x2f
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "1"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "9"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x2f
	.byte 0x02
	.byte 0x32
	.byte 0x02
	.byte 0x35
	.byte 0x02
	.byte 0x30
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz ","
	.byte 0x17, 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x05
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x31
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "3"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0x9e  ; ""
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xcf  ; "Ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x31
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "4"
	.byte 0x02
	.byte 0x32
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz "L"
	.byte 0x13, 0x01
	.asciz "{"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x31
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "3"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz "|"
	.byte 0x13, 0x01
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "<"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0x2f
	.byte 0x02
	.byte 0x36
	.byte 0x02
	.byte 0x37
	.byte 0x02
	.byte 0x31
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.asciz "x:*"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x35
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0x2f
	.byte 0x02
	.byte 0x38
	.byte 0x02
	.byte 0x39
	.byte 0x02
	.byte 0x35
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.byte 0xd2  ; "Ò"
	.asciz ":*"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x37
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0x2f
	.byte 0x02
	.byte 0x3a
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "7"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz ",;*"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x39
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "<"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x12
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x82  ; ""
	.asciz ";*"
	.zero 6
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x3b
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "="
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	nop
	.byte 0x1f
	nop
	.byte 0x1a, 0x00
	pushw de
	normal
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0x3b
	.byte 0x02
	.byte 0x3e
	.byte 0x02
	.byte 0x3f
	.byte 0x02
	.byte 0x3c
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.byte 0xcc  ; "Ì"
	.asciz ";*"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x3d
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0x3b
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "@"
	.byte 0x02
	.byte 0x3d
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "&<*"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x3b
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "A"
	.byte 0x02
	.byte 0x3f
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x3b
	.byte 0x02
	.byte 0x42
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "@"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "4"
	.byte 0x17, 0x01
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x41
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "C"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "\\"
	.byte 0x17, 0x01
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "C"
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x41
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "B"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "E"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x16
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xfa  ; "ú"
	.asciz "<*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "EDIT FLS NAME"
	.asciz "M"
	.ascii "`"
	.byte 0x01
	.byte 0x44
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "F"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	nop
	.byte 0x1f
	nop
	push_f
	nop
	pushw de
	normal
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x44
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "G"
	.byte 0x02
	.byte 0x45
	.byte 0x02, 0x18
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "c"
	.byte 0x01, 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.ascii "`"
	.byte 0x01
	.byte 0x44
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "H"
	.byte 0x02
	.byte 0x46
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	pushw 1536
	nop
	ldf	0
	pushw de
	normal
	.asciz " "
	.ascii "`"
	normal
	.byte 0x44, 0x02
	popw bc
	push	sr
	.fill 2, 1, 0xff
	.ascii "G"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "v"
	.asciz "&"
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8a  ; ""
	.byte 0x00
	.zero 2
	ldf	0
	pushw de
	normal
	.asciz "+"
	.ascii "`"
	normal
	popw wa
	push	sr
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "w"
	.asciz "$"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0xb4  ; "´"
	.asciz "=*"
	.zero 4
	.byte 0xf9  ; "ù"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LST"
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "K"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x1a
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xe2  ; "â"
	.asciz "=*"
	.zero 6
	.asciz "R"
	.ascii "`"
	normal
	popw de
	push	sr
	.fill 2, 1, 0xff
	.ascii "L"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "7"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	normal
	popw de
	push	sr
	.fill 2, 1, 0xff
	.ascii "M"
	push	sr
	popw hl
	push	sr
	ldio	0, 244
	nop
	.byte 0xd8, 0x00
	push xhl
	normal
	.byte 0xee, 0x00
	reti
	nop
	.byte 0xc9, 0x00
	swi	7
	swi	7
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz ",>*"
	.zero 2
	.asciz "6"
	.ascii "`"
	normal
	popw de
	push	sr
	popw iz
	push	sr
	.byte 0x50
	push	sr
	popw ix
	push	sr
	.byte 0x08, 0x00
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xc9  ; "É"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "V>*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	normal
	popw iy
	push	sr
	.fill 2, 1, 0xff
	.ascii "O"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "*"
	.asciz "x"
	.byte 0x1d, 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1d
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	normal
	popw iy
	push	sr
	.fill 4, 1, 0xff
	.ascii "N"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1e
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	normal
	popw de
	push	sr
	.fill 2, 1, 0xff
	.ascii "Q"
	push	sr
	popw iy
	push	sr
	.byte 0x08, 0x00
	.asciz "("
	.asciz "^"
	.byte 0x17, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	normal
	popw de
	push	sr
	.fill 4, 1, 0xff
	.ascii "P"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "S"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x1e
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "*?*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x52
	.byte 0x02
	.byte 0x54
	.byte 0x02
	.byte 0x55
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T?*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x53
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&"
	.asciz "|"
	.byte 0x19, 0x01
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1f
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x52
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "V"
	.byte 0x02
	.byte 0x53
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x52
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "U"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "X"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x22
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xfe  ; "þ"
	.asciz "?*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x57
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "Y"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "(@*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x57
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "Z"
	push	sr
	pop xwa
	push	sr
	.byte 0x08, 0x00
	.asciz "("
	.asciz "z"
	.byte 0x17, 0x01
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz " "
	.zero 4
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x57
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "["
	push	sr
	pop xbc
	push	sr
	.byte 0x08, 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x57
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "Z"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "]"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x26
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xd2  ; "Ò"
	.asciz "@*"
	.zero 6
	.asciz "6"
	.ascii "`"
	normal
	pop xix
	push	sr
	.fill 2, 1, 0xff
	.ascii "^"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xfc  ; "ü"
	.asciz "@*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	normal
	pop xix
	push	sr
	.fill 2, 1, 0xff
	.ascii "_"
	push	sr
	pop xiy
	push	sr
	.byte 0x08, 0x00
	.asciz "("
	.asciz "z"
	.byte 0x17, 0x01
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "!"
	.zero 4
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	normal
	pop xix
	push	sr
	.fill 2, 1, 0xff
	.ascii "`"
	push	sr
	pop xiz
	push	sr
	.byte 0x08, 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	normal
	pop xix
	push	sr
	.fill 4, 1, 0xff
	.ascii "_"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "b"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	pushw de
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xa6  ; "¦"
	.asciz "A*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "a"
	.byte 0x02
	.ascii "c"
	.byte 0x02
	.ascii "d"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd0  ; "Ð"
	.asciz "A*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.ascii "b"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.asciz "|"
	.byte 0x15, 0x01
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "\""
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.ascii "a"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "e"
	.byte 0x02
	.ascii "b"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.ascii "a"
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "d"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "g"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	pushw iz
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "zB*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "f"
	.byte 0x02
	.ascii "h"
	.byte 0x02
	.ascii "i"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xa4  ; "¤"
	.asciz "B*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.ascii "g"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&"
	.asciz "|"
	.byte 0x19, 0x01
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "#"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.ascii "f"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "j"
	.byte 0x02
	.ascii "g"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.ascii "f"
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "i"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "l"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x32
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "NC*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "k"
	.byte 0x02
	.ascii "m"
	.byte 0x02
	.ascii "n"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "xC*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.ascii "l"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&"
	.asciz "x"
	.byte 0x19, 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "$"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.ascii "k"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "o"
	.byte 0x02
	.ascii "l"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.ascii "k"
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "n"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "q"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x36
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "\"D*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "p"
	.byte 0x02
	.ascii "r"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LD*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.ascii "q"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "s"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.ascii "q"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "t"
	.byte 0x02
	.ascii "r"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.ascii "q"
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "s"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&"
	.asciz "x"
	.byte 0x19, 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "%"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "v"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x3a
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xf6  ; "ö"
	.asciz "D*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "u"
	.byte 0x02
	.ascii "w"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " E*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.ascii "v"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "x"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.ascii "v"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "y"
	.byte 0x02
	.ascii "w"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.ascii "v"
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "x"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&"
	.asciz "x"
	.byte 0x19, 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "&"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "{"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x3e
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xca  ; "Ê"
	.asciz "E*"
	.zero 6
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.ascii "z"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "|"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "8"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.ascii "z"
	.byte 0x02
	.byte 0x7d
	.byte 0x02
	.byte 0x7e
	.byte 0x02
	.byte 0x7b
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x14
	.asciz "F*"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x7c
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "z"
	.byte 0x02, 0x7f, 0x02
	.fill 2, 1, 0xff
	.ascii "|"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xa8  ; "¨"
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xc9  ; "É"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "hF*"
	.byte 0x02
	.zero 7
	.byte 0x02
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x7e
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x80  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "^"
	.byte 0x17, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x7e
	.byte 0x02
	.fill 4, 1, 0xff
	jrl	nc, 0x0802
	nop
	.asciz "("
	.asciz "z"
	.byte 0x17, 0x01
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "'"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x82  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x42
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xe8  ; "è"
	.asciz "F*"
	.byte 0x01
	.zero 3
	.asciz "            "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x83  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "L"
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "f"
	.byte 0x1b
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.byte 0x84  ; ""
	.byte 0x02
	.byte 0x88  ; ""
	.byte 0x02
	.byte 0x82  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x19
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "D"
	.ascii "&"
	.byte 0x01
	.asciz "w"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "8G*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x85  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1d
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "E"
	.asciz " "
	.asciz "O"
	.asciz "ZG*"
	.byte 0x03
	.zero 7
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x86  ; ""
	.byte 0x02
	.byte 0x84  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1d
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T"
	.byte 0xe8  ; "è"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "f"
	.asciz "|G*"
	.zero 6

HDAE5000_Credits:	; 0x2A477C
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
	.asciz "Technosoft, CH-Samstagern"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x87  ; ""
	.byte 0x02
	.byte 0x85  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1d
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.byte 0xe8  ; "è"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "v"
	.byte 0xb6  ; "¶"
	.asciz "G*"
	.zero 6
	.asciz "Pointstyle, CH-Buttisholz"
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x86  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1b
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "E"
	.byte 0x1e, 0x01
	.asciz "T"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x11
	.byte 0x00
	.byte 0x03
	.zero 5
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.byte 0x89  ; ""
	.byte 0x02
	.byte 0x8d  ; ""
	.byte 0x02
	.byte 0x83  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x19
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "x"
	.ascii "&"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\"H*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x88  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x8a  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x08, 0x01
	.byte 0x9b  ; ""
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "DH*"
	.zero 6
	.asciz "KEY SOFT SERVICE, CH-Schenkon"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x88  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x8b  ; ""
	.byte 0x02
	.byte 0x89  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.byte 0x9a  ; ""
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x82  ; ""
	.asciz "H*"
	.byte 0x03
	.zero 5
	.asciz "Fax.  +41-41-922 03 15"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x88  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x8c  ; ""
	.byte 0x02
	.byte 0x8a  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.byte 0xa5  ; "¥"
	.byte 0x00
	.byte 0xda  ; "Ú"
	.byte 0x00
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xba  ; "º"
	.asciz "H*"
	.byte 0x03
	.zero 5
	.asciz "email:keysoftservice@bluewin.ch"
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x88  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x8b  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1b
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "z"
	.byte 0x1e, 0x01
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x12
	.byte 0x00
	.byte 0x03
	.zero 5
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.byte 0x8e  ; ""
	.byte 0x02
	.byte 0x8f  ; ""
	.byte 0x02
	.byte 0x88  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.byte 0xb4  ; "´"
	.byte 0x00
	.byte 0x26
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ",I*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x8d  ; ""
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0x26
	.byte 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x13
	.byte 0x00
	.byte 0x03
	.zero 5
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.byte 0x90  ; ""
	.byte 0x02
	.byte 0x92  ; ""
	.byte 0x02
	.byte 0x8d  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x26
	.byte 0x01
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x80  ; ""
	.asciz "I*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x91  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.byte 0xda  ; "Ú"
	.byte 0x00
	.byte 0x21
	.byte 0x01
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.asciz "I*"
	.byte 0x05
	.zero 5
	.asciz "Mr. T.Hamaguchi and Mr. M.Kitajima"
	.byte 0x00
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x90  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xdd  ; "Ý"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x14
	.byte 0x00
	.byte 0x03
	.zero 5
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x93  ; ""
	.byte 0x02
	.byte 0x8f  ; ""
	.byte 0x02, 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x13
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x92  ; ""
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "e"
	.zero 2
	.byte 0x18, 0x01, 0x1f
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0a
	.byte 0x00
	.byte 0x09
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x95  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x25
	.byte 0x01
	.asciz "Y"
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 2
	.ascii "F"
	.byte 0x9c  ; ""
	.asciz "#"
	.ascii "J"
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x94  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x96  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "\""
	.byte 0x17, 0x01
	.asciz "9"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz ";"
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x94  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x95  ; ""
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz ":"
	.ascii "#"
	.byte 0x01
	.asciz "Q"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "1"
	.byte 0x02
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x98  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	popw iz
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x97  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x9a  ; ""
	.byte 0x02
	.byte 0x98  ; ""
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x97  ; ""
	.byte 0x02
	.byte 0x9b  ; ""
	.byte 0x02
	.byte 0x9c  ; ""
	.byte 0x02
	.byte 0x99  ; ""
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x10
	.asciz "K*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x9a  ; ""
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "x"
	.byte 0x17, 0x01
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz ")"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x04
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x97  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x9a  ; ""
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "^"
	.byte 0x17, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9e  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x52
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xa0  ; " "
	.byte 0x02
	.byte 0x9e  ; ""
	.byte 0x02, 0x18
	.zero 3
	.asciz "$"
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "C"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x02
	.byte 0xa1  ; "¡"
	.byte 0x02
	.byte 0xa2  ; "¢"
	.byte 0x02
	.byte 0x9f  ; ""
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.asciz "K*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xa0  ; " "
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "^"
	.byte 0x17, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xa0  ; " "
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "x"
	.byte 0x17, 0x01
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz ")"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x04
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xa4  ; "¤"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x56
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xa3  ; "£"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xa5  ; "¥"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xa3  ; "£"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xa6  ; "¦"
	.byte 0x02
	.byte 0xa4  ; "¤"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xa3  ; "£"
	.byte 0x02
	.byte 0xa7  ; "§"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xa5  ; "¥"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x9e  ; ""
	.asciz "L*"
	.zero 8
	.byte 0x05
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xa8  ; "¨"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "^"
	.byte 0x17, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xa7  ; "§"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "|"
	.byte 0x17, 0x01
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "*"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x04
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xaa  ; "ª"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	pop xde
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xa9  ; "©"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xab  ; "«"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xa9  ; "©"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xac  ; "¬"
	.byte 0x02
	.byte 0xaa  ; "ª"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xa9  ; "©"
	.byte 0x02
	.byte 0xad  ; "­"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xab  ; "«"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "2"
	.byte 0x17, 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xc9  ; "É"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rM*"
	.byte 0x02
	.zero 7
	.byte 0x04
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xac  ; "¬"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xae  ; "®"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "8"
	.byte 0x17, 0x01
	.asciz "O"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xac  ; "¬"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xaf  ; "¯"
	.byte 0x02
	.byte 0xad  ; "­"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "R"
	.byte 0x17, 0x01
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "+"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x04
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xac  ; "¬"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xae  ; "®"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0x98  ; ""
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz ","
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xb1  ; "±"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	pop xiz
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xb0  ; "°"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb2  ; "²"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xb0  ; "°"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb3  ; "³"
	.byte 0x02
	.byte 0xb1  ; "±"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xb0  ; "°"
	.byte 0x02
	.byte 0xb4  ; "´"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb2  ; "²"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "2"
	.byte 0x17, 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xc9  ; "É"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "pN*"
	.byte 0x02
	.zero 7
	.byte 0x04
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb5  ; "µ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0x8c  ; ""
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcf  ; "Ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "."
	.zero 8
	.byte 0x04
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb6  ; "¶"
	.byte 0x02
	.byte 0xb4  ; "´"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "8"
	.byte 0x17, 0x01
	.asciz "O"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xb5  ; "µ"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "-"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xb8  ; "¸"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "b"
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb9  ; "¹"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "?"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x02
	.byte 0xba  ; "º"
	.byte 0x02
	.byte 0xbb  ; "»"
	.byte 0x02
	.byte 0xb8  ; "¸"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "TO*"
	.byte 0x02
	.zero 7
	.byte 0x02
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xb9  ; "¹"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "x"
	.byte 0x17, 0x01
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "/"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xb9  ; "¹"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "\\"
	.byte 0x17, 0x01
	.asciz "s"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xbd  ; "½"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "f"
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xbc  ; "¼"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xbe  ; "¾"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "?"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xbc  ; "¼"
	.byte 0x02
	.byte 0xbf  ; "¿"
	.byte 0x02
	.byte 0xc0  ; "À"
	.byte 0x02
	.byte 0xbd  ; "½"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x0e
	.asciz "P*"
	.byte 0x02
	.zero 7
	.byte 0x02
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xbe  ; "¾"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "\\"
	.byte 0x17, 0x01
	.asciz "s"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xbc  ; "¼"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xbe  ; "¾"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz "x"
	.byte 0x11, 0x01
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "0"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc2  ; "Â"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "j"
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xc1  ; "Á"
	.byte 0x02
	.byte 0xc3  ; "Ã"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xae  ; "®"
	.asciz "P*"
	.byte 0x01
	.zero 7
	.byte 0x01
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "H"
	.asciz "b"
	.byte 0xf1  ; "ñ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "y"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "1"
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc5  ; "Å"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "n"
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xc6  ; "Æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x1a, 0x02, 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xc7  ; "Ç"
	.byte 0x02
	.byte 0xc5  ; "Å"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x02
	.byte 0xc8  ; "È"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xc6  ; "Æ"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "N"
	.byte 0x1f, 0x01
	.byte 0xe3  ; "ã"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "XQ*"
	.byte 0x02
	.zero 7
	.byte 0x05
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xc9  ; "É"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "t"
	.byte 0x17, 0x01
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "3"
	.zero 4
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xca  ; "Ê"
	.byte 0x02
	.byte 0xc8  ; "È"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1e
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "P"
	.ascii "!"
	.byte 0x01
	.asciz "s"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "2"
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xc9  ; "É"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xe3  ; "ã"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "4"
	.byte 0x07
	.zero 7
	.byte 0x04
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xcc  ; "Ì"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "r"
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xcd  ; "Í"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x1a, 0x02, 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xce  ; "Î"
	.byte 0x02
	.byte 0xcc  ; "Ì"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x02
	.byte 0xcf  ; "Ï"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xcd  ; "Í"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "N"
	.byte 0x1f, 0x01
	.byte 0xe3  ; "ã"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "VR*"
	.byte 0x02
	.zero 7
	.byte 0x05
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd0  ; "Ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.asciz "P"
	.ascii "%"
	.byte 0x01
	.asciz "s"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "5"
	.byte 0x02
	.zero 7
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd1  ; "Ñ"
	.byte 0x02
	.byte 0xcf  ; "Ï"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.asciz "t"
	.byte 0x17, 0x01
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "6"
	.zero 4
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xd0  ; "Ð"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0x98  ; ""
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "7"
	.byte 0x07
	.zero 7
	.byte 0x04
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd3  ; "Ó"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "v"
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x00
	.asciz "S*"
	.zero 6
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd4  ; "Ô"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd5  ; "Õ"
	.byte 0x02
	.byte 0xd3  ; "Ó"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "?"
	.byte 0x01
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x02, 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd6  ; "Ö"
	.byte 0x02
	.byte 0xd4  ; "Ô"
	.byte 0x02, 0x18
	.zero 3
	.asciz "@"
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "_"
	.byte 0x02
	.byte 0x00
	.byte 0x10, 0x01, 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd7  ; "×"
	.byte 0x02
	.byte 0xd5  ; "Õ"
	.byte 0x02, 0x18
	.zero 3
	.asciz "`"
	.byte 0x1f
	nop
	jrl	nc, 3328
	nop
	popw de
	normal
	.byte 0x08, 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xd6  ; "Ö"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x3b
	.byte 0x01, 0x17
	.byte 0x00
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.ascii "z"
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd9  ; "Ù"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 4
	.ascii "|"
	.byte 0x9c  ; ""
	.asciz "#"
	adc	(xwa), d
	.asciz "#"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xda  ; "Ú"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0xdc  ; "Ü"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x07
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xdb  ; "Û"
	.byte 0x02
	.byte 0xd9  ; "Ù"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xdc  ; "Ü"
	.byte 0x02
	.byte 0xda  ; "Ú"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz "4"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	normal
	adc	(xix), d
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0x88, 0x9c  ; ""
	.asciz "#"
	.zero 4
	.byte 0x8a, 0x9c  ; ""
	.asciz "#"
	.zero 2
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xdd  ; "Ý"
	.byte 0x02
	.byte 0xdb  ; "Û"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "-"
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xde  ; "Þ"
	.byte 0x02
	.byte 0xdc  ; "Ü"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "*"
	.zero 2
	.asciz "E"
	.byte 0x1b
	.byte 0x00
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xdf  ; "ß"
	.byte 0x02
	.byte 0xdd  ; "Ý"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "F"
	.byte 0x07
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.byte 0xa6  ; "¦"
	.asciz "T*"
	.byte 0x04
	.zero 3
	.byte 0xff
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "FILE SELECT A-Z"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe0  ; "à"
	.byte 0x02
	.byte 0xde  ; "Þ"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "$"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe1  ; "á"
	.byte 0x02
	.byte 0xdf  ; "ß"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "?"
	.byte 0x01
	.asciz "_"
	.byte 0x06
	.asciz "U*"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01, 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "~80"
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe2  ; "â"
	.byte 0x02
	.byte 0xe0  ; "à"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.byte 0xe3  ; "ã"
	.byte 0x02
	.byte 0xe5  ; "å"
	.byte 0x02
	.byte 0xe1  ; "á"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.byte 0x1e
	.byte 0x00
	.byte 0xeb  ; "ë"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "/"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0x8c, 0x9c  ; ""
	.asciz "#"
	normal
	nop
	normal
	nop
	adc	(xwa), ix
	.asciz "#"
	.zero 4
	adc	(xde), ix
	.asciz "#"
	.zero 2
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x02
	.byte 0xe4  ; "ä"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "N"
	.asciz " "
	.byte 0xed  ; "í"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "/"
	.byte 0x08
	.zero 3
	.byte 0x88  ; ""
	.asciz "U*"
	.byte 0x03
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Evergreens slow / 12"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe3  ; "ã"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ","
	.asciz " "
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "/"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc6  ; "Æ"
	.asciz "U*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LOC.:"
	.byte 0x10
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe6  ; "æ"
	.byte 0x02
	.byte 0xe2  ; "â"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.byte 0xe7  ; "ç"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe5  ; "å"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "d"
	.ascii "?"
	.byte 0x01
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x0a
	.asciz "V*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe8  ; "è"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xae  ; "®"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "4V*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.byte 0x00

HDAE5000_Demo_Data:	; 0x2A5634
	; MISNOMER retained for cross-reference.  RETRACTED: "Demo song data and
	; rhythm custom UI".  There is NO demo song data anywhere in this pool -
	; it is 769 UI object descriptors and nothing else, every byte of it
	; assigned to a record by the header at HDAE5000_UI_Descriptors.
	; 0x2A5634 is byte +0x28 of object #743 (record 0x2A560C-0x2A5641, 54
	; bytes, class 0160:0036, under FILE_LOAD_A_Z via object #742) - that
	; ONE object's inline caption, named by the .long at +0x1A of the
	; record.  The nearest record boundary is 0x28 bytes ABOVE this label.
	.asciz "RHYTHM CUSTOM"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe9  ; "é"
	.byte 0x02
	.byte 0xe7  ; "ç"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xba  ; "º"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "jV*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "USER MIDI"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xea  ; "ê"
	.byte 0x02
	.byte 0xe8  ; "è"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x9c  ; ""
	.asciz "V*"
	.byte 0x03
	.zero 3
	.byte 0x0d
	.zero 3
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "TECH LYRICS"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xeb  ; "ë"
	.byte 0x02
	.byte 0xe9  ; "é"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd0  ; "Ð"
	.asciz "V*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "MSP"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.byte 0xec  ; "ì"
	.byte 0x02
	.byte 0xed  ; "í"
	.byte 0x02
	.byte 0xea  ; "ê"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0x96  ; ""
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xa7  ; "§"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xfc  ; "ü"
	.asciz "V*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SOUND MEMORY"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xeb  ; "ë"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "2W*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "COMPOSER"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xee  ; "î"
	.byte 0x02
	.byte 0xeb  ; "ë"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "~"
	.ascii "?"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "dW*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SEQUENCER"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xef  ; "ï"
	.byte 0x02
	.byte 0xed  ; "í"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "r"
	.ascii "?"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x96  ; ""
	.asciz "W*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "PANEL MEMORY"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xee  ; "î"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "f"
	.ascii "?"
	.byte 0x01
	.asciz "w"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xcc  ; "Ì"
	.asciz "W*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "CURRENT PANEL"
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf1  ; "ñ"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	adc	(xix), ix
	.asciz "#"
	.byte 0x04
	.asciz "X*"
	.asciz "<"
	.zero 2
	.asciz "TECH LYRICS"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xf2  ; "ò"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.byte 0xf3  ; "ó"
	.byte 0x02
	.byte 0xf4  ; "ô"
	.byte 0x02
	.byte 0xf1  ; "ñ"
	.byte 0x02, 0x08
	.zero 3
	.asciz "!"
	.ascii "?"
	.byte 0x01
	.asciz "8"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "RX*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf2  ; "ò"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "\""
	.ascii "?"
	.byte 0x01
	.asciz "7"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x05
	.zero 3
	.byte 0xff
	.zero 3
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.byte 0xf5  ; "õ"
	.byte 0x02
	.byte 0xf6  ; "ö"
	.byte 0x02
	.byte 0xf2  ; "ò"
	.byte 0x02, 0x08
	.zero 3
	.asciz "8"
	.ascii "?"
	.byte 0x01
	.asciz "I"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xa0  ; " "
	.asciz "X*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf4  ; "ô"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x03
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "9"
	.ascii "?"
	.byte 0x01
	.asciz "G"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xf7  ; "÷"
	.byte 0x02
	.byte 0xf4  ; "ô"
	.byte 0x02, 0x08
	.zero 3
	.byte 0xe0  ; "à"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xf8  ; "ø"
	.byte 0x02
	.byte 0xf6  ; "ö"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "("
	.byte 0xe0  ; "à"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "O"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xf9  ; "ù"
	.byte 0x02
	.byte 0xf7  ; "÷"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "P"
	.byte 0xe0  ; "à"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "w"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xfa  ; "ú"
	.byte 0x02
	.byte 0xf8  ; "ø"
	.byte 0x02, 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "x"
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xfb  ; "û"
	.byte 0x02
	.byte 0xf9  ; "ù"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xfc  ; "ü"
	.byte 0x02
	.byte 0xfa  ; "ú"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xc8  ; "È"
	.byte 0x00
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xfd  ; "ý"
	.byte 0x02
	.byte 0xfb  ; "û"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xfe  ; "þ"
	.byte 0x02
	.byte 0xfc  ; "ü"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x18, 0x01
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.byte 0xff
	.byte 0x02, 0x03, 0x03
	.byte 0xfd  ; "ý"
	.byte 0x02, 0x08
	.zero 3
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x0e
	.asciz "Z*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.zero 3
	.byte 0x0b
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xfe  ; "þ"
	.byte 0x02, 0x08
	.zero 3
	.asciz "K"
	.ascii "?"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x98, 0x9c  ; ""
	.asciz "#"
	.byte 0x07
	.zero 3
	.byte 0xfc  ; "ü"
	.byte 0x00
	.byte 0x0d
	.byte 0x00
	.byte 0x03
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0x07
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x05, 0x03
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.zero 6
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x9a, 0x9c  ; ""
	.asciz "#"
	.asciz "hZ*"
	.asciz "'"
	.zero 2
	.asciz "LOAD LYRICS FROM FD"
	.asciz "I"
	.ascii "`"
	.byte 0x01, 0x04, 0x03
	.fill 2, 1, 0xff
	.byte 0x06, 0x03
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x02, 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x04, 0x03
	.fill 2, 1, 0xff
	.byte 0x07, 0x03, 0x05, 0x03, 0x08
	.byte 0x00
	.byte 0x1c
	.byte 0x00
	.byte 0xe1  ; "á"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "7"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xb6  ; "¶"
	.asciz "Z*"
	.byte 0x03
	.zero 5
	.asciz "Info"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x04, 0x03
	.fill 2, 1, 0xff
	.byte 0x08, 0x03, 0x06, 0x03, 0x08
	.byte 0x00
	.byte 0x06, 0x01
	.byte 0xe1  ; "á"
	.byte 0x00
	.byte 0x21
	.byte 0x01
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.asciz "Z*"
	.byte 0x03
	.zero 5
	.asciz "Load"
	.byte 0x00
	.byte 0x0c
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x04, 0x03
	.fill 4, 1, 0xff
	.byte 0x07, 0x03, 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x9e, 0x9c  ; ""
	.asciz "#"
	adc	(xwa), xix
	.asciz "#"
	.byte 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x0a, 0x03
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	adc	(xde), xix
	.asciz "#"
	.asciz ",[*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01, 0x09, 0x03, 0x0b, 0x03
	.fill 4, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xc1  ; "Á"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "V[*"
	.byte 0x01
	.zero 7
	.byte 0x01
	.zero 3
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x0a, 0x03
	.fill 6, 1, 0xff
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "H"
	.asciz "b"
	.byte 0xf1  ; "ñ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "y"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "1"
	.zero 8
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x06
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x0d, 0x03
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	adc	(xiz), xix
	.asciz "#"
	.byte 0xac  ; "¬"
	.asciz "[*"
	.asciz "<"
	.zero 2
	.asciz "LYRICS OPTIONS"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "I"
	.ascii "`"
	.byte 0x01, 0x0c, 0x03
	.fill 2, 1, 0xff
	.byte 0x0e, 0x03
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x13
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x0c, 0x03, 0x0f, 0x03, 0x10, 0x03, 0x0d, 0x03, 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "H"
	.byte 0xc5  ; "Å"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "a"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0x10
	.asciz "\\*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xaa, 0x9c  ; "ª"
	.asciz "#"
	.asciz "B"
	.ascii "*"
	.byte 0x01
	.byte 0xac, 0x9c  ; "¬"
	.asciz "#"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x0e, 0x03
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "H"
	.byte 0x8e  ; ""
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "@"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x0c, 0x03, 0x11, 0x03, 0x12, 0x03, 0x0e, 0x03, 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "r"
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.asciz "v\\*"
	.zero 4
	swi	7
	nop
	push	sr
	nop
	max
	nop
	.byte 0x8a, 0x00, 0x01
	nop
	ldcfm	4, (xwa)
	.asciz "#"
	.asciz "C"
	.ascii "*"
	normal
	ldcfm	4, (xde)
	.asciz "#"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x10, 0x03
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "r"
	.byte 0x8e  ; ""
	.byte 0x00
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "A"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x0c, 0x03
	.fill 2, 1, 0xff
	.byte 0x13, 0x03, 0x10, 0x03, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0xdc  ; "Ü"
	.asciz "\\*"
	.zero 4
	swi	7
	nop
	push	sr
	nop
	max
	nop
	.byte 0x8b, 0x00, 0x01
	nop
	ldcfm	4, (xiz)
	.asciz "#"
	.asciz "D"
	.ascii "*"
	.byte 0x01
	.byte 0xb8, 0x9c  ; "¸"
	.asciz "#"
	.zero 2
	.byte 0x0a
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "j"
	.byte 0x01, 0x0c, 0x03
	.fill 4, 1, 0xff
	.byte 0x12, 0x03, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x8e  ; ""
	.byte 0x00
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "B"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 8, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x10
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "p"
	.ascii "3"
	.byte 0x01
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.byte 0xbc, 0x9c  ; "¼"
	.asciz "#"
	.byte 0xc0, 0x9c  ; "À"
	.asciz "#"

; =============================================================================
; HD-AE5000 UI OBJECT TABLE (0x2A5D2C - 0x2A6983)
; =============================================================================
; 789 pointers to UI object descriptors plus a NULL end-of-table marker: 790
; .long entries, no code.  Registered at boot by HDAE5000_Handler_Registration
; (hd-ae5000_v2_06i.s, "Handler 10"): object-set ID 0x007F, PPI port 0x01600010,
; entry count 0x315 = 789, table pointer 0x2A5D2C, handler function from
; workspace[0x0E0A][0x0280], handed to RegisterObjectTable = workspace[0x0E0A][0x00E4].
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
; The targets stay absolute for now: the descriptor pool itself is still decoded
; as instructions in places (721 instruction lines remain inside it), and the
; labels HDAE5000_UI_Descriptors (0x29DC14) / _UI_Page_Titles / _Panel_Save_UI /
; _Credits / _Demo_Data cut that one contiguous pool into five arbitrary pieces -
; none of them a descriptor boundary; the pool really starts at 0x29DC12, two
; bytes below the first of those labels.  The record format, the 769 boundaries
; and where each of those five labels actually falls are now documented in the
; header block at HDAE5000_UI_Descriptors: they are +0x02 of record #0 and
; +0x28 / +0x3A / +0x20 / +0x28 of records #18 / #177 / #645 / #743, the last
; four sitting on that record's inline caption string.  The names are kept as
; misnomers because the ASL mirror, the symbols reference and seven .set bases
; in hdae5000_init_data.s use them.  Symbolising the 769 records is a follow-up
; package, not this one; its only legal split points are the .long values of
; this table.
; =============================================================================

HDAE5000_UiObject_PtrTable:	; 0x2A5D2C
	.long	0x0029DC12        ; [  0] HDDMENU
	.long	0x0029DC46        ; [  1] (unnamed)
	.long	0x0029DC8C        ; [  2] (unnamed)
	.long	0x0029DCC4        ; [  3] (unnamed)
	.long	0x0029DCEE        ; [  4] (unnamed)
	.long	0x0029DD26        ; [  5] (unnamed)
	.long	0x0029DD50        ; [  6] (unnamed)
	.long	0x0029DD88        ; [  7] (unnamed)
	.long	0x0029DDB2        ; [  8] (unnamed)
	.long	0x0029DDEA        ; [  9] (unnamed)
	.long	0x0029DE14        ; [ 10] HARD_DISK_OPT
	.long	0x0029DE50        ; [ 11] (unnamed)
	.long	0x0029DE6A        ; [ 12] (unnamed)
	.long	0x0029DE84        ; [ 13] (unnamed)
	.long	0x0029DE9E        ; [ 14] (unnamed)
	.long	0x0029DED6        ; [ 15] (unnamed)
	.long	0x0029DF00        ; [ 16] (unnamed)
	.long	0x0029DF2A        ; [ 17] (unnamed)
	.long	0x0029DF62        ; [ 18] (unnamed)
	.long	0x0029DF98        ; [ 19] SETUPS_TOOLS
	.long	0x0029DFD2        ; [ 20] (unnamed)
	.long	0x0029DFEC        ; [ 21] (unnamed)
	.long	0x0029E008        ; [ 22] (unnamed)
	.long	0x0029E024        ; [ 23] (unnamed)
	.long	0x0029E048        ; [ 24] SELECT_FILE
	.long	0x0029E074        ; [ 25] (unnamed)
	.long	0x0029E08E        ; [ 26] HD_FILE_LOAD
	.long	0x0029E0AA        ; [ 27] HD_LOAD_OPTION
	.long	0x0029E0C6        ; [ 28] (unnamed)
	.long	0x0029E0EE        ; [ 29] (unnamed)
	.long	0x0029E114        ; [ 30] (unnamed)
	.long	0x0029E12E        ; [ 31] (unnamed)
	.long	0x0029E15A        ; [ 32] (unnamed)
	.long	0x0029E174        ; [ 33] (unnamed)
	.long	0x0029E198        ; [ 34] SELECT_DIR
	.long	0x0029E1D0        ; [ 35] (unnamed)
	.long	0x0029E1FA        ; [ 36] (unnamed)
	.long	0x0029E214        ; [ 37] SEL_DIR
	.long	0x0029E250        ; [ 38] (unnamed)
	.long	0x0029E284        ; [ 39] (unnamed)
	.long	0x0029E2B6        ; [ 40] (unnamed)
	.long	0x0029E2E8        ; [ 41] (unnamed)
	.long	0x0029E31A        ; [ 42] (unnamed)
	.long	0x0029E34C        ; [ 43] (unnamed)
	.long	0x00239CC4        ; [ 44] SELECT_DIR_SW_EDIT  -- RAM descriptor
	.long	0x0029E374        ; [ 45] (unnamed)
	.long	0x0029E39A        ; [ 46] (unnamed)
	.long	0x0029E3B4        ; [ 47] (unnamed)
	.long	0x0029E3E0        ; [ 48] (unnamed)
	.long	0x0029E3FA        ; [ 49] SELECT_DIR2
	.long	0x0029E43A        ; [ 50] (unnamed)
	.long	0x0029E472        ; [ 51] (unnamed)
	.long	0x0029E496        ; [ 52] (unnamed)
	.long	0x0029E4C0        ; [ 53] (unnamed)
	.long	0x0029E4E8        ; [ 54] (unnamed)
	.long	0x0029E520        ; [ 55] (unnamed)
	.long	0x0029E544        ; [ 56] (unnamed)
	.long	0x0029E55E        ; [ 57] (unnamed)
	.long	0x0029E586        ; [ 58] FD_FILE_SELECT
	.long	0x0029E5C4        ; [ 59] (unnamed)
	.long	0x0029E5FC        ; [ 60] (unnamed)
	.long	0x0029E622        ; [ 61] (unnamed)
	.long	0x0029E64C        ; [ 62] (unnamed)
	.long	0x0029E674        ; [ 63] (unnamed)
	.long	0x0029E6AC        ; [ 64] (unnamed)
	.long	0x0029E6C6        ; [ 65] (unnamed)
	.long	0x0029E6EE        ; [ 66] (unnamed)
	.long	0x0029E718        ; [ 67] (unnamed)
	.long	0x0029E740        ; [ 68] (unnamed)
	.long	0x0029E77C        ; [ 69] HARD_TEST
	.long	0x0029E7B4        ; [ 70] (unnamed)
	.long	0x0029E7CE        ; [ 71] (unnamed)
	.long	0x0029E7E8        ; [ 72] (unnamed)
	.long	0x0029E802        ; [ 73] RUN_STOP
	.long	0x0029E834        ; [ 74] (unnamed)
	.long	0x0029E84E        ; [ 75] PPORT_SW
	.long	0x0029E882        ; [ 76] FD_SW
	.long	0x0029E8B2        ; [ 77] HDD_SW
	.long	0x0029E8E2        ; [ 78] HDD_FILE_NAMING
	.long	0x0029E91C        ; [ 79] (unnamed)
	.long	0x0029E936        ; [ 80] (unnamed)
	.long	0x0029E962        ; [ 81] (unnamed)
	.long	0x0029E97C        ; [ 82] (unnamed)
	.long	0x0029E9A8        ; [ 83] (unnamed)
	.long	0x0029E9CC        ; [ 84] (unnamed)
	.long	0x0029E9E6        ; [ 85] (unnamed)
	.long	0x0029EA12        ; [ 86] (unnamed)
	.long	0x0029EA36        ; [ 87] HD_FILE_NAME
	.long	0x0029EA5A        ; [ 88] HDD_DIR_NAMING
	.long	0x0029EA98        ; [ 89] (unnamed)
	.long	0x0029EAB2        ; [ 90] (unnamed)
	.long	0x0029EADE        ; [ 91] (unnamed)
	.long	0x0029EAF8        ; [ 92] (unnamed)
	.long	0x0029EB24        ; [ 93] (unnamed)
	.long	0x0029EB48        ; [ 94] HD_PLEASE_WIN
	.long	0x0029EB6C        ; [ 95] (unnamed)
	.long	0x0029EB9A        ; [ 96] HD_UTIL
	.long	0x0029EBD0        ; [ 97] (unnamed)
	.long	0x0029EBEA        ; [ 98] (unnamed)
	.long	0x0029EC04        ; [ 99] (unnamed)
	.long	0x0029EC1A        ; [100] (unnamed)
	.long	0x0029EC54        ; [101] (unnamed)
	.long	0x0029EC8E        ; [102] PC_DATA_LINK
	.long	0x0029ECC8        ; [103] (unnamed)
	.long	0x0029ECE2        ; [104] PP_STATUS
	.long	0x0029ED1E        ; [105] (unnamed)
	.long	0x0029ED48        ; [106] (unnamed)
	.long	0x0029ED70        ; [107] (unnamed)
	.long	0x0029ED9A        ; [108] (unnamed)
	.long	0x0029EDC0        ; [109] (unnamed)
	.long	0x0029EDDA        ; [110] SETUP_TOOLS_P1
	.long	0x0029EDFE        ; [111] (unnamed)
	.long	0x0029EE42        ; [112] (unnamed)
	.long	0x0029EE5C        ; [113] (unnamed)
	.long	0x0029EE86        ; [114] (unnamed)
	.long	0x0029EEC2        ; [115] (unnamed)
	.long	0x0029EEEC        ; [116] (unnamed)
	.long	0x0029EF36        ; [117] (unnamed)
	.long	0x0029EF80        ; [118] (unnamed)
	.long	0x0029EFBC        ; [119] (unnamed)
	.long	0x0029EFE6        ; [120] (unnamed)
	.long	0x0029F030        ; [121] (unnamed)
	.long	0x0029F076        ; [122] SETUP_TOOLS_P2
	.long	0x0029F09A        ; [123] (unnamed)
	.long	0x0029F0D2        ; [124] (unnamed)
	.long	0x0029F0FC        ; [125] (unnamed)
	.long	0x0029F140        ; [126] (unnamed)
	.long	0x0029F15A        ; [127] (unnamed)
	.long	0x00239CEC        ; [128] SW_HD_FORMAT  -- RAM descriptor
	.long	0x0029F182        ; [129] (unnamed)
	.long	0x0029F19C        ; [130] (unnamed)
	.long	0x0029F1D4        ; [131] (unnamed)
	.long	0x0029F1EE        ; [132] (unnamed)
	.long	0x0029F218        ; [133] OUTPUT_SETTING
	.long	0x0029F252        ; [134] (unnamed)
	.long	0x0029F26C        ; [135] (unnamed)
	.long	0x0029F296        ; [136] (unnamed)
	.long	0x0029F2D2        ; [137] (unnamed)
	.long	0x0029F30E        ; [138] (unnamed)
	.long	0x0029F34A        ; [139] (unnamed)
	.long	0x0029F374        ; [140] (unnamed)
	.long	0x0029F39E        ; [141] (unnamed)
	.long	0x0029F3C8        ; [142] (unnamed)
	.long	0x0029F3F2        ; [143] LOAD_BY_NUM
	.long	0x0029F42C        ; [144] (unnamed)
	.long	0x0029F446        ; [145] (unnamed)
	.long	0x0029F462        ; [146] (unnamed)
	.long	0x0029F47E        ; [147] (unnamed)
	.long	0x0029F4A2        ; [148] (unnamed)
	.long	0x0029F4BC        ; [149] LBN_P1
	.long	0x0029F4E0        ; [150] (unnamed)
	.long	0x0029F50A        ; [151] (unnamed)
	.long	0x0029F530        ; [152] LBN_OPTION
	.long	0x0029F56C        ; [153] (unnamed)
	.long	0x0029F594        ; [154] (unnamed)
	.long	0x0029F5BA        ; [155] (unnamed)
	.long	0x0029F5E6        ; [156] (unnamed)
	.long	0x0029F600        ; [157] (unnamed)
	.long	0x0029F62A        ; [158] (unnamed)
	.long	0x0029F652        ; [159] (unnamed)
	.long	0x0029F67A        ; [160] (unnamed)
	.long	0x0029F6A2        ; [161] (unnamed)
	.long	0x0029F6CA        ; [162] (unnamed)
	.long	0x0029F6F2        ; [163] (unnamed)
	.long	0x0029F71A        ; [164] (unnamed)
	.long	0x0029F742        ; [165] (unnamed)
	.long	0x0029F76A        ; [166] (unnamed)
	.long	0x0029F792        ; [167] (unnamed)
	.long	0x0029F7BA        ; [168] LBN_DIRNO_BOX
	.long	0x0029F7F6        ; [169] LBN_DIRNAME_BOX
	.long	0x0029F832        ; [170] LBN_FILENO_BOX
	.long	0x0029F86E        ; [171] LBN_FILENAME_BOX
	.long	0x0029F8AA        ; [172] (unnamed)
	.long	0x0029F8C4        ; [173] (unnamed)
	.long	0x0029F8EE        ; [174] (unnamed)
	.long	0x0029F918        ; [175] LBN_P2
	.long	0x0029F93C        ; [176] (unnamed)
	.long	0x0029F978        ; [177] (unnamed)
	.long	0x0029F9CA        ; [178] (unnamed)
	.long	0x0029FA1C        ; [179] (unnamed)
	.long	0x0029FA36        ; [180] (unnamed)
	.long	0x0029FA88        ; [181] (unnamed)
	.long	0x0029FADA        ; [182] (unnamed)
	.long	0x0029FB2C        ; [183] (unnamed)
	.long	0x0029FB7E        ; [184] (unnamed)
	.long	0x0029FBD0        ; [185] (unnamed)
	.long	0x0029FC22        ; [186] (unnamed)
	.long	0x0029FC3C        ; [187] (unnamed)
	.long	0x0029FC56        ; [188] (unnamed)
	.long	0x0029FC70        ; [189] (unnamed)
	.long	0x0029FC98        ; [190] (unnamed)
	.long	0x0029FCC0        ; [191] (unnamed)
	.long	0x0029FCE8        ; [192] (unnamed)
	.long	0x0029FD10        ; [193] (unnamed)
	.long	0x0029FD38        ; [194] (unnamed)
	.long	0x0029FD60        ; [195] (unnamed)
	.long	0x0029FD88        ; [196] (unnamed)
	.long	0x0029FDB0        ; [197] (unnamed)
	.long	0x0029FDD4        ; [198] (unnamed)
	.long	0x0029FDFA        ; [199] (unnamed)
	.long	0x0029FE1E        ; [200] (unnamed)
	.long	0x0029FE44        ; [201] (unnamed)
	.long	0x0029FE6A        ; [202] (unnamed)
	.long	0x0029FE8E        ; [203] (unnamed)
	.long	0x0029FEB6        ; [204] (unnamed)
	.long	0x0029FEDC        ; [205] (unnamed)
	.long	0x0029FEF6        ; [206] (unnamed)
	.long	0x0029FF1E        ; [207] (unnamed)
	.long	0x0029FF44        ; [208] (unnamed)
	.long	0x0029FF5E        ; [209] (unnamed)
	.long	0x0029FF8A        ; [210] CP_FD
	.long	0x0029FFC4        ; [211] (unnamed)
	.long	0x0029FFDE        ; [212] (unnamed)
	.long	0x002A0006        ; [213] (unnamed)
	.long	0x002A002E        ; [214] (unnamed)
	.long	0x002A0058        ; [215] CP_FD_LIST
	.long	0x002A0094        ; [216] CP_FD_LINE2
	.long	0x002A00AE        ; [217] CP_FD_LINE1
	.long	0x00239D22        ; [218] CP_FD_HDSWTO  -- RAM descriptor
	.long	0x002A00C8        ; [219] (unnamed)
	.long	0x00239D4A        ; [220] CP_FD_HDSWSEL  -- RAM descriptor
	.long	0x002A00EE        ; [221] (unnamed)
	.long	0x002A0116        ; [222] CP_FD_VOLLABEL
	.long	0x002A0152        ; [223] (unnamed)
	.long	0x00239D72        ; [224] CP_FD_HDALLSEL  -- RAM descriptor
	.long	0x002A0182        ; [225] (unnamed)
	.long	0x002A01AA        ; [226] CP_FD_DIRSEL
	.long	0x002A01E2        ; [227] (unnamed)
	.long	0x002A01FC        ; [228] (unnamed)
	.long	0x002A0224        ; [229] (unnamed)
	.long	0x002A024A        ; [230] CP_FD_DIRBOX
	.long	0x002A0286        ; [231] (unnamed)
	.long	0x002A02B8        ; [232] (unnamed)
	.long	0x002A02EA        ; [233] (unnamed)
	.long	0x002A0314        ; [234] (unnamed)
	.long	0x002A0346        ; [235] (unnamed)
	.long	0x002A0378        ; [236] (unnamed)
	.long	0x002A03AC        ; [237] (unnamed)
	.long	0x002A03D4        ; [238] (unnamed)
	.long	0x002A03FA        ; [239] (unnamed)
	.long	0x002A0414        ; [240] FLS_SELECT
	.long	0x002A044E        ; [241] (unnamed)
	.long	0x002A0468        ; [242] (unnamed)
	.long	0x002A049A        ; [243] (unnamed)
	.long	0x002A04CC        ; [244] (unnamed)
	.long	0x002A04F6        ; [245] (unnamed)
	.long	0x002A0528        ; [246] (unnamed)
	.long	0x002A055A        ; [247] (unnamed)
	.long	0x002A058E        ; [248] FLS_SEL
	.long	0x00239D9A        ; [249] FLS_SELECT_SW_EDIT  -- RAM descriptor
	.long	0x002A05B6        ; [250] (unnamed)
	.long	0x002A05DC        ; [251] SEL_FLS
	.long	0x002A0618        ; [252] (unnamed)
	.long	0x002A0632        ; [253] (unnamed)
	.long	0x002A065E        ; [254] (unnamed)
	.long	0x002A0678        ; [255] HD_FILE_LOAD_P1
	.long	0x00239DC2        ; [256] HD_FILE_LOAD_SW_SAVE  -- RAM descriptor
	.long	0x002A069C        ; [257] (unnamed)
	.long	0x002A06C2        ; [258] HD_FILE_OPTION
	.long	0x002A06FE        ; [259] HD_FILE_LIST
	.long	0x002A073A        ; [260] FILE_LOAD_DIRBOX
	.long	0x002A0776        ; [261] (unnamed)
	.long	0x002A079E        ; [262] (unnamed)
	.long	0x002A07C8        ; [263] (unnamed)
	.long	0x002A07F0        ; [264] (unnamed)
	.long	0x002A080A        ; [265] (unnamed)
	.long	0x00239DEA        ; [266] HD_FILE_LOAD_SW_DEL  -- RAM descriptor
	.long	0x002A083A        ; [267] (unnamed)
	.long	0x002A085E        ; [268] (unnamed)
	.long	0x00239E12        ; [269] HD_FILE_LOAD_SW_DELFILE  -- RAM descriptor
	.long	0x002A0882        ; [270] (unnamed)
	.long	0x002A08A6        ; [271] (unnamed)
	.long	0x002A08CC        ; [272] HD_FILE_LOAD_P2
	.long	0x002A08F0        ; [273] (unnamed)
	.long	0x002A0920        ; [274] (unnamed)
	.long	0x002A093A        ; [275] (unnamed)
	.long	0x002A098C        ; [276] (unnamed)
	.long	0x002A09B4        ; [277] (unnamed)
	.long	0x002A09D8        ; [278] (unnamed)
	.long	0x002A0A00        ; [279] (unnamed)
	.long	0x002A0A28        ; [280] (unnamed)
	.long	0x002A0A50        ; [281] (unnamed)
	.long	0x002A0A78        ; [282] (unnamed)
	.long	0x002A0AA0        ; [283] (unnamed)
	.long	0x002A0AC8        ; [284] (unnamed)
	.long	0x002A0AF0        ; [285] (unnamed)
	.long	0x002A0B16        ; [286] (unnamed)
	.long	0x002A0B3A        ; [287] (unnamed)
	.long	0x002A0B60        ; [288] (unnamed)
	.long	0x002A0B86        ; [289] (unnamed)
	.long	0x002A0BAA        ; [290] (unnamed)
	.long	0x002A0BD2        ; [291] (unnamed)
	.long	0x002A0BF8        ; [292] (unnamed)
	.long	0x002A0C4A        ; [293] (unnamed)
	.long	0x002A0C9C        ; [294] (unnamed)
	.long	0x002A0CEE        ; [295] (unnamed)
	.long	0x002A0D40        ; [296] (unnamed)
	.long	0x002A0D92        ; [297] (unnamed)
	.long	0x002A0DE4        ; [298] (unnamed)
	.long	0x002A0DFE        ; [299] (unnamed)
	.long	0x002A0E3A        ; [300] (unnamed)
	.long	0x002A0E8C        ; [301] (unnamed)
	.long	0x00239E3A        ; [302] (unnamed)  -- RAM descriptor
	.long	0x002A0EA6        ; [303] (unnamed)
	.long	0x002A0ECC        ; [304] (unnamed)
	.long	0x002A0F1E        ; [305] (unnamed)
	.long	0x002A0F38        ; [306] (unnamed)
	.long	0x002A0F52        ; [307] (unnamed)
	.long	0x002A0F6C        ; [308] HDD_FLS_NAMING
	.long	0x002A0FA4        ; [309] (unnamed)
	.long	0x002A0FBE        ; [310] (unnamed)
	.long	0x002A0FD8        ; [311] (unnamed)
	.long	0x002A1004        ; [312] (unnamed)
	.long	0x002A1030        ; [313] (unnamed)
	.long	0x002A1054        ; [314] FLS_FILE_LOAD
	.long	0x002A1090        ; [315] (unnamed)
	.long	0x002A10AA        ; [316] (unnamed)
	.long	0x002A10D2        ; [317] (unnamed)
	.long	0x00239E62        ; [318] FLS_FILE_LOAD_SW_EDIT  -- RAM descriptor
	.long	0x002A10F8        ; [319] (unnamed)
	.long	0x002A111E        ; [320] (unnamed)
	.long	0x002A1148        ; [321] (unnamed)
	.long	0x002A1170        ; [322] (unnamed)
	.long	0x002A1198        ; [323] FLS_OPT_BOX
	.long	0x002A11D4        ; [324] FLS_LOC_BOX
	.long	0x002A1210        ; [325] FLS_NAME_BOX
	.long	0x002A124C        ; [326] (unnamed)
	.long	0x002A1276        ; [327] (unnamed)
	.long	0x002A12A0        ; [328] FLS_FILE_BOX
	.long	0x002A12DC        ; [329] FLS_LOAD_LINE1
	.long	0x002A12F6        ; [330] FLS_LOAD_LINE2
	.long	0x002A1310        ; [331] (unnamed)
	.long	0x002A132A        ; [332] (unnamed)
	.long	0x002A1354        ; [333] (unnamed)
	.long	0x002A137A        ; [334] FLS_DIR_SEL
	.long	0x002A13B6        ; [335] (unnamed)
	.long	0x002A13D0        ; [336] (unnamed)
	.long	0x002A13F8        ; [337] FLS_DIR_BOX
	.long	0x002A1434        ; [338] (unnamed)
	.long	0x002A1466        ; [339] (unnamed)
	.long	0x002A1498        ; [340] (unnamed)
	.long	0x002A14C2        ; [341] (unnamed)
	.long	0x002A14F4        ; [342] (unnamed)
	.long	0x002A1526        ; [343] (unnamed)
	.long	0x002A155A        ; [344] (unnamed)
	.long	0x002A1574        ; [345] FLS_FILE_SEL
	.long	0x002A15B2        ; [346] (unnamed)
	.long	0x002A15CC        ; [347] FLS_FILE_SEL_DIRBOX
	.long	0x002A1608        ; [348] FLS_FILE_SEL_LISTBOX
	.long	0x002A1644        ; [349] (unnamed)
	.long	0x002A166E        ; [350] (unnamed)
	.long	0x002A1696        ; [351] (unnamed)
	.long	0x002A16BE        ; [352] FLS_FILE_SEL_OPTBOX
	.long	0x002A16FA        ; [353] (unnamed)
	.long	0x002A1722        ; [354] (unnamed)
	.long	0x002A174A        ; [355] FLS_EDIT
	.long	0x002A1780        ; [356] (unnamed)
	.long	0x002A179A        ; [357] (unnamed)
	.long	0x002A17C4        ; [358] FLS_EDIT_NAME_BOX
	.long	0x002A1800        ; [359] (unnamed)
	.long	0x002A182A        ; [360] (unnamed)
	.long	0x002A1854        ; [361] FLS_EDIT_LIST_BOX
	.long	0x002A1890        ; [362] FLS_EDIT_LINE2
	.long	0x002A18AA        ; [363] FLS_EDIT_LINE1
	.long	0x002A18C4        ; [364] (unnamed)
	.long	0x002A18EC        ; [365] (unnamed)
	.long	0x002A1914        ; [366] (unnamed)
	.long	0x002A193C        ; [367] (unnamed)
	.long	0x002A1962        ; [368] (unnamed)
	.long	0x002A198A        ; [369] (unnamed)
	.long	0x002A19BC        ; [370] (unnamed)
	.long	0x002A19EE        ; [371] (unnamed)
	.long	0x002A1A1E        ; [372] (unnamed)
	.long	0x002A1A50        ; [373] (unnamed)
	.long	0x002A1A82        ; [374] FLS_EDIT_LOC_BOX
	.long	0x002A1ABE        ; [375] FLS_EDIT_OPT_BOX
	.long	0x002A1AFA        ; [376] (unnamed)
	.long	0x002A1B14        ; [377] (unnamed)
	.long	0x002A1B2E        ; [378] (unnamed)
	.long	0x002A1B48        ; [379] CP_FD_DIR_NAMING
	.long	0x002A1B86        ; [380] (unnamed)
	.long	0x002A1BA0        ; [381] (unnamed)
	.long	0x002A1BBA        ; [382] (unnamed)
	.long	0x002A1BE6        ; [383] (unnamed)
	.long	0x002A1C12        ; [384] (unnamed)
	.long	0x002A1C36        ; [385] (unnamed)
	.long	0x002A1C5A        ; [386] SAVE_OPT_SCREEN
	.long	0x002A1C90        ; [387] (unnamed)
	.long	0x002A1CAA        ; [388] (unnamed)
	.long	0x002A1CD2        ; [389] (unnamed)
	.long	0x002A1CFA        ; [390] (unnamed)
	.long	0x002A1D22        ; [391] (unnamed)
	.long	0x002A1D4A        ; [392] (unnamed)
	.long	0x002A1D72        ; [393] (unnamed)
	.long	0x002A1D9A        ; [394] (unnamed)
	.long	0x002A1DC2        ; [395] (unnamed)
	.long	0x002A1DEA        ; [396] (unnamed)
	.long	0x002A1E0E        ; [397] (unnamed)
	.long	0x002A1E34        ; [398] (unnamed)
	.long	0x002A1E58        ; [399] (unnamed)
	.long	0x002A1E7E        ; [400] (unnamed)
	.long	0x002A1EA4        ; [401] (unnamed)
	.long	0x002A1EC8        ; [402] (unnamed)
	.long	0x002A1EF0        ; [403] (unnamed)
	.long	0x002A1F16        ; [404] RAM_EDIT_CMP
	.long	0x002A1F68        ; [405] (unnamed)
	.long	0x002A1FA4        ; [406] RAM_EDIT_LSW
	.long	0x002A1FF6        ; [407] RAM_EDIT_PMT
	.long	0x002A2048        ; [408] RAM_EDIT_SQT
	.long	0x002A209A        ; [409] RAM_EDIT_TM
	.long	0x002A20EC        ; [410] RAM_EDIT_MSP
	.long	0x002A213E        ; [411] RAM_EDIT_RCM
	.long	0x002A2190        ; [412] RAM_EDIT_MD
	.long	0x002A21E2        ; [413] (unnamed)
	.long	0x002A21FC        ; [414] (unnamed)
	.long	0x002A2216        ; [415] (unnamed)
	.long	0x002A2230        ; [416] (unnamed)
	.long	0x002A224A        ; [417] (unnamed)
	.long	0x002A2264        ; [418] (unnamed)
	.long	0x002A228C        ; [419] (unnamed)
	.long	0x002A22B2        ; [420] (unnamed)
	.long	0x002A22DA        ; [421] (unnamed)
	.long	0x002A2302        ; [422] (unnamed)
	.long	0x002A232A        ; [423] (unnamed)
	.long	0x002A2352        ; [424] (unnamed)
	.long	0x002A237A        ; [425] (unnamed)
	.long	0x002A23A2        ; [426] RAM_EDIT_TLX
	.long	0x002A23F4        ; [427] (unnamed)
	.long	0x002A241C        ; [428] (unnamed)
	.long	0x002A2442        ; [429] (unnamed)
	.long	0x002A245C        ; [430] HddNamingWindow
	.long	0x002A2480        ; [431] (unnamed)
	.long	0x002A24A8        ; [432] (unnamed)
	.long	0x002A24CC        ; [433] (unnamed)
	.long	0x002A24F4        ; [434] (unnamed)
	.long	0x002A2518        ; [435] (unnamed)
	.long	0x002A2540        ; [436] (unnamed)
	.long	0x002A2564        ; [437] (unnamed)
	.long	0x002A258C        ; [438] (unnamed)
	.long	0x002A25B4        ; [439] (unnamed)
	.long	0x002A25DC        ; [440] (unnamed)
	.long	0x002A2604        ; [441] (unnamed)
	.long	0x002A262E        ; [442] HddNamingCursorBox
	.long	0x00239E8A        ; [443] HddNamingABC  -- RAM descriptor
	.long	0x00239EB6        ; [444] HddNamingabc  -- RAM descriptor
	.long	0x00239EE2        ; [445] HddNamingSymbol  -- RAM descriptor
	.long	0x002A266E        ; [446] (unnamed)
	.long	0x002A2696        ; [447] (unnamed)
	.long	0x002A26BE        ; [448] (unnamed)
	.long	0x002A26E6        ; [449] HddNamingLabel
	.long	0x002A270A        ; [450] FILE_DEL_SCREEN
	.long	0x002A2744        ; [451] (unnamed)
	.long	0x002A275E        ; [452] (unnamed)
	.long	0x002A2782        ; [453] (unnamed)
	.long	0x002A27A8        ; [454] (unnamed)
	.long	0x002A27CC        ; [455] (unnamed)
	.long	0x002A27F2        ; [456] (unnamed)
	.long	0x002A2818        ; [457] (unnamed)
	.long	0x002A283C        ; [458] (unnamed)
	.long	0x002A2864        ; [459] (unnamed)
	.long	0x002A288A        ; [460] (unnamed)
	.long	0x002A28A4        ; [461] (unnamed)
	.long	0x002A28BE        ; [462] (unnamed)
	.long	0x002A28D8        ; [463] DEL_EDIT_LSW
	.long	0x002A2926        ; [464] DEL_EDIT_PMT
	.long	0x002A2974        ; [465] DEL_EDIT_SQT
	.long	0x002A29C2        ; [466] DEL_EDIT_CMP
	.long	0x002A2A10        ; [467] DEL_EDIT_TM
	.long	0x002A2A5E        ; [468] DEL_EDIT_MSP
	.long	0x002A2AAC        ; [469] DEL_EDIT_RCM
	.long	0x002A2AFA        ; [470] DEL_EDIT_MD
	.long	0x002A2B48        ; [471] (unnamed)
	.long	0x002A2B70        ; [472] (unnamed)
	.long	0x002A2B98        ; [473] (unnamed)
	.long	0x002A2BC0        ; [474] (unnamed)
	.long	0x002A2BE8        ; [475] (unnamed)
	.long	0x002A2C10        ; [476] (unnamed)
	.long	0x002A2C38        ; [477] (unnamed)
	.long	0x002A2C60        ; [478] (unnamed)
	.long	0x002A2C88        ; [479] (unnamed)
	.long	0x002A2CA2        ; [480] (unnamed)
	.long	0x002A2CCA        ; [481] (unnamed)
	.long	0x002A2CEE        ; [482] (unnamed)
	.long	0x002A2D16        ; [483] (unnamed)
	.long	0x002A2D3E        ; [484] (unnamed)
	.long	0x002A2D66        ; [485] (unnamed)
	.long	0x002A2D8E        ; [486] (unnamed)
	.long	0x002A2DCA        ; [487] (unnamed)
	.long	0x002A2DF2        ; [488] (unnamed)
	.long	0x002A2E18        ; [489] DEL_EDIT_TLX
	.long	0x002A2E66        ; [490] (unnamed)
	.long	0x002A2E80        ; [491] (unnamed)
	.long	0x002A2E9A        ; [492] HDD_ICON_DISPLAY
	.long	0x002A2EBC        ; [493] HD_MENU_BMP
	.long	0x002A2ED6        ; [494] IV_HDDMENU
	.long	0x002A2EF8        ; [495] ATTEN_DEL_DIR
	.long	0x002A2F24        ; [496] (unnamed)
	.long	0x002A2F54        ; [497] (unnamed)
	.long	0x002A2F7E        ; [498] (unnamed)
	.long	0x002A2FAE        ; [499] (unnamed)
	.long	0x002A2FD8        ; [500] (unnamed)
	.long	0x002A2FF2        ; [501] (unnamed)
	.long	0x002A301C        ; [502] (unnamed)
	.long	0x002A3046        ; [503] (unnamed)
	.long	0x002A3070        ; [504] WAIT_DEL_DIR
	.long	0x002A3094        ; [505] (unnamed)
	.long	0x002A30D6        ; [506] (unnamed)
	.long	0x002A3106        ; [507] ATTEN_DEL_FILE
	.long	0x002A3132        ; [508] (unnamed)
	.long	0x002A3162        ; [509] (unnamed)
	.long	0x002A317C        ; [510] (unnamed)
	.long	0x002A31AC        ; [511] (unnamed)
	.long	0x002A31D6        ; [512] (unnamed)
	.long	0x002A3200        ; [513] (unnamed)
	.long	0x002A322A        ; [514] (unnamed)
	.long	0x002A3254        ; [515] (unnamed)
	.long	0x002A327E        ; [516] ATTEN_OVER_FLS
	.long	0x002A32AA        ; [517] (unnamed)
	.long	0x002A32C4        ; [518] (unnamed)
	.long	0x002A32F4        ; [519] (unnamed)
	.long	0x002A331E        ; [520] (unnamed)
	.long	0x002A334E        ; [521] (unnamed)
	.long	0x002A3378        ; [522] (unnamed)
	.long	0x002A33A2        ; [523] (unnamed)
	.long	0x002A33CC        ; [524] (unnamed)
	.long	0x002A33F6        ; [525] ATTEN_DEL_FLS2
	.long	0x002A3422        ; [526] (unnamed)
	.long	0x002A343C        ; [527] (unnamed)
	.long	0x002A346C        ; [528] (unnamed)
	.long	0x002A3496        ; [529] (unnamed)
	.long	0x002A34C6        ; [530] (unnamed)
	.long	0x002A34F0        ; [531] (unnamed)
	.long	0x002A351A        ; [532] (unnamed)
	.long	0x002A3544        ; [533] (unnamed)
	.long	0x002A356E        ; [534] (unnamed)
	.long	0x002A3598        ; [535] WAIT_DEL_FILE
	.long	0x002A35BC        ; [536] (unnamed)
	.long	0x002A35E6        ; [537] (unnamed)
	.long	0x002A3610        ; [538] ATTEN_HD_FORMAT
	.long	0x002A3648        ; [539] (unnamed)
	.long	0x002A3672        ; [540] (unnamed)
	.long	0x002A369C        ; [541] (unnamed)
	.long	0x002A36C6        ; [542] (unnamed)
	.long	0x002A36F0        ; [543] (unnamed)
	.long	0x002A371A        ; [544] (unnamed)
	.long	0x002A3734        ; [545] (unnamed)
	.long	0x002A376A        ; [546] HD_FORMAT_CATCH
	.long	0x002A3784        ; [547] WAIT_HD_FORMAT
	.long	0x002A37A8        ; [548] (unnamed)
	.long	0x002A37D2        ; [549] (unnamed)
	.long	0x002A37FC        ; [550] (unnamed)
	.long	0x002A3826        ; [551] SETUP_HDINFO
	.long	0x002A3852        ; [552] (unnamed)
	.long	0x002A386C        ; [553] (unnamed)
	.long	0x002A389A        ; [554] HD_INFO_LIST
	.long	0x002A38D6        ; [555] (unnamed)
	.long	0x002A38F0        ; [556] DBG_MEMO_SCREEN
	.long	0x002A392C        ; [557] (unnamed)
	.long	0x002A3946        ; [558] (unnamed)
	.long	0x002A395C        ; [559] ATTEN_DEL_FLS1
	.long	0x002A3988        ; [560] (unnamed)
	.long	0x002A39A2        ; [561] (unnamed)
	.long	0x002A39CC        ; [562] (unnamed)
	.long	0x002A39F6        ; [563] (unnamed)
	.long	0x002A3A20        ; [564] (unnamed)
	.long	0x002A3A4A        ; [565] (unnamed)
	.long	0x002A3A7A        ; [566] (unnamed)
	.long	0x002A3AA4        ; [567] (unnamed)
	.long	0x002A3AD4        ; [568] (unnamed)
	.long	0x002A3AFE        ; [569] (unnamed)
	.long	0x002A3B2E        ; [570] (unnamed)
	.long	0x002A3B58        ; [571] ATTEN_OVER_FILE
	.long	0x002A3B84        ; [572] (unnamed)
	.long	0x002A3B9E        ; [573] (unnamed)
	.long	0x002A3BCE        ; [574] (unnamed)
	.long	0x002A3BF8        ; [575] (unnamed)
	.long	0x002A3C28        ; [576] (unnamed)
	.long	0x002A3C52        ; [577] (unnamed)
	.long	0x002A3C7C        ; [578] (unnamed)
	.long	0x002A3CA6        ; [579] (unnamed)
	.long	0x002A3CD0        ; [580] HDD_FLS_NAMING2
	.long	0x002A3D08        ; [581] (unnamed)
	.long	0x002A3D22        ; [582] (unnamed)
	.long	0x002A3D3C        ; [583] (unnamed)
	.long	0x002A3D68        ; [584] (unnamed)
	.long	0x002A3D94        ; [585] (unnamed)
	.long	0x002A3DB8        ; [586] ATTEN_CPHD_WR
	.long	0x002A3DE4        ; [587] (unnamed)
	.long	0x002A3DFE        ; [588] (unnamed)
	.long	0x002A3E2E        ; [589] (unnamed)
	.long	0x002A3E58        ; [590] (unnamed)
	.long	0x002A3E82        ; [591] (unnamed)
	.long	0x002A3EAC        ; [592] (unnamed)
	.long	0x002A3ED6        ; [593] (unnamed)
	.long	0x002A3F00        ; [594] ERR_HD_NOT_FMT
	.long	0x002A3F2C        ; [595] (unnamed)
	.long	0x002A3F56        ; [596] (unnamed)
	.long	0x002A3F80        ; [597] (unnamed)
	.long	0x002A3FAA        ; [598] (unnamed)
	.long	0x002A3FD4        ; [599] ERR_HD_SRAM
	.long	0x002A4000        ; [600] (unnamed)
	.long	0x002A402A        ; [601] (unnamed)
	.long	0x002A4054        ; [602] (unnamed)
	.long	0x002A407E        ; [603] (unnamed)
	.long	0x002A40A8        ; [604] ERR_HD_RESET
	.long	0x002A40D4        ; [605] (unnamed)
	.long	0x002A40FE        ; [606] (unnamed)
	.long	0x002A4128        ; [607] (unnamed)
	.long	0x002A4152        ; [608] (unnamed)
	.long	0x002A417C        ; [609] ERR_HD_READ
	.long	0x002A41A8        ; [610] (unnamed)
	.long	0x002A41D2        ; [611] (unnamed)
	.long	0x002A41FC        ; [612] (unnamed)
	.long	0x002A4226        ; [613] (unnamed)
	.long	0x002A4250        ; [614] ERR_HD_ID_READ
	.long	0x002A427C        ; [615] (unnamed)
	.long	0x002A42A6        ; [616] (unnamed)
	.long	0x002A42D0        ; [617] (unnamed)
	.long	0x002A42FA        ; [618] (unnamed)
	.long	0x002A4324        ; [619] ERR_HD_TRACK_0
	.long	0x002A4350        ; [620] (unnamed)
	.long	0x002A437A        ; [621] (unnamed)
	.long	0x002A43A4        ; [622] (unnamed)
	.long	0x002A43CE        ; [623] (unnamed)
	.long	0x002A43F8        ; [624] ERR_HD_FAT
	.long	0x002A4424        ; [625] (unnamed)
	.long	0x002A444E        ; [626] (unnamed)
	.long	0x002A4478        ; [627] (unnamed)
	.long	0x002A44A2        ; [628] (unnamed)
	.long	0x002A44CC        ; [629] ERR_HD_FSB
	.long	0x002A44F8        ; [630] (unnamed)
	.long	0x002A4522        ; [631] (unnamed)
	.long	0x002A454C        ; [632] (unnamed)
	.long	0x002A4576        ; [633] (unnamed)
	.long	0x002A45A0        ; [634] ATTEN_CPFD_MARK
	.long	0x002A45CC        ; [635] (unnamed)
	.long	0x002A45E6        ; [636] (unnamed)
	.long	0x002A4616        ; [637] (unnamed)
	.long	0x002A4640        ; [638] (unnamed)
	.long	0x002A466A        ; [639] (unnamed)
	.long	0x002A4694        ; [640] (unnamed)
	.long	0x002A46BE        ; [641] ABOUT_HELP
	.long	0x002A46F6        ; [642] (unnamed)
	.long	0x002A4710        ; [643] (unnamed)
	.long	0x002A473A        ; [644] (unnamed)
	.long	0x002A475C        ; [645] (unnamed)
	.long	0x002A4796        ; [646] (unnamed)
	.long	0x002A47D0        ; [647] (unnamed)
	.long	0x002A47FA        ; [648] (unnamed)
	.long	0x002A4824        ; [649] (unnamed)
	.long	0x002A4862        ; [650] (unnamed)
	.long	0x002A489A        ; [651] (unnamed)
	.long	0x002A48DA        ; [652] (unnamed)
	.long	0x002A4904        ; [653] (unnamed)
	.long	0x002A492E        ; [654] (unnamed)
	.long	0x002A4958        ; [655] (unnamed)
	.long	0x002A4982        ; [656] (unnamed)
	.long	0x002A49C6        ; [657] (unnamed)
	.long	0x002A49F0        ; [658] (unnamed)
	.long	0x002A4A0A        ; [659] (unnamed)
	.long	0x002A4A34        ; [660] WAIT_TR0_RECOVER
	.long	0x002A4A58        ; [661] (unnamed)
	.long	0x002A4A82        ; [662] (unnamed)
	.long	0x002A4AAC        ; [663] ERR_SAVE
	.long	0x00239F0E        ; [664] ERR_SAVE_EXIT  -- RAM descriptor
	.long	0x002A4ACE        ; [665] ERR_SAVE_CATCH
	.long	0x002A4AE8        ; [666] (unnamed)
	.long	0x002A4B12        ; [667] (unnamed)
	.long	0x002A4B3C        ; [668] (unnamed)
	.long	0x002A4B66        ; [669] ERR_LOAD
	.long	0x00239F28        ; [670] ERR_LOAD_EXIT  -- RAM descriptor
	.long	0x002A4B88        ; [671] ERR_LOAD_CATCH
	.long	0x002A4BA2        ; [672] (unnamed)
	.long	0x002A4BCC        ; [673] (unnamed)
	.long	0x002A4BF6        ; [674] (unnamed)
	.long	0x002A4C20        ; [675] ERR_NO_HK_DATA
	.long	0x002A4C42        ; [676] (unnamed)
	.long	0x002A4C5C        ; [677] ERR_NO_HK_DATA_CATCH
	.long	0x002A4C76        ; [678] (unnamed)
	.long	0x002A4CA0        ; [679] (unnamed)
	.long	0x002A4CCA        ; [680] (unnamed)
	.long	0x002A4CF4        ; [681] ATTEN_FULL_DIR
	.long	0x002A4D16        ; [682] (unnamed)
	.long	0x002A4D30        ; [683] ATTEN_FULL_DIR_CATCH
	.long	0x002A4D4A        ; [684] (unnamed)
	.long	0x002A4D74        ; [685] (unnamed)
	.long	0x002A4D9E        ; [686] (unnamed)
	.long	0x002A4DC8        ; [687] (unnamed)
	.long	0x002A4DF2        ; [688] ATTEN_CP_UNNAMED
	.long	0x002A4E14        ; [689] (unnamed)
	.long	0x002A4E2E        ; [690] ATTEN_CP_UNNAMED_CATCH
	.long	0x002A4E48        ; [691] (unnamed)
	.long	0x002A4E72        ; [692] (unnamed)
	.long	0x002A4E9C        ; [693] (unnamed)
	.long	0x002A4EC6        ; [694] (unnamed)
	.long	0x002A4EF0        ; [695] DIR_OUT_RANGE
	.long	0x002A4F12        ; [696] DIR_OUT_RANGE_CATCH
	.long	0x002A4F2C        ; [697] (unnamed)
	.long	0x002A4F56        ; [698] (unnamed)
	.long	0x002A4F80        ; [699] (unnamed)
	.long	0x002A4FAA        ; [700] FILE_OUT_RANGE
	.long	0x002A4FCC        ; [701] FILE_OUT_RANGE_CATCH
	.long	0x002A4FE6        ; [702] (unnamed)
	.long	0x002A5010        ; [703] (unnamed)
	.long	0x002A503A        ; [704] (unnamed)
	.long	0x002A5064        ; [705] HD_PLEASE
	.long	0x002A5086        ; [706] (unnamed)
	.long	0x002A50B0        ; [707] (unnamed)
	.long	0x002A50DA        ; [708] ERR_HD_FORMAT
	.long	0x002A50FC        ; [709] (unnamed)
	.long	0x002A5116        ; [710] ERR_HD_FORMAT_CATCH
	.long	0x002A5130        ; [711] (unnamed)
	.long	0x002A515A        ; [712] (unnamed)
	.long	0x002A5184        ; [713] (unnamed)
	.long	0x002A51AE        ; [714] (unnamed)
	.long	0x002A51D8        ; [715] AGAIN_HD_FORMAT
	.long	0x002A51FA        ; [716] (unnamed)
	.long	0x002A5214        ; [717] AGAIN_HD_FORMAT_CATCH
	.long	0x002A522E        ; [718] (unnamed)
	.long	0x002A5258        ; [719] (unnamed)
	.long	0x002A5282        ; [720] (unnamed)
	.long	0x002A52AC        ; [721] (unnamed)
	.long	0x002A52D6        ; [722] SELECT_FILE_A_Z
	.long	0x002A5302        ; [723] (unnamed)
	.long	0x002A531C        ; [724] (unnamed)
	.long	0x002A5338        ; [725] (unnamed)
	.long	0x002A5354        ; [726] (unnamed)
	.long	0x002A536E        ; [727] (unnamed)
	.long	0x002A5392        ; [728] FILE_LOAD_A_Z
	.long	0x002A53B6        ; [729] (unnamed)
	.long	0x002A53DE        ; [730] (unnamed)
	.long	0x002A5408        ; [731] (unnamed)
	.long	0x002A5444        ; [732] (unnamed)
	.long	0x002A546C        ; [733] (unnamed)
	.long	0x002A5486        ; [734] (unnamed)
	.long	0x002A54B6        ; [735] (unnamed)
	.long	0x002A54DE        ; [736] (unnamed)
	.long	0x002A550A        ; [737] (unnamed)
	.long	0x002A5524        ; [738] (unnamed)
	.long	0x002A5560        ; [739] (unnamed)
	.long	0x002A559E        ; [740] (unnamed)
	.long	0x002A55CC        ; [741] (unnamed)
	.long	0x002A55E2        ; [742] (unnamed)
	.long	0x002A560C        ; [743] (unnamed)
	.long	0x002A5642        ; [744] (unnamed)
	.long	0x002A5674        ; [745] (unnamed)
	.long	0x002A56A8        ; [746] (unnamed)
	.long	0x002A56D4        ; [747] (unnamed)
	.long	0x002A570A        ; [748] (unnamed)
	.long	0x002A573C        ; [749] (unnamed)
	.long	0x002A576E        ; [750] (unnamed)
	.long	0x002A57A4        ; [751] (unnamed)
	.long	0x002A57DA        ; [752] Tech_lyrics
	.long	0x002A5810        ; [753] (unnamed)
	.long	0x002A582A        ; [754] (unnamed)
	.long	0x002A5854        ; [755] SongTitle
	.long	0x002A5878        ; [756] (unnamed)
	.long	0x002A58A2        ; [757] Conductor
	.long	0x002A58C6        ; [758] bottom01
	.long	0x002A58EA        ; [759] bottom02
	.long	0x002A590E        ; [760] bottom03
	.long	0x002A5932        ; [761] bottom04
	.long	0x002A5956        ; [762] bottom05
	.long	0x002A597A        ; [763] bottom06
	.long	0x002A599E        ; [764] bottom07
	.long	0x002A59C2        ; [765] bottom08
	.long	0x002A59E6        ; [766] (unnamed)
	.long	0x00239F42        ; [767] ChordinLyric  -- RAM descriptor
	.long	0x00239F66        ; [768] TempoinLyric  -- RAM descriptor
	.long	0x00239F8A        ; [769] MeasureinLyric  -- RAM descriptor
	.long	0x00239FAE        ; [770] TimeSigInLyric  -- RAM descriptor
	.long	0x002A5A10        ; [771] (unnamed)
	.long	0x002A5A3E        ; [772] LoadLyricFD
	.long	0x002A5A7C        ; [773] (unnamed)
	.long	0x002A5A96        ; [774] (unnamed)
	.long	0x002A5ABC        ; [775] (unnamed)
	.long	0x002A5AE2        ; [776] (unnamed)
	.long	0x002A5B02        ; [777] FD_PLEASE
	.long	0x002A5B2E        ; [778] (unnamed)
	.long	0x002A5B58        ; [779] (unnamed)
	.long	0x002A5B82        ; [780] LyrSettings
	.long	0x002A5BBC        ; [781] (unnamed)
	.long	0x002A5BD6        ; [782] (unnamed)
	.long	0x002A5C12        ; [783] (unnamed)
	.long	0x002A5C3C        ; [784] (unnamed)
	.long	0x002A5C78        ; [785] (unnamed)
	.long	0x002A5CA2        ; [786] (unnamed)
	.long	0x002A5CDE        ; [787] (unnamed)
	.long	0x002A5D08        ; [788] WriteIn
	.long	0x00000000        ; [789] end-of-table marker


; =============================================================================
; HD-AE5000 UI OBJECT NAME TABLE (0x2A6984 - 0x2A75DB)
; =============================================================================
; 790 .long pointers into HDAE5000_UiObjectName_Pool below - the symbolic name
; of every UI object in HDAE5000_UiObject_PtrTable, same index.  Registered by
; HDAE5000_Handler_Registration (hd-ae5000_v2_06i.s, "Handler 11"): object-set
; ID 0x037F, PPI port 0x0160000F, entry count 0x315 = 789, table pointer
; 0x2A6984, handler function from workspace[0x0E0A][0x0148].
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
; Layout rule, taken from the copy code inside HDAE5000_Register_Frame and
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

HDAE5000_Config_Strings:	; 0x2E1C82
	; Configuration and version strings
	.asciz "V2.06i"
	.zero 3
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	.zero 23
	.ascii "   "
	.byte 0x09
	.zero 2
	.ascii "                "
	.byte 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "   "
	.byte 0x09
	.zero 2
	.ascii "                          "
	.byte 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "            "
	.byte 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "01:        "
	.byte 0x09
	.ascii "02:        "
	.byte 0x09
	.ascii "03:        "
	.byte 0x09
	.ascii "04:        "
	.byte 0x09
	.ascii "05:        "
	.byte 0x09
	.ascii "06:        "
	.byte 0x09
	.ascii "07:        "
	.byte 0x09
	.ascii "08:        "
	.byte 0x09
	.ascii "09:        "
	.byte 0x09
	.ascii "10:        "
	.byte 0x09
	.ascii "11:        "
	.byte 0x09
	.ascii "12:        "
	.byte 0x09
	.ascii "13:        "
	.byte 0x09
	.ascii "14:        "
	.byte 0x09
	.ascii "15:        "
	.byte 0x09
	.ascii "16:        "
	.byte 0x09
	.ascii "17:        "
	.byte 0x09
	.ascii "18:        "
	.byte 0x09
	.ascii "19:        "
	.byte 0x09
	.ascii "20:        "
	.byte 0x09
	.zero 2
	.ascii "STATUS:                        "
	.byte 0x09
	.zero 14
	.ascii "("
	.byte 0x1e
	.asciz "."
	.ascii "$"
	.byte 0x1e
	.asciz "."
	.ascii " "
	.byte 0x1e
	.asciz "."
	.asciz "DEL"
	.asciz "OFF"
	.asciz "---"
	.asciz "050354"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "965768"
	nop
	popw wa
	.byte 0x1e
	.asciz "."
	.ascii "D"
	.byte 0x1e
	.asciz "."
	.asciz "ON "
	.asciz "OFF"
	.ascii "P"
	.byte 0x1e
	.asciz "."
	.ascii "01:SelectList"
	.byte 0x09
	.byte 0x30, 0x32
	.byte 0x09
	.byte 0x30, 0x33
	.byte 0x09
	.byte 0x30, 0x34
	.byte 0x09
	.byte 0x30, 0x35
	.byte 0x09
	.byte 0x30, 0x36
	.byte 0x09
	.byte 0x30, 0x37
	.byte 0x09
	.byte 0x30, 0x38
	.byte 0x09
	.byte 0x30, 0x39
	.byte 0x09
	.byte 0x31, 0x30
	.byte 0x09
	.byte 0x31, 0x31
	.byte 0x09
	.byte 0x31, 0x32
	.byte 0x09
	.byte 0x31, 0x33
	.byte 0x09
	.byte 0x31, 0x34
	.byte 0x09
	.byte 0x31, 0x35
	.byte 0x09
	.byte 0x31, 0x36
	.byte 0x09
	.byte 0x31, 0x37
	.byte 0x09
	.byte 0x31, 0x38
	.byte 0x09
	.byte 0x31, 0x39
	.byte 0x09
	.byte 0x32, 0x30
	.byte 0x09
	.byte 0x32, 0x31
	.byte 0x09
	.byte 0x32, 0x32
	.byte 0x09
	.byte 0x32, 0x33
	.byte 0x09
	.byte 0x32, 0x34
	.byte 0x09
	.byte 0x32, 0x35
	.byte 0x09
	.byte 0x32, 0x36
	.byte 0x09
	.byte 0x32, 0x37
	.byte 0x09
	.byte 0x32, 0x38
	.byte 0x09
	.byte 0x32, 0x39
	.byte 0x09
	.asciz "30"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Debug Time!"
	.byte 0xea  ; "ê"
	.byte 0x1e
	.asciz "."
	.byte 0xdc  ; "Ü"
	.byte 0x1e
	.asciz "."
	.byte 0xce  ; "Î"
	.byte 0x1e
	.asciz "."
	.asciz " !#$%&?.... "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "abc...123..."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "ABC...123..."
	.byte 0x00
	.byte 0xe2  ; "â"
	.byte 0x1f
	.asciz "."
	.byte 0xe0  ; "à"
	.byte 0x1f
	.asciz "."
	.byte 0xde  ; "Þ"
	.byte 0x1f
	.asciz "."
	.byte 0xdc  ; "Ü"
	.byte 0x1f
	.asciz "."
	.byte 0xda  ; "Ú"
	.byte 0x1f
	.asciz "."
	.byte 0xd8  ; "Ø"
	.byte 0x1f
	.asciz "."
	.byte 0xd6  ; "Ö"
	.byte 0x1f
	.asciz "."
	.byte 0xd4  ; "Ô"
	.byte 0x1f
	.asciz "."
	.byte 0xd2  ; "Ò"
	.byte 0x1f
	.asciz "."
	.byte 0xd0  ; "Ð"
	.byte 0x1f
	.asciz "."
	.byte 0xce  ; "Î"
	.byte 0x1f
	.asciz "."
	.byte 0xcc  ; "Ì"
	.byte 0x1f
	.asciz "."
	.byte 0xca  ; "Ê"
	.byte 0x1f
	.asciz "."
	.byte 0xc8  ; "È"
	.byte 0x1f
	.asciz "."
	.byte 0xc6  ; "Æ"
	.byte 0x1f
	.asciz "."
	.byte 0xc4  ; "Ä"
	.byte 0x1f
	.asciz "."
	.byte 0xc2  ; "Â"
	.byte 0x1f
	.asciz "."
	.byte 0xc0  ; "À"
	.byte 0x1f
	.asciz "."
	.byte 0xbe  ; "¾"
	.byte 0x1f
	.asciz "."
	.byte 0xbc  ; "¼"
	.byte 0x1f
	.asciz "."
	.byte 0xba  ; "º"
	.byte 0x1f
	.asciz "."
	.byte 0xb8  ; "¸"
	.byte 0x1f
	.asciz "."
	.byte 0xb6  ; "¶"
	.byte 0x1f
	.asciz "."
	.byte 0xb4  ; "´"
	.byte 0x1f
	.asciz "."
	.byte 0xb2  ; "²"
	.byte 0x1f
	.asciz "."
	.byte 0xb0  ; "°"
	.byte 0x1f
	.asciz "."
	.byte 0xae  ; "®"
	.byte 0x1f
	.asciz "."
	.byte 0xac  ; "¬"
	.byte 0x1f
	.asciz "."
	.byte 0xaa  ; "ª"
	.byte 0x1f
	.asciz "."
	.byte 0xa8  ; "¨"
	.byte 0x1f
	.asciz "."
	.byte 0xa6  ; "¦"
	.byte 0x1f
	.asciz "."
	.byte 0xa4  ; "¤"
	.byte 0x1f
	.asciz "."
	.byte 0xa2  ; "¢"
	.byte 0x1f
	.asciz "."
	.byte 0xa0  ; " "
	.byte 0x1f
	.asciz "."
	.byte 0x9e  ; ""
	.byte 0x1f
	.asciz "."
	.byte 0x9c  ; ""
	.byte 0x1f
	.asciz "."
	.byte 0x9a  ; ""
	.byte 0x1f
	.asciz "."
	.byte 0x96  ; ""
	.byte 0x1f
	.asciz "."
	.byte 0x94  ; ""
	.byte 0x1f
	.asciz "."
	.zero 2
	.asciz "SPC"
	.asciz "9"
	.asciz "8"
	.asciz "7"
	.asciz "6"
	.asciz "5"
	.asciz "4"
	.asciz "3"
	.asciz "2"
	.asciz "1"
	.asciz "0"
	.asciz "_"
	.asciz "Z"
	.asciz "Y"
	.asciz "X"
	.asciz "W"
	.asciz "V"
	.asciz "U"
	.asciz "T"
	.asciz "S"
	.asciz "R"
	.asciz "Q"
	.asciz "P"
	.asciz "O"
	.asciz "N"
	.asciz "M"
	.asciz "L"
	.asciz "K"
	.asciz "J"
	.asciz "I"
	.asciz "H"
	.asciz "G"
	.asciz "F"
	.asciz "E"
	.asciz "D"
	.asciz "C"
	.asciz "B"
	.asciz "A"
	.byte 0xce  ; "Î"
	.asciz " ."
	.byte 0xcc  ; "Ì"
	.asciz " ."
	.byte 0xca  ; "Ê"
	.asciz " ."
	.byte 0xc8  ; "È"
	.asciz " ."
	.byte 0xc6  ; "Æ"
	.asciz " ."
	.byte 0xc4  ; "Ä"
	.asciz " ."
	.byte 0xc2  ; "Â"
	.asciz " ."
	.byte 0xc0  ; "À"
	.asciz " ."
	.byte 0xbe  ; "¾"
	.asciz " ."
	.byte 0xbc  ; "¼"
	.asciz " ."
	.byte 0xba  ; "º"
	.asciz " ."
	.byte 0xb8  ; "¸"
	.asciz " ."
	.byte 0xb6  ; "¶"
	.asciz " ."
	.byte 0xb4  ; "´"
	.asciz " ."
	.byte 0xb2  ; "²"
	.asciz " ."
	.byte 0xb0  ; "°"
	.asciz " ."
	.byte 0xae  ; "®"
	.asciz " ."
	.byte 0xac  ; "¬"
	.asciz " ."
	.byte 0xaa  ; "ª"
	.asciz " ."
	.byte 0xa8  ; "¨"
	.asciz " ."
	.byte 0xa6  ; "¦"
	.asciz " ."
	.byte 0xa4  ; "¤"
	.asciz " ."
	.byte 0xa2  ; "¢"
	.asciz " ."
	.byte 0xa0  ; " "
	.asciz " ."
	.byte 0x9e  ; ""
	.asciz " ."
	.byte 0x9c  ; ""
	.asciz " ."
	.byte 0x9a  ; ""
	.asciz " ."
	.byte 0x98  ; ""
	.asciz " ."
	.byte 0x96  ; ""
	.asciz " ."
	.byte 0x94  ; ""
	.asciz " ."
	.byte 0x92  ; ""
	.asciz " ."
	.byte 0x90  ; ""
	.asciz " ."
	.byte 0x8e  ; ""
	.asciz " ."
	.byte 0x8c  ; ""
	.asciz " ."
	.byte 0x8a  ; ""
	.asciz " ."
	.byte 0x88  ; ""
	.asciz " ."
	.byte 0x86  ; ""
	.asciz " ."
	.byte 0x82  ; ""
	.asciz " ."
	.byte 0x80  ; ""
	.asciz " ."
	.zero 2
	.asciz "SPC"
	.asciz "9"
	.asciz "8"
	.asciz "7"
	.asciz "6"
	.asciz "5"
	.asciz "4"
	.asciz "3"
	.asciz "2"
	.asciz "1"
	.asciz "0"
	.asciz "_"
	.asciz "z"
	.asciz "y"
	.asciz "x"
	.asciz "w"
	.asciz "v"
	.asciz "u"
	.asciz "t"
	.asciz "s"
	.asciz "r"
	.asciz "q"
	.asciz "p"
	.asciz "o"
	.asciz "n"
	.asciz "m"
	.asciz "l"
	.asciz "k"
	.asciz "j"
	.asciz "i"
	.asciz "h"
	.asciz "g"
	.asciz "f"
	.asciz "e"
	.asciz "d"
	.asciz "c"
	.asciz "b"
	.asciz "a"
	.byte 0xa0  ; " "
	.asciz "!."
	.byte 0x9e  ; ""
	.asciz "!."
	.byte 0x9c  ; ""
	.asciz "!."
	.byte 0x9a  ; ""
	.asciz "!."
	.byte 0x98  ; ""
	.asciz "!."
	.byte 0x96  ; ""
	.asciz "!."
	.byte 0x92  ; ""
	.asciz "!."
	.byte 0x8e  ; ""
	.asciz "!."
	.byte 0x8c  ; ""
	.asciz "!."
	.byte 0x8a  ; ""
	.asciz "!."
	.byte 0x86  ; ""
	.asciz "!."
	.byte 0x82  ; ""
	.asciz "!."
	.byte 0x80  ; ""
	.asciz "!."
	.asciz "~!."
	.asciz "|!."
	.asciz "z!."
	.asciz "x!."
	.asciz "v!."
	.asciz "t!."
	.asciz "r!."
	.asciz "p!."
	.asciz "n!."
	.asciz "j!."
	.asciz "f!."
	.asciz "d!."
	.asciz "b!."
	.asciz "`!."
	.asciz "^!."
	.asciz "\\!."
	.asciz "Z!."
	.asciz "X!."
	.asciz "V!."
	.asciz "T!."
	.zero 2
	.asciz "}"
	.asciz "{"
	.asciz "]"
	.asciz "["
	.asciz ">"
	.asciz "<"
	.asciz ")"
	.asciz "("
	.asciz "~8d"
	.asciz "~8b"
	.asciz "="
	.asciz "/"
	.asciz "*"
	.asciz "-"
	.asciz "+"
	.asciz ";"
	.asciz ":"
	.asciz "."
	.asciz ","
	.asciz "`"
	.asciz "~27"
	.asciz "~22"
	.asciz "|"
	.asciz "^"
	.asciz "~5c"
	.asciz "~40"
	.asciz "?"
	.asciz "&"
	.asciz "%"
	.asciz "$"
	.asciz "#"
	.asciz "!"
	.byte 0xf8  ; "ø"
	.byte 0x1e
	.asciz "."
	.byte 0xe4  ; "ä"
	.byte 0x1f
	.asciz "."
	.byte 0xd0  ; "Ð"
	.asciz " ."
	.asciz "%"
	.asciz "%"
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "$"
	.asciz "$"
	.byte 0x1f
	.byte 0x00
	.byte 0xc4  ; "Ä"
	.asciz "!."
	.byte 0xc2  ; "Â"
	.asciz "!."
	.asciz "_"
	.asciz " "
	.zero 2
	.asciz "L"
	.byte 0x9d  ; ""
	.byte 0x00
	pop xhl
	normal
	.byte 0xb7, 0x03, 0xb5, 0x04, 0x44, 0x05, 0xd3, 0x05
	pop xhl
	.byte 0x07

HDAE5000_Test_Strings:	; 0x2E21D8
	; PPORT test and debug strings
	.asciz "Name"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Test"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "PPORT TEST"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "HDD ID READ"
	.asciz "FD TEST"
	.asciz "OK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "ERROR"
	.asciz "ERROR"
	.asciz "STOP TEST LOOP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "START TEST LOOP"
	.asciz "=======> Port Test OK"
	.asciz "=======> Port Test Error"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "HD-TYPE : "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Fre Capa: %3.1f [MB]"
	.zero 3
	.asciz "=======> HDD OK"
	.asciz "=======> HDD NG!"
	.zero 3
	.byte 0xc8  ; "È"
	.asciz "B%2.2d"
	.asciz "*.*"
	.asciz "CpHD"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "CpHD"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "WRITE PROTECTION   :ON     QUICK LOAD MODE:     1"
	.byte 0x09
	.ascii "WRITE CONFIRM      :OFF    JUMP AFTER LOAD:     2"
	.byte 0x09
	.ascii "LOAD BY NUMBER MODE:  1    FREE HDD SPACE :1251MB"
	.byte 0x09
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "     %d"
	.asciz "     %d"
	.asciz "%4ldMB"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "HDAE"
	.zero 3
	jrl	nc, 20992
	push	sr
	jrl	nc, 22272
	push	sr
	.byte 0x7f, 0x00
	pop xix
	push	sr
	.byte 0x7f, 0x00
	.ascii "a"
	.byte 0x02, 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "f"
	.byte 0x02, 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "k"
	.byte 0x02, 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "p"
	.byte 0x02, 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "u"
	.byte 0x02, 0x7f
	.zero 3
	.byte 0xc0  ; "À"
	.byte 0x01
	.byte 0xc0  ; "À"
	.byte 0x01
	.byte 0xc0  ; "À"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x01
	.byte 0xc0  ; "À"
	.byte 0x01
	.byte 0x37
	.byte 0x01
	.byte 0xfe  ; "þ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "   :                "
	.byte 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%3.3d"
	.ascii "CURRENT PANEL"
	.byte 0x09
	.ascii " PANEL MEMORY"
	.byte 0x09
	.ascii "  SEQUENCER  "
	.byte 0x09
	.ascii "  COMPOSER   "
	.byte 0x09
	.ascii " SOUND MEMORY"
	.byte 0x09
	.ascii "     MSP     "
	.byte 0x09
	.ascii "RHYTHM CUSTOM"
	.byte 0x09
	.ascii "  USER MIDI  "
	.byte 0x09
	.ascii "    LYRICS   "
	.byte 0x09
	.zero 2
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.zero 2
	.ascii "             "
	.byte 0x09
	.zero 2
	max
	normal
	.byte 0x7f, 0x00
	pop xhl
	normal
	jrl	nc, 768
	normal
	.byte 0x7f, 0x00
	pop xix
	normal
	jrl	nc, 512
	normal
	jrl	nc, 24576
	normal
	.byte 0x7f, 0x00

HDAE5000_Dir_Strings:	; 0x2E2500
	; Directory management strings
	.asciz "DIRECTORY "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%2.2d"
	.asciz ":"
	.byte 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii ":                          "
	.byte 0x09
	.zero 2
	.asciz "%2.2d"
	.byte 0x15, 0x01
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x51
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.asciz " "
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x00
	.byte 0x83  ; ""
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "DELD"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "DELF"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "UTIL"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "---[ LSW File Info. ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ SDA File Info. ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ PMT File Info. ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ SQF File Info. ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ SEQ File Info. ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ CMP File Info. ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ TM File Info. ]---"
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ MSP File Info. ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ RCM File Info. ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ MD File Info. ]---"
	.asciz "adr  : "
	.asciz "size : "
	.asciz "PCLK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "PORT IS ACTIVE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "              "
	.byte 0x00
	.byte 0xb0  ; "°"
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xb0  ; "°"
	.byte 0x00
	.byte 0x9d  ; ""
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "v'."
	.asciz "f'."
	.asciz "V'."
	.asciz "F'."
	.asciz "BASS/DRUMS MONO"
	.asciz "BASS+DRUMS MIX "
	.asciz "   DRUMS L/R   "
	.asciz "      OFF      "
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "i"
	.asciz "i"
	.asciz "i"
	.asciz "-"
	.asciz "1"
	.asciz "5"
	.asciz "<"
	.zero 2
	.asciz "B(."
	.asciz "<(."
	.asciz "6(."
	.asciz "0(."
	.asciz "*(."
	.asciz "$(."
	.byte 0x1e
	.asciz "(."
	.byte 0x18
	.asciz "(."
	.byte 0x12
	.asciz "(."
	.byte 0x0c
	.asciz "(."
	.byte 0x06
	.asciz "(."
	.byte 0x00
	.asciz "(."
	.byte 0xfa  ; "ú"
	.asciz "'."
	.byte 0xf4  ; "ô"
	.asciz "'."
	.byte 0xee  ; "î"
	.asciz "'."
	.byte 0xe8  ; "è"
	.asciz "'."
	.byte 0xe2  ; "â"
	.asciz "'."
	.asciz " 16 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " 15 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " 14 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " 13 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " 12 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " 11 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " 10 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  9 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  8 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  7 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  6 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  5 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  4 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  3 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  2 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  1 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "NONE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "l"
	.asciz "l"
	.asciz "l"
	.asciz "-"
	.asciz "4"
	.asciz "8"
	.asciz "?"
	.zero 2
	.byte 0x04
	.asciz ")."
	.byte 0xfe  ; "þ"
	.asciz "(."
	.byte 0xf8  ; "ø"
	.asciz "(."
	.byte 0xf2  ; "ò"
	.asciz "(."
	.byte 0xec  ; "ì"
	.asciz "(."
	.byte 0xe6  ; "æ"
	.asciz "(."
	.byte 0xe0  ; "à"
	.asciz "(."
	.byte 0xda  ; "Ú"
	.asciz "(."
	.byte 0xd4  ; "Ô"
	.asciz "(."
	.byte 0xce  ; "Î"
	.asciz "(."
	.byte 0xc8  ; "È"
	.asciz "(."
	.byte 0xc2  ; "Â"
	.asciz "(."
	.byte 0xbc  ; "¼"
	.asciz "(."
	.byte 0xb6  ; "¶"
	.asciz "(."
	.byte 0xb0  ; "°"
	.asciz "(."
	.byte 0xaa  ; "ª"
	.asciz "(."
	.byte 0xa4  ; "¤"
	.asciz "(."
	.asciz " 16 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " 15 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " 14 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " 13 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " 12 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " 11 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " 10 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  9 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  8 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  7 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  6 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  5 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  4 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  3 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  2 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "  1 "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "NONE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "l"
	.asciz "l"
	.asciz "l"
	.asciz "-"
	.asciz "4"
	.asciz "8"
	.asciz "?"
	.zero 2
	.asciz "6)."
	.asciz "2)."
	.asciz ".)."
	.asciz "YES"
	.asciz "NO "
	.asciz "---"
	.asciz "%s"
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x1f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "B"
	.asciz "B"
	.asciz "B"
	.asciz "#"
	.asciz "'"
	.asciz "+"
	.asciz "2"
	.zero 2
	.asciz "SVOP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.asciz "+"
	.asciz "F"
	.asciz "F"
	.asciz "F"
	.asciz "/"
	.asciz "3"
	.asciz "7"
	.asciz ">"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0"
	.asciz "4"
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "8"
	.asciz "F"
	.asciz "s"
	.asciz "z"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz "%"
	.asciz "J"
	.asciz "J"
	.asciz "J"
	.asciz ")"
	.asciz "-"
	.asciz "1"
	.asciz "8"
	.zero 2
	.asciz "%1d"
	.byte 0x19
	.byte 0x00
	.byte 0x19
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "4"
	.asciz "4"
	.asciz "4"
	.byte 0x1d
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "!"
	.asciz "%"
	.asciz ","
	.zero 2
	.asciz "%1d"
	.byte 0xb0  ; "°"
	.asciz "*."
	.byte 0xa8  ; "¨"
	.asciz "*."
	.byte 0xa0  ; " "
	.asciz "*."
	.byte 0x98  ; ""
	.asciz "*."
	.byte 0x90  ; ""
	.asciz "*."
	.asciz " YELLOW"
	.asciz " BLACK "
	.asciz " BLUE  "
	.asciz " GREEN "
	.asciz " RED   "
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "D"
	.asciz "D"
	.asciz "D"
	.asciz "-"
	.asciz "1"
	.asciz "5"
	.asciz "<"
	.zero 2
	.byte 0x04
	.asciz "+."
	.byte 0xfc  ; "ü"
	.asciz "*."
	.byte 0xf4  ; "ô"
	.asciz "*."
	.byte 0xec  ; "ì"
	.asciz "*."
	.byte 0xe4  ; "ä"
	.asciz "*."
	.asciz " YELLOW"
	.asciz " BLACK "
	.asciz " BLUE  "
	.asciz " GREEN "
	.asciz " RED   "
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "D"
	.asciz "D"
	.asciz "D"
	.asciz "-"
	.asciz "1"
	.asciz "5"
	.asciz "<"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz "%"
	.asciz "@"
	.asciz "@"
	.asciz "@"
	.asciz ")"
	.asciz "-"
	.asciz "1"
	.asciz "8"
	.zero 2
	.asciz "%1d"
	.byte 0x19
	.byte 0x00
	.byte 0x19
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "4"
	.asciz "4"
	.asciz "4"
	.byte 0x1d
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "!"
	.asciz "%"
	.asciz ","
	.zero 2
	.asciz "%1d"
	.byte 0x19
	.byte 0x00
	.byte 0x19
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "4"
	.asciz "4"
	.asciz "4"
	.byte 0x1d
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "!"
	.asciz "%"
	.asciz ","
	.zero 2
	.asciz "%1d"
	.byte 0x19
	.byte 0x00
	.byte 0x19
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "4"
	.asciz "4"
	.asciz "4"
	.byte 0x1d
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "!"
	.asciz "%"
	.asciz ","
	.zero 2
	.ascii "HD-TYPE             :                 "
	.byte 0x09
	.ascii "TRACKS              :                 "
	.byte 0x09
	.ascii "HEADS               :                 "
	.byte 0x09
	.ascii "SECTORS PER TRACK   :                 "
	.byte 0x09
	.ascii "TOTAL HD       (MB) :                 "
	.byte 0x09
	.ascii "USED BY SYSTEM (MB) :                 "
	.byte 0x09
	.ascii "FREE FOR USE   (MB) :                 "
	.byte 0x09
	.ascii "SOFTWARE RELEASE    :                 "
	.byte 0x09
	.zero 2
	.asciz "%6.1f"
	.asciz "%6.1f"
	.asciz "%6.1f"
	.zero 2
	.byte 0xc8  ; "È"
	.asciz "B"
	.byte 0x00
	.byte 0xc8  ; "È"
	.asciz "B"
	.byte 0x00
	.byte 0xc8  ; "È"
	.asciz "BFMT!"
	.zero 3
	.byte 0x13
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "&"
	.asciz "9"
	.asciz "L"
	.byte 0x90  ; ""
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "a"
	.asciz "a"
	.zero 2
	.byte 0x03
	.byte 0x00
	.byte 0x1e
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "9"
	.asciz "N"
	.asciz "i"
	.asciz "LBNS"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "4"
	.asciz "N"
	.asciz "h"
	.byte 0x82  ; ""
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.zero 2
	.asciz "LBN!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%1.1d"
	.asciz "%2.2d"
	.asciz "%3.3d"
	.asciz " %1.1d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " %2.2d"
	.zero 3
	.asciz "U"
	.byte 0x89, 0x00, 0xbd
	nop
	push_a
	normal
	popw bc
	normal
	.byte 0xbb, 0x01
	.asciz "                          "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "B"
	.asciz "F"
	.asciz "a"
	.asciz "a"
	.asciz "a"
	.asciz "J"
	.asciz "N"
	.asciz "R"
	.asciz "Y"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.ascii "   :                "
	.byte 0x09
	.byte 0x00

HDAE5000_Char_Tables:	; 0x2E2E76
	; Character set tables
	.asciz "%3.3d"
	.ascii "E"
	.byte 0x01, 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "f"
	normal
	.byte 0x7f, 0x00
	popw wa
	normal
	.byte 0x7f, 0x00
	.ascii "i"
	.byte 0x01, 0x7f
	.byte 0x00
	.byte 0x44
	.byte 0x01, 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "v"
	.byte 0x01, 0x7f
	.byte 0x00
	.byte 0x43
	.byte 0x01, 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "w"
	normal
	.byte 0x7f, 0x00
	popw bc
	normal
	.byte 0x7f, 0x00
	.ascii "k"
	normal
	.byte 0x7f, 0x00
	popw de
	normal
	.byte 0x7f, 0x00
	.ascii "j"
	.byte 0x01, 0x7f
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "FLS NAME "
	.asciz "%2.2d"
	.asciz ":"
	.byte 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii ":                                 "
	.byte 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%2.2d"
	.ascii " LOC. %3.3d/%2.2d"
	.byte 0x09
	.zero 2
	.ascii " LOC. 000/00"
	.byte 0x09
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "FLS!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "DEL1"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "DEL2"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "OVWR"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%2.2d"
	.asciz ".LSW"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".PMT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".SQT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".CMP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".TM"
	.asciz ".MSP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".RCM"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".MD"
	.asciz ".TLX"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "WrCn"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "DEL!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "'"
	.asciz "+"
	.asciz "F"
	.asciz "F"
	.asciz "F"
	.asciz "/"
	.asciz "3"
	.asciz "7"
	.asciz ">"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%"
	.asciz ")"
	.asciz "l"
	.asciz "l"
	.asciz "l"
	.asciz "-"
	.asciz ";"
	.asciz "U"
	.asciz "\\"
	.zero 2
	.asciz "TimB"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "TLBN"
	.zero 5
	normal
	normal
	normal
	nop
	push	sr
	push	sr
	push	sr
	nop
	pop	sr
	pop	sr
	pop	sr
	nop
	max
	max
	max
	nop
	halt
	halt
	halt
	nop
	ei	6
	ei	0
	reti
	reti
	reti
	nop
	ldio	8, 8
	nop
	push 9
	push 0
	.byte 0x0a, 0x0a, 0x0a, 0x00
	pushw 2827
	nop
	incf
	incf
	incf
	nop
	decf
	decf
	decf
	nop
	ret
	ret
	ret
	nop
	retd	3855
	nop
	rcf
	rcf
	rcf
	nop
	scf
	scf
	scf
	nop
	ccf
	ccf
	ccf
	nop
	zcf
	zcf
	zcf
	nop
	push_a
	push_a
	push_a
	nop
	pop_a
	pop_a
	pop_a
	nop
	ex_ff
	ex_ff
	ex_ff
	nop
	ldf	23
	ldf	0
	push_f
	push_f
	push_f
	nop
	pop_f
	pop_f
	pop_f
	nop
	jp16	6682
	nop
	jp	6939
	call16	7196
	nop
	call	7453
	calr	0x1e1e
	nop
	.byte 0x1f, 0x1f, 0x1f
	nop
	.asciz "   "
	.asciz "!!!"
	.asciz "\"\"\""
	.asciz "###"
	.asciz "$$$"
	.asciz "%%%"
	.asciz "&&&"
	.asciz "'''"
	.asciz "((("
	.asciz ")))"
	.asciz "***"
	.asciz "+++"
	.asciz ",,,"
	.asciz "---"
	.asciz "..."
	.asciz "///"
	.asciz "000"
	.asciz "111"
	.asciz "222"
	.asciz "333"
	.asciz "444"
	.asciz "555"
	.asciz "666"
	.asciz "777"
	.asciz "888"
	.asciz "999"
	.asciz ":::"
	.asciz ";;;"
	.asciz "<<<"
	.asciz "==="
	.asciz ">>>"
	.asciz "???"
	.asciz "@@@"
	.asciz "AAA"
	.asciz "BBB"
	.asciz "CCC"
	.asciz "DDD"
	.asciz "EEE"
	.asciz "FFF"
	.asciz "GGG"
	.asciz "HHH"
	.asciz "III"
	.asciz "JJJ"
	.asciz "KKK"
	.asciz "LLL"
	.asciz "MMM"
	.asciz "NNN"
	.asciz "OOO"
	.asciz "PPP"
	.asciz "QQQ"
	.asciz "RRR"
	.asciz "SSS"
	.asciz "TTT"
	.asciz "UUU"
	.asciz "VVV"
	.asciz "WWW"
	.asciz "XXX"
	.asciz "YYY"
	.asciz "ZZZ"
	.asciz "[[["
	.asciz "\\\\\\"
	.asciz "]]]"
	.asciz "^^^"
	.asciz "___"
	.asciz "```"
	.asciz "aaa"
	.asciz "bbb"
	.asciz "ccc"
	.asciz "ddd"
	.asciz "eee"
	.asciz "fff"
	.asciz "ggg"
	.asciz "hhh"
	.asciz "iii"
	.asciz "jjj"
	.asciz "kkk"
	.asciz "lll"
	.asciz "mmm"
	.asciz "nnn"
	.asciz "ooo"
	.asciz "ppp"
	.asciz "qqq"
	.asciz "rrr"
	.asciz "sss"
	.asciz "ttt"
	.asciz "uuu"
	.asciz "vvv"
	.asciz "www"
	.asciz "xxx"
	.asciz "yyy"
	.asciz "zzz"
	.asciz "{{{"
	.asciz "|||"
	.asciz "}}}"
	.asciz "~~~"
	jrl	nc, 0x7f7f
	nop
	add	w, (xwa)
	.byte 0x80, 0x00
	add	a, (xbc)
	.byte 0x81, 0x00
	add	b, (xde)
	.byte 0x82, 0x00
	add	c, (xhl)
	.byte 0x83, 0x00
	add	d, (xix)
	.byte 0x84, 0x00
	add	e, (xiy)
	.byte 0x85, 0x00
	add	h, (xiz)
	.byte 0x86, 0x00
	add	l, (xsp)
	.byte 0x87, 0x00
	add	(xwa-120), w
	nop
	add	(xbc-119), a
	nop
	add	(xde-118), b
	nop
	add	(xhl-117), c
	nop
	add	(xix-116), d
	nop
	add	(xiy-115), e
	nop
	add	(xiz-114), h
	nop
	.byte 0x8f, 0x8f, 0x8f
	nop
	adc	wa, (xwa)
	.byte 0x90, 0x00
	adc	bc, (xbc)
	.byte 0x91, 0x00
	adc	de, (xde)
	.byte 0x92, 0x00
	adc	hl, (xhl)
	.byte 0x93, 0x00
	adc	ix, (xix)
	.byte 0x94, 0x00
	adc	iy, (xiy)
	.byte 0x95, 0x00
	adc	iz, (xiz)
	.byte 0x96, 0x00, 0x97, 0x97, 0x97, 0x00
	adc	(xwa-104), wa
	nop
	adc	(xbc-103), bc
	nop
	adc	(xde-102), de
	nop
	adc	(xhl-101), hl
	nop
	adc	(xix-100), ix
	nop
	adc	(xiy-99), iy
	nop
	adc	(xiz-98), iz
	nop
	.byte 0x9f, 0x9f, 0x9f
	nop
	sub	xwa, (xwa)
	.byte 0xa0, 0x00
	sub	xbc, (xbc)
	.byte 0xa1, 0x00
	sub	xde, (xde)
	.byte 0xa2, 0x00
	sub	xhl, (xhl)
	.byte 0xa3, 0x00
	sub	xix, (xix)
	.byte 0xa4, 0x00
	sub	xiy, (xiy)
	.byte 0xa5, 0x00
	sub	xiz, (xiz)
	.byte 0xa6, 0x00
	sub	xsp, (xsp)
	.byte 0xa7, 0x00
	sub	(xwa-88), xwa
	nop
	sub	(xbc-87), xbc
	nop
	sub	(xde-86), xde
	nop
	sub	(xhl-85), xhl
	nop
	sub	(xix-84), xix
	nop
	sub	(xiy-83), xiy
	nop
	sub	(xiz-82), xiz
	nop
	sub	(xsp-81), xsp
	nop
	resm	0, (xwa)
	ld	(xwa), 177
	resm	1, (xbc)
	nop
	resm	2, (xde)
	ld	(xde), 179
	resm	3, (xhl)
	nop
	resm	4, (xix)
	ld	(xix), 181
	resm	5, (xiy)
	nop
	resm	6, (xiz)
	ld	(xiz), 183
	resm	7, (xsp)
	nop
	setm	0, (xwa-72)
	nop
	setm	1, (xbc-71)
	nop
	setm	2, (xde-70)
	nop
	setm	3, (xhl-69)
	nop
	setm	4, (xix-68)
	nop
	setm	5, (xiy-67)
	nop
	setm	6, (xiz-66)
	nop
	setm	7, (xsp-65)
	nop
	.byte 0xc0, 0xc0, 0xc0
	nop
	.byte 0xc1, 0xc1, 0xc1, 0x00
	andda8_24	c, (49858)
	.byte 0xc3, 0xc3, 0x00, 0xc4, 0xc4, 0xc4
	nop
	.byte 0xc5, 0xc5, 0xc5
	nop
	.byte 0xc6, 0xc6, 0xc6
	nop
	.byte 0xc7, 0xc7, 0xc7
	nop
	add	w, 0xc8
	nop
	adc	a, 0xc9
	nop
	sub	b, 0xca
	nop
	sbc	c, 0xcb
	nop
	and	d, 0xcc
	nop
	xor	e, 0xcd
	nop
	or	h, 0xce
	nop
	cp l, 0xcf		; "ÏÏÏ"
	nop
	.byte 0xd0, 0xd0, 0xd0
	nop
	.byte 0xd1, 0xd1, 0xd1, 0x00
	xorda16_24	hl, (53970)
	.byte 0xd3, 0xd3, 0x00, 0xd4, 0xd4, 0xd4
	nop
	.byte 0xd5, 0xd5, 0xd5
	nop
	.byte 0xd6, 0xd6, 0xd6
	nop
	.byte 0xd7, 0xd7, 0xd7
	nop
	cps	wa, 0
	.byte 0xd8, 0x00
	cps	bc, 1
	.byte 0xd9, 0x00
	cps	de, 2
	.byte 0xda, 0x00
	cps	hl, 3
	.byte 0xdb, 0x00
	cps	ix, 4
	.byte 0xdc, 0x00
	cps	iy, 5
	.byte 0xdd, 0x00
	cps	iz, 6
	.byte 0xde, 0x00, 0xdf, 0xdf, 0xdf, 0x00, 0xe0, 0xe0
	.byte 0xe0
	nop
	.byte 0xe1, 0xe1, 0xe1, 0x00
	orda32_24	xhl, (58082)
	.byte 0xe3, 0xe3, 0x00, 0xe4, 0xe4, 0xe4
	nop
	.byte 0xe5, 0xe5, 0xe5
	nop
	.byte 0xe6, 0xe6, 0xe6
	nop
	.byte 0xe7, 0xe7, 0xe7
	nop
	.byte 0xe8, 0xe8, 0xe8
	nop
	.byte 0xe9, 0xe9, 0xe9
	nop
	.byte 0xea, 0xea, 0xea
	nop
	.byte 0xeb, 0xeb, 0xeb
	nop
	sla	xix, 0xec
	nop
	sra	xiy, 0xed
	nop
	sll	xiz, 0xee
	nop
	srl	xsp, 0xef
	nop
	.byte 0xf0, 0xf0, 0xf0
	nop
	stdi8	(61937), 242
	.byte 0xf2, 0xf2, 0x00, 0xf3, 0xf3, 0xf3, 0x00, 0xf4
	.byte 0xf4, 0xf4, 0x00, 0xf5
	stib_dsp	245, 246
	.byte 0xf6, 0xf6
	nop
	ldx
	ldx
	ldx
	nop
	swi	0
	swi	0
	swi	0
	nop
	swi	1
	swi	1
	swi	1
	nop
	swi	2
	swi	2
	swi	2
	nop
	swi	3
	swi	3
	swi	3
	nop
	swi	4
	swi	4
	swi	4
	nop
	swi	5
	swi	5
	swi	5
	nop
	swi	6
	swi	6
	swi	6
	nop
	swi	7
	.fill 2, 1, 0xff
	.zero 44

HDAE5000_Path_Strings:	; 0x2E348F
	; File path and config strings
	.asciz ")BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB)"
	.asciz "BZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZB"
	.asciz "BZ{{{{"
	.zero 2
	.asciz "{{"
	.zero 4
	.asciz "{{"
	.zero 2
	.asciz "{{{"
	.zero 3
	.asciz "{{{"
	.zero 3
	.asciz "{{{{ZB"
	.ascii "BZ"
	sub	(xix-83), iy
	nop
	ldx
	ldx
	ldx
	nop
	cp	xsp, (xiy-9)
	nop
	ldx
	ldx
	.byte 0xad, 0x00, 0xf7
	ldx
	ldx
	nop
	.byte 0xad, 0xad, 0x00
	ldx
	ldx
	ldx
	nop
	.byte 0xad, 0xad, 0x00
	ldx
	ldx
	ldx
	.byte 0xad, 0xad, 0xad
	.asciz "{kB"
	.ascii "BZ{"
	.byte 0xc6, 0xc6  ; "ÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6, 0xf7, 0xc6, 0xc6, 0xc6  ; "ÆÆÆ÷ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6  ; "ÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6  ; "ÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xb5  ; "ÆÆÆÆÆµ"
	.asciz "{ZB"
	.ascii "BZ{"
	.byte 0xde, 0xde, 0xf7  ; "ÞÞ÷"
	.byte 0x00
	.zero 2
	cps	iz, 6
	cps	iz, 6
	nop
	cps	iz, 6
	.byte 0xde, 0x00
	cps	iz, 6
	.byte 0xde, 0x00
	cps	iz, 6
	nop
	cps	iz, 6
	.byte 0xde, 0x00
	cps	iz, 6
	nop
	.zero 2
	.byte 0xde, 0xde, 0xde, 0xc6  ; "ÞÞÞÆ"
	.asciz "{ZB"
	.ascii "BZ{"
	srl	xsp, 239
	ldx
	ldx
	ldx
	nop
	srl	xsp, 0xef
	nop
	srl	xsp, 0xef
	nop
	srl	xsp, 0xef
	nop
	srl	xsp, 0
	.zero 3
	.byte 0xf7, 0xef, 0xef  ; "÷ïï"
	.byte 0x00
	.byte 0xf7, 0xf7, 0xef, 0xef, 0xef, 0xc6  ; "÷÷ïïïÆ"
	.asciz "{ZB"
	.ascii ")Z{"
	.byte 0xd6, 0xd6, 0xd6, 0xd6, 0xd6, 0xd6  ; "ÖÖÖÖÖÖ"
	.byte 0x00
	.byte 0xd6, 0xd6, 0xd6  ; "ÖÖÖ"
	.byte 0x00
	.byte 0xd6, 0xd6, 0xd6  ; "ÖÖÖ"
	.byte 0x00
	.byte 0xd6, 0xd6, 0xd6  ; "ÖÖÖ"
	.byte 0x00
	.byte 0xd6, 0xd6  ; "ÖÖ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.byte 0xf7, 0xd6, 0xd6, 0xd6  ; "÷ÖÖÖ"
	.byte 0x00
	.byte 0xd6, 0xd6, 0xd6, 0xd6, 0xd6, 0xc6  ; "ÖÖÖÖÖÆ"
	.asciz "{k)"
	.ascii "BZk"
	.byte 0xc6, 0xc6  ; "ÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6  ; "ÆÆ"
	.byte 0x00
	.byte 0xc6, 0xf7  ; "Æ÷"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xb5  ; "ÆÆÆÆÆµ"
	.asciz "{Z)"
	.ascii ")Z{"
	cp	xsp, (xiy-83)
	nop
	.zero 2
	.byte 0xf7, 0xad, 0xad, 0xad  ; "÷­­­"
	.byte 0x00
	.byte 0xad, 0xad, 0xad, 0xf7  ; "­­­÷"
	.byte 0x00
	.zero 2
	ldx
	.byte 0xad, 0xad, 0x00
	cp	xsp, (xiy-83)
	nop
	.byte 0xad, 0xad, 0x00
	.zero 3
	sub	(xiy-83), xiy
	.asciz "{Z)"
	.ascii ")Z{"
	.byte 0x9c, 0x9c, 0x9c, 0xf7, 0xf7, 0xf7, 0x9c, 0x9c, 0x9c, 0x9c, 0xf7, 0x9c, 0x9c, 0x9c, 0x9c, 0xf7, 0xf7, 0xf7, 0x9c, 0x9c, 0x9c, 0xf7, 0x9c, 0x9c, 0x9c, 0xf7, 0x9c, 0x9c, 0xf7, 0xf7, 0xf7, 0xf7, 0x9c, 0x9c, 0x8c  ; "÷÷÷÷÷÷÷÷÷÷÷÷÷"
	.asciz "{Z)"

HDAE5000_UI_Icons:	; 0x2E365D
	; UI icon/pattern data with language IDs
	.asciz ")Bkk{{{kk{k{{kkk{{kkk{{kkkk{{kk{kkkkkkkB)"
	.asciz ")B)B))))))B)B)B))))B)BB)BB)B)))B)B)BB)))B"
	.zero 41
	.asciz "AcLanguage1"
	.asciz "LANENG00"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LANDEU00"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LANFRA00"
	.byte 0x00

HDAE5000_Multilingual_Messages:	; 0x2E3704
	; Trilingual UI messages (EN/DE/FR)
	.asciz "Would you really delete the selected directory?"
	.asciz "Moechten Sie das angewaehlte Verzeichnis wirklich loeschen?"
	.ascii "Voulez-vous effacer ce r"
	.byte 0xe9  ; "é"
	.asciz "pertoir?"
	.asciz "Would you really delete the selected title?"
	.asciz "Moechten Sie den angewaehlten Titel wirklich loeschen?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Voulez-vous effacer ce titre?"
	.asciz "COPY FD TO HARD DISK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "COPY FD TO HARD DISK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "COPY FD TO HARD DISK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "OUTPUT SETTING"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "OUTPUT SETTING"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "OUTPUT SETTING"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SELECT BY   NAME    "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SELECT BY   NAME    "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SELECT BY   NAME    "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LOAD BY     NUMBER"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LOAD BY     NUMBER"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LOAD BY     NUMBER"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SELECT FILE LOAD SCRIPT"
	.asciz "SELECT FILE LOAD SCRIPT"
	.asciz "SELECT FILE LOAD SCRIPT"
	.asciz "WRITE PROTECT: "
	.asciz "WRITE PROTECT: "
	.asciz "WRITE PROTECT: "
	.asciz "WRITE CONFIRM: "
	.asciz "WRITE CONFIRM: "
	.asciz "WRITE CONFIRM: "
	.asciz "ABOUT & HELP "
	.asciz "ABOUT & HELP "
	.asciz "ABOUT & HELP "
	.asciz "SAVE SETUP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SAVE SETUP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SAVE SETUP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "OUTPUT SETTING"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "OUTPUT SETTING"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "OUTPUT SETTING"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SEPARATE OUTPUT MODE:"
	.asciz "SEPARATE OUTPUT MODE:"
	.asciz "SEPARATE OUTPUT MODE:"
	.asciz "PART SELECT FOR SEQ.DRUMS OUT:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "PART SELECT FOR SEQ.DRUMS OUT:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "PART SELECT FOR SEQ.DRUMS OUT:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "PART SELECT FOR SEQ.BASS  OUT:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "PART SELECT FOR SEQ.BASS  OUT:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "PART SELECT FOR SEQ.BASS  OUT:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "! The separate outputs cannot be controlled by the internal volume control."
	.asciz "! Die separaten Ausgaenge werden nicht durch Volumen am Keyboard kontrolliert."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "! Les sortie s"
	.byte 0xe9  ; "é"
	.ascii "par"
	.byte 0xe9  ; "é"
	.ascii "es ne peuvent pas "
	.byte 0xea  ; "ê"
	.ascii "tre control"
	.byte 0xe9  ; "é"
	.asciz "es par les volume du calvier."
	.asciz "Hardware and software developement:"
	.asciz "Hardware und Software Entwicklung:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Hardware et Software developement:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Conception, marketing, sales and service:"
	.asciz "Konzeption, Marketing, Verkauf und Service:"
	.asciz "Conception, Marketing, Vente et Service:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "All rigths reserved by the called companies"
	.asciz "Alle Rechte bei den obengenannten Firmen"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "All rigths reserved by the called companies"
	.asciz "Special thanks to:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Spezieller Dank an:"
	.asciz "Special thanks to:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Press 3 digits for directory and 2 digits for the file."
	.asciz "Geben Sie 3 Ziffern fuer das Verzeichnis und 2 Ziffern fuer den Titel ein."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "Introduisez 3 chiffres pour le r"
	.byte 0xe9  ; "é"
	.asciz "pertoir at 2 chiffres pour le titre."
	.asciz "Do you really want to overwrite this FLS entry?"
	.asciz "Wollen Sie den bestehenden FLS Eintrag wirklich ueberschreiben?"
	.ascii "Voulez-vous vraiment "
	.byte 0xe9  ; "é"
	.asciz "crire par dessus le FLS?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Do you really want to delete this FLS entry?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Wollen Sie den bestehenden FLS Eintrag wirklich loeschen?"
	.asciz "Voulez-vous vraiment effacer ce FLS?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "HD FORMAT will erase all files at once."
	.asciz "HD FORMAT loescht alle Daten auf der Festplatte."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "HD-FORMAT effacera toutes les donn"
	.byte 0xe9  ; "é"
	.asciz "es de votre disque dur."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Therefore you need a 6-digit key code. Please refer your owners manual chapter SETUP & TOOLS."
	.asciz "Geben Sie auf dieser Seite den 6-stelligen Code ein. Schauen Sie in der Anleitung unter SETUP & TOOLS nach."
	.ascii "Indroduisez le code "
	.byte 0xe0  ; "à"
	.ascii " 6 chiffres et r"
	.byte 0xe9  ; "é"
	.ascii "f"
	.byte 0xe9  ; "é"
	.ascii "rez-vous "
	.byte 0xe0  ; "à"
	.asciz " votre manuel dans (SETUP & TOOLS)."
	.asciz "After your code input all data will be deleted irrevocable!"
	.asciz "Nach der Codeeingabe werden alle Daten unwiderruflich geloescht!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "Apr"
	.byte 0xe8  ; "è"
	.ascii "s l'introduction du code, toutes les donn"
	.byte 0xe9  ; "é"
	.ascii "es seront effac"
	.byte 0xe9  ; "é"
	.asciz "es."
	.asciz "You are going to delete a FLS entry. Are you sure?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Sie haben einen FLS Eintrag zum Loeschen markiert. Sind Sie sicher?"
	.asciz "Vous avez marquer un FLS connection pour effacer. Vous ait sure?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "You are going to overwrite a FLS entry. Are you sure?"
	.asciz "Sie ueberschreiben eine bestehenden FLS Eintrag. Sind Sie sicher?"
	.asciz "Voulez-vous vraiment transcrire ce FLS enregistration?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "The hard disk is write protected!"
	.ascii "Die Festplatte ist schreibgesch"
	.byte 0xfc  ; "ü"
	.asciz "tzt!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "Le disque dur est prot"
	.byte 0xe9  ; "é"
	.ascii "ger contre l'"
	.byte 0xe9  ; "é"
	.asciz "ctriture!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Please set the write protect mode to OFF."
	.asciz "Schalten Sie WRITE PROTECT im SETUP & TOOLS auf OFF."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "Pour "
	.byte 0xe9  ; "é"
	.asciz "crire mettez la protection sur OFF."
	.asciz "The hard disk is not formatted!"
	.asciz "Die Festplatte ist nicht formatiert!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "Le disque dur n'est pas format"
	.byte 0xe9  ; "é"
	.asciz "."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Hard disk SRAM error."
	.asciz "Im HD-AE5000 SRAM ist ein Fehler aufgetreten."
	.asciz "Il y a un problem avec le SRAM de HD-AE5000."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Hard disk reset error."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Die Festplatte konnte nicht initialisiert werden."
	.asciz "Votre disque dur n'est pas reconnu."
	.asciz "Hard disk read error."
	.asciz "Beim Lesen der Festplatte ist ein Fehler aufgetreten."
	.ascii "Il y a un probl"
	.byte 0xe9  ; "é"
	.asciz "me de leture du disque."
	.asciz "Hard disk ID read error."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Die ID der Festplatte konnte nicht gelesen werden."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "L'ID du disque dur n'a pas pu "
	.byte 0xea  ; "ê"
	.asciz "tre lue."
	.asciz "Hard disk track 0 error."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Track O der Festplatte konnte nicht gelesen werden."
	.ascii "La piste 0 du disque dur n'a pas pu "
	.byte 0xea  ; "ê"
	.asciz "tre lue."
	.asciz "Hard disk FAT read error."
	.asciz "Die FAT der Festplatte konnte nicht gelesen werden."
	.ascii "Le FAT du disque dur n'a pas pu "
	.byte 0xea  ; "ê"
	.asciz "tre lue."
	.asciz "Hard disk FSB read error."
	.asciz "Der FSB der Festplatte konnte nicht gelesen werden."
	.ascii "Le FSB du disque dur n'a pas pu "
	.byte 0xea  ; "ê"
	.asciz "tre lue."
	.asciz "There are no files marked for copy to HD!"
	.asciz "Es wurden keine Titel zum Kopieren gefunden."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "Aucun titre n'a "
	.byte 0xe9  ; "é"
	.ascii "t"
	.byte 0xe9  ; "é"
	.ascii " marqu"
	.byte 0xe9  ; "é"
	.asciz " pour faire des copies."
	.asciz "Please make a safety backup of your data and call your service center."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Sichern Sie alle Ihre Daten auf Diskette oder den PC und rufen Sie Ihre Service-Stelle an."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "Sauvez vos donn"
	.byte 0xe9  ; "é"
	.asciz "e sur disquette ou l'ordinateur et contactez votre service assistance."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Please make a safety backup of your data and call your service center."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Sichern Sie alle Ihre Daten auf Diskette oder den PC und rufen Sie Ihre Service-Stelle an."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "Sauvez vos donn"
	.byte 0xe9  ; "é"
	.asciz "e sur disquette ou l'ordinateur et contactez votre service assistance."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "The data on the disk you would like to copy to HD has no KN5000 format or some data are corrupted."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Die Daten auf der Diskette die Sie kopieren moechten, haben keine KN5000 ID oder sind fehlerhaft."
	.ascii "Les donn"
	.byte 0xe9  ; "é"
	.ascii "es que vous voulez charger ne sont pas du KN5000 format ou ont des d"
	.byte 0xe9  ; "é"
	.asciz "faults."
	.asciz "The number or marked songs cannot fit in the free space of the selected directory."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Im gewuenschten Verzeichnis sind nicht genuegend freie Plaetze fuer die Anzahl markierter Titel."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "Le r"
	.byte 0xe9  ; "é"
	.ascii "pertoir est satur"
	.byte 0xe9  ; "é"
	.ascii ", il n'y "
	.byte 0xe0  ; "à"
	.asciz " plus de place pour d'autres titre."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Reduce the number of selected songs or find a free directory."
	.asciz "Reduzieren Sie die Zahl der Titel oder waehlen Sie ein anderes Verzeichnis."
	.ascii "Changer de r"
	.byte 0xe9  ; "é"
	.asciz "pertoire ou supprimez des titres."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "You cannot copy files/songs to an unnamed directory."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Kopieren Sie keine Titel in ein nicht beschriftetes Verzeichnis."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "Vous ne pouvez pas copier des titres dans un r"
	.byte 0xe9  ; "é"
	.ascii "pertoire pas pr"
	.byte 0xe9  ; "é"
	.ascii "par"
	.byte 0xe9  ; "é"
	.asciz "."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Please use a named directory or create the new directory with EDIT first."
	.asciz "Waehlen Sie ein bereits beschriftetes Verzeichnis oder benennen Sie es zuvor mit EDIT."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Nommez-le d'abord par example avec EDIT."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "The DIR number is out of range."
	.asciz "Sie haben eine ungueltige Verzeichnis Nummer eingegeben."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "Le r"
	.byte 0xe9  ; "é"
	.asciz "pertoire choisi n'existe pas."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "The file number is out of range."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Die eingegebene Nummer existiert nicht."
	.asciz "Le titre choisi n'existe pas."
	.asciz "Please wait ..."
	.asciz "Bitte warten ..."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Attendre S.V.P."
	.asciz "!FORMAT ERROR!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "!FORMAT FEHLER!"
	.asciz "!FORMAT ERREUR!"
	.asciz "The automatic HD format was not successful!"
	.asciz "Die Formatierung war nicht erfolgreich!"
	.asciz "Le formatage du disque dur n'a pas pu se faire correctement!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Please try once more, refer your owners manual or ask your dealer/service center."
	.asciz "Versuchen Sie es nochmals, schauen Sie in der Anleitung nach oder rufen Sie Ihre Service-Stelle an."
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
	.asciz "Input error!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Eingabe-Fehler!"
	.asciz "Erreur d'operation!"
	.asciz "The key code input was wrong!"
	.asciz "Die Nummerneingabe war falsch!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Le cocde n'est pas correct!"
	.asciz "Please try once more, refer your owners manual or ask your dealer/service center."
	.asciz "Versuchen Sie es nochmals, schauen Sie in der Anleitung nach oder rufen Sie Ihre Service-Stelle an."
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
	.asciz "Delete file from hard disk:"
	.asciz "Loesche Titel von Festplatte:"
	.asciz "Effacer titre du disque dur:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "The hard disk will now be formatted. This procedure can take about 2-3 minutes."
	.asciz "Die Festplatte wird nun neu formatiert. Dieser Vorgang dauert ca. 2-3 Minuten."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "The hard disk will now be formatted. This procedure can take about 2-3 minutes."
	.asciz "We recommend to turn ON and OFF again the power after the complete format."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Wir empfehlen, nach der Formatierung das Keyboard aus und wieder einzuschalten."
	.asciz "We recommend to turn ON and OFF again the power after the complete format."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Track O will be recovered:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Track 0 wird kontrolliert:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Track O will be recovered:"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "The FLS entry remains free."
	.asciz "Der FLS Eintrag bleibt frei."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Ce FLS registartion reste libre."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "All following entries will be moved."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Alle nachfolgenden Eintraege werden nachgeschoben."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.ascii "Tous les registartion suivant seront d"
	.byte 0xe9  ; "é"
	.asciz "placer."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Evaluation 01-01-99"
	.asciz "Test-Version 01-01-99"
	.ascii "Version d'"
	.byte 0xe9  ; "é"
	.asciz "valuation"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LYRICS LOAD MODE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LYRICS LOAD MODE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "LYRICS LOAD MODE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "COLOR ACTIV"
	.asciz "AKTIVE FARBE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "COLOUR ACTIVE"
	.asciz "COLOR PASSIV"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "PASSIVE FARBE"
	.asciz "COLOUR PASSIVE"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "You are going to overwrite an existing entry. Are you sure?"
	.asciz "Sie ueberschreiben einen bestehenden Eintrag. Sind Sie sicher?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Vous etes en train de modifier un titre existant. Etes-vous sur?"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "YES"
	.asciz "JA"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "OUI"
	.asciz "NO"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "NEIN"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "NON"
	.asciz "OK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "OK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "OK"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "CANCEL"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Abbruch"
	.asciz "CANCEL"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Operation error!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Bedienungsfehler!"
	.asciz "Error d'operation!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "!SAVE ERROR!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "!SAVE-FEHLER!"
	.asciz "!SAVE ERREUR!"
	.asciz "!LOAD ERROR!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "!LOAD-FEHLER!"
	.asciz "!LOAD ERREUR!"
	.asciz "!SYSTEM ERROR!"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "!SYSTEM-FEHLER!"
	.asciz "!SYSTEM ERREUR!"
	.asciz "!ATTENTION!"
	.asciz "!ACHTUNG!"
	.asciz "!ATTENTION!"
	.asciz "Press YES for confirmation, NO to abort."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Bestaetigen Sie den Vorgang mit JA oder druecken Sie die NEIN Taste."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Pressez OUI pour confirmer ou NON pour annuler."
	.asciz "Please call your dealer or service center."
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Bitte rufen Sie Ihre Service-Stelle an."
	.asciz "Contactez votre service assistance."
	.asciz "No Message"
	.zero 3
	.asciz "I"
	.byte 0x92  ; ""
	.byte 0x00
	.byte 0xdb  ; "Û"
	.byte 0x00
	.byte 0x24
	.byte 0x01
	.ascii "m"
	normal
	.byte 0xb6, 0x01
	swi	7
	normal
	popw wa
	push	sr
	.byte 0x91, 0x02, 0xda, 0x02
	ldb	c, 3
	.ascii "l"
	.byte 0x03
	.byte 0xb5  ; "µ"
	.byte 0x03
	.byte 0xfe  ; "þ"
	.byte 0x03
	.byte 0x47
	.byte 0x04
	.byte 0x90  ; ""
	.byte 0x04
	.byte 0xd9  ; "Ù"
	.byte 0x04
	.byte 0x22
	.byte 0x05
	.ascii "k"
	.byte 0x05
	.byte 0xb4  ; "´"
	.byte 0x05
	.byte 0xfd  ; "ý"
	.byte 0x05
	.byte 0x46
	.byte 0x06
	.byte 0x8f  ; ""
	.byte 0x06
	.byte 0xd8  ; "Ø"
	.byte 0x06
	.byte 0x21
	.byte 0x07
	.ascii "j"
	.byte 0x07
	.byte 0xb3  ; "³"
	.byte 0x07
	.byte 0xfc  ; "ü"
	.byte 0x07
	.byte 0x45
	.byte 0x08
	.byte 0x8e  ; ""
	.byte 0x08
	.byte 0xd7  ; "×"
	.byte 0x08
	.ascii " "
	.byte 0x09
	.ascii "i"
	.byte 0x09
	.byte 0xb2  ; "²"
	.byte 0x09
	.byte 0xfb  ; "û"
	.byte 0x09
	.byte 0x44
	.byte 0x0a
	.byte 0x8d  ; ""
	.byte 0x0a
	.byte 0xd6  ; "Ö"
	.byte 0x0a, 0x1f, 0x0b
	.ascii "h"
	.byte 0x0b
	.byte 0xb1  ; "±"
	.byte 0x0b
	.byte 0xfa  ; "ú"
	.byte 0x0b
	.byte 0x43
	.byte 0x0c
	.byte 0x8c  ; ""
	.byte 0x0c
	.byte 0xd5  ; "Õ"
	.byte 0x0c, 0x1e, 0x0d
	.ascii "g"
	.byte 0x0d
	.byte 0xb0  ; "°"
	.byte 0x0d
	.byte 0xf9  ; "ù"
	.byte 0x0d
	.byte 0x42
	.byte 0x0e
	.byte 0x8b  ; ""
	.byte 0x0e
	.byte 0xd4  ; "Ô"
	.byte 0x0e, 0x1d, 0x0f
	.ascii "f"
	.byte 0x0f
	.byte 0xaf  ; "¯"
	.byte 0x0f
	.byte 0xf8  ; "ø"
	.byte 0x0f
	.byte 0x41
	.byte 0x10
	.byte 0x8a  ; ""
	.byte 0x10
	.byte 0xd3  ; "Ó"
	.byte 0x10, 0x1c, 0x11
	.ascii "e"
	.byte 0x11
	.byte 0xf1  ; "ñ"
	.byte 0x15
	.byte 0xae  ; "®"
	.byte 0x11
	.byte 0xf7  ; "÷"
	.byte 0x11
	.byte 0x40
	.byte 0x12
	.byte 0x89  ; ""
	.byte 0x12
	.byte 0xd2  ; "Ò"
	.byte 0x12, 0x1b, 0x13
	.ascii "d"
	.byte 0x13
	.byte 0xad  ; "­"
	.byte 0x13
	.byte 0xf1  ; "ñ"
	.byte 0x15
	.byte 0xf1  ; "ñ"
	.byte 0x15
	.byte 0xf6  ; "ö"
	.byte 0x13
	.byte 0x3f
	.byte 0x14
	.byte 0x88  ; ""
	.byte 0x14
	.byte 0xd1  ; "Ñ"
	.byte 0x14, 0x1a, 0x15
	.ascii "c"
	.byte 0x15
	.byte 0xaa  ; "ª"
	.byte 0x15

HDAE5000_Lang_Codes:	; 0x2E5B80
	; Language code strings and file types
	.asciz "                                        "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Reset"
	.asciz "Load"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "%03i - %i "
	.zero 3
	.asciz "}"
	.asciz "}"
	.asciz "}"
	.asciz "}"
	.asciz "}"
	.asciz "}"
	.asciz "D"
	.byte 0xaa, 0x00, 0xb0
	ei	16
	reti
	.byte 0xa2, 0x05
	pushw bc
	push	sr
	.byte 0xc5, 0x02, 0x3b, 0x05
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "TESTTEST.TLX"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "Fault : No Lyrics loaded or corrupt Data - Code %i %i %i     "
	.asciz " %i/%i "
	.asciz "Chord : %s               "
	.asciz "Info :                            "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "No Copyright Info"
	.asciz "No Song Title"
	.asciz " %i/%i "
	.zero 4
	.asciz "TLhd"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "TLtr"
	.zero 3
	.asciz "                           "
	.asciz "                           "
	.asciz "mid"
	.asciz "   "
	.asciz "                                                 "
	.asciz "%s %s"
	.asciz "%s %s"
	.asciz ".TLX"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.zero 3
	.byte 0x03, 0x03, 0x03, 0x03, 0x02, 0x02
	.zero 2
	.byte 0x01, 0x01, 0x01, 0x01, 0x02, 0x02
	.byte 0xe9  ; "é"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0x1e, 0x01
	.zero 2
	.asciz " ->"
	.asciz "*.*"
	.asciz ".TTX"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".MID"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "XLT."
	.byte 0x00
	.byte 0xbc  ; "¼"
	.asciz "]."
	.byte 0xb2  ; "²"
	.asciz "]."
	.byte 0xa8  ; "¨"
	.asciz "]."
	.byte 0x9e  ; ""
	.asciz "]."
	.byte 0x94  ; ""
	.asciz "]."
	.byte 0x8a  ; ""
	.asciz "]."
	.asciz "LANENG006"
	.asciz "LANENG005"
	.asciz "LANENG004"
	.asciz "LANFRA003"
	.asciz "LANDEU002"
	.asciz "LANENG001"
	.asciz "XAP"
	.asciz "rb"
	.byte 0x00

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
	.asciz "                "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "                "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "                          "
	.byte 0x00
	.byte 0x98, 0x8e
	.asciz "/"
	max
	nop
	push	sr
	nop
	add	(xix), iz
	.asciz "/"
	.zero 2
	push	sr
	nop
	add	(xwa), iz
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
	.asciz ".SEQ"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".SQF"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".LSW"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".PMT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".SQT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".CMP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".TM"
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".MSP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".RCM"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".MD"
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".TLX"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".TTX"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".LSW"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".PMT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".SQT"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".CMP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".TM"
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".MSP"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".RCM"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".MD"
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz ".TLX"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "rb"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "---[ GetInfoBlockPointer ]---"
	.asciz "ppib adr = %lx"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "---[ TurnHdMotorOff ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "---[ SendInfosAboutHd ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "hddname : "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "hddtrck : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "hddhead : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "hddsctr : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "hddscby : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "---[ SendInfosAboutDirBlock ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "FGB ptr : %lx"
	.asciz "FGB wid : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "FGB num : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "---[ SendInfosAboutFileSystemBlock ]---"
	.asciz "FEB ptr : %lx"
	.asciz "FEB wid : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "FEB num : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "---[ SendInfosAboutFlsBlock ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "FLS ptr : %lx"
	.asciz "FLS wid : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "FLS num : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "FLS ent : %d"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "---[ ReadDirBlockFromHd ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "---[ ReadFileBlockFromHd ]---"
	.asciz " "
	.asciz "---[ ReadFlsBlockFromHd ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "---[ WriteDirBlockToHd ]---"
	.asciz " "
	.asciz "---[ WriteFileSystemBlockToHd ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "---[ WriteFlsBlockToHd ]---"
	.asciz " "
	.asciz "---[ SendInfosAboutSong ]--- "
	.asciz "dirname : %s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "sngname : %s"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "---[ LoadSongFromHdToMemory ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "---[ SaveSongInMemoryToHd ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "---[ InitWholeSongInMemory ]---"
	.asciz " "
	.asciz "---[ FormatHd ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "---[ SendPointerToFreeBufferSpace ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "work adr : %lx"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "---[ PreWholeSongInMemory ]---"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz " "
	.asciz "---[ WriteOpenHD ]--- "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "SUFFIX : %d"
	.asciz "---[ WriteCloseHD ]--- "
	.asciz "---[ WriteFileHD ]--- "
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "---[ ReadOpenHD ]--- "
	.asciz "---[ ReadFileHD ]--- "
	.ascii "         (((((                  H"
	.byte 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x84
	.byte 0x84, 0x84, 0x84, 0x84, 0x84, 0x84, 0x84, 0x84, 0x84, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10
	.byte 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10
	.byte 0x82, 0x82, 0x82, 0x82, 0x82, 0x82, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02
	.byte 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x10, 0x10, 0x10, 0x10
	.asciz " "
	.zero 129
	.byte 0x0d, 0x01, 0x8a, 0x06, 0x8a, 0x06, 0x8a, 0x06, 0xe1, 0x06, 0x0d, 0x01, 0xe1, 0x06, 0xe1, 0x06
	.byte 0xe1, 0x06, 0xe1, 0x06
	.ascii "f"
	.byte 0x06, 0x1a, 0x05, 0xaf, 0x03, 0xe1, 0x06, 0xe1, 0x06
	.asciz "i"
	.byte 0xe1, 0x06, 0xb9, 0x02, 0xe1, 0x06, 0xe1, 0x06, 0xb2, 0x03
	.asciz "0123456789abcdef"
	.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)
	.asciz "0123456789ABCDEF"
	.byte 0x00

	.include "hdae5000_init_data.s"

; ============================================================================
; END OF ROM (0x300000)
; ============================================================================

end:

; Labels emitted as .set (exact addresses from ORG/name)
