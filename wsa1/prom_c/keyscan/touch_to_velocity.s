; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xF99598-0xF9973C  the TOUCH-to-VELOCITY path, and its two setters
; ==============================================================================
;
; 348 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
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
; Banner-declared.  ⚠ This is what the ToneGen_* labels are: a key-strike
; to velocity-byte converter and its curves.  It never touches 0x0010C000 --
; its output goes into a MIDI note-on handed to the link.  Filed under the
; keybed, NOT under the register devices.
;
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xF99598-0xF9973C -- the TOUCH-to-VELOCITY path, and its two setters
; ==============================================================================
;
; This is the consumer of the touch tables in zone 2 -- the routine that turns a
; key strike into the velocity byte the tone generator is given.  It is worth more
; than the tables' names: it fixes their record size, their row count, their pivot
; and their divisor, and it settles what the third column of
; ToneGen_VelCurve_ModeParams is, all from prom_c's own arithmetic.
;
; ★ THE WHOLE TRANSFER FUNCTION, read off 0xF995FF-0xF99728:
;
;     v  = ToneGen_Velocity_Input_Curve[touch]              ; 0xFCC61A, 256 bytes
;     v -= 77                                               ; u16 at 0xFCC5C5
;     v += (signed) NoteTrim[note]                          ; RAM table at 0x0084DA
;     v  = ModeParams[mode].gain * v / 128                  ; u16 at 0xFCC5C7
;     v += ModeParams[mode].pivot
;     if note is a BLACK key:  v -= ModeParams[mode].trim
;     v += (0x00F32B - 0x50)                                ; the offset control
;     clamp v to 0..255
;     out = ToneGen_Velocity_Output_Curve[v]                ; 0xFCC71A
;
; ★ THE TWO CONSTANTS COME OUT OF A BLOCK THIS TREE HAD LABELLED "unexplained".
; The header of `unexplained_FCC5BE` in this file calls its last bytes
; `ff fa fb 4d 00 80 00` unidentified.  Four of them are not: the u16 at 0xFCC5C5
; is 0x004D = 77 and the u16 at 0xFCC5C7 is 0x0080 = 128, and they are the pivot
; subtrahend and the fixed-point divisor of the formula above.  77 is the value of
; the input curve at index 144, and it is the ONLY index where the curve is 77 --
; so the pivot is a single point, and at it the bracket is zero and the output is
; ModeParams[mode].pivot whatever the gain is.  That is exactly what the zone-2
; header already calls that column ("output level at the pivot"), now with the
; pivot located.  (Checked by reading the ROM; the curve is monotonically
; decreasing, 255 at index 0..8 down to 0 at 254..255.)
;
; ★ AND THE "BLACK-KEY TRIM" COLUMN IS PROVEN, NOT ASSUMED.  The zone-2 header
; describes ModeParams' third byte as "trim subtracted for the black keys" on the
; strength of the sibling project.  Here is the WSA1 proof, and it is airtight:
; the note number is divided by 12 (`div c,12` at 0xF9961A), the REMAINDER is
; kept, one is subtracted, values above 9 skip the trim, and the surviving 0..9
; index a ten-entry jump table which sends
;
;     index 0 2 5 7 9   (pitch class 1 3 6 8 10)  ->  0xF9968B, subtract trim
;     index 1 3 4 6 8   (pitch class 2 4 5 7 9)   ->  0xF996A7, do nothing
;
; Pitch classes 1, 3, 6, 8, 10 are C#, D#, F#, G# and A#: the five black keys of
; the octave, all of them and nothing else.  Classes 0 and 11 (C and B) fall out
; through the bound check instead, which is the detail that makes this read
; rather than a pattern-match: the two white keys at the ends of the run are
; excluded by a DIFFERENT mechanism from the eight in the middle, and both
; mechanisms have to agree for the black-key set to come out whole.
; ⚠ The note is offset by 0x24 = 36 before it is stored (0xF995EC), and 36 is a
; whole number of octaves, so the remainder is unaffected.  That is what makes
; the pitch-class reading safe rather than lucky.
;
; ★ TEN ROWS, from a setter that rejects an eleventh.  ToneGen_SetVelCurveMode
; below refuses any mode above 9 before storing it at 0x00F32A, and the record
; stride is 3 (`ld a,3 / mul wa,(0x00F32A)`).  10 x 3 = 30 bytes, which is exactly
; the size the zone-2 chain gives ToneGen_VelCurve_ModeParams.  Three independent
; facts, one answer.
;
; ★ THE OUTPUT IS A 7-BIT VELOCITY.  ToneGen_Velocity_Output_Curve (0xFCC71A) is
; non-decreasing over all 256 entries and spans 1..127 -- never 0, never above
; 127.  The input curve is non-increasing over all 256 entries and spans 255..0.
; So a LARGER argument means a SOFTER note, which is what a key-contact travel
; TIME looks like and not what a velocity looks like; and the result is a
; MIDI-range velocity that can never be a note-off by accident.  (Both curves
; checked entry by entry over their full 256 bytes, directly from the ROM.)
;
; ⚠ NOT ESTABLISHED.  What fills the signed per-note table at 0x0084DA (work
; DRAM) -- it is read here and written somewhere not yet converted, so the
; per-note component of the touch response has an untraced origin.  Neither is
; the physical meaning of the (XIZ+0x08) argument: "travel time" is inferred from
; the curve's direction, not read off a hardware register.
;
; --------------------------------------------------------------------------
; ToneGen_SetVelCurveMode -- store the touch-curve mode, rejecting anything > 9.
;
; Called from: not traced.
; Inputs:  (XIZ+8), a 16-bit stack argument.
; Outputs: 0x00F32A = the argument, if it is 0..9; otherwise nothing at all
;          (the store is jumped over, the old mode stands).
; Evidence: the only write to 0x00F32A in prom_c; the other two references
;          (0xF99623, 0xF9968E) are the `mul` that indexes
;          ToneGen_VelCurve_ModeParams by it.  `python3 notes/prom_c_xrefs.py
;          0x00F32A --no-window --classify`.
; Unknown:  which UI control feeds it.
; --------------------------------------------------------------------------
ToneGen_SetVelCurveMode:
	link32	0xEE, 0x0C, 0x00, 0x00
	cp	(xiz+8), 0x09
	jr	ugt, ToneGen_SetVelCurveMode__reject
	ld	c, (xiz+8)
	ld	(0x00F32A:24), c
