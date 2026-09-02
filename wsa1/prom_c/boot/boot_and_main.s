; ==============================================================================
; Technics SX-WSA1R -- prom_c (CPU 2, IC28) -- 0xF98000-0xF98CB8  power-on: the task table, the kernel, the RAM image, MAIN
; ==============================================================================
;
; 1,118 lines moved out of prom_c/wsa1_prom_c.s by notes/prom_c_split.py.  The master
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
; Five adjacent banners that are one subject -- what CPU 2 is when it starts
; and what it does forever after: the four channel-register writers for the
; device at 0x00E00000, EntryPoint_Records (the THREE TASKS), the semaphore
; power-on image, the DSP refresh entry and INTT3, the `.include` of the
; SHARED kernel, RamImage_Copy, ADC_Init, the two A/D inputs and their
; deadband, and MAIN's loop with its four helpers.
;
; >>> END OF EXTRACTION HEADER -- everything below is verbatim from the master

; ==============================================================================
; 0xF98000-0xF980E9 -- ★★ THE DSP CHANNEL-REGISTER DRIVER, SHARED WITH prom_a
; ==============================================================================
;
; These 234 bytes are no longer written out here.  They are dsp/dsp_channel_regs.s,
; ONE source that assembles into prom_c at 0xF98000 AND into prom_a at 0xF85F0F --
; 231 of the 234 bytes are the same byte in the two EPROMs, and the three that
; are not are A23..A16 of each routine's base literal, 0xE0 on this processor and
; 0x7F on the other.  That is the whole difference between the two copies.
;
; The block banner and the four routine headers that stood here moved there
; verbatim and now sit beside prom_a's headers for the same routines, each under
; a banner naming its file.  Nothing was reworded:
;       python3 notes/sound/wsa1_dsp_join_probe.py --verify
;
; dsp/dsp_channel_regs_subcpu.inc below supplies the ONE value that is CPU 2's
; rather than CPU 1's: DSP_REGS_BASE = 0x00E00000.  Nothing else about the two
; copies differs, so there is no conditional anywhere in the body.
;
; ★ prom_c GAINS ADDRESSES AND BYTES in the move.  This block was hand-written
;   and carried no address comments at all; every merged line now names both
;   images' addresses and the bytes at them, so a reader can check the listing
;   against the EPROM without assembling it.
;
; ⚠ The proof is the byte gate, not this comment.  If the equate were wrong THIS
;   image would stop rebuilding:
;       python3 scripts/analysis/assert_byte_identical.py
; ==============================================================================
	.include "dsp/dsp_channel_regs_subcpu.inc"
	.include "dsp/dsp_channel_regs.s"

