# What it means for a disassembly effort to be DONE

Status: normative. Written 2026-08-21 after a completeness claim ("the disassembly is done")
was challenged and did not survive contact with the numbers.

## 0. Why this document exists

The project reports `Similarity: 100.00%` on every build target. That number is the reason this
document is needed, not a substitute for it. **A byte-match gate proves that the build emits the
same bytes as the ROM. It says nothing about whether anyone understands those bytes**, because a
build that emits one giant `.incbin` of the original ROM also scores 100.00%.

A disassembly effort is not a transcription exercise. Its product is not a listing; it is a
COMPLETE, INDEPENDENTLY USABLE DESCRIPTION of a machine's software: what every byte is, what every
routine does, what shape every data structure has, what every protocol says, and what every asset
looks like. The listing is one artefact of that, and not the most valuable one.

## 1. The unit of completion

Completion is assessed **per ROM image**, and within a ROM **per byte**. There is no partial credit
at the ROM level: a ROM is done when every one of its bytes has passed the tests below. Percentages
are for tracking progress, not for declaring victory.

Every byte of every ROM is in exactly one TERRITORY:

| territory | definition |
|---|---|
| CODE | executed as instructions by some processor |
| DATA | read by code as a structure: tables, records, descriptors, pointers, constants |
| ASSET | content authored for a human: glyphs, icons, bitmaps, text, sounds, music |
| PADDING | filler with no semantic role -- must be PROVEN filler, not assumed |

"I have not looked" is not a territory. Unclassified bytes count as UNKNOWN and block completion.

## 2. The seven levels

A ROM is DONE when it satisfies L0 through L6. Each level is independently checkable, and each has
a measurement, not an opinion, attached to it.

### L0 -- Byte-exact reproduction, non-circularly

The build reproduces the ROM byte for byte, **and the comparison is capable of failing**.

This second clause is the whole content of L0. A build that copies slices of the original ROM into
its own inputs cannot fail the comparison, so its 100.00% carries no information. The test:

> For each build input, ask: if the source were WRONG, would the gate notice? If the input is
> derived from the ROM at build time, the answer is no, and those bytes are NOT reproduced -- they
> are echoed.

Every byte must be attributable to a source that a human wrote or that a compiler produced from
source a human wrote. Byte counts that are echoed rather than reproduced MUST be reported
separately and never folded into a coverage headline.

### L1 -- Territory: every byte classified

Every byte is assigned a territory (§1), with the evidence for the assignment recorded. Padding
must be demonstrated -- typically by showing the region is unreferenced AND uniform -- not inferred
from its appearance.

**Measurement:** bytes per territory per ROM, plus bytes still UNKNOWN. UNKNOWN must be zero.

### L2 -- Code: decoded and named

For CODE territory:
- every instruction decodes, and the assembler re-emits it identically;
- every routine has a SEMANTIC name -- one that says what it does for the machine, not where it
  lives. `FDC_Seek` is a name; `LABEL_EF34FB` and `sub_1234` are addresses wearing a name's clothes;
- every routine has a header comment giving its purpose, its inputs and outputs (registers and
  memory), its side effects, and the hardware it touches;
- every entry point is known, including those reached only through jump tables or computed jumps;
- names are CONSISTENT across firmware revisions and across the symbol reference files, so a name
  means the same thing everywhere it appears.

**Measurement:** routines named / total; routines with a complete header / total; address-shaped
names remaining (must be zero); symbol-reference rows that disagree with the build (must be zero).

### L3 -- Data structures: specified, parsed, and round-tripped

For DATA territory, for each distinct structure:
- a FIELD-LEVEL SPECIFICATION: offset, width, signedness, endianness, units, valid range, and
  meaning of every field, plus the record stride and the record count and how the count is found;
- the relationships: which field points at what, which index selects what, what the invariants are
  (and any self-checks the format carries);
- a committed PARSER that reads the structure out of the ROM and reports it in readable form;
- a committed EMITTER that regenerates the ORIGINAL BYTES from the readable form.

The emitter is not optional and it is not busywork: **a structure you can read but cannot rebuild
is a structure you have not finished understanding.** The round-trip is what converts a belief
about a format into a proof, and it is what lets the structure replace a blob in the build.

