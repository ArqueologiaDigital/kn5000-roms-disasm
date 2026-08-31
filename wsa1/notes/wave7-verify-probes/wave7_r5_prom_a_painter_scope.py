#!/usr/bin/env python3
"""REVIEW-WA3: are prom_a's round-5 names CARRIED BY THEIR EVIDENCE?

QUESTION IT ANSWERS
    Round 5 added 35 semantic names and 108 header blocks to prom_a.  The byte
    gate is blind to all of them.  This re-derives every claim INDEPENDENTLY of
    notes/prom_a_understanding_round5.py -- re-parsing the listing, re-finding
    the XIY/XIX immediates, and reading list bytes straight out of the ROM
    images -- and reports where the evidence does not carry the name.

    ★ THE FINDING: `painters()` in the lane's script attributes a display-list
      call site to the NEAREST PRECEDING LABEL BY SOURCE LINE and never checks
      the routine's own `ret`.  The lane applied a before-first-`ret` test to its
      73 GAP headers (its selftest asserts it) but NOT to its 24 NAMED painters.
      6 of the 24 therefore take the name of a screen painted by a DIFFERENT,
      unlabelled function that merely follows them in memory.

RUN
    python3 wave7_round5_review_wa3_prom_a.py
"""
import re, bisect, sys

ROOT = "/home/fsanches/compartilhado/kn5000-roms-disasm/wsa1/"
S    = ROOT + "prom_a/wsa1_prom_a.s"
IMG  = {'a': ROOT+"original_ROMs/wsa1_prom_a.ic12", 'b': ROOT+"original_ROMs/wsa1_prom_b.ic13",
        'c': ROOT+"original_ROMs/wsa1_prom_c.ic28", 'd': ROOT+"original_ROMs/wsa1_prom_d.bin"}
ROM  = {k: open(v,'rb').read() for k,v in IMG.items()}
def rd(a,n):
    return ROM['a'][a-0xF80000:a-0xF80000+n] if a>=0xF80000 else ROM['b'][a-0xF00000:a-0xF00000+n]

lines = open(S).read().splitlines(); src = "\n".join(lines)
ins=[]; lab={}; cur=[]
for l in lines:
    m=re.match(r'^([A-Za-z_.][A-Za-z0-9_.]*):\s*$', l)
    if m: cur.append(m.group(1)); continue
    m=re.search(r'^\t(.*?)\s+;\s+([0-9A-F]{6})\s+((?:[0-9a-f]{2} )*[0-9a-f]{2})', l)
    if m:
        a=int(m.group(2),16); ins.append((a, m.group(1).strip(), len(m.group(3).split())))
        for c in cur: lab[c]=a
        cur=[]
ins.sort(); addrs=[i[0] for i in ins]
starts={i[0] for i in ins}
def first_ret(st):
    i=bisect.bisect_left(addrs,st)
    while i<len(ins):
        if ins[i][1] in ('ret','reti','retd'): return ins[i][0]
        i+=1
DL=('call 0xf417f0','call 0xf417f4')
fail=0
def chk(cond, msg):
    global fail
    print(("  PASS  " if cond else "  FAIL  ")+msg)
    if not cond: fail+=1

print("=== 1. citations are instruction starts, and are the calls claimed ===")
# only the sites round 5 ADDED: the display-list headers.  (An older header,
# Disk_PortA3_Release, cites `calr` sites at opcode 0x1e -- not this pass's work.)
dlh = re.findall(r'-- (?:paints|a display-list painter)(.*?)\n; ---', src, re.S)
cites=sorted({int(x,16) for b in dlh for x in re.findall(r'site 0x([0-9A-F]{6})', b)})
notstart=[a for a in cites if a not in starts]
notcall=[a for a in cites if a in starts and rd(a,4)[:4] not in (b'\x1d\xf0\x17\xf4', b'\x1d\xf4\x17\xf4')]
chk(not notstart, "all %d cited sites are instruction starts (0x44/45/46-at-cited-1 bug: %d)"
    % (len(cites), sum(1 for a in notstart if ROM['a'][a-0xF80001] in (0x44,0x45,0x46))))
chk(not notcall, "all %d cited sites are literally `call 0xF417F0` or `call 0xF417F4`" % len(cites))

print("=== 2. the 0-for-O spelling is literal ROM text, not an invented morpheme ===")
for lit,alt in [(b"S0NG C0PY",b"SONG COPY"),(b"N0TE CHANGE",b"NOTE CHANGE"),
                (b"C0MBINATI0N M0DE",b"COMBINATION MODE")]:
    n=sum(d.count(lit) for d in ROM.values()); m=sum(d.count(alt) for d in ROM.values())
    chk(n>0 and m==0, "%-18s occurs %d time(s); %-18s occurs %d" % (lit.decode(),n,alt.decode(),m))

print("=== 3. named painters: is the cited site INSIDE the labelled routine? ===")
blocks=re.findall(r'; (Paint_[A-Za-z0-9_]+) -- paints.*?It reaches[^\n]*\n; (\d+) time\(s\)(.*?)\n; ---', src, re.S)
outside=[]; wrongn=[]
for nm,n,body in blocks:
    st=lab[nm]; fr=first_ret(st)
    sites=[int(x,16) for x in re.findall(r'site 0x([0-9A-F]{6})', body)]
    i=bisect.bisect_left(addrs,st); c=0
    while i<len(ins):
        if ins[i][1] in DL: c+=1
        if ins[i][1]=='ret': break
        i+=1
    out=[s for s in sites if s>fr]
    if out: outside.append((nm,st,fr,out,c))
    if int(n)!=c: wrongn.append((nm,int(n),c))