; ----------------------------------------------------------------------------
; EntryPoint_Records -- 0xF980EA..0xF9810D  (36 bytes)
;
; THREE 12-byte records, {code address, low-RAM address, constant}.  The shape is
; not asserted from the shape alone -- each column is checked:
;
;   * column 1 holds 0x00F98B7D, 0x00FA54DB and 0x00F98118.  The first is MAIN,
;     converted below, and the third is the top of DSP_ChannelRefresh_Loop at 0xF98118
;     (`ei 0` -- the byte pair `06 00` -- then `link XIZ,0xfffc`).  Both are real
;     entry points; neither is the middle of an instruction.
;     * CORRECTED 2026-08-25 (round-2 audit F8): this line said "`di` then
;     `link`".  `06 00` is `EI 0`, which ENABLES every maskable interrupt; the
;     citations are in the DSP_ChannelRefresh_Loop header ~140 lines below and
;     in notes/prom_c-llvm-mc-spellings.md.  A task entry point that began by
;     disabling interrupts and never re-enabling them would be a different
;     claim entirely, which is why the backwards spelling mattered here and not
;     only in the instruction stream.
;   * column 2 holds 0x0000FFF0, 0x0000F980 and 0x0000F480 -- three descending
;     addresses in the top of CPU 2's work DRAM.  0x0000FFF0 is EXACTLY the value
;     RESET installs in XSP (`ld XSP,0x0000FFF0`, in the boot block at the bottom
;     of this file).
;   * column 3 holds 0x00028800, 0x00028800 and 0x00018800 -- the same low half
;     throughout, and a high half of 2, 2, 1.
;
; ★ RESOLVED 2026-08-25 -- the consumer is Kernel_StartTask (0xF9833E), and the
; table is {entry PC, initial XSP, initial SR, ready-queue level}:
;
;     +0  LE32  entry PC          -> (frame+0x1E), the address RET pops
;     +4  LE32  initial XSP       -> the frame is built at this MINUS 0x22
;     +8  LE16  0x8800            -> (frame+0x1C), the SR `pop SR` restores
;     +10 LE16  1 or 2            -> task control block +8, the READY-QUEUE LEVEL
;
; and 0x22 = 7*4 (the register slots) + 2 (SR) + 4 (PC) is exactly what
; Kernel_ResumeTask pops.  So the "constant" in column 3 was two fields, not one.
;
; ⚠ THE EARLIER SEARCH COULD NOT HAVE FOUND THIS, and the reason is worth keeping:
; the whole kernel is ONE-BASED, so Kernel_StartTask does not name 0xF980EA at
; all -- it computes `add XHL,0xfff980de`, i.e. 0xF980DE = 0xF980EA - 12, and
; indexes it with a task number 1..3.  prom_a's lane hit the identical trap and
; recorded it (notes/FINDINGS-prom_a-kernel-lifecycle.md §2).
;
; The record COUNT is three, and it is now a BOUND CHECK rather than an argument
; from the data: Kernel_InitRam creates exactly THREE task control blocks
; (`ldw ix,0x100 / ldb b,3 / add ix,12`), and Kernel_StartTask indexes records and
; control blocks with the SAME task number and the SAME stride of 12.  A fourth
; record would have no control block.  The four bytes after the third record are
; not a truncated record either -- they are the semaphore-count image, converted
; immediately below, and Kernel_InitRam's `ldir` copies exactly four of them.
;
; The three records are the three TASKS: 1 = MAIN at level 2, 2 = 0xFA54DB at
; level 2, 3 = DSP_ChannelRefresh_Loop at level 1.  Kernel_Start starts 1 and 3;
; 0xFA3365 starts 2.
; ★ ROUND 5: TASK 2 IS THE PORT-P7 UNIT MODULE'S SERVICE TASK.  0xFA54DB is the inner
; label P7Units_ServiceTask__FA54DB, inside P7Units_ServiceTask (0xFA5177-0xFA5534),
; which waits on SEMAPHORE 2 -- the semaphore P7Mixer_RequestGain signals at 0xFA2DE1
; -- and diffs the three unit blocks at RAM 0x856E against their shadows at 0x85BC.
; 0xFA3365 is inside P7Units_BootLoadAndStartTask.
; ----------------------------------------------------------------------------
EntryPoint_Records:
	.long	0x00F98B7D, 0x0000FFF0, 0x00028800	; MAIN
	.long	0x00FA54DB, 0x0000F980, 0x00028800	; P7Units_ServiceTask__FA54DB
	.long	0x00F98118, 0x0000F480, 0x00018800	; DSP_ChannelRefresh_Loop

; ==============================================================================
; 0xF9810E-0xF98111 -- the SEMAPHORE COUNT image
; ==============================================================================
; Four bytes, the power-on values of the four semaphore counters.
;
; Read by:  Kernel_InitRam, which copies them to RAM 0x013C with `ld
;          XHL,0x00F9810E / ld DE,0x013C / ld BC,0x0004 / ldir` (0xF981B8-0xF981C6).
;          That is the ONLY reference to this address in prom_c
;          (`python3 notes/prom_c_xrefs.py 0xF9810E --no-window`).
; Count:   FOUR, and the count is the `ld BC,0x0004` of the copy itself, not a
;          guess about where the run stops.  The destination 0x013C is where
;          Kernel_InitRam's four semaphore WAIT QUEUES end (0x012C + 4*4) and
;          0x013C + 4 = 0x0140, where its next array begins -- so the array is
;          bounded on both sides by structures whose own sizes are literal.
; Meaning: semaphore s = 1..4 starts with count 01, 00, 01, 01.  Semaphore 2 is
;          the only one that starts TAKEN, and it is the one MAIN and 0xFA2DE0
;          signal and task 2 waits on.
; ==============================================================================
	.byte	0x01, 0x00, 0x01, 0x01

; ==============================================================================
; 0xF98112-0xF9816A -- the DSP refresh entry point, and INTT3
; ==============================================================================
; --------------------------------------------------------------------------
; SoftTimer_RotateLevel2 -- the boot software timer's callback: round-robin
; level 2.
;
; Called from: NOT by a call instruction.  Its address, 0x00F98112, is the +4
;              field of SoftTimer_Request_Boot, the eight-byte argument block
;              Kernel_InitRam hands to SoftTimer_Register at 0xF9824D; that
;              routine writes it into software-timer slot 1 (+4), and
;              Kernel_ServiceSoftTimers enters slot+4 by pushing its own
;              continuation and jumping.  That is the only reference to 0xF98112
;              anywhere in prom_c.
; Inputs:  none.  Outputs: ready queue 2 rotated by one, via Kernel_YieldRotate.
; Evidence: three instructions -- `ldb a,2`, `calr Kernel_YieldRotate`, `ret`.
;          The boot request's +0 and +2 are both 1, so the slot's countdown and
;          reload are both 1 and this fires on EVERY kernel tick; the tick is
;          INTT3, whose handler increments (0x0090) and whose count
;          Kernel_Dispatch drains.  Level 2 is the level of both MAIN and task 2,
;          so this is what time-slices them against each other.
;          prom_a has the same routine, sub_F85EC2, with A = 3 -- its own
;          lowest-priority level -- and left it unnamed only because
;          Kernel_YieldRotate was still .incbin there.
; Unknown:  ⚠ `ret` after `calr Kernel_YieldRotate` is unreachable:
;          Kernel_YieldRotate leaves through Kernel_Dispatch or
;          Kernel_ResumeTask, never by returning to its caller.  Recorded as
;          observed; prom_a's copy has the same dead `ret`.
; --------------------------------------------------------------------------
SoftTimer_RotateLevel2:
	ldb	a, 2
	calr	(0xF983DC - 0xF98117)
	ret


