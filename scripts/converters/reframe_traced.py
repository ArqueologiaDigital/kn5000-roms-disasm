#!/usr/bin/env python3
"""reframe_traced.py -- source spans that control flow executes in another framing, re-spelled as that code.

QUESTION THIS ANSWERS / JOB IT DOES
  A control-flow trace of a whole KN5000 maincpu image (scripts/converters/scoop_reframe.py
  trace: MAME unidasm recursive descent) entered at every address a `call`/`calr` of the tree
  targets and every code label a `.long` table holds reaches ~255,000 instructions in v10 with 3
  conflicts.  Where a traced instruction STARTS inside a source line that is not a macro
  invocation, the source frames those bytes differently from the way the CPU executes them --
  `.asciz " E@!"` in storage/flash_floppy_handlers.s, a `.byte` row, or an instruction
  straddling two real ones (131 starts in v10, 2026-10-03).  For each such place this takes
  the span from the last traced instruction start before it that is also a source-line start,
  to the first traced start after it from which four consecutive traced instructions are
  source-line starts again; the traced instructions must tile the span with no gap.  The span
  is re-spelled as code by scoop_reframe.py apply (whole-image byte check, unidasm
  cross-check, labels and comments carried).  Labels inside a rendered instruction are a hard
  refusal there, and the span is left.

USAGE
  make all
  python3 scripts/converters/reframe_traced.py --image v10 [--apply] [--report OUT.json]
"""
import argparse
import collections
import glob
import json
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
sys.path.insert(0, os.path.join(REPO, "scripts", "tools"))
import scoop_reframe as SR                    # noqa: E402
import place_labels                           # noqa: E402

NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
CALL = re.compile(r'^\s*(?:[A-Za-z_][\w.$]*:)?\s*(?:call|calr)\s+(?:[a-z]+\s*,\s*)?([A-Za-z_][\w.$]*)\s*$', re.I)
LONG = re.compile(r'^\s*(?:[A-Za-z_][\w.$]*:)?\s*\.(?:long|4byte)\s+([^;]*)', re.I)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True, choices=("v10", "v9", "v7"))
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--report")
    a = ap.parse_args()
    v = a.image
    addr = {}
    for l in subprocess.run([NM, "--defined-only", os.path.join(REPO, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % v)],
                            capture_output=True, text=True, check=True).stdout.splitlines():
        x, t, n = l.split()
        addr[n] = int(x, 16)
    p = place_labels.Planner(v)

    def code_line_start(x):
        w = p.where(x)
        return bool(w) and w[0] == x and place_labels.snb.drc.classify_line(p.lines(w[1])[w[2]], p.macros)[0] == "code"
    ents = set()
    for f in glob.glob(os.path.join(REPO, v, "maincpu", "**", "*.s"), recursive=True):
        for l in open(f, "rb").read().decode("latin-1").split("\n"):
            c = l.split(";")[0]
            m = CALL.match(c)
            if m and m.group(1) in addr:
                ents.add(addr[m.group(1)])
            m = LONG.match(c)
            if m:
                for it in m.group(1).split(","):
                    it = it.strip()
                    if it in addr and code_line_start(addr[it]):
                        ents.add(addr[it])
    insns, ext, conflicts = SR.trace(v, 0xE00000, 0x1000000, sorted(ents))
    starts = set(s[0] for s in p.spans)
    macros = set(k.lower() for k in p.macros)
    order = sorted(insns)
    idx = {x: i for i, x in enumerate(order)}
    st, rows = collections.Counter(), []
    spans = {}
    for x in order:
        if x in starts:
            continue
        w = p.where(x)
        if not w:
            continue
        code = re.sub(r'^[A-Za-z_][\w.$]*:', '', p.lines(w[1])[w[2]].split(";")[0]).strip()
        if code and code.split()[0].lower() in macros:
            continue
        i = idx[x]
        j = i
        while j > 0 and order[j] not in starts:
            j -= 1
        S = order[j]
        k, E = i + 1, None
        while k + 3 < len(order):
            if all(order[k + q] in starts for q in range(4)) and \
                    all(order[k + q] + insns[order[k + q]][0] == order[k + q + 1] for q in range(3)):
                E = order[k]
                break
            k += 1
        if E is None or not (0 < E - S <= 128):
            st["no clean resync"] += 1
            continue
        if any(order[q] + insns[order[q]][0] != order[q + 1] for q in range(j, idx[E])):
            st["gap in the traced code"] += 1
            continue
        ws, we = p.where(S), p.where(E)
        if not ws or not we or ws[1] != we[1]:
            st["crosses a file"] += 1
            continue
        spans[(ws[1], S)] = E
    merged = collections.defaultdict(list)
    for (rel, S), E in sorted(spans.items()):
        L = merged[rel]
        if L and S < L[-1][1]:
            L[-1] = (L[-1][0], max(L[-1][1], E))
        else:
            L.append((S, E))
    n_spans = sum(len(x) for x in merged.values())
    st["spans"] = n_spans
    print("%s: %d traced insns, %d conflicts; %s" % (v, len(insns), len(conflicts), dict(st)))
    for rel, L in merged.items():
        for S, E in L:
            rows.append(dict(file=rel, start=hex(S), end=hex(E)))
    if a.apply:
        done = 0
        for rel, L in sorted(merged.items()):
            spec = [dict(file="%s/maincpu/%s" % (v, rel), start="0x%X" % S, end="0x%X" % E,
                         segments=[dict(kind="code", len=E - S)]) for S, E in L]
            for chunk in ([spec] if len(spec) > 1 else []) + [[x] for x in spec]:
                path = os.path.join(SR.SCRATCH, "rft-%s.json" % os.getpid())
                json.dump(chunk, open(path, "w"))
                r = subprocess.run([sys.executable, os.path.join(REPO, "scripts", "converters", "scoop_reframe.py"),
                                    "apply", "--image", v, "--spec", path], capture_output=True, text=True)
                out = r.stdout + r.stderr
                if r.returncode == 0 and "REJECT" not in out and "refus" not in out.lower():
                    done += len(chunk)
                    if len(chunk) > 1:
                        break
                elif len(chunk) == 1:
                    st["refused by scoop_reframe"] += 1
            pth = os.path.join(REPO, v, "maincpu", rel)
            t = open(pth, "rb").read().decode("latin-1")
            sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
            import reframe_prefix_bytes as RPB
            t2 = "\n".join(RPB.tidy(l) for l in t.split("\n"))
            if t2 != t:
                open(pth, "wb").write(t2.encode("latin-1"))
        st["applied"] = done
        print("%s: %s" % (v, dict(st)))
    if a.report:
        json.dump(dict(rows=rows, conflicts=[list(c) for c in conflicts]), open(a.report, "w"), indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
