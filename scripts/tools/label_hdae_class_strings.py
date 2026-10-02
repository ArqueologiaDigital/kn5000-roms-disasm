#!/usr/bin/env python3
"""label_hdae_class_strings.py -- the HD-AE5000 class definitions' name and signature strings get labels.

QUESTION THIS ANSWERS / JOB IT DOES
  hdae5000/hdae5000_data_tables.s holds the expansion ROM's NAKA class definitions; each record's
  +0x0C NamePtr and +0x10 SigPtr were numbers (`.long 0x29d972 ; +0x0C NamePtr -> 'SelectList'`),
  26 of them: the dashboard's whole numdata for hdae5000.  For each pair this places
  `ClassName_<Name>` at the name string and `ClassSig_<Name>` at the signature string
  (scripts/tools/place_labels.py), the name read from the ROM bytes at NamePtr; then
  scripts/tools/symbolize_long_pointers.py spells the `.long`s.  A label emits no byte.

USAGE
  make all
  python3 scripts/tools/label_hdae_class_strings.py [--apply]
  python3 scripts/tools/symbolize_long_pointers.py --tree hdae5000 --apply
"""
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "tools"))
import place_labels                           # noqa: E402

rom = open(os.path.join(REPO, "original_ROMs/hd-ae5000_v2_06i.ic4"), "rb").read()
BASE = 0x280000
L = open(os.path.join(REPO, "hdae5000/hdae5000_data_tables.s"), "rb").read().decode("latin-1").split("\n")
want = {}
for i, l in enumerate(L):
    m = re.match(r'^\s*\.long\s+(0x[0-9a-fA-F]+)\s*;\s*\+0x0C NamePtr', l)
    if m and i + 1 < len(L):
        s = re.match(r'^\s*\.long\s+(0x[0-9a-fA-F]+)\s*;\s*\+0x10 SigPtr', L[i + 1])
        na = int(m.group(1), 16)
        o = na - BASE
        name = rom[o:rom.index(b"\0", o)].decode("latin-1")
        if not re.match(r'^[A-Za-z_]\w*$', name) or not s:
            continue
        want[na] = "ClassName_" + name
        want.setdefault(int(s.group(1), 16), "ClassSig_" + name)
p = place_labels.Planner("hdae5000")
st = {}
for a, n in sorted(want.items()):
    how = p.add(a, n)
    st[how] = st.get(how, 0) + 1
print("hdae5000: %d strings; %s%s" % (len(want), st, "" if "--apply" in sys.argv else " (dry run)"))
if "--apply" in sys.argv:
    p.apply()
