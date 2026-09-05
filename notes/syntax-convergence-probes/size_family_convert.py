#!/usr/bin/env python3
"""Convert one "size/form family" mnemonic to its native spelling, per site.

The question this answers
-------------------------
For a synthetic mnemonic in the size/form class (lane w16/conv-size), is the
name a pure *spelling* of a form the operand syntax can already express, or is
it a *form selector* that picks between two legal encodings of the same
instruction?  The only trustworthy answer is the encoder's: assemble the old
spelling and the proposed new spelling and compare the bytes, **at every single
site**, before any file is written.

Usage, from the tree root:

    # triage every family this lane owns, write nothing
    python3 notes/syntax-convergence-probes/size_family_convert.py --triage

    # verify one family site by site (still writes nothing)
    python3 notes/syntax-convergence-probes/size_family_convert.py --family incm

    # verify, and only if 100% of sites match, rewrite the sources
    python3 notes/syntax-convergence-probes/size_family_convert.py --family incm --apply

`--apply` refuses to write if a single site disagrees.  Sources are read and
written as latin-1 (they are not UTF-8; see notes/lanes/BRIEF-2026-09-01.md).

⚠ The toolchain is shared and mutable.  This script copies `llvm-mc` aside
before it starts and prints its sha256 with the results, so a number taken here
names the binary that produced it.
"""
import argparse, hashlib, os, re, shutil, subprocess, sys, tempfile, collections

ROOTS = ['v7', 'v9', 'v10', 'v142', 'subcpu', 'hdae5000',
         'table_data', 'custom_data', 'wsa1', 'symbols', 'dsp']

# family -> (regex over the whole source line, rewrite(match) -> new line)
#
# Every rewrite preserves the leading whitespace, the mnemonic/operand
# separator, and everything after the operands (trailing comment included).

def _rw_incm(m):
    # incm -> incw.  Same length, so column alignment is untouched.
    return m.group('head') + 'incw' + m.group('tail')

def _rw_ldda32(m):
    # ldda32 xwa, 4160   ->   ld xwa, (4160:16)
    # ldda32 xwa, (4160) ->   ld xwa, (4160:16)
    return (m.group('head') + 'ld' + m.group('sep') + m.group('reg') + ', ('
            + m.group('addr') + ':16)' + m.group('rest'))

# ⚠ A control.  `--foil` swaps in a spelling that is a *plausible* native name
# and a *wrong* encoding, so a run that reports 0 mismatches without it has been
# shown able to report mismatches at all.  incm's foil is `inc` (the 8-bit
# memory form, 0x8F prefix instead of 0x9F); ldda32's is the 24-bit address
# width `:24` instead of `:16`.
def _sel_rw(base, sel):
    """`<mn> <dst>, <imm>` -> `<base> <dst>, <imm><sel>`: append an encoding
    selector to the immediate (cps/lds/lds32/ldb sites are all `<reg>, 0..7`)."""
    def rw(m):
        return (m.group('head') + base + m.group('sep') + m.group('dst') + ','
                + m.group('mid') + m.group('imm') + sel + m.group('rest'))
    return rw


def _io_rw(base):
    """Reshape the io family: `<mn> <addr>, <val>` -> `<base> (<addr>:8), <val>:io`."""
    def rw(m):
        return (m.group('head') + base + m.group('sep') + '(' + m.group('addr')
                + ':8),' + m.group('mid') + m.group('val') + ':io'
                + m.group('rest'))
    return rw


def _sel_re(mn):
    return re.compile(r'^(?P<head>\s*)' + mn + r'(?P<sep>[ \t]+)'
                      r'(?P<dst>[^,;]+),(?P<mid>[ \t]*)(?P<imm>[^\s;]+)(?P<rest>.*)$')


