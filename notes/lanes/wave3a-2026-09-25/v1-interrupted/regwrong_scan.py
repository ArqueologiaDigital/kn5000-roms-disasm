# regwrong_scan.py: rows where the SOURCE names a register that MAME's reading of the same bytes
# does not contain at all (source register set minus MAME register set is non-empty).
import re, collections
R="xwa xbc xde xhl xix xiy xiz xsp wa bc de hl ix iy iz sp w a b c d e h l qwa qbc qde qhl qix qiy qiz qsp qw qa qb qc qd qe qh ql".split()
RS=set(R)
def regs(t):
    return [x for x in re.findall(r'[A-Za-z][A-Za-z0-9]*', t.lower()) if x in RS]
c=collections.Counter(); ex={}
for line in open('tree_audit.tsv',encoding='latin-1'):
    p=line.rstrip('\n').split('\t')
    mame=p[-1]; src=' '.join(p[2:-2])
    mn=src.split()[0].lower()
    ops=src[len(src.split()[0]):]
    mm,_,mo=mame.partition(' ')
    a=collections.Counter(regs(ops)); b=collections.Counter(regs(mo))
    if mm.lower() in ('jr','jrl','jp','call','ret','scc') or mn.startswith(('jr','jp','call','ret','scc')):
        a.pop('c',None); b.pop('c',None)
    extra=a-b
    if extra:
        k=(mn, mm.lower(), tuple(sorted(extra))); c[k]+=1; ex.setdefault(k,(p[1],src,p[-2],mame))
print('rows where source names a register MAME does not read:',sum(c.values()))
for k,n in c.most_common(80): print(n,k,ex[k])
