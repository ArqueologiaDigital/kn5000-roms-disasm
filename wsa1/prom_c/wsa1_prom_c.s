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
;   0xF980EA-0xF9810D  EntryPoint_Records -- the THREE TASKS, {entry PC, initial
;                      XSP, initial SR, ready-queue level}.  Read by
;                      Kernel_StartTask; the "?" third column is two fields
;   0xF9810E-0xF98111  the four semaphore counts' power-on image
;   0xF98112-0xF9816A  SoftTimer_RotateLevel2, task 3's body, and the kernel tick
;   0xF9816B-0xF989EE  ★★ CPU 2's MULTITASKING KERNEL -- 35 routines: the RAM
;                      initialiser, the dispatcher, the task lifecycle, four
;                      counting semaphores, two message queues, two software
;                      timers and the shared interrupt epilogue.  The SAME kernel
;                      prom_a carries, in the SAME ORDER, at the SAME lengths;
;                      35 of the 36 pairs have ZERO structural differences
;                      (notes/prom_c_kernel_map.py --pairs; * CORRECTED
;                      2026-08-25, round-2 audit F6 -- the tool has always run
;                      and printed 36, the 35 contiguous rows of PAIRS plus
;                      INTT3_KernelTick, which sits below the block).  ⚠ "at the
;                      SAME lengths" is an ASSUMPTION, not a measurement: ONE
;                      length column serves both images.  What is measured is
;                      that the rows tile each block from the first through the
;                      LAST with no gap, and that every row's address difference
;                      is the one constant 0x12B65.
;                      ★ ITS SOURCE IS NOT IN THIS FILE ANY MORE.  Since
;                      2026-08-30 this block is `kernel/kernel.s`, ONE source
;                      that prom_a includes too, with kernel_subcpu.inc naming
;                      the 21 values that are CPU 2's rather than CPU 1's.  Both
;                      images still rebuild byte for byte, which is what makes
;                      "the SAME kernel" a proof instead of a resemblance.
;   0xF98A0B-0xF98B1F  ★ the two A/D inputs, their deadband filter and the link
;                      messages they produce
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
;   0xFC89C5-0xFC8BB1  ★★ THE SERIAL EEPROM -- a Microwire 64 x 16 device
;                      bit-banged on P6.5/P8.3/P8.4/P8.5, and the 33-word
;                      checksummed block behind the key-touch calibration.  This
;                      is the storage NoteTrim_BuildFromCalibration was reading
;                      from without knowing it
;   0xFCA0BA-0xFCB27D  ★★ THE COMPILER RUNTIME -- 38 routines: the complete
;                      IEEE-754 double and single soft-float set (add, subtract,
;                      multiply, divide, negate, compare, classify and every
;                      conversion), 32-bit integer multiply and divide with their
;                      signed wrappers, and the 8/16/32-bit variable shifts.
;                      ★ float32 MULTIPLY is a / (1 / b) -- two divisions
;                      (notes/prom_c_runtime_check.py)
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
;   0xF80000-0xF97FFF  ★★ THE PRESET BANK, 98,304 bytes -- the largest single
;                      unconverted span this image had.  ASCII magic `ZZZZ`, a
;                      table of 16 named CATEGORIES, and 129 fixed 704-byte
;                      records each opening with a 16-character name.  Geometry
;                      proved four independent ways; NO CONSUMER LOCATED, and no
;                      field named.  notes/gen_prom_c_preset_bank.py --verify,
;                      notes/FINDINGS-prom_c-preset-bank.md
;   0xFCB27E-0xFCC53E  ★ the math library's 77-entry IEEE-754 DOUBLE COEFFICIENT
;                      POOL -- every entry decoded, and 54 of the 77 attributed to
;                      the routine that loads them -- one float32 1.0, and the
;                      head of the boot RAM image.
;                      notes/gen_prom_c_f64_pool.py --verify
;   0xFCD0F7-0xFDD2AA  ★★ THE RELOCATABLE BYTE-STREAM POOL, 65,972 bytes -- the
;                      largest single unconverted span this image had after the
;                      preset bank.  297 length-prefixed streams that P7Stream_Run
;                      sends out PORT P7 one byte at a time, 6 data tables and 4
;                      directory objects.  Framing proved four ways; NO STREAM'S
;                      MEANING NAMED.  notes/gen_prom_c_p7stream_pool.py --verify
;   0xFDD2AB-0xFDF7DF  the voice / DSP data-table zone -- 43 tables, 9,525 bytes,
;                      36 of them byte-identical to a NAMED table in the KN5000
;                      sub-CPU payload
;   0xFDF7E0-0xFE21E5  ★★ THE TAIL DATA ZONE, 10,758 bytes in 119 objects -- FIVE
;                      256-entry MATH TABLES end to end (sin, cos, atan, log2,
;                      exp2) read by a Q11 fixed-point library at 0xFC419D-0xFC4268;
;                      the four flash banks NAMED IN THE ROM ("WSA SOUND RAM S0"..
;                      "S3" at 0xFE14CB, bases 0xE80000/0xE90000/0xEA0000/0xEB0000
;                      at 0xFE151F); the two 251-entry tables that feed 0x00104000
;                      registers 0x00C0+chan and 0x0100+chan; and copy B of the
;                      initialiser image, emitted as its twin's objects with `_B`.
;                      notes/gen_prom_c_tail_tables.py --verify,
;                      notes/FINDINGS-prom_c-tail-data-zone.md
;   0xFCC81A-0xFCCA81  the 616-byte FLOATING-POINT CONSTANT POOL -- 76 doubles and
;                      two 4-byte elements, every element start cited by a load,
;                      and 44100 with its reciprocals among the values.
;                      notes/gen_prom_c_fp_pool.py --verify
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
; ★ AS OF ROUND 3 THIS FILE CONTAINS NO `.incbin` AT ALL: 395,072 bytes of
; substantive source and 129,216 bytes of filler emitted as `.fill` -- the
; 118,298-byte 0x0E run behind the tail data zone, the 3,611-byte run before the
; vector table and three smaller ones -- add up to the whole 524,288.  Filler is
; NOT progress and is reported separately: notes/prom_c_coverage_split.py.
; The gate (scripts/analysis/assert_byte_identical.py) must print PASS after
; every edit.
;
; PROVENANCE: this is not a chip read.  It is the publicly redistributed v2
; firmware set (../technics_roms/roms/wsa1/PROVENANCE.md).
;
; ==============================================================================
; * THE ROUND-12 INVENTORY -- what is NAMED here, and what is DECLARED NAMELESS
; ==============================================================================
; Wave 7 round 12, 2026-08-30.  Regenerate every figure below -- do not retype it:
;
;     python3 notes/prom_c_finish_round12.py --inventory
;     python3 notes/prom_c_finish_round12.py --selftest     # 35 checks
;
; prom_c is the first image in this tree for which the statement
;
;     EVERY OBJECT IS EITHER NAMED WITH EVIDENCE OR DECLARED NAMELESS WITH A
;     DERIVED REASON
;
; is true and checkable.  At emission the image held 1,738 top-level objects --
; 871 content-named, 500 framed, 367 sub_XXXXXX -- plus 4,683 <parent>__<address>
; branch targets, which are jump destinations and not objects.  Of the 867 that are
; not content-named, one of the wave's three naming mechanisms (name it from what it
; CONTAINS, from what READS it, or from what it POINTS AT) fires on 192.  On 70 of
; those the name it yields is only a FRAME.
;
; * AND THAT LAST NUMBER IS THE ROUND'S RESULT, not an apology for it.  A name is a
; frame here when the object has a >=90%-identical sibling in this same image: the two
; are separated by an IMMEDIATE, so anything that tells them apart tells them apart by
; a number.  Round 11 settled the test -- a number may be part of a name when it has a
; referent OUTSIDE the code, as `SoftKeyCol1` does because the legend is silkscreened
; on the instrument.  A record field offset has no such referent.  So the seven
; SlotRec_* / Rec_StoreConsts_* names this round shipped are spelled `_0009`, `_000C`,
; `_003F_0041` ON PURPOSE, so that the documentation metric grades them FRAMED.
; Spelling them `_Off09` would have moved the CONTENT column by seven and taught
; nobody anything.
;
; The 675 objects no mechanism reaches, by reason (--refusals gives the rule for each):
;
;     374  the P7 stream pool -- CONTENT is undecoded byte-code (R2).  What would name
;          them is stated in --refusals: not a cleverer census, a payload decoder or
;          an outside document.  The directory's DescriptorStrings are field-LAYOUT
;          descriptors over {b,w,v,s,h,c,B}, not names.
;     191  every caller is itself framed or unnamed -- no name can propagate in
;      81  the one content-named caller names a SUBSYSTEM, not this routine's job
;      15  no literal reference of any spelling, over four independent sweeps
;       8  not a routine at all: code reached by fall-through from the line above
;       6  a DATA object with no citation -- its bounds rest on tiling, not on a
;          reference, which is evidence and not a hole
;
; * THE NO-REFERENCE CENSUS FOUND SIX MORE THAN ROUND 7 DID, and they corroborate
; rather than contradict the file: round 7 ran that rule only over sub_XXXXXX, so
; it never asked it of the FRAMED objects.  Asked now, it independently reproduces
; two statements already written in this file by another argument -- "SIX ROUTINES
; HERE HAVE NO CALLER" above the 0xFB7B63 bank and "TWO ROUTINES HERE HAVE NO
; CALLER" above 0xFB796E.  32 code objects and 32 data objects survive four sweeps.
; And the census PRINTS ITS OWN BLIND SPOT beside the result: prom_c contains 49
; register-indirect transfers (28 `jp T,XBC`, 14 `jp T,XIX`, 7 `jp T,XWA`), any one
; of which can reach any address.  So every line of it says NOT FOUND and none of
; them says UNREACHABLE.
;
; * TWO THINGS THIS ROUND REFUSED THAT LOOKED EASY.
;   1. The six device-register writers of round 7's bucket S3.  The block extractor
;      that reproduces 36 of 36 already-named accessors DOES fire on all six -- and
;      those 36 run 31 to 136 bytes while these six run 188 to 545 and call other
;      routines.  A register set names an ACCESSOR; it does not name a 545-byte
;      routine that also retires voices.
;   2. The ten objects that are not routines.  Renaming them to <parent>__<address>
;      is right and round 7 said so -- and said it should be done by a lane that is
;      not also reporting the metric it moves.  This lane reports that metric.
;
; DEPTH: all 367 sub_XXXXXX carry a >=3-line header AND an Evidence line -- 367 of
; 367, which no other image in this tree can say.  Of the labels the grader sees with
; no header, 4,849 are branch targets and 467 are entries of three self-documenting
; ROM tables (for a preset, the LABEL IS THE DATUM).  Eight objects remain, all
; one- and two-instruction vector stubs carrying a single Evidence line each.  The one
; that carried none, IRQ_INTTC2, has one as of this round.
; ==============================================================================
; ★ THIS FILE IS NO LONGER THE WHOLE IMAGE -- READ THIS BEFORE GREPPING IT
; ==============================================================================
; Since 2026-08-30, 125,264 of these 127,731 lines live in 26 PER-SUBJECT
; SOURCES under prom_c/, and this file `.include`s them IN ADDRESS ORDER.  The
; include list below is therefore also the image's table of contents.
;
;   ⚠ prom_c has no `.org` and one section, so EMISSION ORDER IS ADDRESS ORDER.
;     Every extracted file is a CONTIGUOUS RANGE included at the line it started
;     on; reordering one would move code, and TLCS-900 `jr` has a short reach.
;     The byte gate is what would catch it.
;
;   ⚠ A TOOL THAT OPENS THIS FILE AND SCANS IT NOW SEES 2% OF THE IMAGE.
;     Follow the `.include`s -- notes/asm_source.py exists for exactly that, and
;     notes/reachability.py and scripts/analysis/source_coverage.py do it.
;
;   The split, its per-file rationale and its preservation proof:
;       python3 notes/prom_c_split.py --plan
;       python3 notes/prom_c_split.py --verify    <- no line lost, moved or reworded
;
; ★ WHAT STAYED HERE, AND WHY.  This header, which is about the whole image; and
;   0xFABE30-0xFACE66, 23 routines whose banner is a census with no title, 105 of
;   whose 118 labels are sub_XXXXXX, and whose callers are a mix.  Nothing there
;   names a subject, so nothing there was given one.  A smaller honest split
;   beats a complete dishonest one.
; ==============================================================================

	.include "include/tmp95c061_sfr.inc"

	.include "prom_c/data_tables/preset_bank.s"	; 0xF80000-0xF97FFF  THE PRESET BANK
	.include "prom_c/boot/boot_and_main.s"	; 0xF98000-0xF98CB8  power-on: the task table, the kernel, the RAM image, MAIN
	.include "prom_c/link/link_key_events.s"	; 0xF98CB9-0xF99062  key events become MIDI, and the four link-channel handlers
	.include "prom_c/boot/scheduler_intt1.s"	; 0xF99063-0xF990F9  INTT1, the six-phase scheduler tick
	.include "prom_c/midi/midi_serial_port.s"	; 0xF990FA-0xF99597  the SC0 serial port that is MIDI: init, ISRs, queues, TX
	.include "prom_c/keyscan/touch_to_velocity.s"	; 0xF99598-0xF9973C  the TOUCH-to-VELOCITY path, and its two setters
	.include "prom_c/keyscan/keyboard_scanner.s"	; 0xF9973D-0xF99BBD  the keyboard scanner at 0x00108000, and the per-note trim
	.include "prom_c/link/link_interrupts.s"	; 0xF99BBE-0xF99E5D  INT0 and INTTC2/INTTC3: the link's whole receive half
	.include "prom_c/link/link_service.s"	; 0xF99E5F-0xF9A04F  Link_ServiceTask, the link wait, uDMA and the block move
	.include "prom_c/p7/p7_module.s"	; 0xF9A050-0xFA5948  THE PORT-P7 MODULE: the byte transport, the streams, the units
	.include "prom_c/voice/voice_leaf_helpers.s"	; 0xFA5949-0xFA7E2B  the leaf helpers the voice-parameter module calls
	.include "prom_c/voice/voice_parameters.s"	; 0xFA7E2C-0xFABE2F  the VOICE-PARAMETER HELPER MODULE
