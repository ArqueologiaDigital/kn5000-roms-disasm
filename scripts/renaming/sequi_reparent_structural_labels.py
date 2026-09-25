#!/usr/bin/env python3
r"""sequi_reparent_structural_labels.py -- give symboliser-made structural labels
the name of the routine they actually sit in.

QUESTION THIS ANSWERS / JOB IT DOES
    symbolize_numeric_branches.py names a new branch target
    `<Parent>_<Role><n>` (Role = Skip / Join / Loop / Return / Epilogue),
    Parent = the nearest ROUTINE ENTRY above the target -- a label something
    calls or a pointer table holds.  Where a run of routines is reached only
    through dispatch tables no such entry lies between them, so labels deep
    inside NoteEditBox_* case bodies came out as `InitializeKubo_Skip4`,
    naming a routine thousands of lines away.  This renames every such label
    to `<nearest preceding descriptive label>_<Role><n>`.

RULES (all checkable in the source)
    * only labels matching `<P>_(Skip|Join|Loop|Return|Epilogue)<digits?>`
      whose `<P>` is NOT the nearest preceding descriptive label (nor a
      prefix of it); a "descriptive" label is one that is not itself
      structural and not a `.L`/`__` local;
    * and only where P is demonstrably the wrong parent: P is itself a
      structural label (`X_Skip2_Join3`), or P is defined in the same file
      more than MIN_DISTANCE (1000) lines above;
    * the new name is `<nearest>_<Role><k>`, k chosen to be unique in the file;
    * a label referenced by any other source file of the SAME image
      (git grep -w over <image>/*.s,*.c,*.h) is left alone -- renaming it
      would edit another lane's file or break its reference (another
      version's copy of the file has its own, unrelated symbol);
    * references are rewritten with word-boundary matching, latin-1 I/O.

RUN
    python3 scripts/renaming/sequi_reparent_structural_labels.py FILE...        # dry
    python3 scripts/renaming/sequi_reparent_structural_labels.py --apply FILE...
    then rebuild: the labels are branch operands, so a wrong rename either
    fails to assemble or moves bytes -- the byte gate polices it.
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROLE = re.compile(r'^(?P<p>[A-Za-z_][\w]*?)_(?P<r>Skip|Join|Loop|Return|Epilogue)(?P<n>\d*)$')
LBL = re.compile(r'^([A-Za-z_.$][\w.$@]*):')


def structural(name):
    return bool(ROLE.match(name)) or name.startswith((".L", "__"))


def refs_outside(name, path):
    """Files of the SAME image (v10/, v9/, v7/ ... tree) other than `path`
    that mention `name`.  Another version's copy of the file defines its own,
    unrelated symbol of the same name, so it does not count."""
    rel = os.path.relpath(os.path.abspath(path), ROOT)
    image = rel.split("/")[0]
    r = subprocess.run(["git", "grep", "-l", "-w", "-a", "-F", name, "--",
                        image + "/*.s", image + "/*.c", image + "/*.h"],
                       cwd=ROOT, capture_output=True, text=True)
    return [f for f in r.stdout.split() if f and f != rel]


MIN_DISTANCE = 1000


def plan(path):
    L = open(path, encoding="latin-1").read().split("\n")
    names = set()
    where = {}
    for i, ln in enumerate(L):
        m = LBL.match(ln)
        if m:
            names.add(m.group(1))
            where.setdefault(m.group(1), i)
    nearest = None
    ren = {}
    used = set(names)
    for i, ln in enumerate(L):
        m = LBL.match(ln)
        if not m:
            continue
        n = m.group(1)
        if not structural(n):
            nearest = n
            continue
        mm = ROLE.match(n)
        if not mm or nearest is None:
            continue
        P = mm.group("p")
        if P == nearest or nearest.startswith(P + "_"):
            continue
        # only where the parent is demonstrably wrong: itself a structural
        # label, or defined in this file more than MIN_DISTANCE lines above
        # (a routine that far away has ended long before).  A parent that is
        # not defined in this file is left alone -- the distance is unknown.
        if not (structural(P) or (P in where and i - where[P] > MIN_DISTANCE)):
            continue
        if n in ren:
            continue
        if refs_outside(n, path):
            continue
        k = ""
        i = 1
        while True:
            cand = "%s_%s%s" % (nearest, mm.group("r"), k)
            if cand not in used:
                break
            i += 1
            k = str(i)
        used.add(cand)
        ren[n] = cand
    return ren


def main():
    args = sys.argv[1:]
    apply = "--apply" in args
    files = [a for a in args if a != "--apply"]
    for path in files:
        ren = plan(path)
        print("%s: %d rename(s)" % (path, len(ren)))
        for o, n in sorted(ren.items()):
            print("    %-45s -> %s" % (o, n))
        if apply and ren:
            s = open(path, encoding="latin-1").read()
            pat = re.compile(r'(?<![\w.$@])(%s)(?![\w.$@])' % "|".join(map(re.escape, ren)))
            s = pat.sub(lambda m: ren[m.group(1)], s)
            open(path, "w", encoding="latin-1").write(s)


if __name__ == "__main__":
    main()
