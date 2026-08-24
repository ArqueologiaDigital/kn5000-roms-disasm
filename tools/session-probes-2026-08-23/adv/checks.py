import pickle, re, collections
S=pickle.load(open("/tmp/claude-1000/-home-fsanches-compartilhado-KN7000/d0e1b1c2-9dd7-40da-b88c-9bcc60bcc85a/scratchpad/adv/sites2.pkl","rb"))
RD=re.compile(r'^\(([A-Za-z]{2,3})\+(0x[0-9a-fA-F]+)\)$')
w16=[]; d0=[]; d100=[]
for a,r in sorted(S.items()):
    p=r["text"].split(None,1)
    if p[0]!="ld": continue
    aa=p[1].split(",",1)[0]
    m=RD.match(aa)
    if not m: continue
    if len(m.group(2))-2>2: w16.append((a,r))
    if int(m.group(2),16)==0: d0.append((a,r))
    if int(m.group(2),16)==0x100: d100.append((a,r))
print("16-bit-displacement sites:",len(w16))
print("printed-zero-displacement sites:",len(d0))
print("  of those, already spellable by translate():",sum(1 for a,r in d0 if r["spellable_now"]))
for a,r in d0:
    if r["spellable_now"]: print(f"    0x{a:06X} {r['raw']:<18} {r['text']}")
print("sites with printed displacement 0x0100:",len(d100))
# negative 16-bit displacements?
neg16=[(a,r) for a,r in w16 if int(RD.match(r['text'].split(None,1)[1].split(',',1)[0]).group(2),16)>=0x8000]
print("16-bit sites with disp >= 0x8000 (would be negative):",len(neg16))
for a,r in neg16[:10]: print(f"    0x{a:06X} {r['raw']:<18} {r['text']}  spellable_now={r['spellable_now']}")
