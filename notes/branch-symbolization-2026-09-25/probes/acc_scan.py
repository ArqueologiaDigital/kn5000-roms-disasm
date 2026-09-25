import re, glob, collections, json, sys
S=sys.argv[1]; img=sys.argv[2]
d=json.load(open(f'{S}/symbr/{img}.json'))
refused=set()
for k,v in d['report'].items():
    if k in ('boundary-data','boundary-incbin'): continue
    for x in v: refused.add(x['src'])
num_branch = re.compile(rb'^\s+(jr|jrl|calr|call|jp|djnz8?)\s+(?:[a-z]+\s*,\s*)?(?:[a-z]+\s*,\s*)?(-?\d+|0x[0-9a-fA-F]+)\s*(;.*)?$')
sus = re.compile(rb'^\s*(?:[A-Za-z_][\w.]*:\s*)?(max\b|min\b|normal\b|halt\b|swi\b|ei\b|di\b|push\s+sr|pop\s+sr|ldf\b|incf\b|decf\b|reti\b|retd\b|ldx\b|ex\s+f|.*:io\b|aligned_string|\.ascii|\.asciz|\.string|push_a|pop_a|push\s+f\b|pop\s+f\b)')
res=collections.Counter(); ex=collections.defaultdict(list); tot=collections.Counter()
for f in glob.glob('**/*.s', recursive=True):
    L=open(f,'rb').read().split(b'\n')
    for i,l in enumerate(L):
        if not num_branch.match(l): continue
        key=f'{f}:{i+1}'
        if key in refused: continue
        tot[f]+=1
        win=L[max(0,i-5):i+6]
        s=sum(1 for w in win if sus.match(w))
        if s>=2:
            res[f]+=1
            if len(ex[f])<6: ex[f].append((i+1,l.decode('latin1').strip(),s))
for f,c in res.most_common(30): print(c,tot[f],f,ex[f][:4])
print('flagged',sum(res.values()),'of accepted-candidates',sum(tot.values()))
