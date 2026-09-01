# The WSA1's sound-chip boundary: which registers, which direction, what values, in what order

Lane S2, 2026-09-01.  Scope: every WSA1 routine that reaches a sound chip, on
**both** processors.  Nothing in this note is a rename; `Dev10C_` and `Dev104_`
keep the prefixes `FINDINGS-prom_c-tone-generator.md` §0 argued for.

Reproduce every figure:

```
python3 notes/sound/wsa1_sound_boundary.py --selftest      # 18 checks, 0 failures
python3 notes/sound/wsa1_sound_boundary.py                 # the per-register census
python3 notes/sound/wsa1_sound_boundary.py --windows       # literal scan vs following
python3 notes/sound/wsa1_sound_boundary.py --routines      # per-routine coverage
python3 notes/sound/wsa1_sound_boundary.py --values        # what crosses, as immediates
python3 notes/sound/wsa1_sound_boundary.py --p7            # the DSP transport
python3 notes/sound/wsa1_dev104_vs_kn5000.py --selftest    # 17 checks, 0 failures
python3 notes/sound/wsa1_dev104_vs_kn5000.py               # the device alignment
python3 notes/sound/wsa1_dev104_vs_kn5000.py --control     # the positive control
```

The source is certified by `python3 scripts/analysis/assert_byte_identical.py`
and the whole-tree gate `make gate-all` from the repository root.

---

## 0. ★★ Two corrections to the window list the coverage claim was computed over

`../notes/sound/sound_coverage.py` — the tool shared with the KN5000 lane —
defines the WSA1's sound subsystem as five windows on CPU 2 and measures
completeness over them.  Its own docstring says the windows are *"the one input a
reader must check: if a window is wrong, every figure here is wrong in the same
direction, and nothing else in the tool can notice."*  Two things are wrong with
that list, and neither is a wrong address; both are **omissions**, which is the
failure mode that sentence describes.

### 0.1 The DSP register files are missing — one per processor

| | address | what converts it | what identifies it |
|---|---|---|---|
| CPU 2 | **0x00E00000** | `prom_c/boot/boot_and_main.s`, 4 routines, 234 bytes | `DSP_WriteChannelRegs_Inner` is **80 of its 81 bytes identical** to the KN5000 sub-CPU routine of the same name at 0x1FD27; the one differing byte is inside the base literal, 0xE0 here against 0x13 there |
| CPU 1 | **0x007F0000** | `prom_a/wsa1_prom_a.s`, 5 routines | the same 44-byte `DSP_WriteAllChannelRegs` is present a **third** time at 0xF85F7C, and prom_a's own inline comments at 0xF85F40 / 0xF85F66 / 0xF85FB4 already read *"the DSP register file"* |

`0x00130000` is exactly the address the shared tool lists for the KN5000 as
`DSP_ADDR` / `DSP_DATA`.  So the two machines' DSP register files are the same
driver at two base addresses, the KN5000's is in the list and the WSA1's two are
not.  Measured: **19 accesses on CPU 2 across 3 routines, 22 on CPU 1 across 5**,
all of them `{+0 register number, +2 register value}`, 8-bit data, four channels
of 32 registers each with the channel's eight data bytes at `channel*0x20 + 0x10`.

⚠ "DSP" is the **sibling project's** name, borrowed because the same bytes drive
it there.  `prom_c/boot/boot_and_main.s` states that at length and this note does
not upgrade it.

### 0.2 The DSP EFFECT transport is not a window at all, so no window list can hold it

DSP effect microcode leaves CPU 2 through **port P7 = SFR 0x0013**, in a
hand-rolled parallel handshake with three destinations (strobe on P5 bit 4 / P5
bit 5 / P2 bit 7, valid on PB bit 5, command qualifier on P5 bit 3, ready polled
on P9 bit 3, 8000-iteration timeout).  That is established by
`notes/prom_c_dsp_port.py`, and that a P7 stream **is** DSP effect data by
`notes/FINDINGS-prom_c-p7-is-dsp-effects.md`: effect 5 PHASER's 164-byte stream
at 0xFD7764 is byte-identical to the KN5000's `DSP_Eff05_Coef_Bytecode`, and the
join of prom_c's program table to prom_b's 128 effect names is a bijection on all
56 named programs with a negative control over all 127 rotations.

