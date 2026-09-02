#!/usr/bin/env python3
"""blind_run_decode_census.py -- how much of an image's `.byte` residue does the
decoder now READ, and is "it decodes" worth anything on this architecture?

QUESTION THIS ANSWERS
----------------------
`byte_run_start_enrichment.py` found that v10's leftover `.byte` runs start with
one of five undecodable leading bytes 19.2% of the time against 0.4% for
decodable bytes of similar magnitude, and read that as "much of this residue is
CODE the decoder could not read".  Those five bytes -- 0x01 normal, 0x04 max,
0x17 ldf, 0x1a jp nnnn, 0x1c call nnnn -- were then taught to the decoder.

The obvious follow-up, "re-run the enrichment census and see it drop", DOES NOT
WORK, and it is worth being explicit about why: that script measures the SOURCE
AS IT STANDS.  Teaching the decoder converts nothing.  The `.byte` runs stay
`.byte` until a conversion pass rewrites them, so the ratio cannot move and a
moved ratio would mean somebody had converted something, not that the decoder
improved.

This script measures the thing that actually changed: given the run's bytes,
HOW FAR DOES THE DECODER GET NOW?

⚠ AND THE ANSWER IS NEARLY MEANINGLESS WITHOUT A NULL.  The TLCS-900 opcode
space is dense -- almost every byte is a valid leading byte -- so "these bytes
disassemble" is close to free.  Two nulls are therefore scored alongside every
real run and printed in the same table:

  shuffled  the SAME BYTES in a seeded random permutation.  Preserves the byte
            frequency of the run exactly and destroys any instruction
            structure.  If real runs decode no better than their own shuffles,
            the runs carry no instruction structure the decoder can see.
  random    uniform random bytes of the same length.  The architecture's raw
            base rate.

A real-vs-shuffled gap is the only part of the "it decodes" number that is
evidence.  Report all three or none.

⚠ AND THE ENRICHMENT RATIO ITSELF HAS A STRUCTURAL CONFOUND, FOUND WHILE
WRITING THIS.  Where a region was converted by a LINEAR FORCE-DISASSEMBLY pass,
a `.byte` run begins at exactly the byte the decoder refused -- so a decodable
control byte can almost never START a run, because it gets consumed into the
surrounding instruction stream instead.  The blind/control comparison is then
close to tautological for such regions, whatever the region really is.  The
per-byte breakdown below is the diagnostic: 0x01 and 0x04 are extremely common
DATA values, and if they dominate the blind count the enrichment is mostly
telling you how often those two values occur, not that the region is code.

WHAT "CLEAN PREFIX" MEANS
--------------------------
The run's bytes are handed to `llvm-mc -disassemble -show-encoding`, which
prints the exact byte span it consumed for each instruction.  The clean prefix
is the number of leading bytes covered by decoded instructions before the first
refusal.  A run with no refusal at all is FULLY CLEAN.  No padding is added, so
a run whose last instruction would overrun the end counts that tail as a
refusal -- deliberately: the run's bytes are all the evidence there is.

RESULT 2026-09-02, v10/maincpu, across tlcs900_backend@6f456a19f05b
(regenerate before quoting; other lanes are converting)

                     runs   bytes   clean prefix   fully clean
    BEFORE  real     3395    8503        0 (0.0%)     0 ( 0.0%)
            shuffled 3395    8503      655 (7.7%)    15 ( 0.4%)
    AFTER   real     3395    8503     6687(78.6%)  2810 (82.8%)
            shuffled 3395    8503     5835(68.6%)  2788 (82.1%)
            random   3395    8503     2489(29.3%)   821 (24.2%)

★ THE FIX IS REAL -- 0 B decoded to 6,687 B -- AND THE CODE HYPOTHESIS IS NOT.
Real and shuffled are 82.8% vs 82.1%: the runs carry no instruction structure
beyond their byte frequency. The mean run is 2.5 B, so most of that mass is
1-3 byte fragments where a shuffle is barely a null; in the 96 runs of >= 12 B
a gap does open (38.5% vs 17.7% fully clean), but inspecting the longest of
those shows the structure is DATA regularity -- `04 00 00 00 08 00 00 00 10 00
00 00 ...` power-of-two masks, 4-byte pointer tables, index ramps.

⚠ THE `BEFORE` COLUMN NEEDS A BASELINE BINARY. Build one by checking out
tlcs900_backend@58fb7f2afaed's TLCS900Disassembler.cpp, `ninja llvm-mc`, copying
the binary aside, then restoring -- and point LLVM_MC at the copy. Do not
approximate it by filtering the five bytes out in Python: the old decoder SKIPS
a refused byte and resumes, so the byte spans differ and a simulation would
quietly report the wrong clean-prefix.

RUN
    python3 scripts/analysis/blind_run_decode_census.py [root ...]
    default root: v10/maincpu
    env: LLVM_MC (default <PROJECTS_ROOT>/llvm-project/build/bin/llvm-mc)
         BLIND_CENSUS_JOBS (default 6)
"""
import collections
import io
import os
import random
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

LLVM_MC = os.environ.get("LLVM_MC") or os.path.expanduser(
    "~/compartilhado/llvm-project/build/bin/llvm-mc")
JOBS = int(os.environ.get("BLIND_CENSUS_JOBS", "6"))

BLIND = {0x01: "normal", 0x04: "max", 0x17: "ldf",
         0x1a: "jp nnnn", 0x1c: "call nnnn"}
BYTE_RE = re.compile(r"^\s*\.byte\s+(.*)$")
ENC_RE = re.compile(r"encoding:\s*\[([^\]]*)\]")


