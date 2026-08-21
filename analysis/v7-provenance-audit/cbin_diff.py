import os,glob
A="/tmp/spec-audit3/repo/v7/maincpu/includes/generated"     # pure clang output
B="/tmp/spec-audit3/full/v7/maincpu/includes/generated"     # after extract_v7_bins.py
names=[l.strip().split('/')[-1] for l in open("/tmp/spec-audit3/v7_c_bins.txt") if l.strip()]
same=diff=sized=0; sameb=diffb=0
difflist=[]
for n in names:
    a=open(os.path.join(A,n),'rb').read(); b=open(os.path.join(B,n),'rb').read()
    if a==b: same+=1; sameb+=len(b)
    else:
        diff+=1; diffb+=len(b); difflist.append((n,len(a),len(b),sum(1 for x,y in zip(a,b) if x==y)))
print(f"76 v7 C-rule bins: IDENTICAL to clang output {same} ({sameb:,d} B) | REPLACED/DIFFERENT {diff} ({diffb:,d} B post-extract)")
for n,la,lb,m in sorted(difflist,key=lambda t:-t[2]):
    print(f"   {n:52s} C={la:7,d} final={lb:7,d} bytes_equal={m:7,d}")
