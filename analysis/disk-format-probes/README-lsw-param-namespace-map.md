# The panel parameter-id space is a LAW: `id = 0x8000 + 0x400*tag + field`

Companion note to `analysis/disk-format-probes/lsw_param_namespace_map.py`.

```
python3 analysis/disk-format-probes/lsw_param_namespace_map.py
python3 analysis/disk-format-probes/lsw_param_namespace_map.py --quiet     # just the gate
python3 analysis/disk-format-probes/lsw_param_namespace_map.py --dump      # the census
```

ROM only, no corpus needed. It exits non-zero if any of the eight tests stops holding, on v7,
v9 **and** v10 — the census it builds is identical in all three.

## Why redo a scan that was already done

`README-lsw-leftover-records.md` calls the parameter-descriptor table "the general tool this
pass found", and scans ids `0x4000..0x4FFF`. That window had already cost one wrong conclusion:
tags `0x44/0x45/0x46` were written down as *"none of the three carries a parameter-id
descriptor, so they are not UI-editable"* — and their 48 ids turned out to sit at
`0x8200/0x8600/0x8A00`, outside the window. `README-lsw-drawbar-records.md` retracted it with
the note that *"the inference 'no descriptor found → not UI-editable' turned a search limit into
a property of the data"*.

This probe scans **the whole id space**, `0x0001..0xFFFF`, and freezes what comes out.

### The filter, and why it needs two rules rather than one

A descriptor is 18 bytes: `u32 param-id | u8 tag | u8 offset | u16 mask | …`. A candidate is
kept only if the id is `0x0001..0xFFFF`, the tag is a schema tag, the offset is inside that
record's payload, the mask is one contiguous run of bits in `0x01..0xFF`, **and**

* another valid candidate sits exactly `0x12` bytes before or after it — it is part of a run,
  which is what a table looks like and a lucky stretch of code does not; **and**
* the id occurs exactly once in the whole census — a parameter id names one field.

Both rules earn their place, and the second one is the new part:

* without the run rule the census invents `0x8D4E → tag 0x68 +0 mask 0x40` at `0xFB6C4B`, four
  random bytes inside an instruction, which would have "refuted" the tag-`0x68` finding;
* without the uniqueness rule it swallows two data tables that decode as descriptors by
  accident — `0xF800 → tag 0x00 +0 mask 0xF8` at **twenty** addresses in `0xE86A..0xE8A0`, and
  `0x0031 → tag 0x63 +0 mask 0x01` at **thirteen** addresses in `0xEE50..0xEE58` — and the law
  below acquires five spurious exceptions (tags `0x00 0x03 0x08 0x0C 0x0D`).

---

## 1. The part namespace law — PROVEN

For every one of the 25 per-part records, tag `T` in `0x00..0x18`, all the parameter ids that
name it fall in one namespace, and it is

    namespace(T) = 0x8000 + 0x400 * T

`0x00`→`0x80xx`, `0x01`→`0x84xx`, `0x02`→`0x88xx`, … `0x18`→`0xE0xx`. No exception, no gap, no
sharing. And the law is finer than the namespace: **every part carries the same ten field
constants**

    id = 0x8000 + 0x400*T + k,     k ∈ { 07, 08, 0A, 20, 40, 5B, 5D, 5E, 80, 81 }

with parts `0x01`, `0x02` and `0x03` carrying an eleventh, `k = 0x00`. So an id anywhere in
`0x8000..0xE3FF` **decodes on sight**: `(id - 0x8000) >> 10` is the part tag and `id & 0x3FF`
is which of its fields. That is a tool for the next pass, not just a fact: any UI screen table
that names such an id immediately says which part and which parameter it is editing.

## 2. The drawbar records are parts 0, 1 and 2 — arithmetically — PROVEN

    tag 0x44 -> 0x8200 = namespace(part 0x00) + 0x200
    tag 0x45 -> 0x8600 = namespace(part 0x01) + 0x200
    tag 0x46 -> 0x8A00 = namespace(part 0x02) + 0x200

16 ids each, 48 in all, and **exactly three non-part tags hold a namespace inside the part id
block `0x8000..0xE3FF` — these three.** (Tag `0x98` has a stray `0xE807`/`0xE808` pair at
`0xEDE96C`/`0xEDE97E`, above the block, so it does not clash.)

`README-lsw-drawbar-records.md` identified the trio as the drawbar registration of RIGHT 1 /
RIGHT 2 / LEFT and assigned the three parts from the *count* of records — "the set of three WAS
the clue — three parts". The namespace arithmetic reaches the same assignment without counting
anything: each record is a `+0x200` sub-namespace of one specific part's id block, and the
parts are 0, 1 and 2. Two derivations, no shared step.

