#!/usr/bin/env python3
"""respell_comment_scan.py -- after a respell, does a comment still state the OLD meaning?

QUESTION THIS ANSWERS
  A respell changes the instruction text to say what the CPU does (`djnz xbc` -> `djnz16 bc`,
  `inc 0, r` -> `inc 8, r`, `srl xhl, 0` -> `srl xhl, 16`, `rrc_i_8 l, 3` -> `rrc l, 3`) and
  the byte gate proves the bytes did not move -- but the gate cannot see a comment on the same
  line, or a header a few lines up, that still describes the retired reading ("stack cleanup
  (no-op)" beside an `inc 8, xsp` that pops 8 bytes; "XDE = word count" above a 16-bit DJNZ).
  The wave 3a V1 re-verification rated that class MAJOR.  This scans every line a commit (or the
  uncommitted working tree) respelled, and the comment lines up to --window lines above it, for
  phrases that state the old meaning, per family:

    djnz     a 32-bit register named as the DJNZ counter (`djnz x..`, `XBC ... count/dec/loop`)
    incdec   inc/dec by 0 or 1, "no-op", "1 byte", "+0"
    shift    a shift or rotate count of 0 (`SLA 0,`, `by 0`, `<< 0`, `0 bits`), "no-op"
    rotate   the retired raw pseudo (`rrc_i_8`) or a "does not round-trip" note that the new
             decoder made untrue

  Hits are CANDIDATES for a human or a reviewer to judge -- the patterns are deliberately
  loose -- not findings.

USAGE
  python3 scripts/analysis/respell_comment_scan.py [REV ...] [--worktree] [--window N]
  REV: a commit whose diff is scanned (e.g. 83a3b70d).  --worktree: scan `git diff HEAD`.
  Reads files as latin-1 bytes (CLAUDE.md: never decode the .s files as UTF-8).
  Adapted from the wave 3a V1 re-verifier's probe of the same name.
"""
import argparse
import collections
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."

PAT = {
    "djnz": re.compile(r'\bx(bc|de|wa|hl|ix|iy|iz)\b.*\b(dec|count|loop|--|zero)|'
                       r'\b(dec|count|loop|--)\b.*\bx(bc|de|wa|hl|ix|iy|iz)\b|djnz\s+x', re.I),
    "incdec": re.compile(r'no-?op|nothing|\bby (0|1|one)\b|\b1 byte|\bone byte|\+\s*0\b|-\s*0\b|'
                         r'\b0 bytes|\b(inc|dec)\s+0\s*,', re.I),
    "shift": re.compile(r'\b(sla|sll|sra|srl|rlc|rrc|rl|rr)\s+0(x0+)?\s*,|\bby 0\b|<<\s*0\b|'
                        r'>>\s*0\b|\b0 bits?\b|no-?op|shift (count|amount) (of )?0\b', re.I),
    "rotate": re.compile(r'_i_(8|16|32)\b|does not round-?trip|raw (count|field)', re.I),
}


def kind_of(code):
    c = code.strip().lower()
    if c.startswith("djnz"):
        return "djnz"
    if re.match(r'(inc|dec)[bw]?\s+8\s*,', c):
        return "incdec"
    if re.match(r'(sla|sll|sra|srl)\s+[^,]+,\s*16\b', c):
        return "shift"
    if re.match(r'(rlc|rrc|rl|rr)\s+[^,]+,\s*\d+', c):
        return "rotate"
    return None


def sites_from_diff(text):
    out, f = [], None
    for l in text.splitlines():
        if l.startswith("+++ b/"):
            f = l[6:]
        m = re.match(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@', l)
        if m and f and f.endswith((".s", ".inc", ".S")):
            start, cnt = int(m.group(1)), int(m.group(2) or 1)
            out += [(f, start + k) for k in range(cnt)]
    return out


def main():
    ap = argparse.ArgumentParser(description="stale-comment scan for respelled lines")
    ap.add_argument("revs", nargs="*")
    ap.add_argument("--worktree", action="store_true")
    ap.add_argument("--window", type=int, default=6)
    a = ap.parse_args()
    diffs = []
    for r in a.revs:
        diffs.append(subprocess.run(["git", "show", "--unified=0", "--format=", r], cwd=REPO,
                                    capture_output=True).stdout.decode("latin-1"))
    if a.worktree:
        diffs.append(subprocess.run(["git", "diff", "--unified=0", "HEAD"], cwd=REPO,
                                    capture_output=True).stdout.decode("latin-1"))
    sites = sorted(set(s for d in diffs for s in sites_from_diff(d)))
    cache, hits, rows, seen = {}, collections.Counter(), [], set()
    nsites = collections.Counter()
    for f, n in sites:
        if f not in cache:
            try:
                cache[f] = open(f"{REPO}/{f}", "rb").read().decode("latin-1").split("\n")
            except FileNotFoundError:
                cache[f] = []
        L = cache[f]
        if n - 1 >= len(L):
            continue
        kind = kind_of(L[n - 1].split(";")[0])
        if not kind:
            continue
        nsites[kind] += 1
        for k in range(max(0, n - 1 - a.window), n):
            line = L[k]
            if ";" not in line or (f, k) in seen:
                continue
            if PAT[kind].search(line.split(";", 1)[1]):
                seen.add((f, k))
                hits[kind] += 1
                rows.append("%s:%d [%s] (site line %d) | %s" % (f, k + 1, kind, n, line.strip()[:160]))
    print("respelled lines scanned per family: %s" % dict(nsites))
    print("comment candidates per family: %s" % dict(hits))
    print("\n".join(rows))
    return 0


if __name__ == "__main__":
    sys.exit(main())
