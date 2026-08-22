# The leftover panel-TLV records (2026-08-22)

Companion note to `lsw_leftover_records.py`. Run it with

    python3 analysis/disk-format-probes/lsw_leftover_records.py            # T5 needs /tmp/disk
    python3 analysis/disk-format-probes/lsw_leftover_records.py --lsw-dir <dir>

It exits non-zero if any of the eight tests stops holding, on v7, v9 **and** v10.
The floppies for T5 are recreated with the recipe in `README.md`.

`docs/kn-disk-file-formats.md` closed its panel-schema section with three open items. This
pass closes one of them outright, closes one more, half-refutes the third, and leaves two
records genuinely unidentified. What follows is the summary; the reasoning, the exact
addresses and the failure modes are in the probe's docstring.

---

## 1. The five DSP/effect slots — SOLVED

Two ROM tables and one validator settle it. All three are located by byte pattern, so the
result is version-independent.

| slot | tag | param ns | algorithms the ROM accepts | what that is |
|---|---|---|---|---|
| 0 | `0x61` | `0x4900` | everything except 16..27 (47 named) | **DSP EFFECT** (38) + the 9 of slots 2/3/4 |
| 1 | `0x63` | `0x4B00` | 9, 10, 16..27 (14) | **DIGITAL REVERB** — 12 reverbs + 2 delays |
| 2 | `0x65` | `0x4D00` | 57..60 (4) | **ACOUSTIC ILLUSION** — STANDARD / PERCUSSIVE / SYMPHONIC / DEEP SPACE |
| 3 | `0x66` | `0x4E00` | 88..91 (4) | ROOM / KARAOKE / BATH ROOM / STAGE |
| 4 | `0x64` | `0x4C00` | 79 only (1) | **EQUALIZER** — GEQ |

* `SlotToTag` at `0x00EE636C` is literally `61 63 65 66 64 FF`, read by
  `DSPCfg_WriteAllSlots_Direct` to pick the tag it hands to `AssswbWr`.
* `DSPCfg_Data_ParamDispatch` maps tag → (namespace, slot) through a 6-entry offset table at
  `0x00EE6384`; `0x62` has no panel record and shares slot 1.
* `DSPCfg_SlotAcceptsAlgorithm` (v9/v10 `0x00FDC883`) is the per-slot range check above,
  behind the common precondition `algo <= 99 && u32[0x00EE75F6 + 4*algo] != 0`.
* **Byte 0 of a slot record is the algorithm number.** The ROM reverb presets at `0xEDB36C`
  and EQ presets at `0xEDB394` are 24-byte blobs copied straight to `0xFC8E` (tag `0x63`) and
  `0xFCA8` (tag `0x64`); their byte 0 reads 16..27 and 79.

**Three independent agreements with `docs/effects-dsp.md`, which was derived from the Sub CPU
and shares no code path with any of the above:** the union of slots 2/3/4 is exactly the nine
IC310 (MN19413) algorithms {57,58,59,60,79,88,89,90,91}; slots 0/1 are exactly the IC311 ones,
matching the Sub-CPU slot→chip table `0,0,1,1,1` at `0x01ED6D`; and 47 − 9 = **38**, the DSP
EFFECT page's type count.

**And a gate on real data.** In the seven floppies, 175/175 tag-`0x61` records and 175/175
tag-`0x63` records satisfy their slot's predicate, with disjoint byte-0 sets
(`01 05 06 09 21 23 34 36 42 44 50` vs `14 15 18 19`). Swapping the two predicates would
produce 175 violations.

### The notify ids were the ON/OFF switches all along

The older note recorded `0x4002` and `0x4006` beside the `0x63` and `0x64` send loops without
knowing what they were. The ROM parameter-descriptor table says:

    0x4002 = tag 0x60 payload+1 bit 7   -> slot 1  REVERB
    0x4004 = tag 0x60 payload+1 bit 6   -> slot 2  ACOUSTIC ILLUSION
    0x4006 = tag 0x60 payload+1 bit 5   -> slot 4  EQUALIZER
    0x4140 = tag 0x43 payload+0 bit 7   -> slot 3

which is why tag `0x60`'s field descriptor declares `+1` with mask `0xE0`.

