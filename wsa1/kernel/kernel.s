; ==============================================================================
; Technics SX-WSA1R -- THE MULTITASKING KERNEL, ONE SOURCE FOR BOTH PROCESSORS
; ==============================================================================
;
; The WSA1R has two Toshiba TMP95C061s and they run THE SAME KERNEL.  Until now
; that fact lived in a note.  This file is the fact itself: prom_a and prom_c
; both `.include` it, and both ROMs still rebuild byte for byte.
;
;     prom_a/wsa1_prom_a.s        CPU 1, "MICROCOMPUTER (MAIN)", IC1/IC12
;         .include "kernel/kernel_maincpu.inc"
;         .include "kernel/kernel.s"          ->  0xF85606-0xF85E89
;
;     prom_c/wsa1_prom_c.s        CPU 2, "MICROCOMPUTER (SUB)",  IC2/IC28
;         .include "kernel/kernel_subcpu.inc"
;         .include "kernel/kernel.s"          ->  0xF9816B-0xF989EE
;
;     every pair of addresses differs by exactly 0x12B65, first slot to last
;
; ★★ THE BYTE GATE IS THE PROOF, AND IT IS THE WHOLE POINT.
;
;     python3 scripts/analysis/assert_byte_identical.py
;
;   Two listings that look alike prove nothing.  ONE SOURCE that assembles to
;   2,180 bytes of prom_a and 2,180 bytes of prom_c, both byte-identical to the
;   original EPROMs, cannot be a resemblance.  If a single equate in either
;   kernel_*.inc is wrong, BOTH images stop rebuilding.
;
; ------------------------------------------------------------------------------
; HOW THE TWO COPIES DIFFER, measured before this file was written
; ------------------------------------------------------------------------------
;
;     python3 notes/kernel_join_probe.py --pairs
;     python3 notes/kernel_join_probe.py --diffs
;     python3 notes/kernel_join_probe.py --symbols
;
;   941 instruction slots, of which 939 exist on both sides as source lines.
;   735 of those 939 already say the same thing.  Of the 204 that do not:
;
;     129  the two files' HOUSE STYLE differs -- prom_a writes
;          `m_ld_rm MWD+r4, 0x00, r0` where prom_c writes `extpfx3 0x9C, 0x00,
;          0x20`, prom_c writes `ldio T23MOD, 14` where prom_a writes
;          `ldio 0x28, 0x0e`, and one of them uses a label where the other uses a
;          raw displacement.  The merge keeps whichever text NAMES MORE THINGS,
;          so neither file loses and 19 lines gain a name they did not have.
;      81  a value that kernel_maincpu.inc and kernel_subcpu.inc name, each
;          named ONCE and used symbolically here.  80 of them genuinely differ
;          between the two CPUs; the other 1 is KERNEL_TIMER_COUNT, which is 2
;          on both and is named only so the RAM map in the .inc files has no hole
;          exactly where the two processors agree.  (6 of the 81 are also a
;          house-style difference: a macro spelling AND a per-CPU address.)
;
;   ⚠ Those 81 sites are NOT 81 unrelated edits: they are 21 constants --
;     TWELVE RAM addresses (the stack top, two low-RAM cells and nine array
;     bases), SIX array sizes and THREE ROM pointers.  The two processors run the
;     same kernel over different RAM maps and with different array counts -- 4
;     tasks against 3, 8 semaphores against 4, 4 message queues against 2 -- and
;     that is the entire difference between them.
;
;   ⚠ These numbers are FORMATTED FROM THE MEASUREMENT, not typed: they cannot
;     disagree with what --diffs prints.
;
; ★ There is NO `.if CPU_MAINCPU` anywhere in this file, and that is deliberate.
;   Wrapping code in conditionals would duplicate every differing line at its
;   site; equates name each difference once and leave the body genuinely shared.
;
; ------------------------------------------------------------------------------
; WHAT THE MERGE DID TO THE TEXT -- so a reviewer can check it rather than trust it
; ------------------------------------------------------------------------------
;
; * Comments and headers were MOVED, not rewritten.  Where both files document
;   the same routine, BOTH headers are here, each under a banner saying which
;   file it came from.  prom_a's and prom_c's headers were written by different
;   passes and cite different call sites, so keeping one would have destroyed
;   real documentation.
; * Both files' LABELS are kept.  Where the two files name the same address
;   differently, prom_c's name is the label and prom_a's is emitted underneath it,
;   so a reference to either still resolves.  prom_c splits the block more finely
;   and gives real names to 11 addresses prom_a still spells `sub_F85B0D` and
;   7 it spells `.LF85B29`, so prom_a's kernel is better named than it was.
; * ⚠ ONE COMMENT LINE IS REWRITTEN, and it is enumerated in CORRECTIONS in
;   notes/kernel_join_probe.py rather than done quietly.  The banner
;   `; 0xF85D1C-0xF85E89 -- not yet converted` was WRONG BEFORE THE MERGE -- that
;   range has been converted for two rounds, and it is the standing "0 of 1"
;   failure of notes/prom_a_byte_checks.py's span-banner check.  Moving it here
;   unfixed would have made that check vacuous, because prom_a would have had no
;   banner left to fail on.
; * Each instruction line carries BOTH addresses, the bytes (both images' when
;   they differ), prom_c's disassembly text and prom_a's prose.  prom_a's block
;   carried the bytes and prom_c's carried the disassembly; the merged line
;   carries both.
; * ⚠ ONE prom_a name is NOT kept: prom_a calls 0xF85C89 `MsgQueue_ReceiveBlocking`
;   and prom_c calls the address three bytes later by that same name, having
;   split the routine into a stack face and a register face.  Keeping both would
;   define one symbol twice.  prom_c's finer split wins; prom_b reaches the
;   routine by address (`T_MsgQueue_ReceiveBlocking: jp 0xF85C89`), so nothing
;   dangles.
; * ★ prom_a GAINS 7 CONVERTED BYTES.  It held 0xF85C3D-0xF85C43 as `.incbin`;
;   prom_c has the same seven bytes decoded, and they are byte-identical in the
;   two EPROMs (`bf 0e 02 ff ff 68 f2`), so the merge takes prom_c's version and
;   prom_a's last `.incbin` inside the kernel disappears.
;
; ------------------------------------------------------------------------------
; THE ONE ROUTINE THE EARLIER PROBE COULD NOT PAIR
; ------------------------------------------------------------------------------
; notes/kernel_shared_source_probe.py reports 76 of 77 routines decoding to the
; same instruction count, the exception being Kernel_InitRam -- because the
; 8-byte block `SoftTimer_Request_Boot` is DATA inside the code stream and a
; linear decode frames it differently on each side.  That is a fact about the
; DISASSEMBLER, not about the source: both files already write those 8 bytes as
; `.short / .short / .long`, identically.  So it needs no duplication and no
; conditional -- only the callback address is per-CPU, and it is the equate
; KERNEL_BOOT_TIMER_CALLBACK.  Handled explicitly, not forced.
;
; ------------------------------------------------------------------------------
; ⚠ REGENERATING THIS FILE
; ------------------------------------------------------------------------------
; `python3 notes/kernel_join_probe.py --emit` produced the first version from
; prom_a's and prom_c's blocks.  It is kept as the RECORD OF THE MERGE, not as a
; build step: this file is the source now, and a re-run would discard anything
; edited here.  `--verify` re-checks the merge against both originals in git and
; is the thing to run after editing.
; ==============================================================================

; ------------------------------------------------------------------------------
; TLCS-900 byte-emitter macros, needed by the lines below that llvm-mc cannot
; spell.  ★ THIS FILE USED TO CARRY A SECOND COPY of prom_a's block -- a 17-name
; subset of it, moved verbatim.  Since 2026-08-30 there is ONE text,
; include/tlcs900_mem_ops.inc, which prom_a, prom_b and this file all include,
; and it is prom_a's full set rather than the subset.
;
; The guard stays, and it is load-bearing: prom_a includes that file directly
; too, and llvm-mc rejects a redefined macro.  kernel_maincpu.inc sets the guard
; symbol; kernel_subcpu.inc does not, because prom_c reaches these macros only
; through this file.
;
; ⚠ These emit BYTES.  The gate proves the bytes; it cannot prove the NAME on a
;   macro is the right mnemonic.  That comes from MAME's dasm900.cpp tables, as
;   argued at include/tlcs900_mem_ops.inc's own definitions, and every use below
;   carries unidasm's text in its trailing comment so the two can be compared by
;   eye.
; ------------------------------------------------------------------------------
.ifndef KERNEL_MEM_OPS_PROVIDED
	.include "include/tlcs900_mem_ops.inc"
.endif


; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ==============================================================================
; 0xF85606-0xF856EB -- Kernel_InitRam: the kernel's whole RAM map, written out
; ==============================================================================
;
; ★ THIS ROUTINE IS THE KERNEL'S DATA-STRUCTURE DECLARATION.  Every list head,
;   every node array and every array stride the kernel uses is created here, in
;   one pass, with literal addresses -- so the layout below is read off
;   immediates rather than inferred from the routines that later use it.  Each
;   row names the instruction that writes it and, where one exists, the already-
;   converted routine that independently confirms the same address:
;
;     0x0300 + (A-1)*12   4 task control blocks, +9 (state) := 0    0xF8562A
;                         -- Kernel_StartTask computes 0x02F4 + A*12
;     0x0330 + (n-1)*4    3 READY QUEUE heads, self-linked          0xF85615
;                         -- Kernel_Dispatch scans three heads from 0x0330
;     0x033C + (i-1)*4    8 more list heads, self-linked            0xF85662
;                         -- ⚠ what they queue is NOT established here
;     0x035C              8 bytes copied from ROM 0xF85EBA          0xF85653
;     0x0364 + (A-1)*4    4 heads, self-linked                      0xF856B5
;                         -- MsgQueue_ReceiveBlocking's WAIT queue, 0x0360+A*4
;     0x0374 + (A-1)*4    4 heads, self-linked                      0xF856C7
;                         -- MsgQueue_ReceiveBlocking's MESSAGE queue, 0x0370+A*4
;     0x0384 + i*8        8 nodes of 8 bytes, +4 := 0xFFFFFFFF      0xF85674
;     0x03C4              1 head, self-linked, then all 8 of those
;                         nodes appended to it                      0xF8568A
;                         -- MsgQueue_ReceiveBlocking's FREE LIST at 0x03C4
;     0x03C8 + (n-1)*8    2 software timers, +4 := 0xFFFFFFFF       0xF8563D
;                         -- Kernel_ServiceSoftTimers walks two 8-byte slots
;                            at 0x03C8 and treats +4 = 0xFFFFFFFF as "empty"
;
; ★ AND IT SETTLES THE 1-BASED CONVENTION.  The four TCBs are written from
;   0x0300 with stride 12 and B = 4, so they occupy 0x0300-0x032F and the first
;   ready-queue head at 0x0330 begins immediately after them.  There is no
;   8-byte hole: Kernel_StartTask's `0x02F4 + A*12` and the queue primitives'
;   `0x032C + n*4` are the same layout written with a one-element bias, and
;   MsgQueue_ReceiveBlocking's `0x0360 + A*4` / `0x0370 + A*4` are two more
;   instances of it.  A = 1..4 and level n = 1..3 throughout.
;
; ★ IT ALSO IDENTIFIES 0xF85EBA.  Those eight bytes sit immediately after
;   EntryPoint_Records and this file has carried them as "UNIDENTIFIED.  Not a
;   fifth record".  They are a ROM IMAGE OF RAM 0x035C-0x0363: `ldir` copies
;   exactly 8 bytes from 0xF85EBA to 0x035C at 0xF85653-0xF85661.  What the
;   eight bytes MEAN is still not established -- only where they go.
;
; Everything quantified above is re-derived from the ROM by
; notes/prom_a_byte_checks.py.
;
; ---------------------------------------------------------------------
; Kernel_InitRam -- build every kernel list and block, then fall into Kernel_Start
;
; Called from: prom_b thunk 0xF42D60 (`jp 0xF85606`), and nothing else -- that
;          is the only site in either ROM naming this address
;          (notes/prom_a_byte_checks.py).
; Inputs:  none
; Outputs: the RAM map in the banner above; XSP = the boot stack 0x0060EB80;
;          (0xBF) = 0, no task running; control register 0x3C = 1, so the
;          kernel starts inside one level of critical section.  It does not
;          return -- its last instruction is a `call` and it then falls into
;          Kernel_Start.
; Evidence: every address in the banner is an IMMEDIATE in this routine and
;          every count is a `ldb b,imm` loop bound; nothing is inferred from a
;          consumer.  The self-linking idiom is `ld IX,HL` followed by two
;          `ld (XHL+),IX` -- head->next = head, head->prev = head, four bytes,
;          which is the empty-list state Kernel_Dispatch tests with `cp HL,IX`
;          and Kernel_YieldRotate with head->next == head->prev.
;          The eight-node append at 0xF8569A-0xF856B4 is the tree's
;          insert-at-tail idiom verbatim, the same four stores as
;          0xF858AF-0xF858BC and 0xF85839-0xF85846.
; Unknown:  what the eight heads at 0x033C queue, and what the eight bytes
;          copied to 0x035C are for.  ⚠ `ld DE,0x0004` at 0xF8561A is DEAD
;          WITHIN THIS REGION -- DE is reloaded at 0xF85658 before anything
;          reads it.  That is a statement about these 230 bytes only.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; ==============================================================================
; 0xF9816B-0xF989EE -- ★★ CPU 2's MULTITASKING KERNEL, all 2,180 bytes of it
; ==============================================================================
;
; This is the same kernel prom_a carries, compiled for the other processor.  The
; correspondence is not a resemblance: it is 35 routines, in the SAME ORDER, with
; the SAME LENGTH to the byte, and 34 of the 35 have ZERO structural differences
; when aligned instruction by instruction -- every difference is an operand, and
; every one of those operands is a RAM address, a table address, a branch target
; or an array bound.
;
;   $ python3 notes/prom_c_kernel_map.py --pairs
;
; re-derives the whole table (it is the script every count on this page comes
; from) and asserts the LAST pair as well as the first.  The one pair that shows
; "structural" differences, Kernel_InitRam, differs only inside the eight-byte
; INLINE DATA BLOCK both copies embed in their code stream -- unidasm decodes the
; two records as two different pieces of nonsense, which is what a data block
; looks like to an instruction decoder.
;
; ★ THE RAM MAP, AND WHY THE COUNTS ARE NOT GUESSES.  Kernel_InitRam below writes
; nine arrays with literal bases and literal `ldb b,N` loop counts.  Laid out in
; address order they TILE 0x0100-0x0183 exactly -- no gap and no overlap:
;
;   0x0100 + (t-1)*12   3 task control blocks     +9 (state) := 0
;   0x0124 + (n-1)*4    2 ready-queue heads       self-linked
;   0x012C + (s-1)*4    4 semaphore wait queues   self-linked
;   0x013C + (s-1)      4 semaphore counts        copied from ROM 0xF9810E
;   0x0140 + (q-1)*4    2 message WAIT queues     self-linked
;   0x0148 + (q-1)*4    2 MESSAGE queues          self-linked
;   0x0150 + i*8        4 free nodes              +4 := 0xFFFFFFFF, all appended
;   0x0170              the free-list head        self-linked
;   0x0174 + (n-1)*8    2 software timers         +4 := 0xFFFFFFFF
;
;   3*12=36, 2*4=8, 4*4=16, 4*1=4, 2*4=8, 2*4=8, 4*8=32, 4, 2*8=16 -- and
;   0x0100+36 = 0x0124, +8 = 0x012C, +16 = 0x013C, +4 = 0x0140, +8 = 0x0148,
;   +8 = 0x0150, +32 = 0x0170, +4 = 0x0174, +16 = 0x0184.  A wrong count anywhere
;   in that chain would leave a hole or an overlap; there is neither.
;   `notes/prom_c_kernel_map.py` re-derives all nine bases and counts from the
;   instruction bytes and re-checks the tiling.
;
; Everything in this kernel is ONE-BASED, exactly as prom_a's is: the code forms
; `0x00F4 + t*12`, `0x0120 + n*4`, `0x0128 + s*4`, `0x013B + s`, `0x013C + q*4`,
; `0x0144 + q*4` and `0x016C + n*8`, each of which is the array base minus one
; element.
;
; Two scalars and one control register complete it:
;   (0x0090)   pending kernel ticks, a byte.  INTT3_KernelTick increments it
;              (`inc 1,(0x90)` at 0xF98165) and Kernel_Dispatch drains it.
;   (0x0091)   LE16 pointer to the RUNNING task's control block; 0 means "we are
;              on the kernel's own stack".
;   cr 0x3C    a 16-bit control register used as the dispatch-inhibit depth.
;              ⚠ NOT NAMED HERE.  MAME's TLCS-900 disassembler prints every
;              control register it does not know as `unknown`, and its symbol
;              table for this exact part names only the SIXTEEN micro-DMA
;              registers -- DMAM0-3, DMAC0-3, DMAS0-3, DMAD0-3, four rows of
;              four (`tmp95c061_cr_syms[]`, tmp95c061.cpp:1394-1399, counted in
;              the source; * CORRECTED 2026-08-25, round-2 audit F7, from
;              "eight"); the emulator maps
;              every other 16-bit control-register encoding to a scratch variable
;              (`m_p2_reg16 = &m_dummy.w.l`, the `default:` arm of `case p_CR16:`
;              in 900tbl.hxx).  So what this register IS is not established by
;              anything in these trees -- only what the firmware DOES with it,
;              which is: zero it at boot, increment it around the software-timer
;              scan, and refuse to reschedule unless it reads 0 (dispatcher) or 1
;              (interrupt epilogue).
;   0x0000FA00 the kernel's own stack, installed by Kernel_InitRam and reinstalled
;              by Kernel_Dispatch every time it leaves a task.
;
; ★ CPU 2 RUNS THREE TASKS, and this block is what makes the rest of the image
;   readable:
;     task 1  MAIN (0xF98B7D)                  level 2   started by Kernel_Start
;     task 2  0xFA54DB                         level 2   started by 0xFA3365
;     task 3  DSP_ChannelRefresh_Loop (0xF98118) level 1 started by Kernel_Start
;   The levels come from EntryPoint_Records+10 (2, 2, 1) and there are exactly
;   TWO ready queues, so 1 and 2 are the only values that index inside the array --
;   a bound check the table passes.
;
; ★ AND THE SEMAPHORES ARE WIRED.  The four initial counts are the four bytes at
;   0xF9810E, `01 00 01 01`: s1 = 1, s2 = 0, s3 = 1, s4 = 1.  Semaphore 2 is the
;   one that starts taken, and it is the one the firmware actually uses -- MAIN
;   signals it (`push 0x0002 / call Kernel_SemaSignal_StackArg` at 0xF98C69) and
;   so does 0xFA2DE0, while task 2 at 0xFA54DB waits on it and then drains it with
;   Kernel_SemaTryWait(2).  Semaphore 3 is what DSP_ChannelRefresh_Loop waits on.
;
;   ⚠ AND NOTHING FOUND EVER SIGNALS SEMAPHORE 3.  Both Signal call sites push 2;
;   Kernel_SemaSignal_NoDispatch and its stack face have no call site at all
;   (`python3 notes/prom_c_kernel_map.py --callers`, which censuses every entry).
;   With an
;   initial count of 1, that makes the DSP refresh task run exactly ONE pass and
;   then block for ever.  Recorded as a searched negative with the search named:
;   prom_c_xrefs.py does not see a target computed at run time.
;
; --------------------------------------------------------------------------
; Kernel_InitRam -- build the kernel's whole RAM state, then fall into Kernel_Start.
;
; Called from: RESET's last instruction, `jp 0xF9816B` at 0xFFF09E, and from
;              IRQ_UNUSED at 0xFFF0A8, which is the vector for twenty of the 33
;              interrupt slots.  Those are the only two references
;              (`python3 notes/prom_c_xrefs.py 0xF9816B --no-window`).
; Inputs:  none.
; Outputs: XSP = 0x0000FA00, (0x0091) = 0, cr 0x3C = 1, the nine arrays above,
;          one software timer registered, and control falls into Kernel_Start.
; Evidence: every base and every count is a literal in this listing and they tile
;          0x0100-0x0183 with no gap -- the argument is in the block comment
;          above and re-derived by `python3 notes/prom_c_kernel_map.py`.
;          The self-linking idiom `ld IX,HL / ld (XHL+),IX / ld (XHL+),IX` writes
;          head->next = head->prev = head, which is exactly the empty-list state
;          Kernel_Dispatch__scan tests with `cp HL,IX`.
;          Instruction for instruction this is prom_a's Kernel_InitRam
;          (0xF85606, also 230 bytes): 84 slots aligned, 0 different mnemonics
;          outside the inline data block, 31 operand differences, and every one
;          of the 31 is a base address, a loop count or a branch target.
; Unknown:  ⚠ the first `ld DE,0x0004` (0xF9817F) is loaded and never used before
;          DE is reloaded at 0xF981BD -- dead in this copy, as it is in prom_a's.
; --------------------------------------------------------------------------

Kernel_InitRam:
	ld XSP,KERNEL_STACK_TOP                      ; F85606/F9816B  a=47 80 eb 60 00 c=47 00 fa 00 00   c: ld XSP,0x0000fa00   the boot stack
	xor WA,WA                                    ; F8560B/F98170  d8 d0   xor WA,WA
	st_dd8w wa, KERNEL_CURRENT_TASK              ; F8560D/F98172  a=f0 bf 50 c=f0 91 50   c: ld (0x91),WA   (0xBF) = 0: no task is running
	inc 1,WA                                     ; F85610/F98175  d8 61   inc 1,WA
	m_ldc_cr_reg RW+r0, 0x3c                     ; F85612/F98177  d8 2e 3c   ldc unknown,WA   critical-section depth := 1
	ldw hl, KERNEL_READY_HEADS                   ; F85615/F9817A  a=33 30 03 c=33 24 01   c: ld HL,0x0124   the THREE READY QUEUE heads
	extz XHL                                     ; F85618/F9817D  eb 12   extz XHL
	ldw de, 0x04                                 ; F8561A/F9817F  32 04 00   ld DE,0x0004   dead here -- DE is reloaded at 0xF85658
	ld b, KERNEL_READY_LEVELS:opc                   ; F8561D/F98182  a=22 03 c=22 02   c: ld B,0x02
Kernel_InitRam__ready_queues:
	ld IX,HL                                     ; F8561F/F98184  db 8c   ld IX,HL
	stw_dpi ix, 0xed                             ; F85621/F98186  f5 ed 54   ld (XHL+),IX   head->next = head
	stw_dpi ix, 0xed                             ; F85624/F98189  f5 ed 54   ld (XHL+),IX   head->prev = head
	djnz8 b, Kernel_InitRam__ready_queues        ; F85627/F9818C  ca 1c f5   djnz B,0xf98184
	ldw ix, KERNEL_TCB_BASE                      ; F8562A/F9818F  a=34 00 03 c=34 00 01   c: ld IX,0x0100   the FOUR task control blocks
	extz XIX                                     ; F8562D/F98192  ec 12   extz XIX
	ld b, KERNEL_TASK_COUNT:opc                     ; F8562F/F98194  a=22 04 c=22 03   c: ld B,0x03
	ld a, 0x00:opc                                  ; F85631/F98196  21 00   ld A,0x00
Kernel_InitRam__tcbs:
	ld (XIX+0x09),A                              ; F85633/F98198  bc 09 41   ld (XIX+0x09),A   +9 = state 0, which is what Kernel_StartTask requires
	add IX,0x000c                                ; F85636/F9819B  dc c8 0c 00   add IX,0x000c   stride 12: 0x0300 0x030C 0x0318 0x0324
	djnz8 b, Kernel_InitRam__tcbs                ; F8563A/F9819F  ca 1c f6   djnz B,0xf98198
	ldw ix, KERNEL_TIMERS                        ; F8563D/F981A2  a=34 c8 03 c=34 74 01   c: ld IX,0x0174   the TWO software timers
	extz XIX                                     ; F85640/F981A5  ec 12   extz XIX
	ld b, KERNEL_TIMER_COUNT:opc                    ; F85642/F981A7  22 02   ld B,0x02
	ld XWA,0xffffffff                            ; F85644/F981A9  40 ff ff ff ff   ld XWA,0xffffffff
Kernel_InitRam__soft_timers:
	ld (XIX+0x04),XWA                            ; F85649/F981AE  bc 04 60   ld (XIX+0x04),XWA   +4 = no callback; Kernel_ServiceSoftTimers skips on this
	add IX,0x0008                                ; F8564C/F981B1  dc c8 08 00   add IX,0x0008
	djnz8 b, Kernel_InitRam__soft_timers         ; F85650/F981B5  ca 1c f6   djnz B,0xf981ae
	ld XHL,KERNEL_SEMA_COUNT_IMAGE               ; F85653/F981B8  a=43 ba 5e f8 00 c=43 0e 81 f9 00   c: ld XHL,0x00f9810e   the 8 ROM bytes after EntryPoint_Records
	ldw de, KERNEL_SEMA_COUNTS                   ; F85658/F981BD  a=32 5c 03 c=32 3c 01   c: ld DE,0x013c
	extz XDE                                     ; F8565B/F981C0  ea 12   extz XDE
	ldw bc, KERNEL_SEMA_COUNT                    ; F8565D/F981C2  a=31 08 00 c=31 04 00   c: ld BC,0x0004
	ldir83                                       ; F85660/F981C5  83 11   ldir   (XDE+) <- (XHL+), 8 bytes: RAM 0x035C-0x0363
	ldw hl, KERNEL_SEMA_QUEUES                   ; F85662/F981C7  a=33 3c 03 c=33 2c 01   c: ld HL,0x012c   EIGHT more list heads
	extz XHL                                     ; F85665/F981CA  eb 12   extz XHL
	ld b, KERNEL_SEMA_COUNT:opc                     ; F85667/F981CC  a=22 08 c=22 04   c: ld B,0x04
