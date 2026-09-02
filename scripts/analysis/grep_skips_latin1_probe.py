#!/usr/bin/env python3
r"""WHICH SOURCES WILL A `-I` (--ignore-binary) GREP SILENTLY SKIP?
(lane v10seq, 2026-09-02)

QUESTION ANSWERED
-----------------
`notes/lanes/BRIEF-2026-09-01.md` carries an addendum marked **UNCONFIRMED**:
a lane reported plain `grep` returning zero matches on these latin-1 sources,
and the brief's own falsification test did not reproduce it -- `file(1)` called
the sampled sources ASCII text, and on `hdae5000/hdae5000_data_tables.s` plain
and `-a` counts were identical (13,755).

**Both observations are right. The discriminator is not "has bytes >= 0x80",
it is "does the file decode as UTF-8".**

  * `hdae5000_data_tables.s` HAS high bytes, but they form valid UTF-8, so it
    is searched normally.  The brief's control happened to pick the one kind of
    file the failure cannot affect, which is why it did not reproduce.
  * `v10/maincpu/sequencer/accompaniment_engine.s` holds 11 raw latin-1 bytes
    that are NOT valid UTF-8 (first at offset 23324).  Any grep that treats
    such a file as binary and is passed `-I` skips it and prints NOTHING --
    not a `0`, no diagnostic.  Silence, not a zero.

WHERE IT BITES, AND WHERE IT DOES NOT
  It is not a property of the repository or of GNU grep: invoking /usr/bin/grep
  directly (as this script does) searches every file below.  It is a property
  of the SHELL the search runs in.  In the Claude Code agent shell, `grep` is a
  function that execs **ugrep with -I always on**, and ugrep's binary test is
  UTF-8 decodability -- so an agent running `grep -c '\.byte' *.s` in this
  directory gets 11 of 15 files and silently loses the four largest, including
  the one holding 6,058 of the 11,096 `.byte` operands this lane was sent to
  triage.  Observed, in that shell:

      $ grep -c '\.byte' accompaniment_engine.s      ->   (no output at all)
      $ grep -a -c '\.byte' accompaniment_engine.s   ->   1431

WHAT THIS SCRIPT DOES
  Reports, per file, whether it decodes as UTF-8 -- the property that decides
  the skip -- and cross-checks the `.byte` count via a latin-1 Python read
  against /usr/bin/grep, so the true count is always available regardless of
  which grep the caller has.

PRACTICAL RULE
  Use `grep -a` for anything under `v10/`, `v9/`, `v7/`, `hdae5000/`, and treat
  an empty or zero result from a tree-wide search as an instrument failure
  until cross-checked with a latin-1 Python read.

RUN
    python3 scripts/analysis/grep_skips_latin1_probe.py v10/maincpu/sequencer
"""
import os
import re
import subprocess
import sys

PAT = r"\.byte"


def main():
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    target = sys.argv[1] if len(sys.argv) > 1 else "v10/maincpu/sequencer"
    d = os.path.join(root, target)
    print("%-34s %6s %7s %9s %9s" % ("file", "utf8?", "hi>=80", "true n", "grep n"))
    at_risk = 0
    for fn in sorted(os.listdir(d)):
        if not fn.endswith(".s"):
            continue
        p = os.path.join(d, fn)
        raw = open(p, "rb").read()
        try:
            raw.decode("utf-8")
            ok = "yes"
        except UnicodeDecodeError:
            ok = "NO"
            at_risk += 1
        hi = sum(1 for b in raw if b >= 0x80)
        true_n = sum(1 for line in raw.decode("latin-1").split("\n")
                     if re.search(PAT, line))
        g = subprocess.run(["/usr/bin/grep", "-c", PAT, p],
                           capture_output=True).stdout.decode().strip() or "(silent)"
        print("%-34s %6s %7d %9d %9s" % (fn, ok, hi, true_n, g))
    print("\n%d of the directory's .s files do not decode as UTF-8 and will be"
          % at_risk)
    print("skipped, silently, by any grep invoked with -I (the agent shell's is).")


if __name__ == "__main__":
    main()
