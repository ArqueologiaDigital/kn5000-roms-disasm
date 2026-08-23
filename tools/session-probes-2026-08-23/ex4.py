import importlib.util, collections, os, sys
REPO='/home/fsanches/compartilhado/kn5000-roms-disasm'; os.chdir(REPO)
_s=importlib.util.spec_from_file_location('crr',REPO+'/scripts/converters/convert_reachable_ranges.py')
crr=importlib.util.module_from_spec(_s); _s.loader.exec_module(crr)
_c=importlib.util.spec_from_file_location('_cache',REPO+'/tools/spelling-probes/refusal-buckets/_cache.py')
cm=importlib.util.module_from_spec(_c); _c.loader.exec_module(cm)
tg,prov=cm.targets(sys.argv[1] if len(sys.argv)>1 else 'seed')
dec=cm.load(crr,tg,verbose=False); raw=cm.load_raw(crr,tg,verbose=False)
spec=importlib.util.spec_from_file_location('spans','scripts/analysis/v7_undisassembled_spans.py')
spans=importlib.util.module_from_spec(spec); spec.loader.exec_module(spans)
terr=spans.territory(spans.runs('v7/maincpu/kn5000_v7_program.s','v7/maincpu'))
rom=open('original_ROMs/kn5000_v7_program.rom','rb').read()
def runfull(t):
    off=t-crr.BASE; r=0
    while off+r<len(terr) and terr[off+r]==2: r+=1
    return r
def stop(t):
    L=raw[t]['lines']; consumed=0
    for i,(a,n,x) in enumerate(L):
        mn=x.split()[0].lower() if x.split() else ''
        if mn=='db': return 'db', consumed, i
        consumed+=n
        if mn in crr.TERMINATORS: return 'terminator', consumed, i
    return 'exhausted', consumed, len(L)
b1=[];b2=[]
for t in tg:
    ins=dec[t]
    if len(ins)<3: b1.append(t); continue
    span=sum(n for _,n,_ in ins); rf=runfull(t)
    last=ins[-1][2].strip()
    if last.split()[0].lower() not in crr.TERMINATORS and not crr.UNCOND_JUMP.match(last) and span!=rf:
        b2.append(t)
print('B1',len(b1),'B2',len(b2))
for nm,bk in (('B1',b1),('B2',b2)):
    c=collections.Counter()
    for t in bk:
        r,_,_=stop(t); rf=runfull(t); buf=min(rf,16384); span=sum(n for _,n,_ in dec[t])
        over = span-buf
        c[(r, 'over' if over>0 else ('exact' if span==buf else 'short'))]+=1
    print(nm, sorted(c.items(), key=lambda kv:-kv[1]))
# For overhang cases: does dropping the last insn give span==runfull?
n=0; nb=0
for t in b2:
    rf=runfull(t); span=sum(n2 for _,n2,_ in dec[t])
    if span>min(rf,16384) and len(dec[t])>1:
        s2=span-dec[t][-1][1]
        if s2==rf: n+=1; nb+=s2
print('B2 overhang-by-exactly-one-insn tiles to runfull:',n,'ranges',nb,'bytes')
n=0;nb=0
for t in b1:
    rf=runfull(t); span=sum(n2 for _,n2,_ in dec[t])
    if span>min(rf,16384) and len(dec[t])>=1:
        s2=span-dec[t][-1][1]
        if s2==rf: n+=1; nb+=s2
print('B1 overhang-by-exactly-one-insn tiles to runfull:',n,'ranges',nb,'bytes')
