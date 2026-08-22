#!/usr/bin/env python3
"""Probe: the llvm-mc spelling for the unidasm form `ld (r+imm),imm`.

QUESTION ANSWERED
  unidasm prints `ld (XIZ+0x00),0x90`, `ld (XSP+0x00ac),0x00` and
  `ld (XBC+0xfe),0x1234` with the SAME printed shape.  That one shape is FOUR
  encodings.  For each, is there an llvm-mc spelling whose --show-encoding
  bytes equal the bytes in the ROM FILE?  "It assembled" is NOT a pass -- five
  of the six spellings a human would naturally reach for assemble happily and
  emit DIFFERENT bytes (pass 4).

COMMANDS  (run from the repo root)
  python3 tools/spelling-probes/verify_ld_ri_imm.py rom        # pass 1, all 8 trees
  python3 tools/spelling-probes/verify_ld_ri_imm.py sweep      # pass 2, synthetic
  python3 tools/spelling-probes/verify_ld_ri_imm.py real       # pass 3, converted lines
  python3 tools/spelling-probes/verify_ld_ri_imm.py dangerous  # pass 4, the traps
  python3 tools/spelling-probes/verify_ld_ri_imm.py data       # pass 5, code or data
  python3 tools/spelling-probes/verify_ld_ri_imm.py all

SIGNAL READ
  raw bytes of the eight original binaries at their real ORIGIN (see TREES).
  PASS = the llvm-mc encoding is byte-for-byte the ROM bytes at that address.
  Sites are taken from the .byte blobs that still block conversion; unidasm
  zero-pads past the end of a blob, so any decode whose bytes do not match the
  ROM file is discarded as a blob-end artefact (34 of them in v7/v9/v10).

THE RULE -- decided on the RAW BYTES, never on the printed text
  b[0] = B8+r , b[1]=d8 , b[2]=0x00   ->  ld  (<XRR[r]><disp>), b[3]
  b[0] = B8+r , b[1]=d8 , b[2]=0x02   ->  ldw (<XRR[r]><disp>), b[3]|b[4]<<8
        disp = signed(d8)  EXCEPT d8 == 0, which must be written "+256":
        the backend uses 256 as a force-d8 sentinel, because a plain "+0"
        collapses to the 1-byte B0+r prefix and loses a byte.
  b[0] = 0xF3 , b[1]&3 == 1 , b[4]=0x00 -> stib_ind b[1], b[2], b[3], b[5]
  b[0] = 0xF3 , b[1]&3 == 1 , b[4]=0x02 -> stiw_ind b[1], b[2], b[3], b[5], b[6]
        raw-byte form, always right.  `ld (<XRR>+d16), imm` is an alias that is
        correct ONLY when b[1] is a current-bank XRR byte (E1 E5 E9 ED F1 F5 F9
        FD) and the signed d16 is outside -128..127; otherwise llvm-mc compacts
        it to the shorter B8/B0 prefix and the bytes differ.
  XRR order: xwa xbc xde xhl xix xiy xiz xsp.

RESULTS -- 2026-08-22, LLVM tlcs900_backend@cb165c5cdc4b
  pass 1  1742 sites still inside .byte blobs across all eight trees
          (v7 1316, v9 85, v10 85, v142/subcpu 41, table_data 215; the other
          three trees have none), 663 distinct encodings,
          1742/1742 BYTE-EXACT, 0 mismatched, 0 unspellable.
          families: B8/ld 1145, B8/ldw 476, F3/ld 115, F3/ldw 6.
          49 sites have d8 == 0 and need the +256 sentinel -- among them the
          example instance, v7 0xefb8e2 `be 00 00 90` = ld (XIZ+0x00),0x90.
          105 have a negative d8.  Of the 121 F3/d16 sites, 0 have a d16 that
          fits in a signed byte and 119 use a current-bank register byte, so
          the `ld (xrr+d16)` alias happens to be safe for all but two of them
          -- stib_ind/stiw_ind is safe for all of them.
  pass 2  21360 synthetic encodings swept, 21360 byte-exact, 0 wrong;
          221/221 sampled cases confirmed by unidasm to print as this form.
  pass 3  1418 lines of this instruction are already native in the sources
          (v7 147, v9 616, v10 616, v142 39) and ALL EIGHT trees currently
          rebuild md5-identical to their original binaries, so those lines are
          byte-exact by construction.
  pass 4  6 natural-looking spellings: 6 assemble, 6 emit the WRONG BYTES.
  pass 5  227 of the 1742 sites are DATA, not code: 215 in table_data (a data
          ROM; 91 inside the 0x830000-0x87FFFF tone database, and in
          panel_memory_presets.s 79 of the 80 sites sit on a fixed 674-byte
          record stride) and 12 in v142/subcpu/subcpu_data_tables.s.
          The rule spells them byte-exactly anyway, but a converter should
          leave them as data.
"""
import os, re, sys, glob, subprocess, tempfile, collections

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNI  = os.path.expanduser('~/compartilhado/tools/unidasm')
MC   = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')
XRR  = ['xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp']

