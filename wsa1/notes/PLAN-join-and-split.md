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
