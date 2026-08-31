# `notes/perf/` — where the time actually goes

Felipe asked whether the Python here is too slow, and whether Rust would help.
These are the instruments that answer it. **Every timing quoted in the commit
messages or in the notes came out of one of them**, and each says, below, what
question it answers and the exact command.

⚠ **Timings are data, never assertions.** Each script has a `--selftest`, and
every check in it is an INVARIANT — "the meter does not change the answer",
"the comparator can detect a difference" — never a pinned number. A machine
under load gives a different second and the same answer.

⚠ **Check for other lanes before trusting a figure.** This tree is worked by
several at once and they run these same tools:

    ps -eo pid,etimes,args | grep -E 'reachability|probe_health'

---

## `profile_reachability.py` — is it the walk, or the subprocess?

**Question:** of the wall time of one *cold* `notes/reachability.py` run, how
much is the `unidasm` subprocess, how much is parsing its output, how much is
re-reading the `.s` sources, and how much is the walk's own inner loop?

It imports `reachability.py` as a module (so the phases are separable), wraps
`subprocess.run` to count and time every `unidasm` spawn, and **bypasses the
result cache on purpose** — a cold walk is the thing being measured.

    python3 notes/perf/profile_reachability.py --all           # ★ the headline
    python3 notes/perf/profile_reachability.py --tag prom_a
    python3 notes/perf/profile_reachability.py --tag prom_a --cprofile
    python3 notes/perf/profile_reachability.py --selftest

`--cprofile` inflates the Python side (it instruments 600M+ calls) and leaves
the subprocess side alone, so read it for *which function*, and read `--all`
for *how many seconds*.

## `profile_probe_health.py` — churn, or a few heavy probes?

**Question:** a full `probe_health.py` sweep is 400+ subprocess runs and over
half an hour. Is that PROCESS STARTUP — in which case batching or an in-process
API is the fix — or a handful of probes that each do minutes of real work, in
which case batching buys nothing?

Uses probe_health's own discovery, so the invocation list is exactly a real
sweep's, then times each invocation once in the committed tree. It also measures
the bare interpreter floor (`python3 -c pass`), so "startup cost" is a number
rather than an intuition. **Write-mode invocations are never run** — the
`WRITE_FLAGS` list is honoured, and `--selftest` asserts that.

    python3 notes/perf/profile_probe_health.py --image prom_d
    python3 notes/perf/profile_probe_health.py --image prom_a
    python3 notes/perf/profile_probe_health.py --selftest

## `prove_identical.py` — ★ the gate on any change in here

**Question:** the tool got faster; does it still say the same thing?

A faster tool that answers differently is a regression, not an optimisation.
This project is certified by the byte gate and the probe corpus, and the
reachability work list decides which bytes a lane converts next — so the gate on
a performance change is EXACT TEXTUAL IDENTITY of every reporting mode
(`--targets`, `--spans`, `--seeds`, the bare report, `--selftest`), each from a
**cold** start. Warm runs prove nothing: they never execute the changed code.

    python3 notes/perf/prove_identical.py --record    # BEFORE the change
    python3 notes/perf/prove_identical.py            # AFTER it
    python3 notes/perf/prove_identical.py --selftest

⚠ `--record` after a change makes the change its own witness. Record first.
The recorded baseline lives in `notes/perf/baseline/` and is committed, so the
answers this tree gave on a given day are reviewable rather than remembered.

---

## What the signal being read actually is

* **`unidasm` spawn count and seconds** — `subprocess.run` entries and exits in
  `reachability._decode_window`. One spawn = one `fork`+`exec` of a 12.5 MB MAME
  binary plus a temp file written and unlinked.
* **boundary index size** — `len(reachability._BOUND[tag])` after a cold walk:
  how many distinct instruction addresses the walk settled. It decides whether
  the decode can be persisted between runs.
* **interpreter floor** — median of 15 `python3 -c pass` runs.
* **identity** — byte equality of stdout+stderr and of the exit code.

---

# What these measured, 2026-08-31

Machine: 8 cores, Python 3.13.5, `unidasm` from `~/compartilhado/kn7000_mame_build`.
Reproduce with the commands above. Timings will differ; the ratios should not.

⚠⚠ SECTIONS 1-6 BELOW ARE THE DIAGNOSIS, AND THEY MEASURE THE TOOL AS IT WAS
   BEFORE P1/P2/P3 LANDED ON THE SAME DAY. They are left as measured -- they are
   what the fixes were chosen from -- but they are no longer what the tool does.
   What it does now is section 0, and every figure there is from the same
   instruments.

