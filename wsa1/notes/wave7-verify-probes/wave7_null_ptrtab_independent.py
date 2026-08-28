# Independent PTRTAB null: 2+ consecutive LE32 words inside the span window,
# scanned over the proven-instruction corpus.
import re, os
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'wave7_null_corpus_independent.py')).read().split('print("instruction lines')[0])
LO,HI=0xFAD800,0xFB2000
def w32(a): return int.from_bytes(rom[a-BASE:a-BASE+4],"little")
fp=[]
for a,e in runs:
    p=a
    while p<=e-8:
        k=0;q=p
        while q<=e-4 and (LO<=w32(q)<HI or w32(q)==0xFFFFFFFF):
            k+=1;q+=4
        # first word must be a real pointer
        if k>=2 and w32(p)!=0xFFFFFFFF:
            fp.append((p,k)); p=q
        else:
            p+=1
print("PTRTAB>=2 window=span false positives over corpus:",len(fp),fp[:10])
# ident >=12
def identrun(a,e,n):
    out=[];p=a
    while p<e:
        q=p+1
        while q<e and rom[q-BASE]==(rom[p-BASE]+(q-p)) and rom[p-BASE]+(q-p)<=0xFF: q+=1
        if q-p>=n: out.append((p,q-p))
        p=max(q,p+1)
    return out
ic=[]
for a,e in runs: ic+=identrun(a,e,12)
print("IDENT>=12 false positives:",len(ic),ic[:5])
ic8=[]
for a,e in runs: ic8+=identrun(a,e,8)
print("IDENT>=8 false positives:",len(ic8),[(hex(x),y) for x,y in ic8[:6]])
