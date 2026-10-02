# Wave 3a of the semantic push: toolchain lane (2026-09-25) -- STOPPED AFTER T1

Wave 3a is the solo toolchain stage of `notes/lanes/wave2-2026-09-25/WAVE3-PLAN.md`. It ran
as one workflow of four stages: T1 fixes the semantic bugs, V1 verifies T1 adversarially,
T2 adds the missing spellings and decodes, and V2 verifies T2. The owner asked for work to
stop at about 14:54. **T1 completed. V1 was interrupted 25 minutes in. T2 and V2 never
ran.** Main was clean at 08896b73 when the workflow was stopped.

## State at the stop

| stage | state | record |
|---|---|---|
| T1 semantic bugs | **done**, pin promoted | `T1-report.json` (the agent's structured report, verbatim); `TOOLCHAIN_VERSION` UPDATE 17; `notes/wave3a-toolchain-probes/` (every number T1 quoted, each with its gate and foil) |
| V1 adversarial verify of T1 | **interrupted, unreviewed** | `v1-interrupted/` (below) |
| T2 missing spellings/decodes | not run | task text: `workflows/wave3a-toolchain.js`, `T2_TASK` |
| V2 adversarial verify of T2 | not run | |

T1 in figures, taken from its report and re-checked at the stop:
- **Toolchain:** llvm-project `tlcs900_backend` 6488ae7d520a..4867e03232a6.
- **Pin:** llvm-mc sha256 `c949d618...`. `TOOLCHAIN_VERSION`, the binary and `~/compartilhado/toolchain-snapshot/llvm-mc.snap` agree.
- **Gate:** `make gate-all` 13/13 at 08896b73, run on a from-nothing build.
- **Tests:** llvm-lit TLCS900 95/95.

T1's `not_done` list is the starting point for the next toolchain work:
- the MUL/DIV immediate forms need an owner ruling, because MAME and Toshiba syntax name different registers;
- the rest of the ERP family still writes raw register numbers;
- the E8+r decodes are ones MAME calls `db`;
- masked-immediate decodes still print false text;
- ANDCF/ORCF/XORCF `#n,(mem)` have no decode;
- LD32mi still encodes a dst 0x08 store;
- about 4,263 `lda_dri` and about 4,600 direct-address pseudo spellings remain for 3b
  (this line first said 4,399, the count before the 136 +256 sites were converted;
  see Errata);
- 254 wsa1 "[llvm-mc cannot encode this]" tags remain.

## V1 and the T1 fix round (2026-10-01/02)

V1 was re-run as a three-lens panel (workflow `wave3a-v1-resume`): encoding truth,
tree truth, certification.  It returned 1 blocker and 11 majors (plus minors); the
fix round addressed all twelve -- llvm-project tlcs900_backend 216e342a7582..
d7752a16b6ee, disasm 83a3b70d..(the pin commit), pin d7752a16b6ee / llvm-mc
c39a1525.  TOOLCHAIN_VERSION UPDATE 18 is the record; the probes are in
`notes/wave3a-toolchain-probes/fixround/` and their figures in `../out/`.

### Re-verification after the fix round (V1:reverify, 2026-10-02)

Every one of the twelve panel issues was confirmed fixed: the original evidence was
reproduced at the old pin, and shown to be gone at d7752a16b6ee. The SP round trip is clean,
with **ASYM 0 over 2,555,184 whole-field probes** in all seven families. The gate is 13/13 and
llvm-lit TLCS900 is 102/102. **Still open** (verdict ISSUES -- the workflow allows one fix
round, so these were not fixed):
- **major:** comments beside lines that 83a3b70d respelled (`djnz xRR` -> `djnz16 rr`,
  `inc 0` -> `inc 8`) still state the retired meaning. Same class as the +256 comment that
  157bd9d8 fixed.
- **major:** 808088a74bc9 (bit numbers / counts must fit their field) does not cover the
  raw-operand bit and condition pseudos. Out-of-range values still assemble silently, often to
  a different operation, and a direct address is silently truncated.
- **minor:**
  - 1,276 `srl/sll/sla/sra r, 0` lines, where the CPU shifts 16. This is the twin of the 1,700
    `inc 0` lines.
  - Register names the CPU has (as MAME prints them, e.g. `QA`) still parse as symbols.
  - The bank-register diagnostic overstates the hardware.
  - Forward-referenced values are not range-checked.
  - ERP raw register bytes are truncated, or crash llvm-mc when symbolic.
  - `(xrr+sp)` is refused.
  - About 15 analysis scripts match `djnz\b`, which no longer sees the 624 `djnz16` lines.
  - Documentation leftovers.

Full returns: `v1-2026-10-02/panel_fix_reverify.json` (the three lenses, the fix report, the
re-verification). The script is `v1-2026-10-02/wave3a-v1-resume.js`.

## Errata (2026-10-02, from the V1 verifier panel)

- disasm `09b760eb`'s trailer names 8e188b215251, but that commit's tree builds
  with da00420dba8d (llvm-mc a7ee33d5) -- read the trailer as
  `LLVM: tlcs900_backend@da00420dba8d`.  TOOLCHAIN_VERSION "UPDATE 17 ERRATA".
- The two-decoder sweep's "was" figures (REG_DIFF 1,247, MNEM_DIFF 320 at
  da00420dba8d) are the 09b760eb classifier's; under the committed one they are
  1,263 / 304.  `T1-report.json` is kept verbatim and still says 1,247 / 320.
