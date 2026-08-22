#!/usr/bin/env python3
"""Did this change delete a label definition anywhere under v7/, v9/ or v10/?

QUESTION ANSWERED, and it is the one the build gate CANNOT answer. A converter
that splices source lines can delete a label along with the `.byte` run it sat
in. If nothing in the same link references that label, the ROM still rebuilds
byte-identically and `Similarity: 100.00%` is reported for a disassembly that
just lost a name -- and `v7_unreferenced_labels_are_live.py` shows 8,203 of 9,975
v7 labels that LOOK unreferenced are referenced in v9/v10, so "unreferenced" is
not permission to drop one.

Compares the set of column-0 label definitions per file, between a revision and
the working tree (or between two revisions). Exits non-zero if any label is gone.

    python3 scripts/analysis/no_label_was_dropped.py               # HEAD vs working tree
    python3 scripts/analysis/no_label_was_dropped.py HEAD~1        # HEAD~1 vs working tree
    python3 scripts/analysis/no_label_was_dropped.py HEAD~1 HEAD   # between two commits

⚠ Read the files as latin-1, never as text: 65 of 506 `.s` files hold bytes over
127, and a UTF-8 read either throws or -- worse, with the wrong tool -- silently
skips the file as binary. A `grep` wrapper doing exactly that reported hundreds
of "lost" labels in a tree that had lost none.

MEASURED on the .incbin split of 2026-08-22: 15 files changed, 0 labels lost,
0 added.
"""
import re
import subprocess
import sys

LABEL = re.compile(r'^([A-Za-z_][\w]*):', re.M)
ROOTS = ("v7/", "v9/", "v10/", "v142/", "custom_data/", "table_data/")


def labels(rev, path):
    if rev is None:
        return set(LABEL.findall(open(path, "rb").read().decode("latin-1")))
    out = subprocess.run(["git", "show", f"{rev}:{path}"], capture_output=True)
    if out.returncode:
        return set()                      # the file did not exist at that revision
    return set(LABEL.findall(out.stdout.decode("latin-1")))


def main():
    args = sys.argv[1:]
    base = args[0] if args else "HEAD"
    head = args[1] if len(args) > 1 else None
    cmd = ["git", "diff", "--name-only", base] + ([head] if head else [])
    files = [f for f in subprocess.run(cmd, capture_output=True, text=True).stdout.split()
             if f.endswith(".s") and f.startswith(ROOTS)]
    lost = added = 0
    for f in files:
        a, b = labels(base, f), labels(head, f)
        if a - b:
            lost += len(a - b)
            print(f"LOST {len(a - b)} label(s) in {f}: {sorted(a - b)[:8]}")
        if b - a:
            added += len(b - a)
    print(f"{len(files)} changed .s file(s) between {base} and "
          f"{head or 'the working tree'}: {lost} label(s) lost, {added} added")
    return 1 if lost else 0


if __name__ == "__main__":
    sys.exit(main())
