# The KN5000 panel records that are **not** the 26 per-part records

`README-lsw-panel-schema.md` established the container (the live panel work area
`0x00F9A0..0x00FFC0` is a tag/length/value stream whose schema is a ROM table) and
`README-lsw-part-record-fields.md` pinned the fields of the 26 per-part records
(tags `0x00..0x19`). This note covers the rest:

    block 0 (base 0xF9A0):  78 44 45 46 47 43 48 90 60 61 63 64 65 66 68 70 72 92 71 99 80
    block 1 (base 0xFD60):  98 91 93  C0..D4 D7  49 9A

Run `python3 analysis/disk-format-probes/lsw_nonpart_records.py` for the machine-checked
part (see the bottom of this file).

---

## The headline: `C0..D4` + `D7` is one array — **one companion block per PART**

Record `0xC0 + T` is the companion block of **part record `T`**. This is not a guess from a
routine name; it is a ROM pointer table.

`VoiceData_LookupPtrByChannel` (`0x00FC9E04`) is

```
    if A <= 0x1F:  return u32[0x00EDB264 + 4*A]
    elif A == 0x48: return 0x00FF92          ; VoiceLookup_CheckRhythm, 0x00FC9E19
    else: return -1
```

and the table at `0x00EDB264` reads, byte for byte:

| part tag | → block | | part tag | → block |
|---|---|---|---|---|
| `00`..`14` | `C0`..`D4` payload+0, one-to-one | | `15` | **`D0`** (aliased onto part `10`) |
| `17` | `D7` payload+0 | | `16` | **`D3`** (aliased onto part `13`) |
| | | | `18` | **`D7`** (aliased onto part `17`) |
| `19`..`1F` | `-1`, no block | | `48` | **tag `49`** payload+0 (special-cased in code) |

That is the whole explanation of the family's odd shape: it stops at `D4` and then jumps to
`D7` because `D5`/`D6` were never needed — parts `0x15` and `0x16` share the blocks of
`0x10` and `0x13`. And **tag `0x49` is the same kind of block for the style/rhythm record
`0x48`**, which is why it sits in the same corner of block 1.

### What the block is

An 18-byte array accessed as `block[index] = value` / `value = block[index]`:

| role | routine | address (v9) |
|---|---|---|
| write | `MIDI_DistributeParamToChannels` | `0x00FC9CF9` |
| read | `VoiceData_DistributeToChannels` | `0x00FC9D41` |
| bulk write at init | `Voice_InitChannelLoop` | `0x00FC4CF6` |
| index bound | `ApplyProgramChangeAs_DoLookupRe` | `0x00FEE770` |

Both accessors take the same 4-byte descriptor `{ u8 part_tag, u8 ?, u8 index, u8 value }`
— `MainVariSet` (`0x00FC27D9`, object method id `0x01E20000`) receives exactly that struct
off the message bus and forwards `(tag, index, value)`. The writers' callers are the
**sound-select** paths: `Sound_SetSelection` (`0x00F98DEA`), `Sound_Navigate_ApplyChange`
(`0x00F98F77`), `MainVariSet`, `MIDI_SetupChannelParams` (`0x00FCA2CD`). The reader is
called from `FileIO_BytecodeData` (`0x00FC5CB1`, `0x00FC5D63`).

At boot, `Voice_InitChannelLoop` walks the 23 tags of the ROM list at `0x00ED92F2`
(`00 01 … 14 17 48 FF`) and, for each, does

```
    local.tag  = tag ; local[3] = part_payload[0] (program) ; local[4] = part_payload[1] (bank)
    SndParam_ResolveVoiceEntry(&local)      ; 0x00FC9B55 -> SndParam_FetchOscTableEntry 0x00FEE7EA
    block[ local[0] ] = local[1]
```

so `index` and `value` come out of a `(bank, program)`-indexed ROM table
(`*(*(0xE14E)+0x10 or +0x20) + 0x80 + bank*0x400 + program*4`, bytes 0 and 2).

