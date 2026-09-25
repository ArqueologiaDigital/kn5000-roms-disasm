#!/usr/bin/env python3
r"""seqeng_v7_call_targets.py -- what do lane seqeng's still-numeric v7 calls call?

QUESTION ANSWERED
-----------------
"Each `call 16635550` left numeric in v7's sequencer files targets an address
that has no label in v7 (it sits inside another file's coarse object).  What
is that routine called in v10?"  -- a worklist for whoever owns the TARGET
file: put a label there (the v10 name) and the call becomes symbolic.

HOW
---
For each numeric absolute `call`/`jp` in the v7 file, take the call site's
v7 bytes with the 24-bit target masked out, plus 8 bytes before and after,
and look for exactly one match of that context in the v10 dump (the target
field again masked).  v10's own target there is looked up in v10's build.
The v7 target's containing label (+offset) comes from v7's build.

RUN
    python3 scripts/analysis/seqeng_v7_call_targets.py sequencer/sequencer_engine.s [...more files]
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from seqeng_line_map import line_map, ROOT  # noqa: E402

NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
B = 0xE00000


def syms(v):
    elf = os.path.join(ROOT, "rebuilt_ROMs", "kn5000_%s_program.llvm.elf" % v)
    rows = []
    for ln in subprocess.run([NM, "-n", elf], capture_output=True, text=True).stdout.split("\n"):
        p = ln.split()
        if len(p) >= 3 and p[1] in "tT" and not p[2].startswith((".", "__")):
            rows.append((int(p[0], 16), p[2]))
    rows.sort()
    return rows


def owner(rows, a):
    import bisect
    i = bisect.bisect_right([r[0] for r in rows], a) - 1
    return rows[i] if i >= 0 else (0, "?")


def main():
    files = sys.argv[1:]
    r7 = open(os.path.join(ROOT, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
    r10 = open(os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
    s7, s10 = syms("v7"), syms("v10")
    exact10 = {}
    for a, n in s10:
        exact10.setdefault(a, []).append(n)
    maps = line_map("v7", files)
    seen = {}
    for rel in files:
        src = open(os.path.join(ROOT, "v7", "maincpu", rel), encoding="latin-1").read().split("\n")
        for ln, ad, sz in maps[rel]:
            c = src[ln - 1].split(";")[0].strip()
            m = re.match(r'^(call|jp)\s+(\d+)$', c)
            if not m or sz != 4:
                continue
            tgt = int(m.group(2))
            off = ad - B
            ctx_b, ctx_a = r7[off - 8:off + 1], r7[off + 4:off + 12]
            hits = []
            i = r10.find(ctx_b)
            while i >= 0 and len(hits) < 3:
                if r10[i + 9 + 3:i + 9 + 3 + 8] == ctx_a:
                    hits.append(i + 8)
                i = r10.find(ctx_b, i + 1)
            v10name = "?"
            if len(hits) == 1:
                t10 = int.from_bytes(r10[hits[0] + 1:hits[0] + 4], "little")
                v10name = ",".join(exact10.get(t10, ["(no v10 label at 0x%06X)" % t10]))
            oa, on = owner(s7, tgt)
            key = tgt
            seen.setdefault(key, [on, tgt - oa, v10name, 0])
            seen[key][3] += 1
    print("%-10s %-44s %-6s %s" % ("v7 target", "inside (v7 label + off)", "calls", "v10 name of the same call's target"))
    for t in sorted(seen):
        on, d, v10n, n = seen[t]
        print("0x%06X  %-44s %5d  %s" % (t, "%s+%d" % (on, d), n, v10n))
    print("%d distinct targets, %d call sites" % (len(seen), sum(x[3] for x in seen.values())))


if __name__ == "__main__":
    main()
