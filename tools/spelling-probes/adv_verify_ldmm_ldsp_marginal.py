#!/usr/bin/env python3
"""Independent marginal-byte accounting for the ldmm family rule and for a
hypothetical `ld SP,#imm16`, replicating convert_reachable_ranges.main() gate by
gate INCLUDING the final whole-block re-assembly gate the report's script omits."""
import importlib.util, json, os, re, sys
REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"; BASE = 0xE00000
_cr = importlib.util.spec_from_file_location("cr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
cr = importlib.util.module_from_spec(_cr); _cr.loader.exec_module(cr); cc = cr.cc
_sp = importlib.util.spec_from_file_location("spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
spans = importlib.util.module_from_spec(_sp); _sp.loader.exec_module(spans)
sys.path.insert(0, os.path.join(REPO, "tools/spelling-probes"))
from verify_ldmm_memtomem import family as ldmm_family

MODE = sys.argv[1] if len(sys.argv) > 1 else "all"   # all | ldw | sp
def fixup(text):
    if MODE == "sp":
        return ["<hypothetical ld SP>"] if re.match(r'^ld\s+SP,0x', text.strip()) else []
    c = ldmm_family(text)
    if MODE == "ldw":
        return c if text.strip().lower().startswith("ldw ") else []
    return c

RANGES = [0xEE50E7,0xF027A4,0xF16AA1,0xF3710A,0xF39585,0xF3A05F,0xF4E67B,0xF69EB3,
          0xF6A502,0xF865DF,0xF972D7,0xF97428,0xF97577,0xF9783E,0xFE82B2,0xFE832D]

rom = open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
old = spans.l1.ROOT; spans.l1.ROOT = REPO
try: rs = spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu")
finally: spans.l1.ROOT = old
terr = spans.territory(rs)
addr2name = dict(cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf"))

tot_now = tot_new = 0
print(f"mode={MODE}")
print(f"{'range':10} {'name':32} {'today':>6} {'+rule':>6}  verdict")
for t in RANGES:
    nm = addr2name.get(t, "")
    insns = cr.decode_range(rom, terr, t)
    if len(insns) < 3: print(f"0x{t:06X}   {nm:32} {'--':>6} {'--':>6}  <3 insns"); continue
    off, run = t - BASE, 0
    while off + run < len(terr) and terr[off + run] == 2: run += 1
    span = sum(n for _, n, _ in insns); last = insns[-1][2].strip()
    if last.split()[0].lower() not in cr.TERMINATORS and not cr.UNCOND_JUMP.match(last) and span != run:
        print(f"0x{t:06X}   {nm:32} {'--':>6} {'--':>6}  no ret / not at code boundary"); continue
    br = cr.resolve_branches(insns, t, span, addr2name)
    if br is None: print(f"0x{t:06X}   {nm:32} {'--':>6} {'--':>6}  a branch target cannot be named"); continue
    br_texts0, br_labels0 = br
    want = rom[off:off + span]
    items, pos = [], 0
    for i, (a, ln, x) in enumerate(insns):
        tgt = want[pos:pos + ln]; pos += ln
        if br_texts0[i] is not None:
            e = cc.encode(br_texts0[i]); ok = e is not None and len(e) == ln; sp_ = br_texts0[i]; fix = None
        else:
            sp_ = next((c for c in list(cc.translate(x)) + [cc.canonical(x)] if cc.encode(c) == tgt), None)
            ok = sp_ is not None
            fix = None if ok else next((c for c in fixup(x) if c != "<hypothetical ld SP>" and cc.encode(c) == tgt), None)
            if not ok and fix is None and MODE == "sp" and fixup(x): fix = "<hypothetical>"
        items.append((a, ln, x, ok, sp_, fix, br_texts0[i]))

    def account(use):
        texts, kept_n, b = [], 0, 0
        for (a, ln, x, ok, sp_, fix, bt) in items:
            if ok: texts.append(sp_ if bt is None else bt)
            elif use and fix: texts.append(fix if fix != "<hypothetical>" else "nop")
            else: break
            b += ln; kept_n += 1
        if kept_n < len(items) and kept_n < 3: return 0, "fewer than 3 instructions survive"
        end = t + b
        lbl = {a: l for a, l in br_labels0.items() if t <= a < end}
        live = set(lbl.values())
        bts = [it[6] for it in items[:kept_n]]
        if any(x and ".Lc_" in x and x.rsplit(None, 1)[-1] not in live for x in bts):
            return 0, "truncation would orphan a branch label"
        bad = cr.implausible(texts)
        if bad: return 0, f"refused: contains `{bad}` (reads as table data)"
        has_branch = any(x is not None for x in bts)
        if not lbl and not has_branch:
            encs = cc.encode_block(texts)
            if encs is None or b"".join(encs) != rom[off:off + b]:
                return 0, "block re-assembly did not reproduce the bytes"
        return b, "converted"
    now, wnow = account(False); new, w = account(True)
    tot_now += now; tot_new += new
    print(f"0x{t:06X}   {nm:32} {now:6} {new:6}  today=[{wnow}]  rule=[{w}]")
print(f"\nTOTAL today {tot_now} B, with rule {tot_new} B, MARGINAL {tot_new - tot_now} B")
