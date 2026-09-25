import re, glob, collections, sys
root = sys.argv[1] if len(sys.argv)>1 else 'v7/maincpu'
num_branch = re.compile(rb'^\s+(jr|jrl|calr|call|jp|djnz8?)\s+(?:[a-z]+\s*,\s*)?(?:[a-z]+\s*,\s*)?(-?\d+|0x[0-9a-fA-F]+)\s*(;.*)?$')
sus = re.compile(rb'^\s+(max|min|normal|halt|swi\b|ei\b|di\b|push\s+sr|pop\s+sr|ldf\b|incf|decf|reti|retd|ldx|ex\s+f|scc\b|ld\s+\(\d+:8\)|.*:io\b|nop\b|mirr|link|unlk|bs1|ldc\b|ldcf|stcf|xorcf|orcf|andcf|daa|cpl|zcf|rcf|ccf|scf|pop\s+sr|push\s+f|pop\s+f|ld\s+[a-z]+,\s*\(\d+:8\))')
res = collections.Counter(); ex = collections.defaultdict(list); total=collections.Counter()
for f in glob.glob(root+'/**/*.s', recursive=True):
    L = open(f,'rb').read().split(b'\n')
    for i,l in enumerate(L):
        m = num_branch.match(l)
        if not m: continue
        total[f]+=1
        win = L[max(0,i-6):i+7]
        s = sum(1 for w in win if sus.match(w))
        if s >= 3:
            res[f]+=1
            if len(ex[f])<4: ex[f].append((i+1, l.decode('latin1').strip(), s))
for f,c in res.most_common(40):
    print(c, total[f], f, ex[f][:3])
print('TOTAL suspicious', sum(res.values()), 'of', sum(total.values()))
