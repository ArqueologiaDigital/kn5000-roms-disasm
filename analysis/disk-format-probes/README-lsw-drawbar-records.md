# `.LSW` tags `0x44` / `0x45` / `0x46` are the DRAWBAR registrations — and what `0x71` is not

Run:

```
python3 analysis/disk-format-probes/lsw_drawbar_records.py
python3 analysis/disk-format-probes/lsw_drawbar_records.py --quiet
python3 analysis/disk-format-probes/lsw_drawbar_records.py --lsw-dir /tmp/disk
```

Corpus for `--lsw-dir`: unzip `~/compartilhado/KN7000/floppy-archive/*.zip`, each holds one
22,528-byte `.LSW`. Exits non-zero on failure. Runs every test on **v7, v9 and v10**.

## The question

`README-lsw-nonpart-records.md` and `README-lsw-leftover-records.md` closed with:

> `0x44` / `0x45` / `0x46` — three identical records; that they are a *set of three* is the only
> structural fact. What the set is, is unknown. … nothing was found that indexes the three as a
> group. The 12-byte stride `0xFC24`/`0xFC30`/`0xFC3C` is an invitation, not evidence.

and

> `0x71` — two payload bytes, `+0` masked `0x03`. Reached by `PmemOutLGridCheck` and a snapshot
> routine; no parameter id, no naming routine.

## Why the earlier pass missed it — one number

`lsw_leftover_records.py` scans for parameter-id descriptors **restricted to ids `0x4000..0x4FFF`**.
The three records have 48 parameter ids between them, all in `0x8200` / `0x8600` / `0x8A00`. Widen
the scan to the whole id space and the answer falls out immediately. The lesson is small and
reusable: *a namespace filter chosen to suppress false positives also suppresses the answer.*

## Result — one DRAWBAR (organ) registration per keyboard part

    tag 0x44 -> part 0 = RIGHT 1
    tag 0x45 -> part 1 = RIGHT 2
    tag 0x46 -> part 2 = LEFT

All three carry the **same sixteen fields**; the ids differ by exactly `0x0400` per part.

| payload | mask | id 0x44 / 0x45 / 0x46 | max | what it is |
|---|---|---|---|---|
| `+0` | — | *(no id)* | — | a shadow of tag `0x61 +0`, the DSP-EFFECT algorithm number |
| `+1` | `0x0F` | `82CC` `86CC` `8ACC` | 15 | |
| `+1` | `0xF0` | `82CB` `86CB` `8ACB` | 15 | |
| `+2` | `0x0F` | `8293` `8693` `8A93` | 15 | |
| `+2` | `0xF0` | `8294` `8694` `8A94` | 15 | |
| `+3` | `0x0F` | `8280` `8680` `8A80` | 8 | **DRAWBAR 16'** |
| `+3` | `0xF0` | `8281` `8681` `8A81` | 8 | **DRAWBAR 8'** |
| `+4` | `0x0F` | `8282` `8682` `8A82` | 8 | **DRAWBAR 5 1/3'** |
| `+4` | `0xF0` | `8283` `8683` `8A83` | 8 | **DRAWBAR 4'** |
| `+5` | `0x0F` | `8284` `8684` `8A84` | 8 | **DRAWBAR 2 2/3'** |
| `+5` | `0xF0` | `8285` `8685` `8A85` | 8 | **DRAWBAR 2'** |
| `+6` | `0x0F` | `8286` `8686` `8A86` | 8 | **DRAWBAR 1 3/5'** |
| `+6` | `0xF0` | `8287` `8687` `8A87` | 8 | **DRAWBAR 1 1/3'** |
| `+7` | `0x0F` | `8288` `8688` `8A88` | 8 | **DRAWBAR 1'** |
| `+7` | `0x10` | `82C0` `86C0` `8AC0` | 1 | a switch |
| `+7` | `0x20` | `82C1` `86C1` `8AC1` | 1 | a switch |
| `+8` | `0x0F` | `8221` `8621` `8A21` | 1 | a switch |
| `+9` | — | *(no id)* | — | declared by the schema as a plain byte |

