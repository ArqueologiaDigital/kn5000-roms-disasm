# The `.LSW` per-part record, byte by byte

`README-lsw-panel-schema.md` established the container: the KN5000 panel work area
`0x00F9A0..0x00FFC0` is a TLV stream whose schema is a ROM table, 26 of its records share
one **per-part layout**, and five of that layout's bytes were attributed (`+0`, `+4`,
`+13`, `+14`/`+15`, `+17`).

This page attributes the rest, and — just as important — says which bytes **cannot** be
attributed from the ROM, and why.

Everything here is produced by one new script:

```
python3 analysis/disk-format-probes/lsw_part_record_fields.py            # the table below
python3 analysis/disk-format-probes/lsw_part_record_fields.py --detail   # every access, with routine + line
python3 analysis/disk-format-probes/lsw_part_record_fields.py --gaps     # what the raw .byte blobs still hide
python3 analysis/disk-format-probes/lsw_part_record_fields.py v7         # same, against the v7 sources
python3 analysis/disk-format-probes/lsw_part_record_fields.py ~/…/*.LSW  # file-side value census
```

Offsets below are **decimal payload offsets** — exactly the `d` byte of
`SwbtWr_QueuePostEvent`, and byte `record_start + 2 + offset` in RAM. The family is tags
`0x00..0x16` and `0x19` (schema block 0) plus `0x17` and `0x18` (block 1): 26 records of
`0x18` = 24 payload bytes.

## First: the event protocol is now proven, not correlated

`lsw_field_evidence.py` argued `SwbtWr_QueuePostEvent(e=tag, d=offset, a=value, w=mask)`
from correlation — 20 of 21 call sites had a matching absolute access nearby. The routine
body itself was still raw `.byte` (`v7/maincpu/audio/dsp_config_sysex.s:491`). Decoded
from the v9 image at `0xFDB3F1` with `unidasm -arch tlcs900`, it is:

```
fdb3f1: cp   (0x90E2), 0x00FB        ; queue write offset vs 251-byte cap
fdb3f7: jr   ugt, ret
fdb3f9: ld   XHL, 0x0000BF39         ; queue base
fdb3fe: add  HL, (0x90E2)
fdb402: ld   (XHL),   DE             ; byte 0 = E = TAG,   byte 1 = D = OFFSET
fdb404: ld   (XHL+2), WA             ; byte 2 = A = VALUE, byte 3 = W = MASK
fdb407: ld   (XHL+4), 0xFF           ; terminator
fdb40b: add  (0x90E2), 4
```

So the queue entry *is* `[tag, offset, value, mask]`, straight from the writer. The
`(e,d,a,w)` reading is no longer an inference. (The same file continues at `0xFDB412`
with a second, `0xFF`-terminated table at `0xC039..0xC074` — a different queue, not
decoded here.)

## The method, and the new source

`lsw_field_evidence.py` scans **absolute** operands, `(0xF9C3)`. That is blind to how
most of this record is actually reached:

```
lda_d16 xiy, (0xf9b6)      ; part 0's payload base
lda     xix, (xiy + 12)    ; <-- offset +12; no absolute operand for it anywhere
```

`lsw_part_record_fields.py` adds a **base-pointer + displacement** pass: bind a long
register to a panel address, then resolve every `(reg+disp)` use of it. It also follows
the two rewrites the firmware uses to reach the three 0x620-byte mirrors of the region
(`sub reg,0xF9A0` then `add reg,{0x03C2C4|0x03C8E4|0x03CF04}`), which move the pointer but
not the field it denotes.

**Trap, worth knowing before you write any probe on these sources:** this assembler
prints displacement 0 as `+256`. `ld a,(xiy+256)` assembles to `[0x8d,0x00,0x21]` —
displacement byte `0x00` (checked with `llvm-mc -triple=tlcs900 --show-encoding`). A probe
that believes the printed number invents an offset 256. Normalised in the script.

