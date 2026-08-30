#!/usr/bin/env python3
"""Round-3 checks for prom_a: every number this round's headers quote.

Run:  python3 notes/prom_a_round3_checks.py            (all sections)
      python3 notes/prom_a_round3_checks.py --selftest (negative controls)

WHAT QUESTION EACH SECTION ANSWERS
  KitCategoryLegends  -- round-2 audit F2.  Where does index 0 really start,
                         how many whole entries fit before the next base, is
                         there any 130 boundary in the table's own bytes, and
                         where does the residue run end?
  TickLabels          -- round-2 audit F3.  Which entries carry glyphs instead
                         of digits, do 1/2/3/4/6 carry digits, and what is the
                         highest LABELLED entry (the last-entry test)?
  OctaveNames         -- round-2 audit F10.  Twelve rows; which octave does
                         MIDI note 127 land in when C-2 is note 0?
  LegendDuplicates    -- the three switch bases appear as immediates; the three
                         SECOND copies appear zero times, in all four images.
  SWI7Table           -- round-2 audit F10.  All 34 live slots resolve to a
                         SYMBOL in the source, none is a bare `.long 0x00...`.

Every value is read from original_ROMs/ or from the gate-verified source text;
nothing is typed from a note.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
ROMS = {
    'prom_a': (os.path.join(ROOT, 'original_ROMs', 'wsa1_prom_a.ic12'), 0xF80000),
    'prom_b': (os.path.join(ROOT, 'original_ROMs', 'wsa1_prom_b.ic13'), 0xF00000),
    'prom_c': (os.path.join(ROOT, 'original_ROMs', 'wsa1_prom_c.ic28'), 0xF80000),
    'prom_d': (os.path.join(ROOT, 'original_ROMs', 'wsa1_prom_d.bin'),  0xF00000),
}
SRC_A = image_path(ROOT, "prom_a/wsa1_prom_a.s")

A = open(ROMS['prom_a'][0], 'rb').read()
def rd(addr, n):
    return A[addr - 0xF80000: addr - 0xF80000 + n]

OK = FAIL = 0
def check(label, got, want):
    global OK, FAIL
    if got == want:
        OK += 1
        print('  ok    %-58s %r' % (label, got))
    else:
        FAIL += 1
        print('  FAIL  %-58s got %r want %r' % (label, got, want))

# --------------------------------------------------------------- F2 ---------
def kit_category_legends():
    print('KitCategoryLegends (0xFF0485, stride 6) -- round-2 audit F2')
    BASE   = 0xFF0485          # KitCategoryLegend_SelectBase 0xFF0424, type 0x20
    DFLT   = 0xFF047F          # the six-space arm at 0xFF041E
    NEXT   = 0xFF079D          # the "user1 " arm at 0xFF042A
    END    = 0xFF07C5          # first byte of sub_FF07C5
    check('index 0 is "STANDR"', rd(BASE, 6), b'STANDR')
    check('the default arm 0xFF047F is six spaces', rd(DFLT, 6), b'      ')
    check('0xFF047F is exactly one entry below index 0', BASE - DFLT, 6)
    check('130 entries from the INDEX base end at', hex(BASE + 130 * 6), '0xff0791')
    check('130 entries from the DEFAULT base end at (the old, wrong figure)',
          hex(DFLT + 130 * 6), '0xff078b')
    check('whole entries that fit before 0xFF079D', (NEXT - BASE) // 6, 132)
    check('...with remainder', (NEXT - BASE) % 6, 0)
    labelled = [i for i in range(132) if rd(BASE + 6 * i, 6) != b'      ']
    check('highest LABELLED entry', max(labelled), 120)
    check('its address', hex(BASE + 6 * 120), '0xff0755')
    check('its text', rd(BASE + 6 * 120, 6), b'SE    ')
    check('entries 121..131 are all blank',
          all(rd(BASE + 6 * i, 6) == b'      ' for i in range(121, 132)), True)
    check('so the table shows NO 130 boundary of its own',
          rd(BASE + 6 * 129, 6) == rd(BASE + 6 * 130, 6) == b'      ', True)
    check('residue 0xFF0791..0xFF07C4 is N bytes', END - 0xFF0791, 52)
    check('0xFF07C5 is code, not table (first bytes of sub_FF07C5)',
          rd(END, 5).hex(), 'f1402500 02'.replace(' ', ''))
    # the three switch bases and their duplicates
    for base, text in ((0xFF079D, b'user1 '), (0xFF07AB, b'user2 '), (0xFF07B9, b'ext   ')):
        check('switch base %06X' % base, rd(base, 6), text)
    check('stride between switch bases', 0xFF07AB - 0xFF079D, 0xFF07B9 - 0xFF07AB)
    check('...which is', 0xFF07AB - 0xFF079D, 14)
    check('base 1 block is the legend twice', rd(0xFF079D, 14), b'user1  user1  ')
    check('base 2 block is the legend twice', rd(0xFF07AB, 14), b'user2  user2  ')
    check('base 3 block is 12 bytes, not 14 (it hits sub_FF07C5)',
          rd(0xFF07B9, 12), b'ext   ext   ')

# --------------------------------------------------------------- F3 ---------
def tick_labels():
    print('TickLabels (0xFF0D65, stride 2) -- round-2 audit F3')
    T = 0xFF0D65
    N = (0xFF0E2B - T) // 2
    check('extent in cells', N, 99)
    glyph = [i for i in range(N) if rd(T + 2 * i, 2)[0] < 0x20]
    check('cells carrying a sub-0x20 glyph pair', glyph, [8, 12, 16, 24, 32, 48, 96])
    divisors = [k for k in range(1, 97) if 96 % k == 0]
    check('the divisors of 96', divisors, [1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 96])
    check('"exactly the divisors of 96" -- is it true?', glyph == divisors, False)
    check('the five missing divisors', [k for k in divisors if k not in glyph], [1, 2, 3, 4, 6])
    check('and every one of those five carries DIGITS',
          [rd(T + 2 * k, 2).decode('latin1') for k in (1, 2, 3, 4, 6)],
          [' 1', ' 2', ' 3', ' 4', ' 6'])
    check('so the rule is "divisors of 96 that are >= 8"',
          sorted(k for k in divisors if k >= 8), glyph)
    # LAST-ENTRY TEST
    check('cell 97 (0xFF0E27)', rd(T + 2 * 97, 2), b'  ')
    check('cell 98 (0xFF0E29), the LAST', rd(T + 2 * 98, 2), b'  ')
    labelled = [i for i in range(N) if rd(T + 2 * i, 2) != b'  ']
    check('highest LABELLED cell', max(labelled), 96)
    check('cell 96 is the whole-beat glyph', rd(T + 2 * 96, 2).hex(), '1520')

# -------------------------------------------------------------- F10b --------
def octave_names():
    print('OctaveNames (0xFF0B22, stride 2) -- round-2 audit F10')
    O = 0xFF0B22
    rows = [rd(O + 2 * i, 2).decode('latin1') for i in range(12)]
    check('twelve rows', rows, ['-2', '-1', '0 ', '1 ', '2 ', '3 ',
                                '4 ', '5 ', '6 ', '7 ', '8 ', '9 '])
    check('last row', rows[-1], '9 ')
    # with C-2 = note 0, octave(n) = n//12 - 2
    check('octave of MIDI note 127', 127 // 12 - 2, 8)
    check('octave of MIDI note 0', 0 // 12 - 2, -2)
    check('distinct octaves a 128-note range touches', len({n // 12 - 2 for n in range(128)}), 11)
    check('so the "9 " row is reachable from a note number?',
          9 in {n // 12 - 2 for n in range(128)}, False)

# ------------------------------------------------- legend duplicates --------
def legend_duplicates():
    print('The three second copies are never addressed -- all four images')
    def imm_hits(addr):
        hits = {}
        for name, (path, _base) in ROMS.items():
            d = open(path, 'rb').read()
            n24 = sum(1 for i in range(len(d) - 3) if d[i:i + 3] == addr.to_bytes(3, 'little'))
            n32 = sum(1 for i in range(len(d) - 4) if d[i:i + 4] == addr.to_bytes(4, 'little'))
            hits[name] = (n24, n32)
        return hits
    for addr, want24 in ((0xFF079D, 1), (0xFF07AB, 1), (0xFF07B9, 1),
                         (0xFF07A4, 0), (0xFF07B2, 0), (0xFF07BF, 0)):
        h = imm_hits(addr)
        tot24 = sum(v[0] for v in h.values())
        check('%06X  24-bit LE immediate hits, all images' % addr, tot24, want24)
    # and the ones that do appear are the operands of the switch's `ld XIY`.
    # ⚠ CITE THE INSTRUCTION, NOT THE OPERAND: the immediate sits one byte into
    # the instruction, and citing 0xFF042B instead of 0xFF042A is the off-by-one
    # that notes/prom_a_audit_callsites.py --evidence exists to catch.  It did.
    for addr, insn in ((0xFF079D, 0xFF042A), (0xFF07AB, 0xFF0430), (0xFF07B9, 0xFF0436)):
        check('`ld XIY,0x%06X` at %06X' % (addr, insn),
              rd(insn, 5).hex(), ('45' + addr.to_bytes(4, 'little').hex()))

# -------------------------------------------------- SWI7 service table ------
def swi7_table():
    print('SWI7_ServiceTable -- every live slot is a SYMBOL (round-2 audit F10)')
    src = open(SRC_A, encoding='utf-8').read()
    i = src.index('\nSWI7_ServiceTable:\n')
    body = src[i:i + 40000]
    rows = re.findall(r'\t\.long ([^\t\n;]+?)\s*; ([0-9A-F]{6})  ((?:[0-9a-f]{2} ){3}[0-9a-f]{2})   svc (0x[0-9A-F]{2})', body)
    check('rows parsed', len(rows), 64)
    bare = [r for r in rows if r[0].startswith('0x')]
    check('rows still spelled as a bare address', bare, [])
    live = [r for r in rows if r[0] != 'LCD_Svc_Unimplemented']
    check('live slots', len(live), 34)
    check('distinct live targets', len({r[0] for r in live}), 34)
    # the emitted bytes in the listing comment must equal the label's own address
    bad = []
    for name, addr, byts, svc in rows:
        want = int.from_bytes(bytes.fromhex(byts.replace(' ', '')), 'little')
        m = re.search(r'\n%s:\n\t\S+[^\n]*; ([0-9A-F]{6})' % re.escape(name), src)
        if not m or int(m.group(1), 16) != want:
            bad.append((svc, name))
    check('slots whose symbol does not sit at the emitted address', bad, [])
    check('slot 0x17 resolves to', dict((r[3], r[0]) for r in rows)['0x17'],
          'LCD_Svc_17_DrawText8x8Packed')

def selftest():
    print('SELFTEST -- three negative controls, each MUST report FAIL')
    global OK, FAIL
    o, f = OK, FAIL
    check('control 1: index 0 is NOT "STANDR"', rd(0xFF0485, 6), b'ROOM  ')
    check('control 2: 130 entries do NOT end at 0xFF0791', hex(0xFF0485 + 780), '0xff078b')
    check('control 3: cell 98 is NOT blank', rd(0xFF0D65 + 196, 2), b'98')
    got = FAIL - f
    OK, FAIL = o, f
    print('  three controls fired: %d/3' % got)
    return got == 3

if __name__ == '__main__':
    if '--selftest' in sys.argv:
        sys.exit(0 if selftest() else 1)
    for fn in (kit_category_legends, tick_labels, octave_names,
               legend_duplicates, swi7_table):
        fn(); print()
    print('%d ok, FAILURES: %d' % (OK, FAIL))
    sys.exit(1 if FAIL else 0)
