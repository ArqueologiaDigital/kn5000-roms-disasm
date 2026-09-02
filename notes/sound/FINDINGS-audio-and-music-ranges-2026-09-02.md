# Which data ranges are PCM audio, and which are music?

**Date:** 2026-09-02 · **Lane:** AUDIO, worktree `census-audio`, branch `w13/census-audio`
**Question:** across the 13 gated images, which byte ranges are PCM audio, which are
music/sequence data, and what is everything else? Then represent them so a human can
play them.

## The answer, first

* **PCM audio: NONE. Not one byte, in any of the 13 images.** Established by a
  three-lane discriminator with a hardware-rooted positive control and six nulls, run
  over every window of every image and over the decompressed contents of the
  containers inside them. Not one window of 16-bit, 8-bit or IMA-ADPCM audio survives
  adjudication. **No WAV file is written, because there is nothing to write.**
* **Music: 259 pieces, all of it EVENT DATA, and all of it now playable.**
  * 19 demo songs in `kn5000_table_data.rom` — already MIDI before this lane, and
    already the ROM's build source (`table_data/includes/demo_presets/`).
  * 240 factory accompaniment styles in `kn5000_custom_data.ic19` and the Composer
    factory image — **new here**: `custom_data/styles/midi/`, one Standard MIDI File
    per style directory record, 41,537 of 41,537 events round-tripped.
* **Everything else that scores audio-like is a TABLE**, and §4 says which table.

This is the expected result and it was worth measuring rather than asserting. These are
CPU program and data ROMs. The KN5000's sampled waveforms live on mask ROMs IC304-307
that are in **no CPU's address space** — the sub-CPU's exhaustive window enumeration
finds three memory-mapped devices and no fourth (`FINDINGS-kn5000-sound-coverage-2026-09-01.md`
§4) — and the SX-WSA1R's six 16 Mbit wave mask ROMs are undumped. There was never a
route by which sample data could be in these files.

---

## 1. The instrument, and why it is a measurement

`notes/sound/pcm_discriminator.py`. Three lanes, each with its own calibration.

**The positive control is hardware-rooted and is not one of the 13 images.** It is the
KN5000's IC307 waveform mask ROM (4,194,304 B, `kn5000_waveform_rom.ic307`), established
as signed 16-bit LE PCM by an independent pass
(`kn7000_mame/notes/kn5000-ic307-content-map.md`). It carries its **own negative control
in the same chip**: its first 0x1A30 bytes are an index table plus 198 parameter records,
exactly the kind of structured byte-valued table these program ROMs are full of.

### Lane 1 — 16-bit
Per 4,096-byte window, read as s16le:

| feature | what it captures |
|---|---|
| `r1` | lag-1 autocorrelation. PCM is SMOOTH: it is bandlimited well below the sample rate. |
| `lo_ent` | entropy of each sample's LOW byte. PCM fills it with ~uniform noise (~7.9/8 bits). |
| `diff_ent` | entropy of the low byte of the first difference. |

`VERDICT = r1 >= 0.60 AND lo_ent >= 7.00 AND diff_ent >= 7.00`

**`diff_ent` exists because of a null that the first two features failed.** An
**ascending u16 table** is perfectly smooth (`r1 = 0.999`) and has a perfectly uniform
low byte (`lo_ent = 8.00`), so `r1` + `lo_ent` alone call it audio **100% of the time**.
Its first difference is the constant 1, so `diff_ent = 0`. Without the third feature this
lane would have reported audio in half the tables in the tree.

```
POSITIVE  IC307 page-0 indexed PCM (1,037,616 B)        168/253   66.4%
POSITIVE  IC307 pages 1-3 un-indexed PCM (3,149,920 B)  564/769   73.3%
NEGATIVE  IC307 index table + 198 parameter records       0/1       0.0%
NULL      uniform random bytes                            0/256     0.0%
NULL      pure sine table (smooth, residual not broadband) 0/256    0.0%
NULL      ascending u16 table (THE TRAP)                  0/256     0.0%
NULL      LZSS-compressed demo presets (real, in-ROM)     0/60      0.0%
NULL      SLIDE8K-compressed help databases (real, in-ROM) 0/21     0.0%
```