Special cases that do NOT satisfy L3:
- a parser whose output is only "here are the bytes, grouped";
- a specification that exists solely as code (see §4);
- a format where some fields are described as "unknown", "unused" or "always 0x00" without evidence
  that they are actually ignored by the firmware.

**Measurement:** structures with a field-level spec / total; with a parser; with a round-trip.

### L4 -- Assets: extracted to their native human form, and round-trippable

For ASSET territory, each asset is exported to the form a human would naturally use for it:

| asset | required form |
|---|---|
| font | a glyph sheet or standard font format, with the encoding/codepage mapping stated |
| icon, bitmap | image files, with dimensions, stride, bit depth and palette stated |
| screen layout | a readable description of the elements and their geometry |
| text, strings | text files, per language, with the character encoding stated |
| music, demo, style, rhythm | a readable event listing, or a standard format such as MIDI |
| sampled audio | audio files, with sample rate, bit depth and encoding stated |

Each asset class also needs the EMITTER of L3: the exported form must rebuild the original bytes.
The exported artefacts must be COMMITTED, not merely producible -- an extractor that has to be run
before anyone can see what the machine looked like leaves the asset undocumented in practice.

**Measurement:** asset bytes exported / total asset bytes; classes with a round-trip / total.

### L5 -- Protocols, algorithms and formats: reimplementable from the documentation

For every protocol the machine speaks, every non-trivial algorithm it implements, and every file
format it reads or writes, there is a document from which **an independent implementer could build
a working implementation without reading the disassembly.** That means:
- the wire/record layout, field by field;
- the state machine: states, events, transitions, and who initiates;
- timing and ordering requirements, and what happens when they are violated;
- error handling and edge cases;
- at least one worked example traced end to end.

This is the level most often skipped, because the knowledge feels present -- it is in the header
comments, spread across forty routines. Spread-out knowledge is not a specification. The test is
the implementer test above, and it is a high bar on purpose.

**MAKE THE TEST EXECUTABLE.** The implementer test reads like something a reviewer judges. It is
not: write a reader from the document alone, sharing no code with the project's own tooling, and
check that it agrees with the artefact. Keep the document's sentences in it as comments so anyone
can verify nothing was smuggled in from the disassembly. `tests/l5_reimplement_style_format.py` is
the worked example -- it reproduces 1564 cells, 1050 chains and 50,245 events from
`accompaniment-style-format.md` and nothing else.

A grade nobody can run is an opinion. A grade with a failing test is a bug report. A grade with a
passing test is evidence, and it stays evidence when the document is edited later.

Note what such a test can and cannot establish. It proves a description sufficient to READ the
data. It cannot prove the description of what the data MEANS -- there is nothing to check that
against but the machine -- so L5 needs both the passing test and the semantic content, and a
format can pass the test while its field meanings remain open.

Codecs deserve an explicit note: identifying a compression format is not the same as documenting
it. A codec is done when there is a committed DECODER and a committed ENCODER, and the encoder
reproduces the original compressed bytes.

### L6 -- Evidence: every claim re-derivable, no claim outstanding

- Every number quoted anywhere -- header comments, docs, commit messages, notes -- is produced by a
  COMMITTED script, and the script says which question it answers and how to run it.
- Every uncertain claim is MARKED as uncertain where it appears, not silently asserted.
- The set of open questions is enumerated in one place, with what would settle each.
- There are no contradictions between two documents, or between a document and the source.
- Claims that came from a measurement of an EMULATOR are labelled as such, and never presented as
  facts about the hardware.

**Measurement:** unmarked inferences (must be zero); contradictions (must be zero); quoted numbers
without a committed producer (must be zero).

## 3. The binary-include rule

This is the sharpest single test of completeness, and the easiest to apply.

> **A `.incbin` is legitimate only if the bytes have NO better human-readable representation.**

A binary include is a statement: "this is irreducibly binary." That statement is true for very
few things:

**LEGITIMATE** -- may remain a blob, provided its format is documented and a committed script can
decode it:
- a compressed stream, where the codec is documented and has a decoder AND an encoder;
- sampled audio (PCM);
- measured coefficient tables with no derivable closed form, where the derivation is documented;
- a genuine unknown that is HONESTLY LABELLED as not yet understood -- legitimate as a temporary
  state, and it blocks completion.

**ILLEGITIMATE** -- must be converted before the ROM can be called done:
- anything with an obvious typed representation: a table of records is `.short`/`.byte` with a
  comment per field, or better, a generator from a readable source;
