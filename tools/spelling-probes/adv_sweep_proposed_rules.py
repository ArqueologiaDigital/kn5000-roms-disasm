#!/usr/bin/env python3
import os as _os, tempfile as _tf
SCRATCH = _os.environ.get("KN5000_PROBE_SCRATCH", _tf.gettempdir())
_os.makedirs(SCRATCH, exist_ok=True)
import os
"""Independent full sweep: apply the REPORT'S proposed rules A/B/C verbatim to
every one of the 807 enumerated sites and byte-compare against the ROM."""
import pickle, re, sys, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from adv_mc import encode_many

S=pickle.load(open(f"{SCRATCH}/sites.pkl","rb"))

# _RIDX as used by the converter -- read out of convert_corroborated_blocks.py
_RIDX = {"XIX": 0xF0, "XIY": 0xF4, "XIZ": 0xF8, "XSP": 0xFC,
         "XWA": 0xE0, "XBC": 0xE4, "XDE": 0xE8, "XHL": 0xEC,
         "IX": 0xF0, "IY": 0xF4, "IZ": 0xF8, "SP": 0xFC,
         "WA": 0xE0, "BC": 0xE4, "DE": 0xE8, "HL": 0xEC,
         "A": 0xE0, "C": 0xE4, "E": 0xE8, "L": 0xEC}

def cands(text):
    """The REPORT's rules A, B, C, transcribed verbatim."""
    out=[]
    p=text.split(None,1)
    _mn9=p[0]; rest=p[1] if len(p)>1 else ""
    # unidasm prints "mn a,b"
    if "," not in rest: return out
    _a9,_b9=rest.split(",",1)
    # rule A
    if _mn9 in ("bit","res","set","ldcf","xorcf") \
            and re.match(r'^\([A-Za-z]{2,3}\+[A-Za-z]{1,3}\)$', _b9) \
            and re.match(r'^(0x[0-7]|[0-7])$', _a9):
        _rrb=re.match(r'^\(([A-Za-z]{2,3})\+([A-Za-z]{1,3})\)$', _b9)
        _bsb,_ixb=_RIDX.get(_rrb.group(1).upper()), _RIDX.get(_rrb.group(2).upper())
        if _bsb is not None and _ixb is not None:
            for _mode in (0x07,0x03):
                out.append(f"{_mn9}_dri {_a9}, 0x{_mode:02x}, 0x{_bsb:02x}, 0x{_ixb:02x}")
    # rule B
    if _mn9=="ld" and re.match(r'^\([A-Za-z]{2,3}\+0x[0-9a-fA-F]+\)$', _a9) \
            and re.match(r'^[A-Za-z]{1,3}$', _b9):
        _mB=re.match(r'^\(([A-Za-z]{2,3})\+(0x[0-9a-fA-F]+)\)$', _a9)
        _rnB,_dpB=_mB.group(1).lower(), int(_mB.group(2),16)
        _wB=1 if len(_mB.group(2))-2<=2 else 2
        if _dpB==0 and _wB==1:
            out.append(f"ld ({_rnB}+0x100), {_b9.lower()}")
        _limB,_modB=(0x80,0x100) if _wB==1 else (0x8000,0x10000)
        _dB=(f"- 0x{_modB-_dpB:0{2*_wB}x}" if _dpB>=_limB else f"+ 0x{_dpB:0{2*_wB}x}")
        out.append(f"ld ({_rnB} {_dB}), {_b9.lower()}")
        out.append(f"ld ({_rnB}+{_mB.group(2)}), {_b9.lower()}")
    # rule C (inside the existing ld (XRR+disp),imm rule)
    if _mn9=="ld" and re.match(r'^\([A-Za-z]{2,3}\+0x[0-9a-fA-F]+\)$', _a9) \
            and re.match(r'^0x[0-9a-fA-F]+$', _b9):
        _m2=re.match(r'^\(([A-Za-z]{2,3})\+(0x[0-9a-fA-F]+)\)$', _a9)
        _rn,_dp=_m2.group(1).upper(), int(_m2.group(2),16)
        if _dp!=0:
            _limC,_modC=(0x80,0x100) if len(_m2.group(2))-2<=2 else (0x8000,0x10000)
            if _dp>=_limC:
                _dC=f"- 0x{_modC-_dp:02x}"
                out.append(f"ld ({_rn.lower()} {_dC}), {_b9}")
                out.append(f"ldw ({_rn.lower()} {_dC}), {_b9}")
    return out

allc=[]
for r in S.values():
    r["cands"]=cands(r["text"]); allc+=r["cands"]
enc=encode_many(allc)

res=collections.Counter(); fails=[]
for a,r in sorted(S.items()):
    raw=bytes.fromhex(r["raw"].replace(" ",""))
    hit=None
    for c in r["cands"]:
        if enc.get(c)==raw: hit=c; break
    r["newhit"]=hit
    if r["spellable_now"]: res["already spellable by translate()"]+=1
    elif hit: res["fixed by a PROPOSED rule"]+=1
    elif r["overshoot"]: res["phantom (overshoot, not code)"]+=1
    else: res["STILL UNSPELLABLE"]+=1; fails.append(r)

for k,v in res.most_common(): print(f"{v:5}  {k}")
print()
print("STILL UNSPELLABLE detail:")
for r in fails: print(f"  0x{r['addr']:06X} {r['raw']:<20} {r['text']}  cands={r['cands']}")
print()
# which rule fixed the previously-blocking ones
print("PROPOSED-rule hits at the 29 previously-blocking real sites:")
for a,r in sorted(S.items()):
    if not r["spellable_now"] and not r["overshoot"]:
        print(f"  0x{a:06X}  {r['raw']:<20} {r['text']:<26} -> {r['newhit']!r}  enc={enc.get(r['newhit']).hex(' ') if r['newhit'] else None}")
pickle.dump({a:{k:v for k,v in r.items()} for a,r in S.items()}, open(f"{SCRATCH}/sites2.pkl","wb"))