The bit→slot column has two kinds of evidence behind it, and they are not equal.
`0x4002`→slot 1 and `0x4006`→slot 4 are **proven by control flow**: `ReverbPreset_Load` writes
tag `0x63` and then notifies `0x4002`; `EQPreset_Load` writes tag `0x64` and then notifies
`0x4006`. `0x4004`→slot 2 and `0x4140`→slot 3 rest on **co-restoration**: one bit of
`BitMapOut_RestoreExtra_*`'s filter mask restores `0xFC6F` bit `0x40` together with the whole
tag-`0x65` record, another restores tag `0x43` together with the whole tag-`0x66` record. That
is a strong grouping — the routine restores nothing else under those bits — but it is
[INFERENCE], not a call graph.

---

## 2. Tag `0x43` — IDENTIFIED (the reading of it is [INFERENCE])

Three parameters, all on one 9-cell screen (`0x00E34750` =
`4141 · · 4140 4E00 4E10 4E11 4E12 4E13`) beside slot 3's algorithm and its four values:

    +0 bit 7   0x4140  on/off  (also slot 3's enable)
    +1 mask 7F 0x4141  a 0..127 level, drawn with "%3d"
    +1 bit 7   0x4142  a second on/off

Slot 3's four algorithms are ROOM / KARAOKE / BATH ROOM / STAGE, and the KN5000's page-title
list holds exactly one title of that shape: **`MIC LEVEL & REVERB`** (`0x00ED128C`). So tag
`0x43` is the microphone record and tag `0x66` its reverb.

⚠ Graded **[INFERENCE]** on the word "microphone". The screen–record binding, the field shapes
and the algorithm names are all proven; what is not proven is the title binding — no routine
reaches from this screen to that string, and `VOCALIST` (`0x00ED13DC`) is the other page in
that family. The four ambience names plus "a level and a reverb" is what carries it.

---

## 3. Tag `0x9A` — the old claim is HALF WRONG

> ~~`0x9A` is touched by nothing but the generic init walk.~~

**Wrong half.** It has a live subscriber, and that subscriber is written specifically for it:
it accepts payload offsets **4..19 only**, maps each through the RAM byte array at `0x00F1A0`,
then through the ROM class table at `0x00EE8EA2`, and forwards only when the class is 0, 1
or 2. Sixteen of the record's twenty-six bytes are live UI fields.

And the split is exact: the schema's field descriptors for `0x9A` declare offsets
**0..3 and 20..25** — precisely the ten bytes the subscriber refuses. Descriptors and handler
tile the 26-byte record with no gap and no overlap. That is not what an abandoned record looks
like.

**Right half.** No instruction anywhere names it. Across v7, v9, v10, the table-data ROM, the
v142 sub-program and the sub-CPU boot ROM the F1/F2 direct-address census returns 1, 1, 1, 2,
1 and 0 candidates in `0x9A`; every one but a single named exception is the four bytes
`.. f1 b0 ff`, the tail of `cp XBC,XWA` + `ret NC` inside a busy-wait loop, i.e. not an
instruction start. The exception is table-data interrupt vector #21 (`0x00FFB7F2`), a handler
address in the pre-remap map where `0x00FFxxxx` is boot ROM and not panel DRAM. No parameter-id
descriptor names tag `0x9A` either, while 14 other tags do.

**The census could have found one.** Same scan, same run: the neighbouring tags `0x78`, `0x48`
and `0x80` collect 267 (v7) / 268 (v9, v10) candidates.

⚠ Two limits, stated rather than smoothed over.

* The positive control is weak *outside* the program ROM — the table-data ROM yields 0 control
  hits and the sub-program 1, so "absent from the sub CPU" rests on a scan with almost nothing
  to calibrate against there.
* Absolute addressing is not the only way in. The generic tag→address table at `0x00EDAE64`
  holds `0xFFA4` at index `0x9A`, so the parameter machinery can reach the record through a
  computed pointer, exactly as the C0..D4 family is. **"No instruction names it" is the claim;
  "no code can touch it" is not.**

**Who writes it is NOT settled.** Of the 131 `AssswbWr` / `AddswbWr` / `SwbtWr_QueuePostEvent`
call sites in the v9 sources, 56 carry a literal tag in `WA` within ten lines — `00 04 44 48 61
63 64 70 90 91 93 98 A8 B0` — and none is `0x9A`; the other 75 pass the tag in a register. A
search that cannot see a register-borne tag cannot rule one out.

---

## 4. Tag `0x68` — declared, saved, and ignored

Its field-descriptor list is the bare terminator — no fields at all. No parameter id names it.
Its only absolute access is the bulk copy in `BitMapOut_CopyAuxTable_Loop`. Its UI subscriber
(v7 `0x00FEA406`, v9/v10 `0x00FEABD5`) is four `ret` bytes, `0E 0E 0E 0E`. Ten bytes the
firmware saves, restores and never interprets. T8 asserts all three, and it locates the
tag→subscriber table from the `0x9A` handler rather than hardcoding it, so it would fail if
`0x68` ever acquired a real one.

---

## 5. What could NOT be resolved

**Tag `0x71`** — two payload bytes, `+0` masked `0x03` (four values). Reached by
`PmemOutLGridCheck` (the panel-memory grid, four sites) and `BitMapOut_Snapshot_PostProcess`.
No parameter-id descriptor, no routine that distinguishes it. Its subscriber list is
`UIStateEvt_MuteToggle_Data+0x2a` and the generic key-scan dispatcher — a suggestive name, but
an auto-generated one, and a name is not evidence.

**Tags `0x44` / `0x45` / `0x46`** — NOT identified. What *is* established:

* ~~none of the three carries a parameter-id descriptor, so they are not UI-editable;~~
  ⚠ **REFUTED 2026-08-22.** All three DO carry parameter-id descriptors -- 48 of them, at
  `0x8200/0x8600/0x8A00`. This scan only looked at `0x4000..0x4FFF (⚠ **WINDOW CORRECTED 2026-08-23**: over the WHOLE id space this yields 456 entries over 44 tags, not 39 over 14. The window was the problem, not the method — and contiguity alone is insufficient, uniqueness is needed too)`. They are the DRAWBAR
  registration and they ARE UI-editable, from the `DRAWBAR SETTING` page. The inference
  "no descriptor found -> not UI-editable" turned a search limit into a property of the data;
* their event subscriber lists are identical;
* in all seven floppies all three are constant across every block and every disk, with `0x44`
  and `0x45` **byte-identical** (`00 00 00 88 80 80 00 00 00 00`) and `0x46` differing at
  **`+3`** -- LEFT's 16' drawbar, 8 -> 0. (Corrected 2026-08-22: this said "one bit" at a later
  byte. The differing byte is `+3`, and it is the first of the nine footages.);
* `FDemoText_SyncPreset_DirectCopy` copies the byte at `0xFC74` (tag `0x61` +0, the DSP-EFFECT
  algorithm) into `0xFC26` (tag `0x44` +0), and `FDemoText_UpdateVoiceDisplay` then compares
  the two and re-posts a tag-`0x61` event when they differ. So **`0x44` +0 is a shadow of the
  DSP-effect algorithm number**, at least on the feature-demo path.

No equivalent pairing was found for `0x45` or `0x46`. Nor is there any sign of the three being
indexed as a group: the whole-ROM direct-address census returns two references to `0x44`
(`FDemoText_SyncPreset_DirectCopy` and the panel-memory restore) and exactly one each to `0x45`
and `0x46`, and those three restore sites are byte-identical clones —

    fb6614  f1 26 fc 33 ...  88 2c 23    lda XHL,0xfc26 ... ld C,(XWA+0x2c)
    fb6684  f1 32 fc 33 ...  88 34 23    lda XHL,0xfc32 ... ld C,(XWA+0x34)
    fb66f4  f1 3e fc 33 ...  88 3c 23    lda XHL,0xfc3e ... ld C,(XWA+0x3c)

— i.e. three constant addresses written out longhand, with constant displacements, not a
`base + 12*i` computation. (Note the source buffer steps by 8 where the panel records step by
12, so the saved image is packed differently from the live area.) "Three identical records must
be three of something" remains a hypothesis with no ROM artefact behind it, and this note does
not adopt one.

---

## Method notes worth keeping

* **The parameter-id descriptor table is the general tool this pass found.** An entry is
  `u32 param-id | u8 tag | u8 offset | u16 mask | u8 max | u8 shift | ...`, and scanning the
  whole image for ids in `0x4000..0x4FFF` whose `(tag, offset)` lands inside the panel schema
  and whose mask is one contiguous run of bits yields 39 ids over 14 tags with no hand-tuning.
  The contiguity rule earns its place: without it the scan invents `0x4A00 -> tag 0x68 +5
  mask 0x46`, and `0x46` is not a field. It converts "which record is this UI cell?"
  into a table lookup, and it is how tag `0x43` and the slot switches fell out.
* **`f1` is a common byte.** Every spurious hit in the `0x9A` census is `f1` sitting inside
  `cp XBC,XWA` (`e8 f1`) or `cp WA,imm` (`d8 f1`). Always print the preceding byte.
* **A negative rule is wider than a menu.** Slot 0's arm says "not a reverb", not "one of the
  38 DSP effects". Reading a validator as an enumeration would have made slot 0 look like it
  offered 47 types.
