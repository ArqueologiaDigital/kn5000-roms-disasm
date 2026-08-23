#!/usr/bin/env python3
"""Reproduce the report's payoff number by running the tree's OWN main()
twice with cached decodes: once unmodified, once with cc.translate wrapped to
also yield `push_a` and `orddm8`. No source file is touched.

Usage: measure.py baseline | patched
"""
import importlib.util, os, pickle, re, sys

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
os.chdir(REPO)
_s = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
crr = importlib.util.module_from_spec(_s); _s.loader.exec_module(crr)
cc = crr.cc

CACHE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "decodes.pkl")
decodes = pickle.load(open(CACHE, "rb"))
crr.decode_range = lambda rom, terr, start, limit=16384: decodes.get(start, [])

if sys.argv[1] == "patched":
    _orig = cc.translate
    def translate(x):
        for c in _orig(x):
            yield c
        p = x.split()
        if p[0].lower() == "push" and len(p) == 2 and p[1].upper() == "A":
            yield "push_a"
        m = re.match(r'^or\s+\((0x[0-9a-fA-F]+)\),([A-Za-z]{1,3})$', x.strip())
        if m:
            yield f"orddm8 {m.group(1)}, {m.group(2).lower()}"
            yield f"orddm16 {m.group(1)}, {m.group(2).lower()}"
    cc.translate = translate

sys.argv = [sys.argv[0]]
crr.main()