ToneGen_SetVelCurveMode__reject:
	unlk32	xiz
	ret

; --------------------------------------------------------------------------
; ToneGen_SetVelOffset -- store the touch OFFSET control, rejecting anything > 0x7F.
;
; Called from: not traced.
; Inputs:  (XIZ+8), a 16-bit stack argument.
; Outputs: 0x00F32B = the argument, if it is 0x00..0x7F.
; Evidence: same shape as ToneGen_SetVelCurveMode, one address along.  It is the
;          only write to 0x00F32B in prom_c; the only other reference is
;          0xF996EC in ToneGen_VelocityFromTouch, which reads it and subtracts
;          0x50 -- so the stored 0..127 is a control centred on 0x50, giving a
;          velocity offset of -80..+47.
; Unknown:  which UI control feeds it, and why the range is asymmetric about the
;          centre it is then given.
; --------------------------------------------------------------------------
ToneGen_SetVelOffset:
	link32	0xEE, 0x0C, 0x00, 0x00
	cp	(xiz+8), 0x7F
	jr	ugt, ToneGen_SetVelOffset__reject
	ld	c, (xiz+8)
	ld	(0x00F32B:24), c
ToneGen_SetVelOffset__reject:
	unlk32	xiz
	ret

; --------------------------------------------------------------------------
; INT4_HANDLER -- INT4: a single RETI.
;
; Called from: vector table offset 0x2C (INT4), which holds 0x00F995C2 directly.
;              Four vectors point straight at a handler instead of going through
;              the trampoline block at 0xFFF0A2 -- INT4, INTT3, INTRX0 and
;              INTTX0.  See VECTORS at the bottom.
; Inputs:  none.  Outputs: none.
; Evidence: the byte at 0xF995C2 is 0x07 and the byte before it is the 0x0E `ret`
;          that ends ToneGen_SetVelOffset, so this is a whole one-instruction
;          routine and not the tail of the routine above it.
; Unknown:  ⚠ why INT4 is armed at all.  INTT2 (0xF99E5E) is the same shape and
;          the note there explains it -- a micro-DMA channel needs its interrupt
;          taken and dismissed for the transfer to be paced.  Nothing in the
;          converted code arms a micro-DMA channel on INT4, so the same
;          explanation is AVAILABLE here but is NOT evidenced.  It may equally be
;          an edge-triggered input that must be acknowledged and ignored.
; --------------------------------------------------------------------------
INT4_HANDLER:
	reti

