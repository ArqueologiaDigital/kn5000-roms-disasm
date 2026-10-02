#!/usr/bin/env python3
"""insert_labels.py -- put named labels at v10 addresses, and at the same code in v9 and v7.

QUESTION THIS ANSWERS / JOB IT DOES
  A routine or a table often has no label of its own: it is reached through a positional
  alias (`.set DefaultHandler_Ret_0x1, DefaultHandler_Ret + 1`), or only its parent is named and
  a header has to cite "the routine at 0xEF60AE".  Naming it means finding, in each version's
  tree, the source line that emits that address -- which no grep can do (the sources carry no
  addresses).  For each requested label this:
    * takes the v10 address;
    * maps it to v9 and v7 with the anchors of scripts/renaming/harmonize_version_labels.py
      (labels both ELFs define under one name; equal deltas on both sides; the 12 ROM bytes
      at both addresses identical) -- a version where that fails is reported and skipped;
    * finds the line that starts exactly at that address (the census marker mirror,
      symbolize_numeric_branches.build_map, refused unless it reproduces the dump) and puts
      `NAME:` in front of it, with optional header comment lines;
    * when the byte check fails (relocated pointers) but the version defines the same
      positional alias, the alias's address is used -- the alias asserts the correspondence;
    * optionally retires a positional alias of the same address: its `.set` line goes and its
      uses take NAME (a word-bounded replacement in that tree).
  A label emits no byte: `make gate-all` proves it.

USAGE
  make all
  python3 scripts/tools/insert_labels.py SPEC.json [--trees v10,v9,v7] [--apply]
  SPEC.json: [{"name": "DisplayMode_Dispatch", "v10": "0xEF61E9",
               "alias": "DefaultHandler_Ret_0x1", "header": ["; one line", "; another"]}]
"""
import argparse
import bisect
import collections
import json
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
sys.path.insert(0, os.path.join(REPO, "scripts", "analysis"))
sys.path.insert(0, os.path.join(REPO, "scripts", "renaming"))
import harmonize_version_labels as hv          # noqa: E402
import symbolize_numeric_branches as snb       # noqa: E402


def mapper(frm, to):
    sF, _ = hv.syms(frm)
    sT, _ = hv.syms(to)
    rF = open(os.path.join(REPO, "original_ROMs/kn5000_%s_program.rom" % frm), "rb").read()
    rT = open(os.path.join(REPO, "original_ROMs/kn5000_%s_program.rom" % to), "rb").read()
    anch = sorted((sF[n], sF[n] - sT[n]) for n in sF if n in sT and 0xE00000 <= sF[n] < 0x1000000)
    keys = [x for x, _ in anch]

    def f(A):
        k = bisect.bisect_right(keys, A) - 1
        if k < 0 or k + 1 >= len(anch) or anch[k][1] != anch[k + 1][1]:
            return None
        B = A - anch[k][1]
        if rF[A - 0xE00000:A - 0xE00000 + 12] != rT[B - 0xE00000:B - 0xE00000 + 12]:
            return None
        return B
    return f


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("spec")
    ap.add_argument("--trees", default="v10,v9,v7")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    spec = json.load(open(a.spec))
    for tree in a.trees.split(","):
        conv = (lambda x: x) if tree == "v10" else mapper("v10", tree)
        img = snb.image_by_key(tree)
        srcroot = os.path.join(REPO, img["mirror"])
        marks, addrs, spans, rom_ok, src, macros = snb.build_map(img, srcroot)
        if not rom_ok:
            sys.exit("%s: marker mirror does not reproduce the dump: refusing" % tree)
        start_of = {s[0]: s for s in spans}
        texts, inserts, retire = {}, collections.defaultdict(list), {}
        tsyms = hv.syms(tree)[0] if tree != "v10" else {}
        for e in spec:
            A = conv(int(e["v10"], 16))
            if A is None and e.get("alias") in tsyms:
                A = tsyms[e["alias"]]           # the version's own alias says where it is
                print("%s: %s -- placed by its alias %s" % (tree, e["name"], e["alias"]))
            if A is None:
                print("%s: %s -- no verified counterpart of v10 %s, skipped" % (tree, e["name"], e["v10"]))
                continue
            sp = start_of.get(A)
            if not sp:
                print("%s: %s -- 0x%X is inside a line, skipped" % (tree, e["name"], A))
                continue
            inserts[sp[2]].append((sp[3], e))
            if e.get("alias"):
                retire[e["alias"]] = e["name"]
            print("%s: %s at 0x%X (%s:%d)" % (tree, e["name"], A, sp[2], sp[3] + 1))
        if not a.apply:
            continue
        for rel, items in inserts.items():
            p = os.path.join(srcroot, rel)
            L = open(p, "rb").read().decode("latin-1").split("\n")
            for li, e in sorted(items, key=lambda x: -x[0]):
                L[li:li] = list(e.get("header", [])) + ["%s:" % e["name"]]
            open(p, "wb").write("\n".join(L).encode("latin-1"))
        if retire:
            pat = re.compile(r'(?<![\w.$])(%s)(?![\w$]|\.\w)' % "|".join(map(re.escape, retire)))
            setl = re.compile(r'^\s*\.set\s+(%s)\s*,' % "|".join(map(re.escape, retire)))
            for dirpath, _, fns in os.walk(os.path.join(REPO, tree, "maincpu")):
                for fn in fns:
                    if not fn.endswith((".s", ".c", ".h")):
                        continue
                    p = os.path.join(dirpath, fn)
                    t = open(p, "rb").read().decode("latin-1")
                    if not pat.search(t):
                        continue
                    L = [l for l in t.split("\n") if not setl.match(l)]
                    t2 = pat.sub(lambda m: retire[m.group(1)], "\n".join(L))
                    open(p, "wb").write(t2.encode("latin-1"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
