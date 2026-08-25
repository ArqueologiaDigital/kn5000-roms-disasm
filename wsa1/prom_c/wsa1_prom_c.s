	.text

; ==============================================================================
; Technics SX-WSA1R -- wsa1_prom_c.ic28
; Target CPU: Toshiba TMP95C061 (TLCS-900/H), "CPU 2" / IC2
; ==============================================================================
;
; IC28, program EPROM of the SECOND processor, base 0xF80000.  Load address
; ESTABLISHED the same way as prom_a: 33 of 64 words at file offset 0x7FF00
; point into 0xF00000-0xFFFFFF, and the reset word 0x00FFF000 lands on a
; textbook TLCS-900 boot block.
;
; CPU 2 is a separate address space from CPU 1.  It owns the flash, the
; expansion-board connector and a cluster of address/data device ports; the two
; processors talk over a byte port with a two-wire handshake (0x100000 on this
; side, 0x7C0000 on CPU 1's).  See notes/FINDINGS-memory-map.md.
;
; STATUS: partially converted.  Converted so far, as real assembly / decoded data:
;   0xF98000-0xF980E9  the four channel-register writers for the device at
;                      0x00E00000.  Two of them are byte-identical to the KN5000
;                      sub-CPU's, and the ONE byte that differs is the peripheral
;                      base address
;   0xF980EA-0xF9810D  EntryPoint_Records -- three {entry, stack, ?} records
;   0xF98112-0xF9816A  the endless DSP refresh entry point, and INTT3
;   0xF98B20-0xF98CB8  ★ CPU 2's MAIN LOOP and its four helpers.  This is what
;                      consumes the work bits INTT1 posts
;   0xF989EF-0xF98A0A  RamImage_Copy -- the 4,312-byte boot copy that gives every
;                      CPU-2 variable a known default (notes/FINDINGS-prom_c-ram-image.md)
;                      -- and ADC_Init
;   0xF99063-0xF990F9  INTT1 -- the tick counter and the six-phase scheduler
;   0xF990FA-0xF991FE  timer 1, the 0x108000 preload, the UART init (this is the
;                      routine notes/FINDINGS-system-clock.md argues from), and
;                      the MIDI receive dequeue
;   0xF991FF-0xF992A6  INTRX0 / INTTX0 -- the serial-channel-0 handlers.  SC0 is
;                      the MIDI port; the argument is in the headers there and in
;                      notes/FINDINGS-prom_c-serial-midi.md
;   0xF99598-0xF9973C  ★ the TOUCH-to-VELOCITY path -- the consumer that proves
;                      the zone-2 touch tables' record size, row count, pivot,
;                      divisor and black-key column -- plus INT4 and two setters
;   0xF99BBE-0xF99CFD  ★ INT0 -- the CPU-1 link command dispatcher, its jump
;                      table AND all seven command arms
;   0xF99CFE-0xF99E5D  ★ INTTC2 / INTTC3 -- micro-DMA completion, the 9-entry
;                      state table AND all nine state arms.  Together with the
;                      INT0 arms this is the whole receive half of the
;                      inter-processor link state machine
;   0xF99E5E           INTT2 -- a one-instruction handler
;   0xF99FC1-0xF9A04F  Link_WaitBlockDone, the seven micro-DMA control-register
;                      helpers and the compiler's block move.  The last eight are
;                      byte-identical to prom_a's, which is where their names
;                      come from
;   0xFCC53F-0xFCD0F6  touch / EQ / mixer-gain / descriptor-string zone, 15
;                      objects, 3,000 bytes (616 of them a deliberate .incbin)
;   0xFDD2AB-0xFDF7DF  the voice / DSP data-table zone -- 43 tables, 9,525 bytes,
;                      36 of them byte-identical to a NAMED table in the KN5000
;                      sub-CPU payload
;   0xFFF000-0xFFF0E4  RESET and the interrupt trampoline block
;   0xFFF0E5-0xFFFFFF  the RET padding, the vector table, the fc configuration
;                      byte and the build tag -- i.e. the whole 4 KiB tail
;
; The two data zones are GENERATED, not typed: notes/gen_prom_c_tables.py emits
; them from the ROM, and `--verify` re-proves the boundaries from three
; independent facts (byte identity with the sibling at its stated sizes; a table
; chain that closes with no gap or overlap; and prom_c's own code carrying 48 of
; the 58 start addresses as literal address operands).
; The code was converted with unidasm for the semantics and
; notes/prom_c_enc_oracle.py for the llvm-mc spelling -- see
; notes/prom_c-llvm-mc-spellings.md, which also records that the llvm
; DISASSEMBLER must not be trusted here.
;
; Everything else is still .incbin, so it builds byte-exact by construction and
; asserts nothing.  The gate (scripts/analysis/assert_byte_identical.py) must
; print PASS after every edit.
;
; PROVENANCE: this is not a chip read.  It is the publicly redistributed v2
; firmware set (../technics_roms/roms/wsa1/PROVENANCE.md).

	.include "include/tmp95c061_sfr.inc"

; ==============================================================================
; 0xF80000-0xF97FFF -- not yet converted
; ==============================================================================
wsa1_prom_c:
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x000000, 0x018000

; ==============================================================================
; 0xF98000-0xF980E9 -- the channel-register writers for the device at 0x00E00000
; ==============================================================================
;
; Four routines, 234 bytes, all four of them drivers for the SAME two-register
; port.  They are the only converted code in this image that touches it.
;
; ★ THE PORT, READ OFF THIS CODE ALONE.  0x00E00000 is an ADDRESS/DATA PAIR:
; +0 takes a register number, +2 takes that register's value.  The proof is the
; loop at 0xF9805E, which writes A to (XBC), a byte to (XBC+0x02), and then
; INCREMENTS A once per data byte -- there is no reading of that in which +0 is
; anything but a register selector.  DSP_WriteChannelRegs_Inner says the same
; thing eight times unrolled.
;
; ★ EACH CHANNEL OWNS 32 REGISTERS, AND ITS DATA BLOCK IS AT +0x10.  Both writers
; compute the first register number the same way:
;       sll 0x05,A      ; channel * 0x20
;       set 0x04,A      ; + 0x10
; so channel n's eight data bytes land in registers n*0x20+0x10 .. n*0x20+0x17.
; DSP_ChannelRegs_Init then writes n*0x20+0x1F as well -- the last register of
; each channel's window -- with the constant 0x01.  There are FOUR channels: each
; of the three routines that walks them is unrolled or counted 0,1,2,3.
;
; ⚠ WHAT THE DEVICE IS, IS NOT ESTABLISHED HERE.  notes/FINDINGS-memory-map.md
; already records 0x00E00000 as an address/data pair of unknown identity and
; cites 0xF98057 for it.  The name "DSP" below is the SIBLING PROJECT'S name for
; the device its own byte-identical code drives at ITS base address, and it is
; used here only because two of these four routines are byte-identical to that
; project's and it would be perverse to call the same bytes something else.  It
; is a borrowed name, not a WSA1 finding.
;
; ★★ AND THE BORROWING HAS A LIMIT WORTH RECORDING.  The WSA1 register file is at
; 0x00E00000; the KN5000 sub-CPU's is at 0x00130000.  In
; DSP_WriteChannelRegs_Inner that is the ONLY difference in the whole 81-byte
; routine -- 80 of 81 bytes are identical and the one that differs is a byte of
; the base-address literal:
;
;   $ python3 notes/prom_c_sibling_map.py --addr 0xF98099 --len 81 --diff 0x1FD27
;     80 of 81 bytes identical; 1 differ
;       +0x00F  WSA1 0xF980A8 = 0xE0   KN5000 0x1FD36 = 0x13
;
; A header that had copied the sibling's comment across without running that
; would have written 0x130000 -- a peripheral address that does not exist on this
; machine -- into this tree, and the byte gate would never have noticed.
;
; --------------------------------------------------------------------------
; DSP_ChannelRegs_Init -- zero all four channels' data registers, then arm them.
;
; Called from: 0xF98B95 (`call 0xF98000`), inside the power-on init chain that
;              also calls 0xFB0504, 0xFC88A0, 0xFC8B9C, 0xF9993E, 0xF9919F and
;              then reads the fc byte at 0xFFFFEF (0xF98BA0) -- i.e. this runs
;              once at boot.  Found with notes/prom_c_xrefs.py 0xF98000.
; Inputs:  none.
; Outputs: registers n*0x20+0x10 .. +0x17 = 0 and register n*0x20+0x1F = 0x01,
;          for n = 0..3, in the device at 0x00E00000.
; Evidence: the eight zero bytes come from `xor xwa,xwa` stored twice into the
;          8-byte stack buffer at (XIZ-8), whose address is then passed to
;          DSP_ChannelRegs_Write8 four times with channel = 0,1,2,3.  The final
;          loop writes XWA = 0x0101001F as a 32-bit store to the port with A
;          stepping 0x1F, 0x3F, 0x5F, 0x7F.
; Unknown:  what register 0x1F does.  Also: the 32-bit store puts the register
;          number in BOTH byte +0 and byte +1 (`ld w,a` immediately before it)
;          and 0x01 in both +2 and +3.  Whether +1 and +3 are the high halves of
;          16-bit registers or ignored mirrors is NOT ESTABLISHED.
; Sibling:  the same routine, instruction for instruction, is
;          DSP_Init_Channels at KN5000 0x1FC95
;          (../kn5000-roms-disasm/v142/subcpu/kn5000_subprogram_v142.s:396).
;          ⚠ It is NOT byte-identical and must not be quoted as if it were: the
;          KN5000 fills its buffer with the test pattern 0x5A5A5A5A where this
;          one fills it with zero, which makes it five bytes longer and shifts
;          everything after; and it passes the channel number in BC and the
;          buffer pointer in XWA where this one passes both on the stack.  Run
;          `notes/prom_c_sibling_map.py --addr 0xF98000 --len 0x4A --diff 0x1FC95`
;          to see that only 12 of 74 bytes line up.
; --------------------------------------------------------------------------
DSP_ChannelRegs_Init:
	link32	0xEE, 0x0C, 0xF8, 0xFF	; frame: 8 bytes of channel data
	xor	xwa, xwa
	ld	(xiz-8), xwa		; buffer[0..3] = 0
	ld	(xiz-4), xwa		; buffer[4..7] = 0
	lda	xiy, (xiz-8)		; XIY = &buffer
	push	xiy
	pushw	0x0000			; channel 0
	calr	(0xF9804A - 0xF98016)	; DSP_ChannelRegs_Write8
	push	xiy
	pushw	0x0001			; channel 1
	calr	(0xF9804A - 0xF9801D)
	push	xiy
	pushw	0x0002			; channel 2
	calr	(0xF9804A - 0xF98024)
	push	xiy
	pushw	0x0003			; channel 3
	calr	(0xF9804A - 0xF9802B)
	add	xsp, 0x18		; drop 4 x (pointer + channel word)
	ld	xbc, 0x00E00000		; the register port
	ld	xwa, 0x0101001F		; A = register 0x1F, data 0x01
	ldb	d, 0x04			; four channels
DSP_ChannelRegs_Init__loop:
	ld	w, a
	ld	(xbc), xwa		; +0 = reg number, +2 = 0x01
	add	a, 0x20			; next channel's window
	djnz8	d, DSP_ChannelRegs_Init__loop
	unlk32	xiz
	ret

; --------------------------------------------------------------------------
; DSP_ChannelRegs_Write8 -- write 8 bytes into one channel's data registers.
;
; Called from: DSP_ChannelRegs_Init (four calr sites, 0xF98013/1A/21/28) and
;              from 0xF98130, 0xF9813F, 0xF9814E, 0xF9815D, which are the four
;              calls inside DSP_ChannelRefresh_Loop (0xF98118, converted below --
;              an interrupt-disabled endless loop that is the third entry in
;              EntryPoint_Records).  notes/prom_c_xrefs.py 0xF9804A.
; Inputs:  (XSP+4) = channel number 0..3, (XSP+6) = pointer to 8 bytes.
;          Caller-cleaned: every call site drops 6 bytes afterwards.
; Outputs: registers channel*0x20+0x10 .. +0x17 of the device at 0x00E00000.
; Evidence: `sll 0x05,A` + `set 0x04,A` on the stacked channel number forms the
;          base register; `ldb_spi e,0xF4` is `ld E,(XIY+)`, a post-incrementing
;          byte fetch, and D = 8 counts the loop.
; Unknown:  nothing about the loop; what the eight registers mean is not
;          determined by this routine.
; Sibling:  corresponds to DSP_Write_Channel at KN5000 0x1FCDE
;          (kn5000_subprogram_v142.s:439), which has the same body but takes its
;          arguments in registers.  NOT byte-identical -- see the diff quoted in
;          the block comment above.
; --------------------------------------------------------------------------
DSP_ChannelRegs_Write8:
	ld	a, (xsp+4)		; channel number
	ld	xiy, (xsp+6)		; source pointer
	pushw	de
	sll	a, 5			; channel * 0x20
	set	4, a			; + 0x10 -> first data register
	ld	xbc, 0x00E00000
	ldb	d, 0x08			; eight registers
DSP_ChannelRegs_Write8__loop:
	ld	(xbc), a		; select register A
	ldb_spi	e, 0xF4			; ld E,(XIY+)
	ld	(xbc+2), e		; write its value
	inc	1, a
	djnz8	d, DSP_ChannelRegs_Write8__loop
	popw	de
	ret

; --------------------------------------------------------------------------
; DSP_WriteAllChannelRegs -- write the caller's registers into all four channels.
;
; Called from: NOT TRACED.  notes/prom_c_xrefs.py finds no absolute literal and
;              no calr displacement anywhere in prom_c that reaches 0xF9806D, and
;              that tool does not search the short PC-relative forms, so this is
;              "not found", not "unreferenced".
; Inputs:  XBC and XDE hold four of the eight bytes for channel 1; the previous
;          register bank's QBC/QDE hold the other four (the inner routine reads
;          them).  XIZ, XWA/XHL and XIX/XIY supply channels 0, 2 and 3.
; Outputs: 32 registers -- eight in each of channels 0..3.
; Evidence: ★ BYTE-IDENTICAL, all 44 bytes, to the KN5000 sub-CPU routine of this
;          name at 0x1FCFB (kn5000_subprogram_v142.s:462).  Checked with
;          `python3 notes/prom_c_sibling_map.py --sym DSP_WriteAllChannelRegs`,
;          which reports the same 44 bytes at prom_a 0xF85F7C as well -- BOTH
;          WSA1 processors carry this routine.
;          Structure independent of the sibling: four calls to 0xF98099, each
;          preceded by `pushw n` for n = 1,0,2,3, and `inc 8,xsp` at the end
;          drops exactly those four words.
; Unknown:  why the channel order is 1,0,2,3 rather than 0,1,2,3.  The sibling
;          has the same order, so it is not a WSA1 quirk.
; --------------------------------------------------------------------------
DSP_WriteAllChannelRegs:
	push	xbc
	push	xde
	pushw	0x0001			; channel 1 first
	calr	(0xF98099 - 0xF98075)	; DSP_WriteChannelRegs_Inner
	ld	xbc, (xsp+10)		; the XBC pushed on entry
	ld	xde, xiz
	pushw	0x0000			; channel 0
	calr	(0xF98099 - 0xF98080)
	ld	xbc, xwa
	ld	xde, xhl
	pushw	0x0002			; channel 2
	calr	(0xF98099 - 0xF9808A)
	ld	xbc, xix
	ld	xde, xiy
	pushw	0x0003			; channel 3
	calr	(0xF98099 - 0xF98094)
	inc	8, xsp			; drop the four channel words
	pop	xde
	pop	xbc
	ret

; --------------------------------------------------------------------------
; DSP_WriteChannelRegs_Inner -- write eight registers of ONE channel, unrolled.
;
; Called from: DSP_WriteAllChannelRegs, four calr sites (0xF98072/7D/87/91).
; Inputs:  (XSP+12) = channel number 0..3 (pushed by the caller).
;          Data: C, B, then QBC's C and B from the previous register bank, then
;          E, D, then QDE's C and B.  Eight bytes, in that order.
; Outputs: registers channel*0x20+0x10 .. +0x17 of the device at 0x00E00000.
; Evidence: ★ 80 of its 81 bytes are identical to the KN5000 sub-CPU's
;          DSP_WriteChannelRegs_Inner at 0x1FD27 (kn5000_subprogram_v142.s:492).
;          The single differing byte is 0xF980A8, inside the base-address
;          literal: 0x00E00000 here, 0x00130000 there.  Reproduce with
;          `python3 notes/prom_c_sibling_map.py --addr 0xF98099 --len 81 --diff 0x1FD27`.
;          The address/data structure is independently visible here: eight
;          (write A to +0, write a byte to +2, inc A) triples.
; Unknown:  what the eight registers hold.  `ld bc,qbc` and `ld bc,qde` reach the
;          PREVIOUS register bank, so two of the eight bytes come from whatever
;          the caller of DSP_WriteAllChannelRegs had in QBC/QDE -- and that
;          caller has not been found (see above), so the data's origin is open.
; --------------------------------------------------------------------------
DSP_WriteChannelRegs_Inner:
	push	xiy
	pushw	wa
	pushw	bc
	ld	a, (xsp+12)		; channel number
	sll	a, 5			; * 0x20
	set	4, a			; + 0x10
	ld	xiy, 0x00E00000		; ⚠ KN5000 has 0x00130000 here -- the one byte
	ld	(xiy), a		; register +0x10
	ld	(xiy+2), c
	inc	1, a
	ld	(xiy), a		; +0x11
	ld	(xiy+2), b
	inc	1, a
	ld	(xiy), a		; +0x12
	ld	bc, qbc			; previous register bank
	ld	(xiy+2), c
	inc	1, a
	ld	(xiy), a		; +0x13
	ld	(xiy+2), b
	inc	1, a
	ld	(xiy), a		; +0x14
	ld	(xiy+2), e
	inc	1, a
	ld	(xiy), a		; +0x15
	ld	(xiy+2), d
	inc	1, a
	ld	(xiy), a		; +0x16
	ld	bc, qde			; previous register bank
	ld	(xiy+2), c
	inc	1, a
	ld	(xiy), a		; +0x17
	ld	(xiy+2), b
	popw	bc
	popw	wa
	pop	xiy
	ret

; ----------------------------------------------------------------------------
; EntryPoint_Records -- 0xF980EA..0xF9810D  (36 bytes)
;
; THREE 12-byte records, {code address, low-RAM address, constant}.  The shape is
; not asserted from the shape alone -- each column is checked:
;
;   * column 1 holds 0x00F98B7D, 0x00FA54DB and 0x00F98118.  The first is MAIN,
;     converted below, and the third is the top of DSP_ChannelRefresh_Loop at 0xF98118
;     (`di` then `link XIZ,0xfffc`).  Both are real entry points; neither is the
;     middle of an instruction.
;   * column 2 holds 0x0000FFF0, 0x0000F980 and 0x0000F480 -- three descending
;     addresses in the top of CPU 2's work DRAM.  0x0000FFF0 is EXACTLY the value
;     RESET installs in XSP (`ld XSP,0x0000FFF0`, in the boot block at the bottom
;     of this file).
;   * column 3 holds 0x00028800, 0x00028800 and 0x00018800 -- the same low half
;     throughout, and a high half of 2, 2, 1.
;
; So the natural reading is {entry point, initial stack pointer, something}.
; ⚠ IT IS ONLY A READING.  Nothing in prom_c refers to 0xF980EA -- neither a
; literal nor a calr displacement (notes/prom_c_xrefs.py) -- so the consumer that
; would settle it has not been found, and the third column is not decoded at all.
; The record COUNT is three because the word after the third record, 0x01010001,
; is not a code address in this image and the run of plausible records stops
; there; that is an argument from the data, and a weaker one than a bound check.
; ----------------------------------------------------------------------------
EntryPoint_Records:
	.long	0x00F98B7D, 0x0000FFF0, 0x00028800	; MAIN
	.long	0x00FA54DB, 0x0000F980, 0x00028800
	.long	0x00F98118, 0x0000F480, 0x00018800	; DSP_ChannelRefresh_Loop

; ==============================================================================
; 0xF9810E-0xF98111 -- not yet converted
; ==============================================================================
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x01810E, 0x000004

; ==============================================================================
; 0xF98112-0xF9816A -- the DSP refresh entry point, and INTT3
; ==============================================================================
; --------------------------------------------------------------------------
; sub_F98112 -- calls 0xF983DC with A = 2.  NOT NAMED: 0xF983DC is unconverted.
;
; Called from: not found.
; Inputs:  none.  Outputs: whatever 0xF983DC does with A = 2.
; Evidence: three instructions, no memory touched.  It is listed only because it
;          is the piece of code between the entry-point table and the refresh
;          loop, and leaving a three-instruction routine inside an .incbin while
;          converting both its neighbours would hide a boundary.
; Unknown:  everything else.
; --------------------------------------------------------------------------
sub_F98112:
	ldb	a, 2
	calr	(0xF983DC - 0xF98117)
	ret


