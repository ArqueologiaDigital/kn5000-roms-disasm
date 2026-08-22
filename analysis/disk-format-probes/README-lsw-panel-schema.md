# `.LSW` field semantics, from the firmware side

`docs/kn-disk-file-formats.md` solved the `.LSW` **container** (26 blocks of tag/length/value
records) but left two things open: the framing was inferred from data shape only ("no code in the
disassembly has been shown to parse this"), and nothing was known about what the fields **mean**.

These three probes close both gaps by reading the KN5000 firmware instead of the files.

The headline: **the panel work area the `.LSW` writer dumps is itself a TLV stream, and the
firmware carries its schema as a ROM table.** Records are `[u8 tag][u8 payload_len][payload]`,
blocks end with `FF FF`, and the region the writer saves ends exactly at the second block's
terminator.

| script | question it answers |
|---|---|
| `lsw_panel_schema_from_rom.py` | Where does each record live, what is its tag/length, and what fields does it have? |
| `lsw_file_vs_firmware_schema.py` | Is a floppy `.LSW` the same format as the KN5000's own panel area? |
| `lsw_field_evidence.py` | Which routine touches which field, and is `(e=tag, d=offset)` really how the firmware names a field? |

## `lsw_panel_schema_from_rom.py`

```
python3 analysis/disk-format-probes/lsw_panel_schema_from_rom.py          # full record + field dump
python3 analysis/disk-format-probes/lsw_panel_schema_from_rom.py --quiet  # just the assertion
```

Signal read: two ROM tables of 10-byte entries,

    NakaInst_ExtDevice_Screens_0x2814 = 0xED8FE0   46 entries, base 0x00F9A0
    NakaInst_ExtDevice_Screens_0x29E0 = 0xED91AC   30 entries, base 0x00FD60

    entry = { u32 offset_from_base ; u32 ptr_to_field_descriptor_list ; u8 TAG ; u8 PAYLOAD_LEN }

Consumed by `DSPCfg_CopyEntryValues` (writes tag/len into RAM), `DSPCfg_Init_Entry1` (payload
starts at `base+off+2`), `DSPCfg_ResetEntryByTable` / `DSPCfg_InitAllEntries` (46 entries over
0xF9A0) and `DSPCfg_ResetAuxEntries` / `DSPCfg_InitAuxEntries` (30 entries over 0xFD60), all in
`v9/maincpu/audio/tonegen_fileio_handlers.s`.

Field-descriptor grammar (list ends at `0xFF`; type is byte 0):

| type | size | layout |
|---|---|---|
| 0,1,2 | 3 | type, payload offset, bit mask |
| 3,4 | 6 | type, payload offset, bit mask, then 3 bytes read as **min, max, default** *[INFERENCE — the handler's disassembly is still partly `.byte`; the last of the three is definitely the value OR-ed into the masked bits (`ld a,(xbc+5) / or (xde),a`), the first two are the operands of two comparisons]* |
| 5,6 | n+5 | type, offset, mask, count, `count` value bytes |
| 7 | 3 | type, payload offset, default (whole byte) |
| 8 | 2 | type, payload offset (plain byte) |

PASS = both tables tile `0xF9A0..0xFFC0` with no gap or overlap, both `FF FF` terminators land
where the firmware expects, and every descriptor list parses to exactly the span up to the next
list. Exits non-zero otherwise. Current output:

    region 0xF980..0xFFC0 = 0x20 header + 0x620 TLV; schema ends at 0xFFC0
    PASS: both schema tables tile 0xF9A0..0xFFC0 exactly, all descriptor lists parse.

## `lsw_file_vs_firmware_schema.py`

```
python3 analysis/disk-format-probes/lsw_file_vs_firmware_schema.py <file.LSW> [...]
```

Corpus: the seven floppies in `~/compartilhado/KN7000/floppy-archive/*.zip` (unzip first; each
holds one 22,528-byte `.LSW`).

PASS = every one of the file's 26 TLV blocks aligns against a firmware block **in order** — the
file may add or drop tags, but never permutes them. Exits non-zero on a permutation. Result on all
seven disks, identical each time:

* file block 0 and blocks 2..25: 37/37 tags aligned against firmware block 0
  (firmware block 0 additionally has `78 47 43 64 65 66 68 99`)
* file block 1: 29/30 aligned against firmware block 1; the file inserts tag `99` after `98`
  (in the KN5000 tag `99` lives in block 0 instead, and at the file's length, `0x1E`)

Note the block-0 vs slot difference the script surfaces: **block 0's records are wider than the 24
slot blocks'.** Same tag list, two record widths — see the `len fw->file` lines: a part record is
24 bytes in the KN5000, 30 in file block 0, and 22 in file blocks 2..25. So the slots are a
compacted form of the same schema, not a copy of block 0.

## `lsw_field_evidence.py`

```
python3 analysis/disk-format-probes/lsw_field_evidence.py v9               # full map + events
python3 analysis/disk-format-probes/lsw_field_evidence.py v9 --events-only
```

(v9 only — the v7 sources have not converted `SwbtWr_QueuePostEvent`'s call sites yet, so v7
yields zero event sites.)

Signals read: (1) every absolute operand in `0x00F9A0..0x00FFC0` in the disassembly, mapped to
`(tag, payload offset)` with its enclosing routine; (2) every `ldb e,<tag> / ldb d,<offset>` ahead
of `call SwbtWr_QueuePostEvent`, which is how the firmware names a panel field in an event.

PASS = wherever an event site has an in-range absolute access within 12 source lines, the two
agree on `(tag, offset)`. Sites whose neighbourhood is still raw `.byte` are skipped and counted.
One disagreement is recorded by name in `KNOWN_EXCEPTIONS` (see the docstring) so that a *new*
one still fails. Current: 20/21 agree, 1 known exception, 2 skipped.

## What the fields are, so far

Everything below comes out of the three scripts plus the routines they name. Marked
**[INFERENCE]** where the reading is not pinned by a routine name or a MIDI byte.

### Region layout

    0x00F980..0x00F99F   32-byte header, only ever taken as a base address (no field-level access)
    0x00F9A0..0x00FD5F   TLV block 0   45 records + FF FF at 0xFD5E
    0x00FD60..0x00FFBF   TLV block 1   29 records + FF FF at 0xFFBE
    0x00FFC0             end of the saved region

`RESOURCE_INFO_HANDLERS` (`v9/maincpu/kn5000_v9_program.s`) returns this as resource 0:
base `0xF980`, size `(0xFFBE + 2) - 0xF980 = 0x640`. It computes the end **from the block-1
terminator address**, which is the firmware saying outright that the payload is the TLV stream.
Resource 1 is `0x1E7800..0x1E8000` (`0x800`), the other half of the `.LSW` payload.

Three 0x620-byte mirrors of `0xF9A0..0xFFC0` live at `0x03C2C4`, `0x03C8E4` and `0x03CF04`:
`SndParam_SyncDisplayBitmap` copies live→`0x3C8E4` and `ToneGen_DiffScanAndUpdate` diffs against it
to build the tone-generator update list; `ToneGen_FileIO_RestoreFromBackup` copies `0x3CF04`→live.

### The 26 part records

Tags `0x00..0x16` and `0x19` (24 records, block 0) plus `0x17` and `0x18` (block 1) are one family,
`0x18` payload bytes each. `AccompSeq_QueueAllMutes` walks all 26 and posts `e = the tag`.

| payload offset | meaning | evidence |
|---|---|---|
| +0 | **sound / program number** | `AccPlay_CompareAndSendProg` sends it as a MIDI `0xC1` program change; descriptor bytes for tags `0x10..0x12` are `00 A7 15` and for `0x13` `00 A7 28` — read as range 0..167 with default 21 / 40. Cross-check: in the seven floppies, tag `0x13` holds 40, 43, 55 |
| +1 | **bank**, bits 0..3 plus bit 7 as a `+0x10` bank bit | `AccPlay_CompareAndSendProg`: `and e,0xf` / `bit 7,w -> or e,0x10`; descriptor `min 0 max 7 default 0` |
| +4 bit 6 | **reverb on/off** | `AccPlay_UpdateBankParams`: `bit 6 -> (xiy+13)`; event `(e=0x17,d=4,mask=0x40)` in `AccPlay_WriteReverbFlag` |
| +4 bit 3 | **chorus on/off** | same routine, `bit 3 -> (xiy+14)`; event mask `0x08` in `AccPlay_WriteChorusFlag` |
| +7 | 7-bit level **[INFERENCE: volume]** | descriptor mask `0x7F`; floppy values 30/50/90/92/100 |
| +8 | 7-bit value sent as a MIDI CC | `AccPlay_SendBankProgram` sends `(xiy+12)` and mirrors it at +8; floppy value is 0x40 = centre **[INFERENCE: pan]** |
| +13 | **mute / part on-off** | `AccPlay_SaveMuteStates` / `AccPlay_RestoreMuteStates` / `AccompSeq_QueueMuteEvent` (`ldb d,0xd`), backed up to `0x7F1C..0x7F33` |

Which part is which, from `AccVoiceReg_WritePart1..5` (`v9/maincpu/sequencer/accompaniment_engine.s`,
source registers `0x3214 + 5k`): tag `0x14`→Part 1, `0x13`→Part 2, `0x10`→Part 3, `0x11`→Part 4,
`0x12`→Part 5. The v9 labels for the same five in `AccPatch_UpdateChain_*` read **Bass** (0x14),
**Rhythm** (0x13), **Acc1/Acc2/Acc3** (0x10/0x11/0x12). Tags `0x15 0x16 0x19 0x17 0x18` carry a
different descriptor default range (168..239) — **[INFERENCE: drum-kit numbers]**.

### Global records

| tag | span | meaning |
|---|---|---|
| `0x48` | 0xFC58, len 0x0A | **style / rhythm selection and tempo.** +0/+1 = style number (11-bit: `0xFC5A` plus `0xFC5B & 7`), read by `AccHelper_ComputeVoiceOffset`; descriptor min/max/default 0..244 / 96. **+8 (u16) = TEMPO**: `SeqTimer_PostTempoUpdate` stores it with `stda16 (0xFC62)` and posts `(e=0x48, d=8)`. +5/+6/+7 are the accompaniment run/pedal flag bytes hammered by `AccPedal_*`, `AccStyle_*`, `rhythm_routines`. |
| `0x80` | 0xFD4E, len 0x0E | sequencer / MIDI-clock control — read by `INTT1_CheckMidiSync`, `INTTR4_*`, `Transport_*`, `MidiCC_ChannelDispatch_*` |
| `0x92` | 0xFD1A, len 0x0E | 13 consecutive bytes read one by one by `SendEpilogue_Data` |
| `0x91` | 0xFDA8, len 0x0A | +3 is a panel-control bit touched by `SetWall_*`, `SongBank_CheckAccompanimentMode` and `NMI_HANDLER` |
| `0x93` | 0xFDB4, len 0x22 | 9 scalar params then **16 bytes defaulting to 0x40** (centre) — **[INFERENCE: a 16-part pan or balance array]** |
| `0xC0..0xD4, 0xD7` | 0xFDD8..0xFF8F | 22 identical 0x12-byte records, all sharing descriptor list 0xED8F82 (18 plain bytes, no masks or defaults); never touched by an absolute address anywhere in the disassembly |
| `0x78` | 0xF9A0, len 0x12 | 16 bytes with min/max/default 32/125/32, then 2 plain bytes. Present on the KN5000, **absent from the floppy files** |

### The `Lsw*` name vocabulary

The ROM carries an object-name table (pointers at `0xE807C2 + 4i`, strings at `0xE808AA..0xE80ABC`)
holding 31 `Lsw`-prefixed parameter names — the panel-parameter vocabulary of this subsystem:

    LswSound LswVolume LswPan LswReverb LswMute LswPartExp LswAfterTouch LswKeyScaling
    LswSustainPedal LswGlidePedal LswBendRange LswTuning LswKeyShift LswSustain
    LswSustainLength LswDigitalEffect LswDSPEffect LswLeftHold LswMidiChannel
    LswLocalControl LswMasterTuning LswOrchestrator LswScalingType LswScalingMode
    LswScalingShift LswScalingShift2 LswScalingKeyX LswPercLevel LswPercDecay
    LswDrawAttack LswDrawRelease

plus accessors `LswPartGet/LswPartAdd/LswPartPut`, `LswGet/LswAdd/LswPut`, `LswAddress`,
`LswFilter`, `LswData`, `LswDataNo`, `LswString`, `LswOutput`, `LswEditCheck`, and the file hooks
`PreLswLoad / PostLswLoad / PreLswSave / PostLswSave` (`v9/maincpu/audio/dsp_config_sysex.s`,
called from `midi_dispatch_handlers.s`). The table is a name registry, so it does **not** by itself
bind a name to an offset — that binding still has to come from the accessors.

### The second saved region, `0x1E7800..0x1E8000`

Previously "unidentified". Only two things in the whole image reach it: the `.LSW` handler, and
`AccVoiceState_Snapshot` (`accompaniment_engine.s`), which writes 10 bytes at
`0x1E7810 + 10*k` — five `(program, bank|flags)` pairs copied out of the five accompaniment part
records (tags `0x14 0x13 0x10 0x11 0x12`). `k` comes from `AccHelper_ComputeVoiceOffset`, which
derives it from the current style number at `0xFC5A/0xFC5B`. So the region is the **per-style
accompaniment voice-assignment table** — the user's per-style sound overrides.
