#!/usr/bin/env python3
"""canonicalize_positional_aliases.py -- a positional alias (`.set X_0xNN, Base + N` in shared/positional_labels.s)
whose address already carries exactly one other label is a second name for that address.

QUESTION THIS ANSWERS / JOB IT DOES
  CLAUDE.md's Canonical Label Names policy: one name per address.  For every alias in <tree>/maincpu/shared/
  positional_labels.s, the tree's linked ELF is asked which other (non-local) symbols sit at the alias's address.
  When there is exactly one, every use of the alias in the tree's .s/.c/.ld files is rewritten to that label
  (`Alias + 0x96` -> `Label + 0x96`) and the `.set` line is removed.  An alias with no other label, or several,
  is listed and left.  Same bytes: run make gate-all after --apply.

USAGE
  make all
  python3 scripts/renaming/canonicalize_positional_aliases.py --tree v10 [--apply]
"""
import argparse, glob, os, re, subprocess
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
ap = argparse.ArgumentParser(); ap.add_argument("--tree", required=True); ap.add_argument("--apply", action="store_true")
a = ap.parse_args()
by, sy = {}, {}
for l in subprocess.run([NM, "--defined-only", os.path.join(REPO, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % a.tree)],
                        capture_output=True, text=True, check=True).stdout.splitlines():
    p = l.split()
    if len(p) == 3:
        by.setdefault(int(p[0], 16), []).append(p[2]); sy[p[2]] = int(p[0], 16)
PLP = os.path.join(REPO, a.tree, "maincpu", "shared", "positional_labels.s")
pl = open(PLP, "rb").read().decode("latin-1")
done, left = {}, []
for alias, base, off in re.findall(r'^\t\.set (\w+), (\w+) \+ (\d+)$', pl, re.M):
    others = [n for n in by.get(sy.get(alias), []) if n != alias and not n.startswith(".L") and n != base]
    if len(others) == 1:
        done[alias] = others[0]
    else:
        left.append((alias, others))
for alias, lab in sorted(done.items()):
    print("  %-40s -> %s" % (alias, lab))
for alias, o in left:
    print("  left: %-34s other labels at its address: %s" % (alias, o))
if a.apply and done:
    rx = re.compile(r"\b(%s)\b" % "|".join(map(re.escape, done)))
    for f in glob.glob(os.path.join(REPO, a.tree, "maincpu", "**", "*"), recursive=True):
        if not f.endswith((".s", ".c", ".ld")) or os.path.abspath(f) == os.path.abspath(PLP):
            continue
        t = open(f, "rb").read().decode("latin-1")
        t2 = rx.sub(lambda m: done[m.group(1)], t)
        if t2 != t:
            open(f + ".tmp", "wb").write(t2.encode("latin-1")); os.replace(f + ".tmp", f)
    pl2 = re.sub(r'^\t\.set (%s), \w+ \+ \d+\n' % "|".join(map(re.escape, done)), "", pl, flags=re.M)
    open(PLP + ".tmp", "wb").write(pl2.encode("latin-1")); os.replace(PLP + ".tmp", PLP)
print("%s: %d aliases canonicalized, %d left%s" % (a.tree, len(done), len(left), "" if a.apply else " (dry run)"))