### Lane 2 — 8-bit
A 16-bit rule is blind to 8-bit sample data, so there is a second lane: 1,024-byte
windows read as 8-bit samples in **both signings**, `r1 >= 0.60 AND byte_ent >= 6.50 AND
diff_ent >= 4.50`. Its positive control is derived from the same dump — the **high bytes**
of IC307's s16 PCM are genuine 8-bit PCM of the same recordings.

```
POSITIVE  IC307 page-0 PCM as 8-bit    264/506   52.2%
POSITIVE  IC307 tail PCM as 8-bit      631/1538  41.0%
NEGATIVE  IC307 index + parameter records 0/6     0.0%
NULL      random / ascending u8 ramp / sine table u8   0 / 0 / 0
```

It is a blunter instrument and it is treated as a **screen, not a verdict**: every window
it flags is looked at (§4).

### Lane 3 — IMA ADPCM
Lanes 1 and 2 are blind to compressed audio **by construction**, which is precisely the
shape of blind spot that turns "we found no audio" into "our instrument cannot see audio".
Lane 3 decodes each window as 4-bit IMA ADPCM (both nibble orders, predictor from zero)
and scores the **decoded** signal with `r1 >= 0.40, lo_ent >= 7.00, diff_ent >= 6.00`.
Relaxed because ADPCM quantisation noise costs the reconstruction about 0.35 of its `r1`.

```
POSITIVE  IC307's own PCM run through an IMA encoder     16/16   100.0%
NULL      uniform random bytes                            0/128    0.0%
NULL      IC307 index + parameter records                 0/1      0.0%
```

⚠ Its false-positive mode is **the ramp again, one level down**: a slowly-rising
staircase table (`00 00 00 01 01 01 01 02 02 ...`) hands the IMA predictor near-constant
nibbles, which it integrates into a smooth ramp.

⚠ **What lane 3 does NOT cover.** It tests IMA/DVI specifically. A different ADPCM
variant with different step tables, or a proprietary codec, would decode to noise under
it and be missed. What it rules out is the most common 1990s ROM sample codec, not every
conceivable one.

---

## 2. The census

```
python3 notes/sound/pcm_discriminator.py --census
```

| image | bytes | 16-bit | 8-bit | ADPCM |
|---|---:|---:|---:|---:|
| KN5000 v10 program | 2,097,152 | 0 | 0 | 0 |
| KN5000 v9 program | 2,097,152 | 0 | 0 | 0 |
| KN5000 v7 program | 2,097,152 | 0 | 0 | 0 |
| KN5000 subprogram v1.42 | 196,608 | 0 | 0 | 0 |
| KN5000 subprogram v1.42 compressed | 93,203 | 0 | 0 | 0 |
| KN5000 sub-CPU boot IC30 | 131,072 | 0 | 0 | 0 |
| KN5000 table data | 2,097,152 | 0 | 0 | **7** |
| KN5000 custom data IC19 | 1,048,576 | 0 | 0 | 0 |
| HD-AE5000 v2.06i IC4 | 524,288 | 0 | **11** | **1** |
| SX-WSA1R prom_a IC12 | 524,288 | 0 | 0 | 0 |
| SX-WSA1R prom_b IC13 | 524,288 | 0 | 0 | 0 |
| SX-WSA1R prom_c IC28 | 524,288 | 0 | **2** | 0 |
| SX-WSA1R prom_d | 524,288 | 0 | 0 | **3** |
| **total** | **10,904,555** | **0** | **13** | **11** |

**And inside the containers**, because a census of the raw image cannot see through an
LZSS stream (`--containers`): all 19 decompressed demo songs and all 6 decompressed help
databases, **0 windows in every lane**.

---

## 3. Sensitivity — could the instrument have seen it?

Yes, on all three lanes, against known audio: 66-73% (16-bit), 41-52% (8-bit), 100%
(ADPCM). And `--selftest` asserts every one of those numbers plus every null, so a
future change that quietly breaks the discriminator turns the test red rather than
turning the census green.

