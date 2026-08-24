#!/usr/bin/env python3
"""Every SITE of the forms `ldw (imm),(imm)` and `ld r,imm`, with ROM bytes.

Decodes every reachable call target to its FULL extent (the census's method;
`--forms` records at most one form per range and so undercounts), and records
each instruction whose converter form key matches, together with the exact ROM
bytes and whether convert_corroborated_blocks.translate()/canonical() can
already spell it byte-exactly.
"""
import importlib.util, json, os, re, sys

REPO = os.path.expanduser("~/compartilhado/kn5000-roms-disasm")
BASE = 0xE00000
HERE = os.path.dirname(os.path.abspath(__file__))

_cr = importlib.util.spec_from_file_location(
    "cr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
cr = importlib.util.module_from_spec(_cr); _cr.loader.exec_module(cr)
cc = cr.cc
_sp = importlib.util.spec_from_file_location(
    "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
spans = importlib.util.module_from_spec(_sp); _sp.loader.exec_module(spans)


def form_of(text):
    parts = text.split(None, 1)
    return parts[0] + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                                   re.sub(r'\b[A-Z]{1,4}\b', 'r',
                                          parts[1] if len(parts) > 1 else ""))


WANT = {"ldw (imm),(imm)", "ld r,imm"}

rom = open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
old = spans.l1.ROOT
spans.l1.ROOT = REPO
try:
    rs = spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu")
finally:
    spans.l1.ROOT = old
terr = spans.territory(rs)
targets = json.load(open(os.path.join(
    REPO, "analysis/v7-reachability/v7_call_targets.json")))["targets"]
addr2name = dict(cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf"))

hits, nranges = [], 0
for t in sorted(targets):
    insns = cr.decode_range(rom, terr, t)
    if len(insns) < 3:
        continue
    off, run = t - BASE, 0
    while off + run < len(terr) and terr[off + run] == 2:
        run += 1
    span = sum(n for _, n, _ in insns)
    last = insns[-1][2].strip()
    ends_at_ret = last.split()[0].lower() in cr.TERMINATORS
    uncond = bool(cr.UNCOND_JUMP.match(last))
    if not ends_at_ret and not uncond and span != run:
        continue
    nranges += 1
    want, pos = rom[off:off + span], 0
    for (a, n, x) in insns:
        tgt = want[pos:pos + n]; pos += n
        f = form_of(x)
        if f not in WANT:
            continue
        spell = next((c for c in list(cc.translate(x)) + [cc.canonical(x)]
                      if cc.encode(c) == tgt), None)
        hits.append(dict(target=t, addr=a, n=n, text=x, form=f, bytes=tgt.hex(),
                         spell=spell, name=addr2name.get(t, ""),
                         framing="ret" if ends_at_ret else ("jump" if uncond else "code")))

json.dump(hits, open(os.path.join(HERE, "lsp_sites.json"), "w"), indent=1)
un = [h for h in hits if h["spell"] is None]
print(f"{nranges} ranges, {len(hits)} site(s) of the two forms, {len(un)} UNSPELLABLE")
for h in sorted(un, key=lambda y: y["addr"]):
    print(f"0x{h['addr']:06X}  {h['bytes']:16}  {h['text']:30} {h['form']:18} "
          f"range=0x{h['target']:06X} {h['name']} ({h['framing']})")
