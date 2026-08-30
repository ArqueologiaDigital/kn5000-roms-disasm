# SX-WSA1R disassembly — resume here

## ★★ THE COVERAGE GOAL IS MET: every reachable code path with start evidence is converted

    python3 notes/reachability.py --targets
    TOTAL reachable-and-unconverted: STRONG 17 bytes, ANY 1,670, in 17 spans.

    python3 notes/reachability.py --evidence
    prom_a  runs with start evidence: 1,541 bytes; WITHOUT: 87
    prom_b  runs with start evidence:     0 bytes; WITHOUT: 80
    prom_c  0 / 0

**The 17 remaining STRONG bytes are a walk artefact and are formally refused.** They are
`0xFA369A-0xFA36AB`, and reading them straight out of the ROM gives
`44 20 47 52 4f 55 50 20 4e 41 4d 49 4e 47 17 0c 07` = `"D GROUP NAMING"` — the tail of a UI
string. No seed of any grade names that address and no converted instruction falls through into it;
the walk decoded its way in. Framing it emits `ld XIX,0x4f524720` **and the byte gate passes**,
because the bytes do not change. A coverage brief told a lane to convert it; the lane refused and
was right.

**The walk has reached a FIXPOINT.** Each conversion turns its own contents into seeds and can
reveal more — round 1 revealed 499 bytes, round 2 revealed 38, and converting those 38 revealed
**nothing**. That is what finished looks like for this goal.

    at goal start   STRONG 17,558 bytes unconverted
    now             STRONG      17 bytes, all of them refused with a derived reason

| image | STRONG reachable & unconverted |
|---|---:|
| prom_a | 17 (the refused string) |
| prom_b | **0** |
| prom_c | **0** |

## The tool

`notes/reachability.py` — recursive descent over the three code images, following the INDIRECT
edges, which is where this machine keeps its control flow: the CPU vector table, the 1,910-slot
routine directory (each slot a `jp imm24`), the entries of every framed pointer table, branch
targets in converted code, and 32-bit immediates that land in an image.

    --targets    the work list, ranked by REACHABLE bytes, with a cumulative column
    --evidence   per-run START evidence: convert the runs with it, refuse the ones without
    --spans      per-span reachable counts        --seeds  seed classes
    --selftest   11 checks

★ **Seeds are GRADED, and it is the difference between code and painted data.** STRONG = a
directory slot, a branch in decoded code, a hardware vector. WEAK = a 32-bit immediate or a `.long`
entry, which are POINTERS, and a pointer is as likely to name a table as a routine. Convert on
STRONG. The gap between the columns (17 vs 1,670) is the weak-seed artefact, measured.

★ **A run start needs POSITIVE EVIDENCE**: a graded seed names it, or converted code falls through
into it. `0xF961BD` is named by no seed and IS code, because the instruction at `0xF961B8` is five
bytes and ends exactly there. `0xFA369A` has neither.

⚠ **A refusal can expire.** `--evidence` answers a question about the TREE, not a property of an
address: `0xFDE75D` was listed unevidenced by a run that predated the splice of `0xFDE729`, whose
`jr z` at `0xFDE72D` targets it exactly. Re-run after every conversion.

⚠ **Editing the tool invalidates its own cache**, by design — the fingerprint covers the tool's
source, because a walk is only as good as the code that made it. `--evidence` always re-walks; it
needs the per-byte set, which the cache does not persist.

## What this goal did NOT do, on purpose

**Semantics.** Every label this goal added is a bare `sub_XXXXXX` with a start-evidence line and no
claim about what the routine does. The documentation metric
(`python3 notes/wave7_documentation_metrics.py`) is the measure for that work, and it is a separate
goal.

**Existing prose was never touched, and it was verified rather than assumed.** Round 1's prom_a
diff is 3,782 insertions and FIVE deletions, all five `.incbin` directives; round 2's is 190 and
THREE. Both verified independently by a reviewer. The method is why: each span is cut into maximal
runs of reachable bytes, runs become instructions, gaps stay `.incbin` narrowed — so a diff is
proportional to coverage gained and cannot reach an already-converted line.

## What is left, for a future goal

* **167 bytes with no start evidence** (prom_a 87, prom_b 80) — refuse unless evidence appears.
* **~1,670 bytes reachable only from WEAK seeds** — pointer-table and immediate artefacts. Each
  would need a byte-level audit before conversion; round 1 framed 701 of them as instructions and
  the gate passed.
* **~105,000 bytes of `.incbin` that nothing reaches** — data. Converting it adds territory and
  zero coverage.
* **The documentation half**: 43.5% of the tree is understood at the lower bound, 5,052 routines
  are still `sub_XXXXXX`. See the wave-7 sections below.

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

## ⚠⚠ AN IMAGE IS NOT ONE FILE — read this before writing a probe

`prom_c/wsa1_prom_c.s` is a **2,516-line master** that `.include`s 26 subject sources;
`prom_d/wsa1_prom_d.s` is 494 lines plus three; prom_a and prom_b pull in `kernel/kernel.s` and two
shared maincpu routines. **A probe that opens the primary by path scans 1.9% of prom_c and 0.9% of
prom_d — and still prints its usual success.** The byte gate cannot see this: the lines a probe
scans assemble to nothing it compares.

**Always read an image through `notes/asm_source.py`:**

```python
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_lines, image_text, image_path, image_text_at_rev
SRC = image_path(ROOT, "prom_c/wsa1_prom_c.s")     # a file, for `open(SRC)` scans
```

| you want | use |
|---|---|
| the image's lines | `image_lines(ROOT, primary)` |
| ...minus a shared source you count separately | `image_lines(ROOT, primary, skip=["kernel/kernel.s"])` |
| a path, so an existing `open(SRC)` keeps working | `image_path(ROOT, primary)` |
| the image **at a git revision** | `image_text_at_rev(ROOT, primary, "HEAD")` |
| to WRITE one block | `locate(ROOT, primary, anchor)` then `write_part(path, text)` |
| to rename a token image-wide | `edit_image(ROOT, primary, fn)` |

★ **`git show HEAD:<primary>` is the trap `image_text_at_rev` exists for.** The split is committed,
so it returns the header while the working-tree side returns the image — four prom_d review probes
were reporting thousands of labels nobody added.

★ **Never redirect a splicer's READ without moving its WRITE.** Overwriting the master with the
expansion orphans 26 sources and **the byte gate stays green**. `write_part()` refuses both halves
of that accident (an `.include` count that drops, and a part that explodes to image size).

**The instrument:** `python3 notes/probe_health.py [--image prom_c]` runs every committed probe that
names a listing in three trees that differ only in the primary's layout — as committed, fully
expanded, and stubbed — and grades it by whether its ANSWER CHANGES:

| grade | meaning |
|---|---|
| `VACUOUS` ★ | differs from the image and still reports success — **fix first** |
| `LOUD` | differs and fails visibly |
| `SPLIT-FRAGILE` | right today, would break the moment its image is split |
| `WRITER` / `TIMEOUT` / `NONDET` / `BY-DESIGN` | not graded; see the docstring |

Its `--selftest` runs the byte gate in both derived trees, so a difference is attributable to the
file and not to the ROM. `python3 notes/migrate_listing_readers.py --list` is the ledger of every
site that still spells a listing by path, with a verdict per site.

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
