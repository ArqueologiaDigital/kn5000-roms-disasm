#!/usr/bin/env python3
"""scan_declared_size_vs_incbin.py -- Find labels whose preceding comment declares a byte count, immediately followed by .incbin.

QUESTION IT SERVES: the recurring sizing defect -- reachability data objects
  sized 2 to 83 bytes TOO LARGE, each silently swallowing the leading records of
  the structure that begins right after. Found three times in prom_b (1,890 B
  recovered) and never looked for elsewhere.

⚠ A DECLARED SIZE DISAGREEING WITH THE BLOB IS A LEAD, NOT A FINDING. The
  symptom is invisible in both directions: an oversized object looks like
  ordinary unconverted data and the truncated structure looks like it simply
  starts later. The corroboration that makes a correction legitimate is a
  ZERO-DRIFT landing on an already call-site-documented or already-converted
  neighbour after shrinking to an independently verifiable extent. Without that,
  a shrink is a guess, and this tree forbids boundaries fixed by nothing more
  than 'the walk stops looking plausible'.

RUN
    python3 scripts/analysis/scan_declared_size_vs_incbin.py

PROVENANCE
  Lane SIZINGHUNT, 2026-09-02; recovered from session scratch.
"""
import re, sys, os

HDR_RE = re.compile(r'^; ([A-Za-z_][A-Za-z0-9_]*) -- (\d+) bytes', re.M)
LABEL_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$', re.M)
INCBIN_RE = re.compile(r'^\t\.incbin ', re.M)

def scan(path):
    text = open(path, encoding='utf-8', errors='replace').read()
    lines = text.split('\n')
    hits = []
    # find every label line, and header-declared-size comment above it (within 15 lines)
    for i, line in enumerate(lines):
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$', line)
        if not m:
            continue
        label = m.group(1)
        # look upward up to 20 lines for "-- N bytes"
        size = None
        for j in range(i-1, max(0, i-20), -1):
            hm = re.search(re.escape(label) + r'\s*-- (\d+) bytes', lines[j])
            if hm:
                size = int(hm.group(1))
                break
            if lines[j].strip() == '' or (not lines[j].startswith(';')):
                # keep scanning through comment block only
                if lines[j].startswith(';'):
                    continue
                else:
                    break
        if size is None:
            continue
        # scan forward from i+1 to find where the object's bytes end (naive: consume .byte/.long/.short/.ascii/.fill lines that are contiguous, no blank/label break) -- instead just look at what comes right after `size` declared, check next non-data line
        # Find next label or directive after this point within reasonable window
        # We instead check the immediate next construct AFTER consuming lines that are data directives
        k = i+1
        while k < len(lines) and re.match(r'^\t\.(byte|long|short|word|ascii|fill)\b', lines[k]):
            k += 1
        # k now points to first non-data line after the object (could be blank/comment/incbin/label)
        # skip blank lines and comments
        k2 = k
        while k2 < len(lines) and (lines[k2].strip()=='' or lines[k2].startswith(';')):
            k2 += 1
        if k2 < len(lines) and lines[k2].startswith('\t.incbin'):
            hits.append((path, label, size, i+1, k2+1, lines[k2].strip()))
    return hits

for path in sys.argv[1:]:
    for h in scan(path):
        print(h)
