#!/usr/bin/env python3
"""Is prom_b's thunk table grouped into MODULES?  Measure it instead of saying
it "looks like" one linker input file per run.

QUESTION IT ANSWERS
    notes/FINDINGS-prom_b-thunk-table.md ends with "Long runs share a target
    prefix and are separated by `ret` fill, which *looks* like one linker input
    file per run.  Not asserted."  This script turns that into numbers:
    it cuts the table at every run of >= 1 all-0x0E slot, and for each surviving
    run reports how many slots it has, whether it OPENS with a pointer slot, and
    how tightly its targets cluster.

WHAT COUNTS AS WHAT
    Nothing is re-implemented: the slot classifier is IMPORTED from the
    committed scripts/analysis/prom_b_thunk_table.py, so `jp`, `ptr` and `fill`
    mean exactly what its --census means by them, and a self-check asserts that
    the three totals still match that census's published 1,976 / 26 / 2,100.
    A run is a maximal stretch of non-fill slots.

WHAT IT DOES *NOT* CLAIM
    A run is a run of slots between fill.  Nothing here shows that a run
    corresponds to a compilation unit; "module" is used below as a NAME for the
    measured object, not as a conclusion about the toolchain.  The clustering
    figure is a fact about addresses, and a tight cluster is consistent with one
    input file and with several other things.

USAGE
    python3 notes/prom_b_thunk_modules.py                # every run
    python3 notes/prom_b_thunk_modules.py --span 0x1000  # runs whose targets fit
                                                         # in one 4 KiB block
    python3 notes/prom_b_thunk_modules.py --at 0xF40F00  # the run holding a slot
    python3 notes/prom_b_thunk_modules.py --selftest     # asserts the SC1 run
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_thunk_table as TT                                   # noqa: E402

LO, HI = TT.TBL_LO + 0xF00000, TT.TBL_HI + 0xF00000


def slots():
    d = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
    out = []
    for o in range(TT.TBL_LO, TT.TBL_HI, 4):
        k, v = TT.classify(d, o)
        out.append((0xF00000 + o, k, v))
    return out


def runs():
    r, cur = [], []
    for s in slots():
        if s[1] == "fill":
            if cur:
                r.append(cur)
                cur = []
        else:
            cur.append(s)
    if cur:
        r.append(cur)
    return r


def describe(run):
    tg = [t for _, k, t in run if t is not None]
    lo, hi = (min(tg), max(tg)) if tg else (0, 0)
    return dict(first=run[0][0], last=run[-1][0], n=len(run),
                njp=sum(1 for _, k, _ in run if k == "jp"),
                nptr=sum(1 for _, k, _ in run if k == "ptr"),
                nother=sum(1 for _, k, _ in run if k not in ("jp", "ptr")),
                opens_ptr=run[0][1] == "ptr", lo=lo, hi=hi, span=hi - lo)


def main():
    rs = runs()
    if "--selftest" in sys.argv:
        return selftest(rs)
    if "--at" in sys.argv:
        want = int(sys.argv[sys.argv.index("--at") + 1], 0)
        rs = [r for r in rs if r[0][0] <= want <= r[-1][0]]
        for r in rs:
            for a, k, t in r:
                print("  T_%06X  %-5s %s" % (a, k, "0x%06X" % t if t else ""))
        return 0
    cap = int(sys.argv[sys.argv.index("--span") + 1], 0) if "--span" in sys.argv else None
    shown = 0
    tot_ptr_first = 0
    for r in rs:
        d = describe(r)
        if d["opens_ptr"]:
            tot_ptr_first += 1
        if cap is not None and d["span"] > cap:
            continue
        shown += 1
        print("  T_%06X-T_%06X  %3d slots (%3d jp, %d ptr, %d other)  "
              "targets 0x%06X-0x%06X span 0x%X%s"
              % (d["first"], d["last"], d["n"], d["njp"], d["nptr"], d["nother"],
                 d["lo"], d["hi"], d["span"], "  opens with a pointer" if d["opens_ptr"] else ""))
    print("  %d runs total, %d shown, %d open with a pointer slot"
          % (len(rs), shown, tot_ptr_first))
    return 0


def selftest(rs):
    ok = True

    def check(what, got, want):
        nonlocal ok
        good = got == want
        ok &= good
        print("  %-52s %-22s (want %-22s) %s" % (what, got, want, "OK" if good else "FAIL"))

    # the imported classifier must still reproduce the published census
    ks = [k for _, k, _ in slots()]
    check("jp / ptr / fill slots (FINDINGS-prom_b-thunk-table.md)",
          (ks.count("jp"), ks.count("ptr"), ks.count("fill")), (1976, 26, 2100))
    check("runs the table splits into", len(rs), 100)
    check("runs opening with a pointer slot",
          sum(1 for r in rs if r[0][1] == "ptr"), 24)
    check("runs whose targets all fit in one 4 KiB span",
          sum(1 for r in rs if describe(r)["span"] <= 0x1000), 60)

    hit = [r for r in rs if r[0][0] <= 0xF40F00 <= r[-1][0]]
    check("runs containing T_F40F00", len(hit), 1)
    r = hit[0]
    d = describe(r)
    check("the run's first and last slot",
          ("0x%06X" % d["first"], "0x%06X" % d["last"]), ("0xF40F00", "0xF40F24"))
    check("slots / jp / ptr / other",
          (d["n"], d["njp"], d["nptr"], d["nother"]), (10, 9, 1, 0))
    check("it opens with a pointer, and the pointer is",
          (d["opens_ptr"], "0x%06X" % r[0][2]), (True, "0xF5A800"))
    check("every target is inside 0xF5A800-0xF5B44D",
          all(0xF5A800 <= t <= 0xF5B44D for _, _, t in r), True)
    check("the three interrupt-vector targets are in it",
          sorted("0x%06X" % t for a, _, t in r
                 if a in (0xF40F0C, 0xF40F10, 0xF40F14)),
          ["0xF5AC0A", "0xF5AC93", "0xF5ACBB"])
    check("slot before the run is fill", 
          open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb")
          .read()[0x40EFC:0x40F00], b"\x0e\x0e\x0e\x0e")
    check("slot after the run is fill",
          open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb")
          .read()[0x40F28:0x40F2C], b"\x0e\x0e\x0e\x0e")
    print("SELFTEST", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