; --------------------------------------------------------------------------
; DSP_ChannelRefresh_Loop -- reload all four channel-register blocks, for ever.
;
; Called from: NOTHING calls it.  Its address, 0xF98118, is the code field of the
;              THIRD record of EntryPoint_Records at 0xF980EA (converted above),
;              paired there with the stack pointer 0x0000F480.  That is the only
;              reference to it in prom_c.
; Inputs:  four buffers in work DRAM: 0x00006612 (used TWICE, for channels 0 and
;          2), 0x00000100 (channel 1) and 0x00000108 (channel 3).
; Outputs: it never returns.  Each pass calls 0xF985F8 with the argument 3, then
;          DSP_ChannelRegs_Write8 four times.
; Evidence: the loop is closed by an unconditional `jr` to 0xF9811E, which is
;          INSIDE the frame the `link32` at 0xF9811A opened -- so the frame is
;          built once and the loop runs below it, which is what an entry point
;          looks like and not what a subroutine looks like.  It also starts by
;          disabling interrupts (`di`, MAME's `ei 0x00`) and never re-enables
;          them.
;          The four calls are DSP_ChannelRegs_Write8 (0xF9804A), converted above:
;          each is `push pointer / pushw channel / call / inc 6,xsp`, matching
;          that routine's stack arguments exactly.
; Unknown:  ⚠ what this is FOR.  An interrupt-disabled endless loop that
;          rewrites the same 32 registers from fixed buffers is what a bench test
;          or a fallback mode looks like; nothing here says which, and the
;          machinery that would choose this entry point over MAIN has not been
;          found.  Reusing 0x6612 for channels 0 and 2 is recorded as observed.
; --------------------------------------------------------------------------
DSP_ChannelRefresh_Loop:
	di
	link32	0xEE, 0x0C, 0xFC, 0xFF
DSP_ChannelRefresh_Loop__top:
	pushw	0x0003
	call	0xF985F8
	inc	2, xsp
	ldw	iy, 0x6612
	extz	xiy
	push	xiy
	pushw	0x0000
	call	0xF9804A
	inc	6, xsp
	ld	xiy, 0x00000100
	push	xiy
	pushw	0x0001
	call	0xF9804A
	inc	6, xsp
	ldw	iy, 0x6612
	extz	xiy
	push	xiy
	pushw	0x0002
	call	0xF9804A
	inc	6, xsp
	ld	xiy, 0x00000108
	push	xiy
	pushw	0x0003
	call	0xF9804A
	inc	6, xsp
	jr	DSP_ChannelRefresh_Loop__top


; --------------------------------------------------------------------------
; INTT3_HANDLER -- timer-3 ISR: bump a counter, then jump into the shared tail.
;
; Called from: vector table offset 0x4C (INTT3), which holds 0x00F98165 directly
;              -- one of the four vectors (with INT4, INTRX0 and INTTX0) that do
;              not go through the trampoline block at 0xFFF0A2.
; Inputs:  none.
; Outputs: the byte at 0x000090 is incremented; control passes to 0xF9831C.
; Evidence: two instructions and no `reti`.  The `jrl` target at 0xF9831C DOES
;          end in `reti` on one path (0xF98325, after `ldc WA,<control reg>` and
;          `cp WA,1`) and on the other pushes seven register pairs and `jrl`s
;          away again -- so the return from interrupt is delegated, and this
;          handler is the head of something larger that is NOT converted here.
;          Timer 3 is the one Timer3_Init programs (TREG3 = 0x2E), so this fires
;          at a fixed rate from shortly after boot.
; Unknown:  ⚠ what 0x000090 counts, and what 0xF9831C decides.  The `ldc`
;          instruction there reads a CPU control register that MAME's
;          disassembler prints as `unknown`, so even the test is not readable
;          without a databook.  Naming this handler after a guess at the tail
;          would be exactly the mistake this tree has already had to retract, so
;          it keeps the vector's name and nothing more.
; --------------------------------------------------------------------------
INTT3_HANDLER:
	extpfx3	0xC0, 0x90, 0x61
	jrl	(0xF9831C - 0xF9816B)

; ==============================================================================
; 0xF9816B-0xF989EE -- not yet converted
; ==============================================================================
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x01816B, 0x000884

; ==============================================================================
; 0xF989EF-0xF98A0A -- the boot RAM image, and the A/D mode register
; ==============================================================================
; --------------------------------------------------------------------------
; RamImage_Copy -- install CPU 2's variable block from ROM.
;
; Called from: RESET, `call 0xF989EF`, as its last act before jumping to the main
;              entry.  Only site (notes/prom_c_xrefs.py 0xF989EF).
; Inputs:  none.
; Outputs: ★ RAM 0x00E2DF-0x00F3B6 = ROM 0xFCB4EA-0xFCC5C1.  4,312 bytes.
; Evidence: the three loads are the three operands of the `ldir` that follows:
;          XIY = source, XIX = destination, BC = count.  That XIX is the
;          DESTINATION and XIY the SOURCE is not a convention picked here -- MAME
;          decodes the 0x85 prefix by setting the LDIR destination pointer from
;          `opcode - 1` and the source from the opcode, giving XIX and XIY
;          (mame/src/devices/cpu/tlcs900/900tbl.hxx:5435-5437, op_LDIR at :2495).
;          `ld XBC,0x000010D8` puts 0x10D8 = 4312 in BC, which is what op_LDIR
;          counts down.
;          ⚠ THIS CORRECTS THE RESET LISTING, which said "0xD8-byte table".
;          Consequences, and the boot value of every variable in the window, are
;          in notes/FINDINGS-prom_c-ram-image.md; `python3
;          notes/prom_c_ram_image.py` re-reads these four instructions and
;          refuses to print anything if they are not exactly these bytes.
; Unknown:  whether the last 131 bytes of the source -- which overlap the data
;          zone's first four objects at 0xFCC53F -- are meant as part of the image
;          or are an overrun.  Two of the corresponding RAM addresses are written
;          at runtime (0xFA561C, 0xFA2DD4), which argues for "meant"; the note
;          leaves it open.
; --------------------------------------------------------------------------
RamImage_Copy:
	lda_24	xiy, 0x00FCB4EA
	lda_24	xix, 0x00E2DF
	ld	xbc, 0x000010D8
	extpfx2	0x85, 0x11
	ret
	.byte	0x0E

; --------------------------------------------------------------------------
; ADC_Init -- write 0x3F to the A/D mode register.
;
; Called from: 0xF98B9D (`calr 0xF98A02`), in MAIN's init chain.
; Inputs:  none.  Outputs: ADMOD = 0x3F.
; Evidence: 0x6D is ADMOD in include/tmp95c061_sfr.inc, whose names come from
;          MAME's symbol table for this exact part.  The routine does nothing
;          else.
; Unknown:  ⚠ what 0x3F selects.  MAME does not decode ADMOD and no databook is
;          available in these trees, so the value is recorded, not read.  What
;          the A/D converter is wired to on this board is likewise unknown --
;          the INTAD vector (0x70) points at IRQ_UNUSED, so whatever it measures
;          is polled, not interrupt-driven.
; --------------------------------------------------------------------------
ADC_Init:
	ldw	bc, ADMOD
	exts	xbc
	ld	(xbc), 0x3F
	ret

; ==============================================================================
; 0xF98A0B-0xF98B1F -- not yet converted
; ==============================================================================
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x018A0B, 0x000115

; ==============================================================================
; 0xF98B20-0xF98CB8 -- CPU 2's MAIN LOOP and the four helpers in front of it
; ==============================================================================
;
; This is the routine everything else in this image hangs off: the power-on init
; chain, then a loop that never returns.  It is also the CONSUMER of the work byte
; the INTT1 scheduler posts into -- which is what makes the scheduler at 0xF99063
; readable at all.
;
; ★ THE LOOP BODY, in order, all of it visible below:
;     1. drain the MIDI receive queue into a 32-byte frame buffer at (XIZ-42),
;        stopping on the 0xFFFF empty sentinel or at 32 bytes;
;     2. if anything was received, hand the buffer to 0xF9997E with the length
;        and the constant 6 -- the same routine, and the same argument shape, that
;        the 0xF98CB9 helper calls with the constant 5;
;     3. test-and-clear bit 4 of 0x007ED1, and on it step a counter at 0x00E2DF
;        with period 14, decrement a countdown at 0x00F2F1, and act on the latch
;        at 0x007ECC.  ⚠ The period is 14, not 13: the counter is incremented
;        and STORED first, and the comparison `cp HL,0x000c` is against the value
;        BEFORE the increment, so 13 is reached and only then cleared;
;     4. test-and-clear bit 5, and on it call 0xF98A75;
;     5. test-and-clear bit 3, and on it call sub_F9915C;
;     6. call 0xF98CB9, then 0xFB060A and 0xF994E4;
;     7. `jrl` back to step 1.  Unconditionally -- the `unlk32`/`ret` after it
;        cannot be reached.
;
; ★ THE SCHEDULER'S BITS ARE CONSUMED HERE AND NOWHERE ELSE.  Together with the
; eight `set` instructions in INTT1_HANDLER these six sites are ALL fourteen
; references to 0x007ED1 in prom_c
; (`python3 notes/prom_c_xrefs.py 0x007ED1 --no-window`).  Each of the three is a
; matched test/clear pair on bits 4, 5 and 3 -- and INTT1 also sets bits 6 and 7,
; which nothing here reads.  That asymmetry is recorded in the INTT1 header and is
; still unexplained.
;
; ⚠ The three bit tests are written as `and C,mask / srl n,C / cps C,0`, i.e. the
; bit is isolated, shifted down to bit 0 and compared -- not `bit`.  Nothing turns
; on that; it is noted because it is what makes the mask and the shift agree and
; therefore what makes the bit NUMBER unambiguous.
;
; --------------------------------------------------------------------------
; Link_SendBuffer -- forward (length, tag, pointer) to the link sender 0xF9997E.
;
; Called from: THIRTEEN sites -- 0xF98AC6 and 0xF98B18 (calr), plus eleven
;              `call`s at 0xF9953D, 0xF99567, 0xF99589, 0xFC1FBC, 0xFC2064,
;              0xFC2155, 0xFC2246, 0xFC237D, 0xFC2425, 0xFC24EB and 0xFC25F5.
;              `python3 notes/prom_c_xrefs.py 0xF98B20 --no-window`.
; Inputs:  (XIZ+0x08) byte, (XIZ+0x0a) word, (XIZ+0x0c) long -- passed straight
;          through, in that order, to 0xF9997E.
; Outputs: whatever 0xF9997E does.
; Evidence: the whole body is three pushes and a call; `inc 8,xsp` afterwards
;          drops exactly the eight bytes pushed.  MAIN and the helper at 0xF98CB9
;          call 0xF9997E directly with the same three-argument shape and the
;          constants 6 and 5 in the middle slot, which is how the argument order
;          is read.
; Unknown:  0xF9997E itself is not converted, so what the middle constant selects
;          is not established.  notes/FINDINGS-memory-map.md records the link
;          protocol's header byte as `(channel << 5) | (len - 1)`, which would
;          make a small constant a CHANNEL -- offered as a lead, not a finding.
; --------------------------------------------------------------------------
Link_SendBuffer:
	link32	0xEE, 0x0C, 0x00, 0x00
	ld	xbc, (xiz+12)
	push	xbc
	extpfx3	0x9E, 0x0A, 0x04
	push	0x00
	extpfx3	0x8E, 0x08, 0x04
	call	0xF9997E
	inc	8, xsp
	unlk32	xiz
	ret


; --------------------------------------------------------------------------
; Delay_CountdownArg_Z -- spin until the caller's counter argument is exactly 0.
;
; Called from: 0xF98B66 (calr, from Serial0_SendByte_Blocking with 200) and
;              0xF9AB31, 0xFA3136, 0xFA337A (call).
; Inputs:  (XIZ+8), a 16-bit stack argument, decremented in place.
; Outputs: none but the burnt time.
; Evidence: identical to Delay_CountdownArg at 0xF995C3 EXCEPT for the exit
;          condition -- `jr z` here against `jr le` there.  The test is on the
;          value BEFORE the decrement either way, so an argument of -1 counts all
;          the way down through 0xFFFE ... 0x0000 here, up to 65,535 passes,
;          where `jr le` exits at once.  Two spellings of the same idea, and the
;          difference is why they are two labels and not one.
; Unknown:  the time per pass; no cycle counts are available in these trees.
; --------------------------------------------------------------------------
Delay_CountdownArg_Z:
	link32	0xEE, 0x0C, 0xFE, 0xFF
	pushw	hl
Delay_CountdownArg_Z__loop:
	ld	hl, (xiz+8)
	ld	bc, hl
	dec	1, bc
	ld	(xiz-2), bc
	ld	(xiz+8), bc
	cps	hl, 0
	jr	z, Delay_CountdownArg_Z__done
	jr	Delay_CountdownArg_Z__loop
Delay_CountdownArg_Z__done:
	popw	hl
	unlk32	xiz
	ret


; --------------------------------------------------------------------------
; Serial0_SendByte_Blocking -- push one byte straight into SC0BUF, then wait.
;
; Called from: not found (no literal reference, no calr displacement).
; Inputs:  (XIZ+8), the byte to send.
; Outputs: SC0BUF = that byte, followed by a fixed delay of 200 counts.
; Evidence: `ld BC,0x0050 / exts XBC / ld (XBC),A` writes SC0BUF, the transmit
;          register of the channel notes/FINDINGS-prom_c-serial-midi.md
;          identifies as the MIDI port.  The `pushw 0x00C8 / calr` afterwards is
;          Delay_CountdownArg_Z with 200.
; Unknown:  ⚠ why this exists at all.  The normal MIDI transmit path is
;          interrupt-driven (INTTX0_HANDLER drains a queue into SC0BUF).  A
;          blocking single-byte writer with a hand-timed delay is what an early
;          boot or a diagnostic uses; with no caller found, which of those it is
;          is NOT ESTABLISHED.
; --------------------------------------------------------------------------
Serial0_SendByte_Blocking:
	link32	0xEE, 0x0C, 0x00, 0x00
	ldw	bc, SC0BUF
	exts	xbc
	ld	a, (xiz+8)
	ld	(xbc), a
	pushw	0x00C8
	calr	(0xF98B39 - 0xF98B69)
	popw	bc
	unlk32	xiz
	ret


; --------------------------------------------------------------------------
; Timer3_Init -- stop timer 3, program it, enable its interrupt, start it.
;
; Called from: 0xF98BAB (`calr 0xF98B6D`), in MAIN's init chain, immediately
;              after Timer1_SetPeriodAndStart.
; Inputs:  none.
; Outputs: TRUN bit 3 cleared, T23MOD = 0x0E, TREG3 = 0x2E, INTET32 = 0x20,
;          TRUN bit 3 set.
; Evidence: the SFR numbers are TRUN 0x20, T23MOD 0x28, TREG3 0x27, INTET32 0x74
;          in include/tmp95c061_sfr.inc.  Stopping the timer, writing its mode
;          and period, enabling its interrupt and starting it -- in that order --
;          is the only reading these five instructions admit.
;          The interrupt it enables has somewhere to go: the vector table's INTT3
;          slot (0x4C) holds 0x00F98165 directly.
; Unknown:  ⚠ the field layouts of T23MOD and INTET32 -- no databook is available
;          in these trees and MAME does not decode them, so 0x0E and 0x20 are
;          recorded as values.  Timer 3's period is 0x2E = 46 COUNTS; the count
;          rate depends on the T23MOD field this pass cannot decode, so the INTT3
;          rate is NOT ESTABLISHED.
; --------------------------------------------------------------------------
Timer3_Init:
	res_dd8	3, TRUN
	ldio	T23MOD, 0x0E
	ldio	TREG3, 0x2E
	ldio	INTET32, 0x20
	set_dd8	3, TRUN
	ret


; --------------------------------------------------------------------------
; MAIN -- CPU 2's initialisation chain and its endless main loop.
;
; Called from: NOTHING calls it.  Its address is the first 32-bit word of the
;              three-record table at 0xF980EA (converted above), and that is the
;              only reference to 0xF98B7D in prom_c.
; Inputs:  none.
; Outputs: it never returns.
; Evidence: the init chain is EIGHT calls in a row before it even reads the fc
;          byte, and four more after it, and four of the twelve are already
;          identified elsewhere in this file -- 0xF9919F is Serial0_Init,
;          0xF98000 is DSP_ChannelRegs_Init, 0xF98B6D is Timer3_Init, and
;          0xF990FA is Timer1_SetPeriodAndStart, called here with the fc byte
;          read from 0xFFFFEF two instructions earlier.  The loop is closed by
;          `jrl MAIN__loop` with no condition.
; Unknown:  0xFB0504, 0xFC88A0, 0xFC8B9C, 0xF9993E, 0xF997FA, 0xF98A02,
;          0xFA3127, 0xFB0A0D, 0xF99E5F, 0xFB05EC, 0xF98510, 0xF98A75, 0xF98CB9,
;          0xFB060A and 0xF994E4 are all unconverted.  So the SHAPE of the loop
;          is established and most of the WORK it schedules is not.
;          The frame temporaries are named by offset only: (XIZ-2) is the MIDI
;          byte count, (XIZ-42) the 32-byte MIDI frame buffer, (XIZ-54) and
;          (XIZ-56) are written and not read in this routine.
; --------------------------------------------------------------------------
MAIN:
	link32	0xEE, 0x0C, 0xC8, 0xFF
	call	0xFB0504
	call	0xFC88A0
	call	0xFC8B9C
	call	0xF9993E
	call	0xF9919F
	call	0xF98000
	call	0xF997FA
	calr	(0xF98A02 - 0xF98BA0)
	ldw_da	bc, 0x00FFFFEF
	extz	bc
	pushw	bc
	calr	(0xF990FA - 0xF98BAB)
	calr	(0xF98B6D - 0xF98BAE)
	call	0xFA3127
	call	0xFB0A0D
	popw	bc
	di
	ld	(xiz-45), 0
	ld	(xiz-46), 0
MAIN__loop:
	ldw	(xiz-2), 0x0000
MAIN__midi_drain:
	call	0xF991F4
	ld	hl, wa
	ld	(xiz-54), wa
	cp	hl, 0xffff
	jr	z, MAIN__midi_done
	ld	ix, (xiz-2)
	exts	xix
	ld	xbc, xix
	add	xbc, xiz
	ld	(xbc-42), a
	incm	1, (xiz-2)
	cpw	(xiz-2), 0x0020
	jr	nz, MAIN__midi_more
	jr	MAIN__midi_done
MAIN__midi_more:
	jr	MAIN__midi_drain
MAIN__midi_done:
	cpw	(xiz-2), 0x0000
	jr	z, MAIN__bit4
	lda	xbc, (xiz-42)
	push	xbc
	extpfx3	0x9E, 0xFE, 0x04
	pushw	0x0006
	call	0xF9997E
	inc	8, xsp
MAIN__bit4:
	ldb_da	c, 0x007ED1
	and	c, 0x10
	srl	c, 4
	cps	c, 0
	jr	z, MAIN__bit5
	resda_24 4, 0x007ED1
	call	0xF99E5F
	call	0xFB05EC
	ldw_da	hl, 0x00E2DF
	ld	bc, hl
	inc	1, bc
	ld	(xiz-56), bc
	stw_da	0x00E2DF, bc
	cp	hl, 0x000c
	jr	le, MAIN__no_wrap
	stiw_da	0x00E2DF, 0x0000
MAIN__no_wrap:
	cpw_da	0x00F2F1, 0x0000
	jr	z, MAIN__timer_expired
	decdi16_24 1, 0x00F2F1
	jr	MAIN__bit5
MAIN__timer_expired:
	ei	6
	cpib_da	0x007ECC, 0x00
	jr	z, MAIN__reenable
	di
	stib_da	0x007ECC, 0x00
	stiw_da	0x00F2F1, 0x000A
	pushw	0x0002
	call	0xF98510
	popw	bc
MAIN__reenable:
	di
MAIN__bit5:
	ldb_da	c, 0x007ED1
	and	c, 0x20
	srl	c, 5
	cps	c, 0
	jr	z, MAIN__bit3
	resda_24 5, 0x007ED1
	calr	(0xF98A75 - 0xF98C8A)
MAIN__bit3:
	ldb_da	c, 0x007ED1
	and	c, 0x08
	srl	c, 3
	cps	c, 0
	jr	z, MAIN__tail
	resda_24 3, 0x007ED1
	calr	(0xF9915C - 0xF98CA1)
MAIN__tail:
	calr	(0xF98CB9 - 0xF98CA4)
	lda_24	xbc, 0x00E2EB
	push	xbc
	call	0xFB060A
	call	0xF994E4
	pop	xiy
	jrl	MAIN__loop
	unlk32	xiz
	ret

; ==============================================================================
; 0xF98CB9-0xF99062 -- not yet converted
; ==============================================================================
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x018CB9, 0x0003AA

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
	link32	0xEE, 0x0C, 0xFE, 0xFF
	sub	xbc, xbc
	inc	1, xbc
	addl_da	0x00F2F3, xbc
	ldw_da	wa, 0x00E2E3
	extz	wa
	ld	(xiz-2), wa
	jr	INTT1_HANDLER__dispatch
INTT1_HANDLER__phase0:
	setda_24 7, 0x007ED1
	setda_24 4, 0x007ED1
	jr	INTT1_HANDLER__advance
INTT1_HANDLER__phase1:
	setda_24 6, 0x007ED1
	jr	INTT1_HANDLER__advance
INTT1_HANDLER__phase2:
	setda_24 5, 0x007ED1
	jr	INTT1_HANDLER__advance
INTT1_HANDLER__phase3:
	setda_24 7, 0x007ED1
	setda_24 3, 0x007ED1
	jr	INTT1_HANDLER__advance
INTT1_HANDLER__phase4:
	setda_24 6, 0x007ED1
	jr	INTT1_HANDLER__advance
INTT1_HANDLER__phase5:
	setda_24 5, 0x007ED1
	jr	INTT1_HANDLER__advance
INTT1_HANDLER__dispatch:
	sub	xbc, xbc
	ld	bc, (xiz-2)
	cps	bc, 5
	jr	ugt, INTT1_HANDLER__advance
	sll	bc, 2
	add	xbc, 0x00F990C8
	ld	xbc, (xbc)
	jp	(xbc)
INTT1_PHASE_TABLE:
	.long	0x00F9907E
	.long	0x00F9908A
	.long	0x00F99091
	.long	0x00F99098
	.long	0x00F990A4
	.long	0x00F990AB
INTT1_HANDLER__advance:
	incdi8_24 1, 0x00E2E3
	cpib_da	0x00E2E3, 0x06
	jr	nc, INTT1_HANDLER__wrap
	jr	INTT1_HANDLER__exit
INTT1_HANDLER__wrap:
	stib_da	0x00E2E3, 0x00
INTT1_HANDLER__exit:
	unlk32	xiz
	popw	wa
	pop	xbc
	reti

; ==============================================================================
; 0xF990FA-0xF991FE -- timer 1, the 0x108000 preload, the UART init, MIDI dequeue
; ==============================================================================
; --------------------------------------------------------------------------
; Timer1_SetPeriodAndStart -- load TREG1 from the caller and (re)start timer 1.
;
; Called from: 0xF98BA8 (`calr 0xF990FA`), and from nowhere else that
;              notes/prom_c_xrefs.py can see.  The three instructions in front of
;              that call are
;                  ld BC,(0xFFFFEF) / extz BC / push BC
;              so ★ THE ARGUMENT IS THE fc CONFIGURATION BYTE, 0x1C = 28.
;              TREG1 is therefore loaded with fc IN MHz -- the same trick
;              notes/FINDINGS-system-clock.md documents for the UART, where
;              BR0CR is also computed from that byte so that the bit rate comes
;              out fc-independent.  Two unrelated peripherals scaled off the same
;              byte is what makes "0xFFFFEF is fc" more than an interpretation.
; Inputs:  (XIZ+8), a 16-bit stack argument; only its low byte reaches TREG1.
; Outputs: TRUN bit 1 cleared then set (timer 1 stopped and restarted), TREG1 =
;          the argument, INTET10 = 0x33.
; Evidence: TRUN is 0x20, TREG1 is 0x23 and INTET10 is 0x73 in
;          include/tmp95c061_sfr.inc, whose names come from MAME's symbol table
;          for this exact part.  `and (XBC),0xFD` on TRUN clears bit 1 and
;          `or (XBC),0x02` sets it, which is timer 1's run bit.
; Unknown:  ⚠ the timer-1 CLOCK SOURCE.  This routine does not write T01MOD, and
;          no write to it has been located, so TREG1 = 28 cannot be turned into a
;          tick period here.  The INTT1 rate -- which paces the whole six-phase
;          scheduler at 0xF99063 -- is therefore NOT ESTABLISHED.
;          The 0x33 in INTET10 is recorded as a value, not decoded: no TMP95C061
;          databook is available in these trees and MAME does not decode the
;          interrupt-level registers (see the header of the SFR include).
; --------------------------------------------------------------------------
Timer1_SetPeriodAndStart:
	link32	0xEE, 0x0C, 0x00, 0x00
	push	xix
	ld	xbc, TRUN
	extpfx3	0x81, 0x3C, 0xFD
	ld	xix, TREG1
	ld	c, (xiz+8)
	ld	(xix), c
	ld	xbc, TRUN
	extpfx3	0x81, 0x3E, 0x02
	ld	xbc, INTET10
	ld	(xbc), 0x33
	pop	xix
	unlk32	xiz
	ret


; --------------------------------------------------------------------------
; Dev108000_Preload_80toBF -- write 64 values into the device port at 0x108000.
;
; Called from: RESET at 0xFFF081, and from IRQ_NMI at 0xFFF0AE -- the two places
;              `call 0xF99125` appears (notes/prom_c_xrefs.py 0xF99125).
; Inputs:  none.
; Outputs: 64 write pairs to the 0x108000 port: the 16-bit value 0x0080 + i goes
;          to +2 and the constant 0x8000 goes to +0, for i = 0x00..0x3F.
; Evidence: ★ THIS CORRECTS A COMMENT ALREADY IN THIS FILE.  The RESET listing
;          below described 0xF99125 as "a counted delay (loops to 0x40)".  It
;          does loop to 0x40, and it is not a delay: the loop body loads
;          XBC = 0x00108002 and stores HL, then loads XBC = 0x00108000 and stores
;          0x8000.  0x108000 is one of CPU 2's three address/data device ports
;          (notes/FINDINGS-memory-map.md, which already lists this very site).
; Unknown:  ⚠ which register 0x8000 is, and what the 64 ascending values are.
;          Note also that the ORDER here is value-to-+2 first and 0x8000-to-+0
;          second, the opposite of the address-then-data order the 0xE00000 and
;          0x10C000 drivers use.  So either +0 is a commit/trigger on this device
;          or the port convention differs; NOT ESTABLISHED which.
;          ⚠ And a behavioural oddity worth flagging: NMI runs this and then
;          spins forever (IRQ_NMI__hang).  Whatever the sweep does, on NMI it is
;          the last thing this processor ever does.
; --------------------------------------------------------------------------
Dev108000_Preload_80toBF:
	link32	0xEE, 0x0C, 0xFF, 0xFF
	pushw	hl
	ld	(xiz-1), 0
Dev108000_Preload_80toBF__test:
	cp	(xiz-1), 0x40
	jr	nc, Dev108000_Preload_80toBF__done
	jr	Dev108000_Preload_80toBF__body
Dev108000_Preload_80toBF__next:
	incm8	1, (xiz-1)
	jr	Dev108000_Preload_80toBF__test
Dev108000_Preload_80toBF__body:
	ld	bc, (xiz-1)
	extz	bc
	ld	hl, bc
	add	hl, 0x0080
	ld	xbc, 0x00108002
	ld	(xbc), hl
	ld	xbc, 0x00108000
	extpfx4	0xB1, 0x02, 0x00, 0x80
	jr	Dev108000_Preload_80toBF__next
Dev108000_Preload_80toBF__done:
	popw	hl
	unlk32	xiz
	ret


; --------------------------------------------------------------------------
; sub_F9915C -- the job the scheduler's phase-3 bit posts.  NOT NAMED: what it
;             decides is not established, only how it decides it.
;
; Called from: 0xF98C9E (`calr 0xF9915C`), reached only when bit 3 of the work
;              byte 0x007ED1 is set -- and INTT1_HANDLER sets bit 3 on phase 3,
;              once every six ticks.  So this is a scheduled poll, not a
;              one-shot.
; Inputs:  the tick counter 0x00F2F3; a countdown byte at 0x00E2E4; bit 0 of the
;          byte at 0x0000FFF8 (work DRAM).
; Outputs: 0x00F35F = 1 if that bit is set, 2 if it is clear; bit 7 of 0x007ECC
;          set either way; 0x00E2E4 decremented.
; Evidence: two guards, both early-outs: `cp XBC,0x000000FA` on the tick counter
;          means nothing happens until 250 INTT1 ticks have elapsed since reset,
;          and `cp (0x00E2E4),0x00` means it only runs while that counter is
;          non-zero.  0x00E2E4's boot value is 1 (see
;          notes/FINDINGS-prom_c-ram-image.md), so ★ THIS BODY RUNS EXACTLY ONCE
;          PER POWER-UP, on the first phase-3 tick after tick 250.  That is a
;          power-on sample of one input, latched into a two-valued result.
;          Bit 7 of 0x007ECC is what the main loop tests at 0xF98C52 before
;          calling 0xF98510 -- so the latch is consumed.
; Unknown:  ⚠ what the byte at 0x0000FFF8 is, and hence what is being sampled.
;          It is work DRAM, so something else must write it; that writer has not
;          been found.  Naming this routine before that is known would be a
;          guess, so it keeps its address.
; --------------------------------------------------------------------------
sub_F9915C:
	ldl_da	xbc, 0x00F2F3
	cp	xbc, 0x000000FA
	jr	nc, sub_F9915C__armed
	jr	sub_F9915C__exit
sub_F9915C__armed:
	cpib_da	0x00E2E4, 0x00
	jr	nz, sub_F9915C__counting
	jr	sub_F9915C__exit
sub_F9915C__counting:
	decdi8_24 1, 0x00E2E4
	ldw	bc, 0xFFF8
	extz	xbc
	ld	a, (xbc)
	and	a, 1
	jr	z, sub_F9915C__bit0_clear
	stib_da	0x00F35F, 1
	setda_24 7, 0x007ECC
	jr	sub_F9915C__exit
sub_F9915C__bit0_clear:
	stib_da	0x00F35F, 2
	setda_24 7, 0x007ECC
sub_F9915C__exit:
	ret


; --------------------------------------------------------------------------
; Serial0_Init -- configure serial channel 0 (the MIDI port) and its interrupts.
;
; Called from: 0xF98B91 (`call 0xF9919F`), in the power-on init chain.
; Inputs:  the fc byte at 0xFFFFEF; the INTES0 shadow byte at 0x00F2F7.
; Outputs: TRUN = 0x80, BR0CR = (fc >> 1) & 0x0F, SC0CR = 0, SC0MOD = 0x29,
;          0x00F2F9 = 2, and INTES0 = (old shadow & 0x88) | 0x55.
; Evidence: ★ THIS IS THE ROUTINE notes/FINDINGS-system-clock.md ARGUES FROM, now
;          in source.  `ld C,(0xFFFFEF) / srl 0x01,C / and C,0x0F / ld (BR0CR),C`
;          is exactly the rule that note states: BR0CR = (M >> 1) & 0x0F.  With
;          the baud generator's fc/4 tap and the UART's own divide-by-16 the bit
;          rate is fc / (32*M), which is 31250 -- the MIDI rate -- for any fc as
;          long as fc = 1,000,000 * M.  M = 0x1C, so fc = 28 MHz.
;          The INTES0 value is built in two steps on the shadow byte and only
;          then written to the register at 0x77: `and 0x8F / or 0x50` sets the
;          upper field to 5 and `and 0xF8 / or 0x05` sets the lower field to 5,
;          so both of channel 0's interrupts get the same setting.  That the two
;          fields are INTTX0 and INTRX0 follows from the register's name in
;          include/tmp95c061_sfr.inc; the numeric meaning of 5 is NOT decoded
;          here for the same reason as in Timer1_SetPeriodAndStart.
;          It runs with interrupts off around the register writes: `ei 6` before
;          and `di` (`ei 0x00`) at the end.
; Unknown:  what 0x00F2F9 = 2 means.  INTTX0_HANDLER writes the same value when
;          its queue runs dry, so "transmitter idle" is the reading offered in
;          notes/FINDINGS-prom_c-serial-midi.md; it is still not established.
;          Why SC0MOD is 0x29 here and 0x09 in the boot block is also open.
; --------------------------------------------------------------------------
Serial0_Init:
	ldio	TRUN, 0x80
	ldb_da	c, 0x00FFFFEF
	srl	c, 1
	and	c, 0x0F
	st_dd8b	c, BR0CR
	ldio	SC0CR, 0x00
	ldio	SC0MOD, 0x29
	ei	6
	stiw_da	0x00F2F9, 0x0002
	ldb_da	c, 0x00F2F7
	and	c, 0x8F
	or	c, 0x50
	stb_da	0x00F2F7, c
	and	c, 0xF8
	or	c, 0x05
	stb_da	0x00F2F7, c
	ldw	bc, INTES0
	exts	xbc
	ldb_da	a, 0x00F2F7
	ld	(xbc), a
	di
	ret


; --------------------------------------------------------------------------
; sub_F991E9 -- a queue operation on the MIDI RECEIVE descriptor.  Which one is
;             not established.
;
; Called from: not found -- no literal reference and no calr displacement in
;              prom_c reaches 0xF991E9.
; Inputs:  none; it supplies the descriptor address 0x00F2FB itself.
; Outputs: whatever 0xF994D7 returns.
; Evidence: byte for byte the same three-instruction wrapper as MIDI_Rx_Dequeue
;          below, on the SAME descriptor, differing only in the routine called
;          (0xF994D7 instead of 0xF993D4).  0x00F2FB is the descriptor
;          INTRX0_HANDLER pushes when it enqueues a received byte.
; Unknown:  what 0xF994D7 does.  A pair of wrappers over one descriptor is what
;          "peek" and "pop" look like, but neither callee has been converted, so
;          that is a shape and not a finding.
; --------------------------------------------------------------------------
sub_F991E9:
	lda_24	xbc, 0x00F2FB
	push	xbc
	calr	(0xF994D7 - 0xF991F2)
	pop	xiy
	ret


; --------------------------------------------------------------------------
; MIDI_Rx_Dequeue -- take the next byte from the MIDI receive queue.
;
; Called from: 0xF98BC6 and 0xF98D52, both `call 0xF991F4`.
; Inputs:  none; the descriptor address 0x00F2FB is supplied here.
; Outputs: WA = the byte, or 0xFFFF when the queue is empty.
; Evidence: the caller at 0xF98BC6 is the main loop's MIDI drain: it calls this,
;          copies WA to HL, and `cp HL,0xFFFF / jr Z` leaves the loop -- so
;          0xFFFF is the empty sentinel, and every other value is a byte it
;          stores into a 32-entry buffer before going round again (it also stops
;          at 0x20 entries).  The descriptor is the same 0x00F2FB the receive ISR
;          enqueues into, which is what makes this the RECEIVE side.
; Unknown:  the layout of the descriptor at 0x00F2FB and the body of 0xF993D4.
; --------------------------------------------------------------------------
MIDI_Rx_Dequeue:
	lda_24	xbc, 0x00F2FB
	push	xbc
	calr	(0xF993D4 - 0xF991FD)
	pop	xiy
	ret

; ==============================================================================
; 0xF991FF-0xF992A6 -- the serial-channel-0 interrupt handlers (MIDI)
; ==============================================================================
;
; Both handlers are converted from unidasm's decode; the llvm-mc spelling for each
; instruction was recovered with notes/prom_c_enc_oracle.py, which inverts the
; 40,101 already-byte-verified instructions of the KN5000 sub-CPU source.  The
; byte gate is what certifies them.
;
; --------------------------------------------------------------------------
; INTRX0_HANDLER -- serial channel 0 receive ISR.  This is the MIDI IN port.
;
; Called from: vector table offset 0x60 (INTRX0), which holds 0x00F991FF -- see
;              VECTORS at the bottom of this file.
; Inputs:  SC0CR (0x51) receive status, SC0BUF (0x50) received byte.
; Outputs: on a receive error, the status byte is stored at 0x00F327 and the byte
;          is dropped.  Otherwise the 32-bit value at 0x00F2F3 is copied to
;          0x007ED6, a byte of 0xFE additionally sets 0x00F2F8 = 1, and the byte
;          is pushed to the routine at 0xF9932E together with the descriptor
;          address 0x00F2FB.
; Notes:   ★ THE MIDI IDENTIFICATION RESTS ON THREE THINGS, ALL VISIBLE HERE.
;          1. `and c,0x1c` on SC0CR tests exactly bits 4..2 -- the three receive
;             error flags of a TLCS-900 serial channel.
;          2. The range filter is MIDI's, exactly.  The two SIGNED compares
;                cp (xiz-1),0x00 / jr ge   -> 0x00..0x7F enqueued
;                cp (xiz-1),0xf8 / jr lt   -> 0x80..0xF7 enqueued
;                                             0xF8..0xFF DROPPED
;             0xF8-0xFF is the MIDI System Real-Time range, which by the standard
;             may appear between the bytes of another message and must not be
;             queued with it.
;          3. The one byte singled out for a flag, 0xFE, is MIDI Active Sensing.
;          Corroborated independently by notes/FINDINGS-system-clock.md, where the
;          firmware's own baud rule makes SC0 run at 31250 bit/s for any fc.
;          ⚠ NOT ESTABLISHED: which physical connector SC0 reaches.  The MIDI
;          reading is from the protocol this code implements, not from a trace.
;          0x00F2FB is presumably a ring-buffer descriptor (the transmit handler
;          below uses 0x00F311 the same way) but that is NOT traced.
; --------------------------------------------------------------------------
INTRX0_HANDLER:
	push xbc
	pushw wa
	link32 0xEE, 0x0C, 0xFE, 0xFF
	push xwa
	push xiy
	ldmi16 (xiz-2), SC0CR
	ldw bc, SC0BUF
	exts xbc
	ld a, (xbc)
	ld (xiz-1), a
	ld c, (xiz-2)
	and c, 0x1c
	cps c, 0
	jr z, INTRX0_HANDLER__no_error
	ld c, (xiz-2)
	stb_da 0x00F327, c
	jr INTRX0_HANDLER__exit
INTRX0_HANDLER__no_error:
	ldl_da xbc, 0x00F2F3
	stl_da 0x007ED6, xbc
	cp (xiz-1), 0xfe
	jr nz, INTRX0_HANDLER__range_check
	stib_da 0x00F2F8, 0x01
INTRX0_HANDLER__range_check:
	cp (xiz-1), 0x00
	jr ge, INTRX0_HANDLER__enqueue
	cp (xiz-1), 0xf8
	jr lt, INTRX0_HANDLER__enqueue
	jr INTRX0_HANDLER__exit
INTRX0_HANDLER__enqueue:
	push 0x00
	extpfx3 0x8e, 0xff, 0x04
	lda_24 xbc, 0x00F2FB
	push xbc
	calr (0xF9932E - 0xF9925C)
	inc 6, xsp
INTRX0_HANDLER__exit:
	pop xiy
	pop xwa
	unlk32 xiz
	popw wa
	pop xbc
	reti

; --------------------------------------------------------------------------
; INTTX0_HANDLER -- serial channel 0 transmit-done ISR.  The MIDI OUT drain.
;
; Called from: vector table offset 0x64 (INTTX0), which holds 0x00F99265.
; Inputs:  none from hardware; it calls 0xF9942F with the descriptor address
;          0x00F311 to fetch the next byte to send.
; Outputs: if 0xF9942F returns 0xFFFF the queue is empty and 0x00F2F9 is set to
;          2 (transmitter idle, presumably).  Otherwise the byte is written to
;          SC0BUF (0x50) and the 32-bit value at 0x00F2F3 is copied to 0x007ED2.
; Notes:   The mirror of INTRX0_HANDLER: same 0x00F2F3 source copied to an adjacent
;          destination (0x007ED2 here, 0x007ED6 there), same descriptor-pointer
;          calling convention.  What 0x00F2F3 counts is NOT ESTABLISHED -- it is
;          read as a 32-bit value on every serial interrupt, which is what a
;          free-running timestamp would look like.
; --------------------------------------------------------------------------
INTTX0_HANDLER:

	push xbc
	pushw wa
	push xiy
	link32 0xEE, 0x0C, 0xFE, 0xFF
	pushw hl
	push xwa
	lda_24 xbc, 0x00F311
	push xbc
	calr (0xF9942F - 0xF99277)
	ld hl, wa
	ld (xiz-2), wa
	pop xiy
	cp hl, 0xffff
	jr z, INTTX0_HANDLER__empty
	ld h, a
	ldw bc, SC0BUF
	exts xbc
	ld (xbc), a
	ldl_da xbc, 0x00F2F3
	stl_da 0x007ED2, xbc
	jr INTTX0_HANDLER__exit
INTTX0_HANDLER__empty:
	stiw_da 0x00F2F9, 0x0002
INTTX0_HANDLER__exit:
	pop xwa
	popw hl
	unlk32 xiz
	pop xiy
	popw wa
	pop xbc
	reti

	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x0192A7, 0x0002F1

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
	stb_da	0x00F32A, c
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
	stb_da	0x00F32B, c
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
	cps	hl, 0
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
	ldb	a, 3
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
	subda16_24 de, 0x00FCC5C5
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
	ldb	c, 3
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
	ldw_da	bc, 0x00F32B
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
	lda_24	xbc, 0x00FCC71A
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

; ==============================================================================
; 0xF9973D-0xF99BBD -- not yet converted
; ==============================================================================
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x01973D, 0x000481

; ==============================================================================
; 0xF99BBE-0xF99C11 -- INT0, the inter-processor command dispatcher
; ==============================================================================
; --------------------------------------------------------------------------
; INT0_HANDLER -- INT0 handler: read a command byte from the CPU-1 link port and
;             dispatch it.
;
; Called from: vector table offset 0x28 (INT0) -> 0x00FFF0B4 (INT0_HANDLER trampoline)
;              -> `jp 0xF99BBE`.
; Inputs:  the byte at 0x00100000, the CS0 inter-processor link port (see
;          notes/FINDINGS-memory-map.md); PA bit 2.
; Outputs: saves the command byte at 0x008518, then jumps through the table
;          below.  If PA bit 2 is set it leaves at once via
;          INT0_HANDLER__return (0xF99CF8).
; Notes:   ★ THE COMMAND RANGE IS READ OFF THE CODE, not assumed:
;              sub bc,0x00E1 / cps bc,6 / jrl ugt -> out of range
;          so the seven dispatched commands are 0xE1..0xE7 and anything else
;          goes to INT0_HANDLER__cmd_E6_or_other (0xF99CCF) -- which is also
;          table entry 5, i.e. command 0xE6's own arm.  0x00100000 is the address
;          RESET programmes CS0 to select, and prom_a's side of the same link is
;          at 0x7C0000.  ★ Round 2 converted all seven arms; their header, just
;          below the table, carries the command -> {state, count, buffer} map and
;          the script that derives it.
;          ⚠ The KN5000 sub-CPU's INT0 handler (../kn5000-roms-disasm/v142/subcpu/
;          kn5000_subprogram_v142.s:2429) reads its link port the same way and
;          also special-cases 0xE1/0xE2/0xE3 -- but it is NOT byte-identical to
;          this one and its dispatch is a chain of compares, not a table.  The
;          command NUMBERS agreeing across the two machines is suggestive; it is
;          not proof that they mean the same thing.
; --------------------------------------------------------------------------
INT0_HANDLER:
	push xbc
	pushw wa
	push xiy
	pushw hl
	push xix
	lda_24 xix, 0x00F9A01F
	bit_dd8 2, PA
	jrl nz, (0x00F99CF8 - 0x00F99BCE)
	ld xbc, 0x00100000
	ld h, (xbc)
	stb_da 0x008518, h
	ld c, h
	extz bc
	extz xbc
	sub bc, 0x00e1
	cps bc, 6
	jrl ugt, (0x00F99CCF - 0x00F99BE9)
	sll bc, 2
	add xbc, 0x00F99BF6
	ld xbc, (xbc)
	jp (xbc)
INT0_HANDLER__jumptable:
	; 7 x u32, indexed by (command - 0xE1).  Every target is inside prom_c, and
	; every one of them is a label defined immediately below.  Note entry 5:
	; command 0xE6 shares INT0_HANDLER__cmd_E6_or_other with the out-of-range path.
	;         0xE1         0xE2         0xE3         0xE4
	.long 0x00F99C12, 0x00F99C32, 0x00F99C52, 0x00F99C72
	;         0xE5         0xE6         0xE7
	.long 0x00F99C91, 0x00F99CCF, 0x00F99CB0


; ==============================================================================
; 0xF99C12-0xF99CFD -- INT0's seven command arms and their shared epilogue
; ==============================================================================
; --------------------------------------------------------------------------
; INT0_HANDLER__cmd_E1 ... __cmd_E7 / __cmd_E6_or_other -- arm micro-DMA channel
;             3 to receive this command's payload, then hand INT0 to the DMA
;             engine so the payload bytes never reach the CPU.
;
; Called from: nothing calls these; they are jumped to.  All seven entries of
;          INT0_HANDLER__jumptable (0xF99BF6, converted above) land here, the
;          table being indexed by (command - 0xE1).  Six entries point at an arm
;          of their own; entry index 5 -- command 0xE6 -- points at
;          INT0_HANDLER__cmd_E6_or_other (0xF99CCF), which is ALSO the target of
;          the out-of-range `jrl ugt` at 0xF99BE9, so that one arm takes 0xE6 and
;          every byte outside 0xE1..0xE7.  (BC is zero-extended from the byte
;          before `sub bc,0x00E1`, so bytes below 0xE1 wrap to a large unsigned
;          value and take the same unsigned-greater-than exit as bytes above
;          0xE7.)
; Inputs:  XIX = 0xF9A01F, loaded by INT0_HANDLER at 0xF99BC3 -- that address is
;          uDMA3_SetDest, converted in this file at 0xF9A01F.  The command byte
;          INT0_HANDLER saved at 0x008518.
; Outputs: DMAD3 = this arm's buffer, DMAC3 = its transfer count, DMA3V = 0x0A,
;          (0x00F32D) = a transfer state, PA bit 1 cleared.  Every arm leaves
;          through INT0_HANDLER__drop_args, which drops the 6 argument bytes and
;          pops the five registers INT0_HANDLER pushed.
; Evidence: each arm is a FIXED seven-instruction shape, so the table below is
;          decoded from the bytes rather than read off:
;              python3 notes/prom_c_link_state_machine.py --selftest
;          prints it and re-proves every field, including the LAST row (0xE7 ->
;          0xF99CB0, state 8) and that the word after the 7-entry jump table
;          (0x00F32DF2) is not a pointer.  It reports "arms matching the fixed
;          shape: 6 of 7" -- the seventh is different BY DESIGN, see below.
;
;          command   arm       state   count   buffer     resume
;            0xE1   0xF99C12     2       6     0x008568   0xF99C29
;            0xE2   0xF99C32     3      10     0x008520   0xF99C49
;            0xE3   0xF99C52     5       4     0x00852D   0xF99C69
;            0xE4   0xF99C72     6       6     0x008568   0xF99C89
;            0xE5   0xF99C91     7       4     0x008531   0xF99CA8
;            0xE7   0xF99CB0     8       6     0x008568   0xF99CC7
;            0xE6 / any other byte:
;                   0xF99CCF     1   (cmd & 0x1F) + 1   0x008548   0xF99CF0
;
;          ★ THE SEVENTH ARM IS THE INTERESTING ONE.  Its transfer count is not a
;          constant: it is the low five bits of the command byte plus one.  So the
;          link protocol is not "seven commands" -- it is six special commands
;          plus a general length-prefixed message whose header byte carries the
;          length in its low 5 bits.  The top 3 bits are then used as a class
;          index by INTTC3_HANDLER__state1_generic (0xF99D6F, below).  That is
;          exactly the header byte notes/FINDINGS-memory-map.md section 3 reports
;          from CPU 1's side, `(channel << 5) | (len - 1)`.
;
;          `ldio DMA3V, 0x0A`: DMA3V is SFR 0x7F (include/tmp95c061_sfr.inc) and
;          the TMP95C061 triggers micro-DMA on `(DMAnV & 0x1f) << 2`
;          (mame/src/devices/cpu/tlcs900/tmp95c061.cpp:353); 0x0A << 2 = 0x28,
;          which the same file's vector map (:322-347) gives as INT0.  So after
;          this write the SAME interrupt that ran this handler is consumed by the
;          DMA engine, one byte per interrupt, and does not reach the CPU again
;          until INTTC3 (the transfer-complete interrupt) re-points it.
;          The other half of that channel is programmed ONCE, at 0xF99966-0xF99977:
;          DMAS3 := 0x00100000 (the inter-processor link port,
;          notes/FINDINGS-memory-map.md) and DMAM3 := 0x00, and mode 0x00 is
;          "byte transfer, DESTINATION incremented" (tmp95c061.cpp:366-371) --
;          i.e. read the fixed port, write successive buffer bytes.  "Once" is
;          measured, not assumed:
;              python3 notes/prom_c_link_state_machine.py --dma
;          censuses every `ldc CRn,r` / `ldc r,CRn` in prom_c naming a micro-DMA
;          control register and finds DMAS3 written at exactly one instruction
;          (0xF9A015) and DMAM3 at exactly one (0xF9A01B), both inside
;          uDMA3_SetSource -- which itself has exactly one call site, 0xF99974.
;          The same census shows EVERY non-spurious micro-DMA register access in
;          the image is inside the helper block 0xF99FF8-0xF9A037.  (⚠ its
;          CR-0x00 rows are byte-pattern noise and are printed as such.)
;          PA is SFR 0x1E.  prom_a's side of the same link does all of this with
;          P7 instead of PA: the notes block above INT0_LinkByte (0xF8E47F) in
;          prom_a/wsa1_prom_a.s records bit 2 tested on entry and bit 1 cleared
;          once the DMA is armed, which is exactly the
;          `bit_dd8 2, PA` at 0xF99BC8 and the `res_dd8 1, PA` in every arm here.
; Unknown:  ⚠ what the commands MEAN.  Only their payload sizes, their landing
;          buffers and their follow-up states are established.  prom_a's header
;          for the same protocol says the same thing and adds "do not name them";
;          that discipline is kept here.
;          ⚠ why 0xE6 shares the generic arm.  It is a table entry like the rest,
;          and it points at the general path; nothing here says whether that is
;          deliberate or the compiler folding an identical body.
; --------------------------------------------------------------------------
; ------------------------- command 0xE1 -------------------------------
INT0_HANDLER__cmd_E1:
	stib_da 0x00F32D, 0x02                     ; F99C12  f2 2d f3 00 00 02   transfer state := 2
	pushw 0x0006                               ; F99C18  0b 06 00   arg2: DMAC3 := 6 transfers
	lda_24 xbc, 0x008568                       ; F99C1B  f2 68 85 00 31
	push xbc                                   ; F99C20  39   arg1: DMAD3 := 0x008568
	lda_24 xiy, 0x00F99C29                     ; F99C21  f2 29 9c f9 35
	push xiy                                   ; F99C26  3d   return address for the tail-jump call
	jp (xix)                                   ; F99C27  b4 d8   XIX = uDMA3_SetDest (0xF9A01F)