; ==============================================================================
; 0xFABE30-0xFACE66 -- 23 routines, 0 computed-goto arm(s), 0 table(s), 4,151 bytes
; ==============================================================================
;
; Boundaries, read off the bytes rather than asserted:
;   0xFABE2F = 0x0E (`ret`)   0xFABE30 = EE 0C (`link XIZ`)
;   0xFACE66 = 0x0E (`ret`)   0xFACE67 = EE 0C (`link XIZ`)
;   ⚠ A `ret`/`link` pair at a cut is evidence the cut falls between
;   routines; anything else on those lines is a cut that needs reading.
;
; Call census (`python3 notes/prom_c_module_map.py 0xFABE30 0xFACE67`):
;   24 literal call site(s) from outside this block, 25 from inside it.
;          6  sub_FBB57C
;          5  sub_FBB4BF
;          4  sub_FBB645
;          2  Toggle14FE_AndDispatch
;          2  sub_FBB6F8
;          1  MidiCtrl_CC120
;          1  MidiCtrl_Dispatch
;          1  sub_FB029E
;          1  sub_FB6BA8
;          1  MidiNote_OnByPartMode
;   ⚠ Sites in code that is still `.incbin` are counted under
;   "(caller not yet converted)"; that row shrinks as conversion proceeds,
;   so every named row is a FLOOR.
;
; No computed-goto table: `python3 notes/prom_c_jumptables.py 0xFABE30 0xFACE67`
;   prints none, so the whole range is decoded linearly.
;
; ★ DECODE ALIGNMENT.  notes/gen_prom_c_block.py requires every
;   call/calr/jp/jrl/jr target that a DECODED INSTRUCTION in this file names
;   and that lands inside this range to be the start of a listing line.  A
;   byte round trip cannot show that -- a misaligned decode of data can
;   re-encode to the same bytes -- so this is the test that says the listing
;   was read at the right offsets, and it is what found the BC-form jump
;   table at 0xFAF08F that the table scanner had missed.
;
; ⚠ NO ROUTINE HERE IS NAMED FOR WHAT IT DOES.  Each header states the frame
;   size, the argument slots read, the absolute addresses read and written,
;   the routines called and the call sites -- operands and decoded-instruction
;   scans, nothing interpreted.
;
; ★ REGENERATE:
;     python3 notes/gen_prom_c_block.py --start 0xFABE30 --end 0xFACE67 > /tmp/b.s
;     python3 notes/gen_prom_c_block_headers.py --start 0xFABE30 --end 0xFACE67 \
;         --labels > /tmp/b.labels
;     python3 notes/gen_prom_c_block_headers.py --start 0xFABE30 --end 0xFACE67 \
;         --headers > /tmp/b.headers
;     python3 notes/prom_c_apply_headers.py /tmp/b.s /tmp/b.labels \
;         /tmp/b.headers > /tmp/b.final.s
;     python3 notes/prom_c_verify_fragment.py c 0xFABE30 /tmp/b.final.s
; ==============================================================================
; --------------------------------------------------------------------------
; Voice_RecomputeAllThreeBaseCurves -- 0xFABE30..0xFAC025 (502 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFACA43
; Inputs:  frame `link XIZ,-12`; no positive frame slot is read
; Outputs: writes 0x00D796, 0x00D79E, 0x00D7A0
; Calls:   0xFA796D = EGEnv_Eval_BaseCurveA, 0xFA7A4B = EGEnv_Eval_BaseCurveB
;          0xFA7B31 = EGEnv_Eval_FreqWriteBaseCurve, 0xFABDAC = sub_FABDAC
;          0xFB7C8F = Dev10C_SetChanReg_0600_b, 0xFB7E7B = Dev10C_SetChanReg_01C0_b
;          0xFB7FCE = Dev10C_SetChanReg_01C0_or_0600_b, 0xFCB11B = Multiply32
; Evidence: the listing below is the byte-identical round-trip of 0xFABE30-0xFAC025
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; ★ ROUND 6 ------------------------------------------------------------
; Voice_RecomputeAllThreeBaseCurves -- the ONE
;          routine in the image that calls all three BASE evaluators (0xFABE60, 0xFABEEB,
;          0xFABF7E) and none of the three value evaluators, writing 0x00D796, 0x00D79E and
;          0x00D7A0 and then Dev10C_SetChanReg_01C0_b / _0600_b / _01C0_or_0600_b.
;          Evidence: the co-occurrence census in notes/prom_c_understanding_round6.py --blocks
;          enumerates every caller of every evaluator; this is the only row with more than one
;          block letter, and the check that says so names it explicitly.
; --------------------------------------------------------------------------
Voice_RecomputeAllThreeBaseCurves:
	link32 0xEE, 0x0C, 0xF4, 0xFF              ; FABE30  link XIZ,0xfff4
	push	xhl                                   ; FABE34  push XHL
	pushw	de                                   ; FABE35  push DE
	pushw	ix                                   ; FABE36  push IX
	ldw (xiz-2), 0x0000                        ; FABE37  ld (XIZ+0xfe),0x0000
	ldw	de, 0                                  ; FABE3C  ld DE,0x0000
Voice_RecomputeAllThreeBaseCurves__FABE3F:
	ld	ix, de                                  ; FABE3F  ld IX,DE
	ldw	hl, 0x4CCF                             ; FABE41  ld HL,0x4ccf
	ld	bc, ix                                  ; FABE44  ld BC,IX
	add	hl, bc                                 ; FABE46  add HL,BC
	extz	xhl                                   ; FABE48  extz XHL
	ld	c, (xhl)                                ; FABE4A  ld C,(XHL)
	and	c, 24                                  ; FABE4C  and C,0x18
	jr z, Voice_RecomputeAllThreeBaseCurves__FABEB3                   ; FABE4F  jr Z,0xfabeb3
	pushw	hl                                   ; FABE51  push HL
	calr (0xFABDAC - 0xFABE55)                 ; FABE52  calr 0xfabdac
	ld	hl, wa                                  ; FABE55  ld HL,WA
	popw	bc                                    ; FABE57  pop BC
	cps	wa, 0                                  ; FABE58  cp WA,0
	jr z, Voice_RecomputeAllThreeBaseCurves__FABEB3                   ; FABE5A  jr Z,0xfabeb3
	ld	c, (xiz-2)                              ; FABE5C  ld C,(XIZ+0xfe)
	pushw	bc                                   ; FABE5F  push BC
	calr (0xFA796D - 0xFABE63)                 ; FABE60  calr 0xfa796d
	stw_da	(0xD79E), wa                        ; FABE63  ld (0x00d79e),WA
	popw	bc                                    ; FABE68  pop BC
	cp	hl, 0x100                               ; FABE69  cp HL,0x0100
	jr z, Voice_RecomputeAllThreeBaseCurves__FABEA4                   ; FABE6D  jr Z,0xfabea4
	ldw_da	ix, (0xD79E)                        ; FABE6F  ld IX,(0x00d79e)
	ld	bc, ix                                  ; FABE74  ld BC,IX
	and	bc, 0x1FFF                             ; FABE76  and BC,0x1fff
	extz	xbc                                   ; FABE7A  extz XBC
	ld	(xiz-6), xbc                            ; FABE7C  ld (XIZ+0xfa),XBC
	ld	wa, hl                                  ; FABE7F  ld WA,HL
	extz	xwa                                   ; FABE81  extz XWA
	push	xwa                                   ; FABE83  push XWA
	push	xbc                                   ; FABE84  push XBC
	call	0xFCB11B                              ; FABE85  call 0xfcb11b
	ld	(xiz-10), xiy                           ; FABE89  ld (XIZ+0xf6),XIY
	ld	hl, ix                                  ; FABE8C  ld HL,IX
	and	hl, 0xE000                             ; FABE8E  and HL,0xe000
	stw_da	(0xD79E), hl                        ; FABE92  ld (0x00d79e),HL
	ld	xiy, (xiz-10)                           ; FABE97  ld XIY,(XIZ+0xf6)
	srl	xiy, 8                                 ; FABE9A  srl 0x08,XIY
	or	iy, hl                                  ; FABE9D  or IY,HL
	stw_da	(0xD79E), iy                        ; FABE9F  ld (0x00d79e),IY
Voice_RecomputeAllThreeBaseCurves__FABEA4:
	lda	xbc, (0xD75E:24)                       ; FABEA4  lda XBC,0x00d75e
	push	xbc                                   ; FABEA9  push XBC
	extpfx3 0x9E, 0xFE, 0x04                   ; FABEAA  pushw (XIZ+0xfe)
	call	0xFB7C8F                              ; FABEAD  call 0xfb7c8f
	inc	6, xsp                                 ; FABEB1  inc 6,XSP
Voice_RecomputeAllThreeBaseCurves__FABEB3:
	add	de, 27                                 ; FABEB3  add DE,0x001b
	incw	1, (xiz-2)                            ; FABEB7  incw 1,(XIZ+0xfe)
	cp	de, 0xD80                               ; FABEBA  cp DE,0x0d80
	jrl c, Voice_RecomputeAllThreeBaseCurves__FABE3F                  ; FABEBE  jrl C,0xfabe3f
	ldw (xiz-2), 0x0000                        ; FABEC1  ld (XIZ+0xfe),0x0000
	ldw	de, 0                                  ; FABEC6  ld DE,0x0000
	ldw	ix, 9                                  ; FABEC9  ld IX,0x0009
Voice_RecomputeAllThreeBaseCurves__FABECC:
	ldw	hl, 0x4CCF                             ; FABECC  ld HL,0x4ccf
	ld	bc, ix                                  ; FABECF  ld BC,IX
	add	hl, bc                                 ; FABED1  add HL,BC
	extz	xhl                                   ; FABED3  extz XHL
	ld	a, (xhl)                                ; FABED5  ld A,(XHL)
	and	a, 24                                  ; FABED7  and A,0x18
	jr z, Voice_RecomputeAllThreeBaseCurves__FABF40                   ; FABEDA  jr Z,0xfabf40
	pushw	hl                                   ; FABEDC  push HL
	calr (0xFABDAC - 0xFABEE0)                 ; FABEDD  calr 0xfabdac
	ld	hl, wa                                  ; FABEE0  ld HL,WA
	popw	bc                                    ; FABEE2  pop BC
	cps	wa, 0                                  ; FABEE3  cp WA,0
	jr z, Voice_RecomputeAllThreeBaseCurves__FABF40                   ; FABEE5  jr Z,0xfabf40
	ld	c, (xiz-2)                              ; FABEE7  ld C,(XIZ+0xfe)
	pushw	bc                                   ; FABEEA  push BC
	calr (0xFA7A4B - 0xFABEEE)                 ; FABEEB  calr 0xfa7a4b
	stw_da	(0xD796), wa                        ; FABEEE  ld (0x00d796),WA
	popw	bc                                    ; FABEF3  pop BC
	cp	hl, 0x100                               ; FABEF4  cp HL,0x0100
	jr z, Voice_RecomputeAllThreeBaseCurves__FABF31                   ; FABEF8  jr Z,0xfabf31
	ldw_da	bc, (0xD796)                        ; FABEFA  ld BC,(0x00d796)
	ld	(xiz-4), bc                             ; FABEFF  ld (XIZ+0xfc),BC
	and	bc, 0x1FFF                             ; FABF02  and BC,0x1fff
	extz	xbc                                   ; FABF06  extz XBC
	ld	(xiz-8), xbc                            ; FABF08  ld (XIZ+0xf8),XBC
	ld	wa, hl                                  ; FABF0B  ld WA,HL
	extz	xwa                                   ; FABF0D  extz XWA
	push	xwa                                   ; FABF0F  push XWA
	push	xbc                                   ; FABF10  push XBC
	call	0xFCB11B                              ; FABF11  call 0xfcb11b
	ld	(xiz-12), xiy                           ; FABF15  ld (XIZ+0xf4),XIY
	ld	hl, (xiz-4)                             ; FABF18  ld HL,(XIZ+0xfc)
	and	hl, 0xE000                             ; FABF1B  and HL,0xe000
	stw_da	(0xD796), hl                        ; FABF1F  ld (0x00d796),HL
	ld	xiy, (xiz-12)                           ; FABF24  ld XIY,(XIZ+0xf4)
	srl	xiy, 8                                 ; FABF27  srl 0x08,XIY
	or	iy, hl                                  ; FABF2A  or IY,HL
	stw_da	(0xD796), iy                        ; FABF2C  ld (0x00d796),IY
Voice_RecomputeAllThreeBaseCurves__FABF31:
	lda	xbc, (0xD75E:24)                       ; FABF31  lda XBC,0x00d75e
	push	xbc                                   ; FABF36  push XBC
	extpfx3 0x9E, 0xFE, 0x04                   ; FABF37  pushw (XIZ+0xfe)
	call	0xFB7E7B                              ; FABF3A  call 0xfb7e7b
	inc	6, xsp                                 ; FABF3E  inc 6,XSP
Voice_RecomputeAllThreeBaseCurves__FABF40:
	add	de, 27                                 ; FABF40  add DE,0x001b
	add	ix, 27                                 ; FABF44  add IX,0x001b
	incw	1, (xiz-2)                            ; FABF48  incw 1,(XIZ+0xfe)
	cp	de, 0x6C0                               ; FABF4B  cp DE,0x06c0
	jrl c, Voice_RecomputeAllThreeBaseCurves__FABECC                  ; FABF4F  jrl C,0xfabecc
	ldw (xiz-2), 0x0000                        ; FABF52  ld (XIZ+0xfe),0x0000
	ldw	de, 0                                  ; FABF57  ld DE,0x0000
	ldw	ix, 18                                 ; FABF5A  ld IX,0x0012
Voice_RecomputeAllThreeBaseCurves__FABF5D:
	ldw	hl, 0x4CCF                             ; FABF5D  ld HL,0x4ccf
	ld	bc, ix                                  ; FABF60  ld BC,IX
	add	hl, bc                                 ; FABF62  add HL,BC
	extz	xhl                                   ; FABF64  extz XHL
	ld	a, (xhl)                                ; FABF66  ld A,(XHL)
	and	a, 24                                  ; FABF68  and A,0x18
	jrl z, Voice_RecomputeAllThreeBaseCurves__FAC00E                  ; FABF6B  jrl Z,0xfac00e
	pushw	hl                                   ; FABF6E  push HL
	calr (0xFABDAC - 0xFABF72)                 ; FABF6F  calr 0xfabdac
	ld	hl, wa                                  ; FABF72  ld HL,WA
	popw	bc                                    ; FABF74  pop BC
	cps	wa, 0                                  ; FABF75  cp WA,0
	jrl z, Voice_RecomputeAllThreeBaseCurves__FAC00E                  ; FABF77  jrl Z,0xfac00e
	ld	c, (xiz-2)                              ; FABF7A  ld C,(XIZ+0xfe)
	pushw	bc                                   ; FABF7D  push BC
	calr (0xFA7B31 - 0xFABF81)                 ; FABF7E  calr 0xfa7b31
	popw	bc                                    ; FABF81  pop BC
	cp	hl, 0x100                               ; FABF82  cp HL,0x0100
	jrl z, Voice_RecomputeAllThreeBaseCurves__FABFFF                  ; FABF86  jrl Z,0xfabfff
	cp	de, 0x6C0                               ; FABF89  cp DE,0x06c0
	jr nc, Voice_RecomputeAllThreeBaseCurves__FABFC8                  ; FABF8D  jr NC,0xfabfc8
	ldw_da	bc, (0xD796)                        ; FABF8F  ld BC,(0x00d796)
	ld	(xiz-4), bc                             ; FABF94  ld (XIZ+0xfc),BC
	and	bc, 0x1FFF                             ; FABF97  and BC,0x1fff
	extz	xbc                                   ; FABF9B  extz XBC
	ld	(xiz-8), xbc                            ; FABF9D  ld (XIZ+0xf8),XBC
	ld	wa, hl                                  ; FABFA0  ld WA,HL
	extz	xwa                                   ; FABFA2  extz XWA
	push	xwa                                   ; FABFA4  push XWA
	push	xbc                                   ; FABFA5  push XBC
	call	0xFCB11B                              ; FABFA6  call 0xfcb11b
	ld	(xiz-12), xiy                           ; FABFAA  ld (XIZ+0xf4),XIY
	ld	hl, (xiz-4)                             ; FABFAD  ld HL,(XIZ+0xfc)
	and	hl, 0xE000                             ; FABFB0  and HL,0xe000
	stw_da	(0xD796), hl                        ; FABFB4  ld (0x00d796),HL
	ld	xiy, (xiz-12)                           ; FABFB9  ld XIY,(XIZ+0xf4)
	srl	xiy, 8                                 ; FABFBC  srl 0x08,XIY
	or	iy, hl                                  ; FABFBF  or IY,HL
	stw_da	(0xD796), iy                        ; FABFC1  ld (0x00d796),IY
	jr Voice_RecomputeAllThreeBaseCurves__FABFFF                      ; FABFC6  jr T,0xfabfff
Voice_RecomputeAllThreeBaseCurves__FABFC8:
	ldw_da	bc, (0xD7A0)                        ; FABFC8  ld BC,(0x00d7a0)
	ld	(xiz-4), bc                             ; FABFCD  ld (XIZ+0xfc),BC
	and	bc, 0x1FFF                             ; FABFD0  and BC,0x1fff
	extz	xbc                                   ; FABFD4  extz XBC
	ld	(xiz-8), xbc                            ; FABFD6  ld (XIZ+0xf8),XBC
	ld	wa, hl                                  ; FABFD9  ld WA,HL
	extz	xwa                                   ; FABFDB  extz XWA
	push	xwa                                   ; FABFDD  push XWA
	push	xbc                                   ; FABFDE  push XBC
	call	0xFCB11B                              ; FABFDF  call 0xfcb11b
	ld	(xiz-12), xiy                           ; FABFE3  ld (XIZ+0xf4),XIY
	ld	hl, (xiz-4)                             ; FABFE6  ld HL,(XIZ+0xfc)
	and	hl, 0xE000                             ; FABFE9  and HL,0xe000
	stw_da	(0xD7A0), hl                        ; FABFED  ld (0x00d7a0),HL
	ld	xiy, (xiz-12)                           ; FABFF2  ld XIY,(XIZ+0xf4)
	srl	xiy, 8                                 ; FABFF5  srl 0x08,XIY
	or	iy, hl                                  ; FABFF8  or IY,HL
	stw_da	(0xD7A0), iy                        ; FABFFA  ld (0x00d7a0),IY
Voice_RecomputeAllThreeBaseCurves__FABFFF:
	lda	xbc, (0xD75E:24)                       ; FABFFF  lda XBC,0x00d75e
	push	xbc                                   ; FAC004  push XBC
	extpfx3 0x9E, 0xFE, 0x04                   ; FAC005  pushw (XIZ+0xfe)
	call	0xFB7FCE                              ; FAC008  call 0xfb7fce
	inc	6, xsp                                 ; FAC00C  inc 6,XSP
Voice_RecomputeAllThreeBaseCurves__FAC00E:
	add	de, 27                                 ; FAC00E  add DE,0x001b
	add	ix, 27                                 ; FAC012  add IX,0x001b
	incw	1, (xiz-2)                            ; FAC016  incw 1,(XIZ+0xfe)
	cp	de, 0xD80                               ; FAC019  cp DE,0x0d80
	jrl c, Voice_RecomputeAllThreeBaseCurves__FABF5D                  ; FAC01D  jrl C,0xfabf5d
	popw	ix                                    ; FAC020  pop IX
	popw	de                                    ; FAC021  pop DE
	pop	xhl                                    ; FAC022  pop XHL
	unlk32 xiz                                 ; FAC023  unlk XIZ
	ret                                        ; FAC025  ret
; --------------------------------------------------------------------------
; sub_FAC026 -- 0xFAC026..0xFAC08C (103 bytes)
;
; Called from: no site outside this module.
;          2 site(s) inside this module:
;          0xFACA7E 0xFACB05
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA6EA5 = sub_FA6EA5, 0xFB3D26 = Voice_Retire_Mode20
;          0xFB732C = Dev10C_WriteReg_c
; Voice record: touches voice_record[+0x00(r), +0x29(r), +0x2B(rw)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAC026-0xFAC08C
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAC026:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAC026  link XIZ,0x0000
	pushw	hl                                   ; FAC02A  push HL
	push	xde                                   ; FAC02B  push XDE
	ld	de, (xiz+8)                             ; FAC02C  ld DE,(XIZ+0x08)
	extz	xde                                   ; FAC02F  extz XDE
	ld	hl, (xde+43)                            ; FAC031  ld HL,(XDE+0x2b)
	ld	bc, hl                                  ; FAC034  ld BC,HL
	and	bc, 0x8000                             ; FAC036  and BC,0x8000
	jr z, sub_FAC026__FAC064                   ; FAC03A  jr Z,0xfac064
	ldw	bc, 0x100                              ; FAC03C  ld BC,0x0100
	sub	hl, bc                                 ; FAC03F  sub HL,BC
	ld	wa, hl                                  ; FAC041  ld WA,HL
	and	wa, 0x7F00                             ; FAC043  and WA,0x7f00
	jr nz, sub_FAC026__FAC064                  ; FAC047  jr NZ,0xfac064
	extz	xde                                   ; FAC049  extz XDE
	ld	wa, (xde+41)                            ; FAC04B  ld WA,(XDE+0x29)
	pushw	wa                                   ; FAC04E  push WA
	ld	a, (xde)                                ; FAC04F  ld A,(XDE)
	extz	wa                                    ; FAC051  extz WA
	pushw	wa                                   ; FAC053  push WA
	call	0xFB732C                              ; FAC054  call 0xfb732c
	ld	c, (xde)                                ; FAC058  ld C,(XDE)
	pushw	bc                                   ; FAC05A  push BC
	call	0xFA6EA5                              ; FAC05B  call 0xfa6ea5
	res	15, hl                                 ; FAC05F  res 0x0f,HL
	inc	6, xsp                                 ; FAC062  inc 6,XSP
sub_FAC026__FAC064:
	ld	bc, hl                                  ; FAC064  ld BC,HL
	and	bc, 0x80                               ; FAC066  and BC,0x0080
	jr z, sub_FAC026__FAC083                   ; FAC06A  jr Z,0xfac083
	dec	1, hl                                  ; FAC06C  dec 1,HL
	ld	bc, hl                                  ; FAC06E  ld BC,HL
	and	bc, 0x7F                               ; FAC070  and BC,0x007f
	jr nz, sub_FAC026__FAC083                  ; FAC074  jr NZ,0xfac083
	extz	xde                                   ; FAC076  extz XDE
	ld	c, (xde)                                ; FAC078  ld C,(XDE)
	pushw	bc                                   ; FAC07A  push BC
	call	0xFB3D26                              ; FAC07B  call 0xfb3d26
	res	7, hl                                  ; FAC07F  res 0x07,HL
	popw	bc                                    ; FAC082  pop BC
sub_FAC026__FAC083:
	extz	xde                                   ; FAC083  extz XDE
	ld	(xde+43), hl                            ; FAC085  ld (XDE+0x2b),HL
	pop	xde                                    ; FAC088  pop XDE
	popw	hl                                    ; FAC089  pop HL
	unlk32 xiz                                 ; FAC08A  unlk XIZ
	ret                                        ; FAC08C  ret
; --------------------------------------------------------------------------
; sub_FAC08D -- 0xFAC08D..0xFAC2AD (545 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFACB16
; Inputs:  frame `link XIZ,-8`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Calls:   0xFA6EA5 = sub_FA6EA5, 0xFAB79D = sub_FAB79D
;          0xFB3D26 = Voice_Retire_Mode20, 0xFB7502 = Dev10C_SetChanReg_0180_FromArg
;          0xFB7521 = sub_FB7521, 0xFB762F = sub_FB762F
; Voice record: touches voice_record[+0x00(r), +0x27(r), +0x2D(r), +0x2F(rw), +0x31(r), +0x32(r), +0x34(r), +0x36(r), +0x38(r)] -- pointer through its (XIZ+0x08) argument.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFAC08D-0xFAC2AD
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAC08D:
	link32 0xEE, 0x0C, 0xF8, 0xFF              ; FAC08D  link XIZ,0xfff8
	pushw	hl                                   ; FAC091  push HL
	pushw	de                                   ; FAC092  push DE
	push	xix                                   ; FAC093  push XIX
	ld	ix, (xiz+8)                             ; FAC094  ld IX,(XIZ+0x08)
	extz	xix                                   ; FAC097  extz XIX
	ld	bc, (xix+45)                            ; FAC099  ld BC,(XIX+0x2d)
	ld	(xiz-2), bc                             ; FAC09C  ld (XIZ+0xfe),BC
	ld	hl, bc                                  ; FAC09F  ld HL,BC
	and	bc, 0x7F                               ; FAC0A1  and BC,0x007f
	ld	hl, bc                                  ; FAC0A5  ld HL,BC
	jrl nz, sub_FAC08D__FAC258                 ; FAC0A7  jrl NZ,0xfac258
	extz	xix                                   ; FAC0AA  extz XIX
	ld	a, (xix+49)                             ; FAC0AC  ld A,(XIX+0x31)
	extz	wa                                    ; FAC0AF  extz WA
	extpfx3 0x9E, 0xFE, 0xE0                   ; FAC0B1  or WA,(XIZ+0xfe)
	xor	wa, 0x800                              ; FAC0B4  xor WA,0x0800
	ld	(xiz-2), wa                             ; FAC0B8  ld (XIZ+0xfe),WA
	and	wa, 0x800                              ; FAC0BB  and WA,0x0800
	jr z, sub_FAC08D__FAC0D6                   ; FAC0BF  jr Z,0xfac0d6
	extz	xix                                   ; FAC0C1  extz XIX
	ld	wa, (xix+39)                            ; FAC0C3  ld WA,(XIX+0x27)
	ld	hl, wa                                  ; FAC0C6  ld HL,WA
	and	hl, 0xFF80                             ; FAC0C8  and HL,0xff80
	ld	a, (xix+56)                             ; FAC0CC  ld A,(XIX+0x38)
	extz	wa                                    ; FAC0CF  extz WA
	or	wa, hl                                  ; FAC0D1  or WA,HL
	pushw	wa                                   ; FAC0D3  push WA
	jr sub_FAC08D__FAC0DC                      ; FAC0D4  jr T,0xfac0dc
sub_FAC08D__FAC0D6:
	extz	xix                                   ; FAC0D6  extz XIX
	ld	bc, (xix+39)                            ; FAC0D8  ld BC,(XIX+0x27)
	pushw	bc                                   ; FAC0DB  push BC
sub_FAC08D__FAC0DC:
	extz	xix                                   ; FAC0DC  extz XIX
	ld	c, (xix)                                ; FAC0DE  ld C,(XIX)
	extz	bc                                    ; FAC0E0  extz BC
	pushw	bc                                   ; FAC0E2  push BC
	call	0xFB7502                              ; FAC0E3  call 0xfb7502
	ld	bc, (xiz-2)                             ; FAC0E7  ld BC,(XIZ+0xfe)
	and	bc, 0x7000                             ; FAC0EA  and BC,0x7000
	pop	xiy                                    ; FAC0EE  pop XIY
	cp	bc, 0x1000                              ; FAC0EF  cp BC,0x1000
	jrl z, sub_FAC08D__FAC1C1                  ; FAC0F3  jrl Z,0xfac1c1
	cp	bc, 0x2000                              ; FAC0F6  cp BC,0x2000
	jrl z, sub_FAC08D__FAC174                  ; FAC0FA  jrl Z,0xfac174
	cp	bc, 0x4000                              ; FAC0FD  cp BC,0x4000
	jr z, sub_FAC08D__FAC106                   ; FAC101  jr Z,0xfac106
	jrl sub_FAC08D__FAC251                     ; FAC103  jrl T,0xfac251
sub_FAC08D__FAC106:
	extz	xix                                   ; FAC106  extz XIX
	ld	de, (xix+50)                            ; FAC108  ld DE,(XIX+0x32)
	ld	hl, (xix+47)                            ; FAC10B  ld HL,(XIX+0x2f)
	ld	bc, de                                  ; FAC10E  ld BC,DE
	add	hl, bc                                 ; FAC110  add HL,BC
	cp	hl, 0xFF00                              ; FAC112  cp HL,0xff00
	jrl le, sub_FAC08D__FAC1D3                 ; FAC116  jrl LE,0xfac1d3
	extz	xix                                   ; FAC119  extz XIX
	ld	c, (xix)                                ; FAC11B  ld C,(XIX)
	extz	bc                                    ; FAC11D  extz BC
	ld	de, bc                                  ; FAC11F  ld DE,BC
	add	de, 0x840                              ; FAC121  add DE,0x0840
	ld	xbc, 0x10C000                           ; FAC125  ld XBC,0x0010c000
	ld	(xiz-6), xbc                            ; FAC12A  ld (XIZ+0xfa),XBC
	ld	(xbc), de                               ; FAC12D  ld (XBC),DE
	ld	xbc, (xiz-6)                            ; FAC12F  ld XBC,(XIZ+0xfa)
	extpfx5 0xB9, 0x02, 0x02, 0x00, 0xFF       ; FAC132  ld (XBC+0x02),0xff00
	nop                                        ; FAC137  nop
	nop                                        ; FAC138  nop
	nop                                        ; FAC139  nop
	nop                                        ; FAC13A  nop
	nop                                        ; FAC13B  nop
	extz	xix                                   ; FAC13C  extz XIX
	ld	c, (xix)                                ; FAC13E  ld C,(XIX)
	extz	bc                                    ; FAC140  extz BC
	add	bc, 0x800                              ; FAC142  add BC,0x0800
	ld	(xiz-4), bc                             ; FAC146  ld (XIZ+0xfc),BC
	ld	xwa, 0x10C000                           ; FAC149  ld XWA,0x0010c000
	ld	(xiz-8), xwa                            ; FAC14E  ld (XIZ+0xf8),XWA
	ld	(xwa), bc                               ; FAC151  ld (XWA),BC
	ld	xbc, (xiz-8)                            ; FAC153  ld XBC,(XIZ+0xf8)
	extpfx5 0xB9, 0x02, 0x02, 0x80, 0xFF       ; FAC156  ld (XBC+0x02),0xff80
	ld	de, (xix+54)                            ; FAC15B  ld DE,(XIX+0x36)
	cp	hl, de                                  ; FAC15E  cp HL,DE
	jrl ge, sub_FAC08D__FAC232                 ; FAC160  jrl GE,0xfac232
	ld	hl, de                                  ; FAC163  ld HL,DE
	ld	bc, (xiz-2)                             ; FAC165  ld BC,(XIZ+0xfe)
	res	14, bc                                 ; FAC168  res 0x0e,BC
	set	13, bc                                 ; FAC16B  set 0x0d,BC
	ld	(xiz-2), bc                             ; FAC16E  ld (XIZ+0xfe),BC
	jrl sub_FAC08D__FAC232                     ; FAC171  jrl T,0xfac232
sub_FAC08D__FAC174:
	extz	xix                                   ; FAC174  extz XIX
	ld	c, (xix)                                ; FAC176  ld C,(XIX)
	extz	bc                                    ; FAC178  extz BC
	ld	hl, bc                                  ; FAC17A  ld HL,BC
	add	hl, 0x840                              ; FAC17C  add HL,0x0840
	ld	xbc, 0x10C000                           ; FAC180  ld XBC,0x0010c000
	ld	(xiz-6), xbc                            ; FAC185  ld (XIZ+0xfa),XBC
	ld	(xbc), hl                               ; FAC188  ld (XBC),HL
	ld	xbc, (xiz-6)                            ; FAC18A  ld XBC,(XIZ+0xfa)
	extpfx5 0xB9, 0x02, 0x02, 0x00, 0xFF       ; FAC18D  ld (XBC+0x02),0xff00
	nop                                        ; FAC192  nop
	nop                                        ; FAC193  nop
	nop                                        ; FAC194  nop
	nop                                        ; FAC195  nop
	nop                                        ; FAC196  nop
	extz	xix                                   ; FAC197  extz XIX
	ld	c, (xix)                                ; FAC199  ld C,(XIX)
	extz	bc                                    ; FAC19B  extz BC
	ld	hl, bc                                  ; FAC19D  ld HL,BC
	add	hl, 0x800                              ; FAC19F  add HL,0x0800
	ld	xbc, 0x10C000                           ; FAC1A3  ld XBC,0x0010c000
	ld	(xiz-6), xbc                            ; FAC1A8  ld (XIZ+0xfa),XBC
	ld	(xbc), hl                               ; FAC1AB  ld (XBC),HL
	ld	xbc, (xiz-6)                            ; FAC1AD  ld XBC,(XIZ+0xfa)
	extpfx5 0xB9, 0x02, 0x02, 0x80, 0xFF       ; FAC1B0  ld (XBC+0x02),0xff80
	pushw	ix                                   ; FAC1B5  push IX
	ld	c, (xix)                                ; FAC1B6  ld C,(XIX)
	extz	bc                                    ; FAC1B8  extz BC
	pushw	bc                                   ; FAC1BA  push BC
	call	0xFB762F                              ; FAC1BB  call 0xfb762f
	jr sub_FAC08D__FAC1ED                      ; FAC1BF  jr T,0xfac1ed
sub_FAC08D__FAC1C1:
	extz	xix                                   ; FAC1C1  extz XIX
	ld	de, (xix+52)                            ; FAC1C3  ld DE,(XIX+0x34)
	ld	hl, (xix+47)                            ; FAC1C6  ld HL,(XIX+0x2f)
	ld	bc, de                                  ; FAC1C9  ld BC,DE
	add	hl, bc                                 ; FAC1CB  add HL,BC
	cp	hl, 0xFF00                              ; FAC1CD  cp HL,0xff00
	jr gt, sub_FAC08D__FAC1F1                  ; FAC1D1  jr GT,0xfac1f1
sub_FAC08D__FAC1D3:
	extz	xix                                   ; FAC1D3  extz XIX
	extpfx5 0xBC, 0x2F, 0x02, 0x00, 0xFF       ; FAC1D5  ld (XIX+0x2f),0xff00
	ld	c, (xix)                                ; FAC1DA  ld C,(XIX)
	pushw	bc                                   ; FAC1DC  push BC
	call	0xFA6EA5                              ; FAC1DD  call 0xfa6ea5
	ld	c, (xix)                                ; FAC1E1  ld C,(XIX)
	pushw	bc                                   ; FAC1E3  push BC
	call	0xFB3D26                              ; FAC1E4  call 0xfb3d26
	extpfx5 0x9E, 0xFE, 0x3C, 0xFF, 0x6F       ; FAC1E8  and (XIZ+0xfe),0x6fff
sub_FAC08D__FAC1ED:
	pop	xiy                                    ; FAC1ED  pop XIY
	jrl sub_FAC08D__FAC2A0                     ; FAC1EE  jrl T,0xfac2a0
sub_FAC08D__FAC1F1:
	extz	xix                                   ; FAC1F1  extz XIX
	ld	c, (xix)                                ; FAC1F3  ld C,(XIX)
	extz	bc                                    ; FAC1F5  extz BC
	ld	de, bc                                  ; FAC1F7  ld DE,BC
	add	de, 0x840                              ; FAC1F9  add DE,0x0840
	ld	xbc, 0x10C000                           ; FAC1FD  ld XBC,0x0010c000
	ld	(xiz-6), xbc                            ; FAC202  ld (XIZ+0xfa),XBC
	ld	(xbc), de                               ; FAC205  ld (XBC),DE
	ld	xbc, (xiz-6)                            ; FAC207  ld XBC,(XIZ+0xfa)
	extpfx5 0xB9, 0x02, 0x02, 0x00, 0xFF       ; FAC20A  ld (XBC+0x02),0xff00
	nop                                        ; FAC20F  nop
	nop                                        ; FAC210  nop
	nop                                        ; FAC211  nop
	nop                                        ; FAC212  nop
	nop                                        ; FAC213  nop
	extz	xix                                   ; FAC214  extz XIX
	ld	c, (xix)                                ; FAC216  ld C,(XIX)
	extz	bc                                    ; FAC218  extz BC
	ld	de, bc                                  ; FAC21A  ld DE,BC
	add	de, 0x800                              ; FAC21C  add DE,0x0800
	ld	xbc, 0x10C000                           ; FAC220  ld XBC,0x0010c000
	ld	(xiz-6), xbc                            ; FAC225  ld (XIZ+0xfa),XBC
	ld	(xbc), de                               ; FAC228  ld (XBC),DE
	ld	xbc, (xiz-6)                            ; FAC22A  ld XBC,(XIZ+0xfa)
	extpfx5 0xB9, 0x02, 0x02, 0x80, 0xFF       ; FAC22D  ld (XBC+0x02),0xff80
sub_FAC08D__FAC232:
	extz	xix                                   ; FAC232  extz XIX
	ld	(xix+47), hl                            ; FAC234  ld (XIX+0x2f),HL
	pushw	ix                                   ; FAC237  push IX
	calr (0xFAB79D - 0xFAC23B)                 ; FAC238  calr 0xfab79d
	pushw	ix                                   ; FAC23B  push IX
	lda	xbc, (0xD75E:24)                       ; FAC23C  lda XBC,0x00d75e
	push	xbc                                   ; FAC241  push XBC
	ld	a, (xix)                                ; FAC242  ld A,(XIX)
	extz	wa                                    ; FAC244  extz WA
	pushw	wa                                   ; FAC246  push WA
	call	0xFB7521                              ; FAC247  call 0xfb7521
	inc	8, xsp                                 ; FAC24B  inc 0,XSP
	inc	2, xsp                                 ; FAC24D  inc 2,XSP
	jr sub_FAC08D__FAC2A0                      ; FAC24F  jr T,0xfac2a0
sub_FAC08D__FAC251:
	ldw (xiz-2), 0x0000                        ; FAC251  ld (XIZ+0xfe),0x0000
	jr sub_FAC08D__FAC2A0                      ; FAC256  jr T,0xfac2a0
sub_FAC08D__FAC258:
	cps	hl, 1                                  ; FAC258  cp HL,1
	jr nz, sub_FAC08D__FAC29D                  ; FAC25A  jr NZ,0xfac29d
	extz	xix                                   ; FAC25C  extz XIX
	ld	c, (xix)                                ; FAC25E  ld C,(XIX)
	extz	bc                                    ; FAC260  extz BC
	ld	hl, bc                                  ; FAC262  ld HL,BC
	add	hl, 0x840                              ; FAC264  add HL,0x0840
	ld	xbc, 0x10C000                           ; FAC268  ld XBC,0x0010c000
	ld	(xiz-6), xbc                            ; FAC26D  ld (XIZ+0xfa),XBC
	ld	(xbc), hl                               ; FAC270  ld (XBC),HL
	ld	xbc, (xiz-6)                            ; FAC272  ld XBC,(XIZ+0xfa)
	extpfx5 0xB9, 0x02, 0x02, 0x00, 0xA2       ; FAC275  ld (XBC+0x02),0xa200
	nop                                        ; FAC27A  nop
	nop                                        ; FAC27B  nop
	nop                                        ; FAC27C  nop
	nop                                        ; FAC27D  nop
	nop                                        ; FAC27E  nop
	extz	xix                                   ; FAC27F  extz XIX
	ld	c, (xix)                                ; FAC281  ld C,(XIX)
	extz	bc                                    ; FAC283  extz BC
	ld	hl, bc                                  ; FAC285  ld HL,BC
	add	hl, 0x800                              ; FAC287  add HL,0x0800
	ld	xbc, 0x10C000                           ; FAC28B  ld XBC,0x0010c000
	ld	(xiz-6), xbc                            ; FAC290  ld (XIZ+0xfa),XBC
	ld	(xbc), hl                               ; FAC293  ld (XBC),HL
	ld	xbc, (xiz-6)                            ; FAC295  ld XBC,(XIZ+0xfa)
	extpfx5 0xB9, 0x02, 0x02, 0x80, 0xA2       ; FAC298  ld (XBC+0x02),0xa280
sub_FAC08D__FAC29D:
	decm	1, (xiz-2)                            ; FAC29D  decw 1,(XIZ+0xfe)
sub_FAC08D__FAC2A0:
	extz	xix                                   ; FAC2A0  extz XIX
	ld	bc, (xiz-2)                             ; FAC2A2  ld BC,(XIZ+0xfe)
	ld	(xix+45), bc                            ; FAC2A5  ld (XIX+0x2d),BC
	pop	xix                                    ; FAC2A8  pop XIX
	popw	de                                    ; FAC2A9  pop DE
	popw	hl                                    ; FAC2AA  pop HL
	unlk32 xiz                                 ; FAC2AB  unlk XIZ
	ret                                        ; FAC2AD  ret
; --------------------------------------------------------------------------
; sub_FAC2AE -- 0xFAC2AE..0xFAC34C (159 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAC3F4
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
;          reads 0x00151D, 0x00151F, 0x001521
; Evidence: the listing below is the byte-identical round-trip of 0xFAC2AE-0xFAC34C
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAC2AE:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAC2AE  link XIZ,0x0000
	push	xix                                   ; FAC2B2  push XIX
	lda	xix, (0xD75E:24)                       ; FAC2B3  lda XIX,0x00d75e
	extpfx5 0xBC, 0x02, 0x02, 0x00, 0x00       ; FAC2B8  ld (XIX+0x02),0x0000
	ld	bc, (0x151D:16)                       ; FAC2BD  ld BC,(0x151d)
	ld	(xix+14), bc                            ; FAC2C1  ld (XIX+0x0e),BC
	extpfx5 0xBC, 0x20, 0x02, 0x00, 0x00       ; FAC2C4  ld (XIX+0x20),0x0000
	extpfx5 0xBC, 0x22, 0x02, 0x00, 0x00       ; FAC2C9  ld (XIX+0x22),0x0000
	extpfx5 0xBC, 0x24, 0x02, 0x00, 0x00       ; FAC2CE  ld (XIX+0x24),0x0000
	extpfx5 0xBC, 0x08, 0x02, 0x7F, 0x01       ; FAC2D3  ld (XIX+0x08),0x017f
	extpfx5 0xBC, 0x0A, 0x02, 0x7F, 0x7F       ; FAC2D8  ld (XIX+0x0a),0x7f7f
	extpfx5 0xBC, 0x26, 0x02, 0x00, 0x00       ; FAC2DD  ld (XIX+0x26),0x0000
	extpfx5 0xBC, 0x28, 0x02, 0x00, 0x00       ; FAC2E2  ld (XIX+0x28),0x0000
	extpfx5 0xBC, 0x2A, 0x02, 0x00, 0x00       ; FAC2E7  ld (XIX+0x2a),0x0000
	extpfx5 0xBC, 0x16, 0x02, 0x00, 0x00       ; FAC2EC  ld (XIX+0x16),0x0000
	extpfx5 0xBC, 0x1E, 0x02, 0x00, 0x00       ; FAC2F1  ld (XIX+0x1e),0x0000
	extpfx5 0xBC, 0x10, 0x02, 0x00, 0x00       ; FAC2F6  ld (XIX+0x10),0x0000
	extpfx5 0xBC, 0x12, 0x02, 0x00, 0x00       ; FAC2FB  ld (XIX+0x12),0x0000
	extpfx5 0xBC, 0x0C, 0x02, 0x40, 0x00       ; FAC300  ld (XIX+0x0c),0x0040
	extpfx5 0xBC, 0x14, 0x02, 0x00, 0x00       ; FAC305  ld (XIX+0x14),0x0000
	extpfx5 0xBC, 0x06, 0x02, 0x00, 0x00       ; FAC30A  ld (XIX+0x06),0x0000
	extpfx5 0xBC, 0x18, 0x02, 0x7F, 0xFF       ; FAC30F  ld (XIX+0x18),0xff7f
	ld	bc, (0x151F:16)                       ; FAC314  ld BC,(0x151f)
	ld	(xix+26), bc                            ; FAC318  ld (XIX+0x1a),BC
	ld	bc, (0x151F:16)                       ; FAC31B  ld BC,(0x151f)
	ld	(xix+28), bc                            ; FAC31F  ld (XIX+0x1c),BC
	ld	bc, (0x1521:16)                       ; FAC322  ld BC,(0x1521)
	muls	bc, 2                                 ; FAC326  muls BC,0x0002
	add	xbc, 0xFDDE2B                          ; FAC32A  add XBC,0x00fdde2b
	ld	bc, (xbc)                               ; FAC330  ld BC,(XBC)
	add	bc, bc                                 ; FAC332  add BC,BC
	ld	(xix+4), bc                             ; FAC334  ld (XIX+0x04),BC
	ldb	c, 68                                  ; FAC337  ld C,0x44
	extpfx3 0x8E, 0x08, 0x43                   ; FAC339  mul BC,(XIZ+0x08)
	add	bc, 41                                 ; FAC33C  add BC,0x0029
	extz	xbc                                   ; FAC340  extz XBC
	extpfx7 0xF3, 0xE5, 0xCF, 0x3B, 0x02, 0x00, 0xF0 ; FAC342  ld (XBC+0x3bcf),0xf000
	pop	xix                                    ; FAC349  pop XIX
	unlk32 xiz                                 ; FAC34A  unlk XIZ
	ret                                        ; FAC34C  ret
; --------------------------------------------------------------------------
; sub_FAC34D -- 0xFAC34D..0xFAC42B (223 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFACABE
; Inputs:  frame `link XIZ,-20`; no positive frame slot is read
; Outputs: no absolute-addressed write.
; Calls:   0xFAC2AE = sub_FAC2AE, 0xFB3FA0 = VoiceRecords_InitFromAlloc
;          0xFB713A = Dev10C_WriteAllChanRegs, 0xFB732C = Dev10C_WriteReg_c
;          0xFB77EF = Dev104_WriteAllChanRegs, 0xFB7A58 = Dev104_WriteChanReg0
;          0xFC571A = Dev104_LoadStageBImage, 0xFC7DAF = sub_FC7DAF
; Evidence: the listing below is the byte-identical round-trip of 0xFAC34D-0xFAC42B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAC34D:
	link32 0xEE, 0x0C, 0xEC, 0xFF              ; FAC34D  link XIZ,0xffec
	pushw	hl                                   ; FAC351  push HL
	pushw	de                                   ; FAC352  push DE
	push	xix                                   ; FAC353  push XIX
	lda	xix, (0x14FE:16)                      ; FAC354  lda XIX,0x14fe
	extz	xix                                   ; FAC358  extz XIX
	ld	c, (xix+29)                             ; FAC35A  ld C,(XIX+0x1d)
	cps	c, 0                                   ; FAC35D  cp C,0
	jrl z, sub_FAC34D__FAC426                  ; FAC35F  jrl Z,0xfac426
	extz	xix                                   ; FAC362  extz XIX
	decm8	1, (xix+30)                          ; FAC364  dec 1,(XIX+0x1e)
	ld	c, (xix+30)                             ; FAC367  ld C,(XIX+0x1e)
	cps	c, 0                                   ; FAC36A  cp C,0
	jrl nz, sub_FAC34D__FAC426                 ; FAC36C  jrl NZ,0xfac426
	lda	xbc, (xiz-14)                          ; FAC36F  lda XBC,XIZ+0xf2
	push	xbc                                   ; FAC372  push XBC
	call	0xFB3FA0                              ; FAC373  call 0xfb3fa0
	ld	h, (xiz-4)                              ; FAC377  ld H,(XIZ+0xfc)
	pop	xiy                                    ; FAC37A  pop XIY
	cp	h, 64                                   ; FAC37B  cp H,0x40
	jrl nc, sub_FAC34D__FAC41D                 ; FAC37E  jrl NC,0xfac41d
	ld	d, h                                    ; FAC381  ld D,H
	ld	c, h                                    ; FAC383  ld C,H
	extz	bc                                    ; FAC385  extz BC
	ld	hl, bc                                  ; FAC387  ld HL,BC
	add	bc, 0x840                              ; FAC389  add BC,0x0840
	ld	(xiz-16), bc                            ; FAC38D  ld (XIZ+0xf0),BC
	ld	xwa, 0x10C000                           ; FAC390  ld XWA,0x0010c000
	ld	(xiz-20), xwa                           ; FAC395  ld (XIZ+0xec),XWA
	ld	(xwa), bc                               ; FAC398  ld (XWA),BC
	ld	xbc, (xiz-20)                           ; FAC39A  ld XBC,(XIZ+0xec)
	extpfx5 0xB9, 0x02, 0x02, 0x00, 0xFF       ; FAC39D  ld (XBC+0x02),0xff00
	nop                                        ; FAC3A2  nop
	nop                                        ; FAC3A3  nop
	nop                                        ; FAC3A4  nop
	nop                                        ; FAC3A5  nop
	nop                                        ; FAC3A6  nop
	ld	bc, hl                                  ; FAC3A7  ld BC,HL
	add	bc, 0x800                              ; FAC3A9  add BC,0x0800
	ld	(xiz-16), bc                            ; FAC3AD  ld (XIZ+0xf0),BC
	ld	xwa, 0x10C000                           ; FAC3B0  ld XWA,0x0010c000
	ld	(xiz-20), xwa                           ; FAC3B5  ld (XIZ+0xec),XWA
	ld	(xwa), bc                               ; FAC3B8  ld (XWA),BC
	ld	xbc, (xiz-20)                           ; FAC3BA  ld XBC,(XIZ+0xec)
	extpfx5 0xB9, 0x02, 0x02, 0x80, 0xFF       ; FAC3BD  ld (XBC+0x02),0xff80
	lda	xbc, (0xD7A2:24)                       ; FAC3C2  lda XBC,0x00d7a2
	push	xbc                                   ; FAC3C7  push XBC
	push	0                                     ; FAC3C8  push 0x00
	push	d                                     ; FAC3CA  push D
	call	0xFC7DAF                              ; FAC3CC  call 0xfc7daf
	lda	xbc, (0xD7A2:24)                       ; FAC3D0  lda XBC,0x00d7a2
	push	xbc                                   ; FAC3D5  push XBC
	pushw	hl                                   ; FAC3D6  push HL
	call	0xFB7A58                              ; FAC3D7  call 0xfb7a58
	lda	xbc, (0xD7A2:24)                       ; FAC3DB  lda XBC,0x00d7a2
	push	xbc                                   ; FAC3E0  push XBC
	call	0xFC571A                              ; FAC3E1  call 0xfc571a
	lda	xbc, (0xD7A2:24)                       ; FAC3E5  lda XBC,0x00d7a2
	push	xbc                                   ; FAC3EA  push XBC
	pushw	hl                                   ; FAC3EB  push HL
	call	0xFB77EF                              ; FAC3EC  call 0xfb77ef
	push	0                                     ; FAC3F0  push 0x00
	push	d                                     ; FAC3F2  push D
	calr (0xFAC2AE - 0xFAC3F7)                 ; FAC3F4  calr 0xfac2ae
	lda	xbc, (0xD75E:24)                       ; FAC3F7  lda XBC,0x00d75e
	push	xbc                                   ; FAC3FC  push XBC
	pushw	hl                                   ; FAC3FD  push HL
	call	0xFB713A                              ; FAC3FE  call 0xfb713a
	ldb	c, 68                                  ; FAC402  ld C,0x44
	mul8rr	c, d                                ; FAC404  mul BC,D
	add	bc, 41                                 ; FAC406  add BC,0x0029
	extz	xbc                                   ; FAC40A  extz XBC
	ld	wa, (xbc+0x3BCF)                        ; FAC40C  ld WA,(XBC+0x3bcf)
	pushw	wa                                   ; FAC411  push WA
	pushw	hl                                   ; FAC412  push HL
	call	0xFB732C                              ; FAC413  call 0xfb732c
	add	xsp, 34                                ; FAC417  add XSP,0x00000022
sub_FAC34D__FAC41D:
	extz	xix                                   ; FAC41D  extz XIX
	decm8	1, (xix+29)                          ; FAC41F  dec 1,(XIX+0x1d)
	ld	(xix+30), 4                             ; FAC422  ld (XIX+0x1e),0x04
sub_FAC34D__FAC426:
	pop	xix                                    ; FAC426  pop XIX
	popw	de                                    ; FAC427  pop DE
	popw	hl                                    ; FAC428  pop HL
	unlk32 xiz                                 ; FAC429  unlk XIZ
	ret                                        ; FAC42B  ret
; --------------------------------------------------------------------------
; sub_FAC42C -- 0xFAC42C..0xFAC525 (250 bytes)
;
; Called from: no site outside this module.
;          4 site(s) inside this module:
;          0xFAC831 0xFAC8C8 0xFAC960 0xFAC9FA
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: writes 0x00D79A, 0x00D79E
; Calls:   0xFA6110 = sub_FA6110, 0xFB582A = sub_FB582A
;          0xFB59D2 = sub_FB59D2, 0xFB7C27 = Dev10C_Slot2_WriteGateAndValue
;          0xFCB11B = Multiply32
; Evidence: the listing below is the byte-identical round-trip of 0xFAC42C-0xFAC525
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAC42C:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FAC42C  link XIZ,0xfffc
	pushw	hl                                   ; FAC430  push HL
	pushw	de                                   ; FAC431  push DE
	push	xix                                   ; FAC432  push XIX
	pushw	1                                    ; FAC433  push 0x0001
	push	0                                     ; FAC436  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAC438  push (XIZ+0x08)
	call	0xFB59D2                              ; FAC43B  call 0xfb59d2
	extz	xwa                                   ; FAC43F  extz XWA
	ld	(xiz-4), xwa                            ; FAC441  ld (XIZ+0xfc),XWA
	ld	bc, (xiz+10)                            ; FAC444  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FAC447  extz BC
	extz	xbc                                   ; FAC449  extz XBC
	push	xbc                                   ; FAC44B  push XBC
	push	xwa                                   ; FAC44C  push XWA
	call	0xFCB11B                              ; FAC44D  call 0xfcb11b
	ld	xix, xiy                                ; FAC451  ld XIX,XIY
	srl	xiy, 8                                 ; FAC453  srl 0x08,XIY
	ld	xix, xiy                                ; FAC456  ld XIX,XIY
	pop	xbc                                    ; FAC458  pop XBC
	cp	xiy, 44                                 ; FAC459  cp XIY,0x0000002c
	jr nc, sub_FAC42C__FAC480                  ; FAC45F  jr NC,0xfac480
	stiw_da	(0xD79A), 44                       ; FAC461  ld (0x00d79a),0x002c
	ld	bc, (xiz+8)                             ; FAC468  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAC46B  extz BC
	mul	bc, 0x12C                              ; FAC46D  mul BC,0x012c
	add	bc, 0x6B                               ; FAC471  add BC,0x006b
	extz	xbc                                   ; FAC475  extz XBC
	extpfx7 0xF3, 0xE5, 0x23, 0x15, 0x02, 0x2C, 0x00 ; FAC477  ld (XBC+0x1523),0x002c
	jr sub_FAC42C__FAC49B                      ; FAC47E  jr T,0xfac49b
sub_FAC42C__FAC480:
	ld	hl, ix                                  ; FAC480  ld HL,IX
	stw_da	(0xD79A), hl                        ; FAC482  ld (0x00d79a),HL
	ld	bc, (xiz+8)                             ; FAC487  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAC48A  extz BC
	mul	bc, 0x12C                              ; FAC48C  mul BC,0x012c
	add	bc, 0x6B                               ; FAC490  add BC,0x006b
	extz	xbc                                   ; FAC494  extz XBC
	ld	(xbc+0x1523), hl                        ; FAC496  ld (XBC+0x1523),HL
sub_FAC42C__FAC49B:
	pushw	1                                    ; FAC49B  push 0x0001
	push	0                                     ; FAC49E  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAC4A0  push (XIZ+0x08)
	call	0xFB582A                              ; FAC4A3  call 0xfb582a
	extz	xwa                                   ; FAC4A7  extz XWA
	ld	(xiz-4), xwa                            ; FAC4A9  ld (XIZ+0xfc),XWA
	ld	bc, (xiz+10)                            ; FAC4AC  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FAC4AF  extz BC
	extz	xbc                                   ; FAC4B1  extz XBC
	add	xbc, 0xFDE495                          ; FAC4B3  add XBC,0x00fde495
	ld	b, (xbc)                                ; FAC4B9  ld B,(XBC)
	extpfx3 0xC7, 0xF4, 0x9A                   ; FAC4BB  ld IYL,B
	extz	iy                                    ; FAC4BE  extz IY
	extz	xiy                                   ; FAC4C0  extz XIY
	push	xiy                                   ; FAC4C2  push XIY
	push	xwa                                   ; FAC4C3  push XWA
	call	0xFCB11B                              ; FAC4C4  call 0xfcb11b
	srl	xiy, 8                                 ; FAC4C8  srl 0x08,XIY
	ld	de, iy                                  ; FAC4CB  ld DE,IY
	stw_da	(0xD79E), iy                        ; FAC4CD  ld (0x00d79e),IY
	ld	bc, (xiz+8)                             ; FAC4D2  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAC4D5  extz BC
	mul	bc, 0x12C                              ; FAC4D7  mul BC,0x012c
	add	bc, 0x69                               ; FAC4DB  add BC,0x0069
	extz	xbc                                   ; FAC4DF  extz XBC
	ld	(xbc+0x1523), de                        ; FAC4E1  ld (XBC+0x1523),DE
	pushw	0                                    ; FAC4E6  push 0x0000
	pushw	13                                   ; FAC4E9  push 0x000d
	push	0                                     ; FAC4EC  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAC4EE  push (XIZ+0x08)
	call	0xFA6110                              ; FAC4F1  call 0xfa6110
	ld	ix, iy                                  ; FAC4F5  ld IX,IY
	ldw	hl, 0                                  ; FAC4F7  ld HL,0x0000
	inc	8, xsp                                 ; FAC4FA  inc 0,XSP
	inc	2, xsp                                 ; FAC4FC  inc 2,XSP
sub_FAC42C__FAC4FE:
	extz	xix                                   ; FAC4FE  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xEC, 0x22       ; FAC500  ld DE,(XIX+HL)
	and	de, 0xFF                               ; FAC505  and DE,0x00ff
	cp	de, 0x80                                ; FAC509  cp DE,0x0080
	jr nc, sub_FAC42C__FAC520                  ; FAC50D  jr NC,0xfac520
	lda	xbc, (0xD75E:24)                       ; FAC50F  lda XBC,0x00d75e
	push	xbc                                   ; FAC514  push XBC
	pushw	de                                   ; FAC515  push DE
	call	0xFB7C27                              ; FAC516  call 0xfb7c27
	inc	2, hl                                  ; FAC51A  inc 2,HL
	inc	6, xsp                                 ; FAC51C  inc 6,XSP
	jr sub_FAC42C__FAC4FE                      ; FAC51E  jr T,0xfac4fe
sub_FAC42C__FAC520:
	pop	xix                                    ; FAC520  pop XIX
	popw	de                                    ; FAC521  pop DE
	popw	hl                                    ; FAC522  pop HL
	unlk32 xiz                                 ; FAC523  unlk XIZ
	ret                                        ; FAC525  ret
; --------------------------------------------------------------------------
; sub_FAC526 -- 0xFAC526..0xFAC58E (105 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAC80D
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D79A, 0x00D79E
; Calls:   0xFA6110 = sub_FA6110, 0xFB582A = sub_FB582A
;          0xFB59D2 = sub_FB59D2, 0xFB7C27 = Dev10C_Slot2_WriteGateAndValue
; Evidence: the listing below is the byte-identical round-trip of 0xFAC526-0xFAC58E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAC526:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAC526  link XIZ,0x0000
	pushw	hl                                   ; FAC52A  push HL
	pushw	de                                   ; FAC52B  push DE
	push	xix                                   ; FAC52C  push XIX
	pushw	1                                    ; FAC52D  push 0x0001
	push	0                                     ; FAC530  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAC532  push (XIZ+0x08)
	call	0xFB59D2                              ; FAC535  call 0xfb59d2
	stw_da	(0xD79A), wa                        ; FAC539  ld (0x00d79a),WA
	pushw	1                                    ; FAC53E  push 0x0001
	push	0                                     ; FAC541  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAC543  push (XIZ+0x08)
	call	0xFB582A                              ; FAC546  call 0xfb582a
	stw_da	(0xD79E), wa                        ; FAC54A  ld (0x00d79e),WA
	pushw	0                                    ; FAC54F  push 0x0000
	pushw	13                                   ; FAC552  push 0x000d
	push	0                                     ; FAC555  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAC557  push (XIZ+0x08)
	call	0xFA6110                              ; FAC55A  call 0xfa6110
	ld	ix, iy                                  ; FAC55E  ld IX,IY
	ldw	hl, 0                                  ; FAC560  ld HL,0x0000
	inc	8, xsp                                 ; FAC563  inc 0,XSP
	inc	6, xsp                                 ; FAC565  inc 6,XSP
sub_FAC526__FAC567:
	extz	xix                                   ; FAC567  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xEC, 0x22       ; FAC569  ld DE,(XIX+HL)
	and	de, 0xFF                               ; FAC56E  and DE,0x00ff
	cp	de, 0x80                                ; FAC572  cp DE,0x0080
	jr nc, sub_FAC526__FAC589                  ; FAC576  jr NC,0xfac589
	lda	xbc, (0xD75E:24)                       ; FAC578  lda XBC,0x00d75e
	push	xbc                                   ; FAC57D  push XBC
	pushw	de                                   ; FAC57E  push DE
	call	0xFB7C27                              ; FAC57F  call 0xfb7c27
	inc	2, hl                                  ; FAC583  inc 2,HL
	inc	6, xsp                                 ; FAC585  inc 6,XSP
	jr sub_FAC526__FAC567                      ; FAC587  jr T,0xfac567
sub_FAC526__FAC589:
	pop	xix                                    ; FAC589  pop XIX
	popw	de                                    ; FAC58A  pop DE
	popw	hl                                    ; FAC58B  pop HL
	unlk32 xiz                                 ; FAC58C  unlk XIZ
	ret                                        ; FAC58E  ret
; --------------------------------------------------------------------------
; sub_FAC58F -- 0xFAC58F..0xFAC688 (250 bytes)
;
; Called from: no site outside this module.
;          4 site(s) inside this module:
;          0xFAC86F 0xFAC8F7 0xFAC988 0xFACA22
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: writes 0x00D79C, 0x00D7A0
; Calls:   0xFA6110 = sub_FA6110, 0xFB582A = sub_FB582A
;          0xFB59D2 = sub_FB59D2, 0xFB7D1D = Dev10C_Slot3_WriteGateAndValue
;          0xFCB11B = Multiply32
; Evidence: the listing below is the byte-identical round-trip of 0xFAC58F-0xFAC688
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAC58F:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FAC58F  link XIZ,0xfffc
	pushw	hl                                   ; FAC593  push HL
	pushw	de                                   ; FAC594  push DE
	push	xix                                   ; FAC595  push XIX
	pushw	0                                    ; FAC596  push 0x0000
	push	0                                     ; FAC599  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAC59B  push (XIZ+0x08)
	call	0xFB59D2                              ; FAC59E  call 0xfb59d2
	extz	xwa                                   ; FAC5A2  extz XWA
	ld	(xiz-4), xwa                            ; FAC5A4  ld (XIZ+0xfc),XWA
	ld	bc, (xiz+10)                            ; FAC5A7  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FAC5AA  extz BC
	extz	xbc                                   ; FAC5AC  extz XBC
	push	xbc                                   ; FAC5AE  push XBC
	push	xwa                                   ; FAC5AF  push XWA
	call	0xFCB11B                              ; FAC5B0  call 0xfcb11b
	ld	xix, xiy                                ; FAC5B4  ld XIX,XIY
	srl	xiy, 8                                 ; FAC5B6  srl 0x08,XIY
	ld	xix, xiy                                ; FAC5B9  ld XIX,XIY
	pop	xbc                                    ; FAC5BB  pop XBC
	cp	xiy, 28                                 ; FAC5BC  cp XIY,0x0000001c
	jr nc, sub_FAC58F__FAC5E3                  ; FAC5C2  jr NC,0xfac5e3
	stiw_da	(0xD79C), 28                       ; FAC5C4  ld (0x00d79c),0x001c
	ld	bc, (xiz+8)                             ; FAC5CB  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAC5CE  extz BC
	mul	bc, 0x12C                              ; FAC5D0  mul BC,0x012c
	add	bc, 0x67                               ; FAC5D4  add BC,0x0067
	extz	xbc                                   ; FAC5D8  extz XBC
	extpfx7 0xF3, 0xE5, 0x23, 0x15, 0x02, 0x1C, 0x00 ; FAC5DA  ld (XBC+0x1523),0x001c
	jr sub_FAC58F__FAC5FE                      ; FAC5E1  jr T,0xfac5fe
sub_FAC58F__FAC5E3:
	ld	hl, ix                                  ; FAC5E3  ld HL,IX
	stw_da	(0xD79C), hl                        ; FAC5E5  ld (0x00d79c),HL
	ld	bc, (xiz+8)                             ; FAC5EA  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAC5ED  extz BC
	mul	bc, 0x12C                              ; FAC5EF  mul BC,0x012c
	add	bc, 0x67                               ; FAC5F3  add BC,0x0067
	extz	xbc                                   ; FAC5F7  extz XBC
	ld	(xbc+0x1523), hl                        ; FAC5F9  ld (XBC+0x1523),HL
sub_FAC58F__FAC5FE:
	pushw	0                                    ; FAC5FE  push 0x0000
	push	0                                     ; FAC601  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAC603  push (XIZ+0x08)
	call	0xFB582A                              ; FAC606  call 0xfb582a
	extz	xwa                                   ; FAC60A  extz XWA
	ld	(xiz-4), xwa                            ; FAC60C  ld (XIZ+0xfc),XWA
	ld	bc, (xiz+10)                            ; FAC60F  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FAC612  extz BC
	extz	xbc                                   ; FAC614  extz XBC
	add	xbc, 0xFDE595                          ; FAC616  add XBC,0x00fde595
	ld	b, (xbc)                                ; FAC61C  ld B,(XBC)
	extpfx3 0xC7, 0xF4, 0x9A                   ; FAC61E  ld IYL,B
	extz	iy                                    ; FAC621  extz IY
	extz	xiy                                   ; FAC623  extz XIY
	push	xiy                                   ; FAC625  push XIY
	push	xwa                                   ; FAC626  push XWA
	call	0xFCB11B                              ; FAC627  call 0xfcb11b
	srl	xiy, 8                                 ; FAC62B  srl 0x08,XIY
	ld	de, iy                                  ; FAC62E  ld DE,IY
	stw_da	(0xD7A0), iy                        ; FAC630  ld (0x00d7a0),IY
	ld	bc, (xiz+8)                             ; FAC635  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAC638  extz BC
	mul	bc, 0x12C                              ; FAC63A  mul BC,0x012c
	add	bc, 0x65                               ; FAC63E  add BC,0x0065
	extz	xbc                                   ; FAC642  extz XBC
	ld	(xbc+0x1523), de                        ; FAC644  ld (XBC+0x1523),DE
	pushw	0                                    ; FAC649  push 0x0000
	pushw	12                                   ; FAC64C  push 0x000c
	push	0                                     ; FAC64F  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAC651  push (XIZ+0x08)
	call	0xFA6110                              ; FAC654  call 0xfa6110
	ld	ix, iy                                  ; FAC658  ld IX,IY
	ldw	hl, 0                                  ; FAC65A  ld HL,0x0000
	inc	8, xsp                                 ; FAC65D  inc 0,XSP
	inc	2, xsp                                 ; FAC65F  inc 2,XSP
sub_FAC58F__FAC661:
	extz	xix                                   ; FAC661  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xEC, 0x22       ; FAC663  ld DE,(XIX+HL)
	and	de, 0xFF                               ; FAC668  and DE,0x00ff
	cp	de, 0x80                                ; FAC66C  cp DE,0x0080
	jr nc, sub_FAC58F__FAC683                  ; FAC670  jr NC,0xfac683
	lda	xbc, (0xD75E:24)                       ; FAC672  lda XBC,0x00d75e
	push	xbc                                   ; FAC677  push XBC
	pushw	de                                   ; FAC678  push DE
	call	0xFB7D1D                              ; FAC679  call 0xfb7d1d
	inc	2, hl                                  ; FAC67D  inc 2,HL
	inc	6, xsp                                 ; FAC67F  inc 6,XSP
	jr sub_FAC58F__FAC661                      ; FAC681  jr T,0xfac661
sub_FAC58F__FAC683:
	pop	xix                                    ; FAC683  pop XIX
	popw	de                                    ; FAC684  pop DE
	popw	hl                                    ; FAC685  pop HL
	unlk32 xiz                                 ; FAC686  unlk XIZ
	ret                                        ; FAC688  ret
; --------------------------------------------------------------------------
; sub_FAC689 -- 0xFAC689..0xFAC6F1 (105 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAC840
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D79C, 0x00D7A0
; Calls:   0xFA6110 = sub_FA6110, 0xFB582A = sub_FB582A
;          0xFB59D2 = sub_FB59D2, 0xFB7D1D = Dev10C_Slot3_WriteGateAndValue
; Evidence: the listing below is the byte-identical round-trip of 0xFAC689-0xFAC6F1
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAC689:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAC689  link XIZ,0x0000
	pushw	hl                                   ; FAC68D  push HL
	pushw	de                                   ; FAC68E  push DE
	push	xix                                   ; FAC68F  push XIX
	pushw	0                                    ; FAC690  push 0x0000
	push	0                                     ; FAC693  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAC695  push (XIZ+0x08)
	call	0xFB59D2                              ; FAC698  call 0xfb59d2
	stw_da	(0xD79C), wa                        ; FAC69C  ld (0x00d79c),WA
	pushw	0                                    ; FAC6A1  push 0x0000
	push	0                                     ; FAC6A4  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAC6A6  push (XIZ+0x08)
	call	0xFB582A                              ; FAC6A9  call 0xfb582a
	stw_da	(0xD7A0), wa                        ; FAC6AD  ld (0x00d7a0),WA
	pushw	0                                    ; FAC6B2  push 0x0000
	pushw	12                                   ; FAC6B5  push 0x000c
	push	0                                     ; FAC6B8  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAC6BA  push (XIZ+0x08)
	call	0xFA6110                              ; FAC6BD  call 0xfa6110
	ld	ix, iy                                  ; FAC6C1  ld IX,IY
	ldw	hl, 0                                  ; FAC6C3  ld HL,0x0000
	inc	8, xsp                                 ; FAC6C6  inc 0,XSP
	inc	6, xsp                                 ; FAC6C8  inc 6,XSP
sub_FAC689__FAC6CA:
	extz	xix                                   ; FAC6CA  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xEC, 0x22       ; FAC6CC  ld DE,(XIX+HL)
	and	de, 0xFF                               ; FAC6D1  and DE,0x00ff
	cp	de, 0x80                                ; FAC6D5  cp DE,0x0080
	jr nc, sub_FAC689__FAC6EC                  ; FAC6D9  jr NC,0xfac6ec
	lda	xbc, (0xD75E:24)                       ; FAC6DB  lda XBC,0x00d75e
	push	xbc                                   ; FAC6E0  push XBC
	pushw	de                                   ; FAC6E1  push DE
	call	0xFB7D1D                              ; FAC6E2  call 0xfb7d1d
	inc	2, hl                                  ; FAC6E6  inc 2,HL
	inc	6, xsp                                 ; FAC6E8  inc 6,XSP
	jr sub_FAC689__FAC6CA                      ; FAC6EA  jr T,0xfac6ca
sub_FAC689__FAC6EC:
	pop	xix                                    ; FAC6EC  pop XIX
	popw	de                                    ; FAC6ED  pop DE
	popw	hl                                    ; FAC6EE  pop HL
	unlk32 xiz                                 ; FAC6EF  unlk XIZ
	ret                                        ; FAC6F1  ret
; --------------------------------------------------------------------------
; sub_FAC6F2 -- 0xFAC6F2..0xFAC79B (170 bytes)
;
; Called from: no site outside this module.
;          4 site(s) inside this module:
;          0xFAC87D 0xFAC903 0xFAC999 0xFACA33
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: writes 0x00D798
; Calls:   0xFA6110 = sub_FA6110, 0xFB5C77 = sub_FB5C77
;          0xFB7E9D = Dev10C_Slot1_StrobeGate, 0xFCB11B = Multiply32
; Evidence: the listing below is the byte-identical round-trip of 0xFAC6F2-0xFAC79B
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAC6F2:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FAC6F2  link XIZ,0xfffc
	pushw	hl                                   ; FAC6F6  push HL
	pushw	de                                   ; FAC6F7  push DE
	push	xix                                   ; FAC6F8  push XIX
	push	0                                     ; FAC6F9  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAC6FB  push (XIZ+0x08)
	call	0xFB5C77                              ; FAC6FE  call 0xfb5c77
	extz	xwa                                   ; FAC702  extz XWA
	ld	(xiz-4), xwa                            ; FAC704  ld (XIZ+0xfc),XWA
	ld	bc, (xiz+10)                            ; FAC707  ld BC,(XIZ+0x0a)
	extz	bc                                    ; FAC70A  extz BC
	extz	xbc                                   ; FAC70C  extz XBC
	push	xbc                                   ; FAC70E  push XBC
	push	xwa                                   ; FAC70F  push XWA
	call	0xFCB11B                              ; FAC710  call 0xfcb11b
	ld	xix, xiy                                ; FAC714  ld XIX,XIY
	srl	xiy, 8                                 ; FAC716  srl 0x08,XIY
	ld	xix, xiy                                ; FAC719  ld XIX,XIY
	popw	bc                                    ; FAC71B  pop BC
	cp	xiy, 28                                 ; FAC71C  cp XIY,0x0000001c
	jr nc, sub_FAC6F2__FAC743                  ; FAC722  jr NC,0xfac743
	stiw_da	(0xD798), 28                       ; FAC724  ld (0x00d798),0x001c
	ld	bc, (xiz+8)                             ; FAC72B  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAC72E  extz BC
	mul	bc, 0x12C                              ; FAC730  mul BC,0x012c
	add	bc, 0x6F                               ; FAC734  add BC,0x006f
	extz	xbc                                   ; FAC738  extz XBC
	extpfx7 0xF3, 0xE5, 0x23, 0x15, 0x02, 0x1C, 0x00 ; FAC73A  ld (XBC+0x1523),0x001c
	jr sub_FAC6F2__FAC75E                      ; FAC741  jr T,0xfac75e
sub_FAC6F2__FAC743:
	ld	hl, ix                                  ; FAC743  ld HL,IX
	stw_da	(0xD798), hl                        ; FAC745  ld (0x00d798),HL
	ld	bc, (xiz+8)                             ; FAC74A  ld BC,(XIZ+0x08)
	extz	bc                                    ; FAC74D  extz BC
	mul	bc, 0x12C                              ; FAC74F  mul BC,0x012c
	add	bc, 0x6F                               ; FAC753  add BC,0x006f
	extz	xbc                                   ; FAC757  extz XBC
	ld	(xbc+0x1523), hl                        ; FAC759  ld (XBC+0x1523),HL
sub_FAC6F2__FAC75E:
	pushw	0                                    ; FAC75E  push 0x0000
	pushw	16                                   ; FAC761  push 0x0010
	push	0                                     ; FAC764  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAC766  push (XIZ+0x08)
	call	0xFA6110                              ; FAC769  call 0xfa6110
	ld	ix, iy                                  ; FAC76D  ld IX,IY
	ldw	hl, 0                                  ; FAC76F  ld HL,0x0000
	jr sub_FAC6F2__FAC792                      ; FAC772  jr T,0xfac792
sub_FAC6F2__FAC774:
	extz	xix                                   ; FAC774  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xEC, 0x22       ; FAC776  ld DE,(XIX+HL)
	and	de, 0xFF                               ; FAC77B  and DE,0x00ff
	cp	de, 64                                  ; FAC77F  cp DE,0x0040
	jr nc, sub_FAC6F2__FAC796                  ; FAC783  jr NC,0xfac796
	lda	xbc, (0xD75E:24)                       ; FAC785  lda XBC,0x00d75e
	push	xbc                                   ; FAC78A  push XBC
	pushw	de                                   ; FAC78B  push DE
	call	0xFB7E9D                              ; FAC78C  call 0xfb7e9d
	inc	2, hl                                  ; FAC790  inc 2,HL
sub_FAC6F2__FAC792:
	inc	6, xsp                                 ; FAC792  inc 6,XSP
	jr sub_FAC6F2__FAC774                      ; FAC794  jr T,0xfac774
sub_FAC6F2__FAC796:
	pop	xix                                    ; FAC796  pop XIX
	popw	de                                    ; FAC797  pop DE
	popw	hl                                    ; FAC798  pop HL
	unlk32 xiz                                 ; FAC799  unlk XIZ
	ret                                        ; FAC79B  ret
; --------------------------------------------------------------------------
; sub_FAC79C -- 0xFAC79C..0xFAC7EE (83 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFAC844
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D798
; Calls:   0xFA6110 = sub_FA6110, 0xFB5C77 = sub_FB5C77
;          0xFB7E9D = Dev10C_Slot1_StrobeGate
; Evidence: the listing below is the byte-identical round-trip of 0xFAC79C-0xFAC7EE
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAC79C:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAC79C  link XIZ,0x0000
	pushw	hl                                   ; FAC7A0  push HL
	pushw	de                                   ; FAC7A1  push DE
	push	xix                                   ; FAC7A2  push XIX
	push	0                                     ; FAC7A3  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAC7A5  push (XIZ+0x08)
	call	0xFB5C77                              ; FAC7A8  call 0xfb5c77
	stw_da	(0xD798), wa                        ; FAC7AC  ld (0x00d798),WA
	pushw	0                                    ; FAC7B1  push 0x0000
	pushw	16                                   ; FAC7B4  push 0x0010
	push	0                                     ; FAC7B7  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FAC7B9  push (XIZ+0x08)
	call	0xFA6110                              ; FAC7BC  call 0xfa6110
	ld	ix, iy                                  ; FAC7C0  ld IX,IY
	ldw	hl, 0                                  ; FAC7C2  ld HL,0x0000
	inc	8, xsp                                 ; FAC7C5  inc 0,XSP
sub_FAC79C__FAC7C7:
	extz	xix                                   ; FAC7C7  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xEC, 0x22       ; FAC7C9  ld DE,(XIX+HL)
	and	de, 0xFF                               ; FAC7CE  and DE,0x00ff
	cp	de, 64                                  ; FAC7D2  cp DE,0x0040
	jr nc, sub_FAC79C__FAC7E9                  ; FAC7D6  jr NC,0xfac7e9
	lda	xbc, (0xD75E:24)                       ; FAC7D8  lda XBC,0x00d75e
	push	xbc                                   ; FAC7DD  push XBC
	pushw	de                                   ; FAC7DE  push DE
	call	0xFB7E9D                              ; FAC7DF  call 0xfb7e9d
	inc	2, hl                                  ; FAC7E3  inc 2,HL
	inc	6, xsp                                 ; FAC7E5  inc 6,XSP
	jr sub_FAC79C__FAC7C7                      ; FAC7E7  jr T,0xfac7c7
sub_FAC79C__FAC7E9:
	pop	xix                                    ; FAC7E9  pop XIX
	popw	de                                    ; FAC7EA  pop DE
	popw	hl                                    ; FAC7EB  pop HL
	unlk32 xiz                                 ; FAC7EC  unlk XIZ
	ret                                        ; FAC7EE  ret
; --------------------------------------------------------------------------
; sub_FAC7EF -- 0xFAC7EF..0xFAC887 (153 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFACBDC
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFAC42C = sub_FAC42C, 0xFAC526 = sub_FAC526
;          0xFAC58F = sub_FAC58F, 0xFAC689 = sub_FAC689
;          0xFAC6F2 = sub_FAC6F2, 0xFAC79C = sub_FAC79C
; Evidence: the listing below is the byte-identical round-trip of 0xFAC7EF-0xFAC887
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAC7EF:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAC7EF  link XIZ,0x0000
	pushw	hl                                   ; FAC7F3  push HL
	push	xde                                   ; FAC7F4  push XDE
	push	xix                                   ; FAC7F5  push XIX
	ld	de, (xiz+10)                            ; FAC7F6  ld DE,(XIZ+0x0a)
	ld	l, (xiz+8)                              ; FAC7F9  ld L,(XIZ+0x08)
	extz	xde                                   ; FAC7FC  extz XDE
	ld	h, (xde+0x72)                           ; FAC7FE  ld H,(XDE+0x72)
	cp	h, 79                                   ; FAC801  cp H,0x4f
	jr c, sub_FAC7EF__FAC813                   ; FAC804  jr C,0xfac813
	extz	xde                                   ; FAC806  extz XDE
	extpfx4 0x8A, 0x71, 0x3E, 0x08             ; FAC808  or (XDE+0x71),0x08
	pushw	hl                                   ; FAC80C  push HL
	calr (0xFAC526 - 0xFAC810)                 ; FAC80D  calr 0xfac526
	popw	bc                                    ; FAC810  pop BC
	jr sub_FAC7EF__FAC835                      ; FAC811  jr T,0xfac835
sub_FAC7EF__FAC813:
	ld	c, h                                    ; FAC813  ld C,H
	inc	1, c                                   ; FAC815  inc 1,C
	extz	xde                                   ; FAC817  extz XDE
	ld	(xde+0x72), c                           ; FAC819  ld (XDE+0x72),C
	extpfx4 0x8A, 0x71, 0x3C, 0xF7             ; FAC81C  and (XDE+0x71),0xf7
	ld	c, (xde+0x72)                           ; FAC820  ld C,(XDE+0x72)
	extz	bc                                    ; FAC823  extz BC
	extz	xbc                                   ; FAC825  extz XBC
	add	xbc, 0xFDE42B                          ; FAC827  add XBC,0x00fde42b
	ld	a, (xbc)                                ; FAC82D  ld A,(XBC)
	pushw	wa                                   ; FAC82F  push WA
	pushw	hl                                   ; FAC830  push HL
	calr (0xFAC42C - 0xFAC834)                 ; FAC831  calr 0xfac42c
	pop	xiy                                    ; FAC834  pop XIY
sub_FAC7EF__FAC835:
	extz	xde                                   ; FAC835  extz XDE
	ld	h, (xde+0x73)                           ; FAC837  ld H,(XDE+0x73)
	cp	h, 0x96                                 ; FAC83A  cp H,0x96
	jr c, sub_FAC7EF__FAC84A                   ; FAC83D  jr C,0xfac84a
	pushw	hl                                   ; FAC83F  push HL
	calr (0xFAC689 - 0xFAC843)                 ; FAC840  calr 0xfac689
	pushw	hl                                   ; FAC843  push HL
	calr (0xFAC79C - 0xFAC847)                 ; FAC844  calr 0xfac79c
	pop	xiy                                    ; FAC847  pop XIY
	jr sub_FAC7EF__FAC882                      ; FAC848  jr T,0xfac882
sub_FAC7EF__FAC84A:
	ld	c, h                                    ; FAC84A  ld C,H
	inc	1, c                                   ; FAC84C  inc 1,C
	extz	xde                                   ; FAC84E  extz XDE
	ld	(xde+0x73), c                           ; FAC850  ld (XDE+0x73),C
	extpfx4 0x8A, 0x71, 0x3C, 0xF7             ; FAC853  and (XDE+0x71),0xf7
	ld	c, (xde+0x73)                           ; FAC857  ld C,(XDE+0x73)
	extz	bc                                    ; FAC85A  extz BC
	div	c, 6                                   ; FAC85C  div C,0x06
	extz	bc                                    ; FAC85F  extz BC
	extz	xbc                                   ; FAC861  extz XBC
	ld	xix, xbc                                ; FAC863  ld XIX,XBC
	add	xbc, 0xFDE47B                          ; FAC865  add XBC,0x00fde47b
	ld	a, (xbc)                                ; FAC86B  ld A,(XBC)
	pushw	wa                                   ; FAC86D  push WA
	pushw	hl                                   ; FAC86E  push HL
	calr (0xFAC58F - 0xFAC872)                 ; FAC86F  calr 0xfac58f
	lda	xbc, (0xFDE47B:24)                     ; FAC872  lda XBC,0xfde47b
	add	xbc, xix                               ; FAC877  add XBC,XIX
	ld	a, (xbc)                                ; FAC879  ld A,(XBC)
	pushw	wa                                   ; FAC87B  push WA
	pushw	hl                                   ; FAC87C  push HL
	calr (0xFAC6F2 - 0xFAC880)                 ; FAC87D  calr 0xfac6f2
	inc	8, xsp                                 ; FAC880  inc 0,XSP
sub_FAC7EF__FAC882:
	pop	xix                                    ; FAC882  pop XIX
	pop	xde                                    ; FAC883  pop XDE
	popw	hl                                    ; FAC884  pop HL
	unlk32 xiz                                 ; FAC885  unlk XIZ
	ret                                        ; FAC887  ret
; --------------------------------------------------------------------------
; sub_FAC888 -- 0xFAC888..0xFAC90D (134 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFACC04
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFAC42C = sub_FAC42C, 0xFAC58F = sub_FAC58F
;          0xFAC6F2 = sub_FAC6F2
; Evidence: the listing below is the byte-identical round-trip of 0xFAC888-0xFAC90D
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAC888:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FAC888  link XIZ,0xfffc
	pushw	hl                                   ; FAC88C  push HL
	push	xde                                   ; FAC88D  push XDE
	push	xix                                   ; FAC88E  push XIX
	lda	xix, (0xFDE47B:24)                     ; FAC88F  lda XIX,0xfde47b
	ld	de, (xiz+10)                            ; FAC894  ld DE,(XIZ+0x0a)
	ld	l, (xiz+8)                              ; FAC897  ld L,(XIZ+0x08)
	extz	xde                                   ; FAC89A  extz XDE
	ld	h, (xde+0x72)                           ; FAC89C  ld H,(XDE+0x72)
	cps	h, 0                                   ; FAC89F  cp H,0
	jr nz, sub_FAC888__FAC8AB                  ; FAC8A1  jr NZ,0xfac8ab
	extz	xde                                   ; FAC8A3  extz XDE
	extpfx4 0x8A, 0x71, 0x3E, 0x10             ; FAC8A5  or (XDE+0x71),0x10
	jr sub_FAC888__FAC8CC                      ; FAC8A9  jr T,0xfac8cc
sub_FAC888__FAC8AB:
	ld	c, h                                    ; FAC8AB  ld C,H
	dec	1, c                                   ; FAC8AD  dec 1,C
	extz	xde                                   ; FAC8AF  extz XDE
	ld	(xde+0x72), c                           ; FAC8B1  ld (XDE+0x72),C
	extpfx4 0x8A, 0x71, 0x3C, 0xEF             ; FAC8B4  and (XDE+0x71),0xef
	ld	c, (xde+0x72)                           ; FAC8B8  ld C,(XDE+0x72)
	srl	c, 1                                   ; FAC8BB  srl 0x01,C
	extz	bc                                    ; FAC8BE  extz BC
	extz	xbc                                   ; FAC8C0  extz XBC
	add	xbc, xix                               ; FAC8C2  add XBC,XIX
	ld	a, (xbc)                                ; FAC8C4  ld A,(XBC)
	pushw	wa                                   ; FAC8C6  push WA
	pushw	hl                                   ; FAC8C7  push HL
	calr (0xFAC42C - 0xFAC8CB)                 ; FAC8C8  calr 0xfac42c
	pop	xiy                                    ; FAC8CB  pop XIY
sub_FAC888__FAC8CC:
	extz	xde                                   ; FAC8CC  extz XDE
	ld	h, (xde+0x73)                           ; FAC8CE  ld H,(XDE+0x73)
	cps	h, 0                                   ; FAC8D1  cp H,0
	jr z, sub_FAC888__FAC908                   ; FAC8D3  jr Z,0xfac908
	ld	c, h                                    ; FAC8D5  ld C,H
	dec	1, c                                   ; FAC8D7  dec 1,C
	extz	xde                                   ; FAC8D9  extz XDE
	ld	(xde+0x73), c                           ; FAC8DB  ld (XDE+0x73),C
	extpfx4 0x8A, 0x71, 0x3C, 0xEF             ; FAC8DE  and (XDE+0x71),0xef
	ld	c, (xde+0x73)                           ; FAC8E2  ld C,(XDE+0x73)
	extz	bc                                    ; FAC8E5  extz BC
	div	c, 5                                   ; FAC8E7  div C,0x05
	extz	bc                                    ; FAC8EA  extz BC
	extz	xbc                                   ; FAC8EC  extz XBC
	ld	(xiz-4), xbc                            ; FAC8EE  ld (XIZ+0xfc),XBC
	add	xbc, xix                               ; FAC8F1  add XBC,XIX
	ld	a, (xbc)                                ; FAC8F3  ld A,(XBC)
	pushw	wa                                   ; FAC8F5  push WA
	pushw	hl                                   ; FAC8F6  push HL
	calr (0xFAC58F - 0xFAC8FA)                 ; FAC8F7  calr 0xfac58f
	ld	xbc, xix                                ; FAC8FA  ld XBC,XIX
	extpfx3 0xAE, 0xFC, 0x81                   ; FAC8FC  add XBC,(XIZ+0xfc)
	ld	a, (xbc)                                ; FAC8FF  ld A,(XBC)
	pushw	wa                                   ; FAC901  push WA
	pushw	hl                                   ; FAC902  push HL
	calr (0xFAC6F2 - 0xFAC906)                 ; FAC903  calr 0xfac6f2
	inc	8, xsp                                 ; FAC906  inc 0,XSP
sub_FAC888__FAC908:
	pop	xix                                    ; FAC908  pop XIX
	pop	xde                                    ; FAC909  pop XDE
	popw	hl                                    ; FAC90A  pop HL
	unlk32 xiz                                 ; FAC90B  unlk XIZ
	ret                                        ; FAC90D  ret
; --------------------------------------------------------------------------
; sub_FAC90E -- 0xFAC90E..0xFAC9A5 (152 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFACC14
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFAC42C = sub_FAC42C, 0xFAC58F = sub_FAC58F
;          0xFAC6F2 = sub_FAC6F2
; Evidence: the listing below is the byte-identical round-trip of 0xFAC90E-0xFAC9A5
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAC90E:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FAC90E  link XIZ,0x0000
	pushw	hl                                   ; FAC912  push HL
	pushw	de                                   ; FAC913  push DE
	push	xix                                   ; FAC914  push XIX
	ld	ix, (xiz+10)                            ; FAC915  ld IX,(XIZ+0x0a)
	ld	d, (xiz+8)                              ; FAC918  ld D,(XIZ+0x08)
	extz	xix                                   ; FAC91B  extz XIX
	extpfx4 0x8C, 0x71, 0x3C, 0xE7             ; FAC91D  and (XIX+0x71),0xe7
	ld	c, (xix+0x72)                           ; FAC921  ld C,(XIX+0x72)
	extz	bc                                    ; FAC924  extz BC
	extz	xbc                                   ; FAC926  extz XBC
	add	xbc, 0xFDE42B                          ; FAC928  add XBC,0x00fde42b
	ld	l, (xbc)                                ; FAC92E  ld L,(XBC)
	ldb	h, 25                                  ; FAC930  ld H,0x19
sub_FAC90E__FAC932:
	ld	c, h                                    ; FAC932  ld C,H
	extz	bc                                    ; FAC934  extz BC
	extz	xbc                                   ; FAC936  extz XBC
	add	xbc, 0xFDE47B                          ; FAC938  add XBC,0x00fde47b
	ld	a, (xbc)                                ; FAC93E  ld A,(XBC)
	cp	l, a                                    ; FAC940  cp L,A
	jr nc, sub_FAC90E__FAC948                  ; FAC942  jr NC,0xfac948
	dec	1, h                                   ; FAC944  dec 1,H
	jr sub_FAC90E__FAC932                      ; FAC946  jr T,0xfac932
sub_FAC90E__FAC948:
	extz	xix                                   ; FAC948  extz XIX
	ld	(xix+0x72), h                           ; FAC94A  ld (XIX+0x72),H
	ld	c, l                                    ; FAC94D  ld C,L
	extz	bc                                    ; FAC94F  extz BC
	extz	xbc                                   ; FAC951  extz XBC
	add	xbc, 0xFDE42B                          ; FAC953  add XBC,0x00fde42b
	ld	a, (xbc)                                ; FAC959  ld A,(XBC)
	pushw	wa                                   ; FAC95B  push WA
	push	0                                     ; FAC95C  push 0x00
	push	d                                     ; FAC95E  push D
	calr (0xFAC42C - 0xFAC963)                 ; FAC960  calr 0xfac42c
	ld	c, (xix+0x73)                           ; FAC963  ld C,(XIX+0x73)
	extz	bc                                    ; FAC966  extz BC
	div	c, 6                                   ; FAC968  div C,0x06
	ld	h, c                                    ; FAC96B  ld H,C
	mul	c, 5                                   ; FAC96D  mul C,0x05
	ld	(xix+0x73), c                           ; FAC970  ld (XIX+0x73),C
	ld	c, h                                    ; FAC973  ld C,H
	extz	bc                                    ; FAC975  extz BC
	extz	xbc                                   ; FAC977  extz XBC
	ld	xix, xbc                                ; FAC979  ld XIX,XBC
	add	xbc, 0xFDE47B                          ; FAC97B  add XBC,0x00fde47b
	ld	a, (xbc)                                ; FAC981  ld A,(XBC)
	pushw	wa                                   ; FAC983  push WA
	push	0                                     ; FAC984  push 0x00
	push	d                                     ; FAC986  push D
	calr (0xFAC58F - 0xFAC98B)                 ; FAC988  calr 0xfac58f
	lda	xbc, (0xFDE47B:24)                     ; FAC98B  lda XBC,0xfde47b
	add	xbc, xix                               ; FAC990  add XBC,XIX
	ld	a, (xbc)                                ; FAC992  ld A,(XBC)
	pushw	wa                                   ; FAC994  push WA
	push	0                                     ; FAC995  push 0x00
	push	d                                     ; FAC997  push D
	calr (0xFAC6F2 - 0xFAC99C)                 ; FAC999  calr 0xfac6f2
	inc	8, xsp                                 ; FAC99C  inc 0,XSP
	inc	4, xsp                                 ; FAC99E  inc 4,XSP
	pop	xix                                    ; FAC9A0  pop XIX
	popw	de                                    ; FAC9A1  pop DE
	popw	hl                                    ; FAC9A2  pop HL
	unlk32 xiz                                 ; FAC9A3  unlk XIZ
	ret                                        ; FAC9A5  ret
; --------------------------------------------------------------------------
; sub_FAC9A6 -- 0xFAC9A6..0xFACA3F (154 bytes)
;
; Called from: no site outside this module.
;          1 site(s) inside this module:
;          0xFACBEC
; Inputs:  frame `link XIZ,-4`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: no absolute-addressed write.
; Calls:   0xFAC42C = sub_FAC42C, 0xFAC58F = sub_FAC58F
;          0xFAC6F2 = sub_FAC6F2
; Evidence: the listing below is the byte-identical round-trip of 0xFAC9A6-0xFACA3F
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FAC9A6:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FAC9A6  link XIZ,0xfffc
	pushw	hl                                   ; FAC9AA  push HL
	pushw	de                                   ; FAC9AB  push DE
	push	xix                                   ; FAC9AC  push XIX
	ld	ix, (xiz+10)                            ; FAC9AD  ld IX,(XIZ+0x0a)
	ld	d, (xiz+8)                              ; FAC9B0  ld D,(XIZ+0x08)
	extz	xix                                   ; FAC9B3  extz XIX
	extpfx4 0x8C, 0x71, 0x3C, 0xE7             ; FAC9B5  and (XIX+0x71),0xe7
	ld	c, (xix+0x72)                           ; FAC9B9  ld C,(XIX+0x72)
	srl	c, 1                                   ; FAC9BC  srl 0x01,C
	extz	bc                                    ; FAC9BF  extz BC
	extz	xbc                                   ; FAC9C1  extz XBC
	add	xbc, 0xFDE47B                          ; FAC9C3  add XBC,0x00fde47b
	ld	h, (xbc)                                ; FAC9C9  ld H,(XBC)
	ldb	l, 0                                   ; FAC9CB  ld L,0x00
sub_FAC9A6__FAC9CD:
	ld	c, l                                    ; FAC9CD  ld C,L
	extz	bc                                    ; FAC9CF  extz BC
	extz	xbc                                   ; FAC9D1  extz XBC
	ld	(xiz-4), xbc                            ; FAC9D3  ld (XIZ+0xfc),XBC
	add	xbc, 0xFDE42B                          ; FAC9D6  add XBC,0x00fde42b
	ld	a, (xbc)                                ; FAC9DC  ld A,(XBC)
	cp	h, a                                    ; FAC9DE  cp H,A
	jr ule, sub_FAC9A6__FAC9E6                 ; FAC9E0  jr ULE,0xfac9e6
	inc	1, l                                   ; FAC9E2  inc 1,L
	jr sub_FAC9A6__FAC9CD                      ; FAC9E4  jr T,0xfac9cd
sub_FAC9A6__FAC9E6:
	extz	xix                                   ; FAC9E6  extz XIX
	ld	(xix+0x72), l                           ; FAC9E8  ld (XIX+0x72),L
	lda	xbc, (0xFDE47B:24)                     ; FAC9EB  lda XBC,0xfde47b
	extpfx3 0xAE, 0xFC, 0x81                   ; FAC9F0  add XBC,(XIZ+0xfc)
	ld	a, (xbc)                                ; FAC9F3  ld A,(XBC)
	pushw	wa                                   ; FAC9F5  push WA
	push	0                                     ; FAC9F6  push 0x00
	push	d                                     ; FAC9F8  push D
	calr (0xFAC42C - 0xFAC9FD)                 ; FAC9FA  calr 0xfac42c
	ld	c, (xix+0x73)                           ; FAC9FD  ld C,(XIX+0x73)
	extz	bc                                    ; FACA00  extz BC
	div	c, 5                                   ; FACA02  div C,0x05
	ld	h, c                                    ; FACA05  ld H,C
	mul	c, 6                                   ; FACA07  mul C,0x06
	ld	(xix+0x73), c                           ; FACA0A  ld (XIX+0x73),C
	ld	c, h                                    ; FACA0D  ld C,H
	extz	bc                                    ; FACA0F  extz BC
	extz	xbc                                   ; FACA11  extz XBC
	ld	xix, xbc                                ; FACA13  ld XIX,XBC
	add	xbc, 0xFDE47B                          ; FACA15  add XBC,0x00fde47b
	ld	a, (xbc)                                ; FACA1B  ld A,(XBC)
	pushw	wa                                   ; FACA1D  push WA
	push	0                                     ; FACA1E  push 0x00
	push	d                                     ; FACA20  push D
	calr (0xFAC58F - 0xFACA25)                 ; FACA22  calr 0xfac58f
	lda	xbc, (0xFDE47B:24)                     ; FACA25  lda XBC,0xfde47b
	add	xbc, xix                               ; FACA2A  add XBC,XIX
	ld	a, (xbc)                                ; FACA2C  ld A,(XBC)
	pushw	wa                                   ; FACA2E  push WA
	push	0                                     ; FACA2F  push 0x00
	push	d                                     ; FACA31  push D
	calr (0xFAC6F2 - 0xFACA36)                 ; FACA33  calr 0xfac6f2
	inc	8, xsp                                 ; FACA36  inc 0,XSP
	inc	4, xsp                                 ; FACA38  inc 4,XSP
	pop	xix                                    ; FACA3A  pop XIX
	popw	de                                    ; FACA3B  pop DE
	popw	hl                                    ; FACA3C  pop HL
	unlk32 xiz                                 ; FACA3D  unlk XIZ
	ret                                        ; FACA3F  ret
; --------------------------------------------------------------------------
; sub_FACA40 -- 0xFACA40..0xFACAB6 (119 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB05F7 in Toggle14FE_AndDispatch
; Inputs:  no frame and no argument slot read.
; Outputs: no absolute-addressed write.
; Calls:   0xFA6EA5 = sub_FA6EA5, 0xFABE30 = Voice_RecomputeAllThreeBaseCurves
;          0xFAC026 = sub_FAC026, 0xFB3D09 = VoiceQuery_Tag00_All
;          0xFB3D26 = Voice_Retire_Mode20, 0xFB6F2C = sub_FB6F2C
; Voice record: touches voice_record[+0x00(r), +0x23(r), +0x2B(rw)] -- pointer built in place.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFACA40-0xFACAB6
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FACA40:
	push	xhl                                   ; FACA40  push XHL
	pushw	de                                   ; FACA41  push DE
	push	xix                                   ; FACA42  push XIX
	calr (0xFABE30 - 0xFACA46)                 ; FACA43  calr 0xfabe30
	call	0xFB3D09                              ; FACA46  call 0xfb3d09
	ld	xix, xiy                                ; FACA4A  ld XIX,XIY
	inc	5, xiy                                 ; FACA4C  inc 5,XIY
	ld	xix, xiy                                ; FACA4E  ld XIX,XIY
sub_FACA40__FACA50:
	ld	h, (xix)                                ; FACA50  ld H,(XIX)
	cp	h, 64                                   ; FACA52  cp H,0x40
	jr nc, sub_FACA40__FACAB3                  ; FACA55  jr NC,0xfacab3
	ldb	c, 68                                  ; FACA57  ld C,0x44
	mul8rr	c, h                                ; FACA59  mul BC,H
	ld	de, bc                                  ; FACA5B  ld DE,BC
	ldw	hl, 0x3BCF                             ; FACA5D  ld HL,0x3bcf
	add	hl, bc                                 ; FACA60  add HL,BC
	extz	xhl                                   ; FACA62  extz XHL
	ld	bc, (xhl+35)                            ; FACA64  ld BC,(XHL+0x23)
	extz	xbc                                   ; FACA67  extz XBC
	ld	wa, (xbc+9)                             ; FACA69  ld WA,(XBC+0x09)
	and	wa, 0x8000                             ; FACA6C  and WA,0x8000
	jr z, sub_FACA40__FACA84                   ; FACA70  jr Z,0xfaca84
	extz	xhl                                   ; FACA72  extz XHL
	ld	bc, (xhl+43)                            ; FACA74  ld BC,(XHL+0x2b)
	and	bc, 0x8080                             ; FACA77  and BC,0x8080
	jr z, sub_FACA40__FACAA5                   ; FACA7B  jr Z,0xfacaa5
	pushw	hl                                   ; FACA7D  push HL
	calr (0xFAC026 - 0xFACA81)                 ; FACA7E  calr 0xfac026
	popw	bc                                    ; FACA81  pop BC
	jr sub_FACA40__FACAA5                      ; FACA82  jr T,0xfacaa5
sub_FACA40__FACA84:
	extz	xhl                                   ; FACA84  extz XHL
	ld	bc, (xhl+43)                            ; FACA86  ld BC,(XHL+0x2b)
	and	bc, 0x8080                             ; FACA89  and BC,0x8080
	jr z, sub_FACA40__FACAA5                   ; FACA8D  jr Z,0xfacaa5
	extz	xhl                                   ; FACA8F  extz XHL
	ld	c, (xhl)                                ; FACA91  ld C,(XHL)
	pushw	bc                                   ; FACA93  push BC
	call	0xFA6EA5                              ; FACA94  call 0xfa6ea5
	ld	c, (xhl)                                ; FACA98  ld C,(XHL)
	pushw	bc                                   ; FACA9A  push BC
	call	0xFB3D26                              ; FACA9B  call 0xfb3d26
	extpfx5 0xBB, 0x2B, 0x02, 0x00, 0x00       ; FACA9F  ld (XHL+0x2b),0x0000
	pop	xiy                                    ; FACAA4  pop XIY
sub_FACA40__FACAA5:
	ld	c, (xix)                                ; FACAA5  ld C,(XIX)
	extz	bc                                    ; FACAA7  extz BC
	pushw	bc                                   ; FACAA9  push BC
	call	0xFB6F2C                              ; FACAAA  call 0xfb6f2c
	inc	1, xix                                 ; FACAAE  inc 1,XIX
	popw	bc                                    ; FACAB0  pop BC
	jr sub_FACA40__FACA50                      ; FACAB1  jr T,0xfaca50
sub_FACA40__FACAB3:
	pop	xix                                    ; FACAB3  pop XIX
	popw	de                                    ; FACAB4  pop DE
	pop	xhl                                    ; FACAB5  pop XHL
	ret                                        ; FACAB6  ret
; --------------------------------------------------------------------------
; sub_FACAB7 -- 0xFACAB7..0xFACC3E (392 bytes)
;
; Called from: 1 site(s) outside this module:
;          0xFB0601 in Toggle14FE_AndDispatch__FB05FD
; Inputs:  frame `link XIZ,-4`; no positive frame slot is read
; Outputs: no absolute-addressed write.
; Calls:   0xFA6EA5 = sub_FA6EA5, 0xFAC026 = sub_FAC026
;          0xFAC08D = sub_FAC08D, 0xFAC34D = sub_FAC34D
;          0xFAC7EF = sub_FAC7EF, 0xFAC888 = sub_FAC888
;          0xFAC90E = sub_FAC90E, 0xFAC9A6 = sub_FAC9A6
;          0xFB3D09 = VoiceQuery_Tag00_All, 0xFB3D26 = Voice_Retire_Mode20
;          0xFB7A73 = Dev104_SetChanRegs_00C0_0100_0240, 0xFB7AC9 = Dev104_SetChanRegs_00C0_0100
;          0xFC7C0D = sub_FC7C0D
; Voice record: touches voice_record[+0x00(r), +0x23(r), +0x2B(rw), +0x2D(rw)] -- pointer built in place.  Field map above VoiceRecords_InitFromAlloc.
; Evidence: the listing below is the byte-identical round-trip of 0xFACAB7-0xFACC3E
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FACAB7:
	link32 0xEE, 0x0C, 0xFC, 0xFF              ; FACAB7  link XIZ,0xfffc
	push	xhl                                   ; FACABB  push XHL
	pushw	de                                   ; FACABC  push DE
	push	xix                                   ; FACABD  push XIX
	calr (0xFAC34D - 0xFACAC1)                 ; FACABE  calr 0xfac34d
	call	0xFB3D09                              ; FACAC1  call 0xfb3d09
	ld	xix, xiy                                ; FACAC5  ld XIX,XIY
	inc	5, xiy                                 ; FACAC7  inc 5,XIY
	ld	xix, xiy                                ; FACAC9  ld XIX,XIY
sub_FACAB7__FACACB:
	ld	h, (xix)                                ; FACACB  ld H,(XIX)
	cp	h, 64                                   ; FACACD  cp H,0x40
	jrl nc, sub_FACAB7__FACBA1                 ; FACAD0  jrl NC,0xfacba1
	ldb	c, 68                                  ; FACAD3  ld C,0x44
	mul8rr	c, h                                ; FACAD5  mul BC,H
	ld	(xiz-4), bc                             ; FACAD7  ld (XIZ+0xfc),BC
	ldw	hl, 0x3BCF                             ; FACADA  ld HL,0x3bcf
	add	hl, bc                                 ; FACADD  add HL,BC
	extz	xhl                                   ; FACADF  extz XHL
	ld	bc, (xhl+35)                            ; FACAE1  ld BC,(XHL+0x23)
	extz	xbc                                   ; FACAE4  extz XBC
	ld	de, (xbc+9)                             ; FACAE6  ld DE,(XBC+0x09)
	ld	bc, de                                  ; FACAE9  ld BC,DE
	and	bc, 0x8000                             ; FACAEB  and BC,0x8000
	jr z, sub_FACAB7__FACB1C                   ; FACAEF  jr Z,0xfacb1c
	ld	bc, de                                  ; FACAF1  ld BC,DE
	and	bc, 0x2000                             ; FACAF3  and BC,0x2000
	jr nz, sub_FACAB7__FACB1C                  ; FACAF7  jr NZ,0xfacb1c
	extz	xhl                                   ; FACAF9  extz XHL
	ld	bc, (xhl+43)                            ; FACAFB  ld BC,(XHL+0x2b)
	and	bc, 0x8080                             ; FACAFE  and BC,0x8080
	jr z, sub_FACAB7__FACB0A                   ; FACB02  jr Z,0xfacb0a
	pushw	hl                                   ; FACB04  push HL
	calr (0xFAC026 - 0xFACB08)                 ; FACB05  calr 0xfac026
	jr sub_FACAB7__FACB19                      ; FACB08  jr T,0xfacb19
sub_FACAB7__FACB0A:
	extz	xhl                                   ; FACB0A  extz XHL
	ld	bc, (xhl+45)                            ; FACB0C  ld BC,(XHL+0x2d)
	and	bc, 0x8000                             ; FACB0F  and BC,0x8000
	jr z, sub_FACAB7__FACB5F                   ; FACB13  jr Z,0xfacb5f
	pushw	hl                                   ; FACB15  push HL
	calr (0xFAC08D - 0xFACB19)                 ; FACB16  calr 0xfac08d
sub_FACAB7__FACB19:
	popw	bc                                    ; FACB19  pop BC
	jr sub_FACAB7__FACB5F                      ; FACB1A  jr T,0xfacb5f
sub_FACAB7__FACB1C:
	extz	xhl                                   ; FACB1C  extz XHL
	ld	bc, (xhl+43)                            ; FACB1E  ld BC,(XHL+0x2b)
	and	bc, 0x8080                             ; FACB21  and BC,0x8080
	jr z, sub_FACAB7__FACB3E                   ; FACB25  jr Z,0xfacb3e
	extz	xhl                                   ; FACB27  extz XHL
	ld	c, (xhl)                                ; FACB29  ld C,(XHL)
	pushw	bc                                   ; FACB2B  push BC
	call	0xFA6EA5                              ; FACB2C  call 0xfa6ea5
	ld	c, (xhl)                                ; FACB30  ld C,(XHL)
	pushw	bc                                   ; FACB32  push BC
	call	0xFB3D26                              ; FACB33  call 0xfb3d26
	extpfx5 0xBB, 0x2B, 0x02, 0x00, 0x00       ; FACB37  ld (XHL+0x2b),0x0000
	jr sub_FACAB7__FACB5E                      ; FACB3C  jr T,0xfacb5e
sub_FACAB7__FACB3E:
	extz	xhl                                   ; FACB3E  extz XHL
	ld	bc, (xhl+45)                            ; FACB40  ld BC,(XHL+0x2d)
	and	bc, 0x8000                             ; FACB43  and BC,0x8000
	jr z, sub_FACAB7__FACB5F                   ; FACB47  jr Z,0xfacb5f
	extz	xhl                                   ; FACB49  extz XHL
	ld	c, (xhl)                                ; FACB4B  ld C,(XHL)
	pushw	bc                                   ; FACB4D  push BC
	call	0xFA6EA5                              ; FACB4E  call 0xfa6ea5
	ld	c, (xhl)                                ; FACB52  ld C,(XHL)
	pushw	bc                                   ; FACB54  push BC
	call	0xFB3D26                              ; FACB55  call 0xfb3d26
	extpfx5 0xBB, 0x2D, 0x02, 0x00, 0x00       ; FACB59  ld (XHL+0x2d),0x0000
sub_FACAB7__FACB5E:
	pop	xiy                                    ; FACB5E  pop XIY
sub_FACAB7__FACB5F:
	lda	xbc, (0xD7A2:24)                       ; FACB5F  lda XBC,0x00d7a2
	push	xbc                                   ; FACB64  push XBC
	ld	a, (xix)                                ; FACB65  ld A,(XIX)
	pushw	wa                                   ; FACB67  push WA
	call	0xFC7C0D                              ; FACB68  call 0xfc7c0d
	extz	wa                                    ; FACB6C  extz WA
	inc	6, xsp                                 ; FACB6E  inc 6,XSP
	cps	wa, 1                                  ; FACB70  cp WA,1
	jr z, sub_FACAB7__FACB7A                   ; FACB72  jr Z,0xfacb7a
	cps	wa, 2                                  ; FACB74  cp WA,2
	jr z, sub_FACAB7__FACB8B                   ; FACB76  jr Z,0xfacb8b
	jr sub_FACAB7__FACB9C                      ; FACB78  jr T,0xfacb9c
sub_FACAB7__FACB7A:
	lda	xbc, (0xD7A2:24)                       ; FACB7A  lda XBC,0x00d7a2
	push	xbc                                   ; FACB7F  push XBC
	ld	a, (xix)                                ; FACB80  ld A,(XIX)
	extz	wa                                    ; FACB82  extz WA
	pushw	wa                                   ; FACB84  push WA
	call	0xFB7A73                              ; FACB85  call 0xfb7a73
	jr sub_FACAB7__FACB9A                      ; FACB89  jr T,0xfacb9a
sub_FACAB7__FACB8B:
	lda	xbc, (0xD7A2:24)                       ; FACB8B  lda XBC,0x00d7a2
	push	xbc                                   ; FACB90  push XBC
	ld	a, (xix)                                ; FACB91  ld A,(XIX)
	extz	wa                                    ; FACB93  extz WA
	pushw	wa                                   ; FACB95  push WA
	call	0xFB7AC9                              ; FACB96  call 0xfb7ac9
sub_FACAB7__FACB9A:
	inc	6, xsp                                 ; FACB9A  inc 6,XSP
sub_FACAB7__FACB9C:
	inc	1, xix                                 ; FACB9C  inc 1,XIX
	jrl sub_FACAB7__FACACB                     ; FACB9E  jrl T,0xfacacb
sub_FACAB7__FACBA1:
	ldb	d, 0                                   ; FACBA1  ld D,0x00
	ldw	ix, 0                                  ; FACBA3  ld IX,0x0000
	ldw (xiz-2), 0x0009                        ; FACBA6  ld (XIZ+0xfe),0x0009
sub_FACAB7__FACBAB:
	ld	(xiz-4), ix                             ; FACBAB  ld (XIZ+0xfc),IX
	ldw	hl, 0x1523                             ; FACBAE  ld HL,0x1523
	ld	bc, (xiz-4)                             ; FACBB1  ld BC,(XIZ+0xfc)
	add	hl, bc                                 ; FACBB4  add HL,BC
	extz	xhl                                   ; FACBB6  extz XHL
	ld	e, (xhl+0x71)                           ; FACBB8  ld E,(XHL+0x71)
	ld	c, e                                    ; FACBBB  ld C,E
	and	c, 1                                   ; FACBBD  and C,0x01
	jr z, sub_FACAB7__FACC18                   ; FACBC0  jr Z,0xfacc18
	ld	c, e                                    ; FACBC2  ld C,E
	and	c, 2                                   ; FACBC4  and C,0x02
	jr z, sub_FACAB7__FACBF1                   ; FACBC7  jr Z,0xfacbf1
	ld	c, e                                    ; FACBC9  ld C,E
	and	c, 4                                   ; FACBCB  and C,0x04
	jr z, sub_FACAB7__FACBE1                   ; FACBCE  jr Z,0xfacbe1
	ld	c, e                                    ; FACBD0  ld C,E
	and	c, 8                                   ; FACBD2  and C,0x08
	jr nz, sub_FACAB7__FACC18                  ; FACBD5  jr NZ,0xfacc18
	pushw	hl                                   ; FACBD7  push HL
	push	0                                     ; FACBD8  push 0x00
	push	d                                     ; FACBDA  push D
	calr (0xFAC7EF - 0xFACBDF)                 ; FACBDC  calr 0xfac7ef
	jr sub_FACAB7__FACC17                      ; FACBDF  jr T,0xfacc17
sub_FACAB7__FACBE1:
	extz	xhl                                   ; FACBE1  extz XHL
	extpfx4 0x8B, 0x71, 0x3E, 0x04             ; FACBE3  or (XHL+0x71),0x04
	pushw	hl                                   ; FACBE7  push HL
	push	0                                     ; FACBE8  push 0x00
	push	d                                     ; FACBEA  push D
	calr (0xFAC9A6 - 0xFACBEF)                 ; FACBEC  calr 0xfac9a6
	jr sub_FACAB7__FACC17                      ; FACBEF  jr T,0xfacc17
sub_FACAB7__FACBF1:
	ld	c, e                                    ; FACBF1  ld C,E
	and	c, 4                                   ; FACBF3  and C,0x04
	jr nz, sub_FACAB7__FACC09                  ; FACBF6  jr NZ,0xfacc09
	ld	c, e                                    ; FACBF8  ld C,E
	and	c, 16                                  ; FACBFA  and C,0x10
	jr nz, sub_FACAB7__FACC18                  ; FACBFD  jr NZ,0xfacc18
	pushw	hl                                   ; FACBFF  push HL
	push	0                                     ; FACC00  push 0x00
	push	d                                     ; FACC02  push D
	calr (0xFAC888 - 0xFACC07)                 ; FACC04  calr 0xfac888
	jr sub_FACAB7__FACC17                      ; FACC07  jr T,0xfacc17
sub_FACAB7__FACC09:
	extz	xhl                                   ; FACC09  extz XHL
	extpfx4 0x8B, 0x71, 0x3C, 0xFB             ; FACC0B  and (XHL+0x71),0xfb
	pushw	hl                                   ; FACC0F  push HL
	push	0                                     ; FACC10  push 0x00
	push	d                                     ; FACC12  push D
	calr (0xFAC90E - 0xFACC17)                 ; FACC14  calr 0xfac90e
sub_FACAB7__FACC17:
	pop	xiy                                    ; FACC17  pop XIY
sub_FACAB7__FACC18:
	ld	hl, (xiz-2)                             ; FACC18  ld HL,(XIZ+0xfe)
	extz	xhl                                   ; FACC1B  extz XHL
	extpfx7 0xD3, 0xED, 0x23, 0x15, 0x3C, 0xFF, 0xDF ; FACC1D  and (XHL+0x1523),0xdfff
	add	ix, 0x12C                              ; FACC24  add IX,0x012c
	ld	bc, hl                                  ; FACC28  ld BC,HL
	add	bc, 0x12C                              ; FACC2A  add BC,0x012c
	ld	(xiz-2), bc                             ; FACC2E  ld (XIZ+0xfe),BC
	inc	1, d                                   ; FACC31  inc 1,D
	cp	d, 33                                   ; FACC33  cp D,0x21
	jrl c, sub_FACAB7__FACBAB                  ; FACC36  jrl C,0xfacbab
	pop	xix                                    ; FACC39  pop XIX
	popw	de                                    ; FACC3A  pop DE
	pop	xhl                                    ; FACC3B  pop XHL
	unlk32 xiz                                 ; FACC3C  unlk XIZ
	ret                                        ; FACC3E  ret
; --------------------------------------------------------------------------
; PartRec_Word0006_SetBit13 -- 0xFACC3F..0xFACC59 (27 bytes)
;             (* NAMED in wave 7 round 12; was `sub_FACC3F`.)
;
; Called from: 4 site(s) outside this module:
;          0xFAFCF0 in MidiCtrl_CC120, 0xFAFF73 in MidiCtrl_Dispatch__FAFF6F
;          0xFB02C0 in sub_FB029E__FB02B2, 0xFB6C14 in sub_FB6BA8
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFACC3F-0xFACC59
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; * WHAT IT DOES: sets bit 13 of the part record's word +0x06, for the part index
;   in (XIZ+0x08).  PartRec_Word0006_ClearBit13 (0xFACC5A) is the matching clear.
; Evidence: `mul BC,0x012c` at 0xFACC48 is the 300-byte part-record stride and
;          `inc 6,BC` at 0xFACC4C the field offset; `or (XBC+0x1523),0x2000` at
;          0xFACC50 is the bit, 0x2000 = 1<<13.  0x001523 is the part-record array
;          base of notes/FINDINGS-prom_c-dev10c-register-meanings.md section 1.
;          The two routines are 27 bytes each and differ in exactly THREE ROM bytes,
;          at offsets 21, 22 and 23 -- the sub-opcode (0x3E `or` against 0x3C `and`)
;          and the two immediate bytes.  Re-measured by
;          `python3 notes/prom_c_finish_round12.py --names`.
; Unknown:  what bit 13 of word +0x06 MEANS.  The name states the field and the
;          operation, both instruction operands, and claims nothing else.
; --------------------------------------------------------------------------
PartRec_Word0006_SetBit13:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACC3F  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FACC43  ld BC,(XIZ+0x08)
	extz	bc                                    ; FACC46  extz BC
	mul	bc, 0x12C                              ; FACC48  mul BC,0x012c
	inc	6, bc                                  ; FACC4C  inc 6,BC
	extz	xbc                                   ; FACC4E  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3E, 0x00, 0x20 ; FACC50  or (XBC+0x1523),0x2000
	unlk32 xiz                                 ; FACC57  unlk XIZ
	ret                                        ; FACC59  ret
; --------------------------------------------------------------------------
; PartRec_Word0006_ClearBit13 -- 0xFACC5A..0xFACC74 (27 bytes)
;             (* NAMED in wave 7 round 12; was `sub_FACC5A`.)
;
; Called from: 1 site(s) outside this module:
;          0xFB3C09 in MidiNote_OnByPartMode__FB3C04
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: no absolute-addressed write.
; Evidence: the listing below is the byte-identical round-trip of 0xFACC5A-0xFACC74
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; * WHAT IT DOES: clears bit 13 of the part record's word +0x06, for the part index
;   in (XIZ+0x08).  The mirror of PartRec_Word0006_SetBit13 (0xFACC3F).
; Evidence: `mul BC,0x012c` at 0xFACC63 / `inc 6,BC` at 0xFACC67 /
;          `and (XBC+0x1523),0xdfff` at 0xFACC6B; 0xDFFF is ~(1<<13).
;          27 bytes against the setter's 27, differing at offsets 21, 22, 23 only.
; Unknown:  what bit 13 of word +0x06 MEANS.
; --------------------------------------------------------------------------
PartRec_Word0006_ClearBit13:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACC5A  link XIZ,0x0000
	ld	bc, (xiz+8)                             ; FACC5E  ld BC,(XIZ+0x08)
	extz	bc                                    ; FACC61  extz BC
	mul	bc, 0x12C                              ; FACC63  mul BC,0x012c
	inc	6, bc                                  ; FACC67  inc 6,BC
	extz	xbc                                   ; FACC69  extz XBC
	extpfx7 0xD3, 0xE5, 0x23, 0x15, 0x3C, 0xFF, 0xDF ; FACC6B  and (XBC+0x1523),0xdfff
	unlk32 xiz                                 ; FACC72  unlk XIZ
	ret                                        ; FACC74  ret
; --------------------------------------------------------------------------
; sub_FACC75 -- 0xFACC75..0xFACD1A (166 bytes)
;
; Called from: 7 site(s) outside this module:
;          0xFBB4EA in sub_FBB4BF__FBB4E2, 0xFBB4F7 in sub_FBB4BF__FBB4E2
;          0xFBB507 in sub_FBB4BF__FBB4FF, 0xFBB53C in sub_FBB4BF__FBB51A
;          0xFBB670 in sub_FBB645__FBB668, 0xFBB6A7 in sub_FBB645__FBB685
;          0xFBB6B6 in sub_FBB645__FBB6AE
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: writes 0x00D79E, 0x00D7A0
; Calls:   0xFA6110 = sub_FA6110, 0xFB582A = sub_FB582A
;          0xFB7C8F = Dev10C_SetChanReg_0600_b, 0xFB7D85 = Dev10C_SetChanReg_0640
; Evidence: the listing below is the byte-identical round-trip of 0xFACC75-0xFACD1A
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FACC75:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACC75  link XIZ,0x0000
	pushw	hl                                   ; FACC79  push HL
	pushw	de                                   ; FACC7A  push DE
	push	xix                                   ; FACC7B  push XIX
	push	0                                     ; FACC7C  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FACC7E  push (XIZ+0x0a)
	push	0                                     ; FACC81  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FACC83  push (XIZ+0x08)
	call	0xFB582A                              ; FACC86  call 0xfb582a
	ld	hl, wa                                  ; FACC8A  ld HL,WA
	pop	xiy                                    ; FACC8C  pop XIY
	cp (xiz+10), 0x00                          ; FACC8D  cp (XIZ+0x0a),0x00
	jr nz, sub_FACC75__FACCD4                  ; FACC91  jr NZ,0xfaccd4
	stw_da	(0xD7A0), wa                        ; FACC93  ld (0x00d7a0),WA
	pushw	0                                    ; FACC98  push 0x0000
	ld	c, (xiz+10)                             ; FACC9B  ld C,(XIZ+0x0a)
	or	c, 12                                   ; FACC9E  or C,0x0c
	pushw	bc                                   ; FACCA1  push BC
	push	0                                     ; FACCA2  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FACCA4  push (XIZ+0x08)
	call	0xFA6110                              ; FACCA7  call 0xfa6110
	ld	ix, iy                                  ; FACCAB  ld IX,IY
	ldw	hl, 0                                  ; FACCAD  ld HL,0x0000
	jr sub_FACC75__FACCD0                      ; FACCB0  jr T,0xfaccd0
sub_FACC75__FACCB2:
	extz	xix                                   ; FACCB2  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xEC, 0x22       ; FACCB4  ld DE,(XIX+HL)
	and	de, 0xFF                               ; FACCB9  and DE,0x00ff
	cp	de, 0x80                                ; FACCBD  cp DE,0x0080
	jr nc, sub_FACC75__FACD15                  ; FACCC1  jr NC,0xfacd15
	lda	xbc, (0xD75E:24)                       ; FACCC3  lda XBC,0x00d75e
	push	xbc                                   ; FACCC8  push XBC
	pushw	de                                   ; FACCC9  push DE
	call	0xFB7D85                              ; FACCCA  call 0xfb7d85
	inc	2, hl                                  ; FACCCE  inc 2,HL
sub_FACC75__FACCD0:
	inc	6, xsp                                 ; FACCD0  inc 6,XSP
	jr sub_FACC75__FACCB2                      ; FACCD2  jr T,0xfaccb2
sub_FACC75__FACCD4:
	stw_da	(0xD79E), hl                        ; FACCD4  ld (0x00d79e),HL
	pushw	0                                    ; FACCD9  push 0x0000
	ld	c, (xiz+10)                             ; FACCDC  ld C,(XIZ+0x0a)
	or	c, 12                                   ; FACCDF  or C,0x0c
	pushw	bc                                   ; FACCE2  push BC
	push	0                                     ; FACCE3  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FACCE5  push (XIZ+0x08)
	call	0xFA6110                              ; FACCE8  call 0xfa6110
	ld	ix, iy                                  ; FACCEC  ld IX,IY
	ldw	hl, 0                                  ; FACCEE  ld HL,0x0000
	jr sub_FACC75__FACD11                      ; FACCF1  jr T,0xfacd11
sub_FACC75__FACCF3:
	extz	xix                                   ; FACCF3  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xEC, 0x22       ; FACCF5  ld DE,(XIX+HL)
	and	de, 0xFF                               ; FACCFA  and DE,0x00ff
	cp	de, 0x80                                ; FACCFE  cp DE,0x0080
	jr nc, sub_FACC75__FACD15                  ; FACD02  jr NC,0xfacd15
	lda	xbc, (0xD75E:24)                       ; FACD04  lda XBC,0x00d75e
	push	xbc                                   ; FACD09  push XBC
	pushw	de                                   ; FACD0A  push DE
	call	0xFB7C8F                              ; FACD0B  call 0xfb7c8f
	inc	2, hl                                  ; FACD0F  inc 2,HL
sub_FACC75__FACD11:
	inc	6, xsp                                 ; FACD11  inc 6,XSP
	jr sub_FACC75__FACCF3                      ; FACD13  jr T,0xfaccf3
sub_FACC75__FACD15:
	pop	xix                                    ; FACD15  pop XIX
	popw	de                                    ; FACD16  pop DE
	popw	hl                                    ; FACD17  pop HL
	unlk32 xiz                                 ; FACD18  unlk XIZ
	ret                                        ; FACD1A  ret
; --------------------------------------------------------------------------
; sub_FACD1B -- 0xFACD1B..0xFACDC0 (166 bytes)
;
; Called from: 6 site(s) outside this module:
;          0xFBB5A8 in sub_FBB57C__FBB5A0, 0xFBB5B5 in sub_FBB57C__FBB5A0
;          0xFBB5C5 in sub_FBB57C__FBB5BD, 0xFBB5FB in sub_FBB57C__FBB5D9
;          0xFBB723 in sub_FBB6F8__FBB71B, 0xFBB74C in sub_FBB6F8__FBB72A
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08), (XIZ+0x0A)
; Outputs: writes 0x00D79A, 0x00D79C
; Calls:   0xFA6110 = sub_FA6110, 0xFB59D2 = sub_FB59D2
;          0xFB7CB1 = Dev10C_Slot2_StrobeGate, 0xFB7DA7 = Dev10C_Slot3_StrobeGate
; Evidence: the listing below is the byte-identical round-trip of 0xFACD1B-0xFACDC0
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FACD1B:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACD1B  link XIZ,0x0000
	pushw	hl                                   ; FACD1F  push HL
	pushw	de                                   ; FACD20  push DE
	push	xix                                   ; FACD21  push XIX
	push	0                                     ; FACD22  push 0x00
	extpfx3 0x8E, 0x0A, 0x04                   ; FACD24  push (XIZ+0x0a)
	push	0                                     ; FACD27  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FACD29  push (XIZ+0x08)
	call	0xFB59D2                              ; FACD2C  call 0xfb59d2
	ld	hl, wa                                  ; FACD30  ld HL,WA
	pop	xiy                                    ; FACD32  pop XIY
	cp (xiz+10), 0x00                          ; FACD33  cp (XIZ+0x0a),0x00
	jr nz, sub_FACD1B__FACD7A                  ; FACD37  jr NZ,0xfacd7a
	stw_da	(0xD79C), wa                        ; FACD39  ld (0x00d79c),WA
	pushw	0                                    ; FACD3E  push 0x0000
	ld	c, (xiz+10)                             ; FACD41  ld C,(XIZ+0x0a)
	or	c, 12                                   ; FACD44  or C,0x0c
	pushw	bc                                   ; FACD47  push BC
	push	0                                     ; FACD48  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FACD4A  push (XIZ+0x08)
	call	0xFA6110                              ; FACD4D  call 0xfa6110
	ld	ix, iy                                  ; FACD51  ld IX,IY
	ldw	hl, 0                                  ; FACD53  ld HL,0x0000
	jr sub_FACD1B__FACD76                      ; FACD56  jr T,0xfacd76
sub_FACD1B__FACD58:
	extz	xix                                   ; FACD58  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xEC, 0x22       ; FACD5A  ld DE,(XIX+HL)
	and	de, 0xFF                               ; FACD5F  and DE,0x00ff
	cp	de, 0x80                                ; FACD63  cp DE,0x0080
	jr nc, sub_FACD1B__FACDBB                  ; FACD67  jr NC,0xfacdbb
	lda	xbc, (0xD75E:24)                       ; FACD69  lda XBC,0x00d75e
	push	xbc                                   ; FACD6E  push XBC
	pushw	de                                   ; FACD6F  push DE
	call	0xFB7DA7                              ; FACD70  call 0xfb7da7
	inc	2, hl                                  ; FACD74  inc 2,HL
sub_FACD1B__FACD76:
	inc	6, xsp                                 ; FACD76  inc 6,XSP
	jr sub_FACD1B__FACD58                      ; FACD78  jr T,0xfacd58
sub_FACD1B__FACD7A:
	stw_da	(0xD79A), hl                        ; FACD7A  ld (0x00d79a),HL
	pushw	0                                    ; FACD7F  push 0x0000
	ld	c, (xiz+10)                             ; FACD82  ld C,(XIZ+0x0a)
	or	c, 12                                   ; FACD85  or C,0x0c
	pushw	bc                                   ; FACD88  push BC
	push	0                                     ; FACD89  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FACD8B  push (XIZ+0x08)
	call	0xFA6110                              ; FACD8E  call 0xfa6110
	ld	ix, iy                                  ; FACD92  ld IX,IY
	ldw	hl, 0                                  ; FACD94  ld HL,0x0000
	jr sub_FACD1B__FACDB7                      ; FACD97  jr T,0xfacdb7
sub_FACD1B__FACD99:
	extz	xix                                   ; FACD99  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xEC, 0x22       ; FACD9B  ld DE,(XIX+HL)
	and	de, 0xFF                               ; FACDA0  and DE,0x00ff
	cp	de, 0x80                                ; FACDA4  cp DE,0x0080
	jr nc, sub_FACD1B__FACDBB                  ; FACDA8  jr NC,0xfacdbb
	lda	xbc, (0xD75E:24)                       ; FACDAA  lda XBC,0x00d75e
	push	xbc                                   ; FACDAF  push XBC
	pushw	de                                   ; FACDB0  push DE
	call	0xFB7CB1                              ; FACDB1  call 0xfb7cb1
	inc	2, hl                                  ; FACDB5  inc 2,HL
sub_FACD1B__FACDB7:
	inc	6, xsp                                 ; FACDB7  inc 6,XSP
	jr sub_FACD1B__FACD99                      ; FACDB9  jr T,0xfacd99
sub_FACD1B__FACDBB:
	pop	xix                                    ; FACDBB  pop XIX
	popw	de                                    ; FACDBC  pop DE
	popw	hl                                    ; FACDBD  pop HL
	unlk32 xiz                                 ; FACDBE  unlk XIZ
	ret                                        ; FACDC0  ret
; --------------------------------------------------------------------------
; sub_FACDC1 -- 0xFACDC1..0xFACE13 (83 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFBB513 in sub_FBB4BF__FBB50E, 0xFBB67D in sub_FBB645__FBB678
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D796
; Calls:   0xFA6110 = sub_FA6110, 0xFB5BAA = sub_FB5BAA
;          0xFB7E7B = Dev10C_SetChanReg_01C0_b
; Evidence: the listing below is the byte-identical round-trip of 0xFACDC1-0xFACE13
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FACDC1:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACDC1  link XIZ,0x0000
	pushw	hl                                   ; FACDC5  push HL
	pushw	de                                   ; FACDC6  push DE
	push	xix                                   ; FACDC7  push XIX
	push	0                                     ; FACDC8  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FACDCA  push (XIZ+0x08)
	call	0xFB5BAA                              ; FACDCD  call 0xfb5baa
	stw_da	(0xD796), wa                        ; FACDD1  ld (0x00d796),WA
	pushw	0                                    ; FACDD6  push 0x0000
	pushw	16                                   ; FACDD9  push 0x0010
	push	0                                     ; FACDDC  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FACDDE  push (XIZ+0x08)
	call	0xFA6110                              ; FACDE1  call 0xfa6110
	ld	ix, iy                                  ; FACDE5  ld IX,IY
	ldw	hl, 0                                  ; FACDE7  ld HL,0x0000
	inc	8, xsp                                 ; FACDEA  inc 0,XSP
sub_FACDC1__FACDEC:
	extz	xix                                   ; FACDEC  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xEC, 0x22       ; FACDEE  ld DE,(XIX+HL)
	and	de, 0xFF                               ; FACDF3  and DE,0x00ff
	cp	de, 64                                  ; FACDF7  cp DE,0x0040
	jr nc, sub_FACDC1__FACE0E                  ; FACDFB  jr NC,0xface0e
	lda	xbc, (0xD75E:24)                       ; FACDFD  lda XBC,0x00d75e
	push	xbc                                   ; FACE02  push XBC
	pushw	de                                   ; FACE03  push DE
	call	0xFB7E7B                              ; FACE04  call 0xfb7e7b
	inc	2, hl                                  ; FACE08  inc 2,HL
	inc	6, xsp                                 ; FACE0A  inc 6,XSP
	jr sub_FACDC1__FACDEC                      ; FACE0C  jr T,0xfacdec
sub_FACDC1__FACE0E:
	pop	xix                                    ; FACE0E  pop XIX
	popw	de                                    ; FACE0F  pop DE
	popw	hl                                    ; FACE10  pop HL
	unlk32 xiz                                 ; FACE11  unlk XIZ
	ret                                        ; FACE13  ret
; --------------------------------------------------------------------------
; sub_FACE14 -- 0xFACE14..0xFACE66 (83 bytes)
;
; Called from: 2 site(s) outside this module:
;          0xFBB5D2 in sub_FBB57C__FBB5CD, 0xFBB605 in sub_FBB57C__FBB5D9
; Inputs:  frame `link XIZ,0`; argument slots read: (XIZ+0x08)
; Outputs: writes 0x00D798
; Calls:   0xFA6110 = sub_FA6110, 0xFB5C77 = sub_FB5C77
;          0xFB7E9D = Dev10C_Slot1_StrobeGate
; Evidence: the listing below is the byte-identical round-trip of 0xFACE14-0xFACE66
;          (notes/gen_prom_c_block.py, cleared by
;          notes/prom_c_verify_fragment.py before insertion).  Every field above
;          is an instruction operand, listed by notes/gen_prom_c_block_headers.py;
;          the call sites are notes/prom_c_module_map.py's image-wide scan.
; Unknown:  what the routine is FOR.  Nothing here reads the meaning of a field,
;          so the name is an address.
; --------------------------------------------------------------------------
sub_FACE14:
	link32 0xEE, 0x0C, 0x00, 0x00              ; FACE14  link XIZ,0x0000
	pushw	hl                                   ; FACE18  push HL
	pushw	de                                   ; FACE19  push DE
	push	xix                                   ; FACE1A  push XIX
	push	0                                     ; FACE1B  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FACE1D  push (XIZ+0x08)
	call	0xFB5C77                              ; FACE20  call 0xfb5c77
	stw_da	(0xD798), wa                        ; FACE24  ld (0x00d798),WA
	pushw	0                                    ; FACE29  push 0x0000
	pushw	16                                   ; FACE2C  push 0x0010
	push	0                                     ; FACE2F  push 0x00
	extpfx3 0x8E, 0x08, 0x04                   ; FACE31  push (XIZ+0x08)
	call	0xFA6110                              ; FACE34  call 0xfa6110
	ld	ix, iy                                  ; FACE38  ld IX,IY
	ldw	hl, 0                                  ; FACE3A  ld HL,0x0000
	inc	8, xsp                                 ; FACE3D  inc 0,XSP
sub_FACE14__FACE3F:
	extz	xix                                   ; FACE3F  extz XIX
	extpfx5 0xD3, 0x07, 0xF0, 0xEC, 0x22       ; FACE41  ld DE,(XIX+HL)
	and	de, 0xFF                               ; FACE46  and DE,0x00ff
	cp	de, 64                                  ; FACE4A  cp DE,0x0040
	jr nc, sub_FACE14__FACE61                  ; FACE4E  jr NC,0xface61
	lda	xbc, (0xD75E:24)                       ; FACE50  lda XBC,0x00d75e
	push	xbc                                   ; FACE55  push XBC
	pushw	de                                   ; FACE56  push DE
	call	0xFB7E9D                              ; FACE57  call 0xfb7e9d
	inc	2, hl                                  ; FACE5B  inc 2,HL
	inc	6, xsp                                 ; FACE5D  inc 6,XSP
	jr sub_FACE14__FACE3F                      ; FACE5F  jr T,0xface3f
sub_FACE14__FACE61:
	pop	xix                                    ; FACE61  pop XIX
	popw	de                                    ; FACE62  pop DE
	popw	hl                                    ; FACE63  pop HL
	unlk32 xiz                                 ; FACE64  unlk XIZ
	ret                                        ; FACE66  ret

	.include "prom_c/devices/dev10c_reg_writers.s"	; 0xFACE67-0xFAD141  the register writers for the device at 0x0010C000
	.include "prom_c/midi/midi_controllers.s"	; 0xFAD142-0xFB0503  the MIDI controllers, the part record and the global setup
	.include "prom_c/voice/note_engine.s"	; 0xFB0504-0xFB6E09  the MIDI message path and the 64-VOICE NOTE ENGINE
	.include "prom_c/devices/dev10c_dev104_drivers.s"	; 0xFB6E0A-0xFB828D  the three register-device drivers, 0x0010C000 and 0x00104000
	.include "prom_c/tone_db/tone_db_module.s"	; 0xFB828E-0xFC3406  the tone/drum database and the query responders
	.include "prom_c/field_accessors.s"	; 0xFC3407-0xFC856B  the field accessors and their callers
	.include "prom_c/storage/flash.s"	; 0xFC856C-0xFC89C4  THE FLASH DRIVER, 512 KiB at 0x00E80000
	.include "prom_c/storage/eeprom.s"	; 0xFC89C5-0xFC8BB1  THE SERIAL EEPROM, a Microwire 64 x 16 bit-banged on port pins
	.include "prom_c/mathlib/mathlib.s"	; 0xFC8BB2-0xFCC53E  the math library: double routines, the runtime, the pools
	.include "prom_c/data_tables/touch_eq_mixer.s"	; 0xFCC53F-0xFCD0F6  touch / EQ / mixer-gain / descriptor-string zone
	.include "prom_c/p7/p7_stream_pool.s"	; 0xFCD0F7-0xFDD2AA  THE RELOCATABLE BYTE-STREAM POOL, 65,972 bytes
	.include "prom_c/data_tables/voice_dsp_tables.s"	; 0xFDD2AB-0xFDF7DF  the voice / DSP data-table zone, 43 tables
	.include "prom_c/data_tables/tail_data_zone.s"	; 0xFDF7E0-0xFFEFFF  the tail data zone, copy B of the initialiser, and the pad
	.include "prom_c/boot/reset_and_vectors.s"	; 0xFFF000-0xFFFFFF  RESET, the trampolines, the vector table and the build tag