## 0. AFTER P1 + P2 + P3 -- the same answers, 30x to 54x less time

    python3 notes/perf/prove_identical.py           # answers: 5 modes, 0 differ
    python3 notes/perf/profile_reachability.py --all               # fresh index
    python3 notes/perf/profile_reachability.py --all --warm-decode

    one --targets run           before        after   unidasm spawns
    ---------------------------------------------------------------
    warm (result cache hits)     0.23 s      0.23 s        0        unchanged
    result cache MISSES,
      decode index persisted   1,020 s      20.3 s        0        the lane's case
    nothing cached at all      1,020 s      34.4 s      876        84,190 before

    per image, decode index persisted:  prom_a 9.98 s, prom_b 4.93 s, prom_c 2.81 s
    per image, fresh index:             prom_a 12.54 s (184 spawns),
                                        prom_b 12.40 s (620), prom_c 4.19 s (72)

★ THE 84,190 SPAWNS ARE 876, and 0 once the index is on disk. What is left is
  `_decode_window` bookkeeping -- 276,757 calls building row lists out of the
  index, 12.0 s of the 17.7 s. That is now the hot spot, and it is Python, not
  `fork`+`exec`; it was 16.1% of the problem before and it is 68% of a much
  smaller one.

★ AND THE ANSWERS DID NOT MOVE. Every one of those runs was gated on
  `prove_identical.py` against the post-guard baseline, cold: --targets, --spans,
  --seeds, the report and --selftest, byte for byte.

## 1. The tool is not slow. A CACHE MISS is slow.

    warm  `--targets`, all three images cached   0.23 s   (three runs, byte-identical output)
    cold  `--targets`, no cache hit          1,019.19 s   (17.0 minutes)

A 4,400x spread. Any statement about this tool's speed that does not say which
of the two it is describing is not about anything.

## 2. Where the 1,019 s goes

    phase                          calls      seconds   % wall
    unidasm subprocess            84,190       846.97    83.1%
    _decode_window minus that    295,340       164.63    16.1%
      (parsing unidasm's stdout with the LINE regex -- ~700 lines
       per spawn, 59M matches -- plus the boundary-index walk)
    walk() inner loop            530,164         4.56      0.4%
    seeds()                            3         1.45      0.1%
    source_lines() + includes         21         1.14      0.1%
    _fingerprint()                     3         0.173     0.017%

    per image:  prom_a 621.72 s / 53,872 spawns   prom_b 210.44 s / 17,111
                prom_c 187.03 s / 13,207

★ The fingerprint is 0.017% of a cold run. The theory that re-reading and
  SHA1-ing 26 included sources per image costs real time is DISPROVEN -- it
  costs 173 milliseconds.

★ The walk's inner loop -- the part a faster language would speed up -- is
  0.4%. **Making the Python infinitely fast would save 16.5% of the run.**

## 3. Why a spawn costs what it costs

    unidasm with no file at all (exec + dynamic link of a 12.5 MB binary)   6.92 ms
    unidasm decoding a 2,048-byte window (WINDOW)                           9.64 ms
    unidasm decoding the WHOLE 512 KiB image                            1,073.65 ms

So **72% of every spawn is process startup**, and 84,190 spawns spend ~582 s --
**57% of the entire cold run** -- in `fork`+`exec` alone.

★ And the whole image decodes linearly in 1.07 s. The walk spends 847 s doing,
  2,048 bytes at a time, work that costs 3.2 s for all three images at once:
  it decodes 110 MB to settle 219,086 boundaries in prom_a, ~265x redundant.
  That is the algorithmic finding. It is not a language problem.

## 4. ⚠ The window has a TRUNCATION DEFECT, and it makes the tool ORDER-DEPENDENT

`decode_conflicts.py --tag prom_a --starts 300`:

    distinct addresses asserted   261,324
    INTERIOR conflicts                  0
    window-TAIL conflicts              52   (17% of windows)
    ... adjudicated wrong               52
    ... injecting a FALSE in-image branch edge   6

An instruction that straddles the end of a 2 KiB window is decoded from
TRUNCATED bytes. unidasm emits a shorter instruction that fits, and
`_BOUND[tag][addr] = (length, text)` stores it, last write wins:

    0xFA9794  truth 'jr NC,0xfa980e'   (3 bytes)
              got   'jr NC,0xfa9796'   (2 bytes)  => FALSE EDGE to 0xFA9796

So a truncated decode hands `walk()` the wrong LENGTH (it then resumes at the
wrong offset) and the wrong BRANCH TARGET (it queues an edge no control flow
takes). This is the "paints data as code" failure the tool's own docstring is
about, arriving through the decoder rather than through a seed.