; --------------------------------------------------------------------------
; DSP_ChannelRefresh_Loop -- CPU 2's task 3: on every signal of semaphore 3,
; reload all four channel-register blocks.
;
; Called from: NOTHING calls it, and nothing is supposed to: it is a TASK ENTRY
;              POINT.  Its address, 0xF98118, is the +0 field of the THIRD record
;              of EntryPoint_Records at 0xF980EA, and Kernel_Start starts that
;              record with `ldb a,3 / call Kernel_StartTask` at 0xF98263.  Its
;              stack, 0x0000F480, is the record's +4, and its LEVEL is the
;              record's +10 -- 1, the queue Kernel_Dispatch scans FIRST.  So this
;              is CPU 2's highest-priority task.
; Inputs:  four buffers in work DRAM: 0x00006612 (used TWICE, for channels 0 and
;          2), 0x00000100 (channel 1) and 0x00000108 (channel 3).
; Outputs: it never returns.  Each pass BLOCKS on Kernel_SemaWait(3) and then
;          calls DSP_ChannelRegs_Write8 four times.
; ★ CORRECTED 2026-08-25.  This header used to call the routine an
;          "interrupt-disabled endless loop" of unknown purpose and to say
;          nothing calls it.  Both were wrong, and converting 0xF9816B-0xF989EE
;          is what fixed them: 0xF985F8 is Kernel_SemaWait, so the loop is not a
;          spin at all -- it runs one pass per V() on semaphore 3 and is
;          descheduled in between.
; ⚠ AND NOTHING FOUND EVER SIGNALS SEMAPHORE 3.  Both Kernel_SemaSignal call
;          sites push 2: `call 0xF98510` at 0xF98C6C in MAIN (its `push 0x0002`
;          at 0xF98C69) and at 0xFA2DE4 (its `push 0x0002` at 0xFA2DE1).  ★
;          CORRECTED 2026-08-25 (round-2 audit F3): this line used to cite
;          "0xFA2DE0", which is the LAST BYTE of the preceding
;          `ld (0x00f3b4),A` (0xFA2DDC..0xFA2DE0) and not an instruction start
;          at all -- and it paired that with 0xF98C69, which is a push, so the
;          two citations did not even name the same kind of thing.  Both call
;          addresses are now cited, and both were read off
;          `scripts/analysis/dis.sh c 0xFA2DD0 48` / `... c 0xF98C60 32`.
;          Neither Kernel_SemaSignal_NoDispatch nor its stack face has any
;          call site
;          (prom_c_xrefs.py 0xF98587 / 0xF98581).  Semaphore 3's initial count is
;          1 (the image at 0xF9810E), so on the evidence available this task runs
;          EXACTLY ONE PASS and then blocks for ever.  Recorded as a searched
;          negative: prom_c_xrefs.py cannot see a target computed at run time.
; Evidence: the loop is closed by an unconditional `jr` to 0xF9811E, which is
;          INSIDE the frame the `link32` at 0xF9811A opened -- so the frame is
;          built once and the loop runs below it, which is what an entry point
;          looks like and not what a subroutine looks like.  It also starts with
;          `ei 0` -- ⚠ WHICH IS NOT A DISABLE, and which this file used to spell
;          `di`.  llvm-mc accepts `di` and assembles it to `06 00`,
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
; Unknown:  ⚠ what the refresh is FOR, and what would signal semaphore 3.
;          Reusing 0x6612 for channels 0 and 2 is recorded as observed.
;          ⚠ NO INSTRUCTION LINE IN THIS FILE SPELLS IT `di` ANY MORE.  All 23
;          `06 00` sites read `ei 0` (`grep -cP '^\s+di\b'` = 0;
;          `grep -oP '^\s+ei\s+\S+' | sort | uniq -c` = 23 `ei 0`, 35 `ei 6`,
;          2 `ei 0x07`); the byte gate proves the change is spelling only.
;          * CORRECTED 2026-08-25 (round-2 audit F8): the earlier wording was
;          "THE `di` SPELLING IS GONE FROM THIS FILE ... all eighteen sites",
;          and both halves were wrong -- the count is 23, not 18, and six PROSE
;          lines still quote `di` (in this file: the EntryPoint_Records header,
;          Serial0_Init, and the four link headers) because they are explaining
;          the trap.  Quoting the old mnemonic while correcting it is fine;
;          claiming it is absent from the file is not.
; --------------------------------------------------------------------------
DSP_ChannelRefresh_Loop:
	ei	0
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
; INTT3_KernelTick -- timer-3 ISR: bump the pending-tick count, then exit
; through the shared interrupt epilogue.
;
; Called from: vector table offset 0x4C (INTT3), which holds 0x00F98165 directly
;              -- one of the four vectors (with INT4, INTRX0 and INTTX0) that do
;              not go through the trampoline block at 0xFFF0A2.
; Inputs:  none.
; Outputs: the byte at 0x0090 is incremented; control passes to IRQ_Epilogue.
; ★ RENAMED AND RESOLVED 2026-08-25.  The old header said "⚠ what 0x000090
;          counts, and what 0xF9831C decides" were unknown and refused to name
;          the routine.  Converting 0xF9816B-0xF989EE settles both:
;            * 0x0090 is the kernel's PENDING TICK COUNT.  Kernel_Start clears it
;              (`ldio 0x90,0` at 0xF9826B) and Kernel_Dispatch__drain_ticks
;              decrements it, calling Kernel_ServiceSoftTimers once per tick,
;              until it reaches zero.  This handler is its only writer.
;            * 0xF9831C is IRQ_Epilogue, which compares control register 0x3C
;              against 1 -- "was this the outermost interrupt?" -- and either
;              RETIs or pushes the seven registers Kernel_ResumeTask pops and
;              enters Kernel_Dispatch.
; Evidence: two instructions and no `reti`, because the RETI is delegated.  The
;          name is transplanted from prom_a's INTT3_KernelTick (0xF85600), which
;          is the same TWO instructions: 2 slots aligned, 0 different mnemonics,
;          2 operand differences -- the counter address (0x90 here, 0xBE there)
;          and the epilogue address.  Reproduce with
;          `python3 notes/prom_c_prom_a_routine_diff.py 0xF98165 0xF85600 0x06`.
;          Timer 3 is programmed twice: Kernel_Start writes TREG3 = 0x36 and
;          Timer3_Init, later, writes 0x2E.
; Unknown:  ⚠ the tick RATE.  T23MOD's field layout is not decoded anywhere
;          available to this tree, so 46 and 54 counts are periods in unknown
;          units.  Control register 0x3C is likewise left as a number -- see the
;          kernel block comment below for what MAME does and does not say.
; --------------------------------------------------------------------------
INTT3_KernelTick:
	extpfx3	0xC0, 0x90, 0x61
	jrl	(0xF9831C - 0xF9816B)

