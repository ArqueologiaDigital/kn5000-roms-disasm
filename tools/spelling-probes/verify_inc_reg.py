#!/usr/bin/env python3
"""FULL verification of the llvm-mc spelling rule for the unidasm printed form
`inc <n>,<REG>` -- increment a REGISTER by a small constant -- in the KN5000
maincpu ROMs (v7, v9, v10) and in the table-data ROM.

QUESTION ANSWERED
  One printed text, `inc 1,WA`, is TWO different TLCS-900 encodings:
  the 2-byte short register form `d8 61`, and the 3-byte extended-register
  form `d7 e0 61`.  Same for `inc 1,W` (c8 61 / c7 e1 61) and `inc 1,XWA`
  (e8 61 / e7 e0 61).  unidasm prints them identically.  Which llvm-mc
  mnemonic reproduces each of them BYTE-EXACTLY, keyed on the RAW BYTES --
  which is all a .byte-blob converter has?

RULE UNDER TEST -- keyed on the RAW BYTES, never on the printed text.
  n = (last byte) & 7.  unidasm prints that value LITERALLY, so `inc 0,XSP`
  is `ef 60` and llvm-mc's `inc 0, xsp` is also `ef 60`.  (The .td comment
  claims 0x60+(n-1); the ENCODER does 0x60+(n&7).  Trust the bytes.)

  c8+r  60+n     (2B)  ->  inc <n>, GR8[r]      GR8  = w a b c d e h l
  d8+r  60+n     (2B)  ->  inc <n>, GR16[r]     GR16 = wa bc de hl ix iy iz
                           r == 7 (SP, `df 6n`) -> NO SPELLING (GR16 excludes SP)
  e8+r  60+n     (2B)  ->  inc <n>, GPR[r]      GPR  = xwa xbc xde xhl xix xiy xiz xsp
  c7 rb 60+n     (3B)  ->  incb_erp 0x<rb>, <n>          (every rb, every n)
  d7 rb 61       (3B)  ->  inc1w_erp 0x<rb>
  d7 rb 64       (3B)  ->  inc4w_erp 0x<rb>
  d7 rb 60+n     (3B)  ->  inc <n>, QMAP[rb]  when rb names a previous-bank
                           word register (QWA..QSP, rb in e2 e6 ea ee f2 f6 fa fe);
                           otherwise NO SPELLING for n not in {1,4}
  e7 rb 64       (3B)  ->  inc4_lerp 0x<rb>
  e7 rb 60+n     (3B)  ->  NO SPELLING for n != 4

  `rb` is the RAW extended-register byte and is passed through as a plain
  immediate -- exactly like the other _erp/_erpb families in this tree.
  There is no need to decode it into a register NAME, and no way to do so
  reliably: unidasm renders 0xFB as QIZH under the c7 prefix, as QIZ under
  d7 (where 0xFA is QIZ) and as a bank register (RC3, XBC3) for rb < 0xE0.

  For the byte prefix c7 the alternative `inc1b_erp 0x<rb>` is the SAME bytes
  when n == 1; `incb_erp` is preferred because it also covers n != 1.
  Both already appear in the byte-exact v9 sources (76 inc1b_erp, 1 incb_erp).

WHY THE TEXT IS NOT ENOUGH
  `--ambiguous` counts the sweep sites whose printed text is produced by more
  than one encoding.  A converter that re-spells from unidasm TEXT would have
  to guess between a 2-byte and a 3-byte instruction at those sites.

PASS = llvm-mc --show-encoding output == the ROM bytes at that address.
"Assembled without error" is NOT a pass.

RUN
  python3 tools/spelling-probes/verify_inc_reg.py              # sweep + exhaustive
  python3 tools/spelling-probes/verify_inc_reg.py --negative   # can the check fail?
  python3 tools/spelling-probes/verify_inc_reg.py --dangerous  # assembles, wrong bytes
  python3 tools/spelling-probes/verify_inc_reg.py --ambiguous  # text-only is impossible

RESULT 2026-08-22 (llvm tlcs900_backend@cb165c5cdc4b)
  EXHAUSTIVE over the whole encoding space -- every prefix x every rb x every n,
  6336 encodings, generated from the SPACE and not from this firmware:
      c8+r 6n   (2B)     64 byte-exact       0 no form
      d8+r 6n   (2B)     56 byte-exact       8 no form   (`df 6n` = SP)
      e8+r 6n   (2B)     64 byte-exact       0 no form
      c7 rb 6n  (3B)   2048 byte-exact       0 no form
      d7 rb 6n  (3B)    560 byte-exact    1488 no form   (n not in {1,4},
                                                     rb not a Q register)
      e7 rb 6n  (3B)    256 byte-exact    1792 no form   (n != 4)
      TOTAL            3048 byte-exact    3288 no form   0 WRONG
  ROM SWEEP (unidasm linear scan, every `inc n,REG` site):
      v7     6326 /  6326 byte-exact    7 no form   0 failures
      v9     6743 /  6743 byte-exact    5 no form   0 failures
      v10    6743 /  6743 byte-exact    5 no form   0 failures
      table   548 /   548 byte-exact   26 no form   0 failures
      GRAND TOTAL 20360 / 20360 spellable sites, 0 failures (20403 sites seen).
      By encoding class: e8+r 10354, d8+r 6179, c8+r 2601, c7 rb 61 957,
      d7 rb 61 228, d7 rb 64 10, c7 rb 60 9, e7 rb 64 9, c7 rb 64 6,
      c7 rb 62 5, c7 rb 63 2.
      The 43 no-form sites are 30 x `df 6n` (SP), 9 x `e7 rb 6n` with n != 4
      and 4 x `d7 rb 66`.  None of them is in a reachable code range; the
      four ROMs disagree about their count, which is what a linear sweep
      running through DATA looks like.
  --negative (count taken as n-1, i.e. believing the .td COMMENT):
      247 / 20360 byte-exact, 20113 FAILURES.  The 247 survivors are exactly
      the d7/e7 forms whose count is baked into the mnemonic (inc1w_erp,
      inc4w_erp, inc4_lerp), where the off-by-one cannot even be written.
  --ambiguous: 19184 / 20403 sweep sites (94.0%) print a text that a SECOND
      encoding also prints -- 352 such texts exist in the space.  Re-spelling
      from the listing text is impossible; the rule must read the raw bytes.

WHAT THIS UNBLOCKS
  41 distinct sites inside the v7 reachable ranges decode to `inc 1,<REG>` and
  had no spelling before this probe.  Every one is `c7 rb 61` -- 31 x rb=0xfb
  (QIZH), 9 x rb=0xfa (QIZL), 1 x rb=0xea (QE) -- and every one is now
  `incb_erp 0x<rb>, 1`.  See blocking_inc_reg.py for that census.
  The spelling is not new to the tree: the byte-exact v9 sources already carry
  76 `inc1b_erp`, 36 `inc1w_erp`, 1 `incb_erp`, 1 `inc4w_erp`, 1 `inc4_lerp`.
  What was missing is the converter's unidasm-text -> mnemonic mapping; the
  comment in scripts/converters/convert_corroborated_blocks.py saying
  "`ld`/`inc` have no _erpb equivalent found yet" is false for `inc`.
"""
import collections, os, re, subprocess, sys

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNI  = os.path.expanduser('~/compartilhado/tools/unidasm')
MC   = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')