The three records' `(k, offset, mask)` triples are **identical**, which is the strongest form
the old "three identical records" observation has taken:

| offset | fields |
|---|---|
| `+0` | none |
| `+1` | `k=CC` mask `0x0F`, `k=CB` mask `0xF0` |
| `+2` | `k=93` mask `0x0F`, `k=94` mask `0xF0` |
| `+3` | `k=80` mask `0x0F`, `k=81` mask `0xF0` |
| `+4` | `k=82` mask `0x0F`, `k=83` mask `0xF0` |
| `+5` | `k=84` mask `0x0F`, `k=85` mask `0xF0` |
| `+6` | `k=86` mask `0x0F`, `k=87` mask `0xF0` |
| `+7` | `k=88` mask `0x0F`, `k=C0` mask `0x10`, `k=C1` mask `0x20` |
| `+8` | `k=21` mask `0x0F` |
| `+9` | none |

i.e. **thirteen 4-bit values and two 1-bit flags**, packed two per byte. The drawbar note's
observation that `0x46` differs from `0x44`/`0x45` at `+3` — "LEFT's 16' drawbar, 8 → 0" — is
the low nibble of `+3`, `k = 0x80`, which is the *first* `k` of the run `80 81 82 83 84 85 86
87 88`: nine consecutive constants for nine consecutive nibbles. **[INFERENCE]** that those
nine are the nine footages — but it is the reading the id numbering itself suggests, and the
falsifier is cheap: move one drawbar on real hardware and see which nibble changes.

## 3. Tag `0x9A` — the negative survives the full window — PROVEN

`README-lsw-leftover-records.md` §3 said "no parameter-id descriptor names tag `0x9A`, while 14
other tags do", measured inside `0x4000..0x4FFF`. Over `0x0001..0xFFFF` it still holds, and the
census is demonstrably not blind: its neighbours in TLV block 1 collect **15** (`0x92`), **27**
(`0x99`) and **29** (`0x98`) ids in the same run of the same scan. The probe asserts those
three counts *as positive controls*, so a change that silenced the census would fail the test
rather than pass it.

This is the "state your window" upgrade the earlier notes asked for: the tag-`0x9A` negative is
no longer a statement about `0x4000..0x4FFF`.

The full list of schema tags with **no parameter id anywhere in the id space**:

    19  49  68  71  72  78  90  9A      and the whole C0..D4 D7 companion family

— consistent with everything already written about `0x68` (declared, saved, never interpreted),
`0x71` (no descriptor; reached only through the panel-memory grid) and the C-family (parked
above the notifiable range).

## 4. Tag `0x92` is a 15-parameter UI record — PROVEN (the shape; not the name)

`README-lsw-nonpart-records.md` has tag `0x92` as *"13 consecutive bytes read one at a time by
`SendEpilogue_Data`"* — shape only. It carries fifteen ids, `0x4280..0x428E`, whose
`(offset, mask)` pairs **tile all fourteen payload bytes with no gap and no overlap**:

    0x4281 -> +0x00 mask FF          0x4283..0x428E -> +0x02..+0x0D mask FF
    0x4280 -> +0x01 mask 80          0x4282        -> +0x01 mask 0F

So it is a full screen's worth of editable parameters, in namespace `0x42xx` — which tag `0x70`
also touches (`0x4201`) and tag `0x48` once (`0x4200`). **What the screen is, is still not
known**: no u32 screen table in the ROM lists `0x4281` or its neighbours (searched: every
4-byte-aligned occurrence of `0x00004281`, `0x00004283`, `0x00002880`, `0x00002884`,
`0x00002100`, `0x00008221` in `0xE00000..0xEF0000`, keeping any window of 13 consecutive u32
where ≥10 are `0`, `0xFFFFFFFF` or `0x100..0xFFFF`). The only tag whose ids *do* appear in such
a table is `0x47`, at `0xE7EE70` — the same shape as the tag-`0x43` screen at `0xE34750` that
`README-lsw-leftover-records.md` used. So the trick works; it just does not reach `0x42xx`.

---

## 5. The field constant `k` is the parameter's MIDI controller number (2026-10-06)

Section 1 left `k` as "which of its fields". The descriptors themselves (`audio/sndparam_records/run_*.c`,
`sndparam_types.h`: record = `bank_index`, byte = `bank_offset`, bits = `mask`) say which field each `k` edits, and
for the part fields that match a documented byte the match is the MIDI controller of that name (part 0x00 shown;
all 25 parts carry the same `(byte, mask)` per `k`, asserted by `scripts/renaming/gen_sndparam_desc_names.py`):