Yield, v9: **280** absolute accesses, **294** base+displacement attributions, **25** event
sites. On v7: 222 / 219 / 0 (v7's `SwbtWr_QueuePostEvent` call sites are not converted).
**The set of offsets with code evidence is identical in v7 and v9** — this is not a
conversion artefact.

### The gate, and the wrong gate it replaced

The first version of the gate copied `lsw_field_evidence.py`'s ±12-source-line window and
**failed with 8 disagreements**. All 8 were the gate's fault, not the scan's:
`AccPatch_UpdateChain_{Rhythm,Bass,Acc1,Acc2,Acc3}` are near-identical clones laid end to
end, they touch a field ~20 lines before they announce it, and a line window therefore
compares one part's pointer against the *next* part's event. The gate is now
**routine-scoped**: in every routine where both sources speak, the set of tags must match
and every `(tag, offset)` posted must also have been reached through a pointer.
15 event sites in 5 routines, **15/15 agree**. It is worth recording that the line-window
form of this check is unsound on clone-heavy code, because `lsw_field_evidence.py` still
uses it and only passes by luck of layout.

## The table

`P` = proven (a mechanical fact: a mask the code applies, a value the code sends, a
descriptor range). `I` = inference, flagged as such.

| off | ROM descriptor | code evidence | reading | |
|---|---|---|---|---|
| **+0** | `t3` 0..167 def 21/40 (tags 10–13); `t4` 168..239 def 1 (tags 15 16 19 17 18) | `AccPlay_CompareAndSendProg` sends it as MIDI program change; `AccPatch_UpdateChain_*` post mask `0xFF`; `AccVoiceState_Snapshot` copies it to the per-style table | **sound / program number** | P |
| **+1** | `t0` mask `0x7F` + `t3` 0..7 | `AccPlay_CompareAndSendProg`: `and e,0xf` / `bit 7,w → or e,0x10`; `BitMapOut_RestoreVoiceFields` restores bits 0–6 (`res 7`) and preserves bit 7 | **bank**, 3 bits, **plus a bit-7 flag the restore deliberately keeps** | P |
| **+2** | `t8` (all 26) | copied by `BitMapOut_ByteData_PatchTable` in the +0..+9 group; *nothing reads it* | member of the voice-parameter group, otherwise dead; `0x00` in all 4,214 saved part records | I |
| **+3** | **none, on any part tag** | `BitMapOut_ByteData_PatchTable` (+0..+9 group); `EffectMode_CopyVoiceParams` writes it from DSP-preset byte +31; `EffectMode_CopyParamByte` copies tag 13's +3 into tag 03's +3 | a byte the **DSP-effect preset owns**; not exposed to the panel-editor descriptor table at all. Files: 51 distinct, 0x3C..0xF2, mode **0x64 = 100** | I: a level |
| **+4** | `t2` mask `0x10` (6 tags); `t0` mask `0xA0` (tags 0F, 14) | `AccPlay_WriteReverbFlag` posts mask `0x40`; `AccPlay_WriteChorusFlag` posts mask `0x08`; `BitMapOut_RestoreVoiceFields` restores exactly `& 0x48`; `BitMapOut_ByteData_PatchTable` / `EffectMode_CopyVoiceParams` take `& 0xCF` from the preset and **keep `& 0x30` local**; `EffectMode_UpdateBitFlags` reads bit 5 for parts 0–3 | **bit 6 = reverb on/off, bit 3 = chorus on/off** (the pair `0x48` that the restore moves as a unit). Bits 4–5 are the part's own, never overwritten by a preset. Bits 0,2 unattributed | P (bits 6,3) |
| **+5** | `t0` mask `0x7F` (all 26) | +0..+9 group; `EffectMode_ProcessPresetChange_Apply` does `andmi8 (0xF9EF),0x80` — clears bits 0–6, keeps bit 7 | a 7-bit parameter the preset-change path zeroes + a bit-7 flag. Files: 0x00 in 95%, else 0x50/0x7F | I |
| **+6** | `t8` (all 26) | **none — and `BitMapOut_ByteData_PatchTable` steps over it**, copying +5 then +7 | reserved. The skip is positive evidence, not just absence | P (unused) |
| **+7** | `t0` mask `0x7F` (all 26) | +0..+9 group only | 7-bit level. Files: 14 distinct, 0x1E..0x70, **96% = 0x5A = 90** | I |
| **+8** | `t0` mask `0x7F` (all 26) | `AccPlay_SendBankProgram` mirrors voice-slot `+12` here and posts mask `0x7F`; the same byte is emitted into the sequencer event buffer as the 3-byte event `D1 04 <value>` (`AccompSeq_WriteMidiToBuffer` writes `a`, `w`, `e` in that order; the reverb and chorus flags of +4 go out the same way as `D1 07` and `D1 03`); `BitMapOut_RestoreVoiceFields` restores bits 0–6 and preserves bit 7 | 7-bit value + bit-7 flag. Files: 27 distinct over the full 0x00..0x7F, **mode 0x40 = centre** | I: **pan** |
| **+9** | `t0` mask `0x7F` (all 26) | +0..+9 group only | 7-bit. Files: `0x40` in 4023 of 4032 records; the 9 exceptions are 0x34 and 0x4C | I: a centred control that is essentially never moved |
| **+10** | **none** | **none** | **not attributable from the ROM.** Only fact available: `0x80` in every one of the 4,214 saved part records | — |
| **+11** | `t0` mask `0x7F` (all 26) | **none** | **declared but dead**: a 7-bit field no routine in either v7 or v9 reads or writes. `0x02` in every saved record | — |
| **+12** | `t0` mask `0x3F` (23 tags); `0x07` (0F, 14); `0xFF` (19) | `BitMapOut_RestoreVoiceChannels` restores **bits 0–2 only** (`& 0xF8` keep, `\| mirror & 0x07`) for all 26 parts, immediately before restoring +13 | bits 0–2 are a 3-bit selector restored with the "voice channel" group; bits 3–5 are declared but never restored. Files: only 0x00 / 0x20 / 0x38 | I: output routing |
| **+13** | `t0` mask `0xEF` (25 tags) — **bit 4 excluded** | `AccPlay_SaveMuteStates` / `RestoreMuteStates` (events mask `0xCF` and `0x4F`); 18 `AudioInit_*` sites test **bit 5** (tags 02, 13, 15); `PanelEvt_CheckFlag7_Dispatch_{A,B,C}` test **bit 6**; `AccAutoPlay_SplitDetect_*` test **bit 7** and compare the **low nibble** against an incoming 4-bit value; restored wholesale by `BitMapOut_RestoreVoiceChannels` | **a packed part-status byte, not one mute bit.** bits 0–3 = a 4-bit id compared part-to-part; bit 5 = audio-routing gate; bit 6 = event-dispatch gate; bit 7 = an off/skip flag; bit 4 reserved. "Mute" is what bits 6–7 do in the save/restore pair | P (structure) / I (nibble = MIDI channel) |
| **+14** | `t8`, and **only on tags 0F,10..19** | `BitMapOut_DispatchIOChanges` tests **bit 7** of tag 00/01/02's +14 and calls `BitMapOut_ApplyIOChange_Port{0,1,2}`, which read it with `res 7` | **I/O port value for parts 0–2, bit 7 = "changed, needs applying"** | P |
| **+15** | `t8`, only on tags 0F,10..19 | `BitMapOut_ApplyIOChange_Port{0,1,2}` read the whole byte (`and a,0xFF`) | second byte of the same I/O group, no flag bit | P |
| **+16** | `t8` (all 26) | **none** | dead; `0x00` in all 4,214 saved part records | — |
| **+17** | `t8`, only on tags 0F,10..19 | `BitMapOut_DispatchIOChanges` tests bit 7 → `BitMapOut_ApplyIOChange_Port{3,4,5}`, which `res 7` | **I/O port value for ports 3–5, same bit-7 flag** | P |
| **+18..+21** | `t8` (all 26) | **none** | dead; `0x00` in all 4,214 saved part records | — |
| **+22** | `t0` mask `0x01` on tags 00..0E; `t8` on the rest | **none** | the record's only declared *bit* field that nothing ever touches. `0x00` everywhere | — |
| **+23** | `t8` (all 26) | **none** | dead; `0x00` in all 4,214 saved part records | — |

### The remaining L3 gap, stated plainly

* **10 of the 24 bytes have no code evidence at all**, in either v7 or v9:
  **`+6 +10 +11 +16 +18 +19 +20 +21 +22 +23`**.
  Of these, `+10` has no ROM descriptor either — nothing in the image says it exists.
  `+6` is the one with a *reason*: the routine that copies the voice-parameter group
  jumps over it.
* **4 more bytes are only "grouped", not named**: `+2 +5 +7 +9` are reached solely by
  the block copies (`BitMapOut_ByteData_PatchTable`, +0..+9), which proves they belong to
  the same voice-parameter set as sound/bank/effect but says nothing about which is which.
* `+3`'s reading and `+8`'s reading (level and pan) are the two that would most repay
  being settled, and neither is settled here.

## What more code conversion would buy: measured, and the answer is "nothing"

`--gaps` counts, inside every raw `.byte` blob, the byte triples that encode a TLCS-900
absolute 16-bit operand landing in the panel region — prefix `{C1,D1,E1,F1}` then LE16 in
`0xF9A0..0xFFC0` (verified against `llvm-mc --show-encoding`: `ldb_d8 a,(0xF9C3)` =
`C1 C3 F9 21`, `stb_d8 (0xF9C3),a` = `F1 C3 F9 41`, `lda_d16 xwa,(0xF9B6)` = `F1 B6 F9 30`).

> **25** candidates in **107,834** bytes of raw `.byte` across 26,506 lines —
> against a chance expectation of **40**.

The still-unconverted v9 code contains *fewer* panel-address operands than random bytes
would. **Converting more code will not attribute more of this record.** The nine bytes
above are not hiding in undecoded blobs; the firmware genuinely never touches them.

(Scope of that bound: a routine that reaches a part record must establish its base
somewhere, and every base in this subsystem is an absolute literal — so bounding the
absolute-operand channel bounds the pointer channel with it. What it does *not* bound is a
routine handed a panel pointer by a caller that is itself undecoded.)

For contrast, `lsw_field_evidence.py`'s own skip counter — sites dropped because a `.byte`
blob sat within 12 lines — is **2**, both in `ClockConfig_Handler_0`
(`v9/maincpu/display/scoop_display.s:7496` and `:7619`), both on tag `0x48`, and
**neither on a part record**. The unconverted code costs this question nothing.

## Two things found on the way

**1. Tag `0xC0+n` is part `n`'s companion record.** `README-lsw-panel-schema.md` records
the 22 records `0xC0..0xD4, 0xD7` as "never touched by an absolute address anywhere". They
are — by a `lda`, which is why an operand scan that only looks at loads and stores misses
it. Six sites, each right after `call PartCtrl_WriteProgramChange`:

| routine | part written to `(0x90F7)` | base loaded | record |
|---|---|---|---|
| `AccPatch_UpdateChain_Acc1` | 0x10 | `0xFF1A` | tag `0xD0` payload |
| `AccPatch_UpdateChain_Acc2` | 0x11 | `0xFF2E` | tag `0xD1` payload |
| `AccPatch_UpdateChain_Acc3` | 0x12 | `0xFF42` | tag `0xD2` payload |
| `AccPatch_UpdateChain_Rhythm` | 0x13 | `0xFF56` | tag `0xD3` payload |
| `AccPatch_UpdateChain_Bass` | 0x14 | `0xFF6A` | tag `0xD4` payload |
| `AccPlay_SetupSoundParams` | 0x17 | `0xFF7E` | tag `0xD7` payload |

6 of 6 satisfy `base = payload(0xC0 + part)`. One mismatch would kill the rule; there is
none. What each record *holds* is still unknown: the instruction is
`lda XIZ, (XBC + HL)` (`f3 03 e4 ec 46`, confirmed by assembling
`lda_dri XIZ, 0x03, 0xe4, 0xec`), i.e. it computes a pointer into that record indexed by
`PartCtrl_WriteProgramChange`'s return value — and no instruction in the enclosing routine
dereferences `XIZ`, nor does `SwbtWr_QueuePostEvent` (disassembled above) read it.

**2. Why the `Lsw*` names cannot be joined to these offsets by searching.** The 31
`Lsw…` parameter names (`LswVolume`, `LswPan`, `LswMute`, …) are a plain pointer array at
`0xE807BE + 4i` with no parallel offset table. `MainLswPartPut/Add/Get`
(`v7/maincpu/ui/ui_widget_defs.s:1345/1411/1500`) do not resolve an address either: they
`Malloc` a 12-byte message, pack `(param_id << 16) | part` into it, and hand it to
`FuncCall` with selectors `0x1E0005A/5B/5C`. Resolution happens in
`SndParam_LookupReadOnly`, which hashes the 32-bit id into a **2048-entry runtime table at
RAM `0x34100`** and calls a handler from `Naka_MainDispatch_Table_0xDC0`. The binding is
therefore created at boot, by registration, and a static scan of the ROM cannot follow it.
Grepping for `LswVolume` cannot find code that refers to it by pointer — recovering the
name↔offset map needs the registration sites, not more searching.

## File-side census (independent of the firmware)

`lsw_part_record_fields.py <files>.LSW` counts what values each offset actually takes in
real saved panels. Corpus: the seven floppies in `~/compartilhado/KN7000/floppy-archive/`
(unzip first), 4,214 per-part records: 4,032 in the 22-byte slot form, 182 in the 30-byte form
(168 of them in block 0). It cannot name a field, but it can contradict a naming, and it is the only
evidence here that is not the firmware.

Two things it settles:

* the 22-byte slot record is the **first 22 bytes of the 30-byte block-0 record** (the
  per-offset distributions match term for term), and the 30-byte record is the firmware's
  24 bytes plus six zero pad bytes — so **file offsets and firmware offsets are the same
  numbers**, no re-basing needed;
* `+4` is seen as `0x15 / 0x45 / 0x55 / 0x5D` — i.e. bit 6 and bit 3 toggling
  independently over a fixed `0x15` background. That is the reverb/chorus pair varying in
  real user data, from the file side, with no firmware involved.

Constant across all 4,214 records: `+2`=0x00, `+6`=0x00, `+10`=0x80, `+11`=0x02,
`+16`=0x00, `+18..+21`=0x00 (and `+22..+29`=0x00 in the 30-byte form). **All ten** of the
offsets no code ever touches are also constant in every saved panel — the two independent
sources agree. The converse does not hold: `+2` is constant in the files yet is copied by
the firmware's voice-parameter block move, so "constant in user data" alone would have
over-counted the dead set by one.
