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

★★ THE CONSEQUENCE FOR OPTIMISATION. Because interior decodes never conflict but
tail decodes do, what `_BOUND` holds at an address depends on WHICH WINDOW GOT
THERE FIRST -- that is, on walk order. So persisting the index, decoding the
image up front, or changing WINDOW all change answers, and none of them can be
argued safe: they must be gated on `prove_identical.py`. Fix the truncation
first (drop rows within a max-instruction-length of the window end) and the
index becomes canonical -- and then every one of those becomes safe.

## 5. probe_health: it is not process churn

    bare `python3 -c pass`                     23 ms  (median of 15)
    a full prom_a sweep                       412 subprocess runs

412 x 23 ms = **9.5 s of interpreter startup in a sweep that takes over an
hour** -- about 0.3%. Batching or an in-process API would buy that 0.3%. The
cost is in what the probes DO, and the probes that call `reachability.py` do it
by `importlib`, in-process, with no result cache in the derived trees -- so each
pays a cold walk. `probe_health` builds four trees per image; the `full` and
`stub` trees differ from the committed one by construction, so their fingerprint
CANNOT hit. Fixing the walk fixes probe_health.

## 6. What invalidates the cache, and how often

Over the 142 commits of 2026-08-30: **8 touched `notes/reachability.py`**
(the fingerprint hashes `__file__`, so each invalidates ALL THREE images) and
**48 touched a `.s`** (one image each). That is ~72 cold image-walks in a day,
roughly 2.5 hours of walking.

★ The `.s` invalidations are HONEST -- the answer really did change. The 24 from
tool edits mostly are not: a docstring, a print format or a new CLI flag cannot
change a walk. **Editing this tool to save 0.1% costs the tree a 17-minute
re-walk**, which is its own argument against micro-optimising it.
