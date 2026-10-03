#!/usr/bin/env python3
r"""v7_table_entries_from_v10.py -- replace v7 references written as `Alias + N` with the label v10 uses there.

QUESTION THIS ANSWERS / WHAT IT DOES
    v7 still reaches into some code blocks through positional aliases: `.set X_0xNN, X + NN` in
    shared/positional_labels.s, used as `.long X_0xNN + 46` or `jp X_0xNN` (dashboard column posalias).
    v10 has the same tables with real labels.  For every v7 line that names one of the --alias symbols
    this tool:
      1. computes the v7 address A that the operand denotes (from the v7 ELF);
      2. takes the nearest label above the v7 line that v10 also defines, and the line's offset from it;
      3. requires that v10 have a line at that label + offset with the same directive or mnemonic, whose
         operand is a plain symbol NAME -- or v10's own `Label + off`, taken as written when it evaluates
         to exactly A in v7;
      4. requires that NAME be undefined in v7 or defined at exactly A, and that a v7 source line start
         at A when NAME has to be created there.
    With --nearest, a `.long` that v10 cannot speak for is written as the nearest real v7 label at or
    below A (one that starts a source line, never an alias) plus the offset, within 0x400 bytes: the
    form v10 itself uses for these tables.
    Then NAME is placed at A in v7 (scripts/tools/place_labels.Planner) when needed, and the operand is
    rewritten to NAME.  The bytes cannot change: NAME's v7 value is A, the value the old expression had.
    `make gate-all` checks that anyway.  Every line is printed with its verdict.

RUN
    make all
    python3 scripts/tools/v7_table_entries_from_v10.py --alias Scoop_SoundEditorData_0xEB ... [--apply]
    make gate-all
"""
import argparse
import bisect
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts", "tools"))
import place_labels as PL  # noqa: E402

NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
OPLINE = re.compile(r'^(?P<pre>\s*(?:[A-Za-z_.$][\w.$]*:)?\s*)(?P<op>\.long|jp|call|calr|jr|jrl)(?P<ws>\s+)(?P<cc>[a-z]+\s*,\s*)?'
                    r'(?P<expr>[A-Za-z_.$][\w.$]*\s*(?:[+-]\s*(?:0x[0-9A-Fa-f]+|\d+))?)(?P<post>\s*(?:;.*)?)$')


def syms(tree):
    elf = os.path.join(REPO, "rebuilt_ROMs", "kn5000_%s_program.llvm.elf" % tree)
    n2a, rows = {}, []
    for l in subprocess.run([NM, "--defined-only", elf], capture_output=True, text=True, check=True).stdout.split("\n"):
        p = l.split()
        if len(p) == 3:
            n2a[p[2]] = int(p[0], 16)
            if p[1] in "tT":
                rows.append((int(p[0], 16), p[2]))
    rows.sort()
    return n2a, rows


