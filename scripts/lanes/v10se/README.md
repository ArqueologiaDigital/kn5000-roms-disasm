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
| `se_classify_byte_runs.py` | The three-way split: (a) code-as-`.byte`, (b) structured data with a typed C description available, (c) genuine byte table — **with its own false-positive control**. | see below |
| `se_integrate_descriptors.py` | Which source lines exactly cover each descriptor span, and rewrite them to `.incbin` | `python3 scripts/lanes/v10se/se_integrate_descriptors.py --plan` |

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
(d) blocked: run starts on a backend gap   403 runs   1046 B
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
| class (d), 401 runs | 745 | the backend cannot spell the leading opcode; converting now would mean inventing a reading that round-trips. Blocked on `w10/missinginsns` |
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
