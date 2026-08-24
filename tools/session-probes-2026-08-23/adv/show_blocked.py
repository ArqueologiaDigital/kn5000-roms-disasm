import pickle
S=pickle.load(open("/tmp/claude-1000/-home-fsanches-compartilhado-KN7000/d0e1b1c2-9dd7-40da-b88c-9bcc60bcc85a/scratchpad/adv/sites.pkl","rb"))
for k in ('bit 7,(r+r)','ld (r+imm),r','ld (r+imm),imm'):
    rs=[r for r in S.values() if r["key"]==k and not r["spellable_now"]]
    print(f"=== {k}  ({len(rs)} unspellable) ===")
    for r in sorted(rs,key=lambda r:r["addr"]):
        ents=", ".join(f"0x{a:06X} {n}" for a,n in r["entries"][:2])
        print(f"  0x{r['addr']:06X}  {r['raw']:<20}  {r['text']:<26} {'OVERSHOOT' if r['overshoot'] else '':<9} [{ents}]")
    print()
