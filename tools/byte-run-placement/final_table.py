#!/usr/bin/env python3
"""The evidence table for the 'no indexed .byte block and no located .incbin' bucket."""
import json, os, pickle, re, tempfile
REPO=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT=os.environ.get("KN5000_PROBE_DIR", os.path.join(tempfile.gettempdir(), "kn5000-byte-run-placement")); BASE=0xE00000
os.makedirs(OUT, exist_ok=True)
os.makedirs(OUT, exist_ok=True)
recs=pickle.load(open(os.path.join(OUT,"line_map.pkl"),"rb"))
LM={}
for (a,_g,rel,ln,_t) in recs: LM.setdefault((rel,ln),a)
rows=pickle.load(open(os.path.join(OUT,"unplaced.pkl"),"rb"))["rows"]
aug={r["entry"]:r for r in json.load(open(os.path.join(OUT,"augment_outcomes.json")))}
rom=open(os.path.join(REPO,"original_ROMs/kn5000_v7_program.rom"),"rb").read()
import bisect
addrs=[r[0] for r in recs]
def line_of(a):
    i=bisect.bisect_right(addrs,a)-1
    while i+1<len(recs) and recs[i+1][0]<=a: i+=1
    return i
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
cache={}
print(f"{'entry':>9} {'B':>5}  {'file:run lines':<46} {'run@':>8} {'runB':>6} rom  outcome")
tot={}
for t,span in sorted(rows):
    i=line_of(t); rel=recs[i][2]; ln0=recs[i][3]
    if rel not in cache:
        cache[rel]=(open(os.path.join(REPO,"v7/maincpu",rel),"rb").read().decode("latin-1").split("\n"))
    lines=cache[rel]
    runs=raw_runs(lines)
    run=next((r for r in runs if r[1]<=ln0<=r[2]),None)
    if run is None:
        print(f"0x{t:06X} {span:5}  {rel}:{ln0+1} NOT A .byte RUN ({lines[ln0].strip()[:40]})")
        tot.setdefault("aligned_string macro",[0,0]); tot["aligned_string macro"][0]+=1; tot["aligned_string macro"][1]+=span
        continue
    lb,s,e,vals=run
    a=LM.get((rel,s)); blob=bytes(v&0xFF for v in vals)
    okrom=rom[a-BASE:a-BASE+len(blob)]==blob if a is not None else False
    out=aug.get(t,{}).get("bucket","?")
    print(f"0x{t:06X} {span:5}  {rel+':'+str(s+1)+'..'+str(e+1):<46} "
          f"{'0x%06X'%a if a else '-':>8} {len(blob):6} {'ok' if okrom else 'NO':<4} {out}")
    tot.setdefault(out,[0,0]); tot[out][0]+=1; tot[out][1]+=span
print()
for k,(n,b) in sorted(tot.items(),key=lambda kv:-kv[1][1]): print(f"  {n:3} range(s) {b:6,} B  {k}")
