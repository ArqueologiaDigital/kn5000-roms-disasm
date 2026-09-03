; ==============================================================================
; Technics SX-WSA1R -- THE DSP CHANNEL-REGISTER DRIVER, ONE SOURCE FOR BOTH CPUs
; ==============================================================================
;
; The WSA1R has two Toshiba TMP95C061s and each of them drives a DSP register
; file of its own.  They drive it with THE SAME 234 BYTES.  Until now that fact
; lived in a probe; this file is the fact itself: prom_a and prom_c both
; `.include` it, and both ROMs still rebuild byte for byte.
;
;     prom_a/wsa1_prom_a.s        CPU 1, "MICROCOMPUTER (MAIN)", IC1/IC12
;         .include "dsp/dsp_channel_regs_maincpu.inc"
;         .include "dsp/dsp_channel_regs.s"     ->  0xF85F0F-0xF85FF8
;
;     prom_c/boot/boot_and_main.s CPU 2, "MICROCOMPUTER (SUB)",  IC2/IC28
;         .include "dsp/dsp_channel_regs_subcpu.inc"
;         .include "dsp/dsp_channel_regs.s"     ->  0xF98000-0xF980E9
;
;     every pair of addresses differs by exactly 0x120F1, first slot to last
;
; ★★ THE BYTE GATE IS THE PROOF, AND IT IS THE WHOLE POINT.
;
;     python3 scripts/analysis/assert_byte_identical.py
;
;   ONE SOURCE that assembles to 234 bytes of prom_a and 234 bytes of prom_c,
;   both byte-identical to the original EPROMs, cannot be a resemblance.  If the
;   single equate in either dsp/dsp_channel_regs_*.inc is wrong by one byte, that
;   image stops rebuilding.
;
; ------------------------------------------------------------------------------
; HOW THE TWO COPIES DIFFER, measured before this file was written
; ------------------------------------------------------------------------------
;
;     python3 notes/sound/wsa1_dsp_driver_shared.py            <- from the ROMs
;     python3 notes/sound/wsa1_dsp_join_probe.py --pairs       <- from the sources
;     python3 notes/sound/wsa1_dsp_join_probe.py --verify      <- the preservation proof
;
;   234 bytes on each side.  231 OF THEM ARE THE SAME BYTE.  The three that are
;   not are A23..A16 of each routine's base literal -- 0x7F on CPU 1, 0xE0 on
;   CPU 2 -- at block offsets 0x034, 0x05A and 0x0A8, and nothing else:
;
;       0xF85F43 / 0xF98034      `ld XBC,DSP_REGS_BASE`   in DSP_ChannelRegs_Init
;       0xF85F69 / 0xF9805A      `ld XBC,DSP_REGS_BASE`   in DSP_ChannelRegs_Write8
;       0xF85FB7 / 0xF980A8      `ld XIY,DSP_REGS_BASE`   in DSP_WriteChannelRegs_Inner
;
;   ★ AND THE NULL SAYS IT IS NOT AN ARTEFACT OF COMPARING TWO BLOBS.  The same
;   comparison at eight neighbouring alignments scores 5 to 19 of 234.  Only the
;   true alignment matches.
;
;   As SOURCE the two blocks are 97 instructions each, pairing 1:1 in order.
;   82 of the 97 pairs already said the same thing in two house styles; 12 are
;   enumerated as ADOPTIONS in notes/sound/wsa1_dsp_join_probe.py, each with the
;   side kept and the reason; 3 are the one per-CPU value.
;
;   ⚠ Those numbers are FORMATTED FROM THE MEASUREMENT, not typed: they cannot
;     disagree with what --pairs prints.
;
; ★ There is NO `.if CPU_MAINCPU` anywhere in this file, and that is deliberate.
;   Wrapping code in conditionals would duplicate every differing line at its
;   site; ONE equate names the one difference and leaves the body genuinely
;   shared.  There is exactly one per-CPU value in 234 bytes.
;
; ------------------------------------------------------------------------------
; WHAT THE MERGE DID TO THE TEXT -- so a reviewer can check it rather than trust it
; ------------------------------------------------------------------------------
;
; * Comments and headers were MOVED, not rewritten.  BOTH files' headers are
;   here, each under a banner saying which file it came from.  They were written
;   by different lanes, cite different call sites and disagree about what is
;   established, so keeping one would have destroyed real documentation.
;   `--verify` fails on a single changed character.
; * Both files' LABELS are kept.  The one address the two files name differently
;   -- prom_c's `DSP_ChannelRegs_Init__loop`, prom_a's `DSP_ChannelRegs_Init_Loop`
;   -- carries BOTH labels, so a reference to either still resolves.
; * Each instruction line carries BOTH addresses, the bytes (both images' when
;   they differ), the DROPPED spelling where the two files disagreed (`c:` or
;   `a:`), and both files' prose separated by ` / ` where they wrote different
;   prose.  prom_a gains prom_c's per-channel and per-register annotations; prom_c
;   gains prom_a's addresses and bytes, which its hand-written block never had.
; * ⚠ NO COMMENT LINE WAS REWRITTEN.  CORRECTIONS in the probe is EMPTY, and it
;   is printed by --verify rather than assumed.
;
; ------------------------------------------------------------------------------
; ★ AND SOMETHING THE MERGE MADE VISIBLE: THE SAME CODE, REACHED DIFFERENTLY
; ------------------------------------------------------------------------------
; Putting the two files' "Called from:" lines side by side, for the first time on
; one page, shows the two processors do NOT use this driver the same way -- and
; the asymmetry runs in OPPOSITE directions for two of the four routines:
;
;   DSP_ChannelRegs_Init      CPU 1: NO SITE FOUND -- nothing in prom_a or prom_b
;                                    names 0xF85F0F and no PC-relative
;                                    displacement reaches it
;                             CPU 2: called once, at 0xF98B95, from the power-on
;                                    init chain
;   DSP_WriteAllChannelRegs   CPU 1: published through prom_b's thunk 0xF42DE4,
;                                    the LAST slot of the kernel thunk block
;                             CPU 2: NOT TRACED
;
; ⚠ "NOT TRACED" and "NO SITE FOUND" are DIFFERENT CLAIMS and both headers say
;   which they mean; neither is "dead code".  What is established is that byte
;   identity of a routine says NOTHING about whether either machine runs it --
;   which is worth stating right where the byte identity is strongest.
;
; ------------------------------------------------------------------------------
; ⚠ WHAT THIS FILE DOES **NOT** ESTABLISH
; ------------------------------------------------------------------------------
; That the two processors run the same driver is a fact about the CODE.  What the
; eight per-channel registers HOLD is not established for either machine, and
; "DSP" is a name BORROWED from the KN5000 lane whose byte-identical routine
; drives its own register file at 0x00130000.  prom_c's header below argues that
; borrowing at length and marks its limit; nothing here strengthens it.
;
; ------------------------------------------------------------------------------
; ★★ WAVE 17, 2026-09-03 -- THE REGISTER MAP OF THE FILE THIS DRIVER WRITES
; ------------------------------------------------------------------------------
; ADDED, not replacing.  The four routine headers below already say what each
; routine does; what was missing was the FILE's map -- which of each channel's 32
; registers the firmware ever touches, how wide they are, and what is not there.
; Every number is an assertion in
;     python3 notes/sound/wsa1_dsp_regfile_map_checks.py --selftest   FAILURES: 0
; over both original EPROM images and no .s file.
;
; ⚠ WHAT THIS IS AND IS NOT.  "DSP" is a BORROWED name, as the blocks below spell
; out at length: it is the KN5000 lane's name for the device ITS byte-identical
; code drives at its own base.  Nothing in either WSA1R image names a part.
; ★★ AND THIS IS **NOT** THE uPD6383GF HOST INTERFACE.  The tree records that
; separation in two places and both are negative results, not identifications:
;   * notes/WSA1-EMULATION-DISASM-GAPS.md, "Gaps I could not frame sharply" --
;     "on the KN5000 the standing correction is that it is NOT the DSP host
;     interface.  So the DSP host interface on this machine has not been located
;     at all, on either processor."
;   * notes/FINDINGS-prom_c-p7-byte-stream-pool.md, answering the gap list's
;     "which port do the microcode BYTES leave by -- 0x00E00000, or something not
;     yet reached?" with
;     "Neither."  The effect microcode goes out over the P7 HANDSHAKE
;     (notes/FINDINGS-prom_c-p7-is-dsp-effects.md), to three destinations, which
;     is the number of uPD6383GF-3BA parts on the schematic.
; ⚠ SO DO NOT WRITE "the DSP base address" OF 0x007F0000 OR 0x00E00000 AS IF IT
;   WERE ESTABLISHED.  An earlier write-up did; the address is an address/data
;   register pair of unidentified silicon that this tree calls DSP_REGS_BASE
;   because two of these four routines are byte-identical to a sibling project's
;   and it would be perverse to call the same bytes something else.
;
; THE PORT
;   DSP_REGS_BASE + 0x00   write   8-bit REGISTER INDEX
;   DSP_REGS_BASE + 0x02   write   that register's 8-bit VALUE
;   DSP_REGS_BASE + 0x04   -- nothing.  NO READ PATH ANYWHERE.  Neither driver
;                             reads the device, and the whole of prom_a names
;                             0x007F0000 in five instruction operands and prom_c
;                             names 0x00E00000 in three, all of them stores.
;   ⚠ The file does NOT auto-increment: the index is re-written before every
;     value (`inc 1,A` between pairs).  PROVEN by the eight unrolled triples in
;     DSP_WriteChannelRegs_Inner and by the loop in DSP_ChannelRegs_Write8.
;
;   DSP_REGS_BASE = 0x007F0000 on CPU 1, 0x00E00000 on CPU 2.  ONE equate; three
;   literals per image; 231 of 234 bytes identical and the three that differ are
;   at block offsets 0x034, 0x05A and 0x0A8, one byte of each literal.  Checker s.1.
;
; THE MAP -- 4 CHANNELS x 32 REGISTERS, OF WHICH NINE PER CHANNEL ARE WRITTEN
;
;   register number = (channel << 5) | 0x10 + k
;
;   reg (per channel)  width  what the firmware puts there              grade
;   -----------------  -----  ---------------------------------------  ------------
;   0x00 .. 0x0F         --   NEVER WRITTEN by any of these routines,  not touched
;                             nor by prom_a's independent driver
;   0x10                  8   data byte 0  (C,       or array[0])      PROVEN as a
;   0x11                  8   data byte 1  (B,       or array[1])      transfer;
;   0x12                  8   data byte 2  (QBC's C, or array[2])      MEANING
;   0x13                  8   data byte 3  (QBC's B, or array[3])      UNIDENTIFIED
;   0x14                  8   data byte 4  (E,       or array[4])      for all eight
;   0x15                  8   data byte 5  (D,       or array[5])
;   0x16                  8   data byte 6  (QDE's C, or array[6])
;   0x17                  8   data byte 7  (QDE's B, or array[7])
;   0x18 .. 0x1E         --   NEVER WRITTEN                            not touched
;   0x1F                  8   0x01, written once per channel at        value PROVEN;
;                             power-on AFTER 0x10..0x17 are zeroed.    role WEAK
;                             "arm" / "enable" is the obvious reading
;                             and nothing here supports it.
;
;   Twenty-three of the thirty-two are never written; nine are.  Four channels, so
;   36 of the file's 128 register slots are reached at all.  ⚠ "Never written" is a
;   statement about the CONVERTED drivers plus a whole-image literal census, not
;   about the silicon: a register nothing writes may still exist and read back.
;
; ★★ THE WINDOW IS CORROBORATED BY A DRIVER THAT SHARES NO BYTES WITH THIS ONE.
;   prom_a carries a SECOND, independent driver for the same file --
;   `Dev7F_WriteSlot8` (0xF83197), published through four prom_b directory slots,
;   plus its own init sweep at 0xF831EE.  Different calling convention (XHL and W,
;   not the stack), different instruction for the same bit (`or W,0x10` against
;   this driver's `set 0x04,A`), different loop form (`djnz16 bc` against `djnz8
;   d`) -- and the SAME nine registers: `sll 0x05,W`, base 0x10, eight bytes, then
;   register 0x1F of four channels set to 0x01 with a stride of 0x20.
;   Two routines that share no bytes agreeing on a window is a fact about the
;   DEVICE.  Checker sections 2, 3 and 5.
;
; ★ WIDTH: THE DATA REGISTERS ARE BYTES, WITH ONE UNRESOLVED EXCEPTION.  Every
;   data write in DSP_ChannelRegs_Write8 and DSP_WriteChannelRegs_Inner is an
;   8-bit store to +0x02.  The armed register 0x1F is written by a 32-BIT store of
;   0x0101001F, which puts the index in BOTH +0x00 and +0x01 and 0x01 in BOTH
;   +0x02 and +0x03 (`ld W,A` immediately before it keeps the two index bytes
;   equal).  Whether +0x01 and +0x03 are the high halves of 16-bit registers or
;   ignored mirrors is NOT ESTABLISHED -- and prom_a's independent driver does the
;   SAME 32-bit store, so it is not an artefact of one author.
;
; ★ AND THE EIGHT DATA REGISTERS ARE REFRESHED, NOT JUST INITIALISED.
;   DSP_ChannelRefresh_Loop (prom_c 0xF98118), the third entry in
;   EntryPoint_Records, is an interrupt-disabled endless loop that calls
;   DSP_ChannelRegs_Write8 four times, once per channel, from RAM.  So on CPU 2
;   these 32 bytes are rewritten continuously for as long as the machine is on.
;   (notes/FINDINGS-sound-subsystem-boundary.md §4.5.)
;
; ⚠ WHAT IS UNIDENTIFIED, plainly: all nine registers.  Not one of the eight data
;   bytes has a meaning in either image, and the ninth has a value but not a role.
;   What would settle it: this file has no reader anywhere, so the routes are the
;   PRODUCERS of the eight bytes -- CPU 2's 0xFC8719 DSP_WriteChans0to3_FromE29D
;   and whatever fills prom_a's eight-byte blocks -- or the schematic net names on
;   whichever LSI carries the CS for 0x7F0000 and 0x00E00000.
;
; ------------------------------------------------------------------------------
; ⚠ REGENERATING THIS FILE
; ------------------------------------------------------------------------------
; `python3 notes/sound/wsa1_dsp_join_probe.py --emit` produced the first version
; from prom_a's and prom_c's blocks as they stood at BASE_REV.  It is kept as the
; RECORD OF THE MERGE, not as a build step: this file is the source now, and a
; re-run would discard anything edited here.  `--verify` re-checks it against both
; originals in git and is the thing to run after editing.
; ==============================================================================

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>
; ---------------------------------------------------------------------
; DSP_ChannelRegs_Init -- zero all 32 channel registers, then set register 0x1F of
;                      each channel to 1
;
; Called from: NO SITE FOUND.  notes/prom_a_xref.py 0xF85F0F reports no `call`,
;          `jp`, `lda` or bare pointer in prom_a or prom_b, and a scan of every
;          PC-relative `calr`/`jr`/`jrl` displacement in prom_a finds none.  It
;          is reachable only if something computes the address.
; Inputs:  none.  Outputs: for each channel 0..3, registers (ch<<5)|0x10 .. +7
;          set to 0, then register (ch<<5)|0x1F set to 1.  XIZ frame; XBC, XWA,
;          D clobbered.
; ★ RENAMED 2026-09-01 (lane S2), from DSP_Init_Channels, because the name was
;          anchored to the WEAKER of two byte identities.  The transplanted name
;          below rests on a 13-byte run shared with the KN5000, whose enclosing
;          routine differs from this one in 62 of 74 bytes.  The 234-byte block
;          0xF85F0F-0xF85FF8 is 231 of 234 bytes IDENTICAL to prom_c 0xF98000,
;          the three differing bytes being A23..A16 of each routine's base
;          literal (0x7F here, 0xE0 there) and nothing else -- one source, two
;          processors, one symbol changed.  The name now follows that identity,
;          which is prom_c's DSP_ChannelRegs_Init.  Measured, with a null over
;          eight neighbouring alignments (best 19 of 234), by
;          `python3 notes/sound/wsa1_dsp_driver_shared.py --selftest`.
;          ⚠ The KN5000 citation below is UNCHANGED and still names the
;          sibling's own labels; do not rename those.
; Evidence: ★ TRANSPLANTED NAME, byte-backed.  0xF85F4C-0xF85F58 is 13 bytes
;          identical to the KN5000 sub-CPU at 0x1FCD1, where llvm-nm names the
;          label DSP_Init_Channels_Loop and the enclosing routine (0x1FC95)
;          DSP_Init_Channels
;          (../kn5000-roms-disasm/v142/subcpu/kn5000_subprogram_v142.s:396-428).
;          Reproduce with `python3 notes/prom_a_sibling_short_runs.py`.
;          The two routines do the same thing with three differences, all
;          visible here: this one zeroes the 8-byte buffer where the KN5000
;          writes the test pattern 0x5A5A5A5A; the register file is at 0x7F0000
;          instead of 0x00130000; and the per-channel writer takes its arguments
;          on the stack rather than in XWA/BC.  prom_c has its own copy at
;          0xF98000, named DSP_ChannelRegs_Init by that lane, with the port at
;          0x00E00000 -- three processors, one routine, three buses.
; Notes:   the tail loop writes XWA (32 bits) at 0x7F0000, so the register index
;          goes to +0 and +1 and the value 0x0101 to +2 and +3; with A starting
;          at 0x1F and stepping 0x20 that is register 0x1F of channels 0..3 set
;          to 0x01.  0x0101001F is a single `ld XWA,imm32`, and `ld W,A` at the
;          top of the loop keeps the two index bytes equal.
; Unknown:  what register 0x1F is; why nothing calls this.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/boot/boot_and_main.s -- CPU 2, the SUB processor >>>
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
	link XIZ,0xfff8                              ; F85F0F/F98000  ee 0c f8 ff   c: link32 0xEE, 0x0C, 0xF8, 0xFF   8-byte buffer / frame: 8 bytes of channel data
	xor XWA,XWA                                  ; F85F13/F98004  e8 d0
	ld (xiz-8), xwa                              ; F85F15/F98006  be f8 60   buffer[0..3] = 0
	ld (xiz-4), xwa                              ; F85F18/F98009  be fc 60   buffer[4..7] = 0
	lda xiy, (xiz-8)                             ; F85F1B/F9800C  be f8 35   XIY = &buffer
	push XIY                                     ; F85F1E/F9800F  3d
	pushw 0x00                                   ; F85F1F/F98010  0b 00 00   channel 0
	calr DSP_ChannelRegs_Write8                  ; F85F22/F98013  1e 34 00   c: calr (0xF9804A - 0xF98016)   DSP_ChannelRegs_Write8
	push XIY                                     ; F85F25/F98016  3d
	pushw 0x01                                   ; F85F26/F98017  0b 01 00   channel 1
	calr DSP_ChannelRegs_Write8                  ; F85F29/F9801A  1e 2d 00   c: calr (0xF9804A - 0xF9801D)
	push XIY                                     ; F85F2C/F9801D  3d
	pushw 0x02                                   ; F85F2D/F9801E  0b 02 00   channel 2
	calr DSP_ChannelRegs_Write8                  ; F85F30/F98021  1e 26 00   c: calr (0xF9804A - 0xF98024)
	push XIY                                     ; F85F33/F98024  3d
	pushw 0x03                                   ; F85F34/F98025  0b 03 00   channel 3
	calr DSP_ChannelRegs_Write8                  ; F85F37/F98028  1e 1f 00   c: calr (0xF9804A - 0xF9802B)
	add XSP,0x00000018                           ; F85F3A/F9802B  ef c8 18 00 00 00   drop 4 x (pointer + channel word)
	ld XBC,DSP_REGS_BASE                         ; F85F40/F98031  a=41 00 00 7f 00 c=41 00 00 e0 00   the DSP register file / the register port
	ld XWA,0x0101001f                            ; F85F45/F98036  40 1f 00 01 01   A = register 0x1F, +2 = 0x01 / A = register 0x1F, data 0x01
	ldb d, 0x04                                  ; F85F4A/F9803B  24 04   four channels
DSP_ChannelRegs_Init__loop:
; prom_a's name for the SAME address, 0xF85F4C on CPU 1 and 0xF9803D on
; CPU 2; prom_c writes DSP_ChannelRegs_Init__loop just above.  BOTH are
; defined, so a reference to either still resolves -- see kernel/kernel.s,
; which does this for every address its two files named differently.
DSP_ChannelRegs_Init_Loop:
	ld W,A                                       ; F85F4C/F9803D  c9 88
	ld (XBC),XWA                                 ; F85F4E/F9803F  b1 60   +0 = reg number, +2 = 0x01
	add A,0x20                                   ; F85F50/F98041  c9 c8 20   next channel's window
	djnz8 d, DSP_ChannelRegs_Init__loop          ; F85F53/F98044  cc 1c f6   a: djnz8 d, DSP_ChannelRegs_Init_Loop
	unlk XIZ                                     ; F85F56/F98047  ee 0d   c: unlk32 xiz
	ret                                          ; F85F58/F98049  0e

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>
; ==============================================================================
; 0xF85F59-0xF85FF8 -- the DSP / tone-generator register file at 0x7F0000
; ==============================================================================
;
; ★ WHAT 0x7F0000 IS.  notes/FINDINGS-memory-map.md already lists
;   "0x7F0000/0x7F0002 address/data register pair, slot (n<<5)|0x10" as a shape
;   without saying what it drives.  These three routines say: it is the DSP /
;   tone-generator register file, and the WSA1 talks to it with the SAME CODE
;   the KN5000 sub-CPU uses for its own tone generator.
;
;   The transplant is byte-backed.  prom_a 0xF85F73-0xF85FB6 is a 68-byte run
;   identical to the KN5000 sub-CPU payload at 0x1FCF2, where the sibling names
;   it DSP_WriteAllChannelRegs / DSP_WriteChannelRegs_Inner and documents it as
;   "write register data to all 4 DSP channels ... each call writes 8 sequential
;   DSP registers"
;   (../kn5000-roms-disasm/v142/subcpu/kn5000_subprogram_v142.s:456-462).
;   ⚠ Use the CORRECTED payload mapping when checking that address --
;   notes/FINDINGS-kn5000-transplant-offset.md.  The same run also appears in
;   WSA1 prom_c at 0xF9806D, so both WSA1 processors carry it.
;
;   ★ THE ONE THING THAT DIFFERS IS THE BASE ADDRESS, and the run ends ON that
;   byte: the shared bytes stop at 0xF85FB6, and 0xF85FB7 is 0x7F here against
;   0x13 in the KN5000 -- `ld XIY,0x007F0000` versus `ld XIY,0x00130000`, the
;   third byte of the same instruction.  So the routine is shared source
;   recompiled for a different bus, not a copied binary, and the register LAYOUT
;   (index = (channel << 5) | 0x10, then eight consecutive indices) is common to
;   both machines.  A 68-byte match that terminates exactly at the one operand
;   the two machines must disagree about is a much stronger identification than
;   its length alone suggests.
;
; THE PORT PAIR:
;   0x7F0000  write = the register index
;   0x7F0002  write = that register's value
;   The index is bumped with `inc 1,A` and re-written before every value, so the
;   file does NOT auto-increment.

; ---------------------------------------------------------------------
; DSP_ChannelRegs_Write8 -- write 8 bytes into one channel's registers
;
; ★ RENAMED 2026-09-01 (lane S2), from DSP_WriteChannelRegs_FromTable, to keep
; one family name across the two processors that run this same 234-byte driver
; (see the block above).  ⚠ THE OLD NAME WAS NOT WRONG -- "FromTable" is argued
; for below by `ldb_spi e,0xf4` walking the caller's array, and that argument
; survives verbatim.  What decides it is that its sibling routine had to move
; anyway, and two images should not spell one driver two ways.
;
; Called from: 0xF85F30 and 0xF85F37 (a caller that pushes a channel number and
;          a pointer; not yet converted)
; Inputs:  on the stack -- (XSP+4) = channel number, (XSP+6) = pointer to 8 bytes
; Outputs: registers (channel<<5)|0x10 .. +7 written from that array.  A, XBC,
;          XIY advanced; DE preserved.
; Evidence: the register index is computed in the open -- `ld A,(XSP+0x04)`
;          then `sll a,0x05` and `set 4,A` (0xF85F60, 0xF85F63) give
;          (channel<<5)|0x10, which notes/prom_a_byte_checks.py re-reads --
;          and the loop count is the literal `ldb d,0x08` at 0xF85F6B: eight
;          (select, write) pairs, `ld (XBC),A` to the index port at +0 and `ld
;          (XBC+0x02),E` to the data port at +2. "FromTable" is `ldb_spi
;          e,0xf4` = `ld E,(XIY+)` at 0xF85F6F: the values walk the caller's
;          array. The four callers are pinned by the same script.
;          ⚠ "DSP" is the DEVICE reading -- this window is 0x007F0000 and the
;          KN5000 sub-CPU has the same routines against ITS OWN base -- not a
;          part number.
; Notes:   `ldb_spi e, 0xf4` is `ld E,(XIY+)`; 0xF4 is the register-address byte
;          for XIY with a post-increment of 1 (same convention as MEM_XIX_PI4 in
;          include/tmp95c061_sfr.inc).
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/boot/boot_and_main.s -- CPU 2, the SUB processor >>>
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
	ld A,(XSP+0x04)                              ; F85F59/F9804A  8f 04 21   argument 1: the channel number / channel number
	ld XIY,(XSP+0x06)                            ; F85F5C/F9804D  af 06 25   argument 2: a pointer to 8 bytes / source pointer
	pushw de                                     ; F85F5F/F98050  2a
	sll a, 0x05                                  ; F85F60/F98051  c9 ee 05   channel << 5 / channel * 0x20
	set 0x04,A                                   ; F85F63/F98054  c9 31 04   | 0x10 -> the register index for this channel's first slot / + 0x10 -> first data register
	ld XBC,DSP_REGS_BASE                         ; F85F66/F98057  a=41 00 00 7f 00 c=41 00 00 e0 00   the DSP register file
	ldb d, 0x08                                  ; F85F6B/F9805C  24 08   eight registers
DSP_ChannelRegs_Write8__loop:
	ld (XBC),A                                   ; F85F6D/F9805E  b1 41   select the register / select register A
	ldb_spi e, 0xf4                              ; F85F6F/F98060  c5 f4 25   ld E,(XIY+)
	ld (XBC+0x02),E                              ; F85F72/F98063  b9 02 45   write its value
	inc 1,A                                      ; F85F75/F98066  c9 61
	djnz8 d, DSP_ChannelRegs_Write8__loop        ; F85F77/F98068  cc 1c f3
	popw de                                      ; F85F7A/F9806B  4a
	ret                                          ; F85F7B/F9806C  0e

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>
; ---------------------------------------------------------------------
; DSP_WriteAllChannelRegs -- push the same parameter block to all four channels
;
; Called from: prom_b thunk 0xF42DE4 (`jp 0xF85F7C`), the LAST slot of the
;          kernel thunk block at 0xF42D60-0xF42DE7.  No prom_a site reaches it.
;          Its neighbour 0xF42DE0 publishes DSP_ChannelRegs_Write8 the
;          same way, so both DSP writers are exported next to the kernel API.
; Inputs:  XBC/XDE hold the data for channel 1; XIZ, XWA/XHL and XIX/XIY carry
;          the data for channels 0, 2 and 3 respectively -- the routine shuffles
;          them into XBC/XDE before each call.
; Outputs: 8 registers written in each of channels 1, 0, 2, 3, in that order.
; Evidence: "all four channels" is the four `pushw <imm> / calr` pairs and the
;          immediates are LITERAL -- 1 at 0xF85F7E, 0 at 0xF85F89, 2 at
;          0xF85F93, 3 at 0xF85F9D -- so the order 1, 0, 2, 3 is read off the
;          bytes and is not the natural one a reader would assume.  The tail
;          `inc 0,XSP` (0xF85FA3) drops 8 bytes, which is exactly those four
;          16-bit pushes.
; Sibling: byte-identical to the KN5000 sub-CPU's DSP_WriteAllChannelRegs, and
;          that is now a MEASUREMENT: over the sibling symbol's whole 44-byte
;          extent (kn5000 0x1FCFB) ZERO bytes differ.  Re-derived from the
;          sibling ELF by notes/prom_a_byte_checks.py.  ⚠ Its callee
;          DSP_WriteChannelRegs_Inner is NOT byte-identical -- see that header.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/boot/boot_and_main.s -- CPU 2, the SUB processor >>>
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
	push XBC                                     ; F85F7C/F9806D  39
	push XDE                                     ; F85F7D/F9806E  3a
	pushw 0x01                                   ; F85F7E/F9806F  0b 01 00   channel 1 first -- not 0 / channel 1 first
	calr DSP_WriteChannelRegs_Inner              ; F85F81/F98072  1e 24 00   c: calr (0xF98099 - 0xF98075)   DSP_WriteChannelRegs_Inner
	ld XBC,(XSP+0x0a)                            ; F85F84/F98075  af 0a 21   the XBC pushed on entry
	ld XDE,XIZ                                   ; F85F87/F98078  ee 8a
	pushw 0x00                                   ; F85F89/F9807A  0b 00 00   channel 0
	calr DSP_WriteChannelRegs_Inner              ; F85F8C/F9807D  1e 19 00   c: calr (0xF98099 - 0xF98080)
	ld XBC,XWA                                   ; F85F8F/F98080  e8 89
	ld XDE,XHL                                   ; F85F91/F98082  eb 8a
	pushw 0x02                                   ; F85F93/F98084  0b 02 00   channel 2
	calr DSP_WriteChannelRegs_Inner              ; F85F96/F98087  1e 0f 00   c: calr (0xF98099 - 0xF9808A)
	ld XBC,XIX                                   ; F85F99/F9808A  ec 89
	ld XDE,XIY                                   ; F85F9B/F9808C  ed 8a
	pushw 0x03                                   ; F85F9D/F9808E  0b 03 00   channel 3
	calr DSP_WriteChannelRegs_Inner              ; F85FA0/F98091  1e 05 00   c: calr (0xF98099 - 0xF98094)
	inc 8, xsp                                   ; F85FA3/F98094  ef 60   a: inc 0,XSP   drop the four pushed channel numbers / drop the four channel words
	pop XDE                                      ; F85FA5/F98096  5a
	pop XBC                                      ; F85FA6/F98097  59
	ret                                          ; F85FA7/F98098  0e

; >>>>>> moved from prom_a/wsa1_prom_a.s -- CPU 1, the MAIN processor >>>>>>>>>>
; ---------------------------------------------------------------------
; DSP_WriteChannelRegs_Inner -- write one channel's 8 registers from XBC/XDE
;
; Called from: DSP_WriteAllChannelRegs, four times
; Inputs:  channel number pushed by the caller, read back at (XSP+0x0C);
;          XBC = the first four bytes (C, B, then QBC's C and B),
;          XDE = the rest (E, D, then QDE's C and B)
; Outputs: registers (channel<<5)|0x10 .. +7 written.  XIY, WA, BC preserved.
; Evidence: the eight (index, data) pairs are literal and alternate strictly --
;          `ld (XIY),A` to the index port at +0, then one `ld (XIY+0x02),<reg>`
;          to the data port at +2, `inc 1,A` between pairs -- eight of each,
;          0xF85FB9 to 0xF85FF4.  The starting index is computed, not assumed:
;          `sll a,0x05` then `set 4,A` (0xF85FAE, 0xF85FB1) is (channel<<5)|0x10.
;
; ★ CORRECTED 2026-08-25.  This header used to say "the seventh write is
;   `ld (XIY+0x00),0x00`, i.e. a zero to the INDEX port rather than to the data
;   port at +2 ... in the KN5000's copy too, byte for byte".  THERE IS NO SUCH
;   INSTRUCTION.  No `ld (XIY+0x00),0x00` appears anywhere in this routine, and
;   none appears in the sibling either (kn5000-roms-disasm
;   v142/subcpu/kn5000_subprogram_v142.s:492-525).  The seventh DATA write is
;   `ld (XIY+0x02),C` at 0xF85FEB, an ordinary write of QDE's low byte.  A
;   trailing comment on 0xF85FE1 repeated the same invention and is gone too.
;
; ★ THE KN5000 DIFF, MEASURED, NOT ASSERTED.  Over the sibling symbol's whole
;   81-byte extent (kn5000 0x1FD27), 80 bytes are identical and EXACTLY ONE
;   differs: offset 15 = 0xF85FB7, the third byte of `ld XIY,0x007F0000`.  The
;   KN5000 holds 0x13 there, i.e. its DSP register file is at 0x00130000 and
;   this machine's is at 0x007F0000.  So the routine is shared and THE
;   PERIPHERAL BASE IS NOT -- copying the sibling's comment verbatim would have
;   written a non-existent address into this tree.  Both numbers are re-derived
;   by notes/prom_a_byte_checks.py from the sibling ELF.
; ---------------------------------------------------------------------

; >>>>>> moved from prom_c/boot/boot_and_main.s -- CPU 2, the SUB processor >>>
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
	push XIY                                     ; F85FA8/F98099  3d
	pushw wa                                     ; F85FA9/F9809A  28
	pushw bc                                     ; F85FAA/F9809B  29
	ld A,(XSP+0x0c)                              ; F85FAB/F9809C  8f 0c 21   the pushed channel number / channel number
	sll a, 0x05                                  ; F85FAE/F9809F  c9 ee 05   * 0x20
	set 0x04,A                                   ; F85FB1/F980A2  c9 31 04   + 0x10
	ld XIY,DSP_REGS_BASE                         ; F85FB4/F980A5  a=45 00 00 7f 00 c=45 00 00 e0 00   the DSP register file / ⚠ KN5000 has 0x00130000 here -- the one byte
	ld (XIY),A                                   ; F85FB9/F980AA  b5 41   register +0x10
	ld (XIY+0x02),C                              ; F85FBB/F980AC  bd 02 43
	inc 1,A                                      ; F85FBE/F980AF  c9 61
	ld (XIY),A                                   ; F85FC0/F980B1  b5 41   +0x11
	ld (XIY+0x02),B                              ; F85FC2/F980B3  bd 02 42
	inc 1,A                                      ; F85FC5/F980B6  c9 61
	ld (XIY),A                                   ; F85FC7/F980B8  b5 41   +0x12
	ld BC,QBC                                    ; F85FC9/F980BA  d7 e6 89   previous register bank
	ld (XIY+0x02),C                              ; F85FCC/F980BD  bd 02 43
	inc 1,A                                      ; F85FCF/F980C0  c9 61
	ld (XIY),A                                   ; F85FD1/F980C2  b5 41   +0x13
	ld (XIY+0x02),B                              ; F85FD3/F980C4  bd 02 42
	inc 1,A                                      ; F85FD6/F980C7  c9 61
	ld (XIY),A                                   ; F85FD8/F980C9  b5 41   +0x14
	ld (XIY+0x02),E                              ; F85FDA/F980CB  bd 02 45
	inc 1,A                                      ; F85FDD/F980CE  c9 61
	ld (XIY),A                                   ; F85FDF/F980D0  b5 41   +0x15
	ld (XIY+0x02),D                              ; F85FE1/F980D2  bd 02 44   data write 6 of 8
	inc 1,A                                      ; F85FE4/F980D5  c9 61
	ld (XIY),A                                   ; F85FE6/F980D7  b5 41   +0x16
	ld BC,QDE                                    ; F85FE8/F980D9  d7 ea 89   previous register bank
	ld (XIY+0x02),C                              ; F85FEB/F980DC  bd 02 43
	inc 1,A                                      ; F85FEE/F980DF  c9 61
	ld (XIY),A                                   ; F85FF0/F980E1  b5 41   +0x17
	ld (XIY+0x02),B                              ; F85FF2/F980E3  bd 02 42
	popw bc                                      ; F85FF5/F980E6  49
	popw wa                                      ; F85FF6/F980E7  48
	pop XIY                                      ; F85FF7/F980E8  5d
	ret                                          ; F85FF8/F980E9  0e
