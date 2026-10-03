#!/usr/bin/env python3
"""kn5000_ram_writers.py -- who writes a KN5000 RAM variable, with what, and how it is otherwise used.

QUESTION THIS ANSWERS
  Naming a RAM variable from its uses needs the census: every `ld (ADDR), value` grouped by value with
  the routines (nearest non-structural label) that write it, and the shapes of the other uses.  The
  names given from it (shared/ram_variables.s: SEQ_ERROR_CODE, GLOBAL_ERROR_CODE) cite this output.
  Numeric and already-named operands both count (pass --name NAME once the variable has one).

USAGE
  python3 scripts/analysis/kn5000_ram_writers.py --tree v10 0x287a [--name SEQ_ERROR_CODE]
"""
import argparse
import collections
import glob
import re


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", default="v10")
    ap.add_argument("addr")
    ap.add_argument("--name")
    a = ap.parse_args()
    addr = int(a.addr, 16)
    spell = r'(?:0x0*%x|%d%s)' % (addr, addr, ("|" + re.escape(a.name)) if a.name else "")
    w, r = collections.defaultdict(set), collections.Counter()
    for f in sorted(glob.glob("%s/maincpu/**/*.s" % a.tree, recursive=True)):
        cur = "?"
        for l in open(f, "rb").read().decode("latin-1").split("\n"):
            m = re.match(r'^([A-Za-z_][\w$]*):', l)
            if m and not re.search(r'_(Skip|Join|Loop|Return|Exit|Done|Next)\d*$', m.group(1)):
                cur = m.group(1)
            c = re.sub(r'\s+', ' ', l.split(";")[0]).strip()
            if not re.search(r'\(%s(?::8|:16|:24)?\)' % spell, c, re.I):
                continue
            g = re.match(r'^ldw? \(%s(?::\d+)?\), ?(\S+)$' % spell, c, re.I)
            if g:
                w[g.group(1)].add(cur)
            else:
                r[re.sub(r'(0x[0-9a-f]+|\b\d+\b)', 'N', c)] += 1
    for v in sorted(w, key=lambda x: (len(x), x)):
        print("write %-8s %3d routines: %s" % (v, len(w[v]), " ".join(sorted(w[v])[:6])))
    print("other uses:", r.most_common(8))


if __name__ == "__main__":
    main()
