# The numbers

*BEFORE = a worktree of 3947944a, the last commit before this lane.
AFTER = the fixed tree. Same tool, same invocations (SAFE_ARGV in
notes/git_path_audit.py).*

| script | before reads/bad | after reads/bad |
|---|---:|---:|
| `notes/asm_source.py` | 0/0 | 0/0 |
| `notes/audit_wave5_checks.py` * | 1/1 | 1/0 |
| `notes/gen_prom_a_cover_round1.py` * | 1/1 | 1/0 |
| `notes/gen_prom_a_cover_round2.py` * | 1/1 | 1/0 |
| `notes/gen_prom_b_cover_round2.py` | 1/0 | 1/0 |
| `notes/git_path_audit.py` | - | 0/0 |
| `notes/kernel_join_probe.py` | 2/0 | 2/0 |
| `notes/maincpu_join_probe.py` | 2/0 | 2/0 |
| `notes/probe_health.py` | - | 224/0 |
| `notes/prom_a_f85ff9_layout.py` * | 1/1 | 7/0 |
| `notes/prom_a_fa5aeb_layout.py` * | 1/1 | 7/0 |
| `notes/prom_a_fad800_layout.py` * | 1/1 | 14/0 |
| `notes/prom_a_frontier_delta.py` * | 1/1 | 1/0 |
| `notes/prom_a_naming_wave8_apply.py` | 1/0 | 1/0 |
| `notes/prom_a_preservation_check.py` * | 1/1 | 7/0 |
| `notes/prom_b_evidence_audit.py` * | 1/1 | 1/0 |
| `notes/prom_b_f65000_layout.py` * | 1/1 | 4/0 |
| `notes/prom_b_naming_preservation.py` * | 1/1 | 4/0 |
| `notes/prom_b_probe_answer_diff.py` * | 1/1 | 3/0 |
| `notes/prom_c_probe_health.py` * | 3/2 | 63/0 |
| `notes/prom_c_round3_frontier_delta.py` * | 1/1 | 31/0 |
| `notes/prom_c_split.py` | 1/0 | 1/0 |
| `notes/promb_macro_preservation.py` * | 1/1 | 4/0 |
| `notes/promb_macro_rewrite.py` | 1/0 | 1/0 |
| `notes/verify_a1_independent_check.py` * | 14/5 | 17/0 |
| `notes/wave7-verify-probes/wave7_r3_citation_check.py` * | 1/1 | 1/0 |
| `notes/wave7-verify-probes/wave7_r3_promc_refute.py` * | 1/1 | 1/0 |
| `notes/wave7-verify-probes/wave7_r9_promc_citation_check.py` * | 1/1 | 1/0 |
| `notes/wave7_round4_review_wd3_prom_d.py` * | 1/1 | 9/0 |
| `notes/wave7_round5_review_wd3_prom_d.py` * | 1/1 | 4/0 |
| `notes/wave7_round6_review_wb_prom_b.py` * | 2/1 | 10/0 |
| `notes/wave7_round8_review_wd3_prom_d.py` * | 1/1 | 17/0 |
| `notes/wave7_round9_review_wb_prom_b.py` * | 9/3 | 28/0 |

**BEFORE: 31 scripts traced, 24 issued a failing or misspelled git read, 31 bad reads.**

**AFTER: 33 scripts traced, 0 issued a failing or misspelled git read, 0 bad reads.**

`*` marks a script that had at least one bad read and now has none.

The AFTER sweep covers TWO MORE scripts than BEFORE, which is the
point of the discovery rule in git_scripts(): a script migrated off a
raw git call must STAY in the sweep, or the instrument stops
measuring exactly what it just fixed.  The two are
notes/prom_c_round3_frontier_delta.py and
notes/promb_macro_preservation.py, which read a revision only through
asm_source and so had no raw call site to be discovered by.
