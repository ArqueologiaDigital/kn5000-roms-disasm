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
12. **"Unreferenced" in a partially converted tree does not mean dead.** A refusal audit found
   that 25 of 29 blocked ranges were held by labels nothing in `v7/maincpu/*.s` references, called
   them transplant artefacts, and proposed deleting them. Measured before acting: **8,203 of the
   9,975 v7 labels that nothing in v7 references ARE referenced in v9 or v10** -- `Memset` 47
   times, `MidiPkt_Nop` 185. They look unreferenced only because the code that jumps to them is
   still `.byte` data. `Audio_NullRet1` has eight `jr` referrers in v9 and none in v7 for exactly
   that reason. Deleting them would have removed the targets the next conversion round needs, and
   the byte-match gate would NOT have objected -- dropping an unused label changes no bytes.
   **Any "prune the unused X" step must ask what fraction of X is merely not-yet-reached.**
   (`scripts/analysis/v7_unreferenced_labels_are_live.py`)
13. **Byte-identity cannot tell code from data that happens to decode.** ⚠ THE MOST IMPORTANT
   ENTRY IN THIS LIST, because it limits the project's strongest check. `ToneKit_FrequencyTable`
   -- a frequency table -- decodes as `nop / swi 7 / max / ei 0x04 / ldwio / normal / halt`: seven
   valid instructions that re-assemble to the original bytes exactly. It would pass the 9/9 gate,
   because THE BYTES DO NOT CHANGE. Five such tables were about to be written into the sources as
   code. What would have been wrong is not the binary but the CLAIM, published with a green test
   behind it.
     * The cheap screens do NOT work, and both were tested: reference kind fails
       (`FileIO_BytecodeData` is also a `jrl` target and is 80 instructions of real code), and
       rarity fails (`swi` occurs 3,804 times in committed v7 code).
     * What works is implausibility in context -- CPU-control instructions (`swi`, `normal`,
       `max`, `halt`, `ldio`, `ldwio`) inside a short would-be routine. It fires on exactly six
       ranges: the five tables, plus one real routine whose `ei 0x06` is why `ei` is NOT in the
       set. Calibrate a screen against the case it would get WRONG.
     * Same family as anti-pattern 12: deleting an unused label also changes no bytes. **A strong
       gate concentrates risk into exactly what it cannot see.** Byte-identity proves the bytes
       are unchanged; it never proves the interpretation is right, and a disassembly is nothing
       but interpretation. (`scripts/analysis/v7_converted_range_screen.py`)
14. **The check that stops answering when the tree moves.** A committed producer satisfies L6
   only while it can still ask its question. Two happened on 2026-08-22, both quiet:
     * `convert_v7_ptr_tables.py --name-conflicts` measured 153 mis-located v7 names by
       cross-checking `.incbin` blobs. Converting those blobs to `.long <symbol>` -- a success --
       destroyed the evidence: it now reports `0 / 0`, which reads like "no problem" rather than
       "nothing left to examine". Re-deriving it needs a worktree at the older commit AND a full
       build of it, because that tree links to different addresses.
     * `no_label_was_dropped.py` compares HEAD with the working tree. Run on a clean tree it
       reports `0 files, 0 labels lost` -- a no-op that looks exactly like a pass.
   **A producer must distinguish "measured, and the answer is zero" from "could not measure".**
   When a fix removes the conditions its own evidence depended on, record the commit and the
   command needed to re-derive it, next to the number.
15. **A ROUNDED PASS IS NOT A PASS.** ⚠ THE MOST EXPENSIVE ERROR OF 2026-08-22/23, because it
   disabled the check everything else in this document leans on. `compare_roms.py` prints
   `Similarity: 100.00%` to two decimals -- in a 2,097,152-byte ROM that is **up to 104 differing
   bytes**. It does append `(N incorrect bytes)`, but the gate was written as
   `grep -c "Similarity: 100.00%"`, which MATCHES THAT LINE, because it is a prefix.
     * Every "gate 9/9" reported that day was that prefix match. 14 run logs contain
       `Similarity: 100.00%  (N incorrect bytes)`.
     * 981 label "repairs" were committed on a 9/9 that was really 22 wrong bytes in v7. The
       corruption was printed the whole time; the check read past it.
     * It also produced a false theory. Believing label moves were byte-neutral, I concluded the
       byte gate was "structurally blind" to them and built a two-verifier argument on that. Moving
       a label DOES change bytes -- through `.long <symbol>` entries in pointer tables -- and the
       gate was catching it.
   **Assert identity, never a formatted percentage.** `scripts/analysis/assert_byte_identical.py`
   compares bytes and exits non-zero; a percentage is for humans reading a report.