INT0_HANDLER__cmd_E1_armed:
	ldio DMA3V, 0x0A                           ; F99C29  08 7f 0a   0x0A << 2 = 0x28 = INT0: the DMA now takes it
	res_dd8 1, PA                              ; F99C2C  f0 1e b1   drop the handshake line
	jrl t, (0x00F99CF6 - 0x00F99C32)           ; F99C2F  78 c4 00   -> INT0_HANDLER__drop_args
; ------------------------- command 0xE2 -------------------------------
INT0_HANDLER__cmd_E2:
	stib_da 0x00F32D, 0x03                     ; F99C32  f2 2d f3 00 00 03   transfer state := 3
	pushw 0x000A                               ; F99C38  0b 0a 00   arg2: DMAC3 := 10 transfers
	lda_24 xbc, 0x008520                       ; F99C3B  f2 20 85 00 31
	push xbc                                   ; F99C40  39   arg1: DMAD3 := 0x008520
	lda_24 xiy, 0x00F99C49                     ; F99C41  f2 49 9c f9 35
	push xiy                                   ; F99C46  3d   return address for the tail-jump call
	jp (xix)                                   ; F99C47  b4 d8   XIX = uDMA3_SetDest (0xF9A01F)
INT0_HANDLER__cmd_E2_armed:
	ldio DMA3V, 0x0A                           ; F99C49  08 7f 0a   0x0A << 2 = 0x28 = INT0: the DMA now takes it
	res_dd8 1, PA                              ; F99C4C  f0 1e b1   drop the handshake line
	jrl t, (0x00F99CF6 - 0x00F99C52)           ; F99C4F  78 a4 00   -> INT0_HANDLER__drop_args
; ------------------------- command 0xE3 -------------------------------
INT0_HANDLER__cmd_E3:
	stib_da 0x00F32D, 0x05                     ; F99C52  f2 2d f3 00 00 05   transfer state := 5
	pushw 0x0004                               ; F99C58  0b 04 00   arg2: DMAC3 := 4 transfers
	lda_24 xbc, 0x00852D                       ; F99C5B  f2 2d 85 00 31
	push xbc                                   ; F99C60  39   arg1: DMAD3 := 0x00852D
	lda_24 xiy, 0x00F99C69                     ; F99C61  f2 69 9c f9 35
	push xiy                                   ; F99C66  3d   return address for the tail-jump call
	jp (xix)                                   ; F99C67  b4 d8   XIX = uDMA3_SetDest (0xF9A01F)
INT0_HANDLER__cmd_E3_armed:
	ldio DMA3V, 0x0A                           ; F99C69  08 7f 0a   0x0A << 2 = 0x28 = INT0: the DMA now takes it
	res_dd8 1, PA                              ; F99C6C  f0 1e b1   drop the handshake line
	jrl t, (0x00F99CF6 - 0x00F99C72)           ; F99C6F  78 84 00   -> INT0_HANDLER__drop_args
; ------------------------- command 0xE4 -------------------------------
INT0_HANDLER__cmd_E4:
	stib_da 0x00F32D, 0x06                     ; F99C72  f2 2d f3 00 00 06   transfer state := 6
	pushw 0x0006                               ; F99C78  0b 06 00   arg2: DMAC3 := 6 transfers
	lda_24 xbc, 0x008568                       ; F99C7B  f2 68 85 00 31
	push xbc                                   ; F99C80  39   arg1: DMAD3 := 0x008568
	lda_24 xiy, 0x00F99C89                     ; F99C81  f2 89 9c f9 35
	push xiy                                   ; F99C86  3d   return address for the tail-jump call
	jp (xix)                                   ; F99C87  b4 d8   XIX = uDMA3_SetDest (0xF9A01F)
INT0_HANDLER__cmd_E4_armed:
	ldio DMA3V, 0x0A                           ; F99C89  08 7f 0a   0x0A << 2 = 0x28 = INT0: the DMA now takes it
	res_dd8 1, PA                              ; F99C8C  f0 1e b1   drop the handshake line
	jr INT0_HANDLER__drop_args                 ; F99C8F  68 65
; ------------------------- command 0xE5 -------------------------------
INT0_HANDLER__cmd_E5:
	stib_da 0x00F32D, 0x07                     ; F99C91  f2 2d f3 00 00 07   transfer state := 7
	pushw 0x0004                               ; F99C97  0b 04 00   arg2: DMAC3 := 4 transfers
	lda_24 xbc, 0x008531                       ; F99C9A  f2 31 85 00 31
	push xbc                                   ; F99C9F  39   arg1: DMAD3 := 0x008531
	lda_24 xiy, 0x00F99CA8                     ; F99CA0  f2 a8 9c f9 35
	push xiy                                   ; F99CA5  3d   return address for the tail-jump call
	jp (xix)                                   ; F99CA6  b4 d8   XIX = uDMA3_SetDest (0xF9A01F)
INT0_HANDLER__cmd_E5_armed:
	ldio DMA3V, 0x0A                           ; F99CA8  08 7f 0a   0x0A << 2 = 0x28 = INT0: the DMA now takes it
	res_dd8 1, PA                              ; F99CAB  f0 1e b1   drop the handshake line
	jr INT0_HANDLER__drop_args                 ; F99CAE  68 46
; ------------------------- command 0xE7 -------------------------------
INT0_HANDLER__cmd_E7:
	stib_da 0x00F32D, 0x08                     ; F99CB0  f2 2d f3 00 00 08   transfer state := 8
	pushw 0x0006                               ; F99CB6  0b 06 00   arg2: DMAC3 := 6 transfers
	lda_24 xbc, 0x008568                       ; F99CB9  f2 68 85 00 31
	push xbc                                   ; F99CBE  39   arg1: DMAD3 := 0x008568
	lda_24 xiy, 0x00F99CC7                     ; F99CBF  f2 c7 9c f9 35
	push xiy                                   ; F99CC4  3d   return address for the tail-jump call
	jp (xix)                                   ; F99CC5  b4 d8   XIX = uDMA3_SetDest (0xF9A01F)
INT0_HANDLER__cmd_E7_armed:
	ldio DMA3V, 0x0A                           ; F99CC7  08 7f 0a   0x0A << 2 = 0x28 = INT0: the DMA now takes it
	res_dd8 1, PA                              ; F99CCA  f0 1e b1   drop the handshake line
	jr INT0_HANDLER__drop_args                 ; F99CCD  68 27
; --------------- command 0xE6 AND every unlisted byte -----------------
INT0_HANDLER__cmd_E6_or_other:
	stib_da 0x00F32D, 0x01                     ; F99CCF  f2 2d f3 00 00 01   transfer state := 1
	ldb_da c, 0x008518                         ; F99CD5  c2 18 85 00 23   the command byte INT0_HANDLER saved
	and c, 0x1f                                ; F99CDA  cb cc 1f   low 5 bits ...
	extz bc                                    ; F99CDD  d9 12
	inc 1, bc                                  ; F99CDF  d9 61   ... + 1 = the payload length
	pushw bc                                   ; F99CE1  29   arg2: DMAC3 := that many transfers
	lda_24 xbc, 0x008548                       ; F99CE2  f2 48 85 00 31
	push xbc                                   ; F99CE7  39   arg1: DMAD3 := 0x008548
	lda_24 xiy, 0x00F99CF0                     ; F99CE8  f2 f0 9c f9 35
	push xiy                                   ; F99CED  3d
	jp (xix)                                   ; F99CEE  b4 d8   XIX = uDMA3_SetDest (0xF9A01F)
INT0_HANDLER__cmd_E6_armed:
	ldio DMA3V, 0x0A                           ; F99CF0  08 7f 0a
	res_dd8 1, PA                              ; F99CF3  f0 1e b1

INT0_HANDLER__drop_args:
	inc 6, xsp                                 ; F99CF6  ef 66   drop the 6 bytes of arguments -- caller-cleaned
INT0_HANDLER__return:
	pop xix                                    ; F99CF8  5c
	popw hl                                    ; F99CF9  4b
	pop xiy                                    ; F99CFA  5d
	popw wa                                    ; F99CFB  48
	pop xbc                                    ; F99CFC  59
	reti                                       ; F99CFD  07

; ==============================================================================
; 0xF99CFE-0xF99D6E -- the micro-DMA completion handlers
; ==============================================================================
; --------------------------------------------------------------------------
; INTTC2_HANDLER -- micro-DMA channel 2 completion.
;
; Called from: vector table offset 0x7C (INTTC2) -> 0x00FFF0C0 -> `jp 0xF99CFE`.
; Inputs:  the state byte at 0x00F32C.
; Outputs: stops the prescaler/timer bit (res 2,(TRUN)) and counts the state byte
;          down: 1 -> 0, 2 -> 1, anything else left alone.
; Notes:   A two-phase transfer state machine, the same shape as the KN5000
;          sub-CPU's MICRODMA_CH2_HANDLER (kn5000_subprogram_v142.s:2499), which
;          also clears a TRUN bit and steps a state byte 2 -> 1 -> 0.  Not
;          byte-identical (different state address, different register), so the
;          resemblance is structural only.
; --------------------------------------------------------------------------
INTTC2_HANDLER:
	res_dd8 2, TRUN
	cpib_da 0x00F32C, 0x01
	jr nz, INTTC2_HANDLER__try2
	stib_da 0x00F32C, 0x00
	jr INTTC2_HANDLER__done
INTTC2_HANDLER__try2:
	cpib_da 0x00F32C, 0x02
	jr nz, INTTC2_HANDLER__done
	stib_da 0x00F32C, 0x01
INTTC2_HANDLER__done:
	reti

; --------------------------------------------------------------------------
; INTTC3_HANDLER -- micro-DMA channel 3 completion; dispatches on a 9-state machine.
;
; Called from: vector table offset 0x80 (INTTC3) -> 0x00FFF0C4 -> `jp 0xF99D20`.
; Inputs:  the 16-bit state at 0x00F32D.
; Outputs: jumps through the table below; state 0 or > 9 falls out to
;          INTTC3_HANDLER__return (0xF99E56).  ★ Round 2 converted all nine
;          arms; their header, just below the table, says which link command
;          reaches which arm and what each one posts.
; Notes:   ★ The state range is read off the code: `dec 1,bc` then `cp bc,0x0008`
;          with an UNSIGNED greater-than exit, so the accepted states are 1..9 and
;          the table has exactly 9 entries -- which is also exactly the space
;          before the first target, 0xF99D6F.
;          `pushw_erp 0xE2` is unidasm's `push QWA`; the llvm-mc backend spells
;          extended-register operands as the raw operand byte.
; --------------------------------------------------------------------------
INTTC3_HANDLER:

	push xbc
	pushw wa
	push xiy
	push xix
	lda_24 xix, 0x008568
	pushw_erp 0xE2
	ldw_da bc, 0x00F32D
	extz bc
	extz xbc
	dec 1, bc
	cp bc, 0x0008
	jrl ugt, (0x00F99E56 - 0x00F99D3E)
	sll bc, 2
	add xbc, 0x00F99D4B
	ld xbc, (xbc)
	jp (xbc)
INTTC3_HANDLER__jumptable:
	; 9 x u32, indexed by (state - 1).  Every target is inside prom_c, is a label
	; defined immediately below, and the first of them, 0xF99D6F, is the byte
	; immediately after this table.
	.long 0x00F99D6F, 0x00F99DAC, 0x00F99DB5, 0x00F99DCC
	.long 0x00F99DDD, 0x00F99DED, 0x00F99E11, 0x00F99E21
	.long 0x00F99E43


; ==============================================================================
; 0xF99D6F-0xF99E5D -- INTTC3's nine state arms and their shared epilogue
; ==============================================================================
; --------------------------------------------------------------------------
; INTTC3_HANDLER__state1_generic ... __state9 -- one arm per transfer state:
;             finish the transfer that just completed, and either post a flag for
;             the service task or arm the NEXT transfer.
;
; Called from: nothing calls these; INTTC3_HANDLER (0xF99D20, converted above)
;          jumps through INTTC3_HANDLER__jumptable (0xF99D4B) indexed by
;          (state - 1), the state being the 16-bit variable at 0x00F32D that the
;          INT0 arms wrote.
; Inputs:  XIX = 0x008568, loaded by INTTC3_HANDLER at 0xF99D24 -- that is the
;          buffer commands 0xE1/0xE4/0xE7 transfer their six descriptor bytes
;          into, and states 2/6/8 read it back as {u32 destination, u16 count}.
;          The command byte at 0x008518 (state 1 only).
; Outputs: (0x00F32D) := 0 on every terminating arm; PA bit 1 raised again; and
;          one of: a flag bit in 0x00852A/0x00852B/0x00852C, a further micro-DMA
;          transfer armed, or the counter at 0x008535 incremented.
; Evidence: the 9-entry table and which command reaches which arm are decoded
;          from the ROM by
;              python3 notes/prom_c_link_state_machine.py --selftest
;          which prints the state -> handler mapping, checks the LAST entry
;          (state 9 -> 0xF99E43) as well as the first, and shows the word after
;          the table (0x008548F2) is not a pointer.  The same run censuses the
;          state variable completely: over all twelve direct-address spellings
;          0x00F32D has EIGHTEEN literal-addressed references in prom_c --
;          SEVENTEEN immediate byte writes, covering exactly the values 0..9 and
;          all inside 0xF99C12-0xF99FDC, and ONE read, the `ldw_da bc, 0x00F32D`
;          at 0xF99D2C in INTTC3_HANDLER itself.  That is what makes "states 4
;          and 9 are entered from INTTC3, not from an INT0 command" a measurement
;          rather than an impression: 0xF99E07 writes 4 and 0xF99E3B writes 9,
;          and no INT0 arm writes either.  (A write through a pointer register
;          would still be invisible -- see the INTT1_HANDLER header.)
;
;          ★ THIS CLOSES THE Handler_PtrTable_FCC53F QUESTION.  That table's
;          header (below, at 0xFCC53F) said "nothing in prom_c references
;          0xFCC53F as a literal ... what dispatches through it is not traced".
;          Both halves are now answered, and the reason the literal search failed
;          is that the dispatcher does not use the ROM address at all: RESET
;          copies ROM 0xFCB4EA.. to RAM 0x00E2DF (notes/prom_c_ram_image.py), and
;          0xFCC53F - 0xFCB4EA = 0x1055, so the table's RAM copy is at
;          0x00E2DF + 0x1055 = 0x00F334.  `add xbc, 0x0000F334` at 0xF99D91 is
;          that address.  The index is (command byte >> 5) * 4, i.e. the message
;          class in the top three bits, 0..7 -- which is exactly why the table has
;          eight entries.  Reproduce the RAM address and the boot contents with
;              python3 notes/prom_c_ram_image.py 0x00F334:32
;          which prints the eight pointers 0xF98D9A, 0xF98DE6, 0xF98FD6, 0xF9901B
;          and then 0xF9993D four times.
;
;          ★ AND IT CONFIRMS THE 0xE2 PACKET LAYOUT FROM THE RECEIVING SIDE.
;          notes/FINDINGS-memory-map.md section 3 derives, from prom_a alone, that
;          command 0xE2 carries a 10-byte packet laid out {+0 remote address u32,
;          +4 local destination u32, +8 length u16}.  Here the 0xE2 arm transfers
;          exactly 10 bytes to 0x008520, and the routine at 0xF99E5F that state 3
;          wakes reads 0x008524 (u32), 0x008528 (u16) and 0x008520 (u32) in that
;          order and passes them as three arguments.  Two independent images, one
;          layout.
;
;          The three flag bytes these arms post to are each fully censused by
;              python3 notes/prom_c_link_state_machine.py --flags
;          (all twelve direct spellings).  0x00852A/B/C have SEVENTEEN sites
;          between them, spanning 0xF99AAE-0xF99FE5 -- note that the top of that
;          span is inside Link_WaitBlockDone, NOT inside this block:
;            0x00852A -- 3 sites.  set 7 HERE (state 3, 0xF99DC4); bit 7 tested at
;                        0xF99E67 and cleared at 0xF99E6E, both in the routine at
;                        0xF99E5F.  A one-bit "0xE2 packet ready" handshake.
;            0x00852B -- 4 sites.  set 7 at 0xF99AAE, immediately after micro-DMA
;                        channel 2 is armed and TRUN bit 2 set (an OUTGOING
;                        transfer starting); cleared HERE by state 4 (0xF99DD2)
;                        and by Link_WaitBlockDone's timeout path (0xF99FE5),
;                        which is also its only reader (0xF99FC6).
;            0x00852C -- 10 sites.  bits 7/6/5 set HERE by states 5/7/9
;                        (0xF99DE3, 0xF99E17, 0xF99E49) and each tested and
;                        cleared by the routine at 0xF99E5F (0xF99E92/0xF99E99,
;                        0xF99ECD/0xF99ED4, 0xF99F06/0xF99F0D); bit 5 is also set
;                        at 0xF99F48.  A three-bit work-request byte.
;          0x008535, incremented by state 9 (0xF99E4E), has 5 sites: cleared at
;          0xF99951 and 0xF99EA6, compared against C at 0xF99F3F and 0xF99F65.
;          It IS read.  Adding it and 0x008519 to the census gives 23 sites over
;          0xF99951-0xF99FE5, which is the whole link subsystem.
; Unknown:  ⚠ WHAT the three flags MEAN -- which link exchange each one belongs to
;          is not established, only which code sets and clears it.
;          ⚠ why states 6 and 8 force the destination into 0x010000-0x01FFFF with
;          `and 0xFFFF` + `add 0x00010000` while state 2 uses the descriptor's
;          full 32-bit address.  Per notes/FINDINGS-memory-map.md that range is
;          CS3, the same chip select as the work DRAM, but its upper half is
;          listed there as NOT ESTABLISHED.
;          ⚠ 0x008519 := 0xFF (state 3) is the ONLY literal-addressed reference
;          to 0x008519 in the whole image -- written once, never read.  Either a
;          pointer-based reader exists (invisible to any literal census) or it is
;          dead.  Stated as measured; not called dead.
; --------------------------------------------------------------------------
; ---- state 1: a generic length-prefixed message; dispatch on the top 3 bits ----
INTTC3_HANDLER__state1_generic:
	lda_24 xbc, 0x008548                       ; F99D6F  f2 48 85 00 31
	push xbc                                   ; F99D74  39   arg2 (XSP+6): the buffer the payload landed in
	ldb_da a, 0x008518                         ; F99D75  c2 18 85 00 21   the command byte INT0_HANDLER saved
	and a, 0x1f                                ; F99D7A  c9 cc 1f
	extz wa                                    ; F99D7D  d8 12
	inc 1, wa                                  ; F99D7F  d8 61
	pushw wa                                   ; F99D81  28   arg1 (XSP+4): (cmd & 0x1F) + 1 = payload length
	ldb_da w, 0x008518                         ; F99D82  c2 18 85 00 20
	srl w, 5                                   ; F99D87  c8 ef 05   the top 3 bits = the message class, 0..7
	ld c, w                                    ; F99D8A  c8 8b
	mul c, 4                                   ; F99D8C  cb 08 04   x 4: these are 32-bit pointers
	extz xbc                                   ; F99D8F  e9 12
	add xbc, 0x0000F334                        ; F99D91  e9 c8 34 f3 00 00   the RAM copy of Handler_PtrTable_FCC53F
	ld xbc, (xbc)                              ; F99D97  a1 21
	lda_24 xiy, 0x00F99DA1                     ; F99D99  f2 a1 9d f9 35
	push xiy                                   ; F99D9E  3d   return address for the tail-jump call
	jp (xbc)                                   ; F99D9F  b1 d8   call the class handler
INTTC3_HANDLER__state1_done:
	stib_da 0x00F32D, 0x00                     ; F99DA1  f2 2d f3 00 00 00   transfer state := idle
	set_dd8 1, PA                              ; F99DA7  f0 1e b9   raise the handshake line again
	jr INTTC3_HANDLER__drop_args               ; F99DAA  68 61

; ---- state 2: the 0xE1 descriptor has landed -- arm the payload transfer ----
INTTC3_HANDLER__state2_block:
	ld bc, (xix+4)                             ; F99DAC  9c 04 21   descriptor +4: the 16-bit count
	pushw bc                                   ; F99DAF  29
	ld xbc, (xix)                              ; F99DB0  a4 21   descriptor +0: the 32-bit destination
	push xbc                                   ; F99DB2  39
	jr INTTC3_HANDLER__arm_payload             ; F99DB3  68 4b

; ---- state 3: the 0xE2 packet has landed -- hand it to the service task ----
INTTC3_HANDLER__state3_packet:
	stib_da 0x008519, 0xff                     ; F99DB5  f2 19 85 00 00 ff
	stib_da 0x00F32D, 0x00                     ; F99DBB  f2 2d f3 00 00 00   transfer state := idle
	set_dd8 1, PA                              ; F99DC1  f0 1e b9
	setda_24 7, 0x00852A                       ; F99DC4  f2 2a 85 00 bf   post 'packet ready' to the service task at 0xF99E5F
	jrl t, (0x00F99E56 - 0x00F99DCC)           ; F99DC9  78 8a 00   -> INTTC3_HANDLER__return

; ---- state 4: a payload transfer finished ----
INTTC3_HANDLER__state4_blockdone:
	stib_da 0x00F32D, 0x00                     ; F99DCC  f2 2d f3 00 00 00   transfer state := idle
	resda_24 7, 0x00852B                       ; F99DD2  f2 2b 85 00 b7   release Link_WaitBlockDone (0xF99FC1)
	set_dd8 1, PA                              ; F99DD7  f0 1e b9
	jrl t, (0x00F99E56 - 0x00F99DDD)           ; F99DDA  78 79 00   -> INTTC3_HANDLER__return

; ---- state 5: the 0xE3 payload has landed ----
INTTC3_HANDLER__state5:
	stib_da 0x00F32D, 0x00                     ; F99DDD  f2 2d f3 00 00 00
	setda_24 7, 0x00852C                       ; F99DE3  f2 2c 85 00 bf
	set_dd8 1, PA                              ; F99DE8  f0 1e b9
	jr INTTC3_HANDLER__return                  ; F99DEB  68 69

; ---- state 6: the 0xE4 descriptor has landed -- same, but banked ----
INTTC3_HANDLER__state6_block_banked:
	ld bc, (xix+4)                             ; F99DED  9c 04 21   descriptor +4: the 16-bit count
	pushw bc                                   ; F99DF0  29
	ld xbc, (xix)                              ; F99DF1  a4 21   descriptor +0: the destination
	and xbc, 0x0000FFFF                        ; F99DF3  e9 cc ff ff 00 00
	add xbc, 0x00010000                        ; F99DF9  e9 c8 00 00 01 00   forced into 0x010000-0x01FFFF
	push xbc                                   ; F99DFF  39
INTTC3_HANDLER__arm_payload:
	call 0x00F9A01F                            ; F99E00  1d 1f a0 f9   uDMA3_SetDest: DMAD3 := dest, DMAC3 := count
	ldio DMA3V, 0x0A                           ; F99E04  08 7f 0a   re-point INT0 at the DMA engine
	stib_da 0x00F32D, 0x04                     ; F99E07  f2 2d f3 00 00 04   transfer state := 4 (payload in flight)
INTTC3_HANDLER__drop_args:
	inc 6, xsp                                 ; F99E0D  ef 66   drop the 6 bytes of arguments -- caller-cleaned
	jr INTTC3_HANDLER__return                  ; F99E0F  68 45

; ---- state 7: the 0xE5 payload has landed ----
INTTC3_HANDLER__state7:
	stib_da 0x00F32D, 0x00                     ; F99E11  f2 2d f3 00 00 00
	setda_24 6, 0x00852C                       ; F99E17  f2 2c 85 00 be
	set_dd8 1, PA                              ; F99E1C  f0 1e b9
	jr INTTC3_HANDLER__return                  ; F99E1F  68 35

; ---- state 8: the 0xE7 descriptor has landed -- banked, then state 9 ----
INTTC3_HANDLER__state8_block_banked:
	ld bc, (xix+4)                             ; F99E21  9c 04 21
	pushw bc                                   ; F99E24  29
	ld xbc, (xix)                              ; F99E25  a4 21
	and xbc, 0x0000FFFF                        ; F99E27  e9 cc ff ff 00 00
	add xbc, 0x00010000                        ; F99E2D  e9 c8 00 00 01 00
	push xbc                                   ; F99E33  39
	call 0x00F9A01F                            ; F99E34  1d 1f a0 f9   uDMA3_SetDest
	ldio DMA3V, 0x0A                           ; F99E38  08 7f 0a
	stib_da 0x00F32D, 0x09                     ; F99E3B  f2 2d f3 00 00 09   transfer state := 9, NOT 4
	jr INTTC3_HANDLER__drop_args               ; F99E41  68 ca

; ---- state 9: the 0xE7 payload has landed ----
INTTC3_HANDLER__state9:
	stib_da 0x00F32D, 0x00                     ; F99E43  f2 2d f3 00 00 00
	setda_24 5, 0x00852C                       ; F99E49  f2 2c 85 00 bd
	incdi8_24 1, 0x008535                      ; F99E4E  c2 35 85 00 61   a counter, incremented only here
	set_dd8 1, PA                              ; F99E53  f0 1e b9
INTTC3_HANDLER__return:
	popw_erp 0xE2                              ; F99E56  d7 e2 05   pop QWA -- matches the pushw_erp in the prologue
	pop xix                                    ; F99E59  5c
	pop xiy                                    ; F99E5A  5d
	popw wa                                    ; F99E5B  48
	pop xbc                                    ; F99E5C  59
	reti                                       ; F99E5D  07

; --------------------------------------------------------------------------
; INTT2_HANDLER -- timer 2 interrupt: acknowledge and return, nothing else.
;
; Called from: vector table offset 0x48 (INTT2) -> 0x00FFF0B8 -> `jp 0xF99E5E`.
; Inputs:  none.  Outputs: none.
; Notes:   A single 0x07 RETI byte.  It is not dead code: the vector table
;          comment at 0x48 records that this is the interrupt CPU 2's micro-DMA
;          channel 2 is armed on (DMA2V = 0x12 at 0xF99A2A), and a micro-DMA
;          channel needs its interrupt to fire and be dismissed for the transfer
;          to be paced.  The byte before it, 0xF99E5D, is the RETI of a different
;          routine, so this really is a one-instruction handler and not a tail.
; --------------------------------------------------------------------------
INTT2_HANDLER:
	reti

	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x019E5F, 0x000162

; ==============================================================================
; 0xF99FC1-0xF9A04F -- the link wait, and the micro-DMA / block-move runtime
; ==============================================================================
; --------------------------------------------------------------------------
; Link_WaitBlockDone -- block until the outstanding link transfer finishes, or
;             500 ticks pass; abort it if they do.
;
; Called from: not yet traced.  notes/prom_c_xrefs.py 0xF99FC1 finds no absolute
;          literal and no calr displacement, and short PC-relative forms are not
;          searched, so this is "not found", not "nothing calls it".
; Inputs:  bit 7 of (0x00852B); the INTT1 tick counter at 0x00F2F3, read as 16
;          bits.
; Outputs: WA = 0 if the flag cleared in time, 0xFFFF if it did not.  On timeout
;          it also aborts: DMA3V := 0, (0x00F32D) := 0, PA bit 1 raised, bit 7 of
;          (0x00852B) cleared, and the counter at 0x00F333 incremented.  HL saved.
; Evidence: this is prom_a's Link_WaitBlockDone (0xF8E66D in
;          prom_a/wsa1_prom_a.s) rewritten for CPU 2's addresses.  The two
;          routines are the SAME FIFTEEN INSTRUCTIONS in the same order with the
;          same opcodes -- push HL / load tick / poll flag / re-load tick /
;          subtract / cp 0x01F4 / loop / DMAnV:=0 / state:=0 / set port bit 1 /
;          clear flag / bump a counter / WA:=0xFFFF / else WA:=0 / pop HL / ret --
;          and only the operand addresses differ:
;
;              role                     prom_a          prom_c
;              tick counter             (0x0080)        (0x00F2F3)
;              outstanding flag         (0x00008A) b7   (0x00852B) b7
;              transfer state           (0x6007DA)      (0x00F32D)
;              handshake port           P7 (0x13) b1    PA (0x1E) b1
;              timeout counter          (0x6007E1)      (0x00F333)
;              timeout                  0x01F4 = 500    0x01F4 = 500
;
;          They are NOT byte-identical -- the embedded addresses see to that.
;          The maximal identical run through this neighbourhood starts only at the
;          `ldw wa, 0xffff` and runs 98 bytes into the helper block below:
;              python3 notes/prom_c_prom_a_shared_runs.py --at 0xF9A01F 0xF8E6C9
;          The clearing side is pinned independently: INTTC3_HANDLER__state4_blockdone
;          (0xF99DCC, converted above) is the only `res 7,(0x00852B)` besides the
;          timeout path here, and it runs when a payload transfer completes.
;
;          ★ The two reads of the tick counter here are the two sites that the
;          round-1 census of 0x00F2F3 MISSED, because they use the 16-bit-direct
;          spelling (prefix 0xD1) instead of the 24-bit one (0xD2).  prom_a's
;          counterpart makes the point twice over: its tick counter lives at
;          0x0080, so the SAME instruction is spelled with the 8-bit-direct prefix
;          0xD0 there.  See the correction in the INTT1_HANDLER header above.
; Unknown:  ⚠ which of the flag's setters a given caller is waiting on, and what
;          reads the timeout counter at 0x00F333 -- prom_a's header records the
;          same two gaps for its own copy.
; --------------------------------------------------------------------------
; uDMA2_SetDest / uDMA2_SetSource / uDMA3_SetSource / uDMA3_SetDest /
; uDMA2_GetCount / uDMA3_GetCount / uDMA3_GetDest -- one micro-DMA control
;             register each, from the stack.
;
; Called from: uDMA2_SetDest 0xF9996C; uDMA2_SetSource 0xF99A26, 0xF99AA4,
;          0xF99B81, 0xF99BA4; uDMA3_SetSource 0xF99974; uDMA3_SetDest 0xF99E00
;          and 0xF99E34, plus the tail-jump from all seven INT0 arms (XIX is
;          loaded with 0xF9A01F at 0xF99BC3); uDMA3_GetCount 0xF99F73, 0xF99F8C.
;          uDMA2_GetCount and uDMA3_GetDest: no literal reference found.
;          (Byte census of the 24-bit literal with the `1D` call opcode in front.)
; Inputs:  (XSP+4) = a 32-bit address; (XSP+8) = the second argument, which is
;          NOT the same thing in all four setters -- read straight off the bodies:
;              uDMA2_SetDest     DMAD2 0x18      DMAM2 0x2A   mode byte
;              uDMA2_SetSource   DMAS2 0x08      DMAC2 0x28   transfer count
;              uDMA3_SetSource   DMAS3 0x0C      DMAM3 0x2E   mode byte
;              uDMA3_SetDest     DMAD3 0x1C      DMAC3 0x2C   transfer count
;          ⚠ the mode byte rides with the SOURCE setter on channel 3 and with the
;          DEST setter on channel 2.  prom_a's block header at 0xF8E6A2 records
;          the same crossing and the round-1 audit finding (F8) that an earlier
;          version of it got backwards.
; Outputs: the named control register.  BC/XBC clobbered.  Callers drop the
;          arguments themselves.
; Evidence: ★ NAMES CARRIED FROM prom_a BY BYTE IDENTITY, not by resemblance.
;          All eight routines here, 0xF99FF8-0xF9A04F, are byte-for-byte
;          prom_a 0xF8E6A2-0xF8E6F9 -- the same C runtime compiled into both
;          EPROMs -- and prom_a names all eight in its own 0xF8E6A2-0xF8E6F9
;          block header.  Measured, not assumed:
;              python3 notes/prom_c_prom_a_shared_runs.py --selftest
;          reports the maximal identical run through this block as 98 bytes,
;          prom_c 0xF99FEE <-> prom_a 0xF8E698, differing one byte before and one
;          byte after -- so the run COVERS all eight routines and stops outside
;          them.  The control-register numbers are MAME's table for this exact
;          part, mame/src/devices/cpu/tlcs900/tmp95c061.cpp:1394-1398:
;          DMAS2 0x08, DMAC2 0x28, DMAD2 0x18, DMAM2 0x2A, DMAS3 0x0C,
;          DMAC3 0x2C, DMAD3 0x1C, DMAM3 0x2E -- which is why the `.equ`s below
;          are equates and not guesses.
; Unknown:  nothing about these seven; each writes or reads one register and rets.
; --------------------------------------------------------------------------
; MemCopyWords -- copy (XSP+0x10) BYTES from (XSP+0x08) to (XSP+0x0C)
;
; Called from: 66 call sites in prom_c -- a byte census of `1D 38 A0 F9`
;          (call + the 24-bit literal), first 0xFB1DE7, last 0xFC575B.  Both ends
;          checked, not just the first.  This is the compiler's block move.
; Inputs:  (XSP+0x08) source, (XSP+0x0C) destination, (XSP+0x10) byte count.
; Outputs: the copy; BC, XIY, XIX clobbered (XIX saved and restored).
; Evidence: byte-identical to prom_a's MemCopyWords (0xF8E6E2 in
;          prom_a/wsa1_prom_a.s), inside the same 98-byte run measured above.
;          The odd-length handling is visible: `bit 0,bc` then one `LDI` before
;          `srl bc,1` + `LDIRW`, so an odd count moves one byte and then
;          (count-1)/2 words.
; Unknown:  nothing.
; --------------------------------------------------------------------------
	.equ CR_DMAS2, 0x08	; mame/src/devices/cpu/tlcs900/tmp95c061.cpp:1394-1398
	.equ CR_DMAC2, 0x28
	.equ CR_DMAD2, 0x18
	.equ CR_DMAM2, 0x2A
	.equ CR_DMAS3, 0x0C
	.equ CR_DMAC3, 0x2C
	.equ CR_DMAD3, 0x1C
	.equ CR_DMAM3, 0x2E
