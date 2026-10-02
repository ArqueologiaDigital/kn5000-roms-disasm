#!/usr/bin/env python3
"""fix_header_addrs.py -- correct comment-quoted addresses that are another image's address.

QUESTION THIS ANSWERS / WHY IT EXISTS
  `scripts/analysis/claims_lint.py header-addrs` finds comments that quote a name at an address
  where THIS image's ELF does not put it ("SendPartDataBlock_InitVal7 (0xFF01AC)" in v9, where
  the v9 ELF has 0xFF01A1).  Its WRONG-ADDR rows carrying the signature "= <other image>
  address" are copy-paste from another version's header (v10 text carried to v9/v7 by a port);
  the independent verification of claims_lint measured that tier at 40/40 true.  This rewrites,
  in each such comment, the quoted address to the one the image's own ELF gives -- nothing else.

  Only rows whose detail is `WRONG-ADDR <Name> quoted 0x<Q>, <img> ELF 0x<E> ...; = <other>
  address` are touched; the first `0x<Q>` (any case) AFTER the name, inside the comment part of
  that line, is replaced, keeping the original digit case and width.  A row whose line no
  longer matches is reported and skipped, and so is a dual-version quote "(0xA / 0xB)" (the
  second address is another version's, written deliberately; a disagreement there is about the
  label's placement -- v7's 0x41A drift zone -- which this tool must not paper over).  Comment-only: `make gate-all` must stay 13/13.

USAGE
  python3 scripts/analysis/claims_lint.py header-addrs --out DIR
  python3 scripts/tools/fix_header_addrs.py DIR/header-addrs.tsv [--apply]
"""
import argparse
import collections
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
ROW = re.compile(r'^WRONG-ADDR (\S+) quoted 0x([0-9A-Fa-f]+), \S+ ELF 0x([0-9A-Fa-f]+) .*= \S+ address')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("tsv")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    rows = [l.rstrip("\n").split("\t") for l in open(a.tsv, encoding="utf-8")][1:]
    todo = collections.defaultdict(list)
    for r in rows:
        if len(r) < 5:
            continue
        m = ROW.match(r[4])
        if m:
            todo[r[1]].append((int(r[2]), m.group(1), m.group(2), m.group(3)))
    done = skipped = 0
    for f, items in sorted(todo.items()):
        path = os.path.join(REPO, f)
        L = open(path, "rb").read().decode("latin-1").split("\n")
        for ln, name, q, e in items:
            line = L[ln - 1]
            ci = line.find(";")
            ni = line.find(name, ci if ci >= 0 else 0)
            if ci < 0 or ni < 0:
                print("SKIP %s:%d name %s not in a comment" % (f, ln, name)); skipped += 1
                continue
            m = re.compile(r'0x(%s)\b' % q, re.I).search(line, ni)
            if not m:
                print("SKIP %s:%d 0x%s not after %s" % (f, ln, q, name)); skipped += 1
                continue
            if re.match(r'\s*/', line[m.end():]):
                # "(0xV10 / 0xV7)": a deliberate dual-version quote, where a disagreement
                # with this image's ELF is about the LABEL's placement (v7's drift zone),
                # not a copied address -- not this tool's call.
                print("SKIP %s:%d dual-version quote 0x%s / ..." % (f, ln, q)); skipped += 1
                continue
            orig = m.group(1)
            new = e.upper() if orig.isupper() or orig.isdigit() else e.lower()
            new = new.zfill(len(orig))
            L[ln - 1] = line[:m.start(1)] + new + line[m.end(1):]
            done += 1
        if a.apply:
            open(path, "wb").write("\n".join(L).encode("latin-1"))
    print("%s %d address(es) in %d file(s); skipped %d" %
          ("rewrote" if a.apply else "would rewrite", done, len(todo), skipped))
    return 0


if __name__ == "__main__":
    sys.exit(main())
