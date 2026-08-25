# The prom_a tools

They live in `prom_a/` rather than `scripts/analysis/` only because this pass was
scoped to `prom_a/` and `notes/`; `scripts/analysis/` belongs to another lane.
Whoever owns that directory next should move them and fold their entries into
`scripts/analysis/README.md`.

Each answers one question, and each says so in its own docstring too.

## `prom_a/roundtrip.py`

**"What source text, fed to `llvm-mc -triple=tlcs900`, assembles back to exactly
the bytes at 0xF8xxxx..0xF8yyyy?"**

```
python3 prom_a/roundtrip.py 0xF82CFF 0xF82E05           # per-instruction
python3 prom_a/roundtrip.py 0xF82CFF 0xF82E05 --stats   # + strategy counts
python3 prom_a/roundtrip.py 0xF82CFF 0xF82E05 --survey  # only what failed
python3 prom_a/roundtrip.py 0xF82CFF 0xF82E05 --block   # labelled, whole-block
                                                        # verified -- paste this
```

unidasm supplies the instruction boundaries and is the decode authority; four
candidate spellings are tried per instruction (unidasm's own text, llvm-mc's
disassembler text, a macro from the prelude in `prom_a/wsa1_prom_a.s`, and
`.byte`), and **every candidate is assembled and byte-compared before it is
printed**. `--block` additionally turns in-range branch targets into labels and
re-assembles the whole region to prove the labelled form still produces the
original bytes; it prints a loud refusal if it does not.

So nothing it emits can break the gate. It says nothing about what the code
*means* — names and headers are written by hand afterwards.

Typical outcome on real code: ~85% of instructions take unidasm's or llvm-mc's
own spelling, ~13% need a prelude macro, and 0-2% stay `.byte` with unidasm's
text in a trailing comment.

## `prom_a/insert_region.py`

**"I have assembly for 0xF8xxxx..0xF8yyyy — what do the surrounding `.incbin`
lines have to become so the image is still complete?"**

```
python3 prom_a/insert_region.py 0xF82CFF 0xF82EA2 region.s
```

The source is one 512 KiB image described by a chain of `.incbin` lines
interleaved with converted assembly. Getting that arithmetic wrong is the easiest
way to break the byte gate, so it is done here rather than by hand. Run the gate
afterwards; this script does not.

## `prom_a/kn5000_run_offsets.py`

**"Does a KN5000 payload file offset equal its sub-CPU address minus 0x400?"**
(No. It is `+0xEF00` above the first 256 bytes.)

```
python3 prom_a/kn5000_run_offsets.py              # the check; exits non-zero on failure
python3 prom_a/kn5000_run_offsets.py --proposals  # the corrected transplant table
```

Full argument, and what it invalidates, in
`notes/FINDINGS-kn5000-transplant-offset.md`.

## The macro prelude

Not a script, but the same kind of artefact: the block between
`; MACRO-PRELUDE-BEGIN` and `; MACRO-PRELUDE-END` in `prom_a/wsa1_prom_a.s`
defines the TLCS-900 memory-operand and LDC forms that llvm-mc's tlcs900 backend
has no encoding for. Every operation byte it emits is cited to the MAME
disassembler table it came from (`../mame/src/devices/cpu/tlcs900/dasm900.cpp`),
and `roundtrip.py` reads the prelude out of the ROM source itself, so the tool
and the image can never disagree about what a macro expands to.

⚠ The macros are byte emitters. The gate proves they emit the right bytes; it
cannot prove the NAME on a macro is the right mnemonic. That comes from the cited
tables, and every use in the ROM source carries unidasm's own text in a trailing
comment so the two can be compared by eye.

## Cross-reference: two of the prom_b lane's "cannot encode" cases are covered

`notes/llvm-mc-tlcs900-spellings.md` lists five shapes that `llvm-mc` cannot
encode and that the prom_b lane therefore emits as `.byte`. The macro prelude
handles two of them:

| bytes | MAME | with the prelude |
|---|---|---|
| `85 3F 07` | `cp (XIY),0x07` | `m_cp_mi8 MBI+r5, 0, 0x07` |
| `85 27` | `ld L,(XIY)` | `m_ld_rm MBI+r5, 0, r7` |

(checked with `prom_a/roundtrip.py`'s own assembler path; both produce exactly
those bytes). The other three — the register-indexed `(rr+r)` operand and the
shift-by-a-register forms — are still `.byte` here too; they need a second macro
family keyed on the register-address bytes, which nobody has written yet.

The prelude is not tied to prom_a: it is a block of `.macro`/`.equ` in
`prom_a/wsa1_prom_a.s` and could be lifted into `include/` for all four images.
It was not put there in this pass because `include/tmp95c061_sfr.inc` is shared
and another lane may be editing it.

---

# Five more, added 2026-08-24, in `notes/`