**THE FIX, AND IT IS MEASURED, NOT PROPOSED BLIND.** One linear decode of the
whole prom_a image is 274,588 instructions and the longest is **7 bytes**
(1-byte 54.8%, 2-byte 19.0%, ... 7-byte 0.15%). So dropping rows that start
within 6 bytes of the window end must remove every truncated decode, and it
does -- `--guard 6` on all three images:

    image    guard 0: interior / tail conflicts / false edges | guard 6
    prom_a         0 / 52 / 6                                 | 0 / 0
    prom_b         0 / 17 / 0                                 | 0 / 0
    prom_c         0 / 15 / 3                                 | 0 / 0

It costs 6 bytes of every 2,048 -- ~0.2% of the addresses a window asserts.

★★ IT WAS IN THE TOOL'S OUTPUT. **THE GUARD IS NOW LANDED** (2026-08-31, with
Felipe's decision, as a correctness fix). It was first A/B'd cold against the
then-recorded baseline (`notes/perf/GUARD-AB-2026-08-31.txt`), and four of five
modes DIFFER:

    TOTAL reachable-and-unconverted
        as committed   STRONG 17 bytes, ANY 1,670, in 17 spans
        with guard     STRONG 17 bytes, ANY 1,702, in 17 spans

    and one span leaves the work list:
        -prom_a  0xFC3000-0xFC5400  9,216 bytes, 1 reachable
        +prom_a  0xF96259-0xF96418    447 bytes, 1 reachable

A 9,216-byte span was on the work list because ONE byte in it was reachable, and
that byte was reachable only through an edge a truncated decode invented.

★ The **STRONG** column is unchanged at 17 bytes, and `--selftest` is identical,
so no conversion decision made to date is affected -- STRONG is the column the
tool tells lanes to convert on. What moves is the weak `any` figure. The guard
costs nothing in time (1,083.70 s vs 1,079.85 s cold).

⚠ It is a CORRECTNESS change, not an optimisation. It moved a published figure,
so it took Felipe's decision, a re-recorded baseline (`notes/perf/baseline/`, now
the GUARDED answers; the pre-guard ones are frozen in
`notes/perf/baseline-preguard-2026-08-31/`) and, before either, an accounting of
EVERY BYTE IT MOVED:

    notes/perf/guard_accounting.py --side pre|post --out DIR ; --explain DIR
    notes/perf/GUARD-ACCOUNTING-2026-08-31.txt

★★ AND IT WAS BLOCKING THE PERFORMANCE WORK, which is the other reason it had to
be settled first. While the tail was in, what `_BOUND` held at an address
depended on WHICH WINDOW GOT THERE FIRST -- on walk order -- so persisting the
index, decoding the image up front, or changing WINDOW all changed answers and
none could be argued safe. With the guard the entry at an address IS
decode(address), and P2/P3 below become provable rather than plausible.

## 5. probe_health: it is not process churn, it is 52 guaranteed timeouts

`profile_probe_health.py --census` (static, so load does not affect it):

    image    scripts  invocations  runs (x4 trees)  of those, WALKERS
    prom_a     103        188           752          12 inv -> 48 runs
    prom_b      89        169           676          10 inv -> 40 runs
    prom_c      73        135           540           4 inv -> 16 runs
    prom_d      28         51           204           0 inv ->  0 runs
    TOTAL                 543         2,172          26 inv -> 104 runs

    bare `python3 -c pass`                     23 ms  (median of 15)

2,172 x 23 ms = **50 s of interpreter startup in a sweep that takes over half an
hour** -- under 3%, and for one image's regrade it is the 9.5 s that 412 runs
cost. **Batching or an in-process API would buy that.** It is not where the time
is.

★ WHERE IT IS. 26 invocations load `reachability.py` by `importlib` and walk.
Each runs in four trees. `asis` and `asis2` have the committed `.s`, so the
copied result cache HITS and they are quick. `full` and `stub` differ from the
committed tree BY CONSTRUCTION -- that difference is the measurement -- so their
fingerprint CANNOT hit and they walk COLD:

    52 runs x 300 s per-invocation timeout = 4.3 hours of CPU,
    at --jobs 8 => ~32 minutes of wall clock.

That is the whole observed regrade time, and it is **spent burning the timeout**:
a cold prom_a walk is 621.72 s and the timeout is 300 s, so those runs can never
finish. They are graded TIMEOUT -- which probe_health's own docstring calls "NOT
a pass: the instrument never saw an answer". So the sweep is not merely slow; it
returns no grade for precisely the probes that do the most work.

★ Fixing the walk fixes probe_health. Nothing else here needs to change.

