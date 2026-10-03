; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xF99063-0xF990F9  INTT1, the six-phase scheduler tick
; ==============================================================================
;
; 136 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
; `.include`s this file at the line the block started on, so the assembler
; sees the same token stream in the same order and the ROM is unchanged:
;
;     python3 scripts/analysis/assert_byte_identical.py    <- the bytes
;     python3 notes/prom_c_split.py --verify               <- the text
;
; ★ EVERY LINE BELOW THIS HEADER IS VERBATIM.  Nothing was reworded, and
;   --verify fails on a single changed character.
;
; WHY THIS IS ONE SUBJECT:
; Banner-declared.  The timer-1 interrupt that posts the work bits MAIN's
; loop consumes; it belongs beside MAIN, not beside the kernel (the kernel
; is CPU-shared source and lives in kernel/kernel.s).
;
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xF99063-0xF990F9 -- INTT1, the six-phase scheduler tick
; ==============================================================================
; --------------------------------------------------------------------------
; INTT1_HANDLER -- timer-1 ISR: bump the tick counter and post the next phase's
;             work bits.
;
; Called from: vector table offset 0x44 (INTT1) -> 0x00FFF0BC (IRQ_INTT1), which
;              is `jp 0xF99063`.  See VECTORS at the bottom of this file.
; Inputs:  the phase counter, a byte at 0x00E2E3 (work DRAM -- 0x000080-0x01007F
;          is CPU 2's DRAM window, notes/FINDINGS-memory-map.md).
; Outputs: (a) the 32-bit word at 0x00F2F3 is incremented by ONE;
;          (b) bits are SET in the work-request byte at 0x007ED1, which bits
;              depending on the phase;
;          (c) the phase counter advances 0 -> 1 -> ... -> 5 -> 0.
; Evidence: ★★ THIS ANSWERS AN OPEN QUESTION.
;          notes/FINDINGS-prom_c-serial-midi.md records that both serial handlers
;          read 0x00F2F3 as a 32-bit value on every interrupt and that what it
;          counts was NOT ESTABLISHED.  It counts INTT1 interrupts.  The three
;          instructions at 0xF99069 are `sub xbc,xbc` / `inc 1,xbc` /
;          `add (0x00F2F3),xbc` -- a read-modify-write of +1 -- and a census of
;          every literal-addressed reference to it in prom_c shows this is the
;          only one of TWENTY-ONE that writes it; the other twenty are
;          `ld reg,(0x00F2F3)` or `pushw (0x00F2F3)`.  Reproduce:
;              python3 notes/prom_c_xrefs.py 0x00F2F3 --no-window --classify
;          (prints "TOTAL literal-addressed sites: 21").
;          ⚠ CORRECTION, round 2.  This header previously said NINETEEN, from a
;          census that searched the 24-bit-direct spelling only.  0x00F2F3 also
;          fits in 16 bits, and the CPU has a shorter 16-bit-direct form (prefix
;          0xD1 instead of 0xD2); two sites use it and were invisible:
;              f99fc2: d1 f3 f2 23   ld HL,(0xf2f3)
;              f99fcd: d1 f3 f2 21   ld BC,(0xf2f3)
;          both inside the routine at 0xF99FC1, both READS -- so the count
;          was wrong but the conclusion was not.  prom_c_xrefs.py now sweeps all
;          twelve direct-address spellings (4 operand-size prefixes x 3 address
;          widths) and prints the total; its docstring documents the encoding.
;          Re-censused with the fixed tool, 0x007ED1 (14), 0x00F32A (3) and
;          0x00F32B (2) are unchanged -- those addresses are only ever spelled
;          24-bit -- so no other header in this file inherits the error.
;          ⚠ Still unsearchable: a write through a POINTER REGISTER.  Read the
;          number as "no other literal-addressed writer", which is what it proves.
;          The phase count is SIX, fixed two independent ways: the guard
;          `cps bc,5 / jr ugt` rejects anything above 5, and the jump table's six
;          4-byte entries end exactly on 0xF990E0, the first instruction after
;          it.  The wrap is `inc` then `cp ...,0x06` then reset to 0.
; Unknown:  ⚠ what the six phases are for, and what consumes bits 6 and 7.
;          The main loop at 0xF98C06 tests and clears bits 4, 5 and 3 -- and only
;          those three.  `python3 notes/prom_c_xrefs.py 0x007ED1 --no-window`
;          finds fourteen references in prom_c: the eight `set` instructions in
;          this handler and six in the main loop, three test/clear pairs.  So
;          bits 6 and 7 are SET here and read by NOTHING that names 0x007ED1
;          outright.  Stated as observed; a pointer-based read would be invisible
;          to that scan.
;          The timer-1 period is not established here either, so the tick rate is
;          unknown -- only that everything downstream is paced by it.
;
; The phase-to-bit schedule, read straight off the six blocks below:
;
;     phase 0   set bit 7, set bit 4
;     phase 1   set bit 6
;     phase 2   set bit 5
;     phase 3   set bit 7, set bit 3
;     phase 4   set bit 6
;     phase 5   set bit 5
;
; so bits 7/6/5 repeat with period THREE and bits 4 and 3 alternate with period
; six -- one 3-tick job triple, plus two jobs that each run once per six ticks on
; opposite halves of the cycle.
; --------------------------------------------------------------------------
INTT1_HANDLER:
	push	xbc
	pushw	wa
	link	xiz, 0xfffe
	sub	xbc, xbc
	inc	1, xbc
	add	(0x00F2F3:24), xbc
	ld	wa, (0x00E2E3:24)
	extz	wa
	ld	(xiz-2), wa
	jr	INTT1_HANDLER__dispatch
INTT1_HANDLER__phase0:
	set 7, (0x007ED1:24)
	set 4, (0x007ED1:24)
	jr	INTT1_HANDLER__advance
INTT1_HANDLER__phase1:
	set 6, (0x007ED1:24)
	jr	INTT1_HANDLER__advance
INTT1_HANDLER__phase2:
	set 5, (0x007ED1:24)
	jr	INTT1_HANDLER__advance
INTT1_HANDLER__phase3:
	set 7, (0x007ED1:24)
	set 3, (0x007ED1:24)
	jr	INTT1_HANDLER__advance
INTT1_HANDLER__phase4:
	set 6, (0x007ED1:24)
	jr	INTT1_HANDLER__advance
INTT1_HANDLER__phase5:
	set 5, (0x007ED1:24)
	jr	INTT1_HANDLER__advance
INTT1_HANDLER__dispatch:
	sub	xbc, xbc
	ld	bc, (xiz-2)
	cp	bc, 5:i3
	jr	ugt, INTT1_HANDLER__advance
	sll	bc, 2
	add	xbc, INTT1_PHASE_TABLE
	ld	xbc, (xbc)
	jp	(xbc)
; Evidence: the dispatch immediately above is `cp BC,5 / jr UGT / sll BC,2 /
;          add XBC,0x00F990C8 / ld XBC,(XBC) / jp (XBC)`, so the table BEGINS at
;          0xF990C8 -- this label's own address -- has stride 4 and is bounded at
;          index 5, i.e. SIX entries, 0xF990C8-0xF990DF.  Last-entry test: entry 5
;          is 0x00F990AB, inside the phase-arm run just above, and the next four
;          bytes are `c2 e3 e2 00`, the `incw 1,(0x00E2E3)` that opens
;          INTT1_HANDLER__advance -- so the table ends where this says it does.
INTT1_PHASE_TABLE:
	.long	INTT1_HANDLER__phase0
	.long	INTT1_HANDLER__phase1
	.long	INTT1_HANDLER__phase2
	.long	INTT1_HANDLER__phase3
	.long	INTT1_HANDLER__phase4
	.long	INTT1_HANDLER__phase5
INTT1_HANDLER__advance:
	inc 1, (0x00E2E3:24)
	cp	(0x00E2E3:24), 0x06
	jr	nc, INTT1_HANDLER__wrap
	jr	INTT1_HANDLER__exit
INTT1_HANDLER__wrap:
	ld	(0x00E2E3:24), 0x00
INTT1_HANDLER__exit:
	unlk	xiz
	popw	wa
	pop	xbc
	reti