The residual limits, stated rather than glossed:

* A PCM region **shorter than one window** (4 KB / 1 KB) can hide. The smallest thing
  the 16-bit lane can resolve is ~2,048 samples, about 46 ms at 44.1 kHz.
* A codec other than raw PCM or IMA ADPCM is not tested.
* Speech ROM formats built on LPC or a delta modulator would not present as smooth
  bytes and are not tested. **However**: the sub-CPU window enumeration finds no device
  that could play one, and no firmware path reads sample data (five reads in the whole
  payload — the active-voice bitmap, one keybed event, one voice on/off bit).

---

## 4. Every flagged window, adjudicated

None survives. All 24 are numeric tables whose purpose the tree already documents.

### 8-bit lane — 13 windows

| where | what it actually is |
|---|---|
| HD-AE5000 IC4 `0x06CC00`, `0x06DC00`, `0x06E000`, `0x06E400`, `0x06E800`, `0x071800`, `0x071C00`, `0x072000`, `0x072400`, `0x073800`, `0x075C00` (11) | inside `HDAE5000_SplashScreen.bin`, file `0x0661CE-0x078DCE` — a **320x240 8bpp indexed photograph** (the "HD-AE5000" wordmark over an open disk platter). Built from `hdae5000/images/HDAE5000_SplashScreen.png`. An 8bpp photo is smooth and entropic for exactly the reasons 8-bit PCM is; this is the classic confusion and it is the whole of this lane's yield on IC4. |
| SX-WSA1R prom_c `0x05DC00` = ROM `0xFDDC00` | a monotone byte curve `5c 5d 5e 5f 60 62 63 ...` — a **non-linear lookup curve**, inside the voice / DSP data-table zone `0xFDD2AB-0xFDF7DF` (43 tables, 9,525 B) named in `prom_c/wsa1_prom_c.s`. |
| SX-WSA1R prom_c `0x05E400` = ROM `0xFDE400` | a **u16 table ascending by 0x40**, followed at `0xFDE42B` by an S-curve LUT `04 09 0e 14 1a 1f 26 ...`. Both bases are taken by `lda XBC,0xfde42b` / `lda XBC,0xfde47b` in the same file. Same zone. |

### ADPCM lane — 11 windows

| where | what it actually is |
|---|---|
| KN5000 table data `0x05B000`-`0x061FFF` (7) = ROM `0x85B000`-`0x861FFF` | inside `table_data/tone_database_aux.s`, the `ToneEnv_*` data chunks at `0x85B09D-0x863078` (974 blobs, 32,732 B) — **tone ENVELOPE data**. Its staircase ramps are what the IMA predictor integrates. |
| SX-WSA1R prom_d `0x025000`, `0x026000`, `0x028000` (3) | inside `wsa1/prom_d/tone_database_aux.s` (file `0x1C58A-0x7FFFF`) — the SX-WSA1R **tone database's auxiliary tables**, the mirror of the KN5000 file above. Same shape, same cause. |
| HD-AE5000 IC4 `0x026000` = ROM `0x2A6000` | an **ascending 32-bit pointer table** (`0x0029FA88, 0x0029FADA, 0x0029FB2C, ...`), between `HDAE5000_UiObject_PtrTable` (`0x2A5D2C`) and `HDAE5000_UiObjectName_PtrTable` (`0x2A6984`). |

★ It is worth noting **where** the ADPCM hits land: both products' hits are in the *same
object* — the tone database's auxiliary/envelope tables. That is the most audio-adjacent
data in either ROM, and it is still not audio: it is the envelope shapes applied to
samples that live elsewhere.

---

## 5. The blocks the brief singled out: `audio/sound_data_*`

```
python3 notes/sound/pcm_discriminator.py --sounddata
```

