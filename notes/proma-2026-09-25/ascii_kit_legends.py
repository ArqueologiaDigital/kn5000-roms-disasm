#!/usr/bin/env python3
r"""KitCategoryLegends (0xFF047F-0xFF07C4) as `.ascii` legends, with a label at every base the switch names.

QUESTION THIS ANSWERS / JOB IT DOES
    The span is text -- six-character drum-kit legends ("STANDR", "ROOM  ",
    ...) and the three type legends "user1 ", "user2 ", "ext   " -- but was
    emitted as 52 lines of `.byte`.  KitCategoryLegend_SelectBase's five-way
    switch names FIVE bases in it (`ld XIY,imm32` at 0xFF041E, 0xFF0424,
    0xFF042A, 0xFF0430, 0xFF0436), which the address pass spelled
    KitCategoryLegends+0x6 / +0x31E / +0x32C / +0x33A.  This rewrites the
    span as one `.ascii` per legend and gives each named base its own label:

      KitCategoryLegends            0xFF047F  the six-space default (any other type)
      KitCategoryLegends_ByProgram  0xFF0485  132 legends, type 0x20, index = program
      KitCategoryLegend_User1       0xFF079D  type 0x28 -- "user1  " twice (14 B)
      KitCategoryLegend_User2       0xFF07AB  type 0x29 -- "user2  " twice (14 B)
      KitCategoryLegend_Ext         0xFF07B9  type 0x30 -- "ext   " twice (12 B)

    Nothing is re-interpreted: the big header above KitCategoryLegends (the GM
    mapping, the retracted count, the duplicate question) stays as it is.

CHECKS
    K1  the five `ld XIY,imm32` operands are the five bases above
    K2  every byte in the span is printable ASCII; 0xFF047F + 6 * 133 = 0xFF079D
    K3  the rewritten lines reproduce the span byte for byte (the gate re-checks)

RUN
    python3 notes/proma-2026-09-25/ascii_kit_legends.py          # checks
    python3 notes/proma-2026-09-25/ascii_kit_legends.py --apply  # ran once
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE
LO, HI = 0xFF047F, 0xFF07C5
BASES = {0xFF041E: 0xFF047F, 0xFF0424: 0xFF0485, 0xFF042A: 0xFF079D, 0xFF0430: 0xFF07AB, 0xFF0436: 0xFF07B9}


def checks(r):
    for site, base in BASES.items():
        assert r[site - B:site - B + 5] == b"\x45" + base.to_bytes(4, "little"), hex(site)
    d = r[LO - B:HI - B]
    assert all(0x20 <= c < 0x7F and c not in (0x22, 0x5C) for c in d)
    assert LO + 6 * 133 == 0xFF079D
    print("K1/K2 ok: five switch bases, %d printable bytes" % len(d))
    return d


def lines(d):
    out = ["KitCategoryLegends:",
           '\t.ascii "%s"                                ; FF047F  default (any other type)' % d[:6].decode()]
    out += ["; ---------------------------------------------------------------------",
            "; KitCategoryLegends_ByProgram -- 132 six-character legends, index = the drum",
            ";          program (the record's +0x00 byte, KitCategoryLegend_Index).",
            "; Read by: KitCategoryLegend_SelectBase's type-0x20 arm, `ld XIY,<this>` at",
            ";          0xFF0424; drawn 6 characters wide (BC = 6, see the header above",
            ";          KitCategoryLegends).  COUNT 132 by abutment: KitCategoryLegend_User1",
            ";          follows; entries 121-131 are blank, 120 (\"SE\") is the last legend.",
            ";          (notes/proma-2026-09-25/ascii_kit_legends.py)",
            "; ---------------------------------------------------------------------",
            "KitCategoryLegends_ByProgram:"]
    for k in range(132):
        a = 0xFF0485 + 6 * k
        s = d[a - LO:a - LO + 6].decode()
        out.append('\t.ascii "%s"                                ; %06X  [%3d]' % (s, a, k))
    for base, n, typ, name, site in ((0xFF079D, 14, 0x28, "KitCategoryLegend_User1", 0xFF042A),
                                     (0xFF07AB, 14, 0x29, "KitCategoryLegend_User2", 0xFF0430),
                                     (0xFF07B9, 12, 0x30, "KitCategoryLegend_Ext", 0xFF0436)):
        s = d[base - LO:base - LO + n].decode()
        out += ["; " + name + " -- the legend for record type 0x%02X: `ld XIY,<this>` at 0x%06X;" % (typ, site),
                ";          KitCategoryLegend_Index returns 0 for this type, so the first six",
                ";          characters are what is drawn.  %d bytes: the legend twice (see the" % n,
                ";          header above KitCategoryLegends).",
                name + ":",
                '\t.ascii "%s"                        ; %06X' % (s, base)]
    return out


def apply(d):
    m = srcmap.load()
    L = m.lines
    i = L.index("KitCategoryLegends:")
    j = i + 1
    got = b""
    while len(got) < HI - LO:
        bm = re.match(r"^\t\.byte\s+([0-9a-fx, ]+?)\s*;\s*([0-9A-F]{6})\s*$", L[j])
        assert bm, L[j]
        got += bytes(int(x, 16) for x in bm.group(1).split(","))
        j += 1
    assert got == d                                                               # K3
    L[i:j] = lines(d)
    txt = "\n".join(L)
    for a, b in (("KitCategoryLegends+0x6", "KitCategoryLegends_ByProgram"),
                 ("KitCategoryLegends+0x31E", "KitCategoryLegend_User1"),
                 ("KitCategoryLegends+0x32C", "KitCategoryLegend_User2"),
                 ("KitCategoryLegends+0x33A", "KitCategoryLegend_Ext")):
        assert txt.count(a + " ") == 1, a
        txt = txt.replace(a + " ", b + " ")
    open(srcmap.SRC, "wb").write(txt.encode("latin-1"))
    print("applied")


if __name__ == "__main__":
    D = checks(open(srcmap.ROM, "rb").read())
    if "--apply" in sys.argv:
        apply(D)
