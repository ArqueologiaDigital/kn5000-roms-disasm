#!/usr/bin/env python3
"""How many display lists does the committed scanner NOT see, and where are they?

QUESTION IT ANSWERS
    `scripts/analysis/prom_b_display_lists.py` finds a display list only where a
    caller spells both ends as immediates:

        SHAPE 1   ld XIY,imm32 / ld XIX,imm32 / call {0xF417F0, 0xF417F4}
                  45 s0 s1 s2 00   44 e0 e1 e2 00   1d t0 t1 t2

    Round 8 found the message module (0xF2D800-0xF317FF) by a pair TABLE, and
    the service-mode screens (0xF2C800-0xF2CB58) by a THIRD shape the scanner
    also does not look for.  This enumerates every shape found so far and says
    how many bytes that are still `.incbin` each one names:

        SHAPE 2   lda XBC,<end> / push XBC / lda XWA,<start> / push XWA
                  / call {0xF42E00, 0xF42E04}                  -- the stack forms
                  f2 e0 e1 e2 31   39   f2 s0 s1 s2 30   38   1d t0 t1 t2
        SHAPE 3   lda XBC,<record> / push XBC / call 0xF42E0C
                  f2 p0 p1 p2 31   39   1d 0c 2e f4
                  T_F42E0C is DisplayListB_RunOne_Stack -- ONE interpreter-B
                  record, no end pointer, so no framing walk reaches it.
        SHAPE 4   a table of 8-byte (start,end) entries somewhere in prom_a,
                  indexed by a message id and a language.  See
                  notes/prom_b_message_module.py.

WHAT IS EXACT AND WHAT IS NOT
    EXACT: the byte patterns, and the framing verdict on every (start,end) they
    yield -- a pair is reported as FRAMES only if the display-list walk from the
    start lands exactly on the end.
    NOT EXACT: this is a byte-level scan, so a shape can match inside data.
    That is why the framing verdict is printed per site and why the byte totals
    below count only sites that frame.  Shape 3 has no end pointer and therefore
    no framing check at all; its records are reported with the interpreter-B
    implied length of their opcode, and a site whose opcode/length disagrees with
    that is printed as SUSPECT rather than counted.

RUN
    python3 notes/prom_b_dl_call_shapes.py               # the summary
    python3 notes/prom_b_dl_call_shapes.py --new         # only what is still .incbin
    python3 notes/prom_b_dl_call_shapes.py --sites       # every site
    python3 notes/prom_b_dl_call_shapes.py --selftest
Exit status is non-zero if a self-check fails.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL                                 # noqa: E402
import prom_b_dl_length_audit as LA                               # noqa: E402

B_BASE, A_BASE = 0xF00000, 0xF80000
RUN_A, RUN_B = 0xF417F0, 0xF417F4
STACK_A, STACK_B, RUN_ONE_B = 0xF42E00, 0xF42E04, 0xF42E0C
FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-58s %-22s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def le(d, o, n=3):
    return int.from_bytes(d[o:o + n], "little")


def incbin_spans():
    out = []
    for line in open(os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")):
        m = re.search(r'\.incbin\s+"[^"]+"\s*,\s*(0x[0-9a-fA-F]+)\s*,\s*(0x[0-9a-fA-F]+)', line)
        if m:
            s = B_BASE + int(m.group(1), 0)
            out.append((s, s + int(m.group(2), 0)))
    return out


def scan(a, b):
    """[(shape, site, start, end_or_None, target)] over prom_a and prom_b."""
    out = []
    for base, d in ((A_BASE, a), (B_BASE, b)):
        n = len(d)
        for o in range(n - 16):
            if d[o] == 0x45 and d[o + 4] == 0x00 and d[o + 5] == 0x44 \
                    and d[o + 9] == 0x00 and d[o + 10] == 0x1D \
                    and le(d, o + 11) in (RUN_A, RUN_B):
                out.append((1, base + o, le(d, o + 1), le(d, o + 6), le(d, o + 11)))
                continue
            if d[o] != 0xF2 or d[o + 4] != 0x31 or d[o + 5] != 0x39:
                continue
            if d[o + 6] == 0xF2 and d[o + 10] == 0x30 and d[o + 11] == 0x38 \
                    and d[o + 12] == 0x1D and le(d, o + 13) in (STACK_A, STACK_B):
                out.append((2, base + o, le(d, o + 7), le(d, o + 1), le(d, o + 13)))
            elif d[o + 6] == 0x1D and le(d, o + 7) == RUN_ONE_B:
                out.append((3, base + o, le(d, o + 1), None, RUN_ONE_B))
    return out


def main():
    a, b = DL.load()
    _ta, tb = LA.tables(b)
    sites = scan(a, b)
    spans = incbin_spans()

    def unconverted(x):
        return any(s <= x < e for s, e in spans)

    def frames(s, e):
        """The walk, against whichever image the addresses live in."""
        for img, base in ((b, B_BASE), (a, A_BASE)):
            if base <= s < e <= base + len(img):
                p, n = s, 0
                while p < e:
                    op, ln = img[p - base], img[p - base + 1]
                    if op >= 0x24 or ln < 2 or p + ln > e:
                        return False
                    p += ln
                    n += 1
                return p == e and n > 0
        return False

    rows, cov = [], {1: set(), 2: set(), 3: set()}
    for shape, site, s, e, t in sites:
        if shape == 3:
            if not (B_BASE <= s < B_BASE + len(b) - 2):
                verdict = "OUT OF RANGE"
            else:
                op, ln = b[s - B_BASE], b[s - B_BASE + 1]
                if op < 0x0F:
                    kind, want = LA.IMPLIED_B[tb[op]]
                    good = ln >= want if kind == "min" else ln == want
                    verdict = "1 record, %d bytes" % ln if good else "SUSPECT"
                else:
                    verdict = "SUSPECT"
                if verdict != "SUSPECT" and unconverted(s):
                    cov[3].update(range(s, s + ln))
            e_show = s + (b[s - B_BASE + 1] if B_BASE <= s < B_BASE + len(b) else 0)
        else:
            verdict = "frames" if frames(s, e) else "DOES NOT FRAME"
            if verdict == "frames" and unconverted(s):
                cov[shape].update(range(s, e))
            e_show = e
        rows.append((shape, site, s, e_show, t, verdict, unconverted(s)))

    if "--selftest" in sys.argv:
        print("prom_b_dl_call_shapes.py --selftest")
        # shape 1 must reproduce the committed scanner exactly
        mine = {(s, e, t) for sh, _o, s, e, t in rows and
                [(r[0], r[1], r[2], r[3], r[4]) for r in rows] if sh == 1}
        theirs = DL.call_sites(a, b)
        check("shape 1 reproduces the committed scanner", mine == theirs, True)
        # the three shape-2 sites the service module rests on
        for want in (0xF9574E, 0xF9577B, 0xF95808):
            check("shape 2 site prom_a 0x%06X found" % want,
                  any(sh == 2 and o == want for sh, o, *_ in rows), True)
        for want in (0xF9585C, 0xF95866, 0xF95870, 0xF9587A):
            check("shape 3 site prom_a 0x%06X found" % want,
                  any(sh == 3 and o == want for sh, o, *_ in rows), True)
        # the LAST site of each shape is exercised, not just the first
        for sh in (1, 2, 3):
            last = max((r for r in rows if r[0] == sh), key=lambda r: r[1])
            check("LAST shape-%d site 0x%06X decodes" % (sh, last[1]),
                  last[5] not in ("OUT OF RANGE",), True)
        na = sum(1 for sh, _o, s, _e, _t, v, _u in rows
                 if sh == 2 and A_BASE <= s and v == "frames")
        check("shape 2 also names display lists in PROM_A (that lane's file)", na, 48)
        check("  the lowest and highest of them",
              (min(hex(s) for sh, _o, s, _e, _t, v, _u in rows
                   if sh == 2 and A_BASE <= s and v == "frames"),
               max(hex(s) for sh, _o, s, _e, _t, v, _u in rows
                   if sh == 2 and A_BASE <= s and v == "frames")),
              ("0xfa1f21", "0xfa4d9a"))
        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    if "--sites" in sys.argv:
        for sh, site, s, e, t, v, unc in sorted(rows):
            print("  shape %d  site %06X  %06X-%06X  -> %06X  %-14s %s"
                  % (sh, site, s, e, t, v, "STILL .incbin" if unc else ""))
        return 0

    if "--new" in sys.argv:
        allcov = cov[2] | cov[3]
        runs = []
        for x in sorted(allcov):
            if runs and x == runs[-1][1] + 1:
                runs[-1][1] = x
            else:
                runs.append([x, x])
        print("bytes still `.incbin` that shapes 2 and 3 NAME: %d in %d runs"
              % (len(allcov), len(runs)))
        for s, e in runs:
            print("  %06X-%06X %6d" % (s, e, e - s + 1))
        return 0

    for sh in (1, 2, 3):
        n = sum(1 for r in rows if r[0] == sh)
        good = sum(1 for r in rows if r[0] == sh and r[5] not in ("DOES NOT FRAME", "SUSPECT", "OUT OF RANGE"))
        print("shape %d: %4d sites, %4d usable, %6d bytes still `.incbin`"
              % (sh, n, good, len(cov[sh])))
    print("shapes 2+3 name %d bytes that are still `.incbin` "
          "(shape 1's are already converted)" % len(cov[2] | cov[3]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
