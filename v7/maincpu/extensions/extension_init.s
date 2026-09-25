; =============================================================================
; Extension Device Registration (internal codename: "TOSHI")
; =============================================================================
;
; This subsystem registers expansion slot devices (such as the HD-AE5000 hard
; disk board) with the main firmware. It creates object tables, titles, and
; modes for each device so that the UI framework can present extension-specific
; screens and route events to extension handlers.
;
; "TOSHI" is the Matsushita/Technics developer codename for this subsystem.
; All original symbol names (InitializeToshi, etc.) are preserved.
;
; Files in this directory:
;   extension_init.s  - InitializeToshi(): 70+ RegisterObjectTable calls
;   extension_data.s  - Extension device data tables and NAKA descriptors
; =============================================================================

; -----------------------------------------------------------------------------
; The 30 viewable-object tables (ViewableProc, registry slot N) and their
; parallel resource-name tables (ResNameProc, slot N + 0x300) that
; InitializeToshi registers lie inside NakaInst_ExtDevice_Screens
; (ui_widgets/extension_device_screens.s, compiled from naka_extension_device.c),
; which carries no labels at these offsets, so they are named here as offsets
; from it.  Each table is `count` 4-byte pointers plus a NULL (the names: string
; pointers, most of them to "").  The suffix is the title RegTitle registers
; for the same index N below ("TT_CTMENU" for 0x40); slot 0x46 (CTPMPARA) is
; registered with count 0 and holds only the NULL.  Offsets checked against the
; v10 dump; the tables sit at the same addresses in v9 and v7.
; -----------------------------------------------------------------------------
Toshi_Viewable_NORMAL     = NakaInst_ExtDevice_Screens + 0x1002	; slot 0x001, 63 entries
Toshi_ResName_NORMAL      = NakaInst_ExtDevice_Screens + 0x168a	; slot 0x301, 63 entries
Toshi_Viewable_CTMENU     = NakaInst_ExtDevice_Screens + 0x1102	; slot 0x040, 9 entries
Toshi_ResName_CTMENU      = NakaInst_ExtDevice_Screens + 0x182a	; slot 0x340, 9 entries
Toshi_Viewable_CTINIT     = NakaInst_ExtDevice_Screens + 0x112a	; slot 0x041, 17 entries
Toshi_ResName_CTINIT      = NakaInst_ExtDevice_Screens + 0x1870	; slot 0x341, 17 entries
Toshi_Viewable_CTFSWAS    = NakaInst_ExtDevice_Screens + 0x1172	; slot 0x042, 6 entries
Toshi_ResName_CTFSWAS     = NakaInst_ExtDevice_Screens + 0x18f6	; slot 0x342, 6 entries
Toshi_Viewable_CTTOUCH    = NakaInst_ExtDevice_Screens + 0x118e	; slot 0x043, 8 entries
Toshi_ResName_CTTOUCH     = NakaInst_ExtDevice_Screens + 0x192a	; slot 0x343, 8 entries
Toshi_Viewable_MSAMODE    = NakaInst_ExtDevice_Screens + 0x11b2	; slot 0x044, 19 entries
Toshi_ResName_MSAMODE     = NakaInst_ExtDevice_Screens + 0x196a	; slot 0x344, 19 entries
Toshi_Viewable_CTPMMD     = NakaInst_ExtDevice_Screens + 0x1202	; slot 0x045, 19 entries
Toshi_ResName_CTPMMD      = NakaInst_ExtDevice_Screens + 0x19e2	; slot 0x345, 19 entries
Toshi_Viewable_CTPMPARA   = NakaInst_ExtDevice_Screens + 0x1252	; slot 0x046, 0 entries
Toshi_ResName_CTPMPARA    = NakaInst_ExtDevice_Screens + 0x1a62	; slot 0x346, 0 entries
Toshi_Viewable_CTSYSTEM   = NakaInst_ExtDevice_Screens + 0x1256	; slot 0x047, 7 entries
Toshi_ResName_CTSYSTEM    = NakaInst_ExtDevice_Screens + 0x1a68	; slot 0x347, 7 entries
Toshi_Viewable_CTWALLSET  = NakaInst_ExtDevice_Screens + 0x1276	; slot 0x048, 25 entries
Toshi_ResName_CTWALLSET   = NakaInst_ExtDevice_Screens + 0x1aa2	; slot 0x348, 25 entries
Toshi_Viewable_ONETCH     = NakaInst_ExtDevice_Screens + 0x12de	; slot 0x0c0, 4 entries
Toshi_ResName_ONETCH      = NakaInst_ExtDevice_Screens + 0x1b56	; slot 0x3c0, 4 entries
Toshi_Viewable_MUSICSTYL  = NakaInst_ExtDevice_Screens + 0x12f2	; slot 0x0c1, 4 entries
Toshi_ResName_MUSICSTYL   = NakaInst_ExtDevice_Screens + 0x1b7a	; slot 0x3c1, 4 entries
Toshi_Viewable_MSCTSEL    = NakaInst_ExtDevice_Screens + 0x1306	; slot 0x0c2, 20 entries
Toshi_ResName_MSCTSEL     = NakaInst_ExtDevice_Screens + 0x1ba0	; slot 0x3c2, 20 entries
Toshi_Viewable_MSSCTSEL   = NakaInst_ExtDevice_Screens + 0x135a	; slot 0x0c3, 17 entries
Toshi_ResName_MSSCTSEL    = NakaInst_ExtDevice_Screens + 0x1c30	; slot 0x3c3, 17 entries
Toshi_Viewable_MSSONGLIST = NakaInst_ExtDevice_Screens + 0x13a2	; slot 0x0c4, 8 entries
Toshi_ResName_MSSONGLIST  = NakaInst_ExtDevice_Screens + 0x1cac	; slot 0x3c4, 8 entries
Toshi_Viewable_MSALPSEL   = NakaInst_ExtDevice_Screens + 0x13c6	; slot 0x0c5, 7 entries
Toshi_ResName_MSALPSEL    = NakaInst_ExtDevice_Screens + 0x1cec	; slot 0x3c5, 7 entries
Toshi_Viewable_PMBKSEL    = NakaInst_ExtDevice_Screens + 0x13e6	; slot 0x0d0, 6 entries
Toshi_ResName_PMBKSEL     = NakaInst_ExtDevice_Screens + 0x1d24	; slot 0x3d0, 6 entries
Toshi_Viewable_PMVIEW     = NakaInst_ExtDevice_Screens + 0x1402	; slot 0x0d1, 13 entries
Toshi_ResName_PMVIEW      = NakaInst_ExtDevice_Screens + 0x1d54	; slot 0x3d1, 13 entries
Toshi_Viewable_PMNAME     = NakaInst_ExtDevice_Screens + 0x143a	; slot 0x0d2, 7 entries
Toshi_ResName_PMNAME      = NakaInst_ExtDevice_Screens + 0x1dae	; slot 0x3d2, 7 entries
Toshi_Viewable_PMBKNAME   = NakaInst_ExtDevice_Screens + 0x145a	; slot 0x0d3, 7 entries
Toshi_ResName_PMBKNAME    = NakaInst_ExtDevice_Screens + 0x1de4	; slot 0x3d3, 7 entries
Toshi_Viewable_SVARI      = NakaInst_ExtDevice_Screens + 0x147a	; slot 0x0e8, 2 entries
Toshi_ResName_SVARI       = NakaInst_ExtDevice_Screens + 0x1e1c	; slot 0x3e8, 2 entries
Toshi_Viewable_RVARI      = NakaInst_ExtDevice_Screens + 0x1486	; slot 0x0e9, 3 entries
Toshi_ResName_RVARI       = NakaInst_ExtDevice_Screens + 0x1e32	; slot 0x3e9, 3 entries
Toshi_Viewable_TEST1      = NakaInst_ExtDevice_Screens + 0x1496	; slot 0x0f4, 14 entries
Toshi_ResName_TEST1       = NakaInst_ExtDevice_Screens + 0x1e4e	; slot 0x3f4, 14 entries
Toshi_Viewable_TEST2      = NakaInst_ExtDevice_Screens + 0x14d2	; slot 0x0f5, 23 entries
Toshi_ResName_TEST2       = NakaInst_ExtDevice_Screens + 0x1eb6	; slot 0x3f5, 23 entries
Toshi_Viewable_TEST3      = NakaInst_ExtDevice_Screens + 0x1532	; slot 0x0f6, 1 entries
Toshi_ResName_TEST3       = NakaInst_ExtDevice_Screens + 0x1f6a	; slot 0x3f6, 1 entries
Toshi_Viewable_TEST4      = NakaInst_ExtDevice_Screens + 0x153a	; slot 0x0f7, 3 entries
Toshi_ResName_TEST4       = NakaInst_ExtDevice_Screens + 0x1f7a	; slot 0x3f7, 3 entries
Toshi_Viewable_TEST5      = NakaInst_ExtDevice_Screens + 0x154a	; slot 0x0f8, 67 entries
Toshi_ResName_TEST5       = NakaInst_ExtDevice_Screens + 0x1f96	; slot 0x3f8, 67 entries
Toshi_Viewable_TEST6      = NakaInst_ExtDevice_Screens + 0x165a	; slot 0x0f9, 9 entries
Toshi_ResName_TEST6       = NakaInst_ExtDevice_Screens + 0x2156	; slot 0x3f9, 9 entries
Toshi_Viewable_EXT        = NakaInst_ExtDevice_Screens + 0x1682	; slot 0x0fb, 1 entries
Toshi_ResName_EXT         = NakaInst_ExtDevice_Screens + 0x21a2	; slot 0x3fb, 1 entries

