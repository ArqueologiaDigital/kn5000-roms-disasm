# SX-WSA1R disassembly — resume here

**Wave 7 ran twelve rounds on 2026-08-28/30 and STOPPED AT THE USER'S INSTRUCTION, not because it
finished.** Read this before starting anything.

---

## Where it actually stands

    python3 scripts/analysis/assert_byte_identical.py      -> PASS, from a make clean
    python3 scripts/analysis/source_coverage.py            -> 1,555,395 substantive (74.2%)
    python3 notes/wave7_documentation_metrics.py           -> the goal metric

  image      content   framed  sub_XXXX    LOWER    UPPER   headers  evidence  internal
  prom_a       1,499      225     2,786    33.2%    38.2%     1,309     1,398       138
  prom_b       1,257    2,950     1,899    20.6%    68.9%     3,423     3,413         2
  prom_c         703      500       367    44.8%    76.6%     1,097       873     4,851
  prom_d       3,430      235         0    93.6%   100.0%     2,228     2,086         0
  TOTAL        6,889    3,910     5,052    43.5%    68.1%     8,057     7,770     4,991

**Byte-matching is perfect and was green at every one of the ~25 commits.** Cross-referencing is
done. **Documentation is 43.5% at the lower bound and that is the open half of the goal.**

★ LOWER and UPPER BRACKET the truth; neither alone is the answer. LOWER counts only names that say
what a thing IS; UPPER counts a kind-plus-address as understood. The tree's one hand-graded sample
landed at 28% of its UPPER figure.

## What is left, in order of size

* **prom_b: 51,246 bytes still `.incbin`** across 117 spans, plus 1,899 `sub_XXXXXX` and 2,950
  framed. It is the whole remaining territory frontier.
* **prom_a: 2,786 `sub_XXXXXX`**, the largest block of unnamed routines. It moved ~0.7 points a
  round for five rounds; that rate does not finish it, and THE CENSUS DELIVERABLE IS STILL OWED —
  a complete mechanical classification of all 2,786 with the bucket sizes published INCLUDING the
  last one ("N have no distinguishing evidence of any kind, and this script decides that").
* **prom_c: 367 `sub_XXXXXX` + 500 framed, and it is INVENTORIED** —
  `notes/prom_c_finish_round12.py` classifies all 867 non-content objects by which mechanism fires.
  ★ All 367 remaining `sub_XXXXXX` carry a header AND an Evidence line, which no other image can
  say. Its lower bound is now structurally capped: on 70 of the 192 objects a mechanism reaches,
  what separates the object from a >=90%-identical sibling is an IMMEDIATE, and round 11's test
  says such a number is not a name.
* **prom_d: 235 framed, zero `sub_XXXXXX`, 93.6%.** Closest to done.

## The mechanism that works, and the two rules around it

    NAME AN OBJECT FROM WHAT IT CONTAINS, FROM WHAT READS IT, OR (for a pointer) FROM WHAT IT
    POINTS AT -- and where none of those reaches, sub_XXXXXX or framed WITH A STATED GAP.

* ★ **A number belongs in a name only when it has a referent OUTSIDE the code.** `SoftKeyCol1`
  passes (the manual prints "SOFT KEY col 1 lower"); `Dispatch_F54248_Arm3` does not. The reasoning
  is in `notes/wave7-round1/APPLIED.md`.
* ★ **Converting data LOWERS understanding.** Round 7's splice added 122 labels, all framed, and
  prom_b's LOWER fell. Convert where a span unlocks NAMES, not to move coverage.

## The panel chain, solved end to end — the wave's main structural result

* **Layer 1 (wire):** segment = switch-matrix COLUMN, bit = ROW, `SW = 8*segment + bit + 1`, all 58
  fitted switches. Read off **page 32 of the service manual**, which has NO TEXT LAYER and must be
  read as images. `notes/wave7_panel_button_codes.py --physical`, 31/31.
* **Layer 2 (event):** ROM TABLES, not a computation — `PanelGroupEventLists_Variant1/2`, four-byte
  `[class][code][shift][mask]` records. `notes/wave7_panel_event_index.py`, 70/70.
* **The SX-WSA1R is VARIANT 2**, proved three independent ways. All three holes round 10 left open
  were symptoms of reading variant 1 against it. `notes/wave7_panel_names_round11.py`, 93/93.
* ⚠ **TWO TABLE FAMILIES, TWO INDEX RULES.** The 32-entry prom_b button tables index on the RAW
  code via prom_a `sub_F8BDC5`. `sub_F55019`'s 23-slot remap belongs to prom_a's four 23-entry
  tables. A round-11 briefing welded them into one chain and was wrong.

## Still open, with the shortest path named

* **Nobody produces code 0x0E**, and round 10's hypothesis (the seven appenders) is ELIMINATED.
  What is not covered: an event record built byte by byte rather than by an immediate.
