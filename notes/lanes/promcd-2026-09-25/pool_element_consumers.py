#!/usr/bin/env python3
r"""Which floating-point operation does each prom_c pool constant feed?

QUESTION THIS ANSWERS
    pool_element_readers.py listed, for every element of fp_constant_pool_FCC81A
    and Float64_ConstantPool, the instructions that load it.  In prom_c a double
    is never used in a register: it is loaded half by half into a 32-bit
    register and each half is PUSHED, high half first, as an argument of a call
    into the double-precision library (Double_Add, Double_Subtract,
    Double_Multiply, Double_Divide, Double_Compare, Double_Pow, ...).  This
    script follows each load forward, in straight-line code, to the call that
    consumes the pushed argument, and states that call.

    A load is credited to a call only when ALL of these hold (otherwise the load
    is counted as "not a push-and-call" and nothing is claimed for it):
      * the very next line is `push` of the register the load wrote;
      * a `call` follows within 24 lines;
      * between the push and that call there is no label (no other path can
        join), no `ret`/`reti`/`jp`/`jr`/`jrl`/`djnz` (no path can leave), and
        no `pop`/`inc N,xsp`/`add xsp`/`ld xsp` (nothing takes the argument
        back off the stack before the call).
    Both halves of one double reach the same call; a call is counted once per
    element however many of its halves reach it.

    The script also measures WHERE on the stack the double sits when the call
    is made: the bytes pushed from its high half up to the call (4 per 32-bit
    push, 2 per 16-bit push; any other push form aborts).  Measured 2026-09-25:
    every credited double is either the top 8 bytes ("on top") or the 8 below
    them ("under the other operand") -- never deeper -- so it is within the two
    doubles that a binary library call takes.  Double_Multiply, _Divide, _Pow
    and _ToFloat32 always get it on top; Double_Add and _Compare always under
    the other operand; Double_Subtract both ways (47 on top, 33 under).

    With --apply it appends ONE line group to each element's existing reader
    header (the lines beginning `; Pool element at 0x...`), directly above the
    element's label.  No existing line is changed.

RUN
    python3 notes/lanes/promcd-2026-09-25/pool_element_consumers.py [--apply]
    make gate-wsa1        # comments only: the images cannot move
"""
import collections
import os
import re
import sys
import textwrap

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
PC = os.path.join(ROOT, "wsa1", "prom_c")
TEM = os.path.join(PC, "data_tables", "touch_eq_mixer.s")
MATH = os.path.join(PC, "mathlib", "mathlib.s")
POOLS = {"fp_constant_pool_FCC81A": TEM, "Float64_ConstantPool": MATH}
LABEL = re.compile(r"^([A-Za-z_.$][\w.$@]*):")
LOAD = re.compile(r"^\s+ld\s+(x[a-z]{2}),\s*\(([A-Za-z_][\w]*)(\+4)?:24\)\s*;\s*([0-9A-F]{6})\b")
STOP = re.compile(r"^\s+(ret|reti|retd|jp|jr|jrl|djnz|pop|popw|popl)\b|^\s+inc\s+\d+,\s*xsp\b|"
                  r"^\s+add\s+xsp\b|^\s+ld\s+xsp\b|^\s+\.byte\b")
CALL = re.compile(r"^\s+call\s+([A-Za-z_][\w]*)\s*;\s*([0-9A-F]{6})\b")
MARK = "; Each load is pushed as an argument of"


def members():
    out = {}
    for pool, path in POOLS.items():
        L = open(path, encoding="latin-1").read().split("\n")
        i = L.index(pool + ":")
        mem = [pool]
        for ln in L[i + 1:]:
            m = LABEL.match(ln)
            if m:
                if m.group(1).startswith(("F64_", "F32_")):
                    mem.append(m.group(1))
                    continue
                break
        out[pool] = mem
    return out


