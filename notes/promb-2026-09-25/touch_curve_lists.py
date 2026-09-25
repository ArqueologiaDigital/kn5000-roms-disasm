#!/usr/bin/env python3
r"""prom_b 0xF04042-0xF0417D (ex `Data_F04042`, 316 bytes): six 42-byte display lists and the four tables that pick them.

QUESTION THIS ANSWERS
    `Data_F04042` was a coverage-walk object ("EMITTED AS DATA", the walk's
    extent).  Its readers are one routine, sub_F5BDBB, and they fix its layout:

      0xF04042  six interpreter-A lists of 42 bytes (4 records each: `TOUCH`
                and `CURVE` captions (op 0x17), a box (op 0x22), a line (op
                0x01)), the same picture at six places;
      0xF0413E  5 pointers to those lists  } `ld XIZ,<table> / add XIZ,XWA /
      0xF04152  3 pointers                 }  ld XIY,(XIZ) / ld XIX,XIY / add
                                              XIX,42 / call T_DisplayList_Run`
                                              (0xF5BE3D/0xF5BE44 .. 0xF5BE55);
      0xF0415E  5 (x, y) word pairs        } `ld XIZ,<table> / add XIZ,XWA /
      0xF04172  3 (x, y) word pairs        }  ld WA,(XIZ) / ld (0x2350),WA /
                                              ld WA,(XIZ+2) / ld (0x2352),WA`
                                              (0xF5BDFA/0xF5BE01 .. 0xF5BE12);
    XWA = 4 * (0x27A3) for both (`ld A,(0x27a3) / sla 2,WA` at 0xF5BDEC), and
    `cp (0x27f5),1` picks the 3-entry tables (0xF5BDF3, 0xF5BE36).  The counts
    are the distances between the four table starts the code names, and the
    (x, y) pair of entry k is the top-left corner of the box its list draws --
    for 7 of the 8 entries; the 3-entry table's first says x = 0xA8 where its
    list's box starts at 0xE0.

RUN
    python3 notes/promb-2026-09-25/touch_curve_lists.py            # checks
    python3 notes/promb-2026-09-25/touch_curve_lists.py --apply    # write the source
    python3 scripts/converters/symbolize_wsa1_rom_addresses.py --arms --offsets --apply --verify
    make gate-wsa1
"""
import os
import re
import sys
import textwrap

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "wsa1", "scripts", "analysis"))
import prom_b_display_lists as DL      # noqa: E402

SRC = os.path.join(ROOT, "wsa1", "prom_b", "wsa1_prom_b.s")
ROMB = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
BASE = 0xF00000
LO, LISTS_END, PT5, PT3, XY5, XY3, HI = 0xF04042, 0xF0413E, 0xF0413E, 0xF04152, 0xF0415E, 0xF04172, 0xF0417E
FAIL = []


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


