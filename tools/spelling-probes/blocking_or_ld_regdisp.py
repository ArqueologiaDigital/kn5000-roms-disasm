#!/usr/bin/env python3
"""PROBE: spell every v7 site of `or (r+imm),imm` and `ld r,(r+imm)` byte-exactly.

Question it answers
-------------------
convert_reachable_ranges.py --forms reports these two shapes as unspellable.
Are they a backend gap, or a spelling nobody tried?

Method
------
Rebuild the converter's own territory map and reachable-range decode, collect
every instruction whose normalised FORM is one of the two, then for each site
compare the ROM bytes against llvm-mc's encoding of

    * the candidates convert_corroborated_blocks.py already offers, and
    * three PROPOSED extra candidates (see PROPOSED below).

PASS = every site's ROM bytes equal the encoding of exactly one candidate.
NEGATIVE CONTROL = the proposed rules are never allowed to *replace* a spelling
that already matched; the byte comparison alone selects, so a wrong candidate
simply never matches.

Run:  python3 verify_forms.py            (needs the repo + llvm-mc + unidasm)
"""
import importlib.util, json, os, re, sys, collections

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
BASE = 0xE00000
spec = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
crr = importlib.util.module_from_spec(spec); spec.loader.exec_module(crr)
cc = crr.cc
os.chdir(REPO)
ROM = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
spec2 = importlib.util.spec_from_file_location(
    "spans", "scripts/analysis/v7_undisassembled_spans.py")
spans = importlib.util.module_from_spec(spec2); spec2.loader.exec_module(spans)
terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
targets = json.load(open("analysis/v7-reachability/v7_call_targets.json"))["targets"]

# ---------------------------------------------------------------- PROPOSED
# RULE OR-1  `or (<XRR>+<d>),<imm>` -> ormi8 / ormi16.
#   OR8mi (sub-opcode 0x3E, MEMri) and OR16mi exist in the backend but were
#   never renamed to the real mnemonic the way AND8mi was, so they answer only
#   to the invented names `ormi8` / `ormi16`. The printed text carries neither
#   the operand width nor which of the two applies, so offer both.
# RULE LD-1  `ld <r>,(<XRR>+0x00)` -> displacement 0x100 (the ZERO-DISPLACEMENT
#   SENTINEL in TLCS900MCCodeEmitter.cpp). Plain `+0x00` folds to the 2-byte
#   no-displacement form 0x80+r, which is a DIFFERENT instruction.
# RULE LD-2  `ld <r>,(<XRR>+0xNN)` with 0x80 <= NN <= 0xFF -> signed `- 0xMM`.
#   unidasm prints the displacement as a raw byte; llvm-mc wants it signed, and
#   the unsigned spelling silently selects the 5-byte 16-bit-displacement form.
_MI8 = {"cp": "cp", "and": "and", "or": "ormi8", "add": "addmi8",
        "sub": "submi8", "adc": "adcmi8", "sbc": "sbcmi8", "xor": "xormi8"}
_MI16 = {"cp": "cpw", "and": "andw", "or": "ormi16", "add": "addiw_da",
         "sub": "submi16", "adc": "adcmi16", "sbc": "sbcmi16", "xor": "xormi16"}
_RD = re.compile(r'^\(([A-Za-z]{2,3})\+(0x[0-9a-fA-F]+)\)$')

def _disps(txt):
    """MEMri displacement spellings for a displacement unidasm printed raw."""
    dv = int(txt, 16)
    out = [f"+{txt}"]
    if dv == 0:
        out.append("+0x100")                       # zero-displacement sentinel
    if 0x80 <= dv <= 0xff and len(txt) == 4:
        out.append(f" - 0x{0x100 - dv:02x}")       # signed d8
    return out

def proposed(text):
    p = text.split(None, 1)
    if len(p) != 2 or p[1].count(",") != 1:
        return
    mn = p[0].lower()
    a, b = [x.strip() for x in p[1].split(",")]
    m = _RD.match(a)
    if m and re.match(r'^0x[0-9a-fA-F]+$', b) and mn in _MI8:   # RULE OR-1
        for d in _disps(m.group(2)):
            yield f"{_MI8[mn]} ({m.group(1).lower()}{d}), {b}"
            yield f"{_MI16[mn]} ({m.group(1).lower()}{d}), {b}"
    m = _RD.match(b)
    if mn == "ld" and m:
        rn, dv = m.group(1).lower(), int(m.group(2), 16)
        if dv == 0:                                     # RULE LD-1
            yield f"ld {a.lower()}, ({rn}+0x100)"
        if 0x80 <= dv <= 0xff and len(m.group(2)) == 4: # RULE LD-2
            yield f"ld {a.lower()}, ({rn} - 0x{0x100 - dv:02x})"

def norm(x):
    mn = x.split()[0]
    rest = x.split(None, 1)[1] if len(x.split(None, 1)) > 1 else ""
    return mn + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                             re.sub(r'\b[A-Z]{1,4}\b', 'r', rest))
WANT = {"or (r+imm),imm", "ld r,(r+imm)"}

sites = []
for t in sorted(targets):
    for (a, n, x) in crr.decode_range(ROM, terr, t):
        if norm(x) in WANT:
            sites.append((t, a, n, x))

old_ok = new_ok = still = 0
rows = collections.OrderedDict()
for (t, a, n, x) in sites:
    want = ROM[a - BASE: a - BASE + n]
    old = next((c for c in list(cc.translate(x)) + [cc.canonical(x)]
                if cc.encode(c) == want), None)
    new = old or next((c for c in proposed(x) if cc.encode(c) == want), None)
    if old:   old_ok += 1
    elif new: new_ok += 1
    else:     still += 1
    if not old:
        rows.setdefault((x, want), []).append((t, a, new))

print(f"sites of the two forms in the reachable ranges: {len(sites)}")
print(f"  already spellable ................ {old_ok}")
print(f"  spellable with the PROPOSED rules  {new_ok}")
print(f"  STILL unspellable ................ {still}")
print()
print(f"{'SITE':10} {'ROM BYTES':17} {'unidasm text':22} {'llvm-mc spelling':30} ENCODING")
for (x, want), locs in rows.items():
    enc = cc.encode(locs[0][2]) if locs[0][2] else None
    for (t, a, sp) in locs:
        print(f"0x{a:06X}  {' '.join(f'{c:02x}' for c in want):17} {x:22} "
              f"{sp or '<NONE>':30} "
              f"[{','.join(f'0x{c:02x}' for c in enc)}]" if enc else "<none>")
        assert enc == want, "encoding does not equal the ROM bytes"
print("\nALL PROPOSED SPELLINGS BYTE-EQUAL THE ROM." if still == 0 else "\nGAP REMAINS.")
