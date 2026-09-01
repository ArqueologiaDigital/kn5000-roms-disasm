#!/usr/bin/env python3
"""prom_d_debt_probe.py -- territorial debt in prom_d's tone-database sources.

QUESTION ANSWERED
  Of prom_d's 524,288 bytes, how many are accounted for by the tone-database
  source files, split by directive class (.byte / ascii / .word / .long /
  fill)?  And: is an UNSTRUCTURED DUMP hiding inside what looks like
  per-record source?

  The second question is the point.  Byte totals alone cannot tell a genuine
  record table from a raw blob that happens to be spelled in .byte
  directives -- both "account for" their bytes.  So the probe also measures
  LABEL DENSITY: any label-to-label span longer than 512 bytes is reported,
  because real per-record data carries labels at record boundaries and a
  dump does not.  A large span is a lead, not a verdict.

  ⚠ It reports what the SOURCE says, not what the ROM says.  It is not a
  substitute for the byte-identity gate, and a difference from 524,288 means
  these three files are not the whole image -- which is expected.

RUN
  python3 wsa1/notes/sound/prom_d_debt_probe.py

PROVENANCE
  Written by the PROMD lane of the 2026-09-01 full-disassembly push, and
  recovered from session scratch before it was lost.  ROOT is derived from
  this file's location so it works from any checkout or worktree.
"""
import re, sys, os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "prom_d")

FILES = ["tone_database_directory.s", "tone_database_records.s", "tone_database_aux.s"]

WIDTH = {"byte": 1, "hword": 2, "short": 2, "word": 4, "long": 4, "dword": 8, "quad": 8}
ESCAPE = re.compile(r'\\(?:[0-7]{1,3}|x[0-9a-fA-F]{1,2}|.)')

def ascii_len(operand):
    total = 0
    for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', operand):
        body = m.group(1)
        total += len(ESCAPE.sub("X", body))
    return total

def count_items(rest):
    # split top-level commas, ignoring none nested (no exprs with commas expected here)
    return len([x for x in rest.split(",") if x.strip() != ""])

total = {"byte": 0, "ascii": 0, "word": 0, "long": 0, "fill": 0, "other": 0}
unknown_directives = set()
pos = 0
label_positions = []  # (pos, label, file, lineno)
gaps = []
last_pos = 0
last_label = None

DIRECTIVE_RE = re.compile(r'^\s*\.(\w+)\s*(.*)$')
LABEL_RE = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.]*):')

for fn in FILES:
    path = os.path.join(ROOT, fn)
    with open(path) as f:
        for lineno, line in enumerate(f, 1):
            s = line.split(";", 1)[0].rstrip("\n")
            stripped = s.strip()
            if not stripped:
                continue
            lm = LABEL_RE.match(stripped)
            if lm:
                label_positions.append((pos, lm.group(1), fn, lineno))
                continue
            m = DIRECTIVE_RE.match(stripped)
            if not m:
                continue
            d, rest = m.group(1), m.group(2).strip()
            if d in WIDTH:
                n = WIDTH[d] * count_items(rest)
                total[d if d in total else "other"] = total.get(d, 0) + n
                pos += n
            elif d in ("ascii", "asciz"):
                n = ascii_len(rest) + (1 if d == "asciz" else 0)
                total["ascii"] += n
                pos += n
            elif d == "fill":
                parts = [p.strip() for p in rest.split(",")]
                n = int(parts[0], 0)
                if len(parts) >= 2:
                    n *= int(parts[1], 0)
                total["fill"] += n
                pos += n
            elif d in ("include",):
                continue
            elif d == "text":
                continue
            else:
                unknown_directives.add(d)

print("=== prom_d territorial debt probe ===")
print("total bytes accounted:", sum(total.values()))
for k, v in total.items():
    print(f"  {k:8s} {v:>10,}")
print("unknown directives:", unknown_directives)
print()
print("expected image size: 524288 (wsa1_prom_d.bin)")
print("difference:", 524288 - sum(total.values()))
print()

# label density / gap analysis: any run of raw .byte with no label boundary
# longer than a threshold is suspect (an unstructured dump hiding inside
# what looks like per-record source).
label_positions.append((pos, "<EOF>", "-", 0))
max_gap = 0
max_gap_info = None
THRESH = 512
big_gaps = []
for i in range(1, len(label_positions)):
    p0, l0, f0, ln0 = label_positions[i-1]
    p1, l1, f1, ln1 = label_positions[i]
    gap = p1 - p0
    if gap > max_gap:
        max_gap = gap
        max_gap_info = (l0, f0, ln0, gap)
    if gap > THRESH:
        big_gaps.append((l0, f0, ln0, gap))

print(f"labels found: {len(label_positions)-1}")
print(f"largest single label-to-label span: {max_gap} bytes, after label {max_gap_info}")
print(f"spans > {THRESH} bytes: {len(big_gaps)}")
for g in big_gaps[:30]:
    print("   ", g)
