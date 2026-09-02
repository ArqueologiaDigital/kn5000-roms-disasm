#!/usr/bin/env python3
"""v7_judged_call_corroboration.py -- do v7's rule-fired code-as-.byte regions
actually BEHAVE like code, independent of the judge rule and the byte gate?

QUESTION ANSWERED
  v9_v10_undisassembled_census.py --judge v7 (run 2026-09-02, this session) flags
  797 non-.incbin DATA regions >= 64 B, 247,603 B, as CODE-shaped. Its own
  --calibrate run on v7 found the DATA control (.incbin interiors) firing at
  15.7% / 11.7% byte-weighted -- far noisier than v9's 1.0% / 0.2% -- so the
  rule alone is a weaker instrument on v7 than it was on v9/v10, and the
  247,603 B figure needs the same external corroboration the v10/v9 lane used
  for its conversions: do the region's `call` targets land on routines already
  named in the tree BEFORE this session touched anything?

METHOD
  For every one of the 797 hit regions, disassemble the ORIGINAL v7 ROM bytes
  (unmodified -- this is a read-only probe, nothing is converted here) with
  unidasm, collect every absolute `call NN` target it prints, and look each one
  up in symbols/maincpu_v7_symbols_reference.txt (generated from the CURRENT,
  unmodified v7 ELF -- i.e. entirely prior evidence, not anything this session
  named). `calr` (PC-relative) targets are excluded, same reasoning as
  verify_converted_call_targets.py: this script does not track instruction
  addresses precisely enough to resolve a relative displacement.

RUN:
    python3 scripts/analysis/v7_judged_call_corroboration.py --work <scratch dir from --prepare>
"""
import argparse, importlib.util, os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
UNI = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE = 0xE00000

CALL_ABS_RE = re.compile(r'^\s*([0-9a-f]+):\s+(?:[0-9a-f]{2} )+\s*call\s+(?:[A-Z]+,)?0x([0-9a-f]+)\s*$', re.I)
DASM = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')


def load_symbols():
    path = os.path.join(REPO, 'symbols', 'maincpu_v7_symbols_reference.txt')
    syms = {}
    for line in open(path):
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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    a = ap.parse_args()

    spec = importlib.util.spec_from_file_location(
        'census', os.path.join(HERE, 'v9_v10_undisassembled_census.py'))
    census = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(census)

    terr, blobs, regs, rom = census.load('v7', a.work)
    tmp = tempfile.NamedTemporaryFile(suffix='.bin', delete=False).name

    hit = []
    for r in regs:
        if r['size'] < 64:
            continue
        met = census.metrics(rom, r['start'], r['size'], tmp)
        if census.rule(met):
            hit.append(r)

    syms = load_symbols()
    targets, region_with_call, region_all_hit = set(), 0, 0
    per_region_hits = []
    for r in hit:
        open(tmp, 'wb').write(rom[r['start']:r['end']])
        out = subprocess.run([UNI, tmp, '-arch', 'tlcs900', '-basepc', hex(BASE + r['start'])],
                             capture_output=True, text=True).stdout
        found_here = set()
        for line in out.split('\n'):
            m = CALL_ABS_RE.match(line.strip())
            if m:
                found_here.add(int(m.group(2), 16))
        if found_here:
            region_with_call += 1
            targets |= found_here
            hits_here = sum(1 for t in found_here if t in syms)
            per_region_hits.append((r, len(found_here), hits_here))

    hit_syms = sorted(t for t in targets if t in syms)
    miss_syms = sorted(t for t in targets if t not in syms)
    print(f"{len(hit)} rule-fired regions, {sum(r['size'] for r in hit):,} B total")
    print(f"{region_with_call}/{len(hit)} regions contain at least one absolute `call`")
    print(f"{len(targets)} distinct absolute call targets across all hit regions")
    print(f"  {len(hit_syms)} land on a symbol ALREADY in "
          f"symbols/maincpu_v7_symbols_reference.txt (pre-existing, not named by this session)")
    print(f"  {len(miss_syms)} land on no pre-existing symbol")
    print(f"  => {100.0*len(hit_syms)/max(len(targets),1):.0f}% of distinct call targets "
          f"resolve to an already-named routine")
    print()
    print("Sample of HIT targets (address -> pre-existing name):")
    for t in hit_syms[:25]:
        print(f"  {BASE+0:#0x}".rjust(0) + f"  0x{t:06x}  {syms[t]}")
    print()
    print("Sample of MISS targets (no pre-existing symbol):")
    for t in miss_syms[:25]:
        print(f"  0x{t:06x}")
    print()
    # Regions with the highest per-region call/named-hit ratio: the strongest single
    # pieces of corroborating evidence, since it means everything that region CALLS
    # was already known before this session looked at it.
    per_region_hits.sort(key=lambda x: (-x[2], -x[1]))
    print("Strongest single-region corroboration (most named-symbol call hits):")
    for r, n, h in per_region_hits[:15]:
        print(f"  0x{BASE+r['start']:06x}  {r['size']:>6,} B  {h}/{n} calls hit  "
              f"[{r['src']['file']}:{r['src']['line']}]")


if __name__ == '__main__':
    main()
