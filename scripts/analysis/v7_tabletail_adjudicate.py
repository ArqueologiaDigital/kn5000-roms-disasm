#!/usr/bin/env python3
"""v7_tabletail_adjudicate.py -- per-region adjudication for the 32 v7 regions
that v9_v10_undisassembled_census.py's CODE/DATA rule flagged as CODE-like
(all call targets resolving to already-named routines) but that
fill_verified_islands.looks_like_a_table_tail() rejected anyway, because its
150-byte tail window failed the same db%/per%/ramp%/dist rule.

WHY THIS SCRIPT: lane V7TABLETAIL's brief is to adjudicate these 32 regions
individually -- neither trust the aggregate corroboration blindly (the guard
exists precisely because 283 island conversions that ALL passed a similar
aggregate check turned two real data tables into instructions) nor reject them
all just because the guard fired (a >=64B region ending on a real ret/reti/jp
with every call resolving is exactly the shape real code has).

METHOD: everything here reads ONLY original_ROMs/kn5000_v7_program.rom, the
frozen hardware dump. A region's *interpretation* (converted to instructions
vs left as .byte) never changes those bytes -- byte-exact reassembly is the
whole point of this project -- so the dump is ground truth for this analysis
regardless of what the CURRENT v7/maincpu/*.s source says at any moment.  This
sidesteps the shifting-line-number problem entirely for the adjudication step;
line numbers only matter later, for a lane that goes on to EDIT one of these
regions, and must be re-derived by address at that time (see
scripts/analysis/v10dac2_line_probe.py for the technique).

For each region this prints:
  * full disassembly of the region
  * metrics() over the WHOLE region and over the last min(150,size) bytes
    (the exact window looks_like_a_table_tail() judged)
  * a fixed-width-record probe: for stride s in 2..32, the modal byte value
    at each phase i%s and what fraction of bytes at that phase equal it
    (a real record table has ONE dominant phase with near-100% agreement on
    some sub-field; code does not)
  * call targets inside the region and whether they resolve against
    symbols/maincpu_v7_symbols_reference.txt
  * up to 32 bytes of context immediately before the start and after the end

RUN
    python3 scripts/analysis/v7_tabletail_adjudicate.py --addr 0xF2BBCF --size 792
    python3 scripts/analysis/v7_tabletail_adjudicate.py --regions-json FILE
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
UNI = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE = 0xE00000
ROM_PATH = os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom")
SYM_PATH = os.path.join(REPO, "symbols", "maincpu_v7_symbols_reference.txt")

DASM = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')
CALL_ABS_RE = re.compile(r'^\s*([0-9a-f]+):\s+(?:[0-9a-f]{2} )+\s*call\s+(?:[A-Z]+,)?0x([0-9a-f]+)\s*$', re.I)
JP_JR_ABS_RE = re.compile(r'^\s*([0-9a-f]+):\s+(?:[0-9a-f]{2} )+\s*jrl?\s+(?:[A-Z]+,)?0x([0-9a-f]+)\s*$', re.I)


def load_symbols():
    syms = {}
    for line in open(SYM_PATH):
        if line.startswith('#') or not line.strip():
            continue
        parts = line.split()
        if len(parts) != 2:
            continue
        name, addr = parts
        try:
            syms[int(addr, 16)] = name
        except ValueError:
            continue
    return syms


def unidasm(blob, basepc, tmp):
    open(tmp, "wb").write(blob)
    out = subprocess.run([UNI, tmp, "-arch", "tlcs900", "-basepc", hex(basepc)],
                          capture_output=True, text=True).stdout
    return [l.strip() for l in out.split("\n") if DASM.match(l.strip())]


def metrics(blob):
    db = 0
    for line in unidasm(blob, 0, tempfile.NamedTemporaryFile(suffix=".bin", delete=False).name):
        m = DASM.match(line)
        if m and m.group(3).strip() == "db":
            db += len(m.group(2).split())
    per = 0.0
    best_p = None
    for p in range(2, 33):
        if len(blob) > p:
            frac = sum(1 for i in range(p, len(blob)) if blob[i] == blob[i - p]) / (len(blob) - p)
            if frac > per:
                per = frac
                best_p = p
    ramp = sum(1 for i in range(1, len(blob)) if blob[i] == (blob[i - 1] + 1) & 0xFF) / max(len(blob) - 1, 1)
    dist = len(set(blob))
    n = len(blob)
    rule_ok = (100.0 * db / n <= 5.0 and 100.0 * per <= 20.0 and 100.0 * ramp <= 12.0
               and dist >= min(60, round(0.35 * n)))
    return dict(db=100.0 * db / n, per=100.0 * per, per_stride=best_p, ramp=100.0 * ramp,
                dist=dist, n=n, rule_ok=rule_ok)


def stride_probe(blob, max_stride=16):
    """For each candidate record stride s, report the phase with the
    strongest single dominant byte value -- the signature of a fixed-width
    DATA record (e.g. every 6th byte is always 0x17)."""
    best = []
    for s in range(2, max_stride + 1):
        if len(blob) < s * 3:
            continue
        for phase in range(s):
            vals = blob[phase::s]
            if len(vals) < 3:
                continue
            from collections import Counter
            c = Counter(vals)
            top_val, top_n = c.most_common(1)[0]
            frac = top_n / len(vals)
            if frac >= 0.6:
                best.append((s, phase, top_val, frac, len(vals)))
    best.sort(key=lambda x: -x[3])
    return best[:6]


def adjudicate(rom, syms, addr, size, tmp, label=""):
    off = addr - BASE
    blob = rom[off:off + size]
    print("=" * 100)
    print(f"REGION {addr:#09x}  {size} B  {label}")
    m_whole = metrics(blob)
    # Match looks_like_a_table_tail()'s EXACT window: off = max(0, end-150) to
    # end, taken from the FULL ROM (not clipped to the region) -- for a region
    # smaller than 150 B this reaches BEFORE the region's own start, into
    # whatever precedes it, which is exactly what the guard actually judged.
    end_off = off + size
    tail_off = max(0, end_off - 150)
    tail = rom[tail_off:end_off]
    m_tail = metrics(tail)
    print(f"  whole-region metrics: db={m_whole['db']:.1f}% per={m_whole['per']:.1f}%"
          f"(stride {m_whole['per_stride']}) ramp={m_whole['ramp']:.1f}% dist={m_whole['dist']}"
          f"/{m_whole['n']}  rule={'CODE-like' if m_whole['rule_ok'] else 'DATA-like'}")
    print(f"  TAIL window (last {len(tail)} B, what the guard judged):"
          f" db={m_tail['db']:.1f}% per={m_tail['per']:.1f}%(stride {m_tail['per_stride']})"
          f" ramp={m_tail['ramp']:.1f}% dist={m_tail['dist']}/{m_tail['n']}"
          f"  rule={'CODE-like (guard would ACCEPT)' if m_tail['rule_ok'] else 'DATA-like (guard REJECTS)'}")
    sp = stride_probe(tail)
    if sp:
        print("  tail-window fixed-stride record probe (stride, phase, dominant byte, fraction, n):")
        for s, ph, v, frac, n in sp:
            print(f"    stride={s:2d} phase={ph:2d} dominant=0x{v:02x} frac={frac:.2f} n={n}")
    else:
        print("  tail-window fixed-stride record probe: no phase >=60% dominant -- no record signature found")

    lines = unidasm(blob, addr, tmp)
    calls, jumps = [], []
    for line in lines:
        cm = CALL_ABS_RE.match(line)
        if cm:
            calls.append(int(cm.group(2), 16))
        jm = JP_JR_ABS_RE.match(line)
        if jm:
            jumps.append(int(jm.group(2), 16))
    print(f"  disassembly: {len(lines)} lines, {len(calls)} absolute calls, {len(jumps)} relative jumps")
    for c in calls:
        tag = syms.get(c, "NOT NAMED")
        inside = " (INSIDE region)" if off <= c - BASE < off + size else ""
        print(f"    call -> {c:#09x}  {tag}{inside}")
    for j in jumps:
        inside = " (inside region)" if off <= j - BASE < off + size else " (OUTSIDE region)"
        print(f"    jump -> {j:#09x}{inside}")
    print("  --- full disassembly ---")
    for l in lines:
        print("   ", l)
    ctx_before = rom[max(0, off - 32):off]
    ctx_after = rom[off + size:off + size + 32]
    print(f"  context before (32B @ {addr-32:#09x}): {ctx_before.hex(' ')}")
    print(f"  context after  (32B @ {addr+size:#09x}): {ctx_after.hex(' ')}")
    return dict(addr=addr, size=size, whole=m_whole, tail=m_tail,
                n_calls=len(calls), n_call_hits=sum(1 for c in calls if c in syms),
                calls=calls)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--addr', type=lambda x: int(x, 16))
    ap.add_argument('--size', type=int)
    ap.add_argument('--regions-json', help='JSON list of {addr,size} (addr as int)')
    a = ap.parse_args()
    rom = open(ROM_PATH, "rb").read()
    syms = load_symbols()
    tmp = tempfile.NamedTemporaryFile(suffix=".bin", delete=False).name
    if a.regions_json:
        regions = json.load(open(a.regions_json))
        for r in regions:
            adjudicate(rom, syms, r['addr'], r['size'], tmp)
    elif a.addr and a.size:
        adjudicate(rom, syms, a.addr, a.size, tmp)
    else:
        sys.exit("need --addr/--size or --regions-json")


if __name__ == '__main__':
    main()
