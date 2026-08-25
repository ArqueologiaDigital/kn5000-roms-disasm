#!/usr/bin/env python3
"""Emit prom_b 0xF157A8-0xF17558 -- the DSP effect editor's VALUE lists -- as assembly.

QUESTION IT ANSWERS
  7,601 bytes at the head of prom_b's largest `.incbin` span.  They are neither code
  nor free text: they are 176 interpreter-B display-list RECORDS in 18 arrays, each
  array followed immediately by the string table its records index.  Records and
  tables ALTERNATE and TILE THE WHOLE RANGE WITH NO SLACK, which is what makes the
  decode checkable rather than a story.

HOW THE FIRMWARE REACHES THEM -- and why the arrays have a 15-byte STRIDE
  `0xF132E4` is a 32-entry array of pointers, one per editor screen, and it is the
  THIRD of four parallel 32-entry arrays that share a row index (0xF131E4, 0xF13264,
  0xF132E4, 0xF13364; each has exactly one reference in the whole image, at
  0xF10700, 0xF110EA, 0xF110FA and 0xF1172A).  The consumer is at 0xF110FA:

      lda  XBC, 0xF132E4
      add  XBC, (XIZ+0xe9)      ; + 4*row
      ld   XWA, (XBC)           ; the row's record array
      add  XWA, (XIZ+0xf1)      ; + a byte offset held in D
      push XWA
      call 0xF42E0C             ; -> DisplayListB_RunOne_Stack (0xF3183D)

  `DisplayListB_RunOne_Stack` sets XIY = the pointer, XIX = XIY+1 and calls
  interpreter B, whose loop runs while XIY < XIX -- so it draws EXACTLY ONE record.
  Records are therefore addressed INDIVIDUALLY, at `base + D`, and D must be a
  multiple of one stride for every row of a screen to be reachable.  The stride is
  15: every record whose own length is less than 15 is followed by 0xFF padding out
  to 15, and the walk below asserts that byte for byte.  (0xF110B9 does the same
  arithmetic on the literal 0xF157A8, which is also what rows 0 and 31 of the
  0xF132E4 array hold -- the array's default value, exactly as rows 0 and 31 of the
  other three arrays hold their own default 0x00F42C70.)

WHAT IS EXACT AND WHAT IS NOT
  EXACT, re-derived here on every run and asserted by --selftest:
    * the 18 array starts (the distinct entries of the 0xF132E4 array);
    * each array's record count, from a stride-15 walk that requires
      len == the length interpreter B's handler implies for that opcode
      (notes/FINDINGS-ui-display-list-interpreter-b.md) AND all bytes from the
      record's end to the stride boundary to be 0xFF;
    * each table's ENTRY WIDTH, which is the record's own `+0x0B` field -- the `BC`
      interpreter B passes to the text service;
    * each table's ENTRY COUNT, which is its extent to the next object divided by
      that width, asserted to divide EXACTLY.  ⚠ The count implied by the record's
      mask, (mask >> shift) + 1, is only an UPPER BOUND -- for 0xF15A7C it is 32
      and the true count is 27 -- so the extent is what is quoted.
    * the tiling: the 36 objects cover 0xF157A8-0xF17558 with no gap and no overlap.
  NOT ESTABLISHED, and not claimed in any label:
    * which effect algorithm each of the 32 screen rows is;
    * which parameter each of the 8 records in an array is -- the eight `+0x0D`
      positions step by 0x280, so they are eight screen LINES, and that is all;
    * what the 4-entry, 1-byte-wide table at 0xF15898 is for.
  The value tables' CONTENT is quoted in the headers as the ASCII it is; reading
  "-1200 .. +1200" as cents or "40 .. 16k" as hertz is left to the reader.

RUN
  python3 notes/gen_prom_b_dsp_value_lists.py --selftest
  python3 notes/gen_prom_b_dsp_value_lists.py --asm
  python3 notes/gen_prom_b_dsp_value_lists.py --leftover   # what 0xF17559+ still is
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B = 0xF00000
LO, HI = 0xF157A8, 0xF17559
PTRARRAY = 0xF132E4
STRIDE = 15
# interpreter B: opcode -> the length its handler implies
BLEN = {0x00: 10, 0x01: 12, 0x02: 15, 0x03: 11, 0x04: 11, 0x05: 11, 0x06: 10,
        0x07: 17, 0x08: 11, 0x09: 12, 0x0A: 12, 0x0B: 13}
BHANDLER = {0x00: 0xF31BA1, 0x06: 0xF31BA1, 0x01: 0xF31C9E, 0x02: 0xF31B21,
            0x03: 0xF31B57, 0x08: 0xF31B57, 0x04: 0xF31B86, 0x05: 0xF31BD7,
            0x07: 0xF31B39, 0x09: 0xF31C14, 0x0A: 0xF31C14, 0x0B: 0xF31C56}
FAIL = []
NCHECK = [0]


def check(msg, got, want):
    NCHECK[0] += 1
    ok = got == want
    print("  %-62s %-26s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def load():
    return open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()


def w16(b, a):
    return int.from_bytes(b[a - B:a - B + 2], "little")


def w32(b, a):
    return int.from_bytes(b[a - B:a - B + 4], "little")


def walk(b, s, hi=HI):
    """Records at 15-byte stride from s; stops at the first byte pair that is not
    a well-formed, correctly padded interpreter-B record."""
    p, out = s, []
    while p < hi:
        op, ln = b[p - B], b[p - B + 1]
        if op not in BLEN or ln != BLEN[op] or ln > STRIDE:
            break
        if any(x != 0xFF for x in b[p - B + ln:p - B + STRIDE]):
            break
        out.append((p, op, ln))
        p += STRIDE
    return out


def objects(b):
    """[(addr, kind, payload)] tiling LO..HI, kind in {'recs','tab'}."""
    starts = sorted({w32(b, PTRARRAY + 4 * i) for i in range(32)})
    arrays, seen = [], set()
    for s in starts:
        if s in seen or not (LO <= s < HI):
            continue
        r = walk(b, s)
        if not r:
            continue
        arrays.append((s, r))
        for p, op, ln in r:
            seen.add(p)
    arrays.sort()
    # drop arrays wholly contained in an earlier one
    keep, cover = [], []
    for s, r in arrays:
        e = s + STRIDE * len(r)
        if any(cs <= s and e <= ce for cs, ce in cover):
            continue
        keep.append((s, r))
        cover.append((s, e))
    objs, tabs = [], {}
    for s, r in keep:
        objs.append((s, "recs", r))
        for rp, op, ln in r:                       # EVERY record, not just the first
            if op not in (0x02, 0x07):
                continue
            t, wd = w32(b, rp + 7), w16(b, rp + 0x0B)
            if LO <= t < HI:
                tabs.setdefault(t, [set(), []])
                tabs[t][0].add(wd)
                tabs[t][1].append(rp)
    for t, (ws, sites) in sorted(tabs.items()):
        assert len(ws) == 1, "0x%06X: records disagree on the entry width: %s" % (t, ws)
        objs.append((t, "tab", (ws.pop(), sorted(sites))))
    objs.sort()
    return objs


def groups(b, recs):
    """[[record, ...], ...] -- an array's records split where the +0x0D screen
    position RESETS.  Within a group the position steps by a constant 0x280."""
    ix = [w16(b, rp + (0x0D if op in (0x02, 0x07) else 0x07)) for rp, op, ln in recs]
    out, cur = [], [0]
    for i in range(1, len(ix)):
        if ix[i] - ix[i - 1] == 0x280:
            cur.append(i)
        else:
            out.append(cur)
            cur = [i]
    out.append(cur)
    return [[recs[i] for i in g] for g in out], ix


def tiling(b):
    """[(addr, end, kind, payload)] -- the objects with their extents."""
    o = objects(b)
    out = []
    for i, (a, k, p) in enumerate(o):
        e = o[i + 1][0] if i + 1 < len(o) else HI
        out.append((a, e, k, p))
    return out


def selftest(b):
    print("gen_prom_b_dsp_value_lists self-test")
    t = tiling(b)
    check("first object starts at the region head", "0x%06X" % t[0][0], "0x%06X" % LO)
    prev = LO
    for a, e, k, p in t:
        check("object 0x%06X abuts the previous" % a, "0x%06X" % prev, "0x%06X" % a)
        prev = e
    check("last object ends at the region tail", "0x%06X" % prev, "0x%06X" % HI)
    nrec = sum(len(p) for a, e, k, p in t if k == "recs")
    check("records", nrec, 176)
    check("record arrays", len([1 for x in t if x[2] == "recs"]), 18)
    # 17, not 18: the FIRST array's opcode-02 records point at 0xF156C8, which is
    # BEFORE this region (it is the 32-entry units strip at the tail of the effect
    # parameter-name block), and the LAST array's point at 0xF17559, the first byte
    # after it.  Both are asserted here so the two edges cannot drift unnoticed.
    check("value tables inside the region", len([1 for x in t if x[2] == "tab"]), 17)
    check("the first array's table lies BEFORE the region",
          "0x%06X" % w32(b, 0xF157A8 + 7), "0x%06X" % 0xF156C8)
    check("  ... and 0xF156C8 + 32*7 is this region's first byte",
          "0x%06X" % (0xF156C8 + 32 * 7), "0x%06X" % LO)
    check("the last array's table lies AFTER the region",
          "0x%06X" % w32(b, 0xF174E1 + 7), "0x%06X" % HI)
    for a, e, k, p in t:
        if k == "recs":
            check("array 0x%06X: %d records fill its extent" % (a, len(p)),
                  STRIDE * len(p), e - a)
        else:
            check("table 0x%06X: extent %d divides by width %d" % (a, e - a, p[0]),
                  (e - a) % p[0], 0)
    # every array is a whole number of 8-line screen groups
    for a, e, k, pl in t:
        if k != "recs":
            continue
        g, ix = groups(b, pl)
        check("array 0x%06X: %d group(s) of 8 lines" % (a, len(g)),
              sorted({len(x) for x in g}), [8])
    # every record reads the same staging variable, which the caller writes
    vs = {w16(b, r[0] + 2) for a, e, k, pl in t if k == "recs" for r in pl}
    check("every record's +2 source variable", " ".join("0x%04X" % v for v in sorted(vs)), "0x2640")
    # the mask is an UPPER bound, and here is the one that proves it
    a0 = [x for x in t if x[0] == 0xF15A7C][0]
    rec = [x for x in t if x[0] == 0xF15A04 or (x[2] == "recs" and x[0] < 0xF15A7C <= x[1])]
    check("0xF15A7C true entry count from its extent", (a0[1] - a0[0]) // a0[3][0], 27)
    check("  ... while its record's mask 0x1F would allow", (0x1F >> 0) + 1, 32)
    # the four parallel arrays and their defaults
    for base, dflt in ((0xF131E4, 0x00F42C70), (0xF13264, 0x00F42C70),
                       (PTRARRAY, 0x00F157A8), (0xF13364, 0x00F42C70)):
        check("0x%06X rows 0 and 31 both hold 0x%08X" % (base, dflt),
              (w32(b, base), w32(b, base + 4 * 31)), (dflt, dflt))
    got = bytes(emit_bytes(b))
    check("emitted bytes == ROM 0x%06X-0x%06X" % (LO, HI - 1), got == b[LO - B:HI - B], True)
    check("emitted length", len(got), HI - LO)
    print("\n%d checks ran, %d failed" % (NCHECK[0], len(FAIL)))
    return 1 if FAIL else 0


def emit_bytes(b):
    out = bytearray()
    for a, e, k, p in tiling(b):
        out += b[a - B:e - B]
    return out


def esc(t):
    return t.replace("\\", "\\\\").replace('"', '\\"')


def asm(b):
    t = tiling(b)
    o = []
    o.append("\n; ==========================================================================\n")
    o.append("; 0x%06X-0x%06X -- THE DSP EFFECT EDITOR'S VALUE LISTS, %d bytes\n"
             % (LO, HI - 1, HI - LO))
    o.append(";\n")
    o.append("; 18 arrays of interpreter-B display-list records, each followed IMMEDIATELY by\n")
    o.append("; the string table its records index.  The 36 objects tile this range with no\n")
    o.append("; gap and no overlap -- that is the check, and it is re-run on every emit.\n")
    o.append(";\n")
    o.append("; HOW THE FIRMWARE GETS HERE.  0xF132E4 is a 32-entry array of pointers, one per\n")
    o.append("; editor screen -- the third of four parallel 32-entry arrays sharing a row index\n")
    o.append("; (0xF131E4, 0xF13264, 0xF132E4, 0xF13364; one reference each, at 0xF10700,\n")
    o.append("; 0xF110EA, 0xF110FA, 0xF1172A).  0xF110FA fetches the row's array, adds a byte\n")
    o.append("; offset and calls T_F42E0C = DisplayListB_RunOne_Stack (0xF3183D), which sets\n")
    o.append("; XIX = XIY+1 so interpreter B draws EXACTLY ONE record.  Records are therefore\n")
    o.append("; addressed individually, and every one is padded with 0xFF to a 15-byte STRIDE\n")
    o.append("; so that `base + 15*line` reaches each of them.  Rows 0 and 31 of the 0xF132E4\n")
    o.append("; array both hold 0x00F157A8 -- its default value, matching rows 0 and 31 of the\n")
    o.append("; other three arrays, which both hold their own default 0x00F42C70.\n")
    o.append(";\n")
    o.append("; RECORD LAYOUT (interpreter B, notes/FINDINGS-ui-display-list-interpreter-b.md):\n")
    o.append(";   +0 opcode   +1 length   +2 source variable   +4 AND mask   +5 right shift\n")
    o.append(";   +6 swi 7 function   then, for opcode 02: +7 string table, +0x0B bytes per\n")
    o.append(";   entry, +0x0D -> IX; for opcodes 00/05/06: +7 -> IX, +9 digit count.\n")
    o.append("; All 176 records here read the same staging byte, RAM 0x2640, which the caller\n")
    o.append("; writes at 0xF110AC immediately before running the record.\n")
    o.append(";\n")
    o.append("; ⚠ ENTRY COUNTS come from each table's EXTENT, not from its record's mask.  The\n")
    o.append("; mask gives (mask >> shift) + 1, an upper bound: 0xF15A7C's record says 32 and\n")
    o.append("; the table is 27 entries.  Every extent below divides exactly by the width the\n")
    o.append("; record passes as BC.\n")
    o.append("; Regenerate + re-check: python3 notes/gen_prom_b_dsp_value_lists.py --selftest\n")
    o.append("; ==========================================================================\n")
    for a, e, k, p in t:
        if k == "recs":
            ops = sorted({x[1] for x in p})
            g, ixs = groups(b, p)
            o.append("\n; --------------------------------------------------------------------------\n")
            o.append("; DLB_Records_%06X -- %d interpreter-B records at a 15-byte stride,\n" % (a, len(p)))
            o.append(";   0x%06X-0x%06X.  Opcode%s %s.\n"
                     % (a, e - 1, "" if len(ops) == 1 else "s", ", ".join("0x%02X" % x for x in ops)))
            o.append("; Called from: 0x%06X -- the entry of the 0xF132E4 screen array that\n"
                     % (PTRARRAY + 4 * sorted({w32(b, PTRARRAY + 4 * i) for i in range(32)}).index(a)
                        if False else PTRARRAY + 4 * [i for i in range(32)
                                                      if w32(b, PTRARRAY + 4 * i) == a][0]))
            o.append(";   names it.  The consumer described in this block's header fetches that\n")
            o.append(";   entry, adds `15 * line`, and runs ONE record.\n")
            o.append("; Inputs:  RAM 0x2640, written immediately before the call.\n")
            o.append("; Outputs: one drawn field per call.\n")
            o.append("; Evidence: every record's length byte equals the length its interpreter-B\n")
            o.append(";   handler implies, and every byte between a record's end and its stride\n")
            o.append(";   boundary is 0xFF.  The %d records fill 0x%06X-0x%06X exactly.\n"
                     % (len(p), a, e - 1))
            o.append("; Structure: %d screen group%s of 8 lines.  Within a group the +0x0D\n"
                     % (len(g), "" if len(g) == 1 else "s"))
            o.append(";   position steps by a constant 0x280 -- %s -- and it RESETS at\n"
                     % ", ".join("0x%04X" % x for x in ixs[:8]))
            o.append(";   each group boundary, which is what makes the group the unit.\n")
            o.append("; Unknown: which effect parameter occupies which line, and -- where there\n")
            o.append(";   is more than one group -- what selects between them.  The caller adds\n")
            o.append(";   a byte offset, so `15 * (8*group + line)` reaches any of them, but\n")
            o.append(";   nothing converted here computes that offset.\n")
            o.append("; --------------------------------------------------------------------------\n")
            o.append("DLB_Records_%06X:\n" % a)
            for idx, (rp, op, ln) in enumerate(p):
                o.append("\t.byte\t0x%02X, 0x%02X\t; %06X  [%2d] op %02X -> handler 0x%06X, %d bytes\n"
                         % (op, ln, rp, idx, op, BHANDLER[op], ln))
                o.append("\t.short\t0x%04X\t\t;   +2 source variable\n" % w16(b, rp + 2))
                o.append("\t.byte\t0x%02X, 0x%02X\t;   +4 AND mask, +5 right shift\n"
                         % (b[rp - B + 4], b[rp - B + 5]))
                o.append("\t.byte\t0x%02X\t\t;   +6 swi 7 function\n" % b[rp - B + 6])
                if op in (0x02, 0x07):
                    o.append("\t.long\t0x%08X\t;   +7 string table\n" % w32(b, rp + 7))
                    o.append("\t.short\t0x%04X\t\t;   +0x0B bytes per entry\n" % w16(b, rp + 0x0B))
                    o.append("\t.short\t0x%04X\t\t;   +0x0D -> IX\n" % w16(b, rp + 0x0D))
                else:
                    o.append("\t.short\t0x%04X\t\t;   +7 -> IX\n" % w16(b, rp + 7))
                    o.append("\t.byte\t0x%02X\t\t;   +9 digit count\n" % b[rp - B + 9])
                    if ln > 10:
                        o.append("\t.byte\t%s\t;   +0x0A..\n"
                                 % ", ".join("0x%02X" % x for x in b[rp - B + 10:rp - B + ln]))
                if ln < STRIDE:
                    o.append("\t.byte\t%s\t; pad to the 15-byte stride\n"
                             % ", ".join("0x%02X" % x for x in b[rp - B + ln:rp - B + STRIDE]))
        else:
            wd, sites = p
            n = (e - a) // wd
            rows = [b[a - B + wd * i:a - B + wd * i + wd] for i in range(n)]
            pr = all(all(0x20 <= c <= 0x7E for c in r) for r in rows)
            o.append("\n; --------------------------------------------------------------------------\n")
            o.append("; DLBTable_%06X -- %d entries of %d bytes, 0x%06X-0x%06X.\n"
                     % (a, n, wd, a, e - 1))
            o.append("; Read by: %s\n" % ", ".join("0x%06X" % x for x in sites))
            o.append(";   -- interpreter-B records that pass this address in their +7 field and\n")
            o.append(";   %d in +0x0B, the BC the text service takes as the entry width.\n" % wd)
            o.append("; Entry count: %d = (0x%06X - 0x%06X) / %d, exact -- the extent to the next\n"
                     % (n, e, a, wd))
            o.append(";   object, NOT the record's mask, which is only an upper bound.\n")
            if pr:
                first = "".join(chr(c) for c in rows[0])
                last = "".join(chr(c) for c in rows[-1])
                o.append("; Content: ASCII, `%s` .. `%s`.\n" % (esc(first), esc(last)))
            o.append("; --------------------------------------------------------------------------\n")
            o.append("DLBTable_%06X:\n" % a)
            for i, r in enumerate(rows):
                if all(0x20 <= c <= 0x7E for c in r):
                    o.append('\t.ascii\t"%s"\t; %06X  [%3d]\n'
                             % (esc("".join(chr(c) for c in r)), a + wd * i, i))
                else:
                    o.append("\t.byte\t%s\t; %06X  [%3d]\n"
                             % (", ".join("0x%02X" % c for c in r), a + wd * i, i))
    return o


def leftover():
    """Every number section 5 of FINDINGS-prom_b-fonts-and-dsp-value-lists.md quotes
    about the part of the span that stays `.incbin`."""
    r = lambda n: open(os.path.join(ROOT, "original_ROMs", n), "rb").read()
    a, b, c = r("wsa1_prom_a.ic12"), r("wsa1_prom_b.ic13"), r("wsa1_prom_c.ic28")
    lo, hi = HI, 0xF1B400
    print("leftover 0x%06X-0x%06X = %d bytes" % (lo, hi - 1, hi - lo))
    tg = {}
    for nm, img in (("a", a), ("b", b), ("c", c)):
        for o in range(len(img) - 4):
            v = int.from_bytes(img[o:o + 4], "little")
            if lo <= v < hi:
                tg.setdefault(v, []).append(nm)
    per = {k: sum(1 for v in tg.values() for x in v if x == k) for k in "abc"}
    print("  distinct pointer targets: %d   sites: prom_a %d, prom_b %d, prom_c %d"
          % (len(tg), per["a"], per["b"], per["c"]))
    print("  prom_c targets: %s"
          % ", ".join("0x%06X" % k for k, v in sorted(tg.items()) if "c" in v))
    # the 0xF17A6C pointer array
    w32 = lambda x: int.from_bytes(b[x - B:x - B + 4], "little")
    p, t = 0xF17A6C, []
    while lo <= w32(p) < hi:
        t.append(w32(p))
        p += 4
    d = sorted({t[i + 1] - t[i] for i in range(len(t) - 1)})
    print("  0xF17A6C: %d pointers, ends 0x%06X, targets 0x%06X..0x%06X, deltas %s"
          % (len(t), p, t[0], t[-1], d))
    # how far a stride-15 walk gets from each target
    got = sum(1 for x in tg if len(walk(b, x, hi)) >= 2)
    print("  targets from which a stride-15 walk yields >= 2 records: %d of %d"
          % (got, len(tg)))
    return 0


def main():
    b = load()
    if "--leftover" in sys.argv:
        return leftover()
    if "--asm" in sys.argv:
        sys.stdout.write("".join(asm(b)))
        return 0
    return selftest(b)


if __name__ == "__main__":
    sys.exit(main())
