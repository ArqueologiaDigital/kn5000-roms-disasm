# Plan: join the proms into maincpu/subcpu, then split by source file

**Status: FOR REVIEW. Nothing below has been done.**

Written after measuring the tree rather than from assumption; every number here has a command
beside it.

---

## 0. What the images actually are, and the one place the brief does not fit

| image | base | size | role |
|---|---|---:|---|
| `prom_b` | `0xF00000` | 512 KiB | CPU 1, **low** half |
| `prom_a` | `0xF80000` | 512 KiB | CPU 1, **high** half |
| `prom_c` | `0xF80000` | 512 KiB | CPU 2 |
| `prom_d` | *not established* | 512 KiB | data only |

★ **prom_b + prom_a are contiguous**: `0xF00000`–`0xFFFFFF`, exactly 1 MiB, no gap and no overlap.
That is a clean join and it is what "maincpu" should mean.

⚠ **prom_c + prom_d is NOT a joinable pair, and I recommend against forcing it.** prom_d's load
address is not established. `prom_d/prom_d.ld` carries an argued decision — "ORIGIN STAYS 0, AND
THAT IS NOW A DECISION RATHER THAN AN ADMISSION" — resting on a search that could have found a tie
and did not. Joining it into subcpu's address space means *inventing* a base, which is the exact
class of error this project has caught repeatedly (most recently a lane framing `"D GROUP NAMING"`
as `ld XIX,0x4f524720`, with the byte gate passing).

**Proposal:** `subcpu` = prom_c alone. prom_d becomes a separate data image, exactly as the KN5000
tree keeps `table_data/` and `custom_data/` outside its CPU trees. If a byte-level tie from a
prom_c instruction to a prom_d offset is ever found, prom_d can be folded in *then*, on evidence.

---

## 1. The blocker I checked first, because it would sink the join

Joining two files into one assembly unit requires unique labels. Measured:

    maincpu (prom_a + prom_b):  4 collisions out of 10,976 labels
    subcpu  (prom_c + prom_d):  0

The four are `IndexedTable_GetPtr`, `LCD_ScreenRedraw_Begin`, `LCD_ScreenRedraw_End`, and `end`.
Three of them are not accidents: round 8 established that prom_b holds routines **byte-identical
over their whole extent** to prom_a's (`LCD_ScreenRedraw_Begin` 14 B, 0 differ; `_End` 6 B, 0
differ). So the collision is a real fact about the machine and the rename should say so —
`LCD_ScreenRedraw_Begin_PromA` / `_PromB`, not a numbered suffix.

---

## 2. Phase order, and what has to hold at every step

**The byte gate is the whole safety net and it must stay green at every commit.** Today it rebuilds
four ROMs from four sources. After the join, ONE maincpu source must still produce TWO byte-exact
512 KiB images.

* **P0 — prove the build shape before moving a line.** Add a `maincpu.ld` with two output sections
  (`0xF00000` and `0xF80000`) and objcopy each to its own binary; verify against the current
  four-way build. If this cannot be made byte-exact, the join stops here and I report that instead
  of forcing it.
* **P1 — join maincpu.** `maincpu/wsa1_maincpu.s` = a manifest of `.include`s, exactly the KN5000
  shape (`v142/subcpu/kn5000_subprogram_v142.s` includes `subcpu_vectors.s` then
  `subcpu_data_tables.s`, with core code inline). Resolve the 4 collisions. Gate green.
* **P2 — subcpu.** Rename prom_c to `subcpu/`, no content change. prom_d moves to `data/` unchanged.
* **P3 — split into dedicated files.** See §3.
* **P4 — name transfer from KN5000.** See §4.

⚠ `.incbin` paths are repo-root-relative and the Makefile passes `-I .`; moving a `.s` is safe as
long as that stays. I will assert it in P0, not assume it.

---

## 3. Where to split — and the cross-reference decides it, not my taste

★ **This is the part with real evidence behind it.** `notes/kn5000_shared_runs.py` establishes that
**28,916–32,795 bytes of prom_c are byte-identical to the KN5000 sub-CPU payload**, against a
shuffle null of 0. The KN5000 splits its sub-CPU into `subcpu_vectors.s`, `subcpu_data_tables.s`
and `subcpu_fp_math.s`. **Where the bytes match, the WSA1 subcpu should split at the same
boundaries** — the file structure is then a measured correspondence, not a filing preference.

