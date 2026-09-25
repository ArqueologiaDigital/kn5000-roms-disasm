#!/usr/bin/env python3
r"""Rename wsa1/prom_b's hand-made RETURN POINTS from `sub_<ADDR>` to `<Routine>_Resume`.

QUESTION THIS ANSWERS / JOB IT DOES
    scripts/converters/symbolize_wsa1_rom_addresses.py --offsets labels an
    instruction start that `ld`/`lda` load as a value, and names it
    `sub_<ADDR>` when the instruction before it is a terminator.  One common
    shape in prom_b is a COMPUTED CALL made by hand:

        lda  XIY,<here>        ; the return address
        push XIY
        jp   (XBC)             ; enter the routine a table selected
      <here>:                  ; ... which returns HERE
        pop  BC

    The label after the `jp` is not a routine of its own; it is where the
    enclosing routine resumes.  This tool finds every label the --offsets pass
    created (it compares the labels at the commit that pass made, 5c37948a,
    with its parent) whose preceding instruction is a `jp` and whose only
    references sit within eight lines above it, and renames it
    `<Routine>_Resume` (Routine = the nearest non-structural label above the
    loading instruction; a number is appended when taken).  Callback entry
    points stored elsewhere keep `sub_<ADDR>`.

    Names only; each label is an operand of the `ld`/`lda` that loads it, so
    the byte gate protects the edit.

RUN
    python3 scripts/renaming/rename_resume_points_prom_b.py                 # dry run
    python3 scripts/renaming/rename_resume_points_prom_b.py --apply --map OUT.map
"""
import argparse
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
REL = "wsa1/prom_b/wsa1_prom_b.s"
PATH = os.path.join(ROOT, REL)
PASS_COMMIT = "5c37948a"
LAB = re.compile(r'^([A-Za-z_][\w.$]*):')
STRUCT = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Entry|Sub|Helper|Arm|Resume)\d*$')


def labels_at(rev):
    t = subprocess.run(["git", "show", "%s:%s" % (rev, REL)], cwd=ROOT,
                       capture_output=True).stdout.decode("latin-1")
    return set(re.findall(r"^([A-Za-z_][\w.$]*):", t, re.M))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--map")
    a = ap.parse_args()
    created = labels_at(PASS_COMMIT) - labels_at(PASS_COMMIT + "~1")
    raw = open(PATH, "rb").read().decode("latin-1")
    L = raw.split("\n")
    idx = {}
    for i, t in enumerate(L):
        m = LAB.match(t)
        if m:
            idx[m.group(1)] = i
    taken = set(idx)
    mapping = {}
    for n in sorted(created):
        if n not in idx or not n.startswith("sub_"):
            continue
        i = idx[n]
        j, prev = i - 1, None
        while j > 0:
            c = L[j].split(";")[0].strip()
            if c and not LAB.match(c):
                prev = c
                break
            j -= 1
        if not prev or not prev.startswith("jp"):
            continue
        refs = [k for k, t in enumerate(L) if k != i and re.search(r'\b%s\b' % re.escape(n), t.split(";")[0])]
        if not refs or not all(0 < i - k < 8 for k in refs):
            continue
        parent = None
        for k in range(refs[0], -1, -1):
            m = LAB.match(L[k])
            if m and not STRUCT.search(m.group(1)) and m.group(1) != n:
                parent = m.group(1)
                break
        if not parent:
            continue
        base = "%s_Resume" % parent
        new, c = base, 1
        while new in taken:
            c += 1
            new = "%s%d" % (base, c)
        taken.add(new)
        mapping[n] = new
    print("return points renamed: %d" % len(mapping))
    for k in sorted(mapping)[:10]:
        print("  %s -> %s" % (k, mapping[k]))
    if a.apply and mapping:
        rx = re.compile(r'\b(' + "|".join(re.escape(k) for k in sorted(mapping, key=len, reverse=True)) + r')\b')
        open(PATH, "wb").write(rx.sub(lambda m: mapping[m.group(1)], raw).encode("latin-1"))
        if a.map:
            with open(a.map, "w") as f:
                for k in sorted(mapping):
                    f.write("%s=%s\n" % (k, mapping[k]))
        print("applied")
    return 0


if __name__ == "__main__":
    sys.exit(main())
