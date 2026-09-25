#!/usr/bin/env python3
r"""List prom_a "code" that no control flow can reach and that decodes as nonsense.

QUESTION THIS ANSWERS
    Where in wsa1/prom_a/wsa1_prom_a.s are UNLABELLED runs of instruction lines
    that begin right after an unconditional transfer (`ret`, `reti`, `retd`,
    `jp`/`jr`/`jrl` without a condition, `jp (xreg)`), run to the next label,
    contain data-as-code markers (the lane worklist's ABS set, plus
    `push SR`/`pop SR`/`reti` pairs), and are the target of NO branch in the
    source (numeric targets computed from the line's guarded address)?  Such a
    run is reached by nothing that this source records: it is data, or code
    reached only by a pointer nobody has found.  Each listed run still needs its
    reader looked for before it is retyped.

RUN
    make gate-wsa1
    python3 notes/proma-2026-09-25/dead_runs.py [--min-markers 2]
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

ABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi|reti|push sr|pop sr)\b'
                 r'|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$|^(jr|jrl)\s+f\s*,')
TERM = re.compile(r'^(ret|reti|retd\b.*|jp\s+[^,]+|jr\s+[^,]+|jrl\s+[^,]+|jp\s+\(x\w+\))$')
BR = re.compile(r'^\s*(?:[A-Za-z_.$][\w.$@]*:\s*)?(jr|jrl|calr|call|jp)\s+(?:([a-z]+)\s*,\s*)?'
                r'(-?0x[0-9a-fA-F]+|-?\d+)\s*$')
LAB = re.compile(r'^([A-Za-z_.$][\w.$@]*):')
SZ = {"jr": 2, "jrl": 3, "calr": 3, "call": 4, "jp": 4}


def runs(m):
    L = m.lines
    addr_of = {i: a for a, i in m.line_at.items()}
    targets = set()
    for i, l in enumerate(L):
        mm = BR.match(l.split(";")[0])
        if mm and i in addr_of:
            mn, _, num = mm.groups()
            v = int(num, 0)
            if mn in ("call", "jp"):
                targets.add(v)
            else:
                if mn == "jr" and v > 127:
                    v -= 256
                if mn in ("jrl", "calr") and v > 32767:
                    v -= 65536
                targets.add(addr_of[i] + SZ[mn] + v)
    # a `lda XIY,(0xADDR:24)` / `push XIY` / `jp (xreg)` computed call returns to
    # ADDR, so a 24-bit lda immediate is a CONTROL target; any other 32-bit
    # immediate that lands in the image (ld XIX,imm / add XBC,imm ...) is kept
    # apart as a possible DATA READER.
    readers = {}
    for i, l in enumerate(L):
        c = l.split(";")[0]
        for mm in re.finditer(r'\(0x([0-9a-fA-F]{6}):24\)', c):
            v = int(mm.group(1), 16)
            if 0xF80000 <= v <= 0xFFFFFF:
                targets.add(v)
        for mm in re.finditer(r'\b0x00([0-9a-fA-F]{6})\b', c):
            v = int(mm.group(1), 16)
            if 0xF80000 <= v <= 0xFFFFFF:
                readers.setdefault(v, []).append((addr_of.get(i), c.strip()[:48]))
    out, cur, after_term = [], None, False
    for i, l in enumerate(L):
        c = l.split(";")[0]
        s = c.strip()
        if LAB.match(s):
            if cur:
                out.append(cur)
            cur, after_term = None, False
            s = LAB.sub("", s).strip()
            if not s:
                continue
        if not s or s.startswith(";"):
            continue
        if s.startswith("."):          # a directive ends a code run
            if cur:
                out.append(cur)
            cur, after_term = None, False
            continue
        low = s.lower()
        if after_term and cur is None:
            cur = {"first": i, "last": i, "markers": 0, "lines": 0}
        if cur is not None:
            cur["last"] = i
            cur["lines"] += 1
            if ABS.match(low) or low == "nop":
                cur["markers"] += 1
        if TERM.match(low) and cur is None:
            after_term = True
    if cur:
        out.append(cur)
    res = []
    for r in out:
        a0 = addr_of.get(r["first"])
        a1 = addr_of.get(r["last"])
        if a0 is None or a1 is None:
            continue
        # end = address of the next statement after the run
        j = r["last"] + 1
        while j < len(L) and j not in addr_of:
            j += 1
        end = addr_of.get(j, a1 + 1)
        hit = [t for t in targets if a0 <= t < end]
        rd = [(v, readers[v]) for v in sorted(readers) if a0 <= v < end]
        res.append((a0, end, r["markers"], r["lines"], hit, r["first"] + 1, rd))
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--min-markers", type=int, default=2)
    a = ap.parse_args()
    m = srcmap.load()
    tot = 0
    for a0, end, mk, n, hit, ln, rd in runs(m):
        if mk >= a.min_markers and not hit:
            tot += end - a0
            print("0x%06X-0x%06X %5d B  %3d markers / %3d lines  line %d%s" % (
                a0, end, end - a0, mk, n, ln,
                ("  DATA READERS: " + "; ".join("0x%06X by %s" % (v, ", ".join(
                    "0x%06X" % x[0] if x[0] else "?" for x in r[:3])) for v, r in rd[:3])) if rd else ""))
    print("total %d bytes" % tot)


if __name__ == "__main__":
    main()
