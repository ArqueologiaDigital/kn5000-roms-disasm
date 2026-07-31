# PREDICT_220 — §219 §8's pre-registered two-sided experiment, armed

**Committed BEFORE `build.sh` was run and before any arm was launched.** Scored against
`SPECULATIVE-APPLIED-REGISTER.md` §219 §8. Grade on `§104`/`s104_score.py`'s **body-0** columns,
**never** on `§70`/`§211` (§216: the output stage is a null *independent* of the send).

---

## 0. THE NULL AND THE CALIBRATION, COMPUTED FIRST FROM THE LOGS THAT ALREADY EXIST

`s104_score.py` over `data/drpub_A_off_217.log.gz` (**the NULL** — the shipped build) and over
`data/drpub_C_on_src0b2_217.log.gz` (**the CALIBRATION** — the §215 rival arm, the one arm in
which body 0 has ever run on live audio):

```
                       acc idep   mem idep    L idep    body-0 idep (acc/mem/L)   last idep slot
   NULL  arm A (ship)     27         21         18            0 / 0 / 0           iw38 / iw35 / iw35
   CAL   SRC0B2=1         65         65         60           28 / 32 / 28         iw204 / iw202 / iw325
```

⇒ **body-0 = `0 / 0 / 0` is the null and `28 / 32 / 28` is what a working send looks like.**
The instrument has already demonstrated it can distinguish the two states, in the same census, in
the same vehicle. A result of `0 / 0 / 0` therefore cannot be dismissed as "the census can't see it".

## 1. THE THREE PROGRAMMATIC CHECKS ON MASK BIT 26 (done before arming; `scratchpad/s220/bit26_audit.py`)

| check | answer |
|---|---|
| bit 26 clear in the shipped default? | **YES.** `m_specmask = 0xb910e446a39b440f` (`upd6383.h:1015`) — the only initialiser, and the only runtime write is the `UPD6383_SPEC` env override at `upd6383.cpp:293`. Bits set: 0,1,2,3,10,14,16,17,19,20,23,24,25,29,31,33,34,38,42,45,46,47,52,56,59,60,61,63. **26 is not among them** |
| exactly one site? | **YES.** `m_specmask & 0x4000000` occurs **once**, `upd6383.cpp:612`. Over both files there are 15 integer literals with bit 26 set and exactly **one** equals `0x4000000`; the only non-single-bit literal ever AND-ed with `m_specmask` is `0x4001` (bits 0 and 14), which does not contain bit 26 |
| fired count, and is it reported? | **YES.** `m_mirror06_n` (`upd6383.h:1378`), incremented at `:615`, emitted at `:5921-5923` — `if (m_mirror06_n) logerror("§106 DIAGNOSTIC: mirrored %u writes of cell 0x06 into 0x05")`. ⚠ Zero prints **nothing**, which is why a null must be read as "count line absent ⇒ 0 fires", not as "unknown" |
| never run? | **CONFIRMED programmatically** over all 17 `data/*.log*`: zero occurrences of the emission |

## 2. WHAT THE TWO ARMS DO, DERIVED STATICALLY FROM THE SHIPPED LOG BEFORE RUNNING

Decoded from the words themselves (`HI_ST = hi12 bit 4`, `mode = class4 & 7`) plus `§109`'s
store-site probe and `§104`'s residency, all in `data/drpub_A_off_217.log.gz`:

```
   iw9   0122FF1D5  HI_ST=1 mode 2  site 2  -> 0x05  val 5 084 004  = acc_to_datum(333 185 286 144)  CONSTANT
   iw11  400201447  HI_ST=0 mode 2  site 3  -> 0x05  val 722..16 760 298                     INPUT-DEPENDENT
   iw19  51220044D  HI_ST=1 mode 2  site 2  -> 0x06
   iw21  410A0040E  HI_ST=1 mode 2  site 2  -> 0x06
   iw27  012201655  HI_ST=1 mode 2  site 2  -> 0x06
   iw33  412A00200  HI_ST=1 mode 2  site 2  -> 0x06  val 6 039 795 .. 6 039 795              CONSTANT
   iw35  012A001C0  HI_ST=1 mode 2  site 2  -> 0x05  val 4 194 304   = acc_to_datum(2^38)    CONSTANT
   iw39  410AFF647  HI_ST=1 mode 2  site 2  -> 0x06  val 1 991 044 .. 8 388 607              INPUT-DEPENDENT
   iw45  010A0020C  HI_ST=1 mode 2  site 2  -> 0x05  val 0                                   ZERO
   iw72  000106087  HI_ST=0 mode 1  site 3  -> 0x06  val 4 194 304                           CONSTANT, mode 1
```