Link_WaitBlockDone:
	pushw hl                                   ; F99FC1  2b
	ldw_d16 hl, 0xF2F3                         ; F99FC2  d1 f3 f2 23   HL := the INTT1 tick count at entry (low 16 bits)
Link_WaitBlockDone__poll:
	bitda_24 7, 0x00852B                       ; F99FC6  f2 2b 85 00 cf   still outstanding?
	jr z, Link_WaitBlockDone__ok               ; F99FCB  66 27
	ldw_d16 bc, 0xF2F3                         ; F99FCD  d1 f3 f2 21
	sub bc, hl                                 ; F99FD1  db a1
	cp bc, 0x01f4                              ; F99FD3  d9 cf f4 01   500 ticks
	jr le, Link_WaitBlockDone__poll            ; F99FD7  62 ed
	ldio DMA3V, 0x00                           ; F99FD9  08 7f 00   timed out: stop INT0 feeding the DMA engine
	stib_da 0x00F32D, 0x00                     ; F99FDC  f2 2d f3 00 00 00   transfer state := idle
	set_dd8 1, PA                              ; F99FE2  f0 1e b9   raise the handshake line
	resda_24 7, 0x00852B                       ; F99FE5  f2 2b 85 00 b7   clear the outstanding flag ourselves
	incdi8_24 1, 0x00F333                      ; F99FEA  c2 33 f3 00 61   the timeout counter
	ldw wa, 0xffff                             ; F99FEF  30 ff ff   return -1
	jr Link_WaitBlockDone__ret                 ; F99FF2  68 02
Link_WaitBlockDone__ok:
	sub wa, wa                                 ; F99FF4  d8 a0   return 0
Link_WaitBlockDone__ret:
	popw hl                                    ; F99FF6  4b
	ret                                        ; F99FF7  0e

uDMA2_SetDest:
	ld xbc, (xsp+4)                            ; F99FF8  af 04 21
	ldc_cr32 xbc, CR_DMAD2                     ; F99FFB  e9 2e 18
	ld c, (xsp+8)                              ; F99FFE  8f 08 23
	ldc_cr8 c, CR_DMAM2                        ; F9A001  cb 2e 2a
	ret                                        ; F9A004  0e
uDMA2_SetSource:
	ld xbc, (xsp+4)                            ; F9A005  af 04 21
	ldc_cr32 xbc, CR_DMAS2                     ; F9A008  e9 2e 08
	ld bc, (xsp+8)                             ; F9A00B  9f 08 21
	ldc_cr16 bc, CR_DMAC2                      ; F9A00E  d9 2e 28
	ret                                        ; F9A011  0e
uDMA3_SetSource:
	ld xbc, (xsp+4)                            ; F9A012  af 04 21
	ldc_cr32 xbc, CR_DMAS3                     ; F9A015  e9 2e 0c
	ld c, (xsp+8)                              ; F9A018  8f 08 23
	ldc_cr8 c, CR_DMAM3                        ; F9A01B  cb 2e 2e
	ret                                        ; F9A01E  0e
uDMA3_SetDest:
	ld xbc, (xsp+4)                            ; F9A01F  af 04 21
	ldc_cr32 xbc, CR_DMAD3                     ; F9A022  e9 2e 1c
	ld bc, (xsp+8)                             ; F9A025  9f 08 21
	ldc_cr16 bc, CR_DMAC3                      ; F9A028  d9 2e 2c
	ret                                        ; F9A02B  0e
uDMA2_GetCount:
	ldc_16_cr wa, CR_DMAC2                     ; F9A02C  d8 2f 28
	ret                                        ; F9A02F  0e
uDMA3_GetCount:
	ldc_16_cr wa, CR_DMAC3                     ; F9A030  d8 2f 2c
	ret                                        ; F9A033  0e
uDMA3_GetDest:
	ldc_32_cr xiy, CR_DMAD3                    ; F9A034  ed 2f 1c
	ret                                        ; F9A037  0e
MemCopyWords:
	push xix                                   ; F9A038  3c
	ld bc, (xsp+16)                            ; F9A039  9f 10 21   arg3: byte count
	ld xiy, (xsp+8)                            ; F9A03C  af 08 25   arg1: source   (LDI/LDIRW read (XIY+))
	ld xix, (xsp+12)                           ; F9A03F  af 0c 24   arg2: dest     (LDI/LDIRW write (XIX+))
	bit 0, bc                                  ; F9A042  d9 33 00
	jr z, MemCopyWords__words                  ; F9A045  66 02   odd count: move the leading byte first
	ldi85                                      ; F9A047  85 10
MemCopyWords__words:
	srl bc, 1                                  ; F9A049  d9 ef 01   the rest as 16-bit words
	ldirw                                      ; F9A04C  95 11
	pop xix                                    ; F9A04E  5c
	ret                                        ; F9A04F  0e

	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x01A050, 0x0324EF

; ============================================================================
; 0xFCC53F-0xFCD0F6 -- touch / EQ / mixer-gain / descriptor-string zone
; ============================================================================
;
; Generated by notes/gen_prom_c_tables.py (SPEC2); the numbers are read out of the
; ROM, never retyped.  This zone rests on DIFFERENT evidence from the big table
; zone at 0xFDD2AB: only five of its objects have a KN5000 counterpart, so most of
; it is carried by prom_c's own reference sites plus decodes that are
; self-evidently right -- the EQ table comes out as the ISO third-octave series,
; and both mixer curves end exactly on digital full scale, values a wrong base or
; a wrong element size could not produce.
;
; Two objects are deliberately NOT decoded and say why in their own headers: the
; f32/f64 constant pool at 0xFCC81A (stride not established) and three bytes at
; 0xFCCB6E.  An honest .incbin beats an invented stride.

; ----------------------------------------------------------------------------
; Handler_PtrTable_FCC53F -- 0xFCC53F..0xFCC55E  (32 bytes)
;
; 8 x u32.  Every entry is a valid prom_c code address, and four of them
; (0xF98D9A, 0xF98DE6, 0xF98FD6, 0xF9901B) land exactly on a `link XIZ,imm` /
; `push HL` prologue -- this compiler's function entry -- while the remaining
; four are all the SAME address, 0xF9993D, whose first byte is 0x0E = RET.
; A handler table with four real arms and four do-nothing stubs.
;
; ★ ROUND 2: THE TWO OPEN QUESTIONS ARE ANSWERED, and the reason a literal search
; found nothing is that the dispatcher never uses the ROM address.  RESET copies
; ROM 0xFCB4EA.. to RAM 0x00E2DF (notes/prom_c_ram_image.py re-derives the copy
; from the instruction bytes), and 0xFCC53F - 0xFCB4EA = 0x1055, so this table's
; RAM copy begins at 0x00E2DF + 0x1055 = 0x00F334.  That address appears as an
; instruction operand at 0xF99D91, `add xbc, 0x0000F334`, inside
; INTTC3_HANDLER__state1_generic (0xF99D6F, converted in this file): it indexes
; the table with (link command byte >> 5) * 4 and jumps through it.  So the START
; is proven by an operand after all, the dispatcher is traced, and the entry count
; of EIGHT is exactly the range of a 3-bit index.
;     python3 notes/prom_c_ram_image.py 0x00F334:32     # the boot contents
;     python3 notes/prom_c_link_state_machine.py        # the dispatcher
; ⚠ Still not established: what the four real class handlers DO.
; ----------------------------------------------------------------------------
Handler_PtrTable_FCC53F:
	.long	0x00f98d9a, 0x00f98de6, 0x00f98fd6, 0x00f9901b
	.long	0x00f9993d, 0x00f9993d, 0x00f9993d, 0x00f9993d

; ----------------------------------------------------------------------------
; unexplained_FCC55F -- 0xFCC55F..0xFCC575  (23 bytes)
;
; 23 bytes that fit no structure found so far: 16 zero bytes, then
; 00 53 6c 00 6c 00 6c 00.  Left as bytes rather than guessed at.
; ----------------------------------------------------------------------------
unexplained_FCC55F:
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x53, 0x6c, 0x00, 0x6c, 0x00, 0x6c, 0x00

; ----------------------------------------------------------------------------
; Packet_PtrTable_FCC576 -- 0xFCC576..0xFCC5BD  (72 bytes)
;
; 6 groups x 3 u32 = 18 pointers, all into the length-prefixed packet pool that
; starts at 0xFCD0F7.  The grouping is visible in the data itself: every group is
; {X, X, Y} -- the first two entries of each group are always equal.
;    group 0  {0xFCD22D, 0xFCD22D, 0xFCD40F}
;    group 1  {0xFCD97D, 0xFCD97D, 0xFCD40F}
;    group 2  {0xFCD0FE, 0xFCD0FE, 0xFCD0F7}
;    group 3  {0xFCD105, 0xFCD105, 0xFCD0F7}
;    group 4  {0xFCD119, 0xFCD119, 0xFCD10C}
;    group 5  {0xFCD131, 0xFCD131, 0xFCD10C}
; Five of the six distinct low targets are exactly the packet starts that the
; length walk in the header of the string pool below lands on, which is what ties
; the two structures together.
; ⚠ NOT ESTABLISHED: the table start, again -- no literal reference to 0xFCC576.
; ----------------------------------------------------------------------------
Packet_PtrTable_FCC576:
	; group 0
	.long	0x00fcd22d, 0x00fcd22d, 0x00fcd40f
	; group 1
	.long	0x00fcd97d, 0x00fcd97d, 0x00fcd40f
	; group 2
	.long	0x00fcd0fe, 0x00fcd0fe, 0x00fcd0f7
	; group 3
	.long	0x00fcd105, 0x00fcd105, 0x00fcd0f7
	; group 4
	.long	0x00fcd119, 0x00fcd119, 0x00fcd10c
	; group 5
	.long	0x00fcd131, 0x00fcd131, 0x00fcd10c

; ----------------------------------------------------------------------------
; unexplained_FCC5BE -- 0xFCC5BE..0xFCC5C8  (11 bytes)
;
; 11 bytes between the pointer table and the first touch curve.  Four zeros then
; ff fa fb 4d 00 80 00.
;
; ★ FOUR OF THE ELEVEN ARE NOW EXPLAINED (2026-08-24).  The u16 at 0xFCC5C5 is
; 0x004D = 77 and the u16 at 0xFCC5C7 is 0x0080 = 128, and
; ToneGen_VelocityFromTouch (0xF995DF, converted above) reads both:
;       ld DE,(curve output) / sub DE,(0xFCC5C5)      ; subtract 77
;       muls XBC,WA / divs XBC,(0xFCC5C7)             ; times gain, over 128
; 77 is the PIVOT of the touch transfer function -- the input-curve value at
; which the bracket goes to zero and the output equals
; ToneGen_VelCurve_ModeParams[mode].pivot whatever the gain is -- and 128 is the
; fixed-point divisor that makes that record's first column read as gain/128,
; which is exactly how the header below already describes it.
; The input curve holds 77 at index 144 and at NO other index, so the pivot is a
; single point on the curve.
;
; ⚠ Still unexplained: the four leading zeros and the bytes ff fa fb at
; 0xFCC5C2-0xFCC5C4.  Note also that the first FOUR bytes of this object (the
; zeros) are inside the boot RAM image copied to 0x00F3B3, and that RAM address
; IS written at runtime (0xFA2DD4) -- see notes/FINDINGS-prom_c-ram-image.md.
; So this object is not homogeneous: its head is a RAM initialiser and its tail
; is two constants read in place.
; ----------------------------------------------------------------------------
unexplained_FCC5BE:
	.byte	0x00, 0x00, 0x00, 0x00, 0xff, 0xfa, 0xfb, 0x4d, 0x00, 0x80, 0x00

; ----------------------------------------------------------------------------
; ToneGen_VelCurve_Trim51 -- 0xFCC5C9..0xFCC5FB  (51 bytes)
;
; 51 signed bytes rising from 0xF4 (-12) to 0x0A (+10), zero-crossing in the
; middle -- a symmetric +-12 trim curve.  Referenced once, from 0xF99874, which
; is inside the same routine family as the touch tables that follow it.
; No KN5000 counterpart at the corresponding address.
; ----------------------------------------------------------------------------
ToneGen_VelCurve_Trim51:
	.byte	0xf4, 0xf4, 0xf5, 0xf6, 0xf6, 0xf7, 0xf7, 0xf8, 0xf8, 0xf9, 0xf9, 0xfa, 0xfb, 0xfb, 0xfc, 0xfc
	.byte	0xfd, 0xfd, 0xfe, 0xfe, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x02, 0x02, 0x03
	.byte	0x03, 0x04, 0x04, 0x04, 0x05, 0x05, 0x06, 0x06, 0x06, 0x07, 0x07, 0x08, 0x08, 0x08, 0x09, 0x09
	.byte	0x0a, 0x0a, 0x0a

; ----------------------------------------------------------------------------
; ToneGen_VelCurve_ModeParams -- 0xFCC5FC..0xFCC619  (30 bytes)
;
; 10 records x 3 bytes: {gain/128, output level at the pivot, trim subtracted for
; the black keys}.  This is the TOUCH SENSITIVITY table.
; ★ The table SELF-DESCRIBES: the first column steps 0x00, 0x10, 0x20 ... 0x90,
;   so the record size and the row count are both readable off the data.
; ★ It also sits at exactly the address the KN5000 offset predicts.  The 256-byte
;   curve that follows it here is byte-identical to the KN5000's, and under that
;   alignment this table lands on kn5000 0x01F420 -- the address the sibling
;   documents as the touch-mode parameter table (v142/subcpu/subcpu_data_tables.s:11302).
; The VALUES are re-tuned for this instrument; they are NOT the KN5000's:
;      curve  gain  pivot out   black trim      (KN5000, for comparison)
;        0     0/128    208         0             208   0
;        1    16/128    199         2             199   3
;        2    32/128    190         5             189   6
;        3    48/128    181         8             180   8
;        4    64/128    171        11             171  11
;        5    80/128    162        13             161  14
;        6    96/128    153        16             152  16
;        7   112/128    144        19             143  19
;        8   128/128    134        22             134  22
;        9   144/128    125        24             130  24
; Referenced three times: 0xF9962D, 0xF9966F, 0xF99698.
; ----------------------------------------------------------------------------
ToneGen_VelCurve_ModeParams:
	; curve 0
	.byte	0x00, 0xd0, 0x00
	; curve 1
	.byte	0x10, 0xc7, 0x02
	; curve 2
	.byte	0x20, 0xbe, 0x05
	; curve 3
	.byte	0x30, 0xb5, 0x08
	; curve 4
	.byte	0x40, 0xab, 0x0b
	; curve 5
	.byte	0x50, 0xa2, 0x0d
	; curve 6
	.byte	0x60, 0x99, 0x10
	; curve 7
	.byte	0x70, 0x90, 0x13
	; curve 8
	.byte	0x80, 0x86, 0x16
	; curve 9
	.byte	0x90, 0x7d, 0x18

; ----------------------------------------------------------------------------
; ToneGen_Velocity_Input_Curve -- 0xFCC61A..0xFCC719  (256 bytes)
;
; 256 bytes, monotonically DECREASING (0xFF for the first nine inputs, down to
; 0x00 at the top).  Maps the raw keybed touch reading to the curve domain.
; The sibling argues [INFERENCE] that the decreasing sense means the raw reading
; behaves like a key-travel TIME -- a small reading is a hard strike.
; Referenced from 0xF99608.  Byte-identical to v142/subcpu/subcpu_data_tables.s:11337 (kn5000 0x01F43E).
; ----------------------------------------------------------------------------
ToneGen_Velocity_Input_Curve:
	.byte	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfb, 0xf6, 0xf1, 0xed, 0xea, 0xe6, 0xe3
	.byte	0xe0, 0xdd, 0xdb, 0xd8, 0xd6, 0xd3, 0xd1, 0xcf, 0xcd, 0xcb, 0xca, 0xc8, 0xc6, 0xc5, 0xc3, 0xc1
	.byte	0xc0, 0xbf, 0xbd, 0xbc, 0xbb, 0xb9, 0xb8, 0xb7, 0xb6, 0xb5, 0xb3, 0xb2, 0xb1, 0xb0, 0xaf, 0xae
	.byte	0xad, 0xac, 0xab, 0xaa, 0xaa, 0xa9, 0xa8, 0xa7, 0xa6, 0xa5, 0xa5, 0xa4, 0xa3, 0xa2, 0xa1, 0xa1
	.byte	0xa0, 0x9f, 0x9d, 0x9c, 0x9b, 0x99, 0x98, 0x97, 0x96, 0x95, 0x93, 0x92, 0x91, 0x90, 0x8f, 0x8e
	.byte	0x8d, 0x8c, 0x8b, 0x8a, 0x8a, 0x89, 0x88, 0x87, 0x86, 0x85, 0x85, 0x84, 0x83, 0x82, 0x81, 0x81
	.byte	0x80, 0x7f, 0x7d, 0x7c, 0x7b, 0x79, 0x78, 0x77, 0x76, 0x75, 0x73, 0x72, 0x71, 0x70, 0x6f, 0x6e
	.byte	0x6d, 0x6c, 0x6b, 0x6a, 0x6a, 0x69, 0x68, 0x67, 0x66, 0x65, 0x65, 0x64, 0x63, 0x62, 0x61, 0x61
	.byte	0x60, 0x5f, 0x5d, 0x5c, 0x5b, 0x59, 0x58, 0x57, 0x56, 0x55, 0x53, 0x52, 0x51, 0x50, 0x4f, 0x4e
	.byte	0x4d, 0x4c, 0x4b, 0x4a, 0x4a, 0x49, 0x48, 0x47, 0x46, 0x45, 0x45, 0x44, 0x43, 0x42, 0x41, 0x41
	.byte	0x40, 0x3f, 0x3d, 0x3c, 0x3b, 0x39, 0x38, 0x37, 0x36, 0x35, 0x33, 0x32, 0x31, 0x30, 0x2f, 0x2e
	.byte	0x2d, 0x2c, 0x2b, 0x2a, 0x2a, 0x29, 0x28, 0x27, 0x26, 0x25, 0x25, 0x24, 0x23, 0x22, 0x21, 0x21
	.byte	0x20, 0x1f, 0x1d, 0x1c, 0x1b, 0x19, 0x18, 0x17, 0x16, 0x15, 0x13, 0x12, 0x11, 0x10, 0x0f, 0x0e
	.byte	0x0d, 0x0c, 0x0b, 0x0a, 0x0a, 0x09, 0x08, 0x07, 0x06, 0x05, 0x05, 0x04, 0x03, 0x02, 0x01, 0x01
	.byte	0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	.byte	0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00

; ----------------------------------------------------------------------------
; ToneGen_Velocity_Output_Curve -- 0xFCC71A..0xFCC819  (256 bytes)
;
; 256 bytes, the second half of the touch mapping: starts 0x01 then a long run of
; 0x02 -- a compressive, roughly logarithmic response.  This is the end that
; produces the delivered MIDI velocity, so it RISES with strike strength.
; Referenced from 0xF99721 (24-bit form).  Byte-identical to kn5000 0x01F53E
; (v142/subcpu/subcpu_data_tables.s:11361).
; ----------------------------------------------------------------------------
ToneGen_Velocity_Output_Curve:
	.byte	0x01, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02
	.byte	0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02
	.byte	0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02
	.byte	0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02
	.byte	0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02
	.byte	0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02
	.byte	0x03, 0x03, 0x03, 0x04, 0x04, 0x04, 0x04, 0x05, 0x05, 0x05, 0x05, 0x06, 0x06, 0x06, 0x07, 0x07
	.byte	0x07, 0x07, 0x08, 0x08, 0x08, 0x08, 0x09, 0x09, 0x09, 0x0a, 0x0a, 0x0a, 0x0a, 0x0b, 0x0b, 0x0b
	.byte	0x0c, 0x0c, 0x0c, 0x0c, 0x0d, 0x0d, 0x0d, 0x0d, 0x0e, 0x0e, 0x0e, 0x0f, 0x0f, 0x0f, 0x0f, 0x10
	.byte	0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f
	.byte	0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f
	.byte	0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f
	.byte	0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f
	.byte	0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f
	.byte	0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f
	.byte	0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f

; ----------------------------------------------------------------------------
; fp_constant_pool_FCC81A -- 0xFCC81A..0xFCCA81  (616 bytes)
;
; 616 bytes LEFT AS .incbin ON PURPOSE.
; It is an IEEE-754 constant pool -- IEEE doubles are visible in it by eye (the
; bytes 00 00 00 00 00 00 4C 40 are 56.0) -- but the element boundaries are NOT
; established: decoding it as f64 from any of the obvious start offsets yields
; mostly denormal garbage (7 of 76 candidates come out as round numbers from the
; best-looking alignment), so the pool is not uniformly 8-byte strided and some
; of it is probably f32 or something else.  Guessing a stride here would produce
; a table of nonsense that the byte gate would happily accept.
; The KN5000 has a pool of the same kind two tables earlier (v142/subcpu/subcpu_data_tables.s:2695); its
; contents do NOT match, so the sibling cannot supply the boundaries either.
; ----------------------------------------------------------------------------
fp_constant_pool_FCC81A:
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x04C81A, 0x268

; ----------------------------------------------------------------------------
; DSP_EQ_FreqHz_Table -- 0xFCCA82..0xFCCAED  (108 bytes)
;
; 27 x f32: parametric-EQ centre frequencies in Hz.
; ★ SELF-PROVING: decoded as little-endian f32 from this address the 27 values
;   come out as exactly the ISO third-octave series 40, 50, 63, 80 ... 12500,
;   16000.  A one-byte error in the base, or a wrong element size, turns that
;   into denormals.  The decoded value is written beside every entry below.
; Referenced four times: 0xF9E292, 0xF9E9A6, 0xF9ED8B, 0xF9F246.
; Byte-identical to kn5000 0x012397 (v142/subcpu/subcpu_data_tables.s:2510).
; ----------------------------------------------------------------------------
DSP_EQ_FreqHz_Table:
	.long	0x42200000	; [ 0] = 40
	.long	0x42480000	; [ 1] = 50
	.long	0x427c0000	; [ 2] = 63
	.long	0x42a00000	; [ 3] = 80
	.long	0x42c80000	; [ 4] = 100
	.long	0x42fa0000	; [ 5] = 125
	.long	0x43200000	; [ 6] = 160
	.long	0x43480000	; [ 7] = 200
	.long	0x437a0000	; [ 8] = 250
	.long	0x439d8000	; [ 9] = 315
	.long	0x43c80000	; [10] = 400
	.long	0x43fa0000	; [11] = 500
	.long	0x441d8000	; [12] = 630
	.long	0x44480000	; [13] = 800
	.long	0x447a0000	; [14] = 1000
	.long	0x449c4000	; [15] = 1250
	.long	0x44c80000	; [16] = 1600
	.long	0x44fa0000	; [17] = 2000
	.long	0x451c4000	; [18] = 2500
	.long	0x4544e000	; [19] = 3150
	.long	0x457a0000	; [20] = 4000
	.long	0x459c4000	; [21] = 5000
	.long	0x45c4e000	; [22] = 6300
	.long	0x45fa0000	; [23] = 8000
	.long	0x461c4000	; [24] = 10000
	.long	0x46435000	; [25] = 12500
	.long	0x467a0000	; [26] = 16000

; ----------------------------------------------------------------------------
; DSP_EQ_Q_Table -- 0xFCCAEE..0xFCCB6D  (128 bytes)
;
; 32 x f32: parametric-EQ Q / bandwidth values -- 0.1..0.9 by 0.1, then 1.0..4.0
; by 0.5, then 5..20 by 1.  Same self-proving decode as the frequency table.
; Referenced from 0xF9E203.  Byte-identical to kn5000 0x012403 (v142/subcpu/subcpu_data_tables.s:2520).
; ----------------------------------------------------------------------------
DSP_EQ_Q_Table:
	.long	0x3dcccccd	; [ 0] = 0.1
	.long	0x3e4ccccd	; [ 1] = 0.2
	.long	0x3e99999a	; [ 2] = 0.3
	.long	0x3ecccccd	; [ 3] = 0.4
	.long	0x3f000000	; [ 4] = 0.5
	.long	0x3f19999a	; [ 5] = 0.6
	.long	0x3f333333	; [ 6] = 0.7
	.long	0x3f4ccccd	; [ 7] = 0.8
	.long	0x3f666666	; [ 8] = 0.9
	.long	0x3f800000	; [ 9] = 1
	.long	0x3fc00000	; [10] = 1.5
	.long	0x40000000	; [11] = 2
	.long	0x40200000	; [12] = 2.5
	.long	0x40400000	; [13] = 3
	.long	0x40600000	; [14] = 3.5
	.long	0x40800000	; [15] = 4
	.long	0x40a00000	; [16] = 5
	.long	0x40c00000	; [17] = 6
	.long	0x40e00000	; [18] = 7
	.long	0x41000000	; [19] = 8
	.long	0x41100000	; [20] = 9
	.long	0x41200000	; [21] = 10
	.long	0x41300000	; [22] = 11
	.long	0x41400000	; [23] = 12
	.long	0x41500000	; [24] = 13
	.long	0x41600000	; [25] = 14
	.long	0x41700000	; [26] = 15
	.long	0x41800000	; [27] = 16
	.long	0x41880000	; [28] = 17
	.long	0x41900000	; [29] = 18
	.long	0x41980000	; [30] = 19
	.long	0x41a00000	; [31] = 20

; ----------------------------------------------------------------------------
; unexplained_FCCB6E -- 0xFCCB6E..0xFCCB70  (3 bytes)
;
; 3 bytes, 00 01 00, sitting between the Q table and the gain curve.  0xFCCB6E is
; referenced three times (0xFA2C21, 0xFA2CD9, 0xFA2D8C) so it is a real object,
; but three bytes is too little to infer a shape from and the readers are not
; traced.  Left as bytes.
; ----------------------------------------------------------------------------
unexplained_FCCB6E:
	.byte	0x00, 0x01, 0x00

; ----------------------------------------------------------------------------
; DSP_MixerGain_Curve_B -- 0xFCCB71..0xFCCD70  (512 bytes)
;
; 128 x u32, strictly monotonic, ending EXACTLY at 0x7FFFFF00 = digital full
; scale.  The wide-range curve of the pair: it spans 0x00002068 to 0x7FFFFF00,
; about 108 dB, with a steep bottom (ratio up to 3.16 per step) flattening to
; 1.017 per step at the top.
; ★ ELEMENT SIZE AND COUNT PROVEN BY THE CONSUMER at 0xFA30D8:
;       ld WA,0x0004 / muls XWA,(XIZ+0x08)   ; index * 4
;       add XWA,0x00FCCB71 / ld XWA,(XWA)    ; 32-bit load
;       sra 0x00,XWA                         ; used unshifted
;   and the same routine seeds a register with the literal 0x7FFFFF00, the value
;   this curve ends on.  The 128 entries are the space to its neighbour.
; WSA1-only: it matches none of the KN5000's five u32 ladders (best 32/512 bytes).
; ----------------------------------------------------------------------------
DSP_MixerGain_Curve_B:
	.long	0x00002068, 0x0000667e, 0x00014427, 0x0004012e
	.long	0x000caa46, 0x00280e26, 0x007eae30, 0x0190a508
	.long	0x04f31850, 0x05367a60, 0x057d71c0, 0x05c82f40
	.long	0x0616e648, 0x0669cce8, 0x06c11c28, 0x071d1000
	.long	0x077de7b0, 0x07e3e5c8, 0x084f5060, 0x08c07150
	.long	0x09379660, 0x09b51170, 0x0a3938d0, 0x0ac46750
	.long	0x0b56fc90, 0x0bf15d60, 0x0c93f3e0, 0x0d3f2fd0
	.long	0x0df386f0, 0x0eb17530, 0x0f797d20, 0x104c2840
	.long	0x112a0760, 0x11aa5980, 0x122e6b00, 0x12b657e0
	.long	0x13423ce0, 0x13d237c0, 0x14666700, 0x14feea20
	.long	0x159be180, 0x163d6e60, 0x16e3b300, 0x178ed2a0
	.long	0x183ef1a0, 0x18f43540, 0x19aec420, 0x1a6ec5a0
	.long	0x1b3462a0, 0x1bffc500, 0x1cd117e0, 0x1da887c0
	.long	0x1e864240, 0x1f6a7660, 0x20555480, 0x21470e80
	.long	0x223fd7c0, 0x233fe500, 0x24476c80, 0x2556a600
	.long	0x266dcb40, 0x278d1780, 0x28b4c780, 0x29e51a40
	.long	0x2b1e5000, 0x2bde9cc0, 0x2ca24300, 0x2d695200
	.long	0x2e33d8c0, 0x2f01e6c0, 0x2fd38b80, 0x30a8d740
	.long	0x3181da40, 0x325ea540, 0x333f48c0, 0x3423d640
	.long	0x350c5f00, 0x35f8f4c0, 0x36e9a9c0, 0x37de9040
	.long	0x38d7bb00, 0x39d53d00, 0x3ad72980, 0x3bdd9440
	.long	0x3ce89140, 0x3df83500, 0x3f0c9440, 0x4025c400
	.long	0x4143da00, 0x4266ec00, 0x438f1000, 0x44bc5c80
	.long	0x45eee900, 0x4726cc80, 0x48641f00, 0x49a6f880
	.long	0x4aef7200, 0x4c3da480, 0x4d91a980, 0x4eeb9b00
	.long	0x504b9300, 0x51b1ad00, 0x531e0400, 0x5490b400
	.long	0x5609d900, 0x57899000, 0x590ff680, 0x5a9d2a00
	.long	0x5c314900, 0x5dcc7200, 0x5f6ec500, 0x61186180
	.long	0x62c96800, 0x6481fa00, 0x66423880, 0x680a4680
	.long	0x69da4600, 0x6bb25b00, 0x6d92a980, 0x6f7b5600
	.long	0x716c8600, 0x73665f80, 0x75690900, 0x7774a980
	.long	0x79896980, 0x7ba77180, 0x7dceea80, 0x7fffff00

; ----------------------------------------------------------------------------
; DSP_MixerGain_Curve_A -- 0xFCCD71..0xFCCF70  (512 bytes)
;
; 128 x u32, strictly monotonic, also ending exactly at 0x7FFFFF00.  The narrow
; companion of curve B: 0x00451EB3..0x7FFFFF00, about 53.5 dB.
; ★ Same consumer, four instructions earlier (0xFA30C5):
;       ld WA,0x0004 / muls XWA,(XIZ+0x0a) / add XWA,0x00FCCD71 / ld XWA,(XWA)
;       ld XIX,XWA / sra 0x0f,XIX           ; >> 15
;   and the two looked-up values are then pushed together into 0xFCB0D3 -- a
;   two-stage product.  The `>> 15` is exactly what the sibling documents for its
;   copy of this curve (v142/subcpu/subcpu_data_tables.s:2926), which is byte-identical to this one
;   (kn5000 0x0131CF).  53.5 dB total span there and here.
; ----------------------------------------------------------------------------
DSP_MixerGain_Curve_A:
	.long	0x00451eb3, 0x004fa2d0, 0x005bc083, 0x0069b61b
	.long	0x0079cb66, 0x008c531b, 0x00a1ac88, 0x00ba457a
	.long	0x00d69c75, 0x00f7433a, 0x011ce1b8, 0x0148396a
	.long	0x017a293c, 0x01b3b204, 0x01f5fbac, 0x02425b20
	.long	0x029a5930, 0x02ffba6c, 0x0374883c, 0x03fb1b60
	.long	0x04962800, 0x0548cb88, 0x06169cc8, 0x0703be48
	.long	0x0814f3b0, 0x094fba20, 0x099c6990, 0x09eb9090
	.long	0x0a3d4370, 0x0a919720, 0x0ae8a150, 0x0b427850
	.long	0x0b9f3330, 0x0bfee9c0, 0x0c61b490, 0x0cc7ad00
	.long	0x0d30ed40, 0x0d9d9050, 0x0e0db210, 0x0e816f40
	.long	0x0ef8e5a0, 0x0f7433e0, 0x0ff379a0, 0x1076d780
	.long	0x10fe6f40, 0x118a63c0, 0x121ad8e0, 0x12aff3a0
	.long	0x1349da60, 0x13e8b4a0, 0x148cab20, 0x1535e7e0
	.long	0x15e49660, 0x1698e380, 0x1752fd80, 0x18131440
	.long	0x18d958e0, 0x19a5fe60, 0x1a793940, 0x1b533fc0
	.long	0x1c3449e0, 0x1d1c9160, 0x1e0c51c0, 0x1f03c8a0
	.long	0x20033580, 0x210ada00, 0x221af9c0, 0x2333da80
	.long	0x2455c480, 0x25810240, 0x26b5e040, 0x27f4ae00
	.long	0x293dbd40, 0x2a916280, 0x2beff500, 0x2d59cec0
	.long	0x2ecf4c80, 0x3050ce40, 0x31deb6c0, 0x33796c40
	.long	0x35215840, 0x36d6e780, 0x389a8a40, 0x3a6cb480
	.long	0x3c4dde00, 0x3e3e8240, 0x403f2080, 0x42503c80
	.long	0x44725e00, 0x46a61180, 0x48ebe700, 0x4b447480
	.long	0x4db05400, 0x50302480, 0x52c48a00, 0x556e2e80
	.long	0x582dc080, 0x5b03f500, 0x5df18600, 0x60f73480
	.long	0x6415c680, 0x674e0980, 0x6aa0d080, 0x6e0ef680
	.long	0x6f45d380, 0x70801e80, 0x71bde180, 0x72ff2600
	.long	0x7443f600, 0x758c5b80, 0x76d86080, 0x78280f00
	.long	0x797b7200, 0x7ad29380, 0x7c2d7e00, 0x7d8c3c80
	.long	0x7dc01680, 0x7df40580, 0x7e280a00, 0x7e5c2400
	.long	0x7e905380, 0x7ec49880, 0x7ef8f380, 0x7f2d6400
	.long	0x7f61ea00, 0x7f968600, 0x7fcb3780, 0x7fffff00

