#!/usr/bin/env python3
"""kn5000_ram_candidates.py -- the busiest still-numeric KN5000 RAM operands, with the evidence a name could rest on.

QUESTION THIS ANSWERS
  Which RAM addresses would naming help most, and what does the tree already say about each?  For the
  top N numeric memory-operand addresses of a maincpu tree: the use count, the one-instruction accessor
  routines (`Name: <one access> / ret`) that touch it, and the writer routines grouped by value (the
  census of kn5000_ram_writers.py, abbreviated).  Evidence for a reviewer, not a naming rule.

USAGE
  python3 scripts/analysis/kn5000_ram_candidates.py --tree v10 [--top 40] [--skip 0]
"""
import argparse
import collections
import glob
import re


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", default="v10")
    ap.add_argument("--top", type=int, default=40)
    ap.add_argument("--skip", type=int, default=0)
    a = ap.parse_args()
    use, acc, wr = collections.Counter(), collections.defaultdict(set), collections.defaultdict(lambda: collections.defaultdict(set))
    for f in sorted(glob.glob("%s/maincpu/**/*.s" % a.tree, recursive=True)):
        L = open(f, "rb").read().decode("latin-1").split("\n")
        cur = "?"
        for i, l in enumerate(L):
            m = re.match(r'^([A-Za-z_][\w$]*):', l)
            if m:
                if not re.search(r'_(Skip|Join|Loop|Return|Exit|Done|Next)\d*$', m.group(1)):
                    cur = m.group(1)
                body = [re.sub(r'\s+', ' ', x.split(";")[0]).strip() for x in L[i + 1:i + 3]]
                if len(body) == 2 and body[1] == "ret":
                    g = re.search(r'\((0x[0-9a-fA-F]+|\d+)(?::\d+)?\)', body[0])
                    if g:
                        acc[int(g.group(1), 0)].add(m.group(1))
            c = re.sub(r'\s+', ' ', l.split(";")[0]).strip()
            if not c or c.startswith("."):
                continue
            for g in re.finditer(r'\((0x[0-9a-fA-F]+|\d+)(:8|:16|:24)?\)', c):
                v = int(g.group(1), 0)
                if 0x400 <= v < 0x100000:
                    use[v] += 1
                    w = re.match(r'^ldw? \((?:0x[0-9a-fA-F]+|\d+)(?::\d+)?\), ?(\S+)$', c)
                    if w:
                        wr[v][w.group(1)].add(cur)
    for v, n in use.most_common(a.top + a.skip)[a.skip:]:
        ws = "; ".join("%s<-%s" % (k, ",".join(sorted(r)[:3])) for k, r in sorted(wr[v].items())[:4])
        print("0x%05x %4d acc[%s] wr[%s]" % (v, n, ",".join(sorted(acc[v])[:3]), ws[:220]))


if __name__ == "__main__":
    main()
