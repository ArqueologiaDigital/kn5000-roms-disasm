#!/usr/bin/env python3
"""align_packages.py -- pair each Wave 7 annotation PACKAGE with ITS OWN critique.

QUESTION ANSWERED: which critique reviewed which package?

THE TRAP THIS EXISTS TO DOCUMENT: the workflow journal (journal.jsonl) records agent results in
COMPLETION order, not in submission order. Reading packages and critiques out of the journal and
zipping them therefore pairs package i with a critique of some *other* package -- silently, and the
result still looks plausible because every critique is about KN5000 disassembly. Two integration
attempts were made on mis-paired data before this was noticed.

The workflow's own RETURN VALUE is the authority: it carries `packages` and `critiques` as two
arrays that are aligned BY POSITION. That file is the tool's output, at

    <session tasks dir>/<runId>.output      (JSON; the payload is under the key "result")

Usage:
    python3 align_packages.py <workflow-output.json> <out.json>

Writes {"packages": [...], "critiques": [...]} with the alignment preserved, and prints one line
per package so the pairing can be eyeballed before anything is applied.
"""
import json
import sys


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    raw = json.load(open(sys.argv[1]))
    res = raw.get('result', raw)
    if isinstance(res, str):
        res = json.loads(res)
    pkgs, crits = res['packages'], res['critiques']
    if len(pkgs) != len(crits):
        sys.exit(f"REFUSING: {len(pkgs)} packages vs {len(crits)} critiques -- not positionally aligned")
    json.dump({'packages': pkgs, 'critiques': crits}, open(sys.argv[2], 'w'), indent=1)
    print(f"{len(pkgs)} packages, {len(crits)} critiques -- aligned by array position\n")
    for i, (p, c) in enumerate(zip(pkgs, crits)):
        cc = c.get('critique', c)
        print(f"  [{i}] {cc.get('verdict','?'):18} {len(p['edits']):2} edits  {p.get('topic', p.get('summary',''))[:64]}")


if __name__ == '__main__':
    main()
