# `iw70`, mask bit 23, and the unit-1 input — is the store mis-routed?

**Written 2026-07-31. STATIC + EXISTING LOGS ONLY.** No emulator was run, no source
was edited, nothing was built, nothing was committed. Every number below is read out
of a log already in `dsp/analysis/data/`, out of the ROM corpus via
`dsp/tools/pat_corpus.py` + `dsp/tools/dsp_disasm.py`, or out of
`kn7000_mame/src/devices/cpu/upd6383/upd6383.{cpp,h}` **at committed head
`3d95aae`** (see §0.1 — the working tree has since drifted under §221).

Scratch scripts (not committed): `bit23_audit.py` (a parameter substitution on
`dsp/tools/bit26_audit.py`, unmodified logic), `d85_producers.py`,
`d85_symmetry.py`.

---

## 0. THE ANSWER IN ONE PARAGRAPH

**`iw70` is NOT mis-routed, and the bit-23 experiment must not be run — but not for
the reason the brief anticipated.** Bit 23 is confounded (**five** sites at head, six
in the working tree, three of them load-bearing on the output path), and three of the
five are *array-blind in the logs*, so a bit-23 arm would be partly **unobservable**
as well as confounded. That much closes the arming question. What closes the *whole*
question is one measurement already on disk: **`iw70`'s stored datum is exactly
`0..0`, quiet and loud, in four independent arms — including the two `NOZ05` arms
where body 0 demonstrably runs its whole ladder on live audio.** `§109`'s store probe
prints `[site3 addr 85 val 0..0 x1020000]` and `§104` row 70's `L` column reads
`0..0 / 0..0` in `drpub_A_off_217`, `drpub_C_on_src0b2_217`, `C_noz05_220` and
`D_noz05_drpub_220`, digit for digit. Re-routing that store from `m_rf[0x85]` to
`m_dram[0x85]` therefore deposits **zero into zero**. The routing is not the defect;
the routing question is **MOOT**, in exactly the way `§216` made the send question
moot for the output stage. And the reason is the same defect: **the epilogue's
accumulator is the frame-invariant constant `2 603 010 048` in every arm**, so
`iw70` (unit 1's input) and `w73`/`w78` (the output) are starved by *one* blocker,
not two. ⇒ **Do not open a unit-1-deposit lane. It is §221's lane.**

One correction to the owning note is required: `IW205-DRAM-D0_findings.md` §2.3
classifies `0x85` as **NO PRODUCER**. Under `§97`'s forced two-array split that is
half right and the half it gets wrong matters. **Register `0x85` HAS exactly one
producer — `iw70`, 1 020 000 stores per settled run, every one of them zero.**
What has no producer is *pointer-space* `D-RAM[0x85]`, the cell `iw205` reads. They
are different cells by construction. The defect is a **space mismatch**, and §3
below shows it is the *only* place in the machine where a producer and its consumer
sit in different spaces.

---

## 0.1 ⚠ THE SOURCE MOVED UNDER THIS PASS

`kn7000_mame` HEAD is `3d95aae`; `src/devices/cpu/upd6383/upd6383.{cpp,h}` are both
` M` (modified) in the working tree — §221 is editing them live. **All line numbers
and site counts in §1 are taken from `git show 3d95aae:...`**, extracted to scratch
and audited there, so they are reproducible. The working-tree delta is reported
separately in §1.1 because it *changes the answer to CHECK 2*. Grade: **MEASURED**
(`git status --porcelain`, `md5sum`).

---

## 1. THE BIT-23 CLEARING AUDIT

Performed programmatically with `dsp/tools/bit26_audit.py`'s logic (comments and
string literals stripped before parsing; no spelling grep anywhere), retargeted from
`0x4000000` to `0x800000`.

### 1.0 The default, confirmed from the code

```
  initialiser of m_specmask : upd6383.h:1015   u64  m_specmask = 0xb910e446a39b440f;
  brief claims 0xB910E446A39B440F            -> MATCH
  bit 23 (0x800000) in default               -> SET
  bits SET in default: 0 1 2 3 10 14 16 17 19 20 23 24 25 29 31 33 34 38
                       42 45 46 47 52 56 59 60 61 63
  the ONLY runtime write to the mask: upd6383.cpp:293  m_specmask = strtoull(env,…,16)
```

The set-bit list reproduces the brief's exactly. Grade: **MEASURED**.

### 1.1 ITEM 1 — every site that tests bit 23, and what each one controls

**Five sites at `3d95aae`. Six in the working tree.**

