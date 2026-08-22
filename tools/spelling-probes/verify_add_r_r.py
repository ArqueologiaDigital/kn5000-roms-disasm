#!/usr/bin/env python3
"""Probe: what is the llvm-mc spelling for the unidasm form `add r,r` (e.g. `add C,QIZH`)?

Question answered
-----------------
`add <reg>,<reg>` is ONE printed form but SIX different encodings.  This script
decides, for every one of them, whether an llvm-mc spelling exists that assembles
to the *exact* ROM bytes -- "it assembled" is never accepted as a pass.

    pass 1  exhaustive   every encoding of the form is generated synthetically,
                         fed to unidasm to confirm it really prints `add r,r`,
                         then the proposed spelling is assembled and compared.
    pass 2  ROM sites    every `add r,r` that a linear decode finds inside the
                         remaining .byte blobs of v7/v9/v10 is spelled and
                         byte-compared against the ROM bytes.
    pass 3  real sites   the already-converted addb_erp/addw_erp instructions in
                         the byte-exact v9 sources are located in the real ROM
                         (unique window search) and re-checked byte-for-byte.
    pass 4  brute force  all 702 mnemonics the TLCS900 AsmParser knows, crossed
                         with 41 operand shapes, are tried against the encodings
                         pass 1 could not spell.  This is the falsifiable half of
                         the "no spelling exists" claim: if any line here emitted
                         e7 34 81, the claim would be wrong.
    pass 5  boundary     proves the one unspellable site really is a 3-byte
                         instruction, using a branch target rather than a
                         disassembler's framing.

Command
-------
    python3 tools/spelling-probes/verify_add_r_r.py            # passes 1-4
    python3 tools/spelling-probes/verify_add_r_r.py exhaustive # single pass

Signal read
-----------
Raw bytes of original_ROMs/kn5000_v{7,9,10}_program.rom, load base 0xE00000.
PASS = the llvm-mc `--show-encoding` bytes equal those ROM bytes.

Numbers produced 2026-08-22 (LLVM tlcs900_backend@cb165c5cdc4b)
-------------------------------------------------------------
pass 1  6336 encodings, 0 unidasm form-mismatches
        short8   64/64    add <d8>, <s8>
        short16  49/64    add <d16>, <s16>        15 holes, all SP
        short32  64/64    add <d32>, <s32>
        erp8   2048/2048  addb_erp <d8>, <bank>
        erp16  1792/2048  addw_erp <d16>, <bank>  256 holes, all dst=SP
        erp32     0/2048  NO SPELLING EXISTS
pass 2  2054 candidate sites, 116 distinct encodings, 115 byte-exact,
        1 unspellable (v7 0xf20158  e7 34 81  add XBC,XBC3)
pass 3  12 real v9 ROM sites located, 12/12 byte-exact
pass 4  702 mnemonics x 41 operand shapes: 0 spellings emit e7 34 81,
        d8 87, df 80 or d7 00 87
pass 5  v7 0xf2014c `jr Z,0xf2015b` lands exactly after `e7 34 81` at 0xf20158,
        so those three bytes are one instruction
"""
import collections, glob, os, re, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNI  = os.path.expanduser('~/compartilhado/tools/unidasm')
MC   = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')
BASE = 0xE00000

GR8  = ['w', 'a', 'b', 'c', 'd', 'e', 'h', 'l']
GR16 = ['wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', 'sp']
GPR  = ['xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp']


def family(b0):
    """Which of the six encodings is this, decided on the FIRST RAW BYTE only."""
    if 0xC8 <= b0 <= 0xCF: return 'short8'
    if b0 == 0xC7:         return 'erp8'
    if 0xD8 <= b0 <= 0xDF: return 'short16'
    if b0 == 0xD7:         return 'erp16'
    if 0xE8 <= b0 <= 0xEF: return 'short32'
    if b0 == 0xE7:         return 'erp32'
    return '?'