**[INFERENCE]** the index is a *sound-group / category* number and the byte is the
selection remembered for that group — i.e. the block is the part's "last sound chosen in
each group" memory, and `0x49` the same for rhythm groups. Two things support it and one
number nails half of it: the object method is called `Vari`(ation)`Set`, the writers are the
sound-select screens, and for the `0x48` path the bound is the literal `0x0F` while record
`0x49` is exactly `0x10` bytes long — 16 slots, 16 groups. **Falsifier:** count the KN5000's
SOUND group buttons; if it is not 18, this reading is wrong. **Open:** in one branch
`ApplyProgramChangeAs_DoLookupRe` returns `0x80`/`0x89` as the bound, which is far past the
end of an 18-byte record — either that branch never runs for these callers, or the firmware
treats `0xFDD8..0xFF8F` as one contiguous 440-byte area. Not settled here.

### Why they look dead from every other angle

Three independent negative results, all machine-checked by the probe on **v7, v9 and v10**:

1. **No event can ever reach them.** `SwbtWr_DispatchLoop` reads the event tag and executes
   `cp L,0xbf / jr UGT,skip` *before* indexing its tag→callback table (v9/v10 `0x00FDB347`,
   v7 `0x00FDAB76`). Tags `>= 0xC0` are dropped, and the three callback tables
   (`0x00EE7786`, `0x00EE7CA7`, `0x00EE86D0`) only have `0xC0` entries. So the C-family is
   deliberately parked *above* the notifiable range.
2. **Nothing names them in an event.** All **64** calls to `SwbtWr_QueuePostEvent` in each
   ROM were decoded; the literal tags used are `00 10 11 12 13 14 17 48 90 91 B1 B2 B3 B4`.
   Nothing `>= 0xC0`. (`B1..B4`, and `90 d=0x10`, are notification-only ids with no record.)
3. **No instruction addresses them directly.** A whole-ROM census of TLCS-900 direct
   addressing (`F1 lo hi` 16-bit, `F2 lo hi 00` 24-bit) found 653 (v7) / 746 (v9, v10)
   operands inside the panel area, of which 582 / 617 / 617 are instruction-aligned — and
   **zero** of the aligned ones is a memory access to a C-family record. The six or seven
   that land there disassemble as `db` or as the operand tail of a `call`/`jp` inside a data
   table (`Bitmap_1bit_Flash_Memory_Update`, `Composer_SettingsBlock`, …). This census does
   **not** depend on how much of the disassembly has been converted away from `.byte`.

And in the seven floppy `.LSW` files the C-family holds 154 records (22 × 7) that are
**every byte zero**. Consistent with a block whose only writer is a sound-select action.

---

## The other block-0 / block-1 records

Grades: **[NAME]** = the enclosing routine's name is the whole argument; **[CODE]** = what
the instructions do; **[INFERENCE]** = a reading, with the falsifier stated.

