#!/usr/bin/env python3
"""v142_apply_patch.py -- apply one decoded region back into the source.

QUESTION ANSWERED
  Given a region that v142_decode_region.py decoded and round-tripped,
  splice the resulting instructions into
  v142/subcpu/kn5000_subprogram_v142.s in place of its `.byte` run.

RUN
    python3 scripts/analysis/v142_apply_patch.py

⚠ THIS ONE WRITES. Everything else in this set only reports. Rebuild and
  `cmp` the image against original_ROMs/ after every apply -- a splice that
  moves a byte is a regression to revert, not progress.

⚠ AND A ROUND TRIP IS NOT PROOF THE BYTES ARE CODE. The byte gate cannot
  object to a wrong interpretation, because re-assembling it reproduces the
  same bytes. Corroborate with call targets landing on routines already
  named in the tree before applying.
"""
import sys, re
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from v142_decode_region import decode_stream

SRC = Path.home() / 'compartilhado/disasm-lanes/v142block/v142/subcpu/kn5000_subprogram_v142.s'
lines = SRC.read_text(encoding='latin-1').splitlines(keepends=True)

def bytes_of_line(l):
    m = re.match(r'\s*\.byte\s+(.+?)\s*(;.*)?$', l)
    if m:
        return [int(v,16) for v in re.findall(r'0x([0-9a-fA-F]{2})', m.group(1))]
    m = re.match(r'\s*\.ascii\s+"((?:[^"\\]|\\.)*)"\s*(;.*)?$', l)
    if m:
        s = m.group(1).encode().decode('unicode_escape')
        return [b for b in s.encode('latin-1')]
    return None

def extract_run(s,e):
    raw=[]
    for i in range(s,e+1):
        bs = bytes_of_line(lines[i-1])
        if bs: raw.extend(bs)
    return bytes(raw)

# All 15 confirmed-code runs (excluding the two genuine DATA runs 572-578, 710-710)
CODE_RUNS = [(796,798),(801,804),(811,813),(816,818),(1008,1014),(1028,1037),
             (1047,1054),(1095,1101),(1104,1111),(1115,1120),(1131,1139),
             (1146,1150),(1153,1160),(1164,1166),(1749,1756)]

# Timer_Delay_Ticks: proven OK by llvm_roundtrip_probe.py already (14 B); decode
# it here too through the same self-verifying pipeline for consistency.
PROVEN_RUNS = [(1762,1763)]

new_lines = list(lines)  # will patch by line-range replacement; process high-to-low
patches = []  # (start_idx0, end_idx0, replacement_text)

for s, e in CODE_RUNS + PROVEN_RUNS:
    raw = extract_run(s, e)
    insns = decode_stream(raw)
    assert sum(l for _,l,_,_ in insns) == len(raw), f"{s}-{e}: length mismatch"
    total = bytearray()
    for _,l,enc,_ in insns:
        total += enc
    assert bytes(total) == raw, f"{s}-{e}: byte mismatch after full reassembly"
    body = []
    for text, length, enc, comment in insns:
        line = f"\t{text}"
        if comment:
            line += f"\t; {comment}"
        body.append(line + "\n")
    patches.append((s-1, e, body))  # 0-indexed [start, end)

patches.sort(key=lambda p: -p[0])
for start0, end0, body in patches:
    new_lines[start0:end0] = body

SRC.write_text(''.join(new_lines), encoding='latin-1')
print(f"Applied {len(patches)} patches.")