print("    %d named painters" % len(blocks))
for nm,st,fr,out,c in outside:
    print("      OUTSIDE  %-30s @%06X own ret %06X, cites %s, dl-calls in body %d"
          % (nm,st,fr,",".join("%06X"%s for s in out),c))
for nm,n,c in wrongn:
    print("      COUNT    %-30s header says %d, body has %d" % (nm,n,c))
chk(not outside, "no named painter cites a site past its own `ret`  (violations: %d)"%len(outside))
chk(not wrongn,  "every header's stated call count matches the body (wrong: %d)"%len(wrongn))

print("=== 4. gap headers are correctly ret-scoped (the lane's own test) ===")
g=re.findall(r'; (sub_[0-9A-F]{6}) -- a display-list painter whose SCREEN IS NOT ESTABLISHED(.*?)\n; ---', src, re.S)
gout=[nm for nm,b in g if any(int(x,16)>first_ret(lab[nm]) for x in re.findall(r'site 0x([0-9A-F]{6})',b))]
chk(not gout, "all %d gap headers cite only inside their routine" % len(g))
chk(all('Unknown:' in b for _,b in g), "all %d gap headers state the gap with an Unknown: line" % len(g))

print("=== 5. non-painter names, byte-checked against the ROM ===")
for new,na,tm,ta,ln,cell in [("Arr2800_Set1",0xFDA48C,"Arr27D6_Set1",0xFD767B,24,0x2800),
                             ("Var280E_GetW",0xFDA8BC,"Var27F2_GetW",0xFD9D3E,16,0x280E)]:
    x,y=rd(na,ln),rd(ta,ln); d=[i for i in range(ln) if x[i]!=y[i]]
    chk(len(d)==2 and int.from_bytes(x[d[0]:d[0]+2],'little')==cell,
        "%s: %d of %d bytes differ from %s, and they ARE cell 0x%04X"%(new,len(d),ln,tm,cell))
for new,na,la,ln in [("Queue2C00_PublishStagedIfPending_StaleCopy",0xFAA0A0,0xFAA4A0,92),
                     ("ParamChange_Notify_StaleCopy",0xFAA204,0xFAA604,31),
                     ("ParamRecord_WriteFieldAndStage_StaleCopy",0xFAA26A,0xFAA66A,71)]:
    d=sum(1 for i in range(ln) if rd(na,ln)[i]!=rd(la,ln)[i])
    chk(d==0, "%s: %d of %d bytes differ from the live twin at +0x400"%(new,d,ln))
d=sum(1 for i in range(24) if ROM['a'][0xFB81CE-0xF80000+i]!=ROM['c'][0xF9A038-0xF80000+i])
chk(d==0, "MemCopyWords_Copy @FB81CE: %d of 24 bytes differ from prom_c MemCopyWords @F9A038 "
          "(intra-WSA1 borrow; the round-2 KN5000 SFR trap does not apply)"%d)

print("=== 6. the five DisplayList_ renames name themselves from their own text ===")
for a,nm,ln in [(0xFF0E2B,"DisplayList_SequencerRealtimeEdit",230),(0xFF0F11,"DisplayList_NoteEditTrackSong",463),
                (0xFF10E0,"DisplayList_DrumEditTrackSong",594),(0xFF1332,"DisplayList_NoteEditPartSelect",600),
                (0xFF158A,"DisplayList_DrumEditPartSelect",600)]:
    pool=" ".join(r.decode('latin1') for r in re.findall(rb'[ -~]{2,}',rd(a,ln))).upper()
    miss=[w for w in re.findall(r'[A-Z0-9][a-z0-9]*',nm.split('_',1)[1]) if w.upper() not in pool]
    chk(not miss and len(re.findall(r'^%s:'%nm,src,re.M))==1,
        "%-34s @%06X: every morpheme in its own text, defined once"%(nm,a))

print("=== 7. the headers are new prose, not removed blank lines ===")
import subprocess
dl=subprocess.run(["git","-C",ROOT,"diff","--unified=0","prom_a/wsa1_prom_a.s"],
                  capture_output=True,text=True).stdout.splitlines()
add=[l[1:] for l in dl if l.startswith('+') and not l.startswith('+++')]
rem=[l[1:] for l in dl if l.startswith('-') and not l.startswith('---')]
chk(sum(1 for l in add if not l.strip())==0 and sum(1 for l in rem if not l.strip())==0,
    "0 blank lines added, 0 removed (round 3's '+35 headers' was 35 blank-line deletions)")
chk(sum(1 for l in add if l.strip().startswith(';'))==1711,
    "%d newly written comment lines; %d Evidence:, %d Unknown:"
    % (sum(1 for l in add if l.strip().startswith(';')),
       sum(1 for l in add if 'Evidence:' in l), sum(1 for l in add if 'Unknown:' in l)))

print("\n%d checks failed" % fail)
sys.exit(1 if fail else 0)