`acc_to_datum(x) = x >> 16` (verified: `333 185 286 144 >> 16 = 5 084 004`, `2^38 >> 16 = 4 194 304`).

**arm B** = `UPD6383_SPEC=b910e446a79b440f` (default **OR** bit 26). The mirror fires on
`mode != 1 && dest == 0x06`, so at **iw19, iw21, iw27, iw33, iw39 — five per kernel-A pass — and
NOT at iw72**, whose mode is 1. **All five are before `iw45`.**

**arm C** = `UPD6383_NOZ05=1`, a NEW env gate (default OFF, fired count + per-`iw` breakdown) that
suppresses the **site-2 bit-4 store when `dest == 0x05` and `pw_region(m_cur_iw) == PW_KERNEL_A`**.
That is `iw9`, `iw35`, `iw45` — **three per kernel-A pass**. `iw11`'s site-3 deposit is untouched,
so the audio still lands in `0x05`.

---

## 3. PRE-REGISTERED PREDICTIONS

### arm A — the CONTROL WHOSE ANSWER IS ALREADY KNOWN

> **A1:** with no env vars set, `s104_score.py` reproduces the NULL **exactly**: `acc 27, mem 21,
> L 18`, body-0 `0/0/0`, last idep `iw38/iw35/iw35`, on 1 440 001 frames / 313 960 loud /
> 726 040 quiet. **If A1 fails the vehicle has drifted and arms B and C are void.**

### arm B — mirror06, and I predict it is a NULL AT THE PICKUP WITH A NON-ZERO FIRED COUNT

★ §219 §8 wrote *"the null is `§104` bit-identical to arm A, which would mean the gate never
fired"*. **I predict a different null: the gate fires ~5× per frame and `iw84` still reads 0**,
because every mirror site is upstream of `iw45`, whose zero store is the last write to `0x05`
before the pickup. §219 §8's stated reading of a null is therefore itself falsifiable here.

