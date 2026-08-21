import glob, os, re, sys
FULL = "/tmp/spec-audit3/full"        # after full build (extract_v7_bins has run)
CONLY = "/tmp/spec-audit3/repo"       # only the 76 clang rules were run
INC = re.compile(r'\.incbin\s+"([^"]+)"(?:\s*,\s*([0-9a-fA-Fx]+)\s*(?:,\s*([0-9a-fA-Fx]+))?)?')

def scan(root, tree):
    """root = FULL or CONLY ; tree = 'v7/maincpu'. returns list of (resolved_abs, size_used, relpath)"""
    out=[]
    for f in glob.glob(os.path.join(root,tree)+"/**/*.s", recursive=True):
        txt=open(f,encoding="latin-1").read()
        for path,off,ln in INC.findall(txt):
            cands=[os.path.join(os.path.dirname(f),path), os.path.join(root,tree,path), os.path.join(root,path)]
            real=next((c for c in cands if os.path.exists(c)),None)
            if not real: 
                out.append((None,0,path)); continue
            fsz=os.path.getsize(real)
            size=int(ln,0) if ln else (fsz-int(off,0) if off else fsz)
            out.append((os.path.realpath(real),size,path))
    return out

cbins=set(l.strip() for l in open("/tmp/spec-audit3/v7_c_bins.txt") if l.strip())
cbin_names=set(os.path.basename(x) for x in cbins)

tree=sys.argv[1] if len(sys.argv)>1 else "v7/maincpu"
rows=scan(FULL,tree)
tot_inc=0; cls={}
missing=[]
for real,size,path in rows:
    if real is None:
        missing.append(path); continue
    tot_inc+=size
    base=os.path.basename(real)
    if "generated/" in path or "/generated/" in real:
        if base in cbin_names:
            k="generated: C-rule bin"
        else:
            k="generated: extract_v7_bins ROM slice"
    else:
        k="committed blob (no build rule)"
    a,b=cls.get(k,(0,0)); cls[k]=(a+1,b+size)
print(f"=== {tree} ===  incbin total {tot_inc:,d} B over {len(rows)} directives; unresolved {len(missing)}")
for k,(n,b) in sorted(cls.items()):
    print(f"  {k:40s} {n:6d} directives {b:10,d} B")