; ----------------------------------------------------------------------------
; DescriptorStrings -- 0xFCCF71..0xFCD0F6  (390 bytes)
;
; A pool of 44 NUL-terminated ASCII strings in two interleaved families:
;   * FIELD-TYPE strings over the alphabet {b, w, v, s, h, c, B} -- 'bbbvb',
;     'bwwbbv', 'wwcbbbbbv', ... ;
;   * INDEX strings '0', '01234', '0123456789abc' -- a run of consecutive
;     base-36 digits whose length matches the type string it is paired with.
; The pairing is not a guess: the pointer records at 0xFDBFE9 onward load the two
; members of a pair four bytes apart (0xFDBFE9 -> 'bbbvb'-family, 0xFDBFED ->
; the digit string), and 0xFCCF77 alone is loaded 21 times.
; [INFERENCE, stated as such] this is a field-layout descriptor: one letter per
; field giving its width or kind, and the digit string giving each field an index.
; What the letters mean individually is NOT ESTABLISHED -- 'b'/'w' as byte/word
; is the obvious reading but nothing here proves it.
; ----------------------------------------------------------------------------
DescriptorStrings:
	.asciz	"bbbvb"	; [ 0] 0xFCCF71
	.asciz	"01234"	; [ 1] 0xFCCF77
	.asciz	"bbbwbvb"	; [ 2] 0xFCCF7D
	.asciz	"0123456"	; [ 3] 0xFCCF85
	.asciz	"wwwwwwv"	; [ 4] 0xFCCF8D
	.asciz	"bbbbv"	; [ 5] 0xFCCF95
	.asciz	"bbbbbbv"	; [ 6] 0xFCCF9B
	.asciz	"bbbbwwv"	; [ 7] 0xFCCFA3
	.asciz	"bbbbbbbv"	; [ 8] 0xFCCFAB
	.asciz	"01234567"	; [ 9] 0xFCCFB4
	.asciz	"bbbbbv"	; [10] 0xFCCFBD
	.asciz	"012345"	; [11] 0xFCCFC4
	.asciz	"bsssbv"	; [12] 0xFCCFCB
	.asciz	"bsssv"	; [13] 0xFCCFD2
	.asciz	"bbbbbbbbbvb"	; [14] 0xFCCFD8
	.asciz	"0123456789a"	; [15] 0xFCCFE4
	.asciz	"v"	; [16] 0xFCCFF0
	.asciz	"0"	; [17] 0xFCCFF2
	.asciz	"bbhbbv"	; [18] 0xFCCFF4
	.asciz	"bwwbbv"	; [19] 0xFCCFFB
	.asciz	"bcbbv"	; [20] 0xFCD002
	.asciz	"bwwbbbv"	; [21] 0xFCD008
	.asciz	"bwwwwbbbbbbv"	; [22] 0xFCD010
	.asciz	"0123456789ab"	; [23] 0xFCD01D
	.asciz	"bbwwBBbv"	; [24] 0xFCD02A
	.asciz	"bbhbv"	; [25] 0xFCD033
	.asciz	"bwwbbbbbbv"	; [26] 0xFCD039
	.asciz	"0123456789"	; [27] 0xFCD044
	.asciz	"bwwbbbwwbbv"	; [28] 0xFCD04F
	.asciz	"bwwbbbbbbbbbv"	; [29] 0xFCD05B
	.asciz	"0123456789abc"	; [30] 0xFCD069
	.asciz	"bwwbbbbbbbv"	; [31] 0xFCD077
	.asciz	"bbbbbwwbbv"	; [32] 0xFCD083
	.asciz	"wwbbbbv"	; [33] 0xFCD08E
	.asciz	"wwbwwbbv"	; [34] 0xFCD096
	.asciz	"wwbbbbbbbv"	; [35] 0xFCD09F
	.asciz	"wwbbbbbv"	; [36] 0xFCD0AA
	.asciz	"wwcbbv"	; [37] 0xFCD0B3
	.asciz	"wwcbbbbbv"	; [38] 0xFCD0BA
	.asciz	"012345678"	; [39] 0xFCD0C4
	.asciz	"wcbbbbvb"	; [40] 0xFCD0CE
	.asciz	"wwbbbwwbbvb"	; [41] 0xFCD0D7
	.asciz	"bBBbBvb"	; [42] 0xFCD0E3
	.asciz	"bbbbbbwwbbv"	; [43] 0xFCD0EB

; ==============================================================================
; 0xFCD0F7-0xFDD2AA -- not yet converted
; ==============================================================================
; Begins with the length-prefixed packet pool the table at 0xFCC576 points into.
; Framing CONFIRMED for the first four records -- a 16-bit big-endian length
; followed by that many bytes walks 0xFCD0F7 -> 0xFCD0FE -> 0xFCD105 -> 0xFCD10C
; -> 0xFCD119, and every one of those four landing points is a pointer target in
; that table.  The walk then desynchronises at 0xFCD119 (its length says 11 but
; the next pointer target is 24 bytes further on), so the framing is NOT fully
; established and the pool is left as bytes rather than mis-split.
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x04D0F7, 0x0101B4

; ============================================================================
; 0xFDD2AB-0xFDF7DF -- the voice / DSP data-table zone (9,525 B, 43 tables)
; ============================================================================
;
; Generated by notes/gen_prom_c_tables.py -- the numbers are read out of the ROM,
; never retyped.  `python3 notes/gen_prom_c_tables.py --verify` re-proves the
; three independent facts the boundaries rest on:
;
;   1. 36 of the 43 tables are BYTE-IDENTICAL, over their whole length, to a
;      named table in the KN5000 sub-CPU payload, at the size that project's
;      map states (../kn5000-roms-disasm/v142/subcpu/subcpu_data_tables.s).
;   2. The 43 tables laid end to end from 0xFDD2AB reach 0xFDF7DF exactly, with
;      no gap and no overlap, and zero fill follows.  One wrong size would
;      desynchronise everything after it and the identity checks would collapse.
;   3. 39 of the 43 start addresses occur in THIS image as a literal 32-bit
;      address operand.  That is prom_c's own code agreeing with the boundary,
;      with no reference to the sibling project at all.  The reference sites are
;      quoted in each header.
;
; ⚠ WHAT THIS DOES NOT ESTABLISH.  Byte identity establishes that the DATA is the
; same.  It does NOT establish that the WSA1 routine reading a table does what the
; KN5000 routine of that name does.  Three readers HAVE been disassembled here and
; are quoted where they are relevant (the key-bend selector at 0xFA8016, the
; chromatic-bend indexer at 0xFA8046, the bit-mask readers at 0xFB0BE8/0xFAFC9D);
; every other name is carried over on byte identity alone and says so.
;
; ⚠ The KN5000 addresses quoted below are LINK addresses in that project's map.
; They are NOT `0x400 + payload file offset` -- that formula, used by
; scripts/analysis/transplant_kn5000_labels.py, is wrong by 0xEB00 because the
; sibling's ROM file is built with a 60,160-byte hole in it.  See
; notes/prom_c_kn5000_xref.py, which proves the correct mapping from the bytes.
;
; PROVENANCE unchanged: this is the publicly redistributed v2 firmware set, not a
; chip read (../technics_roms/roms/wsa1/PROVENANCE.md).

; ----------------------------------------------------------------------------
; Voice_Reg080_NoteField_Table -- 0xFDD2AB..0xFDD3AA  (256 bytes)
;
; 128 u16, indexed by the played note after octave folding.
; Supplies bits 14..12 of a tone-generator register on the branch that does not
; take the zone record's own bits.  Byte-identical to the KN5000 table, and the
; closed form the sibling proves there holds here too, all 128 entries, no
; exceptions:   T[n] = floor(2 * (n mod 12) / 3) << 12
; -- an eight-step staircase per octave.  Referenced from 0xFA7E14.
; Sibling: kn5000 sub-CPU 0x00FBE4, v142/subcpu/subcpu_data_tables.s:931
; ----------------------------------------------------------------------------
Voice_Reg080_NoteField_Table:
	.short	0x0000, 0x0000, 0x1000, 0x2000, 0x2000, 0x3000, 0x4000, 0x4000
	.short	0x5000, 0x6000, 0x6000, 0x7000, 0x0000, 0x0000, 0x1000, 0x2000
	.short	0x2000, 0x3000, 0x4000, 0x4000, 0x5000, 0x6000, 0x6000, 0x7000
	.short	0x0000, 0x0000, 0x1000, 0x2000, 0x2000, 0x3000, 0x4000, 0x4000
	.short	0x5000, 0x6000, 0x6000, 0x7000, 0x0000, 0x0000, 0x1000, 0x2000
	.short	0x2000, 0x3000, 0x4000, 0x4000, 0x5000, 0x6000, 0x6000, 0x7000
	.short	0x0000, 0x0000, 0x1000, 0x2000, 0x2000, 0x3000, 0x4000, 0x4000
	.short	0x5000, 0x6000, 0x6000, 0x7000, 0x0000, 0x0000, 0x1000, 0x2000
	.short	0x2000, 0x3000, 0x4000, 0x4000, 0x5000, 0x6000, 0x6000, 0x7000
	.short	0x0000, 0x0000, 0x1000, 0x2000, 0x2000, 0x3000, 0x4000, 0x4000
	.short	0x5000, 0x6000, 0x6000, 0x7000, 0x0000, 0x0000, 0x1000, 0x2000
	.short	0x2000, 0x3000, 0x4000, 0x4000, 0x5000, 0x6000, 0x6000, 0x7000
	.short	0x0000, 0x0000, 0x1000, 0x2000, 0x2000, 0x3000, 0x4000, 0x4000
	.short	0x5000, 0x6000, 0x6000, 0x7000, 0x0000, 0x0000, 0x1000, 0x2000
	.short	0x2000, 0x3000, 0x4000, 0x4000, 0x5000, 0x6000, 0x6000, 0x7000
	.short	0x0000, 0x0000, 0x1000, 0x2000, 0x2000, 0x3000, 0x4000, 0x4000

; ----------------------------------------------------------------------------
; Voice_KeyBend_Curve_0 -- 0xFDD3AB..0xFDD42A  (128 bytes)
;
; FOUR 128-byte signed per-key bend curves, stride 0x80.  This one is curve 0.
;
; ★ STRUCTURE PROVEN BY prom_c's OWN CODE, not by the sibling.  At 0xFA8016:
;       ld BC,DE / sra 0x08,BC        ; index = pitch accumulator >> 8
;       exts XBC / add XBC,0x00FDD3AB ; this table
;       ld A,(XBC) / exts WA          ; entry is a SIGNED byte
;       add DE,WA                     ; added into the pitch accumulator
; and again at 0xFA8032 with `add XBC,0x00000080` first -- i.e. curve 1 at
; 0xFDD42B.  The 0x80 stride and the signed read are both read off that code.
;
; ★ CURVES 0 AND 1 ARE THE KN5000's TWO s16 BEND TABLES, NARROWED TO 8 BITS.
; Curve 0 == low byte of Voice_KeyBend_Type41_Table (v142/subcpu/subcpu_data_tables.s:966), 128/128 entries.
; Curve 1 == low byte of Voice_KeyBend_Type42_Table (v142/subcpu/subcpu_data_tables.s:989), 128/128 entries.
; That is not a coincidence available to chance: the KN5000 curves span -50..+168,
; so their low bytes are only a smooth sequence if the curve really is the same one.
;
; ⚠ CONSEQUENCE, STATED AS OBSERVED AND NOT EXPLAINED.  The KN5000 curve rises to
; +168; eight bits cannot hold that, and prom_c sign-extends what it reads.  So the
; top of this curve reads back NEGATIVE here (0xA8 -> -88) where the KN5000 reads
; +168.  Whether the WSA1 simply never indexes that far, or this is a narrowing bug,
; is NOT ESTABLISHED -- it needs the caller of 0xFA8016 traced.
; ----------------------------------------------------------------------------
Voice_KeyBend_Curve_0:
	.byte	0xd4, 0xd4, 0xd4, 0xd4, 0xd4, 0xd4, 0xd4, 0xd4, 0xd4, 0xd4, 0xd4, 0xd4, 0xd4, 0xd4, 0xd4, 0xd4
	.byte	0xd4, 0xd4, 0xd4, 0xd4, 0xd4, 0xd4, 0xd4, 0xd6, 0xdc, 0xe0, 0xde, 0xe2, 0xe2, 0xea, 0xec, 0xec
	.byte	0xee, 0xec, 0xf4, 0xee, 0xee, 0xee, 0xf0, 0xee, 0xf2, 0xf4, 0xf6, 0xf6, 0xf6, 0xf6, 0xf8, 0xf8
	.byte	0xfa, 0xf6, 0xf6, 0xfa, 0xfa, 0xfc, 0xfc, 0xfc, 0xfc, 0xfc, 0xfe, 0xfe, 0xfc, 0xfc, 0xfc, 0xfe
	.byte	0xfe, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x02, 0x06, 0x04, 0x06, 0x06, 0x06, 0x08, 0x08, 0x0a
	.byte	0x0a, 0x08, 0x06, 0x0a, 0x0c, 0x0c, 0x0c, 0x0e, 0x0c, 0x0e, 0x0c, 0x0e, 0x10, 0x12, 0x12, 0x14
	.byte	0x1c, 0x1c, 0x28, 0x26, 0x24, 0x26, 0x26, 0x34, 0x3c, 0x3c, 0x40, 0x54, 0x56, 0x5c, 0x62, 0x6a
	.byte	0x72, 0x76, 0x7e, 0x86, 0x8c, 0x96, 0x9e, 0xa8, 0xa8, 0xa8, 0xa8, 0xa8, 0xa8, 0xa8, 0xa8, 0xa8

; ----------------------------------------------------------------------------
; Voice_KeyBend_Curve_1 -- 0xFDD42B..0xFDD4AA  (128 bytes)
;
; Bend curve 1.  Reached as Voice_KeyBend_Curve_0 + 0x80 (0xFA8032), never by a
; literal address -- which is why it has no reference of its own in the scan.
; Byte-identical to the low half of the KN5000's Voice_KeyBend_Type42_Table.
; ----------------------------------------------------------------------------
Voice_KeyBend_Curve_1:
	.byte	0xce, 0xce, 0xcf, 0xd0, 0xd0, 0xd1, 0xd2, 0xd3, 0xd3, 0xd4, 0xd5, 0xd6, 0xd6, 0xd7, 0xd8, 0xd9
	.byte	0xd9, 0xda, 0xdb, 0xdb, 0xdc, 0xdd, 0xde, 0xde, 0xdf, 0xe0, 0xe1, 0xe1, 0xe2, 0xe3, 0xe3, 0xe4
	.byte	0xe5, 0xe6, 0xe6, 0xe7, 0xe8, 0xe9, 0xe9, 0xea, 0xeb, 0xec, 0xec, 0xed, 0xee, 0xee, 0xef, 0xf0
	.byte	0xf1, 0xf1, 0xf2, 0xf3, 0xf4, 0xf4, 0xf5, 0xf6, 0xf6, 0xf7, 0xf8, 0xf9, 0xf9, 0xfa, 0xfb, 0xfc
	.byte	0xfc, 0xfd, 0xfe, 0xff, 0xff, 0x00, 0x01, 0x01, 0x02, 0x03, 0x04, 0x04, 0x05, 0x06, 0x07, 0x07
	.byte	0x08, 0x09, 0x0a, 0x0a, 0x0b, 0x0c, 0x0c, 0x0d, 0x0e, 0x0f, 0x0f, 0x10, 0x11, 0x12, 0x12, 0x13
	.byte	0x14, 0x14, 0x15, 0x16, 0x17, 0x17, 0x18, 0x19, 0x1a, 0x1a, 0x1b, 0x1c, 0x1d, 0x1d, 0x1e, 0x1f
	.byte	0x1f, 0x20, 0x21, 0x22, 0x22, 0x23, 0x24, 0x25, 0x25, 0x26, 0x27, 0x27, 0x28, 0x29, 0x2a, 0x2a

; ----------------------------------------------------------------------------
; Voice_KeyBend_Curve_2 -- 0xFDD4AB..0xFDD52A  (128 bytes)
;
; Bend curve 2.  NO counterpart in the KN5000 payload -- WSA1-only data.
; Same shape family as curves 0 and 1: a flat run at the bottom of the keyboard
; (0xEA here) and then per-key values.  Unlike curves 0/1 the body is not smooth;
; it reads like measured per-key tuning rather than a generated curve.
; Which of the four curves a voice selects is NOT YET TRACED.
; ----------------------------------------------------------------------------
Voice_KeyBend_Curve_2:
	.byte	0xea, 0xea, 0xea, 0xea, 0xea, 0xea, 0xea, 0xea, 0xea, 0xea, 0xea, 0xea, 0xea, 0xea, 0xea, 0xea
	.byte	0xea, 0xea, 0xea, 0xea, 0xea, 0xe6, 0xed, 0xec, 0xe7, 0xea, 0xea, 0xe7, 0xf4, 0xf0, 0xf2, 0xf1
	.byte	0xf2, 0xf5, 0xf7, 0xf9, 0xff, 0xfd, 0xfd, 0xf9, 0xf3, 0xf0, 0xf0, 0xf1, 0xf9, 0xf6, 0xf2, 0xfa
	.byte	0xfe, 0xfe, 0xfc, 0x00, 0xfb, 0xfb, 0xfd, 0xfc, 0xfa, 0xf7, 0xfa, 0xf8, 0xf9, 0xfc, 0x00, 0x03
	.byte	0x03, 0x06, 0xfe, 0x02, 0x03, 0x00, 0xfc, 0xfb, 0x02, 0x03, 0x01, 0x04, 0x05, 0x08, 0x07, 0x06
	.byte	0x07, 0x0c, 0x0a, 0x0a, 0x06, 0x07, 0x0a, 0x0a, 0x0d, 0x10, 0x0e, 0x10, 0x23, 0x1e, 0x21, 0x20
	.byte	0x2d, 0x2c, 0x46, 0x2e, 0x33, 0x31, 0x2d, 0x38, 0x31, 0x38, 0x30, 0x32, 0x34, 0x34, 0x34, 0x34
	.byte	0x34, 0x34, 0x34, 0x34, 0x34, 0x34, 0x34, 0x34, 0x34, 0x34, 0x34, 0x34, 0x34, 0x34, 0x34, 0x34

; ----------------------------------------------------------------------------
; Voice_KeyBend_Curve_3 -- 0xFDD52B..0xFDD5AA  (128 bytes)
;
; Bend curve 3.  NO counterpart in the KN5000 payload -- WSA1-only data.
; Flat 0xE4 at the bottom, then a non-smooth body, same as curve 2.
; ----------------------------------------------------------------------------
Voice_KeyBend_Curve_3:
	.byte	0xe4, 0xe4, 0xe4, 0xe4, 0xe4, 0xe4, 0xe4, 0xe4, 0xe4, 0xe4, 0xe4, 0xe4, 0xe4, 0xe4, 0xe4, 0xe4
	.byte	0xe4, 0xe4, 0xe4, 0xe4, 0xe4, 0xe4, 0xe6, 0xe8, 0xed, 0xf1, 0xf1, 0xec, 0xf4, 0xf5, 0xf8, 0xf5
	.byte	0xf5, 0xf4, 0xfa, 0xf8, 0xf8, 0xf6, 0xf9, 0xf9, 0xf0, 0xf3, 0xfb, 0xfc, 0xff, 0xfd, 0x04, 0x04
	.byte	0xfb, 0xfb, 0xfb, 0xfe, 0xfc, 0xfe, 0xfb, 0xfc, 0xfd, 0xfe, 0xfe, 0xff, 0xfe, 0xfc, 0xfd, 0xfe
	.byte	0x00, 0x00, 0x00, 0x01, 0x03, 0x04, 0x05, 0x06, 0x05, 0x04, 0xff, 0x01, 0xff, 0xfe, 0xfa, 0x00
	.byte	0x07, 0x0a, 0x07, 0x08, 0x08, 0x08, 0x06, 0x08, 0x07, 0x06, 0x08, 0x09, 0x0b, 0x0a, 0x0b, 0x0b
	.byte	0x0a, 0x06, 0x0a, 0x0b, 0x0a, 0x08, 0x09, 0x0b, 0x0b, 0x0e, 0x09, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c
	.byte	0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c

; ----------------------------------------------------------------------------
; Voice_DepthMirror_Table -- 0xFDD5AB..0xFDD62A  (128 bytes)
;
; 128 bytes, the exact mirror i -> 0x7F - i.  Byte-identical to the KN5000 table
; of this name (v142/subcpu/subcpu_data_tables.s:1010), where two users are documented: negative pitch-bend
; depths are re-mapped through it, and the normal note mapping feeds table[note]
; into the colour lookup.  Referenced here from 0xFA75D4, 0xFAB5DB, 0xFAB6FD.
; Sibling: kn5000 sub-CPU 0x00FEE4, v142/subcpu/subcpu_data_tables.s:1010
; ----------------------------------------------------------------------------
Voice_DepthMirror_Table:
	.byte	0x7f, 0x7e, 0x7d, 0x7c, 0x7b, 0x7a, 0x79, 0x78, 0x77, 0x76, 0x75, 0x74, 0x73, 0x72, 0x71, 0x70
	.byte	0x6f, 0x6e, 0x6d, 0x6c, 0x6b, 0x6a, 0x69, 0x68, 0x67, 0x66, 0x65, 0x64, 0x63, 0x62, 0x61, 0x60
	.byte	0x5f, 0x5e, 0x5d, 0x5c, 0x5b, 0x5a, 0x59, 0x58, 0x57, 0x56, 0x55, 0x54, 0x53, 0x52, 0x51, 0x50
	.byte	0x4f, 0x4e, 0x4d, 0x4c, 0x4b, 0x4a, 0x49, 0x48, 0x47, 0x46, 0x45, 0x44, 0x43, 0x42, 0x41, 0x40
	.byte	0x3f, 0x3e, 0x3d, 0x3c, 0x3b, 0x3a, 0x39, 0x38, 0x37, 0x36, 0x35, 0x34, 0x33, 0x32, 0x31, 0x30
	.byte	0x2f, 0x2e, 0x2d, 0x2c, 0x2b, 0x2a, 0x29, 0x28, 0x27, 0x26, 0x25, 0x24, 0x23, 0x22, 0x21, 0x20
	.byte	0x1f, 0x1e, 0x1d, 0x1c, 0x1b, 0x1a, 0x19, 0x18, 0x17, 0x16, 0x15, 0x14, 0x13, 0x12, 0x11, 0x10
	.byte	0x0f, 0x0e, 0x0d, 0x0c, 0x0b, 0x0a, 0x09, 0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0x00

; ----------------------------------------------------------------------------
; PitchBend_ScaleCoeff_Table -- 0xFDD62B..0xFDD6AA  (128 bytes)
;
; 128 bytes, a signed coefficient (0xC0..0xFF then 0x00) multiplied by the bend
; depth and then right-shifted -- a slow-start magnitude curve.  Referenced from
; 0xFA75EC.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1032.
; Sibling: kn5000 sub-CPU 0x00FF64, v142/subcpu/subcpu_data_tables.s:1032
; ----------------------------------------------------------------------------
PitchBend_ScaleCoeff_Table:
	.byte	0xc0, 0xc1, 0xc1, 0xc1, 0xc1, 0xc2, 0xc2, 0xc2, 0xc2, 0xc3, 0xc3, 0xc3, 0xc3, 0xc4, 0xc4, 0xc4
	.byte	0xc4, 0xc5, 0xc5, 0xc5, 0xc5, 0xc6, 0xc6, 0xc6, 0xc6, 0xc7, 0xc7, 0xc7, 0xc7, 0xc8, 0xc8, 0xc8
	.byte	0xc8, 0xc9, 0xc9, 0xc9, 0xc9, 0xca, 0xca, 0xca, 0xca, 0xcb, 0xcb, 0xcb, 0xcb, 0xcc, 0xcc, 0xcc
	.byte	0xcc, 0xcd, 0xcd, 0xcd, 0xcd, 0xce, 0xce, 0xce, 0xce, 0xcf, 0xcf, 0xcf, 0xcf, 0xd0, 0xd0, 0xd0
	.byte	0xd0, 0xd1, 0xd1, 0xd2, 0xd2, 0xd3, 0xd3, 0xd4, 0xd4, 0xd5, 0xd5, 0xd6, 0xd6, 0xd7, 0xd7, 0xd8
	.byte	0xd8, 0xd9, 0xd9, 0xda, 0xda, 0xdb, 0xdb, 0xdc, 0xdc, 0xdd, 0xdd, 0xde, 0xde, 0xdf, 0xdf, 0xe0
	.byte	0xe0, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef, 0xf0
	.byte	0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff, 0x00

; ----------------------------------------------------------------------------
; Voice_Colour_TransferCurves -- 0xFDD6AB..0xFDDDAA  (1792 bytes)
;
; 7 rows x 256 bytes.  Byte [(group << 8) + row], where the row index comes from
; Voice_Colour_RowOffset_Table below.  Each row is a monotone 0x00..0xFF transfer
; curve and higher groups bow it harder -- a brightness/colour response.
; Referenced from 0xFA7CF7.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1058.
; ⚠ The sibling notes the group selector is 3 bits but only 7 rows exist; row 7
; would run into the table that follows.  The same is true here.
; Sibling: kn5000 sub-CPU 0x00FFE4, v142/subcpu/subcpu_data_tables.s:1058
; ----------------------------------------------------------------------------
Voice_Colour_TransferCurves:
	; group 0
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0b, 0x0c, 0x0d
	.byte	0x0e, 0x0f, 0x10, 0x11, 0x12, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x19, 0x1a, 0x1b
	.byte	0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x27, 0x28, 0x29
	.byte	0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2e, 0x2f, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x35, 0x36, 0x37
	.byte	0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3c, 0x3d, 0x3e, 0x3f, 0x40, 0x41, 0x42, 0x43, 0x43, 0x44, 0x45
	.byte	0x46, 0x47, 0x48, 0x49, 0x4a, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x50, 0x51, 0x51, 0x52, 0x53
	.byte	0x54, 0x55, 0x56, 0x57, 0x58, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f, 0x5f, 0x60, 0x61
	.byte	0x62, 0x63, 0x64, 0x65, 0x66, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6d, 0x6e, 0x6f
	.byte	0x70, 0x71, 0x72, 0x73, 0x74, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7b, 0x7c, 0x7d
	.byte	0x7e, 0x7f, 0x80, 0x81, 0x82, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x89, 0x8a, 0x8b
	.byte	0x8c, 0x8d, 0x8e, 0x8f, 0x90, 0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x97, 0x98, 0x99
	.byte	0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9e, 0x9f, 0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa5, 0xa6, 0xa7
	.byte	0xa8, 0xa9, 0xab, 0xac, 0xae, 0xaf, 0xb0, 0xb2, 0xb3, 0xb4, 0xb6, 0xb7, 0xb9, 0xba, 0xbb, 0xbd
	.byte	0xbe, 0xbf, 0xc1, 0xc2, 0xc4, 0xc5, 0xc6, 0xc8, 0xc9, 0xcb, 0xcc, 0xcd, 0xcf, 0xd0, 0xd1, 0xd3
	.byte	0xd4, 0xd6, 0xd7, 0xd8, 0xda, 0xdb, 0xdc, 0xde, 0xdf, 0xe1, 0xe2, 0xe3, 0xe5, 0xe6, 0xe8, 0xe9
	.byte	0xea, 0xec, 0xed, 0xee, 0xf0, 0xf1, 0xf3, 0xf4, 0xf5, 0xf7, 0xf8, 0xf9, 0xfb, 0xfc, 0xfe, 0xff
	; group 1
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e
	.byte	0x0f, 0x10, 0x11, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1c
	.byte	0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x27, 0x28, 0x29, 0x2a, 0x2b
	.byte	0x2c, 0x2d, 0x2e, 0x2f, 0x30, 0x31, 0x32, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a
	.byte	0x3b, 0x3c, 0x3d, 0x3d, 0x3e, 0x3f, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x48
	.byte	0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x50, 0x51, 0x52, 0x53, 0x53, 0x54, 0x55, 0x56, 0x57
	.byte	0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5e, 0x5f, 0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66
	.byte	0x67, 0x68, 0x69, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f, 0x70, 0x71, 0x72, 0x73, 0x74, 0x74
	.byte	0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f, 0x7f, 0x80, 0x81, 0x82, 0x83
	.byte	0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f, 0x90, 0x91, 0x92
	.byte	0x93, 0x94, 0x95, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f, 0xa0, 0xa0
	.byte	0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xab, 0xab, 0xac, 0xad, 0xae, 0xaf
	.byte	0xb0, 0xb1, 0xb3, 0xb4, 0xb5, 0xb6, 0xb8, 0xb9, 0xba, 0xbb, 0xbd, 0xbe, 0xbf, 0xc0, 0xc2, 0xc3
	.byte	0xc4, 0xc5, 0xc7, 0xc8, 0xc9, 0xca, 0xcc, 0xcd, 0xce, 0xcf, 0xd1, 0xd2, 0xd3, 0xd4, 0xd6, 0xd7
	.byte	0xd8, 0xd9, 0xdb, 0xdc, 0xdd, 0xde, 0xe0, 0xe1, 0xe2, 0xe3, 0xe5, 0xe6, 0xe7, 0xe8, 0xea, 0xeb
	.byte	0xec, 0xed, 0xef, 0xf0, 0xf1, 0xf2, 0xf4, 0xf5, 0xf6, 0xf7, 0xf9, 0xfa, 0xfb, 0xfc, 0xfe, 0xff
	; group 2
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0c, 0x0d, 0x0e
	.byte	0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e
	.byte	0x1f, 0x20, 0x21, 0x22, 0x23, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d
	.byte	0x2e, 0x2f, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3a, 0x3b, 0x3c
	.byte	0x3d, 0x3e, 0x3f, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c
	.byte	0x4d, 0x4e, 0x4f, 0x50, 0x51, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b
	.byte	0x5c, 0x5d, 0x5e, 0x5f, 0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x68, 0x69, 0x6a
	.byte	0x6b, 0x6c, 0x6d, 0x6e, 0x6f, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a
	.byte	0x7b, 0x7c, 0x7d, 0x7e, 0x7f, 0x7f, 0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89
	.byte	0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f, 0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x96, 0x97, 0x98
	.byte	0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f, 0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8
	.byte	0xa9, 0xaa, 0xab, 0xac, 0xad, 0xad, 0xae, 0xaf, 0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7
	.byte	0xb8, 0xb9, 0xba, 0xbb, 0xbd, 0xbe, 0xbf, 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc6, 0xc7, 0xc8, 0xc9
	.byte	0xca, 0xcb, 0xcc, 0xcd, 0xcf, 0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd8, 0xd9, 0xda, 0xdb
	.byte	0xdc, 0xdd, 0xde, 0xdf, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xea, 0xeb, 0xec, 0xed
	.byte	0xee, 0xef, 0xf0, 0xf1, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfc, 0xfd, 0xfe, 0xff
	; group 3
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
	.byte	0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f
	.byte	0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f
	.byte	0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f
	.byte	0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f
	.byte	0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f
	.byte	0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f
	.byte	0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f
	.byte	0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f
	.byte	0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f
	.byte	0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf
	.byte	0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf
	.byte	0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf
	.byte	0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf
	.byte	0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef
	.byte	0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff
	; group 4
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0d, 0x0e, 0x0f, 0x10
	.byte	0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20
	.byte	0x21, 0x22, 0x23, 0x24, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x30, 0x31
	.byte	0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x40, 0x41, 0x42
	.byte	0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x50, 0x51, 0x52
	.byte	0x53, 0x54, 0x55, 0x56, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f, 0x60, 0x61, 0x62, 0x63
	.byte	0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f, 0x70, 0x72, 0x73, 0x74
	.byte	0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f, 0x80, 0x81, 0x82, 0x83, 0x84
	.byte	0x85, 0x86, 0x87, 0x88, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f, 0x90, 0x91, 0x92, 0x93, 0x94, 0x95
	.byte	0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f, 0xa0, 0xa1, 0xa3, 0xa4, 0xa5, 0xa6
	.byte	0xa7, 0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf, 0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6
	.byte	0xb7, 0xb8, 0xb9, 0xba, 0xbc, 0xbd, 0xbe, 0xbf, 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7
	.byte	0xc8, 0xc9, 0xca, 0xcb, 0xcb, 0xcc, 0xcd, 0xce, 0xcf, 0xd0, 0xd1, 0xd2, 0xd2, 0xd3, 0xd4, 0xd5
	.byte	0xd6, 0xd7, 0xd8, 0xd9, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf, 0xe0, 0xe0, 0xe1, 0xe2, 0xe3
	.byte	0xe4, 0xe5, 0xe6, 0xe7, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xee, 0xef, 0xf0, 0xf1
	.byte	0xf2, 0xf3, 0xf4, 0xf5, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfc, 0xfd, 0xfe, 0xff
	; group 5
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10
	.byte	0x11, 0x12, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x21, 0x22
	.byte	0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2e, 0x2f, 0x30, 0x31, 0x32, 0x33
	.byte	0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f, 0x40, 0x41, 0x42, 0x43, 0x44
	.byte	0x45, 0x46, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x50, 0x51, 0x52, 0x53, 0x55, 0x56
	.byte	0x57, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f, 0x60, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67
	.byte	0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6f, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78
	.byte	0x79, 0x7a, 0x7c, 0x7d, 0x7e, 0x7f, 0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x89, 0x8a
	.byte	0x8b, 0x8c, 0x8d, 0x8e, 0x8f, 0x90, 0x91, 0x92, 0x93, 0x94, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b
	.byte	0x9c, 0x9d, 0x9e, 0x9f, 0xa0, 0xa1, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xab, 0xac
	.byte	0xad, 0xae, 0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xbb, 0xbd, 0xbe
	.byte	0xbf, 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf
	.byte	0xd0, 0xd1, 0xd1, 0xd2, 0xd3, 0xd4, 0xd4, 0xd5, 0xd6, 0xd7, 0xd7, 0xd8, 0xd9, 0xda, 0xda, 0xdb
	.byte	0xdc, 0xdd, 0xdd, 0xde, 0xdf, 0xe0, 0xe0, 0xe1, 0xe2, 0xe3, 0xe3, 0xe4, 0xe5, 0xe6, 0xe6, 0xe7
	.byte	0xe8, 0xe9, 0xe9, 0xea, 0xeb, 0xec, 0xec, 0xed, 0xee, 0xef, 0xef, 0xf0, 0xf1, 0xf2, 0xf2, 0xf3
	.byte	0xf4, 0xf5, 0xf5, 0xf6, 0xf7, 0xf8, 0xf8, 0xf9, 0xfa, 0xfb, 0xfb, 0xfc, 0xfd, 0xfe, 0xfe, 0xff
	; group 6
	.byte	0x00, 0x01, 0x02, 0x03, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0e, 0x0f, 0x10, 0x11
	.byte	0x12, 0x13, 0x14, 0x15, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x20, 0x21, 0x22, 0x23
	.byte	0x24, 0x25, 0x26, 0x27, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x30, 0x32, 0x33, 0x34, 0x35
	.byte	0x36, 0x37, 0x38, 0x39, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f, 0x40, 0x41, 0x42, 0x44, 0x45, 0x46, 0x47
	.byte	0x48, 0x49, 0x4a, 0x4b, 0x4d, 0x4e, 0x4f, 0x50, 0x51, 0x52, 0x53, 0x54, 0x56, 0x57, 0x58, 0x59
	.byte	0x5a, 0x5b, 0x5c, 0x5d, 0x5f, 0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x68, 0x69, 0x6a, 0x6b
	.byte	0x6c, 0x6d, 0x6e, 0x6f, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x7a, 0x7b, 0x7c, 0x7d
	.byte	0x7e, 0x7f, 0x80, 0x81, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8c, 0x8d, 0x8e, 0x8f
	.byte	0x90, 0x91, 0x92, 0x93, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9e, 0x9f, 0xa0, 0xa1
	.byte	0xa2, 0xa3, 0xa4, 0xa5, 0xa7, 0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xb0, 0xb1, 0xb2, 0xb3
	.byte	0xb4, 0xb5, 0xb6, 0xb7, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf, 0xc0, 0xc2, 0xc3, 0xc4, 0xc5
	.byte	0xc6, 0xc7, 0xc8, 0xc9, 0xcb, 0xcc, 0xcd, 0xce, 0xcf, 0xd0, 0xd1, 0xd2, 0xd4, 0xd5, 0xd6, 0xd7
	.byte	0xd8, 0xd9, 0xd9, 0xda, 0xda, 0xdb, 0xdc, 0xdc, 0xdd, 0xde, 0xde, 0xdf, 0xdf, 0xe0, 0xe1, 0xe1
	.byte	0xe2, 0xe3, 0xe3, 0xe4, 0xe4, 0xe5, 0xe6, 0xe6, 0xe7, 0xe7, 0xe8, 0xe9, 0xe9, 0xea, 0xeb, 0xeb
	.byte	0xec, 0xec, 0xed, 0xee, 0xee, 0xef, 0xf0, 0xf0, 0xf1, 0xf1, 0xf2, 0xf3, 0xf3, 0xf4, 0xf4, 0xf5
	.byte	0xf6, 0xf6, 0xf7, 0xf8, 0xf8, 0xf9, 0xf9, 0xfa, 0xfb, 0xfb, 0xfc, 0xfd, 0xfd, 0xfe, 0xfe, 0xff

