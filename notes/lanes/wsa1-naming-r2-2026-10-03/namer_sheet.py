#!/usr/bin/env python3
"""namer_sheet.py -- round 2 of WSA1 routine naming: the prom_a routines whose callees are all named.

QUESTION THIS ANSWERS
  Which `sub_XXXXXX` routines of prom_a can be named from what they call and touch, and what does each
  one do?  From worklist_prom_a.json (scripts/analysis/routine_naming_worklist.py at the commit in
  AT_COMMIT) it keeps the routines that have a caller and whose every callee is named -- a prom_b
  thunk `T_F4xxxx` counts only when the routine it jumps to is named -- and prints, for entries
  [FROM, TO) of that list in address order: the routine as the source has it now (prom_b thunks shown
  as `T_F42B70{=Target}`), its callers, the text of any display list it loads, and its header.
  The names chosen go into packs/<name>.json for scripts/tools/apply_label_edits.py.

USAGE (repository root)
  python3 notes/lanes/wsa1-naming-r2-2026-10-03/namer_sheet.py [FROM [TO]] [--max N] [--count] [--image prom_b]
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
args = [a for a in sys.argv[1:] if not a.startswith("--") and not a.isdigit() or a.isdigit()]
nums = [int(a) for a in sys.argv[1:] if a.isdigit()]
mx = 16
if "--max" in sys.argv:
    mx = int(sys.argv[sys.argv.index("--max") + 1])
    nums = [n for n in nums if n != mx] if nums.count(mx) == 1 and sys.argv.index(str(mx)) == sys.argv.index("--max") + 1 else nums
IMG = sys.argv[sys.argv.index("--image") + 1] if "--image" in sys.argv else "prom_a"
nums = [n for n in nums if str(n) != IMG]
A = open("wsa1/%s/wsa1_%s.s" % (IMG, IMG), "rb").read().decode("latin-1").split("\n")
B = open("wsa1/prom_b/wsa1_prom_b.s", "rb").read().decode("latin-1").split("\n")
thunk = {}
for l in B:
    m = re.match(r'^(T_[A-Za-z0-9_]+):\s*jp\s+([A-Za-z_][\w]*)', l)
    if m:
        thunk[m.group(1)] = m.group(2)
PH = re.compile(r'^(sub|loc|T)_[0-9A-F]{6}(_\w+)?$')
at = {}
for i, l in enumerate(A):
    m = re.match(r'^([A-Za-z_.$][\w.$@]*):', l)
    if m:
        at[m.group(1)] = i
callers = {}
for i, l in enumerate(A):
    for t in re.findall(r'\b(?:call|calr|jp|jr|jrl)\s+(?:[a-z]+,\s*)?([A-Za-z_]\w*)', l.split(";")[0]):
        callers.setdefault(t, []).append(i)


def named(c):
    t = thunk.get(c, c)
    return not PH.match(t)


def owner(i):
    while i >= 0 and not re.match(r'^[A-Za-z_][\w$]*:', A[i]):
        i -= 1
    return A[i].split(":")[0] if i >= 0 else "?"


def dl_text(name):
    i = at.get(name)
    if i is None:
        return ""
    out = []
    for l in A[i + 1:i + 200]:
        if re.match(r'^[A-Za-z_][\w$]*:', l):
            break
        out += re.findall(r'\.ascii\s+"([^"]*)"', l)
    return " | ".join(out)[:140]


w = json.load(open(os.path.join(HERE, "worklist_%s.json" % IMG)))
todo = [x for x in w if x["name"] in at and x["callers"] and all(named(c) for c in x["callees"])]
todo.sort(key=lambda x: x["addr"])
if "--count" in sys.argv:
    print(len(todo))
    sys.exit(0)
lo = nums[0] if nums else 0
hi = nums[1] if len(nums) > 1 else len(todo)
for k, x in enumerate(todo[lo:hi], lo):
    i = at[x["name"]]
    hdr = []
    j = i - 1
    while j >= 0 and A[j].startswith(";") and len(hdr) < 3:
        hdr.insert(0, A[j][1:].strip())
        j -= 1
    cs = sorted({owner(c) for c in callers.get(x["name"], [])})
    print("#%d %s (%d lines) callers: %s" % (k, x["name"], x["lines"], ", ".join(cs[:5]) + (" ..." if len(cs) > 5 else "")))
    if hdr and not hdr[-1].startswith("----"):
        print("   hdr: " + " / ".join(hdr)[:200])
    for hl in A[max(0, i - 14):i]:
        if re.match(r'^; (Touches|Calls):', hl):
            print("   " + hl[2:].strip()[:160])
    n, j = 0, i + 1
    while j < len(A) and n < mx:
        l = A[j]
        if re.match(r'^[A-Za-z_][\w$]*:', l) and not l.startswith(x["name"] + "_"):
            break
        c = re.sub(r'\s+', ' ', l.split(";")[0]).strip()
        if c:
            c = re.sub(r'\b(T_F4[0-9A-F]{4})\b', lambda m: "%s{=%s}" % (m.group(1), thunk.get(m.group(1), "?")), c)
            print("   " + c)
            n += 1
            for t in re.findall(r'\b(DL_\w+|DisplayList_\w+)\b', c):
                tx = dl_text(t)
                if tx:
                    print("      [%s: %s]" % (t, tx))
        j += 1