def consumers(names):
    names = set(names)
    got = collections.defaultdict(lambda: dict(loads=0, credited=0, calls=collections.OrderedDict(), depth={}))
    for dp, _, fn in os.walk(PC):
        for f in sorted(fn):
            if not f.endswith(".s"):
                continue
            L = open(os.path.join(dp, f), encoding="latin-1").read().split("\n")
            for i, ln in enumerate(L):
                m = LOAD.match(ln)
                if not m or m.group(2) not in names:
                    continue
                reg, el = m.group(1), m.group(2)
                g = got[el]
                g["loads"] += 1
                if i + 1 >= len(L) or not re.match(r"^\s+push\s+%s\b" % reg, L[i + 1]):
                    continue
                nb = 4
                for j in range(i + 2, min(i + 26, len(L))):
                    t = L[j]
                    if LABEL.match(t) or STOP.match(t):
                        break
                    c = CALL.match(t)
                    if c:
                        g["credited"] += 1
                        g["calls"].setdefault(c.group(2), c.group(1))
                        # the double's depth, measured from its HIGH half
                        depth = nb if m.group(3) else nb + 4
                        assert depth in (8, 16), (f, i + 1, depth)
                        prev = g["depth"].setdefault(c.group(2), depth)
                        assert prev == depth, (f, i + 1, prev, depth)
                        break
                    p = re.match(r"^\s+push\s+(\S+)", t)
                    if p:
                        r = p.group(1)
                        if re.match(r"^x[a-z]{2}$", r):
                            nb += 4
                        elif re.match(r"^(wa|bc|de|hl|ix|iy|iz|sp)$", r):
                            nb += 2
                        else:
                            raise AssertionError("push form not measured: %s:%d %s" % (f, j + 1, t))
    return got


def line_for(el, g):
    by = collections.OrderedDict()
    for addr, callee in g["calls"].items():
        where = "on top" if g["depth"][addr] == 8 else "under the other operand"
        by.setdefault((callee, where), []).append("0x" + addr)
    parts = ["%s (call at %s; %s)" % (k[0], ", ".join(v), k[1]) if len(v) == 1 else
             "%s x%d (calls at %s; %s)" % (k[0], len(v), ", ".join(v[:4]) + (" +%d more" % (len(v) - 4) if len(v) > 4 else ""), k[1])
             for k, v in by.items()]
    body = "%s: %s." % (MARK[2:], "; ".join(parts))
    rest = g["loads"] - g["credited"]
    if rest:
        body += " %d of its %d loads are not a push-and-call and are not described here." % (rest, g["loads"])
    return ["; " + x for x in textwrap.wrap(body, 90, break_long_words=False, break_on_hyphens=False)]


def main():
    mem = members()
    allnames = [n for v in mem.values() for n in v]
    got = consumers(allnames)
    tot = collections.Counter()
    for pool, v in mem.items():
        n_el = sum(1 for n in v if got[n]["calls"])
        loads = sum(got[n]["loads"] for n in v)
        cred = sum(got[n]["credited"] for n in v)
        print("  %-24s %3d elements, %3d feed a call; %4d loads, %4d credited to a call" %
              (pool, len(v), n_el, loads, cred))
        for n in v:
            for callee in got[n]["calls"].values():
                tot[callee] += 1
    print("  consumers (element-call pairs):", ", ".join("%s %d" % kv for kv in tot.most_common()))
    dep = collections.Counter()
    for n in allnames:
        for a, callee in got[n]["calls"].items():
            dep[(callee, "on top" if got[n]["depth"][a] == 8 else "under")] += 1
    print("  stack position at the call:", ", ".join("%s %s %d" % (k[0], k[1], v) for k, v in sorted(dep.items())))
    if "--apply" not in sys.argv:
        return
    for path in sorted(set(POOLS.values())):
        L = open(path, "rb").read().decode("latin-1").split("\n")
        if any(x.startswith(MARK) for x in L):
            sys.exit("already applied to " + path)
        out, n = [], 0
        names = {x for p, v in mem.items() if POOLS[p] == path for x in v}
        for ln in L:
            m = LABEL.match(ln)
            if m and m.group(1) in names and m.group(1) not in POOLS and got[m.group(1)]["calls"]:
                assert out[-1].startswith("; "), (m.group(1), out[-1])
                out.extend(line_for(m.group(1), got[m.group(1)]))
                n += 1
            out.append(ln)
        data = "\n".join(out).encode("latin-1")     # encode BEFORE opening
        open(path, "wb").write(data)
        print("  wrote %s: %d headers extended" % (os.path.relpath(path, ROOT), n))


if __name__ == "__main__":
    main()
