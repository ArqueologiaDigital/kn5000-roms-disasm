# The KN5000 sound subsystem: what is covered, what crosses the boundary, and what is not there

**Date:** 2026-09-01
**Question:** is every routine that talks to the KN5000's tone generator, DSPs and
"acoustic modelling LSI" disassembled, where are the boundaries of that code, and what
data crosses them?

Reproduce everything below with:

```
python3 notes/sound/kn5000_sound_boundary.py --selftest        # 11 invariants
python3 notes/sound/kn5000_sound_boundary.py --calibrate --windows --tgregs \
                                             --misframes --coverage --unspellable
python3 notes/sound/kn5000_unspellable_forms.py --selftest      # the work list
python3 notes/sound/kn5000_unspellable_forms.py                 # per form
python3 scripts/converters/convert_sound_byte_blocks.py --selftest
python3 scripts/converters/convert_unspellable_forms.py --selftest
make gate-all        # 9 KN5000 + 4 WSA1R ROMs, byte-identical, plus assemble
```

---

## 0. The finding that comes first, because it invalidated the gate

`make gate-all` was green on 2026-09-01 while **four of the eight KN5000 images did not
assemble at all**. The toolchain pin had moved to `95f7f2d40428`, "[TLCS900] Refuse an
immediate or an index register that does not fit", and 31 `jrl` operands across v10/v9/v7
maincpu and the v1.42 sub-CPU payload were sign-extended 24-bit renderings of what this
backend takes as a **raw 16-bit displacement field** (`jrl t, 0xfd30` assembles to
`78 30 fd` at any address; the disassembly that produced these lines had written
`jrl t, 16776496` for 0xfffd30 = -720). The old assembler truncated silently, the new one
refuses.

Nothing noticed because **every image's object named only its ROOT source**, never the
~150 files the root `.include`s. `assert_byte_identical.py` rebuilds before comparing
precisely so that it cannot certify stale artefacts, and an incomplete prerequisite list
defeated that: the gate compared objects dated 2026-08-23.

Twelve of the 31 are in the sound path -- `DSP_EffParam_Apply_T0..TB`, the twelve
algorithm-type cases that tail-jump into `DSP_EffParam_Copy_V0..V7`.

Fixed in `179709ea`: operands truncated (no byte moved, which is the evidence that
truncation was all the old build ever did), prerequisite lists name every `.s` plus
`$(LLVM_MC)`, and `scripts/analysis/assert_images_assemble.py` now asks the assembler
directly from each root so the check does not depend on `make`'s dependency graph staying
correct. The byte gate also gained the three images it never resolved -- `subcpu_boot`,
`custom_data` and `hd-ae5000` are dumped as `.ic30`/`.ic19`/`.ic4`, so the old
`original_ROMs/<stem>.rom` lookup silently skipped them. All three were already identical.
The gate is now 9 KN5000 + 4 WSA1R images.

---

## 1. The census was measuring the wrong thing, three ways

`notes/sound/sound_coverage.py` reported 400 sites in 218 routines and **zero `.incbin`
inside or after any sound routine**, and concluded the sound subsystem was territorially
complete. Every word of that is true and the conclusion does not follow.

**1. `.incbin` is not the only way a byte can be undisassembled.** A `.byte` run is exactly
as un-decoded as an `.incbin` and it passes a "no `.incbin`" test. The v1.42 payload held
15,996 bytes of `.byte`, and two runs of it -- 0x0280FE-0x028838 and 0x028F75-0x029E30 --
were **already annotated in the source** as "MISLABELLED, THIS IS CODE", with 21 and 60-odd
named entry points, most of them tone-generator register writers.

**2. The `WAVE_RAM` window is sub-CPU-only, and even there it is not a chip.**
0x1E0000-0x1EFFFF is waveform RAM in `kn5000.cpp`'s `subcpu_map`, but in the **main CPU's**
map 0x1E0000-0x1FFFFF is the battery-backed 1 Mbit SRAM at IC21. The old tool scanned
`v10/maincpu/audio` with the sub-CPU window list, so 42 of its 49 "WAVE_RAM" sites are
sound-editor UI and note-mapping code touching NVRAM. **The main CPU has no window on any
sound chip at all** -- it reaches the tone generator only by sending commands to the
sub-CPU through the IC22/IC23 latch pair at 0x140000.