def collect_runs(root):
    """Maximal `.byte` runs, as (path, line, bytes, what-precedes)."""
    runs = []
    for dirpath, _, files in os.walk(root):
        for fn in sorted(files):
            if not fn.endswith(".s"):
                continue
            path = os.path.join(dirpath, fn)
            lines = io.open(path, encoding="latin-1").read().split("\n")
            cur, start, prev = None, None, "none"
            last_nonbyte = "none"
            for i, line in enumerate(lines):
                st = line.strip()
                if not st or st.startswith(";"):
                    continue
                m = BYTE_RE.match(line)
                if m:
                    vals = []
                    for tok in m.group(1).split(";")[0].split(","):
                        tok = tok.strip()
                        if not tok:
                            continue
                        try:
                            vals.append(int(tok, 0) & 0xFF)
                        except ValueError:
                            vals = None
                            break
                    if vals is None:
                        if cur:
                            runs.append((path, start, bytes(cur), prev))
                        cur = None
                        continue
                    if cur is None:
                        cur, start, prev = [], i + 1, last_nonbyte
                    cur.extend(vals)
                else:
                    if cur:
                        runs.append((path, start, bytes(cur), prev))
                        cur = None
                    last_nonbyte = ("label" if st.endswith(":")
                                    else "directive" if st.startswith(".")
                                    else "insn")
            if cur:
                runs.append((path, start, bytes(cur), prev))
    return runs


def clean_prefix(raw):
    """(bytes decoded before the first refusal, fully_clean)."""
    if not raw:
        return 0, False
    text = ",".join("0x%02x" % b for b in raw)
    p = subprocess.run([LLVM_MC, "-triple=tlcs900", "-disassemble",
                        "-show-encoding"],
                       input=text, capture_output=True, text=True)
    # Diagnostics carry the column of the refused byte; every byte is formatted
    # identically as "0xAB," so column -> byte index is exact.
    first_bad = None
    for m in re.finditer(r"<stdin>:1:(\d+):", p.stderr):
        idx = (int(m.group(1)) - 1) // 5
        first_bad = idx if first_bad is None else min(first_bad, idx)
    consumed = 0
    for m in ENC_RE.finditer(p.stdout):
        n = len([t for t in m.group(1).split(",") if t.strip()])
        if first_bad is not None and consumed + n > first_bad:
            break
        consumed += n
    if first_bad is None:
        return len(raw), True
    return min(consumed, first_bad), False


def score(group):
    with ThreadPoolExecutor(max_workers=JOBS) as ex:
        return list(ex.map(clean_prefix, group))


def summarise(name, raws, results):
    tot = sum(len(r) for r in raws)
    pref = sum(c for c, _ in results)
    full = sum(1 for _, f in results if f)
    print("    %-9s %5d runs  %7d B  clean prefix %7d B (%5.1f%%)  "
          "fully clean %4d (%5.1f%%)"
          % (name, len(raws), tot, pref, 100.0 * pref / tot if tot else 0,
             full, 100.0 * full / len(raws) if raws else 0))


def main():
    roots = sys.argv[1:] or ["v10/maincpu"]
    rng = random.Random(20260902)
    for root in roots:
        if not os.path.isdir(root):
            print("  %s (missing)" % root)
            continue
        runs = collect_runs(root)
        blind = [r for r in runs if r[2] and r[2][0] in BLIND]
        print("=== %s   %d `.byte` runs, %d start with a formerly-blind byte"
              % (root, len(runs), len(blind)))

        per = collections.Counter(r[2][0] for r in blind)
        print("    run-start breakdown (the enrichment confound check):")
        for b in sorted(BLIND):
            print("        0x%02x %-10s %5d runs (%4.1f%% of blind starts)"
                  % (b, BLIND[b], per[b],
                     100.0 * per[b] / len(blind) if blind else 0))
        ctx = collections.Counter(r[3] for r in blind)
        print("    preceded by: " +
              ", ".join("%s %d" % (k, v) for k, v in ctx.most_common()))

        raws = [r[2] for r in blind]
        shuf = []
        for r in raws:
            b = list(r)
            rng.shuffle(b)
            shuf.append(bytes(b))
        rnd = [bytes(rng.randrange(256) for _ in r) for r in raws]

        print("    decode census (LLVM_MC=%s):" % LLVM_MC)
        summarise("real", raws, score(raws))
        summarise("shuffled", shuf, score(shuf))
        summarise("random", rnd, score(rnd))

        # ⚠ LENGTH STRATIFICATION IS NOT OPTIONAL. These runs are TINY -- a
        # force-disassembly pass refuses one byte and resumes -- so the mean run
        # is a couple of bytes and a SHUFFLE OF A 2-BYTE RUN IS BARELY A NULL.
        # On the short bucket real and shuffled must agree; if they did not, the
        # instrument would be broken. Only the long bucket can carry a signal.
        for lo in (6, 12):
            idx = [i for i, r in enumerate(raws) if len(r) >= lo]
            if not idx:
                continue
            print("      runs >= %d bytes:" % lo)
            summarise("real", [raws[i] for i in idx],
                      score([raws[i] for i in idx]))
            summarise("shuffled", [shuf[i] for i in idx],
                      score([shuf[i] for i in idx]))
            summarise("random", [rnd[i] for i in idx],
                      score([rnd[i] for i in idx]))
        print()
    print("⚠ Read `real` only against `shuffled` and `random`. On a dense "
          "opcode space a high clean-decode rate is the architecture's base "
          "rate, not evidence that the bytes are code.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