Same rule: each answers one question and says so in its own docstring. They are
in `notes/` rather than `scripts/analysis/` for the same reason the three above
are in `prom_a/` — that directory belongs to another lane — and whoever owns it
next should move all eight and fold them into `scripts/analysis/README.md`.

## `notes/vector_map.py`

**"For each of the 33 slots of the vector table at 0xFFFF00, what routine finally
runs?"** It follows the prom_b thunk the slot points at, and the SECOND-level
thunk two of those reach, and says whether the final target has a label, is
inside a converted routine, or is still `.incbin`. `--unconverted` narrows it to
what is left. Backs `notes/FINDINGS-interrupt-vectors.md`.

## `notes/swi7_service_table.py`

**"Of the 64 slots of `SWI7_ServiceTable`, how many are live, how many distinct
routines do they name, and how many are converted?"** It reads the table out of
the ROM. It exists because those numbers had been counted by hand and disagreed
with each other — a note said 35 implemented services, the table's own header
said 35 real and 29 dead, and the truth is 34 live, 30 dead, 34 distinct. Backs
the corrected text in `FINDINGS-display-controller.md`.

## `notes/lcd_command_census.py`

**"Every byte written to the LCD controller's command port 0x790001 — what are
they and where?"** It finds every `ld XIX/XIY/XIZ/XBC,0x00790000`, confirms with
unidasm that the instruction really is that load, disassembles forward to the
first return and collects the immediate writes to `+0x01`; then the same for the
24-bit direct form. It exists because the first census saw only the direct form
and therefore missed `0x4F CSRDIR DOWN` entirely. 13 bytes, 89 sites, 0 outside
MAME's SED1330 table.

## `notes/render_font.py`

**"Is what lives at `<base>` actually a character generator, and is it indexed by
ASCII?"** Renders a glyph as ASCII art at width 8 or 16, and `--ascii-check` asks
the sharp question — is code `0x20` blank and every code `0x21`-`0x7E` drawn.
Backs `notes/FINDINGS-fonts.md`.

## `notes/prom_a_xref.py`

**"Which sites in prom_a or prom_b name this address?"** — as `call`, `jp`, `lda`
or a bare 32-bit pointer. ⚠ It is an opcode-anchored scan at every byte offset,
not an instruction-boundary walk, so its hits are candidates and its counts are
upper bounds. The one thing it is exact about is ABSENCE: zero hits means no
site spells that address that way. That is how "this thunk and no other site"
appears in several headers below.

## `notes/prom_a_byte_checks.py` — the other half of the gate