- text and strings;
- fonts, icons, bitmaps, screen layouts;
- music, styles, rhythms, sequences;
- code. A blob of instructions is the most serious case: it is undisassembled code hiding inside a
  build that reports 100.00%;
- **a slice of the original ROM injected at build time.** This is not an include, it is the gate
  being told the answer (see L0).

The procedure for every `.incbin` in the tree: classify it into one of the two lists above. If it
is in the second, it is a work item. The count of illegitimate blob bytes is the single most
honest progress metric this project has.

## 4. A script is not a specification

A recurring failure: the format is "documented" in the sense that a Python script parses it.

A script encodes ONE reading of the format and is silent about everything the author did not need.
It does not say which fields are optional, what the valid ranges are, what the invariants mean, or
why the layout is the way it is. It cannot be checked for consistency, and it rots against the ROM
without saying so.

Scripts are REQUIRED (L3 needs a parser and an emitter). They are not SUFFICIENT. Every structure
needs prose that a human can check the script against.

## 5. Anti-patterns that fake completion

Each of these has occurred in this project and been corrected; they are listed so they are
recognised faster next time.

1. **The circular build.** ROM slices injected as build inputs, so the gate cannot fail. Detect by
   asking of every input: could this ever disagree with the ROM?
2. **The one-way extractor.** An asset is exported but cannot be rebuilt, so it can never replace
   the blob and is never checked against the ROM again.
3. **Coverage by percentage.** "59% source" sounds most of the way there. The remaining 41% is
   where all the hard, unknown material is; the easy bytes go first, so progress percentages are
   systematically optimistic.
4. **The confident header.** Prose asserting a fact that was an inference. Marked inferences are
   cheap; unmarked ones cost a later reader a wrong belief they cannot detect.
5. **Names that are addresses.** `LABEL_EF34FB` satisfies a symbol count and communicates nothing.
6. **The stale reference.** A symbol file that no longer matches the build, still being consulted.
   Measure agreement with the build; if it is not near 100%, say so where the file is used.
   ⚠ 2026-08-22 -- there is a SECOND form that a staleness check cannot see: a reference that
   matches its build perfectly and describes **the wrong revision**. `maincpu_symbols_reference.txt`
   agrees with the v10 ELF 100.00% and with the v7 ELF 25.96%, has no revision in its name, and is
   consulted for all three links. "Agrees with its build" and "answers the question being asked"
   are different properties, and only the first was being measured. A shared name across revisions
   is the tell.
7. **Measured-on-the-emulator, reported-as-hardware.** The emulator is a hypothesis about the
   hardware. Numbers taken from it describe the hypothesis.
8. **Byte-match as the headline.** It belongs in the report, as L0, next to the echoed-bytes count.
9. **The unstated search window.** ⚠ THE MOST EXPENSIVE ONE IN THIS PROJECT: eight documented
   claims were retracted in a single day and every one had the same shape -- a search that could
   not express what it was looking for returned a clean zero, and the zero was recorded as a fact
   about the hardware.
     * `"LSW"` searched in uppercase; the ROM writes `Lsw` (`PreLswLoad`, `0xE1F726`). Conclusion
       recorded: "no KN5000 code reads or writes `.LSW` contents".
     * A parameter-id scan limited to `0x4000..0x4FFF`; the ids were at `0x8200/0x8600/0x8A00`.
       Conclusion recorded: "these tags carry no parameter descriptor".
     * A path resolver testing `is_file()` and silently skipping misses; 283 of 288 targets
       vanished and it reported a clean, small, wrong total.
     * A recursive `grep` (ugrep `-I`) skipping the 65 of 506 sources holding bytes above 127.
   The damage is never the failed search -- it is that the zero gets REASONED ONWARD. "No
   descriptor found" became "therefore not UI-editable", about a page whose ROM title is
   `DRAWBAR SETTING`. **Rule: a negative result must state its window in the same sentence.**
   "Not found by X over Y" is falsifiable; "does not exist" is not, and only one of them is a
   measurement.