; ==============================================================================
; 0xF9816B-0xF989EE -- ★★ THE MULTITASKING KERNEL, SHARED WITH CPU 1
; ==============================================================================
;
; The 2,180 bytes that used to be written out here are now in kernel/kernel.s,
; ONE source prom_a includes as well: the same kernel runs on BOTH of the
; WSA1R's processors, and every pair of addresses differs by exactly 0x12B65
; (prom_a's copy starts at 0xF85606).  The block comment and the routine headers
; that stood here moved there verbatim and now sit beside prom_a's headers for
; the same routines, each under a banner naming its file.
;
; kernel_subcpu.inc below supplies the 21 values that are CPU 2's rather than
; CPU 1's -- the stack top, the kernel RAM map, the array sizes.  Nothing else
; about the two copies differs.
;
; ★ prom_c GAINS THE SPELLINGS prom_a already had.  This block held 99 raw
;   `extpfx3 0x9C, 0x00, 0x20` byte-emitter lines; the shared file has ONE.  89
;   of them now read `m_ld_rm MWD+r4, 0x00, r0` -- prom_a's byte-emitter macros,
;   which kernel.s carries under an `.ifndef` guard because prom_a defines them
;   itself -- and 9 read a native spelling llvm-mc does accept, such as
;   `cp (XIX+0x09),0x03`.  unidasm's own text stays in the trailing comment
;   either way.  (Counted with:
;   `grep -cE '^\s*extpfx' kernel/kernel.s` against the same grep over this
;   block at commit 8ff84e5.)
;
; ⚠ The proof is the byte gate, not this comment.  If a single equate were wrong
;   BOTH images would stop rebuilding:
;       python3 scripts/analysis/assert_byte_identical.py
;       python3 notes/kernel_join_probe.py --verify
; ==============================================================================
	.include "kernel/kernel_subcpu.inc"
	.include "kernel/kernel.s"



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
	lda	xiy, (0x00FCB4EA:24)
	lda	xix, (0x00E2DF:24)
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
; 0xF98A0B-0xF98B1F -- ★ the TWO A/D INPUTS, and the deadband that gates them
; ==============================================================================
;
; Two routines.  The second polls two A/D result registers once per pass of MAIN's
; loop and reports a value to CPU 1 over the inter-processor link; the first is
; the filter that decides whether a reading counts as a change at all.  Together
; they are the whole path from an analog control to a link message.
;
; ★ THE FOUR RAM CELLS ARE PAIRED, AND THE BOOT IMAGE CONFIRMS THE PAIRING:
;
;     0x00E2E5  channel 1's LAST REPORTED value   boot value 0x80
;     0x00E2E6  channel 1's filter state          boot value 0x00
;     0x00E2E7  channel 2's LAST REPORTED value   boot value 0x80
;     0x00E2E8  channel 2's filter state          boot value 0x00
;     0x00E2E9  the message being built: +0 tag (0xB0 / 0xB1), +1 the value
;
; The boot values are not read off this code -- they come from the RAM image
; RamImage_Copy installs, `python3 notes/prom_c_ram_image.py 0x00E2E5 0x00E2E6
; 0x00E2E7 0x00E2E8 0x00E2E9:2`.  Both "last value" cells start at 0x80, MID
; SCALE for an 8-bit reading, and both state bytes start at 0.
;
; ⚠ WHAT THE TWO INPUTS ARE IS NOT ESTABLISHED.  They are ADREG1H (SFR 0x63) and
; ADREG2H (SFR 0x65), the high bytes of A/D conversion results 1 and 2
; (include/tmp95c061_sfr.inc, from MAME's symbol table for this part).  The
; converter is polled, not interrupt-driven -- the INTAD vector points at
; IRQ_UNUSED -- and ADC_Init (0xF98A02) writes ADMOD = 0x3F, a value MAME does not
; decode.  What is on the pins is not in these ROMs.  The link tags 0xB0 and 0xB1
; are likewise recorded, not decoded.
;
; --------------------------------------------------------------------------
; Analog_ChangeDetect -- has this input moved far enough, for long enough?
;
; Called from: Analog_ScanAndReport, `calr 0xF98A0B` at 0xF98A94 and 0xF98AE6.
;              Those are the only two sites (prom_c_xrefs.py 0xF98A0B).
; Inputs:  (XIZ+0x08) byte  the new sample
;          (XIZ+0x09) byte  pushed as 0 by both callers and never read
;          (XIZ+0x0a) long  pointer to the LAST REPORTED value
;          (XIZ+0x0e) long  pointer to the FILTER STATE byte
; Outputs: A = 8 if the change is accepted, 0 otherwise; the state byte updated.
;          ⚠ It does NOT update the last-reported value -- the caller does that,
;          and only when A is non-zero.
; Evidence: the argument offsets are fixed by the callers' push order (XBC then
;          XWA, both 4 bytes, then two 1-byte pushes) and by the callers' cleanup,
;          `inc 8,xsp` + `inc 2,xsp` = 10 = 4+4+1+1.  MAME's op_PUSHBI takes one
;          byte (900tbl.hxx:2935), which is what makes 10 come out.
;          The magnitude is computed without a sign test: `cp A,W / jr UGT / ex
;          A,W` leaves A = max and W = min, so `sub A,W` is |sample - last|.
;          Three bands and what each does to the state byte:
;            |d| <= 2   `and C,0xF8`     -- clear the counter and the arm bit
;            3..6       bit 2 set  -> accept;  bit 2 clear -> `or C,4`, arm it
;            > 6        C == 3     -> accept;  otherwise `inc 1,C` and `and C,0xFB`
;          so bits 0-1 are a confirmation COUNTER for large moves (three passes to
;          reach 3, accepted on the fourth), bit 2 is a one-shot arm for medium
;          moves, and bit 3 is the accept flag.  "Accept" is literally `or C,8`
;          followed by `and C,0xF8`, and the return value is `ld A,C / and A,0x08`.
;          The state is stored back with bit 3 cleared and masked to 0x0F, so the
;          byte the caller sees never carries the accept flag forward.
;          ⚠ The `ld A,E` on both accept paths is DEAD -- `ld A,C` at
;          Analog_ChangeDetect__store overwrites it before anything reads A.
; Unknown:  why the second argument slot exists.  Both callers push 0 into it and
;          nothing reads it.
; --------------------------------------------------------------------------
Analog_ChangeDetect:
	link32 0xEE, 0x0C, 0x00, 0x00              ; F98A0B  link XIZ,0x0000
	push	xix                                   ; F98A0F  push XIX
	pushw	de                                   ; F98A10  push DE
	ld	a, (xiz+8)                              ; F98A11  ld A,(XIZ+0x08)
	ld	xbc, (xiz+10)                           ; F98A14  ld XBC,(XIZ+0x0a)
	ld	w, (xbc)                                ; F98A17  ld W,(XBC)
	ld	xbc, (xiz+14)                           ; F98A19  ld XBC,(XIZ+0x0e)
	ld	c, (xbc)                                ; F98A1C  ld C,(XBC)
	ld	e, a                                    ; F98A1E  ld E,A
	cp	a, w                                    ; F98A20  cp A,W
	jr ugt, Analog_ChangeDetect__delta                          ; F98A22  jr UGT,0xf98a26
	ex8	a, w                                   ; F98A24  ex A,W
Analog_ChangeDetect__delta:
	sub	a, w                                   ; F98A26  sub A,W
	cps	a, 2                                   ; F98A28  cp A,2
	jr ule, Analog_ChangeDetect__reset                          ; F98A2A  jr ULE,0xf98a5d
	cps	a, 6                                   ; F98A2C  cp A,6
	jr ule, Analog_ChangeDetect__medium                          ; F98A2E  jr ULE,0xf98a49
	xor	c, 3                                   ; F98A30  xor C,0x03
	jr nz, Analog_ChangeDetect__count_up                           ; F98A33  jr NZ,0xf98a3f
	ld	a, e                                    ; F98A35  ld A,E
	or	c, 8                                    ; F98A37  or C,0x08
	and	c, 0xF8                                ; F98A3A  and C,0xf8
	jr Analog_ChangeDetect__store                               ; F98A3D  jr T,0xf98a60
Analog_ChangeDetect__count_up:
	xor	c, 3                                   ; F98A3F  xor C,0x03
	inc	1, c                                   ; F98A42  inc 1,C
	and	c, 0xFB                                ; F98A44  and C,0xfb
	jr Analog_ChangeDetect__store                               ; F98A47  jr T,0xf98a60
Analog_ChangeDetect__medium:
	bit	2, c                                   ; F98A49  bit 0x02,C
	jr z, Analog_ChangeDetect__arm                            ; F98A4C  jr Z,0xf98a58
	ld	a, e                                    ; F98A4E  ld A,E
	or	c, 8                                    ; F98A50  or C,0x08
	and	c, 0xF8                                ; F98A53  and C,0xf8
	jr Analog_ChangeDetect__store                               ; F98A56  jr T,0xf98a60
Analog_ChangeDetect__arm:
	or	c, 4                                    ; F98A58  or C,0x04
	jr Analog_ChangeDetect__store                               ; F98A5B  jr T,0xf98a60
Analog_ChangeDetect__reset:
	and	c, 0xF8                                ; F98A5D  and C,0xf8
Analog_ChangeDetect__store:
	ld	a, c                                    ; F98A60  ld A,C
	and	a, 8                                   ; F98A62  and A,0x08
	and	c, 0xF7                                ; F98A65  and C,0xf7
	and	c, 15                                  ; F98A68  and C,0x0f
	ld	xix, (xiz+14)                           ; F98A6B  ld XIX,(XIZ+0x0e)
	ld	(xix), c                                ; F98A6E  ld (XIX),C
	popw	de                                    ; F98A70  pop DE
	pop	xix                                    ; F98A71  pop XIX
	unlk32 xiz                                 ; F98A72  unlk XIZ
	ret                                        ; F98A74  ret
; --------------------------------------------------------------------------
; Analog_ScanAndReport -- poll both A/D inputs and send whatever changed.
;
; Called from: MAIN, `calr 0xF98A75` at 0xF98C87 -- the only site
;              (prom_c_xrefs.py 0xF98A75).
; Inputs:  ADREG1H (SFR 0x63) and ADREG2H (SFR 0x65).
;          MAIN reaches this routine only after test-and-clearing bit 5 of the
;          scheduler work byte 0x007ED1, so it runs at the rate INTT1 sets that
;          bit.  ⚠ That address is a VARIABLE, not a call site; it is stated here
;          rather than in `Called from:` because notes/prom_c_audit_callsites.py
;          harvests every 0xXXXXXX in that paragraph and cannot tell prose from a
;          citation.
; Outputs: for each channel whose reading Analog_ChangeDetect accepts: the
;          last-reported cell is updated, a two-byte message {tag, value} is built
;          at 0x00E2E9, and Link_SendBuffer(5, 2, 0x00E2E9) is called.  Tag 0xB0
;          for channel 1, 0xB1 for channel 2.
; Evidence: the two halves are the same eleven instructions with four addresses
;          and one constant substituted -- 0x63/0x65, 0x00E2E5/0x00E2E7,
;          0x00E2E6/0x00E2E8, 0xB0/0xB1 -- which is what makes "two channels of one
;          thing" a reading of the code and not of the layout.  The A/D register
;          numbers come from include/tmp95c061_sfr.inc.  The call at 0xF98AC6 and
;          0xF98B18 is Link_SendBuffer (0xF98B20, converted below), and its three
;          arguments are pushed in the order that routine documents: the byte slot
;          gets 5, the word slot 2, the long slot the buffer address.
; Unknown:  ⚠ why the argument is 5 when only TWO bytes of the buffer are written
;          here.  Link_SendBuffer's own header records the first slot as a length
;          and the middle one as a probable channel, both from
;          notes/FINDINGS-memory-map.md's `(channel << 5) | (len - 1)` header
;          reading; if 5 really is a length, three bytes of the message come from
;          somewhere this routine does not touch.  NOT RESOLVED HERE.
;          ⚠ Also unexplained: the value is re-READ from the cell it was just
;          written to (`ld C,(0x00E2E5)` after `ld (0x00E2E5),C`) rather than
;          reused from C.
; --------------------------------------------------------------------------
Analog_ScanAndReport:
	link32 0xEE, 0x0C, 0xFA, 0xFF              ; F98A75  link XIZ,0xfffa
	ldw	bc, 99                                 ; F98A79  ld BC,0x0063
	exts	xbc                                   ; F98A7C  exts XBC
	ld	a, (xbc)                                ; F98A7E  ld A,(XBC)
	ld	(xiz-5), a                              ; F98A80  ld (XIZ+0xfb),A
	lda	xbc, (0xE2E6:24)                       ; F98A83  lda XBC,0x00e2e6
	push	xbc                                   ; F98A88  push XBC
	lda	xwa, (0xE2E5:24)                       ; F98A89  lda XWA,0x00e2e5
	push	xwa                                   ; F98A8E  push XWA
	push	0                                     ; F98A8F  push 0x00
	extpfx3 0x8E, 0xFB, 0x04                   ; F98A91  push (XIZ+0xfb)
	calr (0xF98A0B - 0xF98A97)                 ; F98A94  calr 0xf98a0b
	ld	(xiz-6), a                              ; F98A97  ld (XIZ+0xfa),A
	inc	8, xsp                                 ; F98A9A  inc 0,XSP
	inc	2, xsp                                 ; F98A9C  inc 2,XSP
	cps	a, 0                                   ; F98A9E  cp A,0
	jr z, Analog_ScanAndReport__chan2                            ; F98AA0  jr Z,0xf98acb
	ld	c, (xiz-5)                              ; F98AA2  ld C,(XIZ+0xfb)
	stb_da	(0xE2E5), c                         ; F98AA5  ld (0x00e2e5),C
	stib_da	(0xE2E9), 0xB0                     ; F98AAA  ld (0x00e2e9),0xb0
	ld	c, (0xE2E5:24)                         ; F98AB0  ld C,(0x00e2e5)
	stb_da	(0xE2EA), c                         ; F98AB5  ld (0x00e2ea),C
	lda	xbc, (0xE2E9:24)                       ; F98ABA  lda XBC,0x00e2e9
	push	xbc                                   ; F98ABF  push XBC
	pushw	2                                    ; F98AC0  push 0x0002
	pushw	5                                    ; F98AC3  push 0x0005
	calr (0xF98B20 - 0xF98AC9)                 ; F98AC6  calr 0xf98b20
	inc	8, xsp                                 ; F98AC9  inc 0,XSP
Analog_ScanAndReport__chan2:
	ldw	bc, 0x65                               ; F98ACB  ld BC,0x0065
	exts	xbc                                   ; F98ACE  exts XBC
	ld	a, (xbc)                                ; F98AD0  ld A,(XBC)
	ld	(xiz-5), a                              ; F98AD2  ld (XIZ+0xfb),A
	lda	xbc, (0xE2E8:24)                       ; F98AD5  lda XBC,0x00e2e8
	push	xbc                                   ; F98ADA  push XBC
	lda	xwa, (0xE2E7:24)                       ; F98ADB  lda XWA,0x00e2e7
	push	xwa                                   ; F98AE0  push XWA
	push	0                                     ; F98AE1  push 0x00
	extpfx3 0x8E, 0xFB, 0x04                   ; F98AE3  push (XIZ+0xfb)
	calr (0xF98A0B - 0xF98AE9)                 ; F98AE6  calr 0xf98a0b
	ld	(xiz-6), a                              ; F98AE9  ld (XIZ+0xfa),A
	inc	8, xsp                                 ; F98AEC  inc 0,XSP
	inc	2, xsp                                 ; F98AEE  inc 2,XSP
	cps	a, 0                                   ; F98AF0  cp A,0
	jr z, Analog_ScanAndReport__done                            ; F98AF2  jr Z,0xf98b1d
	ld	c, (xiz-5)                              ; F98AF4  ld C,(XIZ+0xfb)
	stb_da	(0xE2E7), c                         ; F98AF7  ld (0x00e2e7),C
	stib_da	(0xE2E9), 0xB1                     ; F98AFC  ld (0x00e2e9),0xb1
	ld	c, (0xE2E7:24)                         ; F98B02  ld C,(0x00e2e7)
	stb_da	(0xE2EA), c                         ; F98B07  ld (0x00e2ea),C
	lda	xbc, (0xE2E9:24)                       ; F98B0C  lda XBC,0x00e2e9
	push	xbc                                   ; F98B11  push XBC
	pushw	2                                    ; F98B12  push 0x0002
	pushw	5                                    ; F98B15  push 0x0005
	calr (0xF98B20 - 0xF98B1B)                 ; F98B18  calr 0xf98b20
	inc	8, xsp                                 ; F98B1B  inc 0,XSP
Analog_ScanAndReport__done:
	unlk32 xiz                                 ; F98B1D  unlk XIZ
	ret                                        ; F98B1F  ret


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
;          ★ AND THIS IS THE SECOND TIME TIMER 3 IS PROGRAMMED.  Kernel_Start
;          (0xF98251) has already run the same five writes with TREG3 = 0x36 (54)
;          before MAIN exists -- MAIN is the task Kernel_Start starts -- so 0x36
;          is the boot period and 0x2E is the period for the rest of the run.
;          Both are recorded, neither is decoded.
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
; Called from: NOTHING calls it, and nothing should: MAIN is TASK 1.  Its address
;              is the +0 field of EntryPoint_Records[0], its stack is that
;              record's +4 (0x0000FFF0) and its level is that record's +10 (2),
;              and Kernel_Start starts it with `ldb a,1 / call Kernel_StartTask`
;              at 0xF9825D.  That record is the only reference to 0xF98B7D in
;              prom_c.
; Inputs:  none.
; Outputs: it never returns.
; Evidence: the init chain is EIGHT calls in a row before it even reads the fc
;          byte, and four more after it, and four of the twelve are already
;          identified elsewhere in this file -- 0xF9919F is Serial0_Init,
;          0xF98000 is DSP_ChannelRegs_Init, 0xF98B6D is Timer3_Init, and
;          0xF990FA is Timer1_SetPeriodAndStart, called here with the fc byte
;          read from 0xFFFFEF two instructions earlier.  The loop is closed by
;          `jrl MAIN__loop` with no condition.
; Unknown:  ★ UPDATED 2026-08-25 (round 6).  Of the twelve addresses this line
;          used to list as "still unconverted", EIGHT now have names and headers:
;          0xFB0504 ExtBoard_ProbeAndInstallBases, 0xFC88A0
;          Flash_ProbeAndStoreDeviceId, 0xF997FA NoteTrim_BuildFromCalibration,
;          0xF99E5F Link_ServiceTask, 0xFB05EC Toggle14FE_AndDispatch, 0xF98CB9
;          KeyEvents_ToLink, 0xFB060A MidiIn_ParseRingAndDispatch and 0xFB0A0D
;          MidiMsg_SendBootSequence.  ★ The last two are the whole MIDI path: step
;          12 of the init chain primes the engine with four literal messages, and
;          the bottom of the loop drains the ring KeyEvents_ToLink fills.
;          STILL UNCONVERTED: 0xFC8B9C, 0xF9993E, 0xFA3127 and 0xF994E4.
;          ★ THREE OF THE OLD ENTRIES ARE NOW CONVERTED: 0xF98A02 is ADC_Init,
;          0xF98510 is Kernel_SemaSignal_StackArg -- MAIN pushes 2, so step 3's
;          timer expiry SIGNALS SEMAPHORE 2, the one task 2 waits on -- and
;          0xF98A75 is Analog_ScanAndReport, so step 4 is the A/D poll.
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
	ld	bc, (0x00FFFFEF:24)
	extz	bc
	pushw	bc
	calr	(0xF990FA - 0xF98BAB)
	calr	(0xF98B6D - 0xF98BAE)
	call	0xFA3127
	call	0xFB0A0D
	popw	bc
	ei	0
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
	incw	1, (xiz-2)
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
	ld	c, (0x007ED1:24)
	and	c, 0x10
	srl	c, 4
	cps	c, 0
	jr	z, MAIN__bit5
	resda_24 4, 0x007ED1
	call	0xF99E5F
	call	0xFB05EC
	ld	hl, (0x00E2DF:24)
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
	ei	0
	stib_da	0x007ECC, 0x00
	stiw_da	0x00F2F1, 0x000A
	pushw	0x0002
	call	0xF98510
	popw	bc
MAIN__reenable:
	ei	0
MAIN__bit5:
	ld	c, (0x007ED1:24)
	and	c, 0x20
	srl	c, 5
	cps	c, 0
	jr	z, MAIN__bit3
	resda_24 5, 0x007ED1
	calr	(0xF98A75 - 0xF98C8A)
MAIN__bit3:
	ld	c, (0x007ED1:24)
	and	c, 0x08
	srl	c, 3
	cps	c, 0
	jr	z, MAIN__tail
	resda_24 3, 0x007ED1
	calr	(0xF9915C - 0xF98CA1)
MAIN__tail:
	calr	(0xF98CB9 - 0xF98CA4)
	lda	xbc, (0x00E2EB:24)
	push	xbc
	call	0xFB060A
	call	0xF994E4
	pop	xiy
	jrl	MAIN__loop
	unlk32	xiz
	ret
