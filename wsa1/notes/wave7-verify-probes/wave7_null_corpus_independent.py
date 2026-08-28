# Independent re-implementation of the null corpus, written from the docstring, not copied.
import re
ADDRC = re.compile(r";\s*([0-9A-F]{6})\s\s([0-9a-f]{2}(?: [0-9a-f]{2})*)")
src="/home/fsanches/compartilhado/wsa1-roms-disasm/prom_a/wsa1_prom_a.s"
rom=open("/home/fsanches/compartilhado/wsa1-roms-disasm/original_ROMs/wsa1_prom_a.ic12","rb").read()
BASE=0xF80000
seq=[]
ninstr=0; badbytes=0
for l in open(src, errors="replace"):
    body=l.split(";")[0]
    m=ADDRC.search(l)
    if m and body.startswith("\t") and not body.lstrip().startswith("."):
        a=int(m.group(1),16); bs=[int(x,16) for x in m.group(2).split()]
        ninstr+=1
        # verify the byte comment actually matches the ROM
        if list(rom[a-BASE:a-BASE+len(bs)])!=bs: badbytes+=1
        seq.append((a,len(bs)))
    else:
        seq.append(None)
runs=[];cur=[]
for it in seq:
    if it is None or (cur and it[0]<=cur[-1][0]):
        if len(cur)>1: runs.append((cur[0][0],cur[-1][0]+cur[-1][1]))
        cur=[]
    if it is not None: cur.append(it)
if len(cur)>1: runs.append((cur[0][0],cur[-1][0]+cur[-1][1]))
tot=sum(e-a for a,e in runs)
print("instruction lines:",ninstr,"byte-comment mismatches vs ROM:",badbytes)
print("runs:",len(runs),"bytes:",tot)
print("first run:",hex(runs[0][0]),hex(runs[0][1]))
print("last run:",hex(runs[-1][0]),hex(runs[-1][1]))
# do any runs overlap the span 0xFAD800-0xFB2000 ?
ov=[(a,e) for a,e in runs if e>0xFAD800 and a<0xFB2000]
print("runs overlapping the target span (should be 0 - it is .incbin):",len(ov))
