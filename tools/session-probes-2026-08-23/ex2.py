import importlib.util, collections, os, sys
REPO='/home/fsanches/compartilhado/kn5000-roms-disasm'; os.chdir(REPO)
_s=importlib.util.spec_from_file_location('crr',REPO+'/scripts/converters/convert_reachable_ranges.py')
crr=importlib.util.module_from_spec(_s); _s.loader.exec_module(crr)
_c=importlib.util.spec_from_file_location('_cache',REPO+'/tools/spelling-probes/refusal-buckets/_cache.py')
cm=importlib.util.module_from_spec(_c); _c.loader.exec_module(cm)
which=sys.argv[1] if len(sys.argv)>1 else 'seed'
tg,prov=cm.targets(which); print(prov)
dec=cm.load(crr,tg,verbose=False); raw=cm.load_raw(crr,tg,verbose=False)
def stop(t):
    L=raw[t]['lines']; run=raw[t]['run']; consumed=0
    for i,(a,n,x) in enumerate(L):
        mn=x.split()[0].lower() if x.split() else ''
        if mn=='db': return 'db', consumed, n, i
        consumed+=n
        if mn in crr.TERMINATORS: return 'terminator', consumed, 0, i
    if run>=16384: return 'limit', consumed, 0, len(L)
    return 'run_end', consumed, 0, len(L)
b1=[t for t in tg if len(dec[t])<3]
b2=[]
for t in tg:
    ins=dec[t]
    if len(ins)<3: continue
    span=sum(n for _,n,_ in ins); run=raw[t]['run']
    ends_at_code = span==run
    last=ins[-1][2].strip()
    if last.split()[0].lower() not in crr.TERMINATORS and not crr.UNCOND_JUMP.match(last) and not ends_at_code:
        b2.append(t)
print('bucket1',len(b1),'bucket2',len(b2))
for name,bk in (('B1',b1),('B2',b2)):
    c=collections.Counter(); cb=collections.Counter()
    for t in bk:
        r,cons,dbn,i=stop(t)
        span=sum(n for _,n,_ in dec[t])
        key=(r,)
        c[r]+=1; cb[r]+=span
    print(name, dict(c), 'bytes', dict(cb))
# bucket1 breakdown by n_insns and stop
print('--- B1 detail')
d=collections.Counter()
for t in b1:
    r,_,_,_=stop(t); d[(len(dec[t]),r)]+=1
for k in sorted(d): print('  ',k,d[k])
print('--- B2 detail: db byte at stop')
db=collections.Counter()
for t in b2:
    r,cons,dbn,i=stop(t)
    if r!='db': db[(r,)] +=1; continue
    a=raw[t]['lines'][i][0]
    rom=None
    db[(raw[t]['lines'][i][2], )]+=1
print(db.most_common(20))
