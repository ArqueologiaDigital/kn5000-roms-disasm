# Lane v10se — the sound-editor corner of v10

Branch `w10/v10se`.  Target files:

* `v10/maincpu/audio/sound_editor_ui.s`
* `v10/maincpu/audio/semenu_routines.s`

Together they carry **8,611 `.byte` operands**, which is *not* automatically a
debt figure — a genuine byte-valued table written as `.byte` is already
correctly represented.  These scripts separate the part that is debt from the
part that is not.

| script | question it answers | command |
|---|---|---|
| `se_byte_run_census.py` | How many `.byte` operands are here, and in what SHAPE — a 1-byte run wedged between two instructions, or a 400-byte table? | `python3 scripts/lanes/v10se/se_byte_run_census.py` |
| `se_c_descriptor_vs_rom.py` | Do the *unintegrated* `sound_editor_screens/se_*.c` screen descriptors actually compile to the ROM bytes at their stated base address? | `python3 scripts/lanes/v10se/se_c_descriptor_vs_rom.py` |
| `se_classify_byte_runs.py` | The split: (a) code-as-`.byte`, (b) structured data with a typed C description available, (c) genuine byte table, (d) framing suspect — **with its own false-positive control**. | see below |
| `se_integrate_descriptors.py` | Which source lines exactly cover each descriptor span, and rewrite them to `.incbin` | `python3 scripts/lanes/v10se/se_integrate_descriptors.py --plan` |
| `se_generate_new_screendata.py` | Are there screen-data blocks in this corner that the hand-curated generator list never mentions? | `python3 scripts/lanes/v10se/se_generate_new_screendata.py --amap /tmp/amap.json` |
| `se_converted_span_composition.py` | What were the converted bytes spelled as *before* — instructions, `.byte`, or `.ascii`? | see its header |
| `se_blind_start_is_misframing.py` | Does a blind-start `.byte` run mean undecoded code, or mis-framed data? **Replays from committed data, no rebuild needed.** | `python3 scripts/lanes/v10se/se_blind_start_is_misframing.py --replay scripts/lanes/v10se/se_blind_start_is_misframing.json` |
| `se_gate_sees_the_change.sh` | Would the byte gate have gone red on this lane's conversion? | `bash scripts/lanes/v10se/se_gate_sees_the_change.sh` |