; --------------------------------------------------------------------------
; Delay_CountdownArg -- spin until the caller's counter argument reaches zero.
;
; Called from: not traced (notes/prom_c_xrefs.py finds no literal reference and
;              no calr displacement reaching 0xF995C3).
; Inputs:  (XIZ+8), a SIGNED 16-bit count, passed on the stack.
; Outputs: none, except that it writes the decremented value back over its own
;          stack argument every pass.
; Evidence: the loop body reads (XIZ+8), decrements it, stores it back to both
;          (XIZ+8) and a frame temporary, and re-reads it next pass; `cps hl,0`
;          with `jr le` on the value BEFORE the decrement is the only exit.  It
;          touches no memory outside its own frame and no peripheral, so burning
;          time is all it can be doing.
; Unknown:  how long one pass takes -- no cycle counts are available in these
;          trees, so the delay cannot be converted to microseconds.
; --------------------------------------------------------------------------
Delay_CountdownArg:
	link32	0xEE, 0x0C, 0xFE, 0xFF
	pushw	hl
Delay_CountdownArg__loop:
	ld	hl, (xiz+8)
	ld	bc, hl
	dec	1, bc
	ld	(xiz-2), bc
	ld	(xiz+8), bc
	cp	hl, 0:i3
	jr	le, Delay_CountdownArg__done
	jr	Delay_CountdownArg__loop
Delay_CountdownArg__done:
	popw	hl
	unlk32	xiz
	ret

; --------------------------------------------------------------------------
; ToneGen_VelocityFromTouch -- turn a key strike into a velocity byte.
;
; Called from: 0xF997C8 and 0xF997E9, both `calr 0xF995DF`, from the two arms of
;              one routine at 0xF9979F.  Found with
;              `python3 notes/prom_c_xrefs.py 0xF995DF --no-window`, then
;              confirmed by disassembling both sites: each pushes the same four
;              arguments in the same order.
; Inputs:  (XIZ+0x08) u16  the touch measurement, index into
;                          ToneGen_Velocity_Input_Curve.
;          (XIZ+0x0a) u16  bit 7 = note ON, bits 6..0 = note number.
;          (XIZ+0x0c) ptr  receives (note & 0x7F) + 0x24, written before anything
;                          else and written even on note-off.
;          (XIZ+0x10) ptr  receives the velocity byte, or 0 on note-off.
;          Globals: mode at 0x00F32A, offset at 0x00F32B, per-note trim table at
;          0x0084DA in work DRAM.
; Outputs: *(XIZ+0x10) = velocity 1..127, or 0.  *(XIZ+0x0c) = transposed note.
; Evidence: the full transfer function, the two constants, the black-key set, the
;          ten-row table size and the 7-bit output range are all derived in the
;          block comment above this routine; each step names the instruction it
;          comes from.
; Unknown:  the origin of the 0x0084DA table; the physical unit of the touch
;          argument; and why the note is transposed by 36 semitones on the way
;          out (36 is three octaves, so it does not disturb the pitch class the
;          black-key test uses -- but what the consumer of (XIZ+0x0c) wants with
;          the shift is not established).
; --------------------------------------------------------------------------
ToneGen_VelocityFromTouch:
	link32	0xEE, 0x0C, 0xF2, 0xFF
	pushw	hl
	pushw	de
	push	xix
	ld	c, (xiz+10)
	res	7, c
	add	c, 36
	ld	h, c
	ld	xbc, (xiz+12)
	ld	(xbc), h
	ld	c, (xiz+10)
	and	c, 128
	jrl	z, ToneGen_VelocityFromTouch__note_off
	ld	bc, (xiz+8)
	extz	bc
	extz	xbc
	add	xbc, 0x00FCC61A
	ld	a, (xbc)
	ld	(xiz-1), a
	ld	xbc, (xiz+12)
	ld	w, (xbc)
	ld	c, w
	extz	bc
	div	c, 12
	ld	(xiz-7), b
	ld	a, 3:opc
	extpfx5	0xC2, 0x2A, 0xF3, 0x00, 0x41
	extz	xwa
	ld	xix, xwa
	add	xwa, 0x00FCC5FC
	ld	c, (xwa)
	extz	bc
	ld	hl, bc
	ld	wa, (xiz-1)
	extz	wa
	ld	de, wa
	sub de, (0x00FCC5C5:24)
	ld	a, (xiz+10)
	res	7, a
	extz	wa
	extz	xwa
	add	xwa, 0x000084DA
	ld	w, (xwa)
	ld	a, w
	exts	wa
	add	wa, de
	muls	xbc, xwa
	exts	xbc
	extpfx5	0xD2, 0xC7, 0xC5, 0xFC, 0x59
	exts	xbc
	ld	(xiz-14), xbc
	ld	xwa, xix
	inc	1, xwa
	add	xwa, 0x00FCC5FC
	ld	w, (xwa)
	ldb_erp	w, 0xF4
	extz	iy
	extz	xiy
	add	xbc, xiy
	ld	(xiz-6), xbc
	ld	wa, (xiz-7)
	extz	wa
	ld	(xiz-10), wa
	jr	ToneGen_VelocityFromTouch__pitchclass
