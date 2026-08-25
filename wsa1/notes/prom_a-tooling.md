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
argument passes. Read the ones it prints.

⚠ **AND IT IS A FIGURE ABOUT HEADED LABELS ONLY** — round-2 audit F10. A report
that writes "N labels, 0 without an Evidence line" without that word is claiming
something the script never measured: the internal labels are deliberately
excluded and there are more of them than of headed ones. Always quote the pair.
After round 3 (2026-08-25): **259 headed, 0 without an Evidence line; 327
internal**. The four gaps this round produced were all data headers that argued
their case as "ENTRY COUNT = 32, established rather than counted"; they were
given explicit `Evidence:` lines rather than an exemption, because the point of
the keyword is that a reader can find the argument.

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

---

# Five more, added 2026-08-25 (round 4), in `notes/`

Same rule: each answers one question and says so in its own docstring.

## `notes/prom_a_call_graph.py` — the frontier tool prom_a did not have

**"Which prom_a routines are published through the prom_b directory, heavily
referenced, and still `.incbin`?"** `notes/prom_b_call_graph.py` computes exactly
this ranking and then discards every prom_a answer — its rows loop carries
`if not (B_BASE <= tgt < A_BASE): continue   # prom_a target, other lane` — so
this lane had been choosing targets by eye. This is the mirror of it, sharing its
method so the two numbers are comparable.

```
python3 notes/prom_a_call_graph.py               # top unconverted targets
python3 notes/prom_a_call_graph.py --modules     # whole directory modules, ranked
python3 notes/prom_a_call_graph.py --module 0xF41CD0
```

`--modules` is the one to drive a round from: it groups runs of consecutive
directory slots and sorts by TOTAL references, because the module is the unit
worth converting and a 2 KB span reached by 126 slots is not the same target as
one reached by 3. ⚠ Reference counts are opcode-anchored upper bounds; they rank
slots and are never call counts.

## `notes/prom_a_ringbuf_map.py` — the ring library, read out of the ROM

**"What is 0xF84000-0xF84C6B, and how many ring buffers does CPU 1 own?"** It
matches the 25 class routines against exact byte templates, walks the 15 instance
groups, and cross-checks that every veneer of an instance names one object and
one capacity. 22 self-checks, including the RAM tiling that is the strongest
evidence for the field layout, and the searched negatives the headers rest on.
Its `all_refs()` — absolute `call`/`jp` plus PC-relative `calr`/`jr`/`jrl` over
both images — is reused by the two generators below.

```
python3 notes/prom_a_ringbuf_map.py
python3 notes/prom_a_ringbuf_map.py --veneers
python3 notes/prom_a_ringbuf_map.py --refs
```

## `notes/prom_a_linear_decode_check.py` — may this span be converted linearly?

**"Is a linear disassembly of this span self-consistent, or is there data in
it?"** Three tests: no undecodable bytes; the end is an instruction boundary of a
decode run PAST it; every directory entry into the span lands on a boundary, and
no in-span `call`/`calr` reaches an address that is not one.

```
python3 notes/prom_a_linear_decode_check.py 0xFE0000 0xFE54B6
python3 notes/prom_a_linear_decode_check.py --selftest
```

★ **Two things the selftest exists to keep visible.** The end test as first
written cut the file at the end address and checked the decode finished there —
which it always does, because unidasm cannot run off the bytes it is given. It
had already been written into a routine header before the control was run. And
the three tests do **not** pin the START of a span: re-running them one byte late
passes. `0xF86000-0xF8969B` is the negative control that really does fail.

## `notes/gen_prom_a_ringbuf_module.py` and `notes/gen_prom_a_block.py`

**"What source text goes into `prom_a/wsa1_prom_a.s` for this span?"** The first
is specific to the ring module, whose meaning is established; the second is the
general form, for spans where some routines are understood and most are not. Both
take every instruction from `prom_a/roundtrip.py`, so neither can break the gate;
what they add is labels, headers (from `notes/prom_a_ringbuf_headers.txt` and
`notes/prom_a_block_headers.txt`) and `.fill`/`.byte` regions.

