#!/usr/bin/env python3
"""How much of each NAKA C blob is NAKA class records (whose fields the firmware names) vs other data?

Walks each v<N>/maincpu/ui_widgets/naka_*.c blob (Base ROM address / Total size from its header)
greedily: at each offset, a word that is a valid class id (nakarest_objtab_map.Map.record_class)
with allsize >= 6 that fits starts a record of allsize bytes; otherwise step one byte.  Then counts
the struct's top-level `field_XXXX` members whose offset falls inside a record.
Run from the repo root: python3 notes/naka-fields-2026-10-03/probe_records.py v10
"""
import glob, re, sys, os
sys.path.insert(0, "scripts/analysis")
import nakarest_objtab_map as M
v = sys.argv[1] if len(sys.argv) > 1 else "v10"
m = M.Map(v)
FIELD = re.compile(r'\b(?:field|unk|pad)_(?:0x)?([0-9A-Fa-f]{2,6})\b')
tot = [0, 0, 0, 0]
for f in sorted(glob.glob("%s/maincpu/ui_widgets/naka_*.c" % v)):
    s = open(f, encoding="latin-1").read()
    b = re.search(r'Base ROM address: 0x([0-9A-F]+)', s); n = re.search(r'Total size: (\d+)', s)
    if not b or not n: continue
    base, size = int(b.group(1), 16), int(n.group(1))
    # struct member offsets: top-level `field_XXXX` names inside the main typedef
    offs = [int(x, 16) for x in re.findall(r'^\s+uint\d+_t\s+field_([0-9a-f]{4})\b', s, re.M)]
    o, recs, cov, inrec = 0, [], 0, 0
    while o < size:
        c = m.record_class(base + o)
        if c and c['allsize'] >= 6 and o + c['allsize'] <= size:
            recs.append((o, c['name'], c['allsize'])); cov += c['allsize']; o += c['allsize']
        else:
            o += 1
    spans = [(r[0], r[0] + r[2]) for r in recs]
    inrec = sum(1 for x in offs if any(a <= x < e for a, e in spans))
    allf = len(FIELD.findall(s))
    tot[0] += size; tot[1] += cov; tot[2] += len(offs); tot[3] += inrec
    if allf > 30:
        print("%-38s size %6d records %4d covering %6d B (%3d%%)  struct field_ %5d in records %5d  (dashboard count %d)"
              % (os.path.basename(f), size, len(recs), cov, 100 * cov // size, len(offs), inrec, allf))
print("TOTAL size %d covered %d; struct field_ %d of which in records %d" % tuple(tot))
