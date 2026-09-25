#!/usr/bin/env python3
r"""assert_c_comments_preserved.py -- the comment gate, for C sources.

QUESTION ANSWERED
-----------------
`assert_comments_preserved.py` checks `;` comments in assembly.  The NAKA blob
sources are C, and a retyping pass that replaces thousands of struct members
could silently drop a `/* ... */` block that described one of them -- the byte
gate cannot see that.  This script asks: is every comment of the file at a git
revision still present, in order and unaltered, in the working tree?
(Subsequence test: adding comments passes, deleting or rewording one fails.)

Comment text is compared after collapsing whitespace, so re-indenting a block
is not a change but rewording a single word is.

--allow REGEX names comments that MAY disappear (whole-comment match), for a
pass that deliberately retires a known-false generator annotation.  Every
allowed drop is counted and printed, so the waiver is visible, not silent.
The NAKA retype uses `--allow '/\* (zero padding|\d+ pointers) \*/'`: those
are naka_struct_decode.py's trailing notes on members that turned out to be
pixel bytes inside a bitmap (a 00 run is black pixels, not padding; FF FF FF 00
is four pixels, not a pointer).

RUN
    python3 scripts/analysis/assert_c_comments_preserved.py --base HEAD file.c [...]
    python3 scripts/analysis/assert_c_comments_preserved.py --selftest
"""
import argparse
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]


def comments_of(text):
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c == '/' and text.startswith('/*', i):
            j = text.index('*/', i + 2) + 2
            out.append(' '.join(text[i:j].split()))
            i = j
        elif c == '/' and text.startswith('//', i):
            j = text.find('\n', i)
            j = n if j < 0 else j
            out.append(' '.join(text[i:j].split()))
            i = j
        elif c in '"\'':
            j = i + 1
            while text[j] != c:
                j += 2 if text[j] == '\\' else 1
            i = j + 1
        else:
            i += 1
    return out


def missing(old, new):
    """Return the first comment of `old` that is not matched, in order, in `new`."""
    k = 0
    for c in old:
        while k < len(new) and new[k] != c:
            k += 1
        if k == len(new):
            return c
        k += 1
    return None


def git_show(rev, path):
    rel = pathlib.Path(path).resolve().relative_to(ROOT)
    p = subprocess.run(['git', 'show', '%s:%s' % (rev, rel)], cwd=ROOT, capture_output=True)
    return None if p.returncode else p.stdout.decode('latin-1')


def selftest():
    base = 'int a; /* one */\nint b; // two\nchar *s = "/* not */";\n/* three */'
    assert missing(comments_of(base), comments_of(base + '\n/* four */')) is None
    assert missing(comments_of(base), comments_of(base.replace('/* one */', ''))) == '/* one */'
    assert missing(comments_of(base), comments_of(base.replace('three', 'thr33'))) == '/* three */'
    assert '/* not */' not in comments_of(base)
    print('selftest: PASS (fails on a deleted and on a reworded comment, passes an added one)')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--base', default='HEAD')
    ap.add_argument('--selftest', action='store_true')
    ap.add_argument('--allow', default=None,
                    help='regex of whole comments that may be dropped')
    ap.add_argument('paths', nargs='*')
    a = ap.parse_args()
    if a.selftest:
        selftest()
        return
    bad = 0
    for p in a.paths:
        old = git_show(a.base, p)
        if old is None:
            print('  %-60s new file' % p)
            continue
        new = pathlib.Path(p).read_bytes().decode('latin-1')
        co, cn = comments_of(old), comments_of(new)
        waived = 0
        if a.allow:
            rx = re.compile(a.allow)
            keep = []
            for c in co:
                if rx.fullmatch(c):
                    waived += 1
                else:
                    keep.append(c)
            co = keep
        m = missing(co, cn)
        print('  %-60s %6d -> %6d  %s%s' % (p, len(co) + waived, len(cn),
                                         'ok' if m is None else 'LOST',
                                         ('  (%d allowed by --allow may be gone)' % waived) if waived else ''))
        if m is not None:
            bad += 1
            print('      first lost comment: %s' % m[:200])
    if bad:
        sys.exit('FAIL: %d file(s) lost a comment' % bad)
    print('PASS: every C comment survives, in order, unaltered.')


if __name__ == '__main__':
    main()
