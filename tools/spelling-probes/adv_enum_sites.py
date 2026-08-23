#!/usr/bin/env python3
"""INDEPENDENT enumeration of the three forms' sites in v7's reachable decode.
Written from scratch for the adversarial verification -- does NOT import the
previous agent's probe scripts."""
import os as _os, tempfile as _tf
SCRATCH = _os.environ.get("KN5000_PROBE_SCRATCH", _tf.gettempdir())
_os.makedirs(SCRATCH, exist_ok=True)
import importlib.util, json, os, re, sys, collections, pickle

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
BASE = 0xE00000
sys.path.insert(0, os.path.join(REPO, "scripts/converters"))
_argv = sys.argv[:]
sys.argv = [sys.argv[0]]
spec = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
crr = importlib.util.module_from_spec(spec); spec.loader.exec_module(crr)
cc = crr.cc
sys.argv = _argv

def formkey(text):
    mn = text.split()[0]
    rest = text.split(None, 1)[1] if len(text.split(None, 1)) > 1 else ""
    return mn + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                             re.sub(r'\b[A-Z]{1,4}\b', 'r', rest))

WANT = {'bit 7,(r+r)', 'ld (r+imm),r', 'ld (r+imm),imm'}

rom = open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
s2 = importlib.util.spec_from_file_location(
    "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
spans = importlib.util.module_from_spec(s2); s2.loader.exec_module(spans)
os.chdir(REPO)
terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
targets = json.load(open(os.path.join(REPO, "analysis/v7-reachability/v7_call_targets.json")))["targets"]
syms = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
addr2name = dict(syms)

sites = {}    # addr -> dict
for t in sorted(targets):
    insns = crr.decode_range(rom, terr, t)
    if len(insns) < 3:
        continue
    off = t - BASE; run = 0
    while off + run < len(terr) and terr[off + run] == 2:
        run += 1
    run_end = t + run
    for addr, n, text in insns:
        k = formkey(text)
        if k not in WANT:
            continue
        raw = rom[addr - BASE: addr - BASE + n]
        rec = sites.setdefault(addr, dict(addr=addr, n=n, raw=raw.hex(" "), text=text,
                                          key=k, entries=set(), overshoot=False))
        rec["entries"].add((t, addr2name.get(t, "")))
        if addr + n > run_end:
            rec["overshoot"] = True
        # sanity: same address decoded differently from two entries?
        if rec["text"] != text or rec["n"] != n:
            rec["CONFLICT"] = (rec["text"], rec["n"], text, n)

# spellability with the converter's own logic
for a, r in sites.items():
    raw = bytes.fromhex(r["raw"].replace(" ", ""))
    cands = list(cc.translate(r["text"])) + [cc.canonical(r["text"])]
    r["spellable_now"] = any(cc.encode(c) == raw for c in cands)

pickle.dump({a: {k: (sorted(v) if isinstance(v, set) else v) for k, v in r.items()}
             for a, r in sites.items()},
            open(f"{SCRATCH}/sites.pkl", "wb"))

byk = collections.Counter(r["key"] for r in sites.values())
print("TOTAL distinct site addresses:", len(sites))
for k, v in sorted(byk.items()):
    blocked = sum(1 for r in sites.values() if r["key"] == k and not r["spellable_now"])
    over = sum(1 for r in sites.values() if r["key"] == k and r["overshoot"])
    print(f"  {k:20} total {v:4}   unspellable-now {blocked:4}   overshoot {over}")
conf = [r for r in sites.values() if "CONFLICT" in r]
print("decode conflicts:", len(conf))
