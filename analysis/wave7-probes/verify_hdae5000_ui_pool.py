#!/usr/bin/env python3
from collections import Counter, defaultdict
import bisect

BASE = 0x280000
POOL, POOL_END = 0x29DC12, 0x2A5D2C
PTRTAB, NAMETAB, CLASSTAB = 0x2A5D2C, 0x2A6984, 0x2F9832
NOBJ = 789
CAP = {(0x0160,0x001B):[0x1C], (0x0160,0x0026):[0x1E,0x1A], (0x0160,0x002B):[0x16],
       (0x0160,0x0030):[0x16], (0x0160,0x0036):[0x1A], (0x0160,0x0037):[0x1A],
       (0x0160,0x003D):[0x2A], (0x0160,0x003E):[0x28], (0x0160,0x003F):[0x2A],
       (0x0160,0x0041):[0x2A], (0x016A,0x0002):[0x22], (0x016A,0x0006):[0x22],
       (0x016A,0x0007):[0x22]}

rom = open('original_ROMs/hd-ae5000_v2_06i.ic4','rb').read()
u16 = lambda a: int.from_bytes(rom[a-BASE:a-BASE+2],'little')
u32 = lambda a: int.from_bytes(rom[a-BASE:a-BASE+4],'little')
def cstr(a):
    b = rom[a-BASE:]; z = b.find(0); return b[:z].decode('latin1','replace')

ptrs  = [u32(PTRTAB+4*i) for i in range(NOBJ)]
names = [cstr(u32(NAMETAB+4*i)) if u32(NAMETAB+4*i) else '' for i in range(NOBJ)]
assert u32(PTRTAB+4*NOBJ) == 0, 'table terminator'
idx   = [i for i,p in enumerate(ptrs) if POOL <= p <= POOL_END-1]
S     = [ptrs[i] for i in idx]
E     = S[1:] + [POOL_END]
P     = dict(zip(idx, S))
print('records in pool: %d   RAM descriptors: %d   span 0x%06X-0x%06X = %d bytes'
      % (len(S), NOBJ-len(S), POOL, POOL_END-1, POOL_END-POOL))
print('lengths: min %d max %d, %d distinct, commonest %s'
      % (min(e-s for s,e in zip(S,E)), max(e-s for s,e in zip(S,E)),
         len(set(e-s for s,e in zip(S,E))),
         Counter(e-s for s,e in zip(S,E)).most_common(7)))
print('ascending:', all(S[k] < S[k+1] for k in range(len(S)-1)), 'first 0x%06X last 0x%06X' % (S[0], S[-1]))
print('sum lengths', sum(e-s for s,e in zip(S,E)), 'span', POOL_END-POOL)
print('all even lengths:', all((e-s) % 2 == 0 for s,e in zip(S,E)))

print('\n-- link symmetry at each candidate offset (proposed: +0x04) --')
for d in range(0, 0x18, 2):
    par = {i:u16(p+d)   for i,p in P.items()}; ch = {i:u16(p+d+2) for i,p in P.items()}
    nx  = {i:u16(p+d+4) for i,p in P.items()}; pv = {i:u16(p+d+6) for i,p in P.items()}
    t1=o1=t2=o2=0
    for i in P:
        j = nx[i]
        if j != 0xFFFF and j in P: t1 += 1; o1 += (pv[j] == i)
        c = ch[i]
        if c != 0xFFFF and c in P: t2 += 1; o2 += (par[c] == i)
    print('  +0x%02X  next/prev %4d/%-4d   child/parent %4d/%-4d%s'
          % (d, o1, t1, o2, t2, '   <== proposed' if d == 4 else ''))
roots = [i for i in P if u16(P[i]+4) == 0xFFFF]
print('  roots (parent==0xFFFF): %d, e.g. %s'
      % (len(roots), [names[i] for i in roots[:12] if names[i]]))

print('\n-- bounding-box test x1<=x2<=321, y1<=y2<=239 (proposed: +0x0E) --')
for off in range(4, 0x1E, 2):
    bad = sum(not (u16(p+off) <= u16(p+off+4) <= 321 and u16(p+off+2) <= u16(p+off+6) <= 239)
              for p in S)
    print('  +0x%02X  %4d violations of %d%s' % (off, bad, len(S), '   <== proposed' if off == 0x0E else ''))
for k in (0,1):
    p = S[k]; i = idx[k]
    print('  record #%d %s box %d,%d-%d,%d' % (i, names[i], u16(p+0x0E),u16(p+0x10),u16(p+0x12),u16(p+0x14)))

print('\n-- class ids vs HDAE5000_ClassName_Table (0x%06X) --' % CLASSTAB)
cn = [cstr(u32(CLASSTAB+4*k)) for k in range(14)]
print('  classname table entries:', cn, 'terminator word 0x%08X' % u32(CLASSTAB+4*13))
bycls = defaultdict(list)
for i,p in P.items(): bycls[(u16(p+2), u16(p))].append(i)
hi = Counter(k[0] for k in bycls)
print('  high halves:', {hex(h):(sum(len(bycls[k]) for k in bycls if k[0]==h), sum(1 for k in bycls if k[0]==h)) for h in hi})
def anc(i):
    out=[]; seen=set()
    while i in P and i not in seen:
        seen.add(i); out.append(names[i] or '#%d'%i); i = u16(P[i]+4)
        if i == 0xFFFF: break
    return ' <- '.join(out)
