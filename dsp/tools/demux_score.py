#!/usr/bin/env python3
"""demux_score.py -- score the §133 bank-entry demultiplexer sweep.

Reads the device's per-trial lines out of error.log:

  upd6383: §133 <trial>  <sel0D> <sel0E> <f4> <f5> | <nz> <chg> | <f1s> <f1t> | <f2s> <f2t> | <shift>

and applies the PRE-REGISTERED predicates from PREDICT_133.md, in the order they
were registered.  ⚠ The shift column is TRIVIALLY satisfied on all-zero cells
(0 == 0), so it is reported only for trials that already pass C1; that limitation
was stated before the run, not discovered after it.

  python3 demux_score.py error.log
"""
import collections
import re
import sys

SEL = {0: "none", 1: "acc<-L", 2: "tempA", 3: "tempB",
       4: "mem[ptr]", 5: "P raw", 6: "acc+=L", 7: "P<<16"}
F31 = {0: "alias", 1: "LOAD", 2: "ADD", 3: "HOLD"}
PAT = re.compile(r"§133\s+(\d+)\s+(\d) (\d) (\d) (\d) \| *(\d+) +(\d+) \| *(\d+) +(\d+)"
                 r" \| *(\d+) +(\d+) \| *(\d+)")

rows = []
for line in open(sys.argv[1] if len(sys.argv) > 1 else "error.log",
                 errors="ignore"):
    m = PAT.search(line)
    if m:
        t, d, e, f4, f5, nz, chg, f1s, f1t, f2s, f2t, sh = map(int, m.groups())
        rows.append(dict(t=t, d=d, e=e, f4=f4, f5=f5, nz=nz, chg=chg,
                         f1s=f1s, f1t=f1t, f2s=f2s, f2t=f2t, sh=sh))

print("trials parsed: %d" % len(rows))
if not rows:
    sys.exit("no §133 trial lines found -- did the sweep arm?")

by_t = {r["t"]: r for r in rows}

# ---- P0: trial 0 is the reading null, and it is the shipped default -------------
z = by_t.get(0)
print("\n=== P0  THE READING NULL (trial 0 = shipped default, all selectors 0) ===")
if z is None:
    print("  ⛔ trial 0 missing")
else:
    print("  nz=%d chg=%d feed1=(%d,%d) feed2=(%d,%d)"
          % (z["nz"], z["chg"], z["f1s"], z["f1t"], z["f2s"], z["f2t"]))
    print("  %s" % ("✔ PASS -- the entry routes nothing, as §129 measured"
                    if z["nz"] == 0 else
                    "⛔ FAIL (F1): the injector leaks -- THE RUN IS VOID"))

# ---- P1: the criterion must be able to fail ------------------------------------
live = [r for r in rows if r["chg"] > 0]
fed = [r for r in rows if max(r["f1s"], r["f1t"], r["f2s"], r["f2t"]) > 0]
print("\n=== P1  CAN THE CRITERION FAIL? ===")
print("  trials with any state motion (chg>0): %d/%d = %.1f%%"
      % (len(live), len(rows), 100.0 * len(live) / len(rows)))
print("  trials with a bit-exact feed match:   %d/%d = %.1f%%"
      % (len(fed), len(rows), 100.0 * len(fed) / len(rows)))
if len(fed) > 0.9 * len(rows):
    print("  ⛔ FAIL (F2): >90%% pass -- criterion cannot fail, run VOID")
elif not fed:
    print("  ⛔ (F4) NO trial reproduced a feed -- the destination is not in the menu")
else:
    print("  ✔ the criterion discriminates")

# ---- P2: which cell did each bank feed from? -----------------------------------
print("\n=== P2  THE FEED IDENTITY (bit-exact, chance 2^-24 per frame) ===")
print("  the deciding predicate.  s -> D-RAM 0x05, t -> D-RAM 0x0F\n")
fed.sort(key=lambda r: -(r["f1s"] + r["f1t"] + r["f2s"] + r["f2t"]))
print("  trial  sel0D     sel0E     f31=4 f31=5 | nz chg | bank1 fed by | bank2 fed by")
for r in fed[:30]:
    b1 = ("0x05 x%d" % r["f1s"]) if r["f1s"] else (("0x0F x%d" % r["f1t"]) if r["f1t"] else "-")
    b2 = ("0x05 x%d" % r["f2s"]) if r["f2s"] else (("0x0F x%d" % r["f2t"]) if r["f2t"] else "-")
    print("  %5d  %-9s %-9s %-5s %-5s | %2d %2d | %-12s | %s"
          % (r["t"], SEL[r["d"]], SEL[r["e"]], F31[r["f4"]], F31[r["f5"]],
             r["nz"], r["chg"], b1, b2))
if len(fed) > 30:
    print("  ... %d more" % (len(fed) - 30))

# ---- P3/P4: where do the survivors concentrate? --------------------------------
print("\n=== P3/P4  WHERE DO THE SURVIVORS CONCENTRATE? ===")
for field, name, table in (("d", "ACT 0x0D", SEL), ("e", "ACT 0x0E", SEL),
                           ("f4", "f31=4", F31), ("f5", "f31=5", F31)):
    c = collections.Counter(r[field] for r in fed)
    tot = collections.Counter(r[field] for r in rows)
    line = "  %-9s " % name
    for k in sorted(table):
        if k in tot:
            line += "%s=%d/%d  " % (table[k], c.get(k, 0), tot[k])
    print(line)
print("""
  P3 predicted the survivors sit on sel 5 or 7 (the two P variants), because §131
  shows P is the only register that can carry the sample across the entry.
  P4: exactly one of 5 (raw) and 7 (<<16) should work -- that decides the §132 §3
  scale question instead of assuming it.""")

# ---- the control column, read only where it is meaningful ----------------------
print("\n=== C3  SHIFT IDENTITY (control -- read ONLY on trials with motion) ===")
if live:
    mx = max(r["sh"] for r in live)
    print("  best %d of 1260 among the %d moving trials" % (mx, len(live)))
    print("  ⚠ on all-zero trials this column reads 1260 trivially; ignore those.")
    print("  If it FAILS on a trial that feeds a bank, the CORE model is wrong and")
    print("  nothing may be concluded about the entry (the §107 disqualification rule).")
else:
    print("  no trial produced state motion -- nothing to control")