The classifier needs an address→source-line map, produced by the tree's own
tool (slow, ~10 min; it assembles and links a label-marked mirror of
`v10/maincpu` and self-tests that the mirror's ROM is still byte-identical):

```
python3 scripts/analysis/address_line_map.py --dump /tmp/amap.json
python3 scripts/lanes/v10se/se_classify_byte_runs.py --amap /tmp/amap.json --control
```

## The signal each class is read from

* **(b) is the only class with external evidence.**  `se_c_descriptor_vs_rom.py`
  compiles each `se_*.c` with the Makefile's own `clang -target tlcs900` +
  `ld.lld -T se_screens_link.ld` + `llvm-objcopy` invocation and diffs the
  result against `original_ROMs/kn5000_v10_program.rom`.  A `MATCH` means a
  typed C struct already emits those exact ROM bytes; no decoder opinion can
  overturn that.
* **(a) and (c) are read from source structure plus a decoder**, and
  `--control` measures how badly that fails here.  See below — it fails badly.

## Bucket (d): FRAMING SUSPECT

Added after the coordinator's finding
(`scripts/analysis/byte_run_start_enrichment.py`, `15115eae`): v10's `.byte`
residue starts with one of `{0x01, 0x04, 0x17, 0x1a, 0x1c}` — five leading
opcode bytes the tlcs900 backend cannot encode, but which MAME's unidasm decodes
as `normal` / `max` / `ldf` / `JP nnnn` / `CALL nnnn` — far more often than with
a decodable byte of similar magnitude.

**⚠ The reading of that signal was corrected on 2026-09-02 (`3309e94e`), and
this lane confirmed the correction independently.** It measures **mis-framing**,
not undecoded code. A wrong instruction stream breaks at every byte the decoder
refuses, so data-framed-as-code is chopped into many short `.byte` runs each
necessarily *starting* with a refused byte — the very signature the script was
built to find, produced in bulk by the opposite defect. Two causes, opposite
fixes:

* code spelled as data → decode it (needs `w10/missinginsns`);
* **data spelled as code → type it** (needs no toolchain change at all).

Runs tagged `(d)` are still not converted here, but the reason is now honest:
not "the assembler is the blocker", but "the framing of these bytes is not
established, and the likelier defect in this corner is the one you fix by
typing them".

### This lane's independent confirmation

`se_blind_start_is_misframing.py`. The coordinator's evidence was a before/after
on `seq_event_playback.s`. This lane can test the same claim with a population
that is proven data by **external** evidence rather than by a conversion
decision: the 16 spans converted here are certified data because a C struct,
compiled with the project's own toolchain, emits exactly those ROM bytes.
Nothing about that certificate depends on a decoder, on any framing judgement,
or on this lane being right.

```
INSIDE spans later proven DATA by a C compile   blind  31/154  = 20.1%
OUTSIDE those spans (rest of the same file)     blind 310/1984 = 15.6%
enrichment inside proven data                          1.29x
```

Blind starts are **enriched** on bytes that provably cannot be undecoded code.
That is the corrected mechanism, reproduced from a second direction.

Whole-file, by the sequencer lane's own method (`git show 7294d049^:`):

```
before wave 1   2138 runs  341 blind  15.9%
after  wave 2   1965 runs  308 blind  15.7%
```

33 blind-start runs vanished, 31 of them inside proven-data spans. The rate
barely moves because this lane cleared 2,342 B of a 374 KB file, against the
sequencer lane's 40.9% → 1.7% for a file whose misframes were cleared wholesale.
**So the remaining 15.7% reads as "this file is still substantially
mis-framed" — there is more data-as-code here to type, not undecoded code
waiting on the assembler.**

⚠ **Do not quote a ratio on these two files.** Their control counts are 3 and 0,
and with a zero control the ratio is infinite regardless of the blind count
(`3309e94e`). An earlier revision of this lane's report quoted "68x" and "inf";
both were artefacts of a single-digit denominator and are withdrawn. The script
now prints raw counts and suppresses the ratio below a control of 10.

### Was (d) confounded by ScreenData opcodes here?  Tested; that one is not.

Four of the five blind bytes are also **ScreenData opcodes** in this exact
corner (`scripts/generators/screendata_parser.py`): `0x01 HLINE`, `0x04 CTRL`,
`0x17 PARAM_LABEL`, `0x1C FIELD_LABEL`. `se_blind_start_is_screendata.py` builds
the corner's screen-data territory from every `0x00Fxxxxx` immediate in the v10
sources that lands in these two files (88 of them; 73 parse; 4,384 B of union
span) and asks whether blind-start runs cluster inside it:

```
blind-start runs inside screen-data territory :  23/299  =  7.7%
all other .byte runs inside it                : 232/2384 =  9.7%
enrichment                                     : 0.79x
```

**That specific confound is not supported** — blind-start runs are, if anything,
*less* likely to be screen data at a known entry point than other runs. ⚠ An
earlier revision concluded "and the (d) tag stands", which over-read it: ruling
out one alternative explanation is not evidence for the original one. The
question is settled the other way by the section above.

## ⚠ The control, and what it says

`--control` runs two controls.  Both use the 23 byte-exact `se_*.c` spans as a
population **proven to be data by an external compile**, so any (a) verdict on
them is by construction a false positive.

1. *Decode half alone*: 362/400 sampled windows inside proven data (90.5%)
   decode into an instruction long enough to pass.  At 1–2 byte run lengths the
   decoder is nearly uninformative — almost any byte starts something.
2. *Full (a) test* (source frames both neighbours as instructions **and** the
   decode spans the run), applied to the `.byte` runs lying entirely inside
   proven-data spans: **115/147 runs (78.2%), 130/272 bytes (47.8%) are called
   (a) anyway.**

That second number is the lane's main methodological finding: in this corner of
the ROM the "flanked by instructions" signal carries almost no information,
because the surrounding region *is itself* data that the original disassembly
framed as code.  Class (a) here must be treated as an upper bound with a ~50%
byte-weighted false-positive rate, not as a verdict.

## Results

Measured with the scripts above; `--amap` maps regenerated for each state.

### The three-way split (plus (d)), BEFORE this lane's conversions

```
(a) code-as-.byte (unspellable form)      2065 runs   2498 B
(b) structured data, typed C available     156 runs    470 B
(d) framing suspect (blind run-start)      403 runs   1046 B
(c) genuine byte table (already right)     228 runs   4597 B
    TOTAL                                 2843 runs   8611 B
```

Bytes partition exactly; run counts double-count the runs that straddle a
class boundary.

### AFTER

```
(a) 2038 runs 2469 B   (b) 0 runs 0 B   (d) 401 runs 745 B   (c) 231 runs 4757 B
    TOTAL 2670 runs 7971 B
```

`(b)` is empty: every `.byte` operand for which a byte-exact typed C description
existed has been converted. `(c)` rises slightly because runs that used to be
flanked by (fake) instructions now sit next to an `.incbin`, which the (a) test
correctly declines to call code.

### What was actually converted, and what it used to be

`se_converted_span_composition.py` attributes every converted byte to the kind
of source line that emitted it before the change:

```
                    wave 1 (12 descriptors)   wave 2 (4 new blocks)   total
disassembled code            1033 B  58.4%            353 B  61.6%    1386 B
.byte                         470 B  26.6%            177 B  30.9%     647 B
.ascii                        266 B  15.0%             43 B   7.5%     309 B
TOTAL                        1769 B                   573 B          2342 B
```

**1,386 of the 2,342 bytes were data-as-code** — the tree asserted they were
executable and they never were. That is the half of this result the `.byte`
counter could never have found.

### Refused, with reasons

| region | bytes | why not converted |
|---|---:|---|
| `se_setup_editor_full`, `se_setup_sel4` | 276 | compile byte-exact, but their spans are owned by `storage/flash_floppy_handlers.s` — another lane's file |
| `0xF14640` | 70 | ScreenDataParser misreads a 6-entry LE32 pointer table as one 70-byte CTRL command; the generated struct fails its own size assertion. The 24-byte pointer table is already `.byte` under an earlier lane's comment, i.e. correct if untyped |
| `0xF12AC9` | 11 | already an explicit `.long` under lane B4's 2026-08-30 record-chain comment; `0xF129D1` is deliberately stopped 11 bytes short so that comment stays attached to the cells it describes |
| `0xF164F7`, `0xF16506` | 45 | owned by `storage/flash_floppy_handlers.s` |
| class (d), 401 runs | 745 | framing not established. ⚠ The first version of this row said "blocked on `w10/missinginsns`", i.e. undecoded code. `3309e94e` and this lane's own `se_blind_start_is_misframing.py` say the likelier defect is the opposite one — data spelled as code, fixable by typing with no toolchain change. Not converted because no typed description is in hand yet, **not** because the assembler blocks it |
| class (a), 2038 runs | 2469 | the same unspellable-form problem, plus — see the control — this class is an upper bound with a ~48% byte-weighted false-positive rate in this corner |
| supersets of existing descriptors (`0xF11C49`, `0xF12288`, `0xF122AE`, `0xF162D3`) | ~700 | each parses as a LARGER block containing an already-integrated descriptor as a sub-entry. Re-basing means deleting `.c` files that `SE_NAMES` shares with v7/ and v9/. Left as a clearly-scoped follow-up |

### Gate

`make gate-all` green after each conversion: 13/13 images byte-identical
(9 KN5000 + 4 SX-WSA1R). `se_gate_sees_the_change.sh` shows the gate would have
gone red: perturbing `se_setup_sel1.c`'s `boundary_0.p1.x` changes exactly one
ROM byte, at `0xF12B4B`, and restoring it returns byte-identity.

⚠ The in-domain control above (78.2% of runs / 47.8% of bytes inside proven-data
spans misclassified as (a)) was measured on the PRE-conversion tree. Re-running
it now returns 0/0: the proven-data population is exactly the spans that are now
`.incbin`. The number stands as measured, but the control can only be repeated
against a tree that still has those spans in assembly.