**3. A constant is not an access.** The old scan matched any hex literal inside a window,
so `cp xhl, 0x100000` (a float normalisation constant in `subcpu_fp_math.s`) and a
`.long 0x1e0c51c0` in a data table both counted.

### And the blind spot it documented is bigger here than it said

The old tool warned that a literal address scan misses register-indirect access. On the
KN5000 that costs the DSP window its data port outright: `DSP_Write_Channel` and
`DSP_WriteChannelRegs_Inner` load 0x130000 into XHL/XIY and then write `(xhl)` and
`(xhl+2)`, so the DSP **data** port is never named and "DSP_DATA 0" was a measurement of
the tool's own blindness.

**The larger miss is not addresses at all.** The busiest sound-chip line in the payload is
a **port pin**: P6 bit 7 (SFR 0x18) is strobed low around every tone-generator address
latch and high again before the data word -- 183 assert/182 release in the ROM image,
against 162 latch writes -- and no address-window scan can see one of them.

---

## 2. What was converted

Everything below is `.byte` that became instructions, byte-identically, verified by
`make gate` after each step. The framing authority is the committed MAME **unidasm**
listing, not a resync-on-failure sweep: this backend cannot spell every form the part has,
and a guessed instruction length reframes everything after it.

| round | what | bytes | instructions |
|---|---|---|---|
| 1 | `Voice_DSP_OutputConfig/2`, `Voice_DSP_SimpleCopy/2` | 656 | 222 |
| 2 | the ten `AudioChannel_Handler_Cmd*` + `AllVoices_Update_Variant3` | 3,520 | 1,168 |
| 3 | `ToneGen_WriteVoice_Reg*`, the `AudioMod_*` block, FIFO getters | 1,624 | 601 |
| 4 | nine blocks the tree had named `*_DataTable` / `*_TableData` | 919 | 355 |
| 5 | six more TG writers + 78 stranded inline runs | 620 | 230 |
| 6 | the DSP coefficient and routing routines | 1,233 | 417 |
| 7 | their selectors, fetches and epilogues | 570 | 220 |
| 8 | `ToneGen_PanTable_02D0DC`, `ToneGen_GlobalConfigTable_02D93E` | 117 | 49 |
| 9 | the 59 forms the assembler could not spell, 211 single-instruction sites | 833 | 211 |
| 10 | the three residual blocks `--misframes` still named | 179 | 71 |

Payload bytes emitted as instructions went **112,116 -> 121,624**; bytes emitted by a data
directive went **83,472 -> 73,964**. Sound-chip accesses the source can see went **636 in
190 routines -> 798 in 229 routines**, without a byte of the ROM changing.

### The call-graph fixpoint

Each round exposed the next. `--misframes` counts entry points whose first byte was emitted
by a data directive and which converted code branches or calls to; converting a caller makes
its callees visible for the first time. The sequence was
**4,778 -> 2,629 -> 1,057 -> 2,218 -> 632 -> 424 -> 275 -> 0 bytes**, the rises being the layers
that were invisible until their callers were decoded.  `--misframes` is now empty: zero entry
points, in both images.

### The coverage number that the source cannot influence

`--calibrate` counts an instruction's encoding **in the ROM image** and asks how many of
those occurrences the source has decoded as that instruction:

| pattern | before | after | what |
|---|---|---|---|
| `f0 18 b7` | 166/183 | **183/183** | `res 7,(P6)` -- assert the tone-generator select |
| `f0 18 bf` | 165/182 | **182/182** | `set 7,(P6)` -- release it |
| `f2 00 00 10 50` | 154/162 | **162/162** | `ld (0x100000),WA` -- latch a TG register address |
| `f2 02 00 10 50` | 115/122 | **122/122** | `ld (0x100002),WA` -- write TG register data |
| `f2 00 00 15 50` | 0/0 | 0/0 | **NULL CONTROL** -- same shape, aimed at 0x150000, which nothing decodes |

Every tone-generator opcode in `kn5000_subprogram_v142.rom` is now an instruction in the
source. The boot ROM was already at 24/24 and 22/22.

### What the last 833 bytes turned out to be

Round 9 closed the residue that rounds 1-8 had to leave: **833 bytes in 211 sites across 59
distinct instruction forms**, each already framed as one instruction by the committed unidasm
listing, each carrying that rendering as its comment. The claim attached to them was that they
were forms *this assembler backend cannot spell*. Measured form by form, that was true of eleven
of the fifty-nine:

