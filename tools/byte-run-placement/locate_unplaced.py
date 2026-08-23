#!/usr/bin/env python3
"""For each refused range, print the SOURCE LINE its entry lands in."""
import bisect, os, pickle, sys, tempfile

OUT = os.environ.get("KN5000_PROBE_DIR",
                     os.path.join(tempfile.gettempdir(), "kn5000-byte-run-placement"))
os.makedirs(OUT, exist_ok=True)
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BASE = 0xE00000
recs = pickle.load(open(os.path.join(OUT, "line_map.pkl"), "rb"))   # (addr,tag,rel,lineno,text)
addrs = [r[0] for r in recs]
rows = pickle.load(open(os.path.join(OUT, "unplaced.pkl"), "rb"))["rows"]
rom = open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()

def find(a):
    i = bisect.bisect_right(addrs, a) - 1
    while i >= 0 and recs[i][0] == recs[i + 1][0] if i + 1 < len(recs) else False:
        break
    return i

def line_of(a):
    i = bisect.bisect_right(addrs, a) - 1
    if i < 0:
        return None
    # among equal-address records pick the LAST one (closest preceding emitter)
    while i + 1 < len(recs) and recs[i + 1][0] <= a:
        i += 1
    return i

import collections
byfile = collections.Counter()
bykind = collections.Counter()
print(f"{len(rows)} refused range(s), {sum(s for _t,s in rows):,} bytes\n")
detail = []
for t, span in sorted(rows):
    i = line_of(t)
    a, tag, rel, ln, text = recs[i]
    nxt = recs[i + 1][0] if i + 1 < len(recs) else None
    end = t + span
    j = line_of(end - 1)
    a2, _t2, rel2, ln2, text2 = recs[j]
    print(f"0x{t:06X} {span:4} B  {rel}:{ln+1}  (+{t-a})  {text.strip()[:90]!r}")
    if (rel2, ln2) != (rel, ln):
        print(f"           ..ends in {rel2}:{ln2+1}  {text2.strip()[:80]!r}")
    byfile[rel] += span
    s = text.strip()
    kind = ("incbin" if ".incbin" in s else
            "byte" if s.startswith(".byte") else
            "ascii" if s.startswith((".ascii", ".asciz")) else
            "word/long" if s.startswith((".word", ".long", ".short", ".hword")) else
            "space/fill" if s.startswith((".space", ".fill", ".zero")) else
            "align/org" if s.startswith((".align", ".org", ".balign")) else
            "label" if s.endswith(":") else
            "other-directive" if s.startswith(".") else "instruction")
    bykind[kind] += span
    detail.append((t, span, rel, ln, text, kind))
print("\n--- bytes by file")
for f, b in byfile.most_common():
    print(f"  {b:6,}  {f}")
print("\n--- bytes by construct kind at the ENTRY line")
for k, b in bykind.most_common():
    print(f"  {b:6,}  {k}")
pickle.dump(detail, open(os.path.join(OUT, "detail.pkl"), "wb"))
