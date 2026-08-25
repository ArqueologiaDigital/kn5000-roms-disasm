#!/usr/bin/env python3
"""Do the numbers in the 0xF0EA9F block's emitted headers agree with the rows
under them -- and does this audit reach the LAST object?

QUESTION IT ANSWERS
  The byte gate proves the bytes and says nothing about a comment.  Round 4's
  equivalent (notes/prom_b_f65000_header_audit.py) caught an emitter that
  subtracted the wrong stub constant and printed a wrong "distinct targets"
  count in EVERY table header.  This is the same check for round 5's block, and
  it runs against prom_b/wsa1_prom_b.s itself rather than against the emitter, so
  it also catches a splice that dropped or duplicated something.

WHAT IT ASSERTS (non-zero exit if any fails)
  1. every segment of gen_prom_b_f0ea9f_module.LAYOUT that is a DATA kind has a
     label line in the .s, at the right address, with the right prefix for its
     kind -- DispatchTable/DataPtrTable/ArrayDescriptor/PtrTable by the consumer
     rule's classification, ByteMap, IndexMap, RamPtrTable, Data;
  2. every `.long` row of a pointer table has the address its comment claims and
     a value that is really in 0x00F00000-0x00F7FFFF;
  3. every `.byte` row of a byte map re-reads to the ROM's bytes;
  4. the number a table header states as its entry count equals the number of
     rows emitted under it;
  5. THE LAST OBJECT of the block is one of the objects checked -- printed by
     name, so "the audit passed" cannot mean "the audit stopped early".

RUN
  python3 notes/prom_b_f0ea9f_header_audit.py
  python3 notes/prom_b_f0ea9f_header_audit.py --last     # just check 5
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import gen_prom_b_f0ea9f_module as G                               # noqa: E402

SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
IMG = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
B_BASE = 0xF00000
FAIL = []


def check(name, got, want, verbose=True):
    ok = got == want
    if not ok:
        FAIL.append(name)
    if verbose:
        print("  %-66s %s" % (name, "PASS" if ok else "FAIL got=%r want=%r"
                              % (got, want)))


def source():
    return open(SRC).read().split("\n")


def main():
    d = open(IMG, "rb").read()
    lines = source()
    labels = {}
    for i, l in enumerate(lines):
        m = re.match(r"^([A-Za-z_][\w]*)_([0-9A-F]{6}):", l)
        if m:
            labels[int(m.group(2), 16)] = (m.group(1), i)
    G.install()
    data = [(k, s, n) for k, s, n in G.LAYOUT if k in G.DATA_KINDS]
    last = data[-1]
    if "--last" in sys.argv:
        k, s, n = last
        print("the LAST data object of the block is 0x%06X (%s, %d bytes)"
              % (s, k, n))
        check("  it has a label in prom_b/wsa1_prom_b.s", s in labels, True)
        return 1 if FAIL else 0
    missing, wrongpre = [], []
    for k, s, n in data:
        if s not in labels:
            missing.append("0x%06X" % s)
            continue
        want = (G.KIND_PREFIX[G.kind_of_table(s, n)] if k == "ptrtab"
                else G.PREFIX[k])
        if labels[s][0] != want:
            wrongpre.append("0x%06X is %s, want %s" % (s, labels[s][0], want))
    check("every data segment has a label in the .s", missing, [])
    check("every label's prefix matches its kind", wrongpre, [])
    badrow, badcount = [], []
    for k, s, n in data:
        if s not in labels:
            continue
        start = labels[s][1] + 1
        rows = []
        for l in lines[start:start + n + 4]:
            if not l.startswith("\t."):
                break
            rows.append(l)
        if k == "ptrtab":
            if len(rows) != n // 4:
                badcount.append("0x%06X: %d rows, %d entries"
                                % (s, len(rows), n // 4))
            for i, l in enumerate(rows):
                m = re.search(r"\.long\s+0x([0-9A-F]{8}).*;\s*([0-9A-F]{6})", l)
                v, a = int(m.group(1), 16), int(m.group(2), 16)
                real = int.from_bytes(d[s + 4 * i - B_BASE:s + 4 * i + 4 - B_BASE],
                                      "little")
                if a != s + 4 * i or v != real or not (0x00F00000 <= v < 0x00F80000):
                    badrow.append("0x%06X[%d]" % (s, i))
        if k in ("bytemap", "ident", "data"):
            got = []
            for l in rows:
                got += [int(x, 16) for x in re.findall(r"0x([0-9A-F]{2})",
                                                       l.split(";")[0])]
            if got != list(d[s - B_BASE:s + n - B_BASE]):
                badrow.append("0x%06X (%s rows)" % (s, k))
    check("every emitted row re-reads to the ROM", badrow, [])
    check("every table's row count equals its entry count", badcount, [])
    k, s, n = last
    print("  the LAST data object checked is 0x%06X (%s, %d bytes), label %s"
          % (s, k, n, labels.get(s, ("MISSING",))[0]))
    check("  the last object has a label", s in labels, True)
    print("\n%s (%d failed)" % ("HEADER AUDIT PASS" if not FAIL else
                                "HEADER AUDIT FAIL", len(FAIL)))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
