#!/usr/bin/env python3
"""MARGINAL BYTES for the two assigned forms, by the converter's own accounting.

The converter truncates a range at its FIRST unspellable instruction and drops
the range if fewer than 3 instructions survive.  marginal(F) = bytes converted
when F alone is treated as spellable, minus bytes converted today.  This is the
counterfactual the blocking-forms census defines, restricted to two forms.
"""
import importlib.util, json, os, re

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
    p = text.split(None, 1)
    return p[0] + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                               re.sub(r'\b[A-Z]{1,4}\b', 'r', p[1] if len(p) > 1 else ""))


rom = open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
old = spans.l1.ROOT; spans.l1.ROOT = REPO
try:
    rs = spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu")
finally:
    spans.l1.ROOT = old
terr = spans.territory(rs)
targets = json.load(open(os.path.join(
    REPO, "analysis/v7-reachability/v7_call_targets.json")))["targets"]
addr2name = dict(cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf"))

recs = []
for t in sorted(targets):
    insns = cr.decode_range(rom, terr, t)
    if len(insns) < 3:
        continue
    off, run = t - BASE, 0
    while off + run < len(terr) and terr[off + run] == 2:
        run += 1
    span = sum(n for _, n, _ in insns)
    last = insns[-1][2].strip()
    if (last.split()[0].lower() not in cr.TERMINATORS
            and not cr.UNCOND_JUMP.match(last) and span != run):
        continue
    br = cr.resolve_branches(insns, t, span, addr2name)
    if br is None:
        continue
    br_texts, br_labels = br
    want, pos, items = rom[off:off + span], 0, []
    for i, (a, n, x) in enumerate(insns):
        tgt = want[pos:pos + n]; pos += n
        if br_texts[i] is not None:
            e = cc.encode(br_texts[i])
            ok = e is not None and len(e) == n
            items.append(dict(n=n, ok=ok, form=None if ok else "BRANCH(len) " + form_of(x)))
            continue
        ok = any(cc.encode(c) == tgt for c in list(cc.translate(x)) + [cc.canonical(x)])
        items.append(dict(n=n, ok=ok, form=None if ok else form_of(x)))
    recs.append(dict(t=t, items=items, br_texts=br_texts, br_labels=br_labels))
    print(f"\r{len(recs)} ranges analysed", end="", flush=True)
print()


def cut(rec, fixed):
    for i, it in enumerate(rec["items"]):
        if not it["ok"] and it["form"] not in fixed:
            return i
    return len(rec["items"])


def conv(rec, fixed):
    items = rec["items"]
    k = cut(rec, fixed)
    if k < len(items) and k < 3:
        return 0
    span = sum(it["n"] for it in items[:k])
    if k < len(items):
        end = rec["t"] + span
        live = {l for a, l in rec["br_labels"].items() if rec["t"] <= a < end}
        for bt in rec["br_texts"][:k]:
            if bt and ".Lc_" in bt and bt.rsplit(None, 1)[-1] not in live:
                return 0
    return span


base = sum(conv(r, frozenset()) for r in recs)
print(f"baseline: {len(recs)} ranges, {base:,} bytes convert today")
for F in ("ldw (imm),(imm)", "ld r,imm"):
    got = sum(conv(r, frozenset([F])) for r in recs)
    n = sum(1 for r in recs for it in r["items"] if it["form"] == F)
    print(f"  marginal({F!r}) = {got - base:,} bytes   ({n} blocking site(s))")
both = sum(conv(r, frozenset(["ldw (imm),(imm)", "ld r,imm"])) for r in recs)
print(f"  marginal(both together)          = {both - base:,} bytes")
