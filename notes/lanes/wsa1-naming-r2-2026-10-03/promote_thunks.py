#!/usr/bin/env python3
"""promote_thunks.py -- prom_b's address-named thunks `T_F4xxxx: jp Target` take their target's name.

QUESTION THIS ANSWERS
  prom_a and prom_b call each other through prom_b's 0xF40000 directory of `jp` slots.  A slot whose
  target routine has a semantic name is still spelled `T_F42B70` at every call site (`call T_F42B70`
  in prom_a, through a `.set T_F42B70, 0x00F42B70` alias).  This writes an edit pack that renames such a
  slot to `T_<Target>` -- the convention the already-promoted slots use (`T_Queue2E00_AppendRegs:
  jp Queue2E00_AppendRegs`).  The name is DERIVATIVE: it says only where the slot jumps.
  Rules: the target is not itself placeholder-named (`sub_`, `loc_`, `T_`, a 6-hex-digit run, `_Nop`);
  exactly one slot jumps to it (two slots to one target would need a disambiguating suffix, which
  says nothing; left alone); the new name is defined nowhere yet.
  The pack's `files` is prom_b (the slot's definition), `also` every other WSA1 source and linker
  script (prom_a carries the `.set` aliases).  Apply with scripts/tools/apply_label_edits.py.

USAGE (repository root)
  python3 notes/lanes/wsa1-naming-r2-2026-10-03/promote_thunks.py > notes/lanes/wsa1-naming-r2-2026-10-03/packs/thunks.json
"""
import collections
import glob
import json
import re

B = open("wsa1/prom_b/wsa1_prom_b.s", "rb").read().decode("latin-1").split("\n")
slots = []
for l in B:
    m = re.match(r'^(T_F4[0-9A-F]{4}):\s*jp\s+([A-Za-z_][\w]*)\s*(;.*)?$', l)
    if m:
        slots.append((m.group(1), m.group(2)))
bad = re.compile(r'^(sub|loc|T|LABEL|Data|Unknown)_|[0-9A-F]{6}|_Nop\d*$')
tgt_count = collections.Counter(t for _, t in slots)
defined = set()
for f in glob.glob("wsa1/**/*.s", recursive=True) + glob.glob("wsa1/**/*.inc", recursive=True):
    for l in open(f, "rb").read().decode("latin-1").split("\n"):
        m = re.match(r'^([A-Za-z_.$][\w.$@]*):', l) or re.match(r'^\s*\.(?:set|equ)\s+([A-Za-z_.$][\w.$@]*)\s*,', l)
        if m:
            defined.add(m.group(1))
renames, why = [], collections.Counter()
for old, t in slots:
    if bad.search(t):
        why["target placeholder-named"] += 1
        continue
    if tgt_count[t] > 1:
        why["several slots jump to the target"] += 1
        continue
    new = "T_" + t
    if new in defined:
        why["new name already defined"] += 1
        continue
    renames.append({"old": old, "new": new, "evidence": "prom_b slot %s is `jp %s`" % (old, t)})
also = sorted(f for f in glob.glob("wsa1/**/*.s", recursive=True) + glob.glob("wsa1/**/*.ld", recursive=True)
              + glob.glob("wsa1/**/*.inc", recursive=True)
              if f != "wsa1/prom_b/wsa1_prom_b.s" and "/notes/" not in f)
json.dump({"name": "wsa1-promote-thunks", "files": ["wsa1/prom_b/wsa1_prom_b.s"], "also": also,
           "renames": renames, "headers": []}, open("/dev/stdout", "w"), indent=1)
import sys
print("%d slots `jp <name>`; %d promoted; left: %s" % (len(slots), len(renames), dict(why)), file=sys.stderr)