All 15 blocks, 0 windows called PCM in either lane. The **positive** identification, which
matters more than the negative: they are 4-byte-record grids of
`{sub_bank: u16, patch_ref: u16}` — **patch reference tables**. 50-90% of their bytes are
zero and their low-byte entropy is 2.0-4.6 bits against PCM's 7.9. The tree already says
so: they are compiled from typed C structs (`v10/maincpu/audio/sound_data_*.c`) that build
byte-exact, and `sound_data_piano.c` declares the record type with a `_Static_assert`.

This also corroborates the earlier lane's measurement that only 10 of v10's 3,395
"suspicious" byte runs fall in them.

---

## 6. The music, and how it is now represented

### 6.1 The 19 demo songs — already solved, verified here

`table_data/includes/demo_presets/`. Nineteen SLIDE4K-compressed songs in
`kn5000_table_data.rom` (entries 0-17 at `0x9C4050-0x9F94CB`, entry 18 — the Feature
Presentation — at `0x8E0000`). Standard MIDI Files **are the build source**:
`.mid + .yaml sidecar -> .bin -> LZSS -> ROM`, with `compress_lzss.py --strict` making a
divergence from the factory stream a hard build failure. Nothing to add; `make gate-all`
re-certifies it.

### 6.2 The 240 accompaniment styles — NEW

`kn5000_custom_data.ic19` (7 style banks) plus `Composer_FactoryMemoryImage` inside
`kn5000_table_data.rom` (1 bank). The event grammar and the cell container were already
established (`docs/accompaniment-style-format.md`) and `scripts/build/style_events.py`
already round-trips them as `.styles` listings. What was missing was **playability** and
**identity**: a chain had no name, only a block number.

**`scripts/analysis/style_directory_chains.py` supplies the identity.** The 96-byte
directory record's fields at `+0x00/+0x04/+0x06/+0x08/+0x0A` are five consecutive cell
pointers. Across all 240 records they name **all 1,200 linked chains and none of the 818
unlinked template blocks — a bijection, no duplicate and no gap.**

⚠ **The obvious test for this was worthless and the null said so.** "The value resolves
to a chain head" passes 1,200/1,200 — and so does a uniformly random value drawn from the
same block range, also 1,200/1,200, because chain heads are dense in the cell region. The
script keeps that dead test and its null on screen, because the two real tests
(consecutiveness; selectivity between the two chain-head shapes) only mean something next
to it.

⚠ **A zero is a valid pointer here.** `block = (v & 0x0FFF) + base`, and the Composer
bank's section nibble is 0 rather than section+1, so its first pointer is literally
`0x0000`. Filtering zeros as "absent" discarded one real pointer and manufactured one
phantom unnamed chain.

**`scripts/build/style_to_midi.py` supplies the playability.** `make style-midi` writes
240 Standard MIDI Files to `custom_data/styles/midi/`, one per directory record, carrying
the style's own 16-character name. Format 1, **96 ticks per quarter note** — the format's
own resolution from the firmware's timing routine, not a choice.

The controller mapping is read from the firmware, not guessed:
`SeqPerformance_EventDispatch` (ROM `0xFE89A8`) holds the selector bodies in order, each
ending in `SndPart_SetParam` with a parameter id.

| stream | MIDI | authority |
|---|---|---|
| `0x90 NOTE` / `0x91 NOTE2` | note on/off, tick = beat*96 + pos, dur = dur_beats*96 + dur_ticks | `docs/accompaniment-style-format.md` |
| `0xD1 CTL1` | control change 1 (modulation) | selector body -> parameter 1 |
| `0xD2 CTL2` | **pitch bend**, `(v << 7) \| (2v - 128 if v >= 64 else 0)` | the expansion at ROM `0xFE89C4` |
| `0xD3 CTL3` | control change 64 (damper pedal) | a literal `0xB0` with controller `0x40` |

**Nothing is discarded for not being understood.** Every non-`BEAT` event is *also*
written verbatim as `FF 7F <len> <status> <args>` at its tick. `make verify-style-midi`:
**41,537 of 41,537 events recovered, 0 files mismatched.**

