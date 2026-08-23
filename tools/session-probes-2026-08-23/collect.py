#!/usr/bin/env python3
"""Collect, per range, everything rewrite() saw when it declined for a label."""
import contextlib, importlib.util, io, json, os, pickle, re, sys

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
BASE = 0xE00000
OUT = os.environ["SCRATCH"]

_real_open = open


class _Sink:
    def __init__(self, p): self.p = p
    def write(self, d): return len(d)
    def close(self): pass
    def __enter__(self): return self
    def __exit__(self, *a): return False


def guarded_open(path, mode="r", *a, **kw):
    if any(c in mode for c in "wax+"):
        p = os.path.abspath(str(path))
        if p.startswith(os.path.abspath(REPO) + os.sep):
            return _Sink(p)
    return _real_open(path, mode, *a, **kw)


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


os.chdir(REPO)
mod = load("crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
mod.open = guarded_open
mod.cc.open = guarded_open

CASES = []
state = {}
real_index, real_decode = mod.source_index, mod.decode_range


def w_index(s):
    idx = real_index(s)
    state["idx"] = idx
    return idx


def w_decode(rom, terr, start, limit=16384):
    state["terr"] = terr
    state["rom"] = rom
    return real_decode(rom, terr, start, limit)


mod.source_index, mod.decode_range = w_index, w_decode
_orig = mod.rewrite


def hook(idx, t, span, insns, texts, addr2name, branch_labels=None):
    rec = {"entry": t, "span": span,
           "insns": [(a, n, x) for a, n, x in insns], "texts": list(texts)}
    for path, (lines, blocks) in idx.items():
        covering = [bk for bk in blocks if bk[1] <= t < bk[1] + len(bk[4])]
        if not covering:
            continue
        touched = sorted([bk for bk in blocks
                          if bk[1] < t + span and bk[1] + len(bk[4]) > t],
                         key=lambda bk: bk[2])
        first, last = touched[0], touched[-1]
        ia = {a for a, _n, _x in insns}
        rec["path"] = path
        rec["lead"] = t - first[1]
        rec["tail"] = (last[1] + len(last[4])) - (t + span)
        rec["blocks"] = [(bk[0], bk[1], len(bk[4]), bk[2], bk[3]) for bk in touched]
        rec["lines"] = lines[first[2]:last[3] + 1]
        rec["line_range"] = (first[2], last[3])
        label_at = {bk[1]: bk[0] for bk in touched if bk[0]}
        rec["labels_in_span"] = sorted(
            (a, nm) for a, nm in label_at.items() if t <= a < t + span)
        rec["off_boundary"] = sorted(
            (a, nm) for a, nm in label_at.items()
            if a != first[1] and t <= a < t + span and a not in ia)
        # raw label defs in replaced lines not known to the block index
        known = set(label_at.values())
        rec["raw_unknown_labels"] = [
            m.group(1) for m in
            (re.match(r'^([A-Za-z_][\w]*):', ln) for ln in rec["lines"]) if m
            and m.group(1) not in known]
        break
    before = dict(mod.REFUSED)
    res = _orig(idx, t, span, insns, texts, addr2name, branch_labels)
    moved = [k for k, v in mod.REFUSED.items() if v != before.get(k, 0)]
    rec["result"] = res
    rec["moved"] = moved
    rec["bucket"] = moved[0] if moved else ("APPLIED" if res else "SILENT")
    CASES.append(rec)
    return res


mod.rewrite = hook
sys.argv = ["conv", "--apply"]
cap = io.StringIO()
with contextlib.redirect_stdout(cap):
    mod.main()
_real_open(os.path.join(OUT, "run.log"), "w").write(cap.getvalue())
with _real_open(os.path.join(OUT, "cases.pkl"), "wb") as fh:
    pickle.dump({"cases": CASES, "terr": state["terr"], "rom": state["rom"],
                 "idx_keys": list(state["idx"].keys())}, fh)
from collections import Counter
c = Counter(r["bucket"] for r in CASES)
b = Counter()
for r in CASES:
    b[r["bucket"]] += r["span"]
for k, v in c.most_common():
    print(f"{v:4} ranges {b[k]:6} B   {k}")
