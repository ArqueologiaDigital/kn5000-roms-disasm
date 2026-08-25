# prom_b 0xF0EA9F-0xF13D33, and five rules that stopped data being called code

Round 5 of the prom_b lane, 2026-08-25. The byte gate
(`python3 scripts/analysis/assert_byte_identical.py`) passes.

**25,113 substantive bytes** converted, all of it real content — this block has
no `.fill` at all. Two spans: **21,141 bytes** at 0xF0EA9F-0xF13D33 (§1-§3, of
which 13,357 **bytes** are code — **5,067 instructions**, 2.64 bytes each; see
the ⚠ below) and **3,972 bytes** of DSP-effect text
tables at 0xF147AC and 0xF15024 (§4b). prom_b substantive coverage
167,680 → **192,793** (32.0% → 36.8%); re-run
`python3 scripts/analysis/source_coverage.py` for the live figure.

This round's headline is not the byte count. It is that **round 4's boundary
method, applied unchanged to the next module, produces false code — and that is
now measured rather than suspected.** Five separate decisions had to be added or
switched off, each with its own null, and one of them retro-corrects 76 bytes
already in `prom_b/wsa1_prom_b.s`.

⚠ **CORRECTED 2026-08-25 (round-2 audit, finding F2).** This paragraph and the
banner in `prom_b/wsa1_prom_b.s` both read *"13,357 are decoded instructions"*.
13,357 is the **byte** total of the 21 code segments — it is the figure in the
`bytes` column of §5's own LAYOUT table, which sums to 21,141 — and nothing in
the tree had computed an instruction count at all. The count is now measured:

    python3 notes/prom_b_instr_census.py --module f0ea9f --last

decodes every code segment with the same decoder the layout used, and checks the
decoded instruction starts against this file's own `; ADDR` comments — **0
decoded starts with no source line, 0 source lines that are not a start**, and it
prints the LAST code segment (0xF1173E+3432, 1,344 instructions, last one
0xF124A5) so "the check passed" cannot mean "the check stopped early".
**13,357 bytes, 5,067 instructions, 2.64 bytes per instruction.**
The audit's own hand count of 4,675 is a floor rather than the number: it
classified every `.byte`-emitted line as data, and an instruction llvm-mc cannot
encode is emitted exactly that way (`.byte 0xEE, 0x0C, 0xF8, 0xFF ; F0EA9F  link
XIZ,0xfff8` is one instruction, not four data bytes). 392 of this block's
instructions are of that kind.

---

## 1. Why this span

`notes/prom_b_module_frontier.py` ranks whole thunk RUNS by the contiguous
unconverted extent of their targets. Its top run was

| run | slots | extent | targets |
|---|---:|---:|---|
| `T_F42F40-T_F42F6C` | 12 | 13,084 | 0xF0F018-0xF12334 |

and `T_F434A0-T_F434A4` (2 slots, 0xF11C30 / 0xF1220B) points into the same
span. The block's low end is not a guess either: `0xF0EA9F` is the target of
`calr 0xf0ea9f` at `0xF0EA97`, an instruction **already in the .s** — the
field-blink engine's last routine calls straight into it.

---

## 2. The five corrections, each with the measurement that forced it

Round 4 (`notes/FINDINGS-prom_b-f65000-modules.md`) framed a module with five
content rules calibrated against **proven code**, then filled in the rest with a
recursive descent whose seeds included every pointer-table entry and every 32-bit
immediate an instruction loads, and promoted leftover runs whose linear decode
was "self-consistent". Every one of those decisions fails here, and each failure
is visible as *specific wrong instructions*, not as a worry.

### 2.1 The consumer rule — a pointer table is not automatically a dispatch table

At `0xF10607`-`0xF1061D` the firmware does

```
0xF10607   ld A,0x04
0xF10609   mul WA,(0x2796)
0xF1060D   extz XWA
0xF1060F   add XWA,0x00f12f24        ; &Table128[(0x2796)]
0xF10615   ld XWA,(XWA)              ; fetch the entry
0xF10617   add XWA,XBC
0xF10619   ld H,(XWA)                ; READ A BYTE THROUGH IT
0xF1061B   cp H,0xff                 ; 0xFF == absent
```

