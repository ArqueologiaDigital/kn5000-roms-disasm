#!/usr/bin/env python3
"""IS THE 0x0010C000 PRODUCER CENSUS COMPLETE?  NO -- IT MISSES 17 WRITE SITES.

QUESTION ANSWERED
  notes/prom_c_dev10c_field_sources.py is the index every later pass navigates gap A by: it
  reports "70 write sites over 21 of the 22 words" and, register by register, WHICH routines
  produce the value.  notes/FINDINGS-prom_c-dev10c-producers.md then reasons from the COUNTS
  ("eleven of the 22 words have exactly two write sites ... a register with two producers is
  one routine-read away from a meaning").  If the counts are wrong, that reasoning picks the
  wrong targets.

  This script measures what the shipped scan cannot see.  It imports that scan unmodified,
  runs three wider scans beside it, and prints the corrected table and the delta.  Its
  docstring promises "any write through a base this script cannot follow is COUNTED AND
  REPORTED, never dropped" -- the `unfollowed` list is built but nothing is ever appended to
  it, so the promise does not hold.  The three blind spots, all confirmed by hand:

    A. ABSOLUTE READ-MODIFY-WRITE.  Its ABS regex is `st[ilbwl]*_da`, so `stw_da`, `stb_da`,
       `stiw_da`, `stib_da` and `stl_da` match but `ordm16_24 (0x00d774),BC` does not.
    B. A BASED STORE AFTER AN INTERIOR LABEL.  `scan()` clears its base map at EVERY label,
       including `foo__FA90D8` branch targets, so a `lda Xxx,0x00d75e` at the top of a
       routine is forgotten before the store that uses it.
    C. A STORE THROUGH A POINTER ARGUMENT.  A routine handed the struct's address writes it
       without any `lda` in sight.  The shipped script handles this for the 0x00104000 twin
       (`--dev104`, one packer) and not at all for this device.

  Class C is the one that changes an answer rather than a count: it adds a producer to
  register 0x0040 that no read of prom_c's staging routines would ever find.

WHAT THIS DOES NOT CHANGE
  * "21 of the 22 words".  Word 0 still has no producer of any kind; the corrected sites all
    land on words that already had one.
  * Any register's MEANING.  This is a completeness audit of an index, not a decode.

RUN
  python3 notes/prom_c_staging_producer_audit.py             # the delta and the corrected table
  python3 notes/prom_c_staging_producer_audit.py --selftest  # + negative controls
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import prom_c_dev10c_field_sources as fs            # the shipped census, unmodified

SRC = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
STRUCT, NWORD = fs.STRUCT, fs.NWORD
ADDR = re.compile(r";\s*([0-9A-F]{6})\s")
LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
LDA = re.compile(r"^\s*lda_24\s+(x[a-z]{2}),\s*\(0x([0-9A-Fa-f]{4})\)")
ST = re.compile(r"^\s*(ld|ldw|or|add|sub|and|xor)\s+\((x[a-z]{2})(?:\+(0x[0-9A-Fa-f]+|\d+))?\),\s*(\S+)")
RMW = re.compile(r"^\s*([a-z]+)dm(?:8|16)_24\s+\(0x([0-9A-Fa-f]{4})\),\s*(\S+)")
KILL = re.compile(r"^\s*(?:ld|ldw|ldl|lda_24|pop|add|sub|inc|dec|extz|exts|mul|div)[a-z0-9_]*\s+(x[a-z]{2})\b\s*,?")
FAIL = []


def check(what, got, want):
    if got != want:
        FAIL.append(f"{what}: got {got!r} want {want!r}")
        print(f"  [FAIL] {what}\n         got {got!r}  want {want!r}")
    else:
        print(f"  [ok] {what}")


def lines():
    return open(SRC, encoding="utf-8").read().splitlines()


def scan_wide():
    """Classes A and B: absolute RMW, and based stores whose base survives an interior label.

    The base map is cleared only at a TOP-LEVEL label (one with no `__` in it), and killed
    whenever the register is redefined.  That is less conservative than the shipped scan, so
    every hit is listed with its address for hand checking rather than trusted in bulk.
    """
    cur = top = None
    base = {}
    rmw, carried = [], []
    for line in lines():
        m = LABEL.match(line)
        if m:
            cur = m.group(1)
            if "__" not in cur:
                top, base = cur, {}
            continue
        code = line.split(";")[0]
        if not code.strip():
            continue
        m = ADDR.search(line)
        a = int(m.group(1), 16) if m else None
        m = RMW.match(code)
        if m:
            t = int(m.group(2), 16)
            if STRUCT <= t < STRUCT + 2 * NWORD:
                rmw.append((a, (t - STRUCT) // 2, m.group(1), cur))
            continue
        m = LDA.match(code)
        if m:
            base[m.group(1)] = int(m.group(2), 16)
            continue
        m = ST.match(code)
        if m and m.group(2) in base:
            off = int(m.group(3), 0) if m.group(3) else 0
            t = base[m.group(2)] + off
            if STRUCT <= t < STRUCT + 2 * NWORD:
                carried.append((a, (t - STRUCT) // 2, m.group(1), cur))
            continue
        m = KILL.match(code)
        if m and m.group(1) in base and "lda_24" not in code:
            del base[m.group(1)]
    return rmw, carried


def routine_extents():
    """{start: (name, end)} from the `; NAME -- 0xAAAAAA..0xBBBBBB (n bytes)` headers."""
    hdr = re.compile(r"^; (?:★★ |★ )?([A-Za-z_][A-Za-z0-9_]*) -- "
                     r"0x([0-9A-F]{6})\.\.0x([0-9A-F]{6})")
    out = {}
    for line in lines():
        m = hdr.match(line)
        if m:
            out[int(m.group(2), 16)] = (m.group(1), int(m.group(3), 16))
    return out


def scan_pointer_args():
    """Class C: a callee handed the struct's address, storing through the argument.

    Step 1 finds every `lda Xxx,0x00d75e` (optionally adjusted by `inc n,Xxx`) that is
    PUSHED and then CALLed, and records the callee and the argument slot the callee will see.
    Step 2 walks each callee, bounded by its own header extent, tracking the register it
    loads that slot into and reporting every store through it.
    """
    recs = []
    for line in lines():
        m = re.search(r";\s*([0-9A-F]{6})\s+(.*)$", line)
        if m:
            recs.append((int(m.group(1), 16), m.group(2).strip()))
    ext = routine_extents()
    calls = {}
    for k, (a, d) in enumerate(recs):
        m = re.match(r"lda (X[A-Z]{2}),0x00d75e$", d)
        if not m:
            continue
        reg, adj, pushed = m.group(1), 0, 0
        for j in range(k + 1, min(k + 16, len(recs))):
            aj, dj = recs[j]
            m2 = re.match(r"inc (\d+),%s$" % reg, dj)
            if m2:
                adj += int(m2.group(1))
                continue
            if re.match(r"push X[A-Z]{2}$", dj):
                pushed += 4
                continue
            if re.match(r"push (BC|WA|DE|HL|IX|IY)$", dj):
                pushed += 2
                continue
            m2 = re.match(r"cal[rl]\s+0x([0-9a-f]{6})", dj)
            if m2:
                # the callee sees arguments at (XIZ+0x08) upward, last pushed first
                slot = 8 + (pushed - 4)
                calls.setdefault(int(m2.group(1), 16), set()).add((aj, adj, slot))
                break
            if dj.startswith("ret"):
                break
    out = []
    for callee, sites in sorted(calls.items()):
        if callee not in ext:
            continue
        name, end = ext[callee]
        for start_addr, adj, slot in sorted(sites):
            ptr, seen = {}, []
            for a, d in recs:
                if not (callee <= a <= end):
                    continue
                m = re.match(r"ld (X[A-Z]{2}),\(XIZ\+0x0([0-9a-f])\)$", d)
                if m and int(m.group(2), 16) == slot:
                    ptr[m.group(1)] = True
                    continue
                m = re.match(r"(ld|or|and|add|sub|xor) \((X[A-Z]{2})(?:\+0x([0-9a-f]{2}))?\),(\S+)$", d)
                if m and m.group(2) in ptr:
                    off = (int(m.group(3), 16) if m.group(3) else 0) + adj
                    if 0 <= off < 2 * NWORD:
                        seen.append((a, off // 2, m.group(1), m.group(4)))
                    continue
                m = re.match(r"[a-z0-9]+\s+(X[A-Z]{2})\b", d)
                if m and m.group(1) in ptr:
                    del ptr[m.group(1)]
            if seen:
                out.append((name, callee, start_addr, adj, slot, seen))
    return out


print(__doc__.splitlines()[0])
print()

shipped, _ = fs.scan()
print("1. the shipped census, reproduced by importing it")
check("site count", len(shipped), 70)
check("words covered", len({h[1] // 2 for h in shipped}), 21)
check("`unfollowed` is never populated -- the docstring's promise is unmet",
      fs.scan()[1], [])

rmw, carried = scan_wide()
print("\n2. class A -- absolute read-modify-write the ABS regex cannot match")
for a, w, op, lbl in rmw:
    print(f"     0x{a:06X}  word {w:2d} -> reg 0x{fs.WORD2BLOCK[w]*0x40:04X}  "
          f"`{op}dm16_24`  in {lbl}")
check("three such sites", len(rmw), 3)
check("their words", sorted({w for _, w, _, _ in rmw}), [10, 11, 15])
check("the LAST of them is 0xFA9FEE, word 10", (rmw[-1][0], rmw[-1][1]), (0xFA9FEE, 10))

extra_b = [h for h in carried if h[0] not in {x[0] for x in shipped}]
print("\n3. class B -- based stores whose base was cleared by an interior label")
for a, w, op, lbl in extra_b:
    print(f"     0x{a:06X}  word {w:2d} -> reg 0x{fs.WORD2BLOCK[w]*0x40:04X}  in {lbl}")
check("seven such sites", len(extra_b), 7)
check("all seven are in the two Reg0100/0140 helpers",
      sorted({l.split("__")[0] for _, _, _, l in extra_b}),
      ["Voice_StagePair_Reg0100_0140_Both", "Voice_StagePair_Reg0100_0140_First"])
check("their words are 4 and 5 only", sorted({w for _, w, _, _ in extra_b}), [4, 5])

ptr_raw = scan_pointer_args()
# One STORE INSTRUCTION is one write site, however many call sites reach it -- the same
# convention the shipped census uses.  The call sites are listed, then folded away.
ptr_by_callee = {}
for name, callee, site, adj, slot, seen in ptr_raw:
    e = ptr_by_callee.setdefault((name, callee), {"calls": [], "stores": {}})
    e["calls"].append((site, STRUCT + adj, slot))
    for a, w, op, val in seen:
        e["stores"][a] = (w, op, val)
print("\n4. class C -- stores through a struct POINTER handed to a callee")
for (name, callee), e in sorted(ptr_by_callee.items(), key=lambda kv: kv[0][1]):
    calls = ", ".join(f"0x{s:06X} (arg +0x{sl:02X} = 0x{p:06X})" for s, p, sl in e["calls"])
    print(f"     {name} (0x{callee:06X}), called with the struct pointer at: {calls}")
    for a in sorted(e["stores"]):
        w, op, val = e["stores"][a]
        print(f"        0x{a:06X}  word {w:2d} -> reg 0x{fs.WORD2BLOCK[w]*0x40:04X}  "
              f"`{op}` <- {val}")
ptr_sites = {a: (n, v) for (n, _), e in ptr_by_callee.items()
             for a, v in e["stores"].items()}
check("two callees", sorted(n for n, _ in ptr_by_callee), ["Word_AddTickLow3", "sub_FC7FCA"])
check("seven distinct store instructions", len(ptr_sites), 7)
check("sub_FC7FCA is reached from three call sites",
      len([e for (n, _), e in ptr_by_callee.items() if n == "sub_FC7FCA"][0]["calls"]), 3)
check("sub_FC7FCA covers words 11, 16, 17, 18",
      sorted({v[0] for n, v in ptr_sites.values() if n == "sub_FC7FCA"}), [11, 16, 17, 18])
check("Word_AddTickLow3 covers word 1 -- register 0x0040",
      [(v[0], "0x%04X" % (fs.WORD2BLOCK[v[0]] * 0x40))
       for n, v in ptr_sites.values() if n == "Word_AddTickLow3"], [(1, "0x0040")])

print("\n5. class D -- 32-bit stores covering two words at once: CHECKED AND CLEAN")
stl = [l for l in lines()
       if re.match(r"\s*stl_da\s+\(0x([0-9A-Fa-f]{4})\)", l)
       and STRUCT <= int(re.match(r"\s*stl_da\s+\(0x([0-9A-Fa-f]{4})\)", l).group(1), 16)
       < STRUCT + 2 * NWORD]
check("no `stl_da` targets the staging struct", len(stl), 0)

print("\n6. THE CORRECTED TABLE")
by = {}
for a, off, val, rout, form in shipped:
    by.setdefault(off // 2, []).append((a, rout))
for a, w, op, lbl in rmw + extra_b:
    by.setdefault(w, []).append((a, lbl))
for a, (name, v) in ptr_sites.items():
    by.setdefault(v[0], []).append((a, name))
print("  word  register    shipped  corrected  routines added")
added_total = 0
for w in range(NWORD):
    blk = fs.WORD2BLOCK.get(w)
    reg = f"0x{blk*0x40:04X}+ch" if blk is not None else "  --     "
    old = len([h for h in shipped if h[1] // 2 == w])
    new = len(by.get(w, []))
    oldr = {h[3] for h in shipped if h[1] // 2 == w}
    newr = {r for _, r in by.get(w, [])} - oldr
    added_total += new - old
    mark = "  <=" if new != old else "    "
    print(f"   {w:2d}   {reg}   {old:5d}    {new:6d}{mark} "
          + (", ".join(sorted(newr)) if newr
             else ("(a new site in a routine already credited)" if new != old else "")))
print(f"\n  {len(shipped)} sites shipped + {added_total} missed = "
      f"{len(shipped)+added_total} sites over {len(by)} of the {NWORD} words.")
check("the corrected total", len(shipped) + added_total, 87)
check("still 21 of 22 words -- word 0 gains nothing", len(by), 21)
two = sorted(w for w in range(NWORD) if len(by.get(w, [])) == 2)
print(f"\n  Registers with EXACTLY TWO write sites, corrected: "
      + ", ".join("0x%04X" % (fs.WORD2BLOCK[w] * 0x40) for w in two))
check("the shipped note's 'eleven words have exactly two sites' is now six", len(two), 6)
check("0x0500 and 0x0900 leave that list (they gain a pointer-argument producer)",
      [w for w in (11, 16) if w in two], [])

if "--selftest" in sys.argv:
    print("\nNEGATIVE CONTROLS (each must FAIL)")
    n0 = len(FAIL)
    check("[control] the shipped census is NOT 71 sites", len(shipped), 71)
    check("[control] class B is NOT 8 sites", len(extra_b), 8)
    check("[control] Word_AddTickLow3 does NOT reach word 2",
          sorted({v[0] for n, v in ptr_sites.values() if n == "Word_AddTickLow3"}), [2])
    fired = len(FAIL) - n0
    print(f"  {fired} of 3 controls fired")
    if fired != 3:
        print("  SELFTEST BROKEN")
        sys.exit(2)
    del FAIL[n0:]

print(f"\nFAILURES: {len(FAIL)}")
for f in FAIL:
    print("  -", f)
sys.exit(1 if FAIL else 0)