ROMS = [('kn5000_v7_program.rom',  0xE00000),
        ('kn5000_v9_program.rom',  0xE00000),
        ('kn5000_v10_program.rom', 0xE00000),
        ('kn5000_table_data.rom',  0x200000)]

GR8  = ['w', 'a', 'b', 'c', 'd', 'e', 'h', 'l']
GR16 = ['wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', None]   # None = SP: no form
GPR  = ['xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp']
# The eight extended-register bytes under the d7 (word) prefix that name a
# PREVIOUS-BANK register the backend knows by name.  There is no such table for
# c7 (`inc 1, qizh` is rejected) and none for e7 (no PrevGR32 class exists).
QMAP = {0xE2: 'qwa', 0xE6: 'qbc', 0xEA: 'qde', 0xEE: 'qhl',
        0xF2: 'qix', 0xF6: 'qiy', 0xFA: 'qiz', 0xFE: 'qsp'}

LINE = re.compile(r'^([0-9a-f]+): ([0-9a-f]{2}(?: [0-9a-f]{2})*)\s{2,}(.*)$')
TEXT = re.compile(r'^inc (\d),([A-Z][A-Z0-9]*)$')


def spell(b):
    """The rule. Spelling as a function of the RAW BYTES; None = no form."""
    if len(b) not in (2, 3) or (b[-1] & 0xF8) != 0x60:
        return None
    n = b[-1] & 7
    if len(b) == 2:
        p, r = b[0], b[0] & 7
        tab = {0xC8: GR8, 0xD8: GR16, 0xE8: GPR}.get(p & 0xF8)
        if tab is None or (p & 0xF8) not in (0xC8, 0xD8, 0xE8):
            return None
        return None if tab[r] is None else f'inc {n}, {tab[r]}'
    rb = b[1]
    if b[0] == 0xC7:
        return f'incb_erp 0x{rb:02x}, {n}'
    if b[0] == 0xD7:
        if n == 1:
            return f'inc1w_erp 0x{rb:02x}'
        if n == 4:
            return f'inc4w_erp 0x{rb:02x}'
        # No incNw_erp for the other counts -- but the eight PREVIOUS-BANK word
        # registers do have real backend names (PrevGR16 = QWA..QSP), and the
        # plain `inc n, q<reg>` form takes any count.  That covers exactly the
        # eight rb values below and nothing else.
        return f'inc {n}, {QMAP[rb]}' if rb in QMAP else None
    if b[0] == 0xE7:
        return f'inc4_lerp 0x{rb:02x}' if n == 4 else None
    return None


