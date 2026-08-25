# prom_b 0xF6D002-0xF77FFF — the performance screens, and a Standard MIDI File reader

Round 6 of the prom_b lane, 2026-08-25. The byte gate
(`python3 scripts/analysis/assert_byte_identical.py`) passes.

**44,189 substantive bytes** converted in one contiguous span (45,054 total, of
which **865 are `.fill`** — the first padding run any prom_b round has met, and
it is reported separately because filler is not progress). prom_b substantive
coverage 192,793 → **236,982** (36.8% → **45.2%**); re-run
`python3 scripts/analysis/source_coverage.py` for the live figure.

Three things in this round are worth more than the byte count:

1. **The target was chosen with a NEW tool, because the old one is blind to this
   module.** `notes/prom_b_module_frontier.py` ranks thunk RUNS and puts this span
   thirteenth of fourteen, on an extent of four bytes. It is nevertheless prom_b's
   best remaining target and `notes/prom_b_span_frontier.py` measures why.
2. **Round 5's rule set transferred to a new module UNCHANGED** — the first time
   that has happened in this lane. Round 5 had to add five rules to round 4's
   because round 4's produced false code; round 6 added none.
3. **One object in the block is identified beyond argument: a Standard MIDI File
   reader**, doing the SMF specification's own header validation field by field.
   40 checks, `python3 notes/prom_b_smf_reader.py --list`.

---

## 1. Why this span — and why the frontier tool was overruled

`notes/prom_b_module_frontier.py` ranks whole thunk RUNS by the contiguous
unconverted extent of their targets. On this tree its top rows were

| run | slots | unconverted extent | targets |
|---|---:|---:|---|
| `T_F42E40-T_F42E6C` | 12 | 4,624 | 0xF53000-0xF54210 |
| `T_F41250-T_F41264` | 6 | 4,091 | 0xF36E21-0xF37E1C |
| `T_F40D90-T_F40E18` | 35 | 3,365 | 0xF55800-0xF56525 |
| `T_F41F54-T_F421A8` | 5 of 150 | 2,657 | 0xF0A000-0xF0AA61 |
| `T_F42F80-T_F42FAC` | 11 of 12 | 1,512 | 0xF0B91C-0xF0BF04 |
| … | | | |
| `T_F43380-T_F43384` | 2 | **4** | 0xF6F400-0xF6F404 |

The last row is this module. The tool is not wrong; it is answering a different
question. **This block is entered by DIRECT CALL, not through the 0xF40000
routine directory**, so the directory says almost nothing about it.

`notes/prom_b_span_frontier.py` (new, round 6) ranks the `.incbin` SPANS
themselves, by how many DISTINCT addresses inside them an instruction ALREADY
TRANSCRIBED in prom_a/prom_b calls or jumps to. That is the strongest evidence
this tree has that a span holds code — the byte gate proves the file carrying the
call site rebuilds the image, so there is no byte-window scan in it at all.

```
prom_b `.incbin` spans, 126 of them, ranked by bytes     <- BEFORE the splice; 125 after
  span                     bytes  proven  thunk
  0xF157A8-0xF27BFF     74840       0     13
  0xF6D002-0xF77FFF     45054      76      2
  0xF067A6-0xF0D79B     28662       4     24
  0xF4F000-0xF54FFF     24576       0     11
  0xF2BE35-0xF317FF     22987       0      0
```

**76 proven targets is more than every other unconverted prom_b span put
together** (the rest sum to 42).

⚠ A span with `proven == 0` is **not** thereby data — the column is evidence FOR
code, never against it, and **123 of these 126 spans score zero** (only
0xF6D002, 0xF7E2D8 and 0xF067A6 do not; after the splice it is 123 of 125). What is separately
known about the 74,840-byte span above is that it is the interpreter-B record
region round 5 handed on (`notes/prom_b_dlb_record_arrays.py`: 0xF157A8 walks as
16 records and 0xF15820 as 8, both ending at 0xF15898), so framing it wants the
record rule rather than a code walk. That is why it was passed over, and the
reason is the record framing, not the zero.

The top five, and why each was or was not taken:

| rank | span | bytes | why |
|---|---|---:|---|
| 1 | **0xF6D002-0xF77FFF** | 45,054 | 76 proven call targets — **taken** |
| 2 | 0xF157A8-0xF27BFF | 74,840 | bigger, but **0 proven** — against 32 opcode-anchored byte-window hits, which is an upper bound and not evidence. It is the display-list RECORD region round 5 handed on, and framing it needs `prom_b_dlb_record_arrays.py`'s record rule, not a code walk |
| 3 | 0xF067A6-0xF0D79B | 28,662 | 24 thunk slots but only 4 proven; a good round-7 target |
| 4 | 0xF4F000-0xF54FFF | 24,576 | the thunk frontier's #1 run points here; 0 proven, and a hand look shows code and pointer records interleaved at 0xF50000/0xF52000 |
| 5 | 0xF5553F-0xF57D1D | 10,207 | **38** thunk slots, the densest directory coverage left in prom_b — the best target for the *thunk* method |

## 2. The method — and the fact that it did not have to change

`notes/prom_b_f6d002_layout.py` is `notes/prom_b_f0ea9f_layout.py` with `LO`/`HI`
changed and nothing else. That is the round's methodological result, and it is
measured rather than asserted:

* **barrier conflicts: 0** — no byte the code walk decoded was reclaimed by a
  content rule (`python3 notes/prom_b_f6d002_layout.py --conflicts`);
* **every content rule still fires ZERO times** over the proven prom_b
  instruction text, now 4,239 runs / 84,062 bytes:

```
NULL corpus: 4239 runs, 84062 bytes of proven prom_b instruction text (WORKING TREE).
  ptrtab >= 3, window 0xF00000-0xF7FFFF        false positives:  0
  ramtab >= 4                                  false positives:  0
  bittab >= 8                                  false positives:  0
  ident  >= 12                                 false positives:  0
  ascii  >= 20                                 false positives:  0
  bytemap >= 16 bytes / 12 values              false positives:  0
```

⚠ **Quote that corpus with the tree it came from.** It is derived from the
CURRENT `.s` and grows every round — round 4 measured 2,948 runs / 54,814 bytes at
commit `2707125`, round 5 measured 3,887 / 73,081, this round 4,239 / 84,062. The
conclusion strengthens as it grows; the number does not stay put.

### 2.1 The one thing round 5's emitter would have got wrong here

`build()` paints every run the BYTEMAP rule returns the same colour, so **N
ADJACENT byte maps arrive as ONE segment**. All six of the 0xF0EA9F module's
byte-map segments are a single run (`monotone_maps` returns 1 for 0xF133E4,
0xF13464, 0xF13491, 0xF13511, 0xF1354E and 0xF135CB), which is why round 5 never
met this; six of this module's fourteen are not — 0xF6F985 holds 4 maps and
0xF70298, 0xF7091E, 0xF72555, 0xF731AB and 0xF731DB hold 2 each. Round 5's
emitter writes, for
every byte-map object, *"the other N ascend strictly, 0xAA to 0xBB"* — which is
FALSE for a merged segment, because the sequence restarts at each map:

```
0xF6F985 n=70  subruns=4  17 + 17 + 16 + 20 bytes
0xF7091E n=64  subruns=2  32 + 32
```

The emitter now asks the rule for its own maximal runs, asserts that they **tile
the segment exactly**, checks each one on its own, and says *"N BYTE MAPS end to
end"* in the header. This was caught by the check, before a line was emitted —
`--checks` refused to emit and printed six FAILs.

## 3. What is in the block

`python3 notes/gen_prom_b_f6d002_module.py --layout`

| kind | segments | bytes |
|---|---:|---:|
| code | 75 | 32,569 |
| unsplit `.byte` runs | 68 | 9,408 |
| strings | 16 | 1,146 |
| byte maps | 14 | 500 |
| RAM-pointer tables | 3 | 424 |
| pointer tables | 2 | 128 |
| index maps | 1 | 14 |
| `.fill` (`ret` padding) | 1 | 865 |
| **total** | **180** | **45,054** |

Both pointer tables — 0xF7048D and 0xF72323, 16 entries each — are classed
**TRANSFER** by the consumer rule: the code that indexes them fetches an entry and
then transfers to it, so their entries are entry points and they seed the walk.

**The strings name the screens.** They are evidence about the MODULE and about
nothing smaller, and no routine below is named from them. All 31 quoted here are
asserted present in the span, byte for byte, by
`python3 notes/prom_b_f6d002_touches.py --strings` — a quoted string is a hand
transcription and hand transcriptions drift:

`  TEMPO  ` · `START   STOP    FILL IN1FILL IN2INTRO1  COUNT INENDING1 END` ·
`P 1 P 2 P 3` (the run continues to `P32`) · `VOLUME=` · `PANPOT=` · `KEY SHIFT=` · `TUNING=` ·
`BEND SENS=` · `SUSTAIN ON  OFF ` · `DSP EFFECT ` · `EFFECT1=` · `REVERB=` ·
`PANEL MEMORY=` · `APC OFF         ONE FINGER      FINGERED        PIANIST` ·
`ACCOMP PART1 ON` · `DYNAMIC ACCOMP ON ` · `TECHNI-CHORD ON ` ·
`<G ><Ab><A ><Bb><B ><C ><Db><D ><Eb><E ><F ><F#>` ·
`ACC. TOTAL VOL.=   BASS VOLUME =  DRUMS VOLUME =` · `TREMOLO ` ·
`EXT.TAB EFFECT:EN  DIS ` · `TOTAL REVERB ` · `      MELLOWNORMALBRIGHT` ·
`M.S.A. OFF ON  #2  #3  ` · `TIME SIGNATURE: /4` · `MODULATION2=` ·
`CTRL.PEDAL=` · `R.T.CREAT.X=` · `R.T.CTRL.Y=` and a chord-name table
(`Maj7 aug  min  min7 dim  m7`…`5 mM7  7sus46    aug7`).

That is the PERFORMANCE and ACCOMPANIMENT screen layer; from 0xF6F000 upwards it
is the sequencer/song side.

## 4. The Standard MIDI File reader — the one thing that IS identified

`python3 notes/prom_b_smf_reader.py --list` — 40 checks, every instruction
re-decoded from the ROM, all PASS.

**The tags.** 0xF6F528 holds eight bytes, `MThdMTrk`: the SMF header-chunk tag
and the track-chunk tag, used as two 4-byte compare templates.

**The input.** A 1,024-byte sliding window at **0x60A700-0x60AAFF**, cursor in the
32-bit RAM word `(0x1088)`:

```
0xF7138F  push XIX
0xF71390  ld XIX,(0x1088)
0xF71394  ld A,(XIX+)
0xF7139C  cp XIX,0x0060aaff
0xF713A7  calr 0xf765d4
```

**The header compare, and its single retry.**

```
0xF6F58F  ld XWA,0x0060a700
0xF6F594  ld (0x1088),XWA
0xF6F598  ld BC,0x0004
0xF6F59B  ld XIY,0x00f6f528
0xF6F5A2  calr 0xf7138f
0xF6F5A7  cp A,(XIY+)
0xF6F5D0  djnz BC,0xf6f5a0
0xF6F5B7  ld XWA,0x0060a700
0xF6F5BC  add XWA,0x00000080
0xF6F5C8  ld (0x2880),0x31
```

On the first mismatch the reader retries ONCE from 0x60A700 + 0x80; on the second
it stops with 0x31 in `(0x2880)`.

**The six header bytes, as big-endian pairs.** After `MThd`, `ld BC,0x0005` skips
the four length bytes and keeps the fifth:

| field | high byte | low byte |
|---|---|---|
| format | `(0x1079)` — `0xF6F5DE` | `(0x1078)` — `0xF6F5E5` |
| ntrks | `(0x107B)` — `0xF6F5EC` | `(0x107A)` — `0xF6F5F3` |
| division | `(0x107D)` — `0xF6F5FA` | `(0x107C)` — `0xF6F607` |

**All three of the specification's own rejections are implemented.**

```
0xF6F5FE  bit 0x07,A
0xF6F601  jrl NZ,0xf6f7d8
0xF6F60B  cp (0x107c),0x0000
0xF6F613  ld (0x2880),0x30
0xF6F61E  cp (0x1078),0x0000
0xF6F626  cp (0x1078),0x0001
0xF6F62C  jrl NZ,0xf6f7d8
```

A NEGATIVE division is SMPTE timecode and this reader refuses it; a zero division
gives 0x30 in `(0x2880)`; and the format must be 0 or 1. Then the track tag:

```
0xF6F655  ld BC,0x0004
0xF6F658  ld XIY,0x00f6f52c
```

0xF6F52C is 0xF6F528 + 4 — `MTrk`.

**And the file is a `.MID`.** The refill path writes the 8.3 extension:

```
0xF7661E  ld (0x21d0),0x4d
0xF76623  ld (0x21d1),0x49
0xF76628  ld (0x21d2),0x44
```

`M` `I` `D`.

### 4.1 What is NOT established, and is not claimed

* **WHERE the bytes come from.** The refill leaves prom_b through
  `T_F425A8`/`T_F425B0`/`T_F425E8` into prom_a `0xFE1C3A` / `0xFE1C55` /
  `0xFE1CB3`, all three of which are `sub_` in prom_a. The floppy
  (`notes/FINDINGS-prom_a-fdc.md`) is the obvious candidate and this note does not
  assert it.
