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
