import importlib.util, collections, os, re, subprocess, sys, tempfile
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
# db byte census + retry with 64 ROM bytes ignoring territory
scratch=tempfile.mkdtemp(); tmp=os.path.join(scratch,'r.bin')
LINE=re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')
memo={}
def retry(addr):
    if addr in memo: return memo[addr]
    off=addr-crr.BASE
    open(tmp,'wb').write(rom[off:off+64])
    txt=subprocess.run([crr.UNIDASM,tmp,'-arch','tlcs900','-basepc',hex(addr)],capture_output=True,text=True).stdout
    for ln in txt.split('\n'):
        m=LINE.match(ln)
        if m: memo[addr]=(m.group(2).strip(), m.group(3).strip()); return memo[addr]
    memo[addr]=('','?'); return memo[addr]
tot=collections.Counter(); byte0=collections.Counter(); still=collections.Counter()
rows=[]
for nm,bk in (('B1',b1),('B2',b2)):
    for t in bk:
        r,cons,i=stop(t)
        if r!='db': continue
        a,n,x=raw[t]['lines'][i]
        dbb=rom[a-crr.BASE:a-crr.BASE+n]
        rf=runfull(t); buf=min(rf,16384)
        at_end = (a-t)+n >= buf   # db bytes reach the buffer end
        hexb, txt = retry(a)
        ok = not txt.lower().startswith('db')
        tot[(nm,'at_buffer_end' if at_end else 'mid_run','decodes_with_more_bytes' if ok else 'still_db')]+=1
        byte0[dbb[0]]+=1
        if not ok: still[dbb[0]]+=1
        rows.append((nm,t,a,dbb.hex(),at_end,ok,txt))
for k,v in sorted(tot.items()): print(k,v)
print('--- first db byte, top 20')
for b,c in byte0.most_common(20): print(f'  0x{b:02X} {c:4}  still_db={still.get(b,0)}')
import pickle; pickle.dump(rows,open('/tmp/claude-1000/-home-fsanches-compartilhado-KN7000/d0e1b1c2-9dd7-40da-b88c-9bcc60bcc85a/scratchpad/dbrows.pkl','wb'))