Descriptor addresses (identical in v7/v9/v10): tag `0x44` at `0xEDC946`..`0xEDCA6A`, tag `0x45` at
`0xEDCBAE`..`0xEDCCBC`, tag `0x46` at `0xEDCE00`..`0xEDCF0E`. Each entry is
`u32 id | u8 tag | u8 offset | u16 mask | u8 max | u8 shift | …`, 18-byte stride.

### The evidence, graded

**[CODE] The three are indexed as a group, `0x44 + part`.** `FDemoText_SendVoiceParams`
(v9 `0x00F84CBF`, v7 `0x00F848BB` — same prologue, verified with unidasm) does, at v9 `0x00F84D42`:

```
    f84d3f  ld A,(XSP+0x0c)        ; the part index, from GetPartSelect = byte (0x8D3A)
    f84d42  add A,0x44             ; <- the group index the earlier pass looked for
    f84d45  extz WA
    f84d47  calr 0xf84700          ; tag -> payload address, u32[0x00EDAE64 + 4*tag]
    f84d4a  ld (XSP+0x02),XHL
    f84d4d  ld XWA,3               ; ptr = payload + 3
    f84d52  ld QIZH,4              ; sub-CPU parameter index 4
```

then sends payload `+3..+7` to the Sub CPU as parameters 4..8 (`sendCOMM`, packet
`88 <part> <index> 00 <value> 00`), and payload `+1..+2` of **tag 0x44 only** as parameters
`0x0B`/`0x0C`. The bound on `part` is arithmetic, not assumed: `u32[0x00EDAE64 + 4*tag]` reads
`0xFC26 / 0xFC32 / 0xFC3E` for `0x44/0x45/0x46` and `0xFFFFFFFF` for `0x4A..0x5F`, so a part index
of 3 or more would resolve to nothing.

**[CODE] The trio's private UI subscriber agrees with the parameter ids, to the bit.** The
subscriber table (located from the tag-`0x9A` handler exactly as in `lsw_leftover_records.py` T8)
gives `0x44/0x45/0x46` one handler — v9 `0x00F8476E`, v7 `0x00F8436A` — that belongs to those three
tags and to no other. Its body opens `ld E,(<tag global>) / sub E,0x44` (the group index again),
bounds the payload offset to **1..7**, and splits offset 7 on `mask & 0x0F` versus `mask & 0x30`.
The parameter ids independently say: offsets 1..8 are fields, and `+7` is `0x0F` + `0x10` + `0x20`.
Two tables written for different purposes, agreeing on the same partition.

**[CODE] The screen.** The 15-entry `u16` table at `0xE9F88C` is read by `MainMemDrawControl`
(`v9/maincpu/ui/drawbar_panel_ui.s`), which splits its items at `cp wa,0x8 / jr ule`. It reads

```
    8280 8282 8281 8283 8284 8285 8286 8287 8288 | 82C1 82C0 82CC 82CB 8293 8294
```

— the nine `max=8` ids first, then the six others.

**[CODE] The label.** `DRAWBAR SETTING` at `0xE841E0` (and `0xE841F0`), `DRAWBAR EDIT` at
`0xE846D6`, `DRAWBAR` at `0xE84602`, and at `0xE84266` the footage row itself:

```
    16' 5  ' 8'  4' 2  ' 2' 1  '1  ' 1'
```

with the fraction numerators/denominators drawn from separate strings at `0xE842AA` (`1/3`),
`0xE842CE` (`2/3`), `0xE842F2` (`3/5`) and `0xE84316` (`1/3`) — i.e. `16' 5 1/3' 8' 4' 2 2/3' 2'
1 3/5' 1 1/3' 1'`, the nine footages in the screen table's order. The page's other strings are
`PERCUSSIVE`, `DECAY :`, `LEVEL :`, `ATTACK TIME  :`, `RELEASE TIME :`, `SLOW`, `FAST`, `TREMOLO`
(`0xE8411E`..`0xE8458E`) — six controls for the six non-drawbar ids.