★★ AND IT DID -- MEASURED, 2026-08-31, after P2/P3:
   `notes/reachability.py --targets` TIMEOUT -> UNAFFECTED, and
   `notes/gen_prom_b_cover_round2.py --closure` TIMEOUT -> SPLIT-FRAGILE
   (8 runs in 65 s where it had been 4 x 300 s of timeout).
   Both rows now have an ANSWER. See notes/perf/PROBE-HEALTH-AFTER-P2-2026-08-31.txt,
   which also says which of the other regraded rows are NOT this work's doing.

## 6. What invalidates the cache, and how often

Over the 142 commits of 2026-08-30: **8 touched `notes/reachability.py`**
(the fingerprint hashes `__file__`, so each invalidates ALL THREE images) and
**48 touched a `.s`** (one image each). That is ~72 cold image-walks in a day,
roughly 2.5 hours of walking.

★ The `.s` invalidations are HONEST -- the answer really did change. The 24 from
tool edits mostly are not: a docstring, a print format or a new CLI flag cannot
change a walk. **Editing this tool to save 0.1% costs the tree a 17-minute
re-walk**, which is its own argument against micro-optimising it.

---

# What to do about it

Ordered by return. The first two are the whole problem; the rest are small.

## P1 — the window-tail guard   ★ **LANDED 2026-08-31**

Section 4, `GUARD-AB-2026-08-31.txt` and `GUARD-ACCOUNTING-2026-08-31.txt`. Three
lines in `_decode_window`: it takes `any` from 1,670 to 1,702 and drops a
9,216-byte span off the work list, because one byte in it was reachable only
through an edge a truncated decode invented. STRONG stays 17 and `--selftest` is
unchanged, so no conversion decision to date is affected. Every one of the 231
bytes it moved across the three images -- 205 gained, 26 lost, in 68 runs -- is
attributed to a specific truncated window tail in the accounting, and none is
left unexplained. It was also the PRECONDITION for P2 and P3.

## P2 — persist the decode index between runs   ★ **LANDED 2026-08-31**

    cold, no caches at all                     979.93 s   answers IDENTICAL
    result cache cleared, decode index KEPT     19.01 s   answers IDENTICAL
                                                          (54x; this is the case
                                                           a lane hits after
                                                           editing a .s)

`notes/.reachability-decode.txt`, keyed on the ROM's SHA1, unidasm's SHA1,
WINDOW and MAXLEN. Loaded lazily on a result-cache MISS, so the warm path stays
0.2 s.
Proved with `prove_identical.py` from cold, 5 modes, 0 differ.

The original proposal follows.



`_decode_window` asks unidasm what the ROM BYTES decode to. **The ROM bytes never
change** — the byte gate freezes them — so the 847 s of decoding is invariant to
the very thing that invalidates the result cache: an edited `.s`. A lane converts
a span, the result cache correctly misses, and the tool re-derives from scratch
a decode that could not possibly have changed.

Key it on the ROM hash and unidasm's own hash, load it lazily (only on a result-
cache miss, so the 0.23 s warm path stays 0.23 s), and store the boundary index
plus, per spawned start, its row count. ~219k entries for prom_a, ~8 MB an image;
gitignore it beside `.reachability-cache.json`.

⚠ It must be gated on `prove_identical.py`, not argued — even with the guard, the
index-vs-spawn decision order changes. Place the lookup exactly where the spawn
would happen and the substitution is byte-for-byte what the spawn returned.

**This also fixes probe_health**: the derived trees have different `.s` but the
SAME ROMs, so the decode cache is valid there and the 52 guaranteed timeouts stop.

## P3 — seed the index with one linear decode per image   ★ **LANDED 2026-08-31**

    nothing cached at all      979.93 s -> 34.43 s,  84,190 spawns -> 876
    (the fraction the question was about: 99.0% of the spawn starts ARE
     boundaries of the canonical decode, so 99.0% of the spawns disappear)

`_predecode()` runs one unidasm over the whole 512 KiB image (~1.1 s) when the
persisted index is absent, and pours it into `_BOUND`. A walk that starts
BETWEEN two canonical boundaries -- which weak seeds do -- still spawns, and
those rows are canonical too. Proved with `prove_identical.py` from cold.

## P4 — a cache key that does not punish editing the tool   ⚠ **NOT WORTH IT NOW**

The premise was that a docstring edit costs the tree a 17-minute re-walk. After
P2/P3 it costs **20 seconds**: the edit invalidates the RESULT cache, as it
should, but not the decode index, which is keyed on the ROM and the decoder and
cannot be affected by a comment. So the saving is ~20 s per tool edit, against
the risk the proposal itself names -- a key too narrow serves a STALE answer,
which is the failure the fingerprint docstring exists to prevent. Recommend
leaving the key hashing the whole file.

