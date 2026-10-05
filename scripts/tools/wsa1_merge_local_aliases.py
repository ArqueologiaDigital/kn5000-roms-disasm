#!/usr/bin/env python3
"""Merge a `.L` local label into the named label that sits at the same address in a WSA1 source.

QUESTION IT ANSWERS
  The project's policy is one name per address ("Canonical Label Names").  A label placed later at an address that
  already had a `.Lxxxxxx` local label (scripts: wsa1_place-style placers, linear-decode labels) leaves two labels on
  adjacent lines:
      NamedLabel:
      .LFBE6C4:
  and code goes on reaching the address through the `.L` spelling.  This tool:
    * finds such pairs (a named label line and a `.L` label line next to each other, either order);
    * rewrites every reference to the `.L` label in that image to the named label;
    * removes the `.L` label line;
    * declares `.Lxxxxxx -> NamedLabel` to notes/prom_a_preservation_check.py (its label scan includes `.L` names);
    * refuses when a wsa1/notes file quotes the `.L` label (a checker that reads source text could change answer).
  The bytes do not change: both spellings were the same address.

RUN (from the repository root)
  python3 scripts/tools/wsa1_merge_local_aliases.py prom_a                 # list the pairs
  python3 scripts/tools/wsa1_merge_local_aliases.py prom_a --only NAME,...  # restrict to these named labels
  python3 scripts/tools/wsa1_merge_local_aliases.py prom_a --apply [--only ...]
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def pairs(L):
    out = []
    for i in range(len(L) - 1):
        a = re.match(r'^([A-Za-z_][\w$]*):\s*$', L[i])
        b = re.match(r'^(\.L[\w$]+):\s*$', L[i + 1])
        if a and b:
            out.append((a.group(1), b.group(1), i + 1))
            continue
        c = re.match(r'^(\.L[\w$]+):\s*$', L[i])
        d = re.match(r'^([A-Za-z_][\w$]*):\s*$', L[i + 1])
        if c and d:
            out.append((d.group(1), c.group(1), i))
    return out


def main():
    img = sys.argv[1]
    assert img in ("prom_a", "prom_b"), "image: prom_a or prom_b"
    only = None
    if "--only" in sys.argv:
        only = set(sys.argv[sys.argv.index("--only") + 1].split(","))
    path = os.path.join(ROOT, "wsa1", img, "wsa1_%s.s" % img)
    L = open(path, "rb").read().decode("latin-1").split("\n")
    P = [p for p in pairs(L) if only is None or p[0] in only]
    if "--apply" not in sys.argv:
        for named, local, _i in P:
            print("%-50s %s" % (named, local))
        print("pairs %d" % len(P))
        return
    quoted = subprocess.run(["grep", "-rlwE", "|".join(re.escape(l) for _n, l, _i in P) or "x^", os.path.join(ROOT, "wsa1", "notes"),
                             "--include=*.py", "--include=*.md"], capture_output=True, text=True).stdout.split()
    assert not quoted, "a notes file quotes a local label: %s" % quoted
    drop = {i for _n, _l, i in P}
    L = [l for k, l in enumerate(L) if k not in drop]
    s = "\n".join(L)
    for named, local, _i in P:
        s, n = re.subn(r'(?<![\w$.])%s(?![\w$])' % re.escape(local), named, s)
    data = s.encode("latin-1")
    with open(path + ".tmp", "wb") as fh:
        fh.write(data)
    os.replace(path + ".tmp", path)
    chk = os.path.join(ROOT, "wsa1", "notes", "prom_a_preservation_check.py")
    t = open(chk).read()
    anchor = "\n}\n\n\ndef _renames():"
    assert t.count(anchor) == 1
    t = t.replace(anchor, "".join('\n    "%s": "%s",   # merged into the named label at its address (scripts/tools/wsa1_merge_local_aliases.py)' % (l, n)
                                  for n, l, _i in P) + anchor)
    open(chk, "w").write(t)
    print("merged %d" % len(P))


if __name__ == "__main__":
    main()
