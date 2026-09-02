#!/usr/bin/env python3
"""data_directive_bytes.py -- how many ROM bytes does a maincpu source tree emit
through DATA directives rather than instructions, at any git revision?

THE QUESTION THIS ANSWERS
-------------------------
A conversion lane needs a before/after that does not depend on the tool that did
the converting.  `data_range_census.py`'s `embedded-in-code` column is a property
of a region's NEIGHBOURHOOD -- data with an instruction region on each side -- so
it moves for reasons other than conversion: removing an island merges two code
regions, and each new code/data boundary can create a new, smaller flagged
region.  It is the right instrument for "what is still unexplained" and the
wrong one for "how many bytes did this lane convert".

This counts the thing that actually moved: bytes emitted by `.byte`, `.hword`,
`.word`, `.dword`, `.ascii`, `.asciz` and `.incbin` in `<image>/maincpu/**.s`.
Fill directives are excluded -- padding is not debt of this kind -- and so are
lines inside `.macro` bodies, which are emitted per expansion, not once.

⚠ It reads the source TEXT, at any revision, via `git show`.  That is what makes
a before/after possible without rebuilding an old tree; it also means `.incbin`
sizes come from the CURRENT working tree, which is correct here only because no
`.incbin` target changed between the revisions being compared.  It prints the
incbin total separately so that assumption is visible rather than buried.

RUN
    python3 scripts/analysis/data_directive_bytes.py                  # HEAD
    python3 scripts/analysis/data_directive_bytes.py --rev <commit>
    python3 scripts/analysis/data_directive_bytes.py --diff <base>    # base vs HEAD
    python3 scripts/analysis/data_directive_bytes.py --selftest
"""
import argparse
import os
import re
import subprocess
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
IMAGES = ("v10", "v9", "v7")
WIDTH = {"byte": 1, "hword": 2, "word": 4, "dword": 8}
ESCAPE = re.compile(r'\\(?:[0-7]{1,3}|x[0-9a-fA-F]{1,2}|.)')
INCBIN = re.compile(r'\.incbin\s+"([^"]+)"(?:\s*,\s*([0-9a-fA-Fx]+)\s*(?:,\s*([0-9a-fA-Fx]+))?)?')


def ascii_len(operand):
    return sum(len(ESCAPE.sub("X", m.group(1)))
               for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', operand))


def files_at(rev, image):
    out = subprocess.run(["git", "ls-tree", "-r", "--name-only", rev,
                          "%s/maincpu" % image], cwd=ROOT,
                         capture_output=True, text=True, check=True).stdout
    return [p for p in out.split("\n") if p.endswith(".s")]


def text_at(rev, path):
    return subprocess.run(["git", "show", "%s:%s" % (rev, path)], cwd=ROOT,
                          capture_output=True, check=True).stdout.decode("latin-1")


def count(text):
    """-> (directive bytes, incbin bytes)."""
    data = inc = 0
    in_macro = False
    for line in text.split("\n"):
        s = line.strip()
        if s.startswith(".macro"):
            in_macro = True
            continue
        if s.startswith(".endm"):
            in_macro = False
            continue
        if in_macro or not s or s.startswith(";"):
            continue
        s = re.sub(r'^[A-Za-z_.$][\w.$]*:\s*', '', s)     # label on the same line
        m = INCBIN.search(s)
        if m:
            p = os.path.join(ROOT, m.group(1))
            if m.group(3):
                inc += int(m.group(3), 0)
            elif os.path.exists(p):
                inc += os.path.getsize(p) - (int(m.group(2), 0) if m.group(2) else 0)
            continue
        m = re.match(r'\.(\w+)\s+(.*)$', s)
        if not m:
            continue
        d, rest = m.group(1), m.group(2).split(";")[0]
        if d in WIDTH:
            data += WIDTH[d] * len([x for x in rest.split(",") if x.strip()])
        elif d in ("ascii", "asciz", "string"):
            data += ascii_len(rest) + (0 if d == "ascii" else 1)
    return data, inc


def totals(rev):
    out = {}
    for img in IMAGES:
        d = i = 0
        for p in files_at(rev, img):
            a, b = count(text_at(rev, p))
            d += a
            i += b
        out[img] = (d, i)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rev", default="HEAD")
    ap.add_argument("--diff", default="")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    if a.diff:
        b, h = totals(a.diff), totals(a.rev)
        print("%-6s %12s %12s %12s   (%s vs %s)"
              % ("image", "before", "after", "delta", a.diff[:9], a.rev[:9]))
        tb = th = 0
        for img in IMAGES:
            print("%-6s %12d %12d %+12d" % (img, b[img][0], h[img][0],
                                            h[img][0] - b[img][0]))
            tb += b[img][0]
            th += h[img][0]
        print("%-6s %12d %12d %+12d" % ("TOTAL", tb, th, th - tb))
        ib = sum(x[1] for x in b.values())
        ih = sum(x[1] for x in h.values())
        print("\n.incbin bytes, reported separately because their sizes are read "
              "from the CURRENT tree: %d -> %d (%+d)" % (ib, ih, ih - ib))
        return 0
    t = totals(a.rev)
    for img in IMAGES:
        print("%-6s directive bytes %10d   incbin %10d" % (img, t[img][0], t[img][1]))
    return 0


def selftest():
    f = 0

    def ck(d, c, extra=""):
        nonlocal f
        print(("  ok   " if c else "  FAIL ") + d + (("   " + extra) if extra else ""))
        f += not c

    ck(".byte counts its operands", count("\t.byte 1, 2, 3\n")[0] == 3)
    ck(".word is four bytes each", count("\t.word 1, 2\n")[0] == 8)
    ck(".asciz counts the terminator", count('\t.asciz "ab"\n')[0] == 3)
    ck("an escape is one byte", count('\t.ascii "a\\x41b"\n')[0] == 3)
    ck("a label on the directive's own line is not lost",
       count("Foo:\t.byte 1, 2\n")[0] == 2)
    ck("a .macro body is not counted",
       count(".macro m\n\t.byte 1\n.endm\n\t.byte 2\n")[0] == 1)
    ck("a comment line is not counted", count("; .byte 1, 2, 3\n")[0] == 0)
    print("\n%s (%d failures)" % ("PASS" if not f else "FAIL", f))
    return 1 if f else 0


if __name__ == "__main__":
    sys.exit(main())