★ **The nine P7 data writes are spelled `extpfx5 0x8E, 0x08, 0x19, 0x13, 0x00`** —
a raw-encoding directive for `ld (0x0013),(XIZ+0x08)`, used because llvm-mc cannot
spell the instruction.  The destination address is not an operand; it is two
payload bytes of an assembler directive.  **No address census, however written,
can see it.**  `--selftest` asserts both halves: nine P7 writes exist, and zero
operands anywhere in the three images dereference 0x0013.

That is the strongest single argument in this note that *"which windows are
touched"* is the wrong instrument for *"is the sound code covered"*.

---

## 1. The corrected per-register census — TG_DATA is not zero

The shared tool searches for a window's addresses **as literals**.  Every WSA1
sound device is reached by loading a base into a 32-bit register — and often
spilling it into a stack slot and reloading it from there — so its displacement
uses name nothing the scan can match.  Following the base into its uses:

| device | +0x00 | +0x02 | +0x04 | total | shared tool |
|---|---|---|---|---|---|
| **Dev10C** 0x0010C000 | 198 W, 70 routines | **155 W, 58 routines** | **2 R, 2 routines** | 355 | reported `TG_DATA 0`, `TG_STATUS 0` |
| **Dev104** 0x00104000 | 39 W | 39 W | — | 78 | 9 literal sites |
| **KeyScan** 0x00108000 | 2 R | 1 R, 1 W | — | 4 | 5 literal sites |
| **DspRegs_C** 0x00E00000 | 10 W | 9 W | — | 19 | **not in the list** |
| **DspRegs_A** 0x007F0000 | 12 W | 10 W | — | 22 | **not in the list** |

Reads and writes are separated, and the separation is itself a check: Dev10C's
`+0x04` is **read twice and never written**, while `+0x00` and `+0x02` are
**written and never read**.  A walk that was mis-attributing operands would not
produce that clean a split.

### 1.1 Calibration: three exact agreements and one calibrated disagreement

The walk is checked against counts established by other tools before it existed:

| count | source | this walk |
|---|---|---|
| `Dev104_WriteAllChanRegs` = 19 registers × 2 = **38** | `prom_c_tg_regmap.py --dev104` | 38 ✔ |
| `Dev10C_WriteGlobalRegs` = 13 registers × 2 = **26** | `FINDINGS-prom_c-tone-generator.md` §7 | 26 ✔ |
| `DSP_WriteChannelRegs_Inner` = 8 × 2 = **16**, in both images | `boot_and_main.s`, prom_a | 16 and 16 ✔ |
| `Dev10C_WriteAllChanRegs` = 23 SELECT + 23 DATA = **46** | `prom_c_tg_chanmap.py --selftest` | **45** |

★ The disagreement is the honest one and is asserted as 45, not papered over.
`prom_c_tg_chanmap.py` recovers the store whose base register survived a `calr`
by disassembling the callee and reading its push/pop set; this walk's rule is
*"a call clears every register"*, so it cannot.  If that number ever reads 46
without the rule changing, the rule has been broken.

### 1.2 The values that cross, where they are immediates

```
Dev10C +0x00   13 distinct immediates: 0x200 0x201 0x202 0x203 0x204 0x205
                                       0xC00 0xC01 0xC02 0xC03 0xC04 0xC05 0xE00
Dev10C +0x02    5 distinct immediates: 0x0000 0x7E00 0x8100 0xFF00 0xFF80
Dev104 +0x00    1 distinct immediate:  0x0800
```

