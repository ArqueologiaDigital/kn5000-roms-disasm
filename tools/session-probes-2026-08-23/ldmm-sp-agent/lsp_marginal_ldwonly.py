#!/usr/bin/env python3
"""Per-range accounting for the ranges that hold the two assigned forms,
INCLUDING the plausibility screen that convert_reachable_ranges.py actually runs.

The census's converted_bytes() omits that screen, so its marginal figure is an
upper bound.  A range whose kept prefix contains `swi`/`normal`/`max`/`halt`/
`ldio`/`ldwio` is refused as table data whether or not the form is spellable,
and contributes ZERO either way.
"""
import importlib.util, json, os, re

REPO = os.path.expanduser("~/compartilhado/kn5000-roms-disasm"); BASE = 0xE00000
_cr = importlib.util.spec_from_file_location(
    "cr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
cr = importlib.util.module_from_spec(_cr); _cr.loader.exec_module(cr); cc = cr.cc
_sp = importlib.util.spec_from_file_location(
    "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
spans = importlib.util.module_from_spec(_sp); _sp.loader.exec_module(spans)

rom = open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
old = spans.l1.ROOT; spans.l1.ROOT = REPO
rs = spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"); spans.l1.ROOT = old
terr = spans.territory(rs)
addr2name = dict(cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf"))


def form_of(t):
    p = t.split(None, 1)
    return p[0] + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                               re.sub(r'\b[A-Z]{1,4}\b', 'r', p[1] if len(p) > 1 else ""))


def ldmm(text):
    if os.environ.get("LDW_ONLY") and not text.strip().startswith("ldw "): return []
    m = re.match(r'^(ldw?)\s+\((0x[0-9a-fA-F]+)\),\((0x[0-9a-fA-F]+)\)$', text.strip())
    if not m:
        return []
    d, s = int(m.group(2), 16), int(m.group(3), 16)
    dl, dh, dm = d & 0xff, (d >> 8) & 0xff, (d >> 16) & 0xff
    s0, s1, s2 = s & 0xff, (s >> 8) & 0xff, (s >> 16) & 0xff
    return [f"ldmm16 0x{d:04x}, 0x{s:04x}", f"ldmm8 0x{d:04x}, 0x{s:04x}",
            f"ldmm_sd24w 0x{s0:02x}, 0x{s1:02x}, 0x{s2:02x}, 0x{dl:02x}, 0x{dh:02x}",
            f"ldmm_sd24b 0x{s0:02x}, 0x{s1:02x}, 0x{s2:02x}, 0x{dl:02x}, 0x{dh:02x}",
            f"ldmm_sd8b 0x{s0:02x}, 0x{dl:02x}, 0x{dh:02x}",
            f"ldmmw_dd24 0x{dl:02x}, 0x{dh:02x}, 0x{dm:02x}, 0x{s0:02x}, 0x{s1:02x}",
            f"ldmmb_dd24 0x{dl:02x}, 0x{dh:02x}, 0x{dm:02x}, 0x{s0:02x}, 0x{s1:02x}"]


RANGES = [0xEE50E7, 0xF027A4, 0xF3710A, 0xF39585, 0xF3A05F,
          0xF4E67B, 0xF865DF, 0xF972D7, 0xF97428]

print(f"{'range':10} {'name':32} {'today':>8} {'+rule':>8}  verdict")
tot_now = tot_new = 0
for t in RANGES:
    insns = cr.decode_range(rom, terr, t)
    off, run = t - BASE, 0
    while off + run < len(terr) and terr[off + run] == 2:
        run += 1
    span = sum(n for _, n, _ in insns)
    last = insns[-1][2].strip()
    if (len(insns) < 3 or (last.split()[0].lower() not in cr.TERMINATORS
                           and not cr.UNCOND_JUMP.match(last) and span != run)):
        print(f"0x{t:06X}   {addr2name.get(t,''):32} {'--':>8} {'--':>8}  "
              f"skipped before spelling ever matters"); continue
    br = cr.resolve_branches(insns, t, span, addr2name)
    if br is None:
        print(f"0x{t:06X}   {addr2name.get(t,''):32} {'--':>8} {'--':>8}  "
              f"a branch target cannot be named"); continue
    br_texts, br_labels = br
    want, pos, items = rom[off:off + span], 0, []
    for i, (a, n, x) in enumerate(insns):
        tgt = want[pos:pos + n]; pos += n
        if br_texts[i] is not None:
            e = cc.encode(br_texts[i])
            items.append((n, e is not None and len(e) == n, x, br_texts[i], None))
            continue
        sp_ = next((c for c in list(cc.translate(x)) + [cc.canonical(x)]
                    if cc.encode(c) == tgt), None)
        if sp_ is None:                                  # try the PROPOSED rule
            sp_new = next((c for c in ldmm(x) if cc.encode(c) == tgt), None)
        else:
            sp_new = sp_
        items.append((n, sp_ is not None, x, sp_, sp_new))

    def account(use_rule):
        texts, bytes_ = [], 0
        for (n, ok, x, sp_, sp_new) in items:
            good = ok or (use_rule and sp_new is not None)
            if not good:
                break
            texts.append(sp_ if ok else sp_new); bytes_ += n
        if len(texts) < len(items) and len(texts) < 3:
            return 0, "fewer than 3 instructions survive"
        bad = cr.implausible([x for (_n, _o, x, _s, _s2) in items[:len(texts)]])
        if bad:
            return 0, f"refused: decode contains `{bad}` (reads as table data)"
        return bytes_, "converted"

    now, why_now = account(False)
    new, why_new = account(True)
    tot_now += now; tot_new += new
    print(f"0x{t:06X}   {addr2name.get(t,''):32} {now:8} {new:8}  {why_new}")
print(f"\nTOTAL   today {tot_now} B   with the ldmm rule {tot_new} B   "
      f"MARGINAL {tot_new - tot_now} B")
