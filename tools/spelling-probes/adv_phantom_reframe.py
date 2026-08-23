import os as _os, tempfile as _tf
SCRATCH = _os.environ.get("KN5000_PROBE_SCRATCH", _tf.gettempdir())
_os.makedirs(SCRATCH, exist_ok=True)
import importlib.util, os, sys, subprocess
REPO="/home/fsanches/compartilhado/kn5000-roms-disasm"; BASE=0xE00000
s2=importlib.util.spec_from_file_location("spans", os.path.join(REPO,"scripts/analysis/v7_undisassembled_spans.py"))
spans=importlib.util.module_from_spec(s2); s2.loader.exec_module(spans)
os.chdir(REPO)
terr=spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s","v7/maincpu"))
rom=open("original_ROMs/kn5000_v7_program.rom","rb").read()
UNI="/home/fsanches/compartilhado/tools/unidasm"
for a in (0xFCD010,0xFE5E1D,0xFE6807,0xFE7375):
    off=a-BASE; e=off
    while e<len(terr) and terr[e]==2: e+=1
    print(f"0x{a:06X}: run ends at 0x{BASE+e:06X}  ({e-off} byte(s) of run left)")
    tmp=f"{SCRATCH}/w.bin"
    open(tmp,"wb").write(rom[off:off+24])
    out=subprocess.run([UNI,tmp,"-arch","tlcs900","-basepc",hex(a)],capture_output=True,text=True).stdout
    print("   ROM bytes:", rom[off:off+8].hex(" "))
    print("   fresh 24B window decode:", out.strip().split("\n")[0])