> **B1 (fired count):** `§106 DIAGNOSTIC` line PRESENT with count ≈ **5 × the number of kernel-A
> passes** (≈ 5 100 000 over the `§109` window of 1 020 000, more over all frames). Fails if absent
> or if the ratio is not ≈ 5 per pass.
> **B2 (the pickup — THE GRADED ONE):** body-0 idep stays **`0 / 0 / 0`** and `§104`'s `iw84` mem
> stays `0..0 ‖ 0..0`. Fails if body 0 becomes input-dependent — which would REFUTE my static
> reading and CONFIRM §219 §8's deposit-address hypothesis.
> **B3 (blast radius, and it names wrong `iw`s):** `iw35`'s mem/L become the **constant 6 039 795**
> (`iw33`'s mirrored value), so `iw35` **LEAVES** the mem and L idep lists; `iw40..iw44`'s mem
> becomes input-dependent (`iw39`'s mirrored `1 991 044..8 388 607` instead of the constant
> `4 194 304`), so they **JOIN** it. Net: mem idep `21 -> ~25`, last idep mem slot `iw35 -> iw44`.
> Fails if the kernel-A columns are unchanged (⇒ the mirror is not reaching `0x05` at all).

### arm C — the OVERWRITE half, and it is the arm that can actually move the pickup

> **C1 (fired count):** `§220 NOZ05` line present, count = **3 × kernel-A passes**, breakdown
> exactly `{iw9, iw35, iw45}`. Fails if any other `iw` appears (⇒ the condition is wrong and the
> arm is confounded).
> **C2 (THE DISCRIMINATOR):** `§104`'s `iw84` mem becomes **INPUT-DEPENDENT** — quiet and loud
> ranges with unequal deltas, carrying `iw11`'s deposit. ⇒ cell `0x05` IS body 0's pickup and the
> defect is `iw35`/`iw45`'s store TARGET.
> **C3:** body-0 idep goes from `0/0/0` to **> 0** in at least the mem column. The calibration says
> a fully live send reaches `28/32/28`; I predict mem ≥ 10 and do **not** predict it matches the
> calibration, because `SRC0B2` also changed the kernel's arithmetic.
> **C4 (the other side, and it is worth as much):** if C1 passes and `iw84` mem stays `0..0`, then
> **cell `0x05` is NOT body 0's pickup** and `base = 0x05 | unit<<7` is wrong. That is a publishable
> refutation of §219 §3, and it names the wrong claim precisely.
> **C5:** `iw36..iw45` mem stops being the constant `4 194 304` and becomes input-dependent.

### BOTH ARMS — standing rule 1, applied in advance

> **R1:** `§70 ACCA at w73` and `§211 ACCB at w78` read **`min == max == 0`** in the loud bucket
> **and** in the 726 040-frame no-stimulus quiet window, in **all three** arms — six readings each.
> **This is a PREDICTION, not a hope**: §216 proved the output stage is a null independent of the
> send, so a non-zero here is a REGRESSION to explain, not audio. **No audio claim will be made
> under any outcome, and no `min == max` number will be reported as a signal.**

## 4. WHAT WOULD SHIP, AND WHAT WOULD NOT

**NOT sufficient:** any counter moving; any number changing; body 0 becoming input-dependent under
a gate. Both arms are **diagnostics that remove or duplicate a store the corpus says is there**;
neither is a model of the hardware.

**Necessary before any default flip:** a *decoding* reason — a reading of `iw35`/`iw45` under which
the chip does not store to `0x05` at all — and `dsp/verify.py` still BYTE-MATCH OK. **Default OFF
for both is the expected outcome; the deliverable is which of C2/C4 is true.**

## 5. VEHICLE (identical to §217's three arms)

`kn7000-emulator`, `-rompath ./roms -skip_gameinfo -log`, isolated `-nvram_directory`, isolated
`-cfg_directory` **carrying `:DSPCFG value="3"`**, `-pluginspath ./plugins`,
`-autoboot_script ../kn7000_mame/scratchpad/coldnotes2.lua`, `-seconds_to_run 30`, `-window
-resolution 640x480` (**never `-video none`**), `timeout`-wrapped, **one run at a time**.

---

## 6. ADDENDUM — arm D, pre-registered AFTER arms A/B/C ran and BEFORE arm D was launched

Arm C turned out to be the first arm in which the **delay line carries substantial content**:
`§46` reads returning NON-ZERO go **0 -> 3 494 021** of 24 922 560, and `§75` writes-with-content
**1 175 999 -> 2 351 009**. That makes one currently-unknown fact cheap to measure, and it is
`§219 §1.-0` item 3's standing question: **does `UPD6383_DRPUB` have ANY observable consequence
once the line is full?** In every arm so far it was bit-identical to its control *because the datum
it correctly delivered was zero*.

**arm D** = `UPD6383_NOZ05=1 UPD6383_DRPUB=1`, one variable off arm C.

> **D1:** `§215 CLASS-2 SRC 0x0B ... m_dr non-zero on` goes from **0** (arm C) to **> 0**.
> Fails if it stays 0, which would mean `iw12`'s own reads are still always zero and the loss is
> upstream of the publish — §217 F3's alternative, and equally publishable.
> **D2:** the `§217` provenance at `iw25` reads **`iw12`, age 0**, as it did in §217 arm B.
> **D3:** `§104` differs from arm C from `iw25` onward. **A null here would mean `iw25`'s `tempA`
> does not reach anything, which contradicts §215's corpus anchoring and would need explaining.**
> **D4:** `§70`/`§211` still `min == max == 0` in both buckets. Same standing rule 1.

⚠ **This CANNOT make `DRPUB` shippable**: §219 §1.-0 item 3 requires the **shipped** build's line
to carry content, and arm C's line is full only because a diagnostic gate is on.
