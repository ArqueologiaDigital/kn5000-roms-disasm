import os as _os, tempfile as _tf
SCRATCH = _os.environ.get("KN5000_PROBE_SCRATCH", _tf.gettempdir())
_os.makedirs(SCRATCH, exist_ok=True)
import pickle, re, sys, collections
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from adv_mc import encode_many
S=pickle.load(open(f"{SCRATCH}/sites2.pkl","rb"))
RD=re.compile(r'^\(([A-Za-z]{2,3})\+(0x[0-9a-fA-F]+)\)$')
ctrl=[]
for a,r in sorted(S.items()):
    if r["overshoot"]: continue
    p=r["text"].split(None,1)
    if p[0]!="ld" or p[1].count(",")!=1: continue
    aa,bb=[x.strip() for x in p[1].split(",")]
    m=RD.match(aa)
    if not m: continue
    rn,dp=m.group(1).lower(),int(m.group(2),16)
    if dp>=0x80 and len(m.group(2))-2<=2:
        ctrl.append(("N1-unsigned",a,r,f"ld ({rn}+{m.group(2)}), {bb.lower()}"))
    if dp==0:
        ctrl.append(("N2-zero-folds",a,r,f"ld ({rn}+0x00), {bb.lower()}"))
enc=encode_many([c[3] for c in ctrl])
st=collections.Counter()
for lab,a,r,c in ctrl:
    raw=bytes.fromhex(r["raw"].replace(" ",""))
    e=enc.get(c)
    if e is None: st[f"{lab}: REJECTED by llvm-mc"]+=1
    elif e==raw: st[f"{lab}: TOOTHLESS -- also matches ROM"]+=1
    else: st[f"{lab}: assembles, wrong bytes ({len(e)}B vs {len(raw)}B)"]+=1
for k,v in sorted(st.items()): print(f"  {v:4}  {k}")