```
python3 notes/gen_prom_a_block.py 0xF8BC00 0xF8C000 > /tmp/region.s
python3 prom_a/insert_region.py 0xF8BC00 0xF8C000 /tmp/region.s
python3 scripts/analysis/assert_byte_identical.py
```

⚠ Both REFUSE rather than guess: a `.fill` is emitted only if every byte of the
run really is `0x0E`, and a labelled block only if re-assembling it reproduces
the ROM. `gen_prom_a_block.py` also gives the first byte of a pad run back to the
code before it — `0x0E` is `RET`, so a naive run scan swallows the last routine's
own return, which it did on `0xF83215`, `0xF8BF21`, `0xF8DAB9` and `0xF8DDE5`.

## Correction to the section above: `(rr+r)` is no longer a `.byte` case

The "Cross-reference" section further up lists three shapes `llvm-mc` cannot
encode. **The register-indexed `(rr+r)` operand is not one of them any more.**
The macro prelude gained `MXB`/`MXW`/`MXL`/`MXD`, the `ra_*`/`rb_*`
register-address constants and eleven `mx_*`/`mx8_*` operation macros, all cited
to `dasm900.cpp:1543-1584` and `:1349-1405`, and `roundtrip.py` gained four
recognisers. 44 existing `.byte` lines in `prom_a/wsa1_prom_a.s` became named
macro calls in one pass. Still `.byte`: the shift-by-a-register forms and the
register-direct `s_allreg8` operand (`ld A,IZL`).

⚠ One of those recognisers had a real bug worth recording: `mul`/`muls` accepted
only MAME's `s_mulreg16` spelling of the destination, so the ten
`muls XWA,(XSP+0x08)`-shaped instructions — whose destination prints from
`s_reg32` because a word operand makes it a 16x16->32 multiply — were silently
left as `.byte`. The same operation byte, two MAME tables.

---

# Three more, added 2026-08-25 (round 5), in `notes/`

Same rule: each answers one question and says so in its own docstring.

## `notes/prom_a_audit_callsites.py` — the tool prom_a did not have

**"Does every address a prom_a `Called from:` line names actually START a
transfer to that routine — and if not, WHICH nearby address does?"** The round-2
audit's closing paragraph: *"three of the four worst findings are address and
identity claims in prose that no committed script reads. prom_c has the one tool
that closes that hole and prom_c is the image whose new citations came through
at 148-for-149. prom_a and prom_b have no such tool, and both shipped defects of
exactly the kind it detects."* This is prom_a's.

It is the mirror of `notes/prom_c_audit_callsites.py`, with three differences
that matter:

* it disassembles in **prom_a or prom_b**, chosen by range, because prom_a
  routines are called from both;
* a row that is not a call is **classified**, not just printed — `POINTER` (the
  32-bit word *at* the citation is the routine address: a vector- or
  pointer-table entry, legitimately cited), `THUNK` (that word is an address
  whose instruction transfers to the routine), `CALL-ALT` (it reaches a
  *different label of the same routine* — an alternate entry, which the prom_c
  tool reports as a false positive), or `OFF BY 1`/`OFF BY 2`, which is the
  defect it exists for;
* ⚠ **it knows nothing about any header's claim.** F2's checker hard-coded the
  +1 values it was supposed to catch and therefore could never fail; the
  `--selftest` here asserts that a real call site cited ONE BYTE LATE is
  rejected, and that the `-1` re-decode diagnoses it.

```
python3 notes/prom_a_audit_callsites.py
python3 notes/prom_a_audit_callsites.py --quiet     # only rows that are not CALL
python3 notes/prom_a_audit_callsites.py --selftest
```