| what was added to `tlcs900_backend` | sites | ROM truth |
|---|---|---|
| `cp8_imm_ri`, `cp8_imm_rid8` -- CP (mem),#imm8, sub-opcode 0x3F | 32 | `86 3f 40`, `8f 06 3f 00` |
| `add32_src_ri`, `add32_src_rid8` -- ADD r32,(mem)/(mem+d8) | 26 | `a7 80`, `af 04 84` |
| `cp16_src_rid8` -- CP r16,(mem+d8) | 2 | `9a fa f4` |
| `or_rrw_im` -- the register-indexed operand with an immediate | 12 | `d3 07 e4 e0 3e 08 00` |
| `lda_rrq` -- LDA whose INDEX is a previous-bank register | 2 | `f3 07 e4 e2 36` |

**The other 48 forms -- 137 of the 211 sites -- already had a spelling.** `lda_rr`, `ld_rrb/w/l`,
`st_rrb/w`, `jp_rr`, `ld_erpb_rr`, `ldb_erp`, `lds_erpb`, `and_erpb`, `add_erpw`, `add_spil`,
`minc1_16`, `ldw`, `bit`, `set`, `cpib_da`, `and8_imm_rid8`. ★ In particular
**the register-indexed `(Xrr+Rn)` operand was never missing**: `lda_rr`, `ld_rr[bwl]` and
`st_rr[bwl]` take base and index as separate typed operands and have since before this work.
What `95f7f2d40428` refuses is the `(xix+iz)` **MEMri syntax** -- one spelling of the operand,
not the encoding -- and a previous lane read that refusal as the encoding being unreachable.
`notes/sound/kn5000_unspellable_forms.py` is the tool that separates the two: it asks llvm-mc for
each form and calls it spellable only if the bytes come back identical.

* **`--misframes` is at zero.** Its last reading was 18 entry points. Fifteen were labelled
  routines whose FIRST BYTE was one of these unspellable instructions -- the 275 bytes are those
  routines' spans, and the undisassembled part of each was a single instruction, so round 9 closed
  all fifteen. The remaining three carried a 0-byte span because they sit INSIDE a data run rather
  than at a label, and those were three genuine undisassembled blocks:
  `AudioMod_Porta_Curve_JumpBase` (95 B, the computed-goto target of `jp T,XIX+WA` and the reason
  its bytes are code rather than a pointer table), `DSP_RouteCoeffs_TypeA_CopyLoop` and
  `DSP_RouteCoeffs_TypeB_CopyLoop` (42 B each, two copies of the same coefficient copy loop).
  Round 10 converted all three with `convert_sound_byte_blocks.py`, whose unidasm-boundary guard
  is what makes framing them as code defensible.
* **The misleading names are left alone.** `VoiceCC_DataTable_0280FE`,
  `ToneGen_ExtParams15_DataTable`, `Voice_ProgChange_TableData` and the rest name code, and
  each block's header already records both a rename proposal and an explicit decision to
  leave the choice to the maintainer. Decoding the bytes does not make that call ours.

---

## 3. Per-routine coverage

`--coverage` asks, for every routine that touches a sound chip, whether its control flow
stays inside disassembled text -- both an outgoing edge into a data-framed byte and a
fall-through off the end of source.

```
v142_subcpu : 229 sound routines, 229 clean
subcpu_boot :  36 sound routines,  36 clean
```

Zero fall-throughs, zero edges into data, in either image. Unchanged by rounds 9 and 10 --
which is the point: those rounds moved no byte and reframed nothing, they only changed how
already-framed instructions are spelt.

Alongside it, after rounds 9 and 10:

```
--unspellable : 0 sites, 0 bytes, 0 forms   in BOTH images
--misframes   : 0 entry points, 0 bytes     in BOTH images
```

and the two reachability figures the sound work must not disturb are where they were:
`notes/reachability_kn5000.py` **37 STRONG-with-evidence bytes**, and
`wsa1 && notes/reachability.py --targets` **STRONG 17 / ANY 1,702 / 17 spans**.

---

## 4. The chip boundary

### The device inventory, exhaustively

`--windows` lists **every** direct-addressing access above the 1 MB DRAM, by 64 KB page.
This is an enumeration, not a search for something already expected: a part the window list
does not mention would have to appear here.