def spell_wrong(b):
    """NEGATIVE CONTROL: take the count as the .td COMMENT describes it.

    TLCS900InstrInfo.td says INC32's encoding is `E8+rd, 0x60+(n-1)`, i.e. the
    operand is 1..8 and gets a -1 applied.  The ENCODER does no such thing; it
    emits 0x60+(n&7).  A converter that believed the comment and wrote n+1 to
    compensate is off by one at EVERY site.  Everything it emits assembles."""
    t = spell(b)
    if t is None:
        return None
    m = re.match(r'^inc (\d), (\w+)$', t)
    if m:
        return f'inc {int(m.group(1)) + 1}, {m.group(2)}'
    m = re.match(r'^incb_erp (0x[0-9a-f]{2}), (\d)$', t)
    if m:
        return f'incb_erp {m.group(1)}, {int(m.group(2)) + 1}'
    return t          # inc1w_erp / inc4w_erp / inc4_lerp carry the count in the
                      # mnemonic and cannot express the off-by-one


def assemble(texts):
    """One llvm-mc run for the whole batch; returns {text: bytes or None}."""
    if not texts:
        return {}
    src = '\n'.join(texts) + '\n'
    p = subprocess.run([MC, '-triple=tlcs900', '--show-encoding'],
                       input=src, capture_output=True, text=True)
    encs = re.findall(r'encoding: \[([^\]]*)\]', p.stdout)
    if len(encs) != len(texts):
        sys.exit(f'llvm-mc returned {len(encs)} encodings for {len(texts)} lines\n'
                 + p.stderr[:2000])
    out = {}
    for t, e in zip(texts, encs):
        try:
            out[t] = bytes(int(x, 16) for x in e.split(','))
        except ValueError:
            out[t] = None
    return out


def all_encodings():
    """Every byte sequence the rule is supposed to cover, generated from the
    ENCODING SPACE rather than from the ROM, so coverage does not depend on
    what this particular firmware happens to contain."""
    out = []
    for p in list(range(0xC8, 0xD0)) + list(range(0xD8, 0xE0)) + list(range(0xE8, 0xF0)):
        for n in range(8):
            out.append(bytes([p, 0x60 + n]))
    for p in (0xC7, 0xD7, 0xE7):
        for rb in range(256):
            for n in range(8):
                out.append(bytes([p, rb, 0x60 + n]))
    return out


def klass(b):
    if len(b) == 2:
        return f'{b[0] & 0xF8:02x}+r 6n  (2B)'
    return f'{b[0]:02x} rb 6{b[-1] & 7}  (3B)'


