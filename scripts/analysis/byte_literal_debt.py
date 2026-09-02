#!/usr/bin/env python3
r"""HOW MANY BYTES OF ONE TREE ARE STILL SPELLED AS A `.byte` LITERAL?

QUESTION THIS ANSWERS
---------------------
The lane brief is explicit that counting `.incbin` DIRECTIVES is the wrong
instrument -- this project once shipped a false "territorially complete" claim
by doing exactly that while 8,496 B of sound code sat in plain sight as
`.byte`.  So a lane reporting "N bytes converted" needs a figure that counts
BYTES and is computed from the source rather than from the converter's own
tally, which is the thing under test.

This counts `.byte` OPERANDS -- one per emitted byte -- across a source tree,
at a git revision or in the working tree, so a lane's before/after pair is
measured by something that did not do the conversion.

⚠ WHAT IT DOES NOT COUNT, deliberately: `.word`/`.long`/`.ascii`/`.zero` runs
and `.incbin`.  Those are also debt, and some of them are real typed data that
is not debt at all, so mixing them in would make the number mean less rather
than more.  This is a `.byte`-literal figure and must be quoted as one.

⚠ It reads latin-1.  Several sources carry raw high bytes inside `.ascii`
literals and a UTF-8 read either throws or, with the wrong tool, silently skips
the file.

RUN
    python3 scripts/analysis/byte_literal_debt.py v7/maincpu
    python3 scripts/analysis/byte_literal_debt.py v7/maincpu --rev ec98912f

MEASURED by lane rq-codeshape, 2026-09-02:
    v7/maincpu at ec98912f (before)   293,594 B
    v7/maincpu after the conversion   291,128 B
    difference                          2,466 B  -- equals the converter's own
                                                    tally, computed independently
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BYTE_RE = re.compile(r'^\s*(?:[A-Za-z_.$][\w.$@]*:)?\s*\.byte\s+(.*)$', re.I)


def count_text(text):
    n = 0
    for ln in text.split("\n"):
        m = BYTE_RE.match(ln.split(";")[0])
        if m:
            n += len([x for x in m.group(1).split(",") if x.strip()])
    return n


def count_tree(path):
    n, nf = 0, 0
    for dp, _, fn in os.walk(os.path.join(ROOT, path)):
        for f in sorted(fn):
            if f.endswith(".s"):
                nf += 1
                n += count_text(open(os.path.join(dp, f),
                                     encoding="latin-1").read())
    return n, nf


def count_rev(path, rev):
    files = subprocess.run(["git", "-C", ROOT, "ls-tree", "-r", "--name-only",
                            rev, path], capture_output=True,
                           text=True).stdout.split()
    n, nf = 0, 0
    for f in files:
        if not f.endswith(".s"):
            continue
        nf += 1
        blob = subprocess.run(["git", "-C", ROOT, "show", rev + ":" + f],
                              capture_output=True).stdout.decode("latin-1")
        n += count_text(blob)
    return n, nf


def main():
    a = sys.argv[1:]
    if not a:
        sys.exit(__doc__)
    path = a[0]
    if "--rev" in a:
        rev = a[a.index("--rev") + 1]
        n, nf = count_rev(path, rev)
        print("%s at %s: %d bytes spelled as .byte literals, in %d .s files"
              % (path, rev, n, nf))
    else:
        n, nf = count_tree(path)
        print("%s (working tree): %d bytes spelled as .byte literals, in %d "
              ".s files" % (path, n, nf))


if __name__ == "__main__":
    main()