**[CODE] Which three parts.** A descending 8-byte-stride part-name table at `0xE9F374` reads
`RIGHT1` / `RIGHT2` / `LEFT  ` at indices 0/1/2 (`PART 4`, `PART 5`, … follow). A second, packed
block counts down the same way: `0xE95540` ` RIGHT 1 `, `0xE95536` ` RIGHT 2 `, `0xE9552A`
`   LEFT   `. Descending tables are this ROM's convention — the effect-name table that
`lsw_leftover_records.py` uses is `BASE - 18n`.

**[CODE] The firmware's own default image.** `0xEDB3FC` holds a complete power-on default of panel
block 0 as a TLV stream in schema order — 45 records, ending `0xEDB7BA`. (The reverb and EQ preset
blobs at `0xEDB36C`/`0xEDB394` that `docs/kn-disk-file-formats.md` already records sit just before
it.) Its `0x44`/`0x45`/`0x46` all read `00 00 00 88 80 80 00 00 00 00`, which decodes to a real
organ registration:

```
    16'=8  5 1/3'=0  8'=8  4'=8  2 2/3'=0  2'=8  1 3/5'=0  1 1/3'=0  1'=0
```

**[CODE] Corpus.** 175 records per tag over the seven floppies. `0x44` and `0x45` are **byte-
identical to that firmware default**; `0x46` (LEFT) differs at payload `+3` only — its 16' drawbar
reads 0 where the default reads 8. Every drawbar value is in 0..8.

⚠ **Stated limit.** Only three distinct byte values occur anywhere in the corpus (`00`, `80`, `88`),
so the corpus gate can catch a gross misreading but **not** an off-by-one in the nibble order.
What pins the nibble order is the parameter-descriptor table (each id carries its own mask *and*
shift), not the corpus.

⚠ **A curated name that misleads.** The handler lives in `v9/maincpu/demo/fdemotext_routines.s` and
every routine there is called `FDemoText_*`. That name is an artefact of the string block it sits
next to (`Start the internal DEMO`, `FEATURE PRESENTATION`) — the module has nothing to do with the
demo. Cite `0x00F8476E`, not the label.

## Tag `0x71` — NOT identified. Here is exactly how far it goes

**Proven:**

* **No parameter descriptor anywhere in the image names tag `0x71`** — a whole-id-space scan, the
  same one that finds 48 descriptors for `0x44/0x45/0x46`. The search is shown capable of finding
  one.
* **Its only tag-specific UI subscriber is a bare `ret`** — a single `0x0E` byte (v9/v10
  `0x00FDE9AD`, v7 `0x00FDE1DC`), which is the last byte of `UIStateEvt_MuteToggle_Data`. A no-op
  placeholder, like tag `0x68`'s.
* **A whole-image census of TLCS-900 direct addressing** (`F1 lo hi`, `F2 lo hi 00`) landing in
  `0xFD2A..0xFD2D` finds **six** candidates in every version — five real and one mid-instruction
  false positive (context bytes `30 bf 14 60`, i.e. `jr F` + `ld WA,0x14af`; v7 `0x00F785C1`,
  v9/v10 `0x00F789C5`):

  | v9 address | site |
  |---|---|
  | `0x00F78A75`, `0x00F78B44`, `0x00F78C41` | three arms of `PmemOutLGridCheck`, each `lda XDE,0xFD2C / sub XDE,0xF9A0` |
  | `0x00FB4631` | `bit 1,(0xFD2C)` in `BitMapOut_Snapshot_PostProcess` |
  | `0x00FB4AF6` | `lda XBC,0xFD2C`, the `BitMapOut_CopyAuxTable_Check` bulk restore |

  **Every real site touches BIT 1** — one sets it, one clears it, one tests it, one gates on it.
  Bit 0 of the schema's `mask 0x03` is touched by nothing in v7, v9 or v10.
