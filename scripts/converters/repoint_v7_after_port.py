#!/usr/bin/env python3
"""repoint_v7_after_port.py -- after port_v10_span_to_v7.py rewrites a v7 span, point the v7 references
into it (`.long SndParam_ResolveWidget + 164`) at the labels the port placed at those very addresses.

QUESTION THIS ANSWERS
  The span's OLD v7 labels sat at drifted addresses, so other v7 files reached the real routines as
  `<old label> + k`.  The port replaces those labels with v10's at the aligned addresses, and the old
  names vanish (the link fails: undefined SndParam_ResolveWidget).  For every reference `NAME [+ k]`
  outside the span to a name the span USED to define, this computes the address it meant -- NAME's
  address in the committed symbol file (symbols/maincpu_v7_symbols_reference.txt) plus k -- and, when a
  label of the newly assembled span sits exactly there, rewrites the reference to that label.  A name
  the port kept but MOVED counts too: `NAME + k` would otherwise reach a different place silently.  A
  reference with no label at its address is reported and left for a human.  The build proves it:
  same bytes, `make gate-all`.

USAGE (repository root, after `make rebuilt_ROMs/kn5000_v7_program.llvm.o` assembled the ported span)
  python3 scripts/converters/repoint_v7_after_port.py OLD_SPAN_FILE.s [--apply]
"""
import glob
import os
import re
import subprocess
import sys

old_file = sys.argv[1]
SPANF = ["v7/maincpu/audio/sndparam_routines.s", "v7/maincpu/midi/midi_serial_routines.s"]
olddefs = set()
for l in open(old_file, "rb").read().decode("latin-1").split("\n"):
    m = re.match(r'^([A-Za-z_][\w]*):', l) or re.match(r'^\s*\.set\s+([A-Za-z_][\w]*)\s*,', l)
    if m:
        olddefs.add(m.group(1))
oldaddr = {}
for l in open("symbols/maincpu_v7_symbols_reference.txt"):
    p = l.split()
    if len(p) == 2 and not l.startswith("#"):
        oldaddr[p[0]] = int(p[1], 16)
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
newat, newdefs, newaddr = {}, set(), {}
for l in subprocess.run([NM, "--defined-only", "rebuilt_ROMs/kn5000_v7_program.llvm.o"],
                        capture_output=True, text=True).stdout.split("\n"):
    p = l.split()
    if len(p) == 3 and p[1] == "t":
        a = int(p[0], 16) + 0xE00000
        newdefs.add(p[2])
        newaddr[p[2]] = a
        newat.setdefault(a, []).append(p[2])
spandefs = set()
for sf in SPANF:
    for l in open(sf, "rb").read().decode("latin-1").split("\n"):
        m = re.match(r'^([A-Za-z_][\w]*):', l)
        if m:
            spandefs.add(m.group(1))
# a name the span used to define that is gone, or now sits elsewhere: `NAME + k` would mean another place
moved = {n for n in olddefs if n in oldaddr and newaddr.get(n) != oldaddr[n]}
REF = re.compile(r'\b([A-Za-z_]\w*)(\s*\+\s*(\d+|0x[0-9a-fA-F]+))?')
changed, left = 0, []
for f in sorted(glob.glob("v7/maincpu/**/*.s", recursive=True)):
    if f in SPANF:
        continue
    L = open(f, "rb").read().decode("latin-1").split("\n")
    ch = False
    for i, l in enumerate(L):
        code, sep, cmt = l.partition(";")
        if not any(n in code for n in moved):
            continue

        def sub(m):
            global changed
            n = m.group(1)
            if n not in moved:
                return m.group(0)
            k = int(m.group(3), 0) if m.group(3) else 0
            t = oldaddr[n] + k
            cand = [x for x in newat.get(t, []) if x in spandefs]
            if not cand:
                left.append("%s:%d %s -> 0x%06X has no label" % (f, i + 1, m.group(0), t))
                return m.group(0)
            changed += 1
            return cand[0]
        new = REF.sub(sub, code)
        if new != code:
            L[i] = new + sep + cmt
            ch = True
    if ch and "--apply" in sys.argv:
        data = "\n".join(L).encode("latin-1")
        open(f + ".tmp", "wb").write(data)
        os.replace(f + ".tmp", f)
print("%d references repointed%s" % (changed, "" if "--apply" in sys.argv else " (dry run)"))
for x in left:
    print("  LEFT " + x)
