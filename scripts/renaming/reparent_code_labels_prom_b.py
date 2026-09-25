#!/usr/bin/env python3
r"""Re-parent wsa1/prom_b's `<DataLabel>_Code_<Role>` structural labels onto the routine they sit in.

QUESTION THIS ANSWERS / JOB IT DOES
    scripts/converters/symbolize_numeric_branches.py names a new branch target
    `<Parent>_<Role>`, and when its upward walk meets a DATA-framed label before
    any label it counts as a routine entry, Parent becomes `<DataLabel>_Code`.
    In prom_b that produced 872 labels such as `Unclaimed_F57453_Code_Loop`,
    `BStore_Table_F6415E_Code_Skip17` or `DL_F59C53_Code_Return` -- code labels
    named after a TABLE, often thousands of bytes away from it, although a code
    label (a `sub_XXXXXX` or a named routine) sits between the table and them.

    For each such label this tool finds the nearest label ABOVE it, below the
    data label it is named after, that is not itself structural and whose first
    emitting line is an INSTRUCTION, and renames `<Data>_Code_<Role><n>` to
    `<Routine>_<Role><k>` (k chosen so the name is unique).  Labels with no such
    code label between (the code starts right after the table, unlabelled) are
    left alone and counted.

    It changes names only.  Every one of these labels is used as a branch
    operand (that is why the symboliser created it), so the byte gate protects
    the edit: a wrong rename either fails to assemble or moves bytes.

RUN
    python3 scripts/renaming/reparent_code_labels_prom_b.py            # dry run: counts + sample
    python3 scripts/renaming/reparent_code_labels_prom_b.py --apply --map OUT.map
      (OUT.map is `old=new` per line, for assert_comments_preserved.py --rename-map)
"""
import argparse
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import data_range_census as drc  # noqa: E402

PATH = os.path.join(ROOT, "wsa1", "prom_b", "wsa1_prom_b.s")
LAB = re.compile(r'^([A-Za-z_][\w.$]*):')
CODE_STRUCT = re.compile(r'^(?P<data>.+?)_Code_(?P<role>Skip|Join|Loop|Return|Epilogue|Entry|Sub|Helper)(?P<n>\d*)$')
ROLE = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Entry|Sub|Helper)\d*$')


def plan(lines, macros):
    labels = [(i, LAB.match(t).group(1)) for i, t in enumerate(lines) if LAB.match(t)]
    names = {n for _, n in labels}

    def first_kind(i):
        for k in range(i, min(len(lines), i + 40)):
            bk, _ = drc.classify_line(lines[k], macros)
            if bk in ("code", "data", "fill"):
                return bk
        return None

    out, skipped = [], []
    for idx, (i, n) in enumerate(labels):
        m = CODE_STRUCT.match(n)
        if not m:
            continue
        parent = None
        for j in range(idx - 1, -1, -1):
            li, nm = labels[j]
            if nm == m.group("data"):
                break
            if ROLE.search(nm) or nm.startswith((".L", "__")):
                continue
            if first_kind(li) == "code":
                parent = nm
                break
        if parent:
            out.append((n, parent, m.group("role")))
        else:
            skipped.append(n)
    taken = set(names)
    mapping = {}
    for old, parent, role in out:
        base = "%s_%s" % (parent, role)
        new, k = base, 1
        while new in taken:
            k += 1
            new = "%s%d" % (base, k)
        taken.add(new)
        mapping[old] = new
    return mapping, skipped


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--map")
    a = ap.parse_args()
    raw = open(PATH, "rb").read().decode("latin-1")
    lines = raw.split("\n")
    macros = drc.collect_macros(os.path.join(ROOT, "wsa1"))
    mapping, skipped = plan(lines, macros)
    print("re-parented: %d   left (no code label between table and label): %d" % (len(mapping), len(skipped)))
    for old in sorted(mapping)[:12]:
        print("  %s -> %s" % (old, mapping[old]))
    if not a.apply:
        return 0
    rx = re.compile(r'\b(' + "|".join(re.escape(k) for k in sorted(mapping, key=len, reverse=True)) + r')\b')
    new = rx.sub(lambda m: mapping[m.group(1)], raw)
    open(PATH, "wb").write(new.encode("latin-1"))
    if a.map:
        with open(a.map, "w") as f:
            for k in sorted(mapping):
                f.write("%s=%s\n" % (k, mapping[k]))
    print("applied")
    return 0


if __name__ == "__main__":
    sys.exit(main())