* **Whose buffer 0x60A700 is.** It lies inside the 0x60A000 region prom_a's
  block/remote reader passes as a DESTINATION — `lda_24 XBC,(0x60a000)` at **21**
  sites in prom_a's transcription
  (`grep -c 'lda_24 xbc, (0x60a000)' prom_a/wsa1_prom_a.s`), and this block names
  0x60A000 itself as well as 0x60A700. That is an ADJACENCY, not a proof that the
  same transfer fills it —
  and gap D turns on exactly that kind of tie, so it is worth stating precisely
  and worth nobody quoting as more than it is.
* **What `(0x2880)` is.** It is a status/error word, and the SMF header path
  writes three values into it — 0x26 on entry (0xF6F578), 0x30 on a zero division
  (0xF6F613) and 0x31 on a failed `MThd` (0xF6F5C8 and again at 0xF6F669) — and
  compares against 0x31 at 0xF6F64A. ⚠ But the block as a whole writes **eleven**
  distinct literal values into it (0x03, 0x09, 0x1E, 0x1F, 0x23, 0x26, 0x27,
  0x2F, 0x30, 0x31, 0xFF), so naming three of them is naming a path, not decoding
  the word. `python3 notes/prom_b_f6d002_touches.py --status` lists every site;
  the count and the four SMF sites are both assertions in that script.

## 4b. What the block holds, in objects

316 routines and 104 data objects carry a full header — Name / Called from /
Touches / Calls / Evidence(GRADE) / Unknown — and **every routine in the block is
`sub_XXXXXX`**: the block introduces not one semantic name, so
`python3 notes/prom_b_evidence_audit.py` reports **0 UNBACKED labels inside
0xF6D002-0xF77FFF** (its 69 UNBACKED rows are all pre-existing, in blocks from
earlier rounds).

| object kind | count |
|---|---:|
| routines (`sub_`) | 316 |
| unsplit `.byte` runs (`Data_`) | 68 |
| strings (`Text_`) | 16 |
| byte maps (`ByteMap_`) | 14 |
| RAM-pointer tables (`RamPtrTable_`) | 3 |
| dispatch tables (`DispatchTable_`) | 2 |
| index map (`IndexMap_`) | 1 |

⚠ **State the unit.** The routine grades below count ROUTINES (316 of them); §5's
provenance table counts CODE SEGMENTS (75 of them). A segment usually holds
several routines, so the two tables cannot be compared row for row.

| grade | routines |
|---|---:|
| PROVEN | 75 |
| BRANCH | 188 |
| CALL | 36 |
| TABLE | 15 |
| THUNK | 2 |

**11,299 instructions** in 32,569 code bytes, 2.88 bytes each
(`python3 notes/prom_b_instr_census.py --module f6d002 --last`), cross-checked
against this file's own `; ADDR` comments: **0 decoded starts with no source
line, 0 source lines that are not a start**, and the LAST code segment
(0xF77D61+648, 194 instructions, last one 0xF77FE8) is printed by name.

`python3 notes/prom_b_audit_callsites.py` after the splice: **2,412 citations over
4,353 labels, 24 unresolved — and ZERO of the 24 are in this span.** All 24 are
the pre-existing residue documented in that script's own header (citations of a
table's CONSUMER, e.g. `ld L,(XDE+HL)`), at 0xF31B39, 0xF31CC5, 0xF45E9A,
0xF57D46, 0xF5D802-0xF5DBB4 and 0xF7CD98.

## 5. Provenance — why each code byte is code

`python3 notes/prom_b_f6d002_layout.py --provenance`

```
code segments by the STRONGEST reason their entry point is code:
  PROVEN   31 segments    3566 bytes
  THUNK     1 segments     296 bytes
  CALL      6 segments    5639 bytes
  BRANCH   25 segments   19846 bytes
  TABLE     3 segments    1585 bytes
  ACCEPT    9 segments    1637 bytes
```

**Zero segments with no reason at all.** The two weak grades are 3,222 bytes,
**9.9% of the code**, and every one of the twelve is printed individually so it
can be read by hand. The three biggest were read, and all three are plainly code
— these citations are checked by `python3 notes/prom_b_round6_citations.py`:

```
0xF6F000  jr T,0xf6f004
0xF6F002  jr T,0xf6f01f
0xF6F004  call 0xf409f8
0xF7208F  ld WA,0x0000
0xF72092  bit 7,(XIY)
0xF720A0  cp XIY,0x0000313a
0xF6D6D6  call 0xf431cc
0xF6D6DC  ld WA,(0x12b2)
0xF6D6E0  cp WA,0x03e8
```

