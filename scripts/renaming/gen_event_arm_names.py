#!/usr/bin/env python3
"""gen_event_arm_names.py -- name generic event-dispatch arms <dispatcher>_On<Event> (v10/v9/v7).

QUESTION IT ANSWERS / WHAT IT DOES
  NAKA procedures dispatch on the event in XBC with if-chains:  cp xbc, EVT_SHOW / jr z, <arm>.  The event code
  is the firmware's own name for when the arm runs (shared/event_codes.s, from its EV_* name tables).  Earlier
  passes gave many arms names that say nothing: AcCmpRecBox_HandleEvt1 (EVT_SHOW), DpDoc_CaseA (EVT_SW_IN),
  BitmapDrawsw_Skip4 (EVT_GET_BITMAP_DATA), Bounds_Case1E0006A (EVT_GET_STRING).
  A label is renamed when:
    - every instruction that names it is a `jr z` / `jrl z` right after `cp xbc|bc|xde|xwa, EVT_X`, all with the
      same EVT_X;
    - and its current name is generic: semantic_score's GENERIC, POSITIONAL or CONTINUATION patterns, or a
      _CaseX / _HandleEvt* / _HandleEvent<digit>* / _Evt<X> / _Handler<n> / _Return<n> / _Path<n> suffix.
  The new name is <dispatcher>_On<Event>.  The event is spelled as frame_switch_cases.py spells it (EVT_GET_STRING ->
  OnGetString).  The dispatcher is the nearest label above the compare that is not itself generic in that sense,
  with a continuation suffix stripped.
  An arm whose new name is taken, or collides within the batch, keeps its name and is listed.  The plan is made per
  tree; v9 and v7 must give the same rules as v10 for every label they share.
  Output: scripts/renaming/rename_event_arms_<tree>.sed; --apply runs it over the tree's .s/.c/.ld files that hold
  an old name.

RUN (repository root)
  python3 scripts/renaming/gen_event_arm_names.py [--apply]      # then make all; make gate-all; symbols --regen
"""
import collections
import glob
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
APPLY = "--apply" in sys.argv
sys.path.insert(0, os.path.join(REPO, "scripts/analysis"))
_a, sys.argv = sys.argv, sys.argv[:1]
import semantic_score as SS   # noqa: E402
sys.argv = _a
EXTRA = re.compile(r'(_Case[A-Z0-9]+|_HandleEvt\w*|_HandleEvent\w*\d\w*|_Evt[A-Z0-9]+|_Handler\d+|_Return\d+'
                   r'|_Path\d+)$')
LABEL = re.compile(r'^([A-Za-z_]\w*):')
CONT = re.compile(r'_(Skip|Join|Loop|Return|Epilogue|Done|Next|Exit|Cont|End|Default|Resume|Nop)\d*$')


def generic(n):
    return bool(SS.GENERIC.search(n) or EXTRA.search(n) or any(p.search(n) for p in SS.POSITIONAL)
                or SS.CONTINUATION.search(n))


def code(x):
    return re.sub(r'\s+', ' ', x.split(";")[0].strip())


def spell(evt):
    return "On" + "".join(w.capitalize() for w in evt[4:].split("_"))


def plan(tree):
    files = {}
    for p in glob.glob(os.path.join(REPO, tree, "maincpu", "**", "*.s"), recursive=True):
        files[p] = open(p, "rb").read().decode("latin-1").split("\n")
    defined = set()
    refs = collections.Counter()
    for L in files.values():
        for x in L:
            m = LABEL.match(x)
            if m:
                defined.add(m.group(1))
            m2 = re.match(r'^\s*\.(set|equ)\s+(\w+),', x)
            if m2:
                defined.add(m2.group(2))
            for t in re.findall(r'\b([A-Za-z_]\w*)\b', LABEL.sub('', code(x))):
                refs[t] += 1
    arms = collections.defaultdict(list)
    for p, L in files.items():
        for i, x in enumerate(L):
            mm = re.match(r'^cp (xbc|bc|xde|xwa), (EVT_\w+)$', code(x))
            if not mm:
                continue
            j = i + 1
            while j < len(L) and not code(L[j]):
                j += 1
            if j >= len(L):
                continue
            mz = re.match(r'^jrl? z, (\w+)$', code(L[j]))
            if not mz:
                continue
            k = i
            disp = None
            while k >= 0:
                m = LABEL.match(L[k])
                if m and not generic(m.group(1)):
                    disp = CONT.sub("", m.group(1))
                    break
                k -= 1
            arms[mz.group(1)].append((mm.group(2), disp))
    rules, refused = {}, []
    for t, uses in sorted(arms.items()):
        evts = {e for e, _ in uses}
        disps = {d for _, d in uses}
        if len(evts) != 1 or len(disps) != 1 or None in disps or refs[t] != len(uses) or not generic(t):
            continue
        new = "%s_%s" % (disps.pop(), spell(evts.pop()))
        if new in defined or new in rules.values():
            refused.append((t, new))
            continue
        rules[t] = new
    # a name refused once must not be given to another label either
    clash = {n for _, n in refused}
    for t in [t for t, n in rules.items() if n in clash]:
        refused.append((t, rules.pop(t)))
    return rules, refused


def main():
    plans = {t: plan(t) for t in ("v10", "v9", "v7")}
    r10 = plans["v10"][0]
    for tree in ("v9", "v7"):
        bad = {t: (n, r10[t]) for t, n in plans[tree][0].items() if t in r10 and r10[t] != n}
        assert not bad, (tree, list(bad.items())[:5])
    for tree, (rules, refused) in plans.items():
        print("%s: %d arms renamed, %d refused (name taken or clash)" % (tree, len(rules), len(refused)))
        if not APPLY:
            if tree == "v10":
                for t in sorted(rules):
                    print("  %-48s -> %s" % (t, rules[t]))
                for t, n in refused:
                    print("  refused %-40s -> %s" % (t, n))
            continue
        sed = os.path.join(REPO, "scripts/renaming/rename_event_arms_%s.sed" % tree)
        lines = ["# rename_event_arms_%s.sed -- written by scripts/renaming/gen_event_arm_names.py" % tree,
                 "# generic `cp xbc, EVT_X / jr z, <arm>` targets -> <dispatcher>_On<Event>"]
        lines += ["s/\\b%s\\b/%s/g" % (a, rules[a]) for a in sorted(rules, key=len, reverse=True)]
        open(sed, "w").write("\n".join(lines) + "\n")
        hit = []
        for p in glob.glob(os.path.join(REPO, tree, "maincpu", "**", "*"), recursive=True):
            if p.endswith((".s", ".c", ".ld")):
                s = open(p, "rb").read().decode("latin-1")
                if any(re.search(r'\b%s\b' % a, s) for a in rules):
                    hit.append(p)
        if hit:
            subprocess.run(["sed", "-i", "-f", sed] + hit, check=True)
        print("  sed applied to %d files" % len(hit))


if __name__ == "__main__":
    main()
