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
- about 4,399 `lda_dri` and about 4,600 direct-address pseudo spellings remain for 3b;
- 254 wsa1 "[llvm-mc cannot encode this]" tags remain.

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

## Next steps (in order)

1. **Re-run V1** on the current pin. The workflow cannot be resumed from another session
   (`resumeFromRunId` is session-scoped). Instead, edit `workflows/wave3a-toolchain.js` to
   start at `phase('V1 verify')` and seed `t1` from `T1-report.json`. The tools in
   `v1-interrupted/` are a head start, not a verdict.
2. If V1 finds blockers, run a T1 fix round (the script's own loop). Otherwise go to T2, then V2.
3. Then Wave 3b, the parallel lanes on the new toolchain: `WAVE3-PLAN.md` section 3b, plus the
   items appended at the end of `notes/lanes/wave2-2026-09-25/WAVE3-LEADS.md` after the docs
   catch-up (event-code names, the HD-AE5000 signature header, the tone-DB inverse check).
4. **Owed blog post** (mame-blog `posts/kn7000/`, after part 266, which promised this): the Wave 2 results
   (strict 64.15% -> 95.04%, the four semantic merge conflicts) and T1's semantic backend fixes
   (the `di` alias, post-increment operands, true register names, the extended-register LD direction).
   Not written: work stopped first.
5. Lane scratch and `TMPDIR` go to `~/compartilhado/tmp/<project>-<topic>/` or
   `~/compartilhado/disasm-lanes/`, never `/tmp` (owner's standing rule since 2026-09-25).
   Tell every sub-agent the same.