* **The bit is rendered as ON/OFF.** The third grid arm does
  `bit 1,(0x1ED400 + index*0x3C0 + 0x38C) / jr Z` and picks between `0xE8013E` `" ON  "` and
  `0xE80144` `" OFF "`. `0x38C` is `0xFD2C - 0xF9A0`, so the byte it reads is tag `0x71` payload+0
  inside a **960-byte-strided array at `0x1ED400`**, not the live panel. The same string block holds
  `" LEFT  "`, `"RIGHT 2"`, `"RIGHT 1"` at `0xE800F6`/`FE`/`0xE80106`.
* **What the bit gates.** `bit 1,(0xFD2C)` in `BitMapOut_Snapshot_PostProcess` — itself gated on
  tag `0x80 +0` bit 4 being clear — enables `BitMapOut_DispatchIOChanges`, which re-posts payload
  `+14`/`+15`/`+17` of parts `0x00`/`0x01`/`0x02`: the same three parts the drawbar records belong
  to.
* **A schema inconsistency worth recording.** The field-descriptor list at `0xED8DFE` declares
  offsets 0, 1, 2, 3, while the record's length byte says the payload is **2** bytes. It
  over-declares by two. The disk `.LSW` files carry **four** payload bytes for tag `0x71` — which is
  what the descriptor list, not the length byte, describes. That is one more datum for the
  "same format, later revision" reading in `docs/kn-disk-file-formats.md`.
* ROM default: `00 00`. Corpus: `00 00 00 00` in all 175 records on all seven disks.

**Not determined:** what the bit is called on the instrument, and what bit 0 is for.

**What would settle it**, in order of cheapness:

1. Real hardware. The KN5000's PANEL MEMORY page draws exactly one ON/OFF cell through
   `AcPmemOutLGridBox` / `PmemOutLGridCheck` — original Matsushita symbols, in the ROM's own symbol
   blob at `0xE55638`/`0xE5564A`, beside `PmemOutRight`, `PmemOutLeft`, `TtMdPmemOut`, `PmemModeBox`,
   `oldpmemmode`, `newpmemmode`. Toggle that cell and re-read
   `0x1ED400 + n*0x3C0 + 0x38C` bit 1.
2. The KN7000 firmware, whose widget labels are plain ASCII (`SD_LD2_LBLSW` -> `CURRENT PANEL` was
   recovered that way).
3. Identify the `0x1ED400` array (960-byte stride) and its element count; `0x1E7800` is already
   known to be the second half of what the KN5000's own `.LSW` writer emits.

## Anything the earlier notes should be corrected on

* `README-lsw-leftover-records.md` records the corpus `0x46` as `... 80 80 80 ...` differing from
  `0x44`/`0x45` "in one bit". Measured here: `0x44` = `0x45` = `00 00 00 88 80 80 00 00 00 00` and
  `0x46` = `00 00 00 80 80 80 00 00 00 00`. The difference is at payload **`+3`**, and it is the
  16' drawbar of the LEFT part.
* The same note's "`0x44/0x45/0x46` … carry no parameter-id descriptor, so they are not
  UI-editable" is **wrong**: they carry 48, and they are edited from the DRAWBAR page.

---

## Provenance note (2026-08-22)

`lsw_drawbar_records.py` and this README were committed in **`116f5a2`**, whose message reads
"Blog draft: the .LSW retraction and the case-sensitive search behind it". That message describes
a different piece of work. The files are intact and unmodified; only the commit they rode in on is
wrong.

Cause, recorded because it will recur with concurrent agents: this probe's author staged its files
with `git add`, and a parallel session then ran `git commit` **without a pathspec**. `git commit`
commits the whole INDEX, not just the paths the committer happened to add in the same command, so
the staged-but-unrelated files were swept in.

The fix when it matters is `git commit -- <paths>`, or checking `git diff --cached --name-only`
before committing. History was NOT rewritten to repair this: an earlier `--amend` in the same
session clobbered a concurrent commit, and a wrong subject line is much cheaper than that.

The addendum lives in its own commit, `cb07b94`.
