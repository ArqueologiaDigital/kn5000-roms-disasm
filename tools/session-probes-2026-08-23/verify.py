#!/usr/bin/env python3
"""For every site of `push r` / `or (imm),r`: does the CURRENT converter spell it?
If not, does the PROPOSED spelling assemble to the ROM bytes exactly?"""
import importlib.util, json, os, re, sys, subprocess
REPO="/home/fsanches/compartilhado/kn5000-roms-disasm"; BASE=0xE00000
MC=os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
ENC=re.compile(r'encoding: \[([^\]]+)\]')
def load(n,p):
    s=importlib.util.spec_from_file_location(n,os.path.join(REPO,p))
    m=importlib.util.module_from_spec(s); s.loader.exec_module(m); return m
crr=load("crr","scripts/converters/convert_reachable_ranges.py"); cc=crr.cc
os.chdir(REPO)
rom=open("original_ROMs/kn5000_v7_program.rom","rb").read()
sites=json.load(open("/tmp/claude-1000/-home-fsanches-compartilhado-KN7000/d0e1b1c2-9dd7-40da-b88c-9bcc60bcc85a/scratchpad/allsites.json"))

def mc(text):
    """Assemble ONE line with a fresh llvm-mc invocation (no cc cache)."""
    p=subprocess.run([MC,"-triple=tlcs900","--show-encoding"],input=text+"\n",
                     capture_output=True,text=True)
    if p.returncode!=0: return None,(p.stderr.strip().splitlines() or [""])[-1]
    out=[]
    for m in ENC.finditer(p.stdout):
        out += [int(b,16) for b in m.group(1).split(",") if b.strip().startswith("0x")]
        if any(not b.strip().startswith("0x") for b in m.group(1).split(",")):
            return None,"fixup placeholder"
    return bytes(out),""

def propose(text):
    """The spellings this report proposes, on top of what translate() offers."""
    mn,rest=text.split(None,1); rest=rest.strip()
    if mn.lower()=="push" and rest.upper()=="A":
        return ["push_a"]
    m=re.match(r'^\((0x[0-9a-fA-F]+)\),([A-Z]{1,3})$',rest.replace(" ",""))
    if mn.lower()=="or" and m:
        a,r=m.group(1),m.group(2).lower()
        return [f"orddm8 ({a}), {r}", f"orddm16 ({a}), {r}", f"ordm8_24 ({a}), {r}"]
    return []

rows=[]
for s in sites:
    addr=s["addr"]; want=bytes.fromhex(s["bytes"].replace(" ",""))
    assert rom[addr-BASE:addr-BASE+len(want)]==want, hex(addr)
    cur=None
    for cand in list(cc.translate(s["text"]))+[cc.canonical(s["text"])]:
        if cc.encode(cand)==want: cur=cand; break
    new=None; newenc=None; tried=[]
    if cur is None:
        for cand in propose(s["text"]):
            e,err=mc(cand); tried.append((cand,e.hex(" ") if e else "ERR: "+err))
            if e==want: new=cand; newenc=e; break
    rows.append(dict(addr=addr,bytes=s["bytes"],text=s["text"],form=s["form"],
                     entries=s["entries"],current=cur,proposed=new,
                     proposed_enc=newenc.hex(" ") if newenc else None,tried=tried))
json.dump(rows,open("/tmp/claude-1000/-home-fsanches-compartilhado-KN7000/d0e1b1c2-9dd7-40da-b88c-9bcc60bcc85a/scratchpad/verify.json","w"),indent=1)
tot=len(rows); blocked=[r for r in rows if r["current"] is None]
fixed=[r for r in blocked if r["proposed"]]
print(f"{tot} sites; {len(blocked)} not spellable today; {len(fixed)} fixed by the proposal")
for r in blocked:
    ok="MATCH" if r["proposed"] else "STILL FAILS"
    print(f"  0x{r['addr']:06X}  [{r['bytes']:<12}]  {r['text']:<16} -> {r['proposed']}  {ok}")
