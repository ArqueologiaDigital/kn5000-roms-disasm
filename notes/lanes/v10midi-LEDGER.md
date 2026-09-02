# Lane w10/v10midi — `v10/maincpu/midi/` and `v10/maincpu/display/`

What this lane was asked for: a defensible split of the raw `.byte` operands in
these two directories into (a) real code still spelled as `.byte`, (b)
structured data that should be typed, (c) genuine byte tables already correct —
plus whatever of (a) and (b) could be converted byte-exactly.

Everything below is produced by a script committed next to it. Re-run before
quoting: the decoder changed twice during this lane and three of the numbers
move with it.

## Tools, and the question each answers

| script | question |
|---|---|
| `scripts/analysis/v10_line_address_map.py` | what ROM address does each source line assemble to? (there is no listing, and `llvm-mc -g` attributes every `.include`d line to the root file) |
| `scripts/analysis/v10_byte_run_classifier.py` | is a region a pointer table or code? `--control` measures its error rates against regions of known class |
| `scripts/analysis/v10_reframe.py` | render a named address span as typed data or as code, and refuse any render that is not byte-exact |
| `scripts/analysis/v10_reframe_code_runs.py` | which `.byte` runs inside code can the current decoder frame correctly, and what blocks the rest |
| `scripts/analysis/v10midi_byte_ledger.py` | partition every remaining `.byte` operand byte into exactly one bucket |
| `scripts/analysis/v10_gate_sensitivity_probe.py` | would the byte gate actually go red on the lines this lane converted? |

Commands (from the repo root):

    FILES="$(ls v10/maincpu/midi/*.s v10/maincpu/display/*.s)"
    python3 scripts/analysis/v10_line_address_map.py $FILES --out /tmp/lm.json
    python3 scripts/analysis/v10midi_byte_ledger.py --linemap /tmp/lm.json $FILES
    python3 scripts/analysis/v10_byte_run_classifier.py --linemap /tmp/lm.json --control \
        v10/maincpu/midi/midi_dispatch_handlers.s v10/maincpu/display/scoop_display.s
    python3 scripts/analysis/v10_reframe_code_runs.py --linemap /tmp/lm.json --report $FILES
    python3 scripts/analysis/v10_gate_sensitivity_probe.py
    make all && make gate-all

## Before / after

`.byte` operand bytes, `a99564a6` -> this branch:

| file | before | after |
|---|---:|---:|
| midi/ac_listener_handlers.s | 58 | 12 |
| midi/computer_interface_config.s | 0 | 0 |
| midi/computer_interface_pcg.s | 526 | 526 |
| midi/midi_dispatch_handlers.s | 3443 | 743 |
| midi/midi_encoder_routines.s | 0 | 0 |
| midi/midi_serial_routines.s | 52 | 48 |
| midi/midipkt_routines.s | 82 | 41 |
| midi/param_load_routines.s | 13 | 11 |
| midi/sysex_routines.s | 0 | 0 |
| display/graphics_text_vga.s | 248 | 190 |
| display/scoop_display.s | 3273 | 2309 |
| display/scoop_editor_data.s | 285 | 207 |
| **TOTAL** | **7980** | **4087** |

3,893 B of `.byte` retired. That number understates the change, because most of
it was not a `.byte`-for-`.byte` trade: 3,889 B of MIDI CC dispatch tables were
DATA framed as instructions, and ~3,900 B of code had its instruction
boundaries in the wrong places. Neither is visible to a `.byte` count and
neither is visible to the byte gate.

## The three-way split of what REMAINS (4,087 B)

    a-CODE-AS-BYTE (no anchor)          288
    a-CODE-AS-BYTE (refused)            534
    b-DATA-UNTYPED                       33
    c-BYTE-TABLE (documented)            48
    d-BLOCKED (blind 0x01/0x04)        1097
    d-BLOCKED (other backend gap)      2087

`(d)` is the fourth bucket the coordinator asked for and is 78% of the residue:
these runs cannot be framed until the backend can spell the instruction. The
work order, by `.byte` bytes each blocking byte holds up:

    0x01  826    0x04  815    0xc1  601    0xf1  271    0xa6  193
    0x8f  101    0xef   88    0x57   88    0xaf   79    0xb3   73

`0x01` and `0x04` are the two of the original blind five that `tlcs900_backend`
6f456a19f05b did not add (it added `ldf` 0x17, `jp16` 0x1a, `call16` 0x1c). The
rest are memory-prefix bytes whose sub-opcode the backend lacks.

