#!/usr/bin/env python3
"""v10audio_data_as_code_spans.py -- data-as-code candidates in THIS LANE'S files,
with the `.byte`-island gap that lane V10DAC's census cannot bridge.

QUESTION ANSWERED
  scripts/analysis/v10_data_as_code_census.py finds DATA written as instructions
  by taking maximal CODE-TERRITORY spans that its reachability walk never
  reaches.  In the audio engine a misframed region is not a clean CODE span: it
  alternates mnemonics with short `.byte` islands (the bytes the assembler could
  not spell), which shatters one 441-byte region into dozens of fragments, most
  below any useful size floor.  MEASURED 2026-09-02: the census flagged 24 B of
  VoiceSlot_CheckAndApply_Data; the region is 441 B.

  This script rebuilds the same unreached-span list but lets a span bridge a
  DATA gap of up to --gap bytes, then keeps only spans in this lane's files and
  scores them with the census's OWN byte-level rule.

⚠ WHAT A HIT IS AND IS NOT
  "Unreached" is an instrument verdict, not a fact: the census's own header
  gives its reachability false-positive rate, and indirect dispatch through a
  pointer table whose entries are NUMERIC (`.long 0x00fcb065`) rather than
  symbolic produces no seed, so its targets look unreached.  A hit is a place to
  READ, and the decision still rests on what references the span -- an address
  load means data, a call or jump means code.

RUN
    python3 scripts/analysis/v10_data_as_code_census.py --build --census
    python3 scripts/analysis/address_line_map.py --dump amap.json
    python3 scripts/analysis/v10audio_data_as_code_spans.py --amap amap.json \
        [--gap 8] [--min 48] [--data-only]

PROVENANCE
  Lane V10AUDIO of the 2026-09-01 full-disassembly push.
"""
import argparse
import bisect
import json
import os
import pickle
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts' / 'analysis'))
from v10audio_byte_triage import in_scope
import v10_data_as_code_census as C

BASE = 0xE00000


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--amap", required=True)
    ap.add_argument("--gap", type=int, default=8)
    ap.add_argument("--min", type=int, default=48)
    ap.add_argument("--data-only", action="store_true")
    a = ap.parse_args()

    d = pickle.load(open(REPO / "notes" / "v10-data-as-code" / "cache.pkl", "rb"))
    terr, reach = d["terr"], d["reached"]
    rom = (REPO / "original_ROMs" / "kn5000_v10_program.rom").read_bytes()
    size = len(rom)

    amap = json.load(open(a.amap))
    pts = sorted(set((e["addr"], e["src"]) for e in amap))
    addrs = [p[0] for p in pts]

    def fileof(x):
        i = bisect.bisect_right(addrs, x) - 1
        return pts[i][1] if i >= 0 else "?"

    spans, i = [], 0
    while i < size:
        if terr[i] == 1 and not reach[i]:
            j = i
            while j < size:
                if terr[j] == 1 and not reach[j]:
                    j += 1
                    continue
                k = j
                while k < size and k - j <= a.gap and terr[k] != 1:
                    k += 1
                if k < size and k - j <= a.gap and terr[k] == 1 and not reach[k]:
                    j = k
                    continue
                break
            spans.append((i, j))
            i = j
        else:
            i += 1

    hits = []
    for s, e in spans:
        if e - s < a.min:
            continue
        f = fileof(BASE + s)
        if not in_scope(f.replace("v10/", "")):
            continue
        m = C.byte_metrics(rom[s:e])
        dl = C.looks_data(m)
        st = C.strict_looks_data(m)
        if a.data_only and not dl:
            continue
        hits.append((e - s, s, e, f, m, dl, st))
    hits.sort(reverse=True)
    print(f"{len(hits)} spans >= {a.min} B in this lane's files "
          f"(gap <= {a.gap} B), {sum(h[0] for h in hits):,} B")
    for n, s, e, f, m, dl, st in hits:
        tag = "STRICT" if st else ("data-like" if dl else "code-shaped")
        print(f"  0x{BASE+s:06X}-0x{BASE+e:06X} {n:6d} B  {tag:11s} "
              f"per {m['per']:3.0f}% ramp {m['ramp']:3.0f}% dist {m['dist']:3d}  "
              f"{os.path.basename(f)}")


if __name__ == "__main__":
    main()