Proposed initial split, each file justified by something already in the tree:

| file | justified by |
|---|---|
| `subcpu/subcpu_vectors.s` | the vector table, already framed; mirrors KN5000 |
| `subcpu/subcpu_data_tables.s` | the tone/curve pools; the KN5000 counterpart is 11,758 lines |
| `subcpu/subcpu_fp_math.s` | `Double_Add`/`Double_Subtract`/`Double_ToInt32` etc; KN5000 has the same file |
| `subcpu/subcpu_dsp.s` | `DSP_ChanFreq_*`, `DSP_AlgoChannel_*`, the 0x10C000 staging |
| `maincpu/maincpu_panel.s` | the panel chain solved this wave: wire → group → event → screen |
| `maincpu/maincpu_display_lists.s` | the display-list interpreters and their tables |
| `maincpu/maincpu_disk.s` | FDC + block device (`Disk_PortA3_*`, `Fdc_*`) |
| `maincpu/maincpu_midi.s` | the MIDI-in router converted in wave 7 |
| `maincpu/maincpu_kernel.s` | the 36-pair kernel shared with prom_c, 35 byte-identical |

⚠ **The kernel file is the interesting one.** `notes/prom_c_kernel_map.py --pairs` shows 36 routine
pairs between prom_a and prom_c, **35 structurally identical to the byte**. Splitting both CPUs'
kernels into files at the same boundaries makes that correspondence visible in the directory
listing instead of only in a note.

---

## 4. Name transfer — the opportunity, and the trap that is already measured

The brief's hope is right: comparative analysis should name currently-unnamed routines. Two levers,
both already quantified:

1. **Byte-identical runs, prom_c ↔ KN5000 sub-CPU.** `scripts/analysis/transplant_kn5000_labels.py`
   already does this and every proposal is byte-verified. ⚠ Its retraction banner must be read
   first: an earlier version emitted eight proposals and **all eight named the wrong object**,
   because it matched against a spliced ROM and converted offsets with a constant that was short by
   `0xEB00`.
2. **The prom_a ↔ prom_c kernel pairs**, 35 of 36 identical to the byte.

⚠⚠ **THE TRAP, measured in wave 7 round 2 and not negotiable:** the WSA1 and KN5000 share **68 SFR
register NAMES and exactly ONE shared address** (`PBFC`, `0x2F`). `CAP4L/CAP4H` is the same name for
different hardware; `INTET10`/`INTET01` is the same register spelled backwards. **A name may
transfer; an ADDRESS may not.** Every borrowed name carries a byte diff with the differing count
stated — one WSA1 routine is 80 of 81 bytes identical to the KN5000's and the single difference is
the peripheral base.

⚠ And `notes/wave7_kn5000_transplant_residue.py` records that the transplant is already **complete**
for prom_c: 15 of 19 names applied, and the 4 residuals should NOT be imported because they name
sub-objects of structures this tree models better. Do not re-import them.

---

## 5. What I would NOT do

* **Not fold prom_d into subcpu** without a byte-level tie. §0.
* **Not rename anything to match KN5000 where the bytes differ.** The correspondence is the
  evidence; without it a shared name is a guess wearing a citation.
* **Not touch the 8,057 existing headers or 7,770 Evidence lines.** The split moves lines between
  files; it must not rewrite one. I will verify this the way the coverage rounds did: every hunk
  accounted for, and a diff that shows pure movement.
* **Not treat the split as a naming round.** Semantics remain a separate goal; where comparative
  analysis *does* yield a name, it carries its byte diff.

---

## 6. Verification at every phase

* `python3 scripts/analysis/assert_byte_identical.py` — PASS at every commit, no exceptions.
* A movement check: the concatenation of the split files is byte-identical to the pre-split source,
  modulo the four collision renames. This makes "did the split lose a line?" decidable.
* `python3 notes/reachability.py --selftest` and `--targets` — the coverage result must not move.
* `python3 notes/wave7_documentation_metrics.py` — the header and Evidence counts must not FALL.

---

## 7. Estimated shape

P0 is the risk. If one maincpu source cannot produce two byte-exact images, I report that and
propose keeping the sources separate but the *directory* structure joined, which still gets the
KN5000-style layout and the shared splitting. P1–P2 are mechanical. P3 is the bulk. P4 is
open-ended and should stop when the evidence does.

---

## 8. AMENDMENT: the KN5000 tree is not finished either, and alignment runs BOTH ways