16. **The ROM outranks a cross-revision heuristic.** The same episode: a detector compared v7 bytes
   against the same-named routine in v9 and declared 3,474 labels displaced by 0x41A. The ROM's own
   pointer tables point at those labels' ORIGINAL addresses -- and of the moved labels that a
   pointer table can check, **11 of 11 contradicted the detector**. A name shared across two
   different programs is a hypothesis; a pointer the firmware dereferences is evidence. Check a
   claim about placement against the pointers before acting on it.
17. **"The tool cannot express this" has FOUR causes, and the report flattens them.** When a
   converter says a form is unspellable, that single line covers at least four different faults,
   each needing a different fix. Counts are from 2026-08-22/23 on the v7 spelling work:
     * **a spelling not tried** (7 occurrences) -- the form exists under a name you did not guess.
       `push WA` is the one-byte `0x28+r` short form and answers to `pushw`, not `push`;
       `cp WA,(imm)` is `cpda16 XWA, ...` because the operand class is GPR and the printed
       16-bit register name is not the name you write.
     * **a genuinely missing instruction** (4) -- `cpib_ind` had no mnemonic at all; the store
       direction existed at 0xF3/0x00 and the compare direction was never written.
     * **a lookup table too small** (1) -- `ld RL3,A` failed because the converter's REG_BYTE held
       32 of the 256 register bytes and the banked registers were absent. The backend was fine.
     * **an existing rule too narrow** (2) -- the register-indexed rule offered only mode `0x07`
       (16-bit index) so every 8-bit-indexed site failed; the direct-address ALU rule covered only
       16-bit registers so the 8-bit sites failed.
   ⚠ **Dump the bytes at the failing site before theorising.** unidasm's output is LOSSY BY
   CONSTRUCTION -- it drops exactly the bits that select the encoding: the sub-opcode (`00` byte /
   `02` word), the direction (`f1` vs `f9` for cp), the register width, a 16-bit zero displacement
   collapsed to `+0x00`. Reasoning from the mnemonic cannot recover them; six bytes settle it in
   seconds. Across this work the instinct "the backend is missing something" was wrong roughly
   twice as often as it was right.
18. **A failure that does not propagate.** Twice on 2026-08-22/23, in different disguises, a
   command reported success while the thing it ran had failed:
     * `make all 2>&1 | grep -c "Similarity: 100.00%"` -- the grep matched
       `Similarity: 100.00%  (22 incorrect bytes)` too, because that string is a PREFIX. Fourteen
       run logs carry the pattern; 981 bad label repairs were committed behind it.
     * `ninja llvm-mc | tail -2 && <test>` -- a pipeline's exit status is the LAST stage's, so
       `tail` succeeding let `&&` proceed after the build had failed. The test then ran against a
       22-minute-old binary, and its "unrecognized mnemonic" was read as evidence about a def
       that had never been compiled.
   Both look exactly like the command working. **Check the exit status of the thing you care
   about, not of the pipeline you wrapped it in** -- `set -o pipefail`, or run the build and the
   test as separate steps and read the build's own status. And when a result surprises you, verify
   the tool that produced it actually ran: `stat` the binary, look for the build line, print the
   count you expected to change.
19. **The gate that cannot pass.** The mirror of anti-pattern 1, and it hides work rather than
   faking it. A converter's re-check compared symbolic branches against a LINK-TIME PLACEHOLDER,
   so 361 ranges / 18,412 bytes -- seven times the entire remaining backlog -- were refused with
   the same message a genuinely broken range produces. Rejections concentrated in one bucket
   deserve the same suspicion as acceptances that never fail. **Of every refusal category, ask:
   could anything in this bucket ever pass?**
