# PREDICT_223 — MAKE THE RIG STOP RAILING: the SATURATION CENSUS (`§S1`), `NOZ05` mode 2, and the nop-guard narrowing

**Committed BEFORE `build.sh` was run.** Every number below is read out of a log already in
`dsp/analysis/data/` (decompressed to scratch, never in place) or out of
`kn7000_mame/src/devices/cpu/upd6383/upd6383.{cpp,h}`. **Nothing here was measured by a new run.**

---

## 0. THE TASK, AND WHY §222's OWN PROPOSED FIX IS ALREADY DEAD

§222 §8.1 closed with: *"no end-to-end claim about this machine can be graded until
`UPD6383_NOZ05` stops railing `D-RAM[0x05]`. §220's post-update-store residual is the way in."*

**The residual is REFUTED before it is built, from `A_pickup_222.log.gz` alone.** §220 and §222
both quote the post-update accumulators as if they were audio; convert them the way the store
does, with `acc_to_datum()`'s own `>> ACC_SHIFT` (= `>> 16`) and its own clamp:

```
   iw35 POST, quiet   908 714 800 127 >> 16 = 13 865 887   >  8 388 607   CLIPS  (1.653 x FS)
   iw35 POST, loud    227 691 099 135 .. 1 125 285 262 335
                                      = 3 474 290 .. 17 170 490          CLIPS at the top
   iw45 POST, both    538 760 587 509 >> 16 =  8 220 834   = 98.0 % OF FULL SCALE, CONSTANT
```

⇒ **a post-update bit-4 store deposits the RAIL into cell `0x05` on every quiet frame** — the
exact failure it was proposed to cure — and `iw45` would deposit a near-rail DC constant in both
buckets. **Crossed off. Do not build it.** (Grade: **FORCED** from a log on disk.)

## 0.1 ⇒ AND THE RAIL IS **NOT THE RIG'S**. IT IS IN THE SHIPPED BUILD.