; ----------------------------------------------------------------------------
; Voice_Colour_RowOffset_Table -- 0xFDDDAB..0xFDDE2A  (128 bytes)
;
; 128 bytes.  First stage of the colour lookup: row = table[control value], then
; the byte at Voice_Colour_TransferCurves[(group << 8) + row] is the answer.
; Referenced from 0xFA7CE6.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1296.
; Sibling: kn5000 sub-CPU 0x0106E4, v142/subcpu/subcpu_data_tables.s:1296
; ----------------------------------------------------------------------------
Voice_Colour_RowOffset_Table:
	.byte	0x01, 0x5b, 0x5f, 0x62, 0x66, 0x6a, 0x6d, 0x71, 0x75, 0x78, 0x7c, 0x7f, 0x83, 0x87, 0x8a, 0x8e
	.byte	0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f
	.byte	0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf
	.byte	0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf
	.byte	0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf
	.byte	0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf
	.byte	0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef
	.byte	0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff

; ----------------------------------------------------------------------------
; Voice_OutputLevel_Table -- 0xFDDE2B..0xFDE02A  (512 bytes)
;
; 256 u16, monotone 0x0000..0x07FA.  Output-level curve; the sibling records that
; the index is a clamped byte and the result is doubled again by the caller.
; Referenced from 0xFA7DD3 and 0xFAC32C.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1317.
; Sibling: kn5000 sub-CPU 0x010764, v142/subcpu/subcpu_data_tables.s:1317
; ----------------------------------------------------------------------------
Voice_OutputLevel_Table:
	.short	0x0000, 0x000b, 0x0016, 0x0020, 0x0029, 0x0032, 0x003b, 0x0043
	.short	0x004b, 0x0052, 0x005a, 0x0061, 0x0067, 0x006e, 0x0074, 0x007a
	.short	0x0080, 0x008b, 0x0096, 0x00a0, 0x00a9, 0x00b2, 0x00bb, 0x00c3
	.short	0x00cb, 0x00d2, 0x00da, 0x00e1, 0x00e7, 0x00ee, 0x00f4, 0x00fa
	.short	0x0100, 0x010b, 0x0116, 0x0120, 0x0129, 0x0132, 0x013b, 0x0143
	.short	0x014b, 0x0152, 0x015a, 0x0161, 0x0167, 0x016e, 0x0174, 0x017a
	.short	0x0180, 0x018b, 0x0196, 0x01a0, 0x01a9, 0x01b2, 0x01bb, 0x01c3
	.short	0x01cb, 0x01d2, 0x01da, 0x01e1, 0x01e7, 0x01ee, 0x01f4, 0x01fa
	.short	0x0200, 0x020b, 0x0216, 0x0220, 0x0229, 0x0232, 0x023b, 0x0243
	.short	0x024b, 0x0252, 0x025a, 0x0261, 0x0267, 0x026e, 0x0274, 0x027a
	.short	0x0280, 0x028b, 0x0296, 0x02a0, 0x02a9, 0x02b2, 0x02bb, 0x02c3
	.short	0x02cb, 0x02d2, 0x02da, 0x02e1, 0x02e7, 0x02ee, 0x02f4, 0x02fa
	.short	0x0300, 0x030b, 0x0316, 0x0320, 0x0329, 0x0332, 0x033b, 0x0343
	.short	0x034b, 0x0352, 0x035a, 0x0361, 0x0367, 0x036e, 0x0374, 0x037a
	.short	0x0380, 0x038b, 0x0396, 0x03a0, 0x03a9, 0x03b2, 0x03bb, 0x03c3
	.short	0x03cb, 0x03d2, 0x03da, 0x03e1, 0x03e7, 0x03ee, 0x03f4, 0x03fa
	.short	0x0400, 0x040b, 0x0416, 0x0420, 0x0429, 0x0432, 0x043b, 0x0443
	.short	0x044b, 0x0452, 0x045a, 0x0461, 0x0467, 0x046e, 0x0474, 0x047a
	.short	0x0480, 0x048b, 0x0496, 0x04a0, 0x04a9, 0x04b2, 0x04bb, 0x04c3
	.short	0x04cb, 0x04d2, 0x04da, 0x04e1, 0x04e7, 0x04ee, 0x04f4, 0x04fa
	.short	0x0500, 0x050b, 0x0516, 0x0520, 0x0529, 0x0532, 0x053b, 0x0543
	.short	0x054b, 0x0552, 0x055a, 0x0561, 0x0567, 0x056e, 0x0574, 0x057a
	.short	0x0580, 0x058b, 0x0596, 0x05a0, 0x05a9, 0x05b2, 0x05bb, 0x05c3
	.short	0x05cb, 0x05d2, 0x05da, 0x05e1, 0x05e7, 0x05ee, 0x05f4, 0x05fa
	.short	0x0600, 0x060b, 0x0616, 0x0620, 0x0629, 0x0632, 0x063b, 0x0643
	.short	0x064b, 0x0652, 0x065a, 0x0661, 0x0667, 0x066e, 0x0674, 0x067a
	.short	0x0680, 0x068b, 0x0696, 0x06a0, 0x06a9, 0x06b2, 0x06bb, 0x06c3
	.short	0x06cb, 0x06d2, 0x06da, 0x06e1, 0x06e7, 0x06ee, 0x06f4, 0x06fa
	.short	0x0700, 0x070b, 0x0716, 0x0720, 0x0729, 0x0732, 0x073b, 0x0743
	.short	0x074b, 0x0752, 0x075a, 0x0761, 0x0767, 0x076e, 0x0774, 0x077a
	.short	0x0780, 0x078b, 0x0796, 0x07a0, 0x07a9, 0x07b2, 0x07bb, 0x07c3
	.short	0x07cb, 0x07d2, 0x07da, 0x07e1, 0x07e7, 0x07ee, 0x07f4, 0x07fa

; ----------------------------------------------------------------------------
; EGEnv_ValueCurve_Simple -- 0xFDE02B..0xFDE12A  (256 bytes)
;
; 128 u16.  Envelope-generator VALUE curve: exponential start (0,1,2,4,8,...) and
; a linear tail to 0x3FFF.  Four references here: 0xFA7A15, 0xFA7AFB, 0xFA7C5F,
; 0xFBDC1F.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1355.
; ★ This is one of the two tables the earlier notes/kn5000-label-transplant.md got
;   right by name and wrong by address; see notes/prom_c_kn5000_xref.py.
; Sibling: kn5000 sub-CPU 0x010964, v142/subcpu/subcpu_data_tables.s:1355
; ----------------------------------------------------------------------------
EGEnv_ValueCurve_Simple:
	.short	0x0000, 0x0001, 0x0002, 0x0004, 0x0008, 0x0010, 0x0020, 0x0030
	.short	0x0040, 0x0050, 0x0060, 0x0070, 0x0080, 0x0090, 0x00a0, 0x00a8
	.short	0x00b0, 0x00b8, 0x00c0, 0x00c8, 0x00d0, 0x00d8, 0x00e0, 0x00e8
	.short	0x00f0, 0x00f8, 0x0100, 0x0108, 0x0110, 0x0118, 0x0120, 0x0128
	.short	0x0130, 0x0138, 0x0140, 0x0148, 0x0150, 0x0158, 0x0160, 0x0168
	.short	0x0170, 0x0178, 0x0180, 0x0190, 0x01a0, 0x01b0, 0x01c0, 0x01d0
	.short	0x01e0, 0x01f0, 0x0200, 0x0220, 0x0240, 0x0260, 0x0280, 0x02a0
	.short	0x02c0, 0x02e0, 0x0300, 0x0320, 0x0340, 0x0360, 0x0380, 0x03a0
	.short	0x03c0, 0x03e0, 0x0400, 0x0440, 0x0480, 0x04c0, 0x0500, 0x0540
	.short	0x0580, 0x05c0, 0x0600, 0x0640, 0x0680, 0x06c0, 0x0700, 0x0740
	.short	0x0780, 0x07c0, 0x0800, 0x0880, 0x0900, 0x0980, 0x0a00, 0x0a80
	.short	0x0b00, 0x0b80, 0x0c00, 0x0c80, 0x0d00, 0x0d80, 0x0e00, 0x0e80
	.short	0x0f00, 0x0f80, 0x1000, 0x1100, 0x1200, 0x1300, 0x1400, 0x1500
	.short	0x1600, 0x1700, 0x1800, 0x1900, 0x1a00, 0x1b00, 0x1c00, 0x1d00
	.short	0x1e00, 0x1f00, 0x2000, 0x2200, 0x2400, 0x2600, 0x2800, 0x2a00
	.short	0x2c00, 0x2e00, 0x3000, 0x3200, 0x3400, 0x3800, 0x3c00, 0x3fff

; ----------------------------------------------------------------------------
; EGEnv_BaseCurve_A -- 0xFDE12B..0xFDE22A  (256 bytes)
;
; 128 u16, 0x0000..0x1FFF, 0x10 per step then bowing.  Envelope BASE curve A.
; References: 0xFA798D, 0xFBDA8A, 0xFBDAC0.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1378.
; Sibling: kn5000 sub-CPU 0x010A64, v142/subcpu/subcpu_data_tables.s:1378
; ----------------------------------------------------------------------------
EGEnv_BaseCurve_A:
	.short	0x0000, 0x0010, 0x0020, 0x0030, 0x0040, 0x0050, 0x0060, 0x0070
	.short	0x0080, 0x0090, 0x00a0, 0x00b0, 0x00c0, 0x00d0, 0x00e0, 0x00f0
	.short	0x0100, 0x0110, 0x0120, 0x0130, 0x0140, 0x0150, 0x0160, 0x0170
	.short	0x0180, 0x0190, 0x01a0, 0x01b0, 0x01c0, 0x01d0, 0x01e0, 0x01f0
	.short	0x0200, 0x0220, 0x0240, 0x0260, 0x0280, 0x02a0, 0x02c0, 0x02e0
	.short	0x0300, 0x0320, 0x0340, 0x0360, 0x0380, 0x03a0, 0x03c0, 0x03e0
	.short	0x0400, 0x0420, 0x0440, 0x0460, 0x0480, 0x04a0, 0x04c0, 0x04e0
	.short	0x0500, 0x0520, 0x0540, 0x0560, 0x0580, 0x05a0, 0x05c0, 0x05e0
	.short	0x0600, 0x0640, 0x0680, 0x06c0, 0x0700, 0x0740, 0x0780, 0x07c0
	.short	0x0800, 0x0840, 0x0880, 0x08c0, 0x0900, 0x0940, 0x0980, 0x09c0
	.short	0x0a00, 0x0a40, 0x0a80, 0x0ac0, 0x0b00, 0x0b40, 0x0b80, 0x0bc0
	.short	0x0c00, 0x0c40, 0x0c80, 0x0cc0, 0x0d00, 0x0d40, 0x0d80, 0x0dc0
	.short	0x0e00, 0x0e80, 0x0f00, 0x0f80, 0x1000, 0x1080, 0x1100, 0x1180
	.short	0x1200, 0x1280, 0x1300, 0x1380, 0x1400, 0x1480, 0x1500, 0x1580
	.short	0x1600, 0x1680, 0x1700, 0x1780, 0x1800, 0x1880, 0x1900, 0x1980
	.short	0x1a00, 0x1a80, 0x1b00, 0x1b80, 0x1c00, 0x1d00, 0x1e00, 0x1fff

; ----------------------------------------------------------------------------
; EGEnv_BaseCurve_B -- 0xFDE22B..0xFDE32A  (256 bytes)
;
; 128 u16.  Envelope BASE curve B -- the sibling records it as a pure linear ramp
; of 0x40 per step.  References: 0xFA7A6F, 0xFBDAFB, 0xFBDB31.  Byte-identical to
; v142/subcpu/subcpu_data_tables.s:1399.
; Sibling: kn5000 sub-CPU 0x010B64, v142/subcpu/subcpu_data_tables.s:1399
; ----------------------------------------------------------------------------
EGEnv_BaseCurve_B:
	.short	0x0000, 0x0040, 0x0080, 0x00c0, 0x0100, 0x0140, 0x0180, 0x01c0
	.short	0x0200, 0x0240, 0x0280, 0x02c0, 0x0300, 0x0340, 0x0380, 0x03c0
	.short	0x0400, 0x0440, 0x0480, 0x04c0, 0x0500, 0x0540, 0x0580, 0x05c0
	.short	0x0600, 0x0640, 0x0680, 0x06c0, 0x0700, 0x0740, 0x0780, 0x07c0
	.short	0x0800, 0x0840, 0x0880, 0x08c0, 0x0900, 0x0940, 0x0980, 0x09c0
	.short	0x0a00, 0x0a40, 0x0a80, 0x0ac0, 0x0b00, 0x0b40, 0x0b80, 0x0bc0
	.short	0x0c00, 0x0c40, 0x0c80, 0x0cc0, 0x0d00, 0x0d40, 0x0d80, 0x0dc0
	.short	0x0e00, 0x0e40, 0x0e80, 0x0ec0, 0x0f00, 0x0f40, 0x0f80, 0x0fc0
	.short	0x1000, 0x1040, 0x1080, 0x10c0, 0x1100, 0x1140, 0x1180, 0x11c0
	.short	0x1200, 0x1240, 0x1280, 0x12c0, 0x1300, 0x1340, 0x1380, 0x13c0
	.short	0x1400, 0x1440, 0x1480, 0x14c0, 0x1500, 0x1540, 0x1580, 0x15c0
	.short	0x1600, 0x1640, 0x1680, 0x16c0, 0x1700, 0x1740, 0x1780, 0x17c0
	.short	0x1800, 0x1840, 0x1880, 0x18c0, 0x1900, 0x1940, 0x1980, 0x19c0
	.short	0x1a00, 0x1a40, 0x1a80, 0x1ac0, 0x1b00, 0x1b40, 0x1b80, 0x1bc0
	.short	0x1c00, 0x1c40, 0x1c80, 0x1cc0, 0x1d00, 0x1d40, 0x1d80, 0x1dc0
	.short	0x1e00, 0x1e40, 0x1e80, 0x1ec0, 0x1f00, 0x1f40, 0x1f80, 0x1fc0

; ----------------------------------------------------------------------------
; Voice_FreqWrite_BaseCurve -- 0xFDE32B..0xFDE42A  (256 bytes)
;
; 128 u16, the same 0x40-per-step ramp as EGEnv_BaseCurve_B but a separate object
; because the code addresses it independently -- and it does so here too:
; 0xFA7B5D, 0xFA7BD0, 0xFBDB6C, 0xFBDBA2.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1420.
; Sibling: kn5000 sub-CPU 0x010C64, v142/subcpu/subcpu_data_tables.s:1420
; ----------------------------------------------------------------------------
Voice_FreqWrite_BaseCurve:
	.short	0x0000, 0x0040, 0x0080, 0x00c0, 0x0100, 0x0140, 0x0180, 0x01c0
	.short	0x0200, 0x0240, 0x0280, 0x02c0, 0x0300, 0x0340, 0x0380, 0x03c0
	.short	0x0400, 0x0440, 0x0480, 0x04c0, 0x0500, 0x0540, 0x0580, 0x05c0
	.short	0x0600, 0x0640, 0x0680, 0x06c0, 0x0700, 0x0740, 0x0780, 0x07c0
	.short	0x0800, 0x0840, 0x0880, 0x08c0, 0x0900, 0x0940, 0x0980, 0x09c0
	.short	0x0a00, 0x0a40, 0x0a80, 0x0ac0, 0x0b00, 0x0b40, 0x0b80, 0x0bc0
	.short	0x0c00, 0x0c40, 0x0c80, 0x0cc0, 0x0d00, 0x0d40, 0x0d80, 0x0dc0
	.short	0x0e00, 0x0e40, 0x0e80, 0x0ec0, 0x0f00, 0x0f40, 0x0f80, 0x0fc0
	.short	0x1000, 0x1040, 0x1080, 0x10c0, 0x1100, 0x1140, 0x1180, 0x11c0
	.short	0x1200, 0x1240, 0x1280, 0x12c0, 0x1300, 0x1340, 0x1380, 0x13c0
	.short	0x1400, 0x1440, 0x1480, 0x14c0, 0x1500, 0x1540, 0x1580, 0x15c0
	.short	0x1600, 0x1640, 0x1680, 0x16c0, 0x1700, 0x1740, 0x1780, 0x17c0
	.short	0x1800, 0x1840, 0x1880, 0x18c0, 0x1900, 0x1940, 0x1980, 0x19c0
	.short	0x1a00, 0x1a40, 0x1a80, 0x1ac0, 0x1b00, 0x1b40, 0x1b80, 0x1bc0
	.short	0x1c00, 0x1c40, 0x1c80, 0x1cc0, 0x1d00, 0x1d40, 0x1d80, 0x1dc0
	.short	0x1e00, 0x1e40, 0x1e80, 0x1ec0, 0x1f00, 0x1f40, 0x1f80, 0x1fc0

; ----------------------------------------------------------------------------
; Voice_ToneRampPitch_Curve -- 0xFDE42B..0xFDE47A  (80 bytes)
;
; 80 bytes, an ease-out curve 0x00..0xFF indexed by the pitch ramp position.
; References: 0xFAC829, 0xFAC92A, 0xFAC955, 0xFAC9D8.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1442.
; Sibling: kn5000 sub-CPU 0x010D64, v142/subcpu/subcpu_data_tables.s:1442
; ----------------------------------------------------------------------------
Voice_ToneRampPitch_Curve:
	.byte	0x00, 0x04, 0x09, 0x0e, 0x14, 0x1a, 0x1f, 0x26, 0x2b, 0x32, 0x39, 0x40, 0x46, 0x4d, 0x54, 0x5b
	.byte	0x62, 0x6b, 0x72, 0x78, 0x7e, 0x84, 0x8c, 0x92, 0x98, 0x9d, 0xa2, 0xa8, 0xac, 0xb1, 0xb5, 0xba
	.byte	0xbe, 0xc2, 0xc6, 0xca, 0xce, 0xd1, 0xd3, 0xd6, 0xd8, 0xdb, 0xde, 0xe1, 0xe3, 0xe5, 0xe7, 0xe9
	.byte	0xea, 0xeb, 0xed, 0xee, 0xef, 0xf0, 0xf1, 0xf2, 0xf2, 0xf3, 0xf4, 0xf5, 0xf5, 0xf6, 0xf7, 0xf7
	.byte	0xf8, 0xf8, 0xf9, 0xf9, 0xfa, 0xfa, 0xfb, 0xfb, 0xfc, 0xfc, 0xfd, 0xfd, 0xfe, 0xfe, 0xff, 0xff

; ----------------------------------------------------------------------------
; Voice_ToneRampFilter_Curve -- 0xFDE47B..0xFDE494  (26 bytes)
;
; 26 bytes, a linear 0x00..0xFF filter-ramp curve.  References: 0xFAC867,
; 0xFAC93A, 0xFAC97D, 0xFAC9C5, and four 24-bit forms.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1457.
; ⚠ The sibling documents a shipped quirk: two of its indexing paths run past 26
; entries into the next table.  Not re-checked for the WSA1 readers.
; Sibling: kn5000 sub-CPU 0x010DB4, v142/subcpu/subcpu_data_tables.s:1457
; ----------------------------------------------------------------------------
Voice_ToneRampFilter_Curve:
	.byte	0x00, 0x0a, 0x14, 0x1e, 0x29, 0x33, 0x3d, 0x47, 0x52, 0x5c, 0x66, 0x70, 0x7b, 0x85, 0x8f, 0x99
	.byte	0xa4, 0xae, 0xb8, 0xc2, 0xcd, 0xd7, 0xe1, 0xeb, 0xf6, 0xff

; ----------------------------------------------------------------------------
; Voice_PitchDepth_Scale -- 0xFDE495..0xFDE594  (256 bytes)
;
; 256 bytes, a slow-rising 0x20..0xF8 scale curve (pitch half of the output-list
; build in the sibling).  Referenced from 0xFAC4B5.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1469.
; Sibling: kn5000 sub-CPU 0x010DCE, v142/subcpu/subcpu_data_tables.s:1469
; ----------------------------------------------------------------------------
Voice_PitchDepth_Scale:
	.byte	0x20, 0x20, 0x20, 0x20, 0x21, 0x21, 0x21, 0x21, 0x22, 0x22, 0x22, 0x22, 0x23, 0x23, 0x23, 0x23
	.byte	0x24, 0x24, 0x24, 0x24, 0x25, 0x25, 0x25, 0x25, 0x26, 0x26, 0x26, 0x26, 0x27, 0x27, 0x27, 0x27
	.byte	0x28, 0x28, 0x28, 0x28, 0x29, 0x29, 0x29, 0x29, 0x2a, 0x2a, 0x2a, 0x2a, 0x2b, 0x2b, 0x2b, 0x2b
	.byte	0x2c, 0x2c, 0x2c, 0x2c, 0x2d, 0x2d, 0x2d, 0x2d, 0x2e, 0x2e, 0x2e, 0x2e, 0x2f, 0x2f, 0x2f, 0x2f
	.byte	0x30, 0x30, 0x30, 0x30, 0x31, 0x31, 0x31, 0x31, 0x32, 0x32, 0x32, 0x32, 0x33, 0x33, 0x33, 0x33
	.byte	0x34, 0x34, 0x34, 0x34, 0x35, 0x35, 0x35, 0x35, 0x36, 0x36, 0x36, 0x36, 0x37, 0x37, 0x37, 0x37
	.byte	0x38, 0x38, 0x38, 0x38, 0x39, 0x39, 0x39, 0x39, 0x3a, 0x3a, 0x3a, 0x3a, 0x3b, 0x3b, 0x3b, 0x3b
	.byte	0x3c, 0x3c, 0x3c, 0x3c, 0x3d, 0x3d, 0x3d, 0x3d, 0x3e, 0x3e, 0x3e, 0x3e, 0x3f, 0x3f, 0x3f, 0x3f
	.byte	0x40, 0x40, 0x40, 0x41, 0x41, 0x41, 0x42, 0x42, 0x42, 0x43, 0x43, 0x43, 0x44, 0x44, 0x44, 0x45
	.byte	0x45, 0x45, 0x46, 0x46, 0x46, 0x47, 0x47, 0x47, 0x48, 0x48, 0x48, 0x49, 0x49, 0x49, 0x4a, 0x4a
	.byte	0x4a, 0x4b, 0x4b, 0x4b, 0x4c, 0x4c, 0x4c, 0x4d, 0x4d, 0x4d, 0x4e, 0x4e, 0x4e, 0x4f, 0x4f, 0x4f
	.byte	0x50, 0x50, 0x51, 0x51, 0x52, 0x52, 0x53, 0x53, 0x54, 0x54, 0x55, 0x55, 0x56, 0x56, 0x57, 0x57
	.byte	0x58, 0x58, 0x59, 0x59, 0x5a, 0x5a, 0x5b, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f, 0x60, 0x61, 0x62, 0x63
	.byte	0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6e, 0x70, 0x72, 0x74, 0x76, 0x78, 0x7a
	.byte	0x7c, 0x7e, 0x80, 0x82, 0x84, 0x86, 0x88, 0x8a, 0x8c, 0x8f, 0x92, 0x95, 0x98, 0x9b, 0x9e, 0xa1
	.byte	0xa4, 0xa8, 0xac, 0xb0, 0xb6, 0xbc, 0xc2, 0xc8, 0xce, 0xd4, 0xda, 0xe0, 0xe6, 0xec, 0xf2, 0xf8

; ----------------------------------------------------------------------------
; Voice_FilterDepth_Scale -- 0xFDE595..0xFDE694  (256 bytes)
;
; 256 bytes, 0x40..0xFF (filter half).  Referenced from 0xFAC618.
; Byte-identical to v142/subcpu/subcpu_data_tables.s:1506.
; Sibling: kn5000 sub-CPU 0x010ECE, v142/subcpu/subcpu_data_tables.s:1506
; ----------------------------------------------------------------------------
Voice_FilterDepth_Scale:
	.byte	0x40, 0x40, 0x41, 0x42, 0x43, 0x43, 0x44, 0x45, 0x46, 0x46, 0x47, 0x48, 0x49, 0x49, 0x4a, 0x4b
	.byte	0x4c, 0x4c, 0x4d, 0x4e, 0x4f, 0x4f, 0x50, 0x51, 0x52, 0x52, 0x53, 0x54, 0x55, 0x55, 0x56, 0x57
	.byte	0x58, 0x58, 0x59, 0x5a, 0x5b, 0x5b, 0x5c, 0x5d, 0x5e, 0x5e, 0x5f, 0x60, 0x61, 0x61, 0x62, 0x63
	.byte	0x64, 0x64, 0x65, 0x66, 0x67, 0x67, 0x68, 0x69, 0x6a, 0x6a, 0x6b, 0x6c, 0x6d, 0x6d, 0x6e, 0x6f
	.byte	0x70, 0x70, 0x71, 0x72, 0x73, 0x73, 0x74, 0x75, 0x76, 0x76, 0x77, 0x78, 0x79, 0x79, 0x7a, 0x7b
	.byte	0x7c, 0x7c, 0x7d, 0x7e, 0x7f, 0x7f, 0x80, 0x81, 0x82, 0x82, 0x83, 0x84, 0x85, 0x85, 0x86, 0x87
	.byte	0x88, 0x88, 0x89, 0x8a, 0x8b, 0x8b, 0x8c, 0x8d, 0x8e, 0x8e, 0x8f, 0x90, 0x91, 0x91, 0x92, 0x93
	.byte	0x94, 0x94, 0x95, 0x96, 0x97, 0x97, 0x98, 0x99, 0x9a, 0x9a, 0x9b, 0x9c, 0x9d, 0x9d, 0x9e, 0x9f
	.byte	0xa0, 0xa0, 0xa1, 0xa2, 0xa3, 0xa3, 0xa4, 0xa5, 0xa6, 0xa6, 0xa7, 0xa8, 0xa9, 0xa9, 0xaa, 0xab
	.byte	0xac, 0xac, 0xad, 0xae, 0xaf, 0xaf, 0xb0, 0xb1, 0xb2, 0xb2, 0xb3, 0xb4, 0xb5, 0xb5, 0xb6, 0xb7
	.byte	0xb8, 0xb8, 0xb9, 0xba, 0xbb, 0xbb, 0xbc, 0xbd, 0xbe, 0xbe, 0xbf, 0xc0, 0xc1, 0xc1, 0xc2, 0xc3
	.byte	0xc4, 0xc4, 0xc5, 0xc6, 0xc7, 0xc7, 0xc8, 0xc9, 0xca, 0xca, 0xcb, 0xcc, 0xcd, 0xcd, 0xce, 0xcf
	.byte	0xd0, 0xd0, 0xd1, 0xd2, 0xd3, 0xd3, 0xd4, 0xd5, 0xd6, 0xd6, 0xd7, 0xd8, 0xd9, 0xd9, 0xda, 0xdb
	.byte	0xdc, 0xdc, 0xdd, 0xde, 0xdf, 0xdf, 0xe0, 0xe1, 0xe2, 0xe2, 0xe3, 0xe4, 0xe5, 0xe5, 0xe6, 0xe7
	.byte	0xe8, 0xe8, 0xe9, 0xea, 0xeb, 0xeb, 0xec, 0xed, 0xee, 0xee, 0xef, 0xf0, 0xf1, 0xf1, 0xf2, 0xf3
	.byte	0xf4, 0xf4, 0xf5, 0xf6, 0xf7, 0xf7, 0xf8, 0xf9, 0xfa, 0xfa, 0xfb, 0xfc, 0xfd, 0xfd, 0xfe, 0xff

; ----------------------------------------------------------------------------
; BitMask_Table_FDE695 -- 0xFDE695..0xFDE6A8  (20 bytes)
;
; 10 u16 bit masks.  WSA1-only: the KN5000 payload has nothing here, and this is
; the 20-byte block the WSA1 inserts between Voice_FilterDepth_Scale and the DSP
; selector records.
;
; The u16 element width is read off the readers, not assumed:
;   0xFB0BE8  ld C,0x02 / mul BC,(XIZ+0x0e) / add XBC,0x00FDE695 / ld BC,(XBC)
;             -- index*2 then a WORD load;
;   0xFAFC9D  add XIY,0x00FDE695 / ld IY,(XIY) / and WA,IY
;             -- the value is ANDed against a 16-bit word and branched on;
;   0xFB0EAE  ld BC,(0xFDE695) -- entry 0 fetched by absolute address.
; Seven reference sites in all.  The entry count is the space between its two
; neighbours; nothing has been traced that bounds the index, so 10 is a capacity,
; not a proven count.  What the mask SELECTS is NOT ESTABLISHED.
; ----------------------------------------------------------------------------
BitMask_Table_FDE695:
	.short	0x0001, 0x0002, 0x0004, 0x0008, 0x0401, 0x4010, 0x0401, 0x4010
	.short	0x0802, 0x8020

; ----------------------------------------------------------------------------
; DSP_AlgoChannel_SelectorRecords -- 0xFDE6A9..0xFDE6F0  (72 bytes)
;
; 12 records x 6 bytes: three 2-byte channel pairs per algorithm type, 0xFF = the
; 'no entry' sentinel.  The bytes select a row in DSP_ChanFreq_CurvePool below.
; Four references here: 0xFB58AD, 0xFB58C8, 0xFB5948, 0xFB5A57.
; Byte-identical to v142/subcpu/subcpu_data_tables.s:1543.
; Sibling: kn5000 sub-CPU 0x010FCE, v142/subcpu/subcpu_data_tables.s:1543
; ----------------------------------------------------------------------------
DSP_AlgoChannel_SelectorRecords:
	; type 0
	.byte	0x01, 0x02, 0x00, 0x00, 0xff, 0xff
	; type 1
	.byte	0x01, 0x03, 0x00, 0x00, 0xff, 0xff
	; type 2
	.byte	0x01, 0x04, 0x00, 0x00, 0xff, 0xff
	; type 3
	.byte	0x01, 0x03, 0x00, 0x01, 0xff, 0xff
	; type 4
	.byte	0x00, 0x00, 0x00, 0x03, 0xff, 0xff
	; type 5
	.byte	0x00, 0x00, 0x00, 0x03, 0xff, 0xff
	; type 6
	.byte	0xff, 0xff, 0xff, 0xff, 0x00, 0x03
	; type 7
	.byte	0x00, 0x05, 0x00, 0x06, 0x00, 0x05
	; type 8
	.byte	0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	; type 9
	.byte	0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	; type 10
	.byte	0x02, 0x07, 0xff, 0xff, 0xff, 0xff
	; type 11
	.byte	0x02, 0x07, 0xff, 0xff, 0xff, 0xff

