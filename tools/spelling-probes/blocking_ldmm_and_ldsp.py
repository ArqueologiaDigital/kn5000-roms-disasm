#!/usr/bin/env python3
"""Which v7 ranges are blocked by the mem-to-mem move and by `ld SP,#imm16`,
and what would each rule actually RELEASE?

QUESTION THIS ANSWERS
  Two numbers are wanted for each candidate spelling rule:
    * every SITE of the form, with its ROM bytes -- so the spelling can be
      proved against the bytes rather than against the mnemonic;
    * the MARGINAL BYTES the rule releases, by the converter's own accounting.

⚠ WHY THIS DOES NOT REUSE v7_blocking_forms_census.py's converted_bytes()
  That function replays truncation and the label-orphan check but NOT the
  PLAUSIBILITY SCREEN, which convert_reachable_ranges.py runs on the kept
  prefix (`swi`/`normal`/`max`/`halt`/`ldio`/`ldwio` => the decode reads as
  table data and the whole range is refused).  Ignoring it over-reports: it
  credits `ld r,imm` with 62 bytes that the screen throws away regardless,
  because BOTH of that form's v7 sites sit in ranges the screen already
  refuses.  Screen included, the honest figure for `ld SP,#imm16` is ZERO.

MEASURED 2026-08-23 on v7 @ 28bbfe1 (338 ranges reach the per-instruction
spelling loop; 168 also survive resolve_branches):
    ld/ldw (imm),(imm)   23 blocking site(s), 23 byte-exact under the ldmm rule
                         marginal  79 B for the `ldw` half alone (--ldw-only)
                         marginal 165 B for the whole family (`ld` + `ldw`)
    ld SP,#imm16          2 blocking site(s), 0 spellable, marginal 0 B
                         -- 0xEE5115 is inside a nop/`normal` carpet and
                            0xF027A4 is a misframed entry 3 bytes before the
                            real prologue at 0xF027A7.  Neither is code.

RUN
  python3 tools/spelling-probes/blocking_ldmm_and_ldsp.py          # sites
  python3 tools/spelling-probes/blocking_ldmm_and_ldsp.py --marginal
  python3 tools/spelling-probes/blocking_ldmm_and_ldsp.py --marginal --ldw-only
  Needs `make all` (for rebuilt_ROMs/kn5000_v7_program.llvm.elf), unidasm and
  the llvm-mc build.  A full site scan takes ~5 min; --marginal adds ~1 min.
"""
import importlib.util, json, os, re, sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BASE = 0xE00000