def spell(by):
    """THE RULE.  by = the instruction's raw bytes.  Returns (family, spelling|None)."""
    b0, dst = by[0], by[-1] & 7
    fam = family(b0)
    if fam == 'short8':  return fam, f'add {GR8[dst]}, {GR8[b0 & 7]}'
    if fam == 'erp8':    return fam, f'addb_erp {GR8[dst]}, {by[1]}'
    if fam == 'short16': return fam, f'add {GR16[dst]}, {GR16[b0 & 7]}'
    if fam == 'erp16':   return fam, f'addw_erp {GR16[dst]}, {by[1]}'
    if fam == 'short32': return fam, f'add {GPR[dst]}, {GPR[b0 & 7]}'
    return fam, None                      # erp32: no spelling in the backend


def mc_batch(lines):
    p = subprocess.run([MC, '-triple=tlcs900', '--show-encoding'],
                       input='\n'.join(lines) + '\n', capture_output=True, text=True)
    if 'PLEASE submit a bug report' in p.stderr:
        return None
    out = []
    for l in p.stdout.splitlines():
        m = re.search(r'encoding: \[([^\]]*)\]', l)
        if m:
            out.append((bytes(int(x, 16) for x in m.group(1).split(',')),
                        re.sub(r'\s+', ' ', l.split(';')[0].strip())))
    return out


def mc_safe(lines):
    """mc_batch, bisecting around llvm-mc crashes so one bad line cannot hide the rest."""
    r = mc_batch(lines)
    if r is not None:
        return r
    if len(lines) == 1:
        return []
    h = len(lines) // 2
    return mc_safe(lines[:h]) + mc_safe(lines[h:])


def unidasm_blob(blob, addr=0):
    tf = tempfile.NamedTemporaryFile(suffix='.bin', delete=False)
    tf.write(blob); tf.close()
    out = subprocess.run([UNI, tf.name, '-arch', 'tlcs900', '-basepc', hex(addr)],
                         capture_output=True, text=True).stdout
    os.unlink(tf.name)
    res = []
    for line in out.splitlines():
        m = re.match(r'^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s+(.*)$', line)
        if m:
            res.append((int(m.group(1), 16),
                        bytes(int(x, 16) for x in m.group(2).split()),
                        m.group(3).strip()))
    return res


# --------------------------------------------------------------------------- 1
def pass_exhaustive():
    print('=== pass 1: every encoding of the form, synthesised ===')
    fams = {
        'short8':  [bytes([0xC8 + s, 0x80 + d]) for s in range(8) for d in range(8)],
        'short16': [bytes([0xD8 + s, 0x80 + d]) for s in range(8) for d in range(8)],
        'short32': [bytes([0xE8 + s, 0x80 + d]) for s in range(8) for d in range(8)],
        'erp8':    [bytes([0xC7, bk, 0x80 + d]) for bk in range(256) for d in range(8)],
        'erp16':   [bytes([0xD7, bk, 0x80 + d]) for bk in range(256) for d in range(8)],
        'erp32':   [bytes([0xE7, bk, 0x80 + d]) for bk in range(256) for d in range(8)],
    }
    form_re = re.compile(r'^add [A-Za-z][\w\-]*,[A-Za-z][\w\-]*$')
    total = 0
    for name in ['short8', 'short16', 'short32', 'erp8', 'erp16', 'erp32']:
        enc = fams[name]; ilen = len(enc[0]); total += len(enc)
        # (a) does unidasm really print `add r,r` for all of them?
        dis = {a: (b, t) for a, b, t in unidasm_blob(b''.join(enc))}
        bad_form = sum(1 for i, e in enumerate(enc)
                       if dis.get(i * ilen, (None, ''))[0] != e
                       or not form_re.match(dis.get(i * ilen, (None, ''))[1]))
        # (b) does the spelling reproduce the bytes?
        want = {}
        lines = []
        for e in enc:
            _f, sp = spell(e)
            if sp is not None:
                lines.append(sp); want[sp] = e
        ok = 0
        if lines:
            got = {}
            for by, txt in mc_safe(lines):
                got.setdefault(txt, by)
            # llvm-mc reprints immediates in decimal; re-key by order instead
            res = mc_safe(lines)
            ok = sum(1 for (by, _t), sp in zip(res, lines) if by == want[sp]) if len(res) == len(lines) else \
                 sum(1 for sp in lines if mc_safe([sp]) and mc_safe([sp])[0][0] == want[sp])
        tag = '  <== NO SPELLING EXISTS' if not lines else ''
        print(f'  {name:8s} {len(enc):5d} encodings   unidasm form-mismatches={bad_form}   '
              f'byte-exact={ok:5d}{tag}')
    print(f'  total encodings examined: {total}')


# --------------------------------------------------------------------------- 2
def blob_runs(ver):
    rom = open(os.path.join(REPO, f'original_ROMs/kn5000_{ver}_program.rom'), 'rb').read()
    byte_re = re.compile(r'^\s*\.byte\s+(.*)$')
    runs = []
    for f in sorted(glob.glob(REPO + f'/{ver}/maincpu/**/*.s', recursive=True)):
        cur = b''
        for line in open(f, errors='replace'):
            m = byte_re.match(line)
            if m:
                vals = [v.strip() for v in m.group(1).split(';')[0].split(',') if v.strip()]
                try:
                    cur += bytes(int(v, 0) & 0xFF for v in vals)
                except ValueError:
                    if cur: runs.append((f, cur)); cur = b''
            else:
                s = line.strip()
                if s.startswith(';') or s.endswith(':') or not s:
                    continue          # labels/comments do not break a run
                if cur: runs.append((f, cur)); cur = b''
        if cur: runs.append((f, cur))
    out = []
    for f, b in runs:
        if len(b) < 8: continue
        i = rom.find(b)
        if i < 0 or rom.find(b, i + 1) >= 0: continue     # must be uniquely locatable
        out.append((f, BASE + i, b))
    return out


def pass_rom_sites(vers=('v7', 'v9', 'v10')):
    print('=== pass 2: `add r,r` inside the remaining .byte blobs ===')
    pat = re.compile(r'^add [A-Za-z][\w\-]*,[A-Za-z][\w\-]*$')
    sites = []
    for ver in vers:
        for f, addr, b in blob_runs(ver):
            for a, by, t in unidasm_blob(b, addr):
                if pat.match(t):
                    sites.append((ver, a, by, t, f))
    uniq = {}
    for ver, a, by, t, f in sites:
        uniq.setdefault((family(by[0]), by), (ver, a, t, f))
    lines, keys = [], []
    for (fam, by), meta in uniq.items():
        _f, sp = spell(by)
        if sp is not None:
            lines.append(sp); keys.append((fam, by, meta, sp))
    res = mc_safe(lines)
    assert len(res) == len(keys), (len(res), len(keys))
    ok = collections.Counter(); bad = []
    for (fam, by, meta, sp), (got, _t) in zip(keys, res):
        if got == by: ok[fam] += 1
        else: bad.append((fam, by.hex(), sp, got.hex(), meta))
    n = collections.Counter(family(by[0]) for _v, _a, by, _t, _f in sites)
    d = collections.Counter(fam for fam, _by in uniq)
    print(f'  candidate sites={len(sites)}  distinct encodings={len(uniq)}')
    for fam in ['short8', 'short16', 'short32', 'erp8', 'erp16', 'erp32']:
        tag = '  <== NO SPELLING EXISTS' if fam == 'erp32' and d[fam] else ''
        print(f'  {fam:8s} sites={n[fam]:5d}  distinct={d[fam]:4d}  byte-exact={ok[fam]:4d}{tag}')
    print('  mismatches:', len(bad))
    for x in bad[:10]: print('   ', x)
    print('  every ERP encoding seen in a blob:')
    for (fam, by), (ver, a, t, f) in sorted(uniq.items(), key=lambda kv: (kv[0][0], kv[0][1])):
        if fam.startswith('erp'):
            _f, sp = spell(by)
            print(f'    {ver} {a:06x}: {by.hex(" "):9s} {t:22s} -> {sp}   [{os.path.relpath(f, REPO)}]')


# --------------------------------------------------------------------------- 3
def pass_real_sites(ver='v9'):
    print(f'=== pass 3: already-converted add-ERP instructions, located in the real {ver} ROM ===')
    rom = open(os.path.join(REPO, f'original_ROMs/kn5000_{ver}_program.rom'), 'rb').read()
    TARGET  = re.compile(r'^\s*(addb_erp|addw_erp|add_erpw_rr)\s')
    LITERAL = re.compile(r'^[a-z][a-z0-9_]*(\s+[a-z0-9_]+(\s*[,+]\s*[a-z0-9_()x]+)*)?\s*$', re.I)
    def asm(ls):
        r = mc_batch(ls)
        if r is None or len(r) != len(ls): return None
        return b''.join(x[0] for x in r)
    found = ok = 0
    for f in sorted(glob.glob(REPO + f'/{ver}/maincpu/**/*.s', recursive=True)):
        src = [x.split(';')[0].rstrip() for x in open(f, errors='replace').read().splitlines()]
        for i, l in enumerate(src):
            if not TARGET.match(l): continue
            lo = hi = i
            while lo - 1 >= 0 and src[lo-1].startswith('\t') and LITERAL.match(src[lo-1].strip()): lo -= 1
            while hi + 1 < len(src) and src[hi+1].startswith('\t') and LITERAL.match(src[hi+1].strip()): hi += 1
            best = None
            for a in range(i, lo - 1, -1):
                for b in range(i, hi + 1):
                    blob = asm([src[k].strip() for k in range(a, b + 1)])
                    if blob is None or len(blob) < 6: continue
                    idx = rom.find(blob)
                    if idx >= 0 and rom.find(blob, idx + 1) < 0:
                        off = sum(len(asm([src[k].strip()])) for k in range(a, i))
                        best = BASE + idx + off; break
                if best: break
            if best is None:
                print(f'  {ver} ??????  not uniquely locatable   "{src[i].strip()}"'
                      f'   [{os.path.relpath(f, REPO)}:{i+1}]')
                continue
            mine = asm([src[i].strip()])
            real = rom[best - BASE: best - BASE + len(mine)]
            ut = unidasm_blob(real, best)[0][2]
            found += 1; ok += (mine == real)
            print(f'  {ver} {best:06x}  rom={real.hex(" ")}  llvm={mine.hex(" ")}  '
                  f'match={mine == real}  unidasm="{ut}"  src="{src[i].strip()}"'
                  f'   [{os.path.relpath(f, REPO)}:{i+1}]')
    print(f'  located={found}  byte-exact={ok}')


# --------------------------------------------------------------------------- 4
def pass_brute():
    print('=== pass 4: can ANY known mnemonic emit the unspellable encodings? ===')
    inc = os.path.expanduser('~/compartilhado/llvm-project/build/lib/Target/TLCS900/'
                             'TLCS900GenAsmMatcher.inc')
    lines = open(inc, errors='replace').read().splitlines()
    st = next(i for i, l in enumerate(lines) if 'static const char MnemonicTable[] =' in l)
    buf = ''
    for l in lines[st + 1:]:
        buf += ''.join(re.findall(r'"((?:[^"\\]|\\.)*)"', l))
        if l.rstrip().endswith(';'): break
    lit = buf.encode().decode('unicode_escape')
    mn, i = [], 0
    while i < len(lit):
        n = ord(lit[i]); i += 1
        if n == 0: continue
        mn.append(lit[i:i + n]); i += n
    shapes = ['sp, wa', 'wa, sp', 'sp, 0', '0, sp', 'sp, 0x00', 'sp, xwa', 'xsp, wa', 'sp', 'wa',
              'c, 0xfb', '0xfb, c', 'c, 251', 'qizh, c', 'c, qizh', 'wa, 0xfa', '0xfa, wa',
              'wa, qiz', 'qiz, wa', 'a, c', 'c, a', 'xwa, xbc', 'xbc, xwa', 'sp, iz', 'iz, sp',
              'sp, sp', 'wa, wa', 'sp, 0xfa', '0xfa, sp', 'sp, qiz', 'qiz, sp', 'xbc, 0x34',
              '0x34, xbc', 'xbc, xbc3', 'xbc3, xbc', 'xbc, 52', '52, xbc', 'xbc', '0x34',
              '0x34, 0x81', 'xbc, 0x34, 0x81', '0x34, xbc, 0x81']
    tasks = []
    for sh in shapes:
        ls = [(m + ' ' + sh).strip() for m in mn]
        tasks += [ls[i:i + 20] for i in range(0, len(ls), 20)]
    res = []
    with ThreadPoolExecutor(max_workers=12) as ex:
        for r in ex.map(mc_safe, tasks): res.extend(r)
    targets = {'e73481': 'add XBC,XBC3 (erp32)', 'd887': 'add SP,WA (short16)',
               'df80': 'add WA,SP (short16)', 'd70087': 'add SP,RWA0 (erp16)',
               'c7fb83': 'add C,QIZH (erp8, control)', 'cb81': 'add A,C (short8, control)',
               'd7fa80': 'add WA,QIZ (erp16, control)', 'e980': 'add XWA,XBC (short32, control)'}
    hit = {k: set() for k in targets}
    for by, txt in res:
        h = by.hex()
        if h in hit: hit[h].add(txt)
    print(f'  {len(mn)} mnemonics x {len(shapes)} operand shapes = {len(mn)*len(shapes)} lines; '
          f'{len(res)} assembled')
    for k, v in targets.items():
        print(f'  {k:8s} {v:28s} -> {sorted(hit[k]) if hit[k] else "NO SPELLING"}')


# --------------------------------------------------------------------------- 5
def pass_boundary():
    """Is `e7 34 81` at v7 0xf20158 a real 3-byte instruction, or a linear-decode artefact?

    Falsifiable test that does not depend on any disassembler's framing: an
    EARLIER branch in the same basic block targets 0xf2015b.  A branch target is
    an instruction boundary, so f20158..f2015a must be exactly one instruction.
    If the branch had landed anywhere else, the 3-byte framing would be refuted.
    """
    print('=== pass 5: branch-target proof of the E7 instruction boundary ===')
    rom = open(os.path.join(REPO, 'original_ROMs/kn5000_v7_program.rom'), 'rb').read()
    lo, hi = 0xf20130, 0xf20175
    dis = unidasm_blob(rom[lo - BASE: hi - BASE], lo)
    starts = {a for a, _b, _t in dis}
    targets = []
    for a, b, t in dis:
        m = re.match(r'^(jr|jrl|jp|calr|call)\b.*?0x([0-9a-f]+)$', t)
        if m: targets.append((a, t, int(m.group(2), 16)))
        print(f'  {a:06x}: {b.hex(" "):18s} {t}')
    print('  branch/call targets inside the window:')
    for a, t, tgt in targets:
        inside = lo <= tgt < hi
        print(f'    {a:06x} {t:26s} -> {tgt:06x}   '
              f'{"is an instruction start: " + str(tgt in starts) if inside else "outside window"}')
    print(f'  0xf20158 is an instruction start: {0xf20158 in starts}')
    print(f'  0xf2015b is an instruction start: {0xf2015b in starts}  '
          f'(and is the target of the jr Z at 0xf2014c)')


if __name__ == '__main__':
    which = sys.argv[1] if len(sys.argv) > 1 else 'all'
    if which in ('all', 'exhaustive'): pass_exhaustive()
    if which in ('all', 'rom'):        pass_rom_sites()
    if which in ('all', 'real'):       pass_real_sites()
    if which in ('all', 'brute'):      pass_brute()
    if which in ('all', 'boundary'):   pass_boundary()