; ----------------------------------------------------------------------------
; DSP_ChanFreq_CurvePool -- 0xFDE6F1..0xFDEBB8  (1224 bytes)
;
; 12 rows x 51 u16, stride 0x66.  One contiguous pool of ascending frequency /
; coefficient curves addressed with three different row bases in the sibling; row 7
; is the constant 0x0B4D there and here.  References: 0xFB5AA4, 0xFB5AD8, 0xFB5B2D,
; 0xFB5CE0.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1565.
; Sibling: kn5000 sub-CPU 0x011016, v142/subcpu/subcpu_data_tables.s:1565
; ----------------------------------------------------------------------------
DSP_ChanFreq_CurvePool:
	; row 0
	.short	0x0006, 0x0006, 0x0008, 0x0008, 0x0008, 0x000a, 0x000a, 0x000c
	.short	0x000c, 0x000e, 0x000e, 0x000f, 0x0011, 0x0013, 0x0013, 0x0015
	.short	0x0017, 0x0019, 0x001d, 0x001f, 0x0021, 0x0025, 0x0029, 0x002d
	.short	0x0030, 0x0034, 0x0038, 0x003e, 0x0044, 0x004a, 0x004f, 0x0057
	.short	0x005f, 0x0068, 0x0072, 0x007c, 0x0087, 0x0093, 0x00a1, 0x00ae
	.short	0x00c0, 0x00d1, 0x00e2, 0x00f8, 0x010f, 0x0126, 0x0141, 0x015e
	.short	0x017d, 0x01a0, 0x01c7
	; row 1
	.short	0x0002, 0x0004, 0x0004, 0x0004, 0x0004, 0x0004, 0x0004, 0x0006
	.short	0x0006, 0x0006, 0x0006, 0x0008, 0x0008, 0x0008, 0x000a, 0x000a
	.short	0x000c, 0x000c, 0x000e, 0x000e, 0x000f, 0x0011, 0x0013, 0x0013
	.short	0x0015, 0x0017, 0x0019, 0x001d, 0x001f, 0x0021, 0x0025, 0x0029
	.short	0x002d, 0x0030, 0x0034, 0x0038, 0x003e, 0x0044, 0x004a, 0x004f
	.short	0x0057, 0x005f, 0x0068, 0x0072, 0x007c, 0x0087, 0x0093, 0x00a1
	.short	0x00ae, 0x00c0, 0x00d1
	; row 2
	.short	0x0007, 0x0008, 0x0008, 0x0009, 0x000b, 0x000b, 0x000c, 0x000d
	.short	0x000f, 0x0010, 0x0012, 0x0013, 0x0014, 0x0017, 0x0019, 0x001b
	.short	0x001d, 0x0020, 0x0023, 0x0026, 0x002a, 0x002d, 0x0031, 0x0036
	.short	0x003b, 0x0040, 0x0046, 0x004c, 0x0053, 0x005a, 0x0063, 0x006b
	.short	0x0075, 0x0080, 0x008b, 0x0098, 0x00a6, 0x00b5, 0x00c5, 0x00d7
	.short	0x00eb, 0x0100, 0x0117, 0x0130, 0x014b, 0x016a, 0x018a, 0x01ae
	.short	0x01d5, 0x0200, 0x022d
	; row 3
	.short	0x0013, 0x0014, 0x0017, 0x0019, 0x001b, 0x001d, 0x0020, 0x0023
	.short	0x0026, 0x002a, 0x002d, 0x0031, 0x0036, 0x003b, 0x0040, 0x0046
	.short	0x004c, 0x0053, 0x005a, 0x0063, 0x006b, 0x0075, 0x0080, 0x008b
	.short	0x0098, 0x00a6, 0x00b5, 0x00c5, 0x00d7, 0x00eb, 0x0100, 0x0117
	.short	0x0130, 0x014b, 0x016a, 0x018a, 0x01ae, 0x01d5, 0x0200, 0x022d
	.short	0x0260, 0x0297, 0x02d4, 0x0315, 0x035c, 0x03aa, 0x03ff, 0x045c
	.short	0x04c1, 0x052f, 0x05a6
	; row 4
	.short	0x000b, 0x000c, 0x000d, 0x000f, 0x0010, 0x0012, 0x0013, 0x0014
	.short	0x0017, 0x0019, 0x001b, 0x001d, 0x0020, 0x0023, 0x0026, 0x002a
	.short	0x002d, 0x0031, 0x0036, 0x003b, 0x0040, 0x0046, 0x004c, 0x0053
	.short	0x005a, 0x0063, 0x006b, 0x0075, 0x0080, 0x008b, 0x0098, 0x00a6
	.short	0x00b5, 0x00c5, 0x00d7, 0x00eb, 0x0100, 0x0117, 0x0130, 0x014b
	.short	0x016a, 0x018a, 0x01ae, 0x01d5, 0x0200, 0x022d, 0x0260, 0x0297
	.short	0x02d4, 0x0315, 0x035c
	; row 5
	.short	0x0034, 0x0036, 0x0038, 0x003c, 0x003e, 0x0040, 0x0044, 0x0046
	.short	0x004a, 0x004d, 0x004f, 0x0053, 0x0057, 0x005b, 0x005f, 0x0065
	.short	0x0068, 0x006c, 0x0072, 0x0076, 0x007c, 0x0082, 0x0087, 0x008d
	.short	0x0093, 0x0099, 0x00a1, 0x00a8, 0x00ae, 0x00b6, 0x00c0, 0x00c7
	.short	0x00d1, 0x00d9, 0x00e2, 0x00ee, 0x00f8, 0x0103, 0x010f, 0x011b
	.short	0x0126, 0x0134, 0x0141, 0x014f, 0x015e, 0x016e, 0x017d, 0x018f
	.short	0x01a0, 0x01b3, 0x01c7
	; row 6
	.short	0x00ce, 0x00d7, 0x00e1, 0x00eb, 0x00f5, 0x0100, 0x010b, 0x0117
	.short	0x0123, 0x0130, 0x013d, 0x014b, 0x015a, 0x016a, 0x017a, 0x018a
	.short	0x019c, 0x01ae, 0x01c1, 0x01d5, 0x01ea, 0x0200, 0x0216, 0x022d
	.short	0x0246, 0x0260, 0x027b, 0x0297, 0x02b4, 0x02d4, 0x02f3, 0x0315
	.short	0x0338, 0x035c, 0x0382, 0x03aa, 0x03d3, 0x03ff, 0x042c, 0x045c
	.short	0x048d, 0x04c1, 0x04f6, 0x052f, 0x056a, 0x05a6, 0x05e7, 0x062a
	.short	0x0670, 0x06b9, 0x0705
	; row 7
	.short	0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d
	.short	0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d
	.short	0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d
	.short	0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d
	.short	0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d
	.short	0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d, 0x0b4d
	.short	0x0b4d, 0x0b4d, 0x0b4d
	; row 8
	.short	0x0006, 0x0007, 0x0007, 0x0008, 0x0009, 0x000a, 0x000a, 0x000b
	.short	0x000c, 0x000d, 0x000f, 0x0010, 0x0011, 0x0013, 0x0015, 0x0017
	.short	0x0019, 0x001b, 0x001d, 0x0020, 0x0023, 0x0026, 0x0029, 0x002d
	.short	0x0031, 0x0036, 0x003b, 0x0040, 0x0046, 0x004c, 0x0053, 0x005a
	.short	0x0063, 0x006c, 0x0075, 0x0080, 0x008c, 0x0098, 0x00a6, 0x00b5
	.short	0x00c5, 0x00d7, 0x00eb, 0x0100, 0x0117, 0x0130, 0x014c, 0x016a
	.short	0x018b, 0x01ae, 0x01d5
	; row 9
	.short	0x0003, 0x0004, 0x0004, 0x0004, 0x0005, 0x0005, 0x0005, 0x0006
	.short	0x0006, 0x0007, 0x0008, 0x0008, 0x0009, 0x000a, 0x000b, 0x000c
	.short	0x000d, 0x000e, 0x000f, 0x0010, 0x0012, 0x0013, 0x0015, 0x0017
	.short	0x0019, 0x001b, 0x001e, 0x0020, 0x0023, 0x0026, 0x002a, 0x002d
	.short	0x0032, 0x0036, 0x003b, 0x0040, 0x0046, 0x004c, 0x0053, 0x005b
	.short	0x0063, 0x006c, 0x0076, 0x0080, 0x008c, 0x0098, 0x00a6, 0x00b5
	.short	0x00c6, 0x00d7, 0x00eb
	; row 10
	.short	0x0000, 0x0023, 0x0024, 0x0026, 0x0028, 0x0029, 0x002b, 0x002d
	.short	0x002f, 0x0031, 0x0034, 0x0036, 0x0038, 0x003b, 0x003d, 0x0040
	.short	0x0043, 0x0046, 0x0049, 0x004c, 0x004f, 0x0053, 0x0057, 0x005a
	.short	0x005e, 0x0063, 0x0067, 0x006c, 0x0070, 0x0075, 0x007b, 0x0080
	.short	0x0086, 0x008c, 0x0092, 0x0098, 0x009f, 0x00a6, 0x00ad, 0x00b5
	.short	0x00bd, 0x00c5, 0x00ce, 0x00d7, 0x00e1, 0x00eb, 0x00f5, 0x0100
	.short	0x010b, 0x0117, 0x0123
	; row 11
	.short	0x0000, 0x00a4, 0x0148, 0x01eb, 0x028f, 0x0333, 0x03d7, 0x047b
	.short	0x051f, 0x05c2, 0x0666, 0x070a, 0x07ae, 0x0852, 0x08f5, 0x0999
	.short	0x0a3d, 0x0ae1, 0x0b85, 0x0c29, 0x0ccc, 0x0d70, 0x0e14, 0x0eb8
	.short	0x0f5c, 0x1000, 0x10a3, 0x1147, 0x11eb, 0x128f, 0x1333, 0x13d6
	.short	0x147a, 0x151e, 0x15c2, 0x1666, 0x170a, 0x17ad, 0x1851, 0x18f5
	.short	0x1999, 0x1a3d, 0x1ae0, 0x1b84, 0x1c28, 0x1ccc, 0x1d70, 0x1e14
	.short	0x1eb7, 0x1f5b, 0x1fff

; ----------------------------------------------------------------------------
; DSP_ChanFreq_IndexMap -- 0xFDEBB9..0xFDEBEB  (51 bytes)
;
; 51 bytes: identity through 0x15, then bowing up to 0x7F -- a 51-step
; exponential bend used to index the pool above.  References: 0xFB6332, 0xFB6358,
; 0xFB6372.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1679.
; Sibling: kn5000 sub-CPU 0x0114DE, v142/subcpu/subcpu_data_tables.s:1679
; ----------------------------------------------------------------------------
DSP_ChanFreq_IndexMap:
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
	.byte	0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x17, 0x18, 0x1a, 0x1b, 0x1d, 0x1f, 0x21, 0x23, 0x25, 0x27
	.byte	0x2a, 0x2d, 0x2f, 0x32, 0x36, 0x39, 0x3d, 0x41, 0x45, 0x49, 0x4e, 0x53, 0x58, 0x5e, 0x64, 0x6a
	.byte	0x71, 0x78, 0x7f

; ----------------------------------------------------------------------------
; EGEnv_ModeBits_Table -- 0xFDEBEC..0xFDEBF3  (8 bytes)
;
; 4 u16 {0x0000, 0xC000, 0x4000, 0x8000} -- a 2-bit envelope/format mode field
; pre-shifted into bits 15..14, ORed into the computed envelope word.
; References: 0xFA79E4, 0xFA7AC6, 0xFA7BB4, 0xFA7C27.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1692.
; Sibling: kn5000 sub-CPU 0x011511, v142/subcpu/subcpu_data_tables.s:1692
; ----------------------------------------------------------------------------
EGEnv_ModeBits_Table:
	.short	0x0000, 0xc000, 0x4000, 0x8000

; ----------------------------------------------------------------------------
; TVF_KeyFollow_Curves -- 0xFDEBF4..0xFDEF73  (896 bytes)
;
; 7 curves x 128 SIGNED bytes (0xC0..0x00, i.e. -64..0).  TVF cutoff key-follow:
; a 3-bit selector picks the curve, key & 0x7F indexes inside it, and the signed
; byte is scaled by the key-follow depth.  References: 0xFA7718, 0xFA77D1.
; Byte-identical to v142/subcpu/subcpu_data_tables.s:1700.
; ⚠ Same shipped quirk as the sibling: the selector is 3 bits but only 7 curves
; exist, so selector 7 reads into the table that follows.
; Sibling: kn5000 sub-CPU 0x011519, v142/subcpu/subcpu_data_tables.s:1700
; ----------------------------------------------------------------------------
TVF_KeyFollow_Curves:
	; curve 0
	.byte	0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc1, 0xc1, 0xc1, 0xc1, 0xc1, 0xc1, 0xc1, 0xc1, 0xc2, 0xc2, 0xc2
	.byte	0xc2, 0xc2, 0xc2, 0xc2, 0xc2, 0xc3, 0xc3, 0xc3, 0xc3, 0xc3, 0xc3, 0xc3, 0xc3, 0xc4, 0xc4, 0xc4
	.byte	0xc4, 0xc4, 0xc4, 0xc4, 0xc4, 0xc5, 0xc5, 0xc5, 0xc5, 0xc5, 0xc5, 0xc5, 0xc5, 0xc6, 0xc6, 0xc6
	.byte	0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xc7, 0xc7, 0xc7, 0xc7, 0xc7, 0xc7, 0xc7, 0xc7, 0xc8, 0xc8, 0xc8
	.byte	0xc8, 0xc9, 0xca, 0xcb, 0xcb, 0xcc, 0xcd, 0xce, 0xcf, 0xd0, 0xd1, 0xd2, 0xd2, 0xd3, 0xd4, 0xd5
	.byte	0xd6, 0xd7, 0xd8, 0xd9, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf, 0xe0, 0xe0, 0xe1, 0xe2, 0xe3
	.byte	0xe4, 0xe5, 0xe6, 0xe7, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xee, 0xef, 0xf0, 0xf1
	.byte	0xf2, 0xf3, 0xf4, 0xf5, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfc, 0xfd, 0xfe, 0xff
	; curve 1
	.byte	0xc0, 0xc0, 0xc0, 0xc1, 0xc1, 0xc1, 0xc1, 0xc2, 0xc2, 0xc2, 0xc2, 0xc3, 0xc3, 0xc3, 0xc3, 0xc4
	.byte	0xc4, 0xc4, 0xc4, 0xc5, 0xc5, 0xc5, 0xc5, 0xc6, 0xc6, 0xc6, 0xc6, 0xc7, 0xc7, 0xc7, 0xc7, 0xc8
	.byte	0xc8, 0xc8, 0xc8, 0xc9, 0xc9, 0xc9, 0xc9, 0xca, 0xca, 0xca, 0xca, 0xcb, 0xcb, 0xcb, 0xcb, 0xcc
	.byte	0xcc, 0xcc, 0xcc, 0xcd, 0xcd, 0xcd, 0xcd, 0xce, 0xce, 0xce, 0xce, 0xcf, 0xcf, 0xcf, 0xcf, 0xd0
	.byte	0xd0, 0xd1, 0xd1, 0xd2, 0xd3, 0xd4, 0xd4, 0xd5, 0xd6, 0xd7, 0xd7, 0xd8, 0xd9, 0xda, 0xda, 0xdb
	.byte	0xdc, 0xdd, 0xdd, 0xde, 0xdf, 0xe0, 0xe0, 0xe1, 0xe2, 0xe3, 0xe3, 0xe4, 0xe5, 0xe6, 0xe6, 0xe7
	.byte	0xe8, 0xe9, 0xe9, 0xea, 0xeb, 0xec, 0xec, 0xed, 0xee, 0xef, 0xef, 0xf0, 0xf1, 0xf2, 0xf2, 0xf3
	.byte	0xf4, 0xf5, 0xf5, 0xf6, 0xf7, 0xf8, 0xf8, 0xf9, 0xfa, 0xfb, 0xfb, 0xfc, 0xfd, 0xfe, 0xfe, 0xff
	; curve 2
	.byte	0xc0, 0xc0, 0xc1, 0xc1, 0xc1, 0xc2, 0xc2, 0xc3, 0xc3, 0xc3, 0xc4, 0xc4, 0xc4, 0xc5, 0xc5, 0xc6
	.byte	0xc6, 0xc6, 0xc7, 0xc7, 0xc7, 0xc8, 0xc8, 0xc9, 0xc9, 0xc9, 0xca, 0xca, 0xca, 0xcb, 0xcb, 0xcc
	.byte	0xcc, 0xcc, 0xcd, 0xcd, 0xcd, 0xce, 0xce, 0xcf, 0xcf, 0xcf, 0xd0, 0xd0, 0xd0, 0xd1, 0xd1, 0xd2
	.byte	0xd2, 0xd2, 0xd3, 0xd3, 0xd3, 0xd4, 0xd4, 0xd5, 0xd5, 0xd5, 0xd6, 0xd6, 0xd6, 0xd7, 0xd7, 0xd8
	.byte	0xd8, 0xd9, 0xd9, 0xda, 0xda, 0xdb, 0xdc, 0xdc, 0xdd, 0xde, 0xde, 0xdf, 0xdf, 0xe0, 0xe1, 0xe1
	.byte	0xe2, 0xe3, 0xe3, 0xe4, 0xe4, 0xe5, 0xe6, 0xe6, 0xe7, 0xe8, 0xe8, 0xe9, 0xe9, 0xea, 0xeb, 0xeb
	.byte	0xec, 0xed, 0xed, 0xee, 0xee, 0xef, 0xf0, 0xf0, 0xf1, 0xf2, 0xf2, 0xf3, 0xf3, 0xf4, 0xf5, 0xf5
	.byte	0xf6, 0xf7, 0xf7, 0xf8, 0xf8, 0xf9, 0xfa, 0xfa, 0xfb, 0xfc, 0xfc, 0xfd, 0xfd, 0xfe, 0xff, 0xff
	; curve 3
	.byte	0xc0, 0xc0, 0xc1, 0xc1, 0xc2, 0xc2, 0xc3, 0xc3, 0xc4, 0xc4, 0xc5, 0xc5, 0xc6, 0xc6, 0xc7, 0xc7
	.byte	0xc8, 0xc8, 0xc9, 0xc9, 0xca, 0xca, 0xcb, 0xcb, 0xcc, 0xcc, 0xcd, 0xcd, 0xce, 0xce, 0xcf, 0xcf
	.byte	0xd0, 0xd0, 0xd1, 0xd1, 0xd2, 0xd2, 0xd3, 0xd3, 0xd4, 0xd4, 0xd5, 0xd5, 0xd6, 0xd6, 0xd7, 0xd7
	.byte	0xd8, 0xd8, 0xd9, 0xd9, 0xda, 0xda, 0xdb, 0xdb, 0xdc, 0xdc, 0xdd, 0xdd, 0xde, 0xde, 0xdf, 0xdf
	.byte	0xe0, 0xe0, 0xe1, 0xe1, 0xe2, 0xe2, 0xe3, 0xe3, 0xe4, 0xe4, 0xe5, 0xe5, 0xe6, 0xe6, 0xe7, 0xe7
	.byte	0xe8, 0xe8, 0xe9, 0xe9, 0xea, 0xea, 0xeb, 0xeb, 0xec, 0xec, 0xed, 0xed, 0xee, 0xee, 0xef, 0xef
	.byte	0xf0, 0xf0, 0xf1, 0xf1, 0xf2, 0xf2, 0xf3, 0xf3, 0xf4, 0xf4, 0xf5, 0xf5, 0xf6, 0xf6, 0xf7, 0xf7
	.byte	0xf8, 0xf8, 0xf9, 0xf9, 0xfa, 0xfa, 0xfb, 0xfb, 0xfc, 0xfc, 0xfd, 0xfd, 0xfe, 0xfe, 0xff, 0x00
	; curve 4
	.byte	0xc8, 0xc8, 0xc9, 0xc9, 0xca, 0xca, 0xcb, 0xcb, 0xcc, 0xcc, 0xcd, 0xcd, 0xce, 0xce, 0xcf, 0xcf
	.byte	0xd0, 0xd0, 0xd1, 0xd1, 0xd2, 0xd2, 0xd3, 0xd3, 0xd4, 0xd4, 0xd5, 0xd5, 0xd6, 0xd6, 0xd7, 0xd7
	.byte	0xd8, 0xd8, 0xd9, 0xd9, 0xda, 0xda, 0xdb, 0xdb, 0xdc, 0xdc, 0xdd, 0xdd, 0xde, 0xde, 0xdf, 0xdf
	.byte	0xe0, 0xe0, 0xe1, 0xe1, 0xe2, 0xe2, 0xe3, 0xe3, 0xe4, 0xe4, 0xe5, 0xe5, 0xe6, 0xe6, 0xe7, 0xe7
	.byte	0xe8, 0xe8, 0xe9, 0xe9, 0xea, 0xea, 0xeb, 0xeb, 0xec, 0xec, 0xed, 0xed, 0xee, 0xee, 0xef, 0xef
	.byte	0xf0, 0xf0, 0xf1, 0xf1, 0xf2, 0xf2, 0xf3, 0xf3, 0xf4, 0xf4, 0xf5, 0xf5, 0xf6, 0xf6, 0xf7, 0xf7
	.byte	0xf8, 0xf8, 0xf9, 0xf9, 0xfa, 0xfa, 0xfb, 0xfb, 0xfc, 0xfc, 0xfd, 0xfd, 0xfe, 0xfe, 0xff, 0xff
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; curve 5
	.byte	0xd0, 0xd0, 0xd1, 0xd1, 0xd2, 0xd2, 0xd3, 0xd3, 0xd4, 0xd4, 0xd5, 0xd5, 0xd6, 0xd6, 0xd7, 0xd7
	.byte	0xd8, 0xd8, 0xd9, 0xd9, 0xda, 0xda, 0xdb, 0xdb, 0xdc, 0xdc, 0xdd, 0xdd, 0xde, 0xde, 0xdf, 0xdf
	.byte	0xe0, 0xe0, 0xe1, 0xe1, 0xe2, 0xe2, 0xe3, 0xe3, 0xe4, 0xe4, 0xe5, 0xe5, 0xe6, 0xe6, 0xe7, 0xe7
	.byte	0xe8, 0xe8, 0xe9, 0xe9, 0xea, 0xea, 0xeb, 0xeb, 0xec, 0xec, 0xed, 0xed, 0xee, 0xee, 0xef, 0xef
	.byte	0xf0, 0xf0, 0xf1, 0xf1, 0xf2, 0xf2, 0xf3, 0xf3, 0xf4, 0xf4, 0xf5, 0xf5, 0xf6, 0xf6, 0xf7, 0xf7
	.byte	0xf8, 0xf8, 0xf9, 0xf9, 0xfa, 0xfa, 0xfb, 0xfb, 0xfc, 0xfc, 0xfd, 0xfd, 0xfe, 0xfe, 0xff, 0xff
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; curve 6
	.byte	0xd8, 0xd8, 0xd9, 0xd9, 0xda, 0xda, 0xdb, 0xdb, 0xdc, 0xdc, 0xdd, 0xdd, 0xde, 0xde, 0xdf, 0xdf
	.byte	0xe0, 0xe0, 0xe1, 0xe1, 0xe2, 0xe2, 0xe3, 0xe3, 0xe4, 0xe4, 0xe5, 0xe5, 0xe6, 0xe6, 0xe7, 0xe7
	.byte	0xe8, 0xe8, 0xe9, 0xe9, 0xea, 0xea, 0xeb, 0xeb, 0xec, 0xec, 0xed, 0xed, 0xee, 0xee, 0xef, 0xef
	.byte	0xf0, 0xf0, 0xf1, 0xf1, 0xf2, 0xf2, 0xf3, 0xf3, 0xf4, 0xf4, 0xf5, 0xf5, 0xf6, 0xf6, 0xf7, 0xf7
	.byte	0xf8, 0xf8, 0xf9, 0xf9, 0xfa, 0xfa, 0xfb, 0xfb, 0xfc, 0xfc, 0xfd, 0xfd, 0xfe, 0xfe, 0xff, 0xff
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

; ----------------------------------------------------------------------------
; Voice_LevelPair_AttackCurve -- 0xFDEF74..0xFDEFD8  (101 bytes)
;
; 101 bytes, descending 0xFF..0x09, indexed by a level clamped to 0..100.
; References: 0xFAA56D, 0xFAA9EB, 0xFAADA5, 0xFAB152.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1827.
; Sibling: kn5000 sub-CPU 0x011899, v142/subcpu/subcpu_data_tables.s:1827
; ----------------------------------------------------------------------------
Voice_LevelPair_AttackCurve:
	.byte	0xff, 0xf8, 0xf2, 0xee, 0xea, 0xe6, 0xe2, 0xde, 0xda, 0xd6, 0xd2, 0xce, 0xca, 0xc6, 0xc2, 0xbe
	.byte	0xba, 0xb6, 0xb2, 0xb0, 0xae, 0xac, 0xaa, 0xa8, 0xa6, 0xa4, 0xa2, 0xa0, 0x9e, 0x9c, 0x9a, 0x98
	.byte	0x96, 0x94, 0x92, 0x90, 0x8e, 0x8c, 0x8a, 0x88, 0x86, 0x84, 0x82, 0x80, 0x7e, 0x7c, 0x7a, 0x78
	.byte	0x76, 0x74, 0x72, 0x70, 0x6e, 0x6c, 0x6a, 0x68, 0x66, 0x64, 0x62, 0x60, 0x5e, 0x5c, 0x5a, 0x58
	.byte	0x56, 0x54, 0x52, 0x50, 0x4e, 0x4c, 0x4a, 0x48, 0x46, 0x44, 0x42, 0x40, 0x3e, 0x3c, 0x3a, 0x38
	.byte	0x36, 0x34, 0x32, 0x30, 0x2e, 0x2c, 0x2a, 0x28, 0x26, 0x24, 0x22, 0x20, 0x1e, 0x1c, 0x1a, 0x18
	.byte	0x16, 0x14, 0x12, 0x0e, 0x09

; ----------------------------------------------------------------------------
; Voice_EnvelopeLevel_Curve -- 0xFDEFD9..0xFDF03D  (101 bytes)
;
; 101 bytes, descending 0xFF..0x04.  The sibling calls this the hottest object in
; its zone (38 reference sites); it is heavily referenced here too -- 0xFA84D3,
; 0xFA84F6, 0xFA851E, 0xFA853C and more.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1850.
; Sibling: kn5000 sub-CPU 0x0118FE, v142/subcpu/subcpu_data_tables.s:1850
; ----------------------------------------------------------------------------
Voice_EnvelopeLevel_Curve:
	.byte	0xff, 0xf8, 0xf1, 0xed, 0xe9, 0xe7, 0xe5, 0xe3, 0xe1, 0xde, 0xda, 0xd6, 0xd2, 0xd0, 0xce, 0xcc
	.byte	0xca, 0xc8, 0xc6, 0xc4, 0xc2, 0xc0, 0xbe, 0xbc, 0xba, 0xb8, 0xb6, 0xb4, 0xb2, 0xb0, 0xae, 0xac
	.byte	0xaa, 0xa8, 0xa6, 0xa4, 0xa2, 0xa0, 0x9e, 0x9c, 0x9a, 0x98, 0x96, 0x94, 0x92, 0x90, 0x8e, 0x8c
	.byte	0x8a, 0x88, 0x86, 0x84, 0x82, 0x80, 0x7e, 0x7c, 0x7a, 0x78, 0x76, 0x74, 0x72, 0x70, 0x6e, 0x6c
	.byte	0x6a, 0x68, 0x66, 0x64, 0x62, 0x60, 0x5e, 0x5c, 0x5a, 0x58, 0x56, 0x54, 0x52, 0x50, 0x4e, 0x4c
	.byte	0x4a, 0x48, 0x46, 0x44, 0x42, 0x40, 0x3e, 0x3c, 0x3a, 0x38, 0x36, 0x34, 0x32, 0x30, 0x2e, 0x2a
	.byte	0x26, 0x1e, 0x16, 0x10, 0x04

; ----------------------------------------------------------------------------
; Voice_EnvelopeRate_Table -- 0xFDF03E..0xFDF0A2  (101 bytes)
;
; 101 bytes, monotone 0x00..0x7F: parameter -> envelope rate.  References:
; 0xFAA630, 0xFAA81F, 0xFAA83D, 0xFAAB68.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1869.
; Sibling: kn5000 sub-CPU 0x011963, v142/subcpu/subcpu_data_tables.s:1869
; ----------------------------------------------------------------------------
Voice_EnvelopeRate_Table:
	.byte	0x00, 0x04, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e, 0x20, 0x22
	.byte	0x24, 0x26, 0x28, 0x2a, 0x2c, 0x2e, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39
	.byte	0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49
	.byte	0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59
	.byte	0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f, 0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69
	.byte	0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79
	.byte	0x7a, 0x7b, 0x7c, 0x7e, 0x7f

; ----------------------------------------------------------------------------
; Ramp_0_to_100_Curve -- 0xFDF0A3..0xFDF122  (128 bytes)
;
; 128 bytes rising 0x00 -> 0x64 (0 -> 100).  WSA1-only: the KN5000 payload goes
; straight from Voice_EnvelopeRate_Table to Detune_Scale_Curve with nothing here.
; Shape: doubled steps at the bottom (00 00 00 00 01 01 01 01 02 02 ...), single
; steps from index 0x30, so it compresses a 0..127 input into a 0..100 output.
; Four references: 0xFBDF8D, 0xFBDFAF, 0xFBF55E, 0xFBF580.  What the 0..100 range
; means (a percentage parameter?) is NOT ESTABLISHED.
; ----------------------------------------------------------------------------
Ramp_0_to_100_Curve:
	.byte	0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x02, 0x02, 0x03, 0x03, 0x04, 0x04, 0x05, 0x05
	.byte	0x06, 0x06, 0x07, 0x07, 0x08, 0x08, 0x09, 0x09, 0x0a, 0x0a, 0x0b, 0x0b, 0x0c, 0x0c, 0x0d, 0x0d
	.byte	0x0e, 0x0e, 0x0f, 0x0f, 0x10, 0x10, 0x11, 0x11, 0x12, 0x12, 0x13, 0x13, 0x14, 0x14, 0x15, 0x15
	.byte	0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25
	.byte	0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35
	.byte	0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45
	.byte	0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55
	.byte	0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f, 0x60, 0x61, 0x62, 0x63, 0x63, 0x64

; ----------------------------------------------------------------------------
; Detune_Scale_Curve -- 0xFDF123..0xFDF155  (51 bytes)
;
; 51 bytes, piecewise-linear 0x00..0x7F with knees at [16] and [32].  Detune
; scaling, symmetric about 0 in the sibling.  References: 0xFA7629, 0xFA7648,
; 0xFA7661.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1889.
; Sibling: kn5000 sub-CPU 0x0119C8, v142/subcpu/subcpu_data_tables.s:1889
; ----------------------------------------------------------------------------
Detune_Scale_Curve:
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
	.byte	0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x1e, 0x20, 0x22, 0x24, 0x26, 0x28, 0x2a, 0x2c, 0x2e
	.byte	0x30, 0x34, 0x38, 0x3c, 0x40, 0x44, 0x48, 0x4c, 0x50, 0x54, 0x58, 0x5c, 0x60, 0x64, 0x68, 0x6c
	.byte	0x70, 0x78, 0x7f

; ----------------------------------------------------------------------------
; TVF_DepthRecords_A -- 0xFDF156..0xFDF17F  (42 bytes)
;
; 14 records x 3 bytes: {flag 0x80/0x00, amount 0x00..0x7F, signed offset}.
; The sibling notes the three columns are fetched through fixed +0/+1/+2 bases
; with index*3 -- and prom_c does the same: 0xFA7891 loads the +0 base and
; 0xFA786B / 0xFA787D the +1 and +2 bases as 24-bit operands.
; Byte-identical to v142/subcpu/subcpu_data_tables.s:1902.
; Sibling: kn5000 sub-CPU 0x0119FB, v142/subcpu/subcpu_data_tables.s:1902
; ----------------------------------------------------------------------------
TVF_DepthRecords_A:
	; rec  0
	.byte	0x80, 0x00, 0x00
	; rec  1
	.byte	0x80, 0x40, 0xf0
	; rec  2
	.byte	0x80, 0x4e, 0xf3
	; rec  3
	.byte	0x80, 0x5b, 0xf5
	; rec  4
	.byte	0x80, 0x66, 0xf8
	; rec  5
	.byte	0x80, 0x6f, 0xfb
	; rec  6
	.byte	0x80, 0x78, 0xfd
	; rec  7
	.byte	0x00, 0x7f, 0x00
	; rec  8
	.byte	0x00, 0x78, 0x00
	; rec  9
	.byte	0x00, 0x6f, 0x00
	; rec 10
	.byte	0x00, 0x66, 0x00
	; rec 11
	.byte	0x00, 0x5b, 0x00
	; rec 12
	.byte	0x00, 0x4e, 0x00
	; rec 13
	.byte	0x00, 0x40, 0x00

; ----------------------------------------------------------------------------
; TVF_DepthRecords_B -- 0xFDF180..0xFDF1A9  (42 bytes)
;
; 14 records x 3 bytes, the mirror image of set A (the flag column moves from the
; negative arm to the positive arm).  References 0xFA7836, 0xFA785A, and 0xFA7846
; for the +1 column.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1922.
; Sibling: kn5000 sub-CPU 0x011A25, v142/subcpu/subcpu_data_tables.s:1922
; ----------------------------------------------------------------------------
TVF_DepthRecords_B:
	; rec  0
	.byte	0x00, 0x00, 0x00
	; rec  1
	.byte	0x00, 0x40, 0xf0
	; rec  2
	.byte	0x00, 0x4e, 0xf3
	; rec  3
	.byte	0x00, 0x5b, 0xf5
	; rec  4
	.byte	0x00, 0x66, 0xf8
	; rec  5
	.byte	0x00, 0x6f, 0xfb
	; rec  6
	.byte	0x00, 0x78, 0xfd
	; rec  7
	.byte	0x00, 0x7f, 0x00
	; rec  8
	.byte	0x80, 0x78, 0x00
	; rec  9
	.byte	0x80, 0x6f, 0x00
	; rec 10
	.byte	0x80, 0x66, 0x00
	; rec 11
	.byte	0x80, 0x5b, 0x00
	; rec 12
	.byte	0x80, 0x4e, 0x00
	; rec 13
	.byte	0x80, 0x40, 0x00