| tag | span (len) | what it is | evidence |
|---|---|---|---|
| `78` | `0xF9A0` (`0x12`) | **16-character ASCII name of the currently selected Music Stylist style**, then 2 plain bytes. | **[CODE]** `EffectMode_DisplayPresetName` (`v9/maincpu/ui/ui_mode_handlers.s:432`) picks a record out of `STYLEREC_PTRTABLE_C2C5` (`0x986000`) / `_DEFAULT` (`0x987000`) by the current selection at `0x8D56`, then `EffectMode_DisplayName_Render` does `Strncpy(0xF9A2, rec+43, 0x10)`. `ToneGen_ApplyMaskTable` blank-fills it with `Memset(0xF9A2, 0x20, 0x10)`, matching the descriptor `min=32 max=125 default=32` ×16. Note this record is **absent from the floppy `.LSW` files**. |
| `43` | `0xFC52` (`0x04`) | one bit at `+0` mask `0x80`, two plain bytes | **[NAME]** `BitMapOut_RestoreExtra_CheckDataBit`, `BitMapOut_CopyAuxTable_Check`; callback `HdaeRom_AltTableEntry9` |
| `44` `45` `46` | `0xFC24/30/3C` (`0x0A`) | three identical records: one 6-bit field at `+7` (`0x3F`) and a plain byte at `+9` | **[CODE]** all three share descriptor list `0xED8D0A`; touched by `FDemoText_SyncPreset_DirectCopy`, `AcPresCtrl_DefaultCase`, `BitMapOut_RefreshDisplay_UpdateRegs`, `BitMapOut_CalcDisplayMetrics`; all three subscribe `UIState_KeyScan_Dispatch` + `FDemoText_ByteData_VoiceProbeC` |
| `47` | `0xFC48` (`0x08`) | 4 ranged fields: `+1` 0..17, `+2` 0..99, `+3` 0..176 (mask `0xF0`), `+5` 0..121 and 16..28 | **[CODE]** descriptor list `0xED8D10`; `BitMapOut_RestoreFull_CheckEnd`, `BitMapOut_RestoreExtra_CheckCtrlBit`, `BitMapOut_PartialRestore` |
| `48` | `0xFC58` (`0x0A`) | **style/rhythm selection + tempo** (already documented) — `+0/+1` 11-bit style number, `+5/+6` accompaniment pedal/run flag bytes (`+5` alone: 59 reads and 58 read-modify-writes, the most-hammered field in the area), `+8` u16 tempo | **[CODE]** `SeqTimer_PostTempoUpdate` posts `(e=0x48,d=8)`; 22 of the 64 event sites are tag `0x48` |
| `49` | `0xFF90` (`0x10`) | **the `0x48` record's companion block**, 16 slots | **[CODE]** `VoiceLookup_CheckRhythm` returns `0xFF92` for tag `0x48`; the writer hard-codes bound `0x0F`; `DrumVoice_Handler7` and `RhythmVariation_InlineCode` write `+15` |
| `60` | `0xFC6C` (`0x04`) | 3-bit field at `+1` (mask `0xE0`) + 2 plain bytes | **[NAME]** `BitMapOut_RestoreExtra_CheckLevelBit` / `CheckExpBit`, `EffectMode_UpdateBitFlags`, `VoiceData_SyncLoop` |
| `61` `63` `65` `66` `64` | `0xFC72/8C/C0/DA/A6` (`0x18` each) | **five 24-byte effect/DSP parameter blocks**, no field descriptors at all (empty list `0xED8D96`) — they are opaque blobs pushed whole. `DSPCfg_InitAllEntries` hands them to `DSPCfg_WriteAllSlots_Combined` as **slots 0,1,2,3,4** in the order `61→0, 63→1, 65→2, 66→3, 64→4`. | **[CODE]** `v9/maincpu/audio/tonegen_fileio_handlers.s:228-248`. `0x63` and `0x64` each have a loop that walks all 24 bytes and calls `AssswbWr(tag, i, byte, 0xFF)` — `ReverbPreset_Load/SendLoop` (`0x00FC9F9F`) for `0x63` and `EQPreset_Load/SendLoop` (`0x00FC9FF7`) for `0x64`, then `SoundParam_NotifyChange(0x4002)` / `(0x4006)`. `SysEx_ApplyVoiceParam_49` writes `0x61`, `SysEx_ApplyVoiceParam_4B` writes `0x63`. **[INFERENCE]** `0x63` = reverb block, `0x64` = EQ block (the routine names and the two distinct notify ids); `0x61`/`0x65`/`0x66` = the other three DSP slots. Falsifier: change one byte of `0x64` on hardware and listen for an EQ change, not a reverb change. |
| `68` | `0xFCF4` (`0x0A`) | opaque, no descriptors | **[NAME]** `BitMapOut_CopyAuxTable_Loop/Check`; callback `HdaeRom_TableEntry0` |
| `70` | `0xFD00` (`0x08`) | **digital-effect selection**: `+2` 0..11 def 5, `+3` 15..254 def 255, `+4` 0..13 def 7, `+5` 1..16 def 2, `+6` 1..16 def 4 | **[NAME+CODE]** subscribers `UIStateEvt_EffectSelect_Data`, `DSPCfg_ProcessInput`; touched by `EffectMode_UpdateBitFlags`, `EffectMode_SetRegion_Apply`, `PanelEvt_Handler_4_DualValueCheck` |
| `71` | `0xFD2A` (`0x02`) | 2-bit field at `+0` | **[NAME]** `PmemOutLGridCheck` (panel-memory), `BitMapOut_Snapshot_PostProcess`, `UIStateEvt_MuteToggle_Data` |
| `72` | `0xFD0A` (`0x0E`) | 4-bit value `+0` (0..15), level `+1`, pan-ish `+4`, `+5`, `+7`, then six `0x80` bit-flags `+8..+0D` | **[NAME]** `AccompSeq_MidiFilterCodeBlock` and `AccompSeq_HandleSpecialMode` read/write `+6` |
| `80` | `0xFD4E` (`0x0E`) | **sequencer / MIDI-clock control** — `+0` is the busiest flag byte in the file (42 reads) | **[CODE]** `INTT1_CheckMidiSync`, `INTTR4_*`, `Transport_*`, `MidiCC_ChannelDispatch_*`; the flash "power-on defaults" blob at `0x00ED933A` writes `0xFD50..0xFD5C` with exactly the descriptor masks |
| `90` | `0xFC64` (`0x06`) | small bit-field record; note `(e=0x90, d=0x10)` is a **notification past the end of the record**, posted by `AccStyle_IndexedLookup`, `AccStyle_InlinedBlock`, `AccPatch_PartChanges_MapLookup`, `AccPlay_SetupSoundParams` with values `0x14` / `0x17` — i.e. *part tags*. **[INFERENCE]** "the active part changed to <tag>" | **[CODE]** 4 of the 64 event sites |
| `91` | `0xFDA8` (`0x0A`) | `+3` is a panel-control bit (12 R, 6 RMW) touched by `SetWall_*`, `SongBank_CheckAccompanimentMode`, `NMI_HANDLER`; `+4` is written by `DrumVoice_Handler7` | **[CODE]** |
| `92` | `0xFD1A` (`0x0E`) | ⚠ **corrected 2026-08-23: a 15-parameter UI record whose ids tile all FOURTEEN payload bytes** — was described as 13 consecutive bytes read one at a time by `SendEpilogue_Data` | **[CODE]** |
| `93` | `0xFDB4` (`0x22`) | 9 scalar params (`+0` 0..9 def 6, `+2`/`+3` 0..127 def 127, `+4` 0..12 def 2, `+5` 0..10 def 5, `+6`/`+8` 1..127 def 1, `+7` 0..3) then **16 bytes each defaulting to `0x40`** — **[INFERENCE]** a 16-way pan/balance array | **[CODE]** descriptor list `0xED8F12` |
| `98` | `0xFD94` (`0x12`) | mixed: `+1` 0..80, `+3` 16..48 def 32 (mask `0x70`), `+0A` 0..99 def 90, `+0E` 0..2 | **[NAME]** subscribers `UIStateEvt_PlayModeGuard_Data`, `MidiOut_RealtimeDispatch_Data`, `DSPCfg_ProcessInput`; `AccDir_*` read `+3` |
| `99` | `0xFD2E` (`0x1E`) | 5-bit field `+1`, 3 plain bytes at `+1B..+1D`; `+2` read by `Audio_ReinitToneGenAndOutput` and `MIDI_DispatchVoiceParamCC` | **[NAME]** |
| `9A` | `0xFFA2` (`0x1A`) | 10 plain bytes at `+0..+3` and `+14..+19`; **nothing but the generic init touches it** | **[CODE]** |

