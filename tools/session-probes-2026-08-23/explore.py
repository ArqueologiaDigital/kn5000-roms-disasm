import importlib.util, json, os, re, subprocess, sys, pickle
REPO='/home/fsanches/compartilhado/kn5000-roms-disasm'; os.chdir(REPO)
_s=importlib.util.spec_from_file_location('crr',REPO+'/scripts/converters/convert_reachable_ranges.py')
crr=importlib.util.module_from_spec(_s); _s.loader.exec_module(crr)
rom=open('original_ROMs/kn5000_v7_program.rom','rb').read()
spec=importlib.util.spec_from_file_location('spans','scripts/analysis/v7_undisassembled_spans.py')
spans=importlib.util.module_from_spec(spec); spec.loader.exec_module(spans)
terr=spans.territory(spans.runs('v7/maincpu/kn5000_v7_program.s','v7/maincpu'))
BASE=crr.BASE
targets=json.load(open('analysis/v7-reachability/v7_branch_closure_targets.json'))['targets']
import tempfile
tmp=tempfile.mkdtemp()
def raw(start, limit=16384):
    off=start-BASE; end=off
    while end<len(terr) and terr[end]==2 and end-off<limit: end+=1
    p=os.path.join(tmp,'r.bin'); open(p,'wb').write(rom[off:end])
    out=subprocess.run([crr.UNIDASM,p,'-arch','tlcs900','-basepc',hex(start)],capture_output=True,text=True,timeout=120).stdout
    return end-off, out
# sample a few bucket-1 members
import pickle
d,prov = None,None
_c=importlib.util.spec_from_file_location('_cache',REPO+'/tools/spelling-probes/refusal-buckets/_cache.py')
cm=importlib.util.module_from_spec(_c); _c.loader.exec_module(cm)
d,prov=cm.load(crr,verbose=False)
b1=[t for t in sorted(targets) if len(d.get(t,[]))<3]
print('bucket1',len(b1))
for t in b1[:6]:
    rl,out=raw(t)
    print('='*60); print(f'0x{t:06X} run={rl} insns={len(d[t])}')
    print(out[:600])
