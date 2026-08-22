#!/usr/bin/env python3
"""Which `ldir` sites BLOCK the v7 range converter, at what addresses, with what bytes?

QUESTION ANSWERED
  scripts/converters/convert_reachable_ranges.py --forms lists `ldir` among the
  forms it cannot spell, 6 instances.  That counter records at most ONE form per
  RANGE (it stops at the first unspellable instruction), so 6 is a count of
  ranges.  This script reports the ranges AND the ADDRESS and RAW BYTES of every
  `ldir` the converter meets, so the spelling can be checked against real bytes
  instead of against the printed text -- which for a block transfer carries no
  operands at all and therefore cannot distinguish the encodings.

  Branches are excluded from the "first blocker" question exactly as the
  converter excludes them: resolve_branches() rewrites jr/jrl/calr targets as
  symbols, so those are never what stops a range.

METHOD
  Same inputs as the converter: the v7 call-target list
  (analysis/v7-reachability/v7_call_targets.json), the .byte territory map
  (scripts/analysis/v7_undisassembled_spans.py), unidasm for the decode and
  convert_corroborated_blocks.translate()/canonical() + llvm-mc for the spelling
  attempt.  A site counts as spellable only if some candidate ASSEMBLES TO THE
  ROM BYTES.

  Decodes into a private mkdtemp(), NOT via convert_reachable_ranges.decode_range,
  which writes a fixed path in the system temp dir and so corrupts a second
  concurrent run.

RUN   python3 tools/spelling-probes/blocking_ldir.py     (~5 min)

RESULT 2026-08-22, llvm tlcs900_backend@cb165c5cdc4b
  10 distinct `ldir` sites decode inside the v7 reachable ranges.
  ALL TEN hold the same two bytes: [85 11].  Not one of them is the [80 11]
  that the printed text `ldir` assembles to.
      0xF26F32 0xF56D2B 0xF57524 0xF576E1 0xF5789E 0xF57A5B
      0xF60792 0xF60798 0xF607B9 0xF67077
  6 ranges have `ldir` as their first unspellable non-branch instruction:
      entry 0xF56D10 -> 0xF56D2B      entry 0xF57505 -> 0xF57524
      entry 0xF576C2 -> 0xF576E1      entry 0xF5787F -> 0xF5789E
      entry 0xF57A3C -> 0xF57A5B      entry 0xF67055 -> 0xF67077
  The spelling for [85 11] ALREADY EXISTS -- `ldir85`, byte-exact.  What is
  missing is not a backend definition but the prefix->mnemonic map inside
  convert_corroborated_blocks.translate(); asl_to_llvm.py already carries it
  (Tier 39, BLOCK_XFER_MAP).  See verify_ldir_blocked_ranges.py.
"""
import collections, importlib.util, json, os, re, subprocess, sys, tempfile

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNIDASM = os.path.expanduser('~/compartilhado/tools/unidasm')
BASE = 0xE00000
TERMINATORS = ('ret', 'reti', 'retd')
BRANCHES = ('jr', 'jrl', 'calr')
TMPDIR = tempfile.mkdtemp(prefix='blocking_ldir_')
TMP = os.path.join(TMPDIR, 'range.bin')
FORM = re.compile(r'^ldir$', re.I)

def load(name, rel):
    spec = importlib.util.spec_from_file_location(name, os.path.join(REPO, rel))
    m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m); return m

def decode_range(rom, terr, start, limit=16384):
    off = start - BASE; end = off
    while end < len(terr) and terr[end] == 2 and end - off < limit:
        end += 1
    open(TMP, 'wb').write(rom[off:end])
    out = subprocess.run([UNIDASM, TMP, '-arch', 'tlcs900', '-basepc', hex(start)],
                         capture_output=True, text=True, timeout=120).stdout
    insns = []
    for line in out.split('\n'):
        m = re.match(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.+)$', line)
        if not m: continue
        addr, raw, text = int(m.group(1), 16), m.group(2).split(), m.group(3).strip()
        if text.split()[0].lower() == 'db': break
        insns.append((addr, len(raw), text))
        if text.split()[0].lower() in TERMINATORS: break
    return insns

def main():
    os.chdir(REPO)
    cc = load('cc', 'scripts/converters/convert_corroborated_blocks.py')
    spans = load('spans', 'scripts/analysis/v7_undisassembled_spans.py')
    rom = open('original_ROMs/kn5000_v7_program.rom', 'rb').read()
    terr = spans.territory(spans.runs('v7/maincpu/kn5000_v7_program.s', 'v7/maincpu'))
    targets = json.load(open('analysis/v7-reachability/v7_call_targets.json'))['targets']

    sites = {}; blockers = []
    for t in sorted(targets):
        blocked = None
        for (a, n, x) in decode_range(rom, terr, t):
            b = rom[a - BASE:a - BASE + n]
            spelling = None
            for cand in list(cc.translate(x)) + [cc.canonical(x)]:
                if cc.encode(cand) == b: spelling = cand; break
            if FORM.match(x): sites[a] = (b, x, spelling)
            if spelling is None and blocked is None and x.split()[0].lower() not in BRANCHES:
                blocked = (a, b, x, t)
        if blocked is not None and FORM.match(blocked[2]):
            blockers.append(blocked)

    print(f'distinct `ldir` sites in v7 reachable ranges: {len(sites)}')
    for a in sorted(sites):
        b, x, sp = sites[a]
        print(f'  0x{a:06X}  [{b.hex(" ")}]  {x:8s} -> {sp!r}')
    print(f'\nRANGES whose first unspellable non-branch insn is `ldir`: {len(blockers)}')
    for a, b, x, t in sorted(blockers):
        print(f'  entry 0x{t:06X}  blocked at 0x{a:06X}  [{b.hex(" ")}]')
    json.dump({'sites': {f'0x{a:06X}': [sites[a][0].hex(' '), sites[a][2]] for a in sorted(sites)},
               'blockers': [[f'0x{t:06X}', f'0x{a:06X}', b.hex(' ')] for a,b,x,t in sorted(blockers)]},
              open(os.path.join(TMPDIR,'out.json'),'w'), indent=1)
    print('json ->', os.path.join(TMPDIR,'out.json'))

main()
