# AUDIT — ISA / ENCODING cluster: which PROVEN-BY-CONSTRUCTION and FORCED claims does the MAME device NOT implement?

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-31**.
OFFLINE, READ-ONLY. No emulator run, no rebuild, no source edit outside this file
and `dsp/tools/audit_isa_census.py`.

**Audited notes (the ISA/encoding cluster).**
`kn7000_mame/notes/kn5000-dsp-{hi12,pointer,headerdecode,encoding,axes,INDEX}.md`,
`dsp/instruction-set.md`, `dsp/analysis/bit11-family.md`.
Model for the exercise: `SPECULATIVE-APPLIED-REGISTER.md` §188 — two notes gave a
decode **by construction**, the device disagreed in two lines, and a ROM-derived
control confirmed the fix bit-exactly.

**Device audited (read only).**
`kn7000_mame/src/devices/cpu/upd6383/{upd6383.cpp,upd6383.h,upd6383d.cpp,upd6383d.h}`
at working-tree state of **2026-07-31 03:54** (HEAD `1562d4f`). Shipped default
`m_specmask = 0xB910E446A39B440F` (`upd6383.h:911`).

> ⚠ **`upd6383.cpp` and `upd6383.h` are under ACTIVE EDIT while this audit runs** — their
> mtime advanced during the pass and line numbers moved by ~14. **Every finding below was
> re-verified against the 03:54 snapshot**, but cite the *symbol names* (given alongside
> every line number), not the numbers.

**Instrument.** `dsp/tools/audit_isa_census.py` — a read-only re-measurement over the
**full 3057-word corpus** (kernel 60 + epilogue 23 + 38 distinct body images = 2974),
**split by region**, because most of the claims in this cluster were measured on the
bodies only and I-RAM 0..82 is excluded by construction from every one of them.
Runtime ≈ 4 s. Everything numeric below is that tool's output.

Decoded default mask bits (for the IMPLEMENTED-BUT-OFF column):
`{0,1,2,3,10,14,16,17,19,20,23,24,25,29,31,33,34,38,42,45,46,47,52,56,59,60,61,63}`.

---

## 0. Result in one paragraph

The device implements **almost all** of this cluster's operational content, including
the one the brief flagged as a live thread: the `bit 10 = END OF PROGRAM`
falsification **did** reach the executor, and correctly. Three real gaps remain.
The largest is that `setvec`'s **per-unit call-vector registers are written and then
ignored** — the frame sequencer still uses a hard-coded `{0x0E→84, 0x0F→200}` table,
which the device's own comment labels *"OBSERVED … NOT derived"* — while K5 has this
**DETERMINED / PROVEN BY CONSTRUCTION** and the archived cold-boot capture contains
**both** the LINK and the DISCONNECT value for **both** units. Second: the **C-format
opcode field `bits[35:25]`** (eight opcodes) is neither rendered nor executed; all 68
C-format words run as one instruction, and the 11 words outside the payload rule are
**all on the per-frame critical path**. Third: item J's FORCED negative for mode-1
`ACTION 0x07` is honoured only through its *stated escape*, and the residual
violations land on host-primed registers. Two note-side defects also fell out, one of
which would, if applied, delete the code of the DO1 presentation word.

---

## 1. Classification table

Grades: **MEASURED** (re-measured here) / **FORCED** / **INFERRED** / **SPECULATIVE**.
Column *control* = does an independent instrument exist that could decide it?

### 1.1 IMPLEMENTED — verified against current source

