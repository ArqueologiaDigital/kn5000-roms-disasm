#!/usr/bin/env python3
"""Which `inc <n>,<REG>` sites actually BLOCK the v7 range converter, and where?

QUESTION ANSWERED
  scripts/converters/convert_reachable_ranges.py --forms reports a form
  `inc 1,r` among the things it cannot spell.  Its counter records at most ONE
  form per RANGE (it stops at the first unspellable instruction), so that
  number is a count of ranges, not of sites.  This script reports both, and --
  the part that matters for fixing it -- the ADDRESS and RAW BYTES of every
  blocked site, so the spelling rule can be checked against real bytes.

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

  ⚠ This does NOT call convert_reachable_ranges.decode_range: that function
  writes a fixed path, os.path.join(tempfile.gettempdir(), "_range.bin"), so two
  copies running at once silently read each other's bytes.  A first run of this
  census that did reuse it reported sites like 0xF04E98 `inc 1,WA` where the ROM
  holds `1d 09` (a call).  This script decodes into a private mkdtemp().

RUN   python3 tools/spelling-probes/blocking_inc_reg.py     (~10 min)

RESULT 2026-08-22, llvm tlcs900_backend@cb165c5cdc4b (1129 v7 call targets)
  451 distinct `inc n,REG` sites decode inside the v7 reachable ranges.
  410 of them already have a spelling.
   41 have NO spelling today.  ALL 41 are the byte-size extended-register
      form `c7 rb 61`:
          31 x rb=0xfb  (unidasm: QIZH)
           9 x rb=0xfa  (unidasm: QIZL)
           1 x rb=0xea  (unidasm: QE)
      Every one becomes `incb_erp 0x<rb>, 1`, byte-exact -- see verify_inc_reg.py.
  No d7 (word ERP) site is blocked: unidasm's Q-names for that prefix (QIZ, QWA,
  QBC, QHL...) are real backend register names, so the verbatim listing text
  already assembles to the right 3 bytes.  No e7 (long ERP) site with n != 4
  occurs in a reachable range at all.

  Range-level measure (one form per range, the way --forms counts), top nine:
      27  inc 1,r          21  cp r,(imm)       14  lda r,r+r
      13  ld (r+imm),imm   12  ld (r+r),r       11  cp (imm),r
      10  res 0,(imm)       9  push r            9  set 0,(imm)
  `inc 1,r` is the single biggest blocker of v7 range conversion by that measure.
"""
import collections, importlib.util, json, os, re, subprocess, sys, tempfile

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNIDASM = os.path.expanduser('~/compartilhado/tools/unidasm')
BASE = 0xE00000
TERMINATORS = ('ret', 'reti', 'retd')
BRANCHES = ('jr', 'jrl', 'calr')
TMPDIR = tempfile.mkdtemp(prefix='blocking_inc_')
TMP = os.path.join(TMPDIR, 'range.bin')
FORM = re.compile(r'^inc\s+(\d+),([A-Z][A-Z0-9]*)$')


def load(name, rel):
    spec = importlib.util.spec_from_file_location(name, os.path.join(REPO, rel))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def decode_range(rom, terr, start, limit=16384):
    off = start - BASE
    end = off
    while end < len(terr) and terr[end] == 2 and end - off < limit:
        end += 1
    open(TMP, 'wb').write(rom[off:end])
    out = subprocess.run([UNIDASM, TMP, '-arch', 'tlcs900', '-basepc', hex(start)],
                         capture_output=True, text=True, timeout=120).stdout
    insns = []
    for line in out.split('\n'):
        m = re.match(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.+)$', line)
        if not m:
            continue
        addr, raw, text = int(m.group(1), 16), m.group(2).split(), m.group(3).strip()
        if text.split()[0].lower() == 'db':
            break
        insns.append((addr, len(raw), text))
        if text.split()[0].lower() in TERMINATORS:
            break
    return insns


def main():
    os.chdir(REPO)
    cc = load('cc', 'scripts/converters/convert_corroborated_blocks.py')
    spans = load('spans', 'scripts/analysis/v7_undisassembled_spans.py')
    rom = open('original_ROMs/kn5000_v7_program.rom', 'rb').read()
    terr = spans.territory(spans.runs('v7/maincpu/kn5000_v7_program.s', 'v7/maincpu'))
    targets = json.load(open('analysis/v7-reachability/v7_call_targets.json'))['targets']

    sites = {}
    first_blocker = collections.Counter()
    for t in sorted(targets):
        blocked = None
        for (a, n, x) in decode_range(rom, terr, t):
            b = rom[a - BASE:a - BASE + n]
            spelling = None
            for cand in list(cc.translate(x)) + [cc.canonical(x)]:
                if cc.encode(cand) == b:
                    spelling = cand
                    break
            if FORM.match(x):
                sites[a] = (b, x, spelling)
            if spelling is None and blocked is None \
                    and x.split()[0].lower() not in BRANCHES:
                blocked = x
        if blocked is not None:
            rest = blocked.split(None, 1)[1] if ' ' in blocked else ''
            key = blocked.split()[0] + ' ' + re.sub(
                r'0x[0-9a-fA-F]+', 'imm', re.sub(r'\b[A-Z]{1,4}\b', 'r', rest))
            first_blocker[key] += 1

    uns = {a: v for a, v in sites.items() if v[2] is None}
    print(f'distinct `inc n,REG` sites in v7 reachable ranges: {len(sites)}')
    print(f'  spellable today : {len(sites) - len(uns)}')
    print(f'  UNSPELLABLE     : {len(uns)}')
    by_enc = collections.Counter(v[0].hex(' ') for v in uns.values())
    for k, n in by_enc.most_common():
        print(f'      {n:4d}  {k}')
    print('\nranges whose FIRST unspellable NON-BRANCH instruction is that form')
    print('(this is what convert_reachable_ranges.py --forms counts):')
    for k, n in first_blocker.most_common(14):
        print(f'   {n:5d}  {k}')
    print('\nevery unspellable site:')
    for a in sorted(uns):
        b, x, _ = uns[a]
        print(f'  0x{a:06X}  [{b.hex(" ")}]  {x:16s} -> '
              f'incb_erp 0x{b[1]:02x}, {b[-1] & 7}')


if __name__ == '__main__':
    main()
