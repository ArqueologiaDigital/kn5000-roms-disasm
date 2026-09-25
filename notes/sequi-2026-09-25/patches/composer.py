import sys
p = sys.argv[1]
s = open(p, encoding='latin-1').read()
def rep(old, new):
    global s
    assert s.count(old) == 1, (old[:70], s.count(old))
    s = s.replace(old, new)

# 1. correct the proven-false count in the file header
rep(''';    - Callback function pointer table (55 entries) for UI event handlers
;    - Null-terminated (.long 0 sentinel)''', ''';    - Callback function pointer table (72 entries + a .long 0 sentinel =
;      73, the count InitializeSuna registers; see Composer_FunctionTable)
;    - Null-terminated (.long 0 sentinel)''')

# 2. Composer_SettingsBlock layout
rep('''Composer_SettingsBlock:
	.byte 0x48, 0x00, 0x4b, 0x00, 0x00, 0x03
	.zero 90

	.byte 0x20, 0x00, 0xc0, 0x00
	.byte 0x0c, 0x00, 0x00, 0x01, 0x39, 0x00, 0x0c, 0x00
	.byte 0x00, 0x00, 0xc0, 0x03, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7f
	.byte 0x40, 0x00, 0x00, 0x00
	.ascii " Compile Bank 1  Compile Bank 2                                    User Bank 1     User Bank 2                                  "
''', '''; -----------------------------------------------------------------------------
; Composer_SettingsBlock -- 0x100 bytes: the factory template of the composer
; settings area whose RAM base pointer sits at RAM 0x0C9A
; (FileHdr_InitBasePointer sets it to 0x1E8800, in battery-backed SRAM).
; Reader: ToneData_SetupCopyPointers (storage/flash_floppy_handlers.s; v10/v9
; 0xF19555, v7 0xF1952B), which copies, through the positional aliases
; Composer_SettingsBlock_0x60/_0x70/_0x80/_0xC0 (shared/positional_labels.s):
;   +0x00 ( 6 B) -> base+0x000    "H\\0K\\0" signature + 00 03
;   +0x60 (16 B) -> base+0x010
;   +0x70 (16 B) -> base+0x020+16k for each k = 0..11 whose first byte is 0
;                   (a default for empty 16-byte slots)
;   +0x80 (64 B) -> base+0x240    four 16-char names, " Compile Bank 1 " ...
;   +0xC0 (64 B) -> base+0x280    four 16-char names, "   User Bank 1  " ...
; (and MSP_Default_PartBankMap's 64 bytes -> base+0x200).  +0x06..+0x5F is
; not copied.  What the two 16-byte records' fields mean is not decoded here.
; Composer_FunctionTable follows at +0x100.
; -----------------------------------------------------------------------------
Composer_SettingsBlock:
	.byte 0x48, 0x00, 0x4b, 0x00, 0x00, 0x03
	.zero 90

	; +0x60: 16-byte record copied to base+0x10
	.byte 0x20, 0x00, 0xc0, 0x00, 0x0c, 0x00, 0x00, 0x01, 0x39, 0x00, 0x0c, 0x00, 0x00, 0x00, 0xc0, 0x03
	; +0x70: 16-byte default for the empty slots at base+0x20..0xDF
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7f, 0x40, 0x00, 0x00, 0x00
	; +0x80: bank names, 4 x 16 characters -> base+0x240
	.ascii " Compile Bank 1  Compile Bank 2                                  "
	; +0xC0: bank names, 4 x 16 characters -> base+0x280
	.ascii "   User Bank 1     User Bank 2                                  "

; -----------------------------------------------------------------------------
; Composer_FunctionTable -- 73 x .long: 72 handler addresses and a 0.
; Registered by InitializeSuna (storage/flash_floppy_handlers.s; v10/v9
; 0xF19636, v7 0xF1960C) as object table 0x124: RegisterObjectTable with the
; record {0x01600002, ApFunctionProc, 0x49 entries, this table, id 0x124}
; (`RegObjTabl 0x1600002, 0xfa496c, 0x49, 0xe16284, 0x124` in v10).  Entry i
; is named by Composer_CallbackNameTable entry i (object table 0x424).  The
; same pair of tables for the Kubo module is registered by InitializeKubo as
; ids 0x128 / 0x428.
; -----------------------------------------------------------------------------
Composer_FunctionTable:
''')

# 3. name table header
rep('''
Composer_CallbackNameTable:
''', '''
; -----------------------------------------------------------------------------
; Composer_CallbackNameTable -- 73 x .long pointers to the FuncName_* strings
; below, entry for entry parallel to Composer_FunctionTable (the last points
; at the empty string).  Registered by InitializeSuna as object table 0x424:
; {0x01600002, ApFunctionProc, 0x49 entries, this table, id 0x424}.
; -----------------------------------------------------------------------------
Composer_CallbackNameTable:
''')

# 4. strings header
rep('''
FuncName_Empty_0:''', '''
; The 73 name strings Composer_CallbackNameTable points at (aligned_string:
; NUL-terminated, padded to an even length).  Each is the source-level name
; of the Composer_FunctionTable handler at the same index.
FuncName_Empty_0:''')
open(p, 'w', encoding='latin-1').write(s)
print('ok')
