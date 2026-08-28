# Wave 7 — the shared briefing every lane reads first

Written 2026-08-28 when the effort resumed after the wave-6 pause. This file is the
contract for the wave: what is true at its start, what each lane may touch, and what
it must produce. It is committed rather than passed around because the previous wave
learned that a plan living outside the tree goes stale inside one commit.

## Baseline, measured at resume (not copied from the handoff)

    python3 scripts/analysis/assert_byte_identical.py     -> PASS, from a `make clean`
    python3 scripts/analysis/source_coverage.py

    prom_a   374,691 substantive    43,012 filler   106,585 incbin   13 spans
    prom_b   320,217 substantive    44,612 filler   159,459 incbin  124 spans
    prom_c   395,072 substantive   129,216 filler         0 incbin
    prom_d   330,521 substantive   193,767 filler         0 incbin
    TOTAL  1,420,501 substantive (67.7%)

    sub_XXXXXX routines: 4,997      Evidence: lines: 2,706

## ⚠ The handoff's "next targets" list was STALE and is superseded by this file

`HANDOFF-RESUME-HERE.md` names `0xFE8000-0xFEB330` and `0xFEF746-0xFF3800` as prom_a's
next targets. **Both were converted by wave 6's later rounds**, after that paragraph was
written: `sub_FE8000` is at `prom_a/wsa1_prom_a.s:125114`, `sub_FEF746` at `:132040`, and
the 838-byte effect-name table at `0xFF047F` is `.byte` data at `:133500`. No `.incbin`
covers either range. Likewise prom_b's `0xF067A6-0xF0D79B` is now two spans, not one.

**Derive every target from the tree, never from a prose paragraph.** The span and
frontier tables below were regenerated at resume; regenerate them again before quoting.

## The rules (unchanged, and they are the point)

1. **The gate certifies the tree and nothing else certifies it.**
   `python3 scripts/analysis/assert_byte_identical.py` must print
   `PASS: every rebuilt ROM is byte-identical.` It rebuilds first. A full rebuild from
   `make clean` takes ~1.2 s, so there is no excuse for `--no-build`.
2. **The gate is blind to names and comments.** A confidently wrong routine header
   passes forever. Every documented error in this project's history was gate-clean.
   Therefore: every semantic name carries an `Evidence:` line; every quantified claim
   is reproduced by a committed script that was **tested on the last element as well as
   the first**; every name borrowed from the KN5000 carries a byte diff with the
   differing count stated.
3. **Prefer `sub_XXXXXX` plus a stated gap over a plausible guess.** An honest hole is
   worth more than a confident wrong name, and this tree has paid for that lesson.
4. Commits carry `LLVM: tlcs900_backend @ bcf152d1fe00 (bcf152d1fe003bf7a93ae303b98a66edf06527c0)`.

## Lane discipline for this wave

The four `.s` files are ONE FILE EACH (prom_a is 9.6 MB). **Two agents editing the same
`.s` corrupts it.** So:

* **Recon lanes are READ-ONLY on `prom_*/wsa1_prom_*.s`.** They may create new,
  uniquely-named files under `notes/`. They may not create a file another lane owns.
* **Conversion lanes own exactly one prom** and run in a round where no other lane owns
  that prom.
* A lane verifies with `make rebuilt_ROMs/wsa1_prom_X.llvm.rom` plus a byte compare of
  its own image; the FULL gate runs at the round barrier, before the commit.
* Nobody runs `git commit`, `git checkout`, `git stash` or `git reset`. The wave
  coordinator commits at each barrier. An agent that reverts a file destroys another
  lane's work.

## The gold-standard pattern for converting a span

Read these two together before starting; they are what a good lane looks like:

* `notes/prom_b_f65000_layout.py` — derives the segment boundaries from **content rules
  calibrated against a null corpus** (54,814 bytes of already-proven instruction text,
  on which the rules must fire ZERO times: `--null`). Not from a linear decode.
  `notes/prom_a_linear_decode_check.py` records why a linear decode pins nothing.
