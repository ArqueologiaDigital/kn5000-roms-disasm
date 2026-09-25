import sys,re,json,collections,pickle
sys.path.insert(0,'scripts/converters')
import symbolize_numeric_branches as snb
img=snb.image_by_key('v10')
res=snb.analyse(img)
S=sys.argv[1]
starts=set()
for line in open('original_ROMs/kn5000_v10_program.rom.unidasm'):
    m=re.match(r'([0-9a-f]{6}): ',line)
    if m: starts.add(int(m.group(1),16))
rom=open('original_ROMs/kn5000_v10_program.rom','rb').read()
B=0xE00000
OPS={'jr':range(0x60,0x70),'jrl':range(0x70,0x80),'calr':[0x1e],'call':[0x1d],'jp':[0x1b]}
out=[]
for s in res['sites']:
    p=res['plans'].get(s['target'])
    if not p: continue
    a=s['addr']; t=s['target']
    ok_src = a in starts and rom[a-B] in OPS[s['mn']]
    ok_tgt = t in starts
    out.append(dict(rel=s['rel'],li=s['li']+1,addr=a,mn=s['mn'],target=t,name=p['name'],new=p['new'],kind=p['kind'],ok_src=ok_src,ok_tgt=ok_tgt))
json.dump(out,open(S+'/v10_audit.json','w'))
print(len(out))
