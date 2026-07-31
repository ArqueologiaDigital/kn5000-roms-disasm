# INSTRUMENT AUDIT — every diagnostic in `upd6383`, classified

**Scope.** `src/devices/cpu/upd6383/upd6383.cpp` (6957 lines) and `upd6383.h` (1759 lines)
at `kn7000_mame` HEAD `b03e9d6` ("221 — the epilogue is EXONERATED BY PROVENANCE"),
working tree clean against HEAD **at the time of the sweep**. Read-only pass; no source
was edited, no build was run, no emulator was launched.

⚠ **§221 modified the working tree during this audit** (+114 lines in `.cpp`, +90 in `.h`
as of writing). **Every line number below is a HEAD line number**, recoverable exactly
with `git show b03e9d6:src/devices/cpu/upd6383/upd6383.cpp`. In the working tree they are
shifted from `:389` onward (roughly +18 by `:1009`, +21 by `:1049`, +27 by `:1507`,
+31 by `:1957`). Each finding also names the construct and the `§` number, which are
grep-stable — see recommendation R7.

**Method — programmatic, never a spelling grep.** Comments and string literals are
replaced by spaces (offset-preserving) before any parsing, so prose beside a counter can
never be mistaken for code. Machinery reused/extended from `dsp/tools/bit26_audit.py`
(`strip_comments`). Five independent passes: member enumeration → dataflow separation of
instruments from machine state → gate-conjunct decomposition → scope-walk class-C
detection → a *second, independently written* class-A detector. Scratch scripts:
`/tmp/claude-1000/…/scratchpad/audit/{cpplib,enum1,enum1b,enum2,classify,classify2,classify3,classify4,classA_direct,classB,tally}.py`.

**Detector self-test (this is why the numbers can be trusted).** The first class-C
detector returned 9 hits and did **not** contain `m_dwr` — the defect the brief already
knew about. Root cause: the print-family list omitted `string_format`, and *every* table
in this device is built with `string_format` into a `std::string` that `logerror` emits
later, so `m_dwr` fell out of the population entirely. After adding it the detector
rediscovers `m_dwr` at **both** sites unprompted. Any audit of this file that greps only
for `logerror` misses **50 of 266 print sites (19 %)**.

⚠ **The brief's line numbers are stale.** `:1503`, `:3671`, `:643` do not correspond to
the cited constructs at HEAD (`:643` is a closing brace of `e1_route_name`). Everything
below is re-located structurally and cited at **HEAD line numbers**. A third set of line
numbers for the same instrument appears in the notes (`PREDICT_S1_hi12_bench.md:442` cites
`D-RAM WRITES` at `upd6383.cpp:817`). **Three different line numbers now circulate for
one counter** — see §7, recommendation R7.

---

## 0. HEADLINE — read this first

1. **`§70`/`§211`'s instrument is SOUND.** The `min == max == 0` result is *not* an
   artefact of a defective counter. Both censuses print their own frame counts
   (`726 040` quiet / `313 960` loud, non-zero in every archived arm), the `INT64_MAX`
   sentinels survive `device_reset()`, and the two known defect shapes it could have had
   (pooling, self-concealment) both bias **toward** a non-zero reading, not toward zero.
   Two secondary defects exist and neither can manufacture the null. **MEASURED**, §1.
2. **A confirmed mis-attribution in a load-bearing note.** `OUTPUT-STAGE-NULL_findings.md`
   §1 says `iw205` read cell **`0xD0`**. It read **`0x85`**. The trace's `dp` column is
   sampled **after** `exec_decoded()`; `§104`'s `dp` is sampled **before** it; they have
   the same name and differ by exactly one word. Proven by arithmetic: `0x85 + 0x4B(addr8)
   = 0xD0`. The *conclusion* (ACCB←0) survives; its stated mechanism cites the wrong cell
   and its `D-RAM WRITES D0:` corroboration is about a cell `iw205` never touched. **§5.1.**
3. **`PREDICT_S1_hi12_bench.md`'s falsifier F1 is structurally incapable of firing.** It
   grades on "`D-RAM WRITES` **total** at the cell under `m_dp` rises vs the control arm",
   but `m_dwr[]++` sits **outside** the store guard at both store sites — suppressing the
   store cannot change the total. By this project's own rule, a criterion that cannot fail
   is void. **§5.2.**
4. **The apparatus is *not* sound apart from the four already known.** The sweep found
   the four (three still live, one already fixed by §213 and mis-described in the brief),
   plus **seven** further scalar self-concealing fired-counts, **15** write-only
   instruments, **48** unreset pooling censuses, and a truncation table that drops entries
   with **no overflow counter** while its two sibling tables both have one.