Kernel_InitRam__sema_queues:
Kernel_InitRam__heads_033C:   ; <- prom_a's name for this address.
	ld IX,HL                                     ; F85669/F981CE  db 8c   ld IX,HL
	stw_dpi ix, 0xed                             ; F8566B/F981D0  f5 ed 54   ld (XHL+),IX
	stw_dpi ix, 0xed                             ; F8566E/F981D3  f5 ed 54   ld (XHL+),IX
	djnz8 b, Kernel_InitRam__heads_033C          ; F85671/F981D6  ca 1c f5   djnz B,0xf981ce
	ldw hl, KERNEL_NODE_POOL                     ; F85674/F981D9  a=33 84 03 c=33 50 01   c: ld HL,0x0150   EIGHT 8-byte nodes
	extz XHL                                     ; F85677/F981DC  eb 12   extz XHL
	ld b, KERNEL_NODE_COUNT:opc                     ; F85679/F981DE  a=22 08 c=22 04   c: ld B,0x04
	ld XWA,0xffffffff                            ; F8567B/F981E0  40 ff ff ff ff   ld XWA,0xffffffff
Kernel_InitRam__free_nodes:
	ld (XHL+0x04),XWA                            ; F85680/F981E5  bb 04 60   ld (XHL+0x04),XWA   +4 = the payload, cleared to all-ones
	add HL,0x0008                                ; F85683/F981E8  db c8 08 00   add HL,0x0008
	djnz8 b, Kernel_InitRam__free_nodes          ; F85687/F981EC  ca 1c f6   djnz B,0xf981e5
	ldw iy, KERNEL_FREE_LIST                     ; F8568A/F981EF  a=35 c4 03 c=35 70 01   c: ld IY,0x0170   the FREE LIST head
	extz XIY                                     ; F8568D/F981F2  ed 12   extz XIY
	m_st_mr16 MDD+r5, 0x00, r5                   ; F8568F/F981F4  bd 00 55   ld (XIY+0x00),IY   ld (XIY+0x00),IY -- head->next = head
	ld (XIY+0x02),IY                             ; F85692/F981F7  bd 02 55   ld (XIY+0x02),IY   head->prev = head
	ldw ix, KERNEL_NODE_POOL                     ; F85695/F981FA  a=34 84 03 c=34 50 01   c: ld IX,0x0150
	ld b, KERNEL_NODE_COUNT:opc                     ; F85698/F981FD  a=22 08 c=22 04   c: ld B,0x04
Kernel_InitRam__free_append:
	extz XIX                                     ; F8569A/F981FF  ec 12   extz XIX
	extz XIY                                     ; F8569C/F98201  ed 12   extz XIY
	extz XWA                                     ; F8569E/F98203  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F856A0/F98205  bc 00 55   ld (XIX+0x00),IY   ld (XIX+0x00),IY -- n->next = head
	ld WA,(XIY+0x02)                             ; F856A3/F98208  9d 02 20   ld WA,(XIY+0x02)
	ld (XIX+0x02),WA                             ; F856A6/F9820B  bc 02 50   ld (XIX+0x02),WA   n->prev = head->prev
	ld (XWA),IX                                  ; F856A9/F9820E  b0 54   ld (XWA),IX   head->prev->next = n
	ld (XIY+0x02),IX                             ; F856AB/F98210  bd 02 54   ld (XIY+0x02),IX   head->prev = n
	add IX,0x0008                                ; F856AE/F98213  dc c8 08 00   add IX,0x0008
	djnz8 b, Kernel_InitRam__free_append         ; F856B2/F98217  ca 1c e5   djnz B,0xf981ff
	ldw hl, KERNEL_MSGQ_WAITQ                    ; F856B5/F9821A  a=33 64 03 c=33 40 01   c: ld HL,0x0140   FOUR heads -- the wait queues
	extz XHL                                     ; F856B8/F9821D  eb 12   extz XHL
	ld b, KERNEL_MSGQ_COUNT:opc                     ; F856BA/F9821F  a=22 04 c=22 02   c: ld B,0x02
Kernel_InitRam__wait_queues:
	ld IX,HL                                     ; F856BC/F98221  db 8c   ld IX,HL
	stw_dpi ix, 0xed                             ; F856BE/F98223  f5 ed 54   ld (XHL+),IX
	stw_dpi ix, 0xed                             ; F856C1/F98226  f5 ed 54   ld (XHL+),IX
	djnz8 b, Kernel_InitRam__wait_queues         ; F856C4/F98229  ca 1c f5   djnz B,0xf98221
	ldw hl, KERNEL_MSGQ_HEADS                    ; F856C7/F9822C  a=33 74 03 c=33 48 01   c: ld HL,0x0148   FOUR heads -- the message queues
	extz XHL                                     ; F856CA/F9822F  eb 12   extz XHL
	ld b, KERNEL_MSGQ_COUNT:opc                     ; F856CC/F98231  a=22 04 c=22 02   c: ld B,0x02
Kernel_InitRam__msg_queues:
	ld IX,HL                                     ; F856CE/F98233  db 8c   ld IX,HL
	stw_dpi ix, 0xed                             ; F856D0/F98235  f5 ed 54   ld (XHL+),IX
	stw_dpi ix, 0xed                             ; F856D3/F98238  f5 ed 54   ld (XHL+),IX
	djnz8 b, Kernel_InitRam__msg_queues          ; F856D6/F9823B  ca 1c f5   djnz B,0xf98233
	ld XIX,SoftTimer_Request_Boot                ; F856D9/F9823E  a=44 e0 56 f8 00 c=44 45 82 f9 00   c: ld XIX,0x00f98245   the argument for the call below
	jr Kernel_InitRam__install                   ; F856DE/F98243  68 08   jr T,0xf9824d   step over the argument block

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ---------------------------------------------------------------------
; SoftTimer_Request_Boot -- 8 bytes of argument, INLINE in the code stream
;
; Read by:  the routine at 0xF85D78, through XIX, which the instruction above
;          loads with this address.  Nothing else in either ROM names it
;          (notes/prom_a_byte_checks.py).
; Layout:  the fields are read off the CALLEE, so only two of the three are
;          established:
;            +0  LE16  0x0001  0xF85D82 reads it as a BYTE (`ld A,(XIX+0x00)`)
;                              and forms 0x03C0 + A*8 (0xF85D85-0xF85D88).
;                              0x03C0 + 1*8 = 0x03C8, software timer slot 1 --
;                              the array this very routine initialised, and the
;                              same one-element bias as everywhere else here.
;            +2  LE16  0x0001  ⚠ NOT established.  Do not assume it is the
;                              reload value: the software-timer SLOT layout is
;                              (+0 countdown, +2 reload, +4 callback), and this
;                              block is a REQUEST with a different +0, so the
;                              two layouts must not be conflated.
;            +4  LE32  0x00F85EC2  a code address in this file -- sub_F85EC2,
;                              which notes/prom_a_byte_checks.py records as
;                              calling Kernel_YieldRotate with A = 3.
; Evidence: it is DATA and not code, and that is settled by the branch, not by
;          taste: the `jr` at 0xF856DE targets 0xF856E8, which steps over
;          exactly these eight bytes, and 0xF856E8 is where the next
;          instruction starts.  Reading 0xF856E4 as code is what produced this
;          file's old (and wrong) "0xF856E9 `jrl 0xF84F49`".
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; SoftTimer_Request_Boot -- 8 bytes of ARGUMENT, inline in the code stream.
;
; Read by:  SoftTimer_Register (0xF988DD) through XIX, which the `ld XIX,0x00F98245`
;          two instructions above loads with this address.  Nothing else names it.
; Layout:  read off the callee, so only the fields the callee reads are established:
;            +0  LE16 0x0001   SoftTimer_Register reads it as a BYTE and forms
;                              0x016C + A*8 = 0x0174, software-timer slot 1
;            +2  LE16 0x0001   copied into BOTH slot+0 and slot+2, i.e. the
;                              countdown AND the reload
;            +4  LE32 0x00F98112  the callback -- SoftTimer_RotateLevel2, three
;                              instructions above this file's first .incbin
; Evidence: it is DATA and not code because the `jr` at 0xF98243 targets 0xF9824D,
;          stepping over exactly these eight bytes, and 0xF9824D is where the next
;          instruction begins.  prom_a's copy is the same eight-byte shape at
;          0xF856E0 (SoftTimer_Request_Boot there), with 0x00F85EC2 in +4.
; --------------------------------------------------------------------------

SoftTimer_Request_Boot:
	.short 0x0001                                ; F856E0/F98245  01 00   slot number, read as a BYTE by SoftTimer_Register   slot index, read as a byte by 0xF85D78
	.short 0x0001                                ; F856E2/F98247  01 00   copied into BOTH slot+0 and slot+2   ⚠ role not established
	.long KERNEL_BOOT_TIMER_CALLBACK             ; F856E4/F98249  a=c2 5e f8 00 c=12 81 f9 00   c: the callback: SoftTimer_RotateLevel2   sub_F85EC2
Kernel_InitRam__install:
	call SoftTimer_Register                      ; F856E8/F9824D  a=1d 78 5d f8 c=1d dd 88 f9   c: call 0xf988dd   install that request, then FALL INTO Kernel_Start

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ==============================================================================
; 0xF856EC-0xF857D5 -- the kernel: idle loop, task switch, software timers, and
;                      the interrupt epilogue every handler exits through
; ==============================================================================
;
; ★ prom_a CONTAINS A SMALL MULTITASKING KERNEL.  That is the structural finding
;   here, and it is read off the data structures, not assumed:
;
;     0x0330  three TASK CONTROL BLOCKS, 8 bytes each.  +0 is a ready word --
;             Kernel_Dispatch__scan walks the three and takes the first whose +0
;             is NOT equal to its own address, so a self-referential TCB means
;             "not ready".  +4 is the task's saved XSP.
;     0x03C8  two SOFTWARE TIMER slots, 8 bytes each.  +0 countdown, +2 reload,
;             +4 callback address, with 0xFFFFFFFF meaning "empty".
;     (0xBE)  pending kernel ticks, produced elsewhere and drained here
;     (0xBF)  the task currently running, 0 = "we are on the kernel's own stack"
;     cr 0x3C the critical-section DEPTH.  Incremented on entry to the timer
;             service and decremented on exit; the epilogue below runs the kernel
;             only when it reads exactly 1, and SWI7_ServiceCall_Dispatch writes 0
;             to it so a service call never triggers a switch.
;
;   ⚠ Control register 0x3C is left as a number.  unidasm prints control-register
;   numbers as "unknown", MAME does not name them, and no databook is in these
;   trees.  What it DOES here is established by the code; what Toshiba calls it
;   is not established by anything available.
;
;   ⚠ Kernel_Idle is an interrupts-enabled spin, not a HALT.  Reached when no
;   task is ready.
;
; The stack layout the two halves agree on is the identification: the epilogue
; pushes XHL, XWA, XBC, XDE, XIX, XIY, XIZ and falls into the dispatcher;
; Kernel_ResumeTask pops XIZ, XIY, XIX, XDE, XBC, XWA, XHL, then SR, then RETs.
; Same seven registers in the opposite order, plus the SR and PC the interrupt
; itself pushed -- so "resume a task" and "return from an interrupt" are the same
; frame, which is what makes the switch work at all.
;
; ---------------------------------------------------------------------
; Kernel_Start -- programme timer 3, start TASKS 1 and 3, enter the kernel
;
; Called from: FALLEN INTO from Kernel_InitRam, whose last instruction is
;          `call 0xF85D78` at 0xF856E8 -- four bytes ending exactly at this
;          label.  Nothing branches or calls here.
; Inputs:  none
; Outputs: timer 3 stopped and re-programmed (T23MOD = 0x0E, TREG3 = 0x36,
;          INTET32 = 0x20), TASKS 1 and 3 started through Kernel_StartTask, the
;          depth counter cleared, and control passed to Kernel_Dispatch.
;          Never returns.
; Evidence: the three `ldio`s name their registers by SFR ADDRESS out of
;          include/tmp95c061_sfr.inc -- 0x28 T23MOD, 0x27 TREG3, 0x74 INTET32
;          -- and 0xF856EC clears TRUN bit 3 first, which is "stop timer 3
;          before reprogramming it".  The two `ld A,imm / call 0xF857D9` pairs
;          with A = 1 and A = 3 (0xF856F8, 0xF856FE) reach Kernel_StartTask,
;          converted below, and A there is a TASK number: A = 1 is
;          EntryPoint_Records[0] (entry 0xF4005C, level 3) and A = 3 is
;          EntryPoint_Records[2] (entry 0xF85EC8 = DSP_RefreshTask, level 1).
;          "Enter the kernel" is the tail: 0xF8570E is `jrl Kernel_Dispatch`, a
;          JUMP, so this routine never resumes.
;
; ★ CORRECTED 2026-08-25, twice over.
;   (1) This header said "arm two software timers" and "0xF857D9 takes a slot
;       number in A; it is the 'register a software timer' entry".  0xF857D9 is
;       Kernel_StartTask -- it indexes EntryPoint_Records and the task control
;       blocks and appends to a READY QUEUE.  The software-timer registration is
;       a different routine, 0xF85D78, and this routine does not call it.
;   (2) "falls in from 0xF856E9's `jrl 0xF84F49`" cited an instruction that does
;       not exist: 0xF856E8 is `call 0xF85D78` (opcode 0x1D at 0xF856E8, its
;       operand at 0xF856E9), which is why a disassembly starting mid-region
;       decoded 0xF856E9 as a `jrl`.  The `jr` at 0xF856DE targets 0xF856E8 and
;       fixes the boundary.  Nothing in either ROM names 0xF84F49 at all --
;       notes/prom_a_byte_checks.py re-derives that.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_Start -- programme timer 3, start tasks 1 and 3, enter the scheduler.
;
; Called from: NOTHING -- it is FALLEN INTO.  Kernel_InitRam's last instruction
;              is a four-byte `call` to SoftTimer_Register that ends exactly at
;              this label, and nothing branches here (prom_c_xrefs.py 0xF98251
;              reports zero sites of any kind).
; Inputs:  none.
; Outputs: TRUN bit 3 cleared, T23MOD = 0x0E, TREG3 = 0x36, INTET32 = 0x20, timer
;          3 restarted; tasks 1 and 3 started; interrupt mask set to 6;
;          (0x0090) = 0; cr 0x3C = 0; then `jrl Kernel_Dispatch` -- never returns.
; Evidence: the SFR numbers are TRUN 0x20, T23MOD 0x28, TREG3 0x27, INTET32 0x74
;          in include/tmp95c061_sfr.inc.  The two `ldb a,imm / call 0xF9833E`
;          pairs reach Kernel_StartTask, and A there is a TASK NUMBER: A = 1 is
;          EntryPoint_Records[0] (MAIN, level 2) and A = 3 is
;          EntryPoint_Records[2] (DSP_ChannelRefresh_Loop, level 1).
;          prom_a's Kernel_Start (0xF856EC) is the same 13 instructions with 4
;          operand differences and 0 structural ones -- and it starts ITS records
;          0 and 2 with the same A = 1 and A = 3.
; ★ TIMER 3 IS PROGRAMMED TWICE, WITH DIFFERENT PERIODS.  Here TREG3 = 0x36 (54);
;          Timer3_Init (0xF98B6D), called from MAIN's init chain, later writes
;          TREG3 = 0x2E (46).  MAIN is task 1, started by this routine, so the
;          order is 0x36 first and 0x2E for the rest of the run.  Both values are
;          recorded, not decoded: the count RATE depends on the T23MOD field
;          neither this pass nor Timer3_Init's can decode.
; Unknown:  ⚠ nothing here starts task 2; 0xFA3365 does, and that routine is not
;          converted.
; --------------------------------------------------------------------------

Kernel_Start:
	res_dd8 3, TRUN                              ; F856EC/F98251  f0 20 b3   res 3,(0x20)   TRUN bit 3 = timer 3 off
	ld (T23MOD:8), 14:io                              ; F856EF/F98254  08 28 0e   ld (0x28),0x0e   T23MOD
	ld (TREG3:8), 54:io                               ; F856F2/F98257  08 27 36   ld (0x27),0x36   TREG3
	ld (INTET32:8), 32:io                             ; F856F5/F9825A  08 74 20   ld (0x74),0x20   INTET32
	ld a, 0x01:opc                                  ; F856F8/F9825D  21 01   ld A,0x01
	call Kernel_StartTask                        ; F856FA/F9825F  a=1d d9 57 f8 c=1d 3e 83 f9   c: call 0xf9833e
	ld a, 0x03:opc                                  ; F856FE/F98263  21 03   ld A,0x03
	call Kernel_StartTask                        ; F85700/F98265  a=1d d9 57 f8 c=1d 3e 83 f9   c: call 0xf9833e
	ei 0x06                                      ; F85704/F98269  06 06   ei 0x06
	ld (KERNEL_PENDING_TICKS:8), 0x00:io              ; F85706/F9826B  a=08 be 00 c=08 90 00   c: ld (0x90),0x00
	xor WA,WA                                    ; F85709/F9826E  d8 d0   xor WA,WA
	m_ldc_cr_reg RW+r0, 0x3c                     ; F8570B/F98270  d8 2e 3c   ldc unknown,WA   the depth counter starts at 0
	jrl Kernel_Dispatch                          ; F8570E/F98273  78 04 00   jrl T,0xf9827a

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_Idle -- no task is ready: enable every interrupt and spin.
;
; Called from: Kernel_Dispatch__scan, by `jr` when the ready-queue walk finds
;              both heads still self-linked.
; Inputs:  none.  Outputs: none -- it is left only by an interrupt.
; Evidence: two instructions.  ⚠ `ei 0` is NOT a disable: MAME's op_EI writes the
;          immediate into SR bits 6-4 (900tbl.hxx:2073-2078) and
;          tlcs900_check_irqs scans priorities from max(1,(SR>>4)&7) upward
;          (tmp95c061.cpp:536-545), so a level of 0 accepts every maskable
;          interrupt and `ei 7` is the one that blocks them.  An idle loop with
;          interrupts off could never be left, which is the independent check.
; --------------------------------------------------------------------------

Kernel_Idle:
	ei 0x00                                      ; F85711/F98276  06 00   ei 0x00
