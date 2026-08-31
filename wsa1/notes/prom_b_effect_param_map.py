#!/usr/bin/env python3
"""Is EffectNames entry k the name of DSP effect algorithm k?  YES -- and this
is the measurement, with its negative control.

WHAT QUESTION THIS ANSWERS
    `EffectNames_F147AC`'s header has carried this since it was converted:

      ⚠ Unknown: that entry k is effect algorithm k.  The block at
        0xF0EA9F-0xF13D33 has three 128-entry tables indexed from (0x2796);
        128 and 128 is a CORRESPONDENCE, not a decoded fact.

    and `DataPtrTable_F12F24`'s says `Unknown: what indexes it, and what the
    entries mean`.  Both close here, and the second answers the first.

THE CHAIN, EACH LINK READ OUT OF THE ROM
  1. `DspEffect_LoadParamNames` (0xF10FF1) computes `BC = 4 * (0x2796)`, adds it
     to 0xF12F24, and DEREFERENCES the pointer it finds -- so the 128-entry
     pointer table is indexed by (0x2796).
  2. From the descriptor it reads EIGHT bytes at stride 4, starting at
     `4 * (0x2792)`, and stores them at RAM (0x2640)-(0x2647).
  3. It then runs the display list 0xF14FAC-0xF15023 -- 0x78 bytes, which is
     EXACTLY eight interpreter-B records of 15 -- and record j is
     `02 0F | 40+j 26 | FF | 00 | 20 | <0x00F15024> | <0x0011> | <cursor>`:
     source variable (0x2640+j), full mask, `swi 7` function 0x20
     (LCD_Svc_20_DrawText8x10), table base EffectParamNames_F15024, entry width
     17.  The eight bytes step 1 goes to are the eight rows step 3 draws, and
     17 is the row stride EffectParamNames' own header already states.
  4. So descriptor byte 4*j is a row of EffectParamNames, i.e. the NAME of the
     effect's j-th parameter.

★ THE CONTROL IS AN IDENTITY OF TWO PARTITIONS, NOT A PAIR OF EQUAL COUNTS
    The pointer table has 57 distinct values over 128 slots: 56 used once, and
    ONE (0xF124EC) used 72 times.  EffectNames has 56 real names and 72
    `----------` placeholders.  **The 72 slots that share the pointer are
    exactly the 72 slots that carry the placeholder** -- the symmetric
    difference of the two sets is EMPTY.  That is not "128 and 128"; it is one
    56/72 partition of 0..127 derived from a pointer table matching another
    derived from a string table, and there are C(128,72) ~ 10^37 ways for it to
    have failed.

★ AND A RANGE CONTROL
    All 8 x 57 = 456 descriptor bytes this reads land in rows 0-99 of
    EffectParamNames, and rows 0-99 are exactly the PARAMETER-LABEL rows: 99 of
    those 100 end in `:` (row 0 is the blank), while rows 100-112 -- the object
    runs to 113 rows of 17, as `FINDINGS-prom_b-f0ea9f-module.md` sec. 4b already
    states -- do not.  A random byte is < 100 with probability 0.39, so 456 of
    456 is 0.39^456, and not one of them lands in the 13 rows that are not
    labels.

    ⚠ CORRECTED 2026-08-31: this said "EffectParamNames has exactly 100 rows".
    It does not; it has 113, and only the first 100 are the labelled ones.  The
    control is unaffected -- it is sharper this way -- but the wrong number was
    quoted first and is recorded here rather than quietly replaced.

WHAT IS NOT CLAIMED
    Only byte 0 of each four-byte descriptor group is decoded, because that is
    the only one 0xF10FF1 reads.  Bytes 1-3 are printed by --raw and are NOT
    interpreted; the guess that byte 1 selects one of the 18 value-name lists at
    0xF157A8 is a guess and is written down as one.
    How many groups a descriptor has is bounded by the next descriptor's
    address, not by a terminator this script trusts.
    (0x2792) is called a SCROLL POSITION because it offsets the eight-byte
    window into a longer descriptor; nothing here shows a user scrolling.

RUN
    python3 notes/prom_b_effect_param_map.py            # every effect + its parameters
    python3 notes/prom_b_effect_param_map.py --raw      # descriptors, undecoded
    python3 notes/prom_b_effect_param_map.py --selftest # 20 checks, 3 of them controls
"""
import collections
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B = 0xF00000
PTRTAB = 0xF12F24            # 128 x .long, indexed by 4 * (0x2796)
NAMES = 0xF147AC             # 128 x 16 ASCII
PARAMS = 0xF15024            # 100 x 17 ASCII
PARAM_ROWS, PARAM_W = 100, 17   # the LABEL rows; the object itself runs to 113
PARAM_TOTAL_ROWS = 113
DL = (0xF14FAC, 0xF15024)    # the 8-record parameter page
NPROG = 128
PLACEHOLDER = "----------"