---

## 1. ★★★ `§70` ACCA@`w73` / `§211` ACCB@`w78` — THE INSTRUMENT IS SOUND

**Verdict: SOUND for the claim it carries.** Grade **MEASURED**.

| element | site | finding |
|---|---|---|
| capture | `upd6383.cpp:2157-2178` | `m_pa_{min,max,sum,n}` / `m_pb_{min,max,sum,n}` |
| sentinels | `upd6383.h:1041,1050` | `{INT64_MAX,INT64_MAX}` / `{INT64_MIN,INT64_MIN}` |
| `device_reset()` | `upd6383.cpp:451-474` | **does not touch them** — the sentinels are intact |
| print | `upd6383.cpp:5977-5985` | fired count printed **first**, unconditionally |
| RULE 19 | `upd6383.cpp:5992-6007` | mean and AC span printed separately |

**Why the three failure modes cannot produce the null:**

* **Not class A.** The print renders `m_pa_n[k] ? m_pa_min[k] : 0` — a ternary on its own
  count that substitutes **`0`**, the very value that means "silent". But `m_pa_n[k]` is
  printed as the *first* field of the same line, so "never ran" is distinguishable.
  Archived logs read `quiet frames 726040 loud frames 313960` — the census demonstrably
  ran. **MEASURED**, `data/A_epibus_221.log.gz:2150-2151`.
  *Residual cosmetic hazard*: a reader quoting `min 0 max 0` without the frames column
  gets a false negative. Fix: render a sentinel (`--`) instead of `0` when `n == 0`.
* **Not class D in a direction that matters.** `m_pa_*`/`m_pb_*` arm at frame 400 000 and
  are **never reset** (48-of-48 census, §4). Pooling a program change can only *add*
  values to a min/max, i.e. only *widen* the span. The observed span is 0, so pooling
  did not hide anything. **INFERRED from the monotonicity of min/max; the premise is
  MEASURED.**
* **Sentinel not clobbered.** `device_reset()` re-initialises `m_kq_min`/`m_kl_min` (`:463`)
  but never `m_pa_*`/`m_pb_*`. Had it zeroed them, `if (a < m_pa_min[k])` would never fire
  for non-negative data and `min` would be pinned at 0 — a manufactured null. It does not.
  **MEASURED**, `upd6383.cpp:451-474`.

**Two real secondary defects, neither load-bearing on the null:**

**(1.a) `§211`'s "ACCB" column is ACCB only under the speculative mask — class C, latent.**
`upd6383.cpp:2094`:

```
const u64 pacc = (m_speculative && (m_specmask & 0x4001) && unit) ? m_accb : m_acc;
```

`§211`'s capture (`:2166-2177`) reads `pacc`. With `m_speculative == false` (its declared
default, `upd6383.h:504`) **or** with bits 0 and 14 both clear, the line labelled
`§211 ACCB AT w78` silently reports **ACCA** — the identical register `§70` reports.
The shipped mask `0xb910e446a39b440f` has bits 0 and 14 set, and both archived masks
(`0x110E446A39B440F`, `0xB910E446A79B440F`) do too, so **no archived log is affected**.
Grade: **MEASURED** (mask arithmetic + log mask lines) for "not currently affected";
**FORCED** for "a `UPD6383_SPEC=0` control arm would mislabel the column".

**(1.b) `§70`/`§211` arm 20 000 frames earlier than the file's own settled point — RULE 16.**
`:2157` and `:2166` use `m_frames_run > 400000`. The same file declares the first
**420 000** frames one boot transient and refuses to count them in `pwatch()` (`:609`),
`kwatch()` (`:1050`), `§81` (`:5134`) and `§104` (`:5170`), citing §46. `§70` and `§211`
are the **only** two censuses in the device at 400 000. Measured consequence, visible in
every log: `§70` reports `quiet 726 040`, `§104` reports `nq 706 040` — **exactly 20 000
frames apart**. Any note that compares the two populations row-for-row is comparing
different windows. The bias direction again favours a *non-zero* reading, so the null
survives; but a future *non-zero* `§70` reading would need the 400 000 gate raised before
it could be believed. **MEASURED**, `data/A_epibus_221.log.gz:2150` vs `:2205`.

---

## 2. THE FOUR ALREADY-KNOWN DEFECTS, RE-VERIFIED (RULE 3)

Checking the code's own comments and the owning notes **first** changed the verdict on
two of the four.

