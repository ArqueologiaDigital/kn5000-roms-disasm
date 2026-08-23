import importlib.util, collections, os, sys
REPO='/home/fsanches/compartilhado/kn5000-roms-disasm'; os.chdir(REPO)
_s=importlib.util.spec_from_file_location('crr',REPO+'/scripts/converters/convert_reachable_ranges.py')
crr=importlib.util.module_from_spec(_s); _s.loader.exec_module(crr)
_c=importlib.util.spec_from_file_location('_cache',REPO+'/tools/spelling-probes/refusal-buckets/_cache.py')
cm=importlib.util.module_from_spec(_c); _c.loader.exec_module(cm)
tg,prov=cm.targets('seed')
dec=cm.load(crr,tg,verbose=False); raw=cm.load_raw(crr,tg,verbose=False)
spec=importlib.util.spec_from_file_location('spans','scripts/analysis/v7_undisassembled_spans.py')
spans=importlib.util.module_from_spec(spec); spec.loader.exec_module(spans)
terr=spans.territory(spans.runs('v7/maincpu/kn5000_v7_program.s','v7/maincpu'))
def runfull(t):
    off=t-crr.BASE; r=0
    while off+r<len(terr) and terr[off+r]==2: r+=1
    return r
b2=[]
for t in tg:
    ins=dec[t]
    if len(ins)<3: continue
    span=sum(n for _,n,_ in ins); rf=runfull(t)
    last=ins[-1][2].strip()
    if last.split()[0].lower() not in crr.TERMINATORS and not crr.UNCOND_JUMP.match(last) and span!=rf:
        b2.append(t)
print('bucket2 (runfull uncapped)',len(b2))
# stop reasons
def stop(t):
    L=raw[t]['lines']; consumed=0
    for i,(a,n,x) in enumerate(L):
        mn=x.split()[0].lower() if x.split() else ''
        if mn=='db': return 'db', consumed, i
        consumed+=n
        if mn in crr.TERMINATORS: return 'terminator', consumed, i
    return 'exhausted', consumed, len(L)
c=collections.Counter()
ex=collections.defaultdict(list)
for t in b2:
    r,cons,i=stop(t); c[r]+=1; ex[r].append(t)
print(c)
for t in ex['exhausted'][:5]:
    print('---',hex(t),'buffer',raw[t]['run'],'runfull',runfull(t),'span',sum(n for _,n,_ in dec[t]))
    print(raw[t]['raw'][-300:])
