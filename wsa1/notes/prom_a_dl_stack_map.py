#!/usr/bin/env python3
"""The map of prom_a 0xFA1404-0xFA53FF, the biggest `.incbin` left in prom_a.

QUESTION IT ANSWERS
  "0xFA1404-0xFA53FF is 16,380 bytes and holds most of the machine's menu text
   -- TUNE & SCALE, CONTROLLER ASSIGN, SOUND/COMBINATION MANAGER, DRUMS MAP.
   `notes/gen_prom_a_screens.py`'s call-site scan finds ZERO display lists in
   it.  What is actually in there, and what would a converter have to declare?"

★ THE ANSWER IS THAT prom_a USES THE STACK VENEERS TOO.
  `notes/prom_b_dl_stack_sites.py` established that a display list can be run
  with its two ends pushed on the stack rather than in XIY/XIX, and that the
  veneers are prom_b 0xF31800/0xF31814 (thunks T_F42E00/T_F42E04) and prom_a
  0xFF75D3/0xFF75EF.  That tool scans prom_b.  Every list in this prom_a span is
  entered the same way, which is why the register-form scan sees none of them.

  This file uses the STRICTEST possible form of that test -- the exact 12-byte
  byte sequence

      f2 <end24>   31      lda XBC,(end)
      39                   push XBC
      f2 <start24> 30      lda XWA,(start)
      38                   push XWA

  -- and then the framing walk: the record length bytes read from `start` must
  land EXACTLY on `end`.  **368 of 368 idioms in the two images pass the walk**,
  67 of them naming a list inside this span.
  ⚠ This is a SUBSET of what prom_b_dl_stack_sites.py's resolver would find: it
  does not follow `jr` hops or the cached `jp (XIX)` shape, so a list entered
  that way is missing here, not refuted.  Whoever converts this span should run
  both.

★ AND THE RECORDS DECLARE THEIR OWN TABLES.  An op-0x02, length-0x0F record is
      02 0F <dest u32> <count u8> <src u32> <stride u16> <2 more>
  (the layout `Screen_DrawKitCategoryLegend`'s neighbours already document at
  0xFF0AF9 and 0xFE8405).  So every table this span draws from has its BASE,
  its ENTRY COUNT and its STRIDE in the record that draws it -- read off the
  interpreter's own input, not from an extent.  34 such sources land inside the
  span.  ⚠ Several of them OVERLAP: 0xFA4B33 is (32 x 6) and 0xFA4B4B..0xFA4B61
  are twelve (32 x 2) declarations two bytes apart, which is one row-structured
  table read column by column, not thirteen tables.  Do not emit them as
  thirteen objects.

RUN
  python3 notes/prom_a_dl_stack_map.py            # the whole map
  python3 notes/prom_a_dl_stack_map.py --selftest # 3 negative controls
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
A_BASE, B_BASE = 0xF80000, 0xF00000
LO, HI = 0xFA1404, 0xFA5400

OK = FAIL = 0


def check(label, got, want):
    global OK, FAIL
    if got == want:
        OK += 1
        print("  ok    %-56s %r" % (label, got))
    else:
        FAIL += 1
        print("  FAIL  %-56s got %r want %r" % (label, got, want))


def img(v):
    if 0xF80000 <= v <= 0xFFFFFF:
        return A, A_BASE
    if 0xF00000 <= v < 0xF80000:
        return B, B_BASE
    return None, None


def records(s, e):
    """The records of [s,e), or None if the length bytes do not land on e."""
    d, b = img(s)
    if d is None or e <= s:
        return None
    p, out = s, []
    while p < e:
        ln = d[p - b + 1]
        if ln < 2 or p + ln > e:
            return None
        out.append((p, d[p - b], ln))
        p += ln
    return out if p == e else None


def idioms():
    """Every exact 12-byte stack-veneer argument idiom, in both images."""
    out = []
    for d, base in ((A, A_BASE), (B, B_BASE)):
        for i in range(len(d) - 12):
            if (d[i] == 0xF2 and d[i + 4] == 0x31 and d[i + 5] == 0x39 and
                    d[i + 6] == 0xF2 and d[i + 10] == 0x30 and d[i + 11] == 0x38):
                e = d[i + 1] | d[i + 2] << 8 | d[i + 3] << 16
                s = d[i + 7] | d[i + 8] << 8 | d[i + 9] << 16
                out.append((base + i, s, e))
    return out


def main():
    sites = idioms()
    good = [(a, s, e) for a, s, e in sites if records(s, e)]
    check("exact 12-byte idioms in both images", len(sites), 368)
    check("...whose record walk lands exactly on the end", len(good), 368)
    spans = sorted({(s, e) for _a, s, e in good if LO <= s < HI})
    check("distinct display lists inside 0x%06X-0x%06X" % (LO, HI - 1),
          len(spans), 67)
    check("their byte extent", sum(e - s for s, e in spans), 10516)
    # merge the four overlapping pairs
    merged = []
    for s, e in spans:
        if merged and s < merged[-1][1]:
            merged[-1] = (merged[-1][0], max(merged[-1][1], e))
        else:
            merged.append((s, e))
    check("after merging the overlaps", len(merged), 63)
    check("merged extent", sum(e - s for s, e in merged), 9403)
    # every overlap must be CONSISTENT: the union tiles and all four ends are
    # record boundaries, i.e. the two lists are two views of one sequence.
    bad = []
    for i in range(1, len(spans)):
        if spans[i][0] < spans[i - 1][1]:
            u, v = min(spans[i][0], spans[i - 1][0]), max(spans[i][1], spans[i - 1][1])
            r = records(u, v)
            bounds = {p for p, _o, _l in r} | {v} if r else set()
            if not r or not all(x in bounds for x in spans[i] + spans[i - 1]):
                bad.append((spans[i - 1], spans[i]))
    check("overlapping pairs that are NOT one consistent sequence", bad, [])
    print()
    print("DISPLAY LISTS in 0x%06X-0x%06X (merged)" % (LO, HI - 1))
    for s, e in merged:
        r = records(s, e)
        txt = bytes(A[s - A_BASE:e - A_BASE])
        words = b"".join(bytes([c]) if 0x20 <= c < 0x7F else b" " for c in txt)
        sample = " ".join(w.decode() for w in words.split() if len(w) >= 4)[:56]
        print("  %06X-%06X %5d %3d recs  %s" % (s, e, e - s, len(r), sample))
    print()
    # ---- tables declared by op-0x02 records ---------------------------------
    tabs = {}
    for s, e in merged:
        for p, op, ln in records(s, e):
            if op == 0x02 and ln == 0x0F:
                o = p - A_BASE
                cnt = A[o + 6]
                src = int.from_bytes(A[o + 7:o + 11], "little")
                st = int.from_bytes(A[o + 11:o + 13], "little")
                if LO <= src < HI and cnt and st:
                    tabs.setdefault(src, set()).add((cnt, st))
    check("op-0x02 records naming a source inside the span", len(tabs), 34)
    print()
    print("TABLES the records declare -- base, count x stride, from the RECORD")
    for src in sorted(tabs):
        vs = sorted(tabs[src])
        print("  %06X  %s  max extent %d" % (src, ", ".join("%dx%d" % v for v in vs),
                                             max(c * s for c, s in vs)))
    print()
    # ---- what is left -------------------------------------------------------
    regions = sorted(merged)
    gaps, at = [], LO
    for s, e in regions:
        if s > at:
            gaps.append((at, s))
        at = max(at, e)
    if at < HI:
        gaps.append((at, HI))
    print("NOT display lists: %d gaps, %d bytes -- code, the ten `jp` tables at "
          "0xFA146F..0xFA1DE1, and the tables above" % (len(gaps),
                                                        sum(e - s for s, e in gaps)))
    for s, e in gaps:
        print("  %06X-%06X %5d" % (s, e, e - s))
    print()
    print("%d ok, FAILURES: %d" % (OK, FAIL))
    return 1 if FAIL else 0


def selftest():
    print("SELFTEST -- three negative controls, each MUST report FAIL")
    global OK, FAIL
    o, f = OK, FAIL
    check("control 1: the 0xFA1F21 list does NOT frame",
          records(0xFA1F21, 0xFA204B) is None, True)
    check("control 2: the idiom count is 367, not 368", len(idioms()), 367)
    check("control 3: 0xFA1404-0xFA146F IS a display list",
          records(0xFA1404, 0xFA146F) is not None, True)
    got = FAIL - f
    OK, FAIL = o, f
    print("  three controls fired: %d/3" % got)
    return got == 3


if __name__ == "__main__":
    sys.exit(0 if ("--selftest" in sys.argv and selftest()) else
             (1 if "--selftest" in sys.argv else main()))