`0xF12F24` is a table of **data** pointers. So is `0xF13674`: `add XBC,0x00f13674` at `0xF113FC`, `ld XBC,(XBC)` at
`0xF11402`, and `ld A,(XBC)` at `0xF1141B`. Only `0xF131E4` is transferred to:

```
0xF10700   add XBC,0x00f131e4
0xF10706   ld XBC,(XBC)
0xF10708   lda XIY,0xf10710
0xF1070D   push XIY
0xF1070E   jp T,XBC                  ; TRANSFERS to the entry
```

Round 4's `table_entry_seeds()` seeds the code walk from **every** table, so the
4-byte records at `0xF124EC-0xF12EE4` — `00 00 ff ff / 01 01 01 00 /
19 01 02 01` — were decoded as instructions, including **nine one-byte
"routines"** whose single byte is `0x07`.

The rule: walk forward from each indexer and take the first of a register
control-transfer (**TRANSFER**, entries seed the walk) or an 8/16-bit load
through a register (**DEREF**, entries do not). A table with no decodable
indexer is **UNKNOWN** and does not seed either.

    python3 notes/gen_prom_b_f0ea9f_module.py --tables

### 2.2 STRIDED — an arithmetic progression is an array, not a handler set

`0xF0EE6C` is 29 words stepping by exactly **72**, `0x00F0EEE0` to `0x00F0F6C0`.
Its first four targets are 4 × 72 bytes at `0xF0EEE0-0xF0EFFF` whose bytes are
`00 00 00 00 00 01 03 07 07 0f 0f 2f 0f 0f 07 07 03 01 00 ...` — symmetric
bitmap rows. The descent decoded them as `nop nop nop nop nop / normal / pop SR
/ reti`, and the run **ends in `reti`**, so even the tail rule of §2.4 admits it.
Only the table's shape rejects it.

**NULL:** over the 33 dispatch tables this tree has already proven — the 31 of
the 0xF65000 module plus the two display-list handler tables at `0xF31D21` (36
entries, the exact bound the interpreter checks) and `0xF31DB1` (16), 655 entries
in all — **zero** are strided.

    python3 notes/prom_b_f0ea9f_layout.py --null-stride

⚠ The rule is whole-table and has a minimum stride of 8 **because the null said
so**: one proven table (`0xF6AB92`) opens with four entries stepping by 1, which
is a run of one-byte handlers, not an array.

### 2.3 BYTEMAP — an ascending byte table, which the ASCII rule was calling text

`0xF133E4-0xF135F5` is six runs like `00 01 02 03 04 05 06 ff 07 08 09 0a ff ff
… ff 0b 0c 0d …`: index maps in which **0xFF means absent** — exactly what
§2.1's consumer compares against. The IDENT rule needs +1 exactly and sees only
the unbroken stretches, so the gaps between them were decoded as `nop / normal /
push SR / pop SR / max / halt / ei 0xff / reti`.

⚠ **And the ASCII rule was making it worse, not better.** `0xF13464` is
`00 01 02 03 04 05 06 08 09 0a 0b 20 21 22 … 63` — ascending **with jumps** — and
its tail is 36 consecutive printable bytes, so the 20-byte ASCII rule framed that
tail as a **string** and would have emitted
`.ascii " !\"#$%&'012345678@ABCDEFGHIJK\`abc"` under a `Text_` label. Six such
runs in this block are index tables and none of them is text. The ASCII rule's
null was measured over proven CODE, where it is genuinely zero; nobody had
measured it over an ascending byte table.

Rule: a maximal run of ≥ 16 bytes in which every byte is 0xFF or **strictly
greater** than the previous non-0xFF byte, with ≥ 12 non-0xFF values, trimmed of
trailing 0xFF, and painted **over** ASCII so no byte map gets a `Text_` name.

**NULL: zero** false positives over every maximal run of proven prom_b
instruction text (3,887 runs, 73,081 bytes at the time of writing), at (16, 12)
and also at (20, 14), (24, 16) and (16, 16).

### 2.4 The tail rule — and 76 bytes of the 0xF65000 module were wrong