**"The prom_a headers say `exactly five accessors`, `82 of those bytes are
equal`, `eight entries`, `three entries`, `nine bytes` — are they still true?"**

The byte gate proves the source rebuilds the ROM and is **blind to what a comment
claims**; this is the complement. Each check is named after the sentence it backs and
fails loudly. ⚠ **Do not quote a count from here** — this line said "133
checks", prom_a's banner said "232", and the number that actually ran on
2026-08-25 was **231**. The script prints its own count as its first line of
output; that is the only figure to quote. Some of what it pins:

* the CS0 device at `0x7B0004/5` really is reached through exactly five
  accessors, all inside prom_a `0xFE54B6-0xFE54EB`;
* `LCD_BlitGlyph8_ExtraWait` really is `LCD_BlitGlyph8` plus one nine-byte busy
  poll, with 82 identical bytes after it;
* `LCD_LayerBasePtr_Table` really is three entries pointing at `(0x2541)`,
  `(0x2543)`, `(0x2545)`, and the byte after it really is SWI7 slot `0x05`'s
  target;
* both edge-mask tables really are `0xFF >> k` and `0xFF << (8-k)`, and both
  dither tables really are `0xCC` shifted and `0xCC` rotated;
* the link selector-1 table at prom_b `0xF57D4F` really is eight in-range
  addresses, and the entry table at `0xFE3000` really is eight `jp nnn`;
* all ten text services really load the font base this tree says they do and are
  really pointed at by the SWI7 slot this tree says they are;
* and five of the ten fonts really pass the ASCII test while the other five
  really do not.

```
python3 notes/prom_a_byte_checks.py        # exits non-zero on any failure
python3 notes/prom_a_byte_checks.py -v     # print all 133
```

Round 2 added checks for every sentence the audit made us rewrite: the 22 bytes
of `Int_Mul32` and their single KN5000 occurrence (the KN5000 half is skipped
loudly if the sibling ELF is missing, never silently passed); the control
register each micro-DMA setter's second argument reaches, and its operand width;
the three `DMA3V := 0x0A` writes and the one `DMA0V := 0x0E`; that vector slot
`0x28` is *not* the hang; that **eight** slots are, and which eight; and the
five structural facts behind the new `DSP_Init_Channels`. Round 2's new
territory brought its own: the two micro-DMA direction setups register by
register, and the ten `Dev7A_StartDma` command codes — **parsed out of the
compare chain by the check itself**, so a miscount or a changed literal fails
instead of passing forever; the scheduler's three ready-queue heads and the
node layout; the 38 bytes `Kernel_YieldRotate` and `Kernel_RotateQueue` share
**and the fact that the run is exactly 38** — the byte either side differs; and
every field of `EntryPoint_Records` in both prom_a and prom_c, so the
"seven records, +8 always 0x8800, +10 always 1..3" claim is a script's output
and not a reader's addition.

★ **Round 2 also put every "nothing references X" sentence under it.** A searched
negative is a claim about a search, and the one that had to be retracted in round
1 was made by a tool that could not have found the answer. The checks now
re-derive each such sentence from the ROM — the 3-byte little-endian address at
every offset of prom_a + prom_b (which covers `call`, `jp`, `lda`, a bare LE32
pointer and any 24-bit memory operand) plus every PC-relative `calr`/`jr`/`jrl`
displacement in prom_a resolved to its target.

It immediately failed **two** headers written minutes earlier in this same round:
`Kernel_RotateQueue` is published through prom_b thunk `0xF42D78`, and
`Dev7A_StartDma` has four `calr` callers, not none. Both are corrected in the
source, and the corrected positives are now pinned by checks of their own — a
negative that a script cannot reproduce should not be in a header.

Run it with the byte gate, not instead of it. Neither one catches what the other
does.

## `notes/prom_a_evidence_census.py` — which names have no stated evidence

**"Which prom_a labels carry a semantic NAME but no `Evidence:` line above
them?"** The round-1 audit counted 25 of 84 and noted the raw count over-states
it, because a routine's INTERNAL labels were never meant to carry one. This
script separates the two cases, so the number in a report is a number about
headers:

* **HEADED** — the label is introduced by its own `; ---- … ; ----` block whose
  first lines name it. These must say `Evidence`.
* **INTERNAL** — the label sits inside an earlier headed routine with no header
  of its own. Reported separately, never counted as a gap.

```
python3 notes/prom_a_evidence_census.py            # summary + the gaps
python3 notes/prom_a_evidence_census.py --all      # every headed label
python3 notes/prom_a_evidence_census.py --internal # the internal ones too
python3 notes/prom_a_evidence_census.py --selftest # asserts known-good cases
```

⚠ It is a KEYWORD test, not a judgement: a header that argues its case in prose
without the word is reported as a gap, and a header with the word and a bad
argument passes. Read the ones it prints. Result 2026-08-25: **176 headed, 0
without an Evidence line**; 180 internal.

## `notes/prom_a_addr_census.py` — every spelling, not one

**"Which instructions in prom_a + prom_b touch memory address X?"** The
TLCS-900 writes an absolute address in twelve ways — prefix groups `0xC0`
(byte), `0xD0` (word), `0xE0` (long), `0xF0` (memory-destination), each with an
8-, 16- or 24-bit address field (`dasm900.cpp:1525-1543`). Two headers in this
tree searched **one** of the twelve and then wrote "every site that touches it".

Each byte hit is then filtered by backward-disassembly convergence: how many of
the 64 preceding start offsets step exactly onto the site. The separation is
clean rather than marginal — on the two addresses it was written for, real
instructions score 17-64 out of 64 and every byte coincidence scores 0.

```
python3 notes/prom_a_addr_census.py 0x00008A
python3 notes/prom_a_addr_census.py --selftest   # asserts the (0x8A) and (0xBE) lists
```

⚠ Convergence is a filter, not a proof: 0/64 has not shown a site is data, and
64/64 has not shown it is reached.

## `notes/prom_a_sibling_short_runs.py` — the routines the transplant floor hides

**"Which complete KN5000 sub-CPU routines appear verbatim in a WSA1 image, at
any length?"** `scripts/analysis/transplant_kn5000_labels.py` has `MIN_RUN = 48`;
the runtime multiply at `0xFE68DD` is 22 bytes, so that tool was silent about it
and a header turned the silence into "no counterpart in the KN5000 sub-CPU".
There is one.

This scan is anchored on the sibling's symbols instead of on every k-mer: for
each KN5000 symbol it takes the symbol's whole extent up to the next symbol and
looks for those exact bytes in the WSA1 image, so a hit is a COMPLETE sibling
routine rather than a fragment. A distinct-byte-count guard drops fill.

```
python3 notes/prom_a_sibling_short_runs.py                 # prom_a, floor 12
python3 notes/prom_a_sibling_short_runs.py --image c --min-run 8
python3 notes/prom_a_sibling_short_runs.py --selftest      # must find FP_MulAccum64
```

Results 2026-08-25 — and the last two lines are the null that makes the first
two mean something:

```
prom_a  9 routines at floor 12,  20 at floor 8
prom_c  ...                      77 at floor 8
prom_b  0 at floor 8
prom_d  0 at floor 8
```

prom_b and prom_d share **nothing** with the sibling at an 8-byte floor, so the
prom_a and prom_c hits are not what a scan of this shape returns by default.
