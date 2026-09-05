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

## ⚠ RESUMED, then cut by a session rate limit — two lanes preserved as WIP (late 2026-09-04)

The quota was reset, four efforts ran, and then a session limit killed the two still running.
Their uncommitted work was committed as explicitly-marked WIP so a resume cannot lose it:

* **Backend, encoding selectors** — spec `notes/SPEC-encoding-selectors-2026-09-04.md`. Step 2
  (parser) is COMPLETE on `llvm-project` branch `tlcs900_backend` at `adfbb55cf835`. Step 3 (the
  `.td` table + printer) is PARTIAL and UNBUILT on branch `tlcs900_backend-wip-selectors-step3` at
  `8b2c062f83b4`. ⚠ Do not pin or merge that WIP commit until it compiles and lit passes. Resume
  from spec step 3; steps 4-8 follow; step 9 (71,667-site conversion) and step 10 (delete the nine
  legacy aliases) are dispatched separately after step 8's four foils go red-then-green.
* **DSP `ACT 0x0D + 0x0E`** — ✅ FINISHED and MERGED (§234). Verdict CONFIRMED 1 of 49: the shipped
  pair survives, confirmed from disk by PARAMETRIC EQ's entry window; both codes stay OPEN because
  the delay-context consequence is a lag only hardware settles (parked as Q4). ★ "a10" was DSP
  PROGRAM a10 (MULTI TAP DELAY), a static arm that had completed — NOT a MAME run. Name arms
  unambiguously. Queue item 0 is now `SRC 0x11` (+49), and a lane (`w28/src11`) is on it: corpus
  census first, then a device arm, because both known-mathematics harnesses are blind to it.

Landed and merged in the same resumed stretch, all gated: `SRC 0x00` decided (§233, 1 of 7,
`mem[ptr]` survives; PEQ falsifier found BLIND, fired count 0); 11,840 direct-address sites
converted (SYNTHETIC 147,842 → 136,863; the backend has TWO register-name rules split by
instruction class; the branch verifier had a latent false green); docs site de-changelogged with
~20 stale figures corrected; `DbMemDump_StepTable` named.

## ⚠ FINAL STATE, 2026-09-05 ~00:35 — both remaining lanes STOPPED BY FELIPE; everything preserved

* **Backend, encoding selectors — steps 3-7 LANDED.** `llvm-project` `tlcs900_backend` was
  fast-forwarded by the lane to `7a7a3fd6318b` ("Decode the io family's long forms as ld/ldw
  (n:8), imm"), on top of `3a0635ee2c65` (the .td table: nine defs, nine legacy aliases),
  `3369a7097158` (lit pins every family, DEFAULTS INCLUDED), `34048ba78e45` (the 3-bit and I/O
  immediate-field refusals), and two disassembler-test commits. Zero uncommitted.
  ⚠ NOT YET DONE: the spec's **step 4 null run** (build from a CLEAN checkout, record the binary
  sha256 as TOOLCHAIN_VERSION UPDATE 15, `gate-all` 13/13 under it) and **step 8's four foils**
  (each RED then GREEN). Until step 4 runs, `toolchain-snapshot/llvm-mc.snap` (850b013e) is STILL the
  pinned reference and the new backend is UNGATED. Do step 4 before anything else touches this.
  Then steps 9 (71,667-site conversion, six commits) and 10 (delete the nine aliases).
* **DSP `SRC 0x11` (§235) — PARTIAL.** On `w28/src11`: the corpus census with its nulls
  (`dd7c05a7`), the pre-registered device-arm prediction (`1bad13ad`, PREDICT_235), and an UNRUN
  grader (WIP commit). The device instrumentation is on `kn7000_mame` branch
  `wip/src11-device-arm`, compiled at 00:28 but never executed. Resume: `run_dsp_arm.sh`, arm A0
  first; A1-A5 only if A0's regression row passes. ✅ VERIFIED: the PUBLISHED binary at
  `~/compartilhado/kn7000-emulator/kn7000` is the 14:19 DSP-OFF build (75,567,576 B), NOT the 00:28
  DSP-on build (75,567,512 B) sitting in `kn7000_mame_build/`. Nothing to republish.

Nothing was pushed anywhere. All four repos are clean on `main`.

## ⚠ CONTINUED 2026-09-05 (Opus 4.8): STEPS 4 & 8 DONE, step 9 scoped

Both repos clean on their canonical branches. Committed this stretch:

* **kn5000-docs 34c2f1f** — mame-emulation-gaps.md Gap 4 CLOSED. The driver now
  binds main-CPU Port G to PEDALS and returns Port E bit 0 = 0 with a card
  fitted (kn5000.cpp, 2026-09-02); removed Gap 4, its two table rows, and the
  stale Port-E-bit-0 boot-gate entry. The sub-CPU DRAM strap (Port G bit 0)
  stayed -- still unimplemented; full port detail already on cpu-subsystem.md.
* **llvm-project tlcs900_backend cc2c09c7376e** — the encoding-selector
  ambiguity-guard foils (llvm/utils/tlcs900-ambiguity-foils.sh), a new commit
  ON TOP of the pin 7a7a3fd6318b (which stays immutable in history; binary
  unchanged). Foil c corrected: the :i3 selector is TWO parts (FormI3.AsmTail
  spelling + immi3_8 operand class); removing the tail alone keeps the report
  at 1 pair, so the original tail-only foil was malformed.
* **kn5000-roms-disasm 9310fb7d** — STEP 4 (null run re-certified at the tip
  7a7a3fd6318b, binary 35829d3c reproduced deterministically, gate-all 13/13
  zero-delta on the unconverted tree) and STEP 8 (four foils red-then-green).
  Harness notes/syntax-convergence-probes/encoding_selector_foils.py +
  transcripts committed. Full record: TOOLCHAIN_VERSION UPDATE 15 STEPS 4 & 8.

**Step 9 (source conversion) is NOT started and needs real work, not just a
run:**
* size_family_convert.py has the machinery (--family per-site byte-equality via
  -show-encoding, FOILS null, latin-1) but only the `incm` family. The six
  selector families are NOT in FAMILIES, and the example rows at lines ~160-176
  are STALE pre-selector spellings (`cps a,4 -> cp a,4`, the LONG form, wrong
  bytes) -- do NOT trust them; the per-site probe would reject them anyway.
  Correct spellings from TOOLCHAIN_VERSION "Final syntax": cps->`:i3`, and the
  ld families split `:i3` vs `:opc` by encoding -- VERIFY each against the
  assembler before writing, do not guess the family->selector map.
* ldio/ldwio are a RESHAPE not a rename (`ldio 7, 255` -> `ld (7:8), 255:io`),
  need a PARSER + assert_comments_preserved.py.
* Step 9 REQUIRES promoting the header pin to 7a7a3fd6318b / binary 35829d3c in
  lockstep with the first converted commit (snapshot llvm-mc.snap + the header
  Commit/Binary lines + the LLVM: trailer all move together). This is the
  "coordinator's call" the spec names; there is no lane contention now.
* Order (largest first): cps 19,261 -> lds 18,564 -> ldb 16,138 ->
  lds32 14,239 -> ldio 2,354 -> ldwio 1,111. gate-all + null after each.
  Then step 10: delete the nine aliases, re-run steps 4/5/6/8.