20. **The fixpoint nobody iterated.** Reachability analysis was written as a single pass: scan the
   already-disassembled CODE territory for `call`/`jp`/`jrl`, emit the targets, stop. But every
   range the converter accepts and byte-matches is newly-proven code, and the branches *inside* it
   name further addresses that are code by exactly the same argument. Feeding that back and
   iterating took the entry set from 687 to 1,209 in ten rounds -- a 76% expansion that had been
   sitting there since the analysis was written, invisible because the scan's output looked like
   an answer rather than a first approximation. **When an analysis derives facts of the same kind
   it consumes, it is a fixpoint. Ask how many times it was run.**
     * The discipline that keeps this honest: harvest only from ranges that pass every structural
       gate. A mis-framed decode's "branches" may be data bytes that happen to read as `jr`, and
       propagating those would grow the set with garbage that the byte gate cannot catch, because
       nothing about a wrong entry point makes the *bytes* differ. Here 254 destinations seen only
       in refused ranges were withheld for exactly that reason, and counted separately so the
       withholding is visible rather than silent.
21. **The constant that matched nothing.** A probe asked how many branch destinations land in
   `.byte` territory and printed a confident zero. The territory encoding is `1 = CODE`,
   `2 = .byte`, `3 = incbin`; the probe tested against `DATA = 0`, which matches nothing, so the
   filter discarded every candidate. The true answer was 266. This is anti-pattern 10 wearing
   different clothes -- a check that cannot fail versus a filter that cannot pass -- and the same
   remedy finds both: **before believing a zero, prove the code path can produce a non-zero.**
   Print the histogram of whatever you are filtering on. A named constant is not a verified one.
22. **The average that hides the exception.** The binary-include audit classifies each blob as a
   whole, so a structured region that is a small fraction of a large file cannot move the file's
   statistics. `naka_widget_descriptors.bin` (150,888 B) passed as OPAQUE -- "earns no better
   format on this evidence" -- while the comment printed directly above its own `.incbin` line
   documents four tables inside it, one of them 128 x u32 with 128/128 words landing in the ROM
   address range. A windowed re-scan found 45 such regions / 25,344 B across 391 blobs. **When a
   verdict is computed over a whole object, ask what fraction of that object could be wrong
   without changing the verdict.** For a 150 KB blob judged by byte statistics, the answer was
   "several kilobytes", which is to say the check had no power where it was most needed.
     * The correction has a milder form of the same defect and says so: the windowed scan aligns
       its windows, so the very table that motivated it (blob offset 0x1c1a) is not among the 45 it
       reports. A bound that is knowably loose must be published as a bound, not as a count.
23. **The check the subject can satisfy while being wrong.** Reachability's entry points are gated
   on structure -- at least 3 instructions, ends in a terminator, every instruction spellable, no
   implausible opcodes. Measured against a control that is WRONG BY CONSTRUCTION (an offset placed
   strictly inside an instruction), those gates pass **67.5%** of known-bad entries, slightly more
   than they pass real ones. The mechanism is the ISA: TLCS-900 self-synchronises, and 387 of 400
   wrong entries re-join the true instruction stream, 74% of them within 5 bytes. A wrong entry
   therefore prepends a couple of bad instructions to an otherwise correct function, and every
   structural check sees something well-formed. The byte gate is blind by construction -- the bytes
   are the same bytes.
     * The lesson is not "the gates are useless" (they remove the grossly broken cases) but **know
       which of your checks carries the confidence.** Here it is not the gates, it is PROVENANCE: a
       branch inside already-verified code makes its target an instruction boundary by
       construction. I had written that the gates made the closure sound; they do not, and the
       docstring is corrected.
     * And a control is only as good as its known-badness. The first control here was random
       offsets in `.byte` territory -- but that territory is mostly undisassembled CODE, so a large
       share of those offsets are genuine boundaries that SHOULD pass. It measured the wrong thing
       and had to be replaced with one that is wrong by construction.

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
- [x] **§3** every remaining `.incbin` is on the LEGITIMATE list, **with its format documented**
      -- ⚠ demoted 2026-08-22 and RESTORED the same day, on a different check. The old test
      justified 790 of 873 directives by directory name and could not fail; it was blind to
      61 blobs holding 8,440 B of ROM addresses. Those are now `.long <symbol>` (gate 9/9), and
      the audit itself runs the structure triage and exits non-zero on any blob still carrying
      pointer-table structure. Verified to FAIL against the pre-conversion tree, which is the
      only evidence that makes the PASS mean anything. Three blobs are exempted by name with
      their reasons -- notably a 16-bit drawbar table whose u16 pairs read as in-range u32s by
      coincidence.

The PROJECT is done when every ROM image is done. Until then, the honest report is per-ROM levels
plus the illegitimate-blob byte count -- never a single percentage, and never the gate alone.