Not decoded, therefore not invented: **tempo** (a style has none — the player supplies it;
the files carry a nominal 120 BPM), the **instrument/channel** (the part comes from RAM
`0x7E52` at runtime — the five channels exist only so the parts are separable by ear, and
no program change is emitted), **`NOTE2`'s two extra bytes** (the KN5000's emitter can
produce three distinct pairs and this corpus has 57, so the styles were authored on
equipment whose table is not in these ROMs), and the **five slots' musical roles**.

⚠ **The MIDI is a VIEW, not the build source.** `custom_data/styles/*.styles` still builds
the ROM and holds what MIDI cannot: cell allocation and link topology, the PAD bytes after
`0x83`, and which statuses were explicit rather than running. No ROM target depends on the
`.mid` files; deleting them cannot move a ROM byte. Presenting the MIDI as the data would
lose those bytes, which is the failure mode the brief warns about.

**Two silent bugs the event census caught**, both worth recording because neither raised
an error:

1. Keying the cell set by BANK NAME gave `section_1_2`'s first directory the second's
   cells — the blobs each hold **two** 30-record directories. 140 of the 1,050 IC19 chains
   then walked short and **5,391 events vanished**.
2. Naming files by bank+record collided across those two directories: **227 files written
   for 240 records**, 13 silently overwritten.

Both were found by comparing the per-status census against the independently published one
rather than by anything failing. With them fixed the counts agree **exactly**, IC19 and the
Composer bank separately:

```
IC19            0x81 BEAT 13,965  0x90 NOTE 26,633  0x91 NOTE2 7,538
                0xD1 112  0xD2 1,227  0xD3 770  0x83 END 1,050
Composer image  non-terminator total 7,457
```

which are the figures in `docs/accompaniment-style-format.md` and `style_events.py`, from a
different walk. Two independent routes reaching the same 57,702 events is the check.

A musicality check on the result: the pitch-class histogram over all 39,216 notes is
C 29.1%, G 16.1%, E 14.1%, D 11.9%, every other class below 7% — strongly tonal in C, which
is what accompaniment patterns recorded in a reference key look like. Three files
(`section_5_6_d0_r19/21/23_clear.mid`) carry no notes: empty factory slots, kept so the set
is complete.

---

## 7. Examined and rejected — for the inventory lane to mark PURPOSE KNOWN

| range / object | what it is | not audio because |
|---|---|---|
| all 13 gated images, every window | see §2 | 0 of 6,080 windows in the 16-bit lane, 13 adjudicated of 12,187 in the 8-bit lane |
| `v10/v9/v7 audio/sound_data_*` (15 blocks) | `{sub_bank, patch_ref}` patch reference tables | typed C structs; 50-90% zero, low-byte entropy 2.0-4.6 |
| `table_data/tone_database_aux.s` `ToneEnv_*`, `0x85B09D-0x863078` | 974 tone **envelope** chunks | monotone staircase; ADPCM-lane artefact |
| `wsa1/prom_d/tone_database_aux.s` | SX-WSA1R tone database aux tables | same shape, same cause |
| `HDAE5000_SplashScreen.bin`, IC4 `0x0661CE-0x078DCE` | 320x240 8bpp indexed **photograph** | built byte-exact from a committed PNG |
| `HDAE5000_UiObject*_PtrTable`, ROM `0x2A5D2C` / `0x2A6984` | ascending u32 pointer tables | values are ROM addresses |
| prom_c `0xFDD2AB-0xFDF7DF` | voice / DSP data-table zone, 43 tables | lookup curves; bases taken by `lda` |
| `table_data/style_records.s` `0x951000-0x983B39` | 1000 Music Stylist preset records, 198 B each | ASCII names + parameter blocks |
| `original_ROMs/demo_preset_*_compressed` | SLIDE4K/LZSS-compressed **song event data** | see §6.1 — it is music, not samples |
| `original_ROMs/help_db_*_compressed` | SLIDE8K-compressed **help text** | decompresses to prose |
| `custom_data` sections 0-6 + Composer image | **accompaniment style event streams** | see §6.2 — music, not samples |
| `dsp/` microcode and coefficient uploads | uPD6383GF / MN19413 **programs** | instructions for a DSP, not a signal; deliberately not converted |
| IC307 / IC304-306, IC14 | the actual waveform and rhythm mask ROMs | **not among the 13 images**, and in no CPU's address space |

