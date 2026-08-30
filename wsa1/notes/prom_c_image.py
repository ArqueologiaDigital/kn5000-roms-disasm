#!/usr/bin/env python3
"""Give a prom_c probe the IMAGE, not the file that used to be the whole of it.

WHY THIS EXISTS
---------------
notes/prom_c_split.py moved 125,264 of prom_c's 127,731 lines into 26 included
files.  Twenty-nine committed probes open `prom_c/wsa1_prom_c.s` and scan it, and
notes/prom_c_probe_health.py grades seven of them VACUOUS: they still print
success over an input with no payload in it.

★ THIS IS A SHIM, AND IT SHOULD NOT SURVIVE.  notes/asm_source.py is the general
  reader for this -- one resolver for all four images, written by the lane that
  split prom_d in the same hour.  It is not used here only because its --selftest
  was failing on an unrelated double-include of include/tlcs900_mem_ops.inc while
  these seven probes needed a read path.  When asm_source is green, this file
  should become one line:  `from asm_source import image_text`.

WHAT IT GIVES BACK
------------------
`path()` returns a file whose CONTENT is the whole image -- the master with every
`.include "prom_c/..."` replaced inline -- so a caller's existing
`open(SRC)`, `open(SRC, encoding=...)` or `for ln in open(SRC)` keeps working with
a one-line change and no rewrite of its scan.

⚠ IT IS A READ PATH ONLY.  Three probes SPLICE the master (see
  notes/prom_c_probe_health.py's hazard note); pointing their READ here while
  their WRITE stays on the master would overwrite the 2,517-line master with the
  whole image and silently undo the split.  Do not use this in a writer.

⚠ THE EXPANSION IS DERIVED AND IS NOT COMMITTED.  It is rebuilt whenever any
  source is newer than it, and written atomically so two lanes running probes at
  once cannot read a half-written file.

    python3 notes/prom_c_image.py --selftest
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MASTER = os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")
CACHE = os.path.join(ROOT, "notes", ".prom_c-image.s")
INCLUDE_RE = re.compile(r'^\t\.include "(prom_c/[^"]+)"')


def sources():
    """The master and every prom_c file it includes, in include order."""
    out = [MASTER]
    with open(MASTER, encoding="utf-8") as fh:
        for ln in fh:
            m = INCLUDE_RE.match(ln)
            if m:
                p = os.path.join(ROOT, m.group(1))
                if not os.path.isfile(p):
                    raise FileNotFoundError(
                        "%s: .include %r resolves to nothing.  Returning a short "
                        "listing is the bug this module prevents." % (MASTER, m.group(1)))
                out.append(p)
    return out


def text():
    parts = []
    with open(MASTER, encoding="utf-8") as fh:
        for ln in fh:
            m = INCLUDE_RE.match(ln)
            if m:
                with open(os.path.join(ROOT, m.group(1)), encoding="utf-8") as inc:
                    parts.append(inc.read())
            else:
                parts.append(ln)
    return "".join(parts)


def lines():
    return text().split("\n")


def path():
    """A file holding the expanded image; rebuilt when any source is newer."""
    srcs = sources()
    if len(srcs) == 1:
        return MASTER                      # not split; nothing to expand
    newest = max(os.path.getmtime(p) for p in srcs + [os.path.abspath(__file__)])
    if not os.path.exists(CACHE) or os.path.getmtime(CACHE) < newest:
        tmp = "%s.%d" % (CACHE, os.getpid())
        with open(tmp, "w", encoding="utf-8") as fh:
            fh.write(text())
        os.replace(tmp, CACHE)             # atomic; concurrent lanes are safe
    return CACHE


def _selftest():
    """INVARIANTS, not today's line count."""
    ok = True

    def check(cond, msg):
        nonlocal ok
        print(("  ok    " if cond else "  FAIL  ") + msg)
        ok = ok and cond

    srcs = sources()
    master = open(MASTER, encoding="utf-8").read().split("\n")
    exp = lines()
    check(len(exp) >= len(master),
          f"the expansion is never shorter than the master ({len(exp):,} vs {len(master):,})")
    check(not any(INCLUDE_RE.match(l) for l in exp),
          "no `.include \"prom_c/...\"` survives the expansion")
    n_inc = sum(1 for l in master if INCLUDE_RE.match(l))
    check(len(srcs) == n_inc + 1,
          f"every include is accounted for as a source ({len(srcs)} = {n_inc} + 1)")
    if n_inc:
        # ★ the point of the module: the two MUST differ, or a probe reading the
        #   master was never in danger and this shim would be pure ceremony.
        check(len(exp) > 10 * len(master),
              "the image and the master differ by more than an order of magnitude")
    p = path()
    check(open(p, encoding="utf-8").read() == text(),
          "path() holds exactly what text() returns")
    check(p != MASTER or n_inc == 0,
          "path() does not hand back the master while the image is split")
    print("\nPASS" if ok else "\nFAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(_selftest() if "--selftest" in sys.argv else print(path()) or 0)