* **The 374 P7Stream_* pool objects** need a payload decoder or an outside document — NOT the
  directory, whose descriptor pair is a field LAYOUT, not a name.
* **prom_d's base address.** `prom_d.ld` argues ORIGIN 0 is a decision, not an admission. ⚠ Do not
  change it on an inference.
* **PB.0 strap:** the variant identification is a contrapositive. Felipe owns real hardware;
  measuring PB bit 0 on a WSA1R main board would turn four converging inferences into a
  measurement.

## ⚠ Process failures this wave, so they are not repeated

* **I assigned two lanes to prom_c in round 12.** The file-disjointness rule exists because each
  image is one multi-MB `.s`. The lane detected the collision and reported it; both survived by
  luck. Check the lane list against the file list before launching.
* **The documentation metric was wrong FIVE times** — it counted framing as understanding, counted
  4,975 jump targets as debt, counted 168 descriptive branch labels as content, had a check pinned
  to a number meant to move, and measured whitespace. Three of the five made the tree look better
  than it is. `notes/wave7_documentation_metrics.py --selftest` is 37 checks.
* **A hand-edit to `prom_d/wsa1_prom_d.s` is silently reverted** — it is GENERATED. Every prose
  change goes in `scripts/analysis/gen_prom_d_asm.py`, and prefer DERIVING a claim over asserting
  it.

## The rule that has not changed

**The gate is the only thing that certifies this tree, and it is blind to every name and header in
it.** Every quantified claim needs a committed script, tested on the LAST element as well as the
first. Every semantic name needs an `Evidence:` line. **Prefer `sub_XXXXXX` plus a stated gap over
a plausible guess** — and a MEASURED REFUSAL is a first-class deliverable. Three of them paid off
directly this wave: round 9's refusal to guess layer 2 is what let round 10 solve it, and round
10's three written-down holes are what let round 11 see they were one error.

## The one rule that matters

**The gate is the only thing that certifies this tree.**

    python3 scripts/analysis/assert_byte_identical.py

It must print `PASS: every rebuilt ROM is byte-identical.` after **every** edit and at **every**
commit. It rebuilds first and compares bytes — never substitute a similarity percentage, and do
not use `--no-build` unless you have just built. Both shortcuts have already cost the sibling
project real retractions; the reasons are in the script's docstring.

Commits also need the `LLVM: <branch>@<short> (<full>)` line (enforced by `.githooks/commit-msg`).
Current pin: `tlcs900_backend @ bcf152d1fe00`.

## ⚠ The rule the gate cannot enforce

**The gate is blind to names and comments.** A confidently wrong routine header passes forever.
Every error below was gate-clean:

* 8 KN5000 label transplants naming the wrong object (a spliced-ROM offset bug, off by 0xEB00)
* "zero exceptions" that had 341 exceptions
* "243 of 244" reproduced by no committed script
* a handler count of 35 that was 34
* "byte for byte" for a match that was 170 of 204 bytes
* a routine 80/81 bytes identical to the KN5000's where the ONE difference was the peripheral base
* ~20 call sites cited one byte past the instruction, systematically
* "no references" and "no site found" asserted without running the census (they had references)
* a findings title claiming producers were "named" when they were only "located"
* **lever B of `FINDINGS-system-clock.md`** — see the retraction in that file

So: every semantic name needs an `Evidence:` line; every quantified claim needs a committed script,
tested on the **last** element as well as the first; every borrowed name needs a byte diff with the
differing count stated. Prefer `sub_XXXXXX` plus a stated gap over a plausible guess.

---

## Where it stands

Regenerate, never retype — `python3 scripts/analysis/source_coverage.py`:

    prom_a   374,691 substantive    43,012 filler   106,585 incbin   (71.5%)
    prom_b   320,217 substantive    44,612 filler   159,459 incbin   (61.1%)
    prom_c   395,072 substantive   129,216 filler         0 incbin   (75.4%)
    prom_d   330,521 substantive   193,767 filler         0 incbin   (63.0%)
    TOTAL  1,420,501 substantive + 410,607 filler          67.7% substantive

**Quote the substantive column.** A `.fill` of verified pad counts as converted while telling you
nothing; wave 3's prom_c gain was 96% pad.

Documentation: **2,657 routine headers with evidence lines, 17,438 labels, 80 findings docs,
191 committed analysis scripts.**

★ **Track `sub_XXXXXX` too — it is currently ~4,998 and it went UP during wave 6.** Newly converted
code brings in unnamed routines faster than naming retires them. Coverage measures territory;
this number measures meaning, which is the half of the goal that is furthest from done.

## What is left

`prom_c` and `prom_d` have **zero `.incbin`** — territorially complete. All remaining conversion is
`prom_a` (106,585 B) and `prom_b` (159,459 B).

Next targets, as the wave-6 lanes left them:

* **prom_a** — `0xFE8000-0xFEB330` (13,104 B) and `0xFEF746-0xFF3800` (16,570 B), the code halves of
  the sequencer/UI module. Deferred because ~15 string constants sit **inside the instruction
  stream** (`SEQUENCER`, `NOTE EDIT`, `DRUM EDIT`, an 838-byte effect-name table at `0xFF047F`);
  their bounds must be pinned first or the linear decode desynchronises. **That bounding is the
  next pass's first job.** After that `prom_a_module_frontier.py` ranks `T_F43350` (`0xFA60C2`,
  8,886 B) first.
* **prom_b** — top span is now `0xF067A6-0xF0D79B` (28,662 B); `prom_b_module_frontier.py`'s top
  thunk run is `T_F42E40` (4,624 B).
* **prom_c** — `0xFCD0F7-0xFDD2AA` (65,972 B) is a byte-code/command stream left **whole** because
  the existing 16-bit-BE framing desynchronises at the fifth record. It needs its interpreter found
  first — likely a prom_c analogue of prom_b's display-list VM. Guessing a stride is this project's
  known failure mode.

## ⚠ Tools that mislead — read this before trusting a ranking

* **`prom_c_frontier.py`: 132 of its 135 targets are phantoms**, produced by linearly disassembling
  ASCII descriptor strings and data zones. Its own docstring warns about it. Wave 5 ignored it and
  was right to.
* **`prom_b_span_frontier.py`'s `proven 0` is not evidence of data.** Its call-site scanner only
  recognises `ld XIY / ld XIX / call`; a region reached through `DisplayListB_RunOne_Stack` (one
  pointer on the stack) scores 0 while being well-evidenced. Wave 6's best target scored worst.
* A frontier count that does **not** fall after converting a data span is correct, not a failure —
  data retires no call target. Do not quote a drop that did not happen.

Good tools: `prom_a_module_frontier.py`, `prom_b_module_frontier.py`, `vector_map.py --unconverted`,
`prom_c_kernel_map.py`, `prom_a_xref.py`, `prom_c_xrefs.py`, the `*_audit_callsites.py` pair, and
`scripts/analysis/transplant_kn5000_labels.py` (105 byte-verified proposals — read its retraction
banner first). `notes/README-prom_c-tools.md` and `notes/prom_a-tooling.md` index the rest.

## Cross-referencing works, in both directions

* **KN5000 sub-CPU ↔ WSA1 prom_c**: 32,795 shared bytes survive an entropy guard (291,802 rejected
  as fill), shuffle null 0. `kn5000_shared_runs.py`, `transplant_kn5000_labels.py`.
* **This machine against itself**: prom_a and prom_c run the **same kernel** — 36 routine pairs,
  35 structurally identical to the byte. `prom_c_prom_a_routine_diff.py`, `prom_c_kernel_map.py`.
* ⚠ Always diff the bytes before reusing a name. `DSP_WriteChannelRegs_Inner` is 80/81 identical to
  the KN5000's and the one differing byte is the peripheral base.

## The emulation side

`notes/WSA1-EMULATION-DISASM-GAPS.md` (mirrored here from the overlay) is a ranked request list from
the MAME driver, ~95 entries. Prefer targets that answer it. Top open items: **gap A** — *name* the
`0x10C000` registers (21 of 22 have a located producer, none is named; which block is pitch, which a
sample address, which a level), **gap T** — ⚠ this line USED TO SAY "now a hardware question: the
firmware never writes PA bit 3 at all", and that is **RETRACTED**. The firmware writes PA at
**five** instructions, all in prom_a, and bit 3 is the only bit it changes after RESET: `res
3,(PA)` at 0xFE18EF followed by a 307 ms settle (so the line is ACTIVE LOW), `set 3,(PA)` at
0xFE18F7, two `ld (PA),A` at 0xFE660D/0xFE6631, and RESET's own `ldio PA,0xF9`. The earlier census
searched for one spelling of the operation. See `notes/FINDINGS-prom_a-gap-T-pa3.md`, re-derived by
`notes/prom_a_pa3_census.py` (19 checks) and by
`notes/wave7-verify-probes/wave7_pa_write_census.py` (18 checks, and it states its denominator:
zero unadjudicated candidates in prom_a's unconverted bytes, three in prom_b's, none addressing bit
3). What the pin is WIRED to remains a hardware question; whether the firmware drives it does not.
**gap O**.

The driver lives in `../kn7000_mame/src/mame/matsushita/wsa1.cpp`. It boots **both** variants to a
real `SOUND MODE` UI, has a working keybed, HLE control panel, EEPROM, floppy controller and four
TLCS-900 core fixes. Findings flow both ways: the disassembly predicted `cr 0x3C` and the emulator
confirmed it was what blocked the UI.

## Do not restart automatically

Felipe asked to stop after wave 6 and resume at a later date. The `/goal` condition is deliberately
unmet.
