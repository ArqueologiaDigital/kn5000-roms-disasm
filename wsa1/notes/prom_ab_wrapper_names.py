#!/usr/bin/env python3
"""Name the unnamed one-purpose WRAPPERS after the named routine they wrap -- re-run after every naming batch.

QUESTION IT ANSWERS
  Three body shapes do nothing but reach one other routine.  The tree already names each one after its target:
      SaveRegs   push XDE / push XHL / push XIX / push XIZ / call <T> / pop XIZ / pop XIX / pop XHL / pop XDE / ret
                 -> <target>_SaveRegs        (e.g. Mode_SwitchToSound_SaveRegs, ParamImage_QueueDiffAll_SaveRegs)
      Call       calr|call <T> / ret          -> <target>_Call     (e.g. Disk_MountAndScanDirectory_Call)
      Jump       jp|jr|jrl <T>                -> <target>_Veneer   (e.g. SeqBufRing_Discard_Veneer)
  where <target> is the wrapped label with a prom_b directory slot's `T_` prefix removed.  The body is read up to its
  first `ret` (or the jump), with `.L` locals allowed inside.  A wrapper is named only when its target's name carries
  meaning: not sub_XXXXXX, not T_<address>, not a name that ends in an address.  A second wrapper of the same target
  takes the next free suffix 2, 3, ... (the tree's _SaveRegs2 / _SaveRegs3 precedent).
  Every name is DERIVATIVE -- the understanding is the target's.  Run after each batch that names targets.

RUN
  python3 notes/prom_ab_wrapper_names.py          # the plan
  python3 notes/prom_ab_wrapper_names.py --args   # 'old=new|header' for the rename helper
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = re.compile(r'^([A-Za-z_][\w$]*):')
FRAMED = re.compile(r'^sub_|^T_F4[0-9A-F]{4}|[0-9A-F]{6}')
SAVE = ["push xde", "push xhl", "push xix", "push xiz"]
REST = ["pop xiz", "pop xix", "pop xhl", "pop xde", "ret"]
SUFFIX = {"SaveRegs": "_SaveRegs", "Call": "_Call", "Jump": "_Veneer"}
WHAT = {"SaveRegs": "saves XDE / XHL / XIX / XIZ around a call of %s and returns",
        "Call": "calls %s and returns",
        "Jump": "jumps to %s"}


def load():
    return {img: open(os.path.join(ROOT, img, "wsa1_%s.s" % img), "rb").read().decode("latin-1").split("\n")
            for img in ("prom_a", "prom_b")}


def shape(L, i):
    body = []
    for x in L[i + 1:i + 14]:
        if G.match(x):
            break
        c = re.sub(r'\s+', ' ', x.split(";")[0]).strip()
        if not c or re.match(r'^\.L[\w$]*:$', c):
            continue
        body.append(c)
        if c.lower() == "ret" or re.match(r'^(jp|jr|jrl) ', c, re.I):
            break
    low = [b.lower() for b in body]
    if len(low) == 10 and low[:4] == SAVE and low[5:] == REST and low[4].startswith("call "):
        return "SaveRegs", body[4].split()[1]
    if len(low) == 2 and re.match(r'^(calr|call) [\w$]+$', low[0]) and low[1] == "ret":
        return "Call", body[0].split()[1]
    if len(low) == 1 and re.match(r'^(jp|jr|jrl) [\w$]+$', low[0]):
        return "Jump", body[0].split()[1]
    return None, None


def plan():
    src = load()
    taken = set(re.findall(r'[A-Za-z_][\w$]*', "\n".join("\n".join(L) for L in src.values())))
    rows = []
    for img, L in src.items():
        for i, l in enumerate(L):
            m = G.match(l)
            if not m or not re.match(r'^sub_F[0-9A-F]{5}$', m.group(1)):
                continue
            kind, t = shape(L, i)
            if not kind or FRAMED.search(t):
                continue
            base = (t[2:] if t.startswith("T_") else t) + SUFFIX[kind]
            new, k = base, 2
            while new in taken:
                new, k = "%s%d" % (base, k), k + 1
            taken.add(new)
            rows.append((img, m.group(1), new, "%s: %s (notes/prom_ab_wrapper_names.py; DERIVATIVE)" % (new, WHAT[kind] % t)))
    return rows


def main():
    rows = plan()
    for img, old, new, hdr in rows:
        if "--args" in sys.argv:
            print("%s=%s|%s" % (old, new, hdr))
        else:
            print("%-7s %-12s -> %s" % (img, old, new))
    if "--args" not in sys.argv:
        print("wrappers %d" % len(rows))


if __name__ == "__main__":
    main()