The original proposal follows.


The fingerprint hashes `__file__`, so a docstring, a print format or a new flag
invalidates all three images and costs a 17-minute re-walk. 8 of 2026-08-30's 142
commits touched this file: ~24 image-walks, most of them for edits that cannot
change a walk. Hash the walk-determining code rather than the whole file, or a
hand-bumped `WALK_VERSION`. ⚠ Too narrow a key serves a STALE answer, which is
the failure the fingerprint docstring is already about — so this one needs care,
not speed.

## P5 — `--evidence` is O(runs x proven) and deletes a shared file   ★ **LANDED 2026-08-31**

    --evidence, decode index warm      29.15 s -> 19.50 s, output byte-identical
    result cache after --evidence      DELETED -> same inode, survives

`fallthrough_index()` answers "does a proven instruction end exactly here" from
one dict instead of a scan per run, and `FORCE_WALK` gets the re-walk that the
`os.unlink()` of every lane's result cache used to. Both proved on the real tree
by `notes/perf/evidence_equiv.py`, which keeps the OLD scan as an oracle: 44
graded runs, 0 disagreements.

The original proposal follows.


`start_evidence()` scans the WHOLE proven set per reachable run — 257,759 proven
addresses across the tree — calling `_decode_window` for each. Build the
fall-through index once (`{a + len(a): a}`) instead. Separately, `--evidence`
`os.unlink`s `notes/.reachability-cache.json`, which is every lane's cache, to
get an in-memory effect; a module flag does the same thing without the collateral.

## P6 — walk the three images in parallel   ⚠ **NOT WORTH IT NOW**

Bounded by prom_a: with the decode index that is 9.98 s of a 17.7 s run, so the
ceiling is ~8 s saved, for three processes racing two read-modify-write JSON/text
caches. The README below already called it moot if P2 landed. It did.

The original proposal follows.


They are independent. A cold full run is bounded by prom_a (621.72 s) instead of
their sum (1,019.19 s), ~40%. ⚠ `_cache_store` is read-modify-write on one JSON
file; three writers race. Moot if P2 lands.

## P7 — the NEW hot spot: `_decode_window`'s chain builder   ★ MEASURED, NOT LANDED

    _decode_window   276,757 calls   12.0 s of a 17.7 s run   0 subprocesses

With the index in memory the cost is no longer `fork`+`exec`, it is building a
row list per call: the index path walks the chain from `start` up to **512
rows**, and `walk()` then consumes rows only until the first FLOW_END -- usually
a handful. Stopping the chain at the first FLOW_END row would cut nearly all of
those 141M iterations.

⚠ It LOOKS answer-identical (every current caller either consumes rows up to a
FLOW_END or reads `rows[0]`), but "looks" is not the gate here: it would need
`prove_identical.py` cold, and a note in `_decode_window` saying that a caller
which reads past a FLOW_END would silently get a short list. Not landed, because
the run is already 20 s and the invariant is subtle enough to deserve its own
pass.

## NOT Rust, and not PyPy

    unidasm subprocess        847 s   83.1%   a Rust caller pays the same fork+exec
    everything in Python      169 s   16.6%   the ceiling for ANY language change
    walk() inner loop         4.6 s    0.4%   the part people picture rewriting

Rewriting every line of Python in Rust and making it take zero time turns 1,019 s
into 850 s — **1.2x**. P2 and P3 attacked the 83% and were worth 30-54x. Rust
makes a bad algorithm fast; it does not make it good, and that algorithm decoded
110 MB to settle 219,086 boundaries.

★ AND THE ARGUMENT ONLY GOT STRONGER. The run those percentages describe is now
20 s, of which 0 s is `unidasm` once the index exists. What is left is ~17 s of
Python, and P7 above removes most of it in a dozen lines.

The honest costs, if it were ever proposed again:

* **unidasm is the decode authority.** The only Rust worth writing here is a
  TLCS-900 decoder, and that replaces the authority this project is certified
  against. Every boundary would need re-certifying.
* **It could not reproduce the answers of the day even in principle.** Section 4
  shows the output BEFORE the guard depended on a truncation artifact, so
  "byte-identical to the Python" would have meant reimplementing the bug.
* A build toolchain for every contributor and every lane, in a 321-file /
  158,677-line Python tree, and `probe_health` copies the tree four times per
  image and runs probes inside the copies.
* PyPy would address the same 16.6%, is not installed, and would have to be for
  every lane. After P2 there is nothing left for it to speed up.
* Python 3.13.5 is current; a newer one changes nothing material here.
