#!/usr/bin/env python3
r"""WHICH DATA REGIONS ARE THE TARGET OF A CONTROL TRANSFER, AND FROM WHERE?

QUESTION THIS ANSWERS
---------------------
`notes/DATA-CENSUS-2026-09-02.md` §6 reports **1,089 regions / 85,536 B** of
"code-suspect" data: a label at or inside a DATA region is named as the operand
of a `call`/`calr`/`jp`/`jr`/`jrl`/`djnz` somewhere in the same source tree.
That flag is the strongest of the three §6 flags because it is a *reference*,
not a name.  But the census only COUNTS it.  This script ENUMERATES it, so the
sites can be adjudicated one at a time.

It reproduces the census's own definition (same `CTRL_RE`/`IDENT_RE`/`LABEL_RE`,
same latin-1 read) and additionally records, for every flagged label, **every
source site that refers to it** -- which is what adjudication needs and what the
census throws away.

⚠ THIS IS A SCREEN, NOT A VERDICT.  A `call Foo` written inside a region that is
itself misframed data emits the right ROM bytes and still means nothing at
runtime.  The census's own record (`notes/DEBT-INVENTORY-2026-09-02.md`) has one
lane proving 13 such transfers into IC19 were ALL phantoms.  So each site's
referring context must be graded separately; that is `--refsites`.

THE NULL
--------
The tempting null -- the same rate over the three images established as PURE
DATA (`table_data`, `custom_data` IC19, `prom_d`) -- is WORTHLESS HERE and this
script does not offer it.  Those images contain no instruction statements at
all, so no control transfer can exist in them to be counted: the rate is ZERO
BY CONSTRUCTION whatever the flag is worth.  That is exactly the defect that
got the "46x undecodable leading byte" finding retracted, and the pure-data
columns printed by --census are labelled so nobody reads them as a null.

The real null is in `code_suspect_adjudicate.py --null`: the C-compiled
`.incbin` regions INSIDE the same code-bearing images, which are data on an
authority independent of every decoder and framing judgement here.  It scores
0 of 11,179, with the numeric-transfer confound checked at 0 of 711.

RUN
    python3 scripts/analysis/code_suspect_sites.py --census
    python3 scripts/analysis/code_suspect_sites.py --refsites   # per-site detail
    python3 scripts/analysis/code_suspect_sites.py --json out.json

TOOLCHAIN.  This script reads SOURCE TEXT only.  It never invokes llvm-mc, so
its numbers do not depend on the shared, mutable toolchain build.  (The census
figure it is compared against was taken at tlcs900_backend@6f456a19f05b.)
"""
import json
import os
import re
import sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

LABEL_RE = re.compile(r'^([A-Za-z_.$][\w.$@]*):')
CTRL_RE = re.compile(r'^(call|calr|jp|jr|jrl|djnz)\b', re.I)
IDENT_RE = re.compile(r'\b([A-Za-z_][\w.$]{2,})\b')

# Directives that emit bytes.  `.incbin` emits bytes too and is debt of its own.
DATA_DIR = re.compile(r'^\.(byte|word|short|long|hword|quad|ascii|asciz|asciiz'
                      r'|string|space|zero|fill|incbin|2byte|4byte|8byte)\b', re.I)
# Anything else with a leading dot is a non-emitting pseudo-op for our purpose
# (.section, .globl, .align, .set, .equ, .include is handled separately).
PSEUDO_RE = re.compile(r'^\.')

MIRRORS = [
    ("v10", "v10/maincpu"), ("v9", "v9/maincpu"), ("v7", "v7/maincpu"),
    ("v142", "v142/subcpu"), ("subboot", "subcpu/boot"),
    ("tabledata", "table_data"), ("customdata", "custom_data"),
    ("hdae5000", "hdae5000"),
    ("wsa1", "wsa1"),
]
PURE_DATA = {"tabledata", "customdata"}   # prom_d is inside the wsa1 mirror


def strip_comment(line):
    """Drop a ';' or '#' comment, respecting quotes (mirrors the census)."""
    out, q = [], None
    for ch in line:
        if q:
            out.append(ch)
            if ch == q:
                q = None
            continue
        if ch in '"\'':
            q = ch
            out.append(ch)
            continue
        if ch in ';#':
            break
        if ch == '/' and out and out[-1] == '/':
            out.pop()
            break
        out.append(ch)
    return "".join(out)


def scan(mirror):
    """-> files: {rel: [lines]}, labels: {name: [(rel,line)]},
                 refs: {name: [(rel,line,text)]}"""
    root = os.path.join(ROOT, mirror)
    files, labels, refs = {}, defaultdict(list), defaultdict(list)
    for dp, _, fn in os.walk(root):
        for f in sorted(fn):
            if not f.endswith(".s"):
                continue
            p = os.path.join(dp, f)
            rel = os.path.relpath(p, root)
            L = open(p, encoding="latin-1").read().split("\n")
            files[rel] = L
            for i, ln in enumerate(L):
                c = strip_comment(ln).strip()
                m = LABEL_RE.match(c)
                if m:
                    labels[m.group(1)].append((rel, i))
                    c = c[m.end():].strip()
                if CTRL_RE.match(c):
                    ops = c.split(None, 1)[1] if " " in c else ""
                    for g in IDENT_RE.findall(ops):
                        refs[g].append((rel, i, ln.rstrip()))
    return files, labels, refs