| `k` | MIDI controller | record byte, mask | independent basis |
|---|---|---|---|
| `0x00` | CC 0 Bank Select MSB | `+0`, `FF` | `+0` is the flat panel sound number (kn-disk-file-formats.md, "The voice selector's 168 options") |
| `0x20` | CC 32 Bank Select LSB | `+1`, `7F` | `+1` is its variation bank (same) |
| `0x07` | CC 7 Volume | `+3`, `7F` | |
| `0x0A` | CC 10 Pan | `+8`, `7F` | |
| `0x5B` | CC 91 Reverb send | `+7`, `7F` | |
| `0x5D` | CC 93 Chorus send | `+5`, `7F` | |
| `0x40` | CC 64 Sustain | `+4`, `08` | the panel SUSTAIN button's action addresses tag 0 (the current part) byte 4 bit 3 (`PanelActions_RightSeg3`, technics-docs control-panel-protocol.md) |
| `0x5E` | CC 94 (Celeste) | `+4`, `40` | DIGITAL EFFECT's action addresses byte 4 bit 6 (same list) |
| `0x01` | CC 1 Modulation | record `0xB2`, byte = part | a per-part live-controller array, not the part record |
| `0x0B` | CC 11 Expression | record `0xB3`, byte = part | same |

**[INFERENCE, with the evidence above]** The controller reading is not stated by the firmware; it is the one
reading under which the constants are not arbitrary: eight of them land on the very byte or bit the controller of
that number governs, and two of those are confirmed by the panel buttons that set them. `k = 0x08` (`+3`, `80`),
`0x78`, `0x80`-`0x82` and `0x1B0`/`0x1B2` are not named. The drawbar keys `0x280`-`0x288` of parts 0-2 are the nine
footages of section 2. `gen_sndparam_desc_names.py` names those descriptors `SndParam_Part<TT>_<Field>`.

## PROVEN vs INFERRED

**PROVEN:** the part namespace law and its ten field constants; that only the three drawbar
records intrude into the part id block, at `+0x200` of parts 0/1/2; that the three carry
identical `(k, offset, mask)` sets; that tag `0x9A` has no id over the full window while
`0x92`/`0x98`/`0x99` collect 15/29/27 in the same scan; that tag `0x92`'s fifteen ids tile its
fourteen payload bytes; the no-id tag list; and that all of it is identical in v7, v9 and v10.

**[INFERENCE]:** that the nine consecutive constants `0x80..0x88` on nibbles `+3 lo` … `+7 lo`
are the nine drawbar footages. Falsifier: move one drawbar on hardware and watch which nibble
of the record changes.

**NOT DETERMINED:** what screen edits tag `0x92`; the names of `0x91`, `0x93`, `0x98`, `0x99`;
anything at all about `0x9A`, `0x68`, `0x71`, `0x72`, `0x78`, `0x90`, which have no id to follow.

---

## Can it fail?

Checked:

* retag one drawbar descriptor's block (`0x8621` → `0x8E21`) → `T1: census differs`,
  `T3: drawbar tag 0x45 namespace ['0x86', '0x8e'], expected [0x86]`, `T3b: … != the common
  set`, and `census differs between revisions`;
* **give tag `0x9A` a descriptor** by changing the tag byte of id `0x4285` from `0x92` to
  `0x9A` → `T4: the no-id set is [… no 9A …], expected [… 9A …]`, `T4: the positive control for
  tag 0x9A is gone — tag 0x92 collects 14 ids, expected 15`, and `T5: tag 0x92 ids cover
  offsets [0,1,2,3,5,…], its payload is 14 bytes`. The tag-`0x9A` negative is a test, not a
  memory: if a descriptor for it ever appears, this probe says so.

---

## Corrections other files need (not applied here — this pass was told not to edit)

1. `README-lsw-leftover-records.md`, "Method notes worth keeping": *"scanning the whole image
   for ids in `0x4000..0x4FFF` … yields 39 ids over 14 tags with no hand-tuning"*. The window is
   the problem, not the method; over the whole id space it is **456 entries over 44 tags**, and
   the contiguity rule alone is not enough — uniqueness is needed too.
2. Same file, §3: *"no parameter-id descriptor names tag `0x9A` either, while 14 other tags
   do"* — still true, and can now cite a full-window search instead of `0x4000..0x4FFF`.
3. Same file, §5: *"`0x44`/`0x45`/`0x46` … 'Three identical records must be three of something'
   remains a hypothesis with no ROM artefact behind it"*. There is one now: their id blocks are
   `+0x200` of parts 0, 1 and 2.
4. `README-lsw-nonpart-records.md`, tag `0x92` row (*"13 consecutive bytes read one at a time by
   `SendEpilogue_Data`"*): it is a 15-parameter UI record and the ids tile all fourteen bytes.
5. `README-lsw-drawbar-records.md`: the part assignment can cite the namespace arithmetic, and
   the field table above supersedes "nine footages" as a description of the record's layout.
