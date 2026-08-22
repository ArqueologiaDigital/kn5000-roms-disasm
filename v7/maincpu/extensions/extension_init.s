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

InitializeToshi:
	lda xsp, (xsp - 0x0e)
	lda XBC, (XSP)
	ld XWA,0x01600004
	ld (XBC),XWA
	lda_24 xwa, (ClassProc)
	ld (XBC+0x04),XWA
	ldw_da wa, (0xed2d02)
	ld (XBC+0x08),WA
	lda_24 xwa, (ExtData_NormScreenProc_Ptr)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0162
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000c
	ld (XBC),XWA
	lda_24 xwa, (ResEventProc)
	ld (XBC+0x04),XWA
	ldw_da wa, (0xed2d92)
	ld (XBC+0x08),WA
	lda_24 xwa, (0xed2d04)
	ld (XBC+0x0a),XWA
	ldw WA, 0x01c2
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000d
	ld (XBC),XWA
	lda_24 xwa, (ResMethodProc)
	ld (XBC+0x04),XWA
	ldw_da wa, (0xed2f64)
	ld (XBC+0x08),WA
	lda_24 xwa, (0xed2d94)
	ld (XBC+0x0a),XWA
	ldw WA, 0x01e2
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600002
	ld (XBC),XWA
	lda_24 xwa, (ApFunctionProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x002a
	lda_24 xwa, (KeyScaleNoteStr_G_PtrTable)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0122
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600002
	ld (XBC),XWA
	lda_24 xwa, (ApFunctionProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x002a
	lda_24 xwa, (NoteNameStr_Table_5)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0422
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600001
	ld (XBC),XWA
	lda_24 xwa, (FunctionProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x001c
	lda_24 xwa, (MethodNameStr_MT_SvariIni_PtrTable)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0102
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600001
	ld (XBC),XWA
	lda_24 xwa, (FunctionProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x001c
	lda_24 xwa, (NoteNameStr_Table_7)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0402
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600003
	ld (XBC),XWA
	lda_24 xwa, (MainFunctionProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0014
	lda_24 xwa, (ProcNameStr_NormScreenProc_PtrTable)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0142
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600003
	ld (XBC),XWA
	lda_24 xwa, (MainFunctionProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0014
	lda_24 xwa, (NoteNameStr_Table_8)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0442
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x003f
	lda_24 xwa, (0xed77ce)
	ld (XBC+0x0a),XWA
	lds wa, 1
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x003f
	lda_24 xwa, (0xed7e56)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0301
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0009
	lda_24 xwa, (0xed78ce)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0040
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0009
	lda_24 xwa, (0xed7ff6)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0340
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0011
	lda_24 xwa, (0xed78f6)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0041
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0011
	lda_24 xwa, (0xed803c)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0341
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda_24 xwa, (0xed793e)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0042
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda_24 xwa, (0xed80c2)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0342
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda_24 xwa, (0xed795a)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0043
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda_24 xwa, (0xed80f6)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0343
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0013
	lda_24 xwa, (0xed797e)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0044
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0013
	lda_24 xwa, (0xed8136)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0344
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0013
	lda_24 xwa, (0xed79ce)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0045
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0013
	lda_24 xwa, (0xed81ae)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0345
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xed7a1e)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0046
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xed822e)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0346
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda_24 xwa, (0xed7a22)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0047
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda_24 xwa, (0xed8234)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0347
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0019
	lda_24 xwa, (0xed7a42)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0048
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0019
	lda_24 xwa, (0xed826e)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0348
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda_24 xwa, (0xed7aaa)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00c0
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda_24 xwa, (0xed8322)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03c0
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda_24 xwa, (0xed7abe)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00c1
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda_24 xwa, (0xed8346)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03c1
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0014
	lda_24 xwa, (0xed7ad2)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00c2
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0014
	lda_24 xwa, (0xed836c)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03c2
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0011
	lda_24 xwa, (0xed7b26)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00c3
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0011
	lda_24 xwa, (0xed83fc)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03c3
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda_24 xwa, (0xed7b6e)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00c4
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda_24 xwa, (0xed8478)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03c4
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda_24 xwa, (0xed7b92)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00c5
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda_24 xwa, (0xed84b8)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03c5
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda_24 xwa, (0xed7bb2)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00d0
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda_24 xwa, (0xed84f0)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03d0
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000d
	lda_24 xwa, (0xed7bce)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00d1
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000d
	lda_24 xwa, (0xed8520)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03d1
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda_24 xwa, (0xed7c06)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00d2
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda_24 xwa, (0xed857a)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03d2
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda_24 xwa, (0xed7c26)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00d3
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0007
	lda_24 xwa, (0xed85b0)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03d3
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0002
	lda_24 xwa, (0xed7c46)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00e8
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0002
	lda_24 xwa, (0xed85e8)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03e8
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0003
	lda_24 xwa, (0xed7c52)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00e9
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0003
	lda_24 xwa, (0xed85fe)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03e9
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000e
	lda_24 xwa, (0xed7c62)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00f4
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000e
	lda_24 xwa, (0xed861a)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03f4
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0017
	lda_24 xwa, (0xed7c9e)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00f5
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0017
	lda_24 xwa, (0xed8682)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03f5
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0001
	lda_24 xwa, (0xed7cfe)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00f6
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0001
	lda_24 xwa, (0xed8736)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03f6
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0003
	lda_24 xwa, (0xed7d06)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00f7
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0003
	lda_24 xwa, (0xed8746)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03f7
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0043
	lda_24 xwa, (0xed7d16)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00f8
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0043
	lda_24 xwa, (0xed8762)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03f8
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0009
	lda_24 xwa, (0xed7e26)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00f9
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0009
	lda_24 xwa, (0xed8922)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03f9
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0001
	lda_24 xwa, (0xed7e4e)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00fb
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0001
	lda_24 xwa, (0xed896e)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03fb
	call RegisterObjectTable
	pushw 0x0002
	pushw 0x00ed
	pushw 0x897c
	lds32 xwa, 1
	ld XBC,0x01200000
	ld XDE,0x01a00001
	call RegisterMode
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8986
	lds32 xwa, 4
	ld XBC,0x01200000
	ld XDE,0x01a00040
	call RegisterMode
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8992
	ld XWA,0x00000012
	ld XBC,0x01200000
	ld XDE,0x01a000c0
	call RegisterMode
	pushw 0x0002
	pushw 0x00ed
	pushw 0x899a
	lds32 xwa, 1
	ld XBC,0x01200000
	ld XDE,0x00010001
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x89a4
	ld XWA,0x00000040
	ld XBC,0x01200000
	ld XDE,0x00400000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x89ae
	ld XWA,0x00000041
	ld XBC,0x0142000b
	ld XDE,0x00410000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x89b8
	ld XWA,0x00000042
	ld XBC,0x0142000c
	ld XDE,0x00420000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x89c4
	ld XWA,0x00000043
	ld XBC,0x01200000
	ld XDE,0x00430000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x89d0
	ld XWA,0x00000044
	ld XBC,0x01200000
	ld XDE,0x00440000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x89dc
	ld XWA,0x00000045
	ld XBC,0x01200000
	ld XDE,0x00450000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x89e6
	ld XWA,0x00000046
	ld XBC,0x01200000
	ld XDE,0x00410000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x89f2
	ld XWA,0x00000047
	ld XBC,0x01200000
	ld XDE,0x00470000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x89fe
	ld XWA,0x00000048
	ld XBC,0x01200000
	ld XDE,0x00480002
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8a0c
	ld XWA,0x000000c0
	ld XBC,0x01420009
	ld XDE,0x00c00000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8a16
	ld XWA,0x000000c1
	ld XBC,0x01200000
	ld XDE,0x00c10000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8a24
	ld XWA,0x000000c2
	ld XBC,0x01200000
	ld XDE,0x00c20000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8a30
	ld XWA,0x000000c3
	ld XBC,0x01200000
	ld XDE,0x00c30000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8a3c
	ld XWA,0x000000c4
	ld XBC,0x01200000
	ld XDE,0x00c40000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8a4a
	ld XWA,0x000000c5
	ld XBC,0x01200000
	ld XDE,0x00c50000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8a56
	ld XWA,0x000000d0
	ld XBC,0x01200000
	ld XDE,0x00d00000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8a62
	ld XWA,0x000000d1
	ld XBC,0x01200000
	ld XDE,0x00d10000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8a6c
	ld XWA,0x000000d2
	ld XBC,0x01200000
	ld XDE,0x00d20000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8a76
	ld XWA,0x000000d3
	ld XBC,0x01200000
	ld XDE,0x00d30000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8a82
	ld XWA,0x000000e8
	ld XBC,0x01200000
	ld XDE,0x00e80000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8a8c
	ld XWA,0x000000e9
	ld XBC,0x01200000
	ld XDE,0x00e90000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8a96
	ld XWA,0x000000f4
	ld XBC,0x01200000
	ld XDE,0x00f40000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8aa0
	ld XWA,0x000000f5
	ld XBC,0x01420010
	ld XDE,0x00f50000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8aaa
	ld XWA,0x000000f6
	ld XBC,0x01420011
	ld XDE,0x00f60000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8ab4
	ld XWA,0x000000f7
	ld XBC,0x01420012
	ld XDE,0x00f70000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8abe
	ld XWA,0x000000f8
	ld XBC,0x01200000
	ld XDE,0x00f80000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8ac8
	ld XWA,0x000000f9
	ld XBC,0x01420013
	ld XDE,0x00f90000
	call RegisterTitle
	pushw 0x0002
	pushw 0x00ed
	pushw 0x8ad2
	ld XWA,0x000000fb
	ld XBC,0x01200000
	ld XDE,0x00fb0000
	call RegisterTitle
	lda xsp, (xsp + 0x0e)
	ret