Same log, `§104 PER-SLOT`, arm **A** = `UPD6383_NOZ05 = 0`, **the shipped default**, quiet
bucket = **input exactly zero** (`§54`'s own predicate, `m_in_val[0] == 0 && m_in_val[1] == 0`):

```
   kernel-A accumulator, QUIET bucket, shipped build, as a 24-bit datum (>> 16):
        iw13  15 689 182  (1.870 x FS)      iw33  14 428 403  (1.720 x FS)
        iw16  18 061 870  (2.153 x FS)      iw35  13 865 887  (1.653 x FS)
        iw18  18 865 872  (2.249 x FS)      iw36   8 469 568  (1.010 x FS)
        iw19   8 388 607  (EXACTLY the rail) iw37  10 729 595  (1.279 x FS)
   iw39 is a bit-4 store with dp = 06.  Its datum is the PRE-update accumulator = iw38's
   POST value = 703 174 786 484 >> 16 = 10 729 595 -> CLAMPED to 8 388 607.
   §96, same log:  "cell 06  quiet [0 .. 8388607]  loud [0 .. 16776960]"
   §104 rows 12..21, arm A:  mem quiet 8 388 607 .. 8 388 607
```

⇒ **`D-RAM[0x06]` holds the positive 24-bit rail on every quiet frame of the SHIPPED build**, and
`iw12..iw21` read it back. The accumulator exceeds full scale at **7 of 46** kernel-A slots with
**zero input**. §222's *"the pedestal is `UPD6383_NOZ05`'s own rail"* is therefore **too kind to the
shipped build**: the rig does not create the pedestal, it **removes the two stores that were
hiding it from body 0.**

## 0.2 AND THE RIG'S DIVERGENCE STARTS **UPSTREAM OF EVERY STORE IT DELETES**

```
   §104 row 8  = 084.2.01.1C0   (the FIRST slot where arm A and arm B differ at all)
        arm A   L quiet 0 .. 0                 arm B   L quiet 8 388 607 .. 8 388 607
   The first store NOZ05 suppresses is iw9.  Rows 0..7 are identical in both arms.
```

⇒ the rig's rail arrives **CROSS-FRAME**, not from the deleted stores inside the frame. That is
the falsifiable core of arm **H** below.

---

## 1. WHAT THIS PASS BUILDS — three changes, one build, bisected by the arms

| # | change | class | default |
|---|---|---|---|
| **1** | **`§S1` SATURATION CENSUS** in `acc_to_datum()` — per-`iw`, per-bucket clip counts and pre-clip ranges | **READ-ONLY instrument** | always on, settled frames only |
| **2** | **`UPD6383_NOZ05 = 2`** — suppress **only `iw35`/`iw45`**, keep `iw9` | **rig, env-gated** | OFF (mode 0) |
| **3** | **narrow the nop guard** by `addr8 == 0x00` (`BUILD-LANE-QUEUE.md` item 1) | proven-by-construction | ON, with a fired count |

**Change 3 carries its own unconditional fired count** (`§NG`), because a narrowing whose
count is zero is untested, not inert (rule 8 as sharpened by §220).

## 2. THE ARMS

| arm | env | what it is |
|---|---|---|
| **F** | *(none)* | shipped default. **The NULL, and the bisector for change 3.** |
| **G** | `UPD6383_NOZ05=1` | the existing rig. **The regression control for change 2.** |
| **H** | `UPD6383_NOZ05=2` | the candidate non-railing rig. |

Vehicle: `coldnotes2.lua`, cold boot, isolated NVRAM, isolated `-cfg_directory` carrying
`:DSPCFG value="3"`, `-log`, triad C4/E4/G4 held 21.0–27.5 s, `-seconds_to_run 30`, visible video,
one run at a time.

---

## 3. PREDICTIONS AND FALSIFIERS

### 3.1 `§S1`, the saturation census — arm **F** (shipped)

* **S1** — **≥ 4 distinct `iw` clip in the QUIET bucket**, and **`iw39` is one of them.**
  ⛔ *Falsifier:* zero quiet-bucket clips anywhere ⇒ §0.1's reading of `§104` is wrong **or the
  census is broken**, which S2 exists to separate.
* **S2 — KNOWN-ANSWER CONTROL THAT CAN FAIL, and it is UPSTREAM of all three changes** (a pure
  observer changes nothing, so every control here is upstream by construction; the point of
  naming it is that it must be a value the census could get *wrong*):
  `iw34`'s conversion is `274 877 906 944 >> 16 = 4 194 304` — it **must appear with clips = 0**,
  and `iw35`'s PRE-conversion likewise. A census that reports these as clipping is measuring
  something other than the conversion.
* **S3 — ROW COUNT, PRE-REGISTERED:** the report prints one row per `iw` **with at least one
  clip**, capped at **48** rows **with an overflow counter** (`store_probe()`'s missing-overflow
  defect, `INSTRUMENT-AUDIT` item 7). Predicted rows in arm F: **between 4 and 24**.
* **S4** — the LOUD bucket clips **too** (`iw38 POST loud max = 13 508 518`), so *"clipping only
  happens with no input"* is **not** the claim and must not be reported as one.
* ⚠ **`acc_to_datum()` is called several times per store** (the store, `kwatch`, `watch_store`,
  `store_probe`). The census counts **conversions, not stores**; the *ratio* clips/calls is the
  meaningful column and the report says so on its own line.

### 3.2 `NOZ05 = 2` — arm **H**

* **H1 — THE PRIMARY, and it is a PREDICTED NULL.** `D-RAM[05]`'s `iw11` value in the quiet
  bucket **stays at the rail `8 388 607`**, because §0.2 shows the divergence begins at `iw8`,
  upstream of `iw9`. ⛔ *Falsifier, and it is the outcome worth having:* if `iw11` returns to
  `5 084 004` (arm A's value) or to any non-railed range, **`iw9` was the cause, arm H is a
  non-railing rig, and mode 2 ships as the rig of record.**
* **H2 — FIRED COUNT, and it can fail:** the `§220 NOZ05` breakdown lists **exactly 2** `iw`
  entries — `iw35` and `iw45`, ~1 176 000 each — where arm B listed **8**
  (`iw9:1176015 iw19:19 iw21:12 iw27:12 iw35:1176007 iw33:8 iw45:1176003 iw39:4`).
  A different row count means mode 2 does not do what it says.
* **H3 — `iw9` IS BACK:** the writer census prints `D-RAM[05] site 2 iw 9 n 540000
  val quiet 5084004..5084004 loud 5084004..5084004`, exactly as arm A does.
* **H4 — body 0 stays on live audio:** `§104` body 0 = **`28/32/28`**, the §220/§222 calibration,
  identical to arm G. ⛔ If it is not, mode 2 changed something it should not have.
* **H5 — `§54` stays clean and the output stays a null:** `quiet-in → LOUD = 0`, `§70`/`§211`
  **mean 0.0, AC span 0** in **both** buckets — because §216/§221 make the output stage a null
  independently of the send. ★ **A non-zero `§70` here would NOT be audio**; it would be the
  §222 rail again and is pre-registered as a FAILURE, not a success.

### 3.3 The nop-guard narrowing — arm **F** against the archive

* **N1 — FIRED COUNT > 0.** `§NG` counts words that now reach `exec_alu()` because
  `addr8 != 0x00`. `NOP-GUARD_findings.md` says **21 of the 103** execute in the archived vehicle
  (kernel `iw57` + 20 in body 1). ⛔ A count of **0** means the change is **untested**, not inert,
  and it must be reported as such.
* **N2 — THE BISECTION, graded against `A_pickup_222.log.gz` which is already on disk.**
  Arm F must reproduce, **digit for digit**:
  - `§104` region tallies **`kernel A 27/26/20 | body 0 2/4/1 | body 1 0/0/0 | epilogue 0/0/0`**
    (`dsp/tools/s104_tally.py`, validated this pass against all four §222 arms — it reproduces
    `28/32/28`, `33/40/29`, `2/1/2`, `59/44/49`, `22/19/9` exactly);
  - `§54` `quiet-in 826 040 → 826 040 silent / 0 LOUD`;
  - `§70`/`§211` **mean 0.0 span 0**, both buckets;
  - `§41` `unit0 0x400000 / unit1 0x178D0B`;
  - `m_rf[0x8D] = 0x009B26`;
  - `D-RAM[05]` writer census `iw9 / iw11 / iw35 / iw45`, values as §0 quotes them.
  ⛔ **Any divergence ⇒ the narrowing is LOAD-BEARING and gets REVERTED**, and the divergence is
  attributable to it alone: `§S1` is read-only and `NOZ05` mode 0 is the shipped path unchanged.
* **N3** — `dsp/verify.py` **BYTE-MATCH OK**; both disassembler mirrors untouched.

### 3.4 WHAT WOULD MAKE THIS PASS SHIP A DEFAULT FLIP

**Nothing below the line "arm H does not rail AND arm F is byte-identical to the archive".**
A moved number is not enough; §217–§222 all correctly declined. **A NULL is a fine outcome**, and
so is *"no store-suppression rig can avoid the rail, because the rail has two independent causes
and here they are, named and counted."*

---

## 4. THE NUMBERS THIS PASS IS NOT ALLOWED TO QUOTE WITHOUT `§54`

Three "the output moved" events have occurred in this project; two were retracted and §222's was
caught only by `§54`. **Report order is fixed:** `§54` first (quiet bucket must not be full scale,
loud peak must exceed quiet peak), then the peak comparison, then `§70`/`§211` **mean AND AC span,
both buckets, every arm**, then body 0's `28/32/28`. `79 438 ± 90` passes min-vs-max, the
no-stimulus check and the translation rule and is a **DC at −59 dB** (rule 19).
