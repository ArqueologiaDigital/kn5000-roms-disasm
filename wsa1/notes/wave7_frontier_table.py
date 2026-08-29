#!/usr/bin/env python3
"""The wave-7 frontier table: what is still .incbin, and what points into it.

QUESTION IT ANSWERS
    "Which .incbin spans remain in each image, how big is each one, which thunk
     runs point into it -- and what are the two numbers that measure MEANING
     rather than territory?"

WHY THIS EXISTS
    Every number in notes/WAVE7-BRIEFING.md's two span tables was first produced
    by an ad-hoc shell heredoc while the wave was being planned.  That is exactly
    the failure this tree keeps paying for: the README's status section was stale
    within one commit because it was maintained by hand, and the fix was to
    derive it from the sources instead.  A planning table deserves the same
    treatment as a findings table, so this script is the briefing's source.

    It also re-derives the sub_XXXXXX and Evidence: counts.  Coverage measures
    TERRITORY; sub_XXXXXX measures MEANING, and during wave 6 it went UP while
    coverage went up too -- newly converted code brings in unnamed routines
    faster than naming retires them.  Quote both or neither.

WHAT IT DOES NOT DO
    It does not certify anything.  scripts/analysis/assert_byte_identical.py is
    the only gate.  This is a planning instrument: it says where the work is, not
    whether the tree is correct.

RUN
    python3 notes/wave7_frontier_table.py            # both images, with thunk runs
    python3 notes/wave7_frontier_table.py --brief    # spans only, no subprocess
    python3 notes/wave7_frontier_table.py --sums     # spans ranked by SUMMED thunk
                                                     # extent, which is NOT the same
                                                     # ranking as by span size
    python3 notes/wave7_frontier_table.py --selftest # 16 checks, incl. the LAST
                                                     # span of each image
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (source dir, .s basename, incbin filename, load base, frontier tool)
IMAGES = [
    ("prom_a", "wsa1_prom_a.s", "wsa1_prom_a.ic12", 0xF80000, "prom_a_module_frontier.py"),
    ("prom_b", "wsa1_prom_b.s", "wsa1_prom_b.ic13", 0xF00000, "prom_b_module_frontier.py"),
    ("prom_c", "wsa1_prom_c.s", "wsa1_prom_c.ic28", 0xF80000, None),
    ("prom_d", "wsa1_prom_d.s", "wsa1_prom_d.bin",  0x000000, None),
]
IMAGE_SIZE = 512 * 1024


def spans(image):
    """[(file_offset, length)] for every .incbin still in this image's source,
    in the order they appear -- which is also address order, and the selftest
    checks that it is."""
    d, s, inc, _base, _f = image
    text = open(os.path.join(ROOT, d, s)).read()
    rx = re.compile(r'^\t\.incbin "original_ROMs/%s", (0x[0-9A-Fa-f]+), (0x[0-9A-Fa-f]+)\s*$'
                    % re.escape(inc), re.M)
    return [(int(a, 16), int(b, 16)) for a, b in rx.findall(text)]


def thunk_runs(tool):
    """[(run, slots, unconverted, extent, refs, lo, hi)] parsed from the frontier
    tool's own output, so this script and it can never disagree."""
    if tool is None:
        return []
    r = subprocess.run([sys.executable, os.path.join(ROOT, "notes", tool)],
                       capture_output=True, text=True, cwd=ROOT)
    out = []
    rx = re.compile(r'^\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+'
                    r'0x([0-9A-Fa-f]+)-0x([0-9A-Fa-f]+)\s*$')
    for line in r.stdout.splitlines():
        m = rx.match(line)
        if m:
            out.append((m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(4)),
                        int(m.group(7)), int(m.group(8), 16), int(m.group(9), 16)))
    return out


def meaning_counts():
    """The two numbers that measure meaning rather than territory."""
    subs, ev = set(), 0
    rx_sub = re.compile(r'^(sub_[0-9A-Fa-f]{6}):', re.M)
    for d, s, _i, _b, _f in IMAGES:
        text = open(os.path.join(ROOT, d, s)).read()
        subs.update(rx_sub.findall(text))
        ev += text.count("Evidence:")
    return len(subs), ev