# tree glob -> (binary, ORIGIN)   (same table as blob_cp_reg_direct_alltrees.py)
TREES = [('v7/maincpu',   'kn5000_v7_program.rom',      0xE00000),
         ('v9/maincpu',   'kn5000_v9_program.rom',      0xE00000),
         ('v10/maincpu',  'kn5000_v10_program.rom',     0xE00000),
         ('v142/subcpu',  'kn5000_subprogram_v142.rom', 0x00EF00),
         ('subcpu',       'kn5000_subcpu_boot.ic30',    0xFE0000),
         ('table_data',   'kn5000_table_data.rom',      0x800000),
         ('custom_data',  'kn5000_custom_data.ic19',    0x300000),
         ('hdae5000',     'hd-ae5000_v2_06i.ic4',       0x280000)]

BYTE_RE = re.compile(r'^\s*\.byte\s+(.*)$')
# a bank digit is allowed: `f3 01 34 12 00 55` prints as ld (XWA0+0x1234),0x55
SITE_RE = re.compile(r'^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s+'
                     r'(ld \(X[A-Z]{2}\d?\+0x[0-9a-f]+\),0x[0-9a-f]+)\s*$')


# ------------------------------------------------------------------ the rule
def spell(b):
    """(llvm-mc spelling, instruction length) for the raw bytes of one site."""
    if 0xB8 <= b[0] <= 0xBF and len(b) >= 3:
        r, d8, op = b[0] - 0xB8, b[1], b[2]
        d = 256 if d8 == 0 else (d8 - 256 if d8 >= 0x80 else d8)
        disp = '+%d' % d if d >= 0 else '-%d' % -d
        if op == 0x00 and len(b) >= 4:
            return 'ld (%s%s), %d' % (XRR[r], disp, b[3]), 4
        if op == 0x02 and len(b) >= 5:
            return 'ldw (%s%s), %d' % (XRR[r], disp, b[3] | (b[4] << 8)), 5
        return None, 0
    if b[0] == 0xF3 and len(b) >= 5 and (b[1] & 3) == 1:
        if b[4] == 0x00 and len(b) >= 6:
            return 'stib_ind %d, %d, %d, %d' % (b[1], b[2], b[3], b[5]), 6
        if b[4] == 0x02 and len(b) >= 7:
            return ('stiw_ind %d, %d, %d, %d, %d'
                    % (b[1], b[2], b[3], b[5], b[6])), 7
    return None, 0


# ------------------------------------------------------------------- llvm-mc
def asm_batch(lines):
    """Assemble many lines at once; bisect around any that llvm-mc rejects."""
    if not lines:
        return []
    p = subprocess.run([MC, '-triple=tlcs900', '--show-encoding'],
                       input='\n'.join(lines) + '\n',
                       capture_output=True, text=True)
    enc = re.findall(r'encoding: \[([^\]]*)\]', p.stdout)
    if p.returncode == 0 and len(enc) == len(lines):
        return [bytes(int(x, 0) for x in e.replace(' ', '').split(','))
                for e in enc]
    if len(lines) == 1:
        return [None]
    h = len(lines) // 2
    return asm_batch(lines[:h]) + asm_batch(lines[h:])


# ----------------------------------------------------------------- ROM sites
def blob_runs(tree):
    runs = []
    for f in sorted(glob.glob('%s/%s/**/*.s' % (REPO, tree), recursive=True)):
        cur, start = b'', None
        for i, line in enumerate(open(f, errors='replace'), 1):
            m = BYTE_RE.match(line)
            if m:
                vals = [x.strip() for x in m.group(1).split(';')[0].split(',')
                        if x.strip()]
                try:
                    bb = bytes(int(x, 0) & 0xFF for x in vals)
                except ValueError:
                    if cur: runs.append((f, start, cur)); cur, start = b'', None
                    continue
                if not cur: start = i
                cur += bb
            else:
                s = line.strip()
                if s.startswith(';') or s.endswith(':') or not s:
                    continue
                if cur: runs.append((f, start, cur)); cur, start = b'', None
        if cur: runs.append((f, start, cur))
    return runs