The brief has been extended: KN5000's disassembly is itself incomplete, so where the two trees
disagree the fix may belong on the **KN5000** side, and both trees may be edited.

**This is safe to do, and I checked before proposing it.** `kn5000-roms-disasm` carries the same
byte gate (`scripts/analysis/assert_byte_identical.py`), it currently prints
`PASS: every rebuilt ROM is byte-identical.`, and its tree is clean at `46a916e`. So it can be
edited under identical discipline: gate green at every commit, no exceptions.

### The rule I propose for resolving a disagreement

Not "the older tree wins" and not "the tree I am standing in wins". **The side with the
reproducible measurement wins, and if neither has one, neither tree changes** — the disagreement
gets written down in both instead.

That matters because this project has twice shipped a cross-tree claim that was wrong in the
plausible direction: the label transplant whose first version named the wrong object at every one
of eight sites, and the SFR trap where 68 register names are shared and exactly one address is.

### A worked example, already sitting in both trees

WSA1 `prom_d` says, of the descriptor tag:

    the element SIZE is the descriptor's own tag bit 7: 6 bytes when it is CLEAR
    (161 records here) and 8 when it is SET (0)
    ⚠ ../kn5000-roms-disasm's note on the same field states the OPPOSITE polarity.
    It is measured here, not borrowed: with the polarity inverted JOIN 2 holds for
    0 of 318 records at slot +0x30

KN5000 `table_data/tone_database_aux.s:718` says:

    bit 7  zone-record stride: set -> 6 bytes (143 records), clear -> 4 bytes

⚠ **And these do not actually contradict cleanly, which is the point.** WSA1 reads
clear→6 / set→8; KN5000 reads set→6 / clear→4. That is not an inversion — **the sizes differ too**
(4 against 8). So there are two live possibilities and the comparison cannot settle which:

1. one tree has the polarity backwards, or
2. the two machines genuinely use different record formats, and the "same field" premise in the
   WSA1 note is itself the error.

**Neither tree should be edited until that is measured on both sides.** The WSA1 side already has
its null (0 of 318 under inversion); the KN5000 side needs the equivalent — does its 143-record
count survive the WSA1 polarity, and does its 4-byte stride appear at all in prom_d? This is a
concrete, bounded first job, and it is a better opening move than any file rename because it tests
the whole premise of aligning the two trees.

### What this changes in the phases above

* **P4 becomes bidirectional.** Every cross-tree name or boundary carries its byte diff and a
  statement of which tree the evidence came from. Where WSA1's measurement is the stronger one, the
  KN5000 file gets the correction and the WSA1 note stops being a lone dissent in a comment.
* **A new P5: reconcile the disagreements both trees already record.** The WSA1 tree contains at
  least one explicit "the sibling says the opposite" note; there may be more in both directions.
  Enumerate them, measure each, and land the result in whichever tree is wrong — or in both, if the
  answer is "different formats".
* **Splitting boundaries may move KN5000 files too.** If the byte-identical runs suggest a cleaner
  cut than KN5000's current `subcpu_data_tables.s`, proposing that cut on the KN5000 side is now in
  scope rather than something to work around.

⚠ **What does not change:** neither tree's gate may go red, neither tree's existing comments and
semantic labels may be overwritten, and a name still does not transfer without a byte diff and a
differing count.

---

## 9. AMENDMENT 2: four constraints from review, three of them measured before answering

### 9.1 ⚠ DO NOT FLATTEN KN5000 — and the work is SYMMETRIC, not one-way

Accepted without reservation, and the measurement makes it sharper than a rule about my behaviour:
**KN5000 is not uniformly split either.** It has 511 `.s` files and 36.2 MB, which sounds finished,
but two of them are monoliths:

    1,394 KB   v142/subcpu/kn5000_subprogram_v142.s     <- subcpu core, INLINE
    1,256 KB   subcpu/boot/kn5000_subcpu_boot.s
    1,451 KB   table_data/style_records.s               (data, legitimately one file)

Its subcpu splits out only `subcpu_vectors.s`, `subcpu_data_tables.s` and `subcpu_fp_math.s`; the
whole core -- RESET, main loop, voice management, tone generation, DSP protocol -- sits inline in
the top-level file. Its maincpu trees are better split (`sequencer/accompaniment_engine.s`,
`sequencer/sequencer_engine.s`).

