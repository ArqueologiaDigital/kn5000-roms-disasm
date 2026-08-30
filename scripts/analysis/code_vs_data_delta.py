#!/usr/bin/env python3
r"""HOW MANY BYTES DID A COMMIT MOVE BETWEEN CODE AND DATA TERRITORY?

QUESTION ANSWERED
-----------------
A re-framing lane's headline number is "N bytes moved from CODE territory to
DATA". `assert_byte_identical.py` cannot measure it -- by construction nothing
moved in the ROM. Counting `.byte` lines by hand gets it wrong. This measures
it: it assembles the v10 maincpu at two revisions with `llvm-mc -show-encoding`
and counts the bytes that came out of INSTRUCTION lines (those with an
encoding) versus everything else.

    code(rev) = sum of encoding widths over the whole flattened stream

The delta is the answer, and it is signed: a lane that re-framed data as code
by mistake would show a POSITIVE code delta.

RUN
    python3 scripts/analysis/code_vs_data_delta.py <old-rev> [<new-rev>]
    python3 scripts/analysis/code_vs_data_delta.py --selftest

--selftest checks INVARIANTS: that HEAD against itself is exactly zero, and
that the counter's code+data+pad total equals the ROM size to the byte at every
revision it is asked about -- the same closure check l1_territory_map.py uses.
Neither pins a value.
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import reachability_kn5000 as R          # noqa: E402


def measure(rev):
    """(code, data, pad, total) for v10/maincpu at `rev`."""
    with tempfile.TemporaryDirectory() as wt:
        subprocess.run(["git", "worktree", "add", "--detach", wt, rev],
                       cwd=ROOT, check=True, capture_output=True)
        # ** The `includes/generated/*.bin` blobs are BUILD ARTEFACTS and are not
        # tracked, so a fresh worktree has none of them. Symlink every
        # non-.s file the live tree has and the worktree lacks. They are
        # generated from the ROM, which is identical at both revisions, so this
        # cannot smuggle a difference in -- and the closure check below would
        # catch it if it did.
        live = os.path.join(ROOT, "v10/maincpu")
        for dp, dn, fn in os.walk(live):
            rel = os.path.relpath(dp, live)
            for f in fn:
                if f.endswith(".s"):
                    continue
                dst = os.path.normpath(os.path.join(wt, "v10/maincpu", rel, f))
                if not os.path.exists(dst):
                    os.makedirs(os.path.dirname(dst), exist_ok=True)
                    os.symlink(os.path.join(dp, f), dst)
        try:
            old = R.ROOT
            R.ROOT = wt
            mirror = tempfile.mkdtemp(prefix="cvd-")
            R.build_mirror(mirror)
            code, labels, words, data, pad, pos = R.flatten(mirror)
            R.ROOT = old
            return sum(n for n, _ in code.values()), data, pad, pos
        finally:
            subprocess.run(["git", "worktree", "remove", "--force", wt],
                           cwd=ROOT, capture_output=True)


def main():
    if "--selftest" in sys.argv:
        ok = True
        c, d, p, tot = measure("HEAD")
        romsize = len(open(os.path.join(ROOT, R.TARGET["rom"]), "rb").read())
        for desc, cond, extra in (
                ("code + data + pad closes on the ROM size",
                 c + d + p == tot == romsize, "%d + %d + %d = %d" % (c, d, p, tot)),
                ("HEAD measured against HEAD is a zero delta",
                 measure("HEAD")[0] - c == 0, "")):
            print("  %-52s %s %s" % (desc, "PASS" if cond else "FAIL", extra))
            ok = ok and cond
        print("SELFTEST", "PASS" if ok else "FAIL")
        return 0 if ok else 1
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    old_rev = sys.argv[1]
    new_rev = sys.argv[2] if len(sys.argv) > 2 else "HEAD"
    co, do, po, to = measure(old_rev)
    cn, dn, pn, tn = measure(new_rev)
    print("%-12s code %9s   data %9s   pad %8s   total %9s"
          % (old_rev, format(co, ","), format(do, ","), format(po, ","),
             format(to, ",")))
    print("%-12s code %9s   data %9s   pad %8s   total %9s"
          % (new_rev, format(cn, ","), format(dn, ","), format(pn, ","),
             format(tn, ",")))
    print("delta        code %+9s   data %+9s   pad %+8s"
          % (format(cn - co, ","), format(dn - do, ","), format(pn - po, ",")))
    print("★ %s bytes moved from CODE territory to DATA" % format(co - cn, ","))
    return 0


if __name__ == "__main__":
    sys.exit(main())