InitializeToshi:
	lda xsp, (xsp - 14)

	RegObjTable 0x1600004, ClassProc, Toshi_Class_Count, Toshi_Class_Table, 0x162
	RegObjTable 0x160000c, ResEventProc, Toshi_ResEvent_Count, Toshi_ResEvent_Table, 0x1c2
	RegObjTable 0x160000d, ResMethodProc, Toshi_ResMethod_Count, Toshi_ResMethod_Table, 0x1e2
	RegObjTabl 0x1600002, ApFunctionProc, 0x2a, Toshi_ApFunction_Table, 0x122
	RegObjTabl 0x1600002, ApFunctionProc, 0x2a, Toshi_ApFunctionName_Table, 0x422
	RegObjTabl 0x1600001, FunctionProc, 0x1c, Toshi_Function_Table, 0x102
	RegObjTabl 0x1600001, FunctionProc, 0x1c, Toshi_FunctionName_Table, 0x402
	RegObjTabl 0x1600003, MainFunctionProc, 0x14, Toshi_MainFunction_Table, 0x142
	RegObjTabl 0x1600003, MainFunctionProc, 0x14, Toshi_MainFunctionName_Table, 0x442
	RegObjTabl 0x1600010, ViewableProc, 0x3f, Toshi_Viewable_NORMAL, 0x1
	RegObjTabl 0x160000f, ResNameProc, 0x3f, Toshi_ResName_NORMAL, 0x301
	RegObjTabl 0x1600010, ViewableProc, 0x9, Toshi_Viewable_CTMENU, 0x40
	RegObjTabl 0x160000f, ResNameProc, 0x9, Toshi_ResName_CTMENU, 0x340
	RegObjTabl 0x1600010, ViewableProc, 0x11, Toshi_Viewable_CTINIT, 0x41
	RegObjTabl 0x160000f, ResNameProc, 0x11, Toshi_ResName_CTINIT, 0x341
	RegObjTabl 0x1600010, ViewableProc, 0x6, Toshi_Viewable_CTFSWAS, 0x42
	RegObjTabl 0x160000f, ResNameProc, 0x6, Toshi_ResName_CTFSWAS, 0x342
	RegObjTabl 0x1600010, ViewableProc, 0x8, Toshi_Viewable_CTTOUCH, 0x43
	RegObjTabl 0x160000f, ResNameProc, 0x8, Toshi_ResName_CTTOUCH, 0x343
	RegObjTabl 0x1600010, ViewableProc, 0x13, Toshi_Viewable_MSAMODE, 0x44
	RegObjTabl 0x160000f, ResNameProc, 0x13, Toshi_ResName_MSAMODE, 0x344
	RegObjTabl 0x1600010, ViewableProc, 0x13, Toshi_Viewable_CTPMMD, 0x45
	RegObjTabl 0x160000f, ResNameProc, 0x13, Toshi_ResName_CTPMMD, 0x345
	RegObjTabl 0x1600010, ViewableProc, 0x0, Toshi_Viewable_CTPMPARA, 0x46
	RegObjTabl 0x160000f, ResNameProc, 0x0, Toshi_ResName_CTPMPARA, 0x346
	RegObjTabl 0x1600010, ViewableProc, 0x7, Toshi_Viewable_CTSYSTEM, 0x47
	RegObjTabl 0x160000f, ResNameProc, 0x7, Toshi_ResName_CTSYSTEM, 0x347
	RegObjTabl 0x1600010, ViewableProc, 0x19, Toshi_Viewable_CTWALLSET, 0x48
	RegObjTabl 0x160000f, ResNameProc, 0x19, Toshi_ResName_CTWALLSET, 0x348
	RegObjTabl 0x1600010, ViewableProc, 0x4, Toshi_Viewable_ONETCH, 0xc0
	RegObjTabl 0x160000f, ResNameProc, 0x4, Toshi_ResName_ONETCH, 0x3c0
	RegObjTabl 0x1600010, ViewableProc, 0x4, Toshi_Viewable_MUSICSTYL, 0xc1
	RegObjTabl 0x160000f, ResNameProc, 0x4, Toshi_ResName_MUSICSTYL, 0x3c1
	RegObjTabl 0x1600010, ViewableProc, 0x14, Toshi_Viewable_MSCTSEL, 0xc2
	RegObjTabl 0x160000f, ResNameProc, 0x14, Toshi_ResName_MSCTSEL, 0x3c2
	RegObjTabl 0x1600010, ViewableProc, 0x11, Toshi_Viewable_MSSCTSEL, 0xc3
	RegObjTabl 0x160000f, ResNameProc, 0x11, Toshi_ResName_MSSCTSEL, 0x3c3
	RegObjTabl 0x1600010, ViewableProc, 0x8, Toshi_Viewable_MSSONGLIST, 0xc4
	RegObjTabl 0x160000f, ResNameProc, 0x8, Toshi_ResName_MSSONGLIST, 0x3c4
	RegObjTabl 0x1600010, ViewableProc, 0x7, Toshi_Viewable_MSALPSEL, 0xc5
	RegObjTabl 0x160000f, ResNameProc, 0x7, Toshi_ResName_MSALPSEL, 0x3c5
	RegObjTabl 0x1600010, ViewableProc, 0x6, Toshi_Viewable_PMBKSEL, 0xd0
	RegObjTabl 0x160000f, ResNameProc, 0x6, Toshi_ResName_PMBKSEL, 0x3d0
	RegObjTabl 0x1600010, ViewableProc, 0xd, Toshi_Viewable_PMVIEW, 0xd1
	RegObjTabl 0x160000f, ResNameProc, 0xd, Toshi_ResName_PMVIEW, 0x3d1
	RegObjTabl 0x1600010, ViewableProc, 0x7, Toshi_Viewable_PMNAME, 0xd2
	RegObjTabl 0x160000f, ResNameProc, 0x7, Toshi_ResName_PMNAME, 0x3d2
	RegObjTabl 0x1600010, ViewableProc, 0x7, Toshi_Viewable_PMBKNAME, 0xd3
	RegObjTabl 0x160000f, ResNameProc, 0x7, Toshi_ResName_PMBKNAME, 0x3d3
	RegObjTabl 0x1600010, ViewableProc, 0x2, Toshi_Viewable_SVARI, 0xe8
	RegObjTabl 0x160000f, ResNameProc, 0x2, Toshi_ResName_SVARI, 0x3e8
	RegObjTabl 0x1600010, ViewableProc, 0x3, Toshi_Viewable_RVARI, 0xe9
	RegObjTabl 0x160000f, ResNameProc, 0x3, Toshi_ResName_RVARI, 0x3e9
	RegObjTabl 0x1600010, ViewableProc, 0xe, Toshi_Viewable_TEST1, 0xf4
	RegObjTabl 0x160000f, ResNameProc, 0xe, Toshi_ResName_TEST1, 0x3f4
	RegObjTabl 0x1600010, ViewableProc, 0x17, Toshi_Viewable_TEST2, 0xf5
	RegObjTabl 0x160000f, ResNameProc, 0x17, Toshi_ResName_TEST2, 0x3f5
	RegObjTabl 0x1600010, ViewableProc, 0x1, Toshi_Viewable_TEST3, 0xf6
	RegObjTabl 0x160000f, ResNameProc, 0x1, Toshi_ResName_TEST3, 0x3f6
	RegObjTabl 0x1600010, ViewableProc, 0x3, Toshi_Viewable_TEST4, 0xf7
	RegObjTabl 0x160000f, ResNameProc, 0x3, Toshi_ResName_TEST4, 0x3f7
	RegObjTabl 0x1600010, ViewableProc, 0x43, Toshi_Viewable_TEST5, 0xf8
	RegObjTabl 0x160000f, ResNameProc, 0x43, Toshi_ResName_TEST5, 0x3f8
	RegObjTabl 0x1600010, ViewableProc, 0x9, Toshi_Viewable_TEST6, 0xf9
	RegObjTabl 0x160000f, ResNameProc, 0x9, Toshi_ResName_TEST6, 0x3f9
	RegObjTabl 0x1600010, ViewableProc, 0x1, Toshi_Viewable_EXT, 0xfb
	RegObjTabl 0x160000f, ResNameProc, 0x1, Toshi_ResName_EXT, 0x3fb

	; RegMode / RegTitle push 0x0002 and then the 32-bit address of a name
	; string as two words (high 0x00ed, then low), because the macros take the
	; halves separately -- the assembler cannot split a symbol into halves, so
	; each name is given in a comment.  All the strings are in
	; NakaInst_ExtDevice_Screens.  RegisterMode (ui/ui_widget_defs.s) stores
	; {XBC, XDE, word 2, name} in a 14-byte slot of the mode table at RAM
	; 0x328FC indexed by XWA; RegisterTitle stores the same four fields in a
	; 22-byte slot of the title table at RAM 0x32ABC, again indexed by XWA --
	; the index each Toshi_Viewable_* table above is registered under.
	RegMode 0x2, 0xed, 0x897c, 0x1, 0x1200000, 0x1a00001	; "MD_NORMAL"
	RegMode 0x2, 0xed, 0x8986, 0x4, 0x1200000, 0x1a00040	; "MD_CONTROL"
	RegMode 0x2, 0xed, 0x8992, 0x12, 0x1200000, 0x1a000c0	; "MD_OTP"
	RegTitle 0x2, 0xed, 0x899a, 0x1, 0x1200000, 0x10001	; "TT_NORMAL"
	RegTitle 0x2, 0xed, 0x89a4, 0x40, 0x1200000, 0x400000	; "TT_CTMENU"
	RegTitle 0x2, 0xed, 0x89ae, 0x41, 0x142000b, 0x410000	; "TT_CTINIT"
	RegTitle 0x2, 0xed, 0x89b8, 0x42, 0x142000c, 0x420000	; "TT_CTFSWAS"
	RegTitle 0x2, 0xed, 0x89c4, 0x43, 0x1200000, 0x430000	; "TT_CTTOUCH"
	RegTitle 0x2, 0xed, 0x89d0, 0x44, 0x1200000, 0x440000	; "TT_MSAMODE"
	RegTitle 0x2, 0xed, 0x89dc, 0x45, 0x1200000, 0x450000	; "TT_CTPMMD"
	RegTitle 0x2, 0xed, 0x89e6, 0x46, 0x1200000, 0x410000	; "TT_CTPMPARA"
	RegTitle 0x2, 0xed, 0x89f2, 0x47, 0x1200000, 0x470000	; "TT_CTSYSTEM"
	RegTitle 0x2, 0xed, 0x89fe, 0x48, 0x1200000, 0x480002	; "TT_CTWALLSET"
	RegTitle 0x2, 0xed, 0x8a0c, 0xc0, 0x1420009, 0xc00000	; "TT_ONETCH"
	RegTitle 0x2, 0xed, 0x8a16, 0xc1, 0x1200000, 0xc10000	; "TT_MUSICSTYL"
	RegTitle 0x2, 0xed, 0x8a24, 0xc2, 0x1200000, 0xc20000	; "TT_MSCTSEL"
	RegTitle 0x2, 0xed, 0x8a30, 0xc3, 0x1200000, 0xc30000	; "TT_MSSCTSEL"
	RegTitle 0x2, 0xed, 0x8a3c, 0xc4, 0x1200000, 0xc40000	; "TT_MSSONGLIST"
	RegTitle 0x2, 0xed, 0x8a4a, 0xc5, 0x1200000, 0xc50000	; "TT_MSALPSEL"
	RegTitle 0x2, 0xed, 0x8a56, 0xd0, 0x1200000, 0xd00000	; "TT_PMBKSEL"
	RegTitle 0x2, 0xed, 0x8a62, 0xd1, 0x1200000, 0xd10000	; "TT_PMVIEW"
	RegTitle 0x2, 0xed, 0x8a6c, 0xd2, 0x1200000, 0xd20000	; "TT_PMNAME"
	RegTitle 0x2, 0xed, 0x8a76, 0xd3, 0x1200000, 0xd30000	; "TT_PMBKNAME"
	RegTitle 0x2, 0xed, 0x8a82, 0xe8, 0x1200000, 0xe80000	; "TT_SVARI"
	RegTitle 0x2, 0xed, 0x8a8c, 0xe9, 0x1200000, 0xe90000	; "TT_RVARI"
	RegTitle 0x2, 0xed, 0x8a96, 0xf4, 0x1200000, 0xf40000	; name "TT_TEST1" = 0xED8A96, NakaInst_ExtDevice_Screens + 0x22CA
	RegTitle 0x2, 0xed, 0x8aa0, 0xf5, 0x1420010, 0xf50000	; name "TT_TEST2" = 0xED8AA0, NakaInst_ExtDevice_Screens + 0x22D4
	RegTitle 0x2, 0xed, 0x8aaa, 0xf6, 0x1420011, 0xf60000	; name "TT_TEST3" = 0xED8AAA, NakaInst_ExtDevice_Screens + 0x22DE
	RegTitle 0x2, 0xed, 0x8ab4, 0xf7, 0x1420012, 0xf70000	; name "TT_TEST4" = 0xED8AB4, NakaInst_ExtDevice_Screens + 0x22E8
	RegTitle 0x2, 0xed, 0x8abe, 0xf8, 0x1200000, 0xf80000	; name "TT_TEST5" = 0xED8ABE, NakaInst_ExtDevice_Screens + 0x22F2
	RegTitle 0x2, 0xed, 0x8ac8, 0xf9, 0x1420013, 0xf90000	; name "TT_TEST6" = 0xED8AC8, NakaInst_ExtDevice_Screens + 0x22FC
	RegTitle 0x2, 0xed, 0x8ad2, 0xfb, 0x1200000, 0xfb0000	; "TT_EXT"
	lda xsp, (xsp + 14)
	ret