Kernel_Idle__loop:
	jr Kernel_Idle__loop                         ; F85713/F98278  68 fe   jr T,0xf98278

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ---------------------------------------------------------------------
; Kernel_Dispatch -- drain the tick queue, then pick a task and resume it
;
; Called from: Kernel_Start, and from IRQ_Epilogue (0xF857D3) on every interrupt
;          that was not nested
; Inputs:  cr 0x3C (must be 0 to proceed), (0xBE), (0xBF), the three ready-queue
;          heads at 0x0330/0x0334/0x0338
; Outputs: control transferred into a task, or into Kernel_Idle when none is
;          ready.  Does not return to its caller.
; Evidence: the structural reading below is what names it, and its two
;          keystones are re-derived from the ROM by
;          notes/prom_a_byte_checks.py -- "Kernel_Dispatch: scans 3 heads from
;          0x0330 with stride 4" and "Kernel_Dispatch: reads the saved XSP
;          from node+4". The same script pins that the queue primitives
;          address exactly those three heads ("0x032C + n*4 for n=1,2,3 is
;          exactly Kernel_Dispatch's three heads") and that the boot stack
;          this routine switches to lies inside the entry records' stack run.
; Notes:   if the current task's XSP is still live it is saved into that task's
;          node first and the kernel switches to the boot stack 0x0060EB80 -- the
;          same address RESET's continuation sets, which is the second sign that
;          this is the top of the system rather than a subroutine.
;
; ★ CORRECTED 2026-08-25.  This header used to call 0x0330 "the task control
;   blocks: 3 x 8 bytes".  It is THREE FOUR-BYTE LIST HEADS -- the scan steps
;   `inc 4,IX` three times, and the emptiness test `cp HL,IX` is a circular
;   list's "head->next == &head".  The task control blocks are the NODES on those
;   lists: the very next instruction, `ld XSP,(XHL+0x04)`, reads the saved stack
;   out of the node HL and not out of 0x0330.  The queue primitives at 0xF85877
;   and 0xF85C89 (converted below) address the same three heads as
;   0x032C + n*4 for n = 1, 2, 3, and share the node layout
;   (+0 next, +2 prev, +4 saved XSP or payload, +9 state).  So 0x0330/0x0334/
;   0x0338 are three PRIORITY LEVELS, scanned in that order.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_Dispatch -- save the running task, drain the ticks, pick the next task.
;
; Called from: THIRTEEN sites in this block, every one of them a JUMP and not a
;              call -- 0xF98273 (Kernel_Start), 0xF98338 (IRQ_Epilogue), 0xF983AC,
;              0xF983D6, 0xF98422, 0xF9848C, 0xF984CF, 0xF9857E, 0xF98651,
;              0xF98736, 0xF9887E, 0xF98904, 0xF9895E.  Counted by scanning every
;              `jr T`/`jrl T` displacement in this whole kernel block, not by
;              reading the listing: `python3 notes/prom_c_kernel_map.py --selftest`.
;              Nothing calls it (prom_c_xrefs.py 0xF9827A: zero literals, zero
;              calr) -- entering the scheduler is always a one-way jump.
; Inputs:  cr 0x3C, (0x0091), (0x0090), the two ready-queue heads at 0x0124.
; Outputs: enters Kernel_ResumeTask with XSP set to the chosen task's saved stack.
;          Never returns to its caller.
; Evidence: the four steps are visible in order -- (1) if cr 0x3C is non-zero this
;          is a nested entry, so fall straight through to Kernel_ResumeTask; (2)
;          if (0x0091) is non-zero, store XSP into that task's control block +4
;          and move to the kernel stack 0x0000FA00; (3) while (0x0090) is
;          non-zero, decrement it and call Kernel_ServiceSoftTimers; (4) walk
;          B = 2 heads from 0x0124 with `inc 4,IX` and take the first whose +0
;          differs from the head's own address.  `ld XSP,(XHL+0x04)` at the end
;          is what makes +4 the SAVED STACK POINTER field.
;          prom_a's Kernel_Dispatch (0xF85715) is the same 31 instructions with
;          17 operand differences and 0 structural ones; it scans THREE heads
;          from 0x0330 where this scans two from 0x0124.
; Unknown:  nothing in the routine; what raises (0x0090) other than INTT3 is not
;          established -- INTT3_KernelTick is its only writer in this image.
; --------------------------------------------------------------------------

Kernel_Dispatch:
	m_ldc_reg_cr RW+r0, 0x3c                     ; F85715/F9827A  d8 2f 3c   ldc WA,unknown   outermost only: a non-zero depth means resume, not dispatch
	or WA,WA                                     ; F85718/F9827D  d8 e0   or WA,WA
	jr nz, Kernel_ResumeTask                     ; F8571A/F9827F  6e 47   jr NZ,0xf982c8
	xor WA,WA                                    ; F8571C/F98281  d8 d0   xor WA,WA
	m_cp_mr MW8, KERNEL_CURRENT_TASK, r0         ; F8571E/F98283  a=d0 bf f8 c=d0 91 f8   c: cp (0x91),WA   (0xBF) = the task whose stack we are on, 0 = none
	jr z, Kernel_Dispatch__drain_ticks           ; F85721/F98286  66 12   jr Z,0xf9829a
	m_ld_rm MW8, KERNEL_CURRENT_TASK, r5         ; F85723/F98288  a=d0 bf 25 c=d0 91 25   c: ld IY,(0x91)
	extz XIY                                     ; F85726/F9828B  ed 12   extz XIY
	ld (XIY+0x04),XSP                            ; F85728/F9828D  bd 04 67   ld (XIY+0x04),XSP   save its XSP into the TCB
	ld XSP,KERNEL_STACK_TOP                      ; F8572B/F98290  a=47 80 eb 60 00 c=47 00 fa 00 00   c: ld XSP,0x0000fa00   and run the kernel on the boot stack
	xor WA,WA                                    ; F85730/F98295  d8 d0   xor WA,WA
	st_dd8w wa, KERNEL_CURRENT_TASK              ; F85732/F98297  a=f0 bf 50 c=f0 91 50   c: ld (0x91),WA
Kernel_Dispatch__drain_ticks:
	ld_sd8b a, KERNEL_PENDING_TICKS              ; F85735/F9829A  a=c0 be 21 c=c0 90 21   c: ld A,(0x90)   (0xBE) = pending timer ticks
	or A,A                                       ; F85738/F9829D  c9 e1   or A,A
	jr z, Kernel_Dispatch__pick_task             ; F8573A/F9829F  66 0a   jr Z,0xf982ab
	dec 1,A                                      ; F8573C/F982A1  c9 69   dec 1,A
	st_dd8b a, KERNEL_PENDING_TICKS              ; F8573E/F982A3  a=f0 be 41 c=f0 90 41   c: ld (0x90),A
	calr Kernel_ServiceSoftTimers                ; F85741/F982A6  1e 28 00   calr 0xf982d1
	jr Kernel_Dispatch__drain_ticks              ; F85744/F982A9  68 ef   jr T,0xf9829a
Kernel_Dispatch__pick_task:
	ld b, KERNEL_READY_LEVELS:opc                   ; F85746/F982AB  a=22 03 c=22 02   c: ld B,0x02
	ldw ix, KERNEL_READY_HEADS                   ; F85748/F982AD  a=34 30 03 c=34 24 01   c: ld IX,0x0124   the THREE ready-queue heads, 4 bytes each
	extz XIX                                     ; F8574B/F982B0  ec 12   extz XIX
Kernel_Dispatch__scan:
	m_ld_rm MWD+r4, 0x00, r3                     ; F8574D/F982B2  9c 00 23   ld HL,(XIX+0x00)   HL = head->next; a head that points at itself is an EMPTY queue
	cp HL,IX                                     ; F85750/F982B5  dc f3   cp HL,IX
	jr nz, Kernel_Dispatch__switch_to            ; F85752/F982B7  6e 07   jr NZ,0xf982c0
	inc 4,IX                                     ; F85754/F982B9  dc 64   inc 4,IX
	djnz8 b, Kernel_Dispatch__scan               ; F85756/F982BB  ca 1c f4   djnz B,0xf982b2
	jr Kernel_Idle                               ; F85759/F982BE  68 b6   jr T,0xf98276
Kernel_Dispatch__switch_to:
	st_dd8w hl, KERNEL_CURRENT_TASK              ; F8575B/F982C0  a=f0 bf 53 c=f0 91 53   c: ld (0x91),HL
	extz XHL                                     ; F8575E/F982C3  eb 12   extz XHL
	ld XSP,(XHL+0x04)                            ; F85760/F982C5  ab 04 27   ld XSP,(XHL+0x04)   node+4 = that task's saved XSP

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_ResumeTask -- the seven-register restore that IS the task switch.
;
; Called from: fallen into from Kernel_Dispatch__switch_to, and entered by `jr`
;              or `jrl` from EIGHT further sites -- 0xF98365 and 0xF983F9
;              (conditional, the two refusal paths), 0xF98543, 0xF98616,
;              0xF986E8, 0xF986F0, 0xF98848 and 0xF98964.  Those are every
;              "nothing to do, go straight back" arm in the block; the same
;              displacement scan that counts Kernel_Dispatch's entries counts
;              these.
; Inputs:  XSP pointing at a frame of {XIZ, XIY, XIX, XDE, XBC, XWA, XHL, SR}.
; Outputs: those eight restored, then RET -- which pops the PC the interrupt or
;          the call pushed.
; Evidence: ★ ALL NINE BYTES ARE IDENTICAL to prom_a's Kernel_ResumeTask at
;          0xF85763 (9 slots aligned, 9 identical, 0 differences of any kind).
;          It is the exact inverse of IRQ_Epilogue__enter_kernel's seven pushes,
;          which is what makes "resume a task" and "return from an interrupt" the
;          same frame -- and Kernel_StartTask builds precisely that frame, by
;          hand, for a task that has never run.
; --------------------------------------------------------------------------

Kernel_ResumeTask:
	pop XIZ                                      ; F85763/F982C8  5e   pop XIZ   restore the task's registers and return into it
	pop XIY                                      ; F85764/F982C9  5d   pop XIY
	pop XIX                                      ; F85765/F982CA  5c   pop XIX
	pop XDE                                      ; F85766/F982CB  5a   pop XDE
	pop XBC                                      ; F85767/F982CC  59   pop XBC
	pop XWA                                      ; F85768/F982CD  58   pop XWA
	pop XHL                                      ; F85769/F982CE  5b   pop XHL
	pop SR                                       ; F8576A/F982CF  03   pop SR
	ret                                          ; F8576B/F982D0  0e   ret

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ---------------------------------------------------------------------
; Kernel_ServiceSoftTimers -- one tick of the two software timers
;
; Called from: Kernel_Dispatch__drain_ticks, once per pending tick in (0xBE)
; Inputs:  the two slots at 0x03C8
; Outputs: each live slot's countdown decremented; on reaching zero the slot is
;          reloaded from +2 and its callback at +4 is entered.
; Evidence: the slot array is literal -- `ldw ix,0x03c8` at 0xF85776, `ldb
;          b,0x02` at 0xF8577B and `add IX,0x0008` at 0xF85794: TWO slots,
;          EIGHT bytes apart. The field roles are read off the loop: +4 is
;          tested against 0xFFFFFFFF for "empty" (0xF8577D), +0 is loaded,
;          decremented and stored back (0xF85788-0xF8578D), and on reaching
;          zero +2 is copied into +0 (0xF857A6) before the callback is
;          entered. The `cr 0x3C` bracket at either end is the same register
;          Kernel_Dispatch tests and IRQ_Epilogue compares against 1.
;          ⚠ "software timers" is that SHAPE (countdown / reload / callback),
;          not a name taken from the firmware.
; Notes:   the callback is entered by pushing the loop's own continuation
;          (0xF85794) and jumping -- so a callback returns straight back into the
;          scan, and the kernel never has to know how long it took.
;          It brackets the whole thing with depth++/depth-- on cr 0x3C, which is
;          what stops a timer callback from re-entering the dispatcher.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_ServiceSoftTimers -- one tick of the two software timers.
;
; Called from: Kernel_Dispatch__drain_ticks, `calr 0xF982D1` at 0xF982A6 -- the
;              only site (prom_c_xrefs.py 0xF982D1: 0 literals, 1 calr).
; Inputs:  the two 8-byte slots at 0x0174.
; Outputs: each live slot's +0 decremented; on reaching zero, +0 is reloaded from
;          +2 and the callback at +4 is entered.
; Evidence: the array is literal -- `ldw ix,0x174`, `ldb b,2`, `add ix,8`: TWO
;          slots, EIGHT bytes apart.  The field roles are read off the loop: +4 is
;          compared with 0xFFFFFFFF for "empty", +0 is loaded/decremented/stored,
;          and the fire path copies +2 into +0 before entering +4.  The callback
;          is entered by PUSHING the loop's own continuation (0xF982F9) and
;          jumping, so a callback returns straight back into the scan.
;          The whole scan is bracketed by cr 0x3C ++ / -- around an `ei 0`, which
;          is what stops a callback from re-entering the dispatcher.
;          prom_a's (0xF8576C) is the same 28 instructions, 5 operand differences,
;          0 structural ones.
; Unknown:  ⚠ "software timer" is that SHAPE (countdown / reload / callback), not
;          a name taken from the firmware.
; --------------------------------------------------------------------------

Kernel_ServiceSoftTimers:
	m_ldc_reg_cr RW+r0, 0x3c                     ; F8576C/F982D1  d8 2f 3c   ldc WA,unknown   enter a critical section: depth++
	inc 1,WA                                     ; F8576F/F982D4  d8 61   inc 1,WA
	m_ldc_cr_reg RW+r0, 0x3c                     ; F85771/F982D6  d8 2e 3c   ldc unknown,WA
	ei 0x00                                      ; F85774/F982D9  06 00   ei 0x00
	ldw ix, KERNEL_TIMERS                        ; F85776/F982DB  a=34 c8 03 c=34 74 01   c: ld IX,0x0174   the software timers: 2 x 8 bytes at 0x03C8
	extz XIX                                     ; F85779/F982DE  ec 12   extz XIX
	ld b, 0x02:opc                                  ; F8577B/F982E0  22 02   ld B,0x02
Kernel_ServiceSoftTimers__next:
	ld XWA,(XIX+0x04)                            ; F8577D/F982E2  ac 04 20   ld XWA,(XIX+0x04)
	cp XWA,0xffffffff                            ; F85780/F982E5  e8 cf ff ff ff ff   cp XWA,0xffffffff   +4 = the callback, 0xFFFFFFFF = the slot is empty
	jr z, Kernel_ServiceSoftTimers__step         ; F85786/F982EB  66 0c   jr Z,0xf982f9
	m_ld_rm MWD+r4, 0x00, r0                     ; F85788/F982ED  9c 00 20   ld WA,(XIX+0x00)
	dec 1,WA                                     ; F8578B/F982F0  d8 69   dec 1,WA   +0 = the countdown
	m_st_mr16 MDD+r4, 0x00, r0                   ; F8578D/F982F2  bc 00 50   ld (XIX+0x00),WA
	or WA,WA                                     ; F85790/F982F5  d8 e0   or WA,WA
	jr z, Kernel_ServiceSoftTimers__fire         ; F85792/F982F7  66 12   jr Z,0xf9830b
Kernel_ServiceSoftTimers__step:
	add IX,0x0008                                ; F85794/F982F9  dc c8 08 00   add IX,0x0008
	djnz8 b, Kernel_ServiceSoftTimers__next      ; F85798/F982FD  ca 1c e2   djnz B,0xf982e2
	ei 0x06                                      ; F8579B/F98300  06 06   ei 0x06
	m_ldc_reg_cr RW+r0, 0x3c                     ; F8579D/F98302  d8 2f 3c   ldc WA,unknown
	dec 1,WA                                     ; F857A0/F98305  d8 69   dec 1,WA
	m_ldc_cr_reg RW+r0, 0x3c                     ; F857A2/F98307  d8 2e 3c   ldc unknown,WA
	ret                                          ; F857A5/F9830A  0e   ret
Kernel_ServiceSoftTimers__fire:
	ld WA,(XIX+0x02)                             ; F857A6/F9830B  9c 02 20   ld WA,(XIX+0x02)   +2 = the reload value
	m_st_mr16 MDD+r4, 0x00, r0                   ; F857A9/F9830E  bc 00 50   ld (XIX+0x00),WA
	ld XWA,Kernel_ServiceSoftTimers__step        ; F857AC/F98311  a=40 94 57 f8 00 c=40 f9 82 f9 00   c: ld XWA,0x00f982f9   push the loop's continuation, then jump to the callback
	push XWA                                     ; F857B1/F98316  38   push XWA
	ld XWA,(XIX+0x04)                            ; F857B2/F98317  ac 04 20   ld XWA,(XIX+0x04)
	jp (xwa)                                     ; F857B5/F9831A  b0 d8   jp T,XWA

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ---------------------------------------------------------------------
; IRQ_Epilogue -- where every interrupt handler in this firmware exits
;
; Called from: reached as `jp 0xF42D68`, a prom_b thunk holding `jp 0xF857B7`.
;          INTT1_Tick (0xF82E9E) and INTTR4_SequencerTick (0xF83030) both end
;          that way, and those are the ONLY two sites in either ROM that spell
;          `jp 0xF42D68`.  The INTT3 handler at 0xF85600 also ends here but by
;          a DIFFERENT route -- `jrl T,0xF857B7` at 0xF85603, straight to this
;          label without the thunk.  ⚠ CORRECTED 2026-08-25: this line said all
;          three "end that way", which reads as three thunk sites; there are
;          two.  All of it is re-derived by notes/prom_a_byte_checks.py.
; Inputs:  cr 0x3C, the critical-section depth
; Outputs: either a plain RETI (nested case) or a full register push followed by
;          a jump into Kernel_Dispatch, which will not come back.
; Evidence: prom_b 0xF42D68 really is `jp 0xF857B7` -- its four bytes are 1B B7
;          57 F8 -- so the handlers that end `jp 0xF42D68` do land on this
;          label, and notes/prom_a_byte_checks.py re-derives that plus the
;          fact that exactly two sites in either ROM spell that jump.
;          "Epilogue" is the body: control register 0x3C is read and compared
;          against 1 (0xF857B8-0xF857BB) and the two arms are a bare RETI
;          (0xF857C0) or seven pushes followed by `jrl Kernel_Dispatch`
;          (0xF857CC-0xF857D3).
;          ⚠ it is not the ONLY exit in this file -- the MIDI handlers execute
;          RETI themselves; it is the exit of the handlers listed above.
; Notes:   this is the whole reason interrupt handlers here `jp` to a thunk
;          instead of executing RETI themselves: the decision about whether to
;          reschedule is taken in one place.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; IRQ_Epilogue -- the shared interrupt exit: reschedule only if outermost.
;
; Called from: INTT3_KernelTick's `jrl 0xF9831C` at 0xF98168 -- the only site.
; Inputs:  cr 0x3C.
; Outputs: either a bare RETI, or seven register pushes followed by `jrl
;          Kernel_Dispatch`, which does not come back.
; Evidence: the two arms are the whole body -- cr 0x3C is read and compared with
;          1; equal means this interrupt was the outermost one, so the register is
;          zeroed and the kernel is entered on the interrupted task's stack;
;          otherwise WA is popped and RETI executed.  The seven pushes are exactly
;          the seven pops of Kernel_ResumeTask, in the opposite order.
;          prom_a's IRQ_Epilogue (0xF857B7) is the same 20 instructions with 2
;          operand differences (the two branch targets) and 0 structural ones.
; Unknown:  ⚠ only ONE handler in prom_c ends here, where prom_a publishes the
;          epilogue through a prom_b thunk and has three.  Whether the other
;          prom_c handlers (which execute RETI themselves) are meant to be unable
;          to trigger a switch is not established.
; --------------------------------------------------------------------------

IRQ_Epilogue:
	pushw wa                                     ; F857B7/F9831C  28   push WA   THE SHARED INTERRUPT EPILOGUE
	m_ldc_reg_cr RW+r0, 0x3c                     ; F857B8/F9831D  d8 2f 3c   ldc WA,unknown
	cp wa, 0x01:i3                                 ; F857BB/F98320  d8 d9   cp WA,1   depth == 1 means this interrupt was the outermost one
	jr z, IRQ_Epilogue__enter_kernel             ; F857BD/F98322  66 02   jr Z,0xf98326
	popw wa                                      ; F857BF/F98324  48   pop WA
	reti                                         ; F857C0/F98325  07   reti   nested: plain RETI, do not run the kernel
IRQ_Epilogue__enter_kernel:
	xor WA,WA                                    ; F857C1/F98326  d8 d0   xor WA,WA
	m_ldc_cr_reg RW+r0, 0x3c                     ; F857C3/F98328  d8 2e 3c   ldc unknown,WA
	popw wa                                      ; F857C6/F9832B  48   pop WA
	ei 0x00                                      ; F857C7/F9832C  06 00   ei 0x00
	nop                                          ; F857C9/F9832E  00   nop
	ei 0x06                                      ; F857CA/F9832F  06 06   ei 0x06
	push XHL                                     ; F857CC/F98331  3b   push XHL
	push XWA                                     ; F857CD/F98332  38   push XWA
	push XBC                                     ; F857CE/F98333  39   push XBC
	push XDE                                     ; F857CF/F98334  3a   push XDE
	push XIX                                     ; F857D0/F98335  3c   push XIX
	push XIY                                     ; F857D1/F98336  3d   push XIY
	push XIZ                                     ; F857D2/F98337  3e   push XIZ
	jrl Kernel_Dispatch                          ; F857D3/F98338  78 3f ff   jrl T,0xf9827a   into the kernel, on the interrupted task's stack

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ==============================================================================
; 0xF857D6-0xF85876 -- the kernel's task LIFECYCLE: start one, and exit one
; ==============================================================================
;
; ★ THE KERNEL IS PUBLISHED TWICE, WITH TWO CALLING CONVENTIONS.  prom_b holds
;   a block of 34 `jp` thunks at 0xF42D60-0xF42DE7 -- bounded by 0x0E padding at
;   both ends, so the block's extent is a fact and not a choice.  Three slots at
;   the front are not part of either argument run (0xF85606 Kernel_InitRam,
;   0xF85600 INTT3_KernelTick, 0xF857B7 IRQ_Epilogue) and two at the back
;   publish the DSP register writers (0xF85F59, 0xF85F7C).  Between them are two
;   runs of the SAME API:
;
;     0xF42D6C-0xF42DA8   16 slots  ->  0xF857D9 0xF8584A 0xF85877 0xF858C0
;                                       0xF85904 0xF8592D 0xF8596D 0xF859AE
;                                       0xF85A22 0xF85A96 0xF85B1F 0xF85BD4
;                                       0xF85C8C 0xF85DA8 0xF85E02 0xF85E5E
;     0xF42DAC-0xF42DD4   11 slots  ->  0xF857D6 0xF8584A 0xF85874 0xF85904
;                                       0xF8592A 0xF859AB 0xF85A93 0xF85B0D
;                                       0xF85C89 0xF85DA2 0xF85E5B
;
;   Pair each slot of the second run with the nearest target of the first at or
;   above it and the whole run resolves, with nothing left over:
;
;     2 of the 11   the SAME address in both runs (0xF8584A, 0xF85904)
;                   -- what a routine that takes NO argument looks like;
;     9 of the 11   begin with `ld A,(XSP+0x04)`, the three bytes 8F 04 21 --
;                   7 of those are exactly that one instruction and fall
;                   straight through into the register entry three bytes on;
;                   0xF85DA2 adds `ld W,(XSP+0x06)` for a SECOND argument
;                   (6 bytes to 0xF85DA8), and 0xF85B0D fetches its second
;                   argument as `ld XIZ,(XSP+0x24)` only AFTER the register
;                   pushes -- 0x24 = 0x06 + 2 + 7*4, the same stack slot seen
;                   through 30 bytes of pushes -- then `jr` into the body.
;
;   So the second run is the STACK-ARGUMENT face of the same kernel: a
;   C-callable entry that lifts its arguments off the frame and joins the
;   register-argument entry.  ALL NINE differing slots start with the same
;   three bytes; there is no residue and no slot that does not fit.
;   ⚠ TWO MORE STACK FACES SIT OUTSIDE THAT RUN, at 0xF42DD8 -> 0xF85AEF
;   (Kernel_SemaTryWait) and 0xF42DDC -> 0xF85D1C.  Both open with the same
;   8F 04 21, and neither has a register-argument twin in the first run -- so
;   "two runs" describes the alignment, not the whole block, and those two are
;   published only with a stack argument.
;   The whole table, the nine 8F 04 21 prologues, the two no-argument
;   coincidences and both second-argument shapes are re-derived from the ROM by
;   notes/prom_a_byte_checks.py.
;
; ★ AND THE KERNEL IS 1-BASED THROUGHOUT.  The task selector A indexes three
;   arrays, and all three are addressed with a one-element negative bias:
;
;     EntryPoint_Records   0xF85E7E + A*12   = 0xF85E8A + (A-1)*12   (this file)
;     task control blocks  0x02F4   + A*12   = 0x0300   + (A-1)*12
;     ready-queue heads    0x032C   + n*4    = 0x0330   + (n-1)*4
;
;   The first is computed at 0xF857E9 below, the second at 0xF857F3 below, the
;   third at 0xF8582D below and in both queue primitives at 0xF85877/0xF858C0.
;   So A = 1..4 and level n = 1..3, and there is no 8-byte hole between the TCBs
;   and the queue heads: the four TCBs occupy 0x0300-0x032F and 0x0330 is the
;   first head.  The kernel's own boot code agrees -- 0xF8562A is
;   `ld IX,0x0300 / ld B,0x04 / ld (XIX+0x09),0 / add IX,0x000C`, four blocks of
;   twelve starting at 0x0300.
;   ⚠ This refines, and does not contradict, the check "the 4x12+8 arithmetic
;   lines up in RAM and in ROM": 0x02F4 + 4*12 + 8 = 0x032C is true, but the
;   +8 is not a gap in the layout, it is 12 - 4 seen through the bias.
;
; ---------------------------------------------------------------------
; Kernel_StartTask_StackArg -- the stack-argument face of Kernel_StartTask
;
; Called from: prom_b thunk 0xF42DAC (`jp 0xF857D6`).  No prom_a site reaches
;          it: notes/prom_a_byte_checks.py resolves every PC-relative branch in
;          prom_a and every 3-byte LE address in prom_a + prom_b and finds this
;          one reference and no other.
; Inputs:  (XSP+0x04) = the task number, 1..4
; Outputs: as Kernel_StartTask, which it falls into
; Evidence: it is one instruction, `ld A,(XSP+0x04)`, immediately above
;          Kernel_StartTask's first instruction -- the same three bytes
;          (8F 04 21) that open every one of the nine second-run entries that
;          differ from their first-run twin.  See the region banner.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_StartTask_StackArg / Kernel_StartTask -- make task A runnable for the
; first time, by BUILDING the frame Kernel_ResumeTask will pop.
;
; Called from: the STACK face (this label) has one site, `call` at 0xFA3365,
;              which pushes 2 -- so task 2 is started there.  The REGISTER face
;              three bytes on has two, both in Kernel_Start; they are cited in
;              its own header below.
; Inputs:  A = task number, 1-based.
; Outputs: nothing if the task is already live; otherwise a control block filled
;          in and appended to a ready queue, then `jrl Kernel_Dispatch`.
; Evidence: the two index computations are the identification, and both carry the
;          kernel's one-element bias:
;            `ld L,12 / mul HL,A / add XHL,0xFFF980DE`  -> 0xF980DE + A*12, and
;              0xF980DE = EntryPoint_Records - 12, so A = 1 is record 0;
;            `ld C,12 / mul BC,A / add BC,0x00F4`       -> 0x00F4 + A*12 = the
;              task control block, 0x0100 + (A-1)*12.
;          It refuses if TCB+9 is already non-zero, bailing out with `jrl
;          Kernel_ResumeTask`, which undoes its own seven pushes.
;          The frame is exact arithmetic against Kernel_ResumeTask:
;            XIY = record+4 (the initial stack) - 0x22
;            (XIY+0x1C) = record+8   -- the SR word, 0x8800 in all three records
;            (XIY+0x1E) = record+0   -- the entry PC
;          and 0x22 = 7*4 register slots + 2 (SR) + 4 (PC), which is precisely
;          what that epilogue pops.  Then TCB+4 = XIY, TCB+8 = record+10 (the
;          level), TCB+9 = 4, and the block is appended to the TAIL of
;          0x0120 + level*4 with the four-store insert idiom.
;          prom_a's Kernel_StartTask (0xF857D9) is the same 45 instructions with
;          5 operand differences -- its own record table, its own TCB base, its
;          own queue base and its two branch targets -- and 0 structural ones.
; Unknown:  what the halfword at record+8 (0x8800) means beyond "the SR a task
;          starts with"; no databook is available for the SR layout.
; --------------------------------------------------------------------------

Kernel_StartTask_StackArg:
	ld A,(XSP+0x04)                              ; F857D6/F9833B  8f 04 21   ld A,(XSP+0x04)   the task number, off the stack

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ---------------------------------------------------------------------
; Kernel_StartTask -- make statically-declared task A runnable, then dispatch
;
; Called from: Kernel_Start, twice, with A = 1 and A = 3 (0xF856FA, 0xF85700);
;          prom_b thunk 0xF42D6C; and by falling in from the entry above.
; Inputs:  A = the task number, 1..4.  EntryPoint_Records[A-1] supplies the
;          entry address (+0), the top of that task's stack (+4), the initial
;          SR (+8, always 0x8800) and the priority level (+10, 1..3).
; Outputs: NEVER RETURNS on success -- it jumps into Kernel_Dispatch.  On the
;          way it writes the task's initial stack frame, fills in the task
;          control block at 0x0300 + (A-1)*12 and appends that block to the tail
;          of ready queue 0x0330 + (level-1)*4.  If the task is ALREADY live it
;          returns to its caller instead, through Kernel_ResumeTask's pops.
; Evidence: ★ the initial STACK FRAME is the identification, and it is exact
;          arithmetic against a routine already converted in this file.  The
;          frame is built at record.stack - 0x22 (`sub XIY,0x00000022`,
;          0xF85806); SR goes to frame+0x1C (0xF8580F) and the entry address to
;          frame+0x1E (0xF85815).  Kernel_ResumeTask (0xF85763) resumes a task
;          with SEVEN 32-bit pops, then `pop SR`, then `ret`: 7 x 4 = 0x1C, the
;          SR sits at 0x1C and is 2 bytes, and the return address at 0x1E is 4
;          bytes -- 0x22 in total.  The frame this routine writes is precisely
;          the frame that epilogue consumes, with the seven register slots left
;          uninitialised because a task has no previous register state.
;          The record fields are the ones EntryPoint_Records' own header gives,
;          and +8 = 0x8800 in all four records is checked by
;          notes/prom_a_byte_checks.py.
;          The queue insert at 0xF85839-0xF85846 is the tree's established
;          insert-at-tail idiom verbatim -- `n->next = head; n->prev =
;          head->prev; head->prev->next = n; head->prev = n` -- the same four
;          stores as 0xF858AF-0xF858BC (see the block header at 0xF85877).
;          The state byte written at +9 is 4; MsgQueue_ReceiveBlocking writes 3
;          there for "blocked", and the kernel's boot code writes 0.
; Unknown:  what state values other than 0, 3 and 4 mean, and whether "4" is
;          READY or RUNNABLE in the firmware's own vocabulary.  Nothing here
;          names them; the numbers are what is established.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_StartTask -- the register-argument face; A = the task number.
; Called from: Kernel_Start, `call` at 0xF9825F with A = 1 and at 0xF98265 with
;              A = 3.  Those are the only two sites (prom_c_xrefs.py 0xF9833E).
; The body, its evidence and its unknowns are in the block above.
; --------------------------------------------------------------------------

Kernel_StartTask:
	push SR                                      ; F857D9/F9833E  02   push SR
	ei 0x06                                      ; F857DA/F9833F  06 06   ei 0x06
	push XHL                                     ; F857DC/F98341  3b   push XHL
	push XWA                                     ; F857DD/F98342  38   push XWA
	push XBC                                     ; F857DE/F98343  39   push XBC
	push XDE                                     ; F857DF/F98344  3a   push XDE
	push XIX                                     ; F857E0/F98345  3c   push XIX
	push XIY                                     ; F857E1/F98346  3d   push XIY
	push XIZ                                     ; F857E2/F98347  3e   push XIZ   seven pushes: the same set Kernel_ResumeTask pops
	ld l, 0x0c:opc                                  ; F857E3/F98348  27 0c   ld L,0x0c
	mul hl, a                                  ; F857E5/F9834A  c9 47   mul HL,A   HL = 12 * A
	extz XHL                                     ; F857E7/F9834C  eb 12   extz XHL
	add XHL,KERNEL_TCB_TEMPLATE                  ; F857E9/F9834E  a=eb c8 7e 5e f8 ff c=eb c8 de 80 f9 ff   c: add XHL,0xfff980de   XHL = EntryPoint_Records + (A-1)*12; only the low 24 bits reach the bus
	ld c, 0x0c:opc                                  ; F857EF/F98354  23 0c   ld C,0x0c
	mul bc, a                                  ; F857F1/F98356  c9 43   mul BC,A   BC = 12 * A
	add BC,KERNEL_TCB_BASE-12                    ; F857F3/F98358  a=d9 c8 f4 02 c=d9 c8 f4 00   c: add BC,0x00f4   XBC = 0x0300 + (A-1)*12, the task control block
	extz XBC                                     ; F857F7/F9835C  e9 12   extz XBC
	ld XIX,XBC                                   ; F857F9/F9835E  e9 8c   ld XIX,XBC
	ld A,(XIX+0x09)                              ; F857FB/F98360  8c 09 21   ld A,(XIX+0x09)   +9 = the state byte
	cp a, 0x00:i3                                  ; F857FE/F98363  c9 d8   cp A,0
	jrl nz, Kernel_ResumeTask                    ; F85800/F98365  7e 60 ff   jrl NZ,0xf982c8   already live: undo the pushes and return
	ld XIY,(XHL+0x04)                            ; F85803/F98368  ab 04 25   ld XIY,(XHL+0x04)   record+4 = the top of this task's stack
	sub XIY,0x00000022                           ; F85806/F9836B  ed ca 22 00 00 00   sub XIY,0x00000022   room for 7 registers (0x1C) + SR (2) + PC (4)
	ld WA,(XHL+0x08)                             ; F8580C/F98371  9b 08 20   ld WA,(XHL+0x08)   record+8 = the initial SR, 0x8800 in every record
	ld (XIY+0x1c),WA                             ; F8580F/F98374  bd 1c 50   ld (XIY+0x1c),WA   ...lands where `pop SR` will read it
	m_ld_rm MLD+r3, 0x00, r0                     ; F85812/F98377  ab 00 20   ld XWA,(XHL+0x00)   ld XWA,(XHL+0x00) -- record+0 = the entry address
	ld (XIY+0x1e),XWA                            ; F85815/F9837A  bd 1e 60   ld (XIY+0x1e),XWA   ...lands where the final `ret` will read it
	ld (XIX+0x04),XIY                            ; F85818/F9837D  bc 04 65   ld (XIX+0x04),XIY   TCB+4 = the saved XSP, which is what Kernel_Dispatch loads
	ld A,(XHL+0x0a)                              ; F8581B/F98380  8b 0a 21   ld A,(XHL+0x0a)   record+10 = the priority level, 1..3
	ld (XIX+0x08),A                              ; F8581E/F98383  bc 08 41   ld (XIX+0x08),A   TCB+8 = that level
	ld (XIX+0x09),0x04                           ; F85821/F98386  bc 09 00 04   ld (XIX+0x09),0x04   TCB+9 = state 4
	ld A,(XHL+0x0a)                              ; F85825/F9838A  8b 0a 21   ld A,(XHL+0x0a)
	sll a, 0x02                                  ; F85828/F9838D  c9 ee 02   sll 0x02,A
	extz WA                                      ; F8582B/F98390  d8 12   extz WA
	add WA,KERNEL_READY_HEADS-4                  ; F8582D/F98392  a=d8 c8 2c 03 c=d8 c8 20 01   c: add WA,0x0120   the ready-queue head, 0x0330 + (level-1)*4
	ld IY,WA                                     ; F85831/F98396  d8 8d   ld IY,WA
	extz XIX                                     ; F85833/F98398  ec 12   extz XIX
	extz XIY                                     ; F85835/F9839A  ed 12   extz XIY
	extz XWA                                     ; F85837/F9839C  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F85839/F9839E  bc 00 55   ld (XIX+0x00),IY   ld (XIX+0x00),IY -- n->next = head
	ld WA,(XIY+0x02)                             ; F8583C/F983A1  9d 02 20   ld WA,(XIY+0x02)   head->prev
	ld (XIX+0x02),WA                             ; F8583F/F983A4  bc 02 50   ld (XIX+0x02),WA   n->prev = head->prev
	ld (XWA),IX                                  ; F85842/F983A7  b0 54   ld (XWA),IX   head->prev->next = n
	ld (XIY+0x02),IX                             ; F85844/F983A9  bd 02 54   ld (XIY+0x02),IX   head->prev = n
	jrl Kernel_Dispatch                          ; F85847/F983AC  78 cb fe   jrl T,0xf9827a   and straight into the scheduler; this never returns

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ---------------------------------------------------------------------
; Kernel_ExitTask -- the running task removes itself and gives up the CPU
;
; Called from: prom_b thunks 0xF42D70 AND 0xF42DB0 -- the same address in both
;          runs, which is what a no-argument entry looks like.  No prom_a site
;          reaches it (same search as above).
; Inputs:  (0xBF) = the running task's control block, as Kernel_Dispatch left it
; Outputs: never returns.  The task's state byte goes to 0, (0xBF) is cleared,
;          the control block is unlinked from whatever queue it was on, and
;          control passes to Kernel_Dispatch on the BOOT stack.
; Evidence: three facts, each an instruction: it switches to 0x0060EB80
;          (0xF8584C), which is the same boot stack RESET's continuation and
;          Kernel_Dispatch use and therefore NOT any task's stack -- so the
;          stack it was running on is abandoned; it writes 0 to TCB+9
;          (0xF85856), the value the kernel's boot code writes into all four
;          blocks and the value Kernel_StartTask above refuses to start over;
;          and 0xF85865-0xF85870 is the tree's established UNLINK idiom
;          verbatim -- `prev->next = next; next->prev = prev`, the same two
;          stores as 0xF8589D-0xF858A8.  Nothing is saved on the way out, which
;          is what distinguishes an exit from a yield.
; Unknown:  who calls it.  Both references are prom_b thunks; the callers are in
;          prom_b and are another lane's territory.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_ExitTask -- the running task removes itself and never comes back.
;
; Called from: `call 0xF983AF` at 0xFA5530, the instruction after task 2's loop
;              closes -- i.e. the compiler's unreachable epilogue for that task.
;              One site (prom_c_xrefs.py 0xF983AF).
; Inputs:  (0x0091), the running task's control block.
; Outputs: XSP := 0x0000FA00 (the kernel stack), TCB+9 := 0, (0x0091) := 0, the
;          block unlinked, then `jrl Kernel_Dispatch`.
; Evidence: it switches stacks FIRST and clears (0x0091), so the dispatcher's own
;          prologue cannot save anything into the block -- that is exactly what
;          distinguishes an exit from Kernel_BlockSelf, which does neither.  The
;          unlink is the tree's `prev->next = next; next->prev = prev` pair.
;          prom_a's Kernel_ExitTask (0xF8584A) is the same 15 instructions with 4
;          operand differences and 0 structural ones.
; --------------------------------------------------------------------------

Kernel_ExitTask:
	ei 0x06                                      ; F8584A/F983AF  06 06   ei 0x06
	ld XSP,KERNEL_STACK_TOP                      ; F8584C/F983B1  a=47 80 eb 60 00 c=47 00 fa 00 00   c: ld XSP,0x0000fa00   the BOOT stack -- the task's own stack is abandoned
	m_ld_rm MW8, KERNEL_CURRENT_TASK, r4         ; F85851/F983B6  a=d0 bf 24 c=d0 91 24   c: ld IX,(0x91)   ld IX,(0xBF) -- the running task's control block
	extz XIX                                     ; F85854/F983B9  ec 12   extz XIX
	ld (XIX+0x09),0x00                           ; F85856/F983BB  bc 09 00 00   ld (XIX+0x09),0x00   state 0 = not live
	xor WA,WA                                    ; F8585A/F983BF  d8 d0   xor WA,WA
	st_dd8w wa, KERNEL_CURRENT_TASK              ; F8585C/F983C1  a=f0 bf 50 c=f0 91 50   c: ld (0x91),WA   (0xBF) = 0: no task is running
	extz XIX                                     ; F8585F/F983C4  ec 12   extz XIX
	extz XWA                                     ; F85861/F983C6  e8 12   extz XWA
	extz XHL                                     ; F85863/F983C8  eb 12   extz XHL
	m_ld_rm MWD+r4, 0x00, r0                     ; F85865/F983CA  9c 00 20   ld WA,(XIX+0x00)   ld WA,(XIX+0x00) -- next
	ld HL,(XIX+0x02)                             ; F85868/F983CD  9c 02 23   ld HL,(XIX+0x02)   prev
	m_st_mr16 MDD+r3, 0x00, r0                   ; F8586B/F983D0  bb 00 50   ld (XHL+0x00),WA   ld (XHL+0x00),WA -- prev->next = next
	ld (XWA+0x02),HL                             ; F8586E/F983D3  b8 02 53   ld (XWA+0x02),HL   next->prev = prev
	jrl Kernel_Dispatch                          ; F85871/F983D6  78 a1 fe   jrl T,0xf9827a

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ---------------------------------------------------------------------
; Kernel_YieldRotate_StackArg -- the stack-argument face of Kernel_YieldRotate
;
; Called from: prom_b thunk 0xF42DB4 (`jp 0xF85874`), and nothing else
; Inputs:  (XSP+0x04) = the queue level
; Outputs: as Kernel_YieldRotate (0xF85877), which it falls into
; Evidence: the same three bytes 8F 04 21 as the other stack-argument entries,
;          sitting immediately above the register-argument entry that the FIRST
;          thunk run names.  See the region banner for the whole pairing.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_YieldRotate_StackArg / Kernel_YieldRotate -- rotate ready queue A and
; reschedule; if the queue holds fewer than two tasks, do nothing.
;
; Called from: the STACK face (this label) has one site, `call` at 0xFA311C,
;              which pushes 2.  The REGISTER face three bytes on is called by
;              SoftTimer_RotateLevel2 -- i.e. FROM THE BOOT SOFTWARE TIMER, which
;              is what makes level 2 round-robin; cited in its own header below.
; Inputs:  A = ready-queue level, 1-based.
; Outputs: the queue's first element moved to its tail, then `jrl Kernel_Dispatch`;
;          or `jrl Kernel_ResumeTask` if there was nothing to rotate.
; Evidence: `sll 2,A / add WA,0x0120` forms 0x0120 + A*4, the ready-queue head.
;          The emptiness test is `cp IX,(XIY+0x02)` -- head->next against
;          head->PREV -- which is true for a queue of zero OR ONE element, i.e.
;          "nothing to rotate"; the body then unlinks the first node and
;          re-appends it at the tail with the same four-store idiom used
;          everywhere in this kernel.
;          prom_a's Kernel_YieldRotate (0xF85877) is the same 33 instructions with
;          3 operand differences and 0 structural ones.
; --------------------------------------------------------------------------

Kernel_YieldRotate_StackArg:
	ld A,(XSP+0x04)                              ; F85874/F983D9  8f 04 21   ld A,(XSP+0x04)   the queue level, off the stack

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ==============================================================================
; 0xF85877-0xF85903 -- the scheduler's two queue-rotate primitives
; ==============================================================================
;
; ★ WHAT 0x0330 REALLY IS.  Kernel_Dispatch__pick_task (0xF85746, converted
;   above) walks THREE list heads four bytes apart starting at 0x0330 -- `ldw
;   ix,0x0330`, `ld HL,(XIX+0)`, `cp HL,IX`, `inc 4,IX`, `djnz8 b` with B = 3 --
;   and a head whose `next` points at itself is skipped.  These two routines
;   compute their head as **0x032C + A*4**, so A = 1, 2, 3 lands on exactly
;   0x0330, 0x0334, 0x0338: the three heads the dispatcher scans, in the order it
;   scans them.  They are READY QUEUES, one per priority level, and 1 is the
;   level the dispatcher reaches first.
;
;   That also corrects a sentence in this file: Kernel_Dispatch's comment used to
;   call 0x0330 "the task control blocks: 3 x 8 bytes".  It is three FOUR-byte
;   list heads; the task control blocks are the NODES on them, and the
;   dispatcher's own next instruction proves it -- `ld XSP,(XHL+0x04)` reads the
;   saved stack out of the node HL, not out of 0x0330.
;
; THE LIST SHAPE, read off these two routines and used unchanged by every other
; queue in the kernel:
;   node+0  LE16  next        node+4  LE32  payload / saved XSP
;   node+2  LE16  prev        node+9  BYTE  state
; The heads are two-word sentinels of the same shape.  Unlink is
; `next->prev = prev; prev->next = next` (0xF8589D-0xF858A8) and insert-at-tail
; is `n->next = head; n->prev = head->prev; head->prev->next = n; head->prev = n`
; (0xF858AF-0xF858BC).  Both routines contain that pair verbatim.
;
; ⚠ The two differ ONLY in their save/restore and their exit, which is what makes
;   the naming safe: same address arithmetic, same test, same twelve list
;   instructions.

; ---------------------------------------------------------------------
; Kernel_YieldRotate -- move ready-queue A's head task to the back and reschedule
;
; Called from: sub_F85EC2 (0xF85EC4, converted below) with A = 3; and prom_b
;          thunk 0xF42D74 (notes/prom_a_xref.py 0xF85877), so it is a published
;          kernel entry, not a local helper.
; Inputs:  A = the queue number.  The list at 0x032C + A*4.
; Outputs: does not return normally.  On success the calling task's context is
;          left on its own stack in Kernel_ResumeTask's exact layout and control
;          goes to Kernel_Dispatch, which may pick someone else.  When the queue
;          holds at most one element it jumps to Kernel_ResumeTask instead, which
;          pops back exactly what was pushed -- so the caller simply returns.
; Evidence: 1. the seven `push` at 0xF8587A-0xF85880 are, in order, the seven
;             `pop` of Kernel_ResumeTask (0xF85763) read backwards, and the
;             `push SR` at 0xF85877 is its `pop SR`.  That is what makes both
;             exits legal from the same frame;
;          2. `ei 0x06` immediately after, i.e. the interrupt mask RAISED for the
;             list surgery -- the same critical-section idiom
;             Kernel_ServiceSoftTimers uses (`ei 0x00` ... `ei 0x06`);
;          3. the test is `cp IX,(XIY+0x02)`, head->next against head->prev:
;             equal means the queue holds zero or one element, and rotating it
;             would be a no-op.  Kernel_YieldRotate is the only place in this
;             pair that then RESCHEDULES.
; Unknown:  nothing here says which task is "current"; the rotation is by queue
;          position, so this is round-robin within a priority, not a yield to a
;          named task.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_YieldRotate -- the register-argument face; A = the ready-queue level.
; Called from: SoftTimer_RotateLevel2, `calr` at 0xF98114 with A = 2.  The only
;              site (prom_c_xrefs.py 0xF983DC: 0 literals, 1 calr).
; The body, its evidence and its unknowns are in the block above.
; --------------------------------------------------------------------------

Kernel_YieldRotate:
	push SR                                      ; F85877/F983DC  02   push SR
	ei 0x06                                      ; F85878/F983DD  06 06   ei 0x06   raise the mask: list surgery
	push XHL                                     ; F8587A/F983DF  3b   push XHL
	push XWA                                     ; F8587B/F983E0  38   push XWA
	push XBC                                     ; F8587C/F983E1  39   push XBC
	push XDE                                     ; F8587D/F983E2  3a   push XDE
	push XIX                                     ; F8587E/F983E3  3c   push XIX
	push XIY                                     ; F8587F/F983E4  3d   push XIY
	push XIZ                                     ; F85880/F983E5  3e   push XIZ   Kernel_ResumeTask's frame, exactly
	sll a, 0x02                                  ; F85881/F983E6  c9 ee 02   sll 0x02,A
	extz WA                                      ; F85884/F983E9  d8 12   extz WA
	add WA,KERNEL_READY_HEADS-4                  ; F85886/F983EB  a=d8 c8 2c 03 c=d8 c8 20 01   c: add WA,0x0120   head = 0x032C + A*4
	ld IY,WA                                     ; F8588A/F983EF  d8 8d   ld IY,WA
	extz XIY                                     ; F8588C/F983F1  ed 12   extz XIY
	m_ld_rm MWD+r5, 0x00, r4                     ; F8588E/F983F3  9d 00 24   ld IX,(XIY+0x00)   IX = head->next
	cp IX,(XIY+0x02)                             ; F85891/F983F6  9d 02 f4   cp IX,(XIY+0x02)   == head->prev? then 0 or 1 element
	jrl z, Kernel_ResumeTask                     ; F85894/F983F9  76 cc fe   jrl Z,0xf982c8   nothing to rotate: unwind and return
	extz XIX                                     ; F85897/F983FC  ec 12   extz XIX
	extz XWA                                     ; F85899/F983FE  e8 12   extz XWA
	extz XHL                                     ; F8589B/F98400  eb 12   extz XHL
	m_ld_rm MWD+r4, 0x00, r0                     ; F8589D/F98402  9c 00 20   ld WA,(XIX+0x00)   WA = n->next
	ld HL,(XIX+0x02)                             ; F858A0/F98405  9c 02 23   ld HL,(XIX+0x02)   HL = n->prev
	m_st_mr16 MDD+r3, 0x00, r0                   ; F858A3/F98408  bb 00 50   ld (XHL+0x00),WA   prev->next = next
	ld (XWA+0x02),HL                             ; F858A6/F9840B  b8 02 53   ld (XWA+0x02),HL   next->prev = prev
	extz XIX                                     ; F858A9/F9840E  ec 12   extz XIX
	extz XIY                                     ; F858AB/F98410  ed 12   extz XIY
	extz XWA                                     ; F858AD/F98412  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F858AF/F98414  bc 00 55   ld (XIX+0x00),IY   n->next = head
	ld WA,(XIY+0x02)                             ; F858B2/F98417  9d 02 20   ld WA,(XIY+0x02)
	ld (XIX+0x02),WA                             ; F858B5/F9841A  bc 02 50   ld (XIX+0x02),WA   n->prev = head->prev
	ld (XWA),IX                                  ; F858B8/F9841D  b0 54   ld (XWA),IX   head->prev->next = n
	ld (XIY+0x02),IX                             ; F858BA/F9841F  bd 02 54   ld (XIY+0x02),IX   head->prev = n   -- n is now last
	jrl Kernel_Dispatch                          ; F858BD/F98422  78 55 fe   jrl T,0xf9827a   and re-pick

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ---------------------------------------------------------------------
; Kernel_RotateQueue -- the same rotation, without yielding
;
; Called from: prom_b thunk 0xF42D78 (`jp 0xF858C0`) -- the slot immediately
;          after Kernel_YieldRotate's own thunk at 0xF42D74.  That run of the
;          prom_b thunk table is a block of kernel entry points: 0xF42D70
;          0xF8584A, 0xF42D74 0xF85877, 0xF42D78 0xF858C0, 0xF42D7C 0xF85904,
;          0xF42D80 0xF8592D.  Who calls the THUNK is prom_b's business.
; Inputs:  A = the queue number.  Outputs: the list at 0x032C + A*4 rotated by
;          one; WA, XIX, XIY, XHL saved and restored, so it clobbers nothing.
; Evidence: the two bodies are BYTE-IDENTICAL over 38 bytes --
;          0xF85897-0xF858BC here matches 0xF858D9-0xF858FE there exactly, and
;          the run stops on the byte after in both directions (checked by
;          notes/prom_a_byte_checks.py, not by eye).  What differs is only the
;          wrapper: the four-register save of an ordinary leaf instead of the
;          scheduler frame, `jr` to the epilogue instead of Kernel_ResumeTask,
;          and `ret` instead of Kernel_Dispatch.  It also does NOT raise the
;          interrupt mask, which is worth noticing before calling it.
; Unknown:  who calls it, and why a version without the critical section exists.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_RotateQueue -- the same rotation, but it RETURNS.
;
; Called from: ⚠ NOT ESTABLISHED.  prom_c_xrefs.py reports one calr displacement,
;              at 0xF92121, which lies inside the 96 KiB this file still leaves as
;              `.incbin` at the front -- the tool does not prove a hit is an
;              instruction, so that is a candidate and not a call site.  No
;              literal reference exists.
; Inputs:  A = ready-queue level, 1-based.
; Outputs: as Kernel_YieldRotate, but four registers are saved and restored and
;          the routine RETs instead of entering the scheduler.
; Evidence: the queue arithmetic, the head->next vs head->prev emptiness test and
;          the four-store re-append are the same instructions as
;          Kernel_YieldRotate; the difference is the wrapper -- four pushes
;          instead of seven, no `ei 6`, and `ret`.
;          prom_a's Kernel_RotateQueue (0xF858C0) is the same 32 instructions with
;          2 operand differences and 0 structural ones.
; --------------------------------------------------------------------------

Kernel_RotateQueue:
	push XWA                                     ; F858C0/F98425  38   push XWA
	push XIX                                     ; F858C1/F98426  3c   push XIX
	push XIY                                     ; F858C2/F98427  3d   push XIY
	push XHL                                     ; F858C3/F98428  3b   push XHL
	sll a, 0x02                                  ; F858C4/F98429  c9 ee 02   sll 0x02,A
	extz WA                                      ; F858C7/F9842C  d8 12   extz WA
	add WA,KERNEL_READY_HEADS-4                  ; F858C9/F9842E  a=d8 c8 2c 03 c=d8 c8 20 01   c: add WA,0x0120
	ld IY,WA                                     ; F858CD/F98432  d8 8d   ld IY,WA
	extz XIY                                     ; F858CF/F98434  ed 12   extz XIY
	m_ld_rm MWD+r5, 0x00, r4                     ; F858D1/F98436  9d 00 24   ld IX,(XIY+0x00)
	cp IX,(XIY+0x02)                             ; F858D4/F98439  9d 02 f4   cp IX,(XIY+0x02)
	jr z, Kernel_RotateQueue__ret                ; F858D7/F9843C  66 26   jr Z,0xf98464
	extz XIX                                     ; F858D9/F9843E  ec 12   extz XIX
	extz XWA                                     ; F858DB/F98440  e8 12   extz XWA
	extz XHL                                     ; F858DD/F98442  eb 12   extz XHL
	m_ld_rm MWD+r4, 0x00, r0                     ; F858DF/F98444  9c 00 20   ld WA,(XIX+0x00)
	ld HL,(XIX+0x02)                             ; F858E2/F98447  9c 02 23   ld HL,(XIX+0x02)
	m_st_mr16 MDD+r3, 0x00, r0                   ; F858E5/F9844A  bb 00 50   ld (XHL+0x00),WA
	ld (XWA+0x02),HL                             ; F858E8/F9844D  b8 02 53   ld (XWA+0x02),HL
	extz XIX                                     ; F858EB/F98450  ec 12   extz XIX
	extz XIY                                     ; F858ED/F98452  ed 12   extz XIY
	extz XWA                                     ; F858EF/F98454  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F858F1/F98456  bc 00 55   ld (XIX+0x00),IY
	ld WA,(XIY+0x02)                             ; F858F4/F98459  9d 02 20   ld WA,(XIY+0x02)
	ld (XIX+0x02),WA                             ; F858F7/F9845C  bc 02 50   ld (XIX+0x02),WA
	ld (XWA),IX                                  ; F858FA/F9845F  b0 54   ld (XWA),IX
	ld (XIY+0x02),IX                             ; F858FC/F98461  bd 02 54   ld (XIY+0x02),IX
Kernel_RotateQueue__ret:
	pop XHL                                      ; F858FF/F98464  5b   pop XHL
	pop XIY                                      ; F85900/F98465  5d   pop XIY
	pop XIX                                      ; F85901/F98466  5c   pop XIX
	pop XWA                                      ; F85902/F98467  58   pop XWA
	ret                                          ; F85903/F98468  0e   ret

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ==============================================================================
; 0xF85904-0xF85C88 -- CONVERTED.  This banner said "not yet converted" and sat directly
; above the converted code; removed 2026-08-25 (wave 5 round 2).  A check in
; notes/prom_a_byte_checks.py now fails if a "not yet converted" banner has no
; `.incbin` under it.
; ==============================================================================

; ==============================================================================
; 0xF85904-0xF8596C -- block the running task, and put a blocked one back
; ==============================================================================
;
; ★ QUEUE MEMBERSHIP IS RUNNABILITY; THE +9 STATE BYTE IS BOOKKEEPING.  These
;   two routines are what settle that, and it matters because it is the opposite
;   of what a reader expects.  Kernel_ReadyTask below puts a task back on its
;   ready queue and NEVER WRITES +9 -- it leaves the byte at 3.  That is not an
;   omission: Kernel_Dispatch__scan (0xF85746, converted above) picks a task by
;   walking the three heads and taking the first whose +0 differs from the head
;   address; it never reads +9.  So a task is runnable exactly while it is
;   linked into a ready queue, and +9 records WHY it is where it is.
;   ⚠ What the values mean in the firmware's own vocabulary is still not
;   established.  What IS established is who writes each one:
;     0  Kernel_InitRam, Kernel_ExitTask, 0xF85E5B
;     3  Kernel_BlockSelf (here) and MsgQueue_ReceiveBlocking
;     4  Kernel_StartTask
;
; ---------------------------------------------------------------------
; Kernel_BlockSelf -- take the running task off its queue and mark it blocked
;
; Called from: prom_b thunks 0xF42D7C AND 0xF42DB8 -- the same address in both
;          runs, so it takes no argument.  No prom_a site reaches it
;          (notes/prom_a_byte_checks.py).
; Inputs:  (0xBF) = the running task's control block, as Kernel_Dispatch left it
; Outputs: never returns to its caller.  The block is unlinked from whatever
;          queue it was on, its +9 becomes 3, and control passes to
;          Kernel_Dispatch -- which, because (0xBF) is still set, saves this
;          task's XSP into node+4 on the way.  That is what makes the task
;          RESUMABLE, and it is the whole difference from Kernel_ExitTask.
; Evidence: three instructions carry the name.  `ld IX,(0xBF)` at 0xF8590E takes
;          the RUNNING task rather than an argument -- (0xBF) is the byte
;          Kernel_Dispatch writes at 0xF8575B when it switches in.  0xF85917-
;          0xF85922 is the tree's unlink idiom verbatim, `prev->next = next;
;          next->prev = prev`, the same two stores as 0xF8589D-0xF858A8 and
;          0xF85865-0xF85870.  And `ld (XIX+0x09),0x03` at 0xF85923 writes the
;          same value MsgQueue_ReceiveBlocking writes when a receive finds the
;          queue empty -- which is the one place in this file where a task is
;          known to be waiting for something.
;          ⚠ Contrast with Kernel_ExitTask (0xF8584A), which is the same shape
;          but ALSO clears (0xBF) and switches to the boot stack.  This one does
;          neither, so its stack survives and Kernel_Dispatch records it.
; Unknown:  who calls it -- both references are prom_b thunks.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_BlockSelf -- take the running task off its queue and reschedule.
;
; Called from: ⚠ no site found in prom_c -- no literal, no calr.
; Inputs:  (0x0091).
; Outputs: the running task's block unlinked, its +9 set to 3, then `jrl
;          Kernel_Dispatch`.
; Evidence: the inverse of Kernel_ReadyTask, which refuses to re-queue a block
;          whose +9 is not 3.  It does NOT clear (0x0091) and does NOT switch
;          stacks, so the dispatcher's prologue saves this task's XSP into its
;          own block +4 -- which is the whole difference from Kernel_ExitTask.
;          prom_a's Kernel_BlockSelf (0xF85904) is the same 19 instructions with 2
;          operand differences and 0 structural ones.
; --------------------------------------------------------------------------

Kernel_BlockSelf:
	push SR                                      ; F85904/F98469  02   push SR
	ei 0x06                                      ; F85905/F9846A  06 06   ei 0x06
	push XHL                                     ; F85907/F9846C  3b   push XHL
	push XWA                                     ; F85908/F9846D  38   push XWA
	push XBC                                     ; F85909/F9846E  39   push XBC
	push XDE                                     ; F8590A/F9846F  3a   push XDE
	push XIX                                     ; F8590B/F98470  3c   push XIX
	push XIY                                     ; F8590C/F98471  3d   push XIY
	push XIZ                                     ; F8590D/F98472  3e   push XIZ   the seven Kernel_ResumeTask will pop
	m_ld_rm MW8, KERNEL_CURRENT_TASK, r4         ; F8590E/F98473  a=d0 bf 24 c=d0 91 24   c: ld IX,(0x91)   ld IX,(0xBF) -- the RUNNING task
	extz XIX                                     ; F85911/F98476  ec 12   extz XIX
	extz XWA                                     ; F85913/F98478  e8 12   extz XWA
	extz XHL                                     ; F85915/F9847A  eb 12   extz XHL
	m_ld_rm MWD+r4, 0x00, r0                     ; F85917/F9847C  9c 00 20   ld WA,(XIX+0x00)   ld WA,(XIX+0x00) -- next
	ld HL,(XIX+0x02)                             ; F8591A/F9847F  9c 02 23   ld HL,(XIX+0x02)   prev
	m_st_mr16 MDD+r3, 0x00, r0                   ; F8591D/F98482  bb 00 50   ld (XHL+0x00),WA   ld (XHL+0x00),WA -- prev->next = next
	ld (XWA+0x02),HL                             ; F85920/F98485  b8 02 53   ld (XWA+0x02),HL   next->prev = prev
	ld (XIX+0x09),0x03                           ; F85923/F98488  bc 09 00 03   ld (XIX+0x09),0x03   state 3 -- the value a blocking receive writes
	jrl Kernel_Dispatch                          ; F85927/F9848C  78 eb fd   jrl T,0xf9827a   (0xBF) is left set, so the dispatcher saves XSP into node+4

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ---------------------------------------------------------------------
; Kernel_ReadyTask_StackArg -- the stack-argument face of Kernel_ReadyTask
;
; Called from: prom_b thunk 0xF42DBC (`jp 0xF8592A`), and nothing else
; Inputs:  (XSP+0x04) = the task number
; Outputs: as Kernel_ReadyTask, which it falls into
; Evidence: the same three bytes 8F 04 21 as the other stack-argument entries,
;          three bytes above the register entry the FIRST thunk run names.  See
;          the region banner at 0xF857D6.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_ReadyTask_StackArg / Kernel_ReadyTask -- put a BLOCKED task back on its
; own ready queue, then reschedule.
;
; Called from: ⚠ no site found in prom_c for either entry.
; Inputs:  A = task number, 1-based.
; Outputs: nothing unless TCB+9 == 3; then the block is appended to the tail of
;          0x0120 + (TCB+8)*4.  Either way it leaves through Kernel_Dispatch.
; Evidence: the guard is literal -- `cp (XIX+0x09),0x03` -- and the level comes
;          from the task's OWN +8, filled by Kernel_StartTask from
;          EntryPoint_Records+10, not from an argument.
;          ★ It never writes +9.  The state byte stays 3 while the task is back on
;          a queue and running, and Kernel_Dispatch__scan never reads +9 at all --
;          queue membership is runnability, +9 is bookkeeping.  Same finding as
;          prom_a's, and it holds here for the same reason: this routine's 64
;          bytes contain the byte 0x09 EXACTLY ONCE, at 0xF984A8, which is the
;          displacement inside the guard `cp (XIX+0x09),0x03` at 0xF984A7 -- so
;          there is no store to +9 in any encoding.  Checked by
;          `python3 notes/prom_c_kernel_map.py --selftest`, not by eye.
;          prom_a's Kernel_ReadyTask (0xF8592D) is the same 29 instructions with 4
;          operand differences and 0 structural ones.
; --------------------------------------------------------------------------

Kernel_ReadyTask_StackArg:
	ld A,(XSP+0x04)                              ; F8592A/F9848F  8f 04 21   ld A,(XSP+0x04)   the task number, off the stack

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ---------------------------------------------------------------------
; Kernel_ReadyTask -- put blocked task A back on its ready queue
;
; Called from: prom_b thunk 0xF42D80; and by falling in from the entry above.
;          No prom_a site reaches either.
; Inputs:  A = the task number, 1..4
; Outputs: never returns to its caller -- it ends in Kernel_Dispatch either way.
;          If the task's +9 is 3 it is appended to the TAIL of ready queue
;          0x0330 + (level-1)*4, where level is its own +8.  If +9 is anything
;          else the routine does nothing at all.
; Evidence: the guard is literal -- `cp (XIX+0x09),0x03` at 0xF85942 tests for
;          exactly the value Kernel_BlockSelf above and MsgQueue_ReceiveBlocking
;          write, so this routine is the inverse of those two and of nothing
;          else.  The queue it chooses is not an argument: it comes from the
;          task's own +8 (0xF85948), which Kernel_StartTask filled from
;          EntryPoint_Records+10.  The four stores at 0xF8595C-0xF85969 are the
;          insert-at-tail idiom verbatim, the same as 0xF858AF-0xF858BC.
;          The TCB address 0x02F4 + A*12 is the same 1-based form as
;          Kernel_StartTask's.
; Notes:   ★ IT DOES NOT WRITE +9.  The state byte stays 3 while the task is
;          back on a ready queue and running.  See the region banner: queue
;          membership is what the dispatcher reads.
; Unknown:  who calls it, and therefore what "blocked" is blocked ON in the
;          cases that do not go through MsgQueue_ReceiveBlocking.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_ReadyTask -- the register-argument face; A = the task number.
; Called from: ⚠ no site found in prom_c (prom_c_xrefs.py 0xF98492: zero of every kind).
; Evidence: it is the same routine as the stack face immediately above -- that
;          face's only instruction(s) load the argument(s) from the stack and
;          fall through to this label.  Body, evidence and unknowns are in the
;          block above.
; --------------------------------------------------------------------------

Kernel_ReadyTask:
	push SR                                      ; F8592D/F98492  02   push SR
	ei 0x06                                      ; F8592E/F98493  06 06   ei 0x06
	push XHL                                     ; F85930/F98495  3b   push XHL
	push XWA                                     ; F85931/F98496  38   push XWA
	push XBC                                     ; F85932/F98497  39   push XBC
	push XDE                                     ; F85933/F98498  3a   push XDE
	push XIX                                     ; F85934/F98499  3c   push XIX
	push XIY                                     ; F85935/F9849A  3d   push XIY
	push XIZ                                     ; F85936/F9849B  3e   push XIZ
	mul A,0x0c                                   ; F85937/F9849C  c9 08 0c   mul A,0x0c
	add WA,KERNEL_TCB_BASE-12                    ; F8593A/F9849F  a=d8 c8 f4 02 c=d8 c8 f4 00   c: add WA,0x00f4   XIX = 0x0300 + (A-1)*12, the task control block
	ld IX,WA                                     ; F8593E/F984A3  d8 8c   ld IX,WA
	extz XIX                                     ; F85940/F984A5  ec 12   extz XIX
	cp (XIX+0x09),0x03                           ; F85942/F984A7  8c 09 3f 03   cp (XIX+0x09),0x03   only a BLOCKED task is re-queued
	jr nz, Kernel_ReadyTask__done                ; F85946/F984AB  6e 22   jr NZ,0xf984cf
	ld A,(XIX+0x08)                              ; F85948/F984AD  8c 08 21   ld A,(XIX+0x08)   +8 = the task's own priority level
	sll a, 0x02                                  ; F8594B/F984B0  c9 ee 02   sll 0x02,A
	extz WA                                      ; F8594E/F984B3  d8 12   extz WA
	add WA,KERNEL_READY_HEADS-4                  ; F85950/F984B5  a=d8 c8 2c 03 c=d8 c8 20 01   c: add WA,0x0120   the head, 0x0330 + (level-1)*4
	ld IY,WA                                     ; F85954/F984B9  d8 8d   ld IY,WA
	extz XIX                                     ; F85956/F984BB  ec 12   extz XIX
	extz XIY                                     ; F85958/F984BD  ed 12   extz XIY
	extz XWA                                     ; F8595A/F984BF  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F8595C/F984C1  bc 00 55   ld (XIX+0x00),IY   ld (XIX+0x00),IY -- n->next = head
	ld WA,(XIY+0x02)                             ; F8595F/F984C4  9d 02 20   ld WA,(XIY+0x02)
	ld (XIX+0x02),WA                             ; F85962/F984C7  bc 02 50   ld (XIX+0x02),WA   n->prev = head->prev
	ld (XWA),IX                                  ; F85965/F984CA  b0 54   ld (XWA),IX   head->prev->next = n
	ld (XIY+0x02),IX                             ; F85967/F984CC  bd 02 54   ld (XIY+0x02),IX   head->prev = n
Kernel_ReadyTask__done:
	jrl Kernel_Dispatch                          ; F8596A/F984CF  78 a8 fd   jrl T,0xf9827a

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ==============================================================================
; 0xF8596D-0xF85AEE -- the kernel's COUNTING SEMAPHORES, and a no-reschedule
;                      variant of Kernel_ReadyTask
; ==============================================================================
;
; ★ THIS REGION IDENTIFIES THE TWO STRUCTURES Kernel_InitRam LEFT UNEXPLAINED.
;   That routine creates eight self-linked list heads at 0x033C and copies eight
;   bytes from ROM 0xF85EBA to 0x035C, and this file could say no more about
;   either.  They are the two halves of EIGHT COUNTING SEMAPHORES:
;
;     0x033C + (s-1)*4   the wait queue for semaphore s, s = 1..8
;     0x035C + (s-1)     its count, ONE BYTE, saturating at 0xFF
;
;   The arrays are adjacent and both are exactly eight long: the last head is at
;   0x0358 and 0x0358 + 4 = 0x035C, where the counts begin, and 0x035C + 8 =
;   0x0364, which is the wait-queue array Kernel_InitRam creates next.  Both are
;   addressed with the same one-element bias as everything else in this kernel --
;   `0x0338 + s*4` and `0x035B + s`.
;
;   ★ AND THE ROM IMAGE IS THE INITIAL COUNTS.  The eight bytes at 0xF85EBA are
;     00 01 00 01 00 00 00 00, so semaphores 2 and 4 start at 1 and the other six
;     start at 0 -- two binary semaphores taken by the first waiter, and six that
;     block until something signals.  This is what those "UNIDENTIFIED" bytes
;     after EntryPoint_Records are for.
;
; ★ THE PAIR IS A TEXTBOOK P/V, and that is what carries the name -- not the
;   shape of one routine but the fact that two routines are exact inverses over
;   the same two arrays:
;
;     WAIT   (0xF85A96)  count non-zero -> decrement it and RETURN;
;                        count zero     -> unlink the running task, state := 3,
;                                          append it to queue s, dispatch
;     SIGNAL (0xF859AE)  queue non-empty -> unlink its FIRST node, state := 4,
;                                           append to that task's ready queue
;                        queue empty     -> increment the count, saturating
;
;   Nothing else in this kernel touches 0x033C or 0x035C.
;
; ★ EVERY PRIMITIVE COMES IN TWO FORMS.  Signal exists twice: 0xF859AE ends in
;   `jrl Kernel_Dispatch` and 0xF85A22 ends in `ret`.  The same split is already
;   visible one region up -- Kernel_ReadyTask (0xF8592D) dispatches and
;   Kernel_ReadyTask_NoDispatch (0xF8596D) returns.  A caller that must not lose
;   the CPU (an interrupt handler, or kernel code mid-sequence) uses the second.
;   The two members of a pair are byte-for-byte the same logic with a different
;   epilogue; the differences are measured, not asserted -- see each header.
;
; Everything quantified here is re-derived by notes/prom_a_byte_checks.py.
;
; ---------------------------------------------------------------------
; Kernel_ReadyTask_NoDispatch -- Kernel_ReadyTask, but it returns to its caller
;
; Called from: prom_b thunk 0xF42D84, and nothing else.  It has no
;          stack-argument face: the second thunk run has no slot for it.
; Inputs:  A = the task number, 1..4
; Outputs: if the task's +9 is 3 it is appended to the tail of ready queue
;          0x0330 + (level-1)*4.  Then it RETURNS -- no reschedule.  Only XWA,
;          XIX, XIY and SR are saved, because the caller keeps running.
; Evidence: the body is Kernel_ReadyTask's (0xF8592D, converted above) with a
;          different prologue and epilogue: the same `cp (XIX+0x09),0x03` guard,
;          the same 0x02F4 + A*12, the same 0x032C + level*4 and the same four
;          insert-at-tail stores.  ⚠ MEASURED, not asserted: 0xF85937 and
;          0xF85973 are IDENTICAL for exactly 51 bytes -- the identity extends
;          0 bytes backwards and stops at byte 51, which is each routine's
;          epilogue.  notes/prom_a_byte_checks.py does that diff and checks both
;          ends of the run, not just its start.
; Unknown:  who calls it -- the one reference is a prom_b thunk.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_ReadyTask_NoDispatch -- the same, but it RETs instead of rescheduling.
;
; Called from: ⚠ no site found in prom_c.
; Inputs:  A = task number, 1-based.  Outputs: as above, minus the reschedule.
; Evidence: same guard, same level source, same four-store append; four pushes and
;          a `pop SR / ret` epilogue instead of the seven-push kernel entry.
;          prom_a's (0xF8596D) is the same 29 instructions with 3 operand
;          differences and 0 structural ones.
; --------------------------------------------------------------------------

Kernel_ReadyTask_NoDispatch:
	push XWA                                     ; F8596D/F984D2  38   push XWA
	push XIX                                     ; F8596E/F984D3  3c   push XIX
	push XIY                                     ; F8596F/F984D4  3d   push XIY
	push SR                                      ; F85970/F984D5  02   push SR
	ei 0x06                                      ; F85971/F984D6  06 06   ei 0x06
	mul A,0x0c                                   ; F85973/F984D8  c9 08 0c   mul A,0x0c
	add WA,KERNEL_TCB_BASE-12                    ; F85976/F984DB  a=d8 c8 f4 02 c=d8 c8 f4 00   c: add WA,0x00f4
	ld IX,WA                                     ; F8597A/F984DF  d8 8c   ld IX,WA
	extz XIX                                     ; F8597C/F984E1  ec 12   extz XIX
	cp (XIX+0x09),0x03                           ; F8597E/F984E3  8c 09 3f 03   cp (XIX+0x09),0x03
	jr nz, Kernel_ReadyTask_NoDispatch__done     ; F85982/F984E7  6e 22   jr NZ,0xf9850b
	ld A,(XIX+0x08)                              ; F85984/F984E9  8c 08 21   ld A,(XIX+0x08)
	sll a, 0x02                                  ; F85987/F984EC  c9 ee 02   sll 0x02,A
	extz WA                                      ; F8598A/F984EF  d8 12   extz WA
	add WA,KERNEL_READY_HEADS-4                  ; F8598C/F984F1  a=d8 c8 2c 03 c=d8 c8 20 01   c: add WA,0x0120
	ld IY,WA                                     ; F85990/F984F5  d8 8d   ld IY,WA
	extz XIX                                     ; F85992/F984F7  ec 12   extz XIX
	extz XIY                                     ; F85994/F984F9  ed 12   extz XIY
	extz XWA                                     ; F85996/F984FB  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F85998/F984FD  bc 00 55   ld (XIX+0x00),IY
	ld WA,(XIY+0x02)                             ; F8599B/F98500  9d 02 20   ld WA,(XIY+0x02)
	ld (XIX+0x02),WA                             ; F8599E/F98503  bc 02 50   ld (XIX+0x02),WA
	ld (XWA),IX                                  ; F859A1/F98506  b0 54   ld (XWA),IX
	ld (XIY+0x02),IX                             ; F859A3/F98508  bd 02 54   ld (XIY+0x02),IX
Kernel_ReadyTask_NoDispatch__done:
	pop SR                                       ; F859A6/F9850B  03   pop SR
	pop XIY                                      ; F859A7/F9850C  5d   pop XIY
	pop XIX                                      ; F859A8/F9850D  5c   pop XIX
	pop XWA                                      ; F859A9/F9850E  58   pop XWA
	ret                                          ; F859AA/F9850F  0e   ret

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ---------------------------------------------------------------------
; Kernel_SemaSignal_StackArg -- the stack-argument face of Kernel_SemaSignal
;
; Called from: prom_b thunk 0xF42DC0 (`jp 0xF859AB`), and nothing else
; Inputs:  (XSP+0x04) = the semaphore number, 1..8
; Outputs: as Kernel_SemaSignal, which it falls into
; Evidence: the same three bytes 8F 04 21 as every other stack face, three bytes
;          above the register entry the first thunk run names (0xF42D88 ->
;          0xF859AE).  See the region banner at 0xF857D6.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_SemaSignal_StackArg / Kernel_SemaSignal -- V() on semaphore A.
;
; Called from: TWO sites, both on this STACK face and both pushing 2 -- `call`
;              at 0xF98C6C, inside MAIN's loop, and `call` at 0xFA2DE4
;              (prom_c_xrefs.py 0xF98510).  The register face three bytes on has
;              none.
; Inputs:  A = semaphore number, 1..4.
; Outputs: if the wait queue 0x0128 + A*4 is non-empty, its first waiter is
;          unlinked, given state 4 and appended to ITS ready queue, and the
;          scheduler is entered; otherwise the count at 0x013B + A is incremented,
;          SATURATING at 0xFF, and control goes to Kernel_ResumeTask.
; Evidence: the two arrays are the two literal bases, 0x0128 + A*4 (the wait-queue
;          head, i.e. 0x012C + (A-1)*4) and 0x013B + A (the count byte, i.e.
;          0x013C + (A-1)) -- adjacent arrays, four entries each, exactly as
;          Kernel_InitRam lays them out.  The saturation is an instruction, not a
;          reading: `ld A,(XHL) / inc 1,A / jr Z,+2 / ld (XHL),A` skips the store
;          precisely when the increment wrapped 0xFF to 0x00.
;          prom_a's Kernel_SemaSignal (0xF859AE) is the same 48 instructions with
;          7 operand differences and 0 structural ones.
; --------------------------------------------------------------------------

Kernel_SemaSignal_StackArg:
	ld A,(XSP+0x04)                              ; F859AB/F98510  8f 04 21   ld A,(XSP+0x04)

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ---------------------------------------------------------------------
; Kernel_SemaSignal -- V(s): wake the first waiter, or bump the count
;
; Called from: prom_b thunk 0xF42D88; and by falling in from the stack face
;          above.  No prom_a site reaches either.
; Inputs:  A = the semaphore number, 1..8
; Outputs: never returns to its caller.  If a task is waiting on semaphore A it
;          is unlinked from that wait queue, its +9 becomes 4, it is appended to
;          the tail of its OWN ready queue (from its +8), and control passes to
;          Kernel_Dispatch.  If nobody is waiting, the count byte is incremented
;          -- unless it is already 0xFF -- and control returns through
;          Kernel_ResumeTask's pops.
; Evidence: the two arrays are literal and adjacent: `add WA,0x0338` at 0xF859BF
;          with A*4 is the head 0x033C + (A-1)*4, and `add HL,0x035b` at 0xF859D0
;          with A (not A*4) is the count 0x035C + (A-1).  The emptiness test is
;          the tree's own `head->next == head` -- `ld IX,(XIY+0x00) / cp IX,IY`
;          at 0xF859C7 -- the same test Kernel_Dispatch__scan uses.
;          ★ THE SATURATION IS THE INSTRUCTION, not a reading: `ld A,(XHL) /
;          inc 1,A / jr Z,+2 / ld (XHL),A` at 0xF859D6-0xF859DD skips the store
;          exactly when the increment wrapped 0xFF to 0x00, so 0xFF is a ceiling
;          rather than a wrap.
;          The woken task's state is set to 4 (0xF859F3), the value
;          Kernel_StartTask writes for a runnable task, and its queue comes from
;          its own +8 (0xF859F7) -- not from the semaphore.
; Unknown:  who signals which semaphore.  All eight are anonymous here; the
;          callers are in prom_b.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_SemaSignal -- the register-argument face; A = the semaphore number.
; Called from: ⚠ no site found in prom_c (prom_c_xrefs.py 0xF98513: zero); both callers use the stack face above.
; Evidence: it is the same routine as the stack face immediately above -- that
;          face's only instruction(s) load the argument(s) from the stack and
;          fall through to this label.  Body, evidence and unknowns are in the
;          block above.
; --------------------------------------------------------------------------

Kernel_SemaSignal:
	push SR                                      ; F859AE/F98513  02   push SR
	ei 0x06                                      ; F859AF/F98514  06 06   ei 0x06
	push XHL                                     ; F859B1/F98516  3b   push XHL
	push XWA                                     ; F859B2/F98517  38   push XWA
	push XBC                                     ; F859B3/F98518  39   push XBC
	push XDE                                     ; F859B4/F98519  3a   push XDE
	push XIX                                     ; F859B5/F9851A  3c   push XIX
	push XIY                                     ; F859B6/F9851B  3d   push XIY
	push XIZ                                     ; F859B7/F9851C  3e   push XIZ
	ld L,A                                       ; F859B8/F9851D  c9 8f   ld L,A
	sll a, 0x02                                  ; F859BA/F9851F  c9 ee 02   sll 0x02,A
	extz WA                                      ; F859BD/F98522  d8 12   extz WA
	add WA,KERNEL_SEMA_QUEUES-4                  ; F859BF/F98524  a=d8 c8 38 03 c=d8 c8 28 01   c: add WA,0x0128
	ld IY,WA                                     ; F859C3/F98528  d8 8d   ld IY,WA
	extz XIY                                     ; F859C5/F9852A  ed 12   extz XIY
	m_ld_rm MWD+r5, 0x00, r4                     ; F859C7/F9852C  9d 00 24   ld IX,(XIY+0x00)
	cp IX,IY                                     ; F859CA/F9852F  dd f4   cp IX,IY
	jr nz, Kernel_SemaSignal__wake               ; F859CC/F98531  6e 13   jr NZ,0xf98546
	extz HL                                      ; F859CE/F98533  db 12   extz HL
	add HL,KERNEL_SEMA_COUNTS-1                  ; F859D0/F98535  a=db c8 5b 03 c=db c8 3b 01   c: add HL,0x013b
	extz XHL                                     ; F859D4/F98539  eb 12   extz XHL
	ld A,(XHL)                                   ; F859D6/F9853B  83 21   ld A,(XHL)
	inc 1,A                                      ; F859D8/F9853D  c9 61   inc 1,A
	jr z, Kernel_SemaSignal__return              ; F859DA/F9853F  66 02   jr Z,0xf98543
	ld (XHL),A                                   ; F859DC/F98541  b3 41   ld (XHL),A
Kernel_SemaSignal__return:
	jrl Kernel_ResumeTask                        ; F859DE/F98543  78 82 fd   jrl T,0xf982c8
Kernel_SemaSignal__wake:
	extz XIX                                     ; F859E1/F98546  ec 12   extz XIX
	extz XWA                                     ; F859E3/F98548  e8 12   extz XWA
	extz XHL                                     ; F859E5/F9854A  eb 12   extz XHL
	m_ld_rm MWD+r4, 0x00, r0                     ; F859E7/F9854C  9c 00 20   ld WA,(XIX+0x00)
	ld HL,(XIX+0x02)                             ; F859EA/F9854F  9c 02 23   ld HL,(XIX+0x02)
	m_st_mr16 MDD+r3, 0x00, r0                   ; F859ED/F98552  bb 00 50   ld (XHL+0x00),WA
	ld (XWA+0x02),HL                             ; F859F0/F98555  b8 02 53   ld (XWA+0x02),HL
	ld (XIX+0x09),0x04                           ; F859F3/F98558  bc 09 00 04   ld (XIX+0x09),0x04
	ld A,(XIX+0x08)                              ; F859F7/F9855C  8c 08 21   ld A,(XIX+0x08)
	sll a, 0x02                                  ; F859FA/F9855F  c9 ee 02   sll 0x02,A
	extz WA                                      ; F859FD/F98562  d8 12   extz WA
	add WA,KERNEL_READY_HEADS-4                  ; F859FF/F98564  a=d8 c8 2c 03 c=d8 c8 20 01   c: add WA,0x0120
	ld IY,WA                                     ; F85A03/F98568  d8 8d   ld IY,WA
	extz XIX                                     ; F85A05/F9856A  ec 12   extz XIX
	extz XIY                                     ; F85A07/F9856C  ed 12   extz XIY
	extz XWA                                     ; F85A09/F9856E  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F85A0B/F98570  bc 00 55   ld (XIX+0x00),IY
	ld WA,(XIY+0x02)                             ; F85A0E/F98573  9d 02 20   ld WA,(XIY+0x02)
	ld (XIX+0x02),WA                             ; F85A11/F98576  bc 02 50   ld (XIX+0x02),WA
	ld (XWA),IX                                  ; F85A14/F98579  b0 54   ld (XWA),IX
	ld (XIY+0x02),IX                             ; F85A16/F9857B  bd 02 54   ld (XIY+0x02),IX
	jrl Kernel_Dispatch                          ; F85A19/F9857E  78 f9 fc   jrl T,0xf9827a

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ---------------------------------------------------------------------
; Kernel_SemaSignal_NoDispatch_StackArg -- stack face, and it is NOT `8F 04 21`
;
; Called from: nothing in either ROM names 0xF85A1C -- it is not in the thunk
;          block and no prom_a site reaches it (notes/prom_a_byte_checks.py).
;          It is reachable only as the entry ABOVE Kernel_SemaSignal_NoDispatch,
;          which is how every other stack face in this kernel is reached.
; Inputs:  (XSP+0x04) = the semaphore number, before its own push
; Outputs: as Kernel_SemaSignal_NoDispatch
; Evidence: ⚠ this one breaks the `ld A,(XSP+0x04)` pattern and the reason is
;          visible in the bytes: it pushes XWA FIRST (0xF85A1C) and therefore
;          reads its argument at (XSP+0x08), four bytes deeper, then `jr` over
;          the register entry's own `push XWA`.  The two paths converge at
;          0xF85A23 with XWA pushed exactly once either way.  That is the same
;          trick 0xF85B0D uses with (XSP+0x24) after seven pushes.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_SemaSignal_NoDispatch -- V(), returning instead of rescheduling.
;
; Called from: ⚠ no site found for either entry -- and that matters, because it is
;              half of the reason nothing is believed to signal semaphore 3.
; Inputs:  A = semaphore number.  Outputs: as Kernel_SemaSignal, minus the switch.
; Evidence: same two arrays, same saturating increment, same wake-and-requeue; the
;          difference is that `push SR / ei 6` is DEFERRED until after the queue
;          head has been computed, and the exit is `pop SR / ... / ret`.
;          prom_a's (0xF85A22) is the same 55 instructions with 5 operand
;          differences and 0 structural ones.
; Note:    the two entries differ only in where A comes from -- 0xF98581 reads it
;          from (XSP+0x08) after pushing XWA, 0xF98587 takes it in A -- and they
;          join at Kernel_SemaSignal_NoDispatch__common.
; --------------------------------------------------------------------------

Kernel_SemaSignal_NoDispatch_StackArg:
	push XWA                                     ; F85A1C/F98581  38   push XWA
	ld A,(XSP+0x08)                              ; F85A1D/F98582  8f 08 21   ld A,(XSP+0x08)
	jr Kernel_SemaSignal_NoDispatch__common      ; F85A20/F98585  68 01   jr T,0xf98588

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ---------------------------------------------------------------------
; Kernel_SemaSignal_NoDispatch -- V(s), returning to the caller
;
; Called from: prom_b thunk 0xF42D8C, and nothing else
; Inputs:  A = the semaphore number, 1..8
; Outputs: as Kernel_SemaSignal, except that it RETURNS instead of entering the
;          scheduler, so a woken task does not run until the next reschedule.
;          Saves XWA, XIX, XIY, XHL and SR only.
; Evidence: same two arrays, same emptiness test, same saturating increment and
;          same insert-at-tail as Kernel_SemaSignal above -- and the sameness is
;          MEASURED rather than asserted, run by run, by
;          notes/prom_a_byte_checks.py:
;            the WAKE arm      0xF859E1 / 0xF85A55   56 bytes identical
;            the COUNT arm     0xF859CE / 0xF85A3F   16 bytes identical
;            the emptiness test 0xF859C7 / 0xF85A38   6 bytes identical
;            the index arithmetic 0xF859B8 / 0xF85A26 15 bytes identical
;          and each run stops at the FIRST byte of its epilogue -- 0xF85A19 is
;          `jrl Kernel_Dispatch` where 0xF85A8D is `pop SR`, and 0xF859DE is
;          `jrl Kernel_ResumeTask` where 0xF85A4F is `pop SR`.
;          ⚠ THE WHOLE ROUTINES ARE NOT IDENTICAL and this header does not say
;          they are: the arithmetic run breaks at 0xF859C7 / 0xF85A35 because
;          this variant defers `push SR / ei 0x06` until AFTER it has computed
;          the queue head, while Kernel_SemaSignal does it in its prologue.  A
;          first draft of this header claimed "74 bytes, 0 differ"; the real
;          figure over that span is 51 differing bytes of 74, which is why the
;          runs are quoted individually.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_SemaSignal_NoDispatch -- the register-argument face; A = the semaphore number.
; Called from: ⚠ no site found in prom_c (prom_c_xrefs.py 0xF98587: zero) -- half of the reason nothing is believed to signal semaphore 3.
; Evidence: it is the same routine as the stack face immediately above -- that
;          face's only instruction(s) load the argument(s) from the stack and
;          fall through to this label.  Body, evidence and unknowns are in the
;          block above.
; --------------------------------------------------------------------------

Kernel_SemaSignal_NoDispatch:
	push XWA                                     ; F85A22/F98587  38   push XWA
Kernel_SemaSignal_NoDispatch__common:
	push XIX                                     ; F85A23/F98588  3c   push XIX
	push XIY                                     ; F85A24/F98589  3d   push XIY
	push XHL                                     ; F85A25/F9858A  3b   push XHL
	ld L,A                                       ; F85A26/F9858B  c9 8f   ld L,A
	sll a, 0x02                                  ; F85A28/F9858D  c9 ee 02   sll 0x02,A
	extz WA                                      ; F85A2B/F98590  d8 12   extz WA
	add WA,KERNEL_SEMA_QUEUES-4                  ; F85A2D/F98592  a=d8 c8 38 03 c=d8 c8 28 01   c: add WA,0x0128
	ld IY,WA                                     ; F85A31/F98596  d8 8d   ld IY,WA
	extz XIY                                     ; F85A33/F98598  ed 12   extz XIY
	push SR                                      ; F85A35/F9859A  02   push SR
	ei 0x06                                      ; F85A36/F9859B  06 06   ei 0x06
	m_ld_rm MWD+r5, 0x00, r4                     ; F85A38/F9859D  9d 00 24   ld IX,(XIY+0x00)
	cp IX,IY                                     ; F85A3B/F985A0  dd f4   cp IX,IY
	jr nz, Kernel_SemaSignal_NoDispatch__wake    ; F85A3D/F985A2  6e 16   jr NZ,0xf985ba
	extz HL                                      ; F85A3F/F985A4  db 12   extz HL
	add HL,KERNEL_SEMA_COUNTS-1                  ; F85A41/F985A6  a=db c8 5b 03 c=db c8 3b 01   c: add HL,0x013b
	extz XHL                                     ; F85A45/F985AA  eb 12   extz XHL
	ld A,(XHL)                                   ; F85A47/F985AC  83 21   ld A,(XHL)
	inc 1,A                                      ; F85A49/F985AE  c9 61   inc 1,A
	jr z, Kernel_SemaSignal_NoDispatch__return   ; F85A4B/F985B0  66 02   jr Z,0xf985b4
	ld (XHL),A                                   ; F85A4D/F985B2  b3 41   ld (XHL),A
Kernel_SemaSignal_NoDispatch__return:
	pop SR                                       ; F85A4F/F985B4  03   pop SR
	pop XHL                                      ; F85A50/F985B5  5b   pop XHL
	pop XIY                                      ; F85A51/F985B6  5d   pop XIY
	pop XIX                                      ; F85A52/F985B7  5c   pop XIX
	pop XWA                                      ; F85A53/F985B8  58   pop XWA
	ret                                          ; F85A54/F985B9  0e   ret
Kernel_SemaSignal_NoDispatch__wake:
	extz XIX                                     ; F85A55/F985BA  ec 12   extz XIX
	extz XWA                                     ; F85A57/F985BC  e8 12   extz XWA
	extz XHL                                     ; F85A59/F985BE  eb 12   extz XHL
	m_ld_rm MWD+r4, 0x00, r0                     ; F85A5B/F985C0  9c 00 20   ld WA,(XIX+0x00)
	ld HL,(XIX+0x02)                             ; F85A5E/F985C3  9c 02 23   ld HL,(XIX+0x02)
	m_st_mr16 MDD+r3, 0x00, r0                   ; F85A61/F985C6  bb 00 50   ld (XHL+0x00),WA
	ld (XWA+0x02),HL                             ; F85A64/F985C9  b8 02 53   ld (XWA+0x02),HL
	ld (XIX+0x09),0x04                           ; F85A67/F985CC  bc 09 00 04   ld (XIX+0x09),0x04
	ld A,(XIX+0x08)                              ; F85A6B/F985D0  8c 08 21   ld A,(XIX+0x08)
	sll a, 0x02                                  ; F85A6E/F985D3  c9 ee 02   sll 0x02,A
	extz WA                                      ; F85A71/F985D6  d8 12   extz WA
	add WA,KERNEL_READY_HEADS-4                  ; F85A73/F985D8  a=d8 c8 2c 03 c=d8 c8 20 01   c: add WA,0x0120
	ld IY,WA                                     ; F85A77/F985DC  d8 8d   ld IY,WA
	extz XIX                                     ; F85A79/F985DE  ec 12   extz XIX
	extz XIY                                     ; F85A7B/F985E0  ed 12   extz XIY
	extz XWA                                     ; F85A7D/F985E2  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F85A7F/F985E4  bc 00 55   ld (XIX+0x00),IY
	ld WA,(XIY+0x02)                             ; F85A82/F985E7  9d 02 20   ld WA,(XIY+0x02)
	ld (XIX+0x02),WA                             ; F85A85/F985EA  bc 02 50   ld (XIX+0x02),WA
	ld (XWA),IX                                  ; F85A88/F985ED  b0 54   ld (XWA),IX
	ld (XIY+0x02),IX                             ; F85A8A/F985EF  bd 02 54   ld (XIY+0x02),IX
	pop SR                                       ; F85A8D/F985F2  03   pop SR
	pop XHL                                      ; F85A8E/F985F3  5b   pop XHL
	pop XIY                                      ; F85A8F/F985F4  5d   pop XIY
	pop XIX                                      ; F85A90/F985F5  5c   pop XIX
	pop XWA                                      ; F85A91/F985F6  58   pop XWA
	ret                                          ; F85A92/F985F7  0e   ret

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ---------------------------------------------------------------------
; Kernel_SemaWait_StackArg -- the stack-argument face of Kernel_SemaWait
;
; Called from: prom_b thunk 0xF42DC4 (`jp 0xF85A93`), and nothing else
; Inputs:  (XSP+0x04) = the semaphore number, 1..8
; Outputs: as Kernel_SemaWait, which it falls into
; Evidence: the `8F 04 21` prologue again, three bytes above the register entry
;          the first thunk run names (0xF42D90 -> 0xF85A96).
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_SemaWait_StackArg / Kernel_SemaWait -- P() on semaphore A; blocks.
;
; Called from: TWO sites, both on the stack face: `call 0xF985F8` at 0xF98121,
;              inside DSP_ChannelRefresh_Loop, which pushes 3; and at 0xFA54DE,
;              the first instruction of task 2, which pushes 2.
; Inputs:  A = semaphore number, 1..4.
; Outputs: count non-zero -> decrement it and leave through Kernel_ResumeTask;
;          count zero -> unlink the running task, +9 := 3, append it to the wait
;          queue 0x0128 + A*4, and enter Kernel_Dispatch.
; Evidence: the exact inverse of Kernel_SemaSignal over the SAME two arrays -- the
;          same count byte at 0x013B + A, the same emptiness question asked the
;          other way round, `dec` against `inc`, the same queue.  That inverse
;          relation is what carries the name; no single routine's shape would.
;          prom_a's Kernel_SemaWait (0xF85A96) is the same 39 instructions with 6
;          operand differences and 0 structural ones.
; --------------------------------------------------------------------------

Kernel_SemaWait_StackArg:
	ld A,(XSP+0x04)                              ; F85A93/F985F8  8f 04 21   ld A,(XSP+0x04)

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ---------------------------------------------------------------------
; Kernel_SemaWait -- P(s): take the count, or block on the semaphore's queue
;
; Called from: prom_b thunk 0xF42D90; and by falling in from the stack face.
; Inputs:  A = the semaphore number, 1..8
; Outputs: if the count byte is non-zero it is DECREMENTED and the routine
;          returns to its caller through Kernel_ResumeTask's pops -- the caller
;          keeps the CPU.  If it is zero, the RUNNING task (from (0xBF)) is
;          unlinked from its ready queue, its +9 becomes 3, it is appended to
;          the tail of semaphore A's wait queue, and control passes to
;          Kernel_Dispatch, which -- because (0xBF) is still set -- saves its
;          XSP into node+4 first.  So the task resumes exactly here when
;          Kernel_SemaSignal wakes it.
; Evidence: ★ it is the EXACT INVERSE of Kernel_SemaSignal over the same two
;          arrays, and that is what makes "semaphore" a name rather than a
;          guess: `add WA,0x035b` at 0xF85AA4 is the same count byte
;          0x035C + (A-1); `cp (XWA),0x00 / jr z` at 0xF85AAA is the test
;          Signal's "queue empty" arm complements; `dec 1,(XWA)` at 0xF85AAF
;          undoes Signal's `inc 1,A`; and `add DE,0x0338` at 0xF85AD2 with A*4
;          is the same wait queue 0x033C + (A-1)*4 that Signal pops from.
;          The blocking arm is Kernel_BlockSelf's body verbatim -- (0xBF), the
;          unlink idiom, +9 := 3 -- followed by the insert-at-tail idiom onto
;          the semaphore's queue instead of a ready queue.
;          ⚠ Note it keeps the semaphore number in E across the unlink
;          (`ld E,A` at 0xF85AA0), because A is destroyed by the count
;          arithmetic; the queue index is recomputed from E at 0xF85ACD.
; Unknown:  which semaphore is which.  Nothing here names them, and the two that
;          start at 1 (numbers 2 and 4, from the ROM image at 0xF85EBA) are the
;          only asymmetry the firmware itself shows.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_SemaWait -- the register-argument face; A = the semaphore number.
; Called from: ⚠ no site found in prom_c (prom_c_xrefs.py 0xF985FB: zero); both callers use the stack face above.
; Evidence: it is the same routine as the stack face immediately above -- that
;          face's only instruction(s) load the argument(s) from the stack and
;          fall through to this label.  Body, evidence and unknowns are in the
;          block above.
; --------------------------------------------------------------------------

Kernel_SemaWait:
	push SR                                      ; F85A96/F985FB  02   push SR
	ei 0x06                                      ; F85A97/F985FC  06 06   ei 0x06
	push XHL                                     ; F85A99/F985FE  3b   push XHL
	push XWA                                     ; F85A9A/F985FF  38   push XWA
	push XBC                                     ; F85A9B/F98600  39   push XBC
	push XDE                                     ; F85A9C/F98601  3a   push XDE
	push XIX                                     ; F85A9D/F98602  3c   push XIX
	push XIY                                     ; F85A9E/F98603  3d   push XIY
	push XIZ                                     ; F85A9F/F98604  3e   push XIZ
	ld E,A                                       ; F85AA0/F98605  c9 8d   ld E,A
	extz WA                                      ; F85AA2/F98607  d8 12   extz WA
	add WA,KERNEL_SEMA_COUNTS-1                  ; F85AA4/F98609  a=d8 c8 5b 03 c=d8 c8 3b 01   c: add WA,0x013b
	extz XWA                                     ; F85AA8/F9860D  e8 12   extz XWA
	cp (XWA),0x00                                ; F85AAA/F9860F  80 3f 00   cp (XWA),0x00
	jr z, Kernel_SemaWait__block                 ; F85AAD/F98612  66 05   jr Z,0xf98619
	decm8 0x01, (xwa)                            ; F85AAF/F98614  80 69   dec 1,(XWA)
	jrl Kernel_ResumeTask                        ; F85AB1/F98616  78 af fc   jrl T,0xf982c8
Kernel_SemaWait__block:
	m_ld_rm MW8, KERNEL_CURRENT_TASK, r4         ; F85AB4/F98619  a=d0 bf 24 c=d0 91 24   c: ld IX,(0x91)
	extz XIX                                     ; F85AB7/F9861C  ec 12   extz XIX
	extz XWA                                     ; F85AB9/F9861E  e8 12   extz XWA
	extz XHL                                     ; F85ABB/F98620  eb 12   extz XHL
	m_ld_rm MWD+r4, 0x00, r0                     ; F85ABD/F98622  9c 00 20   ld WA,(XIX+0x00)
	ld HL,(XIX+0x02)                             ; F85AC0/F98625  9c 02 23   ld HL,(XIX+0x02)
	m_st_mr16 MDD+r3, 0x00, r0                   ; F85AC3/F98628  bb 00 50   ld (XHL+0x00),WA
	ld (XWA+0x02),HL                             ; F85AC6/F9862B  b8 02 53   ld (XWA+0x02),HL
	ld (XIX+0x09),0x03                           ; F85AC9/F9862E  bc 09 00 03   ld (XIX+0x09),0x03
	sll e, 0x02                                  ; F85ACD/F98632  cd ee 02   sll 0x02,E
	extz DE                                      ; F85AD0/F98635  da 12   extz DE
	add DE,KERNEL_SEMA_QUEUES-4                  ; F85AD2/F98637  a=da c8 38 03 c=da c8 28 01   c: add DE,0x0128
	ld IY,DE                                     ; F85AD6/F9863B  da 8d   ld IY,DE
	extz XIX                                     ; F85AD8/F9863D  ec 12   extz XIX
	extz XIY                                     ; F85ADA/F9863F  ed 12   extz XIY
	extz XWA                                     ; F85ADC/F98641  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F85ADE/F98643  bc 00 55   ld (XIX+0x00),IY
	ld WA,(XIY+0x02)                             ; F85AE1/F98646  9d 02 20   ld WA,(XIY+0x02)
	ld (XIX+0x02),WA                             ; F85AE4/F98649  bc 02 50   ld (XIX+0x02),WA
	ld (XWA),IX                                  ; F85AE7/F9864C  b0 54   ld (XWA),IX
	ld (XIY+0x02),IX                             ; F85AE9/F9864E  bd 02 54   ld (XIY+0x02),IX
	jrl Kernel_Dispatch                          ; F85AEC/F98651  78 26 fc   jrl T,0xf9827a

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ---------------------------------------------------------------------
; Kernel_SemaTryWait -- P(s) that never blocks: take the count or say no
;
; Called from: prom_b thunk 0xF42DD8 (`jp 0xF85AEF`), and nothing else.  ⚠ It is
;          the ONLY semaphore entry with no register-argument twin in the first
;          thunk run -- it is published once, and only with a stack argument.
; Inputs:  (XSP+0x04) = the semaphore number, 1..8
; Outputs: WA = 0 if the count was non-zero, in which case it was DECREMENTED;
;          WA = 0xFFFF if it was zero, in which case nothing was touched.  It
;          always returns to its caller and can never block, so it is safe from
;          code that must not lose the CPU.  Only SR is saved.
; Evidence: it is Kernel_SemaWait's first arm and nothing else.  The count byte
;          is the same 0x035B + s (0xF85AF4) that Wait, Signal and
;          Signal_NoDispatch use -- notes/prom_a_byte_checks.py enumerates all
;          seven sites in prom_a that form that base and there are no others --
;          and `cp (XWA),0x00 / jr z` at 0xF85AFD is Wait's test verbatim
;          (0xF85AAA), followed by Wait's `dec 1,(XWA)` (0xF85B02 against
;          0xF85AAF).  Where Wait then blocks the running task, this one loads a
;          RESULT: `xor WA,WA` on the success path (0xF85B04) and
;          `ld WA,0xFFFF` on the failure path (0xF85B08).
;          ⚠ It never touches the semaphore's WAIT QUEUE at 0x033C -- the byte
;          pair that forms that base (C8 38 03) does not occur in these 30
;          bytes, which is the check named above seen from the other side.
; Unknown:  who calls it.  The single reference is a prom_b thunk.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_SemaTryWait -- P() that never blocks.
;
; Called from: `call 0xF98654` at 0xFA54E6, inside task 2's drain loop, pushing 2.
;              One site.
; Inputs:  (XSP+4) = semaphore number.
; Outputs: count non-zero -> decrement, WA = 0; count zero -> WA = 0xFFFF and
;          nothing touched.  It never enters the scheduler.
; Evidence: the same count byte 0x013B + A and the same `cp (XWA),0x00` test as
;          Kernel_SemaWait, with the blocking arm replaced by `ld WA,0xFFFF`.
;          Task 2 uses it exactly as a drain: `SemaWait(2)` once, then TryWait(2)
;          in a loop until it returns non-zero (0xFA54E3-0xFA54EF).
;          prom_a's Kernel_SemaTryWait (0xF85AEF) is the same 14 instructions with
;          3 operand differences and 0 structural ones.
; --------------------------------------------------------------------------

Kernel_SemaTryWait:
	ld A,(XSP+0x04)                              ; F85AEF/F98654  8f 04 21   ld A,(XSP+0x04)   the semaphore number, off the stack
	extz WA                                      ; F85AF2/F98657  d8 12   extz WA
	add WA,KERNEL_SEMA_COUNTS-1                  ; F85AF4/F98659  a=d8 c8 5b 03 c=d8 c8 3b 01   c: add WA,0x013b   the count byte, 0x035C + (s-1)
	extz XWA                                     ; F85AF8/F9865D  e8 12   extz XWA
	push SR                                      ; F85AFA/F9865F  02   push SR
	ei 0x06                                      ; F85AFB/F98660  06 06   ei 0x06
	cp (XWA),0x00                                ; F85AFD/F98662  80 3f 00   cp (XWA),0x00
	jr z, Kernel_SemaTryWait__fail               ; F85B00/F98665  66 06   jr Z,0xf9866d
	decm8 0x01, (xwa)                            ; F85B02/F98667  80 69   dec 1,(XWA)   take one
	xor WA,WA                                    ; F85B04/F98669  d8 d0   xor WA,WA   0 = taken
	jr Kernel_SemaTryWait__ret                   ; F85B06/F9866B  68 03   jr T,0xf98670
Kernel_SemaTryWait__fail:
	ldw wa, 0xffff                               ; F85B08/F9866D  30 ff ff   ld WA,0xffff   0xFFFF = not taken; the count is untouched
Kernel_SemaTryWait__ret:
	pop SR                                       ; F85B0B/F98670  03   pop SR
	ret                                          ; F85B0C/F98671  0e   ret

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ==== 0xF85B0D-0xF85C89 -- REACHABLE CODE ONLY, emitted by notes/gen_prom_a_cover_round1.py ====
; 2 reachable run(s), 373 bytes framed as code.  7 bytes that nothing reaches stay
; `.incbin` -- this round converts REACHABLE CODE, not territory.
; Boundaries: notes/reachability.py's walk, frozen against this file's own output.
; Labels are sub_XXXXXX by design: this round is COVERAGE, naming is a later goal.
; This text was assembled and byte-compared with the ROM before printing.

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; MsgQueue_Send_StackArg / MsgQueue_Send -- post a 32-bit message to queue A, then
; reschedule.
;
; Called from: ⚠ no site found in prom_c for either entry.
; Inputs:  A = queue number 1..2; XIZ = the 32-bit payload.  The stack face takes
;          the payload from (XSP+0x24) -- 0x06 + 2 + 7*4, i.e. the caller's second
;          argument seen through this routine's own seven pushes -- and joins the
;          register face at MsgQueue_Send__common.
; Outputs: WA = 0 if the message was delivered or queued, 0xFFFF if the free list
;          was empty.  Enters Kernel_Dispatch either way.
; Evidence: the two arrays are literal and are the two Kernel_InitRam creates last:
;          the WAIT queue at 0x013C + A*4 (= 0x0140 + (A-1)*4) is examined first,
;          and if a task is waiting there it is unlinked, given state 4, and the
;          payload is written into ITS SAVED FRAME at saved_XSP+4 -- which is the
;          XIY slot of Kernel_ResumeTask's pop order, so a message is delivered in
;          XIY.  Otherwise a node is taken from the free list at 0x0170, its +4
;          set to the payload, and it is appended to the MESSAGE queue at
;          0x0144 + A*4 (= 0x0148 + (A-1)*4).  The status is written into the
;          saved-XWA slot of this routine's own frame, (XSP+0x14).
;          prom_a's 0xF85B1F -- still .incbin there -- is the same 71 instructions
;          with 9 operand differences and 0 structural ones, and it occupies the
;          same slot of the published API.
; Unknown:  what the two queues carry.  Nothing in prom_c posts to them.
; --------------------------------------------------------------------------

MsgQueue_Send_StackArg:
sub_F85B0D:   ; <- prom_a's name for this address.  entry: prom_b routine directory
	ld A,(XSP+0x04)                              ; F85B0D/F98672  8f 04 21   ld A,(XSP+0x04)
	push SR                                      ; F85B10/F98675  02   push SR
	ei 0x06                                      ; F85B11/F98676  06 06   ei 0x06
	push XHL                                     ; F85B13/F98678  3b   push XHL
	push XWA                                     ; F85B14/F98679  38   push XWA
	push XBC                                     ; F85B15/F9867A  39   push XBC
	push XDE                                     ; F85B16/F9867B  3a   push XDE
	push XIX                                     ; F85B17/F9867C  3c   push XIX
	push XIY                                     ; F85B18/F9867D  3d   push XIY
	push XIZ                                     ; F85B19/F9867E  3e   push XIZ
	ld XIZ,(XSP+0x24)                            ; F85B1A/F9867F  af 24 26   ld XIZ,(XSP+0x24)
	jr MsgQueue_Send__common                     ; F85B1D/F98682  68 0a   jr T,0xf9868e

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; MsgQueue_Send -- the register-argument face; A = the queue number, XIZ = the payload.
; Called from: ⚠ no site found in prom_c (prom_c_xrefs.py 0xF98684: zero).
; Evidence: it is the same routine as the stack face immediately above -- that
;          face's only instruction(s) load the argument(s) from the stack and
;          fall through to this label.  Body, evidence and unknowns are in the
;          block above.
; --------------------------------------------------------------------------

MsgQueue_Send:
sub_F85B1F:   ; <- prom_a's name for this address.  entry: prom_b routine directory
	push SR                                      ; F85B1F/F98684  02   push SR
	ei 0x06                                      ; F85B20/F98685  06 06   ei 0x06
	push XHL                                     ; F85B22/F98687  3b   push XHL
	push XWA                                     ; F85B23/F98688  38   push XWA
	push XBC                                     ; F85B24/F98689  39   push XBC
	push XDE                                     ; F85B25/F9868A  3a   push XDE
	push XIX                                     ; F85B26/F9868B  3c   push XIX
	push XIY                                     ; F85B27/F9868C  3d   push XIY
	push XIZ                                     ; F85B28/F9868D  3e   push XIZ
MsgQueue_Send__common:
.LF85B29:   ; <- prom_a's name for this address.
	sll a, 0x02                                  ; F85B29/F9868E  c9 ee 02   sll 0x02,A
	ld C,A                                       ; F85B2C/F98691  c9 8b   ld C,A
	extz WA                                      ; F85B2E/F98693  d8 12   extz WA
	add WA,KERNEL_MSGQ_WAITQ-4                   ; F85B30/F98695  a=d8 c8 60 03 c=d8 c8 3c 01   c: add WA,0x013c
	ld IY,WA                                     ; F85B34/F98699  d8 8d   ld IY,WA
	extz XIY                                     ; F85B36/F9869B  ed 12   extz XIY
	m_ld_rm MWD+r5, 0x00, r4                     ; F85B38/F9869D  9d 00 24   ld IX,(XIY+0x00)
	cp IX,IY                                     ; F85B3B/F986A0  dd f4   cp IX,IY
	jr nz, MsgQueue_Send__wake                   ; F85B3D/F986A2  6e 4f   jr NZ,0xf986f3
	ld ix, (KERNEL_FREE_LIST:16)               ; F85B3F/F986A4  a=d1 c4 03 24 c=d1 70 01 24   c: ld IX,(0x0170)
	extz XIX                                     ; F85B43/F986A8  ec 12   extz XIX
	m_ld_rm MWD+r4, 0x00, r5                     ; F85B45/F986AA  9c 00 25   ld IY,(XIX+0x00)
	cp IY,IX                                     ; F85B48/F986AD  dc f5   cp IY,IX
	jrl z, MsgQueue_Send__no_node                ; F85B4A/F986AF  76 39 00   jrl Z,0xf986eb
	m_ld_mi16 MDD+r7, 0x14, 0x0000               ; F85B4D/F986B2  bf 14 02 00 00   ld (XSP+0x14),0x0000
	extz XIX                                     ; F85B52/F986B7  ec 12   extz XIX
	extz XWA                                     ; F85B54/F986B9  e8 12   extz XWA
	extz XHL                                     ; F85B56/F986BB  eb 12   extz XHL
	m_ld_rm MWD+r4, 0x00, r0                     ; F85B58/F986BD  9c 00 20   ld WA,(XIX+0x00)
	ld HL,(XIX+0x02)                             ; F85B5B/F986C0  9c 02 23   ld HL,(XIX+0x02)
	m_st_mr16 MDD+r3, 0x00, r0                   ; F85B5E/F986C3  bb 00 50   ld (XHL+0x00),WA
	ld (XWA+0x02),HL                             ; F85B61/F986C6  b8 02 53   ld (XWA+0x02),HL
	ld (XIX+0x04),XIZ                            ; F85B64/F986C9  bc 04 66   ld (XIX+0x04),XIZ
	extz BC                                      ; F85B67/F986CC  d9 12   extz BC
	add BC,KERNEL_MSGQ_HEADS-4                   ; F85B69/F986CE  a=d9 c8 70 03 c=d9 c8 44 01   c: add BC,0x0144
	ld IY,BC                                     ; F85B6D/F986D2  d9 8d   ld IY,BC
	extz XIX                                     ; F85B6F/F986D4  ec 12   extz XIX
	extz XIY                                     ; F85B71/F986D6  ed 12   extz XIY
	extz XWA                                     ; F85B73/F986D8  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F85B75/F986DA  bc 00 55   ld (XIX+0x00),IY
	ld WA,(XIY+0x02)                             ; F85B78/F986DD  9d 02 20   ld WA,(XIY+0x02)
	ld (XIX+0x02),WA                             ; F85B7B/F986E0  bc 02 50   ld (XIX+0x02),WA
	ld (XWA),IX                                  ; F85B7E/F986E3  b0 54   ld (XWA),IX
	ld (XIY+0x02),IX                             ; F85B80/F986E5  bd 02 54   ld (XIY+0x02),IX
	jrl Kernel_ResumeTask                        ; F85B83/F986E8  78 dd fb   jrl T,0xf982c8
MsgQueue_Send__no_node:
.LF85B86:   ; <- prom_a's name for this address.
	m_ld_mi16 MDD+r7, 0x14, 0xffff               ; F85B86/F986EB  bf 14 02 ff ff   ld (XSP+0x14),0xffff
	jrl Kernel_ResumeTask                        ; F85B8B/F986F0  78 d5 fb   jrl T,0xf982c8
MsgQueue_Send__wake:
.LF85B8E:   ; <- prom_a's name for this address.
	m_ld_mi16 MDD+r7, 0x14, 0x0000               ; F85B8E/F986F3  bf 14 02 00 00   ld (XSP+0x14),0x0000
	extz XIX                                     ; F85B93/F986F8  ec 12   extz XIX
	extz XWA                                     ; F85B95/F986FA  e8 12   extz XWA
	extz XHL                                     ; F85B97/F986FC  eb 12   extz XHL
	m_ld_rm MWD+r4, 0x00, r0                     ; F85B99/F986FE  9c 00 20   ld WA,(XIX+0x00)
	ld HL,(XIX+0x02)                             ; F85B9C/F98701  9c 02 23   ld HL,(XIX+0x02)
	m_st_mr16 MDD+r3, 0x00, r0                   ; F85B9F/F98704  bb 00 50   ld (XHL+0x00),WA
	ld (XWA+0x02),HL                             ; F85BA2/F98707  b8 02 53   ld (XWA+0x02),HL
	ld (XIX+0x09),0x04                           ; F85BA5/F9870A  bc 09 00 04   ld (XIX+0x09),0x04
	ld XWA,(XIX+0x04)                            ; F85BA9/F9870E  ac 04 20   ld XWA,(XIX+0x04)
	ld (XWA+0x04),XIZ                            ; F85BAC/F98711  b8 04 66   ld (XWA+0x04),XIZ
	ld A,(XIX+0x08)                              ; F85BAF/F98714  8c 08 21   ld A,(XIX+0x08)
	sll a, 0x02                                  ; F85BB2/F98717  c9 ee 02   sll 0x02,A
	extz WA                                      ; F85BB5/F9871A  d8 12   extz WA
	add WA,KERNEL_READY_HEADS-4                  ; F85BB7/F9871C  a=d8 c8 2c 03 c=d8 c8 20 01   c: add WA,0x0120
	ld IY,WA                                     ; F85BBB/F98720  d8 8d   ld IY,WA
	extz XIX                                     ; F85BBD/F98722  ec 12   extz XIX
	extz XIY                                     ; F85BBF/F98724  ed 12   extz XIY
	extz XWA                                     ; F85BC1/F98726  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F85BC3/F98728  bc 00 55   ld (XIX+0x00),IY
	ld WA,(XIY+0x02)                             ; F85BC6/F9872B  9d 02 20   ld WA,(XIY+0x02)
	ld (XIX+0x02),WA                             ; F85BC9/F9872E  bc 02 50   ld (XIX+0x02),WA
	ld (XWA),IX                                  ; F85BCC/F98731  b0 54   ld (XWA),IX
	ld (XIY+0x02),IX                             ; F85BCE/F98733  bd 02 54   ld (XIY+0x02),IX
	jrl Kernel_Dispatch                          ; F85BD1/F98736  78 41 fb   jrl T,0xf9827a

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; MsgQueue_Send_NoDispatch -- the same post, returning instead of rescheduling.
;
; Called from: ⚠ no site found in prom_c.
; Inputs:  A = queue number; XIZ = payload.
; Outputs: the same three arms; ⚠ SEE BELOW for where the status goes.
; Evidence: the same wait queue, free list and message queue, the same four-store
;          append; the wrapper is five pushes (XWA, XIX, XIY, XHL, BC) with
;          `push SR / ei 6` deferred, and a `pop SR / ... / ret` exit.
;          prom_a's 0xF85BD4 is the same 80 instructions with 7 operand
;          differences and 0 structural ones.
; ⚠ THE STATUS STORE IS TWO BYTES LOW, AND IT IS LIKE THAT IN BOTH IMAGES.  This
;          variant writes its 0x0000 / 0xFFFF to (XSP+0x0E).  Its frame is
;          4+4+4+4+2 = 18 bytes of registers plus the 2-byte `push SR`, so the
;          saved XWA is at (XSP+0x10) and (XSP+0x0E) is the HIGH half of the saved
;          XIX -- and 2 is exactly the width of the SR push this variant defers.
;          The blocking version, whose SR push is NOT deferred, stores at
;          (XSP+0x14), which in its 30-byte frame IS the saved XWA.  Recorded as
;          observed: the byte widths are MAME's (op_PUSHLR 4, op_PUSHWR 2,
;          op_PUSHBI 1, 900tbl.hxx:2935-2977), the frame is this listing, and the
;          routine diff shows prom_a's copy is structurally identical, so this is
;          not a transcription error here.  The wake arm stores no status at all.
;          What, if anything, reads the result is unknown -- no caller was found.
; --------------------------------------------------------------------------

MsgQueue_Send_NoDispatch:
sub_F85BD4:   ; <- prom_a's name for this address.  entry: prom_b routine directory
	push XWA                                     ; F85BD4/F98739  38   push XWA
	push XIX                                     ; F85BD5/F9873A  3c   push XIX
	push XIY                                     ; F85BD6/F9873B  3d   push XIY
	push XHL                                     ; F85BD7/F9873C  3b   push XHL
	pushw bc                                     ; F85BD8/F9873D  29   push BC
	sll a, 0x02                                  ; F85BD9/F9873E  c9 ee 02   sll 0x02,A
	ld C,A                                       ; F85BDC/F98741  c9 8b   ld C,A
	extz WA                                      ; F85BDE/F98743  d8 12   extz WA
	add WA,KERNEL_MSGQ_WAITQ-4                   ; F85BE0/F98745  a=d8 c8 60 03 c=d8 c8 3c 01   c: add WA,0x013c
	ld IY,WA                                     ; F85BE4/F98749  d8 8d   ld IY,WA
	extz XIY                                     ; F85BE6/F9874B  ed 12   extz XIY
	push SR                                      ; F85BE8/F9874D  02   push SR
	ei 0x06                                      ; F85BE9/F9874E  06 06   ei 0x06
	m_ld_rm MWD+r5, 0x00, r4                     ; F85BEB/F98750  9d 00 24   ld IX,(XIY+0x00)
	cp IX,IY                                     ; F85BEE/F98753  dd f4   cp IX,IY
	jr nz, MsgQueue_Send_NoDispatch__wake        ; F85BF0/F98755  6e 52   jr NZ,0xf987a9
	ld ix, (KERNEL_FREE_LIST:16)               ; F85BF2/F98757  a=d1 c4 03 24 c=d1 70 01 24   c: ld IX,(0x0170)
	extz XIX                                     ; F85BF6/F9875B  ec 12   extz XIX
	m_ld_rm MWD+r4, 0x00, r5                     ; F85BF8/F9875D  9c 00 25   ld IY,(XIX+0x00)
	cp IY,IX                                     ; F85BFB/F98760  dc f5   cp IY,IX
	jrl z, MsgQueue_Send_NoDispatch__no_node     ; F85BFD/F98762  76 3d 00   jrl Z,0xf987a2
	m_ld_mi16 MDD+r7, 0x0e, 0x0000               ; F85C00/F98765  bf 0e 02 00 00   ld (XSP+0x0e),0x0000
	extz XIX                                     ; F85C05/F9876A  ec 12   extz XIX
	extz XWA                                     ; F85C07/F9876C  e8 12   extz XWA
	extz XHL                                     ; F85C09/F9876E  eb 12   extz XHL
	m_ld_rm MWD+r4, 0x00, r0                     ; F85C0B/F98770  9c 00 20   ld WA,(XIX+0x00)
	ld HL,(XIX+0x02)                             ; F85C0E/F98773  9c 02 23   ld HL,(XIX+0x02)
	m_st_mr16 MDD+r3, 0x00, r0                   ; F85C11/F98776  bb 00 50   ld (XHL+0x00),WA
	ld (XWA+0x02),HL                             ; F85C14/F98779  b8 02 53   ld (XWA+0x02),HL
	ld (XIX+0x04),XIZ                            ; F85C17/F9877C  bc 04 66   ld (XIX+0x04),XIZ
	extz BC                                      ; F85C1A/F9877F  d9 12   extz BC
	add BC,KERNEL_MSGQ_HEADS-4                   ; F85C1C/F98781  a=d9 c8 70 03 c=d9 c8 44 01   c: add BC,0x0144
	ld IY,BC                                     ; F85C20/F98785  d9 8d   ld IY,BC
	extz XIX                                     ; F85C22/F98787  ec 12   extz XIX
	extz XIY                                     ; F85C24/F98789  ed 12   extz XIY
	extz XWA                                     ; F85C26/F9878B  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F85C28/F9878D  bc 00 55   ld (XIX+0x00),IY
	ld WA,(XIY+0x02)                             ; F85C2B/F98790  9d 02 20   ld WA,(XIY+0x02)
	ld (XIX+0x02),WA                             ; F85C2E/F98793  bc 02 50   ld (XIX+0x02),WA
	ld (XWA),IX                                  ; F85C31/F98796  b0 54   ld (XWA),IX
	ld (XIY+0x02),IX                             ; F85C33/F98798  bd 02 54   ld (XIY+0x02),IX
MsgQueue_Send_NoDispatch__ret:
	pop SR                                       ; F85C36/F9879B  03   pop SR
	popw bc                                      ; F85C37/F9879C  49   pop BC
	pop XHL                                      ; F85C38/F9879D  5b   pop XHL
	pop XIY                                      ; F85C39/F9879E  5d   pop XIY
	pop XIX                                      ; F85C3A/F9879F  5c   pop XIX
	pop XWA                                      ; F85C3B/F987A0  58   pop XWA
	ret                                          ; F85C3C/F987A1  0e   ret
MsgQueue_Send_NoDispatch__no_node:
	extpfx5 0xBF, 0x0E, 0x02, 0xFF, 0xFF         ; F85C3D/F987A2  bf 0e 02 ff ff   ld (XSP+0x0e),0xffff
	jr MsgQueue_Send_NoDispatch__ret             ; F85C42/F987A7  68 f2   jr T,0xf9879b
MsgQueue_Send_NoDispatch__wake:
sub_F85C44:   ; <- prom_a's name for this address.  entry: reachable-run entry
	extz XIX                                     ; F85C44/F987A9  ec 12   extz XIX
	extz XWA                                     ; F85C46/F987AB  e8 12   extz XWA
	extz XHL                                     ; F85C48/F987AD  eb 12   extz XHL
	m_ld_rm MWD+r4, 0x00, r0                     ; F85C4A/F987AF  9c 00 20   ld WA,(XIX+0x00)
	ld HL,(XIX+0x02)                             ; F85C4D/F987B2  9c 02 23   ld HL,(XIX+0x02)
	m_st_mr16 MDD+r3, 0x00, r0                   ; F85C50/F987B5  bb 00 50   ld (XHL+0x00),WA
	ld (XWA+0x02),HL                             ; F85C53/F987B8  b8 02 53   ld (XWA+0x02),HL
	ld (XIX+0x09),0x04                           ; F85C56/F987BB  bc 09 00 04   ld (XIX+0x09),0x04
	ld XWA,(XIX+0x04)                            ; F85C5A/F987BF  ac 04 20   ld XWA,(XIX+0x04)
	ld (XWA+0x04),XIZ                            ; F85C5D/F987C2  b8 04 66   ld (XWA+0x04),XIZ
	ld A,(XIX+0x08)                              ; F85C60/F987C5  8c 08 21   ld A,(XIX+0x08)
	sll a, 0x02                                  ; F85C63/F987C8  c9 ee 02   sll 0x02,A
	extz WA                                      ; F85C66/F987CB  d8 12   extz WA
	add WA,KERNEL_READY_HEADS-4                  ; F85C68/F987CD  a=d8 c8 2c 03 c=d8 c8 20 01   c: add WA,0x0120
	ld IY,WA                                     ; F85C6C/F987D1  d8 8d   ld IY,WA
	extz XIX                                     ; F85C6E/F987D3  ec 12   extz XIX
	extz XIY                                     ; F85C70/F987D5  ed 12   extz XIY
	extz XWA                                     ; F85C72/F987D7  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F85C74/F987D9  bc 00 55   ld (XIX+0x00),IY
	ld WA,(XIY+0x02)                             ; F85C77/F987DC  9d 02 20   ld WA,(XIY+0x02)
	ld (XIX+0x02),WA                             ; F85C7A/F987DF  bc 02 50   ld (XIX+0x02),WA
	ld (XWA),IX                                  ; F85C7D/F987E2  b0 54   ld (XWA),IX
	ld (XIY+0x02),IX                             ; F85C7F/F987E4  bd 02 54   ld (XIY+0x02),IX
	pop SR                                       ; F85C82/F987E7  03   pop SR
	popw bc                                      ; F85C83/F987E8  49   pop BC
	pop XHL                                      ; F85C84/F987E9  5b   pop XHL
	pop XIY                                      ; F85C85/F987EA  5d   pop XIY
	pop XIX                                      ; F85C86/F987EB  5c   pop XIX
	pop XWA                                      ; F85C87/F987EC  58   pop XWA
	ret                                          ; F85C88/F987ED  0e   ret

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ==============================================================================
; 0xF85C89-0xF85D1B -- the blocking message receive DSP_RefreshTask waits on
; ==============================================================================
;
; This is the routine DSP_RefreshTask (0xF85EC8, converted below) calls once per
; pass with the argument 1.  It is the first kernel IPC primitive in this file
; and it fixes three RAM layouts at once, so the whole map is set out here:
;
;   0x032C + n*4   ready queues; n = 1,2,3 are the three heads Kernel_Dispatch
;                  scans (see the 0xF85877 block above)
;   0x0360 + n*4   the WAIT queue of message queue n -- where a task parks when
;                  the queue is empty
;   0x0370 + n*4   the MESSAGE queue itself
;   0x03C4         the free-node list; a consumed node is returned here
;   0x03C8         the two software timers (Kernel_ServiceSoftTimers, converted)
;   (0xBF)         LE16 pointer to the current task's node.  Kernel_Dispatch
;                  writes it at 0xF8575B and clears it at 0xF85732; this routine
;                  reads it at 0xF85CE6 -- which is what says a node IS a task
;                  control block, since the same +0/+2 links serve both.
;
; NODE LAYOUT, as used here:  +0 next, +2 prev, +4 LE32 payload, +9 BYTE state.
; The payload slot is cleared to 0xFFFFFFFF as the node is recycled, the same
; "empty" marker Kernel_ServiceSoftTimers uses for an unused timer slot
; (0xF85780, converted above).

; ---------------------------------------------------------------------
; MsgQueue_ReceiveBlocking -- take the next message from queue A, or block
;
; Called from: DSP_RefreshTask (0xF85ED1) with A = 1; and prom_b thunk 0xF42DCC
;          (notes/prom_a_xref.py 0xF85C89).
; Inputs:  (XSP+0x04) = the queue number A.  Caller-cleaned (`inc 2,XSP`).
; Outputs: the 32-bit payload written back over the argument at (XSP+0x04), and
;          control returned through Kernel_ResumeTask.  If the queue is empty the
;          caller does not come back until someone posts: its node is taken off
;          whatever list it is on, marked state 3, put on 0x0360 + A*4, and
;          Kernel_Dispatch runs.
; Evidence: 1. the seven pushes plus `push SR` are again Kernel_ResumeTask's
;             frame, and BOTH exits are `jrl` -- to Kernel_ResumeTask on the
;             success path (0xF85CE3) and to Kernel_Dispatch on the empty path
;             (0xF85D19).  A routine whose two exits are "resume me" and "pick
;             someone else" is a blocking receive;
;          2. the emptiness test here is `cp IX,IY`, head->next against the head
;             itself -- the zero-element test, not the zero-or-one test the
;             rotate primitives use.  Two different tests for two different jobs,
;             in code that is otherwise identical, is why the readings are not
;             interchangeable;
;          3. the node is not freed to a heap: it is unlinked from the message
;             queue and linked onto 0x03C4 with the same twelve instructions, and
;             its payload word is set to 0xFFFFFFFF on the way past;
;          4. the result is returned by overwriting the incoming argument slot,
;             `ld (XSP+0x04),XIZ` -- which is why the caller's `inc 2,XSP` at
;             0xF85ED5 is followed by reading XIY rather than a register.
; Unknown:  ⚠ what state 3 means beyond "waiting on a message queue"; the only
;          other value seen is the 0 written at 0xF85E7F by an unconverted
;          routine, and nothing that READS +9 has been converted.  Who posts to
;          queue 1 is likewise not traced.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; MsgQueue_ReceiveBlocking_StackArg / MsgQueue_ReceiveBlocking -- take a message
; from queue A, blocking until there is one.
;
; Called from: ⚠ no site found in prom_c for either entry.
; Inputs:  A = queue number 1..2.
; Outputs: the payload in XIY; the consumed node returned to the free list with
;          its +4 reset to 0xFFFFFFFF.
; Evidence: it reads the MESSAGE queue at 0x0144 + A*4 first.  Non-empty: unlink
;          the node, XIZ := node+4, node+4 := 0xFFFFFFFF, append the node to the
;          free list at 0x0170, and write XIZ into (XSP+0x04) -- the XIY slot of
;          this routine's own frame, which Kernel_ResumeTask pops.  Empty: unlink
;          the running task from (0x0091), +9 := 3, append it to the WAIT queue at
;          0x013C + A*4 and enter Kernel_Dispatch -- the exact queue MsgQueue_Send
;          looks in first, which is what ties the two halves together.
;          prom_a's MsgQueue_ReceiveBlocking (0xF85C8C) is the same 59
;          instructions with 7 operand differences and 0 structural ones.
; --------------------------------------------------------------------------

MsgQueue_ReceiveBlocking_StackArg:
	ld A,(XSP+0x04)                              ; F85C89/F987EE  8f 04 21   ld A,(XSP+0x04)   A = the queue number

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; MsgQueue_ReceiveBlocking -- the register-argument face; A = the queue number.
; Called from: ⚠ no site found in prom_c (prom_c_xrefs.py 0xF987F1: zero).
; Evidence: it is the same routine as the stack face immediately above -- that
;          face's only instruction(s) load the argument(s) from the stack and
;          fall through to this label.  Body, evidence and unknowns are in the
;          block above.
; --------------------------------------------------------------------------

MsgQueue_ReceiveBlocking:
	push SR                                      ; F85C8C/F987F1  02   push SR
	ei 0x06                                      ; F85C8D/F987F2  06 06   ei 0x06
	push XHL                                     ; F85C8F/F987F4  3b   push XHL
	push XWA                                     ; F85C90/F987F5  38   push XWA
	push XBC                                     ; F85C91/F987F6  39   push XBC
	push XDE                                     ; F85C92/F987F7  3a   push XDE
	push XIX                                     ; F85C93/F987F8  3c   push XIX
	push XIY                                     ; F85C94/F987F9  3d   push XIY
	push XIZ                                     ; F85C95/F987FA  3e   push XIZ
	sll a, 0x02                                  ; F85C96/F987FB  c9 ee 02   sll 0x02,A
	extz WA                                      ; F85C99/F987FE  d8 12   extz WA
	ld DE,WA                                     ; F85C9B/F98800  d8 8a   ld DE,WA   keep A*4 for the wait queue below
	add WA,KERNEL_MSGQ_HEADS-4                   ; F85C9D/F98802  a=d8 c8 70 03 c=d8 c8 44 01   c: add WA,0x0144   the message queue
	ld IY,WA                                     ; F85CA1/F98806  d8 8d   ld IY,WA
	extz XIY                                     ; F85CA3/F98808  ed 12   extz XIY
	m_ld_rm MWD+r5, 0x00, r4                     ; F85CA5/F9880A  9d 00 24   ld IX,(XIY+0x00)   IX = head->next
	cp IX,IY                                     ; F85CA8/F9880D  dd f4   cp IX,IY   == head? then the queue is EMPTY
	jr z, MsgQueue_ReceiveBlocking__block        ; F85CAA/F9880F  66 3a   jr Z,0xf9884b
	extz XIX                                     ; F85CAC/F98811  ec 12   extz XIX
	extz XWA                                     ; F85CAE/F98813  e8 12   extz XWA
	extz XHL                                     ; F85CB0/F98815  eb 12   extz XHL
	m_ld_rm MWD+r4, 0x00, r0                     ; F85CB2/F98817  9c 00 20   ld WA,(XIX+0x00)   unlink the node
	ld HL,(XIX+0x02)                             ; F85CB5/F9881A  9c 02 23   ld HL,(XIX+0x02)
	m_st_mr16 MDD+r3, 0x00, r0                   ; F85CB8/F9881D  bb 00 50   ld (XHL+0x00),WA
	ld (XWA+0x02),HL                             ; F85CBB/F98820  b8 02 53   ld (XWA+0x02),HL
	ld XIZ,(XIX+0x04)                            ; F85CBE/F98823  ac 04 26   ld XIZ,(XIX+0x04)   XIZ = the payload
	ld XBC,0xffffffff                            ; F85CC1/F98826  41 ff ff ff ff   ld XBC,0xffffffff
	ld (XIX+0x04),XBC                            ; F85CC6/F9882B  bc 04 61   ld (XIX+0x04),XBC   mark the node empty
	ldw iy, KERNEL_FREE_LIST                     ; F85CC9/F9882E  a=35 c4 03 c=35 70 01   c: ld IY,0x0170   the free list
	extz XIX                                     ; F85CCC/F98831  ec 12   extz XIX
	extz XIY                                     ; F85CCE/F98833  ed 12   extz XIY
	extz XWA                                     ; F85CD0/F98835  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F85CD2/F98837  bc 00 55   ld (XIX+0x00),IY   recycle it at the tail
	ld WA,(XIY+0x02)                             ; F85CD5/F9883A  9d 02 20   ld WA,(XIY+0x02)
	ld (XIX+0x02),WA                             ; F85CD8/F9883D  bc 02 50   ld (XIX+0x02),WA
	ld (XWA),IX                                  ; F85CDB/F98840  b0 54   ld (XWA),IX
	ld (XIY+0x02),IX                             ; F85CDD/F98842  bd 02 54   ld (XIY+0x02),IX
	ld (XSP+0x04),XIZ                            ; F85CE0/F98845  bf 04 66   ld (XSP+0x04),XIZ   the payload IS the return value
	jrl Kernel_ResumeTask                        ; F85CE3/F98848  78 7d fa   jrl T,0xf982c8
MsgQueue_ReceiveBlocking__block:
	m_ld_rm MW8, KERNEL_CURRENT_TASK, r4         ; F85CE6/F9884B  a=d0 bf 24 c=d0 91 24   c: ld IX,(0x91)   IX = the CURRENT task's node
	extz XIX                                     ; F85CE9/F9884E  ec 12   extz XIX
	extz XWA                                     ; F85CEB/F98850  e8 12   extz XWA
	extz XHL                                     ; F85CED/F98852  eb 12   extz XHL
	m_ld_rm MWD+r4, 0x00, r0                     ; F85CEF/F98854  9c 00 20   ld WA,(XIX+0x00)   take it off its ready queue
	ld HL,(XIX+0x02)                             ; F85CF2/F98857  9c 02 23   ld HL,(XIX+0x02)
	m_st_mr16 MDD+r3, 0x00, r0                   ; F85CF5/F9885A  bb 00 50   ld (XHL+0x00),WA
	ld (XWA+0x02),HL                             ; F85CF8/F9885D  b8 02 53   ld (XWA+0x02),HL
	ld (XIX+0x09),0x03                           ; F85CFB/F98860  bc 09 00 03   ld (XIX+0x09),0x03   state 3 = waiting on a message queue
	add DE,KERNEL_MSGQ_WAITQ-4                   ; F85CFF/F98864  a=da c8 60 03 c=da c8 3c 01   c: add DE,0x013c   the wait queue of the SAME index
	ld IY,DE                                     ; F85D03/F98868  da 8d   ld IY,DE
	extz XIX                                     ; F85D05/F9886A  ec 12   extz XIX
	extz XIY                                     ; F85D07/F9886C  ed 12   extz XIY
	extz XWA                                     ; F85D09/F9886E  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F85D0B/F98870  bc 00 55   ld (XIX+0x00),IY   park it there, at the tail
	ld WA,(XIY+0x02)                             ; F85D0E/F98873  9d 02 20   ld WA,(XIY+0x02)
	ld (XIX+0x02),WA                             ; F85D11/F98876  bc 02 50   ld (XIX+0x02),WA
	ld (XWA),IX                                  ; F85D14/F98879  b0 54   ld (XWA),IX
	ld (XIY+0x02),IX                             ; F85D16/F9887B  bd 02 54   ld (XIY+0x02),IX
	jrl Kernel_Dispatch                          ; F85D19/F9887E  78 f9 f9   jrl T,0xf9827a   run somebody else

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>>>>
; ==============================================================================
; 0xF85D1C-0xF85E89 -- CONVERTED.  This banner said "not yet converted" and sat
; directly above converted code; corrected 2026-08-30 when the kernel became one
; shared source.  Same failure and same wording as the 0xF85904-0xF85C88 banner
; two screens up, which wave 5 round 2 corrected for the same reason.
; notes/prom_a_byte_checks.py fails if a "not yet converted" banner has no
; `.incbin` under it, and this one had none -- it was the "0 of 1" that check has
; been reporting.
; ==============================================================================
; ==== 0xF85D1C-0xF85E8A -- REACHABLE CODE ONLY, emitted by notes/gen_prom_a_cover_round1.py ====
; 1 reachable run(s), 366 bytes framed as code.  0 bytes that nothing reaches stay
; `.incbin` -- this round converts REACHABLE CODE, not territory.
; Boundaries: notes/reachability.py's walk, frozen against this file's own output.
; Labels are sub_XXXXXX by design: this round is COVERAGE, naming is a later goal.
; This text was assembled and byte-compared with the ROM before printing.

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; MsgQueue_Receive_NoBlock -- take a message from queue A if there is one.
;
; Called from: ⚠ no site found in prom_c.
; Inputs:  (XSP+4) = queue number.
; Outputs: XIY = the payload, or 0 if the queue was empty.  Never blocks.
; Evidence: same message queue, same recycle-to-free-list; the empty arm is `xor
;          XIY,XIY` instead of parking the caller, and the routine ends in `pop
;          SR / ... / ret`.  That XIY carries the result is stated twice over: the
;          non-empty arm ends `ld XIY,XIZ` and the empty arm zeroes XIY, both
;          after the pops that would otherwise clobber it.
;          prom_a's 0xF85D1C is the same 41 instructions with 4 operand
;          differences and 0 structural ones.
; --------------------------------------------------------------------------

MsgQueue_Receive_NoBlock:
sub_F85D1C:   ; <- prom_a's name for this address.  entry: prom_b routine directory
	ld A,(XSP+0x04)                              ; F85D1C/F98881  8f 04 21   ld A,(XSP+0x04)
	push XHL                                     ; F85D1F/F98884  3b   push XHL
	push XIX                                     ; F85D20/F98885  3c   push XIX
	push XIZ                                     ; F85D21/F98886  3e   push XIZ
	sll a, 0x02                                  ; F85D22/F98887  c9 ee 02   sll 0x02,A
	extz WA                                      ; F85D25/F9888A  d8 12   extz WA
	add WA,KERNEL_MSGQ_HEADS-4                   ; F85D27/F9888C  a=d8 c8 70 03 c=d8 c8 44 01   c: add WA,0x0144
	ld IY,WA                                     ; F85D2B/F98890  d8 8d   ld IY,WA
	push SR                                      ; F85D2D/F98892  02   push SR
	ei 0x06                                      ; F85D2E/F98893  06 06   ei 0x06
	extz XIY                                     ; F85D30/F98895  ed 12   extz XIY
	m_ld_rm MWD+r5, 0x00, r4                     ; F85D32/F98897  9d 00 24   ld IX,(XIY+0x00)
	cp IX,IY                                     ; F85D35/F9889A  dd f4   cp IX,IY
	jr z, MsgQueue_Receive_NoBlock__empty        ; F85D37/F9889C  66 38   jr Z,0xf988d6
	extz XIX                                     ; F85D39/F9889E  ec 12   extz XIX
	extz XWA                                     ; F85D3B/F988A0  e8 12   extz XWA
	extz XHL                                     ; F85D3D/F988A2  eb 12   extz XHL
	m_ld_rm MWD+r4, 0x00, r0                     ; F85D3F/F988A4  9c 00 20   ld WA,(XIX+0x00)
	ld HL,(XIX+0x02)                             ; F85D42/F988A7  9c 02 23   ld HL,(XIX+0x02)
	m_st_mr16 MDD+r3, 0x00, r0                   ; F85D45/F988AA  bb 00 50   ld (XHL+0x00),WA
	ld (XWA+0x02),HL                             ; F85D48/F988AD  b8 02 53   ld (XWA+0x02),HL
	ld XIZ,(XIX+0x04)                            ; F85D4B/F988B0  ac 04 26   ld XIZ,(XIX+0x04)
	ld XWA,0xffffffff                            ; F85D4E/F988B3  40 ff ff ff ff   ld XWA,0xffffffff
	ld (XIX+0x04),XWA                            ; F85D53/F988B8  bc 04 60   ld (XIX+0x04),XWA
	ldw iy, KERNEL_FREE_LIST                     ; F85D56/F988BB  a=35 c4 03 c=35 70 01   c: ld IY,0x0170
	extz XIX                                     ; F85D59/F988BE  ec 12   extz XIX
	extz XIY                                     ; F85D5B/F988C0  ed 12   extz XIY
	extz XWA                                     ; F85D5D/F988C2  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F85D5F/F988C4  bc 00 55   ld (XIX+0x00),IY
	ld WA,(XIY+0x02)                             ; F85D62/F988C7  9d 02 20   ld WA,(XIY+0x02)
	ld (XIX+0x02),WA                             ; F85D65/F988CA  bc 02 50   ld (XIX+0x02),WA
	ld (XWA),IX                                  ; F85D68/F988CD  b0 54   ld (XWA),IX
	ld (XIY+0x02),IX                             ; F85D6A/F988CF  bd 02 54   ld (XIY+0x02),IX
	ld XIY,XIZ                                   ; F85D6D/F988D2  ee 8d   ld XIY,XIZ
	jr MsgQueue_Receive_NoBlock__ret             ; F85D6F/F988D4  68 02   jr T,0xf988d8
MsgQueue_Receive_NoBlock__empty:
.LF85D71:   ; <- prom_a's name for this address.
	xor XIY,XIY                                  ; F85D71/F988D6  ed d5   xor XIY,XIY
MsgQueue_Receive_NoBlock__ret:
.LF85D73:   ; <- prom_a's name for this address.
	pop SR                                       ; F85D73/F988D8  03   pop SR
	pop XIZ                                      ; F85D74/F988D9  5e   pop XIZ
	pop XIX                                      ; F85D75/F988DA  5c   pop XIX
	pop XHL                                      ; F85D76/F988DB  5b   pop XHL
	ret                                          ; F85D77/F988DC  0e   ret

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; SoftTimer_Register -- install a software-timer request into slot n.
;
; Called from: Kernel_InitRam__install, `call 0xF988DD` at 0xF9824D.  One site.
; Inputs:  XIX = a request block: +0 slot number (read as a byte), +2 the initial
;          value, +4 the callback address.
; Outputs: slot 0x016C + n*8 (= 0x0174 + (n-1)*8) gets +0 = +2 = request+2 and
;          +4 = request+4; then `jrl Kernel_Dispatch`.
; Evidence: `ld A,(XIX+0x00) / mul A,0x08 / add WA,0x016C` is the slot address
;          with the kernel's usual one-element bias, and 0x016C + 1*8 = 0x0174,
;          the array Kernel_InitRam built.  The SAME word from the request is
;          written into both slot+0 and slot+2 -- countdown and reload -- which is
;          what makes a periodic timer.  With the boot request that is 1 and 1:
;          the callback fires on every kernel tick.
;          prom_a's 0xF85D78 is the same 20 instructions with 2 operand
;          differences and 0 structural ones.
; Unknown:  nothing in this image ever registers a SECOND timer, so slot 2 stays
;          0xFFFFFFFF for the whole run.
; --------------------------------------------------------------------------

SoftTimer_Register:
sub_F85D78:   ; <- prom_a's name for this address.  entry: branch/call in converted code
	push SR                                      ; F85D78/F988DD  02   push SR
	ei 0x06                                      ; F85D79/F988DE  06 06   ei 0x06
	push XHL                                     ; F85D7B/F988E0  3b   push XHL
	push XWA                                     ; F85D7C/F988E1  38   push XWA
	push XBC                                     ; F85D7D/F988E2  39   push XBC
	push XDE                                     ; F85D7E/F988E3  3a   push XDE
	push XIX                                     ; F85D7F/F988E4  3c   push XIX
	push XIY                                     ; F85D80/F988E5  3d   push XIY
	push XIZ                                     ; F85D81/F988E6  3e   push XIZ
	m_ld_rm MBD+r4, 0x00, r1                     ; F85D82/F988E7  8c 00 21   ld A,(XIX+0x00)
	mul A,0x08                                   ; F85D85/F988EA  c9 08 08   mul A,0x08
	add WA,KERNEL_TIMERS-8                       ; F85D88/F988ED  a=d8 c8 c0 03 c=d8 c8 6c 01   c: add WA,0x016c
	ld IY,WA                                     ; F85D8C/F988F1  d8 8d   ld IY,WA
	extz XIY                                     ; F85D8E/F988F3  ed 12   extz XIY
	ld WA,(XIX+0x02)                             ; F85D90/F988F5  9c 02 20   ld WA,(XIX+0x02)
	m_st_mr16 MDD+r5, 0x00, r0                   ; F85D93/F988F8  bd 00 50   ld (XIY+0x00),WA
	ld (XIY+0x02),WA                             ; F85D96/F988FB  bd 02 50   ld (XIY+0x02),WA
	ld XWA,(XIX+0x04)                            ; F85D99/F988FE  ac 04 20   ld XWA,(XIX+0x04)
	ld (XIY+0x04),XWA                            ; F85D9C/F98901  bd 04 60   ld (XIY+0x04),XWA
	jrl Kernel_Dispatch                          ; F85D9F/F98904  78 73 f9   jrl T,0xf9827a

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_SetTaskLevel_StackArg / Kernel_SetTaskLevel -- move task A to priority
; level W, then reschedule.
;
; Called from: ⚠ no site found in prom_c for either entry.
; Inputs:  A = task number, W = new level.  The stack face reads them from
;          (XSP+0x04) and (XSP+0x06) and falls through.
; Outputs: TCB+8 := W always; and if TCB+9 == 4 the block is also unlinked and
;          re-appended to the tail of 0x0120 + W*4.  Leaves through
;          Kernel_Dispatch on the requeue path and through Kernel_ResumeTask
;          otherwise.
; Evidence: TCB+8 is the field Kernel_StartTask fills from EntryPoint_Records+10
;          and the field Kernel_ReadyTask reads to choose a queue, so writing it
;          IS changing the task's level; the guard `cp (XIX+0x09),0x04` is the
;          runnable state, i.e. only a queued task needs moving.  ⚠ The store to
;          TCB+8 appears on BOTH arms, including once inside the requeue path
;          before the queue index is computed.
;          prom_a's 0xF85DA8 is the same 39 instructions with 5 operand
;          differences and 0 structural ones.
; --------------------------------------------------------------------------

Kernel_SetTaskLevel_StackArg:
sub_F85DA2:   ; <- prom_a's name for this address.  entry: prom_b routine directory
	ld A,(XSP+0x04)                              ; F85DA2/F98907  8f 04 21   ld A,(XSP+0x04)
	ld W,(XSP+0x06)                              ; F85DA5/F9890A  8f 06 20   ld W,(XSP+0x06)

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_SetTaskLevel -- the register-argument face; A = the task number, W = the new level.
; Called from: ⚠ no site found in prom_c (prom_c_xrefs.py 0xF9890D: zero).
; Evidence: it is the same routine as the stack face immediately above -- that
;          face's only instruction(s) load the argument(s) from the stack and
;          fall through to this label.  Body, evidence and unknowns are in the
;          block above.
; --------------------------------------------------------------------------

Kernel_SetTaskLevel:
sub_F85DA8:   ; <- prom_a's name for this address.  entry: prom_b routine directory
	push SR                                      ; F85DA8/F9890D  02   push SR
	ei 0x06                                      ; F85DA9/F9890E  06 06   ei 0x06
	push XHL                                     ; F85DAB/F98910  3b   push XHL
	push XWA                                     ; F85DAC/F98911  38   push XWA
	push XBC                                     ; F85DAD/F98912  39   push XBC
	push XDE                                     ; F85DAE/F98913  3a   push XDE
	push XIX                                     ; F85DAF/F98914  3c   push XIX
	push XIY                                     ; F85DB0/F98915  3d   push XIY
	push XIZ                                     ; F85DB1/F98916  3e   push XIZ
	ld E,W                                       ; F85DB2/F98917  c8 8d   ld E,W
	mul A,0x0c                                   ; F85DB4/F98919  c9 08 0c   mul A,0x0c
	add WA,KERNEL_TCB_BASE-12                    ; F85DB7/F9891C  a=d8 c8 f4 02 c=d8 c8 f4 00   c: add WA,0x00f4
	ld IX,WA                                     ; F85DBB/F98920  d8 8c   ld IX,WA
	extz XIX                                     ; F85DBD/F98922  ec 12   extz XIX
	cp (XIX+0x09),0x04                           ; F85DBF/F98924  8c 09 3f 04   cp (XIX+0x09),0x04
	jr nz, Kernel_SetTaskLevel__store_only       ; F85DC3/F98928  6e 37   jr NZ,0xf98961
	extz XIX                                     ; F85DC5/F9892A  ec 12   extz XIX
	extz XWA                                     ; F85DC7/F9892C  e8 12   extz XWA
	extz XHL                                     ; F85DC9/F9892E  eb 12   extz XHL
	m_ld_rm MWD+r4, 0x00, r0                     ; F85DCB/F98930  9c 00 20   ld WA,(XIX+0x00)
	ld HL,(XIX+0x02)                             ; F85DCE/F98933  9c 02 23   ld HL,(XIX+0x02)
	m_st_mr16 MDD+r3, 0x00, r0                   ; F85DD1/F98936  bb 00 50   ld (XHL+0x00),WA
	ld (XWA+0x02),HL                             ; F85DD4/F98939  b8 02 53   ld (XWA+0x02),HL
	ld (XIX+0x08),E                              ; F85DD7/F9893C  bc 08 45   ld (XIX+0x08),E
	sll e, 0x02                                  ; F85DDA/F9893F  cd ee 02   sll 0x02,E
	extz DE                                      ; F85DDD/F98942  da 12   extz DE
	add DE,KERNEL_READY_HEADS-4                  ; F85DDF/F98944  a=da c8 2c 03 c=da c8 20 01   c: add DE,0x0120
	ld IY,DE                                     ; F85DE3/F98948  da 8d   ld IY,DE
	extz XIX                                     ; F85DE5/F9894A  ec 12   extz XIX
	extz XIY                                     ; F85DE7/F9894C  ed 12   extz XIY
	extz XWA                                     ; F85DE9/F9894E  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F85DEB/F98950  bc 00 55   ld (XIX+0x00),IY
	ld WA,(XIY+0x02)                             ; F85DEE/F98953  9d 02 20   ld WA,(XIY+0x02)
	ld (XIX+0x02),WA                             ; F85DF1/F98956  bc 02 50   ld (XIX+0x02),WA
	ld (XWA),IX                                  ; F85DF4/F98959  b0 54   ld (XWA),IX
	ld (XIY+0x02),IX                             ; F85DF6/F9895B  bd 02 54   ld (XIY+0x02),IX
	jrl Kernel_Dispatch                          ; F85DF9/F9895E  78 19 f9   jrl T,0xf9827a
Kernel_SetTaskLevel__store_only:
.LF85DFC:   ; <- prom_a's name for this address.
	ld (XIX+0x08),E                              ; F85DFC/F98961  bc 08 45   ld (XIX+0x08),E
	jrl Kernel_ResumeTask                        ; F85DFF/F98964  78 61 f9   jrl T,0xf982c8

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_SetTaskLevel_NoDispatch -- the same, returning instead of rescheduling.
;
; Called from: ⚠ no site found in prom_c.
; Inputs:  A = task number, W = new level.
; Outputs: as above, minus the reschedule.
; Evidence: same guard, same TCB+8 store, same four-store re-append; five pushes
;          and a `pop SR / ... / ret` epilogue.
;          prom_a's 0xF85E02 is the same 42 instructions with 3 operand
;          differences and 0 structural ones.
; --------------------------------------------------------------------------

Kernel_SetTaskLevel_NoDispatch:
sub_F85E02:   ; <- prom_a's name for this address.  entry: prom_b routine directory
	push XWA                                     ; F85E02/F98967  38   push XWA
	push XIX                                     ; F85E03/F98968  3c   push XIX
	push XIY                                     ; F85E04/F98969  3d   push XIY
	push XHL                                     ; F85E05/F9896A  3b   push XHL
	pushw de                                     ; F85E06/F9896B  2a   push DE
	ld E,W                                       ; F85E07/F9896C  c8 8d   ld E,W
	mul A,0x0c                                   ; F85E09/F9896E  c9 08 0c   mul A,0x0c
	add WA,KERNEL_TCB_BASE-12                    ; F85E0C/F98971  a=d8 c8 f4 02 c=d8 c8 f4 00   c: add WA,0x00f4
	ld IX,WA                                     ; F85E10/F98975  d8 8c   ld IX,WA
	extz XIX                                     ; F85E12/F98977  ec 12   extz XIX
	push SR                                      ; F85E14/F98979  02   push SR
	ei 0x06                                      ; F85E15/F9897A  06 06   ei 0x06
	cp (XIX+0x09),0x04                           ; F85E17/F9897C  8c 09 3f 04   cp (XIX+0x09),0x04
	jr nz, Kernel_SetTaskLevel_NoDispatch__store_only ; F85E1B/F98980  6e 34   jr NZ,0xf989b6
	extz XIX                                     ; F85E1D/F98982  ec 12   extz XIX
	extz XWA                                     ; F85E1F/F98984  e8 12   extz XWA
	extz XHL                                     ; F85E21/F98986  eb 12   extz XHL
	m_ld_rm MWD+r4, 0x00, r0                     ; F85E23/F98988  9c 00 20   ld WA,(XIX+0x00)
	ld HL,(XIX+0x02)                             ; F85E26/F9898B  9c 02 23   ld HL,(XIX+0x02)
	m_st_mr16 MDD+r3, 0x00, r0                   ; F85E29/F9898E  bb 00 50   ld (XHL+0x00),WA
	ld (XWA+0x02),HL                             ; F85E2C/F98991  b8 02 53   ld (XWA+0x02),HL
	ld (XIX+0x08),E                              ; F85E2F/F98994  bc 08 45   ld (XIX+0x08),E
	sll e, 0x02                                  ; F85E32/F98997  cd ee 02   sll 0x02,E
	extz DE                                      ; F85E35/F9899A  da 12   extz DE
	add DE,KERNEL_READY_HEADS-4                  ; F85E37/F9899C  a=da c8 2c 03 c=da c8 20 01   c: add DE,0x0120
	ld IY,DE                                     ; F85E3B/F989A0  da 8d   ld IY,DE
	extz XIX                                     ; F85E3D/F989A2  ec 12   extz XIX
	extz XIY                                     ; F85E3F/F989A4  ed 12   extz XIY
	extz XWA                                     ; F85E41/F989A6  e8 12   extz XWA
	m_st_mr16 MDD+r4, 0x00, r5                   ; F85E43/F989A8  bc 00 55   ld (XIX+0x00),IY
	ld WA,(XIY+0x02)                             ; F85E46/F989AB  9d 02 20   ld WA,(XIY+0x02)
	ld (XIX+0x02),WA                             ; F85E49/F989AE  bc 02 50   ld (XIX+0x02),WA
	ld (XWA),IX                                  ; F85E4C/F989B1  b0 54   ld (XWA),IX
	ld (XIY+0x02),IX                             ; F85E4E/F989B3  bd 02 54   ld (XIY+0x02),IX
Kernel_SetTaskLevel_NoDispatch__store_only:
.LF85E51:   ; <- prom_a's name for this address.
	ld (XIX+0x08),E                              ; F85E51/F989B6  bc 08 45   ld (XIX+0x08),E
	pop SR                                       ; F85E54/F989B9  03   pop SR
	popw de                                      ; F85E55/F989BA  4a   pop DE
	pop XHL                                      ; F85E56/F989BB  5b   pop XHL
	pop XIY                                      ; F85E57/F989BC  5d   pop XIY
	pop XIX                                      ; F85E58/F989BD  5c   pop XIX
	pop XWA                                      ; F85E59/F989BE  58   pop XWA
	ret                                          ; F85E5A/F989BF  0e   ret

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_KillTask_StackArg / Kernel_KillTask -- unlink task A and mark it dead.
;
; Called from: ⚠ no site found in prom_c for either entry.
; Inputs:  A = task number, 1-based.
; Outputs: the block at 0x00F4 + A*12 unlinked from whatever list it is on, and
;          its +9 set to 0.  It does not touch (0x0091), does not switch stacks
;          and does not enter the scheduler; it RETs.
; Evidence: those two effects are exactly Kernel_ExitTask's two effects on the
;          control block, applied to a block chosen by ARGUMENT instead of by
;          (0x0091) -- the same `mul A,0x0c / add WA,0x00F4` index every other
;          task routine here uses, the same `prev->next = next; next->prev = prev`
;          unlink, and the state byte 0 that Kernel_InitRam writes to every block
;          at boot and Kernel_ExitTask writes when a task removes itself.
;          ⚠ "Kill" is that reading of {unlink, state := 0}; nothing in the
;          firmware names it, and prom_a's lane left the same routine (0xF85E5B,
;          the same 23 instructions with 1 operand difference and 0 structural
;          ones) unnamed.  It is named here because Kernel_ExitTask -- the routine
;          it copies -- is converted on both sides, and the pairing is what the
;          name asserts.
; Unknown:  ⚠ killing the RUNNING task this way would leave (0x0091) pointing at a
;          block that is on no list; nothing here guards against that, and no
;          caller was found to say whether it can happen.
; --------------------------------------------------------------------------

Kernel_KillTask_StackArg:
sub_F85E5B:   ; <- prom_a's name for this address.  entry: prom_b routine directory
	ld A,(XSP+0x04)                              ; F85E5B/F989C0  8f 04 21   ld A,(XSP+0x04)

; >>>>>> moved from prom_c/wsa1_prom_c.s -- CPU 2, the SUB processor >>>>>>>>>>>>>>
; --------------------------------------------------------------------------
; Kernel_KillTask -- the register-argument face; A = the task number.
; Called from: ⚠ no site found in prom_c (prom_c_xrefs.py 0xF989C3: zero).
; Evidence: it is the same routine as the stack face immediately above -- that
;          face's only instruction(s) load the argument(s) from the stack and
;          fall through to this label.  Body, evidence and unknowns are in the
;          block above.
; --------------------------------------------------------------------------

Kernel_KillTask:
sub_F85E5E:   ; <- prom_a's name for this address.  entry: prom_b routine directory
	pushw wa                                     ; F85E5E/F989C3  28   push WA
	push XIX                                     ; F85E5F/F989C4  3c   push XIX
	push XIY                                     ; F85E60/F989C5  3d   push XIY
	push XHL                                     ; F85E61/F989C6  3b   push XHL
	ei 0x06                                      ; F85E62/F989C7  06 06   ei 0x06
	mul A,0x0c                                   ; F85E64/F989C9  c9 08 0c   mul A,0x0c
	add WA,KERNEL_TCB_BASE-12                    ; F85E67/F989CC  a=d8 c8 f4 02 c=d8 c8 f4 00   c: add WA,0x00f4
	ld IX,WA                                     ; F85E6B/F989D0  d8 8c   ld IX,WA
	extz XIX                                     ; F85E6D/F989D2  ec 12   extz XIX
	extz XWA                                     ; F85E6F/F989D4  e8 12   extz XWA
	extz XHL                                     ; F85E71/F989D6  eb 12   extz XHL
	m_ld_rm MWD+r4, 0x00, r0                     ; F85E73/F989D8  9c 00 20   ld WA,(XIX+0x00)
	ld HL,(XIX+0x02)                             ; F85E76/F989DB  9c 02 23   ld HL,(XIX+0x02)
	m_st_mr16 MDD+r3, 0x00, r0                   ; F85E79/F989DE  bb 00 50   ld (XHL+0x00),WA
	ld (XWA+0x02),HL                             ; F85E7C/F989E1  b8 02 53   ld (XWA+0x02),HL
	ld (XIX+0x09),0x00                           ; F85E7F/F989E4  bc 09 00 00   ld (XIX+0x09),0x00
	ei 0x00                                      ; F85E83/F989E8  06 00   ei 0x00
	pop XHL                                      ; F85E85/F989EA  5b   pop XHL
	pop XIY                                      ; F85E86/F989EB  5d   pop XIY
	pop XIX                                      ; F85E87/F989EC  5c   pop XIX
	popw wa                                      ; F85E88/F989ED  48   pop WA
	ret                                          ; F85E89/F989EE  0e   ret
