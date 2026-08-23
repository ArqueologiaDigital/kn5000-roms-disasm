# Adversarial re-check of the `ldmm` / `ld SP,#imm16` report (2026-08-23)

Independent verification of `README-ldmm_memtomem.md` and `README-ld_sp_imm16.md`.
Every spelling was re-assembled and every site's ROM bytes re-read from
`original_ROMs/kn5000_v7_program.rom` (base 0xE00000) without reusing the
original probe's site list.

| script | question it answers | command |
|---|---|---|
| `adv_verify_site_bytes.py` | what bytes are really at the 25 named sites? | `python3 tools/spelling-probes/adv_verify_site_bytes.py` |
| `adv_verify_ldmm_spellings.s` | do the 17 distinct proposed spellings emit those bytes? | `llvm-mc -triple=tlcs900 --show-encoding tools/spelling-probes/adv_verify_ldmm_spellings.s` |
| `adv_verify_ldmm_ldsp_scan.py` | which sites really block, once `resolve_branches` is applied as the converter applies it? | `python3 tools/spelling-probes/adv_verify_ldmm_ldsp_scan.py` (~6 min) |
| `adv_verify_ldmm_ldsp_marginal.py` | marginal bytes with ALL FOUR converter gates (truncation, label-orphan, plausibility screen, block re-assembly) | `python3 tools/spelling-probes/adv_verify_ldmm_ldsp_marginal.py {all,ldw,sp}` |
| `adv_verify_orphan_at_today_cut.py` | which `.Lc_` label does today's cut orphan? | `... F865DF F3A05F F39585` |
| `adv_verify_orphan_with_rule.py` | where does the range cut once the ldmm rule is in, and does THAT orphan a label? | `... F39585` |

## Results (v7 @ 28bbfe1)

* 23/23 `ld/ldw (imm),(imm)` spellings reproduce their ROM bytes — CONFIRMED.
* Whole-image sweep reproduced: v7 630->621/9 unmatched/0 collisions,
  v9 628->621/7/0, v10 628->621/7/0, same member distribution.
* `ld SP,#imm16` genuinely unspellable — CONFIRMED (GR16 has 7 registers,
  GR16SP has 8; `LD16ri_short` uses GR16). 1092 printed `ld SP,0x` sites in v7,
  none spellable.
* CORRECTION — marginal bytes. `blocking_ldmm_and_ldsp.py` omits the converter's
  label-orphan-on-truncation check and its whole-block re-assembly gate, so it
  credits 292 B as "converted today" that the converter refuses outright.
  Today = 0 B; with the family rule 242 B; with the `ldw` half alone 209 B
  (not 165 B / 79 B).
  Orphans proved: 0xF865DF cut #21 orphans `.Lc_f86637`; 0xF3A05F cut #15
  orphans `.Lc_f3a09a`; 0xF39585 cut #47 orphans `.Lc_f39627`, and WITH the
  rule cuts at #63 `sla A,BC` orphaning `.Lc_f39676` + `.Lc_f3965e` — so
  0xF39585 releases nothing either way.
* CORRECTION — the reason to ship the `ld` byte half is 0xF6A502
  (`AccScreen_UpdateBeatDisplay`, byte form at instruction #0 blocking 33 B),
  NOT 0xF39585.
* CORRECTION — "0 spellings whose first byte is 0x37" is false: `extpfx3`,
  `mrdb3`, `mrdw3`, `mrdl3`, `mrdd3` and `mrid3` all emit `[0x37,0x00,0x00]`.
  All six are the same `ExtPrefixInst` raw-byte emitter and none is a legitimate
  spelling — but the "appears nowhere in v7/v9/v10" guard must name the `mr*`
  family too, which IS used in the trees (mrdb5, mrdw3, mrdw5, mri_d2, mrib2,
  mrib4, mriw2, mriw4).
