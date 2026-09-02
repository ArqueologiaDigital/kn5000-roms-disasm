#!/usr/bin/env python3
"""v10dac2_resolve91.py -- Locate the 91 data-as-code spans that text matching could not place uniquely.

QUESTION ANSWERED
  Reads the committed manifest (notes/v10-data-as-code/v10dac_conversion_manifest.json,
  key `excluded`, reason 'matches (no unique context)') and resolves each span by
  ADDRESS via v10dac2_line_probe, rather than by instruction text -- text was
  ambiguous for exactly these 91, which is why the previous lane refused them.

RUN
    python3 scripts/analysis/v10dac2_resolve91.py

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
import json, re, sys, os
sys.path.insert(0, '/home/fsanches/compartilhado/disasm-lanes/v10dac2/scripts/analysis')
import v10dac2_line_probe as lp

REPO = '/home/fsanches/compartilhado/disasm-lanes/v10dac2'

manifest = json.load(open(os.path.join(REPO, 'notes/v10-data-as-code/v10dac_conversion_manifest.json')))
targets = [e for e in manifest['excluded'] if 'matches (no unique context)' in e.get('reason', '')]
by_addr = lp.load_cache()

results = []
for e in targets:
    lo = int(e['addr_lo'], 16)
    hi = int(e['addr_hi'], 16)
    rows = lp.lookup(by_addr, lo, hi)
    content_rows = [(f, l, a) for f, l, a in rows if a < hi]
    end_rows = [(f, l, a) for f, l, a in rows if a == hi]
    files = set(f for f, l, a in content_rows)
    ok = True
    reason = []
    if not content_rows:
        ok = False
        reason.append('no rows resolved (address unreached by any probe -- file never included?)')
    if content_rows and content_rows[0][2] != lo:
        ok = False
        reason.append(f'first row addr {content_rows[0][2]:#x} != addr_lo {lo:#x}')
    if len(files) > 1:
        ok = False
        reason.append(f'spans multiple files: {files}')
    results.append(dict(e=e, lo=lo, hi=hi, content_rows=content_rows, end_rows=end_rows,
                         files=list(files), ok=ok, reason=reason))

resolved = [r for r in results if r['ok']]
unresolved = [r for r in results if not r['ok']]
print(f"{len(resolved)}/{len(results)} resolved to a single-file, addr_lo-anchored line range")
if unresolved:
    print(f"{len(unresolved)} UNRESOLVED:")
    for r in unresolved:
        print(' ', r['e']['loc'], r['e']['addr_lo'], r['e']['addr_hi'], r['reason'])

json.dump([{**{k: v for k, v in r.items() if k != 'content_rows' and k != 'end_rows'},
            'file': r['files'][0] if r['files'] else None,
            'start_line': r['content_rows'][0][1] if r['content_rows'] else None,
            'end_line': r['content_rows'][-1][1] if r['content_rows'] else None,
            'end_marker_line': r['end_rows'][0][1] if r['end_rows'] else None,
            } for r in results],
          open(os.environ.get('RESOLVED91', os.path.join(REPO, 'notes/v10-data-as-code/resolved91.json')), 'w'),
          indent=1)
print('wrote resolved91.json')
