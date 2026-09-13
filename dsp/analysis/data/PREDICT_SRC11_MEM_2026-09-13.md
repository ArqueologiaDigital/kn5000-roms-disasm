# PRE-REGISTRATION — re-test SPEC bit 18 (`SRC 0x11 = mem[ptr]`) at the CORRECTED default

Written **before** the run. 2026-09-13.

## Why this is being re-opened

`§168` (2026-07-30) tested SPEC bit 18 and decided it on **arm 2**: the gate fired 9 279 912
times, `m_tb` at the class-6 site stayed at `0..5872025, chg 1`, and the diagnosis recorded in
`upd6383.cpp:3847` is

> *"The real defect is ADDRESSING: §162 measures `m_dp = 12` (`0x0C`) at the class-6 word, and
> §164's exhaustive per-frame census lists every D-RAM cell `0x00..0x1F` that moves — 01 02 04 06
> 07 0E and nothing else. **Cell `0x0C` is not among them.** `C63` reads cell `0x0C`; the LFO
> phase is in cell `0x07`. It is reading the wrong cell."*

⚠ **That premise is false at today's default.** A chorus frame captured this session at the true
device default (`UPD6383_PSHIFT=0 UPD6383_C8SHIFT=0`, nothing else set) reports

```
§176 D-RAM CENSUS ... 0C:1(-17..19/chg19520) ...   NON-ZERO 11 of 256, MOVING 12
§162 CLASS-6 SITE 00006184CD addr8=18 lo12=4CD : m_dp 12..12 | cursor 9..9 | acc VARIES
§162 CLASS-6 SITE 0000620407 addr8=20 lo12=407 : m_dp 14..14 | cursor 9..9 | acc VARIES
§167 SAME SITE, THE TEMPS: tB 0..5872025 chg 1 (VARIES) | tA 0..0 | K 0..24 | L -2869494..3486228
```

**Cell `0x0C` moves 19 520 times**, over a range of `-17..+19`. A small signed integer that
changes every ~91 frames is the shape of a table INDEX or a tap OFFSET, which is exactly what
`§166` predicted lives in the register the `C63` word loads.

⚠⚠ **Not isolated.** Between §168 and today the input stage was corrected (§76 promoted
`UPD6383_SRC0B2`), and the census quoted by §168 (`§164`) is not the census quoted here (`§176`).
I have **not** established which of the two changed the answer. What is established is that the
sentence the refutation rests on is not true of the machine as it ships today.

## The arm

```
UPD6383_SPEC=b910e446a39f440f      # the default mask 0xb910e446a39b440f with bit 18 SET
```

Captured exactly like the control, one program, one frame, no other environment:

```
NOPAIR=1 TYPES="0" NOTEOFS=2.5 dsp/tools/catalogue_regression.sh <out> \
    UPD6383_PSHIFT=0 UPD6383_C8SHIFT=0 UPD6383_SPEC=b910e446a39f440f
```

CONTROL: the capture already taken at the true default, quoted above.

## Predictions, in advance

| | prediction | what a miss means |
|---|---|---|
| **P1** | the gate FIRES — `§113` / `m_src11_mem_n` > 0 | the run says nothing at all; discard it |
| **P2** ★ | `§167 tB` at the class-6 site VARIES with **chg ≫ 1**, and its range lies inside cell `0x0C`'s `-17..+19` | the arm is still inert: §168's verdict survives the input fix, for a reason that is then NOT the one it gave |
| **P3** | CONTROL THAT CAN FAIL: `m_dp` stays `12..12` / `14..14` and `cursor` stays `9..9`. Bit 18 is a SOURCE decode and must not touch addressing | the arm is doing something other than what it claims; the measurement is void |
| **P4** | UPSTREAM NULL: cell `0x0C`'s own census stays `-17..19 / chg19520`. The arm READS the cell; it must not write it | the arm has a feedback path and P2 would be self-fulfilling |
| **P5** | RULE 12 — the traced frame has audio: input cells `01` / `05` non-zero and moving | not a test |

## What a HIT would and would not settle

★ A hit says `SRC 0x11 = mem[ptr]` delivers a **live, small, signed** quantity into the index
register at the one site the corpus pairs 53-of-53 with a table read. That is a two-sided result
where §168 had a one-sided one.

⛔ It would **not** by itself promote the reading. `§27`'s `ACCB` reading is live and was promoted
on its own evidence; the two contradict, and one liveness result does not outrank it (this session
has already recorded that **liveness alone rewards contamination**, §240). A promotion would need
the catalogue regression at the true default, as `SRC0B2` did.

⛔ And it would not decode the table read. `class 6` would still need its table's location and its
index arithmetic — `§166 §4`'s standing rule 4 — before any word is anchored.
