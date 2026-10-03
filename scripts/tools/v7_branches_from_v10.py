#!/usr/bin/env python3
r"""v7_branches_from_v10.py -- name a refused v7 numeric branch from the v10 line that does the same thing.

QUESTION THIS ANSWERS / WHAT IT DOES
    scripts/converters/symbolize_numeric_branches.py refuses some numeric branch operands (R3 "absurd
    neighbourhood", R5, R6 ...) because nothing proves that the line is code.  v10 is the reference tree:
    when the same routine is decoded and named there, the v10 line is that proof.  For every site in a
    --report of the v7 image this tool:
      1. takes the nearest v7 label at or below the site and the site's offset from it;
      2. requires that the same label exist in v10, and that a v10 source line start at label + offset
         with the same mnemonic, the same condition and the same byte length;
      3. requires that the v10 line name its target with a symbol N, and that N be defined in v7
         at exactly the v7 site's numeric target.
    Only then is the v7 operand rewritten to N.  The bytes cannot change: the v7 build gives N the value
    the number had.  `make gate-all` checks that anyway.  Every site is printed with its verdict.

RUN
    make all
    python3 scripts/converters/symbolize_numeric_branches.py --image v7 --report R.json
    python3 scripts/tools/v7_branches_from_v10.py --report R.json [--apply]
    make gate-all
"""
import argparse
import bisect
import json
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "scripts", "tools"))
import place_labels as PL  # noqa: E402

NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
BR = re.compile(r'^(?P<pre>\s*)(?P<mn>jr|jrl|calr|call|jp|djnz)(?P<ws>\s+)(?:(?P<cc>[a-z]+)\s*,\s*)?(?P<op>[^;]*?)(?P<post>\s*(?:;.*)?)$', re.I)


def syms(tree):
    elf = os.path.join(REPO, "rebuilt_ROMs", "kn5000_%s_program.llvm.elf" % tree)
    n2a, rows = {}, []
    for l in subprocess.run([NM, "--defined-only", elf], capture_output=True, text=True, check=True).stdout.split("\n"):
        p = l.split()
        if len(p) == 3 and p[1] in "tT":
            a = int(p[0], 16)
            n2a[p[2]] = a
            rows.append((a, p[2]))
    rows.sort()
    return n2a, rows


def code_of(line):
    return line.split(";", 1)[0].strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--report", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    rep = json.load(open(a.report))["report"]
    sites = [x for v in rep.values() for x in v]
    P7, P10 = PL.Planner("v7"), PL.Planner("v10")
    n2a7, rows7 = syms("v7")
    n2a10, _ = syms("v10")
    addrs7 = [r[0] for r in rows7]
    edits, done, why = {}, 0, {}
    for s in sites:
        sa, tgt = int(s["src_addr"], 16), int(s["target"], 16)
        w7 = P7.where(sa)
        if not w7 or w7[0] != sa:
            why[s["src"]] = "v7 site is not a line start"
            continue
        _, rel7, li7 = w7
        t7 = P7.lines(rel7)[li7]
        m7 = BR.match(code_of(t7))
        if not m7:
            why[s["src"]] = "v7 line is not a branch: %r" % t7
            continue
        k = bisect.bisect_right(addrs7, sa) - 1
        # nearest label at or below the site that v10 also defines
        lab = None
        while k >= 0 and sa - rows7[k][0] < 0x400:
            if rows7[k][1] in n2a10:
                lab = rows7[k][1]
                break
            k -= 1
        if not lab:
            why[s["src"]] = "no shared label within 0x400 bytes above"
            continue
        off = sa - n2a7[lab]
        s10 = n2a10[lab] + off
        w10 = P10.where(s10)
        if not w10 or w10[0] != s10:
            why[s["src"]] = "v10 %s+%d is not a line start" % (lab, off)
            continue
        _, rel10, li10 = w10
        t10 = P10.lines(rel10)[li10]
        m10 = BR.match(code_of(t10))
        if not m10 or m10["mn"].lower() != m7["mn"].lower() or (m10["cc"] or "").lower() != (m7["cc"] or "").lower():
            why[s["src"]] = "v10 line differs: %r vs %r" % (t10.strip(), t7.strip())
            continue
        k7 = bisect.bisect_right(P7.starts, sa)
        k10 = bisect.bisect_right(P10.starts, s10)
        if P7.spans[k7 - 1][1] - sa != P10.spans[k10 - 1][1] - s10:
            why[s["src"]] = "lengths differ"
            continue
        name = m10["op"].strip()
        if not re.match(r'^[A-Za-z_][\w.$]*$', name):
            why[s["src"]] = "v10 operand is not a plain symbol: %r" % name
            continue
        if n2a7.get(name) != tgt:
            why[s["src"]] = "v7 has no %s at 0x%06X (v7: %s)" % (name, tgt, hex(n2a7[name]) if name in n2a7 else None)
            continue
        new = m7["pre"] + m7["mn"] + m7["ws"] + ((m7["cc"] + ", ") if m7["cc"] else "") + name + m7["post"]
        edits.setdefault(rel7, {})[li7] = (t7, new)
        why[s["src"]] = "OK -> %s (v10 %s+%d)" % (name, lab, off)
        done += 1
    for k, v in sorted(why.items()):
        print("%-50s %s" % (k, v))
    print("sites %d, named %d%s" % (len(sites), done, "" if a.apply else " (dry run)"))
    if a.apply:
        for rel, ed in edits.items():
            p = os.path.join(REPO, P7.img["mirror"], rel)
            L = open(p, "rb").read().decode("latin-1").split("\n")
            for li, (old, new) in ed.items():
                assert L[li] == old, (rel, li)
                L[li] = new
            data = "\n".join(L).encode("latin-1")
            with open(p + ".tmp", "wb") as fh:
                fh.write(data)
            os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
