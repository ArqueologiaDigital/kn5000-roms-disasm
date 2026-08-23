#!/usr/bin/env python3
"""Dump the ranges convert_reachable_ranges.py refuses with
   "entry is in no indexed .byte block and in no located .incbin".

Runs the REAL converter (--dry-run, plus a write guard) and records, for each
refusal, the entry address and the span, by logging the delta the converter
itself writes into REFUSED_BYTES right after site_of() returned None.
"""
import builtins, importlib.util, json, os, pickle, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.environ.get("KN5000_PROBE_DIR",
                     os.path.join(tempfile.gettempdir(), "kn5000-byte-run-placement"))
os.makedirs(OUT, exist_ok=True)
os.chdir(REPO)
KEY = "entry is in no indexed .byte block and in no located .incbin"

_real_open = builtins.open
class _Sink:
    def __init__(s, p): s.p = p
    def write(s, d): SUPPRESSED.append(s.p); return len(d)
    def close(s): pass
    def __enter__(s): return s
    def __exit__(s, *a): return False
SUPPRESSED = []
def guarded_open(path, mode="r", *a, **kw):
    if any(c in mode for c in "wax+"):
        p = os.path.abspath(str(path))
        if p.startswith(REPO + os.sep):
            return _Sink(p)
    return _real_open(path, mode, *a, **kw)

conv = os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py")
sys.argv = [conv, "--dry-run"]
spec = importlib.util.spec_from_file_location("crr", conv)
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
mod.open = guarded_open
mod.cc.open = guarded_open

CUR = {"t": None}
real_site_of = mod.site_of
def w_site_of(sites, t):
    CUR["t"] = t
    return real_site_of(sites, t)
mod.site_of = w_site_of

class LogDict(dict):
    log = []
    def __setitem__(self, k, v):
        self.log.append((k, v - self.get(k, 0), CUR["t"]))
        dict.__setitem__(self, k, v)
mod.REFUSED_BYTES = LogDict()

state = {}
real_index, real_inc, real_decode = mod.source_index, mod.incbin_index, mod.decode_range
def w_index(s):
    idx = real_index(s); state["idx"] = idx; return idx
def w_inc():
    sites = real_inc(); state["sites"] = sites; return sites
def w_decode(rom, terr, start, limit=16384):
    ins = real_decode(rom, terr, start, limit)
    state.setdefault("decodes", {})[start] = ins
    state["terr"] = terr
    return ins
mod.source_index, mod.incbin_index, mod.decode_range = w_index, w_inc, w_decode

mod.main()

rows = [(t, span) for (k, span, t) in LogDict.log if k == KEY]
print("\n=== EVERY REFUSED_BYTES delta, with the entry site_of() was asked about:")
for (k, d, t) in LogDict.log:
    print(f"   {('0x%06X' % t) if t else '-':>10}  {d:5} B  {k}")
print(f"\n=== {len(rows)} range(s) refused with: {KEY}")
print(f"=== {sum(s for _t, s in rows):,} bytes")
for t, span in sorted(rows):
    print(f"  0x{t:06X}  {span:5} B")
if SUPPRESSED:
    print("WRITES SUPPRESSED:", sorted(set(SUPPRESSED)))

with _real_open(os.path.join(OUT, "unplaced.pkl"), "wb") as fh:
    pickle.dump({"rows": rows,
                 "sites": [{k: v for k, v in s.items() if k != "blob"} |
                           {"bloblen": len(s["blob"])} for s in state.get("sites", [])],
                 "idx_files": {p: [(bk[0], bk[1], bk[2], bk[3], len(bk[4]))
                                   for bk in blocks]
                               for p, (lines, blocks) in state["idx"].items()},
                 }, fh)
print("wrote", os.path.join(OUT, "unplaced.pkl"))