### Things the probe found on the way that are worth writing down

* **Part-record field `+0x0C` is the MIDI channel.** The three "power-on default" blobs the
  firmware burns into flash (`0x00ED933A → 0x3D3000`, `0x00ED9434 → 0x3D3110`,
  `0x00ED951E → 0x3D3210`; written by `ToneGen_FlashWriteAll`) are 6-byte records
  `(u16 addr, u16 0, u8 a, u8 b)` — for the tag-`0x80` stretch `a` reproduces that record's
  descriptor masks exactly (`7F 0C 1C C5 … 3F …`), so `b` is the value. Their first 22
  records all target `payload+0x0C` of a part record: tags `0x00..0x0F` get `0..15` and tags
  `0x19, 0x10..0x15` get `0xC0`. So tags `0x00..0x0F` are the 16 MIDI-receive parts and
  `0xC0` means "no channel" (which is why tag `0x19`'s `+0x0C` mask is `0xFF` while the
  others' is `0x3F`).
* **The KN5000's own panel-file writer saves only `0xF9A0..0xFDA2`** (`0x402` bytes) —
  `ToneGen_FileIO_SaveAndSync` computes the length as `0xFDA2 - 0xF9A0`. Everything from tag
  `0x91` onwards, the whole C-family included, is outside that copy.
* **Event ids `0xB1..0xB4` have callbacks but no record.** `MidiStream_DispatchData_0xEE`
  posts them; they are notification-only, like `(0x90, 0x10)`.

---

## Still unidentified — say so plainly

* **`0x9A`** (`0xFFA2`, 26 bytes). Nothing in any of the three ROMs reads or writes it apart
  from `DSPCfg_InitAuxEntries`/`DSPCfg_ResetAuxEntries` walking every block-1 entry. Its only
  callback is `UIState_KeyScan_Dispatch`, which every tag has.
  ~~**No identification is possible from the ROM.**~~ ⚠ Softened 2026-08-22: that sentence
  claims a limit on the ROM when what it had measured was a limit of one search. The
  neighbouring `0x44/0x45/0x46` entry made exactly this claim and fell the same week, to a
  wider parameter-id window. Accurate version: **no identification has been FOUND**, by the
  searches listed above; a scan whose window is stated is falsifiable, an impossibility claim
  is not.
* **`0x68`, `0x43`** — the touching routines are all generic bitmap/restore helpers, so the
  name evidence does not narrow anything. Field *shapes* are known, meanings are not.
* **`0x71`** — ⚠ **NARROWED 2026-08-22, this entry was too pessimistic.** The routines are
  generic, but the ADDRESS is not: every real site touches bit 1 of `0xFD2C`, and since block 0
  is 960 bytes and `0xFD2C - 0xF9A0 = 0x38C`, the panel-memory grid's
  `0x1ED400 + index*0x3C0 + 0x38C` is this tag's payload+0 for slot `index`. It is a
  **per-panel-memory ON/OFF flag** (the display arm selects `" ON  "`/`" OFF "`). Its UI label
  and bit 0 of the `0x03` mask are still open.
* **`0x61`, `0x65`, `0x66`** — known to be three of the five 24-byte DSP slots, but which
  effect each drives is not settled (only `0x63`/`0x64` have the reverb/EQ send loops).
* ~~**`0x44` / `0x45` / `0x46`** — three identical records; that they are a *set of three* is
  the only structural fact. What the set is, is unknown.~~
  ⚠ **IDENTIFIED 2026-08-22: the DRAWBAR registration, one record per keyboard part**
  (`0x44` RIGHT 1, `0x45` RIGHT 2, `0x46` LEFT). The "set of three" WAS the clue -- three
  parts. They carry 48 parameter ids at `0x8200/0x8600/0x8A00`; the earlier scan only covered
  `0x4000..0x4FFF`. See `README-lsw-drawbar-records.md`.
* **`0x92`, `0x93`, `0x98`, `0x99`, `0x90`, `0x91`** — field shapes and touching routines are
  recorded above; the semantic labels beyond that are inference, marked as such.
* **The C-family's index space.** The mapping tag→block is proved; the meaning of the *index*
  inside the block is inference, and the `0x80`/`0x89` bound branch is unexplained.

---

## Reproducing

```
python3 analysis/disk-format-probes/lsw_nonpart_records.py
python3 analysis/disk-format-probes/lsw_nonpart_records.py --quiet
python3 analysis/disk-format-probes/lsw_nonpart_records.py \
        --lsw-dir <dir with the unzipped floppy images>
```

Needs `~/compartilhado/tools/unidasm` for tests 3 and 4 (it skips them, with a note, if the
binary is missing). Corpus for `--lsw-dir`: unzip `~/compartilhado/KN7000/floppy-archive/*.zip`,
each archive holds one 22,528-byte `.LSW`.

Summary of the output on 2026-08-22, all three ROMs (the script prints it per version):

```
  [1] 25 live entries in 0xEDB264, 22 distinct C-family blocks, 3 aliases, 0x48 -> tag 49
  [2] the cp L,0xbf guard is present exactly once   (v7 0xFDAB76, v9/v10 0xFDB347)
  [3] 653 / 746 / 746 direct-address candidates, 582 / 617 / 617 aligned, 0 real C-family accesses
  [4] 64 / 64 / 64 event call sites; literal tags 00 10 11 12 13 14 17 48 90 91 B1 B2 B3 B4
      154 C-family records across 7 .LSW files, 0 with any non-zero byte
  PASS
```