def derive():
    b = open(ROMB, "rb").read()
    at = lambda a, n: b[a - BASE:a - BASE + n]
    u32 = lambda a: int.from_bytes(at(a, 4), "little")
    u16 = lambda a: int.from_bytes(at(a, 2), "little")
    lists = [LO + 42 * k for k in range(6)]
    recs = [DL.walk(b, s, s + 42) for s in lists]
    check("0xF04042-0xF0413D: six interpreter-A lists, each exactly 4 records / 42 bytes "
          "(ops 17 17 22 01)", all([(op, ln) for _, op, ln in r] == [(0x17, 11), (0x17, 11), (0x22, 10), (0x01, 10)]
                                   for r in recs) and lists[-1] + 42 == LISTS_END)
    texts = [(at(s + 6, 5), at(s + 17, 5)) for s in lists]
    check("  each draws `TOUCH` and `CURVE`", all(t == (b"TOUCH", b"CURVE") for t in texts))
    box = [(u16(s + 24), u16(s + 26)) for s in lists]
    p5 = [u32(PT5 + 4 * k) for k in range(5)]
    p3 = [u32(PT3 + 4 * k) for k in range(3)]
    xy5 = [(u16(XY5 + 4 * k), u16(XY5 + 4 * k + 2)) for k in range(5)]
    xy3 = [(u16(XY3 + 4 * k), u16(XY3 + 4 * k + 2)) for k in range(3)]
    check("0xF0413E: 5 pointers %s, 0xF04152: 3 pointers %s -- every one a list start"
          % ([hex(x) for x in p5], [hex(x) for x in p3]), all(x in lists for x in p5 + p3))
    same = [xy == box[lists.index(p)] for xy, p in zip(xy5 + xy3, p5 + p3)]
    check("0xF0415E / 0xF04172: the (x, y) of entry k is the top-left corner of the op-0x22 box its "
          "list draws, for all 8 entries but the 3-table's first: (0x%X, 0x%X) against the box's "
          "(0x%X, 0x%X)" % (xy3[0] + box[lists.index(p3[0])]), same == [True] * 5 + [False, True, True])
    check("readers: `ld XIZ,0x00F0413E` at 0xF5BE44, `ld XIZ,0x00F04152` at 0xF5BE3D, then `add XIZ,XWA / "
          "ld XIY,(XIZ) / ld XIX,XIY / add XIX,42 / call T_DisplayList_Run` (0xF5BE49-0xF5BE55)",
          at(0xF5BE44, 5).hex() == "463e41f000" and at(0xF5BE3D, 5).hex() == "465241f000"
          and at(0xF5BE49, 16).hex() == "e886a625ed8cecc82a0000001df017f4")
    check("readers: `ld XIZ,0x00F0415E` at 0xF5BE01, `ld XIZ,0x00F04172` at 0xF5BDFA, then `push XWA / "
          "add XIZ,XWA / ld WA,(XIZ) / ld (0x2350),WA / ld WA,(XIZ+2) / ld (0x2352),WA`",
          at(0xF5BE01, 5).hex() == "465e41f000" and at(0xF5BDFA, 5).hex() == "467241f000"
          and at(0xF5BE06, 3).hex() == "38e886" and at(0xF5BE0B, 4).hex() == "f1502350")
    check("index XWA = 4 * (0x27A3) (`ld A,(0x27a3)` at 0xF5BDEC, `sla 2,WA` at 0xF5BDF0); "
          "`cp (0x27f5),1` at 0xF5BDF3 and 0xF5BE36 picks the 3-entry tables",
          at(0xF5BDEC, 4).hex() == "c1a32721" and at(0xF5BDF0, 3).hex() == "d8ec02"
          and at(0xF5BDF3, 5).hex() == "c1f5273f01" and at(0xF5BE36, 5).hex() == "c1f5273f01")
    check("0xF5BDCC: `ld XIX,0x00F04042 / call T_DisplayList_Run` -- also the END of the list before",
          at(0xF5BDCC, 9).hex() == "444240f0001df017f4")
    return dict(b=b, lists=lists, recs=recs, p5=p5, p3=p3, xy5=xy5, xy3=xy3)


def wrap(t):
    return textwrap.wrap(t, width=78, initial_indent="; ", subsequent_indent=";   ")


def emit(d):
    b = d["b"]
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    out = ["; " + "-" * 74]
    out += wrap("DL_TouchCurve_0..5 -- 0xF04042-0xF0413D, six interpreter-A lists of 42 bytes (4 "
                "records each): the captions TOUCH and CURVE (op 0x17), a box (op 0x22) and a line "
                "(op 0x01), the same picture at six places.  Run one at a time by sub_F5BDBB through "
                "TouchCurve_ListPtrs / TouchCurve_ListPtrs3 (`ld XIY,(XIZ) / ld XIX,XIY / add XIX,42 / "
                "call T_DisplayList_Run` at 0xF5BE4B-0xF5BE55).  0xF04042 is also the END of the list "
                "before it (`ld XIX,0x00F04042` at 0xF5BDCC).  notes/promb-2026-09-25/"
                "touch_curve_lists.py.")
    out.append("; " + "-" * 74)
    for k, (s, r) in enumerate(zip(d["lists"], d["recs"])):
        out.append("DL_TouchCurve_%d:" % k)
        out += [x for x in "".join(DL.render(b, r, hta, set())).rstrip("\n").split("\n")]
    tabs = [
        ("TouchCurve_ListPtrs", PT5, d["p5"], "5 pointers to DL_TouchCurve_*, entry (0x27A3) when "
         "(0x27F5) != 1: `ld XIZ,this` at 0xF5BE44, then `add XIZ,XWA / ld XIY,(XIZ)`, XWA = 4 * "
         "(0x27A3).  5 = the distance to TouchCurve_ListPtrs3 over 4."),
        ("TouchCurve_ListPtrs3", PT3, d["p3"], "3 pointers, the same when (0x27F5) == 1 (`cp "
         "(0x27f5),1` at 0xF5BE36, `ld XIZ,this` at 0xF5BE3D).  3 = the distance to "
         "TouchCurve_BoxOrigins over 4."),
    ]
    for nm, a, ps, text in tabs:
        out += wrap("%s -- 0x%06X: %s" % (nm, a, text))
        out.append("%s:" % nm)
        for k, p in enumerate(ps):
            out.append("\t.long\t0x%08X\t; %06X  [%d] -> DL_TouchCurve_%d" % (p, a + 4 * k, k,
                                                                             d["lists"].index(p)))
    xy = [
        ("TouchCurve_BoxOrigins", XY5, d["xy5"], "5 (x, y) word pairs, entry (0x27A3) when (0x27F5) "
         "!= 1 -> (0x2350), (0x2352): `ld XIZ,this` at 0xF5BE01, then `add XIZ,XWA / ld WA,(XIZ) / ld "
         "(0x2350),WA / ld WA,(XIZ+2) / ld (0x2352),WA`.  Entry k is the top-left corner of the box "
         "the list TouchCurve_ListPtrs[k] draws.  5 = the distance to TouchCurve_BoxOrigins3 over 4."),
        ("TouchCurve_BoxOrigins3", XY3, d["xy3"], "3 pairs, the same when (0x27F5) == 1 (`ld "
         "XIZ,this` at 0xF5BDFA), matching TouchCurve_ListPtrs3 -- except entry 0, x = 0xA8 where "
         "its list's box starts at x = 0xE0; they end the object at 0xF0417D."),
    ]
    for nm, a, ps, text in xy:
        out += wrap("%s -- 0x%06X: %s" % (nm, a, text))
        out.append("%s:" % nm)
        for k, (x, y) in enumerate(ps):
            out.append("\t.short\t%d, %d\t; %06X  [%d]" % (x, y, a + 4 * k, k))
    return out