**So "split into dedicated per-subject files" is a job on BOTH trees**, and KN5000's subcpu core
needs the same treatment WSA1's does: `subcpu_dsp.s`, `subcpu_voice.s`, `subcpu_tonegen.s`,
`subcpu_main.s`. Flattening is not a risk I am guarding against — splitting KN5000 further is part
of the deliverable.

### 9.2 ★★ THE SHARED KERNEL GETS ONE SOURCE, AND IT GOES FIRST

Accepted, and it should go first for a reason the data makes plain.
`python3 notes/prom_c_kernel_map.py --pairs`:

    routine                          slots   same  operand   STRUCTURAL
    Kernel_ResumeTask                    9      9        0        0
    Kernel_StartTask                    45     40        5        0
    Kernel_YieldRotate                  33     30        3        0
    Kernel_ServiceSoftTimers            28     23        5        0
    IRQ_Epilogue                        20     18        2        0
    Kernel_InitRam                      84     51       31        2
    ...

★ **35 of the 36 pairs have ZERO structural differences.** Every difference outside `Kernel_InitRam`
is an OPERAND -- overwhelmingly a peripheral base, the same substitution the tree already documented
when it found a routine 80 of 81 bytes identical to the KN5000's where the single differing byte was
the peripheral base.

That is exactly the shape `.if/.else/.endif` is for, and it is the right first move:

    kernel/kernel.s          one source, assembled twice
    kernel/kernel_maincpu.inc   .equ CPU_MAINCPU, 1   + this CPU's peripheral bases
    kernel/kernel_subcpu.inc    .equ CPU_SUBCPU, 1    + its bases

⚠ **The byte gate makes this honest in a way prose never could.** If the conditionals are wrong by
one byte, both images stop rebuilding. A shared kernel source that assembles to the SAME BYTES in
both CPUs is proof the sharing is real -- not a claim that two listings look alike.
⚠ `Kernel_InitRam` has the only 2 structural differences, both inside an 8-byte inline data block.
It gets the conditional treatment or stays duplicated, whichever the gate accepts; it does not get
forced.

### 9.3 Is the kernel ALSO in KN5000? MEASURED, AND THE ANSWER IS "NOT YET KNOWN"

I tested it rather than assume, and the test is **underpowered** -- which I would rather report than
dress up. `notes/kernel_three_way.py` takes each kernel routine's bytes straight from prom_c and
searches all 41 KN5000 images for that exact run:

    0 kernel routines found in a KN5000 image, 5 not found, 32 TOO SHORT TO COUNT (<24 B)

**Only five routines were long enough to be evidence**, so "0 of 5" is not a negative result about
the machine. The instrument itself is sound -- its negative control (a synthetic 32-byte run) is
absent from all 41 images and its positive control (the already-measured shared run at `0xFDE32B`)
is FOUND -- so a miss would mean something if the sample were bigger.

**First job, before any renaming:** redo this against `prom_c_kernel_map.py`'s actual pair extents
rather than my label heuristic, and allow structural matching (same mnemonic sequence, different
operands) rather than byte-identity alone -- because §9.2 shows the differences between two WSA1
CPUs are already operand-only, so a third processor would differ at least that much.
**If it lands, one kernel source serves three processors across two instruments and it is the
strongest possible starting point. If it does not, we know, and the two trees converge elsewhere.**

### 9.4 Would "full disassembly before semantics" work on KN5000? YES, and I would make it a prerequisite

    11,143 .incbin directives across 130 KN5000 source files

So the same question that reframed the WSA1 work applies with force: **how many of those bytes are
reachable code, and how many are data?** On WSA1 the answer was 16.4%, which turned a 107,371-byte
job into a 17,558-byte one and stopped two rounds from converting data that nothing executes.

`notes/reachability.py` should port with modest work:

* Both machines are TLCS-900 (WSA1 TMP95C061, KN5000 TMP94C241), so `unidasm -arch tlcs900` is the
  decode authority for both -- the KN5000 tree already ships `.unidasm` files.
* ⚠ Its `IMAGES`/`CPU1`/`CPU2` tables and the routine-directory scan are WSA1-specific and must be
  re-derived, not copied. The KN5000 has its own indirection structures.
* ⚠ Its source-line regex already had to learn that prom_a and prom_b write different line shapes;
  KN5000 will be a third. That bug emptied three of five seed classes for prom_b, so it is the
  first thing to check, not the last.