10. **The control that could not have failed.** A negative control must be drawn from a
   distribution capable of exhibiting the defect. A blob classifier here was validated against
   `os.urandom` and stayed 100% clean while its pointer rule was counting every small integer as
   an address -- a uniform `u32` lands in the bad range with probability 1/4096, so the control
   was incapable of failing. Reshuffling the REAL blobs' own bytes (same distribution, no
   arrangement) exposed it at once. **Before quoting a control, state what result would have
   falsified it.**
11. **The check that assembles instead of verifying.** An instruction that assembles cleanly can
   still be the wrong instruction. Two TLCS-900 backend defects survived for months because both
   forms were reachable and produced valid bytes under swapped names -- 4,693 sites named a byte
   STORE where the CPU computes an ADDRESS. A missing form fails loudly at assembly time; a wrong
   sub-opcode assembles and lies. **Compare the mnemonic against what the ROM does, never against
   whether it assembled.**
12. **The gate that cannot pass.** The mirror of anti-pattern 1, and it hides work rather than
   faking it. A converter's re-check compared symbolic branches against a LINK-TIME PLACEHOLDER,
   so 361 ranges / 18,412 bytes -- seven times the entire remaining backlog -- were refused with
   the same message a genuinely broken range produces. Rejections concentrated in one bucket
   deserve the same suspicion as acceptances that never fail. **Of every refusal category, ask:
   could anything in this bucket ever pass?**

## 6. Definition of done

A ROM image is DONE when all of the following are true, each backed by a committed measurement:

Status as measured on 2026-08-22 (evidence and the runnable check for each row are in
`docs/IS-IT-DONE.md`; this list is kept in sync with that scorecard deliberately, because the two
had drifted apart once already).

- [x] **L0** every byte reproduced from real source; echoed-byte count is ZERO
      -- `rom_provenance_poison.py all`, 0 copied bytes on v7/v9/v10
- [x] **L1** every byte classified; UNKNOWN bytes ZERO; padding proven
      -- `l1_territory_map.py v7 v9 v10`, totals equal the rebuilt ROMs to the byte
- [ ] **L2** every routine semantically named with a complete header; address-shaped names ZERO;
      symbol references agree with the build
      -- references regenerate from the build and match 100%; naming coverage effectively
      complete. NOT MET on APTNESS: two decidable classes are now checked by script
      (`l2_name_vs_fopen_mode.py`, `l2_name_vs_return_value.py`) and found 5 wrong names, but a
      name that declares nothing checkable cannot be tested this way -- `FileIO_ReadHeader`
      builds a file path and never reads a header, and scores as semantic either way.
- [ ] **L3** every data structure has a field-level spec, a parser, and a round-trip emitter
      -- `.LSW` closed to a residue on 2026-08-22 (container, 24 panel-memory slots, drawbar
      tags 0x44/0x45/0x46, tag 0x71 role). OPEN: why format 2 imports 10 of 24; the 0x30 gap at
      0x4E80 and the 0xC0 at 0x53C0; what `"M4"`/`"NN"` are; several tags still shape-only.
- [x] **L4** every asset exported to its natural form, committed, and round-trippable
      -- seven converters in `scripts/build/`, each `verify` asserting ROUND TRIP EXACT
- [ ] **L5** every protocol, algorithm and format reimplementable from the documentation alone
      -- CP-serial specified from firmware on both sides. NOT MET: four items need a logic
      analyser on real hardware, and the NOTE2 question lives on other equipment entirely.
- [x] **L6** every quoted number has a committed producer; unmarked inferences ZERO;
      contradictions ZERO; open questions enumerated in one place
- [ ] **§3** every remaining `.incbin` is on the LEGITIMATE list, **with its format documented**
      -- ⚠ DEMOTED 2026-08-22, having been recorded as PASS. `audit_incbin_legitimacy.py`
      reports 0 illegitimate bytes, but 790 of its 873 directives are justified by ONE rule:
      the target sits under `generated/` or `romslices/`. That is a PATH-PREFIX test -- for
      those 790 it cannot fail, which is anti-pattern 12 in the list above, in the project's own
      completeness audit. Measuring the blobs instead (`l3_slice_structure_triage.py`) leaves
      **61 files / 8,440 bytes of pointer tables** whose better form is `.long <symbol>` and
      whose format is NOT documented. The second half of this row -- "with its format
      documented" -- was never being checked at all.

The PROJECT is done when every ROM image is done. Until then, the honest report is per-ROM levels
plus the illegitimate-blob byte count -- never a single percentage, and never the gate alone.