; ----------------------------------------------------------------------------
; Voice_FineTune_Curve -- 0xFDF1AA..0xFDF229  (128 bytes)
;
; 128 signed bytes, a +-8 fine-tune dip curve (0 at both ends, -8 mid-scale),
; added into the pitch accumulator.  References: 0xFAB656, 0xFAB75B.
; Byte-identical to v142/subcpu/subcpu_data_tables.s:1941.
; Sibling: kn5000 sub-CPU 0x011A4F, v142/subcpu/subcpu_data_tables.s:1941
; ----------------------------------------------------------------------------
Voice_FineTune_Curve:
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff
	.byte	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xfe, 0xfe, 0xfe, 0xfe, 0xfe, 0xfe, 0xfe
	.byte	0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfc, 0xfc, 0xfc, 0xfc, 0xfc, 0xfc, 0xfb, 0xfb, 0xfb
	.byte	0xfb, 0xfb, 0xfa, 0xfa, 0xfa, 0xfa, 0xfa, 0xfa, 0xf9, 0xf9, 0xf9, 0xf9, 0xf9, 0xf9, 0xf8, 0xf8
	.byte	0xf8, 0xf8, 0xf9, 0xf9, 0xf9, 0xf9, 0xf9, 0xf9, 0xfa, 0xfa, 0xfa, 0xfa, 0xfa, 0xfa, 0xfb, 0xfb
	.byte	0xfb, 0xfb, 0xfb, 0xfc, 0xfc, 0xfc, 0xfc, 0xfc, 0xfc, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd
	.byte	0xfe, 0xfe, 0xfe, 0xfe, 0xfe, 0xfe, 0xfe, 0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	.byte	0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

; ----------------------------------------------------------------------------
; Instrument_OctaveShift_Semitones -- 0xFDF22A..0xFDF239  (16 bytes)
;
; 16 signed bytes = 12*k semitones for k = -8..+7, i.e. -96, -84 ... 0 ... +84.
; Whole-octave transpose offsets.  Referenced from 0xFA737E.
; Byte-identical to v142/subcpu/subcpu_data_tables.s:1962.
; Sibling: kn5000 sub-CPU 0x011ACF, v142/subcpu/subcpu_data_tables.s:1962
; ----------------------------------------------------------------------------
Instrument_OctaveShift_Semitones:
	.byte	0xa0, 0xac, 0xb8, 0xc4, 0xd0, 0xdc, 0xe8, 0xf4, 0x00, 0x0c, 0x18, 0x24, 0x30, 0x3c, 0x48, 0x54

; ----------------------------------------------------------------------------
; Voice_EnvLevel_IndexMap -- 0xFDF23A..0xFDF242  (9 bytes)
;
; 9 bytes {0x31,0x31,0x35,0x39,0x3D,0x41,0x45,0x49,0x4D} -- an index INTO
; Voice_EnvelopeLevel_Curve above, so the pair is read as curve[map[n]].
; References: 0xFAB96B, 0xFABA74, 0xFABB43, 0xFABC39.  Byte-identical to v142/subcpu/subcpu_data_tables.s:1971.
; Sibling: kn5000 sub-CPU 0x011ADF, v142/subcpu/subcpu_data_tables.s:1971
; ----------------------------------------------------------------------------
Voice_EnvLevel_IndexMap:
	.byte	0x31, 0x31, 0x35, 0x39, 0x3d, 0x41, 0x45, 0x49, 0x4d

; ----------------------------------------------------------------------------
; Voice_VibratoDepth_Table -- 0xFDF243..0xFDF2C2  (128 bytes)
;
; 128 bytes, every entry 0x96 except [49] = 0x88 -- shipped that way in BOTH
; machines, which is itself the strongest possible check that the two tables are
; the same object.  Referenced from 0xFAB847 (and 0xFAB85B, 24-bit).
; Byte-identical to v142/subcpu/subcpu_data_tables.s:1979.
; Sibling: kn5000 sub-CPU 0x011AE8, v142/subcpu/subcpu_data_tables.s:1979
; ----------------------------------------------------------------------------
Voice_VibratoDepth_Table:
	.byte	0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96
	.byte	0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96
	.byte	0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96
	.byte	0x96, 0x88, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96
	.byte	0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96
	.byte	0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96
	.byte	0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96
	.byte	0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96, 0x96

; ----------------------------------------------------------------------------
; Voice_ChromaticBend_Table -- 0xFDF2C3..0xFDF3D6  (276 bytes)
;
; 23 rows x 12 signed bytes.  Rows 0 and 3..21 are zero; rows 1, 2 and 22 carry
; per-semitone corrections.
; ★ The 12-column row stride is proven by prom_c's own code, at 0xFA8046:
;       ld C,(XIX+0x05) / res 0x07,C / div C,0x0c   ; key/12 and key%12
;       ld C,0x0c / mul BC,H / add XBC,XWA
;       add XBC,0x00FDF2C3 / ld A,(XBC) / exts WA / add WA,WA / add DE,WA
; -- row = key/12, column = key%12, the signed byte DOUBLED into the pitch
; accumulator.  That matches the sibling's description exactly (v142/subcpu/subcpu_data_tables.s:2001).
; Sibling: kn5000 sub-CPU 0x011B68, v142/subcpu/subcpu_data_tables.s:2001
; ----------------------------------------------------------------------------
Voice_ChromaticBend_Table:
	; row  0
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; row  1
	.byte	0x13, 0xf0, 0x18, 0x28, 0x03, 0x12, 0xef, 0x16, 0xf4, 0x00, 0x2a, 0x04
	; row  2
	.byte	0x13, 0x3f, 0x18, 0x28, 0x03, 0x12, 0x3b, 0x16, 0x25, 0x00, 0x2a, 0x04
	; row  3
	.byte	0xf8, 0x0a, 0xfd, 0xf1, 0x03, 0xf6, 0x08, 0xfb, 0x0d, 0x00, 0xf4, 0xf1
	; row  4
	.byte	0x0f, 0x03, 0x05, 0x08, 0x03, 0x0d, 0x00, 0x0a, 0x05, 0x00, 0x0a, 0xfd
	; row  5
	.byte	0x0d, 0x00, 0x04, 0x05, 0x03, 0x0a, 0x00, 0x09, 0x03, 0x00, 0x08, 0x05
	; row  6
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; row  7
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; row  8
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; row  9
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; row 10
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; row 11
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; row 12
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; row 13
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; row 14
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; row 15
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; row 16
	.byte	0x00, 0x00, 0x00, 0x00, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc0
	; row 17
	.byte	0x00, 0x00, 0x00, 0x00, 0xc0, 0x00, 0x00, 0x00, 0x00, 0xc0, 0x00, 0x00
	; row 18
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc0, 0x00, 0x00, 0x00, 0x00, 0xc0
	; row 19
	.byte	0x00, 0x00, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc0, 0x00, 0x00
	; row 20
	.byte	0x00, 0xc0, 0x00, 0x00, 0x00, 0x00, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00
	; row 21
	.byte	0x00, 0x00, 0x51, 0x00, 0x00, 0xef, 0x00, 0x32, 0x00, 0x60, 0x00, 0x00
	; row 22
	.byte	0x00, 0x00, 0xd6, 0x00, 0x0f, 0x2f, 0x00, 0xeb, 0x00, 0x2d, 0x00, 0x00

; ----------------------------------------------------------------------------
; Voice_KeyShiftRamp_Steps -- 0xFDF3D7..0xFDF3F0  (26 bytes)
;
; 26 signed bytes.  KEY SHIFT / transpose ramp: entry [0] seeds the ramp at -127
; (0x81) and the ramp self-terminates on the 0x00 entries at [24] and [25].
; No literal reference to this address was found in prom_c -- like the bend curves
; it is presumably reached as an offset from its neighbour, but that is NOT traced.
; Byte-identical to v142/subcpu/subcpu_data_tables.s:2030.
; Sibling: kn5000 sub-CPU 0x011C7C, v142/subcpu/subcpu_data_tables.s:2030
; ----------------------------------------------------------------------------
Voice_KeyShiftRamp_Steps:
	.byte	0x81, 0x81, 0x8b, 0x99, 0xa6, 0xb2, 0xbb, 0xc2, 0xc9, 0xcf, 0xd5, 0xdb, 0xe0, 0xe4, 0xe7, 0xe9
	.byte	0xec, 0xee, 0xf1, 0xf3, 0xf5, 0xf7, 0xf9, 0xfb, 0x00, 0x00

; ----------------------------------------------------------------------------
; Voice_CC_VolumeCurve -- 0xFDF3F1..0xFDF4F0  (256 bytes)
;
; 128 u16, a non-linear attenuation curve 0xFF01 .. 0x0000 indexed by a 0..0x7F
; controller value (CC 7 volume / CC 11 expression in the sibling).
; References: 0xFAD712, 0xFAD7A9.  Byte-identical to v142/subcpu/subcpu_data_tables.s:2062.
; ★ NOTE THE ALIGNMENT STEP HERE.  Between Voice_KeyShiftRamp_Steps and this table
;   the WSA1-to-KN5000 offset moves by exactly 0x80, because the KN5000's 128-byte
;   Voice_AltNoteMap_Curve (v142/subcpu/subcpu_data_tables.s:2040) has NO counterpart in the WSA1 image.
; Sibling: kn5000 sub-CPU 0x011D16, v142/subcpu/subcpu_data_tables.s:2062
; ----------------------------------------------------------------------------
Voice_CC_VolumeCurve:
	.short	0xff01, 0xff20, 0xff40, 0xff52, 0xff60, 0xff6a, 0xff73, 0xff7a
	.short	0xff80, 0xff85, 0xff8a, 0xff8f, 0xff93, 0xff96, 0xff9a, 0xff9d
	.short	0xffa0, 0xffa3, 0xffa5, 0xffa8, 0xffaa, 0xffad, 0xffaf, 0xffb1
	.short	0xffb3, 0xffb5, 0xffb7, 0xffb8, 0xffba, 0xffbc, 0xffbd, 0xffbf
	.short	0xffc0, 0xffc2, 0xffc3, 0xffc4, 0xffc6, 0xffc7, 0xffc8, 0xffc9
	.short	0xffca, 0xffcc, 0xffcd, 0xffce, 0xffcf, 0xffd0, 0xffd1, 0xffd2
	.short	0xffd3, 0xffd4, 0xffd5, 0xffd6, 0xffd7, 0xffd8, 0xffd8, 0xffd9
	.short	0xffda, 0xffdb, 0xffdc, 0xffdc, 0xffdd, 0xffde, 0xffdf, 0xffe0
	.short	0xffe0, 0xffe1, 0xffe2, 0xffe2, 0xffe3, 0xffe4, 0xffe4, 0xffe5
	.short	0xffe6, 0xffe6, 0xffe7, 0xffe8, 0xffe8, 0xffe9, 0xffe9, 0xffea
	.short	0xffeb, 0xffeb, 0xffec, 0xffec, 0xffed, 0xffed, 0xffee, 0xffee
	.short	0xffef, 0xfff0, 0xfff0, 0xfff1, 0xfff1, 0xfff2, 0xfff2, 0xfff3
	.short	0xfff3, 0xfff4, 0xfff4, 0xfff4, 0xfff5, 0xfff5, 0xfff6, 0xfff6
	.short	0xfff7, 0xfff7, 0xfff8, 0xfff8, 0xfff8, 0xfff9, 0xfff9, 0xfffa
	.short	0xfffa, 0xfffb, 0xfffb, 0xfffb, 0xfffc, 0xfffc, 0xfffd, 0xfffd
	.short	0xfffd, 0xfffe, 0xfffe, 0xffff, 0xffff, 0xffff, 0x0000, 0x0000

; ----------------------------------------------------------------------------
; DSP_AlgoDescriptor_Records -- 0xFDF4F1..0xFDF6C4  (468 bytes)
;
; 12 records x 39 bytes (stride 0x27), indexed by algorithm type.
; ★ THE RECORD COUNT DIFFERS FROM THE KN5000 AND THE DIFFERENCE IS SELF-PROVING.
;   The KN5000 has 14 records (v142/subcpu/subcpu_data_tables.s:2084); the WSA1 has 12.  Nothing was assumed:
;   the byte run that is identical to the sibling ends 78 bytes early, 78 = 2*39,
;   and the next table starts exactly there.  Two fewer algorithm types.
;   (The sibling notes its own types 12/13 are all-zero -- the two that are gone.)
; Field offsets located by the sibling, not re-verified here: +0x00/+0x01/+0x1A
; copied to a part record; +0x02 top two bits index EGEnv_ModeBits_Table; +0x06 a
; packet sub-index; +0x0D bit 7 selects the +0x0E byte; +0x13 + 5*channel a
; per-channel flag.  References: 0xFB5994, 0xFB5B15, 0xFB5C39, 0xFB5DC2.
; Sibling: kn5000 sub-CPU 0x011E16, v142/subcpu/subcpu_data_tables.s:2084
; ----------------------------------------------------------------------------
DSP_AlgoDescriptor_Records:
	; type  0
	.byte	0x0f, 0x19, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x44, 0x00, 0x00, 0x00, 0x00, 0x88, 0x00, 0x0a, 0x64, 0x00, 0x44, 0x00, 0x00
	.byte	0x00, 0x00, 0x88, 0x00, 0x00, 0x00, 0x00
	; type  1
	.byte	0x0c, 0x25, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0xc4, 0x00, 0x00, 0x00, 0x00, 0xc8, 0x00, 0x11, 0x64, 0x01, 0xc4, 0x00, 0x00
	.byte	0x00, 0x00, 0xc8, 0x00, 0x00, 0x00, 0x00
	; type  2
	.byte	0x0c, 0x25, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x44, 0x00, 0x00, 0x00, 0x00, 0x88, 0x00, 0x0a, 0x64, 0x00, 0x44, 0x00, 0x00
	.byte	0x00, 0x00, 0x88, 0x00, 0x00, 0x00, 0x00
	; type  3
	.byte	0x0a, 0x28, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0xc8, 0x00, 0x00, 0x00, 0x00, 0xc4, 0x00, 0x08, 0x64, 0x01, 0xc8, 0x00, 0x00
	.byte	0x00, 0x00, 0xc4, 0x00, 0x00, 0x00, 0x00
	; type  4
	.byte	0x19, 0x20, 0x00, 0x19, 0x21, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x88, 0x00, 0x00, 0x00, 0x00, 0x44, 0x00, 0x0a, 0x00, 0x04, 0x44, 0x00, 0x00
	.byte	0x00, 0x00, 0x88, 0x00, 0x00, 0x00, 0x00
	; type  5
	.byte	0x14, 0x14, 0x00, 0x0f, 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0xc8, 0x00, 0x00, 0x00, 0x00, 0xc4, 0x00, 0x02, 0x00, 0x00, 0xc8, 0x00, 0x00
	.byte	0x00, 0x00, 0xc4, 0x00, 0x00, 0x00, 0x00
	; type  6
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x28, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x22, 0x00, 0x00, 0x50, 0x00, 0x20, 0x00, 0x00
	.byte	0x00, 0x00, 0x22, 0x00, 0x00, 0x00, 0x00
	; type  7
	.byte	0x1c, 0x28, 0x00, 0x22, 0x19, 0x00, 0x19, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0xe4, 0x00, 0x00, 0x00, 0x00, 0xea, 0x00, 0x00, 0x00, 0x00, 0xe4, 0x00, 0x00
	.byte	0x00, 0x00, 0xea, 0x00, 0x00, 0x00, 0x00
	; type  8
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x50, 0x0a, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; type  9
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1b, 0x14, 0x16, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	; type 10
	.byte	0x14, 0x32, 0xb2, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x1e, 0x80, 0x00, 0x00, 0x00, 0x00, 0x88, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00
	.byte	0x00, 0x00, 0x88, 0x00, 0x00, 0x00, 0x00
	; type 11
	.byte	0x14, 0x32, 0xb2, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00
	.byte	0x00, 0x00, 0x1e, 0x80, 0x00, 0x00, 0x00, 0x00, 0x88, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00
	.byte	0x00, 0x00, 0x88, 0x00, 0x00, 0x00, 0x00

; ----------------------------------------------------------------------------
; Voice_SecondaryParam_Curve -- 0xFDF6C5..0xFDF6E3  (31 bytes)
;
; 31 bytes descending 0x46..0x00 (70..0).  References: 0xFB0D42, 0xFB0FD8,
; 0xFB11E7, 0xFB146C.  Byte-identical to v142/subcpu/subcpu_data_tables.s:2198.
; Sibling: kn5000 sub-CPU 0x012038, v142/subcpu/subcpu_data_tables.s:2198
; ----------------------------------------------------------------------------
Voice_SecondaryParam_Curve:
	.byte	0x46, 0x40, 0x3a, 0x35, 0x30, 0x2c, 0x28, 0x24, 0x21, 0x1e, 0x1b, 0x18, 0x16, 0x14, 0x12, 0x10
	.byte	0x0e, 0x0d, 0x0c, 0x0b, 0x0a, 0x09, 0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0x00

; ----------------------------------------------------------------------------
; Voice_SecondaryParam_WordCurveA -- 0xFDF6E4..0xFDF721  (62 bytes)
;
; 31 s16: 0xFF00 then -62..0.  Indexed by a parameter byte * 2.
; References: 0xFB0D5F, 0xFB0D99, 0xFB0FF2, 0xFB1026.  Byte-identical to v142/subcpu/subcpu_data_tables.s:2208.
; Sibling: kn5000 sub-CPU 0x012057, v142/subcpu/subcpu_data_tables.s:2208
; ----------------------------------------------------------------------------
Voice_SecondaryParam_WordCurveA:
	.short	0xff00, 0xffc2, 0xffc6, 0xffca, 0xffce, 0xffd2, 0xffd6, 0xffd9
	.short	0xffdc, 0xffdf, 0xffe2, 0xffe4, 0xffe6, 0xffe8, 0xffea, 0xffec
	.short	0xffee, 0xfff0, 0xfff2, 0xfff4, 0xfff6, 0xfff7, 0xfff8, 0xfff9
	.short	0xfffa, 0xfffb, 0xfffc, 0xfffd, 0xfffe, 0xffff, 0x0000

; ----------------------------------------------------------------------------
; Voice_SecondaryParam_WordCurveB -- 0xFDF722..0xFDF75F  (62 bytes)
;
; 31 s16: 0xFF00 then -116..0 in steps of 4.  References: 0xFB0D7C, 0xFB100C,
; 0xFB121B, 0xFB14B4.  Byte-identical to v142/subcpu/subcpu_data_tables.s:2217.
; Sibling: kn5000 sub-CPU 0x012095, v142/subcpu/subcpu_data_tables.s:2217
; ----------------------------------------------------------------------------
Voice_SecondaryParam_WordCurveB:
	.short	0xff00, 0xff8c, 0xff90, 0xff94, 0xff98, 0xff9c, 0xffa0, 0xffa4
	.short	0xffa8, 0xffac, 0xffb0, 0xffb4, 0xffb8, 0xffbc, 0xffc0, 0xffc4
	.short	0xffc8, 0xffcc, 0xffd0, 0xffd4, 0xffd8, 0xffdc, 0xffe0, 0xffe4
	.short	0xffe8, 0xffec, 0xfff0, 0xfff4, 0xfff8, 0xfffc, 0x0000

; ----------------------------------------------------------------------------
; ExpCurve_0_to_0x80 -- 0xFDF760..0xFDF7DF  (128 bytes)
;
; 128 bytes rising 0x00 -> 0x80 with an exponential shape (flat 0x01 for 24
; entries, then accelerating; the last 16 steps are 0x43 0x46 0x49 ... 0x7B 0x80).
; WSA1-only -- no counterpart anywhere in the KN5000 payload.
; Four references: 0xFC51CA, 0xFC6E75, 0xFC70A1, 0xFC72E3 -- note these sit in a
; different part of the image from every other table here, so this one belongs to
; another subsystem.  Which one is NOT ESTABLISHED.
; ----------------------------------------------------------------------------
ExpCurve_0_to_0x80:
	.byte	0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	.byte	0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02
	.byte	0x02, 0x02, 0x02, 0x02, 0x02, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x04, 0x04, 0x04, 0x04
	.byte	0x04, 0x04, 0x05, 0x05, 0x05, 0x05, 0x05, 0x06, 0x06, 0x06, 0x06, 0x07, 0x07, 0x07, 0x08, 0x08
	.byte	0x08, 0x09, 0x09, 0x0a, 0x0a, 0x0a, 0x0b, 0x0b, 0x0c, 0x0c, 0x0d, 0x0d, 0x0e, 0x0f, 0x0f, 0x10
	.byte	0x11, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1f, 0x20
	.byte	0x21, 0x23, 0x24, 0x26, 0x28, 0x29, 0x2b, 0x2d, 0x2f, 0x31, 0x34, 0x36, 0x38, 0x3b, 0x3d, 0x40
	.byte	0x43, 0x46, 0x49, 0x4c, 0x4f, 0x53, 0x57, 0x5b, 0x5f, 0x63, 0x67, 0x6c, 0x70, 0x75, 0x7b, 0x80

; ==============================================================================
; 0xFDF7E0-0xFFEFFF -- not yet converted
; ==============================================================================
; Begins with 94 bytes of zero fill, then a `08 00` repeating block at 0xFDF83E.
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x05F7E0, 0x01F820

; ==============================================================================
; RESET -- 0xFFF000, the address in the reset vector at 0xFFFF00
; ==============================================================================
;
; Same shape as CPU 1's boot block but shorter, and in a different order: this
; one sets a stack up front, so it can and does call.
;
RESET:
	; --- watchdog off ------------------------------------------------------
	ldio WDMOD,0x00
	ldio WDCR,0xB1

	; --- stack, at the top of the 128 KiB CS3 DRAM block -------------------
	ld XSP,0x0000FFF0
	ldio IIMC,0x04
	ldio INTETC01,0x00

	; --- ports -------------------------------------------------------------
	ldio P2FC,0x7F
	ldio P7FC,0x00
	ldio P7CR,0xFF
	ldio P6FC,0x1F		; the same five port-6 alternate functions CPU 1
				; enables: RAS and REFOUT out (DRAM controller
				; live) and the CS3 pin as LCAS, so the CS3 area
				; is the DRAM area on this CPU too.
	ldio P5,0x1D
	ldio P5FC,0x04
	ldio P5CR,0x3C
	ldio PA,0xFF
	ldio PAFC,0x00
	ldio PACR,0x03		; PA bits 0 and 1 driven out -- MAME masks the
				; port write with PnCR (tmp95c061.cpp:107).
				; PA0 is the strobe and PA3 the busy input of the
				; link to CPU 1 (0xF99AE0 res 0,(PA) /
				; 0xF99AFF set 0,(PA); 0xF999D0 and 0xF99A06
				; bit 3,(PA)).
	ldio PB,0xFB
	ldio PBFC,0x00
	ldio PBCR,0x7E

	; --- memory controller -------------------------------------------------
	; MSARn = A23-A16 of the block start.  MSAR0 = 0x10 is the one place in
	; either image where the meaning of MSAR is PROVEN rather than assumed:
	; 0x2F bytes further down this same routine, `ld XIX,0x00100000` loads
	; the base of the device cluster that CS0 must be selecting.
	ldio MSAR0,0x10		; CS0 -> 0x100000: link port + three address/data
				; device ports (0x104000, 0x108000, 0x10C000)
	ldio MAMR0,0x07
	ldio MSAR1,0xC0		; CS1 -> 0xC00000: the expansion board.  Its
				; header carries the ASCII signature "WSA1 EXTBD",
				; which also appears twice in this ROM (file
				; 0x6129E and 0x61EC9) as the string it is
				; compared against.
	ldio MAMR1,0x7F
	ldio MSAR2,0xE0		; CS2 -> 0xE00000: an address/data register pair
				; at 0xE00000, the 512 KiB flash at 0xE80000, and
				; this EPROM at 0xF80000
	ldio MAMR2,0x3F
	ldio MSAR3,0x00		; CS3 -> 0x000000: work DRAM
	ldio MAMR3,0x03	; MAMR = window size, 32 KB per unit.  See the long note
			; in prom_a/wsa1_prom_a.s and
			; scripts/analysis/mamr_reading_elimination.py: eight
			; candidate decoders are tested against this firmware's
			; own facts and six die.  Unlike CPU 1, both survivors
			; give IDENTICAL windows here, so these four rows carry
			; no residual ambiguity:
			;   MAMR0 0x07 -> 256 KB   CS0 0x100000-0x13FFFF
			;   MAMR1 0x7F -> 4 MB     CS1 0xC00000-0xFFFFFF, of
			;                          which CS2 takes the top half
			;   MAMR2 0x3F -> 2 MB     CS2 0xE00000-0xFFFFFF
			;   MAMR3 0x03 -> 128 KB   CS3 0x000000-0x01FFFF
			; ⚠ Still NOT ESTABLISHED: the BnCS/BEXCS bit layout and
			; every DREFCR/DMEMCR field.

	ldio B0CS,0x10
	ldio B1CS,0x14
	ldio B2CS,0x1B
	ldio B3CS,0x1B
	ldio BEXCS,0x00
	ldio DREFCR,0x71	; refresh enabled, same value as CPU 1
	ldio DMEMCR,0x89	; CPU 1 uses 0x8D.  Neither is decoded anywhere.

	; --- first touch of the CS0 device cluster -----------------------------
	; This is the pair that proves MSAR0: the base just programmed as 0x10
	; is loaded here as a full 24-bit address.
	ldb E,0x01
	ld XIX,0x00100000

	; --- timers, ports, serial ---------------------------------------------
	ldio T01MOD,0x0D
	ldio P8CR,0x19
	ldio P8FC,0x01
	ldio TRUN,0x80		; prescaler run only (bit 7); no timer started here
	ldio BR0CR,0x13	; boot value: divide by 768, the 24 MHz constant.
			; ⚠ NOT the operative one.  0xF991A2, reached from the
			; init chain at 0xF98B7D, recomputes it from the
			; configuration byte at 0xFFFFEF (see CLOCK_CONFIG_MHZ
			; at the bottom of this file): BR0CR = (M >> 1) & 0x0F,
			; which for M = 0x1C gives 0x0E, i.e. divide by 896.
			; The firmware's own rule makes the bit rate come out
			; at 31250 for any M, so M is literally fc in MHz.
	ldio SC0CR,0x00
	ldio SC0MOD,0x09	; 8-bit UART, baud-rate generator; unlike CPU 1
				; the receiver is not enabled here
	call 0xF99125		; ⚠ NOT a delay.  Earlier text here called it "a counted
				; delay (loops to 0x40)".  It is
				; Dev108000_Preload_80toBF, converted above: 64
				; write pairs into the device port at 0x108000.

	; --- clear work DRAM, 0x000080-0x01007F --------------------------------
	; 0x8000 stores of 2 bytes = 64 KiB starting just above the internal I/O
	; registers.  As on CPU 1, this is a lower bound on the DRAM, not its
	; size.
	ld XBC,0x00008000
	lda_dd8l XIX,0x80		; lda XIX,0x80
	xor WA,WA
RESET__clear_dram:
	stw_dpi WA,MEM_XIX_PI2		; ld (XIX+),WA
	sub XBC,0x00000001
	jr NZ,RESET__clear_dram

	call 0xF989EF		; ⚠ 0x10D8 bytes, not 0xD8 -- earlier text here said
				; 0xD8.  `ld XBC,0x000010D8` sets BC = 4312 and
				; `ldir` copies that many bytes from 0xFCB4EA to
				; 0x00E2DF.  This is the RAM IMAGE: it initialises
				; 0x00E2DF-0x00F3B6, which is where the tick
				; counter, the scheduler phase and the touch
				; controls all live.  See
				; notes/FINDINGS-prom_c-ram-image.md.
	jp 0xF9816B		; main entry: `ld XSP,0x0000FA00`, then the
				; main loop.  Note it moves the stack down from
				; the 0xFFF0 the boot block used.

; ==============================================================================
; 0xFFF0A2 -- interrupt trampolines
; ==============================================================================
; Every entry in the vector table at 0xFFFF00 points either into this block or
; straight at a handler elsewhere in the ROM.  The labels below are named after
; the vector that reaches them; where two vectors share an entry the name says
; so.
;
IRQ_WATCHDOG_REBOOT:			; vector 0x24 (INTWD)
	jrl RESET
IRQ_SWI1_REBOOT:			; vector 0x04
	jrl RESET
IRQ_UNUSED:				; vectors 0x08-0x1C, 0x30-0x40,
					; 0x50-0x5C, 0x68-0x78
	jp 0xF9816B		; back to the main entry, exactly as the end
				; of RESET does
IRQ_NMI:				; vector 0x20
	ei 0x07
	call 0xF99125
IRQ_NMI__hang:
	jr IRQ_NMI__hang	; spin forever
IRQ_INT0:				; vector 0x28
	jp 0xF99BBE		; -> INT0_HANDLER, converted above
IRQ_INTT2:				; vector 0x48
	jp 0xF99E5E		; -> INTT2_HANDLER, converted above
IRQ_INTT1:				; vector 0x44
	jp 0xF99063		; -> INTT1_HANDLER, converted above: the tick
				; counter at 0x00F2F3 and the six-phase work
				; schedule in 0x007ED1
IRQ_INTTC2:				; vector 0x7C
	jp 0xF99CFE		; -> INTTC2_HANDLER, converted above
IRQ_INTTC3:				; vector 0x80
	jp 0xF99D20		; -> INTTC3_HANDLER, converted above

; ------------------------------------------------------------------------------
; 0xFFF0C8-0xFFF0E4 -- six more entries in the same style that NOTHING reaches.
; A byte scan of all four images for a 24-bit reference to any of these six
; addresses finds none, and no vector points here.  What calls them is NOT
; ESTABLISHED; they may simply be dead.
; ------------------------------------------------------------------------------
UNREFERENCED_TRAMPOLINES:
	ei 0x07
	call 0xF98610
	jrl RESET
	jp 0xF98EFE
	jp 0xF99133
	jp 0xF9854E
	jp 0xF99016
	jp 0xF99038

; ==============================================================================
; 0xFFF0E5-0xFFFEFF -- padding
; ==============================================================================
; 3611 bytes of 0x0E, the one-byte RET opcode.  Verified to contain no other
; byte value.
	.fill 0x0E1B, 1, 0x0E

; ==============================================================================
; 0xFFFF00 -- interrupt vector table
; ==============================================================================
;
; Fetched as a 32-bit little-endian word from 0xFFFF00 + offset
; (tmp95c061.cpp:560).  What is CITED and what is CONVENTION:
;   0x00        cited -- the reset PC is fetched from 0xFFFF00
;               (tlcs900.cpp:215-217)
;   0x20        cited -- NMI, tmp95c061.cpp:505
;   0x28-0x80   cited -- names and offsets from tmp95c061_irq_vector_map[] at
;               tmp95c061.cpp:322-346
;   0x04-0x1C,  CONVENTION.  MAME does not name these slots and no databook is
;   0x24        available in these trees.  This ROM corroborates the shape --
;               0x24 and 0x04 both reboot, which is what INTWD and an
;               undefined-instruction trap would do -- but that is
;               corroboration, not a citation.
;
VECTORS:
	.long 0x00FFF000	; 0x00  RESET
	.long 0x00FFF0A5	; 0x04  SWI1        -> IRQ_SWI1_REBOOT
	.long 0x00FFF0A8	; 0x08  SWI2 / INTUNDEF -> IRQ_UNUSED
	.long 0x00FFF0A8	; 0x0C  SWI3
	.long 0x00FFF0A8	; 0x10  SWI4
	.long 0x00FFF0A8	; 0x14  SWI5
	.long 0x00FFF0A8	; 0x18  SWI6
	.long 0x00FFF0A8	; 0x1C  SWI7
	.long 0x00FFF0AC	; 0x20  NMI         -> IRQ_NMI
	.long 0x00FFF0A2	; 0x24  INTWD       -> IRQ_WATCHDOG_REBOOT
	.long 0x00FFF0B4	; 0x28  INT0        -> IRQ_INT0
	.long 0x00F995C2	; 0x2C  INT4        -> INT4_HANDLER, a bare RETI,
				;                      converted above
	.long 0x00FFF0A8	; 0x30  INT5
	.long 0x00FFF0A8	; 0x34  INT6
	.long 0x00FFF0A8	; 0x38  INT7
	.long 0x00FFF0A8	; 0x3C  (reserved; MAME skips this slot)
	.long 0x00FFF0A8	; 0x40  INTT0
	.long 0x00FFF0BC	; 0x44  INTT1       -> IRQ_INTT1 -> INTT1_HANDLER
	.long 0x00FFF0B8	; 0x48  INTT2       -> IRQ_INTT2.  This is the
				;                      interrupt CPU 2's micro-DMA
				;                      channel 2 is armed on at
				;                      0xF99A2A (DMA2V = 0x12,
				;                      0x12<<2 = 0x48).
	.long 0x00F98165	; 0x4C  INTT3       -> INTT3_HANDLER, converted
				;                      above.  Timer 3 is started
				;                      by Timer3_Init (0xF98B6D)
	.long 0x00FFF0A8	; 0x50  INTTR4
	.long 0x00FFF0A8	; 0x54  INTTR5
	.long 0x00FFF0A8	; 0x58  INTTR6
	.long 0x00FFF0A8	; 0x5C  INTTR7
	.long 0x00F991FF	; 0x60  INTRX0     -> INTRX0_HANDLER (MIDI in)
	.long 0x00F99265	; 0x64  INTTX0     -> INTTX0_HANDLER (MIDI out)
	.long 0x00FFF0A8	; 0x68  INTRX1
	.long 0x00FFF0A8	; 0x6C  INTTX1
	.long 0x00FFF0A8	; 0x70  INTAD
	.long 0x00FFF0A8	; 0x74  INTTC0
	.long 0x00FFF0A8	; 0x78  INTTC1
	.long 0x00FFF0C0	; 0x7C  INTTC2      -> IRQ_INTTC2
	.long 0x00FFF0C4	; 0x80  INTTC3      -> IRQ_INTTC3

; ==============================================================================
; 0xFFFF84-0xFFFFEE -- padding
; ==============================================================================
	.fill 0x6B, 1, 0x0E

; ==============================================================================
; 0xFFFFEF -- fc in MHz, as a byte
; ==============================================================================
; The UART init at 0xF991A2 reads this byte and computes
;   BR0CR = (M >> 1) & 0x0F
; With the baud-rate generator's fc/4 tap and the UART's own divide by 16 that
; makes the bit rate fc / (32*M), so a bit rate of 31250 comes out for ANY M
; provided fc = 1,000,000 * M.  M = 0x1C = 28 therefore asserts fc = 28 MHz in
; the ROM itself, without anyone having to decide which of several BR0CR writes
; is the operative one.  This byte is the ONLY value in the 0x6C-byte RET run
; that is not 0x0E.  See notes/FINDINGS-system-clock.md.
CLOCK_CONFIG_MHZ:
	.byte 0x1C

; ==============================================================================
; 0xFFFFF0 -- build tag
; ==============================================================================
BUILD_TAG:
	.ascii "wsac_230"
	.byte 0x02
	.ascii "ssf"
	.byte 0x00, 0x00, 0x00, 0x00
end:
