#!/usr/bin/env python3
"""Tile a prom_b display-list MODULE into records and operand tables, from anchors.

QUESTION IT ANSWERS
    Round 9 closed 0xF2BE35-0xF317FF by hand.  The same shape of region occurs
    several more times, and `notes/prom_b_dl_call_shapes.py --new` lists 6,879
    bytes of them.  This is the method, written down once:

      ANCHORS   every (start,end) a call site of ANY of the three code shapes
                gives, plus the module's own two ends.
      RECORDS   an interval between consecutive anchors is a record run if the
                display-list framing walk from its start lands EXACTLY on its end.
      TABLES    an interval that is not a record run is tiled by the objects that
                display-list records POINT AT.  A pointer's width comes from the
                record that carries it -- the `+0x0B` word for interpreter B's
                two string-table handlers, the fixed stride 8 or 6 for its two
                array handlers, and `HL` (bytes per column) for interpreter A's
                opcode 03/04, whose service is LCD_Svc_03_BlitColumns.
                An interval TILES when each object's start is a pointer target,
                each object's length is a whole number of its own width, and the
                last one ends exactly on the next anchor.

    ⚠ THE MASK IS NOT A COUNT.  A record's `+4` AND mask bounds the INDEX, not
    the array: masks of 0xFF are everywhere and no array here has 256 entries.
    The count comes from the EXTENT, and the mask is only ever a corroboration
    when the two agree.  A solver that trusted the mask produced a 1,536-byte
    "table" where the anchors say 304.

    ⚠ AND THE TILING IS NOT UNIQUE WITHOUT ANCHORS.  Counted by this script's
    own `--count`: an unanchored 4,004-byte module admits 25,692,504 tilings
    under the record/table constraints alone.  That is why this tool refuses to
    emit anything for an interval that no anchor bounds.

RUN
    python3 notes/prom_b_anchored_tiler.py 0xF0C800 0xF0D061     # a module
    python3 notes/prom_b_anchored_tiler.py 0xF0C800 0xF0D061 --count
    python3 notes/prom_b_anchored_tiler.py --selftest
Exit status is non-zero if a self-check fails, or if a module does not tile.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL                                 # noqa: E402
import prom_b_dl_length_audit as LA                               # noqa: E402
import prom_b_dl_call_shapes as CS                                # noqa: E402

B_BASE = 0xF00000
# interpreter-B handler -> (offset of the 32-bit pointer, offset of the width word
#                           or None when the handler's stride is fixed)
BPTR = {0xF31B21: (7, 11), 0xF31B39: (7, 11), 0xF31B57: (7, None), 0xF31B86: (7, None)}
BSTRIDE = {0xF31B57: 8, 0xF31B86: 6}
FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-58s %-24s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


class Module(object):
    def __init__(self, lo, hi):
        self.a, self.b = DL.load()
        self.ta, self.tb = LA.tables(self.b)
        self.lo, self.hi = lo, hi
        self.site_interp = {}
        self.anchors = self._anchors()
        self.tables = self._pointer_targets()

    # ---------------------------------------------------------------- anchors
    def _anchors(self):
        """Anchor addresses, and -- for the (start,end) a site actually names --
        which interpreter that site's thunk runs."""
        out = {self.lo, self.hi}
        for shape, _site, s, e, t in CS.scan(self.a, self.b):
            if shape == 3:
                if self.lo <= s < self.hi:
                    end = s + self.b[s - B_BASE + 1]
                    out.add(s)
                    out.add(end)
                    self.site_interp[(s, end)] = "B"        # DisplayListB_RunOne_Stack
                continue
            if self.lo <= s < self.hi:
                out.add(s)
            if e is not None and self.lo < e <= self.hi:
                out.add(e)
            if e is not None and self.lo <= s and e <= self.hi:
                self.site_interp[(s, e)] = "B" if t in (CS.RUN_B, CS.STACK_B) else "A"
        return sorted(x for x in out if self.lo <= x <= self.hi)

    # ------------------------------------------------------- pointer targets
    def _ptrs_of(self, p):
        b, out = self.b, []
        op, ln = b[p - B_BASE], b[p - B_BASE + 1]
        if op >= 0x24 or ln < 2 or p + ln > self.hi:
            return out
        r = b[p - B_BASE:p - B_BASE + ln]
        if op < 0x0F:
            h = self.tb[op]
            if h in BPTR:
                kind, need = LA.IMPLIED_B[h]
                if (ln == need) if kind == "fixed" else (ln >= need):
                    po, wo = BPTR[h]
                    ptr = int.from_bytes(r[po:po + 4], "little")
                    w = int.from_bytes(r[wo:wo + 2], "little") if wo else BSTRIDE[h]
                    if self.lo <= ptr < self.hi and 0 < w <= 64:
                        out.append((ptr, w, p, "record +0x%02X, width %s" %
                                    (po, "+0x%02X" % wo if wo else "fixed %d" % w)))
        h = self.ta[op]
        if h == 0xF31ABE and ln >= 12:
            ptr = int.from_bytes(r[2:6], "little")
            bc = int.from_bytes(r[8:10], "little")
            hl = int.from_bytes(r[10:12], "little")
            if self.lo <= ptr < self.hi and bc and hl:
                out.append((ptr, hl, p, "A op %02X blit, BC=%d columns of HL=%d" % (op, bc, hl)))
        return out

    def _pointer_targets(self):
        t = {}
        for p in range(self.lo, self.hi - 2):
            for ptr, w, src, why in self._ptrs_of(p):
                t.setdefault(ptr, []).append((w, src, why))
        return t

    # ------------------------------------------------------------- the walk
    def records(self, s, e):
        b, out, p = self.b, [], s
        while p < e:
            op, ln = b[p - B_BASE], b[p - B_BASE + 1]
            if op >= 0x24 or ln < 2 or p + ln > e:
                return None
            out.append((p, op, ln))
            p += ln
        return out if p == e else None

    def interp(self, recs):
        def fits(table, implied, bound):
            for _p, op, ln in recs:
                if op >= bound:
                    return False
                kind, n = implied[table[op]]
                if (ln != n) if kind == "fixed" else (ln < n):
                    return False
            return True
        a = fits(self.ta, LA.IMPLIED_A, 0x24)
        bb = fits(self.tb, LA.IMPLIED_B, 0x0F)
        return "A" if a and not bb else "B" if bb and not a else "AMBIG" if a else "NEITHER"

    # ------------------------------------------------------------ the tiling
    def tile(self):
        objs = []
        for i in range(len(self.anchors) - 1):
            s, e = self.anchors[i], self.anchors[i + 1]
            r = self.records(s, e)
            if r is not None:
                which = self.interp(r)
                site = self.site_interp.get((s, e))
                if site and which in ("AMBIG", site):
                    which = site                    # the call site's own thunk wins
                objs.append((s, e, "list", (which, r)))
                continue
            objs += self._tile_data(s, e)
        return objs

    def _tile_data(self, s, e):
        """Objects that tile [s,e) exactly, or one UNTILED object."""
        out, p = [], s
        while p < e:
            if p not in self.tables:
                return [(s, e, "UNTILED", "0x%06X is not a pointer target" % p)]
            nxt = min([t for t in self.tables if p < t < e] + [e])
            width = None
            for w, src, why in self.tables[p]:
                if (nxt - p) % w == 0:
                    width = (w, src, why)
                    break
            if width is None:
                return [(s, e, "UNTILED",
                         "0x%06X: no width divides %d" % (p, nxt - p))]
            out.append((p, nxt, "table", width))
            p = nxt
        return out

    # ------------------------------------------------- how ambiguous it is
    def count_tilings(self):
        from functools import lru_cache
        b, lo, hi, T = self.b, self.lo, self.hi, self.tables

        def runend(p):
            q = p
            while q < hi:
                op, ln = b[q - B_BASE], b[q - B_BASE + 1]
                if op >= 0x24 or ln < 2 or q + ln > hi:
                    break
                if q > p and q in T:
                    break
                q += ln
            return q

        @lru_cache(maxsize=None)
        def f(p):
            if p == hi:
                return 1
            n = 0
            if p in T:
                for w in sorted({x[0] for x in T[p]}):
                    m = 1
                    while p + m * w <= hi:
                        e = p + m * w
                        if e == hi or e in T or (b[e - B_BASE] < 0x24 and b[e - B_BASE + 1] >= 2):
                            n += f(e)
                        m += 1
            q = runend(p)
            if q > p:
                n += f(q)
            return n
        return f(lo)