| # | site (`3d95aae`) | what it routes | if bit 23 were CLEARED |
|---|---|---|---|
| **S1** | `upd6383.cpp:643` `store_mode()` | a **mode-1 store** goes to `m_rf[dest]` (+`m_rf_st[dest]++`) instead of `m_dram[dest]` | **the site under investigation.** All 13 mode-1 store targets move: `06 0E 0F 50 51 52 53 85 8A 8C 8D 8F D0` |
| **S2** | `upd6383.cpp:1084` host packet, tag 0x15 | the **host's register-file writes** go to `m_rf[m_dram_wp]` instead of `m_dram` | 63 host writes over 59 cells (`§186`) land in the pointer-walked D-RAM, re-creating the `§71`/`§86` collision `§97` was created to resolve |
| **S3** | `upd6383.cpp:1730` the **presentation** | the **per-unit OUTPUT LEVEL** is read from `m_rf[0x06]`/`m_rf[0x86]` instead of `m_dram`/`m_cram` | ⛔ **catastrophic and quantified** — see §1.2 |
| **S4** | `upd6383.cpp:2663` `SRC 0x02` (under bit 24, SET) | `reg[addr8]` is read from `m_rf` instead of `m_dram` | `w72`'s operand stops being the host's `+0.5`; `§99`'s "destroys the user's effect depth" returns |
| **S5** | `upd6383.cpp:2838` `SRC 0x07` mode-1 | the **mode-1 register READ** comes from `m_rf[rdsrc]` instead of `m_dram[rdsrc]` | every register read in the machine moves, including `w63` (`05r`) and `w65` (`8Fr`) |
| *S6* | *working tree only* `:2883` | *`e1route = (m_specmask & 0x800000) ? E1_RF_IDX : E1_DRAM_IDX; // §221 §E1`* | *§221's provenance tagging follows the same bit — so §221's own instrument would be re-aimed by the arm* |

Grade: **MEASURED** (programmatic; the tool prints each site with its source line).
**CHECK 2 verdict as printed: `FAILS -- CONFOUNDED`.**

### 1.2 ITEM 2 — what ELSE clearing it changes, with the numbers

Bit 23 is not "the `iw70` routing bit". **It is the existence of the `m_rf`/`m_dram`
split itself** — the store side (S1), the host side (S2), the read side (S4, S5) and
the output-level side (S3) are all one switch. Clearing it *is* "collapse the
`m_rf`/`m_dram` alias", which the LEDGER already carries as an established **dead
end** (`§97` FORCED). The brief asked me to engage with `§186` explicitly, so:

**(a) The level, and it alone disqualifies the arm.** `§41`, arm C:

```
  §41 LEVEL AT PRESENTATION: unit0 0x400000 (non-zero on 1 172 160),
                             unit1 0x178D0B (non-zero on 1 172 160)
      [cold boot set 0x06 = +0.5 = 0x400000, 0x86 = +0.183992 = 0x178D50]
```

