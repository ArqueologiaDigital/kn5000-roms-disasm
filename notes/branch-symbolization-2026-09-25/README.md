# Numeric branch operands -> symbolic labels (2026-09-25)

Tool: `scripts/converters/symbolize_numeric_branches.py` (its docstring is the spec).

## What question each artefact here answers

| file | question |
|---|---|
| `samples/<image>.txt` | the 45 randomly sampled sites the tool ACCEPTED per image (first tool revision, before R5/R6), with source and target context -- the exact input the verification panel read |
| `panel1_verdicts.json` | the panel's verdict per site: is the source real code, is the target a plausible destination, is the proposed name misleading, plus each judge's pattern notes |
| `workflows/verify-branch-symbolization-sample.js` | the exact workflow script that ran panel 1 (the judge prompt and verdict schema) |

The samples were drawn with `random.seed(hash(key) % 1000)` from the accepted
set of the tool as it stood before the R5/R6 guards; Python's string hash is
salted per process, so re-drawing gives a DIFFERENT sample -- the committed
sample files are the record, not the seed.

## Result of panel 1 (8 judges, 45 sites each, 360 sites)

| image | source real code | target plausible | name misleading |
|---|---:|---:|---:|
| v10 | 44/45 | 44/45 | 6 |
| v9 | 44/45 | 44/45 | 3 |
| v7 | 45/45 | 45/45 | 7 |
| v142 | 45/45 | 45/45 | 3 |
| hdae5000 | 45/45 | 45/45 | 4 (all pre-existing hand names) |
| prom_a | 45/45 | 45/45 | 2 |
| prom_b | 45/45 | 45/45 | 0 |
| prom_c | 45/45 | 45/45 | 0 |

Both failures (v10 site 26 at 0xF183DF, v9 site 9 at 0xF092B1) are PHANTOM
branches: a real multi-byte instruction the converter split into a lone
`.byte` prefix plus "instructions" made of its operand bytes.  The judges' own
tree-wide audits put such phantoms at ~1% of accepted sites (v10: 86 of 8,028).
What the panel changed in the tool:

* **R5** -- a second decoder (MAME `unidasm`, linear over the dump) must see an
  instruction start at the site, of the same branch kind, with the same target.
  Refuses both sampled phantoms; 741 v10 / 842 v9 / 201 v7 sites refused.
* **R6** -- data both decoders read the same wrong way survives R5: the v7
  judge found `extension_data.s` chord strings ("min" as `jr pl`) and
  `0x00ED02xx` pointer tables read as `jr nov, 2`.  Refuse when the ROM around
  the site is >= 80% printable or holds 4 consecutive in-range 32-bit pointers.
* never-taken `jr f`/`jrl f` refused; `jr cc, 0x00` recognised as absurd.
* naming: frame-drop epilogues (`inc N,xsp; ret`) are Epilogue; the parent is
  the nearest ROUTINE ENTRY (called / in a pointer table), never a data label;
  a called routine that starts after a terminator is `<FirstCaller>_Helper`
  (WSA1: `sub_<ADDR>`, its house style); Loop needs a backward CONDITIONAL.
* R4 (refuse code glued to data) was tried and switched OFF: it refused 10,229
  v9 sites, overwhelmingly real code after `.byte` islands.

## Findings the panel made that are NOT about this tool (leads for lanes)

* **`di` is mis-encoded by the backend**: llvm-mc spells 06 00 as `di`, but 06 00
  is `EI 0` (IFF=0, every level accepted); the real DI is `EI 7` = 06 07.  Fixed
  in the sources by `scripts/tools/fix_di_ei_semantics.py` (213 sites); the
  backend mnemonic still needs fixing so a future lift cannot reintroduce it.
* hdae5000 names contradicted by code: `HDAE5000_Divide_Signed` (0x29B8C5) is the
  UNSIGNED core (signed wrapper at 0x29B870); `HDAE5000_Display_Sub_294414` is a
  one-byte `ret` debug-trace stub (callers pass `'---[ Name ]---'` banners);
  `HDAE5000_StrCopy` (0x29AF0B) is strcat; coarse region labels ("LDS 3061
  bytes" etc.) span many functions.
* prom_a `Data_FF17E2` is mis-bounded: 0xFF21F6-0xFF2269 are four real
  subroutines (FF21F6, FF2204, FF2232, FF224D) with dozens of callers.
* v9/v10 carry many MISFRAMED instructions (a lone `.byte` prefix + operand
  bytes decoded as instructions): v10 `sequencer_engine.s` 22, `scoop_display.s`
  18, `ui_window_procs.s` 7 phantom sites among others -- unidasm gives the
  correct framing.
* v7 `extensions/extension_data.s` and the `ui_widgets/*_dispatch.s` record
  headers (`XX 6a 00`) are data decoded as code.
