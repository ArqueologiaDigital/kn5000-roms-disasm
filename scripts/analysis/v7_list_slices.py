#!/usr/bin/env python3
"""v7_list_slices.py -- inventory of v7's .incbin slices, with their labels.

QUESTION ANSWERED
  Which `.incbin` slices does v7's maincpu actually pull in, from which file,
  at what offset and length, and under which label? This is the work list for
  v7's verbatim debt (123,927 B across 272 live-referenced romslices plus 2
  raw patches) -- the largest genuine block of verbatim debt in the tree once
  the table_data BMPs are excluded, since those turned out to be the shipped
  artefact rather than debt.

RUN
    python3 scripts/analysis/v7_list_slices.py

⚠ IT REPORTS WHAT THE SOURCE SAYS, NOT WHAT THE ROM CONTAINS. A slice listed
  here is un-disassembled territory, but the label above it is a claim by
  whoever wrote it, not a measurement. Do not treat a label as evidence of
  what the bytes are.

⚠ AND THE LIST IS A LEAD, NOT A PLAN. The mechanical pointer-table class is
  already EXHAUSTED here (convert_v7_ptr_tables.py finds 0 candidates), and a
  structural triage found the remainder ~89% opaque. The productive route is
  cross-version: v7 is an earlier revision of the same firmware as v9 and v10,
  which are far better disassembled, so the corresponding region in v9/v10 is
  usually the strongest available evidence for what a v7 slice holds.
  Correspondence is a LEAD, not proof -- v7 genuinely differs, which is why
  the slices exist at all.
"""
import glob, os, re, json
from pathlib import Path

REPO = str(Path(__file__).resolve().parents[2])
INC = re.compile(r'\.incbin\s+"([^"]+)"(?:\s*,\s*([0-9a-fA-Fx]+)\s*(?:,\s*([0-9a-fA-Fx]+))?)?')
LABEL = re.compile(r'^([A-Za-z_.][\w.]*):')

rows = []
seen_files = set()
for f in sorted(glob.glob('v7/maincpu/**/*.s', recursive=True)):
    lines = open(f, encoding='latin-1').readlines()
    base = os.path.dirname(f)
    for i, line in enumerate(lines):
        m = INC.search(line)
        if not m:
            continue
        path, off, ln = m.groups()
        if 'romslices/' not in path:
            continue
        real = next((c for c in (os.path.join(base, path), os.path.join('v7/maincpu', path), path)
                     if os.path.exists(c)), None)
        if not real:
            continue
        real = os.path.abspath(real)
        fsz = os.path.getsize(real)
        size = int(ln, 0) if ln else (fsz - int(off, 0) if off else fsz)
        # find preceding label
        label = None
        for j in range(i-1, -1, -1):
            mm = LABEL.match(lines[j].strip())
            if mm:
                label = mm.group(1)
                break
        # find following label (after this incbin)
        nextlabel = None
        for j in range(i+1, min(i+5, len(lines))):
            mm = LABEL.match(lines[j].strip())
            if mm:
                nextlabel = mm.group(1)
                break
        if real in seen_files:
            continue
        seen_files.add(real)
        rows.append({'file': f, 'label': label, 'next_label': nextlabel,
                     'bin': os.path.relpath(real, REPO), 'size': size})

rows.sort(key=lambda r: -r['size'])
print(f"total slices: {len(rows)}  total bytes: {sum(r['size'] for r in rows)}")
json.dump(rows, open('/tmp/claude-1000/-home-fsanches-compartilhado-KN7000/af5fe695-af5e-4caf-a2c2-2624dd161081/scratchpad/v7lane/slices.json', 'w'), indent=1)
for r in rows[:30]:
    print(f"{r['size']:6d}  {r['label']!s:45s} -> {r['next_label']!s:35s} {r['bin']}")