```
v142 payload   0x100000  361   IC303 tone generator, address latch + data port
               0x110000    4   IC303 keybed data / status (A23 high)
               0x120000    5   inter-CPU latch pair (IC22 / IC23)
boot ROM       same three, plus 0xFF0000 = its own ROM
reached ONLY through a register base, so absent above:  0x130000 (DSP), 0x1E0000
```

Nothing else. There is no fourth memory-mapped device in either sound image.

### IC303 -- the tone generator (TC183C230002)

Two windows, selected by P6.7 driving A23:

| address | dir | meaning |
|---|---|---|
| 0x100000 | W | register-ADDRESS latch. Value = `(register << 6) | channel`. |
| 0x100000 | R | active-voice bitmap (one read, in `ToneGen_Read_Register`). |
| 0x100002 | W | register DATA, 16-bit. **Never read.** |
| 0x110000 | R | keybed / voice data. No writes. |
| 0x110002 | R | keybed / voice status. No writes. |

**The per-word sequence**, identical at all 162 sites:

```
res 7,(0x18)          ; P6.7 low  -- assert the select
add wa,<register<<6>  ; channel + register base
ld  (0x100000),wa     ; latch the address
nop
set 7,(0x18)          ; P6.7 high -- release it
ld  (0x100002),wa     ; or stiw (0x100002),<immediate>
jr  $+2 ; nop ; nop ; nop     ; settling
```

**The registers the firmware writes** (`--tgregs`, 148 latch sites resolved in the payload,
22 in the boot ROM):