with open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb") as _f:
    ROM = _f.read()


def u32(a):
    return int.from_bytes(ROM[a - B:a - B + 4], "little")


def u16(a):
    return int.from_bytes(ROM[a - B:a - B + 2], "little")


def txt(a, n):
    return "".join(chr(c) if 0x20 <= c < 0x7F else "." for c in ROM[a - B:a - B + n])


def ptrs():
    return [u32(PTRTAB + 4 * k) for k in range(NPROG)]


def effect_name(k):
    return txt(NAMES + 16 * k, 16)


def param_name(i):
    return txt(PARAMS + PARAM_W * i, PARAM_W)


def descriptor(p, groups=8):
    """The parameter-NAME index of each 4-byte group; byte 0 only."""
    return [ROM[p - B + 4 * j] for j in range(groups)]


def records():
    """The 8 interpreter-B records of the parameter page."""
    lo, hi = DL
    out = []
    for j in range((hi - lo) // 15):
        a = lo + 15 * j
        out.append(dict(addr=a, opcode=ROM[a - B], length=ROM[a - B + 1],
                        var=u16(a + 2), mask=ROM[a - B + 4], shift=ROM[a - B + 5],
                        svc=ROM[a - B + 6], table=u32(a + 7), width=u16(a + 0x0B),
                        cursor=u16(a + 0x0D)))
    return out


def report(raw=False):
    p = ptrs()
    c = collections.Counter(p)
    catch = max(c, key=lambda x: c[x])
    print(f"pointer table 0xF12F24: {NPROG} entries, {len(c)} distinct, "
          f"catch-all 0x{catch:06X} used {c[catch]} times\n")
    print("the parameter page, 0x%06X-0x%06X, 8 records of 15:" % (DL[0], DL[1] - 1))
    for r in records():
        row, col = divmod(r["cursor"], 40)
        print(f"  0x{r['addr']:06X} var=(0x{r['var']:04X}) svc=0x{r['svc']:02X} "
              f"table=0x{r['table']:06X} width={r['width']} cursor=0x{r['cursor']:04X} "
              f"-> x={col*8} y={row}")
    print()
    for k in range(NPROG):
        if c[p[k]] > 1 and effect_name(k).find(PLACEHOLDER) >= 0:
            continue
        idx = descriptor(p[k])
        if raw:
            print(f"{k:3d} {effect_name(k)!r} 0x{p[k]:06X}  " +
                  " ".join("%02X" % ROM[p[k] - B + i] for i in range(32)))
            continue
        pn = [param_name(i).rstrip(": ").strip() for i in idx]
        print(f"{k:3d} {effect_name(k).strip()}")
        print("     " + " | ".join(x for x in pn if x))
    print(f"\n{sum(1 for k in range(NPROG) if c[p[k]] == 1)} effects with their own descriptor; "
          f"the other {c[catch]} share the catch-all and are all named "
          f"`{PLACEHOLDER}`.")


CHECKS = []


def ck(cond, what):
    CHECKS.append((bool(cond), what))


def selftest():
    p = ptrs()
    c = collections.Counter(p)
    ck(len(p) == NPROG, "128 pointer entries")
    ck(all(0xF00000 <= x < 0xF80000 for x in p), "every entry is inside this image")
    ck(len(c) == 57, f"57 distinct descriptors ({len(c)})")
    mult = sorted(c.values(), reverse=True)
    ck(mult[0] == 72 and mult[1] == 1, "one descriptor is shared 72 times, the rest once")

    # ★ CONTROL 1: the two 56/72 partitions are the SAME partition
    shared = {k for k in range(NPROG) if c[p[k]] > 1}
    place = {k for k in range(NPROG) if PLACEHOLDER in effect_name(k)}
    ck(len(place) == 72, f"72 placeholder names ({len(place)})")
    ck(shared == place, "the slots sharing the catch-all ARE the placeholder slots")
    ck(len(shared ^ place) == 0, "symmetric difference is empty")

    # ★ CONTROL 2: every decoded index lands on a PARAMETER-LABEL row
    bad = [(hex(q), j) for q in set(p) for j in range(8)
           if descriptor(q)[j] >= PARAM_ROWS]
    ck(not bad, f"all {8 * len(set(p))} descriptor indices are < {PARAM_ROWS} ({len(bad)} bad)")
    lab = sum(1 for i in range(PARAM_ROWS) if param_name(i).endswith(":"))
    ck(lab == PARAM_ROWS - 1, f"rows 0-{PARAM_ROWS - 1}: {lab} of {PARAM_ROWS} end in ':' "
                              f"(row 0 is the blank)")
    tail = sum(1 for i in range(PARAM_ROWS, PARAM_TOTAL_ROWS) if param_name(i).endswith(":"))
    ck(tail == 0, f"rows {PARAM_ROWS}-{PARAM_TOTAL_ROWS - 1} are NOT labels "
                  f"({tail} end in ':'), and no index reaches them")

    # the display list
    rs = records()
    ck(DL[1] - DL[0] == 0x78, "the parameter page is 0x78 bytes")
    ck(len(rs) == 8, "which is exactly 8 records of 15")
    ck(all(r["opcode"] == 0x02 and r["length"] == 0x0F for r in rs), "all opcode 0x02, length 15")
    ck([r["var"] for r in rs] == [0x2640 + j for j in range(8)],
       "their source variables are (0x2640)..(0x2647), the eight bytes 0xF10FF1 writes")
    ck(all(r["table"] == PARAMS for r in rs), "every record's table base is EffectParamNames_F15024")
    ck(all(r["width"] == PARAM_W for r in rs), f"every record's entry width is {PARAM_W}")
    ck(all(r["svc"] == 0x20 for r in rs), "every record calls swi7 service 0x20 (the 8x10 font)")
    cur = [r["cursor"] for r in rs]
    ck(all((cur[i + 1] - cur[i]) == 640 for i in range(7)),
       "the eight cursors step by 640 = 16 display lines of 40 bytes")
    ck(all(divmod(x, 40)[1] == 9 for x in cur), "all eight start at column 9, x = 72")

    # the two names the chain is asserted against
    ck(effect_name(0).strip() == "NO OPERATION", "program 0 is NO OPERATION")
    ck(param_name(1).startswith("WET"), "EffectParamNames row 1 is WET")
    ck(descriptor(p[32])[:4] == [1, 2, 3, 4],
       "DISTORTION's first four parameters are rows 1,2,3,4 = WET/DRIVE/ADJUST/VOLUME")

    bad = [w for ok, w in CHECKS if not ok]
    for ok, what in CHECKS:
        print(("  ok   " if ok else "  FAIL ") + what)
    print(f"\n{len(CHECKS) - len(bad)}/{len(CHECKS)} checks passed")
    return 1 if bad else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    report(raw="--raw" in sys.argv)