The thirteen at Dev10C `+0x00` are **exactly** `Dev10C_WriteGlobalRegs`'s thirteen
global register numbers (§7 of the tone-generator note), recovered here from the
instruction stream instead of from the routine.  The five at `+0x02` are exactly
the reset and gate values §5 and §6 record: `0x8100` = gate with bit 15 and bit 8
set, `0x7E00` = the stopped value, `0xFF80`/`0xFF00` = the quiescent pair of
blocks 0x800/0x840, `0x0000` = block 0x0C0 at reset.  Everything else crosses
through a register and is not knowable from the instruction alone.

---

## 2. Per-routine coverage: 89 routines, zero unconverted

`--routines` lists every routine that reaches a sound device, per image:

```
prom_a   5 routines, 22 accesses     (all DspRegs_A)
prom_b   0 routines,  0 accesses
prom_c  84 routines, 456 accesses
------------------------------------
        89 sound routines, 0 with unconverted text inside them.
```

No routine that touches a sound chip contains `.incbin`, on either processor.
That is the coverage goal, and it is met with the DSP register files and the P7
transport **inside** the measured set rather than outside it.

⚠ prom_b's zero is a real zero, not a gap: CPU 1's sound work is entirely in
prom_a, and prom_b is the UI/display/song-store half of that processor's firmware.

### 2.1 And nothing is hiding in the 87,118 bytes that are still `.incbin`

The paragraph above is a statement about routines a SOURCE scan can see.  prom_a
still has 29 `.incbin` spans and prom_b 123, and a driver living entirely inside
one would be invisible to it.  So the unconverted BYTES were searched directly,
for the instruction every sound driver in this firmware starts with -- opcode
`0x40..0x47` followed by a device base as a 32-bit little-endian immediate:

```
python3 notes/sound/wsa1_sound_in_unconverted.py            # 7 checks, 0 failures
```

| | in CONVERTED bytes | in 87,118 UNCONVERTED bytes |
|---|---:|---:|
| the five real device bases | **122** | **0** |
| four bases of identical shape that no chip decodes | 0 | 0 |

★ Three controls, because `../notes/sound/sound_coverage.py` records a byte
search of this kind that was NOT evidence (272 real against 188 null, a 1.45x
ratio in zero-heavy data) and ends *"Do not reintroduce that search without its
null"*:

* **POSITIVE:** the search finds 102 `ld <X..>,0x0010C000` sites in prom_c's
  converted bytes -- the source census's number exactly, arrived at from the ROM
  instead of from the listing.  An instrument that found nothing anywhere would
  not be evidence of absence.
* **NULL:** four undecoded bases of the same shape score 0 in both halves.
* **FALSIFIABILITY:** prom_b's unconverted spans contain **1,102** five-byte
  sites whose first byte is an `ld <Xrr>,imm32` opcode.  A hit was possible; none
  of them was a sound base.

⚠ RESIDUE: a driver handed its base as an ARGUMENT would not be found.  What
bounds that is that all 102 converted references to 0x0010C000 are the single
instruction shape `ld <X..>,0x0010C000` -- this firmware does not pass device
bases around.

⚠ What this does **not** check is that a routine's callees are converted.  It
checks that the routine's own text is.  The tree-wide answer to the callee
question is `notes/reachability.py --targets`, which reports **STRONG 17 bytes,
ANY 1,702, in 17 spans** — all seventeen already formally refused as data.

---

## 3. Which device is the ACOUSTIC MODELLING LSI

The SX-WSA1R is a physical-modelling instrument, so unlike the KN5000 it should
carry a modelling part.  CPU 2 drives two devices of the same general shape —
64 channels of parameter registers numbered `block*0x40 + channel` — and
`FINDINGS-prom_c-tone-generator.md` §0 refused to name either.  The comparison
that separates them is with the **KN5000 sub-CPU as a control group**: a PCM
sample-playback engine, closely related firmware, no physical modelling.