def value(expr, n2a):
    m = re.match(r'^([A-Za-z_.$][\w.$]*)\s*(?:([+-])\s*(0x[0-9A-Fa-f]+|\d+))?$', expr.strip())
    v = n2a[m.group(1)]
    if m.group(2):
        v = v + int(m.group(3), 0) if m.group(2) == "+" else v - int(m.group(3), 0)
    return v


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--alias", action="append", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--nearest", action="store_true",
                    help="for a .long that v10 cannot speak for: nearest real v7 label at or below the target + offset")
    a = ap.parse_args()
    P7, P10 = PL.Planner("v7"), PL.Planner("v10")
    n2a7, rows7 = syms("v7")
    n2a10, _ = syms("v10")
    addrs7 = [r[0] for r in rows7]
    alias_re = re.compile(r'\b(%s)\b' % "|".join(map(re.escape, a.alias)))
    edits, newlabels, verdict = {}, {}, []
    for (sa, se, rel, li) in P7.spans:
        t7 = P7.lines(rel)[li]
        if not alias_re.search(t7.split(";", 1)[0]):
            continue
        m7 = OPLINE.match(t7)
        if not m7:
            verdict.append((rel, li, "not a single-operand .long/branch: %r" % t7.strip()))
            continue
        A = value(m7["expr"], n2a7)
        k = bisect.bisect_right(addrs7, sa) - 1
        lab = None
        while k >= 0 and sa - rows7[k][0] < 0x2000:
            if rows7[k][1] in n2a10:
                lab = rows7[k][1]
                break
            k -= 1
        if not lab:
            verdict.append((rel, li, "no shared label above"))
            continue
        s10 = n2a10[lab] + (sa - n2a7[lab])
        w10 = P10.where(s10)
        if not w10 or w10[0] != s10:
            verdict.append((rel, li, "v10 %s+%d is not a line start" % (lab, sa - n2a7[lab])))
            continue
        t10 = P10.lines(w10[1])[w10[2]]
        m10 = OPLINE.match(t10)
        if not m10 or m10["op"] != m7["op"]:
            verdict.append((rel, li, "v10 line differs: %r" % t10.strip()))
            continue
        name = m10["expr"].strip()
        if not re.match(r'^[A-Za-z_.$][\w.$]*$', name):
            # v10 writes `Label + off` itself: take it when it means the same address in v7
            base = re.match(r'^([A-Za-z_.$][\w.$]*)', name).group(1)
            if base in a.alias or base not in n2a7 or value(name, n2a7) != A:
                verdict.append((rel, li, "v10 expression %r is not 0x%06X in v7" % (name, A)))
                continue
            new = m7["pre"] + m7["op"] + m7["ws"] + (m7["cc"] or "") + name + m7["post"]
            edits.setdefault(rel, {})[li] = (t7, new)
            verdict.append((rel, li, "OK -> %s" % name))
            continue
        if name in a.alias:
            verdict.append((rel, li, "v10 uses the alias too"))
            continue
        have = n2a7.get(name, newlabels.get(name))
        if have is not None and have != A:
            verdict.append((rel, li, "v7 defines %s at 0x%06X, not 0x%06X" % (name, have, A)))
            continue
        if have is None:
            w = P7.where(A)
            if not w or w[0] != A:
                verdict.append((rel, li, "0x%06X is not a v7 line start (for %s)" % (A, name)))
                continue
            newlabels[name] = A
        new = m7["pre"] + m7["op"] + m7["ws"] + (m7["cc"] or "") + name + m7["post"]
        edits.setdefault(rel, {})[li] = (t7, new)
        verdict.append((rel, li, "OK -> %s" % name))
    if a.nearest:
        # second pass, `.long` only: a line v10 cannot speak for is written as the nearest real v7
        # label at or below its target (a label that starts a source line, not an alias) + offset,
        # the form v10 itself uses for these tables
        for j, (rel, li, v) in enumerate(verdict):
            if v.startswith("OK"):
                continue
            t7 = P7.lines(rel)[li]
            m7 = OPLINE.match(t7)
            if not m7 or m7["op"] != ".long":
                continue
            A = value(m7["expr"], n2a7)
            k = bisect.bisect_right(addrs7, A) - 1
            while k >= 0:
                nm, la = rows7[k][1], rows7[k][0]
                w = P7.where(la)
                if nm not in a.alias and not re.search(r'_0x[0-9A-Fa-f]+$', nm) and w and w[0] == la \
                        and any(re.match(r'^%s:' % re.escape(nm), x) for x in P7.lines(w[1])[max(0, w[2] - 4):w[2] + 1]):
                    break
                k -= 1
            if k < 0 or A - rows7[k][0] > 0x400:
                continue
            nm, la = rows7[k][1], rows7[k][0]
            expr = nm if A == la else "%s+0x%X" % (nm, A - la)
            new = m7["pre"] + m7["op"] + m7["ws"] + expr + m7["post"]
            edits.setdefault(rel, {})[li] = (t7, new)
            verdict[j] = (rel, li, "OK (nearest v7 label) -> %s" % expr)
    for rel, li, v in verdict:
        print("%s:%d  %s" % (rel, li + 1, v))
    ok = sum(1 for v in verdict if v[2].startswith("OK"))
    print("lines %d, rewritten %d, labels to place %d%s" % (len(verdict), ok, len(newlabels), "" if a.apply else " (dry run)"))
    if not a.apply:
        return
    for name, A in sorted(newlabels.items(), key=lambda x: x[1]):
        r = P7.add(A, name)
        assert r == "line-start", (name, hex(A), r)
    for rel, ed in edits.items():
        L = P7.lines(rel)
        for li, (old, new) in ed.items():
            assert L[li] == old, (rel, li)
            L[li] = new
    P7.apply()
    P7.write()


if __name__ == "__main__":
    main()
