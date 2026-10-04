# prom_b 0xF65000-0xF6D001 — the three modules at the head of the 0x065000 span

Round 4 of the prom_b lane, 2026-08-25. **29,143 substantive bytes** converted in
one contiguous span; prom_b substantive coverage 138,537 → **167,680** bytes
(26.4% → **32.0%**). The byte gate
(`python3 scripts/analysis/assert_byte_identical.py`) passes.

Every number below comes from a script named beside it. Nothing here is typed.

---

## 1. Why this span, and what it retired

`notes/prom_b_module_frontier.py` ranks whole thunk RUNS by the **contiguous**
unconverted extent of their targets. Its top four runs all pointed into one
`.incbin`:

| run | slots | extent | targets |
|---|---|---|---|
| `T_F42ED0-T_F42F04` | 14 | 20,977 | 0xF67434-0xF6C625 |
| `T_StepRecord_OnEnter-T_StepRecord_ButtonByTrackKind` | 3 | 14,463 | 0xF675CC-0xF6AE4B |
| `T_F42B70-T_SequencerMedley_LcdKeyRow4` | 48 | 2,648 | 0xF65C00-0xF66658 |
| `T_F432C0-T_F432CC` | 4 | 9 | 0xF65000-0xF65009 |

**69 slots.** All four are gone from the frontier now, and no other run went with
them:

    python3 notes/prom_b_f65000_frontier_delta.py

which reconstructs the BEFORE survey from the file's own current `.incbin` set
plus the range, so it stays checkable after the fact rather than being a figure
copied out of a session log. It asserts the four are in BEFORE, absent from
AFTER, that nothing else disappeared, that the four own exactly **69** `jp`
slots, and that every one of the 69 targets is inside 0xF65000-0xF6D001.

⚠ Its run TOTALS are not `prom_b_module_frontier.py`'s (19→15 against the tool's
20→16): the tool groups a run across a leading non-`jp` slot and this script does
not. The docstring says so and the four run NAMES are identical in both.

---

## 2. The method, and the null that licenses it

The interesting part of this round is not the volume, it is that the code/data
split is **measured** rather than eyeballed.

`notes/prom_b_module_trace.py`'s recursive descent reaches only **44.7%** of
0xF65000-0xF6F000, because the block is built out of pointer tables: a handler is
selected by indexing a table, and a plain descent cannot follow a table. So five
**content rules** run first and become BARRIERS the code walk may not enter:

| rule | threshold | what it frames |
|---|---|---|
| PTRTAB | ≥ 3 consecutive 4-byte LE words in 0x00F60000-0x00F6FFFF | dispatch tables |
| RAMTAB | ≥ 4 consecutive 4-byte LE words below 0x10000 | tables of 16-bit RAM addresses |
| BITTAB | ≥ 8 consecutive 4-byte LE words with `w[k] == w[0] << k` | bit-weight tables |
| IDENT | ≥ 12 bytes counting up by one, **without wrapping past 0xFF** | index maps |
| ASCII | ≥ 20 consecutive bytes in 0x20-0x7E | screen text |

**The null.** Each rule was run over every maximal run of PROVEN instruction text
already in `prom_b/wsa1_prom_b.s` — at commit `2707125`, **2,948 runs / 54,814
bytes**, all of it byte-gate-proven code. A rule that fires there is a false
positive.

    python3 notes/prom_b_f65000_layout.py --null --rev 2707125

All five fire **zero** times. The ASCII threshold is 20 and not 8 or 10 because
that corpus gives **7** false positives at 8 and **3** at 10 — both are printed
by `--null` so the choice reads as a measurement, not a preference.

⚠ **CORRECTED 2026-08-25 (round-1 audit finding 6). The corpus GROWS, so a null
figure without a revision rots.** `proven_code_runs()` derives it from the
*current* `.s`, so this round's own 29,143 converted bytes joined it: bare
`--null` on the post-round tree reports **3,891 runs / 73,139 bytes**, and the
rejected thresholds move to **23** at 8 and **3** at 10. The four figures above
were correct when measured and are *not* reproducible from a bare `--null` today;
`--rev` was added so they are. The conclusion is unchanged and in fact
strengthened — all five live rules still fire **zero** times on the 33% larger
corpus, and 20 is still the lowest ASCII threshold with a zero null:

| corpus | runs | bytes | ascii ≥ 20 | ascii ≥ 10 | ascii ≥ 8 |
|---|---:|---:|---:|---:|---:|
| `--rev 2707125` (as quoted above) | 2,948 | 54,814 | **0** | 3 | 7 |
| working tree, after this round | 3,891 | 73,139 | **0** | 3 | 23 |

The docstring of `prom_b_f65000_layout.py` was wrong in the same place and is
also corrected: it said the ASCII rule was "at least TEN bytes" with a null of
"16,316 bytes … ONE at >= 8", while the code has always had `ASCII_MIN = 20`.
Three different corpus sizes were in circulation (16,316 / 54,814 / 73,139) and
only one of them was ever what the code measured.

⚠ **The cost of that choice is stated and not hidden.** The 9-byte string
`VOLUME = ` at 0xF67DC6 is *not* promoted; it sits inside the code segment that
starts at 0xF67D6F and comes out as `db` bytes.

⚠⚠ **CORRECTED 2026-08-25 by round 5: `selfconsistent()` NEEDED A NULL OF ITS
OWN, and when it got one it demoted four runs of this very module.** The rule
below was calibrated against pointer tables, strings and 0x0E padding — data it
had been shown. Measured against 39,329 bytes of proven display-list DATA it had
not, it accepts **13.9%** of record-aligned 16-byte chunks as code. `accept()`
now also requires the decode to END IN A FLOW END, which takes that to 1 of
1,884; `0xF6A475` (40 bytes, a lookup table this module printed as `rcf / swi 7 /
scf / pop F / jp 0xff17 / …`), `0xF6B006` (24), `0xF65DCC` (6) and `0xF65DF1` (6)
are `.byte` now, and the module in `prom_b/wsa1_prom_b.s` was regenerated and
re-gated. Read `FINDINGS-prom_b-f0ea9f-module.md` §2.4 for the table of
false-positive rates, and `python3 notes/prom_b_f0ea9f_layout.py --null-accept`
to re-derive it.

⚠ **A criterion I built, measured, and THREW AWAY.** The first idea was: an
unreached run is code if a linear decode from its start lands exactly on the next
proven instruction boundary. Both edges are proven boundaries, so it sounds like
a real test. It is not:

    python3 notes/prom_b_f65000_trace.py --discriminate

| unreached runs of 0xF65000-0xF6F000 | runs | linear LANDS | self-consistent |
|---|---|---|---|
| all | 98 | **89** | 57 |
| tagged PTR32 | 12 | **12** | **0** |
| tagged ASCII | 3 | **3** | **0** |
| tagged FILL (0x0E) | 19 | 19 | 19 |
| tagged ? | 64 | 55 | 38 |

The linear test passes **every** pointer table and **every** string, including
the 278-byte `APC OFF / ONE FINGER / FINGERED / PIANIST` block: TLCS-900
resynchronises within a couple of instructions, so it cannot fail and it is
worthless. It survives in `notes/prom_b_f65000_trace.py` as `linear_lands()`
**only** so the next person does not re-invent it. The rule actually used is
`selfconsistent()` — the decode consumes the run exactly, contains no undefined
opcode, and every relative branch targets an instruction boundary — and it
rejects 12 of 12 pointer tables and 3 of 3 strings while accepting all 19 padding
runs. That is a test that can fail.

**The descent's four seed sources** are the thunk targets, every opcode-anchored
`call`/`jp` site in prom_a+prom_b, every 32-bit immediate an instruction it has
already decoded LOADS, and **every in-range entry of every table the PTRTAB rule
framed**. The last one is worth **4,688 bytes** on its own — 19,790 → 24,478,
printed by `python3 notes/prom_b_f65000_layout.py --seeds` — and it is not a
nicety: the 122-byte run at 0xF67D6F is entry **[8] of FIVE**
dispatch tables — a handler — and it came out as an unsplit `.byte` run until
table entries were seeded. `notes/prom_b_f65000_layout.py`'s
`table_entry_seeds()` is that step, and it is licensed by the PTRTAB rule's zero
false positives: a table the rule frames holds addresses the firmware transfers
to.

