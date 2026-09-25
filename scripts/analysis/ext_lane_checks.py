#!/usr/bin/env python3
r"""ext_lane_checks.py -- the byte-level checks behind the headers in extensions/extension_data.s.

QUESTION ANSWERED
-----------------
Each header the `ext` lane (2026-09-25) wrote in
v10/v9/v7 maincpu/extensions/extension_data.s states a structural fact about
the ROM bytes.  This script re-derives every such fact from the dumps, so a
reader can check the header instead of trusting it.  Each check prints PASS or
FAIL and the numbers it saw; exit status is non-zero if any check fails.

  chord      the chord-type pointer table 0xECFF6A (64 x 4 B, read by
             MainChordPre via `lda xbc, (0xecff6a:24)`) -- every entry points
             at the first byte of a NUL-terminated string, the strings follow
             in reverse order of the entry index, and 0x00ED0008 (this file's
             first byte) is the high half of entry 39.
  sharp      "~9e" is the sharp glyph and "~a0" the flat glyph: the note-name
             table 0xED02A0 (12 entries, C..B) spells the five black keys with
             ~9e (C# D# F# G# A#); the split-point table 0xED1B40 spells them
             Db Eb F# Ab Bb -- ~a0 for the four flats, ~9e for F#.
  class      the 28 Toshi class records at 0xED27E4 (24 B each): +0x06 is
             0x0160 in all, +0x00 points into 0xF00000-0xFFFFFF, +0x0C/+0x10/
             +0x14 point into 0xED0000-0xEDFFFF, and the length of the +0x10
             signature string equals the number of names in the +0x14 table.
  objtabs    the three code-pointer object tables (ApFunction 0xED1C9E x42,
             Function 0xED2F66 x28, MainFunction 0xED3292 x20) are each
             followed by a NULL, and their parallel name tables by "".
  counts     the count words InitializeToshi reads with `ldw_da`: 0xED2D02 = 28,
             0xED2D92 = 8, 0xED2F64 = 26, and the tables they count end in NULL
             after exactly that many entries.
  widgets    the NAKA widget records 0xED37DA-0xED3C95 are elements 25-62 of
             the Toshi_Viewable_NORMAL table (slot 1, 0xED77CE), and in every
             one +4 is the parent element, +6 the first child, +8 the next
             sibling and +10 the previous sibling (element indices of the same
             table, 0xFFFF = none): each link is checked against the others;
             and +0x0E..+0x14 are a rectangle x1,y1,x2,y2 on the 320x240
             screen that lies inside the parent's rectangle.  The same links
             are checked for the five LABEL records 0xED669A-0xED67CB,
             elements 8-12 of Toshi_Viewable_TEST1 (slot 0xF4).

All checks run on v10 and on v7 (and v9, which is byte-identical in this range).

RUN
    python3 scripts/analysis/ext_lane_checks.py            # all checks, v10+v9+v7
    python3 scripts/analysis/ext_lane_checks.py chord class
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
B = 0xE00000
ROMS = {v: open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()
        for v in ("v10", "v9", "v7")}


class R:
    def __init__(self, v):
        self.v, self.b = v, ROMS[v]

    def u8(self, a):
        return self.b[a - B]

    def u16(self, a):
        return int.from_bytes(self.b[a - B:a - B + 2], "little")

    def u32(self, a):
        return int.from_bytes(self.b[a - B:a - B + 4], "little")

    def cs(self, a):
        e = self.b.index(b"\0", a - B)
        return self.b[a - B:e].decode("latin-1")


def chord(r):
    tab = [r.u32(0xECFF6A + 4 * k) for k in range(64)]
    ok = all(r.u8(p - 1) in (0x00, 0xFF) for p in tab)          # a string starts after a NUL/pad
    rev = all(tab[k] > tab[k + 1] for k in range(63))
    first = r.u32(0xED0006) == tab[39] and 0xED0006 == 0xECFF6A + 4 * 39
    ok = ok and rev and first and tab[63] == 0xED006A
    return ok, "64 entries, string starts: %s, strictly descending: %s, entry 39 at 0xED0006 = 0x%06X, entry 63 -> 0x%06X" % (
        ok, rev, tab[39], tab[63])


def sharp(r):
    notes = [r.cs(r.u32(0xED02A0 + 4 * k)) for k in range(12)]      # NoteNameStr_Table_0 = C..B
    split = [r.cs(r.u32(0xED1B40 + 4 * k)) for k in range(12)]      # ParamStr_Table_06 = C..B
    black = (1, 3, 6, 8, 10)
    # the split table uses the usual key spelling Db Eb F# Ab Bb: four flats and F-sharp
    ok = all("~9e" in notes[k] for k in black) and all("~a0" in split[k] for k in (1, 3, 8, 10)) and \
        "~9e" in split[6] and all("~" not in notes[k] and "~" not in split[k] for k in range(12) if k not in black)
    return ok, "note table %s | split table %s" % (notes, split)


def klass(r):
    bad = []
    for k in range(28):
        a = 0xED27E4 + 24 * k
        proc, w6, n, sig, vt = r.u32(a), r.u16(a + 6), r.u32(a + 12), r.u32(a + 16), r.u32(a + 20)
        names = []
        p = vt
        while r.cs(r.u32(p)) != "":
            names.append(r.cs(r.u32(p)))
            p += 4
        good = (0xF00000 <= proc <= 0xFFFFFF and w6 == 0x0160 and all(0xED0000 <= x <= 0xEDFFFF for x in (n, sig, vt))
                and len(r.cs(sig)) == len(names))
        if not good:
            bad.append(k)
    return not bad, "28 records, failing: %s, count word 0xED2D02 = %d" % (bad or "none", r.u16(0xED2D02))


def objtabs(r):
    msgs, ok = [], True
    for nm, tab, n, ntab in (("ApFunction", 0xED1C9E, 42, 0xED1D4A), ("Function", 0xED2F66, 28, 0xED2FDA),
                             ("MainFunction", 0xED3292, 20, 0xED32E6)):
        ptrs = [r.u32(tab + 4 * k) for k in range(n)]
        good = r.u32(tab + 4 * n) == 0 and all(0xF00000 <= p <= 0xFFFFFF for p in ptrs) and \
            r.cs(r.u32(ntab + 4 * n)) == "" and all(r.cs(r.u32(ntab + 4 * k)) for k in range(n))
        ok &= good
        msgs.append("%s %d+NULL %s" % (nm, n, "ok" if good else "BAD"))
    return ok, ", ".join(msgs)


def counts(r):
    ok = True
    msgs = []
    for cw, tab, want in ((0xED2D92, 0xED2D04, 8), (0xED2F64, 0xED2D94, 26)):
        n = r.u16(cw)
        good = n == want and r.u32(tab + 4 * n) == 0 and all(r.u32(tab + 4 * k) for k in range(n))
        ok &= good
        msgs.append("0x%06X=%d (table 0x%06X NULL after %d: %s)" % (cw, n, tab, n, good))
    n = r.u16(0xED2D02)
    ok &= n == 28
    msgs.append("0xED2D02=%d" % n)
    return ok, ", ".join(msgs)


def widgets(r):
    vt = 0xED77CE
    n = 63
    elems = [r.u32(vt + 4 * k) for k in range(n)]
    idx = {a: k for k, a in enumerate(elems)}
    lo, hi = 0xED37DA, 0xED3C96
    recs = sorted(a for a in elems if lo <= a < hi)
    ks = [idx[a] for a in recs]
    bad = []
    NONE = 0xFFFF
    for a in recs:
        k = idx[a]
        par, child, nxt, prv = (r.u16(a + o) for o in (4, 6, 8, 10))
        if nxt != NONE and r.u16(elems[nxt] + 10) != k:
            bad.append((k, "next.prev"))
        if prv != NONE and r.u16(elems[prv] + 8) != k:
            bad.append((k, "prev.next"))
        if child != NONE and r.u16(elems[child] + 4) != k:
            bad.append((k, "child.parent"))
        if par != NONE and not (0 <= par < n):
            bad.append((k, "parent range"))
        # +0x0E..+0x14 are a rectangle x1, y1, x2, y2 inside the parent's
        x1, y1, x2, y2 = (r.u16(a + o) for o in (14, 16, 18, 20))
        if not (x1 <= x2 < 320 and y1 <= y2 < 240):
            bad.append((k, "rect"))
        if par != NONE:
            px1, py1, px2, py2 = (r.u16(elems[par] + o) for o in (14, 16, 18, 20))
            if not (px1 <= x1 and x2 <= px2 and py1 <= y1 and y2 <= py2):
                bad.append((k, "rect outside parent"))
    ok = not bad and ks == list(range(25, 63))
    return ok, "%d records = elements %d..%d of slot 1, link inconsistencies: %s" % (
        len(recs), min(ks), max(ks), bad or "none")


def test1(r):
    vt = 0xED7C62                       # Toshi_Viewable_TEST1, slot 0xF4, 14 entries
    elems = [r.u32(vt + 4 * k) for k in range(14)]
    NONE = 0xFFFF
    bad = []
    for k in range(7, 13):
        a = elems[k]
        par, child, nxt, prv = (r.u16(a + o) for o in (4, 6, 8, 10))
        if nxt != NONE and r.u16(elems[nxt] + 10) != k:
            bad.append((k, "next.prev"))
        if prv != NONE and r.u16(elems[prv] + 8) != k:
            bad.append((k, "prev.next"))
        if child != NONE and r.u16(elems[child] + 4) != k:
            bad.append((k, "child.parent"))
    want = [0xED6676, 0xED669A, 0xED66C4, 0xED670A, 0xED6750, 0xED6790]
    ok = not bad and elems[7:13] == want and all(r.u8(a) == 0x2B for a in want[1:])
    return ok, "elements 7-12 at %s, link inconsistencies: %s" % (
        ",".join("0x%06X" % a for a in elems[7:13]), bad or "none")


CHECKS = {"test1": test1, "chord": chord, "sharp": sharp, "class": klass, "objtabs": objtabs, "counts": counts, "widgets": widgets}


def main():
    want = sys.argv[1:] or list(CHECKS)
    allok = True
    for name in want:
        for v in ("v10", "v9", "v7"):
            ok, msg = CHECKS[name](R(v))
            allok &= ok
            print("%-8s %-4s %s  %s" % (name, v, "PASS" if ok else "FAIL", msg))
    sys.exit(0 if allok else 1)


if __name__ == "__main__":
    main()