0xF6F000 is a two-arm entry veneer; 0xF7208F walks 7-byte records to a fixed
top; 0xF6D6D5 is a `ret`, then a `call`/`ret` veneer, then a routine that
compares `(0x12B2)` against 1000.

⚠ `--provenance` had to be re-implemented for this module and the reason is
recorded: round 5's version calls the decoder once per CODE BYTE, and the decoder
spawns a subprocess for any address the merged phase table missed. On 13,357 bytes
that finished; on 32,569 it does not. `notes/prom_b_f6d002_layout.py` walks
instruction BOUNDARIES instead — identical branch-target and immediate sets, since
an operand can only be read off an instruction.

## 6. What this round did NOT close

Both of the following are NEGATIVE claims, so both come from a script:
`python3 notes/prom_b_f6d002_touches.py`, which censuses the **transcription**
(12,118 emitted lines, of which 11,299 are instructions) rather than the raw
bytes — every line carries its MAME text in a `; ADDR` comment and the byte gate
proves the file rebuilds the image, so this is not a byte-window upper bound.

* **Emulation gap O** (which panel button is which bit) asked for *"a converted
  display list that reacts to one group id"*. **This block does not close it:
  ZERO operands anywhere in it name the panel's change-mask shadow at RAM
  0x2B20-0x2B3F.** The screens are here; the panel decode is not.
* **The block touches no device.** Every absolute operand that is neither a
  16-bit RAM address nor an address in the images themselves lies in
  0x600000-0x6177FF — CPU 1 work DRAM on CS3 — and there are fifteen of them:
  0x603400, 0x603422, 0x603433, 0x60347E, 0x6034A0, 0x603500, 0x6036A0,
  0x603EE4, 0x60A000, 0x60A100, 0x60A480, 0x60A700, 0x60AAFF, 0x60AB00,
  0x610000. Nothing in 0x700000-0x7FFFFF, where prom_a's floppy registers and
  0x7E0008 live.
* **Gap D** (tie prom_d to an instruction) is untouched. §4.1 records the one new
  address-space adjacency this round produced — and note that the block names
  **0x60A000 itself**, not only 0x60A700 — and still refuses to call it a tie:
  what fills that buffer is a prom_a question and the prom_a lane has already had
  to retract one conclusion built on the same region.

## 6b. Two defects this round found in ITS OWN TOOLING, and fixed

Both are in `notes/prom_b-round2-audit-responses.md` in full; they belong here
too because they are the reason this block's headers say what they say.

1. **`proven_call_sites()` counted the block's own branches once the block was
   spliced in** — 1,119 targets instead of 76 — so the layout the generator
   re-derived stopped matching the one frozen in it (206 segments against 180).
   `--checks` caught it and refused. It now excludes a site inside the block.
2. **`header()` asked the same question one level down** —
   `proven_call_sites(a, a+1)`, "is there any transcribed transfer to exactly
   this address" — so after the splice **252 headers** carried the line *"an
   already-converted call site elsewhere in the image"* directly after their
   in-module call sites had been listed, against **74** before. It now tests
   membership of the block-wide external set.

Both were latent in round 5's generator as well and are fixed there too. The
result is checked, not asserted:

* `python3 notes/gen_prom_b_f6d002_module.py --checks` → **CHECKS PASS (0
  failed)**, 125 checks, run AFTER the splice;
* `python3 notes/gen_prom_b_f0ea9f_module.py --checks` → **CHECKS PASS (0
  failed)**, also after the splice, so round 5's block re-derives identically and
  the correction restored reproducibility rather than changing an answer;
* **idempotence**: a fresh `python3 notes/gen_prom_b_f6d002_module.py` produces
  19,662 lines that occur EXACTLY ONCE, verbatim, inside
  `prom_b/wsa1_prom_b.s` — the generator reproduces its own output;
* the final emitted block differs from the first one by **zero non-comment
  lines** — the code and data never moved, only the headers.

## 7. The frontier, before and after

`python3 notes/prom_b_round6_frontier_delta.py`

The honest headline is that **the thunk frontier barely moves**: one run,
`T_F43380-T_F43384`, two slots. That is stated rather than omitted, because it is
the direct consequence of §1 — a module the directory does not name cannot retire
much of the directory. The measure that ranked the span is
`notes/prom_b_span_frontier.py`, and there the span goes from the top row to gone.
