; ==============================================================================
; maincpu/shared/lcd_screen_redraw.s -- ONE SOURCE, INCLUDED AT BOTH SITES
; ==============================================================================
;
; prom_a and prom_b are two EPROMs on one bus carrying one program: prom_b at
; 0xF00000-0xF7FFFF and prom_a at 0xF80000-0xFFFFFF, contiguous, both on CS2.
; The pair is at 0xF999F0-0xF99A03 in prom_a and at 0xF7E2D9-0xF7E2EC in
; prom_b, 20 bytes, byte-identical.  They are ADJACENT in both images, which is
; itself evidence that the two copies come from one source object.
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
; LCD_ScreenRedraw_Begin -- blank the panel, re-issue SYSTEM SET, select layer 0
;
; Called from: prom_a Paint_SysexBulkDump (`calr`) at 0xF99A25
;          prom_a Paint_Sending (`calr`) at 0xF99B89
;          prom_a Paint_SystemExclusivePleaseWait (`calr`) at 0xF99CA8
;          prom_a Paint_GeneralMidiMode (`calr`) at 0xF99D3F
; Issues:  SWI7 service 0x0C at 0xF999F4 -- LCD_Svc_0C_SetLayersOn, rebuild DISP ON: C bits 0/1/2 = layers 1/2/3 steady on
; Issues:  SWI7 service 0x10 at 0xF999F7 -- LCD_Svc_10_SetPanel3Layer, re-issue SYSTEM SET for a three-layer panel
; Evidence: its four instructions before the `ret` are `ld C,0x00` + service 0x0C, then
;           service 0x10, then `ld (0x2540),0x00`.  Service 0x0C REBUILDS the DISP ON
;           byte from C, so C = 0 turns all three layers off and sets bit 0 of (0xC6),
;           the driver's do-not-poll-BUSY flag; 0x10 re-issues SYSTEM SET for a
;           three-layer panel; (0x2540) is the current-layer number.  It is called
;           FIRST by every one of its callers and LCD_ScreenRedraw_End LAST by the same
;           callers -- checked at all ten sites by --services.
; Named by notes/prom_a_understanding_round6.py --apply; the byte gate
;          is blind to this name, --verify reads it back.
; ---------------------------------------------------------------------
; >>>>>> prom_b/wsa1_prom_b.s's header, moved here verbatim >>>>>>>>>>>>>>>>>>>>>
; ---------------------------------------------------------------------
; LCD_ScreenRedraw_Begin -- blank the panel, re-issue SYSTEM SET for three
;                           layers, select layer 0 -- prom_b's own copy of
;                           the prom_a routine of this name
;
; Called from: call from prom_b 0xF7E3F9; call from prom_b 0xF7E619; call
;              from prom_a 0xF80265; calr from prom_b 0xF7E47B; calr from
;              prom_b 0xF7E997; calr from prom_b 0xF7EAE6; and 10 more
; Evidence: byte-identical to prom_a's LCD_ScreenRedraw_Begin (0xF999F0)
;           over BOTH whole extents: 14 bytes here, 14 bytes there,
;           differing in 0 of 14 positions. Each ends at its own `ret`, so
;           this is not a prefix match. --selftest re-reads both from the
;           ROM images and re-compares them.
; ---------------------------------------------------------------------
LCD_ScreenRedraw_Begin:
	ld c, 0x00:opc                                   ; F999F0/F7E2D9  23 00   ld C,0x00
	ld a, 0x0c:opc                                   ; F999F2/F7E2DB  21 0c   ld A,0x0c
	swi 7                                         ; F999F4/F7E2DD  ff   swi 7
	ld a, 0x10:opc                                   ; F999F5/F7E2DE  21 10   ld A,0x10
	swi 7                                         ; F999F7/F7E2E0  ff   swi 7
	ld (LCD_CurrentLayer:16), 0x00                          ; F999F8/F7E2E1  f1 40 25 00 00   ld (0x2540),0x00
	ret                                           ; F999FD/F7E2E6  0e   ret

; >>>>>> prom_a/wsa1_prom_a.s's header, moved here verbatim >>>>>>>>>>>>>>>>>>>>>
; ---------------------------------------------------------------------
; LCD_ScreenRedraw_End -- make all three layers visible again
;
; Called from: prom_a Paint_SysexBulkDump (`calr`) at 0xF99A4A
;          prom_a Paint_Sending (`calr`) at 0xF99BE9
;          prom_a Paint_SystemExclusivePleaseWait (`calr`) at 0xF99D08
;          prom_a Paint_GeneralMidiMode (`calr`) at 0xF99DC2
; Issues:  SWI7 service 0x0C at 0xF99A02 -- LCD_Svc_0C_SetLayersOn, rebuild DISP ON: C bits 0/1/2 = layers 1/2/3 steady on
; Evidence: `ld C,0x07` + `ld A,0x0C` + `swi 7` + `ret`, six bytes.  In service 0x0C's
;           own documented convention C bits 0/1/2 select layers 1/2/3, so 0x07 is all
;           three steady on, and a non-zero DISP byte also clears (0xC6) bit 0.  It is
;           the LAST call of each of its four callers.
; Named by notes/prom_a_understanding_round6.py --apply; the byte gate
;          is blind to this name, --verify reads it back.
; ---------------------------------------------------------------------
; >>>>>> prom_b/wsa1_prom_b.s's header, moved here verbatim >>>>>>>>>>>>>>>>>>>>>
; ---------------------------------------------------------------------
; LCD_ScreenRedraw_End -- make all three layers visible again -- prom_b's
;                         own copy of the prom_a routine of this name
;
; Called from: call from prom_b 0xF7E41C; call from prom_b 0xF7E675; call
;              from prom_a 0xF802E7; call from prom_a 0xF80E96; calr from
;              prom_b 0xF7E4A7; calr from prom_b 0xF7E4F5; and 12 more
; Evidence: byte-identical to prom_a's LCD_ScreenRedraw_End (0xF999FE) over
;           BOTH whole extents: 6 bytes here, 6 bytes there, differing in 0
;           of 6 positions. Each ends at its own `ret`, so this is not a
;           prefix match. --selftest re-reads both from the ROM images and
;           re-compares them.
; ---------------------------------------------------------------------
LCD_ScreenRedraw_End:
	ld c, 0x07:opc                                   ; F999FE/F7E2E7  23 07   ld C,0x07
	ld a, 0x0c:opc                                   ; F99A00/F7E2E9  21 0c   ld A,0x0c
	swi 7                                         ; F99A02/F7E2EB  ff   swi 7
	ret                                           ; F99A03/F7E2EC  0e   ret