_cr = importlib.util.spec_from_file_location(
    "cr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
cr = importlib.util.module_from_spec(_cr); _cr.loader.exec_module(cr)
cc = cr.cc
_sp = importlib.util.spec_from_file_location(
    "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
spans = importlib.util.module_from_spec(_sp); _sp.loader.exec_module(spans)

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_ldmm_memtomem import family as _family           # the proposed rule


def family(text):
    """The proposed rule, optionally restricted to the `ldw` half (--ldw-only),
    so the two halves' marginal bytes can be reported separately."""
    if "--ldw-only" in sys.argv and not text.strip().lower().startswith("ldw "):
        return []
    return _family(text)

WANT = {"ldw (imm),(imm)", "ld (imm),(imm)", "ld r,imm"}


def form_of(text):
    p = text.split(None, 1)
    return p[0] + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                               re.sub(r'\b[A-Z]{1,4}\b', 'r', p[1] if len(p) > 1 else ""))


def inputs():
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
    return rom, terr, targets, addr2name


def decode_ok(rom, terr, t):
    """The converter's pre-spelling filters, in its own order."""
    insns = cr.decode_range(rom, terr, t)
    if len(insns) < 3:
        return None
    off, run = t - BASE, 0
    while off + run < len(terr) and terr[off + run] == 2:
        run += 1
    span = sum(n for _, n, _ in insns)
    last = insns[-1][2].strip()
    if (last.split()[0].lower() not in cr.TERMINATORS
            and not cr.UNCOND_JUMP.match(last) and span != run):
        return None
    return insns, span, ("ret" if last.split()[0].lower() in cr.TERMINATORS
                         else ("jump" if cr.UNCOND_JUMP.match(last) else "code"))


def scan_sites():
    rom, terr, targets, addr2name = inputs()
    rows, n = [], 0
    for t in sorted(targets):
        d = decode_ok(rom, terr, t)
        if d is None:
            continue
        insns, span, framing = d
        n += 1
        want, pos = rom[t - BASE: t - BASE + span], 0
        for (a, ln, x) in insns:
            tgt = want[pos:pos + ln]; pos += ln
            if form_of(x) not in WANT:
                continue
            if any(cc.encode(c) == tgt for c in list(cc.translate(x)) + [cc.canonical(x)]):
                continue                                     # already spellable
            fix = next((c for c in family(x) if cc.encode(c) == tgt), None)
            rows.append((a, tgt, x, fix, t, addr2name.get(t, ""), framing))
    print(f"{n} range(s) reach the spelling loop; {len(rows)} blocking site(s)\n")
    for a, raw, x, fix, t, nm, fr in sorted(rows):
        print(f"0x{a:06X}  {raw.hex():16} {x:26} -> "
              f"{fix or 'NO SPELLING (see verify_ld_sp_imm16.py)':44} "
              f"[range 0x{t:06X} {nm} {fr}]")
    return rows


def marginal(ranges):
    """Bytes each range converts today vs with the ldmm rule, screen included."""
    rom, terr, _targets, addr2name = inputs()
    tot_now = tot_new = 0
    print(f"\n{'range':10} {'name':32} {'today':>7} {'+rule':>7}  verdict")
    for t in ranges:
        d = decode_ok(rom, terr, t)
        if d is None:
            print(f"0x{t:06X}   {addr2name.get(t,''):32} {'--':>7} {'--':>7}  "
                  f"skipped before spelling matters"); continue
        insns, span, _fr = d
        br = cr.resolve_branches(insns, t, span, addr2name)
        if br is None:
            print(f"0x{t:06X}   {addr2name.get(t,''):32} {'--':>7} {'--':>7}  "
                  f"a branch target cannot be named"); continue
        br_texts, _bl = br
        want, pos, items = rom[t - BASE: t - BASE + span], 0, []
        for i, (a, ln, x) in enumerate(insns):
            tgt = want[pos:pos + ln]; pos += ln
            if br_texts[i] is not None:
                e = cc.encode(br_texts[i])
                items.append((ln, e is not None and len(e) == ln, x, False)); continue
            ok = any(cc.encode(c) == tgt for c in list(cc.translate(x)) + [cc.canonical(x)])
            fix = (not ok) and any(cc.encode(c) == tgt for c in family(x))
            items.append((ln, ok, x, bool(fix)))

        def account(use_rule):
            kept, b = [], 0
            for (ln, ok, x, fix) in items:
                if not (ok or (use_rule and fix)):
                    break
                kept.append(x); b += ln
            if len(kept) < len(items) and len(kept) < 3:
                return 0, "fewer than 3 instructions survive"
            bad = cr.implausible(kept)
            if bad:
                return 0, f"refused: decode contains `{bad}` (reads as table data)"
            return b, "converted"

        now, _w1 = account(False)
        new, w2 = account(True)
        tot_now += now; tot_new += new
        print(f"0x{t:06X}   {addr2name.get(t,''):32} {now:7} {new:7}  {w2}")
    print(f"\nTOTAL today {tot_now} B, with the ldmm rule {tot_new} B, "
          f"MARGINAL {tot_new - tot_now} B")


if __name__ == "__main__":
    rows = scan_sites()
    if "--marginal" in sys.argv:
        marginal(sorted({r[4] for r in rows}))
