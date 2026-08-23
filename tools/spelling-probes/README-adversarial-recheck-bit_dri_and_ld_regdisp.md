# Adversarial re-check of the `bit_dri` / `ld (r+disp)` spelling report (2026-08-23)

Independent verification of `README-bit_dri_and_ld_regdisp.md`. Nothing here
imports the scripts it checks: the site list, the ROM byte reads and the
llvm-mc encodings were all produced from scratch.

Signal read: raw bytes of `original_ROMs/kn5000_v7_program.rom`, load base
`0xE00000`. PASS = the `llvm-mc --show-encoding` bytes **equal** those ROM
bytes. Backend: `tlcs900_backend` @ `bcf152d1fe00`.

All scripts take the scratch directory from `$KN5000_PROBE_SCRATCH`
(default `$TMPDIR`). Run from the repo root.

| script | question it answers | command |
|---|---|---|
| `adv_mc.py` | (library) batch `llvm-mc` encoder, one line per candidate, bisecting on assembler errors | imported |
| `adv_enum_sites.py` | Independently: how many sites of the three forms exist in v7's reachable decode, and which of them can `translate()`/`canonical()` already spell? Writes `sites.pkl`. | `python3 tools/spelling-probes/adv_enum_sites.py` |
| `adv_sweep_proposed_rules.py` | Do the report's rules A/B/C, transcribed verbatim, reproduce the ROM bytes at every site? Writes `sites2.pkl`. | `python3 tools/spelling-probes/adv_sweep_proposed_rules.py` |
| `adv_controls.py` | Do the two negative controls assemble cleanly *and* emit different bytes at every site where they apply? | `python3 tools/spelling-probes/adv_controls.py` |
| `adv_phantom_reframe.py` | For the four overshoot sites: where does the undisassembled run really end, and what does the ROM really hold there? | `python3 tools/spelling-probes/adv_phantom_reframe.py` |
| `adv_census_sites.py` | Which addresses actually increment the `--forms` counter in `convert_reachable_ranges.py --forms`? (Tests the "phantoms inflate the census" claim.) | `python3 tools/spelling-probes/adv_census_sites.py` |
| `adv_refute_plus256_gap.py` | Is `f3 e5 00 01 41` a real backend gap? | `python3 tools/spelling-probes/adv_refute_plus256_gap.py` |

## Results

**Confirmed.** 807 sites; 2 / 15 / 12 real blocking sites at exactly the
addresses reported; all 29 spellings reproduce the ROM bytes; 0 still
unspellable; both negative controls assemble and emit wrong bytes at every
applicable site; the four overshoot decodes are phantoms and the ranges that
carry them are refused by `main()`.

**Refuted — 1: the "genuine backend gap" is a spelling that was not tried.**
`stb_dri`/`stw_dri`/`stl_dri` (`TLCS900InstrInfo.td:4738/4744/4747`,
`RIRegInst<0xF3, 0x40|0x50|0x60, 5, ...>`) already reach the +256 register
store. The report searched for the mnemonic string `st{b,w,l}_ind`; the defs
are named `_dri`. `adv_refute_plus256_gap.py` is the proof. What IS true is
narrower: the plain `ld` mnemonic cannot express +256 (the force-d8 sentinel
takes 256 to mean "wide form, displacement 0"), and `translate()` offers no
`_dri` candidate for that text — a **converter** gap, not a backend one, and
with 0 sites in v7 it blocks nothing.

**Refuted — 2: phantoms do NOT enter the `--forms` census.**
`adv_census_sites.py` replays `main()`'s accounting and records every address
that increments `FORMS`: 88 instances, **0** of them phantom. The refusal
"no `ret`, and does not end at a code boundary" runs *before* the spelling
loop in the same iteration, so an overshooting range is dropped before the
counter is touched. The phantom observation itself is real and worth keeping —
it just has no effect on the census.

**Corrected — the sweep's credit table.** "561 fixed by rule B, 235 by rule C,
5 already covered" overstates the marginal value. `adv_enum_sites.py` shows
**774** of the 803 real sites are ALREADY spellable, because `canonical()`
passes unidasm's text through unchanged and a *positive* printed displacement
is already correct. The honest decomposition is
**774 already spellable / 29 newly fixed (2 A + 15 B + 12 C) / 4 phantom**.
The report's verify script tries the proposed candidates first and credits the
rule that matched, which is why every positive-displacement site was billed to
a new rule.

## Coverage note

No site in v7's reachable decode has a **negative 16-bit** displacement
(0 of the 71 16-bit sites have `d16 >= 0x8000`), so rules B and C's 16-bit
negative branch is unexercised by real data. The printed digit count is a sound
width discriminator here: the histogram over all 805 `ld (r+disp)` sites is
`{2 digits: 734, 4 digits: 71}` — nothing else occurs.
