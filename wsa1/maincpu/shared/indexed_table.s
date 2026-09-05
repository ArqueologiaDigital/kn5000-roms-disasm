; ==============================================================================
; maincpu/shared/indexed_table.s -- ONE SOURCE, INCLUDED AT BOTH SITES
; ==============================================================================
;
; prom_a and prom_b are two EPROMs on one bus carrying one program: prom_b at
; 0xF00000-0xF7FFFF and prom_a at 0xF80000-0xFFFFFF, contiguous, both on CS2.
; This routine is at 0xFB77D8 in prom_a and at 0xF55321 in prom_b, 27
; bytes, byte-identical.
;
; ★ WHY THE ROUTINE IS THERE TWICE, measured rather than assumed:
;
;     python3 notes/maincpu_join_probe.py --collisions --callers --nearest
;
;   The obvious reading -- "each ROM carries its own copy so it can be called
;   without a bank switch" -- is REFUTED by this machine's own call sites.
;   There is no bank: prom_a's and prom_b's linker scripts put them in one flat
;   window.  And prom_a calls prom_b's copies SIXTEEN times, thirteen of them
;   with `calr`, a 16-bit PC-relative call that could not cross a bank if one
;   existed.
;
;   What IS true is decidable and holds without exception: of the 63 references
;   to the six copies, all 63 bind to the copy NEAREST IN THE ADDRESS SPACE.
;   prom_a's boot block at 0xF80000 calls the copy at 0xF7E2D9, just below it,
;   while prom_a's UI block at 0xF99021 calls the copy at 0xF999F0, inside it.
;   That is a routine emitted once per LINK UNIT with each unit's references
;   bound to its own copy -- and it is why the chip boundary is invisible to the
;   call graph.  It is the same shape as kernel/kernel.s, one step down: there,
;   one source serves two PROCESSORS; here, one source serves two link units of
;   one processor.
;
; ⚠ THE BYTE GATE IS THE PROOF.  This file is assembled twice, into two images,
;   at two addresses, and both must still reproduce their EPROM exactly:
;
;     python3 scripts/analysis/assert_byte_identical.py
;
;   Two listings that look alike prove nothing.  One source that assembles to
;   both cannot be a resemblance.
;
; ⚠ EVERY LINE CARRIES BOTH ADDRESSES -- `; FB77D8/F55321` -- which is the same
;   line shape kernel/kernel.s uses and which NO prom_*.s file uses.  Any tool
;   that scans a source by address has to be told about it or it silently
;   measures a tree with this file missing.  notes/reachability.py knows.
; ==============================================================================

; >>>>>> prom_a/wsa1_prom_a.s's header, moved here verbatim >>>>>>>>>>>>>>>>>>>>>
; ---------------------------------------------------------------------
; IndexedTable_GetPtr -- pointer n of the table whose base is the 32-bit
;                        word at RAM 0x60F018
;
; Called from: 3 proven sites in prom_a.
; Inputs:  (XIZ+8) = a 16-bit index.  Outputs: XIY = base[index].
; ★ BORROWED NAME, WITH THE DIFF: prom_b 0xF55321 carries this name
;          already, and the two routines are the same 27 bytes with
;          **0 differing** -- ROM_A[0xFB77D8..0xFB77F2] ==
;          ROM_B[0xF55321..0xF5533B].  Check N4 recomputes both the length
;          and the differing count; a borrowed name with no diff behind it
;          is exactly what this tree's rules forbid.
; Unknown:  what the table holds and who writes (0x60F018) -- prom_b's
;          header says the same, and this rename does not change that.
; ---------------------------------------------------------------------
; >>>>>> prom_b/wsa1_prom_b.s's header, moved here verbatim >>>>>>>>>>>>>>>>>>>>>
; ---------------------------------------------------------------------
; IndexedTable_GetPtr -- pointer n of the table whose base is the word at
;                        0x60F018
; Called from: thunk T_IndexedTable_GetPtr (0xF42C8C), 45 opcode-anchored references
; Inputs:  (XIZ+8) = 16-bit index
; Outputs: XIY = the 32-bit pointer at base + 4*index
; Evidence: `ld XIX,(0x60F018)` loads the base from RAM, `ld C,4 / mul BC,(XIZ+8)
;           / extz XBC / add XBC,XIX / ld XWA,(XBC) / ld XIY,XWA`.
; Unknown:  what the table holds and who writes 0x60F018.
; ---------------------------------------------------------------------
IndexedTable_GetPtr:
	link XIZ,0x0000                               ; FB77D8/F55321  ee 0c 00 00   link XIZ,0x0000
	push XIX                                      ; FB77DC/F55325  3c   push XIX
	ld xix, (0x60f018:24)                        ; FB77DD/F55326  e2 18 f0 60 24   ld XIX,(0x60f018)
	ld c, 0x04:opc                                   ; FB77E2/F5532B  23 04   ld C,0x04
	m_mul MBD+r6, 0x08, 3                         ; FB77E4/F5532D  8e 08 43   mul BC,(XIZ+0x08)
	extz XBC                                      ; FB77E7/F55330  e9 12   extz XBC
	add XBC,XIX                                   ; FB77E9/F55332  ec 81   add XBC,XIX
	ld XWA,(XBC)                                  ; FB77EB/F55334  a1 20   ld XWA,(XBC)
	ld XIY,XWA                                    ; FB77ED/F55336  e8 8d   ld XIY,XWA
	pop XIX                                       ; FB77EF/F55338  5c   pop XIX
	unlk XIZ                                      ; FB77F0/F55339  ee 0d   unlk XIZ
	ret                                           ; FB77F2/F5533B  0e   ret