def exhaustive():
    print('EXHAUSTIVE: every encoding in the register-INC space, spelled by the '
          'rule\nand assembled.  A spelling whose bytes differ is a FAILURE; '
          '"no form" is\ncounted separately.\n')
    seqs = all_encodings()
    texts = sorted({t for b in seqs if (t := spell(b))})
    enc = assemble(texts)
    ok, bad, none_ = collections.Counter(), [], collections.Counter()
    for b in seqs:
        t = spell(b)
        k = (f'{b[0] & 0xF8:02x}+r  2B' if len(b) == 2 else f'{b[0]:02x} rb 6n  3B')
        if t is None:
            none_[k] += 1
            continue
        if enc.get(t) == b:
            ok[k] += 1
        else:
            bad.append((b, t, enc.get(t)))
    for k in sorted(set(ok) | set(none_)):
        print(f'  {k:16s} {ok[k]:5d} byte-exact   {none_[k]:5d} no form')
    print(f'  {"TOTAL":16s} {sum(ok.values()):5d} byte-exact   '
          f'{sum(none_.values()):5d} no form   {len(bad):d} WRONG')
    for b, t, g in bad[:20]:
        print(f'    WRONG {b.hex(" ")} -> {t!r} gave {g.hex(" ") if g else None}')
    return len(bad)


def sites_of(rom_path, base):
    rom = open(rom_path, 'rb').read()
    dis = subprocess.run([UNI, rom_path, '-arch', 'tlcs900', '-basepc', hex(base)],
                         capture_output=True, text=True).stdout
    out = []
    for line in dis.split('\n'):
        m = LINE.match(line)
        if not m or not TEXT.match(m.group(3)):
            continue
        addr = int(m.group(1), 16)
        by = bytes(int(x, 16) for x in m.group(2).split())
        assert rom[addr - base:addr - base + len(by)] == by, hex(addr)
        out.append((addr, by, m.group(3)))
    return out


def ambiguous():
    """How many sweep sites print a text that ANOTHER encoding also prints?

    Built from unidasm itself: assemble every encoding in the space into one
    blob, disassemble it, and collect text -> {encodings}.  Any text with more
    than one encoding cannot be re-spelled from the printed text alone."""
    import tempfile
    seqs = all_encodings()
    blob = b''.join(seqs)
    tmp = os.path.join(tempfile.mkdtemp(prefix='incamb_'), 'space.bin')
    open(tmp, 'wb').write(blob)
    dis = subprocess.run([UNI, tmp, '-arch', 'tlcs900', '-basepc', '0'],
                         capture_output=True, text=True).stdout
    # decode positionally: our blob is a concatenation of known-length insns
    text_of, off = {}, 0
    pos = {}
    for line in dis.split('\n'):
        m = LINE.match(line)
        if m:
            pos[int(m.group(1), 16)] = (m.group(2), m.group(3))
    for b in seqs:
        if off in pos and len(pos[off][0].split()) == len(b):
            text_of.setdefault(pos[off][1], set()).add(b)
        off += len(b)
    multi = {t: v for t, v in text_of.items() if len(v) > 1}
    print(f'printed texts produced by MORE THAN ONE encoding: {len(multi)}')
    for t in sorted(multi)[:12]:
        print(f'   {t:16s} <- ' + ' | '.join(sorted(x.hex(" ") for x in multi[t])))
    tot = amb = 0
    for rom_name, base in ROMS:
        for _a, by, txt in sites_of(os.path.join(REPO, 'original_ROMs', rom_name), base):
            tot += 1
            amb += txt in multi
        print(f'  {rom_name:26s} running totals: {amb} ambiguous / {tot} sites')
    print(f'\n{amb} / {tot} sweep sites print an AMBIGUOUS text '
          f'({100.0 * amb / tot:.1f}%).  Re-spelling from the\nlisting TEXT is '
          f'therefore impossible; the rule must read the raw bytes.')


