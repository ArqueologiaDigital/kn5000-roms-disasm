import importlib.util, json, os, re, sys
REPO="/home/fsanches/compartilhado/kn5000-roms-disasm"
os.chdir(REPO)
s=importlib.util.spec_from_file_location("crr","scripts/converters/convert_reachable_ranges.py")
crr=importlib.util.module_from_spec(s)
sys.argv=["x"]           # don't let it see our flags
s.loader.exec_module(crr)

rom=open("original_ROMs/kn5000_v7_program.rom","rb").read()
sp=importlib.util.spec_from_file_location("spans","scripts/analysis/v7_undisassembled_spans.py")
spans=importlib.util.module_from_spec(sp); sp.loader.exec_module(spans)
terr=spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s","v7/maincpu"))
targets=json.load(open("analysis/v7-reachability/v7_call_targets.json"))["targets"]

djnz=[]; dpi=[]
seen=set()
for t in sorted(targets):
    insns=crr.decode_range(rom,terr,t)
    for a,n,x in insns:
        if a in seen: continue
        seen.add(a)
        xl=x.strip()
        if xl.lower().startswith("djnz"):
            djnz.append((a,n,xl,t))
        if re.match(r'^ld\s+\(X?[A-Z]{2,3}\+\)\s*,', xl, re.I):
            dpi.append((a,n,xl,t))
print("=== djnz sites: %d ==="%len(djnz))
for a,n,x,t in sorted(djnz):
    print("0x%06X  %s  %-24s  (range entry 0x%06X)"%(a,' '.join('%02x'%b for b in rom[a-0xE00000:a-0xE00000+n]),x,t))
print("=== ld (r+),r sites: %d ==="%len(dpi))
for a,n,x,t in sorted(dpi):
    print("0x%06X  %s  %-24s  (range entry 0x%06X)"%(a,' '.join('%02x'%b for b in rom[a-0xE00000:a-0xE00000+n]),x,t))