| reg | latch base | sites | notes |
|---|---|---|---|
| 0x01 | 0x0040 | 1 | wave selector: `class = w>>12` (1 MB page), `entry = w & 0x0FFF` |
| 0x02, 0x03 | 0x0080, 0x00C0 | 5, 3 | 0x03 written with immediate 0x0000 |
| 0x04, 0x05 | 0x0100, 0x0140 | 3, 3 | the stereo pan pair |
| 0x06 | 0x0180 | 4 | per-voice envelope level (write side of MAME's read-back) |
| 0x07 | 0x01C0 | 6 | |
| 0x10-0x14 | 0x0400-0x0500 | 3,4,3,3,1 | |
| 0x15-0x17 | 0x0540-0x05C0 | 12,12,5 | immediate **0x8100** = the mute/strobe value |
| 0x18, 0x19 | 0x0600, 0x0640 | 6, 2 | |
| 0x20-0x29 | 0x0800-0x0A40 | 24,29,4,1,3,3,1,3,3,1 | the ten envelope words, `(target<<8) | rate` |

The envelope column is an **independent corroboration**: an older pass recorded exactly
those ten counts by scanning the ROM image for the opcode bytes `D8 C8 <lo> <hi>`, a
different method with a different tool, and wrote them into the payload's own comments.
`--selftest` asserts the two agree.

`ToneGen_ExtParams15_DataTable` is the firmware's clearest statement that **the chip has two
channel banks split at channel 0x40**, each with its own register-base set: below 0x40 it
strobes 0x0540+ch from shadow +0x3A with companion 0x01C0+ch <- +0x38, at or above it
strobes 0x0580+ch from +0x3E with companion 0x0600+ch <- +0x42.

**Negative result, still holding after this work:** nothing in either sub-CPU image reads
wave data. The five reads in the whole payload are the active-voice bitmap, one keybed
event and one voice on/off bit. The wave ROMs IC304-307 hang off IC303 and are in no CPU's
address space.

### 0x130000 -- a 4-channel x 8-register block

Reached only through a register base (`ld xhl,0x130000`, then `(xhl)` and `(xhl+2)`), which
is why an address scan never sees the data port. Address = `channel * 32 + 0x10 + index`,
index 0..7; `DSP_Init_Channels` writes the pattern 0x5A5A5A5A to all four channels and then
four config words 0x0101001F, `A += 0x20` per channel.

**Which chip decodes it is [UNCERTAIN].** `kn5000.cpp` maps it to IC311 while recording that
it is *not* the uPD6383GF host interface, since the microprogram and coefficient uploads go
over port PZ with the port 7 strobes. What is certain is that **it is not the tone
generator**: every tone-generator word is bracketed by the P6.7 select strobe and no access
to 0x130000 in either image is. The boot ROM called this `TONE_GEN_BASE` and named its four
writers `INIT_TONE_GEN` / `TONE_GEN_WRITE` / `WRITE_TONE_REG_*`; those routines are byte for
byte the payload's `DSP_Init_Channels` / `DSP_Write_Channel` / `DSP_WriteAllChannelRegs` /
`DSP_WriteChannelRegs_Inner`. The names are kept (the docs site, `symbols/` and `archive/asl`
all cite them) and the comments corrected.

### IC311 -- DSP1 (NEC uPD6383GF-3BA), a parallel port transport

No memory window: a byte port plus handshake pins.

| pin | SFR | direction | meaning |
|---|---|---|---|
| PZ (whole byte) | 0x68 | W | command/data byte port |
| P7.3 | 0x1C | W | write strobe, active low |
| P7.4 | 0x1C | W | read strobe, active low |
| P7.5 | 0x1C | W | DSP1 chip select, active low |
| P7.6 | 0x1C | W | command/data select: 0 = command, 1 = data |
| PH.0 | 0x44 | R | ready / status |
| PH.1 | 0x44 | W | DSP1 reset, active low |

`DSP_Send_Command(chip, byte)`: deassert read, deassert write, select, read status,
deselect -- each poll bracketed by `ei 6` / `ei 0`, so interrupts below level 6 are masked
for the poll and re-enabled between polls. The counter starts at **0x1F40 = 8000 polls**, so
it always terminates. On ready: deselect, deassert read, assert write, command mode, select,
re-read status, and if status is non-zero write the byte to PZ. Cleanup always deselects,
deasserts write and returns to data mode. It calls `Debug_Print_String("\n[") +
Debug_Print_Byte(cmd) + Debug_Print_String("]\n")` on **every** byte.

Its parameter protocol is an 11-byte sequence ending in a 24-bit value packed 7+8+8+1 with a
0x15 tag in the last byte -- the 36-bit microcode word packing.

### IC310 -- DSP2 (Matsushita MN19413), a bit-banged two-wire link

| pin | SFR | direction | meaning |
|---|---|---|---|
| PF.0 | 0x3C | W | serial DATA (SDA) |
| PF.2 | 0x3C | W | serial CLOCK (SCLK) |
| PE.6 | 0x38 | W | DSP2 chip select, active low |
| PH.2 | 0x44 | W | DSP2 reset, active low |

Corroborated outside the firmware by the schematic net names `DSP2DA` / `DSP2SCK` /
`DSP2CS`. **Write-only**: the board gives IC310 no data-in line, so unlike IC311 there is no
ready bit, no timeout and no error return. The start sequence is an I2C-style START --
clock high, ~19 `nop`, data high, 1 `nop`, data LOW while clock is HIGH, ~16 `nop`, clock
low -- and the firmware's own trace string for it is `"<sta>"`. Its parameter protocol is
COMMAND 0x30, DATA 0x00, DATA (index & 0xFF), then the 16-bit value low byte first.

---

## 5. The acoustic modelling LSI: **not separately present on the KN5000**

The goal names three things. Two are mapped above. The third is not a part on this machine,
and the evidence is a measured negative plus a positive identification of what the name
actually refers to.

* **The exhaustive window enumeration** (section 4) finds three memory-mapped devices in the
  sub-CPU's space and no fourth. The port-pin enumeration finds two chips beyond IC303.
* **The audio-section IC inventory** is IC303 (tone generator) + IC304-307 (its private wave
  ROMs) + IC308/IC309 (the two delay DRAMs) + IC310 (MN19413) + IC311 (uPD6383GF) + IC313
  (PCM69AU DAC). There is no additional signal-processing part.
* **What the name refers to is a FEATURE, not a chip.** The KN5000 has a front-panel
  **ACOUSTIC ILLUSION** button and an LCD page with four types -- STANDARD, PERCUSSIVE,
  SYMPHONIC, DEEP SPACE. Those are effect-algorithm **slots 57, 58, 59 and 60**, and
  `dsp/analysis/EFFECT-CHIP-MAP_findings.md` places all four on **IC310**, not IC311 --
  the chip the whole main mix passes through (IC303 SDO0 -> IC310 SDI; IC310 SDO1/SDO2 ->
  IC313). The acoustic-space processing is four microcode programs on the second DSP.

So: **acoustic modelling on the KN5000 is a program running on DSP2, not a dedicated LSI.**
The machine that does have a dedicated acoustic-modelling part is the SX-WSA1R, whose whole
synthesis method is named for it; that is lane S2's tree.

---

## 6. Contradictions to record

1. **The gate was green while a third of the images did not compile.** Section 0.
2. **`WAVE_RAM 0x1E0000-0x1EFFFF` is not a sound-chip window.** In `kn5000.cpp` it is
   `.noprw()`, a stub. All eight occurrences in the payload load it as a **destination
   address for an inter-CPU DMA push** -- `InterCPU_E1_DMA_Transfer(src 0x007800, len 0x72AA,
   dst 0x1E0000)`, and reply buffers in `Audio_Cmd_ToneEdit_Reply_Send` and
   `InterCPU_Reply_EditBuffer_Block` -- i.e. the **main CPU's** IC21 battery SRAM. No
   firmware evidence supports it being waveform RAM in the sub-CPU's own space.
3. **The main CPU is not in the window list's scope at all.** It has no sound-chip window;
   `v10/maincpu/audio` reaches the tone generator only through the sub-CPU.
4. **`--unspellable` was counting DATA TABLES as unspelt instructions.** Its rule was "a `.byte`
   line with a comment", and the boot ROM's velocity-curve and error-bit tables annotate every
   row -- so it reported **562 bytes in 45 forms** for `subcpu_boot` that are not instructions at
   all. Only three of those 81 lines even had bytes that form an instruction, and none of the
   three had a comment that was one. The rule is now: the committed unidasm listing must decode
   exactly those bytes as ONE instruction *and* the comment must be that rendering. The payload's
   211/833/59 is unchanged by the tightening, which is the evidence that it was measuring the
   right thing there; the boot ROM's figure was noise and is now 0.
5. **The 8-bit INDEX register's file address was inverted in the backend, and the byte gate could
   not see it.** The register file is byte-addressed and little-endian, so a word register's low
   half sits at offset 0 -- `A`=0xE0, `W`=0xE1, `C`=0xE4, `B`=0xE5 -- and `TLCS900MCCodeEmitter`
   had it the other way. All four call sites in this tree (`ld_rr8b a, xhl, w` twice in
   `scoop_display.s`, `ld_rr8w bc, xix, w` once in `midi_dispatch_handlers.s`, per image) named
   the WRONG register to obtain the RIGHT byte, so the gate stayed green while the source said
   `w` where the CPU reads `A` -- and at both `scoop_display.s` sites the preceding instruction is
   literally `ld a, l` or `ld a, c`. Corroborated by MAME unidasm over all 32 codes 0xE0-0xFF.
   Fixed in `4149d0474bf8`, sources corrected, gate still green.
6. **"Territorially complete" was doing work it cannot do.** `subcpu/boot` has zero
   `.incbin` and 99,209 of its 131,072 bytes come from data directives -- but 98,304 of
   those are the leading 0xFF filler (only 4,352 bytes of the image are not 0xFF), so the
   boot ROM really is essentially fully disassembled. The payload's `.byte` was a different
   story, and the same phrase covered both.

## 7. What the next pass needs

* **Nothing in the sound path.** `--unspellable` and `--misframes` are both at zero in both
  images, `--coverage` is 229/229 and 36/36, all 8 KN5000 images assemble, and 9 KN5000 + 4
  SX-WSA1R ROMs rebuild byte-identical. Every byte the tone generator, either DSP or the acoustic
  modelling programs are reached through is an instruction in the source.
* The `*_DataTable` / `*_TableData` names on code are still a maintainer decision. Decoding the
  bytes did not make that call ours, and rounds 9 and 10 did not touch a name or a comment.
* **The remaining KN5000 debt is elsewhere**: `notes/reachability_kn5000.py`'s 37
  STRONG-with-evidence bytes in the v10 maincpu, which is a different tree and a different
  question.
* ⚠ **The LLVM TLCS-900 DISASSEMBLER is not trustworthy and nothing here depends on it.** Asked
  for the 63 distinct byte strings in the residue, it refused 51 and got at least three of the
  remaining twelve WRONG -- `ba 01 cf` came back as `and (xde+1), xsp` where the hardware and
  unidasm both say `bit 7,(XDE+0x01)`, and `bf 04 02 00 00` as `ldmi16` where sub-opcode 0x02 is
  `ldw`. The framing authority is the committed unidasm listing and the encoding authority is a
  round-trip through the ASSEMBLER; the backend's own `--disassemble` is neither.