for c in sorted(k for k in bycls if k[0] == 0x016A):
    ex = [names[i] for i in bycls[c] if names[i]][:4] or [anc(bycls[c][0])]
    nm = cn[c[1]] if c[1] < len(cn) else '??'
    print('  016A:%04X n=%-4d ClassName_Table[%d]=%-22s %s' % (c[1], len(bycls[c]), c[1], nm, ex))

print('\n-- body length per class and byte accounting --')
F = {}
for p,e in zip(S,E):
    c = (u16(p+2), u16(p))
    f = min(u32(p+s) for s in CAP[c]) - p if c in CAP else e-p
    F.setdefault(c, Counter())[f] += 1
nonconst = [c for c in F if len(F[c]) != 1]
print('  classes: %d   non-constant body length: %d %s'
      % (len(F), len(nonconst), ['%04X:%04X %s' % (c[0], c[1], dict(F[c])) for c in nonconst]))
FF = {c: min(F[c]) for c in F}
sb = ss = pd = 0; viol = []
for p,e in zip(S,E):
    c = (u16(p+2), u16(p)); f = FF[c]; sb += f
    a = rom[p-BASE+f : e-BASE]; k = 0
    while k < len(a):
        z = a.find(0, k)
        if z < 0: viol.append((hex(p),'unterminated')); break
        if not all(32 <= ch < 127 for ch in a[k:z]): viol.append((hex(p),'non-ascii')); break
        ss += z-k+1; k = z+1
        if k == len(a)-1 and a[k] == 0: pd += 1; k += 1
print('  bodies %d + inline strings %d + pad %d = %d (pool %d); violations %s'
      % (sb, ss, pd, sb+ss+pd, POOL_END-POOL, viol))
ncap = sum(len(CAP[c]) for p in S for c in [(u16(p+2), u16(p))] if c in CAP)
print('  caption slots: %d in %d records' % (ncap, sum(1 for p in S if (u16(p+2),u16(p)) in CAP)))
inside = out = 0
for p,e in zip(S,E):
    c = (u16(p+2), u16(p))
    for s in CAP.get(c, []):
        t = u32(p+s)
        if p <= t < e: inside += 1
        else: out += 1
print('  caption targets inside own record: %d, outside: %d' % (inside, out))

print('\n-- the five legacy labels, located against the record boundaries --')
for nm, a in [('HDAE5000_UI_Descriptors',0x29DC14), ('HDAE5000_UI_Page_Titles',0x29DF8A),
              ('HDAE5000_Panel_Save_UI',0x29F9B2), ('HDAE5000_Credits',0x2A477C),
              ('HDAE5000_Demo_Data',0x2A5634)]:
    k = bisect.bisect_right(S, a) - 1
    p, i = S[k], idx[k]; c = (u16(p+2), u16(p))
    cap = c in CAP and any(u32(p+s) == a for s in CAP[c])
    capoff = [s for s in CAP.get(c,[]) if u32(p+s)==a]
    print('  %-24s 0x%06X = record #%d (0x%06X-0x%06X len %d, class %04X:%04X, name %r) +0x%02X  %s capslot %s'
          % (nm, a, i, p, E[k]-1, E[k]-p, c[0], c[1], names[i], a-p,
             'ON ITS INLINE CAPTION %r' % cstr(a) if cap else 'MID-RECORD', capoff))
    par = u16(p+4)
    print('        parent #%d %r' % (par, names[par] if par != 0xFFFF and par < NOBJ else ''))

print('\n-- RAM descriptor init image (HDAE5000_WindowGeometry_Init records) --')
ram = [(i,p) for i,p in enumerate(ptrs) if p and not (POOL <= p < POOL_END)]
print('  RAM ptr range 0x%06X..0x%06X, count %d' % (ram[0][1], ram[-1][1], len(ram)))
sz  = [ram[k+1][1]-ram[k][1] for k in range(len(ram)-1)] + [0x24]
print('  deltas:', sz)
def expect(t):
    e = {}
    for i,p in P.items():
        if u16(p+6)   == t: e['parent'] = i
        if u16(p+4)   == t: e.setdefault('child', i)
        if u16(p+8)   == t: e['prev'] = i
        if u16(p+0xa) == t: e['next'] = i
    return e
a = 0x2F9C4C; ok = tot = 0; rows=[]
for (i,rp), n in zip(ram, sz):
    L = {'parent':u16(a+4), 'child':u16(a+6), 'next':u16(a+8), 'prev':u16(a+0xa)}
    ex = expect(i)
    for k, v in ex.items(): tot += 1; ok += (L[k] == v)
    rows.append((i, names[i], hex(a), n, '%04X:%04X'%(u16(a+2),u16(a)), L, ex))
    a += n
for r in rows: print('   ', r)
print('  20 records 0x2F9C4C-0x%06X; link agreement with the ROM tree: %d/%d' % (a-1, ok, tot))
print('\nOK' if not viol and ok == tot else '\nFAILED')