def show(lo, hi):
    m = Module(lo, hi)
    objs = m.tile()
    print("module 0x%06X-0x%06X, %d bytes, %d anchors"
          % (lo, hi - 1, hi - lo, len(m.anchors)))
    bad = 0
    for s, e, kind, det in objs:
        if kind == "list":
            extra = "interpreter %s, %d records" % (det[0], len(det[1]))
        elif kind == "table":
            w, src, why = det
            extra = "%d entries of %d bytes -- %s at 0x%06X" % ((e - s) // w, w, why, src)
        else:
            extra = "UNTILED -- %s" % det
            bad += 1
        print("  %06X-%06X %6d  %-8s %s" % (s, e - 1, e - s, kind, extra))
    cov = sum(e - s for s, e, _k, _d in objs)
    print("  %d objects, %d bytes, %d untiled" % (len(objs), cov, bad))
    return 0 if (bad == 0 and cov == hi - lo) else 1


def main():
    if "--selftest" in sys.argv:
        print("prom_b_anchored_tiler.py --selftest")
        # the module round 9 converted, re-derived by the generic tiler
        m = Module(0xF0C800, 0xF0D061)
        objs = m.tile()
        check("0xF0C800-0xF0D060 tiles with nothing untiled",
              [o for o in objs if o[2] == "UNTILED"], [])
        check("  it covers every byte", sum(e - s for s, e, _k, _d in objs), 0xF0D061 - 0xF0C800)
        check("  objects", len(objs), 49)
        check("  exactly ONE list is left ambiguous, and it is 0xF0D023",
              [hex(o[0]) for o in objs if o[2] == "list" and o[3][0] not in ("A", "B")],
              ["0xf0d023"])
        check("    -- no site names it, and its single op-00 10-byte record is the "
              "implied length of BOTH interpreters",
              (m.b[0xF0D023 - B_BASE], m.b[0xF0D023 - B_BASE + 1],
               LA.IMPLIED_A[m.ta[0]], LA.IMPLIED_B[m.tb[0]]),
              (0x00, 0x0A, ("fixed", 10), ("fixed", 10)))
        tabs = [(hex(s), (e - s) // d[0]) for s, e, k, d in objs if k == "table"]
        check("  the tables and their entry counts", tabs,
              [("0xf0ca9f", 3), ("0xf0cab1", 2), ("0xf0cabd", 32), ("0xf0cb7d", 2),
               ("0xf0cb83", 3), ("0xf0cb95", 2), ("0xf0cb9f", 6), ("0xf0ccc5", 3),
               ("0xf0ccce", 2), ("0xf0ccde", 2), ("0xf0ce75", 2), ("0xf0ce7b", 8)])
        check("  LAST object is a record run ending on the module end",
              (hex(objs[-1][0]), hex(objs[-1][1]), objs[-1][2], objs[-1][3][0]),
              ("0xf0d04b", "0xf0d061", "list", "B"))
        # the service screens round 9 converted by hand
        m2 = Module(0xF2C800, 0xF2CB59)
        objs2 = m2.tile()
        check("0xF2C800-0xF2CB58 tiles too",
              [o for o in objs2 if o[2] == "UNTILED"], [])
        check("  and finds the 5x30 bitmap at 0xF2CAC3",
              [(hex(s), e - s) for s, e, k, d in objs2
               if k == "table" and s == 0xF2CAC3], [("0xf2cac3", 150)])
        # the negative control: without anchors the tiling is not unique
        n = Module(0xF0C800, 0xF0D79C).count_tilings()
        check("an UNANCHORED 4,004-byte module admits many tilings", n > 1000000, True)
        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0
    args = [x for x in sys.argv[1:] if not x.startswith("--")]
    if len(args) != 2:
        print(__doc__)
        return 2
    lo, hi = int(args[0], 0), int(args[1], 0)
    if "--count" in sys.argv:
        print("tilings without anchors: %d" % Module(lo, hi).count_tilings())
        return 0
    return show(lo, hi)


if __name__ == "__main__":
    sys.exit(main())
