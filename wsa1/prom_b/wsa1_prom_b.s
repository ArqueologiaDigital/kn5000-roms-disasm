	.text

; ==============================================================================
; Technics SX-WSA1R -- wsa1_prom_b.ic13
; Target CPU: Toshiba TMP95C061 (TLCS-900/H), "CPU 1" / IC1
; ==============================================================================
;
; IC13, the second program EPROM on CPU 1's bus, base 0xF00000.
;
; ⚠ The base is now CONFIRMED, not inferred.  Four independent proofs are
; written out in prom_b/prom_b.ld; the short form is that prom_a's interrupt
; vectors, its reset path, a PC-relative call across the boundary and the
; expansion-board probe's thunk all land on well-formed code in this image at
; exactly this base, and none of them survives a one-byte error in it.
;
; prom_a + prom_b are ONE contiguous 1 MiB image on CS2.  This half is not a
; boot image: its own file 0x7FF00 holds only 3 vector-shaped words, and its
; 0x7FFF0 -- where the other three images carry a lowercase `wsaX_NNN` build
; tag -- is code.
;
; STATUS: partially converted.  Converted so far, as real assembly:
;   0xF01800-0xF3E15B  129 spans of UI DISPLAY-LIST data (39,329 bytes) -- the
;                      machine's screen text and layout, in records.  Each record
;                      is rendered with the field layout of the interpreter that
;                      RUNS it; there are two, and they do not share a layout.
;                      13 of the gaps between the spans (999 bytes) hold the
;                      operand tables those records point at, and are decoded
;                      here too -- including the 64 eight-character resonator
;                      names at 0xF03241.
;   0xF0E800-0xF0EA9E  the FIELD-BLINK ENGINE -- 16 labels: 11 routines, 4
;                      dispatch arms reached only by `jp`, and a 12-entry
;                      command table.  Blinks at 1.27 Hz; the whole clock chain
;                      is re-derived by notes/prom_b_blink_rate.py.  The two
;                      display-list record TEMPLATES it patches on the stack are
;                      at 0xF78000, below.
;   0xF31800-0xF32708  BOTH display-list interpreters, their handler tables, the
;                      quantiser, 29 value glyphs and 3 fixed bitmaps
;   0xF40000-0xF44017  the THUNK TABLE -- the image's routine directory
;   0xF55000-0xF5535A  nine parameter-edit primitives and table accessors, four
;                      of them named by top-ranked thunk slots
;   0xF5535B-0xF5553E  two more of the same family: IndexedParam_AdjustField and
;                      IndexedParam_SetBit, which resolve their target through
;                      IndexedTable_GetPtr and journal every change
;   0xF5B8B6-0xF5BAB7  two selector dispatchers and their 48-entry tables
;   0xF78000-0xF78028  the two interpreter-B record templates and the eight-space
;                      blank the blink engine erases with
;   0xF7D000-0xF7E2D7  a stub/veneer block and 32 tables of 32 routine pointers
; Everything else is still .incbin, so it builds byte-exact by construction and
; asserts nothing.  The gate (scripts/analysis/assert_byte_identical.py) must
; print PASS after every edit.
;
; PROVENANCE: this is not a chip read.  It is the publicly redistributed v2
; firmware set (../technics_roms/roms/wsa1/PROVENANCE.md).

; --- 0xF00000-0xF017FF: not converted ---
wsa1_prom_b:
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x000000, 0x001800

; ==============================================================================
; 0xF01800-0xF3E15B -- UI DISPLAY LISTS  (129 spans, 4011 records, 39329 bytes)
; ==============================================================================
;
; The WSA1 has no string table.  Every string it shows -- "SOUND EDIT",
; "TONE LAYER", "DSP EFFECT", "CONTROLLER", "AMPLITUDE" -- lives inside a
; byte-coded DISPLAY LIST, executed by one of TWO interpreters, both converted
; below in 0xF31800-0xF32708.
;
; RECORD:   +0  opcode
;           +1  length of the WHOLE record in bytes; the loop advances by it
;           +2  operands, and for interpreter A's text opcodes a run of characters
;
;   interpreter A  0xF31A09, opcode bound 0x24, handler table 0xF31D21 (36 slots)
;                  draws what the RECORD says: fixed text, boxes, bitmaps.
;   interpreter B  0xF31AF0, opcode bound 0x0F, handler table 0xF31DB1 (15 slots)
;                  draws what a VARIABLE says: every one of its handlers opens by
;                  extracting a bit-field from a 16-bit RAM address named in the
;                  record (+2 address, +4 mask, +5 shift).
;
; The two share the (opcode, length) header and NOTHING else -- not the opcode
; space, not the handler table, not the field layout.  A record is attributed to
; an interpreter by the call site that reaches it: `ld XIY,<start>` /
; `ld XIX,<end>` / `call 0xF417F0` (A) or `call 0xF417F4` (B).  Each record below
; is rendered with THAT interpreter's field layout, and B records are marked
; `B op NN` in their header comment.
;
; ⚠ CORRECTED 2026-08-24.  Until this pass every record here was rendered with
; interpreter A's layout, including the 494 that only interpreter B ever runs.
; That is exactly where the "341 records violate the length rule" figure came
; from: judged by A's layout, 353 of B's 494 records disagree -- because they are
; not A's records.  Judged by the OWNING interpreter, the exception count is
; ZERO on both sides: 3,603 A records and 494 B records, first and last of each
; class tested.  Reproduce with
;     python3 notes/prom_b_dl_length_audit.py --edges
; Its implied lengths are read off each handler's own instructions, one line per
; handler, in that script's docstring.
;
; FRAMING, per call site and UN-MERGED: 243 of 244 interpreter-A sites and 158 of
; 162 interpreter-B sites walk their length bytes exactly onto the end address
; the caller passes.  The five that do not are all genuine instruction sequences,
; not artefacts of the byte-level call-site scan; they are dissected in
; notes/FINDINGS-ui-display-list-interpreter-b.md.
;
; ⚠ The span list below is the MERGED one, which is why it holds 4,011 records
; and the un-merged walk finds 4,097.  Merging joins a good site to a bad one at
; 0xF286F9-0xF28750, and the four good records at 0xF286F9 are lost with it; they
; are still .incbin.
;
; `DL_<addr>` labels mark the addresses call sites actually pass as a list start.
; Generated by notes/gen_prom_b_display_lists_v2.py.
;

; ------------------------------------------------------------------
; 0xF01800-0xF01919 -- 35 display-list records, 282 bytes -- interpreter A
;   entered at: 0xF01800, 0xF01873
;   ends used:  0xF01873, 0xF0191A
; ------------------------------------------------------------------
DL_F01800:
	.byte 0x1C, 0x10	; op 1C, 16 bytes -> handler 0xF31A52
	.short 0x006E
	.short 0x0005
	.ascii "SOUND EDIT"
	.byte 0x06, 0x0B	; op 06, 11 bytes -> handler 0xF31A3A
	.short 0x05A0
	.byte 0x10	; character codes below 0x20
	.ascii " WRITE"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x0C08
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x059F
	.byte 0x11	; character codes below 0x20
	.byte 0x20, 0x08	; op 20, 8 bytes -> handler 0xF31A3A
	.short 0x05C2
	.ascii "COPY"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x0BDF
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x11F8
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x11F7
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x17BF
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1838
	.byte 0x10	; character codes below 0x20
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x001F
	.short 0x003C
	.short 0x0032
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000E
	.short 0x0021
	.short 0x003A
	.short 0x0030
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x010A
	.short 0x001E
	.short 0x0135
	.short 0x0033
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x010C
	.short 0x0020
	.short 0x0133
	.short 0x0031
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x10
	.short 0x0032
DL_F01873:
	.byte 0x06, 0x0E	; op 06, 14 bytes -> handler 0xF31A3A
	.short 0x0CE6
	.ascii "TONE LAYER"
	.byte 0x06, 0x0E	; op 06, 14 bytes -> handler 0xF31A3A
	.short 0x1876
	.ascii "DSP EFFECT"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x1867
	.ascii "PITCH"
	.byte 0x06, 0x0B	; op 06, 11 bytes -> handler 0xF31A3A
	.short 0x1196
	.ascii "DIGITAL"
	.byte 0x06, 0x0A	; op 06, 10 bytes -> handler 0xF31A3A
	.short 0x13A3
	.ascii "EFFECT"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1E50
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x0A	; op 06, 10 bytes -> handler 0xF31A3A
	.short 0x1E7F
	.ascii "FILTER"
	.byte 0x06, 0x0E	; op 06, 14 bytes -> handler 0xF31A3A
	.short 0x1E8E
	.ascii "CONTROLLER"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1DFF
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x0D	; op 06, 13 bytes -> handler 0xF31A3A
	.short 0x1277
	.ascii "AMPLITUDE"
	.byte 0x06, 0x0C	; op 06, 12 bytes -> handler 0xF31A3A
	.short 0x0CD7
	.ascii "MODELING"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000F
	.short 0x0041
	.short 0x0131
	.short 0x00D9
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x07
	.short 0x1773
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x21
	.short 0x1D63
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x64
	.short 0x0BB2
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x76
	.short 0x11A2
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x0A
	.short 0x1792
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x24
	.short 0x1D82
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x5A
	.short 0x0B93
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x63
	.short 0x1183

; --- 0xF0191A-0xF01E71: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x00191A, 0x000558

; ------------------------------------------------------------------
; 0xF01E72-0xF02294 -- 111 display-list records, 1059 bytes -- interpreter A
;   entered at: 0xF01E72, 0xF01F96, 0xF02064, 0xF020AA, 0xF021E4
;   ends used:  0xF01F96, 0xF0203E, 0xF02064, 0xF020AA, 0xF021E4, 0xF02295
; ------------------------------------------------------------------
DL_F01E72:
	.byte 0x20, 0x0F	; op 20, 15 bytes -> handler 0xF31A3A
	.short 0x0B2E
	.ascii "EFFECT SEND"
	.byte 0x20, 0x0C	; op 20, 12 bytes -> handler 0xF31A3A
	.short 0x0D39
	.ascii "& OUTPUT"
	.byte 0x20, 0x0E	; op 20, 14 bytes -> handler 0xF31A3A
	.short 0x1236
	.ascii "DSP EFFECT"
	.byte 0x17, 0x13	; op 17, 19 bytes -> handler 0xF31A52
	.short 0x0088
	.short 0x0088
	.ascii "KIT PARAMETER"
	.byte 0x20, 0x0A	; op 20, 10 bytes -> handler 0xF31A3A
	.short 0x1817
	.ascii "FILTER"
	.byte 0x20, 0x0E	; op 20, 14 bytes -> handler 0xF31A3A
	.short 0x184E
	.ascii "CONTROLLER"
	.byte 0x17, 0x17	; op 17, 23 bytes -> handler 0xF31A52
	.short 0x00CF
	.short 0x00BA
	.ascii "DRUM SOUND NAMING"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1D37
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0025
	.short 0x00C8
	.ascii "NOTE"
	.byte 0x17, 0x17	; op 17, 23 bytes -> handler 0xF31A52
	.short 0x0070
	.short 0x00C8
	.ascii "DRUM SOUND SELECT"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0064
	.short 0x00D6
	.ascii ":"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2446
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x244B
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2451
	.byte 0x12	; character codes below 0x20
	.byte 0x06, 0x0D	; op 06, 13 bytes -> handler 0xF31A3A
	.short 0x1227
	.ascii "AMPLITUDE"
	.byte 0x06, 0x0C	; op 06, 12 bytes -> handler 0xF31A3A
	.short 0x0BBF
	.ascii "MODELING"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000F
	.short 0x003A
	.short 0x0131
	.short 0x00B1
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x0079
	.short 0x00AD
	.short 0x0079
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x009F
	.short 0x00AD
	.short 0x009F
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x0079
	.short 0x00A9
	.short 0x0084
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x0093
	.short 0x00A9
	.short 0x009F
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x21
	.short 0x1723
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x70
	.short 0x0B12
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x0A
	.short 0x1152
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x24
	.short 0x1742
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x5A
	.short 0x0A7B
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x63
	.short 0x1133
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x001E
	.short 0x00D1
	.short 0x0047
	.short 0x00E8
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0053
	.short 0x00D1
	.short 0x0104
	.short 0x00E8
DL_F01F96:
	.byte 0x1C, 0x0E	; op 1C, 14 bytes -> handler 0xF31A52
	.short 0x0082
	.short 0x0005
	.ascii "M0DELING"
	.byte 0x17, 0x10	; op 17, 16 bytes -> handler 0xF31A52
	.short 0x0006
	.short 0x0007
	.ascii "SOUND EDIT"
	.byte 0x20, 0x08	; op 20, 8 bytes -> handler 0xF31A3A
	.short 0x05C2
	.ascii "TONE"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0135
	.short 0x0021
	.byte 0x11	; character codes below 0x20
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0135
	.short 0x0047
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x010F
	.short 0x004C
	.ascii "DRIVER"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0FC4
	.byte 0x12	; character codes below 0x20
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0135
	.short 0x006E
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x010F
	.short 0x0070
	.ascii "CONNEC"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x011B
	.short 0x0079
	.ascii "TION"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x158C
	.byte 0x12	; character codes below 0x20
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0004
	.short 0x0004
	.short 0x0044
	.short 0x0010
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x010C
	.short 0x001D
	.short 0x0136
	.short 0x0034
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x010C
	.short 0x0048
	.short 0x0136
	.short 0x0056
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x010C
	.short 0x006C
	.short 0x0136
	.short 0x0083
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0123
	.short 0x0056
	.short 0x0124
	.short 0x0066
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0123
	.short 0x0083
	.short 0x0124
	.short 0x008B
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x5A
	.short 0x0035
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x010F
	.short 0x0095
	.ascii "RESO"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0135
	.short 0x0096
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0115
	.short 0x009E
	.ascii "NATOR"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x010C
	.short 0x0091
	.short 0x0136
	.short 0x00A8
DL_F02064:
	.byte 0x20, 0x05	; op 20, 5 bytes -> handler 0xF31A3A
	.short 0x1728
	.ascii ":"
	.byte 0x20, 0x05	; op 20, 5 bytes -> handler 0xF31A3A
	.short 0x1CF0
	.ascii ":"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00B9
	.short 0x0089
	.short 0x00FA
	.short 0x00A8
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0034
	.short 0x008E
	.short 0x00B5
	.short 0x00A3
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00B9
	.short 0x00AE
	.short 0x00FA
	.short 0x00CD
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0034
	.short 0x00B3
	.short 0x00B5
	.short 0x00C8
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00B5
	.short 0x0098
	.short 0x00B9
	.short 0x0099
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00B5
	.short 0x00BD
	.short 0x00B9
	.short 0x00BE
DL_F020AA:
	.byte 0x17, 0x0F	; op 17, 15 bytes -> handler 0xF31A52
	.short 0x00BF
	.short 0x0036
	.ascii "RESONATOR"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x0038
	.short 0x003B
	.ascii "DRIVER"
	.byte 0x20, 0x05	; op 20, 5 bytes -> handler 0xF31A3A
	.short 0x0B98
	.ascii ":"
	.byte 0x20, 0x05	; op 20, 5 bytes -> handler 0xF31A3A
	.short 0x1160
	.ascii ":"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x0002
	.short 0x00D1
	.ascii "ON/OFF"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x002E
	.short 0x00D1
	.ascii "GROUP"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x0052
	.short 0x00D1
	.ascii "DRIVER"
	.byte 0x17, 0x0F	; op 17, 15 bytes -> handler 0xF31A52
	.short 0x00BA
	.short 0x00D1
	.ascii "RESONATOR"
	.byte 0x17, 0x11	; op 17, 17 bytes -> handler 0xF31A52
	.short 0x00F4
	.short 0x00D1
	.ascii "INTERACTION"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21C2
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21C7
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21CC
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21DB
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2209
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x237A
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x237F
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2384
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2393
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x23C1
	.byte 0x8E	; character codes below 0x20
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00B9
	.short 0x003F
	.short 0x00FA
	.short 0x005E
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0034
	.short 0x0044
	.short 0x00B5
	.short 0x0059
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00B9
	.short 0x0064
	.short 0x00FA
	.short 0x0083
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0034
	.short 0x0069
	.short 0x00B5
	.short 0x007E
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0009
	.short 0x00DA
	.short 0x001E
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00DA
	.short 0x0046
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00DA
	.short 0x006E
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00DA
	.short 0x00E6
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0101
	.short 0x00DA
	.short 0x0116
	.short 0x00EE
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00B5
	.short 0x004E
	.short 0x00B9
	.short 0x004F
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00B5
	.short 0x0073
	.short 0x00B9
	.short 0x0074
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0009
	.short 0x00E4
	.short 0x001E
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00E4
	.short 0x0046
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00E4
	.short 0x006E
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00E4
	.short 0x00E6
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0101
	.short 0x00E4
	.short 0x0116
	.short 0x00E4
DL_F021E4:
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0084
	.short 0x001A
	.ascii "TONE"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x0054
	.short 0x0029
	.ascii "DRIVER"
	.byte 0x17, 0x0F	; op 17, 15 bytes -> handler 0xF31A52
	.short 0x0094
	.short 0x0029
	.ascii "RESONATOR"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0051
	.short 0x0025
	.short 0x007B
	.short 0x0033
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0091
	.short 0x0025
	.short 0x00CE
	.short 0x0033
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0084
	.short 0x002A
	.short 0x0087
	.short 0x002D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0051
	.short 0x001D
	.short 0x0082
	.short 0x001D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x009E
	.short 0x001D
	.short 0x00CE
	.short 0x001D
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x007B
	.short 0x002B
	.short 0x0084
	.short 0x002C
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0087
	.short 0x002B
	.short 0x0091
	.short 0x002C
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00CE
	.short 0x002B
	.short 0x00E8
	.short 0x002C
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00E5
	.short 0x002C
	.short 0x00E8
	.short 0x002C
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0051
	.short 0x001D
	.short 0x0051
	.short 0x0020
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00CE
	.short 0x001D
	.short 0x00CE
	.short 0x0020
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00E5
	.short 0x0028
	.short 0x00E5
	.short 0x002F
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00E6
	.short 0x0029
	.short 0x00E6
	.short 0x002E
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00E7
	.short 0x002A
	.short 0x00E7
	.short 0x002D

; --- 0xF02295-0xF022F6: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x002295, 0x000062

; ------------------------------------------------------------------
; 0xF022F7-0xF02F35 -- 335 display-list records, 3135 bytes -- interpreter A
;   entered at: 0xF022F7, 0xF02329, 0xF0245F, 0xF02469, 0xF02671, 0xF027AF, 0xF02942, 0xF02A46, 0xF02B47, 0xF02D08, 0xF02DFB, 0xF02EF9, 0xF02F22
;   ends used:  0xF02329, 0xF0245F, 0xF02469, 0xF02671, 0xF027AF, 0xF02942, 0xF02A46, 0xF02B47, 0xF02D08, 0xF02DFB, 0xF02F22, 0xF02F2C, 0xF02F36
; ------------------------------------------------------------------
DL_F022F7:
	.byte 0x20, 0x05	; op 20, 5 bytes -> handler 0xF31A3A
	.short 0x174F
	.ascii ":"
	.byte 0x20, 0x05	; op 20, 5 bytes -> handler 0xF31A3A
	.short 0x1C4F
	.ascii ":"
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x008A
	.short 0x0108
	.short 0x00CA
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x00AA
	.short 0x0108
	.short 0x00AA
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x002C
	.short 0x008A
	.short 0x002C
	.short 0x00CA
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00AC
	.short 0x008A
	.short 0x00AC
	.short 0x00CA
DL_F02329:
	.byte 0x17, 0x13	; op 17, 19 bytes -> handler 0xF31A52
	.short 0x0044
	.short 0x003F
	.ascii "TONE TEMPLATE"
	.byte 0x17, 0x14	; op 17, 20 bytes -> handler 0xF31A52
	.short 0x00B0
	.short 0x003F
	.ascii "LEVEL KEY TUNE"
	.byte 0x20, 0x05	; op 20, 5 bytes -> handler 0xF31A3A
	.short 0x0D4F
	.ascii ":"
	.byte 0x20, 0x05	; op 20, 5 bytes -> handler 0xF31A3A
	.short 0x124F
	.ascii ":"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x002D
	.short 0x00D1
	.ascii "GROUP"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0058
	.short 0x00D1
	.ascii "TONE"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00A4
	.short 0x00D1
	.ascii "LEVEL"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00D2
	.short 0x00D1
	.ascii "KEY"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00F7
	.short 0x00D1
	.ascii "TUNE"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21EF
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F4
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21FE
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2203
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2208
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x237F
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2384
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x238E
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2393
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2398
	.byte 0x8E	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0039
	.short 0x0108
	.short 0x008A
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00DA
	.short 0x0046
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00DA
	.short 0x006E
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00DA
	.short 0x00BE
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00DA
	.short 0x00E6
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00F9
	.short 0x00DA
	.short 0x010E
	.short 0x00EE
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x004A
	.short 0x0108
	.short 0x004A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x006A
	.short 0x0108
	.short 0x006A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00E4
	.short 0x0046
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00E4
	.short 0x006E
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00E4
	.short 0x00BE
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00E4
	.short 0x00E6
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F9
	.short 0x00E4
	.short 0x010E
	.short 0x00E4
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x002C
	.short 0x0039
	.short 0x002C
	.short 0x008A
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00AC
	.short 0x0039
	.short 0x00AC
	.short 0x008A
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x010E
	.short 0x001F
	.short 0x0134
	.short 0x0032
DL_F0245F:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x008B
	.short 0x0109
	.short 0x008B
DL_F02469:
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0049
	.short 0x003A
	.short 0x00A9
	.short 0x0048
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0047
	.short 0x0036
	.short 0x00A7
	.short 0x0044
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0047
	.short 0x0036
	.short 0x00A7
	.short 0x0044
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0045
	.short 0x0032
	.short 0x00A5
	.short 0x0040
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0045
	.short 0x0032
	.short 0x00A5
	.short 0x0040
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0043
	.short 0x002E
	.short 0x00A3
	.short 0x003C
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0043
	.short 0x002E
	.short 0x00A3
	.short 0x003C
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x0060
	.short 0x0022
	.ascii "DRIVER"
	.byte 0x17, 0x15	; op 17, 21 bytes -> handler 0xF31A52
	.short 0x0046
	.short 0x0032
	.ascii "DRIVER WAVEFORM"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00C4
	.short 0x0032
	.ascii "RESO"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00CA
	.short 0x003B
	.ascii "NATOR"
	.byte 0x17, 0x15	; op 17, 21 bytes -> handler 0xF31A52
	.short 0x004E
	.short 0x0067
	.ascii "DRIVER WAVEFORM"
	.byte 0x17, 0x0E	; op 17, 14 bytes -> handler 0xF31A52
	.short 0x00C3
	.short 0x0067
	.ascii "VELOCITY"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x0052
	.short 0x00C8
	.ascii "DRIVER"
	.byte 0x20, 0x0A	; op 20, 10 bytes -> handler 0xF31A3A
	.short 0x202A
	.ascii "CURS0R"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0024
	.short 0x00D1
	.ascii "GROUP"
	.byte 0x17, 0x0E	; op 17, 14 bytes -> handler 0xF31A52
	.short 0x004C
	.short 0x00D1
	.ascii "WAVEFORM"
	.byte 0x17, 0x0E	; op 17, 14 bytes -> handler 0xF31A52
	.short 0x00C4
	.short 0x00D1
	.ascii "VELOCITY"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21C6
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F4
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2203
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x220D
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2356
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2384
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2393
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x239D
	.byte 0x8E	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00C1
	.short 0x002E
	.short 0x00EB
	.short 0x0045
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00B8
	.short 0x0038
	.short 0x00BB
	.short 0x003B
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x003C
	.short 0x0061
	.short 0x00FD
	.short 0x00B7
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0029
	.short 0x00DA
	.short 0x003E
	.short 0x00EC
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00DA
	.short 0x006E
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00DA
	.short 0x00E6
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00DA
	.short 0x013A
	.short 0x00EE
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0039
	.short 0x0026
	.short 0x005D
	.short 0x0026
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0088
	.short 0x0026
	.short 0x00B3
	.short 0x0026
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00B3
	.short 0x0039
	.short 0x00B8
	.short 0x003A
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00BB
	.short 0x0039
	.short 0x00C1
	.short 0x003A
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00EB
	.short 0x0039
	.short 0x00FA
	.short 0x003A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F7
	.short 0x003A
	.short 0x00FA
	.short 0x003A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0039
	.short 0x0051
	.short 0x00B3
	.short 0x0051
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x003C
	.short 0x0072
	.short 0x00FD
	.short 0x0072
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0029
	.short 0x00E3
	.short 0x003E
	.short 0x00E3
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00E4
	.short 0x006E
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00E4
	.short 0x00E6
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00E4
	.short 0x013A
	.short 0x00E4
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0039
	.short 0x0026
	.short 0x0039
	.short 0x0051
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00B3
	.short 0x0026
	.short 0x00B3
	.short 0x0051
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00BD
	.short 0x0061
	.short 0x00BD
	.short 0x00B7
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00F7
	.short 0x0036
	.short 0x00F7
	.short 0x003D
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00F8
	.short 0x0037
	.short 0x00F8
	.short 0x003C
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00F9
	.short 0x0038
	.short 0x00F9
	.short 0x003B
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x010E
	.short 0x004A
	.short 0x0134
	.short 0x0054
DL_F02671:
	.byte 0x20, 0x0B	; op 20, 11 bytes -> handler 0xF31A3A
	.short 0x00E8
	.ascii "PAGE1/2"
	.byte 0x20, 0x16	; op 20, 22 bytes -> handler 0xF31A3A
	.short 0x0FD1
	.ascii "P0SITI0N PARAMETER"
	.byte 0x20, 0x0F	; op 20, 15 bytes -> handler 0xF31A3A
	.short 0x122B
	.ascii "P0SITI0N  :"
	.byte 0x20, 0x05	; op 20, 5 bytes -> handler 0xF31A3A
	.short 0x1238
	.ascii "."
	.byte 0x20, 0x0F	; op 20, 15 bytes -> handler 0xF31A3A
	.short 0x1483
	.ascii "DEPTH     :"
	.byte 0x20, 0x0F	; op 20, 15 bytes -> handler 0xF31A3A
	.short 0x16DB
	.ascii "FORMANT   :"
	.byte 0x20, 0x0F	; op 20, 15 bytes -> handler 0xF31A3A
	.short 0x19A9
	.ascii "INTERACTION"
	.byte 0x20, 0x0F	; op 20, 15 bytes -> handler 0xF31A3A
	.short 0x1C03
	.ascii "GAIN      :"
	.byte 0x17, 0x1C	; op 17, 28 bytes -> handler 0xF31A52
	.short 0x001C
	.short 0x00D1
	.ascii "POSITION DEPTH FORMANT"
	.byte 0x17, 0x11	; op 17, 17 bytes -> handler 0xF31A52
	.short 0x00BF
	.short 0x00C9
	.ascii "INTERACTION"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00D1
	.short 0x00D1
	.ascii "GAIN"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21EF
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F4
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F9
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2203
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x237F
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2384
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2389
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2393
	.byte 0x8E	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0041
	.short 0x005E
	.short 0x00DF
	.short 0x00C0
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00DA
	.short 0x0046
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00DA
	.short 0x006E
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00DA
	.short 0x0096
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00DA
	.short 0x00E6
	.short 0x00EE
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0041
	.short 0x009F
	.short 0x00DF
	.short 0x009F
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00E4
	.short 0x0046
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00E4
	.short 0x006E
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00E4
	.short 0x0096
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00E4
	.short 0x00E6
	.short 0x00E4
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x010E
	.short 0x006E
	.short 0x0134
	.short 0x0081
DL_F027AF:
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x007B
	.short 0x0025
	.byte 0x7F	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x008F
	.short 0x0025
	.ascii "~"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0085
	.short 0x0029
	.byte 0x12	; character codes below 0x20
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00C6
	.short 0x002B
	.ascii "RESO"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x007B
	.short 0x002E
	.byte 0x8D	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00A5
	.short 0x002E
	.byte 0x8D	; character codes below 0x20
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x003A
	.short 0x0030
	.ascii "DRIVER"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00CC
	.short 0x0034
	.ascii "NATOR"
	.byte 0x17, 0x0E	; op 17, 14 bytes -> handler 0xF31A52
	.short 0x007B
	.short 0x0037
	.ascii "POSITION"
	.byte 0x17, 0x0E	; op 17, 14 bytes -> handler 0xF31A52
	.short 0x007B
	.short 0x004F
	.ascii "MOVEMENT"
	.byte 0x17, 0x11	; op 17, 17 bytes -> handler 0xF31A52
	.short 0x00BB
	.short 0x004F
	.ascii "INTERACTION"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0077
	.short 0x0023
	.short 0x00AE
	.short 0x0041
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00C3
	.short 0x0027
	.short 0x00ED
	.short 0x003E
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0037
	.short 0x002C
	.short 0x0061
	.short 0x003A
	.byte 0x00, 0x0A	; op 00, 10 bytes -> handler 0xF31A75
	.short 0x0088
	.short 0x0027
	.short 0x0088
	.short 0x0029
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x0028
	.short 0x0085
	.short 0x0028
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x008B
	.short 0x0028
	.short 0x008F
	.short 0x0028
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007C
	.short 0x002F
	.short 0x00AA
	.short 0x002F
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0061
	.short 0x0032
	.short 0x0077
	.short 0x0033
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00AE
	.short 0x0032
	.short 0x00C3
	.short 0x0033
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00ED
	.short 0x0032
	.short 0x00F8
	.short 0x0033
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007C
	.short 0x0033
	.short 0x0080
	.short 0x0033
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A6
	.short 0x0033
	.short 0x00AA
	.short 0x0033
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0092
	.short 0x0046
	.short 0x0093
	.short 0x004C
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00D8
	.short 0x0043
	.short 0x00D9
	.short 0x004C
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F9
	.short 0x0032
	.short 0x00FC
	.short 0x0032
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F9
	.short 0x0033
	.short 0x00FC
	.short 0x0033
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D7
	.short 0x0040
	.short 0x00DA
	.short 0x0040
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D6
	.short 0x0041
	.short 0x00DB
	.short 0x0041
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D5
	.short 0x0042
	.short 0x00DC
	.short 0x0042
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0091
	.short 0x0043
	.short 0x0094
	.short 0x0043
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0090
	.short 0x0044
	.short 0x0095
	.short 0x0044
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x008F
	.short 0x0045
	.short 0x0096
	.short 0x0045
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0092
	.short 0x0042
	.short 0x0092
	.short 0x0045
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0093
	.short 0x0042
	.short 0x0093
	.short 0x0045
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00D8
	.short 0x003F
	.short 0x00D8
	.short 0x0042
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00D9
	.short 0x003F
	.short 0x00D9
	.short 0x0042
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00F9
	.short 0x002F
	.short 0x00F9
	.short 0x0036
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00FA
	.short 0x0030
	.short 0x00FA
	.short 0x0035
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00FB
	.short 0x0031
	.short 0x00FB
	.short 0x0034
DL_F02942:
	.byte 0x20, 0x0B	; op 20, 11 bytes -> handler 0xF31A3A
	.short 0x00E8
	.ascii "PAGE2/2"
	.byte 0x20, 0x15	; op 20, 21 bytes -> handler 0xF31A3A
	.short 0x0F82
	.ascii "P0SITI0N M0VEMENT"
	.byte 0x20, 0x0B	; op 20, 11 bytes -> handler 0xF31A3A
	.short 0x118D
	.ascii "WIDTH :"
	.byte 0x20, 0x0B	; op 20, 11 bytes -> handler 0xF31A3A
	.short 0x1395
	.ascii "SPEED :"
	.byte 0x20, 0x0B	; op 20, 11 bytes -> handler 0xF31A3A
	.short 0x15C5
	.ascii "S/H   :"
	.byte 0x20, 0x0B	; op 20, 11 bytes -> handler 0xF31A3A
	.short 0x1895
	.ascii "TOUCH :"
	.byte 0x17, 0x17	; op 17, 23 bytes -> handler 0xF31A52
	.short 0x002C
	.short 0x00D1
	.ascii "WIDTH  SPEED  S/H"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00CE
	.short 0x00D1
	.ascii "TOUCH"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21EF
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F4
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F9
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2203
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x237F
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2384
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2389
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2393
	.byte 0x8E	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0049
	.short 0x005E
	.short 0x00DD
	.short 0x00AE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00DA
	.short 0x0046
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00DA
	.short 0x006E
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00DA
	.short 0x0096
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00DA
	.short 0x00E6
	.short 0x00EE
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0049
	.short 0x0098
	.short 0x00DD
	.short 0x0098
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00E4
	.short 0x0046
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00E4
	.short 0x006E
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00E4
	.short 0x0096
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00E4
	.short 0x00E6
	.short 0x00E4
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x010E
	.short 0x006E
	.short 0x0134
	.short 0x0081
DL_F02A46:
	.byte 0x20, 0x0B	; op 20, 11 bytes -> handler 0xF31A3A
	.short 0x0110
	.ascii "PAGE1/3"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0031
	.short 0x007D
	.ascii "FIT"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0056
	.short 0x007D
	.ascii "MUT"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0081
	.short 0x007D
	.ascii "KEY"
	.byte 0x17, 0x08	; op 17, 8 bytes -> handler 0xF31A52
	.short 0x00A8
	.short 0x007D
	.ascii "DE"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00D2
	.short 0x007D
	.ascii "RESO"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0037
	.short 0x0087
	.ascii "TING"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x005C
	.short 0x0087
	.ascii "ING"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0081
	.short 0x0087
	.ascii "SHIFT"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00A8
	.short 0x0087
	.ascii "TUNE"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00D2
	.short 0x0087
	.ascii "SCALE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x208C
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2091
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2096
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x209B
	.byte 0x12	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F4
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F9
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21FE
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2203
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2384
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2389
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x238E
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2393
	.byte 0x8E	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00DA
	.short 0x006E
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00DA
	.short 0x0096
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00DA
	.short 0x00BE
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0027
	.short 0x0091
	.short 0x0135
	.short 0x00CF
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00DA
	.short 0x00E6
	.short 0x00EE
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00E4
	.short 0x006E
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00E4
	.short 0x0096
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00E4
	.short 0x00BE
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00E4
	.short 0x00E6
	.short 0x00E4
DL_F02B47:
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0082
	.short 0x0030
	.ascii "MAIN"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x003A
	.short 0x0035
	.ascii "DRIVER"
	.byte 0x17, 0x0F	; op 17, 15 bytes -> handler 0xF31A52
	.short 0x0082
	.short 0x0039
	.ascii "RESONATOR"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0082
	.short 0x004F
	.ascii "SUB"
	.byte 0x17, 0x0F	; op 17, 15 bytes -> handler 0xF31A52
	.short 0x0082
	.short 0x0058
	.ascii "RESONATOR"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00D1
	.short 0x005C
	.ascii "SUB"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00D1
	.short 0x0066
	.ascii "GAIN"
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F05CE0
	.short 0x0C98
	.short 0x0002
	.short 0x000C
	.byte 0x17, 0x0E	; op 17, 14 bytes -> handler 0xF31A52
	.short 0x00FF
	.short 0x00DC
	.ascii "MAIN&SUB"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2439
	.byte 0x12	; character codes below 0x20
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0107
	.short 0x0098
	.ascii "MAIN"
	.byte 0x17, 0x0F	; op 17, 15 bytes -> handler 0xF31A52
	.short 0x00FB
	.short 0x00A4
	.ascii "RESONATOR"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x010B
	.short 0x00B7
	.ascii "SUB"
	.byte 0x17, 0x0F	; op 17, 15 bytes -> handler 0xF31A52
	.short 0x00FB
	.short 0x00C3
	.ascii "RESONATOR"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0135
	.short 0x0096
	.byte 0x11	; character codes below 0x20
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0135
	.short 0x00BC
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2087
	.byte 0x12	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21EF
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x237F
	.byte 0x8E	; character codes below 0x20
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x007F
	.short 0x002C
	.short 0x00BB
	.short 0x0043
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0037
	.short 0x0031
	.short 0x0061
	.short 0x003F
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0067
	.short 0x0036
	.short 0x006A
	.short 0x0039
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x007F
	.short 0x004B
	.short 0x00BB
	.short 0x0062
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00FA
	.short 0x00D7
	.short 0x0134
	.short 0x00E7
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00FC
	.short 0x00D9
	.short 0x0132
	.short 0x00E5
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00DA
	.short 0x0046
	.short 0x00EE
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0027
	.short 0x0079
	.short 0x00F6
	.short 0x00CF
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0061
	.short 0x0037
	.short 0x0067
	.short 0x0038
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x006A
	.short 0x0037
	.short 0x007F
	.short 0x0038
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00BB
	.short 0x0037
	.short 0x00EC
	.short 0x0038
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00E9
	.short 0x0038
	.short 0x00EC
	.short 0x0038
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D9
	.short 0x003A
	.short 0x00DC
	.short 0x003A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D8
	.short 0x003B
	.short 0x00DD
	.short 0x003B
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D7
	.short 0x003C
	.short 0x00DE
	.short 0x003C
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0071
	.short 0x0055
	.short 0x007F
	.short 0x0056
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00BB
	.short 0x0055
	.short 0x00BF
	.short 0x0056
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x0055
	.short 0x00DB
	.short 0x0056
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x006F
	.short 0x0039
	.short 0x0070
	.short 0x0056
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00DA
	.short 0x0039
	.short 0x00DB
	.short 0x0055
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00DB
	.short 0x0039
	.short 0x00DB
	.short 0x003C
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00E9
	.short 0x0034
	.short 0x00E9
	.short 0x003B
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00EA
	.short 0x0035
	.short 0x00EA
	.short 0x003A
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00EB
	.short 0x0036
	.short 0x00EB
	.short 0x0039
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0027
	.short 0x00B0
	.short 0x0135
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00E4
	.short 0x0046
	.short 0x00E4
DL_F02D08:
	.byte 0x20, 0x0B	; op 20, 11 bytes -> handler 0xF31A3A
	.short 0x0110
	.ascii "PAGE2/3"
	.byte 0x17, 0x11	; op 17, 17 bytes -> handler 0xF31A52
	.short 0x0052
	.short 0x007D
	.ascii "TOUCH DEPTH"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00D0
	.short 0x007D
	.ascii "SUB"
	.byte 0x17, 0x1D	; op 17, 29 bytes -> handler 0xF31A52
	.short 0x002E
	.short 0x0087
	.ascii "FITTING MUTING SUB-GAIN"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00D0
	.short 0x0087
	.ascii "GAIN"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x208D
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2095
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x209B
	.byte 0x12	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F5
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21FD
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2203
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2385
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x238D
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2393
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1874
	.ascii "--"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x187B
	.ascii "--"
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0061
	.short 0x00DA
	.short 0x0076
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00A1
	.short 0x00DA
	.short 0x00B6
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00DA
	.short 0x00E6
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0027
	.short 0x0091
	.short 0x0135
	.short 0x00CF
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0040
	.short 0x0080
	.short 0x0050
	.short 0x0080
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0097
	.short 0x0080
	.short 0x00A6
	.short 0x0080
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0061
	.short 0x00E4
	.short 0x0076
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A1
	.short 0x00E4
	.short 0x00B6
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00E4
	.short 0x00E6
	.short 0x00E4
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0040
	.short 0x0080
	.short 0x0040
	.short 0x0085
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A6
	.short 0x0080
	.short 0x00A6
	.short 0x0084
DL_F02DFB:
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x0064
	.short 0x007D
	.ascii "MUTING"
	.byte 0x17, 0x10	; op 17, 16 bytes -> handler 0xF31A52
	.short 0x008D
	.short 0x007D
	.ascii "KEY FOLLOW"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0058
	.short 0x0087
	.ascii "SLOPE"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00A5
	.short 0x0087
	.ascii "RANGE"
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x1783
	.ascii "__"
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x1788
	.ascii "__"
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x1C5B
	.ascii "__"
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x1C60
	.ascii "__"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x208C
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2091
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2096
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x209B
	.byte 0x12	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F4
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F9
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21FE
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2203
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2384
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2389
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x238E
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2393
	.byte 0x8E	; character codes below 0x20
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x008C
	.short 0x008A
	.short 0x008C
	.short 0x008F
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00DD
	.short 0x008A
	.short 0x00DD
	.short 0x008E
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x008C
	.short 0x008A
	.short 0x00A3
	.short 0x008A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00C5
	.short 0x008A
	.short 0x00DD
	.short 0x008A
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00DA
	.short 0x006E
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00DA
	.short 0x0096
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00DA
	.short 0x00BE
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00DA
	.short 0x00E6
	.short 0x00EE
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00E4
	.short 0x006E
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00E4
	.short 0x0096
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00E4
	.short 0x00BE
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00E4
	.short 0x00E6
	.short 0x00E4
DL_F02EF9:
	.byte 0x20, 0x0B	; op 20, 11 bytes -> handler 0xF31A3A
	.short 0x0110
	.ascii "PAGE3/3"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0030
	.short 0x007D
	.ascii "RESO"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0030
	.short 0x0087
	.ascii "MODE"
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0027
	.short 0x0091
	.short 0x0135
	.short 0x00CF
DL_F02F22:
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x0B90
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1158
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1748
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1D10
	.byte 0x10	; character codes below 0x20

; --- 0xF02F36-0xF02FB1: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x002F36, 0x00007C

; ------------------------------------------------------------------
; 0xF02FB2-0xF02FD8 -- 4 display-list records, 39 bytes -- interpreter A
;   entered at: 0xF02FB2
;   ends used:  0xF02FD9
; ------------------------------------------------------------------
DL_F02FB2:
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x0550
	.byte 0x10	; character codes below 0x20
	.ascii "SOLO"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x001E
	.short 0x002B
	.short 0x002F
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x0020
	.short 0x0029
	.short 0x002D
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x001F
	.short 0x0006
	.short 0x002E

; --- 0xF02FD9-0xF02FE2: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x002FD9, 0x00000A

; ------------------------------------------------------------------
; 0xF02FE3-0xF02FF6 -- 2 display-list records, 20 bytes -- interpreter A
;   entered at: 0xF02FE3, 0xF02FED
;   ends used:  0xF02FED, 0xF02FF7
; ------------------------------------------------------------------
DL_F02FE3:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0008
	.short 0x0021
	.short 0x0028
	.short 0x002C
DL_F02FED:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0008
	.short 0x0049
	.short 0x0022
	.short 0x00C5

; --- 0xF02FF7-0xF03029: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x002FF7, 0x000033

; ------------------------------------------------------------------
; 0xF0302A-0xF03106 -- 15 display-list records, 221 bytes -- interpreter B
;   entered at: 0xF0302A, 0xF0306E, 0xF030E6
;   ends used:  0xF0304C, 0xF030AA, 0xF03107
; ------------------------------------------------------------------
DL_F0302A:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x2808	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F03241	; +0x07 -> XIY: string table
	.short 0x0008	; +0x0B -> BC: bytes per entry
	.short 0x00C1	; +0x0D -> (0x2530)
	.short 0x0054	; +0x0F -> (0x2532)
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x2809	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F03241	; +0x07 -> XIY: string table
	.short 0x0008	; +0x0B -> BC: bytes per entry
	.short 0x00C1	; +0x0D -> (0x2530)
	.short 0x0079	; +0x0F -> (0x2532)
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x280A	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F03241	; +0x07 -> XIY: string table
	.short 0x0008	; +0x0B -> BC: bytes per entry
	.short 0x00C1	; +0x0D -> (0x2530)
	.short 0x009E	; +0x0F -> (0x2532)
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x280B	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F03241	; +0x07 -> XIY: string table
	.short 0x0008	; +0x0B -> BC: bytes per entry
	.short 0x00C1	; +0x0D -> (0x2530)
	.short 0x00C3	; +0x0F -> (0x2532)
DL_F0306E:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AE	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F04CBD	; +0x07 -> XIY: string table
	.short 0x0001	; +0x0B -> BC: bytes per entry
	.short 0x0B97	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x000022F0	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x0B99	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AF	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F04CBD	; +0x07 -> XIY: string table
	.short 0x0001	; +0x0B -> BC: bytes per entry
	.short 0x115F	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00002300	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x1161	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B0	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F04CBD	; +0x07 -> XIY: string table
	.short 0x0001	; +0x0B -> BC: bytes per entry
	.short 0x1727	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00002310	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x1729	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B1	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F04CBD	; +0x07 -> XIY: string table
	.short 0x0001	; +0x0B -> BC: bytes per entry
	.short 0x1CEF	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00002320	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x1CF1	; +0x0D -> IX
DL_F030E6:
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A3	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F031C9	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A3	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F031F1	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A3	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F03219	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF03107-0xF03168: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x003107, 0x000062

; ------------------------------------------------------------------
; 0xF03169-0xF03172 -- 1 display-list records, 10 bytes -- interpreter A
;   entered at: 0xF03169
;   ends used:  0xF03173
; ------------------------------------------------------------------
DL_F03169:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x0048
	.short 0x0109
	.short 0x00C3

; --- 0xF03173-0xF031BE: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x003173, 0x00004C

; ------------------------------------------------------------------
; 0xF031BF-0xF031C8 -- 1 display-list records, 10 bytes -- interpreter A
;   entered at: 0xF031BF
;   ends used:  0xF031C9
; ------------------------------------------------------------------
DL_F031BF:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x000E
	.short 0x003E
	.short 0x00FB
	.short 0x00CE

; ==================================================================
; 0xF031C9-0xF03440 -- display-list OPERAND TABLES (632 bytes, 4 objects)
; ==================================================================
;
; Every object here is named by a display-list record that points at it, and
; its SIZE is proven by tiling: the objects start at the first byte of this
; gap, each extent is a whole number of entries, and the last object's
; handler-implied size ends exactly on the first byte of the next display
; list.  Reproduce with `python3 notes/prom_b_dl_operand_tables.py --exact`.
;
; ------------------------------------------------------------------
; DLTable_F031C9 -- 5 entries of 8 bytes
; Referenced by: display-list record 0xF030E6
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           5 entries is the EXTENT (40 bytes / 8), not the (mask >> shift) + 1
;           = 16 the record would allow.
; ------------------------------------------------------------------
DLTable_F031C9:
	.short 0x000F, 0x0048, 0x0029, 0x0055	; [0]
	.short 0x000F, 0x0048, 0x0029, 0x0055	; [1]
	.short 0x000F, 0x006D, 0x0029, 0x007A	; [2]
	.short 0x000F, 0x0092, 0x0029, 0x009F	; [3]
	.short 0x000F, 0x00B7, 0x0029, 0x00C4	; [4]
; ------------------------------------------------------------------
; DLTable_F031F1 -- 5 entries of 8 bytes
; Referenced by: display-list record 0xF030F1
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           5 entries is the EXTENT (40 bytes / 8), not the (mask >> shift) + 1
;           = 16 the record would allow.
; ------------------------------------------------------------------
DLTable_F031F1:
	.short 0x0036, 0x0046, 0x00B3, 0x0057	; [0]
	.short 0x0036, 0x0046, 0x00B3, 0x0057	; [1]
	.short 0x0036, 0x006B, 0x00B3, 0x007C	; [2]
	.short 0x0036, 0x0090, 0x00B3, 0x00A1	; [3]
	.short 0x0036, 0x00B5, 0x00B3, 0x00C6	; [4]
; ------------------------------------------------------------------
; DLTable_F03219 -- 5 entries of 8 bytes
; Referenced by: display-list record 0xF030FC
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           5 entries is the EXTENT (40 bytes / 8), not the (mask >> shift) + 1
;           = 16 the record would allow.
; ------------------------------------------------------------------
DLTable_F03219:
	.short 0x00BB, 0x0041, 0x00F8, 0x005C	; [0]
	.short 0x00BB, 0x0041, 0x00F8, 0x005C	; [1]
	.short 0x00BB, 0x0066, 0x00F8, 0x0081	; [2]
	.short 0x00BB, 0x008B, 0x00F8, 0x00A6	; [3]
	.short 0x00BB, 0x00B0, 0x00F8, 0x00CB	; [4]
; ------------------------------------------------------------------
; DLTable_F03241 -- 64 entries of 8 characters
; Referenced by: display-list records 0xF0302A, 0xF0303B, 0xF0304C, 0xF0305D
; Evidence: the record's +7 pointer lands here and its +0x0B word is 8, so the
;           entries are 8 bytes wide (handler 0xF31B21/0xF31B39 loads the
;           extracted bit-field into HL as the index).
;           64 entries is the EXTENT (512 bytes / 8), not the (mask >> shift) + 1
;           = 64 the record would allow.
; ------------------------------------------------------------------
DLTable_F03241:
	.ascii "ORIGINAL"	; [0]
	.ascii " STRING "	; [1]
	.ascii "CYLINDER"	; [2]
	.ascii "  CONE  "	; [3]
	.ascii " FLARE  "	; [4]
	.ascii "PLATE L "	; [5]
	.ascii "PLATE H "	; [6]
	.ascii " MEMB L "	; [7]
	.ascii " MEMB H "	; [8]
	.ascii "THROUGH "	; [9]
	.ascii " MELLOW "	; [10]
	.ascii "  MUTE  "	; [11]
	.ascii " BRIGHT "	; [12]
	.ascii "  MOVE  "	; [13]
	.ascii " RANDOM "	; [14]
	.ascii " OCTAVE "	; [15]
	.ascii "HARMONIC"	; [16]
	.ascii " METAL  "	; [17]
	.ascii " BOTTLE "	; [18]
	.ascii " MELLOW "	; [19]
	.ascii "  MUTE  "	; [20]
	.ascii " BRIGHT "	; [21]
	.ascii "  MOVE  "	; [22]
	.ascii " RANDOM "	; [23]
	.ascii " OCTAVE "	; [24]
	.ascii "  SOFT  "	; [25]
	.ascii " MELLOW "	; [26]
	.ascii "  MUTE  "	; [27]
	.ascii " BRIGHT "	; [28]
	.ascii "  MOVE  "	; [29]
	.ascii " RANDOM "	; [30]
	.ascii " OCTAVE "	; [31]
	.ascii " MELLOW "	; [32]
	.ascii "  MUTE  "	; [33]
	.ascii " BRIGHT "	; [34]
	.ascii "  MOVE  "	; [35]
	.ascii " RANDOM "	; [36]
	.ascii " OCTAVE "	; [37]
	.ascii " WOOD L "	; [38]
	.ascii " WOOD H "	; [39]
	.ascii "METAL L "	; [40]
	.ascii "METAL H "	; [41]
	.ascii " MUTE L "	; [42]
	.ascii " MUTE H "	; [43]
	.ascii "BRIGHT L"	; [44]
	.ascii "BRIGHT H"	; [45]
	.ascii " MOVE L "	; [46]
	.ascii " MOVE H "	; [47]
	.ascii "RANDOM L"	; [48]
	.ascii "RANDOM H"	; [49]
	.ascii "SMALL L "	; [50]
	.ascii "SMALL H "	; [51]
	.ascii "LARGE L "	; [52]
	.ascii "LARGE H "	; [53]
	.ascii " MUTE L "	; [54]
	.ascii " MUTE H "	; [55]
	.ascii " SLAP L "	; [56]
	.ascii " SLAP H "	; [57]
	.ascii " MOVE L "	; [58]
	.ascii " MOVE H "	; [59]
	.ascii "RANDOM L"	; [60]
	.ascii "RANDOM H"	; [61]
	.ascii "SPECIAL1"	; [62]
	.ascii "SPECIAL2"	; [63]

; ------------------------------------------------------------------
; 0xF03441-0xF03477 -- 5 display-list records, 55 bytes -- interpreter B
;   entered at: 0xF03441, 0xF03455
;   ends used:  0xF0346E, 0xF03478
; ------------------------------------------------------------------
DL_F03441:
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1236	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1239	; +0x07 -> IX
	.byte 0x01	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
DL_F03455:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x80	; +0x04 AND mask
	.byte 0x07	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F03478	; +0x07 -> XIY: string table
	.short 0x0004	; +0x0B -> BC: bytes per entry
	.short 0x16E6	; +0x0D -> IX
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x148E	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1C0E	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663

; --- 0xF03478-0xF03497: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x003478, 0x000020

; ------------------------------------------------------------------
; 0xF03498-0xF034C5 -- 4 display-list records, 46 bytes -- interpreter B
;   entered at: 0xF03498, 0xF034AD
;   ends used:  0xF034C6
; ------------------------------------------------------------------
DL_F03498:
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x189D	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1196	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
DL_F034AD:
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x139E	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x80	; +0x04 AND mask
	.byte 0x07	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F034D2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x15CD	; +0x0D -> IX

; --- 0xF034C6-0xF034DD: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0034C6, 0x000018

; ------------------------------------------------------------------
; 0xF034DE-0xF0355C -- 11 display-list records, 127 bytes -- interpreter B
;   entered at: 0xF034DE, 0xF034E8, 0xF03522
;   ends used:  0xF03502, 0xF0353C, 0xF0355D
; ------------------------------------------------------------------
DL_F034DE:
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1866	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
DL_F034E8:
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27B0	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x186B	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x80	; +0x04 AND mask
	.byte 0x07	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F034D8	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x187A	; +0x0D -> IX
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1870	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1874	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1D3E	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
DL_F03522:
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27B1	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1D43	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AC	; +0x02 source variable, 16-bit address
	.byte 0x80	; +0x04 AND mask
	.byte 0x07	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F034D8	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1D52	; +0x0D -> IX
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AD	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1D48	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AE	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1D4C	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x01	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F035AA	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF0355D-0xF03580: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x00355D, 0x000024

; ------------------------------------------------------------------
; 0xF03581-0xF035A9 -- 4 display-list records, 41 bytes -- interpreter A (3 records) and B (1)
;   entered at: 0xF03581, 0xF03595, 0xF0359F
;   ends used:  0xF03595, 0xF0359F, 0xF035AA
; ------------------------------------------------------------------
DL_F03581:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0029
	.short 0x0093
	.short 0x0133
	.short 0x00CD
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x00FD
	.short 0x00DA
	.short 0x0131
	.short 0x00E4
DL_F03595:
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x00FD
	.short 0x00DA
	.short 0x0131
	.short 0x00E4
DL_F0359F:
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x01	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F035BA	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; ==================================================================
; 0xF035AA-0xF035C9 -- display-list OPERAND TABLES (32 bytes, 2 objects)
; ==================================================================
;
; Every object here is named by a display-list record that points at it, and
; its SIZE is proven by tiling: the objects start at the first byte of this
; gap, each extent is a whole number of entries, and the last object's
; handler-implied size ends exactly on the first byte of the next display
; list.  Reproduce with `python3 notes/prom_b_dl_operand_tables.py --exact`.
;
; ------------------------------------------------------------------
; DLTable_F035AA -- 2 entries of 8 bytes
; Referenced by: display-list records 0xF03552, 0xF0360C, 0xF036B7
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F035AA:
	.short 0x0029, 0x0093, 0x0133, 0x00AE	; [0]
	.short 0x0029, 0x00B2, 0x0133, 0x00CD	; [1]
; ------------------------------------------------------------------
; DLTable_F035BA -- 2 entries of 8 bytes
; Referenced by: display-list record 0xF0359F
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F035BA:
	.short 0x0029, 0x00B2, 0x0133, 0x00CD	; [0]
	.short 0x0029, 0x0093, 0x0133, 0x00AE	; [1]

; ------------------------------------------------------------------
; 0xF035CA-0xF03616 -- 7 display-list records, 77 bytes -- interpreter B
;   entered at: 0xF035CA
;   ends used:  0xF03617
; ------------------------------------------------------------------
DL_F035CA:
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1866	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x186C	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1D51	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1D3E	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1D44	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AC	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1D4B	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x01	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F035AA	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF03617-0xF03632: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x003617, 0x00001C

; ------------------------------------------------------------------
; 0xF03633-0xF036C1 -- 11 display-list records, 143 bytes -- interpreter B
;   entered at: 0xF03633, 0xF036A3
;   ends used:  0xF036C2
; ------------------------------------------------------------------
DL_F03633:
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AC	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x186B	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1870	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1875	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x187A	; +0x0D -> IX
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27B0	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1D43	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AE	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1D48	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AD	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1D4D	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AF	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1D52	; +0x0D -> IX
DL_F036A3:
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x80	; +0x04 AND mask
	.byte 0x07	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1867	; +0x07 -> IX
	.byte 0x01	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x80	; +0x04 AND mask
	.byte 0x07	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1D3F	; +0x07 -> IX
	.byte 0x01	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x01	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F035AA	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF036C2-0xF03891: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0036C2, 0x0001D0

; ------------------------------------------------------------------
; 0xF03892-0xF039EC -- 41 display-list records, 347 bytes -- interpreter A
;   entered at: 0xF03892, 0xF039A9, 0xF039D9
;   ends used:  0xF03943, 0xF039A9, 0xF039D9, 0xF039E3, 0xF039ED
; ------------------------------------------------------------------
DL_F03892:
	.byte 0x1C, 0x10	; op 1C, 16 bytes -> handler 0xF31A52
	.short 0x0073
	.short 0x0005
	.ascii "T0NE LAYER"
	.byte 0x17, 0x10	; op 17, 16 bytes -> handler 0xF31A52
	.short 0x0006
	.short 0x0007
	.ascii "SOUND EDIT"
	.byte 0x20, 0x08	; op 20, 8 bytes -> handler 0xF31A3A
	.short 0x04D1
	.ascii "TRIG"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0134
	.short 0x0021
	.byte 0x11	; character codes below 0x20
	.byte 0x20, 0x07	; op 20, 7 bytes -> handler 0xF31A3A
	.short 0x06DB
	.ascii "GER"
	.byte 0x20, 0x07	; op 20, 7 bytes -> handler 0xF31A3A
	.short 0x0B11
	.ascii "KEY"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0134
	.short 0x0048
	.byte 0x11	; character codes below 0x20
	.byte 0x20, 0x09	; op 20, 9 bytes -> handler 0xF31A3A
	.short 0x0D19
	.ascii "LAYER"
	.byte 0x20, 0x07	; op 20, 7 bytes -> handler 0xF31A3A
	.short 0x1101
	.ascii "VEL"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0134
	.short 0x006E
	.byte 0x11	; character codes below 0x20
	.byte 0x20, 0x09	; op 20, 9 bytes -> handler 0xF31A3A
	.short 0x1309
	.ascii "LAYER"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0134
	.short 0x0095
	.byte 0x11	; character codes below 0x20
	.byte 0x20, 0x07	; op 20, 7 bytes -> handler 0xF31A3A
	.short 0x1719
	.ascii "PAN"
	.byte 0x20, 0x08	; op 20, 8 bytes -> handler 0xF31A3A
	.short 0x1922
	.ascii "NING"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0004
	.short 0x0004
	.short 0x0044
	.short 0x0010
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0104
	.short 0x001A
	.short 0x0134
	.short 0x0038
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0104
	.short 0x0042
	.short 0x0134
	.short 0x0060
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0104
	.short 0x0068
	.short 0x0134
	.short 0x0086
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0104
	.short 0x008F
	.short 0x0134
	.short 0x00AD
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x64
	.short 0x0033
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1F72
	.ascii "_"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1F82
	.ascii "_"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2061
	.ascii "L"
	.byte 0x06, 0x13	; op 06, 19 bytes -> handler 0xF31A3A
	.short 0x2063
	.ascii "FADE LOW HIGH H"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x2073
	.ascii "FADE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x244B
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2451
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2456
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x245B
	.byte 0x12	; character codes below 0x20
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0045
	.short 0x00CC
	.short 0x00FB
	.short 0x00E9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0045
	.short 0x00DB
	.short 0x00FB
	.short 0x00DB
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x009C
	.short 0x00CC
	.short 0x009C
	.short 0x00E9
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0046
	.short 0x00DC
	.short 0x00FA
	.short 0x00E8
DL_F039A9:
	.byte 0x1C, 0x11	; op 1C, 17 bytes -> handler 0xF31A52
	.short 0x0072
	.short 0x0005
	.ascii "T0NE SELECT"
	.byte 0x17, 0x10	; op 17, 16 bytes -> handler 0xF31A52
	.short 0x0006
	.short 0x0007
	.ascii "SOUND EDIT"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0004
	.short 0x0004
	.short 0x0044
	.short 0x0010
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x61
	.short 0x0083
DL_F039D9:
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x0C30
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x11F8
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1770
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1D38
	.byte 0x10	; character codes below 0x20

; --- 0xF039ED-0xF03C94: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0039ED, 0x0002A8

; ------------------------------------------------------------------
; 0xF03C95-0xF03D49 -- 18 display-list records, 181 bytes -- interpreter A
;   entered at: 0xF03C95
;   ends used:  0xF03D4A
; ------------------------------------------------------------------
DL_F03C95:
	.byte 0x1C, 0x0B	; op 1C, 11 bytes -> handler 0xF31A52
	.short 0x008C
	.short 0x0005
	.ascii "PITCH"
	.byte 0x17, 0x10	; op 17, 16 bytes -> handler 0xF31A52
	.short 0x0006
	.short 0x0007
	.ascii "SOUND EDIT"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x068B
	.ascii "ENV "
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x0B	; op 06, 11 bytes -> handler 0xF31A3A
	.short 0x0BD9
	.ascii "PITCH "
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x112B
	.ascii "LF0 "
	.byte 0x11	; character codes below 0x20
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0004
	.short 0x0004
	.short 0x0044
	.short 0x0010
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x0025
	.short 0x0134
	.short 0x0036
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0104
	.short 0x0041
	.short 0x0134
	.short 0x005E
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x0069
	.short 0x0134
	.short 0x007A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0120
	.short 0x003D
	.short 0x0127
	.short 0x003D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0121
	.short 0x003E
	.short 0x0126
	.short 0x003E
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0122
	.short 0x003F
	.short 0x0125
	.short 0x003F
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0122
	.short 0x0060
	.short 0x0125
	.short 0x0060
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0121
	.short 0x0061
	.short 0x0126
	.short 0x0061
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0120
	.short 0x0062
	.short 0x0127
	.short 0x0062
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0123
	.short 0x0036
	.short 0x0124
	.short 0x0041
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0123
	.short 0x005E
	.short 0x0124
	.short 0x0069
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x07
	.short 0x0036

; --- 0xF03D4A-0xF03D67: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x003D4A, 0x00001E

; ------------------------------------------------------------------
; 0xF03D68-0xF03F76 -- 58 display-list records, 527 bytes -- interpreter A
;   entered at: 0xF03D68, 0xF03F31
;   ends used:  0xF03F31, 0xF03F77
; ------------------------------------------------------------------
DL_F03D68:
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0031
	.short 0x0037
	.ascii "KEY"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x005B
	.short 0x0037
	.ascii "DE-"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0084
	.short 0x0037
	.ascii "TONE"
	.byte 0x17, 0x11	; op 17, 17 bytes -> handler 0xF31A52
	.short 0x00B6
	.short 0x0089
	.ascii "KEY SCALING"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0031
	.short 0x0040
	.ascii "SHIFT"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x005B
	.short 0x0040
	.ascii "TUNE"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0084
	.short 0x0040
	.ascii "SCALE"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x0C30
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x0F	; op 17, 15 bytes -> handler 0xF31A52
	.short 0x00BB
	.short 0x00AF
	.ascii "OCT-SHIFT"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x11F8
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x176C
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1770
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1797
	.byte 0xA9	; character codes below 0x20
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x0113
	.short 0x00AC
	.ascii "CURSOR"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1D38
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1DAC
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1DAF
	.byte 0xA9	; character codes below 0x20
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0033
	.short 0x00D1
	.ascii "KEY"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x0052
	.short 0x00D1
	.ascii "DETUNE"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x007D
	.short 0x00D1
	.ascii "SCALE"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00CD
	.short 0x00D1
	.ascii "VALUE"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21EF
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F4
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F9
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2203
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x237F
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2384
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2389
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2393
	.byte 0x8E	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0033
	.short 0x00A8
	.short 0x00CA
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00B3
	.short 0x0083
	.short 0x00FB
	.short 0x00A2
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0117
	.short 0x0094
	.short 0x0130
	.short 0x00A3
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0119
	.short 0x0096
	.short 0x012E
	.short 0x00A1
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00B3
	.short 0x00AB
	.short 0x00FB
	.short 0x00CA
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0117
	.short 0x00BB
	.short 0x0130
	.short 0x00CA
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0119
	.short 0x00BD
	.short 0x012E
	.short 0x00C8
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00DA
	.short 0x0046
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00DA
	.short 0x006E
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00DA
	.short 0x0096
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00DA
	.short 0x00E6
	.short 0x00EE
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x004A
	.short 0x00A8
	.short 0x004A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x006A
	.short 0x00A8
	.short 0x006A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x008A
	.short 0x00A8
	.short 0x008A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00B3
	.short 0x0091
	.short 0x00FB
	.short 0x0091
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x00AA
	.short 0x00A8
	.short 0x00AA
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00B3
	.short 0x00B9
	.short 0x00FB
	.short 0x00B9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00E4
	.short 0x0046
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00E4
	.short 0x006E
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00E4
	.short 0x0096
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00E4
	.short 0x00E6
	.short 0x00E4
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x002C
	.short 0x0033
	.short 0x002C
	.short 0x00CA
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0106
	.short 0x0043
	.short 0x0132
	.short 0x005C
DL_F03F31:
	.byte 0x17, 0x11	; op 17, 17 bytes -> handler 0xF31A52
	.short 0x0043
	.short 0x00B2
	.ascii "START PITCH"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0092
	.short 0x00B2
	.ascii "STOP"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00AD
	.short 0x00B2
	.ascii "PITCH"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00D8
	.short 0x00B2
	.ascii "TOTAL"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00FC
	.short 0x00B2
	.ascii "DEPTH"
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00D5
	.short 0x00AE
	.short 0x00D5
	.short 0x00CB

; --- 0xF03F77-0xF0402D: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x003F77, 0x0000B7

; ------------------------------------------------------------------
; 0xF0402E-0xF04041 -- 2 display-list records, 20 bytes -- interpreter A
;   entered at: 0xF0402E, 0xF04038
;   ends used:  0xF04038, 0xF04042
; ------------------------------------------------------------------
DL_F0402E:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x00D6
	.short 0x0046
	.short 0x0107
	.short 0x00E1
DL_F04038:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x00D6
	.short 0x0046
	.short 0x010A
	.short 0x00A1

; --- 0xF04042-0xF0417D: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x004042, 0x00013C

; ------------------------------------------------------------------
; 0xF0417E-0xF04573 -- 115 display-list records, 1014 bytes -- interpreter A
;   entered at: 0xF0417E, 0xF0426B, 0xF04344, 0xF04358, 0xF04415, 0xF04560
;   ends used:  0xF0426B, 0xF04323, 0xF04344, 0xF04358, 0xF04370, 0xF04415, 0xF04560, 0xF04574
; ------------------------------------------------------------------
DL_F0417E:
	.byte 0x06, 0x0B	; op 06, 11 bytes -> handler 0xF31A3A
	.short 0x0110
	.ascii "PAGE1/2"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0043
	.short 0x003E
	.ascii "LEVEL"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0073
	.short 0x003E
	.ascii "TOUCH"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00A3
	.short 0x003E
	.ascii "CURVE"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x004E
	.short 0x00D1
	.ascii "LEVEL"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x007C
	.short 0x00D1
	.ascii "TOUCH"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00A5
	.short 0x00D1
	.ascii "CURVE"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F3
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F9
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21FE
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2383
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2389
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x238E
	.byte 0x8E	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0035
	.short 0x00D4
	.short 0x00CA
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0051
	.short 0x00DA
	.short 0x0066
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00DA
	.short 0x0096
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00DA
	.short 0x00BE
	.short 0x00EE
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x004A
	.short 0x00D4
	.short 0x004A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x006A
	.short 0x00D4
	.short 0x006A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x008A
	.short 0x00D4
	.short 0x008A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x00AA
	.short 0x00D4
	.short 0x00AA
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0051
	.short 0x00E4
	.short 0x0066
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00E4
	.short 0x0096
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00E4
	.short 0x00BE
	.short 0x00E4
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x0035
	.short 0x002E
	.short 0x00CA
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x0043
	.short 0x0132
	.short 0x005C
DL_F0426B:
	.byte 0x06, 0x0B	; op 06, 11 bytes -> handler 0xF31A3A
	.short 0x0110
	.ascii "PAGE2/2"
	.byte 0x17, 0x10	; op 17, 16 bytes -> handler 0xF31A52
	.short 0x0076
	.short 0x003E
	.ascii "KEY FOLLOW"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0042
	.short 0x0082
	.ascii "0"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x005D
	.short 0x0082
	.ascii "1"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x007A
	.short 0x0082
	.ascii "2"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0096
	.short 0x0082
	.ascii "3"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00B2
	.short 0x0082
	.ascii "4"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00CE
	.short 0x0082
	.ascii "5"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00EA
	.short 0x0082
	.ascii "6"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0056
	.short 0x00D1
	.ascii "SLOPE"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00A1
	.short 0x00D1
	.ascii "RANGE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x21AB
	.ascii "_"
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x21B0
	.ascii "__"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21FC
	.ascii "_"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x244C
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2451
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2456
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x245B
	.byte 0x12	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x0048
	.short 0x00FF
	.short 0x007A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0052
	.short 0x00DB
	.short 0x00EB
	.short 0x00DB
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0077
	.short 0x00CD
	.short 0x0077
	.short 0x00E9
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x0043
	.short 0x0132
	.short 0x005C
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0053
	.short 0x00DC
	.short 0x00EA
	.short 0x00E8
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x000E
	.short 0x005F
	.ascii "LEVEL"
	.byte 0x17, 0x16	; op 17, 22 bytes -> handler 0xF31A52
	.short 0x006D
	.short 0x00C3
	.ascii "LEVEL KEY FOLLOW"
DL_F04344:
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x0061
	.short 0x00FF
	.short 0x0061
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0052
	.short 0x00CD
	.short 0x00EB
	.short 0x00E9
DL_F04358:
	.byte 0x17, 0x0E	; op 17, 14 bytes -> handler 0xF31A52
	.short 0x007F
	.short 0x0030
	.ascii "ENVELOPE"
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0032
	.short 0x003A
	.short 0x0101
	.short 0x0091
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x00C3
	.short 0x0097
	.ascii "KEYOFF"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x000B
	.short 0x00CF
	.ascii "ATK"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0029
	.short 0x00CF
	.ascii "PEAK"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x0047
	.short 0x00CF
	.ascii "DECAY1"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0071
	.short 0x00CF
	.ascii "SUST1"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x009B
	.short 0x00CF
	.ascii "DECAY2"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00C5
	.short 0x00CF
	.ascii "SUST2"
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x00EF
	.short 0x00CF
	.ascii "RELEASE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x241A
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x241F
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2424
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2429
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x242E
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2433
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2439
	.byte 0x12	; character codes below 0x20
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0003
	.short 0x00CB
	.short 0x011D
	.short 0x00E8
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0003
	.short 0x00D9
	.short 0x011D
	.short 0x00D9
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0004
	.short 0x00DA
	.short 0x011C
	.short 0x00E7
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x0027
	.short 0x0132
	.short 0x0034
DL_F04415:
	.byte 0x06, 0x0B	; op 06, 11 bytes -> handler 0xF31A3A
	.short 0x0110
	.ascii "PAGE2/2"
	.byte 0x17, 0x12	; op 17, 18 bytes -> handler 0xF31A52
	.short 0x0055
	.short 0x003E
	.ascii "KEY FOLLOW ("
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0042
	.short 0x0082
	.ascii "0"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x005D
	.short 0x0082
	.ascii "1"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x007A
	.short 0x0082
	.ascii "2"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0096
	.short 0x0082
	.ascii "3"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00B2
	.short 0x0082
	.ascii "4"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00CE
	.short 0x0082
	.ascii "5"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00EA
	.short 0x0082
	.ascii "6"
	.byte 0x17, 0x0E	; op 17, 14 bytes -> handler 0xF31A52
	.short 0x003D
	.short 0x00C3
	.ascii "ENVELOPE"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0073
	.short 0x00C3
	.ascii "KEY"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x008B
	.short 0x00C3
	.ascii "FOLLOW"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0100
	.short 0x00C3
	.ascii "TOUCH"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0007
	.short 0x00D1
	.ascii "ATK"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0025
	.short 0x00D1
	.ascii "DECAY"
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x0049
	.short 0x00D1
	.ascii "RELEASE"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x009E
	.short 0x00D1
	.ascii "RANGE"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x00F1
	.short 0x00D1
	.ascii "ATTACK"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x011B
	.short 0x00D1
	.ascii "DECAY"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x21AA
	.ascii "_"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x21B0
	.ascii "_"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21FB
	.ascii "_"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21FF
	.ascii "_"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2442
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2447
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x244C
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2451
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2456
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x245B
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2460
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2466
	.byte 0x12	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x0048
	.short 0x00FF
	.short 0x007A
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00ED
	.short 0x00CD
	.short 0x013D
	.short 0x00E9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0003
	.short 0x00DA
	.short 0x00E6
	.short 0x00DA
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00ED
	.short 0x00DA
	.short 0x013D
	.short 0x00DA
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0075
	.short 0x00CD
	.short 0x0075
	.short 0x00E9
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x0027
	.short 0x0132
	.short 0x0034
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0004
	.short 0x00DB
	.short 0x00E5
	.short 0x00E8
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x00EE
	.short 0x00DB
	.short 0x013C
	.short 0x00E8
DL_F04560:
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x0061
	.short 0x00FF
	.short 0x0061
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0003
	.short 0x00CD
	.short 0x00E6
	.short 0x00E9

; --- 0xF04574-0xF04671: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x004574, 0x0000FE

; ------------------------------------------------------------------
; 0xF04672-0xF04CBC -- 172 display-list records, 1611 bytes -- interpreter A
;   entered at: 0xF04672, 0xF0467D, 0xF047CA, 0xF047DF, 0xF047F3, 0xF04889, 0xF0489D, 0xF048B2, 0xF049BC, 0xF049D3, 0xF049DD, 0xF049F3, 0xF049FD, 0xF04B1F, 0xF04B6C, 0xF04CA9
;   ends used:  0xF0467D, 0xF047CA, 0xF047DF, 0xF047F3, 0xF04889, 0xF0489D, 0xF048B2, 0xF049BC, 0xF049D3, 0xF049E7, 0xF049F3, 0xF049FD, 0xF04B1F, 0xF04B6C, 0xF04CA9, 0xF04CBD
; ------------------------------------------------------------------
DL_F04672:
	.byte 0x06, 0x0B	; op 06, 11 bytes -> handler 0xF31A3A
	.short 0x0110
	.ascii "PAGE1/2"
DL_F0467D:
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x0043
	.short 0x001E
	.ascii "FILTER:"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x00D5
	.short 0x0062
	.ascii "CUTOFF"
	.byte 0x17, 0x0F	; op 17, 15 bytes -> handler 0xF31A52
	.short 0x0043
	.short 0x006C
	.ascii "EQUALIZER"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00DD
	.short 0x00B0
	.ascii "FREQ"
	.byte 0x06, 0x0A	; op 06, 10 bytes -> handler 0xF31A3A
	.short 0x1E2F
	.ascii "FILTER"
	.byte 0x06, 0x0A	; op 06, 10 bytes -> handler 0xF31A3A
	.short 0x1E43
	.ascii "EQUALI"
	.byte 0x20, 0x05	; op 20, 5 bytes -> handler 0xF31A3A
	.short 0x1E49
	.ascii "Z"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1E4A
	.ascii "ER"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x0006
	.short 0x00D1
	.ascii "CUTOFF"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0034
	.short 0x00D1
	.ascii "RESO"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0059
	.short 0x00D1
	.ascii "TOUCH"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x007D
	.short 0x00D1
	.ascii "CURVE"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00CA
	.short 0x00D1
	.ascii "RANGE"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00F4
	.short 0x00D1
	.ascii "FREQ"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0118
	.short 0x00D1
	.ascii "GAIN"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x228C
	.ascii "K"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x22A9
	.ascii "K"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x2291
	.ascii "dB"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x22AD
	.ascii "dB"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2442
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2447
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x244C
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2451
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x245B
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2460
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2465
	.byte 0x12	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0042
	.short 0x0027
	.short 0x00E9
	.short 0x005E
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0042
	.short 0x0075
	.short 0x00E9
	.short 0x00AC
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0002
	.short 0x00CD
	.short 0x00A0
	.short 0x00E9
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00BB
	.short 0x00CD
	.short 0x013C
	.short 0x00E9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0092
	.short 0x0071
	.short 0x0099
	.short 0x0071
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0093
	.short 0x0072
	.short 0x0098
	.short 0x0072
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0094
	.short 0x0073
	.short 0x0097
	.short 0x0073
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0002
	.short 0x00DB
	.short 0x00A0
	.short 0x00DB
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00BB
	.short 0x00DB
	.short 0x013C
	.short 0x00DB
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0095
	.short 0x0060
	.short 0x0096
	.short 0x0075
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0003
	.short 0x00DC
	.short 0x009F
	.short 0x00E8
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x00BC
	.short 0x00DC
	.short 0x013B
	.short 0x00E8
DL_F047CA:
	.byte 0x17, 0x15	; op 17, 21 bytes -> handler 0xF31A52
	.short 0x006D
	.short 0x001E
	.ascii "HIGH PASS -12dB"
DL_F047DF:
	.byte 0x17, 0x14	; op 17, 20 bytes -> handler 0xF31A52
	.short 0x006D
	.short 0x001E
	.ascii "LOW PASS -12dB"
DL_F047F3:
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x0043
	.short 0x0043
	.ascii "FILTER:"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x00D3
	.short 0x0087
	.ascii "CUTOFF"
	.byte 0x06, 0x0A	; op 06, 10 bytes -> handler 0xF31A3A
	.short 0x1E39
	.ascii "FILTER"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x0056
	.short 0x00D1
	.ascii "CUTOFF"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0084
	.short 0x00D1
	.ascii "RESO"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00A9
	.short 0x00D1
	.ascii "TOUCH"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00CD
	.short 0x00D1
	.ascii "CURVE"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2296
	.ascii "K"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x229B
	.ascii "dB"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x244C
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2451
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2456
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x245B
	.byte 0x12	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0042
	.short 0x004C
	.short 0x00E9
	.short 0x0083
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x004D
	.short 0x00CD
	.short 0x00F0
	.short 0x00E9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x004D
	.short 0x00DB
	.short 0x00F0
	.short 0x00DB
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x004E
	.short 0x00DC
	.short 0x00EF
	.short 0x00E8
DL_F04889:
	.byte 0x17, 0x14	; op 17, 20 bytes -> handler 0xF31A52
	.short 0x006D
	.short 0x0043
	.ascii "LOW PASS -24dB"
DL_F0489D:
	.byte 0x17, 0x15	; op 17, 21 bytes -> handler 0xF31A52
	.short 0x006D
	.short 0x0043
	.ascii "HIGH PASS -24dB"
DL_F048B2:
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x0043
	.short 0x0043
	.ascii "FILTER:"
	.byte 0x17, 0x0F	; op 17, 15 bytes -> handler 0xF31A52
	.short 0x006D
	.short 0x0043
	.ascii "BAND PASS"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0055
	.short 0x0087
	.byte 0x7F	; character codes below 0x20
	.ascii " LOW"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x00A9
	.short 0x0087
	.ascii "HIGH ~"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x00D4
	.short 0x0087
	.ascii "CUTOFF"
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x1E30
	.ascii "LOW"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x1E3F
	.ascii "HIGH"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x0026
	.short 0x00D1
	.ascii "CUTOFF"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0054
	.short 0x00D1
	.ascii "RESO"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x007E
	.short 0x00D1
	.ascii "CUTOFF"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00AC
	.short 0x00D1
	.ascii "RESO"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00D1
	.short 0x00D1
	.ascii "TOUCH"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00F5
	.short 0x00D1
	.ascii "CURVE"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x228F
	.ascii "K"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x2294
	.ascii "dB"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x229B
	.ascii "K"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x22A0
	.ascii "dB"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2446
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x244B
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2451
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2456
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x245B
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2460
	.byte 0x12	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0042
	.short 0x004C
	.short 0x00E9
	.short 0x0083
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x001D
	.short 0x00CD
	.short 0x0075
	.short 0x00E9
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x007A
	.short 0x00CD
	.short 0x0118
	.short 0x00E9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x001D
	.short 0x00DB
	.short 0x0075
	.short 0x00DB
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007A
	.short 0x00DB
	.short 0x0118
	.short 0x00DB
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x001E
	.short 0x00DC
	.short 0x0074
	.short 0x00E8
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x007B
	.short 0x00DC
	.short 0x0117
	.short 0x00E8
DL_F049BC:
	.byte 0x1C, 0x0D	; op 1C, 13 bytes -> handler 0xF31A52
	.short 0x0070
	.short 0x0060
	.ascii "THROUGH"
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0042
	.short 0x004C
	.short 0x00E9
	.short 0x0083
DL_F049D3:
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0032
	.short 0x0066
	.short 0x0101
	.short 0x0066
DL_F049DD:
	.byte 0x12, 0x0A	; op 12, 10 bytes -> handler 0xF31A75
	.short 0x00D5
	.short 0x003A
	.short 0x00D5
	.short 0x0091
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x00C3
	.short 0x0097
	.ascii "KEYOFF"
DL_F049F3:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x00C3
	.short 0x003A
	.short 0x00E7
	.short 0x009D
DL_F049FD:
	.byte 0x06, 0x0B	; op 06, 11 bytes -> handler 0xF31A3A
	.short 0x0110
	.ascii "PAGE1/2"
	.byte 0x17, 0x0E	; op 17, 14 bytes -> handler 0xF31A52
	.short 0x007F
	.short 0x0030
	.ascii "ENVELOPE"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x00C3
	.short 0x0097
	.ascii "KEYOFF"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x17BE
	.byte 0x8D	; character codes below 0x20
	.ascii " "
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0126
	.short 0x00AA
	.ascii "CUR"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x012C
	.short 0x00B3
	.ascii "SOR"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1DFE
	.byte 0x8E	; character codes below 0x20
	.ascii " "
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x000B
	.short 0x00CF
	.ascii "ATK"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0029
	.short 0x00CF
	.ascii "PEAK"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x0047
	.short 0x00CF
	.ascii "DECAY1"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0071
	.short 0x00CF
	.ascii "SUST1"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x009B
	.short 0x00CF
	.ascii "DECAY2"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00C5
	.short 0x00CF
	.ascii "SUST2"
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x00EF
	.short 0x00CF
	.ascii "RELEASE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x241A
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x241F
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2424
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2429
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x242E
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2433
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2439
	.byte 0x12	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0032
	.short 0x003A
	.short 0x0101
	.short 0x0091
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0126
	.short 0x0096
	.short 0x013F
	.short 0x00A5
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0128
	.short 0x0098
	.short 0x013D
	.short 0x00A3
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x003C
	.short 0x00AE
	.short 0x011D
	.short 0x00CB
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0126
	.short 0x00BD
	.short 0x013F
	.short 0x00CC
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0128
	.short 0x00BF
	.short 0x013D
	.short 0x00CA
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x003C
	.short 0x00BC
	.short 0x011D
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x008A
	.short 0x00AE
	.short 0x008A
	.short 0x00CB
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0003
	.short 0x00CB
	.short 0x011D
	.short 0x00E8
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0003
	.short 0x00D9
	.short 0x011D
	.short 0x00D9
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x0027
	.short 0x0132
	.short 0x0034
DL_F04B1F:
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0041
	.short 0x00B2
	.ascii "START"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0063
	.short 0x00B2
	.ascii "POINT"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x008E
	.short 0x00B2
	.ascii "STOP"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00A9
	.short 0x00B2
	.ascii "POINT"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x00CC
	.short 0x00B2
	.ascii "CUTOFF"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x00F6
	.short 0x00B2
	.ascii "ADJUST"
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00CA
	.short 0x00AE
	.short 0x00CA
	.short 0x00CB
DL_F04B6C:
	.byte 0x06, 0x0B	; op 06, 11 bytes -> handler 0xF31A3A
	.short 0x0110
	.ascii "PAGE2/2"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0055
	.short 0x003E
	.ascii "KEY"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x006D
	.short 0x003E
	.ascii "FOLLOW"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0097
	.short 0x003E
	.ascii "("
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0042
	.short 0x0082
	.ascii "0"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x005D
	.short 0x0082
	.ascii "1"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x007A
	.short 0x0082
	.ascii "2"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0096
	.short 0x0082
	.ascii "3"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00B2
	.short 0x0082
	.ascii "4"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00CE
	.short 0x0082
	.ascii "5"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00EA
	.short 0x0082
	.ascii "6"
	.byte 0x17, 0x0E	; op 17, 14 bytes -> handler 0xF31A52
	.short 0x003D
	.short 0x00C3
	.ascii "ENVELOPE"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0073
	.short 0x00C3
	.ascii "KEY"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x008B
	.short 0x00C3
	.ascii "FOLLOW"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0100
	.short 0x00C3
	.ascii "TOUCH"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x0022
	.short 0x00D1
	.ascii "ATTACK"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x004C
	.short 0x00D1
	.ascii "DECAY"
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x0070
	.short 0x00D1
	.ascii "RELEASE"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x00A4
	.short 0x00D1
	.ascii "CENTER"
	.byte 0x17, 0x0E	; op 17, 14 bytes -> handler 0xF31A52
	.short 0x00E6
	.short 0x00D1
	.ascii "ADR-TIME"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x011C
	.short 0x00D1
	.ascii "DEPTH"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2447
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x244C
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2451
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2456
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2460
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2466
	.byte 0x12	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x0048
	.short 0x00FF
	.short 0x007A
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00E4
	.short 0x00CD
	.short 0x013D
	.short 0x00E9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x001E
	.short 0x00DA
	.short 0x00CE
	.short 0x00DA
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00E4
	.short 0x00DA
	.short 0x013D
	.short 0x00DA
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x009E
	.short 0x00CD
	.short 0x009E
	.short 0x00E9
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x001F
	.short 0x00DB
	.short 0x00CD
	.short 0x00E8
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x00E5
	.short 0x00DB
	.short 0x013C
	.short 0x00E8
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x0027
	.short 0x0132
	.short 0x0034
DL_F04CA9:
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x0061
	.short 0x00FF
	.short 0x0061
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x001E
	.short 0x00CD
	.short 0x00CE
	.short 0x00E9

; ==================================================================
; 0xF04CBD-0xF04CDD -- display-list OPERAND TABLES (33 bytes, 2 objects)
; ==================================================================
;
; Every object here is named by a display-list record that points at it, and
; its SIZE is proven by tiling: the objects start at the first byte of this
; gap, each extent is a whole number of entries, and the last object's
; handler-implied size ends exactly on the first byte of the next display
; list.  Reproduce with `python3 notes/prom_b_dl_operand_tables.py --exact`.
;
; ------------------------------------------------------------------
; DLTable_F04CBD -- 25 entries of 1 characters
; Referenced by: display-list records 0xF0306E, 0xF0308C, 0xF030AA, 0xF030C8, 0xF33549, 0xF33B09, 0xF33B27, 0xF33B45, 0xF33B63
; Evidence: the record's +7 pointer lands here and its +0x0B word is 1, so the
;           entries are 1 bytes wide (handler 0xF31B21/0xF31B39 loads the
;           extracted bit-field into HL as the index).
;           25 entries is the EXTENT (25 bytes / 1), not the (mask >> shift) + 1
;           = 128 the record would allow.
; ------------------------------------------------------------------
DLTable_F04CBD:
	.ascii "A"	; [0]
	.ascii "B"	; [1]
	.ascii "C"	; [2]
	.ascii "D"	; [3]
	.ascii "E"	; [4]
	.ascii "F"	; [5]
	.ascii "G"	; [6]
	.ascii "H"	; [7]
	.ascii "I"	; [8]
	.ascii "J"	; [9]
	.ascii "K"	; [10]
	.ascii "L"	; [11]
	.ascii "M"	; [12]
	.ascii "N"	; [13]
	.ascii "O"	; [14]
	.ascii "P"	; [15]
	.ascii "Q"	; [16]
	.ascii "R"	; [17]
	.ascii "S"	; [18]
	.ascii "U"	; [19]
	.ascii "V"	; [20]
	.ascii "W"	; [21]
	.ascii "X"	; [22]
	.ascii "Y"	; [23]
	.ascii "Z"	; [24]
; ------------------------------------------------------------------
; DLTable_F04CD6 -- 2 entries of 4 characters
; Referenced by: display-list record 0xF04D85
; Evidence: the record's +7 pointer lands here and its +0x0B word is 4, so the
;           entries are 4 bytes wide (handler 0xF31B21/0xF31B39 loads the
;           extracted bit-field into HL as the index).
;           2 entries is the EXTENT (8 bytes / 4), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F04CD6:
	.ascii "LOW "	; [0]
	.ascii "HIGH"	; [1]

; ------------------------------------------------------------------
; 0xF04CDE-0xF04CE7 -- 1 display-list records, 10 bytes -- interpreter A
;   entered at: 0xF04CDE
;   ends used:  0xF04CE8
; ------------------------------------------------------------------
DL_F04CDE:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x004A
	.short 0x0108
	.short 0x00CA

; --- 0xF04CE8-0xF04D42: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x004CE8, 0x00005B

; ------------------------------------------------------------------
; 0xF04D43-0xF04DA2 -- 7 display-list records, 96 bytes -- interpreter B
;   entered at: 0xF04D43, 0xF04D85
;   ends used:  0xF04DA3
; ------------------------------------------------------------------
DL_F04D43:
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0xE0	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2298	; +0x07 -> IX
	.byte 0x01	; +0x09 digit count
	.byte 0x03	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2294	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F05CF8	; +0x07 -> XIY: string table
	.short 0x0005	; +0x0B -> BC: bytes per entry
	.short 0x2289	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F04DB7	; +0x07 -> XIY: string table
	.short 0x0002	; +0x0B -> BC: bytes per entry
	.short 0x228F	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F05CF8	; +0x07 -> XIY: string table
	.short 0x0005	; +0x0B -> BC: bytes per entry
	.short 0x22A5	; +0x0D -> IX
DL_F04D85:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0x80	; +0x04 AND mask
	.byte 0x07	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F04CD6	; +0x07 -> XIY: string table
	.short 0x0004	; +0x0B -> BC: bytes per entry
	.short 0x22A0	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F04DD5	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22AA	; +0x0D -> IX

; --- 0xF04DA3-0xF04DFE: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x004DA3, 0x00005C

; ------------------------------------------------------------------
; 0xF04DFF-0xF04E31 -- 4 display-list records, 51 bytes -- interpreter B
;   entered at: 0xF04DFF
;   ends used:  0xF04E32
; ------------------------------------------------------------------
DL_F04DFF:
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0xE0	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x22A2	; +0x07 -> IX
	.byte 0x01	; +0x09 digit count
	.byte 0x03	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x229E	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F05CF8	; +0x07 -> XIY: string table
	.short 0x0005	; +0x0B -> BC: bytes per entry
	.short 0x2292	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F04DC3	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x2298	; +0x0D -> IX

; --- 0xF04E32-0xF04E41: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x004E32, 0x000010

; ------------------------------------------------------------------
; 0xF04E42-0xF04E92 -- 6 display-list records, 81 bytes -- interpreter B
;   entered at: 0xF04E42
;   ends used:  0xF04E93
; ------------------------------------------------------------------
DL_F04E42:
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0xE0	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x22A7	; +0x07 -> IX
	.byte 0x01	; +0x09 digit count
	.byte 0x03	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x22A3	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F05CF8	; +0x07 -> XIY: string table
	.short 0x0005	; +0x0B -> BC: bytes per entry
	.short 0x228C	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F04DB7	; +0x07 -> XIY: string table
	.short 0x0002	; +0x0B -> BC: bytes per entry
	.short 0x2292	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F05CF8	; +0x07 -> XIY: string table
	.short 0x0005	; +0x0B -> BC: bytes per entry
	.short 0x2298	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F04DB7	; +0x07 -> XIY: string table
	.short 0x0002	; +0x0B -> BC: bytes per entry
	.short 0x229E	; +0x0D -> IX

; --- 0xF04E93-0xF04EAA: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x004E93, 0x000018

; ------------------------------------------------------------------
; 0xF04EAB-0xF04F1F -- 11 display-list records, 117 bytes -- interpreter B
;   entered at: 0xF04EAB
;   ends used:  0xF04F20
; ------------------------------------------------------------------
DL_F04EAB:
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1DE2	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27B0	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1DEC	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1DF7	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2261	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2265	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x226A	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AC	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x226F	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AD	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2274	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AE	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2279	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AF	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x227F	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x01	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F04F22	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF04F20-0xF04F31: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x004F20, 0x000012

; ------------------------------------------------------------------
; 0xF04F32-0xF04F45 -- 2 display-list records, 20 bytes -- interpreter A
;   entered at: 0xF04F32
;   ends used:  0xF04F46
; ------------------------------------------------------------------
DL_F04F32:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x003D
	.short 0x00BD
	.short 0x011C
	.short 0x00CA
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0004
	.short 0x00DA
	.short 0x011C
	.short 0x00E7

; --- 0xF04F46-0xF04F71: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x004F46, 0x00002C

; ------------------------------------------------------------------
; 0xF04F72-0xF04FFC -- 13 display-list records, 139 bytes -- interpreter B
;   entered at: 0xF04F72
;   ends used:  0xF04FFD
; ------------------------------------------------------------------
DL_F04F72:
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x0D51	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1251	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1779	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1C79	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x0D57	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AC	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1257	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AD	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x177F	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AE	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1C7F	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AF	; +0x02 source variable, 16-bit address
	.byte 0xE0	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x0D5D	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x03	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27B0	; +0x02 source variable, 16-bit address
	.byte 0xE0	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x125D	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x03	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27B1	; +0x02 source variable, 16-bit address
	.byte 0xE0	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1785	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x03	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27B2	; +0x02 source variable, 16-bit address
	.byte 0xE0	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1C85	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x03	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A3	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F0503B	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF04FFD-0xF05062: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x004FFD, 0x000066

; ------------------------------------------------------------------
; 0xF05063-0xF0509A -- 4 display-list records, 56 bytes -- interpreter B
;   entered at: 0xF05063
;   ends used:  0xF0509B
; ------------------------------------------------------------------
DL_F05063:
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2293	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x2298	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x229D	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22A2	; +0x0D -> IX

; --- 0xF0509B-0xF050AA: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x00509B, 0x000010

; ------------------------------------------------------------------
; 0xF050AB-0xF050F0 -- 7 display-list records, 70 bytes -- interpreter B
;   entered at: 0xF050AB
;   ends used:  0xF050F1
; ------------------------------------------------------------------
DL_F050AB:
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2261	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2265	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x226A	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x226F	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2274	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2279	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AC	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x227F	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663

; --- 0xF050F1-0xF0510C: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0050F1, 0x00001C

; ------------------------------------------------------------------
; 0xF0510D-0xF05181 -- 9 display-list records, 117 bytes -- interpreter B
;   entered at: 0xF0510D
;   ends used:  0xF05182
; ------------------------------------------------------------------
DL_F0510D:
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x22A6	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x22AC	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x229C	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x2297	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22A1	; +0x0D -> IX
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2289	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AC	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x228E	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AD	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2292	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x27AF	; +0x02 source variable, 16-bit address
	.byte 0x03	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F05182	; +0x07 -> XIY: string table
	.short 0x0008	; +0x0B -> BC: bytes per entry
	.short 0x009D	; +0x0D -> (0x2530)
	.short 0x003E	; +0x0F -> (0x2532)

; --- 0xF05182-0xF051C1: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x005182, 0x000040

; ------------------------------------------------------------------
; 0xF051C2-0xF05285 -- 16 display-list records, 196 bytes -- interpreter B
;   entered at: 0xF051C2
;   ends used:  0xF05286
; ------------------------------------------------------------------
DL_F051C2:
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x0D4E	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x0D52	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F052FE	; +0x07 -> XIY: string table
	.short 0x0004	; +0x0B -> BC: bytes per entry
	.short 0x0D58	; +0x0D -> IX
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x124E	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1252	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AC	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F052FE	; +0x07 -> XIY: string table
	.short 0x0004	; +0x0B -> BC: bytes per entry
	.short 0x1258	; +0x0D -> IX
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AD	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x174E	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AE	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1752	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AF	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F052FE	; +0x07 -> XIY: string table
	.short 0x0004	; +0x0B -> BC: bytes per entry
	.short 0x1758	; +0x0D -> IX
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27B0	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1C4E	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27B1	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1C52	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B2	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F052FE	; +0x07 -> XIY: string table
	.short 0x0004	; +0x0B -> BC: bytes per entry
	.short 0x1C58	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B6	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F05286	; +0x07 -> XIY: string table
	.short 0x0008	; +0x0B -> BC: bytes per entry
	.short 0x175F	; +0x0D -> IX
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27B5	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1DA2	; +0x07 -> IX
	.byte 0x01	; +0x09 digit count
	.byte 0x08	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F0531E	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27B3	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F05346	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF05286-0xF0535D: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x005286, 0x0000D8

; ------------------------------------------------------------------
; 0xF0535E-0xF05371 -- 2 display-list records, 20 bytes -- interpreter A
;   entered at: 0xF0535E, 0xF05368
;   ends used:  0xF05368, 0xF05372
; ------------------------------------------------------------------
DL_F0535E:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x000D
	.short 0x004C
	.short 0x00A6
	.short 0x00C8
DL_F05368:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x00B5
	.short 0x0043
	.short 0x00F9
	.short 0x00C8

; --- 0xF05372-0xF053B5: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x005372, 0x000044

; ------------------------------------------------------------------
; 0xF053B6-0xF05406 -- 7 display-list records, 81 bytes -- interpreter B
;   entered at: 0xF053B6, 0xF053E3
;   ends used:  0xF053CF, 0xF053FC, 0xF05407
; ------------------------------------------------------------------
DL_F053B6:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0xC0	; +0x04 AND mask
	.byte 0x06	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F05469	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x2294	; +0x0D -> IX
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0x1F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2298	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x229D	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x22A1	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
DL_F053E3:
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x22A6	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x80	; +0x04 AND mask
	.byte 0x07	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F034D2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22AB	; +0x0D -> IX
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F05475	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF05407-0xF0549C: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x005407, 0x000096

; ------------------------------------------------------------------
; 0xF0549D-0xF054B0 -- 2 display-list records, 20 bytes -- interpreter A
;   entered at: 0xF0549D, 0xF054A7
;   ends used:  0xF054A7, 0xF054B1
; ------------------------------------------------------------------
DL_F0549D:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x00B6
	.short 0x003E
	.short 0x00DA
	.short 0x00A9
DL_F054A7:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x003E
	.short 0x004A
	.short 0x00A9

; --- 0xF054B1-0xF054EC: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0054B1, 0x00003C

; ------------------------------------------------------------------
; 0xF054ED-0xF0550A -- 3 display-list records, 30 bytes -- interpreter A
;   entered at: 0xF054ED, 0xF054F7, 0xF05501
;   ends used:  0xF054F7, 0xF05501, 0xF0550B
; ------------------------------------------------------------------
DL_F054ED:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x00DD
	.short 0x0044
	.short 0x00ED
	.short 0x00CB
DL_F054F7:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x0043
	.short 0x00B3
	.short 0x00A6
DL_F05501:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x004D
	.short 0x0041
	.short 0x0058
	.short 0x00A7

; --- 0xF0550B-0xF0564A: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x00550B, 0x000140

; ------------------------------------------------------------------
; 0xF0564B-0xF0574C -- 28 display-list records, 258 bytes -- interpreter A
;   entered at: 0xF0564B
;   ends used:  0xF05740, 0xF0574D
; ------------------------------------------------------------------
DL_F0564B:
	.byte 0x1C, 0x12	; op 1C, 18 bytes -> handler 0xF31A52
	.short 0x0063
	.short 0x0005
	.ascii "MEM0RY WRITE"
	.byte 0x17, 0x10	; op 17, 16 bytes -> handler 0xF31A52
	.short 0x0006
	.short 0x0007
	.ascii "SOUND EDIT"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0550
	.byte 0x10	; character codes below 0x20
	.byte 0x20, 0x06	; op 20, 6 bytes -> handler 0xF31A3A
	.short 0x057A
	.ascii "0K"
	.byte 0x07, 0x09	; op 07, 9 bytes -> handler 0xF31A3A
	.short 0x0B6F
	.ascii "NAME:"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0136
	.short 0x006D
	.byte 0x91	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x117C
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11CF
	.byte 0xA9	; character codes below 0x20
	.byte 0x07, 0x10	; op 07, 16 bytes -> handler 0xF31A3A
	.short 0x1367
	.ascii "MEMORY BANK:"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0136
	.short 0x0094
	.byte 0x91	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17BC
	.byte 0x8E	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17E7
	.byte 0xA9	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1DD7
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x10	; op 07, 16 bytes -> handler 0xF31A3A
	.short 0x1DF0
	.ascii "SOUND NAMING"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0004
	.short 0x0004
	.short 0x0044
	.short 0x0010
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x001E
	.short 0x0025
	.short 0x0031
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000D
	.short 0x0020
	.short 0x0023
	.short 0x002F
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0029
	.short 0x003C
	.short 0x00EE
	.short 0x00AC
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0112
	.short 0x006C
	.short 0x0135
	.short 0x007F
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x006E
	.short 0x0133
	.short 0x007D
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0112
	.short 0x0093
	.short 0x0135
	.short 0x00A6
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x0095
	.short 0x0133
	.short 0x00A4
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00B1
	.short 0x00B3
	.short 0x0130
	.short 0x00D6
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00F7
	.short 0x0089
	.short 0x010A
	.short 0x008A
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x010A
	.short 0x0075
	.short 0x010B
	.short 0x009E
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0029
	.short 0x0072
	.short 0x00EE
	.short 0x0072
	.byte 0x07, 0x08	; op 07, 8 bytes -> handler 0xF31A3A
	.short 0x1373
	.ascii "USER"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1378
	.ascii "-"

; --- 0xF0574D-0xF057BF: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x00574D, 0x000073

; ------------------------------------------------------------------
; 0xF057C0-0xF05800 -- 5 display-list records, 65 bytes -- interpreter B
;   entered at: 0xF057C0, 0xF057E3
;   ends used:  0xF057E3, 0xF05801
; ------------------------------------------------------------------
DL_F057C0:
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x03	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1377	; +0x07 -> IX
	.byte 0x01	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1379	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x000022F0	; +0x07 -> XIY: string table
	.short 0x0010	; +0x0B -> BC: bytes per entry
	.short 0x0E69	; +0x0D -> IX
DL_F057E3:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F05801	; +0x07 -> XIY: string table
	.short 0x0009	; +0x0B -> BC: bytes per entry
	.short 0x1373	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x000022F0	; +0x07 -> XIY: string table
	.short 0x0010	; +0x0B -> BC: bytes per entry
	.short 0x0E69	; +0x0D -> IX

; --- 0xF05801-0xF0582D: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x005801, 0x00002D

; ------------------------------------------------------------------
; 0xF0582E-0xF05AB3 -- 51 display-list records, 646 bytes -- interpreter A (45 records) and B (6)
;   entered at: 0xF0582E, 0xF05850, 0xF0587C, 0xF05A2E, 0xF05A38, 0xF05A42, 0xF05A4C, 0xF05A68, 0xF05A84, 0xF05AA0, 0xF05AAA
;   ends used:  0xF05850, 0xF05A2E, 0xF05A38, 0xF05A42, 0xF05A4C, 0xF05A68, 0xF05A84, 0xF05AA0, 0xF05AB4
; ------------------------------------------------------------------
DL_F0582E:
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0550
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x057A
	.ascii "WRITE"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x001E
	.short 0x003C
	.short 0x0031
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000E
	.short 0x0020
	.short 0x003A
	.short 0x002F
DL_F05850:
	.byte 0x17, 0x10	; op 17, 16 bytes -> handler 0xF31A52
	.short 0x0006
	.short 0x0007
	.ascii "SOUND EDIT"
	.byte 0x1C, 0x12	; op 1C, 18 bytes -> handler 0xF31A52
	.short 0x0066
	.short 0x0005
	.ascii "S0UND NAMING"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0004
	.short 0x0004
	.short 0x0044
	.short 0x0010
DL_F0587C:
	.byte 0x06, 0x21	; op 06, 33 bytes -> handler 0xF31A3A
	.short 0x1046
	.ascii "A B C D E F G H I J K L M N O"
	.byte 0x06, 0x23	; op 06, 35 bytes -> handler 0xF31A3A
	.short 0x129C
	.ascii "P Q R S T U V W X Y Z a b c d e"
	.byte 0x06, 0x23	; op 06, 35 bytes -> handler 0xF31A3A
	.short 0x14F4
	.ascii "f g h i j k l m n o p q r s t u"
	.byte 0x06, 0x23	; op 06, 35 bytes -> handler 0xF31A3A
	.short 0x174C
	.ascii "v w x y z 0 1 2 3 4 5 6 7 8 9 !"
	.byte 0x06, 0x23	; op 06, 35 bytes -> handler 0xF31A3A
	.short 0x19A4
	.ascii "\" # $ % & ' ( ) + - * / = , . @"
	.byte 0x06, 0x23	; op 06, 35 bytes -> handler 0xF31A3A
	.short 0x1BFC
	.ascii ": ; ? \\ ^ _ ` | ~ "
	.byte 0x7F	; character codes below 0x20
	.ascii " < > [ ] { }"
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x059B
	.ascii "CLR"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x059F
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8B
	.ascii "~"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8D
	.byte 0x7F	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8F
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x1E98
	.ascii ".."
	.byte 0x06, 0x0C	; op 06, 12 bytes -> handler 0xF31A3A
	.short 0x1EC9
	.ascii "P0SITI0N"
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x1EE5
	.ascii "ABC"
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x1EEA
	.ascii "]{}"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x20F0
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x0A	; op 06, 10 bytes -> handler 0xF31A3A
	.short 0x2212
	.ascii "<    >"
	.byte 0x06, 0x11	; op 06, 17 bytes -> handler 0xF31A3A
	.short 0x221B
	.ascii "INS  DEL  A/a"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x222B
	.ascii "<"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2235
	.ascii ">"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x22D0
	.byte 0x8E	; character codes below 0x20
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0115
	.short 0x001C
	.short 0x0132
	.short 0x0034
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0115
	.short 0x0042
	.short 0x0132
	.short 0x005A
	.byte 0x13, 0x0A	; op 13, 10 bytes -> handler 0xF31A75
	.short 0x000F
	.short 0x0062
	.short 0x012C
	.short 0x00C2
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00D2
	.short 0x0022
	.short 0x00EA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00D2
	.short 0x004A
	.short 0x00EA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00D2
	.short 0x0072
	.short 0x00EA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00D2
	.short 0x009A
	.short 0x00EA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00D2
	.short 0x00C2
	.short 0x00EA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00D2
	.short 0x00EA
	.short 0x00EA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00D2
	.short 0x0112
	.short 0x00EA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00D2
	.short 0x013A
	.short 0x00EA
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00DE
	.short 0x0112
	.short 0x00DE
DL_F05A2E:
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x004D
	.short 0x003B
	.short 0x0105
	.short 0x0051
DL_F05A38:
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x004D
	.short 0x003B
	.short 0x00E5
	.short 0x0051
DL_F05A42:
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x004D
	.short 0x003B
	.short 0x006C
	.short 0x0051
DL_F05A4C:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1C	; +0x06 swi 7 function
	.long 0x000022F0	; +0x07 -> XIY: string table
	.short 0x0010	; +0x0B -> BC: bytes per entry
	.short 0x0051	; +0x0D -> (0x2530)
	.short 0x003F	; +0x0F -> (0x2532)
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F05AB4	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
DL_F05A68:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1C	; +0x06 swi 7 function
	.long 0x000022F0	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x0051	; +0x0D -> (0x2530)
	.short 0x003F	; +0x0F -> (0x2532)
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F05AB4	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
DL_F05A84:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1C	; +0x06 swi 7 function
	.long 0x000022F0	; +0x07 -> XIY: string table
	.short 0x0002	; +0x0B -> BC: bytes per entry
	.short 0x0051	; +0x0D -> (0x2530)
	.short 0x003F	; +0x0F -> (0x2532)
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F05AB4	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
DL_F05AA0:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0051
	.short 0x003E
	.short 0x0101
	.short 0x004F
DL_F05AAA:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0020
	.short 0x0067
	.short 0x0118
	.short 0x00C0

; --- 0xF05AB4-0xF05F77: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x005AB4, 0x0004C4

; ------------------------------------------------------------------
; 0xF05F78-0xF06561 -- 156 display-list records, 1514 bytes -- interpreter A (147 records) and B (9)
;   entered at: 0xF05F78, 0xF06048, 0xF060DA, 0xF060E4, 0xF06154, 0xF06224, 0xF06481, 0xF06495, 0xF064A9, 0xF064C6, 0xF064E5, 0xF064F9, 0xF06517, 0xF06544
;   ends used:  0xF06048, 0xF060DA, 0xF060E4, 0xF06154, 0xF06224, 0xF06481, 0xF06495, 0xF064A9, 0xF064C6, 0xF064E5, 0xF06517, 0xF06535, 0xF06562
; ------------------------------------------------------------------
DL_F05F78:
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x0039
	.short 0x003E
	.ascii "TRIGGER"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0086
	.short 0x003E
	.ascii "DELAY"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x0C30
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x11F8
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1770
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1D38
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x0027
	.short 0x00D1
	.ascii "TRIGGER"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x007C
	.short 0x00D1
	.ascii "DELAY"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21EF
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F9
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x237F
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2389
	.byte 0x8E	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0038
	.short 0x00AE
	.short 0x00CA
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00DA
	.short 0x0046
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00DA
	.short 0x0096
	.short 0x00EE
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x004A
	.short 0x00AE
	.short 0x004A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x006A
	.short 0x00AE
	.short 0x006A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x008A
	.short 0x00AE
	.short 0x008A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x00AA
	.short 0x00AE
	.short 0x00AA
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00E4
	.short 0x0046
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00E4
	.short 0x0096
	.short 0x00E4
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x002C
	.short 0x0038
	.short 0x002C
	.short 0x00CA
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x007C
	.short 0x0038
	.short 0x007C
	.short 0x00CA
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0106
	.short 0x001C
	.short 0x0132
	.short 0x0036
DL_F06048:
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x0045
	.short 0x003E
	.ascii "PANNING"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x0C30
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x11F8
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1770
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1D38
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x0046
	.short 0x00D1
	.ascii "PANNING"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F3
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2383
	.byte 0x8E	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0038
	.short 0x0086
	.short 0x00CA
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0051
	.short 0x00DA
	.short 0x0066
	.short 0x00EE
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x004A
	.short 0x0086
	.short 0x004A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x006A
	.short 0x0086
	.short 0x006A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x008A
	.short 0x0086
	.short 0x008A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x00AA
	.short 0x0086
	.short 0x00AA
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0051
	.short 0x00E4
	.short 0x0066
	.short 0x00E4
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x002C
	.short 0x0038
	.short 0x002C
	.short 0x00CA
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0106
	.short 0x0091
	.short 0x0132
	.short 0x00AB
DL_F060DA:
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0045
	.short 0x00CC
	.short 0x00FB
	.short 0x00E9
DL_F060E4:
	.byte 0x06, 0x0D	; op 06, 13 bytes -> handler 0xF31A3A
	.short 0x04BD
	.ascii "KEY LAYER"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0039
	.short 0x002A
	.ascii "0"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0054
	.short 0x002A
	.ascii "1"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0071
	.short 0x002A
	.ascii "2"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x008D
	.short 0x002A
	.ascii "3"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00A9
	.short 0x002A
	.ascii "4"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00C5
	.short 0x002A
	.ascii "5"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00E1
	.short 0x002A
	.ascii "6"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0027
	.short 0x0062
	.short 0x00F6
	.short 0x0063
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0027
	.short 0x0081
	.short 0x00F6
	.short 0x0082
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0027
	.short 0x00A0
	.short 0x00F6
	.short 0x00A1
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0027
	.short 0x00BF
	.short 0x00F6
	.short 0x00C0
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0106
	.short 0x0044
	.short 0x0132
	.short 0x005E
DL_F06154:
	.byte 0x06, 0x12	; op 06, 18 bytes -> handler 0xF31A3A
	.short 0x055B
	.ascii "VELOCITY LAYER"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x002D
	.short 0x0032
	.ascii "0"
	.byte 0x17, 0x08	; op 17, 8 bytes -> handler 0xF31A52
	.short 0x005B
	.short 0x0032
	.ascii "32"
	.byte 0x17, 0x08	; op 17, 8 bytes -> handler 0xF31A52
	.short 0x008A
	.short 0x0032
	.ascii "64"
	.byte 0x17, 0x08	; op 17, 8 bytes -> handler 0xF31A52
	.short 0x00BA
	.short 0x0032
	.ascii "96"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00E4
	.short 0x0033
	.ascii "127"
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0030
	.short 0x003D
	.short 0x00F0
	.short 0x003D
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0030
	.short 0x0062
	.short 0x00F0
	.short 0x0063
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0030
	.short 0x0081
	.short 0x00F0
	.short 0x0082
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0030
	.short 0x00A0
	.short 0x00F0
	.short 0x00A1
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0030
	.short 0x00BF
	.short 0x00F0
	.short 0x00C0
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0030
	.short 0x003C
	.short 0x0030
	.short 0x003E
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0048
	.short 0x003C
	.short 0x0048
	.short 0x003E
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0060
	.short 0x003C
	.short 0x0060
	.short 0x003E
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0078
	.short 0x003C
	.short 0x0078
	.short 0x003E
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0090
	.short 0x003C
	.short 0x0090
	.short 0x003E
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A8
	.short 0x003C
	.short 0x00A8
	.short 0x003E
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00C0
	.short 0x003C
	.short 0x00C0
	.short 0x003E
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00D8
	.short 0x003C
	.short 0x00D8
	.short 0x003E
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00F0
	.short 0x003C
	.short 0x00F0
	.short 0x003E
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0106
	.short 0x006A
	.short 0x0132
	.short 0x0084
DL_F06224:
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x006B
	.short 0x0025
	.ascii "EFFECT"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0095
	.short 0x0025
	.ascii "BLOCK"
	.byte 0x20, 0x08	; op 20, 8 bytes -> handler 0xF31A3A
	.short 0x0A5E
	.ascii "EFF1"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00B5
	.short 0x0044
	.byte 0x11	; character codes below 0x20
	.byte 0x20, 0x08	; op 20, 8 bytes -> handler 0xF31A3A
	.short 0x0E46
	.ascii "EFF2"
	.byte 0x20, 0x07	; op 20, 7 bytes -> handler 0xF31A3A
	.short 0x122F
	.ascii "REV"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00B5
	.short 0x0076
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00B7
	.short 0x008F
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00BE
	.short 0x0076
	.ascii "MAIN"
	.byte 0x17, 0x15	; op 17, 21 bytes -> handler 0xF31A52
	.short 0x004B
	.short 0x0097
	.ascii "DIRECT MAIN OUT"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00B7
	.short 0x00A6
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x14	; op 17, 20 bytes -> handler 0xF31A52
	.short 0x004B
	.short 0x00AE
	.ascii "DIRECT SUB OUT"
	.byte 0x20, 0x0F	; op 20, 15 bytes -> handler 0xF31A3A
	.short 0x1E06
	.ascii "EFFECT SEND"
	.byte 0x20, 0x0E	; op 20, 14 bytes -> handler 0xF31A3A
	.short 0x1E14
	.ascii "DIRECT OUT"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x002B
	.short 0x00D1
	.ascii "EFF1"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0055
	.short 0x00D1
	.ascii "EFF2"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x007F
	.short 0x00D1
	.ascii "REV"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00A7
	.short 0x00D1
	.ascii "MAIN"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00D6
	.short 0x00D1
	.ascii "SUB"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2447
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x244C
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2451
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2456
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x245C
	.byte 0x12	; character codes below 0x20
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F05CE0
	.short 0x0A59
	.short 0x0002
	.short 0x000C
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0047
	.short 0x0048
	.short 0x0048
	.short 0x0049
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F05CE0
	.short 0x1229
	.short 0x0002
	.short 0x000C
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0047
	.short 0x007A
	.short 0x0048
	.short 0x007B
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0048
	.short 0x005F
	.short 0x004A
	.short 0x0061
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0052
	.short 0x005F
	.short 0x0054
	.short 0x0061
	.byte 0x07, 0x18	; op 07, 24 bytes -> handler 0xF31A3A
	.short 0x00D6
	.ascii "EFFECT SEND & OUTPUT"
	.byte 0x17, 0x10	; op 17, 16 bytes -> handler 0xF31A52
	.short 0x0006
	.short 0x0007
	.ascii "SOUND EDIT"
	.byte 0x20, 0x0B	; op 20, 11 bytes -> handler 0xF31A3A
	.short 0x1E20
	.ascii "PANNING"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0102
	.short 0x00D0
	.ascii "1st"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0120
	.short 0x00D0
	.ascii "2nd"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2461
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2466
	.byte 0x12	; character codes below 0x20
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x70
	.short 0x000A
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x005E
	.short 0x0030
	.short 0x00E3
	.short 0x0088
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x006D
	.short 0x003E
	.short 0x0094
	.short 0x004F
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x006D
	.short 0x0057
	.short 0x0094
	.short 0x0068
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0073
	.short 0x0070
	.short 0x0094
	.short 0x0081
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0024
	.short 0x00CD
	.short 0x00F5
	.short 0x00E9
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0004
	.short 0x0004
	.short 0x0044
	.short 0x0010
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00F9
	.short 0x00CD
	.short 0x013E
	.short 0x00E9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0033
	.short 0x0047
	.short 0x0047
	.short 0x0047
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0054
	.short 0x0047
	.short 0x006D
	.short 0x0047
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0094
	.short 0x0047
	.short 0x00B5
	.short 0x0047
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0033
	.short 0x0060
	.short 0x0047
	.short 0x0060
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x0060
	.short 0x006D
	.short 0x0060
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0033
	.short 0x0079
	.short 0x0047
	.short 0x0079
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0054
	.short 0x0079
	.short 0x0073
	.short 0x0079
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0094
	.short 0x0079
	.short 0x00B5
	.short 0x0079
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0033
	.short 0x0092
	.short 0x00B7
	.short 0x0092
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0020
	.short 0x00A9
	.short 0x00B7
	.short 0x00A9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0024
	.short 0x00DA
	.short 0x00F5
	.short 0x00DA
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0033
	.short 0x0047
	.short 0x0033
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0099
	.short 0x00CD
	.short 0x0099
	.short 0x00E9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F9
	.short 0x00DA
	.short 0x013E
	.short 0x00DA
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x00FA
	.short 0x00DB
	.short 0x013D
	.short 0x00E8
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0025
	.short 0x00DB
	.short 0x00F4
	.short 0x00E8
DL_F06481:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x004B
	.short 0x005B
	.short 0x0054
	.short 0x005E
	.byte 0x00, 0x0A	; op 00, 10 bytes -> handler 0xF31A75
	.short 0x004B
	.short 0x005E
	.short 0x0054
	.short 0x005B
DL_F06495:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x004B
	.short 0x005B
	.short 0x0054
	.short 0x005E
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x004B
	.short 0x005E
	.short 0x0054
	.short 0x005E
DL_F064A9:
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x009D
	.short 0x0036
	.ascii "SERIAL"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x007D
	.short 0x004E
	.byte 0x8D	; character codes below 0x20
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0080
	.short 0x0052
	.short 0x0080
	.short 0x0056
DL_F064C6:
	.byte 0x17, 0x0E	; op 17, 14 bytes -> handler 0xF31A52
	.short 0x009B
	.short 0x0036
	.ascii "PARALLEL"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00B5
	.short 0x005D
	.byte 0x11	; character codes below 0x20
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0095
	.short 0x0060
	.short 0x00B5
	.short 0x0060
DL_F064E5:
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x228D	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2297	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
DL_F064F9:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F06598	; +0x07 -> XIY: string table
	.short 0x0004	; +0x0B -> BC: bytes per entry
	.short 0x1648	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F034D8	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x229D	; +0x0D -> IX
DL_F06517:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F06598	; +0x07 -> XIY: string table
	.short 0x0004	; +0x0B -> BC: bytes per entry
	.short 0x19B8	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F06598	; +0x07 -> XIY: string table
	.short 0x0004	; +0x0B -> BC: bytes per entry
	.short 0x22A2	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F034D8	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x2292	; +0x0D -> IX
DL_F06544:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B0	; +0x02 source variable, 16-bit address
	.byte 0x03	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F32A4E	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22A8	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B0	; +0x02 source variable, 16-bit address
	.byte 0x0C	; +0x04 AND mask
	.byte 0x02	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F32A4E	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22AC	; +0x0D -> IX

; --- 0xF06562-0xF06575: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x006562, 0x000014

; ------------------------------------------------------------------
; 0xF06576-0xF06597 -- 2 display-list records, 34 bytes -- interpreter B
;   entered at: 0xF06576
;   ends used:  0xF06587, 0xF06598
; ------------------------------------------------------------------
DL_F06576:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x27AC	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F06598	; +0x07 -> XIY: string table
	.short 0x0004	; +0x0B -> BC: bytes per entry
	.short 0x00BE	; +0x0D -> (0x2530)
	.short 0x0044	; +0x0F -> (0x2532)
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x27AC	; +0x02 source variable, 16-bit address
	.byte 0xF0	; +0x04 AND mask
	.byte 0x04	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F06598	; +0x07 -> XIY: string table
	.short 0x0004	; +0x0B -> BC: bytes per entry
	.short 0x00BE	; +0x0D -> (0x2530)
	.short 0x005D	; +0x0F -> (0x2532)

; --- 0xF06598-0xF065DF: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x006598, 0x000048

; ------------------------------------------------------------------
; 0xF065E0-0xF067A5 -- 50 display-list records, 454 bytes -- interpreter A
;   entered at: 0xF065E0, 0xF06601
;   ends used:  0xF06601, 0xF067A6
; ------------------------------------------------------------------
DL_F065E0:
	.byte 0x17, 0x17	; op 17, 23 bytes -> handler 0xF31A52
	.short 0x006A
	.short 0x00C3
	.ascii "FILTER KEY FOLLOW"
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x010E
	.short 0x0043
	.short 0x0132
	.short 0x005C
DL_F06601:
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x0A17
	.ascii "LF01"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x0BB8
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x0F17
	.ascii "LF02"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x11A8
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x13C7
	.ascii "LF03"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x17C0
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x18C7
	.ascii "LF04"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1DB0
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x2084
	.ascii "LF0"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0060
	.short 0x00D0
	.ascii "WAVE"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x007E
	.short 0x00D0
	.ascii "DELAY"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00A2
	.short 0x00D0
	.ascii "SPEED"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00C6
	.short 0x00D0
	.ascii "DEPTH"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00EA
	.short 0x00D0
	.ascii "TOUCH"
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x010E
	.short 0x00D0
	.ascii "KEYSYNC"
	.byte 0x06, 0x0A	; op 06, 10 bytes -> handler 0xF31A3A
	.short 0x2264
	.ascii "SELECT"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2447
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x244C
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2451
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2456
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x245B
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2460
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2465
	.byte 0x12	; character codes below 0x20
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x002C
	.short 0x003C
	.short 0x004C
	.short 0x004D
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00B4
	.short 0x003C
	.short 0x00DC
	.short 0x004D
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x002C
	.short 0x005B
	.short 0x004C
	.short 0x006C
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00B4
	.short 0x005C
	.short 0x00DC
	.short 0x006D
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x002C
	.short 0x007A
	.short 0x004C
	.short 0x008B
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00B4
	.short 0x007A
	.short 0x00DC
	.short 0x008B
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x002C
	.short 0x009A
	.short 0x004C
	.short 0x00AB
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00B4
	.short 0x009A
	.short 0x00DC
	.short 0x00AB
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00CC
	.short 0x013D
	.short 0x00E9
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x001D
	.short 0x00CD
	.short 0x0052
	.short 0x00E8
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0018
	.short 0x0044
	.short 0x002C
	.short 0x0044
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0008
	.short 0x004F
	.short 0x0018
	.short 0x004F
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0018
	.short 0x0064
	.short 0x002C
	.short 0x0064
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0008
	.short 0x0075
	.short 0x0018
	.short 0x0075
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0018
	.short 0x0082
	.short 0x002C
	.short 0x0082
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0008
	.short 0x009C
	.short 0x0018
	.short 0x009C
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x001F
	.short 0x00A2
	.short 0x002C
	.short 0x00A2
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0008
	.short 0x00C2
	.short 0x001F
	.short 0x00C2
	.byte 0x12, 0x0A	; op 12, 10 bytes -> handler 0xF31A75
	.short 0x0018
	.short 0x0044
	.short 0x0018
	.short 0x004F
	.byte 0x12, 0x0A	; op 12, 10 bytes -> handler 0xF31A75
	.short 0x0018
	.short 0x0064
	.short 0x0018
	.short 0x0075
	.byte 0x12, 0x0A	; op 12, 10 bytes -> handler 0xF31A75
	.short 0x0018
	.short 0x0082
	.short 0x0018
	.short 0x009C
	.byte 0x12, 0x0A	; op 12, 10 bytes -> handler 0xF31A75
	.short 0x001F
	.short 0x00A2
	.short 0x001F
	.short 0x00C2
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00DB
	.short 0x013D
	.short 0x00DB
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x006B
	.short 0x0132
	.short 0x0078
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x005A
	.short 0x00DC
	.short 0x013C
	.short 0x00E8

; --- 0xF067A6-0xF0D79B: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0067A6, 0x006FF6

; ------------------------------------------------------------------
; 0xF0D79C-0xF0D7E1 -- 5 display-list records, 70 bytes -- interpreter A
;   entered at: 0xF0D79C, 0xF0D7A7
;   ends used:  0xF0D7D5, 0xF0D7E2
; ------------------------------------------------------------------
DL_F0D79C:
	.byte 0x08, 0x0B	; op 08, 11 bytes -> handler 0xF31A3A
	.short 0x0585
	.ascii "SENDING"
DL_F0D7A7:
	.byte 0x08, 0x14	; op 08, 20 bytes -> handler 0xF31A3A
	.short 0x0194
	.ascii "SYSTEM EXCLUSIVE"
	.byte 0x08, 0x10	; op 08, 16 bytes -> handler 0xF31A3A
	.short 0x0968
	.ascii "PLEASE WAIT!"
	.byte 0x13, 0x0A	; op 13, 10 bytes -> handler 0xF31A75
	.short 0x002C
	.short 0x007F
	.short 0x0111
	.short 0x00E4
	.byte 0x08, 0x0D	; op 08, 13 bytes -> handler 0xF31A3A
	.short 0x0583
	.ascii "RECEIVING"

; --- 0xF0D7E2-0xF0D99B: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x00D7E2, 0x0001BA

; ------------------------------------------------------------------
; 0xF0D99C-0xF0D9A3 -- 1 display-list records, 8 bytes -- interpreter A
;   entered at: 0xF0D99C
;   ends used:  0xF0D9A4
; ------------------------------------------------------------------
DL_F0D99C:
	.byte 0x0E, 0x08	; op 0E, 8 bytes -> handler 0xF31A9F
	.short 0x0FA4
	.short 0x0020
	.short 0x0010

; --- 0xF0D9A4-0xF0D9E1: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x00D9A4, 0x00003E

; ------------------------------------------------------------------
; 0xF0D9E2-0xF0DA92 -- 18 display-list records, 177 bytes -- interpreter A
;   entered at: 0xF0D9E2, 0xF0DA73
;   ends used:  0xF0DA73, 0xF0DA93
; ------------------------------------------------------------------
DL_F0D9E2:
	.byte 0x1C, 0x12	; op 1C, 18 bytes -> handler 0xF31A52
	.short 0x0060
	.short 0x0005
	.ascii "GENERAL MIDI"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0008
	.short 0x0008
	.ascii "MIDI"
	.byte 0x07, 0x1B	; op 07, 27 bytes -> handler 0xF31A3A
	.short 0x1183
	.ascii " GENERAL MIDI MODE  :  "
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11A7
	.byte 0x11	; character codes below 0x20
	.byte 0x20, 0x07	; op 20, 7 bytes -> handler 0xF31A3A
	.short 0x11CA
	.ascii " ON"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17BF
	.byte 0x11	; character codes below 0x20
	.byte 0x20, 0x08	; op 20, 8 bytes -> handler 0xF31A3A
	.short 0x17E2
	.ascii " OFF"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0012
	.short 0x005E
	.short 0x00F6
	.short 0x008D
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x0004
	.short 0x0022
	.short 0x0012
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0113
	.short 0x006C
	.short 0x0135
	.short 0x007F
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0115
	.short 0x006E
	.short 0x0133
	.short 0x007D
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0113
	.short 0x0093
	.short 0x0135
	.short 0x00A6
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0115
	.short 0x0095
	.short 0x0133
	.short 0x00A4
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x1E
	.short 0x0030
DL_F0DA73:
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0577
	.byte 0x11	; character codes below 0x20
	.byte 0x20, 0x07	; op 20, 7 bytes -> handler 0xF31A3A
	.short 0x059B
	.ascii " OK"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011B
	.short 0x001E
	.short 0x0135
	.short 0x0031
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x0020
	.short 0x0133
	.short 0x002F

; --- 0xF0DA93-0xF0DAA1: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x00DA93, 0x00000F

; ------------------------------------------------------------------
; 0xF0DAA2-0xF0DB17 -- 13 display-list records, 118 bytes -- interpreter A
;   entered at: 0xF0DAA2
;   ends used:  0xF0DB18
; ------------------------------------------------------------------
DL_F0DAA2:
	.byte 0x1C, 0x12	; op 1C, 18 bytes -> handler 0xF31A52
	.short 0x0060
	.short 0x0005
	.ascii "GENERAL MIDI"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0008
	.short 0x0008
	.ascii "MIDI"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x0004
	.short 0x0022
	.short 0x0012
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x1E
	.short 0x0030
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11A7
	.byte 0x11	; character codes below 0x20
	.byte 0x20, 0x08	; op 20, 8 bytes -> handler 0xF31A3A
	.short 0x11CA
	.ascii " YES"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17BF
	.byte 0x11	; character codes below 0x20
	.byte 0x20, 0x07	; op 20, 7 bytes -> handler 0xF31A3A
	.short 0x17E2
	.ascii " NO"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0113
	.short 0x006C
	.short 0x0135
	.short 0x007F
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0115
	.short 0x006E
	.short 0x0133
	.short 0x007D
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0113
	.short 0x0093
	.short 0x0135
	.short 0x00A6
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0115
	.short 0x0095
	.short 0x0133
	.short 0x00A4
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x0023
	.short 0x010E
	.short 0x00D2

; --- 0xF0DB18-0xF0E7FF: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x00DB18, 0x000CE8

; =============================================================================
; 0xF0E800-0xF0EA9E -- THE FIELD-BLINK ENGINE
; =============================================================================
;
; Five consecutive thunk slots T_F42E20/24/28/2C/30 name five consecutive
; routines starting at 0xF0E800, and the byte before 0xF0E800 is the last of a
; long run of 0x0E (`ret`) fill -- so this is one linker input file, exported in
; address order, with a hard lower boundary.  Reference upper bounds:
;   T_F42E20 x41 -> 0xF0E9CF   T_F42E24 x85 -> 0xF0E82B (the 2nd busiest
;   T_F42E28 x21 -> 0xF0E800     prom_b-targeting slot that was still .incbin)
;   T_F42E2C x1  -> 0xF0E83A   T_F42E30 x2  -> 0xF0E835
; (python3 notes/prom_b_call_graph.py -- opcode-anchored, an upper bound that
; RANKS slots; never quote one as a call count.)
;
; WHAT IT DOES, and why "blink" is a measurement and not a guess:
;   0xF0E83A is called once per rota clear of bit 7 of (0x88).  It advances a
;   counter (0x28D1), masks it with 7, and
;       at phase 0  draws the live text with argument 1
;       at phase 4  draws it again with argument 0, which substitutes the ROM
;                   constant at 0xF78020 -- eight ASCII spaces (20 20 20 20 20
;                   20 20 20 00) -- for the text pointer.
;   Draw the text, then erase it with spaces, forever, 50% duty.  That is a
;   blink, and the rate falls where a UI blink falls: 1.27 Hz, 0.39 s on and
;   0.39 s off.  Every link of that clock chain is re-read from the ROM by
;       python3 notes/prom_b_blink_rate.py
;   (28 MHz / 2048 / TREG1 28 = 488.28 Hz INTT1; (0x86) counts 0,1,2 so the rota
;   advances every 3rd tick; one of 16 rota slots clears bit 7 of (0x88); the
;   main loop's `tset 7,(0x88)` at prom_a 0xF82182 calls the tick once per
;   clear; the tick's own counter has 8 phases.)
;   ⚠ The last link assumes the main loop iterates faster than 10.17 Hz, which
;   is NOT established here -- so 1.27 Hz is an UPPER bound on the rate.
;
; HOW IT DRAWS: not by calling a text service directly.  0xF0E926 and 0xF0E978
; each COPY A DISPLAY-LIST RECORD TEMPLATE OUT OF ROM INTO A STACK FRAME, patch
; four or five of its fields with live values, and run the one record through
; interpreter B (`call 0xF3183D` = DisplayListB_RunOne_Stack, thunk T_F42E0C).
; The templates are at 0xF78000 and 0xF7800F, converted below:
;     0xF78000: 02 0F 00 00 00 00 20 C0 28 00 00 03 00 00 00
;     0xF7800F: 07 0F 00 00 00 00 20 C0 28 00 00 03 00 00 00 00 00
; Their OPCODES identify them: 0x02 and 0x07, the two interpreter-B opcodes
; whose handlers -- DLB_Handler_StringTable (0xF31B21) and
; DLB_Handler_StringTable2 (0xF31B39), both converted above -- imply record
; lengths of 15 and 17, exactly the two `ldir` counts (0x0F, 0x11).  ⚠ The second record's own length
; BYTE says 15, not 17 -- see DLB_RecordTemplate_Op07's header for why that is
; inert rather than a defect.  The record layout is the one already documented
; on the static op-02 records above:
;     +0 opcode  +1 length  +2..3 source variable  +4 AND mask  +5 shift
;     +6 swi 7 function  +7..A -> XIY string table  +B..C bytes per entry
;     +D..E -> IX   (op 07 only: +F..10, a second word)
; The template leaves +2/+4/+5 zero, so the extracted index is always 0 and the
; record renders entry 0 of whatever +7 points at.  In other words +7 is a
; pointer to the text, and 0xF78020 is the eight-space blank that erases it.
;
; THE CONTROL BLOCK, 0x28C8-0x28D3 in CS1 static RAM.  Every field below is
; named by the ROM instruction that reads or writes it, nothing else:
;   (0x28C8) -> (0x2540) for the duration of the draw.  (0x2540) is the LCD
;              layer selector -- LCD_LayerBasePtr_Table in prom_a indexes 0..2
;              by it -- so this is which layer the field is drawn into.
;   (0x28C9) -> the record's +6, the swi 7 function.  0x17 and 0x1C are the two
;              values that select the 17-byte op-07 template; everything else
;              gets the 15-byte op-02 one.
;   (0x28CA) -> op-02's +0x0D word.
;   (0x28CC) -> op-07's +0x0D word;  (0x28CE) -> op-07's +0x0F word.
;   (0x28D0) -> +0x0B, bytes per entry (loaded as a word then `extz`'d, so only
;              the byte at 0x28D0 reaches the record).
;   (0x28D1)   the 8-phase blink counter.
;   (0x28D2)   blink state: 0 = stopped, 2 = blinking (the only value 0xF0E83A
;              proceeds on), 1 = a third state the command arms set.  What 1
;              means is NOT established.
;   (0x28D3)   0 => draw inline, non-0 => post the draw to the ring buffer.
;              Written by 0xF0E9CF from a stack-address comparison; see there.
;   (0x28C0)   the template's default +7 pointer, i.e. where the text lives.
;              Nothing in THIS module writes it.
;
; ⚠ NOT ESTABLISHED: which on-screen field this is (a cursor? a value being
; edited?); what (0x2823) and (0x2820) hold, though the constants they are
; compared with -- 0x20 and 0x2D -- are ASCII space and '-'; what state 1 means;
; and what bit 1 of (0x2075) is called in the rest of the firmware.
; =============================================================================

; ---------------------------------------------------------------------
; Blink_SetEnable -- turn field-blinking on or off, and reset it on a change
; Called from: thunk T_F42E28 (x21, an upper bound)
; Inputs:  (XIZ+8) = a boolean; non-zero enables
; Outputs: bit 1 of (0x2075) := the boolean.  If and only if the bit CHANGED,
;          calls Blink_Stop, which zeroes (0x28D2).
; Evidence: the two arms are the two transitions -- `and (XIX),0xfd` when the
;          bit was set and the argument is 0, `or (XIX),0x02` when the bit was
;          clear and the argument is not; both then fall into `calr 0xF0E82B`,
;          and both "no change" paths jump past it.  Blink_Tick reads the same
;          bit (`ld C,(0x2075) / and C,0x02 / jrl Z,<exit>`), which is what
;          makes bit 1 the blink enable rather than an unrelated flag.
;          (0x2075) is a shared flag byte: bit 3 is set by Dispatch_Code80 at
;          0xF5B9EB, converted below.
; Unknown:  what bit 1 is called elsewhere; the other six bits.
; ---------------------------------------------------------------------
Blink_SetEnable:
	.byte 0xEE, 0x0C, 0x00, 0x00	; F0E800  link XIZ,0x0000   [llvm-mc cannot encode this]
	push	xix	; F0E804  push XIX
	lda_d16	xix, (8309)	; F0E805  lda XIX,0x2075
	ld	c, (xix)	; F0E809  ld C,(XIX)
	and	c, 2	; F0E80B  and C,0x02
	jr	z, 11	; F0E80E  jr Z,0xf0e81b
	.byte 0x8E, 0x08, 0x3F, 0x00	; F0E810  cp (XIZ+0x08),0x00   [llvm-mc cannot encode this]
	jr	nz, 17	; F0E814  jr NZ,0xf0e827
	.byte 0x84, 0x3C, 0xFD	; F0E816  and (XIX),0xfd   [llvm-mc cannot encode this]
	jr	9	; F0E819  jr T,0xf0e824
	.byte 0x8E, 0x08, 0x3F, 0x00	; F0E81B  cp (XIZ+0x08),0x00   [llvm-mc cannot encode this]
	jr	z, 6	; F0E81F  jr Z,0xf0e827
	.byte 0x84, 0x3E, 0x02	; F0E821  or (XIX),0x02   [llvm-mc cannot encode this]
	calr	4	; F0E824  calr 0xf0e82b
	pop	xix	; F0E827  pop XIX
	.byte 0xEE, 0x0D	; F0E828  unlk XIZ   [llvm-mc cannot encode this]
	ret	; F0E82A  ret

; ---------------------------------------------------------------------
; Blink_Stop -- stop the blink
; Called from: thunk T_F42E24 (x85 -- the busiest prom_b-targeting slot that was
;          still unconverted), and from Blink_SetEnable at 0xF0E824
; Inputs:  none
; Outputs: (0x28D2) := 0, which is the value Blink_Tick refuses to run on;
;          plus whatever 0xF8BC78 does
; Evidence: two instructions and a `ret`.  The name is from its one side effect
;          and from Blink_Tick's gate on the same byte.
; Unknown:  what prom_a 0xF8BC78 (reached through thunk T_F432F8) does; it is
;          not converted in this tree.  Because it runs FIRST, "stop" describes
;          this routine's own effect only.
; ---------------------------------------------------------------------
Blink_Stop:
	call	16003832	; F0E82B  call 0xf432f8
	stdi8	(10450), 0	; F0E82F  ld (0x28d2),0x00
	ret	; F0E834  ret

; ---------------------------------------------------------------------
; Blink_GetState -- read the blink state byte
; Called from: thunk T_F42E30 (x2): prom_a 0xFA0D22 and prom_a 0xFBD003
; Inputs:  none
; Outputs: A = (0x28D2)
; Evidence: `ld A,(0x28d2) / ret`, five bytes.
; ---------------------------------------------------------------------
Blink_GetState:
	ldb_d8	a, (10450)	; F0E835  ld A,(0x28d2)
	ret	; F0E839  ret

; ---------------------------------------------------------------------
; Blink_Tick -- one blink phase; draws at phase 0 and blanks at phase 4
; Called from: thunk T_F42E2C (x1): prom_a 0xF8218B, inside the main loop's
;          `tset 7,(0x88) / jr NZ` arm, so it runs once per rota clear of that
;          bit -- 10.17 times a second (notes/prom_b_blink_rate.py)
; Inputs:  (0x2075) bit 1, (0x28D2), (0x28D3), (0x28C9), (0x28D1)
; Outputs: (0x28D1)++ always; on phases 0 and 4, one display-list record is run
;          (or posted to the ring buffer)
; Evidence: `inc 1,(0x28d1)` then two arms, `and C,0x07 / jr NZ` (phase 0) and
;          `and C,0x07 / cp C,4 / jr NZ` (phase 4), pushing 1 and 0
;          respectively.  Argument 1 keeps the record's +7 text pointer;
;          argument 0 replaces it with 0xF78020, eight spaces.  Draw / erase /
;          draw / erase.
; Notes:   the gate is `ld BC,(0x28d2) / extz BC / cp BC,0 / cp BC,1 / cp BC,2`.
;          The load IS 16-bit -- prefix 0xD1 selects mnemonic_d0, whose opcodes
;          0x20-0x27 are `M_LD, O_C16, O_M`
;          (mame/src/devices/cpu/tlcs900/dasm900.cpp:846) -- but `extz BC`
;          immediately zeroes the high byte
;          (`*m_p1_reg16 &= 0x00ff`, mame/.../900tbl.hxx:2135), so only the byte
;          at 0x28D2 is tested and (0x28D3) does NOT contaminate it.  Only the
;          value 2 continues.
;          Which template is used is chosen by (0x28C9): 0x17 or 0x1C take the
;          op-07 renderer at 0xF0E978, anything else the op-02 one at 0xF0E926.
;          When (0x28D3) is 0 the renderer is called inline; otherwise the
;          address of one of the four trampolines below is pushed and handed to
;          thunk T_F42E84 (prom_a 0xF8DA16, the 128-slot ring-buffer enqueue)
;          followed by T_F42DC0 (prom_a 0xF859AB), and the six pushed bytes are
;          released with `inc 6,XSP`.
; Unknown:  why phase 4 and not phase 1 -- 50% duty is the effect, intent is not
;          established.  What 0x17 and 0x1C are as swi 7 functions.
; ---------------------------------------------------------------------
Blink_Tick:
	push	xix	; F0E83A  push XIX
	lda_d16	xix, (10451)	; F0E83B  lda XIX,0x28d3
	incdi8	1, (10449)	; F0E83F  inc 1,(0x28d1)
	ldb_d8	c, (8309)	; F0E843  ld C,(0x2075)
	and	c, 2	; F0E847  and C,0x02
	jrl	z, 183	; F0E84A  jrl Z,0xf0e904
	ldw_d16	bc, (10450)	; F0E84D  ld BC,(0x28d2)
	extz	bc	; F0E851  extz BC
	cps	bc, 0	; F0E853  cp BC,0
	jrl	z, 172	; F0E855  jrl Z,0xf0e904
	cps	bc, 1	; F0E858  cp BC,1
	jrl	z, 167	; F0E85A  jrl Z,0xf0e904
	cps	bc, 2	; F0E85D  cp BC,2
	jr	z, 3	; F0E85F  jr Z,0xf0e864
	jrl	160	; F0E861  jrl T,0xf0e904
	ldb_d8	c, (10449)	; F0E864  ld C,(0x28d1)
	and	c, 7	; F0E868  and C,0x07
	jr	nz, 70	; F0E86B  jr NZ,0xf0e8b3
	.byte 0xC1, 0xC9, 0x28, 0x3F, 0x17	; F0E86D  cp (0x28c9),0x17   [llvm-mc cannot encode this]
	jr	z, 7	; F0E872  jr Z,0xf0e87b
	.byte 0xC1, 0xC9, 0x28, 0x3F, 0x1C	; F0E874  cp (0x28c9),0x1c   [llvm-mc cannot encode this]
	jr	nz, 22	; F0E879  jr NZ,0xf0e891
	ld	c, (xix)	; F0E87B  ld C,(XIX)
	cps	c, 0	; F0E87D  cp C,0
	jr	nz, 8	; F0E87F  jr NZ,0xf0e889
	pushw	1	; F0E881  push 0x0001
	calr	241	; F0E884  calr 0xf0e978
	jr	20	; F0E887  jr T,0xf0e89d
	lda_24	xbc, (15788310)	; F0E889  lda XBC,0xf0e916
	push	xbc	; F0E88E  push XBC
	jr	21	; F0E88F  jr T,0xf0e8a6
	ld	c, (xix)	; F0E891  ld C,(XIX)
	cps	c, 0	; F0E893  cp C,0
	jr	nz, 9	; F0E895  jr NZ,0xf0e8a0
	pushw	1	; F0E897  push 0x0001
	calr	137	; F0E89A  calr 0xf0e926
	popw	bc	; F0E89D  pop BC
	jr	19	; F0E89E  jr T,0xf0e8b3
	lda_24	xbc, (15788294)	; F0E8A0  lda XBC,0xf0e906
	push	xbc	; F0E8A5  push XBC
	call	16002692	; F0E8A6  call 0xf42e84
	pushw	1	; F0E8AA  push 0x0001
	call	16002496	; F0E8AD  call 0xf42dc0
	inc	6, xsp	; F0E8B1  inc 6,XSP
	ldb_d8	c, (10449)	; F0E8B3  ld C,(0x28d1)
	and	c, 7	; F0E8B7  and C,0x07
	cps	c, 4	; F0E8BA  cp C,4
	jr	nz, 70	; F0E8BC  jr NZ,0xf0e904
	.byte 0xC1, 0xC9, 0x28, 0x3F, 0x17	; F0E8BE  cp (0x28c9),0x17   [llvm-mc cannot encode this]
	jr	z, 7	; F0E8C3  jr Z,0xf0e8cc
	.byte 0xC1, 0xC9, 0x28, 0x3F, 0x1C	; F0E8C5  cp (0x28c9),0x1c   [llvm-mc cannot encode this]
	jr	nz, 22	; F0E8CA  jr NZ,0xf0e8e2
	ld	c, (xix)	; F0E8CC  ld C,(XIX)
	cps	c, 0	; F0E8CE  cp C,0
	jr	nz, 8	; F0E8D0  jr NZ,0xf0e8da
	pushw	0	; F0E8D2  push 0x0000
	calr	160	; F0E8D5  calr 0xf0e978
	jr	20	; F0E8D8  jr T,0xf0e8ee
	lda_24	xbc, (15788318)	; F0E8DA  lda XBC,0xf0e91e
	push	xbc	; F0E8DF  push XBC
	jr	21	; F0E8E0  jr T,0xf0e8f7
	ld	c, (xix)	; F0E8E2  ld C,(XIX)
	cps	c, 0	; F0E8E4  cp C,0
	jr	nz, 9	; F0E8E6  jr NZ,0xf0e8f1
	pushw	0	; F0E8E8  push 0x0000
	calr	56	; F0E8EB  calr 0xf0e926
	popw	bc	; F0E8EE  pop BC
	jr	19	; F0E8EF  jr T,0xf0e904
	lda_24	xbc, (15788302)	; F0E8F1  lda XBC,0xf0e90e
	push	xbc	; F0E8F6  push XBC
	call	16002692	; F0E8F7  call 0xf42e84
	pushw	1	; F0E8FB  push 0x0001
	call	16002496	; F0E8FE  call 0xf42dc0
	inc	6, xsp	; F0E902  inc 6,XSP
	pop	xix	; F0E904  pop XIX
	ret	; F0E905  ret

; ---------------------------------------------------------------------
; Blink_Deferred_* -- four 8-byte trampolines, one per (renderer, argument) pair
; Called from: never directly.  Their ADDRESSES are loaded with `lda XBC` in
;          Blink_Tick and pushed to the ring-buffer enqueue T_F42E84, so
;          whatever drains that ring calls them later.
; Inputs:  none (each supplies its own immediate argument)
; Outputs: as the renderer it wraps
; Evidence: each is exactly `push <imm> / calr <renderer> / pop BC / ret`, and
;          the four immediates and targets are the four combinations Blink_Tick
;          needs: {1,0} x {0xF0E926, 0xF0E978}.  Blink_Tick loads 0xF0E916 and
;          0xF0E906 on the phase-0 (draw) path and 0xF0E91E and 0xF0E90E on the
;          phase-4 (blank) path, matching the immediates below.
; ---------------------------------------------------------------------
Blink_Deferred_Op02_Draw:
	pushw	1	; F0E906  push 0x0001
	calr	26	; F0E909  calr 0xf0e926
	popw	bc	; F0E90C  pop BC
	ret	; F0E90D  ret
Blink_Deferred_Op02_Blank:
	pushw	0	; F0E90E  push 0x0000
	calr	18	; F0E911  calr 0xf0e926
	popw	bc	; F0E914  pop BC
	ret	; F0E915  ret
Blink_Deferred_Op07_Draw:
	pushw	1	; F0E916  push 0x0001
	calr	92	; F0E919  calr 0xf0e978
	popw	bc	; F0E91C  pop BC
	ret	; F0E91D  ret
Blink_Deferred_Op07_Blank:
	pushw	0	; F0E91E  push 0x0000
	calr	84	; F0E921  calr 0xf0e978
	popw	bc	; F0E924  pop BC
	ret	; F0E925  ret

; ---------------------------------------------------------------------
; Blink_DrawField_Op02 -- run one patched interpreter-B op-02 record
; Called from: Blink_Tick, four sites, all verified by decoding the `calr`
;          displacement: INLINE at 0xF0E89A (phase 0, draw) and 0xF0E8EB
;          (phase 4, blank), and through the trampolines at 0xF0E909 and
;          0xF0E911 when the draw is deferred to the ring buffer
; Inputs:  (XIZ+8) = 1 to draw the text, 0 to draw the blank;
;          (0x28C8), (0x28C9), (0x28CA), (0x28D0)
; Outputs: one display-list record executed by interpreter B; (0x2540) saved in
;          H and restored afterwards
; Evidence: `link XIZ,-15 / ldir BC=0x0F from DLB_RecordTemplate_Op02` -- and
;          prom_b 0xF78000 reads `02 0F ...`, i.e. opcode 0x02, length 15, the
;          length interpreter B's op-02 handler DLB_Handler_StringTable implies.
;          It then writes the record's documented fields: +6 := (0x28C9) (swi 7
;          function), +0x0D := (0x28CA), +0x0B := (0x28D0), and +7 := 0xF78020
;          (eight spaces) when the argument is 0.  Finally `push XIX / call
;          0xF3183D` -- DisplayListB_RunOne_Stack, converted above.
; Unknown:  nothing is written to +2/+4/+5, so the extracted index stays 0 and
;          the record always renders entry 0.  Whether the author intended the
;          record as a one-entry table or as a plain string is not established.
; ---------------------------------------------------------------------
Blink_DrawField_Op02:
	.byte 0xEE, 0x0C, 0xF1, 0xFF	; F0E926  link XIZ,0xfff1   [llvm-mc cannot encode this]
	pushw	hl	; F0E92A  push HL
	push	xix	; F0E92B  push XIX
	lda	xix, (xiz-15)	; F0E92C  lda XIX,XIZ+0xf1
	push	xix	; F0E92F  push XIX
	ldw	bc, 15	; F0E930  ld BC,0x000f
	lda_24	xiy, (16220160)	; F0E933  lda XIY,0xf78000
	lda	xix, (xiz-15)	; F0E938  lda XIX,XIZ+0xf1
	.byte 0x85, 0x11	; F0E93B  ldir   [llvm-mc cannot encode this]
	pop	xix	; F0E93D  pop XIX
	ldb_d8	h, (9536)	; F0E93E  ld H,(0x2540)
	.byte 0xC1, 0xC8, 0x28, 0x19, 0x40, 0x25	; F0E942  ld (0x2540),(0x28c8)   [llvm-mc cannot encode this]
	.byte 0xBC, 0x06, 0x14, 0xC9, 0x28	; F0E948  ld (XIX+0x06),(0x28c9)   [llvm-mc cannot encode this]
	.byte 0xBC, 0x0D, 0x16, 0xCA, 0x28	; F0E94D  ldw (XIX+0x0d),(0x28ca)   [llvm-mc cannot encode this]
	ldw_d16	bc, (10448)	; F0E952  ld BC,(0x28d0)
	extz	bc	; F0E956  extz BC
	ld	(xix+11), bc	; F0E958  ld (XIX+0x0b),BC
	.byte 0x8E, 0x08, 0x3F, 0x00	; F0E95B  cp (XIZ+0x08),0x00   [llvm-mc cannot encode this]
	jr	nz, 8	; F0E95F  jr NZ,0xf0e969
	lda_24	xbc, (16220192)	; F0E961  lda XBC,0xf78020
	ld	(xix+7), xbc	; F0E966  ld (XIX+0x07),XBC
	push	xix	; F0E969  push XIX
	call	15931453	; F0E96A  call 0xf3183d
	stb_d8	(9536), h	; F0E96E  ld (0x2540),H
	pop	xbc	; F0E972  pop XBC
	pop	xix	; F0E973  pop XIX
	popw	hl	; F0E974  pop HL
	.byte 0xEE, 0x0D	; F0E975  unlk XIZ   [llvm-mc cannot encode this]
	ret	; F0E977  ret

; ---------------------------------------------------------------------
; Blink_DrawField_Op07 -- the same, for the 17-byte op-07 record
; Called from: Blink_Tick, four sites: INLINE at 0xF0E884 (phase 0, draw) and
;          0xF0E8D5 (phase 4, blank), and through the trampolines at 0xF0E919
;          and 0xF0E921 when the draw is deferred
; Inputs:  (XIZ+8) = 1 to draw, 0 to blank; (0x28C8), (0x28C9), (0x28CC),
;          (0x28CE), (0x28D0)
; Outputs: as Blink_DrawField_Op02
; Evidence: identical shape with `link XIZ,-17 / ldir BC=0x11 from 0xF7800F`,
;          and 0xF7800F reads `07 0F ...` -- opcode 0x07, whose handler 0xF31B39
;          implies a 17-byte record, which is the ldir count.  (The record's own
;          length byte says 15; see DLB_RecordTemplate_Op07 for why nothing
;          reads it.)  The one structural difference from the op-02 renderer is
;          the extra field: `ldw (XIX+0x0f),(0x28ce)`, which is exactly the word
;          op 07 has and op 02 does not.
; Unknown:  as above; plus why (0x28CC) and not (0x28CA) feeds +0x0D here.
; ---------------------------------------------------------------------
Blink_DrawField_Op07:
	.byte 0xEE, 0x0C, 0xEF, 0xFF	; F0E978  link XIZ,0xffef   [llvm-mc cannot encode this]
	pushw	hl	; F0E97C  push HL
	push	xix	; F0E97D  push XIX
	lda	xix, (xiz-17)	; F0E97E  lda XIX,XIZ+0xef
	push	xix	; F0E981  push XIX
	ldw	bc, 17	; F0E982  ld BC,0x0011
	lda_24	xiy, (16220175)	; F0E985  lda XIY,0xf7800f
	lda	xix, (xiz-17)	; F0E98A  lda XIX,XIZ+0xef
	.byte 0x85, 0x11	; F0E98D  ldir   [llvm-mc cannot encode this]
	pop	xix	; F0E98F  pop XIX
	ldb_d8	h, (9536)	; F0E990  ld H,(0x2540)
	.byte 0xC1, 0xC8, 0x28, 0x19, 0x40, 0x25	; F0E994  ld (0x2540),(0x28c8)   [llvm-mc cannot encode this]
	.byte 0xBC, 0x06, 0x14, 0xC9, 0x28	; F0E99A  ld (XIX+0x06),(0x28c9)   [llvm-mc cannot encode this]
	.byte 0xBC, 0x0D, 0x16, 0xCC, 0x28	; F0E99F  ldw (XIX+0x0d),(0x28cc)   [llvm-mc cannot encode this]
	.byte 0xBC, 0x0F, 0x16, 0xCE, 0x28	; F0E9A4  ldw (XIX+0x0f),(0x28ce)   [llvm-mc cannot encode this]
	ldw_d16	bc, (10448)	; F0E9A9  ld BC,(0x28d0)
	extz	bc	; F0E9AD  extz BC
	ld	(xix+11), bc	; F0E9AF  ld (XIX+0x0b),BC
	.byte 0x8E, 0x08, 0x3F, 0x00	; F0E9B2  cp (XIZ+0x08),0x00   [llvm-mc cannot encode this]
	jr	nz, 8	; F0E9B6  jr NZ,0xf0e9c0
	lda_24	xbc, (16220192)	; F0E9B8  lda XBC,0xf78020
	ld	(xix+7), xbc	; F0E9BD  ld (XIX+0x07),XBC
	push	xix	; F0E9C0  push XIX
	call	15931453	; F0E9C1  call 0xf3183d
	stb_d8	(9536), h	; F0E9C5  ld (0x2540),H
	pop	xbc	; F0E9C9  pop XBC
	pop	xix	; F0E9CA  pop XIX
	popw	hl	; F0E9CB  pop HL
	.byte 0xEE, 0x0D	; F0E9CC  unlk XIZ   [llvm-mc cannot encode this]
	ret	; F0E9CE  ret

; ---------------------------------------------------------------------
; Blink_Command -- 12-way command dispatch that sets the blink state
; Called from: thunk T_F42E20 (x41, an upper bound)
; Inputs:  (XIZ+8) = a pointer; the byte at *(XIZ+8) is the command, 0x00-0x0B
; Outputs: (0x28C8) := (0x2540) (the current LCD layer is captured for the
;          renderers); (0x28D3) := 1 or 0; XIX := 0x28D2 for the arms; then a
;          jump through Blink_Command_Table
; Evidence: `ld A,(XBC) / extz / cp WA,0x000b / jrl UGT,<exit> / sll 2,WA /
;          add XWA,0x00F0EA14 / ld XWA,(XWA) / jp XWA`.  The bound 0x0B fixes
;          the table at 12 entries and 0xF0EA14 + 12*4 = 0xF0EA44 is the lowest
;          address any entry holds, so nothing is left over between the table
;          and the first arm.
; Notes:   (0x28D3) is set by comparing a frame address (`lda XWA,XIZ+0xfe`)
;          with the constant 0x0060E800: at or above it the byte stays 1, below
;          it becomes 0.  The boot stack pointer is 0x0060EB80 (prom_a 0xF85606,
;          notes/FINDINGS-memory-map.md), so the constant is 0x380 = 896 bytes
;          into that stack.  Blink_Tick uses the result to choose between
;          calling the renderer inline and posting it to the ring buffer.
; Unknown:  ⚠ WHAT THE TEST MEANS is not established -- "deep frame vs shallow
;          frame", "task stack vs interrupt stack" and "recursion guard" all fit
;          the same three instructions and this tree cannot tell them apart.
;          Also unknown: what the 12 commands are.  Only their SHAPE is decoded
;          below, from the four distinct arms the table names.
; ---------------------------------------------------------------------
Blink_Command:
	.byte 0xEE, 0x0C, 0xFA, 0xFF	; F0E9CF  link XIZ,0xfffa   [llvm-mc cannot encode this]
	push	xix	; F0E9D3  push XIX
	lda_d16	xix, (10450)	; F0E9D4  lda XIX,0x28d2
	ld	xbc, 6350848	; F0E9D8  ld XBC,0x0060e800
	ld	(xiz-6), xbc	; F0E9DD  ld (XIZ+0xfa),XBC
	stdi8	(10451), 1	; F0E9E0  ld (0x28d3),0x01
	lda	xwa, (xiz-2)	; F0E9E5  lda XWA,XIZ+0xfe
	cp	xwa, xbc	; F0E9E8  cp XWA,XBC
	jr	nc, 5	; F0E9EA  jr NC,0xf0e9f1
	stdi8	(10451), 0	; F0E9EC  ld (0x28d3),0x00
	.byte 0xC1, 0x40, 0x25, 0x19, 0xC8, 0x28	; F0E9F1  ld (0x28c8),(0x2540)   [llvm-mc cannot encode this]
	ld	xbc, (xiz+8)	; F0E9F7  ld XBC,(XIZ+0x08)
	ld	a, (xbc)	; F0E9FA  ld A,(XBC)
	extz	wa	; F0E9FC  extz WA
	extz	xwa	; F0E9FE  extz XWA
	cp	wa, 11	; F0EA00  cp WA,0x000b
	jrl	ugt, 148	; F0EA04  jrl UGT,0xf0ea9b
	sll	wa, 2	; F0EA07  sll 0x02,WA
	add	xwa, 15788564	; F0EA0A  add XWA,0x00f0ea14
	ld	xwa, (xwa)	; F0EA10  ld XWA,(XWA)
	jp	(xwa)	; F0EA12  jp T,XWA

; ------------------------------------------------------------------
; Blink_Command_Table -- 12 x LE32 code pointer
; Read by:  Blink_Command 0xF0EA0A (`add XWA,0x00f0ea14`), indexed by the
;           command byte * 4.
; Count:    12, and it is bounded twice.  (a) `cp WA,0x000b / jrl UGT` rejects
;           anything above 0x0B, so at most 12 entries can ever be read.
;           (b) 0xF0EA14 + 12*4 = 0xF0EA44, which is the LOWEST address any of
;           the twelve entries holds -- the table abuts its own first arm with
;           nothing in between, so it cannot be longer either.
;           Verified for the LAST entry as well as the first: entry [11] is
;           0xF0EA75, an arm, and the four bytes at 0xF0EA44 are the arm's first
;           instruction (`ld C,(0x2823)`), not a thirteenth pointer.
; Layout:   only four distinct targets appear; the repetition IS the command map.
; Note:     the twelve entries are emitted as SYMBOLS, not as literals, so the
;           build gate itself proves each pointer equals the address its named
;           arm actually sits at -- a wrong label would change the bytes.
; ------------------------------------------------------------------
Blink_Command_Table:
	.long Blink_CmdArm_SetState			; [ 0] 0xF0EA64
	.long Blink_CmdArm_Ret				; [ 1] 0xF0EA9B
	.long Blink_CmdArm_SetState_Then_F0EC4A		; [ 2] 0xF0EA44
	.long Blink_CmdArm_Ret				; [ 3] 0xF0EA9B
	.long Blink_CmdArm_Ret				; [ 4] 0xF0EA9B
	.long Blink_CmdArm_SetState_DashTest		; [ 5] 0xF0EA75
	.long Blink_CmdArm_SetState			; [ 6] 0xF0EA64
	.long Blink_CmdArm_SetState_Then_F0EC4A		; [ 7] 0xF0EA44
	.long Blink_CmdArm_Ret				; [ 8] 0xF0EA9B
	.long Blink_CmdArm_SetState			; [ 9] 0xF0EA64
	.long Blink_CmdArm_SetState			; [10] 0xF0EA64
	.long Blink_CmdArm_SetState_DashTest		; [11] 0xF0EA75

; ---------------------------------------------------------------------
; Blink_CmdArm_SetState_Then_F0EC4A -- commands 2 and 7
; Called from: Blink_Command_Table entries [2] and [7]
; Inputs:  XIX = 0x28D2 (set by Blink_Command); (0x2823); (XIZ+8)
; Outputs: (0x28D2) := 2 when (0x2823) != 0x20; := 1 when (0x2823) == 0x20 and
;          (0x28D2) was 0; unchanged otherwise.  Then calls 0xF0EC4A with the
;          command pointer.
; Evidence: the writes are literal (`ld (XIX),0x02` / `ld (XIX),0x01`) and XIX
;          is 0x28D2 by construction.  2 is the value Blink_Tick runs on, so
;          "(0x2823) is not 0x20" is what starts the blink.
; Unknown:  what (0x2823) is.  0x20 is ASCII space and this module is about
;          text, but that reading is NOT asserted.  0xF0EC4A is not converted.
; ---------------------------------------------------------------------
Blink_CmdArm_SetState_Then_F0EC4A:
	ldb_d8	c, (10275)	; F0EA44  ld C,(0x2823)
	cp	c, 32	; F0EA48  cp C,0x20
	jr	z, 5	; F0EA4B  jr Z,0xf0ea52
	ld	(xix), 2	; F0EA4D  ld (XIX),0x02
	jr	9	; F0EA50  jr T,0xf0ea5b
	ld	c, (xix)	; F0EA52  ld C,(XIX)
	cps	c, 0	; F0EA54  cp C,0
	jr	nz, 3	; F0EA56  jr NZ,0xf0ea5b
	ld	(xix), 1	; F0EA58  ld (XIX),0x01
	ld	xbc, (xiz+8)	; F0EA5B  ld XBC,(XIZ+0x08)
	push	xbc	; F0EA5E  push XBC
	calr	488	; F0EA5F  calr 0xf0ec4a
	jr	54	; F0EA62  jr T,0xf0ea9a

; ---------------------------------------------------------------------
; Blink_CmdArm_SetState -- commands 0, 6, 9 and 10
; Called from: Blink_Command_Table entries [0], [6], [9], [10]
; Inputs/Outputs: as the arm above, minus the 0xF0EC4A call; the tail it falls
;          into calls 0xF0EA9F instead
; Evidence: same two literal writes through the same XIX; the only difference is
;          the shared tail at 0xF0EA93.
; Unknown:  0xF0EA9F is not converted this round.
; ---------------------------------------------------------------------
Blink_CmdArm_SetState:
	ldb_d8	c, (10275)	; F0EA64  ld C,(0x2823)
	cp	c, 32	; F0EA68  cp C,0x20
	jr	nz, 24	; F0EA6B  jr NZ,0xf0ea85
	ld	c, (xix)	; F0EA6D  ld C,(XIX)
	cps	c, 0	; F0EA6F  cp C,0
	jr	nz, 32	; F0EA71  jr NZ,0xf0ea93
	jr	27	; F0EA73  jr T,0xf0ea90

; ---------------------------------------------------------------------
; Blink_CmdArm_SetState_DashTest -- commands 5 and 11
; Called from: Blink_Command_Table entries [5] and [11]
; Inputs:  XIX = 0x28D2; (0x2823); (0x2820)
; Outputs: as Blink_CmdArm_SetState, except that when (0x2823) == 0x20 a second
;          test decides: (0x2820) == 0x2D also gives state 2; only when both
;          fail does the state-1 path run.
; Evidence: `cp (0x2820),0x2d / jr NZ` inserted between the space test and the
;          shared tail; nothing else differs from the arm above.
; Unknown:  what (0x2820) is.  0x2D is ASCII '-'; not asserted.
; ---------------------------------------------------------------------
Blink_CmdArm_SetState_DashTest:
	ldb_d8	c, (10275)	; F0EA75  ld C,(0x2823)
	cp	c, 32	; F0EA79  cp C,0x20
	jr	nz, 7	; F0EA7C  jr NZ,0xf0ea85
	.byte 0xC1, 0x20, 0x28, 0x3F, 0x2D	; F0EA7E  cp (0x2820),0x2d   [llvm-mc cannot encode this]
	jr	nz, 5	; F0EA83  jr NZ,0xf0ea8a
	ld	(xix), 2	; F0EA85  ld (XIX),0x02
	jr	9	; F0EA88  jr T,0xf0ea93
	ld	c, (xix)	; F0EA8A  ld C,(XIX)
	cps	c, 0	; F0EA8C  cp C,0
	jr	nz, 3	; F0EA8E  jr NZ,0xf0ea93
	ld	(xix), 1	; F0EA90  ld (XIX),0x01
	ld	xbc, (xiz+8)	; F0EA93  ld XBC,(XIZ+0x08)
	push	xbc	; F0EA96  push XBC
	calr	5	; F0EA97  calr 0xf0ea9f
	pop	xiy	; F0EA9A  pop XIY

; ---------------------------------------------------------------------
; Blink_CmdArm_Ret -- commands 1, 3, 4 and 8, and the out-of-range exit
; Called from: Blink_Command_Table entries [1], [3], [4], [8], and by the
;          `jrl UGT,0xF0EA9B` that rejects a command byte above 0x0B
; Outputs: none beyond the (0x28C8)/(0x28D3) writes Blink_Command already made
; Evidence: it is Blink_Command's own epilogue -- `pop XIX / unlk XIZ / ret`.
;          Four of the twelve commands do nothing but reach it.
; ---------------------------------------------------------------------
Blink_CmdArm_Ret:
	pop	xix	; F0EA9B  pop XIX
	.byte 0xEE, 0x0D	; F0EA9C  unlk XIZ   [llvm-mc cannot encode this]
	ret	; F0EA9E  ret

; --- 0xF0EA9F-0xF27BFF: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x00EA9F, 0x019161

; ------------------------------------------------------------------
; 0xF27C00-0xF283A6 -- 200 display-list records, 1959 bytes -- interpreter A
;   entered at: 0xF27C00, 0xF28064, 0xF2808C, 0xF28331, 0xF2833B, 0xF2834F, 0xF28373, 0xF2837D
;   ends used:  0xF28064, 0xF2808C, 0xF28331, 0xF2833B, 0xF28345, 0xF2834F, 0xF28373, 0xF2837D, 0xF283A7
; ------------------------------------------------------------------
DL_F27C00:
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F2843D
	.short 0x05F1
	.short 0x0002
	.short 0x0009
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F2843D
	.short 0x0FC9
	.short 0x0002
	.short 0x0009
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F2843D
	.short 0x0615
	.short 0x0002
	.short 0x0009
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F2843D
	.short 0x0FED
	.short 0x0002
	.short 0x0009
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x49
	.short 0x16AA
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x24
	.short 0x16CB
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x2080
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x2085
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x208A
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x208F
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x2094
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x2099
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x209E
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x20A3
	.short 0x0005
	.short 0x001E
	.byte 0x1C, 0x10	; op 1C, 16 bytes -> handler 0xF31A52
	.short 0x006E
	.short 0x0005
	.ascii "SOUND MODE"
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x13
	.short 0x005A
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17C0
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17E7
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0031
	.short 0x00B3
	.ascii "1"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x003F
	.short 0x00B3
	.ascii "2"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x004D
	.short 0x00B3
	.ascii "3"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x005B
	.short 0x00B3
	.ascii "4"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0069
	.short 0x00B3
	.ascii "5"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0077
	.short 0x00B3
	.ascii "6"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00C2
	.short 0x00B3
	.ascii "1"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00D0
	.short 0x00B3
	.ascii "2"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00DE
	.short 0x00B3
	.ascii "3"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00EC
	.short 0x00B3
	.ascii "4"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00FA
	.short 0x00B3
	.ascii "5"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0108
	.short 0x00B3
	.ascii "6"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x000A
	.short 0x00D4
	.ascii "OCT"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0032
	.short 0x00D4
	.ascii "LVL"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x005A
	.short 0x00D4
	.ascii "PAN"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0080
	.short 0x00D4
	.ascii "EFF1"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00A8
	.short 0x00D4
	.ascii "EFF2"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00D2
	.short 0x00D4
	.ascii "REV"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00FA
	.short 0x00D4
	.ascii "INT"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0120
	.short 0x00D4
	.ascii "MIDI"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0008
	.short 0x0023
	.short 0x0136
	.short 0x0070
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000A
	.short 0x007D
	.short 0x009C
	.short 0x00C2
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00A2
	.short 0x007D
	.short 0x0135
	.short 0x00C2
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x001B
	.short 0x0089
	.short 0x002E
	.short 0x0089
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x001B
	.short 0x008A
	.short 0x002E
	.short 0x008A
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x001B
	.short 0x0089
	.short 0x001B
	.short 0x0090
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x001C
	.short 0x0089
	.short 0x001C
	.short 0x0090
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0028
	.short 0x009D
	.short 0x002D
	.short 0x009D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0028
	.short 0x009E
	.short 0x002D
	.short 0x009E
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0112
	.short 0x0089
	.short 0x0122
	.short 0x0089
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0112
	.short 0x008A
	.short 0x0122
	.short 0x008A
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0122
	.short 0x0089
	.short 0x0122
	.short 0x0090
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0123
	.short 0x0089
	.short 0x0123
	.short 0x0090
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0113
	.short 0x009D
	.short 0x0116
	.short 0x009D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0113
	.short 0x009E
	.short 0x0116
	.short 0x009E
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x00B0
	.short 0x003A
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x003C
	.short 0x00B0
	.short 0x0048
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x004A
	.short 0x00B0
	.short 0x0056
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0058
	.short 0x00B0
	.short 0x0064
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0066
	.short 0x00B0
	.short 0x0072
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0074
	.short 0x00B0
	.short 0x0080
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00BF
	.short 0x00B0
	.short 0x00CB
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00B0
	.short 0x00D9
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00DB
	.short 0x00B0
	.short 0x00E7
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00E9
	.short 0x00B0
	.short 0x00F5
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F7
	.short 0x00B0
	.short 0x0103
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0105
	.short 0x00B0
	.short 0x0111
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x00BC
	.short 0x0081
	.short 0x00BC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00BF
	.short 0x00BC
	.short 0x0112
	.short 0x00BC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x00BD
	.short 0x003B
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x003D
	.short 0x00BD
	.short 0x0049
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x004B
	.short 0x00BD
	.short 0x0057
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00BD
	.short 0x0065
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0067
	.short 0x00BD
	.short 0x0073
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0075
	.short 0x00BD
	.short 0x0081
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00C0
	.short 0x00BD
	.short 0x00CC
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CE
	.short 0x00BD
	.short 0x00DA
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00DC
	.short 0x00BD
	.short 0x00E8
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00EA
	.short 0x00BD
	.short 0x00F6
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F8
	.short 0x00BD
	.short 0x0104
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0106
	.short 0x00BD
	.short 0x0112
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x00B0
	.short 0x002E
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x003A
	.short 0x00B0
	.short 0x003A
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x003B
	.short 0x00B1
	.short 0x003B
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x003C
	.short 0x00B0
	.short 0x003C
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0048
	.short 0x00B0
	.short 0x0048
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0049
	.short 0x00B1
	.short 0x0049
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x004A
	.short 0x00B0
	.short 0x004A
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0056
	.short 0x00B0
	.short 0x0056
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0057
	.short 0x00B1
	.short 0x0057
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0058
	.short 0x00B0
	.short 0x0058
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0064
	.short 0x00B0
	.short 0x0064
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0065
	.short 0x00B1
	.short 0x0065
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0066
	.short 0x00B0
	.short 0x0066
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0072
	.short 0x00B0
	.short 0x0072
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0073
	.short 0x00B1
	.short 0x0073
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0074
	.short 0x00B0
	.short 0x0074
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0080
	.short 0x00B0
	.short 0x0080
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00B1
	.short 0x0081
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00BF
	.short 0x00B0
	.short 0x00BF
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00CB
	.short 0x00B0
	.short 0x00CB
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00CC
	.short 0x00B1
	.short 0x00CC
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00B0
	.short 0x00CD
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00D9
	.short 0x00B0
	.short 0x00D9
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00DA
	.short 0x00B1
	.short 0x00DA
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00DB
	.short 0x00B0
	.short 0x00DB
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00E7
	.short 0x00B0
	.short 0x00E7
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00E8
	.short 0x00B1
	.short 0x00E8
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00E9
	.short 0x00B0
	.short 0x00E9
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00B0
	.short 0x00F5
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00F6
	.short 0x00B1
	.short 0x00F6
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00F7
	.short 0x00B0
	.short 0x00F7
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0103
	.short 0x00B0
	.short 0x0103
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0104
	.short 0x00B1
	.short 0x0104
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0105
	.short 0x00B0
	.short 0x0105
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0111
	.short 0x00B0
	.short 0x0111
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0112
	.short 0x00B1
	.short 0x0112
	.short 0x00BD
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x0021
	.short 0x0138
	.short 0x0072
DL_F28064:
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x0083
	.short 0x009A
	.short 0x0090
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00A6
	.short 0x0083
	.short 0x0112
	.short 0x0090
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x0097
	.short 0x009A
	.short 0x00A4
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00A6
	.short 0x0097
	.short 0x0112
	.short 0x00A4
DL_F2808C:
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F2843D
	.short 0x05F1
	.short 0x0002
	.short 0x0009
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F2843D
	.short 0x0FC9
	.short 0x0002
	.short 0x0009
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F2843D
	.short 0x0615
	.short 0x0002
	.short 0x0009
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F2843D
	.short 0x0FED
	.short 0x0002
	.short 0x0009
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x24
	.short 0x183B
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x2080
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x2085
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x208A
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x208F
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x2094
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x2099
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x209E
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x20A3
	.short 0x0005
	.short 0x001E
	.byte 0x1C, 0x10	; op 1C, 16 bytes -> handler 0xF31A52
	.short 0x006E
	.short 0x0005
	.ascii "SOUND MODE"
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x13
	.short 0x005A
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00C7
	.short 0x009F
	.ascii "1"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00D5
	.short 0x009F
	.ascii "2"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00E3
	.short 0x009F
	.ascii "3"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00F1
	.short 0x009F
	.ascii "4"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00FF
	.short 0x009F
	.ascii "5"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x010D
	.short 0x009F
	.ascii "6"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x000A
	.short 0x00D4
	.ascii "OCT"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0032
	.short 0x00D4
	.ascii "LVL"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x005A
	.short 0x00D4
	.ascii "PAN"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0080
	.short 0x00D4
	.ascii "EFF1"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00A8
	.short 0x00D4
	.ascii "EFF2"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00D2
	.short 0x00D4
	.ascii "REV"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00FA
	.short 0x00D4
	.ascii "INT"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0120
	.short 0x00D4
	.ascii "MIDI"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0008
	.short 0x0023
	.short 0x0136
	.short 0x0070
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0009
	.short 0x007D
	.short 0x0135
	.short 0x00C2
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0021
	.short 0x0093
	.short 0x0036
	.short 0x0093
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0021
	.short 0x0094
	.short 0x0036
	.short 0x0094
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00C4
	.short 0x009C
	.short 0x00D0
	.short 0x009C
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D2
	.short 0x009C
	.short 0x00DE
	.short 0x009C
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00E0
	.short 0x009C
	.short 0x00EC
	.short 0x009C
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00EE
	.short 0x009C
	.short 0x00FA
	.short 0x009C
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00FC
	.short 0x009C
	.short 0x0108
	.short 0x009C
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x010A
	.short 0x009C
	.short 0x0116
	.short 0x009C
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x00A7
	.short 0x0036
	.short 0x00A7
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x00A8
	.short 0x0036
	.short 0x00A8
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00C4
	.short 0x00A8
	.short 0x0117
	.short 0x00A8
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00C5
	.short 0x00A9
	.short 0x00D1
	.short 0x00A9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D3
	.short 0x00A9
	.short 0x00DF
	.short 0x00A9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00E1
	.short 0x00A9
	.short 0x00ED
	.short 0x00A9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00EF
	.short 0x00A9
	.short 0x00FB
	.short 0x00A9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00FD
	.short 0x00A9
	.short 0x0109
	.short 0x00A9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x010B
	.short 0x00A9
	.short 0x0117
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0021
	.short 0x0093
	.short 0x0021
	.short 0x009A
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0022
	.short 0x0093
	.short 0x0022
	.short 0x009A
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00C4
	.short 0x009C
	.short 0x00C4
	.short 0x00A8
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00D0
	.short 0x009C
	.short 0x00D0
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x009D
	.short 0x00D1
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00D2
	.short 0x009C
	.short 0x00D2
	.short 0x00A8
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00DE
	.short 0x009C
	.short 0x00DE
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00DF
	.short 0x009D
	.short 0x00DF
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00E0
	.short 0x009C
	.short 0x00E0
	.short 0x00A8
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00EC
	.short 0x009C
	.short 0x00EC
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00ED
	.short 0x009D
	.short 0x00ED
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00EE
	.short 0x009C
	.short 0x00EE
	.short 0x00A8
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00FA
	.short 0x009C
	.short 0x00FA
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00FB
	.short 0x009D
	.short 0x00FB
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00FC
	.short 0x009C
	.short 0x00FC
	.short 0x00A8
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0108
	.short 0x009C
	.short 0x0108
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0109
	.short 0x009D
	.short 0x0109
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x010A
	.short 0x009C
	.short 0x010A
	.short 0x00A8
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x009C
	.short 0x0116
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0117
	.short 0x009D
	.short 0x0117
	.short 0x00A9
DL_F28331:
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x0021
	.short 0x0138
	.short 0x0072
DL_F2833B:
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0036
	.short 0x008D
	.short 0x00A2
	.short 0x009A
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0036
	.short 0x00A1
	.short 0x00A2
	.short 0x00AE
DL_F2834F:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0000
	.short 0x001E
	.short 0x004F
	.short 0x0031
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0550
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x0B	; op 06, 11 bytes -> handler 0xF31A3A
	.short 0x0552
	.ascii "DRAWBAR"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x001E
	.short 0x004C
	.short 0x002E
DL_F28373:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0000
	.short 0x001E
	.short 0x004F
	.short 0x0031
DL_F2837D:
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F2843D
	.short 0x05F1
	.short 0x0002
	.short 0x0009
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0008
	.short 0x0023
	.short 0x004F
	.short 0x0023
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0008
	.short 0x0023
	.short 0x0008
	.short 0x0031
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x0021
	.short 0x004F
	.short 0x0031

; --- 0xF283A7-0xF28801: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0283A7, 0x00045B

; ------------------------------------------------------------------
; 0xF28802-0xF2882A -- 4 display-list records, 41 bytes -- interpreter A (3 records) and B (1)
;   entered at: 0xF28802, 0xF2880C, 0xF28816, 0xF28820
;   ends used:  0xF2880C, 0xF28816, 0xF28820, 0xF2882B
; ------------------------------------------------------------------
DL_F28802:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0030
	.short 0x00B2
	.short 0x007E
	.short 0x00BA
DL_F2880C:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x00C1
	.short 0x00B2
	.short 0x010F
	.short 0x00BA
DL_F28816:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x00C6
	.short 0x009E
	.short 0x0114
	.short 0x00A6
DL_F28820:
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F2882B	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF2882B-0xF2885A: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x02882B, 0x000030

; ------------------------------------------------------------------
; 0xF2885B-0xF28865 -- 1 display-list records, 11 bytes -- interpreter B
;   entered at: 0xF2885B
;   ends used:  0xF28866
; ------------------------------------------------------------------
DL_F2885B:
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F28866	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF28866-0xF28895: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x028866, 0x000030

; ------------------------------------------------------------------
; 0xF28896-0xF288A0 -- 1 display-list records, 11 bytes -- interpreter B
;   entered at: 0xF28896
;   ends used:  0xF288A1
; ------------------------------------------------------------------
DL_F28896:
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F288A1	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF288A1-0xF288D0: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0288A1, 0x000030

; ------------------------------------------------------------------
; 0xF288D1-0xF296D5 -- 363 display-list records, 3589 bytes -- interpreter A (357 records) and B (6)
;   entered at: 0xF288D1, 0xF288E0, 0xF288EF, 0xF288FE, 0xF2890D, 0xF2891C, 0xF2892B, 0xF28930, 0xF28938, 0xF28DF3, 0xF28E1B, 0xF29121, 0xF29135, 0xF29672, 0xF2967C, 0xF29686, 0xF296AE, 0xF296B8, 0xF296C2, 0xF296CC
;   ends used:  0xF288E0, 0xF288EF, 0xF288FE, 0xF2890D, 0xF2891C, 0xF2892B, 0xF28930, 0xF28938, 0xF28DF3, 0xF28E1B, 0xF29121, 0xF29135, 0xF29672, 0xF2967C, 0xF29686, 0xF296AE, 0xF296B8, 0xF296C2, 0xF296CC, 0xF296D6
; ------------------------------------------------------------------
DL_F288D1:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x000022F0	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x17EE	; +0x0D -> IX
DL_F288E0:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x000022F0	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x14CE	; +0x0D -> IX
DL_F288EF:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x000022F0	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x17FD	; +0x0D -> IX
DL_F288FE:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x000022F0	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x14DD	; +0x0D -> IX
DL_F2890D:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x000022F0	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x197F	; +0x0D -> IX
DL_F2891C:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x000022F0	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x165F	; +0x0D -> IX
DL_F2892B:
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x1E
	.short 0x0DB1
DL_F28930:
	.byte 0x0E, 0x08	; op 0E, 8 bytes -> handler 0xF31A9F
	.short 0x0DB1
	.short 0x0003
	.short 0x0018
DL_F28938:
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F2843D
	.short 0x05F1
	.short 0x0002
	.short 0x0009
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F2843D
	.short 0x0FC9
	.short 0x0002
	.short 0x0009
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F2843D
	.short 0x0615
	.short 0x0002
	.short 0x0009
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F2843D
	.short 0x0FED
	.short 0x0002
	.short 0x0009
	.byte 0x20, 0x0B	; op 20, 11 bytes -> handler 0xF31A3A
	.short 0x0110
	.ascii "PAGE1/2"
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x49
	.short 0x16AA
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x24
	.short 0x16CB
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x2080
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x2085
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x208A
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x208F
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x2094
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x2099
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x209E
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x20A3
	.short 0x0005
	.short 0x001E
	.byte 0x1C, 0x16	; op 1C, 22 bytes -> handler 0xF31A52
	.short 0x0040
	.short 0x0005
	.ascii "C0MBINATI0N M0DE"
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x6F
	.short 0x002C
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17C0
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17E7
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0031
	.short 0x00B3
	.ascii "1"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x003F
	.short 0x00B3
	.ascii "2"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x004D
	.short 0x00B3
	.ascii "3"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x005B
	.short 0x00B3
	.ascii "4"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0069
	.short 0x00B3
	.ascii "5"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0077
	.short 0x00B3
	.ascii "6"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00C2
	.short 0x00B3
	.ascii "1"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00D0
	.short 0x00B3
	.ascii "2"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00DE
	.short 0x00B3
	.ascii "3"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00EC
	.short 0x00B3
	.ascii "4"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00FA
	.short 0x00B3
	.ascii "5"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0108
	.short 0x00B3
	.ascii "6"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x000A
	.short 0x00D4
	.ascii "OCT"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0032
	.short 0x00D4
	.ascii "VOL"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x005A
	.short 0x00D4
	.ascii "PAN"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0080
	.short 0x00D4
	.ascii "EFF1"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00A8
	.short 0x00D4
	.ascii "EFF2"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00D2
	.short 0x00D4
	.ascii "REV"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00FA
	.short 0x00D4
	.ascii "INT"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0120
	.short 0x00D4
	.ascii "PART"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000A
	.short 0x007D
	.short 0x009C
	.short 0x00C2
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00A2
	.short 0x007D
	.short 0x0135
	.short 0x00C2
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x0021
	.short 0x0138
	.short 0x0021
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x0022
	.short 0x0138
	.short 0x0022
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x0071
	.short 0x0138
	.short 0x0071
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x0072
	.short 0x0138
	.short 0x0072
	.byte 0x12, 0x0A	; op 12, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x0021
	.short 0x0006
	.short 0x0072
	.byte 0x12, 0x0A	; op 12, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x0021
	.short 0x0007
	.short 0x0072
	.byte 0x12, 0x0A	; op 12, 10 bytes -> handler 0xF31A75
	.short 0x0137
	.short 0x0021
	.short 0x0137
	.short 0x0072
	.byte 0x12, 0x0A	; op 12, 10 bytes -> handler 0xF31A75
	.short 0x0138
	.short 0x0021
	.short 0x0138
	.short 0x0072
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x001B
	.short 0x0089
	.short 0x002E
	.short 0x0089
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x001B
	.short 0x008A
	.short 0x002E
	.short 0x008A
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x001B
	.short 0x0089
	.short 0x001B
	.short 0x0090
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x001C
	.short 0x0089
	.short 0x001C
	.short 0x0090
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0028
	.short 0x009D
	.short 0x002D
	.short 0x009D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0028
	.short 0x009E
	.short 0x002D
	.short 0x009E
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0112
	.short 0x0089
	.short 0x0122
	.short 0x0089
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0112
	.short 0x008A
	.short 0x0122
	.short 0x008A
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0122
	.short 0x0089
	.short 0x0122
	.short 0x0090
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0123
	.short 0x0089
	.short 0x0123
	.short 0x0090
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0113
	.short 0x009D
	.short 0x0116
	.short 0x009D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0113
	.short 0x009E
	.short 0x0116
	.short 0x009E
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x00B0
	.short 0x003A
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x003C
	.short 0x00B0
	.short 0x0048
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x004A
	.short 0x00B0
	.short 0x0056
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0058
	.short 0x00B0
	.short 0x0064
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0066
	.short 0x00B0
	.short 0x0072
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0074
	.short 0x00B0
	.short 0x0080
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00BF
	.short 0x00B0
	.short 0x00CB
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00B0
	.short 0x00D9
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00DB
	.short 0x00B0
	.short 0x00E7
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00E9
	.short 0x00B0
	.short 0x00F5
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F7
	.short 0x00B0
	.short 0x0103
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0105
	.short 0x00B0
	.short 0x0111
	.short 0x00B0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x00BC
	.short 0x0081
	.short 0x00BC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00BF
	.short 0x00BC
	.short 0x0112
	.short 0x00BC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x00BD
	.short 0x003B
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x003D
	.short 0x00BD
	.short 0x0049
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x004B
	.short 0x00BD
	.short 0x0057
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00BD
	.short 0x0065
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0067
	.short 0x00BD
	.short 0x0073
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0075
	.short 0x00BD
	.short 0x0081
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00C0
	.short 0x00BD
	.short 0x00CC
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CE
	.short 0x00BD
	.short 0x00DA
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00DC
	.short 0x00BD
	.short 0x00E8
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00EA
	.short 0x00BD
	.short 0x00F6
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F8
	.short 0x00BD
	.short 0x0104
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0106
	.short 0x00BD
	.short 0x0112
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x00B0
	.short 0x002E
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x003A
	.short 0x00B0
	.short 0x003A
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x003B
	.short 0x00B1
	.short 0x003B
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x003C
	.short 0x00B0
	.short 0x003C
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0048
	.short 0x00B0
	.short 0x0048
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0049
	.short 0x00B1
	.short 0x0049
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x004A
	.short 0x00B0
	.short 0x004A
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0056
	.short 0x00B0
	.short 0x0056
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0057
	.short 0x00B1
	.short 0x0057
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0058
	.short 0x00B0
	.short 0x0058
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0064
	.short 0x00B0
	.short 0x0064
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0065
	.short 0x00B1
	.short 0x0065
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0066
	.short 0x00B0
	.short 0x0066
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0072
	.short 0x00B0
	.short 0x0072
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0073
	.short 0x00B1
	.short 0x0073
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0074
	.short 0x00B0
	.short 0x0074
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0080
	.short 0x00B0
	.short 0x0080
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00B1
	.short 0x0081
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00BF
	.short 0x00B0
	.short 0x00BF
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00CB
	.short 0x00B0
	.short 0x00CB
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00CC
	.short 0x00B1
	.short 0x00CC
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00B0
	.short 0x00CD
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00D9
	.short 0x00B0
	.short 0x00D9
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00DA
	.short 0x00B1
	.short 0x00DA
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00DB
	.short 0x00B0
	.short 0x00DB
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00E7
	.short 0x00B0
	.short 0x00E7
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00E8
	.short 0x00B1
	.short 0x00E8
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00E9
	.short 0x00B0
	.short 0x00E9
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00B0
	.short 0x00F5
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00F6
	.short 0x00B1
	.short 0x00F6
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00F7
	.short 0x00B0
	.short 0x00F7
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0103
	.short 0x00B0
	.short 0x0103
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0104
	.short 0x00B1
	.short 0x0104
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0105
	.short 0x00B0
	.short 0x0105
	.short 0x00BC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0111
	.short 0x00B0
	.short 0x0111
	.short 0x00BD
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0112
	.short 0x00B1
	.short 0x0112
	.short 0x00BD
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0009
	.short 0x0024
	.short 0x0135
	.short 0x006F
DL_F28DF3:
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x0083
	.short 0x009A
	.short 0x0090
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00A6
	.short 0x0083
	.short 0x0112
	.short 0x0090
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x0097
	.short 0x009A
	.short 0x00A4
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00A6
	.short 0x0097
	.short 0x0112
	.short 0x00A4
DL_F28E1B:
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F2843D
	.short 0x05F1
	.short 0x0002
	.short 0x0009
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F2843D
	.short 0x0FC9
	.short 0x0002
	.short 0x0009
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F2843D
	.short 0x0615
	.short 0x0002
	.short 0x0009
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F2843D
	.short 0x0FED
	.short 0x0002
	.short 0x0009
	.byte 0x20, 0x0B	; op 20, 11 bytes -> handler 0xF31A3A
	.short 0x0110
	.ascii "PAGE1/2"
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x24
	.short 0x183B
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x2080
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x2085
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x208A
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x208F
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x2094
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x2099
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x209E
	.short 0x0005
	.short 0x001E
	.byte 0x03, 0x0C	; op 03, 12 bytes -> handler 0xF31ABE
	.long 0x00F283A7
	.short 0x20A3
	.short 0x0005
	.short 0x001E
	.byte 0x1C, 0x16	; op 1C, 22 bytes -> handler 0xF31A52
	.short 0x0040
	.short 0x0005
	.ascii "C0MBINATI0N M0DE"
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x6F
	.short 0x002C
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00C7
	.short 0x009F
	.ascii "1"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00D5
	.short 0x009F
	.ascii "2"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00E3
	.short 0x009F
	.ascii "3"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00F1
	.short 0x009F
	.ascii "4"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00FF
	.short 0x009F
	.ascii "5"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x010D
	.short 0x009F
	.ascii "6"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x000A
	.short 0x00D4
	.ascii "OCT"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0032
	.short 0x00D4
	.ascii "VOL"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x005A
	.short 0x00D4
	.ascii "PAN"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0080
	.short 0x00D4
	.ascii "EFF1"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00A8
	.short 0x00D4
	.ascii "EFF2"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00D2
	.short 0x00D4
	.ascii "REV"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00FA
	.short 0x00D4
	.ascii "INT"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0120
	.short 0x00D4
	.ascii "PART"
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x0021
	.short 0x0138
	.short 0x0021
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x0022
	.short 0x0138
	.short 0x0022
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x0071
	.short 0x0138
	.short 0x0071
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x0072
	.short 0x0138
	.short 0x0072
	.byte 0x12, 0x0A	; op 12, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x0021
	.short 0x0006
	.short 0x0072
	.byte 0x12, 0x0A	; op 12, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x0021
	.short 0x0007
	.short 0x0072
	.byte 0x12, 0x0A	; op 12, 10 bytes -> handler 0xF31A75
	.short 0x0137
	.short 0x0021
	.short 0x0137
	.short 0x0072
	.byte 0x12, 0x0A	; op 12, 10 bytes -> handler 0xF31A75
	.short 0x0138
	.short 0x0021
	.short 0x0138
	.short 0x0072
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0009
	.short 0x007D
	.short 0x0135
	.short 0x00C2
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0021
	.short 0x0093
	.short 0x0036
	.short 0x0093
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0021
	.short 0x0094
	.short 0x0036
	.short 0x0094
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00C4
	.short 0x009C
	.short 0x00D0
	.short 0x009C
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D2
	.short 0x009C
	.short 0x00DE
	.short 0x009C
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00E0
	.short 0x009C
	.short 0x00EC
	.short 0x009C
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00EE
	.short 0x009C
	.short 0x00FA
	.short 0x009C
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00FC
	.short 0x009C
	.short 0x0108
	.short 0x009C
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x010A
	.short 0x009C
	.short 0x0116
	.short 0x009C
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x00A7
	.short 0x0036
	.short 0x00A7
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x00A8
	.short 0x0036
	.short 0x00A8
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00C4
	.short 0x00A8
	.short 0x0117
	.short 0x00A8
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00C5
	.short 0x00A9
	.short 0x00D1
	.short 0x00A9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D3
	.short 0x00A9
	.short 0x00DF
	.short 0x00A9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00E1
	.short 0x00A9
	.short 0x00ED
	.short 0x00A9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00EF
	.short 0x00A9
	.short 0x00FB
	.short 0x00A9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00FD
	.short 0x00A9
	.short 0x0109
	.short 0x00A9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x010B
	.short 0x00A9
	.short 0x0117
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0021
	.short 0x0093
	.short 0x0021
	.short 0x009A
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0022
	.short 0x0093
	.short 0x0022
	.short 0x009A
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00C4
	.short 0x009C
	.short 0x00C4
	.short 0x00A8
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00D0
	.short 0x009C
	.short 0x00D0
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x009D
	.short 0x00D1
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00D2
	.short 0x009C
	.short 0x00D2
	.short 0x00A8
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00DE
	.short 0x009C
	.short 0x00DE
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00DF
	.short 0x009D
	.short 0x00DF
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00E0
	.short 0x009C
	.short 0x00E0
	.short 0x00A8
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00EC
	.short 0x009C
	.short 0x00EC
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00ED
	.short 0x009D
	.short 0x00ED
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00EE
	.short 0x009C
	.short 0x00EE
	.short 0x00A8
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00FA
	.short 0x009C
	.short 0x00FA
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00FB
	.short 0x009D
	.short 0x00FB
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00FC
	.short 0x009C
	.short 0x00FC
	.short 0x00A8
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0108
	.short 0x009C
	.short 0x0108
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0109
	.short 0x009D
	.short 0x0109
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x010A
	.short 0x009C
	.short 0x010A
	.short 0x00A8
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x009C
	.short 0x0116
	.short 0x00A9
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0117
	.short 0x009D
	.short 0x0117
	.short 0x00A9
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0009
	.short 0x0024
	.short 0x0135
	.short 0x006F
DL_F29121:
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0036
	.short 0x008D
	.short 0x00A2
	.short 0x009A
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0036
	.short 0x00A1
	.short 0x00A2
	.short 0x00AE
DL_F29135:
	.byte 0x1C, 0x16	; op 1C, 22 bytes -> handler 0xF31A52
	.short 0x0040
	.short 0x0005
	.ascii "C0MBINATI0N M0DE"
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x6F
	.short 0x002C
	.byte 0x20, 0x0B	; op 20, 11 bytes -> handler 0xF31A3A
	.short 0x0110
	.ascii "PAGE2/2"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x0077
	.short 0x001B
	.ascii "SOUND:"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0007
	.short 0x0022
	.ascii "SOUND"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0121
	.short 0x0022
	.ascii "SOLO"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x0024
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013B
	.short 0x0024
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x000D
	.short 0x0049
	.ascii "INT"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x004B
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0010
	.short 0x005D
	.ascii "o"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x003A
	.short 0x005D
	.ascii "o"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0061
	.short 0x005D
	.ascii "o"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x008A
	.short 0x005D
	.ascii "o"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00B2
	.short 0x005D
	.ascii "o"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00DA
	.short 0x005D
	.ascii "o"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0102
	.short 0x005D
	.ascii "o"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x012A
	.short 0x005D
	.ascii "o"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x000D
	.short 0x0070
	.ascii "PAN"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x0072
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x0099
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x000D
	.short 0x009B
	.ascii "VOL"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x000B
	.short 0x00E4
	.ascii "PT1"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0033
	.short 0x00E4
	.ascii "PT2"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x005B
	.short 0x00E4
	.ascii "PT3"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0083
	.short 0x00E4
	.ascii "PT4"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00AB
	.short 0x00E4
	.ascii "PT5"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00D3
	.short 0x00E4
	.ascii "PT6"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00FB
	.short 0x00E4
	.ascii "PT7"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0123
	.short 0x00E4
	.ascii "PT8"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0046
	.short 0x0018
	.short 0x0102
	.short 0x0024
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x0020
	.short 0x0026
	.short 0x002A
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0120
	.short 0x0020
	.short 0x013A
	.short 0x002A
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x002E
	.short 0x0023
	.short 0x0042
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x002E
	.short 0x004C
	.short 0x0042
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x002E
	.short 0x0073
	.short 0x0042
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x007E
	.short 0x002E
	.short 0x009C
	.short 0x0042
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00A6
	.short 0x002E
	.short 0x00C4
	.short 0x0042
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00CE
	.short 0x002E
	.short 0x00EC
	.short 0x0042
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00F6
	.short 0x002E
	.short 0x0114
	.short 0x0042
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011E
	.short 0x002E
	.short 0x013C
	.short 0x0042
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x0047
	.short 0x0026
	.short 0x0051
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x006E
	.short 0x0026
	.short 0x0078
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x0099
	.short 0x0026
	.short 0x00A3
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0046
	.short 0x0019
	.short 0x0102
	.short 0x0019
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0046
	.short 0x0023
	.short 0x0102
	.short 0x0023
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x0038
	.short 0x0023
	.short 0x0038
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x0038
	.short 0x004C
	.short 0x0038
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x0038
	.short 0x0073
	.short 0x0038
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x007E
	.short 0x0038
	.short 0x009C
	.short 0x0038
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x00A6
	.short 0x0038
	.short 0x00C4
	.short 0x0038
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x00CE
	.short 0x0038
	.short 0x00EC
	.short 0x0038
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x00F6
	.short 0x0038
	.short 0x0114
	.short 0x0038
	.byte 0x11, 0x0A	; op 11, 10 bytes -> handler 0xF31A75
	.short 0x011E
	.short 0x0038
	.short 0x013C
	.short 0x0038
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x0055
	.short 0x001A
	.short 0x0055
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0036
	.short 0x0055
	.short 0x0044
	.short 0x0055
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x005D
	.short 0x0055
	.short 0x006B
	.short 0x0055
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0086
	.short 0x0055
	.short 0x0094
	.short 0x0055
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00AE
	.short 0x0055
	.short 0x00BC
	.short 0x0055
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D6
	.short 0x0055
	.short 0x00E4
	.short 0x0055
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00FE
	.short 0x0055
	.short 0x010C
	.short 0x0055
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0126
	.short 0x0055
	.short 0x0134
	.short 0x0055
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x005D
	.short 0x001B
	.short 0x005D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0035
	.short 0x005D
	.short 0x0045
	.short 0x005D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x005C
	.short 0x005D
	.short 0x006C
	.short 0x005D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0085
	.short 0x005D
	.short 0x0095
	.short 0x005D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00AD
	.short 0x005D
	.short 0x00BD
	.short 0x005D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D5
	.short 0x005D
	.short 0x00E5
	.short 0x005D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00FD
	.short 0x005D
	.short 0x010D
	.short 0x005D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0125
	.short 0x005D
	.short 0x0135
	.short 0x005D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x0065
	.short 0x001A
	.short 0x0065
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0036
	.short 0x0065
	.short 0x0044
	.short 0x0065
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x005D
	.short 0x0065
	.short 0x006B
	.short 0x0065
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0086
	.short 0x0065
	.short 0x0094
	.short 0x0065
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00AE
	.short 0x0065
	.short 0x00BC
	.short 0x0065
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D6
	.short 0x0065
	.short 0x00E4
	.short 0x0065
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00FE
	.short 0x0065
	.short 0x010C
	.short 0x0065
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0126
	.short 0x0065
	.short 0x0134
	.short 0x0065
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x00E1
	.short 0x0022
	.short 0x00E1
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x00E1
	.short 0x004A
	.short 0x00E1
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0056
	.short 0x00E1
	.short 0x0072
	.short 0x00E1
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007E
	.short 0x00E1
	.short 0x009A
	.short 0x00E1
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A6
	.short 0x00E1
	.short 0x00C2
	.short 0x00E1
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CE
	.short 0x00E1
	.short 0x00EA
	.short 0x00E1
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F6
	.short 0x00E1
	.short 0x0112
	.short 0x00E1
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x011E
	.short 0x00E1
	.short 0x013A
	.short 0x00E1
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x00ED
	.short 0x0022
	.short 0x00ED
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x00ED
	.short 0x004A
	.short 0x00ED
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0056
	.short 0x00ED
	.short 0x0072
	.short 0x00ED
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007E
	.short 0x00ED
	.short 0x009A
	.short 0x00ED
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A6
	.short 0x00ED
	.short 0x00C2
	.short 0x00ED
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CE
	.short 0x00ED
	.short 0x00EA
	.short 0x00ED
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F6
	.short 0x00ED
	.short 0x0112
	.short 0x00ED
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x011E
	.short 0x00ED
	.short 0x013A
	.short 0x00ED
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00E2
	.short 0x0005
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0056
	.short 0x000B
	.short 0x0064
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0013
	.short 0x0057
	.short 0x0013
	.short 0x005B
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x001B
	.short 0x0056
	.short 0x001B
	.short 0x0064
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0023
	.short 0x00E2
	.short 0x0023
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00E2
	.short 0x002D
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0035
	.short 0x0056
	.short 0x0035
	.short 0x0064
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x003D
	.short 0x0057
	.short 0x003D
	.short 0x005B
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0042
	.short 0x001B
	.short 0x0042
	.short 0x0022
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0044
	.short 0x001A
	.short 0x0044
	.short 0x0023
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0045
	.short 0x0056
	.short 0x0045
	.short 0x0064
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x004B
	.short 0x00E2
	.short 0x004B
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00E2
	.short 0x0055
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x005C
	.short 0x0056
	.short 0x005C
	.short 0x0064
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0064
	.short 0x0057
	.short 0x0064
	.short 0x005B
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x006C
	.short 0x0056
	.short 0x006C
	.short 0x0064
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0073
	.short 0x00E2
	.short 0x0073
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00E2
	.short 0x007D
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0085
	.short 0x0056
	.short 0x0085
	.short 0x0064
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x008D
	.short 0x0057
	.short 0x008D
	.short 0x005B
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0095
	.short 0x0056
	.short 0x0095
	.short 0x0064
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x009B
	.short 0x00E2
	.short 0x009B
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00E2
	.short 0x00A5
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00AD
	.short 0x0056
	.short 0x00AD
	.short 0x0064
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00B5
	.short 0x0057
	.short 0x00B5
	.short 0x005B
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00BD
	.short 0x0056
	.short 0x00BD
	.short 0x0064
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00C3
	.short 0x00E2
	.short 0x00C3
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00E2
	.short 0x00CD
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00D5
	.short 0x0056
	.short 0x00D5
	.short 0x0064
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00DD
	.short 0x0057
	.short 0x00DD
	.short 0x005B
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00E5
	.short 0x0056
	.short 0x00E5
	.short 0x0064
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00EB
	.short 0x00E2
	.short 0x00EB
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00E2
	.short 0x00F5
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00FD
	.short 0x0056
	.short 0x00FD
	.short 0x0064
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0104
	.short 0x001A
	.short 0x0104
	.short 0x0023
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0105
	.short 0x0057
	.short 0x0105
	.short 0x005B
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0106
	.short 0x001B
	.short 0x0106
	.short 0x0022
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x010D
	.short 0x0056
	.short 0x010D
	.short 0x0064
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0113
	.short 0x00E2
	.short 0x0113
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00E2
	.short 0x011D
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0125
	.short 0x0056
	.short 0x0125
	.short 0x0064
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x012D
	.short 0x0057
	.short 0x012D
	.short 0x005B
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0135
	.short 0x0056
	.short 0x0135
	.short 0x0064
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x013B
	.short 0x00E2
	.short 0x013B
	.short 0x00EC
DL_F29672:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0121
	.short 0x0021
	.short 0x0139
	.short 0x0029
DL_F2967C:
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0121
	.short 0x0021
	.short 0x0139
	.short 0x0029
DL_F29686:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x0021
	.short 0x0025
	.short 0x0029
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x0048
	.short 0x0025
	.short 0x0050
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x006F
	.short 0x0025
	.short 0x0077
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x009A
	.short 0x0025
	.short 0x00A2
DL_F296AE:
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x0021
	.short 0x0025
	.short 0x0029
DL_F296B8:
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x0048
	.short 0x0025
	.short 0x0050
DL_F296C2:
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x006F
	.short 0x0025
	.short 0x0077
DL_F296CC:
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x009A
	.short 0x0025
	.short 0x00A2

; --- 0xF296D6-0xF29764: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0296D6, 0x00008F

; ------------------------------------------------------------------
; 0xF29765-0xF2979F -- 4 display-list records, 59 bytes -- interpreter B
;   entered at: 0xF29765, 0xF29783
;   ends used:  0xF29783, 0xF297A0
; ------------------------------------------------------------------
DL_F29765:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F297A0	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0F6D	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x2642	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00002661	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0F71	; +0x0D -> IX
DL_F29783:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x76DF	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F297A0	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x000C	; +0x0D -> (0x2530)
	.short 0x0030	; +0x0F -> (0x2532)
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x000C	; +0x07 -> (0x2530)
	.short 0x003A	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count

; --- 0xF297A0-0xF29862: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0297A0, 0x0000C3

; ------------------------------------------------------------------
; 0xF29863-0xF29943 -- 16 display-list records, 225 bytes -- interpreter B
;   entered at: 0xF29863, 0xF29880, 0xF2989D, 0xF298BA, 0xF298D7, 0xF298F4, 0xF29911, 0xF2992E
;   ends used:  0xF29880, 0xF2989D, 0xF298BA, 0xF298D7, 0xF298F4, 0xF29911, 0xF2992E, 0xF29944
; ------------------------------------------------------------------
DL_F29863:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x771F	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F297A0	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0034	; +0x0D -> (0x2530)
	.short 0x0030	; +0x0F -> (0x2532)
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x0034	; +0x07 -> (0x2530)
	.short 0x003A	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
DL_F29880:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x775F	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F297A0	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x005C	; +0x0D -> (0x2530)
	.short 0x0030	; +0x0F -> (0x2532)
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x005C	; +0x07 -> (0x2530)
	.short 0x003A	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
DL_F2989D:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x779F	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F297A0	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0084	; +0x0D -> (0x2530)
	.short 0x0030	; +0x0F -> (0x2532)
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x0084	; +0x07 -> (0x2530)
	.short 0x003A	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
DL_F298BA:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x77DF	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F297A0	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x00AC	; +0x0D -> (0x2530)
	.short 0x0030	; +0x0F -> (0x2532)
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00AC	; +0x07 -> (0x2530)
	.short 0x003A	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
DL_F298D7:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x781F	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F297A0	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x00D4	; +0x0D -> (0x2530)
	.short 0x0030	; +0x0F -> (0x2532)
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00D4	; +0x07 -> (0x2530)
	.short 0x003A	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
DL_F298F4:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x785F	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F297A0	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x00FC	; +0x0D -> (0x2530)
	.short 0x0030	; +0x0F -> (0x2532)
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00FC	; +0x07 -> (0x2530)
	.short 0x003A	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
DL_F29911:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x789F	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F297A0	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0124	; +0x0D -> (0x2530)
	.short 0x0030	; +0x0F -> (0x2532)
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x0124	; +0x07 -> (0x2530)
	.short 0x003A	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
DL_F2992E:
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x76AF	; +0x02 source variable, 16-bit address
	.byte 0x20	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x1B	; +0x06 swi 7 function
	.long 0x00F29944	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x76AF	; +0x02 source variable, 16-bit address
	.byte 0x20	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F29954	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; ==================================================================
; 0xF29944-0xF29963 -- display-list OPERAND TABLES (32 bytes, 2 objects)
; ==================================================================
;
; Every object here is named by a display-list record that points at it, and
; its SIZE is proven by tiling: the objects start at the first byte of this
; gap, each extent is a whole number of entries, and the last object's
; handler-implied size ends exactly on the first byte of the next display
; list.  Reproduce with `python3 notes/prom_b_dl_operand_tables.py --exact`.
;
; ------------------------------------------------------------------
; DLTable_F29944 -- 2 entries of 8 bytes
; Referenced by: display-list record 0xF2992E
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F29944:
	.short 0x000C, 0x005E, 0x001A, 0x0064	; [0]
	.short 0x000C, 0x0056, 0x001A, 0x005C	; [1]
; ------------------------------------------------------------------
; DLTable_F29954 -- 2 entries of 8 bytes
; Referenced by: display-list record 0xF29939
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F29954:
	.short 0x000C, 0x0056, 0x001A, 0x005C	; [0]
	.short 0x000C, 0x005E, 0x001A, 0x0064	; [1]

; ------------------------------------------------------------------
; 0xF29964-0xF29979 -- 2 display-list records, 22 bytes -- interpreter B
;   entered at: 0xF29964
;   ends used:  0xF2997A
; ------------------------------------------------------------------
DL_F29964:
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x76EF	; +0x02 source variable, 16-bit address
	.byte 0x20	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x1B	; +0x06 swi 7 function
	.long 0x00F2997A	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x76EF	; +0x02 source variable, 16-bit address
	.byte 0x20	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F2998A	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; ==================================================================
; 0xF2997A-0xF29999 -- display-list OPERAND TABLES (32 bytes, 2 objects)
; ==================================================================
;
; Every object here is named by a display-list record that points at it, and
; its SIZE is proven by tiling: the objects start at the first byte of this
; gap, each extent is a whole number of entries, and the last object's
; handler-implied size ends exactly on the first byte of the next display
; list.  Reproduce with `python3 notes/prom_b_dl_operand_tables.py --exact`.
;
; ------------------------------------------------------------------
; DLTable_F2997A -- 2 entries of 8 bytes
; Referenced by: display-list record 0xF29964
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F2997A:
	.short 0x0036, 0x005E, 0x0044, 0x0064	; [0]
	.short 0x0036, 0x0056, 0x0044, 0x005C	; [1]
; ------------------------------------------------------------------
; DLTable_F2998A -- 2 entries of 8 bytes
; Referenced by: display-list record 0xF2996F
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F2998A:
	.short 0x0036, 0x0056, 0x0044, 0x005C	; [0]
	.short 0x0036, 0x005E, 0x0044, 0x0064	; [1]

; ------------------------------------------------------------------
; 0xF2999A-0xF299AF -- 2 display-list records, 22 bytes -- interpreter B
;   entered at: 0xF2999A
;   ends used:  0xF299B0
; ------------------------------------------------------------------
DL_F2999A:
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x772F	; +0x02 source variable, 16-bit address
	.byte 0x20	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x1B	; +0x06 swi 7 function
	.long 0x00F299B0	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x772F	; +0x02 source variable, 16-bit address
	.byte 0x20	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F299C0	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; ==================================================================
; 0xF299B0-0xF299CF -- display-list OPERAND TABLES (32 bytes, 2 objects)
; ==================================================================
;
; Every object here is named by a display-list record that points at it, and
; its SIZE is proven by tiling: the objects start at the first byte of this
; gap, each extent is a whole number of entries, and the last object's
; handler-implied size ends exactly on the first byte of the next display
; list.  Reproduce with `python3 notes/prom_b_dl_operand_tables.py --exact`.
;
; ------------------------------------------------------------------
; DLTable_F299B0 -- 2 entries of 8 bytes
; Referenced by: display-list record 0xF2999A
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F299B0:
	.short 0x005D, 0x005E, 0x006B, 0x0064	; [0]
	.short 0x005D, 0x0056, 0x006B, 0x005C	; [1]
; ------------------------------------------------------------------
; DLTable_F299C0 -- 2 entries of 8 bytes
; Referenced by: display-list record 0xF299A5
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F299C0:
	.short 0x005D, 0x0056, 0x006B, 0x005C	; [0]
	.short 0x005D, 0x005E, 0x006B, 0x0064	; [1]

; ------------------------------------------------------------------
; 0xF299D0-0xF299E5 -- 2 display-list records, 22 bytes -- interpreter B
;   entered at: 0xF299D0
;   ends used:  0xF299E6
; ------------------------------------------------------------------
DL_F299D0:
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x776F	; +0x02 source variable, 16-bit address
	.byte 0x20	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x1B	; +0x06 swi 7 function
	.long 0x00F299E6	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x776F	; +0x02 source variable, 16-bit address
	.byte 0x20	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F299F6	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; ==================================================================
; 0xF299E6-0xF29A05 -- display-list OPERAND TABLES (32 bytes, 2 objects)
; ==================================================================
;
; Every object here is named by a display-list record that points at it, and
; its SIZE is proven by tiling: the objects start at the first byte of this
; gap, each extent is a whole number of entries, and the last object's
; handler-implied size ends exactly on the first byte of the next display
; list.  Reproduce with `python3 notes/prom_b_dl_operand_tables.py --exact`.
;
; ------------------------------------------------------------------
; DLTable_F299E6 -- 2 entries of 8 bytes
; Referenced by: display-list record 0xF299D0
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F299E6:
	.short 0x0086, 0x005E, 0x0094, 0x0064	; [0]
	.short 0x0086, 0x0056, 0x0094, 0x005C	; [1]
; ------------------------------------------------------------------
; DLTable_F299F6 -- 2 entries of 8 bytes
; Referenced by: display-list record 0xF299DB
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F299F6:
	.short 0x0086, 0x0056, 0x0094, 0x005C	; [0]
	.short 0x0086, 0x005E, 0x0094, 0x0064	; [1]

; ------------------------------------------------------------------
; 0xF29A06-0xF29A1B -- 2 display-list records, 22 bytes -- interpreter B
;   entered at: 0xF29A06
;   ends used:  0xF29A1C
; ------------------------------------------------------------------
DL_F29A06:
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x77AF	; +0x02 source variable, 16-bit address
	.byte 0x20	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x1B	; +0x06 swi 7 function
	.long 0x00F29A1C	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x77AF	; +0x02 source variable, 16-bit address
	.byte 0x20	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F29A2C	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; ==================================================================
; 0xF29A1C-0xF29A3B -- display-list OPERAND TABLES (32 bytes, 2 objects)
; ==================================================================
;
; Every object here is named by a display-list record that points at it, and
; its SIZE is proven by tiling: the objects start at the first byte of this
; gap, each extent is a whole number of entries, and the last object's
; handler-implied size ends exactly on the first byte of the next display
; list.  Reproduce with `python3 notes/prom_b_dl_operand_tables.py --exact`.
;
; ------------------------------------------------------------------
; DLTable_F29A1C -- 2 entries of 8 bytes
; Referenced by: display-list record 0xF29A06
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F29A1C:
	.short 0x00AE, 0x005E, 0x00BC, 0x0064	; [0]
	.short 0x00AE, 0x0056, 0x00BC, 0x005C	; [1]
; ------------------------------------------------------------------
; DLTable_F29A2C -- 2 entries of 8 bytes
; Referenced by: display-list record 0xF29A11
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F29A2C:
	.short 0x00AE, 0x0056, 0x00BC, 0x005C	; [0]
	.short 0x00AE, 0x005E, 0x00BC, 0x0064	; [1]

; ------------------------------------------------------------------
; 0xF29A3C-0xF29A51 -- 2 display-list records, 22 bytes -- interpreter B
;   entered at: 0xF29A3C
;   ends used:  0xF29A52
; ------------------------------------------------------------------
DL_F29A3C:
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x77EF	; +0x02 source variable, 16-bit address
	.byte 0x20	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x1B	; +0x06 swi 7 function
	.long 0x00F29A52	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x77EF	; +0x02 source variable, 16-bit address
	.byte 0x20	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F29A62	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; ==================================================================
; 0xF29A52-0xF29A71 -- display-list OPERAND TABLES (32 bytes, 2 objects)
; ==================================================================
;
; Every object here is named by a display-list record that points at it, and
; its SIZE is proven by tiling: the objects start at the first byte of this
; gap, each extent is a whole number of entries, and the last object's
; handler-implied size ends exactly on the first byte of the next display
; list.  Reproduce with `python3 notes/prom_b_dl_operand_tables.py --exact`.
;
; ------------------------------------------------------------------
; DLTable_F29A52 -- 2 entries of 8 bytes
; Referenced by: display-list record 0xF29A3C
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F29A52:
	.short 0x00D6, 0x005E, 0x00E4, 0x0064	; [0]
	.short 0x00D6, 0x0056, 0x00E4, 0x005C	; [1]
; ------------------------------------------------------------------
; DLTable_F29A62 -- 2 entries of 8 bytes
; Referenced by: display-list record 0xF29A47
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F29A62:
	.short 0x00D6, 0x0056, 0x00E4, 0x005C	; [0]
	.short 0x00D6, 0x005E, 0x00E4, 0x0064	; [1]

; ------------------------------------------------------------------
; 0xF29A72-0xF29A87 -- 2 display-list records, 22 bytes -- interpreter B
;   entered at: 0xF29A72
;   ends used:  0xF29A88
; ------------------------------------------------------------------
DL_F29A72:
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x782F	; +0x02 source variable, 16-bit address
	.byte 0x20	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x1B	; +0x06 swi 7 function
	.long 0x00F29A88	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x782F	; +0x02 source variable, 16-bit address
	.byte 0x20	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F29A98	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; ==================================================================
; 0xF29A88-0xF29AA7 -- display-list OPERAND TABLES (32 bytes, 2 objects)
; ==================================================================
;
; Every object here is named by a display-list record that points at it, and
; its SIZE is proven by tiling: the objects start at the first byte of this
; gap, each extent is a whole number of entries, and the last object's
; handler-implied size ends exactly on the first byte of the next display
; list.  Reproduce with `python3 notes/prom_b_dl_operand_tables.py --exact`.
;
; ------------------------------------------------------------------
; DLTable_F29A88 -- 2 entries of 8 bytes
; Referenced by: display-list record 0xF29A72
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F29A88:
	.short 0x00FE, 0x005E, 0x010C, 0x0064	; [0]
	.short 0x00FE, 0x0056, 0x010C, 0x005C	; [1]
; ------------------------------------------------------------------
; DLTable_F29A98 -- 2 entries of 8 bytes
; Referenced by: display-list record 0xF29A7D
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F29A98:
	.short 0x00FE, 0x0056, 0x010C, 0x005C	; [0]
	.short 0x00FE, 0x005E, 0x010C, 0x0064	; [1]

; ------------------------------------------------------------------
; 0xF29AA8-0xF29ABD -- 2 display-list records, 22 bytes -- interpreter B
;   entered at: 0xF29AA8
;   ends used:  0xF29ABE
; ------------------------------------------------------------------
DL_F29AA8:
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x786F	; +0x02 source variable, 16-bit address
	.byte 0x20	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x1B	; +0x06 swi 7 function
	.long 0x00F29ABE	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x786F	; +0x02 source variable, 16-bit address
	.byte 0x20	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F29ACE	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; ==================================================================
; 0xF29ABE-0xF29ADD -- display-list OPERAND TABLES (32 bytes, 2 objects)
; ==================================================================
;
; Every object here is named by a display-list record that points at it, and
; its SIZE is proven by tiling: the objects start at the first byte of this
; gap, each extent is a whole number of entries, and the last object's
; handler-implied size ends exactly on the first byte of the next display
; list.  Reproduce with `python3 notes/prom_b_dl_operand_tables.py --exact`.
;
; ------------------------------------------------------------------
; DLTable_F29ABE -- 2 entries of 8 bytes
; Referenced by: display-list record 0xF29AA8
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F29ABE:
	.short 0x0126, 0x005E, 0x0134, 0x0064	; [0]
	.short 0x0126, 0x0056, 0x0134, 0x005C	; [1]
; ------------------------------------------------------------------
; DLTable_F29ACE -- 2 entries of 8 bytes
; Referenced by: display-list record 0xF29AB3
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           2 entries is the EXTENT (16 bytes / 8), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F29ACE:
	.short 0x0126, 0x0056, 0x0134, 0x005C	; [0]
	.short 0x0126, 0x005E, 0x0134, 0x0064	; [1]

; ------------------------------------------------------------------
; 0xF29ADE-0xF29BC5 -- 16 display-list records, 232 bytes -- interpreter B
;   entered at: 0xF29ADE, 0xF29AEF, 0xF29B00, 0xF29B11, 0xF29B22, 0xF29B33, 0xF29B44, 0xF29B55, 0xF29B66, 0xF29B72, 0xF29B7E, 0xF29B8A, 0xF29B96, 0xF29BA2, 0xF29BAE, 0xF29BBA
;   ends used:  0xF29AEF, 0xF29B00, 0xF29B11, 0xF29B22, 0xF29B33, 0xF29B44, 0xF29B55, 0xF29B66, 0xF29B72, 0xF29B7E, 0xF29B8A, 0xF29B96, 0xF29BA2, 0xF29BAE, 0xF29BBA, 0xF29BC6
; ------------------------------------------------------------------
DL_F29ADE:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x76AA	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F28522	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x000A	; +0x0D -> (0x2530)
	.short 0x007B	; +0x0F -> (0x2532)
DL_F29AEF:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x76EA	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F28522	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0032	; +0x0D -> (0x2530)
	.short 0x007B	; +0x0F -> (0x2532)
DL_F29B00:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x772A	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F28522	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x005A	; +0x0D -> (0x2530)
	.short 0x007B	; +0x0F -> (0x2532)
DL_F29B11:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x776A	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F28522	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0082	; +0x0D -> (0x2530)
	.short 0x007B	; +0x0F -> (0x2532)
DL_F29B22:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x77AA	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F28522	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x00AA	; +0x0D -> (0x2530)
	.short 0x007B	; +0x0F -> (0x2532)
DL_F29B33:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x77EA	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F28522	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x00D2	; +0x0D -> (0x2530)
	.short 0x007B	; +0x0F -> (0x2532)
DL_F29B44:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x782A	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F28522	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x00FA	; +0x0D -> (0x2530)
	.short 0x007B	; +0x0F -> (0x2532)
DL_F29B55:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x786A	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F28522	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0122	; +0x0D -> (0x2530)
	.short 0x007B	; +0x0F -> (0x2532)
DL_F29B66:
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x76A5	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x000A	; +0x07 -> (0x2530)
	.short 0x00A7	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
DL_F29B72:
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x76E5	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x0032	; +0x07 -> (0x2530)
	.short 0x00A7	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
DL_F29B7E:
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x7725	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x005A	; +0x07 -> (0x2530)
	.short 0x00A7	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
DL_F29B8A:
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x7765	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x0082	; +0x07 -> (0x2530)
	.short 0x00A7	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
DL_F29B96:
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x77A5	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00AA	; +0x07 -> (0x2530)
	.short 0x00A7	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
DL_F29BA2:
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x77E5	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00D2	; +0x07 -> (0x2530)
	.short 0x00A7	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
DL_F29BAE:
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x7825	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00FA	; +0x07 -> (0x2530)
	.short 0x00A7	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
DL_F29BBA:
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x7865	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x0122	; +0x07 -> (0x2530)
	.short 0x00A7	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count

; --- 0xF29BC6-0xF2ADD1: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x029BC6, 0x00120C

; ------------------------------------------------------------------
; 0xF2ADD2-0xF2AF80 -- 48 display-list records, 431 bytes -- interpreter A
;   entered at: 0xF2ADD2
;   ends used:  0xF2AF81
; ------------------------------------------------------------------
DL_F2ADD2:
	.byte 0x1C, 0x1C	; op 1C, 28 bytes -> handler 0xF31A52
	.short 0x0035
	.short 0x0005
	.ascii "COMBINATION GROUP MENU"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x05A1
	.ascii "1."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x05B5
	.ascii "9."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x08C1
	.ascii "2."
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x08D4
	.ascii "10."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x0BE1
	.ascii "3."
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x0BF4
	.ascii "11."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x0F01
	.ascii "4."
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x0F14
	.ascii "12."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1221
	.ascii "5."
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x1234
	.ascii "13."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1541
	.ascii "6."
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x1554
	.ascii "14."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1861
	.ascii "7."
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x1874
	.ascii "15."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1B81
	.ascii "8."
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x1B94
	.ascii "16."
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x0009
	.short 0x00C9
	.ascii "RE-MAP1"
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x0041
	.short 0x00C9
	.ascii "RE-MAP2"
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x0079
	.short 0x00C9
	.ascii "RE-MAP3"
	.byte 0x08, 0x05	; op 08, 5 bytes -> handler 0xF31A3A
	.short 0x2096
	.byte 0x8D	; character codes below 0x20
	.byte 0x08, 0x05	; op 08, 5 bytes -> handler 0xF31A3A
	.short 0x22C6
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x236B
	.ascii "OK"
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x25
	.short 0x0003
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0002
	.short 0x001A
	.short 0x013D
	.short 0x00C6
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0003
	.short 0x001B
	.short 0x013C
	.short 0x00C5
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x00D2
	.short 0x0035
	.short 0x00D2
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x003F
	.short 0x00D2
	.short 0x006D
	.short 0x00D2
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0077
	.short 0x00D2
	.short 0x00A5
	.short 0x00D2
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00D3
	.short 0x00C6
	.short 0x00D3
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00E0
	.short 0x00C6
	.short 0x00E0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00ED
	.short 0x00C6
	.short 0x00ED
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D2
	.short 0x00E0
	.short 0x00ED
	.short 0x00E0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D2
	.short 0x00ED
	.short 0x00ED
	.short 0x00ED
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x00C8
	.short 0x0006
	.short 0x00D1
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0036
	.short 0x00C8
	.short 0x0036
	.short 0x00D1
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x003E
	.short 0x00C8
	.short 0x003E
	.short 0x00D1
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x006E
	.short 0x00C8
	.short 0x006E
	.short 0x00D1
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0076
	.short 0x00C8
	.short 0x0076
	.short 0x00D1
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A6
	.short 0x00C8
	.short 0x00A6
	.short 0x00D1
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A8
	.short 0x00E1
	.short 0x00A8
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x009E
	.short 0x001A
	.short 0x009E
	.short 0x00C6
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A8
	.short 0x00D4
	.short 0x00A8
	.short 0x00DF
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A8
	.short 0x00E1
	.short 0x00A8
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00C7
	.short 0x00D4
	.short 0x00C7
	.short 0x00DF
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00C7
	.short 0x00E1
	.short 0x00C7
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00E1
	.short 0x00D1
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00EE
	.short 0x00E1
	.short 0x00EE
	.short 0x00EC

; --- 0xF2AF81-0xF2B12F: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x02AF81, 0x0001AF

; ------------------------------------------------------------------
; 0xF2B130-0xF2B2E2 -- 50 display-list records, 435 bytes -- interpreter A
;   entered at: 0xF2B130
;   ends used:  0xF2B2E3
; ------------------------------------------------------------------
DL_F2B130:
	.byte 0x1C, 0x0B	; op 1C, 11 bytes -> handler 0xF31A52
	.short 0x0055
	.short 0x0005
	.ascii "SOUND"
	.byte 0x1C, 0x0B	; op 1C, 11 bytes -> handler 0xF31A52
	.short 0x0097
	.short 0x0005
	.ascii "GROUP"
	.byte 0x1C, 0x0A	; op 1C, 10 bytes -> handler 0xF31A52
	.short 0x00D9
	.short 0x0005
	.ascii "MENU"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x05A1
	.ascii "1."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x05B5
	.ascii "9."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x08C1
	.ascii "2."
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x08D4
	.ascii "10."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x0BE1
	.ascii "3."
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x0BF4
	.ascii "11."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x0F01
	.ascii "4."
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x0F14
	.ascii "12."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1221
	.ascii "5."
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x1234
	.ascii "13."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1541
	.ascii "6."
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x1554
	.ascii "14."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1861
	.ascii "7."
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x1874
	.ascii "15."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1B81
	.ascii "8."
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x1B94
	.ascii "16."
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x0009
	.short 0x00C9
	.ascii "RE-MAP1"
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x0041
	.short 0x00C9
	.ascii "RE-MAP2"
	.byte 0x17, 0x0D	; op 17, 13 bytes -> handler 0xF31A52
	.short 0x0079
	.short 0x00C9
	.ascii "RE-MAP3"
	.byte 0x08, 0x05	; op 08, 5 bytes -> handler 0xF31A3A
	.short 0x2096
	.byte 0x8D	; character codes below 0x20
	.byte 0x08, 0x05	; op 08, 5 bytes -> handler 0xF31A3A
	.short 0x22C6
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x236B
	.ascii "OK"
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x25
	.short 0x0007
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0002
	.short 0x001A
	.short 0x013D
	.short 0x00C6
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0003
	.short 0x001B
	.short 0x013C
	.short 0x00C5
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x00D2
	.short 0x0035
	.short 0x00D2
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x003F
	.short 0x00D2
	.short 0x006D
	.short 0x00D2
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0077
	.short 0x00D2
	.short 0x00A5
	.short 0x00D2
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00D3
	.short 0x00C6
	.short 0x00D3
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00E0
	.short 0x00C6
	.short 0x00E0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00ED
	.short 0x00C6
	.short 0x00ED
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D2
	.short 0x00E0
	.short 0x00ED
	.short 0x00E0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D2
	.short 0x00ED
	.short 0x00ED
	.short 0x00ED
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x00C8
	.short 0x0006
	.short 0x00D1
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0036
	.short 0x00C8
	.short 0x0036
	.short 0x00D1
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x003E
	.short 0x00C8
	.short 0x003E
	.short 0x00D1
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x006E
	.short 0x00C8
	.short 0x006E
	.short 0x00D1
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0076
	.short 0x00C8
	.short 0x0076
	.short 0x00D1
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A6
	.short 0x00C8
	.short 0x00A6
	.short 0x00D1
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A8
	.short 0x00E1
	.short 0x00A8
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x009E
	.short 0x001A
	.short 0x009E
	.short 0x00C6
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A8
	.short 0x00D4
	.short 0x00A8
	.short 0x00DF
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A8
	.short 0x00E1
	.short 0x00A8
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00C7
	.short 0x00D4
	.short 0x00C7
	.short 0x00DF
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00C7
	.short 0x00E1
	.short 0x00C7
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00E1
	.short 0x00D1
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00EE
	.short 0x00E1
	.short 0x00EE
	.short 0x00EC

; --- 0xF2B2E3-0xF2B378: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x02B2E3, 0x000096

; ------------------------------------------------------------------
; 0xF2B379-0xF2B38E -- 2 display-list records, 22 bytes -- interpreter B
;   entered at: 0xF2B379
;   ends used:  0xF2B38F
; ------------------------------------------------------------------
DL_F2B379:
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x2674	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1B	; +0x06 swi 7 function
	.long 0x00F2B38F	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x216A	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F2B38F	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF2B38F-0xF2B573: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x02B38F, 0x0001E5

; ------------------------------------------------------------------
; 0xF2B574-0xF2B8F8 -- 98 display-list records, 901 bytes -- interpreter A
;   entered at: 0xF2B574, 0xF2B736
;   ends used:  0xF2B736, 0xF2B8F9
; ------------------------------------------------------------------
DL_F2B574:
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x010D
	.short 0x000A
	.ascii "GROUP:"
	.byte 0x1C, 0x0B	; op 1C, 11 bytes -> handler 0xF31A52
	.short 0x0021
	.short 0x0005
	.ascii "SOUND"
	.byte 0x06, 0x0B	; op 06, 11 bytes -> handler 0xF31A3A
	.short 0x2190
	.ascii "DISPLAY"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x2371
	.ascii "HOLD"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x1EDF
	.ascii "GR0UP"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x227A
	.ascii "MENU"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x0026
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013A
	.short 0x0026
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x004D
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013A
	.short 0x004D
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x0074
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013A
	.short 0x0074
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x009B
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013A
	.short 0x009B
	.byte 0x11	; character codes below 0x20
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x13
	.short 0x0029
	.byte 0x08, 0x05	; op 08, 5 bytes -> handler 0xF31A3A
	.short 0x2096
	.byte 0x8D	; character codes below 0x20
	.byte 0x08, 0x05	; op 08, 5 bytes -> handler 0xF31A3A
	.short 0x22C6
	.byte 0x8E	; character codes below 0x20
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A8
	.short 0x00D3
	.short 0x00C6
	.short 0x00D3
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A8
	.short 0x00E0
	.short 0x00C6
	.short 0x00E0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A8
	.short 0x00ED
	.short 0x00C6
	.short 0x00ED
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x005B
	.short 0x0002
	.short 0x010B
	.short 0x0002
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x005B
	.short 0x0015
	.short 0x010B
	.short 0x0015
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x001A
	.short 0x0134
	.short 0x001A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x001B
	.short 0x0134
	.short 0x001B
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x00B5
	.short 0x0134
	.short 0x00B5
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x00B6
	.short 0x0134
	.short 0x00B6
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00FE
	.short 0x00D3
	.short 0x0139
	.short 0x00D3
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00FE
	.short 0x00ED
	.short 0x0139
	.short 0x00ED
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x001A
	.short 0x000B
	.short 0x00B6
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x001A
	.short 0x000C
	.short 0x00B6
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x005A
	.short 0x0003
	.short 0x005A
	.short 0x0014
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x009E
	.short 0x001A
	.short 0x009E
	.short 0x00B6
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00FD
	.short 0x00D4
	.short 0x00FD
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x013A
	.short 0x00D4
	.short 0x013A
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x010C
	.short 0x0003
	.short 0x010C
	.short 0x0014
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0133
	.short 0x001A
	.short 0x0133
	.short 0x00B6
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0134
	.short 0x001A
	.short 0x0134
	.short 0x00B6
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A6
	.short 0x00C9
	.short 0x00B1
	.short 0x00C9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00E4
	.short 0x00C9
	.short 0x00F3
	.short 0x00C9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CF
	.short 0x00D3
	.short 0x00F1
	.short 0x00D3
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CF
	.short 0x00ED
	.short 0x00F1
	.short 0x00ED
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A6
	.short 0x00C9
	.short 0x00A6
	.short 0x00CE
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A7
	.short 0x00D4
	.short 0x00A7
	.short 0x00DF
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A7
	.short 0x00E1
	.short 0x00A7
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00C7
	.short 0x00D4
	.short 0x00C7
	.short 0x00DF
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00C7
	.short 0x00E1
	.short 0x00C7
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00CE
	.short 0x00D4
	.short 0x00CE
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00F2
	.short 0x00D4
	.short 0x00F2
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00F3
	.short 0x00C9
	.short 0x00F3
	.short 0x00CE
DL_F2B736:
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x010D
	.short 0x000A
	.ascii "GROUP:"
	.byte 0x1C, 0x0C	; op 1C, 12 bytes -> handler 0xF31A52
	.short 0x001C
	.short 0x0005
	.ascii "COMBI."
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x0026
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013A
	.short 0x0026
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x004D
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013A
	.short 0x004D
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x0074
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013A
	.short 0x0074
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x009B
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013A
	.short 0x009B
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x0B	; op 06, 11 bytes -> handler 0xF31A3A
	.short 0x2190
	.ascii "DISPLAY"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x2371
	.ascii "HOLD"
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x27
	.short 0x0028
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x1EDF
	.ascii "GR0UP"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x227A
	.ascii "MENU"
	.byte 0x08, 0x05	; op 08, 5 bytes -> handler 0xF31A3A
	.short 0x2096
	.byte 0x8D	; character codes below 0x20
	.byte 0x08, 0x05	; op 08, 5 bytes -> handler 0xF31A3A
	.short 0x22C6
	.byte 0x8E	; character codes below 0x20
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A8
	.short 0x00D3
	.short 0x00C6
	.short 0x00D3
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A8
	.short 0x00E0
	.short 0x00C6
	.short 0x00E0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A8
	.short 0x00ED
	.short 0x00C6
	.short 0x00ED
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x005B
	.short 0x0002
	.short 0x010B
	.short 0x0002
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x005B
	.short 0x0015
	.short 0x010B
	.short 0x0015
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x001A
	.short 0x0134
	.short 0x001A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x001B
	.short 0x0134
	.short 0x001B
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x00B5
	.short 0x0134
	.short 0x00B5
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x00B6
	.short 0x0134
	.short 0x00B6
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00FE
	.short 0x00D3
	.short 0x0139
	.short 0x00D3
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00FE
	.short 0x00ED
	.short 0x0139
	.short 0x00ED
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x001A
	.short 0x000B
	.short 0x00B6
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x001A
	.short 0x000C
	.short 0x00B6
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x005A
	.short 0x0003
	.short 0x005A
	.short 0x0014
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x009E
	.short 0x001A
	.short 0x009E
	.short 0x00B6
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00FD
	.short 0x00D4
	.short 0x00FD
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x013A
	.short 0x00D4
	.short 0x013A
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x010C
	.short 0x0003
	.short 0x010C
	.short 0x0014
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0133
	.short 0x001A
	.short 0x0133
	.short 0x00B6
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0134
	.short 0x001A
	.short 0x0134
	.short 0x00B6
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A6
	.short 0x00C9
	.short 0x00B1
	.short 0x00C9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00E4
	.short 0x00C9
	.short 0x00F3
	.short 0x00C9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CF
	.short 0x00D3
	.short 0x00F1
	.short 0x00D3
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CF
	.short 0x00ED
	.short 0x00F1
	.short 0x00ED
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A6
	.short 0x00C9
	.short 0x00A6
	.short 0x00CE
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A7
	.short 0x00D4
	.short 0x00A7
	.short 0x00DF
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A7
	.short 0x00E1
	.short 0x00A7
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00C7
	.short 0x00D4
	.short 0x00C7
	.short 0x00DF
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00C7
	.short 0x00E1
	.short 0x00C7
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00CE
	.short 0x00D4
	.short 0x00CE
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00F2
	.short 0x00D4
	.short 0x00F2
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00F3
	.short 0x00C9
	.short 0x00F3
	.short 0x00CE

; --- 0xF2B8F9-0xF2BA0B: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x02B8F9, 0x000113

; ------------------------------------------------------------------
; 0xF2BA0C-0xF2BB0C -- 26 display-list records, 257 bytes -- interpreter A (25 records) and B (1)
;   entered at: 0xF2BA0C, 0xF2BA16, 0xF2BA20, 0xF2BA50, 0xF2BA5A, 0xF2BA64, 0xF2BA73, 0xF2BB03
;   ends used:  0xF2BA16, 0xF2BA20, 0xF2BA50, 0xF2BA5A, 0xF2BA64, 0xF2BA73, 0xF2BAD3, 0xF2BB03, 0xF2BB0D
; ------------------------------------------------------------------
DL_F2BA0C:
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x00FE
	.short 0x00D4
	.short 0x0139
	.short 0x00EC
DL_F2BA16:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x00FE
	.short 0x00D4
	.short 0x0139
	.short 0x00EC
DL_F2BA20:
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x235B
	.ascii "DRUM"
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0057
	.short 0x00E0
	.short 0x0079
	.short 0x00E0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0057
	.short 0x00ED
	.short 0x0079
	.short 0x00ED
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0056
	.short 0x00E1
	.short 0x0056
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x007A
	.short 0x00E1
	.short 0x007A
	.short 0x00EC
DL_F2BA50:
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0057
	.short 0x00E1
	.short 0x0079
	.short 0x00EC
DL_F2BA5A:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0057
	.short 0x00E1
	.short 0x0079
	.short 0x00EC
DL_F2BA64:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00002661	; +0x07 -> XIY: string table
	.short 0x0002	; +0x0B -> BC: bytes per entry
	.short 0x0166	; +0x0D -> IX
DL_F2BA73:
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x2351
	.ascii "R0M1"
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x00E0
	.short 0x0029
	.short 0x00E0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x00ED
	.short 0x0029
	.short 0x00ED
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x00E1
	.short 0x0006
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x002A
	.short 0x00E1
	.short 0x002A
	.short 0x00EC
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x2360
	.ascii "EXT1"
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007F
	.short 0x00E0
	.short 0x00A1
	.short 0x00E0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007F
	.short 0x00ED
	.short 0x00A1
	.short 0x00ED
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x007E
	.short 0x00E1
	.short 0x007E
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A2
	.short 0x00E1
	.short 0x00A2
	.short 0x00EC
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x2356
	.ascii "R0M2"
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x00E0
	.short 0x0051
	.short 0x00E0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x00ED
	.short 0x0051
	.short 0x00ED
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x00E1
	.short 0x002E
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0052
	.short 0x00E1
	.short 0x0052
	.short 0x00EC
DL_F2BB03:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x00E0
	.short 0x00A2
	.short 0x00ED

; --- 0xF2BB0D-0xF2BD17: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x02BB0D, 0x00020B

; ------------------------------------------------------------------
; 0xF2BD18-0xF2BE34 -- 30 display-list records, 285 bytes -- interpreter A (28 records) and B (2)
;   entered at: 0xF2BD18, 0xF2BD48, 0xF2BD52, 0xF2BD66, 0xF2BD96, 0xF2BDA0, 0xF2BDB4, 0xF2BDC3, 0xF2BDD2, 0xF2BDF5
;   ends used:  0xF2BD48, 0xF2BD52, 0xF2BD66, 0xF2BD96, 0xF2BDA0, 0xF2BDB4, 0xF2BDC3, 0xF2BDD2, 0xF2BDF5, 0xF2BE35
; ------------------------------------------------------------------
DL_F2BD18:
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x2351
	.ascii "USR1"
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x00E0
	.short 0x0029
	.short 0x00E0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x00ED
	.short 0x0029
	.short 0x00ED
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x00E1
	.short 0x0006
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x002A
	.short 0x00E1
	.short 0x002A
	.short 0x00EC
DL_F2BD48:
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x00E1
	.short 0x0029
	.short 0x00EC
DL_F2BD52:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0007
	.short 0x00E1
	.short 0x0029
	.short 0x00EC
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x007F
	.short 0x00E1
	.short 0x00A1
	.short 0x00EC
DL_F2BD66:
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x2356
	.ascii "USR2"
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x00E0
	.short 0x0051
	.short 0x00E0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x00ED
	.short 0x0051
	.short 0x00ED
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x00E1
	.short 0x002E
	.short 0x00EC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0052
	.short 0x00E1
	.short 0x0052
	.short 0x00EC
DL_F2BD96:
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x00E1
	.short 0x0051
	.short 0x00EC
DL_F2BDA0:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x002F
	.short 0x00E1
	.short 0x0051
	.short 0x00EC
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x007F
	.short 0x00E1
	.short 0x00A1
	.short 0x00EC
DL_F2BDB4:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x2642	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00002661	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1D12	; +0x0D -> IX
DL_F2BDC3:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x2642	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00002661	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1D16	; +0x0D -> IX
DL_F2BDD2:
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1D15
	.ascii "-"
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x00C6
	.short 0x004C
	.short 0x00C6
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x00B7
	.short 0x000B
	.short 0x00C5
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x004D
	.short 0x00B7
	.short 0x004D
	.short 0x00C5
DL_F2BDF5:
	.byte 0x0E, 0x08	; op 0E, 8 bytes -> handler 0xF31A9F
	.short 0x05A3
	.short 0x0010
	.short 0x000E
	.byte 0x0E, 0x08	; op 0E, 8 bytes -> handler 0xF31A9F
	.short 0x0BBB
	.short 0x0010
	.short 0x000E
	.byte 0x0E, 0x08	; op 0E, 8 bytes -> handler 0xF31A9F
	.short 0x11D3
	.short 0x0010
	.short 0x000E
	.byte 0x0E, 0x08	; op 0E, 8 bytes -> handler 0xF31A9F
	.short 0x17EB
	.short 0x0010
	.short 0x000E
	.byte 0x0E, 0x08	; op 0E, 8 bytes -> handler 0xF31A9F
	.short 0x05B5
	.short 0x0010
	.short 0x000E
	.byte 0x0E, 0x08	; op 0E, 8 bytes -> handler 0xF31A9F
	.short 0x0BCD
	.short 0x0010
	.short 0x000E
	.byte 0x0E, 0x08	; op 0E, 8 bytes -> handler 0xF31A9F
	.short 0x11E5
	.short 0x0010
	.short 0x000E
	.byte 0x0E, 0x08	; op 0E, 8 bytes -> handler 0xF31A9F
	.short 0x17FD
	.short 0x0010
	.short 0x000E

; --- 0xF2BE35-0xF317FF: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x02BE35, 0x0059CB

; ==============================================================================
; 0xF31800-0xF32708 -- the UI DISPLAY-LIST INTERPRETER, and the data it owns
; ==============================================================================
;
; This block is the machine's screen-drawing engine.  Everything the WSA1 puts
; on its LCD -- "SOUND EDIT", "TONE LAYER", "DSP EFFECT", "CONTROLLER",
; "AMPLITUDE" and ~4,000 other records -- is a byte-coded DISPLAY LIST that the
; loop at 0xF31A09 walks.  The lists themselves are data elsewhere in this image
; (129 spans, 39,329 bytes, all converted below/above this block); this is the
; code that executes them.
;
; RECORD FORMAT
;       +0  opcode, bounds-checked against 0x24
;       +1  length of the WHOLE record in bytes -- the loop advances by it
;       +2  operands, and for the text opcodes a run of characters
;
; DISPATCH.  opcode -> 0xF31D21[opcode] -> a small handler that marshals the
; record's operands into registers and issues `swi 7`.  The opcode IS the swi
; function number (handler 0xF31A3A: `ld A,(XIY)` then `swi 7`).
;
; `swi 7` IS THE SYSTEM CALL.  Its vector (prom_a 0xFFFF1C) is 0x00F400A4, i.e.
; the thunk T_F400A4 in this image, which jumps to prom_a 0xF8E9A5.  That
; routine masks A with 0x3F, scales by 4 and indexes a 64-entry table at
; prom_a 0xF8E9C6.  Entries 0x00-0x22 span 35 slots, but slot 0x18 also points at the
; shared ret stub 0xF8EAC6, so there are 34 LIVE services and the first dead slot is
; 0x18, not 0x23 (corrected 2026-08-24).  Entries
; 0x23-0x3F are all 0xF8EAC6, which is a single 0x0E = `ret`.  So the service
; has 35 live functions numbered 0x00-0x22 -- and the display-list bound 0x24
; is exactly one past the last of them.  Three independent numbers agreeing
; ⚠ CORRECTED 2026-08-24.  Of the three numbers this paragraph called independent,
; TWO hold: the 0x24 bound and the 36-entry handler table, both read directly off
; `cp L,0x24` at 0xF31A0F.  The third (0x23 = first dead service slot) is wrong --
; 0x18 is.  The 'zero exceptions' leg, also disputed that day, HOLDS after all:
; the 341 apparent violations are interpreter-B records that had been measured
; against interpreter A's layout, and judged by the interpreter that runs them
; the exception count is zero on both sides (3,603 A records, 494 B records).
; See notes/FINDINGS-ui-display-list-interpreter-b.md and reproduce with
; `python3 notes/prom_b_dl_length_audit.py --edges`.
; The DECODE stands; the licence to call it fact rather than a reading does not.
;
; SERVICE FUNCTIONS IDENTIFIED SO FAR, and how:
;   fn 0x03  draw bitmap.  IX = position, BC = width in BYTES, HL = height in
;            rows, XIY = bitmap.  Evidence: three call sites in this block
;            whose BC x HL is EXACTLY the size of the contiguous data block at
;            XIY -- 1x16 at 0xF318EE, 1x16 at 0xF318FE, 5x15 = 75 at 0xF31952,
;            and the three blocks abut with no slack.
;   fn 0x06  draw characters.  XIY = character table, HL = index, BC = count.
;            Evidence: 0xF319A2 passes the ASCII table at 0xF319E9 with HL = a
;            nibble and BC = 1.
;   fn 0x05  takes the four 16-bit words at (0x2530),(0x2532),(0x2534),(0x2536),
;            which callers set immediately before the call.  What they mean is
;            NOT established; a rectangle is the obvious reading and is NOT
;            asserted here.
;   fn 0x0C, 0x10 exist and take C; nothing further is established.
;
; STATE.  (0x2530),(0x2532),(0x2534),(0x2536) are 16-bit parameter words shared
; with the service; (0x2540) is a byte several routines save and restore across
; a service call.  Which memory these are in is not resolved in
; notes/FINDINGS-memory-map.md, so no name is invented for them here.
;
; ⚠ ELEVEN INSTRUCTIONS BELOW ARE `.byte`.  They are not padding and not
; unknown: each is an instruction MAME decodes but this LLVM TLCS-900 backend
; cannot encode -- `(rr+r)` indexed loads, the variable shift `srl A,r`, and
; `cp (mem),imm8`.  The MAME mnemonic is kept in the comment.  Produced and
; PROVEN byte-for-byte by scripts/analysis/llvm_roundtrip.py.
;

; ---------------------------------------------------------------------
; DisplayList_Run_Stack -- run a display list, arguments on the stack
;
; Called from: through the thunk table; not yet traced to a specific caller
; Inputs:  (XIZ+8) = list start, (XIZ+0x0C) = list end (both 32-bit)
; Outputs: draws; clobbers nothing the caller can see (XIX/XHL/XDE saved)
; Notes:   a plain stack-frame wrapper around DisplayList_Run at 0xF31A09.
;          The register-passing form is the one everything else calls.
; ---------------------------------------------------------------------
DisplayList_Run_Stack:
	push	xiz	; F31800  push XIZ
	ld	xiz, xsp	; F31801  ld XIZ,XSP
	push	xix	; F31803  push XIX
	push	xhl	; F31804  push XHL
	push	xde	; F31805  push XDE
	ld	xiy, (xiz+8)	; F31806  ld XIY,(XIZ+0x08)
	ld	xix, (xiz+12)	; F31809  ld XIX,(XIZ+0x0c)
	calr	506	; F3180C  calr 0xf31a09
	pop	xde	; F3180F  pop XDE
	pop	xhl	; F31810  pop XHL
	pop	xix	; F31811  pop XIX
	pop	xiz	; F31812  pop XIZ
	ret	; F31813  ret

; ---------------------------------------------------------------------
; DisplayListB_Run_Stack -- same, for the SECOND interpreter
;
; Inputs:  (XIZ+8) = list start, (XIZ+0x0C) = list end
; Notes:   wraps DisplayListB_Run at 0xF31AF0, whose opcode bound is 0x0F and
;          whose handler table is at 0xF31DB1.  The two interpreters share the
;          record shape (opcode, length) but not the opcode space.
; ---------------------------------------------------------------------
DisplayListB_Run_Stack:
	push	xiz	; F31814  push XIZ
	ld	xiz, xsp	; F31815  ld XIZ,XSP
	push	xix	; F31817  push XIX
	push	xhl	; F31818  push XHL
	push	xde	; F31819  push XDE
	ld	xiy, (xiz+8)	; F3181A  ld XIY,(XIZ+0x08)
	ld	xix, (xiz+12)	; F3181D  ld XIX,(XIZ+0x0c)
	calr	717	; F31820  calr 0xf31af0
	pop	xde	; F31823  pop XDE
	pop	xhl	; F31824  pop XHL
	pop	xix	; F31825  pop XIX
	pop	xiz	; F31826  pop XIZ
	ret	; F31827  ret

; ---------------------------------------------------------------------
; DisplayList_RunOne_Stack -- run exactly ONE record, argument on the stack
;
; Inputs:  (XIZ+8) = pointer to the record
; Notes:   sets the end pointer to start+1, so the loop executes one record and
;          stops.  Same trick as DisplayListB_RunOne at 0xF31AEC.
; ---------------------------------------------------------------------
DisplayList_RunOne_Stack:
	push	xiz	; F31828  push XIZ
	ld	xiz, xsp	; F31829  ld XIZ,XSP
	push	xix	; F3182B  push XIX
	push	xhl	; F3182C  push XHL
	push	xde	; F3182D  push XDE
	ld	xiy, (xiz+8)	; F3182E  ld XIY,(XIZ+0x08)
	ld	xix, xiy	; F31831  ld XIX,XIY
	inc	1, xix	; F31833  inc 1,XIX
	calr	465	; F31835  calr 0xf31a09
	pop	xde	; F31838  pop XDE
	pop	xhl	; F31839  pop XHL
	pop	xix	; F3183A  pop XIX
	pop	xiz	; F3183B  pop XIZ
	ret	; F3183C  ret

; ---------------------------------------------------------------------
; DisplayListB_RunOne_Stack -- the same, for the second interpreter
; ---------------------------------------------------------------------
DisplayListB_RunOne_Stack:
	push	xiz	; F3183D  push XIZ
	ld	xiz, xsp	; F3183E  ld XIZ,XSP
	push	xix	; F31840  push XIX
	push	xhl	; F31841  push XHL
	push	xde	; F31842  push XDE
	ld	xiy, (xiz+8)	; F31843  ld XIY,(XIZ+0x08)
	ld	xix, xiy	; F31846  ld XIX,XIY
	inc	1, xix	; F31848  inc 1,XIX
	calr	675	; F3184A  calr 0xf31af0
	pop	xde	; F3184D  pop XDE
	pop	xhl	; F3184E  pop XHL
	pop	xix	; F3184F  pop XIX
	pop	xiz	; F31850  pop XIZ
	ret	; F31851  ret

; ---------------------------------------------------------------------
; sub_F31852 -- issues service 0x0C then service 0x10, both with C = 0
;
; Called from: not yet traced
; Inputs:  none (C is zeroed here)
; Outputs: unknown -- the two services are not identified
; Notes:   named by address on purpose.  Its sibling sub_F31863 issues the same
;          service 0x0C with C = 7, so C looks like a mode selector, but that is
;          an inference from two data points and is NOT asserted.
; ---------------------------------------------------------------------
sub_F31852:
	push	xiz	; F31852  push XIZ
	push	xix	; F31853  push XIX
	push	xhl	; F31854  push XHL
	push	xde	; F31855  push XDE
	xor	c, c	; F31856  xor C,C
	ldb	a, 12	; F31858  ld A,0x0c
	swi	7	; F3185A  swi 7
	ldb	a, 16	; F3185B  ld A,0x10
	swi	7	; F3185D  swi 7
	pop	xde	; F3185E  pop XDE
	pop	xhl	; F3185F  pop XHL
	pop	xix	; F31860  pop XIX
	pop	xiz	; F31861  pop XIZ
	ret	; F31862  ret

; ---------------------------------------------------------------------
; sub_F31863 -- issues service 0x0C with C = 7
; ---------------------------------------------------------------------
sub_F31863:
	push	xiz	; F31863  push XIZ
	ld	xiz, xsp	; F31864  ld XIZ,XSP
	push	xix	; F31866  push XIX
	push	xhl	; F31867  push XHL
	push	xde	; F31868  push XDE
	ldb	c, 7	; F31869  ld C,0x07
	ldb	a, 12	; F3186B  ld A,0x0c
	swi	7	; F3186D  swi 7
	pop	xde	; F3186E  pop XDE
	pop	xhl	; F3186F  pop XHL
	pop	xix	; F31870  pop XIX
	pop	xiz	; F31871  pop XIZ
	ret	; F31872  ret

; ---------------------------------------------------------------------
; DrawValueGlyph_24x24 -- draw the graphic for a 0..127 parameter value
;
; Called from: not yet traced
; Inputs:  L = value; IX = position (inherited, this routine does not set it)
; Outputs: one service-3 blit of a 3-byte x 24-row bitmap
; Notes:   L is masked to 7 bits, quantised through the 128-entry table at
;          0xF31DED (values 0x00..0x1C), and the result indexes the 29-entry
;          pointer table at 0xF31E6D.  Three sizes agree and that is the whole
;          evidence for the name: the quantiser's maximum is 0x1C so the pointer
;          table has 29 entries = 116 bytes, 0xF31E6D + 116 = 0xF31EE1 which is
;          exactly where the first bitmap starts, and 29 bitmaps x 72 bytes ends
;          at 0xF32709, exactly where this whole block ends.
; ---------------------------------------------------------------------
DrawValueGlyph_24x24:
	and	l, 127	; F31873  and L,0x7f
	ld	xiy, 15932909	; F31876  ld XIY,0x00f31ded
	.byte 0xC3, 0x03, 0xF4, 0xEC, 0x27	; F3187B  ld L,(XIY+L)   [llvm-mc cannot encode this]
	extz	hl	; F31880  extz HL
	sla	hl, 2	; F31882  sla 0x02,HL
	ld	xiy, 15933037	; F31885  ld XIY,0x00f31e6d
	.byte 0xE3, 0x07, 0xF4, 0xEC, 0x25	; F3188A  ld XIY,(XIY+HL)   [llvm-mc cannot encode this]
	ldw	bc, 3	; F3188F  ld BC,0x0003
	ldw	hl, 24	; F31892  ld HL,0x0018
	ldb	a, 3	; F31895  ld A,0x03
	swi	7	; F31897  swi 7
	ret	; F31898  ret

; ---------------------------------------------------------------------
; sub_F31899 -- draws a fixed 16x16 decoration, around a service-5 call
;
; Called from: not yet traced
; Inputs:  none -- every operand is an immediate here
; Outputs: two service-3 blits (8x16 at IX = 0x97 and 8x16 at IX = 0x9F, i.e.
;          the two halves of one 16-pixel-wide shape) with a service-5 call in
;          between whose four parameter words are 0x0100, 0x0002, 0x0137, 0x0013
; Notes:   saves (0x2540), forces it to 1 for the duration, restores it.  The
;          name is descriptive, not semantic: what the shape MEANS is unknown.
;          The two IX values differ by 8, which is what two horizontally
;          adjacent 8-pixel halves would need if IX counted pixels -- suggestive
;          only, and not asserted.
; ---------------------------------------------------------------------
sub_F31899:
	push	xiz	; F31899  push XIZ
	push	xix	; F3189A  push XIX
	push	xhl	; F3189B  push XHL
	push	xde	; F3189C  push XDE
	ldb_d8	l, (9536)	; F3189D  ld L,(0x2540)
	pushw	hl	; F318A1  push HL
	stdi8	(9536), 1	; F318A2  ld (0x2540),0x01
	ldb	a, 3	; F318A7  ld A,0x03
	ldw	ix, 151	; F318A9  ld IX,0x0097
	ldw	bc, 1	; F318AC  ld BC,0x0001
	ldw	hl, 16	; F318AF  ld HL,0x0010
	ld	xiy, 15931630	; F318B2  ld XIY,0x00f318ee
	swi	7	; F318B7  swi 7
	stdi16	(9520), 256	; F318B8  ld (0x2530),0x0100
	stdi16	(9522), 2	; F318BE  ld (0x2532),0x0002
	stdi16	(9524), 311	; F318C4  ld (0x2534),0x0137
	stdi16	(9526), 19	; F318CA  ld (0x2536),0x0013
	ldb	a, 5	; F318D0  ld A,0x05
	swi	7	; F318D2  swi 7
	ldb	a, 3	; F318D3  ld A,0x03
	ldw	ix, 159	; F318D5  ld IX,0x009f
	ldw	bc, 1	; F318D8  ld BC,0x0001
	ldw	hl, 16	; F318DB  ld HL,0x0010
	ld	xiy, 15931646	; F318DE  ld XIY,0x00f318fe
	swi	7	; F318E3  swi 7
	popw	hl	; F318E4  pop HL
	stb_d8	(9536), l	; F318E5  ld (0x2540),L
	pop	xde	; F318E9  pop XDE
	pop	xhl	; F318EA  pop XHL
	pop	xix	; F318EB  pop XIX
	pop	xiz	; F318EC  pop XIZ
	ret	; F318ED  ret

; --- 0xF318EE: two 8-pixel-wide, 16-row bitmaps, blitted by sub_F31899 -------
bitmap_F318EE:
	.byte 0x03, 0x07, 0x0F, 0x1F, 0x1F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x1F, 0x1F, 0x0F, 0x07, 0x03
bitmap_F318FE:
	.byte 0xC0, 0xE0, 0xF0, 0xF8, 0xF8, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xF8, 0xF8, 0xF0, 0xE0, 0xC0

; ---------------------------------------------------------------------
; sub_F3190E -- draws a fixed 5-byte x 15-row shape, around a service-5 call
;
; Same shape as sub_F31899: save (0x2540), force it to 1, service 5 with
; parameter words 0x0120/0x0004/0x0121/0x0004, then one service-3 blit of the
; 75-byte bitmap at 0xF31952, then restore (0x2540).
; ---------------------------------------------------------------------
sub_F3190E:
	push	xiz	; F3190E  push XIZ
	push	xix	; F3190F  push XIX
	push	xhl	; F31910  push XHL
	push	xde	; F31911  push XDE
	ldb_d8	l, (9536)	; F31912  ld L,(0x2540)
	pushw	hl	; F31916  push HL
	stdi8	(9536), 1	; F31917  ld (0x2540),0x01
	stdi16	(9520), 288	; F3191C  ld (0x2530),0x0120
	stdi16	(9522), 4	; F31922  ld (0x2532),0x0004
	stdi16	(9524), 289	; F31928  ld (0x2534),0x0121
	stdi16	(9526), 4	; F3192E  ld (0x2536),0x0004
	ldb	a, 5	; F31934  ld A,0x05
	swi	7	; F31936  swi 7
	ldb	a, 3	; F31937  ld A,0x03
	ldw	ix, 195	; F31939  ld IX,0x00c3
	ldw	bc, 5	; F3193C  ld BC,0x0005
	ldw	hl, 15	; F3193F  ld HL,0x000f
	ld	xiy, 15931730	; F31942  ld XIY,0x00f31952
	swi	7	; F31947  swi 7
	popw	hl	; F31948  pop HL
	stb_d8	(9536), l	; F31949  ld (0x2540),L
	pop	xde	; F3194D  pop XDE
	pop	xhl	; F3194E  pop XHL
	pop	xix	; F3194F  pop XIX
	pop	xiz	; F31950  pop XIZ
	ret	; F31951  ret

; --- 0xF31952: one 5-byte x 15-row bitmap (75 bytes), blitted by sub_F3190E --
bitmap_F31952:
	.byte 0x00, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x1F, 0x1F, 0x1F, 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x00, 0xFF
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x80, 0xE0, 0xF0, 0xF0
	.byte 0xF8, 0xF8, 0xFC, 0xFC, 0xFC, 0xF8, 0xF8, 0xF0, 0xF0, 0xE0, 0x80

; ---------------------------------------------------------------------
; PrintHex32_XIY -- print XIY as eight hexadecimal digits
;
; Called from: DisplayList_Run and DisplayListB_Run, on an out-of-range opcode
; Inputs:  XIY = the value to print (at the call sites: the display-list
;          pointer that went wrong)
; Outputs: eight service-6 character draws, most significant nibble first
; Notes:   0xF3199D only zeroes the digit counter and falls through into the
;          loop at 0xF319A2, which is also the loop's own back-edge target.
;          Evidence for the name is complete and local: the digit table at
;          0xF319E9 is the literal ASCII "0123456789ABCDEF", the shift-pair
;          table at 0xF319F9 is (16,12) (16,8) (16,4) (16,0) (12,0) (8,0) (4,0)
;          (0,0) -- i.e. right-shifts of 28,24,20,16,12,8,4,0 -- and the result
;          is masked with 0x0F before the draw.
; ---------------------------------------------------------------------
PrintHex32_XIY:
	ld	xix, 0	; F3199D  ld XIX,0x00000000
	push	xiy	; F319A2  push XIY
	push	xix	; F319A3  push XIX
	sla	xix, 1	; F319A4  sla 0x01,XIX
	ld	xiz, 15931897	; F319A7  ld XIZ,0x00f319f9
	.byte 0xC3, 0x07, 0xF8, 0xF0, 0x21	; F319AC  ld A,(XIZ+IX)   [llvm-mc cannot encode this]
	cps	a, 0	; F319B1  cp A,0
	jr	z, 2	; F319B3  jr Z,0xf319b7
	.byte 0xED, 0xFF	; F319B5  srl A,XIY   [llvm-mc cannot encode this]
	inc	1, ix	; F319B7  inc 1,IX
	.byte 0xC3, 0x07, 0xF8, 0xF0, 0x21	; F319B9  ld A,(XIZ+IX)   [llvm-mc cannot encode this]
	cps	a, 0	; F319BE  cp A,0
	jr	z, 2	; F319C0  jr Z,0xf319c4
	.byte 0xED, 0xFF	; F319C2  srl A,XIY   [llvm-mc cannot encode this]
	dec	1, ix	; F319C4  dec 1,IX
	srl	xix, 1	; F319C6  srl 0x01,XIX
	and	xiy, 15	; F319C9  and XIY,0x0000000f
	ld	hl, iy	; F319CF  ld HL,IY
	ldw	bc, 1	; F319D1  ld BC,0x0001
	ld	xiy, 15931881	; F319D4  ld XIY,0x00f319e9
	ldb	a, 6	; F319D9  ld A,0x06
	swi	7	; F319DB  swi 7
	pop	xix	; F319DC  pop XIX
	pop	xiy	; F319DD  pop XIY
	inc	1, xix	; F319DE  inc 1,XIX
	cp	xix, 8	; F319E0  cp XIX,0x00000008
	jr	c, -70	; F319E6  jr C,0xf319a2
	ret	; F319E8  ret

; --- 0xF319E9: the digit table PrintHex32_XIY indexes with each nibble -------
hex_digits:
	.ascii "0123456789ABCDEF"

; --- 0xF319F9: PrintHex32_XIY's shift pairs.  Digit i is XIY >> (a+b) where
;     (a,b) is the i-th pair, i.e. 28,24,20,16,12,8,4,0 -- MSB first.
hex_shift_pairs:
	.byte 0x10, 0x0C
	.byte 0x10, 0x08
	.byte 0x10, 0x04
	.byte 0x10, 0x00
	.byte 0x0C, 0x00
	.byte 0x08, 0x00
	.byte 0x04, 0x00
	.byte 0x00, 0x00

; ---------------------------------------------------------------------
; DisplayList_Run -- THE display-list interpreter (opcode space 0x00-0x23)
;
; Called from: everywhere, through thunk T_F417F0 -- the most-referenced slot in
;          the whole thunk table
; Inputs:  XIY = first record, XIX = one past the last record
; Outputs: draws; XIY and XIX are saved across each handler call
; Notes:   while (XIY < XIX): opcode = (XIY); if opcode >= 0x24 the pointer is
;          hex-printed and the loop aborts; otherwise call 0xF31D21[opcode] and
;          advance XIY by the length byte at (XIY+1).
;          Advancing by a length field is what makes every list self-checking:
;          walking it from the call site's start address lands exactly on the
;          call site's end address.  UN-MERGED, per call site, that holds for 243
;          of this interpreter's 244 prom_b sites and 158 of interpreter B's 162.
;          Both figures INCLUDING THEIR DENOMINATORS are printed by
;          `python3 notes/prom_b_dl_length_audit.py` ("A 243 of 244, B 158 of
;          162"); before 2026-08-25 the script printed only the numerators and
;          the denominators here were the reader's own addition.
;          ⚠ That script is UNTRACKED -- this lane may not commit -- so the
;          figure is reproducible only while the working tree survives.
;          The five sites that fail are dissected in
;          notes/FINDINGS-ui-display-list-interpreter-b.md.
; ---------------------------------------------------------------------
DisplayList_Run:
	cp	xix, xiy	; F31A09  cp XIX,XIY
	jr	ule, 44	; F31A0B  jr ULE,0xf31a39
	ld	l, (xiy)	; F31A0D  ld L,(XIY)
	cp	l, 36	; F31A0F  cp L,0x24
	jr	c, 5	; F31A12  jr C,0xf31a19
	calr	65414	; F31A14  calr 0xf3199d
	jr	32	; F31A17  jr T,0xf31a39
	extz	hl	; F31A19  extz HL
	extz	xhl	; F31A1B  extz XHL
	sla	xhl, 2	; F31A1D  sla 0x02,XHL
	add	xhl, 15932705	; F31A20  add XHL,0x00f31d21
	push	xiy	; F31A26  push XIY
	push	xix	; F31A27  push XIX
	ld	xhl, (xhl)	; F31A28  ld XHL,(XHL)
	call	(xhl)	; F31A2A  call T,XHL
	pop	xix	; F31A2C  pop XIX
	pop	xiy	; F31A2D  pop XIY
	ld	a, (xiy+1)	; F31A2E  ld A,(XIY+0x01)
	extz	wa	; F31A31  extz WA
	extz	xwa	; F31A33  extz XWA
	add	xiy, xwa	; F31A35  add XIY,XWA
	jr	-48	; F31A37  jr T,0xf31a09
	ret	; F31A39  ret

; ---------------------------------------------------------------------
; DLHandler_IX_Text -- opcodes 06 07 08 16 18 19 1A 1D 1E 1F 20 21
;
; Inputs:  XIY = the record
; Outputs: A = opcode, IX = the 16-bit word at +2, BC = length-4, HL = 0,
;          XIY = +4 (the characters); then `swi 7`
; Notes:   this is the routine that proves opcode == swi function number.
;          BC = length-4 is why these records' payload starts at +4.
; ---------------------------------------------------------------------
DLHandler_IX_Text:
	ld	a, (xiy)	; F31A3A  ld A,(XIY)
	ld	c, (xiy+1)	; F31A3C  ld C,(XIY+0x01)
	extz	bc	; F31A3F  extz BC
	sub	bc, 4	; F31A41  sub BC,0x0004
	ld	ix, (xiy+2)	; F31A45  ld IX,(XIY+0x02)
	xor	hl, hl	; F31A48  xor HL,HL
	add	xiy, 4	; F31A4A  add XIY,0x00000004
	swi	7	; F31A50  swi 7
	ret	; F31A51  ret

; ---------------------------------------------------------------------
; DLHandler_2Words_Text -- opcodes 17 and 1C
;
; Outputs: (0x2530) = word at +2, (0x2532) = word at +4, A = opcode,
;          BC = length-6, XIY = +6 (the characters); then `swi 7`
; ---------------------------------------------------------------------
DLHandler_2Words_Text:
	ld	a, (xiy)	; F31A52  ld A,(XIY)
	ld	c, (xiy+1)	; F31A54  ld C,(XIY+0x01)
	extz	bc	; F31A57  extz BC
	sub	bc, 6	; F31A59  sub BC,0x0006
	ld	ix, (xiy+2)	; F31A5D  ld IX,(XIY+0x02)
	stda16	(9520), ix	; F31A60  ld (0x2530),IX
	ld	ix, (xiy+4)	; F31A64  ld IX,(XIY+0x04)
	stda16	(9522), ix	; F31A67  ld (0x2532),IX
	xor	hl, hl	; F31A6B  xor HL,HL
	add	xiy, 6	; F31A6D  add XIY,0x00000006
	swi	7	; F31A73  swi 7
	ret	; F31A74  ret

; ---------------------------------------------------------------------
; DLHandler_4Words -- opcodes 00 01 02 05 09 0A 11 12 13 15 1B 22
;
; Outputs: (0x2530),(0x2532),(0x2534),(0x2536) = the four words at +2..+9,
;          A = opcode; then `swi 7`.  (0x2540) is saved across the call.
; Notes:   every record using this handler is exactly 10 bytes long, in all
;          ~4,000 records checked -- which is the length this handler implies.
; ---------------------------------------------------------------------
DLHandler_4Words:
	ldb_d8	l, (9536)	; F31A75  ld L,(0x2540)
	ld	wa, (xiy+2)	; F31A79  ld WA,(XIY+0x02)
	stda16	(9520), wa	; F31A7C  ld (0x2530),WA
	ld	wa, (xiy+4)	; F31A80  ld WA,(XIY+0x04)
	stda16	(9522), wa	; F31A83  ld (0x2532),WA
	ld	wa, (xiy+6)	; F31A87  ld WA,(XIY+0x06)
	stda16	(9524), wa	; F31A8A  ld (0x2534),WA
	ld	wa, (xiy+8)	; F31A8E  ld WA,(XIY+0x08)
	stda16	(9526), wa	; F31A91  ld (0x2536),WA
	ld	a, (xiy)	; F31A95  ld A,(XIY)
	pushw	hl	; F31A97  push HL
	swi	7	; F31A98  swi 7
	popw	hl	; F31A99  pop HL
	stb_d8	(9536), l	; F31A9A  ld (0x2540),L
	ret	; F31A9E  ret

; ---------------------------------------------------------------------
; DLHandler_IY_BC_HL -- opcode 0E.  Records are 8 bytes.
; Outputs: IY = word at +2, BC = word at +4, HL = word at +6, A = opcode; swi 7
; ---------------------------------------------------------------------
DLHandler_IY_BC_HL:
	ld	bc, (xiy+4)	; F31A9F  ld BC,(XIY+0x04)
	ld	hl, (xiy+6)	; F31AA2  ld HL,(XIY+0x06)
	ld	a, (xiy)	; F31AA5  ld A,(XIY)
	ld	iy, (xiy+2)	; F31AA7  ld IY,(XIY+0x02)
	swi	7	; F31AAA  swi 7
	ret	; F31AAB  ret

; ---------------------------------------------------------------------
; DLHandler_2Words -- opcode 0B.  Records are 6 bytes.
; Outputs: (0x2530),(0x2532) = the words at +2 and +4, A = opcode; swi 7
; ---------------------------------------------------------------------
DLHandler_2Words:
	ld	wa, (xiy+2)	; F31AAC  ld WA,(XIY+0x02)
	stda16	(9520), wa	; F31AAF  ld (0x2530),WA
	ld	wa, (xiy+4)	; F31AB3  ld WA,(XIY+0x04)
	stda16	(9522), wa	; F31AB6  ld (0x2532),WA
	ld	a, (xiy)	; F31ABA  ld A,(XIY)
	swi	7	; F31ABC  swi 7
	ret	; F31ABD  ret

; ---------------------------------------------------------------------
; DLHandler_FarPtr -- opcodes 03 and 04.  Records are 12 bytes.
; Outputs: XIY = the 32-BIT pointer at +2, IX = +6, BC = +8, HL = +0x0A,
;          A = opcode; swi 7.  With A = 3 that is exactly the bitmap-blit
;          signature, so these records blit a bitmap that lives outside the list.
; ---------------------------------------------------------------------
DLHandler_FarPtr:
	ld	a, (xiy)	; F31ABE  ld A,(XIY)
	ld	ix, (xiy+6)	; F31AC0  ld IX,(XIY+0x06)
	ld	bc, (xiy+8)	; F31AC3  ld BC,(XIY+0x08)
	ld	hl, (xiy+10)	; F31AC6  ld HL,(XIY+0x0a)
	ld	xiy, (xiy+2)	; F31AC9  ld XIY,(XIY+0x02)
	swi	7	; F31ACC  swi 7
	ret	; F31ACD  ret

; ---------------------------------------------------------------------
; DLHandler_Glyph24x24 -- opcode 23.  Records are 5 bytes.
;
; Inputs:  (XIY+2) = glyph index, (XIY+3) = position
; Outputs: one service-3 blit, BC = 3 bytes wide, HL = 0x18 = 24 rows, from
;          0xF78028 + index * 0x48
; Notes:   0x48 = 72 = 3 x 24, so the stride and the blit size agree; that is
;          the evidence that 0xF78028 is an array of 24x24 glyphs.  How many
;          there are is NOT established here.  Opcode 0x23 is the one display-
;          list opcode with no service slot of its own (service 0x23 is the dead
;          `ret`), because it is implemented here and issues service 3 itself.
; ---------------------------------------------------------------------
DLHandler_Glyph24x24:
	ld	ix, (xiy+3)	; F31ACE  ld IX,(XIY+0x03)
	ldw	bc, 3	; F31AD1  ld BC,0x0003
	ldw	hl, 24	; F31AD4  ld HL,0x0018
	ld	a, (xiy+2)	; F31AD7  ld A,(XIY+0x02)
	extz	wa	; F31ADA  extz WA
	mul	wa, 72	; F31ADC  mul WA,0x0048
	ld	xiy, 16220200	; F31AE0  ld XIY,0x00f78028
	add	xiy, xwa	; F31AE5  add XIY,XWA
	ldb	a, 3	; F31AE7  ld A,0x03
	swi	7	; F31AE9  swi 7
	ret	; F31AEA  ret

; ---------------------------------------------------------------------
; DLHandler_Ignore -- opcodes 0C 0D 0F 10 14.  A bare `ret`: the record is
; skipped and only its length byte matters.
; ---------------------------------------------------------------------
DLHandler_Ignore:
	ret	; F31AEB  ret

; ---------------------------------------------------------------------
; DisplayListB_RunOne / DisplayListB_Run -- the SECOND interpreter
;
; Called from: through thunk T_F417F4 (the second-most-referenced slot)
; Inputs:  XIY = first record, XIX = one past the last
; Notes:   identical shape to DisplayList_Run but bound 0x0F and handler table
;          0xF31DB1 (15 entries -- again exactly the bound).  Its handlers below
;          have NOT been analysed, so its record layout is not documented and
;          its lists are left as .incbin.
; ---------------------------------------------------------------------
DisplayListB_RunOne:
	ld	xix, xiy	; F31AEC  ld XIX,XIY
	inc	1, xix	; F31AEE  inc 1,XIX
DisplayListB_Run:
	cp	xix, xiy	; F31AF0  cp XIX,XIY
	jr	ule, 44	; F31AF2  jr ULE,0xf31b20
	ld	l, (xiy)	; F31AF4  ld L,(XIY)
	cp	l, 15	; F31AF6  cp L,0x0f
	jr	c, 5	; F31AF9  jr C,0xf31b00
	calr	65183	; F31AFB  calr 0xf3199d
	jr	32	; F31AFE  jr T,0xf31b20
	extz	hl	; F31B00  extz HL
	extz	xhl	; F31B02  extz XHL
	sla	xhl, 2	; F31B04  sla 0x02,XHL
	add	xhl, 15932849	; F31B07  add XHL,0x00f31db1
	push	xiy	; F31B0D  push XIY
	push	xix	; F31B0E  push XIX
	ld	xhl, (xhl)	; F31B0F  ld XHL,(XHL)
	call	(xhl)	; F31B11  call T,XHL
	pop	xix	; F31B13  pop XIX
	pop	xiy	; F31B14  pop XIY
	ld	a, (xiy+1)	; F31B15  ld A,(XIY+0x01)
	extz	wa	; F31B18  extz WA
	extz	xwa	; F31B1A  extz XWA
	add	xiy, xwa	; F31B1C  add XIY,XWA
	jr	-48	; F31B1E  jr T,0xf31af0
	ret	; F31B20  ret

; ---------------------------------------------------------------------
; 0xF31B21-0xF31D1F -- the second interpreter's handlers
;
; Called from: the 15-entry table at 0xF31DB1
;
; WHAT MAKES INTERPRETER B DIFFERENT.  Interpreter A draws what the record says.
; Interpreter B draws what a VARIABLE says: every one of these handlers opens
; with `calr DisplayListB_ExtractField` (or its sign-extending twin at 0xF31CE4),
; which reads a byte out of memory at an address the record carries, masks it and
; shifts it.  So these lists are the live parameter readouts, and interpreter A's
; are the static furniture.
;
; RECORD LAYOUT, read straight off the handlers -- each field is named by the
; instruction that consumes it, and the per-opcode length below is the highest
; byte the handler touches, plus one:
;
;   +0   opcode, bounds-checked against 0x0F
;   +1   length of the whole record
;   +2   16-bit ADDRESS of the source variable   (`ld IX,(XIY+2)` / `ld A,(IX)`)
;   +4   AND mask, one byte                      (`ld W,(XIY+4)` / `and A,W`)
;   +5   right-shift count, low 3 bits           (`and C,0x07` / `srl A,C`)
;   +6   the `swi 7` function number             (`ld A,(XIY+6)` -- every handler
;                                                 but opcode 01, which hard-codes
;                                                 0x0A; interpreter A puts this
;                                                 at +0 instead)
;   +7   and beyond: per handler, see each one's header.
;
;   opcode  handler     length   what the +7 field is
;   ------  ----------  ------   ---------------------------------------------
;   00 06   0xF31BA1      10     word -> IX; +9 digit count; buffer 0x2661..3
;   01      0xF31C9E      12     (no +7 pointer; +6/+8/+0x0A are three words)
;   02      0xF31B21      15     long -> string table, +0x0B = entry width
;   03 08   0xF31B57      11     long -> array of 8-byte entries
;   04      0xF31B86      11     long -> array of 6-byte entries
;   05      0xF31BD7      11     word -> IX; +0x0A sign flag; buffer 0x2660
;   07      0xF31B39      17     long -> string table, +0x0B = entry width
;   09 0A   0xF31C14      12     word -> (0x2530); +9 -> (0x2532)
;   0B      0xF31C56      13     word -> (0x2530); +0x0C sign flag
;   0C 0D 0E 0xF31D20      2     bare `ret`
;
; EVERY interpreter-B record in the image obeys that table, with no exceptions,
; and so does every interpreter-A record obey A's.  Sharper still: each of B's
; eleven live opcodes has exactly ONE record length across the whole image --
;   op 00 x74 len 10   op 02 x183 len 15   op 03 x67 len 11   op 04 x3  len 11
;   op 05 x62 len 11   op 06 x32  len 10   op 07 x30 len 17   op 08 x5  len 11
;   op 09 x27 len 12   op 0A x3   len 12   op 0B x8  len 13
; -- 494 records, no opcode with two lengths.  This is the correction of the
; "341 records violate the length rule" figure: those 341 were B records measured
; against A's layout.  Reproduce:
;     python3 notes/prom_b_dl_length_audit.py --edges
;
; The lists themselves are emitted as records above and below this block, each
; rendered with its own interpreter's layout; B records are marked `B op NN`.
;
; ⚠ STILL NOT ESTABLISHED: which RAM variables the +2 addresses are, and what
; each `swi 7` function draws.
; ---------------------------------------------------------------------
; DLB_Handler_StringTable -- interpreter B opcode 02: draw entry [value] of a
;                            string table
; Called from: DisplayListB_HandlerTable slot 0x02 (0xF31DB1+8)
; Inputs:  XIY = the record, 15 bytes:
;            +2 word source-variable address, +4 mask, +5 shift  (ExtractField)
;            +6 swi 7 function, +7 long -> XIY, +0x0B -> BC, +0x0D -> IX
; Outputs: issues `swi 7` with HL = the extracted bit-field = the entry index
; Evidence: `ld XIY,(XIY+7)` re-points XIY at the table and `ld BC,(XIY+0x0B)`
;           is the entry width; the record at 0xF03455 carries BC = 4 and points
;           at 0xF03478, which reads "FIX MOVE" -- two four-character entries,
;           and its mask 0x80 with shift 7 admits exactly the indices 0 and 1.
;           Highest record byte touched is +0x0E; all 183 interpreter-B op-02
;           records in the image are 15 bytes (notes/prom_b_dl_length_audit.py).
;           The `cp (XIY),0x07 / jr Z` at 0xF31B24 is dead when the handler is
;           reached through the table, because slot 0x07 holds 0xF31B39.
; Unknown:  which variables the +2 addresses are.
; ---------------------------------------------------------------------
DLB_Handler_StringTable:
	calr	417	; F31B21  calr 0xf31cc5
	.byte 0x85, 0x3F, 0x07	; F31B24  cp (XIY),0x07   [llvm-mc cannot encode this]
	jr	z, 19	; F31B27  jr Z,0xf31b3c
	ld	hl, wa	; F31B29  ld HL,WA
	ld	ix, (xiy+13)	; F31B2B  ld IX,(XIY+0x0d)
	ld	a, (xiy+6)	; F31B2E  ld A,(XIY+0x06)
	ld	bc, (xiy+11)	; F31B31  ld BC,(XIY+0x0b)
	ld	xiy, (xiy+7)	; F31B34  ld XIY,(XIY+0x07)
	swi	7	; F31B37  swi 7
	ret	; F31B38  ret
; ---------------------------------------------------------------------
; DLB_Handler_StringTable2 -- interpreter B opcode 07: draw entry [value] of a
;                             string table, with two extra words
; Called from: DisplayListB_HandlerTable slot 0x07 (0xF31DB1+0x1C).  Slot 0x02's
;              handler (0xF31B21) jumps INTO this one at 0xF31B3C when the record
;              it is running has opcode 0x07 -- which cannot happen through the
;              table, so 0xF31B21's `cp (XIY),0x07` is dead for table entry.
; Inputs:  XIY = the record.  Record is 17 bytes:
;            +2 word source-variable address, +4 mask, +5 shift  (ExtractField)
;            +6 swi 7 function, +7 long -> XIY, +0x0B -> BC,
;            +0x0D -> (0x2530), +0x0F -> (0x2532)
; Outputs: issues `swi 7` with HL = the extracted bit-field
; Evidence: the six loads listed above are the whole routine; the highest record
;           byte any of them touches is +0x10, and all 30 interpreter-B op-07
;           records are exactly 17 bytes (notes/prom_b_dl_length_audit.py).
;           BC is the entry WIDTH: the record at 0xF0302A carries BC = 8 and its
;           +7 points at 0xF03241, which holds 64 eight-character names
;           ("ORIGINAL", " STRING ", "CYLINDER", ...) ending exactly on the next
;           display list at 0xF03441.
; Unknown:  which variables the +2 addresses are.
; ---------------------------------------------------------------------
DLB_Handler_StringTable2:
	calr	393	; F31B39  calr 0xf31cc5
	ld	hl, wa	; F31B3C  ld HL,WA
	ld	a, (xiy+6)	; F31B3E  ld A,(XIY+0x06)
	ld	bc, (xiy+11)	; F31B41  ld BC,(XIY+0x0b)
	ld	ix, (xiy+13)	; F31B44  ld IX,(XIY+0x0d)
	stda16	(9520), ix	; F31B47  ld (0x2530),IX
	ld	ix, (xiy+15)	; F31B4B  ld IX,(XIY+0x0f)
	stda16	(9522), ix	; F31B4E  ld (0x2532),IX
	ld	xiy, (xiy+7)	; F31B52  ld XIY,(XIY+0x07)
	swi	7	; F31B55  swi 7
	ret	; F31B56  ret
; ---------------------------------------------------------------------
; DLB_Handler_Array8 -- interpreter B opcodes 03 and 08: four words of
;                       entry[value] of an array of 8-byte entries
; Called from: DisplayListB_HandlerTable slots 0x03 and 0x08
; Inputs:  XIY = the record, 11 bytes: +2/+4/+5 the field, +6 the swi 7
;          function, +7 a 32-bit array base
; Outputs: (0x2530),(0x2532),(0x2534),(0x2536) = the entry's four 16-bit words;
;          then `swi 7`
; Evidence: `sla 3,HL` on the extracted value before `add XIX,XHL` is what fixes
;           the entry size at 8; the four `ld BC,(XIX+n)` at n = 0, 2, 4, 6 are
;           what fixes it at four words.  Highest record byte touched is +0x0A,
;           and all 67 op-03 and all 5 op-08 interpreter-B records are 11 bytes.
; Unknown:  what service (XIY+6) does with the four words.  0x05 is the value
;           seen most often and is the same service interpreter A's
;           DLHandler_4Words feeds.
; ---------------------------------------------------------------------
DLB_Handler_Array8:
	calr	363	; F31B57  calr 0xf31cc5
	ld	hl, wa	; F31B5A  ld HL,WA
	sla	hl, 3	; F31B5C  sla 0x03,HL
	extz	xhl	; F31B5F  extz XHL
	ld	a, (xiy+6)	; F31B61  ld A,(XIY+0x06)
	ld	xix, (xiy+7)	; F31B64  ld XIX,(XIY+0x07)
	add	xix, xhl	; F31B67  add XIX,XHL
	ld	bc, (xix)	; F31B69  ld BC,(XIX)
	stda16	(9520), bc	; F31B6B  ld (0x2530),BC
	ld	bc, (xix+2)	; F31B6F  ld BC,(XIX+0x02)
	stda16	(9522), bc	; F31B72  ld (0x2532),BC
	ld	bc, (xix+4)	; F31B76  ld BC,(XIX+0x04)
	stda16	(9524), bc	; F31B79  ld (0x2534),BC
	ld	bc, (xix+6)	; F31B7D  ld BC,(XIX+0x06)
	stda16	(9526), bc	; F31B80  ld (0x2536),BC
	swi	7	; F31B84  swi 7
	ret	; F31B85  ret
; ---------------------------------------------------------------------
; DLB_Handler_Array6 -- interpreter B opcode 04: entry[value] of an array of
;                       6-byte entries, into IY/BC/HL
; Called from: DisplayListB_HandlerTable slot 0x04
; Inputs:  XIY = the record, 11 bytes, same field layout as DLB_Handler_Array8
; Outputs: IY = (entry+0), BC = (entry+2), HL = (entry+4); then `swi 7`
; Evidence: `mul HL,6` fixes the entry size at 6; the three loads fix the shape.
;           All 3 interpreter-B op-04 records are 11 bytes.
; ---------------------------------------------------------------------
DLB_Handler_Array6:
	calr	316	; F31B86  calr 0xf31cc5
	ld	hl, wa	; F31B89  ld HL,WA
	mul	hl, 6	; F31B8B  mul HL,0x0006
	ld	a, (xiy+6)	; F31B8F  ld A,(XIY+0x06)
	ld	xix, (xiy+7)	; F31B92  ld XIX,(XIY+0x07)
	add	xix, xhl	; F31B95  add XIX,XHL
	ld	bc, (xix+2)	; F31B97  ld BC,(XIX+0x02)
	ld	hl, (xix+4)	; F31B9A  ld HL,(XIX+0x04)
	ld	iy, (xix)	; F31B9D  ld IY,(XIX)
	swi	7	; F31B9F  swi 7
	ret	; F31BA0  ret
; ---------------------------------------------------------------------
; DLB_Handler_Decimal -- interpreter B opcodes 00 and 06: draw the field as
;                        decimal digits
; Called from: DisplayListB_HandlerTable slots 0x00 and 0x06
; Inputs:  XIY = the record, 10 bytes: +2/+4/+5 the field, +6 the swi 7
;          function, +7 word -> IX, +9 digit count
; Outputs: `swi 7` with XIY pointing into the digit buffer at 0x2660
; Evidence: for opcode 6 the value is read as a 16-bit word straight from the
;           +2 address instead of through ExtractField (`ld IX,(XIY+2) / extz
;           XIX / ld WA,(XIX)`).  Either way it then calls thunk T_F41AF0 ->
;           prom_a 0xF8BCAF, which is a decimal converter: 0xF8BCD7 repeatedly
;           subtracts 100 and 10 and leaves three digits at 0x2661, 0x2662,
;           0x2663, and 0xF8BCAF blanks the leading ones with 0x20 (' ').
;           The +9 count then picks the starting digit: 3 -> 0x2661, 2 -> 0x2662,
;           anything else -> 0x2663.
; Unknown:  what `swi 7` function (XIY+6) is.
; ---------------------------------------------------------------------
DLB_Handler_Decimal:
	ld	a, (xiy)	; F31BA1  ld A,(XIY)
	cps	a, 6	; F31BA3  cp A,6
	jr	nz, 9	; F31BA5  jr NZ,0xf31bb0
	ld	ix, (xiy+2)	; F31BA7  ld IX,(XIY+0x02)
	extz	xix	; F31BAA  extz XIX
	ld	wa, (xix)	; F31BAC  ld WA,(XIX)
	jr	3	; F31BAE  jr T,0xf31bb3
	calr	274	; F31BB0  calr 0xf31cc5
	call	15997680	; F31BB3  call 0xf41af0
	ld	ix, (xiy+7)	; F31BB7  ld IX,(XIY+0x07)
	ld	a, (xiy+6)	; F31BBA  ld A,(XIY+0x06)
	ld	c, (xiy+9)	; F31BBD  ld C,(XIY+0x09)
	extz	bc	; F31BC0  extz BC
	ld	xiy, 9825	; F31BC2  ld XIY,0x00002661
	xor	hl, hl	; F31BC7  xor HL,HL
	cps	bc, 3	; F31BC9  cp BC,3
	jr	z, 8	; F31BCB  jr Z,0xf31bd5
	cps	bc, 2	; F31BCD  cp BC,2
	jr	z, 2	; F31BCF  jr Z,0xf31bd3
	inc	1, iy	; F31BD1  inc 1,IY
	inc	1, iy	; F31BD3  inc 1,IY
	swi	7	; F31BD5  swi 7
	ret	; F31BD6  ret
; ---------------------------------------------------------------------
; DLB_Handler_DecimalSigned -- interpreter B opcode 05: the same, signed
; Called from: DisplayListB_HandlerTable slot 0x05
; Inputs:  XIY = the record, 11 bytes; +0x0A is the sign flag
; Outputs: `swi 7` with XIY pointing into the buffer at 0x2660, one character
;          earlier than the unsigned form
; Evidence: it uses DisplayListB_ExtractFieldSigned (0xF31CE4), which after the
;           mask and shift reads (XIY+0x0A) and sign-extends WA unless that
;           byte's bit 7 is set; and thunk T_F41AF8 -> prom_a 0xF8BCC9, which is
;           0xF8BD41 followed by the same 0xF8BCAF -- i.e. a sign step in front
;           of the decimal conversion.  The buffer base here is 0x2660, one byte
;           below the unsigned handler's 0x2661, and BC is incremented, so the
;           extra character is the sign.
; ---------------------------------------------------------------------
DLB_Handler_DecimalSigned:
	calr	266	; F31BD7  calr 0xf31ce4
	call	15997688	; F31BDA  call 0xf41af8
	ld	ix, (xiy+7)	; F31BDE  ld IX,(XIY+0x07)
	ld	a, (xiy+6)	; F31BE1  ld A,(XIY+0x06)
	ld	c, (xiy+9)	; F31BE4  ld C,(XIY+0x09)
	extz	bc	; F31BE7  extz BC
	inc	1, bc	; F31BE9  inc 1,BC
	ld	xiy, 9824	; F31BEB  ld XIY,0x00002660
	xor	hl, hl	; F31BF0  xor HL,HL
	cps	bc, 4	; F31BF2  cp BC,4
	jr	z, 28	; F31BF4  jr Z,0xf31c12
	cps	bc, 3	; F31BF6  cp BC,3
	jr	z, 10	; F31BF8  jr Z,0xf31c04
	pushw	wa	; F31BFA  push WA
	ld	a, (xiy+3)	; F31BFB  ld A,(XIY+0x03)
	ld	(xiy+1), a	; F31BFE  ld (XIY+0x01),A
	popw	wa	; F31C01  pop WA
	jr	14	; F31C02  jr T,0xf31c12
	pushw	wa	; F31C04  push WA
	ld	a, (xiy+2)	; F31C05  ld A,(XIY+0x02)
	ld	(xiy+1), a	; F31C08  ld (XIY+0x01),A
	ld	a, (xiy+3)	; F31C0B  ld A,(XIY+0x03)
	ld	(xiy+2), a	; F31C0E  ld (XIY+0x02),A
	popw	wa	; F31C11  pop WA
	swi	7	; F31C12  swi 7
	ret	; F31C13  ret
; ---------------------------------------------------------------------
; DLB_Handler_Decimal2Words -- interpreter B opcodes 09 and 0A: decimal, with
;                              two extra words
; Called from: DisplayListB_HandlerTable slots 0x09 and 0x0A
; Inputs:  XIY = the record, 12 bytes: field, +6 function, +7 -> (0x2530),
;          +9 -> (0x2532), +0x0B digit count
; Outputs: as DLB_Handler_Decimal
; Evidence: opcode 0x0A takes the same direct 16-bit read that opcode 0x06 takes
;           in DLB_Handler_Decimal (`cp A,0x0A` instead of `cp A,6`); the rest is
;           the unsigned decimal path with two more words stored.
; ---------------------------------------------------------------------
DLB_Handler_Decimal2Words:
	ld	a, (xiy)	; F31C14  ld A,(XIY)
	cp	a, 10	; F31C16  cp A,0x0a
	jr	nz, 9	; F31C19  jr NZ,0xf31c24
	ld	ix, (xiy+2)	; F31C1B  ld IX,(XIY+0x02)
	extz	xix	; F31C1E  extz XIX
	ld	wa, (xix)	; F31C20  ld WA,(XIX)
	jr	3	; F31C22  jr T,0xf31c27
	calr	158	; F31C24  calr 0xf31cc5
	call	15997680	; F31C27  call 0xf41af0
	ld	ix, (xiy+7)	; F31C2B  ld IX,(XIY+0x07)
	stda16	(9520), ix	; F31C2E  ld (0x2530),IX
	ld	ix, (xiy+9)	; F31C32  ld IX,(XIY+0x09)
	stda16	(9522), ix	; F31C35  ld (0x2532),IX
	ld	a, (xiy+6)	; F31C39  ld A,(XIY+0x06)
	ld	c, (xiy+11)	; F31C3C  ld C,(XIY+0x0b)
	extz	bc	; F31C3F  extz BC
	ld	xiy, 9825	; F31C41  ld XIY,0x00002661
	xor	hl, hl	; F31C46  xor HL,HL
	cps	bc, 3	; F31C48  cp BC,3
	jr	z, 8	; F31C4A  jr Z,0xf31c54
	cps	bc, 2	; F31C4C  cp BC,2
	jr	z, 2	; F31C4E  jr Z,0xf31c52
	inc	1, iy	; F31C50  inc 1,IY
	inc	1, iy	; F31C52  inc 1,IY
	swi	7	; F31C54  swi 7
	ret	; F31C55  ret
; ---------------------------------------------------------------------
; DLB_Handler_DecimalSigned2Words -- interpreter B opcode 0B: signed decimal,
;                                    two extra words
; Called from: DisplayListB_HandlerTable slot 0x0B
; Inputs:  XIY = the record, 13 bytes; +0x0C is the sign flag
; Evidence: DisplayListB_ExtractFieldSigned reads its sign flag from (XIY+0x0C)
;           rather than (XIY+0x0A) exactly when the opcode is 0x0B -- that is the
;           `cp (XIY),0x0B` at 0xF31D02 -- which is why this record is 13 bytes
;           and opcode 05's is 11.  All 8 interpreter-B op-0B records are 13.
; ---------------------------------------------------------------------
DLB_Handler_DecimalSigned2Words:
	calr	139	; F31C56  calr 0xf31ce4
	call	15997688	; F31C59  call 0xf41af8
	ld	ix, (xiy+7)	; F31C5D  ld IX,(XIY+0x07)
	stda16	(9520), ix	; F31C60  ld (0x2530),IX
	ld	ix, (xiy+9)	; F31C64  ld IX,(XIY+0x09)
	stda16	(9522), ix	; F31C67  ld (0x2532),IX
	ld	a, (xiy+6)	; F31C6B  ld A,(XIY+0x06)
	ld	c, (xiy+11)	; F31C6E  ld C,(XIY+0x0b)
	extz	bc	; F31C71  extz BC
	inc	1, bc	; F31C73  inc 1,BC
	ld	xiy, 9824	; F31C75  ld XIY,0x00002660
	xor	hl, hl	; F31C7A  xor HL,HL
	cps	bc, 4	; F31C7C  cp BC,4
	jr	z, 28	; F31C7E  jr Z,0xf31c9c
	cps	bc, 3	; F31C80  cp BC,3
	jr	z, 10	; F31C82  jr Z,0xf31c8e
	pushw	wa	; F31C84  push WA
	ld	a, (xiy+3)	; F31C85  ld A,(XIY+0x03)
	ld	(xiy+1), a	; F31C88  ld (XIY+0x01),A
	popw	wa	; F31C8B  pop WA
	jr	14	; F31C8C  jr T,0xf31c9c
	pushw	wa	; F31C8E  push WA
	ld	a, (xiy+2)	; F31C8F  ld A,(XIY+0x02)
	ld	(xiy+1), a	; F31C92  ld (XIY+0x01),A
	ld	a, (xiy+3)	; F31C95  ld A,(XIY+0x03)
	ld	(xiy+2), a	; F31C98  ld (XIY+0x02),A
	popw	wa	; F31C9B  pop WA
	swi	7	; F31C9C  swi 7
	ret	; F31C9D  ret
; ---------------------------------------------------------------------
; DLB_Handler_CentredSpan -- interpreter B opcode 01: four words, one of them
;                            offset by half the field value
; Called from: DisplayListB_HandlerTable slot 0x01
; Inputs:  XIY = the record, 12 bytes: +2/+4/+5 the field, +6 -> (0x2530),
;          +8 -> (0x2534), +0x0A -> (0x2536)
; Outputs: (0x2532) = (XIY+0x0A) - value/2; `swi 7` with A hard-coded to 0x0A
; Evidence: `srl 1,WA / sub HL,WA` on the copy of (XIY+0x0A) is the only
;           arithmetic; `ld A,0x0A` immediately before `swi 7` is why this
;           handler is the one interpreter-B opcode with no +6 function byte.
; Unknown:  what service 0x0A draws.
; ---------------------------------------------------------------------
DLB_Handler_CentredSpan:
	calr	36	; F31C9E  calr 0xf31cc5
	ld	hl, (xiy+10)	; F31CA1  ld HL,(XIY+0x0a)
	stda16	(9526), hl	; F31CA4  ld (0x2536),HL
	extz	wa	; F31CA8  extz WA
	srl	wa, 1	; F31CAA  srl 0x01,WA
	sub	hl, wa	; F31CAD  sub HL,WA
	stda16	(9522), hl	; F31CAF  ld (0x2532),HL
	ld	wa, (xiy+6)	; F31CB3  ld WA,(XIY+0x06)
	stda16	(9520), wa	; F31CB6  ld (0x2530),WA
	ld	wa, (xiy+8)	; F31CBA  ld WA,(XIY+0x08)
	stda16	(9524), wa	; F31CBD  ld (0x2534),WA
	ldb	a, 10	; F31CC1  ld A,0x0a
	swi	7	; F31CC3  swi 7
	ret	; F31CC4  ret

; ---------------------------------------------------------------------
; DisplayListB_ExtractField -- read one bit-field out of a live variable
;
; Called from: every handler in the 0xF31DB1 table (as `calr`, first thing)
; Inputs:  XIY = the record
; Outputs: WA = ((byte at the 16-bit address in (XIY+2)) & (XIY+4)) >> ((XIY+5) & 7)
; Notes:   this routine is the whole difference between the two interpreters.
;          0xF31CE4 below is a SECOND copy with a tail; both are entered by
;          `calr`, so they are two routines, not one with a fall-through.
; ---------------------------------------------------------------------
DisplayListB_ExtractField:
	ld	ix, (xiy+2)	; F31CC5  ld IX,(XIY+0x02)
	extz	xix	; F31CC8  extz XIX
	ld	a, (xix)	; F31CCA  ld A,(XIX)
	ld	w, (xiy+4)	; F31CCC  ld W,(XIY+0x04)
	and	a, w	; F31CCF  and A,W
	extz	wa	; F31CD1  extz WA
	ld	c, (xiy+5)	; F31CD3  ld C,(XIY+0x05)
	and	c, 7	; F31CD6  and C,0x07
	cps	c, 0	; F31CD9  cp C,0
	jr	z, 6	; F31CDB  jr Z,0xf31ce3
	ex8	a, c	; F31CDD  ex A,C
	.byte 0xCB, 0xFF	; F31CDF  srl A,C   [llvm-mc cannot encode this]
	ex8	a, c	; F31CE1  ex A,C
	ret	; F31CE3  ret

; ---------------------------------------------------------------------
; DisplayListB_ExtractFieldSigned -- the same field read, then sign-extended
;                                    under the control of a flag byte
; Called from: handlers 0xF31BD7 (opcode 05) and 0xF31C56 (opcode 0B), by `calr`
; Inputs:  XIY = the record
; Outputs: WA = the field, sign-extended to 16 bits unless bit 7 of the flag byte
;          is set, in which case W is cleared and the field stays unsigned
; Evidence: 0xF31CC5..0xF31CE3 repeated verbatim, then `cp (XIY),0x0B` picks the
;           flag byte's offset -- +0x0C for opcode 0x0B, +0x0A for everything
;           else -- `ld E,(XIY+E)` fetches it, `bit 7,E` tests it, and the two
;           arms are `xor W,W` (stay unsigned) and `exts WA` (sign-extend).
;           That offset choice is exactly why op-0B records are 13 bytes and
;           op-05 records are 11.
; ---------------------------------------------------------------------
DisplayListB_ExtractFieldSigned:
	ld	ix, (xiy+2)	; F31CE4  ld IX,(XIY+0x02)
	extz	xix	; F31CE7  extz XIX
	ld	a, (xix)	; F31CE9  ld A,(XIX)
	ld	w, (xiy+4)	; F31CEB  ld W,(XIY+0x04)
	and	a, w	; F31CEE  and A,W
	extz	wa	; F31CF0  extz WA
	ld	c, (xiy+5)	; F31CF2  ld C,(XIY+0x05)
	and	c, 7	; F31CF5  and C,0x07
	cps	c, 0	; F31CF8  cp C,0
	jr	z, 6	; F31CFA  jr Z,0xf31d02
	ex8	a, c	; F31CFC  ex A,C
	.byte 0xCB, 0xFF	; F31CFE  srl A,C   [llvm-mc cannot encode this]
	ex8	a, c	; F31D00  ex A,C
	.byte 0x85, 0x3F, 0x0B	; F31D02  cp (XIY),0x0b   [llvm-mc cannot encode this]
	jr	z, 4	; F31D05  jr Z,0xf31d0b
	ldb	e, 10	; F31D07  ld E,0x0a
	jr	2	; F31D09  jr T,0xf31d0d
	ldb	e, 12	; F31D0B  ld E,0x0c
	.byte 0xC3, 0x03, 0xF4, 0xE8, 0x25	; F31D0D  ld E,(XIY+E)   [llvm-mc cannot encode this]
	extz	de	; F31D12  extz DE
	bit	7, e	; F31D14  bit 0x07,E
	jr	z, 4	; F31D17  jr Z,0xf31d1d
	xor	w, w	; F31D19  xor W,W
	jr	2	; F31D1B  jr T,0xf31d1f
	exts	wa	; F31D1D  exts WA
	ret	; F31D1F  ret

; --- 0xF31D20: a bare `ret`, used as the handler for the second interpreter's
;     opcodes 0x0C, 0x0D and 0x0E.  Same idea as the 0x0E fill in the thunk
;     table: an unused slot returns instead of running on.
dl_handler_ret:
	ret

; --- 0xF31D21: DisplayList_Run's handler table.  36 entries = the 0x24 bound.
DisplayList_HandlerTable:
	.long 0x00F31A75	; opcode 0x00
	.long 0x00F31A75	; opcode 0x01
	.long 0x00F31A75	; opcode 0x02
	.long 0x00F31ABE	; opcode 0x03
	.long 0x00F31ABE	; opcode 0x04
	.long 0x00F31A75	; opcode 0x05
	.long 0x00F31A3A	; opcode 0x06
	.long 0x00F31A3A	; opcode 0x07
	.long 0x00F31A3A	; opcode 0x08
	.long 0x00F31A75	; opcode 0x09
	.long 0x00F31A75	; opcode 0x0A
	.long 0x00F31AAC	; opcode 0x0B
	.long 0x00F31AEB	; opcode 0x0C
	.long 0x00F31AEB	; opcode 0x0D
	.long 0x00F31A9F	; opcode 0x0E
	.long 0x00F31AEB	; opcode 0x0F
	.long 0x00F31AEB	; opcode 0x10
	.long 0x00F31A75	; opcode 0x11
	.long 0x00F31A75	; opcode 0x12
	.long 0x00F31A75	; opcode 0x13
	.long 0x00F31AEB	; opcode 0x14
	.long 0x00F31A75	; opcode 0x15
	.long 0x00F31A3A	; opcode 0x16
	.long 0x00F31A52	; opcode 0x17
	.long 0x00F31A3A	; opcode 0x18
	.long 0x00F31A3A	; opcode 0x19
	.long 0x00F31A3A	; opcode 0x1A
	.long 0x00F31A75	; opcode 0x1B
	.long 0x00F31A52	; opcode 0x1C
	.long 0x00F31A3A	; opcode 0x1D
	.long 0x00F31A3A	; opcode 0x1E
	.long 0x00F31A3A	; opcode 0x1F
	.long 0x00F31A3A	; opcode 0x20
	.long 0x00F31A3A	; opcode 0x21
	.long 0x00F31A75	; opcode 0x22
	.long 0x00F31ACE	; opcode 0x23

; --- 0xF31DB1: DisplayListB_Run's handler table.  15 entries = the 0x0F bound.
DisplayListB_HandlerTable:
	.long 0x00F31BA1	; opcode 0x00
	.long 0x00F31C9E	; opcode 0x01
	.long 0x00F31B21	; opcode 0x02
	.long 0x00F31B57	; opcode 0x03
	.long 0x00F31B86	; opcode 0x04
	.long 0x00F31BD7	; opcode 0x05
	.long 0x00F31BA1	; opcode 0x06
	.long 0x00F31B39	; opcode 0x07
	.long 0x00F31B57	; opcode 0x08
	.long 0x00F31C14	; opcode 0x09
	.long 0x00F31C14	; opcode 0x0A
	.long 0x00F31C56	; opcode 0x0B
	.long 0x00F31D20	; opcode 0x0C
	.long 0x00F31D20	; opcode 0x0D
	.long 0x00F31D20	; opcode 0x0E

; --- 0xF31DED: DrawValueGlyph_24x24's quantiser.  128 entries, one per input
;     value 0..127; the value is the index into ValueGlyph_Table below.  It is
;     monotonic and its maximum is 0x1C, which fixes that table's length at 29.
ValueGlyph_Quantiser:
	.byte 0x00, 0x01, 0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0x02, 0x03, 0x03, 0x03, 0x03, 0x04, 0x04, 0x04
	.byte 0x04, 0x05, 0x05, 0x05, 0x05, 0x05, 0x06, 0x06, 0x06, 0x06, 0x06, 0x07, 0x07, 0x07, 0x07, 0x07
	.byte 0x08, 0x08, 0x08, 0x08, 0x08, 0x09, 0x09, 0x09, 0x09, 0x09, 0x0A, 0x0A, 0x0A, 0x0A, 0x0A, 0x0B
	.byte 0x0B, 0x0B, 0x0B, 0x0B, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x0E, 0x0E
	.byte 0x0E, 0x0E, 0x0E, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x10, 0x10, 0x10, 0x10, 0x10, 0x11, 0x11, 0x11
	.byte 0x11, 0x11, 0x12, 0x12, 0x12, 0x12, 0x12, 0x13, 0x13, 0x13, 0x13, 0x13, 0x14, 0x14, 0x14, 0x14
	.byte 0x14, 0x15, 0x15, 0x15, 0x15, 0x15, 0x16, 0x16, 0x16, 0x16, 0x16, 0x17, 0x17, 0x17, 0x17, 0x18
	.byte 0x18, 0x18, 0x18, 0x19, 0x19, 0x19, 0x19, 0x1A, 0x1A, 0x1A, 0x1A, 0x1B, 0x1B, 0x1B, 0x1B, 0x1C

; --- 0xF31E6D: 29 pointers, one per quantiser output, to 24x24 bitmaps.
;     0xF31E6D + 29*4 = 0xF31EE1 = the first bitmap, so the count is not a guess.
ValueGlyph_Table:
	.long 0x00F31EE1	; step  0
	.long 0x00F31F29	; step  1
	.long 0x00F31F71	; step  2
	.long 0x00F31FB9	; step  3
	.long 0x00F32001	; step  4
	.long 0x00F32049	; step  5
	.long 0x00F32091	; step  6
	.long 0x00F320D9	; step  7
	.long 0x00F32121	; step  8
	.long 0x00F32169	; step  9
	.long 0x00F321B1	; step 10
	.long 0x00F321F9	; step 11
	.long 0x00F32241	; step 12
	.long 0x00F32289	; step 13
	.long 0x00F322D1	; step 14
	.long 0x00F32319	; step 15
	.long 0x00F32361	; step 16
	.long 0x00F323A9	; step 17
	.long 0x00F323F1	; step 18
	.long 0x00F32439	; step 19
	.long 0x00F32481	; step 20
	.long 0x00F324C9	; step 21
	.long 0x00F32511	; step 22
	.long 0x00F32559	; step 23
	.long 0x00F325A1	; step 24
	.long 0x00F325E9	; step 25
	.long 0x00F32631	; step 26
	.long 0x00F32679	; step 27
	.long 0x00F326C1	; step 28

; --- 0xF31EE1: the 29 bitmaps themselves, 3 bytes x 24 rows = 72 bytes each.
;     29 * 72 = 2088, and 0xF31EE1 + 2088 = 0xF32709 -- the end of this block.
ValueGlyph_Bitmaps:
	; step  0 -- 0xF31EE1
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xEF
	.byte 0xEF, 0xDF, 0xDF, 0xDF, 0xBF, 0xBF, 0x3C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step  1 -- 0xF31F29
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xEF
	.byte 0xDF, 0xDF, 0xBF, 0x7F, 0x7F, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step  2 -- 0xF31F71
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x06, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xEF
	.byte 0xDF, 0xBF, 0x7F, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step  3 -- 0xF31FB9
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x04, 0x03, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xEF
	.byte 0x9F, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step  4 -- 0xF32001
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0E, 0x01, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xCF
	.byte 0x3F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step  5 -- 0xF32049
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x00, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x0F
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step  6 -- 0xF32091
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x20
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x0F
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step  7 -- 0xF320D9
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x00, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x0F
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step  8 -- 0xF32121
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x01, 0x0E, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x3F, 0xCF
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step  9 -- 0xF32169
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x03, 0x04, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F, 0x9F, 0xEF
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 10 -- 0xF321B1
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x06, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0x7F, 0xBF, 0xDF, 0xEF
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 11 -- 0xF321F9
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0x7F, 0x7F, 0xBF, 0xDF, 0xDF, 0xEF
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 12 -- 0xF32241
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x3C, 0xBF, 0xBF, 0xDF, 0xDF, 0xDF, 0xEF, 0xEF
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 13 -- 0xF32289
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x5C, 0xDF, 0xDF, 0xDF, 0xEF, 0xEF, 0xEF, 0xEF
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 14 -- 0xF322D1
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x6C, 0xEF, 0xEF, 0xEF, 0xEF, 0xEF, 0xEF, 0xEF
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 15 -- 0xF32319
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x74, 0xF7, 0xF7, 0xF7, 0xEF, 0xEF, 0xEF, 0xEF
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 16 -- 0xF32361
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x78, 0xFB, 0xFB, 0xF7, 0xF7, 0xF7, 0xEF, 0xEF
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 17 -- 0xF323A9
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFE, 0xFD, 0xFD, 0xFB, 0xF7, 0xF7, 0xEF
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 18 -- 0xF323F1
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFE, 0xFD, 0xFB, 0xF7, 0xEF
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 19 -- 0xF32439
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFE, 0xFD, 0xF3, 0xEF
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x80, 0x40, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 20 -- 0xF32481
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xF8, 0xE7
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0x00, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 21 -- 0xF324C9
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0xE1
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0x00, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 22 -- 0xF32511
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xE0
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0x08
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 23 -- 0xF32559
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xE1
	.byte 0xFE, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0x00, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 24 -- 0xF325A1
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xE7
	.byte 0xF8, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0x00, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 25 -- 0xF325E9
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xEF
	.byte 0xF3, 0xFD, 0xFE, 0xFF, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0x40, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 26 -- 0xF32631
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xEF
	.byte 0xF7, 0xFB, 0xFD, 0xFE, 0xFF, 0xFF, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 27 -- 0xF32679
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xEF
	.byte 0xF7, 0xF7, 0xFB, 0xFD, 0xFD, 0xFE, 0x7C, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; step 28 -- 0xF326C1
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x07, 0x07, 0x0F, 0x0F, 0x2F
	.byte 0x0F, 0x0F, 0x07, 0x07, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x00, 0x7C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xEF
	.byte 0xEF, 0xF7, 0xF7, 0xF7, 0xFB, 0xFB, 0x78, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xC0, 0xE0, 0xE0, 0xE8
	.byte 0xE0, 0xE0, 0xC0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

; --- 0xF32709-0xF328DB: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x032709, 0x0001D3

; ------------------------------------------------------------------
; 0xF328DC-0xF32991 -- 14 display-list records, 182 bytes -- interpreter B
;   entered at: 0xF328DC, 0xF3294B, 0xF32987
;   ends used:  0xF32918, 0xF3294B, 0xF32987, 0xF32992
; ------------------------------------------------------------------
DL_F328DC:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x03	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F32A5A	; +0x07 -> XIY: string table
	.short 0x0007	; +0x0B -> BC: bytes per entry
	.short 0x0D4F	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x0C	; +0x04 AND mask
	.byte 0x02	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F32A5A	; +0x07 -> XIY: string table
	.short 0x0007	; +0x0B -> BC: bytes per entry
	.short 0x1277	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x30	; +0x04 AND mask
	.byte 0x04	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F32A5A	; +0x07 -> XIY: string table
	.short 0x0007	; +0x0B -> BC: bytes per entry
	.short 0x174F	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0xC0	; +0x04 AND mask
	.byte 0x06	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F32A5A	; +0x07 -> XIY: string table
	.short 0x0007	; +0x0B -> BC: bytes per entry
	.short 0x1C4F	; +0x0D -> IX
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x0D59	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1281	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1759	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1C59	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A3	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F32A87	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
DL_F3294B:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B1	; +0x02 source variable, 16-bit address
	.byte 0x03	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F32A4E	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0D52	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B1	; +0x02 source variable, 16-bit address
	.byte 0x0C	; +0x04 AND mask
	.byte 0x02	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F32A4E	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x127A	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B1	; +0x02 source variable, 16-bit address
	.byte 0x30	; +0x04 AND mask
	.byte 0x04	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F32A4E	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1752	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B1	; +0x02 source variable, 16-bit address
	.byte 0xC0	; +0x04 AND mask
	.byte 0x06	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F32A4E	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1C52	; +0x0D -> IX
DL_F32987:
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A3	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F32AAF	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF32992-0xF32A7C: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x032992, 0x0000EB

; ------------------------------------------------------------------
; 0xF32A7D-0xF32A86 -- 1 display-list records, 10 bytes -- interpreter A
;   entered at: 0xF32A7D
;   ends used:  0xF32A87
; ------------------------------------------------------------------
DL_F32A7D:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x000D
	.short 0x004C
	.short 0x00AC
	.short 0x00C8

; --- 0xF32A87-0xF32AD6: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x032A87, 0x000050

; ------------------------------------------------------------------
; 0xF32AD7-0xF32B1D -- 5 display-list records, 71 bytes -- interpreter B
;   entered at: 0xF32AD7
;   ends used:  0xF32B1E
; ------------------------------------------------------------------
DL_F32AD7:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x2292	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x2298	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x229D	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22A2	; +0x0D -> IX
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A3	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F32B3C	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF32B1E-0xF32B31: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x032B1E, 0x000014

; ------------------------------------------------------------------
; 0xF32B32-0xF32B3B -- 1 display-list records, 10 bytes -- interpreter A
;   entered at: 0xF32B32
;   ends used:  0xF32B3C
; ------------------------------------------------------------------
DL_F32B32:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0008
	.short 0x0049
	.short 0x00FA
	.short 0x00C5

; --- 0xF32B3C-0xF32B63: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x032B3C, 0x000028

; ------------------------------------------------------------------
; 0xF32B64-0xF32B96 -- 5 display-list records, 51 bytes -- interpreter B
;   entered at: 0xF32B64
;   ends used:  0xF32B97
; ------------------------------------------------------------------
DL_F32B64:
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2291	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2297	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x229D	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x22A2	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A3	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F32B3C	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF32B97-0xF32BAA: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x032B97, 0x000014

; ------------------------------------------------------------------
; 0xF32BAB-0xF32C01 -- 7 display-list records, 87 bytes -- interpreter B
;   entered at: 0xF32BAB
;   ends used:  0xF32C02
; ------------------------------------------------------------------
DL_F32BAB:
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x22A6	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x22AC	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x229D	; +0x0D -> IX
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x228D	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2292	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2297	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x27AF	; +0x02 source variable, 16-bit address
	.byte 0x03	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.long 0x00F05182	; +0x07 -> XIY: string table
	.short 0x0008	; +0x0B -> BC: bytes per entry
	.short 0x009D	; +0x0D -> (0x2530)
	.short 0x003E	; +0x0F -> (0x2532)

; --- 0xF32C02-0xF32C29: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x032C02, 0x000028

; ------------------------------------------------------------------
; 0xF32C2A-0xF32FE5 -- 104 display-list records, 956 bytes -- interpreter A (92 records) and B (12)
;   entered at: 0xF32C2A, 0xF32D03, 0xF32D2C, 0xF32E71, 0xF32F43, 0xF32FA0, 0xF32FC8
;   ends used:  0xF32CC8, 0xF32D03, 0xF32D2C, 0xF32E71, 0xF32F43, 0xF32FA0, 0xF32FC8, 0xF32FE6
; ------------------------------------------------------------------
DL_F32C2A:
	.byte 0x1C, 0x10	; op 1C, 16 bytes -> handler 0xF31A52
	.short 0x0072
	.short 0x0005
	.ascii "C0NTR0LLER"
	.byte 0x17, 0x10	; op 17, 16 bytes -> handler 0xF31A52
	.short 0x0006
	.short 0x0007
	.ascii "SOUND EDIT"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x2067
	.ascii "DEPTH"
	.byte 0x06, 0x0C	; op 06, 12 bytes -> handler 0xF31A3A
	.short 0x214B
	.ascii "FUNCTION"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x241E
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2451
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2457
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x245C
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B68
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8F
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1108
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x112F
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x16D0
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x16F7
	.byte 0x11	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0013
	.short 0x00CC
	.short 0x005D
	.short 0x00E7
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0075
	.short 0x00CC
	.short 0x00A4
	.short 0x00E9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0075
	.short 0x00DB
	.short 0x00A4
	.short 0x00DB
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0076
	.short 0x00DC
	.short 0x00A3
	.short 0x00E8
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0004
	.short 0x0004
	.short 0x0044
	.short 0x0010
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x24
	.short 0x000B
	.byte 0x06, 0x13	; op 06, 19 bytes -> handler 0xF31A3A
	.short 0x206F
	.ascii "1st 2nd 3rd 4th"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2461
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2466
	.byte 0x12	; character codes below 0x20
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00B5
	.short 0x00CC
	.short 0x0133
	.short 0x00E9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00B5
	.short 0x00DB
	.short 0x0133
	.short 0x00DB
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x00B6
	.short 0x00DC
	.short 0x0132
	.short 0x00E8
DL_F32D03:
	.byte 0x06, 0x0B	; op 06, 11 bytes -> handler 0xF31A3A
	.short 0x206F
	.ascii "1st 2nd"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00B5
	.short 0x00CC
	.short 0x00F4
	.short 0x00E9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00B5
	.short 0x00DB
	.short 0x00F4
	.short 0x00DB
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x00B6
	.short 0x00DC
	.short 0x00F3
	.short 0x00E8
DL_F32D2C:
	.byte 0x06, 0x0B	; op 06, 11 bytes -> handler 0xF31A3A
	.short 0x0110
	.ascii "PAGE1/2"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0017
	.short 0x0099
	.ascii "1"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0027
	.short 0x0099
	.ascii "2"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0037
	.short 0x0099
	.ascii "3"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0047
	.short 0x0099
	.ascii "4"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0057
	.short 0x0099
	.ascii "5"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0067
	.short 0x0099
	.ascii "6"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00D1
	.short 0x0099
	.ascii "1"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00E1
	.short 0x0099
	.ascii "2"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00F1
	.short 0x0099
	.ascii "3"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0101
	.short 0x0099
	.ascii "4"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0111
	.short 0x0099
	.ascii "5"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0121
	.short 0x0099
	.ascii "6"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000A
	.short 0x0043
	.short 0x007B
	.short 0x005C
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00C5
	.short 0x0043
	.short 0x0136
	.short 0x005C
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000A
	.short 0x0067
	.short 0x007B
	.short 0x0080
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00C5
	.short 0x0067
	.short 0x0136
	.short 0x0080
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0013
	.short 0x0095
	.short 0x0021
	.short 0x00A2
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0023
	.short 0x0095
	.short 0x0031
	.short 0x00A2
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0033
	.short 0x0095
	.short 0x0041
	.short 0x00A2
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0043
	.short 0x0095
	.short 0x0051
	.short 0x00A2
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0053
	.short 0x0095
	.short 0x0061
	.short 0x00A2
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0063
	.short 0x0095
	.short 0x0071
	.short 0x00A2
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x0095
	.short 0x00DB
	.short 0x00A2
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00DD
	.short 0x0095
	.short 0x00EB
	.short 0x00A2
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00ED
	.short 0x0095
	.short 0x00FB
	.short 0x00A2
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00FD
	.short 0x0095
	.short 0x010B
	.short 0x00A2
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x010D
	.short 0x0095
	.short 0x011B
	.short 0x00A2
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x0095
	.short 0x012B
	.short 0x00A2
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x49
	.short 0x1079
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x24
	.short 0x107D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007B
	.short 0x004F
	.short 0x0094
	.short 0x004F
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00B3
	.short 0x004F
	.short 0x00C5
	.short 0x004F
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007B
	.short 0x0073
	.short 0x0087
	.short 0x0073
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00BF
	.short 0x0073
	.short 0x00C5
	.short 0x0073
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0094
	.short 0x004F
	.short 0x0094
	.short 0x0068
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00B3
	.short 0x004F
	.short 0x00B3
	.short 0x0068
DL_F32E71:
	.byte 0x06, 0x0B	; op 06, 11 bytes -> handler 0xF31A3A
	.short 0x0110
	.ascii "PAGE2/2"
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x0557
	.ascii "__"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0001
	.short 0x0024
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x0A57
	.ascii "__"
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x0FA7
	.ascii "__"
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x14A7
	.ascii "__"
	.byte 0x17, 0x11	; op 17, 17 bytes -> handler 0xF31A52
	.short 0x000A
	.short 0x009D
	.ascii "AFTER TOUCH"
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x1A1F
	.ascii "__"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0001
	.short 0x00B4
	.byte 0x10	; character codes below 0x20
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0135
	.short 0x00B4
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x10	; op 17, 16 bytes -> handler 0xF31A52
	.short 0x000B
	.short 0x00C1
	.ascii "CTRL PEDAL"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x004B
	.short 0x0023
	.short 0x00BC
	.short 0x0036
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x004B
	.short 0x0043
	.short 0x012C
	.short 0x0056
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x004B
	.short 0x0065
	.short 0x012C
	.short 0x0078
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x004B
	.short 0x0085
	.short 0x012C
	.short 0x0098
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x004B
	.short 0x00A8
	.short 0x012C
	.short 0x00BB
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00BC
	.short 0x0043
	.short 0x00BC
	.short 0x0056
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00BC
	.short 0x0065
	.short 0x00BC
	.short 0x0078
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00BC
	.short 0x0085
	.short 0x00BC
	.short 0x0098
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00BC
	.short 0x00A8
	.short 0x00BC
	.short 0x00BB
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x5B
	.short 0x0553
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x5C
	.short 0x0A53
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x5D
	.short 0x0FA3
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x39
	.short 0x14A3
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x2D
	.short 0x19F3
DL_F32F43:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F33022	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x0BBA	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F33022	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x115A	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F33022	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x0BD1	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F33022	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x1171	; +0x0D -> IX
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F33394	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27B4	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F333BC	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27B5	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F333EC	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
DL_F32FA0:
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27B1	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2298	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B2	; +0x02 source variable, 16-bit address
	.byte 0x03	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F33016	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x229F	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B2	; +0x02 source variable, 16-bit address
	.byte 0x0C	; +0x04 AND mask
	.byte 0x02	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F33016	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22A3	; +0x0D -> IX
DL_F32FC8:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B2	; +0x02 source variable, 16-bit address
	.byte 0x30	; +0x04 AND mask
	.byte 0x04	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F33016	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22A7	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B2	; +0x02 source variable, 16-bit address
	.byte 0xC0	; +0x04 AND mask
	.byte 0x06	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F33016	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22AB	; +0x0D -> IX

; --- 0xF32FE6-0xF33361: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x032FE6, 0x00037C

; ------------------------------------------------------------------
; 0xF33362-0xF33393 -- 5 display-list records, 50 bytes -- interpreter A
;   entered at: 0xF33362, 0xF3338A
;   ends used:  0xF3338A, 0xF33394
; ------------------------------------------------------------------
DL_F33362:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0044
	.short 0x0079
	.short 0x005A
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x00C6
	.short 0x0044
	.short 0x0134
	.short 0x005A
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0068
	.short 0x0079
	.short 0x007E
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x00C7
	.short 0x0069
	.short 0x0134
	.short 0x007E
DL_F3338A:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0015
	.short 0x0097
	.short 0x0129
	.short 0x00A0

; --- 0xF33394-0xF3341B: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x033394, 0x000088

; ------------------------------------------------------------------
; 0xF3341C-0xF334AD -- 10 display-list records, 146 bytes -- interpreter B
;   entered at: 0xF3341C
;   ends used:  0xF334AE
; ------------------------------------------------------------------
DL_F3341C:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F33022	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x064A	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F33022	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x0B4A	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F33022	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x0B58	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F33022	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x109A	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F33022	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x10A8	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AC	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F33022	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x1B12	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AD	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F33022	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x1B20	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AE	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F33022	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x159A	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AF	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F33022	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x15A8	; +0x0D -> IX
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F334AE	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF334AE-0xF334FD: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0334AE, 0x000050

; ------------------------------------------------------------------
; 0xF334FE-0xF33507 -- 1 display-list records, 10 bytes -- interpreter A
;   entered at: 0xF334FE
;   ends used:  0xF33508
; ------------------------------------------------------------------
DL_F334FE:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x004C
	.short 0x0024
	.short 0x012B
	.short 0x00BA

; --- 0xF33508-0xF33537: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x033508, 0x000030

; ------------------------------------------------------------------
; 0xF33538-0xF3356A -- 3 display-list records, 51 bytes -- interpreter B
;   entered at: 0xF33538
;   ends used:  0xF3356B
; ------------------------------------------------------------------
DL_F33538:
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1C	; +0x06 swi 7 function
	.long 0x00F05B60	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0020	; +0x0D -> (0x2530)
	.short 0x00D6	; +0x0F -> (0x2532)
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1C	; +0x06 swi 7 function
	.long 0x00F04CBD	; +0x07 -> XIY: string table
	.short 0x0001	; +0x0B -> BC: bytes per entry
	.short 0x0058	; +0x0D -> (0x2530)
	.short 0x00D6	; +0x0F -> (0x2532)
	.byte 0x07, 0x11	; B op 07, 17 bytes -> handler 0xF31B39 -- string-table readout with two extra words
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1C	; +0x06 swi 7 function
	.long 0x000022F0	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x0070	; +0x0D -> (0x2530)
	.short 0x00D6	; +0x0F -> (0x2532)

; --- 0xF3356B-0xF33572: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03356B, 0x000008

; ------------------------------------------------------------------
; 0xF33573-0xF3380D -- 69 display-list records, 667 bytes -- interpreter A (58 records) and B (11)
;   entered at: 0xF33573, 0xF336CE, 0xF33796
;   ends used:  0xF336CE, 0xF33796, 0xF337EF, 0xF3380E
; ------------------------------------------------------------------
DL_F33573:
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0031
	.short 0x003E
	.ascii "DELAY"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0059
	.short 0x003E
	.ascii "LEVEL"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0083
	.short 0x003E
	.ascii "TOUCH"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00AB
	.short 0x003E
	.ascii "CURVE"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x0C30
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x11F8
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x10	; op 17, 16 bytes -> handler 0xF31A52
	.short 0x00F7
	.short 0x00C2
	.ascii "GROUP DUMP"
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x00F0
	.short 0x00CF
	.ascii "ON/OFF"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x011B
	.short 0x00CF
	.ascii "GROUP"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x002C
	.short 0x00D1
	.ascii "DELAY"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0056
	.short 0x00D1
	.ascii "LEVEL"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x007C
	.short 0x00D1
	.ascii "TOUCH"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00A5
	.short 0x00D1
	.ascii "CURVE"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21EF
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F4
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F9
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21FE
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x237F
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2384
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2389
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x238E
	.byte 0x8E	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2438
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x243D
	.byte 0x12	; character codes below 0x20
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0038
	.short 0x00D4
	.short 0x008A
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00EC
	.short 0x00CB
	.short 0x013C
	.short 0x00E8
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00DA
	.short 0x0046
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00DA
	.short 0x006E
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00DA
	.short 0x0096
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00DA
	.short 0x00BE
	.short 0x00EE
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x004A
	.short 0x00D4
	.short 0x004A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x006A
	.short 0x00D4
	.short 0x006A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00EC
	.short 0x00D9
	.short 0x013C
	.short 0x00D9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00E4
	.short 0x0046
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0059
	.short 0x00E4
	.short 0x006E
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00E4
	.short 0x0096
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00E4
	.short 0x00BE
	.short 0x00E4
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x002C
	.short 0x0038
	.short 0x002C
	.short 0x008A
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x0043
	.short 0x0132
	.short 0x005C
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x00ED
	.short 0x00DA
	.short 0x013B
	.short 0x00E7
DL_F336CE:
	.byte 0x06, 0x13	; op 06, 19 bytes -> handler 0xF31A3A
	.short 0x1D60
	.byte 0x10	; character codes below 0x20
	.ascii "KEY OFF MODE :"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x010B
	.short 0x00C2
	.ascii "TOUCH"
	.byte 0x17, 0x2C	; op 17, 44 bytes -> handler 0xF31A52
	.short 0x0009
	.short 0x00CF
	.ascii "ATK  DECAY1 SUST1 DECAY2 SUST2 RELEASE"
	.byte 0x17, 0x10	; op 17, 16 bytes -> handler 0xF31A52
	.short 0x00FE
	.short 0x00CF
	.ascii "ATK  DECAY"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x241A
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x241F
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2424
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2429
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x242E
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2433
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x2439
	.byte 0x12	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x243E
	.byte 0x12	; character codes below 0x20
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0003
	.short 0x00CB
	.short 0x00F1
	.short 0x00E8
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00FA
	.short 0x00CB
	.short 0x013E
	.short 0x00E8
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0003
	.short 0x00D9
	.short 0x00F1
	.short 0x00D9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00FA
	.short 0x00D9
	.short 0x013E
	.short 0x00D9
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0004
	.short 0x00DA
	.short 0x00F0
	.short 0x00E7
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x00FB
	.short 0x00DA
	.short 0x013D
	.short 0x00E7
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x0027
	.short 0x0132
	.short 0x0034
DL_F33796:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x80	; +0x04 AND mask
	.byte 0x07	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F034D8	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x227F	; +0x0D -> IX
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2284	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x0D59	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1259	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AC	; +0x02 source variable, 16-bit address
	.byte 0xE0	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x0D5F	; +0x07 -> IX
	.byte 0x01	; +0x09 digit count
	.byte 0x03	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AD	; +0x02 source variable, 16-bit address
	.byte 0xE0	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x125F	; +0x07 -> IX
	.byte 0x01	; +0x09 digit count
	.byte 0x03	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AE	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x0D4F	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AF	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x124F	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x0D53	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x1253	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A3	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F33840	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF3380E-0xF33835: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03380E, 0x000028

; ------------------------------------------------------------------
; 0xF33836-0xF3383F -- 1 display-list records, 10 bytes -- interpreter A
;   entered at: 0xF33836
;   ends used:  0xF33840
; ------------------------------------------------------------------
DL_F33836:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x000D
	.short 0x004C
	.short 0x00D2
	.short 0x0088

; --- 0xF33840-0xF33857: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x033840, 0x000018

; ------------------------------------------------------------------
; 0xF33858-0xF338A4 -- 7 display-list records, 77 bytes -- interpreter B
;   entered at: 0xF33858
;   ends used:  0xF338A5
; ------------------------------------------------------------------
DL_F33858:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x20	; +0x04 AND mask
	.byte 0x05	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F034D2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1D70	; +0x0D -> IX
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2261	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2265	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x226A	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x226F	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AD	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2280	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x27AE	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2284	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed

; --- 0xF338A5-0xF338C8: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0338A5, 0x000024

; ------------------------------------------------------------------
; 0xF338C9-0xF3391D -- 8 display-list records, 85 bytes -- interpreter A (2 records) and B (6)
;   entered at: 0xF338C9, 0xF338DD, 0xF338EB, 0xF338F6
;   ends used:  0xF338DD, 0xF338EB, 0xF338F6, 0xF3391E
; ------------------------------------------------------------------
DL_F338C9:
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x2274	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27AC	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x227A	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
DL_F338DD:
	.byte 0x20, 0x07	; op 20, 7 bytes -> handler 0xF31A3A
	.short 0x2274
	.ascii " --"
	.byte 0x20, 0x07	; op 20, 7 bytes -> handler 0xF31A3A
	.short 0x227A
	.ascii " --"
DL_F338EB:
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A6	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F33A49	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
DL_F338F6:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27AE	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F0574D	; +0x07 -> XIY: string table
	.short 0x0002	; +0x0B -> BC: bytes per entry
	.short 0x12A0	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x000022F0	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x12A2	; +0x0D -> IX
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x27A7	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x12B4	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663

; --- 0xF3391E-0xF339B3: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03391E, 0x000096

; ------------------------------------------------------------------
; 0xF339B4-0xF339BB -- 1 display-list records, 8 bytes -- interpreter A
;   entered at: 0xF339B4
;   ends used:  0xF339BC
; ------------------------------------------------------------------
DL_F339B4:
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x12B0
	.ascii "  0-"

; --- 0xF339BC-0xF33A3E: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0339BC, 0x000083

; ------------------------------------------------------------------
; 0xF33A3F-0xF33A48 -- 1 display-list records, 10 bytes -- interpreter A
;   entered at: 0xF33A3F
;   ends used:  0xF33A49
; ------------------------------------------------------------------
DL_F33A3F:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x003D
	.short 0x0076
	.short 0x00FC
	.short 0x00B4

; --- 0xF33A49-0xF33A70: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x033A49, 0x000028

; ------------------------------------------------------------------
; 0xF33A71-0xF33B8B -- 21 display-list records, 283 bytes -- interpreter B
;   entered at: 0xF33A71, 0xF33B09, 0xF33B81
;   ends used:  0xF33ABD, 0xF33B45, 0xF33B8C
; ------------------------------------------------------------------
DL_F33A71:
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x27A8	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00B4	; +0x07 -> (0x2530)
	.short 0x0057	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
	.byte 0x0B, 0x0D	; B op 0B, 13 bytes -> handler 0xF31C56 -- decimal readout, signed, two extra words
	.short 0x27A9	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00D2	; +0x07 -> (0x2530)
	.short 0x0057	; +0x09 -> (0x2532)
	.byte 0x02	; +0x0B digit count
	.byte 0x00	; +0x0C bit 7 set = unsigned, clear = signed
	.byte 0x0B, 0x0D	; B op 0B, 13 bytes -> handler 0xF31C56 -- decimal readout, signed, two extra words
	.short 0x27AA	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00EA	; +0x07 -> (0x2530)
	.short 0x0057	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
	.byte 0x00	; +0x0C bit 7 set = unsigned, clear = signed
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x27AB	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00B4	; +0x07 -> (0x2530)
	.short 0x0077	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
	.byte 0x0B, 0x0D	; B op 0B, 13 bytes -> handler 0xF31C56 -- decimal readout, signed, two extra words
	.short 0x27AC	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00D2	; +0x07 -> (0x2530)
	.short 0x0077	; +0x09 -> (0x2532)
	.byte 0x02	; +0x0B digit count
	.byte 0x00	; +0x0C bit 7 set = unsigned, clear = signed
	.byte 0x0B, 0x0D	; B op 0B, 13 bytes -> handler 0xF31C56 -- decimal readout, signed, two extra words
	.short 0x27AD	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00EA	; +0x07 -> (0x2530)
	.short 0x0077	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
	.byte 0x00	; +0x0C bit 7 set = unsigned, clear = signed
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x27AE	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00B4	; +0x07 -> (0x2530)
	.short 0x0097	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
	.byte 0x0B, 0x0D	; B op 0B, 13 bytes -> handler 0xF31C56 -- decimal readout, signed, two extra words
	.short 0x27AF	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00D2	; +0x07 -> (0x2530)
	.short 0x0097	; +0x09 -> (0x2532)
	.byte 0x02	; +0x0B digit count
	.byte 0x00	; +0x0C bit 7 set = unsigned, clear = signed
	.byte 0x0B, 0x0D	; B op 0B, 13 bytes -> handler 0xF31C56 -- decimal readout, signed, two extra words
	.short 0x27B0	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00EA	; +0x07 -> (0x2530)
	.short 0x0097	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
	.byte 0x00	; +0x0C bit 7 set = unsigned, clear = signed
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x27B1	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00B4	; +0x07 -> (0x2530)
	.short 0x00B7	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
	.byte 0x0B, 0x0D	; B op 0B, 13 bytes -> handler 0xF31C56 -- decimal readout, signed, two extra words
	.short 0x27B2	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00D2	; +0x07 -> (0x2530)
	.short 0x00B7	; +0x09 -> (0x2532)
	.byte 0x02	; +0x0B digit count
	.byte 0x00	; +0x0C bit 7 set = unsigned, clear = signed
	.byte 0x0B, 0x0D	; B op 0B, 13 bytes -> handler 0xF31C56 -- decimal readout, signed, two extra words
	.short 0x27B3	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00EA	; +0x07 -> (0x2530)
	.short 0x00B7	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
	.byte 0x00	; +0x0C bit 7 set = unsigned, clear = signed
DL_F33B09:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B4	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F04CBD	; +0x07 -> XIY: string table
	.short 0x0001	; +0x0B -> BC: bytes per entry
	.short 0x0D4E	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x000022F0	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x0D50	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B5	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F04CBD	; +0x07 -> XIY: string table
	.short 0x0001	; +0x0B -> BC: bytes per entry
	.short 0x124E	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00002300	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x1250	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B6	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F04CBD	; +0x07 -> XIY: string table
	.short 0x0001	; +0x0B -> BC: bytes per entry
	.short 0x174E	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00002310	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x1750	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x27B7	; +0x02 source variable, 16-bit address
	.byte 0x3F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F04CBD	; +0x07 -> XIY: string table
	.short 0x0001	; +0x0B -> BC: bytes per entry
	.short 0x1C4E	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00002320	; +0x07 -> XIY: string table
	.short 0x000D	; +0x0B -> BC: bytes per entry
	.short 0x1C50	; +0x0D -> IX
DL_F33B81:
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x27A3	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F04CE8	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF33B8C-0xF33BD7: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x033B8C, 0x00004C

; ------------------------------------------------------------------
; 0xF33BD8-0xF33F00 -- 96 display-list records, 809 bytes -- interpreter A
;   entered at: 0xF33BD8
;   ends used:  0xF33F01
; ------------------------------------------------------------------
DL_F33BD8:
	.byte 0x1C, 0x0E	; op 1C, 14 bytes -> handler 0xF31A52
	.short 0x0070
	.short 0x0009
	.ascii "User Kit"
	.byte 0x17, 0x10	; op 17, 16 bytes -> handler 0xF31A52
	.short 0x0006
	.short 0x0007
	.ascii "SOUND EDIT"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0136
	.short 0x001F
	.byte 0x91	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x054C
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x059F
	.byte 0xA9	; character codes below 0x20
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x005E
	.short 0x0035
	.ascii ":"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x0115
	.short 0x0038
	.ascii "SOUND"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0136
	.short 0x0046
	.byte 0x91	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8C
	.byte 0x8E	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0BB7
	.byte 0xA9	; character codes below 0x20
	.byte 0x17, 0x11	; op 17, 17 bytes -> handler 0xF31A52
	.short 0x0047
	.short 0x0064
	.ascii "TONE SELECT"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x00A2
	.short 0x0064
	.ascii "LEVEL"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00C7
	.short 0x0064
	.ascii "KEY"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00E1
	.short 0x0064
	.ascii "TUNE"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0102
	.short 0x0064
	.ascii "PAN"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x011D
	.short 0x0064
	.ascii "REV"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x11D0
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0044
	.short 0x0076
	.ascii "."
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0043
	.short 0x007B
	.byte 0x91	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0044
	.short 0x0094
	.ascii "."
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x17E8
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0043
	.short 0x0099
	.byte 0x91	; character codes below 0x20
	.byte 0x06, 0x0F	; op 06, 15 bytes -> handler 0xF31A3A
	.short 0x1D53
	.ascii "DETAIL EDIT"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1DB0
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1DD7
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x0C	; op 17, 12 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x00D1
	.ascii "ON/OFF"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x002B
	.short 0x00D1
	.ascii "GROUP"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0050
	.short 0x00D1
	.ascii "TONE"
	.byte 0x17, 0x0B	; op 17, 11 bytes -> handler 0xF31A52
	.short 0x007D
	.short 0x00D1
	.ascii "LEVEL"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x00AA
	.short 0x00D1
	.ascii "KEY"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00CF
	.short 0x00D1
	.ascii "TUNE"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x0102
	.short 0x00D1
	.ascii "PAN"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x012B
	.short 0x00D1
	.ascii "REV"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21E9
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21EF
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F3
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21F9
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x21FE
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2203
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2209
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x220E
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2379
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x237F
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2383
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2389
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x238E
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2393
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2399
	.byte 0x8E	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x239E
	.byte 0x8E	; character codes below 0x20
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0004
	.short 0x0004
	.short 0x0044
	.short 0x0010
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0112
	.short 0x001E
	.short 0x0135
	.short 0x0031
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x0020
	.short 0x0133
	.short 0x002F
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0037
	.short 0x002E
	.short 0x00FD
	.short 0x0049
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0039
	.short 0x0030
	.short 0x00FB
	.short 0x0047
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0112
	.short 0x0045
	.short 0x0135
	.short 0x0058
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x0047
	.short 0x0133
	.short 0x0056
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x005E
	.short 0x0135
	.short 0x00AA
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00D2
	.short 0x00B5
	.short 0x0135
	.short 0x00CA
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00D4
	.short 0x00B7
	.short 0x0133
	.short 0x00C8
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0001
	.short 0x00DA
	.short 0x0016
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00DA
	.short 0x0046
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0051
	.short 0x00DA
	.short 0x0066
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00DA
	.short 0x0096
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00DA
	.short 0x00BE
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00DA
	.short 0x00E6
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0101
	.short 0x00DA
	.short 0x0116
	.short 0x00EE
	.byte 0x22, 0x0A	; op 22, 10 bytes -> handler 0xF31A75
	.short 0x0129
	.short 0x00DA
	.short 0x013E
	.short 0x00EE
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x006F
	.short 0x0135
	.short 0x006F
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x008C
	.short 0x0119
	.short 0x008C
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0001
	.short 0x00E4
	.short 0x0016
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0031
	.short 0x00E4
	.short 0x0046
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0051
	.short 0x00E4
	.short 0x0066
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0081
	.short 0x00E4
	.short 0x0096
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A9
	.short 0x00E4
	.short 0x00BE
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00D1
	.short 0x00E4
	.short 0x00E6
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0101
	.short 0x00E4
	.short 0x0116
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0129
	.short 0x00E4
	.short 0x013E
	.short 0x00E4
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0038
	.short 0x005E
	.short 0x0038
	.short 0x00AA
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x009D
	.short 0x005E
	.short 0x009D
	.short 0x00AA
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0119
	.short 0x005E
	.short 0x0119
	.short 0x00AA
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0003
	.short 0x001F
	.byte 0x91	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x052B
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0578
	.byte 0xA8	; character codes below 0x20
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0010
	.short 0x0038
	.ascii "NOTE"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0003
	.short 0x0046
	.byte 0x91	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B6B
	.byte 0x8E	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B90
	.byte 0xA8	; character codes below 0x20
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x1D3A
	.ascii "WRITE"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1DB0
	.byte 0x10	; character codes below 0x20
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x001E
	.short 0x002E
	.short 0x0031
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000D
	.short 0x0020
	.short 0x002C
	.short 0x002F
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0045
	.short 0x002E
	.short 0x0058
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000D
	.short 0x0047
	.short 0x002C
	.short 0x0056
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x00B5
	.short 0x003D
	.short 0x00CA
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000D
	.short 0x00B7
	.short 0x003B
	.short 0x00C8
	.byte 0x05, 0x0A	; op 05, 10 bytes -> handler 0xF31A75
	.short 0x011B
	.short 0x0071
	.short 0x0133
	.short 0x00A8

; --- 0xF33F01-0xF341B5: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x033F01, 0x0002B5

; ------------------------------------------------------------------
; 0xF341B6-0xF34255 -- 16 display-list records, 160 bytes -- interpreter A
;   entered at: 0xF341B6
;   ends used:  0xF34256
; ------------------------------------------------------------------
DL_F341B6:
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00A0
	.short 0x0022
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00A0
	.short 0x004A
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00A0
	.short 0x0072
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00A0
	.short 0x009A
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00A0
	.short 0x00C2
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00A0
	.short 0x00EA
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00A0
	.short 0x0112
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00A0
	.short 0x013A
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00CF
	.short 0x0022
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00CF
	.short 0x004A
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00CF
	.short 0x0072
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00CF
	.short 0x009A
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00CF
	.short 0x00C2
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00CF
	.short 0x00EA
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00CF
	.short 0x0112
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00CF
	.short 0x013A
	.short 0x00E9

; --- 0xF34256-0xF34360: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x034256, 0x00010B

; ------------------------------------------------------------------
; 0xF34361-0xF343B5 -- 7 display-list records, 85 bytes -- interpreter B
;   entered at: 0xF34361, 0xF3437F, 0xF343A2
;   ends used:  0xF3438E, 0xF343AC, 0xF343B6
; ------------------------------------------------------------------
DL_F34361:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x2648	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F343B6	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0573	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x2647	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F349BB	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0BB3	; +0x0D -> IX
DL_F3437F:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1309	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F349C1	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0B2C	; +0x0D -> IX
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x264B	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x013C	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x2644	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x053E	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
DL_F343A2:
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x2646	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x0887	; +0x07 -> IX
	.byte 0x01	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x2649	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x0EC5	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663

; --- 0xF343B6-0xF343BB: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0343B6, 0x000006

; ------------------------------------------------------------------
; 0xF343BC-0xF34967 -- 170 display-list records, 1452 bytes -- interpreter A
;   entered at: 0xF343BC, 0xF34681
;   ends used:  0xF34681, 0xF34968
; ------------------------------------------------------------------
DL_F343BC:
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x32
	.short 0x002D
	.byte 0x1C, 0x15	; op 1C, 21 bytes -> handler 0xF31A52
	.short 0x0048
	.short 0x0005
	.ascii "REALTIME RECORD"
	.byte 0x20, 0x08	; op 20, 8 bytes -> handler 0xF31A3A
	.short 0x0138
	.ascii "SONG"
	.byte 0x07, 0x0E	; op 07, 14 bytes -> handler 0xF31A3A
	.short 0x0534
	.ascii "MEASURE = "
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x0571
	.byte 0x87	; character codes below 0x20
	.byte 0x20, 0x05	; op 20, 5 bytes -> handler 0xF31A3A
	.short 0x0572
	.ascii " "
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0577
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0578
	.byte 0x10	; character codes below 0x20
	.byte 0x20, 0x0A	; op 20, 10 bytes -> handler 0xF31A3A
	.short 0x05CA
	.ascii "QUANTI"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x05D0
	.ascii "Z"
	.byte 0x20, 0x05	; op 20, 5 bytes -> handler 0xF31A3A
	.short 0x05D1
	.ascii "E"
	.byte 0x07, 0x0F	; op 07, 15 bytes -> handler 0xF31A3A
	.short 0x087C
	.ascii "TIME SIG.= "
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x0888
	.ascii "/4"
	.byte 0x07, 0x0C	; op 07, 12 bytes -> handler 0xF31A3A
	.short 0x0B24
	.ascii "(MASTER:"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B2F
	.ascii ")"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8F
	.byte 0x11	; character codes below 0x20
	.byte 0x20, 0x0A	; op 20, 10 bytes -> handler 0xF31A3A
	.short 0x0BAD
	.ascii "CYCLE:"
	.byte 0x07, 0x0D	; op 07, 13 bytes -> handler 0xF31A3A
	.short 0x0EBD
	.ascii "MEMORY = "
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x0EC8
	.ascii " %"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1158
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11A5
	.ascii "."
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11A7
	.byte 0x11	; character codes below 0x20
	.byte 0x20, 0x09	; op 20, 9 bytes -> handler 0xF31A3A
	.short 0x11AA
	.ascii "MIXER"
	.byte 0x20, 0x0C	; op 20, 12 bytes -> handler 0xF31A3A
	.short 0x11ED
	.ascii "TIME SIG"
	.byte 0x08, 0x06	; op 08, 6 bytes -> handler 0xF31A3A
	.short 0x127D
	.byte 0x15	; character codes below 0x20
	.ascii "="
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1952
	.ascii "1"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1957
	.ascii "2"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x195C
	.ascii "3"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1961
	.ascii "4"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1966
	.ascii "5"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x196B
	.ascii "6"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1970
	.ascii "7"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1975
	.ascii "8"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x20AA
	.ascii "9"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20AF
	.ascii "10"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20B4
	.ascii "11"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20B9
	.ascii "12"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20BE
	.ascii "13"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20C3
	.ascii "14"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20C8
	.ascii "15"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20CD
	.ascii "16"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00A0
	.short 0x0022
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00A0
	.short 0x004A
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00A0
	.short 0x0072
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00A0
	.short 0x009A
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00A0
	.short 0x00C2
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00A0
	.short 0x00EA
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00A0
	.short 0x0112
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00A0
	.short 0x013A
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00CF
	.short 0x0022
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00CF
	.short 0x004A
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00CF
	.short 0x0072
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00CF
	.short 0x009A
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00CF
	.short 0x00C2
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00CF
	.short 0x00EA
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00CF
	.short 0x0112
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00CF
	.short 0x013A
	.short 0x00E9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00AD
	.short 0x0024
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00AD
	.short 0x004C
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00AD
	.short 0x0074
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00AD
	.short 0x009C
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00AD
	.short 0x00C4
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00AD
	.short 0x00EC
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00AD
	.short 0x0114
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00AD
	.short 0x013C
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00DC
	.short 0x0024
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00DC
	.short 0x004C
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00DC
	.short 0x0074
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00DC
	.short 0x009C
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00DC
	.short 0x00C4
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00DC
	.short 0x00EC
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00DC
	.short 0x0114
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00DC
	.short 0x013C
	.short 0x00DC
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00FF
	.short 0x001D
	.short 0x0134
	.short 0x0030
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0101
	.short 0x001F
	.short 0x0132
	.short 0x002E
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000A
	.short 0x0020
	.short 0x0056
	.short 0x0033
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x0022
	.short 0x0054
	.short 0x0031
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00E3
	.short 0x0045
	.short 0x0135
	.short 0x0058
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00E5
	.short 0x0047
	.short 0x0133
	.short 0x0056
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000A
	.short 0x006C
	.short 0x003E
	.short 0x007F
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00E4
	.short 0x006D
	.short 0x0134
	.short 0x0080
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x006E
	.short 0x003C
	.short 0x007D
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00E6
	.short 0x006F
	.short 0x0132
	.short 0x007E
DL_F34681:
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x32
	.short 0x002D
	.byte 0x1C, 0x15	; op 1C, 21 bytes -> handler 0xF31A52
	.short 0x0048
	.short 0x0005
	.ascii "REALTIME RECORD"
	.byte 0x20, 0x08	; op 20, 8 bytes -> handler 0xF31A3A
	.short 0x0138
	.ascii "SONG"
	.byte 0x07, 0x0E	; op 07, 14 bytes -> handler 0xF31A3A
	.short 0x0534
	.ascii "MEASURE = "
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x0571
	.byte 0x87	; character codes below 0x20
	.byte 0x20, 0x05	; op 20, 5 bytes -> handler 0xF31A3A
	.short 0x0572
	.ascii " "
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0577
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0578
	.byte 0x10	; character codes below 0x20
	.byte 0x20, 0x0A	; op 20, 10 bytes -> handler 0xF31A3A
	.short 0x05CA
	.ascii "QUANTI"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x05D0
	.ascii "Z"
	.byte 0x20, 0x05	; op 20, 5 bytes -> handler 0xF31A3A
	.short 0x05D1
	.ascii "E"
	.byte 0x07, 0x0F	; op 07, 15 bytes -> handler 0xF31A3A
	.short 0x087C
	.ascii "TIME SIG.= "
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x0888
	.ascii "/4"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B18
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x0C	; op 07, 12 bytes -> handler 0xF31A3A
	.short 0x0B24
	.ascii "(MASTER:"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B2F
	.ascii ")"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8F
	.byte 0x11	; character codes below 0x20
	.byte 0x20, 0x09	; op 20, 9 bytes -> handler 0xF31A3A
	.short 0x0B92
	.ascii "CLEAR"
	.byte 0x20, 0x0A	; op 20, 10 bytes -> handler 0xF31A3A
	.short 0x0BAD
	.ascii "CYCLE:"
	.byte 0x07, 0x0D	; op 07, 13 bytes -> handler 0xF31A3A
	.short 0x0EBD
	.ascii "MEMORY = "
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x0EC8
	.ascii " %"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1158
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11A5
	.ascii "."
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11A7
	.byte 0x11	; character codes below 0x20
	.byte 0x20, 0x09	; op 20, 9 bytes -> handler 0xF31A3A
	.short 0x11AA
	.ascii "MIXER"
	.byte 0x20, 0x0C	; op 20, 12 bytes -> handler 0xF31A3A
	.short 0x11ED
	.ascii "TIME SIG"
	.byte 0x08, 0x06	; op 08, 6 bytes -> handler 0xF31A3A
	.short 0x127D
	.byte 0x15	; character codes below 0x20
	.ascii "="
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1952
	.ascii "1"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1957
	.ascii "2"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x195C
	.ascii "3"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1961
	.ascii "4"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1966
	.ascii "5"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x196B
	.ascii "6"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1970
	.ascii "7"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1975
	.ascii "8"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x20AA
	.ascii "9"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20AF
	.ascii "10"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20B4
	.ascii "11"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20B9
	.ascii "12"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20BE
	.ascii "13"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20C3
	.ascii "14"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20C8
	.ascii "15"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20CD
	.ascii "16"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00A0
	.short 0x0022
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00A0
	.short 0x004A
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00A0
	.short 0x0072
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00A0
	.short 0x009A
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00A0
	.short 0x00C2
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00A0
	.short 0x00EA
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00A0
	.short 0x0112
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00A0
	.short 0x013A
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00CF
	.short 0x0022
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00CF
	.short 0x004A
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00CF
	.short 0x0072
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00CF
	.short 0x009A
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00CF
	.short 0x00C2
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00CF
	.short 0x00EA
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00CF
	.short 0x0112
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00CF
	.short 0x013A
	.short 0x00E9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00AD
	.short 0x0024
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00AD
	.short 0x004C
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00AD
	.short 0x0074
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00AD
	.short 0x009C
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00AD
	.short 0x00C4
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00AD
	.short 0x00EC
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00AD
	.short 0x0114
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00AD
	.short 0x013C
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00DC
	.short 0x0024
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00DC
	.short 0x004C
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00DC
	.short 0x0074
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00DC
	.short 0x009C
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00DC
	.short 0x00C4
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00DC
	.short 0x00EC
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00DC
	.short 0x0114
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00DC
	.short 0x013C
	.short 0x00DC
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00FF
	.short 0x001D
	.short 0x0134
	.short 0x0030
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0101
	.short 0x001F
	.short 0x0132
	.short 0x002E
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000A
	.short 0x0020
	.short 0x0056
	.short 0x0033
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x0022
	.short 0x0054
	.short 0x0031
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000A
	.short 0x0043
	.short 0x003E
	.short 0x0059
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x0045
	.short 0x003C
	.short 0x0057
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00E3
	.short 0x0045
	.short 0x0135
	.short 0x0058
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00E5
	.short 0x0047
	.short 0x0133
	.short 0x0056
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000A
	.short 0x006C
	.short 0x003E
	.short 0x007F
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00E4
	.short 0x006D
	.short 0x0134
	.short 0x0080
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x006E
	.short 0x003C
	.short 0x007D
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00E6
	.short 0x006F
	.short 0x0132
	.short 0x007E

; --- 0xF34968-0xF3496F: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x034968, 0x000008

; ------------------------------------------------------------------
; 0xF34970-0xF349BA -- 6 display-list records, 75 bytes -- interpreter B
;   entered at: 0xF34970
;   ends used:  0xF349BB
; ------------------------------------------------------------------
DL_F34970:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x2647	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F349BB	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0573	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1309	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F349C1	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x11A3	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x0000264C	; +0x07 -> XIY: string table
	.short 0x0006	; +0x0B -> BC: bytes per entry
	.short 0x0160	; +0x0D -> IX
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x264B	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.short 0x015D	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x2644	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x0656	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x2646	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x0ADF	; +0x07 -> IX
	.byte 0x01	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663

; --- 0xF349BB-0xF349C6: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0349BB, 0x00000C

; ------------------------------------------------------------------
; 0xF349C7-0xF34C6D -- 79 display-list records, 679 bytes -- interpreter A
;   entered at: 0xF349C7
;   ends used:  0xF34C6E
; ------------------------------------------------------------------
DL_F349C7:
	.byte 0x1C, 0x14	; op 1C, 20 bytes -> handler 0xF31A52
	.short 0x0015
	.short 0x0005
	.ascii "SEQUENCER PLAY"
	.byte 0x20, 0x08	; op 20, 8 bytes -> handler 0xF31A3A
	.short 0x0159
	.ascii "S0NG"
	.byte 0x20, 0x05	; op 20, 5 bytes -> handler 0xF31A3A
	.short 0x015F
	.ascii ":"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x054F
	.byte 0x11	; character codes below 0x20
	.byte 0x20, 0x0A	; op 20, 10 bytes -> handler 0xF31A3A
	.short 0x056D
	.ascii "CYCLE:"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x057B
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x05A0
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x0E	; op 07, 14 bytes -> handler 0xF31A3A
	.short 0x064C
	.ascii "MEASURE = "
	.byte 0x20, 0x08	; op 20, 8 bytes -> handler 0xF31A3A
	.short 0x089A
	.ascii "MEAS"
	.byte 0x07, 0x0F	; op 07, 15 bytes -> handler 0xF31A3A
	.short 0x0AD4
	.ascii "TIME SIG.= "
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x0AE0
	.ascii "/4"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B18
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B43
	.byte 0x8E	; character codes below 0x20
	.byte 0x20, 0x0A	; op 20, 10 bytes -> handler 0xF31A3A
	.short 0x0B5F
	.ascii "REC0RD"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8F
	.byte 0x11	; character codes below 0x20
	.byte 0x08, 0x06	; op 08, 6 bytes -> handler 0xF31A3A
	.short 0x1075
	.byte 0x15	; character codes below 0x20
	.ascii "="
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1158
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x117F
	.byte 0x11	; character codes below 0x20
	.byte 0x20, 0x0B	; op 20, 11 bytes -> handler 0xF31A3A
	.short 0x119C
	.ascii "MASTER:"
	.byte 0x20, 0x09	; op 20, 9 bytes -> handler 0xF31A3A
	.short 0x11AA
	.ascii "MIXER"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1952
	.ascii "1"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1957
	.ascii "2"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x195C
	.ascii "3"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1961
	.ascii "4"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1966
	.ascii "5"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x196B
	.ascii "6"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1970
	.ascii "7"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1975
	.ascii "8"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x20AA
	.ascii "9"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20AF
	.ascii "10"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20B4
	.ascii "11"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20B9
	.ascii "12"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20BE
	.ascii "13"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20C3
	.ascii "14"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20C8
	.ascii "15"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20CD
	.ascii "16"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00F2
	.short 0x0043
	.short 0x0132
	.short 0x0056
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00A0
	.short 0x0022
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00A0
	.short 0x004A
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00A0
	.short 0x0072
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00A0
	.short 0x009A
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00A0
	.short 0x00C2
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00A0
	.short 0x00EA
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00A0
	.short 0x0112
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00A0
	.short 0x013A
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00CF
	.short 0x0022
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00CF
	.short 0x004A
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00CF
	.short 0x0072
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00CF
	.short 0x009A
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00CF
	.short 0x00C2
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00CF
	.short 0x00EA
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00CF
	.short 0x0112
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00CF
	.short 0x013A
	.short 0x00E9
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00E3
	.short 0x001D
	.short 0x0135
	.short 0x0030
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00E5
	.short 0x001F
	.short 0x0133
	.short 0x002E
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000A
	.short 0x0020
	.short 0x002D
	.short 0x0033
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x0022
	.short 0x002B
	.short 0x0031
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000A
	.short 0x0044
	.short 0x002D
	.short 0x0057
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x0046
	.short 0x002B
	.short 0x0055
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00DA
	.short 0x006B
	.short 0x0134
	.short 0x007E
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000A
	.short 0x006C
	.short 0x003E
	.short 0x007F
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00DC
	.short 0x006D
	.short 0x0132
	.short 0x007C
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x006E
	.short 0x003C
	.short 0x007D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00AD
	.short 0x0024
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00AD
	.short 0x004C
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00AD
	.short 0x0074
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00AD
	.short 0x009C
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00AD
	.short 0x00C4
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00AD
	.short 0x00EC
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00AD
	.short 0x0114
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00AD
	.short 0x013C
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00DC
	.short 0x0024
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00DC
	.short 0x004C
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00DC
	.short 0x0074
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00DC
	.short 0x009C
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00DC
	.short 0x00C4
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00DC
	.short 0x00EC
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00DC
	.short 0x0114
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00DC
	.short 0x013C
	.short 0x00DC

; --- 0xF34C6E-0xF34D97: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x034C6E, 0x00012A

; ------------------------------------------------------------------
; 0xF34D98-0xF34E87 -- 16 display-list records, 240 bytes -- interpreter B
;   entered at: 0xF34D98
;   ends used:  0xF34E88
; ------------------------------------------------------------------
DL_F34D98:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F34E88	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1B59	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F7	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F34E88	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1B5E	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F8	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F34E88	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1B63	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F9	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F34E88	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1B68	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12FA	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F34E88	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1B6D	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12FB	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F34E88	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1B72	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12FC	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F34E88	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1B77	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12FD	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F34E88	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1B7C	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12FE	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F34E88	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22B1	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12FF	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F34E88	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22B6	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1300	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F34E88	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22BB	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1301	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F34E88	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22C0	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1302	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F34E88	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22C5	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1303	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F34E88	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22CA	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1304	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F34E88	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22CF	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1305	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F34E88	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22D4	; +0x0D -> IX

; --- 0xF34E88-0xF34EE7: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x034E88, 0x000060

; ------------------------------------------------------------------
; 0xF34EE8-0xF35034 -- 39 display-list records, 333 bytes -- interpreter A (33 records) and B (6)
;   entered at: 0xF34EE8, 0xF34FF2
;   ends used:  0xF34FF2, 0xF35001, 0xF35035
; ------------------------------------------------------------------
DL_F34EE8:
	.byte 0x1C, 0x0B	; op 1C, 11 bytes -> handler 0xF31A52
	.short 0x0068
	.short 0x0004
	.ascii "CYCLE"
	.byte 0x1C, 0x0A	; op 1C, 10 bytes -> handler 0xF31A52
	.short 0x00AA
	.short 0x0004
	.ascii "PLAY"
	.byte 0x07, 0x0B	; op 07, 11 bytes -> handler 0xF31A3A
	.short 0x05A3
	.ascii "CURRENT"
	.byte 0x07, 0x0B	; op 07, 11 bytes -> handler 0xF31A3A
	.short 0x05AB
	.ascii "MEASURE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x05B7
	.ascii ":"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B64
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8F
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0BB8
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x09	; op 07, 9 bytes -> handler 0xF31A3A
	.short 0x0BE3
	.ascii "CYCLE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0BEC
	.ascii ":"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x112C
	.byte 0x8E	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x112F
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11D0
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x09	; op 07, 9 bytes -> handler 0xF31A3A
	.short 0x11FB
	.ascii "CYCLE"
	.byte 0x07, 0x09	; op 07, 9 bytes -> handler 0xF31A3A
	.short 0x1201
	.ascii "START"
	.byte 0x07, 0x0B	; op 07, 11 bytes -> handler 0xF31A3A
	.short 0x1207
	.ascii "MEASURE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x120F
	.ascii ":"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17E8
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x09	; op 07, 9 bytes -> handler 0xF31A3A
	.short 0x17EB
	.ascii "CYCLE"
	.byte 0x07, 0x07	; op 07, 7 bytes -> handler 0xF31A3A
	.short 0x17F1
	.ascii "END"
	.byte 0x07, 0x0B	; op 07, 11 bytes -> handler 0xF31A3A
	.short 0x17F5
	.ascii "MEASURE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17FF
	.ascii ":"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1DD7
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x1DFA
	.ascii "EXIT"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000D
	.short 0x0041
	.short 0x0096
	.short 0x0060
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000D
	.short 0x0067
	.short 0x00E5
	.short 0x0086
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000D
	.short 0x008D
	.short 0x00E5
	.short 0x00AC
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0112
	.short 0x0045
	.short 0x0135
	.short 0x0058
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x0047
	.short 0x0133
	.short 0x0056
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0112
	.short 0x0069
	.short 0x0135
	.short 0x007C
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x006B
	.short 0x0133
	.short 0x007A
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0109
	.short 0x00BA
	.short 0x0135
	.short 0x00CD
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x010B
	.short 0x00BC
	.short 0x0133
	.short 0x00CB
DL_F34FF2:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x2647	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F35035	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0BED	; +0x0D -> IX
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x2644	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x05B8	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x2652	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1210	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x2654	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1800	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F3503B	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x08, 0x0B	; B op 08, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1B	; +0x06 swi 7 function
	.long 0x00F3503B	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF35035-0xF3505A: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x035035, 0x000026

; ------------------------------------------------------------------
; 0xF3505B-0xF351F8 -- 48 display-list records, 414 bytes -- interpreter A (41 records) and B (7)
;   entered at: 0xF3505B, 0xF351A7
;   ends used:  0xF351A7, 0xF351F9
; ------------------------------------------------------------------
DL_F3505B:
	.byte 0x1C, 0x0B	; op 1C, 11 bytes -> handler 0xF31A52
	.short 0x0058
	.short 0x0003
	.ascii "CYCLE"
	.byte 0x1C, 0x0C	; op 1C, 12 bytes -> handler 0xF31A52
	.short 0x009A
	.short 0x0003
	.ascii "RECORD"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0549
	.byte 0x87	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0577
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x0B	; op 07, 11 bytes -> handler 0xF31A3A
	.short 0x05A3
	.ascii "CURRENT"
	.byte 0x07, 0x0B	; op 07, 11 bytes -> handler 0xF31A3A
	.short 0x05AB
	.ascii "MEASURE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x05B7
	.ascii ":"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B64
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8F
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B90
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x09	; op 07, 9 bytes -> handler 0xF31A3A
	.short 0x0BE3
	.ascii "CYCLE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0BEB
	.ascii ":"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x112C
	.byte 0x8E	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x112F
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11D0
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x09	; op 07, 9 bytes -> handler 0xF31A3A
	.short 0x11FB
	.ascii "CYCLE"
	.byte 0x07, 0x09	; op 07, 9 bytes -> handler 0xF31A3A
	.short 0x1201
	.ascii "START"
	.byte 0x07, 0x0B	; op 07, 11 bytes -> handler 0xF31A3A
	.short 0x1207
	.ascii "MEASURE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x120F
	.ascii ":"
	.byte 0x07, 0x09	; op 07, 9 bytes -> handler 0xF31A3A
	.short 0x17EB
	.ascii "CYCLE"
	.byte 0x07, 0x07	; op 07, 7 bytes -> handler 0xF31A3A
	.short 0x17F1
	.ascii "END"
	.byte 0x07, 0x0B	; op 07, 11 bytes -> handler 0xF31A3A
	.short 0x17F5
	.ascii "MEASURE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17E8
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17FF
	.ascii ":"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1DD7
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1DD8
	.byte 0x10	; character codes below 0x20
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x1DFA
	.ascii "EXIT"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x1E52
	.ascii "CLEAR"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000D
	.short 0x0041
	.short 0x0096
	.short 0x0060
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000D
	.short 0x0067
	.short 0x00E5
	.short 0x0086
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000D
	.short 0x008D
	.short 0x00E5
	.short 0x00AC
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00FF
	.short 0x001D
	.short 0x0134
	.short 0x0030
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0101
	.short 0x001F
	.short 0x0132
	.short 0x002E
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0112
	.short 0x0045
	.short 0x0135
	.short 0x0058
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x0047
	.short 0x0133
	.short 0x0056
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0112
	.short 0x0069
	.short 0x0135
	.short 0x007C
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x006B
	.short 0x0133
	.short 0x007A
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0109
	.short 0x00BA
	.short 0x0135
	.short 0x00CD
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000A
	.short 0x00BB
	.short 0x003E
	.short 0x00D1
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x010B
	.short 0x00BC
	.short 0x0133
	.short 0x00CB
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x00BD
	.short 0x003C
	.short 0x00CF
DL_F351A7:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x2647	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F35035	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0BED	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x2648	; +0x02 source variable, 16-bit address
	.byte 0x01	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x20	; +0x06 swi 7 function
	.long 0x00F343B6	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0573	; +0x0D -> IX
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x2644	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x05B8	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x2656	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1210	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x2658	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1800	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F3503B	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x08, 0x0B	; B op 08, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1B	; +0x06 swi 7 function
	.long 0x00F3503B	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF351F9-0xF35207: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0351F9, 0x00000F

; ------------------------------------------------------------------
; 0xF35208-0xF3533B -- 29 display-list records, 308 bytes -- interpreter A (23 records) and B (6)
;   entered at: 0xF35208, 0xF352F9
;   ends used:  0xF352F9, 0xF35308, 0xF3533C
; ------------------------------------------------------------------
DL_F35208:
	.byte 0x1C, 0x10	; op 1C, 16 bytes -> handler 0xF31A52
	.short 0x0060
	.short 0x0005
	.ascii "CYCLE PLAY"
	.byte 0x07, 0x19	; op 07, 25 bytes -> handler 0xF31A3A
	.short 0x05A3
	.ascii "CURRENT MEASURE     :"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x05C2
	.ascii "EDIT"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x05C7
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B64
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8F
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B90
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x0C	; op 07, 12 bytes -> handler 0xF31A3A
	.short 0x0BBB
	.ascii "SOLO  : "
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x112C
	.byte 0x8E	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1157
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11F8
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x19	; op 07, 25 bytes -> handler 0xF31A3A
	.short 0x11FB
	.ascii "CYCLE START MEASURE :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17E8
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x19	; op 07, 25 bytes -> handler 0xF31A3A
	.short 0x17EB
	.ascii "CYCLE END MEASURE   :"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000D
	.short 0x0041
	.short 0x00E5
	.short 0x0060
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000D
	.short 0x0067
	.short 0x00E5
	.short 0x0086
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000D
	.short 0x008D
	.short 0x00E5
	.short 0x00AC
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x010B
	.short 0x001F
	.short 0x0135
	.short 0x0033
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x010D
	.short 0x0021
	.short 0x0133
	.short 0x0031
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0115
	.short 0x0045
	.short 0x0135
	.short 0x0058
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0117
	.short 0x0047
	.short 0x0133
	.short 0x0056
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0115
	.short 0x0069
	.short 0x0135
	.short 0x007C
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0117
	.short 0x006B
	.short 0x0133
	.short 0x007A
DL_F352F9:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1308	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3533C	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0BC3	; +0x0D -> IX
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x2644	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x05B8	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x2652	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1210	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x2654	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1800	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F3503B	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x08, 0x0B	; B op 08, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1B	; +0x06 swi 7 function
	.long 0x00F3503B	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF3533C-0xF35341: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03533C, 0x000006

; ------------------------------------------------------------------
; 0xF35342-0xF353AA -- 11 display-list records, 105 bytes -- interpreter A (10 records) and B (1)
;   entered at: 0xF35342, 0xF3539F
;   ends used:  0xF3539F, 0xF353AB
; ------------------------------------------------------------------
DL_F35342:
	.byte 0x1C, 0x17	; op 1C, 23 bytes -> handler 0xF31A52
	.short 0x003D
	.short 0x0052
	.ascii "METRONOME BALANCE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1794
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17BF
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1D5C
	.byte 0x8E	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1D5F
	.byte 0x11	; character codes below 0x20
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0112
	.short 0x0093
	.short 0x0135
	.short 0x00A6
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x004F
	.short 0x0094
	.short 0x00E4
	.short 0x00C8
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x0095
	.short 0x0133
	.short 0x00A4
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0112
	.short 0x00B7
	.short 0x0135
	.short 0x00CA
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x00B9
	.short 0x0133
	.short 0x00C8
DL_F3539F:
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x2652	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1C	; +0x06 swi 7 function
	.short 0x0086	; +0x07 -> (0x2530)
	.short 0x00A6	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count

; --- 0xF353AB-0xF3934B: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0353AB, 0x003FA1

; ------------------------------------------------------------------
; 0xF3934C-0xF394E2 -- 48 display-list records, 407 bytes -- interpreter A
;   entered at: 0xF3934C
;   ends used:  0xF394E3
; ------------------------------------------------------------------
DL_F3934C:
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1952
	.ascii "1"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1957
	.ascii "2"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x195C
	.ascii "3"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1961
	.ascii "4"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1966
	.ascii "5"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x196B
	.ascii "6"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1970
	.ascii "7"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x1975
	.ascii "8"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x20AA
	.ascii "9"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20AF
	.ascii "10"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20B4
	.ascii "11"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20B9
	.ascii "12"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20BE
	.ascii "13"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20C3
	.ascii "14"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20C8
	.ascii "15"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x20CD
	.ascii "16"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00A0
	.short 0x0022
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00A0
	.short 0x004A
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00A0
	.short 0x0072
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00A0
	.short 0x009A
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00A0
	.short 0x00C2
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00A0
	.short 0x00EA
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00A0
	.short 0x0112
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00A0
	.short 0x013A
	.short 0x00BA
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00CF
	.short 0x0022
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00CF
	.short 0x004A
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00CF
	.short 0x0072
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00CF
	.short 0x009A
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00CF
	.short 0x00C2
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00CF
	.short 0x00EA
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00CF
	.short 0x0112
	.short 0x00E9
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00CF
	.short 0x013A
	.short 0x00E9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00AD
	.short 0x0024
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00AD
	.short 0x004C
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00AD
	.short 0x0074
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00AD
	.short 0x009C
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00AD
	.short 0x00C4
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00AD
	.short 0x00EC
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00AD
	.short 0x0114
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00AD
	.short 0x013C
	.short 0x00AD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00DC
	.short 0x0024
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00DC
	.short 0x004C
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00DC
	.short 0x0074
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00DC
	.short 0x009C
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00DC
	.short 0x00C4
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00DC
	.short 0x00EC
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00DC
	.short 0x0114
	.short 0x00DC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00DC
	.short 0x013C
	.short 0x00DC

; --- 0xF394E3-0xF39550: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0394E3, 0x00006E

; ------------------------------------------------------------------
; 0xF39551-0xF39558 -- 1 display-list records, 8 bytes -- interpreter A
;   entered at: 0xF39551
;   ends used:  0xF39559
; ------------------------------------------------------------------
DL_F39551:
	.byte 0x0E, 0x08	; op 0E, 8 bytes -> handler 0xF31A9F
	.short 0x0000
	.short 0x0028
	.short 0x00F0

; --- 0xF39559-0xF3972C: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x039559, 0x0001D4

; ------------------------------------------------------------------
; 0xF3972D-0xF39736 -- 1 display-list records, 10 bytes -- interpreter A
;   entered at: 0xF3972D
;   ends used:  0xF39737
; ------------------------------------------------------------------
DL_F3972D:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0038
	.short 0x003E
	.short 0x0117
	.short 0x00B5

; --- 0xF39737-0xF39853: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x039737, 0x00011D

; ------------------------------------------------------------------
; 0xF39854-0xF39879 -- 4 display-list records, 38 bytes -- interpreter A
;   entered at: 0xF39854, 0xF39870
;   ends used:  0xF39870, 0xF3987A
; ------------------------------------------------------------------
DL_F39854:
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x11CC
	.ascii "OK "
	.byte 0x11	; character codes below 0x20
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x006C
	.short 0x0134
	.short 0x007F
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011F
	.short 0x006E
	.short 0x0132
	.short 0x007D
DL_F39870:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x006C
	.short 0x0140
	.short 0x007F

; --- 0xF3987A-0xF3998D: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03987A, 0x000114

; ------------------------------------------------------------------
; 0xF3998E-0xF399C0 -- 4 display-list records, 51 bytes -- interpreter B
;   entered at: 0xF3998E
;   ends used:  0xF399C1
; ------------------------------------------------------------------
DL_F3998E:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x08	; +0x06 swi 7 function
	.long 0x000012F7	; +0x07 -> XIY: string table
	.short 0x0006	; +0x0B -> BC: bytes per entry
	.short 0x0D80	; +0x0D -> IX
	.byte 0x0A, 0x0C	; B op 0A, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x12FE	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00F8	; +0x07 -> (0x2530)
	.short 0x0049	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1C	; +0x06 swi 7 function
	.short 0x005D	; +0x07 -> (0x2530)
	.short 0x0056	; +0x09 -> (0x2532)
	.byte 0x02	; +0x0B digit count
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x12FD	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1C	; +0x06 swi 7 function
	.short 0x00EE	; +0x07 -> (0x2530)
	.short 0x0056	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count

; --- 0xF399C1-0xF399D4: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0399C1, 0x000014

; ------------------------------------------------------------------
; 0xF399D5-0xF3A0A4 -- 202 display-list records, 1744 bytes -- interpreter A (198 records) and B (4)
;   entered at: 0xF399D5, 0xF39A73, 0xF39A7D, 0xF39BF8, 0xF39C02, 0xF39C35, 0xF39D3E, 0xF39E87, 0xF39F8A
;   ends used:  0xF39A73, 0xF39A7D, 0xF39BF8, 0xF39C02, 0xF39C35, 0xF39D3E, 0xF39E87, 0xF39F8A, 0xF3A0A5
; ------------------------------------------------------------------
DL_F399D5:
	.byte 0x1C, 0x0A	; op 1C, 10 bytes -> handler 0xF31A52
	.short 0x0079
	.short 0x0006
	.ascii "SONG"
	.byte 0x1C, 0x0B	; op 1C, 11 bytes -> handler 0xF31A52
	.short 0x00B0
	.short 0x0006
	.ascii "CLEAR"
	.byte 0x17, 0x08	; op 17, 8 bytes -> handler 0xF31A52
	.short 0x0110
	.short 0x0049
	.ascii "KB"
	.byte 0x1C, 0x0A	; op 1C, 10 bytes -> handler 0xF31A52
	.short 0x0030
	.short 0x0056
	.ascii "SONG"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x00E3
	.short 0x0056
	.ascii ":"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x010F
	.short 0x0056
	.ascii "%"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0073
	.short 0x0057
	.ascii ";"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1797
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x17BC
	.ascii "0K"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x1ED1
	.ascii "S0NG"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1ED6
	.ascii "N0"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x1ED9
	.ascii "/ALL"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x226C
	.ascii "<"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2271
	.ascii ">"
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x3D
	.short 0x0033
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0026
	.short 0x0043
	.short 0x0122
	.short 0x006D
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00D4
	.short 0x0072
	.short 0x00EC
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00D4
	.short 0x009A
	.short 0x00EC
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011B
	.short 0x0092
	.short 0x0135
	.short 0x00A5
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x0094
	.short 0x0133
	.short 0x00A3
DL_F39A73:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0027
	.short 0x0044
	.short 0x0122
	.short 0x006D
DL_F39A7D:
	.byte 0x1C, 0x0A	; op 1C, 10 bytes -> handler 0xF31A52
	.short 0x0079
	.short 0x0006
	.ascii "SONG"
	.byte 0x1C, 0x0B	; op 1C, 11 bytes -> handler 0xF31A52
	.short 0x00B0
	.short 0x0006
	.ascii "CLEAR"
	.byte 0x17, 0x08	; op 17, 8 bytes -> handler 0xF31A52
	.short 0x00FA
	.short 0x002D
	.ascii "KB"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0060
	.short 0x0032
	.ascii "."
	.byte 0x1C, 0x0A	; op 1C, 10 bytes -> handler 0xF31A52
	.short 0x001A
	.short 0x003A
	.ascii "SONG"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x00CF
	.short 0x003B
	.ascii ":"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x00FB
	.short 0x003B
	.ascii "%"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0060
	.short 0x0042
	.ascii "'"
	.byte 0x08, 0x0E	; op 08, 14 bytes -> handler 0xF31A3A
	.short 0x1097
	.ascii "ATTENTI0N!"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x14F4
	.ascii "Using"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x14FA
	.ascii "S0NG"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x14FF
	.ascii "CLEAR"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x1505
	.ascii "will"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x150A
	.ascii "erase"
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x1793
	.ascii "YES"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1797
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x183C
	.ascii "any"
	.byte 0x06, 0x0C	; op 06, 12 bytes -> handler 0xF31A3A
	.short 0x1840
	.ascii "existing"
	.byte 0x06, 0x0D	; op 06, 13 bytes -> handler 0xF31A3A
	.short 0x1849
	.ascii "recording"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1853
	.ascii "in"
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x1856
	.ascii "the"
	.byte 0x06, 0x0E	; op 06, 14 bytes -> handler 0xF31A3A
	.short 0x1B84
	.ascii "Sequencer."
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1D87
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1DAB
	.ascii "N0"
	.byte 0x08, 0x07	; op 08, 7 bytes -> handler 0xF31A3A
	.short 0x1EF4
	.ascii "Are"
	.byte 0x08, 0x07	; op 08, 7 bytes -> handler 0xF31A3A
	.short 0x1EFC
	.ascii "You"
	.byte 0x08, 0x09	; op 08, 9 bytes -> handler 0xF31A3A
	.short 0x1F04
	.ascii "Sure?"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0010
	.short 0x0027
	.short 0x010C
	.short 0x0051
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x0091
	.short 0x0134
	.short 0x00A4
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x0093
	.short 0x0132
	.short 0x00A2
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x00B8
	.short 0x0134
	.short 0x00CB
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x00BA
	.short 0x0132
	.short 0x00C9
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000F
	.short 0x0060
	.short 0x010E
	.short 0x0060
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0037
	.short 0x007A
	.short 0x00D7
	.short 0x007A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0037
	.short 0x007B
	.short 0x00D7
	.short 0x007B
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x000F
	.short 0x00DA
	.short 0x0110
	.short 0x00DA
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0011
	.short 0x00DB
	.short 0x0110
	.short 0x00DB
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0011
	.short 0x00DC
	.short 0x0110
	.short 0x00DC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x000F
	.short 0x0060
	.short 0x000F
	.short 0x00DC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x010E
	.short 0x0060
	.short 0x010E
	.short 0x00DC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x010F
	.short 0x0061
	.short 0x010F
	.short 0x00DC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0110
	.short 0x0061
	.short 0x0110
	.short 0x00DC
DL_F39BF8:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0011
	.short 0x0028
	.short 0x010C
	.short 0x0051
DL_F39C02:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x08	; +0x06 swi 7 function
	.long 0x000012F7	; +0x07 -> XIY: string table
	.short 0x0006	; +0x0B -> BC: bytes per entry
	.short 0x091D	; +0x0D -> IX
	.byte 0x0A, 0x0C	; B op 0A, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x12FE	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00E2	; +0x07 -> (0x2530)
	.short 0x002C	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1C	; +0x06 swi 7 function
	.short 0x0048	; +0x07 -> (0x2530)
	.short 0x003A	; +0x09 -> (0x2532)
	.byte 0x02	; +0x0B digit count
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x12FD	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1C	; +0x06 swi 7 function
	.short 0x00D8	; +0x07 -> (0x2530)
	.short 0x003A	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
DL_F39C35:
	.byte 0x1C, 0x0B	; op 1C, 11 bytes -> handler 0xF31A52
	.short 0x0079
	.short 0x0006
	.ascii "TRACK"
	.byte 0x1C, 0x0B	; op 1C, 11 bytes -> handler 0xF31A52
	.short 0x00BB
	.short 0x0006
	.ascii "CLEAR"
	.byte 0x08, 0x0E	; op 08, 14 bytes -> handler 0xF31A3A
	.short 0x061E
	.ascii "ATTENTI0N!"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x09DA
	.ascii "Using"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x09E0
	.ascii "TRACK"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x09E6
	.ascii "CLEAR"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x09EC
	.ascii "will"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x09F1
	.ascii "erase"
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x0B8B
	.ascii "YES"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8F
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x0D22
	.ascii "any"
	.byte 0x06, 0x0C	; op 06, 12 bytes -> handler 0xF31A3A
	.short 0x0D26
	.ascii "existing"
	.byte 0x06, 0x0E	; op 06, 14 bytes -> handler 0xF31A3A
	.short 0x0D2F
	.ascii "recordings"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x0D3A
	.ascii "in"
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x0D3D
	.ascii "the"
	.byte 0x06, 0x0C	; op 06, 12 bytes -> handler 0xF31A3A
	.short 0x106A
	.ascii "selected"
	.byte 0x06, 0x0B	; op 06, 11 bytes -> handler 0xF31A3A
	.short 0x1073
	.ascii "Tracks."
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x117F
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x11A3
	.ascii "N0"
	.byte 0x08, 0x07	; op 08, 7 bytes -> handler 0xF31A3A
	.short 0x13DB
	.ascii "Are"
	.byte 0x08, 0x07	; op 08, 7 bytes -> handler 0xF31A3A
	.short 0x13E3
	.ascii "You"
	.byte 0x08, 0x09	; op 08, 9 bytes -> handler 0xF31A3A
	.short 0x13EB
	.ascii "Sure?"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x001D
	.short 0x0108
	.short 0x0095
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x0044
	.short 0x0134
	.short 0x0057
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x0046
	.short 0x0132
	.short 0x0055
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x006B
	.short 0x0134
	.short 0x007E
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x006D
	.short 0x0132
	.short 0x007C
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x0037
	.short 0x00CE
	.short 0x0037
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x0038
	.short 0x00CE
	.short 0x0038
DL_F39D3E:
	.byte 0x1C, 0x0A	; op 1C, 10 bytes -> handler 0xF31A52
	.short 0x0097
	.short 0x0005
	.ascii "EDIT"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0009
	.short 0x0008
	.ascii "SEQ."
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x05A5
	.ascii "N0TE"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x05AA
	.ascii "EDIT"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x05B6
	.ascii "S0NG"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x05BB
	.ascii "CLEAR"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x0026
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013A
	.short 0x0026
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x0BBD
	.ascii "DRUM"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x0BC2
	.ascii "EDIT"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x0BCE
	.ascii "TRACK"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x0BD4
	.ascii "CLEAR"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x004D
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013A
	.short 0x004D
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x11BE
	.ascii "N0TE"
	.byte 0x06, 0x0A	; op 06, 10 bytes -> handler 0xF31A3A
	.short 0x11C3
	.ascii "CHANGE"
	.byte 0x06, 0x0C	; op 06, 12 bytes -> handler 0xF31A3A
	.short 0x11D5
	.ascii "QUANTIZE"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x0074
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013A
	.short 0x0074
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x0D	; op 06, 13 bytes -> handler 0xF31A3A
	.short 0x17ED
	.ascii "TRANSP0SE"
	.byte 0x06, 0x11	; op 06, 17 bytes -> handler 0xF31A3A
	.short 0x17FE
	.ascii "ADVANCE/DELAY"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x009B
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013A
	.short 0x009B
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x0C	; op 06, 12 bytes -> handler 0xF31A3A
	.short 0x1E05
	.ascii "VEL0CITY"
	.byte 0x06, 0x0A	; op 06, 10 bytes -> handler 0xF31A3A
	.short 0x1E0E
	.ascii "CHANGE"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x00C2
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013A
	.short 0x00C2
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x0F	; op 06, 15 bytes -> handler 0xF31A3A
	.short 0x1E16
	.ascii "PANEL WRITE"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0120
	.short 0x0008
	.ascii "P1/2"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x0004
	.short 0x0024
	.short 0x0012
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x10
	.short 0x0060
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x02
	.short 0x0411
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x0F
	.short 0x0A51
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x3B
	.short 0x1091
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x3C
	.short 0x16D1
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x08
	.short 0x1D11
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x3D
	.short 0x0434
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x3E
	.short 0x0A74
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x3F
	.short 0x10B4
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x40
	.short 0x16F4
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x44
	.short 0x1D34
DL_F39E87:
	.byte 0x1C, 0x0A	; op 1C, 10 bytes -> handler 0xF31A52
	.short 0x0097
	.short 0x0005
	.ascii "EDIT"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0009
	.short 0x0008
	.ascii "SEQ."
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x05A5
	.ascii "SONG"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x05AA
	.ascii "COPY"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x05BD
	.ascii "COPY"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x0026
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013A
	.short 0x0026
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x0BD5
	.ascii "ERASE"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013A
	.short 0x004D
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x0B	; op 06, 11 bytes -> handler 0xF31A3A
	.short 0x0EED
	.ascii "MEASURE"
	.byte 0x06, 0x0A	; op 06, 10 bytes -> handler 0xF31A3A
	.short 0x11ED
	.ascii "DELETE"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013A
	.short 0x0074
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x11D5
	.ascii "TRACK"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x11DB
	.ascii "MERGE"
	.byte 0x06, 0x0A	; op 06, 10 bytes -> handler 0xF31A3A
	.short 0x1805
	.ascii "INSERT"
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x0000
	.short 0x0074
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x013A
	.short 0x009B
	.byte 0x11	; character codes below 0x20
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0120
	.short 0x0008
	.ascii "P2/2"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x0004
	.short 0x0024
	.short 0x0012
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00E4
	.short 0x0028
	.short 0x00E7
	.short 0x0028
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00E4
	.short 0x004F
	.short 0x00E7
	.short 0x004F
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00E1
	.short 0x0063
	.short 0x00E4
	.short 0x0063
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00E4
	.short 0x0077
	.short 0x00E7
	.short 0x0077
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00E4
	.short 0x009E
	.short 0x00E7
	.short 0x009E
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00E4
	.short 0x0028
	.short 0x00E4
	.short 0x009E
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x10
	.short 0x0060
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x41
	.short 0x0411
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x43
	.short 0x10E1
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x45
	.short 0x054C
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x46
	.short 0x0AEC
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x47
	.short 0x1104
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x48
	.short 0x176C
DL_F39F8A:
	.byte 0x1C, 0x0B	; op 1C, 11 bytes -> handler 0xF31A52
	.short 0x0079
	.short 0x0006
	.ascii "TRACK"
	.byte 0x1C, 0x0B	; op 1C, 11 bytes -> handler 0xF31A52
	.short 0x00BB
	.short 0x0006
	.ascii "CLEAR"
	.byte 0x07, 0x09	; op 07, 9 bytes -> handler 0xF31A3A
	.short 0x0731
	.ascii "Press"
	.byte 0x07, 0x07	; op 07, 7 bytes -> handler 0xF31A3A
	.short 0x0737
	.ascii "the"
	.byte 0x07, 0x0B	; op 07, 11 bytes -> handler 0xF31A3A
	.short 0x073B
	.ascii "up/down"
	.byte 0x07, 0x0B	; op 07, 11 bytes -> handler 0xF31A3A
	.short 0x0743
	.ascii "buttons"
	.byte 0x07, 0x09	; op 07, 9 bytes -> handler 0xF31A3A
	.short 0x074B
	.ascii "under"
	.byte 0x07, 0x07	; op 07, 7 bytes -> handler 0xF31A3A
	.short 0x0A29
	.ascii "the"
	.byte 0x07, 0x0A	; op 07, 10 bytes -> handler 0xF31A3A
	.short 0x0A2D
	.ascii "screen"
	.byte 0x07, 0x11	; op 07, 17 bytes -> handler 0xF31A3A
	.short 0x0A34
	.ascii "corresponding"
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x0A42
	.ascii "to"
	.byte 0x07, 0x07	; op 07, 7 bytes -> handler 0xF31A3A
	.short 0x0A45
	.ascii "the"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0BB7
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x0BDC
	.ascii "0K"
	.byte 0x07, 0x0A	; op 07, 10 bytes -> handler 0xF31A3A
	.short 0x0D21
	.ascii "tracks"
	.byte 0x07, 0x08	; op 07, 8 bytes -> handler 0xF31A3A
	.short 0x0D28
	.ascii "that"
	.byte 0x07, 0x07	; op 07, 7 bytes -> handler 0xF31A3A
	.short 0x0D2D
	.ascii "you"
	.byte 0x07, 0x08	; op 07, 8 bytes -> handler 0xF31A3A
	.short 0x0D31
	.ascii "want"
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x0D36
	.ascii "to"
	.byte 0x07, 0x0A	; op 07, 10 bytes -> handler 0xF31A3A
	.short 0x0D39
	.ascii "clear."
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x1069
	.ascii "Press"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x106F
	.ascii "0K"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1072
	.ascii "to"
	.byte 0x06, 0x0C	; op 06, 12 bytes -> handler 0xF31A3A
	.short 0x1075
	.ascii "Complete"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x107E
	.ascii "TRACK"
	.byte 0x06, 0x0A	; op 06, 10 bytes -> handler 0xF31A3A
	.short 0x1084
	.ascii "CLEAR."
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0004
	.short 0x0022
	.short 0x0116
	.short 0x0084
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011C
	.short 0x0046
	.short 0x0134
	.short 0x0059
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011E
	.short 0x0048
	.short 0x0132
	.short 0x0057
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0033
	.short 0x0064
	.short 0x004C
	.short 0x0077
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0035
	.short 0x0066
	.short 0x004A
	.short 0x0075
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x3E
	.short 0x005C

; --- 0xF3A0A5-0xF3A0D0: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03A0A5, 0x00002C

; ------------------------------------------------------------------
; 0xF3A0D1-0xF3A0D8 -- 1 display-list records, 8 bytes -- interpreter A
;   entered at: 0xF3A0D1
;   ends used:  0xF3A0D9
; ------------------------------------------------------------------
DL_F3A0D1:
	.byte 0x0E, 0x08	; op 0E, 8 bytes -> handler 0xF31A9F
	.short 0x1720
	.short 0x0028
	.short 0x004B

; --- 0xF3A0D9-0xF3A1CE: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03A0D9, 0x0000F6

; ------------------------------------------------------------------
; 0xF3A1CF-0xF3A432 -- 54 display-list records, 612 bytes -- interpreter A (37 records) and B (17)
;   entered at: 0xF3A1CF, 0xF3A2BF, 0xF3A40D, 0xF3A417, 0xF3A41F, 0xF3A429
;   ends used:  0xF3A2BF, 0xF3A40D, 0xF3A417, 0xF3A41F, 0xF3A429, 0xF3A433
; ------------------------------------------------------------------
DL_F3A1CF:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F395A2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1B59	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F7	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F395A2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1B5E	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F8	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F395A2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1B63	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F9	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F395A2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1B68	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12FA	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F395A2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1B6D	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12FB	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F395A2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1B72	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12FC	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F395A2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1B77	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12FD	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F395A2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1B7C	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12FE	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F395A2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22B1	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12FF	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F395A2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22B6	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1300	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F395A2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22BB	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1301	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F395A2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22C0	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1302	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F395A2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22C5	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1303	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F395A2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22CA	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1304	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F395A2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22CF	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1305	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F395A2	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x22D4	; +0x0D -> IX
DL_F3A2BF:
	.byte 0x1C, 0x0B	; op 1C, 11 bytes -> handler 0xF31A52
	.short 0x0030
	.short 0x0007
	.ascii "TRACK"
	.byte 0x1C, 0x0C	; op 1C, 12 bytes -> handler 0xF31A52
	.short 0x0072
	.short 0x0007
	.ascii "ASSIGN"
	.byte 0x1C, 0x0D	; op 1C, 13 bytes -> handler 0xF31A52
	.short 0x00C0
	.short 0x0007
	.ascii "PRESETS"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x05C8
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x1C	; op 07, 28 bytes -> handler 0xF31A3A
	.short 0x0644
	.ascii "TECHNICS SET-UP1 ( 1-16)"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B68
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x1C	; op 07, 28 bytes -> handler 0xF31A3A
	.short 0x0BBC
	.ascii "TECHNICS SET-UP2 (17-32)"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x10E0
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x0D	; op 07, 13 bytes -> handler 0xF31A3A
	.short 0x110C
	.ascii "GM SET-UP"
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x18DA
	.ascii "Any"
	.byte 0x06, 0x0C	; op 06, 12 bytes -> handler 0xF31A3A
	.short 0x18DE
	.ascii "existing"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x18E7
	.ascii "song"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x18EC
	.ascii "will"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x18F1
	.ascii "be"
	.byte 0x06, 0x0C	; op 06, 12 bytes -> handler 0xF31A3A
	.short 0x18F4
	.ascii "cleared."
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x1C22
	.ascii "Press"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1C29
	.ascii "0K"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1C2D
	.ascii "to"
	.byte 0x06, 0x0C	; op 06, 12 bytes -> handler 0xF31A3A
	.short 0x1C30
	.ascii "proceed."
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x1ECC
	.ascii "S0NG"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1ED1
	.ascii "N0"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x1ED4
	.ascii "/ALL"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x223F
	.ascii "<"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2244
	.ascii ">"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x22A2
	.ascii "0K"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0012
	.short 0x0020
	.short 0x00F1
	.short 0x0039
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0012
	.short 0x0043
	.short 0x00F1
	.short 0x005D
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0012
	.short 0x0066
	.short 0x00F1
	.short 0x007F
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00D3
	.short 0x004A
	.short 0x00EB
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00D3
	.short 0x0072
	.short 0x00EB
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0044
	.short 0x00AF
	.short 0x005D
	.short 0x00C2
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0046
	.short 0x00B1
	.short 0x005B
	.short 0x00C0
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00CB
	.short 0x00D8
	.short 0x00E5
	.short 0x00EB
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00DA
	.short 0x00E3
	.short 0x00E9
DL_F3A40D:
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x001E
	.short 0x0087
	.short 0x0055
	.short 0x0098
DL_F3A417:
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x15BC
	.ascii "S0NG"
DL_F3A41F:
	.byte 0x06, 0x0A	; op 06, 10 bytes -> handler 0xF31A3A
	.short 0x15BC
	.ascii "  ALL "
DL_F3A429:
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F7	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.short 0x15C0	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663

; --- 0xF3A433-0xF3A460: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03A433, 0x00002E

; ------------------------------------------------------------------
; 0xF3A461-0xF3A589 -- 31 display-list records, 297 bytes -- interpreter A (27 records) and B (4)
;   entered at: 0xF3A461, 0xF3A47F, 0xF3A526, 0xF3A561
;   ends used:  0xF3A47F, 0xF3A526, 0xF3A561, 0xF3A57F, 0xF3A58A
; ------------------------------------------------------------------
DL_F3A461:
	.byte 0x1C, 0x14	; op 1C, 20 bytes -> handler 0xF31A52
	.short 0x0051
	.short 0x00CA
	.ascii "Are You Sure ?"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0049
	.short 0x00BD
	.short 0x00F3
	.short 0x00E4
DL_F3A47F:
	.byte 0x1C, 0x11	; op 1C, 17 bytes -> handler 0xF31A52
	.short 0x0071
	.short 0x0006
	.ascii "TRACK MERGE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0BB7
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x0BDC
	.ascii "OK"
	.byte 0x07, 0x0E	; op 07, 14 bytes -> handler 0xF31A3A
	.short 0x0C0C
	.ascii "TRACK  :  "
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0C30
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x0E	; op 07, 14 bytes -> handler 0xF31A3A
	.short 0x11BF
	.ascii "TRACK  :  "
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11CF
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1720
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x0E	; op 07, 14 bytes -> handler 0xF31A3A
	.short 0x1724
	.ascii "TRACK  :  "
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00AC
	.short 0x0073
	.byte 0x11	; character codes below 0x20
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0016
	.short 0x0040
	.short 0x008A
	.short 0x0064
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00B1
	.short 0x0064
	.short 0x0126
	.short 0x0088
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0016
	.short 0x0087
	.short 0x008A
	.short 0x00AB
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x008A
	.short 0x0054
	.short 0x009B
	.short 0x0054
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x009B
	.short 0x0076
	.short 0x00B1
	.short 0x0076
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x008A
	.short 0x009A
	.short 0x009B
	.short 0x009A
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x009B
	.short 0x0054
	.short 0x009B
	.short 0x009A
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x43
	.short 0x005A
DL_F3A526:
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x1F04
	.ascii "TRACK"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x210E
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x233E
	.byte 0x8E	; character codes below 0x20
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011B
	.short 0x0046
	.short 0x0135
	.short 0x0059
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x0048
	.short 0x0133
	.short 0x0057
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00D4
	.short 0x00C2
	.short 0x00EC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00E0
	.short 0x00C4
	.short 0x00E0
DL_F3A561:
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x0C16	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F7	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x172E	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F8	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x11C9	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x12F9	; +0x02 source variable, 16-bit address
	.byte 0x03	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F3A58A	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; ==================================================================
; 0xF3A58A-0xF3A5A9 -- display-list OPERAND TABLES (32 bytes, 1 objects)
; ==================================================================
;
; Every object here is named by a display-list record that points at it, and
; its SIZE is proven by tiling: the objects start at the first byte of this
; gap, each extent is a whole number of entries, and the last object's
; handler-implied size ends exactly on the first byte of the next display
; list.  Reproduce with `python3 notes/prom_b_dl_operand_tables.py --exact`.
;
; ------------------------------------------------------------------
; DLTable_F3A58A -- 4 entries of 8 bytes
; Referenced by: display-list record 0xF3A57F
; Evidence: the record's +7 pointer lands here and its handler scales the
;           extracted bit-field by 8 before adding it (0xF31B57 `sla 3,HL`,
;           0xF31B86 `mul HL,6`).
;           4 entries is the EXTENT (32 bytes / 8), not the (mask >> shift) + 1
;           = 4 the record would allow.
; ------------------------------------------------------------------
DLTable_F3A58A:
	.short 0x0000, 0x0000, 0x0001, 0x0001	; [0]
	.short 0x0016, 0x0040, 0x008A, 0x0064	; [1]
	.short 0x0016, 0x0087, 0x008A, 0x00AB	; [2]
	.short 0x00B1, 0x0064, 0x0126, 0x0088	; [3]

; ------------------------------------------------------------------
; 0xF3A5AA-0xF3A6D8 -- 31 display-list records, 303 bytes -- interpreter A (27 records) and B (4)
;   entered at: 0xF3A5AA, 0xF3A5E9, 0xF3A66E, 0xF3A6AB
;   ends used:  0xF3A5E9, 0xF3A66E, 0xF3A6AB, 0xF3A6CE, 0xF3A6D9
; ------------------------------------------------------------------
DL_F3A5AA:
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x0BB3
	.ascii "YES"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0BB7
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17E7
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x180B
	.ascii "NO"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x0045
	.short 0x0134
	.short 0x0058
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x0047
	.short 0x0132
	.short 0x0056
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x0094
	.short 0x0134
	.short 0x00A7
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x0096
	.short 0x0132
	.short 0x00A5
DL_F3A5E9:
	.byte 0x1C, 0x14	; op 1C, 20 bytes -> handler 0xF31A52
	.short 0x0061
	.short 0x0006
	.ascii "MEASURE DELETE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0C08
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x0C0B
	.ascii "TRACK           :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11A8
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x11AB
	.ascii "FIRST MEASURE   :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1748
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x174B
	.ascii "LAST MEASURE    :"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0043
	.short 0x00DF
	.short 0x0062
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0067
	.short 0x00DF
	.short 0x0086
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x008B
	.short 0x00DF
	.short 0x00AA
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x47
	.short 0x0030
DL_F3A66E:
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11CF
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x11F4
	.ascii "OK"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011C
	.short 0x006D
	.short 0x0134
	.short 0x0080
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011E
	.short 0x006F
	.short 0x0132
	.short 0x007E
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x210E
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x233E
	.byte 0x8E	; character codes below 0x20
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00D4
	.short 0x00C2
	.short 0x00EC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00E0
	.short 0x00C4
	.short 0x00E0
DL_F3A6AB:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0x1F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3A72F	; +0x07 -> XIY: string table
	.short 0x0006	; +0x0B -> BC: bytes per entry
	.short 0x0C1C	; +0x0D -> IX
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F7	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x11BC	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F9	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x175C	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x12FB	; +0x02 source variable, 16-bit address
	.byte 0x03	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F3A6D9	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF3A6D9-0xF3A7D9: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03A6D9, 0x000101

; ------------------------------------------------------------------
; 0xF3A7DA-0xF3AA16 -- 57 display-list records, 573 bytes -- interpreter A (52 records) and B (5)
;   entered at: 0xF3A7DA, 0xF3A8F5, 0xF3A99D, 0xF3A9DA
;   ends used:  0xF3A8F5, 0xF3A99D, 0xF3A9DA, 0xF3AA0C, 0xF3AA17
; ------------------------------------------------------------------
DL_F3A7DA:
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x11A3
	.ascii "YES"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11A7
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1797
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x17BB
	.ascii "NO"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x006B
	.short 0x0134
	.short 0x007E
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x006D
	.short 0x0132
	.short 0x007C
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x0092
	.short 0x0134
	.short 0x00A5
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x0094
	.short 0x0132
	.short 0x00A3
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0139
	.short 0x0073
	.short 0x013C
	.short 0x0073
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0139
	.short 0x0074
	.short 0x013D
	.short 0x0074
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0139
	.short 0x0075
	.short 0x013E
	.short 0x0075
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0139
	.short 0x0076
	.short 0x013E
	.short 0x0076
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0139
	.short 0x0077
	.short 0x013D
	.short 0x0077
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0139
	.short 0x0078
	.short 0x013C
	.short 0x0078
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0139
	.short 0x0099
	.short 0x013C
	.short 0x0099
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0139
	.short 0x009A
	.short 0x013D
	.short 0x009A
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0139
	.short 0x009B
	.short 0x013E
	.short 0x009B
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0139
	.short 0x009C
	.short 0x013E
	.short 0x009C
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0139
	.short 0x009D
	.short 0x013D
	.short 0x009D
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0139
	.short 0x009E
	.short 0x013C
	.short 0x009E
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0139
	.short 0x0070
	.short 0x0139
	.short 0x007B
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0139
	.short 0x0096
	.short 0x0139
	.short 0x00A1
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x013A
	.short 0x0071
	.short 0x013A
	.short 0x007A
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x013A
	.short 0x0097
	.short 0x013A
	.short 0x00A0
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x013B
	.short 0x0072
	.short 0x013B
	.short 0x0079
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x013B
	.short 0x0098
	.short 0x013B
	.short 0x009F
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x013C
	.short 0x0073
	.short 0x013C
	.short 0x0078
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x013C
	.short 0x0099
	.short 0x013C
	.short 0x009E
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x013D
	.short 0x0074
	.short 0x013D
	.short 0x0077
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x013D
	.short 0x009A
	.short 0x013D
	.short 0x009D
DL_F3A8F5:
	.byte 0x1C, 0x13	; op 1C, 19 bytes -> handler 0xF31A52
	.short 0x005F
	.short 0x0006
	.ascii "MEASURE ERASE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0668
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x066B
	.ascii "TRACK           :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0C08
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x0C0B
	.ascii "FIRST MEASURE   :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11A8
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x11AB
	.ascii "LAST MEASURE    :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1770
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x179B
	.ascii "ERASE DATA      :"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x001F
	.short 0x00DF
	.short 0x003E
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0043
	.short 0x00DF
	.short 0x0062
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0067
	.short 0x00DF
	.short 0x0086
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x008C
	.short 0x00DF
	.short 0x00AB
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x46
	.short 0x0030
DL_F3A99D:
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0BB7
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x0BDC
	.ascii "OK"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011C
	.short 0x0046
	.short 0x0134
	.short 0x0059
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011E
	.short 0x0048
	.short 0x0132
	.short 0x0057
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x210E
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x233E
	.byte 0x8E	; character codes below 0x20
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00D4
	.short 0x00C2
	.short 0x00EC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00E0
	.short 0x00C4
	.short 0x00E0
DL_F3A9DA:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0x1F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3A72F	; +0x07 -> XIY: string table
	.short 0x0006	; +0x0B -> BC: bytes per entry
	.short 0x067C	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12FB	; +0x02 source variable, 16-bit address
	.byte 0x03	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3AA3F	; +0x07 -> XIY: string table
	.short 0x0007	; +0x0B -> BC: bytes per entry
	.short 0x17AC	; +0x0D -> IX
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F7	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x0C1C	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F9	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x11BC	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x12FC	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F3AA17	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF3AA17-0xF3AA53: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03AA17, 0x00003D

; ------------------------------------------------------------------
; 0xF3AA54-0xF3AB73 -- 27 display-list records, 288 bytes -- interpreter A (22 records) and B (5)
;   entered at: 0xF3AA54, 0xF3AB3B
;   ends used:  0xF3AAFE, 0xF3AB3B, 0xF3AB69, 0xF3AB74
; ------------------------------------------------------------------
DL_F3AA54:
	.byte 0x1C, 0x15	; op 1C, 21 bytes -> handler 0xF31A52
	.short 0x005E
	.short 0x0007
	.ascii "VEL0CITY CHANGE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0690
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x0693
	.ascii "TRACK           :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0C30
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x0C33
	.ascii "FIRST MEASURE   :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11D0
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x11D3
	.ascii "LAST MEASURE    :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1770
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x179B
	.ascii "VELOCITY        :"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0020
	.short 0x00DF
	.short 0x003F
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0044
	.short 0x00DF
	.short 0x0063
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0068
	.short 0x00DF
	.short 0x0087
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x008C
	.short 0x00DF
	.short 0x00AB
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x08
	.short 0x0030
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8F
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x0BB4
	.ascii "OK"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011B
	.short 0x0045
	.short 0x0135
	.short 0x0058
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x0047
	.short 0x0133
	.short 0x0056
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x210E
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x233E
	.byte 0x8E	; character codes below 0x20
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00D4
	.short 0x00C2
	.short 0x00EC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00E0
	.short 0x00C4
	.short 0x00E0
DL_F3AB3B:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0x1F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3A6F9	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x06A4	; +0x0D -> IX
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F7	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x0C44	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F9	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x11E4	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x12FB	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x17AC	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x12FC	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F3AB74	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF3AB74-0xF3AB9B: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03AB74, 0x000028

; ------------------------------------------------------------------
; 0xF3AB9C-0xF3AD41 -- 45 display-list records, 422 bytes -- interpreter A (38 records) and B (7)
;   entered at: 0xF3AB9C, 0xF3ABDB, 0xF3ACB3, 0xF3ACF0
;   ends used:  0xF3ABDB, 0xF3ACB3, 0xF3ACF0, 0xF3AD37, 0xF3AD42
; ------------------------------------------------------------------
DL_F3AB9C:
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x0B8B
	.ascii "YES"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8F
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x117F
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x11A3
	.ascii "NO"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x0044
	.short 0x0134
	.short 0x0057
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x0046
	.short 0x0132
	.short 0x0055
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x006B
	.short 0x0134
	.short 0x007E
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x006D
	.short 0x0132
	.short 0x007C
DL_F3ABDB:
	.byte 0x1C, 0x0E	; op 1C, 14 bytes -> handler 0xF31A52
	.short 0x0077
	.short 0x0005
	.ascii "QUANTIZE"
	.byte 0x07, 0x13	; op 07, 19 bytes -> handler 0xF31A3A
	.short 0x0642
	.ascii "TRACK         :"
	.byte 0x07, 0x0E	; op 07, 14 bytes -> handler 0xF31A3A
	.short 0x0656
	.ascii "STRENGTH :"
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x0663
	.ascii " %"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0668
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x06B7
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x13	; op 07, 19 bytes -> handler 0xF31A3A
	.short 0x0BE2
	.ascii "FIRST MEASURE :"
	.byte 0x07, 0x0D	; op 07, 13 bytes -> handler 0xF31A3A
	.short 0x0BF6
	.ascii "WINDOW  :"
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x0C03
	.ascii " %"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0C08
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0C57
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x13	; op 07, 19 bytes -> handler 0xF31A3A
	.short 0x1182
	.ascii "LAST MEASURE  :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11A8
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1748
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x0B	; op 07, 11 bytes -> handler 0xF31A3A
	.short 0x174A
	.ascii "VALUE: "
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x001D
	.short 0x00A2
	.short 0x003C
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00AA
	.short 0x001D
	.short 0x0133
	.short 0x003C
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0041
	.short 0x00A2
	.short 0x0060
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00AA
	.short 0x0041
	.short 0x0133
	.short 0x0060
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0065
	.short 0x00A2
	.short 0x0084
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x008A
	.short 0x00A2
	.short 0x00A9
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x3B
	.short 0x005C
DL_F3ACB3:
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11CF
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x11F4
	.ascii "OK"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011B
	.short 0x006D
	.short 0x0135
	.short 0x0080
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x006F
	.short 0x0133
	.short 0x007E
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x210E
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x233E
	.byte 0x8E	; character codes below 0x20
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00D4
	.short 0x00C2
	.short 0x00EC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00E0
	.short 0x00C4
	.short 0x00E0
DL_F3ACF0:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0x1F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3A6F9	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0651	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12FB	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3AD7A	; +0x07 -> XIY: string table
	.short 0x0002	; +0x0B -> BC: bytes per entry
	.short 0x1751	; +0x0D -> IX
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F7	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x0BF1	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F9	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1191	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12FC	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x0660	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x12FD	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x0BFF	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x12FE	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F3AD42	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF3AD42-0xF3AD87: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03AD42, 0x000046

; ------------------------------------------------------------------
; 0xF3AD88-0xF3B064 -- 61 display-list records, 733 bytes -- interpreter A (51 records) and B (10)
;   entered at: 0xF3AD88, 0xF3AEAF, 0xF3AFAF, 0xF3AFE7
;   ends used:  0xF3AEAF, 0xF3AFAF, 0xF3AFE7, 0xF3B05A, 0xF3B065
; ------------------------------------------------------------------
DL_F3AD88:
	.byte 0x1C, 0x11	; op 1C, 17 bytes -> handler 0xF31A52
	.short 0x0078
	.short 0x0006
	.ascii "PANEL WRITE"
	.byte 0x07, 0x27	; op 07, 39 bytes -> handler 0xF31A3A
	.short 0x06E2
	.ascii "PANEL WRITE replaces the sounds and"
	.byte 0x07, 0x25	; op 07, 37 bytes -> handler 0xF31A3A
	.short 0x0A2A
	.ascii "settings at the beginning of your"
	.byte 0x07, 0x20	; op 07, 32 bytes -> handler 0xF31A3A
	.short 0x0D72
	.ascii "song,which are selected when"
	.byte 0x07, 0x1D	; op 07, 29 bytes -> handler 0xF31A3A
	.short 0x1092
	.ascii "you press SEQUENCER RESET"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x10D3
	.ascii "."
	.byte 0x07, 0x26	; op 07, 38 bytes -> handler 0xF31A3A
	.short 0x16FA
	.ascii "Make the desired changes and press"
	.byte 0x07, 0x1F	; op 07, 31 bytes -> handler 0xF31A3A
	.short 0x1A1F
	.ascii "to store your new settings."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1A6B
	.ascii "OK"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x22D0
	.ascii "OK"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0006
	.short 0x0022
	.short 0x0131
	.short 0x00C9
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0014
	.short 0x00A4
	.short 0x002D
	.short 0x00B7
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0016
	.short 0x00A6
	.short 0x002B
	.short 0x00B5
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00FB
	.short 0x00D9
	.short 0x0114
	.short 0x00EC
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00FD
	.short 0x00DB
	.short 0x0112
	.short 0x00EA
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x44
	.short 0x0033
DL_F3AEAF:
	.byte 0x1C, 0x11	; op 1C, 17 bytes -> handler 0xF31A52
	.short 0x0071
	.short 0x0006
	.ascii "N0TE CHANGE"
	.byte 0x07, 0x0F	; op 07, 15 bytes -> handler 0xF31A3A
	.short 0x0A90
	.ascii "TARGET NOTE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B68
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x13	; op 07, 19 bytes -> handler 0xF31A3A
	.short 0x0B6A
	.ascii "TRACK         :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0BDF
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0CC2
	.ascii ":"
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x0CC7
	.ascii " ("
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0CCC
	.ascii ")"
	.byte 0x07, 0x0D	; op 07, 13 bytes -> handler 0xF31A3A
	.short 0x10A8
	.ascii "CHANGE TO"
	.byte 0x07, 0x13	; op 07, 19 bytes -> handler 0xF31A3A
	.short 0x11AA
	.ascii "FIRST MEASURE :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11D0
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11F7
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1302
	.ascii ":"
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x1307
	.ascii " ("
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x130C
	.ascii ")"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17E7
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x13	; op 07, 19 bytes -> handler 0xF31A3A
	.short 0x17EA
	.ascii "LAST MEASURE  :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1810
	.byte 0x10	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00B6
	.short 0x0075
	.byte 0x11	; character codes below 0x20
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000A
	.short 0x003E
	.short 0x00A6
	.short 0x005D
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00BB
	.short 0x003E
	.short 0x0131
	.short 0x0060
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000A
	.short 0x0067
	.short 0x00A6
	.short 0x0085
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00BB
	.short 0x0066
	.short 0x0131
	.short 0x0088
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000A
	.short 0x008F
	.short 0x00A6
	.short 0x00AE
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x3F
	.short 0x0033
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00B3
	.short 0x004F
	.short 0x00BB
	.short 0x004F
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00B3
	.short 0x0078
	.short 0x00BB
	.short 0x0078
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00B3
	.short 0x004F
	.short 0x00B3
	.short 0x0078
DL_F3AFAF:
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x180C
	.ascii "OK"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011C
	.short 0x0094
	.short 0x0134
	.short 0x00A7
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011E
	.short 0x0096
	.short 0x0132
	.short 0x00A5
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x210E
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x233E
	.byte 0x8E	; character codes below 0x20
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00D4
	.short 0x00C2
	.short 0x00EC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00E0
	.short 0x00C4
	.short 0x00E0
DL_F3AFE7:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0x1F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3A6F9	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x0B79	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F7	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3B095	; +0x07 -> XIY: string table
	.short 0x0002	; +0x0B -> BC: bytes per entry
	.short 0x0C9B	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F8	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3B0AD	; +0x07 -> XIY: string table
	.short 0x0002	; +0x0B -> BC: bytes per entry
	.short 0x0C9D	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F9	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3B095	; +0x07 -> XIY: string table
	.short 0x0002	; +0x0B -> BC: bytes per entry
	.short 0x12DB	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12FA	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3B0AD	; +0x07 -> XIY: string table
	.short 0x0002	; +0x0B -> BC: bytes per entry
	.short 0x12DD	; +0x0D -> IX
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12FB	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x0CA1	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12FC	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x11B9	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12FE	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x12E1	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12FF	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x17F9	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x1301	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F3B065	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF3B065-0xF3B0C2: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03B065, 0x00005E

; ------------------------------------------------------------------
; 0xF3B0C3-0xF3B21B -- 35 display-list records, 345 bytes -- interpreter A (30 records) and B (5)
;   entered at: 0xF3B0C3, 0xF3B102, 0xF3B1E3
;   ends used:  0xF3B102, 0xF3B1A6, 0xF3B1E3, 0xF3B211, 0xF3B21C
; ------------------------------------------------------------------
DL_F3B0C3:
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x17BB
	.ascii "YES"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17BF
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1DAF
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1DD3
	.ascii "NO"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x0092
	.short 0x0134
	.short 0x00A5
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x0094
	.short 0x0132
	.short 0x00A3
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x00B9
	.short 0x0134
	.short 0x00CC
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x00BB
	.short 0x0132
	.short 0x00CA
DL_F3B102:
	.byte 0x1C, 0x0F	; op 1C, 15 bytes -> handler 0xF31A52
	.short 0x0070
	.short 0x0006
	.ascii "TRANSP0SE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0690
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x0693
	.ascii "TRACK           :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0C30
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x0C33
	.ascii "FIRST MEASURE   :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11D0
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x11D3
	.ascii "LAST MEASURE    :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1770
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x1773
	.ascii "TRANSPOSE       :"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0020
	.short 0x00DF
	.short 0x003F
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0044
	.short 0x00DF
	.short 0x0063
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0068
	.short 0x00DF
	.short 0x0087
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x008C
	.short 0x00DF
	.short 0x00AB
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x3C
	.short 0x0033
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8F
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x0BB4
	.ascii "OK"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011B
	.short 0x0045
	.short 0x0135
	.short 0x0058
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x0047
	.short 0x0133
	.short 0x0056
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x210E
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x233E
	.byte 0x8E	; character codes below 0x20
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00D4
	.short 0x00C2
	.short 0x00EC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00E0
	.short 0x00C4
	.short 0x00E0
DL_F3B1E3:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3A6F9	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x06A4	; +0x0D -> IX
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F7	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x0C44	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F9	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x11E4	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x12FB	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1784	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x12FC	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F3B21C	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF3B21C-0xF3B243: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03B21C, 0x000028

; ------------------------------------------------------------------
; 0xF3B244-0xF3B3B1 -- 33 display-list records, 366 bytes -- interpreter A (28 records) and B (5)
;   entered at: 0xF3B244, 0xF3B26C, 0xF3B294, 0xF3B33C, 0xF3B379
;   ends used:  0xF3B26C, 0xF3B294, 0xF3B33C, 0xF3B379, 0xF3B3A7, 0xF3B3B2
; ------------------------------------------------------------------
DL_F3B244:
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x00E8
	.short 0x0057
	.ascii ":"
	.byte 0x1C, 0x17	; op 1C, 23 bytes -> handler 0xF31A52
	.short 0x002A
	.short 0x0056
	.ascii "   ALL S0NGS     "
	.byte 0x1C, 0x0A	; op 1C, 10 bytes -> handler 0xF31A52
	.short 0x00F0
	.short 0x0056
	.ascii "100%"
DL_F3B26C:
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x00D2
	.short 0x0039
	.ascii ":"
	.byte 0x1C, 0x17	; op 1C, 23 bytes -> handler 0xF31A52
	.short 0x0014
	.short 0x003B
	.ascii "   ALL S0NGS     "
	.byte 0x1C, 0x0A	; op 1C, 10 bytes -> handler 0xF31A52
	.short 0x00DA
	.short 0x003B
	.ascii "100%"
DL_F3B294:
	.byte 0x1C, 0x13	; op 1C, 19 bytes -> handler 0xF31A52
	.short 0x0067
	.short 0x0006
	.ascii "ADVANCE/DELAY"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0690
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x0693
	.ascii "TRACK           :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0C30
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x0C33
	.ascii "FIRST MEASURE   :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11D0
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x11D3
	.ascii "LAST MEASURE    :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1770
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x15	; op 07, 21 bytes -> handler 0xF31A3A
	.short 0x1773
	.ascii "ADVANCE/DELAY   :"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0020
	.short 0x00DF
	.short 0x003F
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0044
	.short 0x00DF
	.short 0x0063
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0068
	.short 0x00DF
	.short 0x0087
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x008C
	.short 0x00DF
	.short 0x00AB
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x40
	.short 0x0032
DL_F3B33C:
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11CF
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x11F4
	.ascii "OK"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011E
	.short 0x006F
	.short 0x0132
	.short 0x007E
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011C
	.short 0x006D
	.short 0x0134
	.short 0x0080
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x210E
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x233E
	.byte 0x8E	; character codes below 0x20
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00D4
	.short 0x00C2
	.short 0x00EC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00E0
	.short 0x00C4
	.short 0x00E0
DL_F3B379:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3A6F9	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x06A4	; +0x0D -> IX
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F7	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x0C44	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F9	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x11E4	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x05, 0x0B	; B op 05, 11 bytes -> handler 0xF31BD7 -- decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660
	.short 0x12FB	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1784	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count
	.byte 0x00	; +0x0A bit 7 set = unsigned, clear = signed
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x12FC	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F3B3B2	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF3B3B2-0xF3B7C2: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03B3B2, 0x000411

; ------------------------------------------------------------------
; 0xF3B7C3-0xF3B7CC -- 1 display-list records, 10 bytes -- interpreter A
;   entered at: 0xF3B7C3
;   ends used:  0xF3B7CD
; ------------------------------------------------------------------
DL_F3B7C3:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x000C
	.short 0x006F
	.short 0x0031
	.short 0x00A5

; --- 0xF3B7CD-0xF3B99C: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03B7CD, 0x0001D0

; ------------------------------------------------------------------
; 0xF3B99D-0xF3BB96 -- 40 display-list records, 506 bytes -- interpreter A (36 records) and B (4)
;   entered at: 0xF3B99D, 0xF3BA91, 0xF3BAB9, 0xF3BB7E, 0xF3BB8D
;   ends used:  0xF3BA91, 0xF3BAB9, 0xF3BB7E, 0xF3BB8D, 0xF3BB97
; ------------------------------------------------------------------
DL_F3B99D:
	.byte 0x1C, 0x19	; op 1C, 25 bytes -> handler 0xF31A52
	.short 0x0030
	.short 0x0008
	.ascii "TRACK ASSIGN CHANGE"
	.byte 0x08, 0x0E	; op 08, 14 bytes -> handler 0xF31A3A
	.short 0x07FE
	.ascii "ATTENTION!"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0BB7
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x0C03
	.ascii "YES"
	.byte 0x07, 0x1E	; op 07, 30 bytes -> handler 0xF31A3A
	.short 0x0E39
	.ascii "Changing the assignment of"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1157
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x117B
	.ascii "NO"
	.byte 0x07, 0x09	; op 07, 9 bytes -> handler 0xF31A3A
	.short 0x1249
	.ascii "Track"
	.byte 0x07, 0x0A	; op 07, 10 bytes -> handler 0xF31A3A
	.short 0x1250
	.ascii " from "
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x125D
	.ascii "~"
	.byte 0x07, 0x23	; op 07, 35 bytes -> handler 0xF31A3A
	.short 0x1659
	.ascii "will erase all the current data"
	.byte 0x08, 0x07	; op 08, 7 bytes -> handler 0xF31A3A
	.short 0x1BD3
	.ascii "Are"
	.byte 0x08, 0x07	; op 08, 7 bytes -> handler 0xF31A3A
	.short 0x1BDB
	.ascii "You"
	.byte 0x08, 0x09	; op 08, 9 bytes -> handler 0xF31A3A
	.short 0x1BE3
	.ascii "Sure?"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0003
	.short 0x0025
	.short 0x010A
	.short 0x00D2
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0113
	.short 0x0047
	.short 0x0135
	.short 0x005A
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0115
	.short 0x0049
	.short 0x0133
	.short 0x0058
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0113
	.short 0x006A
	.short 0x0135
	.short 0x007D
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0115
	.short 0x006C
	.short 0x0133
	.short 0x007B
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x0043
	.short 0x00D0
	.short 0x0043
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x0044
	.short 0x00D0
	.short 0x0044
DL_F3BA91:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F7	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F39602	; +0x07 -> XIY: string table
	.short 0x0007	; +0x0B -> BC: bytes per entry
	.short 0x1256	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F8	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F39602	; +0x07 -> XIY: string table
	.short 0x0007	; +0x0B -> BC: bytes per entry
	.short 0x125E	; +0x0D -> IX
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x124E	; +0x07 -> IX
	.byte 0x02	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
DL_F3BAB9:
	.byte 0x1C, 0x19	; op 1C, 25 bytes -> handler 0xF31A52
	.short 0x0048
	.short 0x0005
	.ascii "AFTER T0UCH SETTING"
	.byte 0x07, 0x25	; op 07, 37 bytes -> handler 0xF31A3A
	.short 0x070A
	.ascii "Select whether or not After Touch"
	.byte 0x07, 0x21	; op 07, 33 bytes -> handler 0xF31A3A
	.short 0x0A02
	.ascii "is recorded by the Sequencer."
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11A7
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x11CB
	.ascii "EN"
	.byte 0x07, 0x18	; op 07, 24 bytes -> handler 0xF31A3A
	.short 0x1453
	.ascii "AFTER TOUCH RECORD :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x171F
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x1743
	.ascii "DIS"
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x39
	.short 0x002D
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000A
	.short 0x006A
	.short 0x00FE
	.short 0x00A5
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x006C
	.short 0x0134
	.short 0x007F
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x006E
	.short 0x0132
	.short 0x007D
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0114
	.short 0x008F
	.short 0x0134
	.short 0x00A2
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0116
	.short 0x0091
	.short 0x0132
	.short 0x00A0
DL_F3BB7E:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0x01	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3BB97	; +0x07 -> XIY: string table
	.short 0x0007	; +0x0B -> BC: bytes per entry
	.short 0x1467	; +0x0D -> IX
DL_F3BB8D:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x00B8
	.short 0x0082
	.short 0x00F8
	.short 0x008A

; ==================================================================
; 0xF3BB97-0xF3BBA4 -- display-list OPERAND TABLES (14 bytes, 1 objects)
; ==================================================================
;
; Every object here is named by a display-list record that points at it, and
; its SIZE is proven by tiling: the objects start at the first byte of this
; gap, each extent is a whole number of entries, and the last object's
; handler-implied size ends exactly on the first byte of the next display
; list.  Reproduce with `python3 notes/prom_b_dl_operand_tables.py --exact`.
;
; ------------------------------------------------------------------
; DLTable_F3BB97 -- 2 entries of 7 characters
; Referenced by: display-list record 0xF3BB7E
; Evidence: the record's +7 pointer lands here and its +0x0B word is 7, so the
;           entries are 7 bytes wide (handler 0xF31B21/0xF31B39 loads the
;           extracted bit-field into HL as the index).
;           2 entries is the EXTENT (14 bytes / 7), not the (mask >> shift) + 1
;           = 2 the record would allow.
; ------------------------------------------------------------------
DLTable_F3BB97:
	.ascii "DISABLE"	; [0]
	.ascii "ENABLE "	; [1]

; ------------------------------------------------------------------
; 0xF3BBA5-0xF3BD57 -- 47 display-list records, 435 bytes -- interpreter A (40 records) and B (7)
;   entered at: 0xF3BBA5, 0xF3BC93, 0xF3BCCB, 0xF3BD07
;   ends used:  0xF3BC93, 0xF3BCCB, 0xF3BD07, 0xF3BD4D, 0xF3BD58
; ------------------------------------------------------------------
DL_F3BBA5:
	.byte 0x1C, 0x12	; op 1C, 18 bytes -> handler 0xF31A52
	.short 0x0060
	.short 0x0006
	.ascii "MEASURE C0PY"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0617
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x0E	; op 07, 14 bytes -> handler 0xF31A3A
	.short 0x0A53
	.ascii "FROM TRACK"
	.byte 0x07, 0x0C	; op 07, 12 bytes -> handler 0xF31A3A
	.short 0x0A68
	.ascii "TO TRACK"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B68
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8F
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0C88
	.ascii ":"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0C9D
	.ascii ":"
	.byte 0x07, 0x11	; op 07, 17 bytes -> handler 0xF31A3A
	.short 0x1043
	.ascii "FIRST MEASURE"
	.byte 0x07, 0x11	; op 07, 17 bytes -> handler 0xF31A3A
	.short 0x1058
	.ascii "START MEASURE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1158
	.byte 0x10	; character codes below 0x20
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x009B
	.short 0x006F
	.byte 0x8A	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x117F
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1278
	.ascii ":"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x128D
	.ascii ":"
	.byte 0x07, 0x10	; op 07, 16 bytes -> handler 0xF31A3A
	.short 0x165B
	.ascii "LAST MEASURE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1748
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x0C	; op 07, 12 bytes -> handler 0xF31A3A
	.short 0x1760
	.ascii "REPEAT :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1797
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1890
	.ascii ":"
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x45
	.short 0x0030
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0090
	.short 0x003F
	.short 0x0093
	.short 0x003F
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00AB
	.short 0x003F
	.short 0x00AE
	.short 0x003F
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00AB
	.short 0x0086
	.short 0x00AE
	.short 0x0086
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0090
	.short 0x00AC
	.short 0x0093
	.short 0x00AC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0093
	.short 0x003F
	.short 0x0093
	.short 0x00AC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00AB
	.short 0x003F
	.short 0x00AB
	.short 0x0086
DL_F3BC93:
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x063C
	.ascii "OK"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011B
	.short 0x0022
	.short 0x0135
	.short 0x0035
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x0024
	.short 0x0133
	.short 0x0033
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x210E
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x233E
	.byte 0x8E	; character codes below 0x20
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00D4
	.short 0x00C2
	.short 0x00EC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00E0
	.short 0x00C4
	.short 0x00E0
DL_F3BCCB:
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x003F
	.short 0x008A
	.short 0x005E
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00B3
	.short 0x003F
	.short 0x0132
	.short 0x005E
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0065
	.short 0x008A
	.short 0x0084
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00B3
	.short 0x0065
	.short 0x0132
	.short 0x0084
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00B3
	.short 0x008F
	.short 0x0132
	.short 0x00A6
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x008B
	.short 0x008A
	.short 0x00AA
DL_F3BD07:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0x1F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3A72F	; +0x07 -> XIY: string table
	.short 0x0006	; +0x0B -> BC: bytes per entry
	.short 0x0C89	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12FB	; +0x02 source variable, 16-bit address
	.byte 0x1F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3A72F	; +0x07 -> XIY: string table
	.short 0x0006	; +0x0B -> BC: bytes per entry
	.short 0x0C9E	; +0x0D -> IX
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F7	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1279	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F9	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1891	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12FC	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x128E	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12FE	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1768	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x12FF	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F3BD58	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF3BD58-0xF3BD8F: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03BD58, 0x000038

; ------------------------------------------------------------------
; 0xF3BD90-0xF3BF47 -- 49 display-list records, 440 bytes -- interpreter A (42 records) and B (7)
;   entered at: 0xF3BD90, 0xF3BDCF, 0xF3BEBF, 0xF3BEF7
;   ends used:  0xF3BDCF, 0xF3BEBF, 0xF3BEF7, 0xF3BF3D, 0xF3BF48
; ------------------------------------------------------------------
DL_F3BD90:
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x05EF
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x063B
	.ascii "YES"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1DAF
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x1DD3
	.ascii "NO"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0113
	.short 0x0022
	.short 0x0135
	.short 0x0035
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0115
	.short 0x0024
	.short 0x0133
	.short 0x0033
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0113
	.short 0x00B9
	.short 0x0135
	.short 0x00CC
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0115
	.short 0x00BB
	.short 0x0133
	.short 0x00CA
DL_F3BDCF:
	.byte 0x1C, 0x14	; op 1C, 20 bytes -> handler 0xF31A52
	.short 0x005F
	.short 0x0006
	.ascii "MEASURE INSERT"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x05C7
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x0E	; op 07, 14 bytes -> handler 0xF31A3A
	.short 0x0A53
	.ascii "FROM TRACK"
	.byte 0x07, 0x0C	; op 07, 12 bytes -> handler 0xF31A3A
	.short 0x0A68
	.ascii "TO TRACK"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B68
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8F
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0C88
	.ascii ":"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0C9D
	.ascii ":"
	.byte 0x07, 0x11	; op 07, 17 bytes -> handler 0xF31A3A
	.short 0x1043
	.ascii "FIRST MEASURE"
	.byte 0x07, 0x11	; op 07, 17 bytes -> handler 0xF31A3A
	.short 0x1058
	.ascii "START MEASURE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1158
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x117F
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1278
	.ascii ":"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0098
	.short 0x0076
	.byte 0x8A	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x128D
	.ascii ":"
	.byte 0x07, 0x10	; op 07, 16 bytes -> handler 0xF31A3A
	.short 0x1633
	.ascii "LAST MEASURE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1748
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x0C	; op 07, 12 bytes -> handler 0xF31A3A
	.short 0x1760
	.ascii "REPEAT :"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1797
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1868
	.ascii ":"
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x48
	.short 0x0030
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0090
	.short 0x003F
	.short 0x0093
	.short 0x003F
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00AB
	.short 0x003F
	.short 0x00AE
	.short 0x003F
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00AB
	.short 0x0086
	.short 0x00AE
	.short 0x0086
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0090
	.short 0x00AC
	.short 0x0093
	.short 0x00AC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0093
	.short 0x003F
	.short 0x0093
	.short 0x00AC
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00AB
	.short 0x003F
	.short 0x00AB
	.short 0x0086
DL_F3BEBF:
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x05EC
	.ascii "OK"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011C
	.short 0x0020
	.short 0x0134
	.short 0x0033
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011E
	.short 0x0022
	.short 0x0132
	.short 0x0031
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x210E
	.byte 0x8D	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x233E
	.byte 0x8E	; character codes below 0x20
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00D4
	.short 0x00C2
	.short 0x00EC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00E0
	.short 0x00C4
	.short 0x00E0
DL_F3BEF7:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0x1F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3A72F	; +0x07 -> XIY: string table
	.short 0x0006	; +0x0B -> BC: bytes per entry
	.short 0x0C89	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x12FB	; +0x02 source variable, 16-bit address
	.byte 0x1F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3A72F	; +0x07 -> XIY: string table
	.short 0x0006	; +0x0B -> BC: bytes per entry
	.short 0x0C9E	; +0x0D -> IX
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F7	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1279	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F9	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1869	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x06, 0x0A	; B op 06, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12FC	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x128E	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12FE	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1768	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x12FF	; +0x02 source variable, 16-bit address
	.byte 0x07	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F3BF48	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF3BF48-0xF3BF7F: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03BF48, 0x000038

; ------------------------------------------------------------------
; 0xF3BF80-0xF3C198 -- 49 display-list records, 537 bytes -- interpreter A (45 records) and B (4)
;   entered at: 0xF3BF80, 0xF3BFF8, 0xF3C133, 0xF3C145, 0xF3C15D, 0xF3C16C, 0xF3C17B
;   ends used:  0xF3BFF8, 0xF3C133, 0xF3C145, 0xF3C15D, 0xF3C16C, 0xF3C17B, 0xF3C199
; ------------------------------------------------------------------
DL_F3BF80:
	.byte 0x1C, 0x0F	; op 1C, 15 bytes -> handler 0xF31A52
	.short 0x0078
	.short 0x0006
	.ascii "S0NG C0PY"
	.byte 0x07, 0x08	; op 07, 8 bytes -> handler 0xF31A3A
	.short 0x0648
	.ascii "FROM"
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x065A
	.ascii "TO"
	.byte 0x07, 0x09	; op 07, 9 bytes -> handler 0xF31A3A
	.short 0x0A7F
	.ascii "SONG "
	.byte 0x07, 0x09	; op 07, 9 bytes -> handler 0xF31A3A
	.short 0x0A90
	.ascii "SONG "
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B8F
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x0BB4
	.ascii "OK"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0D9F
	.ascii ":"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0DB0
	.ascii ":"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0093
	.short 0x005F
	.byte 0x8A	; character codes below 0x20
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x0038
	.short 0x007B
	.short 0x008F
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00B7
	.short 0x0038
	.short 0x0104
	.short 0x008F
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x006E
	.short 0x007D
	.short 0x006E
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00B7
	.short 0x006E
	.short 0x0106
	.short 0x006E
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x41
	.short 0x0034
DL_F3BFF8:
	.byte 0x07, 0x08	; op 07, 8 bytes -> handler 0xF31A3A
	.short 0x1B10
	.ascii "FROM"
	.byte 0x07, 0x06	; op 07, 6 bytes -> handler 0xF31A3A
	.short 0x1B25
	.ascii "TO"
	.byte 0x06, 0x28	; op 06, 40 bytes -> handler 0xF31A3A
	.short 0x1EF2
	.ascii "SONG NO   TR/ALL    SONG NO   TR/ALL"
	.byte 0x06, 0x29	; op 06, 41 bytes -> handler 0xF31A3A
	.short 0x2239
	.ascii " <    >    <    >    <    >    <    >"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00D3
	.short 0x0022
	.short 0x00EB
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00D3
	.short 0x004A
	.short 0x00EB
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0051
	.short 0x00D3
	.short 0x006E
	.short 0x00EB
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0079
	.short 0x00D3
	.short 0x0096
	.short 0x00EB
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A7
	.short 0x00D3
	.short 0x00C4
	.short 0x00EB
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00CF
	.short 0x00D3
	.short 0x00EC
	.short 0x00EB
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00D3
	.short 0x0112
	.short 0x00EB
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00D3
	.short 0x013A
	.short 0x00EB
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011B
	.short 0x0045
	.short 0x0135
	.short 0x0058
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x0047
	.short 0x0133
	.short 0x0056
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0004
	.short 0x00BD
	.short 0x0098
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A4
	.short 0x00BD
	.short 0x013B
	.short 0x00BD
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0004
	.short 0x00BE
	.short 0x0098
	.short 0x00BE
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A4
	.short 0x00BE
	.short 0x013B
	.short 0x00BE
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0004
	.short 0x00BD
	.short 0x0004
	.short 0x00C2
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00BD
	.short 0x0005
	.short 0x00C2
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0097
	.short 0x00BD
	.short 0x0097
	.short 0x00C2
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0098
	.short 0x00BD
	.short 0x0098
	.short 0x00C2
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A4
	.short 0x00BD
	.short 0x00A4
	.short 0x00C2
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00BD
	.short 0x00A5
	.short 0x00C2
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x013A
	.short 0x00BD
	.short 0x013A
	.short 0x00C2
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x013B
	.short 0x00BD
	.short 0x013B
	.short 0x00C2
DL_F3C133:
	.byte 0x07, 0x09	; op 07, 9 bytes -> handler 0xF31A3A
	.short 0x133F
	.ascii "TRACK"
	.byte 0x07, 0x09	; op 07, 9 bytes -> handler 0xF31A3A
	.short 0x1350
	.ascii "TRACK"
DL_F3C145:
	.byte 0x07, 0x0C	; op 07, 12 bytes -> handler 0xF31A3A
	.short 0x133F
	.ascii "  ALL   "
	.byte 0x07, 0x0C	; op 07, 12 bytes -> handler 0xF31A3A
	.short 0x1350
	.ascii "  ALL   "
DL_F3C15D:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x000012F8	; +0x07 -> XIY: string table
	.short 0x0006	; +0x0B -> BC: bytes per entry
	.short 0x0DA0	; +0x0D -> IX
DL_F3C16C:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x000012FE	; +0x07 -> XIY: string table
	.short 0x0006	; +0x0B -> BC: bytes per entry
	.short 0x0DB1	; +0x0D -> IX
DL_F3C17B:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1304	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3A7A1	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1344	; +0x0D -> IX
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1305	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.long 0x00F3A7A1	; +0x07 -> XIY: string table
	.short 0x0003	; +0x0B -> BC: bytes per entry
	.short 0x1355	; +0x0D -> IX

; --- 0xF3C199-0xF3C1AC: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03C199, 0x000014

; ------------------------------------------------------------------
; 0xF3C1AD-0xF3C350 -- 41 display-list records, 420 bytes -- interpreter A (37 records) and B (4)
;   entered at: 0xF3C1AD, 0xF3C31E
;   ends used:  0xF3C31E, 0xF3C351
; ------------------------------------------------------------------
DL_F3C1AD:
	.byte 0x1C, 0x18	; op 1C, 24 bytes -> handler 0xF31A52
	.short 0x0055
	.short 0x0005
	.ascii "S0NG SELECT & NAME"
	.byte 0x17, 0x09	; op 17, 9 bytes -> handler 0xF31A52
	.short 0x010A
	.short 0x0030
	.ascii " KB"
	.byte 0x1C, 0x0A	; op 1C, 10 bytes -> handler 0xF31A52
	.short 0x0030
	.short 0x003D
	.ascii "S0NG"
	.byte 0x08, 0x05	; op 08, 5 bytes -> handler 0xF31A3A
	.short 0x09A4
	.ascii ":"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0111
	.short 0x003D
	.ascii "%"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0073
	.short 0x003E
	.ascii ":"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11FF
	.ascii "_"
	.byte 0x06, 0x1E	; op 06, 30 bytes -> handler 0xF31A3A
	.short 0x1250
	.ascii " A B C D E F G H I J K L M"
	.byte 0x06, 0x1D	; op 06, 29 bytes -> handler 0xF31A3A
	.short 0x14A7
	.ascii "N O P Q R S T U V W X Y Z"
	.byte 0x06, 0x17	; op 06, 23 bytes -> handler 0xF31A3A
	.short 0x1727
	.ascii "O 1 2 3 4 5 6 7 8 9"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x1C61
	.ascii "NAME"
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x1ECB
	.ascii "SONG"
	.byte 0x06, 0x0C	; op 06, 12 bytes -> handler 0xF31A3A
	.short 0x1ED8
	.ascii "POSITION"
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x1EE2
	.ascii "ABC"
	.byte 0x16, 0x06	; op 16, 6 bytes -> handler 0xF31A3A
	.short 0x1EE5
	.byte 0x16, 0x16	; character codes below 0x20
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x1EE7
	.ascii "789"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x223A
	.ascii "<"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x223F
	.ascii ">"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2249
	.ascii "<"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x224E
	.ascii ">"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2253
	.ascii "<"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x2258
	.ascii ">"
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x225C
	.ascii "CLR"
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x35
	.short 0x002F
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0026
	.short 0x002A
	.short 0x0122
	.short 0x0054
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00D3
	.short 0x0022
	.short 0x00EB
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00D3
	.short 0x004A
	.short 0x00EB
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00D3
	.short 0x009A
	.short 0x00EB
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00D3
	.short 0x00C2
	.short 0x00EB
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00D3
	.short 0x00EA
	.short 0x00EB
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00D3
	.short 0x0112
	.short 0x00EB
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00D3
	.short 0x013A
	.short 0x00EB
	.byte 0x13, 0x0A	; op 13, 10 bytes -> handler 0xF31A75
	.short 0x0026
	.short 0x006A
	.short 0x0122
	.short 0x00A7
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007B
	.short 0x00BA
	.short 0x00BF
	.short 0x00BA
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00F4
	.short 0x00BA
	.short 0x013C
	.short 0x00BA
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x007B
	.short 0x00BA
	.short 0x007B
	.short 0x00BE
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x013C
	.short 0x00BA
	.short 0x013C
	.short 0x00BF
DL_F3C31E:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x0000	; +0x02 source variable, 16-bit address
	.byte 0x00	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x08	; +0x06 swi 7 function
	.long 0x000012F6	; +0x07 -> XIY: string table
	.short 0x0006	; +0x0B -> BC: bytes per entry
	.short 0x0998	; +0x0D -> IX
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x12FC	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1C	; +0x06 swi 7 function
	.short 0x005C	; +0x07 -> (0x2530)
	.short 0x003D	; +0x09 -> (0x2532)
	.byte 0x02	; +0x0B digit count
	.byte 0x0A, 0x0C	; B op 0A, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x12FD	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x17	; +0x06 swi 7 function
	.short 0x00F8	; +0x07 -> (0x2530)
	.short 0x0030	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count
	.byte 0x09, 0x0C	; B op 09, 12 bytes -> handler 0xF31C14 -- decimal readout, unsigned, two extra words
	.short 0x12FF	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1C	; +0x06 swi 7 function
	.short 0x00F0	; +0x07 -> (0x2530)
	.short 0x003D	; +0x09 -> (0x2532)
	.byte 0x03	; +0x0B digit count

; --- 0xF3C351-0xF3C366: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03C351, 0x000016

; ------------------------------------------------------------------
; 0xF3C367-0xF3C37C -- 2 display-list records, 22 bytes -- interpreter B
;   entered at: 0xF3C367
;   ends used:  0xF3C372, 0xF3C37D
; ------------------------------------------------------------------
DL_F3C367:
	.byte 0x08, 0x0B	; B op 08, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x1301	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1B	; +0x06 swi 7 function
	.long 0x00F3C37D	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x08, 0x0B	; B op 08, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x1302	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x1B	; +0x06 swi 7 function
	.long 0x00F3C3AD	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF3C37D-0xF3C4D4: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03C37D, 0x000158

; ------------------------------------------------------------------
; 0xF3C4D5-0xF3C53E -- 7 display-list records, 106 bytes -- interpreter A (6 records) and B (1)
;   entered at: 0xF3C4D5, 0xF3C530
;   ends used:  0xF3C530, 0xF3C53F
; ------------------------------------------------------------------
DL_F3C4D5:
	.byte 0x06, 0x0E	; op 06, 14 bytes -> handler 0xF31A3A
	.short 0x1863
	.ascii "A current "
	.byte 0x06, 0x12	; op 06, 18 bytes -> handler 0xF31A3A
	.short 0x1874
	.ascii " track will be"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1AA7
	.ascii "."
	.byte 0x06, 0x18	; op 06, 24 bytes -> handler 0xF31A3A
	.short 0x1AE3
	.ascii "cleared automaticaly"
	.byte 0x1C, 0x14	; op 1C, 20 bytes -> handler 0xF31A52
	.short 0x0040
	.short 0x00C4
	.ascii "Are You Sure ?"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0011
	.short 0x0098
	.short 0x0122
	.short 0x00E9
DL_F3C530:
	.byte 0x02, 0x0F	; B op 02, 15 bytes -> handler 0xF31B21 -- string-table readout: HL = extracted value = entry index
	.short 0x1307	; +0x02 source variable, 16-bit address
	.byte 0x7F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x06	; +0x06 swi 7 function
	.long 0x00F3C53F	; +0x07 -> XIY: string table
	.short 0x0007	; +0x0B -> BC: bytes per entry
	.short 0x186D	; +0x0D -> IX

; --- 0xF3C53F-0xF3C561: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03C53F, 0x000023

; ------------------------------------------------------------------
; 0xF3C562-0xF3C6B2 -- 37 display-list records, 337 bytes -- interpreter A
;   entered at: 0xF3C562
;   ends used:  0xF3C6B3
; ------------------------------------------------------------------
DL_F3C562:
	.byte 0x1C, 0x16	; op 1C, 22 bytes -> handler 0xF31A52
	.short 0x0058
	.short 0x0006
	.ascii "SEQUENCER MEDLEY"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0B67
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x0B89
	.ascii "START"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0C08
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x12	; op 07, 18 bytes -> handler 0xF31A3A
	.short 0x0C0C
	.ascii "FIRST S0NG    "
	.byte 0x08, 0x05	; op 08, 5 bytes -> handler 0xF31A3A
	.short 0x118D
	.byte 0x89	; character codes below 0x20
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x11F7
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x1219
	.ascii "STOP"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1797
	.byte 0x11	; character codes below 0x20
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x17B9
	.ascii "SKIP"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x17E8
	.byte 0x10	; character codes below 0x20
	.byte 0x07, 0x12	; op 07, 18 bytes -> handler 0xF31A3A
	.short 0x1814
	.ascii "LAST S0NG     "
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x1F55
	.ascii "SONG"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00F7
	.short 0x00D2
	.ascii "MIDI"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0120
	.short 0x00D2
	.ascii "NORM"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x210E
	.byte 0x8D	; character codes below 0x20
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x00F7
	.short 0x00DD
	.ascii "FILE"
	.byte 0x17, 0x0A	; op 17, 10 bytes -> handler 0xF31A52
	.short 0x0120
	.short 0x00DD
	.ascii "FILE"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x233E
	.byte 0x8E	; character codes below 0x20
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x00FE
	.short 0x00E5
	.byte 0x12	; character codes below 0x20
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0128
	.short 0x00E5
	.byte 0x12	; character codes below 0x20
	.byte 0x17, 0x07	; op 17, 7 bytes -> handler 0xF31A52
	.short 0x00C4
	.short 0x004F
	.byte 0x10	; character codes below 0x20
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x38
	.short 0x0030
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0043
	.short 0x00C2
	.short 0x0062
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x008F
	.short 0x00C2
	.short 0x00AE
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00D4
	.short 0x00C2
	.short 0x00EC
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0104
	.short 0x0044
	.short 0x0134
	.short 0x0057
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0106
	.short 0x0046
	.short 0x0132
	.short 0x0055
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0104
	.short 0x006E
	.short 0x0134
	.short 0x0081
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0106
	.short 0x0070
	.short 0x0132
	.short 0x007F
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0104
	.short 0x0092
	.short 0x0134
	.short 0x00A5
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x00F3
	.short 0x00CE
	.short 0x0113
	.short 0x00E7
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x011C
	.short 0x00CE
	.short 0x013D
	.short 0x00E7
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00C2
	.short 0x0052
	.short 0x00D2
	.short 0x0052
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00C2
	.short 0x00A0
	.short 0x00D2
	.short 0x00A0
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00E0
	.short 0x00C4
	.short 0x00E0
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x00D2
	.short 0x0052
	.short 0x00D2
	.short 0x00A0

; --- 0xF3C6B3-0xF3C720: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03C6B3, 0x00006E

; ------------------------------------------------------------------
; 0xF3C721-0xF3C7AC -- 15 display-list records, 140 bytes -- interpreter A (10 records) and B (5)
;   entered at: 0xF3C721, 0xF3C778
;   ends used:  0xF3C778, 0xF3C78C, 0xF3C7AD
; ------------------------------------------------------------------
DL_F3C721:
	.byte 0x06, 0x0A	; op 06, 10 bytes -> handler 0xF31A3A
	.short 0x1E56
	.ascii "SELECT"
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x219D
	.ascii "INT"
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x21A3
	.ascii "FD"
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x002E
	.short 0x00E5
	.byte 0x12	; character codes below 0x20
	.byte 0x1C, 0x07	; op 1C, 7 bytes -> handler 0xF31A52
	.short 0x0059
	.short 0x00E5
	.byte 0x12	; character codes below 0x20
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0024
	.short 0x00D4
	.short 0x0044
	.short 0x00E4
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x004D
	.short 0x00D4
	.short 0x006D
	.short 0x00E4
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0024
	.short 0x00CE
	.short 0x006D
	.short 0x00CE
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x0024
	.short 0x00CE
	.short 0x0024
	.short 0x00D1
	.byte 0x02, 0x0A	; op 02, 10 bytes -> handler 0xF31A75
	.short 0x006D
	.short 0x00CE
	.short 0x006D
	.short 0x00D1
DL_F3C778:
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12FE	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x0C1A	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x1300	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x1822	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x1302	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F3C7E3	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x1303	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F3C7FB	; +0x07 -> XIX: array of 8-byte entries, indexed by the value
	.byte 0x03, 0x0B	; B op 03, 11 bytes -> handler 0xF31B57 -- four words of entry[value] -> (0x2530..0x2536)
	.short 0x1304	; +0x02 source variable, 16-bit address
	.byte 0x0F	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x05	; +0x06 swi 7 function
	.long 0x00F3C813	; +0x07 -> XIX: array of 8-byte entries, indexed by the value

; --- 0xF3C7AD-0xF3C7C2: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03C7AD, 0x000016

; ------------------------------------------------------------------
; 0xF3C7C3-0xF3C7CC -- 1 display-list records, 10 bytes -- interpreter A
;   entered at: 0xF3C7C3
;   ends used:  0xF3C7CD
; ------------------------------------------------------------------
DL_F3C7C3:
	.byte 0x1B, 0x0A	; op 1B, 10 bytes -> handler 0xF31A75
	.short 0x0024
	.short 0x00D4
	.short 0x0098
	.short 0x00E4

; --- 0xF3C7CD-0xF3C86A: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03C7CD, 0x00009E

; ------------------------------------------------------------------
; 0xF3C86B-0xF3C872 -- 1 display-list records, 8 bytes -- interpreter A
;   entered at: 0xF3C86B
;   ends used:  0xF3C873
; ------------------------------------------------------------------
DL_F3C86B:
	.byte 0x0E, 0x08	; op 0E, 8 bytes -> handler 0xF31A9F
	.short 0x05CC
	.short 0x0021
	.short 0x0010

; --- 0xF3C873-0xF3C89C: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03C873, 0x00002A

; ------------------------------------------------------------------
; 0xF3C89D-0xF3C946 -- 9 display-list records, 170 bytes -- interpreter A (8 records) and B (1)
;   entered at: 0xF3C89D, 0xF3C8A7
;   ends used:  0xF3C8A7, 0xF3C947
; ------------------------------------------------------------------
DL_F3C89D:
	.byte 0x00, 0x0A	; B op 00, 10 bytes -> handler 0xF31BA1 -- decimal readout, unsigned (0xF8BCAF via T_F41AF0)
	.short 0x12F6	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x07	; +0x06 swi 7 function
	.short 0x05DD	; +0x07 -> IX
	.byte 0x03	; +0x09 digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663
DL_F3C8A7:
	.byte 0x1C, 0x11	; op 1C, 17 bytes -> handler 0xF31A52
	.short 0x0044
	.short 0x0005
	.ascii "STEP RECORD"
	.byte 0x07, 0x11	; op 07, 17 bytes -> handler 0xF31A3A
	.short 0x0109
	.ascii ": PART SELECT"
	.byte 0x07, 0x22	; op 07, 34 bytes -> handler 0xF31A3A
	.short 0x07FB
	.ascii "Press the up/down button under"
	.byte 0x07, 0x23	; op 07, 35 bytes -> handler 0xF31A3A
	.short 0x0B43
	.ascii "the screen corresponding to the"
	.byte 0x07, 0x1A	; op 07, 26 bytes -> handler 0xF31A3A
	.short 0x0E3B
	.ascii "track that you want to"
	.byte 0x07, 0x10	; op 07, 16 bytes -> handler 0xF31A3A
	.short 0x11AB
	.ascii "STEP RECORD."
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0013
	.short 0x0027
	.short 0x0122
	.short 0x0086
	.byte 0x23, 0x05	; op 23, 5 bytes -> handler 0xF31ACE
	.byte 0x34
	.short 0x002D

; --- 0xF3C947-0xF3D015: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03C947, 0x0006CF

; ------------------------------------------------------------------
; 0xF3D016-0xF3D088 -- 13 display-list records, 115 bytes -- interpreter A
;   entered at: 0xF3D016
;   ends used:  0xF3D089
; ------------------------------------------------------------------
DL_F3D016:
	.byte 0x07, 0x10	; op 07, 16 bytes -> handler 0xF31A3A
	.short 0x0033
	.ascii "STEP RECORD:"
	.byte 0x06, 0x0A	; op 06, 10 bytes -> handler 0xF31A3A
	.short 0x028F
	.ascii "TRACK:"
	.byte 0x06, 0x09	; op 06, 9 bytes -> handler 0xF31A3A
	.short 0x171A
	.ascii "TRACK"
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x199B
	.ascii "CLR"
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0115
	.short 0x00A0
	.short 0x0133
	.short 0x00AF
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0113
	.short 0x009E
	.short 0x0135
	.short 0x00B1
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1977
	.byte 0x11	; character codes below 0x20
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00AF
	.short 0x00FA
	.short 0x00C3
	.byte 0x06, 0x08	; op 06, 8 bytes -> handler 0xF31A3A
	.short 0x1F19
	.ascii "MEAS"
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x20D2
	.byte 0x8D	; character codes below 0x20
	.byte 0x06, 0x05	; op 06, 5 bytes -> handler 0xF31A3A
	.short 0x22DA
	.byte 0x8E	; character codes below 0x20
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00D2
	.short 0x0023
	.short 0x00EC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00DF
	.short 0x0023
	.short 0x00DF

; --- 0xF3D089-0xF3DA6E: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03D089, 0x0009E6

; ------------------------------------------------------------------
; 0xF3DA6F-0xF3DA76 -- 1 display-list records, 8 bytes -- interpreter A
;   entered at: 0xF3DA6F
;   ends used:  0xF3DA77
; ------------------------------------------------------------------
DL_F3DA6F:
	.byte 0x0E, 0x08	; op 0E, 8 bytes -> handler 0xF31A9F
	.short 0x1159
	.short 0x0021
	.short 0x000D

; --- 0xF3DA77-0xF3DBFF: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03DA77, 0x000189

; ------------------------------------------------------------------
; 0xF3DC00-0xF3DC20 -- 3 display-list records, 33 bytes -- interpreter B
;   entered at: 0xF3DC00
;   ends used:  0xF3DC21
; ------------------------------------------------------------------
DL_F3DC00:
	.byte 0x04, 0x0B	; B op 04, 11 bytes -> handler 0xF31B86 -- entry[value] -> IY, BC, HL
	.short 0x2640	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x0E	; +0x06 swi 7 function
	.long 0x00F3DC21	; +0x07 -> XIX: array of 6-byte entries, indexed by the value
	.byte 0x04, 0x0B	; B op 04, 11 bytes -> handler 0xF31B86 -- entry[value] -> IY, BC, HL
	.short 0x2641	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x0E	; +0x06 swi 7 function
	.long 0x00F3DC3F	; +0x07 -> XIX: array of 6-byte entries, indexed by the value
	.byte 0x04, 0x0B	; B op 04, 11 bytes -> handler 0xF31B86 -- entry[value] -> IY, BC, HL
	.short 0x2642	; +0x02 source variable, 16-bit address
	.byte 0xFF	; +0x04 AND mask
	.byte 0x00	; +0x05 right shift, low 3 bits
	.byte 0x0E	; +0x06 swi 7 function
	.long 0x00F3DC5D	; +0x07 -> XIX: array of 6-byte entries, indexed by the value

; --- 0xF3DC21-0xF3DE25: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03DC21, 0x000205

; ------------------------------------------------------------------
; 0xF3DE26-0xF3DEB1 -- 14 display-list records, 140 bytes -- interpreter A
;   entered at: 0xF3DE26
;   ends used:  0xF3DEB2
; ------------------------------------------------------------------
DL_F3DE26:
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00D2
	.short 0x0023
	.short 0x00EC
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00D2
	.short 0x004B
	.short 0x00EC
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00D2
	.short 0x0073
	.short 0x00EC
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00D2
	.short 0x009B
	.short 0x00EC
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00D2
	.short 0x00C3
	.short 0x00EC
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00D2
	.short 0x00EB
	.short 0x00EC
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x00F5
	.short 0x00D2
	.short 0x0113
	.short 0x00EC
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x011D
	.short 0x00D2
	.short 0x013B
	.short 0x00EC
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0005
	.short 0x00DF
	.short 0x0023
	.short 0x00DF
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002D
	.short 0x00DF
	.short 0x004B
	.short 0x00DF
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x0055
	.short 0x00DF
	.short 0x0073
	.short 0x00DF
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x007D
	.short 0x00DF
	.short 0x009B
	.short 0x00DF
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00A5
	.short 0x00DF
	.short 0x00C3
	.short 0x00DF
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x00CD
	.short 0x00DF
	.short 0x00EB
	.short 0x00DF

; --- 0xF3DEB2-0xF3E06D: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03DEB2, 0x0001BC

; ------------------------------------------------------------------
; 0xF3E06E-0xF3E15B -- 17 display-list records, 238 bytes -- interpreter A
;   entered at: 0xF3E06E
;   ends used:  0xF3E15C
; ------------------------------------------------------------------
DL_F3E06E:
	.byte 0x1C, 0x18	; op 1C, 24 bytes -> handler 0xF31A52
	.short 0x0038
	.short 0x0003
	.ascii "MASTER TRACK CLEAR"
	.byte 0x08, 0x0E	; op 08, 14 bytes -> handler 0xF31A3A
	.short 0x075E
	.ascii "ATTENTION!"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x0BB7
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x21	; op 07, 33 bytes -> handler 0xF31A3A
	.short 0x0BBA
	.ascii "Using MASTER TRACK CLEAR will"
	.byte 0x06, 0x07	; op 06, 7 bytes -> handler 0xF31A3A
	.short 0x0C03
	.ascii "YES"
	.byte 0x07, 0x21	; op 07, 33 bytes -> handler 0xF31A3A
	.short 0x0E62
	.ascii "erase any existing recordings"
	.byte 0x07, 0x05	; op 07, 5 bytes -> handler 0xF31A3A
	.short 0x1157
	.byte 0x11	; character codes below 0x20
	.byte 0x07, 0x18	; op 07, 24 bytes -> handler 0xF31A3A
	.short 0x115A
	.ascii "in the MASTER TRACK."
	.byte 0x06, 0x06	; op 06, 6 bytes -> handler 0xF31A3A
	.short 0x117B
	.ascii "N0"
	.byte 0x08, 0x11	; op 08, 17 bytes -> handler 0xF31A3A
	.short 0x151B
	.ascii "Are You Sure?"
	.byte 0x0A, 0x0A	; op 0A, 10 bytes -> handler 0xF31A75
	.short 0x000B
	.short 0x0025
	.short 0x0108
	.short 0x009D
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0113
	.short 0x0047
	.short 0x0135
	.short 0x005A
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0115
	.short 0x0049
	.short 0x0133
	.short 0x0058
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0113
	.short 0x006A
	.short 0x0135
	.short 0x007D
	.byte 0x09, 0x0A	; op 09, 10 bytes -> handler 0xF31A75
	.short 0x0115
	.short 0x006C
	.short 0x0133
	.short 0x007B
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x003F
	.short 0x00CE
	.short 0x003F
	.byte 0x01, 0x0A	; op 01, 10 bytes -> handler 0xF31A75
	.short 0x002E
	.short 0x0040
	.short 0x00CE
	.short 0x0040

; --- 0xF3E15C-0xF3FFFF: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03E15C, 0x001EA4

; ==============================================================================
; 0xF40000-0xF44017 -- THUNK TABLE  (the routine directory of the 1 MiB image)
; ==============================================================================
;
; WHAT IT IS.  16,408 bytes of 4-byte slots.  A slot is one of exactly three
; things, and the split is decided by bytes alone (the gate re-checks every one
; of them):
;
;   `1B lo mid hi`      `jp nnn` -- a thunk.  1976 slots.  The operand is a
;                       routine entry point somewhere in the 1 MiB prom_a+prom_b
;                       image: 1255 of them land in prom_a (0xF80000-0xFFFFFF)
;                       and 721 in prom_b itself.  1910 are distinct.
;   `lo mid hi 00`      a 32-bit little-endian pointer with a zero top byte, i.e.
;                       a 24-bit address in a 32-bit slot.  26 slots.  25 of the
;                       26 point at a short run of further thunk slots -- see
;                       "the pointer slots" below.
;   0x0E / 0x00 fill    2100 slots.  0x0E is `ret`
;                       (mame/src/devices/cpu/tlcs900/dasm900.cpp:1267 puts
;                       M_RET at opcode 0x0E), so an unused slot returns rather
;                       than running on.  0x00 (`nop`) fill occurs in eight
;                       stretches: four are the three bytes after a LONE `ret`
;                       slot (`0E 00 00 00`, at 0xF40788 / 0xF40FC0 / 0xF40FC4 /
;                       0xF42ECC), and four are whole zeroed slots -- 8, 4, 4 and
;                       44 bytes at 0xF40A34, 0xF40A68, 0xF41F50 and 0xF42AC0.
;
; WHY IT MATTERS.  Callers do not call routines here; they call THE SLOT.  Every
; `call nnn` in prom_a and prom_b whose operand lands in 0xF40000-0xF44017 is a
; call through this directory, and there are thousands of them.  So the table is
; the single best index of "what routines exist" in an image that is otherwise
; 1 MiB of undifferentiated bytes -- which is exactly why it is the first thing
; converted here.
;
; LABELS.  Each slot is labelled `T_<its own address>`, e.g. `T_F42E24`.  This is
; deliberately an ADDRESS name, not a semantic one: the slot's address is what
; callers name, and nothing in the table itself says what the routine does.
; Semantic names belong on the TARGET, once the target has been read.  A handful
; of targets have been read and are named in the block comments below; the rest
; are honestly anonymous.
;
; ANNOTATIONS.  `x<N>` on a slot is the number of opcode-anchored references to
; that slot found by scanning prom_a and prom_b for `1D lo mid hi` (call nnn) and
; `1B lo mid hi` (jp nnn).  The scan is at every byte offset, not at instruction
; boundaries, so N is an UPPER BOUND: some hits are bytes lying inside another
; instruction or inside data.  Use it to RANK slots, never as an exact count.
; Generated by scripts/analysis/prom_b_thunk_table.py, which is the reproducible
; source of both this listing and the census in
; notes/FINDINGS-prom_b-thunk-table.md.
;
; THE POINTER SLOTS.  26 slots hold an address instead of an instruction.  Four
; point into this image (0xF44000, 0xF53000, 0xF57C00, 0xF5A800); the other 22
; into prom_a.  Counting how many thunk-shaped slots (a `jp`, a `ret` slot, or a
; zero slot) follow each target gives a sharp answer: 23 of the 26 are followed
; by EXACTLY SIX and then by something else, one (0xF57C00) by eight, one
; (0xF53000) by three, and one (0xFF75B6) by none -- 0xFF75B6 is code, not a
; table.  So 23 of these pointers name a 24-byte group of six thunks.  Example
; at both ends: T_F400A0 = 0x00F8E800, and prom_a 0xF8E800 reads
; `jp 0xF8E819` / `jp 0xF8E818` / `jp 0xF8E99F` / three more.
;
; ⚠ What READS these pointers has not been traced, so what a six-thunk group
; means -- a per-object vtable is the obvious guess -- is NOT established.
;
; NOT ESTABLISHED.  Why the table is banked the way it is (long runs share a
; 0xF8xxxx / 0xF9xxxx / 0xFAxxxx target prefix, separated by `ret` fill, which
; looks like one linker input file per run -- but that is a guess and is not
; asserted here); what the 0x00-filled stretches meant to the tool that emitted
; them; and what any individual routine does beyond the few named below.
;

T_F40000:	.long 0x00F82010	; ptr -> 0xF82010 (prom_a 0x02010)
T_F40004:	jp 0xF83171  ; -> prom_a 0x03171   x7
T_F40008:	jp 0xF83179  ; -> prom_a 0x03179   x7
T_F4000C:	jp 0xF83181  ; -> prom_a 0x03181   x7
T_F40010:	jp 0xF83189  ; -> prom_a 0x03189   x7
T_F40014:	jp 0xF82028  ; -> prom_a 0x02028
T_F40018:	jp 0xF823AC  ; -> prom_a 0x023AC   x16
T_F4001C:	jp 0xF8262E  ; -> prom_a 0x0262E
T_F40020:	jp 0xF825C7  ; -> prom_a 0x025C7
T_F40024:	jp 0xF82557  ; -> prom_a 0x02557   x2
T_F40028:	jp 0xF8262E  ; -> prom_a 0x0262E
T_F4002C:	jp 0xF82630  ; -> prom_a 0x02630
T_F40030:	jp 0xF82634  ; -> prom_a 0x02634
T_F40034:	jp 0xF82638  ; -> prom_a 0x02638   x2
T_F40038:	jp 0xF823C8  ; -> prom_a 0x023C8   x21
T_F4003C:	jp 0xF82407  ; -> prom_a 0x02407
T_F40040:	jp 0xF8262E  ; -> prom_a 0x0262E
T_F40044:	jp 0xF8262E  ; -> prom_a 0x0262E
T_F40048:	jp 0xF8262E  ; -> prom_a 0x0262E
T_F4004C:	jp 0xF8262E  ; -> prom_a 0x0262E
T_F40050:	jp 0xF8262E  ; -> prom_a 0x0262E
T_F40054:	jp 0xF8262E  ; -> prom_a 0x0262E
T_F40058:	jp 0xF8262E  ; -> prom_a 0x0262E
T_F4005C:	jp 0xF827C8  ; -> prom_a 0x027C8
	.fill 0x40, 1, 0x0E  ; 0xF40060: 64 x ret
; --- the SWI7 pair.  prom_a's vector table sends SWI7 (0xFFFF1C) here, not to a
;     routine: the vector value IS 0x00F400A4.  See the display-list block at
;     0xF31800 for what the service does and how its 64-entry table was found.
T_F400A0:	.long 0x00F8E800	; ptr -> 0xF8E800 (prom_a 0x0E800), itself a run of
				; `jp` thunks
T_F400A4:	jp 0xF8E9A5  ; -> prom_a 0x0E9A5   SWI7 SYSTEM-CALL ENTRY.  Masks A
				; with 0x3F and indexes the 64-entry service
				; table at prom_a 0xF8E9C6.
	.fill 0x28, 1, 0x0E  ; 0xF400A8: 40 x ret
T_F400D0:	jp 0xF95734  ; -> prom_a 0x15734
T_F400D4:	jp 0xF95765  ; -> prom_a 0x15765
T_F400D8:	jp 0xF95766  ; -> prom_a 0x15766
T_F400DC:	jp 0xF95767  ; -> prom_a 0x15767
T_F400E0:	jp 0xF95768  ; -> prom_a 0x15768
T_F400E4:	jp 0xF95795  ; -> prom_a 0x15795
T_F400E8:	jp 0xF95796  ; -> prom_a 0x15796
T_F400EC:	jp 0xF95797  ; -> prom_a 0x15797
T_F400F0:	jp 0xF95798  ; -> prom_a 0x15798
T_F400F4:	jp 0xF95890  ; -> prom_a 0x15890
T_F400F8:	jp 0xF95891  ; -> prom_a 0x15891
T_F400FC:	jp 0xF9598F  ; -> prom_a 0x1598F
T_F40100:	jp 0xF95990  ; -> prom_a 0x15990
T_F40104:	jp 0xF959BD  ; -> prom_a 0x159BD
T_F40108:	jp 0xF959BE  ; -> prom_a 0x159BE
T_F4010C:	jp 0xF959BF  ; -> prom_a 0x159BF
T_F40110:	jp 0xF959C0  ; -> prom_a 0x159C0
T_F40114:	jp 0xF959C1  ; -> prom_a 0x159C1
T_F40118:	jp 0xF959C2  ; -> prom_a 0x159C2
T_F4011C:	jp 0xF959C3  ; -> prom_a 0x159C3
T_F40120:	jp 0xF959C4  ; -> prom_a 0x159C4
T_F40124:	jp 0xF959C5  ; -> prom_a 0x159C5
T_F40128:	jp 0xF959C6  ; -> prom_a 0x159C6
T_F4012C:	jp 0xF959C7  ; -> prom_a 0x159C7
T_F40130:	jp 0xF959C8  ; -> prom_a 0x159C8
T_F40134:	jp 0xF959E1  ; -> prom_a 0x159E1
T_F40138:	jp 0xF959E2  ; -> prom_a 0x159E2
T_F4013C:	jp 0xF95C14  ; -> prom_a 0x15C14
T_F40140:	.long 0x00F94C00	; ptr -> 0xF94C00 (prom_a 0x14C00)
T_F40144:	jp 0xF95137  ; -> prom_a 0x15137   x1
T_F40148:	jp 0xF952FC  ; -> prom_a 0x152FC   x1
T_F4014C:	jp 0xF95444  ; -> prom_a 0x15444   x1
T_F40150:	jp 0xF95646  ; -> prom_a 0x15646
T_F40154:	jp 0xF95647  ; -> prom_a 0x15647
T_F40158:	jp 0xF95648  ; -> prom_a 0x15648
T_F4015C:	jp 0xF95659  ; -> prom_a 0x15659
T_F40160:	jp 0xF9565A  ; -> prom_a 0x1565A
T_F40164:	jp 0xF95669  ; -> prom_a 0x15669
T_F40168:	jp 0xF9566A  ; -> prom_a 0x1566A
T_F4016C:	jp 0xF95731  ; -> prom_a 0x15731
T_F40170:	jp 0xF95732  ; -> prom_a 0x15732
T_F40174:	jp 0xF95733  ; -> prom_a 0x15733
	.fill 0x58, 1, 0x0E  ; 0xF40178: 88 x ret
T_F401D0:	.long 0x00F96000	; ptr -> 0xF96000 (prom_a 0x16000)
T_F401D4:	jp 0xF96018  ; -> prom_a 0x16018   x6
T_F401D8:	jp 0xF96019  ; -> prom_a 0x16019   x5
T_F401DC:	jp 0xF9601D  ; -> prom_a 0x1601D   x3
T_F401E0:	jp 0xF96257  ; -> prom_a 0x16257
T_F401E4:	jp 0xF96258  ; -> prom_a 0x16258
T_F401E8:	jp 0xF96021  ; -> prom_a 0x16021   x1
T_F401EC:	jp 0xF96022  ; -> prom_a 0x16022   x1
T_F401F0:	jp 0xF96023  ; -> prom_a 0x16023
	.fill 0x1C, 1, 0x0E  ; 0xF401F4: 28 x ret
T_F40210:	.long 0x00F96400	; ptr -> 0xF96400 (prom_a 0x16400)
T_F40214:	jp 0xF96418  ; -> prom_a 0x16418   x2
T_F40218:	jp 0xF9641D  ; -> prom_a 0x1641D
T_F4021C:	jp 0xF9641E  ; -> prom_a 0x1641E   x5
T_F40220:	jp 0xF96423  ; -> prom_a 0x16423   x2
T_F40224:	jp 0xF96428  ; -> prom_a 0x16428   x8
T_F40228:	jp 0xF9642D  ; -> prom_a 0x1642D   x2
	.fill 0x14, 1, 0x0E  ; 0xF4022C: 20 x ret
T_F40240:	.long 0x00F97400	; ptr -> 0xF97400 (prom_a 0x17400)
T_F40244:	jp 0xF97593  ; -> prom_a 0x17593
T_F40248:	jp 0xF9898E  ; -> prom_a 0x1898E   x5
T_F4024C:	jp 0xF98984  ; -> prom_a 0x18984   x5
T_F40250:	jp 0xF98927  ; -> prom_a 0x18927
T_F40254:	jp 0xF9759E  ; -> prom_a 0x1759E   x1
T_F40258:	jp 0xF98ADE  ; -> prom_a 0x18ADE   x1
T_F4025C:	jp 0xF98989  ; -> prom_a 0x18989   x1
	.fill 0x30, 1, 0x0E  ; 0xF40260: 48 x ret
T_F40290:	jp 0xF99400  ; -> prom_a 0x19400
	.fill 0xC, 1, 0x0E  ; 0xF40294: 12 x ret
T_F402A0:	.long 0x00FE8046	; ptr -> 0xFE8046 (prom_a 0x68046)
T_F402A4:	jp 0xFE810B  ; -> prom_a 0x6810B
T_F402A8:	jp 0xFE8116  ; -> prom_a 0x68116
T_F402AC:	jp 0xFE812C  ; -> prom_a 0x6812C
T_F402B0:	jp 0xFE8165  ; -> prom_a 0x68165
T_F402B4:	jp 0xFE8060  ; -> prom_a 0x68060
T_F402B8:	jp 0xFE805F  ; -> prom_a 0x6805F
T_F402BC:	jp 0xFE836F  ; -> prom_a 0x6836F
T_F402C0:	jp 0xFE8564  ; -> prom_a 0x68564
T_F402C4:	jp 0xFE8565  ; -> prom_a 0x68565
T_F402C8:	jp 0xFE8564  ; -> prom_a 0x68564
T_F402CC:	jp 0xFE88AA  ; -> prom_a 0x688AA
T_F402D0:	jp 0xFE8C3A  ; -> prom_a 0x68C3A
T_F402D4:	jp 0xFE9A33  ; -> prom_a 0x69A33
T_F402D8:	jp 0xFE8CB3  ; -> prom_a 0x68CB3
T_F402DC:	jp 0xFE83A3  ; -> prom_a 0x683A3
T_F402E0:	jp 0xFE8045  ; -> prom_a 0x68045
T_F402E4:	jp 0xFE8565  ; -> prom_a 0x68565
T_F402E8:	jp 0xFE8045  ; -> prom_a 0x68045
T_F402EC:	jp 0xFE8868  ; -> prom_a 0x68868
T_F402F0:	jp 0xFE8C1F  ; -> prom_a 0x68C1F
T_F402F4:	jp 0xFE9B8D  ; -> prom_a 0x69B8D
T_F402F8:	jp 0xFE8045  ; -> prom_a 0x68045
T_F402FC:	jp 0xFE82D7  ; -> prom_a 0x682D7
T_F40300:	jp 0xFE833F  ; -> prom_a 0x6833F   x2
T_F40304:	jp 0xFE8026  ; -> prom_a 0x68026   x2
T_F40308:	jp 0xFE8000  ; -> prom_a 0x68000   x1
T_F4030C:	jp 0xFE8005  ; -> prom_a 0x68005   x1
	.fill 0x2E0, 1, 0x0E  ; 0xF40310: 736 x ret
T_F405F0:	jp 0xF89800  ; -> prom_a 0x09800   x10
T_F405F4:	jp 0xF89804  ; -> prom_a 0x09804
	.fill 0x18, 1, 0x0E  ; 0xF405F8: 24 x ret
T_F40610:	.long 0x00F8A000	; ptr -> 0xF8A000 (prom_a 0x0A000)
T_F40614:	jp 0xF8A023  ; -> prom_a 0x0A023   x1
T_F40618:	jp 0xF8A027  ; -> prom_a 0x0A027
	.fill 0x14, 1, 0x0E  ; 0xF4061C: 20 x ret
T_F40630:	.long 0x00F8A800	; ptr -> 0xF8A800 (prom_a 0x0A800)
T_F40634:	jp 0xF8A81D  ; -> prom_a 0x0A81D   x1
	.fill 0x28, 1, 0x0E  ; 0xF40638: 40 x ret
T_F40660:	.long 0x00F8C000	; ptr -> 0xF8C000 (prom_a 0x0C000)
T_F40664:	jp 0xF8C18B  ; -> prom_a 0x0C18B   x2
T_F40668:	jp 0xF8C338  ; -> prom_a 0x0C338   x1
T_F4066C:	jp 0xF8C8C2  ; -> prom_a 0x0C8C2
T_F40670:	jp 0xF8C846  ; -> prom_a 0x0C846   x2
T_F40674:	jp 0xF8C8C3  ; -> prom_a 0x0C8C3   x1
T_F40678:	jp 0xF8C842  ; -> prom_a 0x0C842   x2
T_F4067C:	jp 0xF8C032  ; -> prom_a 0x0C032
T_F40680:	jp 0xF8C071  ; -> prom_a 0x0C071
T_F40684:	jp 0xF8C095  ; -> prom_a 0x0C095
T_F40688:	jp 0xF8C096  ; -> prom_a 0x0C096
T_F4068C:	jp 0xF8C097  ; -> prom_a 0x0C097
T_F40690:	jp 0xF8C0B3  ; -> prom_a 0x0C0B3
T_F40694:	jp 0xF8C0B4  ; -> prom_a 0x0C0B4
T_F40698:	jp 0xF8C04E  ; -> prom_a 0x0C04E
T_F4069C:	jp 0xF8C0D0  ; -> prom_a 0x0C0D0
T_F406A0:	jp 0xF8C3FB  ; -> prom_a 0x0C3FB   x2
	.fill 0x6C, 1, 0x0E  ; 0xF406A4: 108 x ret
T_F40710:	.long 0x00FA5400	; ptr -> 0xFA5400 (prom_a 0x25400)
T_F40714:	jp 0xFA5496  ; -> prom_a 0x25496
T_F40718:	jp 0xFA542F  ; -> prom_a 0x2542F
T_F4071C:	jp 0xFA5418  ; -> prom_a 0x25418
T_F40720:	jp 0xFA55F4  ; -> prom_a 0x255F4   x1
T_F40724:	jp 0xFA590F  ; -> prom_a 0x2590F   x15
T_F40728:	jp 0xFA5942  ; -> prom_a 0x25942   x1
T_F4072C:	jp 0xFA5B5F  ; -> prom_a 0x25B5F   x1
T_F40730:	jp 0xFA5C12  ; -> prom_a 0x25C12   x5
T_F40734:	jp 0xFA5C54  ; -> prom_a 0x25C54   x1
	.fill 0x8, 1, 0x0E  ; 0xF40738: 8 x ret
T_F40740:	.long 0x00FA6000	; ptr -> 0xFA6000 (prom_a 0x26000)
T_F40744:	jp 0xFA6018  ; -> prom_a 0x26018   x1
T_F40748:	jp 0xFA70F5  ; -> prom_a 0x270F5   x9
T_F4074C:	jp 0xFA7D92  ; -> prom_a 0x27D92   x1
T_F40750:	jp 0xFA7D95  ; -> prom_a 0x27D95   x2
T_F40754:	jp 0xFA6EEF  ; -> prom_a 0x26EEF
T_F40758:	jp 0xFA6F04  ; -> prom_a 0x26F04   x1
T_F4075C:	jp 0xFA7DA3  ; -> prom_a 0x27DA3   x1
T_F40760:	jp 0xFA7E0C  ; -> prom_a 0x27E0C   x1
	.fill 0xC, 1, 0x0E  ; 0xF40764: 12 x ret
T_F40770:	.long 0x00FAA400	; ptr -> 0xFAA400 (prom_a 0x2A400)
T_F40774:	jp 0xFAAAB1  ; -> prom_a 0x2AAB1   x2
T_F40778:	jp 0xFAAA8F  ; -> prom_a 0x2AA8F
T_F4077C:	jp 0xFAA967  ; -> prom_a 0x2A967   x2
T_F40780:	jp 0xFAB7E6  ; -> prom_a 0x2B7E6   x1
T_F40784:	jp 0xFABD33  ; -> prom_a 0x2BD33   x2
	ret  ; 0xF40788: 1 x ret
	.fill 0x3, 1, 0x00  ; 0xF40789: 3 x nop
T_F4078C:	jp 0xFAA418  ; -> prom_a 0x2A418   x2
T_F40790:	jp 0xFAA43A  ; -> prom_a 0x2A43A   x6
T_F40794:	jp 0xFAA742  ; -> prom_a 0x2A742   x13
T_F40798:	jp 0xFABFE2  ; -> prom_a 0x2BFE2   x1
T_F4079C:	jp 0xFAB643  ; -> prom_a 0x2B643
T_F407A0:	jp 0xFAB5EA  ; -> prom_a 0x2B5EA   x4
T_F407A4:	jp 0xFAA7AB  ; -> prom_a 0x2A7AB   x6
T_F407A8:	jp 0xFAB5E9  ; -> prom_a 0x2B5E9
T_F407AC:	jp 0xFAAB28  ; -> prom_a 0x2AB28   x2
T_F407B0:	jp 0xFAAAB5  ; -> prom_a 0x2AAB5   x2
T_F407B4:	jp 0xFAA4A0  ; -> prom_a 0x2A4A0   x31
T_F407B8:	jp 0xFAA550  ; -> prom_a 0x2A550   x11
T_F407BC:	jp 0xFAA5A4  ; -> prom_a 0x2A5A4
T_F407C0:	jp 0xFAA5A5  ; -> prom_a 0x2A5A5
T_F407C4:	jp 0xFAB657  ; -> prom_a 0x2B657
T_F407C8:	jp 0xFAA5A6  ; -> prom_a 0x2A5A6
T_F407CC:	jp 0xFAA5FE  ; -> prom_a 0x2A5FE   x26
T_F407D0:	jp 0xFAA604  ; -> prom_a 0x2A604   x18
T_F407D4:	jp 0xFAA623  ; -> prom_a 0x2A623   x9
T_F407D8:	jp 0xFAA66A  ; -> prom_a 0x2A66A   x2
T_F407DC:	jp 0xFAA6B1  ; -> prom_a 0x2A6B1
T_F407E0:	jp 0xFAA71C  ; -> prom_a 0x2A71C
T_F407E4:	jp 0xFAA71E  ; -> prom_a 0x2A71E
T_F407E8:	jp 0xFAA71D  ; -> prom_a 0x2A71D   x1
T_F407EC:	jp 0xFAA71F  ; -> prom_a 0x2A71F   x3
T_F407F0:	jp 0xFABBD6  ; -> prom_a 0x2BBD6
T_F407F4:	jp 0xFAB658  ; -> prom_a 0x2B658   x6
T_F407F8:	jp 0xFAB6D7  ; -> prom_a 0x2B6D7
T_F407FC:	jp 0xFAA45C  ; -> prom_a 0x2A45C   x1
T_F40800:	jp 0xFAA47E  ; -> prom_a 0x2A47E
T_F40804:	jp 0xFAB779  ; -> prom_a 0x2B779   x3
T_F40808:	jp 0xFAB728  ; -> prom_a 0x2B728   x3
T_F4080C:	jp 0xFABEFB  ; -> prom_a 0x2BEFB   x21
T_F40810:	jp 0xFAC786  ; -> prom_a 0x2C786
	.fill 0x2C, 1, 0x0E  ; 0xF40814: 44 x ret
T_F40840:	jp 0xFB1800  ; -> prom_a 0x31800   x1
	.fill 0xC, 1, 0x0E  ; 0xF40844: 12 x ret
T_F40850:	jp 0xFADB2C  ; -> prom_a 0x2DB2C   x1
T_F40854:	jp 0xFADF1E  ; -> prom_a 0x2DF1E   x1
T_F40858:	jp 0xFAD80A  ; -> prom_a 0x2D80A   x1
T_F4085C:	jp 0xFAD805  ; -> prom_a 0x2D805
T_F40860:	jp 0xFAD800  ; -> prom_a 0x2D800
T_F40864:	jp 0xFAD870  ; -> prom_a 0x2D870   x1
T_F40868:	jp 0xFAD88A  ; -> prom_a 0x2D88A   x1
T_F4086C:	jp 0xFAD84A  ; -> prom_a 0x2D84A   x1
T_F40870:	jp 0xFAE223  ; -> prom_a 0x2E223   x2
T_F40874:	jp 0xFAD81D  ; -> prom_a 0x2D81D   x2
T_F40878:	jp 0xFAD8A1  ; -> prom_a 0x2D8A1   x2
T_F4087C:	jp 0xFAD8FE  ; -> prom_a 0x2D8FE   x2
T_F40880:	jp 0xFAD98F  ; -> prom_a 0x2D98F   x1
T_F40884:	jp 0xFAD8BC  ; -> prom_a 0x2D8BC   x3
T_F40888:	jp 0xFAD9B0  ; -> prom_a 0x2D9B0   x5
T_F4088C:	jp 0xFAD8DD  ; -> prom_a 0x2D8DD   x7
T_F40890:	jp 0xFADE8D  ; -> prom_a 0x2DE8D
T_F40894:	jp 0xFADF08  ; -> prom_a 0x2DF08   x1
T_F40898:	jp 0xFADA26  ; -> prom_a 0x2DA26   x3
T_F4089C:	jp 0xFAD9CB  ; -> prom_a 0x2D9CB   x1
	.fill 0x40, 1, 0x0E  ; 0xF408A0: 64 x ret
T_F408E0:	.long 0x00FB2000	; ptr -> 0xFB2000 (prom_a 0x32000)
T_F408E4:	jp 0xFB2049  ; -> prom_a 0x32049   x1
T_F408E8:	jp 0xFB20CE  ; -> prom_a 0x320CE   x1
T_F408EC:	jp 0xFB3355  ; -> prom_a 0x33355   x2
T_F408F0:	jp 0xFB590A  ; -> prom_a 0x3590A
T_F408F4:	jp 0xFB5EE9  ; -> prom_a 0x35EE9
T_F408F8:	jp 0xFB2022  ; -> prom_a 0x32022
T_F408FC:	jp 0xFB50EE  ; -> prom_a 0x350EE
T_F40900:	jp 0xFB4B7D  ; -> prom_a 0x34B7D   x1
T_F40904:	jp 0xFB21CB  ; -> prom_a 0x321CB   x1
T_F40908:	jp 0xFB585E  ; -> prom_a 0x3585E   x1
T_F4090C:	jp 0xFB7A90  ; -> prom_a 0x37A90   x2
T_F40910:	jp 0xFB7AC2  ; -> prom_a 0x37AC2   x1
	.fill 0x3C, 1, 0x0E  ; 0xF40914: 60 x ret
T_F40950:	jp 0xFB9E79  ; -> prom_a 0x39E79   x1
T_F40954:	jp 0xFB9DFE  ; -> prom_a 0x39DFE   x1
T_F40958:	jp 0xFB9B41  ; -> prom_a 0x39B41   x1
T_F4095C:	jp 0xFB9B73  ; -> prom_a 0x39B73   x1
T_F40960:	jp 0xFB9BA4  ; -> prom_a 0x39BA4
T_F40964:	jp 0xFB9C52  ; -> prom_a 0x39C52
	.fill 0x8, 1, 0x0E  ; 0xF40968: 8 x ret
T_F40970:	jp 0xF00800  ; -> prom_b 0x00800
T_F40974:	jp 0xF00800  ; -> prom_b 0x00800
T_F40978:	jp 0xF00800  ; -> prom_b 0x00800
T_F4097C:	jp 0xF00800  ; -> prom_b 0x00800   x2
T_F40980:	jp 0xF00800  ; -> prom_b 0x00800
T_F40984:	jp 0xF00AFF  ; -> prom_b 0x00AFF   x5
	.fill 0x18, 1, 0x0E  ; 0xF40988: 24 x ret
T_F409A0:	jp 0xF0001B  ; -> prom_b 0x0001B
T_F409A4:	jp 0xF00293  ; -> prom_b 0x00293   x1
T_F409A8:	jp 0xF002C9  ; -> prom_b 0x002C9   x2
T_F409AC:	jp 0xF000B9  ; -> prom_b 0x000B9   x29
T_F409B0:	jp 0xF0001A  ; -> prom_b 0x0001A
T_F409B4:	jp 0xF001C9  ; -> prom_b 0x001C9   x1
	.fill 0x8, 1, 0x0E  ; 0xF409B8: 8 x ret
T_F409C0:	.long 0x00F44000	; ptr -> 0xF44000 (prom_b 0x44000)
T_F409C4:	jp 0xF40B44  ; -> prom_b 0x40B44   x1
T_F409C8:	jp 0xF44582  ; -> prom_b 0x44582   x2
T_F409CC:	jp 0xF450F7  ; -> prom_b 0x450F7   x4
T_F409D0:	jp 0xF451E6  ; -> prom_b 0x451E6   x4
T_F409D4:	jp 0xF452D3  ; -> prom_b 0x452D3   x2
T_F409D8:	jp 0xF45348  ; -> prom_b 0x45348   x1
T_F409DC:	jp 0xF45BD3  ; -> prom_b 0x45BD3   x1
T_F409E0:	jp 0xF4542D  ; -> prom_b 0x4542D   x24
T_F409E4:	jp 0xF45445  ; -> prom_b 0x45445   x1
T_F409E8:	jp 0xF4545B  ; -> prom_b 0x4545B
T_F409EC:	jp 0xF4545F  ; -> prom_b 0x4545F   x1
T_F409F0:	jp 0xF45474  ; -> prom_b 0x45474   x1
T_F409F4:	jp 0xF45489  ; -> prom_b 0x45489   x2
T_F409F8:	jp 0xF454A6  ; -> prom_b 0x454A6   x2
T_F409FC:	jp 0xF414B0  ; -> prom_b 0x414B0   x1
T_F40A00:	jp 0xF40C70  ; -> prom_b 0x40C70   x3
T_F40A04:	jp 0xF40C74  ; -> prom_b 0x40C74   x8
T_F40A08:	jp 0xF45FC4  ; -> prom_b 0x45FC4   x2
T_F40A0C:	jp 0xF45524  ; -> prom_b 0x45524   x1
T_F40A10:	jp 0xF45975  ; -> prom_b 0x45975   x2
T_F40A14:	jp 0xF45B0A  ; -> prom_b 0x45B0A   x8
T_F40A18:	jp 0xF455A0  ; -> prom_b 0x455A0   x2
T_F40A1C:	jp 0xF44367  ; -> prom_b 0x44367   x15
T_F40A20:	jp 0xF455C5  ; -> prom_b 0x455C5   x3
T_F40A24:	jp 0xF456EC  ; -> prom_b 0x456EC   x2
T_F40A28:	jp 0xF45D09  ; -> prom_b 0x45D09   x1
T_F40A2C:	jp 0xF45D19  ; -> prom_b 0x45D19
T_F40A30:	jp 0xF45D80  ; -> prom_b 0x45D80
	.fill 0x8, 1, 0x00  ; 0xF40A34: 8 x nop
T_F40A3C:	jp 0xF45E58  ; -> prom_b 0x45E58   x1
T_F40A40:	jp 0xF46031  ; -> prom_b 0x46031   x2
T_F40A44:	jp 0xF4402D  ; -> prom_b 0x4402D
T_F40A48:	jp 0xF44036  ; -> prom_b 0x44036
T_F40A4C:	jp 0xF450B2  ; -> prom_b 0x450B2
T_F40A50:	jp 0xF454B3  ; -> prom_b 0x454B3
T_F40A54:	jp 0xF46015  ; -> prom_b 0x46015
T_F40A58:	jp 0xF45FAE  ; -> prom_b 0x45FAE
T_F40A5C:	jp 0xF45FB4  ; -> prom_b 0x45FB4   x3
T_F40A60:	jp 0xF4402A  ; -> prom_b 0x4402A   x1
T_F40A64:	jp 0xF44030  ; -> prom_b 0x44030
	.fill 0x4, 1, 0x00  ; 0xF40A68: 4 x nop
T_F40A6C:	jp 0xF44033  ; -> prom_b 0x44033
T_F40A70:	jp 0xF4566A  ; -> prom_b 0x4566A   x1
T_F40A74:	jp 0xF4403F  ; -> prom_b 0x4403F
T_F40A78:	jp 0xF4401B  ; -> prom_b 0x4401B   x1
T_F40A7C:	jp 0xF4401E  ; -> prom_b 0x4401E   x1
T_F40A80:	jp 0xF44021  ; -> prom_b 0x44021   x1
T_F40A84:	jp 0xF44024  ; -> prom_b 0x44024
T_F40A88:	jp 0xF44027  ; -> prom_b 0x44027
T_F40A8C:	jp 0xF44367  ; -> prom_b 0x44367   x1
T_F40A90:	jp 0xF44039  ; -> prom_b 0x44039   x1
T_F40A94:	jp 0xF4403C  ; -> prom_b 0x4403C
T_F40A98:	jp 0xF44018  ; -> prom_b 0x44018   x1
T_F40A9C:	jp 0xF45CC4  ; -> prom_b 0x45CC4   x3
T_F40AA0:	jp 0xF44E8E  ; -> prom_b 0x44E8E
T_F40AA4:	jp 0xF448C6  ; -> prom_b 0x448C6   x3
T_F40AA8:	jp 0xF455E6  ; -> prom_b 0x455E6   x5
T_F40AAC:	jp 0xF44B2D  ; -> prom_b 0x44B2D   x2
T_F40AB0:	jp 0xF45BCD  ; -> prom_b 0x45BCD   x1
T_F40AB4:	jp 0xF45FE5  ; -> prom_b 0x45FE5
T_F40AB8:	jp 0xF440A0  ; -> prom_b 0x440A0
T_F40ABC:	jp 0xF44F67  ; -> prom_b 0x44F67   x2
T_F40AC0:	jp 0xF4603C  ; -> prom_b 0x4603C   x1
T_F40AC4:	jp 0xF44AEE  ; -> prom_b 0x44AEE   x11
T_F40AC8:	jp 0xF44131  ; -> prom_b 0x44131   x6
	.fill 0x74, 1, 0x0E  ; 0xF40ACC: 116 x ret
T_F40B40:	jp 0xF48107  ; -> prom_b 0x48107   x1
T_F40B44:	jp 0xF47800  ; -> prom_b 0x47800   x1
T_F40B48:	jp 0xF47802  ; -> prom_b 0x47802   x1
T_F40B4C:	jp 0xF47804  ; -> prom_b 0x47804   x1
T_F40B50:	jp 0xF47807  ; -> prom_b 0x47807
T_F40B54:	jp 0xF483B2  ; -> prom_b 0x483B2   x3
T_F40B58:	jp 0xF47A5D  ; -> prom_b 0x47A5D   x2
T_F40B5C:	jp 0xF48464  ; -> prom_b 0x48464   x13
T_F40B60:	jp 0xF48580  ; -> prom_b 0x48580   x13
T_F40B64:	jp 0xF486BA  ; -> prom_b 0x486BA   x7
T_F40B68:	jp 0xF4869B  ; -> prom_b 0x4869B   x7
T_F40B6C:	jp 0xF48647  ; -> prom_b 0x48647   x3
T_F40B70:	jp 0xF48707  ; -> prom_b 0x48707   x1
T_F40B74:	jp 0xF487A7  ; -> prom_b 0x487A7   x1
T_F40B78:	jp 0xF47F9A  ; -> prom_b 0x47F9A
	.fill 0x44, 1, 0x0E  ; 0xF40B7C: 68 x ret
T_F40BC0:	jp 0xF49800  ; -> prom_b 0x49800   x1
T_F40BC4:	jp 0xF49802  ; -> prom_b 0x49802   x1
T_F40BC8:	jp 0xF49804  ; -> prom_b 0x49804   x4
T_F40BCC:	jp 0xF49806  ; -> prom_b 0x49806   x1
T_F40BD0:	jp 0xF49808  ; -> prom_b 0x49808   x1
T_F40BD4:	jp 0xF4980A  ; -> prom_b 0x4980A   x1
T_F40BD8:	jp 0xF4A57E  ; -> prom_b 0x4A57E   x3
T_F40BDC:	jp 0xF4A5AD  ; -> prom_b 0x4A5AD   x6
T_F40BE0:	jp 0xF4A661  ; -> prom_b 0x4A661   x2
T_F40BE4:	jp 0xF49A3D  ; -> prom_b 0x49A3D   x9
T_F40BE8:	jp 0xF4AF08  ; -> prom_b 0x4AF08   x2
T_F40BEC:	jp 0xF4B0E7  ; -> prom_b 0x4B0E7   x1
T_F40BF0:	jp 0xF4B104  ; -> prom_b 0x4B104   x1
T_F40BF4:	jp 0xF4A6CF  ; -> prom_b 0x4A6CF   x3
T_F40BF8:	jp 0xF4A6E7  ; -> prom_b 0x4A6E7   x3
T_F40BFC:	jp 0xF4AF51  ; -> prom_b 0x4AF51   x2
T_F40C00:	jp 0xF4A5B5  ; -> prom_b 0x4A5B5   x3
T_F40C04:	jp 0xF4B414  ; -> prom_b 0x4B414   x3
	.fill 0x48, 1, 0x0E  ; 0xF40C08: 72 x ret
T_F40C50:	jp 0xF4D02C  ; -> prom_b 0x4D02C   x15
T_F40C54:	jp 0xF4D0DB  ; -> prom_b 0x4D0DB   x18
T_F40C58:	jp 0xF4D0FB  ; -> prom_b 0x4D0FB   x14
T_F40C5C:	jp 0xF4D690  ; -> prom_b 0x4D690   x7
T_F40C60:	jp 0xF4D6F6  ; -> prom_b 0x4D6F6   x2
T_F40C64:	jp 0xF4D000  ; -> prom_b 0x4D000   x9
T_F40C68:	jp 0xF4D002  ; -> prom_b 0x4D002   x1
T_F40C6C:	jp 0xF4D00B  ; -> prom_b 0x4D00B   x3
T_F40C70:	jp 0xF4D00E  ; -> prom_b 0x4D00E   x2
T_F40C74:	jp 0xF4D011  ; -> prom_b 0x4D011   x2
T_F40C78:	jp 0xF4D01A  ; -> prom_b 0x4D01A
T_F40C7C:	jp 0xF4D005  ; -> prom_b 0x4D005   x2
T_F40C80:	jp 0xF4D008  ; -> prom_b 0x4D008   x1
T_F40C84:	jp 0xF4D01D  ; -> prom_b 0x4D01D   x21
T_F40C88:	jp 0xF4D023  ; -> prom_b 0x4D023   x6
T_F40C8C:	jp 0xF4D014  ; -> prom_b 0x4D014   x1
T_F40C90:	jp 0xF4D017  ; -> prom_b 0x4D017   x1
T_F40C94:	jp 0xF4D026  ; -> prom_b 0x4D026   x2
T_F40C98:	jp 0xF4D651  ; -> prom_b 0x4D651
	.fill 0x14, 1, 0x0E  ; 0xF40C9C: 20 x ret
T_F40CB0:	jp 0xF4E000  ; -> prom_b 0x4E000
T_F40CB4:	jp 0xF4E524  ; -> prom_b 0x4E524   x14
T_F40CB8:	jp 0xF4E591  ; -> prom_b 0x4E591
T_F40CBC:	jp 0xF4E525  ; -> prom_b 0x4E525
T_F40CC0:	jp 0xF4E1B2  ; -> prom_b 0x4E1B2   x1
T_F40CC4:	jp 0xF4E56F  ; -> prom_b 0x4E56F   x24
T_F40CC8:	jp 0xF4E592  ; -> prom_b 0x4E592   x1
T_F40CCC:	jp 0xF4E30F  ; -> prom_b 0x4E30F   x2
	.fill 0x10, 1, 0x0E  ; 0xF40CD0: 16 x ret
T_F40CE0:	jp 0xF4EC00  ; -> prom_b 0x4EC00
T_F40CE4:	jp 0xF4EC25  ; -> prom_b 0x4EC25
T_F40CE8:	jp 0xF4EC2B  ; -> prom_b 0x4EC2B   x1
T_F40CEC:	jp 0xF4EC56  ; -> prom_b 0x4EC56   x2
T_F40CF0:	jp 0xF4EC8A  ; -> prom_b 0x4EC8A   x1
T_F40CF4:	jp 0xF4EC9A  ; -> prom_b 0x4EC9A
T_F40CF8:	jp 0xF4ECA9  ; -> prom_b 0x4ECA9   x1
T_F40CFC:	jp 0xF4EE6F  ; -> prom_b 0x4EE6F   x2
T_F40D00:	jp 0xF4ED84  ; -> prom_b 0x4ED84   x4
T_F40D04:	jp 0xF4EEAD  ; -> prom_b 0x4EEAD   x1
T_F40D08:	jp 0xF4EEBC  ; -> prom_b 0x4EEBC
T_F40D0C:	jp 0xF4EED9  ; -> prom_b 0x4EED9   x1
T_F40D10:	jp 0xF4EEE6  ; -> prom_b 0x4EEE6   x1
T_F40D14:	jp 0xF4ED0C  ; -> prom_b 0x4ED0C   x1
T_F40D18:	jp 0xF4EEF3  ; -> prom_b 0x4EEF3   x2
	.fill 0x44, 1, 0x0E  ; 0xF40D1C: 68 x ret
T_F40D60:	jp 0xF4E426  ; -> prom_b 0x4E426   x1
T_F40D64:	jp 0xF4E32A  ; -> prom_b 0x4E32A   x1
T_F40D68:	jp 0xF4E478  ; -> prom_b 0x4E478   x1
T_F40D6C:	jp 0xF4E390  ; -> prom_b 0x4E390   x1
	.fill 0x20, 1, 0x0E  ; 0xF40D70: 32 x ret
T_F40D90:	jp 0xF55808  ; -> prom_b 0x55808
T_F40D94:	jp 0xF5580C  ; -> prom_b 0x5580C
T_F40D98:	jp 0xF55800  ; -> prom_b 0x55800
T_F40D9C:	jp 0xF55804  ; -> prom_b 0x55804
T_F40DA0:	jp 0xF55856  ; -> prom_b 0x55856
T_F40DA4:	jp 0xF5585A  ; -> prom_b 0x5585A
T_F40DA8:	jp 0xF5585E  ; -> prom_b 0x5585E
T_F40DAC:	jp 0xF55868  ; -> prom_b 0x55868
T_F40DB0:	jp 0xF5586C  ; -> prom_b 0x5586C
T_F40DB4:	jp 0xF55870  ; -> prom_b 0x55870
T_F40DB8:	jp 0xF55874  ; -> prom_b 0x55874
T_F40DBC:	jp 0xF5587E  ; -> prom_b 0x5587E
T_F40DC0:	jp 0xF55810  ; -> prom_b 0x55810
T_F40DC4:	jp 0xF55814  ; -> prom_b 0x55814
T_F40DC8:	jp 0xF55818  ; -> prom_b 0x55818
T_F40DCC:	jp 0xF55822  ; -> prom_b 0x55822
T_F40DD0:	jp 0xF5583C  ; -> prom_b 0x5583C
T_F40DD4:	jp 0xF55840  ; -> prom_b 0x55840
T_F40DD8:	jp 0xF55844  ; -> prom_b 0x55844
T_F40DDC:	jp 0xF5584E  ; -> prom_b 0x5584E
T_F40DE0:	jp 0xF55882  ; -> prom_b 0x55882
T_F40DE4:	jp 0xF55886  ; -> prom_b 0x55886
T_F40DE8:	jp 0xF5588A  ; -> prom_b 0x5588A
T_F40DEC:	jp 0xF55894  ; -> prom_b 0x55894
T_F40DF0:	jp 0xF55898  ; -> prom_b 0x55898
T_F40DF4:	jp 0xF5589C  ; -> prom_b 0x5589C
T_F40DF8:	jp 0xF558A0  ; -> prom_b 0x558A0
T_F40DFC:	jp 0xF558AA  ; -> prom_b 0x558AA
T_F40E00:	jp 0xF55826  ; -> prom_b 0x55826
T_F40E04:	jp 0xF5582A  ; -> prom_b 0x5582A
T_F40E08:	jp 0xF5582E  ; -> prom_b 0x5582E
T_F40E0C:	jp 0xF55838  ; -> prom_b 0x55838
T_F40E10:	jp 0xF55D90  ; -> prom_b 0x55D90   x6
T_F40E14:	jp 0xF55882  ; -> prom_b 0x55882
T_F40E18:	jp 0xF56525  ; -> prom_b 0x56525   x2
	.fill 0xB4, 1, 0x0E  ; 0xF40E1C: 180 x ret
T_F40ED0:	.long 0x00F57C00	; ptr -> 0xF57C00 (prom_b 0x57C00)
T_F40ED4:	jp 0xF8E02C  ; -> prom_a 0x0E02C   x46
T_F40ED8:	jp 0xF8E5F6  ; -> prom_a 0x0E5F6   x1
T_F40EDC:	jp 0xF8E47F  ; -> prom_a 0x0E47F   INT0 vector target (prom_a 0xFFFF28)
T_F40EE0:	jp 0xF57D45  ; -> prom_b 0x57D45
T_F40EE4:	jp 0xF8E52D  ; -> prom_a 0x0E52D
T_F40EE8:	jp 0xF8E54F  ; -> prom_a 0x0E54F
T_F40EEC:	jp 0xF8E26F  ; -> prom_a 0x0E26F   x2
T_F40EF0:	jp 0xF8E0FE  ; -> prom_a 0x0E0FE   x23  the 0xE2 remote-read entry the
				; expansion-board probe calls (prom_b/prom_b.ld)
	.fill 0xC, 1, 0x0E  ; 0xF40EF4: 12 x ret
T_F40F00:	.long 0x00F5A800	; ptr -> 0xF5A800 (prom_b 0x5A800)
T_F40F04:	jp 0xF5A832  ; -> prom_b 0x5A832   x1
T_F40F08:	jp 0xF5A836  ; -> prom_b 0x5A836   x6
T_F40F0C:	jp 0xF5AC0A  ; -> prom_b 0x5AC0A
T_F40F10:	jp 0xF5ACBB  ; -> prom_b 0x5ACBB
T_F40F14:	jp 0xF5AC93  ; -> prom_b 0x5AC93
T_F40F18:	jp 0xF5A83A  ; -> prom_b 0x5A83A   x1
T_F40F1C:	jp 0xF5A83B  ; -> prom_b 0x5A83B   x3
T_F40F20:	jp 0xF5A847  ; -> prom_b 0x5A847   x1
T_F40F24:	jp 0xF5A84B  ; -> prom_b 0x5A84B
	.fill 0x8, 1, 0x0E  ; 0xF40F28: 8 x ret
T_F40F30:	.long 0x00F86000	; ptr -> 0xF86000 (prom_a 0x06000)
T_F40F34:	jp 0xF86066  ; -> prom_a 0x06066   x1
T_F40F38:	jp 0xF86A81  ; -> prom_a 0x06A81   x14
T_F40F3C:	jp 0xF86AA3  ; -> prom_a 0x06AA3   x81
T_F40F40:	jp 0xF86AC7  ; -> prom_a 0x06AC7   x18
T_F40F44:	jp 0xF86903  ; -> prom_a 0x06903   x1
T_F40F48:	jp 0xF86AE9  ; -> prom_a 0x06AE9
T_F40F4C:	jp 0xF86AE9  ; -> prom_a 0x06AE9   x3
T_F40F50:	jp 0xF860A6  ; -> prom_a 0x060A6   x7
	.fill 0x4, 1, 0x0E  ; 0xF40F54: 4 x ret
T_F40F58:	jp 0xF8659B  ; -> prom_a 0x0659B
T_F40F5C:	jp 0xF8697E  ; -> prom_a 0x0697E   x1
T_F40F60:	jp 0xF8699D  ; -> prom_a 0x0699D   x2
T_F40F64:	jp 0xF869BC  ; -> prom_a 0x069BC   x1
T_F40F68:	jp 0xF86B43  ; -> prom_a 0x06B43
T_F40F6C:	jp 0xF86B6F  ; -> prom_a 0x06B6F
T_F40F70:	jp 0xF86B7F  ; -> prom_a 0x06B7F
T_F40F74:	jp 0xF86C5C  ; -> prom_a 0x06C5C   x2
T_F40F78:	jp 0xF86BF4  ; -> prom_a 0x06BF4
T_F40F7C:	jp 0xF86BC0  ; -> prom_a 0x06BC0
T_F40F80:	jp 0xF86C01  ; -> prom_a 0x06C01
T_F40F84:	jp 0xF86C0E  ; -> prom_a 0x06C0E
T_F40F88:	jp 0xF86C59  ; -> prom_a 0x06C59
T_F40F8C:	jp 0xF86C5A  ; -> prom_a 0x06C5A
T_F40F90:	jp 0xF865BC  ; -> prom_a 0x065BC
T_F40F94:	jp 0xF86C5B  ; -> prom_a 0x06C5B
	.fill 0x18, 1, 0x0E  ; 0xF40F98: 24 x ret
T_F40FB0:	.long 0x00FC0000	; ptr -> 0xFC0000 (prom_a 0x40000)
T_F40FB4:	jp 0xFC0E56  ; -> prom_a 0x40E56
T_F40FB8:	jp 0xFC0FBD  ; -> prom_a 0x40FBD
T_F40FBC:	jp 0xFC0FBE  ; -> prom_a 0x40FBE
	ret  ; 0xF40FC0: 1 x ret
	.fill 0x3, 1, 0x00  ; 0xF40FC1: 3 x nop
	ret  ; 0xF40FC4: 1 x ret
	.fill 0x3, 1, 0x00  ; 0xF40FC5: 3 x nop
T_F40FC8:	jp 0xFC1CD1  ; -> prom_a 0x41CD1
T_F40FCC:	jp 0xFC0E6B  ; -> prom_a 0x40E6B
T_F40FD0:	jp 0xFC10DD  ; -> prom_a 0x410DD   x2
T_F40FD4:	jp 0xFC10FA  ; -> prom_a 0x410FA
T_F40FD8:	jp 0xFC19DC  ; -> prom_a 0x419DC
T_F40FDC:	jp 0xFC18AA  ; -> prom_a 0x418AA   x1
T_F40FE0:	jp 0xFC10DB  ; -> prom_a 0x410DB
T_F40FE4:	jp 0xFC10DA  ; -> prom_a 0x410DA
T_F40FE8:	jp 0xFC2213  ; -> prom_a 0x42213
T_F40FEC:	jp 0xFC0206  ; -> prom_a 0x40206   x3
T_F40FF0:	jp 0xFC01F3  ; -> prom_a 0x401F3   x2
T_F40FF4:	jp 0xFC018D  ; -> prom_a 0x4018D   x1
T_F40FF8:	jp 0xFC024F  ; -> prom_a 0x4024F
T_F40FFC:	jp 0xFC22BA  ; -> prom_a 0x422BA   x3
T_F41000:	jp 0xFC2403  ; -> prom_a 0x42403   x4
T_F41004:	jp 0xFC24EB  ; -> prom_a 0x424EB   x4
T_F41008:	jp 0xFC2526  ; -> prom_a 0x42526   x7
T_F4100C:	jp 0xFC188F  ; -> prom_a 0x4188F   x1
T_F41010:	jp 0xFC1B81  ; -> prom_a 0x41B81   x9
T_F41014:	jp 0xFC1CD1  ; -> prom_a 0x41CD1
T_F41018:	jp 0xFC2035  ; -> prom_a 0x42035   x3
T_F4101C:	jp 0xFC2222  ; -> prom_a 0x42222   x14
T_F41020:	jp 0xFC18B2  ; -> prom_a 0x418B2   x3
T_F41024:	jp 0xFC239B  ; -> prom_a 0x4239B   x2
T_F41028:	jp 0xFC24E3  ; -> prom_a 0x424E3   x2
T_F4102C:	jp 0xFC1C59  ; -> prom_a 0x41C59   x4
T_F41030:	jp 0xFC2155  ; -> prom_a 0x42155   x3
T_F41034:	jp 0xFC2282  ; -> prom_a 0x42282   x7
T_F41038:	jp 0xFC1E68  ; -> prom_a 0x41E68   x4
T_F4103C:	jp 0xFC1D92  ; -> prom_a 0x41D92   x1
T_F41040:	jp 0xFC25A8  ; -> prom_a 0x425A8   x1
T_F41044:	jp 0xFC25A2  ; -> prom_a 0x425A2   x1
T_F41048:	jp 0xFC01B1  ; -> prom_a 0x401B1   x2
T_F4104C:	jp 0xFC01C7  ; -> prom_a 0x401C7   x2
T_F41050:	jp 0xFC01DD  ; -> prom_a 0x401DD   x2
T_F41054:	jp 0xFC11FB  ; -> prom_a 0x411FB   x4
T_F41058:	jp 0xFC1116  ; -> prom_a 0x41116
T_F4105C:	jp 0xFC182F  ; -> prom_a 0x4182F   x1
T_F41060:	jp 0xFC020F  ; -> prom_a 0x4020F   x1
	.fill 0xC, 1, 0x0E  ; 0xF41064: 12 x ret
T_F41070:	jp 0xFC0250  ; -> prom_a 0x40250
T_F41074:	jp 0xFC0260  ; -> prom_a 0x40260
T_F41078:	jp 0xFC0270  ; -> prom_a 0x40270
T_F4107C:	jp 0xFC0280  ; -> prom_a 0x40280
T_F41080:	jp 0xFC0290  ; -> prom_a 0x40290
T_F41084:	jp 0xFC02A0  ; -> prom_a 0x402A0
T_F41088:	jp 0xFC02B0  ; -> prom_a 0x402B0
T_F4108C:	jp 0xFC02C0  ; -> prom_a 0x402C0
T_F41090:	jp 0xFC02D0  ; -> prom_a 0x402D0
T_F41094:	jp 0xFC02E0  ; -> prom_a 0x402E0
T_F41098:	jp 0xFC02F0  ; -> prom_a 0x402F0
T_F4109C:	jp 0xFC0300  ; -> prom_a 0x40300
T_F410A0:	jp 0xFC0310  ; -> prom_a 0x40310
T_F410A4:	jp 0xFC0320  ; -> prom_a 0x40320
T_F410A8:	jp 0xFC0330  ; -> prom_a 0x40330
T_F410AC:	jp 0xFC0340  ; -> prom_a 0x40340
T_F410B0:	jp 0xFC0350  ; -> prom_a 0x40350
T_F410B4:	jp 0xFC0360  ; -> prom_a 0x40360
T_F410B8:	jp 0xFC0370  ; -> prom_a 0x40370
T_F410BC:	jp 0xFC0380  ; -> prom_a 0x40380
T_F410C0:	jp 0xFC0390  ; -> prom_a 0x40390
T_F410C4:	jp 0xFC03A0  ; -> prom_a 0x403A0
T_F410C8:	jp 0xFC03B0  ; -> prom_a 0x403B0
T_F410CC:	jp 0xFC03C0  ; -> prom_a 0x403C0
T_F410D0:	jp 0xFC03D0  ; -> prom_a 0x403D0
T_F410D4:	jp 0xFC03E0  ; -> prom_a 0x403E0
T_F410D8:	jp 0xFC03F0  ; -> prom_a 0x403F0
T_F410DC:	jp 0xFC0400  ; -> prom_a 0x40400
T_F410E0:	jp 0xFC0410  ; -> prom_a 0x40410
T_F410E4:	jp 0xFC0420  ; -> prom_a 0x40420
T_F410E8:	jp 0xFC0430  ; -> prom_a 0x40430
T_F410EC:	jp 0xFC0440  ; -> prom_a 0x40440
T_F410F0:	jp 0xFC0651  ; -> prom_a 0x40651
T_F410F4:	jp 0xFC0653  ; -> prom_a 0x40653
T_F410F8:	jp 0xFC0654  ; -> prom_a 0x40654
T_F410FC:	jp 0xFC0655  ; -> prom_a 0x40655
T_F41100:	jp 0xFC0656  ; -> prom_a 0x40656
T_F41104:	jp 0xFC0657  ; -> prom_a 0x40657
T_F41108:	jp 0xFC0658  ; -> prom_a 0x40658
T_F4110C:	jp 0xFC0659  ; -> prom_a 0x40659
T_F41110:	jp 0xFC065A  ; -> prom_a 0x4065A
T_F41114:	jp 0xFC0663  ; -> prom_a 0x40663
T_F41118:	jp 0xFC066C  ; -> prom_a 0x4066C
T_F4111C:	jp 0xFC0675  ; -> prom_a 0x40675
T_F41120:	jp 0xFC067E  ; -> prom_a 0x4067E
T_F41124:	jp 0xFC067F  ; -> prom_a 0x4067F
T_F41128:	jp 0xFC0680  ; -> prom_a 0x40680
T_F4112C:	jp 0xFC0681  ; -> prom_a 0x40681
T_F41130:	jp 0xFC0682  ; -> prom_a 0x40682
T_F41134:	jp 0xFC0683  ; -> prom_a 0x40683
T_F41138:	jp 0xFC0684  ; -> prom_a 0x40684
T_F4113C:	jp 0xFC0685  ; -> prom_a 0x40685
T_F41140:	jp 0xFC0686  ; -> prom_a 0x40686
T_F41144:	jp 0xFC0691  ; -> prom_a 0x40691
T_F41148:	jp 0xFC0692  ; -> prom_a 0x40692
T_F4114C:	jp 0xFC069D  ; -> prom_a 0x4069D
T_F41150:	jp 0xFC069E  ; -> prom_a 0x4069E
T_F41154:	jp 0xFC069F  ; -> prom_a 0x4069F
T_F41158:	jp 0xFC06AA  ; -> prom_a 0x406AA
T_F4115C:	jp 0xFC06B5  ; -> prom_a 0x406B5
T_F41160:	jp 0xFC06C0  ; -> prom_a 0x406C0
T_F41164:	jp 0xFC06CB  ; -> prom_a 0x406CB
T_F41168:	jp 0xFC06CC  ; -> prom_a 0x406CC
T_F4116C:	jp 0xFC06D0  ; -> prom_a 0x406D0
T_F41170:	jp 0xFC06DB  ; -> prom_a 0x406DB
T_F41174:	jp 0xFC06DC  ; -> prom_a 0x406DC
T_F41178:	jp 0xFC06DD  ; -> prom_a 0x406DD
T_F4117C:	jp 0xFC06DE  ; -> prom_a 0x406DE
T_F41180:	jp 0xFC06DF  ; -> prom_a 0x406DF
T_F41184:	jp 0xFC0427  ; -> prom_a 0x40427
T_F41188:	jp 0xFC043C  ; -> prom_a 0x4043C
T_F4118C:	jp 0xFC043D  ; -> prom_a 0x4043D
T_F41190:	jp 0xFC0452  ; -> prom_a 0x40452
T_F41194:	jp 0xFC0453  ; -> prom_a 0x40453
T_F41198:	jp 0xFC0454  ; -> prom_a 0x40454
T_F4119C:	jp 0xFC0455  ; -> prom_a 0x40455
T_F411A0:	jp 0xFC046A  ; -> prom_a 0x4046A
	.fill 0xC, 1, 0x0E  ; 0xF411A4: 12 x ret
T_F411B0:	.long 0x00FC5400	; ptr -> 0xFC5400 (prom_a 0x45400)
T_F411B4:	jp 0xFC546A  ; -> prom_a 0x4546A
T_F411B8:	jp 0xFC54C6  ; -> prom_a 0x454C6   x43
T_F411BC:	jp 0xFC5518  ; -> prom_a 0x45518   x15
T_F411C0:	jp 0xFC55CA  ; -> prom_a 0x455CA
T_F411C4:	jp 0xFC57F0  ; -> prom_a 0x457F0
T_F411C8:	jp 0xFC596D  ; -> prom_a 0x4596D
T_F411CC:	jp 0xFC596E  ; -> prom_a 0x4596E
T_F411D0:	jp 0xFC596F  ; -> prom_a 0x4596F
T_F411D4:	jp 0xFC59AC  ; -> prom_a 0x459AC
T_F411D8:	jp 0xFC5ACA  ; -> prom_a 0x45ACA
T_F411DC:	jp 0xFC5ACB  ; -> prom_a 0x45ACB
T_F411E0:	jp 0xFC5ACC  ; -> prom_a 0x45ACC
T_F411E4:	jp 0xFC5B25  ; -> prom_a 0x45B25
T_F411E8:	jp 0xFC596C  ; -> prom_a 0x4596C
T_F411EC:	jp 0xFC5566  ; -> prom_a 0x45566   x7
	.fill 0x40, 1, 0x0E  ; 0xF411F0: 64 x ret
T_F41230:	jp 0xF8E320  ; -> prom_a 0x0E320   x10
T_F41234:	jp 0xF8E1FE  ; -> prom_a 0x0E1FE   x10
T_F41238:	jp 0xF8E222  ; -> prom_a 0x0E222   x7
T_F4123C:	jp 0xF8E66D  ; -> prom_a 0x0E66D   x22
T_F41240:	jp 0xF8E3D1  ; -> prom_a 0x0E3D1   x4
	.fill 0xC, 1, 0x0E  ; 0xF41244: 12 x ret
T_F41250:	jp 0xF36E21  ; -> prom_b 0x36E21   x1
T_F41254:	jp 0xF36F8C  ; -> prom_b 0x36F8C   x1
T_F41258:	jp 0xF379AB  ; -> prom_b 0x379AB   x1
T_F4125C:	jp 0xF37D17  ; -> prom_b 0x37D17   x1
T_F41260:	jp 0xF37DAE  ; -> prom_b 0x37DAE   x3
T_F41264:	jp 0xF37E1C  ; -> prom_b 0x37E1C   x1
	.fill 0x148, 1, 0x0E  ; 0xF41268: 328 x ret
T_F413B0:	.long 0x00FC8000	; ptr -> 0xFC8000 (prom_a 0x48000)
T_F413B4:	jp 0xFC80E2  ; -> prom_a 0x480E2   x1
T_F413B8:	jp 0xFC87AE  ; -> prom_a 0x487AE   x4
T_F413BC:	jp 0xFC8960  ; -> prom_a 0x48960   x1
T_F413C0:	jp 0xFC8A8D  ; -> prom_a 0x48A8D   x6
T_F413C4:	jp 0xFC8B36  ; -> prom_a 0x48B36   x3
T_F413C8:	jp 0xFC8CE0  ; -> prom_a 0x48CE0   x11
T_F413CC:	jp 0xFC8D45  ; -> prom_a 0x48D45   x1
T_F413D0:	jp 0xFC807D  ; -> prom_a 0x4807D   x1
T_F413D4:	jp 0xFC8D49  ; -> prom_a 0x48D49   x2
T_F413D8:	jp 0xFCB2F0  ; -> prom_a 0x4B2F0   x1
T_F413DC:	jp 0xFCAD7C  ; -> prom_a 0x4AD7C   x2
T_F413E0:	jp 0xFC8E7B  ; -> prom_a 0x48E7B   x2
T_F413E4:	jp 0xFC80DC  ; -> prom_a 0x480DC   x3
T_F413E8:	jp 0xFC80DD  ; -> prom_a 0x480DD   x1
T_F413EC:	jp 0xFC80DE  ; -> prom_a 0x480DE
T_F413F0:	jp 0xFC80DF  ; -> prom_a 0x480DF
T_F413F4:	jp 0xFC80E0  ; -> prom_a 0x480E0
T_F413F8:	jp 0xFC8448  ; -> prom_a 0x48448   x1
T_F413FC:	jp 0xFC8FD7  ; -> prom_a 0x48FD7   x8
T_F41400:	jp 0xFC9016  ; -> prom_a 0x49016   x4
	.fill 0xAC, 1, 0x0E  ; 0xF41404: 172 x ret
T_F414B0:	jp 0xF4C800  ; -> prom_b 0x4C800   x2
T_F414B4:	jp 0xF4C802  ; -> prom_b 0x4C802   x1
T_F414B8:	jp 0xF4CA64  ; -> prom_b 0x4CA64   x1
T_F414BC:	jp 0xF4CA2A  ; -> prom_b 0x4CA2A   x1
T_F414C0:	jp 0xF4CADA  ; -> prom_b 0x4CADA   x1
T_F414C4:	jp 0xF4CA92  ; -> prom_b 0x4CA92   x1
	.fill 0x38, 1, 0x0E  ; 0xF414C8: 56 x ret
T_F41500:	jp 0xF90C00  ; -> prom_a 0x10C00
T_F41504:	jp 0xF90C12  ; -> prom_a 0x10C12
T_F41508:	jp 0xF90C13  ; -> prom_a 0x10C13
T_F4150C:	jp 0xF90C20  ; -> prom_a 0x10C20
T_F41510:	jp 0xF94078  ; -> prom_a 0x14078
T_F41514:	jp 0xF9407C  ; -> prom_a 0x1407C
T_F41518:	jp 0xF94080  ; -> prom_a 0x14080
T_F4151C:	jp 0xF9408A  ; -> prom_a 0x1408A
T_F41520:	jp 0xF90CC2  ; -> prom_a 0x10CC2
T_F41524:	jp 0xF90CC6  ; -> prom_a 0x10CC6
T_F41528:	jp 0xF90CCA  ; -> prom_a 0x10CCA
T_F4152C:	jp 0xF90CD4  ; -> prom_a 0x10CD4
T_F41530:	jp 0xF914D9  ; -> prom_a 0x114D9
T_F41534:	jp 0xF914DD  ; -> prom_a 0x114DD
T_F41538:	jp 0xF914E1  ; -> prom_a 0x114E1
T_F4153C:	jp 0xF914F7  ; -> prom_a 0x114F7
T_F41540:	jp 0xF92710  ; -> prom_a 0x12710
T_F41544:	jp 0xF92714  ; -> prom_a 0x12714
T_F41548:	jp 0xF92718  ; -> prom_a 0x12718
T_F4154C:	jp 0xF92722  ; -> prom_a 0x12722
T_F41550:	jp 0xF92C50  ; -> prom_a 0x12C50
T_F41554:	jp 0xF92C54  ; -> prom_a 0x12C54
T_F41558:	jp 0xF92C58  ; -> prom_a 0x12C58
T_F4155C:	jp 0xF92C62  ; -> prom_a 0x12C62
T_F41560:	jp 0xF93541  ; -> prom_a 0x13541
T_F41564:	jp 0xF93541  ; -> prom_a 0x13541
T_F41568:	jp 0xF93541  ; -> prom_a 0x13541
T_F4156C:	jp 0xF93541  ; -> prom_a 0x13541
T_F41570:	jp 0xF93541  ; -> prom_a 0x13541
T_F41574:	jp 0xF93545  ; -> prom_a 0x13545
T_F41578:	jp 0xF93549  ; -> prom_a 0x13549
T_F4157C:	jp 0xF93553  ; -> prom_a 0x13553
T_F41580:	jp 0xF93823  ; -> prom_a 0x13823
T_F41584:	jp 0xF93827  ; -> prom_a 0x13827
T_F41588:	jp 0xF9382B  ; -> prom_a 0x1382B
T_F4158C:	jp 0xF93835  ; -> prom_a 0x13835
T_F41590:	jp 0xF93F4E  ; -> prom_a 0x13F4E
T_F41594:	jp 0xF93F4E  ; -> prom_a 0x13F4E
T_F41598:	jp 0xF93F4E  ; -> prom_a 0x13F4E
T_F4159C:	jp 0xF93F4E  ; -> prom_a 0x13F4E
T_F415A0:	jp 0xF93FF2  ; -> prom_a 0x13FF2
T_F415A4:	jp 0xF914AF  ; -> prom_a 0x114AF
T_F415A8:	jp 0xF9427D  ; -> prom_a 0x1427D
T_F415AC:	jp 0xF943EE  ; -> prom_a 0x143EE
T_F415B0:	jp 0xF93F4E  ; -> prom_a 0x13F4E
T_F415B4:	jp 0xF9458C  ; -> prom_a 0x1458C   x2
T_F415B8:	jp 0xF945F4  ; -> prom_a 0x145F4
T_F415BC:	jp 0xF94600  ; -> prom_a 0x14600   x2
T_F415C0:	jp 0xF90C21  ; -> prom_a 0x10C21   x2
T_F415C4:	jp 0xF90C72  ; -> prom_a 0x10C72   x4
T_F415C8:	jp 0xF9433A  ; -> prom_a 0x1433A   x10
	.fill 0x34, 1, 0x0E  ; 0xF415CC: 52 x ret
T_F41600:	jp 0xF99098  ; -> prom_a 0x19098   x13
T_F41604:	jp 0xF99021  ; -> prom_a 0x19021
T_F41608:	jp 0xF9904C  ; -> prom_a 0x1904C
T_F4160C:	jp 0xF9904D  ; -> prom_a 0x1904D
T_F41610:	jp 0xF99097  ; -> prom_a 0x19097
	.fill 0x2C, 1, 0x0E  ; 0xF41614: 44 x ret
T_F41640:	jp 0xF99F04  ; -> prom_a 0x19F04
T_F41644:	jp 0xF99F15  ; -> prom_a 0x19F15
T_F41648:	jp 0xF99F1A  ; -> prom_a 0x19F1A
T_F4164C:	jp 0xF99F1F  ; -> prom_a 0x19F1F
T_F41650:	jp 0xF99F24  ; -> prom_a 0x19F24
T_F41654:	jp 0xF99F5C  ; -> prom_a 0x19F5C
T_F41658:	jp 0xF99F5E  ; -> prom_a 0x19F5E
T_F4165C:	jp 0xF99F5D  ; -> prom_a 0x19F5D
T_F41660:	jp 0xF99821  ; -> prom_a 0x19821
T_F41664:	jp 0xF99821  ; -> prom_a 0x19821
T_F41668:	jp 0xF99821  ; -> prom_a 0x19821
T_F4166C:	jp 0xF99821  ; -> prom_a 0x19821
T_F41670:	jp 0xF99825  ; -> prom_a 0x19825
T_F41674:	jp 0xF99825  ; -> prom_a 0x19825
T_F41678:	jp 0xF99825  ; -> prom_a 0x19825
T_F4167C:	jp 0xF99825  ; -> prom_a 0x19825
T_F41680:	jp 0xF99826  ; -> prom_a 0x19826
T_F41684:	jp 0xF99826  ; -> prom_a 0x19826
T_F41688:	jp 0xF99826  ; -> prom_a 0x19826
T_F4168C:	jp 0xF99826  ; -> prom_a 0x19826
T_F41690:	jp 0xF9A6C0  ; -> prom_a 0x1A6C0
T_F41694:	jp 0xF9A754  ; -> prom_a 0x1A754
T_F41698:	jp 0xF9A756  ; -> prom_a 0x1A756
T_F4169C:	jp 0xF9A755  ; -> prom_a 0x1A755
T_F416A0:	jp 0xF99827  ; -> prom_a 0x19827
T_F416A4:	jp 0xF99827  ; -> prom_a 0x19827
T_F416A8:	jp 0xF99827  ; -> prom_a 0x19827
T_F416AC:	jp 0xF99827  ; -> prom_a 0x19827
T_F416B0:	jp 0xF99828  ; -> prom_a 0x19828
T_F416B4:	jp 0xF99828  ; -> prom_a 0x19828
T_F416B8:	jp 0xF99828  ; -> prom_a 0x19828
T_F416BC:	jp 0xF99828  ; -> prom_a 0x19828
T_F416C0:	jp 0xF9982B  ; -> prom_a 0x1982B
T_F416C4:	jp 0xF9982B  ; -> prom_a 0x1982B
T_F416C8:	jp 0xF9982B  ; -> prom_a 0x1982B
T_F416CC:	jp 0xF9982B  ; -> prom_a 0x1982B
T_F416D0:	jp 0xF9982C  ; -> prom_a 0x1982C
T_F416D4:	jp 0xF9982C  ; -> prom_a 0x1982C
T_F416D8:	jp 0xF9982C  ; -> prom_a 0x1982C
T_F416DC:	jp 0xF9982C  ; -> prom_a 0x1982C
T_F416E0:	jp 0xF99822  ; -> prom_a 0x19822
T_F416E4:	jp 0xF99822  ; -> prom_a 0x19822
T_F416E8:	jp 0xF99822  ; -> prom_a 0x19822
T_F416EC:	jp 0xF99822  ; -> prom_a 0x19822
T_F416F0:	jp 0xF99823  ; -> prom_a 0x19823
T_F416F4:	jp 0xF99823  ; -> prom_a 0x19823
T_F416F8:	jp 0xF99823  ; -> prom_a 0x19823
T_F416FC:	jp 0xF99823  ; -> prom_a 0x19823
T_F41700:	jp 0xF99824  ; -> prom_a 0x19824
T_F41704:	jp 0xF99824  ; -> prom_a 0x19824
T_F41708:	jp 0xF99824  ; -> prom_a 0x19824
T_F4170C:	jp 0xF99824  ; -> prom_a 0x19824
T_F41710:	jp 0xF9982D  ; -> prom_a 0x1982D
T_F41714:	jp 0xF99831  ; -> prom_a 0x19831
T_F41718:	jp 0xF99835  ; -> prom_a 0x19835
T_F4171C:	jp 0xF99843  ; -> prom_a 0x19843
T_F41720:	jp 0xF99844  ; -> prom_a 0x19844
T_F41724:	jp 0xF99848  ; -> prom_a 0x19848
T_F41728:	jp 0xF9984C  ; -> prom_a 0x1984C
T_F4172C:	jp 0xF9985A  ; -> prom_a 0x1985A
T_F41730:	jp 0xF9985B  ; -> prom_a 0x1985B   x1
T_F41734:	jp 0xF9985F  ; -> prom_a 0x1985F   x1
T_F41738:	jp 0xF99863  ; -> prom_a 0x19863
T_F4173C:	jp 0xF9A1A8  ; -> prom_a 0x1A1A8
T_F41740:	jp 0xF9A26D  ; -> prom_a 0x1A26D
T_F41744:	jp 0xF9A26F  ; -> prom_a 0x1A26F
T_F41748:	jp 0xF9A26E  ; -> prom_a 0x1A26E
T_F4174C:	jp 0xF9A998  ; -> prom_a 0x1A998
T_F41750:	jp 0xF9AA4F  ; -> prom_a 0x1AA4F
T_F41754:	jp 0xF9AA51  ; -> prom_a 0x1AA51
T_F41758:	jp 0xF9AA50  ; -> prom_a 0x1AA50
T_F4175C:	jp 0xF9AF61  ; -> prom_a 0x1AF61
T_F41760:	jp 0xF9B05E  ; -> prom_a 0x1B05E
T_F41764:	jp 0xF9B060  ; -> prom_a 0x1B060
T_F41768:	jp 0xF9B05F  ; -> prom_a 0x1B05F
T_F4176C:	.long 0x00F99800	; ptr -> 0xF99800 (prom_a 0x19800)
	.fill 0x80, 1, 0x0E  ; 0xF41770: 128 x ret
; --- the two display-list interpreters.  These are the two busiest slots in the
;     whole table; both targets are converted below at 0xF31800.
T_F417F0:	jp DisplayList_Run  ; -> prom_b 0x31A09   x392  THE UI ENGINE
T_F417F4:	jp DisplayListB_Run  ; -> prom_b 0x31AF0   x269  the second interpreter
T_F417F8:	jp 0xF31B21  ; -> prom_b 0x31B21   x15
T_F417FC:	jp 0xF31B39  ; -> prom_b 0x31B39   x16
T_F41800:	jp 0xF31BA1  ; -> prom_b 0x31BA1   x3
T_F41804:	jp 0xF31BA1  ; -> prom_b 0x31BA1   x3
T_F41808:	jp 0xF31BD7  ; -> prom_b 0x31BD7
T_F4180C:	jp 0xF31C14  ; -> prom_b 0x31C14   x8
T_F41810:	jp 0xF31C14  ; -> prom_b 0x31C14
T_F41814:	jp 0xF31C56  ; -> prom_b 0x31C56   x1
T_F41818:	jp 0xF31C9E  ; -> prom_b 0x31C9E
T_F4181C:	jp 0xF31B57  ; -> prom_b 0x31B57   x53
T_F41820:	jp 0xF31B57  ; -> prom_b 0x31B57   x15
T_F41824:	jp 0xF31B86  ; -> prom_b 0x31B86   x7
T_F41828:	jp 0xF31ACE  ; -> prom_b 0x31ACE
T_F4182C:	jp 0xF31A3A  ; -> prom_b 0x31A3A   x6
T_F41830:	jp 0xF31AEC  ; -> prom_b 0x31AEC   x5
T_F41834:	jp 0xF31873  ; -> prom_b 0x31873   x10
	.fill 0x8, 1, 0x0E  ; 0xF41838: 8 x ret
T_F41840:	jp 0xFBCB06  ; -> prom_a 0x3CB06
T_F41844:	jp 0xFBCB31  ; -> prom_a 0x3CB31
T_F41848:	jp 0xFBCB40  ; -> prom_a 0x3CB40
T_F4184C:	jp 0xFBCB81  ; -> prom_a 0x3CB81
T_F41850:	jp 0xFBCB82  ; -> prom_a 0x3CB82
T_F41854:	jp 0xFBCBA9  ; -> prom_a 0x3CBA9
T_F41858:	jp 0xFBCDFC  ; -> prom_a 0x3CDFC
T_F4185C:	jp 0xFBCEF7  ; -> prom_a 0x3CEF7
T_F41860:	jp 0xFBCF3C  ; -> prom_a 0x3CF3C
T_F41864:	jp 0xFBCF81  ; -> prom_a 0x3CF81
T_F41868:	jp 0xFBC56B  ; -> prom_a 0x3C56B
T_F4186C:	jp 0xFBC56F  ; -> prom_a 0x3C56F
T_F41870:	jp 0xFBC573  ; -> prom_a 0x3C573
T_F41874:	jp 0xFBC584  ; -> prom_a 0x3C584
T_F41878:	jp 0xFBC5BD  ; -> prom_a 0x3C5BD
T_F4187C:	jp 0xFBC5C1  ; -> prom_a 0x3C5C1
T_F41880:	jp 0xFBC5C5  ; -> prom_a 0x3C5C5
T_F41884:	jp 0xFBC5D6  ; -> prom_a 0x3C5D6
T_F41888:	jp 0xFBCDEC  ; -> prom_a 0x3CDEC
T_F4188C:	jp 0xFBCEE7  ; -> prom_a 0x3CEE7
T_F41890:	jp 0xFBCEF8  ; -> prom_a 0x3CEF8
T_F41894:	jp 0xFBCF7D  ; -> prom_a 0x3CF7D
T_F41898:	jp 0xFBCDF0  ; -> prom_a 0x3CDF0
T_F4189C:	jp 0xFBCEEB  ; -> prom_a 0x3CEEB
T_F418A0:	jp 0xFBCF09  ; -> prom_a 0x3CF09
T_F418A4:	jp 0xFBCF7E  ; -> prom_a 0x3CF7E
T_F418A8:	jp 0xFBC5D7  ; -> prom_a 0x3C5D7
T_F418AC:	jp 0xFBC5DB  ; -> prom_a 0x3C5DB
T_F418B0:	jp 0xFBC5DF  ; -> prom_a 0x3C5DF
T_F418B4:	jp 0xFBC5F0  ; -> prom_a 0x3C5F0
T_F418B8:	jp 0xFBDB95  ; -> prom_a 0x3DB95
T_F418BC:	jp 0xFBDD11  ; -> prom_a 0x3DD11
T_F418C0:	jp 0xFBDD91  ; -> prom_a 0x3DD91
T_F418C4:	jp 0xFBDDD6  ; -> prom_a 0x3DDD6
T_F418C8:	jp 0xFBC5F1  ; -> prom_a 0x3C5F1
T_F418CC:	jp 0xFBC64F  ; -> prom_a 0x3C64F
T_F418D0:	jp 0xFBB800  ; -> prom_a 0x3B800   x3
T_F418D4:	jp 0xFBB93C  ; -> prom_a 0x3B93C
T_F418D8:	jp 0xFBEE83  ; -> prom_a 0x3EE83
	.fill 0x34, 1, 0x0E  ; 0xF418DC: 52 x ret
T_F41910:	jp 0xF9FED1  ; -> prom_a 0x1FED1
T_F41914:	jp 0xF9FEE2  ; -> prom_a 0x1FEE2
T_F41918:	jp 0xF9FEE7  ; -> prom_a 0x1FEE7
T_F4191C:	jp 0xF9FEFF  ; -> prom_a 0x1FEFF
T_F41920:	jp 0xF9FF00  ; -> prom_a 0x1FF00
T_F41924:	jp 0xF9FF27  ; -> prom_a 0x1FF27
T_F41928:	jp 0xFA0094  ; -> prom_a 0x20094
T_F4192C:	jp 0xFA00E9  ; -> prom_a 0x200E9
T_F41930:	jp 0xFA00EA  ; -> prom_a 0x200EA
T_F41934:	jp 0xFA0111  ; -> prom_a 0x20111
T_F41938:	jp 0xFA0689  ; -> prom_a 0x20689
T_F4193C:	jp 0xFA07A1  ; -> prom_a 0x207A1
T_F41940:	jp 0xFA07A2  ; -> prom_a 0x207A2
T_F41944:	jp 0xFA07EA  ; -> prom_a 0x207EA
T_F41948:	jp 0xFA0DF3  ; -> prom_a 0x20DF3
T_F4194C:	jp 0xFA0E4D  ; -> prom_a 0x20E4D
T_F41950:	jp 0xFA0EEA  ; -> prom_a 0x20EEA
T_F41954:	jp 0xFA0F11  ; -> prom_a 0x20F11
T_F41958:	jp 0xF9EF6C  ; -> prom_a 0x1EF6C
T_F4195C:	jp 0xF9EF71  ; -> prom_a 0x1EF71
T_F41960:	jp 0xF9EF72  ; -> prom_a 0x1EF72
T_F41964:	jp 0xF9EF84  ; -> prom_a 0x1EF84
T_F41968:	jp 0xF9C087  ; -> prom_a 0x1C087
T_F4196C:	jp 0xF9C0C1  ; -> prom_a 0x1C0C1
T_F41970:	jp 0xF9C0C2  ; -> prom_a 0x1C0C2
T_F41974:	jp 0xF9C0E9  ; -> prom_a 0x1C0E9
T_F41978:	jp 0xF9C9F4  ; -> prom_a 0x1C9F4
T_F4197C:	jp 0xF9CA0C  ; -> prom_a 0x1CA0C
T_F41980:	jp 0xF9CA0D  ; -> prom_a 0x1CA0D
T_F41984:	jp 0xF9CA34  ; -> prom_a 0x1CA34
T_F41988:	jp 0xF9ED34  ; -> prom_a 0x1ED34
T_F4198C:	jp 0xF9EDA1  ; -> prom_a 0x1EDA1
T_F41990:	jp 0xF9EDA2  ; -> prom_a 0x1EDA2
T_F41994:	jp 0xF9EDC9  ; -> prom_a 0x1EDC9
T_F41998:	jp 0xF9EB75  ; -> prom_a 0x1EB75
T_F4199C:	jp 0xF9EBED  ; -> prom_a 0x1EBED
T_F419A0:	jp 0xF9EBEE  ; -> prom_a 0x1EBEE
T_F419A4:	jp 0xF9EC15  ; -> prom_a 0x1EC15
T_F419A8:	jp 0xFA007B  ; -> prom_a 0x2007B
T_F419AC:	jp 0xFA0080  ; -> prom_a 0x20080
T_F419B0:	jp 0xFA0081  ; -> prom_a 0x20081
T_F419B4:	jp 0xFA0093  ; -> prom_a 0x20093
T_F419B8:	jp 0xF9EF85  ; -> prom_a 0x1EF85
T_F419BC:	jp 0xF9EFF6  ; -> prom_a 0x1EFF6
T_F419C0:	jp 0xF9F006  ; -> prom_a 0x1F006
T_F419C4:	jp 0xF9F034  ; -> prom_a 0x1F034
	.fill 0x38, 1, 0x0E  ; 0xF419C8: 56 x ret
T_F41A00:	jp 0xFBECC3  ; -> prom_a 0x3ECC3
T_F41A04:	jp 0xFBED02  ; -> prom_a 0x3ED02
T_F41A08:	jp 0xFBEED9  ; -> prom_a 0x3EED9
T_F41A0C:	jp 0xFBEEE3  ; -> prom_a 0x3EEE3
T_F41A10:	jp 0xFBEEE4  ; -> prom_a 0x3EEE4
T_F41A14:	jp 0xFBEEE5  ; -> prom_a 0x3EEE5
T_F41A18:	jp 0xFBFAB0  ; -> prom_a 0x3FAB0
T_F41A1C:	jp 0xFBFAF1  ; -> prom_a 0x3FAF1
T_F41A20:	jp 0xFBFAF2  ; -> prom_a 0x3FAF2
T_F41A24:	jp 0xFBFB33  ; -> prom_a 0x3FB33
T_F41A28:	jp 0xFBC585  ; -> prom_a 0x3C585
T_F41A2C:	jp 0xFBC589  ; -> prom_a 0x3C589
T_F41A30:	jp 0xFBC58D  ; -> prom_a 0x3C58D
T_F41A34:	jp 0xFBC59E  ; -> prom_a 0x3C59E
T_F41A38:	jp 0xFBC59F  ; -> prom_a 0x3C59F
T_F41A3C:	jp 0xFBC5A3  ; -> prom_a 0x3C5A3
T_F41A40:	jp 0xFBC5A7  ; -> prom_a 0x3C5A7
T_F41A44:	jp 0xFBC5B8  ; -> prom_a 0x3C5B8
T_F41A48:	jp 0xFBCDF4  ; -> prom_a 0x3CDF4
T_F41A4C:	jp 0xFBCEEF  ; -> prom_a 0x3CEEF
T_F41A50:	jp 0xFBCF1A  ; -> prom_a 0x3CF1A
T_F41A54:	jp 0xFBCF7F  ; -> prom_a 0x3CF7F
T_F41A58:	jp 0xFBCDF8  ; -> prom_a 0x3CDF8
T_F41A5C:	jp 0xFBCEF3  ; -> prom_a 0x3CEF3
T_F41A60:	jp 0xFBCF2B  ; -> prom_a 0x3CF2B
T_F41A64:	jp 0xFBCF80  ; -> prom_a 0x3CF80
T_F41A68:	jp 0xFBEEE6  ; -> prom_a 0x3EEE6
T_F41A6C:	jp 0xFBEEEB  ; -> prom_a 0x3EEEB
T_F41A70:	jp 0xFBEEEC  ; -> prom_a 0x3EEEC
T_F41A74:	jp 0xFBEF1B  ; -> prom_a 0x3EF1B
T_F41A78:	jp 0xFBDB91  ; -> prom_a 0x3DB91
T_F41A7C:	jp 0xFBDD0D  ; -> prom_a 0x3DD0D
T_F41A80:	jp 0xFBDD80  ; -> prom_a 0x3DD80
T_F41A84:	jp 0xFBDDD2  ; -> prom_a 0x3DDD2
T_F41A88:	jp 0xFBC5B9  ; -> prom_a 0x3C5B9
T_F41A8C:	jp 0xFBC5BA  ; -> prom_a 0x3C5BA
T_F41A90:	jp 0xFBC5BB  ; -> prom_a 0x3C5BB
T_F41A94:	jp 0xFBC5BC  ; -> prom_a 0x3C5BC
T_F41A98:	jp 0xFBEF1C  ; -> prom_a 0x3EF1C
T_F41A9C:	jp 0xFBEF75  ; -> prom_a 0x3EF75
T_F41AA0:	jp 0xFBEF76  ; -> prom_a 0x3EF76
T_F41AA4:	jp 0xFBEFB0  ; -> prom_a 0x3EFB0
	.fill 0x48, 1, 0x0E  ; 0xF41AA8: 72 x ret
T_F41AF0:	jp 0xF8BCAF  ; -> prom_a 0x0BCAF   x35
T_F41AF4:	jp 0xF8BC8A  ; -> prom_a 0x0BC8A   x2
T_F41AF8:	jp 0xF8BCC9  ; -> prom_a 0x0BCC9   x7
T_F41AFC:	jp 0xF8BCD0  ; -> prom_a 0x0BCD0
T_F41B00:	jp 0xF8BCD7  ; -> prom_a 0x0BCD7   x10
T_F41B04:	jp 0xF8BD73  ; -> prom_a 0x0BD73   x9
T_F41B08:	jp 0xF8BDC5  ; -> prom_a 0x0BDC5   x32
T_F41B0C:	jp 0xF8BDF8  ; -> prom_a 0x0BDF8   x2
T_F41B10:	jp 0xF8BC00  ; -> prom_a 0x0BC00   x3
T_F41B14:	jp 0xF8BC04  ; -> prom_a 0x0BC04   x12
T_F41B18:	jp 0xF8BC08  ; -> prom_a 0x0BC08   x34
	.fill 0x14, 1, 0x0E  ; 0xF41B1C: 20 x ret
T_F41B30:	.long 0x00F8DC00	; ptr -> 0xF8DC00 (prom_a 0x0DC00)
T_F41B34:	jp 0xF8DC25  ; -> prom_a 0x0DC25   x1
	.fill 0x198, 1, 0x0E  ; 0xF41B38: 408 x ret
T_F41CD0:	jp 0xF842DF  ; -> prom_a 0x042DF   x6
T_F41CD4:	jp 0xF842ED  ; -> prom_a 0x042ED
T_F41CD8:	jp 0xF84304  ; -> prom_a 0x04304
T_F41CDC:	jp 0xF84327  ; -> prom_a 0x04327   x3
T_F41CE0:	jp 0xF8433C  ; -> prom_a 0x0433C   x1
T_F41CE4:	jp 0xF8434A  ; -> prom_a 0x0434A
T_F41CE8:	jp 0xF84357  ; -> prom_a 0x04357
T_F41CEC:	jp 0xF84366  ; -> prom_a 0x04366
T_F41CF0:	jp 0xF84375  ; -> prom_a 0x04375
T_F41CF4:	jp 0xF84382  ; -> prom_a 0x04382   x1
T_F41CF8:	jp 0xF84390  ; -> prom_a 0x04390
T_F41CFC:	jp 0xF843A7  ; -> prom_a 0x043A7
T_F41D00:	jp 0xF843CA  ; -> prom_a 0x043CA
T_F41D04:	jp 0xF843DF  ; -> prom_a 0x043DF   x1
T_F41D08:	jp 0xF843ED  ; -> prom_a 0x043ED
T_F41D0C:	jp 0xF843FA  ; -> prom_a 0x043FA
T_F41D10:	jp 0xF84409  ; -> prom_a 0x04409
T_F41D14:	jp 0xF84418  ; -> prom_a 0x04418
T_F41D18:	jp 0xF8493D  ; -> prom_a 0x0493D   x1
T_F41D1C:	jp 0xF8494B  ; -> prom_a 0x0494B
T_F41D20:	jp 0xF84962  ; -> prom_a 0x04962
T_F41D24:	jp 0xF84985  ; -> prom_a 0x04985   x1
T_F41D28:	jp 0xF8499A  ; -> prom_a 0x0499A   x2
T_F41D2C:	jp 0xF849A8  ; -> prom_a 0x049A8
T_F41D30:	jp 0xF849B5  ; -> prom_a 0x049B5
T_F41D34:	jp 0xF849C4  ; -> prom_a 0x049C4
T_F41D38:	jp 0xF849D3  ; -> prom_a 0x049D3
T_F41D3C:	jp 0xF84425  ; -> prom_a 0x04425
T_F41D40:	jp 0xF84433  ; -> prom_a 0x04433
T_F41D44:	jp 0xF8444A  ; -> prom_a 0x0444A
T_F41D48:	jp 0xF8446D  ; -> prom_a 0x0446D
T_F41D4C:	jp 0xF84482  ; -> prom_a 0x04482   x1
T_F41D50:	jp 0xF84490  ; -> prom_a 0x04490
T_F41D54:	jp 0xF8449D  ; -> prom_a 0x0449D
T_F41D58:	jp 0xF844AC  ; -> prom_a 0x044AC
T_F41D5C:	jp 0xF844BB  ; -> prom_a 0x044BB
T_F41D60:	jp 0xF8456B  ; -> prom_a 0x0456B   x1
T_F41D64:	jp 0xF84579  ; -> prom_a 0x04579   x67
T_F41D68:	jp 0xF84590  ; -> prom_a 0x04590
T_F41D6C:	jp 0xF845B3  ; -> prom_a 0x045B3
T_F41D70:	jp 0xF845C8  ; -> prom_a 0x045C8   x2
T_F41D74:	jp 0xF845D6  ; -> prom_a 0x045D6   x2
T_F41D78:	jp 0xF845E3  ; -> prom_a 0x045E3   x6
T_F41D7C:	jp 0xF845F2  ; -> prom_a 0x045F2
T_F41D80:	jp 0xF84601  ; -> prom_a 0x04601
T_F41D84:	jp 0xF8460E  ; -> prom_a 0x0460E   x48
T_F41D88:	jp 0xF8461C  ; -> prom_a 0x0461C
T_F41D8C:	jp 0xF84633  ; -> prom_a 0x04633   x2
T_F41D90:	jp 0xF84656  ; -> prom_a 0x04656   x7
T_F41D94:	jp 0xF8466B  ; -> prom_a 0x0466B   x4
T_F41D98:	jp 0xF84679  ; -> prom_a 0x04679
T_F41D9C:	jp 0xF84686  ; -> prom_a 0x04686
T_F41DA0:	jp 0xF84695  ; -> prom_a 0x04695
T_F41DA4:	jp 0xF846A4  ; -> prom_a 0x046A4
T_F41DA8:	jp 0xF846B1  ; -> prom_a 0x046B1
T_F41DAC:	jp 0xF846BF  ; -> prom_a 0x046BF   x5
T_F41DB0:	jp 0xF846D6  ; -> prom_a 0x046D6   x1
T_F41DB4:	jp 0xF846F9  ; -> prom_a 0x046F9   x1
T_F41DB8:	jp 0xF8470E  ; -> prom_a 0x0470E   x4
T_F41DBC:	jp 0xF8471C  ; -> prom_a 0x0471C   x2
T_F41DC0:	jp 0xF84729  ; -> prom_a 0x04729   x4
T_F41DC4:	jp 0xF84738  ; -> prom_a 0x04738
T_F41DC8:	jp 0xF84747  ; -> prom_a 0x04747
T_F41DCC:	jp 0xF84754  ; -> prom_a 0x04754
T_F41DD0:	jp 0xF84762  ; -> prom_a 0x04762
T_F41DD4:	jp 0xF84779  ; -> prom_a 0x04779   x2
T_F41DD8:	jp 0xF8479C  ; -> prom_a 0x0479C   x1
T_F41DDC:	jp 0xF847B1  ; -> prom_a 0x047B1   x2
T_F41DE0:	jp 0xF847BF  ; -> prom_a 0x047BF   x2
T_F41DE4:	jp 0xF847CC  ; -> prom_a 0x047CC   x4
T_F41DE8:	jp 0xF847DB  ; -> prom_a 0x047DB
T_F41DEC:	jp 0xF847EA  ; -> prom_a 0x047EA
T_F41DF0:	jp 0xF847F7  ; -> prom_a 0x047F7   x1
T_F41DF4:	jp 0xF84805  ; -> prom_a 0x04805   x1
T_F41DF8:	jp 0xF8481C  ; -> prom_a 0x0481C   x10
T_F41DFC:	jp 0xF8483F  ; -> prom_a 0x0483F   x2
T_F41E00:	jp 0xF84854  ; -> prom_a 0x04854   x4
T_F41E04:	jp 0xF84862  ; -> prom_a 0x04862
T_F41E08:	jp 0xF8486F  ; -> prom_a 0x0486F
T_F41E0C:	jp 0xF8487E  ; -> prom_a 0x0487E
T_F41E10:	jp 0xF8488D  ; -> prom_a 0x0488D
T_F41E14:	jp 0xF8489A  ; -> prom_a 0x0489A   x1
T_F41E18:	jp 0xF848A8  ; -> prom_a 0x048A8
T_F41E1C:	jp 0xF848BF  ; -> prom_a 0x048BF   x5
T_F41E20:	jp 0xF848E2  ; -> prom_a 0x048E2
T_F41E24:	jp 0xF848F7  ; -> prom_a 0x048F7   x2
T_F41E28:	jp 0xF84905  ; -> prom_a 0x04905
T_F41E2C:	jp 0xF84912  ; -> prom_a 0x04912
T_F41E30:	jp 0xF84921  ; -> prom_a 0x04921
T_F41E34:	jp 0xF84930  ; -> prom_a 0x04930
T_F41E38:	jp 0xF849E0  ; -> prom_a 0x049E0   x2
T_F41E3C:	jp 0xF849EE  ; -> prom_a 0x049EE   x4
T_F41E40:	jp 0xF84A05  ; -> prom_a 0x04A05   x2
T_F41E44:	jp 0xF84A28  ; -> prom_a 0x04A28
T_F41E48:	jp 0xF84A3D  ; -> prom_a 0x04A3D   x3
T_F41E4C:	jp 0xF84A4B  ; -> prom_a 0x04A4B
T_F41E50:	jp 0xF84A58  ; -> prom_a 0x04A58
T_F41E54:	jp 0xF84A67  ; -> prom_a 0x04A67
T_F41E58:	jp 0xF84A76  ; -> prom_a 0x04A76
T_F41E5C:	jp 0xF84B26  ; -> prom_a 0x04B26   x2
T_F41E60:	jp 0xF84B34  ; -> prom_a 0x04B34
T_F41E64:	jp 0xF84B4B  ; -> prom_a 0x04B4B   x3
T_F41E68:	jp 0xF84B6E  ; -> prom_a 0x04B6E   x3
T_F41E6C:	jp 0xF84B83  ; -> prom_a 0x04B83   x5
T_F41E70:	jp 0xF84B91  ; -> prom_a 0x04B91
T_F41E74:	jp 0xF84B9E  ; -> prom_a 0x04B9E
T_F41E78:	jp 0xF84BAD  ; -> prom_a 0x04BAD
T_F41E7C:	jp 0xF84BBC  ; -> prom_a 0x04BBC
T_F41E80:	jp 0xF844C8  ; -> prom_a 0x044C8   x1
T_F41E84:	jp 0xF844D6  ; -> prom_a 0x044D6
T_F41E88:	jp 0xF844ED  ; -> prom_a 0x044ED
T_F41E8C:	jp 0xF84510  ; -> prom_a 0x04510   x2
T_F41E90:	jp 0xF84525  ; -> prom_a 0x04525   x1
T_F41E94:	jp 0xF84533  ; -> prom_a 0x04533
T_F41E98:	jp 0xF84540  ; -> prom_a 0x04540
T_F41E9C:	jp 0xF8454F  ; -> prom_a 0x0454F
T_F41EA0:	jp 0xF8455E  ; -> prom_a 0x0455E
T_F41EA4:	jp 0xF84A83  ; -> prom_a 0x04A83   x1
T_F41EA8:	jp 0xF84A91  ; -> prom_a 0x04A91   x2
T_F41EAC:	jp 0xF84AA8  ; -> prom_a 0x04AA8   x1
T_F41EB0:	jp 0xF84ACB  ; -> prom_a 0x04ACB   x1
T_F41EB4:	jp 0xF84AE0  ; -> prom_a 0x04AE0   x2
T_F41EB8:	jp 0xF84AEE  ; -> prom_a 0x04AEE
T_F41EBC:	jp 0xF84AFB  ; -> prom_a 0x04AFB
T_F41EC0:	jp 0xF84B0A  ; -> prom_a 0x04B0A
T_F41EC4:	jp 0xF84B19  ; -> prom_a 0x04B19
	.fill 0x8, 1, 0x0E  ; 0xF41EC8: 8 x ret
T_F41ED0:	jp 0xF5B8B6  ; -> prom_b 0x5B8B6   x39
T_F41ED4:	jp 0xF5B9B8  ; -> prom_b 0x5B9B8   x109
T_F41ED8:	jp 0xF5BAB8  ; -> prom_b 0x5BAB8   x1
T_F41EDC:	jp 0xF5BB00  ; -> prom_b 0x5BB00
T_F41EE0:	jp 0xF5BBB2  ; -> prom_b 0x5BBB2   x7
T_F41EE4:	jp 0xF5B84C  ; -> prom_b 0x5B84C   x23
T_F41EE8:	jp 0xF5B881  ; -> prom_b 0x5B881   x9
T_F41EEC:	jp 0xF5B81C  ; -> prom_b 0x5B81C   x1
	.fill 0x8, 1, 0x0E  ; 0xF41EF0: 8 x ret
T_F41EF8:	jp 0xFBAC00  ; -> prom_a 0x3AC00   x1
T_F41EFC:	jp 0xFBAE5A  ; -> prom_a 0x3AE5A   x1
T_F41F00:	jp 0xFBB392  ; -> prom_a 0x3B392   x1
T_F41F04:	jp 0xFBB3DC  ; -> prom_a 0x3B3DC   x1
	.fill 0x8, 1, 0x0E  ; 0xF41F08: 8 x ret
T_F41F10:	jp 0xFAED76  ; -> prom_a 0x2ED76   x1
T_F41F14:	jp 0xFAE84D  ; -> prom_a 0x2E84D   x5
T_F41F18:	jp 0xFAEC8A  ; -> prom_a 0x2EC8A   x9
T_F41F1C:	jp 0xFAEC78  ; -> prom_a 0x2EC78
T_F41F20:	jp 0xFAF48F  ; -> prom_a 0x2F48F
T_F41F24:	jp 0xFAEBAA  ; -> prom_a 0x2EBAA
T_F41F28:	jp 0xFAF490  ; -> prom_a 0x2F490
T_F41F2C:	jp 0xFAE800  ; -> prom_a 0x2E800
T_F41F30:	jp 0xFAE872  ; -> prom_a 0x2E872   x1
T_F41F34:	jp 0xFAE921  ; -> prom_a 0x2E921   x1
T_F41F38:	jp 0xFAE84C  ; -> prom_a 0x2E84C
T_F41F3C:	jp 0xFAE829  ; -> prom_a 0x2E829
	.fill 0x10, 1, 0x0E  ; 0xF41F40: 16 x ret
	.fill 0x4, 1, 0x00  ; 0xF41F50: 4 x nop
T_F41F54:	jp 0xFDAC6B  ; -> prom_a 0x5AC6B
T_F41F58:	jp 0xFDACBD  ; -> prom_a 0x5ACBD
T_F41F5C:	jp 0xFDAD44  ; -> prom_a 0x5AD44
T_F41F60:	jp 0xFDE152  ; -> prom_a 0x5E152
T_F41F64:	jp 0xFCFDA7  ; -> prom_a 0x4FDA7
T_F41F68:	jp 0xFDE15F  ; -> prom_a 0x5E15F
T_F41F6C:	jp 0xFDD437  ; -> prom_a 0x5D437
T_F41F70:	jp 0xFDE332  ; -> prom_a 0x5E332
T_F41F74:	jp 0xFD3DA7  ; -> prom_a 0x53DA7
T_F41F78:	jp 0xFDE33F  ; -> prom_a 0x5E33F
T_F41F7C:	jp 0xFDD7F7  ; -> prom_a 0x5D7F7
T_F41F80:	jp 0xFDE340  ; -> prom_a 0x5E340
T_F41F84:	jp 0xFD3DF8  ; -> prom_a 0x53DF8
T_F41F88:	jp 0xFDE34D  ; -> prom_a 0x5E34D
T_F41F8C:	jp 0xFDD7F8  ; -> prom_a 0x5D7F8
T_F41F90:	jp 0xFDE34E  ; -> prom_a 0x5E34E
T_F41F94:	jp 0xFD3DF9  ; -> prom_a 0x53DF9
T_F41F98:	jp 0xFDE35B  ; -> prom_a 0x5E35B
T_F41F9C:	jp 0xFDD7F9  ; -> prom_a 0x5D7F9
T_F41FA0:	jp 0xFDE35C  ; -> prom_a 0x5E35C
T_F41FA4:	jp 0xFD3DFA  ; -> prom_a 0x53DFA
T_F41FA8:	jp 0xFDE369  ; -> prom_a 0x5E369
T_F41FAC:	jp 0xFDD958  ; -> prom_a 0x5D958
T_F41FB0:	jp 0xFDE36A  ; -> prom_a 0x5E36A
T_F41FB4:	jp 0xFD3E4B  ; -> prom_a 0x53E4B
T_F41FB8:	jp 0xFDE377  ; -> prom_a 0x5E377
T_F41FBC:	jp 0xFDDA1C  ; -> prom_a 0x5DA1C
T_F41FC0:	jp 0xFDE378  ; -> prom_a 0x5E378
T_F41FC4:	jp 0xFD3E9C  ; -> prom_a 0x53E9C
T_F41FC8:	jp 0xFDE385  ; -> prom_a 0x5E385
T_F41FCC:	jp 0xFDDC3A  ; -> prom_a 0x5DC3A
T_F41FD0:	jp 0xFDE386  ; -> prom_a 0x5E386
T_F41FD4:	jp 0xFD3EED  ; -> prom_a 0x53EED
T_F41FD8:	jp 0xFDE393  ; -> prom_a 0x5E393
T_F41FDC:	jp 0xFDDDAA  ; -> prom_a 0x5DDAA
T_F41FE0:	jp 0xFDE394  ; -> prom_a 0x5E394
T_F41FE4:	jp 0xFD3F3E  ; -> prom_a 0x53F3E
T_F41FE8:	jp 0xFDE3A1  ; -> prom_a 0x5E3A1
T_F41FEC:	jp 0xFDDF36  ; -> prom_a 0x5DF36
T_F41FF0:	jp 0xFDE3A2  ; -> prom_a 0x5E3A2
T_F41FF4:	jp 0xFD3F8F  ; -> prom_a 0x53F8F
T_F41FF8:	jp 0xFDE3AF  ; -> prom_a 0x5E3AF
T_F41FFC:	jp 0xFDB22F  ; -> prom_a 0x5B22F
T_F42000:	jp 0xFDE160  ; -> prom_a 0x5E160
T_F42004:	jp 0xF0A000  ; -> prom_b 0x0A000
T_F42008:	jp 0xFDE16D  ; -> prom_a 0x5E16D
T_F4200C:	jp 0xFDB38C  ; -> prom_a 0x5B38C
T_F42010:	jp 0xFDE16E  ; -> prom_a 0x5E16E
T_F42014:	jp 0xF0A051  ; -> prom_b 0x0A051
T_F42018:	jp 0xFDE17B  ; -> prom_a 0x5E17B
T_F4201C:	jp 0xFDB44D  ; -> prom_a 0x5B44D
T_F42020:	jp 0xFDE17C  ; -> prom_a 0x5E17C
T_F42024:	jp 0xF0A0B1  ; -> prom_b 0x0A0B1
T_F42028:	jp 0xFDE189  ; -> prom_a 0x5E189
T_F4202C:	jp 0xFDB529  ; -> prom_a 0x5B529
T_F42030:	jp 0xFDE18A  ; -> prom_a 0x5E18A
T_F42034:	jp 0xF0A111  ; -> prom_b 0x0A111
T_F42038:	jp 0xFDE197  ; -> prom_a 0x5E197
T_F4203C:	jp 0xFDB693  ; -> prom_a 0x5B693
T_F42040:	jp 0xFDE198  ; -> prom_a 0x5E198
T_F42044:	jp 0xFD2751  ; -> prom_a 0x52751
T_F42048:	jp 0xFDE1A5  ; -> prom_a 0x5E1A5
T_F4204C:	jp 0xFDB8D9  ; -> prom_a 0x5B8D9
T_F42050:	jp 0xFDE1A6  ; -> prom_a 0x5E1A6
T_F42054:	jp 0xFD27A2  ; -> prom_a 0x527A2
T_F42058:	jp 0xFDE1B3  ; -> prom_a 0x5E1B3
T_F4205C:	jp 0xFDB9AB  ; -> prom_a 0x5B9AB
T_F42060:	jp 0xFDE1B4  ; -> prom_a 0x5E1B4
T_F42064:	jp 0xFD27F2  ; -> prom_a 0x527F2
T_F42068:	jp 0xFDE1DD  ; -> prom_a 0x5E1DD
T_F4206C:	jp 0xFDBAE7  ; -> prom_a 0x5BAE7
T_F42070:	jp 0xFDE1C2  ; -> prom_a 0x5E1C2
T_F42074:	jp 0xFD2852  ; -> prom_a 0x52852
T_F42078:	jp 0xFDE1CF  ; -> prom_a 0x5E1CF
T_F4207C:	jp 0xFDBBC3  ; -> prom_a 0x5BBC3
T_F42080:	jp 0xFDE1D0  ; -> prom_a 0x5E1D0
T_F42084:	jp 0xFD28B2  ; -> prom_a 0x528B2
T_F42088:	jp 0xFDE1DD  ; -> prom_a 0x5E1DD
T_F4208C:	jp 0xFDBBD6  ; -> prom_a 0x5BBD6
T_F42090:	jp 0xFDE1DE  ; -> prom_a 0x5E1DE
T_F42094:	jp 0xFD053D  ; -> prom_a 0x5053D
T_F42098:	jp 0xFDE1EB  ; -> prom_a 0x5E1EB
T_F4209C:	jp 0xFDBEDE  ; -> prom_a 0x5BEDE
T_F420A0:	jp 0xFDE1EC  ; -> prom_a 0x5E1EC
T_F420A4:	jp 0xFD058E  ; -> prom_a 0x5058E
T_F420A8:	jp 0xFDE1F9  ; -> prom_a 0x5E1F9
T_F420AC:	jp 0xFDC0E1  ; -> prom_a 0x5C0E1
T_F420B0:	jp 0xFDE1FA  ; -> prom_a 0x5E1FA
T_F420B4:	jp 0xF0AA61  ; -> prom_b 0x0AA61
T_F420B8:	jp 0xFDE207  ; -> prom_a 0x5E207
T_F420BC:	jp 0xFDC0ED  ; -> prom_a 0x5C0ED
T_F420C0:	jp 0xFDE24E  ; -> prom_a 0x5E24E
T_F420C4:	jp 0xFDE3BE  ; -> prom_a 0x5E3BE
T_F420C8:	jp 0xFDE25B  ; -> prom_a 0x5E25B
T_F420CC:	jp 0xFDC27B  ; -> prom_a 0x5C27B
T_F420D0:	jp 0xFDE25C  ; -> prom_a 0x5E25C
T_F420D4:	jp 0xFDE41E  ; -> prom_a 0x5E41E
T_F420D8:	jp 0xFDE269  ; -> prom_a 0x5E269
T_F420DC:	jp 0xFDC2A7  ; -> prom_a 0x5C2A7
T_F420E0:	jp 0xFDE26A  ; -> prom_a 0x5E26A
T_F420E4:	jp 0xFDE47E  ; -> prom_a 0x5E47E
T_F420E8:	jp 0xFDE277  ; -> prom_a 0x5E277
T_F420EC:	jp 0xFDC2CF  ; -> prom_a 0x5C2CF
T_F420F0:	jp 0xFDE278  ; -> prom_a 0x5E278
T_F420F4:	jp 0xFDE4DE  ; -> prom_a 0x5E4DE
T_F420F8:	jp 0xFDE285  ; -> prom_a 0x5E285
T_F420FC:	jp 0xFDC2F7  ; -> prom_a 0x5C2F7
T_F42100:	jp 0xFDE286  ; -> prom_a 0x5E286
T_F42104:	jp 0xFDE53E  ; -> prom_a 0x5E53E
T_F42108:	jp 0xFDE293  ; -> prom_a 0x5E293
T_F4210C:	jp 0xFDC317  ; -> prom_a 0x5C317
T_F42110:	jp 0xFDE294  ; -> prom_a 0x5E294
T_F42114:	jp 0xFDE59E  ; -> prom_a 0x5E59E
T_F42118:	jp 0xFDE2A1  ; -> prom_a 0x5E2A1
T_F4211C:	jp 0xFDC333  ; -> prom_a 0x5C333
T_F42120:	jp 0xFDE2A2  ; -> prom_a 0x5E2A2
T_F42124:	jp 0xFDE5EF  ; -> prom_a 0x5E5EF
T_F42128:	jp 0xFDE2AF  ; -> prom_a 0x5E2AF
T_F4212C:	jp 0xFDC405  ; -> prom_a 0x5C405
T_F42130:	jp 0xFDE2B0  ; -> prom_a 0x5E2B0
T_F42134:	jp 0xFDE64F  ; -> prom_a 0x5E64F
T_F42138:	jp 0xFDE2BD  ; -> prom_a 0x5E2BD
T_F4213C:	jp 0xFDC4C6  ; -> prom_a 0x5C4C6
T_F42140:	jp 0xFDE2BE  ; -> prom_a 0x5E2BE
T_F42144:	jp 0xFDE6AF  ; -> prom_a 0x5E6AF
T_F42148:	jp 0xFDE2CB  ; -> prom_a 0x5E2CB
T_F4214C:	jp 0xFDC5A2  ; -> prom_a 0x5C5A2
T_F42150:	jp 0xFDE2CC  ; -> prom_a 0x5E2CC
T_F42154:	jp 0xFDE70F  ; -> prom_a 0x5E70F
T_F42158:	jp 0xFDE2D9  ; -> prom_a 0x5E2D9
T_F4215C:	jp 0xFDC5B5  ; -> prom_a 0x5C5B5
T_F42160:	jp 0xFDE208  ; -> prom_a 0x5E208
T_F42164:	jp 0xFD0AA5  ; -> prom_a 0x50AA5
T_F42168:	jp 0xFDE215  ; -> prom_a 0x5E215
T_F4216C:	jp 0xFDC84C  ; -> prom_a 0x5C84C
T_F42170:	jp 0xFDE216  ; -> prom_a 0x5E216
T_F42174:	jp 0xFD0AF6  ; -> prom_a 0x50AF6
T_F42178:	jp 0xFDE223  ; -> prom_a 0x5E223
T_F4217C:	jp 0xFDC95B  ; -> prom_a 0x5C95B
T_F42180:	jp 0xFDE224  ; -> prom_a 0x5E224
T_F42184:	jp 0xFD0B47  ; -> prom_a 0x50B47
T_F42188:	jp 0xFDE231  ; -> prom_a 0x5E231
T_F4218C:	jp 0xFDCA77  ; -> prom_a 0x5CA77
T_F42190:	jp 0xFDE232  ; -> prom_a 0x5E232
T_F42194:	jp 0xFD0BA7  ; -> prom_a 0x50BA7
T_F42198:	jp 0xFDE23F  ; -> prom_a 0x5E23F
T_F4219C:	jp 0xFDCB93  ; -> prom_a 0x5CB93
T_F421A0:	jp 0xFDE240  ; -> prom_a 0x5E240
T_F421A4:	jp 0xFD0C07  ; -> prom_a 0x50C07
T_F421A8:	jp 0xFDE24D  ; -> prom_a 0x5E24D
	.fill 0xA4, 1, 0x0E  ; 0xF421AC: 164 x ret
T_F42250:	.long 0x00FF75B6	; ptr -> 0xFF75B6 (prom_a 0x775B6)
T_F42254:	jp 0xFF42B7  ; -> prom_a 0x742B7
T_F42258:	jp 0xFF42C0  ; -> prom_a 0x742C0
T_F4225C:	jp 0xFF42C5  ; -> prom_a 0x742C5
T_F42260:	jp 0xFF42C9  ; -> prom_a 0x742C9
T_F42264:	jp 0xFF42CD  ; -> prom_a 0x742CD
T_F42268:	jp 0xFF431B  ; -> prom_a 0x7431B
T_F4226C:	jp 0xFF431C  ; -> prom_a 0x7431C
T_F42270:	jp 0xFF4407  ; -> prom_a 0x74407
T_F42274:	jp 0xFF4408  ; -> prom_a 0x74408
T_F42278:	jp 0xFF457C  ; -> prom_a 0x7457C
T_F4227C:	jp 0xFF4596  ; -> prom_a 0x74596
T_F42280:	jp 0xFF475B  ; -> prom_a 0x7475B
	.fill 0x9C, 1, 0x0E  ; 0xF42284: 156 x ret
T_F42320:	jp 0xFDD272  ; -> prom_a 0x5D272
T_F42324:	jp 0xFDE308  ; -> prom_a 0x5E308
T_F42328:	jp 0xF0AAB3  ; -> prom_b 0x0AAB3
T_F4232C:	jp 0xFDE315  ; -> prom_a 0x5E315
T_F42330:	jp 0xFDD27F  ; -> prom_a 0x5D27F
T_F42334:	jp 0xFDE316  ; -> prom_a 0x5E316
T_F42338:	jp 0xF0AAF9  ; -> prom_b 0x0AAF9
T_F4233C:	jp 0xFDE323  ; -> prom_a 0x5E323
T_F42340:	jp 0xFDD436  ; -> prom_a 0x5D436
T_F42344:	jp 0xFDE324  ; -> prom_a 0x5E324
T_F42348:	jp 0xF0AB4A  ; -> prom_b 0x0AB4A
T_F4234C:	jp 0xFDE331  ; -> prom_a 0x5E331
T_F42350:	jp 0xFDD0D4  ; -> prom_a 0x5D0D4
T_F42354:	jp 0xFDE2FA  ; -> prom_a 0x5E2FA
T_F42358:	jp 0xF0A90E  ; -> prom_b 0x0A90E
T_F4235C:	jp 0xFDE307  ; -> prom_a 0x5E307
T_F42360:	jp 0xFDCDE0  ; -> prom_a 0x5CDE0
T_F42364:	jp 0xFDE2DA  ; -> prom_a 0x5E2DA
T_F42368:	jp 0xF0A95F  ; -> prom_b 0x0A95F
T_F4236C:	jp 0xFDE2DB  ; -> prom_a 0x5E2DB
T_F42370:	jp 0xFDCFEB  ; -> prom_a 0x5CFEB
T_F42374:	jp 0xFDE2DC  ; -> prom_a 0x5E2DC
T_F42378:	jp 0xF0A9BF  ; -> prom_b 0x0A9BF
T_F4237C:	jp 0xFDE2DD  ; -> prom_a 0x5E2DD
T_F42380:	jp 0xFD2504  ; -> prom_a 0x52504   x2
	.fill 0x1C, 1, 0x0E  ; 0xF42384: 28 x ret
T_F423A0:	jp 0xFF4786  ; -> prom_a 0x74786
T_F423A4:	jp 0xFF4986  ; -> prom_a 0x74986
T_F423A8:	jp 0xFF4995  ; -> prom_a 0x74995
T_F423AC:	jp 0xFF4FF9  ; -> prom_a 0x74FF9
T_F423B0:	jp 0xFF548A  ; -> prom_a 0x7548A
T_F423B4:	jp 0xFF571F  ; -> prom_a 0x7571F
T_F423B8:	jp 0xFF572E  ; -> prom_a 0x7572E
T_F423BC:	jp 0xFF5C3D  ; -> prom_a 0x75C3D
T_F423C0:	jp 0xFF5C3E  ; -> prom_a 0x75C3E
T_F423C4:	jp 0xFF5EAE  ; -> prom_a 0x75EAE
T_F423C8:	jp 0xFF5ED1  ; -> prom_a 0x75ED1
T_F423CC:	jp 0xFF6511  ; -> prom_a 0x76511
T_F423D0:	jp 0xFF6512  ; -> prom_a 0x76512
T_F423D4:	jp 0xFF654F  ; -> prom_a 0x7654F
T_F423D8:	jp 0xFF6550  ; -> prom_a 0x76550
T_F423DC:	jp 0xFF6612  ; -> prom_a 0x76612
T_F423E0:	jp 0xFF672D  ; -> prom_a 0x7672D
T_F423E4:	jp 0xFF68CA  ; -> prom_a 0x768CA
T_F423E8:	jp 0xFF68D8  ; -> prom_a 0x768D8
T_F423EC:	jp 0xFF6DB6  ; -> prom_a 0x76DB6
T_F423F0:	jp 0xFF6613  ; -> prom_a 0x76613
T_F423F4:	jp 0xFF66A9  ; -> prom_a 0x766A9
T_F423F8:	jp 0xFF66AA  ; -> prom_a 0x766AA
T_F423FC:	jp 0xFF672C  ; -> prom_a 0x7672C
T_F42400:	jp 0xFF4FFA  ; -> prom_a 0x74FFA
T_F42404:	jp 0xFF520C  ; -> prom_a 0x7520C
T_F42408:	jp 0xFF522F  ; -> prom_a 0x7522F
T_F4240C:	jp 0xFF5489  ; -> prom_a 0x75489
T_F42410:	jp 0xFF70B6  ; -> prom_a 0x770B6   x1
T_F42414:	jp 0xFF70D8  ; -> prom_a 0x770D8   x1
T_F42418:	jp 0xFF48F0  ; -> prom_a 0x748F0   x1
T_F4241C:	jp 0xFF6DB7  ; -> prom_a 0x76DB7
T_F42420:	jp 0xFF6F13  ; -> prom_a 0x76F13
T_F42424:	jp 0xFF6F21  ; -> prom_a 0x76F21
T_F42428:	jp 0xFF7083  ; -> prom_a 0x77083
	.fill 0x44, 1, 0x0E  ; 0xF4242C: 68 x ret
T_F42470:	jp 0xFC0450  ; -> prom_a 0x40450
T_F42474:	jp 0xFC0460  ; -> prom_a 0x40460
T_F42478:	jp 0xFC0470  ; -> prom_a 0x40470
T_F4247C:	jp 0xFC0480  ; -> prom_a 0x40480
T_F42480:	jp 0xFC0490  ; -> prom_a 0x40490
T_F42484:	jp 0xFC04A0  ; -> prom_a 0x404A0
T_F42488:	jp 0xFC04B0  ; -> prom_a 0x404B0
T_F4248C:	jp 0xFC04C0  ; -> prom_a 0x404C0
T_F42490:	jp 0xFC04D0  ; -> prom_a 0x404D0
T_F42494:	jp 0xFC04E0  ; -> prom_a 0x404E0
T_F42498:	jp 0xFC04F0  ; -> prom_a 0x404F0
T_F4249C:	jp 0xFC0500  ; -> prom_a 0x40500
T_F424A0:	jp 0xFC0510  ; -> prom_a 0x40510
T_F424A4:	jp 0xFC0520  ; -> prom_a 0x40520
T_F424A8:	jp 0xFC0530  ; -> prom_a 0x40530
T_F424AC:	jp 0xFC0540  ; -> prom_a 0x40540
T_F424B0:	jp 0xFC0551  ; -> prom_a 0x40551
T_F424B4:	jp 0xFC0561  ; -> prom_a 0x40561
T_F424B8:	jp 0xFC0571  ; -> prom_a 0x40571
T_F424BC:	jp 0xFC0581  ; -> prom_a 0x40581
T_F424C0:	jp 0xFC0591  ; -> prom_a 0x40591
T_F424C4:	jp 0xFC05A1  ; -> prom_a 0x405A1
T_F424C8:	jp 0xFC05B1  ; -> prom_a 0x405B1
T_F424CC:	jp 0xFC05C1  ; -> prom_a 0x405C1
T_F424D0:	jp 0xFC05D1  ; -> prom_a 0x405D1
T_F424D4:	jp 0xFC05E1  ; -> prom_a 0x405E1
T_F424D8:	jp 0xFC05F1  ; -> prom_a 0x405F1
T_F424DC:	jp 0xFC0601  ; -> prom_a 0x40601
T_F424E0:	jp 0xFC0611  ; -> prom_a 0x40611
T_F424E4:	jp 0xFC0621  ; -> prom_a 0x40621
T_F424E8:	jp 0xFC0631  ; -> prom_a 0x40631
T_F424EC:	jp 0xFC0641  ; -> prom_a 0x40641
T_F424F0:	jp 0xFC06F4  ; -> prom_a 0x406F4
T_F424F4:	jp 0xFC06FF  ; -> prom_a 0x406FF
T_F424F8:	jp 0xFC0724  ; -> prom_a 0x40724
T_F424FC:	jp 0xFC0749  ; -> prom_a 0x40749
T_F42500:	jp 0xFC075E  ; -> prom_a 0x4075E
T_F42504:	jp 0xFC078A  ; -> prom_a 0x4078A
T_F42508:	jp 0xFC07AF  ; -> prom_a 0x407AF
T_F4250C:	jp 0xFC07B0  ; -> prom_a 0x407B0
T_F42510:	jp 0xFC07B1  ; -> prom_a 0x407B1
T_F42514:	jp 0xFC07D6  ; -> prom_a 0x407D6
T_F42518:	jp 0xFC07FB  ; -> prom_a 0x407FB
T_F4251C:	jp 0xFC0820  ; -> prom_a 0x40820
T_F42520:	jp 0xFC0845  ; -> prom_a 0x40845
T_F42524:	jp 0xFC086A  ; -> prom_a 0x4086A
	.fill 0x48, 1, 0x0E  ; 0xF42528: 72 x ret
T_F42570:	.long 0x00FE0000	; ptr -> 0xFE0000 (prom_a 0x60000)
T_F42574:	jp 0xFE1BCE  ; -> prom_a 0x61BCE   x8
T_F42578:	jp 0xFE1BDE  ; -> prom_a 0x61BDE   x8
T_F4257C:	jp 0xFE152E  ; -> prom_a 0x6152E   x5
T_F42580:	jp 0xFE1C16  ; -> prom_a 0x61C16   x6
T_F42584:	jp 0xFE144E  ; -> prom_a 0x6144E   x1
T_F42588:	jp 0xFE1C17  ; -> prom_a 0x61C17
T_F4258C:	jp 0xFE1C1E  ; -> prom_a 0x61C1E
T_F42590:	jp 0xFE1C1F  ; -> prom_a 0x61C1F   x4
T_F42594:	jp 0xFE1C23  ; -> prom_a 0x61C23   x15
T_F42598:	jp 0xFE1C27  ; -> prom_a 0x61C27
T_F4259C:	jp 0xFE1C2B  ; -> prom_a 0x61C2B
T_F425A0:	jp 0xFE1C2F  ; -> prom_a 0x61C2F
T_F425A4:	jp 0xFE1C33  ; -> prom_a 0x61C33
T_F425A8:	jp 0xFE1C3A  ; -> prom_a 0x61C3A   x11
T_F425AC:	jp 0xFE1C4D  ; -> prom_a 0x61C4D   x14
T_F425B0:	jp 0xFE1C55  ; -> prom_a 0x61C55   x11
T_F425B4:	jp 0xFE1C5D  ; -> prom_a 0x61C5D   x3
T_F425B8:	jp 0xFE1C67  ; -> prom_a 0x61C67   x2
T_F425BC:	jp 0xFE1BCA  ; -> prom_a 0x61BCA
T_F425C0:	jp 0xFE1C71  ; -> prom_a 0x61C71
T_F425C4:	jp 0xFE1C75  ; -> prom_a 0x61C75   x1
T_F425C8:	jp 0xFE1C79  ; -> prom_a 0x61C79   x3
T_F425CC:	jp 0xFE1C80  ; -> prom_a 0x61C80   x3
T_F425D0:	jp 0xFE1C98  ; -> prom_a 0x61C98   x1
T_F425D4:	jp 0xFE1C9F  ; -> prom_a 0x61C9F   x2
T_F425D8:	jp 0xFE1CA3  ; -> prom_a 0x61CA3   x3
T_F425DC:	jp 0xFE1CA7  ; -> prom_a 0x61CA7   x3
T_F425E0:	jp 0xFE1CAB  ; -> prom_a 0x61CAB
T_F425E4:	jp 0xFE1CAF  ; -> prom_a 0x61CAF   x5
T_F425E8:	jp 0xFE1CB3  ; -> prom_a 0x61CB3   x5
T_F425EC:	jp 0xFE1CC0  ; -> prom_a 0x61CC0
T_F425F0:	jp 0xFE1CC4  ; -> prom_a 0x61CC4   x1
T_F425F4:	jp 0xFE1CC8  ; -> prom_a 0x61CC8   x1
T_F425F8:	jp 0xFE1CCC  ; -> prom_a 0x61CCC   x3
T_F425FC:	jp 0xFE1CD0  ; -> prom_a 0x61CD0
T_F42600:	jp 0xFE1CD4  ; -> prom_a 0x61CD4   x2
T_F42604:	jp 0xFE1CD8  ; -> prom_a 0x61CD8   x8
T_F42608:	jp 0xFE1CDC  ; -> prom_a 0x61CDC   x1
T_F4260C:	jp 0xFE1CE0  ; -> prom_a 0x61CE0   x1
T_F42610:	jp 0xFE1CE4  ; -> prom_a 0x61CE4   x1
T_F42614:	jp 0xFE1C0B  ; -> prom_a 0x61C0B   x5
T_F42618:	jp 0xFE04BE  ; -> prom_a 0x604BE   x2
T_F4261C:	jp 0xFE0391  ; -> prom_a 0x60391   x26
T_F42620:	jp 0xFE0435  ; -> prom_a 0x60435   x2
T_F42624:	jp 0xFE1BEB  ; -> prom_a 0x61BEB   x1
T_F42628:	jp 0xFE1BF3  ; -> prom_a 0x61BF3   x1
T_F4262C:	jp 0xFE1BFB  ; -> prom_a 0x61BFB   x1
T_F42630:	jp 0xFE1C03  ; -> prom_a 0x61C03
T_F42634:	jp 0xFE1C59  ; -> prom_a 0x61C59   x1
	.fill 0x28, 1, 0x0E  ; 0xF42638: 40 x ret
T_F42660:	jp 0xF38800  ; -> prom_b 0x38800   x1
T_F42664:	jp 0xF38843  ; -> prom_b 0x38843   x1
	.fill 0x8, 1, 0x0E  ; 0xF42668: 8 x ret
T_F42670:	jp 0xFA129D  ; -> prom_a 0x2129D
T_F42674:	jp 0xFA12CE  ; -> prom_a 0x212CE
T_F42678:	jp 0xFA12DD  ; -> prom_a 0x212DD
T_F4267C:	jp 0xFA1304  ; -> prom_a 0x21304
T_F42680:	jp 0xF9CB00  ; -> prom_a 0x1CB00
T_F42684:	jp 0xF9CB52  ; -> prom_a 0x1CB52
T_F42688:	jp 0xF9CB53  ; -> prom_a 0x1CB53
T_F4268C:	jp 0xF9CB7A  ; -> prom_a 0x1CB7A
T_F42690:	jp 0xF9CF68  ; -> prom_a 0x1CF68
T_F42694:	jp 0xF9CFBA  ; -> prom_a 0x1CFBA
T_F42698:	jp 0xF9CFBB  ; -> prom_a 0x1CFBB
T_F4269C:	jp 0xF9CFE2  ; -> prom_a 0x1CFE2
T_F426A0:	jp 0xF9D3BA  ; -> prom_a 0x1D3BA
T_F426A4:	jp 0xF9D3F4  ; -> prom_a 0x1D3F4
T_F426A8:	jp 0xF9D404  ; -> prom_a 0x1D404
T_F426AC:	jp 0xF9D432  ; -> prom_a 0x1D432
T_F426B0:	jp 0xF9DF91  ; -> prom_a 0x1DF91
T_F426B4:	jp 0xF9DFCB  ; -> prom_a 0x1DFCB
T_F426B8:	jp 0xF9DFCC  ; -> prom_a 0x1DFCC
T_F426BC:	jp 0xF9DFF3  ; -> prom_a 0x1DFF3
	.fill 0x20, 1, 0x0E  ; 0xF426C0: 32 x ret
T_F426E0:	jp 0xF608D0  ; -> prom_b 0x608D0   x3
T_F426E4:	jp 0xF6079A  ; -> prom_b 0x6079A   x2
T_F426E8:	jp 0xF60012  ; -> prom_b 0x60012   x1
T_F426EC:	jp 0xF5E3DA  ; -> prom_b 0x5E3DA   x1
T_F426F0:	jp 0xF5E708  ; -> prom_b 0x5E708   x1
T_F426F4:	jp 0xF5EC12  ; -> prom_b 0x5EC12   x2
T_F426F8:	jp 0xF5F221  ; -> prom_b 0x5F221   x2
T_F426FC:	jp 0xF60598  ; -> prom_b 0x60598   x1
T_F42700:	jp 0xF5DAA2  ; -> prom_b 0x5DAA2   x1
T_F42704:	jp 0xF60B22  ; -> prom_b 0x60B22   x6
T_F42708:	jp 0xF60B0C  ; -> prom_b 0x60B0C   x6
T_F4270C:	jp 0xF5EBD0  ; -> prom_b 0x5EBD0   x25
T_F42710:	jp 0xF5EC0E  ; -> prom_b 0x5EC0E   x7
T_F42714:	jp 0xF60B4E  ; -> prom_b 0x60B4E   x1
T_F42718:	jp 0xF60D3E  ; -> prom_b 0x60D3E   x1
T_F4271C:	jp 0xF6119A  ; -> prom_b 0x6119A   x1
T_F42720:	jp 0xF61A16  ; -> prom_b 0x61A16   x1
	.fill 0x4C, 1, 0x0E  ; 0xF42724: 76 x ret
T_F42770:	jp 0xF62C7E  ; -> prom_b 0x62C7E   x11
T_F42774:	jp 0xF62CFE  ; -> prom_b 0x62CFE   x29
T_F42778:	jp 0xF62DC9  ; -> prom_b 0x62DC9   x8
T_F4277C:	jp 0xF6306A  ; -> prom_b 0x6306A   x13
T_F42780:	jp 0xF63317  ; -> prom_b 0x63317   x4
T_F42784:	jp 0xF63383  ; -> prom_b 0x63383   x6
T_F42788:	jp 0xF633F5  ; -> prom_b 0x633F5
T_F4278C:	jp 0xF6342C  ; -> prom_b 0x6342C   x5
T_F42790:	jp 0xF63489  ; -> prom_b 0x63489   x8
T_F42794:	jp 0xF63510  ; -> prom_b 0x63510   x10
T_F42798:	jp 0xF6353E  ; -> prom_b 0x6353E   x7
T_F4279C:	jp 0xF635C9  ; -> prom_b 0x635C9   x43
T_F427A0:	jp 0xF6360E  ; -> prom_b 0x6360E   x16
T_F427A4:	jp 0xF6364D  ; -> prom_b 0x6364D   x1
T_F427A8:	jp 0xF63749  ; -> prom_b 0x63749   x10
T_F427AC:	jp 0xF638BB  ; -> prom_b 0x638BB   x3
T_F427B0:	jp 0xF63924  ; -> prom_b 0x63924   x20
T_F427B4:	jp 0xF63988  ; -> prom_b 0x63988   x8
T_F427B8:	jp 0xF63A59  ; -> prom_b 0x63A59   x1
T_F427BC:	jp 0xF63BAE  ; -> prom_b 0x63BAE   x42
T_F427C0:	jp 0xF63BC0  ; -> prom_b 0x63BC0   x12
T_F427C4:	jp 0xF63BE5  ; -> prom_b 0x63BE5   x13
T_F427C8:	jp 0xF63C02  ; -> prom_b 0x63C02
T_F427CC:	jp 0xF63C41  ; -> prom_b 0x63C41
T_F427D0:	jp 0xF6452B  ; -> prom_b 0x6452B   x2
T_F427D4:	jp 0xF64594  ; -> prom_b 0x64594   x1
T_F427D8:	jp 0xF6466E  ; -> prom_b 0x6466E   x1
T_F427DC:	jp 0xF647DD  ; -> prom_b 0x647DD
T_F427E0:	jp 0xF64838  ; -> prom_b 0x64838
T_F427E4:	jp 0xF62C08  ; -> prom_b 0x62C08   x9
T_F427E8:	jp 0xF62C0C  ; -> prom_b 0x62C0C   x3
T_F427EC:	jp 0xF62C10  ; -> prom_b 0x62C10   x4
T_F427F0:	jp 0xF62C14  ; -> prom_b 0x62C14   x3
T_F427F4:	jp 0xF62C18  ; -> prom_b 0x62C18   x3
T_F427F8:	jp 0xF62C1C  ; -> prom_b 0x62C1C   x4
T_F427FC:	jp 0xF62C20  ; -> prom_b 0x62C20   x6
T_F42800:	jp 0xF62C00  ; -> prom_b 0x62C00   x2
T_F42804:	jp 0xF6418E  ; -> prom_b 0x6418E   x1
T_F42808:	jp 0xF6487D  ; -> prom_b 0x6487D   x1
T_F4280C:	jp 0xF63C06  ; -> prom_b 0x63C06   x1
T_F42810:	jp 0xF633FF  ; -> prom_b 0x633FF   x1
T_F42814:	jp 0xF63408  ; -> prom_b 0x63408   x1
T_F42818:	jp 0xF63411  ; -> prom_b 0x63411   x1
T_F4281C:	jp 0xF6341A  ; -> prom_b 0x6341A   x1
T_F42820:	jp 0xF63423  ; -> prom_b 0x63423   x1
T_F42824:	jp 0xF64A7A  ; -> prom_b 0x64A7A   x1
T_F42828:	jp 0xF62C05  ; -> prom_b 0x62C05
T_F4282C:	jp 0xF64B1B  ; -> prom_b 0x64B1B   x1
T_F42830:	jp 0xF64BB6  ; -> prom_b 0x64BB6   x1
	.fill 0x4C, 1, 0x0E  ; 0xF42834: 76 x ret
T_F42880:	jp 0xF7A400  ; -> prom_b 0x7A400   x2
T_F42884:	jp 0xF7A402  ; -> prom_b 0x7A402   x17
T_F42888:	jp 0xF7A404  ; -> prom_b 0x7A404   x7
T_F4288C:	jp 0xF7A406  ; -> prom_b 0x7A406
T_F42890:	jp 0xF7A408  ; -> prom_b 0x7A408   x1
T_F42894:	jp 0xF7A613  ; -> prom_b 0x7A613   x8
	.fill 0x18, 1, 0x0E  ; 0xF42898: 24 x ret
T_F428B0:	jp 0xF7AA00  ; -> prom_b 0x7AA00   x1
T_F428B4:	jp 0xF7AA02  ; -> prom_b 0x7AA02   x1
T_F428B8:	jp 0xF7AA29  ; -> prom_b 0x7AA29   x1
T_F428BC:	jp 0xF7AA88  ; -> prom_b 0x7AA88   x1
T_F428C0:	jp 0xF7AA89  ; -> prom_b 0x7AA89   x1
T_F428C4:	jp 0xF7AAAF  ; -> prom_b 0x7AAAF   x1
T_F428C8:	jp 0xF7AADD  ; -> prom_b 0x7AADD   x1
T_F428CC:	jp 0xF7AAF0  ; -> prom_b 0x7AAF0   x1
T_F428D0:	jp 0xF7AB9C  ; -> prom_b 0x7AB9C   x1
T_F428D4:	jp 0xF7ABB9  ; -> prom_b 0x7ABB9   x1
T_F428D8:	jp 0xF7ABDC  ; -> prom_b 0x7ABDC   x2
T_F428DC:	jp 0xF7AC07  ; -> prom_b 0x7AC07   x2
T_F428E0:	jp 0xF7BCFD  ; -> prom_b 0x7BCFD   x1
T_F428E4:	jp 0xF7BD24  ; -> prom_b 0x7BD24   x1
T_F428E8:	jp 0xF7BD30  ; -> prom_b 0x7BD30   x1
T_F428EC:	jp 0xF7BD40  ; -> prom_b 0x7BD40   x1
T_F428F0:	jp 0xF7BD55  ; -> prom_b 0x7BD55   x1
T_F428F4:	jp 0xF7BD6A  ; -> prom_b 0x7BD6A   x1
T_F428F8:	jp 0xF7BD7F  ; -> prom_b 0x7BD7F   x4
T_F428FC:	jp 0xF7BDD4  ; -> prom_b 0x7BDD4   x2
T_F42900:	jp 0xF7BEF4  ; -> prom_b 0x7BEF4   x2
T_F42904:	jp 0xF7BDC0  ; -> prom_b 0x7BDC0
T_F42908:	jp 0xF7BFEA  ; -> prom_b 0x7BFEA   x1
T_F4290C:	jp 0xF7C0AF  ; -> prom_b 0x7C0AF   x1
T_F42910:	jp 0xF7C0BB  ; -> prom_b 0x7C0BB   x1
T_F42914:	jp 0xF7C0C6  ; -> prom_b 0x7C0C6   x1
T_F42918:	jp 0xF7C0D6  ; -> prom_b 0x7C0D6   x1
T_F4291C:	jp 0xF7C0E6  ; -> prom_b 0x7C0E6   x1
T_F42920:	jp 0xF7C310  ; -> prom_b 0x7C310   x1
T_F42924:	jp 0xF7C31B  ; -> prom_b 0x7C31B   x1
T_F42928:	jp 0xF7C0F1  ; -> prom_b 0x7C0F1   x4
T_F4292C:	jp 0xF7C17D  ; -> prom_b 0x7C17D   x2
T_F42930:	jp 0xF7C326  ; -> prom_b 0x7C326   x2
T_F42934:	jp 0xF7C13E  ; -> prom_b 0x7C13E
T_F42938:	jp 0xF7AC9D  ; -> prom_b 0x7AC9D   x1
T_F4293C:	jp 0xF7ACA6  ; -> prom_b 0x7ACA6   x1
T_F42940:	jp 0xF7ACC5  ; -> prom_b 0x7ACC5   x1
T_F42944:	jp 0xF7ACD0  ; -> prom_b 0x7ACD0   x1
T_F42948:	jp 0xF7ACDB  ; -> prom_b 0x7ACDB   x1
T_F4294C:	jp 0xF7ACE6  ; -> prom_b 0x7ACE6   x1
T_F42950:	jp 0xF7AD14  ; -> prom_b 0x7AD14   x1
T_F42954:	jp 0xF7ADF5  ; -> prom_b 0x7ADF5   x2
T_F42958:	jp 0xF7AE0C  ; -> prom_b 0x7AE0C   x2
T_F4295C:	jp 0xF7B000  ; -> prom_b 0x7B000   x1
T_F42960:	jp 0xF7B00E  ; -> prom_b 0x7B00E   x1
T_F42964:	jp 0xF7B01A  ; -> prom_b 0x7B01A   x1
T_F42968:	jp 0xF7B025  ; -> prom_b 0x7B025   x1
T_F4296C:	jp 0xF7B035  ; -> prom_b 0x7B035   x1
T_F42970:	jp 0xF7B045  ; -> prom_b 0x7B045   x4
T_F42974:	jp 0xF7B08B  ; -> prom_b 0x7B08B   x2
T_F42978:	jp 0xF7B162  ; -> prom_b 0x7B162   x2
T_F4297C:	jp 0xF7B07A  ; -> prom_b 0x7B07A
T_F42980:	jp 0xF7B22C  ; -> prom_b 0x7B22C   x1
T_F42984:	jp 0xF7B23A  ; -> prom_b 0x7B23A   x1
T_F42988:	jp 0xF7B246  ; -> prom_b 0x7B246   x1
T_F4298C:	jp 0xF7B251  ; -> prom_b 0x7B251   x1
T_F42990:	jp 0xF7B261  ; -> prom_b 0x7B261   x1
T_F42994:	jp 0xF7B271  ; -> prom_b 0x7B271   x1
T_F42998:	jp 0xF7B27C  ; -> prom_b 0x7B27C   x4
T_F4299C:	jp 0xF7B2CE  ; -> prom_b 0x7B2CE   x2
T_F429A0:	jp 0xF7B3E0  ; -> prom_b 0x7B3E0   x2
T_F429A4:	jp 0xF7B2BD  ; -> prom_b 0x7B2BD
T_F429A8:	jp 0xF7B4BF  ; -> prom_b 0x7B4BF   x1
T_F429AC:	jp 0xF7B4CD  ; -> prom_b 0x7B4CD   x1
T_F429B0:	jp 0xF7B4EC  ; -> prom_b 0x7B4EC   x1
T_F429B4:	jp 0xF7B4F7  ; -> prom_b 0x7B4F7   x1
T_F429B8:	jp 0xF7B507  ; -> prom_b 0x7B507   x1
T_F429BC:	jp 0xF7B517  ; -> prom_b 0x7B517   x1
T_F429C0:	jp 0xF7B522  ; -> prom_b 0x7B522   x1
T_F429C4:	jp 0xF7B532  ; -> prom_b 0x7B532   x1
T_F429C8:	jp 0xF7B53D  ; -> prom_b 0x7B53D   x2
T_F429CC:	jp 0xF7B58C  ; -> prom_b 0x7B58C   x2
T_F429D0:	jp 0xF7B761  ; -> prom_b 0x7B761   x2
T_F429D4:	jp 0xF7B771  ; -> prom_b 0x7B771   x2
T_F429D8:	jp 0xF7B8DC  ; -> prom_b 0x7B8DC   x1
T_F429DC:	jp 0xF7B8EA  ; -> prom_b 0x7B8EA   x1
T_F429E0:	jp 0xF7B909  ; -> prom_b 0x7B909   x1
T_F429E4:	jp 0xF7B914  ; -> prom_b 0x7B914   x1
T_F429E8:	jp 0xF7B924  ; -> prom_b 0x7B924   x1
T_F429EC:	jp 0xF7B934  ; -> prom_b 0x7B934   x1
T_F429F0:	jp 0xF7B93F  ; -> prom_b 0x7B93F   x1
T_F429F4:	jp 0xF7B94F  ; -> prom_b 0x7B94F   x1
T_F429F8:	jp 0xF7B95A  ; -> prom_b 0x7B95A   x2
T_F429FC:	jp 0xF7B9AB  ; -> prom_b 0x7B9AB   x2
T_F42A00:	jp 0xF7BB82  ; -> prom_b 0x7BB82   x2
T_F42A04:	jp 0xF7BB92  ; -> prom_b 0x7BB92   x2
T_F42A08:	jp 0xF7C3B2  ; -> prom_b 0x7C3B2   x1
T_F42A0C:	jp 0xF7C3EE  ; -> prom_b 0x7C3EE
T_F42A10:	jp 0xF7C41D  ; -> prom_b 0x7C41D   x1
T_F42A14:	jp 0xF7C3FA  ; -> prom_b 0x7C3FA   x1
T_F42A18:	jp 0xF7C48C  ; -> prom_b 0x7C48C   x1
T_F42A1C:	jp 0xF7C463  ; -> prom_b 0x7C463   x1
T_F42A20:	jp 0xF7C4DC  ; -> prom_b 0x7C4DC   x1
T_F42A24:	jp 0xF7C4B9  ; -> prom_b 0x7C4B9   x1
T_F42A28:	jp 0xF7C528  ; -> prom_b 0x7C528   x1
T_F42A2C:	jp 0xF7C4FF  ; -> prom_b 0x7C4FF   x1
T_F42A30:	jp 0xF7C555  ; -> prom_b 0x7C555   x2
T_F42A34:	jp 0xF7C5C0  ; -> prom_b 0x7C5C0   x2
T_F42A38:	jp 0xF7C606  ; -> prom_b 0x7C606   x1
T_F42A3C:	jp 0xF7C666  ; -> prom_b 0x7C666   x1
T_F42A40:	jp 0xF7C672  ; -> prom_b 0x7C672   x1
T_F42A44:	jp 0xF7C682  ; -> prom_b 0x7C682   x1
T_F42A48:	jp 0xF7C692  ; -> prom_b 0x7C692   x1
T_F42A4C:	jp 0xF7C6A2  ; -> prom_b 0x7C6A2   x1
T_F42A50:	jp 0xF7C6B2  ; -> prom_b 0x7C6B2   x2
T_F42A54:	jp 0xF7C6FB  ; -> prom_b 0x7C6FB   x2
T_F42A58:	jp 0xF7C7F0  ; -> prom_b 0x7C7F0   x2
T_F42A5C:	jp 0xF7C843  ; -> prom_b 0x7C843   x2
T_F42A60:	jp 0xF7CAD2  ; -> prom_b 0x7CAD2   x1
T_F42A64:	jp 0xF7CB12  ; -> prom_b 0x7CB12   x1
T_F42A68:	jp 0xF7CB1E  ; -> prom_b 0x7CB1E   x1
T_F42A6C:	jp 0xF7CB29  ; -> prom_b 0x7CB29   x1
T_F42A70:	jp 0xF7CB34  ; -> prom_b 0x7CB34   x1
T_F42A74:	jp 0xF7CB3F  ; -> prom_b 0x7CB3F   x1
T_F42A78:	jp 0xF7CB4A  ; -> prom_b 0x7CB4A   x2
T_F42A7C:	jp 0xF7CB90  ; -> prom_b 0x7CB90   x2
T_F42A80:	jp 0xF7CC7C  ; -> prom_b 0x7CC7C   x2
T_F42A84:	jp 0xF7CCCA  ; -> prom_b 0x7CCCA   x2
T_F42A88:	jp 0xF7C853  ; -> prom_b 0x7C853   x1
T_F42A8C:	jp 0xF7C8BC  ; -> prom_b 0x7C8BC   x1
T_F42A90:	jp 0xF7C8C8  ; -> prom_b 0x7C8C8   x1
T_F42A94:	jp 0xF7C8D8  ; -> prom_b 0x7C8D8   x1
T_F42A98:	jp 0xF7C8E8  ; -> prom_b 0x7C8E8   x1
T_F42A9C:	jp 0xF7C8F8  ; -> prom_b 0x7C8F8   x1
T_F42AA0:	jp 0xF7C908  ; -> prom_b 0x7C908   x1
T_F42AA4:	jp 0xF7C918  ; -> prom_b 0x7C918   x2
T_F42AA8:	jp 0xF7C964  ; -> prom_b 0x7C964   x2
T_F42AAC:	jp 0xF7CA6F  ; -> prom_b 0x7CA6F   x2
T_F42AB0:	jp 0xF7CAC2  ; -> prom_b 0x7CAC2   x2
T_F42AB4:	jp 0xF7C5CB  ; -> prom_b 0x7C5CB   x1
T_F42AB8:	jp 0xF7C5EA  ; -> prom_b 0x7C5EA
T_F42ABC:	jp 0xF7C5F6  ; -> prom_b 0x7C5F6   x1
	.fill 0x2C, 1, 0x00  ; 0xF42AC0: 44 x nop
	.fill 0x84, 1, 0x0E  ; 0xF42AEC: 132 x ret
T_F42B70:	jp 0xF65C51  ; -> prom_b 0x65C51   x1
T_F42B74:	jp 0xF6609C  ; -> prom_b 0x6609C
T_F42B78:	jp 0xF660EC  ; -> prom_b 0x660EC
T_F42B7C:	jp 0xF66246  ; -> prom_b 0x66246   x2
T_F42B80:	jp 0xF66251  ; -> prom_b 0x66251   x1
T_F42B84:	jp 0xF6625C  ; -> prom_b 0x6625C   x1
T_F42B88:	jp 0xF66278  ; -> prom_b 0x66278   x1
T_F42B8C:	jp 0xF65C5E  ; -> prom_b 0x65C5E   x1
T_F42B90:	jp 0xF65C9A  ; -> prom_b 0x65C9A   x1
T_F42B94:	jp 0xF65CD6  ; -> prom_b 0x65CD6   x2
T_F42B98:	jp 0xF65DAE  ; -> prom_b 0x65DAE   x1
T_F42B9C:	jp 0xF65DD3  ; -> prom_b 0x65DD3   x2
T_F42BA0:	jp 0xF65DF8  ; -> prom_b 0x65DF8   x1
T_F42BA4:	jp 0xF65E94  ; -> prom_b 0x65E94   x1
T_F42BA8:	jp 0xF65F7C  ; -> prom_b 0x65F7C   x1
T_F42BAC:	jp 0xF65FDD  ; -> prom_b 0x65FDD   x1
T_F42BB0:	jp 0xF66020  ; -> prom_b 0x66020   x1
T_F42BB4:	jp 0xF65C00  ; -> prom_b 0x65C00   x1
T_F42BB8:	jp 0xF65C0D  ; -> prom_b 0x65C0D   x1
T_F42BBC:	jp 0xF664AE  ; -> prom_b 0x664AE   x8
T_F42BC0:	jp 0xF66081  ; -> prom_b 0x66081   x2
T_F42BC4:	jp 0xF664D5  ; -> prom_b 0x664D5   x1
T_F42BC8:	jp 0xF6650F  ; -> prom_b 0x6650F   x1
T_F42BCC:	jp 0xF660ED  ; -> prom_b 0x660ED   x1
T_F42BD0:	jp 0xF6614E  ; -> prom_b 0x6614E   x1
T_F42BD4:	jp 0xF66191  ; -> prom_b 0x66191   x1
T_F42BD8:	jp 0xF66201  ; -> prom_b 0x66201   x1
T_F42BDC:	jp 0xF66522  ; -> prom_b 0x66522
T_F42BE0:	jp 0xF6656D  ; -> prom_b 0x6656D
T_F42BE4:	jp 0xF6652C  ; -> prom_b 0x6652C   x1
T_F42BE8:	jp 0xF6655D  ; -> prom_b 0x6655D   x1
T_F42BEC:	jp 0xF6657A  ; -> prom_b 0x6657A   x1
T_F42BF0:	jp 0xF66598  ; -> prom_b 0x66598
T_F42BF4:	jp 0xF6656E  ; -> prom_b 0x6656E   x1
T_F42BF8:	jp 0xF665B4  ; -> prom_b 0x665B4   x1
T_F42BFC:	jp 0xF665F1  ; -> prom_b 0x665F1
T_F42C00:	jp 0xF665F2  ; -> prom_b 0x665F2   x1
T_F42C04:	jp 0xF665FF  ; -> prom_b 0x665FF   x1
T_F42C08:	jp 0xF6660C  ; -> prom_b 0x6660C   x1
T_F42C0C:	jp 0xF66619  ; -> prom_b 0x66619   x1
T_F42C10:	jp 0xF66639  ; -> prom_b 0x66639   x1
T_F42C14:	jp 0xF66658  ; -> prom_b 0x66658   x1
T_F42C18:	jp 0xF6633A  ; -> prom_b 0x6633A   x2
T_F42C1C:	jp 0xF66382  ; -> prom_b 0x66382   x1
T_F42C20:	jp 0xF663D6  ; -> prom_b 0x663D6
T_F42C24:	jp 0xF66415  ; -> prom_b 0x66415   x1
T_F42C28:	jp 0xF663D7  ; -> prom_b 0x663D7   x1
T_F42C2C:	jp 0xF6645A  ; -> prom_b 0x6645A   x1
	.fill 0x40, 1, 0x0E  ; 0xF42C30: 64 x ret
T_F42C70:	jp 0xF55018  ; -> prom_b 0x55018   never CALLED, but the 4 bytes
				; `70 2C F4 00` occur 397 times in prom_a+prom_b
				; -- 222 in prom_a, 175 in prom_b -- so it is a
				; DEFAULT entry filling pointer tables.
				; ⚠ CORRECTED 2026-08-25: this used to add "222 of
				; them in one dense run at prom_a 0x216B4".  222 is
				; prom_a's TOTAL; 0x216B4 is only its first
				; occurrence.  The longest stride-4 run is 10 in
				; prom_a and 17 in prom_b, and the run at 0x216B4
				; is 6 (notes/prom_b_default_slot_census.py).
				; Which tables these are has not been traced.
T_F42C74:	jp 0xF55019  ; -> prom_b 0x55019   x28
T_F42C78:	jp 0xF550A6  ; -> prom_b 0x550A6   x77
T_F42C7C:	jp 0xF5517B  ; -> prom_b 0x5517B   x8
T_F42C80:	jp 0xF55231  ; -> prom_b 0x55231   x31
T_F42C84:	jp 0xF5527E  ; -> prom_b 0x5527E   x13
T_F42C88:	jp 0xF552CC  ; -> prom_b 0x552CC   x4
T_F42C8C:	jp 0xF55321  ; -> prom_b 0x55321   x45
T_F42C90:	jp 0xF5533C  ; -> prom_b 0x5533C   x119
T_F42C94:	jp 0xF5535B  ; -> prom_b 0x5535B   x23
T_F42C98:	jp 0xF5547B  ; -> prom_b 0x5547B   x35
T_F42C9C:	jp 0xF556D2  ; -> prom_b 0x556D2   x13
T_F42CA0:	jp 0xF556EA  ; -> prom_b 0x556EA   x5
T_F42CA4:	jp 0xF551E7  ; -> prom_b 0x551E7
T_F42CA8:	jp 0xF5553F  ; -> prom_b 0x5553F   x15
	.fill 0x74, 1, 0x0E  ; 0xF42CAC: 116 x ret
T_F42D20:	jp 0xFE3000  ; -> prom_a 0x63000
T_F42D24:	jp 0xFE3004  ; -> prom_a 0x63004
T_F42D28:	jp 0xFE3008  ; -> prom_a 0x63008
T_F42D2C:	jp 0xFE300C  ; -> prom_a 0x6300C
T_F42D30:	jp 0xFE3010  ; -> prom_a 0x63010
T_F42D34:	jp 0xFE3014  ; -> prom_a 0x63014   x23
T_F42D38:	jp 0xFE3018  ; -> prom_a 0x63018   x17
	.fill 0x24, 1, 0x0E  ; 0xF42D3C: 36 x ret
T_F42D60:	jp 0xF85606  ; -> prom_a 0x05606   x1  the RESET path's landing slot:
				; prom_a 0xF827C4 `jp 0xF42D60`, and 0xF85606
				; is `ld XSP,0x0060EB80`, the first stack
T_F42D64:	jp 0xF85600  ; -> prom_a 0x05600
T_F42D68:	jp 0xF857B7  ; -> prom_a 0x057B7   x2
T_F42D6C:	jp 0xF857D9  ; -> prom_a 0x057D9   x2
T_F42D70:	jp 0xF8584A  ; -> prom_a 0x0584A
T_F42D74:	jp 0xF85877  ; -> prom_a 0x05877
T_F42D78:	jp 0xF858C0  ; -> prom_a 0x058C0
T_F42D7C:	jp 0xF85904  ; -> prom_a 0x05904
T_F42D80:	jp 0xF8592D  ; -> prom_a 0x0592D
T_F42D84:	jp 0xF8596D  ; -> prom_a 0x0596D
T_F42D88:	jp 0xF859AE  ; -> prom_a 0x059AE   x98  A selects a 4-byte descriptor
				; at 0x0338 + A*4 and a saturating byte counter
				; at 0x035B + A, under `ei 6`.  A kernel object
				; operation; WHICH one is not established.
T_F42D8C:	jp 0xF85A22  ; -> prom_a 0x05A22
T_F42D90:	jp 0xF85A96  ; -> prom_a 0x05A96   x9
T_F42D94:	jp 0xF85B1F  ; -> prom_a 0x05B1F
T_F42D98:	jp 0xF85BD4  ; -> prom_a 0x05BD4
T_F42D9C:	jp 0xF85C8C  ; -> prom_a 0x05C8C
T_F42DA0:	jp 0xF85DA8  ; -> prom_a 0x05DA8
T_F42DA4:	jp 0xF85E02  ; -> prom_a 0x05E02
T_F42DA8:	jp 0xF85E5E  ; -> prom_a 0x05E5E   x1
T_F42DAC:	jp 0xF857D6  ; -> prom_a 0x057D6   x1
T_F42DB0:	jp 0xF8584A  ; -> prom_a 0x0584A   x1
T_F42DB4:	jp 0xF85874  ; -> prom_a 0x05874
T_F42DB8:	jp 0xF85904  ; -> prom_a 0x05904
T_F42DBC:	jp 0xF8592A  ; -> prom_a 0x0592A
T_F42DC0:	jp 0xF859AB  ; -> prom_a 0x059AB   x98  the same routine entered three
				; bytes earlier, which first does
				; `ld A,(XSP+4)` -- the stack-argument form
T_F42DC4:	jp 0xF85A93  ; -> prom_a 0x05A93   x1
T_F42DC8:	jp 0xF85B0D  ; -> prom_a 0x05B0D   x7
T_F42DCC:	jp 0xF85C89  ; -> prom_a 0x05C89   x2
T_F42DD0:	jp 0xF85DA2  ; -> prom_a 0x05DA2
T_F42DD4:	jp 0xF85E5B  ; -> prom_a 0x05E5B
T_F42DD8:	jp 0xF85AEF  ; -> prom_a 0x05AEF   x1
T_F42DDC:	jp 0xF85D1C  ; -> prom_a 0x05D1C
T_F42DE0:	jp 0xF85F59  ; -> prom_a 0x05F59   x1
T_F42DE4:	jp 0xF85F7C  ; -> prom_a 0x05F7C
	.fill 0x18, 1, 0x0E  ; 0xF42DE8: 24 x ret
T_F42E00:	jp DisplayList_Run_Stack  ; -> prom_b 0x31800   x85
T_F42E04:	jp DisplayListB_Run_Stack  ; -> prom_b 0x31814   x104
T_F42E08:	jp DisplayList_RunOne_Stack  ; -> prom_b 0x31828   x47
T_F42E0C:	jp DisplayListB_RunOne_Stack  ; -> prom_b 0x3183D   x107
T_F42E10:	jp sub_F31852  ; -> prom_b 0x31852   x37  services 0x0C and 0x10, C = 0
T_F42E14:	jp sub_F31863  ; -> prom_b 0x31863   x39  service 0x0C, C = 7
T_F42E18:	jp 0xF31899  ; -> prom_b 0x31899   x9
T_F42E1C:	jp 0xF3190E  ; -> prom_b 0x3190E   x1
T_F42E20:	jp 0xF0E9CF  ; -> prom_b 0x0E9CF   x41
T_F42E24:	jp 0xF0E82B  ; -> prom_b 0x0E82B   x85
T_F42E28:	jp 0xF0E800  ; -> prom_b 0x0E800   x21
T_F42E2C:	jp 0xF0E83A  ; -> prom_b 0x0E83A   x1
T_F42E30:	jp 0xF0E835  ; -> prom_b 0x0E835   x2
	.fill 0xC, 1, 0x0E  ; 0xF42E34: 12 x ret
T_F42E40:	.long 0x00F53000	; ptr -> 0xF53000 (prom_b 0x53000)
T_F42E44:	jp 0xF53025  ; -> prom_b 0x53025
T_F42E48:	jp 0xF53029  ; -> prom_b 0x53029
T_F42E4C:	jp 0xF5302A  ; -> prom_b 0x5302A
T_F42E50:	jp 0xF53051  ; -> prom_b 0x53051
T_F42E54:	jp 0xF53DCC  ; -> prom_b 0x53DCC
T_F42E58:	jp 0xF5301A  ; -> prom_b 0x5301A
T_F42E5C:	jp 0xF5301A  ; -> prom_b 0x5301A
T_F42E60:	jp 0xF53DF4  ; -> prom_b 0x53DF4
T_F42E64:	jp 0xF53E04  ; -> prom_b 0x53E04   x1
T_F42E68:	jp 0xF541FF  ; -> prom_b 0x541FF   x3
T_F42E6C:	jp 0xF54210  ; -> prom_b 0x54210   x12
	.fill 0x10, 1, 0x0E  ; 0xF42E70: 16 x ret
T_F42E80:	jp 0xF8DA83  ; -> prom_a 0x0DA83   x141
T_F42E84:	jp 0xF8DA16  ; -> prom_a 0x0DA16   x188  ENQUEUE one 32-bit word on the
				; ring buffer at 0x600416: write index at +0xFC,
				; free count at +0xFE, `minc4 0x01FC` wrap ->
				; 128 slots.  Returns 0xFFFF when fewer than 5
				; free.  Runs under `ei 6`.
T_F42E88:	jp 0xF8DA00  ; -> prom_a 0x0DA00
	.fill 0x4, 1, 0x0E  ; 0xF42E8C: 4 x ret
T_F42E90:	jp 0xFB9DA0  ; -> prom_a 0x39DA0   x2
T_F42E94:	jp 0xFB9D2C  ; -> prom_a 0x39D2C   x3
T_F42E98:	jp 0xFB9D43  ; -> prom_a 0x39D43   x2
	.fill 0x24, 1, 0x0E  ; 0xF42E9C: 36 x ret
T_F42EC0:	jp 0xF6A9CA  ; -> prom_b 0x6A9CA   x1
T_F42EC4:	jp 0xF6AE4B  ; -> prom_b 0x6AE4B   x1
T_F42EC8:	jp 0xF675CC  ; -> prom_b 0x675CC   x2
	ret  ; 0xF42ECC: 1 x ret
	.fill 0x3, 1, 0x00  ; 0xF42ECD: 3 x nop
T_F42ED0:	jp 0xF68951  ; -> prom_b 0x68951   x1
T_F42ED4:	jp 0xF6A26C  ; -> prom_b 0x6A26C
T_F42ED8:	jp 0xF6C515  ; -> prom_b 0x6C515
T_F42EDC:	jp 0xF6AF58  ; -> prom_b 0x6AF58   x1
T_F42EE0:	jp 0xF68787  ; -> prom_b 0x68787
T_F42EE4:	jp 0xF67470  ; -> prom_b 0x67470
T_F42EE8:	jp 0xF67434  ; -> prom_b 0x67434
T_F42EEC:	jp 0xF687EC  ; -> prom_b 0x687EC
T_F42EF0:	jp 0xF6AB8E  ; -> prom_b 0x6AB8E
T_F42EF4:	jp 0xF6C625  ; -> prom_b 0x6C625
T_F42EF8:	jp 0xF6747D  ; -> prom_b 0x6747D   x1
T_F42EFC:	jp 0xF67479  ; -> prom_b 0x67479   x2
T_F42F00:	jp 0xF67488  ; -> prom_b 0x67488
T_F42F04:	jp 0xF693F6  ; -> prom_b 0x693F6   x1
	.fill 0x38, 1, 0x0E  ; 0xF42F08: 56 x ret
T_F42F40:	jp 0xF0F018  ; -> prom_b 0x0F018
T_F42F44:	jp 0xF0F02B  ; -> prom_b 0x0F02B
T_F42F48:	jp 0xF0F042  ; -> prom_b 0x0F042
T_F42F4C:	jp 0xF0F105  ; -> prom_b 0x0F105   x3
T_F42F50:	jp 0xF0F17C  ; -> prom_b 0x0F17C   x3
T_F42F54:	jp 0xF0F061  ; -> prom_b 0x0F061
T_F42F58:	jp 0xF114DA  ; -> prom_b 0x114DA   x8
T_F42F5C:	jp 0xF1156B  ; -> prom_b 0x1156B   x4
T_F42F60:	jp 0xF11365  ; -> prom_b 0x11365
T_F42F64:	jp 0xF11556  ; -> prom_b 0x11556
T_F42F68:	jp 0xF122C5  ; -> prom_b 0x122C5   x1
T_F42F6C:	jp 0xF12334  ; -> prom_b 0x12334   x1
	.fill 0x10, 1, 0x0E  ; 0xF42F70: 16 x ret
T_F42F80:	jp 0xF0B91C  ; -> prom_b 0x0B91C   x6
T_F42F84:	jp 0xF0B9B3  ; -> prom_b 0x0B9B3   x3
T_F42F88:	jp 0xF0BA20  ; -> prom_b 0x0BA20   x3
T_F42F8C:	jp 0xF0BAA8  ; -> prom_b 0x0BAA8   x3
T_F42F90:	jp 0xF0BBB4  ; -> prom_b 0x0BBB4   x3
T_F42F94:	jp 0xF0BC98  ; -> prom_b 0x0BC98   x3
T_F42F98:	jp 0xF0BD31  ; -> prom_b 0x0BD31   x3
T_F42F9C:	jp 0xF0BDAC  ; -> prom_b 0x0BDAC   x3
T_F42FA0:	jp 0xF0BE44  ; -> prom_b 0x0BE44   x3
T_F42FA4:	jp 0xF0BEBF  ; -> prom_b 0x0BEBF   x6
T_F42FA8:	jp 0xF0BF04  ; -> prom_b 0x0BF04   x4
T_F42FAC:	jp 0xFDA252  ; -> prom_a 0x5A252   x2
	.fill 0x20, 1, 0x0E  ; 0xF42FB0: 32 x ret
T_F42FD0:	jp 0xF19C18  ; -> prom_b 0x19C18
T_F42FD4:	jp 0xF19C19  ; -> prom_b 0x19C19
T_F42FD8:	jp 0xF19C94  ; -> prom_b 0x19C94
T_F42FDC:	jp 0xF19D4F  ; -> prom_b 0x19D4F
T_F42FE0:	jp 0xF19DB4  ; -> prom_b 0x19DB4
T_F42FE4:	jp 0xF19E01  ; -> prom_b 0x19E01
T_F42FE8:	jp 0xF19E4F  ; -> prom_b 0x19E4F
T_F42FEC:	jp 0xF19EA4  ; -> prom_b 0x19EA4
T_F42FF0:	jp 0xF19EBF  ; -> prom_b 0x19EBF
T_F42FF4:	jp 0xF19EDE  ; -> prom_b 0x19EDE
T_F42FF8:	jp 0xF19FEB  ; -> prom_b 0x19FEB
T_F42FFC:	jp 0xF1A0AF  ; -> prom_b 0x1A0AF
T_F43000:	jp 0xF1A0C7  ; -> prom_b 0x1A0C7
	.fill 0x1C, 1, 0x0E  ; 0xF43004: 28 x ret
T_F43020:	jp 0xFE7950  ; -> prom_a 0x67950   x1
T_F43024:	jp 0xFE7927  ; -> prom_a 0x67927   x1
T_F43028:	jp 0xFE7A49  ; -> prom_a 0x67A49   x1
T_F4302C:	jp 0xFE7800  ; -> prom_a 0x67800   x1
T_F43030:	jp 0xFE782C  ; -> prom_a 0x6782C   x1
T_F43034:	jp 0xFE7848  ; -> prom_a 0x67848   x1
	.fill 0x8, 1, 0x0E  ; 0xF43038: 8 x ret
T_F43040:	jp 0xF7D018  ; -> prom_b 0x7D018
T_F43044:	jp 0xF7D01C  ; -> prom_b 0x7D01C
T_F43048:	jp 0xF7D020  ; -> prom_b 0x7D020
T_F4304C:	jp 0xF7D025  ; -> prom_b 0x7D025
T_F43050:	jp 0xF7D02A  ; -> prom_b 0x7D02A
T_F43054:	jp 0xF7D02E  ; -> prom_b 0x7D02E
T_F43058:	jp 0xF7D032  ; -> prom_b 0x7D032
T_F4305C:	jp 0xF7D048  ; -> prom_b 0x7D048
T_F43060:	jp 0xF7D04C  ; -> prom_b 0x7D04C
T_F43064:	jp 0xF7D050  ; -> prom_b 0x7D050
T_F43068:	jp 0xF7D054  ; -> prom_b 0x7D054
T_F4306C:	jp 0xF7D05E  ; -> prom_b 0x7D05E
T_F43070:	jp 0xF7D062  ; -> prom_b 0x7D062
T_F43074:	jp 0xF7D066  ; -> prom_b 0x7D066
T_F43078:	jp 0xF7D06A  ; -> prom_b 0x7D06A
T_F4307C:	jp 0xF7D080  ; -> prom_b 0x7D080
T_F43080:	jp 0xF7D150  ; -> prom_b 0x7D150
T_F43084:	jp 0xF7D155  ; -> prom_b 0x7D155
T_F43088:	jp 0xF7D15A  ; -> prom_b 0x7D15A
T_F4308C:	jp 0xF7D170  ; -> prom_b 0x7D170
T_F43090:	jp 0xF7D12F  ; -> prom_b 0x7D12F
T_F43094:	jp 0xF7D134  ; -> prom_b 0x7D134
T_F43098:	jp 0xF7D139  ; -> prom_b 0x7D139
T_F4309C:	jp 0xF7D14F  ; -> prom_b 0x7D14F
T_F430A0:	jp 0xF7D0BC  ; -> prom_b 0x7D0BC
T_F430A4:	jp 0xF7D0C1  ; -> prom_b 0x7D0C1
T_F430A8:	jp 0xF7D0C6  ; -> prom_b 0x7D0C6
T_F430AC:	jp 0xF7D0DC  ; -> prom_b 0x7D0DC
T_F430B0:	jp 0xF7D0FE  ; -> prom_b 0x7D0FE
T_F430B4:	jp 0xF7D103  ; -> prom_b 0x7D103
T_F430B8:	jp 0xF7D108  ; -> prom_b 0x7D108
T_F430BC:	jp 0xF7D11E  ; -> prom_b 0x7D11E
T_F430C0:	jp 0xF7D238  ; -> prom_b 0x7D238
T_F430C4:	jp 0xF7D23D  ; -> prom_b 0x7D23D
T_F430C8:	jp 0xF7D242  ; -> prom_b 0x7D242
T_F430CC:	jp 0xF7D258  ; -> prom_b 0x7D258
T_F430D0:	jp 0xF7D259  ; -> prom_b 0x7D259
T_F430D4:	jp 0xF7D25E  ; -> prom_b 0x7D25E
T_F430D8:	jp 0xF7D263  ; -> prom_b 0x7D263
T_F430DC:	jp 0xF7D279  ; -> prom_b 0x7D279
T_F430E0:	jp 0xF7D0DD  ; -> prom_b 0x7D0DD
T_F430E4:	jp 0xF7D0E2  ; -> prom_b 0x7D0E2
T_F430E8:	jp 0xF7D0E7  ; -> prom_b 0x7D0E7
T_F430EC:	jp 0xF7D0FD  ; -> prom_b 0x7D0FD
T_F430F0:	jp 0xF7D1F6  ; -> prom_b 0x7D1F6
T_F430F4:	jp 0xF7D1FB  ; -> prom_b 0x7D1FB
T_F430F8:	jp 0xF7D200  ; -> prom_b 0x7D200
T_F430FC:	jp 0xF7D216  ; -> prom_b 0x7D216
T_F43100:	jp 0xF7D171  ; -> prom_b 0x7D171
T_F43104:	jp 0xF7D176  ; -> prom_b 0x7D176
T_F43108:	jp 0xF7D17B  ; -> prom_b 0x7D17B
T_F4310C:	jp 0xF7D191  ; -> prom_b 0x7D191
T_F43110:	jp 0xF7D1D5  ; -> prom_b 0x7D1D5
T_F43114:	jp 0xF7D1DA  ; -> prom_b 0x7D1DA
T_F43118:	jp 0xF7D1DF  ; -> prom_b 0x7D1DF
T_F4311C:	jp 0xF7D1F5  ; -> prom_b 0x7D1F5
T_F43120:	jp 0xF7D217  ; -> prom_b 0x7D217
T_F43124:	jp 0xF7D21C  ; -> prom_b 0x7D21C
T_F43128:	jp 0xF7D221  ; -> prom_b 0x7D221
T_F4312C:	jp 0xF7D237  ; -> prom_b 0x7D237
T_F43130:	jp 0xF7D11F  ; -> prom_b 0x7D11F
T_F43134:	jp 0xF7D124  ; -> prom_b 0x7D124
T_F43138:	jp 0xF7D129  ; -> prom_b 0x7D129
T_F4313C:	jp 0xF7D12E  ; -> prom_b 0x7D12E
T_F43140:	jp 0xF7D084  ; -> prom_b 0x7D084
T_F43144:	jp 0xF7D088  ; -> prom_b 0x7D088
T_F43148:	jp 0xF7D08C  ; -> prom_b 0x7D08C
T_F4314C:	jp 0xF7D0A2  ; -> prom_b 0x7D0A2
T_F43150:	jp 0xF7D29F  ; -> prom_b 0x7D29F
T_F43154:	jp 0xF7D2A4  ; -> prom_b 0x7D2A4
T_F43158:	jp 0xF7D2A9  ; -> prom_b 0x7D2A9
T_F4315C:	jp 0xF7D2B3  ; -> prom_b 0x7D2B3
T_F43160:	jp 0xF7D2B4  ; -> prom_b 0x7D2B4
T_F43164:	jp 0xF7D2B9  ; -> prom_b 0x7D2B9
T_F43168:	jp 0xF7D2BE  ; -> prom_b 0x7D2BE
T_F4316C:	jp 0xF7D2C5  ; -> prom_b 0x7D2C5
T_F43170:	jp 0xF7D28A  ; -> prom_b 0x7D28A
T_F43174:	jp 0xF7D28F  ; -> prom_b 0x7D28F
T_F43178:	jp 0xF7D294  ; -> prom_b 0x7D294
T_F4317C:	jp 0xF7D29E  ; -> prom_b 0x7D29E
T_F43180:	jp 0xF7D192  ; -> prom_b 0x7D192
T_F43184:	jp 0xF7D197  ; -> prom_b 0x7D197
T_F43188:	jp 0xF7D19C  ; -> prom_b 0x7D19C
T_F4318C:	jp 0xF7D1D4  ; -> prom_b 0x7D1D4
T_F43190:	jp 0xF7D0A6  ; -> prom_b 0x7D0A6
T_F43194:	jp 0xF7D0AA  ; -> prom_b 0x7D0AA
T_F43198:	jp 0xF7D0AE  ; -> prom_b 0x7D0AE
T_F4319C:	jp 0xF7D0B8  ; -> prom_b 0x7D0B8
T_F431A0:	jp 0xF7D27A  ; -> prom_b 0x7D27A
T_F431A4:	jp 0xF7D27F  ; -> prom_b 0x7D27F
T_F431A8:	jp 0xF7D284  ; -> prom_b 0x7D284
T_F431AC:	jp 0xF7D289  ; -> prom_b 0x7D289
T_F431B0:	jp 0xF7D000  ; -> prom_b 0x7D000   x53
T_F431B4:	jp 0xF7D006  ; -> prom_b 0x7D006   x57
T_F431B8:	jp 0xF7D003  ; -> prom_b 0x7D003
T_F431BC:	jp 0xF7D009  ; -> prom_b 0x7D009
T_F431C0:	jp 0xF7D00C  ; -> prom_b 0x7D00C   x5
T_F431C4:	jp 0xF7D00F  ; -> prom_b 0x7D00F   x2
T_F431C8:	jp 0xF7D012  ; -> prom_b 0x7D012   x3
T_F431CC:	jp 0xF7D015  ; -> prom_b 0x7D015   x4
T_F431D0:	jp 0xF7D2C6  ; -> prom_b 0x7D2C6
T_F431D4:	jp 0xF7D2CB  ; -> prom_b 0x7D2CB
T_F431D8:	jp 0xF7D2D0  ; -> prom_b 0x7D2D0
T_F431DC:	jp 0xF7D2D7  ; -> prom_b 0x7D2D7
	.fill 0xE0, 1, 0x0E  ; 0xF431E0: 224 x ret
T_F432C0:	jp 0xF65000  ; -> prom_b 0x65000   x2
T_F432C4:	jp 0xF65003  ; -> prom_b 0x65003   x2
T_F432C8:	jp 0xF65006  ; -> prom_b 0x65006   x2
T_F432CC:	jp 0xF65009  ; -> prom_b 0x65009   x2
	.fill 0x20, 1, 0x0E  ; 0xF432D0: 32 x ret
T_F432F0:	jp 0xF8BC0C  ; -> prom_a 0x0BC0C   x21
T_F432F4:	jp 0xF8BC67  ; -> prom_a 0x0BC67   x4
T_F432F8:	jp 0xF8BC78  ; -> prom_a 0x0BC78   x2
	.fill 0x34, 1, 0x0E  ; 0xF432FC: 52 x ret
T_F43330:	jp 0xF5B800  ; -> prom_b 0x5B800   x8
	.fill 0x1C, 1, 0x0E  ; 0xF43334: 28 x ret
T_F43350:	jp 0xFA835E  ; -> prom_a 0x2835E
T_F43354:	jp 0xFA8378  ; -> prom_a 0x28378
T_F43358:	jp 0xFA60C2  ; -> prom_a 0x260C2   x1
	.fill 0x24, 1, 0x0E  ; 0xF4335C: 36 x ret
T_F43380:	jp 0xF6F400  ; -> prom_b 0x6F400   x1
T_F43384:	jp 0xF6F404  ; -> prom_b 0x6F404   x2
	.fill 0x38, 1, 0x0E  ; 0xF43388: 56 x ret
T_F433C0:	jp 0xFE02AB  ; -> prom_a 0x602AB
	.fill 0xC, 1, 0x0E  ; 0xF433C4: 12 x ret
T_F433D0:	jp 0xFDD02D  ; -> prom_a 0x5D02D
T_F433D4:	jp 0xFDE2EC  ; -> prom_a 0x5E2EC
T_F433D8:	jp 0xF0AA10  ; -> prom_b 0x0AA10
T_F433DC:	jp 0xFDE2F9  ; -> prom_a 0x5E2F9
T_F433E0:	jp 0xFDE151  ; -> prom_a 0x5E151
T_F433E4:	jp 0xFDE3B0  ; -> prom_a 0x5E3B0
T_F433E8:	jp 0xF0AAB2  ; -> prom_b 0x0AAB2
T_F433EC:	jp 0xFDE3BD  ; -> prom_a 0x5E3BD
	.fill 0x10, 1, 0x0E  ; 0xF433F0: 16 x ret
T_F43400:	jp 0xF9F5E8  ; -> prom_a 0x1F5E8   x1
T_F43404:	jp 0xF9F65B  ; -> prom_a 0x1F65B   x3
T_F43408:	jp 0xF9F6B2  ; -> prom_a 0x1F6B2   x4
T_F4340C:	jp 0xF9F6EC  ; -> prom_a 0x1F6EC   x1
T_F43410:	jp 0xF9F75C  ; -> prom_a 0x1F75C   x2
T_F43414:	jp 0xF9F7B8  ; -> prom_a 0x1F7B8   x2
T_F43418:	jp 0xF9F457  ; -> prom_a 0x1F457   x1
T_F4341C:	jp 0xF9FBDE  ; -> prom_a 0x1FBDE   x1
T_F43420:	jp 0xFA0054  ; -> prom_a 0x20054   x1
	.fill 0xC, 1, 0x0E  ; 0xF43424: 12 x ret
T_F43430:	jp 0xF48C1A  ; -> prom_b 0x48C1A   x1
	.fill 0xC, 1, 0x0E  ; 0xF43434: 12 x ret
T_F43440:	jp 0xFAAE2A  ; -> prom_a 0x2AE2A   x2
T_F43444:	jp 0xFAAF91  ; -> prom_a 0x2AF91   x2
T_F43448:	jp 0xFABFFF  ; -> prom_a 0x2BFFF
T_F4344C:	jp 0xFAC7C4  ; -> prom_a 0x2C7C4   x3
T_F43450:	jp 0xFAABB3  ; -> prom_a 0x2ABB3   x1
T_F43454:	jp 0xFAC80F  ; -> prom_a 0x2C80F   x3
	.fill 0x8, 1, 0x0E  ; 0xF43458: 8 x ret
T_F43460:	jp 0xFE7200  ; -> prom_a 0x67200   x1
	.fill 0xC, 1, 0x0E  ; 0xF43464: 12 x ret
T_F43470:	jp 0xFD616A  ; -> prom_a 0x5616A   x1
T_F43474:	jp 0xFD61CF  ; -> prom_a 0x561CF   x1
T_F43478:	jp 0xFD6704  ; -> prom_a 0x56704   x1
T_F4347C:	jp 0xFD63D7  ; -> prom_a 0x563D7   x1
T_F43480:	jp 0xFD622B  ; -> prom_a 0x5622B   x1
T_F43484:	jp 0xFDA911  ; -> prom_a 0x5A911   x1
T_F43488:	jp 0xFD665C  ; -> prom_a 0x5665C   x2
T_F4348C:	jp 0xFD6513  ; -> prom_a 0x56513   x1
	.fill 0x10, 1, 0x0E  ; 0xF43490: 16 x ret
T_F434A0:	jp 0xF11C30  ; -> prom_b 0x11C30   x2
T_F434A4:	jp 0xF1220B  ; -> prom_b 0x1220B   x2
	.fill 0x18, 1, 0x0E  ; 0xF434A8: 24 x ret
T_F434C0:	jp 0xF9EEAB  ; -> prom_a 0x1EEAB
T_F434C4:	jp 0xF9EEDF  ; -> prom_a 0x1EEDF
T_F434C8:	jp 0xF9EEE0  ; -> prom_a 0x1EEE0
T_F434CC:	jp 0xF9EF07  ; -> prom_a 0x1EF07
T_F434D0:	jp 0xF9FDC8  ; -> prom_a 0x1FDC8
T_F434D4:	jp 0xFA0D10  ; -> prom_a 0x20D10   x1
	.fill 0x8, 1, 0x0E  ; 0xF434D8: 8 x ret
T_F434E0:	jp 0xF4C46A  ; -> prom_b 0x4C46A
T_F434E4:	jp 0xF4C4B0  ; -> prom_b 0x4C4B0
T_F434E8:	jp 0xF4C4B5  ; -> prom_b 0x4C4B5
T_F434EC:	jp 0xF4C4DC  ; -> prom_b 0x4C4DC
T_F434F0:	jp 0xF4C3F2  ; -> prom_b 0x4C3F2
T_F434F4:	jp 0xF4C42E  ; -> prom_b 0x4C42E
	.fill 0xB08, 1, 0x0E  ; 0xF434F8: 2824 x ret
T_F44000:	jp 0xF44042  ; -> prom_b 0x44042
T_F44004:	jp 0xF4425F  ; -> prom_b 0x4425F
T_F44008:	jp 0xF44095  ; -> prom_b 0x44095
T_F4400C:	jp 0xF440C4  ; -> prom_b 0x440C4
T_F44010:	jp 0xF44095  ; -> prom_b 0x44095
	.fill 0x4, 1, 0x0E  ; 0xF44014: 4 x ret

; --- 0xF44018-0xF54FFF: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x044018, 0x010FE8

; ==============================================================================
; 0xF55000-0xF5535A -- PARAMETER-EDIT PRIMITIVES AND TWO TABLE ACCESSORS
; ==============================================================================
;
; A linker section: 65 bytes of 0x0E (`ret`) fill end at 0xF54FFF, then 25 bytes
; of 4-byte `0E 00 00 00` slot fill, then nine routines, the last of which ends
; on a `ret` at 0xF5535A with the next `link XIZ` at 0xF5535B.
;
; Four of the nine are named by thunk slots that the census ranks near the top of
; the whole table (`python3 scripts/analysis/prom_b_thunk_table.py --census`):
;   T_F42C90 -> 0xF5533C  119 opcode-anchored references
;   T_F42C78 -> 0xF550A6   77
;   T_F42C8C -> 0xF55321   45
;   T_F42C70 -> 0xF55018  never called, but its 4-byte slot ADDRESS (`70 2C F4
;                         00`) occurs 397 times in prom_a+prom_b, 222 of them in
;                         one run at prom_a 0x216B4.  This block settles what it
;                         is: 0xF55018 is a single byte 0x0E -- a bare `ret`.
;                         The pointer table it fills is filled with a NO-OP.
;
; ⚠ The subsystem these belong to is NOT established.  Each header below says
; what its routine does to memory and nothing more.
; ==============================================================================

; --- 0xF55000-0xF55018: fill.  Six 4-byte slots of `0E 00 00 00` and one more
;     `0E`, the same `ret`-in-every-slot convention the thunk table uses. -----
	.byte 0x0E, 0x00, 0x00, 0x00
	.byte 0x0E, 0x00, 0x00, 0x00
	.byte 0x0E, 0x00, 0x00, 0x00
	.byte 0x0E, 0x00, 0x00, 0x00
	.byte 0x0E, 0x00, 0x00, 0x00
	.byte 0x0E, 0x00, 0x00, 0x00
; ---------------------------------------------------------------------
; Stub_Ret_F55018 -- the do-nothing entry the thunk table's most-spelled slot
;                    points at
; Called from: thunk T_F42C70 (0xF42C70).  That slot is never the operand of a
;              call or jp; its 32-bit ADDRESS appears 397 times as data.
; Inputs:  none.  Outputs: none.
; Evidence: the byte at 0xF55018 is 0x0E, which is RET
;           (mame/src/devices/cpu/tlcs900/dasm900.cpp:1267, M_RET at opcode 0x0E).
; Unknown:  which table those 397 words belong to.
; ---------------------------------------------------------------------
Stub_Ret_F55018:
	ret	; F55018  ret

; ---------------------------------------------------------------------
; sub_F55019 -- normalise a selector index and rebuild the flag byte (0x28B0)
; Called from: not yet traced to a specific caller
; Inputs:  (XIZ+8) = 16-bit index, (XIZ+0x0A) = 16-bit flags
; Outputs: A = the adjusted index; (0x28B1) = the original index;
;          (0x28B0) = a freshly built flag byte
; Evidence: `cp HL,0x1F / jrl UGT` rejects an index above 0x1F without touching
;           anything; then (0x28B0) is cleared and set bit by bit --
;             bit 0 <- bit 7 of the second argument
;             bit 1 <- (0x208C) AND the 32-bit word at 0xF55755 + 4*(0x28B1)
;             bit 2 <- index in 0x11..0x19, and the index has 0x11 subtracted
;             bit 5 <- index == 0x1B and (0x2267) == 0x0F
;           an index >= 0x1A additionally has 9 subtracted.
; Unknown:  what the index enumerates, what 0x208C and 0x2267 hold, and what the
;           32-bit mask table at 0xF55755 is.  That table is NOT converted here:
;           nothing bounds its length.
; ---------------------------------------------------------------------
sub_F55019:
	.byte 0xEE, 0x0C, 0x00, 0x00	; F55019  link XIZ,0x0000   [llvm-mc cannot encode this]
	pushw	hl	; F5501D  push HL
	push	xix	; F5501E  push XIX
	lda_d16	xix, (10416)	; F5501F  lda XIX,0x28b0
	ld	hl, (xiz+8)	; F55023  ld HL,(XIZ+0x08)
	cp	hl, 31	; F55026  cp HL,0x001f
	jrl	ugt, 116	; F5502A  jrl UGT,0xf550a1
	stb_d8	(10417), l	; F5502D  ld (0x28b1),L
	ld	(xix), 0	; F55031  ld (XIX),0x00
	ld	bc, (xiz+10)	; F55034  ld BC,(XIZ+0x0a)
	and	bc, 128	; F55037  and BC,0x0080
	jr	z, 5	; F5503B  jr Z,0xf55042
	ld	(xix), 1	; F5503D  ld (XIX),0x01
	jr	3	; F55040  jr T,0xf55045
	ld	(xix), 0	; F55042  ld (XIX),0x00
	ldb	c, 4	; F55045  ld C,0x04
	.byte 0xC1, 0xB1, 0x28, 0x43	; F55047  mul BC,(0x28b1)   [llvm-mc cannot encode this]
	extz	xbc	; F5504B  extz XBC
	add	xbc, 16078677	; F5504D  add XBC,0x00f55755
	ld	xbc, (xbc)	; F55053  ld XBC,(XBC)
	.byte 0xE1, 0x8C, 0x20, 0xC1	; F55055  and XBC,(0x208c)   [llvm-mc cannot encode this]
	jr	z, 3	; F55059  jr Z,0xf5505e
	.byte 0x84, 0x3E, 0x02	; F5505B  or (XIX),0x02   [llvm-mc cannot encode this]
	.byte 0xC1, 0xB1, 0x28, 0x3F, 0x11	; F5505E  cp (0x28b1),0x11   [llvm-mc cannot encode this]
	jr	c, 21	; F55063  jr C,0xf5507a
	.byte 0xC1, 0xB1, 0x28, 0x3F, 0x19	; F55065  cp (0x28b1),0x19   [llvm-mc cannot encode this]
	jr	ugt, 14	; F5506A  jr UGT,0xf5507a
	.byte 0x84, 0x3E, 0x04	; F5506C  or (XIX),0x04   [llvm-mc cannot encode this]
	ldw_d16	hl, (10417)	; F5506F  ld HL,(0x28b1)
	extz	hl	; F55073  extz HL
	ldw	bc, 17	; F55075  ld BC,0x0011
	sub	hl, bc	; F55078  sub HL,BC
	.byte 0xC1, 0xB1, 0x28, 0x3F, 0x1A	; F5507A  cp (0x28b1),0x1a   [llvm-mc cannot encode this]
	jr	c, 11	; F5507F  jr C,0xf5508c
	ldw_d16	hl, (10417)	; F55081  ld HL,(0x28b1)
	extz	hl	; F55085  extz HL
	ldw	bc, 9	; F55087  ld BC,0x0009
	sub	hl, bc	; F5508A  sub HL,BC
	.byte 0xC1, 0xB1, 0x28, 0x3F, 0x1B	; F5508C  cp (0x28b1),0x1b   [llvm-mc cannot encode this]
	jr	nz, 10	; F55091  jr NZ,0xf5509d
	.byte 0xC1, 0x67, 0x22, 0x3F, 0x0F	; F55093  cp (0x2267),0x0f   [llvm-mc cannot encode this]
	jr	nz, 3	; F55098  jr NZ,0xf5509d
	.byte 0x84, 0x3E, 0x20	; F5509A  or (XIX),0x20   [llvm-mc cannot encode this]
	ld	c, l	; F5509D  ld C,L
	ld	a, c	; F5509F  ld A,C
	pop	xix	; F550A1  pop XIX
	popw	hl	; F550A2  pop HL
	.byte 0xEE, 0x0D	; F550A3  unlk XIZ   [llvm-mc cannot encode this]
	ret	; F550A5  ret

; ---------------------------------------------------------------------
; sub_F550A6 -- read a bit-field through an 8-byte descriptor and range-check it
; Called from: thunk T_F42C78 (0xF42C78), 77 opcode-anchored references
; Inputs:  (XIZ+8) = 32-bit pointer to the source byte,
;          (XIZ+0x0C) = 32-bit pointer to an 8-byte descriptor
; Outputs: register results; (0x28B0) is XORed with descriptor byte +7 and bit 3
;          of (0x2075) is set
; Evidence: `ld E,(XBC)` reads the source byte, `and D,E` masks it with
;           descriptor +1, then a loop shifts D right and counts in L until L
;           reaches descriptor +2 -- i.e. it normalises the field.  Descriptor
;           +3/+4 are the clamp bounds, +5/+6 are alternative step values chosen
;           by bits of (0x2075) and (0x28B0), +7 is the flag XOR mask.
;           The routine does not only READ: after the adjust it writes the field
;           back (`and (XBC),H / or A,D / ld (XBC),A` at 0xF55161) and returns
;           A = 1, or returns A = 0 unchanged when `cp H,D` at 0xF5513D finds
;           the value did not move.
; ⚠ CORRECTED 2026-08-25.  This header used to end "0xF5535B, just past this
;           block, is the same routine with the two pointer arguments swapped."
;           Both halves are wrong.  0xF5535B's first argument is an INDEX, not a
;           pointer -- it resolves the target through IndexedTable_GetPtr and
;           then adds descriptor +0 -- and it journals every change to
;           List2030_Append4 or Queue2C00_Append4, which this routine does not
;           do at all.  What the two really share is the 100-byte ADJUST CORE,
;           identical in 99 of 100 bytes (the one difference is a frame
;           displacement).  Measured by notes/prom_b_param_edit_pair.py; the
;           converted routine is IndexedParam_AdjustField below.
; Unknown:  what the descriptor describes.
; ---------------------------------------------------------------------
sub_F550A6:
	.byte 0xEE, 0x0C, 0xFE, 0xFF	; F550A6  link XIZ,0xfffe   [llvm-mc cannot encode this]
	pushw	hl	; F550AA  push HL
	pushw	de	; F550AB  push DE
	push	xix	; F550AC  push XIX
	ld	xix, (xiz+12)	; F550AD  ld XIX,(XIZ+0x0c)
	ld	c, (xix+7)	; F550B0  ld C,(XIX+0x07)
	xordm8	(10416), c	; F550B3  xor (0x28b0),C
	.byte 0xF1, 0x75, 0x20, 0xBB	; F550B7  set 3,(0x2075)   [llvm-mc cannot encode this]
	ld	xbc, (xiz+8)	; F550BB  ld XBC,(XIZ+0x08)
	ld	e, (xbc)	; F550BE  ld E,(XBC)
	ld	a, (xix+1)	; F550C0  ld A,(XIX+0x01)
	ld	d, a	; F550C3  ld D,A
	and	d, e	; F550C5  and D,E
	ldb	l, 0	; F550C7  ld L,0x00
	ld	h, (xix+2)	; F550C9  ld H,(XIX+0x02)
	cp	l, h	; F550CC  cp L,H
	jr	nc, 11	; F550CE  jr NC,0xf550db
	ld	c, d	; F550D0  ld C,D
	srl	c, 1	; F550D2  srl 0x01,C
	ld	d, c	; F550D5  ld D,C
	inc	1, l	; F550D7  inc 1,L
	jr	-15	; F550D9  jr T,0xf550cc
	ld	h, d	; F550DB  ld H,D
	ldb_d8	c, (10416)	; F550DD  ld C,(0x28b0)
	and	c, 4	; F550E1  and C,0x04
	jr	z, 5	; F550E4  jr Z,0xf550eb
	ld	l, (xix+6)	; F550E6  ld L,(XIX+0x06)
	jr	14	; F550E9  jr T,0xf550f9
	ldb	l, 1	; F550EB  ld L,0x01
	ldb_d8	c, (8309)	; F550ED  ld C,(0x2075)
	and	c, 4	; F550F1  and C,0x04
	jr	z, 3	; F550F4  jr Z,0xf550f9
	ld	l, (xix+5)	; F550F6  ld L,(XIX+0x05)
	ldb_d8	c, (10416)	; F550F9  ld C,(0x28b0)
	and	c, 1	; F550FD  and C,0x01
	jr	z, 29	; F55100  jr Z,0xf5511f
	ld	e, (xix+4)	; F55102  ld E,(XIX+0x04)
	ld	c, e	; F55105  ld C,E
	add	c, l	; F55107  add C,L
	ld	(xiz-2), c	; F55109  ld (XIZ+0xfe),C
	cp	h, c	; F5510C  cp H,C
	jr	c, 10	; F5510E  jr C,0xf5511a
	cp	c, e	; F55110  cp C,E
	jr	ule, 6	; F55112  jr ULE,0xf5511a
	ld	a, l	; F55114  ld A,L
	sub	h, a	; F55116  sub H,A
	jr	35	; F55118  jr T,0xf5513d
	ld	h, (xix+4)	; F5511A  ld H,(XIX+0x04)
	jr	30	; F5511D  jr T,0xf5513d
	ld	c, (xix+3)	; F5511F  ld C,(XIX+0x03)
	ld	(xiz-1), c	; F55122  ld (XIZ+0xff),C
	ld	e, c	; F55125  ld E,C
	sub	c, l	; F55127  sub C,L
	ld	e, c	; F55129  ld E,C
	cp	h, c	; F5512B  cp H,C
	jr	ugt, 11	; F5512D  jr UGT,0xf5513a
	.byte 0x8E, 0xFF, 0xF3	; F5512F  cp C,(XIZ+0xff)   [llvm-mc cannot encode this]
	jr	nc, 6	; F55132  jr NC,0xf5513a
	ld	c, l	; F55134  ld C,L
	add	h, c	; F55136  add H,C
	jr	3	; F55138  jr T,0xf5513d
	ld	h, (xix+3)	; F5513A  ld H,(XIX+0x03)
	cp	h, d	; F5513D  cp H,D
	jr	z, 50	; F5513F  jr Z,0xf55173
	ldb	l, 0	; F55141  ld L,0x00
	ld	d, (xix+2)	; F55143  ld D,(XIX+0x02)
	cp	l, d	; F55146  cp L,D
	jr	nc, 10	; F55148  jr NC,0xf55154
	ld	c, h	; F5514A  ld C,H
	add	c, h	; F5514C  add C,H
	ld	h, c	; F5514E  ld H,C
	inc	1, l	; F55150  inc 1,L
	jr	-14	; F55152  jr T,0xf55146
	ld	l, (xix+1)	; F55154  ld L,(XIX+0x01)
	ld	d, l	; F55157  ld D,L
	and	d, h	; F55159  and D,H
	ld	c, l	; F5515B  ld C,L
	cpl	c	; F5515D  cpl C
	ld	h, c	; F5515F  ld H,C
	ld	xbc, (xiz+8)	; F55161  ld XBC,(XIZ+0x08)
	and	(xbc), h	; F55164  and (XBC),H
	ld	xbc, (xiz+8)	; F55166  ld XBC,(XIZ+0x08)
	ld	a, (xbc)	; F55169  ld A,(XBC)
	or	a, d	; F5516B  or A,D
	ld	(xbc), a	; F5516D  ld (XBC),A
	ldb	a, 1	; F5516F  ld A,0x01
	jr	2	; F55171  jr T,0xf55175
	sub	a, a	; F55173  sub A,A
	pop	xix	; F55175  pop XIX
	popw	de	; F55176  pop DE
	popw	hl	; F55177  pop HL
	.byte 0xEE, 0x0D	; F55178  unlk XIZ   [llvm-mc cannot encode this]
	ret	; F5517A  ret

; ---------------------------------------------------------------------
; sub_F5517B -- set, clear or toggle a masked bit group in one byte
; Called from: not yet traced to a specific caller
; Inputs:  (XIZ+8) = 32-bit pointer to the target byte,
;          (XIZ+0x0C) = 32-bit pointer to a descriptor whose +1 is the mask and
;          whose +2 is XORed into (0x28B0) first
; Outputs: A = 1 if the byte changed, 0 if it did not; the byte is updated
; Evidence: after the XOR into (0x28B0), bit 0 of (0x28B0) selects between two
;           edits of L = (XIX): with the bit set, `and A,L` then `cpl A / and
;           L,A` clears the mask; with it clear, `or L,A` sets it.  The result is
;           compared with the original `cp H,L` and only written back on a
;           difference, which is also what the 1/0 return reports.
; Unknown:  what the byte is.
; ---------------------------------------------------------------------
sub_F5517B:
	.byte 0xEE, 0x0C, 0x00, 0x00	; F5517B  link XIZ,0x0000   [llvm-mc cannot encode this]
	pushw	hl	; F5517F  push HL
	pushw	de	; F55180  push DE
	push	xix	; F55181  push XIX
	ld	xix, (xiz+8)	; F55182  ld XIX,(XIZ+0x08)
	ld	xbc, (xiz+12)	; F55185  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+2)	; F55188  ld A,(XBC+0x02)
	xordm8	(10416), a	; F5518B  xor (0x28b0),A
	ld	l, (xix)	; F5518F  ld L,(XIX)
	ldb_d8	a, (10416)	; F55191  ld A,(0x28b0)
	and	a, 1	; F55195  and A,0x01
	jr	z, 17	; F55198  jr Z,0xf551ab
	ld	h, (xbc+1)	; F5519A  ld H,(XBC+0x01)
	ld	a, h	; F5519D  ld A,H
	and	a, l	; F5519F  and A,L
	jr	z, 24	; F551A1  jr Z,0xf551bb
	ld	a, h	; F551A3  ld A,H
	cpl	a	; F551A5  cpl A
	and	l, a	; F551A7  and L,A
	jr	16	; F551A9  jr T,0xf551bb
	ld	xbc, (xiz+12)	; F551AB  ld XBC,(XIZ+0x0c)
	ld	h, (xbc+1)	; F551AE  ld H,(XBC+0x01)
	ld	a, h	; F551B1  ld A,H
	and	a, l	; F551B3  and A,L
	jr	nz, 4	; F551B5  jr NZ,0xf551bb
	ld	a, h	; F551B7  ld A,H
	or	l, a	; F551B9  or L,A
	ld	h, (xix)	; F551BB  ld H,(XIX)
	cp	h, l	; F551BD  cp H,L
	jr	z, 30	; F551BF  jr Z,0xf551df
	ld	xbc, (xiz+12)	; F551C1  ld XBC,(XIZ+0x0c)
	ld	d, (xbc+1)	; F551C4  ld D,(XBC+0x01)
	ld	e, d	; F551C7  ld E,D
	and	e, l	; F551C9  and E,L
	ld	c, d	; F551CB  ld C,D
	cpl	c	; F551CD  cpl C
	ld	l, c	; F551CF  ld L,C
	and	l, h	; F551D1  and L,H
	ld	(xix), l	; F551D3  ld (XIX),L
	ld	c, e	; F551D5  ld C,E
	or	c, l	; F551D7  or C,L
	ld	(xix), c	; F551D9  ld (XIX),C
	ldb	a, 1	; F551DB  ld A,0x01
	jr	2	; F551DD  jr T,0xf551e1
	sub	a, a	; F551DF  sub A,A
	pop	xix	; F551E1  pop XIX
	popw	de	; F551E2  pop DE
	popw	hl	; F551E3  pop HL
	.byte 0xEE, 0x0D	; F551E4  unlk XIZ   [llvm-mc cannot encode this]
	ret	; F551E6  ret

; ---------------------------------------------------------------------
; sub_F551E7 -- clamp a 16-bit value to a descriptor's two bounds
; Called from: not yet traced to a specific caller
; Inputs:  (XIZ+8) = 32-bit pointer to the 16-bit value,
;          (XIZ+0x0C) = 32-bit pointer to a descriptor; +3 and +4 are the bounds,
;          +7 is XORed into (0x28B0) first
; Outputs: A = 1 if the value was already inside the bounds, 0 if it was clamped
;          and written back
; Evidence: `ld IX,(XWA)` reads the value, `cp IX,WA / jr NC` against descriptor
;           +4 and `cp DE,WA / jr ULE` against descriptor +3 each replace DE with
;           the bound; `cp DE,IX` then decides between writing DE back and
;           returning 1.
; Unknown:  what the value is.
; ---------------------------------------------------------------------
sub_F551E7:
	.byte 0xEE, 0x0C, 0x00, 0x00	; F551E7  link XIZ,0x0000   [llvm-mc cannot encode this]
	pushw	hl	; F551EB  push HL
	pushw	de	; F551EC  push DE
	pushw	ix	; F551ED  push IX
	ld	xbc, (xiz+12)	; F551EE  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+7)	; F551F1  ld A,(XBC+0x07)
	xordm8	(10416), a	; F551F4  xor (0x28b0),A
	ld	xwa, (xiz+8)	; F551F8  ld XWA,(XIZ+0x08)
	ld	ix, (xwa)	; F551FB  ld IX,(XWA)
	ld	de, ix	; F551FD  ld DE,IX
	ld	a, (xbc+4)	; F551FF  ld A,(XBC+0x04)
	extz	wa	; F55202  extz WA
	ld	hl, wa	; F55204  ld HL,WA
	cp	ix, wa	; F55206  cp IX,WA
	jr	nc, 2	; F55208  jr NC,0xf5520c
	ld	de, wa	; F5520A  ld DE,WA
	ld	xbc, (xiz+12)	; F5520C  ld XBC,(XIZ+0x0c)
	ld	a, (xbc+3)	; F5520F  ld A,(XBC+0x03)
	extz	wa	; F55212  extz WA
	ld	hl, wa	; F55214  ld HL,WA
	cp	de, wa	; F55216  cp DE,WA
	jr	ule, 2	; F55218  jr ULE,0xf5521c
	ld	de, wa	; F5521A  ld DE,WA
	cp	de, ix	; F5521C  cp DE,IX
	jr	z, 9	; F5521E  jr Z,0xf55229
	ld	xbc, (xiz+8)	; F55220  ld XBC,(XIZ+0x08)
	ld	(xbc), de	; F55223  ld (XBC),DE
	sub	a, a	; F55225  sub A,A
	jr	2	; F55227  jr T,0xf5522b
	ldb	a, 1	; F55229  ld A,0x01
	popw	ix	; F5522B  pop IX
	popw	de	; F5522C  pop DE
	popw	hl	; F5522D  pop HL
	.byte 0xEE, 0x0D	; F5522E  unlk XIZ   [llvm-mc cannot encode this]
	ret	; F55230  ret

; ---------------------------------------------------------------------
; Queue2C00_Append4 -- append a 4-byte record to the queue at 0x2C00
; Called from: not yet traced to a specific caller
; Inputs:  four bytes, one per 16-bit stack slot: (XIZ+8), (XIZ+0x0A),
;          (XIZ+0x0C), (XIZ+0x0E)
; Outputs: the record is stored at 0x2C00 + (0x60F000), 0xFF is written one byte
;          past it, and (0x60F000) is advanced by 4.  Nothing happens once
;          (0x60F000) reaches 0x01FC.
; Evidence: `lda XIX,0x60F000 / ld BC,(XIX) / cp BC,0x01FC / jr NC,<exit>`, then
;           `ld BC,0x2C00 / add BC,HL` forms the write address, four
;           `ld (XBC+n),A` stores, `ld (XBC+4),0xFF`, `incw 4,(XIX)`.
;           0x01FC / 4 = 127 records.
; Unknown:  what reads the queue, and what the four bytes mean.
; ---------------------------------------------------------------------
Queue2C00_Append4:
	.byte 0xEE, 0x0C, 0xFC, 0xFF	; F55231  link XIZ,0xfffc   [llvm-mc cannot encode this]
	pushw	hl	; F55235  push HL
	push	xix	; F55236  push XIX
	lda_24	xix, (6352896)	; F55237  lda XIX,0x60f000
	ld	bc, (xix)	; F5523C  ld BC,(XIX)
	cp	bc, 508	; F5523E  cp BC,0x01fc
	jr	nc, 53	; F55242  jr NC,0xf55279
	ld	hl, (xix)	; F55244  ld HL,(XIX)
	ldw	bc, 11264	; F55246  ld BC,0x2c00
	add	bc, hl	; F55249  add BC,HL
	extz	xbc	; F5524B  extz XBC
	ld	(xiz-4), xbc	; F5524D  ld (XIZ+0xfc),XBC
	ld	a, (xiz+8)	; F55250  ld A,(XIZ+0x08)
	ld	(xbc), a	; F55253  ld (XBC),A
	ld	xbc, (xiz-4)	; F55255  ld XBC,(XIZ+0xfc)
	ld	a, (xiz+10)	; F55258  ld A,(XIZ+0x0a)
	ld	(xbc+1), a	; F5525B  ld (XBC+0x01),A
	ld	xbc, (xiz-4)	; F5525E  ld XBC,(XIZ+0xfc)
	ld	a, (xiz+12)	; F55261  ld A,(XIZ+0x0c)
	ld	(xbc+2), a	; F55264  ld (XBC+0x02),A
	ld	xbc, (xiz-4)	; F55267  ld XBC,(XIZ+0xfc)
	ld	a, (xiz+14)	; F5526A  ld A,(XIZ+0x0e)
	ld	(xbc+3), a	; F5526D  ld (XBC+0x03),A
	ld	xbc, (xiz-4)	; F55270  ld XBC,(XIZ+0xfc)
	ld	(xbc+4), 255	; F55273  ld (XBC+0x04),0xff
	incm	4, (xix)	; F55277  incw 4,(XIX)
	pop	xix	; F55279  pop XIX
	popw	hl	; F5527A  pop HL
	.byte 0xEE, 0x0D	; F5527B  unlk XIZ   [llvm-mc cannot encode this]
	ret	; F5527D  ret

; ---------------------------------------------------------------------
; Queue2E00_Append4 -- the same, for the queue at 0x2E00, gated on the first
; Called from: not yet traced to a specific caller
; Inputs:  as Queue2C00_Append4
; Outputs: record at 0x2E00 + (0x60F004), 0xFF one past, (0x60F004) += 4
; Evidence: byte for byte the same routine with 0x2C00 -> 0x2E00 and 0x60F000 ->
;           0x60F004, EXCEPT that the capacity test is still on (0x60F000):
;           `cp (0x60F000),0x00FC / jr NC,<exit>`.  So this queue is only written
;           while the FIRST queue is less than 0xFC (63 records) deep.
; Unknown:  why the two queues are coupled this way.
; ---------------------------------------------------------------------
Queue2E00_Append4:
	.byte 0xEE, 0x0C, 0xFC, 0xFF	; F5527E  link XIZ,0xfffc   [llvm-mc cannot encode this]
	pushw	hl	; F55282  push HL
	push	xix	; F55283  push XIX
	.byte 0xD2, 0x00, 0xF0, 0x60, 0x3F, 0xFC, 0x00	; F55284  cp (0x60f000),0x00fc   [llvm-mc cannot encode this]
	jr	nc, 58	; F5528B  jr NC,0xf552c7
	lda_24	xix, (6352900)	; F5528D  lda XIX,0x60f004
	ld	hl, (xix)	; F55292  ld HL,(XIX)
	ldw	bc, 11776	; F55294  ld BC,0x2e00
	add	bc, hl	; F55297  add BC,HL
	extz	xbc	; F55299  extz XBC
	ld	(xiz-4), xbc	; F5529B  ld (XIZ+0xfc),XBC
	ld	a, (xiz+8)	; F5529E  ld A,(XIZ+0x08)
	ld	(xbc), a	; F552A1  ld (XBC),A
	ld	xbc, (xiz-4)	; F552A3  ld XBC,(XIZ+0xfc)
	ld	a, (xiz+10)	; F552A6  ld A,(XIZ+0x0a)
	ld	(xbc+1), a	; F552A9  ld (XBC+0x01),A
	ld	xbc, (xiz-4)	; F552AC  ld XBC,(XIZ+0xfc)
	ld	a, (xiz+12)	; F552AF  ld A,(XIZ+0x0c)
	ld	(xbc+2), a	; F552B2  ld (XBC+0x02),A
	ld	xbc, (xiz-4)	; F552B5  ld XBC,(XIZ+0xfc)
	ld	a, (xiz+14)	; F552B8  ld A,(XIZ+0x0e)
	ld	(xbc+3), a	; F552BB  ld (XBC+0x03),A
	ld	xbc, (xiz-4)	; F552BE  ld XBC,(XIZ+0xfc)
	ld	(xbc+4), 255	; F552C1  ld (XBC+0x04),0xff
	incm	4, (xix)	; F552C5  incw 4,(XIX)
	pop	xix	; F552C7  pop XIX
	popw	hl	; F552C8  pop HL
	.byte 0xEE, 0x0D	; F552C9  unlk XIZ   [llvm-mc cannot encode this]
	ret	; F552CB  ret

; ---------------------------------------------------------------------
; List2030_Append4 -- append a 4-byte record to the 0xFF-terminated list at
;                     0x2030, which ends at 0x206C
; Called from: not yet traced to a specific caller
; Inputs:  four bytes in (XIZ+8), (XIZ+0x0A), (XIZ+0x0C), (XIZ+0x0E)
; Outputs: the record replaces the 0xFF terminator, and a new 0xFF follows it
; Evidence: `lda XIX,0x2030 / lda XBC,0x206C`, then a scan `ld C,(XIX) /
;           cp C,0xFF / jr Z / inc 4,XIX` walks the list in 4-byte steps to its
;           terminator; `cp XWA,XBC / jr NC,<exit>` refuses to write at or past
;           0x206C.  (0x206C - 0x2030) / 4 = 15 slots.
; Unknown:  what the list is for.
; ---------------------------------------------------------------------
List2030_Append4:
	.byte 0xEE, 0x0C, 0xF8, 0xFF	; F552CC  link XIZ,0xfff8   [llvm-mc cannot encode this]
	push	xix	; F552D0  push XIX
	lda_d16	xix, (8240)	; F552D1  lda XIX,0x2030
	lda_d16	xbc, (8300)	; F552D5  lda XBC,0x206c
	ld	(xiz-4), xbc	; F552D9  ld (XIZ+0xfc),XBC
	ld	c, (xix)	; F552DC  ld C,(XIX)
	cp	c, 255	; F552DE  cp C,0xff
	jr	z, 4	; F552E1  jr Z,0xf552e7
	inc	4, xix	; F552E3  inc 4,XIX
	jr	-11	; F552E5  jr T,0xf552dc
	ld	xbc, (xiz-4)	; F552E7  ld XBC,(XIZ+0xfc)
	ld	(xiz-8), xbc	; F552EA  ld (XIZ+0xf8),XBC
	ld	xwa, xix	; F552ED  ld XWA,XIX
	cp	xwa, xbc	; F552EF  cp XWA,XBC
	jr	nc, 42	; F552F1  jr NC,0xf5531d
	ld	c, (xiz+8)	; F552F3  ld C,(XIZ+0x08)
	ld	(xix), c	; F552F6  ld (XIX),C
	ld	xbc, xix	; F552F8  ld XBC,XIX
	inc	1, xbc	; F552FA  inc 1,XBC
	ld	(xiz-8), xbc	; F552FC  ld (XIZ+0xf8),XBC
	ld	a, (xiz+10)	; F552FF  ld A,(XIZ+0x0a)
	ld	(xbc), a	; F55302  ld (XBC),A
	ld	xbc, (xiz-8)	; F55304  ld XBC,(XIZ+0xf8)
	ld	a, (xiz+12)	; F55307  ld A,(XIZ+0x0c)
	ld	(xbc+1), a	; F5530A  ld (XBC+0x01),A
	ld	xbc, (xiz-8)	; F5530D  ld XBC,(XIZ+0xf8)
	ld	a, (xiz+14)	; F55310  ld A,(XIZ+0x0e)
	ld	(xbc+2), a	; F55313  ld (XBC+0x02),A
	ld	xbc, (xiz-8)	; F55316  ld XBC,(XIZ+0xf8)
	ld	(xbc+3), 255	; F55319  ld (XBC+0x03),0xff
	pop	xix	; F5531D  pop XIX
	.byte 0xEE, 0x0D	; F5531E  unlk XIZ   [llvm-mc cannot encode this]
	ret	; F55320  ret

; ---------------------------------------------------------------------
; IndexedTable_GetPtr -- pointer n of the table whose base is the word at
;                        0x60F018
; Called from: thunk T_F42C8C (0xF42C8C), 45 opcode-anchored references
; Inputs:  (XIZ+8) = 16-bit index
; Outputs: XIY = the 32-bit pointer at base + 4*index
; Evidence: `ld XIX,(0x60F018)` loads the base from RAM, `ld C,4 / mul BC,(XIZ+8)
;           / extz XBC / add XBC,XIX / ld XWA,(XBC) / ld XIY,XWA`.
; Unknown:  what the table holds and who writes 0x60F018.
; ---------------------------------------------------------------------
IndexedTable_GetPtr:
	.byte 0xEE, 0x0C, 0x00, 0x00	; F55321  link XIZ,0x0000   [llvm-mc cannot encode this]
	push	xix	; F55325  push XIX
	ldl_da	xix, (6352920)	; F55326  ld XIX,(0x60f018)
	ldb	c, 4	; F5532B  ld C,0x04
	.byte 0x8E, 0x08, 0x43	; F5532D  mul BC,(XIZ+0x08)   [llvm-mc cannot encode this]
	extz	xbc	; F55330  extz XBC
	add	xbc, xix	; F55332  add XBC,XIX
	ld	xwa, (xbc)	; F55334  ld XWA,(XBC)
	ld	xiy, xwa	; F55336  ld XIY,XWA
	pop	xix	; F55338  pop XIX
	.byte 0xEE, 0x0D	; F55339  unlk XIZ   [llvm-mc cannot encode this]
	ret	; F5533B  ret

; ---------------------------------------------------------------------
; IndexedTable_GetByte -- byte m of pointer n of the same table
; Called from: thunk T_F42C90 (0xF42C90), 119 opcode-anchored references -- the
;              third-busiest prom_b-resident slot in the thunk table
; Inputs:  (XIZ+8) = table index, (XIZ+0x0A) = byte offset
; Outputs: A = the byte; XIX = the entry pointer; XIY = the byte's address
; Evidence: it pushes a 32-bit argument built as `push 0x00 / push (XIZ+8)`,
;           calls IndexedTable_GetPtr, then `ld BC,(XIZ+0x0A) / extz / add
;           XIY,XBC / ld A,(XIY)`.
; Unknown:  as above.
; ---------------------------------------------------------------------
IndexedTable_GetByte:
	.byte 0xEE, 0x0C, 0x00, 0x00	; F5533C  link XIZ,0x0000   [llvm-mc cannot encode this]
	push	xix	; F55340  push XIX
	push	0	; F55341  push 0x00
	.byte 0x8E, 0x08, 0x04	; F55343  push (XIZ+0x08)   [llvm-mc cannot encode this]
	calr	65496	; F55346  calr 0xf55321
	ld	xix, xiy	; F55349  ld XIX,XIY
	ld	bc, (xiz+10)	; F5534B  ld BC,(XIZ+0x0a)
	extz	bc	; F5534E  extz BC
	extz	xbc	; F55350  extz XBC
	add	xiy, xbc	; F55352  add XIY,XBC
	ld	a, (xiy)	; F55354  ld A,(XIY)
	popw	bc	; F55356  pop BC
	pop	xix	; F55357  pop XIX
	.byte 0xEE, 0x0D	; F55358  unlk XIZ   [llvm-mc cannot encode this]
	ret	; F5535A  ret


; ---------------------------------------------------------------------
; IndexedParam_AdjustField -- step one packed parameter field up or down,
;                             clamp it, write it back and journal the change
; Called from: thunk T_F42C94 (0xF42C94), 23 opcode-anchored references
;          (an upper bound that ranks slots; not a call count)
; Inputs:  (XIZ+0x08) = a 16-bit INDEX -- not a pointer;
;          (XIZ+0x0A) = 32-bit pointer to the 8-byte descriptor already
;          documented on sub_F550A6 above:
;              +0 byte offset into the object   +1 field mask
;              +2 right-shift count             +3 upper bound
;              +4 lower bound                   +5 step when (0x2075) bit 2
;              +6 step when (0x28B0) bit 2      +7 XORed into (0x28B0) on entry
;          plus (0x28B0) bits 0/2/3/4 and (0x2075) bit 2.
; Outputs: the field in the target byte is replaced; a 4-byte record is appended
;          to one of the two journals; bit 3 of (0x2075) is set; (0x28B0) is
;          XORed with descriptor +7.  Nothing is written if the value did not
;          change (`cp H,D / jr Z` at 0xF55413 jumps straight to the epilogue).
; Evidence: the object is resolved, not passed: `push 0x00 / push (XIZ+0x08) /
;          calr 0xF55321` is IndexedTable_GetPtr, and descriptor +0 is then
;          added to the pointer it returns (`ld C,(XIX) / extz / add XIY,XBC`).
;          The adjust core is BYTE-IDENTICAL to sub_F550A6's: 0xF553B1..0xF55414
;          equals 0xF550DB..0xF5513E in 99 of 100 bytes, the single difference
;          being a frame displacement at 0xF553E0 (0xF9 = -7) versus 0xF5510A
;          (0xFE = -2), which is just the two routines' different frame sizes.
;          (Measured by notes/prom_b_param_edit_pair.py.)
;          The journals are the already-converted appenders: 0xF552CC =
;          List2030_Append4 when bit 3 of (0x28B0) is set, otherwise the
;          in-place write-back followed by 0xF55231 = Queue2C00_Append4.
;          Both are handed the same four-slot frame those routines read --
;          index, descriptor +0, the NEW field value, descriptor +1 -- eight
;          bytes, released by the `inc 0,XSP`.  An immediate of 0 there means
;          EIGHT, not zero: MAME's op_INCLIR is
;          `*m_p2_reg32 += m_imm1.b.l ? m_imm1.b.l : 8`
;          (mame/src/devices/cpu/tlcs900/900tbl.hxx).  Counting the pushes
;          confirms it -- 2+1+1+2+1+1 = 8 bytes.
; Notes:   bit 0 of (0x28B0) picks the direction: clear takes the +3 bound and
;          `add H,C`, set takes the +4 bound and `sub H,A`.  Each branch has two
;          guards, one against crossing the bound and one against the bound
;          arithmetic itself wrapping, and both land on `ld H,(XIX+3 or +4)`.
;          Bit 4 of (0x28B0) adds 0x20 to the index before the lookup.
; Unknown:  what the objects in the 0x60F018 table are, so what parameter this
;          edits; what (0x28B0)'s bits are called; why bit 3 substitutes the
;          0x2030 list for the write-back instead of doing both.
; ---------------------------------------------------------------------
IndexedParam_AdjustField:
	.byte 0xEE, 0x0C, 0xF5, 0xFF	; F5535B  link XIZ,0xfff5   [llvm-mc cannot encode this]
	pushw	hl	; F5535F  push HL
	pushw	de	; F55360  push DE
	push	xix	; F55361  push XIX
	ld	xix, (xiz+10)	; F55362  ld XIX,(XIZ+0x0a)
	.byte 0xF1, 0x75, 0x20, 0xBB	; F55365  set 3,(0x2075)   [llvm-mc cannot encode this]
	ld	c, (xix+7)	; F55369  ld C,(XIX+0x07)
	xordm8	(10416), c	; F5536C  xor (0x28b0),C
	ldb_d8	c, (10416)	; F55370  ld C,(0x28b0)
	and	c, 16	; F55374  and C,0x10
	jr	z, 4	; F55377  jr Z,0xf5537d
	.byte 0x8E, 0x08, 0x38, 0x20	; F55379  add (XIZ+0x08),0x20   [llvm-mc cannot encode this]
	push	0	; F5537D  push 0x00
	.byte 0x8E, 0x08, 0x04	; F5537F  push (XIZ+0x08)   [llvm-mc cannot encode this]
	calr	65436	; F55382  calr 0xf55321
	ld	(xiz-11), xiy	; F55385  ld (XIZ+0xf5),XIY
	ld	c, (xix)	; F55388  ld C,(XIX)
	extz	bc	; F5538A  extz BC
	extz	xbc	; F5538C  extz XBC
	add	xiy, xbc	; F5538E  add XIY,XBC
	ld	(xiz-6), xiy	; F55390  ld (XIZ+0xfa),XIY
	ld	e, (xiy)	; F55393  ld E,(XIY)
	ld	c, (xix+1)	; F55395  ld C,(XIX+0x01)
	ld	d, c	; F55398  ld D,C
	and	d, e	; F5539A  and D,E
	ldb	l, 0	; F5539C  ld L,0x00
	ld	h, (xix+2)	; F5539E  ld H,(XIX+0x02)
	popw	bc	; F553A1  pop BC
	cp	l, h	; F553A2  cp L,H
	jr	nc, 11	; F553A4  jr NC,0xf553b1
	ld	c, d	; F553A6  ld C,D
	srl	c, 1	; F553A8  srl 0x01,C
	ld	d, c	; F553AB  ld D,C
	inc	1, l	; F553AD  inc 1,L
	jr	-15	; F553AF  jr T,0xf553a2
	ld	h, d	; F553B1  ld H,D
	ldb_d8	c, (10416)	; F553B3  ld C,(0x28b0)
	and	c, 4	; F553B7  and C,0x04
	jr	z, 5	; F553BA  jr Z,0xf553c1
	ld	l, (xix+6)	; F553BC  ld L,(XIX+0x06)
	jr	14	; F553BF  jr T,0xf553cf
	ldb	l, 1	; F553C1  ld L,0x01
	ldb_d8	c, (8309)	; F553C3  ld C,(0x2075)
	and	c, 4	; F553C7  and C,0x04
	jr	z, 3	; F553CA  jr Z,0xf553cf
	ld	l, (xix+5)	; F553CC  ld L,(XIX+0x05)
	ldb_d8	c, (10416)	; F553CF  ld C,(0x28b0)
	and	c, 1	; F553D3  and C,0x01
	jr	z, 29	; F553D6  jr Z,0xf553f5
	ld	e, (xix+4)	; F553D8  ld E,(XIX+0x04)
	ld	c, e	; F553DB  ld C,E
	add	c, l	; F553DD  add C,L
	ld	(xiz-7), c	; F553DF  ld (XIZ+0xf9),C
	cp	h, c	; F553E2  cp H,C
	jr	c, 10	; F553E4  jr C,0xf553f0
	cp	c, e	; F553E6  cp C,E
	jr	ule, 6	; F553E8  jr ULE,0xf553f0
	ld	a, l	; F553EA  ld A,L
	sub	h, a	; F553EC  sub H,A
	jr	35	; F553EE  jr T,0xf55413
	ld	h, (xix+4)	; F553F0  ld H,(XIX+0x04)
	jr	30	; F553F3  jr T,0xf55413
	ld	c, (xix+3)	; F553F5  ld C,(XIX+0x03)
	ld	(xiz-1), c	; F553F8  ld (XIZ+0xff),C
	ld	e, c	; F553FB  ld E,C
	sub	c, l	; F553FD  sub C,L
	ld	e, c	; F553FF  ld E,C
	cp	h, c	; F55401  cp H,C
	jr	ugt, 11	; F55403  jr UGT,0xf55410
	.byte 0x8E, 0xFF, 0xF3	; F55405  cp C,(XIZ+0xff)   [llvm-mc cannot encode this]
	jr	nc, 6	; F55408  jr NC,0xf55410
	ld	c, l	; F5540A  ld C,L
	add	h, c	; F5540C  add H,C
	jr	3	; F5540E  jr T,0xf55413
	ld	h, (xix+3)	; F55410  ld H,(XIX+0x03)
	cp	h, d	; F55413  cp H,D
	jr	z, 94	; F55415  jr Z,0xf55475
	ldb	l, 0	; F55417  ld L,0x00
	ld	d, (xix+2)	; F55419  ld D,(XIX+0x02)
	cp	l, d	; F5541C  cp L,D
	jr	nc, 10	; F5541E  jr NC,0xf5542a
	ld	c, h	; F55420  ld C,H
	add	c, h	; F55422  add C,H
	ld	h, c	; F55424  ld H,C
	inc	1, l	; F55426  inc 1,L
	jr	-14	; F55428  jr T,0xf5541c
	ld	l, (xix+1)	; F5542A  ld L,(XIX+0x01)
	ld	c, l	; F5542D  ld C,L
	and	h, c	; F5542F  and H,C
	ldb_d8	a, (10416)	; F55431  ld A,(0x28b0)
	and	a, 8	; F55435  and A,0x08
	jr	z, 18	; F55438  jr Z,0xf5544c
	pushw	bc	; F5543A  push BC
	push	0	; F5543B  push 0x00
	push	h	; F5543D  push H
	ld	c, (xix)	; F5543F  ld C,(XIX)
	pushw	bc	; F55441  push BC
	push	0	; F55442  push 0x00
	.byte 0x8E, 0x08, 0x04	; F55444  push (XIZ+0x08)   [llvm-mc cannot encode this]
	calr	65154	; F55447  calr 0xf552cc
	jr	39	; F5544A  jr T,0xf55473
	ld	c, l	; F5544C  ld C,L
	cpl	c	; F5544E  cpl C
	ld	l, c	; F55450  ld L,C
	ld	xbc, (xiz-6)	; F55452  ld XBC,(XIZ+0xfa)
	and	(xbc), l	; F55455  and (XBC),L
	ld	xbc, (xiz-6)	; F55457  ld XBC,(XIZ+0xfa)
	ld	a, (xbc)	; F5545A  ld A,(XBC)
	or	a, h	; F5545C  or A,H
	ld	(xbc), a	; F5545E  ld (XBC),A
	ld	c, (xix+1)	; F55460  ld C,(XIX+0x01)
	pushw	bc	; F55463  push BC
	push	0	; F55464  push 0x00
	push	h	; F55466  push H
	ld	c, (xix)	; F55468  ld C,(XIX)
	pushw	bc	; F5546A  push BC
	push	0	; F5546B  push 0x00
	.byte 0x8E, 0x08, 0x04	; F5546D  push (XIZ+0x08)   [llvm-mc cannot encode this]
	calr	64958	; F55470  calr 0xf55231
	inc	8, xsp	; F55473  inc 0,XSP
	pop	xix	; F55475  pop XIX
	popw	de	; F55476  pop DE
	popw	hl	; F55477  pop HL
	.byte 0xEE, 0x0D	; F55478  unlk XIZ   [llvm-mc cannot encode this]
	ret	; F5547A  ret

; ---------------------------------------------------------------------
; IndexedParam_SetBit -- set or clear one flag field of an indexed object and
;                        journal the change
; Called from: thunk T_F42C98 (0xF42C98), 35 opcode-anchored references -- the
;          busiest of this group
; Inputs:  (XIZ+0x08) = the 16-bit index; (XIZ+0x0A) = the 8-byte descriptor.
;          Only +0 (byte offset), +1 (mask) and +2 (XORed into (0x28B0)) are
;          used -- there is no shift, no bound and no step, because there is no
;          arithmetic.
; Outputs: the masked bits of the target byte are forced on or off; a journal
;          record is appended; nothing happens if the byte did not change
;          (`ld L,(XBC) / cp L,D / jr Z` at 0xF554DA).
; Evidence: the same `calr 0xF55321` + descriptor-+0 resolution as
;          IndexedParam_AdjustField, then two mirrored arms selected by bit 0 of
;          (0x28B0): the set arm tests `and C,D / jr NZ` and `or D,C`, the clear
;          arm tests `and C,D / jr Z` and `cpl C / and D,C`.  Each arm first
;          checks whether the bits are already in the wanted state, which is why
;          this is "force to a state", not "toggle".
;          The POLARITY matches IndexedParam_AdjustField's: bit 0 of (0x28B0)
;          CLEAR reaches the arm at 0xF554CA that SETS the bits, and bit 0 SET
;          reaches 0xF554B9, which clears them -- the same sense in which bit 0
;          clear means "up" and set means "down" for the numeric editor.
;          ⚠ Note the descriptor byte XORed into (0x28B0) here is +2
;          (`ld C,(XIX+0x02)` at 0xF55488), NOT the +7 that sub_F550A6 and
;          IndexedParam_AdjustField use.  Read from the bytes, not assumed.
; Notes:   the bit-3 (0x28B0) path calls List2030_Append4 TWICE, once with the
;          value D and once with 0x0000, and releases 16 bytes with two
;          `inc 0,XSP`.  The other path writes the byte and appends one
;          Queue2C00_Append4 record.  Some argument slots carry register residue
;          in their high byte (e.g. (0x28B0)&8 rides along in W at 0xF554F0);
;          that is harmless because the appenders read only the low byte of each
;          16-bit slot, as their own headers record.
; Unknown:  the same three gaps as the routine above.
; ---------------------------------------------------------------------
IndexedParam_SetBit:
	.byte 0xEE, 0x0C, 0xF8, 0xFF	; F5547B  link XIZ,0xfff8   [llvm-mc cannot encode this]
	pushw	hl	; F5547F  push HL
	pushw	de	; F55480  push DE
	push	xix	; F55481  push XIX
	ld	xix, (xiz+10)	; F55482  ld XIX,(XIZ+0x0a)
	ld	e, (xiz+8)	; F55485  ld E,(XIZ+0x08)
	ld	c, (xix+2)	; F55488  ld C,(XIX+0x02)
	xordm8	(10416), c	; F5548B  xor (0x28b0),C
	ldb_d8	c, (10416)	; F5548F  ld C,(0x28b0)
	and	c, 16	; F55493  and C,0x10
	jr	z, 3	; F55496  jr Z,0xf5549b
	add	e, 32	; F55498  add E,0x20
	pushw	de	; F5549B  push DE
	calr	65154	; F5549C  calr 0xf55321
	ld	(xiz-8), xiy	; F5549F  ld (XIZ+0xf8),XIY
	ld	c, (xix)	; F554A2  ld C,(XIX)
	extz	bc	; F554A4  extz BC
	extz	xbc	; F554A6  extz XBC
	add	xiy, xbc	; F554A8  add XIY,XBC
	ld	(xiz-4), xiy	; F554AA  ld (XIZ+0xfc),XIY
	ld	d, (xiy)	; F554AD  ld D,(XIY)
	ldb_d8	c, (10416)	; F554AF  ld C,(0x28b0)
	and	c, 1	; F554B3  and C,0x01
	popw	wa	; F554B6  pop WA
	jr	z, 17	; F554B7  jr Z,0xf554ca
	ld	h, (xix+1)	; F554B9  ld H,(XIX+0x01)
	ld	c, h	; F554BC  ld C,H
	and	c, d	; F554BE  and C,D
	jr	z, 21	; F554C0  jr Z,0xf554d7
	ld	c, h	; F554C2  ld C,H
	cpl	c	; F554C4  cpl C
	and	d, c	; F554C6  and D,C
	jr	13	; F554C8  jr T,0xf554d7
	ld	h, (xix+1)	; F554CA  ld H,(XIX+0x01)
	ld	c, h	; F554CD  ld C,H
	and	c, d	; F554CF  and C,D
	jr	nz, 4	; F554D1  jr NZ,0xf554d7
	ld	c, h	; F554D3  ld C,H
	or	d, c	; F554D5  or D,C
	ld	xbc, (xiz-4)	; F554D7  ld XBC,(XIZ+0xfc)
	ld	l, (xbc)	; F554DA  ld L,(XBC)
	cp	l, d	; F554DC  cp L,D
	jr	z, 89	; F554DE  jr Z,0xf55539
	ld	h, (xix+1)	; F554E0  ld H,(XIX+0x01)
	ld	a, h	; F554E3  ld A,H
	and	d, a	; F554E5  and D,A
	ldb_d8	w, (10416)	; F554E7  ld W,(0x28b0)
	and	w, 8	; F554EB  and W,0x08
	jr	z, 32	; F554EE  jr Z,0xf55510
	pushw	wa	; F554F0  push WA
	push	0	; F554F1  push 0x00
	push	d	; F554F3  push D
	ld	a, (xix)	; F554F5  ld A,(XIX)
	pushw	wa	; F554F7  push WA
	pushw	de	; F554F8  push DE
	calr	64976	; F554F9  calr 0xf552cc
	ld	c, (xix+1)	; F554FC  ld C,(XIX+0x01)
	pushw	bc	; F554FF  push BC
	pushw	0	; F55500  push 0x0000
	ld	c, (xix)	; F55503  ld C,(XIX)
	pushw	bc	; F55505  push BC
	pushw	de	; F55506  push DE
	calr	64962	; F55507  calr 0xf552cc
	inc	8, xsp	; F5550A  inc 0,XSP
	inc	8, xsp	; F5550C  inc 0,XSP
	jr	41	; F5550E  jr T,0xf55539
	ld	c, h	; F55510  ld C,H
	cpl	c	; F55512  cpl C
	ld	h, c	; F55514  ld H,C
	and	h, l	; F55516  and H,L
	ld	xbc, (xiz-4)	; F55518  ld XBC,(XIZ+0xfc)
	ld	(xbc), h	; F5551B  ld (XBC),H
	ld	c, d	; F5551D  ld C,D
	or	c, h	; F5551F  or C,H
	ld	h, c	; F55521  ld H,C
	ld	xbc, (xiz-4)	; F55523  ld XBC,(XIZ+0xfc)
	ld	(xbc), h	; F55526  ld (XBC),H
	ld	c, (xix+1)	; F55528  ld C,(XIX+0x01)
	pushw	bc	; F5552B  push BC
	push	0	; F5552C  push 0x00
	push	d	; F5552E  push D
	ld	c, (xix)	; F55530  ld C,(XIX)
	pushw	bc	; F55532  push BC
	pushw	de	; F55533  push DE
	calr	64762	; F55534  calr 0xf55231
	inc	8, xsp	; F55537  inc 0,XSP
	pop	xix	; F55539  pop XIX
	popw	de	; F5553A  pop DE
	popw	hl	; F5553B  pop HL
	.byte 0xEE, 0x0D	; F5553C  unlk XIZ   [llvm-mc cannot encode this]
	ret	; F5553E  ret

; --- 0xF5553F-0xF5B8B5: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x05553F, 0x006377


; ==============================================================================
; 0xF5B8B6-0xF5BAB7 -- TWO SELECTOR DISPATCHERS AND THEIR 48-ENTRY TABLES
; ==============================================================================
;
; Both are reached through the thunk table and are among the busiest slots in it:
; T_F41ED0 -> 0xF5B8B6 (opcode-anchored upper bound 39 references) and
; T_F41ED4 -> 0xF5B9B8 (109), ranked by
; `python3 scripts/analysis/prom_b_thunk_table.py --census`.
;
; Both take a 16-bit selector on the stack and index a table of 32-bit routine
; pointers with it:
;
;     code = (XIZ+8)
;     if code >= 0xC0:  entry = table_hi[code - 0xC0]
;     else:             entry = table_lo[code - 0x80]
;     call entry
;
; and `table_hi` is `table_lo + 0x80`, so codes 0xC0.. land on the SAME entries as
; codes 0xA0.., 16 of them, before running off the end of the table.
;
; TABLE SIZE IS PROVEN BY ABUTMENT, not by the 0xC0 bound:
;   0xF5B8F8 + 48*4 = 0xF5B9B8, exactly the `push XIZ` that starts the second
;                     dispatcher;
;   0xF5B9F8 + 48*4 = 0xF5BAB8, exactly a `push XWA/XBC/XDE/XHL/XIX/XIY/XIZ`
;                     register-save prologue.
;   All 96 entries are 0x00F00000-0x00FFFFFF; the first word past each table is
;   not (0x3B3A3938 and 0x5B5C5D5E -- both are push/pop opcode runs).
; Reproduce every line of that with
;     python3 notes/prom_b_dispatch_tables.py
;
; 0xF5BF17 is a bare `ret` (byte 0x0E): it is the DEFAULT entry, and it fills 6
; slots of the first table and 7 of the second.  41 of the first table's 48
; entries and 35 of the second's are distinct.
;
; ⚠ WHAT THE SELECTOR MEANS IS NOT ESTABLISHED.  It is a 16-bit value >= 0x80
; passed by the caller; nothing here says whether it is a screen id, a panel
; event or a message opcode.  The name below describes the mechanism only.
; ==============================================================================

; ---------------------------------------------------------------------
; Dispatch_Code80_Bracketed -- run selector table entry, bracketed by two
;                              display service calls
; Called from: thunk T_F41ED0 (0xF41ED0), 39 opcode-anchored references
; Inputs:  (XIZ+8) = 16-bit selector, >= 0x80
; Outputs: whatever the selected routine does; all registers restored
; Evidence: the `sub HL,0xC0 / ld XIY,0x00F5B978` and `sub HL,0x80 /
;           ld XIY,0x00F5B8F8` pair, then `sla 2,HL`, `ld XIY,(XIY+HL)`,
;           `call XIY`.  The bracket is `call 0xF5BF18` before and
;           `call 0xF5BF21` after; 0xF5BF18 is `ld C,0 / ld A,0x0C / swi 7 /
;           ld A,0x10 / swi 7` and 0xF5BF21 is `ld C,7 / ld A,0x0C / swi 7` --
;           the same services 0x0C (argument in C, 0 or 7 seen) and 0x10 that
;           sub_F31852 and sub_F31863 in the interpreter block issue.
; Unknown:  what the selector enumerates; what services 0x0C and 0x10 do.
; ---------------------------------------------------------------------
Dispatch_Code80_Bracketed:
	push	xiz	; F5B8B6  push XIZ
	ld	xiz, xsp	; F5B8B7  ld XIZ,XSP
	push	xwa	; F5B8B9  push XWA
	push	xbc	; F5B8BA  push XBC
	push	xde	; F5B8BB  push XDE
	push	xhl	; F5B8BC  push XHL
	push	xix	; F5B8BD  push XIX
	push	xiy	; F5B8BE  push XIY
	ld	hl, (xiz+8)	; F5B8BF  ld HL,(XIZ+0x08)
	cp	hl, 192	; F5B8C2  cp HL,0x00c0
	jr	c, 11	; F5B8C6  jr C,0xf5b8d3
	sub	hl, 192	; F5B8C8  sub HL,0x00c0
	ld	xiy, 16103800	; F5B8CC  ld XIY,0x00f5b978
	jr	9	; F5B8D1  jr T,0xf5b8dc
	sub	hl, 128	; F5B8D3  sub HL,0x0080
	ld	xiy, 16103672	; F5B8D7  ld XIY,0x00f5b8f8
	sla	hl, 2	; F5B8DC  sla 0x02,HL
	.byte 0xE3, 0x07, 0xF4, 0xEC, 0x25	; F5B8DF  ld XIY,(XIY+HL)   [llvm-mc cannot encode this]
	push	xiy	; F5B8E4  push XIY
	call	16105240	; F5B8E5  call 0xf5bf18
	pop	xiy	; F5B8E9  pop XIY
	call	(xiy)	; F5B8EA  call T,XIY
	call	16105249	; F5B8EC  call 0xf5bf21
	pop	xiy	; F5B8F0  pop XIY
	pop	xix	; F5B8F1  pop XIX
	pop	xhl	; F5B8F2  pop XHL
	pop	xde	; F5B8F3  pop XDE
	pop	xbc	; F5B8F4  pop XBC
	pop	xwa	; F5B8F5  pop XWA
	pop	xiz	; F5B8F6  pop XIZ
	ret	; F5B8F7  ret

; --- 0xF5B8F8: 48 entries, one per selector 0x80..0xAF.  Ends exactly on the
;     next routine's first byte.  Entries for 0xC0.. re-use 0xA0.. ------------
DispatchTable_F5B8F8:
	.long 0x00F5BF27	; [0x80]
	.long 0x00F5BF17	; [0x81]   (default `ret`)
	.long 0x00F5C2A8	; [0x82]
	.long 0x00F5D40E	; [0x83]
	.long 0x00F5D4C3	; [0x84]
	.long 0x00F5D519	; [0x85]
	.long 0x00F5C06C	; [0x86]
	.long 0x00F5C4D1	; [0x87]
	.long 0x00F5D55F	; [0x88]
	.long 0x00F5D57A	; [0x89]
	.long 0x00F5C513	; [0x8A]
	.long 0x00F5C6BE	; [0x8B]
	.long 0x00F5C749	; [0x8C]
	.long 0x00F5C79E	; [0x8D]
	.long 0x00F5C876	; [0x8E]
	.long 0x00F5D622	; [0x8F]
	.long 0x00F5C8CB	; [0x90]
	.long 0x00F5C983	; [0x91]
	.long 0x00F5C9CE	; [0x92]
	.long 0x00F5CA19	; [0x93]
	.long 0x00F5CA64	; [0x94]
	.long 0x00F5CAA1	; [0x95]
	.long 0x00F5D583	; [0x96]
	.long 0x00F5CACB	; [0x97]
	.long 0x00F5D5C4	; [0x98]
	.long 0x00F5D619	; [0x99]
	.long 0x00F099F5	; [0x9A]
	.long 0x00F0985C	; [0x9B]
	.long 0x00F5BF17	; [0x9C]   (default `ret`)
	.long 0x00F09B9B	; [0x9D]
	.long 0x00F5D14E	; [0x9E]
	.long 0x00F5D1E8	; [0x9F]
	.long 0x00F5BFC7	; [0xA0]  <- also selector 0xC0
	.long 0x00F5C2A8	; [0xA1]  <- also selector 0xC1
	.long 0x00F5C06C	; [0xA2]  <- also selector 0xC2
	.long 0x00F5C09E	; [0xA3]  <- also selector 0xC3
	.long 0x00F5C0D4	; [0xA4]  <- also selector 0xC4
	.long 0x00F5C10A	; [0xA5]  <- also selector 0xC5
	.long 0x00F5C172	; [0xA6]  <- also selector 0xC6
	.long 0x00F5C1AC	; [0xA7]  <- also selector 0xC7
	.long 0x00F5C210	; [0xA8]  <- also selector 0xC8
	.long 0x00F5BF17	; [0xA9]   (default `ret`)  <- also selector 0xC9
	.long 0x00F5D29A	; [0xAA]  <- also selector 0xCA
	.long 0x00F5D29B	; [0xAB]  <- also selector 0xCB
	.long 0x00F5BF17	; [0xAC]   (default `ret`)  <- also selector 0xCC
	.long 0x00F09800	; [0xAD]  <- also selector 0xCD
	.long 0x00F5BF17	; [0xAE]   (default `ret`)  <- also selector 0xCE
	.long 0x00F5BF17	; [0xAF]   (default `ret`)  <- also selector 0xCF

; ---------------------------------------------------------------------
; Dispatch_Code80 -- the same selector table mechanism, no display bracket
; Called from: thunk T_F41ED4 (0xF41ED4), 109 opcode-anchored references -- the
;              busiest prom_b-resident slot in the thunk table after the two
;              display-list interpreters
; Inputs:  (XIZ+8) = 16-bit selector >= 0x80; (XIZ+0x0A) = a byte loaded into A
;          and left there for the selected routine
; Outputs: sets bit 3 of (0x2075) after the call; all registers restored
; Evidence: identical index arithmetic against 0xF5B9F8 / 0xF5BA78; the extra
;           `ld A,(XIZ+0x0A)` at 0xF5B9C4 is the only argument difference, and
;           `or (0x2075),0x08` at 0xF5B9EB is the only side effect.
; Unknown:  what the selector enumerates; what bit 3 of 0x2075 means.
; ---------------------------------------------------------------------
Dispatch_Code80:
	push	xiz	; F5B9B8  push XIZ
	ld	xiz, xsp	; F5B9B9  ld XIZ,XSP
	push	xwa	; F5B9BB  push XWA
	push	xbc	; F5B9BC  push XBC
	push	xde	; F5B9BD  push XDE
	push	xhl	; F5B9BE  push XHL
	push	xix	; F5B9BF  push XIX
	push	xiy	; F5B9C0  push XIY
	ld	hl, (xiz+8)	; F5B9C1  ld HL,(XIZ+0x08)
	ld	a, (xiz+10)	; F5B9C4  ld A,(XIZ+0x0a)
	cp	hl, 192	; F5B9C7  cp HL,0x00c0
	jr	c, 11	; F5B9CB  jr C,0xf5b9d8
	sub	hl, 192	; F5B9CD  sub HL,0x00c0
	ld	xiy, 16104056	; F5B9D1  ld XIY,0x00f5ba78
	jr	9	; F5B9D6  jr T,0xf5b9e1
	sub	hl, 128	; F5B9D8  sub HL,0x0080
	ld	xiy, 16103928	; F5B9DC  ld XIY,0x00f5b9f8
	sla	hl, 2	; F5B9E1  sla 0x02,HL
	.byte 0xE3, 0x07, 0xF4, 0xEC, 0x25	; F5B9E4  ld XIY,(XIY+HL)   [llvm-mc cannot encode this]
	call	(xiy)	; F5B9E9  call T,XIY
	.byte 0xC1, 0x75, 0x20, 0x3E, 0x08	; F5B9EB  or (0x2075),0x08   [llvm-mc cannot encode this]
	pop	xiy	; F5B9F0  pop XIY
	pop	xix	; F5B9F1  pop XIX
	pop	xhl	; F5B9F2  pop XHL
	pop	xde	; F5B9F3  pop XDE
	pop	xbc	; F5B9F4  pop XBC
	pop	xwa	; F5B9F5  pop XWA
	pop	xiz	; F5B9F6  pop XIZ
	ret	; F5B9F7  ret

; --- 0xF5B9F8: 48 entries, one per selector 0x80..0xAF ---------------------
DispatchTable_F5B9F8:
	.long 0x00F09CA9	; [0x80]
	.long 0x00F5BF17	; [0x81]   (default `ret`)
	.long 0x00F5CE65	; [0x82]
	.long 0x00F5D62B	; [0x83]
	.long 0x00F5D6AC	; [0x84]
	.long 0x00F5D6D4	; [0x85]
	.long 0x00F5CC3D	; [0x86]
	.long 0x00F5CEB2	; [0x87]
	.long 0x00F5D126	; [0x88]
	.long 0x00F5D6FC	; [0x89]
	.long 0x00F5CEF6	; [0x8A]
	.long 0x00F5CFD7	; [0x8B]
	.long 0x00F5D05B	; [0x8C]
	.long 0x00F5D06A	; [0x8D]
	.long 0x00F5D09F	; [0x8E]
	.long 0x00F5CEF6	; [0x8F]
	.long 0x00F5D0AE	; [0x90]
	.long 0x00F5D0D1	; [0x91]
	.long 0x00F5D0F9	; [0x92]
	.long 0x00F5D108	; [0x93]
	.long 0x00F5D117	; [0x94]
	.long 0x00F5BF17	; [0x95]   (default `ret`)
	.long 0x00F5D05B	; [0x96]
	.long 0x00F5D126	; [0x97]
	.long 0x00F5D6FC	; [0x98]
	.long 0x00F5CEF6	; [0x99]
	.long 0x00F09AA5	; [0x9A]
	.long 0x00F09961	; [0x9B]
	.long 0x00F5BF17	; [0x9C]   (default `ret`)
	.long 0x00F09C08	; [0x9D]
	.long 0x00F5D2E9	; [0x9E]
	.long 0x00F5D313	; [0x9F]
	.long 0x00F5CB1E	; [0xA0]  <- also selector 0xC0
	.long 0x00F5CE65	; [0xA1]  <- also selector 0xC1
	.long 0x00F5CC3D	; [0xA2]  <- also selector 0xC2
	.long 0x00F5CCF6	; [0xA3]  <- also selector 0xC3
	.long 0x00F5CD1E	; [0xA4]  <- also selector 0xC4
	.long 0x00F5CD46	; [0xA5]  <- also selector 0xC5
	.long 0x00F5CDA8	; [0xA6]  <- also selector 0xC6
	.long 0x00F5CDD4	; [0xA7]  <- also selector 0xC7
	.long 0x00F5CE00	; [0xA8]  <- also selector 0xC8
	.long 0x00F5BF17	; [0xA9]   (default `ret`)  <- also selector 0xC9
	.long 0x00F5D40D	; [0xAA]  <- also selector 0xCA
	.long 0x00F5D2D5	; [0xAB]  <- also selector 0xCB
	.long 0x00F5BF17	; [0xAC]   (default `ret`)  <- also selector 0xCC
	.long 0x00F098FB	; [0xAD]  <- also selector 0xCD
	.long 0x00F5BF17	; [0xAE]   (default `ret`)  <- also selector 0xCE
	.long 0x00F5BF17	; [0xAF]   (default `ret`)  <- also selector 0xCF

; --- 0xF5BAB8-0xF77FFF: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x05BAB8, 0x01C548

; ------------------------------------------------------------------
; DLB_RecordTemplate_Op02 / DLB_RecordTemplate_Op07 -- the two interpreter-B
; display-list records the field-blink engine copies to the stack and patches
;
; Read by:  prom_b 0xF0E933 (`lda XIY,0xf78000`, then `ldir` BC = 0x0F) and
;           prom_b 0xF0E985 (`lda XIY,0xf7800f`, then `ldir` BC = 0x11).
;           Nothing else in prom_a or prom_b loads either address.
; Layout:   interpreter B's record, the same layout the static op-02 records
;           above carry (+0 opcode, +1 total length, +2..3 source variable,
;           +4 AND mask, +5 shift, +6 swi 7 function, +7 32-bit table pointer,
;           +0x0B bytes per entry, +0x0D word; op 07 adds a second word at +0x0F).
; Extent:   15 and 17 bytes, from the `ldir` counts the copier uses (0x0F at
;           0xF0E930, 0x11 at 0xF0E982) and from the fields interpreter B's own
;           handlers touch (0xF31B21 -> 15, 0xF31B39 -> 17; the per-handler
;           table is in notes/prom_b_dl_length_audit.py's docstring).
;           15 + 17 = 32, so the pair ends exactly on DLB_BlankField_8.
;
; ⚠ THE SECOND TEMPLATE'S OWN LENGTH BYTE DISAGREES, AND IT DOES NOT MATTER.
;           0xF78010 is 0x0F = 15, not the 17 the record actually occupies.  A
;           first draft of this header claimed "three ways agree" and wrote 0x11
;           there; the build gate rejected it, which is the only reason the
;           claim is not still sitting here looking plausible.
;           Why it is harmless: these records are never FRAMED.  The copier
;           calls DisplayListB_RunOne_Stack (0xF3183D), which sets the end
;           pointer to XIY + 1, so interpreter B's `cp XIX,XIY / jr ULE` lets
;           exactly one record run and then exits.  The length byte is used only
;           to advance XIY past the record, and any value >= 1 ends the loop.
;           Nothing walks from this record to a next one, so nothing reads it.
;           This is also NOT a counterexample to "494 interpreter-B records, 0
;           disagree": that audit walks records reachable from
;           `ld XIY,imm32 / ld XIX,imm32 / call 0xF417F0|0xF417F4` call sites,
;           and these two are reached by neither -- they are copied, not run in
;           place.
; Note:     fields +2, +4 and +5 are zero and the copier never patches them, so
;           the extracted index is always 0 and the record renders entry 0.
; ------------------------------------------------------------------
DLB_RecordTemplate_Op02:
	.byte 0x02, 0x0F	; +0 opcode 0x02 -> DLB_Handler_StringTable ; +1 len 15
	.short 0x0000		; +0x02 source variable, 16-bit address (never patched)
	.byte 0x00		; +0x04 AND mask (never patched)
	.byte 0x00		; +0x05 right shift, low 3 bits (never patched)
	.byte 0x20		; +0x06 swi 7 function -- patched from (0x28C9)
	.long 0x000028C0	; +0x07 -> XIY: the text.  Replaced with
				;          DLB_BlankField_8 when the argument is 0
	.short 0x0003		; +0x0B -> BC: bytes per entry -- patched from (0x28D0)
	.short 0x0000		; +0x0D -> IX -- patched from (0x28CA)

DLB_RecordTemplate_Op07:
	.byte 0x07, 0x0F	; +0 opcode 0x07 -> DLB_Handler_StringTable2
				; +1 length 15 -- WRONG for a 17-byte record; see
				;    the header.  Never read: run-one framing.
	; NOTE the two `.byte 0x02, 0x0F` / `0x07, 0x0F` pairs are NOT a typo
	; repeated: op 02 really is 15 bytes long, op 07 really is 17.
	.short 0x0000		; +0x02 source variable, 16-bit address (never patched)
	.byte 0x00		; +0x04 AND mask (never patched)
	.byte 0x00		; +0x05 right shift, low 3 bits (never patched)
	.byte 0x20		; +0x06 swi 7 function -- patched from (0x28C9)
	.long 0x000028C0	; +0x07 -> XIY: the text, as above
	.short 0x0003		; +0x0B -> BC: bytes per entry -- patched from (0x28D0)
	.short 0x0000		; +0x0D -> IX -- patched from (0x28CC)
	.short 0x0000		; +0x0F -> the second word -- patched from (0x28CE)

; ------------------------------------------------------------------
; DLB_BlankField_8 -- the eight spaces the blink engine draws to erase the field
; Read by:  prom_b 0xF0E961 and 0xF0E9B8 (`lda XBC,0xf78020`), each guarded by
;           `cp (XIZ+0x08),0x00 / jr NZ` -- i.e. taken only when the caller
;           asked for the BLANK half of the blink.  The address is then stored
;           into the copied record's +7 field, replacing the text pointer.
; Extent:   the run of 0x20 bytes starts at 0xF78020 and ends at 0xF78027; the
;           byte at 0xF78028 is 0x00.  ⚠ That is a measurement of the RUN, not
;           of the object: how many of these bytes are actually drawn is set at
;           run time by the record's +0x0B field, which the copier patches from
;           (0x28D0), and this tree cannot read (0x28D0) statically.  Eight is
;           therefore an upper bound on the blank width, not the width.
; ------------------------------------------------------------------
DLB_BlankField_8:
	.ascii "        "	; 0xF78020-0xF78027, eight ASCII spaces
	.byte 0x00		; 0xF78028

; --- 0xF78029-0xF7CFFF: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x078029, 0x004FD7

; ==============================================================================
; 0xF7D000-0xF7E2D7 -- A STUB BLOCK AND 32 TABLES OF 32 ROUTINE POINTERS
; ==============================================================================
;
; 728 bytes of stubs, then 4,096 bytes that are exactly 32 tables of 32 32-bit
; routine pointers.  Two of the thunk table's busier slots name entries 0 and 2
; of the veneer table: T_F431B0 -> 0xF7D000 (53 opcode-anchored references) and
; T_F431B4 -> 0xF7D006 (57).  So the WSA1's routine directory reaches prom_a
; 0xF81ACB and 0xF81C15 through TWO levels of veneer.
;
; THE STUBS come in three shapes, and nothing else:
;   * 0xF7D000-0xF7D017: eight `jrl T,nnn` long-branch veneers, 3 bytes each,
;     every one into prom_a 0xF81ACB-0xF81E7E.  A linker branch island.
;   * `calr`/`call <routine>` followed by `ret` -- a one-line forwarder.
;   * `ld XIX,<one of the 32 tables>` (sometimes choosing between two on
;     `cp (0x207E),0x00` or `cp (0x0C10),0x00`), then `call 0xF41B08`, then `ret`.
;
; WHY THE TABLES ARE 32 ENTRIES.  T_F41B08 -> prom_a 0xF8BDC5, which is
;     cp HL,0x1F / jr UGT,<ret> / ... / and L,0x1F / sla 2,L /
;     ld XIX,(XIX+L) / call XIX
; -- a bounds-checked call of entry HL of the table in XIX, with the index masked
; to 5 bits.  32 entries, 4 bytes each, 128 bytes per table.
;
; WHY THERE ARE EXACTLY 32 TABLES.  Three independent counts agree:
;   * scanning 0xF7D2D8 upward in 128-byte blocks, the first 32 blocks are
;     entirely 0x00F00000-0x00FFFFFF words and the 33rd (0xF7E2D8) is not --
;     its first word is 0x2100230E, and the bytes there disassemble as code;
;   * the stub block contains exactly 32 `ld XIX,imm32` instructions, and their
;     32 immediates are exactly the 32 table bases, each named once;
;   * the highest of those immediates is 0xF7E258 = 0xF7D2D8 + 31*0x80, the last
;     table, and 0xF7E258 + 0x80 = 0xF7E2D8 is where the block ends.
;
; ⚠ NOT ESTABLISHED: what the 32 tables enumerate, what the index HL is, and what
; (0x207E) and (0x0C10) select.  The names below are positional.
; ==============================================================================

; ---------------------------------------------------------------------
; StubBlock_F7D000 -- long-branch veneers and one-line forwarders
; Called from: thunks T_F431B0 (0xF7D000, x53) and T_F431B4 (0xF7D006, x57);
;              the rest not yet traced to a specific caller
; Inputs:  pass-through; the table stubs additionally expect HL = the index that
;          prom_a 0xF8BDC5 bounds-checks against 0x1F
; Outputs: pass-through
; Evidence: every instruction in these 728 bytes is one of `jrl`, `calr`, `call`,
;           `ret`, `ld XIX,imm32`, `cp (mem),0x00`, `jr Z` and one `ld BC,HL`.
;           Round-tripped through llvm-mc by notes/llvm_roundtrip_force.py:
;           260 instructions, 246 encoded, 14 left as .byte.
; Unknown:  what any individual stub selects.
; ---------------------------------------------------------------------
StubBlock_F7D000:
	jrl	19144	; F7D000  jrl T,0xf81acb
	jrl	19406	; F7D003  jrl T,0xf81bd4
	jrl	19468	; F7D006  jrl T,0xf81c15
	jrl	20080	; F7D009  jrl T,0xf81e7c
	jrl	19762	; F7D00C  jrl T,0xf81d41
	jrl	19489	; F7D00F  jrl T,0xf81c33
	jrl	19579	; F7D012  jrl T,0xf81c90
	jrl	20070	; F7D015  jrl T,0xf81e7e
	calr	6486	; F7D018  calr 0xf7e971
	ret	; F7D01B  ret
	calr	6493	; F7D01C  calr 0xf7e97c
	ret	; F7D01F  ret
	call	16256826	; F7D020  call 0xf80f3a
	ret	; F7D024  ret
	call	16256847	; F7D025  call 0xf80f4f
	ret	; F7D029  ret
	calr	6490	; F7D02A  calr 0xf7e987
	ret	; F7D02D  ret
	calr	6550	; F7D02E  calr 0xf7e9c7
	ret	; F7D031  ret
	ld	xix, 16241368	; F7D032  ld XIX,0x00f7d2d8
	.byte 0xC1, 0x10, 0x0C, 0x3F, 0x00	; F7D037  cp (0x0c10),0x00   [llvm-mc cannot encode this]
	jr	z, 5	; F7D03C  jr Z,0xf7d043
	ld	xix, 16241496	; F7D03E  ld XIX,0x00f7d358
	call	15997704	; F7D043  call 0xf41b08
	ret	; F7D047  ret
	calr	6666	; F7D048  calr 0xf7ea55
	ret	; F7D04B  ret
	calr	6785	; F7D04C  calr 0xf7ead0
	ret	; F7D04F  ret
	calr	7045	; F7D050  calr 0xf7ebd8
	ret	; F7D053  ret
	ld	xix, 16241624	; F7D054  ld XIX,0x00f7d3d8
	call	15997704	; F7D059  call 0xf41b08
	ret	; F7D05D  ret
	calr	7183	; F7D05E  calr 0xf7ec70
	ret	; F7D061  ret
	calr	7180	; F7D062  calr 0xf7ec71
	ret	; F7D065  ret
	calr	7313	; F7D066  calr 0xf7ecfa
	ret	; F7D069  ret
	ld	xix, 16241752	; F7D06A  ld XIX,0x00f7d458
	.byte 0xC1, 0x7E, 0x20, 0x3F, 0x00	; F7D06F  cp (0x207e),0x00   [llvm-mc cannot encode this]
	jr	z, 5	; F7D074  jr Z,0xf7d07b
	ld	xix, 16241880	; F7D076  ld XIX,0x00f7d4d8
	call	15997704	; F7D07B  call 0xf41b08
	ret	; F7D07F  ret
	calr	7556	; F7D080  calr 0xf7ee07
	ret	; F7D083  ret
	calr	5049	; F7D084  calr 0xf7e440
	ret	; F7D087  ret
	calr	5230	; F7D088  calr 0xf7e4f9
	ret	; F7D08B  ret
	ld	xix, 16242008	; F7D08C  ld XIX,0x00f7d558
	.byte 0xC1, 0x7E, 0x20, 0x3F, 0x00	; F7D091  cp (0x207e),0x00   [llvm-mc cannot encode this]
	jr	z, 5	; F7D096  jr Z,0xf7d09d
	ld	xix, 16242136	; F7D098  ld XIX,0x00f7d5d8
	call	15997704	; F7D09D  call 0xf41b08
	ret	; F7D0A1  ret
	calr	5467	; F7D0A2  calr 0xf7e600
	ret	; F7D0A5  ret
	calr	5464	; F7D0A6  calr 0xf7e601
	ret	; F7D0A9  ret
	calr	5581	; F7D0AA  calr 0xf7e67a
	ret	; F7D0AD  ret
	ld	xix, 16242264	; F7D0AE  ld XIX,0x00f7d658
	call	15997704	; F7D0B3  call 0xf41b08
	ret	; F7D0B7  ret
	calr	5812	; F7D0B8  calr 0xf7e76f
	ret	; F7D0BB  ret
	call	16248328	; F7D0BC  call 0xf7ee08
	ret	; F7D0C0  ret
	call	16248470	; F7D0C1  call 0xf7ee96
	ret	; F7D0C5  ret
	ld	xix, 16242392	; F7D0C6  ld XIX,0x00f7d6d8
	.byte 0xC1, 0x7E, 0x20, 0x3F, 0x00	; F7D0CB  cp (0x207e),0x00   [llvm-mc cannot encode this]
	jr	z, 5	; F7D0D0  jr Z,0xf7d0d7
	ld	xix, 16242520	; F7D0D2  ld XIX,0x00f7d758
	call	15997704	; F7D0D7  call 0xf41b08
	ret	; F7D0DB  ret
	ret	; F7D0DC  ret
	call	16248700	; F7D0DD  call 0xf7ef7c
	ret	; F7D0E1  ret
	call	16248881	; F7D0E2  call 0xf7f031
	ret	; F7D0E6  ret
	ld	xix, 16242648	; F7D0E7  ld XIX,0x00f7d7d8
	.byte 0xC1, 0x7E, 0x20, 0x3F, 0x00	; F7D0EC  cp (0x207e),0x00   [llvm-mc cannot encode this]
	jr	z, 5	; F7D0F1  jr Z,0xf7d0f8
	ld	xix, 16242776	; F7D0F3  ld XIX,0x00f7d858
	call	15997704	; F7D0F8  call 0xf41b08
	ret	; F7D0FC  ret
	ret	; F7D0FD  ret
	call	16249428	; F7D0FE  call 0xf7f254
	ret	; F7D102  ret
	call	16249557	; F7D103  call 0xf7f2d5
	ret	; F7D107  ret
	ld	xix, 16242904	; F7D108  ld XIX,0x00f7d8d8
	.byte 0xC1, 0x7E, 0x20, 0x3F, 0x00	; F7D10D  cp (0x207e),0x00   [llvm-mc cannot encode this]
	jr	z, 5	; F7D112  jr Z,0xf7d119
	ld	xix, 16243032	; F7D114  ld XIX,0x00f7d958
	call	15997704	; F7D119  call 0xf41b08
	ret	; F7D11D  ret
	ret	; F7D11E  ret
	call	16250166	; F7D11F  call 0xf7f536
	ret	; F7D123  ret
	call	16250200	; F7D124  call 0xf7f558
	ret	; F7D128  ret
	call	16250201	; F7D129  call 0xf7f559
	ret	; F7D12D  ret
	ret	; F7D12E  ret
	call	16250242	; F7D12F  call 0xf7f582
	ret	; F7D133  ret
	call	16250371	; F7D134  call 0xf7f603
	ret	; F7D138  ret
	ld	xix, 16243160	; F7D139  ld XIX,0x00f7d9d8
	.byte 0xC1, 0x7E, 0x20, 0x3F, 0x00	; F7D13E  cp (0x207e),0x00   [llvm-mc cannot encode this]
	jr	z, 5	; F7D143  jr Z,0xf7d14a
	ld	xix, 16243288	; F7D145  ld XIX,0x00f7da58
	call	15997704	; F7D14A  call 0xf41b08
	ret	; F7D14E  ret
	ret	; F7D14F  ret
	call	16251049	; F7D150  call 0xf7f8a9
	ret	; F7D154  ret
	call	16251215	; F7D155  call 0xf7f94f
	ret	; F7D159  ret
	ld	xix, 16243416	; F7D15A  ld XIX,0x00f7dad8
	.byte 0xC1, 0x7E, 0x20, 0x3F, 0x00	; F7D15F  cp (0x207e),0x00   [llvm-mc cannot encode this]
	jr	z, 5	; F7D164  jr Z,0xf7d16b
	ld	xix, 16243544	; F7D166  ld XIX,0x00f7db58
	call	15997704	; F7D16B  call 0xf41b08
	ret	; F7D16F  ret
	ret	; F7D170  ret
	call	16251896	; F7D171  call 0xf7fbf8
	ret	; F7D175  ret
	call	16252057	; F7D176  call 0xf7fc99
	ret	; F7D17A  ret
	ld	xix, 16243672	; F7D17B  ld XIX,0x00f7dbd8
	.byte 0xC1, 0x7E, 0x20, 0x3F, 0x00	; F7D180  cp (0x207e),0x00   [llvm-mc cannot encode this]
	jr	z, 5	; F7D185  jr Z,0xf7d18c
	ld	xix, 16243800	; F7D187  ld XIX,0x00f7dc58
	call	15997704	; F7D18C  call 0xf41b08
	ret	; F7D190  ret
	ret	; F7D191  ret
	call	16245749	; F7D192  call 0xf7e3f5
	ret	; F7D196  ret
	call	16245823	; F7D197  call 0xf7e43f
	ret	; F7D19B  ret
	cp	hl, 15	; F7D19C  cp HL,0x000f
	jr	z, 36	; F7D1A0  jr Z,0xf7d1c6
	cp	hl, 10	; F7D1A2  cp HL,0x000a
	jr	z, 6	; F7D1A6  jr Z,0xf7d1ae
	cp	hl, 11	; F7D1A8  cp HL,0x000b
	jr	nz, 37	; F7D1AC  jr NZ,0xf7d1d3
	ld	bc, hl	; F7D1AE  ld BC,HL
	call	16002028	; F7D1B0  call 0xf42bec
	call	16245808	; F7D1B4  call 0xf7e430
	ldb_d8	a, (32706)	; F7D1B8  ld A,(0x7fc2)
	stb_d8	(4854), a	; F7D1BC  ld (0x12f6),A
	call	16245793	; F7D1C0  call 0xf7e421
	jr	13	; F7D1C4  jr T,0xf7d1d3
	bit	7, w	; F7D1C6  bit 0x07,W
	jr	nz, 8	; F7D1C9  jr NZ,0xf7d1d3
	stdi16	(8304), 32772	; F7D1CB  ld (0x2070),0x8004
	jr	0	; F7D1D1  jr T,0xf7d1d3
	ret	; F7D1D3  ret
	ret	; F7D1D4  ret
	call	16252711	; F7D1D5  call 0xf7ff27
	ret	; F7D1D9  ret
	call	16252872	; F7D1DA  call 0xf7ffc8
	ret	; F7D1DE  ret
	ld	xix, 16243928	; F7D1DF  ld XIX,0x00f7dcd8
	.byte 0xC1, 0x7E, 0x20, 0x3F, 0x00	; F7D1E4  cp (0x207e),0x00   [llvm-mc cannot encode this]
	jr	z, 5	; F7D1E9  jr Z,0xf7d1f0
	ld	xix, 16244056	; F7D1EB  ld XIX,0x00f7dd58
	call	15997704	; F7D1F0  call 0xf41b08
	ret	; F7D1F4  ret
	ret	; F7D1F5  ret
	call	16253537	; F7D1F6  call 0xf80261
	ret	; F7D1FA  ret
	call	16253896	; F7D1FB  call 0xf803c8
	ret	; F7D1FF  ret
	ld	xix, 16244184	; F7D200  ld XIX,0x00f7ddd8
	.byte 0xC1, 0x7E, 0x20, 0x3F, 0x00	; F7D205  cp (0x207e),0x00   [llvm-mc cannot encode this]
	jr	z, 5	; F7D20A  jr Z,0xf7d211
	ld	xix, 16244312	; F7D20C  ld XIX,0x00f7de58
	call	15997704	; F7D211  call 0xf41b08
	ret	; F7D215  ret
	ret	; F7D216  ret
	call	16254009	; F7D217  call 0xf80439
	ret	; F7D21B  ret
	call	16254188	; F7D21C  call 0xf804ec
	ret	; F7D220  ret
	ld	xix, 16244440	; F7D221  ld XIX,0x00f7ded8
	.byte 0xC1, 0x7E, 0x20, 0x3F, 0x00	; F7D226  cp (0x207e),0x00   [llvm-mc cannot encode this]
	jr	z, 5	; F7D22B  jr Z,0xf7d232
	ld	xix, 16244568	; F7D22D  ld XIX,0x00f7df58
	call	15997704	; F7D232  call 0xf41b08
	ret	; F7D236  ret
	ret	; F7D237  ret
	call	16254828	; F7D238  call 0xf8076c
	ret	; F7D23C  ret
	call	16254985	; F7D23D  call 0xf80809
	ret	; F7D241  ret
	ld	xix, 16244696	; F7D242  ld XIX,0x00f7dfd8
	.byte 0xC1, 0x7E, 0x20, 0x3F, 0x00	; F7D247  cp (0x207e),0x00   [llvm-mc cannot encode this]
	jr	z, 5	; F7D24C  jr Z,0xf7d253
	ld	xix, 16244824	; F7D24E  ld XIX,0x00f7e058
	call	15997704	; F7D253  call 0xf41b08
	ret	; F7D257  ret
	ret	; F7D258  ret
	call	16255689	; F7D259  call 0xf80ac9
	ret	; F7D25D  ret
	call	16255846	; F7D25E  call 0xf80b66
	ret	; F7D262  ret
	ld	xix, 16244952	; F7D263  ld XIX,0x00f7e0d8
	.byte 0xC1, 0x7E, 0x20, 0x3F, 0x00	; F7D268  cp (0x207e),0x00   [llvm-mc cannot encode this]
	jr	z, 5	; F7D26D  jr Z,0xf7d274
	ld	xix, 16245080	; F7D26F  ld XIX,0x00f7e158
	call	15997704	; F7D274  call 0xf41b08
	ret	; F7D278  ret
	ret	; F7D279  ret
	call	16256558	; F7D27A  call 0xf80e2e
	ret	; F7D27E  ret
	call	16256687	; F7D27F  call 0xf80eaf
	ret	; F7D283  ret
	call	16256692	; F7D284  call 0xf80eb4
	ret	; F7D288  ret
	ret	; F7D289  ret
	call	16256858	; F7D28A  call 0xf80f5a
	ret	; F7D28E  ret
	call	16256960	; F7D28F  call 0xf80fc0
	ret	; F7D293  ret
	ld	xix, 16245208	; F7D294  ld XIX,0x00f7e1d8
	call	15997704	; F7D299  call 0xf41b08
	ret	; F7D29D  ret
	ret	; F7D29E  ret
	call	16257096	; F7D29F  call 0xf81048
	ret	; F7D2A3  ret
	call	16257264	; F7D2A4  call 0xf810f0
	ret	; F7D2A8  ret
	ld	xix, 16245336	; F7D2A9  ld XIX,0x00f7e258
	call	15997704	; F7D2AE  call 0xf41b08
	ret	; F7D2B2  ret
	ret	; F7D2B3  ret
	call	16257054	; F7D2B4  call 0xf8101e
	ret	; F7D2B8  ret
	call	16257081	; F7D2B9  call 0xf81039
	ret	; F7D2BD  ret
	ld	bc, hl	; F7D2BE  ld BC,HL
	call	16002760	; F7D2C0  call 0xf42ec8
	ret	; F7D2C4  ret
	ret	; F7D2C5  ret
	call	16257054	; F7D2C6  call 0xf8101e
	ret	; F7D2CA  ret
	call	16257081	; F7D2CB  call 0xf81039
	ret	; F7D2CF  ret
	ld	bc, hl	; F7D2D0  ld BC,HL
	call	16002760	; F7D2D2  call 0xf42ec8
	ret	; F7D2D6  ret
	ret	; F7D2D7  ret

; ==================================================================
; 0xF7D2D8-0xF7E2D7 -- the 32 tables, 32 entries each
; ==================================================================
; Reproduce all three counts with
;     python3 notes/prom_b_f7d_tables.py

; --- table  0 of 32: 10 distinct targets; named by the `ld XIX` at 0xF7D032
Table_F7D2D8:
	.long 0x00F7E9C7	; [ 0]
	.long 0x00F7E9C7	; [ 1]
	.long 0x00F7E9C7	; [ 2]
	.long 0x00F7E9C7	; [ 3]
	.long 0x00F7E9C7	; [ 4]
	.long 0x00F7E9C7	; [ 5]
	.long 0x00F7E9C7	; [ 6]
	.long 0x00F7E9C7	; [ 7]
	.long 0x00F7E9C8	; [ 8]
	.long 0x00F7E9DC	; [ 9]
	.long 0x00F7E9F0	; [10]
	.long 0x00F7EA04	; [11]
	.long 0x00F7EA18	; [12]
	.long 0x00F7EA2C	; [13]
	.long 0x00F7EA2C	; [14]
	.long 0x00F7EA2D	; [15]
	.long 0x00F7EA3B	; [16]
	.long 0x00F7EA54	; [17]
	.long 0x00F7EA54	; [18]
	.long 0x00F7EA54	; [19]
	.long 0x00F7EA54	; [20]
	.long 0x00F7EA54	; [21]
	.long 0x00F7EA54	; [22]
	.long 0x00F7EA54	; [23]
	.long 0x00F7EA54	; [24]
	.long 0x00F7EA3B	; [25]
	.long 0x00F7EA54	; [26]
	.long 0x00F7EA54	; [27]
	.long 0x00F7EA54	; [28]
	.long 0x00F7EA54	; [29]
	.long 0x00F7EA54	; [30]
	.long 0x00F7EA54	; [31]

; --- table  1 of 32: 10 distinct targets; named by the `ld XIX` at 0xF7D03E
Table_F7D358:
	.long 0x00F7EA56	; [ 0]
	.long 0x00F7EA56	; [ 1]
	.long 0x00F7EA56	; [ 2]
	.long 0x00F7EA56	; [ 3]
	.long 0x00F7EA56	; [ 4]
	.long 0x00F7EA56	; [ 5]
	.long 0x00F7EA56	; [ 6]
	.long 0x00F7EA56	; [ 7]
	.long 0x00F7EA57	; [ 8]
	.long 0x00F7EA6B	; [ 9]
	.long 0x00F7EA79	; [10]
	.long 0x00F7EA8D	; [11]
	.long 0x00F7EA9B	; [12]
	.long 0x00F7EAA3	; [13]
	.long 0x00F7EAA3	; [14]
	.long 0x00F7EAA4	; [15]
	.long 0x00F7EAB6	; [16]
	.long 0x00F7EACF	; [17]
	.long 0x00F7EACF	; [18]
	.long 0x00F7EACF	; [19]
	.long 0x00F7EACF	; [20]
	.long 0x00F7EACF	; [21]
	.long 0x00F7EACF	; [22]
	.long 0x00F7EACF	; [23]
	.long 0x00F7EACF	; [24]
	.long 0x00F7EAB6	; [25]
	.long 0x00F7EACF	; [26]
	.long 0x00F7EACF	; [27]
	.long 0x00F7EACF	; [28]
	.long 0x00F7EACF	; [29]
	.long 0x00F7EACF	; [30]
	.long 0x00F7EACF	; [31]

; --- table  2 of 32: 9 distinct targets; named by the `ld XIX` at 0xF7D054
Table_F7D3D8:
	.long 0x00F7EBDD	; [ 0]
	.long 0x00F7EBDD	; [ 1]
	.long 0x00F7EBDE	; [ 2]
	.long 0x00F7EC10	; [ 3]
	.long 0x00F7EC42	; [ 4]
	.long 0x00F7EC42	; [ 5]
	.long 0x00F7EC42	; [ 6]
	.long 0x00F7EC42	; [ 7]
	.long 0x00F7EC42	; [ 8]
	.long 0x00F7EC42	; [ 9]
	.long 0x00F7EC42	; [10]
	.long 0x00F7EC43	; [11]
	.long 0x00F7EC54	; [12]
	.long 0x00F7EC60	; [13]
	.long 0x00F7EC60	; [14]
	.long 0x00F7EC61	; [15]
	.long 0x00F7EC6F	; [16]
	.long 0x00F7EC6F	; [17]
	.long 0x00F7EC6F	; [18]
	.long 0x00F7EBDE	; [19]
	.long 0x00F7EC10	; [20]
	.long 0x00F7EC6F	; [21]
	.long 0x00F7EC6F	; [22]
	.long 0x00F7EC6F	; [23]
	.long 0x00F7EC6F	; [24]
	.long 0x00F7EC6F	; [25]
	.long 0x00F7EC6F	; [26]
	.long 0x00F7EC6F	; [27]
	.long 0x00F7EC6F	; [28]
	.long 0x00F7EC6F	; [29]
	.long 0x00F7EC6F	; [30]
	.long 0x00F7EC6F	; [31]

; --- table  3 of 32: 13 distinct targets; named by the `ld XIX` at 0xF7D06A
Table_F7D458:
	.long 0x00F7ECFF	; [ 0]
	.long 0x00F7ED18	; [ 1]
	.long 0x00F7ED31	; [ 2]
	.long 0x00F7ED4A	; [ 3]
	.long 0x00F7ED63	; [ 4]
	.long 0x00F7ED7C	; [ 5]
	.long 0x00F7ED95	; [ 6]
	.long 0x00F7EDAE	; [ 7]
	.long 0x00F7EDC7	; [ 8]
	.long 0x00F7EDC8	; [ 9]
	.long 0x00F7EDD2	; [10]
	.long 0x00F7EDD2	; [11]
	.long 0x00F7EDD2	; [12]
	.long 0x00F7EDD2	; [13]
	.long 0x00F7EDD2	; [14]
	.long 0x00F7EDD3	; [15]
	.long 0x00F7EDE1	; [16]
	.long 0x00F7ECFF	; [17]
	.long 0x00F7ED18	; [18]
	.long 0x00F7ED31	; [19]
	.long 0x00F7ED4A	; [20]
	.long 0x00F7ED63	; [21]
	.long 0x00F7ED7C	; [22]
	.long 0x00F7ED95	; [23]
	.long 0x00F7EDAE	; [24]
	.long 0x00F7EDE1	; [25]
	.long 0x00F7EDE1	; [26]
	.long 0x00F7EDE1	; [27]
	.long 0x00F7EDE1	; [28]
	.long 0x00F7EDE1	; [29]
	.long 0x00F7EDE1	; [30]
	.long 0x00F7EDE1	; [31]

; --- table  4 of 32: 6 distinct targets; named by the `ld XIX` at 0xF7D076
Table_F7D4D8:
	.long 0x00F7EDE2	; [ 0]
	.long 0x00F7EDE2	; [ 1]
	.long 0x00F7EDE2	; [ 2]
	.long 0x00F7EDE2	; [ 3]
	.long 0x00F7EDE2	; [ 4]
	.long 0x00F7EDE2	; [ 5]
	.long 0x00F7EDE2	; [ 6]
	.long 0x00F7EDE2	; [ 7]
	.long 0x00F7EDE2	; [ 8]
	.long 0x00F7EDE3	; [ 9]
	.long 0x00F7EDF2	; [10]
	.long 0x00F7EDFC	; [11]
	.long 0x00F7EDFC	; [12]
	.long 0x00F7EDFC	; [13]
	.long 0x00F7EDFC	; [14]
	.long 0x00F7EDFD	; [15]
	.long 0x00F7EE07	; [16]
	.long 0x00F7EE07	; [17]
	.long 0x00F7EE07	; [18]
	.long 0x00F7EE07	; [19]
	.long 0x00F7EE07	; [20]
	.long 0x00F7EE07	; [21]
	.long 0x00F7EE07	; [22]
	.long 0x00F7EE07	; [23]
	.long 0x00F7EE07	; [24]
	.long 0x00F7EE07	; [25]
	.long 0x00F7EE07	; [26]
	.long 0x00F7EE07	; [27]
	.long 0x00F7EE07	; [28]
	.long 0x00F7EE07	; [29]
	.long 0x00F7EE07	; [30]
	.long 0x00F7EE07	; [31]

; --- table  5 of 32: 15 distinct targets; named by the `ld XIX` at 0xF7D08C
Table_F7D558:
	.long 0x00F7E508	; [ 0]
	.long 0x00F7E509	; [ 1]
	.long 0x00F7E509	; [ 2]
	.long 0x00F7E50A	; [ 3]
	.long 0x00F7E52A	; [ 4]
	.long 0x00F7E535	; [ 5]
	.long 0x00F7E536	; [ 6]
	.long 0x00F7E546	; [ 7]
	.long 0x00F7E547	; [ 8]
	.long 0x00F7E563	; [ 9]
	.long 0x00F7E581	; [10]
	.long 0x00F7E5A5	; [11]
	.long 0x00F7E5BA	; [12]
	.long 0x00F7E5C4	; [13]
	.long 0x00F7E5C4	; [14]
	.long 0x00F7E5C5	; [15]
	.long 0x00F7E5D3	; [16]
	.long 0x00F7E5D3	; [17]
	.long 0x00F7E5D3	; [18]
	.long 0x00F7E5D3	; [19]
	.long 0x00F7E50A	; [20]
	.long 0x00F7E52A	; [21]
	.long 0x00F7E535	; [22]
	.long 0x00F7E536	; [23]
	.long 0x00F7E5D3	; [24]
	.long 0x00F7E5D3	; [25]
	.long 0x00F7E5D3	; [26]
	.long 0x00F7E5D3	; [27]
	.long 0x00F7E5D3	; [28]
	.long 0x00F7E5D3	; [29]
	.long 0x00F7E5D3	; [30]
	.long 0x00F7E5D3	; [31]

; --- table  6 of 32: 6 distinct targets; named by the `ld XIX` at 0xF7D098
Table_F7D5D8:
	.long 0x00F7E5D4	; [ 0]
	.long 0x00F7E5D4	; [ 1]
	.long 0x00F7E5D4	; [ 2]
	.long 0x00F7E5D4	; [ 3]
	.long 0x00F7E5D4	; [ 4]
	.long 0x00F7E5D4	; [ 5]
	.long 0x00F7E5D4	; [ 6]
	.long 0x00F7E5D4	; [ 7]
	.long 0x00F7E5D4	; [ 8]
	.long 0x00F7E5D5	; [ 9]
	.long 0x00F7E5E6	; [10]
	.long 0x00F7E5F2	; [11]
	.long 0x00F7E5F2	; [12]
	.long 0x00F7E5F2	; [13]
	.long 0x00F7E5F2	; [14]
	.long 0x00F7E5F3	; [15]
	.long 0x00F7E5FF	; [16]
	.long 0x00F7E5FF	; [17]
	.long 0x00F7E5FF	; [18]
	.long 0x00F7E5FF	; [19]
	.long 0x00F7E5FF	; [20]
	.long 0x00F7E5FF	; [21]
	.long 0x00F7E5FF	; [22]
	.long 0x00F7E5FF	; [23]
	.long 0x00F7E5FF	; [24]
	.long 0x00F7E5FF	; [25]
	.long 0x00F7E5FF	; [26]
	.long 0x00F7E5FF	; [27]
	.long 0x00F7E5FF	; [28]
	.long 0x00F7E5FF	; [29]
	.long 0x00F7E5FF	; [30]
	.long 0x00F7E5FF	; [31]

; --- table  7 of 32: 17 distinct targets; named by the `ld XIX` at 0xF7D0AE
Table_F7D658:
	.long 0x00F7E687	; [ 0]
	.long 0x00F7E68F	; [ 1]
	.long 0x00F7E6A0	; [ 2]
	.long 0x00F7E6B1	; [ 3]
	.long 0x00F7E6B9	; [ 4]
	.long 0x00F7E6C1	; [ 5]
	.long 0x00F7E6CD	; [ 6]
	.long 0x00F7E6D5	; [ 7]
	.long 0x00F7E6DD	; [ 8]
	.long 0x00F7E6FE	; [ 9]
	.long 0x00F7E71F	; [10]
	.long 0x00F7E740	; [11]
	.long 0x00F7E748	; [12]
	.long 0x00F7E750	; [13]
	.long 0x00F7E758	; [14]
	.long 0x00F7E760	; [15]
	.long 0x00F7E76E	; [16]
	.long 0x00F7E76E	; [17]
	.long 0x00F7E76E	; [18]
	.long 0x00F7E76E	; [19]
	.long 0x00F7E76E	; [20]
	.long 0x00F7E76E	; [21]
	.long 0x00F7E76E	; [22]
	.long 0x00F7E76E	; [23]
	.long 0x00F7E76E	; [24]
	.long 0x00F7E76E	; [25]
	.long 0x00F7E76E	; [26]
	.long 0x00F7E76E	; [27]
	.long 0x00F7E76E	; [28]
	.long 0x00F7E76E	; [29]
	.long 0x00F7E76E	; [30]
	.long 0x00F7E76E	; [31]

; --- table  8 of 32: 16 distinct targets; named by the `ld XIX` at 0xF7D0C6
Table_F7D6D8:
	.long 0x00F7EE9B	; [ 0]
	.long 0x00F7EE9C	; [ 1]
	.long 0x00F7EE9D	; [ 2]
	.long 0x00F7EE9E	; [ 3]
	.long 0x00F7EE9F	; [ 4]
	.long 0x00F7EECA	; [ 5]
	.long 0x00F7EECB	; [ 6]
	.long 0x00F7EECC	; [ 7]
	.long 0x00F7EECC	; [ 8]
	.long 0x00F7EECD	; [ 9]
	.long 0x00F7EF02	; [10]
	.long 0x00F7EF1E	; [11]
	.long 0x00F7EF3A	; [12]
	.long 0x00F7EF3B	; [13]
	.long 0x00F7EF3C	; [14]
	.long 0x00F7EF3D	; [15]
	.long 0x00F7EF4B	; [16]
	.long 0x00F7EF4B	; [17]
	.long 0x00F7EF4B	; [18]
	.long 0x00F7EF4B	; [19]
	.long 0x00F7EF4B	; [20]
	.long 0x00F7EF4B	; [21]
	.long 0x00F7EF4B	; [22]
	.long 0x00F7EF4B	; [23]
	.long 0x00F7EF4B	; [24]
	.long 0x00F7EF4B	; [25]
	.long 0x00F7EF4B	; [26]
	.long 0x00F7EF4B	; [27]
	.long 0x00F7EF4B	; [28]
	.long 0x00F7EF4B	; [29]
	.long 0x00F7EF4B	; [30]
	.long 0x00F7EF4B	; [31]

; --- table  9 of 32: 16 distinct targets; named by the `ld XIX` at 0xF7D0D2
Table_F7D758:
	.long 0x00F7EF4C	; [ 0]
	.long 0x00F7EF4D	; [ 1]
	.long 0x00F7EF4E	; [ 2]
	.long 0x00F7EF4F	; [ 3]
	.long 0x00F7EF50	; [ 4]
	.long 0x00F7EF51	; [ 5]
	.long 0x00F7EF52	; [ 6]
	.long 0x00F7EF53	; [ 7]
	.long 0x00F7EF53	; [ 8]
	.long 0x00F7EF54	; [ 9]
	.long 0x00F7EF63	; [10]
	.long 0x00F7EF64	; [11]
	.long 0x00F7EF6E	; [12]
	.long 0x00F7EF6F	; [13]
	.long 0x00F7EF70	; [14]
	.long 0x00F7EF71	; [15]
	.long 0x00F7EF7B	; [16]
	.long 0x00F7EF7B	; [17]
	.long 0x00F7EF7B	; [18]
	.long 0x00F7EF7B	; [19]
	.long 0x00F7EF7B	; [20]
	.long 0x00F7EF7B	; [21]
	.long 0x00F7EF7B	; [22]
	.long 0x00F7EF7B	; [23]
	.long 0x00F7EF7B	; [24]
	.long 0x00F7EF7B	; [25]
	.long 0x00F7EF7B	; [26]
	.long 0x00F7EF7B	; [27]
	.long 0x00F7EF7B	; [28]
	.long 0x00F7EF7B	; [29]
	.long 0x00F7EF7B	; [30]
	.long 0x00F7EF7B	; [31]

; --- table 10 of 32: 20 distinct targets; named by the `ld XIX` at 0xF7D0E7
Table_F7D7D8:
	.long 0x00F7F036	; [ 0]
	.long 0x00F7F037	; [ 1]
	.long 0x00F7F038	; [ 2]
	.long 0x00F7F039	; [ 3]
	.long 0x00F7F03A	; [ 4]
	.long 0x00F7F061	; [ 5]
	.long 0x00F7F062	; [ 6]
	.long 0x00F7F063	; [ 7]
	.long 0x00F7F063	; [ 8]
	.long 0x00F7F064	; [ 9]
	.long 0x00F7F088	; [10]
	.long 0x00F7F0B3	; [11]
	.long 0x00F7F0D5	; [12]
	.long 0x00F7F0D6	; [13]
	.long 0x00F7F0D7	; [14]
	.long 0x00F7F0D8	; [15]
	.long 0x00F7F0E6	; [16]
	.long 0x00F7F0E6	; [17]
	.long 0x00F7F0E6	; [18]
	.long 0x00F7F0E6	; [19]
	.long 0x00F7F0E6	; [20]
	.long 0x00F7F0E7	; [21]
	.long 0x00F7F10E	; [22]
	.long 0x00F7F10E	; [23]
	.long 0x00F7F10E	; [24]
	.long 0x00F7F10E	; [25]
	.long 0x00F7F10E	; [26]
	.long 0x00F7F10F	; [27]
	.long 0x00F7F113	; [28]
	.long 0x00F7F113	; [29]
	.long 0x00F7F113	; [30]
	.long 0x00F7F113	; [31]

; --- table 11 of 32: 16 distinct targets; named by the `ld XIX` at 0xF7D0F3
Table_F7D858:
	.long 0x00F7F205	; [ 0]
	.long 0x00F7F206	; [ 1]
	.long 0x00F7F207	; [ 2]
	.long 0x00F7F208	; [ 3]
	.long 0x00F7F209	; [ 4]
	.long 0x00F7F20A	; [ 5]
	.long 0x00F7F20B	; [ 6]
	.long 0x00F7F20C	; [ 7]
	.long 0x00F7F20D	; [ 8]
	.long 0x00F7F20D	; [ 9]
	.long 0x00F7F20E	; [10]
	.long 0x00F7F21D	; [11]
	.long 0x00F7F229	; [12]
	.long 0x00F7F22A	; [13]
	.long 0x00F7F22B	; [14]
	.long 0x00F7F22C	; [15]
	.long 0x00F7F236	; [16]
	.long 0x00F7F236	; [17]
	.long 0x00F7F236	; [18]
	.long 0x00F7F236	; [19]
	.long 0x00F7F236	; [20]
	.long 0x00F7F236	; [21]
	.long 0x00F7F236	; [22]
	.long 0x00F7F236	; [23]
	.long 0x00F7F236	; [24]
	.long 0x00F7F236	; [25]
	.long 0x00F7F236	; [26]
	.long 0x00F7F236	; [27]
	.long 0x00F7F236	; [28]
	.long 0x00F7F236	; [29]
	.long 0x00F7F236	; [30]
	.long 0x00F7F236	; [31]

; --- table 12 of 32: 21 distinct targets; named by the `ld XIX` at 0xF7D108
Table_F7D8D8:
	.long 0x00F7F2DA	; [ 0]
	.long 0x00F7F2DB	; [ 1]
	.long 0x00F7F2DC	; [ 2]
	.long 0x00F7F2DD	; [ 3]
	.long 0x00F7F2DE	; [ 4]
	.long 0x00F7F305	; [ 5]
	.long 0x00F7F306	; [ 6]
	.long 0x00F7F307	; [ 7]
	.long 0x00F7F308	; [ 8]
	.long 0x00F7F34A	; [ 9]
	.long 0x00F7F375	; [10]
	.long 0x00F7F3AE	; [11]
	.long 0x00F7F3D0	; [12]
	.long 0x00F7F3D1	; [13]
	.long 0x00F7F3D2	; [14]
	.long 0x00F7F3D3	; [15]
	.long 0x00F7F3E1	; [16]
	.long 0x00F7F3E1	; [17]
	.long 0x00F7F3E1	; [18]
	.long 0x00F7F3E1	; [19]
	.long 0x00F7F3E1	; [20]
	.long 0x00F7F3E2	; [21]
	.long 0x00F7F409	; [22]
	.long 0x00F7F409	; [23]
	.long 0x00F7F409	; [24]
	.long 0x00F7F409	; [25]
	.long 0x00F7F409	; [26]
	.long 0x00F7F40A	; [27]
	.long 0x00F7F40E	; [28]
	.long 0x00F7F40E	; [29]
	.long 0x00F7F40E	; [30]
	.long 0x00F7F40E	; [31]

; --- table 13 of 32: 17 distinct targets; named by the `ld XIX` at 0xF7D114
Table_F7D958:
	.long 0x00F7F40F	; [ 0]
	.long 0x00F7F410	; [ 1]
	.long 0x00F7F411	; [ 2]
	.long 0x00F7F412	; [ 3]
	.long 0x00F7F413	; [ 4]
	.long 0x00F7F414	; [ 5]
	.long 0x00F7F415	; [ 6]
	.long 0x00F7F416	; [ 7]
	.long 0x00F7F417	; [ 8]
	.long 0x00F7F418	; [ 9]
	.long 0x00F7F427	; [10]
	.long 0x00F7F431	; [11]
	.long 0x00F7F432	; [12]
	.long 0x00F7F433	; [13]
	.long 0x00F7F434	; [14]
	.long 0x00F7F435	; [15]
	.long 0x00F7F43F	; [16]
	.long 0x00F7F43F	; [17]
	.long 0x00F7F43F	; [18]
	.long 0x00F7F43F	; [19]
	.long 0x00F7F43F	; [20]
	.long 0x00F7F43F	; [21]
	.long 0x00F7F43F	; [22]
	.long 0x00F7F43F	; [23]
	.long 0x00F7F43F	; [24]
	.long 0x00F7F43F	; [25]
	.long 0x00F7F43F	; [26]
	.long 0x00F7F43F	; [27]
	.long 0x00F7F43F	; [28]
	.long 0x00F7F43F	; [29]
	.long 0x00F7F43F	; [30]
	.long 0x00F7F43F	; [31]

; --- table 14 of 32: 21 distinct targets; named by the `ld XIX` at 0xF7D139
Table_F7D9D8:
	.long 0x00F7F608	; [ 0]
	.long 0x00F7F609	; [ 1]
	.long 0x00F7F60A	; [ 2]
	.long 0x00F7F60B	; [ 3]
	.long 0x00F7F60C	; [ 4]
	.long 0x00F7F633	; [ 5]
	.long 0x00F7F634	; [ 6]
	.long 0x00F7F635	; [ 7]
	.long 0x00F7F636	; [ 8]
	.long 0x00F7F688	; [ 9]
	.long 0x00F7F6BA	; [10]
	.long 0x00F7F6FC	; [11]
	.long 0x00F7F71E	; [12]
	.long 0x00F7F71F	; [13]
	.long 0x00F7F720	; [14]
	.long 0x00F7F721	; [15]
	.long 0x00F7F74D	; [16]
	.long 0x00F7F74D	; [17]
	.long 0x00F7F74D	; [18]
	.long 0x00F7F74D	; [19]
	.long 0x00F7F74D	; [20]
	.long 0x00F7F74E	; [21]
	.long 0x00F7F775	; [22]
	.long 0x00F7F775	; [23]
	.long 0x00F7F775	; [24]
	.long 0x00F7F775	; [25]
	.long 0x00F7F775	; [26]
	.long 0x00F7F776	; [27]
	.long 0x00F7F77A	; [28]
	.long 0x00F7F77A	; [29]
	.long 0x00F7F77A	; [30]
	.long 0x00F7F77A	; [31]

; --- table 15 of 32: 16 distinct targets; named by the `ld XIX` at 0xF7D145
Table_F7DA58:
	.long 0x00F7F77B	; [ 0]
	.long 0x00F7F77C	; [ 1]
	.long 0x00F7F77D	; [ 2]
	.long 0x00F7F77E	; [ 3]
	.long 0x00F7F77F	; [ 4]
	.long 0x00F7F780	; [ 5]
	.long 0x00F7F781	; [ 6]
	.long 0x00F7F782	; [ 7]
	.long 0x00F7F783	; [ 8]
	.long 0x00F7F783	; [ 9]
	.long 0x00F7F784	; [10]
	.long 0x00F7F793	; [11]
	.long 0x00F7F79D	; [12]
	.long 0x00F7F79E	; [13]
	.long 0x00F7F79F	; [14]
	.long 0x00F7F7A0	; [15]
	.long 0x00F7F7AA	; [16]
	.long 0x00F7F7AA	; [17]
	.long 0x00F7F7AA	; [18]
	.long 0x00F7F7AA	; [19]
	.long 0x00F7F7AA	; [20]
	.long 0x00F7F7AA	; [21]
	.long 0x00F7F7AA	; [22]
	.long 0x00F7F7AA	; [23]
	.long 0x00F7F7AA	; [24]
	.long 0x00F7F7AA	; [25]
	.long 0x00F7F7AA	; [26]
	.long 0x00F7F7AA	; [27]
	.long 0x00F7F7AA	; [28]
	.long 0x00F7F7AA	; [29]
	.long 0x00F7F7AA	; [30]
	.long 0x00F7F7AA	; [31]

; --- table 16 of 32: 21 distinct targets; named by the `ld XIX` at 0xF7D15A
Table_F7DAD8:
	.long 0x00F7F954	; [ 0]
	.long 0x00F7F955	; [ 1]
	.long 0x00F7F956	; [ 2]
	.long 0x00F7F957	; [ 3]
	.long 0x00F7F958	; [ 4]
	.long 0x00F7F97F	; [ 5]
	.long 0x00F7F980	; [ 6]
	.long 0x00F7F981	; [ 7]
	.long 0x00F7F982	; [ 8]
	.long 0x00F7F9BC	; [ 9]
	.long 0x00F7F9DF	; [10]
	.long 0x00F7FA15	; [11]
	.long 0x00F7FA31	; [12]
	.long 0x00F7FA32	; [13]
	.long 0x00F7FA33	; [14]
	.long 0x00F7FA34	; [15]
	.long 0x00F7FA42	; [16]
	.long 0x00F7FA42	; [17]
	.long 0x00F7FA42	; [18]
	.long 0x00F7FA42	; [19]
	.long 0x00F7FA42	; [20]
	.long 0x00F7FA43	; [21]
	.long 0x00F7FA6A	; [22]
	.long 0x00F7FA6A	; [23]
	.long 0x00F7FA6A	; [24]
	.long 0x00F7FA6A	; [25]
	.long 0x00F7FA6A	; [26]
	.long 0x00F7FA6B	; [27]
	.long 0x00F7FA6F	; [28]
	.long 0x00F7FA6F	; [29]
	.long 0x00F7FA6F	; [30]
	.long 0x00F7FA6F	; [31]

; --- table 17 of 32: 17 distinct targets; named by the `ld XIX` at 0xF7D166
Table_F7DB58:
	.long 0x00F7FA70	; [ 0]
	.long 0x00F7FA71	; [ 1]
	.long 0x00F7FA72	; [ 2]
	.long 0x00F7FA73	; [ 3]
	.long 0x00F7FA74	; [ 4]
	.long 0x00F7FA75	; [ 5]
	.long 0x00F7FA76	; [ 6]
	.long 0x00F7FA77	; [ 7]
	.long 0x00F7FA78	; [ 8]
	.long 0x00F7FA79	; [ 9]
	.long 0x00F7FA88	; [10]
	.long 0x00F7FA92	; [11]
	.long 0x00F7FA93	; [12]
	.long 0x00F7FA94	; [13]
	.long 0x00F7FA95	; [14]
	.long 0x00F7FA96	; [15]
	.long 0x00F7FAA0	; [16]
	.long 0x00F7FAA0	; [17]
	.long 0x00F7FAA0	; [18]
	.long 0x00F7FAA0	; [19]
	.long 0x00F7FAA0	; [20]
	.long 0x00F7FAA0	; [21]
	.long 0x00F7FAA0	; [22]
	.long 0x00F7FAA0	; [23]
	.long 0x00F7FAA0	; [24]
	.long 0x00F7FAA0	; [25]
	.long 0x00F7FAA0	; [26]
	.long 0x00F7FAA0	; [27]
	.long 0x00F7FAA0	; [28]
	.long 0x00F7FAA0	; [29]
	.long 0x00F7FAA0	; [30]
	.long 0x00F7FAA0	; [31]

; --- table 18 of 32: 21 distinct targets; named by the `ld XIX` at 0xF7D17B
Table_F7DBD8:
	.long 0x00F7FC9E	; [ 0]
	.long 0x00F7FC9F	; [ 1]
	.long 0x00F7FCA0	; [ 2]
	.long 0x00F7FCA1	; [ 3]
	.long 0x00F7FCA2	; [ 4]
	.long 0x00F7FCC9	; [ 5]
	.long 0x00F7FCCA	; [ 6]
	.long 0x00F7FCCB	; [ 7]
	.long 0x00F7FCCC	; [ 8]
	.long 0x00F7FD06	; [ 9]
	.long 0x00F7FD29	; [10]
	.long 0x00F7FD5C	; [11]
	.long 0x00F7FD78	; [12]
	.long 0x00F7FD79	; [13]
	.long 0x00F7FD7A	; [14]
	.long 0x00F7FD7B	; [15]
	.long 0x00F7FD89	; [16]
	.long 0x00F7FD89	; [17]
	.long 0x00F7FD89	; [18]
	.long 0x00F7FD89	; [19]
	.long 0x00F7FD89	; [20]
	.long 0x00F7FD8A	; [21]
	.long 0x00F7FDB1	; [22]
	.long 0x00F7FDB1	; [23]
	.long 0x00F7FDB1	; [24]
	.long 0x00F7FDB1	; [25]
	.long 0x00F7FDB1	; [26]
	.long 0x00F7FDB2	; [27]
	.long 0x00F7FDB6	; [28]
	.long 0x00F7FDB6	; [29]
	.long 0x00F7FDB6	; [30]
	.long 0x00F7FDB6	; [31]

; --- table 19 of 32: 17 distinct targets; named by the `ld XIX` at 0xF7D187
Table_F7DC58:
	.long 0x00F7FDB7	; [ 0]
	.long 0x00F7FDB8	; [ 1]
	.long 0x00F7FDB9	; [ 2]
	.long 0x00F7FDBA	; [ 3]
	.long 0x00F7FDBB	; [ 4]
	.long 0x00F7FDBC	; [ 5]
	.long 0x00F7FDBD	; [ 6]
	.long 0x00F7FDBE	; [ 7]
	.long 0x00F7FDBF	; [ 8]
	.long 0x00F7FDC0	; [ 9]
	.long 0x00F7FDCF	; [10]
	.long 0x00F7FDD9	; [11]
	.long 0x00F7FDDA	; [12]
	.long 0x00F7FDDB	; [13]
	.long 0x00F7FDDC	; [14]
	.long 0x00F7FDDD	; [15]
	.long 0x00F7FDE7	; [16]
	.long 0x00F7FDE7	; [17]
	.long 0x00F7FDE7	; [18]
	.long 0x00F7FDE7	; [19]
	.long 0x00F7FDE7	; [20]
	.long 0x00F7FDE7	; [21]
	.long 0x00F7FDE7	; [22]
	.long 0x00F7FDE7	; [23]
	.long 0x00F7FDE7	; [24]
	.long 0x00F7FDE7	; [25]
	.long 0x00F7FDE7	; [26]
	.long 0x00F7FDE7	; [27]
	.long 0x00F7FDE7	; [28]
	.long 0x00F7FDE7	; [29]
	.long 0x00F7FDE7	; [30]
	.long 0x00F7FDE7	; [31]

; --- table 20 of 32: 21 distinct targets; named by the `ld XIX` at 0xF7D1DF
Table_F7DCD8:
	.long 0x00F7FFCD	; [ 0]
	.long 0x00F7FFCE	; [ 1]
	.long 0x00F7FFCF	; [ 2]
	.long 0x00F7FFD0	; [ 3]
	.long 0x00F7FFD1	; [ 4]
	.long 0x00F7FFF8	; [ 5]
	.long 0x00F7FFF9	; [ 6]
	.long 0x00F7FFFA	; [ 7]
	.long 0x00F7FFFB	; [ 8]
	.long 0x00F8003A	; [ 9]
	.long 0x00F80059	; [10]
	.long 0x00F8009D	; [11]
	.long 0x00F800BE	; [12]
	.long 0x00F800BF	; [13]
	.long 0x00F800C0	; [14]
	.long 0x00F800C1	; [15]
	.long 0x00F800CF	; [16]
	.long 0x00F800CF	; [17]
	.long 0x00F800CF	; [18]
	.long 0x00F800CF	; [19]
	.long 0x00F800CF	; [20]
	.long 0x00F800D0	; [21]
	.long 0x00F800F7	; [22]
	.long 0x00F800F7	; [23]
	.long 0x00F800F7	; [24]
	.long 0x00F800F7	; [25]
	.long 0x00F800F7	; [26]
	.long 0x00F800F8	; [27]
	.long 0x00F800FC	; [28]
	.long 0x00F800FC	; [29]
	.long 0x00F800FC	; [30]
	.long 0x00F800FC	; [31]

; --- table 21 of 32: 17 distinct targets; named by the `ld XIX` at 0xF7D1EB
Table_F7DD58:
	.long 0x00F800FD	; [ 0]
	.long 0x00F800FE	; [ 1]
	.long 0x00F800FF	; [ 2]
	.long 0x00F80100	; [ 3]
	.long 0x00F80101	; [ 4]
	.long 0x00F80102	; [ 5]
	.long 0x00F80103	; [ 6]
	.long 0x00F80104	; [ 7]
	.long 0x00F80105	; [ 8]
	.long 0x00F80106	; [ 9]
	.long 0x00F80107	; [10]
	.long 0x00F80116	; [11]
	.long 0x00F80120	; [12]
	.long 0x00F80121	; [13]
	.long 0x00F80122	; [14]
	.long 0x00F80123	; [15]
	.long 0x00F8012D	; [16]
	.long 0x00F8012D	; [17]
	.long 0x00F8012D	; [18]
	.long 0x00F8012D	; [19]
	.long 0x00F8012D	; [20]
	.long 0x00F8012D	; [21]
	.long 0x00F8012D	; [22]
	.long 0x00F8012D	; [23]
	.long 0x00F8012D	; [24]
	.long 0x00F8012D	; [25]
	.long 0x00F8012D	; [26]
	.long 0x00F8012D	; [27]
	.long 0x00F8012D	; [28]
	.long 0x00F8012D	; [29]
	.long 0x00F8012D	; [30]
	.long 0x00F8012D	; [31]

; --- table 22 of 32: 13 distinct targets; named by the `ld XIX` at 0xF7D200
Table_F7DDD8:
	.long 0x00F803C9	; [ 0]
	.long 0x00F803D2	; [ 1]
	.long 0x00F803DB	; [ 2]
	.long 0x00F803E4	; [ 3]
	.long 0x00F803ED	; [ 4]
	.long 0x00F803F6	; [ 5]
	.long 0x00F803FF	; [ 6]
	.long 0x00F80408	; [ 7]
	.long 0x00F80411	; [ 8]
	.long 0x00F80412	; [ 9]
	.long 0x00F80417	; [10]
	.long 0x00F80417	; [11]
	.long 0x00F80417	; [12]
	.long 0x00F80417	; [13]
	.long 0x00F80417	; [14]
	.long 0x00F80418	; [15]
	.long 0x00F80426	; [16]
	.long 0x00F803C9	; [17]
	.long 0x00F803D2	; [18]
	.long 0x00F803DB	; [19]
	.long 0x00F803E4	; [20]
	.long 0x00F803ED	; [21]
	.long 0x00F803F6	; [22]
	.long 0x00F803FF	; [23]
	.long 0x00F80408	; [24]
	.long 0x00F80426	; [25]
	.long 0x00F80426	; [26]
	.long 0x00F80426	; [27]
	.long 0x00F80426	; [28]
	.long 0x00F80426	; [29]
	.long 0x00F80426	; [30]
	.long 0x00F80426	; [31]

; --- table 23 of 32: 6 distinct targets; named by the `ld XIX` at 0xF7D20C
Table_F7DE58:
	.long 0x00F80427	; [ 0]
	.long 0x00F80427	; [ 1]
	.long 0x00F80427	; [ 2]
	.long 0x00F80427	; [ 3]
	.long 0x00F80427	; [ 4]
	.long 0x00F80427	; [ 5]
	.long 0x00F80427	; [ 6]
	.long 0x00F80427	; [ 7]
	.long 0x00F80427	; [ 8]
	.long 0x00F80428	; [ 9]
	.long 0x00F8042D	; [10]
	.long 0x00F80432	; [11]
	.long 0x00F80432	; [12]
	.long 0x00F80432	; [13]
	.long 0x00F80432	; [14]
	.long 0x00F80433	; [15]
	.long 0x00F80438	; [16]
	.long 0x00F80438	; [17]
	.long 0x00F80438	; [18]
	.long 0x00F80438	; [19]
	.long 0x00F80438	; [20]
	.long 0x00F80438	; [21]
	.long 0x00F80438	; [22]
	.long 0x00F80438	; [23]
	.long 0x00F80438	; [24]
	.long 0x00F80438	; [25]
	.long 0x00F80438	; [26]
	.long 0x00F80438	; [27]
	.long 0x00F80438	; [28]
	.long 0x00F80438	; [29]
	.long 0x00F80438	; [30]
	.long 0x00F80438	; [31]

; --- table 24 of 32: 20 distinct targets; named by the `ld XIX` at 0xF7D221
Table_F7DED8:
	.long 0x00F804F1	; [ 0]
	.long 0x00F804F2	; [ 1]
	.long 0x00F804F3	; [ 2]
	.long 0x00F804F4	; [ 3]
	.long 0x00F804F5	; [ 4]
	.long 0x00F8051C	; [ 5]
	.long 0x00F8051D	; [ 6]
	.long 0x00F8051E	; [ 7]
	.long 0x00F8051E	; [ 8]
	.long 0x00F8051F	; [ 9]
	.long 0x00F80569	; [10]
	.long 0x00F80595	; [11]
	.long 0x00F805CF	; [12]
	.long 0x00F805D0	; [13]
	.long 0x00F805D1	; [14]
	.long 0x00F805D2	; [15]
	.long 0x00F805E0	; [16]
	.long 0x00F805E0	; [17]
	.long 0x00F805E0	; [18]
	.long 0x00F805E0	; [19]
	.long 0x00F805E0	; [20]
	.long 0x00F805E1	; [21]
	.long 0x00F80608	; [22]
	.long 0x00F80608	; [23]
	.long 0x00F80608	; [24]
	.long 0x00F80608	; [25]
	.long 0x00F80608	; [26]
	.long 0x00F80609	; [27]
	.long 0x00F8060D	; [28]
	.long 0x00F8060D	; [29]
	.long 0x00F8060D	; [30]
	.long 0x00F8060D	; [31]

; --- table 25 of 32: 6 distinct targets; named by the `ld XIX` at 0xF7D22D
Table_F7DF58:
	.long 0x00F8060E	; [ 0]
	.long 0x00F8060E	; [ 1]
	.long 0x00F8060E	; [ 2]
	.long 0x00F8060E	; [ 3]
	.long 0x00F8060E	; [ 4]
	.long 0x00F8060E	; [ 5]
	.long 0x00F8060E	; [ 6]
	.long 0x00F8060E	; [ 7]
	.long 0x00F8060E	; [ 8]
	.long 0x00F8060E	; [ 9]
	.long 0x00F8060E	; [10]
	.long 0x00F8060F	; [11]
	.long 0x00F80619	; [12]
	.long 0x00F80623	; [13]
	.long 0x00F80623	; [14]
	.long 0x00F80624	; [15]
	.long 0x00F80629	; [16]
	.long 0x00F80629	; [17]
	.long 0x00F80629	; [18]
	.long 0x00F80629	; [19]
	.long 0x00F80629	; [20]
	.long 0x00F80629	; [21]
	.long 0x00F80629	; [22]
	.long 0x00F80629	; [23]
	.long 0x00F80629	; [24]
	.long 0x00F80629	; [25]
	.long 0x00F80629	; [26]
	.long 0x00F80629	; [27]
	.long 0x00F80629	; [28]
	.long 0x00F80629	; [29]
	.long 0x00F80629	; [30]
	.long 0x00F80629	; [31]

; --- table 26 of 32: 21 distinct targets; named by the `ld XIX` at 0xF7D242
Table_F7DFD8:
	.long 0x00F8080E	; [ 0]
	.long 0x00F8080F	; [ 1]
	.long 0x00F80810	; [ 2]
	.long 0x00F80811	; [ 3]
	.long 0x00F80812	; [ 4]
	.long 0x00F8084C	; [ 5]
	.long 0x00F8084D	; [ 6]
	.long 0x00F8084E	; [ 7]
	.long 0x00F8084F	; [ 8]
	.long 0x00F8085C	; [ 9]
	.long 0x00F808B1	; [10]
	.long 0x00F808E6	; [11]
	.long 0x00F8091B	; [12]
	.long 0x00F8091C	; [13]
	.long 0x00F8091D	; [14]
	.long 0x00F8091E	; [15]
	.long 0x00F8092C	; [16]
	.long 0x00F8092C	; [17]
	.long 0x00F8092C	; [18]
	.long 0x00F8092C	; [19]
	.long 0x00F8092C	; [20]
	.long 0x00F8092D	; [21]
	.long 0x00F80967	; [22]
	.long 0x00F80967	; [23]
	.long 0x00F80967	; [24]
	.long 0x00F80967	; [25]
	.long 0x00F80967	; [26]
	.long 0x00F80968	; [27]
	.long 0x00F8096C	; [28]
	.long 0x00F8096C	; [29]
	.long 0x00F8096C	; [30]
	.long 0x00F8096C	; [31]

; --- table 27 of 32: 16 distinct targets; named by the `ld XIX` at 0xF7D24E
Table_F7E058:
	.long 0x00F8096D	; [ 0]
	.long 0x00F8096E	; [ 1]
	.long 0x00F8096F	; [ 2]
	.long 0x00F80970	; [ 3]
	.long 0x00F80971	; [ 4]
	.long 0x00F80972	; [ 5]
	.long 0x00F80973	; [ 6]
	.long 0x00F80974	; [ 7]
	.long 0x00F80975	; [ 8]
	.long 0x00F80984	; [ 9]
	.long 0x00F80985	; [10]
	.long 0x00F80985	; [11]
	.long 0x00F80986	; [12]
	.long 0x00F80990	; [13]
	.long 0x00F80991	; [14]
	.long 0x00F80992	; [15]
	.long 0x00F8099C	; [16]
	.long 0x00F8099C	; [17]
	.long 0x00F8099C	; [18]
	.long 0x00F8099C	; [19]
	.long 0x00F8099C	; [20]
	.long 0x00F8099C	; [21]
	.long 0x00F8099C	; [22]
	.long 0x00F8099C	; [23]
	.long 0x00F8099C	; [24]
	.long 0x00F8099C	; [25]
	.long 0x00F8099C	; [26]
	.long 0x00F8099C	; [27]
	.long 0x00F8099C	; [28]
	.long 0x00F8099C	; [29]
	.long 0x00F8099C	; [30]
	.long 0x00F8099C	; [31]

; --- table 28 of 32: 21 distinct targets; named by the `ld XIX` at 0xF7D263
Table_F7E0D8:
	.long 0x00F80B6B	; [ 0]
	.long 0x00F80B6C	; [ 1]
	.long 0x00F80B6D	; [ 2]
	.long 0x00F80B6E	; [ 3]
	.long 0x00F80B6F	; [ 4]
	.long 0x00F80BA9	; [ 5]
	.long 0x00F80BAA	; [ 6]
	.long 0x00F80BAB	; [ 7]
	.long 0x00F80BAC	; [ 8]
	.long 0x00F80BB9	; [ 9]
	.long 0x00F80C0E	; [10]
	.long 0x00F80C43	; [11]
	.long 0x00F80C78	; [12]
	.long 0x00F80C79	; [13]
	.long 0x00F80C7A	; [14]
	.long 0x00F80C7B	; [15]
	.long 0x00F80C89	; [16]
	.long 0x00F80C89	; [17]
	.long 0x00F80C89	; [18]
	.long 0x00F80C89	; [19]
	.long 0x00F80C89	; [20]
	.long 0x00F80C8A	; [21]
	.long 0x00F80CC4	; [22]
	.long 0x00F80CC4	; [23]
	.long 0x00F80CC4	; [24]
	.long 0x00F80CC4	; [25]
	.long 0x00F80CC4	; [26]
	.long 0x00F80CC5	; [27]
	.long 0x00F80CC9	; [28]
	.long 0x00F80CC9	; [29]
	.long 0x00F80CC9	; [30]
	.long 0x00F80CC9	; [31]

; --- table 29 of 32: 17 distinct targets; named by the `ld XIX` at 0xF7D26F
Table_F7E158:
	.long 0x00F80CCA	; [ 0]
	.long 0x00F80CCB	; [ 1]
	.long 0x00F80CCC	; [ 2]
	.long 0x00F80CCD	; [ 3]
	.long 0x00F80CCE	; [ 4]
	.long 0x00F80CCF	; [ 5]
	.long 0x00F80CD0	; [ 6]
	.long 0x00F80CD1	; [ 7]
	.long 0x00F80CD2	; [ 8]
	.long 0x00F80CE1	; [ 9]
	.long 0x00F80CE2	; [10]
	.long 0x00F80CE3	; [11]
	.long 0x00F80CE4	; [12]
	.long 0x00F80CEE	; [13]
	.long 0x00F80CEF	; [14]
	.long 0x00F80CF0	; [15]
	.long 0x00F80CFA	; [16]
	.long 0x00F80CFA	; [17]
	.long 0x00F80CFA	; [18]
	.long 0x00F80CFA	; [19]
	.long 0x00F80CFA	; [20]
	.long 0x00F80CFA	; [21]
	.long 0x00F80CFA	; [22]
	.long 0x00F80CFA	; [23]
	.long 0x00F80CFA	; [24]
	.long 0x00F80CFA	; [25]
	.long 0x00F80CFA	; [26]
	.long 0x00F80CFA	; [27]
	.long 0x00F80CFA	; [28]
	.long 0x00F80CFA	; [29]
	.long 0x00F80CFA	; [30]
	.long 0x00F80CFA	; [31]

; --- table 30 of 32: 12 distinct targets; named by the `ld XIX` at 0xF7D294
Table_F7E1D8:
	.long 0x00F80FC5	; [ 0]
	.long 0x00F80FCE	; [ 1]
	.long 0x00F80FD7	; [ 2]
	.long 0x00F80FE0	; [ 3]
	.long 0x00F80FE9	; [ 4]
	.long 0x00F80FF2	; [ 5]
	.long 0x00F80FFB	; [ 6]
	.long 0x00F81004	; [ 7]
	.long 0x00F8100D	; [ 8]
	.long 0x00F8100E	; [ 9]
	.long 0x00F8100E	; [10]
	.long 0x00F8100E	; [11]
	.long 0x00F8100E	; [12]
	.long 0x00F8100E	; [13]
	.long 0x00F8100E	; [14]
	.long 0x00F8100F	; [15]
	.long 0x00F8101D	; [16]
	.long 0x00F80FC5	; [17]
	.long 0x00F80FCE	; [18]
	.long 0x00F80FD7	; [19]
	.long 0x00F80FE0	; [20]
	.long 0x00F80FE9	; [21]
	.long 0x00F80FF2	; [22]
	.long 0x00F80FFB	; [23]
	.long 0x00F81004	; [24]
	.long 0x00F8101D	; [25]
	.long 0x00F8101D	; [26]
	.long 0x00F8101D	; [27]
	.long 0x00F8101D	; [28]
	.long 0x00F8101D	; [29]
	.long 0x00F8101D	; [30]
	.long 0x00F8101D	; [31]

; --- table 31 of 32: 16 distinct targets; named by the `ld XIX` at 0xF7D2A9
Table_F7E258:
	.long 0x00F81101	; [ 0]
	.long 0x00F81102	; [ 1]
	.long 0x00F8111E	; [ 2]
	.long 0x00F81136	; [ 3]
	.long 0x00F81137	; [ 4]
	.long 0x00F81165	; [ 5]
	.long 0x00F81166	; [ 6]
	.long 0x00F81185	; [ 7]
	.long 0x00F8119D	; [ 8]
	.long 0x00F8119E	; [ 9]
	.long 0x00F811E2	; [10]
	.long 0x00F811FF	; [11]
	.long 0x00F81230	; [12]
	.long 0x00F81230	; [13]
	.long 0x00F81230	; [14]
	.long 0x00F81224	; [15]
	.long 0x00F81230	; [16]
	.long 0x00F81230	; [17]
	.long 0x00F81102	; [18]
	.long 0x00F8111E	; [19]
	.long 0x00F81136	; [20]
	.long 0x00F81137	; [21]
	.long 0x00F81230	; [22]
	.long 0x00F81166	; [23]
	.long 0x00F81185	; [24]
	.long 0x00F81230	; [25]
	.long 0x00F81230	; [26]
	.long 0x00F81231	; [27]
	.long 0x00F81235	; [28]
	.long 0x00F81235	; [29]
	.long 0x00F81235	; [30]
	.long 0x00F81235	; [31]

; --- 0xF7E2D8-0xF7FFFF: not converted ---
	.incbin "original_ROMs/wsa1_prom_b.ic13", 0x07E2D8, 0x001D28
end:
