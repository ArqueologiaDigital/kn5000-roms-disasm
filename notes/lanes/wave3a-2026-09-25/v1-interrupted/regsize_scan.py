# regsize_scan.py: from tree_audit.tsv, list source lines whose register NAMES differ from MAME's
# reading in SIZE only (xwa vs wa vs a ...): the "32-bit name encoded by index" lie class.
import re, collections
R32="xwa xbc xde xhl xix xiy xiz xsp".split(); R16="wa bc de hl ix iy iz sp".split(); R8="w a b c d e h l".split()
ALL=set(R32+R16+R8)
def regs(t):
    return [x for x in re.findall(r'[A-Za-z][A-Za-z0-9]*', t.lower()) if x in ALL]
cnt=collections.Counter(); ex={}
for line in open('tree_audit.tsv',encoding='latin-1'):
    p=line.rstrip('\n').split('\t')
    v,loc=p[0],p[1]; mame=p[-1]; hx=p[-2]; src=' '.join(p[2:-2])
    mn=src.split()[0].lower()
    ops=src[len(src.split()[0]):]
    mm,_,mo=mame.partition(' ')
    a=regs(ops); b=regs(mo)
    if len(a)!=len(b) or a==b: continue
    diff=[(x,y) for x,y in zip(a,b) if x!=y]
    # size-only: same index in a different class
    def idx(r):
        for L in (R32,R16,R8):
            if r in L: return L.index(r)
    sz=[(x,y) for x,y in diff if (x in R32)!=(y in R32) or (x in R16)!=(y in R16)]
    if not sz: continue
    key=(mn, tuple(sorted(set((('32' if x in R32 else '16' if x in R16 else '8'),('32' if y in R32 else '16' if y in R16 else '8')) for x,y in sz))))
    cnt[key]+=1; ex.setdefault(key,(loc,src,hx,mame))
for k,n in cnt.most_common():
    print(n,k,ex[k])