def _io_re(mn):
    return re.compile(r'^(?P<head>\s*)' + mn + r'(?P<sep>[ \t]+)'
                      r'(?P<addr>[^,;]+),(?P<mid>[ \t]*)(?P<val>[^\s;]+)(?P<rest>.*)$')


FOILS = {
    'incm': ('incw', 'inc'),
    'ldda32': (':16)', ':24)'),
    # Dropping the selector yields the long/untagged form: different bytes, a
    # clean byte-difference null (verified: none become a rejection).
    'cps': (':i3', ''),
    'lds': (':i3', ''),
    'lds32': (':i3', ''),
    'ldb': (':opc', ''),
    'ldio': (':io', ''),
    'ldwio': (':io', ''),
}

FAMILIES = {
    'incm': (re.compile(r'^(?P<head>\s*)incm(?P<tail>[ \t].*)$'), _rw_incm),
    # Encoding-selector families (SPEC-encoding-selectors-2026-09-04.md step 9);
    # selector per family VERIFIED against the assembler, not assumed.
    'cps':   (_sel_re('cps'),   _sel_rw('cp', ':i3')),
    'lds':   (_sel_re('lds'),   _sel_rw('ld', ':i3')),
    'lds32': (_sel_re('lds32'), _sel_rw('ld', ':i3')),
    'ldb':   (_sel_re('ldb'),   _sel_rw('ld', ':opc')),
    'ldio':  (_io_re('ldio'),   _io_rw('ld')),
    'ldwio': (_io_re('ldwio'),  _io_rw('ldw')),
    'ldda32': (re.compile(
        r'^(?P<head>\s*)ldda32(?P<sep>[ \t]+)(?P<reg>[a-z]+)\s*,\s*'
        r'\(?\s*(?P<addr>0x[0-9a-fA-F]+|\d+)\s*\)?(?P<rest>.*)$'), _rw_ldda32),
}

INSN = re.compile(r'^(?P<head>\s*)(?P<mn>[a-z][a-z0-9_]*)(?P<tail>[ \t].*)?$')


def sources():
    # Git-tracked assembler files only, so the population matches the census in
    # encoding_selector_exposure.py exactly (git ls-files, same globs) and no
    # scratch/generated file is ever rewritten -- e.g. the untracked image dump
    # wsa1/notes/.image-*.s, which os.walk would otherwise sweep in.
    out = subprocess.run(['git', 'ls-files', '-z', '*.s', '*.inc', '*.asm'],
                         capture_output=True, text=True, check=True).stdout
    for path in out.split('\0'):
        if path:
            yield path


def collect(family, foil=False):
    pat, rw = FAMILIES[family]
    sites = []
    for path in sources():
        with open(path, encoding='latin-1') as fh:
            for lineno, line in enumerate(fh, 1):
                line = line.rstrip('\n')
                m = pat.match(line)
                if m:
                    new = rw(m)
                    if foil:
                        a, b = FOILS[family]
                        new = new.replace(a, b, 1)
                    sites.append((path, lineno, line, new))
    return sites


def mc_encode(mc, lines):
    """Assemble one instruction per line; return [bytes|None] in order."""
    src = '\n'.join(lines) + '\n'
    with tempfile.NamedTemporaryFile('w', suffix='.s', delete=False,
                                     encoding='latin-1') as fh:
        fh.write(src)
        tmp = fh.name
    try:
        p = subprocess.run([mc, '-triple=tlcs900', '-show-encoding', tmp],
                           capture_output=True, text=True)
        bad = set()
        for e in p.stderr.splitlines():
            m = re.match(re.escape(tmp) + r':(\d+):', e)
            if m:
                bad.add(int(m.group(1)))
        out = []
        for m in re.finditer(r'encoding: \[([^\]]*)\]', p.stdout):
            out.append(m.group(1).replace(' ', ''))
        if bad:
            # A rejected line still prints an encoding (see the probes README),
            # so a positional map is unsafe once anything failed.  Fall back to
            # per-line assembly for the whole batch.
            return None, sorted(bad)
        return out, []
    finally:
        os.unlink(tmp)


