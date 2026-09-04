# Handoff — end of session, 2026-09-04

Written against a token budget, so this is an index rather than an account. Everything named here
is committed; nothing of value was left in scratch.

## State: all four repos clean, gates green

    make LLVM_MC=<snapshot> gate-all      13/13 byte-identical, 8/8 + 4/4 prerequisite
    wsa1/notes/l7a1429_crosscheck.py      PASS -- four artefacts agree
    toolchain                             tlcs900_backend@86332721969d, clean, binary sha 850b013e
                                          preserved at ~/compartilhado/toolchain-snapshot/llvm-mc.snap

⚠ `/home` is a 19 GB root at ~95%; the trees live on a virtiofs mount with ~57 GB. Read `df` on the
actual path, not on `/` — a misread of that cost a day of shared-toolchain pain (BRIEF-2026-09-01).

## What this session finished

* **Mnemonic convergence** — synthetic mnemonic sites 265,116 → 147,842. Residue splits three ways
  (~9,748 mechanical, ~78,364 needing one of three named backend features, ~2,371 refused with
  evidence). See `notes/ASSESSMENT-syntax-convergence-2026-09-02.md` §STATUS.
* **WSA1R sound subsystem labelling** — 152 routines named, ~155 refused with reasons.
* **The L7A1429 (IC3) is documented end to end** — `wsa1/notes/HLE-GUIDE-l7a1429.md` is the entry
  point; register map, units, timing, topology, editor names, limits, and the coupling solver.
  Public page: `kn5000-docs/wsa1-modeling-lsi.md`.
* **WSA1R MAME driver** — schematic facts applied; `l7a1429_device` logs a named register trace.
* **KN5000 DSP** — queue item 0 consumed as §232: 16 unanchored codes closed, 8 open, 9 not resident.

## The lane that was still running — it landed

`w25/src00` committed before stopping. It measured that §232's "648 corpus words, 605 paired with
`ACTION 0x00`" is **C-format-contaminated** — 26 have no `src` field at all; correct is **622 / 580**
— while the **+348 price is unaffected**, because `guard_fail()` refuses C-format before reading
`src`. Seventh occurrence of that conflation. Both live falsifiers are shown not blind by
construction (PEQ carries 8 `SRC 0x00` words, SINGLE DELAY 9).

**Resume at** `dsp/analysis/SRC00-HANDOFF-2026-09-04.md` §4, which pre-registers the next action and
its pass condition — including the case where all seven readings agree, which would make both
harnesses blind and is itself the finding. It also lists what NOT to redo: `action00-discriminator`
item I is VOIDED by `adjudication-round6` §14, so `mem[ptr]` and `zero` are both unrefuted and the
device ships one; `peq_tf.py` is not the 0.198 dB harness; `sd_rerun.py` hard-codes `src00="mem"`.

## The original entry for that lane

`w25/src00` — the DSP queue's new item 0, `SRC 0x00` alone (+348 words = 46 % of the routing
ceiling; the device's own reading is graded "1 of 6 enumerated, no independent support"). It was
told to commit and stop. **Check `git log main..w25/src00` first**; if it committed a partial
census, that is the resumption point. Falsifiers pre-registered in `BUILD-LANE-QUEUE.md` item 0:
PARAMETRIC EQ's 0.198 dB and SINGLE DELAY's `+0.02149296`, both live because `SRC 0x00` is
605-of-648 paired with `ACTION 0x00`.

## Ready work, in the order I would take it

1. `SRC 0x00`, above — fully specified, falsifiers named.
2. The three backend features in `notes/TRIAGE-size-form-mnemonics-2026-09-02.md` — A and B are one
   parser change and retire 71,667 sites between them.
3. `notes/lanes/conv-width-2026-09-03.md` — 9,748 sites of the SAME shape already converted;
   `scripts/converters/run_direct_address_convergence.sh` does them once entries are added to `MAP`.
4. Six pending side-quests in `~/compartilhado/KN7000/side-quests/pending/`. ⚠ Checked this session:
   today's KN5000 floppy Terminal-Count fix does NOT transfer to the KN7000 quest — that machine has
   an N82077AA at 0x98020000, a different controller.

## What is blocked, and why — do not re-derive these

* **WSA1R audio**: the six wave mask ROMs (IC43-45, IC47-49) are **not dumped**. No honest sound is
  possible; do not model IC4 to fake it.
* **POSITION's absolute scale**: proven NOT recoverable from the ROM
  (`wsa1/notes/FINDINGS-l7a1429-position-scale.md`) — 12 candidate units, tolerance fixed before
  looking, and the two grids are 303.9 cents from ever aligning. Only the instrument settles it.
* **Three hardware questions** are parked in `kn7000_mame/notes/HARDWARE-QUESTIONS-PENDING-FELIPE.md`.
  ⚠ Felipe has no access to his KN5000 — it is in storage in another country, no date. Do not plan
  work that blocks on it, and do not promote an inference in its place.

## The standing lessons this session added

All in `notes/lanes/BRIEF-2026-09-01.md`, and each cost something:

* **Gate the assembler, not just the bytes** — the WSA1R Makefile rebuilt 0 of 4 images on a
  toolchain change. `scripts/analysis/assert_toolchain_is_a_prerequisite.py` now guards it.
* **The byte gate cannot see a lost comment** — `scripts/analysis/assert_comments_preserved.py`,
  with `--rename-map` as a NARROW exemption (a reword still fails).
* **When the byte gate does NOT protect a rename** — it only does when the label is a symbolic
  operand. For data tables cited by literal address, the comment gate is the real check.
* **A census that matches ONE INSTRUCTION SHAPE finds only that shape.** Six claims of the form
  "nothing reads/writes this" fell in three days: a base spilled to a frame; a parallel
  `(map, array, stride)` triple; `TABLE - 4*k`; three writers reloading from a frame slot;
  24 routines reached only by computed jump; and an address arriving ON THE STACK via
  `lda / push / calr`. **Write down which forms you searched.**
* **A filter written for one purpose becomes a POPULATION when someone quotes a rate through it.**
  State the denominator's definition next to the rate.
* **A rename's blast radius reaches the probes**, which no gate sees — and a stale name in a record
  of what a PAST pass refused is history, to be annotated, not corrected.
