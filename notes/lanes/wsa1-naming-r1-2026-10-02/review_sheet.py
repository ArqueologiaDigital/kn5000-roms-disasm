#!/usr/bin/env python3
"""review_sheet.py -- one compact sheet per proposed rename, for an independent check of a round-1 pack.

QUESTION THIS ANSWERS
  Does the code of each routine a pack renames support the proposed name and the namer's evidence?
  For renames [FROM, TO) of a rebased pack it prints `OLD -> NEW`, the evidence line, the routine's
  instructions as the source has them now (comments dropped, names resolved), the strings of any
  display list it loads (`ld XIY,<list>` text, read from the list's `.ascii` lines), and who calls
  it.  The reviewer's verdicts go in verdicts/<pack>.json; apply_verdicts.py writes the accepted
  renames as a pack.

USAGE (repository root)
  python3 notes/lanes/wsa1-naming-r1-2026-10-02/review_sheet.py prom_a-s06 [FROM [TO]] [--max N]
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
args = [a for a in sys.argv[1:] if not a.startswith("--")]
mx = int(sys.argv[sys.argv.index("--max") + 1]) if "--max" in sys.argv else 22
pk = json.load(open(os.path.join(HERE, "rebased", args[0] + ".json")))
lo = int(args[1]) if len(args) > 1 else 0
hi = int(args[2]) if len(args) > 2 else len(pk["renames"])
L = open(pk["files"][0], "rb").read().decode("latin-1").split("\n")
at = {}
for i, l in enumerate(L):
    m = re.match(r'^([A-Za-z_.$][\w.$@]*):', l)
    if m:
        at[m.group(1)] = i
callers = {}
for i, l in enumerate(L):
    c = l.split(";")[0]
    for t in re.findall(r'\b(?:call|calr|jp|jr|jrl)\s+(?:[a-z]+,\s*)?([A-Za-z_][\w]*)', c):
        callers.setdefault(t, []).append(i)


def owner(i):
    while i >= 0 and not re.match(r'^[A-Za-z_][\w$]*:', L[i]):
        i -= 1
    return L[i].split(":")[0] if i >= 0 else "?"


def list_text(name, off=0):
    """the list's text, and its first record lines' commented fields (`; +0x02 source variable`)"""
    i = at.get(name)
    if i is None:
        return ""
    out, fields = [], []
    for l in L[i + 1:i + 160]:
        if re.match(r'^[A-Za-z_][\w$]*:', l):
            break
        out += re.findall(r'\.ascii\s+"([^"]*)"', l)
        if len(fields) < 4 and re.search(r';\s*\+0x[0-9A-Fa-f]+\s+\w', l):
            fields.append(re.sub(r'\s+', ' ', l.strip())[:90])
        elif not fields and not out and l.strip().startswith(".byte"):
            fields.append(re.sub(r'\s+', ' ', l.split(";")[0].strip())[:70])
    return (" | ".join(out)[:160] + ("  {" + " ; ".join(fields) + "}" if fields else "")).strip()


for k, r in enumerate(pk["renames"][lo:hi], lo):
    i = at[r["old"]]
    print("#%d %s -> %s" % (k, r["old"], r["new"]))
    print("   ev: " + r["evidence"][:400])
    n, j = 0, i + 1
    while j < len(L) and n < mx:
        l = L[j]
        if re.match(r'^[A-Za-z_][\w$]*:', l) and not l.startswith(r["old"] + "_"):
            break
        c = re.sub(r'\s+', ' ', l.split(";")[0]).strip()
        if c:
            print("   " + c)
            n += 1
            for t in re.findall(r'\b(DisplayList_\w+|Descriptor\w+)\b', c):
                tx = list_text(t)
                if tx:
                    print("      [%s: %s]" % (t, tx))
        j += 1
    cs = sorted({owner(x) for x in callers.get(r["old"], [])})
    print("   callers: %s" % (", ".join(cs[:6]) + (" ..." if len(cs) > 6 else "") if cs else "(none in prom_a)"))