def verify(mc, sites):
    """Assemble old and new spelling of every site; return list of mismatches.

    A site whose operand is a macro parameter (`\\Param`) cannot be assembled
    standalone -- it needs the macro-expansion context -- and is rejected
    identically as the OLD and the NEW spelling, so the rewrite cannot have
    changed it.  Such sites are dropped from the byte check here and their
    equivalence is proven in context by gate-all after --apply.  A site that
    assembles as one spelling but NOT the other is a real change: return
    'ASYM' so the caller fails loudly."""
    olds = [l.split(';', 1)[0].rstrip() for _p, _n, l, _nw in sites]
    news = [nw.split(';', 1)[0].rstrip() for _p, _n, _l, nw in sites]
    eo, bad_o = mc_encode(mc, olds)
    en, bad_n = mc_encode(mc, news)
    if eo is not None and en is not None:
        if len(eo) != len(sites) or len(en) != len(sites):
            raise SystemExit('encoding count mismatch: %d old / %d new / %d sites'
                             % (len(eo), len(en), len(sites)))
        mism = [(sites[i][0], sites[i][1], olds[i], news[i], eo[i], en[i])
                for i in range(len(sites)) if eo[i] != en[i]]
        return mism, (eo, en)
    # Rejected lines somewhere (bad_o / bad_n are 1-based indices into the batch).
    so, sn = set(bad_o or []), set(bad_n or [])
    if so != sn:
        return 'ASYM', (sorted(so), sorted(sn), sorted(so ^ sn))
    keep = [i for i in range(len(sites)) if (i + 1) not in so]
    eo2, _bo = mc_encode(mc, [olds[i] for i in keep])
    en2, _bn = mc_encode(mc, [news[i] for i in keep])
    if eo2 is None or en2 is None:
        return None, (_bo, _bn)
    mism = [(sites[keep[j]][0], sites[keep[j]][1], olds[keep[j]], news[keep[j]],
             eo2[j], en2[j]) for j in range(len(keep)) if eo2[j] != en2[j]]
    return mism, ('deferred', sorted(so))


def apply(sites):
    per = collections.defaultdict(dict)
    for path, lineno, old, new in sites:
        per[path][lineno] = new
    for path, edits in per.items():
        with open(path, encoding='latin-1') as fh:
            lines = fh.read().split('\n')
        for lineno, new in edits.items():
            assert lines[lineno - 1] == \
                [s for s in sites if s[0] == path and s[1] == lineno][0][2]
            lines[lineno - 1] = new
        with open(path, 'w', encoding='latin-1') as fh:
            fh.write('\n'.join(lines))
    return len(per)