| # | brief's claim | verdict at HEAD |
|---|---|---|
| 1 | fired count under `if (count)`, §220 bit 26 | **FIXED**. `:6480-6482` now prints `§106 DIAGNOSTIC (mask bit 26 = %d): mirrored %u writes`, unconditionally, with the gate state. `:6477` carries a comment naming the exact defect. |
| 1b | "found again at `upd6383.cpp:643`, counter on the `m_rf` branch only" | **NOT REPRODUCED at that line.** `:643` is `}`. `m_rf_st[dest]++` (`:1036`) *is* on the `m_rf` branch only — but that branch **is** the register-file store, so the counter is correctly scoped. It is a class-A *row filter* at `:6494` (`if (m_rf_st[c])`), which is table sparsity, not a concealed fired-count. **The brief is wrong here.** |
| 2 | `m_src02_n` incremented, never printed | **CONFIRMED**, `:3087` writes, no read anywhere. One of 15 (§3). |
| 3 | `D-RAM WRITES` is not a per-cell content census | **CONFIRMED AND WORSE**, §5. Already documented in `IW205-DRAM-D0_findings.md:178,424` and `OUTPUT-STAGE-NULL_findings.md:17`. |
| 4 | `§104` arms at 420 000 and never resets | **CONFIRMED**, `:5170`; hard-coded literal, no env knob. `m_sp_word[prof_iw] = raw` (`:5176`) is last-write-wins, so the printed **word** is the last program's while the **numbers** pool every program at that slot. Note `§128` (`:314-320`) gives the *trace* an env-settable arm frame for exactly this reason; `§104` never got one. |
| 5 | stale format string dropping `mem`/`tA`/`tB` | **CONFIRMED**, §6. |

Programmatic format-string check: **0** printf arity mismatches across all 266 call sites.
Defect 5 is not an arity bug — the fields are captured into `trace_t` and never passed.

---

## 3. CLASS B — WRITE-ONLY (value reaches no output on any path): **15 of 203**

Naïve "never a print argument" gives 16; one (`m_cwr_start`) reaches the report via
`m_run_base`, so reachability over the member→member assignment graph is the correct test.

| instrument | write sites | note |
|---|---|---|
| `m_src02_n` | `:3087` | §100 "times SRC 0x02 read the addressed register" — the brief's defect 2 |
| `m_bx_act0e_n` | `:3872` | §133 demux fired-count |
| `m_bx_inj_n` | `:5398` | §133 injector fired-count |
| `m_bx_supp_n` | `:3775` | §133 tempA-suppress fired-count |
| `m_bx_shmax` | decl only (`h:695`) | never written at runtime |
| `m_dr_pend`, `m_dr_pend_v` | decl only (`h:1575`) | pre-§78 single pending register, superseded by `m_dr_line[]`; dead |
| `m_dr_prov_line` | `:2584`, `:2634` | §217 line tag; the `iw` sibling is used, the line is not |
| `m_cimm` | `:2275` | "c-format immediate latch (row 5 test)" |
| `m_cwr_hi` | `:1344` | read once at `:1345` into `m_cwr_port`, which is itself class B |
| `m_cwr_port` | `:1345` | terminal |
| `m_in_readbase` | `:1899` | |
| `m_pv_acc_zfr`, `m_pv_ta_zfr`, `m_pv_tb_zfr` | `h:1543,1551,1559` | **§221 `§E1` — owned by another agent; listed, not adjudicated** |

**Severity: low individually, high as a pattern.** Four of the fifteen are `§133` demux
fired-counts. `§133`'s own comment (`h:298-300`) says *"A silent selector is how §121 ran
seven arms that were all the same arm"* — and then four of its selectors' fired-counts are
unprintable. If `§133` is ever re-armed, three of its four arms cannot be graded.

---

## 4. CLASS D — UNRESET / POOLING: **48 of 48 armed instruments**

Every instrument in the device that has a frame-arming threshold pools across program
changes, mode changes and warm resets. **Zero exceptions.** `device_reset()` touches 24
members; **none of them is an armed census**.

| threshold | instruments | sections |
|---|---|---|
| 300 000 | (`§54` scoring gate, `:4762`) | §54 |
| **400 000** | `m_pa_{min,max,sum,n}`, `m_pb_{min,max,sum,n}` (8) | **§70, §211** |
| 420 000 (guard clause) | `m_kw_{n,cell,who,word}` (4) | §86, §96 |
| 420 000 | `m_sp_*` (15), `m_s213_*` (11) | **§104, §213** |
| 900 000 | `m_prov_*` (3), `m_c2c_*` (5), `m_epibus_fired` (1) | §217, §218, §221 |
| 970 000 | (`§33` one-shot, `:1903`) | §33 |