Result 2026-08-25, after this round's headers: **301 cited sites — 179 CALL,
9 CALL-ALT, 37 POINTER, 8 THUNK, 68 unclassified, and ZERO off by one or two.**
The 68 are a list to READ: most are module bases (`T_F41CD0`), RAM addresses, or
addresses a header cites in a *searched-negative* sentence ("0xF830C5 is the
`ret` before, so it is not reached by fall-through").

## `notes/prom_a_jumptables.py` — the data a linear decode walks into

**"Where are prom_a's inline computed-jump tables, and how many entries has
each?"** They are why `prom_a_linear_decode_check.py` fails on a whole module:
the LE32 target table is emitted immediately after the `jp T,XBC` that reads it,
so a linear decode runs straight into it. The script finds the reader by its
shape (`add XBC,imm32` whose immediate is the address of the NEXT byte, then
`ld XBC,(XBC)`, then `jp T,XBC`) and takes each **entry count from the reader's
own `cp BC,n`** — the same discipline the prom_b lane uses for its dispatch
tables, and never a count by eye.

```
python3 notes/prom_a_jumptables.py                    # whole image
python3 notes/prom_a_jumptables.py 0xFAA000 0xFAC8E6  # one span
python3 notes/prom_a_jumptables.py --data             # @@DATA/@@LONG stanzas
python3 notes/prom_a_jumptables.py --selftest
```

**13 in the image**, 1044 bytes of `.long`. The selftest asserts one of them
(`0xFAC326`, 13 entries) *and its two negative controls*: 12 or 14 entries do
not land where the decode resynchronises.

## `notes/prom_a_frontier_delta.py` — slots are not targets

**"How many prom_a directory SLOTS — and how many DISTINCT TARGETS — are still
`.incbin`, for a named revision of the source?"** `prom_a_call_graph.py` prints
"top N of M" where M counts **slots**, and a round report quoted that M as a
count of *targets*. Round-2 audit F10. This prints both, from any git revision,
so a before/after pair is measured rather than remembered; `--vs-worktree` adds
the newly converted ranges and how many targets each retired, with a self-check
that every retired target lies in one of them, and `--by-block` repeats the
split at the finer per-block granularity a findings table uses.

```
python3 notes/prom_a_frontier_delta.py --rev HEAD --vs-worktree --by-block
```

## Changes to `notes/gen_prom_a_block.py`

* **`@@LONG lo hi Name`** beside `@@DATA`: emits one `.long` per 4-byte
  little-endian word with its index in a trailing comment, and REFUSES if the
  span is not a whole number of words. Use it only where the 4-byte framing is
  established by a reader; `.byte` stays the honest default.
* **A pass-1/pass-2 split, and a refusal.** The generator used to substitute
  `call sub_FAAE92` for `call 0xfaae92` on the strength of an opcode-anchored
  reference scan alone — for an address that is two bytes inside another
  instruction and therefore never gets a line. `ld.lld: error: undefined symbol`
  was the lucky outcome; the unlucky one is a label that lands somewhere
  plausible. It now decodes every code sub-region first, keeps only labels that
  a line will actually define, prints the dropped ones on stderr, and refuses to
  print at all if any `sub_XXXXXX` is referenced and never defined.
* **`.byte` fallbacks keep unidasm's text.** This file's own documentation says
  every `.byte` "carries unidasm's own text in a trailing comment"; the
  generator dropped it, and 14 lines of the 0xFAA000 module would have shipped
  as five hex bytes with no mnemonic. They now read
  `.byte 0xe2, 0x84, ... ; FAC198  e2 84 f2 60 ed   or (0x60f284),XIY`.

---

# Three more, added 2026-08-25 (round 3), in `notes/`

Same rule: each answers one question and says so in its own docstring. All three
print their own check count as their LAST line; that is the only figure to quote,
because this file has already been wrong about a hard-coded one.

## `notes/prom_a_div_runtime_check.py`

**"Where exactly do prom_a's 64-bit divide runtime and the KN5000 sub-CPU's
agree, and which KN5000 symbol name belongs at which prom_a address?"** It exists
because the round-2 audit's F4 and F5 were both address claims about that one
block: the header gave the divergence as the run's LAST identical byte, and it
placed the string `FP_UnsignedDiv_ShiftLoop` — a real KN5000 symbol, llvm-nm
0x3DCBB — 17 bytes past the 0xFE699A the block's own anchor maps it to, with
nothing saying a rename had happened.

It walks both ROMs forward and backward from the anchor pair rather than trusting
either header, and it found a fact neither tree had: there are **two** identical
runs, 170 bytes at 0xFE68F2-0xFE699B and 23 more at 0xFE69A8-0xFE69BE, so the
images differ in exactly one 12-byte window.

```
python3 notes/prom_a_div_runtime_check.py --selftest    # 27 checks, 3 controls
```

⚠ One control is worth keeping: `--selftest` asserts that the retracted claim
("the images diverge at the run's last byte") is REFUTED by the bytes. And the
corrected header deliberately does not quote the defective sentence verbatim,
because `notes/round2_audit_probes.py` searches the source for its exact text and
a quotation would keep that search failing for ever.

## `notes/prom_a_fc0000_module_check.py` and `notes/prom_a_fc8000_module_check.py`

**"Is every quantified sentence in this module's headers still true?"** — one per
module converted in round 3, 0xFC0000-0xFC2FFF and 0xFC8000-0xFCEFFF. Each is
named after the sentence it backs, reads the ROMs rather than the listing, and
re-decodes span by span (through `prom_a_linear_decode_check.decode`) so the
declared data regions never desynchronise the disassembler.

```
python3 notes/prom_a_fc0000_module_check.py --selftest   # 128 checks, 3 controls
python3 notes/prom_a_fc8000_module_check.py --selftest   #  77 checks, 4 controls
```

What they are for, beyond re-checking numbers:

* the ten handler-table declarations behind the 131-entry count are **parsed out
  of the decode**, not typed in, so an eleventh caller or a changed literal fails
  instead of passing for ever;
* every "no site names X" sentence is stated as **what the search returned**, not
  as a bare negative — 0xFC11E2's single hit is a `jrl` displacement computed
  from bytes inside the table's own last entry, and 0xFCC1FB's is a `calr` at an
  address that is the second byte of another instruction. Both are recorded as
  opcode coincidences rather than dropped;
* section 10 of the 0xFC0000 checker measures **the module this round did NOT
  take** — the longest `0x0E` run in 0xF86000-0xF8969A (4 bytes), the extent that
  follows from it (13,979), the 408 undecodable bytes in 12 clusters and the 24
  slots — so "left for next round" is a measurement rather than an excuse.

They caught real defects in headers written minutes earlier, and those are worth
naming because they are the kinds this tree keeps making: a slot cited as
`T_F413B4` that is actually `T_F413D0`; a module-total reference bound (52)
quoted as one entry's; `MIDI_PostSendWork` given prom_a 0xF8590F when it is at
0xFA590F; "24 published targets are a bare `ret`" when it is 34; "12 times in a
row" when it is 20.


---

# A defect in a SHARED tool, recorded because nobody owns it

`scripts/analysis/source_coverage.py:52` counts `.incbin` spans with
`text.count(".incbin")`, a SUBSTRING count over the whole file, so every mention
of the word in a comment inflates it. Round-2 audit F8 flagged it in all three
lanes and it is still there; `scripts/` belongs to another lane and this round
did not touch it. Measured 2026-08-25, after round 3:

| image | raw substring count | real `.incbin` directives |
|---|---|---|
| prom_a | 36 | **17** |
| prom_b | 140 | **124** |
| prom_c | 45 | **15** |

```
python3 - <<'EOF'
import re
for img in ('prom_a/wsa1_prom_a.s','prom_b/wsa1_prom_b.s','prom_c/wsa1_prom_c.s'):
    t = open(img).read()
    print(img, t.count('.incbin'), len(re.findall(r'^\s*\.incbin\b', t, re.M)))
EOF
```

The BYTE columns of `source_coverage.py` are unaffected — they are parsed from
the directives' operands, not from the substring count — so every coverage figure
in this tree stands. It is the span COUNT that is wrong, and the fix is one line
in a file this lane must not edit.