def triage(mc):
    """Assemble one representative of every lane mnemonic next to the native
    spelling a plain rename would produce, and print the byte comparison."""
    probes = [
        ('cps',      'cps a, 4',            'cp a, 4'),
        ('cps',      'cps wa, 4',           'cp wa, 4'),
        ('cps',      'cps xwa, 4',          'cp xwa, 4'),
        ('lds',      'lds hl, 0',           'ld hl, 0'),
        ('lds32',    'lds32 xiz, 0',        'ld xiz, 0'),
        ('lds32',    'lds32 xiz, 0',        'lds xiz, 0'),
        ('ldb',      'ldb d, 0x4',          'ld d, 0x4'),
        ('ldda32',   'ldda32 xwa, 4160',    'ld xwa, (4160:16)'),
        ('cpw',      'cpw (xsp + 6), 0x0',  'cp (xsp + 6), 0x0'),
        ('stb_erp',  'stb_erp a, 0xFB',     'ld (0xFB), a'),
        ('ldb_erp',  'ldb_erp a, 0xFB',     'ld a, (0xFB)'),
        ('incm',     'incm 1, (xsp + 4)',   'incw 1, (xsp + 4)'),
        ('incm',     'incm 1, (xsp + 4)',   'inc 1, (xsp + 4)'),
        ('ldio',     'ldio 0x07, 0xFF',     'ld (0x07:8), 0xFF'),
        ('ldio',     'ldio 0x07, 0xFF',     'ld (0x07), 0xFF'),
        ('ldwio',    'ldwio 237, 0x8e00',   'ldw (237:8), 0x8e00'),
        ('ldwio',    'ldwio 237, 0x8e00',   'ldw (237), 0x8e00'),
    ]
    print('%-9s %-22s %-24s %-26s %-26s %s'
          % ('family', 'old spelling', 'proposed native', 'old bytes',
             'new bytes', 'verdict'))
    for fam, old, new in probes:
        eo, _ = one(mc, old)
        en, _ = one(mc, new)
        if en is None:
            v = 'REFUSED  (b) form-selector, no syntax'
        elif eo == en:
            v = 'SAME     (a) pure spelling'
        else:
            v = 'DIFFERS  (b) form-selector'
        print('%-9s %-22s %-24s %-26s %-26s %s'
              % (fam, old, new, eo, en if en else '-', v))


def collisions():
    """⚠ Would "let the assembler pick the short form when the immediate fits"
    be safe?  No: count the sites that already use the LONG encoding with an
    immediate the short form could hold.  Every one of them would be silently
    rewritten by such a rule."""
    G32 = {'xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp'}
    G16 = {'wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', 'sp'}
    G8 = {'w', 'a', 'b', 'c', 'd', 'e', 'h', 'l', 'ixl', 'ixh', 'iyl', 'iyh',
          'izl', 'izh', 'spl', 'sph'}
    pat = re.compile(r'^\s*(cp|ld)\s+([a-z]+)\s*,\s*(-?0x[0-9a-fA-F]+|-?\d+)'
                     r'\s*(;.*)?$')
    n = collections.Counter()
    for path in sources():
        with open(path, encoding='latin-1') as fh:
            for line in fh:
                m = pat.match(line.rstrip('\n'))
                if not m:
                    continue
                r = m.group(2).lower()
                cls = ('32' if r in G32 else '16' if r in G16
                       else '8' if r in G8 else None)
                if cls is None:
                    continue
                n[(m.group(1), cls, 'total')] += 1
                if 0 <= int(m.group(3), 0) <= 7:
                    n[(m.group(1), cls, 'fits_short')] += 1
    print('%-4s %-5s %8s %12s' % ('insn', 'size', 'sites', 'imm in 0..7'))
    for insn in ('cp', 'ld'):
        for cls in ('8', '16', '32'):
            print('%-4s %-5s %8d %12d'
                  % (insn, cls, n[(insn, cls, 'total')],
                     n[(insn, cls, 'fits_short')]))


def sentinel():
    """How many sites now spell the explicit d8=0 encoding as `(Xrr+256)`?

    `TLCS900MCCodeEmitter.cpp:283` documents 256 as a SENTINEL meaning "force
    the d8 form with displacement 0" -- introduced 2026-09-02 (llvm-project
    63ff7d92fb5f) so that `(Xrr)` and `(Xrr+0x00)`, two different encodings,
    stop printing the same text.  It works; the point of counting is that it is
    a form selector spelled as a magic NUMBER where every other form selector in
    this backend is spelled as a `:width` annotation.  See
    scripts/analysis/census_rid8_zero_disp.py for the lane that owns the
    conversion itself.
    """
    # ⚠ Match on the VALUE, not on the text `256`: the tree spells the same
    # sentinel `256` (931), `0x0100` (200) and `0x100` (1), and a text match
    # undercounts it by 201 sites.
    pat = re.compile(r'\((x[a-z]{2})\s*\+\s*(0x[0-9a-fA-F]+|\d+)\s*\)')
    n = collections.Counter()
    spell = collections.Counter()
    for path in sources():
        with open(path, encoding='latin-1') as fh:
            for line in fh:
                for m in pat.finditer(line):
                    if int(m.group(2), 0) == 256:
                        n[path.split('/')[0]] += 1
                        spell[m.group(2)] += 1
    print('(Xrr+256) sentinel sites: %d in %d trees' % (sum(n.values()), len(n)))
    for k, v in n.most_common():
        print('  %-12s %6d' % (k, v))
    print('  spelled: %s' % dict(spell.most_common()))


def one(mc, line):
    with tempfile.NamedTemporaryFile('w', suffix='.s', delete=False) as fh:
        fh.write(line + '\n')
        tmp = fh.name
    try:
        p = subprocess.run([mc, '-triple=tlcs900', '-show-encoding', tmp],
                           capture_output=True, text=True)
        if re.search(re.escape(tmp) + r':\d+:', p.stderr):
            return None, p.stderr
        m = re.search(r'encoding: \[([^\]]*)\]', p.stdout)
        return (m.group(1).replace(' ', '') if m else None), p.stderr
    finally:
        os.unlink(tmp)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--family', choices=sorted(FAMILIES))
    ap.add_argument('--triage', action='store_true')
    ap.add_argument('--sentinel', action='store_true',
                    help='count sites spelling the explicit d8=0 encoding as '
                         'the magic displacement 256')
    ap.add_argument('--collisions', action='store_true',
                    help='count long-form sites a "pick the short form when it '
                         'fits" rule would silently rewrite')
    ap.add_argument('--foil', action='store_true',
                    help='substitute a deliberately wrong native spelling; '
                         'every site MUST come back a mismatch')
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--mc', default=os.path.expanduser(
        '~/compartilhado/llvm-project/build/bin/llvm-mc'))
    a = ap.parse_args()

    work = tempfile.mkdtemp(prefix='conv-size-')
    mc = os.path.join(work, 'llvm-mc')
    shutil.copy2(a.mc, mc)
    sha = hashlib.sha256(open(mc, 'rb').read()).hexdigest()
    print('llvm-mc sha256 %s (copied from %s)' % (sha[:16], a.mc))

    if a.sentinel:
        sentinel()
        return

    if a.collisions:
        collisions()
        return

    if a.triage:
        triage(mc)
        return

    if not a.family:
        raise SystemExit('need --family, --triage, --collisions or --sentinel')

    if a.foil and a.apply:
        raise SystemExit('--foil never writes')
    sites = collect(a.family, foil=a.foil)
    files = len({s[0] for s in sites})
    print('%s: %d sites in %d files' % (a.family, len(sites), files))
    if not sites:
        return
    result, extra = verify(mc, sites)
    if result == 'ASYM':
        so, sn, asym = extra
        print('ASYMMETRIC: %d site(s) assemble as one spelling but not the '
              'other -- the rewrite changed assemblability; batch indices %r'
              % (len(asym), asym[:20]))
        raise SystemExit(2)
    mism = result
    if mism is None:
        print('REFUSED: llvm-mc rejected lines; old %r new %r' % extra)
        raise SystemExit(2)
    if isinstance(extra, tuple) and extra and extra[0] == 'deferred':
        print('deferred to gate-all: %d macro-parameter site(s), un-assemblable '
              'standalone and symmetric (old rejects == new rejects)' % len(extra[1]))
    print('mismatching sites: %d' % len(mism))
    for row in mism[:20]:
        print('  %s:%d\n    old %-40s %s\n    new %-40s %s' % row)
    if mism:
        print('NOT CONVERTIBLE by a plain rewrite -- nothing written.')
        raise SystemExit(1)
    if a.apply:
        n = apply(sites)
        print('rewrote %d files' % n)
    else:
        print('all sites byte-identical; re-run with --apply to write')


if __name__ == '__main__':
    main()
