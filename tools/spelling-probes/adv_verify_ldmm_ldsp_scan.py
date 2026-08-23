#!/usr/bin/env python3
"""Independent adversarial re-derivation of the blocking picture for
`ld/ldw (imm),(imm)` and `ld r,imm`, mirroring convert_reachable_ranges.main()
including resolve_branches (which the report's script omits before scanning)."""
import importlib.util, json, os, re, sys

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
BASE = 0xE00000
_cr = importlib.util.spec_from_file_location("cr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
cr = importlib.util.module_from_spec(_cr); _cr.loader.exec_module(cr)
cc = cr.cc
_sp = importlib.util.spec_from_file_location("spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
spans = importlib.util.module_from_spec(_sp); _sp.loader.exec_module(spans)
sys.path.insert(0, os.path.join(REPO, "tools/spelling-probes"))
from verify_ldmm_memtomem import family

WANT = {"ldw (imm),(imm)", "ld (imm),(imm)", "ld r,imm"}
def form_of(text):
    p = text.split(None, 1)
    return p[0] + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm', re.sub(r'\b[A-Z]{1,4}\b', 'r', p[1] if len(p) > 1 else ""))

rom = open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
old = spans.l1.ROOT; spans.l1.ROOT = REPO
try:
    rs = spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu")
finally:
    spans.l1.ROOT = old
terr = spans.territory(rs)
targets = json.load(open(os.path.join(REPO, "analysis/v7-reachability/v7_call_targets.json")))["targets"]
addr2name = dict(cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf"))

n_reach = n_afterbr = 0
all_sites = []      # every site of WANT in a range reaching the spelling loop
first_block = []    # ranges where a WANT form is the FIRST unspellable insn (census semantics)
for t in sorted(targets):
    insns = cr.decode_range(rom, terr, t)
    if len(insns) < 3: continue
    off, run = t - BASE, 0
    while off + run < len(terr) and terr[off + run] == 2: run += 1
    span = sum(n for _, n, _ in insns)
    last = insns[-1][2].strip()
    if (last.split()[0].lower() not in cr.TERMINATORS and not cr.UNCOND_JUMP.match(last) and span != run):
        continue
    n_reach += 1
    want = rom[t - BASE: t - BASE + span]
    br = cr.resolve_branches(insns, t, span, addr2name)
    passes_br = br is not None
    if passes_br: n_afterbr += 1
    br_texts = br[0] if passes_br else [None]*len(insns)
    pos = 0; first_bad = None
    for i, (a, ln, x) in enumerate(insns):
        tgt = want[pos:pos+ln]; pos += ln
        if br_texts[i] is not None:
            e = cc.encode(br_texts[i])
            ok = e is not None and len(e) == ln
        else:
            ok = any(cc.encode(c) == tgt for c in list(cc.translate(x)) + [cc.canonical(x)])
        f = form_of(x)
        if not ok and f in WANT:
            fix = next((c for c in family(x) if cc.encode(c) == tgt), None)
            all_sites.append((a, tgt, x, fix, t, addr2name.get(t, ""), passes_br, i))
        if not ok and first_bad is None:
            first_bad = (i, f, x, a)
    if passes_br and first_bad and first_bad[1] in WANT:
        first_block.append((t, addr2name.get(t, ""), first_bad))

print(f"ranges reaching spelling loop: {n_reach}; of those passing resolve_branches: {n_afterbr}")
print(f"sites of WANT forms that are unspellable today: {len(all_sites)}")
print(f"  in ranges that PASS resolve_branches: {sum(1 for s in all_sites if s[6])}")
print(f"  in ranges REFUSED at resolve_branches: {sum(1 for s in all_sites if not s[6])}")
print(f"ranges whose FIRST unspellable insn is a WANT form (census semantics): {len(first_block)}")
for t, nm, fb in sorted(first_block):
    print(f"   range 0x{t:06X} {nm:34} first-bad #{fb[0]} @0x{fb[3]:06X}  {fb[1]:20} {fb[2]}")
print()
for a, raw, x, fix, t, nm, pb, i in sorted(all_sites):
    print(f"0x{a:06X}  {raw.hex(' '):22} {x:26} -> {fix or 'NO SPELLING':46} [range 0x{t:06X} {nm} br_ok={pb} idx={i}]")
