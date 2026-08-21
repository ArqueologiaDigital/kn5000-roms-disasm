import re,sys
f='/home/fsanches/compartilhado/kn5000-roms-disasm/v142/subcpu/kn5000_subprogram_v142.s'
L=open(f,encoding='latin-1').read().split('\n')
lab=re.compile(r'^([A-Za-z_][\w]*):')
def enclosing(n):
    for i in range(n-1,-1,-1):
        m=lab.match(L[i])
        if m: return m.group(1), i+1
    return None,None
for n in [3990,4066,4080,4405,17230,17241,17835,33331,44822,44863,44883,44912]:
    lb,ln=enclosing(n)
    print('line %5d  in %-45s (label@%d)  text=%r'%(n,lb,ln,L[n-1][:70]))