OLD_EXTENT = ("; ⚠ The extent is the reachability walk's, not the object's; the rest of\n"
              ";   this span is unreachable and stays `.incbin`.  Why this is data and\n"
              ";   not code: THE PROVENANCE SPLIT in notes/gen_prom_b_cover_round1.py.").encode(
                  "utf-8").decode("latin-1")
NEW_EXTENT = ("; ⚠ CORRECTED: that extent came from the coverage walk, not from the object;\n"
              ";   its readers split it into the six lists and four tables below\n"
              ";   (notes/promb-2026-09-25/touch_curve_lists.py).  The rest of this span\n"
              ";   is unreachable and stays `.incbin`.  Why this is data and not code: THE\n"
              ";   PROVENANCE SPLIT in notes/gen_prom_b_cover_round1.py.").encode("utf-8").decode("latin-1")


def apply(d):
    L = open(SRC, "rb").read().decode("latin-1").split("\n")
    i = [k for k, t in enumerate(L) if t == "Data_F04042:"][0]
    h = i
    while L[h - 1].startswith(";"):
        h -= 1
    head = "\n".join(L[h:i])
    assert OLD_EXTENT in head
    head = head.replace(OLD_EXTENT, NEW_EXTENT).replace(
        "; Data_F04042 -- 316 bytes, EMITTED AS DATA", "; 0xF04042-0xF0417D -- 316 bytes, EMITTED AS DATA")
    e = i + 1
    while L[e].startswith("\t.byte"):
        e += 1
    new = head.split("\n") + [x.encode("utf-8").decode("latin-1") for x in emit(d)[1:]]
    L = L[:h] + new + L[e:]
    txt = "\n".join(L)
    # the code's references: `Data_F04042 + off` -> the object at that offset
    names = [(0, "DL_TouchCurve_0")] + [(42 * k, "DL_TouchCurve_%d" % k) for k in range(1, 6)] + \
            [(PT5 - LO, "TouchCurve_ListPtrs"), (PT3 - LO, "TouchCurve_ListPtrs3"),
             (XY5 - LO, "TouchCurve_BoxOrigins"), (XY3 - LO, "TouchCurve_BoxOrigins3")]

    def repl(m):
        off = int(m.group(1), 16) if m.group(1) else 0
        st, nm = max((x for x in names if x[0] <= off), key=lambda x: x[0])
        return nm if off == st else "%s + 0x%X" % (nm, off - st)
    txt = re.sub(r'\bData_F04042(?: \+ (0x[0-9A-Fa-f]+))?\b', repl, txt)
    open(SRC, "wb").write(txt.encode("latin-1"))
    print("wrote", SRC)


def main():
    d = derive()
    if FAIL:
        print("\nVERDICT: FAIL (%d)" % len(FAIL))
        return 1
    if "--apply" in sys.argv:
        apply(d)
    print("\nVERDICT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
