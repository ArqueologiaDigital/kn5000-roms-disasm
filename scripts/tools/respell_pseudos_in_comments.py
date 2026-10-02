#!/usr/bin/env python3
"""respell_pseudos_in_comments.py -- comments that quote a retired register-indexed pseudo quote the native spelling.

QUESTION THIS ANSWERS / JOB IT DOES
  scripts/converters/respell_reg_indexed_pseudos.py replaced `ld_rrl xwa, xbc, wa` and its kin by
  `ld xwa, (xbc+wa)` in the code (2026-10-02); headers that QUOTE the instruction in backticks
  kept the retired spelling, which no longer assembles and no longer appears next to them.  This
  rewrites every backtick-quoted pseudo (ld_rr*, st_rr*, lda_rr, jp_rr, jp_24) in .s and .c
  comments with the same native() mapping.  Comments only: no byte changes.

USAGE
  python3 scripts/tools/respell_pseudos_in_comments.py DIR [DIR ...] [--apply]
"""
import glob
import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "converters"))
import respell_reg_indexed_pseudos as R  # noqa: E402

Q = re.compile(r'`(ld_rr8?[bwl]|st_rr8?[bwl]|lda_rr|jp_rr|jp_24)\s+([^`]+)`')
SPAN = re.compile(r'`([^`\n]*(?:ld_rr8?[bwl]|st_rr8?[bwl]|lda_rr|jp_rr|jp_24)\s[^`\n]*)`')   # every ;-part


def main():
    apply = "--apply" in sys.argv
    for d in [x for x in sys.argv[1:] if x != "--apply"]:
        n = 0
        for f in sorted(glob.glob(os.path.join(d, "**", "*.s"), recursive=True) + glob.glob(os.path.join(d, "**", "*.c"), recursive=True)):
            t = open(f, "rb").read().decode("latin-1")

            def one(part):
                m = re.match(r'^(\s*)(ld_rr8?[bwl]|st_rr8?[bwl]|lda_rr|jp_rr|jp_24)\s+(.+?)(\s*)$', part)
                if not m:
                    return part
                nat = R.native(m.group(2), m.group(3))
                return m.group(1) + re.sub(r'\t', ' ', nat) + m.group(4) if nat else part

            def rep(m):
                return "`%s`" % "".join(one(x) for x in re.split(r'(;|\s/\s)', m.group(1)))
            t2 = SPAN.sub(rep, t)
            if t2 != t:
                n += len(SPAN.findall(t)) - len(SPAN.findall(t2))
                if apply:
                    open(f, "wb").write(t2.encode("latin-1"))
        print("%s: %d quotes respelled%s" % (d, n, "" if apply else " (dry run)"))


if __name__ == "__main__":
    main()
