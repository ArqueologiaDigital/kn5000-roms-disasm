#!/usr/bin/env python3
r"""scoop_reparent_structural.py -- re-parent the symboliser's STRUCTURAL
labels in lane scoop's files onto the routine that actually contains them.

QUESTION ANSWERED
-----------------
"Which `<Parent>_<Role><n>` labels (Skip, Join, Loop, Entry, Epilogue, Return,
Helper, Next -- with or without a `_Code_` infix) inside CODE carry a parent
that is a DATA label?"  Only those are renamed: a
parent that is some other routine label is left alone (it may be the better
name).  The symboliser named each after the nearest routine
entry it could see; where that was a DATA label (StringData_APCModeNames_Code_Skip22
inside what is now ParamPopup_ApcMemory) or a routine further up, the name
misleads.  Each is renamed `<EnclosingRoutine>_<Role><n>` -- enclosing
routine = nearest preceding CODE label that is not itself structural -- in
this file only, and only when no other file names it.  Comments that quote
the old name are updated with it (a rename of a label this lane's tools
created or re-derived).  Emits the rename map it applied as a sed script
under scripts/renaming/ (CLAUDE.md's sed-based renaming policy).

RUN
    python3 scripts/renaming/scoop_reparent_structural.py --image v10
"""
import argparse
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "converters"))
import scoop_reframe as R  # noqa: E402

FILES = ["display/scoop_display.s", "display/scoop_editor_data.s", "display/graphics_text_vga.s"]
STRUCT = re.compile(r'^(?P<parent>[\w.$]+?)_(?:Code_)?(?P<role>Skip|Join|Loop|Entry|Epilogue|Return|Helper|Next|Sub)(?P<n>\d*)$')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    a = ap.parse_args()
    img = a.image
    root = os.path.join(R.ROOT, img, "maincpu")
    others = []
    for dp, _, fn in os.walk(root):
        for f in fn:
            if f.endswith(".s"):
                rel = os.path.relpath(os.path.join(dp, f), root)
                if rel not in FILES:
                    others.append(open(os.path.join(dp, f), encoding="latin-1").read())
    other_text = "\n".join(others)
    other_ids = set(re.findall(r'[A-Za-z_][\w.$]*', other_text))
    all_labels = set()
    for rel in FILES:
        all_labels |= set(re.findall(r'^([A-Za-z_][\w.$]*):', open(os.path.join(root, rel), encoding="latin-1").read(), re.M))
    all_labels |= set(re.findall(r'^([A-Za-z_][\w.$]*):', other_text, re.M))
    # labels that stand on DATA (their first following statement is a directive)
    data_labels = set()
    for text in others + [open(os.path.join(root, r), encoding="latin-1").read() for r in FILES]:
        LL = text.split("\n")
        for i, ln in enumerate(LL):
            c = R.strip_comment(ln)[0].strip()
            m = R.LABEL_RE.match(c)
            if not m:
                continue
            rest = c[m.end():].strip()
            j = i
            while not rest and j + 1 < len(LL) and j < i + 12:
                j += 1
                rest = R.strip_comment(LL[j])[0].strip()
                while R.LABEL_RE.match(rest):
                    rest = rest[R.LABEL_RE.match(rest).end():].strip()
            if rest.startswith((".byte", ".ascii", ".asciz", ".long", ".short", ".word", ".incbin")):
                data_labels.add(m.group(1))
    ren_all = {}
    for rel in FILES:
        p = os.path.join(root, rel)
        L = open(p, encoding="latin-1").read().split("\n")
        cur = None
        taken = set(all_labels)
        counters = {}
        for i, ln in enumerate(L):
            c = R.strip_comment(ln)[0].strip()
            m = R.LABEL_RE.match(c)
            if not m:
                continue
            nm = m.group(1)
            s = STRUCT.match(nm)
            rest = c[m.end():].strip()
            is_code = bool(rest) and not rest.startswith(".")
            if not rest:
                for j in range(i + 1, min(len(L), i + 12)):
                    t = R.strip_comment(L[j])[0].strip()
                    while R.LABEL_RE.match(t):
                        t = t[R.LABEL_RE.match(t).end():].strip()
                    if t:
                        is_code = not t.startswith(".")
                        break
            if not s:
                if is_code and not nm.startswith(".") and not re.search(r'_0x[0-9A-Fa-f]+$', nm):
                    cur = nm
                continue
            if not cur or s.group("parent") == cur or not is_code:
                continue
            # only MISLEADING parents: a label that stands on DATA
            par = s.group("parent")
            if par not in data_labels:
                continue
            if nm in other_ids:
                continue
            base = "%s_%s" % (cur, s.group("role"))
            k = counters.get(base, 0) + 1
            new = base if k == 1 else "%s%d" % (base, k)
            while new in taken:
                k += 1
                new = "%s%d" % (base, k)
            counters[base] = k
            taken.add(new)
            ren_all[(rel, nm)] = new
    if not ren_all:
        print("nothing to re-parent")
        return
    backup = {}
    for rel in FILES:
        p = os.path.join(root, rel)
        mp = {o: n for (r, o), n in ren_all.items() if r == rel}
        if not mp:
            continue
        raw = open(p, "rb").read()
        backup[p] = raw
        pat = re.compile(r'(?<![\w.$])(%s)(?![\w.$])' % "|".join(re.escape(o) for o in sorted(mp, key=len, reverse=True)))
        open(p, "wb").write(pat.sub(lambda m: mp[m.group(1)], raw.decode("latin-1")).encode("latin-1"))
    ok, _, data = R.build(img)
    if not ok or data != R.rom(img):
        for p, t in backup.items():
            open(p, "wb").write(t)
        raise SystemExit("REJECTED: restored")
    sed = os.path.join(HERE, "rename_scoop_reparent_%s.sed" % img)
    with open(sed, "w") as f:
        for (rel, o), n in sorted(ren_all.items()):
            f.write("s/\\b%s\\b/%s/g\n" % (o, n))
    print("%s: %d structural labels re-parented (map: %s); image byte-identical"
          % (img, len(ren_all), os.path.relpath(sed, R.ROOT)))


if __name__ == "__main__":
    main()