| # | claim (source, grade) | device site | verdict |
|---|---|---|---|
| A1 | field map `hi12[35:24].class4[23:20].addr8[19:12].lo12[11:0]` (`-encoding.md` §8, INFERRED) | `upd6383d.h:39-42` | **IMPLEMENTED** |
| A2 | `addr8` = **signed post-increment on an 8-bit wrapping pointer, only for `class4 & 7 == 2`** (`-encoding.md` §4 minimal pair algo 32/34 ±115 mod 256, MEASURED) | `upd6383_disassembler::ptr_postinc()` (`upd6383d.h:900`); `m_dp = u8(m_dp + s8(addr8(word)))` in `exec_decoded()`'s bit-11 branch and in `exec_alu()`'s tail | **IMPLEMENTED**, including the 8-bit wrap |
| A3 | terminator = `class4==1 && addr8 ∈ {0x0E,0x0F}`, 91/91 finals, 0 elsewhere; that `addr8` is the **unit index**, stride **+1** not +0x80 (`-encoding.md` §6.1/§7; `instruction-set.md` correction 2026-07-27) | the `const bool tagged = …` / `const bool ending = …` conjunctions in `upd6383_device::run_frame()` and `upd6383_device::execute_run()` | **IMPLEMENTED**. Re-measured: 40 such words corpus-wide, **all 40 carry bit 10**, so the device's extra `is_end()` conjunct selects the identical set |
| A4 | ★ **bit 10 = END OF BLOCK, default action FALL THROUGH; the transfer rides on the unit tag, not on the bit** (`-pointer.md` §5 + `-headerdecode.md` §2.3, **PROVEN BY CONSTRUCTION**) | `upd6383_disassembler::is_end()` (`upd6383d.h:942-955`, comment cites `-headerdecode.md`); the `tagged`/`ending` tests in `run_frame()` and `execute_run()` | **IMPLEMENTED — see §2, the live thread** |
| A5 | END is a **MODIFIER**: the halting word still does its datapath work (`-hi12.md` §3.2, MEASURED) | `const u64 word = tagged ? (raw & ~(u64(HI_END) << 24)) : raw;` in `run_frame()` (and the `ending` twin in `execute_run()`) | **IMPLEMENTED** |
| A6 | call/return **share one encoding**, distinguished by context; 2-deep stack (`-headerdecode.md` §2.1, **PROVEN BY CONSTRUCTION** from the double register load at I-RAM 42-44 / 50-52) | the `if (tagged)` block in `run_frame()` (`m_sp == 0` → CALL and push, else pop and RETURN; `m_stack[2]`) | **IMPLEMENTED** |
| A7 | the frame is closed by **hardware**, and I-RAM 82 `C00.A.47.407` is the wait (`-headerdecode.md` §3, MEASURED: 0 END words in I-RAM 60..82) | `FRAME_WAIT_WORD = 0xc00a47407` (`upd6383.h:219`) + the `if (raw == FRAME_WAIT_WORD)` termination in `run_frame()`; PC restart is `m_pc = 0; m_sp = 0;` at the head of `run_frame()` | **IMPLEMENTED** (re-measured: epilogue END words = 0) |
| A8 | **bit 4 = write ACC → mem[ptr]**, target **MODE-DEPENDENT**, `mem[ptr]` is the mode-2 target only (`-hi12.md` §4, MEASURED; R2, FORCED) | guard 5 in `alu_decoded()` (`upd6383d.h:634-635`); `upd6383_device::store_mode()` | **IMPLEMENTED** |
| A9 | the bit-7 **store gate** in its agreed part (`store-gate.md` item C, FORCED where the survivors agree) | `st_suppressed()` `upd6383d.h:457`; guard 7 `:639-647` | **IMPLEMENTED** — but see D2, the shipped arm is the *other* co-equal survivor |
| A10 | **FETCH is not ADVANCE**: bit 23 fetches, only `class4 == 0xA` advances (K4, **FORCED**) | `cursor_fetch()` / `coeff_fetch()` / `coeff_consumer()` `upd6383d.h:822,841,869` | **IMPLEMENTED**, and the mnemonic honours it (`,c+` vs `,c`, `upd6383d.cpp:886-891`) |
| A11 | ⚠ K4's bit-23 census is **body-scoped**; the kernel also sets bit 23 on classes **9, C, D** (`instruction-set.md`) | `coeff_fetch = (class4 & 8)` covers 9/C/D; `coeff_consumer = (class4==0xA)` excludes them | **IMPLEMENTED**. Re-measured, kernel bit-23 by class: `{8:2, 9:4, A:21, C:1, D:1}` — matches the note exactly |
| A12 | a **C-format** word does not advance the cursor and has no `addr8`, so it cannot post-increment (`instruction-set.md`, MEASURED, "exactly one word affected: `C00.A.47.407`") | `!c_format(w)` guard on `ptr_postinc`, `coeff_consumer`, `coeff_fetch`, `cursor_fetch` | **IMPLEMENTED** |
| A13 | the C-format immediate is **13 bits at [24:12], reaching into `hi12` bit 0** (K5, MEASURED — why unit 1's link word reads `0xC41`) | `c_imm13()` `upd6383d.h:75` | **IMPLEMENTED** |
| A14 | the **payload rule** is `(hi12 & 0xFFE) == 0xC40`, family-local, 57/57 in / 2/11 out (`isa-adjudication.md` §1/§3, MEASURED) | `is_c40()` `upd6383d.h:74` | **IMPLEMENTED**. Re-measured: c_format 68, is_c40 57, outside 11; `is_c40` is *exactly* opcode `0x620` |
| A15 | `801.0.NN.821` = `ldptr`, `0x021`/`0x821` are **one route plus a modifier** (`-hi12.md` §5.2 + K3 §1.1 item A, **PROVEN BY CONSTRUCTION**) | `is_regload`/`is_ldptr`/`is_rstcur` `upd6383d.h:754-772` | **IMPLEMENTED** |
| A16 | ★ the **retraction** of `-pointer.md` headline 2 (`0x821` is C-RAM, not the D-RAM operand pointer) | `upd6383d.h:729` states the withdrawal (*"★ This WITHDRAWS 'the body's operand pointer is the 0x821 register'"*); `exec_decoded()`'s `is_ldptr` branch sets `m_cp = ad`, **not** `m_dp` | **IMPLEMENTED — the retraction reached the device** |
| A17 | `lo12` **bit 11 selects a second encoding**; on those words there is no SRC and no ACTION field (`bit11-family.md` §9, FORCED by enumeration) | `if (lo12(w) & 0x800) return false;` in `alu_decoded()` (`upd6383d.h:628`); the speculative path executes **addressing only** — `if (lo12(word) & 0x800) { cursor++; m_dp += s8(addr8); return; }` in `exec_decoded()` | **IMPLEMENTED** (and see D3 — the note over-reached) |
| A18 | phaser: the three `addr8` deltas of an all-pass section **cancel exactly**, 30/38, exceptions are the 8 chain terminals (`-axes.md` §2.2, MEASURED — pure arithmetic) | falls out of A2 (all three words are class 2/A) | **IMPLEMENTED** by construction |
| A19 | `lo12 ∈ {0x647,0x687}` are the biquad **latch** writebacks, a different mechanism from the bit-4 accumulator store (`-hi12.md` §4.5) | `LO_ACT_ST_BUS` with `LO_SRC_TA`/`TB`: `0x647` = `mem[p]←tempA`, `0x687` = `mem[p]←tempB` | **IMPLEMENTED** |
| A20 | ACTION `0x07`'s target is mode-dependent (`output-stage-decode.md` item J, FORCED) | guard 6 `upd6383d.h:636-637` | **IMPLEMENTED in the decoded core**; see B3 for the speculative core |
| A21 | the header runs on its **own coefficient bank** (`-headerdecode.md` §5, MEASURED: uploaded − body cursor words is +1 in 18 images, never near +23) | per-unit cursor seed inside `run_frame()`'s CALL — `m_cursor = unit1 ? 0x90 : 0x00; m_cursor_rebase_n++;` — behind **mask bit 38, SET in the default** | **IMPLEMENTED-BUT-SPECULATIVE**, on by default (§130 pre-registered P1/P2/P3 all hit) |
| A22 | `hi12[9:8]` has **arity 3, not 4** (`-headerdecode.md` §6, MEASURED) | `hi_f98()` comment `upd6383d.h:92` records `1713/493/766/2` | **IMPLEMENTED as documentation**; no semantic depends on it, except D4 |
| A23 | `000.1.NN.000` = D-RAM register select (`instruction-set.md` decoded-forms table, PROVEN BY CONSTRUCTION) | not in `decoded()` | **NOT-APPLICABLE**. Re-measured: **0 occurrences in I-RAM** across all 3057 words — it is a *host-stream* word only, so an instruction decoder is the wrong place for it. The table row is filed under "Decoded forms" and should say so |

### 1.2 MISMATCH / ABSENT

| # | claim (source, grade) | what the device does | class | **INDEPENDENT CONTROL?** |
|---|---|---|---|---|
| **B1** | ★★★ **`setvec` writes the per-unit CALL-VECTOR register, and the entry addresses are host-loaded registers, NOT a fixed 2-entry table** — the host rewrites I-RAM 64 / 71 to LINK (84/200) or DISCONNECT (42/50) (`instruction-set.md` `setvec` §, **DETERMINED**; `-headerdecode.md` §4.1) | `exec_decoded()` writes `m_vec[vector_unit(lo12)] = c_a(word)` (`upd6383.cpp:3629`) and **nothing reads it** — the only other references are `reset`, `state_add` and `save_item`. The sequencer uses `m_pc = (unit1 ? UNIT1_ENTRY : UNIT0_ENTRY)` with `UNIT0_ENTRY = 84`, `UNIT1_ENTRY = 200` hard-coded (`upd6383.h:227-228`; `upd6383.cpp:4366`). Its own comment concedes: *"The table below (0x0E -> 84, 0x0F -> 200) is **OBSERVED** in every captured upload … **NOT** derived."* and `exec_decoded` adds *"deliberately NOT wired to the call sequencer in this pass"* | **ABSENT (deliberate)** | ★ **YES, two.** (i) The four values are **literal constants in Sub CPU ROM** at `0xF6CD/0xF6D8` (script A) and `0xF707/0xF712` (script B) — `EFF_Disconnect` / `EFF_Link`, indexed by unit, PROVEN BY CONSTRUCTION. (ii) The archived cold-boot capture carries **all four** host writes: `C40.A.80.445`→84, `C40.5.40.445`→42, `C41.9.00.446`→200, `C40.6.40.446`→50 (decoded here from `-headerdecode.md` §4.1 with `A = imm13>>5`; all four land on the correct, different windows) |
| **B2** | ★★ **There is an OPCODE FIELD in the C-format, `bits[35:25]`, with eight values** — `600`×2 (both WAITs), `602`, `605`×3, `60B`, **`620`×57**, `621`, `625`, `632`×2 — and *"the five `lo12 = 0x820` header words carry four different opcodes, so they are not a family at all"* (`instruction-set.md` Word-format §, citing `output-stage-decode.md` §5; MEASURED). The note names it explicitly: *"Neither disassembler renders the opcode yet … that is a sync item."* | **Not rendered**: `upd6383_disassembler::text()` prints `{C-fmt A=%d B=%d}` (`upd6383d.cpp:936`) and `hi12_text()` still renders a C-format `hi12` as microword flags. **Not executed**: all 68 C-format words take one branch in `exec_decoded()`, `m_cimm = s64(imm) << 11` (`upd6383.cpp:1740`) | **ABSENT** | ★ **YES.** The census is ROM-derived and reproduced here exactly (§3 of the tool). Sharper still: the **11 words outside opcode `0x620` are 8 kernel + 3 epilogue and ZERO body words**, i.e. every one of them executes **on the per-frame critical path**, and only 2 of the 11 have a multiple-of-32 immediate. The payload rule's own split (57/57 in, 2/11 out) is the calibration |
| **B3** | **On a MODE-1 word `ACTION 0x07` does NOT write `reg[addr8]`** — FORCED, with the positive reason that register `0x06` carries the user's effect depth and would survive exactly one frame (`instruction-set.md` guard-6 §, `output-stage-decode.md` §6.4) | `exec_alu()`'s `LO_ACT_ST_BUS` case sets `u8 d07 = (mode07 == 1 …) ? addr8(word) : m_dp` (`upd6383.cpp:3147-3149`) and `store_mode()` then writes `m_rf[dest]` when `mode == 1` (`:538-545`, mask bit 23 — **SET**). The item-J **escape** is taken for the motivating word only: §100 reads `SRC 0x02 = reg[addr8]` (`:2333`, mask bit 24 — **SET**), which makes `w72 = 000.1.06.087` an identity. The §41 guard that covered the rest is **mask bit 5 — CLEAR in the shipped default**, and the source itself flags *"⚠ THE GUARD IS NARROWER THAN THE DEFECT"* | **MISMATCH (partial)** — the FORCED *conclusion as written* is not implemented; only its motivating instance is neutralised | ★ **YES for `0x06`/`0x86`** (the host writes them once, `EFF_VolumeLoop`, PROVEN BY CONSTRUCTION; the device already instruments it as `m_lvl_seen`/`m_lvl_nz`). **NO for the residue**: `w66→0x8C`, `w70→0x85`, kernel `w58→0x8A` are written every frame from `SRC 0x04 = m_ta` and `SRC 0x03 = acc` (mask bit 25 — SET), and nothing reads them, so today the violation is unobservable |
| **B4** | **`C00` = wait/sync; BOTH `C00` words encode their own I-RAM address** (2/2) — `C00.9.84.000` @76 and `C00.A.47.407` @82 (`instruction-set.md` landmarks, **INFERRED**) | `annotate()` calls both WAIT/SYNC (`upd6383d.cpp:387-394`), but the executor stops only on the exact value `FRAME_WAIT_WORD`; I-RAM 76 executes as a C-format immediate load | **ABSENT** | ⚠ **NO CONTROL, AND IT MUST NOT BE SHIPPED.** The claim is INFERRED. Worse, a naive fix is *actively dangerous*: if I-RAM 76 halted the frame, the unit-1 presentation `w78` would never run and DO2 would go dead. The reading that survives is "wait, then continue", which is a **timing** semantic the device does not need. **Recorded as understood-and-declined, not as a defect** |

---

## 2. ★ The live thread the brief named: `hi12` bit 10

`-hi12.md` §3 measured *"bit 10 with bit 11 clear = END OF PROGRAM"* **38/38 on the
body images**; `-pointer.md` §5 **FALSIFIED it as a bit meaning** the moment the
common header was read (14 occurrences in 60 words, only 2 of them terminators).

**Re-measured here, by region:**

```
   kernel  (83 words)  END words 14   unit-TAGGED  2   untagged 12
   bodies (2974 words) END words 38   unit-TAGGED 38   untagged  0
                       one per image: YES ; final word in 38 of 38
```

The 14 kernel sites are I-RAM 6, 11, 14, 19, 21, 23, 24, 28, 33, 36, 39, 41 (interior,
fall through) and 49, 59 (the two unit-tagged CALLs). `-pointer.md` §5's *"halted at
word 6, `400.A.00.419`"* is reproduced exactly.

**Verdict: the falsification REACHED the device, in three places, and correctly.**

* `upd6383d.h:942-955` renames the predicate **END OF BLOCK** and cites
  `notes/kn5000-dsp-headerdecode.md`: *"Its default action is FALL THROUGH; a
  transfer happens only when the word also carries a UNIT TAG."*
* `upd6383_device::execute_run()` restricts strip-and-halt to
  `is_end && class4 == 1 && addr8 ∈ {0x0E,0x0F}` — *"applies the strip-and-halt model
  to the form it was measured on and traps the rest, rather than extrapolating."*
* `run_frame()` (`:4014-4018`) uses the same conjunction for the transfer, and
  untagged END words simply fall through.

Two consequences worth recording because they are easy to get wrong:

1. For an **untagged** END word the device leaves bit 10 **set** in `hi12` and
   executes the word. That is safe: no semantic reads bit 10 (`hi_f31`, `HI_ST`,
   `HI_B7`, `f98` all sit elsewhere), and `hi_residue()` accounts for it. So the
   MODIFIER reading (A5) and the fall-through reading (A4) coexist without a
   double-strip.
2. The device's extra `is_end()` conjunct on the transfer is a **free** restriction:
   re-measured, all 40 `class4==1 && addr8∈{0E,0F}` words carry bit 10, so the two
   predicates select the identical set. The conjunct costs nothing and would catch a
   future stream that separated them.

**The brief's second half is confirmed and is the more productive half.** Every static
search in this series excluded I-RAM 0..82 by construction, and the kernel really is
where the counter-examples live — see D3, where the same blind spot produced a note
claim that is false in the epilogue.

---

## 3. Ranked shortlist — what to implement next

Ranked by (confidence the note is right) × (size of discrepancy) × (control exists).

### R1. Wire `setvec` to the call sequencer — B1

* **Confidence** high (DETERMINED, plus PROVEN-BY-CONSTRUCTION provenance for the four
  values). **Discrepancy** large: the sequencer's target is currently an *observation of
  one upload layout*, not a decode. **Control: YES** (§1.2 B1).
* **Why it matters beyond PC order.** `dsp-next-steps-roadmap.md` measured that the two
  host-patch words are written as a **mute/restore bracket around every body reload**.
  Under the hard-coded table the device therefore **runs the body during the window in
  which the firmware has deliberately disconnected it** — i.e. during a body upload.
  `instruction-set.md` states the hardware consequence explicitly: *"a disconnected unit
  goes silent, it is not attenuated."*
* **Two-sided falsifier.**
  *Side A (the change is real):* with `m_pc = m_vec[unit] * WORD_BYTES`, a fired-count
  on `m_vec[unit] ∈ {42,50}` must be **> 0** across an effect change, and during those
  frames the tagged word at I-RAM 42/50 must re-enter the header's own setup block, hit
  `w49`/`w59` with `m_sp == 1`, and RETURN — so **body slots executed per frame → 0**
  and that unit's presentation count → 0.
  *Side B (the change is a no-op):* if `m_vec` never holds 42/50 at any `Fs` edge — the
  host always re-links inside one sample period — the fired count is **0** and the
  observed table is adequate. That outcome is worth as much and is measured by the same
  counter. **The experiment cannot come out "inconclusive".**
* **Prerequisite, stated:** `m_vec` starts at 0 and is only written by the C-format
  `is_setvec` spelling. The canned boot default `011.9.0E.445` / `011.9.0F.446` is **not
  decoded** (source field OPEN, `instruction-set.md` "Third state"), so before the host's
  first `setvec` the registers are 0 and a naive wiring would jump to I-RAM 0. Seed
  `m_vec = {84, 200}` at reset, *labelled as the observed layout*, and let `setvec`
  overwrite it — that keeps today's behaviour as the null arm exactly.

### R2. Render and split the C-format opcode `bits[35:25]` — B2

* **Confidence** high (MEASURED, and the payload rule is *exactly* opcode `0x620`, which
  is itself a strong internal check). **Discrepancy** medium-large: **11 of 11**
  non-`0x620` C-format words execute every frame and all take one branch.
  **Control: YES.**
* **Cheapest first step is zero-risk and is a pure listing change**: print the opcode,
  and suppress the `{C-fmt A= B=}` split outside `is_c40()`. The device already has the
  caveat text for the `lo12 ∈ {820,822,825,827}` sub-family (`upd6383d.cpp:396-399`) but
  `text()` prints A/B for *all* 68 anyway (`:936`) — the exact over-reach
  `instruction-set.md` names (*"the listing annotates with an A/B split they have not
  earned"*). Re-measured, the four affected header words are `w15 C0A.2.92.820` (A=20
  B=18), `w22 C04.3.12.820` (A=24 B=18), `w29 C42.4.57.820` (A=34 B=23),
  `w31 C0A.4.B1.820` (A=37 B=17) — **none** a multiple of 32.
* **Two-sided falsifier for the executable half.** Opcodes `605` (×3) and `625` (×1)
  are the four words that share destination `lo12 = 0x820`. Give `605` and `625`
  *different* handlers and read the register `0x820` names: under "four opcodes, one
  destination" the register must take **different** values from the two; under the
  current "one instruction" model it cannot. If both handlers produce the same
  observable, the opcode split is inert on this machine and should be documented as
  rendering-only.

### R3. Decide item J's general form, or narrow the note — B3

* **Confidence** in the *forcing argument* is high but its **scope is narrower than its
  ⇒**: the argument is "a host-programmed register must persist", which reaches `0x06`
  and `0x86` and nothing else. The device satisfies the argument (via the §100 escape)
  and violates the general statement.
* **Control: partial.** For `0x06`/`0x86` the control exists and the device already
  passes. For `0x85`/`0x8A`/`0x8C` there is **no control today** — nothing reads them —
  so *this cannot be shipped as a change*, only as a note correction plus a fired-count.
* **Two-sided falsifier, and it is cheap because both arms already exist in the source.**
  `output-stage-decode.md` §7.2's reading R-2 **needs** `w70` (`2A6.1.85.0C7`) to *supply*
  reg `0x85` with something new. Item J's general form **forbids** it. They cannot both
  hold. §101 already wires `SRC 0x03 = acc` (mask bit 25, on) with the pre-registered
  test: *"if the accumulator at w70 carries audio, cell 0x85 joins {0x06, 0x07} in the
  §86 quiet-vs-loud range report; if it does not, R-2 dies here."* Run that report and
  read the answer off it — **no new code**. If R-2 lives, item J's ⇒ must be narrowed to
  host-programmed registers in `instruction-set.md`. If R-2 dies, item J's general form
  gains its first independent support and the device should adopt it.

### R4. (Do **not** implement) treat I-RAM 76 as a halt — B4

Recorded so the next pass does not spend a tick on it: INFERRED only, no control, and a
naive implementation kills DO2. Leave as annotation.

---

## 4. Note-side defects found by the audit (the reverse direction)

These are cases where the **device is right and the note is wrong**. They matter because
each is an instruction a future pass would follow.

### D1. `bit11-family.md` §9.3's "five codes do not exist" is BODY-SCOPED and false for four of five

§9.3 states: *"⛔ `ACT 0x03`, `ACT 0x04`, `ACT 0x1C`, `SRC 0x02` and `SRC 0x04` do not
exist. They are what you get by applying the bit-11-clear encoding to bit-11 words."*
§11 item 2 turns it into an instruction: *"Delete `ACT 0x03/0x04/0x1C` and
`SRC 0x02/0x04` from any working ISA table."*

Re-measured over the **full** corpus, split by region:

```
   code       region   n   bit11-set  bit11-CLEAR   the bit-11-CLEAR site
   SRC 0x02   kernel   1       0           1        EPILOGUE w12 = 000.1.06.087   (iw 72)
   SRC 0x02   body    24      24           0
   SRC 0x04   kernel   1       0           1        EPILOGUE w6  = 000.1.8C.107   (iw 66)
   SRC 0x04   body     1       1           0
   ACT 0x03   kernel   1       0           1        EPILOGUE w3  = 2A7.9.05.1C3   (iw 63)
   ACT 0x03   body    53      53           0
   ACT 0x04   kernel   1       0           1        EPILOGUE w13 = E30.C.00.404   (iw 73)
   ACT 0x04   body     1       1           0
   ACT 0x1C   body    24      24           0        (no kernel site -- this one is clean)
```

**Four of the five have exactly one bit-11-CLEAR site, and every one of them is in the
23-word output stage.** Only `ACT 0x1C` is genuinely 100 % bit-11.

Worse, the note **contradicts itself**: its own item A is *about* `w73` and says
*"`w73` = `E30.C.00.404` does **not** [carry bit 11]"* — so item A knows `ACT 0x04` has a
bit-11-clear site, and §9.3's census then reports `ACT 0x04` as "1 site, 100 % bit-11"
because the census ran over bodies only. **The instruction shipped from the wrong half
of the note.**

The stakes are concrete: `E30.C.00.404` is **`w73`, the DO1 output presentation** — one
of only two words in the machine that write an output latch (`output-stage-decode.md`
§6.5). Deleting `ACT 0x04` would delete the code of the word the whole output-stage
line depends on. `000.1.06.087` is the word item J is *about*.

* **MAME is unaffected and correct**: `alu_decoded()` refuses bit-11 words wholesale, and
  `exec_alu()`'s source switch reads `SRC 0x04` (`upd6383.cpp:2330`), `SRC 0x02` (`:2333`)
  and `SRC 0x03` (`:2365`) precisely on the epilogue's class-1 words, with comments that
  already name them.
* **`dsp/tools/dsp_disasm.py:347-348` carries the defect**: `PHANTOM_ACT = {0x03:54,
  0x04:1, 0x1C:25}`, `PHANTOM_SRC = {0x02:25, 0x04:1}`, documented as *"Codes whose
  every corpus site is an alt_lo12() word"*. Nothing consumes them today (grepped: the
  tables are referenced nowhere), so the defect is **latent, not live** — but it is a
  published table that is wrong for 4 of 5 rows.
