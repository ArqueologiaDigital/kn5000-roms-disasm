# The KN5000 tone generator's register interface, as the firmware drives it

**Date:** 2026-08-23  ·  **Sources:** `v142/subcpu/kn5000_subprogram_v142.s`,
`subcpu/boot/kn5000_subcpu_boot.s`, `v7|v9|v10/maincpu/**`,
`original_ROMs/kn5000_subprogram_v142.rom`, the two `table_data` mask-ROM dumps.
**Probes:** `analysis/tonegen-register-interface/` (see `README.md` for the exact commands).

The question this answers: *an emulated tone generator must be driven by the interface the
real chip has, not by data copied out of a ROM it cannot reach. What is that interface, and
is there a bulk ROM-to-register upload anywhere in the firmware?*

Short answers, both established from the ROM:

* **The interface is a two-port, address-latch-then-data register file on the SUB-CPU bus.**
  Every per-voice parameter the chip needs is written to it, one 16-bit word at a time.
* **There is NO routine that walks a large ROM table into TG registers.** The largest bulk
  upload in the whole firmware is a **68-byte** default-voice template pushed to 64 voices at
  power-up, and a 26-byte global-config block. The big tables (the 320 KB tone database) are
  *read to compute* the ~22 words of a per-voice register image; they are never sent.

---

## 0. Correction: `TGReg_*` in v7/v9/v10 is NOT the tone-generator interface

The `TGReg_Write*` family in `v{7,9,10}/maincpu/midi/midi_dispatch_handlers.s` (v9 line 15590 ff.)
is a MIDI *channel-controller default* writer. Each routine builds a 4-byte descriptor
`{part, cc, value, mask}` on the stack, loops parts 0..0x0F, and calls
`MidiTG_WriteRegByDescriptor` (v9:13282), which does a masked read-modify-write into a
per-part parameter block in **main-CPU RAM** — the block pointer comes from
`Part_LookupByIndex` (a table of 4-byte pointers at RAM `0x90F2`). No hardware is touched.

The values they install are the GM-ish controller defaults: CC3 expression 0x64, CC4 pan
0x00/mask 0x08, CC4 sustain mask 0x40, CC5 modulation 0x00, CC7 reverb 0x28, CC8 chorus 0x40,
CC9 variation 0x40, CC10 key-shift 0x80/mask 0xFF, CC11 part-mode 0x02.

**The main CPU has no window on IC303 at all.** The census script scans every `.s` file in
`v7/`, `v9/` and `v10/`: **0 bus accesses** to `0x100000`/`0x100002`; the 17 textual
occurrences are all immediate operands (`cp xiz, 0x100000` — the 1 MB DRAM top bound) or
comments. `0x110000` in the main CPU is `FDC_MAP__BASE_ADDR`
(`v7/maincpu/fdc_constants.s:16`), an unrelated device.

Everything below is therefore **sub-CPU** code.

---

## 1. The hardware interface

IC303 (TC183C230002) presents two windows to the sub-CPU, multiplexed by **P6.7 (SFR 0x18
bit 7) driving A23**:

| sub-CPU address | write | read |
|---|---|---|
| `0x100000` | register **ADDRESS latch** | status: the 16-bit **active-voice bitmap** for bank `0..3`, or, at latch `0x180+ch`, that channel's envelope level |
| `0x100002` | register **DATA** | never read by the firmware |
| `0x110000` | — | keybed event DATA |
| `0x110002` | — | keybed STATUS (bit 0 = ready) |

MAME already maps exactly this (`kn5000.cpp: subcpu_mem`, `0x100000`/`0x100002`).

★ **One port is missing from the driver map: `0x100004`.** The sub-CPU BOOT ROM's
`AUDIO_HW_WRITE_READ` (0xFF8C75) writes the latch and then reads a status word from
`0x100004`; `HARDWARE_CALIBRATION_SEQUENCE` (0xFF8C80) polls it up to 1000 times and treats
**0** as "chip alive". The v1.42 payload never uses it. Not currently modelled.

### Access pattern — a fixed 8-instruction idiom

```asm
    res 7,(0x18)              ; P6.7 low  -> A23 low -> select the register window
    ld   wa, iz               ; the voice number, 0..0x3F
    add  wa, 0x840            ; + the register BANK  (register 0x21 << 6)
    ld   (0x100000), wa       ; ADDRESS latch
    nop                       ; one settling nop between latch and data
    set 7,(0x18)
    ld   wa, (xwa + 26)       ; the datum (here: staging block +0x1A)
    ld   (0x100002), wa       ; DATA
    jr   <next instruction>   ; + 3 nops -- the mandatory settling gap after the data write
    nop / nop / nop
```