## The control, and how the classifier could be wrong

`v10_byte_run_classifier.py --control` scores the pointer-array test against
regions whose class the tree already states — known DATA = regions containing
only `.long`/`.word`/`.ascii`, known CODE = regions containing only
instructions:

| file | known CODE regions | called CODE | known DATA regions | called DATA |
|---|---:|---:|---:|---:|
| midi_dispatch_handlers.s | 687 | 686 (99.9%) | 4 | 4 (100%) |
| scoop_display.s | 477 | 477 (100%) | 30 | 18 (60%) |

* **False DATA on known code: 1 of 1,164 (0.09%).** That is the direction that
  would be destructive, since it would leave real code typed as bytes.
* **Missed DATA: 12 of 34 (35%).** All misses are short tables (fewer than
  8 entries) or non-pointer tables, which the test is built not to claim. This
  is the safe direction — an undetected data region is left alone rather than
  disassembled — but it means bucket **(b) is a lower bound**, not the whole of
  the data still to type.

The decode test can never stand alone: data disassembles into plausible
instructions and re-assembles to the same bytes. So the pointer test runs first
and wins, and nothing was converted to instructions on decode evidence alone.

## Corroboration from an independent instrument

`byte_run_start_enrichment.py` (main, `3309e94e`) reads the blind-start rate as
MIS-FRAMING. Raw counts, not ratios — the control population here is 0-2 runs:

| directory | runs before | blind before | runs after | blind after |
|---|---:|---:|---:|---:|
| `v10/maincpu/midi/` | 1120 | 68 | 471 | 25 |
| `v10/maincpu/display/` | 2362 | 260 | 1558 | 124 |

`scoop_editor_data.s` fell hardest (32/255 -> 9/177). `graphics_text_vga.s` did
not (46/191 -> 36/137), and inspection says that is honest: its blind starts are
one- and two-byte runs sitting between instructions that decode cleanly, in a
repeated routine — genuinely undecoded CODE waiting on 0x01/0x04, not data
framed as code.

## Refusals, with reasons

* **1,097 B blocked on 0x01/0x04**, plus **2,087 B on other backend gaps.** Not
  forced. A span that would swallow one of these bytes into an operand is
  refused too: that reading re-assembles identically and is still wrong, and two
  of the original blind five were control flow.
* **`computer_interface_pcg.s`: 526 B, nothing converted.** A programmable
  character generator's glyph data disassembles into beautiful nonsense; the
  pass refused all of it.
* **25 spans in `scoop_display.s` refused for containing a string literal.**
  This rule exists because this lane broke it first: the initial run of the
  re-frame pass turned 14 `.ascii` lines into instructions, among them
  `"TEMPO   "`, `"Y SHIFT="` and `"ADE-IN ON OFF"` — real UI text re-framed as
  code, byte-exact and invisible to the gate. Fixed in `481e047b`, and the two
  files were reset and redone rather than patched.
* **173 spans refused for not round-tripping.** The disassembler is not a
  bijection: it prints `and (xiz), sp` and `and sp, de`, which the assembler
  rejects. Every emitted text is assembled and byte-compared before it lands.
* **288 B with no anchor** on one side of the run — no address that is both a
  source line start and an instruction boundary in the new framing.

## Two failures worth keeping

1. **Overlapping spans deleted 30 label definitions.** Two `.byte` runs a few
   bytes apart resolved to overlapping line ranges; splicing both dropped what
   lay between. The BYTE GATE COULD NOT SEE IT — the bytes were still right —
   and it was the LINKER that objected (`undefined symbol`). Both tools now
   refuse any edit that changes the set of label definitions, and spans are
   merged before emission.
2. **`llvm-objdump` elides runs of zero bytes as `...`** unless given `-z`, so a
   span containing them came back half-covered. It raised instead of
   mis-emitting only because the helper asserts that the segments cover the
   span exactly.

## Gate

`make gate-all` green, 13 images, at every commit in this branch.
`v10_gate_sensitivity_probe.py` perturbs one `.long` this lane typed
(0xFD17AE) and one instruction it re-framed (0xFCFA5E), rebuilds, and shows
the first differing address is the perturbed one — then restores and rebuilds
to byte-identical.

⚠ The installed `llvm-project` build moved from the pinned `6fe210fb0a81` to
`6f456a19f05b` while this lane ran. Every number here was measured against the
installed build; re-measure before quoting.
