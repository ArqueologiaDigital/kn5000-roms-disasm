# SHIPPED-FIX LIST — derived, never counted

source: `upd6383.cpp` / `upd6383.h` @ 193ee63   register: 120 sections
shipped `m_specmask` = **0xb910e446a39b440f** (popcount 28)

## 0. RULE 20 — the self-test, printed BEFORE any list

| # | check | result | what it read | what it demanded |
|---|---|---|---|---|
| | T1  LFOWRAP is IN (§225 shipped it as the default) | PASS | `LFOWRAP in=True` | `True` |
| | T2  the §223 NOP-GUARD narrowing is IN (ungated, unconditional count) | PASS | `narrowing sections=[223]` | `223 present` |
| | T3  UPD6383_NOCARRY is OUT (default OFF) | PASS | `UPD6383_NOCARRY: off` | `off` |
| | T3  UPD6383_SRC0B2 is OUT (default OFF) | PASS | `UPD6383_SRC0B2: off` | `off` |
| | T3  UPD6383_DRPUB is OUT (default OFF) | PASS | `UPD6383_DRPUB: off` | `off` |
| | T3  UPD6383_EPIBUS is OUT (default OFF) | PASS | `UPD6383_EPIBUS: off` | `off` |
| | T3  UPD6383_PICKUP is OUT (default OFF) | PASS | `UPD6383_PICKUP: off` | `off` |
| | T4  the RIG knobs are non-bool and sit at baseline 0 | PASS | `NOZ05=0 XB85=0` | `0 / 0` |
| | T5  §196 is OUT -- its own heading says "Measured, no gate" | PASS | `§196 in shipped set=False` | `False` |
| | T5  §203 is OUT -- its own heading says "Not shipped" | PASS | `§203 in shipped set=False` | `False` |
| | T5  §217 is OUT -- its own heading says "UPD6383_DRPUB NOT SHIPPED" | PASS | `§217 in shipped set=False` | `False` |
| | T5  §180 is OUT -- its own heading says "Not shipped." | PASS | `§180 in shipped set=False` | `False` |
| | T6  every getenv site is resolved to a member (denominator 19) | PASS | `unresolved=[]` | `[]` |
| | T7  m_specmask parsed from its ONE initialiser | PASS | `0xb910e446a39b440f -> 0xB910E446A39B440F` | `equal` |
| | T8  SHIFT-extracted mask bits are counted (bits 42/45 are `>> N & 7`) | PASS | `shift-bearing bits=[35, 36, 37, 42, 43, 44, 45, 46, 47, 48, 49, 50]` | `42 and 45 present` |
| | T9  every bit SET in the default is also REFERENCED (else the census is blind) | PASS | `set-but-unreferenced=[1, 2, 3]` | `reported, not fatal: bits 1/2/3 are known set-and-unreferenced` |
| | T10 the logerror scanner saw the whole file (denominator 267 calls) | PASS | `267 logerror calls` | `>100` |

**17 of 17 self-tests PASS.**

## A. ENV GATES ACTIVE IN THE SHIPPED DEFAULT — **FORCED**

Denominator: **19** `getenv("UPD6383_*")` sites; 13 bool gates, of which **7 initialise `true`**; 6 bool gates default `false`; 6 non-bool knobs.

| § | gate | member | default | what it changes | commit |
|--:|---|---|:--:|---|---|
| §200 | `UPD6383_ROTSIGN` | `m_rotsign` | **true** | ★ The proof is bit-exact and was NOT the falsifier I pre-registered (I predicted the complement 65536-D and got neither that nor the old values): with the sign  | kn5000-roms-disasm@594c29c |
| §201 | `UPD6383_BODYIX` | `m_bodyix` | **true** | \n", m_bodyix ? 1 : 0); | kn5000-roms-disasm@49bf53b |
| §203 | `UPD6383_CFMTIX` | `m_cfmtix` | **true** | \n", m_cfmtix ? 1 : 0); | kn5000-roms-disasm@5824a0c |
| §209 | `UPD6383_DSCPRE` | `m_dscpre` | **true** | ★ FREE PARAMETERS, not measured, printed so they are never read as forced: the sweep pins L1 only to 0x20..0x26 (= 0x26 under the MOD flavour alone), B0 is unco | kn7000_mame@c107c4d, kn5000-roms-disasm@35fc12e |
| §209 | `UPD6383_DSCRING` | `m_dscring` | **true** | ★ FREE PARAMETERS, not measured, printed so they are never read as forced: the sweep pins L1 only to 0x20..0x26 (= 0x26 under the MOD flavour alone), B0 is unco | kn7000_mame@c107c4d, kn5000-roms-disasm@35fc12e |
| §112, §213 | `UPD6383_STPROBE` | `m_stprobe` | **true** | ★★★ §213: THE STORE-PROBE FIX. `upd6383.cpp'`s ACTION-0x07 site had an UNBRACED `else' in front of store_mode(), so kwatch()/watch_store()/ store_probe()/m_dwr[ | kn7000_mame@f04ee72, kn5000-roms-disasm@f5eeedd, kn5000-roms-disasm@251c513 |
| §224, §225 | `UPD6383_LFOWRAP` | `m_lfowrap` | **true** | ★★★ §225 SHIPPED AS THE DEFAULT. `W4' -- the one gate §224 failed -- was RESTATED so it cannot fire on a ramp (which is what RULE 21 demands) and then PASSED: b | kn7000_mame@612a5e6, kn5000-roms-disasm@0908745, kn5000-roms-disasm@fba980d, kn7000_mame@b4757a7, kn5000-roms-disasm@9693048, kn5000-roms-disasm@4b4f600 |