def rom_sites():
    """Every `ld (r+imm),imm` inside a .byte blob, bytes read FROM THE BINARY."""
    out, trunc = [], 0
    for tree, binname, base in TREES:
        rom = open(os.path.join(REPO, 'original_ROMs', binname), 'rb').read()
        for f, ln, b in blob_runs(tree):
            if len(b) < 8: continue
            idx = rom.find(b)
            if idx < 0 or rom.find(b, idx + 1) >= 0:
                continue                       # unlocatable or ambiguous run
            addr = base + idx
            tf = tempfile.NamedTemporaryFile(suffix='.bin', delete=False)
            tf.write(b); tf.close()
            txt = subprocess.run([UNI, tf.name, '-arch', 'tlcs900',
                                  '-basepc', hex(addr)],
                                 capture_output=True, text=True).stdout
            os.unlink(tf.name)
            for line in txt.split('\n'):
                m = SITE_RE.match(line)
                if not m: continue
                a = int(m.group(1), 16)
                by = bytes(int(x, 16) for x in m.group(2).split())
                if rom[a - base:a - base + len(by)] != by:
                    trunc += 1                 # unidasm padded past the blob
                    continue
                out.append((tree, a, by, m.group(3), os.path.relpath(f, REPO), ln))
    return out, trunc


# -------------------------------------------------------------------- passes
def pass_rom():
    sites, trunc = rom_sites()
    print('pass 1 -- `ld (r+imm),imm` still inside .byte blobs, all eight trees')
    print('  sites: %d   (discarded %d blob-end zero-padding artefacts)'
          % (len(sites), trunc))
    lines, keep, unspellable = [], [], []
    for s in sites:
        sp, n = spell(s[2])
        if sp is None or n != len(s[2]):
            unspellable.append(s); continue
        lines.append(sp); keep.append(s)
    encs = asm_batch(lines)
    ok = bad = fail = 0
    fams = collections.Counter(); per_tree = collections.Counter(); seen = {}
    for (tree, a, by, txt, f, ln), sp, e in zip(keep, lines, encs):
        subop = by[2] if by[0] != 0xF3 else by[4]
        fam = ('B8' if by[0] != 0xF3 else 'F3') + ('/ld' if subop == 0 else '/ldw')
        fams[fam] += 1; per_tree[tree] += 1
        if e is None:
            fail += 1
            print('  FAIL      %-12s %06x %-22s <- %s' % (tree, a, by.hex(' '), sp))
        elif e == by:
            ok += 1
            seen.setdefault((fam, by[0], by[1]), (tree, a, by, txt, sp, f, ln))
        else:
            bad += 1
            print('  MISMATCH  %-12s %06x rom=%-22s got=%-22s <- %s'
                  % (tree, a, by.hex(' '), e.hex(' '), sp))
    print('  byte-exact: %d   mismatched: %d   did-not-assemble: %d   unspellable: %d'
          % (ok, bad, fail, len(unspellable)))
    print('  by family:', dict(fams))
    print('  by tree:  ', dict(per_tree))
    print('  distinct encodings covered: %d' % len(set(bytes(s[2]) for s in keep)))
    # the two trap sub-populations
    z = [s for s in keep if s[2][0] != 0xF3 and s[2][1] == 0]
    neg = [s for s in keep if s[2][0] != 0xF3 and 0x80 <= s[2][1]]
    f3 = [s for s in keep if s[2][0] == 0xF3]
    def sd16(b):
        v = b[2] | (b[3] << 8)
        return v - 65536 if v >= 0x8000 else v
    f3small = [s for s in f3 if -128 <= sd16(s[2]) <= 127]
    f3bank = [s for s in f3 if s[2][1] in (0xE1, 0xE5, 0xE9, 0xED, 0xF1, 0xF5, 0xF9, 0xFD)]
    print('  d8 == 0 (need the +256 sentinel): %d' % len(z))
    print('  d8 negative (0x80..0xff):         %d' % len(neg))
    print('  F3/d16 sites: %d, of which d16 fits a signed byte: %d, '
          'current-bank register byte: %d' % (len(f3), len(f3small), len(f3bank)))
    print('  representative sites (one per family x prefix x displacement byte):')
    for k in sorted(seen):
        tree, a, by, txt, sp, f, ln = seen[k]
        print('    %-12s %06x  %-22s %-28s <- %-34s [%s:%d]'
              % (tree, a, by.hex(' '), txt, sp, f, ln))
    for s in unspellable:
        print('  UNSPELLABLE %-12s %06x %s' % (s[0], s[1], s[2].hex(' ')))
    return ok, bad, fail, len(unspellable)


