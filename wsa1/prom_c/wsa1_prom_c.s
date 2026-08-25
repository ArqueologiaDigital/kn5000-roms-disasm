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
;   0xFB7715-0xFB7B62  ★★ the driver for the SECOND register device, 0x00104000
;                      -- its COMPLETE 19-register per-channel map -- and
;                      0x0010C000's thirteen GLOBAL registers
;   0xFB7B63-0xFB828D  ★★ the SECOND 0x0010C000 driver -- the bit-15 gate
;                      strobe, the three-slot per-channel structure, the identity
;                      that explains the `chan >= 0x40` split, and
;                      Dev10C_ResetAllChannels, which fixes the CHANNEL COUNT AT 64
;                      with a loop counter and names the ROM block the staging
;                      struct is initialised from
;   0xFC856C-0xFC89C4  ★★ THE FLASH DRIVER -- 16 routines: the JEDEC command
;                      sequences, the 512 KiB device's TWO boot-block sector maps,
;                      the 64 KiB staging buffer at 0x00010000, and the six
;                      routines the inter-processor link's three deferred jobs
;                      call.  This is what the link is FOR
;   0xFACE67-0xFAD141  ★ the register writers for the device at 0x0010C000 --
;                      17 routines that establish the port's shape {select,
;                      write data, read data} and the `channel + K*0x40` register
;                      map.  0x0010C000 is CPU 2's busiest device (102 sites)
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
;          looks like and not what a subroutine looks like.  It also starts with
;          `di` -- ⚠ WHICH IS NOT A DISABLE.  llvm-mc's `di` assembles to `06 00`,
;          and `06 00` is `EI 0`: op_EI writes the immediate into SR bits 6..4
;          (mame/src/devices/cpu/tlcs900/900tbl.hxx:2073-2078) and
;          tlcs900_check_irqs scans priorities from `max(1, (SR>>4)&7)` up to 6
;          (tmp95c061.cpp:536-545), so a level of 0 accepts EVERY maskable
;          interrupt and a level of 7 accepts none.  Reset leaves the field at 7
;          (`m_sr.d = 0xf800`, "iff set to 111", tlcs900.cpp:213-220).  So this
;          instruction ENABLES interrupts, and `ei 0x07` -- used in IRQ_NMI just
;          before its infinite spin -- is the one that disables them.
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
; ==============================================================================
; 0xF98CB9-0xF99062 -- KEY EVENTS BECOME MIDI, and the FOUR link-channel handlers
;                      5 routines and one 16-entry jump table, 938 bytes
; ==============================================================================
;
; ★★ THE KEYBOARD IS SENT TO CPU 1 AS MIDI NOTE-ON MESSAGES.
; KeyEvents_ToLink builds a buffer of 3-byte groups
;
;       0x90 , note , velocity
;
; -- the byte 0x90 is a literal in the code (`ld (XBC+0xde),0x90` at 0xF98D24) --
; and hands the whole buffer to Link_SendBlock on channel 5.  0x90 is MIDI's
; Note-On status for channel 1, and the two bytes after it are exactly what
; ToneGen_VelocityFromTouch was made to produce.
;
; ★ THAT CLOSES THREE THINGS THIS FILE ALREADY WONDERED ABOUT, and each one is a
; separate check that lands on the same reading:
;   1. ToneGen_VelocityFromTouch's header notes that its output curve "spans 1..127
;      over all 256 entries and never reaches 0 or 128", i.e. a velocity that can
;      never be a note-off by accident.  In MIDI, note-on with velocity 0 IS a
;      note-off -- and KeyScan_ReadEvent forces the velocity byte to 0 on exactly
;      the note-OFF path (0xF997CE).  The curve's floor of 1 is what keeps that
;      encoding unambiguous.
;   2. The same header asks why the note is transposed by +36.  36 = MIDI note C2,
;      so keys 0..60 become MIDI notes 36..96 = C2..C7 -- the range of a 61-key
;      instrument, and 61 is the key count NoteTrim_BuildFromCalibration walks.
;   3. It also asks what the two pointer arguments are for.  They point into this
;      routine's frame buffer, one 3-byte group apart.
;
; ⚠ "MIDI" here is the ENCODING of the message, not a claim about where it goes:
; the buffer is handed to the inter-processor link, not to the UART.  The UART
; path is the separate drain in MAIN that uses channel 6.
;
; ★ THE FOUR LINK-CHANNEL HANDLERS ARE THESE FOUR ROUTINES.
; Handler_PtrTable_FCC53F (further down this file) is 8 x u32 and its header ends
; "⚠ Still not established: what the four real class handlers DO".  Its first four
; entries are 0xF98D9A, 0xF98DE6, 0xF98FD6 and 0xF9901B -- the four routines below
; -- and its last four are all 0xF9993D, the `ret` now labelled
; Link_ChannelHandler_Ignore.  INTTC3_HANDLER__state1_generic indexes the table's
; RAM copy at 0x00F334 with (command byte >> 5), so:
;
;     link channel 0 -> Link_Ch0_AppendToRing       bytes into a 4096-byte ring
;     link channel 1 -> Link_Ch1_WriteParamBlock    16 sub-commands, 4 param blocks
;     link channel 2 -> Link_Ch2_ForwardBytes       byte stream, 0xFA intercepted
;     link channel 3 -> Link_Ch3_SetTouchControl    the two touch controls
;     link channels 4-7 -> discarded
;
; and the two channels CPU 2 SENDS on -- 5 and 6 -- are among the four it ignores
; when receiving, which is what a one-way channel assignment looks like.
;
; ⚠ WHAT IS NOT ESTABLISHED HERE: what CPU 1 does with the note-on stream; what
; the four parameter blocks at 0x00007E7E, 0x00007E98, 0x00007EB2 and 0x00007ECD
; control; and what 0xF992C6 (the per-byte sink of channel 2) does with a byte.
;
; Transcribed with notes/llvm_roundtrip_autoforce.py c 0xF98CB9 0x3AA, restyled by
; notes/prom_c_listing_prep.py, the jump table replaced by `.long` entries by hand,
; and re-proved before insertion with
; `python3 notes/prom_c_verify_fragment.py c 0xF98CB9 <file>`.

; --------------------------------------------------------------------------
; ★★ KeyEvents_ToLink -- drain the key scanner and the MIDI receive queue, and
;             send each as a link packet.
;
; Called from: 0xF98CA1 (`calr 0xF98CB9`, inside MAIN's per-pass tail) and six
;          `call 0xF98CB9` sites at 0xFB09FE, 0xFB3740, 0xFB384D, 0xFB39D7,
;          0xFB3ADF and 0xFB3BF8.  notes/prom_c_xrefs.py 0xF98CB9.
; Inputs:  none.  Globals: the flush counter at 0x00E2E1.
; Outputs: up to ten 3-byte MIDI note-on groups on link channel 5, and up to 32
;          raw MIDI bytes on link channel 6.
; Evidence, step by step off the instructions:
;   * FLUSH MODE.  If the 16-bit value at 0x00E2E1 is > 0, the routine drains the
;     scanner into the SAME two frame bytes over and over until KeyScan_ReadEvent
;     returns 0xFFFF, decrements 0x00E2E1, and returns without sending anything.
;     So a positive 0x00E2E1 means "throw the keyboard away this pass".
;   * NORMAL MODE.  `i = 0`; each pass calls KeyScan_ReadEvent with pointers
;     `frame+i+1` and `frame+i+2`, and on success writes `frame+i = 0x90` and
;     `i += 3`.  The loop stops on 0xFFFF or when `i` reaches 0x1E = 30, so the
;     buffer holds at most TEN groups.  30 / 3 = 10, and the bound is a literal.
;   * `Link_SendBlock(channel 5, i, frame)` if i != 0.
;   * Then the identical shape for MIDI_Rx_Dequeue: up to 0x20 = 32 bytes into the
;     same frame buffer, then `Link_SendBlock(channel 6, i, frame)`.
; ⚠ The two drains SHARE the frame buffer and the counter at (XIZ-0x23); the
;   second sets it back to 0 first (0xF98D4E).  Nothing is left over between them.
; ⚠ MAIN has its OWN channel-6 drain (the loop at 0xF98BC1, whose MIDI_Rx_Dequeue
;   call is at 0xF98BC6, converted above) that does the same thing with the same
;   32-byte bound.  Two drains of one queue, in one
;   loop body, is what the code says; why is not established.
; Unknown:  what writes 0x00E2E1 (it is inside the boot RAM image, so its power-on
;          value is readable with notes/prom_c_ram_image.py, but no writer has been
;          found in converted code); what CPU 1 does with channel 5.
; --------------------------------------------------------------------------
KeyEvents_ToLink:
	link32 0xEE, 0x0C, 0xDD, 0xFF          ; F98CB9  link XIZ,0xffdd   [llvm-mc cannot encode this]
	pushw	hl                               ; F98CBD  push HL
	push	xix                               ; F98CBE  push XIX
	extpfx7 0xD2, 0xE1, 0xE2, 0x00, 0x3F, 0x00, 0x00 ; F98CBF  cp (0x00e2e1),0x0000   [llvm-mc cannot encode this]
	jr le, KeyEvents_ToLink__F98CEA                       ; F98CC6  jr LE,0xf98cea
KeyEvents_ToLink__F98CC8:
	lda	xbc, (xiz-34)                      ; F98CC8  lda XBC,XIZ+0xde
	inc	2, xbc                             ; F98CCB  inc 2,XBC
	push	xbc                               ; F98CCD  push XBC
	lda	xbc, (xiz-34)                      ; F98CCE  lda XBC,XIZ+0xde
	inc	1, xbc                             ; F98CD1  inc 1,XBC
	push	xbc                               ; F98CD3  push XBC
	call	0xF9973D                          ; F98CD4  call 0xf9973d
	inc	8, xsp                             ; F98CD8  inc 0,XSP
	cp	wa, 0xFFFF                          ; F98CDA  cp WA,0xffff
	jr z, KeyEvents_ToLink__F98CE2                        ; F98CDE  jr Z,0xf98ce2
	jr KeyEvents_ToLink__F98CC8                           ; F98CE0  jr T,0xf98cc8
KeyEvents_ToLink__F98CE2:
	decdi16_24	1, (0xE2E1)                 ; F98CE2  decw 1,(0x00e2e1)
	jrl KeyEvents_ToLink__F98D4E                          ; F98CE7  jrl T,0xf98d4e
KeyEvents_ToLink__F98CEA:
	ld	(xiz-35), 0                         ; F98CEA  ld (XIZ+0xdd),0x00
KeyEvents_ToLink__F98CEE:
	ld	ix, (xiz-35)                        ; F98CEE  ld IX,(XIZ+0xdd)
	extz	ix                                ; F98CF1  extz IX
	extz	xix                               ; F98CF3  extz XIX
	ld	xbc, xix                            ; F98CF5  ld XBC,XIX
	inc	2, xbc                             ; F98CF7  inc 2,XBC
	add	xbc, xiz                           ; F98CF9  add XBC,XIZ
	add	xbc, 0xFFFFFFDE                    ; F98CFB  add XBC,0xffffffde
	push	xbc                               ; F98D01  push XBC
	ld	xbc, xix                            ; F98D02  ld XBC,XIX
	inc	1, xbc                             ; F98D04  inc 1,XBC
	add	xbc, xiz                           ; F98D06  add XBC,XIZ
	add	xbc, 0xFFFFFFDE                    ; F98D08  add XBC,0xffffffde
	push	xbc                               ; F98D0E  push XBC
	call	0xF9973D                          ; F98D0F  call 0xf9973d
	inc	8, xsp                             ; F98D13  inc 0,XSP
	cp	wa, 0xFFFF                          ; F98D15  cp WA,0xffff
	jr z, KeyEvents_ToLink__F98D35                        ; F98D19  jr Z,0xf98d35
	ld	bc, (xiz-35)                        ; F98D1B  ld BC,(XIZ+0xdd)
	extz	bc                                ; F98D1E  extz BC
	extz	xbc                               ; F98D20  extz XBC
	add	xbc, xiz                           ; F98D22  add XBC,XIZ
	ld	(xbc-34), 0x90                      ; F98D24  ld (XBC+0xde),0x90
	incm8	3, (xiz-35)                      ; F98D28  inc 3,(XIZ+0xdd)
	cp (xiz-35), 0x1E                      ; F98D2B  cp (XIZ+0xdd),0x1e   [llvm-mc cannot encode this]
	jr nz, KeyEvents_ToLink__F98D33                       ; F98D2F  jr NZ,0xf98d33
	jr KeyEvents_ToLink__F98D35                           ; F98D31  jr T,0xf98d35
KeyEvents_ToLink__F98D33:
	jr KeyEvents_ToLink__F98CEE                           ; F98D33  jr T,0xf98cee
KeyEvents_ToLink__F98D35:
	cp (xiz-35), 0x00                      ; F98D35  cp (XIZ+0xdd),0x00   [llvm-mc cannot encode this]
	jr z, KeyEvents_ToLink__F98D4E                        ; F98D39  jr Z,0xf98d4e
	lda	xbc, (xiz-34)                      ; F98D3B  lda XBC,XIZ+0xde
	push	xbc                               ; F98D3E  push XBC
	ld	wa, (xiz-35)                        ; F98D3F  ld WA,(XIZ+0xdd)
	extz	wa                                ; F98D42  extz WA
	pushw	wa                               ; F98D44  push WA
	pushw	5                                ; F98D45  push 0x0005
	call	0xF9997E                          ; F98D48  call 0xf9997e
	inc	8, xsp                             ; F98D4C  inc 0,XSP
KeyEvents_ToLink__F98D4E:
	ld	(xiz-35), 0                         ; F98D4E  ld (XIZ+0xdd),0x00
KeyEvents_ToLink__F98D52:
	call	0xF991F4                          ; F98D52  call 0xf991f4
	ld	hl, wa                              ; F98D56  ld HL,WA
	ld	(xiz-2), wa                         ; F98D58  ld (XIZ+0xfe),WA
	cp	hl, 0xFFFF                          ; F98D5B  cp HL,0xffff
	jr z, KeyEvents_ToLink__F98D7C                        ; F98D5F  jr Z,0xf98d7c
	ld	ix, (xiz-35)                        ; F98D61  ld IX,(XIZ+0xdd)
	extz	ix                                ; F98D64  extz IX
	extz	xix                               ; F98D66  extz XIX
	ld	xbc, xix                            ; F98D68  ld XBC,XIX
	add	xbc, xiz                           ; F98D6A  add XBC,XIZ
	ld	(xbc-34), a                         ; F98D6C  ld (XBC+0xde),A
	incm8	1, (xiz-35)                      ; F98D6F  inc 1,(XIZ+0xdd)
	cp (xiz-35), 0x20                      ; F98D72  cp (XIZ+0xdd),0x20   [llvm-mc cannot encode this]
	jr nz, KeyEvents_ToLink__F98D7A                       ; F98D76  jr NZ,0xf98d7a
	jr KeyEvents_ToLink__F98D7C                           ; F98D78  jr T,0xf98d7c
KeyEvents_ToLink__F98D7A:
	jr KeyEvents_ToLink__F98D52                           ; F98D7A  jr T,0xf98d52
KeyEvents_ToLink__F98D7C:
	cp (xiz-35), 0x00                      ; F98D7C  cp (XIZ+0xdd),0x00   [llvm-mc cannot encode this]
	jr z, KeyEvents_ToLink__F98D95                        ; F98D80  jr Z,0xf98d95
	lda	xbc, (xiz-34)                      ; F98D82  lda XBC,XIZ+0xde
	push	xbc                               ; F98D85  push XBC
	ld	wa, (xiz-35)                        ; F98D86  ld WA,(XIZ+0xdd)
	extz	wa                                ; F98D89  extz WA
	pushw	wa                               ; F98D8B  push WA
	pushw	6                                ; F98D8C  push 0x0006
	call	0xF9997E                          ; F98D8F  call 0xf9997e
	inc	8, xsp                             ; F98D93  inc 0,XSP
KeyEvents_ToLink__F98D95:
	pop	xix                                ; F98D95  pop XIX
	popw	hl                                ; F98D96  pop HL
	unlk32 xiz                             ; F98D97  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F98D99  ret

; --------------------------------------------------------------------------
; Link_Ch0_AppendToRing -- append a packet's bytes to the 4096-byte ring at
;             0x00E2F1.
;
; Called from: entry 0 of Handler_PtrTable_FCC53F, through its RAM copy at
;          0x00F334 (notes/prom_c_xrefs.py 0xF98D9A finds the ROM table entry at
;          0xFCC53F and nothing else).
; Inputs:  (XIZ+0x08) u16 byte count, (XIZ+0x0a) pointer to the bytes.
; Outputs: `count` bytes into the ring; the 16-bit write index at 0x00E2EB and the
;          16-bit counter at 0x00E2EF each advanced by `count`.
; Evidence: the store address is
;          `((0x00E2EB) & 0x0FFF) + 6 + 0x0000E2EB`, so the descriptor is
;          {u16 write index at +0, u16 at +4, data from +6} and the ring is
;          0x00E2F1-0x00F2F0.
;          ★ THE MASK AND THE NEXT KNOWN VARIABLE AGREE EXACTLY.  0x0FFF makes the
;          ring 4096 bytes, and 0x00F2F1 -- the first address past it -- is
;          `0x00E2F1 + 0x1000` and is the main loop's countdown, whose boot value
;          notes/FINDINGS-prom_c-ram-image.md already records.  The ring ends
;          precisely where the next documented variable begins.
;          The whole descriptor lies inside the boot RAM image (0x00E2DF-0x00F3B6),
;          so its power-on contents are readable:
;              python3 notes/prom_c_ram_image.py 0x00E2EB:8
; ★ ITS CONSUMER IS TRACED.  MAIN pushes `0x00E2EB` and calls 0xFB060A
;   immediately after KeyEvents_ToLink (0xF98CA4-0xF98CAA), and 0xF98CA4 is the
;   only `lda XBC,0x00E2EB` in the image -- the other two literal-addressed sites
;   are the `ld WA,(0x00E2EB)` and `incw 1,(0x00E2EB)` inside this routine
;   (notes/prom_c_xrefs.py 0x00E2EB --no-window --classify).
; Unknown:  what 0x00E2EF counts -- it is written here and by nothing else that
;          names it, and read by nothing that names it.
; --------------------------------------------------------------------------
Link_Ch0_AppendToRing:
	link32 0xEE, 0x0C, 0xFE, 0xFF          ; F98D9A  link XIZ,0xfffe   [llvm-mc cannot encode this]
	pushw	hl                               ; F98D9E  push HL
	ldw (xiz-2), 0x0000                    ; F98D9F  ld (XIZ+0xfe),0x0000   [llvm-mc cannot encode this]
Link_Ch0_AppendToRing__F98DA4:
	ld	bc, (xiz+8)                         ; F98DA4  ld BC,(XIZ+0x08)
	extz	bc                                ; F98DA7  extz BC
	cp	(xiz-2), bc                         ; F98DA9  cp (XIZ+0xfe),BC
	jr nc, Link_Ch0_AppendToRing__F98DE2                       ; F98DAC  jr NC,0xf98de2
	jr Link_Ch0_AppendToRing__F98DB5                           ; F98DAE  jr T,0xf98db5
Link_Ch0_AppendToRing__F98DB0:
	incm	1, (xiz-2)                        ; F98DB0  incw 1,(XIZ+0xfe)
	jr Link_Ch0_AppendToRing__F98DA4                           ; F98DB3  jr T,0xf98da4
Link_Ch0_AppendToRing__F98DB5:
	ld	xbc, (xiz+10)                       ; F98DB5  ld XBC,(XIZ+0x0a)
	ld	h, (xbc)                            ; F98DB8  ld H,(XBC)
	ldw_da	wa, (0xE2EB)                    ; F98DBA  ld WA,(0x00e2eb)
	and	wa, 0xFFF                          ; F98DBF  and WA,0x0fff
	exts	xwa                               ; F98DC3  exts XWA
	inc	6, xwa                             ; F98DC5  inc 6,XWA
	add	xwa, 0xE2EB                        ; F98DC7  add XWA,0x0000e2eb
	ld	(xwa), h                            ; F98DCD  ld (XWA),H
	incdi16_24	1, (0xE2EB)                 ; F98DCF  incw 1,(0x00e2eb)
	incdi16_24	1, (0xE2EF)                 ; F98DD4  incw 1,(0x00e2ef)
	sub	xbc, xbc                           ; F98DD9  sub XBC,XBC
	inc	1, xbc                             ; F98DDB  inc 1,XBC
	add	(xiz+10), xbc                      ; F98DDD  add (XIZ+0x0a),XBC
	jr Link_Ch0_AppendToRing__F98DB0                           ; F98DE0  jr T,0xf98db0
Link_Ch0_AppendToRing__F98DE2:
	popw	hl                                ; F98DE2  pop HL
	unlk32 xiz                             ; F98DE3  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F98DE5  ret

; --------------------------------------------------------------------------
; ★ Link_Ch1_WriteParamBlock -- CPU 1 writes a byte range into one of four
;             parameter blocks, and flags it.
;
; Called from: entry 1 of Handler_PtrTable_FCC53F (ROM 0xFCC543).
; Inputs:  (XIZ+0x08) u16 total packet length, (XIZ+0x0a) pointer to the packet.
; Packet:  `{u8 command, u8 offset, u8 length, payload...}` -- read off the three
;          byte fetches at 0xF98DEC-0xF98E0A and the two checks that follow:
;              `HL = length + 3;  if HL != total, return`     (0xF98E11-0xF98E1C)
;              `if offset + length > 0x1A, return`            (0xF98E1F-0xF98E2A)
;          so every block is at most **26 bytes** and the packet is exactly
;          3 + length bytes.  Both bounds are literals.
; Dispatch: `command - 0x80`, rejected unless <= 0x0F, then
;          `Link_Ch1_CommandTable[index]`.  Sixteen 4-byte entries running from
;          0xF98F91 to 0xF98FD0 inclusive, which ends EXACTLY on 0xF98FD1 -- the
;          routine's own epilogue, and also the target every unused entry holds.
;          The table's end is therefore fixed by the code that follows it.
;
;     command  destination block   flag         extra
;     0x80/88  -- (one byte)       0x007ECC.0   (0x00F361) = payload[0]
;     0x81     0x00007E7E          0x007ECC.1   (0x007E97) = 1, then as 0x89
;     0x89     0x00007E7E          0x007ECC.1
;     0x82     0x00007E98          0x007ECC.2   (0x007EB1) = 1, then as 0x8A
;     0x8A     0x00007E98          0x007ECC.2
;     0x83     0x00007EB2          0x007ECC.3   (0x007ECB) = 1, then as 0x8B
;     0x8B     0x00007EB2          0x007ECC.3
;     0x87/8F  0x00007ECD          0x007ECC.4
;     0x84-86, 0x8C-8E             -- ignored, straight to the epilogue
;
; ★ THE THREE BLOCK BASES ARE 26 BYTES APART, WHICH IS THE BOUND THE ROUTINE
;   ENFORCES: 0x7E98 - 0x7E7E = 0x1A and 0x7EB2 - 0x7E98 = 0x1A.  And the three
;   "extra" bytes 0x7E97, 0x7EB1 and 0x7ECB are each the LAST byte of the block
;   before them, so the 0x8x form of each pair sets its own block's last byte to 1
;   and the 0x8(x+8) form does not.  That is read off five addresses agreeing, not
;   from any one instruction.
; ⚠ 0x00007ECD + 0x19 = 0x00007EE6, so the fourth block COVERS 0x007ED1 -- the
;   six-phase scheduler's job-request byte (notes/FINDINGS-prom_c-scheduler.md) --
;   at offset 4.  Whether any packet actually reaches that far depends on the
;   offset and length CPU 1 sends, which is not established.  Recorded because a
;   MAME device or a firmware change that assumed 0x007ED1 was CPU-2-private would
;   be assuming something this routine does not guarantee.
; ★ 0x007ECC IS THE "SOMETHING CHANGED" BYTE.  Ten literal-addressed sites in the
;   image (`notes/prom_c_xrefs.py 0x007ECC --no-window --classify`): MAIN tests it
;   at 0xF98C52 and clears it at 0xF98C5C, five of the sets are the arms here, two
;   more set bit 7 inside the 0xF9918C/0xF99199 pair, and 0xFA26C1 sets bit 5.
; Unknown:  what any of the four blocks controls.
; --------------------------------------------------------------------------
Link_Ch1_WriteParamBlock:
	link32 0xEE, 0x0C, 0xF4, 0xFF          ; F98DE6  link XIZ,0xfff4   [llvm-mc cannot encode this]
	pushw	hl                               ; F98DEA  push HL
	push	xix                               ; F98DEB  push XIX
	ld	xbc, (xiz+10)                       ; F98DEC  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F98DEF  ld A,(XBC)
	ld	(xiz-1), a                          ; F98DF1  ld (XIZ+0xff),A
	inc	1, xbc                             ; F98DF4  inc 1,XBC
	ld	(xiz+10), xbc                       ; F98DF6  ld (XIZ+0x0a),XBC
	ld	w, (xbc)                            ; F98DF9  ld W,(XBC)
	ld	(xiz-2), w                          ; F98DFB  ld (XIZ+0xfe),W
	inc	1, xbc                             ; F98DFE  inc 1,XBC
	ld	(xiz+10), xbc                       ; F98E00  ld (XIZ+0x0a),XBC
	ld	a, (xbc)                            ; F98E03  ld A,(XBC)
	ld	(xiz-3), a                          ; F98E05  ld (XIZ+0xfd),A
	inc	1, xbc                             ; F98E08  inc 1,XBC
	ld	(xiz+10), xbc                       ; F98E0A  ld (XIZ+0x0a),XBC
	extz	wa                                ; F98E0D  extz WA
	ld	hl, wa                              ; F98E0F  ld HL,WA
	inc	3, hl                              ; F98E11  inc 3,HL
	ld	wa, (xiz+8)                         ; F98E13  ld WA,(XIZ+0x08)
	extz	wa                                ; F98E16  extz WA
	cp	hl, wa                              ; F98E18  cp HL,WA
	jr z, Link_Ch1_WriteParamBlock__F98E1F                        ; F98E1A  jr Z,0xf98e1f
	jrl Link_Ch1_WriteParamBlock__F98FD1                          ; F98E1C  jrl T,0xf98fd1
Link_Ch1_WriteParamBlock__F98E1F:
	ld	c, (xiz-3)                          ; F98E1F  ld C,(XIZ+0xfd)
	extpfx3 0x8E, 0xFE, 0x83               ; F98E22  add C,(XIZ+0xfe)   [llvm-mc cannot encode this]
	cp	c, 26                               ; F98E25  cp C,0x1a
	jr ule, Link_Ch1_WriteParamBlock__F98E2D                      ; F98E28  jr ULE,0xf98e2d
	jrl Link_Ch1_WriteParamBlock__F98FD1                          ; F98E2A  jrl T,0xf98fd1
Link_Ch1_WriteParamBlock__F98E2D:
	ld	bc, (xiz-1)                         ; F98E2D  ld BC,(XIZ+0xff)
	extz	bc                                ; F98E30  extz BC
	ld	(xiz-12), bc                        ; F98E32  ld (XIZ+0xf4),BC
	jrl Link_Ch1_WriteParamBlock__F98F75                          ; F98E35  jrl T,0xf98f75
	setda_24 0, 0x007ECC                   ; F98E38  set 0,(0x007ecc)   [llvm-mc cannot encode this]
	ld	xbc, (xiz+10)                       ; F98E3D  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F98E40  ld A,(XBC)
	stb_da	(0xF361), a                     ; F98E42  ld (0x00f361),A
	jrl Link_Ch1_WriteParamBlock__F98FD1                          ; F98E47  jrl T,0xf98fd1
	stib_da	(0x7E97), 1                    ; F98E4A  ld (0x007e97),0x01
	setda_24 1, 0x007ECC                   ; F98E50  set 1,(0x007ecc)   [llvm-mc cannot encode this]
	ld	bc, (xiz-2)                         ; F98E55  ld BC,(XIZ+0xfe)
	extz	bc                                ; F98E58  extz BC
	extz	xbc                               ; F98E5A  extz XBC
	add	xbc, 0x7E7E                        ; F98E5C  add XBC,0x00007e7e
	ld	(xiz-8), xbc                        ; F98E62  ld (XIZ+0xf8),XBC
	ldw (xiz-10), 0x0000                   ; F98E65  ld (XIZ+0xf6),0x0000   [llvm-mc cannot encode this]
Link_Ch1_WriteParamBlock__F98E6A:
	ld	bc, (xiz-3)                         ; F98E6A  ld BC,(XIZ+0xfd)
	extz	bc                                ; F98E6D  extz BC
	cp	(xiz-10), bc                        ; F98E6F  cp (XIZ+0xf6),BC
	jr nc, Link_Ch1_WriteParamBlock__F98E93                       ; F98E72  jr NC,0xf98e93
	jr Link_Ch1_WriteParamBlock__F98E7B                           ; F98E74  jr T,0xf98e7b
Link_Ch1_WriteParamBlock__F98E76:
	incm	1, (xiz-10)                       ; F98E76  incw 1,(XIZ+0xf6)
	jr Link_Ch1_WriteParamBlock__F98E6A                           ; F98E79  jr T,0xf98e6a
Link_Ch1_WriteParamBlock__F98E7B:
	ld	xbc, (xiz+10)                       ; F98E7B  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F98E7E  ld A,(XBC)
	ld	h, a                                ; F98E80  ld H,A
	ld	xwa, (xiz-8)                        ; F98E82  ld XWA,(XIZ+0xf8)
	ld	(xwa), h                            ; F98E85  ld (XWA),H
	sub	xbc, xbc                           ; F98E87  sub XBC,XBC
	inc	1, xbc                             ; F98E89  inc 1,XBC
	add	(xiz+10), xbc                      ; F98E8B  add (XIZ+0x0a),XBC
	add	(xiz-8), xbc                       ; F98E8E  add (XIZ+0xf8),XBC
	jr Link_Ch1_WriteParamBlock__F98E76                           ; F98E91  jr T,0xf98e76
Link_Ch1_WriteParamBlock__F98E93:
	jrl Link_Ch1_WriteParamBlock__F98FD1                          ; F98E93  jrl T,0xf98fd1
	stib_da	(0x7EB1), 1                    ; F98E96  ld (0x007eb1),0x01
	setda_24 2, 0x007ECC                   ; F98E9C  set 2,(0x007ecc)   [llvm-mc cannot encode this]
	lda_24	xix, (0x7E98)                   ; F98EA1  lda XIX,0x007e98
	ld	bc, (xiz-2)                         ; F98EA6  ld BC,(XIZ+0xfe)
	extz	bc                                ; F98EA9  extz BC
	extz	xbc                               ; F98EAB  extz XBC
	add	xbc, xix                           ; F98EAD  add XBC,XIX
	ld	(xiz-8), xbc                        ; F98EAF  ld (XIZ+0xf8),XBC
	ldw (xiz-10), 0x0000                   ; F98EB2  ld (XIZ+0xf6),0x0000   [llvm-mc cannot encode this]
Link_Ch1_WriteParamBlock__F98EB7:
	ld	bc, (xiz-3)                         ; F98EB7  ld BC,(XIZ+0xfd)
	extz	bc                                ; F98EBA  extz BC
	cp	(xiz-10), bc                        ; F98EBC  cp (XIZ+0xf6),BC
	jr nc, Link_Ch1_WriteParamBlock__F98EE0                       ; F98EBF  jr NC,0xf98ee0
	jr Link_Ch1_WriteParamBlock__F98EC8                           ; F98EC1  jr T,0xf98ec8
Link_Ch1_WriteParamBlock__F98EC3:
	incm	1, (xiz-10)                       ; F98EC3  incw 1,(XIZ+0xf6)
	jr Link_Ch1_WriteParamBlock__F98EB7                           ; F98EC6  jr T,0xf98eb7
Link_Ch1_WriteParamBlock__F98EC8:
	ld	xbc, (xiz+10)                       ; F98EC8  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F98ECB  ld A,(XBC)
	ld	h, a                                ; F98ECD  ld H,A
	ld	xwa, (xiz-8)                        ; F98ECF  ld XWA,(XIZ+0xf8)
	ld	(xwa), h                            ; F98ED2  ld (XWA),H
	sub	xbc, xbc                           ; F98ED4  sub XBC,XBC
	inc	1, xbc                             ; F98ED6  inc 1,XBC
	add	(xiz+10), xbc                      ; F98ED8  add (XIZ+0x0a),XBC
	add	(xiz-8), xbc                       ; F98EDB  add (XIZ+0xf8),XBC
	jr Link_Ch1_WriteParamBlock__F98EC3                           ; F98EDE  jr T,0xf98ec3
Link_Ch1_WriteParamBlock__F98EE0:
	jrl Link_Ch1_WriteParamBlock__F98FD1                          ; F98EE0  jrl T,0xf98fd1
	stib_da	(0x7ECB), 1                    ; F98EE3  ld (0x007ecb),0x01
	setda_24 3, 0x007ECC                   ; F98EE9  set 3,(0x007ecc)   [llvm-mc cannot encode this]
	lda_24	xix, (0x7EB2)                   ; F98EEE  lda XIX,0x007eb2
	ld	bc, (xiz-2)                         ; F98EF3  ld BC,(XIZ+0xfe)
	extz	bc                                ; F98EF6  extz BC
	extz	xbc                               ; F98EF8  extz XBC
	add	xbc, xix                           ; F98EFA  add XBC,XIX
	ld	(xiz-8), xbc                        ; F98EFC  ld (XIZ+0xf8),XBC
	ldw (xiz-10), 0x0000                   ; F98EFF  ld (XIZ+0xf6),0x0000   [llvm-mc cannot encode this]
Link_Ch1_WriteParamBlock__F98F04:
	ld	bc, (xiz-3)                         ; F98F04  ld BC,(XIZ+0xfd)
	extz	bc                                ; F98F07  extz BC
	cp	(xiz-10), bc                        ; F98F09  cp (XIZ+0xf6),BC
	jr nc, Link_Ch1_WriteParamBlock__F98F2D                       ; F98F0C  jr NC,0xf98f2d
	jr Link_Ch1_WriteParamBlock__F98F15                           ; F98F0E  jr T,0xf98f15
Link_Ch1_WriteParamBlock__F98F10:
	incm	1, (xiz-10)                       ; F98F10  incw 1,(XIZ+0xf6)
	jr Link_Ch1_WriteParamBlock__F98F04                           ; F98F13  jr T,0xf98f04
Link_Ch1_WriteParamBlock__F98F15:
	ld	xbc, (xiz+10)                       ; F98F15  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F98F18  ld A,(XBC)
	ld	h, a                                ; F98F1A  ld H,A
	ld	xwa, (xiz-8)                        ; F98F1C  ld XWA,(XIZ+0xf8)
	ld	(xwa), h                            ; F98F1F  ld (XWA),H
	sub	xbc, xbc                           ; F98F21  sub XBC,XBC
	inc	1, xbc                             ; F98F23  inc 1,XBC
	add	(xiz+10), xbc                      ; F98F25  add (XIZ+0x0a),XBC
	add	(xiz-8), xbc                       ; F98F28  add (XIZ+0xf8),XBC
	jr Link_Ch1_WriteParamBlock__F98F10                           ; F98F2B  jr T,0xf98f10
Link_Ch1_WriteParamBlock__F98F2D:
	jrl Link_Ch1_WriteParamBlock__F98FD1                          ; F98F2D  jrl T,0xf98fd1
	setda_24 4, 0x007ECC                   ; F98F30  set 4,(0x007ecc)   [llvm-mc cannot encode this]
	ld	bc, (xiz-2)                         ; F98F35  ld BC,(XIZ+0xfe)
	extz	bc                                ; F98F38  extz BC
	extz	xbc                               ; F98F3A  extz XBC
	add	xbc, 0x7ECD                        ; F98F3C  add XBC,0x00007ecd
	ld	(xiz-8), xbc                        ; F98F42  ld (XIZ+0xf8),XBC
	ldw (xiz-10), 0x0000                   ; F98F45  ld (XIZ+0xf6),0x0000   [llvm-mc cannot encode this]
Link_Ch1_WriteParamBlock__F98F4A:
	ld	bc, (xiz-3)                         ; F98F4A  ld BC,(XIZ+0xfd)
	extz	bc                                ; F98F4D  extz BC
	cp	(xiz-10), bc                        ; F98F4F  cp (XIZ+0xf6),BC
	jr nc, Link_Ch1_WriteParamBlock__F98F73                       ; F98F52  jr NC,0xf98f73
	jr Link_Ch1_WriteParamBlock__F98F5B                           ; F98F54  jr T,0xf98f5b
Link_Ch1_WriteParamBlock__F98F56:
	incm	1, (xiz-10)                       ; F98F56  incw 1,(XIZ+0xf6)
	jr Link_Ch1_WriteParamBlock__F98F4A                           ; F98F59  jr T,0xf98f4a
Link_Ch1_WriteParamBlock__F98F5B:
	ld	xbc, (xiz+10)                       ; F98F5B  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F98F5E  ld A,(XBC)
	ld	h, a                                ; F98F60  ld H,A
	ld	xwa, (xiz-8)                        ; F98F62  ld XWA,(XIZ+0xf8)
	ld	(xwa), h                            ; F98F65  ld (XWA),H
	sub	xbc, xbc                           ; F98F67  sub XBC,XBC
	inc	1, xbc                             ; F98F69  inc 1,XBC
	add	(xiz+10), xbc                      ; F98F6B  add (XIZ+0x0a),XBC
	add	(xiz-8), xbc                       ; F98F6E  add (XIZ+0xf8),XBC
	jr Link_Ch1_WriteParamBlock__F98F56                           ; F98F71  jr T,0xf98f56
Link_Ch1_WriteParamBlock__F98F73:
	jr Link_Ch1_WriteParamBlock__F98FD1                           ; F98F73  jr T,0xf98fd1
Link_Ch1_WriteParamBlock__F98F75:
	sub	xbc, xbc                           ; F98F75  sub XBC,XBC
	ld	bc, (xiz-12)                        ; F98F77  ld BC,(XIZ+0xf4)
	sub	bc, 0x80                           ; F98F7A  sub BC,0x0080
	cp	bc, 15                              ; F98F7E  cp BC,0x000f
	jr ugt, Link_Ch1_WriteParamBlock__F98FD1                      ; F98F82  jr UGT,0xf98fd1
	sll	bc, 2                              ; F98F84  sll 0x02,BC
	add	xbc, 0xF98F91                      ; F98F87  add XBC,0x00f98f91
	ld	xbc, (xbc)                          ; F98F8D  ld XBC,(XBC)
	jp	(xbc)                               ; F98F8F  jp T,XBC

; ----------------------------------------------------------------------------
; Link_Ch1_CommandTable -- 0xF98F91-0xF98FD0, SIXTEEN 32-bit targets for
; sub-commands 0x80..0x8F.  Bounded twice: `cp BC,0x000F / jr UGT` rejects
; anything above 15, and sixteen 4-byte entries from 0xF98F91 end exactly on
; 0xF98FD1, which is the routine's epilogue AND the target of every unused entry.
; The LAST entry (0xF98FCD) was checked as well as the first: it holds 0xF98F30,
; the 0x87 arm, which is what command 0x8F has to be for the 0x8x/0x8(x+8) pairing
; to hold all the way across.
; ----------------------------------------------------------------------------
Link_Ch1_CommandTable:
	.long	0x00F98E38			; 0xF98F91  command 0x80
	.long	0x00F98E4A			; 0xF98F95  command 0x81
	.long	0x00F98E96			; 0xF98F99  command 0x82
	.long	0x00F98EE3			; 0xF98F9D  command 0x83
	.long	0x00F98FD1			; 0xF98FA1  command 0x84
	.long	0x00F98FD1			; 0xF98FA5  command 0x85
	.long	0x00F98FD1			; 0xF98FA9  command 0x86
	.long	0x00F98F30			; 0xF98FAD  command 0x87
	.long	0x00F98E38			; 0xF98FB1  command 0x88
	.long	0x00F98E50			; 0xF98FB5  command 0x89
	.long	0x00F98E9C			; 0xF98FB9  command 0x8A
	.long	0x00F98EE9			; 0xF98FBD  command 0x8B
	.long	0x00F98FD1			; 0xF98FC1  command 0x8C
	.long	0x00F98FD1			; 0xF98FC5  command 0x8D
	.long	0x00F98FD1			; 0xF98FC9  command 0x8E
	.long	0x00F98F30			; 0xF98FCD  command 0x8F
Link_Ch1_WriteParamBlock__F98FD1:
	pop	xix                                ; F98FD1  pop XIX
	popw	hl                                ; F98FD2  pop HL
	unlk32 xiz                             ; F98FD3  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F98FD5  ret

; --------------------------------------------------------------------------
; Link_Ch2_ForwardBytes -- push a packet's bytes one at a time into 0xF992C6,
;             intercepting the byte 0xFA.
;
; Called from: entry 2 of Handler_PtrTable_FCC53F (ROM 0xFCC547).
; Inputs:  (XIZ+0x08) u16 count, (XIZ+0x0a) pointer.
; Outputs: for each byte: if it is **0xFA**, `(0x00F328) = 0xFF` and the byte is
;          NOT forwarded; otherwise `0xF992C6(byte)`.
; Evidence: `cp A,0xFA / jr NZ` is the only comparison in the routine; the count
;          is decremented in place at (XIZ+0x08) and the loop ends when it reaches
;          zero.
; ⚠ 0xFA is MIDI's System-Real-Time "Start" and 0xF992C6 is reached from the
;   serial transmit side as well (`calr 0xF992C6` at 0xF992BD and 0xF9950A), so
;   "this is the MIDI OUT path with a transport-start intercept" FITS.  It is NOT
;   ESTABLISHED: 0xF992C6 is not converted and nothing here shows the byte
;   reaching SC0BUF.
; ★ 0x00F328 has five literal-addressed sites and the other four are all in the
;   converted routine at 0xF99553-0xF9958D, which compares it against 0 and 1 and
;   writes 0 and 1 -- so 0xFF here is a third, distinct value written by this one
;   instruction.  Stated as read.
; Unknown:  what 0xF992C6 does; what 0x00F328 selects.
; --------------------------------------------------------------------------
Link_Ch2_ForwardBytes:
	link32 0xEE, 0x0C, 0xFF, 0xFF          ; F98FD6  link XIZ,0xffff   [llvm-mc cannot encode this]
	pushw	hl                               ; F98FDA  push HL
Link_Ch2_ForwardBytes__F98FDB:
	ld	h, (xiz+8)                          ; F98FDB  ld H,(XIZ+0x08)
	ld	c, h                                ; F98FDE  ld C,H
	dec	1, c                               ; F98FE0  dec 1,C
	ld	(xiz-1), c                          ; F98FE2  ld (XIZ+0xff),C
	ld	(xiz+8), c                          ; F98FE5  ld (XIZ+0x08),C
	cps	h, 0                               ; F98FE8  cp H,0
	jr z, Link_Ch2_ForwardBytes__F99017                        ; F98FEA  jr Z,0xf99017
	ld	xbc, (xiz+10)                       ; F98FEC  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F98FEF  ld A,(XBC)
	cp	a, 0xFA                             ; F98FF1  cp A,0xfa
	jr nz, Link_Ch2_ForwardBytes__F99003                       ; F98FF4  jr NZ,0xf99003
	stib_da	(0xF328), 0xFF                 ; F98FF6  ld (0x00f328),0xff
	inc	1, xbc                             ; F98FFC  inc 1,XBC
	ld	(xiz+10), xbc                       ; F98FFE  ld (XIZ+0x0a),XBC
	jr Link_Ch2_ForwardBytes__F99015                           ; F99001  jr T,0xf99015
Link_Ch2_ForwardBytes__F99003:
	ld	xbc, (xiz+10)                       ; F99003  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F99006  ld A,(XBC)
	extz	wa                                ; F99008  extz WA
	pushw	wa                               ; F9900A  push WA
	inc	1, xbc                             ; F9900B  inc 1,XBC
	ld	(xiz+10), xbc                       ; F9900D  ld (XIZ+0x0a),XBC
	call	0xF992C6                          ; F99010  call 0xf992c6
	popw	bc                                ; F99014  pop BC
Link_Ch2_ForwardBytes__F99015:
	jr Link_Ch2_ForwardBytes__F98FDB                           ; F99015  jr T,0xf98fdb
Link_Ch2_ForwardBytes__F99017:
	popw	hl                                ; F99017  pop HL
	unlk32 xiz                             ; F99018  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F9901A  ret

; --------------------------------------------------------------------------
; ★★ Link_Ch3_SetTouchControl -- CPU 1 sets the two TOUCH controls.
;
; Called from: entry 3 of Handler_PtrTable_FCC53F (ROM 0xFCC54B).
; Inputs:  (XIZ+0x08) u16 packet length, (XIZ+0x0a) pointer to `{u8 sel, u8 val}`.
; Outputs: nothing unless the length is EXACTLY 2 (`cp (XIZ+0x08),0x02 / jr NZ`);
;          then
;              sel == 0x80  ->  ToneGen_SetVelCurveMode(val)   (0xF99598)
;              sel == 0x90  ->  ToneGen_SetVelOffset(val)      (0xF995AD)
;              anything else -> nothing.
; Evidence: two `cp BC,0x0080` / `cp BC,0x0090` against the first byte, each
;          jumping to a two-instruction arm that pushes the second byte and calls
;          one of the two setters.  0xF995AD is ToneGen_SetVelOffset, checked by
;          disassembling rather than by counting a listing: ToneGen_SetVelCurveMode
;          occupies 0xF99598-0xF995AC (21 bytes, ending in the 0x0E `ret` at
;          0xF995AC), so 0xF995AD is the next routine's `link XIZ,0x0000`.
; ★ THIS ANSWERS BOTH SETTERS' OPEN QUESTION.  ToneGen_SetVelCurveMode's header
;   says "Called from: not traced" and "Unknown: which UI control feeds it", and
;   ToneGen_SetVelOffset's says the same.  Neither is fed by a control on this
;   processor at all: **CPU 1 sends them over the link**, on channel 3, as a
;   two-byte packet.  The UI is on the other CPU, which is why nothing on this one
;   could be found.
; Unknown:  whether sub-selectors other than 0x80 and 0x90 are ever sent.
; --------------------------------------------------------------------------
Link_Ch3_SetTouchControl:
	link32 0xEE, 0x0C, 0xFE, 0xFF          ; F9901B  link XIZ,0xfffe   [llvm-mc cannot encode this]
	cp (xiz+8), 0x02                       ; F9901F  cp (XIZ+0x08),0x02   [llvm-mc cannot encode this]
	jr nz, Link_Ch3_SetTouchControl__F99060                       ; F99023  jr NZ,0xf99060
	ld	xbc, (xiz+10)                       ; F99025  ld XBC,(XIZ+0x0a)
	ld	a, (xbc)                            ; F99028  ld A,(XBC)
	extz	wa                                ; F9902A  extz WA
	ld	(xiz-2), wa                         ; F9902C  ld (XIZ+0xfe),WA
	jr Link_Ch3_SetTouchControl__F99051                           ; F9902F  jr T,0xf99051
Link_Ch3_SetTouchControl__F99031:
	ld	xbc, (xiz+10)                       ; F99031  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+1)                          ; F99034  ld A,(XBC+0x01)
	extz	wa                                ; F99037  extz WA
	pushw	wa                               ; F99039  push WA
	call	0xF99598                          ; F9903A  call 0xf99598
	popw	bc                                ; F9903E  pop BC
	jr Link_Ch3_SetTouchControl__F99060                           ; F9903F  jr T,0xf99060
Link_Ch3_SetTouchControl__F99041:
	ld	xbc, (xiz+10)                       ; F99041  ld XBC,(XIZ+0x0a)
	ld	a, (xbc+1)                          ; F99044  ld A,(XBC+0x01)
	extz	wa                                ; F99047  extz WA
	pushw	wa                               ; F99049  push WA
	call	0xF995AD                          ; F9904A  call 0xf995ad
	popw	bc                                ; F9904E  pop BC
	jr Link_Ch3_SetTouchControl__F99060                           ; F9904F  jr T,0xf99060
Link_Ch3_SetTouchControl__F99051:
	ld	bc, (xiz-2)                         ; F99051  ld BC,(XIZ+0xfe)
	cp	bc, 0x80                            ; F99054  cp BC,0x0080
	jr z, Link_Ch3_SetTouchControl__F99031                        ; F99058  jr Z,0xf99031
	cp	bc, 0x90                            ; F9905A  cp BC,0x0090
	jr z, Link_Ch3_SetTouchControl__F99041                        ; F9905E  jr Z,0xf99041
Link_Ch3_SetTouchControl__F99060:
	unlk32 xiz                             ; F99060  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F99062  ret

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
; Evidence: the dispatch immediately above is `cp BC,5 / jr UGT / sll BC,2 /
;          add XBC,0x00F990C8 / ld XBC,(XBC) / jp (XBC)`, so the table BEGINS at
;          0xF990C8 -- this label's own address -- has stride 4 and is bounded at
;          index 5, i.e. SIX entries, 0xF990C8-0xF990DF.  Last-entry test: entry 5
;          is 0x00F990AB, inside the phase-arm run just above, and the next four
;          bytes are `c2 e3 e2 00`, the `incw 1,(0x00E2E3)` that opens
;          INTT1_HANDLER__advance -- so the table ends where this says it does.
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
;          It brackets the register writes with `ei 6` before and `di` after.
;          ⚠ THAT PAIR IS THE OPPOSITE WAY ROUND FROM WHAT THE MNEMONICS SUGGEST:
;          `ei 6` raises the minimum accepted interrupt priority to 6 (blocking
;          everything below it) and llvm-mc's `di` is the byte pair `06 00` =
;          `EI 0`, which lowers it to 0 and accepts everything.  See the long note
;          in DSP_ChannelRefresh_Loop's header for the citations.  So the guarded
;          region is between them, and the routine ends with interrupts ON.
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

; ==============================================================================
; 0xF992A7-0xF99597 -- the RING-QUEUE runtime, the MIDI transmit path, and the
;                      ACTIVE-SENSING / TRANSPORT-SWITCH watchdogs
;                      9 routines, 753 bytes
; ==============================================================================
;
; ★★ THE QUEUE DESCRIPTOR, AND ITS SIZE CONFIRMED THREE WAYS.  Six of the nine
; routines below take one pointer argument and do nothing but walk a ring buffer
; through it.  The fields are read off their instructions:
;
;     +0x00  u32  first slot
;     +0x04  u32  LAST slot        (the wrap test is `cursor == +0x04 -> +0x00`)
;     +0x08  u32  read cursor
;     +0x0C  u32  write cursor
;     +0x10  u32  a SECOND read cursor, used only by Queue_Peek_Cursor2
;     +0x14  u16  FREE-slot count  (`== 0` means full; put decrements, get
;                                   increments)
;                                                  = 22 = 0x16 bytes
;
; The size is not counted off a listing.  Three independent facts give it:
;   1. `notes/FINDINGS-prom_c-serial-midi.md` already names 0x00F2FB as the
;      receive descriptor, and MIDI_Tx_PutByte below passes **0x00F311** for the
;      transmit one.  0x00F311 - 0x00F2FB = **0x16**.
;   2. Both descriptors are inside the boot RAM image, so their power-on contents
;      are readable and the last field is where the struct stops:
;          python3 notes/prom_c_ram_image.py 0x00F2FB:22 0x00F311:22
;      RX: first 0x00007EDA, last 0x000082D9, all three cursors 0x00007EDA,
;          free 0x03FF = 1023 -- a 0x400 = 1024-byte buffer with one slot held back.
;      TX: first 0x000082DA, last 0x000084D9, all three cursors 0x000082DA,
;          free 0x01FF =  511 -- a 0x200 =  512-byte buffer, likewise.
;   3. The two buffers are ADJACENT and each free count is its buffer's size minus
;      one: 0x82D9 + 1 = 0x82DA and 0x84D9 + 1 = **0x0084DA**, which is the
;      per-note velocity trim table
;      (notes/FINDINGS-prom_c-keyboard-and-touch.md).  Three RAM objects meeting
;      end to end with no gap.
;
; ★ THE MIDI TRANSMIT PATH.  MIDI_Tx_PutByte writes STRAIGHT to SC0BUF when the
; transmitter is idle -- `(0x00F2F9) == 2`, which is the value INTTX0_HANDLER
; writes when its queue runs dry (see notes/FINDINGS-prom_c-serial-midi.md) --
; and otherwise queues the byte on 0x00F311, retrying while the queue is full.
; Every direct write also stamps 0x007ED2 with the current INTT1 tick count, which
; is what the active-sensing timer below measures against.
;
; ★★ ACTIVE SENSING, IN BOTH DIRECTIONS.  MIDI_Watchdogs_And_TransportSwitch is
; called from MAIN every pass and does three unrelated jobs:
;
;   1. If more than 0x87 = 135 INTT1 ticks have passed since the last byte was
;      given to the UART (0x007ED2), it re-stamps and sends the byte **0xFE**.
;   2. If a 0xFE has been RECEIVED -- INTRX0_HANDLER sets 0x00F2F8 on exactly that
;      byte, which that handler's own header already records -- and more than
;      0xA5 = 165 ticks have passed since the last receive timestamp (0x007ED6),
;      it clears the flag and sends the byte at **0xFCC5C2** up link channel 6.
;   3. It reads bit 2 of port P8 and, on a change, sends the byte at **0xFCC5C3**
;      or **0xFCC5C4** up link channel 6, tracking the state in 0x00F328.
;
; ★★★ AND THAT DECODES THE LAST THREE BYTES OF `unexplained_FCC5BE`.  The zone-2
; header in this file lists `ff fa fb 4d 00 80 00` as unidentified and a later pass
; explained only the `4d 00` and `80 00`.  The other three are these:
;
;     0xFCC5C2 = 0xFF     sent on the receive-side active-sensing TIMEOUT
;     0xFCC5C3 = 0xFA     sent when P8 bit 2 goes HIGH
;     0xFCC5C4 = 0xFB     sent when P8 bit 2 goes LOW
;
; They are single bytes with addresses because Link_SendBuffer takes a POINTER and
; a length, and each is sent with length 1.
;
; ⚠ In MIDI, 0xFE is Active Sensing, 0xFF is System Reset, 0xFA is Start and 0xFB
; is Continue.  The 0xFE side is not just a name-match: the transmitter emits it on
; a timer and the receiver flags it and times it out, which IS the active-sensing
; protocol.  What P8 bit 2 physically is -- a footswitch, a transport button -- is
; NOT ESTABLISHED; only that its two states send two different single-byte messages
; and that 0xF992A7's byte-string terminator is 0xFF.
;
; ⚠ AND A TIMING INFERENCE, LABELLED AS ONE.  notes/FINDINGS-prom_c-scheduler.md
; records "the tick RATE is not established".  It still is not.  But IF the 0xFE is
; MIDI Active Sensing, the standard requires it at intervals of at most 300 ms, and
; 135 ticks would then be at most 300 ms -- a tick of about 2.2 ms or less, and a
; receive timeout (165 ticks) about 22% longer than the send interval, which is the
; margin an active-sensing receiver needs.  That is an argument from the MIDI
; specification, NOT from this ROM, and it is written here so that a later
; measurement can contradict it.
;
; Transcribed with notes/llvm_roundtrip_autoforce.py c 0xF992A7 0x2F1, restyled by
; notes/prom_c_listing_prep.py, re-proved with notes/prom_c_verify_fragment.py.

; --------------------------------------------------------------------------
; MIDI_Tx_SendUntilFF -- hand bytes to MIDI_Tx_PutByte until one of them is 0xFF.
;
; Called from: 0xF9A0ED, 0xF9A11B and 0xF9A153, three `call 0xF992A7` sites in the
;          still-unconverted stretch above Link_WaitBlockDone.
; Inputs:  (XIZ+0x08) a pointer, updated in place as it walks.
; Outputs: none.  The terminating 0xFF is NOT sent.
; Evidence: `ld A,(XBC) / cp A,0xFF / jr Z,exit`, then the same byte is pushed and
;          `calr 0xF992C6` called, the pointer incremented and written back to the
;          stack slot, and the loop repeats.
; Unknown:  what the three callers send.  ⚠ 0xFF is MIDI System Reset, so a
;          message list terminated by 0xFF cannot itself contain one; whether that
;          is deliberate is not established.
; --------------------------------------------------------------------------
MIDI_Tx_SendUntilFF:
	link32 0xEE, 0x0C, 0x00, 0x00          ; F992A7  link XIZ,0x0000   [llvm-mc cannot encode this]
MIDI_Tx_SendUntilFF__F992AB:
	ld	xbc, (xiz+8)                        ; F992AB  ld XBC,(XIZ+0x08)
	ld	a, (xbc)                            ; F992AE  ld A,(XBC)
	cp	a, 0xFF                             ; F992B0  cp A,0xff
	jr z, MIDI_Tx_SendUntilFF__F992C3                        ; F992B3  jr Z,0xf992c3
	ld	a, (xbc)                            ; F992B5  ld A,(XBC)
	pushw	wa                               ; F992B7  push WA
	inc	1, xbc                             ; F992B8  inc 1,XBC
	ld	(xiz+8), xbc                        ; F992BA  ld (XIZ+0x08),XBC
	calr (0xF992C6 - 0xF992C0)             ; F992BD  calr 0xf992c6
	popw	bc                                ; F992C0  pop BC
	jr MIDI_Tx_SendUntilFF__F992AB                           ; F992C1  jr T,0xf992ab
MIDI_Tx_SendUntilFF__F992C3:
	unlk32 xiz                             ; F992C3  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F992C5  ret

; --------------------------------------------------------------------------
; ★ MIDI_Tx_PutByte -- send one byte out of serial channel 0, directly if the
;             transmitter is idle and through the ring queue otherwise.
;
; Called from: 0xF992BD (MIDI_Tx_SendUntilFF), 0xF9950A
;          (MIDI_Watchdogs_And_TransportSwitch's active-sensing arm) and 0xF99010
;          (Link_Ch2_ForwardBytes -- so a byte CPU 1 sends on link channel 2 goes
;          out of the MIDI port).  notes/prom_c_xrefs.py 0xF992C6.
; Inputs:  (XIZ+0x08) the byte.
; Outputs: either SC0BUF directly, or one slot of the transmit queue at 0x00F311.
; Evidence: `push SR` / `ei 6` guards the test; `cp (0x00F2F9),0x0002` is the idle
;          test -- 2 is the value INTTX0_HANDLER writes when its queue runs dry,
;          per notes/FINDINGS-prom_c-serial-midi.md -- and the direct path is
;          `ld BC,0x0050 / exts XBC / ld (XBC),A`, i.e. a store to SC0BUF at
;          internal-I/O address 0x50.  It then stamps 0x007ED2 with the 32-bit
;          tick counter and sets the state to 1.
;          The queued path calls Queue_Put(0x00F311, byte) and RETRIES while the
;          result is 0xFFFF, so a full queue blocks here rather than dropping.
; ★ 0x007ED2 IS THE ACTIVE-SENSING TIMER'S REFERENCE.  Four literal-addressed
;          sites: written here and at 0xF99502, written by INTTX0_HANDLER at
;          0xF99291, and read at 0xF994ED.
; Unknown:  what the third value of 0x00F2F9 (0 -- its boot value) means.
; --------------------------------------------------------------------------
MIDI_Tx_PutByte:
	link32 0xEE, 0x0C, 0xFE, 0xFF          ; F992C6  link XIZ,0xfffe   [llvm-mc cannot encode this]
	push	sr                                ; F992CA  push SR
	ei	6                                   ; F992CB  ei 0x06
	extpfx7 0xD2, 0xF9, 0xF2, 0x00, 0x3F, 0x02, 0x00 ; F992CD  cp (0x00f2f9),0x0002   [llvm-mc cannot encode this]
	jr nz, MIDI_Tx_PutByte__F992F8                       ; F992D4  jr NZ,0xf992f8
	ldw	bc, 80                             ; F992D6  ld BC,0x0050
	exts	xbc                               ; F992D9  exts XBC
	ld	a, (xiz+8)                          ; F992DB  ld A,(XIZ+0x08)
	ld	(xbc), a                            ; F992DE  ld (XBC),A
	ldl_da	xbc, (0xF2F3)                   ; F992E0  ld XBC,(0x00f2f3)
	stl_da	(0x7ED2), xbc                   ; F992E5  ld (0x007ed2),XBC
	stiw_da	(0xF2F9), 1                    ; F992EA  ld (0x00f2f9),0x0001
	ldw (xiz-2), 0x0000                    ; F992F1  ld (XIZ+0xfe),0x0000   [llvm-mc cannot encode this]
	jr MIDI_Tx_PutByte__F9930B                           ; F992F6  jr T,0xf9930b
MIDI_Tx_PutByte__F992F8:
	push	0                                 ; F992F8  push 0x00
	extpfx3 0x8E, 0x08, 0x04               ; F992FA  push (XIZ+0x08)   [llvm-mc cannot encode this]
	lda_24	xbc, (0xF311)                   ; F992FD  lda XBC,0x00f311
	push	xbc                               ; F99302  push XBC
	calr (0xF9932E - 0xF99306)             ; F99303  calr 0xf9932e
	ld	(xiz-2), wa                         ; F99306  ld (XIZ+0xfe),WA
	inc	6, xsp                             ; F99309  inc 6,XSP
MIDI_Tx_PutByte__F9930B:
	pop	sr                                 ; F9930B  pop SR
	cpw (xiz-2), 0xFFFF                    ; F9930C  cp (XIZ+0xfe),0xffff   [llvm-mc cannot encode this]
	jr nz, MIDI_Tx_PutByte__F9932B                       ; F99311  jr NZ,0xf9932b
MIDI_Tx_PutByte__F99313:
	push	0                                 ; F99313  push 0x00
	extpfx3 0x8E, 0x08, 0x04               ; F99315  push (XIZ+0x08)   [llvm-mc cannot encode this]
	lda_24	xbc, (0xF311)                   ; F99318  lda XBC,0x00f311
	push	xbc                               ; F9931D  push XBC
	calr (0xF9932E - 0xF99321)             ; F9931E  calr 0xf9932e
	inc	6, xsp                             ; F99321  inc 6,XSP
	cp	wa, 0xFFFF                          ; F99323  cp WA,0xffff
	jr nz, MIDI_Tx_PutByte__F9932B                       ; F99327  jr NZ,0xf9932b
	jr MIDI_Tx_PutByte__F99313                           ; F99329  jr T,0xf99313
MIDI_Tx_PutByte__F9932B:
	unlk32 xiz                             ; F9932B  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F9932D  ret

; --------------------------------------------------------------------------
; Queue_Put -- store one byte at the write cursor of a ring queue.
;
; Called from: 0xF99303 and 0xF9931E, both inside MIDI_Tx_PutByte, and both
;          passing the descriptor 0x00F311.
; Inputs:  (XIZ+0x08) descriptor pointer, (XIZ+0x0c) the byte.
; Outputs: WA = the free count AFTER the store, or 0 if the queue was already
;          full -- and the caller's `cp (XIZ+0xfe),0xFFFF` test means a full queue
;          is signalled by the value it reads back, not by a flag.
; Evidence: the descriptor layout in the block comment above is read entirely from
;          this routine and its five siblings: `(XBC+0x14)` is tested against 0 and
;          decremented, `(XBC+0x0c)` is the store address, and the wrap is
;          `if (XBC+0x0c) == (XBC+0x04) then (XBC+0x0c) = (XBC) else += 1`.
; Unknown:  nothing about the routine.
; --------------------------------------------------------------------------
Queue_Put:
	link32 0xEE, 0x0C, 0x00, 0x00          ; F9932E  link XIZ,0x0000   [llvm-mc cannot encode this]
	push	xix                               ; F99332  push XIX
	ld	xbc, (xiz+8)                        ; F99333  ld XBC,(XIZ+0x08)
	ld	wa, (xbc+20)                        ; F99336  ld WA,(XBC+0x14)
	cps	wa, 0                              ; F99339  cp WA,0
	jr nz, Queue_Put__F99344                       ; F9933B  jr NZ,0xf99344
	ld	wa, (xbc+20)                        ; F9933D  ld WA,(XBC+0x14)
	jr Queue_Put__F9937B                           ; F99340  jr T,0xf9937b
	jr Queue_Put__F9937B                           ; F99342  jr T,0xf9937b
Queue_Put__F99344:
	ld	xbc, (xiz+8)                        ; F99344  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+12)                       ; F99347  ld XWA,(XBC+0x0c)
	ld	c, (xiz+12)                         ; F9934A  ld C,(XIZ+0x0c)
	ld	(xwa), c                            ; F9934D  ld (XWA),C
	ld	xbc, (xiz+8)                        ; F9934F  ld XBC,(XIZ+0x08)
	decm	1, (xbc+20)                       ; F99352  decw 1,(XBC+0x14)
	ld	xbc, (xiz+8)                        ; F99355  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+4)                        ; F99358  ld XWA,(XBC+0x04)
	ld	xix, xwa                            ; F9935B  ld XIX,XWA
	ld	xiy, (xbc+12)                       ; F9935D  ld XIY,(XBC+0x0c)
	cp	xiy, xwa                            ; F99360  cp XIY,XWA
	jr nz, Queue_Put__F9936B                       ; F99362  jr NZ,0xf9936b
	ld	xwa, (xbc)                          ; F99364  ld XWA,(XBC)
	ld	(xbc+12), xwa                       ; F99366  ld (XBC+0x0c),XWA
	jr Queue_Put__F99375                           ; F99369  jr T,0xf99375
Queue_Put__F9936B:
	ld	xbc, (xiz+8)                        ; F9936B  ld XBC,(XIZ+0x08)
	sub	xwa, xwa                           ; F9936E  sub XWA,XWA
	inc	1, xwa                             ; F99370  inc 1,XWA
	add	(xbc+12), xwa                      ; F99372  add (XBC+0x0c),XWA
Queue_Put__F99375:
	ld	xbc, (xiz+8)                        ; F99375  ld XBC,(XIZ+0x08)
	ld	wa, (xbc+20)                        ; F99378  ld WA,(XBC+0x14)
Queue_Put__F9937B:
	pop	xix                                ; F9937B  pop XIX
	unlk32 xiz                             ; F9937C  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F9937E  ret

; --------------------------------------------------------------------------
; Queue_Put_IrqGuarded -- Queue_Put with the free-count decrement bracketed by
;             `ei 6` / `di`.
;
; Called from: NOT FOUND.  `python3 notes/prom_c_xrefs.py 0xF9937F --no-window`
;          reports no literal and no calr; short PC-relative forms are not
;          searched.
; Inputs / Outputs: as Queue_Put.
; Evidence: Queue_Put is 81 bytes and this one 85.  Aligned byte by byte with
;          difflib, the difference is exactly two INSERTED two-byte instructions --
;          `06 06` and `06 00` -- wrapped round the `decw 1,(XBC+0x14)`, plus the
;          two branch-displacement bytes at Queue_Put offsets +0x13 and +0x15 that
;          had to move because of them.  Nothing else differs, and the four
;          "changed" bytes are two displacements, not two instructions.
;          ⚠ Read `ei 6` … `di` the right way round: `di` is the byte pair
;          `06 00` = `EI 0`, which ENABLES interrupts -- see the long note in
;          DSP_ChannelRefresh_Loop's header.  So the guard RAISES the mask for the
;          decrement and drops it again, which is what protecting a counter shared
;          with an ISR looks like.
; Unknown:  why the guarded variant exists and is unused, while the unguarded one
;          is the one MIDI_Tx_PutByte calls -- from inside its own `ei 6` region.
; --------------------------------------------------------------------------
Queue_Put_IrqGuarded:
	link32 0xEE, 0x0C, 0x00, 0x00          ; F9937F  link XIZ,0x0000   [llvm-mc cannot encode this]
	push	xix                               ; F99383  push XIX
	ld	xbc, (xiz+8)                        ; F99384  ld XBC,(XIZ+0x08)
	ld	wa, (xbc+20)                        ; F99387  ld WA,(XBC+0x14)
	cps	wa, 0                              ; F9938A  cp WA,0
	jr nz, Queue_Put_IrqGuarded__F99395                       ; F9938C  jr NZ,0xf99395
	ld	wa, (xbc+20)                        ; F9938E  ld WA,(XBC+0x14)
	jr Queue_Put_IrqGuarded__F993D0                           ; F99391  jr T,0xf993d0
	jr Queue_Put_IrqGuarded__F993D0                           ; F99393  jr T,0xf993d0
Queue_Put_IrqGuarded__F99395:
	ld	xbc, (xiz+8)                        ; F99395  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+12)                       ; F99398  ld XWA,(XBC+0x0c)
	ld	c, (xiz+12)                         ; F9939B  ld C,(XIZ+0x0c)
	ld	(xwa), c                            ; F9939E  ld (XWA),C
	ei	6                                   ; F993A0  ei 0x06
	ld	xbc, (xiz+8)                        ; F993A2  ld XBC,(XIZ+0x08)
	decm	1, (xbc+20)                       ; F993A5  decw 1,(XBC+0x14)
	di                                     ; F993A8  ei 0x00
	ld	xbc, (xiz+8)                        ; F993AA  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+4)                        ; F993AD  ld XWA,(XBC+0x04)
	ld	xix, xwa                            ; F993B0  ld XIX,XWA
	ld	xiy, (xbc+12)                       ; F993B2  ld XIY,(XBC+0x0c)
	cp	xiy, xwa                            ; F993B5  cp XIY,XWA
	jr nz, Queue_Put_IrqGuarded__F993C0                       ; F993B7  jr NZ,0xf993c0
	ld	xwa, (xbc)                          ; F993B9  ld XWA,(XBC)
	ld	(xbc+12), xwa                       ; F993BB  ld (XBC+0x0c),XWA
	jr Queue_Put_IrqGuarded__F993CA                           ; F993BE  jr T,0xf993ca
Queue_Put_IrqGuarded__F993C0:
	ld	xbc, (xiz+8)                        ; F993C0  ld XBC,(XIZ+0x08)
	sub	xwa, xwa                           ; F993C3  sub XWA,XWA
	inc	1, xwa                             ; F993C5  inc 1,XWA
	add	(xbc+12), xwa                      ; F993C7  add (XBC+0x0c),XWA
Queue_Put_IrqGuarded__F993CA:
	ld	xbc, (xiz+8)                        ; F993CA  ld XBC,(XIZ+0x08)
	ld	wa, (xbc+20)                        ; F993CD  ld WA,(XBC+0x14)
Queue_Put_IrqGuarded__F993D0:
	pop	xix                                ; F993D0  pop XIX
	unlk32 xiz                             ; F993D1  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F993D3  ret

; --------------------------------------------------------------------------
; Queue_Get_IrqGuarded -- take one byte from the read cursor, with the free-count
;             increment bracketed by `ei 6` / `di`.
;
; Called from: 0xF991FA, the `calr 0xF993D4` inside MIDI_Rx_Dequeue, which passes
;          the RECEIVE descriptor 0x00F2FB.  One site.
; Inputs:  (XIZ+0x08) descriptor pointer.
; Outputs: WA = the byte, zero-extended; 0xFFFF when the queue is empty.
; Evidence: empty is `(XBC+0x0c) == (XBC+0x08)`, write cursor equal to read cursor;
;          the byte is fetched from `(XBC+0x08)`, the cursor wrapped the same way
;          as in Queue_Put, and `(XBC+0x14)` incremented.
; ★ THIS IS THE BODY notes/FINDINGS-prom_c-serial-midi.md CALLS UNKNOWN.  That note
;          and MIDI_Rx_Dequeue's header both end with "the layout of the descriptor
;          at 0x00F2FB and the body of 0xF993D4" as open.  Both are now read off
;          instructions, and the RX buffer's extent (0x00007EDA-0x000082D9, 1024
;          bytes) comes out of the boot RAM image.
; Unknown:  nothing about the routine.
; --------------------------------------------------------------------------
Queue_Get_IrqGuarded:
	link32 0xEE, 0x0C, 0xFF, 0xFF          ; F993D4  link XIZ,0xffff   [llvm-mc cannot encode this]
	push	xix                               ; F993D8  push XIX
	ld	xbc, (xiz+8)                        ; F993D9  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+12)                       ; F993DC  ld XWA,(XBC+0x0c)
	ld	xix, xwa                            ; F993DF  ld XIX,XWA
	ld	xiy, (xbc+8)                        ; F993E1  ld XIY,(XBC+0x08)
	cp	xiy, xwa                            ; F993E4  cp XIY,XWA
	jr nz, Queue_Get_IrqGuarded__F993EF                       ; F993E6  jr NZ,0xf993ef
	ldw	wa, 0xFFFF                         ; F993E8  ld WA,0xffff
	jr Queue_Get_IrqGuarded__F9942B                           ; F993EB  jr T,0xf9942b
	jr Queue_Get_IrqGuarded__F993FA                           ; F993ED  jr T,0xf993fa
Queue_Get_IrqGuarded__F993EF:
	ld	xbc, (xiz+8)                        ; F993EF  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+8)                        ; F993F2  ld XWA,(XBC+0x08)
	ld	c, (xwa)                            ; F993F5  ld C,(XWA)
	ld	(xiz-1), c                          ; F993F7  ld (XIZ+0xff),C
Queue_Get_IrqGuarded__F993FA:
	ld	xbc, (xiz+8)                        ; F993FA  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+4)                        ; F993FD  ld XWA,(XBC+0x04)
	ld	xix, xwa                            ; F99400  ld XIX,XWA
	ld	xiy, (xbc+8)                        ; F99402  ld XIY,(XBC+0x08)
	cp	xiy, xwa                            ; F99405  cp XIY,XWA
	jr nz, Queue_Get_IrqGuarded__F99410                       ; F99407  jr NZ,0xf99410
	ld	xwa, (xbc)                          ; F99409  ld XWA,(XBC)
	ld	(xbc+8), xwa                        ; F9940B  ld (XBC+0x08),XWA
	jr Queue_Get_IrqGuarded__F9941A                           ; F9940E  jr T,0xf9941a
Queue_Get_IrqGuarded__F99410:
	ld	xbc, (xiz+8)                        ; F99410  ld XBC,(XIZ+0x08)
	sub	xwa, xwa                           ; F99413  sub XWA,XWA
	inc	1, xwa                             ; F99415  inc 1,XWA
	add	(xbc+8), xwa                       ; F99417  add (XBC+0x08),XWA
Queue_Get_IrqGuarded__F9941A:
	ei	6                                   ; F9941A  ei 0x06
	ld	xbc, (xiz+8)                        ; F9941C  ld XBC,(XIZ+0x08)
	incm	1, (xbc+20)                       ; F9941F  incw 1,(XBC+0x14)
	di                                     ; F99422  ei 0x00
	ld	bc, (xiz-1)                         ; F99424  ld BC,(XIZ+0xff)
	extz	bc                                ; F99427  extz BC
	ld	wa, bc                              ; F99429  ld WA,BC
Queue_Get_IrqGuarded__F9942B:
	pop	xix                                ; F9942B  pop XIX
	unlk32 xiz                             ; F9942C  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F9942E  ret

; --------------------------------------------------------------------------
; Queue_Get -- Queue_Get_IrqGuarded without the guard.
;
; Called from: 0xF99274, the `calr 0xF9942F` inside INTTX0_HANDLER -- which is
;          already inside an interrupt, so the guard would be pointless.  One site.
; Inputs / Outputs: as Queue_Get_IrqGuarded.
; Evidence: 87 bytes against the guarded version's 91; aligned byte by byte the
;          difference is the two inserted pairs `06 06` / `06 00` plus the two
;          branch-displacement bytes at this routine's offsets +0x18 and +0x1A that
;          moved with them.
; Unknown:  nothing.
; --------------------------------------------------------------------------
Queue_Get:
	link32 0xEE, 0x0C, 0xFF, 0xFF          ; F9942F  link XIZ,0xffff   [llvm-mc cannot encode this]
	push	xix                               ; F99433  push XIX
	ld	xbc, (xiz+8)                        ; F99434  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+12)                       ; F99437  ld XWA,(XBC+0x0c)
	ld	xix, xwa                            ; F9943A  ld XIX,XWA
	ld	xiy, (xbc+8)                        ; F9943C  ld XIY,(XBC+0x08)
	cp	xiy, xwa                            ; F9943F  cp XIY,XWA
	jr nz, Queue_Get__F9944A                       ; F99441  jr NZ,0xf9944a
	ldw	wa, 0xFFFF                         ; F99443  ld WA,0xffff
	jr Queue_Get__F99482                           ; F99446  jr T,0xf99482
	jr Queue_Get__F99482                           ; F99448  jr T,0xf99482
Queue_Get__F9944A:
	ld	xbc, (xiz+8)                        ; F9944A  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+8)                        ; F9944D  ld XWA,(XBC+0x08)
	ld	c, (xwa)                            ; F99450  ld C,(XWA)
	ld	(xiz-1), c                          ; F99452  ld (XIZ+0xff),C
	ld	xbc, (xiz+8)                        ; F99455  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+4)                        ; F99458  ld XWA,(XBC+0x04)
	ld	xix, xwa                            ; F9945B  ld XIX,XWA
	ld	xiy, (xbc+8)                        ; F9945D  ld XIY,(XBC+0x08)
	cp	xiy, xwa                            ; F99460  cp XIY,XWA
	jr nz, Queue_Get__F9946B                       ; F99462  jr NZ,0xf9946b
	ld	xwa, (xbc)                          ; F99464  ld XWA,(XBC)
	ld	(xbc+8), xwa                        ; F99466  ld (XBC+0x08),XWA
	jr Queue_Get__F99475                           ; F99469  jr T,0xf99475
Queue_Get__F9946B:
	ld	xbc, (xiz+8)                        ; F9946B  ld XBC,(XIZ+0x08)
	sub	xwa, xwa                           ; F9946E  sub XWA,XWA
	inc	1, xwa                             ; F99470  inc 1,XWA
	add	(xbc+8), xwa                       ; F99472  add (XBC+0x08),XWA
Queue_Get__F99475:
	ld	xbc, (xiz+8)                        ; F99475  ld XBC,(XIZ+0x08)
	incm	1, (xbc+20)                       ; F99478  incw 1,(XBC+0x14)
	ld	bc, (xiz-1)                         ; F9947B  ld BC,(XIZ+0xff)
	extz	bc                                ; F9947E  extz BC
	ld	wa, bc                              ; F99480  ld WA,BC
Queue_Get__F99482:
	pop	xix                                ; F99482  pop XIX
	unlk32 xiz                             ; F99483  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F99485  ret

; --------------------------------------------------------------------------
; Queue_Peek_Cursor2 -- read a byte through the descriptor's SECOND cursor at
;             +0x10, without touching the free count.
;
; Called from: NOT FOUND (notes/prom_c_xrefs.py 0xF99486: no literal, no calr).
; Inputs:  (XIZ+0x08) descriptor pointer.
; Outputs: WA = the byte, or 0xFFFF when the second cursor has caught up with the
;          WRITE cursor.
; Evidence: every access is to `(XBC+0x10)` where Queue_Get uses `(XBC+0x08)`, and
;          the free count at +0x14 is never touched -- so this cursor consumes
;          nothing and a byte can be read twice, once by each.  That is what makes
;          +0x10 a second reader rather than a copy of the first.
;          Both descriptors' boot images set +0x08, +0x0C and +0x10 to the same
;          address (`python3 notes/prom_c_ram_image.py 0x00F2FB:22`).
; Unknown:  ⚠ what the second reader is FOR.  Nothing calls this routine, so the
;          field exists in the struct and in this code and nowhere else that has
;          been found.
; --------------------------------------------------------------------------
Queue_Peek_Cursor2:
	link32 0xEE, 0x0C, 0xFF, 0xFF          ; F99486  link XIZ,0xffff   [llvm-mc cannot encode this]
	push	xix                               ; F9948A  push XIX
	ld	xbc, (xiz+8)                        ; F9948B  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+12)                       ; F9948E  ld XWA,(XBC+0x0c)
	ld	xix, xwa                            ; F99491  ld XIX,XWA
	ld	xiy, (xbc+16)                       ; F99493  ld XIY,(XBC+0x10)
	cp	xiy, xwa                            ; F99496  cp XIY,XWA
	jr nz, Queue_Peek_Cursor2__F994A1                       ; F99498  jr NZ,0xf994a1
	ldw	wa, 0xFFFF                         ; F9949A  ld WA,0xffff
	jr Queue_Peek_Cursor2__F994D3                           ; F9949D  jr T,0xf994d3
	jr Queue_Peek_Cursor2__F994AC                           ; F9949F  jr T,0xf994ac
Queue_Peek_Cursor2__F994A1:
	ld	xbc, (xiz+8)                        ; F994A1  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+16)                       ; F994A4  ld XWA,(XBC+0x10)
	ld	c, (xwa)                            ; F994A7  ld C,(XWA)
	ld	(xiz-1), c                          ; F994A9  ld (XIZ+0xff),C
Queue_Peek_Cursor2__F994AC:
	ld	xbc, (xiz+8)                        ; F994AC  ld XBC,(XIZ+0x08)
	ld	xwa, (xbc+4)                        ; F994AF  ld XWA,(XBC+0x04)
	ld	xix, xwa                            ; F994B2  ld XIX,XWA
	ld	xiy, (xbc+16)                       ; F994B4  ld XIY,(XBC+0x10)
	cp	xiy, xwa                            ; F994B7  cp XIY,XWA
	jr nz, Queue_Peek_Cursor2__F994C2                       ; F994B9  jr NZ,0xf994c2
	ld	xwa, (xbc)                          ; F994BB  ld XWA,(XBC)
	ld	(xbc+16), xwa                       ; F994BD  ld (XBC+0x10),XWA
	jr Queue_Peek_Cursor2__F994CC                           ; F994C0  jr T,0xf994cc
Queue_Peek_Cursor2__F994C2:
	ld	xbc, (xiz+8)                        ; F994C2  ld XBC,(XIZ+0x08)
	sub	xwa, xwa                           ; F994C5  sub XWA,XWA
	inc	1, xwa                             ; F994C7  inc 1,XWA
	add	(xbc+16), xwa                      ; F994C9  add (XBC+0x10),XWA
Queue_Peek_Cursor2__F994CC:
	ld	bc, (xiz-1)                         ; F994CC  ld BC,(XIZ+0xff)
	extz	bc                                ; F994CF  extz BC
	ld	wa, bc                              ; F994D1  ld WA,BC
Queue_Peek_Cursor2__F994D3:
	pop	xix                                ; F994D3  pop XIX
	unlk32 xiz                             ; F994D4  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F994D6  ret

; --------------------------------------------------------------------------
; Queue_FreeSlots -- return the descriptor's free-slot count.
;
; Called from: 0xF991EF, the `calr 0xF994D7` inside sub_F991E9, which passes
;          0x00F2FB.  One site.
; Inputs:  (XIZ+0x08) descriptor pointer.  Outputs: WA = the u16 at +0x14.
; Evidence: three instructions and a return.
; Unknown:  nothing.
; --------------------------------------------------------------------------
Queue_FreeSlots:
	link32 0xEE, 0x0C, 0x00, 0x00          ; F994D7  link XIZ,0x0000   [llvm-mc cannot encode this]
	ld	xbc, (xiz+8)                        ; F994DB  ld XBC,(XIZ+0x08)
	ld	wa, (xbc+20)                        ; F994DE  ld WA,(XBC+0x14)
	unlk32 xiz                             ; F994E1  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F994E3  ret

; --------------------------------------------------------------------------
; ★★ MIDI_Watchdogs_And_TransportSwitch -- active sensing out, active sensing in,
;             and the P8 bit 2 transport input.  Three unrelated jobs in one
;             routine because MAIN calls it once per pass.
;
; Called from: 0xF98CAE (`call 0xF994E4`), the last call in MAIN's loop body.  One
;          site.
; Inputs:  the tick counter 0x00F2F3; the two timestamps 0x007ED2 (last transmit)
;          and 0x007ED6 (last receive, written by INTRX0_HANDLER); the received
;          active-sensing flag 0x00F2F8; port P8 bit 2; the transport state
;          0x00F328.
; Outputs: MIDI_Tx_PutByte(0xFE); Link_SendBuffer(channel 6, length 1, pointer)
;          for the three single-byte messages at 0xFCC5C2, 0xFCC5C3 and 0xFCC5C4.
; Evidence, arm by arm:
;   1. `(0x00F2F3) - (0x007ED2) > 0x87` -> re-stamp 0x007ED2 and `push 0x00FE /
;      calr 0xF992C6`.  0x00FE is an immediate in the instruction, not a table
;      lookup.
;   2. `(0x00F2F8) != 0` AND `(0x00F2F3) - (0x007ED6) > 0xA5` -> clear the flag and
;      send the byte at 0xFCC5C2 (= 0xFF).  0x00F2F8 is set by INTRX0_HANDLER on a
;      received 0xFE and by nothing else in this image, and 0x007ED6 is stamped by
;      the same handler on every good byte -- both are already in that handler's
;      converted header.
;      ⚠ `notes/prom_c_xrefs.py 0x00F2F8` reports FOUR literal-addressed hits, not
;      three.  The extra one, at 0xFBE149, is a byte coincidence: the bytes
;      `e1 f8 f2` there are the tail of `calr 0xFBDA2C` (`1e e1 f8`) followed by
;      the next instruction's prefix.  Checked by disassembling, not assumed.
;   3. `res 2,(P8)` then read P8 and test bit 2.  Clear and `(0x00F328) != 0` ->
;      send the byte at 0xFCC5C4 (= 0xFB) and set 0x00F328 = 0.  Set and
;      `(0x00F328) != 1` -> send the byte at 0xFCC5C3 (= 0xFA) and set
;      0x00F328 = 1.  So the messages go out only on a CHANGE.
; ★ 0x00F328's third value is written elsewhere: Link_Ch2_ForwardBytes sets it to
;   0xFF when CPU 1 sends the byte 0xFA on link channel 2.  0xFF is neither 0 nor
;   1, so the next P8 transition in either direction will send a message.  All five
;   literal-addressed sites of 0x00F328 are accounted for.
; ⚠ NOT ESTABLISHED: what P8 bit 2 is wired to.  `res 2,(P8)` before reading it is
;   the shape of driving a line low and sampling it, which is how an open-collector
;   input is read, but the port direction registers are set in RESET and P8CR's bit
;   layout is not decoded anywhere in this tree.
; ⚠ NOT ESTABLISHED: the tick rate.  See the timing paragraph in the block comment
;   above -- the 135/165-tick pair is consistent with MIDI's 300 ms active-sensing
;   rule, but that is an argument from the standard, not from this ROM.
; --------------------------------------------------------------------------
MIDI_Watchdogs_And_TransportSwitch:
	link32 0xEE, 0x0C, 0xFC, 0xFF          ; F994E4  link XIZ,0xfffc   [llvm-mc cannot encode this]
	ldl_da	xbc, (0xF2F3)                   ; F994E8  ld XBC,(0x00f2f3)
	sub32_24	xbc, (0x7ED2)                 ; F994ED  sub XBC,(0x007ed2)
	ld	(xiz-4), xbc                        ; F994F2  ld (XIZ+0xfc),XBC
	cp	xbc, 0x87                           ; F994F5  cp XBC,0x00000087
	jr ule, MIDI_Watchdogs_And_TransportSwitch__F9950E                      ; F994FB  jr ULE,0xf9950e
	ldl_da	xwa, (0xF2F3)                   ; F994FD  ld XWA,(0x00f2f3)
	stl_da	(0x7ED2), xwa                   ; F99502  ld (0x007ed2),XWA
	pushw	0xFE                             ; F99507  push 0x00fe
	calr (0xF992C6 - 0xF9950D)             ; F9950A  calr 0xf992c6
	popw	bc                                ; F9950D  pop BC
MIDI_Watchdogs_And_TransportSwitch__F9950E:
	cpib_da 0x00F2F8, 0x00                 ; F9950E  cp (0x00f2f8),0x00   [llvm-mc cannot encode this]
	jr z, MIDI_Watchdogs_And_TransportSwitch__F99543                        ; F99514  jr Z,0xf99543
	ldl_da	xbc, (0xF2F3)                   ; F99516  ld XBC,(0x00f2f3)
	sub32_24	xbc, (0x7ED6)                 ; F9951B  sub XBC,(0x007ed6)
	ld	(xiz-4), xbc                        ; F99520  ld (XIZ+0xfc),XBC
	cp	xbc, 0xA5                           ; F99523  cp XBC,0x000000a5
	jr ule, MIDI_Watchdogs_And_TransportSwitch__F99543                      ; F99529  jr ULE,0xf99543
	stib_da	(0xF2F8), 0                    ; F9952B  ld (0x00f2f8),0x00
	lda_24	xwa, (0xFCC5C2)                 ; F99531  lda XWA,0xfcc5c2
	push	xwa                               ; F99536  push XWA
	pushw	1                                ; F99537  push 0x0001
	pushw	6                                ; F9953A  push 0x0006
	call	0xF98B20                          ; F9953D  call 0xf98b20
	inc	8, xsp                             ; F99541  inc 0,XSP
MIDI_Watchdogs_And_TransportSwitch__F99543:
	res_dd8	2, P8                          ; F99543  res 2,(0x18)
	ld_sd8b	c, 24                          ; F99546  ld C,(0x18)
	and	c, 4                               ; F99549  and C,0x04
	srl	c, 2                               ; F9954C  srl 0x02,C
	cps	c, 0                               ; F9954F  cp C,0
	jr nz, MIDI_Watchdogs_And_TransportSwitch__F99575                       ; F99551  jr NZ,0xf99575
	cpib_da 0x00F328, 0x00                 ; F99553  cp (0x00f328),0x00   [llvm-mc cannot encode this]
	jr z, MIDI_Watchdogs_And_TransportSwitch__F99573                        ; F99559  jr Z,0xf99573
	lda_24	xbc, (0xFCC5C4)                 ; F9955B  lda XBC,0xfcc5c4
	push	xbc                               ; F99560  push XBC
	pushw	1                                ; F99561  push 0x0001
	pushw	6                                ; F99564  push 0x0006
	call	0xF98B20                          ; F99567  call 0xf98b20
	stib_da	(0xF328), 0                    ; F9956B  ld (0x00f328),0x00
	inc	8, xsp                             ; F99571  inc 0,XSP
MIDI_Watchdogs_And_TransportSwitch__F99573:
	jr MIDI_Watchdogs_And_TransportSwitch__F99595                           ; F99573  jr T,0xf99595
MIDI_Watchdogs_And_TransportSwitch__F99575:
	cpib_da 0x00F328, 0x01                 ; F99575  cp (0x00f328),0x01   [llvm-mc cannot encode this]
	jr z, MIDI_Watchdogs_And_TransportSwitch__F99595                        ; F9957B  jr Z,0xf99595
	lda_24	xbc, (0xFCC5C3)                 ; F9957D  lda XBC,0xfcc5c3
	push	xbc                               ; F99582  push XBC
	pushw	1                                ; F99583  push 0x0001
	pushw	6                                ; F99586  push 0x0006
	call	0xF98B20                          ; F99589  call 0xf98b20
	stib_da	(0xF328), 1                    ; F9958D  ld (0x00f328),0x01
	inc	8, xsp                             ; F99593  inc 0,XSP
MIDI_Watchdogs_And_TransportSwitch__F99595:
	unlk32 xiz                             ; F99595  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F99597  ret

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
; 0xF9973D-0xF99BBD -- THE KEYBOARD SCANNER at 0x00108000, the per-note touch
;                      calibration, and CPU 2's half of the link TRANSMITTER
;                      10 routines, 1,153 bytes
; ==============================================================================
;
; ★★ 0x00108000 IS THE KEY-SCAN PORT, AND ITS 16-BIT WORD IS {touch, key event}.
; notes/FINDINGS-memory-map.md lists 0x108000 as "same shape" as the other two
; address/data devices with the note "Three sites, not five: 0xF9914D, 0xF99776,
; 0xF998C6".  Two of those three are in this block, and they settle what the port
; carries -- not by resemblance, but because the word they read is handed
; STRAIGHT to a routine whose argument meanings are already converted:
;
;     +2  read  a status word.  Bit 0 gates everything: KeyScan_ReadEvent returns
;               "no event" unless it is set (0xF9976F `and BC,0x0001`).  The whole
;               word is separately compared against 2 (0xF9979A).
;     +0  read  one key event, 16 bits:
;                   low  byte  bit 7 = note ON, bits 6..0 = key number
;                   high byte  the touch measurement
;
; The low/high split is READ OFF THE CALL, not guessed.  Both call sites push the
; two bytes as the first two arguments of ToneGen_VelocityFromTouch (0xF995DF,
; converted above), whose own header -- written before this block existed --
; already says (XIZ+0x08) is "the touch measurement, index into
; ToneGen_Velocity_Input_Curve" and (XIZ+0x0a) is "bit 7 = note ON, bits 6..0 =
; note number".  The argument that lands in each slot follows from the push
; widths, and those are cited: `push #imm8` (0x09) and `push (mem)` in byte size
; (0x8E .. 0x04) each move ONE byte -- op_PUSHBI and op_PUSHBM in
; mame/src/devices/cpu/tlcs900/900tbl.hxx:2935-2946 -- so each
; `push 0x00 / push (XIZ+d)` PAIR builds one zero-extended 16-bit argument, and
; the pair pushed LAST is the one at (XIZ+0x08).  The caller drops 12 bytes
; afterwards (`inc 8,xsp` + `inc 4,xsp`), which is exactly 4+4+1+1+1+1.
;
; ★ THE KEYBOARD HAS 61 KEYS, AND THE NUMBER COMES OUT TWICE.
;   * KeyScan_InitKeyStateBitmap folds each event into a bit at
;     base[(key>>3)&7] bit (key&7) -- an EIGHT-byte bitmap, so 64 bit positions.
;   * NoteTrim_BuildFromCalibration walks note 0..0x3C inclusive -- `cp
;     (XIZ-2),0x003D / jr GE` -- which is 61 notes, and it is the SAME index that
;     ToneGen_VelocityFromTouch uses to read 0x0084DA.
;   61 keys in a 64-bit map is what a 61-key instrument needs; 64 would fit
;   exactly and 61 is what the firmware actually walks.  Stated as read.
;
; ★★ THE ORIGIN OF THE PER-NOTE TRIM TABLE AT 0x0084DA IS NOW KNOWN.
; notes/FINDINGS-prom_c-voice-tables.md §3 ends with "find what writes the signed
; per-note table at 0x0084DA.  It is the only term of the velocity formula whose
; origin is unknown".  NoteTrim_BuildFromCalibration (0xF997FA) is the writer, and
; it is the ONLY one.  `python3 notes/prom_c_xrefs.py 0x0084DA --no-window
; --classify` reports THREE literal-addressed sites in the whole image, and the
; instruction each one belongs to starts two bytes before the literal it prints:
; 0xF99829 and 0xF9987F -- both `add XBC,0x000084DA` in this block, each feeding
; a WRITE -- and 0xF9964D, the `add XWA,0x000084DA` inside
; ToneGen_VelocityFromTouch that feeds its only READ.  The rule is
;
;     trim[note] = ToneGen_VelCurve_Trim51[ clamp(cal[note] - 0x4B, 0, 50) ]
;
; with ToneGen_VelCurve_Trim51 at ROM 0xFCC5C9 (already emitted in the zone-2
; listing below) and cal[] the byte array returned by
; 0xFC8B0B; if that routine returns a null pointer, all 61 trims are set to zero.
;
; ★ AND IT CONFIRMS ToneGen_VelCurve_Trim51 FROM THE CODE SIDE.
; ⚠ RETRACTION, SAME SESSION: an earlier draft of this header said the table at
; 0xFCC5C9 was "unidentified" and claimed to decode it.  It was NOT unidentified --
; the zone-2 listing further down this file already emits it as
; ToneGen_VelCurve_Trim51, 51 bytes, sized by the object chain.  What this pass
; actually adds is the INDEPENDENT confirmation and the purpose:
;   * the clamp here is `cp A,0 / jr GE` then `cp (XIZ-7),0x32 / jr LE`, so the
;     index range is exactly 0..0x32 = 51 values -- the code's own bound agrees
;     with the size the data chain gave, which it did not have to;
;   * the curve is what turns a per-note CALIBRATION byte into the signed velocity
;     trim at 0x0084DA, which is what the table is FOR.
; 0xFCC5C9 + 51 = 0xFCC5FC, which is where ToneGen_VelCurve_ModeParams begins.
;
; ★ 0xFCC81A IS NOT THE START OF A FLOAT POOL.  The zone-2 text in this file
; leaves 0xFCC81A-0xFCCA81 as a deliberate `.incbin`, calling it "an IEEE-754
; constant pool ... the element boundaries are not established".  Its FIRST FOUR
; BYTES are not a float: they are `f0 ff 00 00` = the 32-bit constant 0x0000FFF0,
; and all three references to 0xFCC81A in the image are the same instruction,
; `add XBC,(0xFCC81A)` (0xF998AA, 0xF99910, 0xF99930), adding it to a 0..7 index.
; So bytes 0..3 of that block are the BASE OF THE KEY-STATE BITMAP, at work DRAM
; 0x0000FFF0-0x0000FFF7.  The remaining 612 bytes are untouched by this pass.
; ⚠ 0x0000FFF0 occurs as a 32-bit literal in exactly three places in prom_c --
; 0xF980EE (EntryPoint_Records' second column), 0xFCC81A (here) and 0xFFF007
; (RESET's `ld XSP,0x0000FFF0`).  The boot stack and the key bitmap are therefore
; the SAME eight bytes at two different times: RESET's stack is moved down to
; 0x0000FA00 at 0xF9816B before MAIN runs, and the bitmap is not built until
; MAIN's init chain reaches 0xF997FA.  Nothing here says the two uses were meant
; to overlap; they are recorded because they do.
; ⚠ And nothing in prom_c READS the bitmap by literal address.  The three sites
; above are its only literal-addressed users and all three are writes.  A reader
; through a pointer would be invisible to that census, so this is "no
; literal-addressed reader", not "nobody reads it".
;
; ★ TIMER 2 IS THE BYTE CLOCK OF THE OUTBOUND LINK.  Link_Init stops timer 2
; (`res 2,(TRUN)`), programs T23MOD = 0x0E and TREG2 = 5, and arms micro-DMA
; channel 2 on it; every one of the four senders below ends with
; `ldio DMA2V,0x12` + `set 2,(TRUN)`.  0x12 << 2 = 0x48 = INTT2
; (tmp95c061.cpp:353 and the vector map at :322-346), so each timer-2 tick moves
; one byte out of the packet buffer into the port at 0x00100000 and the CPU is
; not involved until INTTC2.  This is the transmit mirror of the receive path
; already documented in notes/FINDINGS-prom_c-link-receive.md.
;
; ⚠ WHAT THIS BLOCK DOES NOT ESTABLISH.  What the status word's value 2 means; the
; physical unit of the touch byte; what 0xFC8B0B reads its 62-byte block FROM;
; what 0x008517, 0x008535-0x008537 and 0x00852B are beyond the one bit each site
; touches.
;
; Transcribed with notes/llvm_roundtrip_autoforce.py c 0xF9973D 0x481, restyled by
; notes/prom_c_listing_prep.py and re-proved before insertion with
; `python3 notes/prom_c_verify_fragment.py c 0xF9973D <file>`.

; --------------------------------------------------------------------------
; KeyScan_ReadEvent -- take ONE key event off the scanner at 0x00108000 and turn
;             it into a note number and a velocity.
;
; Called from: 0xF98CD4 and 0xF98D0F, both `call 0xF9973D`
;          (notes/prom_c_xrefs.py 0xF9973D -- the tool prints the literal at
;          0xF98CD5/0xF98D10 and names the instruction start).  Both sites are
;          inside 0xF98CB9, which MAIN calls on every pass.
; Inputs:  (XIZ+0x08) ptr, receives the note number.
;          (XIZ+0x0c) ptr, receives the velocity byte.
;          Device: 0x00108002 status, 0x00108000 event.  Global: 0x00F329.
; Outputs: WA = 0 if an event was decoded, 0xFFFF if not.  *(XIZ+0x08) and
;          *(XIZ+0x0c) are written by ToneGen_VelocityFromTouch, which this
;          routine calls with the two device bytes.
; Evidence: the argument-to-slot mapping and the port layout are derived in the
;          block comment above, from the push widths cited there.  The two
;          pointer arguments are passed straight through: the routine pushes
;          (XIZ+0x0c) FIRST and (XIZ+0x08) second, and the callee's converted
;          header says its (XIZ+0x10) receives the velocity and its (XIZ+0x0c)
;          the note -- so this routine's +0x08 is the note pointer and its +0x0c
;          the velocity pointer.
; ★ THE SCANNER IS NOT READ FOR THE FIRST 1000 TICKS.  While (0x00F329) is zero
;          the routine returns 0xFFFF without touching the device, and it only
;          sets that byte once the INTT1 tick counter at 0x00F2F3 has passed
;          0x3E8 = 1000 (`cp XBC,0x000003E8 / jr ULE`).  0x00F329 is written by
;          exactly one instruction in the image and read by exactly one
;          (notes/prom_c_xrefs.py 0x00F329), both of them here, so this is a
;          one-shot arming latch and nothing else can clear it.
;          ⚠ The tick RATE is still not established (see the INTT1 header), so
;          1000 ticks cannot be turned into milliseconds.
; ★ THE THREE OUTCOMES, read off the branches at 0xF99795-0xF997B4:
;          (a) touch byte != 0xFF and status word != 2  -> decode normally.
;          (b) touch byte == 0xFF, or status word == 2:
;                 note ON  -> `or (0x008517),0x03`, return 0xFFFF, event dropped;
;                 note OFF -> decode, then FORCE the velocity byte to 0.
;          ⚠ "touch byte == 0xFF means no travel time was measured" fits (b) --
;          a note-on with no touch value cannot be given a velocity, a note-off
;          does not need one -- but nothing here proves it and 0x008517 is
;          referenced by this one instruction alone in the whole image, so what
;          collects the two bits is unknown.
; Unknown:  the meaning of status-word value 2; who reads 0x008517.
; --------------------------------------------------------------------------
KeyScan_ReadEvent:
	link32 0xEE, 0x0C, 0xFA, 0xFF          ; F9973D  link XIZ,0xfffa   [llvm-mc cannot encode this]
	cpib_da 0x00F329, 0x00                 ; F99741  cp (0x00f329),0x00   [llvm-mc cannot encode this]
	jr nz, KeyScan_ReadEvent__F99762                       ; F99747  jr NZ,0xf99762
	ldl_da	xbc, (0xF2F3)                   ; F99749  ld XBC,(0x00f2f3)
	cp	xbc, 0x3E8                          ; F9974E  cp XBC,0x000003e8
	jr ule, KeyScan_ReadEvent__F9975C                      ; F99754  jr ULE,0xf9975c
	stib_da	(0xF329), 1                    ; F99756  ld (0x00f329),0x01
KeyScan_ReadEvent__F9975C:
	ldw	wa, 0xFFFF                         ; F9975C  ld WA,0xffff
	jrl KeyScan_ReadEvent__F997F7                          ; F9975F  jrl T,0xf997f7
KeyScan_ReadEvent__F99762:
	ld	xbc, 0x108002                       ; F99762  ld XBC,0x00108002
	ld	wa, (xbc)                           ; F99767  ld WA,(XBC)
	ld	(xiz-6), wa                         ; F99769  ld (XIZ+0xfa),WA
	ld	bc, (xiz-6)                         ; F9976C  ld BC,(XIZ+0xfa)
	and	bc, 1                              ; F9976F  and BC,0x0001
	jrl z, KeyScan_ReadEvent__F997F4                       ; F99773  jrl Z,0xf997f4
	ld	xbc, 0x108000                       ; F99776  ld XBC,0x00108000
	ld	wa, (xbc)                           ; F9977B  ld WA,(XBC)
	ld	(xiz-4), wa                         ; F9977D  ld (XIZ+0xfc),WA
	ld	c, (xiz-4)                          ; F99780  ld C,(XIZ+0xfc)
	and	c, 0xFF                            ; F99783  and C,0xff
	ld	(xiz-1), c                          ; F99786  ld (XIZ+0xff),C
	ld	bc, (xiz-4)                         ; F99789  ld BC,(XIZ+0xfc)
	srl	bc, 8                              ; F9978C  srl 0x08,BC
	and	c, 0xFF                            ; F9978F  and C,0xff
	ld	(xiz-2), c                          ; F99792  ld (XIZ+0xfe),C
	cp	c, 0xFF                             ; F99795  cp C,0xff
	jr z, KeyScan_ReadEvent__F997A1                        ; F99798  jr Z,0xf997a1
	cpw (xiz-6), 0x0002                    ; F9979A  cp (XIZ+0xfa),0x0002   [llvm-mc cannot encode this]
	jr nz, KeyScan_ReadEvent__F997D7                       ; F9979F  jr NZ,0xf997d7
KeyScan_ReadEvent__F997A1:
	ld	c, (xiz-1)                          ; F997A1  ld C,(XIZ+0xff)
	and	c, 0x80                            ; F997A4  and C,0x80
	jr z, KeyScan_ReadEvent__F997B6                        ; F997A7  jr Z,0xf997b6
	extpfx6 0xC2, 0x17, 0x85, 0x00, 0x3E, 0x03 ; F997A9  or (0x008517),0x03   [llvm-mc cannot encode this]
	ldw	wa, 0xFFFF                         ; F997AF  ld WA,0xffff
	jr KeyScan_ReadEvent__F997F7                           ; F997B2  jr T,0xf997f7
	jr KeyScan_ReadEvent__F997D5                           ; F997B4  jr T,0xf997d5
KeyScan_ReadEvent__F997B6:
	ld	xbc, (xiz+12)                       ; F997B6  ld XBC,(XIZ+0x0c)
	push	xbc                               ; F997B9  push XBC
	ld	xwa, (xiz+8)                        ; F997BA  ld XWA,(XIZ+0x08)
	push	xwa                               ; F997BD  push XWA
	push	0                                 ; F997BE  push 0x00
	extpfx3 0x8E, 0xFF, 0x04               ; F997C0  push (XIZ+0xff)   [llvm-mc cannot encode this]
	push	0                                 ; F997C3  push 0x00
	extpfx3 0x8E, 0xFE, 0x04               ; F997C5  push (XIZ+0xfe)   [llvm-mc cannot encode this]
	calr (0xF995DF - 0xF997CB)             ; F997C8  calr 0xf995df
	ld	xbc, (xiz+12)                       ; F997CB  ld XBC,(XIZ+0x0c)
	ld	(xbc), 0                            ; F997CE  ld (XBC),0x00
	inc	8, xsp                             ; F997D1  inc 0,XSP
	inc	4, xsp                             ; F997D3  inc 4,XSP
KeyScan_ReadEvent__F997D5:
	jr KeyScan_ReadEvent__F997F0                           ; F997D5  jr T,0xf997f0
KeyScan_ReadEvent__F997D7:
	ld	xbc, (xiz+12)                       ; F997D7  ld XBC,(XIZ+0x0c)
	push	xbc                               ; F997DA  push XBC
	ld	xwa, (xiz+8)                        ; F997DB  ld XWA,(XIZ+0x08)
	push	xwa                               ; F997DE  push XWA
	push	0                                 ; F997DF  push 0x00
	extpfx3 0x8E, 0xFF, 0x04               ; F997E1  push (XIZ+0xff)   [llvm-mc cannot encode this]
	push	0                                 ; F997E4  push 0x00
	extpfx3 0x8E, 0xFE, 0x04               ; F997E6  push (XIZ+0xfe)   [llvm-mc cannot encode this]
	calr (0xF995DF - 0xF997EC)             ; F997E9  calr 0xf995df
	inc	8, xsp                             ; F997EC  inc 0,XSP
	inc	4, xsp                             ; F997EE  inc 4,XSP
KeyScan_ReadEvent__F997F0:
	sub	wa, wa                             ; F997F0  sub WA,WA
	jr KeyScan_ReadEvent__F997F7                           ; F997F2  jr T,0xf997f7
KeyScan_ReadEvent__F997F4:
	ldw	wa, 0xFFFF                         ; F997F4  ld WA,0xffff
KeyScan_ReadEvent__F997F7:
	unlk32 xiz                             ; F997F7  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F997F9  ret

; --------------------------------------------------------------------------
; NoteTrim_BuildFromCalibration -- fill the 61-entry signed per-note velocity trim
;             table at 0x0084DA from a checksummed calibration block.
;
; Called from: 0xF98B99 (`call 0xF997FA`), in MAIN's power-on init chain -- the
;          same chain that calls DSP_ChannelRegs_Init and Link_Init.  One site.
; Inputs:  none.  It calls KeyScan_InitKeyStateBitmap first, then 0xFC8B0B.
; Outputs: 0x0084DA[0..0x3C], 61 signed bytes.
; Evidence: ★ 0xFC8B0B RETURNS ITS ANSWER IN XIY, and the branch here is
;          `cp XIY,0x00000000 / jr NZ`, so a null return is a defined case: the
;          zero arm writes 0 to all 61 entries and returns.  The non-null arm
;          reads `cal[i] = (XIY)[i]`, subtracts 0x4B = 75, clamps the result to
;          0..0x32 = 0..50, and uses it to index the signed byte curve at ROM
;          0xFCC5C9, storing the looked-up byte at 0x0084DA + i.
;          ★ THE ENTRY COUNT IS 61 AND THE LAST ENTRY IS THE TEST.  The loop
;          guard is `cp (XIZ-2),0x003D / jr GE,done`, so i runs 0..0x3C
;          inclusive; entry 0x3C is written by the same instruction as entry 0
;          and is inside the same guard.  61 is also the count
;          ToneGen_VelocityFromTouch can reach, because it indexes 0x0084DA with
;          `note & 0x7F` and the scanner's key numbers are what fill that field.
;          ★ THE 51-ENTRY CURVE IS BOUNDED BY THE CLAMP.  0..0x32 is 51 values
;          and 0xFCC5C9 + 51 = 0xFCC5FC, exactly where
;          ToneGen_VelCurve_ModeParams starts (see the zone-2 chain below).  So
;          the code's bound and the data's next-object boundary agree without
;          either being assumed from the other.
;          ⚠ 0xFC8B0B is NOT CONVERTED.  What is read off it, and stated as read:
;          it fills 31 words at RAM 0x00E2A1 through 0xFC8A29/0xFC8ADA,
;          accumulates their sum in DE, compares that sum with a further word,
;          then requires yet another word to equal 0x5AA5, and returns
;          XIY = 0x00E2A1 on success or XIY = 0 on failure (0xFC8B5F-0xFC8B77).
;          A 62-byte block with a checksum and a magic is what a stored
;          calibration looks like; WHERE it is read from is not established here
;          and the name says only what this routine does with it.
; Unknown:  the source medium behind 0xFC8B0B; the physical meaning of the 75
;          that is subtracted (the curve is zero for cal values 0x61..0x65).
; --------------------------------------------------------------------------
NoteTrim_BuildFromCalibration:
	link32 0xEE, 0x0C, 0xF9, 0xFF          ; F997FA  link XIZ,0xfff9   [llvm-mc cannot encode this]
	pushw	hl                               ; F997FE  push HL
	calr (0xF9988D - 0xF99802)             ; F997FF  calr 0xf9988d
	call	0xFC8B0B                          ; F99802  call 0xfc8b0b
	ld	(xiz-6), xiy                        ; F99806  ld (XIZ+0xfa),XIY
	cp	xiy, 0                              ; F99809  cp XIY,0x00000000
	jr nz, NoteTrim_BuildFromCalibration__F99836                       ; F9980F  jr NZ,0xf99836
	ldw (xiz-2), 0x0000                    ; F99811  ld (XIZ+0xfe),0x0000   [llvm-mc cannot encode this]
NoteTrim_BuildFromCalibration__F99816:
	cpw (xiz-2), 0x003D                    ; F99816  cp (XIZ+0xfe),0x003d   [llvm-mc cannot encode this]
	jr ge, NoteTrim_BuildFromCalibration__F99834                       ; F9981B  jr GE,0xf99834
	jr NoteTrim_BuildFromCalibration__F99824                           ; F9981D  jr T,0xf99824
NoteTrim_BuildFromCalibration__F9981F:
	incm	1, (xiz-2)                        ; F9981F  incw 1,(XIZ+0xfe)
	jr NoteTrim_BuildFromCalibration__F99816                           ; F99822  jr T,0xf99816
NoteTrim_BuildFromCalibration__F99824:
	ld	bc, (xiz-2)                         ; F99824  ld BC,(XIZ+0xfe)
	exts	xbc                               ; F99827  exts XBC
	add	xbc, 0x84DA                        ; F99829  add XBC,0x000084da
	ld	(xbc), 0                            ; F9982F  ld (XBC),0x00
	jr NoteTrim_BuildFromCalibration__F9981F                           ; F99832  jr T,0xf9981f
NoteTrim_BuildFromCalibration__F99834:
	jr NoteTrim_BuildFromCalibration__F99889                           ; F99834  jr T,0xf99889
NoteTrim_BuildFromCalibration__F99836:
	ldw (xiz-2), 0x0000                    ; F99836  ld (XIZ+0xfe),0x0000   [llvm-mc cannot encode this]
NoteTrim_BuildFromCalibration__F9983B:
	cpw (xiz-2), 0x003D                    ; F9983B  cp (XIZ+0xfe),0x003d   [llvm-mc cannot encode this]
	jr ge, NoteTrim_BuildFromCalibration__F99889                       ; F99840  jr GE,0xf99889
	jr NoteTrim_BuildFromCalibration__F99849                           ; F99842  jr T,0xf99849
NoteTrim_BuildFromCalibration__F99844:
	incm	1, (xiz-2)                        ; F99844  incw 1,(XIZ+0xfe)
	jr NoteTrim_BuildFromCalibration__F9983B                           ; F99847  jr T,0xf9983b
NoteTrim_BuildFromCalibration__F99849:
	ld	bc, (xiz-2)                         ; F99849  ld BC,(XIZ+0xfe)
	exts	xbc                               ; F9984C  exts XBC
	extpfx3 0xAE, 0xFA, 0x81               ; F9984E  add XBC,(XIZ+0xfa)   [llvm-mc cannot encode this]
	ld	a, (xbc)                            ; F99851  ld A,(XBC)
	sub	a, 75                              ; F99853  sub A,0x4b
	ld	(xiz-7), a                          ; F99856  ld (XIZ+0xf9),A
	cps	a, 0                               ; F99859  cp A,0
	jr ge, NoteTrim_BuildFromCalibration__F99861                       ; F9985B  jr GE,0xf99861
	ld	(xiz-7), 0                          ; F9985D  ld (XIZ+0xf9),0x00
NoteTrim_BuildFromCalibration__F99861:
	cp (xiz-7), 0x32                       ; F99861  cp (XIZ+0xf9),0x32   [llvm-mc cannot encode this]
	jr le, NoteTrim_BuildFromCalibration__F9986B                       ; F99865  jr LE,0xf9986b
	ld	(xiz-7), 50                         ; F99867  ld (XIZ+0xf9),0x32
NoteTrim_BuildFromCalibration__F9986B:
	ld	bc, (xiz-7)                         ; F9986B  ld BC,(XIZ+0xf9)
	exts	bc                                ; F9986E  exts BC
	exts	xbc                               ; F99870  exts XBC
	add	xbc, 0xFCC5C9                      ; F99872  add XBC,0x00fcc5c9
	ld	h, (xbc)                            ; F99878  ld H,(XBC)
	ld	bc, (xiz-2)                         ; F9987A  ld BC,(XIZ+0xfe)
	exts	xbc                               ; F9987D  exts XBC
	add	xbc, 0x84DA                        ; F9987F  add XBC,0x000084da
	ld	(xbc), h                            ; F99885  ld (XBC),H
	jr NoteTrim_BuildFromCalibration__F99844                           ; F99887  jr T,0xf99844
NoteTrim_BuildFromCalibration__F99889:
	popw	hl                                ; F99889  pop HL
	unlk32 xiz                             ; F9988A  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F9988C  ret

; --------------------------------------------------------------------------
; KeyScan_InitKeyStateBitmap -- clear the 8-byte key-state bitmap and fold the
;             next SIXTEEN scanner events into it.
;
; Called from: 0xF997FA (`calr 0xF9988D`, the instruction at 0xF997FF).  One
;          site; notes/prom_c_xrefs.py 0xF9988D.
; Inputs:  the scanner at 0x00108000.  Base pointer: the 32-bit constant at ROM
;          0xFCC81A, which is 0x0000FFF0.
; Outputs: 0x0000FFF0-0x0000FFF7, one bit per key.
; Evidence: two counted loops, both bounded by an UNSIGNED compare:
;          `cp (XIZ-7),0x08 / jr NC` clears eight bytes, and
;          `cp (XIZ-7),0x10 / jr NC` runs the body sixteen times.  The body reads
;          0x00108000 once per pass, splits the word exactly as
;          KeyScan_ReadEvent does, and computes byte = (low >> 3) & 7,
;          bit = low & 7 -- so eight bytes hold 64 bit positions and key numbers
;          above 63 would alias, which the 61-key walk in
;          NoteTrim_BuildFromCalibration says they never are.
;          ★ THE BIT MASK COMES FROM THE COMPILER'S SHIFT HELPER, and the helper
;          is decoded rather than assumed: 0xFCA0BA reads (XSP+4) into IY and the
;          BYTE at (XSP+6) into B, then does `sll A,IY` twice with A = B>>4 = 0
;          and A = B & 0x0F.  A shift count of ZERO on TLCS-900 means SIXTEEN --
;          `count = (s & 0x0f) ? (s & 0x0f) : 16` in
;          mame/src/devices/cpu/tlcs900/900tbl.hxx:990-992 -- which is what makes
;          the first `sll` the "count >= 16" arm and not a no-op.  Both call
;          sites here pass the value 1 and the count (key & 7), so A comes back
;          holding 1 << (key & 7): the note-on arm ORs it in, the note-off arm
;          complements it and ANDs.
;          ⚠ The note-on arm pushes WA whose high byte is the leftover
;          (low & 0x80); only the byte at (XSP+6) is read by the helper, so the
;          high half is dead.  Recorded because it looks like an argument and is
;          not one.
; Unknown:  ⚠ WHY SIXTEEN.  Nothing here bounds the scanner's queue; 16 is a
;          literal and the routine runs once, at boot.  Also: nothing in prom_c
;          reads the bitmap through a literal address (see the block comment), so
;          its consumer has not been found.
; --------------------------------------------------------------------------
KeyScan_InitKeyStateBitmap:
	link32 0xEE, 0x0C, 0xF9, 0xFF          ; F9988D  link XIZ,0xfff9   [llvm-mc cannot encode this]
	pushw	hl                               ; F99891  push HL
	ld	(xiz-7), 0                          ; F99892  ld (XIZ+0xf9),0x00
KeyScan_InitKeyStateBitmap__F99896:
	cp (xiz-7), 0x08                       ; F99896  cp (XIZ+0xf9),0x08   [llvm-mc cannot encode this]
	jr nc, KeyScan_InitKeyStateBitmap__F998B4                       ; F9989A  jr NC,0xf998b4
	jr KeyScan_InitKeyStateBitmap__F998A3                           ; F9989C  jr T,0xf998a3
KeyScan_InitKeyStateBitmap__F9989E:
	incm8	1, (xiz-7)                       ; F9989E  inc 1,(XIZ+0xf9)
	jr KeyScan_InitKeyStateBitmap__F99896                           ; F998A1  jr T,0xf99896
KeyScan_InitKeyStateBitmap__F998A3:
	ld	bc, (xiz-7)                         ; F998A3  ld BC,(XIZ+0xf9)
	extz	bc                                ; F998A6  extz BC
	extz	xbc                               ; F998A8  extz XBC
	addda32_24	xbc, (0xFCC81A)             ; F998AA  add XBC,(0xfcc81a)
	ld	(xbc), 0                            ; F998AF  ld (XBC),0x00
	jr KeyScan_InitKeyStateBitmap__F9989E                           ; F998B2  jr T,0xf9989e
KeyScan_InitKeyStateBitmap__F998B4:
	ld	(xiz-7), 0                          ; F998B4  ld (XIZ+0xf9),0x00
KeyScan_InitKeyStateBitmap__F998B8:
	cp (xiz-7), 0x10                       ; F998B8  cp (XIZ+0xf9),0x10   [llvm-mc cannot encode this]
	jrl nc, KeyScan_InitKeyStateBitmap__F99939                      ; F998BC  jrl NC,0xf99939
	jr KeyScan_InitKeyStateBitmap__F998C6                           ; F998BF  jr T,0xf998c6
KeyScan_InitKeyStateBitmap__F998C1:
	incm8	1, (xiz-7)                       ; F998C1  inc 1,(XIZ+0xf9)
	jr KeyScan_InitKeyStateBitmap__F998B8                           ; F998C4  jr T,0xf998b8
KeyScan_InitKeyStateBitmap__F998C6:
	ld	xbc, 0x108000                       ; F998C6  ld XBC,0x00108000
	ld	wa, (xbc)                           ; F998CB  ld WA,(XBC)
	ld	(xiz-6), wa                         ; F998CD  ld (XIZ+0xfa),WA
	and	a, 0xFF                            ; F998D0  and A,0xff
	ld	(xiz-1), a                          ; F998D3  ld (XIZ+0xff),A
	ld	bc, (xiz-6)                         ; F998D6  ld BC,(XIZ+0xfa)
	srl	bc, 8                              ; F998D9  srl 0x08,BC
	and	c, 0xFF                            ; F998DC  and C,0xff
	ld	(xiz-2), c                          ; F998DF  ld (XIZ+0xfe),C
	ld	b, (xiz-1)                          ; F998E2  ld B,(XIZ+0xff)
	srl	b, 3                               ; F998E5  srl 0x03,B
	and	b, 7                               ; F998E8  and B,0x07
	ld	(xiz-3), b                          ; F998EB  ld (XIZ+0xfd),B
	ld	a, (xiz-1)                          ; F998EE  ld A,(XIZ+0xff)
	and	a, 7                               ; F998F1  and A,0x07
	ld	(xiz-4), a                          ; F998F4  ld (XIZ+0xfc),A
	ld	w, (xiz-1)                          ; F998F7  ld W,(XIZ+0xff)
	and	w, 0x80                            ; F998FA  and W,0x80
	jr z, KeyScan_InitKeyStateBitmap__F99919                        ; F998FD  jr Z,0xf99919
	pushw	wa                               ; F998FF  push WA
	pushw	1                                ; F99900  push 0x0001
	call	0xFCA0BA                          ; F99903  call 0xfca0ba
	ld	h, a                                ; F99907  ld H,A
	ld	bc, (xiz-3)                         ; F99909  ld BC,(XIZ+0xfd)
	extz	bc                                ; F9990C  extz BC
	extz	xbc                               ; F9990E  extz XBC
	addda32_24	xbc, (0xFCC81A)             ; F99910  add XBC,(0xfcc81a)
	or	(xbc), a                            ; F99915  or (XBC),A
	jr KeyScan_InitKeyStateBitmap__F99937                           ; F99917  jr T,0xf99937
KeyScan_InitKeyStateBitmap__F99919:
	push	0                                 ; F99919  push 0x00
	extpfx3 0x8E, 0xFC, 0x04               ; F9991B  push (XIZ+0xfc)   [llvm-mc cannot encode this]
	pushw	1                                ; F9991E  push 0x0001
	call	0xFCA0BA                          ; F99921  call 0xfca0ba
	cpl	a                                  ; F99925  cpl A
	ld	h, a                                ; F99927  ld H,A
	ld	bc, (xiz-3)                         ; F99929  ld BC,(XIZ+0xfd)
	extz	bc                                ; F9992C  extz BC
	extz	xbc                               ; F9992E  extz XBC
	addda32_24	xbc, (0xFCC81A)             ; F99930  add XBC,(0xfcc81a)
	and	(xbc), a                           ; F99935  and (XBC),A
KeyScan_InitKeyStateBitmap__F99937:
	jr KeyScan_InitKeyStateBitmap__F998C1                           ; F99937  jr T,0xf998c1
KeyScan_InitKeyStateBitmap__F99939:
	popw	hl                                ; F99939  pop HL
	unlk32 xiz                             ; F9993A  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F9993C  ret

; --------------------------------------------------------------------------
; Link_ChannelHandler_Ignore -- the do-nothing handler for link channels 4-7.
;
; ⚠ RETRACTION, SAME SESSION.  The first version of this header said "a lone 0x0E
; `ret` ... Nothing in prom_c references it (notes/prom_c_xrefs.py 0xF9993D: no
; literal, no calr)".  That claim was written WITHOUT RUNNING THE TOOL.  Running
; it gives FOUR references:
;
;   $ python3 notes/prom_c_xrefs.py 0xF9993D --no-window
;     ABS32 at 0xFCC54F / 0xFCC553 / 0xFCC557 / 0xFCC55B
;     TOTAL literal-addressed sites: 4
;
; They are entries 4, 5, 6 and 7 of Handler_PtrTable_FCC53F, whose own header
; further down THIS FILE already said so -- "the remaining four are all the SAME
; address, 0xF9993D, whose first byte is 0x0E = RET".  The byte gate passed either
; way; nothing but reading catches this.
;
; Called from: INTTC3_HANDLER__state1_generic (0xF99D6F) via the RAM copy of
;          Handler_PtrTable_FCC53F at 0x00F334, indexed by
;          (link command byte >> 5).  Channels 4-7 all land here.
; Inputs / Outputs: none.  It returns immediately, so a packet on channels 4-7 is
;          received and discarded.
; --------------------------------------------------------------------------
Link_ChannelHandler_Ignore:
	ret                                    ; F9993D  ret

; --------------------------------------------------------------------------
; Link_Init -- program timer 2 and BOTH micro-DMA channels of the CPU-1 link.
;
; Called from: 0xF98B8D (`call 0xF9993E`), MAIN's power-on init chain.  One site.
; Inputs:  none.  Outputs: TRUN, T23MOD, TREG2, INTET32, INTETC23, INTE0AD, the
;          three bytes 0x008535-0x008537, and micro-DMA channels 2 and 3.
; Evidence: ★ THIS IS THE ROUTINE notes/FINDINGS-prom_c-link-receive.md POINTS AT.
;          That note says "The channel's other half is programmed once, at
;          0xF99966-0xF99977: DMAS3 := 0x00100000, DMAM3 := 0x00" -- those two
;          instructions are the `push 0x0000 / push XIX / call 0xF9A012` at
;          0xF99970-0xF99974, because uDMA3_SetSource (converted below) writes
;          (XSP+4) to DMAS3 and (XSP+8) to DMAM3.  The channel-2 half is the pair
;          before it: `push 0x0008 / push XIX / call 0xF99FF8` = uDMA2_SetDest,
;          so DMAD2 := 0x00100000 and DMAM2 := 0x08.  Mode 0x08 is "byte
;          transfer, SOURCE incremented" and mode 0x00 is "byte transfer,
;          DESTINATION incremented" (tmp95c061.cpp:366-371 and :398-401), which is
;          exactly right for a walking buffer writing a fixed port and a fixed
;          port filling a walking buffer.
;          ★ TIMER 2 IS SET UP HERE AND STARTED BY THE SENDERS.  `res 2,(TRUN)`
;          stops it, T23MOD := 0x0E and TREG2 := 5 program it, and every sender
;          below finishes with `set 2,(TRUN)`.  Nothing else in the converted
;          code writes TREG2.
;          INTET32 := 0x00 disables the INTT2/INTT3 levels while this runs;
;          INTETC23 := 0x55 sets the INTTC2/INTTC3 levels; INTE0AD := 0x01 the
;          INT0 level -- names from include/tmp95c061_sfr.inc.
; Unknown:  the three bytes 0x008535-0x008537 zeroed at 0xF9994B-0xF9995D; the
;          exact level fields inside 0x55 and 0x01 (the register layout is not
;          decoded anywhere in this tree).
; --------------------------------------------------------------------------
Link_Init:
	push	xix                               ; F9993E  push XIX
	ldio	INTET32, 0                        ; F9993F  ld (0x74),0x00
	res_dd8	2, TRUN                        ; F99942  res 2,(0x20)
	ldio	T23MOD, 14                        ; F99945  ld (0x28),0x0e
	ldio	INTETC23, 85                      ; F99948  ld (0x7a),0x55
	stib_da	(0x8537), 0                    ; F9994B  ld (0x008537),0x00
	stib_da	(0x8535), 0                    ; F99951  ld (0x008535),0x00
	stib_da	(0x8536), 0                    ; F99957  ld (0x008536),0x00
	ldio	INTE0AD, 1                        ; F9995D  ld (0x70),0x01
	ldio	TREG2, 5                          ; F99960  ld (0x26),0x05
	pushw	8                                ; F99963  push 0x0008
	ld	xix, 0x100000                       ; F99966  ld XIX,0x00100000
	push	xix                               ; F9996B  push XIX
	call	0xF99FF8                          ; F9996C  call 0xf99ff8
	pushw	0                                ; F99970  push 0x0000
	push	xix                               ; F99973  push XIX
	call	0xF9A012                          ; F99974  call 0xf9a012
	inc	8, xsp                             ; F99978  inc 0,XSP
	inc	4, xsp                             ; F9997A  inc 4,XSP
	pop	xix                                ; F9997C  pop XIX
	ret                                    ; F9997D  ret

; --------------------------------------------------------------------------
; Link_SendBlock -- send a buffer of arbitrary length as 32-byte packets.
;
; Called from: 0xF98B30, 0xF98C00, 0xF98D48, 0xF98D8F -- four `call 0xF9997E`
;          sites (notes/prom_c_xrefs.py 0xF9997E).  Two of them are inside MAIN
;          and are already named in the MAIN listing above as the MIDI drain path.
; Inputs:  (XIZ+0x08) u16 channel number, (XIZ+0x0a) u16 length,
;          (XIZ+0x0c) ptr buffer.
; Outputs: one call to Link_SendChunk per packet.
; Evidence: the loop is `cp HL,0x0020 / jr UGT` with HL = the remaining length:
;          while more than 32 bytes remain it sends exactly 0x20 and advances the
;          pointer by 0x20, and it always finishes with ONE more call carrying
;          the remainder in C (`ld C,L`).  So a length that is an exact multiple
;          of 32 still ends with a zero-length call -- read off the code, not
;          smoothed over.  32 is the largest length the header byte can express:
;          notes/FINDINGS-memory-map.md gives the header as
;          `(channel << 5) | (len - 1)`, and len-1 has five bits.
; Unknown:  which channel numbers the four callers use.
; --------------------------------------------------------------------------
Link_SendBlock:
	link32 0xEE, 0x0C, 0x00, 0x00          ; F9997E  link XIZ,0x0000   [llvm-mc cannot encode this]
	pushw	hl                               ; F99982  push HL
	push	xix                               ; F99983  push XIX
	ld	xix, (xiz+12)                       ; F99984  ld XIX,(XIZ+0x0c)
	ld	hl, (xiz+10)                        ; F99987  ld HL,(XIZ+0x0a)
	jr Link_SendBlock__F999A5                           ; F9998A  jr T,0xf999a5
Link_SendBlock__F9998C:
	push	xix                               ; F9998C  push XIX
	pushw	32                               ; F9998D  push 0x0020
	push	0                                 ; F99990  push 0x00
	extpfx3 0x8E, 0x08, 0x04               ; F99992  push (XIZ+0x08)   [llvm-mc cannot encode this]
	calr (0xF999BE - 0xF99998)             ; F99995  calr 0xf999be
	add	xix, 32                            ; F99998  add XIX,0x00000020
	ldw	bc, 32                             ; F9999E  ld BC,0x0020
	sub	hl, bc                             ; F999A1  sub HL,BC
	inc	8, xsp                             ; F999A3  inc 0,XSP
Link_SendBlock__F999A5:
	cp	hl, 32                              ; F999A5  cp HL,0x0020
	jr ugt, Link_SendBlock__F9998C                      ; F999A9  jr UGT,0xf9998c
	push	xix                               ; F999AB  push XIX
	ld	c, l                                ; F999AC  ld C,L
	pushw	bc                               ; F999AE  push BC
	push	0                                 ; F999AF  push 0x00
	extpfx3 0x8E, 0x08, 0x04               ; F999B1  push (XIZ+0x08)   [llvm-mc cannot encode this]
	calr (0xF999BE - 0xF999B7)             ; F999B4  calr 0xf999be
	inc	8, xsp                             ; F999B7  inc 0,XSP
	pop	xix                                ; F999B9  pop XIX
	popw	hl                                ; F999BA  pop HL
	unlk32 xiz                             ; F999BB  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F999BD  ret

; --------------------------------------------------------------------------
; Link_SendChunk -- send ONE packet: header byte by hand, payload by micro-DMA.
;
; Called from: Link_SendBlock, two calr sites (the instructions at 0xF99995 and
;          0xF999B4).
; Inputs:  (XIZ+0x08) u16 channel, (XIZ+0x0a) u16 length, (XIZ+0x0c) ptr payload.
; Outputs: the header byte at 0x00100000, then `length` payload bytes moved by
;          micro-DMA channel 2; (0x00F32C) := 1 for the duration.
; Evidence: ★ THE HEADER BYTE IS BUILT HERE AND IT IS THE ONE THE MEMORY MAP
;          ALREADY RECORDS.  `ld L,H / dec 1,L / ld C,(XIZ+0x08) / sll 0x05,C /
;          or C,L` is (channel << 5) | (len - 1), which is
;          notes/FINDINGS-memory-map.md §3's format, now read off the SENDER
;          rather than inferred.  A length of 0 is rejected up front
;          (`cp H,0 / jrl Z,exit`), which is why `len - 1` never underflows.
;          The handshake is the one §3 tabulates: wait for PA bit 3, drop PA
;          bit 0, write the byte, wait for PA bit 3 again, raise PA bit 0.  Both
;          waits are bounded by 0x4E20 = 20000 spins and both time out by raising
;          PA bit 0 and returning.
;          The payload goes out through uDMA2_SetSource(payload, length) followed
;          by `ldio DMA2V,0x12` and `set 2,(TRUN)`: 0x12 << 2 = 0x48 = INTT2
;          (tmp95c061.cpp:353), so timer 2 clocks the bytes.  The routine then
;          spins on (0x00F32C) until the completion path clears it.
; Unknown:  ⚠ the busy flag 0x00F32C is written with 0, 1 and 2 across the image
;          (16 literal-addressed sites, notes/prom_c_xrefs.py 0x00F32C); 1 and 2
;          are set by different senders and both are compared against by
;          INTTC2_HANDLER at 0xF99D01/0xF99D11.  What distinguishes them is not
;          established here.
; --------------------------------------------------------------------------
Link_SendChunk:
	link32 0xEE, 0x0C, 0xFE, 0xFF          ; F999BE  link XIZ,0xfffe   [llvm-mc cannot encode this]
	pushw	hl                               ; F999C2  push HL
	pushw	de                               ; F999C3  push DE
	pushw	ix                               ; F999C4  push IX
	ld	h, (xiz+10)                         ; F999C5  ld H,(XIZ+0x0a)
	cps	h, 0                               ; F999C8  cp H,0
	jrl z, Link_SendChunk__F99A3A                       ; F999CA  jrl Z,0xf99a3a
	ldw	de, 0                              ; F999CD  ld DE,0x0000
Link_SendChunk__F999D0:
	bit_dd8	3, PA                          ; F999D0  bit 3,(0x1e)
	jr nz, Link_SendChunk__F999E1                       ; F999D3  jr NZ,0xf999e1
	ld	ix, de                              ; F999D5  ld IX,DE
	inc	1, de                              ; F999D7  inc 1,DE
	cp	ix, 0x4E20                          ; F999D9  cp IX,0x4e20
	jr ule, Link_SendChunk__F999D0                      ; F999DD  jr ULE,0xf999d0
	jr Link_SendChunk__F99A3A                           ; F999DF  jr T,0xf99a3a
Link_SendChunk__F999E1:
	res_dd8	0, PA                          ; F999E1  res 0,(0x1e)
	stib_da	(0xF32C), 1                    ; F999E4  ld (0x00f32c),0x01
	ld	l, h                                ; F999EA  ld L,H
	dec	1, l                               ; F999EC  dec 1,L
	ld	c, (xiz+8)                          ; F999EE  ld C,(XIZ+0x08)
	sll	c, 5                               ; F999F1  sll 0x05,C
	or	c, l                                ; F999F4  or C,L
	ld	(xiz-2), c                          ; F999F6  ld (XIZ+0xfe),C
	ld	xbc, 0x100000                       ; F999F9  ld XBC,0x00100000
	ld	a, (xiz-2)                          ; F999FE  ld A,(XIZ+0xfe)
	ld	(xbc), a                            ; F99A01  ld (XBC),A
	ldw	de, 0                              ; F99A03  ld DE,0x0000
Link_SendChunk__F99A06:
	bit_dd8	3, PA                          ; F99A06  bit 3,(0x1e)
	jr z, Link_SendChunk__F99A1A                        ; F99A09  jr Z,0xf99a1a
	ld	ix, de                              ; F99A0B  ld IX,DE
	inc	1, de                              ; F99A0D  inc 1,DE
	cp	ix, 0x4E20                          ; F99A0F  cp IX,0x4e20
	jr ule, Link_SendChunk__F99A06                      ; F99A13  jr ULE,0xf99a06
	set_dd8	0, PA                          ; F99A15  set 0,(0x1e)
	jr Link_SendChunk__F99A3A                           ; F99A18  jr T,0xf99a3a
Link_SendChunk__F99A1A:
	set_dd8	0, PA                          ; F99A1A  set 0,(0x1e)
	ld	c, h                                ; F99A1D  ld C,H
	extz	bc                                ; F99A1F  extz BC
	pushw	bc                               ; F99A21  push BC
	ld	xbc, (xiz+12)                       ; F99A22  ld XBC,(XIZ+0x0c)
	push	xbc                               ; F99A25  push XBC
	call	0xF9A005                          ; F99A26  call 0xf9a005
	ldio	DMA2V, 18                         ; F99A2A  ld (0x7e),0x12
	set_dd8	2, TRUN                        ; F99A2D  set 2,(0x20)
	inc	6, xsp                             ; F99A30  inc 6,XSP
Link_SendChunk__F99A32:
	cpib_da 0x00F32C, 0x00                 ; F99A32  cp (0x00f32c),0x00   [llvm-mc cannot encode this]
	jr nz, Link_SendChunk__F99A32                       ; F99A38  jr NZ,0xf99a32
Link_SendChunk__F99A3A:
	popw	ix                                ; F99A3A  pop IX
	popw	de                                ; F99A3B  pop DE
	popw	hl                                ; F99A3C  pop HL
	unlk32 xiz                             ; F99A3D  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F99A3F  ret

; --------------------------------------------------------------------------
; Link_SendCmdE2_MemRead -- command 0xE2 plus a 10-byte parameter packet.
;
; Called from: NOT FOUND.  notes/prom_c_xrefs.py 0xF99A40 reports no literal and
;          no calr reaching it; short PC-relative forms are not searched.
; Inputs:  (XIZ+0x08) u32, (XIZ+0x0c) u16, (XIZ+0x0e) u32.
; Outputs: the byte 0xE2 at 0x00100000, then the 10-byte packet built at
;          0x008538 -- +0x00 = arg(XIZ+0x08), +0x04 = arg(XIZ+0x0e),
;          +0x08 = arg(XIZ+0x0c) -- moved by micro-DMA channel 2.  Bit 7 of
;          (0x00852B) is set, which is the flag Link_WaitBlockDone polls.
; Evidence: ★ THIS IS prom_a's 0xF8E0FE, COMPILED FOR THE OTHER CPU -- and the
;          claim is measured, not eyeballed:
;
;            $ python3 notes/prom_c_prom_a_routine_diff.py 0xF99A40 0xF8E0FE 0x83
;              instruction slots compared: 47
;              identical text:        29
;              same mnemonic, different operand: 18
;              DIFFERENT MNEMONIC:    0
;
;          All eighteen differences are substituted addresses: buffer 0x008538 vs
;          0x600793, port 0x00100000 vs 0x007C0000, handshake PA vs P7, busy flag
;          0x00F32C vs 0x6007D9, outstanding flag 0x00852B vs 0x00008A, the DMA
;          setter, and the branch targets.  ⚠ They are therefore NOT byte-
;          identical, and the honest byte figure is NOT the leading run:
;
;            $ python3 notes/prom_c_prom_a_shared_runs.py --window 0xF99A40 0xF8E0FE 0x83
;              equal runs (offset,len): (0,8) (11,18) (32,5) (38,2) (43,5) (49,8)
;                                       (58,14) (73,4) (78,23) (104,7) (113,5) (121,10)
;              leading run: 8      LONGEST equal run: 23 of 131
;              total equal bytes: 109 of 131  (83%)
;
;          ★ A ROUND-1 DRAFT OF THIS HEADER SAID "an identical run of only EIGHT
;          bytes".  Eight is the LEADING run; the longest is 23 and 83% of the
;          window is equal.  Elsewhere in this file "identical run" means the
;          MAXIMAL run, so that sentence understated byte similarity about
;          threefold.  The conclusion is unchanged -- 83% equal bytes still cannot
;          tell you the two routines have the same 47-instruction structure, which
;          is why the header cites the instruction-level diff -- but the number was
;          wrong and is corrected here.  Both figures are now asserted by that
;          script's --selftest.
;          The three packet stores are in the IDENTICAL group, so the field
;          layout is literally the same code -- and notes/FINDINGS-memory-map.md
;          §3 already pins what those fields mean, from TWO CPU-1 callers:
;          +0x00 the address to read on the other processor, +0x04 the local
;          destination, +0x08 the length.
;          ⚠ Those meanings are CARRIED FROM prom_a.  prom_c has no caller of
;          this routine, so nothing in this image confirms the direction.
; Unknown:  what sends this; what else reads bit 7 of 0x00852B.
; --------------------------------------------------------------------------
Link_SendCmdE2_MemRead:
	link32 0xEE, 0x0C, 0x00, 0x00          ; F99A40  link XIZ,0x0000   [llvm-mc cannot encode this]
	pushw	hl                               ; F99A44  push HL
	pushw	de                               ; F99A45  push DE
	push	xix                               ; F99A46  push XIX
	lda_24	xix, (0x8538)                   ; F99A47  lda XIX,0x008538
	ldw	hl, 0                              ; F99A4C  ld HL,0x0000
	jr Link_SendCmdE2_MemRead__F99A5C                           ; F99A4F  jr T,0xf99a5c
Link_SendCmdE2_MemRead__F99A51:
	ld	de, hl                              ; F99A51  ld DE,HL
	inc	1, hl                              ; F99A53  inc 1,HL
	cp	de, 0x4E20                          ; F99A55  cp DE,0x4e20
	jrl ugt, Link_SendCmdE2_MemRead__F99ABD                     ; F99A59  jrl UGT,0xf99abd
Link_SendCmdE2_MemRead__F99A5C:
	cpib_da 0x00F32C, 0x00                 ; F99A5C  cp (0x00f32c),0x00   [llvm-mc cannot encode this]
	jr nz, Link_SendCmdE2_MemRead__F99A51                       ; F99A62  jr NZ,0xf99a51
	res_dd8	0, PA                          ; F99A64  res 0,(0x1e)
	stib_da	(0xF32C), 1                    ; F99A67  ld (0x00f32c),0x01
	ld	xbc, 0x100000                       ; F99A6D  ld XBC,0x00100000
	ld	(xbc), 0xE2                         ; F99A72  ld (XBC),0xe2
	ldw	hl, 0                              ; F99A75  ld HL,0x0000
Link_SendCmdE2_MemRead__F99A78:
	bit_dd8	3, PA                          ; F99A78  bit 3,(0x1e)
	jr z, Link_SendCmdE2_MemRead__F99A8C                        ; F99A7B  jr Z,0xf99a8c
	ld	de, hl                              ; F99A7D  ld DE,HL
	inc	1, hl                              ; F99A7F  inc 1,HL
	cp	de, 0x4E20                          ; F99A81  cp DE,0x4e20
	jr ule, Link_SendCmdE2_MemRead__F99A78                      ; F99A85  jr ULE,0xf99a78
	set_dd8	0, PA                          ; F99A87  set 0,(0x1e)
	jr Link_SendCmdE2_MemRead__F99ABD                           ; F99A8A  jr T,0xf99abd
Link_SendCmdE2_MemRead__F99A8C:
	set_dd8	0, PA                          ; F99A8C  set 0,(0x1e)
	ld	xbc, (xiz+8)                        ; F99A8F  ld XBC,(XIZ+0x08)
	ld	(xix), xbc                          ; F99A92  ld (XIX),XBC
	ld	xbc, (xiz+14)                       ; F99A94  ld XBC,(XIZ+0x0e)
	ld	(xix+4), xbc                        ; F99A97  ld (XIX+0x04),XBC
	ld	bc, (xiz+12)                        ; F99A9A  ld BC,(XIZ+0x0c)
	ld	(xix+8), bc                         ; F99A9D  ld (XIX+0x08),BC
	pushw	10                               ; F99AA0  push 0x000a
	push	xix                               ; F99AA3  push XIX
	call	0xF9A005                          ; F99AA4  call 0xf9a005
	ldio	DMA2V, 18                         ; F99AA8  ld (0x7e),0x12
	set_dd8	2, TRUN                        ; F99AAB  set 2,(0x20)
	setda_24 7, 0x00852B                   ; F99AAE  set 7,(0x00852b)   [llvm-mc cannot encode this]
	inc	6, xsp                             ; F99AB3  inc 6,XSP
Link_SendCmdE2_MemRead__F99AB5:
	cpib_da 0x00F32C, 0x00                 ; F99AB5  cp (0x00f32c),0x00   [llvm-mc cannot encode this]
	jr nz, Link_SendCmdE2_MemRead__F99AB5                       ; F99ABB  jr NZ,0xf99ab5
Link_SendCmdE2_MemRead__F99ABD:
	pop	xix                                ; F99ABD  pop XIX
	popw	de                                ; F99ABE  pop DE
	popw	hl                                ; F99ABF  pop HL
	unlk32 xiz                             ; F99AC0  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F99AC2  ret

; --------------------------------------------------------------------------
; Link_SendCmdByte -- send one bare command byte 0xE0 | n, with no payload.
;
; Called from: 0xF99EFD (`calr 0xF99AC3`), inside Link_ServiceTask -- the last
;          instruction of the arm guarded by bit 6 of the flag byte 852C (see
;          that routine).  ONE site
;          (`notes/prom_c_xrefs.py 0xF99AC3 --no-window`: CALR 1, literal 0).
;          ⚠ "the unconverted stretch that follows INTT2_HANDLER" was a round-1
;          draft; 0xF99EFD is converted, in this file.  Corrected.
; Inputs:  (XIZ+0x08) -- only the low nibble survives `or H,0xE0`.
; Outputs: one byte at 0x00100000; (0x00F32C) raised to 1 and lowered to 0 by
;          this routine itself.
; Evidence: `ld H,(XIZ+0x08) / or H,0xE0 / ld XBC,0x00100000 / ld (XBC),H` is the
;          "bare command 0xE0 | n" form notes/FINDINGS-memory-map.md §3 names,
;          and 0xF99AEC is the exact instruction that note already cites for it.
;          ★ IT IS NOT THE SAME ROUTINE AS CPU 1's.  prom_a 0xF8E181 is the
;          nearest match and the diff is not clean:
;            $ python3 notes/prom_c_prom_a_routine_diff.py 0xF99AC3 0xF8E181 0x4A
;              identical text: 7   same mnemonic, different operand: 10
;              DIFFERENT MNEMONIC: 9
;          The nine are one block: where CPU 1 waits on its busy PIN after
;          writing the byte, CPU 2 runs a fixed countdown of 0x3E8 = 1000 and then
;          clears the busy flag itself.  So this variant NEVER waits for the far
;          end and never leaves the flag set.  Also, CPU 1 takes the command in
;          (XIZ+0x0c) and CPU 2 in (XIZ+0x08).
;          ★ THE ONE CALLER SENDS COMMAND 0xE6, and this is arithmetic, not a
;          guess.  `link XIZ,0x0000` leaves XIZ on the saved XIZ, so XIZ+0 = saved
;          XIZ (4), XIZ+4 = the return address (4), and XIZ+0x08 = the LAST thing
;          pushed -- confirmed independently by Link_SendCmdE1, whose three
;          arguments at +0x08/+0x0c/+0x0e line up byte for byte with its caller's
;          `push XBC / push BC / push XBC`.  The last push before 0xF99EFD is
;          `push 0x0006` at 0xF99EFA (16-bit, little-endian, so the byte at
;          XIZ+0x08 is 0x06), `ld H,(XIZ+0x08)` reads it, and `or H,0xe0` makes
;          0xE6.  The following `inc 6,XSP` pops that 2-byte argument together
;          with the 4-byte XBC left by the `call 0xFC88F9` above it.
; Unknown:  what 0xE6 means to CPU 1; why the acknowledgement is replaced by a
;          delay here and not there.
; --------------------------------------------------------------------------
Link_SendCmdByte:
	link32 0xEE, 0x0C, 0x00, 0x00          ; F99AC3  link XIZ,0x0000   [llvm-mc cannot encode this]
	pushw	hl                               ; F99AC7  push HL
	pushw	de                               ; F99AC8  push DE
	ldw	hl, 0                              ; F99AC9  ld HL,0x0000
	jr Link_SendCmdByte__F99AD8                           ; F99ACC  jr T,0xf99ad8
Link_SendCmdByte__F99ACE:
	ld	de, hl                              ; F99ACE  ld DE,HL
	inc	1, hl                              ; F99AD0  inc 1,HL
	cp	de, 0x4E20                          ; F99AD2  cp DE,0x4e20
	jr ugt, Link_SendCmdByte__F99B08                      ; F99AD6  jr UGT,0xf99b08
Link_SendCmdByte__F99AD8:
	cpib_da 0x00F32C, 0x00                 ; F99AD8  cp (0x00f32c),0x00   [llvm-mc cannot encode this]
	jr nz, Link_SendCmdByte__F99ACE                       ; F99ADE  jr NZ,0xf99ace
	res_dd8	0, PA                          ; F99AE0  res 0,(0x1e)
	stib_da	(0xF32C), 1                    ; F99AE3  ld (0x00f32c),0x01
	ld	h, (xiz+8)                          ; F99AE9  ld H,(XIZ+0x08)
	or	h, 0xE0                             ; F99AEC  or H,0xe0
	ld	xbc, 0x100000                       ; F99AEF  ld XBC,0x00100000
	ld	(xbc), h                            ; F99AF4  ld (XBC),H
	ldw	hl, 0x3E8                          ; F99AF6  ld HL,0x03e8
Link_SendCmdByte__F99AF9:
	dec	1, hl                              ; F99AF9  dec 1,HL
	cps	hl, 0                              ; F99AFB  cp HL,0
	jr nz, Link_SendCmdByte__F99AF9                       ; F99AFD  jr NZ,0xf99af9
	set_dd8	0, PA                          ; F99AFF  set 0,(0x1e)
	stib_da	(0xF32C), 0                    ; F99B02  ld (0x00f32c),0x00
Link_SendCmdByte__F99B08:
	popw	de                                ; F99B08  pop DE
	popw	hl                                ; F99B09  pop HL
	unlk32 xiz                             ; F99B0A  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F99B0C  ret

; --------------------------------------------------------------------------
; Link_SendCmdE1 -- command 0xE1, a 6-byte parameter packet, then the caller's
;             own buffer as a second micro-DMA transfer.
;
; Called from: 0xF99E87 (`calr 0xF99B0D`), inside Link_ServiceTask -- the arm
;          guarded by bit 7 of the flag byte 852A (see that routine).  ONE site
;          (`notes/prom_c_xrefs.py 0xF99B0D --no-window`: CALR 1, literal 0).
;          ⚠ A round-1 draft of this line said "in the unconverted stretch after
;          INTT2_HANDLER".  0xF99E87 is converted, in this file, at the label
;          Link_ServiceTask__F99E8E's predecessor -- and the Evidence block below
;          already reasoned from that very caller.  Corrected.
; Inputs:  (XIZ+0x08) u32, (XIZ+0x0c) u16, (XIZ+0x0e) u32.
; Outputs: the byte 0xE1 at 0x00100000; then SIX bytes from 0x008542, laid out
;          +0x00 = arg(XIZ+0x0e) u32 and +0x04 = arg(XIZ+0x0c) u16; then, once
;          the busy flag has fallen to 1, a SECOND transfer of arg(XIZ+0x0c)
;          bytes taken from arg(XIZ+0x08).  (0x00F32C) is set to 2 here, not 1.
; Evidence: ★ prom_a 0xF8E26F IS THE SAME ROUTINE, measured not eyeballed:
;
;            $ python3 notes/prom_c_prom_a_routine_diff.py 0xF99B0D 0xF8E26F 0xAB
;              instruction slots compared: 58
;              identical text: 34
;              same mnemonic, different operand: 24
;              DIFFERENT MNEMONIC:    0
;
;          -- 58 instructions, no structural difference, 24 substituted operands
;          (the port, the pins, the flags, the buffers and the branch targets).
;          The two-stage shape is readable in prom_c alone: uDMA2_SetSource is
;          called first with (0x008542, 6), then `cp (0x00F32C),0x01 / jr NZ`
;          spins until the state machine has moved the flag from 2 down to 1, a
;          0xC8 = 200-pass countdown follows, and then uDMA2_SetSource is called
;          again with ((XIX), (XIX+4)) where XIX = 0x00851A.
;          ★ SO THE SECOND TRANSFER IS THE PAYLOAD AND THE FIRST IS ITS HEADER:
;          the 6-byte packet carries a 32-bit address and a 16-bit length, and
;          the payload that follows is that many bytes from arg(XIZ+0x08).
;          ⚠ THE LENGTH IS STORED TWICE and the two ADDRESSES ARE DIFFERENT ONES.
;          arg(XIZ+0x08) goes to (0x00851A) and arg(XIZ+0x0e) to (0x008542) --
;          two distinct 32-bit slots -- while arg(XIZ+0x0c) is written to BOTH
;          (0x00851E) and (0x008546).  0x008542 is 0x00851A + 0x28, so these are
;          two separate buffers and not one object seen twice.
;          ★ AND THE CALLER SETTLES WHICH IS WHICH, WITHOUT prom_a.  Link_ServiceTask
;          (0xF99E5F, converted below) is the only caller, and it passes the three
;          words of the 0xE2 request packet that micro-DMA channel 3 just deposited
;          at 0x008520: `Link_SendCmdE1((0x008520), (0x008528), (0x008524))`.  The
;          0xE2 packet's fields are +0x00 address, +0x04 address, +0x08 length, so
;          arg(XIZ+0x08) = packet+0x00 -- the one THIS routine dereferences as the
;          payload's source -- is an address on THIS processor, and
;          arg(XIZ+0x0e) = packet+0x04, the one that travels in the header, is on
;          the OTHER one.  Command 0xE2 is a remote READ REQUEST and command 0xE1
;          is the WRITE that answers it.
; Unknown:  what 0xE1 means to CPU 1.  (What the caller passes is NOT unknown --
;          the Evidence block above reads it off Link_ServiceTask; the round-1
;          draft of this line contradicted its own header.)
; --------------------------------------------------------------------------
Link_SendCmdE1:
	link32 0xEE, 0x0C, 0x00, 0x00          ; F99B0D  link XIZ,0x0000   [llvm-mc cannot encode this]
	pushw	hl                               ; F99B11  push HL
	pushw	de                               ; F99B12  push DE
	push	xix                               ; F99B13  push XIX
	lda_24	xix, (0x851A)                   ; F99B14  lda XIX,0x00851a
	ldw	hl, 0                              ; F99B19  ld HL,0x0000
	jr Link_SendCmdE1__F99B29                           ; F99B1C  jr T,0xf99b29
Link_SendCmdE1__F99B1E:
	ld	de, hl                              ; F99B1E  ld DE,HL
	inc	1, hl                              ; F99B20  inc 1,HL
	cp	de, 0x4E20                          ; F99B22  cp DE,0x4e20
	jrl ugt, Link_SendCmdE1__F99BB8                     ; F99B26  jrl UGT,0xf99bb8
Link_SendCmdE1__F99B29:
	cpib_da 0x00F32C, 0x00                 ; F99B29  cp (0x00f32c),0x00   [llvm-mc cannot encode this]
	jr nz, Link_SendCmdE1__F99B1E                       ; F99B2F  jr NZ,0xf99b1e
	res_dd8	0, PA                          ; F99B31  res 0,(0x1e)
	stib_da	(0xF32C), 2                    ; F99B34  ld (0x00f32c),0x02
	ld	xbc, 0x100000                       ; F99B3A  ld XBC,0x00100000
	ld	(xbc), 0xE1                         ; F99B3F  ld (XBC),0xe1
	ldw	hl, 0                              ; F99B42  ld HL,0x0000
Link_SendCmdE1__F99B45:
	bit_dd8	3, PA                          ; F99B45  bit 3,(0x1e)
	jr z, Link_SendCmdE1__F99B5A                        ; F99B48  jr Z,0xf99b5a
	ld	de, hl                              ; F99B4A  ld DE,HL
	inc	1, hl                              ; F99B4C  inc 1,HL
	cp	de, 0x4E20                          ; F99B4E  cp DE,0x4e20
	jr ule, Link_SendCmdE1__F99B45                      ; F99B52  jr ULE,0xf99b45
	set_dd8	0, PA                          ; F99B54  set 0,(0x1e)
	jrl Link_SendCmdE1__F99BB8                          ; F99B57  jrl T,0xf99bb8
Link_SendCmdE1__F99B5A:
	set_dd8	0, PA                          ; F99B5A  set 0,(0x1e)
	ld	xbc, (xiz+8)                        ; F99B5D  ld XBC,(XIZ+0x08)
	ld	(xix), xbc                          ; F99B60  ld (XIX),XBC
	ld	xbc, (xiz+14)                       ; F99B62  ld XBC,(XIZ+0x0e)
	stl_da	(0x8542), xbc                   ; F99B65  ld (0x008542),XBC
	ld	bc, (xiz+12)                        ; F99B6A  ld BC,(XIZ+0x0c)
	ld	(xix+4), bc                         ; F99B6D  ld (XIX+0x04),BC
	ld	bc, (xiz+12)                        ; F99B70  ld BC,(XIZ+0x0c)
	stw_da	(0x8546), bc                    ; F99B73  ld (0x008546),BC
	pushw	6                                ; F99B78  push 0x0006
	lda_24	xbc, (0x8542)                   ; F99B7B  lda XBC,0x008542
	push	xbc                               ; F99B80  push XBC
	call	0xF9A005                          ; F99B81  call 0xf9a005
	ldio	DMA2V, 18                         ; F99B85  ld (0x7e),0x12
	set_dd8	2, TRUN                        ; F99B88  set 2,(0x20)
	inc	6, xsp                             ; F99B8B  inc 6,XSP
Link_SendCmdE1__F99B8D:
	cpib_da 0x00F32C, 0x01                 ; F99B8D  cp (0x00f32c),0x01   [llvm-mc cannot encode this]
	jr nz, Link_SendCmdE1__F99B8D                       ; F99B93  jr NZ,0xf99b8d
	ldb	h, 0xC8                            ; F99B95  ld H,0xc8
Link_SendCmdE1__F99B97:
	dec	1, h                               ; F99B97  dec 1,H
	cps	h, 0                               ; F99B99  cp H,0
	jr nz, Link_SendCmdE1__F99B97                       ; F99B9B  jr NZ,0xf99b97
	ld	bc, (xix+4)                         ; F99B9D  ld BC,(XIX+0x04)
	pushw	bc                               ; F99BA0  push BC
	ld	xbc, (xix)                          ; F99BA1  ld XBC,(XIX)
	push	xbc                               ; F99BA3  push XBC
	call	0xF9A005                          ; F99BA4  call 0xf9a005
	ldio	DMA2V, 18                         ; F99BA8  ld (0x7e),0x12
	set_dd8	2, TRUN                        ; F99BAB  set 2,(0x20)
	inc	6, xsp                             ; F99BAE  inc 6,XSP
Link_SendCmdE1__F99BB0:
	cpib_da 0x00F32C, 0x00                 ; F99BB0  cp (0x00f32c),0x00   [llvm-mc cannot encode this]
	jr nz, Link_SendCmdE1__F99BB0                       ; F99BB6  jr NZ,0xf99bb0
Link_SendCmdE1__F99BB8:
	pop	xix                                ; F99BB8  pop XIX
	popw	de                                ; F99BB9  pop DE
	popw	hl                                ; F99BBA  pop HL
	unlk32 xiz                             ; F99BBB  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; F99BBD  ret

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

; ==============================================================================
; 0xF99E5F-0xF99FC0 -- Link_ServiceTask: the deferred half of the link, and the
;                      micro-DMA stall watchdog.  One routine, 354 bytes
; ==============================================================================
;
; `notes/FINDINGS-prom_c-link-receive.md` names this address seven times without
; being able to say what it does -- "the routine at 0xF99E5F" tests and clears
; every flag INT0_HANDLER and INTTC3_HANDLER post, and its own header list ends
; "**0xF99E5F-0xF99FC0 is the consumer** of every flag in §3 and is still
; `.incbin`.  Converting it should name the flags."  This is that conversion.
;
; ★★ IT ANSWERS THE 0xE2 REQUEST WITH AN 0xE1 REPLY, AND THAT PINS THE PACKET
; LAYOUT FROM CPU 2'S OWN CODE.  `INT0_HANDLER__cmd_E2` (converted above) points
; micro-DMA channel 3 at 0x008520 for ten bytes, and `INTTC3_HANDLER__state3_packet`
; sets bit 7 of 0x00852A when they have landed.  The first thing this routine does
; is take that bit down and call
;
;     Link_SendCmdE1( (0x008520) u32, (0x008528) u16, (0x008524) u32 )
;
; -- and Link_SendCmdE1 DEREFERENCES its first argument as the source of the
; payload transfer and puts its third into the 6-byte header packet.  So, entirely
; from prom_c:
;
;     0xE2 packet +0x00  u32  the address to read ON THIS PROCESSOR
;                 +0x04  u32  the destination ON THE OTHER ONE
;                 +0x08  u16  the length
;
; ★ Command 0xE2 is a REMOTE READ REQUEST and command 0xE1 is the WRITE that
; answers it.  `notes/FINDINGS-memory-map.md` §3 states the same three fields from
; CPU 1's two callers of its own 0xE2 sender; this is the independent confirmation
; from the answering side, and it removes the "carried from prom_a" caveat that
; Link_SendCmdE2_MemRead's header still has to carry for the sending direction.
;
; ★ THE THREE REQUEST BITS OF 0x00852C, NOW MATCHED TO THEIR CONSUMERS.
; INTTC3_HANDLER's states 5, 7 and 9 set bits 7, 6 and 5 (0xF99DE3, 0xF99E17,
; 0xF99E49) and this routine is where each is tested and cleared -- the existing
; INTTC3 header already says so, and now says what happens next:
;
;     bit 7  ->  clear 0x008537, 0x008535 and 0x008536, then
;                0xFC89AF((0x00852D)), 0xFC856C(), 0xFC8646((0x00852D))
;     bit 6  ->  0xFC856C(), then poll 0xFC898F((0x008531)) until it stops
;                returning 0xFFFF, then 0xFC88F9((0x008531)), then
;                Link_SendCmdByte(6) -- i.e. the bare command 0xE6 goes back
;     bit 5  ->  walk the index at 0x008536 up to the count at 0x008535, calling
;                0xFC893B(index) for each
;
; ⚠ None of 0xFC856C / 0xFC8646 / 0xFC88F9 / 0xFC893B / 0xFC898F / 0xFC89AF is
; converted, so what the three jobs DO is still unknown.  What is established is
; the handshake: which ISR raises which bit, and which call sequence answers it.
;
; ★ 0x008535/0x008536 ARE A PRODUCER/CONSUMER PAIR.  0x008535 is incremented by
; INTTC3 state 9 and by nothing else; 0x008536 is the index this routine walks and
; is loaded into XIX at entry (`lda XIX,0x008536` -- the only such instruction in
; the image).  The two loops at 0xF99F2D and 0xF99F59 both run `while (XIX) <
; (0x008535)`, so 0x008535 counts what arrived and 0x008536 counts what has been
; handed on.
;
; ★★ THE MICRO-DMA STALL WATCHDOG.  The last third of the routine, 0xF99F6E
; onward, is not part of any flag:
;
;     if PA bit 1 is clear:                      ; a transfer is outstanding
;         n = uDMA3_GetCount()                   ; DMAC3, bytes still to move
;         if n == (0x00F331):  (0x00F32F) += 1   ; no progress this pass
;         else:                (0x00F32F) = 0
;         (0x00F331) = uDMA3_GetCount()          ; remember it
;     else:
;         (0x00F32F) = 0
;     if (0x00F32F) > 10:
;         (0x00F32F) = 0;  DMA3V := 0;  (0x00F32D) := 0;  set PA bit 1;
;         (0x00F32E) += 1
;
; So ten consecutive service passes with the INBOUND byte count unchanged abort the
; transfer: the channel is unhooked from INT0, the transfer state goes idle, the
; handshake line is raised, and a counter is bumped.  This is the receive-side twin
; of Link_WaitBlockDone's 500-tick timeout on the transmit side, and it uses the
; same three actions.
; ⚠ `(0x00F32E)` is incremented here and referenced NOWHERE else in the image
; (`notes/prom_c_xrefs.py 0x00F32E --no-window --classify`: one site).  Written,
; never read by anything that names it.
; ⚠ The threshold is a comparison against 0x000A with `jr ULE`, so the abort needs
; ELEVEN unchanged passes, not ten.  Stated as the instruction reads.
;
; ⚠ EVERY FLAG TEST IS BRACKETED BY `ei 6` AND `di`, AND THAT IS NOT WHAT IT
; LOOKS LIKE.  llvm-mc's `di` assembles to the byte pair `06 00`, which is `EI 0`:
; op_EI writes the immediate into SR bits 6..4
; (mame/src/devices/cpu/tlcs900/900tbl.hxx:2073-2078) and tlcs900_check_irqs scans
; interrupt priorities from `max(1, (SR>>4)&7)` up to 6 (tmp95c061.cpp:536-545), so
; a level of 0 accepts EVERY maskable interrupt and a level of 7 accepts none;
; reset leaves the field at 7 (`m_sr.d = 0xf800`, "iff set to 111",
; tlcs900.cpp:213-220).  So each flag is read with the level RAISED to 6 -- almost
; everything blocked -- and the job that follows runs with the level back at 0.
; The flags are written by ISRs, which is why the read is guarded.
; ★ This is a correction to two headers earlier in this file, which read `di` as a
; disable; both now carry the citation.  The bytes were never in doubt -- only the
; reading -- which is precisely the kind of error the byte gate cannot see.

; --------------------------------------------------------------------------
; ★★ Link_ServiceTask -- the deferred half of the inter-processor link.
;
; Called from: 0xF98C1A (`call 0xF99E5F`), inside MAIN's phase-4 job -- the arm
;          guarded by bit 4 of the scheduler byte 0x007ED1, which INTT1_HANDLER
;          sets once every six ticks.  One site.
; Inputs:  the flag bits 0x00852A.7 and 0x00852C.7/6/5, the parameter blocks at
;          0x008520 (10 bytes), 0x00852D (u32) and 0x008531 (u32), the counter
;          pair 0x008535/0x008536, and micro-DMA channel 3's remaining count.
; Outputs: one 0xE1 reply, three job sequences, and the stall abort -- all four
;          described in the block comment above.  XIX is saved and restored; the
;          routine has NO stack frame (`push XIX` and not `link`).
; Evidence: every claim above is one of
;          * an instruction in this routine, cited by address;
;          * a census over all twelve direct-address spellings
;            (`notes/prom_c_xrefs.py <addr> --no-window --classify`) for
;            0x00852A (3 sites), 0x00852C (10), 0x008535 (5), 0x008536 (2),
;            0x008537 (4), 0x00F32F (5), 0x00F331 (2) and 0x00F32E (1);
;          * a converted routine elsewhere in this file -- INT0_HANDLER__cmd_E2
;            for where the 10-byte packet comes from, INTTC3_HANDLER states 3/5/7/9
;            for who raises each bit, uDMA3_GetCount for what 0xF9A030 returns.
; ★★ WHAT THE THREE JOBS ARE -- SOLVED IN ROUND 4.  The header used to read
;          "Unknown: the six 0xFC8xxx routines the three jobs call".  All six are
;          the FLASH DRIVER, converted below at 0xFC856C-0xFC89C4:
;            0xFC89AF Flash_ReadSectorToBuffer    0xFC8646 Flash_SectorErase
;            0xFC856C Flash_ReadResetMode         0xFC898F Flash_SectorBlankCheck
;            0xFC88F9 Flash_ProgramSectorFromBuffer
;            0xFC893B Flash_ProgramSlice1K
;          so the three jobs read:
;            bit 7 -> copy sector (0x00852D) into the 64 KiB RAM buffer at
;                     0x00010000, then erase that sector
;            bit 6 -> wait for the erase, burn the whole buffer back into sector
;                     (0x008531), then Link_SendCmdByte(6) = command 0xE6 to CPU 1
;            bit 5 -> burn the 1 KiB slices that have arrived, one per index
;          ★ THE INTER-PROCESSOR LINK IS A FLASH DOWNLOAD PATH.  Command 0xE2 is
;          CPU 2 asking CPU 1 to read, 0xE1 is the write that answers, micro-DMA
;          channel 3 lands the payload, and 0xE6 acknowledges a committed sector.
;          ⚠ WHAT THE DOWNLOADED BYTES ARE is still not established.
; Unknown:  what 0x008537 gates (it is set to 1 by the bit-5 job's first loop and
;          tested by its second); and what reads 0x00F32E.
; --------------------------------------------------------------------------
Link_ServiceTask:
	push	xix                               ; F99E5F  push XIX
	lda_24	xix, (0x8536)                   ; F99E60  lda XIX,0x008536
	ei	6                                   ; F99E65  ei 0x06
	extpfx5 0xF2, 0x2A, 0x85, 0x00, 0xCF   ; F99E67  bit 7,(0x00852a)   [llvm-mc cannot encode this]
	jr z, Link_ServiceTask__F99E8E                        ; F99E6C  jr Z,0xf99e8e
	extpfx5 0xF2, 0x2A, 0x85, 0x00, 0xB7   ; F99E6E  res 7,(0x00852a)   [llvm-mc cannot encode this]
	di                                     ; F99E73  ei 0x00
	ldl_da	xbc, (0x8524)                   ; F99E75  ld XBC,(0x008524)
	push	xbc                               ; F99E7A  push XBC
	ldw_da	bc, (0x8528)                    ; F99E7B  ld BC,(0x008528)
	pushw	bc                               ; F99E80  push BC
	ldl_da	xbc, (0x8520)                   ; F99E81  ld XBC,(0x008520)
	push	xbc                               ; F99E86  push XBC
	calr (0xF99B0D - 0xF99E8A)             ; F99E87  calr 0xf99b0d
	inc	8, xsp                             ; F99E8A  inc 0,XSP
	inc	2, xsp                             ; F99E8C  inc 2,XSP
Link_ServiceTask__F99E8E:
	di                                     ; F99E8E  ei 0x00
	ei	6                                   ; F99E90  ei 0x06
	extpfx5 0xF2, 0x2C, 0x85, 0x00, 0xCF   ; F99E92  bit 7,(0x00852c)   [llvm-mc cannot encode this]
	jr z, Link_ServiceTask__F99EC9                        ; F99E97  jr Z,0xf99ec9
	extpfx5 0xF2, 0x2C, 0x85, 0x00, 0xB7   ; F99E99  res 7,(0x00852c)   [llvm-mc cannot encode this]
	di                                     ; F99E9E  ei 0x00
	stib_da	(0x8537), 0                    ; F99EA0  ld (0x008537),0x00
	stib_da	(0x8535), 0                    ; F99EA6  ld (0x008535),0x00
	ld	(xix), 0                            ; F99EAC  ld (XIX),0x00
	ldl_da	xbc, (0x852D)                   ; F99EAF  ld XBC,(0x00852d)
	push	xbc                               ; F99EB4  push XBC
	call	0xFC89AF                          ; F99EB5  call 0xfc89af
	call	0xFC856C                          ; F99EB9  call 0xfc856c
	ldl_da	xbc, (0x852D)                   ; F99EBD  ld XBC,(0x00852d)
	push	xbc                               ; F99EC2  push XBC
	call	0xFC8646                          ; F99EC3  call 0xfc8646
	inc	8, xsp                             ; F99EC7  inc 0,XSP
Link_ServiceTask__F99EC9:
	di                                     ; F99EC9  ei 0x00
	ei	6                                   ; F99ECB  ei 0x06
	extpfx5 0xF2, 0x2C, 0x85, 0x00, 0xCE   ; F99ECD  bit 6,(0x00852c)   [llvm-mc cannot encode this]
	jr z, Link_ServiceTask__F99F02                        ; F99ED2  jr Z,0xf99f02
	extpfx5 0xF2, 0x2C, 0x85, 0x00, 0xB6   ; F99ED4  res 6,(0x00852c)   [llvm-mc cannot encode this]
	di                                     ; F99ED9  ei 0x00
	call	0xFC856C                          ; F99EDB  call 0xfc856c
Link_ServiceTask__F99EDF:
	ldl_da	xbc, (0x8531)                   ; F99EDF  ld XBC,(0x008531)
	push	xbc                               ; F99EE4  push XBC
	call	0xFC898F                          ; F99EE5  call 0xfc898f
	pop	xiy                                ; F99EE9  pop XIY
	cp	wa, 0xFFFF                          ; F99EEA  cp WA,0xffff
	jr z, Link_ServiceTask__F99EDF                        ; F99EEE  jr Z,0xf99edf
	ldl_da	xbc, (0x8531)                   ; F99EF0  ld XBC,(0x008531)
	push	xbc                               ; F99EF5  push XBC
	call	0xFC88F9                          ; F99EF6  call 0xfc88f9
	pushw	6                                ; F99EFA  push 0x0006
	calr (0xF99AC3 - 0xF99F00)             ; F99EFD  calr 0xf99ac3
	inc	6, xsp                             ; F99F00  inc 6,XSP
Link_ServiceTask__F99F02:
	di                                     ; F99F02  ei 0x00
	ei	6                                   ; F99F04  ei 0x06
	extpfx5 0xF2, 0x2C, 0x85, 0x00, 0xCD   ; F99F06  bit 5,(0x00852c)   [llvm-mc cannot encode this]
	jr z, Link_ServiceTask__F99F6C                        ; F99F0B  jr Z,0xf99f6c
	extpfx5 0xF2, 0x2C, 0x85, 0x00, 0xB5   ; F99F0D  res 5,(0x00852c)   [llvm-mc cannot encode this]
	di                                     ; F99F12  ei 0x00
	ld	c, (xix)                            ; F99F14  ld C,(XIX)
	cps	c, 0                               ; F99F16  cp C,0
	jr nz, Link_ServiceTask__F99F4F                       ; F99F18  jr NZ,0xf99f4f
	ldl_da	xbc, (0x8568)                   ; F99F1A  ld XBC,(0x008568)
	push	xbc                               ; F99F1F  push XBC
	call	0xFC898F                          ; F99F20  call 0xfc898f
	pop	xiy                                ; F99F24  pop XIY
	cp	wa, 0xFFFF                          ; F99F25  cp WA,0xffff
	jr z, Link_ServiceTask__F99F48                        ; F99F29  jr Z,0xf99f48
	jr Link_ServiceTask__F99F3D                           ; F99F2B  jr T,0xf99f3d
Link_ServiceTask__F99F2D:
	ld	c, (xix)                            ; F99F2D  ld C,(XIX)
	pushw	bc                               ; F99F2F  push BC
	incm8	1, (xix)                         ; F99F30  inc 1,(XIX)
	call	0xFC893B                          ; F99F32  call 0xfc893b
	stib_da	(0x8537), 1                    ; F99F36  ld (0x008537),0x01
	popw	bc                                ; F99F3C  pop BC
Link_ServiceTask__F99F3D:
	ld	c, (xix)                            ; F99F3D  ld C,(XIX)
	extpfx5 0xC2, 0x35, 0x85, 0x00, 0xF3   ; F99F3F  cp C,(0x008535)   [llvm-mc cannot encode this]
	jr c, Link_ServiceTask__F99F2D                        ; F99F44  jr C,0xf99f2d
	jr Link_ServiceTask__F99F6C                           ; F99F46  jr T,0xf99f6c
Link_ServiceTask__F99F48:
	setda_24 5, 0x00852C                   ; F99F48  set 5,(0x00852c)   [llvm-mc cannot encode this]
	jr Link_ServiceTask__F99F6C                           ; F99F4D  jr T,0xf99f6c
Link_ServiceTask__F99F4F:
	cpib_da 0x008537, 0x01                 ; F99F4F  cp (0x008537),0x01   [llvm-mc cannot encode this]
	jr nz, Link_ServiceTask__F99F6C                       ; F99F55  jr NZ,0xf99f6c
	jr Link_ServiceTask__F99F63                           ; F99F57  jr T,0xf99f63
Link_ServiceTask__F99F59:
	ld	c, (xix)                            ; F99F59  ld C,(XIX)
	pushw	bc                               ; F99F5B  push BC
	incm8	1, (xix)                         ; F99F5C  inc 1,(XIX)
	call	0xFC893B                          ; F99F5E  call 0xfc893b
	popw	bc                                ; F99F62  pop BC
Link_ServiceTask__F99F63:
	ld	c, (xix)                            ; F99F63  ld C,(XIX)
	extpfx5 0xC2, 0x35, 0x85, 0x00, 0xF3   ; F99F65  cp C,(0x008535)   [llvm-mc cannot encode this]
	jr c, Link_ServiceTask__F99F59                        ; F99F6A  jr C,0xf99f59
Link_ServiceTask__F99F6C:
	di                                     ; F99F6C  ei 0x00
	bit_dd8	1, PA                          ; F99F6E  bit 1,(0x1e)
	jr nz, Link_ServiceTask__F99F97                       ; F99F71  jr NZ,0xf99f97
	call	0xF9A030                          ; F99F73  call 0xf9a030
	cpdm16_24	(0xF331), wa                 ; F99F77  cp (0x00f331),WA
	jr nz, Link_ServiceTask__F99F85                       ; F99F7C  jr NZ,0xf99f85
	incdi16_24	1, (0xF32F)                 ; F99F7E  incw 1,(0x00f32f)
	jr Link_ServiceTask__F99F8C                           ; F99F83  jr T,0xf99f8c
Link_ServiceTask__F99F85:
	stiw_da	(0xF32F), 0                    ; F99F85  ld (0x00f32f),0x0000
Link_ServiceTask__F99F8C:
	call	0xF9A030                          ; F99F8C  call 0xf9a030
	stw_da	(0xF331), wa                    ; F99F90  ld (0x00f331),WA
	jr Link_ServiceTask__F99F9E                           ; F99F95  jr T,0xf99f9e
Link_ServiceTask__F99F97:
	stiw_da	(0xF32F), 0                    ; F99F97  ld (0x00f32f),0x0000
Link_ServiceTask__F99F9E:
	extpfx7 0xD2, 0x2F, 0xF3, 0x00, 0x3F, 0x0A, 0x00 ; F99F9E  cp (0x00f32f),0x000a   [llvm-mc cannot encode this]
	jr ule, Link_ServiceTask__F99FBF                      ; F99FA5  jr ULE,0xf99fbf
	stiw_da	(0xF32F), 0                    ; F99FA7  ld (0x00f32f),0x0000
	ldio	DMA3V, 0                          ; F99FAE  ld (0x7f),0x00
	stib_da	(0xF32D), 0                    ; F99FB1  ld (0x00f32d),0x00
	set_dd8	1, PA                          ; F99FB7  set 1,(0x1e)
	incdi8_24	1, (0xF32E)                  ; F99FBA  inc 1,(0x00f32e)
Link_ServiceTask__F99FBF:
	pop	xix                                ; F99FBF  pop XIX
	ret                                    ; F99FC0  ret

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
; Evidence: (the nine routines below are described by the block comments above the
;          `.equ` group; each carries a one-line citation of its own so a grep for
;          "Evidence" does not skip them.)
;          Link_WaitBlockDone: the 500-tick bound is `cp BC,0x01f4 / jr LE` at
;          0xF99FD3 against the INTT1 tick counter 0x00F2F3 sampled at entry, and
;          the three timeout actions are the instructions at 0xF99FD9-0xF99FE5.
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

; Evidence: writes CR_DMAD2 (0x18) then CR_DMAM2 (0x2A); both `.equ`s above are
;          cited to mame/src/devices/cpu/tlcs900/tmp95c061.cpp:1394-1398.
uDMA2_SetDest:
	ld xbc, (xsp+4)                            ; F99FF8  af 04 21
	ldc_cr32 xbc, CR_DMAD2                     ; F99FFB  e9 2e 18
	ld c, (xsp+8)                              ; F99FFE  8f 08 23
	ldc_cr8 c, CR_DMAM2                        ; F9A001  cb 2e 2a
	ret                                        ; F9A004  0e
; Evidence: writes CR_DMAS2 (0x08) then CR_DMAC2 (0x28) -- source address and
;          transfer count of micro-DMA channel 2; `.equ`s cited above.
uDMA2_SetSource:
	ld xbc, (xsp+4)                            ; F9A005  af 04 21
	ldc_cr32 xbc, CR_DMAS2                     ; F9A008  e9 2e 08
	ld bc, (xsp+8)                             ; F9A00B  9f 08 21
	ldc_cr16 bc, CR_DMAC2                      ; F9A00E  d9 2e 28
	ret                                        ; F9A011  0e
; Evidence: writes CR_DMAS3 (0x0C) then CR_DMAM3 (0x2E); `.equ`s cited above.
uDMA3_SetSource:
	ld xbc, (xsp+4)                            ; F9A012  af 04 21
	ldc_cr32 xbc, CR_DMAS3                     ; F9A015  e9 2e 0c
	ld c, (xsp+8)                              ; F9A018  8f 08 23
	ldc_cr8 c, CR_DMAM3                        ; F9A01B  cb 2e 2e
	ret                                        ; F9A01E  0e
; Evidence: writes CR_DMAD3 (0x1C) then CR_DMAC3 (0x2C); `.equ`s cited above.
uDMA3_SetDest:
	ld xbc, (xsp+4)                            ; F9A01F  af 04 21
	ldc_cr32 xbc, CR_DMAD3                     ; F9A022  e9 2e 1c
	ld bc, (xsp+8)                             ; F9A025  9f 08 21
	ldc_cr16 bc, CR_DMAC3                      ; F9A028  d9 2e 2c
	ret                                        ; F9A02B  0e
; Evidence: one `ldc WA,CR_DMAC2` and a `ret`; `.equ` cited above.
uDMA2_GetCount:
	ldc_16_cr wa, CR_DMAC2                     ; F9A02C  d8 2f 28
	ret                                        ; F9A02F  0e
; Evidence: one `ldc WA,CR_DMAC3` and a `ret`; `.equ` cited above.  This is the
;          0xF9A030 that Link_ServiceTask calls to read the remaining count.
uDMA3_GetCount:
	ldc_16_cr wa, CR_DMAC3                     ; F9A030  d8 2f 2c
	ret                                        ; F9A033  0e
; Evidence: one `ldc XIY,CR_DMAD3` and a `ret`; `.equ` cited above.
uDMA3_GetDest:
	ldc_32_cr xiy, CR_DMAD3                    ; F9A034  ed 2f 1c
	ret                                        ; F9A037  0e
; Evidence: see this routine's own header above the `.equ` group -- 66 call sites
;          by byte census, byte-identical to prom_a's, odd-length handling read
;          off the `bit 0,bc / ldi / srl bc,1 / ldirw` sequence below.
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

	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x01A050, 0x012E17

; ==============================================================================
; 0xFACE67-0xFAD141 -- the register writers for the 64-channel parameter device
;                      at 0x0010C000.  17 routines, 731 bytes
; ==============================================================================
;
; ⚠⚠ NAMING RETRACTION, ROUND 4.  Every label in this bank and in the two banks
; below was prefixed `TG_` (and `TG2_` for 0x00104000) from round 2 until round 4,
; and the supporting note was titled "The WSA1's tone generator".  NOTHING IN THIS
; IMAGE ESTABLISHES THAT THE DEVICE MAKES SOUND.  What is established is only the
; shape, and the shape is what the names now say: `Dev10C_...` for 0x0010C000 and
; `Dev104_...` for 0x00104000, matching the neutral convention this file already
; used for `Dev108000_Preload_80toBF` before that device's role was pinned down.
; The tone-generator reading is a reasonable INFERENCE and it is written out in
; full, with what would settle it, in notes/FINDINGS-prom_c-tone-generator.md §0.
; What is missing is an instruction connecting a NOTE to a CHANNEL: CPU 2 scans
; the keybed (0x00108000) and then SENDS the note-on over the inter-processor link
; (Link_Ch0_AppendToRing's block comment), so the one path this image does show
; from a key to anything goes AWAY from this device, not into it.
;
; 0x0010C000 is CPU 2's busiest device: prom_c loads that literal into a pointer
; register 102 times, against 20 for 0x00E00000, 12 for 0x00104000 and 3 for
; 0x00108000.  All 102 are the SAME instruction shape, `ld <X..>,0x0010C000`
; (51 x XIX, 41 x XBC, 10 x XWA), so the census has no false positives to discard
; -- `python3 notes/prom_c_tg_regmap.py --selftest` re-derives the count and
; checks the LAST site, not only the first.
;
; ★ THE PORT IS AN ADDRESS/DATA PAIR, AND ONE ROUTINE PROVES IT WITHOUT
; INTERPRETATION.  Dev10C_WriteReg at 0xFACE89 is 25 bytes long and does nothing but
;
;       ld bc,(xiz+8)   / ld (xix),bc         ; +0x00 <- argument 0
;       ld bc,(xiz+10)  / ld (xix+2),bc       ; +0x02 <- argument 1
;
; -- no arithmetic, no mask, no shift between the argument and the port.  There
; is no reading of that in which +0x00 is anything but a 16-bit register selector
; and +0x02 anything but that register's 16-bit data.  Every other routine here
; is that same pair with the register number computed first.
;
; ★ THE REGISTER NUMBER IS `channel + K`, AND EVERY K IS A MULTIPLE OF 0x40.
; `python3 notes/prom_c_tg_regmap.py` extracts the (K, source field) pair from
; each site mechanically -- it parses unidasm's rendering, bounds the window to
; one routine, and prints the sites it could NOT match rather than dropping them
; (75 of 102 matched; the 27 it rejects are sites whose register number is in a
; register it cannot follow, and they are listed by `--unmatched`).  Over the
; matched set:
;
;   19 distinct K:  0x0040 0x0080 0x00C0 0x0100 0x0140 0x0180 0x01C0
;                   0x0400 0x0440 0x0480 0x04C0 0x0540 0x0580 0x05C0 0x0600 0x0640
;                   0x0800 0x0840 0x0880
;   all divisible by 0x40; as K/0x40:  1 2 3 4 5 6 7  16 17 18 19 21 22 23 24 25  32 33 34
;
; and K = 0 occurs too (0xFACE89 here, 0xFB7331 elsewhere).  So the device's
; register file reads as `parameter_block * 0x40 + channel`, with 0x40 channels
; per block.  ⚠ THAT LAST SENTENCE IS AN OBSERVATION ABOUT THE CONSTANTS, not
; something any instruction says.  What the instructions say is only `chan + K`.
;
; ★ 0x40 IS ALSO A BRANCH POINT IN THE CODE.  Dev10C_SetChanReg_01C0_or_0600 and
; Dev10C_SetChanReg_0540_or_0580 both `cp hl,0x0040` on the channel argument and pick
; a different block AND a different source field on each arm.  Independently, the
; loop at 0xFADCC3 that drives this bank walks a list of channel bytes and stops
; on the first one >= 0x40 (`cp H,0x40 / jr NC,exit`) -- so in that path 0x40 is a
; list TERMINATOR, and the channel numbers that reach the accessors from it are
; 0..63.  Something else reaches the >= 0x40 arms; that caller is not converted.
;
; ★ ALL 23 STRUCT-TAKING CALL SITES PASS THE SAME POINTER, 0x00D75E.  The bank has
; 25 calr sites in total (`--callers` finds them by displacement, and reports that
; no routine here is uncalled); 23 of them set the arguments up as
; `lda XBC,0x00D75E / push XBC / <compute chan> / push WA`, and the two that do
; not are the two routines that take no struct (Dev10C_WriteReg, Dev10C_WriteReg_0201).
; 0x00D75E is work DRAM -- outside the boot RAM image at 0x00E2DF
; (notes/FINDINGS-prom_c-ram-image.md) -- and prom_c takes its address 74 times,
; every one of them the identical instruction `lda XBC,0x00D75E`
; (`python3 notes/prom_c_xrefs.py 0x00D75E --no-window --classify`).  It is a
; single global STAGING STRUCT: the accessors read fields 0x08..0x42 of it and
; push them at the hardware.  The fields observed here are
; 0x08 0x0A 0x0C 0x0E 0x10 0x14 0x1A 0x1C 0x2C 0x2E 0x38 0x3A 0x3C 0x3E 0x40 0x42.
;
; ⚠ NO KN5000 COUNTERPART.  `python3 notes/prom_c_sibling_map.py --addr 0xFACE67
; --len 731` reports the run does not occur in the sibling image at all, so unlike
; the 0x00E00000 writers at the top of this file NOTHING here is a transplanted
; name.  Every name below describes only what its own instructions do.
;
; ⚠ THIS BANK IS DUPLICATED INSIDE prom_c.  13 of the 17 bodies occur a second
; time, byte for byte, between 0xFB7016 and 0xFB7FCE -- and two of the 17
; (0xFACEA2 and 0xFACF78) are byte-identical to EACH OTHER.  Run
; `python3 notes/prom_c_tg_regmap.py --dups` for the address of every copy.  The
; second bank is larger than this one (it adds K = 0x0040, 0x0080, 0x0480, 0x05C0,
; 0x0640) and is NOT converted here.
;
; ★ AND +0x04 IS THE READ PORT.  0xFA68FC does the SAME select through the same
; pointer -- `ld (XIX),BC` -- and then takes the value from XIX+4:
;
;       ld xbc,xix / inc 4,xbc / ld (xiz-14),xbc / ld hl,(xbc)     ; 0xFA6903
;
; 16 bits again.  So the device's shape, entirely from prom_c's own instructions,
; is {+0x00 select, +0x02 write data, +0x04 read data}.  That routine is not
; converted here; it is quoted because it is the only evidence in this image that
; the port can be read at all.
;
; ⚠ WHAT ANY REGISTER MEANS IS NOT ESTABLISHED, and no name below claims one.

; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0400 -- register (chan + 0x0400) = staging->0x0E.
;
; Called from: 0xFADD1A, 0xFADDB8 (notes/prom_c_tg_regmap.py --callers).  Both
;              sites are `lda XBC,0x00D75E / push XBC / <compute chan> / push WA`.
; Inputs:  (XIZ+8) = chan, 16-bit.  (XIZ+10) = pointer to the staging struct.
; Outputs: one 16-bit write to the device at 0x0010C000.
; Evidence: `add hl,0x0400` on the argument, `ld (xix),hl`, then
;          `ld wa,(xbc+14)` / `ld (xix+2),wa`.  Nothing else touches the port.
; Unknown:  what register block 0x0400 controls.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0400:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACE67  ee 0c 00 00
	pushw hl                                   ; FACE6B  2b
	push xix                                   ; FACE6C  3c
	ld hl, (xiz+8)                             ; FACE6D  9e 08 23
	add hl, 0x0400                             ; FACE70  db c8 00 04
	ld xix, 0x0010C000                         ; FACE74  44 00 c0 10 00
	ld (xix), hl                               ; FACE79  b4 53
	ld xbc, (xiz+10)                           ; FACE7B  ae 0a 21
	ld wa, (xbc+14)                            ; FACE7E  99 0e 20
	ld (xix+2), wa                             ; FACE81  bc 02 50
	pop xix                                    ; FACE84  5c
	popw hl                                    ; FACE85  4b
	unlk32 xiz                                 ; FACE86  ee 0d
	ret                                        ; FACE88  0e
; --------------------------------------------------------------------------
; ★ Dev10C_WriteReg -- the RAW two-word primitive, and the routine that fixes the
; port's shape for the whole bank.
;
; Called from: 0xFADF40, its only calr site.
; Inputs:  (XIZ+8) = the 16-bit REGISTER NUMBER, (XIZ+10) = the 16-bit VALUE.
; Outputs: one register of the device at 0x0010C000.
; Evidence: ★ both arguments go to the port UNMODIFIED and in order -- there is
;          no add, no mask and no shift anywhere in the 25 bytes:
;              ld bc,(xiz+8)  / ld (xix),bc
;              ld bc,(xiz+10) / ld (xix+2),bc
;          so +0x00 is a register selector and +0x02 is that register's data, and
;          every other routine below is this one with the number computed.
;          At the single call site the number pushed is the channel (`ld C,(XIX)`
;          / extz / push) and the value comes from (XHL+0x29) where
;          XHL = 0x3BCF + chan*0x44 -- i.e. block 0, and the value comes out of
;          the per-channel record array, not out of the staging struct.
; Unknown:  what block 0 holds.
; --------------------------------------------------------------------------
Dev10C_WriteReg:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACE89  ee 0c 00 00
	push xix                                   ; FACE8D  3c
	ld xix, 0x0010C000                         ; FACE8E  44 00 c0 10 00
	ld bc, (xiz+8)                             ; FACE93  9e 08 21
	ld (xix), bc                               ; FACE96  b4 51
	ld bc, (xiz+10)                            ; FACE98  9e 0a 21
	ld (xix+2), bc                             ; FACE9B  bc 02 51
	pop xix                                    ; FACE9E  5c
	unlk32 xiz                                 ; FACE9F  ee 0d
	ret                                        ; FACEA1  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0840_0880 -- registers (chan+0x0840) = staging->0x1A and
; (chan+0x0880) = staging->0x1C, in that order.
;
; Called from: 0xFADE9B.
; Inputs:  (XIZ+8) = chan, (XIZ+10) = staging struct.
; Outputs: two 16-bit writes.
; Evidence: the two `add`s are `0x0840` and `0x0880`; the sources are the
;          ADJACENT struct words 0x1A and 0x1C.  The four bytes of frame the
;          `link XIZ,0xFFFC` opens hold a copy of the data-port address
;          (`ld xwa,xix / inc 2,xwa / ld (xiz-4),xwa`), which is why the second
;          write goes through XIY rather than (XIX+2).
; ⚠ BYTE-IDENTICAL, all 60 bytes, to Dev10C_SetChanReg_0840_0880_dup at 0xFACF78 --
;          two copies of one function in the same bank.  Reproduce with
;          `python3 notes/prom_c_tg_regmap.py --dups`, whose 0xFACEA2 and
;          0xFACF78 rows report each other's address.
; Unknown:  whether 0x1A/0x1C are the halves of one 32-bit quantity.  They are
;          adjacent and written to adjacent blocks, which is suggestive and is
;          NOT evidence.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0840_0880:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FACEA2  ee 0c fc ff
	pushw hl                                   ; FACEA6  2b
	push xix                                   ; FACEA7  3c
	ld hl, (xiz+8)                             ; FACEA8  9e 08 23
	add hl, 0x0840                             ; FACEAB  db c8 40 08
	ld xix, 0x0010C000                         ; FACEAF  44 00 c0 10 00
	ld (xix), hl                               ; FACEB4  b4 53
	ld xbc, (xiz+10)                           ; FACEB6  ae 0a 21
	ld hl, (xbc+26)                            ; FACEB9  99 1a 23
	ld xwa, xix                                ; FACEBC  ec 88
	inc 2, xwa                                 ; FACEBE  e8 62
	ld (xiz-4), xwa                            ; FACEC0  be fc 60
	ld (xwa), hl                               ; FACEC3  b0 53
	ld bc, (xiz+8)                             ; FACEC5  9e 08 21
	add bc, 0x0880                             ; FACEC8  d9 c8 80 08
	ld (xix), bc                               ; FACECC  b4 51
	ld xbc, (xiz+10)                           ; FACECE  ae 0a 21
	ld wa, (xbc+28)                            ; FACED1  99 1c 20
	ld xiy, (xiz-4)                            ; FACED4  ae fc 25
	ld (xiy), wa                               ; FACED7  b5 50
	pop xix                                    ; FACED9  5c
	popw hl                                    ; FACEDA  4b
	unlk32 xiz                                 ; FACEDB  ee 0d
	ret                                        ; FACEDD  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0840_0800 -- registers (chan+0x0840) = staging->0x2E and
; (chan+0x0800) = staging->0x2C.  Note the DESCENDING block order.
;
; Called from: 0xFADF91.
; Inputs / Outputs: as above.
; Evidence: `add hl,0x0840` then `add bc,0x0800`; sources (xbc+46) and (xbc+44).
; Unknown:  why this one writes the higher block first when
;          Dev10C_SetChanReg_0840_0880 writes the lower first.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0840_0800:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FACEDE  ee 0c fc ff
	pushw hl                                   ; FACEE2  2b
	push xix                                   ; FACEE3  3c
	ld hl, (xiz+8)                             ; FACEE4  9e 08 23
	add hl, 0x0840                             ; FACEE7  db c8 40 08
	ld xix, 0x0010C000                         ; FACEEB  44 00 c0 10 00
	ld (xix), hl                               ; FACEF0  b4 53
	ld xbc, (xiz+10)                           ; FACEF2  ae 0a 21
	ld hl, (xbc+46)                            ; FACEF5  99 2e 23
	ld xwa, xix                                ; FACEF8  ec 88
	inc 2, xwa                                 ; FACEFA  e8 62
	ld (xiz-4), xwa                            ; FACEFC  be fc 60
	ld (xwa), hl                               ; FACEFF  b0 53
	ld bc, (xiz+8)                             ; FACF01  9e 08 21
	add bc, 0x0800                             ; FACF04  d9 c8 00 08
	ld (xix), bc                               ; FACF08  b4 51
	ld xbc, (xiz+10)                           ; FACF0A  ae 0a 21
	ld wa, (xbc+44)                            ; FACF0D  99 2c 20
	ld xiy, (xiz-4)                            ; FACF10  ae fc 25
	ld (xiy), wa                               ; FACF13  b5 50
	pop xix                                    ; FACF15  5c
	popw hl                                    ; FACF16  4b
	unlk32 xiz                                 ; FACF17  ee 0d
	ret                                        ; FACF19  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0840 -- register (chan + 0x0840) = staging->0x2E.
;
; Called from: 0xFADF32.
; Evidence: the single-write half of Dev10C_SetChanReg_0840_0800 above -- same block,
;          same source field.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0840:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACF1A  ee 0c 00 00
	pushw hl                                   ; FACF1E  2b
	push xix                                   ; FACF1F  3c
	ld hl, (xiz+8)                             ; FACF20  9e 08 23
	add hl, 0x0840                             ; FACF23  db c8 40 08
	ld xix, 0x0010C000                         ; FACF27  44 00 c0 10 00
	ld (xix), hl                               ; FACF2C  b4 53
	ld xbc, (xiz+10)                           ; FACF2E  ae 0a 21
	ld wa, (xbc+46)                            ; FACF31  99 2e 20
	ld (xix+2), wa                             ; FACF34  bc 02 50
	pop xix                                    ; FACF37  5c
	popw hl                                    ; FACF38  4b
	unlk32 xiz                                 ; FACF39  ee 0d
	ret                                        ; FACF3B  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0100_0140 -- registers (chan+0x0100) = staging->0x08 and
; (chan+0x0140) = staging->0x0A.
;
; Called from: 0xFAE004.
; Evidence: `add hl,0x0100` / `add bc,0x0140`; sources (xbc+8) and (xbc+10).
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0100_0140:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FACF3C  ee 0c fc ff
	pushw hl                                   ; FACF40  2b
	push xix                                   ; FACF41  3c
	ld hl, (xiz+8)                             ; FACF42  9e 08 23
	add hl, 0x0100                             ; FACF45  db c8 00 01
	ld xix, 0x0010C000                         ; FACF49  44 00 c0 10 00
	ld (xix), hl                               ; FACF4E  b4 53
	ld xbc, (xiz+10)                           ; FACF50  ae 0a 21
	ld hl, (xbc+8)                             ; FACF53  99 08 23
	ld xwa, xix                                ; FACF56  ec 88
	inc 2, xwa                                 ; FACF58  e8 62
	ld (xiz-4), xwa                            ; FACF5A  be fc 60
	ld (xwa), hl                               ; FACF5D  b0 53
	ld bc, (xiz+8)                             ; FACF5F  9e 08 21
	add bc, 0x0140                             ; FACF62  d9 c8 40 01
	ld (xix), bc                               ; FACF66  b4 51
	ld xbc, (xiz+10)                           ; FACF68  ae 0a 21
	ld wa, (xbc+10)                            ; FACF6B  99 0a 20
	ld xiy, (xiz-4)                            ; FACF6E  ae fc 25
	ld (xiy), wa                               ; FACF71  b5 50
	pop xix                                    ; FACF73  5c
	popw hl                                    ; FACF74  4b
	unlk32 xiz                                 ; FACF75  ee 0d
	ret                                        ; FACF77  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0840_0880_dup -- ⚠ 60 bytes BYTE-IDENTICAL to
; Dev10C_SetChanReg_0840_0880 at 0xFACEA2.  It is a second copy of the same function,
; not a variant: `notes/prom_c_tg_regmap.py --dups` finds each at the other's
; address.  It is given its own name because it has its own callers.
;
; Called from: 0xFAE092, 0xFAE0F8.
; Evidence / Inputs / Outputs: see 0xFACEA2.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0840_0880_dup:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FACF78  ee 0c fc ff
	pushw hl                                   ; FACF7C  2b
	push xix                                   ; FACF7D  3c
	ld hl, (xiz+8)                             ; FACF7E  9e 08 23
	add hl, 0x0840                             ; FACF81  db c8 40 08
	ld xix, 0x0010C000                         ; FACF85  44 00 c0 10 00
	ld (xix), hl                               ; FACF8A  b4 53
	ld xbc, (xiz+10)                           ; FACF8C  ae 0a 21
	ld hl, (xbc+26)                            ; FACF8F  99 1a 23
	ld xwa, xix                                ; FACF92  ec 88
	inc 2, xwa                                 ; FACF94  e8 62
	ld (xiz-4), xwa                            ; FACF96  be fc 60
	ld (xwa), hl                               ; FACF99  b0 53
	ld bc, (xiz+8)                             ; FACF9B  9e 08 21
	add bc, 0x0880                             ; FACF9E  d9 c8 80 08
	ld (xix), bc                               ; FACFA2  b4 51
	ld xbc, (xiz+10)                           ; FACFA4  ae 0a 21
	ld wa, (xbc+28)                            ; FACFA7  99 1c 20
	ld xiy, (xiz-4)                            ; FACFAA  ae fc 25
	ld (xiy), wa                               ; FACFAD  b5 50
	pop xix                                    ; FACFAF  5c
	popw hl                                    ; FACFB0  4b
	unlk32 xiz                                 ; FACFB1  ee 0d
	ret                                        ; FACFB3  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0180 -- register (chan + 0x0180) = staging->0x0C.
; Called from: 0xFAE650, 0xFAE78C.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0180:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACFB4  ee 0c 00 00
	pushw hl                                   ; FACFB8  2b
	push xix                                   ; FACFB9  3c
	ld hl, (xiz+8)                             ; FACFBA  9e 08 23
	add hl, 0x0180                             ; FACFBD  db c8 80 01
	ld xix, 0x0010C000                         ; FACFC1  44 00 c0 10 00
	ld (xix), hl                               ; FACFC6  b4 53
	ld xbc, (xiz+10)                           ; FACFC8  ae 0a 21
	ld wa, (xbc+12)                            ; FACFCB  99 0c 20
	ld (xix+2), wa                             ; FACFCE  bc 02 50
	pop xix                                    ; FACFD1  5c
	popw hl                                    ; FACFD2  4b
	unlk32 xiz                                 ; FACFD3  ee 0d
	ret                                        ; FACFD5  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0440 -- register (chan + 0x0440) = staging->0x10.
; Called from: 0xFAE3D3, 0xFAE50D.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0440:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACFD6  ee 0c 00 00
	pushw hl                                   ; FACFDA  2b
	push xix                                   ; FACFDB  3c
	ld hl, (xiz+8)                             ; FACFDC  9e 08 23
	add hl, 0x0440                             ; FACFDF  db c8 40 04
	ld xix, 0x0010C000                         ; FACFE3  44 00 c0 10 00
	ld (xix), hl                               ; FACFE8  b4 53
	ld xbc, (xiz+10)                           ; FACFEA  ae 0a 21
	ld wa, (xbc+16)                            ; FACFED  99 10 20
	ld (xix+2), wa                             ; FACFF0  bc 02 50
	pop xix                                    ; FACFF3  5c
	popw hl                                    ; FACFF4  4b
	unlk32 xiz                                 ; FACFF5  ee 0d
	ret                                        ; FACFF7  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_04C0 -- register (chan + 0x04C0) = staging->0x14.
; Called from: 0xFAE8D1, 0xFAEA0F.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_04C0:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACFF8  ee 0c 00 00
	pushw hl                                   ; FACFFC  2b
	push xix                                   ; FACFFD  3c
	ld hl, (xiz+8)                             ; FACFFE  9e 08 23
	add hl, 0x04C0                             ; FAD001  db c8 c0 04
	ld xix, 0x0010C000                         ; FAD005  44 00 c0 10 00
	ld (xix), hl                               ; FAD00A  b4 53
	ld xbc, (xiz+10)                           ; FAD00C  ae 0a 21
	ld wa, (xbc+20)                            ; FAD00F  99 14 20
	ld (xix+2), wa                             ; FAD012  bc 02 50
	pop xix                                    ; FAD015  5c
	popw hl                                    ; FAD016  4b
	unlk32 xiz                                 ; FAD017  ee 0d
	ret                                        ; FAD019  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0600 -- register (chan + 0x0600) = staging->0x40.
; Called from: 0xFAE475, 0xFAE598.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0600:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD01A  ee 0c 00 00
	pushw hl                                   ; FAD01E  2b
	push xix                                   ; FAD01F  3c
	ld hl, (xiz+8)                             ; FAD020  9e 08 23
	add hl, 0x0600                             ; FAD023  db c8 00 06
	ld xix, 0x0010C000                         ; FAD027  44 00 c0 10 00
	ld (xix), hl                               ; FAD02C  b4 53
	ld xbc, (xiz+10)                           ; FAD02E  ae 0a 21
	ld wa, (xbc+64)                            ; FAD031  99 40 20
	ld (xix+2), wa                             ; FAD034  bc 02 50
	pop xix                                    ; FAD037  5c
	popw hl                                    ; FAD038  4b
	unlk32 xiz                                 ; FAD039  ee 0d
	ret                                        ; FAD03B  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0580 -- register (chan + 0x0580) = staging->0x3C.
; Called from: 0xFAE5B7.  No copy of this body exists elsewhere in prom_c
;              (`--dups`), unlike thirteen of its neighbours.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0580:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD03C  ee 0c 00 00
	pushw hl                                   ; FAD040  2b
	push xix                                   ; FAD041  3c
	ld hl, (xiz+8)                             ; FAD042  9e 08 23
	add hl, 0x0580                             ; FAD045  db c8 80 05
	ld xix, 0x0010C000                         ; FAD049  44 00 c0 10 00
	ld (xix), hl                               ; FAD04E  b4 53
	ld xbc, (xiz+10)                           ; FAD050  ae 0a 21
	ld wa, (xbc+60)                            ; FAD053  99 3c 20
	ld (xix+2), wa                             ; FAD056  bc 02 50
	pop xix                                    ; FAD059  5c
	popw hl                                    ; FAD05A  4b
	unlk32 xiz                                 ; FAD05B  ee 0d
	ret                                        ; FAD05D  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_01C0 -- register (chan + 0x01C0) = staging->0x38.
; Called from: 0xFAE6F4, 0xFAE819.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_01C0:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD05E  ee 0c 00 00
	pushw hl                                   ; FAD062  2b
	push xix                                   ; FAD063  3c
	ld hl, (xiz+8)                             ; FAD064  9e 08 23
	add hl, 0x01C0                             ; FAD067  db c8 c0 01
	ld xix, 0x0010C000                         ; FAD06B  44 00 c0 10 00
	ld (xix), hl                               ; FAD070  b4 53
	ld xbc, (xiz+10)                           ; FAD072  ae 0a 21
	ld wa, (xbc+56)                            ; FAD075  99 38 20
	ld (xix+2), wa                             ; FAD078  bc 02 50
	pop xix                                    ; FAD07B  5c
	popw hl                                    ; FAD07C  4b
	unlk32 xiz                                 ; FAD07D  ee 0d
	ret                                        ; FAD07F  0e
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0540 -- register (chan + 0x0540) = staging->0x3A.
; Called from: 0xFAE838.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0540:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD080  ee 0c 00 00
	pushw hl                                   ; FAD084  2b
	push xix                                   ; FAD085  3c
	ld hl, (xiz+8)                             ; FAD086  9e 08 23
	add hl, 0x0540                             ; FAD089  db c8 40 05
	ld xix, 0x0010C000                         ; FAD08D  44 00 c0 10 00
	ld (xix), hl                               ; FAD092  b4 53
	ld xbc, (xiz+10)                           ; FAD094  ae 0a 21
	ld wa, (xbc+58)                            ; FAD097  99 3a 20
	ld (xix+2), wa                             ; FAD09A  bc 02 50
	pop xix                                    ; FAD09D  5c
	popw hl                                    ; FAD09E  4b
	unlk32 xiz                                 ; FAD09F  ee 0d
	ret                                        ; FAD0A1  0e
; --------------------------------------------------------------------------
; ★ Dev10C_SetChanReg_01C0_or_0600 -- the channel number is COMPARED AGAINST 0x40 and
; picks BOTH the register block and the source field:
;
;       chan <  0x40 :  register (chan + 0x01C0) = staging->0x38
;       chan >= 0x40 :  register (chan + 0x0600) = staging->0x42
;
; Called from: 0xFAE977, 0xFAEAA4.
; Inputs:  (XIZ+8) = chan, (XIZ+10) = staging struct.
; Outputs: exactly ONE 16-bit write, on whichever arm is taken.
; Evidence: `cp hl,0x0040` / `jr nc,...`.  On TLCS-900 CF is set when the first
;          operand is the smaller, so NC is taken for chan >= 0x40.  The two arms
;          are otherwise the same six instructions with different constants.
; ⚠ WHAT THE SPLIT MEANS IS NOT ESTABLISHED.  The obvious reading -- that the
;          first 64 channels are one kind of voice and the rest another -- is a
;          reading.  What IS on the ROM: the arms differ in the register block AND
;          in which staging field they read, so the two ranges are not the same
;          parameter relocated; they are different parameters.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_01C0_or_0600:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD0A2  ee 0c 00 00
	pushw hl                                   ; FAD0A6  2b
	pushw de                                   ; FAD0A7  2a
	push xix                                   ; FAD0A8  3c
	ld hl, (xiz+8)                             ; FAD0A9  9e 08 23
	cp hl, 0x0040                              ; FAD0AC  db cf 40 00
	jr nc, Dev10C_SetChanReg_01C0_or_0600__high                            ; FAD0B0  6f 18
	ld de, hl                                  ; FAD0B2  db 8a
	add de, 0x01C0                             ; FAD0B4  da c8 c0 01
	ld xix, 0x0010C000                         ; FAD0B8  44 00 c0 10 00
	ld (xix), de                               ; FAD0BD  b4 52
	ld xbc, (xiz+10)                           ; FAD0BF  ae 0a 21
	ld wa, (xbc+56)                            ; FAD0C2  99 38 20
	ld (xix+2), wa                             ; FAD0C5  bc 02 50
	jr Dev10C_SetChanReg_01C0_or_0600__done                                ; FAD0C8  68 16
Dev10C_SetChanReg_01C0_or_0600__high:
	ld de, hl                                  ; FAD0CA  db 8a
	add de, 0x0600                             ; FAD0CC  da c8 00 06
	ld xix, 0x0010C000                         ; FAD0D0  44 00 c0 10 00
	ld (xix), de                               ; FAD0D5  b4 52
	ld xbc, (xiz+10)                           ; FAD0D7  ae 0a 21
	ld wa, (xbc+66)                            ; FAD0DA  99 42 20
	ld (xix+2), wa                             ; FAD0DD  bc 02 50
Dev10C_SetChanReg_01C0_or_0600__done:
	pop xix                                    ; FAD0E0  5c
	popw de                                    ; FAD0E1  4a
	popw hl                                    ; FAD0E2  4b
	unlk32 xiz                                 ; FAD0E3  ee 0d
	ret                                        ; FAD0E5  0e
; --------------------------------------------------------------------------
; ★ Dev10C_SetChanReg_0540_or_0580 -- the same split, different pair:
;
;       chan <  0x40 :  register (chan + 0x0540) = staging->0x3A
;       chan >= 0x40 :  register (chan + 0x0580) = staging->0x3E
;
; Called from: 0xFAEABE.
; Evidence: identical shape to 0xFAD0A2; `cp hl,0x0040` / `jr nc,...`.
; ⚠ Note the low arm is the same (block, field) pair as Dev10C_SetChanReg_0540 at
;          0xFAD080, and the high arm is the same BLOCK as Dev10C_SetChanReg_0580 at
;          0xFAD03C but a DIFFERENT source field (0x3E, not 0x3C).
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0540_or_0580:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD0E6  ee 0c 00 00
	pushw hl                                   ; FAD0EA  2b
	pushw de                                   ; FAD0EB  2a
	push xix                                   ; FAD0EC  3c
	ld hl, (xiz+8)                             ; FAD0ED  9e 08 23
	cp hl, 0x0040                              ; FAD0F0  db cf 40 00
	jr nc, Dev10C_SetChanReg_0540_or_0580__high                            ; FAD0F4  6f 18
	ld de, hl                                  ; FAD0F6  db 8a
	add de, 0x0540                             ; FAD0F8  da c8 40 05
	ld xix, 0x0010C000                         ; FAD0FC  44 00 c0 10 00
	ld (xix), de                               ; FAD101  b4 52
	ld xbc, (xiz+10)                           ; FAD103  ae 0a 21
	ld wa, (xbc+58)                            ; FAD106  99 3a 20
	ld (xix+2), wa                             ; FAD109  bc 02 50
	jr Dev10C_SetChanReg_0540_or_0580__done                                ; FAD10C  68 16
Dev10C_SetChanReg_0540_or_0580__high:
	ld de, hl                                  ; FAD10E  db 8a
	add de, 0x0580                             ; FAD110  da c8 80 05
	ld xix, 0x0010C000                         ; FAD114  44 00 c0 10 00
	ld (xix), de                               ; FAD119  b4 52
	ld xbc, (xiz+10)                           ; FAD11B  ae 0a 21
	ld wa, (xbc+62)                            ; FAD11E  99 3e 20
	ld (xix+2), wa                             ; FAD121  bc 02 50
Dev10C_SetChanReg_0540_or_0580__done:
	pop xix                                    ; FAD124  5c
	popw de                                    ; FAD125  4a
	popw hl                                    ; FAD126  4b
	unlk32 xiz                                 ; FAD127  ee 0d
	ret                                        ; FAD129  0e
; --------------------------------------------------------------------------
; Dev10C_WriteReg_0201 -- register 0x0201 = the caller's word.  The only routine in
; the bank whose register number is a constant.
;
; Called from: 0xFADCB9, its only calr site, which builds the word as
;              `and bc,0x0F9F / or bc,ix / or bc,hl` -- a packed field, so 0x0201
;              is a CONTROL register and not a per-channel parameter.
; Inputs:  (XIZ+8) = the 16-bit value.  There is no second argument: the caller
;          drops 2 bytes (`pop BC`), not 6.
; Outputs: one 16-bit write.
; Evidence: `ldw (xix),0x0201` writes the number as an immediate.
; Unknown:  what the register does, and what the 0x0F9F mask means.  Under the
;          `block*0x40 + channel` reading of the address that number is block 8,
;          channel 1 -- stated because the arithmetic works, not because anything
;          confirms it.
; --------------------------------------------------------------------------
Dev10C_WriteReg_0201:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAD12A  ee 0c 00 00
	push xix                                   ; FAD12E  3c
	ld xix, 0x0010C000                         ; FAD12F  44 00 c0 10 00
	ldw (xix), 0x0201                          ; FAD134  b4 02 01 02
	ld bc, (xiz+8)                             ; FAD138  9e 08 21
	ld (xix+2), bc                             ; FAD13B  bc 02 51
	pop xix                                    ; FAD13E  5c
	unlk32 xiz                                 ; FAD13F  ee 0d
	ret                                        ; FAD141  0e

; ==============================================================================
; 0xFAD142-0xFCC53E -- not yet converted
; ==============================================================================
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x02D142, 0x009CC8
; ==============================================================================
; 0xFB6E0A-0xFB7344 -- the FULL per-channel register map of 0x0010C000, the
;                      block-0x0080 GATE and its RAM shadow
;                      9 routines, 1,339 bytes
; ==============================================================================
;
; The block above (0xFACE67, the first accessor bank) writes ONE register per
; routine.  This block contains the routine that writes a whole channel at once,
; and with it the register blocks the first bank never touches.
;
; ★★ TWENTY-TWO REGISTERS OF ONE CHANNEL, AND THE STRUCT IS THE REGISTER FILE IN
; ORDER.  Dev10C_WriteAllChanRegs (0xFB713A) is an unrolled run of select/write pairs.
; They were extracted by a symbolic walk, not by eye -- `notes/prom_c_tg_chanmap.py`
; follows the two frame slots that hold the +0 and +2 pointers, tracks what each
; 16-bit register holds, and preserves across a `calr` exactly the registers the
; CALLEE pushes and pops (read off the callee, not assumed):
;
;   $ python3 notes/prom_c_tg_chanmap.py 0xFB713A 0x1F2 --pairs
;   $ python3 notes/prom_c_tg_chanmap.py 0xFB713A 0x1F2 --groups
;   $ python3 notes/prom_c_tg_chanmap.py --selftest      # checks the LAST pair
;
;     register block   0x0040 0x0080 0x00C0 0x0100 0x0140 0x0180
;     struct word           1      2      3      4      5      6   (offset 0x02..0x0C)
;
;     register block   0x0400 0x0440 0x0480 0x04C0 0x0500
;     struct word           7      8      9     10     11        (offset 0x0E..0x16)
;
;     register block   0x0800 0x0840 0x0880 0x08C0 0x0900 0x0940 0x0980 0x09C0 0x0A00 0x0A40
;     struct word          12     13     14     15     16     17     18     19     20     21
;                                                                    (offset 0x18..0x2A)
;
;     register block   0x0000  <- the LITERAL 0x8100, no struct field at all
;
; So the struct's words 1..21 map onto THREE CONSECUTIVE RUNS of register blocks:
; indices 1-6, 16-20 and 32-41.  `--groups` derives the runs mechanically and
; prints them; it reports four runs rather than three only because block 0x0080 is
; written through the bit-15 path below and is excluded from the plain
; (SELECT, DATA) pairing.  Put it back and the first run is 1..6 unbroken.
;
; ★ EIGHT REGISTER BLOCKS HERE ARE NEW.  notes/FINDINGS-prom_c-tone-generator.md
; §2 lists the 19 distinct constants its census could match:
;   0x0040 0x0080 0x00C0 0x0100 0x0140 0x0180 0x01C0 0x0400 0x0440 0x0480 0x04C0
;   0x0540 0x0580 0x05C0 0x0600 0x0640 0x0800 0x0840 0x0880.
; This routine adds 0x0500, 0x08C0, 0x0900, 0x0940, 0x0980, 0x09C0, 0x0A00 and
; 0x0A40.  The highest register number the device is now known to take is
; therefore 0x0A40 + 0x3F = 0x0A7F, not 0x08BF.  That note's §10 asked for exactly
; this: "the five blocks the first bank never touches ... are the remaining
; 0x0010C000 surface".
;
; ★★ BLOCK 0x0080 IS A GATE WITH A RAM SHADOW, AND THE SHADOW IS AT 0x0000D85B.
; Three routines here do nothing but re-issue one channel's block-0x0080 value
; with bit 15 forced:
;     Dev10C_ChanMinus2_SetReg_0080_Bit15 (0xFB6E8C)  read shadow, SET bit 15, write
;     Dev10C_ChanMinus2_ClrReg_0080_Bit15 (0xFB6EDC)  read shadow, CLEAR bit 15, write
;     Dev10C_SetChanReg_0080_ClrBit15     (0xFB7038)  write struct+0x04 with bit 15
;                                                 clear, and store it to the
;                                                 shadow with bit 15 SET
; The shadow is a 16-bit array at work DRAM 0x0000D85B indexed by channel
; (`ld BC,0x0002 / mul XBC,HL / add XBC,0x0000D85B`), and Dev10C_WriteAllChanRegs
; writes it at 0xFB7317-0xFB7322 with the same value it last sent the device.
; This is the same "bit 15 written 1 then 0" shape §5 of the tone-generator note
; found in the second accessor bank, here with the value it pulses kept in RAM.
; ⚠ What the pulse DOES is still not established.
;
; ★ THE PER-CHANNEL RECORD AT 0x00003BCF CARRIES A TWO-BIT STATE, AND THIS BLOCK
; DRIVES IT.  Every routine here that touches a channel first computes
; `record = 0x00003BCF + 0x44 * ch + 1` -- the 0x44 = 68-byte stride the
; tone-generator note already established for that array -- and reads the 16-bit
; word there:
;     0xFB6E2E  `and WA,0x0600 / cp WA,0x0200`   bit 9 set AND bit 10 clear
;               -> load registers 0x0900/0x0940/0x0980 and SET bit 10 (0xFB6E3A)
;     0xFB6F49  `and WA,0x0400`                  bit 10 set
;               -> run the gate sequence and CLEAR bit 10 (0xFB6FB7, `and ...,0xFBFF`)
;     0xFB6EAA  `cp WA,0`                        the whole word non-zero
;               -> otherwise do nothing
; So bit 9 and bit 10 of that word are a request/loaded pair.  Stated as read; no
; name is given to either bit.
;
; ⚠ THE ±2 IS REAL AND IS NOT EXPLAINED.  0xFB6E0A operates on channel
; `(arg0 + 2) & 0x3F` and 0xFB6E8C/0xFB6EDC on `(arg0 - 2) & 0x3F` -- both the
; record lookup AND the register number use the adjusted value.  The masks make
; it wrap inside 0..0x3F.  Dev10C_WriteAllChanRegs calls the minus-2 helper twice and
; the plus-2 helper once and then writes ITS OWN channel's registers unadjusted,
; so one call touches three different channels.  Why is NOT ESTABLISHED.
;
; ⚠ AND A TRAP FOR THE XREF TOOL.  0xFB6F2C and 0xFB707E call 0xFB6E8C five times
; each through the idiom
;       lda XIX,0xFB6E8C ... push arg / lda XIY,<return> / push XIY / jp (XIX)
; -- a hand-built call.  `notes/prom_c_xrefs.py 0xFB6E8C` classifies the two
; `lda XIX,0xFB6E8C` sites (0xFB6F33, 0xFB7085) as "operand/data" because the byte
; in front of the literal is not 0x1D, and it cannot see the ten transfers at all.
; A caller census of this routine that trusted the tool's classification would be
; wrong by ten.
;
; Transcribed with notes/llvm_roundtrip_autoforce.py c 0xFB6E0A 0x53B, restyled by
; notes/prom_c_listing_prep.py, and re-proved before insertion with
; `python3 notes/prom_c_verify_fragment.py c 0xFB6E0A <file>`.

; --------------------------------------------------------------------------
; Dev10C_ChanPlus2_SetRegs_09xx -- for channel (arg0+2)&0x3F, and only if its record
;             word says "requested but not loaded", write register blocks 0x0900,
;             0x0940 and 0x0980 and mark it loaded.
;
; Called from: three calr sites -- the instructions at 0xFB7043
;          (Dev10C_SetChanReg_0080_ClrBit15), 0xFB7150 (Dev10C_WriteAllChanRegs) and
;          0xFB75A9 (not converted).  notes/prom_c_xrefs.py 0xFB6E0A.
; Inputs:  (XIZ+0x08) u16.  The channel it acts on is (arg0 + 2) & 0x3F -- `inc
;          2,HL / and HL,0x003F`, and every later use is of that value.
; Outputs: nothing at all unless bits 10..9 of the record word are exactly 0b01;
;          then registers ch+0x0900, ch+0x0940 and ch+0x0980 of 0x0010C000 all
;          receive the SAME value, and bit 10 of the record word is set.
; Evidence: the guard is `ld WA,DE / and WA,0x0600 / cp WA,0x0200 / jr NZ,exit`
;          on the 16-bit word at 0x00003BCF + 0x44*ch + 1; the mark is
;          `set 0x0a,WA` written back to the same place.  The value written to
;          all three registers is the low byte of the u16 at
;          0x0000E21D + 2*ch (`and DE,0x00FF`).
;          The register numbers come from notes/prom_c_tg_chanmap.py 0xFB6E0A 0x82
;          -- three writes, blocks 0x0900, 0x0940, 0x0980.
; Unknown:  what 0x0000E21D holds and who fills it; what the three registers do;
;          why the channel is offset by +2.
; --------------------------------------------------------------------------
Dev10C_ChanPlus2_SetRegs_09xx:
	link32 0xEE, 0x0C, 0xFC, 0xFF          ; FB6E0A  link XIZ,0xfffc   [llvm-mc cannot encode this]
	pushw	hl                               ; FB6E0E  push HL
	pushw	de                               ; FB6E0F  push DE
	push	xix                               ; FB6E10  push XIX
	ld	hl, (xiz+8)                         ; FB6E11  ld HL,(XIZ+0x08)
	inc	2, hl                              ; FB6E14  inc 2,HL
	and	hl, 63                             ; FB6E16  and HL,0x003f
	ldw	bc, 68                             ; FB6E1A  ld BC,0x0044
	mul	xbc, xhl                           ; FB6E1D  mul XBC,HL
	ld	ix, bc                              ; FB6E1F  ld IX,BC
	inc	1, bc                              ; FB6E21  inc 1,BC
	ld	ix, bc                              ; FB6E23  ld IX,BC
	extz	xbc                               ; FB6E25  extz XBC
	ld	de, (xbc+0x3BCF)                    ; FB6E27  ld DE,(XBC+0x3bcf)
	ld	wa, de                              ; FB6E2C  ld WA,DE
	and	wa, 0x600                          ; FB6E2E  and WA,0x0600
	cp	wa, 0x200                           ; FB6E32  cp WA,0x0200
	jr nz, Dev10C_ChanPlus2_SetRegs_09xx__FB6E86                       ; FB6E36  jr NZ,0xfb6e86
	ld	wa, de                              ; FB6E38  ld WA,DE
	set	10, wa                             ; FB6E3A  set 0x0a,WA
	ld	(xbc+0x3BCF), wa                    ; FB6E3D  ld (XBC+0x3bcf),WA
	ldw	bc, 2                              ; FB6E42  ld BC,0x0002
	mul	xbc, xhl                           ; FB6E45  mul XBC,HL
	add	xbc, 0xE21D                        ; FB6E47  add XBC,0x0000e21d
	ld	bc, (xbc)                           ; FB6E4D  ld BC,(XBC)
	ld	de, bc                              ; FB6E4F  ld DE,BC
	and	de, 0xFF                           ; FB6E51  and DE,0x00ff
	ld	ix, hl                              ; FB6E55  ld IX,HL
	add	ix, 0x900                          ; FB6E57  add IX,0x0900
	ld	xbc, 0x10C000                       ; FB6E5B  ld XBC,0x0010c000
	ld	(xiz-4), xbc                        ; FB6E60  ld (XIZ+0xfc),XBC
	ld	(xbc), ix                           ; FB6E63  ld (XBC),IX
	ld	xix, (xiz-4)                        ; FB6E65  ld XIX,(XIZ+0xfc)
	inc	2, xix                             ; FB6E68  inc 2,XIX
	ld	(xix), de                           ; FB6E6A  ld (XIX),DE
	ld	bc, hl                              ; FB6E6C  ld BC,HL
	add	bc, 0x940                          ; FB6E6E  add BC,0x0940
	ld	xwa, (xiz-4)                        ; FB6E72  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB6E75  ld (XWA),BC
	ld	(xix), de                           ; FB6E77  ld (XIX),DE
	ld	bc, hl                              ; FB6E79  ld BC,HL
	add	bc, 0x980                          ; FB6E7B  add BC,0x0980
	ld	xwa, (xiz-4)                        ; FB6E7F  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB6E82  ld (XWA),BC
	ld	(xix), de                           ; FB6E84  ld (XIX),DE
Dev10C_ChanPlus2_SetRegs_09xx__FB6E86:
	pop	xix                                ; FB6E86  pop XIX
	popw	de                                ; FB6E87  pop DE
	popw	hl                                ; FB6E88  pop HL
	unlk32 xiz                             ; FB6E89  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB6E8B  ret

; --------------------------------------------------------------------------
; Dev10C_ChanMinus2_SetReg_0080_Bit15 -- re-issue channel (arg0-2)&0x3F's block-0x0080
;             value from its RAM shadow, with bit 15 SET.
;
; Called from: SEVEN calr sites (0xFB7148, 0xFB714C in Dev10C_WriteAllChanRegs;
;          0xFB7353/57/5B/5F/63 in the unconverted routine at 0xFB7345) AND TEN
;          more transfers the xref tool cannot see -- see the ⚠ about
;          `lda XIX,0xFB6E8C ... jp (XIX)` in the block comment above.
; Inputs:  (XIZ+0x08) u16; the channel used is (arg0 - 2) & 0x3F.
; Outputs: register ch+0x0080 of 0x0010C000 = shadow[ch] | 0x8000, but only if the
;          record word at 0x00003BCF + 0x44*ch + 1 is non-zero.
; Evidence: `dec 2,HL / and HL,0x003F` fixes the channel; `ld WA,(XBC+0x3bcf) /
;          cp WA,0 / jr Z,exit` is the guard; `ld BC,0x0002 / mul XBC,HL /
;          add XBC,0x0000D85B / ld BC,(XBC)` is the shadow read; `set 0x0f,DE` is
;          the bit; `add IX,0x0080` is the register block.
; Unknown:  what bit 15 means.  Its twin below is the same 80 bytes with `res`
;          in place of `set`.
; --------------------------------------------------------------------------
Dev10C_ChanMinus2_SetReg_0080_Bit15:
	link32 0xEE, 0x0C, 0xFC, 0xFF          ; FB6E8C  link XIZ,0xfffc   [llvm-mc cannot encode this]
	pushw	hl                               ; FB6E90  push HL
	pushw	de                               ; FB6E91  push DE
	pushw	ix                               ; FB6E92  push IX
	ld	hl, (xiz+8)                         ; FB6E93  ld HL,(XIZ+0x08)
	dec	2, hl                              ; FB6E96  dec 2,HL
	and	hl, 63                             ; FB6E98  and HL,0x003f
	ldw	bc, 68                             ; FB6E9C  ld BC,0x0044
	mul	xbc, xhl                           ; FB6E9F  mul XBC,HL
	inc	1, bc                              ; FB6EA1  inc 1,BC
	extz	xbc                               ; FB6EA3  extz XBC
	ld	wa, (xbc+0x3BCF)                    ; FB6EA5  ld WA,(XBC+0x3bcf)
	cps	wa, 0                              ; FB6EAA  cp WA,0
	jr z, Dev10C_ChanMinus2_SetReg_0080_Bit15__FB6ED6                        ; FB6EAC  jr Z,0xfb6ed6
	ldw	bc, 2                              ; FB6EAE  ld BC,0x0002
	mul	xbc, xhl                           ; FB6EB1  mul XBC,HL
	add	xbc, 0xD85B                        ; FB6EB3  add XBC,0x0000d85b
	ld	bc, (xbc)                           ; FB6EB9  ld BC,(XBC)
	ld	de, bc                              ; FB6EBB  ld DE,BC
	set	15, de                             ; FB6EBD  set 0x0f,DE
	ld	ix, hl                              ; FB6EC0  ld IX,HL
	add	ix, 0x80                           ; FB6EC2  add IX,0x0080
	ld	xbc, 0x10C000                       ; FB6EC6  ld XBC,0x0010c000
	ld	(xiz-4), xbc                        ; FB6ECB  ld (XIZ+0xfc),XBC
	ld	(xbc), ix                           ; FB6ECE  ld (XBC),IX
	ld	xbc, (xiz-4)                        ; FB6ED0  ld XBC,(XIZ+0xfc)
	ld	(xbc+2), de                         ; FB6ED3  ld (XBC+0x02),DE
Dev10C_ChanMinus2_SetReg_0080_Bit15__FB6ED6:
	popw	ix                                ; FB6ED6  pop IX
	popw	de                                ; FB6ED7  pop DE
	popw	hl                                ; FB6ED8  pop HL
	unlk32 xiz                             ; FB6ED9  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB6EDB  ret

; --------------------------------------------------------------------------
; Dev10C_ChanMinus2_ClrReg_0080_Bit15 -- the twin of the routine above with bit 15
;             CLEARED instead of set.
;
; Called from: four calr sites -- the instructions at 0xFB6FCC, 0xFB70CB,
;          0xFB729D and 0xFB73BD.
; Inputs / Outputs: as above, except the value written is shadow[ch] & 0x7FFF.
; Evidence: the two routines are 80 bytes each and differ in ONE instruction --
;          0xFB6EBD `da 31 0f` (set 0x0f,DE) against 0xFB6F0D `da 30 0f`
;          (res 0x0f,DE).  Checked byte by byte over the whole 80, not sampled:
;          the only differing offset is +0x32, where 0x31 (`set`) becomes 0x30
;          (`res`) -- one bit of one byte in eighty.
; Unknown:  as above.
; --------------------------------------------------------------------------
Dev10C_ChanMinus2_ClrReg_0080_Bit15:
	link32 0xEE, 0x0C, 0xFC, 0xFF          ; FB6EDC  link XIZ,0xfffc   [llvm-mc cannot encode this]
	pushw	hl                               ; FB6EE0  push HL
	pushw	de                               ; FB6EE1  push DE
	pushw	ix                               ; FB6EE2  push IX
	ld	hl, (xiz+8)                         ; FB6EE3  ld HL,(XIZ+0x08)
	dec	2, hl                              ; FB6EE6  dec 2,HL
	and	hl, 63                             ; FB6EE8  and HL,0x003f
	ldw	bc, 68                             ; FB6EEC  ld BC,0x0044
	mul	xbc, xhl                           ; FB6EEF  mul XBC,HL
	inc	1, bc                              ; FB6EF1  inc 1,BC
	extz	xbc                               ; FB6EF3  extz XBC
	ld	wa, (xbc+0x3BCF)                    ; FB6EF5  ld WA,(XBC+0x3bcf)
	cps	wa, 0                              ; FB6EFA  cp WA,0
	jr z, Dev10C_ChanMinus2_ClrReg_0080_Bit15__FB6F26                        ; FB6EFC  jr Z,0xfb6f26
	ldw	bc, 2                              ; FB6EFE  ld BC,0x0002
	mul	xbc, xhl                           ; FB6F01  mul XBC,HL
	add	xbc, 0xD85B                        ; FB6F03  add XBC,0x0000d85b
	ld	bc, (xbc)                           ; FB6F09  ld BC,(XBC)
	ld	de, bc                              ; FB6F0B  ld DE,BC
	res	15, de                             ; FB6F0D  res 0x0f,DE
	ld	ix, hl                              ; FB6F10  ld IX,HL
	add	ix, 0x80                           ; FB6F12  add IX,0x0080
	ld	xbc, 0x10C000                       ; FB6F16  ld XBC,0x0010c000
	ld	(xiz-4), xbc                        ; FB6F1B  ld (XIZ+0xfc),XBC
	ld	(xbc), ix                           ; FB6F1E  ld (XBC),IX
	ld	xbc, (xiz-4)                        ; FB6F20  ld XBC,(XIZ+0xfc)
	ld	(xbc+2), de                         ; FB6F23  ld (XBC+0x02),DE
Dev10C_ChanMinus2_ClrReg_0080_Bit15__FB6F26:
	popw	ix                                ; FB6F26  pop IX
	popw	de                                ; FB6F27  pop DE
	popw	hl                                ; FB6F28  pop HL
	unlk32 xiz                             ; FB6F29  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB6F2B  ret

; --------------------------------------------------------------------------
; sub_FB6F2C -- NOT NAMED.  For one channel: five bit-15-SET pulses of block
;             0x0080, then one bit-15-CLEAR, then blocks 0x0900/0x0940/0x0980.
;
; Called from: 0xFACAAA (`call 0xFB6F2C`).  One site.
; Inputs:  (XIZ+0x08) u16, used UNADJUSTED as the channel here (the ±2 lives in
;          the helpers it calls).
; Outputs: see below.  Nothing at all unless bit 10 of the record word at
;          0x00003BCF + 0x44*arg0 + 1 is set.
; Evidence: read in order off the instructions --
;            1. guard `and WA,0x0400 / jrl Z,exit`;
;            2. `sh = shadow[(arg0-2)&0x3F]`; if bit 15 of it is SET, clear it,
;               write it back to the shadow and RETURN -- the sequence below is
;               skipped entirely (0xFB6F6D `jr Z` / 0xFB6F7E `jrl T,exit`);
;            3. otherwise call Dev10C_ChanMinus2_SetReg_0080_Bit15 FIVE times with the
;               same argument, through the `push arg / push <return> / jp (XIX)`
;               idiom;
;            4. clear bit 10 of the record word (`and (XBC+0x3bcf),0xFBFF`);
;            5. call Dev10C_ChanMinus2_ClrReg_0080_Bit15 once;
;            6. write registers arg0+0x0900, +0x0940 and +0x0980 with the u16 at
;               0x0000E21D + 2*arg0.
;          The five-then-one shape and the register list come from
;          `python3 notes/prom_c_tg_chanmap.py 0xFB6F2C 0xEA --pairs`.
;          The stack accounting agrees: six 2-byte argument pushes are dropped by
;          `inc 8,xsp` + `inc 4,xsp` = 12 at the end.
; Unknown:  ⚠ WHY FIVE.  The five calls are identical and the shadow does not
;          change between them, so the device receives the same word five times.
;          A hold time is the obvious reading and nothing here supports it.
;          Also unknown: what this routine is FOR.  It is left `sub_` rather than
;          given a plausible name.
; --------------------------------------------------------------------------
sub_FB6F2C:
	link32 0xEE, 0x0C, 0xF2, 0xFF          ; FB6F2C  link XIZ,0xfff2   [llvm-mc cannot encode this]
	pushw	hl                               ; FB6F30  push HL
	pushw	de                               ; FB6F31  push DE
	push	xix                               ; FB6F32  push XIX
	lda_24	xix, (0xFB6E8C)                 ; FB6F33  lda XIX,0xfb6e8c
	ld	de, (xiz+8)                         ; FB6F38  ld DE,(XIZ+0x08)
	ldw	bc, 68                             ; FB6F3B  ld BC,0x0044
	mul	xbc, xde                           ; FB6F3E  mul XBC,DE
	inc	1, bc                              ; FB6F40  inc 1,BC
	extz	xbc                               ; FB6F42  extz XBC
	ld	wa, (xbc+0x3BCF)                    ; FB6F44  ld WA,(XBC+0x3bcf)
	and	wa, 0x400                          ; FB6F49  and WA,0x0400
	jrl z, sub_FB6F2C__FB7010                       ; FB6F4D  jrl Z,0xfb7010
	ld	c, e                                ; FB6F50  ld C,E
	dec	2, c                               ; FB6F52  dec 2,C
	and	c, 63                              ; FB6F54  and C,0x3f
	mul	c, 2                               ; FB6F57  mul C,0x02
	extz	xbc                               ; FB6F5A  extz XBC
	ld	(xiz-4), xbc                        ; FB6F5C  ld (XIZ+0xfc),XBC
	add	xbc, 0xD85B                        ; FB6F5F  add XBC,0x0000d85b
	ld	hl, (xbc)                           ; FB6F65  ld HL,(XBC)
	ld	bc, hl                              ; FB6F67  ld BC,HL
	and	bc, 0x8000                         ; FB6F69  and BC,0x8000
	jr z, sub_FB6F2C__FB6F81                        ; FB6F6D  jr Z,0xfb6f81
	ld	bc, hl                              ; FB6F6F  ld BC,HL
	res	15, bc                             ; FB6F71  res 0x0f,BC
	lda_24	xwa, (0xD85B)                   ; FB6F74  lda XWA,0x00d85b
	extpfx3 0xAE, 0xFC, 0x80               ; FB6F79  add XWA,(XIZ+0xfc)   [llvm-mc cannot encode this]
	ld	(xwa), bc                           ; FB6F7C  ld (XWA),BC
	jrl sub_FB6F2C__FB7010                          ; FB6F7E  jrl T,0xfb7010
sub_FB6F2C__FB6F81:
	pushw	de                               ; FB6F81  push DE
	lda_24	xiy, (0xFB6F8A)                 ; FB6F82  lda XIY,0xfb6f8a
	push	xiy                               ; FB6F87  push XIY
	jp	(xix)                               ; FB6F88  jp T,XIX
	pushw	de                               ; FB6F8A  push DE
	lda_24	xiy, (0xFB6F93)                 ; FB6F8B  lda XIY,0xfb6f93
	push	xiy                               ; FB6F90  push XIY
	jp	(xix)                               ; FB6F91  jp T,XIX
	pushw	de                               ; FB6F93  push DE
	lda_24	xiy, (0xFB6F9C)                 ; FB6F94  lda XIY,0xfb6f9c
	push	xiy                               ; FB6F99  push XIY
	jp	(xix)                               ; FB6F9A  jp T,XIX
	pushw	de                               ; FB6F9C  push DE
	lda_24	xiy, (0xFB6FA5)                 ; FB6F9D  lda XIY,0xfb6fa5
	push	xiy                               ; FB6FA2  push XIY
	jp	(xix)                               ; FB6FA3  jp T,XIX
	pushw	de                               ; FB6FA5  push DE
	lda_24	xiy, (0xFB6FAE)                 ; FB6FA6  lda XIY,0xfb6fae
	push	xiy                               ; FB6FAB  push XIY
	jp	(xix)                               ; FB6FAC  jp T,XIX
	ldw	bc, 68                             ; FB6FAE  ld BC,0x0044
	mul	xbc, xde                           ; FB6FB1  mul XBC,DE
	inc	1, bc                              ; FB6FB3  inc 1,BC
	extz	xbc                               ; FB6FB5  extz XBC
	extpfx7 0xD3, 0xE5, 0xCF, 0x3B, 0x3C, 0xFF, 0xFB ; FB6FB7  and (XBC+0x3bcf),0xfbff   [llvm-mc cannot encode this]
	ldw	bc, 2                              ; FB6FBE  ld BC,0x0002
	mul	xbc, xde                           ; FB6FC1  mul XBC,DE
	add	xbc, 0xE21D                        ; FB6FC3  add XBC,0x0000e21d
	ld	hl, (xbc)                           ; FB6FC9  ld HL,(XBC)
	pushw	de                               ; FB6FCB  push DE
	calr (0xFB6EDC - 0xFB6FCF)             ; FB6FCC  calr 0xfb6edc
	ld	bc, de                              ; FB6FCF  ld BC,DE
	add	bc, 0x900                          ; FB6FD1  add BC,0x0900
	ld	(xiz-6), bc                         ; FB6FD5  ld (XIZ+0xfa),BC
	ld	xwa, 0x10C000                       ; FB6FD8  ld XWA,0x0010c000
	ld	(xiz-10), xwa                       ; FB6FDD  ld (XIZ+0xf6),XWA
	ld	(xwa), bc                           ; FB6FE0  ld (XWA),BC
	ld	xbc, (xiz-10)                       ; FB6FE2  ld XBC,(XIZ+0xf6)
	inc	2, xbc                             ; FB6FE5  inc 2,XBC
	ld	(xiz-14), xbc                       ; FB6FE7  ld (XIZ+0xf2),XBC
	ld	(xbc), hl                           ; FB6FEA  ld (XBC),HL
	ld	bc, de                              ; FB6FEC  ld BC,DE
	add	bc, 0x940                          ; FB6FEE  add BC,0x0940
	ld	xwa, (xiz-10)                       ; FB6FF2  ld XWA,(XIZ+0xf6)
	ld	(xwa), bc                           ; FB6FF5  ld (XWA),BC
	ld	xbc, (xiz-14)                       ; FB6FF7  ld XBC,(XIZ+0xf2)
	ld	(xbc), hl                           ; FB6FFA  ld (XBC),HL
	ld	bc, de                              ; FB6FFC  ld BC,DE
	add	bc, 0x980                          ; FB6FFE  add BC,0x0980
	ld	xwa, (xiz-10)                       ; FB7002  ld XWA,(XIZ+0xf6)
	ld	(xwa), bc                           ; FB7005  ld (XWA),BC
	ld	xbc, (xiz-14)                       ; FB7007  ld XBC,(XIZ+0xf2)
	ld	(xbc), hl                           ; FB700A  ld (XBC),HL
	inc	8, xsp                             ; FB700C  inc 0,XSP
	inc	4, xsp                             ; FB700E  inc 4,XSP
sub_FB6F2C__FB7010:
	pop	xix                                ; FB7010  pop XIX
	popw	de                                ; FB7011  pop DE
	popw	hl                                ; FB7012  pop HL
	unlk32 xiz                             ; FB7013  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB7015  ret

; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0400_c -- register (chan + 0x0400) = struct->0x0E.
;
; Called from: NOT FOUND (notes/prom_c_xrefs.py 0xFB7016: no literal, no calr).
; Inputs:  (XIZ+0x08) chan, (XIZ+0x0a) struct pointer.
; Evidence: ★ BYTE-IDENTICAL, all 34 bytes, to Dev10C_SetChanReg_0400 at 0xFACE67 in
;          the first accessor bank above.  `python3 notes/prom_c_tg_regmap.py
;          --dups` prints the pair (0xFACE67 -> 0xFB7016).  The name is that
;          routine's, with `_c` to keep the label unique; `_b` is the suffix this
;          file already uses for the copies in the bank at 0xFB7B63 onward.
; Unknown:  as for the original -- what register block 0x0400 does.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0400_c:
	link32 0xEE, 0x0C, 0x00, 0x00          ; FB7016  link XIZ,0x0000   [llvm-mc cannot encode this]
	pushw	hl                               ; FB701A  push HL
	push	xix                               ; FB701B  push XIX
	ld	hl, (xiz+8)                         ; FB701C  ld HL,(XIZ+0x08)
	add	hl, 0x400                          ; FB701F  add HL,0x0400
	ld	xix, 0x10C000                       ; FB7023  ld XIX,0x0010c000
	ld	(xix), hl                           ; FB7028  ld (XIX),HL
	ld	xbc, (xiz+10)                       ; FB702A  ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+14)                        ; FB702D  ld WA,(XBC+0x0e)
	ld	(xix+2), wa                         ; FB7030  ld (XIX+0x02),WA
	pop	xix                                ; FB7033  pop XIX
	popw	hl                                ; FB7034  pop HL
	unlk32 xiz                             ; FB7035  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB7037  ret

; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0080_ClrBit15 -- write block 0x0080 with bit 15 CLEAR and leave the
;             shadow holding the same value with bit 15 SET.
;
; Called from: 0xFADE1F (`call 0xFB7038`).  One site.
; Inputs:  (XIZ+0x08) chan, (XIZ+0x0a) struct pointer.
; Outputs: Dev10C_ChanPlus2_SetRegs_09xx(chan) first; then register chan+0x0080 =
;          struct->0x04 with bit 15 cleared; then
;          shadow[chan] = struct->0x04 with bit 15 SET.
; Evidence: `res 0x0f,WA` before the port write at 0xFB705C and `set 0x0f,DE`
;          before the shadow write at 0xFB7075 -- the two polarities are in the
;          SAME routine, four instructions apart, so this is not a transcription
;          slip.  The shadow address is `ld WA,0x0002 / mul XWA,HL /
;          add XWA,0x0000D85B`.
; Unknown:  why the shadow keeps the opposite polarity from what was just sent.
;          Dev10C_WriteAllChanRegs stores the shadow with bit 15 CLEAR instead.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0080_ClrBit15:
	link32 0xEE, 0x0C, 0x00, 0x00          ; FB7038  link XIZ,0x0000   [llvm-mc cannot encode this]
	pushw	hl                               ; FB703C  push HL
	pushw	de                               ; FB703D  push DE
	push	xix                               ; FB703E  push XIX
	ld	hl, (xiz+8)                         ; FB703F  ld HL,(XIZ+0x08)
	pushw	hl                               ; FB7042  push HL
	calr (0xFB6E0A - 0xFB7046)             ; FB7043  calr 0xfb6e0a
	ld	de, hl                              ; FB7046  ld DE,HL
	add	de, 0x80                           ; FB7048  add DE,0x0080
	ld	xix, 0x10C000                       ; FB704C  ld XIX,0x0010c000
	ld	(xix), de                           ; FB7051  ld (XIX),DE
	ld	xbc, (xiz+10)                       ; FB7053  ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+4)                         ; FB7056  ld WA,(XBC+0x04)
	res	15, wa                             ; FB7059  res 0x0f,WA
	ld	(xix+2), wa                         ; FB705C  ld (XIX+0x02),WA
	ld	xbc, (xiz+10)                       ; FB705F  ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+4)                         ; FB7062  ld WA,(XBC+0x04)
	ld	de, wa                              ; FB7065  ld DE,WA
	set	15, de                             ; FB7067  set 0x0f,DE
	ldw	wa, 2                              ; FB706A  ld WA,0x0002
	mul	xwa, xhl                           ; FB706D  mul XWA,HL
	add	xwa, 0xD85B                        ; FB706F  add XWA,0x0000d85b
	ld	(xwa), de                           ; FB7075  ld (XWA),DE
	popw	bc                                ; FB7077  pop BC
	pop	xix                                ; FB7078  pop XIX
	popw	de                                ; FB7079  pop DE
	popw	hl                                ; FB707A  pop HL
	unlk32 xiz                             ; FB707B  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB707D  ret

; --------------------------------------------------------------------------
; sub_FB707E -- NOT NAMED.  sub_FB6F2C's shape, but taking a struct: five bit-15
;             pulses, clear the record bit, then blocks 0x0500 and 0x09xx from the
;             struct.
;
; Called from: 0xFADD78 (`call 0xFB707E`).  One site.
; Inputs:  (XIZ+0x08) chan, (XIZ+0x0a) struct pointer.
; Outputs: five calls to Dev10C_ChanMinus2_SetReg_0080_Bit15(chan) through the
;          `jp (XIX)` idiom; bit 10 of the record word cleared; one call to
;          Dev10C_ChanMinus2_ClrReg_0080_Bit15(chan); then
;              register chan+0x0500 = struct->0x16
;              register chan+0x0900 = struct->0x20
;              register chan+0x0940 = struct->0x22
;              register chan+0x0980 = struct->0x24
; Evidence: `python3 notes/prom_c_tg_chanmap.py 0xFB707E 0xBC --pairs` lists the
;          four register writes and the call; the five hand-built calls are the
;          five `lda XIY,<next> / push XIY / jp (XIX)` groups at 0xFB708E-0xFB70B8
;          with XIX loaded from 0xFB7085.  Unlike sub_FB6F2C there is NO guard on
;          the record word at entry -- the five pulses always run.
;          The four (block, field) pairs are the same four
;          Dev10C_WriteAllChanRegs uses for words 11, 16, 17 and 18.
; Unknown:  as sub_FB6F2C; and why this one has no entry guard.
; --------------------------------------------------------------------------
sub_FB707E:
	link32 0xEE, 0x0C, 0xF8, 0xFF          ; FB707E  link XIZ,0xfff8   [llvm-mc cannot encode this]
	pushw	hl                               ; FB7082  push HL
	pushw	de                               ; FB7083  push DE
	push	xix                               ; FB7084  push XIX
	lda_24	xix, (0xFB6E8C)                 ; FB7085  lda XIX,0xfb6e8c
	ld	hl, (xiz+8)                         ; FB708A  ld HL,(XIZ+0x08)
	pushw	hl                               ; FB708D  push HL
	lda_24	xiy, (0xFB7096)                 ; FB708E  lda XIY,0xfb7096
	push	xiy                               ; FB7093  push XIY
	jp	(xix)                               ; FB7094  jp T,XIX
	pushw	hl                               ; FB7096  push HL
	lda_24	xiy, (0xFB709F)                 ; FB7097  lda XIY,0xfb709f
	push	xiy                               ; FB709C  push XIY
	jp	(xix)                               ; FB709D  jp T,XIX
	pushw	hl                               ; FB709F  push HL
	lda_24	xiy, (0xFB70A8)                 ; FB70A0  lda XIY,0xfb70a8
	push	xiy                               ; FB70A5  push XIY
	jp	(xix)                               ; FB70A6  jp T,XIX
	pushw	hl                               ; FB70A8  push HL
	lda_24	xiy, (0xFB70B1)                 ; FB70A9  lda XIY,0xfb70b1
	push	xiy                               ; FB70AE  push XIY
	jp	(xix)                               ; FB70AF  jp T,XIX
	pushw	hl                               ; FB70B1  push HL
	lda_24	xiy, (0xFB70BA)                 ; FB70B2  lda XIY,0xfb70ba
	push	xiy                               ; FB70B7  push XIY
	jp	(xix)                               ; FB70B8  jp T,XIX
	ldw	bc, 68                             ; FB70BA  ld BC,0x0044
	mul	xbc, xhl                           ; FB70BD  mul XBC,HL
	inc	1, bc                              ; FB70BF  inc 1,BC
	extz	xbc                               ; FB70C1  extz XBC
	extpfx7 0xD3, 0xE5, 0xCF, 0x3B, 0x3C, 0xFF, 0xFB ; FB70C3  and (XBC+0x3bcf),0xfbff   [llvm-mc cannot encode this]
	pushw	hl                               ; FB70CA  push HL
	calr (0xFB6EDC - 0xFB70CE)             ; FB70CB  calr 0xfb6edc
	ld	de, hl                              ; FB70CE  ld DE,HL
	add	de, 0x500                          ; FB70D0  add DE,0x0500
	ld	xbc, 0x10C000                       ; FB70D4  ld XBC,0x0010c000
	ld	(xiz-4), xbc                        ; FB70D9  ld (XIZ+0xfc),XBC
	ld	(xbc), de                           ; FB70DC  ld (XBC),DE
	ld	xbc, (xiz+10)                       ; FB70DE  ld XBC,(XIZ+0x0a)
	ld	de, (xbc+22)                        ; FB70E1  ld DE,(XBC+0x16)
	ld	xwa, (xiz-4)                        ; FB70E4  ld XWA,(XIZ+0xfc)
	inc	2, xwa                             ; FB70E7  inc 2,XWA
	ld	(xiz-8), xwa                        ; FB70E9  ld (XIZ+0xf8),XWA
	ld	(xwa), de                           ; FB70EC  ld (XWA),DE
	ld	bc, hl                              ; FB70EE  ld BC,HL
	add	bc, 0x900                          ; FB70F0  add BC,0x0900
	ld	xwa, (xiz-4)                        ; FB70F4  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB70F7  ld (XWA),BC
	ld	xbc, (xiz+10)                       ; FB70F9  ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+32)                        ; FB70FC  ld WA,(XBC+0x20)
	ld	xiy, (xiz-8)                        ; FB70FF  ld XIY,(XIZ+0xf8)
	ld	(xiy), wa                           ; FB7102  ld (XIY),WA
	ld	bc, hl                              ; FB7104  ld BC,HL
	add	bc, 0x940                          ; FB7106  add BC,0x0940
	ld	xwa, (xiz-4)                        ; FB710A  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB710D  ld (XWA),BC
	ld	xbc, (xiz+10)                       ; FB710F  ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+34)                        ; FB7112  ld WA,(XBC+0x22)
	ld	xiy, (xiz-8)                        ; FB7115  ld XIY,(XIZ+0xf8)
	ld	(xiy), wa                           ; FB7118  ld (XIY),WA
	ld	bc, hl                              ; FB711A  ld BC,HL
	add	bc, 0x980                          ; FB711C  add BC,0x0980
	ld	xwa, (xiz-4)                        ; FB7120  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB7123  ld (XWA),BC
	ld	xbc, (xiz+10)                       ; FB7125  ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+36)                        ; FB7128  ld WA,(XBC+0x24)
	ld	xiy, (xiz-8)                        ; FB712B  ld XIY,(XIZ+0xf8)
	ld	(xiy), wa                           ; FB712E  ld (XIY),WA
	inc	8, xsp                             ; FB7130  inc 0,XSP
	inc	4, xsp                             ; FB7132  inc 4,XSP
	pop	xix                                ; FB7134  pop XIX
	popw	de                                ; FB7135  pop DE
	popw	hl                                ; FB7136  pop HL
	unlk32 xiz                             ; FB7137  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB7139  ret

; --------------------------------------------------------------------------
; ★★ Dev10C_WriteAllChanRegs -- twenty-two registers of ONE channel of 0x0010C000, in
;             one unrolled run, from a 0x2C-byte struct.  The twin of
;             Dev104_WriteAllChanRegs (0xFB77EF), which does the same for 0x00104000.
;
; Called from: SEVEN sites -- `call 0xFB713A` at 0xFAC3FE, 0xFB0B86, 0xFB1FA5,
;          0xFB288B, 0xFB2F65 and 0xFC3F17, plus the `calr` at 0xFB817E inside
;          Dev10C_ResetAllChannels (which is why step 5 of the reset sweep in
;          notes/FINDINGS-prom_c-tone-generator.md §6 lists 0xFB713A).
;          notes/prom_c_xrefs.py 0xFB713A.
; Inputs:  (XIZ+0x08) channel, (XIZ+0x0a) pointer to the staging struct (XIX).
; Outputs: the register table in the block comment above, plus the three helper
;          calls at the top and the shadow write at the bottom.
; Evidence: ★ THE WHOLE TABLE IS MACHINE-EXTRACTED.  `notes/prom_c_tg_chanmap.py`
;          walks the routine, tracks the two device pointers through their frame
;          slots and the value registers through their arithmetic, and prints
;          every port write in EXECUTION ORDER with its provenance -- it does not
;          zip two lists, which is the mistake
;          notes/FINDINGS-prom_c-tone-generator.md §3 had to retract:
;
;            $ python3 notes/prom_c_tg_chanmap.py --selftest
;              Dev10C_WriteAllChanRegs 0xFB713A: 23 SELECT, 23 DATA, 0 untracked
;              selftest: OK
;
;          The selftest asserts the LAST select (arg0 + 0x0080) and the LAST data
;          write (struct+0x04 with bit 15 cleared), not the first.
;          ★ THE LAST WRITE IS THE GATE FALLING.  Register chan+0x0080 is written
;          TWICE by this routine: at 0xFB7179 with struct->0x04 and bit 15 SET, and
;          at 0xFB7302 with the same field and bit 15 CLEAR -- the 1-then-0 pulse
;          §5 of the tone-generator note describes, here wrapped round the other
;          twenty registers instead of round one companion.
;          ★ AND THE PULSE'S VALUE IS THEN SHADOWED: 0xFB7317-0xFB7322 stores
;          struct->0x04 with bit 15 clear to 0x0000D85B + 2*chan, which is exactly
;          what the two ±2 helpers read back.
;          Register block 0 gets the literal 0x8100 (0xFB7239) and no struct field
;          -- the same constant three routines of the second accessor bank write,
;          per §5 of that note.
; Unknown:  what any register does; what struct word 0 (offset 0x00) is for --
;          this routine never writes it, while Dev104_WriteAllChanRegs writes its
;          word 0 LAST.
; --------------------------------------------------------------------------
Dev10C_WriteAllChanRegs:
	link32 0xEE, 0x0C, 0xF8, 0xFF          ; FB713A  link XIZ,0xfff8   [llvm-mc cannot encode this]
	pushw	hl                               ; FB713E  push HL
	pushw	de                               ; FB713F  push DE
	push	xix                               ; FB7140  push XIX
	ld	xix, (xiz+10)                       ; FB7141  ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                         ; FB7144  ld HL,(XIZ+0x08)
	pushw	hl                               ; FB7147  push HL
	calr (0xFB6E8C - 0xFB714B)             ; FB7148  calr 0xfb6e8c
	pushw	hl                               ; FB714B  push HL
	calr (0xFB6E8C - 0xFB714F)             ; FB714C  calr 0xfb6e8c
	pushw	hl                               ; FB714F  push HL
	calr (0xFB6E0A - 0xFB7153)             ; FB7150  calr 0xfb6e0a
	ld	de, hl                              ; FB7153  ld DE,HL
	add	de, 64                             ; FB7155  add DE,0x0040
	ld	xbc, 0x10C000                       ; FB7159  ld XBC,0x0010c000
	ld	(xiz-4), xbc                        ; FB715E  ld (XIZ+0xfc),XBC
	ld	(xbc), de                           ; FB7161  ld (XBC),DE
	ld	de, (xix+2)                         ; FB7163  ld DE,(XIX+0x02)
	ld	xbc, (xiz-4)                        ; FB7166  ld XBC,(XIZ+0xfc)
	inc	2, xbc                             ; FB7169  inc 2,XBC
	ld	(xiz-8), xbc                        ; FB716B  ld (XIZ+0xf8),XBC
	ld	(xbc), de                           ; FB716E  ld (XBC),DE
	ld	de, hl                              ; FB7170  ld DE,HL
	add	de, 0x80                           ; FB7172  add DE,0x0080
	ld	xbc, (xiz-4)                        ; FB7176  ld XBC,(XIZ+0xfc)
	ld	(xbc), de                           ; FB7179  ld (XBC),DE
	ld	bc, (xix+4)                         ; FB717B  ld BC,(XIX+0x04)
	set	15, bc                             ; FB717E  set 0x0f,BC
	ld	xwa, (xiz-8)                        ; FB7181  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB7184  ld (XWA),BC
	ld	bc, hl                              ; FB7186  ld BC,HL
	add	bc, 0xC0                           ; FB7188  add BC,0x00c0
	ld	xwa, (xiz-4)                        ; FB718C  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB718F  ld (XWA),BC
	ld	bc, (xix+6)                         ; FB7191  ld BC,(XIX+0x06)
	ld	xwa, (xiz-8)                        ; FB7194  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB7197  ld (XWA),BC
	ld	bc, hl                              ; FB7199  ld BC,HL
	add	bc, 0x100                          ; FB719B  add BC,0x0100
	ld	xwa, (xiz-4)                        ; FB719F  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB71A2  ld (XWA),BC
	ld	bc, (xix+8)                         ; FB71A4  ld BC,(XIX+0x08)
	ld	xwa, (xiz-8)                        ; FB71A7  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB71AA  ld (XWA),BC
	ld	bc, hl                              ; FB71AC  ld BC,HL
	add	bc, 0x140                          ; FB71AE  add BC,0x0140
	ld	xwa, (xiz-4)                        ; FB71B2  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB71B5  ld (XWA),BC
	ld	bc, (xix+10)                        ; FB71B7  ld BC,(XIX+0x0a)
	ld	xwa, (xiz-8)                        ; FB71BA  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB71BD  ld (XWA),BC
	ld	bc, hl                              ; FB71BF  ld BC,HL
	add	bc, 0x180                          ; FB71C1  add BC,0x0180
	ld	xwa, (xiz-4)                        ; FB71C5  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB71C8  ld (XWA),BC
	ld	bc, (xix+12)                        ; FB71CA  ld BC,(XIX+0x0c)
	ld	xwa, (xiz-8)                        ; FB71CD  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB71D0  ld (XWA),BC
	ld	bc, hl                              ; FB71D2  ld BC,HL
	add	bc, 0x400                          ; FB71D4  add BC,0x0400
	ld	xwa, (xiz-4)                        ; FB71D8  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB71DB  ld (XWA),BC
	ld	bc, (xix+14)                        ; FB71DD  ld BC,(XIX+0x0e)
	ld	xwa, (xiz-8)                        ; FB71E0  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB71E3  ld (XWA),BC
	ld	bc, hl                              ; FB71E5  ld BC,HL
	add	bc, 0x440                          ; FB71E7  add BC,0x0440
	ld	xwa, (xiz-4)                        ; FB71EB  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB71EE  ld (XWA),BC
	ld	bc, (xix+16)                        ; FB71F0  ld BC,(XIX+0x10)
	ld	xwa, (xiz-8)                        ; FB71F3  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB71F6  ld (XWA),BC
	ld	bc, hl                              ; FB71F8  ld BC,HL
	add	bc, 0x480                          ; FB71FA  add BC,0x0480
	ld	xwa, (xiz-4)                        ; FB71FE  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB7201  ld (XWA),BC
	ld	bc, (xix+18)                        ; FB7203  ld BC,(XIX+0x12)
	ld	xwa, (xiz-8)                        ; FB7206  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB7209  ld (XWA),BC
	ld	bc, hl                              ; FB720B  ld BC,HL
	add	bc, 0x4C0                          ; FB720D  add BC,0x04c0
	ld	xwa, (xiz-4)                        ; FB7211  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB7214  ld (XWA),BC
	ld	bc, (xix+20)                        ; FB7216  ld BC,(XIX+0x14)
	ld	xwa, (xiz-8)                        ; FB7219  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB721C  ld (XWA),BC
	ld	bc, hl                              ; FB721E  ld BC,HL
	add	bc, 0x800                          ; FB7220  add BC,0x0800
	ld	xwa, (xiz-4)                        ; FB7224  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB7227  ld (XWA),BC
	ld	bc, (xix+24)                        ; FB7229  ld BC,(XIX+0x18)
	ld	xwa, (xiz-8)                        ; FB722C  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB722F  ld (XWA),BC
	ld	xbc, (xiz-4)                        ; FB7231  ld XBC,(XIZ+0xfc)
	ld	(xbc), hl                           ; FB7234  ld (XBC),HL
	ld	xbc, (xiz-8)                        ; FB7236  ld XBC,(XIZ+0xf8)
	extpfx4 0xB1, 0x02, 0x00, 0x81         ; FB7239  ld (XBC),0x8100   [llvm-mc cannot encode this]
	ld	bc, hl                              ; FB723D  ld BC,HL
	add	bc, 0x840                          ; FB723F  add BC,0x0840
	ld	xwa, (xiz-4)                        ; FB7243  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB7246  ld (XWA),BC
	ld	bc, (xix+26)                        ; FB7248  ld BC,(XIX+0x1a)
	ld	xwa, (xiz-8)                        ; FB724B  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB724E  ld (XWA),BC
	ld	bc, hl                              ; FB7250  ld BC,HL
	add	bc, 0x880                          ; FB7252  add BC,0x0880
	ld	xwa, (xiz-4)                        ; FB7256  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB7259  ld (XWA),BC
	ld	bc, (xix+28)                        ; FB725B  ld BC,(XIX+0x1c)
	ld	xwa, (xiz-8)                        ; FB725E  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB7261  ld (XWA),BC
	ld	bc, hl                              ; FB7263  ld BC,HL
	add	bc, 0x9C0                          ; FB7265  add BC,0x09c0
	ld	xwa, (xiz-4)                        ; FB7269  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB726C  ld (XWA),BC
	ld	bc, (xix+38)                        ; FB726E  ld BC,(XIX+0x26)
	ld	xwa, (xiz-8)                        ; FB7271  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB7274  ld (XWA),BC
	ld	bc, hl                              ; FB7276  ld BC,HL
	add	bc, 0xA00                          ; FB7278  add BC,0x0a00
	ld	xwa, (xiz-4)                        ; FB727C  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB727F  ld (XWA),BC
	ld	bc, (xix+40)                        ; FB7281  ld BC,(XIX+0x28)
	ld	xwa, (xiz-8)                        ; FB7284  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB7287  ld (XWA),BC
	ld	bc, hl                              ; FB7289  ld BC,HL
	add	bc, 0xA40                          ; FB728B  add BC,0x0a40
	ld	xwa, (xiz-4)                        ; FB728F  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB7292  ld (XWA),BC
	ld	bc, (xix+42)                        ; FB7294  ld BC,(XIX+0x2a)
	ld	xwa, (xiz-8)                        ; FB7297  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB729A  ld (XWA),BC
	pushw	hl                               ; FB729C  push HL
	calr (0xFB6EDC - 0xFB72A0)             ; FB729D  calr 0xfb6edc
	ld	bc, hl                              ; FB72A0  ld BC,HL
	add	bc, 0x8C0                          ; FB72A2  add BC,0x08c0
	ld	xwa, (xiz-4)                        ; FB72A6  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB72A9  ld (XWA),BC
	ld	bc, (xix+30)                        ; FB72AB  ld BC,(XIX+0x1e)
	ld	xwa, (xiz-8)                        ; FB72AE  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB72B1  ld (XWA),BC
	ld	bc, hl                              ; FB72B3  ld BC,HL
	add	bc, 0x500                          ; FB72B5  add BC,0x0500
	ld	xwa, (xiz-4)                        ; FB72B9  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB72BC  ld (XWA),BC
	ld	bc, (xix+22)                        ; FB72BE  ld BC,(XIX+0x16)
	ld	xwa, (xiz-8)                        ; FB72C1  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB72C4  ld (XWA),BC
	ld	bc, hl                              ; FB72C6  ld BC,HL
	add	bc, 0x900                          ; FB72C8  add BC,0x0900
	ld	xwa, (xiz-4)                        ; FB72CC  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB72CF  ld (XWA),BC
	ld	bc, (xix+32)                        ; FB72D1  ld BC,(XIX+0x20)
	ld	xwa, (xiz-8)                        ; FB72D4  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB72D7  ld (XWA),BC
	ld	bc, hl                              ; FB72D9  ld BC,HL
	add	bc, 0x940                          ; FB72DB  add BC,0x0940
	ld	xwa, (xiz-4)                        ; FB72DF  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB72E2  ld (XWA),BC
	ld	bc, (xix+34)                        ; FB72E4  ld BC,(XIX+0x22)
	ld	xwa, (xiz-8)                        ; FB72E7  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB72EA  ld (XWA),BC
	ld	bc, hl                              ; FB72EC  ld BC,HL
	add	bc, 0x980                          ; FB72EE  add BC,0x0980
	ld	xwa, (xiz-4)                        ; FB72F2  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FB72F5  ld (XWA),BC
	ld	bc, (xix+36)                        ; FB72F7  ld BC,(XIX+0x24)
	ld	xwa, (xiz-8)                        ; FB72FA  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB72FD  ld (XWA),BC
	ld	xbc, (xiz-4)                        ; FB72FF  ld XBC,(XIZ+0xfc)
	ld	(xbc), de                           ; FB7302  ld (XBC),DE
	ld	bc, (xix+4)                         ; FB7304  ld BC,(XIX+0x04)
	res	15, bc                             ; FB7307  res 0x0f,BC
	ld	xwa, (xiz-8)                        ; FB730A  ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                           ; FB730D  ld (XWA),BC
	ld	bc, (xix+4)                         ; FB730F  ld BC,(XIX+0x04)
	ld	de, bc                              ; FB7312  ld DE,BC
	res	15, de                             ; FB7314  res 0x0f,DE
	ldw	bc, 2                              ; FB7317  ld BC,0x0002
	mul	xbc, xhl                           ; FB731A  mul XBC,HL
	add	xbc, 0xD85B                        ; FB731C  add XBC,0x0000d85b
	ld	(xbc), de                           ; FB7322  ld (XBC),DE
	inc	8, xsp                             ; FB7324  inc 0,XSP
	pop	xix                                ; FB7326  pop XIX
	popw	de                                ; FB7327  pop DE
	popw	hl                                ; FB7328  pop HL
	unlk32 xiz                             ; FB7329  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB732B  ret

; --------------------------------------------------------------------------
; Dev10C_WriteReg_c -- register (arg0) = arg1.  The bare address/data pair.
;
; Called from: NINE `call` sites (0xFAC054, 0xFAC413, 0xFB371D, 0xFB382A,
;          0xFB39AD, 0xFB3AB8, 0xFB3BD1, 0xFB3D87, 0xFC3F27) and the `calr` at
;          0xFB81AE inside Dev10C_ResetAllChannels.
; Inputs:  (XIZ+0x08) = the 16-bit register number, (XIZ+0x0a) = its value.
; Evidence: ★ BYTE-IDENTICAL, all 25 bytes, to Dev10C_WriteReg at 0xFACE89 above
;          (`notes/prom_c_tg_regmap.py --dups`).  It is the routine that fixes the
;          port's shape: no arithmetic between the arguments and the port.
; Unknown:  nothing about the routine.
; --------------------------------------------------------------------------
Dev10C_WriteReg_c:
	link32 0xEE, 0x0C, 0x00, 0x00          ; FB732C  link XIZ,0x0000   [llvm-mc cannot encode this]
	push	xix                               ; FB7330  push XIX
	ld	xix, 0x10C000                       ; FB7331  ld XIX,0x0010c000
	ld	bc, (xiz+8)                         ; FB7336  ld BC,(XIZ+0x08)
	ld	(xix), bc                           ; FB7339  ld (XIX),BC
	ld	bc, (xiz+10)                        ; FB733B  ld BC,(XIZ+0x0a)
	ld	(xix+2), bc                         ; FB733E  ld (XIX+0x02),BC
	pop	xix                                ; FB7341  pop XIX
	unlk32 xiz                             ; FB7342  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FB7344  ret

; ==============================================================================
; 0xFB7345-0xFB7714 -- not yet converted
; ==============================================================================
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x037345, 0x0003D0

; ==============================================================================
; 0xFB7715-0xFB7B62 -- the driver for the SECOND register device, 0x00104000,
;                      and the tone generator's thirteen GLOBAL registers
;                      9 routines, 1,102 bytes
; ==============================================================================
;
; This block sits immediately below the second tone-generator driver and is part
; of the same module.  It settles two things the memory map could only gesture at.
;
; ★ 0x00104000 IS AN ADDRESS/DATA PAIR OF THE SAME KIND AS 0x0010C000, WITH THE
; SAME `block * 0x40 + channel` REGISTER MAP.  Dev104_WriteAllChanRegs below writes
; nineteen registers of one channel in one unrolled run, blocks 0x0000 through
; 0x0480 in 0x40 steps, taking the value for block k*0x40 from word 2*k of a
; struct.  Nothing is inferred: the run is exhaustive and the field offset is a
; linear function of the block index, checked over all nineteen by
; `python3 notes/prom_c_tg_regmap.py --dev104` (which tests the LAST pair, not
; only the first).  prom_c loads the literal 0x00104000 into a pointer register
; nine times and every one of them is in this block or in Dev10C_ResetAllChannels.
;
; ★ THE TONE GENERATOR HAS GLOBAL REGISTERS, AND THERE ARE THIRTEEN OF THEM.
; Dev10C_WriteGlobalRegs takes no channel argument at all -- every register number in
; it is an immediate -- and writes 0x0200-0x0205, 0x0C00-0x0C05 and 0x0E00 from
; thirteen consecutive words.  Its argument is therefore 26 bytes, which is
; exactly the gap between the two ROM addresses Dev10C_ResetAllChannels hands out
; (0xFE12B5 and 0xFE12CF).  The register-number ARITHMETIC also agrees with the
; other bank: Dev10C_WriteReg_0201 at 0xFAD12A writes 0x0201 on its own.
;
; ⚠ TWO ROUTINES HERE HAVE NO CALLER: 0xFB796E and 0xFB79D0 are reached by no
; absolute `call` and no `calr` in prom_c.  Same caveat as always -- a call
; through a register operand would not be found.
;
; ⚠ NOTHING HERE SAYS WHAT ANY REGISTER DOES, and no name below claims one.  The
; names encode the register block and the struct field, both read off the
; instructions.
;
; Transcribed the same way as the block below it:
; `notes/llvm_roundtrip_force.py c 0xFB7715 0x44E` proved the listing rebuilds
; these bytes, and the 31 instructions it left as `.byte` were each replaced with
; a mnemonic re-encoded by `llvm-mc --show-encoding` and accepted only on an exact
; byte match.  No `.byte` and no `extpfx` remains in this block.

; --------------------------------------------------------------------------
; ★★ Dev10C_WriteGlobalRegs -- the THIRTEEN GLOBAL registers of the 0x0010C000 device,
; written from thirteen consecutive words of one struct.
;
;     register 0x0200 0x0201 0x0202 0x0203 0x0204 0x0205  <- arg0->0x00 .. 0x0A
;     register 0x0C00 0x0C01 0x0C02 0x0C03 0x0C04 0x0C05  <- arg0->0x0C .. 0x16
;     register 0x0E00                                     <- arg0->0x18
;
; Called from: 0xFB80EE, inside Dev10C_ResetAllChannels, which passes ROM 0xFE12B5.
; Inputs:  (XIZ+8) = a pointer to 13 words.  ★ THERE IS NO CHANNEL ARGUMENT and
;          no `add` anywhere in the routine -- every register number is an
;          immediate.  That is what makes these registers GLOBAL rather than
;          per-channel, and it is read off the instruction, not assumed.
; Outputs: 13 16-bit writes.
; Evidence: thirteen `ldw (xbc),0xNNNN` immediates, each followed by a fetch from
;          (XIX + 2k) and a store through the +2 pointer held in the frame.
; ★ THE ARGUMENT'S SIZE CHECKS OUT AGAINST THE ROM.  13 words = 26 = 0x1A bytes,
;   and Dev10C_ResetAllChannels passes 0xFE12B5 while the NEXT ROM block it uses
;   starts at 0xFE12CF.  0xFE12CF - 0xFE12B5 = 0x1A exactly.  Two independent
;   facts -- this routine's field count and the spacing of two ROM addresses in
;   another routine -- give the same size.
; ★ AND IT AGREES WITH THE OTHER BANK.  Dev10C_WriteReg_0201 at 0xFAD12A writes
;   register 0x0201 alone, with a value the caller builds by masking with 0x0F9F.
;   0x0201 is the second of the six registers here, so both banks agree that
;   0x0200-0x0205 is one six-register control block.
; Unknown:  what any of the thirteen do.
; --------------------------------------------------------------------------
Dev10C_WriteGlobalRegs:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB7715  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB7719  2b                push HL
	push	xix                                   ; FB771A  3c                push XIX
	ld	xix, (xiz+8)                            ; FB771B  ae 08 24          ld XIX,(XIZ+0x08)
	ld	xbc, 0x0010C000                         ; FB771E  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7723  be fc 61          ld (XIZ+0xfc),XBC
	ldw (xbc), 0x0200                          ; FB7726  b1 02 00 02       ld (XBC),0x0200
	ld	hl, (xix)                               ; FB772A  94 23             ld HL,(XIX)
	ld	xbc, (xiz-4)                            ; FB772C  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB772F  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB7731  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), hl                               ; FB7734  b1 53             ld (XBC),HL
	ld	xbc, (xiz-4)                            ; FB7736  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0201                          ; FB7739  b1 02 01 02       ld (XBC),0x0201
	ld	bc, (xix+2)                             ; FB773D  9c 02 21          ld BC,(XIX+0x02)
	ld	xwa, (xiz-8)                            ; FB7740  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7743  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB7745  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0202                          ; FB7748  b1 02 02 02       ld (XBC),0x0202
	ld	bc, (xix+4)                             ; FB774C  9c 04 21          ld BC,(XIX+0x04)
	ld	xwa, (xiz-8)                            ; FB774F  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7752  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB7754  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0203                          ; FB7757  b1 02 03 02       ld (XBC),0x0203
	ld	bc, (xix+6)                             ; FB775B  9c 06 21          ld BC,(XIX+0x06)
	ld	xwa, (xiz-8)                            ; FB775E  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7761  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB7763  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0204                          ; FB7766  b1 02 04 02       ld (XBC),0x0204
	ld	bc, (xix+8)                             ; FB776A  9c 08 21          ld BC,(XIX+0x08)
	ld	xwa, (xiz-8)                            ; FB776D  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7770  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB7772  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0205                          ; FB7775  b1 02 05 02       ld (XBC),0x0205
	ld	bc, (xix+10)                            ; FB7779  9c 0a 21          ld BC,(XIX+0x0a)
	ld	xwa, (xiz-8)                            ; FB777C  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB777F  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB7781  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0C00                          ; FB7784  b1 02 00 0c       ld (XBC),0x0c00
	ld	bc, (xix+12)                            ; FB7788  9c 0c 21          ld BC,(XIX+0x0c)
	ld	xwa, (xiz-8)                            ; FB778B  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB778E  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB7790  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0C01                          ; FB7793  b1 02 01 0c       ld (XBC),0x0c01
	ld	bc, (xix+14)                            ; FB7797  9c 0e 21          ld BC,(XIX+0x0e)
	ld	xwa, (xiz-8)                            ; FB779A  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB779D  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB779F  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0C02                          ; FB77A2  b1 02 02 0c       ld (XBC),0x0c02
	ld	bc, (xix+16)                            ; FB77A6  9c 10 21          ld BC,(XIX+0x10)
	ld	xwa, (xiz-8)                            ; FB77A9  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB77AC  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB77AE  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0C03                          ; FB77B1  b1 02 03 0c       ld (XBC),0x0c03
	ld	bc, (xix+18)                            ; FB77B5  9c 12 21          ld BC,(XIX+0x12)
	ld	xwa, (xiz-8)                            ; FB77B8  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB77BB  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB77BD  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0C04                          ; FB77C0  b1 02 04 0c       ld (XBC),0x0c04
	ld	bc, (xix+20)                            ; FB77C4  9c 14 21          ld BC,(XIX+0x14)
	ld	xwa, (xiz-8)                            ; FB77C7  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB77CA  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB77CC  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0C05                          ; FB77CF  b1 02 05 0c       ld (XBC),0x0c05
	ld	bc, (xix+22)                            ; FB77D3  9c 16 21          ld BC,(XIX+0x16)
	ld	xwa, (xiz-8)                            ; FB77D6  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB77D9  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB77DB  ae fc 21          ld XBC,(XIZ+0xfc)
	ldw (xbc), 0x0E00                          ; FB77DE  b1 02 00 0e       ld (XBC),0x0e00
	ld	bc, (xix+24)                            ; FB77E2  9c 18 21          ld BC,(XIX+0x18)
	ld	xwa, (xiz-8)                            ; FB77E5  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB77E8  b0 51             ld (XWA),BC
	pop	xix                                    ; FB77EA  5c                pop XIX
	popw	hl                                    ; FB77EB  4b                pop HL
	unlk32 xiz                                 ; FB77EC  ee 0d             unlk XIZ
	ret                                        ; FB77EE  0e                ret
; --------------------------------------------------------------------------
; ★★ Dev104_WriteAllChanRegs -- the COMPLETE per-channel register map of the SECOND
; device, 0x00104000, in one unrolled routine.
;
;     register (chan + k*0x40) = arg1->(2*k)      for k = 1,2,3 ... 0x12
;     register (chan + 0)      = arg1->0x00       written LAST
;
; so nineteen 16-bit registers per channel, fed from nineteen consecutive words
; of the staging struct, with the field offset exactly twice the block index.
; The mapping is not eyeballed: `python3 notes/prom_c_tg_regmap.py --dev104`
; re-derives it from the ROM and checks the LAST pair (0x0480 <- 0x24) as well as
; the first, then asserts field == 2 * (base / 0x40) for every one of the 19.
;
; ★ 0x00104000 THEREFORE HAS THE SAME SHAPE AS 0x0010C000: a 16-bit register
; number at +0x00, that register's 16-bit value at +0x02, and register numbers of
; the form `parameter_block * 0x40 + channel`.  notes/FINDINGS-memory-map.md had
; the address/data pair for this device from a single site; this is the whole map.
;
; Called from: 0xFAC3EC, 0xFB0B71, 0xFB1F51, 0xFB2876, 0xFB2F4B, 0xFB3708,
;              0xFB3815, 0xFC3ECD and 0xFB81A4 (in Dev10C_ResetAllChannels).
; Inputs:  (XIZ+8) = chan, (XIZ+10) = struct pointer (kept in XIX).
; Unknown:  what any of the nineteen parameters is.  Note that block 0 is written
;           LAST, after all the others -- the shape of a "commit" register, but
;           nothing here establishes that.
; --------------------------------------------------------------------------
Dev104_WriteAllChanRegs:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB77EF  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB77F3  2b                push HL
	pushw	de                                   ; FB77F4  2a                push DE
	push	xix                                   ; FB77F5  3c                push XIX
	ld	xix, (xiz+10)                           ; FB77F6  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB77F9  9e 08 23          ld HL,(XIZ+0x08)
	ld	de, hl                                  ; FB77FC  db 8a             ld DE,HL
	add	de, 64                                 ; FB77FE  da c8 40 00       add DE,0x0040
	ld	xbc, 0x00104000                         ; FB7802  41 00 40 10 00    ld XBC,0x00104000
	ld	(xiz-4), xbc                            ; FB7807  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB780A  b1 52             ld (XBC),DE
	ld	de, (xix+2)                             ; FB780C  9c 02 22          ld DE,(XIX+0x02)
	ld	xbc, (xiz-4)                            ; FB780F  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB7812  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB7814  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB7817  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB7819  db 89             ld BC,HL
	add	bc, 128                                ; FB781B  d9 c8 80 00       add BC,0x0080
	ld	xwa, (xiz-4)                            ; FB781F  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7822  b0 51             ld (XWA),BC
	ld	bc, (xix+4)                             ; FB7824  9c 04 21          ld BC,(XIX+0x04)
	ld	xwa, (xiz-8)                            ; FB7827  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB782A  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB782C  db 89             ld BC,HL
	add	bc, 192                                ; FB782E  d9 c8 c0 00       add BC,0x00c0
	ld	xwa, (xiz-4)                            ; FB7832  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7835  b0 51             ld (XWA),BC
	ld	bc, (xix+6)                             ; FB7837  9c 06 21          ld BC,(XIX+0x06)
	ld	xwa, (xiz-8)                            ; FB783A  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB783D  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB783F  db 89             ld BC,HL
	add	bc, 0x0100                             ; FB7841  d9 c8 00 01       add BC,0x0100
	ld	xwa, (xiz-4)                            ; FB7845  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7848  b0 51             ld (XWA),BC
	ld	bc, (xix+8)                             ; FB784A  9c 08 21          ld BC,(XIX+0x08)
	ld	xwa, (xiz-8)                            ; FB784D  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7850  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7852  db 89             ld BC,HL
	add	bc, 0x0140                             ; FB7854  d9 c8 40 01       add BC,0x0140
	ld	xwa, (xiz-4)                            ; FB7858  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB785B  b0 51             ld (XWA),BC
	ld	bc, (xix+10)                            ; FB785D  9c 0a 21          ld BC,(XIX+0x0a)
	ld	xwa, (xiz-8)                            ; FB7860  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7863  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7865  db 89             ld BC,HL
	add	bc, 0x0180                             ; FB7867  d9 c8 80 01       add BC,0x0180
	ld	xwa, (xiz-4)                            ; FB786B  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB786E  b0 51             ld (XWA),BC
	ld	bc, (xix+12)                            ; FB7870  9c 0c 21          ld BC,(XIX+0x0c)
	ld	xwa, (xiz-8)                            ; FB7873  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7876  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7878  db 89             ld BC,HL
	add	bc, 0x01C0                             ; FB787A  d9 c8 c0 01       add BC,0x01c0
	ld	xwa, (xiz-4)                            ; FB787E  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7881  b0 51             ld (XWA),BC
	ld	bc, (xix+14)                            ; FB7883  9c 0e 21          ld BC,(XIX+0x0e)
	ld	xwa, (xiz-8)                            ; FB7886  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7889  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB788B  db 89             ld BC,HL
	add	bc, 0x0200                             ; FB788D  d9 c8 00 02       add BC,0x0200
	ld	xwa, (xiz-4)                            ; FB7891  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7894  b0 51             ld (XWA),BC
	ld	bc, (xix+16)                            ; FB7896  9c 10 21          ld BC,(XIX+0x10)
	ld	xwa, (xiz-8)                            ; FB7899  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB789C  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB789E  db 89             ld BC,HL
	add	bc, 0x0240                             ; FB78A0  d9 c8 40 02       add BC,0x0240
	ld	xwa, (xiz-4)                            ; FB78A4  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB78A7  b0 51             ld (XWA),BC
	ld	bc, (xix+18)                            ; FB78A9  9c 12 21          ld BC,(XIX+0x12)
	ld	xwa, (xiz-8)                            ; FB78AC  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB78AF  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB78B1  db 89             ld BC,HL
	add	bc, 0x0280                             ; FB78B3  d9 c8 80 02       add BC,0x0280
	ld	xwa, (xiz-4)                            ; FB78B7  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB78BA  b0 51             ld (XWA),BC
	ld	bc, (xix+20)                            ; FB78BC  9c 14 21          ld BC,(XIX+0x14)
	ld	xwa, (xiz-8)                            ; FB78BF  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB78C2  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB78C4  db 89             ld BC,HL
	add	bc, 0x02C0                             ; FB78C6  d9 c8 c0 02       add BC,0x02c0
	ld	xwa, (xiz-4)                            ; FB78CA  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB78CD  b0 51             ld (XWA),BC
	ld	bc, (xix+22)                            ; FB78CF  9c 16 21          ld BC,(XIX+0x16)
	ld	xwa, (xiz-8)                            ; FB78D2  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB78D5  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB78D7  db 89             ld BC,HL
	add	bc, 0x0300                             ; FB78D9  d9 c8 00 03       add BC,0x0300
	ld	xwa, (xiz-4)                            ; FB78DD  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB78E0  b0 51             ld (XWA),BC
	ld	bc, (xix+24)                            ; FB78E2  9c 18 21          ld BC,(XIX+0x18)
	ld	xwa, (xiz-8)                            ; FB78E5  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB78E8  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB78EA  db 89             ld BC,HL
	add	bc, 0x0340                             ; FB78EC  d9 c8 40 03       add BC,0x0340
	ld	xwa, (xiz-4)                            ; FB78F0  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB78F3  b0 51             ld (XWA),BC
	ld	bc, (xix+26)                            ; FB78F5  9c 1a 21          ld BC,(XIX+0x1a)
	ld	xwa, (xiz-8)                            ; FB78F8  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB78FB  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB78FD  db 89             ld BC,HL
	add	bc, 0x0380                             ; FB78FF  d9 c8 80 03       add BC,0x0380
	ld	xwa, (xiz-4)                            ; FB7903  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7906  b0 51             ld (XWA),BC
	ld	bc, (xix+28)                            ; FB7908  9c 1c 21          ld BC,(XIX+0x1c)
	ld	xwa, (xiz-8)                            ; FB790B  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB790E  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7910  db 89             ld BC,HL
	add	bc, 0x03C0                             ; FB7912  d9 c8 c0 03       add BC,0x03c0
	ld	xwa, (xiz-4)                            ; FB7916  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7919  b0 51             ld (XWA),BC
	ld	bc, (xix+30)                            ; FB791B  9c 1e 21          ld BC,(XIX+0x1e)
	ld	xwa, (xiz-8)                            ; FB791E  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7921  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7923  db 89             ld BC,HL
	add	bc, 0x0400                             ; FB7925  d9 c8 00 04       add BC,0x0400
	ld	xwa, (xiz-4)                            ; FB7929  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB792C  b0 51             ld (XWA),BC
	ld	bc, (xix+32)                            ; FB792E  9c 20 21          ld BC,(XIX+0x20)
	ld	xwa, (xiz-8)                            ; FB7931  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7934  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7936  db 89             ld BC,HL
	add	bc, 0x0440                             ; FB7938  d9 c8 40 04       add BC,0x0440
	ld	xwa, (xiz-4)                            ; FB793C  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB793F  b0 51             ld (XWA),BC
	ld	bc, (xix+34)                            ; FB7941  9c 22 21          ld BC,(XIX+0x22)
	ld	xwa, (xiz-8)                            ; FB7944  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7947  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7949  db 89             ld BC,HL
	add	bc, 0x0480                             ; FB794B  d9 c8 80 04       add BC,0x0480
	ld	xwa, (xiz-4)                            ; FB794F  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7952  b0 51             ld (XWA),BC
	ld	bc, (xix+36)                            ; FB7954  9c 24 21          ld BC,(XIX+0x24)
	ld	xwa, (xiz-8)                            ; FB7957  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB795A  b0 51             ld (XWA),BC
	ld	xbc, (xiz-4)                            ; FB795C  ae fc 21          ld XBC,(XIZ+0xfc)
	ld	(xbc), hl                               ; FB795F  b1 53             ld (XBC),HL
	ld	bc, (xix)                               ; FB7961  94 21             ld BC,(XIX)
	ld	xwa, (xiz-8)                            ; FB7963  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7966  b0 51             ld (XWA),BC
	pop	xix                                    ; FB7968  5c                pop XIX
	popw	de                                    ; FB7969  4a                pop DE
	popw	hl                                    ; FB796A  4b                pop HL
	unlk32 xiz                                 ; FB796B  ee 0d             unlk XIZ
	ret                                        ; FB796D  0e                ret
; --------------------------------------------------------------------------
; Dev104_SetChanRegs_01C0_0200_0240 -- register (chan+0) from struct field 0x00
; FIRST, then (chan+0x01C0), (chan+0x0200), (chan+0x0240) from fields 0x0E, 0x10,
; 0x12.
; ⚠ CORRECTION, ROUND 4.  This header used to end "... then register (chan+0) from
; field 0x00 last -- the same trailing write Dev104_WriteAllChanRegs ends with".
; The (chan+0) write is FIRST here, at 0xFB7983, before any of the other three.
; It IS last in Dev104_WriteAllChanRegs (0xFB795F, its final write), so the
; comparison was backwards, not merely mis-ordered.
; Called from: NOT FOUND (no absolute `call`, no `calr`; notes/prom_c_xrefs.py).
; Evidence: `python3 notes/prom_c_tg_chanmap.py 0xFB796E 0x62 --dev 0x00104000
;          --pairs` walks the routine and prints the four writes in EXECUTION
;          order: 0xFB7983 chan+0 <- field 0x00, 0xFB799A chan+0x01C0 <- 0x0E,
;          0xFB79AD chan+0x0200 <- 0x10, 0xFB79C0 chan+0x0240 <- 0x12.
; --------------------------------------------------------------------------
Dev104_SetChanRegs_01C0_0200_0240:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB796E  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB7972  2b                push HL
	pushw	de                                   ; FB7973  2a                push DE
	push	xix                                   ; FB7974  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7975  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB7978  9e 08 23          ld HL,(XIZ+0x08)
	ld	xbc, 0x00104000                         ; FB797B  41 00 40 10 00    ld XBC,0x00104000
	ld	(xiz-4), xbc                            ; FB7980  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), hl                               ; FB7983  b1 53             ld (XBC),HL
	ld	de, (xix)                               ; FB7985  94 22             ld DE,(XIX)
	ld	xbc, (xiz-4)                            ; FB7987  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB798A  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB798C  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB798F  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB7991  db 89             ld BC,HL
	add	bc, 0x01C0                             ; FB7993  d9 c8 c0 01       add BC,0x01c0
	ld	xwa, (xiz-4)                            ; FB7997  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB799A  b0 51             ld (XWA),BC
	ld	bc, (xix+14)                            ; FB799C  9c 0e 21          ld BC,(XIX+0x0e)
	ld	xwa, (xiz-8)                            ; FB799F  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB79A2  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB79A4  db 89             ld BC,HL
	add	bc, 0x0200                             ; FB79A6  d9 c8 00 02       add BC,0x0200
	ld	xwa, (xiz-4)                            ; FB79AA  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB79AD  b0 51             ld (XWA),BC
	ld	bc, (xix+16)                            ; FB79AF  9c 10 21          ld BC,(XIX+0x10)
	ld	xwa, (xiz-8)                            ; FB79B2  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB79B5  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB79B7  db 89             ld BC,HL
	add	bc, 0x0240                             ; FB79B9  d9 c8 40 02       add BC,0x0240
	ld	xwa, (xiz-4)                            ; FB79BD  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB79C0  b0 51             ld (XWA),BC
	ld	bc, (xix+18)                            ; FB79C2  9c 12 21          ld BC,(XIX+0x12)
	ld	xwa, (xiz-8)                            ; FB79C5  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB79C8  b0 51             ld (XWA),BC
	pop	xix                                    ; FB79CA  5c                pop XIX
	popw	de                                    ; FB79CB  4a                pop DE
	popw	hl                                    ; FB79CC  4b                pop HL
	unlk32 xiz                                 ; FB79CD  ee 0d             unlk XIZ
	ret                                        ; FB79CF  0e                ret
; --------------------------------------------------------------------------
; Dev104_SetChanRegs_0140_to_0240 -- register (chan+0) from struct field 0x00
; FIRST, then (chan+0x0140), (chan+0x0180), (chan+0x01C0), (chan+0x0200),
; (chan+0x0240) from fields 0x0A, 0x0C, 0x0E, 0x10, 0x12.
; ⚠ CORRECTION, ROUND 4: this header used to say the (chan+0) write came LAST.
; It is the FIRST of the six, at 0xFB79E5.  Same defect as the header above.
; Called from: NOT FOUND -- `notes/prom_c_xrefs.py 0xFB79D0 --no-window` finds no
;          literal and no calr; short PC-relative forms are not searched.
; Evidence: `ld XBC,0x00104000` at 0xFB79DD is the device, and each register is the
;          select/data pair this bank's block comment establishes, with the
;          register number formed by `add BC,<K>` on the channel argument.  The
;          order and the field numbers are read off the ROM, not off this header:
;          `python3 notes/prom_c_tg_chanmap.py 0xFB79D0 0x88 --dev 0x00104000
;          --pairs` walks the routine and prints, in EXECUTION order,
;            0xFB79E5 chan+0      <- field 0x00     0xFB7A22 chan+0x01C0 <- 0x0E
;            0xFB79FC chan+0x0140 <- field 0x0A     0xFB7A35 chan+0x0200 <- 0x10
;            0xFB7A0F chan+0x0180 <- field 0x0C     0xFB7A48 chan+0x0240 <- 0x12
;          ⚠ 0x88 is the routine's real length (0xFB79D0-0xFB7A57); an earlier
;          draft of this line passed 0x66 and therefore saw only four of the six
;          writes.  Always pass the length to the `ret`.
; --------------------------------------------------------------------------
Dev104_SetChanRegs_0140_to_0240:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB79D0  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB79D4  2b                push HL
	pushw	de                                   ; FB79D5  2a                push DE
	push	xix                                   ; FB79D6  3c                push XIX
	ld	xix, (xiz+10)                           ; FB79D7  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB79DA  9e 08 23          ld HL,(XIZ+0x08)
	ld	xbc, 0x00104000                         ; FB79DD  41 00 40 10 00    ld XBC,0x00104000
	ld	(xiz-4), xbc                            ; FB79E2  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), hl                               ; FB79E5  b1 53             ld (XBC),HL
	ld	de, (xix)                               ; FB79E7  94 22             ld DE,(XIX)
	ld	xbc, (xiz-4)                            ; FB79E9  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB79EC  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB79EE  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB79F1  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB79F3  db 89             ld BC,HL
	add	bc, 0x0140                             ; FB79F5  d9 c8 40 01       add BC,0x0140
	ld	xwa, (xiz-4)                            ; FB79F9  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB79FC  b0 51             ld (XWA),BC
	ld	bc, (xix+10)                            ; FB79FE  9c 0a 21          ld BC,(XIX+0x0a)
	ld	xwa, (xiz-8)                            ; FB7A01  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7A04  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7A06  db 89             ld BC,HL
	add	bc, 0x0180                             ; FB7A08  d9 c8 80 01       add BC,0x0180
	ld	xwa, (xiz-4)                            ; FB7A0C  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7A0F  b0 51             ld (XWA),BC
	ld	bc, (xix+12)                            ; FB7A11  9c 0c 21          ld BC,(XIX+0x0c)
	ld	xwa, (xiz-8)                            ; FB7A14  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7A17  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7A19  db 89             ld BC,HL
	add	bc, 0x01C0                             ; FB7A1B  d9 c8 c0 01       add BC,0x01c0
	ld	xwa, (xiz-4)                            ; FB7A1F  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7A22  b0 51             ld (XWA),BC
	ld	bc, (xix+14)                            ; FB7A24  9c 0e 21          ld BC,(XIX+0x0e)
	ld	xwa, (xiz-8)                            ; FB7A27  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7A2A  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7A2C  db 89             ld BC,HL
	add	bc, 0x0200                             ; FB7A2E  d9 c8 00 02       add BC,0x0200
	ld	xwa, (xiz-4)                            ; FB7A32  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7A35  b0 51             ld (XWA),BC
	ld	bc, (xix+16)                            ; FB7A37  9c 10 21          ld BC,(XIX+0x10)
	ld	xwa, (xiz-8)                            ; FB7A3A  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7A3D  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7A3F  db 89             ld BC,HL
	add	bc, 0x0240                             ; FB7A41  d9 c8 40 02       add BC,0x0240
	ld	xwa, (xiz-4)                            ; FB7A45  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7A48  b0 51             ld (XWA),BC
	ld	bc, (xix+18)                            ; FB7A4A  9c 12 21          ld BC,(XIX+0x12)
	ld	xwa, (xiz-8)                            ; FB7A4D  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7A50  b0 51             ld (XWA),BC
	pop	xix                                    ; FB7A52  5c                pop XIX
	popw	de                                    ; FB7A53  4a                pop DE
	popw	hl                                    ; FB7A54  4b                pop HL
	unlk32 xiz                                 ; FB7A55  ee 0d             unlk XIZ
	ret                                        ; FB7A57  0e                ret
; --------------------------------------------------------------------------
; Dev104_WriteChanReg0 -- register (chan + 0) of 0x00104000 = the first word of the
; struct.  The smallest routine in the block, and the one that isolates the
; (chan+0) write on its own.
; ⚠ CORRECTION, ROUND 4: this header used to call that write "the trailing write
; the two routines above and Dev104_WriteAllChanRegs all end with".  Only
; Dev104_WriteAllChanRegs ends with it (0xFB795F).  In the two routines above it
; is the FIRST write, not the last -- measured with
; `notes/prom_c_tg_chanmap.py ... --pairs`, which reports execution order.
; Called from: 0xFAC3D7, 0xFB36FB, 0xFB3808, 0xFB3927, 0xFB3A72, 0xFB3B90,
;              0xFC3EA1 and 0xFB826B (in Dev10C_ResetAllChannels).
; Inputs:  (XIZ+8) = chan, (XIZ+10) = struct pointer.
; Evidence: `ld (xix),bc` with BC = the raw argument (no `add`), then
;          `ld wa,(xbc)` / `ld (xix+2),wa` -- field 0x00.
; --------------------------------------------------------------------------
Dev104_WriteChanReg0:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7A58  ee 0c 00 00       link XIZ,0x0000
	push	xix                                   ; FB7A5C  3c                push XIX
	ld	xix, 0x00104000                         ; FB7A5D  44 00 40 10 00    ld XIX,0x00104000
	ld	bc, (xiz+8)                             ; FB7A62  9e 08 21          ld BC,(XIZ+0x08)
	ld	(xix), bc                               ; FB7A65  b4 51             ld (XIX),BC
	ld	xbc, (xiz+10)                           ; FB7A67  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc)                               ; FB7A6A  91 20             ld WA,(XBC)
	ld	(xix+2), wa                             ; FB7A6C  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7A6F  5c                pop XIX
	unlk32 xiz                                 ; FB7A70  ee 0d             unlk XIZ
	ret                                        ; FB7A72  0e                ret
; --------------------------------------------------------------------------
; Dev104_SetChanRegs_00C0_0100_0240 -- registers (chan+0x00C0), (chan+0x0100),
; (chan+0x0240) from fields 0x06, 0x08, 0x12.
; Called from: 0xFACB85, 0xFAEB56, 0xFAEBC2.
; --------------------------------------------------------------------------
Dev104_SetChanRegs_00C0_0100_0240:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB7A73  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB7A77  2b                push HL
	pushw	de                                   ; FB7A78  2a                push DE
	push	xix                                   ; FB7A79  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7A7A  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB7A7D  9e 08 23          ld HL,(XIZ+0x08)
	ld	de, hl                                  ; FB7A80  db 8a             ld DE,HL
	add	de, 192                                ; FB7A82  da c8 c0 00       add DE,0x00c0
	ld	xbc, 0x00104000                         ; FB7A86  41 00 40 10 00    ld XBC,0x00104000
	ld	(xiz-4), xbc                            ; FB7A8B  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7A8E  b1 52             ld (XBC),DE
	ld	de, (xix+6)                             ; FB7A90  9c 06 22          ld DE,(XIX+0x06)
	ld	xbc, (xiz-4)                            ; FB7A93  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB7A96  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB7A98  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB7A9B  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB7A9D  db 89             ld BC,HL
	add	bc, 0x0100                             ; FB7A9F  d9 c8 00 01       add BC,0x0100
	ld	xwa, (xiz-4)                            ; FB7AA3  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7AA6  b0 51             ld (XWA),BC
	ld	bc, (xix+8)                             ; FB7AA8  9c 08 21          ld BC,(XIX+0x08)
	ld	xwa, (xiz-8)                            ; FB7AAB  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7AAE  b0 51             ld (XWA),BC
	ld	bc, hl                                  ; FB7AB0  db 89             ld BC,HL
	add	bc, 0x0240                             ; FB7AB2  d9 c8 40 02       add BC,0x0240
	ld	xwa, (xiz-4)                            ; FB7AB6  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7AB9  b0 51             ld (XWA),BC
	ld	bc, (xix+18)                            ; FB7ABB  9c 12 21          ld BC,(XIX+0x12)
	ld	xwa, (xiz-8)                            ; FB7ABE  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7AC1  b0 51             ld (XWA),BC
	pop	xix                                    ; FB7AC3  5c                pop XIX
	popw	de                                    ; FB7AC4  4a                pop DE
	popw	hl                                    ; FB7AC5  4b                pop HL
	unlk32 xiz                                 ; FB7AC6  ee 0d             unlk XIZ
	ret                                        ; FB7AC8  0e                ret
; --------------------------------------------------------------------------
; Dev104_SetChanRegs_00C0_0100 -- registers (chan+0x00C0), (chan+0x0100) from fields
; 0x06, 0x08.
; Called from: 0xFACB96.
; --------------------------------------------------------------------------
Dev104_SetChanRegs_00C0_0100:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB7AC9  ee 0c fc ff       link XIZ,0xfffc
	pushw	hl                                   ; FB7ACD  2b                push HL
	push	xix                                   ; FB7ACE  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7ACF  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 192                                ; FB7AD2  db c8 c0 00       add HL,0x00c0
	ld	xix, 0x00104000                         ; FB7AD6  44 00 40 10 00    ld XIX,0x00104000
	ld	(xix), hl                               ; FB7ADB  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7ADD  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	hl, (xbc+6)                             ; FB7AE0  99 06 23          ld HL,(XBC+0x06)
	ld	xwa, xix                                ; FB7AE3  ec 88             ld XWA,XIX
	inc	2, xwa                                 ; FB7AE5  e8 62             inc 2,XWA
	ld	(xiz-4), xwa                            ; FB7AE7  be fc 60          ld (XIZ+0xfc),XWA
	ld	(xwa), hl                               ; FB7AEA  b0 53             ld (XWA),HL
	ld	bc, (xiz+8)                             ; FB7AEC  9e 08 21          ld BC,(XIZ+0x08)
	add	bc, 0x0100                             ; FB7AEF  d9 c8 00 01       add BC,0x0100
	ld	(xix), bc                               ; FB7AF3  b4 51             ld (XIX),BC
	ld	xbc, (xiz+10)                           ; FB7AF5  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+8)                             ; FB7AF8  99 08 20          ld WA,(XBC+0x08)
	ld	xiy, (xiz-4)                            ; FB7AFB  ae fc 25          ld XIY,(XIZ+0xfc)
	ld	(xiy), wa                               ; FB7AFE  b5 50             ld (XIY),WA
	pop	xix                                    ; FB7B00  5c                pop XIX
	popw	hl                                    ; FB7B01  4b                pop HL
	unlk32 xiz                                 ; FB7B02  ee 0d             unlk XIZ
	ret                                        ; FB7B04  0e                ret
; --------------------------------------------------------------------------
; Dev104_SetChanRegs_0140_0180 -- registers (chan+0x0140), (chan+0x0180) from fields
; 0x0A, 0x0C.
; Called from: 0xFB373A, 0xFB3847, 0xFB39D1, 0xFB3AD9, 0xFB3BF2.
; --------------------------------------------------------------------------
Dev104_SetChanRegs_0140_0180:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB7B05  ee 0c fc ff       link XIZ,0xfffc
	pushw	hl                                   ; FB7B09  2b                push HL
	push	xix                                   ; FB7B0A  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7B0B  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0140                             ; FB7B0E  db c8 40 01       add HL,0x0140
	ld	xix, 0x00104000                         ; FB7B12  44 00 40 10 00    ld XIX,0x00104000
	ld	(xix), hl                               ; FB7B17  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7B19  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	hl, (xbc+10)                            ; FB7B1C  99 0a 23          ld HL,(XBC+0x0a)
	ld	xwa, xix                                ; FB7B1F  ec 88             ld XWA,XIX
	inc	2, xwa                                 ; FB7B21  e8 62             inc 2,XWA
	ld	(xiz-4), xwa                            ; FB7B23  be fc 60          ld (XIZ+0xfc),XWA
	ld	(xwa), hl                               ; FB7B26  b0 53             ld (XWA),HL
	ld	bc, (xiz+8)                             ; FB7B28  9e 08 21          ld BC,(XIZ+0x08)
	add	bc, 0x0180                             ; FB7B2B  d9 c8 80 01       add BC,0x0180
	ld	(xix), bc                               ; FB7B2F  b4 51             ld (XIX),BC
	ld	xbc, (xiz+10)                           ; FB7B31  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+12)                            ; FB7B34  99 0c 20          ld WA,(XBC+0x0c)
	ld	xiy, (xiz-4)                            ; FB7B37  ae fc 25          ld XIY,(XIZ+0xfc)
	ld	(xiy), wa                               ; FB7B3A  b5 50             ld (XIY),WA
	pop	xix                                    ; FB7B3C  5c                pop XIX
	popw	hl                                    ; FB7B3D  4b                pop HL
	unlk32 xiz                                 ; FB7B3E  ee 0d             unlk XIZ
	ret                                        ; FB7B40  0e                ret
; --------------------------------------------------------------------------
; Dev104_SetChanReg_0280 -- register (chan+0x0280) from field 0x14.
; Called from: 0xFAED24.
; --------------------------------------------------------------------------
Dev104_SetChanReg_0280:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7B41  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7B45  2b                push HL
	push	xix                                   ; FB7B46  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7B47  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0280                             ; FB7B4A  db c8 80 02       add HL,0x0280
	ld	xix, 0x00104000                         ; FB7B4E  44 00 40 10 00    ld XIX,0x00104000
	ld	(xix), hl                               ; FB7B53  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7B55  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+20)                            ; FB7B58  99 14 20          ld WA,(XBC+0x14)
	ld	(xix+2), wa                             ; FB7B5B  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7B5E  5c                pop XIX
	popw	hl                                    ; FB7B5F  4b                pop HL
	unlk32 xiz                                 ; FB7B60  ee 0d             unlk XIZ
	ret                                        ; FB7B62  0e                ret


; ==============================================================================
; 0xFB7B63-0xFB828D -- the SECOND tone-generator driver, and the power-on sweep
;                      22 routines, 1,835 bytes
; ==============================================================================
;
; The same device, 0x0010C000, driven by a second copy of the accessor family --
; `python3 notes/prom_c_tg_regmap.py --dups` shows 13 of the 17 routines in the
; 0xFACE67 bank occur again, byte for byte, between 0xFB7016 and 0xFB7FCE.  This
; block is the largest contiguous stretch of that second driver.  It is worth
; converting on its own account because it contains three things the first bank
; does not:
;
;   * the BIT-15 STROBE.  Six routines write a gate register with bit 15 set and
;     then write the SAME register again with bit 15 cleared (`res 15`), loading a
;     companion register in between.  That is the only place in either bank where
;     one routine writes one register twice.
;   * the THREE-SLOT structure.  The gate/value pairs come in three parallel sets:
;
;         slot   gate register   gate field   value register   value field
;           1      chan+0x0540      0x3A        chan+0x01C0        0x38
;           2      chan+0x0580      0x3C        chan+0x0600        0x40
;           3      chan+0x05C0      0x3E        chan+0x0640        0x42
;
;     ⚠ the gates are a clean 0x40 ladder; the VALUE registers are not -- slot 1's
;     is in block 7 and slots 2 and 3 are in blocks 0x18 and 0x19.  Stated as read.
;   * ★★ THE EXPLANATION OF THE `chan >= 0x40` SPLIT.  Six routines across the two
;     banks branch on `cp hl,0x0040`.  The high arm is NOT a different parameter:
;     its base is exactly 0x40 below the base an unconditional routine uses for the
;     same staging field, and the channel argument already carries that 0x40, so
;     0x0580 + (0x40+k) = 0x05C0 + k -- slot 3's register for channel k.  Every
;     port write on every arm of all six routines satisfies this:
;
;         python3 notes/prom_c_tg_regmap.py --slots      # 0 failures, exit 0
;
;     The reference set that check tests against is built by symbolically walking
;     the 32 routines that have NO bound check, so a failure would be reported, not
;     absorbed.  ⚠ An earlier draft of that check zipped two lists instead of
;     pairing a select with its data write; it passed, on pairs the ROM never
;     writes.  The comment in `_walk` records that, because the wrong version
;     printed a table that looked exactly like evidence.
;
;     It follows that a "channel" argument of 0x40..0x7F selects SLOT 3 of physical
;     channel 0..0x3F.  It is not a 65th channel, and 0x40 is not a channel count
;     derived from a bound.
;
; ★★ THE CHANNEL COUNT IS 64, AND IT COMES FROM A LOOP COUNTER.  Dev10C_ResetAllChannels
; below runs `ldb d,0x40` and steps one register per pass through blocks 0x0800 and
; 0x0840, so each block has exactly 0x40 registers.  A second loop in the same
; routine runs `cp hl,0x0040` over the channels.  That is the count read off an
; instruction rather than inferred from an address stride.
;
; ★ AND THE STAGING STRUCT'S POWER-ON IMAGE IS IN THIS ROM.  Dev10C_ResetAllChannels
; copies 0x44 = 68 bytes from ROM 0xFE12CF to 0x00D8DB and 0x26 = 38 bytes from ROM
; 0xFE133B to 0x00D91F, through the already-converted MemCopyWords at 0xF9A038
; whose argument order its own header fixes.  68 is exactly the span of the staging
; fields both banks read (0x08..0x42 plus a word).
; ⚠ 0x00D8DB is NOT 0x00D75E, the struct the 0xFACE67 bank's callers pass.  There
; are at least two staging structs of the same shape.
;
; ⚠ SIX ROUTINES HERE HAVE NO CALLER.  0xFB7B63, 0xFB7B9F, 0xFB7BC1, 0xFB7BE3,
; 0xFB7C05 and 0xFB7DF5 are reached by no absolute `call` and no `calr` anywhere in
; prom_c (notes/prom_c_xrefs.py).  A call through a register operand would be
; invisible to that search, so their headers say "NOT FOUND", not "dead".
;
; HOW THIS BLOCK WAS TRANSCRIBED.  Mechanically, not by hand:
; `notes/llvm_roundtrip_force.py c 0xFB7B63 0x72B` produced the listing and PROVED
; it re-assembles to these bytes before printing it; 65 instructions it could not
; spell were then replaced one at a time, each replacement re-encoded with
; `llvm-mc --show-encoding` and accepted only if it produced the ROM's own bytes.
; Seven remain as `extpfx`, which per notes/prom_c-llvm-mc-spellings.md is the
; correct escape hatch and keeps one source line per instruction.  Each line
; carries its address, its ROM bytes and unidasm's independent decode.

; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0440_0480 -- registers (chan+0x0440) = staging->0x10 and
; (chan+0x0480) = staging->0x12.
;
; Called from: NOT FOUND.  notes/prom_c_xrefs.py finds neither an absolute `call`
;              nor a `calr` displacement anywhere in prom_c reaching 0xFB7B63.  A
;              call through a register operand would be invisible to that search,
;              so this is "not found", not "dead".
; Inputs:  (XIZ+8) = chan, (XIZ+10) = staging struct.
; Evidence: `add hl,0x0440` / `add bc,0x0480`; sources (xbc+16), (xbc+18).
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0440_0480:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB7B63  ee 0c fc ff       link XIZ,0xfffc
	pushw	hl                                   ; FB7B67  2b                push HL
	push	xix                                   ; FB7B68  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7B69  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0440                             ; FB7B6C  db c8 40 04       add HL,0x0440
	ld	xix, 0x0010C000                         ; FB7B70  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7B75  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7B77  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	hl, (xbc+16)                            ; FB7B7A  99 10 23          ld HL,(XBC+0x10)
	ld	xwa, xix                                ; FB7B7D  ec 88             ld XWA,XIX
	inc	2, xwa                                 ; FB7B7F  e8 62             inc 2,XWA
	ld	(xiz-4), xwa                            ; FB7B81  be fc 60          ld (XIZ+0xfc),XWA
	ld	(xwa), hl                               ; FB7B84  b0 53             ld (XWA),HL
	ld	bc, (xiz+8)                             ; FB7B86  9e 08 21          ld BC,(XIZ+0x08)
	add	bc, 0x0480                             ; FB7B89  d9 c8 80 04       add BC,0x0480
	ld	(xix), bc                               ; FB7B8D  b4 51             ld (XIX),BC
	ld	xbc, (xiz+10)                           ; FB7B8F  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+18)                            ; FB7B92  99 12 20          ld WA,(XBC+0x12)
	ld	xiy, (xiz-4)                            ; FB7B95  ae fc 25          ld XIY,(XIZ+0xfc)
	ld	(xiy), wa                               ; FB7B98  b5 50             ld (XIY),WA
	pop	xix                                    ; FB7B9A  5c                pop XIX
	popw	hl                                    ; FB7B9B  4b                pop HL
	unlk32 xiz                                 ; FB7B9C  ee 0d             unlk XIZ
	ret                                        ; FB7B9E  0e                ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0180_b -- register (chan+0x0180) = staging->0x0C.
; ⚠ 34 bytes BYTE-IDENTICAL to Dev10C_SetChanReg_0180 at 0xFACFB4
;   (`python3 notes/prom_c_tg_regmap.py --dups`).
; Called from: NOT FOUND (same caveat as 0xFB7B63).
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0180_b:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7B9F  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7BA3  2b                push HL
	push	xix                                   ; FB7BA4  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7BA5  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0180                             ; FB7BA8  db c8 80 01       add HL,0x0180
	ld	xix, 0x0010C000                         ; FB7BAC  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7BB1  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7BB3  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+12)                            ; FB7BB6  99 0c 20          ld WA,(XBC+0x0c)
	ld	(xix+2), wa                             ; FB7BB9  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7BBC  5c                pop XIX
	popw	hl                                    ; FB7BBD  4b                pop HL
	unlk32 xiz                                 ; FB7BBE  ee 0d             unlk XIZ
	ret                                        ; FB7BC0  0e                ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0440_b -- register (chan+0x0440) = staging->0x10.
; ⚠ 34 bytes BYTE-IDENTICAL to Dev10C_SetChanReg_0440 at 0xFACFD6.
; Called from: NOT FOUND.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0440_b:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7BC1  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7BC5  2b                push HL
	push	xix                                   ; FB7BC6  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7BC7  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0440                             ; FB7BCA  db c8 40 04       add HL,0x0440
	ld	xix, 0x0010C000                         ; FB7BCE  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7BD3  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7BD5  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+16)                            ; FB7BD8  99 10 20          ld WA,(XBC+0x10)
	ld	(xix+2), wa                             ; FB7BDB  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7BDE  5c                pop XIX
	popw	hl                                    ; FB7BDF  4b                pop HL
	unlk32 xiz                                 ; FB7BE0  ee 0d             unlk XIZ
	ret                                        ; FB7BE2  0e                ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0480 -- register (chan+0x0480) = staging->0x12.
; Block 0x0480 has no writer in the 0xFACE67 bank; it is one of the five blocks
; only this second bank reaches.
; Called from: NOT FOUND.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0480:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7BE3  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7BE7  2b                push HL
	push	xix                                   ; FB7BE8  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7BE9  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0480                             ; FB7BEC  db c8 80 04       add HL,0x0480
	ld	xix, 0x0010C000                         ; FB7BF0  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7BF5  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7BF7  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+18)                            ; FB7BFA  99 12 20          ld WA,(XBC+0x12)
	ld	(xix+2), wa                             ; FB7BFD  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7C00  5c                pop XIX
	popw	hl                                    ; FB7C01  4b                pop HL
	unlk32 xiz                                 ; FB7C02  ee 0d             unlk XIZ
	ret                                        ; FB7C04  0e                ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_04C0_b -- register (chan+0x04C0) = staging->0x14.
; ⚠ 34 bytes BYTE-IDENTICAL to Dev10C_SetChanReg_04C0 at 0xFACFF8.
; Called from: NOT FOUND.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_04C0_b:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7C05  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7C09  2b                push HL
	push	xix                                   ; FB7C0A  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7C0B  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x04C0                             ; FB7C0E  db c8 c0 04       add HL,0x04c0
	ld	xix, 0x0010C000                         ; FB7C12  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7C17  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7C19  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+20)                            ; FB7C1C  99 14 20          ld WA,(XBC+0x14)
	ld	(xix+2), wa                             ; FB7C1F  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7C22  5c                pop XIX
	popw	hl                                    ; FB7C23  4b                pop HL
	unlk32 xiz                                 ; FB7C24  ee 0d             unlk XIZ
	ret                                        ; FB7C26  0e                ret
; --------------------------------------------------------------------------
; ★ Dev10C_Slot2_WriteGateAndValue -- the routine that shows what BIT 15 of a gate
; register is for.
;
;       if (staging->0x3C & 0x8000)  register (chan+0x0580) = staging->0x3C
;       register (chan+0x0600) = staging->0x40
;       register (chan+0x0580) = staging->0x3C with BIT 15 CLEARED
;
; Called from: 0xFA9B6D, 0xFAC516, 0xFAC57F, 0xFB8AEA and 0xFB822A (the last
;              inside Dev10C_ResetAllChannels below).
; Inputs:  (XIZ+8) = chan, (XIZ+10) = staging struct (here loaded into XIX).
; Evidence: `and bc,0x8000` / `jr z,...` guards the first write; `res 15,bc`
;          (unidasm: `res 0x0f,BC`) makes the third.  Same field both times.
; ★ So the sequence written to register (chan+0x0580) is <value with bit 15> then
;   <the same value without bit 15> -- a ONE-THEN-ZERO PULSE on bit 15 with the
;   companion register loaded in between.  That is a strobe, and it is the only
;   place in either bank where the same register is written twice in one routine.
; ⚠ What the strobe DOES is not established.  "Trigger", "latch" and "key-on" all
;   fit the shape and nothing here distinguishes them.
; --------------------------------------------------------------------------
Dev10C_Slot2_WriteGateAndValue:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB7C27  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB7C2B  2b                push HL
	pushw	de                                   ; FB7C2C  2a                push DE
	push	xix                                   ; FB7C2D  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7C2E  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB7C31  9e 08 23          ld HL,(XIZ+0x08)
	ld	bc, (xix+60)                            ; FB7C34  9c 3c 21          ld BC,(XIX+0x3c)
	and	bc, 0x8000                             ; FB7C37  d9 cc 00 80       and BC,0x8000
	jr z, L_FB7C56                             ; FB7C3B  66 19             jr Z,0xfb7c56
	ld	de, hl                                  ; FB7C3D  db 8a             ld DE,HL
	add	de, 0x0580                             ; FB7C3F  da c8 80 05       add DE,0x0580
	ld	xbc, 0x0010C000                         ; FB7C43  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7C48  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7C4B  b1 52             ld (XBC),DE
	ld	bc, (xix+60)                            ; FB7C4D  9c 3c 21          ld BC,(XIX+0x3c)
	ld	xwa, (xiz-4)                            ; FB7C50  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7C53  b8 02 51          ld (XWA+0x02),BC
L_FB7C56:
	ld	de, hl                                  ; FB7C56  db 8a             ld DE,HL
	add	de, 0x0600                             ; FB7C58  da c8 00 06       add DE,0x0600
	ld	xbc, 0x0010C000                         ; FB7C5C  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7C61  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7C64  b1 52             ld (XBC),DE
	ld	de, (xix+64)                            ; FB7C66  9c 40 22          ld DE,(XIX+0x40)
	ld	xbc, (xiz-4)                            ; FB7C69  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB7C6C  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB7C6E  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB7C71  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB7C73  db 89             ld BC,HL
	add	bc, 0x0580                             ; FB7C75  d9 c8 80 05       add BC,0x0580
	ld	xwa, (xiz-4)                            ; FB7C79  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7C7C  b0 51             ld (XWA),BC
	ld	bc, (xix+60)                            ; FB7C7E  9c 3c 21          ld BC,(XIX+0x3c)
	res	15, bc                                 ; FB7C81  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-8)                            ; FB7C84  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7C87  b0 51             ld (XWA),BC
	pop	xix                                    ; FB7C89  5c                pop XIX
	popw	de                                    ; FB7C8A  4a                pop DE
	popw	hl                                    ; FB7C8B  4b                pop HL
	unlk32 xiz                                 ; FB7C8C  ee 0d             unlk XIZ
	ret                                        ; FB7C8E  0e                ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0600_b -- register (chan+0x0600) = staging->0x40.
; ⚠ 34 bytes BYTE-IDENTICAL to Dev10C_SetChanReg_0600 at 0xFAD01A.
; Called from: 0xFA9AC2, 0xFABEAD, 0xFACD0B.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0600_b:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7C8F  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7C93  2b                push HL
	push	xix                                   ; FB7C94  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7C95  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0600                             ; FB7C98  db c8 00 06       add HL,0x0600
	ld	xix, 0x0010C000                         ; FB7C9C  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7CA1  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7CA3  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+64)                            ; FB7CA6  99 40 20          ld WA,(XBC+0x40)
	ld	(xix+2), wa                             ; FB7CA9  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7CAC  5c                pop XIX
	popw	hl                                    ; FB7CAD  4b                pop HL
	unlk32 xiz                                 ; FB7CAE  ee 0d             unlk XIZ
	ret                                        ; FB7CB0  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot2_StrobeGate -- the same pulse as Dev10C_Slot2_WriteGateAndValue without the
; companion register:
;
;       if (staging->0x3C & 0x8000)  register (chan+0x0580) = staging->0x3C
;       register (chan+0x0580) = staging->0x3C with bit 15 cleared
;
; Called from: 0xFA9A43, 0xFACDB1.
; --------------------------------------------------------------------------
Dev10C_Slot2_StrobeGate:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB7CB1  ee 0c fc ff       link XIZ,0xfffc
	pushw	hl                                   ; FB7CB5  2b                push HL
	push	xix                                   ; FB7CB6  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7CB7  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	bc, (xix+60)                            ; FB7CBA  9c 3c 21          ld BC,(XIX+0x3c)
	and	bc, 0x8000                             ; FB7CBD  d9 cc 00 80       and BC,0x8000
	jr z, L_FB7CDD                             ; FB7CC1  66 1a             jr Z,0xfb7cdd
	ld	hl, (xiz+8)                             ; FB7CC3  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0580                             ; FB7CC6  db c8 80 05       add HL,0x0580
	ld	xbc, 0x0010C000                         ; FB7CCA  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7CCF  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), hl                               ; FB7CD2  b1 53             ld (XBC),HL
	ld	bc, (xix+60)                            ; FB7CD4  9c 3c 21          ld BC,(XIX+0x3c)
	ld	xwa, (xiz-4)                            ; FB7CD7  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7CDA  b8 02 51          ld (XWA+0x02),BC
L_FB7CDD:
	ld	hl, (xiz+8)                             ; FB7CDD  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0580                             ; FB7CE0  db c8 80 05       add HL,0x0580
	ld	xbc, 0x0010C000                         ; FB7CE4  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7CE9  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), hl                               ; FB7CEC  b1 53             ld (XBC),HL
	ld	bc, (xix+60)                            ; FB7CEE  9c 3c 21          ld BC,(XIX+0x3c)
	res	15, bc                                 ; FB7CF1  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-4)                            ; FB7CF4  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7CF7  b8 02 51          ld (XWA+0x02),BC
	pop	xix                                    ; FB7CFA  5c                pop XIX
	popw	hl                                    ; FB7CFB  4b                pop HL
	unlk32 xiz                                 ; FB7CFC  ee 0d             unlk XIZ
	ret                                        ; FB7CFE  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot2_WriteGate8100 -- register (chan+0x0580) = the CONSTANT 0x8100.
; Called from: 0xFA999F.
; Evidence: `ldw (xix+2),0x8100` -- an immediate, not a struct field.
; ⚠ 0x8100 has bit 15 set (the bit the strobe routines pulse) and bit 8 set.
;   Nothing here says what either means.
; --------------------------------------------------------------------------
Dev10C_Slot2_WriteGate8100:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7CFF  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7D03  2b                push HL
	push	xix                                   ; FB7D04  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7D05  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0580                             ; FB7D08  db c8 80 05       add HL,0x0580
	ld	xix, 0x0010C000                         ; FB7D0C  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7D11  b4 53             ld (XIX),HL
	ldw (xix+2), 0x8100                        ; FB7D13  bc 02 02 00 81    ld (XIX+0x02),0x8100
	pop	xix                                    ; FB7D18  5c                pop XIX
	popw	hl                                    ; FB7D19  4b                pop HL
	unlk32 xiz                                 ; FB7D1A  ee 0d             unlk XIZ
	ret                                        ; FB7D1C  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot3_WriteGateAndValue -- Dev10C_Slot2_WriteGateAndValue's shape on the THIRD
; slot:
;       if (staging->0x3E & 0x8000)  register (chan+0x05C0) = staging->0x3E
;       register (chan+0x0640) = staging->0x42
;       register (chan+0x05C0) = staging->0x3E with bit 15 cleared
;
; Called from: 0xFA9C52, 0xFAC679, 0xFAC6E2, 0xFB8236.
; --------------------------------------------------------------------------
Dev10C_Slot3_WriteGateAndValue:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB7D1D  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB7D21  2b                push HL
	pushw	de                                   ; FB7D22  2a                push DE
	push	xix                                   ; FB7D23  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7D24  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB7D27  9e 08 23          ld HL,(XIZ+0x08)
	ld	bc, (xix+62)                            ; FB7D2A  9c 3e 21          ld BC,(XIX+0x3e)
	and	bc, 0x8000                             ; FB7D2D  d9 cc 00 80       and BC,0x8000
	jr z, L_FB7D4C                             ; FB7D31  66 19             jr Z,0xfb7d4c
	ld	de, hl                                  ; FB7D33  db 8a             ld DE,HL
	add	de, 0x05C0                             ; FB7D35  da c8 c0 05       add DE,0x05c0
	ld	xbc, 0x0010C000                         ; FB7D39  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7D3E  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7D41  b1 52             ld (XBC),DE
	ld	bc, (xix+62)                            ; FB7D43  9c 3e 21          ld BC,(XIX+0x3e)
	ld	xwa, (xiz-4)                            ; FB7D46  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7D49  b8 02 51          ld (XWA+0x02),BC
L_FB7D4C:
	ld	de, hl                                  ; FB7D4C  db 8a             ld DE,HL
	add	de, 0x0640                             ; FB7D4E  da c8 40 06       add DE,0x0640
	ld	xbc, 0x0010C000                         ; FB7D52  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7D57  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7D5A  b1 52             ld (XBC),DE
	ld	de, (xix+66)                            ; FB7D5C  9c 42 22          ld DE,(XIX+0x42)
	ld	xbc, (xiz-4)                            ; FB7D5F  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB7D62  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB7D64  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB7D67  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB7D69  db 89             ld BC,HL
	add	bc, 0x05C0                             ; FB7D6B  d9 c8 c0 05       add BC,0x05c0
	ld	xwa, (xiz-4)                            ; FB7D6F  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7D72  b0 51             ld (XWA),BC
	ld	bc, (xix+62)                            ; FB7D74  9c 3e 21          ld BC,(XIX+0x3e)
	res	15, bc                                 ; FB7D77  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-8)                            ; FB7D7A  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7D7D  b0 51             ld (XWA),BC
	pop	xix                                    ; FB7D7F  5c                pop XIX
	popw	de                                    ; FB7D80  4a                pop DE
	popw	hl                                    ; FB7D81  4b                pop HL
	unlk32 xiz                                 ; FB7D82  ee 0d             unlk XIZ
	ret                                        ; FB7D84  0e                ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_0640 -- register (chan+0x0640) = staging->0x42.
; Called from: 0xFACCCA.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_0640:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7D85  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7D89  2b                push HL
	push	xix                                   ; FB7D8A  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7D8B  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0640                             ; FB7D8E  db c8 40 06       add HL,0x0640
	ld	xix, 0x0010C000                         ; FB7D92  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7D97  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7D99  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+66)                            ; FB7D9C  99 42 20          ld WA,(XBC+0x42)
	ld	(xix+2), wa                             ; FB7D9F  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7DA2  5c                pop XIX
	popw	hl                                    ; FB7DA3  4b                pop HL
	unlk32 xiz                                 ; FB7DA4  ee 0d             unlk XIZ
	ret                                        ; FB7DA6  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot3_StrobeGate -- slot 3's copy of Dev10C_Slot2_StrobeGate, on 0x05C0 / 0x3E.
; Called from: 0xFACD70.
; --------------------------------------------------------------------------
Dev10C_Slot3_StrobeGate:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB7DA7  ee 0c fc ff       link XIZ,0xfffc
	pushw	hl                                   ; FB7DAB  2b                push HL
	push	xix                                   ; FB7DAC  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7DAD  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	bc, (xix+62)                            ; FB7DB0  9c 3e 21          ld BC,(XIX+0x3e)
	and	bc, 0x8000                             ; FB7DB3  d9 cc 00 80       and BC,0x8000
	jr z, L_FB7DD3                             ; FB7DB7  66 1a             jr Z,0xfb7dd3
	ld	hl, (xiz+8)                             ; FB7DB9  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x05C0                             ; FB7DBC  db c8 c0 05       add HL,0x05c0
	ld	xbc, 0x0010C000                         ; FB7DC0  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7DC5  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), hl                               ; FB7DC8  b1 53             ld (XBC),HL
	ld	bc, (xix+62)                            ; FB7DCA  9c 3e 21          ld BC,(XIX+0x3e)
	ld	xwa, (xiz-4)                            ; FB7DCD  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7DD0  b8 02 51          ld (XWA+0x02),BC
L_FB7DD3:
	ld	hl, (xiz+8)                             ; FB7DD3  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x05C0                             ; FB7DD6  db c8 c0 05       add HL,0x05c0
	ld	xbc, 0x0010C000                         ; FB7DDA  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7DDF  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), hl                               ; FB7DE2  b1 53             ld (XBC),HL
	ld	bc, (xix+62)                            ; FB7DE4  9c 3e 21          ld BC,(XIX+0x3e)
	res	15, bc                                 ; FB7DE7  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-4)                            ; FB7DEA  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7DED  b8 02 51          ld (XWA+0x02),BC
	pop	xix                                    ; FB7DF0  5c                pop XIX
	popw	hl                                    ; FB7DF1  4b                pop HL
	unlk32 xiz                                 ; FB7DF2  ee 0d             unlk XIZ
	ret                                        ; FB7DF4  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot3_WriteGate8100 -- register (chan+0x05C0) = 0x8100.
; Called from: NOT FOUND -- `notes/prom_c_xrefs.py 0xFB7DF5 --no-window` finds no
;          literal and no calr; short PC-relative forms are not searched.
; Evidence: eleven instructions, all of them here: `ld HL,(XIZ+0x08) /
;          add HL,0x05c0 / ld XIX,0x0010C000 / ld (XIX),HL /
;          ld (XIX+0x02),0x8100` -- the select/data pair with an immediate.
;          0x05C0 is slot 3's GATE register in the three-slot table of
;          notes/FINDINGS-prom_c-tone-generator.md §5, and 0x8100 is the same
;          constant its slot-1 and slot-2 twins write, which is why the name says
;          "Gate8100" rather than naming a function for the value.
;          ⚠ What writing 0x8100 DOES is not established.
; --------------------------------------------------------------------------
Dev10C_Slot3_WriteGate8100:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7DF5  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7DF9  2b                push HL
	push	xix                                   ; FB7DFA  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7DFB  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x05C0                             ; FB7DFE  db c8 c0 05       add HL,0x05c0
	ld	xix, 0x0010C000                         ; FB7E02  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7E07  b4 53             ld (XIX),HL
	ldw (xix+2), 0x8100                        ; FB7E09  bc 02 02 00 81    ld (XIX+0x02),0x8100
	pop	xix                                    ; FB7E0E  5c                pop XIX
	popw	hl                                    ; FB7E0F  4b                pop HL
	unlk32 xiz                                 ; FB7E10  ee 0d             unlk XIZ
	ret                                        ; FB7E12  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot1_WriteGateAndValue -- the FIRST slot's copy.  ⚠ Note that slot 1's
; companion register is in a different part of the map from slots 2 and 3:
;
;       if (staging->0x3A & 0x8000)  register (chan+0x0540) = staging->0x3A
;       register (chan+0x01C0) = staging->0x38          <-- block 7, not 0x18/0x19
;       register (chan+0x0540) = staging->0x3A with bit 15 cleared
;
; Called from: 0xFA9EAE, 0xFB8BEA, 0xFB821E.
; --------------------------------------------------------------------------
Dev10C_Slot1_WriteGateAndValue:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB7E13  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB7E17  2b                push HL
	pushw	de                                   ; FB7E18  2a                push DE
	push	xix                                   ; FB7E19  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7E1A  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB7E1D  9e 08 23          ld HL,(XIZ+0x08)
	ld	bc, (xix+58)                            ; FB7E20  9c 3a 21          ld BC,(XIX+0x3a)
	and	bc, 0x8000                             ; FB7E23  d9 cc 00 80       and BC,0x8000
	jr z, L_FB7E42                             ; FB7E27  66 19             jr Z,0xfb7e42
	ld	de, hl                                  ; FB7E29  db 8a             ld DE,HL
	add	de, 0x0540                             ; FB7E2B  da c8 40 05       add DE,0x0540
	ld	xbc, 0x0010C000                         ; FB7E2F  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7E34  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7E37  b1 52             ld (XBC),DE
	ld	bc, (xix+58)                            ; FB7E39  9c 3a 21          ld BC,(XIX+0x3a)
	ld	xwa, (xiz-4)                            ; FB7E3C  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7E3F  b8 02 51          ld (XWA+0x02),BC
L_FB7E42:
	ld	de, hl                                  ; FB7E42  db 8a             ld DE,HL
	add	de, 0x01C0                             ; FB7E44  da c8 c0 01       add DE,0x01c0
	ld	xbc, 0x0010C000                         ; FB7E48  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7E4D  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7E50  b1 52             ld (XBC),DE
	ld	de, (xix+56)                            ; FB7E52  9c 38 22          ld DE,(XIX+0x38)
	ld	xbc, (xiz-4)                            ; FB7E55  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB7E58  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB7E5A  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB7E5D  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB7E5F  db 89             ld BC,HL
	add	bc, 0x0540                             ; FB7E61  d9 c8 40 05       add BC,0x0540
	ld	xwa, (xiz-4)                            ; FB7E65  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7E68  b0 51             ld (XWA),BC
	ld	bc, (xix+58)                            ; FB7E6A  9c 3a 21          ld BC,(XIX+0x3a)
	res	15, bc                                 ; FB7E6D  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-8)                            ; FB7E70  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7E73  b0 51             ld (XWA),BC
	pop	xix                                    ; FB7E75  5c                pop XIX
	popw	de                                    ; FB7E76  4a                pop DE
	popw	hl                                    ; FB7E77  4b                pop HL
	unlk32 xiz                                 ; FB7E78  ee 0d             unlk XIZ
	ret                                        ; FB7E7A  0e                ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_01C0_b -- register (chan+0x01C0) = staging->0x38.
; ⚠ 34 bytes BYTE-IDENTICAL to Dev10C_SetChanReg_01C0 at 0xFAD05E.
; Called from: 0xFA9E09, 0xFABF3A, 0xFACE04.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_01C0_b:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7E7B  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7E7F  2b                push HL
	push	xix                                   ; FB7E80  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7E81  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x01C0                             ; FB7E84  db c8 c0 01       add HL,0x01c0
	ld	xix, 0x0010C000                         ; FB7E88  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7E8D  b4 53             ld (XIX),HL
	ld	xbc, (xiz+10)                           ; FB7E8F  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+56)                            ; FB7E92  99 38 20          ld WA,(XBC+0x38)
	ld	(xix+2), wa                             ; FB7E95  bc 02 50          ld (XIX+0x02),WA
	pop	xix                                    ; FB7E98  5c                pop XIX
	popw	hl                                    ; FB7E99  4b                pop HL
	unlk32 xiz                                 ; FB7E9A  ee 0d             unlk XIZ
	ret                                        ; FB7E9C  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot1_StrobeGate -- slot 1's copy of Dev10C_Slot2_StrobeGate, on 0x0540 / 0x3A.
; Called from: 0xFA9D89, 0xFAC78C, 0xFAC7DF, 0xFACE57.
; --------------------------------------------------------------------------
Dev10C_Slot1_StrobeGate:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB7E9D  ee 0c fc ff       link XIZ,0xfffc
	pushw	hl                                   ; FB7EA1  2b                push HL
	push	xix                                   ; FB7EA2  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7EA3  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	bc, (xix+58)                            ; FB7EA6  9c 3a 21          ld BC,(XIX+0x3a)
	and	bc, 0x8000                             ; FB7EA9  d9 cc 00 80       and BC,0x8000
	jr z, L_FB7EC9                             ; FB7EAD  66 1a             jr Z,0xfb7ec9
	ld	hl, (xiz+8)                             ; FB7EAF  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0540                             ; FB7EB2  db c8 40 05       add HL,0x0540
	ld	xbc, 0x0010C000                         ; FB7EB6  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7EBB  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), hl                               ; FB7EBE  b1 53             ld (XBC),HL
	ld	bc, (xix+58)                            ; FB7EC0  9c 3a 21          ld BC,(XIX+0x3a)
	ld	xwa, (xiz-4)                            ; FB7EC3  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7EC6  b8 02 51          ld (XWA+0x02),BC
L_FB7EC9:
	ld	hl, (xiz+8)                             ; FB7EC9  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0540                             ; FB7ECC  db c8 40 05       add HL,0x0540
	ld	xbc, 0x0010C000                         ; FB7ED0  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7ED5  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), hl                               ; FB7ED8  b1 53             ld (XBC),HL
	ld	bc, (xix+58)                            ; FB7EDA  9c 3a 21          ld BC,(XIX+0x3a)
	res	15, bc                                 ; FB7EDD  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-4)                            ; FB7EE0  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7EE3  b8 02 51          ld (XWA+0x02),BC
	pop	xix                                    ; FB7EE6  5c                pop XIX
	popw	hl                                    ; FB7EE7  4b                pop HL
	unlk32 xiz                                 ; FB7EE8  ee 0d             unlk XIZ
	ret                                        ; FB7EEA  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot1_WriteGate8100 -- register (chan+0x0540) = 0x8100.
; Called from: 0xFA9CD6.
; --------------------------------------------------------------------------
Dev10C_Slot1_WriteGate8100:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7EEB  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7EEF  2b                push HL
	push	xix                                   ; FB7EF0  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7EF1  9e 08 23          ld HL,(XIZ+0x08)
	add	hl, 0x0540                             ; FB7EF4  db c8 40 05       add HL,0x0540
	ld	xix, 0x0010C000                         ; FB7EF8  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), hl                               ; FB7EFD  b4 53             ld (XIX),HL
	ldw (xix+2), 0x8100                        ; FB7EFF  bc 02 02 00 81    ld (XIX+0x02),0x8100
	pop	xix                                    ; FB7F04  5c                pop XIX
	popw	hl                                    ; FB7F05  4b                pop HL
	unlk32 xiz                                 ; FB7F06  ee 0d             unlk XIZ
	ret                                        ; FB7F08  0e                ret
; --------------------------------------------------------------------------
; ★★ Dev10C_Slot1or3_WriteGateAndValue -- the routine that MAKES THE `chan >= 0x40`
; SPLIT ADD UP.
;
;       chan <  0x40 :  slot 1 -- gate (chan+0x0540) from 0x3A, value (chan+0x01C0) from 0x38
;       chan >= 0x40 :  gate (chan+0x0580) from 0x3E, value (chan+0x0600) from 0x42
;
; and the high arm is not a different parameter: 0x0580 + (0x40+k) = 0x05C0 + k
; and 0x0600 + (0x40+k) = 0x0640 + k, which are EXACTLY the registers
; Dev10C_Slot3_WriteGateAndValue writes for channel k -- with exactly slot 3's struct
; fields, 0x3E and 0x42.  The base is 0x40 low because the channel argument
; already carries that 0x40.
;
; Called from: 0xFB8CE0.
; Evidence: `cp hl,0x0040` / `jr nc,...`; then the two arms.  The identity above
;          is checked for all five bound-checked routines in both banks by
;          `python3 notes/prom_c_tg_regmap.py --slots`, which fails loudly rather
;          than printing a table if any of them does not satisfy it.
; ⚠ It follows that a "channel" argument of 0x40..0x7F means slot 3 of physical
;   channel 0..0x3F, NOT a 65th channel.  Anything that reads the 0x40 bound as a
;   channel COUNT is reading it wrong.
; --------------------------------------------------------------------------
Dev10C_Slot1or3_WriteGateAndValue:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FB7F09  ee 0c f8 ff       link XIZ,0xfff8
	pushw	hl                                   ; FB7F0D  2b                push HL
	pushw	de                                   ; FB7F0E  2a                push DE
	push	xix                                   ; FB7F0F  3c                push XIX
	ld	xix, (xiz+10)                           ; FB7F10  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB7F13  9e 08 23          ld HL,(XIZ+0x08)
	cp	hl, 64                                  ; FB7F16  db cf 40 00       cp HL,0x0040
	jr nc, L_FB7F73                            ; FB7F1A  6f 57             jr NC,0xfb7f73
	ld	bc, (xix+58)                            ; FB7F1C  9c 3a 21          ld BC,(XIX+0x3a)
	and	bc, 0x8000                             ; FB7F1F  d9 cc 00 80       and BC,0x8000
	jr z, L_FB7F3E                             ; FB7F23  66 19             jr Z,0xfb7f3e
	ld	de, hl                                  ; FB7F25  db 8a             ld DE,HL
	add	de, 0x0540                             ; FB7F27  da c8 40 05       add DE,0x0540
	ld	xbc, 0x0010C000                         ; FB7F2B  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7F30  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7F33  b1 52             ld (XBC),DE
	ld	bc, (xix+58)                            ; FB7F35  9c 3a 21          ld BC,(XIX+0x3a)
	ld	xwa, (xiz-4)                            ; FB7F38  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7F3B  b8 02 51          ld (XWA+0x02),BC
L_FB7F3E:
	ld	de, hl                                  ; FB7F3E  db 8a             ld DE,HL
	add	de, 0x01C0                             ; FB7F40  da c8 c0 01       add DE,0x01c0
	ld	xbc, 0x0010C000                         ; FB7F44  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7F49  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7F4C  b1 52             ld (XBC),DE
	ld	de, (xix+56)                            ; FB7F4E  9c 38 22          ld DE,(XIX+0x38)
	ld	xbc, (xiz-4)                            ; FB7F51  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB7F54  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB7F56  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB7F59  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB7F5B  db 89             ld BC,HL
	add	bc, 0x0540                             ; FB7F5D  d9 c8 40 05       add BC,0x0540
	ld	xwa, (xiz-4)                            ; FB7F61  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7F64  b0 51             ld (XWA),BC
	ld	bc, (xix+58)                            ; FB7F66  9c 3a 21          ld BC,(XIX+0x3a)
	res	15, bc                                 ; FB7F69  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-8)                            ; FB7F6C  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7F6F  b0 51             ld (XWA),BC
	jr L_FB7FC8                                ; FB7F71  68 55             jr T,0xfb7fc8
L_FB7F73:
	ld	bc, (xix+62)                            ; FB7F73  9c 3e 21          ld BC,(XIX+0x3e)
	and	bc, 0x8000                             ; FB7F76  d9 cc 00 80       and BC,0x8000
	jr z, L_FB7F95                             ; FB7F7A  66 19             jr Z,0xfb7f95
	ld	de, hl                                  ; FB7F7C  db 8a             ld DE,HL
	add	de, 0x0580                             ; FB7F7E  da c8 80 05       add DE,0x0580
	ld	xbc, 0x0010C000                         ; FB7F82  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7F87  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7F8A  b1 52             ld (XBC),DE
	ld	bc, (xix+62)                            ; FB7F8C  9c 3e 21          ld BC,(XIX+0x3e)
	ld	xwa, (xiz-4)                            ; FB7F8F  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB7F92  b8 02 51          ld (XWA+0x02),BC
L_FB7F95:
	ld	de, hl                                  ; FB7F95  db 8a             ld DE,HL
	add	de, 0x0600                             ; FB7F97  da c8 00 06       add DE,0x0600
	ld	xbc, 0x0010C000                         ; FB7F9B  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB7FA0  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB7FA3  b1 52             ld (XBC),DE
	ld	de, (xix+66)                            ; FB7FA5  9c 42 22          ld DE,(XIX+0x42)
	ld	xbc, (xiz-4)                            ; FB7FA8  ae fc 21          ld XBC,(XIZ+0xfc)
	inc	2, xbc                                 ; FB7FAB  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB7FAD  be f8 61          ld (XIZ+0xf8),XBC
	ld	(xbc), de                               ; FB7FB0  b1 52             ld (XBC),DE
	ld	bc, hl                                  ; FB7FB2  db 89             ld BC,HL
	add	bc, 0x0580                             ; FB7FB4  d9 c8 80 05       add BC,0x0580
	ld	xwa, (xiz-4)                            ; FB7FB8  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                               ; FB7FBB  b0 51             ld (XWA),BC
	ld	bc, (xix+62)                            ; FB7FBD  9c 3e 21          ld BC,(XIX+0x3e)
	res	15, bc                                 ; FB7FC0  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-8)                            ; FB7FC3  ae f8 20          ld XWA,(XIZ+0xf8)
	ld	(xwa), bc                               ; FB7FC6  b0 51             ld (XWA),BC
L_FB7FC8:
	pop	xix                                    ; FB7FC8  5c                pop XIX
	popw	de                                    ; FB7FC9  4a                pop DE
	popw	hl                                    ; FB7FCA  4b                pop HL
	unlk32 xiz                                 ; FB7FCB  ee 0d             unlk XIZ
	ret                                        ; FB7FCD  0e                ret
; --------------------------------------------------------------------------
; Dev10C_SetChanReg_01C0_or_0600_b -- the value half of the split alone.
; ⚠ 68 bytes BYTE-IDENTICAL to Dev10C_SetChanReg_01C0_or_0600 at 0xFAD0A2.
; Called from: 0xFAA0B0, 0xFAC008.
; --------------------------------------------------------------------------
Dev10C_SetChanReg_01C0_or_0600_b:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB7FCE  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB7FD2  2b                push HL
	pushw	de                                   ; FB7FD3  2a                push DE
	push	xix                                   ; FB7FD4  3c                push XIX
	ld	hl, (xiz+8)                             ; FB7FD5  9e 08 23          ld HL,(XIZ+0x08)
	cp	hl, 64                                  ; FB7FD8  db cf 40 00       cp HL,0x0040
	jr nc, L_FB7FF6                            ; FB7FDC  6f 18             jr NC,0xfb7ff6
	ld	de, hl                                  ; FB7FDE  db 8a             ld DE,HL
	add	de, 0x01C0                             ; FB7FE0  da c8 c0 01       add DE,0x01c0
	ld	xix, 0x0010C000                         ; FB7FE4  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), de                               ; FB7FE9  b4 52             ld (XIX),DE
	ld	xbc, (xiz+10)                           ; FB7FEB  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+56)                            ; FB7FEE  99 38 20          ld WA,(XBC+0x38)
	ld	(xix+2), wa                             ; FB7FF1  bc 02 50          ld (XIX+0x02),WA
	jr L_FB800C                                ; FB7FF4  68 16             jr T,0xfb800c
L_FB7FF6:
	ld	de, hl                                  ; FB7FF6  db 8a             ld DE,HL
	add	de, 0x0600                             ; FB7FF8  da c8 00 06       add DE,0x0600
	ld	xix, 0x0010C000                         ; FB7FFC  44 00 c0 10 00    ld XIX,0x0010c000
	ld	(xix), de                               ; FB8001  b4 52             ld (XIX),DE
	ld	xbc, (xiz+10)                           ; FB8003  ae 0a 21          ld XBC,(XIZ+0x0a)
	ld	wa, (xbc+66)                            ; FB8006  99 42 20          ld WA,(XBC+0x42)
	ld	(xix+2), wa                             ; FB8009  bc 02 50          ld (XIX+0x02),WA
L_FB800C:
	pop	xix                                    ; FB800C  5c                pop XIX
	popw	de                                    ; FB800D  4a                pop DE
	popw	hl                                    ; FB800E  4b                pop HL
	unlk32 xiz                                 ; FB800F  ee 0d             unlk XIZ
	ret                                        ; FB8011  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot1or3_StrobeGate -- the gate half of the split alone: the bit-15 pulse on
; slot 1 for chan < 0x40 and on slot 3 for chan >= 0x40.
; Called from: 0xFAA02E.
; --------------------------------------------------------------------------
Dev10C_Slot1or3_StrobeGate:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FB8012  ee 0c fc ff       link XIZ,0xfffc
	pushw	hl                                   ; FB8016  2b                push HL
	pushw	de                                   ; FB8017  2a                push DE
	push	xix                                   ; FB8018  3c                push XIX
	ld	xix, (xiz+10)                           ; FB8019  ae 0a 24          ld XIX,(XIZ+0x0a)
	ld	hl, (xiz+8)                             ; FB801C  9e 08 23          ld HL,(XIZ+0x08)
	cp	hl, 64                                  ; FB801F  db cf 40 00       cp HL,0x0040
	jr nc, L_FB8065                            ; FB8023  6f 40             jr NC,0xfb8065
	ld	bc, (xix+58)                            ; FB8025  9c 3a 21          ld BC,(XIX+0x3a)
	and	bc, 0x8000                             ; FB8028  d9 cc 00 80       and BC,0x8000
	jr z, L_FB8047                             ; FB802C  66 19             jr Z,0xfb8047
	ld	de, hl                                  ; FB802E  db 8a             ld DE,HL
	add	de, 0x0540                             ; FB8030  da c8 40 05       add DE,0x0540
	ld	xbc, 0x0010C000                         ; FB8034  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB8039  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB803C  b1 52             ld (XBC),DE
	ld	bc, (xix+58)                            ; FB803E  9c 3a 21          ld BC,(XIX+0x3a)
	ld	xwa, (xiz-4)                            ; FB8041  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB8044  b8 02 51          ld (XWA+0x02),BC
L_FB8047:
	ld	de, hl                                  ; FB8047  db 8a             ld DE,HL
	add	de, 0x0540                             ; FB8049  da c8 40 05       add DE,0x0540
	ld	xbc, 0x0010C000                         ; FB804D  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB8052  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB8055  b1 52             ld (XBC),DE
	ld	bc, (xix+58)                            ; FB8057  9c 3a 21          ld BC,(XIX+0x3a)
	res	15, bc                                 ; FB805A  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-4)                            ; FB805D  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB8060  b8 02 51          ld (XWA+0x02),BC
	jr L_FB80A3                                ; FB8063  68 3e             jr T,0xfb80a3
L_FB8065:
	ld	bc, (xix+62)                            ; FB8065  9c 3e 21          ld BC,(XIX+0x3e)
	and	bc, 0x8000                             ; FB8068  d9 cc 00 80       and BC,0x8000
	jr z, L_FB8087                             ; FB806C  66 19             jr Z,0xfb8087
	ld	de, hl                                  ; FB806E  db 8a             ld DE,HL
	add	de, 0x0580                             ; FB8070  da c8 80 05       add DE,0x0580
	ld	xbc, 0x0010C000                         ; FB8074  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB8079  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB807C  b1 52             ld (XBC),DE
	ld	bc, (xix+62)                            ; FB807E  9c 3e 21          ld BC,(XIX+0x3e)
	ld	xwa, (xiz-4)                            ; FB8081  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB8084  b8 02 51          ld (XWA+0x02),BC
L_FB8087:
	ld	de, hl                                  ; FB8087  db 8a             ld DE,HL
	add	de, 0x0580                             ; FB8089  da c8 80 05       add DE,0x0580
	ld	xbc, 0x0010C000                         ; FB808D  41 00 c0 10 00    ld XBC,0x0010c000
	ld	(xiz-4), xbc                            ; FB8092  be fc 61          ld (XIZ+0xfc),XBC
	ld	(xbc), de                               ; FB8095  b1 52             ld (XBC),DE
	ld	bc, (xix+62)                            ; FB8097  9c 3e 21          ld BC,(XIX+0x3e)
	res	15, bc                                 ; FB809A  d9 30 0f          res 0x0f,BC
	ld	xwa, (xiz-4)                            ; FB809D  ae fc 20          ld XWA,(XIZ+0xfc)
	ld	(xwa+2), bc                             ; FB80A0  b8 02 51          ld (XWA+0x02),BC
L_FB80A3:
	pop	xix                                    ; FB80A3  5c                pop XIX
	popw	de                                    ; FB80A4  4a                pop DE
	popw	hl                                    ; FB80A5  4b                pop HL
	unlk32 xiz                                 ; FB80A6  ee 0d             unlk XIZ
	ret                                        ; FB80A8  0e                ret
; --------------------------------------------------------------------------
; Dev10C_Slot1or3_WriteGate8100 -- register (chan+0x0540) or (chan+0x0580) = 0x8100,
; on the same chan < 0x40 split.
; Called from: 0xFA9F8C.
; Evidence: the two arms only choose the SELECT value; the data write
;          `ldw (xbc+2),0x8100` is shared and sits after the join.
; --------------------------------------------------------------------------
Dev10C_Slot1or3_WriteGate8100:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FB80A9  ee 0c 00 00       link XIZ,0x0000
	pushw	hl                                   ; FB80AD  2b                push HL
	pushw	de                                   ; FB80AE  2a                push DE
	push	xix                                   ; FB80AF  3c                push XIX
	ld	xix, 0x0010C000                         ; FB80B0  44 00 c0 10 00    ld XIX,0x0010c000
	ld	hl, (xiz+8)                             ; FB80B5  9e 08 23          ld HL,(XIZ+0x08)
	cp	hl, 64                                  ; FB80B8  db cf 40 00       cp HL,0x0040
	jr nc, L_FB80CA                            ; FB80BC  6f 0c             jr NC,0xfb80ca
	ld	de, hl                                  ; FB80BE  db 8a             ld DE,HL
	add	de, 0x0540                             ; FB80C0  da c8 40 05       add DE,0x0540
	ld	xbc, xix                                ; FB80C4  ec 89             ld XBC,XIX
	ld	(xbc), de                               ; FB80C6  b1 52             ld (XBC),DE
	jr L_FB80D4                                ; FB80C8  68 0a             jr T,0xfb80d4
L_FB80CA:
	ld	de, hl                                  ; FB80CA  db 8a             ld DE,HL
	add	de, 0x0580                             ; FB80CC  da c8 80 05       add DE,0x0580
	ld	xbc, xix                                ; FB80D0  ec 89             ld XBC,XIX
	ld	(xbc), de                               ; FB80D2  b1 52             ld (XBC),DE
L_FB80D4:
	ld	xbc, xix                                ; FB80D4  ec 89             ld XBC,XIX
	ldw (xbc+2), 0x8100                        ; FB80D6  b9 02 02 00 81    ld (XBC+0x02),0x8100
	pop	xix                                    ; FB80DB  5c                pop XIX
	popw	de                                    ; FB80DC  4a                pop DE
	popw	hl                                    ; FB80DD  4b                pop HL
	unlk32 xiz                                 ; FB80DE  ee 0d             unlk XIZ
	ret                                        ; FB80E0  0e                ret
; --------------------------------------------------------------------------
; ★★ Dev10C_ResetAllChannels -- the power-on sweep.  This is the single most useful
; routine in the image for anyone modelling the device, because it fixes the
; CHANNEL COUNT with a loop counter instead of a comparison, and it names the ROM
; block the staging structs are initialised from.
;
; Called from: 0xFB05CD.
; Inputs:  none.
; Outputs: see below.
; Evidence, step by step, all of it in the listing:
;
;   1. `lda_24 xbc,0xFE12B5` / `push xbc` / `calr 0xFB7715`  -- hands a ROM block
;      at 0xFE12B5 to an unconverted routine.
;   2. `ld xix,0x00104000` / `ldw (xix),0x0800` / `ldw_da bc,0xFE1313` /
;      `ld (xix+2),bc`  -- ★ THE DEVICE AT 0x00104000 HAS THE SAME ADDRESS/DATA
;      SHAPE: register 0x0800 of it is loaded with the 16-bit word at ROM
;      0xFE1313.
;   3. ★ `ldb d,0x40` -- SIXTY-FOUR iterations, a literal loop counter, and the
;      loop body walks HL from 0x0840 and a frame word from 0x0800 upward by one
;      each pass, writing
;             register (0x0840 + i) = 0xFF00
;             register (0x0800 + i) = 0xFF80        for i = 0..0x3F
;      so blocks 0x21 and 0x20 have exactly 0x40 registers each.  This is the
;      channel count read off an instruction, not inferred from an address.
;      Five `nop`s follow each data write -- the bus-timing padding
;      notes/FINDINGS-memory-map.md already recorded for this device.
;   4. Two calls to MemCopyWords (0xF9A038, converted above), whose argument order
;      is fixed by its own header -- (XSP+8) source, (XSP+12) dest, (XSP+16) count:
;             0x00D8DB <- ROM 0xFE12CF, 0x44 = 68 bytes
;             0x00D91F <- ROM 0xFE133B, 0x26 = 38 bytes
;      ★ 68 is exactly the span of the staging-struct fields both banks read
;      (0x08..0x42 inclusive of a word at 0x42), so 0x00D8DB is a staging struct
;      and ROM 0xFE12CF is its POWER-ON IMAGE.
;      ⚠ 0x00D8DB is NOT the 0x00D75E the 0xFACE67 bank uses.  There are at least
;      two of these structs.
;   5. A loop over HL = 0..0x3F (`cp hl,0x0040` / `jr c,...`) that calls
;      0xFB713A, 0xFB77EF and Dev10C_WriteReg (0xFB732C) with &0x00D8DB, editing a
;      bitfield at 0x00D91F between calls.
;   6. A second loop over HL = 0..0x3F that writes, per channel,
;             register (0x0840 + i) = 0xFF00
;             register (0x0800 + i) = 0xFF80
;             register (0x00C0 + i) = 0x0000
;             register (0x0000 + i) = 0x7E00
;      and then calls Dev10C_Slot1_WriteGateAndValue, Dev10C_Slot2_WriteGateAndValue,
;      Dev10C_Slot3_WriteGateAndValue and 0xFB7A58, each with &0x00D8DB.
;      ★ All three slots, in order, for every one of 64 channels -- which is the
;      strongest evidence in the image that the three (gate, value) pairs really
;      are three parallel per-channel objects and not three unrelated parameters.
;
; ⚠ 0xFB7715, 0xFB713A, 0xFB77EF and 0xFB7A58 are NOT converted, so what steps 1
;   and 5 compute is unknown.  The reset VALUES above are what the ROM writes;
;   what they mean is not established.
; --------------------------------------------------------------------------
Dev10C_ResetAllChannels:
	link32 0xEE, 0x0C, 0xF4, 0xFF              ; FB80E1  ee 0c f4 ff       link XIZ,0xfff4
	pushw	hl                                   ; FB80E5  2b                push HL
	pushw	de                                   ; FB80E6  2a                push DE
	push	xix                                   ; FB80E7  3c                push XIX
	lda_24	xbc, 0xFE12B5                       ; FB80E8  f2 b5 12 fe 31    lda XBC,0xfe12b5
	push	xbc                                   ; FB80ED  39                push XBC
	calr (0xFB7715 - 0xFB80F1)                 ; FB80EE  1e 24 f6          calr 0xfb7715
	ld	xix, 0x00104000                         ; FB80F1  44 00 40 10 00    ld XIX,0x00104000
	ldw (xix), 0x0800                          ; FB80F6  b4 02 00 08       ld (XIX),0x0800
	ldw_da	bc, 0xFE1313                        ; FB80FA  d2 13 13 fe 21    ld BC,(0xfe1313)
	ld	(xix+2), bc                             ; FB80FF  bc 02 51          ld (XIX+0x02),BC
	ld	xix, 0x0010C000                         ; FB8102  44 00 c0 10 00    ld XIX,0x0010c000
	ld	xbc, xix                                ; FB8107  ec 89             ld XBC,XIX
	inc	2, xbc                                 ; FB8109  e9 62             inc 2,XBC
	ld	(xiz-6), xbc                            ; FB810B  be fa 61          ld (XIZ+0xfa),XBC
	ldw	hl, 0x0840                             ; FB810E  33 40 08          ld HL,0x0840
	ldw (xiz-2), 0x0800                        ; FB8111  be fe 02 00 08    ld (XIZ+0xfe),0x0800
	ldb	d, 64                                  ; FB8116  24 40             ld D,0x40
	pop	xiy                                    ; FB8118  5d                pop XIY
L_FB8119:
	ld	(xix), hl                               ; FB8119  b4 53             ld (XIX),HL
	ld	xbc, (xiz-6)                            ; FB811B  ae fa 21          ld XBC,(XIZ+0xfa)
	ldw (xbc), 0xFF00                          ; FB811E  b1 02 00 ff       ld (XBC),0xff00
	nop                                        ; FB8122  00                nop
	nop                                        ; FB8123  00                nop
	nop                                        ; FB8124  00                nop
	nop                                        ; FB8125  00                nop
	nop                                        ; FB8126  00                nop
	ld	bc, (xiz-2)                             ; FB8127  9e fe 21          ld BC,(XIZ+0xfe)
	ld	(xiz-10), bc                            ; FB812A  be f6 51          ld (XIZ+0xf6),BC
	ld	(xix), bc                               ; FB812D  b4 51             ld (XIX),BC
	ld	xbc, (xiz-6)                            ; FB812F  ae fa 21          ld XBC,(XIZ+0xfa)
	ldw (xbc), 0xFF80                          ; FB8132  b1 02 80 ff       ld (XBC),0xff80
	inc	1, hl                                  ; FB8136  db 61             inc 1,HL
	ld	bc, (xiz-10)                            ; FB8138  9e f6 21          ld BC,(XIZ+0xf6)
	inc	1, bc                                  ; FB813B  d9 61             inc 1,BC
	ld	(xiz-2), bc                             ; FB813D  be fe 51          ld (XIZ+0xfe),BC
	dec	1, d                                   ; FB8140  cc 69             dec 1,D
	cps	d, 0                                   ; FB8142  cc d8             cp D,0
	jr nz, L_FB8119                            ; FB8144  6e d3             jr NZ,0xfb8119
	lda_24	xix, 0x00D8DB                       ; FB8146  f2 db d8 00 34    lda XIX,0x00d8db
	pushw	68                                   ; FB814B  0b 44 00          push 0x0044
	push	xix                                   ; FB814E  3c                push XIX
	lda_24	xwa, 0xFE12CF                       ; FB814F  f2 cf 12 fe 30    lda XWA,0xfe12cf
	push	xwa                                   ; FB8154  38                push XWA
	call 0x00F9A038                            ; FB8155  1d 38 a0 f9       call 0xf9a038
	lda_24	xix, 0x00D91F                       ; FB8159  f2 1f d9 00 34    lda XIX,0x00d91f
	pushw	38                                   ; FB815E  0b 26 00          push 0x0026
	push	xix                                   ; FB8161  3c                push XIX
	lda_24	xbc, 0xFE133B                       ; FB8162  f2 3b 13 fe 31    lda XBC,0xfe133b
	push	xbc                                   ; FB8167  39                push XBC
	call 0x00F9A038                            ; FB8168  1d 38 a0 f9       call 0xf9a038
	ldw	hl, 0                                  ; FB816C  33 00 00          ld HL,0x0000
	add	xsp, 20                                ; FB816F  ef c8 14 00 00 00 add XSP,0x00000014
L_FB8175:
	lda_24	xbc, 0x00D8DB                       ; FB8175  f2 db d8 00 31    lda XBC,0x00d8db
	push	xbc                                   ; FB817A  39                push XBC
	ld	de, hl                                  ; FB817B  db 8a             ld DE,HL
	pushw	de                                   ; FB817D  2a                push DE
	calr (0xFB713A - 0xFB8181)                 ; FB817E  1e b9 ef          calr 0xfb713a
	extpfx7 0xD2, 0x1F, 0xD9, 0x00, 0x3C, 0xFF, 0xC0 ; FB8181  d2 1f d9 00 3c ff c0 and (0x00d91f),0xc0ff
	ldw_da	ix, 0x00D91F                        ; FB8188  d2 1f d9 00 24    ld IX,(0x00d91f)
	ld	bc, de                                  ; FB818D  da 89             ld BC,DE
	sll	bc, 8                                  ; FB818F  d9 ee 08          sll 0x08,BC
	and	bc, 0x3F00                             ; FB8192  d9 cc 00 3f       and BC,0x3f00
	or	bc, ix                                  ; FB8196  dc e1             or BC,IX
	stw_da	0x00D91F, bc                        ; FB8198  f2 1f d9 00 51    ld (0x00d91f),BC
	lda_24	xbc, 0x00D91F                       ; FB819D  f2 1f d9 00 31    lda XBC,0x00d91f
	push	xbc                                   ; FB81A2  39                push XBC
	pushw	de                                   ; FB81A3  2a                push DE
	calr (0xFB77EF - 0xFB81A7)                 ; FB81A4  1e 48 f6          calr 0xfb77ef
	ldw_da	bc, 0x00D8DB                        ; FB81A7  d2 db d8 00 21    ld BC,(0x00d8db)
	pushw	bc                                   ; FB81AC  29                push BC
	pushw	de                                   ; FB81AD  2a                push DE
	calr (0xFB732C - 0xFB81B1)                 ; FB81AE  1e 7b f1          calr 0xfb732c
	ld	hl, de                                  ; FB81B1  da 8b             ld HL,DE
	inc	1, hl                                  ; FB81B3  db 61             inc 1,HL
	inc	8, xsp                                 ; FB81B5  ef 60             inc 0,XSP
	inc	8, xsp                                 ; FB81B7  ef 60             inc 0,XSP
	cp	hl, 64                                  ; FB81B9  db cf 40 00       cp HL,0x0040
	jr c, L_FB8175                             ; FB81BD  67 b6             jr C,0xfb8175
	ldw	hl, 0                                  ; FB81BF  33 00 00          ld HL,0x0000
	ld	xix, 0x0010C000                         ; FB81C2  44 00 c0 10 00    ld XIX,0x0010c000
	ld	xbc, xix                                ; FB81C7  ec 89             ld XBC,XIX
	inc	2, xbc                                 ; FB81C9  e9 62             inc 2,XBC
	ld	(xiz-8), xbc                            ; FB81CB  be f8 61          ld (XIZ+0xf8),XBC
	ldw (xiz-2), 0x0840                        ; FB81CE  be fe 02 40 08    ld (XIZ+0xfe),0x0840
	ldw	de, 0x0800                             ; FB81D3  32 00 08          ld DE,0x0800
	ldw (xiz-4), 0x00C0                        ; FB81D6  be fc 02 c0 00    ld (XIZ+0xfc),0x00c0
L_FB81DB:
	ld	bc, (xiz-2)                             ; FB81DB  9e fe 21          ld BC,(XIZ+0xfe)
	ld	(xix), bc                               ; FB81DE  b4 51             ld (XIX),BC
	ld	xbc, (xiz-8)                            ; FB81E0  ae f8 21          ld XBC,(XIZ+0xf8)
	ldw (xbc), 0xFF00                          ; FB81E3  b1 02 00 ff       ld (XBC),0xff00
	nop                                        ; FB81E7  00                nop
	nop                                        ; FB81E8  00                nop
	nop                                        ; FB81E9  00                nop
	nop                                        ; FB81EA  00                nop
	nop                                        ; FB81EB  00                nop
	ld	(xix), de                               ; FB81EC  b4 52             ld (XIX),DE
	ld	xbc, (xiz-8)                            ; FB81EE  ae f8 21          ld XBC,(XIZ+0xf8)
	ldw (xbc), 0xFF80                          ; FB81F1  b1 02 80 ff       ld (XBC),0xff80
	ld	bc, (xiz-4)                             ; FB81F5  9e fc 21          ld BC,(XIZ+0xfc)
	ld	(xix), bc                               ; FB81F8  b4 51             ld (XIX),BC
	ld	xbc, (xiz-8)                            ; FB81FA  ae f8 21          ld XBC,(XIZ+0xf8)
	ldw (xbc), 0x0000                          ; FB81FD  b1 02 00 00       ld (XBC),0x0000
	nop                                        ; FB8201  00                nop
	nop                                        ; FB8202  00                nop
	nop                                        ; FB8203  00                nop
	nop                                        ; FB8204  00                nop
	nop                                        ; FB8205  00                nop
	ld	(xiz-10), hl                            ; FB8206  be f6 53          ld (XIZ+0xf6),HL
	ld	bc, (xiz-10)                            ; FB8209  9e f6 21          ld BC,(XIZ+0xf6)
	ld	(xix), bc                               ; FB820C  b4 51             ld (XIX),BC
	ld	xbc, (xiz-8)                            ; FB820E  ae f8 21          ld XBC,(XIZ+0xf8)
	ldw (xbc), 0x7E00                          ; FB8211  b1 02 00 7e       ld (XBC),0x7e00
	lda_24	xbc, 0x00D8DB                       ; FB8215  f2 db d8 00 31    lda XBC,0x00d8db
	push	xbc                                   ; FB821A  39                push XBC
	extpfx3 0x9E, 0xF6, 0x04                   ; FB821B  9e f6 04          pushw (XIZ+0xf6)
	calr (0xFB7E13 - 0xFB8221)                 ; FB821E  1e f2 fb          calr 0xfb7e13
	lda_24	xbc, 0x00D8DB                       ; FB8221  f2 db d8 00 31    lda XBC,0x00d8db
	push	xbc                                   ; FB8226  39                push XBC
	extpfx3 0x9E, 0xF6, 0x04                   ; FB8227  9e f6 04          pushw (XIZ+0xf6)
	calr (0xFB7C27 - 0xFB822D)                 ; FB822A  1e fa f9          calr 0xfb7c27
	lda_24	xbc, 0x00D8DB                       ; FB822D  f2 db d8 00 31    lda XBC,0x00d8db
	push	xbc                                   ; FB8232  39                push XBC
	extpfx3 0x9E, 0xF6, 0x04                   ; FB8233  9e f6 04          pushw (XIZ+0xf6)
	calr (0xFB7D1D - 0xFB8239)                 ; FB8236  1e e4 fa          calr 0xfb7d1d
	extpfx7 0xD2, 0x1F, 0xD9, 0x00, 0x3C, 0xFF, 0xC0 ; FB8239  d2 1f d9 00 3c ff c0 and (0x00d91f),0xc0ff
	ldw_da	bc, 0x00D91F                        ; FB8240  d2 1f d9 00 21    ld BC,(0x00d91f)
	res	2, bc                                  ; FB8245  d9 30 02          res 0x02,BC
	ld	(xiz-12), bc                            ; FB8248  be f4 51          ld (XIZ+0xf4),BC
	stw_da	0x00D91F, bc                        ; FB824B  f2 1f d9 00 51    ld (0x00d91f),BC
	ld	bc, (xiz-10)                            ; FB8250  9e f6 21          ld BC,(XIZ+0xf6)
	sll	bc, 8                                  ; FB8253  d9 ee 08          sll 0x08,BC
	and	bc, 0x3F00                             ; FB8256  d9 cc 00 3f       and BC,0x3f00
	extpfx3 0x9E, 0xF4, 0xE1                   ; FB825A  9e f4 e1          or BC,(XIZ+0xf4)
	stw_da	0x00D91F, bc                        ; FB825D  f2 1f d9 00 51    ld (0x00d91f),BC
	lda_24	xbc, 0x00D91F                       ; FB8262  f2 1f d9 00 31    lda XBC,0x00d91f
	push	xbc                                   ; FB8267  39                push XBC
	extpfx3 0x9E, 0xF6, 0x04                   ; FB8268  9e f6 04          pushw (XIZ+0xf6)
	calr (0xFB7A58 - 0xFB826E)                 ; FB826B  1e ea f7          calr 0xfb7a58
	incm	1, (xiz-2)                            ; FB826E  9e fe 61          incw 1,(XIZ+0xfe)
	inc	1, de                                  ; FB8271  da 61             inc 1,DE
	incm	1, (xiz-4)                            ; FB8273  9e fc 61          incw 1,(XIZ+0xfc)
	ld	hl, (xiz-10)                            ; FB8276  9e f6 23          ld HL,(XIZ+0xf6)
	inc	1, hl                                  ; FB8279  db 61             inc 1,HL
	add	xsp, 24                                ; FB827B  ef c8 18 00 00 00 add XSP,0x00000018
	cp	hl, 64                                  ; FB8281  db cf 40 00       cp HL,0x0040
	jrl c, L_FB81DB                            ; FB8285  77 53 ff          jrl C,0xfb81db
	pop	xix                                    ; FB8288  5c                pop XIX
	popw	de                                    ; FB8289  4a                pop DE
	popw	hl                                    ; FB828A  4b                pop HL
	unlk32 xiz                                 ; FB828B  ee 0d             unlk XIZ
	ret                                        ; FB828D  0e                ret

; ==============================================================================
; 0xFB828E-0xFC856B -- not yet converted
; ==============================================================================
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x03828E, 0x0102DE


; ==============================================================================
; 0xFC856C-0xFC89C4 -- THE FLASH DRIVER: the 512 KiB device at 0x00E80000, the
;                      64 KiB staging buffer at 0x00010000, and the three jobs
;                      CPU 1 drives through the inter-processor link.
;                      16 routines, 1,113 bytes
; ==============================================================================
;
; ★★ THIS CLOSES Link_ServiceTask's LARGEST OPEN QUESTION.  That routine's header
; (converted above) ends "Unknown: the six 0xFC8xxx routines the three jobs call".
; All six are here, and together they say what the link is FOR:
;
;   bit 7 of 0x00852C  ->  Flash_ReadSectorToBuffer((0x00852D))
;                          Flash_ReadResetMode()
;                          Flash_SectorErase((0x00852D))
;                          -- "start a sector": copy it into RAM, then erase it
;   bit 6 of 0x00852C  ->  Flash_ReadResetMode()
;                          while (Flash_SectorBlankCheck((0x008531)) == 0xFFFF) ;
;                          Flash_ProgramSectorFromBuffer((0x008531))
;                          Link_SendCmdByte(6)   -- i.e. command 0xE6 back to CPU 1
;                          -- "commit the sector", then acknowledge
;   bit 5 of 0x00852C  ->  while (0x008536) < (0x008535):
;                              Flash_ProgramSlice1K((0x008536)++)
;                          -- "program the 1 KiB slices that have arrived so far".
;                          Link_ServiceTask holds 0x008536 in XIX for the whole
;                          routine (`lda XIX,0x008536` at 0xF99E60) and the arm's
;                          two loops both test `cp C,(0x008535)`.
;                          ⚠ SIMPLIFIED.  The real arm has two sub-paths -- one
;                          when the counter is still 0, gated on a blank check of
;                          the sector in (0x008568) that re-sets bit 5 and retries
;                          if the erase has not finished, and one when it is not,
;                          gated on (0x008537) == 1 -- and only the first sets
;                          (0x008537).  Read Link_ServiceTask for the exact shape;
;                          what is identified here is the CALL TARGET
;
; So the 0xE1/0xE2 command pair and micro-DMA channel 3 are the transport of a
; FLASH DOWNLOAD: CPU 1 pushes data into CPU 2's RAM buffer at 0x00010000 and
; CPU 2 burns it into the flash a kilobyte at a time, acknowledging with 0xE6.
; ⚠ Each of those three lines is a reading of the arms in Link_ServiceTask, whose
; own instructions are converted above; the call targets are the ones its header
; already cited, and they are what is newly identified here.  What the downloaded
; bytes ARE is still unknown.
;
; ★★ THE FLASH IS A 4-Mbit x16 BOOT-BLOCK PART, AND THE ROM PROVES ITS SECTOR MAP
; WITHOUT ANY DATASHEET.  Flash_SectorErase has two special arms, and the boot
; block they split is 64 KiB in both:
;
;     device code 0x22AB, sector 0x00E80000  ->  0x30 at +0x0000 +0x4000
;                                                +0x6000 +0x8000
;                                                = 16K, 8K, 8K, 32K
;     otherwise,          sector 0x00EF0000  ->  0x30 at +0x70000 +0x78000
;                                                +0x7A000 +0x7C000
;                                                = 32K, 8K, 8K, 16K
;
; The two maps are exact mirror images, one at the bottom of the device and one at
; the top, and the top one begins at 0x70000 -- seven 64 KiB sectors below it --
; so the device is 0x80000 = 512 KiB.
; ⚠ THIS IS NOT NEW AND IS NOT INDEPENDENT.  notes/FINDINGS-memory-map.md §2
; ("The flash, and why its size is established") already derived exactly this,
; from THIS SAME ROUTINE, before the block was converted.  What round 4 adds is
; not the size but the rest of the driver around it, and a script:
; `python3 notes/prom_c_flash_driver_check.py` asserts all four offsets on each
; arm, both size lists, the mirror relation and the 7 x 64 KiB, from the bytes --
; so the memory map's paragraph is now reproducible instead of hand-read.
;
; ⚠ THE PART NUMBER IS AN INFERENCE, AND IT IS LABELLED AS ONE -- the same
; inference notes/FINDINGS-memory-map.md §2 already records ("Am29F400B/T-class;
; that is an inference from published ID tables, with no datasheet in these
; trees").  16K/8K/8K/32K at the bottom and its mirror at the top is that family's
; sector map, and JEDEC assigns manufacturer code 0x01 to AMD and 0x04 to Fujitsu
; -- the two codes Flash_ReadDeviceId accepts.  That is EXTERNAL knowledge.  What
; this image establishes on its own is: a JEDEC-command flash, 512 KiB, 16-bit,
; with a split boot block at either end and exactly two device codes recognised
; (0x2223 and 0x22AB).  No part is named in any label here.
; ★ What round 4 DOES add to that paragraph is the manufacturer side: the memory
; map only had the device-ID compare at 0xFC8694.  Flash_ReadDeviceId shows where
; the value comes from -- a real autoselect read of the chip at boot, gated on
; manufacturer code 1 or 4 -- so 0x00E29D holds what the silicon answered and not
; a build-time constant.
;
; ★ THE STAGING BUFFER IS AT 0x00010000 AND IS ONE WHOLE SECTOR.
; Flash_ReadSectorToBuffer, Flash_ProgramSectorFromBuffer and Flash_ProgramSlice1K
; all load 0x00010000 into XIX and mask their flash argument with 0x00FF0000, and
; the block routines compute their destination as `flash address - 0x00E70000`,
; which is 0x00010000 + (address - 0x00E80000).  ⚠ SO THE BUFFER SHADOWS THE FIRST
; 64 KiB OF THE FLASH ONLY: for a sector above 0x00E8FFFF the block writers would
; address past the buffer.  Stated as read; nothing here says the firmware ever
; does that.  This also fills in one row of notes/FINDINGS-memory-map.md, whose
; CS3 range 0x010080-0x01FFFF was "NOT ESTABLISHED".
;
; ★ ONE LOOP COUNTS WITH AN 8-BIT REGISTER WHERE ITS TWO SIBLINGS USE 16.
; Flash_ProgramSectorFromBuffer (0xFC8935) and Flash_ProgramSlice1K (0xFC8989)
; both end their loop with `djnz BC` -- prefix byte 0xD9, the 16-bit register BC --
; and cover 0x8000 and 0x0200 words respectively.  Flash_SectorBlankCheck loads
; `ld BC,0x4000` and then ends its loop with `djnz B` at 0xFC89A5 -- prefix byte
; 0xCA, the 8-BIT register B, which is the HIGH byte of BC.  B is therefore 0x40,
; the loop runs 64 times, and since each pass compares a 32-bit long the routine
; inspects the FIRST 256 BYTES of the sector and not the 64 KiB the 0x4000 implies.
; The prefix->register mapping is MAME's: oC8()/oD8() and get_reg8_current()
; in mame/src/devices/cpu/tlcs900/900tbl.hxx (lines 115-150, 5672-5690).
; ⚠ Recorded as what the bytes say.  Whether it is a defect or a deliberate short
; poll is NOT established -- as an "is the erase finished" poll a 256-byte sample
; is adequate, and every caller uses it only that way.
; `notes/prom_c_flash_driver_check.py` asserts both prefix bytes and all three
; counts.
;
; ⚠ WHAT THIS BLOCK DOES NOT ESTABLISH: what is stored in the flash; what
; 0x00E83232 holds (Flash_ReadResetMode reads it and every caller discards the
; value); and what the layer at 0xFC38xx-0xFC3Cxx -- three callers of
; Flash_ReprogramSector and three more of Flash_ReadSectorToBuffer -- is doing.
; That layer is the next thing to convert.
;
; --------------------------------------------------------------------------
; Flash_ReadResetMode -- put the flash back into read mode.
;
; Called from: EIGHT sites: 0xF99EB9 and 0xF99EDB (`call`, both inside
;          Link_ServiceTask, converted above), and 0xFC85F3, 0xFC8774, 0xFC8799,
;          0xFC8806, 0xFC88A0, 0xFC88EE (`calr`, all in this block).
;          `notes/prom_c_xrefs.py 0xFC856C --no-window` -- 2 literal, 6 CALR.
; Inputs:  none.
; Outputs: the JEDEC read/reset sequence on the flash at 0x00E80000 --
;          (0x00E8AAAA) = 0xAA, (0x00E85554) = 0x55, (0x00E8AAAA) = 0xF0 -- and
;          then WA = the 16-bit word read from 0x00E83232.
; Evidence: byte-checked.  `python3 notes/prom_c_flash_driver_check.py` asserts
;          the two unlock addresses and every command byte in this block against
;          the ROM image, matching BYTES and not disassembler text.
; Unknown:  ⚠ why it reads 0x00E83232.  The read is real (`ld BC,(XIX+0x3232)` at
;          0xFC8593 with XIX = 0x00E80000) and the value is returned, but every
;          caller in this image discards WA.  A dummy read to complete the reset
;          is one reading and a fixed word stored in the flash is another;
;          nothing here decides between them.
; --------------------------------------------------------------------------
Flash_ReadResetMode:
	link32 0xEE, 0x0C, 0xFC, 0xFF          ; FC856C  link XIZ,0xfffc   [llvm-mc cannot encode this]
	push	xix                               ; FC8570  push XIX
	ld	xix, 0xE80000                       ; FC8571  ld XIX,0x00e80000
	ld	xbc, xix                            ; FC8576  ld XBC,XIX
	add	xbc, 0xAAAA                        ; FC8578  add XBC,0x0000aaaa
	ld	(xiz-4), xbc                        ; FC857E  ld (XIZ+0xfc),XBC
	extpfx4 0xB1, 0x02, 0xAA, 0x00         ; FC8581  ld (XBC),0x00aa   [llvm-mc cannot encode this]
	extpfx7 0xF3, 0xF1, 0x54, 0x55, 0x02, 0x55, 0x00 ; FC8585  ld (XIX+0x5554),0x0055   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC858C  ld XBC,(XIZ+0xfc)
	extpfx4 0xB1, 0x02, 0xF0, 0x00         ; FC858F  ld (XBC),0x00f0   [llvm-mc cannot encode this]
	ld	bc, (xix+0x3232)                    ; FC8593  ld BC,(XIX+0x3232)
	ld	wa, bc                              ; FC8598  ld WA,BC
	pop	xix                                ; FC859A  pop XIX
	unlk32 xiz                             ; FC859B  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC859D  ret
; --------------------------------------------------------------------------
; ★★ Flash_ReadDeviceId -- JEDEC autoselect: read the manufacturer and device
;                     codes out of the flash, and recognise exactly two parts.
;
; Called from: 0xFC88A3 (`calr`), ONE site -- Flash_ProbeAndStoreDeviceId, below.
; Inputs:  none.
; Outputs: (0x00E29F) = the 16-bit MANUFACTURER code read from 0x00E80000.
;          WA = the 16-bit DEVICE code read from 0x00E80002 if the pair is
;          recognised, otherwise 0xFFFF -- IX is preloaded with 0xFFFF at
;          0xFC85AD and is only overwritten on a match.
;          ⚠ THE RESET IS ON THE MATCHING PATH ONLY.  `calr Flash_ReadResetMode`
;          is at 0xFC85F3, and 0xFC85E1 `jr NZ,0xFC85F6` jumps PAST it when the
;          manufacturer word is neither 1 nor 4.  So on an unrecognised part this
;          routine returns with the device still in autoselect mode, where reads
;          return ID words rather than data.  Its one caller
;          (Flash_ProbeAndStoreDeviceId) does not reset it afterwards either.
;          Stated as the instructions read; no claim that it ever happens.
; Evidence: (0x00E8AAAA)=0xAA / (0x00E85554)=0x55 / (0x00E8AAAA)=0x90 is JEDEC
;          autoselect, and the two reads that follow are at base+0 and base+2.
;          The four literals it tests are asserted from the ROM bytes by
;          `python3 notes/prom_c_flash_driver_check.py`: manufacturer 1
;          (`cp DE,1` at 0xFC85DB) or 4 (0xFC85DF), device 0x2223 (0xFC85E3) or
;          0x22AB (0xFC85EB).
;          ⚠ The manufacturer test GATES the device test but the device value is
;          what is returned, and the two device comparisons are written as two
;          independent `cp / jr NZ / ld IX,HL` pairs rather than a switch -- so a
;          part answering 0x2223 is accepted exactly as one answering 0x22AB, and
;          only 0x22AB gets the special boot map in Flash_SectorErase.
; Unknown:  the meaning of the codes is external knowledge; see the block comment
;          above for what is and is not established from this image.
; --------------------------------------------------------------------------
Flash_ReadDeviceId:
	link32 0xEE, 0x0C, 0xF8, 0xFF          ; FC859E  link XIZ,0xfff8   [llvm-mc cannot encode this]
	pushw	hl                               ; FC85A2  push HL
	pushw	de                               ; FC85A3  push DE
	pushw	ix                               ; FC85A4  push IX
	ld	xbc, 0xE80000                       ; FC85A5  ld XBC,0x00e80000
	ld	(xiz-4), xbc                        ; FC85AA  ld (XIZ+0xfc),XBC
	ldw	ix, 0xFFFF                         ; FC85AD  ld IX,0xffff
	add	xbc, 0xAAAA                        ; FC85B0  add XBC,0x0000aaaa
	ld	(xiz-8), xbc                        ; FC85B6  ld (XIZ+0xf8),XBC
	extpfx4 0xB1, 0x02, 0xAA, 0x00         ; FC85B9  ld (XBC),0x00aa   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC85BD  ld XBC,(XIZ+0xfc)
	extpfx7 0xF3, 0xE5, 0x54, 0x55, 0x02, 0x55, 0x00 ; FC85C0  ld (XBC+0x5554),0x0055   [llvm-mc cannot encode this]
	ld	xbc, (xiz-8)                        ; FC85C7  ld XBC,(XIZ+0xf8)
	extpfx4 0xB1, 0x02, 0x90, 0x00         ; FC85CA  ld (XBC),0x0090   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC85CE  ld XBC,(XIZ+0xfc)
	ld	de, (xbc)                           ; FC85D1  ld DE,(XBC)
	stw_da	(0xE29F), de                    ; FC85D3  ld (0x00e29f),DE
	ld	hl, (xbc+2)                         ; FC85D8  ld HL,(XBC+0x02)
	cps	de, 1                              ; FC85DB  cp DE,1
	jr z, Flash_ReadDeviceId__FC85E3                        ; FC85DD  jr Z,0xfc85e3
	cps	de, 4                              ; FC85DF  cp DE,4
	jr nz, Flash_ReadDeviceId__FC85F6                       ; FC85E1  jr NZ,0xfc85f6
Flash_ReadDeviceId__FC85E3:
	cp	hl, 0x2223                          ; FC85E3  cp HL,0x2223
	jr nz, Flash_ReadDeviceId__FC85EB                       ; FC85E7  jr NZ,0xfc85eb
	ld	ix, hl                              ; FC85E9  ld IX,HL
Flash_ReadDeviceId__FC85EB:
	cp	hl, 0x22AB                          ; FC85EB  cp HL,0x22ab
	jr nz, Flash_ReadDeviceId__FC85F3                       ; FC85EF  jr NZ,0xfc85f3
	ld	ix, hl                              ; FC85F1  ld IX,HL
Flash_ReadDeviceId__FC85F3:
	calr (0xFC856C - 0xFC85F6)             ; FC85F3  calr 0xfc856c
Flash_ReadDeviceId__FC85F6:
	ld	wa, ix                              ; FC85F6  ld WA,IX
	popw	ix                                ; FC85F8  pop IX
	popw	de                                ; FC85F9  pop DE
	popw	hl                                ; FC85FA  pop HL
	unlk32 xiz                             ; FC85FB  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC85FD  ret
; --------------------------------------------------------------------------
; Flash_ChipErase -- erase the ENTIRE flash device.
;
; Called from: NOT FOUND.  `notes/prom_c_xrefs.py 0xFC85FE --no-window` reports no
;          literal and no calr reaching it; short PC-relative forms are not
;          searched, so this is "not found", never "unreachable".
; Inputs:  none.
; Outputs: the six-cycle JEDEC chip-erase command -- AA / 55 / 0x80 then
;          AA / 55 / 0x10, all through 0x00E8AAAA and 0x00E85554.
;          ⚠ It does NOT wait for completion and returns immediately.
; Evidence: the six command bytes are asserted from the ROM by
;          `notes/prom_c_flash_driver_check.py`; 0x10 after the 0x80 setup is
;          what distinguishes chip erase from the 0x30 of Flash_SectorErase.
; --------------------------------------------------------------------------
Flash_ChipErase:
	link32 0xEE, 0x0C, 0xF8, 0xFF          ; FC85FE  link XIZ,0xfff8   [llvm-mc cannot encode this]
	push	xix                               ; FC8602  push XIX
	ld	xix, 0xE80000                       ; FC8603  ld XIX,0x00e80000
	ld	xbc, xix                            ; FC8608  ld XBC,XIX
	add	xbc, 0xAAAA                        ; FC860A  add XBC,0x0000aaaa
	ld	(xiz-4), xbc                        ; FC8610  ld (XIZ+0xfc),XBC
	extpfx4 0xB1, 0x02, 0xAA, 0x00         ; FC8613  ld (XBC),0x00aa   [llvm-mc cannot encode this]
	ld	xbc, xix                            ; FC8617  ld XBC,XIX
	add	xbc, 0x5554                        ; FC8619  add XBC,0x00005554
	ld	(xiz-8), xbc                        ; FC861F  ld (XIZ+0xf8),XBC
	extpfx4 0xB1, 0x02, 0x55, 0x00         ; FC8622  ld (XBC),0x0055   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC8626  ld XBC,(XIZ+0xfc)
	extpfx4 0xB1, 0x02, 0x80, 0x00         ; FC8629  ld (XBC),0x0080   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC862D  ld XBC,(XIZ+0xfc)
	extpfx4 0xB1, 0x02, 0xAA, 0x00         ; FC8630  ld (XBC),0x00aa   [llvm-mc cannot encode this]
	ld	xbc, (xiz-8)                        ; FC8634  ld XBC,(XIZ+0xf8)
	extpfx4 0xB1, 0x02, 0x55, 0x00         ; FC8637  ld (XBC),0x0055   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC863B  ld XBC,(XIZ+0xfc)
	extpfx4 0xB1, 0x02, 0x10, 0x00         ; FC863E  ld (XBC),0x0010   [llvm-mc cannot encode this]
	pop	xix                                ; FC8642  pop XIX
	unlk32 xiz                             ; FC8643  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC8645  ret
; --------------------------------------------------------------------------
; ★★ Flash_SectorErase -- erase one 64 KiB sector, splitting the BOOT BLOCK into
;                    its four sub-sectors, with a different map at each end.
;
; Called from: FOUR sites: 0xF99EC3 (`call`, the bit-7 job of Link_ServiceTask)
;          and 0xFC8778, 0xFC87A8, 0xFC8815 (`calr`, in this block).
;          `notes/prom_c_xrefs.py 0xFC8646 --no-window`.
; Inputs:  (XIZ+0x08) = a flash address, masked down to a 64 KiB boundary at
;          0xFC8656 (`ld XWA,0x00FF0000 / and XIX,XWA`).  It also reads
;          (0x00E29D), the device code Flash_ProbeAndStoreDeviceId stored there.
; Outputs: AA / 55 / 0x80 then AA / 55 / 0x30 -- JEDEC sector erase -- with the
;          0x30 issued once per sub-sector.  Interrupts are raised to level 6 for
;          the whole sequence (`ei 6` at 0xFC865D, back to `ei 0` at 0xFC8713).
;          ⚠ It does not wait; Flash_SectorBlankCheck is the completion poll.
; Evidence: three arms, all four offsets of each asserted from the ROM bytes by
;          `python3 notes/prom_c_flash_driver_check.py`:
;            (0x00E29D) == 0x22AB and sector == 0x00E80000
;                -> 0x30 at +0x0000, +0x4000, +0x6000, +0x8000   (16K 8K 8K 32K)
;            device code anything else, and sector == 0x00EF0000
;                -> 0x30 at +0x70000, +0x78000, +0x7A000, +0x7C000 (32K 8K 8K 16K)
;            neither
;                -> a single 0x30 at the sector base
; Unknown:  ⚠ the two arms are keyed on DIFFERENT things -- the first on the device
;          code AND the address, the second on the address alone.  So device code
;          0x22AB with sector 0x00EF0000, or 0x2223 with sector 0x00E80000, both
;          fall through to the single-0x30 arm, which on a split boot block would
;          erase only its first sub-sector.  Recorded as the instructions read; no
;          claim that either combination ever occurs.
; --------------------------------------------------------------------------
Flash_SectorErase:
	link32 0xEE, 0x0C, 0xF4, 0xFF          ; FC8646  link XIZ,0xfff4   [llvm-mc cannot encode this]
	push	xix                               ; FC864A  push XIX
	ld	xbc, 0xE80000                       ; FC864B  ld XBC,0x00e80000
	ld	(xiz-4), xbc                        ; FC8650  ld (XIZ+0xfc),XBC
	ld	xix, (xiz+8)                        ; FC8653  ld XIX,(XIZ+0x08)
	ld	xwa, 0xFF0000                       ; FC8656  ld XWA,0x00ff0000
	and	xix, xwa                           ; FC865B  and XIX,XWA
	ei	6                                   ; FC865D  ei 0x06
	ld	xbc, (xiz-4)                        ; FC865F  ld XBC,(XIZ+0xfc)
	add	xbc, 0xAAAA                        ; FC8662  add XBC,0x0000aaaa
	ld	(xiz-8), xbc                        ; FC8668  ld (XIZ+0xf8),XBC
	extpfx4 0xB1, 0x02, 0xAA, 0x00         ; FC866B  ld (XBC),0x00aa   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC866F  ld XBC,(XIZ+0xfc)
	add	xbc, 0x5554                        ; FC8672  add XBC,0x00005554
	ld	(xiz-12), xbc                       ; FC8678  ld (XIZ+0xf4),XBC
	extpfx4 0xB1, 0x02, 0x55, 0x00         ; FC867B  ld (XBC),0x0055   [llvm-mc cannot encode this]
	ld	xbc, (xiz-8)                        ; FC867F  ld XBC,(XIZ+0xf8)
	extpfx4 0xB1, 0x02, 0x80, 0x00         ; FC8682  ld (XBC),0x0080   [llvm-mc cannot encode this]
	ld	xbc, (xiz-8)                        ; FC8686  ld XBC,(XIZ+0xf8)
	extpfx4 0xB1, 0x02, 0xAA, 0x00         ; FC8689  ld (XBC),0x00aa   [llvm-mc cannot encode this]
	ld	xbc, (xiz-12)                       ; FC868D  ld XBC,(XIZ+0xf4)
	extpfx4 0xB1, 0x02, 0x55, 0x00         ; FC8690  ld (XBC),0x0055   [llvm-mc cannot encode this]
	extpfx7 0xD2, 0x9D, 0xE2, 0x00, 0x3F, 0xAB, 0x22 ; FC8694  cp (0x00e29d),0x22ab   [llvm-mc cannot encode this]
	jr nz, Flash_SectorErase__FC86CF                       ; FC869B  jr NZ,0xfc86cf
	cp	xix, 0xE80000                       ; FC869D  cp XIX,0x00e80000
	jr nz, Flash_SectorErase__FC870D                       ; FC86A3  jr NZ,0xfc870d
	ld	xbc, (xiz-4)                        ; FC86A5  ld XBC,(XIZ+0xfc)
	extpfx4 0xB1, 0x02, 0x30, 0x00         ; FC86A8  ld (XBC),0x0030   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC86AC  ld XBC,(XIZ+0xfc)
	extpfx7 0xF3, 0xE5, 0x00, 0x40, 0x02, 0x30, 0x00 ; FC86AF  ld (XBC+0x4000),0x0030   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC86B6  ld XBC,(XIZ+0xfc)
	extpfx7 0xF3, 0xE5, 0x00, 0x60, 0x02, 0x30, 0x00 ; FC86B9  ld (XBC+0x6000),0x0030   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC86C0  ld XBC,(XIZ+0xfc)
	add	xbc, 0x8000                        ; FC86C3  add XBC,0x00008000
	extpfx4 0xB1, 0x02, 0x30, 0x00         ; FC86C9  ld (XBC),0x0030   [llvm-mc cannot encode this]
	jr Flash_SectorErase__FC8713                           ; FC86CD  jr T,0xfc8713
Flash_SectorErase__FC86CF:
	cp	xix, 0xEF0000                       ; FC86CF  cp XIX,0x00ef0000
	jr nz, Flash_SectorErase__FC870D                       ; FC86D5  jr NZ,0xfc870d
	ld	xbc, (xiz-4)                        ; FC86D7  ld XBC,(XIZ+0xfc)
	add	xbc, 0x70000                       ; FC86DA  add XBC,0x00070000
	extpfx4 0xB1, 0x02, 0x30, 0x00         ; FC86E0  ld (XBC),0x0030   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC86E4  ld XBC,(XIZ+0xfc)
	add	xbc, 0x78000                       ; FC86E7  add XBC,0x00078000
	extpfx4 0xB1, 0x02, 0x30, 0x00         ; FC86ED  ld (XBC),0x0030   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC86F1  ld XBC,(XIZ+0xfc)
	add	xbc, 0x7A000                       ; FC86F4  add XBC,0x0007a000
	extpfx4 0xB1, 0x02, 0x30, 0x00         ; FC86FA  ld (XBC),0x0030   [llvm-mc cannot encode this]
	ld	xbc, (xiz-4)                        ; FC86FE  ld XBC,(XIZ+0xfc)
	add	xbc, 0x7C000                       ; FC8701  add XBC,0x0007c000
	extpfx4 0xB1, 0x02, 0x30, 0x00         ; FC8707  ld (XBC),0x0030   [llvm-mc cannot encode this]
	jr Flash_SectorErase__FC8713                           ; FC870B  jr T,0xfc8713
Flash_SectorErase__FC870D:
	ld	xbc, xix                            ; FC870D  ld XBC,XIX
	extpfx4 0xB1, 0x02, 0x30, 0x00         ; FC870F  ld (XBC),0x0030   [llvm-mc cannot encode this]
Flash_SectorErase__FC8713:
	di                                     ; FC8713  ei 0x00
	pop	xix                                ; FC8715  pop XIX
	unlk32 xiz                             ; FC8716  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC8718  ret
; --------------------------------------------------------------------------
; DSP_WriteChans0to3_FromE29D -- call DSP_ChannelRegs_Write8 for channels 0, 1, 2
;                     and 3, all four from the same 8 bytes at 0x00E29D.
;
; Called from: NOT FOUND (`notes/prom_c_xrefs.py 0xFC8719 --no-window`: no literal,
;          no calr; short PC-relative forms are not searched).
; Inputs:  the 8 bytes at 0x00E29D.
; Outputs: 32 DSP registers -- eight in each of channels 0..3 of the device at
;          0x00E00000, via DSP_ChannelRegs_Write8 (0xF9804A, converted at the top
;          of this file).
; Evidence: mechanical, and byte-asserted by
;          `python3 notes/prom_c_flash_driver_check.py`.  `lda XIX,0xF9804A` at
;          0xFC871A takes that routine's address; each of the four blocks does
;          `push &0x00E29D / push #n / push &<next block> / jp XIX` for
;          n = 0, 1, 2, 3 -- a hand-built call whose "return address" is the last
;          push, so the callee's `ret` lands on the following block.  That places
;          the channel at (XSP+4) and the pointer at (XSP+6), which is exactly
;          DSP_ChannelRegs_Write8's documented convention, and 0xFC8763 then drops
;          0x18 = 24 = 4 x 6 argument bytes.
; Unknown:  ⚠ WHAT IT IS FOR, and why it sits inside the flash driver.  0x00E29D
;          is where Flash_ProbeAndStoreDeviceId stores the device code and
;          0x00E29F is where Flash_ReadDeviceId stores the manufacturer code, so
;          the first four of the eight bytes handed to each DSP channel are the
;          two flash ID words.  Whether that is deliberate or whether 0x00E29D is
;          simply a scratch buffer two unrelated things share is NOT established.
; --------------------------------------------------------------------------
DSP_WriteChans0to3_FromE29D:
	push	xix                               ; FC8719  push XIX
	lda_24	xix, (0xF9804A)                 ; FC871A  lda XIX,0xf9804a
	lda_24	xbc, (0xE29D)                   ; FC871F  lda XBC,0x00e29d
	push	xbc                               ; FC8724  push XBC
	pushw	0                                ; FC8725  push 0x0000
	lda_24	xiy, (0xFC8730)                 ; FC8728  lda XIY,0xfc8730
	push	xiy                               ; FC872D  push XIY
	jp	(xix)                               ; FC872E  jp T,XIX
	lda_24	xbc, (0xE29D)                   ; FC8730  lda XBC,0x00e29d
	push	xbc                               ; FC8735  push XBC
	pushw	1                                ; FC8736  push 0x0001
	lda_24	xiy, (0xFC8741)                 ; FC8739  lda XIY,0xfc8741
	push	xiy                               ; FC873E  push XIY
	jp	(xix)                               ; FC873F  jp T,XIX
	lda_24	xbc, (0xE29D)                   ; FC8741  lda XBC,0x00e29d
	push	xbc                               ; FC8746  push XBC
	pushw	2                                ; FC8747  push 0x0002
	lda_24	xiy, (0xFC8752)                 ; FC874A  lda XIY,0xfc8752
	push	xiy                               ; FC874F  push XIY
	jp	(xix)                               ; FC8750  jp T,XIX
	lda_24	xbc, (0xE29D)                   ; FC8752  lda XBC,0x00e29d
	push	xbc                               ; FC8757  push XBC
	pushw	3                                ; FC8758  push 0x0003
	lda_24	xiy, (0xFC8763)                 ; FC875B  lda XIY,0xfc8763
	push	xiy                               ; FC8760  push XIY
	jp	(xix)                               ; FC8761  jp T,XIX
	add	xsp, 24                            ; FC8763  add XSP,0x00000018
	pop	xix                                ; FC8769  pop XIX
	ret                                    ; FC876A  ret
; --------------------------------------------------------------------------
; sub_FC876B -- one `ret`, nothing else.
;
; Called from: NOT FOUND (`notes/prom_c_xrefs.py 0xFC876B --no-window`).
; Evidence: the single byte 0x0E at 0xFC876B, between the `ret` that ends
;          DSP_WriteChans0to3_FromE29D and the `link` that starts
;          Flash_ReprogramSector.  Named, not interpreted: this file already has
;          one such stub (Link_ChannelHandler_Ignore) that turned out to be a
;          pointer-table entry, so a lone `ret` is worth a label even when
;          nothing found reaches it.
; --------------------------------------------------------------------------
sub_FC876B:
	ret                                    ; FC876B  ret
; --------------------------------------------------------------------------
; Flash_ReprogramSector -- erase one sector and burn the staging buffer into it.
;
; Called from: 0xFC39E1, 0xFC3B17, 0xFC3CAB (`call`) -- THREE sites, all in the
;          still-unconverted stretch around 0xFC38xx-0xFC3Cxx.
;          `notes/prom_c_xrefs.py 0xFC876C --no-window`.
; Inputs:  (XIZ+0x08) = the flash sector address.  The staging buffer at
;          0x00010000 must already hold what is to be written -- this routine
;          never fills it.
; Outputs: Flash_ReadResetMode(), Flash_SectorErase(addr), then
;          `while (Flash_SectorBlankCheck(addr) == 0xFFFF) ;`, then
;          Flash_ProgramSectorFromBuffer(addr).
; Evidence: the four calls are the instructions at 0xFC8774, 0xFC8778, 0xFC877D
;          and 0xFC8789, and the wait is `cp WA,0xFFFF / jr Z,0xFC877C` at
;          0xFC8782 -- i.e. it spins while the sector is NOT yet blank, which is
;          the sense Flash_SectorBlankCheck's return value has.
; --------------------------------------------------------------------------
Flash_ReprogramSector:
	link32 0xEE, 0x0C, 0x00, 0x00          ; FC876C  link XIZ,0x0000   [llvm-mc cannot encode this]
	push	xix                               ; FC8770  push XIX
	ld	xix, (xiz+8)                        ; FC8771  ld XIX,(XIZ+0x08)
	calr (0xFC856C - 0xFC8777)             ; FC8774  calr 0xfc856c
	push	xix                               ; FC8777  push XIX
	calr (0xFC8646 - 0xFC877B)             ; FC8778  calr 0xfc8646
	pop	xiy                                ; FC877B  pop XIY
Flash_ReprogramSector__FC877C:
	push	xix                               ; FC877C  push XIX
	call	0xFC898F                          ; FC877D  call 0xfc898f
	pop	xiy                                ; FC8781  pop XIY
	cp	wa, 0xFFFF                          ; FC8782  cp WA,0xffff
	jr z, Flash_ReprogramSector__FC877C                        ; FC8786  jr Z,0xfc877c
	push	xix                               ; FC8788  push XIX
	call	0xFC88F9                          ; FC8789  call 0xfc88f9
	pop	xbc                                ; FC878D  pop XBC
	pop	xix                                ; FC878E  pop XIX
	unlk32 xiz                             ; FC878F  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC8791  ret
; --------------------------------------------------------------------------
; Flash_WriteBlockIntoSector -- patch one block into the staging buffer, then
;                     erase and reprogram the sector that holds it.
;
; Called from: 0xFC88EB (`calr`), ONE site -- Flash_WriteRampPattern_E81000.
; Inputs:  (XIZ+0x08) = source pointer; (XIZ+0x0C) = a BYTE count (halved to a
;          word count at 0xFC87C2, `srl 0x01,IY`); (XIZ+0x0E) = the flash address
;          to write at.
; Outputs: Flash_ReadResetMode(); Flash_ReadSectorToBuffer(addr);
;          Flash_SectorErase(addr); then count/2 words copied from the source to
;          `addr - 0x00E70000`, i.e. into the staging buffer at the same offset
;          the flash address has inside the device; then the blank-check spin and
;          Flash_ProgramSectorFromBuffer(addr).
; Evidence: the destination arithmetic is the single instruction
;          `sub XBC,0x00E70000` at 0xFC87AE, asserted from the bytes by
;          `notes/prom_c_flash_driver_check.py`, and 0xE80000 - 0xE70000 =
;          0x010000 is the buffer base the other three routines load literally.
;          ⚠ THE READ-MODIFY-WRITE IS WHAT MAKES THIS SAFE: the sector is copied
;          into RAM BEFORE it is erased, the caller's block overwrites part of the
;          copy, and the copy goes back.  Without that first step the erase would
;          destroy everything else in the sector.
; Unknown:  the buffer only covers 0x00E80000-0x00E8FFFF, so an address above that
;          would write past it.  Stated as read.
; --------------------------------------------------------------------------
Flash_WriteBlockIntoSector:
	link32 0xEE, 0x0C, 0xFC, 0xFF          ; FC8792  link XIZ,0xfffc   [llvm-mc cannot encode this]
	pushw	hl                               ; FC8796  push HL
	pushw	de                               ; FC8797  push DE
	push	xix                               ; FC8798  push XIX
	calr (0xFC856C - 0xFC879C)             ; FC8799  calr 0xfc856c
	ld	xbc, (xiz+14)                       ; FC879C  ld XBC,(XIZ+0x0e)
	push	xbc                               ; FC879F  push XBC
	call	0xFC89AF                          ; FC87A0  call 0xfc89af
	ld	xbc, (xiz+14)                       ; FC87A4  ld XBC,(XIZ+0x0e)
	push	xbc                               ; FC87A7  push XBC
	calr (0xFC8646 - 0xFC87AB)             ; FC87A8  calr 0xfc8646
	ld	xbc, (xiz+14)                       ; FC87AB  ld XBC,(XIZ+0x0e)
	sub	xbc, 0xE70000                      ; FC87AE  sub XBC,0x00e70000
	ld	(xiz-4), xbc                        ; FC87B4  ld (XIZ+0xfc),XBC
	ld	xix, (xiz+8)                        ; FC87B7  ld XIX,(XIZ+0x08)
	ldw	hl, 0                              ; FC87BA  ld HL,0x0000
	ld	de, (xiz+12)                        ; FC87BD  ld DE,(XIZ+0x0c)
	ld	iy, de                              ; FC87C0  ld IY,DE
	srl	iy, 1                              ; FC87C2  srl 0x01,IY
	ld	de, iy                              ; FC87C5  ld DE,IY
	inc	8, xsp                             ; FC87C7  inc 0,XSP
Flash_WriteBlockIntoSector__FC87C9:
	cp	hl, de                              ; FC87C9  cp HL,DE
	jr nc, Flash_WriteBlockIntoSector__FC87E1                       ; FC87CB  jr NC,0xfc87e1
	ld	bc, (xix)                           ; FC87CD  ld BC,(XIX)
	ld	xwa, (xiz-4)                        ; FC87CF  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FC87D2  ld (XWA),BC
	inc	2, xix                             ; FC87D4  inc 2,XIX
	sub	xbc, xbc                           ; FC87D6  sub XBC,XBC
	inc	2, xbc                             ; FC87D8  inc 2,XBC
	add	(xiz-4), xbc                       ; FC87DA  add (XIZ+0xfc),XBC
	inc	1, hl                              ; FC87DD  inc 1,HL
	jr Flash_WriteBlockIntoSector__FC87C9                           ; FC87DF  jr T,0xfc87c9
Flash_WriteBlockIntoSector__FC87E1:
	ld	xbc, (xiz+14)                       ; FC87E1  ld XBC,(XIZ+0x0e)
	push	xbc                               ; FC87E4  push XBC
	call	0xFC898F                          ; FC87E5  call 0xfc898f
	pop	xiy                                ; FC87E9  pop XIY
	cp	wa, 0xFFFF                          ; FC87EA  cp WA,0xffff
	jr z, Flash_WriteBlockIntoSector__FC87E1                        ; FC87EE  jr Z,0xfc87e1
	ld	xbc, (xiz+14)                       ; FC87F0  ld XBC,(XIZ+0x0e)
	push	xbc                               ; FC87F3  push XBC
	call	0xFC88F9                          ; FC87F4  call 0xfc88f9
	pop	xbc                                ; FC87F8  pop XBC
	pop	xix                                ; FC87F9  pop XIX
	popw	de                                ; FC87FA  pop DE
	popw	hl                                ; FC87FB  pop HL
	unlk32 xiz                             ; FC87FC  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC87FE  ret
; --------------------------------------------------------------------------
; Flash_WriteTwoBlocksIntoSector -- Flash_WriteBlockIntoSector with a second
;                     source block, written after the first.
;
; Called from: NOT FOUND (`notes/prom_c_xrefs.py 0xFC87FF --no-window`).
; Inputs:  six arguments.  (XIZ+0x08) src1, (XIZ+0x0C) byte count 1,
;          (XIZ+0x0E) the flash address -- which is also the sector that gets
;          erased and reprogrammed -- then (XIZ+0x12) src2, (XIZ+0x16) byte
;          count 2, (XIZ+0x18) the flash address for the second block.
; Outputs: identical to Flash_WriteBlockIntoSector up to 0xFC884E, then a second
;          copy loop through `(XIZ+0x18) - 0x00E70000`, and only then the
;          blank-check spin and Flash_ProgramSectorFromBuffer((XIZ+0x0E)).
; Evidence: the two copy loops at 0xFC8836 and 0xFC886A are the same eight
;          instructions with different frame offsets; the second destination uses
;          the same `sub XBC,0x00E70000` (0xFC8851, byte-asserted by
;          `notes/prom_c_flash_driver_check.py`).
;          ⚠ ONLY ONE SECTOR IS ERASED AND COMMITTED -- (XIZ+0x0E)'s.  The second
;          block therefore has to fall in the same 64 KiB sector for this to be
;          correct, and nothing in the routine checks that.  Stated as read.
; --------------------------------------------------------------------------
Flash_WriteTwoBlocksIntoSector:
	link32 0xEE, 0x0C, 0xFC, 0xFF          ; FC87FF  link XIZ,0xfffc   [llvm-mc cannot encode this]
	pushw	hl                               ; FC8803  push HL
	pushw	de                               ; FC8804  push DE
	push	xix                               ; FC8805  push XIX
	calr (0xFC856C - 0xFC8809)             ; FC8806  calr 0xfc856c
	ld	xbc, (xiz+14)                       ; FC8809  ld XBC,(XIZ+0x0e)
	push	xbc                               ; FC880C  push XBC
	call	0xFC89AF                          ; FC880D  call 0xfc89af
	ld	xbc, (xiz+14)                       ; FC8811  ld XBC,(XIZ+0x0e)
	push	xbc                               ; FC8814  push XBC
	calr (0xFC8646 - 0xFC8818)             ; FC8815  calr 0xfc8646
	ld	xbc, (xiz+14)                       ; FC8818  ld XBC,(XIZ+0x0e)
	sub	xbc, 0xE70000                      ; FC881B  sub XBC,0x00e70000
	ld	(xiz-4), xbc                        ; FC8821  ld (XIZ+0xfc),XBC
	ld	xix, (xiz+8)                        ; FC8824  ld XIX,(XIZ+0x08)
	ldw	hl, 0                              ; FC8827  ld HL,0x0000
	ld	de, (xiz+12)                        ; FC882A  ld DE,(XIZ+0x0c)
	ld	iy, de                              ; FC882D  ld IY,DE
	srl	iy, 1                              ; FC882F  srl 0x01,IY
	ld	de, iy                              ; FC8832  ld DE,IY
	inc	8, xsp                             ; FC8834  inc 0,XSP
Flash_WriteTwoBlocksIntoSector__FC8836:
	cp	hl, de                              ; FC8836  cp HL,DE
	jr nc, Flash_WriteTwoBlocksIntoSector__FC884E                       ; FC8838  jr NC,0xfc884e
	ld	bc, (xix)                           ; FC883A  ld BC,(XIX)
	ld	xwa, (xiz-4)                        ; FC883C  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FC883F  ld (XWA),BC
	inc	2, xix                             ; FC8841  inc 2,XIX
	sub	xbc, xbc                           ; FC8843  sub XBC,XBC
	inc	2, xbc                             ; FC8845  inc 2,XBC
	add	(xiz-4), xbc                       ; FC8847  add (XIZ+0xfc),XBC
	inc	1, hl                              ; FC884A  inc 1,HL
	jr Flash_WriteTwoBlocksIntoSector__FC8836                           ; FC884C  jr T,0xfc8836
Flash_WriteTwoBlocksIntoSector__FC884E:
	ld	xbc, (xiz+24)                       ; FC884E  ld XBC,(XIZ+0x18)
	sub	xbc, 0xE70000                      ; FC8851  sub XBC,0x00e70000
	ld	(xiz-4), xbc                        ; FC8857  ld (XIZ+0xfc),XBC
	ld	xix, (xiz+18)                       ; FC885A  ld XIX,(XIZ+0x12)
	ldw	hl, 0                              ; FC885D  ld HL,0x0000
	ld	de, (xiz+22)                        ; FC8860  ld DE,(XIZ+0x16)
	ld	iy, de                              ; FC8863  ld IY,DE
	srl	iy, 1                              ; FC8865  srl 0x01,IY
	ld	de, iy                              ; FC8868  ld DE,IY
Flash_WriteTwoBlocksIntoSector__FC886A:
	cp	hl, de                              ; FC886A  cp HL,DE
	jr nc, Flash_WriteTwoBlocksIntoSector__FC8882                       ; FC886C  jr NC,0xfc8882
	ld	bc, (xix)                           ; FC886E  ld BC,(XIX)
	ld	xwa, (xiz-4)                        ; FC8870  ld XWA,(XIZ+0xfc)
	ld	(xwa), bc                           ; FC8873  ld (XWA),BC
	inc	2, xix                             ; FC8875  inc 2,XIX
	sub	xbc, xbc                           ; FC8877  sub XBC,XBC
	inc	2, xbc                             ; FC8879  inc 2,XBC
	add	(xiz-4), xbc                       ; FC887B  add (XIZ+0xfc),XBC
	inc	1, hl                              ; FC887E  inc 1,HL
	jr Flash_WriteTwoBlocksIntoSector__FC886A                           ; FC8880  jr T,0xfc886a
Flash_WriteTwoBlocksIntoSector__FC8882:
	ld	xbc, (xiz+14)                       ; FC8882  ld XBC,(XIZ+0x0e)
	push	xbc                               ; FC8885  push XBC
	call	0xFC898F                          ; FC8886  call 0xfc898f
	pop	xiy                                ; FC888A  pop XIY
	cp	wa, 0xFFFF                          ; FC888B  cp WA,0xffff
	jr z, Flash_WriteTwoBlocksIntoSector__FC8882                        ; FC888F  jr Z,0xfc8882
	ld	xbc, (xiz+14)                       ; FC8891  ld XBC,(XIZ+0x0e)
	push	xbc                               ; FC8894  push XBC
	call	0xFC88F9                          ; FC8895  call 0xfc88f9
	pop	xbc                                ; FC8899  pop XBC
	pop	xix                                ; FC889A  pop XIX
	popw	de                                ; FC889B  pop DE
	popw	hl                                ; FC889C  pop HL
	unlk32 xiz                             ; FC889D  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC889F  ret
; --------------------------------------------------------------------------
; Flash_ProbeAndStoreDeviceId -- reset the flash, read its ID, remember it.
;
; Called from: 0xF98B85 (`call`) -- ONE site, in MAIN's start-up sequence.
;          `notes/prom_c_xrefs.py 0xFC88A0 --no-window`.
; Inputs:  none.
; Outputs: (0x00E29D) = the device code Flash_ReadDeviceId returned (0x2223,
;          0x22AB or 0xFFFF); (0x00E29F) = the manufacturer code, written by
;          Flash_ReadDeviceId itself.
; Evidence: three instructions, no frame: `calr Flash_ReadResetMode` (0xFC88A0),
;          `calr Flash_ReadDeviceId` (0xFC88A3), `ld (0x00E29D),WA` (0xFC88A6,
;          byte-asserted by `notes/prom_c_flash_driver_check.py`).
;          ★ This is what makes Flash_SectorErase's `cp (0x00E29D),0x22AB` a test
;          of the REAL part in the machine rather than of a build-time constant --
;          the value is sampled from the device at boot.
; --------------------------------------------------------------------------
Flash_ProbeAndStoreDeviceId:
	calr (0xFC856C - 0xFC88A3)             ; FC88A0  calr 0xfc856c
	calr (0xFC859E - 0xFC88A6)             ; FC88A3  calr 0xfc859e
	stw_da	(0xE29D), wa                    ; FC88A6  ld (0x00e29d),WA
	ret                                    ; FC88AB  ret
; --------------------------------------------------------------------------
; MemFillWordRamp -- fill a word array with 0, 1, 2, ... n-1.
;
; Called from: 0xFC88E0 (`calr`), ONE site -- Flash_WriteRampPattern_E81000.
; Inputs:  (XIZ+0x08) = destination pointer; (XIZ+0x0C) = the number of WORDS.
; Outputs: dest[i] = i for i = 0 .. count-1, 16 bits each.
; Evidence: `ld (XIX),HL / inc 2,XIX / inc 1,HL` with the bound
;          `cp HL,(XIZ+0x0c) / jr C` -- the store is 2 bytes wide and the pointer
;          advances by 2, so the count is in words.  Named for what it does; it is
;          not flash-specific and its one caller is the pattern writer below.
; --------------------------------------------------------------------------
MemFillWordRamp:
	link32 0xEE, 0x0C, 0x00, 0x00          ; FC88AC  link XIZ,0x0000   [llvm-mc cannot encode this]
	pushw	hl                               ; FC88B0  push HL
	push	xix                               ; FC88B1  push XIX
	ld	xix, (xiz+8)                        ; FC88B2  ld XIX,(XIZ+0x08)
	ldw	hl, 0                              ; FC88B5  ld HL,0x0000
	jr MemFillWordRamp__FC88C0                           ; FC88B8  jr T,0xfc88c0
MemFillWordRamp__FC88BA:
	ld	(xix), hl                           ; FC88BA  ld (XIX),HL
	inc	2, xix                             ; FC88BC  inc 2,XIX
	inc	1, hl                              ; FC88BE  inc 1,HL
MemFillWordRamp__FC88C0:
	extpfx3 0x9E, 0x0C, 0xF3               ; FC88C0  cp HL,(XIZ+0x0c)   [llvm-mc cannot encode this]
	jr c, MemFillWordRamp__FC88BA                        ; FC88C3  jr C,0xfc88ba
	pop	xix                                ; FC88C5  pop XIX
	popw	hl                                ; FC88C6  pop HL
	unlk32 xiz                             ; FC88C7  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC88C9  ret
; --------------------------------------------------------------------------
; Flash_WriteRampPattern_E81000 -- build a counting pattern in RAM and burn it to
;                     the flash at 0x00E81000.  A test or factory routine.
;
; Called from: NOT FOUND (`notes/prom_c_xrefs.py 0xFC88CA --no-window`).
; Inputs:  none -- every value is an immediate.
; Outputs: MemFillWordRamp(0x0000F000, 0x0100), i.e. 256 words 0..0xFF at
;          0x0000F000; then Flash_WriteBlockIntoSector(0x0000F000, 0x0100,
;          0x00E81000), which writes 0x0100/2 = 128 words = 256 bytes of that
;          ramp into the flash; then Flash_ReadResetMode.
; Evidence: `ld IX,0xF000 / extz XIX` (0xFC88CF) gives the 24-bit pointer
;          0x0000F000, and the two `push 0x0100` are the same immediate used as a
;          WORD count by MemFillWordRamp and as a BYTE count by
;          Flash_WriteBlockIntoSector -- which is why the ramp filled is twice as
;          long as the part written.  Stated as read.
; Unknown:  ⚠ what it is for.  Writing an ascending pattern into a fixed flash
;          address and never reading it back is what a production test looks like,
;          but nothing here calls it and nothing here verifies the result.
; --------------------------------------------------------------------------
Flash_WriteRampPattern_E81000:
	link32 0xEE, 0x0C, 0xFC, 0xFF          ; FC88CA  link XIZ,0xfffc   [llvm-mc cannot encode this]
	push	xix                               ; FC88CE  push XIX
	ldw	ix, 0xF000                         ; FC88CF  ld IX,0xf000
	extz	xix                               ; FC88D2  extz XIX
	ld	xbc, 0xE81000                       ; FC88D4  ld XBC,0x00e81000
	ld	(xiz-4), xbc                        ; FC88D9  ld (XIZ+0xfc),XBC
	pushw	0x100                            ; FC88DC  push 0x0100
	push	xix                               ; FC88DF  push XIX
	calr (0xFC88AC - 0xFC88E3)             ; FC88E0  calr 0xfc88ac
	ld	xbc, (xiz-4)                        ; FC88E3  ld XBC,(XIZ+0xfc)
	push	xbc                               ; FC88E6  push XBC
	pushw	0x100                            ; FC88E7  push 0x0100
	push	xix                               ; FC88EA  push XIX
	calr (0xFC8792 - 0xFC88EE)             ; FC88EB  calr 0xfc8792
	calr (0xFC856C - 0xFC88F1)             ; FC88EE  calr 0xfc856c
	inc	8, xsp                             ; FC88F1  inc 0,XSP
	inc	8, xsp                             ; FC88F3  inc 0,XSP
	pop	xix                                ; FC88F5  pop XIX
	unlk32 xiz                             ; FC88F6  unlk XIZ   [llvm-mc cannot encode this]
	ret                                    ; FC88F8  ret
; --------------------------------------------------------------------------
; ★ Flash_ProgramSectorFromBuffer -- burn the whole 64 KiB staging buffer into one
;                     sector, word by word, skipping words that are 0xFFFF.
;
; Called from: FOUR sites: 0xF99EF6 (`call`, the bit-6 job of Link_ServiceTask),
;          0xFC8789, 0xFC87F4, 0xFC8895 (in this block).
;          `notes/prom_c_xrefs.py 0xFC88F9 --no-window`.
; Inputs:  (XSP+4) = a flash address; no stack frame.  Masked to its 64 KiB
;          sector at 0xFC8908.  Source: the staging buffer at 0x00010000.
; Outputs: for each of 0x8000 words: if the buffer word is 0xFFFF it is skipped
;          (an erased cell already reads 0xFFFF); otherwise AA / 55 / 0xA0 --
;          the JEDEC word-program command -- then the word is written to the flash
;          and re-read until it matches (`cp (XIY),WA / jr NZ` at 0xFC892F), which
;          is the data-polling completion test.  Interrupts are raised to level 6
;          around each program cycle and lowered again before the poll.
; Evidence: `ld BC,0x8000` at 0xFC890E and `djnz BC` at 0xFC8935 (prefix byte
;          0xD9 = the 16-bit BC), so 0x8000 words = 65,536 bytes = one whole
;          sector.  Both are asserted from the ROM by
;          `python3 notes/prom_c_flash_driver_check.py`.
; Unknown:  the skip means this can only ever turn 1 bits into 0 bits, which is
;          what flash does -- so the caller must have erased the sector first.
;          Every caller in this image does.
; --------------------------------------------------------------------------
Flash_ProgramSectorFromBuffer:
	ld	xiy, (xsp+4)                        ; FC88F9  ld XIY,(XSP+0x04)
	push	xhl                               ; FC88FC  push XHL
	push	xix                               ; FC88FD  push XIX
	ld	xhl, 0xE8AAAA                       ; FC88FE  ld XHL,0x00e8aaaa
	ld	xix, 0x10000                        ; FC8903  ld XIX,0x00010000
	and	xiy, 0xFF0000                      ; FC8908  and XIY,0x00ff0000
	ldw	bc, 0x8000                         ; FC890E  ld BC,0x8000
	ld_spiw	wa, 0xF1                       ; FC8911  ld WA,(XIX+)
	cp	wa, 0xFFFF                          ; FC8914  cp WA,0xffff
	jr z, Flash_ProgramSectorFromBuffer__FC8933                        ; FC8918  jr Z,0xfc8933
	ei	6                                   ; FC891A  ei 0x06
	extpfx4 0xB3, 0x02, 0xAA, 0x00         ; FC891C  ld (XHL),0x00aa   [llvm-mc cannot encode this]
	stiw_da	(0xE85554), 85                 ; FC8920  ld (0xe85554),0x0055
	extpfx4 0xB3, 0x02, 0xA0, 0x00         ; FC8927  ld (XHL),0x00a0   [llvm-mc cannot encode this]
	ld	(xiy), wa                           ; FC892B  ld (XIY),WA
	di                                     ; FC892D  ei 0x00
Flash_ProgramSectorFromBuffer__FC892F:
	cp	(xiy), wa                           ; FC892F  cp (XIY),WA
	jr nz, Flash_ProgramSectorFromBuffer__FC892F                       ; FC8931  jr NZ,0xfc892f
Flash_ProgramSectorFromBuffer__FC8933:
	inc	2, xiy                             ; FC8933  inc 2,XIY
	djnz16	bc, -39                         ; FC8935  djnz BC,0xfc8911
	pop	xix                                ; FC8938  pop XIX
	pop	xhl                                ; FC8939  pop XHL
	ret                                    ; FC893A  ret
; --------------------------------------------------------------------------
; ★★ Flash_ProgramSlice1K -- burn ONE 1 KiB slice of the staging buffer into the
;                     matching 1 KiB of the sector.  This is the routine the
;                     inter-processor link drives.
;
; Called from: 0xF99F32 and 0xF99F5E (`call`) -- TWO sites, both the bit-5 job of
;          Link_ServiceTask, which calls it once per slice index while a counter
;          is below a limit byte (see Inputs).
;          `notes/prom_c_xrefs.py 0xFC893B --no-window`.
; Inputs:  (XSP+4) = the slice INDEX, one byte, no stack frame.  The sector comes
;          from the 32-bit variable (0x008568), masked with 0x00FF0000; the source
;          is the staging buffer at 0x00010000.  The index the two call sites pass
;          is the byte at 0x008536 and the bound they test it against is the byte
;          at 0x008535 -- both read off Link_ServiceTask, not off this routine.
; Outputs: the same AA / 55 / 0xA0 word-program loop as
;          Flash_ProgramSectorFromBuffer, restricted to
;          buffer[index*0x400 .. index*0x400+0x3FF] -> sector[same offset].
; Evidence: `extz WA / sll 0x0a,WA / extz XWA / or XIX,XWA / or XIY,XWA` at
;          0xFC8957-0xFC8960 scales the index by 1 << 10 = 1024 and ORs it into
;          BOTH the buffer pointer and the flash pointer, so the two stay aligned;
;          `ld BC,0x0200` at 0xFC8962 with `djnz BC` at 0xFC8989 (prefix 0xD9, the
;          16-bit BC) is 512 words = 1,024 bytes, which is exactly the 1 << 10 the
;          index was scaled by.  The shift, the count and the prefix byte are all
;          asserted from the ROM by `python3 notes/prom_c_flash_driver_check.py`.
; Unknown:  ⚠ `or` is used rather than `add`, so an index of 0x40 or more would
;          collide with the sector bits instead of overflowing cleanly.  With a
;          64 KiB sector the valid range is 0..0x3F.  Nothing here bounds it; the
;          caller's counter is what limits it.
; --------------------------------------------------------------------------
Flash_ProgramSlice1K:
	ld	a, (xsp+4)                          ; FC893B  ld A,(XSP+0x04)
	push	xhl                               ; FC893E  push XHL
	push	xix                               ; FC893F  push XIX
	ld	xhl, 0xE8AAAA                       ; FC8940  ld XHL,0x00e8aaaa
	ld	xix, 0x10000                        ; FC8945  ld XIX,0x00010000
	lda_24	xiy, (0x8568)                   ; FC894A  lda XIY,0x008568
	ld	xiy, (xiy)                          ; FC894F  ld XIY,(XIY)
	and	xiy, 0xFF0000                      ; FC8951  and XIY,0x00ff0000
	extz	wa                                ; FC8957  extz WA
	sll	wa, 10                             ; FC8959  sll 0x0a,WA
	extz	xwa                               ; FC895C  extz XWA
	or	xix, xwa                            ; FC895E  or XIX,XWA
	or	xiy, xwa                            ; FC8960  or XIY,XWA
	ldw	bc, 0x200                          ; FC8962  ld BC,0x0200
	ld_spiw	wa, 0xF1                       ; FC8965  ld WA,(XIX+)
	cp	wa, 0xFFFF                          ; FC8968  cp WA,0xffff
	jr z, Flash_ProgramSlice1K__FC8987                        ; FC896C  jr Z,0xfc8987
	ei	6                                   ; FC896E  ei 0x06
	extpfx4 0xB3, 0x02, 0xAA, 0x00         ; FC8970  ld (XHL),0x00aa   [llvm-mc cannot encode this]
	stiw_da	(0xE85554), 85                 ; FC8974  ld (0xe85554),0x0055
	extpfx4 0xB3, 0x02, 0xA0, 0x00         ; FC897B  ld (XHL),0x00a0   [llvm-mc cannot encode this]
	ld	(xiy), wa                           ; FC897F  ld (XIY),WA
	di                                     ; FC8981  ei 0x00
Flash_ProgramSlice1K__FC8983:
	cp	(xiy), wa                           ; FC8983  cp (XIY),WA
	jr nz, Flash_ProgramSlice1K__FC8983                       ; FC8985  jr NZ,0xfc8983
Flash_ProgramSlice1K__FC8987:
	inc	2, xiy                             ; FC8987  inc 2,XIY
	djnz16	bc, -39                         ; FC8989  djnz BC,0xfc8965
	pop	xix                                ; FC898C  pop XIX
	pop	xhl                                ; FC898D  pop XHL
	ret                                    ; FC898E  ret
; --------------------------------------------------------------------------
; ★ Flash_SectorBlankCheck -- is this sector erased?  ⚠ It only looks at the first
;                     256 bytes, and the reason is one prefix byte.
;
; Called from: FIVE sites: 0xF99EE5 and 0xF99F20 (`call`, both in
;          Link_ServiceTask) and 0xFC877D, 0xFC87E5, 0xFC8886 (in this block).
;          `notes/prom_c_xrefs.py 0xFC898F --no-window`.
; Inputs:  (XSP+4) = a flash address, masked to its 64 KiB sector at 0xFC8992.
;          No stack frame.
; Outputs: WA = 0 if every long inspected is 0xFFFFFFFF; WA = 0xFFFF as soon as
;          one is not.  Callers spin while it returns 0xFFFF, i.e. until the
;          erase has completed.
; Evidence: `ld XWA,0xFFFFFFFF` (0xFC899B) and `cp XWA,(XIY+)` (0xFC89A0) compare
;          32 bits at a time.  The count is where it gets interesting:
;          `ld BC,0x4000` at 0xFC8998 -- but the loop ends with `djnz B` at
;          0xFC89A5, prefix byte 0xCA, which is the 8-BIT register B, the HIGH
;          byte of BC.  B is therefore 0x40 = 64, and 64 x 4 bytes = 256.
;          ★ Its two siblings in this block use `djnz BC`, prefix byte 0xD9, and
;          do cover their full counts -- so the difference is one byte of encoding
;          and not a difference in intent that can be read off the source.
;          The prefix -> register mapping is MAME's `oC8()` / `oD8()` and
;          `get_reg8_current()`, mame/src/devices/cpu/tlcs900/900tbl.hxx lines
;          115-150 and 5672-5690.  Both prefix bytes and all three loop counts in
;          this block are asserted from the ROM by
;          `python3 notes/prom_c_flash_driver_check.py`.
; Unknown:  ⚠ whether the 8-bit `djnz` is a defect or a deliberately short poll is
;          NOT established.  As "has the erase finished" -- which is the only way
;          any caller uses it -- 256 bytes is a sufficient sample.  As "is this
;          sector blank" it is not.  Recorded, not judged.
; --------------------------------------------------------------------------
Flash_SectorBlankCheck:
	ld	xiy, (xsp+4)                        ; FC898F  ld XIY,(XSP+0x04)
	and	xiy, 0xFF0000                      ; FC8992  and XIY,0x00ff0000
	ldw	bc, 0x4000                         ; FC8998  ld BC,0x4000
	ld	xwa, 0xFFFFFFFF                     ; FC899B  ld XWA,0xffffffff
	cp_spil	xwa, 0xF6                      ; FC89A0  cp XWA,(XIY+)
	jr nz, Flash_SectorBlankCheck__FC89AB                       ; FC89A3  jr NZ,0xfc89ab
	djnz8	b, -8                            ; FC89A5  djnz B,0xfc89a0
	xor	wa, wa                             ; FC89A8  xor WA,WA
	ret                                    ; FC89AA  ret
Flash_SectorBlankCheck__FC89AB:
	ldw	wa, 0xFFFF                         ; FC89AB  ld WA,0xffff
	ret                                    ; FC89AE  ret
; --------------------------------------------------------------------------
; Flash_ReadSectorToBuffer -- copy one whole 64 KiB sector into the staging
;                     buffer at 0x00010000.
;
; Called from: SIX sites: 0xF99EB5 (`call`, the bit-7 job of Link_ServiceTask),
;          0xFC87A0, 0xFC880D (in this block), and 0xFC38AB, 0xFC3A5D, 0xFC3B72 --
;          three more in the unconverted layer at 0xFC38xx-0xFC3Bxx.
;          `notes/prom_c_xrefs.py 0xFC89AF --no-window`.
; Inputs:  (XSP+4) = a flash address, masked to its 64 KiB sector at 0xFC89B8.
;          No stack frame.
; Outputs: 0x8000 words moved from the sector to 0x00010000 by one `LDIRW`.
; Evidence: `ld XIX,0x00010000` (destination), `and XIY,0x00FF0000` (source),
;          `ld BC,0x8000`, then the two bytes `95 11` at 0xFC89C1.  MAME's
;          `op_LDIRW` writes `*m_p1_reg32` from `*m_p2_reg32` and `op_90()` sets
;          p1 = the register one below the prefix and p2 = the prefix's own --
;          for prefix 0x95 that is XIX and XIY (900tbl.hxx:2514-2530 and
;          5472-5486).  So the direction is buffer <- flash, and 0x8000 words is
;          65,536 bytes, one whole sector.  Asserted from the ROM by
;          `python3 notes/prom_c_flash_driver_check.py`.
; --------------------------------------------------------------------------
Flash_ReadSectorToBuffer:
	ld	xiy, (xsp+4)                        ; FC89AF  ld XIY,(XSP+0x04)
	push	xix                               ; FC89B2  push XIX
	ld	xix, 0x10000                        ; FC89B3  ld XIX,0x00010000
	and	xiy, 0xFF0000                      ; FC89B8  and XIY,0x00ff0000
	ldw	bc, 0x8000                         ; FC89BE  ld BC,0x8000
	extpfx2 0x95, 0x11                     ; FC89C1  ldirw   [llvm-mc cannot encode this]
	pop	xix                                ; FC89C3  pop XIX
	ret                                    ; FC89C4  ret

; ==============================================================================
; 0xFC89C5-0xFCC53E -- not yet converted
; ==============================================================================
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x0489C5, 0x003B7A

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
; ★★ AND THE THREE BYTES ff fa fb ARE EXPLAINED TOO (2026-08-25).  They are three
; single-byte MIDI messages, each sent with length 1 through Link_SendBuffer,
; which takes a POINTER -- which is why constants that could have been immediates
; have addresses:
;       0xFCC5C2 = 0xFF   MIDI System Reset  -- sent by
;                         MIDI_Watchdogs_And_TransportSwitch when active sensing
;                         stops arriving (165 ticks after the last received byte)
;       0xFCC5C3 = 0xFA   MIDI Start         -- sent when P8 bit 2 goes HIGH
;       0xFCC5C4 = 0xFB   MIDI Continue      -- sent when P8 bit 2 goes LOW
; All three go up LINK CHANNEL 6, the same channel the raw MIDI IN bytes use.
; See notes/FINDINGS-prom_c-serial-midi.md.
;
; ⚠ Still unexplained: the four leading zeros.  They are inside the boot RAM image
; copied to 0x00F3B3, and that RAM address IS written at runtime (0xFA2DD4) -- see
; notes/FINDINGS-prom_c-ram-image.md.  So this object is not homogeneous: its head
; is a RAM initialiser and its tail is five constants read in place.
; ----------------------------------------------------------------------------
unexplained_FCC5BE:
	.byte	0x00, 0x00, 0x00, 0x00, 0xff, 0xfa, 0xfb, 0x4d, 0x00, 0x80, 0x00

; ----------------------------------------------------------------------------
; ToneGen_VelCurve_Trim51 -- 0xFCC5C9..0xFCC5FB  (51 bytes)
;
; 51 signed bytes rising monotonically from 0xF4 (-12) to 0x0A (+10).
; ⚠ TWO CORRECTIONS, 2026-08-25.
;   * "a symmetric +-12 trim curve" is wrong: the range is -12..+10, not -12..+12,
;     and the zero run is five entries wide (indices 22..26), not a crossing.
;   * "Referenced once, from 0xF99874" cites the LITERAL, not the instruction.
;     The instruction is `add XBC,0x00FCC5C9` and it starts at 0xF99872.  (This
;     tree has made that off-by-two systematically; the xref tool prints the
;     literal's address and the instruction begins one or two bytes earlier.)
; ★ AND ITS CONSUMER IS NOW CONVERTED.  NoteTrim_BuildFromCalibration (0xF997FA)
; indexes this curve with `clamp(calibration_byte - 0x4B, 0, 0x32)` and stores the
; result in the signed per-note velocity trim table at 0x0084DA, which
; ToneGen_VelocityFromTouch adds into every velocity.  The clamp's upper bound
; 0x32 gives 51 entries -- the same 51 the object chain gave, from a completely
; different argument.
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
; 0xFDF7E0-0xFFEFFF -- the power-on INITIALISER IMAGE, its RELOCATED SECOND COPY,
;                      and 118,298 bytes of RET filler
; ==============================================================================
;
; Begins with 94 bytes of zero fill, then a `08 00` repeating block at 0xFDF83E.
; Most of this range is still `.incbin`; what follows is what round 3 established
; about it, and the objects whose boundaries are now proven are emitted below.
;
; ★★ THE INITIALISER IMAGE EXISTS TWICE, RELOCATED, WITH ONE OBJECT DROPPED AND
; ONE PARAMETER CHANGED.  notes/FINDINGS-prom_c-tone-generator.md §9 spotted this
; ("the 68-byte reset image at ROM 0xFE12CF is byte-identical to the 68 bytes at
; 0xFE12CF + 0xC2B ... Left for a later pass") and round 2 described the region as
; "2,259 bytes repeated at +0xC2B".  That description splits on ONE delta and
; therefore stops exactly where the alignment changes.  The real shape, from
; `python3 notes/prom_c_dup_image.py --extent`:
;
;     copy A   0xFE0A6D-0xFE15E0   2,932 bytes
;     copy B   0xFE1698-0xFE21E5   2,894 bytes
;
;     0xFE0A6D-0xFE133A  2,254 B  ->  0xFE1698-0xFE1F65   delta 0xC2B, 33 differ
;     0xFE133B-0xFE1360     38 B  ->  ** NO COUNTERPART AT ALL **
;     0xFE1361-0xFE15E0    640 B  ->  0xFE1F66-0xFE21E5   delta 0xC05,  8 differ
;
; and the two deltas differ by 0x26 = 38, which is exactly the size of the object
; that has no counterpart.  That is the whole explanation of the "shifting"
; alignment: copy B is copy A minus the 38-byte block at 0xFE133B.
; ⚠ Copy B's last byte, 0xFE21E5, is 0x0E, which is also the filler value that
; follows, so the end of copy B is ambiguous by exactly one byte.
;
; ★ FORTY OF THE FORTY-ONE DIFFERING BYTES ARE RELOCATED POINTERS.
; `python3 notes/prom_c_dup_image.py --diff` decodes every one:
;   * sixteen 24-bit pointers at stride 6 in Voice_SearchOrder_Records below,
;     each larger by exactly 0xC2B in copy B;
;   * four 24-bit pointers at stride 4 at 0xFE150F-0xFE151E, each larger by
;     exactly 0xC05.
; So copy B is not a stale duplicate that happens to look similar -- it is a
; RELOCATED image whose internal pointers were rewritten to point inside itself.
;
; ★ AND THE ONE REMAINING DIFFERENCE IS A SINGLE TONE-GENERATOR PARAMETER.
; 0xFE12C9 holds 0x0030 in copy A and 0x0020 in copy B.  That word is item 10 of
; Dev10C_GlobalRegs_ResetImage, and Dev10C_WriteGlobalRegs (0xFB7715, converted above)
; sends item 10 to GLOBAL REGISTER 0x0C04 of the 0x0010C000 device.  Two images of
; the same initialiser differing in exactly one global register is the shape of a
; configuration variant.  ⚠ WHAT the variant is, is NOT ESTABLISHED -- nothing
; here says which one the machine uses or why there are two.
;
; ★ NOTHING REACHES COPY B.  `python3 notes/prom_c_dup_image.py --refs` searches
; every 24-bit little-endian address inside each copy across the whole image and
; classifies each hit by the bytes AROUND it -- an `ld <X..>,#imm32`, one of the
; four direct-address prefixes, or a `call`/`jp` -- discarding the rest as
; coincidences that straddle an instruction boundary:
;
;     copy A   98 coincidences, 54 hits in an address-operand position
;     copy B   17 coincidences,  1 hit  in an address-operand position
;
; and that single hit is not a reference either: it is at 0xFE05DC, inside the
; descending 16-bit table at 0xFE05B0 (`... e7 ff | e2 ff | 18 fe | 68 fc ...`),
; where the bytes `e2 ff 18 fe` are the boundary between two table ENTRIES.
; ⚠ The search is for literals only.  A pointer already in RAM, or an address
; computed at run time, would be invisible -- this is "no literal reference",
; not "unreachable".
;
; ★ THE TAIL IS 118,298 BYTES OF 0x0E.  0xFE21E6-0xFFEFFF contains the single byte
; value 0x0E and nothing else -- checked over all 118,298 bytes, not sampled
; (`python3 notes/prom_c_dup_image.py --fill`).  0x0E is the one-byte `ret`
; opcode, the same filler the 3,611-byte run before the vector table uses.  It is
; emitted as `.fill` for the same reason that run is.
;
; ⚠ WHAT IS STILL `.incbin` HERE, AND WHY.  0xFDF7E0-0xFE11EF and
; 0xFE1280-0xFE12B4 and 0xFE1361-0xFE1697 have no established object boundaries:
; the reference census finds no address-operand citation into the first 1,787
; bytes of copy A (0xFE0A6D-0xFE1167; the earliest is 0xFE1168), and the objects at 0xFE1286/0xFE128A/0xFE12A9-0xFE12B4
; are cited BYTE BY BYTE from twenty different sites, which fixes fields but not
; edges.  Copy B is left whole, as one labelled `.incbin`, because emitting it as
; a second set of named objects would double every name in this file for an image
; nothing calls.
; ==============================================================================
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x05F7E0, 0x00128D

; ------------------------------------------------------------------------------
; DuplicateImage_CopyA -- 0xFE0A6D-0xFE15E0, 2,932 bytes.  Its first 1,923 bytes
; (0xFE0A6D-0xFE11EF) have no established object boundary and stay as bytes.
; ------------------------------------------------------------------------------
DuplicateImage_CopyA:
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x060A6D, 0x000783

; ------------------------------------------------------------------------------
; Four 0xFF-TERMINATED LISTS, 0xFE11F0-0xFE121F, 48 bytes in all.
;
; The names come from the KN5000 sub-CPU transplant table
; (notes/kn5000-label-transplant-generated.md, backing run 48 bytes at KN5000
; 0xF603/0xF60B/0xF61A/0xF628) -- and the run length 48 is EXACTLY these four
; objects, which is the first independent thing that agrees with the transplant.
;
; The SIZES do not rest on the sibling at all.  Each list ends in 0xFF and none
; contains 0xFF anywhere else, so the terminator fixes every boundary:
;     0xFE11F0   8 bytes   06 05 02 04 03 01 00 FF
;     0xFE11F8  15 bytes   ends 00 FF
;     0xFE1207  14 bytes   ends 01 FF
;     0xFE1215  11 bytes   ends 02 FF
; and the fourth ends exactly where Voice_SearchOrder_Records begins.  Three of
; the four are cited by that table's pointers, which is a second, independent fix
; on their start addresses.
; ⚠ The three search lists are nested: list 2 is list 1 without its last entry
; (0x00), and list 3 is list 2 without its last two (0x81 0x80 0x01).  The high
; bit is set on entries 0x80-0x86 and clear on 0x00-0x06, so the lists read as two
; interleaved groups of seven.  Nothing here says what the entries index.
; ------------------------------------------------------------------------------
Voice_KeyTable_Remapping:
	.byte	0x06, 0x05, 0x02, 0x04, 0x03, 0x01, 0x00, 0xFF	; 0xFE11F0, 8 bytes, 0xFF-terminated
; Evidence: start address, length and 0xFF terminator all measured in the block
;          comment above; three of the four objects here are also pointed at by
;          Voice_SearchOrder_Records below, which fixes the start independently.
Voice_Search_Order_List_1:
	.byte	0x86, 0x85, 0x06, 0x05, 0x84, 0x83, 0x82, 0x04, 0x03, 0x02, 0x81, 0x80, 0x01, 0x00, 0xFF	; 0xFE11F8, 15 bytes, 0xFF-terminated
; Evidence: as list 1 -- 0xFE1207, 14 bytes, 0xFF-terminated; see above.
Voice_Search_Order_List_2:
	.byte	0x86, 0x85, 0x06, 0x05, 0x84, 0x83, 0x82, 0x04, 0x03, 0x02, 0x81, 0x80, 0x01, 0xFF	; 0xFE1207, 14 bytes, 0xFF-terminated
; Evidence: as list 1 -- 0xFE1215, 11 bytes, 0xFF-terminated, and it ends exactly
;          where Voice_SearchOrder_Records begins; see above.
Voice_Search_Order_List_3:
	.byte	0x86, 0x85, 0x06, 0x05, 0x84, 0x83, 0x82, 0x04, 0x03, 0x02, 0xFF	; 0xFE1215, 11 bytes, 0xFF-terminated

; ------------------------------------------------------------------------------
; Voice_SearchOrder_Records -- 0xFE1220-0xFE127F, SIXTEEN 6-byte records
; {u32 pointer to one of the three lists above, u8, u8}.
;
; ★ THE RECORD SIZE AND THE COUNT ARE MEASURED, NOT GUESSED.  The two copies of
; this image differ in exactly sixteen 24-bit pointers, at a stride of SIX bytes,
; each larger by exactly the relocation delta 0xC2B in copy B:
;     python3 notes/prom_c_dup_image.py --diff
; The stride IS the record size, the number of relocated pointers IS the record
; count, and the last record (0xFE127A) was checked as well as the first --
; notes/prom_c_dup_image.py --selftest asserts precisely that.  The object below
; it, at 0xFE1280, contains no relocated pointer and begins a bit-mask run
; (01 02 04 08 10 20 / 01 04 10 40 / 02 08 20 80), so the table's end is fixed
; from both sides.
; ⚠ NOT ESTABLISHED: what the sixteen records are indexed by, and what the two
; trailing bytes mean.  Records 3..15 are all identical
; {Voice_Search_Order_List_3, 02, 05}; only the first three differ.
; ------------------------------------------------------------------------------
	.long	0x00FE11F8
	.byte	0x00, 0x03			; 0xFE1220  record  0
	.long	0x00FE1207
	.byte	0x01, 0x03			; 0xFE1226  record  1
	.long	0x00FE1215
	.byte	0x02, 0x04			; 0xFE122C  record  2
	.long	0x00FE1215
	.byte	0x02, 0x05			; 0xFE1232  record  3
	.long	0x00FE1215
	.byte	0x02, 0x05			; 0xFE1238  record  4
	.long	0x00FE1215
	.byte	0x02, 0x05			; 0xFE123E  record  5
	.long	0x00FE1215
	.byte	0x02, 0x05			; 0xFE1244  record  6
	.long	0x00FE1215
	.byte	0x02, 0x05			; 0xFE124A  record  7
	.long	0x00FE1215
	.byte	0x02, 0x05			; 0xFE1250  record  8
	.long	0x00FE1215
	.byte	0x02, 0x05			; 0xFE1256  record  9
	.long	0x00FE1215
	.byte	0x02, 0x05			; 0xFE125C  record 10
	.long	0x00FE1215
	.byte	0x02, 0x05			; 0xFE1262  record 11
	.long	0x00FE1215
	.byte	0x02, 0x05			; 0xFE1268  record 12
	.long	0x00FE1215
	.byte	0x02, 0x05			; 0xFE126E  record 13
	.long	0x00FE1215
	.byte	0x02, 0x05			; 0xFE1274  record 14
	.long	0x00FE1215
	.byte	0x02, 0x05			; 0xFE127A  record 15
; ------------------------------------------------------------------------------
; 0xFE1280-0xFE12B4 -- 53 bytes, NOT decoded.
; The reference census finds twenty citations into this range, every one of them
; a BYTE at a fixed address (0xFE1286, 0xFE128A, 0xFE12A9 ... 0xFE12B4, each with
; a 0xC2/0xD2/0xF2 direct-address prefix).  That pins fields and not edges, so it
; stays as bytes rather than being cut into invented records.
; ------------------------------------------------------------------------------
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x061280, 0x000035

; ------------------------------------------------------------------------------
; Dev10C_GlobalRegs_ResetImage -- 0xFE12B5, THIRTEEN 16-bit words, 26 bytes.
;
; The argument Dev10C_ResetAllChannels hands Dev10C_WriteGlobalRegs at 0xFB80E9
; (`lda_24 xbc,0x00FE12B5`).  Its size is fixed twice over: that routine reads
; exactly thirteen consecutive words, and 0xFE12CF - 0xFE12B5 = 0x1A = 26.
; The register each word lands in is read off Dev10C_WriteGlobalRegs' immediates.
; ⚠ Word 10 is the ONE non-pointer byte pair that differs between the two copies
; of this image -- see the block comment above.
; ------------------------------------------------------------------------------
Dev10C_GlobalRegs_ResetImage:
	.short	0x006F			; 0xFE12B5  word  0 -> register 0x0200
	.short	0x0993			; 0xFE12B7  word  1 -> register 0x0201
	.short	0x0001			; 0xFE12B9  word  2 -> register 0x0202
	.short	0x0004			; 0xFE12BB  word  3 -> register 0x0203
	.short	0x0004			; 0xFE12BD  word  4 -> register 0x0204
	.short	0x0001			; 0xFE12BF  word  5 -> register 0x0205
	.short	0x0000			; 0xFE12C1  word  6 -> register 0x0C00
	.short	0x0000			; 0xFE12C3  word  7 -> register 0x0C01
	.short	0x0000			; 0xFE12C5  word  8 -> register 0x0C02
	.short	0x0000			; 0xFE12C7  word  9 -> register 0x0C03
	.short	0x0030			; 0xFE12C9  word 10 -> register 0x0C04   <-- 0x0020 in the second copy
	.short	0x0001			; 0xFE12CB  word 11 -> register 0x0C05
	.short	0x0000			; 0xFE12CD  word 12 -> register 0x0E00
; ------------------------------------------------------------------------------
; Dev10C_StagingStruct_ResetImage -- 0xFE12CF, 68 bytes.
;
; `MemCopyWords(src=0xFE12CF, dst=0x00D8DB, count=0x44)` at 0xFB8150 inside
; Dev10C_ResetAllChannels.  68 = 0x44 is the count argument itself, and it is also the
; stride of the per-channel record array at 0x00003BCF and the span of the fields
; the 0x0010C000 accessors read (0x08 ... 0x42).  Left as bytes: Dev10C_WriteAllChanRegs
; reads it as 16-bit words at even offsets 0x02..0x2A, but the accessor bank reads
; single bytes out of it too, so a uniform width would be an invention.
; ------------------------------------------------------------------------------
Dev10C_StagingStruct_ResetImage:
	.byte	0x00, 0x12, 0x02, 0x00, 0x00, 0x80, 0x00, 0x00	; +0x00
	.byte	0x7C, 0x25, 0x7C, 0x7F, 0x40, 0x00, 0x00, 0x00	; +0x08
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; +0x10
	.byte	0x80, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0x00	; +0x18
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; +0x20
	.byte	0x00, 0x00, 0x00, 0x00, 0x80, 0xA0, 0x00, 0xFF	; +0x28
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; +0x30
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; +0x38
	.byte	0x00, 0x00, 0x00, 0x00	; +0x40
; ------------------------------------------------------------------------------
; Dev104_Reg0800_ResetValue -- 0xFE1313, one 16-bit word.
; Dev10C_ResetAllChannels writes register 0x0800 of the 0x00104000 device with it
; (`ldw_da bc,0xFE1313` after `ldw (xix),0x0800`).  It is one word because the
; object before it ends at 0xFE1313 and the one after starts at 0xFE1315.
; ------------------------------------------------------------------------------
Dev104_Reg0800_ResetValue:
	.short	0x1100			; 0xFE1313
; ------------------------------------------------------------------------------
; unexplained_FE1315 -- 0xFE1315, 38 bytes = 19 words.  NOT NAMED.
;
; Same size and same shape as Dev104_StagingStruct_ResetImage below -- 19 words, four
; of them repeated in pairs -- and it is cited once, at 0xFC5756
; (`lda ...,0x00FE1315`).  Its boundaries are the neighbours': the word before it
; is Dev104_Reg0800_ResetValue and the object after it is the 38-byte block
; Dev10C_ResetAllChannels copies.  ⚠ Nothing establishes that it is a staging image
; for the same device, so it keeps its address for a name.
; ------------------------------------------------------------------------------
unexplained_FE1315:
	.short	0x0004			; 0xFE1315  word  0
	.short	0x0000			; 0xFE1317  word  1
	.short	0x0000			; 0xFE1319  word  2
	.short	0x0000			; 0xFE131B  word  3
	.short	0x0000			; 0xFE131D  word  4
	.short	0x0000			; 0xFE131F  word  5
	.short	0x0000			; 0xFE1321  word  6
	.short	0x0000			; 0xFE1323  word  7
	.short	0x0000			; 0xFE1325  word  8
	.short	0x0000			; 0xFE1327  word  9
	.short	0x0000			; 0xFE1329  word 10
	.short	0x0000			; 0xFE132B  word 11
	.short	0x0000			; 0xFE132D  word 12
	.short	0xE150			; 0xFE132F  word 13
	.short	0xE150			; 0xFE1331  word 14
	.short	0xE150			; 0xFE1333  word 15
	.short	0xD71B			; 0xFE1335  word 16
	.short	0xD71B			; 0xFE1337  word 17
	.short	0xD71B			; 0xFE1339  word 18
; ------------------------------------------------------------------------------
; ★ Dev104_StagingStruct_ResetImage -- 0xFE133B, 38 bytes = NINETEEN 16-bit words.
;
; `MemCopyWords(src=0xFE133B, dst=0x00D91F, count=0x26)` at 0xFB8163 inside
; Dev10C_ResetAllChannels, and 0x00D91F is the struct that routine then hands to
; Dev104_WriteAllChanRegs for each of the 64 channels.
;
; ★ NINETEEN WORDS AND NINETEEN REGISTERS ARE THE SAME NINETEEN.  0x26 = 38 bytes
; is 19 words, and Dev104_WriteAllChanRegs writes exactly 19 registers of the
; 0x00104000 device from 19 consecutive words of that struct (blocks 0x0000 to
; 0x0480 in 0x40 steps -- see its header above, and
; `notes/prom_c_tg_regmap.py --dev104`).  The COUNT ARGUMENT of a block copy and
; the FIELD COUNT of an unrolled register writer, established independently and in
; different routines, give the same 19.  The register each word reaches is
; therefore known, and is in the comments below.
;
; ★★ AND THIS IS THE OBJECT COPY B DOES NOT HAVE.  It is exactly the 38 bytes that
; the two relocation deltas differ by.  Copy A carries the 0x00104000 reset image;
; copy B stops one object short of it.
; ⚠ What any of the nineteen parameters IS remains unknown.
; ------------------------------------------------------------------------------
Dev104_StagingStruct_ResetImage:
	.short	0x0004			; 0xFE133B  word  0 -> register 0x0000
	.short	0x0000			; 0xFE133D  word  1 -> register 0x0040
	.short	0x0000			; 0xFE133F  word  2 -> register 0x0080
	.short	0x6C00			; 0xFE1341  word  3 -> register 0x00C0
	.short	0x0100			; 0xFE1343  word  4 -> register 0x0100
	.short	0x0230			; 0xFE1345  word  5 -> register 0x0140
	.short	0x0230			; 0xFE1347  word  6 -> register 0x0180
	.short	0x1C54			; 0xFE1349  word  7 -> register 0x01C0
	.short	0x1C54			; 0xFE134B  word  8 -> register 0x0200
	.short	0x26D7			; 0xFE134D  word  9 -> register 0x0240
	.short	0x8000			; 0xFE134F  word 10 -> register 0x0280
	.short	0xFF00			; 0xFE1351  word 11 -> register 0x02C0
	.short	0x0000			; 0xFE1353  word 12 -> register 0x0300
	.short	0xE0B8			; 0xFE1355  word 13 -> register 0x0340
	.short	0xE0B8			; 0xFE1357  word 14 -> register 0x0380
	.short	0xE05E			; 0xFE1359  word 15 -> register 0x03C0
	.short	0xBDF0			; 0xFE135B  word 16 -> register 0x0400
	.short	0xBDF0			; 0xFE135D  word 17 -> register 0x0440
	.short	0x987B			; 0xFE135F  word 18 -> register 0x0480

; ------------------------------------------------------------------------------
; 0xFE1361-0xFE1697 -- the rest of copy A (0xFE1361-0xFE15E0) and the 183 bytes
; between the two copies.  0xFE150F-0xFE151E holds the FOUR relocated 32-bit
; pointers of the second differing group; the objects around them are cited from
; 0xFC38B0, 0xFC39D8, 0xFC3D9C, 0xFC3DF5, 0xFC3ED9 and 0xFC294E but their edges
; are not established.
; ------------------------------------------------------------------------------
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x061361, 0x000337

; ------------------------------------------------------------------------------
; DuplicateImage_CopyB -- 0xFE1698-0xFE21E5, 2,894 bytes.
; The relocated second copy.  See the block comment at the top of this section:
; it is copy A with every internal pointer moved by 0xC2B (or 0xC05 after the
; missing object), with Dev10C_GlobalRegs_ResetImage word 10 changed from 0x0030 to
; 0x0020, and with Dev104_StagingStruct_ResetImage absent.  No literal reference to
; any address inside it survives classification.
; ------------------------------------------------------------------------------
DuplicateImage_CopyB:
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x061698, 0x000B4E

; ------------------------------------------------------------------------------
; 0xFE21E6-0xFFEFFF -- 118,298 bytes of 0x0E, the one-byte `ret` opcode.
; Verified to contain no other byte value: `python3 notes/prom_c_dup_image.py
; --fill` reports "1 distinct value" over all 118,298 bytes.
; ------------------------------------------------------------------------------
	.fill 0x1CE1A, 1, 0x0E

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
; Evidence: VECTORS slot 0x04 (below) holds 0x00FFF0A5, this label's address.
IRQ_SWI1_REBOOT:			; vector 0x04
	jrl RESET
; Evidence: 0x00FFF0A8, this label's address, is the value of TWENTY of the 33
;          entries in VECTORS below -- every slot listed on the right.
IRQ_UNUSED:				; vectors 0x08-0x1C, 0x30-0x40,
					; 0x50-0x5C, 0x68-0x78
	jp 0xF9816B		; back to the main entry, exactly as the end
				; of RESET does
; Evidence: VECTORS slot 0x20 (below) holds 0x00FFF0AC, this label's address, and
;          MAME fetches NMI from that offset (tmp95c061.cpp:505).
IRQ_NMI:				; vector 0x20
	ei 0x07
	call 0xF99125
IRQ_NMI__hang:
	jr IRQ_NMI__hang	; spin forever
; Evidence: VECTORS slot 0x28 (below) holds 0x00FFF0B4, this label's address; the
;          slot's name is cited to tmp95c061_irq_vector_map[] (tmp95c061.cpp:322-346).
IRQ_INT0:				; vector 0x28
	jp 0xF99BBE		; -> INT0_HANDLER, converted above
; Evidence: VECTORS slot 0x48 (below) holds 0x00FFF0B8, this label's address.  It
;          is also the vector micro-DMA channel 2 is armed on (DMA2V = 0x12 at
;          0xF99A2A, and 0x12 << 2 = 0x48).
IRQ_INTT2:				; vector 0x48
	jp 0xF99E5E		; -> INTT2_HANDLER, converted above
; Evidence: VECTORS slot 0x44 (below) holds 0x00FFF0BC, this label's address.
IRQ_INTT1:				; vector 0x44
	jp 0xF99063		; -> INTT1_HANDLER, converted above: the tick
				; counter at 0x00F2F3 and the six-phase work
				; schedule in 0x007ED1
IRQ_INTTC2:				; vector 0x7C
	jp 0xF99CFE		; -> INTTC2_HANDLER, converted above
; Evidence: VECTORS slot 0x80 (below) holds 0x00FFF0C4, this label's address.
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

; `end` is not a ROM object: it is a label on the address one past the last ROM
; byte.  ⚠ NOTHING REFERENCES IT -- it is not used by prom_c/prom_c.ld and grep
; finds no other use; it is left in place because removing a label is a source
; change with no benefit.
; Evidence: it follows BUILD_TAG's last byte, which is at 0xFFFFFF, so its value
;          is 0x1000000; the byte gate would fail if any byte followed it.
end:
