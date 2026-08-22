#!/usr/bin/env python3
"""WHICH `cp (imm),r` sites block the v7 range converter, and does the cpdm rule
spell every one of them byte-exactly?

QUESTION ANSWERED
  `python3 scripts/converters/convert_reachable_ranges.py --forms` reports the
  printed form `cp (imm),r` (e.g. `cp (0x0d57),A`) among the instructions its
  own spelling layer cannot reproduce -- 8 instances on 2026-08-22 (9 before
  commit ca61032 taught it the sibling `cp r,(imm)` family).  A count is not a
  fix: this script names the SITES.  It re-runs the converter's exact range
  enumeration (call targets from analysis/v7-reachability/v7_call_targets.json,
  decoded with the converter's own decode_range) and, for every `cp (imm),r` it
  meets, asks two questions:

     (a) does the converter's translate()/canonical() produce a candidate whose
         ENCODING equals the ROM bytes?   (today: no -- that is the blockage)
     (b) does the cpdm rule of verify_cp_direct_reg.py?

RUN
  python3 tools/spelling-probes/blocked_cp_direct_reg.py

RESULT 2026-08-22, llvm tlcs900_backend@cb165c5cdc4b
  18 `cp (imm),r` sites inside the converter's reachable v7 ranges
  (16 distinct addresses; 0xF44C79 and 0xF44D9F each fall in two overlapping
  ranges).  The converter's own `--forms` census reports 8 rather than 18
  because it BREAKS at the first unspellable instruction in each range, so it
  counts blocked RANGES, not sites.

  converter spells  0 / 18.
  cpdm rule spells 18 / 18 byte-exactly.

  17 of the 18 are prefix c1 / d1 (16-bit direct) and one is d2 (24-bit,
  0xF9B207 `cp (0x0274e0),DE`).  NONE is c0/d0/e0 -- the encoding class for
  which no spelling exists -- which is the same answer
  code_or_data_cp_direct_reg.py reaches from the other side.
"""
import collections, importlib.util, json, os, re, subprocess, sys

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
os.chdir(REPO)
BASE = 0xE00000
MC = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')

_crr = importlib.util.spec_from_file_location(
    'crr', os.path.join(REPO, 'scripts/converters/convert_reachable_ranges.py'))
crr = importlib.util.module_from_spec(_crr); _crr.loader.exec_module(crr)
cc = crr.cc

_vp = importlib.util.spec_from_file_location(
    'vp', os.path.join(REPO, 'tools/spelling-probes/verify_cp_direct_reg.py'))

# verify_cp_direct_reg.py runs main() at import; re-implement its 12-line rule
# here rather than import it, so this script has no side effects.
GR8 = ['w', 'a', 'b', 'c', 'd', 'e', 'h', 'l']
GPR = ['xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp']
MNEM = {0xC: 'cpdm8', 0xD: 'cpdm16', 0xE: 'cpdm32'}


def spell(b):
    if len(b) < 3 or (b[-1] & 0xF8) != 0xF8:
        return None
    size, width, r = b[0] >> 4, b[0] & 0x0F, b[-1] & 7
    if size not in MNEM or width not in (1, 2) or len(b) != width + 3:
        return None
    addr = int.from_bytes(bytes(b[1:-1]), 'little')
    reg = GR8[r] if size == 0xC else GPR[r]
    return f'{MNEM[size]}{"_24" if width == 2 else ""} (0x{addr:0{width*2}x}), {reg}'


def encode(text):
    p = subprocess.run([MC, '-triple=tlcs900', '--show-encoding'],
                       input=text + '\n', capture_output=True, text=True)
    if p.returncode != 0:
        return None
    m = re.search(r'encoding: \[([^\]]*)\]', p.stdout)
    if not m:
        return None
    try:
        return bytes(int(x, 16) for x in m.group(1).split(','))
    except ValueError:
        return None


TEXT = re.compile(r'^cp \((0x[0-9a-f]+)\),([A-Za-z]+)$')


def main():
    rom = open('original_ROMs/kn5000_v7_program.rom', 'rb').read()
    spec = importlib.util.spec_from_file_location(
        'spans', os.path.join(REPO, 'scripts/analysis/v7_undisassembled_spans.py'))
    spans = importlib.util.module_from_spec(spec); spec.loader.exec_module(spans)
    terr = spans.territory(spans.runs('v7/maincpu/kn5000_v7_program.s', 'v7/maincpu'))
    targets = json.load(open('analysis/v7-reachability/v7_call_targets.json'))['targets']

    hits = []
    for t in sorted(targets):
        insns = crr.decode_range(rom, terr, t)
        if len(insns) < 3:
            continue
        _off, _run = t - BASE, 0
        while _off + _run < len(terr) and terr[_off + _run] == 2:
            _run += 1
        ends_at_code = sum(n for _, n, _ in insns) == _run
        if insns[-1][2].split()[0].lower() not in crr.TERMINATORS and not ends_at_code:
            continue
        pos = 0
        span = sum(n for _, n, _ in insns)
        want = rom[t - BASE: t - BASE + span]
        for a, n, x in insns:
            by = want[pos:pos + n]; pos += n
            if not TEXT.match(x):
                continue
            conv = None
            for cand in list(cc.translate(x)) + [cc.canonical(x)]:
                if encode(cand) == by:
                    conv = cand; break
            mine = spell(by)
            got = encode(mine) if mine else None
            hits.append((a, by, x, conv, mine, got))

    print(f'{len(hits)} `cp (imm),r` sites inside the converter\'s reachable v7 ranges\n')
    conv_ok = sum(1 for h in hits if h[3])
    mine_ok = sum(1 for h in hits if h[5] == h[1])
    for a, by, x, conv, mine, got in hits:
        mark = 'OK ' if got == by else 'BAD'
        print(f'  {a:06x}  {by.hex(" "):14s} {x:22s} converter={conv!r:6s} '
              f'{mark} {mine!r}')
    uniq = {h[0] for h in hits}
    pfx = collections.Counter(f'{h[1][0]:02x}' for h in hits)
    print(f'\nconverter spells {conv_ok} / {len(hits)}; '
          f'cpdm rule spells {mine_ok} / {len(hits)} byte-exactly')
    print(f'{len(uniq)} distinct addresses; prefixes ' +
          ', '.join(f'{k} x{v}' for k, v in sorted(pfx.items())))
    return 0 if mine_ok == len(hits) else 1


sys.exit(main())