* **Recommended wording** (a correction, not a retraction — §9's core result survives):
  *"Over the 2974-word BODY corpus these five codes occur only on bit-11 words. Four of
  the five have a single bit-11-CLEAR site each, all in the 23-word output stage, which
  this note's corpus excludes by construction; `ACT 0x1C` is clean at 24/24. So the codes
  are parse artefacts **in the bodies**; in the kernel they are real."*

### D2. Three places in the device describe the shipped store gate differently, and the default mask picks the third

`store-gate.md` item C leaves exactly two survivors: `b7 && f31 == 1` and
`b7 && f31 != 2`. They differ on 13 corpus words.

* `upd6383d.h:457` ships `st_suppressed() = b7 && f31 == 1` and §34 records *"REVERTED
  to the round-4 condition"*.
* `upd6383.h` (the `m_stgate_alt_n` block, `:682`) describes bit 29 as the co-equal arm,
  **"Default OFF, with a FIRED COUNT."**
* But `upd6383_device::st_suppressed_live()` selects the co-equal arm whenever mask
  bit 29 is set, and **bit 29 IS in the shipped default** — added deliberately by §116
  (`upd6383.h`: *"bits 25 …, 29 (store-gate co-equal survivor) and 33 join the
  default"*).

So the running machine uses `b7 && f31 != 2`. That is **legitimate** (both arms survive
item C) and is **not** a defect in behaviour — but the "Default OFF" line at
`upd6383.h:687` is stale, and `upd6383d.h`'s §34 "REVERTED" note reads as if the shipped
gate were the other one. **One-line fix, no behaviour change.** Cost of leaving it: the
next pass that reads §34 will believe kernel `iw30` (f31 = 5) stores, when in the shipped
build it does not.

### D3. `upd6383d.h`'s "708 words carry bit 4" counts one word where bit 4 is not a store

Re-measured over 3057 words excluding C-format: **707 bit-4 words**, split
`(bit7, f31) → {(0,0):19, (0,1):494, (0,4):13, (0,6):1, (1,0):3, (1,1):138, (1,2):29,
(1,5):10}` — i.e. **527** at `bit7 = 0`, 138 at (1,1), 29 at (1,2), 13 at (1, f31∉{1,2}).
Every sub-count in `upd6383d.h:571-576` matches **except** the totals, which read
708/528 and are corrected there from "707/527 was one word short".

The 708th is `EPILOGUE w14 = C16.9.AB.000` (iw 74), the **one C-format word carrying
`hi12` bit 4** (`instruction-set.md` §"The DO write" says so: *"only 1 of the 68
C-format words does"*). In the C-format, `hi12` bit 4 is word bit 28 — inside the
opcode field `bits[35:25]`, not a store enable. So **707/527 was right and the
"correction" introduced the error.** No behavioural impact (the format guard fires
first), but the census line should not be quoted.

### D4. `f98` is UNKNOWN and is being used as a live discriminator

`-headerdecode.md` §6 and `-hi12.md` §8 both record `hi12[9:8]` as *a proven field of
unknown meaning* (and the accumulator-op reading as **measured and failed**). §148
(mask bit 59, **SET in the default**) gates `SRC 0x00 = coef` on `f98 == 1`
(the `case 0x00:` arm of `exec_alu()`'s source switch). The device flags the hazard itself — *"Gating on f98 BECAUSE
it separates the twins from the railers would be fitting the gate to the outcome"* —
and offers §147 as the independent licence. **Not a defect; recorded so that any future
decode of `f98` is checked against this gate rather than fitted to it.**

---

## 5. What I could NOT verify, and why

1. **Nothing here was executed.** Read-only audit, per the brief: no MAME run, no
   rebuild. Every "the device does X" is a reading of the current source plus a static
   re-measurement of the corpus, never an observation of the running machine. Where I
   quote a fired count or a measured symptom, it is the **device's own committed
   comment**, and those are exactly the things that go stale.
2. **Two lines were declared CLOSED and I honoured that**: the bit-11 alternate `lo12`
   family (§192) and `f31 = 4` (§194/§195). I audited only whether the device
   *implements* what those notes assert (A17 — it does) and proposed no experiment on
   either. D1 is a **scope correction to a census**, not a re-opening of §192's
   decidability question, which stays closed.
3. **The delay/DRAM and host/packet clusters were left alone** (other auditors), so
   `dram_dir`, the descriptor-cursor model, `ldptr.d`, the tag switch and the §188
   payload decode are quoted only where an ISA claim depends on them.
4. **Algorithms 79, 88, 89, 90, 91 are excluded** from every count above (IC310 /
   MN19413 streams). The tool inherits `pat_corpus.MALFORMED`; the 3057 = 83 + 2974
   identity is the check that the corpus is the same one the notes used.
5. **B3's residue is unobservable today.** I can show the device writes `0x85`/`0x8A`/
   `0x8C` every frame; I cannot show it is wrong, because nothing reads them. That is
   why R3 is a note-correction-or-measurement, not a code change.
6. **I did not run `upd6383d_diff.sh`** (it needs a built MAME disassembler; building is
   forbidden here), so the claimed 3057/3057 agreement between `dsp_disasm.py` and
   `upd6383d.cpp` is **unverified as of today**. D1 gives a concrete reason to re-run it
   once building is allowed: the two files now disagree about whether `SRC 0x02/0x04` and
   `ACT 0x03/0x04` exist.

---

## 6. Reproduce

```
python3 dsp/tools/audit_isa_census.py
```

Sections: `1` bit-11 family and the five phantom codes, by region; `2` bit 10 by region;
`3` C-format format-vs-payload and the opcode census; `4` bit 23 by class by region;
`5` the bit-4 store census; `6` mode × escape. Read-only; touches no ROM but
`original_ROMs/kn5000_subprogram_v142.rom`.