def summed(base_only=None):
    """Rank spans by the SUM of the contiguous unconverted extents of the thunk runs
    that point into them.

    QUESTION: "is the biggest .incbin also the one the most call-target weight
    points into?"  It is NOT, and that matters: prom_a's largest remaining span
    (0xFAD800, 18,432 B) sums to 5,811, while 0xFA5AEB (17,685 B) sums to 16,799
    -- T_F43350 alone is 8,886.  A wave-7 lane's docstring claimed the frontier
    ranked 0xFAD800 top; it does not, and this mode is why that is now checkable
    instead of arguable.  Both are legitimate reasons to pick a span; they are
    different reasons and should not be confused for each other."""
    for image in IMAGES:
        d, _s, _i, base, tool = image
        if tool is None:
            continue
        if base_only and d != base_only:
            continue
        sp = spans(image)
        runs = thunk_runs(tool)
        rows = []
        for off, ln in sp:
            lo, hi = base + off, base + off + ln
            inside = [r for r in runs if r[5] >= lo and r[6] < hi]
            rows.append((sum(r[3] for r in inside), ln, lo, hi, len(inside)))
        rows.sort(reverse=True)
        print("=== %s: spans by SUMMED thunk extent (not by size) ===" % d)
        for tot, ln, lo, hi, n in rows[:8]:
            print("    0x%06X-0x%06X  summed extent %7s   span %8s bytes   %d runs"
                  % (lo, hi, format(tot, ","), format(ln, ","), n))
        print()


def report(brief=False):
    for image in IMAGES:
        d, _s, _i, base, tool = image
        sp = spans(image)
        total = sum(l for _o, l in sp)
        print("=== %s: %d .incbin span%s, %s bytes still unconverted ==="
              % (d, len(sp), "" if len(sp) == 1 else "s", format(total, ",")))
        if not sp:
            print("    territorially complete -- remaining work is MEANING, not territory\n")
            continue
        runs = [] if brief else thunk_runs(tool)
        for off, ln in sorted(sp, key=lambda t: -t[1]):
            lo, hi = base + off, base + off + ln
            print("    0x%06X-0x%06X  file 0x%05X  %9s bytes" % (lo, hi, off, format(ln, ",")))
            for name, slots, unc, extent, refs, tlo, thi in runs:
                if tlo >= lo and thi < hi:
                    print("        <- %-20s %3d slots, %3d unconverted, extent %6d, %4d refs"
                          % (name, slots, unc, extent, refs))
        print()
    nsub, nev = meaning_counts()
    print("MEANING (not territory):  %s routines still named only sub_XXXXXX" % format(nsub, ","))
    print("                          %s Evidence: lines in routine headers" % format(nev, ","))
    print("Territory is scripts/analysis/source_coverage.py; the GATE is")
    print("scripts/analysis/assert_byte_identical.py and nothing else.")


def selftest():
    """Checks the LAST span of each image as well as the first -- a table that is
    right at the top and wrong at the bottom is this project's signature failure."""
    ok = fail = 0

    def check(desc, cond):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc)
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    for image in IMAGES:
        d, s, inc, base, _t = image
        sp = spans(image)
        text = open(os.path.join(ROOT, d, s)).read()
        if not sp:
            check("%s: no .incbin remains, and none in the text either" % d,
                  ('.incbin "original_ROMs/%s"' % inc) not in text)
            continue
        offs = [o for o, _l in sp]
        check("%s: spans appear in strictly increasing file order" % d,
              offs == sorted(offs) and len(set(offs)) == len(offs))
        check("%s: no two spans overlap" % d,
              all(sp[i][0] + sp[i][1] <= sp[i + 1][0] for i in range(len(sp) - 1)))
        # FIRST span
        fo, fl = sp[0]
        check("%s: FIRST span 0x%05X+0x%05X is a literal line in the source" % (d, fo, fl),
              '\t.incbin "original_ROMs/%s", 0x%06X, 0x%06X' % (inc, fo, fl) in text)
        # LAST span -- the half a hand-written table gets wrong
        lo_, ll = sp[-1]
        check("%s: LAST span 0x%05X+0x%05X is a literal line in the source" % (d, lo_, ll),
              '\t.incbin "original_ROMs/%s", 0x%06X, 0x%06X' % (inc, lo_, ll) in text)
        check("%s: LAST span ends at or before the 512 KiB image end (0x%05X <= 0x%X)"
              % (d, lo_ + ll, IMAGE_SIZE), lo_ + ll <= IMAGE_SIZE)
        check("%s: LAST span maps to CPU address 0x%06X, inside the image window"
              % (d, base + lo_), base + lo_ + ll <= base + IMAGE_SIZE)

    nsub, nev = meaning_counts()
    check("sub_XXXXXX count is a positive number (%s)" % format(nsub, ","), nsub > 0)
    check("Evidence: count is a positive number (%s)" % format(nev, ","), nev > 0)
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    if "--sums" in sys.argv:
        summed()
        sys.exit(0)
    report(brief="--brief" in sys.argv)
