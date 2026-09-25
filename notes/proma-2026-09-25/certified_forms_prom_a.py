#!/usr/bin/env python3
r"""Run wsa1/scripts/converters/convert_certified_forms.py on prom_a ONLY.

QUESTION THIS ANSWERS
    Which `.byte` lines of wsa1/prom_a/wsa1_prom_a.s does the WSA1 census
    (notes/sound/wsa1_unspellable_forms.py) certify as single decoded
    instructions that the assembler can now spell byte-identically -- and, with
    --apply, rewrite exactly those?  The shared converter walks all four images;
    lane `proma` owns only prom_a, so this wrapper filters its candidate list to
    `prom_a/` paths and reuses its round-trip check and its writer unchanged.

RUN
    python3 notes/proma-2026-09-25/certified_forms_prom_a.py          # dry run, lists them
    python3 notes/proma-2026-09-25/certified_forms_prom_a.py --apply
    make gate-wsa1
"""
import importlib.util
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
CONV = os.path.join(ROOT, "wsa1", "scripts", "converters", "convert_certified_forms.py")
spec = importlib.util.spec_from_file_location("ccf", CONV)
C = importlib.util.module_from_spec(spec)
spec.loader.exec_module(C)

_all = C.candidates
C.candidates = lambda: [c for c in _all() if c[0].startswith("prom_a/")]

if __name__ == "__main__":
    dry = "--apply" not in sys.argv
    for c in C.candidates():
        print("  %s:%d  %-34s ; %s" % c)
    n, refused = C.apply(dry_run=dry)
    print("%d prom_a line(s) %sconverted" % (n, "would be " if dry else ""))
    for r in refused:
        print("  REFUSED %s:%s -- %s" % r)