def first_emitting(L, i):
    """From the line AFTER index i, the first line that emits bytes.
    -> (index, 'data'|'code', text) or None."""
    for k in range(i + 1, min(i + 400, len(L))):
        c = strip_comment(L[k]).strip()
        if not c:
            continue
        m = LABEL_RE.match(c)
        if m:
            c = c[m.end():].strip()
            if not c:
                continue
        if DATA_DIR.match(c):
            return (k, "data", L[k].rstrip())
        if PSEUDO_RE.match(c):
            continue          # .align/.globl/.section/... emit nothing here
        return (k, "code", L[k].rstrip())
    return None


def run_extent(L, i):
    """Bytes emitted by the contiguous data run starting at line i, and the
    index of the first line after it.  Counts BYTES, not directives -- the lane
    brief is explicit that a directive count is the wrong instrument."""
    n, k = 0, i
    while k < len(L):
        c = strip_comment(L[k]).strip()
        if not c:
            k += 1
            continue
        m = LABEL_RE.match(c)
        if m:
            if k > i:
                break                       # a new label ends the run
            c = c[m.end():].strip()
            if not c:
                k += 1
                continue
        if not DATA_DIR.match(c):
            if PSEUDO_RE.match(c):
                break
            break
        n += emitted_bytes(c)
        k += 1
    return n, k


def emitted_bytes(c):
    d = c.split(None, 1)[0].lower().lstrip('.')
    ops = c.split(None, 1)[1] if " " in c else ""
    ops = ops.strip()
    if d in ("byte", "2byte") and d == "byte":
        return len(split_ops(ops))
    if d in ("word", "short", "hword", "2byte"):
        return 2 * len(split_ops(ops))
    if d in ("long", "4byte"):
        return 4 * len(split_ops(ops))
    if d in ("quad", "8byte"):
        return 8 * len(split_ops(ops))
    if d in ("space", "zero", "fill"):
        try:
            return int(ops.split(",")[0].strip(), 0)
        except ValueError:
            return 0
    if d in ("ascii", "asciz", "asciiz", "string"):
        return ascii_len(ops) + (0 if d == "ascii" else 1)
    if d == "incbin":
        mm = re.search(r'"([^"]+)"', ops)
        if mm:
            for base in ("", "v10/maincpu", "v9/maincpu", "v7/maincpu", "wsa1"):
                p = os.path.join(ROOT, base, mm.group(1))
                if os.path.isfile(p):
                    return os.path.getsize(p)
        return 0
    return 0


def split_ops(ops):
    out, depth, cur = [], 0, ""
    for ch in ops:
        if ch in "([":
            depth += 1
        elif ch in ")]":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur)
    return [x for x in out if x.strip()]


def ascii_len(ops):
    tot = 0
    for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', ops):
        s, i = m.group(1), 0
        while i < len(s):
            if s[i] == "\\":
                i += 2
                if i - 1 < len(s) and s[i - 2] == "\\" and s[i - 1] in "01234567":
                    while i < len(s) and s[i] in "01234567":
                        i += 1
            else:
                i += 1
            tot += 1
    return tot


def collect(mirror):
    files, labels, refs = scan(mirror)
    sites = []
    for name, places in labels.items():
        if name not in refs:
            continue
        for (rel, li) in places:
            L = files[rel]
            fe = first_emitting(L, li)
            if not fe or fe[1] != "data":
                continue
            nb, end = run_extent(L, fe[0])
            # self-reference only?  (a label referred to solely from its own run)
            ext = [r for r in refs[name] if not (r[0] == rel and li <= r[1] < end)]
            sites.append(dict(label=name, rel=rel, line=li + 1,
                              data_line=fe[0] + 1, first=fe[2].strip()[:110],
                              bytes=nb, nrefs=len(refs[name]),
                              nrefs_external=len(ext),
                              refs=[dict(rel=a, line=b + 1, text=c.strip()[:110])
                                    for (a, b, c) in refs[name]]))
    return sites


def main():
    args = sys.argv[1:]
    jsonout = None
    if "--json" in args:
        jsonout = args[args.index("--json") + 1]
        args = args[:args.index("--json")] + args[args.index("--json") + 2:]
    want = [a for a in args if not a.startswith("-")]
    allsites = {}
    for key, mirror in MIRRORS:
        if want and key not in want:
            continue
        allsites[key] = collect(mirror)

    if "--refsites" in args:
        for key, s in allsites.items():
            for r in sorted(s, key=lambda x: -x["bytes"]):
                print("%-10s %-40s %s:%d  %6d B  refs=%d(ext %d)" % (
                    key, r["label"][:40], r["rel"], r["line"], r["bytes"],
                    r["nrefs"], r["nrefs_external"]))
                for q in r["refs"][:8]:
                    print("        <- %s:%d  %s" % (q["rel"], q["line"], q["text"]))
        return

    print("CONTROL-TRANSFER-TARGETED DATA REGIONS (source-text screen)")
    print("  %-10s %8s %10s %8s" % ("image", "sites", "bytes", "ext-ref"))
    tot_s = tot_b = 0
    for key, s in allsites.items():
        b = sum(x["bytes"] for x in s)
        e = sum(1 for x in s if x["nrefs_external"])
        print("  %-10s %8d %10d %8d%s" % (
            key, len(s), b, e,
            "   <- 0 BY CONSTRUCTION, not a null: no instructions here"
            if key in PURE_DATA else ""))
        if key not in PURE_DATA:
            tot_s += len(s)
            tot_b += b
    print("  %-10s %8d %10d" % ("TOTAL", tot_s, tot_b))
    if jsonout:
        json.dump(allsites, open(jsonout, "w"))
        print("  wrote %s" % jsonout)


if __name__ == "__main__":
    main()
