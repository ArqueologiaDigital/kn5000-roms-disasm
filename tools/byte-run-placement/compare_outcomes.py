import json, os, pickle, tempfile
OUT = os.environ.get("KN5000_PROBE_DIR",
                     os.path.join(tempfile.gettempdir(), "kn5000-byte-run-placement"))
os.makedirs(OUT, exist_ok=True)
base=json.load(open(os.path.join(OUT,"base_outcomes.json")))
aug=json.load(open(os.path.join(OUT,"augment_outcomes.json")))
def tot(rows):
    d={}
    for r in rows: d.setdefault(r["bucket"],[0,0]); d[r["bucket"]][0]+=1; d[r["bucket"]][1]+=r["span"]
    return d
for nm,rows in (("BASE (converter as committed)",base),("AUGMENT (assembler-addressed runs)",aug)):
    print(f"\n{nm}: {len(rows)} range(s), {sum(r['span'] for r in rows):,} bytes reached placement")
    for k,(n,b) in sorted(tot(rows).items(), key=lambda kv:-kv[1][1]):
        print(f"   {n:4} range(s) {b:6,} B  {k}")
bucket_rows = pickle.load(open(os.path.join(OUT,"unplaced.pkl"),"rb"))["rows"]
noblock={t for t,_ in bucket_rows}
ab={r["entry"]:r for r in aug}
print(f"\nthe {len(noblock)} ranges of the NO-BLOCK bucket, after the fix:")
d={}
for t in sorted(noblock):
    r=ab.get(t)
    k=r["bucket"] if r else "MISSING"
    d.setdefault(k,[]).append((t,r["span"] if r else 0,r["file"] if r else ""))
for k,v in sorted(d.items(), key=lambda kv:-sum(x[1] for x in kv[1])):
    print(f"  {len(v):3} range(s) {sum(x[1] for x in v):5,} B  {k}")
    for (t,s,f) in v: print(f"        0x{t:06X} {s:5} B  {f}")