⚠⚠ **AND ROUND 5 FOUND TWO MORE SEED DEFECTS THIS SECTION DOES NOT COVER.** The
four seed sources below are not equally good, and the next module measured how
unequal: a table the firmware DEREFERENCES rather than transfers to seeds the
walk into data (2 of that module's 3 big tables), a table whose entries are an
arithmetic progression is an array descriptor (its first four targets there are
bitmaps), and following every loaded 32-bit immediate was wrong **8 times out of
8**. This module's own numbers below are unaffected — its tables really are
dispatch tables — but the method's "+4,688 bytes" is a figure for THIS block and
not a general licence. `FINDINGS-prom_b-f0ea9f-module.md` §2.1, §2.2, §2.5.

⚠ **The barrier is not cosmetic.** Two of those four seed sources are addresses
the firmware STORES rather than jumps it makes, and a stored address is as often
a DATA address. Measured on this exact range:

    python3 notes/prom_b_f65000_layout.py --barrier

with the barrier the walk claims 24,478 bytes; without it, 25,890, of which
**1,411** are inside an object a content rule framed — whole 32-entry pointer
tables at 0xF6828B and 0xF685C1 among them. `--conflicts` prints those bytes and
`gen_prom_b_f65000_module.py --checks` asserts the count is zero.

---

## 3. What is in the block

90 segments: 43 code (25,976 bytes), **31 dispatch tables** (2,412), 2
RAM-pointer tables (256), 1 bit-weight table (128), 6 index maps (286), 1 string
(40), **3** unsplit `.byte` runs (**45** bytes) and 3 runs of 0x0E `ret` padding
(3,627).

    python3 notes/gen_prom_b_f65000_module.py --layout
    python3 notes/gen_prom_b_f65000_module.py --tables

* **The dispatch tables** — 31 of them, **603 entries** between them, 3 to 32
  entries each (`python3 notes/gen_prom_b_f65000_module.py --stats`). **384 of
  the 603 (63.7%)** are `0x00F675CB`, a single 0x0E byte, i.e. a bare `ret`:
  that is the module's own do-nothing stub. 88 distinct targets in all; the
  busiest after the stub are 0xF678F8, 0xF6748D and 0xF6749D at 22 entries each.

  ⚠ The stub is **not** the image-wide default thunk slot `0x00F42C70`
  (`notes/prom_b_default_slot_census.py`) — which appears in these tables
  **zero** times. Confusing the two is not hypothetical: the first draft of the
  emitter subtracted `0x00F42C70` when it meant `0x00F675CB` and printed the
  wrong "distinct other targets" count in **every one** of the 31 table headers.
  The byte gate saw nothing. `notes/prom_b_f65000_header_audit.py` is what found
  it and what now re-checks each header's arithmetic against the `.long` rows
  under it, on all 356 objects (31 dispatch tables, 2 RAM-pointer tables, 1
  bit-weight table, 6 index maps, 1 string, 3 `.byte` runs and 312 routines),
  with `--last` proving it runs on the last one.
* **`BitWeight_F6C7F7`** — 32 words, entry *k* = 1 << *k*, read from one site.
  It is why the BITTAB rule exists: read one byte to the left the same bytes are
  *also* a valid chain of words below 0x10000, so RAMTAB and BITTAB disagree by
  one byte at 0xF6C7F6. The bit-weight reading starts on the byte after a `ret`,
  so it wins, and `ram_tables_ex()` drops the straddling chain whole.
* **`IndexMap_*`** — six of them, 286 bytes, each a run counting up by one. The
  no-wrap clause in the rule is load-bearing: at 0xF6A9A9 the byte before the map
  is the 0xFF that ends a `jrl` displacement, and 0xFF,0x00,0x01… would extend
  the "map" backwards into an instruction.
* **`Text_F6CA3B`** — `PAN      :KEY SHIFT:TUNING   :BEND SENS:`, 40 bytes, four
  10-character columns, read by `ld XIY,0x00f6ca3b` at 0xF6C9D7.
* **Three unsplit runs remain**, 45 bytes: one byte at 0xF657B2, one at
  0xF65E93, and 43 bytes at 0xF6B1FE that begin `0E 0E 0E 50 40 30 20 10 00 01
  02 03 05 04 06` — a small byte table with code after it that no rule frames.
  They are `Data_*` with a header that says only what the bytes are.
* **`RamPtrTable_F67EE8` / `RamPtrTable_F6CA63`** — 32 words each, all below
  0x10000; first 0x76A5 / 0x76A2, last 0x7EA5 / 0x7EA2, the step between
  neighbours taking two values (0x40 and 0x80) in both. Each has exactly one
  reader (`ld XIX,0x00f67ee8` at 0xF67E93; `ld XIX,0x00f6ca63` at 0xF6C99A).
  ⚠ That the two are the same 32 records read at two different field offsets
  three bytes apart is an INFERENCE from the constant difference, not something
  decoded here.

---

## 4. What the block ADDRESSES — a measurement, not an identification

Over the transcription itself, the heaviest absolute operands are

    0x603422 (x31)  0x60347E (x13)  0x610000 (x9)  0x603500 (x9)  0x600A14 (x7)

and the heaviest 16-bit RAM words

    (0x0EF5) x74  (0x0E63) x55  (0x0E53) x55  (0x126E) x49  (0x2075) x41

`0x603422`, `0x60347E`, `0x603500` and `0x610000` are the **song store's** bank
workspace, saved cursors, directory and ten banks
(`FINDINGS-prom_b-song-store.md`, `FINDINGS-memory-map.md`); `(0x2075)` is the UI
redraw-request byte of `FINDINGS-prom_b-field-blink.md`. Together with the one
string, the 32-entry tables and the 32-entry index maps, that is the shape of a
song/part editing UI over the song store.

⚠ **It is not named as one.** Every routine in the block is `sub_XXXXXX`. What
the code addresses is not what the code is for, and this tree's rule is that a
stated gap beats a plausible guess. The banner carries the same measurement with
the same refusal.

---

## 5. What is left, and why

`0xF6D002-0xF77FFF` stays `.incbin`.

* `0xF6D002-0xF6EFFF` is the **screen-text block**: 43 runs of ≥ 10 printable
  bytes in 8,190 bytes — `APC OFF`, `ONE FINGER`, `FINGERED`, `PIANIST`,
  `MODULATION2=`, `CTRL.PEDAL=`, `TIME SIGNATURE: /4`, the note-name table
  `<G ><Ab><A >…` — **interleaved with code the descent enters through them**.
  Splitting text from code there needs an ASCII rule with a null this round does
  not have: at 20 bytes the rule misses most of those runs, at 10 it has three
  false positives. That is the next round's problem and it is a real one.
* Above that, exactly **two** thunk slots point anywhere into 0xF6D002-0xF77FFF
  (`T_MidiFileL0ad_LcdKeyRow1 -> 0xF6F400`, `T_F43384 -> 0xF6F404`), so a split there would rest
  on a linear decode — which §2 shows is not a test.

---

## 6. Scripts this round added

| script | question |
|---|---|
| `notes/prom_b_f65000_trace.py` | which bytes of 0xF65000-0xF6F000 are code, once pointer tables are followed — and the refuted `linear_lands()` |
| `notes/prom_b_f65000_layout.py` | the code/data/fill LAYOUT, its five rules, their NULL, and the barrier's effect |
| `notes/gen_prom_b_f65000_module.py` | the emitter whose output is in the `.s`; `--checks` refuses to emit on a failed assertion |
| `notes/prom_b_f65000_header_audit.py` | do the numbers in the emitted headers agree with the rows under them |
| `notes/prom_b_f65000_frontier_delta.py` | did the round retire exactly the four runs it claims |
| `notes/prom_b_sc1_serial_regs.py` | what CPU 1's SC1 serial registers are programmed with (see `FINDINGS-prom_b-sc1-link.md` §"Round 4") |

⚠ Like every other script in `notes/`, all six are **untracked** — this lane may
not `git commit`. The first thing the owner of this tree should do is commit
`notes/`; until then the sentence "every number here comes from a script" is true
of a working tree a single `git clean -fd` would destroy.
