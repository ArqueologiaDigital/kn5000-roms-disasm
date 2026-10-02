#!/usr/bin/env python3
"""trim_string_slices.py -- a `<X>_Str_<Text>` label covers its string, not the unrelated bytes after it.

QUESTION THIS ANSWERS / JOB IT DOES
  split_blobs_at_far_pointers.py cuts an `.incbin` slice where a string starts and gives the new
  piece the string's name -- but the piece runs to the end of the old slice, so
  `InitializeToshi_Str_TT_EXT` labelled 1,294 bytes of which "TT_EXT" is 8 (18 such slices per
  KN5000 maincpu tree on 2026-10-03).  Each is cut after its NUL (and the 0xFF alignment pad
  when there is one); the rest stays an unnamed slice with a comment saying so.  Slices only
  move: `make gate-all`.

USAGE
  make all
  python3 scripts/tools/trim_string_slices.py --tree v10 [--apply]
"""
import argparse
import glob
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
import symbolize_far_pointer_pushes as fp     # noqa: E402
import split_blobs_at_far_pointers as sb      # noqa: E402

LINE = re.compile(r'^(?P<lab>\w+_Str_\w*):(?P<ws>\s*)\.incbin\s+"(?P<f>[^"]+)",\s*(?P<o>0x[0-9A-Fa-f]+|\d+),\s*(?P<n>0x[0-9A-Fa-f]+|\d+)(?P<post>\s*(?:;.*)?)$')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=("v10", "v9", "v7", "hdae5000"))
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    elf, src, _ = fp.IMAGES[a.tree]
    syms = fp.elf_symbols(elf)
    addr = {n: x for x, ns in syms.items() for n in ns}
    rom_path, base = sb.ROM[a.tree]
    rom = open(os.path.join(REPO, rom_path), "rb").read()
    n_cut = 0
    for f in sorted(glob.glob(os.path.join(REPO, src, "**", "*.s"), recursive=True)):
        L = open(f, "rb").read().decode("latin-1").split("\n")
        out, changed = [], False
        for l in L:
            m = LINE.match(l)
            if m and m.group("lab") in addr:
                ad, o, n = addr[m.group("lab")], int(m.group("o"), 0), int(m.group("n"), 0)
                p = ad - base
                e = rom.find(b"\0", p, p + n)
                if e >= 0:
                    sl = e - p + 1
                    if sl < n and rom[p + sl] == 0xFF:
                        sl += 1
                    if n > sl + 2:
                        out.append('%s:%s.incbin "%s", 0x%X, 0x%X%s' % (m.group("lab"), m.group("ws"), m.group("f"), o, sl, m.group("post")))
                        out.append('\t.incbin "%s", 0x%X, 0x%X\t; %d bytes after %s\'s string; unnamed (they sat under its label until 2026-10-03)'
                                   % (m.group("f"), o + sl, n - sl, n - sl, m.group("lab")))
                        n_cut += 1
                        changed = True
                        continue
            out.append(l)
        if changed and a.apply:
            open(f, "wb").write("\n".join(out).encode("latin-1"))
    print("%s: %d string slices trimmed%s" % (a.tree, n_cut, "" if a.apply else " (dry run)"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
