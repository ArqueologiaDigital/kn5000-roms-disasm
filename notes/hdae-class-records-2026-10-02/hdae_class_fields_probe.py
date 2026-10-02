#!/usr/bin/env python3
"""hdae_class_fields_probe.py -- are the HD-AE5000 class records' "undecoded" fields the NAKA class fields?

QUESTION THIS ANSWERS
  hdae5000/hdae5000_data_tables.s heads 13 class records (registered under ClassProc,
  0x01600004) whose +0x04/+0x06/+0x08/+0x0A words it called Field_04..Field_0A, UNDECODED.
  The main CPU's class system (scripts/analysis/nakarest_objtab_map.py, THE CLASS SYSTEM)
  names a class definition's fields: proc, parent (u32 class id), allsize (u16), selfsize
  (u16), name, propdata (the type signature), propname.  If the HD-AE5000 records follow it,
  then for every record: selfsize == the summed sizes of its signature characters (SIG_SIZE),
  and allsize == the parent class's allsize + selfsize, the parent being looked up by its
  class id in v10's class tables (or in this same table).  Prints each record and the verdict.

USAGE
  make all
  python3 notes/hdae-class-records-2026-10-02/hdae_class_fields_probe.py
"""
import os
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "analysis"))
import nakarest_objtab_map as nom  # noqa: E402

rom = open(os.path.join(REPO, "original_ROMs/hd-ae5000_v2_06i.ic4"), "rb").read()
B = 0x280000
u16 = lambda a: int.from_bytes(rom[a - B:a - B + 2], "little")
u32 = lambda a: int.from_bytes(rom[a - B:a - B + 4], "little")
cstr = lambda a: rom[a - B:rom.index(b"\0", a - B)].decode("latin-1")
m = nom.Map("v10")
recs = [0x29C0AA + 24 * k for k in range(13)]
own = {}
for a in recs:
    own[u32(a + 4)] = None
ok = True
rows = []
for k, a in enumerate(recs):
    parent, alls, selfs = u32(a + 4), u16(a + 8), u16(a + 10)
    name, sig = cstr(u32(a + 12)), cstr(u32(a + 16))
    sigsize = sum(nom.SIG_SIZE.get(ch, 0) for ch in sig)
    pc = m.klass(parent)
    pname, pall = (pc["name"], pc["allsize"]) if pc else ("?", None)
    good = sigsize == selfs and pall is not None and pall + selfs == alls
    ok &= good
    rows.append((k, name, parent, pname, alls, selfs, sig, sigsize, pall, good))
    print("%2d %-18s parent 0x%08X %-14s allsize %3d selfsize %3d sig %-12r sig sum %3d parent allsize %s %s"
          % (k, name, parent, pname, alls, selfs, sig, sigsize, pall, "ok" if good else "MISMATCH"))
print("VERDICT:", "PASS -- all 13 follow the class layout" if ok else "FAIL")