```
role                     WSA1 CPU 2 (prom_c)        KN5000 sub-CPU
------------------------------------------------------------------------------
tone generator           0x10C000  (102 refs)       0x100000  (335 refs)
keybed                   0x108000  (5 refs)         0x110000  (32 refs)
inter-processor link     0x100000  (8 refs)         0x120000  (14 refs)
DSP register file        0xE00000  (21 refs)        0x130000  (10 refs)
wave / tone bank         -- none --                 0x1E0000  (11 refs)
★ NO COUNTERPART         0x104000  (9 refs)         -- none --
```

**One-to-one, with exactly one extra row.**  Two further facts make the row
meaningful rather than an artefact of counting:

1. **Dev10C is a tone generator of the KN5000 family, so it is not the modelling
   part.**  Its 22 register blocks are the KN5000 tone generator's 22 blocks in
   the same order (`FINDINGS-prom_c-dev10c-sibling-register-map.md` §1, checked
   against the sibling's own comment block rather than a retyped list), and its
   port shape `{+0 select, +2 data, +4 readback}` is the KN5000 tone generator's
   port shape, `+4` included — 0x00100004 occurs in the sibling source and its own
   header calls it *"a status word"*.  The KN5000 does no acoustic modelling.
2. **The two register files are different shapes, not two windows onto one.**
   Dev104 is **19 CONTIGUOUS blocks 0x000..0x480**.  Dev10C is **22 SPARSE
   blocks** — 0x000..0x180, then a hole to 0x400..0x500, then a hole to
   0x800..0xA40.  Ten block *numbers* coincide, which they must, because both
   devices number registers the same way; the sets do not.

### The grade

* ★ **ESTABLISHED:** 0x00104000 is the only per-channel synthesis device CPU 2
  drives that has no counterpart in the PCM sibling, and its register file is a
  different shape from the tone generator's.
* ⚠ **INFERENCE, RANKED, NOT PROOF:** therefore 0x00104000 is the acoustic
  modelling section.  Supporting it: it is per-CHANNEL on the same 64-channel
  numbering; it is reset channel by channel *inside* `Dev10C_ResetAllChannels`,
  so the two files are two halves of one voice; and all four note-on staging
  paths write **both** devices for **every** voice.
* ⚠ **AN ALTERNATIVE THAT FITS EVERY NUMBER HERE:** that the two devices are the
  *driver* and the *resonator* halves of one modelling engine rather than "the
  PCM part and the modelling part".  Nothing measured distinguishes those two
  readings — and both of them put the modelling in 0x00104000's register file.
* ⚠ **WHAT WOULD REFUTE IT:** a part number, or a KN5000 sub-CPU device below the
  detection threshold that is a 64-channel parameter file.  `--control` runs the
  identical method over CPU 1, whose devices are already established, and reports
  that it loses two of six — one under the reference threshold, one at an
  unaligned base.  Both errors hide devices rather than invent them, which is the
  direction that can make this finding wrong.

★ **NOTHING IS RENAMED.**  §0 of the tone-generator note sets the bar for
restoring a role-bearing prefix at *"the day a converted routine turns a note
number into a CHANNEL argument"*, and this does not clear it.

---

## 4. The boundary in ORDER — initialisation, per-voice, polling

### 4.1 Power-on, from `MAIN` (0xF98B7D), in the order the instructions run

`MAIN` is task 1; nothing calls it — `EntryPoint_Records`' first record gives it
its PC and `Kernel_Start` starts it.  Its init chain is twelve calls; the
sound-bearing ones, in order:

| # | routine | what crosses the boundary |
|---|---|---|
| 1 | `ExtBoard_ProbeAndInstallBases` 0xFB0504 | installs eight 32-bit base slots at RAM 0x00D7ED (0xF00000 tone bank ×2, 0xE80000-0xEB0000 flash, 0x010000 staging, 0xC00000 board), probes the expansion board against the ROM string `"WSA1 EXTBD"`, then **calls `Dev10C_ResetAllChannels` (0xFB80E1)** |
| 1a | ↳ `Dev10C_ResetAllChannels` | the whole power-on sweep of **both** parameter devices — see §4.2 |
| 2 | 0xFC88A0, 0xFC8B9C | flash / EEPROM, not sound |
| 3 | 0xF9993E | key-state bitmap init; reads the keybed at 0x00108000 |
| 4 | `Serial0_Init` 0xF9919F | MIDI UART, and `Dev108000_Preload_80toBF` writes 0x0080+i to keybed +2 and 0x8000 to +0 |
| 5 | **`DSP_ChannelRegs_Init` 0xF98000** | 0x00E00000: for n = 0..3, registers `n*0x20+0x10 .. +0x17` := 0, then `n*0x20+0x1F` := 0x01 |
| 6 | 0xF997FA | key scan |
| 7 | `ADC_Init` 0xF98A02 | the two analog inputs |
| 8 | Timer1 (period from the fc byte at 0xFFFFEF), Timer3 | the tick the whole engine runs on |
| 9 | **`P7Units_BootLoadAndStartTask` 0xFA3127** | uploads **20 fixed P7 streams** to the three effect units (a strict subset of `P7Units_ReloadFixedStreams`' 22) and starts task 2, `P7Units_ServiceTask` |
| 10 | **`MidiMsg_SendBootSequence` 0xFB0A0D** | four MIDI messages through the engine's own handlers: `C0 00 …` program change, `B0 00 07 00` CC7 channel volume, `90 00 30 01` note 48 velocity 1, `B0 00 78 7F` CC120 all sound off |

★ Step 10 is worth keeping: the firmware **plays a note at the quietest audible
velocity and then silences everything** as the last act of initialisation.
"Priming the engine" is the obvious reading and is not established.

### 4.2 `Dev10C_ResetAllChannels` (0xFB80E1) — the reset image, in order

1. `Dev10C_WriteGlobalRegs(ROM 0xFE12B5)` → the thirteen global registers
   0x0200-0x0205, 0x0C00-0x0C05, 0x0E00 from thirteen consecutive ROM words
   (13 registers × 2 bytes = 0x1A, and 0xFE12CF − 0xFE12B5 = 0x1A exactly)
2. **0x00104000** register 0x0800 := the word at ROM 0xFE1313
3. for i = 0..0x3F: register `0x0840+i` := **0xFF00**, register `0x0800+i` := **0xFF80**
   (the count is a literal `ldb d,0x40`, not an address stride)
   ⚠ **CORRECTED 2026-09-01: this sweep is the TONE GENERATOR's, not 0x00104000's.**
   Following step 2, this step read as if it continued on the same device.  A bus
   trace of CPU 2's program space at 0x104000-0x104003 across 45 emulated seconds
   of boot (`kn7000_mame/tools/rigs/wsa1_dev104_bus_trace.lua`) measures 0x104000's
   written span as **0x0000..0x0800**, with nothing in 0x0801..0x087F ever written.
   The arithmetic agrees without needing the trace: the run touches **1217 distinct
   registers = 19 blocks x 64 channels + 1**, the +1 being step 2's single 0x0800.
   Had this sweep landed here it would have added 64 more.  Only step 2 is
   0x00104000's.
4. RAM 0x00D8DB ← ROM 0xFE12CF, **68 bytes** (the staging struct's exact span);
   RAM 0x00D91F ← ROM 0xFE133B, 38 bytes
5. for chan = 0..0x3F: `Dev10C_WriteAllChanRegs`, `Dev104_WriteAllChanRegs`,
   `Dev10C_WriteReg`, editing a bitfield at 0x00D91F between calls
6. for chan = 0..0x3F: `0x0840+i`:=0xFF00, `0x0800+i`:=0xFF80, `0x00C0+i`:=0x0000,
   `0x0000+i`:=0x7E00, then slots 1, 2 and 3
   ⚠ Same correction as step 3: the 0x0840/0x0800 pair here is the tone generator's.
   Which device each line in this step addresses is NOT disambiguated by the text
   above, and the trace is what separates them.

★ Step 5 is where the two devices are shown to be two halves of one voice: the
same loop, the same channel index, one call each.

### 4.3 One note-on

```
INT from the MIDI UART / the keybed -> ring -> MidiNote_Dispatch (velocity != 0 arm)
  -> MidiNote_OnByPartMode (0xFB3860)
       four-way switch on BITS 6-7 of part-record byte +0x10
         0x00  VoiceParams_Compute_A, then VoiceRegs_Stage_C or _A per voice,
               LOOPING OVER AT MOST FOUR VOICES (`cp L,4`), and driving 0x0010C000
               directly between voices: reg v+0x0840 := 0xFF00, v+0x0800 := 0xFF80
         0x40  VoiceParams_Compute_B, VoiceRegs_Stage_B
         0x80  VoiceParams_Compute_C, VoiceRegs_Stage_C
         0xC0  and the default: 0xFB3C0E, not traced
  -> VoiceRegs_Stage_*  ->  Dev104_WriteAllChanRegs  (19 registers, one channel)
                        ->  Dev10C_WriteAllChanRegs  (22 registers, one channel)
```

★ **`VoiceRegs_Stage_B` does not compute its 0x00104000 image at all.**  Stage_A,
_C and _D call `Dev104_PackStagingStruct` (0xFC4DBD); Stage_B calls
`Dev104_LoadStageBImage` (0xFC571A), which block-copies a **fixed 19-word image
from ROM 0xFE1315** into the struct and patches five fields.  So part mode 0x40
runs the second device from a constant.  ⚠ What that means is not established;
"a bypass or neutral configuration" is the obvious reading and is not proved.

### 4.4 Polling and read-back — the only two reads of Dev10C in the whole image

| routine | what it does |
|---|---|
| `Dev10C_PollBankAndRetire` 0xFA68FC | selects through `ld (xix),bc` at 0xFA6901, reads `+0x04` at **0xFA690A**; the register number is a byte from 0x0087CF multiplied by 2 |
| `Dev10C_ReadChanReg_0100` 0xFC7E57 | `add HL,0x0100` forms the selector, `ld (XIX),HL` at 0xFC7E6D selects, `ld BC,(XIX+0x04)` at **0xFC7E6F** reads.  A dedicated read accessor that does nothing else |

⚠ **CORRECTION.**  `FINDINGS-prom_c-tone-generator.md` §10 still reads *"0xFA68FC
is the only READ of 0x0010C000 located so far"*.  There are **two**, and the
second was already named in round 7 — the census here rediscovers it
independently.  That line is corrected in the same commit as this note.

The keybed's poll is the other direction of the same idea: read `+0x02`, test bit
0, and only then read the 16-bit event from `+0x00`
(`KeyScan_ReadEvent` 0xF9973D, `notes/FINDINGS-prom_c-keyboard-and-touch.md`).

### 4.4b 0x00104000's boundary: which of its 19 blocks the firmware MODULATES

The unrolled writer loads all nineteen; the seven small accessors show which ones
the firmware touches again after a note has started.  Each accessor was walked
with the tree's existing symbolic tool, which reports the SELECT and the struct
word that feeds it in execution order:

```
python3 notes/prom_c_tg_chanmap.py 0xFB796E 0x62 --dev 0x00104000 --pairs   # 0x01C0 0x0200 0x0240
python3 notes/prom_c_tg_chanmap.py 0xFB79D0 0x88 --dev 0x00104000 --pairs   # 0x0140 0x0180 0x01C0 0x0200 0x0240
python3 notes/prom_c_tg_chanmap.py 0xFB7A73 0x56 --dev 0x00104000 --pairs   # 0x00C0 0x0100 0x0240
python3 notes/prom_c_tg_chanmap.py 0xFB7AC9 0x3C --dev 0x00104000 --pairs   # 0x00C0 0x0100
python3 notes/prom_c_tg_chanmap.py 0xFB7B05 0x3C --dev 0x00104000 --pairs   # 0x0140 0x0180
python3 notes/prom_c_tg_chanmap.py 0xFB7B41 0x2A --dev 0x00104000 --pairs   # 0x0280
python3 notes/prom_c_tg_chanmap.py 0xFB7A58 0x1B --dev 0x00104000 --pairs   # block 0 only
```

| block | k | reached by a small accessor? | staging word |
|---|---|---|---|
| 0x0000 | 0 | **yes** — `Dev104_WriteChanReg0`, and written first by two accessors | word 0 |
| 0x0040 | 1 | no | 0x02 |
| 0x0080 | 2 | no | 0x04 |
| 0x00C0 | 3 | **yes** ×2 | 0x06 |
| 0x0100 | 4 | **yes** ×2 | 0x08 |
| 0x0140 | 5 | **yes** ×2 | 0x0A |
| 0x0180 | 6 | **yes** ×2 | 0x0C |
| 0x01C0 | 7 | **yes** ×2 | 0x0E |
| 0x0200 | 8 | **yes** ×2 | 0x10 |
| 0x0240 | 9 | **yes** ×4 | 0x12 |
| 0x0280 | 10 | **yes** — from a register, not a staging word | — |
| 0x02C0 … 0x0480 | 11..18 | no | 0x16 … 0x24 |

★ So the firmware **modulates blocks 0 and 3..10 after the note starts, and sets
blocks 1, 2 and 11..18 only as part of a whole-channel load.**  On a tone
generator that split is the boundary between per-note-modulated parameters and
set-at-note-on ones; what it is on this device is not established.

⚠ The relation `staging word = 2 × (block / 0x40)` holds at every site above,
which is the same relation `prom_c_tg_regmap.py --dev104` asserts over the
unrolled writer — two tools, two routines, one layout.

### 4.5 The 0x00E00000 DSP register file is REFRESHED, not just initialised

`DSP_ChannelRefresh_Loop` (0xF98118) is the **third** entry in
`EntryPoint_Records` — an interrupt-disabled endless loop that calls
`DSP_ChannelRegs_Write8` four times, once per channel.  So the eight data bytes
of each of the four channels are rewritten continuously for as long as the
machine is on, from RAM rather than from a one-shot boot image.

---

## 4.6 ★★ The shared-code result: ONE DSP driver, TWO processors

```
python3 notes/sound/wsa1_dsp_driver_shared.py            # 8 checks, 0 failures
```

| | |
|---|---|
| prom_a 0xF85F0F..0xF85FF8 | prom_c 0xF98000..0xF980E9 |
| 234 bytes, four routines | 234 bytes, four routines |

**231 of 234 bytes are identical.**  The three that differ are:

```
+0x034   prom_a 0xF85F43 = 0x7F      prom_c 0xF98034 = 0xE0
+0x05A   prom_a 0xF85F69 = 0x7F      prom_c 0xF9805A = 0xE0
+0x0A8   prom_a 0xF85FB7 = 0x7F      prom_c 0xF980A8 = 0xE0
```

— A23..A16 of each routine's `ld <Xrr>,imm32`, and nothing else.  `0x007F0000` on
CPU 1, `0x00E00000` on CPU 2.  Three routines each loading a 32-bit immediate,
all three differing in the same byte of that immediate and in no other byte of
234, is **one source assembled twice with one symbol changed** — the same
evidence shape as this tree's kernel result (`kernel/kernel.s` → 2,180 identical
bytes of prom_a and prom_c), at 234 bytes instead of 2,180.

★ **NULL CONTROL:** the same comparison at eight neighbouring alignments scores
between 5 and 19 of 234.  Only the true alignment matches, which is what makes
231/234 a fact about the code rather than about padding.

**The third copy.**  `DSP_WriteAllChannelRegs`, 44 of these bytes, is
byte-identical in the KN5000 sub-CPU at 0x1FCFB as well — three processors across
two products.  The 234-byte block as a whole is **not**: the KN5000's version
fills its buffer with the test pattern 0x5A5A5A5A where both WSA1 copies fill it
with zero, so only 12 of 74 bytes line up there.

### The label collision this exposed, and how it was resolved

The same four routines carried **two different names** in the two images.  The
brief's rule is to choose the better and adopt it, and the argument decided it in
prom_c's favour:

| prom_a had | now | why |
|---|---|---|
| `DSP_Init_Channels` | `DSP_ChannelRegs_Init` | the old name was **anchored to the weaker of two byte identities** — a 13-byte run shared with the KN5000, whose enclosing routine differs from this one in 62 of 74 bytes, against 231 of 234 shared with prom_c.  A transplanted name over non-transplanted bytes is exactly the error `notes/prom_c_sibling_map.py`'s docstring exists to prevent |
| `DSP_Init_Channels_Loop` | `DSP_ChannelRegs_Init_Loop` | its local label |
| `DSP_WriteChannelRegs_FromTable` | `DSP_ChannelRegs_Write8` | ⚠ **the old name was not wrong.**  "FromTable" is argued for in its own header by `ldb_spi e,0xf4` walking the caller's array, and that argument survives verbatim in the source.  What decides it is that its sibling routine had to move anyway and two images should not spell one driver two ways |
| `DSP_WriteChannelRegs_FromTable__loop` | `DSP_ChannelRegs_Write8__loop` | its local label |
| prom_b's thunk `T_DSP_WriteChannelRegs_FromTable` | `T_DSP_ChannelRegs_Write8` | follows the routine |

⚠ **The KN5000 citations are deliberately unchanged.**  `prom_a/wsa1_prom_a.s`'s
`llvm-nm names the label DSP_Init_Channels_Loop`, the `0x1FC95` line in
`FINDINGS-prom_a-tasks-and-dsp-refresh.md` and `boot_and_main.s:90` all name the
*sibling's* labels, not this tree's.

★ **The opportunity, not taken here.**  A shared `include/dsp_channel_regs.inc`
parameterised on one `DSP_BASE` symbol would make the two copies literally one
source, the way `kernel/kernel.s` already is.  That is a source-layout change with
its own byte gate and it belongs in its own pass, not bolted to a naming commit.

---

## 5. What this note does NOT establish

* **Any part number.**  No WSA1 ROM names a chip.  The one part number in the
  tree, `uPD6383GF` in `prom_c/p7/p7_module.s`, is flagged there as an import
  from a parts list and not a finding, and this note does not promote it.
* **That 0x00104000 is the acoustic modelling LSI.**  §3 grades that as a ranked
  inference and names what would refute it.
* **What any Dev104 register means.**  Nineteen registers, nineteen unknowns —
  and unlike Dev10C there is no sibling map to borrow, precisely *because* the
  sibling has no such device.  That is the largest open surface in the WSA1's
  sound subsystem and it is where the next pass belongs.
* **What the P7 stream bytes mean.**  §0.2 joins a NUMBER to a NAME and decodes
  no payload byte.

---

## 6. For the KN5000 lane, not acted on here

Two things this comparison surfaced on the other side of the fence.  This lane
owns `wsa1/` and changed nothing outside it; both are reported, not fixed.

1. **The shared tool's KN5000 window list omits 0x00120000**, which the KN5000
   sub-CPU references 14 times and which `subcpu_vectors.s:5` defines as
   `INTER_CPU_COMM_LATCHES`.  It is not a sound device, so no sound figure moves
   — but a window list that omits a 14-reference device is not a list to compute
   a completeness claim over.
2. **`kn5000.cpp`'s `subcpu_map` and the disassembly disagree about which address
   is the tone generator.**  The driver's commented-out line at 0x110000 reads
   *"tone_generator @ IC303"*, while the shared tool calls 0x110000 the keybed
   and 0x100000 the tone generator — and the sub-CPU source agrees with the tool
   (*"0x100000 and 0x100002 are its only TG ports"*, `kn5000_subprogram_v142.s`
   :24589, 171 and 161 references against 18 and 14).  Two documents about the
   same silicon, disagreeing, which is exactly the situation
   `FINDINGS-prom_c-tone-generator.md` §0 was written about.  Worth an
   evidence column on the KN5000 side.
