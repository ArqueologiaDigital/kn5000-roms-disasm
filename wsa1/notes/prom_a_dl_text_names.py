#!/usr/bin/env python3
"""Name prom_a's text-bearing display lists DL_<their text>, the way prom_b's are named.

QUESTION IT ANSWERS
  notes/gen_prom_a_display_list_text.py rendered 26 prom_a lists as records with `.ascii` text.  prom_b names
  such a list from the text it draws: round 4 / notes/prom_b_dl_screens_round5.py accumulate CamelCase from
  the list's own `.ascii` literals (only literals with two adjacent letters), stop at 24 characters, and keep
  going -- up to 60 -- while the name collides.  Same rule here, over a prom_a DisplayList_FXXXXX label's
  literals up to the next label.  REFUSED: a list whose whole text collides with another list's or an
  existing name even at 60 characters (it draws the same words; nothing in it says which screen).

RUN
  python3 notes/prom_a_dl_text_names.py          # the plan and the refusals
  python3 notes/prom_a_dl_text_names.py --args   # 'old=new|header' for the rename helper
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), "rb").read().decode("latin-1")
B = open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s"), "rb").read().decode("latin-1")
SLUG_MIN, SLUG_MAX = 24, 60
ASC = re.compile(r'\.ascii\s+"((?:[^"\\]|\\.)*)"')


def camel(s):
    return "".join(w[0].upper() + w[1:].lower() for w in re.split(r"[^A-Za-z0-9]+", s) if w)


def literals():
    L = A.split("\n")
    out, cur = {}, None
    for l in L:
        m = re.match(r'^([A-Za-z_.][\w$.]*):', l)
        if m:
            cur = m.group(1) if re.match(r'^DisplayList_F[0-9A-F]{5}$', m.group(1)) else None
            continue
        if cur:
            for t in ASC.findall(l.split(";")[0]):
                if re.search(r'[A-Za-z]{2}', t):
                    out.setdefault(cur, []).append(t.strip())
    return out


def slug_list(lit):
    out, s = [], ""
    for t in lit:
        s += camel(t)
        if len(s) >= SLUG_MIN:
            out.append(s[:SLUG_MAX])
        if len(s) >= SLUG_MAX:
            break
    if not out:
        out.append(s[:SLUG_MAX])
    return out


def plan():
    lit = literals()
    taken = set(re.findall(r'[A-Za-z_][\w$]*', A + "\n" + B))
    cands = {n: ["DL_" + s for s in slug_list(t)] for n, t in lit.items()}
    rows, refused, used = [], [], set()
    for n in sorted(cands):
        others = {c for m, cs in cands.items() if m != n for c in cs}
        pick = next((c for c in cands[n] if c not in taken and c not in others and c not in used), None)
        if pick is None:
            refused.append((n, "its text %r collides" % " / ".join(lit[n])[:80]))
            continue
        used.add(pick)
        rows.append((n, pick, "%s: the display list whose text records draw %s (notes/prom_a_dl_text_names.py)." % (
            pick, " / ".join('"%s"' % t for t in lit[n][:6]) + (" ..." if len(lit[n]) > 6 else ""))))
    return rows, refused


def main():
    rows, refused = plan()
    for o, n, h in rows:
        print(("%s=%s|%s" % (o, n, h)) if "--args" in sys.argv else "%-22s -> %s" % (o, n))
    if "--args" not in sys.argv:
        for o, why in refused:
            print("REFUSED %s: %s" % (o, why))
        print("rename %d, refused %d" % (len(rows), len(refused)))


if __name__ == "__main__":
    main()