DANGEROUS = [
    ('inc 9, xwa',        'e8 61 -- imm3 SILENTLY WRAPS: 9&7 = 1, so this is `inc 1`'),
    ('inc 8, xwa',        'e8 60 -- correct only because unidasm prints that as `inc 0`'),
    ('incb_erp 0xfb, 9',  'c7 fb 61 -- same silent imm3 wrap on the ERP form'),
    ('incb_erp 1, 0xfb',  'c7 01 63 -- OPERANDS SWAPPED and it still assembles: '
                          'bank 0x01, count 3'),
    ('inc 2, qiz',        'd7 fa 62 -- 3 bytes.  The Q-names DO assemble, so a '
                          'converter that trusts unidasm text gets the right bytes '
                          'here but NOT for QIZH/QIZL (rejected) or for `inc 1,WA` '
                          '(2-byte d8 61 vs 3-byte d7 e0 61)'),
    ('inc 1, qizh',       'REJECTED: no Q byte-register class exists; c7 fb 61 '
                          'MUST be spelled incb_erp'),
    ('inc 1, ra0',        'REJECTED: bank register names do not exist in the backend'),
    ('inc 1, xwa0',       'REJECTED: ditto'),
    ('inc 1, sp',         'REJECTED: GR16 excludes SP, so `df 61` has no spelling'),
    ('inc1b_erp 0xfb',    'c7 fb 61 -- CORRECT for n==1 only; there is no '
                          'inc<N>b_erp for other counts, use incb_erp'),
    ('inc4w_erp 0xfa',    'd7 fa 64 -- wrong bytes if the site is d7 fa 61'),
    ('incb_erp 0xfa, 1',  'c7 fa 61 -- WRONG PREFIX for a d7 site: the byte-size '
                          'ERP form assembles happily where the word-size one was '
                          'meant'),
]


def dangerous():
    print('Spellings that ASSEMBLE (or are rejected) but do NOT give the '
          'expected bytes.\nEach line assembled live:\n')
    for text, note in DANGEROUS:
        p = subprocess.run([MC, '-triple=tlcs900', '--show-encoding'],
                           input=text + '\n', capture_output=True, text=True)
        m = re.search(r'encoding: \[([^\]]*)\]', p.stdout)
        got = m.group(1).replace('0x', '').replace(',', ' ') if m else '-'
        if p.returncode != 0:
            got = 'rejected'
        print(f'  {text:22s} -> {got:14s} {note}')


def main():
    if '--dangerous' in sys.argv:
        return dangerous()
    if '--ambiguous' in sys.argv:
        return ambiguous()
    rule = spell_wrong if '--negative' in sys.argv else spell
    if rule is spell_wrong:
        print('NEGATIVE CONTROL: count taken as the .td COMMENT describes it '
              '(0x60+(n-1)),\nso the rule writes n+1.  EVERY site should fail.\n')
    else:
        if exhaustive():
            sys.exit('EXHAUSTIVE FAILED')
        print()
    grand = collections.Counter()
    gbad = 0
    for rom_name, base in ROMS:
        sites = sites_of(os.path.join(REPO, 'original_ROMs', rom_name), base)
        texts = sorted({t for _a, b, _x in sites if (t := rule(b))})
        enc = assemble(texts)
        ok, bad, none_ = collections.Counter(), [], collections.Counter()
        for addr, by, _txt in sites:
            t = rule(by)
            k = klass(by)
            if t is None:
                none_[k] += 1
                continue
            if enc.get(t) == by:
                ok[k] += 1
                grand[k] += 1
            else:
                bad.append((addr, by, t, enc.get(t)))
        gbad += len(bad)
        print(f'{rom_name:26s} {sum(ok.values()):5d} / '
              f'{sum(ok.values()) + len(bad):5d} byte-exact   '
              f'{sum(none_.values()):4d} no form   {len(bad):4d} FAILURES')
        for k in sorted(none_):
            print(f'      no form: {k}  x{none_[k]}')
        for addr, by, t, got in bad[:10]:
            print(f'      FAIL 0x{addr:06X} {by.hex(" "):10s} {t!r} -> '
                  f'{got.hex(" ") if got else None}')
    print(f'\nGRAND TOTAL byte-exact {sum(grand.values())}, failures {gbad}')
    for k in sorted(grand):
        print(f'   {k:18s} {grand[k]}')


if __name__ == '__main__':
    main()
