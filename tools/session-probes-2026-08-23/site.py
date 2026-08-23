#!/usr/bin/env python3
import os, pickle, re, subprocess, sys, json
ROOT="/home/fsanches/compartilhado/kn5000-roms-disasm"; S=os.environ["SCRATCH"]; BASE=0xE00000
UNI=os.path.expanduser("~/compartilhado/tools/unidasm")
rom=open(os.path.join(ROOT,"original_ROMs/kn5000_v7_program.rom"),"rb").read()
def dis(start,n,tag=""):
    p=os.path.join(S,"_s.bin"); open(p,"wb").write(rom[start-BASE:start-BASE+n])
    o=subprocess.run([UNI,p,"-arch","tlcs900","-basepc",hex(start)],capture_output=True,text=True).stdout
    return [l for l in o.split("\n") if re.match(r'^[0-9a-f]+:',l)]
cases=pickle.load(open(os.path.join(S,"cases.pkl"),"rb"))["cases"]
by={c["entry"]:c for c in cases}
for e in [int(x,16) for x in sys.argv[1:]]:
    c=by[e]
    fb=c["blocks"][0][1]; end=e+c["span"]
    last=c["blocks"][-1]; blkend=last[1]+last[2]
    print(f"===== entry 0x{e:06X} span {c['span']} lead {c['lead']} tail {c['tail']} file {os.path.basename(c['path'])}")
    print("  blocks: "+" | ".join(f"{nm or '(unlab)'}@0x{a:06X}+{n}" for nm,a,n,s,ee in c["blocks"]))
    print("  off-boundary: "+", ".join(f"{nm}@0x{a:06X}" for a,nm in c["off_boundary"]))
    lo=min(fb,e); hi=max(blkend,end)
    print(f"  ROM 0x{lo:06X}..0x{hi:06X}: "+rom[lo-BASE:hi-BASE].hex(" "))
    print("  -- decode from the BLOCK LABEL 0x%06X:"%fb)
    for l in dis(fb,hi-fb)[:24]: print("     "+l)
    print("  -- decode from the CALL TARGET 0x%06X (what the converter uses):"%e)
    for l in dis(e,hi-e)[:24]: print("     "+l)
    for a,nm in c["off_boundary"]:
        print("  -- decode from the BLOCKING LABEL %s 0x%06X:"%(nm,a))
        for l in dis(a,hi-a)[:10]: print("     "+l)
