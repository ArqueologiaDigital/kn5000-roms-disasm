#!/usr/bin/env python3
"""v10dac2_review91.py -- Review the resolved spans before any of them is converted.

QUESTION ANSWERED
  Applies a branch/call check over each resolved span: a span reached by real
  control flow is CODE and must not be converted, whatever the census said.

RUN
    python3 scripts/analysis/v10dac2_review91.py

⚠ RESOLVING AN ADDRESS IS NOT LICENCE TO CONVERT. The previous lane
  refused these 91 because it could not place them uniquely; locating them
  removes that obstacle and nothing else. The evidence that a span is DATA
  is still the reference pattern and the byte content, and the byte gate
  cannot help either way -- it passes whether bytes are spelled as
  instructions or as data.

⚠ DO NOT WIDEN THE ACCEPTANCE RULE TO GET MORE MATCHES. A wave-2 lane
  converted 283 island runs on a criterion it later proved unsound and
  reverted all of them, including the ~281 that were probably fine.

PROVENANCE
  Lane V10DAC2, 2026-09-02; recovered from session scratch.
"""
import json, re, os

REPO = '/home/fsanches/compartilhado/disasm-lanes/v10dac2'
SRC = os.path.join(REPO, 'v10/maincpu')

resolved = json.load(open(os.environ.get('RESOLVED91', os.path.join(REPO, 'notes/v10-data-as-code/resolved91.json'))))

BRANCH_RE = re.compile(r'\b(call|calr|call_24|jp|jp_24|jr|jrl)\b', re.IGNORECASE)

file_cache = {}
def get_lines(relpath):
    if relpath not in file_cache:
        p = os.path.join(SRC, relpath)
        file_cache[relpath] = open(p, encoding='latin-1').read().split('\n')
    return file_cache[relpath]

def named_branch_target(name):
    hits = []
    for dirpath, _, fns in os.walk(SRC):
        for fn in fns:
            if not fn.endswith('.s'):
                continue
            p = os.path.join(dirpath, fn)
            for i, line in enumerate(open(p, encoding='latin-1'), 1):
                if BRANCH_RE.search(line) and re.search(r'\b' + re.escape(name) + r'\b', line):
                    hits.append((os.path.relpath(p, SRC), i, line.strip()))
    return hits

out = []
for r in resolved:
    loc = r['e']['loc']
    relfile = r['file']
    sl, el, eml = r['start_line'], r['end_line'], r['end_marker_line']
    lines = get_lines(relfile)
    content = [lines[i-1] for i in range(sl, el+1)]
    after = [lines[i-1] for i in range(el+1, min(el+4, len(lines))+1)] if eml else []
    out.append(dict(loc=loc, addr_lo=r['e']['addr_lo'], addr_hi=r['e']['addr_hi'],
                     size=r['e']['size'], per=r['e'].get('per'), dist=r['e'].get('dist'),
                     file=relfile, start_line=sl, end_line=el, end_marker_line=eml,
                     content=content, after=after))

json.dump(out, open('/tmp/claude-1000/-home-fsanches-compartilhado-KN7000/af5fe695-af5e-4caf-a2c2-2624dd161081/scratchpad/review91.json', 'w'), indent=1)
print('wrote review91.json,', len(out), 'entries')