ToneGen_VelocityFromTouch__black_key:
	ld	c, 3:opc
	extpfx5	0xC2, 0x2A, 0xF3, 0x00, 0x43
	extz	xbc
	inc	2, xbc
	add	xbc, 0x00FCC5FC
	ld	a, (xbc)
	extz	wa
	extz	xwa
	sub	(xiz-6), xwa
	jr	ToneGen_VelocityFromTouch__offset
ToneGen_VelocityFromTouch__white_key:
	jr	ToneGen_VelocityFromTouch__offset
ToneGen_VelocityFromTouch__pitchclass:
	sub	xbc, xbc
	ld	bc, (xiz-10)
	dec	1, bc
	cp	bc, 0x0009
	jr	ugt, ToneGen_VelocityFromTouch__white_key
	sll	bc, 2
	add	xbc, 0x00F996C3
	ld	xbc, (xbc)
	jp	(xbc)
; ----------------------------------------------------------------------------
; ToneGen_BlackKeyTrim_Table -- 0xF996C3..0xF996EA  (40 bytes)
;
; TEN 32-bit jump targets, indexed by (note mod 12) - 1.  The count is fixed
; twice over: `cp bc,0x0009 / jr ugt` rejects anything above 9, and ten 4-byte
; entries from 0xF996C3 end exactly on 0xF996EB, which is the next instruction
; the routine executes.  The LAST entry was checked as well as the first --
; 0xF996E7 holds 8b 96 f9 00 = 0xF9968B, the apply-trim arm, which is what pitch
; class 10 (A#) has to be.
; Only two distinct targets appear:
;     0xF9968B  subtract ModeParams[mode].trim   (entries 0,2,5,7,9)
;     0xF996A7  fall through, no trim            (entries 1,3,4,6,8)
; ----------------------------------------------------------------------------
ToneGen_BlackKeyTrim_Table:
	.long	0x00F9968B
	.long	0x00F996A7
	.long	0x00F9968B
	.long	0x00F996A7
	.long	0x00F996A7
	.long	0x00F9968B
	.long	0x00F996A7
	.long	0x00F9968B
	.long	0x00F996A7
	.long	0x00F9968B
ToneGen_VelocityFromTouch__offset:
	ld	bc, (0x00F32B:24)
	extz	bc
	extz	xbc
	sub	xbc, 80
	add	(xiz-6), xbc
	ld	xbc, (xiz-6)
	cp	xbc, 255
	jr	le, ToneGen_VelocityFromTouch__no_clip_hi
	ld	xwa, 255
	ld	(xiz-6), xwa
ToneGen_VelocityFromTouch__no_clip_hi:
	ld	xbc, (xiz-6)
	cp	xbc, 0
	jr	ge, ToneGen_VelocityFromTouch__no_clip_lo
	sub	xwa, xwa
	ld	(xiz-6), xwa
ToneGen_VelocityFromTouch__no_clip_lo:
	lda	xbc, (0x00FCC71A:24)
	extpfx3	0xAE, 0xFA, 0x81
	ld	a, (xbc)
	ld	xbc, (xiz+16)
	ld	(xbc), a
	jr	ToneGen_VelocityFromTouch__exit
ToneGen_VelocityFromTouch__note_off:
	ld	xbc, (xiz+16)
	ld	(xbc), 0
ToneGen_VelocityFromTouch__exit:
	pop	xix
	popw	de
	popw	hl
	unlk32	xiz
	ret