**Recommendation: make this P-1, ahead of the join.** Splitting a tree into per-subject files while
11,143 `.incbin` directives remain means every future conversion lands in a file chosen before
anyone knew what the bytes were. Getting KN5000's reachable code converted first makes the split
durable -- and the same tool then reports both trees' coverage in one number.

### 9.5 Revised phase order

    P-1  port reachability.py to KN5000; report its reachable-vs-data split       (new, first)
    P0   prove one source can emit two byte-exact images                           (unchanged)
    P0.5 the three-way kernel test, done properly                                  (new)
    P1   ★ ONE SHARED KERNEL SOURCE for WSA1 maincpu+subcpu, .if/.else, gate green (promoted)
    P2   join maincpu; subcpu = prom_c; prom_d separate
    P3   split BOTH trees into per-subject files -- including KN5000's two monoliths
    P4   name transfer, bidirectional, every name with its byte diff
    P5   reconcile the disagreements both trees already record

---

## 10. APPROVED — with the KN5000 preservation constraint, and a re-scope from measuring it

### 10.1 The constraint, applying to BOTH trees now

⚠⚠ **Do not destroy pre-existing comments, documentation headers, or semantic structures in the
KN5000 tree.** Modify one only when the change is *demonstrably* semantically better, and say why
in the commit.

This is the same rule the coverage goal ran under for WSA1, where it was verified rather than
promised: round 1's prom_a diff was 3,782 insertions and FIVE deletions, all five `.incbin`
directives. The KN5000 tree is larger and older, so the same standard applies with the same
verification: **every hunk accounted for, and a diff that shows movement rather than rewriting.**

⚠ The KN5000 tree has its own byte gate, it PASSES today, and it is clean at `46a916e`. Green at
every commit there too.

### 10.2 ★ WHAT MEASURING KN5000 CHANGED ABOUT THE ROUTE

    incbin directives by tree area
        v7   maincpu   3,810
        v9   maincpu   3,642
        v10  maincpu   3,642
        table_data        28
        custom_data       11
        hdae5000          10
        ★ v142/subcpu      0   -- payload AND boot
        ★ subcpu/boot      0

★★ **KN5000's sub-CPU is already territorially complete**, exactly as WSA1's prom_c is. The 11,143
incbins are **entirely in the three maincpu versions**, which are three builds of the same program —
so that debt is one job seen three times, not three jobs.

**This unblocks the ordering.** P-1 (the KN5000 coverage pass) was proposed as a prerequisite for
everything. It is not: it is a prerequisite only for splitting the **maincpu** trees. The whole
sub-CPU line of work — the kernel, the WSA1 prom_c ↔ KN5000 subcpu comparison, the shared-source
experiment — can start immediately, because **both trees' sub-CPUs are already fully converted.**

Revised route, and it is now two tracks rather than one queue:

    TRACK A (starts now, nothing blocks it)
      A1  ★ ONE SHARED KERNEL SOURCE for WSA1 maincpu+subcpu, .if/.else, gate green
      A2  the three-way kernel test done properly (structural, real pair extents)
      A3  if A2 lands: extend the shared source to KN5000's subcpu
      A4  split BOTH sub-CPUs into per-subject files at the byte-matched boundaries

    TRACK B (parallel; gates the maincpu split only)
      B1  port reachability.py to KN5000's maincpu; report reachable-vs-data
      B2  convert KN5000 maincpu's reachable code, semantics deferred
      B3  join WSA1 maincpu (prom_b+prom_a) and split both trees' maincpu trees

★ A1 does NOT require the maincpu join. A shared kernel source is `.include`d by
`prom_a/wsa1_prom_a.s` and `prom_c/wsa1_prom_c.s` with different `.equ` settings; the join is a
separate concern. So the thing you asked to be prioritised is also the thing with the fewest
prerequisites, which is a good sign for the plan rather than a coincidence.

### 10.3 Addresses, for the record

    WSA1  prom_b  0xF00000  512K   maincpu low        KN5000  maincpu   0xE00000  2M  (v7/v9/v10)
    WSA1  prom_a  0xF80000  512K   maincpu high       KN5000  subcpu    0x000400  251K
    WSA1  prom_c  0xF80000  512K   subcpu             KN5000  subcpu boot 0xFE0000 128K
    WSA1  prom_d  not established  data               KN5000  table_data 0x800000  2M
                                                      KN5000  custom_data 0x300000 1M
                                                      KN5000  hdae5000   0x280000 512K