*Not counted (default OFF or baseline):* `UPD6383_LAND`=4, `UPD6383_SPEC`=0xb910e446a39b440f, `UPD6383_TRACE_FRAME`=420000, `UPD6383_AB_NOSTORE08`=false, `UPD6383_SRC0B2`=false, `UPD6383_DRPUB`=false, `UPD6383_NOZ05`=0, `UPD6383_NOCARRY`=false, `UPD6383_PSHIFT`=0, `UPD6383_EPIBUS`=false, `UPD6383_XB85`=0, `UPD6383_PICKUP`=false

## B. UNGATED BEHAVIOURAL NARROWINGS — **FORCED** (source announcement)

Denominator: **267** `logerror` calls scanned; 1 declare a narrowing/ship without an env var.

| § | site | announcement | commit |
|--:|--:|---|---|
| §223 | `upd6383.cpp:7195` |  ★ §223 §NG NOP-GUARD NARROWED (addr8 == 0x00 added): " "%u words handed to exec_alu() that the old guard swallowed, " "%u distinct slots (cap 16)%s \| | kn7000_mame@2c79f4a, kn5000-roms-disasm@8bfe33f, kn5000-roms-disasm@fc6d792 |

## C. DEFAULT-MASK MOVES — **FORCED** (heading + `.h` initialiser)

| § | new default | still the default? | claim | control (excerpt) | commit |
|--:|---|:--:|---|---|---|
| §156 | `0x1910E446A39B440F` | superseded | SHIPPED: `SRC 0x00 = coef` and the DELAY-TAP MODULATION PATH; default `0x1910E44 | Evidence grade: **MEASURED** (four pre-registered predictions, one of them the known-answe | — |
| §188 | `0xB910E446A39B440F` | YES | the host payload's LSB was being dropped. SHIPPED, default → `0xB910E446A39B440F | Evidence grade: §1 **FORCED** (two notes, by construction); §2 **FORCED**; §3 **MEASURED** | kn5000-roms-disasm@05aa3f8 |

## D. REGISTER HEADINGS DECLARING SHIPPED WITH NO GATE AND NO MASK MOVE — **INFERRED** (prose)

⚠ Reported separately and NOT folded into the headline: a heading is prose, and prose is what this tool exists to stop trusting.

| § | claim | control (excerpt) | commit |
|--:|---|---|---|
| §144 | ★★★ §135's REFUSAL IS OVERTURNED: the railing was my own bug, and the §133 READINGS ARE SHIPPED | Evidence grade: **MEASURED** (three pre-registered predictions, one of them a known-answer | — |
| §197 | the poke packet's leading nibble is a FLAG, not a constant. Two-character fix, SHIPPED. | Evidence grade: the packet form **PROVEN BY CONSTRUCTION** (two notes); the fix's effect | kn5000-roms-disasm@41cde5a |
| §202 | ★★★ THE ROTATION SWEEPS DOWN, and the proof is the ROM's own numbers. SHIPPED. | Evidence grade: **MEASURED**, bit-exact at two lines against an independently-taken dump;  | kn5000-roms-disasm@24272a0 |
| §204 | the CONSUMER-TO-CELL census grades §203. It was right. SHIPPED. | Evidence grade: the decode **FORCED** (r3 §6.1 + the 28 + 4 = 32 arithmetic); the conseque | kn5000-roms-disasm@05607b8 |

## ★ THE COUNT, WITH ITS UNIT

| unit | count | what it counts |
|---|--:|---|
| **forced GATES** | **8** | 7 env gates default-ON + 1 ungated narrowings (channels A+B) |
| **forced SECTIONS** | **11** | sections owning an A/B/C item: §112, §156, §188, §200, §201, §203, §209, §213, §223, §224, §225 |
| all SECTIONS incl. prose | 15 | + channel D: §144, §197, §202, §204 |

⚠ **NO published figure states its unit.** That is why five of them disagree. Quote a count only with the unit and the denominator beside it.

⚠ **ATTRIBUTION IS NOT UNIQUE** for 2 gates -- report the pair, never pick:
  * `UPD6383_STPROBE` -> §112, §213 (the source announces one, the register heading may credit another)
  * `UPD6383_LFOWRAP` -> §224, §225 (the source announces one, the register heading may credit another)