Round 4 promoted an unreached run to code when its linear decode consumed the run
exactly, held no undefined opcode and landed every relative branch on a
boundary. That rule was calibrated against pointer tables, strings and `0x0E`
padding — never against **proven data**.

There is proven data available: the **4,011 display-list records** of
`notes/FINDINGS-ui-display-list.md`, 39,329 bytes whose framing is self-checking
(the interpreter advances by each record's own length byte and must land exactly
on the call site's end address). Chopped into record-**aligned** chunks and
offered to the rule:

| chunk ≥ | chunks | round-4 rule accepts | + must end in a flow end |
|---:|---:|---:|---:|
| 16 | 1,884 | **261 (13.9%)** | **1 (0.1%)** |
| 24 | 1,392 | 144 (10.3%) | 1 (0.1%) |
| 32 | 1,084 | 74 (6.8%) | **0** |
| 48 | 813 | 42 (5.2%) | 0 |
| 64 | 634 | 32 (5.0%) | 0 |

    python3 notes/prom_b_f0ea9f_layout.py --null-accept

A rule with a 13.9% false-positive rate on data is not a boundary argument.
Requiring the decode to end in a `ret`/`reti`/unconditional transfer — what a
routine tail looks like — takes it to 1 in 1,884.

⚠ **This is retro-active and it has been applied.** `accept()` in
`notes/prom_b_f65000_layout.py` now carries the tail requirement, the LAYOUT in
`notes/gen_prom_b_f65000_module.py` was re-derived, the module was regenerated
and re-spliced, and the gate passes. Four runs (76 bytes) moved from
instructions to `.byte`:

| run | bytes | what it really is |
|---|---:|---|
| `0xF6A475` | **40** | `10 ff 11 19 1a 17 ff 12 13 14 15 16 ff 18 ff …` — a lookup table over the same 0x00-0x1F alphabet as `IndexMap_F6A455` directly above it. Round 4 printed it as `rcf / swi 7 / scf / pop F / jp 0xff17 / …`. |
| `0xF6B006` | 24 | two `0x0E` pad bytes then real-looking code that does not end in a flow end |
| `0xF65DCC` | 6 | `ld A,0x55 / ld W,(0x0c03)` |
| `0xF65DF1` | 6 | the same two instructions |

The last three may well be code that falls through; they are `.byte` with the
reason in their headers, because "may well be" is not a boundary argument
either. The 40-byte one is not code at all.

### 2.5 No immediate-seeding, and the cost is stated

Round 4 seeded the descent with every 32-bit immediate an instruction loads and
priced that at **+4,688 bytes**, while warning that "a stored address is as often
a DATA address". Here it is not *as often*, it is *always*: with the source on,
`--provenance` grades **eight** code segments (266 bytes) as reachable only that
way, and all eight are data —

* `0xF133E4`, `0xF13464`, `0xF13491`, `0xF13511`, `0xF1353E`, `0xF135BE`,
  `0xF135F7` are fragments of the byte maps of §2.3;
* `0xF13874` is 218 bytes of `60 00 01 / 61 00 ff / 61 01 ff / 61 02 ff …`, a
  three-byte-record table with one ascending field.

Eight of eight. The source is **off** for this module, and the cost is that a
routine reachable only through a stored address comes out as `.byte`.

⚠ **That measurement was taken against round 4's rule set** — immediate-seeding
on, BYTEMAP off — which is the only configuration in which it is visible. With
the rules as they now stand, `--provenance` reports **no IMMED segment at all**,
because seven of the eight are inside byte maps the barrier now owns. So the
number cannot be re-derived by running the tool today, and saying so is part of
the finding rather than a footnote to it.

---

## 3. What the block is made of

    python3 notes/gen_prom_b_f0ea9f_module.py --layout
    python3 notes/gen_prom_b_f0ea9f_module.py --tables

81 segments over 21,141 bytes, counted from the frozen LAYOUT literal and not by
hand:

| kind | segments | bytes |
|---|---:|---:|
| code | 21 | **13,357** |
| pointer tables | 23 | 2,376 |
| unsplit `.byte` data | 23 | 4,821 |
| byte maps | 6 | 415 |
| RAM-pointer tables | 7 | 160 |
| index map | 1 | 12 |
| **total** | **81** | **21,141** |

**No `.fill` and no strings:** the block contains no padding run of 16 bytes or
more, so every byte of it is substantive, and every printable-looking run in it
turned out to be a byte map.

The 23 pointer tables classify as **19 TRANSFER, 2 DEREF, 1 STRIDED, 1
UNKNOWN** (19+2+1+1 = 23) — and the classification is in each table's own header,
with the instruction that establishes it. Only the 19 TRANSFER tables seed the
code walk.

**135 routines** carry a header. That is more than the 21 code segments because
a segment holds several routines, and it counts three entry sources the 0xF65000
emitter did not label: an address an already-proven instruction calls, an entry
of a TRANSFER table, and an in-module call target. Their grades:
**93 TABLE, 25 BRANCH, 14 THUNK, 2 PROVEN, 1 CALL** — `grep -c "^; Evidence ("`
over the emitted block.

### What a routine header does and does not say

Each carries **Name / Called from / Touches / Calls / Evidence(grade) /
Unknown**. It does **not** carry Inputs and Outputs: nothing in this lane derives
a register-level contract, and a guessed one would be worse than the gap. That
is stated here rather than left for a reader to notice.

### Every routine carries its provenance grade

This is the first module in this lane whose headers say **why** a byte is code,
not just that it is:

| grade | segments | bytes | what it means |
|---|---:|---:|---|
| PROVEN | 1 | 689 | an instruction already in the .s calls it (`calr 0xf0ea9f`) |
| THUNK | 1 | 182 | a `jp` slot of the 0xF40000 directory names it |
| CALL | 2 | 2,122 | an opcode-anchored `call`/`jp addr24` targets it |
| BRANCH | 1 | 3,432 | a branch decoded inside the block targets it |
| TABLE | 16 | 6,932 | an entry of a table the consumer rule classed TRANSFER |

**No segment is graded IMMED, ACCEPT or NONE.**

⚠ Two honest caveats on that table. (a) `accept()` still admitted **7 runs** —
runs nothing reaches, whose decode is self-consistent *and* ends in a flow end.
Because such a run merges into the descent-reached segment beside it, the grade
shown is the **segment's** entry point, not the run's; the 0.1% figure of §2.4 is
what those 7 runs rest on. (b) TABLE is the weakest grade that survives here and
it covers 16 segments and 6,932 bytes — half the code — so this module's code is
only as good as §2.1's consumer classification, which is why every table's
`--tables` line names the instruction that classified it.

    python3 notes/prom_b_f0ea9f_layout.py --provenance

---

## 4. What the block ADDRESSES — and a correspondence that is NOT an identification

Heaviest 16-bit RAM words over the transcription: `(0x2797)`, `(0x28B0)`,
`(0x2790)`, `(0x2540)`, `(0x2640)`, `(0x2076)`. `(0x2540)`/`(0x2640)` are the
display-list interpreters' own working words
(`notes/FINDINGS-ui-display-list.md`); `(0x2075)`/`(0x2076)` are the UI
redraw-request bytes of `notes/FINDINGS-prom_b-field-blink.md`.

⚠ **There is not one absolute operand in `0x600000-0x7FFFFF` anywhere in the
block.** It touches no device — only RAM. So it answers no register question,
and it is not the audio path.

**The correspondence.** Immediately above the block, still `.incbin`, sit
`DSP EFFECT`, `ALGORITHM :`, `OUT SELECT`, a **2,048-byte table at `0xF147AC` of
128 sixteen-character names** — `  NO OPERATION  `, `CHORUS`, `GATED REVERB`,
`PLATE REVERB 1`, `PEQ+COMPR+DIST`, `----------` for unused slots — and a table
of parameter names (`WET`, `DRIVE`, `EMPHASIS Fc`, `LFO WAVEFORM`,
`REVERB TIME`). This block's three big tables have **128 entries each**, and the
index into them comes from `(0x2796)`.

128 names and 128 entries is worth recording. It is **not** proof that the index
is the effect-algorithm number: nothing decoded in this block reads the name
table. Every routine here is `sub_XXXXXX`.

---

## 4b. A second span: the effect table has 128 SLOTS and 56 are used

`0xF147AC` is 2,048 printable bytes that tile **exactly** as 128 entries of 16
characters, and it is converted this round as `EffectNames_F147AC`:

    python3 notes/gen_prom_b_effect_tables.py --checks   # 14 checks
    python3 notes/gen_prom_b_effect_tables.py --bands    # the 16-slot banding
    python3 notes/gen_prom_b_effect_tables.py --names    # the 56 real names

| what | value | how it was established |
|---|---|---|
| extent | 0xF147AC-0xF14FAB, 2,048 bytes | maximal printable run: the byte before is `0x00`, the byte after `0x02` |
| stride | **16** | 2048/16 = 128 with no remainder, **and** 113 of the 128 rows are blank-padded on BOTH sides (a centred display column) against 8 of 256 at stride 8 — `--stride` |
| entry 0 / 127 | `  NO OPERATION  ` / `   ----------   ` | asserted on every emit |
| used slots | **56**; 72 are the `----------` placeholder | asserted: 72 + 56 = 128 |

The 56, with their slot numbers, are the machine's effect list: `NO OPERATION`
(0), `CHORUS` (1), `MODULATED CHORUS` (2), `ENHANCER` (3), `FLANGER` (4),
`PHASER` (5), `ENSEMBLE` (6), `GATED REVERB` (8), `SINGLE DELAY` (9),
`MULTI TAP DELAY` (10), `MANUAL DELAY` (11), the reverbs at 16-27
(`ROOM/PLATE/CONCERT/DARK/BRIGHT/WAVE REVERB 1` and `2`), the distortion family
at 32-39 (`DISTORTION`, `OVERDRIVE`, `FUZZ`, `EXCITER`, `COMPRESSOR`,
`SLOW ATTACKER`, `NOISE GENERATOR`, `PARAMETRIC EQ`), the modulation family at
48-56 (`AUTO PAN`, `PITCH SHIFTER`, `VIBRATO`, `PEDAL WAH`, `AUTO WAH`,
`ROTARY SPEAKER`, `RING MODULATOR`, `HAAS EFFECT`, `MIX UP`) and the combinations
from 64 (`S.DELAY+CHORUS` …, `PEQ+COMPR+DIST` …).

**And the slots are BANDED.** Every used slot lies in the low part of a 16-slot
band, and two whole bands are empty (`--bands`):

| band | used | range |
|---|---:|---|
| 0x00 | 11 | 0x00-0x0B — chorus / flanger / phaser / ensemble, then the delays |
| 0x10 | 12 | 0x10-0x1B — the twelve reverbs |
| 0x20 | 8 | 0x20-0x27 — distortion, dynamics, EQ |
| 0x30 | 9 | 0x30-0x38 — pan, pitch, wah, rotary, ring mod |
| 0x40 | 12 | 0x40-0x4B — two-effect combinations |
| 0x50 | **0** | — |
| 0x60 | 4 | 0x60-0x63 — three-effect combinations |
| 0x70 | **0** | — |

That the high nibble is a CATEGORY is an observation about the table, asserted
for the two empty bands and printed for the rest; no code here is shown reading
it that way.

⚠ **The slot numbers are the table's own indices, not a decoded effect number.**
Nothing in prom_a or prom_b spells `0x00F147AC` in a decodable operand; the only
byte-scan hits are 4-byte windows inside the record region at
`0xF144A6-0xF146E8`. That the index into §3's three 128-entry tables — which
comes from `(0x2796)` — is the same index is a **correspondence**.

`EffectParamNames_F15024` (1,924 bytes) goes with it, and its tiling is stated
without rounding: 113 rows of 17 cover 1,921 of the 1,924, 99 of the first 100
rows end in `:`, and the 3-byte remainder is emitted as its own row.

⚠ This is the first thing in this lane that the emulation side can use directly:
`kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md` lists "the audio path" among
the gaps it could not frame sharply, and says of the three uPD6383GF DSPs "I
cannot even say whether the DSPs sit in the main mix". This does not answer that
— but it does say, from the ROM, exactly which 56 algorithms the firmware
believes the machine has.

---

## 5. What is left, and why

`0xF13D34-0xF27BFF` is 81,612 bytes, of which **77,640 stay `.incbin`** — the
3,972 the two text tables of §4b take out of it are the difference. Its first
part is a record
region interleaved with those strings, and `scripts/analysis/prom_b_display_lists.py`
cannot frame it: that tool finds a list's ENDS from `ld XIY,start / ld XIX,end`
call sites, and these lists have none.

**But this round found what they have instead, and it is a real framing
argument.** Two instructions in the converted block hand a computed address to
interpreter B **one record at a time**:

```
0xF110B9   add XBC,0x00f157a8
0xF110BF   push XBC
0xF110C0   call 0xf42e0c
0xF11154   add XBC,0x00f15820
0xF1115A   push XBC
0xF1115B   call 0xf42e0c
```

and `T_F42E0C` is `jp DisplayListB_RunOne_Stack` (0xF3183D) — already converted
and already named in `prom_b/wsa1_prom_b.s`. Walking record lengths from those
two bases:

    python3 notes/prom_b_dlb_record_arrays.py

| base | records | opcode | size | walk ends at |
|---|---:|---|---:|---|
| `0xF157A8` (pushed at 0xF110B9) | 16 | 0x02 | 15 | `0xF15898` |
| `0xF15820` (pushed at 0xF11154) | 8 | 0x02 | 15 | `0xF15898` |
| `0xF15B03` | 8 | 0x02 | 15 | `0xF15B7B` |

The first two end at the **same** address and their bases differ by 120 = 8 × 15:
two entry points into one array. **That is the round-6 rule** — walk from a base
an instruction pushes, require whole records, and require the end to agree with
another base's walk.

⚠ And the third row is a bonus check on §2.4: `0xF15B03` is one of the runs round
4's rule would have called code, and it walks as **eight interpreter-B records**.
That is a second, independent reason — nothing to do with the tail rule — to
believe the demotion was right.

Above that, `0xF14800-0xF17FFF` is 62-97% printable. Two of its tables are
converted this round (§4b); the rest are the VALUE tables (`  0.1  0.2 …`,
`-12.0-11.5 …`, ` SINE TRIANGSQUARE`, `PART 1PART 2 …`), each a maximal
printable run with its own fixed column width. They are cheap and safe, and they
are the round-6 target if the record rule does not come out.

⚠ **And one warning for whoever takes them:** §2.3 of this note is exactly what
goes wrong if a printable run is assumed to be text. Every one of those value
tables must be checked against the BYTEMAP rule first.

---

## 4c. The frontier, before and after

`notes/prom_b_module_frontier.py` BEFORE this round: **16 runs** with
unconverted prom_b targets, headed by

```
  run                    slots   unc    extent    1span  spans   refs
  T_F42F40-T_F42F6C    12    12     13084    13084      1     20   0xF0F018-0xF12334
  T_F42E40-T_F42E6C    12    12      4624     4624      1     16   0xF53000-0xF54210
  T_F41250-T_F41264     6     6      4091     4091      1      8   0xF36E21-0xF37E1C
  T_F40D90-T_F40E18    35    35      3365     3365      1      8   0xF55800-0xF56525
  T_F41F54-T_F421A8   150     5      2657     2657      1      0   0xF0A000-0xF0AA61
```

The round claims exactly two runs — `T_F42F40-T_F42F6C` (12 slots) and
`T_F434A0-T_F434A4` (2) — and

    python3 notes/prom_b_round5_frontier_delta.py

reconstructs BEFORE from the file's own current `.incbin` set plus the converted
range, so the claim stays checkable after the fact. It asserts the two are in
BEFORE, absent from AFTER, that nothing else disappeared, that they own exactly
**14** `jp` slots, and that every one of the 14 targets is inside
0xF0EA9F-0xF13D33.

⚠ Its run TOTALS are not the tool's: it groups maximal spans of consecutive `jp`
slots and the tool groups across a leading non-`jp` slot. The run NAMES are
identical in both.

---

## 5b. For the emulation lane

`kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md` is read-only from here, so this
is the mirror. Nothing in this round closes a numbered gap: **the whole block
touches no device address at all**, so it cannot answer gap A, F, G or H. What it
does hand over:

1. **The 56 effect algorithms, with their slot numbers** (§4b) — from the ROM,
   with an entry count that tiles exactly. The gaps file's "gaps I could not
   frame sharply" opens with *"I cannot even say whether the DSPs sit in the main
   mix"*; this at least fixes what the firmware thinks the effect list is.
2. **A warning about `0x00F42C70`.** The image-wide default thunk slot appears as
   an entry in this block's 128-entry dispatch table, i.e. "this algorithm has no
   handler" is spelled as a jump to the default slot. Anything counting live
   handlers has to subtract it.
3. **A method warning that applies to the driver's own reading of ROM tables:**
   a pointer table in this image is not necessarily a jump table. Two of the
   three 128-entry tables here are read with `ld H,(XWA)`.

---

## 6. Scripts this round added or changed

| script | question |
|---|---|
| `notes/prom_b_f0ea9f_layout.py` | the LAYOUT, the four new/changed rules, and a null for each |
| `notes/gen_prom_b_f0ea9f_module.py` | the emitter whose output is in the .s; `--checks` refuses to emit on a failed assertion |
| `notes/gen_prom_b_effect_tables.py` | the two DSP-effect text tables, their tiling and the 72/56 split (13 checks) |
| `notes/prom_b_round5_frontier_delta.py` | did this round retire exactly the two runs it claims |
| `notes/prom_b_dlb_record_arrays.py` | are the arrays above 0xF13D34 interpreter-B records, and where do the walks end |
| `notes/prom_b_round5_citations.py` | does every instruction QUOTED in this note decode there (it parses this note, so the two cannot drift) |
| `notes/prom_b_f0ea9f_header_audit.py` | do the emitted headers agree with the rows under them, **in the .s itself** — and `--last` proves the audit reaches the block's last object |
| `notes/prom_b_f65000_layout.py` | **changed**: `accept()` now requires the tail; `--null --rev REV` pins the corpus |
| `notes/gen_prom_b_f65000_module.py` | **changed**: LAYOUT re-derived, four runs demoted to data, banner corrected |

⚠ All of them are **untracked** — this lane may not `git commit`. Committing
`notes/` is still the first thing the owner of this tree should do.

## 7. Everything this round asserts, and the command that re-derives it

| claim | command | result |
|---|---|---|
| the ROMs still rebuild byte-identically | `python3 scripts/analysis/assert_byte_identical.py` | PASS |
| coverage: prom_b 167,680 → 192,793 substantive | `python3 scripts/analysis/source_coverage.py` | 36.8% |
| the layout is derived, not typed | `python3 notes/gen_prom_b_f0ea9f_module.py --checks` | all PASS |
| content rules do not fire in proven code | `python3 notes/prom_b_f0ea9f_layout.py --null-ptr` | 6 rules, 0 hits |
| `accept()`'s rate on proven DATA | `python3 notes/prom_b_f0ea9f_layout.py --null-accept` | 13.9% → 0.1% |
| STRIDED does not fire on proven dispatch tables | `python3 notes/prom_b_f0ea9f_layout.py --null-stride` | 0 of 33 |
| why each code segment is code | `python3 notes/prom_b_f0ea9f_layout.py --provenance` | no IMMED/ACCEPT/NONE |
| exactly two frontier runs retired | `python3 notes/prom_b_round5_frontier_delta.py` | DELTA PASS |
| the effect table's tiling and 72/56 split | `python3 notes/gen_prom_b_effect_tables.py --checks` | 14 checks PASS |
| the record arrays above 0xF13D34 | `python3 notes/prom_b_dlb_record_arrays.py` | PASS |
| every instruction quoted in this note | `python3 notes/prom_b_round5_citations.py` | 19 checked, 0 wrong |
| the emitted headers match their rows | `python3 notes/prom_b_f0ea9f_header_audit.py` | 4 checks PASS, last object 0xF139AB |
| no citation in the .s misses its object | `python3 notes/prom_b_audit_callsites.py` | 1,741 cited, 24 `??` — the pre-existing set, none in this round's ranges |
