#!/usr/bin/env python3
"""Which of p7_module.s's 43 `sub_XXXXXX` objects are ROUTINES, and which are the
CONTINUATION of the object above them?  -- the evidence for the w17/p7-dsp naming pass.

QUESTION IT ANSWERS
  The splitter that produced prom_c/p7/p7_module.s cuts a top-level object at every
  `ret`/`link` pair.  A routine whose body contains an interior `ret` followed by code
  that is only ever REACHED BY A JUMP is therefore cut into several objects, and every
  piece after the first gets an address name.  Before naming anything for behaviour, the
  pass has to know which `sub_` labels are entry points at all.

  A `sub_` is classified CONTINUATION when ALL THREE hold:
      1. its first instruction is not `link` -- it never builds a frame, so it cannot be
         entered with the ABI's argument slots;
      2. no `call`/`calr` anywhere in the image names it (the header's own census);
      3. it is reachable from the object above it -- either the preceding object's last
         instruction falls through into it, or a `jr`/`jrl`/`jp` inside the enclosing
         run of objects targets its entry.
  Anything else is UNRESOLVED and is left as `sub_`.

  ★ THE NULL.  "No `link` at entry" is only evidence if a frame is the norm here.  The
  script prints the fraction of the file's NAMED (already-adjudicated) top-level objects
  that open with `link`; that is the base rate the CONTINUATION test is measured against.

RUN
    python3 notes/p7_sub_classify.py            # the table
    python3 notes/p7_sub_classify.py --null     # base rates only
"""
import os, re, sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_c", "p7", "p7_module.s")
L = open(SRC).read().split("\n")

OBJ = re.compile(r"^; ([A-Za-z_][A-Za-z0-9_]*) -- 0x([0-9A-F]+)\.\.0x([0-9A-F]+) \((\d+) bytes\)")
LAB = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):$")
ADDR = re.compile(r";\s+([0-9A-F]{6})\s+(.*)$")

objs = []           # (name, lo, hi, header_line_idx)
for i, ln in enumerate(L):
    m = OBJ.match(ln)
    if m:
        objs.append([m.group(1), int(m.group(2), 16), int(m.group(3), 16), i])
objs.sort(key=lambda o: o[1])

# line index of each top-level label definition
labline = {}
for i, ln in enumerate(L):
    m = LAB.match(ln)
    if m:
        labline.setdefault(m.group(1), i)

def first_insn(name):
    i = labline.get(name)
    if i is None: return None
    j = i + 1
    while j < len(L) and (L[j].startswith(";") or not L[j].strip()):
        j += 1
    m = ADDR.search(L[j])
    return (m.group(2).strip() if m else L[j].strip())

def last_insn_before(lineidx):
    """the decoded instruction on the last listing line above lineidx"""
    j = lineidx - 1
    while j > 0 and (L[j].startswith(";") or not L[j].strip() or LAB.match(L[j])):
        j -= 1
    m = ADDR.search(L[j])
    return (m.group(2).strip() if m else L[j].strip())

TERMINAL = ("ret", "reti", "jp ", "jrl T,", "jr T,", "unlk")
def terminates(ins):
    if ins is None: return False
    s = ins.lower()
    return s == "ret" or s.startswith("ret") or s.startswith("jp ") \
        or s.startswith("jrl t,") or s.startswith("jr t,")

# every reference to a label, with the mnemonic that makes it
refs = defaultdict(list)
for i, ln in enumerate(L):
    if ln.startswith(";") or not ln.strip(): continue
    code = ln.split(";")[0]
    for tok in re.findall(r"\b(sub_[0-9A-F]{6}|[A-Za-z_][A-Za-z0-9_]*)\b", code):
        if tok in labline and labline[tok] != i:
            mn = code.strip().split()[0] if code.strip() else "?"
            refs[tok].append((i, mn))

subs = [o for o in objs if o[0].startswith("sub_")]
named = [o for o in objs if not o[0].startswith("sub_")]

def base_rates():
    def frac(group):
        n = sum(1 for o in group if (first_insn(o[0]) or "").lower().startswith("link"))
        return n, len(group)
    a = frac(named); b = frac(subs)
    print("★ NULL / BASE RATE -- how often does a top-level object open with `link`?")
    print(f"   already-NAMED objects : {a[0]:2d}/{a[1]:2d} = {100*a[0]/a[1]:.1f}%")
    print(f"   sub_XXXXXX objects    : {b[0]:2d}/{b[1]:2d} = {100*b[0]/b[1]:.1f}%")
    print("   A frame is the norm for an entry point, so 'no link' is a real signal,")
    print("   not a property most objects share.")
    print()

def main():
    base_rates()
    if "--null" in sys.argv: return
    print(f"{'object':16s} {'bytes':>6s}  {'entry insn':22s} {'calls-in':>8s}  verdict")
    print("-" * 92)
    tally = defaultdict(int)
    for k, (name, lo, hi, hdr) in enumerate(subs):
        ins = first_insn(name) or "?"
        callers = [r for r in refs[name] if r[1].startswith(("call", "calr"))]
        jumpers = [r for r in refs[name] if r[1].startswith(("jr", "jrl", "jp"))]
        # predecessor object
        gi = objs.index([name, lo, hi, hdr])
        prev = objs[gi-1] if gi else None
        fell = prev is not None and not terminates(last_insn_before(labline[name]))
        has_frame = ins.lower().startswith("link")
        if not has_frame and not callers and (fell or jumpers):
            v = "CONTINUATION of " + (prev[0] if fell else "n/a")
            tally["continuation"] += 1
        elif has_frame and callers:
            v = f"ROUTINE ({len(callers)} call site(s))"
            tally["routine-called"] += 1
        elif has_frame:
            v = "ROUTINE, frame but no located call site"
            tally["routine-uncalled"] += 1
        else:
            v = "UNRESOLVED"
            tally["unresolved"] += 1
        print(f"{name:16s} {hi-lo+1:6d}  {ins[:22]:22s} {len(callers):8d}  {v}")
    print("-" * 92)
    for k in sorted(tally): print(f"  {k:22s} {tally[k]}")

main()
