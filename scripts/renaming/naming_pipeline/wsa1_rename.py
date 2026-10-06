#!/usr/bin/env python3
"""wsa1_rename.py SEDNAME 'old=new|header' ...  -- one WSA1 naming step, done the way the lane requires:
rename in both images and in notes/probes that quote the old name, put an optional one-line header above
the new label (prom_a or prom_b, wherever it is defined), write scripts/renaming/<SEDNAME>.sed, and declare
the renames to notes/prom_a_preservation_check.py and notes/prom_b_names_session_53b889a2.py.
Refuses a new name already used anywhere in WSA1."""
import os,re,sys,glob,subprocess
ROOT="/home/fsanches/compartilhado/kn5000-roms-disasm"
os.chdir(ROOT)
sedname=sys.argv[1]; items=[]
for a in sys.argv[2:]:
    pair,_,hdr=a.partition("|"); old,new=pair.split("="); items.append((old,new,hdr.replace(chr(10),"\\n")))  # a real newline becomes the separator too
srcs=["wsa1/prom_a/wsa1_prom_a.s","wsa1/prom_b/wsa1_prom_b.s"]+sorted(glob.glob("wsa1/prom_c/**/*.s",recursive=True))
alltext="\n".join(open(p,"rb").read().decode("latin-1") for p in srcs)
LABELS=set(re.findall(r'^([A-Za-z_][\w$]*):',alltext,re.M))
TOKENS=set(re.findall(r'[A-Za-z_][\w$]*',"\n".join(l.split(";")[0] for l in alltext.split("\n"))))   # code only: a comment may name what this run defines (2026-10-04)
for old,new,_ in items:
    assert old in LABELS, "no label "+old
    assert new not in TOKENS, "taken: "+new
assert len({n for _,n,_ in items})==len(items), "duplicate new name"
# *.ld: prom_a.ld defines prom_b calr targets by name (2026-10-04)
files=subprocess.run(["grep","-rlwE","|".join(o for o,_,_ in items),"wsa1","--include=*.s","--include=*.md","--include=*.py","--include=*.ld"],capture_output=True,text=True).stdout.split()
files=[f for f in files if "/.image-" not in f]
# WSA1_RENAME_SKIP=path,...: files left exactly as they are (a historical key that must keep the old name)
files=[f for f in files if f not in os.environ.get("WSA1_RENAME_SKIP","").split(",")]
# prom_c is another CPU: its sub_FBxxxx names are a different address space.  Never touch them.
ctext="\n".join(open(p,"rb").read().decode("latin-1") for p in srcs if "/prom_c/" in p)
CTOK=set(re.findall(r'[A-Za-z_][\w$]*',ctext))
CCODE=set(re.findall(r'[A-Za-z_][\w$]*',"\n".join(l.split(";")[0] for l in ctext.split("\n"))))
# WSA1_RENAME_PROMC_COMMENT_OK=old,...: names that prom_c quotes only in COMMENTS that cite the prom_a routine
# (checked by hand first); those comments are renamed with it.  A prom_c CODE token of that name still refuses.
COK=set(x for x in os.environ.get("WSA1_RENAME_PROMC_COMMENT_OK","").split(",") if x)
for old,_,_ in items:
    assert old not in CCODE, "prom_c code has "+old
    assert old not in CTOK or old in COK, "prom_c also has "+old
bad=[f for f in files if "prom_c" in f and not any(re.search(r'\b%s\b' % re.escape(o), open(f,"rb").read().decode("latin-1")) for o in COK)]
assert not bad, "old name quoted in prom_c notes: %s" % bad
MAP={o:n for o,n,_ in items}
ALT=re.compile(r'\b(?:%s)\b' % "|".join(sorted(map(re.escape,MAP),key=len,reverse=True)))
for f in files:
    s=open(f,"rb").read().decode("latin-1")
    s=ALT.sub(lambda m: MAP[m.group(0)], s)
    if f.endswith(".s"):
        L=s.split("\n")
        first={}
        for i,l in enumerate(L):
            m=re.match(r'^([A-Za-z_][\w$]*):',l)
            if m: first.setdefault(m.group(1),i)
        ins=[(first[new],["; "+ALT.sub(lambda m: MAP[m.group(0)], h) for h in hdr.split("\\n")]) for old,new,hdr in items if hdr and new in first]   # a header may cite another name of the same batch (2026-10-06)
        for i,h in sorted(ins,reverse=True): L[i:i]=h
        s="\n".join(L)
    data=s.encode("latin-1")
    with open(f+".tmp","wb") as fh: fh.write(data)
    os.replace(f+".tmp",f)
open("scripts/renaming/%s.sed"%sedname,"w").write("# WSA1 naming step (session 53b889a2, wsa1_rename.py)\n"+"".join(r"s/\b%s\b/%s/g"%(o,n)+"\n" for o,n,_ in items))
p="wsa1/notes/prom_a_preservation_check.py"; s=open(p).read()
anchor="\n}\n\n\ndef _renames():"
s=s.replace(anchor,"".join('\n    "%s": "%s",'%(o,n) for o,n,_ in items)+anchor); open(p,"w").write(s)
p="wsa1/notes/prom_b_names_session_53b889a2.py"; s=open(p).read().rstrip()
s=s[:-1]+"".join('    ("%s", "%s"),\n'%(o,n) for o,n,_ in items)+"]\n"; open(p,"w").write(s)
print("renamed %d in %d files: %s"%(len(items),len(files),files))
