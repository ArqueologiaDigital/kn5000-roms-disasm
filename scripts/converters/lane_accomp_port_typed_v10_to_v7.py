#!/usr/bin/env python3
r"""lane_accomp_port_typed_v10_to_v7.py -- carry v10's typed DATA to v7 where the
bytes are the same.

QUESTION ANSWERED
-----------------
"For which label-delimited chunks of accompaniment_engine.s has v10 already
worked out the data typing (directives + evidence header) while v7 still spells
the SAME bytes as instructions -- and can v10's text simply be used in v7?"

A chunk is the text from a label line to the next label line.  A chunk is
ported when ALL hold:
  * the same label starts it in both versions and the same label ends it;
  * v10's chunk holds no instruction line (only data directives, comments,
    blank lines) and v7's chunk holds at least one instruction line;
  * both chunks emit the same number of bytes (from fresh lane_line_map.py
    maps) and the ROM bytes are IDENTICAL -- so every value in v10's text is
    right for v7 by construction, and the byte gate checks the layout;
  * v10's chunk defines no label (it would be defined twice or orphaned).
Every comment of the replaced v7 chunk is kept, in order, after a one-line
note.  Symbolic operands in v10's directives (`.long Foo`) need Foo to exist in
v7 at the address whose bytes are already identical; the gate checks that.

RUN
    python3 scripts/converters/lane_accomp_port_typed_v10_to_v7.py \
        --map10 M10.json --map7 M7.json [--apply]
"""
import argparse
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
REL = "sequencer/accompaniment_engine.s"
BASE = 0xE00000
LABEL_RE = re.compile(r'^([A-Za-z_.$][\w.$@]*):')
DATA = (".byte", ".short", ".long", ".ascii", ".asciz", ".zero", ".fill", ".word", ".hword")


def strip_comment(line):
    out, q = [], None
    for ch in line:
        if q:
            out.append(ch)
            if ch == q:
                q = None
            continue
        if ch == '"':
            q = ch
        elif ch == ";":
            break
        out.append(ch)
    return "".join(out).strip()


def comment_of(line):
    q = None
    for i, ch in enumerate(line):
        if q:
            if ch == q:
                q = None
            continue
        if ch == '"':
            q = ch
        elif ch == ";":
            return line[i:].rstrip()
    return None


def chunks(L, rows):
    """-> {label: (start_idx, end_idx, next_label, first_addr, end_addr)} (0-based, end exclusive)."""
    addr = {ln: (a, sz) for ln, a, sz, t in rows}
    labs = [(i, LABEL_RE.match(L[i]).group(1)) for i in range(len(L))
            if LABEL_RE.match(L[i]) and strip_comment(L[i]) == LABEL_RE.match(L[i]).group(0)]
    out = {}
    for k, (i, name) in enumerate(labs[:-1]):
        j, nxt = labs[k + 1]
        if (i + 1) in addr and (j + 1) in addr:
            out[name] = (i, j, nxt, addr[i + 1][0], addr[j + 1][0])
    return out


def kinds(lines):
    ins = dat = 0
    for x in lines:
        c = strip_comment(x)
        if not c:
            continue
        if LABEL_RE.match(c):
            return None          # a label inside
        if c.startswith(DATA):
            dat += 1
        elif c.startswith("."):
            return None
        else:
            ins += 1
    return ins, dat


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map10", required=True)
    ap.add_argument("--map7", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    r10 = open(os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
    r7 = open(os.path.join(ROOT, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
    p10, p7 = (os.path.join(ROOT, v, "maincpu", REL) for v in ("v10", "v7"))
    L10 = open(p10, encoding="latin-1").read().split("\n")
    L7 = open(p7, encoding="latin-1").read().split("\n")
    m10 = json.load(open(a.map10))["files"][REL]
    m7 = json.load(open(a.map7))["files"][REL]
    for L, m in ((L10, m10), (L7, m7)):
        for ln, ad, sz, t in m:
            if L[ln - 1] != t:
                sys.exit("stale map")
    c10, c7 = chunks(L10, m10), chunks(L7, m7)
    todo = []
    for name, (i10, j10, n10, a10, e10) in c10.items():
        if name not in c7:
            continue
        i7, j7, n7, a7, e7 = c7[name]
        if n7 != n10 or e10 - a10 != e7 - a7 or e10 <= a10:
            continue
        k10, k7 = kinds(L10[i10 + 1:j10]), kinds(L7[i7 + 1:j7])
        if not k10 or not k7 or k10[0] != 0 or k10[1] == 0 or k7[0] == 0:
            continue
        if r10[a10 - BASE:e10 - BASE] != r7[a7 - BASE:e7 - BASE]:
            continue
        todo.append((name, i7, j7, i10, j10, e10 - a10))
    print("%d chunks to port, %d B" % (len(todo), sum(t[5] for t in todo)))
    for t in todo:
        print("  %-48s %5d B  v7 lines %d-%d" % (t[0], t[5], t[1] + 2, t[2]))
    if not a.apply:
        return
    for name, i7, j7, i10, j10, n in sorted(todo, key=lambda t: -t[1]):
        old = L7[i7 + 1:j7]
        cm = [comment_of(x) for x in old]
        cm = [c for c in cm if c]
        new = ["; ** v7: typed as in v10 (the %d bytes are identical in both ROMs) -- lane accomp" % n,
               ";    2026-09-25, scripts/converters/lane_accomp_port_typed_v10_to_v7.py."]
        if cm:
            new.append("; -- comments this v7 range carried before, in order:")
            new += ["\t" + c for c in cm]
        new += L10[i10 + 1:j10]
        L7[i7 + 1:j7] = new
    tmp = p7 + ".tmp"
    open(tmp, "w", encoding="latin-1").write("\n".join(L7))
    os.replace(tmp, p7)
    print("ported %d chunks into %s" % (len(todo), p7))


if __name__ == "__main__":
    main()