The `jr` to the next instruction plus three `nop`s appears after **every single** TG write in
the firmware. It is timing, not filler. Interrupts stay enabled through the whole sequence and
no lock is taken, so the shared address latch is in principle racy — that is the structure of
the code; whether the race is reachable was not established.

### Address-latch encoding

```
    latch = (register << 6) | channel        channel = 0..0x3F
```

Registers `0x00..0x07`, `0x10..0x19` and `0x20..0x29` are **per-voice** — the low 6 bits are
the voice number. Registers `0x08`, `0x30` and `0x38` are **global** — the firmware writes
latch values `0x0200..0x0205`, `0x0C00..0x0C05` and `0x0E00`, i.e. the low bits are a
sub-index, not a channel.

---

## 2. Register map, from the firmware's own writes

`ToneGen_WriteVoiceParams` (0x02D101, 794 bytes, 23 writes) bursts one voice's whole image
from a 68-byte staging block. Combining that with every other writer gives the map below.
"shadow+N" is the byte offset into the staging block; for the voice-engine paths the block is
at sub-CPU **0x0451CC**, so `shadow+0x02` = `0x0451CE`, and so on.

| reg | latch | shadow | what the firmware puts there | where the value comes from |
|---|---|---|---|---|
| 0x00 | `0x000+ch` | +0x00 | **CONTROL / gate.** Literals `0x8100` (note-on gate), `0x7E00` (FREE a voice); otherwise the *hand-off* word with bit 15 set (bit 15 clear = update without re-gate) | `Voice_Build_GateCommand` (0x025589) from the live slot record +0x2D. Low byte = output level (`0xFF` full … `0x00` silent). Measured values over 1705 demo note-ons: only `F0FF`, `F000`, `F1D7`, `F187` |
| 0x01 | `0x040+ch` | +0x02 | **recording selector**, `(class << 12) | entry` | copied verbatim from a zone record — the tone database (§4) |
| 0x02 | `0x080+ch` | +0x04 | output level + a 3-bit descriptor field. **Bit 15 is a LOAD STROBE**: the burst sets it (write #2) and clears it again (write #23) | UI volume / CC7 / CC11 via the part parameter chain |
| 0x03 | `0x0C0+ch` | +0x06 | coarse level + expression | ditto |
| 0x04 | `0x100+ch` | +0x08 | TVF cutoff | patch parameters |
| 0x05 | `0x140+ch` | +0x0A | TVF depth / bias | patch parameters |
| 0x06 | `0x180+ch` | +0x0C | **pan**, `0x0040` = centre | UI pan / CC4; also written alone by `ToneGen_WriteExprReg` |
| 0x07 | `0x1C0+ch` | +0x38 | extended parameter | `EGEnv_Compute_B` |
| 0x08 | `0x0200..0x0205` | global +0x00..+0x0A | 6 global config words | ROM block at sub-CPU `0x00F8BB` (§3) |
| 0x10 | `0x400+ch` | +0x0E | **absolute log pitch**, 0x100 units per semitone | `Pitch_Emit_Reg400` (0x023A4A) — see §5 |
| 0x11 | `0x440+ch` | +0x10 | — | staging |
| 0x12 | `0x480+ch` | +0x12 | — | staging |
| 0x13 | `0x4C0+ch` | +0x14 | oscillator config + slot | staging |
| 0x14 | `0x500+ch` | +0x16 | detune / bend pair | staging |
| 0x15 | `0x540+ch` | +0x3A | extended parameter; `0x8100` = mute | `ToneGen_WriteExtParams_15` family |
| 0x16 | `0x580+ch` | +0x3C/+0x3E | extended parameter; `0x8100` = mute | `ToneGen_WriteExtParams_56` family |
| 0x17 | `0x5C0+ch` | +0x3E | extended parameter | `ToneGen_WriteExtParams_56b` |
| 0x18 | `0x600+ch` | +0x40/+0x42 | extended parameter | `ToneGen_WriteExtParam_600` |
| 0x19 | `0x640+ch` | +0x42 | extended parameter | `ToneGen_WriteExtParams_56b_ClearPath` |
| 0x20 | `0x800+ch` | +0x18 | **amplitude envelope segment 0**, `(target << 8) | rate` | `Voice_Calc_LevelPair_EGA` |
| 0x21 | `0x840+ch` | +0x1A | amplitude envelope segment 1 | ditto |
| 0x22 | `0x880+ch` | +0x1C | amplitude envelope segment 2 | ditto |
| 0x23 | `0x8C0+ch` | +0x1E | amplitude envelope segment 3 | ditto |
| 0x24 | `0x900+ch` | +0x20 | envelope 2, segment 0 | `Voice_Calc_LevelPair_EGA2` |
| 0x25 | `0x940+ch` | +0x22 | envelope 2, segment 1 | ditto |
| 0x26 | `0x980+ch` | +0x24 | envelope 2, segment 2 | ditto |
| 0x27 | `0x9C0+ch` | +0x26 | envelope 3, segment 0 | `Voice_Calc_LevelPair_EGA3` |
| 0x28 | `0xA00+ch` | +0x28 | envelope 3, segment 1 | ditto |
| 0x29 | `0xA40+ch` | +0x2A | envelope 3, segment 2 | ditto |
| 0x30 | `0x0C00..0x0C05` | global +0x0C..+0x16 | 6 global config words | ROM block at `0x00F8BB` |
| 0x38 | `0x0E00` | global +0x18 | 1 global config word | ROM block at `0x00F8BB` |

Refresh rates matter for a model. Counting write **sites** in the ROM image
(`tg_rom_opcode_scan.py`): regs `0x23`, `0x26`, `0x29` have exactly **one** writer each
(`ToneGen_WriteVoiceParams`) — whatever the note-on burst leaves there is what the chip keeps
for the whole note. Regs `0x20` (24 sites) and `0x21` (29 sites) are rewritten constantly:
expression ramps, portamento, note-off, velocity updates and the sustain-pedal retrigger all
poke them, usually with the literals `0xFF00`/`0xFF80` (mute) and `0xA200`/`0xA280` (damp).

**Reads.** Exactly **one** read of the register window exists in the entire payload:
`ToneGen_Read_Register` (0x021023, verified at ROM offset 0x01212B by the opcode scan).
Latch `0..3` returns a 16-bit active-voice bitmap (consumed by `Voice_Manager_PollBank`, which
frees a slot on a 1→0 edge); latch `0x180+ch` returns that channel's envelope level. No read
anywhere returns a wave-ROM byte.

---

## 3. Bulk uploads — what actually exists

**Everything in this section is established from the ROM.**

| routine | source | size | destination |
|---|---|---|---|
| `ToneGen_WriteGlobalConfig` (0x02D7C7), called once from `DSP_Config_Init` | `ToneGen_GlobalConfig_Defaults`, sub-CPU ROM **0x00F8BB**, `0x1A` bytes | **26 bytes** | 13 global registers (`0x0200-0x0205`, `0x0C00-0x0C05`, `0x0E00`) |
| `DSP_Config_Init` (0x02DFA8) → `ToneGen_Config_Init` (0x02DFCF), 64 iterations | `ToneGen_VoiceParamShadow_Defaults`, ROM **0x00F8D5**, `0x22` words, `ldirw`'d to DRAM `0x2AA4` | **68 bytes** | for each of the 64 voices: mute, the 22-register burst, the control word, mute again, `reg 0x03 <- 0`, `reg 0x00 <- 0x7E00` (FREE), then the three `WriteExtParams` |
| `ToneGen_SetupPolyVoice` (0x0355AD) / `ToneGen_SetupPercussionVoice` (0x035656), per note-on for the auxiliary 8-voice pool | `ToneGen_Voice_Param_Template`, ROM **0x012115**, `0x22` words, `ldirw`'d to DRAM `0x3B1C` | **68 bytes** | patched (pitch, volume, routing, level) then bursted through `ToneGen_WriteVoiceParams` + `ToneGen_WriteSingleReg` |
| `HARDWARE_PARAM_BLOCK_WRITE` (**0xFF8D0A**), sub-CPU **boot mask ROM** (IC30) | `ToneGen_ProbeVoice_ParamBlock`, boot ROM **0xFF824C**, `0x22` words | **68 bytes** | 23 writes in the *identical order* to `ToneGen_WriteVoiceParams`, to one voice, as the power-on TG liveness probe — before the payload exists |

Byte values, for reference:

```
ToneGen_GlobalConfig_Defaults  (0x00F8BB, 13 u16)
  0060 0993 0001 0004 0004 000C 0000 0000 0000 0000 0020 0001 0000
  (bit 3 of word 0 is forced from bit 3 of the global word 0x041343 before sending)

ToneGen_VoiceParamShadow_Defaults (0x00F8D5, 34 u16)
  1200 0002 8000 0000 257C 7F7C 0040 0000 0000 0000 0000 0000 FF80 FF00 FF00 0000
  0000 0000 0000 0000 0000 0000 A080 FF00 0000 0000 0000 0000 0000 0000 0000 0000
  0000 0000

ToneGen_Voice_Param_Template      (0x012115, 34 u16)
  F000 0000 8000 0000 017C 7F7C 0040 0080 0000 0000 0000 0000 7FA0 7FFF 7FFF 0000
  ...
```

**That is the complete list.** No routine anywhere reads a table larger than 68 bytes into TG
registers. The census is exhaustive by construction: `tg_rom_opcode_scan.py` finds every
address-latch/data-port pair in the ROM image (176 of them), including the stretches the
disassembly still carries as `.byte`, and `tg_register_census.py` attributes 137 of them to
named routines in the sources.

---

## 4. Where the big tables go instead — and why the driver reads `table_data`

The firmware *does* have a large table: a **320 KB tone database**. It never reaches IC303.

`SubCPU_Send_Payload` (`v7/maincpu/kn5000_v7_program.s:313`) ships it over the E1 inter-CPU
latch protocol at boot:

```
    main bus 0x830000 + 0x10000*k   ->   sub-CPU 0x050000 + 0x10000*k,   k = 0..4
```

and `DSP_System_Init` (sub-CPU 0x034C45) then installs

```
    (0x045310) ToneDB_RelBase = 0x00050000
    (0x045314) ToneDB_RootPtr = 0x00050000
```

So the structure MAME's `build_pitch_constants()` calls `ROOT` at `table_data` offset
`0x30000` **is** the sub-CPU's `ToneDB_RootPtr`. `tonedb_root_check.py` verifies this against
the real dumps: every pointer field in the root (`+0x04 … +0xB0`) is an offset **inside** the
0x50000-byte block that was transferred, and

```
    n_sets = (min(Root+0x24, Root+0x28, Root+0x2C) - Root+0x30) / u16(Root+0xEC)
           = (0x2959D - 0x27914) / 15 = 487
```

— the 487 multisample SET descriptors the driver logs. Verdict printed by the script:
*the driver's ROOT is the sub-CPU's ToneDB root.*

The firmware's own use of that root, for comparison (`VoiceTablePtr_*`, 0x0341xx):

```
    family 0x00/0xC0 : index table Root+0x24 (or +0x9C when 0x041343 bit 2), SETs Root+0x30, stride Root+0xEC
    family 0x80      : index table Root+0x28 (or +0xA0),                      SETs Root+0x34, stride Root+0xEC
    family 0x40      : index table Root+0x2C (or +0xA4),                      SETs Root+0x38, stride Root+0xF2
    idx  = u16[ RelBase + IndexTable + ((partNibble << 7) | toneNumber) * 2 ]
    desc = RelBase + SETs + stride * idx
```

and then `WaveSel_StageB_Build_Reg040` (0x023849) turns a descriptor plus the current pitch
into one zone record:

```
    table1 = RelBase + u32(desc+0x01)
    table2 = RelBase + u32(desc+0x05)
    zone   = u8[ RelBase + u32(table1) + ((pitch & 0x7F00) >> 8) ]     ; WaveSel_KeyTable_Lookup
    rec    = table2 + STRIDE * u8(table1 + 4 + zone)
    (0x0451CE) = u16(rec + 0)          -> TG register 0x040+ch, the selector
    (0x293E)   = u16(rec + 0x0D|0x0A|0x04|0)   -> the zone TRIM, folded into the pitch
```

`STRIDE` is one of **six** formats chosen by descriptor bits 5, 6, 7: `0x0F`, `0x0C`, `0x0D`,
`0x0A`, `0x06` and `0x04`. The driver's `build_pitch_constants()` models exactly two of them
(`BIT(flags,7) ? 6 : 4`) and takes the trim from `rec+4`, which is the stride-6
(`WaveSel_Emit_ZoneRecord_S6`) case. **The other four zone-record formats are not modelled.**

**So: the database is consumed to compute 22 words per voice, and those 22 words are what the
chip is told.** Nothing else crosses to IC303. This is the same "the firmware publishes it"
pattern recorded for the KN7000 and the KN6000 in `kn7000_mame/notes/AUTONOMOUS-STATUS.md`
("BLOCKER 2 … dissolved, not reversed").

---

## 5. Pitch: what IS and what is NOT in the register traffic

`Pitch_Emit_Reg400` (0x023A4A) produces the word for register `0x10` (`0x400+ch`):

```
    record+0x06  = fold_into_key_range( desc[+0x0C]                       ; SET base pitch
                                      + s8(patch[+0x03]) << 8            ; coarse, semitones
                                      + s8(patch[+0x04]) * 2 )           ; fine
    record+0x0A  = record+0x06 + (0x293E)                                ; the zone TRIM
                              + partial detunes                          ; Pitch_Apply_Partial_Detune
    reg 0x400    = saturate15( record+0x0A + (0x041347)                  ; global fine tune
                              +/- patch detune + optional (0x04135A) )
```

Which is, as the disassembly's own header states,

```
    reg 0x400 = (note << 8) + 0x80 + C(recording) + 2*fine + detune
```

with `C` the constant belonging to the selected multisample.

**In the register traffic:** the *sum*. That is everything IC303 needs, because IC303 resolves
the recording's own tuning against the wave ROM directory it alone can read.

**Not in the register traffic:** the *split* between "which MIDI note" and "which recording's
tuning origin". `build_pitch_constants()` recovers `C` statically from the tone database so it
can invert the sum and get an absolute note for voices with no correlated input event.

Two facts bear on doing that without the ROM:

1. **The auxiliary 8-voice pool publishes a C = 0 pitch.** `ToneGen_SetupPolyVoice` writes
   staging `0x3B2A` (= block +0x0E = register `0x400`) as literally `(note << 8) | 0x80`, with
   the *selector* (`0x3B1E`, block +0x02) chosen per octave from the table at ROM `0x01217D`.
   On that path the register alone gives the absolute MIDI note exactly. It is a usable
   calibration/again-check point that needs no ROM at all.
2. **`C` is a property of the recording, not of the firmware.** The proper owner of a
   recording's tuning origin is IC304-IC307, which *is* IC303's own bus. Whether the wave
   ROM's per-entry parameter records carry it is currently **[OPEN]** — the existing analysis
   (`v142/subcpu/kn5000_subprogram_v142.s`, the "WHAT +0x040 SELECTS" header) records
   *"NO ROOT NOTE AND NO LOOP POINTS ARE STORED HERE [INFERENCE]"*, while noting that some of
   the `flag != 0x00` bytes may be IC303's own per-wave tune parameters.

---

## 6. Evidence grade

### Established from the ROM (byte- or instruction-level)

* The two-port interface, the P6.7/A23 multiplex, the latch encoding `(reg << 6) | ch`, and
  the mandatory nop gap. Idiom present at all 176 paired write sites in the ROM image.
* The register table of §2, register by register, including which shadow word feeds each.
* Exactly one read of the register window, at sub-CPU `0x02102B`.
* The main CPU never accesses `0x100000`/`0x100002` — 0 hits over all of v7, v9 and v10.
* The complete list of bulk uploads in §3, with source addresses, sizes and byte values.
* An independent cross-confirmation of the burst: the sub-CPU BOOT MASK ROM's
  `HARDWARE_PARAM_BLOCK_WRITE` (0xFF8D0A) emits the same 23 writes in the same order
  from the same 68-word record shape as `ToneGen_WriteVoiceParams` in the payload. Two
  independently written pieces of firmware agree on the register set and its order.
* `SubCPU_Send_Payload`'s five 64 KB transfers `0x830000..0x87FFFF -> 0x050000..0x09FFFF`,
  and `DSP_System_Init` installing `ToneDB_RelBase = ToneDB_RootPtr = 0x050000`. Hence the
  driver's `ROOT` and the firmware's `ToneDB` are the same bytes — verified numerically
  (487 SET descriptors, all root pointers inside the transferred block).
* The pitch chain of §5, instruction by instruction, and the `C = 0` aux-pool path.
* The register-0x00 command set (`0x8100` gate, `0x7E00` free, hand-off word with bit 15).

### Inference, clearly marked as such in the sources

* That IC303 walks the wave ROM directory itself. It is a conclusion by elimination — no CPU
  on the board has the wave ROMs in its address space — not an observation of the chip.
* The meaning of registers `0x11`, `0x12`, `0x15`-`0x19` beyond "the firmware writes staging
  word N here". No semantic has been pinned.
* `rate = 0` meaning "go to target now" on the envelope registers. Firmware-side argument
  only; no rate-to-time law for IC303 has ever been captured.
* Which physical socket is wave bank 0.

### Open / unresolved

* Four of the six zone-record stride formats are not modelled by
  `build_pitch_constants()`, and the "SET family 0x40 / 0x80" descriptor arrays
  (`Root+0x34`, `Root+0x38`) are not walked at all.
* `WaveSel_StageB_Store_Reg040` doubles the selector's top nibble when `0x041343` bit 2 is
  set; `Voice_Init_Type1` adds `(tick & 7)` to the whole selector word. Under a plain
  `entry = word & 0x0FFF` reading the second one picks a different directory entry on every
  note. Unresolved — see the "WHAT +0x040 SELECTS" header.
* Whether a recording's tuning origin is recoverable from the wave ROM parameter records.
