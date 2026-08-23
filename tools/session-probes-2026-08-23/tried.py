import importlib.util, os, sys
REPO="/home/fsanches/compartilhado/kn5000-roms-disasm"
def load(n,p):
    s=importlib.util.spec_from_file_location(n,os.path.join(REPO,p))
    m=importlib.util.module_from_spec(s); s.loader.exec_module(m); return m
cc=load("crr","scripts/converters/convert_reachable_ranges.py").cc
os.chdir(REPO)
for text,want in (("push A","14"),("or (0x328e),A","c1 8e 32 e9")):
    print(f"--- {text!r}   ROM = [{want}]")
    seen=[]
    for cand in list(cc.translate(text))+[cc.canonical(text)]:
        if cand in seen: continue
        seen.append(cand)
        e=cc.encode(cand)
        print(f"    {cand:<34} -> {e.hex(' ') if e else 'REJECTED by llvm-mc'}")
    print()