**Five different arming thresholds in one device**, and tables at different thresholds are
read against each other in the notes. The 20 000-frame gap between `§70` and `§104` is
directly visible in every archived log (§1.b).

**The `§104` pooling defect, stated precisely (matches §193's shape):** arm at
`m_frames_run > 420000` (`:5170`), no reset, `m_sp_word[prof_iw] = raw` last-wins
(`:5176`). In a type-walk the panel selects an effect at ~1.8–2.2 M frames (`§128`,
`:314-320`), so a single run's `§104` table pools ~1.4 M cold-boot-program frames with
~0.4 M selected-program frames **at the same slot numbers**, printing the selected
program's *word* beside the default program's *numbers*. **FORCED** from the code.

Exception worth recording: the **frame trace is not affected** — it re-zeroes `m_trace_n`
on arming (`:1814`) and disarms at `:5471`, so it is a genuine one-shot.

---

## 5. CLASS C — MIS-SCOPED / MIS-NAMED (the dangerous class)

### 5.1 ★★ `dp` means two opposite things and has produced a wrong cell attribution

| instrument | sampling phase | site |
|---|---|---|
| `§104` `m_sp_dp[]` | `m_dp` **before** the word runs (`s104_dp`) | `:5109` → `:5175` |
| frame trace `t.dp` | `m_dp` **after** `exec_decoded(word)` | `:5111` → `:5115` |

Both print under a column headed `dp`. They differ by exactly one word's pointer update.

**Confirmed consequence.** `OUTPUT-STAGE-NULL_findings.md` §1 (the "THIRD DEATH at `iw205`,
kills 128 of body 1's 133 slots" paragraph) states: *"`m_dp = 0xD0` at that slot (trace row
n=135)"* and corroborates with *"`D-RAM WRITES` reports `D0: 0/4 727 824`"*.

Measured, `data/drpub_A_off_217.log.gz`:

```
trace  n=135  iw 205  …  dp D0        (POST-execution pointer)
§104   iw 205  word 020224B1CD  dp 85  mem quiet 0..0 / loud 0..0   (PRE-execution)
§104   iw 206  word 000020040E  dp D0
```

`iw205 = 020224B1CD`, `addr8 = 0x4B`; `0x85 + 0x4B = 0xD0`. **PROVEN BY ARITHMETIC**:
`iw205` read cell **`0x85`** and left the pointer at `0xD0`, which is what `iw206` reads.

⇒ The **conclusion** (`ACCB ← 0` at `iw205`) **stands** — `§104`'s `mem` column at `iw205`
is `0..0` in both buckets, and that column is the correct instrument. The **mechanism
paragraph names the wrong cell**, and its `D-RAM WRITES D0:` corroboration is evidence
about a cell `iw205` never touched. (`D0: 0/4 727 824` is dominated by `iw206`+.)
Note that `IW205-DRAM-D0_findings.md:178`'s ⚠ box is about `D-RAM WRITES 85:…` — the note
was circling the right cell already.

### 5.2 ★★ `D-RAM WRITES (nonzero/total)` — three sites, three semantics, one array

`m_dwr[256]` / `m_dwr_nz[256]` (`h:804`), printed at `:1209-1211`.

| site | `m_dwr` increment | `m_dwr_nz` predicate | inside the store guard? |
|---|---|---|---|
| `:1932` (§109 site 1, K6) | `m_dwr[cell & 0xff]++` | `m_dram.read_dword(cell)` — **cell content** | **NO** — guard at `:1922-1931` closed before it |
| `:3483` (§109 site 2, bit-4) | `m_dwr[stdest]++` | `m_dram.read_dword(stdest)` — **cell content** | **NO** — guard at `:3413` closed before it |
| `:4198-4199` (§109 site 3, ACT-07) | `m_dwr[d07]++` | `u32(L) & 0xffffff` — **the datum**, not the cell | partly: inside `if (!phantom)` (`:4192`), but `lvl_hit`/`ab_hit` also reach it |

So the array is **(a)** a visit census at two sites and a store census at the third,
**(b)** a residency census at two sites and a datum census at the third, and **(c)** the
`!lvl_hit && !ab_hit` hand-patch that `§213` applied to `store_probe()` at `:4196-4197`
was **not** applied to `m_dwr` two lines below — so the `§104 A/B` and `§41` suppressor
arms still record stores that did not happen. §213's fix (`:4187-4200`) is **partial**.
Programmatically confirmed: 4 distinct predicates feed one array (`classify4.py`).

**Load-bearing consequence — `PREDICT_S1_hi12_bench.md` falsifier F1 cannot fire.**
F1 reads *"`D-RAM WRITES` **total** at the cell under `m_dp` at iw119 rises vs the control
arm"*. Suppressing a bit-4 store changes `st_suppressed_live()` → changes whether
`m_dram.write_dword` runs at `:3477` → does **not** change `m_dwr[stdest]++` at `:3483`,
which is outside that guard. **The PASS condition is structurally unreachable.** By the
project's own rule ("a criterion that cannot fail is not a pass") F1 is void as a
calibration — which matters because the note states *"F1 and F2 are the calibration and
they must be read BEFORE anything else in the log."* Grade **FORCED** from the code.

### 5.3 `§49 PIPELINE` sums two different pipeline models into one counter

`m_dr_landed++` at `:2595` (the `§78` **per-line** pipe, mask bit 20) **and** at `:5045`
(the `§49` **per-slot** pipe, mask bit 10). Both bits are set in the shipped default
(`0x100000` and `0x400` are both in `0xb910e446a39b440f`), so the printed number
(`§49 PIPELINE: %u delay data LANDED`) is a sum the reader cannot decompose.
*Currently unambiguous by luck*: archived logs show `§49 LANDED 24 922 552` **equal** to
`§80 hits 24 922 552`, so the `:5045` site contributed 0. **MEASURED**
(`data/A_epibus_221.log.gz`). Latent, not active.

### 5.4 `m_pk_cram` counts packets tagged `0x26`, not C-RAM writes

`:1495-1501`: `if (m_cram_wp_set) { m_cram.write_dword(…); }` then `m_pk_cram++`
**unconditionally**. A coefficient arriving before the pointer is set is discarded and
still counted. Low severity — the report at `:1253` uses `m_cwr`, not `m_pk_cram`, for
"coefficients routed".

### 5.5 Triaged and CLEARED (detector hits that are not defects)

`m_rf_st` (`:1036`), `m_pk_dram` (`:1488`), `m_pk_dsc` (`:1493`), `m_pk_ptr`
(`:1513/1514/1516`), `m_pk_other` (`:1503/1517`), `m_dly_noalu` (`:2605`),
`m_stprobe_n` (`:4202`), `m_bx_chg` (`:5874`) — each inspected; the counter is in the
scope that owns the action it names. `m_dly_noalu` in particular is a correct RULE-8
two-sided measurement (`§77 … skipped 0`, printed unconditionally).

---

## 6. CLASS E — TRUNCATION AND DROPPED COLUMNS

### 6.1 ★★ The frame trace's header is stale and three captured columns are never printed

`trace_t` (`h:653-655`) captures 14 fields including `mem`, `ta`, `tb`.

* header, `:1228`: `n  iw   word  dp  mem[dp]  acc  P  tA  tB cur  coef  MUL  L` — **13 names**
* format, `:1232-1235`: `q, t.iw, t.u1, t.word, t.dp, t.acc, t.accb, t.p, t.cur, t.coef, t.mul, t.l` — **12 values**

`t.mem`, `t.ta`, `t.tb` are captured and dropped; `u1` is printed and unnamed. Reading the
table by header name shifts every column after `iw`:

| header says | actually is |
|---|---|
| `word` | `u1` |
| `dp` | `word` |
| `mem[dp]` | `dp` |
| `acc` | `acc` *(coincidence)* |
| **`P`** | **`accb`** |
| **`tA`** | **`P`** |
| **`tB`** | **`cur`** |
| `cur` | `coef` |
| `coef` | `MUL` |
| `MUL` | `L` |
| `L` | *(nothing)* |

Verified against a real row (`drpub_A_off_217`, n=132): under `P` sits `5 206 020 096`,
which `OUTPUT-STAGE-NULL_findings.md` correctly identifies as **ACCB**. So the note's
author decoded the real order — but anyone trusting the header reads ACCB as P and P as
tempA. **MEASURED.**

This is also why `§213` exists: its comment (`h:537-541`) says *"`L' shows tempA only at
the slots that SOURCE it, and P is never shown at all"* — a whole instrument was built
because the trace's `tA`/`P` columns were believed absent. They **are** captured; only the
print drops them.

### 6.2 `store_probe()` truncates with **no** overflow counter — and `§109` is load-bearing

`:546-563`: `if (s.nst >= SPROBE_ST) return;` with `SPROBE_ST = 4` (`h:737`). A watched
word storing to a 5th distinct `(site,addr)` pair is **silently dropped**.
Its two sibling tables both do this correctly: `prov_bump()` (`:569-581`) increments
`other++`, and `e1_bump()` (`:674-680`) increments `other++`. `store_probe()` is the odd
one out, and it is the instrument behind `§109 STORE-SITE PROBE`.

Related latent hazard: `sprobe_idx()`'s `SLOTS[]` (`:538-540`) holds **exactly 24**
entries and `SPROBE_MAX == 24` (`h:736`), with `m_sprobe[SPROBE_MAX]` (`h:751`) and **no
`static_assert`**. Adding a 25th watch slot writes past the array — a buffer overrun, not
a truncation.

### 6.3 `§41 LEVEL` reports one value where it should report a range

`:2138` `m_lvl_seen[unit] = lvl;` is a last-value latch overwritten ~1.2 M times, printed
at `:6738-6741` as a single hex value. The file's own rule (`:671-673`): *"a census that
can only print one answer cannot show that the answer varies."* It is also **ungated** —
it counts from frame 0, pooling the boot. Mitigated by the co-printed `m_lvl_nz` count
(`1 172 160` of `1 203 840` presentations — the 31 680-presentation shortfall *is* the
boot). Low severity, but `§41` is on the brief's load-bearing list.

### 6.4 `§46`/`§75`/`§77`/`§80`/`§48` delay counters are ungated — RULE 16

`m_dly_r`/`m_dly_w` (`:2418`), `m_dly_cell_nz` (`:2419`), `m_dly_w_nz` (`:2528`),
`m_dly_r_nz` (`:2615`), `m_latch_n`/`m_latch_nz` (`:2618-2619`), `m_pub_*` (`:2577-2580`),
`m_dr_reads*` (`:2901`) all count from frame 0 — the exact error the brief attributes to
`§46`'s descriptor claim. Still present. Internal coherence *is* good:
`§77` `22 521 600` + `§215` `1 211 520` = `§48` `23 733 120` ✓ and `§80 hits` = `§49 landed`
= `24 922 552` ✓ (`data/A_epibus_221.log.gz`), so the counters are consistent with each
other; they are simply measuring a window that includes the boot.

---

## 7. CLASS A — SELF-CONCEALING: **23 sites**, of which **7** are the §220 shape

Two independently written detectors were used because the first (scope-walk) returned
only 2 and I did not trust it; the second (direct guard-dominance) returned 23 and
subsumes the first.

**The 7 that matter — a scalar whose zero is the interesting answer:**

| instrument | guard | site |
|---|---|---|
| `m_lvlguard_n` | `if (m_lvlguard_n)` | `:6742-6744` — `§41 LEVEL GUARD` (mask bit 5, **off by default**) |
| `m_latchguard_n` | `if (m_latchguard_n)` ×2 | `:6745`, `:6752-6760` — `§34`/`§36 LATCH ALARM` |
| `m_trace_n` | `if (m_trace_n)` | `:1225-1237` — the frame trace: "armed, 0 slots" ≡ "never armed" |
| `m_prov_other` | `if (m_prov_other)` | `:6198-6200` — **the overflow indicator of a truncated table** (E+A compounded: the one number that says whether `§217`'s histogram is complete is printed only when it is not) |
| `m_bx_on`, `m_bx_sweep` | `if (m_bx_on \|\| m_bx_sweep)` | `:309-313` — `§133`'s selector announcement, silent when off, contradicting its own comment at `h:298-300` |
| `m_frames_dp_measured` | `if (… != 0 && …)` | `:6348-6349` |

**The other 16** are per-row sparsity filters on tables (`if (m_dwr[i])`, `if (m_pk_tag[i])`,
`if (m_rw_rd[r][c] || m_rw_wr[r][c])`, …). Normal for a sparse table; the residual hazard
is that a row's absence conflates "cell never touched" with "the census never ran". Only
`m_dwr`'s table prints **no** total alongside, so it is the one worth a denominator.

**Blocks whose entire output vanishes on a truth test** (RULE-8 exposure, not
self-concealment): `if (m_latchguard_n)` suppresses 7 members' output; `if (m_order_valid)`
suppresses 6 — but that one has an **`else`** that explains the null (`:6786-6791`) and is
the model the others should follow.

---

## 8. RISK LIST — recorded findings ranked by load-bearing-ness

| # | recorded finding | instrument | defect | risk | cheapest check |
|---|---|---|---|---|---|
| **1** | `OUTPUT-STAGE-NULL_findings.md` §1: `iw205` is the THIRD DEATH, "kills 128 of body 1's 133 slots"; mechanism = `m_dp = 0xD0`, `D-RAM WRITES D0: 0/4 727 824` | trace `dp` (post-exec) vs `§104` `dp` (pre-exec) + `D-RAM WRITES` | **C** §5.1 | **CONCLUSION SURVIVES, MECHANISM CITES THE WRONG CELL.** Correct cell is `0x85` | **already done, zero cost**: `§104` row `iw205` in `drpub_A_off_217` reads `dp 85 / mem 0..0` — replace the `D0` citation with `§104 iw205 mem` |
| **2** | `PREDICT_S1_hi12_bench.md` F1 (the pre-registered **calibration** for the whole `a70` bench) | `m_dwr` total | **C** §5.2 | **F1 CANNOT FIRE** — the total is invariant to store suppression. A run graded on it is void by the project's own rule | re-express F1 on `§104`'s `mem` column at the cell under `m_dp` at `iw119`, or on `§109`'s `store_probe` `[siteN addr XX …]` list; both are content/store censuses |
| **3** | `§104` residency: `28/32/28`, `2/1/2`, body-0 pickup | `m_sp_*` | **D** §4 | **SAFE FOR SINGLE-PROGRAM RUNS, UNSAFE FOR TYPE-WALKS.** All archived logs are single-program (word column consistent), so the recorded numbers stand | grep any type-walk log for a `§104` row whose `word` disagrees with the same `iw` in a single-program log — a disagreement proves pooling; identical words prove the run was single-program |
| **4** | `§70`/`§211` `min == max == 0` — the whole "still silent" claim | `m_pa_*`, `m_pb_*` | **1.a latent C, 1.b RULE 16** | **SOUND. The null stands.** Both defects bias toward a *non-zero* reading | none needed. Before believing any *future* non-zero `§70`, raise the gate to 420 000 and re-run — the 20 000-frame boot window is the only untested contaminant |
| **5** | `§109` store-site tables (cited in `LEDGER`, `HANDOFF-NEXT`, `PREDICT_220`, `F31_ROUND2`) | `store_probe` `SPROBE_ST = 4` | **E** §6.2 | **UNQUANTIFIED.** No overflow counter, so no log can say whether any site truncated | count `[siteN addr …]` groups per row in an archived log; **any row printing exactly 4 groups is a truncation suspect**. Computable from `data/*.log.gz` now |
| **6** | any conclusion read off the frame trace by column name | trace header `:1228` | **E** §6.1 | **HIGH for a new reader, LOW for existing notes** — the one note that uses it decoded the real order | re-read every note passage quoting a trace column and confirm it used the real order `n iw u1 word dp acc accb p cur coef MUL L` |
| **7** | `§46 DELAY PORT` descriptor claim; `§75`, `§77`, `§80`, `§48` | ungated counters | **RULE 16** §6.4 | **LOW.** Boot is ~1.4 % of frames and the counters are mutually coherent | divide each by `m_frames_run` and compare with the same ratio over `frames > 420 000` from `§104`'s `nq+nl` |
| **8** | `§41` presentation LEVEL | `m_lvl_seen` last-value | **E** §6.3 | **LOW.** `m_lvl_nz` supplies the denominator | already answered in-log: `0x400000`, non-zero on `1 172 160` of `1 203 840` |
| **9** | `§133` demux arms | 4 write-only fired-counts | **B** §3 | **DORMANT** (bits 39-41 off in the default) — becomes acute the moment `§133` is re-armed | print them before re-arming |
| **10** | `§49 PIPELINE` landed count | two mechanisms, one counter | **C** §5.3 | **LATENT.** Currently equals `§80 hits` exactly, so the second site contributed 0 | already checked; re-check on any arm that changes mask bit 10 or 20 |
| **11** | `§160`, `§186` | `m_rf` / `m_hostw_*` | — | **SOUND.** Both print totals and per-cell detail with an explicit denominator (`63 writes over 59 cells (42 ever non-zero)`) | none |
| **12** | `§86` input-dependence (`3 of 31`) | `m_kq/kl_min/max` | — | **SOUND.** Sentinel-initialised **and** re-initialised in `device_reset()` (`:463`), guard-clause gated at 420 000 (`:1050`), prints the denominator | none |

---

## 9. RECOMMENDED FIXES (described, not diffed — §221 owns the file)

**R1 (highest value, ~4 lines).** In `store_probe()` (`:546-563`) add a `u64 m_sprobe_drop`
incremented on the `if (s.nst >= SPROBE_ST) return;` path, and print it in the `§109`
header line unconditionally. Also add `static_assert(sizeof(SLOTS)/sizeof(SLOTS[0]) <=
SPROBE_MAX)` in `sprobe_idx()`.

**R2.** Fix the trace header at `:1228` to `n iw u1 word dp acc accb P cur coef MUL L`, or
add `t.mem`, `t.ta`, `t.tb` to the format at `:1232` and keep the header. Prefer the
latter — `§213` exists only because those columns were thought missing.

**R3.** Rename one of the two `dp` columns. Suggest `§104`'s stays `dp` (pre) and the
trace's becomes `dp'` (post), with a one-line legend. This is the fix that would have
prevented risk-list item 1.

**R4.** Split `m_dwr` into `m_dwr_visit[]` and `m_dwr_store[]`, and make `m_dwr_nz` test
the **cell** at all three sites (`:1932`, `:3483`, `:4199`), moving the `:4198-4199` pair
inside `if (!lvl_hit && !ab_hit)` alongside `store_probe()` — completing §213's fix. Print
a per-cell total so the table has a denominator.

**R5.** Make the seven scalar class-A prints unconditional with the gate state, using
`:6480-6482`'s pattern (`(mask bit N = %d): FIRED %u times`). `m_prov_other` and
`m_lvlguard_n` first — the former is a truncation indicator, the latter grades a
default-off arm.

**R6.** Raise `§70`/`§211`'s gate from 400 000 to 420 000 (`:2157`, `:2166`) so all
comparative censuses share one window; and give `§104` a `UPD6383_S104_FRAME` env knob
mirroring `§128`'s `UPD6383_TRACE_FRAME`, so a type-walk can arm it after the program
change instead of pooling across it.

**R7 (process).** Line numbers cited in notes go stale within days. Cite instruments by
`§` number **plus** the printed format-string prefix (e.g. `"D-RAM WRITES (nonzero/total)"`),
which is grep-stable across edits, and record the commit hash.

---

## 10. TEN-LINE SUMMARY

1. **539 members** parsed; **203 diagnostic instruments** (pure sink) + **176** machine-state
   members that are also reported; **266 print sites** (214 `logerror`, 50 `string_format`,
   2 `osd_printf_info`) — grepping only `logerror` misses 19 % of them.
2. **Class A (self-concealing): 23 sites**, of which **7** are the §220 shape (a scalar
   fired-count whose zero is the answer) and 16 are ordinary sparse-table row filters.
3. **Class B (write-only, value reaches no output): 15 of 203**, including the brief's
   `m_src02_n` and four `§133` demux fired-counts.
4. **Class C (mis-scoped / mis-named): 4 confirmed** — `m_dwr`/`m_dwr_nz` (3 sites, 4
   predicates), the two-phase `dp` column, `§49`'s double-counted `m_dr_landed`,
   `m_pk_cram`; 8 further detector hits triaged and cleared.
5. **Class D (unreset pooling): 48 of 48 armed instruments.** Zero exceptions; five
   different arming thresholds coexist (300 k / 400 k / 420 k / 900 k / 970 k).
6. **Class E (truncating): 3** — the trace drops `mem`/`tA`/`tB` behind a stale header,
   `store_probe` caps at 4 with no overflow counter (its two sibling tables both have one),
   `§41` latches one value where a range is needed.
7. **`§70`/`§211`'s instrument is SOUND.** The `min == max == 0` null is not an artefact:
   the census demonstrably ran (726 040 / 313 960 frames printed), its sentinels survive
   `device_reset()`, and both of its real defects bias toward a *non-zero* reading.
8. **Most load-bearing conclusion at risk:** `PREDICT_S1_hi12_bench.md`'s falsifier **F1**
   — the pre-registered *calibration* for the whole `a70` bench — grades on a `D-RAM WRITES`
   **total** that is structurally invariant to store suppression. It cannot fire, so it is
   void by this project's own "a criterion that cannot fail is not a pass" rule.
9. **Runner-up:** `OUTPUT-STAGE-NULL_findings.md` §1's THIRD-DEATH mechanism names cell
   `0xD0`; `iw205` read `0x85` (`0x85 + 0x4B = 0xD0`). The conclusion survives on `§104`'s
   `mem` column; only the cited cell and its `D-RAM WRITES` corroboration are wrong.
10. **No audio claim is made or implied here.** Every finding above is a finding about the
    *apparatus*. Where an instrument turned out to be defective, that changes what a
    measurement can support — it never makes the chip audible, and RULE 19 (report MEAN and
    AC AMPLITUDE separately) remains the gate any future non-zero reading must pass.
