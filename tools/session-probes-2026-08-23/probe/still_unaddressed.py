import os, pickle, re, glob
REPO="/home/fsanches/compartilhado/kn5000-roms-disasm"
OUT=os.path.dirname(os.path.abspath(__file__))
recs=pickle.load(open(os.path.join(OUT,"line_map.pkl"),"rb"))
lm={}
for (a,tag,rel,ln,text) in recs: lm.setdefault((rel,ln),a)
def raw_runs(lines):
    runs,cur,start,label=[],[],None,None
    for i,ln in enumerate(lines):
        m=re.match(r'^\s*\.byte\s+(.*)$',ln)
        if m:
            if start is None: start=i
            body=re.split(r'[;#]',m.group(1))[0]
            for tok in body.split(","):
                tok=tok.strip()
                if not tok: continue
                try: cur.append(int(tok,0))
                except ValueError: cur.append(None)
            continue
        if cur: runs.append((label,start,i-1,cur)); cur,start,label=[],None,None
        l2=re.match(r'^([A-Za-z_][\w]*):',ln)
        if l2: label=l2.group(1)
        elif ln.strip() and not ln.lstrip().startswith((';','#')): label=None
    if cur: runs.append((label,start,len(lines)-1,cur))
    return runs
files=sorted(glob.glob(REPO+"/v7/maincpu/*/*.s")+glob.glob(REPO+"/v7/maincpu/*.s"))
tot=0
for f in files:
    rel=os.path.relpath(f,REPO+"/v7/maincpu")
    lines=open(f,"rb").read().decode("latin-1").split("\n")
    for (lb,s,e,vals) in raw_runs(lines):
        if (rel,s) not in lm:
            print(f"{rel}:{s+1}..{e+1}  {len(vals)} B  label={lb}  first={lines[s].strip()[:60]!r}")
            tot+=len(vals)
print("total",tot)
inc=set()
for f in files:
    for ln in open(f,"rb").read().decode("latin-1").split("\n"):
        m=re.match(r'^\s*\.include\s+"([^"]+)"',ln)
        if m: inc.add(m.group(1))
allrel={os.path.relpath(f,REPO+"/v7/maincpu") for f in files}
print("\n.s files never .include'd:")
for r in sorted(allrel-inc): print("   ",r)