* `notes/gen_prom_b_f65000_module.py` — the emitter, which re-derives the layout on every
  run and refuses to print if a segment moved.

And the two prom_a tools, documented in `notes/prom_a-tooling.md`:

* `prom_a/roundtrip.py LO HI --block` — emits labelled assembly that has **already been
  assembled and byte-compared**, so it cannot break the gate.
* `prom_a/insert_region.py LO HI region.s` — splices it in, fixing the `.incbin` chain.

## ⚠ Tools that mislead — do not rank targets with these

* `notes/prom_c_frontier.py`: **132 of its 135 targets are phantoms**, produced by
  linearly disassembling ASCII descriptor strings. Its own docstring says so.
* `notes/prom_b_span_frontier.py`: its `proven 0` is not evidence of data. Its call-site
  scanner only recognises `ld XIY / ld XIX / call`, so a region reached through
  `DisplayListB_RunOne_Stack` scores 0 while being well-evidenced. Wave 6's best target
  scored worst on it.
* A frontier count that does not fall after converting a **data** span is correct, not a
  failure. Data retires no call target. Do not quote a drop that did not happen.

Good tools: `prom_a_module_frontier.py`, `prom_b_module_frontier.py`,
`vector_map.py --unconverted`, `prom_c_kernel_map.py`, `prom_a_xref.py`, `prom_c_xrefs.py`,
the `*_audit_callsites.py` pair, `scripts/analysis/transplant_kn5000_labels.py`
(105 byte-verified proposals — read its retraction banner first).

## The frontier at resume

prom_a `.incbin` spans, largest first, with the thunk runs that point into each:

    0xFAD800-0xFB2000  18,432   T_F40850 (20 slots), T_F41F10 (12), T_F40840
    0xFA5AEB-0xFAA000  17,685   T_F43350 (top run, 8,886 extent), T_F40744 (7,668), T_F40714
    0xFA1404-0xFA5400  16,380   no thunk targets -- identify before converting
    0xF85FF9-0xF89800  14,343   T_F40F34 (125 refs), T_F40F58
    0xF96018-0xF99021  12,297   T_F40244, T_F401D4
    0xFC3000-0xFC5400   9,216   0xF8C000-0xF8DA00 6,656 (T_F40664)
    0xFDE70F-0xFE0000   6,385   0xFC7000-0xFC8000 4,096
    plus four spans under 400 bytes

prom_b, largest first:

    0xF4F000-0xF55000  24,576   T_F42E40 (top run, 4,624 extent)
    0xF067A6-0xF0C735  24,463   T_F41F54 (5 unc), T_F42F80 (40 refs), T_F42320, T_F433D0
    0xF353AB-0xF3934C  16,289   T_F41250 (4,091), T_F42660
    0xF17559-0xF1B400  16,039   T_F42FD0
    0xF5553F-0xF57D1E  10,207   T_F40D90 (35 slots), T_F42C70 (33 refs), T_F40ED0
    0xF78029-0xF7A400   9,175   0xF3E15C-0xF40000 7,844   0xF7E2D8-0xF80000 7,464
    0xF00000-0xF01800   6,144   T_F409A0 (33 refs), T_F40970

prom_c and prom_d have **zero `.incbin`** — territorially complete. Their remaining work is
meaning, not territory: the 65,972-byte byte-code stream at `0xFCD0F7-0xFDD2AA` left whole
because its framing desynchronises at the fifth record (it needs its interpreter found
first — guessing a stride is this project's known failure mode), gap A's four registers
with no statement of any kind (`0x0440`, `0x0480`, `0x04C0`, `0x0500`), and the ~4,997
`sub_XXXXXX`.

## What the emulator is asking for

`notes/WSA1-EMULATION-DISASM-GAPS.md`, ~95 ranked entries. Prefer targets that answer it.
Its top three were refreshed on 2026-08-26 **after** wave 6 closed the previous three, so
read that section rather than the older body.