- "about 4,399 `lda_dri`" left for 3b is 4,263 (corrected above;
  `T1-report.json` and the 08896b73 message keep the old figure).

## What each file here answers

| file | question |
|---|---|
| `T1-report.json` | what T1 changed (llvm and disasm commits), how it was gated, what it did not do and why, its leads |
| `workflows/wave3a-toolchain.js` | the exact workflow script: the shared brief, the T1/T2 task texts, the verifier prompt, the fix-round logic |
| `workflows/wave3-docs.js` | the docs catch-up workflow that ran alongside it (technics-docs merges 2045487, 813e721, then 214c483) |
| `docs-workflow-results.json` | what each docs agent (write/check/fix x kn5000/wsa1status) returned, verbatim from the workflow journal |
| `v1-interrupted/*.py, *.sh` | V1's verification tools as it left them. Each docstring states its question. `strict_sweep.py` compares every operand of the families T1 touched against unidasm over the whole register/mode/displacement field. `tree_audit.py` asks whether any instruction line in the tree still disagrees with MAME. `roundtrip_tree.py` runs assemble, disassemble and reassemble for every line of those families. `verify_respells.py` checks the source respells. |
| `v1-interrupted/rt_fail.tsv` | `roundtrip_tree.py`'s partial output: 242 lines (no header row) that failed the round trip, e.g. `ldfr_werp DE, 0x3e` (`d7 3e 9a`) which the decoder does not decode -- consistent with T1's own ERP not_done item, but **not reviewed** |
| `v1-interrupted/tree_audit_bymnem.txt` | `tree_audit.py`'s partial counts per class and mnemonic. **Not reviewed**, and it mixes known, deferred pseudo spellings (`lda_dri`, `ldb_sri`, ...) with whatever is genuinely wrong |

**Nothing in `v1-interrupted/` is a finding.** V1 had not reported and nobody has read its
outputs critically. `dis.sh` still points at its original scratch directory. The large
outputs stayed in `~/compartilhado/disasm-lanes/wave3a-scratch/verify-T1/` and are regenerable
by re-running the scripts: `records.json` 25 MB, `tree_audit.tsv` 5 MB and
`out_{autoinc,disp,direct,muldiv,erp,ei}.tsv`.

## Next steps (in order) -- revised 2026-10-02

1. ~~Re-run V1~~ done; ~~T1 fix round~~ done (UPDATE 18, pin d7752a16b6ee).
2. A second fix round for the re-verification's two majors (stale comments beside the
   83a3b70d respells; out-of-range bit/condition pseudos) and the `sll/srl/sla/sra r, 0`
   respell. Then **T2** (missing spellings / decodes, plus T1's remaining false-text
   items) and **V2**. The task texts are in `workflows/wave3a-toolchain.js`. Split T2 into a
   backend stage and a tree-wide respell stage, each verified, as
   `../WAVE3B-PLAN-2026-10-02.md` describes.
3. Then Wave 3b (`../WAVE3B-PLAN-2026-10-02.md`). Its inputs now exist:
   - the Wave 2 claims review (`../wave2-2026-09-25/claims-review/`);
   - `scripts/analysis/claims_lint.py` (`notes/claims-lint-2026-10-02/`);
   - the per-lane census worklists;
   - the event-code catalog (applied: de617909);
   - the unverified wsa1 naming packs (`../wsa1-naming-r1-2026-10-02/`).
4. **Owed blog post** (mame-blog `posts/kn7000/`, after part 266): the Wave 2 results, T1 and
   its fix round, the claims review (483/682) and the event-code catalog.
5. Lane scratch and `TMPDIR` go to `~/compartilhado/tmp/<project>-<topic>/` or
   `~/compartilhado/disasm-lanes/`, never `/tmp`. Deletion paths are written `"${VAR:?}"`.