Under bit 23 the level read finds **the host's own cold-boot parameters**, on
1 172 160 of 1 172 160 presentations. Clear the bit and `:1730` reads
`m_dram[0x06]`/`m_dram[0x86]` instead. `§176` measures `m_dram[0x06]` = `8388607`
(and `§86` grades it INPUT-DEPENDENT, loud `[0 .. 16 776 960]`) — kernel scratch —
and `m_dram[0x86]` is absent from `§176`'s non-zero list, i.e. **0**. So clearing
bit 23 makes unit 0's output gain a per-frame garbage multiplier and makes unit 1's
level `0`, which trips `if (lvl != 0)` and **skips the level multiply entirely**.
Any audio-side number from such a run is meaningless. Grade: **MEASURED**
(`§41` + `§176` + `§86`) / **FORCED** (the consequence follows from `:1730`'s ternary).

**(b) `§186` bears on this directly, and it argues FOR the split.** The host's
tag-0x15 sweep writes 59 cells: `05:1(z) 06:3 07:1(z) 0E:1(z) 10:1(z) 11:1(z)
1D..40:1 50..57 85:1(z) 86:3 87:1(z) 8A:1(z) 8B:1(z) 94:1(z) D0..D2:1(z)`. Nine of
those indices (`05 06 07 0E 10 11` and the `50..53` block) lie **inside** the
pointer-walked window `§98` measures kernel A and body 0 using as scratch. Under a
collapse the host's parameter sweep would overwrite that scratch — which is exactly
the `§71`/`§86` conflict. The split is what keeps `06 = 0x400000` alive to be read at
the presentation, and `§41` measures that it does. Grade: **MEASURED**.

**(c) The instrumentation gap — clearing it would be partly UNOBSERVABLE.** Rule 8,
per site:

| site | fired counter | emitted? |
|---|---|---|
| S1 | `m_rf_st[dest]++` **inside the `m_rf` branch only** | `§99` at `:6003`, but **guarded** `if (m_rf_st[c])`, and the `m_dram` else-branch has **no counter at all** ⇒ with the bit cleared the census prints `(none)` and "fired zero times" is indistinguishable from "never ran" — the §220 trap verbatim |
| S2 | none in either branch (`m_hostw_cell[]` is outside and array-blind) | `§186` prints the same string under either routing |
| S3 | `m_lvl_seen[unit]`, `m_lvl_nz[unit]` | ✅ `§41`, unconditionally — **the only routing-sensitive number in the set** |
| S4 | `m_src02_n++` | ⛔ **incremented at `:2665` and never printed anywhere in the file** |
| S5 | none (`pwatch(rdsrc,false,regfile)` records index+mode, **not the array**) | `§98` prints `05r` identically under either routing |

Grade: **PROVEN BY CONSTRUCTION** (every reference to each counter enumerated
programmatically).

⇒ **A bit-23 arm is confounded across five sites, three of which decide the output
path, and four of which report nothing that distinguishes the arms.** If the routing
question ever had to be asked, the narrow gate is §5's one-word form — but §2 shows
it does not have to be asked at all.

### 1.3 ITEM 3 — multi-bit literals and shift windows

* The **only** non-single-bit literal AND-ed with `m_specmask` anywhere in the two
  files is **`0x4001`** at `upd6383.cpp:1690` (bits 0 and 14). **Bit 23 is not in
  it.** Grade: **MEASURED** (tool output: `NON-single-bit masks tested against
  m_specmask: [('multi','0x4001')]`).
* The mask is also consumed by **shift-extraction**, which a single-bit scan would
  miss. All six windows enumerated: `>>42 &7` (`m_bx_sel0d`), `>>45 &7`
  (`m_bx_sel0e`), `>>48 &3` (`m_bx_f4`), `>>50 &3` (`m_bx_f5`), `>>35 &7` (`ACT 0x0D`
  fallback), `>>48 &0xf` (a report). **None covers bit 23.** Grade: **MEASURED**.
* The 7 literals equal to `0x800000` = 5 mask tests + `cpp:1650` twice, which is the
  24-bit **saturation constant** `if (v < -0x800000) return -0x800000`, not a mask
  test. Grade: **MEASURED**.

⇒ bit 23 is only ever tested as a single bit, at exactly those five (now six) sites.

---

## 2. ⛔⛔ THE ROUTING QUESTION IS MOOT — `iw70` STORES ZERO

This is the load-bearing section and it needs no run.

### 2.1 Two independent instruments, four arms, digit-identical

`§109`'s store-site probe (frame-gated, `site 3` = the `ACTION 0x07` store):

```
   70 02A61850C7 1020000   dp 00->00  +0  |  [site3 addr 85 val 0..0 x1020000]
   72 0000106087 1020000   dp 00->00  +0  |  [site3 addr 06 val 4194304..4194304 x1020000]
   73 0E30C00404 1020000   dp 00->00  +0  |  [site2 addr 00 val 0..0 x1020000]
```

`§104` row 70's `L` column — and `L` **is** the datum, `PROVEN BY CONSTRUCTION`:
`m_last_l = L` at `upd6383.cpp:3089`, `store_mode(mode07, d07, u32(L))` at `:3723`,
and **no reassignment of `L` between those two lines** (verified programmatically
over the 641-line span):

| arm | log | `iw70` `L` quiet | `iw70` `L` loud |
|---|---|---|---|
| A (shipped) | `drpub_A_off_217` | `0..0` | `0..0` |
| C (DRPUB+SRC0B2, body 0 LIVE) | `drpub_C_on_src0b2_217` | `0..0` | `0..0` |
| C (NOZ05, body 0 LIVE) | `C_noz05_220` | `0..0` | `0..0` |
| **D (NOZ05+DRPUB, body 0 LIVE)** | `D_noz05_drpub_220` | `0..0` | `0..0` |

Grade: **MEASURED**, two instruments, four arms.

### 2.2 The register-file content census confirms it — and gives a POSITIVE CONTROL

`§160` dumps `m_rf` directly (this is a *content* census, not the broken
`D-RAM WRITES` counter — see the ⚠ box in `IW205-DRAM-D0_findings.md` §2.1):

```
  §160 register file, ALL non-zero cells (41): 06=400000 1D..40=<LFO wavetable>
       54=0009B0 56=000DC0 86=178D0B 8D=009B26
  §99 MODE-1 STORES -> register file: 13 cells
       06:1203840 0E:28800 0F:1215360 50:1176960 51:1176960 52:1176000 53:1176000
       85:1203840 8A:1181760 8C:1204800 8D:1204800 8F:1176000 D0:1181760
```

* **`m_rf[0x85]` is absent from the non-zero list ⇒ it is 0**, after `1 203 840`
  mode-1 stores. The store *fires*; the datum is zero. (⚠ RULE 16: `§99`'s counter is
  **not** frame-gated; use `§109`'s `1 020 000` for the settled rate. The un-gated
  number is used here only for "non-zero vs zero".)
* **`m_rf[0x05]` is also absent ⇒ 0**, and it is not among the 13 mode-1 store
  targets at all. Its only writer in the whole machine is the host, once, with zero
  (`§186 05:1(z)`). **So `w63` — the word that reads it — reads zero forever.**
* ★ **`m_rf[0x8D] = 0x009B26 = 39 718`, and `2 603 010 048 >> 16 = 39 718` EXACTLY.**
  `w60`/`w61` are mode-1 bit-4 stores of `acc_to_datum(ACCA)` and `ACCA` at those
  slots is the constant `2 603 010 048` (`§104` rows 60/61, all four arms).
  ⇒ **the mode-1 store path into `m_rf` is MEASURED WORKING AND EXACT.** It is not
  broken, not suppressed, not mis-addressed. Grade: **MEASURED EXACT**.

### 2.3 Why the datum is zero — and it is the OUTPUT-STAGE NULL, not a second defect

`§104`'s `acc` column across the CALL return, arm D (`NOZ05+DRPUB`, i.e. the rig on
which body 0 *is* input-dependent at 28/32/28 slots):

```
   iw149  acc  1800..1800        (body 0, still computing)
   iw150  acc  0..0              <- ACCA dies INSIDE body 0
   iw153  acc  0..0              (body 0's last word, the RETURN)
   iw50   acc  0..0              (kernel B)
   iw54   acc  2603010048..2603010048   <- a CONSTANT appears
   iw60..64 acc 2603010048..2603010048  '='   quiet AND loud
   iw65..81 acc 0..0                    '='
   iw70   L   0..0                      '='   <- the store
   iw73   acc 0..0                      '='   <- the presentation
```

