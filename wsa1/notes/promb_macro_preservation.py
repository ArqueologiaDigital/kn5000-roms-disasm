#!/usr/bin/env python3
"""Did the macro rewrite of prom_b LOSE ANYTHING? Line by line, against git.

QUESTION IT ANSWERS
    "notes/promb_macro_rewrite.py replaces thousands of `.byte` rows with macro
     calls.  The byte gate proves the ROM is unchanged.  It is blind to prose.
     Is every comment, every documentation header, every label and every
     `; ADDR <disassembler text>` decode still there, verbatim?"

    The tree's own list of gate-clean errors is why this exists: a confidently
    wrong header passes the byte gate forever, and so does a deleted one.

WHAT IT ALLOWS, AND IT IS EXACTLY ONE THING
    A row that stops being a `.byte` may drop its trailing
    `   [llvm-mc cannot encode this]` marker, because the marker explains why the
    row is a `.byte`.  Everything else must be identical: the line count, every
    label, every comment-only line, and every address and decode text.
    The count of dropped markers must equal the count of rewritten rows, so a
    marker cannot go missing from a row that was not rewritten.

RUN
    python3 notes/promb_macro_preservation.py            # working tree vs HEAD
    python3 notes/promb_macro_preservation.py <rev>      # ... vs another revision
    python3 notes/promb_macro_preservation.py --selftest
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REL = "prom_b/wsa1_prom_b.s"
MARKER = "   [llvm-mc cannot encode this]"
LABEL = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.$]*):')
ADDRESSED = re.compile(r'^\t(\S.*?)\s*;\s*([0-9A-F]{6})\s+(.*)$')


def at(rev):
    return subprocess.run(["git", "show", "%s:%s" % (rev, REL)], cwd=ROOT,
                          capture_output=True, text=True, check=True).stdout.split('\n')


def now():
    return open(os.path.join(ROOT, REL)).read().split('\n')


def facets(lines):
    """The three things the byte gate cannot see."""
    comments = [ln for ln in lines if ln.lstrip().startswith(';')]
    labels = [m.group(1) for m in (LABEL.match(ln) for ln in lines) if m]
    decodes = {}
    for ln in lines:
        m = ADDRESSED.match(ln)
        if m:
            decodes.setdefault(m.group(2), []).append(
                (m.group(3)[:-len(MARKER)] if m.group(3).endswith(MARKER.strip())
                 else m.group(3), m.group(3).endswith(MARKER.strip())))
    return comments, labels, decodes


def compare(before, after, verbose=True):
    ok = fail = 0

    def check(name, cond, extra=""):
        nonlocal ok, fail
        if cond:
            ok += 1
            if verbose:
                print("  ok    %s" % name)
        else:
            fail += 1
            print("  FAIL  %s%s" % (name, extra))

    check("the file has the same number of lines (%d)" % len(before),
          len(before) == len(after),
          "  %d -> %d" % (len(before), len(after)))
    cb, lb, db = facets(before)
    ca, la, da = facets(after)
    check("every comment-only line survives, verbatim (%d)" % len(cb),
          cb == ca, "  %d -> %d" % (len(cb), len(ca)))
    check("every label survives, in order (%d)" % len(lb),
          lb == la, "  %d -> %d" % (len(lb), len(la)))
    check("the same addresses carry a decode (%d)" % len(db),
          set(db) == set(da),
          "  gone: %s" % sorted(set(db) - set(da))[:5])
    bad = [a for a in db if a in da and [t for t, _ in db[a]] != [t for t, _ in da[a]]]
    check("every decode text is unchanged (%d addresses)" % len(db), not bad,
          "  e.g. %s: %r -> %r" % (bad[0], db[bad[0]], da[bad[0]]) if bad else "")
    # the one permitted delta, and it must be accounted for exactly
    mb = sum(1 for a in db for _t, m in db[a] if m)
    ma = sum(1 for a in da for _t, m in da[a] if m)
    changed = sum(1 for i in range(min(len(before), len(after)))
                  if before[i] != after[i])
    check("markers dropped (%d) == lines rewritten (%d)" % (mb - ma, changed),
          mb - ma == changed, "  %d markers, %d lines" % (mb - ma, changed))
    still_byte = sum(1 for a in da for t, m in ((t, m) for t, m in da[a]) if m)
    print("\n  rows still spelled `.byte` with the marker: %d" % still_byte)
    print("  rows rewritten as an instruction:           %d" % changed)
    print("\n%d checks, %d failed" % (ok + fail, fail))
    return fail


def selftest():
    """The comparator must REPORT a loss, not just fail to find one."""
    base = ["\t.byte 0xC1, 0xB8	; F0003C  cp (0x20b8),0x11   [llvm-mc cannot encode this]",
            "; a header line",
            "Label_A:"]
    good = ["\tm_cp_mi8 MB16, 0x20b8, 0x11	; F0003C  cp (0x20b8),0x11",
            "; a header line",
            "Label_A:"]
    print("-- a legal rewrite --")
    a = compare(base, good, verbose=False)
    print("-- a header deleted --")
    b = compare(base, [good[0], good[2]], verbose=False)
    print("-- a decode text quietly changed --")
    c = compare(base, ["\tm_cp_mi8 MB16, 0x20b8, 0x11	; F0003C  cp (0x20b9),0x11"] + good[1:],
                verbose=False)
    print("-- a label renamed --")
    d = compare(base, good[:2] + ["Label_B:"], verbose=False)
    print("\nselftest: legal=%d failures (want 0), deleted-header=%d (want >0), "
          "changed-decode=%d (want >0), renamed-label=%d (want >0)" % (a, b, c, d))
    return 0 if (a == 0 and b and c and d) else 1


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    rev = next((a for a in sys.argv[1:] if not a.startswith('-')), "HEAD")
    print("prom_b/wsa1_prom_b.s: working tree vs %s\n" % rev)
    sys.exit(1 if compare(at(rev), now()) else 0)
