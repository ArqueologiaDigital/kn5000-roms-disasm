#!/usr/bin/env python3
"""check_retired_label_mentions.py -- does any [nakarest] header, or other comment, still cite a label retired since BASE?

QUESTION THIS ANSWERS
  Retiring a label (scripts/tools/name_naka_view_ids.py, fix_presentation_region.py ...) leaves
  generated headers that listed it as a reader or an object stale.  For each maincpu tree: the
  column-0 labels defined at BASE but not in the working tree are "retired"; this counts the
  `; [nakarest]` blocks and the other comment lines that still name one.  Exit 1 if a [nakarest]
  block does.

USAGE
  python3 scripts/tools/check_retired_label_mentions.py --base 5ff67996^
"""
import argparse
import glob
import re
import subprocess
import sys

LAB = re.compile(r'^([A-Za-z_][\w.$]*):', re.M)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", required=True)
    a = ap.parse_args()
    bad = 0
    for t in ("v10", "v9", "v7"):
        names = subprocess.run(["git", "ls-tree", "-r", "--name-only", a.base, t + "/maincpu"],
                               capture_output=True, text=True, check=True).stdout.split()
        old = set()
        for f in names:
            if f.endswith(".s"):
                old |= set(LAB.findall(subprocess.run(["git", "show", "%s:%s" % (a.base, f)],
                                                      capture_output=True).stdout.decode("latin-1")))
        cur, files = set(), sorted(glob.glob(t + "/maincpu/**/*.s", recursive=True))
        text = {f: open(f, "rb").read().decode("latin-1") for f in files}
        for s in text.values():
            cur |= set(LAB.findall(s))
        gone = old - cur
        if not gone:
            print("%s: nothing retired since %s" % (t, a.base))
            continue
        pat = re.compile(r'\b(%s)\b' % "|".join(map(re.escape, sorted(gone, key=len, reverse=True))))
        blocks = other = 0
        for f, s in text.items():
            L = s.split("\n")
            i = 0
            while i < len(L):
                if L[i].startswith("; [nakarest]"):
                    j = i
                    while j < len(L) and L[j].startswith("; [nakarest]"):
                        j += 1
                    if any(pat.search(x) for x in L[i:j]):
                        blocks += 1
                        print("  %s:%d [nakarest] block cites %s" % (f, i + 1, pat.search(" ".join(L[i:j])).group(1)))
                    i = j
                    continue
                if ";" in L[i] and pat.search(L[i].split(";", 1)[1]):
                    other += 1
                i += 1
        bad += blocks
        print("%s: %d labels retired since %s; %d [nakarest] blocks and %d other comment lines name one"
              % (t, len(gone), a.base, blocks, other))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