Identical in all four arms. ⇒ **the epilogue never sees unit 0's audio.** `iw70`
(unit 1's input) and `w73`/`w78` (the output) read the *same* dead accumulator.
Grade: **MEASURED** (four arms) / **FORCED** for the unification (both words' only
modelled source is `ACCA`, and `ACCA` is measured frame-invariant there).

★ **Consequence for the project plan:** the "unit-1 deposit" is **not a separate
open item**. It is `§216`'s blocker seen from the other side. Opening a lane for it
would duplicate §221.

### 2.4 The constant-fill trap is live here, with its number

If anyone "fixes" `iw70` by giving it a source that is non-zero-but-constant, unit 1
*will* produce a non-zero `w78` and it will pass standing rule 1. The two constants
already in the epilogue are **`2 603 010 048`** (`ACCA` at `iw60..64`; its datum form
is **`39 718`**) and **`4 194 304`** (`w72`'s `L`). **RULE 19: if `§104` row 205's
`mem` column ever reads `39 718` or `4 194 304`, that is a DC, not audio — report the
mean and the AC amplitude separately and reject it.** The companion named wrong
number remains `w78` mean **`79 438 ± 90`** (−59 dB).

---

## 3. IS `iw70` THE ONLY CANDIDATE PRODUCER? — YES, ON EVERY ROUTE

### 3.1 The complete write-site inventory of the device

Every `m_dram.write_dword(...)` in `upd6383.cpp` at `3d95aae`, enumerated (9 sites),
with the address each can produce:

| site | address | can it be `0x85`? |
|---|---|---|
| bit-26 mirror | literal `0x05` | no (and dead end 30, OFF) |
| `store_mode()` else-branch | `dest` = `m_dp` (mode≠1) or `addr8 \| unit<<7` (mode 1, only when bit 23 clear) | **the only I-RAM route** |
| host tag-0x15 else-branch | `m_dram_wp` | **yes — host only** (`§186 85:1(z)`) |
| input-latch deposit ×2 | `m_in_addr[0..1]` | **no — MEASURED `01`/`04`** (`§33 in_base=FF dp=01/04 in_addr=01/04`) |
| `exec_addressing_only` K6 bit-4 | `m_dp` | no (K6 words, `m_dp` ∈ `01..07`) |
| `ACT 0x0D`/`0x0E` `case 4` ×2 | `m_dp` | inactive (`sel0d=1`, `sel0e=7`) |
| `bx_stim` ×2 | literals `0x05`, `0x0f` | no (test injector; ⚠ note it is another unit-0-only asymmetry) |
| boot zeroing ×2 | `0x50+i` | no |

Grade: **PROVEN BY CONSTRUCTION**.

### 3.2 The resident frame, enumerated on the LIVE image, under every route

`d85_producers.py` walks the **live** `I-RAM` (`§104`'s word column, 285 slots — the
ROM listing and the live image **differ at `iw64` and `iw71`**, which are C-format at
run time; using the listing there would have been an error) and applies every
addressing route the device implements:

```
  iw70   2A6.1.85.0C7  EPILOGUE  R2 mode-1 ACT-07 store, addr8 = 85
  iw205  202.2.4B.1CD  body1     R5 sel0d==4  (INACTIVE: sel0d = 1)
  iw319  202.2.08.1CD  body1     R5 sel0d==4  (INACTIVE)
  iw330  202.2.7B.1CD  body1     R5 sel0d==4  (INACTIVE)
```

and the pointer route is empty by measurement — **every** slot whose MEASURED `dp`
is `0x85` is a pure read:

```
  iw200 880.1.30.00B  ESC delay word   ST=0  ACT 0B
  iw201 000.2.89.415                   ST=0  ACT 15
  iw205 202.2.4B.1CD                   ST=0  ACT 0D
  iw319 202.2.08.1CD                   ST=0  ACT 0D
  iw330 202.2.7B.1CD                   ST=0  ACT 0D
```

Routes checked and closed: **R1** mode-1 bit-4 store (`addr8 | unit<<7`, `:2914`) —
no resident word qualifies; **R2** mode-1 `ACT 0x07` store (`addr8`, `:3491`) —
`iw70` only; **R2′** the same *with* the unit rebase that R1 uses — see §3.3;
**R3/R4** mode-2 stores at the pointer — none, per the table above; **R4′** the
`ACT 0x07` POST-increment variants (mask bits 28 and 34, both **clear** in the
default) — none reaches `0x85`; **R5** the `ACT 0x0D` selector-4 memory write —
inactive at `sel0d = 1`, and a self-write no-op at those sites anyway.

Grade: **PROVEN BY CONSTRUCTION** for the enumeration, **MEASURED** for the pointer
column (`§104`, 285 slots; the live word column agrees with the ROM listing at
283 of 285 and the two exceptions are identified).

### 3.3 ⚠ A REAL ASYMMETRY INSIDE THE DEVICE, found on the way

The two mode-1 store sites do **not** apply the same address rule:

```
  bit-4 store   :2914   stdest = addr8(word) | (m_cur_unit1 ? 0x80 : 0x00)   <- rebased
  ACT-07 store  :3491   d07    = addr8(word)                                 <- NOT rebased
```

`store_mode()`'s own banner is *"★★★ §99: one rule for both store sites"*, and the
two callers disagree about the unit bit. It does **not** affect `iw70` (its `addr8`
already carries bit 7, so `0x85 | 0x80 = 0x85`), and no resident mode-1 `ACT 0x07`
word has `addr8 = 0x05`, so **nothing in the resident frame changes today**. Flagged
because it is a latent divergence at the exact site under study, and because the
corpus is not the resident frame. Grade: **PROVEN BY CONSTRUCTION** (source),
**INFERRED** that it is a defect rather than an intended distinction. *Not fixed
here — I am read-only, and it is `upd6383.cpp`, which is §221's file.*

---

## 4. THE UNIT-0 / UNIT-1 SYMMETRY — the units are **NOT** symmetric, and the break is exact

### 4.1 The bodies ARE symmetric; only the kernel and the epilogue are unit-aware

`programs.tsv` tags 37 of 38 body images `unit 0` and 1 `unit 1`, but the **same 38
images serve both units** — the unit context is supplied at run time by
`m_cur_unit1` and by the per-unit rebase at the CALL. So a body image cannot be
asymmetric. Corroborating that, **0 of 38 body images contain a mode-1 word naming
`0x05` or `0x85`**: *the bodies address their input through the pointer, never
through the register file.* ⇒ any asymmetry must live in the kernel or the epilogue.
Grade: **MEASURED** (corpus census).

### 4.2 `§98`'s pointer window — the symmetry statement, MEASURED

```
  kernel A  (iw 0..49)    mode-2  01r 02w 03r 04r [05rw] 06w [07r]
  body 0    (iw 84..199)  mode-2  03r [05r] [07rw] 0Crw 0Dr 0Erw 0Frw 10rw 11w 12rw 13w 50r..53r F1w
                          mode-1  50w 51w 52w 53w
  kernel B  (iw 50..59)   mode-2  FDw
                          mode-1  0Fw 8Aw D0w
  body 1    (iw 200..332) mode-2  0Erw [85r] [87rw] 88w 89rw 8Arw 8Brw 8Cr 8Dw 8Fr 94rw D0rw D1rw D2rw
                          mode-1  8Fw
  epilogue  (iw 60..82)   mode-2  00w FFr
                          mode-1  05r 06w 85w 8Cw 8Dw 8Fr
```

My static enumeration of the epilogue's mode-1 words reproduces that line **8 of 8**
(`05r 06w 85w 8Cw×2 8Dw×2 8Fr`) — a calibration the census passes.

**Read it as a symmetry table:**

* **The bodies are symmetric.** Body 0 `[05r] [07rw]`; body 1 `[85r] [87rw]`. Both
  *read* their base cell and *read-write* base+2. Neither writes its own input.
  ✅ symmetric.
* **The kernel is NOT.** Kernel A walks the pointer through `01..07` and **writes
  `02`, `05`, `06`** — the audio deposit. Kernel B's pointer sits at `FC..FE`
  (MEASURED, `§104` rows 50–59) and it writes **`FD`** plus three registers
  `0F 8A D0`. **Kernel B has no write to `85`, `86` or `87` on any route.** There is
  no unit-1 input stage; the K6 port read happens once per frame, in unit-0 space
  (`in_addr = 01/04`, MEASURED). ⛔ **asymmetric.**
* **The rebase is visible in the pointer column.** `iw49 dp=05 → iw84 dp=05` (unit 0
  enters where the walk already was); `iw59 dp=FE → iw200 dp=85` (unit 1 is *teleported*
  by `base = 0x05 | unit<<7`). So unit 0's base cell is **both** the rebase value and
  the natural terminus of the kernel's walk; unit 1's base cell is **only** the rebase
  value, and the walk never visits it. Grade: **MEASURED**.
* **`§86` seals it:** the kernel-written cells whose value depends on the input are
  `05 06 07 0C 0F 10 11 13 50 F1`. **Not one `0x8x` cell appears.** Grade: **MEASURED**.

### 4.3 ★★★ THE EXACT BREAK: unit 0's pair is (pointer, pointer); unit 1's is (register, pointer)

| | producer | consumer | same array? |
|---|---|---|---|
| **unit 0** | `iw9`/`iw11` — mode-2 **pointer** stores → `m_dram[0x05]` | `iw85` — mode-2 **pointer** read of `m_dram[0x05]` | ✅ **yes** |
| **unit 1** | `iw70` — mode-1 **register** store → `m_rf[0x85]` | `iw205` — mode-2 **pointer** read of `m_dram[0x85]` | ⛔ **no** |

All six writers of `0x05` (`iw9 iw11 iw35 iw37 iw45 iw111`) are pointer-route stores;
not one is a register store. The unit-1 side has **no** pointer-route producer and
**one** register-route producer. Under `§97`'s FORCED split those are different cells.
Grade: **PROVEN BY CONSTRUCTION** (the routes) + **MEASURED** (`§98`, `§96`, `§160`).

**This is the strongest structural result in the pass — and §2 shows it is not
currently actionable, because the register-route producer's datum is zero anyway.**

### 4.4 The epilogue's crossbar — and why `iw63`/`iw70` are a matched pair

```
  w63 = 02A79051C3   2A7.9.05.1C3   mode 1  addr8 = 05   SRC 07  ACT 03
  w70 = 02A61850C7   2A6.1.85.0C7   mode 1  addr8 = 85   SRC 03  ACT 07
  XOR = 0001880104   differing bits {2, 8, 19, 23, 24};  bit 19 = addr8 bit 7 = THE UNIT BIT
```

`SRC` and `ACT` are **transposed** (`07/03` ↔ `03/07`) and the addresses are the two
units' base cells. Over the **2557 plain corpus words** (not C-format, `hi12` ESCAPE
clear, `lo12` bit 11 clear — LEDGER dead end 16):

```
  SRC 0x03  : 1 site   EPILOGUE w70   (and upd6383.cpp:2672 says the same: "n = 1")
  ACT 0x03  : 1 site   EPILOGUE w63   (LEDGER dead end 16 names this exact exception)
  SRC 0x02  : 1 site   EPILOGUE w72
  SRC 0x01,04,05,06 : 1 site each — ALL in the EPILOGUE
  ACT 0x01,05,06    : 1 site each — ALL in the EPILOGUE
```

⇒ **the epilogue's register words use a private, contiguous, one-shot `SRC`/`ACT`
numbering `0x01..0x06` that occurs nowhere else in the machine.** That is a
crossbar/selector sub-ISA, not the bodies' shared ALU codes, and it means **no
`SRC 0x03` reading can ever be corroborated by counting** — a point `upd6383.cpp`
already makes at `:2672`. Grade: **MEASURED** (corpus counts) / **SPECULATIVE** for
the "crossbar" reading (n = 1 per code).

★ One variant is **already refuted without a run**: if `ACT 0x03` latched the
*accumulator* at `w63`, the latched value would be `2 603 010 048` — a constant in
all four arms (`§104` row 63) — i.e. the constant-fill trap. Only a *bus* latch can
carry anything live, and `w63`'s bus is `m_rf[0x05]` = **0**. Grade: **MEASURED
negative**.

---

## 5. THE PRE-REGISTERED EXPERIMENT

### 5.0 What I am NOT recommending, and why

* ⛔ **Do not clear bit 23.** Five sites; three decide the output path; four report
  nothing that separates the arms; and `§41`'s `0x400000`/`0x178D0B` would be
  destroyed (§1.2a). Also — decisively — §2 makes it pointless.
* ⛔ **Do not re-route `iw70` alone.** Predicted outcome computed: `D-RAM[0x85]`
  receives `0`, `§104` row 205 stays `0..0`, body 1 stays at its null. It would
  convert one INFERRED line to MEASURED at the cost of a run, and teach nothing else.
* ⛔ **Do not re-open `DRAM_UNIT_BASE`/`STRIDE`.** FORCED, and `§220` measured
  `0x05 | unit<<7` correct at unit 0.

### 5.1 §E-D85 — THE EPILOGUE CROSSBAR ARM (one env var, two words, two fired counts)

**`UPD6383_XB85`, default 0.** Two coupled changes, each with its **own,
UNCONDITIONALLY printed** fired count (rule 8 as sharpened by §220 — never print
under `if (count)`):

1. **`ACT 0x03` becomes a latch:** at the action switch, `case 0x03: m_xb = L;
   m_xb_st_n++;`. Corpus-unique (`w63`); **zero collateral**.
2. **`SRC 0x03` sources that latch:** replace mask bit 25's `acc_to_datum(...)` with
   `L = s32(util::sext(m_xb, 24)); m_xb_ld_n++;`. Corpus-unique (`w70`); **zero
   collateral**. Bit 25's own state must be printed on the same line.
3. **The array route, for those two words only:** when `ACT == 0x03` (read) or
   `SRC == 0x03` (store), use `m_dram` instead of `m_rf`. Counters
   `m_xb_rd_dram_n`, `m_xb_wr_dram_n`. This is the *narrow* form of bit 23 — it
   touches **2 of 285** resident slots and **none** of S2/S3/S4.

**Rig:** the **`NOZ05`** vehicle (`UPD6383_NOZ05=1`), because it is the only rig on
which `m_dram[0x05]` is live at the epilogue (`§220`: body 0 goes 0/0/0 → 28/32/28).
Notes 21.0 s → 27.5 s, `-seconds_to_run 30`, `-log`, **visible video** (never
`-video none`), frame-gated ≥ 900 000 (RULE 16), `timeout`-wrapped.
⚠ **§221 currently holds that rig. This arm must be QUEUED behind §221, not run in
parallel** — and §221's `iw60..81` provenance census, if it prints an **array**
column for `w63`'s read and `w70`'s store, may settle steps 1–2 with no run at all.

### 5.2 THE NULL — computed from the logs BEFORE the run

| # | quantity | predicted, from the logs on disk |
|---|---|---|
| **N1** | `iw70` executions / settled frame | **exactly 1** (`§109` `n_exec = 1 020 000` over `nq+nl = 706 040 + 313 960 = 1 020 000`) |
| **N2** | `iw70`'s stored datum, bit off | **`0..0`** quiet and loud — four arms |
| **N3** | `m_rf[0x85]` content, bit off | **0** (absent from `§160`'s 41 non-zero cells) after `1 203 840` stores |
| **N4** | `m_rf[0x05]` content | **0**, and **zero I-RAM writers** (not among `§99`'s 13 cells); host `05:1(z)` |
| **N5** | body-1 input-dependent slots (`§104`, acc/mem/L of 133) | **`0/0/0`** in arms A/B; **`2/1/2`** in the two `NOZ05` arms — the slots are `iw202`(mem,L, `−82..80`), `iw203`,`iw204`(acc), `iw325`(L, `−256..0`). **This `2/1/2`, not `0/0/0`, is the null to beat.** |
| **N6** | body-0 input-dependent slots on the same rig | **`28/32/28`** (unchanged by this arm — it is a regression control) |
| **N7** | value published to `0x85` **if the arm works** | **exactly `§104` row 85's `mem` column on the same rig**: `−8 388 608 .. 8 388 607` on `D_noz05_drpub_220` (⚠ **railed** — the input latch rails at `0x800000`, RULE 12), or `−8 034 877 .. 7 192 534` on `drpub_C_on_src0b2_217` |
| **cal** | vehicle | `§54` loud ≈ **313 960** frames; `§104` `nq/nl` = **706 040 / 313 960**. **A loud count of 0 VOIDS the run.** |

### 5.3 THE FALSIFIERS — each names a specific wrong number

> **F1 — THE CONTROL WHOSE ANSWER IS ALREADY KNOWN (and it can fail).**
> `m_rf[0x8D]` must still read **`0x009B26` = `39 718` = `2 603 010 048 >> 16`**, and
> `§41` must still read **unit0 `0x400000`, unit1 `0x178D0B`, non-zero on
> `1 172 160`**.
> **F1 FAILS ⇒ the gate leaked past its two words and the run is VOID** — no other
> number in it may be quoted. This is a real calibration, not a restatement: `0x8D`'s
> value is produced by a *different* mechanism (a mode-1 **bit-4** store of
> `acc_to_datum`), and `0x400000` is the *host's* datum arriving through the mode-1
> **read** route. Both are load-bearing on bit 23 and neither is touched by this arm.

> **F2 — THE RESULT.** `§104` row 205's `mem` column becomes `*` (input-dependent)
> and equals N7, and body 1's count rises above **`2/1/2`**.
> **F2 FAILS ⇒ the crossbar reading is dead** and `iw70`'s routing is exonerated for
> good. Given §2, **F2 failing is the PREDICTED outcome** and is a full result: it
> retires `SRC 0x03`, `ACT 0x03` and the bit-23 routing from the worklist and folds
> unit 1's starvation into §216/§221's single blocker.

> **F3 — THE REGRESSION CONTROL (`m_bx_sel0d` is FROZEN at 1).**
> `§104` row 85's `acc` must remain exactly `L × 65536` and body 0 must remain at
> **`28/32/28`**.
> **F3 FAILS ⇒ VOID.** Named wrong numbers: row-85 `acc` min `−1 391 207 691 857`
> (an ADD arm), and `w78` mean **`79 438 ± 90`** (the −59 dB DC that `§6.5(ii)`
> already names).

> **F4 — THE CONSTANT-FILL TRAP (RULE 19).** If row 205's `mem` becomes a
> **constant** — specifically **`39 718`**, **`4 194 304`**, or `2 603 010 048` in the
> `acc` column — the arm has published a DC. **Report the mean and the AC amplitude
> separately, and the loud/quiet AC ratio, BEFORE the word "audible" is used**; the
> ratio must exceed the `2.2×` the §6.5(ii) counter-example already achieves without
> being audio. Grade the arm on `§104` and on provenance (RULE 17 — name a specific
> wrong `iw`), **never by listening**: `§216`/`§220` guarantee this cannot produce
> audio, because the bodies already run live on the rig and `w73`/`w78` are still
> exactly zero.

### 5.4 THE DECISION RULE, WRITTEN BEFORE THE DATA

* **F1 or F3 fails** → VOID. Fix the gate's scope, re-run. Nothing is salvageable.
* **F1, F3 hold and F2 fails** (predicted) → `iw70` is **correctly routed**, `SRC/ACT
  0x03` are not a crossbar latch, and the unit-1 input is starved by the *same*
  missing link as the output stage. Close this question; hand everything to §221.
* **F2 holds** → the epilogue crossbar is real, and the *narrow* array route (not
  bit 23) is the fix. Report which of `m_xb_st_n`, `m_xb_ld_n`, `m_xb_rd_dram_n`,
  `m_xb_wr_dram_n` fired; the arm is compound, so a positive result must then be
  bisected (latch-only vs route-only) before any of it is promoted.

---

## 6. HONEST LIMITS

* **The compound-arm problem is real.** §5.1's three changes are inseparable
  *a priori* (the latch is a no-op without the route and vice versa), so a positive
  F2 cannot attribute the effect to one of them. The bisection is named in §5.4 and
  must be run before promotion.
* **`SRC 0x03` and `ACT 0x03` are n = 1 each.** No corpus statistic can support or
  refute the latch reading; only the run can, and only weakly. Grade of the
  hypothesis: **SPECULATIVE**, deliberately.
* **I did not re-derive the pointer walk.** `§104`'s `dp` column is used as the
  measured pointer (the owning note calibrated a static walk against it 29/29); this
  pass added no rival loader, per the brief.
* **`§99`'s `m_rf_st` counter is not frame-gated** (RULE 16). Used only for the
  binary "does this cell receive stores".
* **The `:2914`/`:3491` unit-rebase divergence (§3.3) is unresolved.** It changes
  nothing in the resident frame today. It is in `upd6383.cpp`, which I may not edit.
* **`§41` reports unit 1's level as `0x178D0B` where the code's own comment says the
  host set `0x178D50`** (Δ = `0x45`). Not this note's question — possibly `§111`'s
  payload handling — but it is a discrepancy sitting on a value this note uses as a
  control, so F1 pins the *observed* `0x178D0B`, not the commented `0x178D50`.
* **What a run cannot change:** §1 (the site count), §2.1–2.2 (the datum is zero),
  §3 (the enumeration), §4.2–4.3 (the symmetry) are decided by the ROM, by the C++
  control flow, and by measurements already on disk.

---

## 7. TEN-LINE SUMMARY

1. **Bit 23 is NOT safe to clear. CONFOUNDED, verdict printed by the tool.** It has
   **five** `m_specmask & 0x800000` sites at head `3d95aae` (`:643` mode-1 store,
   `:1084` host tag-0x15, `:1730` the presentation LEVEL, `:2663` `SRC 0x02`,
   `:2838` the mode-1 read) and a **sixth in the working tree** that §221 has just
   added at `:2883`. It is not a routing bit — it *is* the `m_rf`/`m_dram` split.
2. Clearing it destroys the output level: `§41` measures `unit0 0x400000` /
   `unit1 0x178D0B` on 1 172 160 of 1 172 160 presentations; from `m_dram` those
   become kernel scratch (`8 388 607`, input-dependent) and **0**, and `if (lvl != 0)`
   then skips the multiply entirely. `§186` argues the same way: 9 of the host's 59
   register targets lie inside the pointer-walked scratch window.
3. **It would also be partly UNOBSERVABLE.** Of the five sites only `§41` prints a
   routing-sensitive number; `:643`'s counter exists on the `m_rf` branch **only**
   (so with the bit off the census prints `(none)` — the §220 trap); `:2665`'s
   `m_src02_n` is **never printed**; `§98` and `§186` are array-blind by construction.
4. **No multi-bit literal AND-ed with `m_specmask` contains bit 23** — the only one
   is `0x4001` (bits 0, 14) — and **none of the six shift-extraction windows**
   (`>>42`, `>>45`, `>>48`, `>>50`, `>>35`, `>>48 &0xf`) covers it.
5. **`iw70` IS the producer of index `0x85` — the only one, on every route.** The
   live-image enumeration over 285 resident slots finds exactly one store that can
   name `0x85`; the five slots whose MEASURED pointer is `0x85` (`iw200/201/205/319/330`)
   all carry `ST = 0` and no `ACT 0x07`. The owning note's "NO PRODUCER" should be
   refined: **register `0x85` has one producer; pointer-space `D-RAM[0x85]` has none.**
6. **★★ But the routing question is MOOT: `iw70` stores exactly ZERO.** `§109`
   `[site3 addr 85 val 0..0 x1020000]` and `§104` row 70 `L 0..0 / 0..0` — two
   instruments, **four arms** including both `NOZ05` arms where body 0 runs live.
   `§160` confirms the destination: `m_rf[0x85]` is 0 after 1 203 840 stores.
   Re-routing it writes zero into zero.
7. **Why: the epilogue's accumulator is the frame-invariant constant `2 603 010 048`
   in every arm** (`§104` rows 60–64; body 0 leaves `ACCA = 0` at `iw150`). So `iw70`
   and `w73`/`w78` are starved by **one** blocker. ⇒ **there is no separate "unit-1
   deposit" lane; it is §216/§221's.** Positive control that the store path itself
   works: `m_rf[0x8D] = 0x009B26 = 39 718 = 2 603 010 048 >> 16`, EXACT.
8. **The units are NOT symmetric, and the break is exact.** The **bodies are**
   (`[05r][07rw]` ↔ `[85r][87rw]`, and 0 of 38 images name a base cell in register
   space). The **kernel is not**: kernel A walks `01..07` and deposits the audio;
   kernel B's pointer sits at `FC..FE` and it writes `FD/0F/8A/D0` — **no `85/86/87`
   on any route**, and `§86`'s input-dependent list (`05 06 07 0C 0F 10 11 13 50 F1`)
   contains **no `0x8x` cell at all**. Unit 0's producer/consumer pair is
   (pointer, pointer); unit 1's is (register, pointer) — the only cross-space pair in
   the machine.
9. `w63 = 2A7.9.05.1C3` and `w70 = 2A6.1.85.0C7` differ in 5 bits, one of which is the
   unit bit, with **`SRC` and `ACT` transposed**. `SRC 0x03` and `ACT 0x03` are each
   **1 site in 2557 plain corpus words**, and `SRC 0x01..0x06` / `ACT 0x01,05,06` are
   *all* singletons *all* in the epilogue ⇒ the output stage has a private selector
   sub-ISA and no `SRC 0x03` reading can be corroborated by counting.
10. **The one experiment I recommend: §E-D85**, the epilogue-crossbar arm — one env
    var, **two of 285 resident words**, unconditional fired counts, on the `NOZ05`
    rig, **queued behind §221** (which may settle it with no run at all). NULL: body 1
    is `0/0/0` in arms A/B and **`2/1/2`** in both `NOZ05` arms — `2/1/2` is the number
    to beat. Control with a known answer: `m_rf[0x8D] = 0x009B26` and `§41 =
    0x400000 / 0x178D0B`; if either moves the run is VOID. Named wrong numbers:
    row-205 `mem` = **`39 718`** or **`4 194 304`** ⇒ constant-fill DC, reject under
    RULE 19; `w78` mean **`79 438 ± 90`** ⇒ the `sel0d` regression; row-85 `acc` min
    **`−1 391 207 691 857`** ⇒ an ADD arm. **Predicted outcome: F2 fails, `iw70` is
    correctly routed, and that is a full result.**