def pass_sweep():
    """Synthetic: every register x every d8 x a grid of d16 and immediates.
    Each case is also fed through unidasm, so a case that is NOT our printed
    form is reported instead of silently inflating the pass count."""
    print('pass 2 -- synthetic sweep of the whole form')
    imms8 = [0x00, 0x01, 0x7f, 0x80, 0xff]
    imms16 = [0x0000, 0x0001, 0x00ff, 0x1234, 0xffff]
    cases = []
    for r in range(8):
        for d8 in range(256):
            for i in imms8:
                cases.append(bytes([0xB8 + r, d8, 0x00, i]))
            for i in imms16:
                cases.append(bytes([0xB8 + r, d8, 0x02, i & 0xFF, i >> 8]))
        rb = 0xE0 + r * 4 + 1
        for d16 in (0x0000, 0x0001, 0x007f, 0x0080, 0x00ff, 0x0100,
                    0x7fff, 0x8000, 0xff00, 0xfff6, 0xffff):
            for i in imms8:
                cases.append(bytes([0xF3, rb, d16 & 0xFF, d16 >> 8, 0x00, i]))
            for i in imms16:
                cases.append(bytes([0xF3, rb, d16 & 0xFF, d16 >> 8, 0x02,
                                    i & 0xFF, i >> 8]))
    lines = [spell(c)[0] for c in cases]
    assert all(lines), 'the rule failed to produce a spelling for a swept case'
    encs = asm_batch(lines)
    bad = [(c, e) for c, e in zip(cases, encs) if e != c]
    print('  encodings tried: %d   byte-exact: %d   wrong or failed: %d'
          % (len(cases), len(cases) - len(bad), len(bad)))
    for c, e in bad[:20]:
        print('    %s -> %s' % (c.hex(' '), e.hex(' ') if e else 'FAIL'))
    # unidasm cross-check on a sample: is each really printed as our form?
    sample = cases[::97]
    blob = b''.join(c for c in sample)
    tf = tempfile.NamedTemporaryFile(suffix='.bin', delete=False)
    tf.write(blob); tf.close()
    txt = subprocess.run([UNI, tf.name, '-arch', 'tlcs900', '-basepc', '0xe00000'],
                         capture_output=True, text=True).stdout
    os.unlink(tf.name)
    n_form = sum(1 for line in txt.split('\n') if SITE_RE.match(line))
    print('  unidasm cross-check: %d of %d sampled decodes print as the form'
          % (n_form, len(sample)))
    return len(cases) - len(bad), len(bad)


def pass_real():
    """The trees already carry this instruction in native form, and every one
    of the eight trees currently rebuilds BYTE-IDENTICAL to its original
    binary. So those lines are byte-exact by construction, not by search;
    this pass asserts the md5 equality and counts the lines it certifies."""
    import hashlib
    print('pass 3 -- already-converted source lines, certified by the byte-exact build')
    exact = {}
    for tree, binname, base in TREES:
        orig = os.path.join(REPO, 'original_ROMs', binname)
        stem = os.path.splitext(binname)[0]
        rb = os.path.join(REPO, 'rebuilt_ROMs', stem + '.llvm.rom')
        if not os.path.exists(rb):
            exact[tree] = None; continue
        a = hashlib.md5(open(orig, 'rb').read()).hexdigest()
        b = hashlib.md5(open(rb, 'rb').read()).hexdigest()
        exact[tree] = (a == b)
    # our form ONLY: a displacement is mandatory, else it is the B0+r form
    pat = re.compile(r'^\s*(ld|ldw)\s+\((x[a-z]{2})([+-]\d+)\),\s*(-?\d+)\s*(;.*)?$')
    lines, where = [], []
    for tree, binname, base in TREES:
        for f in sorted(glob.glob('%s/%s/**/*.s' % (REPO, tree), recursive=True)):
            for i, line in enumerate(open(f, errors='replace'), 1):
                if not pat.match(line): continue
                lines.append(line.strip().split(';')[0].strip())
                where.append((tree, binname, os.path.relpath(f, REPO), i))
    encs = asm_batch(lines)
    roms = {}
    per_tree = collections.Counter(); found = miss = 0
    for (tree, binname, f, i), sp, e in zip(where, lines, encs):
        per_tree[tree] += 1
        if e is None:
            print('  DID NOT ASSEMBLE %s:%d  %s' % (f, i, sp)); miss += 1; continue
        rom = roms.setdefault(binname, open(os.path.join(
            REPO, 'original_ROMs', binname), 'rb').read())
        if e in rom:
            found += 1
        else:
            miss += 1
            print('  ENCODING ABSENT FROM ITS BINARY %s:%d  %s -> %s'
                  % (f, i, sp, e.hex(' ')))
    for tree, binname, base in TREES:
        tag = {True: 'rebuild BYTE-EXACT', False: 'rebuild DIFFERS',
               None: 'no rebuild found'}[exact[tree]]
        print('  %-12s %5d native lines   %s' % (tree, per_tree[tree], tag))
    print('  total native `ld/ldw (xrr+d),imm` lines: %d   '
          'encoding also occurs in its binary: %d   absent: %d'
          % (len(lines), found, miss))
    return len(lines), found, miss