---

## 8. Reproduce

```
python3 notes/sound/pcm_discriminator.py --calibrate    # the tables in §1
python3 notes/sound/pcm_discriminator.py --census       # §2
python3 notes/sound/pcm_discriminator.py --containers   # §2, inside the LZSS blobs
python3 notes/sound/pcm_discriminator.py --sounddata    # §5
python3 notes/sound/pcm_discriminator.py --selftest     # every number above, asserted

python3 scripts/analysis/style_directory_chains.py            # §6.2 evidence + its null
python3 scripts/analysis/style_directory_chains.py --selftest
make style-midi && make verify-style-midi                     # §6.2 output
make gate-all                                                 # 9 KN5000 + 4 SX-WSA1R
```

`--containers` needs `make decompress-demo-presets` and `make decompress-help-databases`
first; it refuses to conclude anything if they are absent rather than reporting a green
zero over an empty directory.

⚠ The positive control lives **outside this repository**, at
`~/compartilhado/kn7000-emulator/roms/kn5000/kn5000_waveform_rom.ic307`. Without it the
tool exits 2 and reports nothing, rather than running uncalibrated.

## 9. Gate

`make gate-all` green in this worktree: 9 KN5000 images `IDENTICAL`, 4 SX-WSA1R images
`ok`, exit 0. **No KN5000 or SX-WSA1R source file was touched by this lane** — the only
change to a build file is two new `.PHONY` targets in `Makefile` that no ROM target
depends on, so there is no ROM byte this lane could have moved.

---

## 10. A gate defect found on the way, and fixed

**`make gate` was not certifying `custom_data/styles/*.styles` at all.**

Proving the gate can see your change is a standing rule, so this lane changed one NOTE
pitch (105 -> 106) in `custom_data/styles/section_0.styles` — a change that really does
move ROM byte `0x1409`, as `style_events.py verify` said at once — and ran the gate. It
printed `kn5000_custom_data IDENTICAL` and exited 0.

Cause: `rebuilt_ROMs/kn5000_custom_data.llvm.o` named `style-events` as a prerequisite,
and `style-events` was a target with **no output file**. Normally a nonexistent
prerequisite forces a rebuild — but this Makefile declares `.SECONDARY:` with no
prerequisites, which marks *every* target intermediate, and make then decides:

```
Prerequisite 'style-events' of target 'rebuilt_ROMs/kn5000_custom_data.llvm.o' does not exist.
No need to remake target 'rebuilt_ROMs/kn5000_custom_data.llvm.o'.
```

`$(CUSTOMDATA_SRC)` is `$(wildcard custom_data/*.s custom_data/*/*.s)`, so the `.bin`
files the sources `.incbin` were not prerequisites either. On an already-built tree the
edit was invisible; it only went red after `touch custom_data/kn5000_custom_data.s`.

**Fixed** by naming the five generated `.bin` files as real prerequisites through a
grouped target (`&:`, so the script still runs once), with `style-events` kept as a
phony alias. Re-tested with the same perturbation: `kn5000_custom_data 1 BYTES DIFFER`,
`FAIL`, exit 2. Restored: 9 KN5000 `IDENTICAL` + 4 SX-WSA1R `ok`, exit 0.

⚠ **The same shape is still present for three other targets** — `indexed-images`,
`tabledata-images` and `hdae5000-images` are likewise output-less and likewise named as
prerequisites of `kn5000_table_data.llvm.o` and `hd-ae5000_v2_06i.llvm.o`. They own other
lanes' files, so this lane did not touch them. **An edit to a committed PNG, palette or
font source may not go red on an already-built tree.** That is for the integrator or the
owning lane, and it should be tested the same way: perturb one pixel, gate, expect red.

This is the same failure the sound-coverage findings record in their §0 — the gate green
while its inputs were not really being read — reached by a different route.
