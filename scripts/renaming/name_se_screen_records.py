#!/usr/bin/env python3
"""name_se_screen_records.py -- SeScreenData_0xNNNN record lists are named after the one routine that loads them (v10).

QUESTION IT ANSWERS
  The sound editor's screen layout data was converted with positional labels SeScreenData_0x0558 ... (444 of them
  in v10, the largest positional family the semantic score counts).  Each is a static record list that
  GraphicsRender_ProcessEntries draws: a routine does `ld xiy, SeScreenData_0x0685` (or lda / ld x.., ...) and
  hands it on.  The WSA1 display lists were named the same way after the routine that draws them
  (wsa1/notes/wsa1_display_list_drawer_names.py).  For every such label this script collects the CODE references
  to it.  An instruction that names it counts; a `.long` / data line does not.  Each reference resolves to its
  enclosing routine: the nearest label above that is not a local continuation (_Skip/_Join/...).  The label is
  renamed only when:
    - all references come from ONE routine;
    - that routine's name is not generic or positional (_Helper/_Data/_Code/..., 6 hex digits).
  The new name is <Routine>_Records, numbered _Records2, _Records3 in source order of the references when one routine
  loads several.  Lists loaded by several routines, by none, or by generic ones keep their names and are counted.
  Labels move no bytes; the byte gate is the proof.

RUN (repository root)
  python3 scripts/renaming/name_se_screen_records.py [--apply]
  then: make all; harmonize_version_labels.py --to v9 --apply / --to v7 --apply; make gate-all; l2 --regen/--check
"""
import collections
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TREE = os.path.join(ROOT, "v10", "maincpu")
DEF = re.compile(r'^([A-Za-z_][\w$]*):')
CONT = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Done|Next|Exit|Cont|End|Default|Resume|Nop)\d*$')
GEN = re.compile(r'_(Helper|Data|Code|Block|Branch|Stub|Part|Case|Entry|Sub|Thunk|Wrapper|Body|Chunk|Tail|Frag'
                 r'|Fragment)\d*(_\d+)*$|_Switch\d+_Case\d+$|[0-9A-F]{6}|_0x[0-9A-Fa-f]+$')
TARGET = re.compile(r'\bSeScreenData_0x[0-9A-Fa-f]+\b')


def main():
    apply = "--apply" in sys.argv
    files = sorted(glob.glob(os.path.join(TREE, "**", "*.s"), recursive=True))
    src = {p: open(p, "rb").read().decode("latin-1").split("\n") for p in files}
    defs = {m.group(1) for L in src.values() for x in L for m in [DEF.match(x)] if m}
    readers = collections.defaultdict(list)
    for p, L in src.items():
        routine = None
        for x in L:
            m = DEF.match(x)
            if m and not CONT.search(m.group(1)):
                routine = m.group(1)
            code = x.split(";")[0]
            if m:
                code = code[m.end():]
            s = code.strip()
            if not s or s.startswith("."):
                continue
            for t in TARGET.findall(s):
                readers[t].append(routine)
    targets = sorted(d for d in defs if TARGET.fullmatch(d))
    plan, why = {}, collections.Counter()
    taken = set(defs)
    per = collections.Counter()
    for t in targets:
        rs = readers.get(t, [])
        u = sorted(set(rs))
        if not rs:
            why["no code reference"] += 1
            continue
        if len(u) > 1:
            why["several reading routines"] += 1
            continue
        r = u[0]
        if not r or GEN.search(r):
            why["generic or positional reader"] += 1
            continue
        per[r] += 1
        new = "%s_Records%s" % (r, "" if per[r] == 1 else per[r])
        while new in taken:
            per[r] += 1
            new = "%s_Records%d" % (r, per[r])
        taken.add(new)
        plan[t] = new
    print("v10: %d SeScreenData_0x labels; %d named after their one reader; left: %s"
          % (len(targets), len(plan), dict(why)))
    if not apply or not plan:
        for o, n in list(plan.items())[:12]:
            print("   ", o, "->", n)
        return
    rx = re.compile(r'\b(%s)\b' % "|".join(sorted(map(re.escape, plan), key=len, reverse=True)))
    for p, L in src.items():
        t = "\n".join(L)
        t2 = rx.sub(lambda m: plan[m.group(1)], t)
        if t2 != t:
            data = t2.encode("latin-1")
            with open(p + ".tmp", "wb") as fh:
                fh.write(data)
            os.replace(p + ".tmp", p)
    with open(os.path.join(ROOT, "scripts/renaming/rename_se_screen_records_v10.sed"), "w") as fh:
        fh.write("# written by scripts/renaming/name_se_screen_records.py\n")
        fh.writelines("s/\\b%s\\b/%s/g\n" % (o, n) for o, n in plan.items())


if __name__ == "__main__":
    main()
