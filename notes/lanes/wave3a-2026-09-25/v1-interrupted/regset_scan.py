# regset_scan.py: for every non-OK tree_audit row, compare the MULTISET of standard register names
# (source text vs MAME reading). A difference means the source text names a register the CPU does not
# use (or omits one it does). Implicit-operand pseudos (push_a etc.) are expected differences.
import re, collections
R="xwa xbc xde xhl xix xiy xiz xsp wa bc de hl ix iy iz sp w a b c d e h l qwa qbc qde qhl qix qiy qiz qsp qw qa qb qc qd qe qh ql".split()
RS=set(R)
def regs(t):
    t=re.sub(r';.*','',t)
    return sorted(x for x in re.findall(r'[A-Za-z][A-Za-z0-9]*', t.lower()) if x in RS)
c=collections.Counter(); ex={}
for line in open('tree_audit.tsv',encoding='latin-1'):
    p=line.rstrip('\n').split('\t')
    v=p[0]; mame=p[-1]; src=' '.join(p[2:-2])
    mn=src.split()[0].lower()
    ops=src[len(src.split()[0]):]
    mm,_,mo=mame.partition(' ')
    # condition codes that collide with register names: c (carry) in jr/jp/call/ret/scc
    a=regs(ops); b=regs(mo)
    if mm.lower() in ('jr','jrl','jp','call','ret','scc','djnz') or mn.startswith(('jr','jp','call','ret','scc')):
        a=[x for x in a if x!='c']; b=[x for x in b if x!='c']
    if a!=b:
        k=(mn, mm.lower()); c[k]+=1; ex.setdefault(k,(p[1],src,p[-2],mame))
tot=sum(c.values())
print('rows with register-name multiset difference:',tot)
for k,n in c.most_common(60): print(n,k,ex[k])