def pass_data():
    """Not every site is an instruction. Which of them are DATA, and why?"""
    print('pass 5 -- which sites are data rather than code')
    sites, _ = rom_sites()
    for tree in ('table_data', 'v142/subcpu'):
        sub = [s for s in sites if s[0] == tree]
        if not sub: continue
        print('  %s: %d sites' % (tree, len(sub)))
        byfile = collections.Counter(s[4] for s in sub)
        for f, n in byfile.most_common():
            a = sorted(x[1] for x in sub if x[4] == f)
            gaps = collections.Counter(a[i + 1] - a[i] for i in range(len(a) - 1))
            top = gaps.most_common(3)
            print('    %5d  %-40s  most common address gaps: %s' % (n, f, top))
    td = [s for s in sites if s[0] == 'table_data']
    print('  table_data is a DATA ROM: 0x830000-0x87FFFF is the tone database that')
    print('  SubCPU_Send_Payload bulk-copies to Sub-CPU RAM as five 64KB E1 transfers')
    print('  (v10/maincpu/kn5000_v10_program.s:326-345); %d of the %d sites are inside it.'
          % (sum(1 for s in td if 0x830000 <= s[1] < 0x880000), len(td)))
    print('  In panel_memory_presets.s the sites sit on a FIXED 674-byte stride --')
    print('  that is a record table being linear-scanned, not an instruction stream.')
    return


def pass_dangerous():
    """Spellings that ASSEMBLE but emit the WRONG bytes. These are the traps."""
    print('pass 4 -- dangerous spellings (assemble fine, wrong bytes)')
    traps = [
        ('ld (xiz+0), 0x90',   'be 00 00 90',
         'd8==0 collapses to the 1-byte B0+r prefix -- write +256'),
        ('ld (xiz), 0x90',     'be 00 00 90',
         'same trap spelled with no displacement at all'),
        ('ldw (xiz+0), 0x1234', 'be 00 02 34 12',
         'the word form of the same trap'),
        ('ld (xsp+4), 0x00ff', 'bf 04 02 ff 00',
         'a WORD store written as `ld` silently becomes a BYTE store'),
        ('ld (xix+246), 0',    'bc f6 00 00',
         "unidasm's raw d8 0xf6 read as unsigned inflates to the 6-byte d16 form"),
        ('ld (xbc+44), 0',     'f3 e5 2c 00 00 00',
         'a d16 site whose value fits in d8 is compacted -- use stib_ind'),
    ]
    encs = asm_batch([t[0] for t in traps])
    n_wrong = 0
    for (sp, want, why), e in zip(traps, encs):
        w = bytes(int(x, 16) for x in want.split())
        got = e.hex(' ') if e else 'DID NOT ASSEMBLE'
        if e != w: n_wrong += 1
        print('  %-22s rom=%-22s got=%-22s %-12s %s'
              % (sp, want, got, 'WRONG BYTES' if e != w else 'ok', why))
    print('  assembled but emitted the wrong bytes: %d/%d' % (n_wrong, len(traps)))
    return n_wrong


if __name__ == '__main__':
    what = sys.argv[1] if len(sys.argv) > 1 else 'rom'
    if what == 'rom':         pass_rom()
    elif what == 'sweep':     pass_sweep()
    elif what == 'real':      pass_real()
    elif what == 'dangerous': pass_dangerous()
    elif what == 'data':      pass_data()
    elif what == 'all':
        pass_rom(); print(); pass_sweep(); print(); pass_real(); print()
        pass_dangerous(); print(); pass_data()
    else:
        sys.exit('unknown pass: %s' % what)
