#!/usr/bin/env python3
"""Shared decode cache for the class-A sweep probes.

QUESTION ANSWERED: none on its own -- this is the piece the other probes need.
It decodes every reachable range once (slow: minutes) and memoises the result in
`decodes.pkl`, so `census.py`, `which.py` and `enum_sites.py` can each be run
standalone and in any order.

⚠ It exists because the first committed version of `census.py` loaded the pickle
without being able to build it. The probe was committed, looked reproducible,
and raised FileNotFoundError for anyone who ran it before `enum_sites.py` --
the cache had only ever been built in a scratch directory. Committing a script
is not the same as committing a script that runs.

Delete `decodes.pkl` to force a rebuild.
"""
import importlib.util, json, os, pickle, sys

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
CACHE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "decodes.pkl")


def load(crr):
    """Return {range_start: [(addr, nbytes, text), ...]}, building the cache if needed."""
    if os.path.exists(CACHE):
        return pickle.load(open(CACHE, "rb"))
    rom = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
    spec = importlib.util.spec_from_file_location(
        "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
    spans = importlib.util.module_from_spec(spec); spec.loader.exec_module(spans)
    terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
    targets = json.load(open(os.path.join(
        REPO, "analysis/v7-reachability/v7_call_targets.json")))["targets"]
    decodes = {}
    for i, t in enumerate(sorted(targets)):
        decodes[t] = crr.decode_range(rom, terr, t)
        if i % 200 == 0:
            print(f"  building decode cache {i}/{len(targets)}", file=sys.stderr)
    pickle.dump(decodes, open(CACHE, "wb"))
    print(f"  cache written: {CACHE}", file=sys.stderr)
    return decodes
