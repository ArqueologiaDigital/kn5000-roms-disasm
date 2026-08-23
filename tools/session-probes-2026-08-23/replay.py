"""INDEPENDENT patched replay. Monkey-patches in memory only; touches no file."""
import importlib.util, os, re, sys
REPO="/home/fsanches/compartilhado/kn5000-roms-disasm"; os.chdir(REPO)
PATCH = "--patch" in sys.argv
sys.argv=["x","--forms"]
s=importlib.util.spec_from_file_location("crr","scripts/converters/convert_reachable_ranges.py")
crr=importlib.util.module_from_spec(s); s.loader.exec_module(crr)
cc=crr.cc

R8  = {"W":0,"A":1,"B":2,"C":3,"D":4,"E":5,"H":6,"L":7}
R16 = {"WA":0,"BC":1,"DE":2,"HL":3,"IX":4,"IY":5,"IZ":6,"SP":7}
R32B= {"XWA":0xE0,"XBC":0xE4,"XDE":0xE8,"XHL":0xEC,
       "XIX":0xF0,"XIY":0xF4,"XIZ":0xF8,"XSP":0xFC}
GPR32=["xwa","xbc","xde","xhl","xix","xiy","xiz","xsp"]

if PATCH:
    # ---- Rule 1: djnz is a branch --------------------------------------
    crr.BRANCH_RE = re.compile(
        r'^(jr|jrl|calr|djnz)\s+(?:(\w+),\s*)?0x([0-9a-fA-F]+)$', re.I)
    _orig = crr.resolve_branches
    def resolve_branches(insns, t, span, addr2name):
        addrs={a for a,_n,_x in insns}
        needed, texts = {}, []
        for a,n,x in insns:
            m = crr.BRANCH_RE.match(x.strip())
            if not m:
                texts.append(None); continue
            mn, cc_, tgt = m.group(1).lower(), m.group(2), int(m.group(3),16)
            if t <= tgt < t+span:
                if tgt not in addrs: return None
                needed[tgt]=f".Lc_{tgt:06x}"; name=needed[tgt]
            elif tgt in addr2name:
                name=addr2name[tgt]
            else:
                return None
            if mn=="djnz":
                r=(cc_ or "").upper()
                if   r in R16: texts.append(f"djnz16 {r.lower()}, {name}")
                elif r in R8:  texts.append(f"djnz8 {r.lower()}, {name}")
                else: return None
            else:
                texts.append(f"{mn} {cc_.lower()}, {name}" if cc_ else f"{mn} {name}")
        return texts, needed
    crr.resolve_branches = resolve_branches

    # ---- Rule 2: ld (r+),r  = F5 destination post-increment -------------
    DPI = re.compile(r'^ld\s+\((X[A-Z]{2})\+\)\s*,\s*([A-Z]{1,2})$', re.I)
    _tr = cc.translate
    def translate(text):
        yield from _tr(text)
        m = DPI.match(text.strip())
        if not m: return
        base, src = m.group(1).upper(), m.group(2).upper()
        b0 = R32B.get(base)
        if b0 is None: return
        if src in R8:                      # byte store, sub-opc 0x40
            code=R8[src]
            yield f"lda_dpi {GPR32[code]}, 0x{b0:02x}"        # backend name swapped
            yield f"stb_dpi {src.lower()}, 0x{b0:02x}"        # correct name, post-fix
        if src in R16:                     # word store, sub-opc 0x50, base+1
            yield f"stw_dpi {src.lower()}, 0x{b0+1:02x}"
        if src.startswith("X") and src in R32B:
            yield f"stl_dpi {src.lower()}, 0x{b0+3:02x}"
    cc.translate = translate

crr.main()
