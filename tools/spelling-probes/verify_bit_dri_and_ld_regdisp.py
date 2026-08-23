#!/usr/bin/env python3
"""Verify the PROPOSED spellings for three blocking forms, at every site.

Forms:
  bit 7,(r+r)      e.g. bit 7,(XDE+IZ)
  ld (r+imm),r     e.g. ld (XIX+0x00),WA
  ld (r+imm),imm   e.g. ld (XHL+0xfc),0x0000

For each site the script prints ADDRESS, ROM BYTES, the chosen spelling and the
encoding llvm-mc produced, and asserts they are equal.  It also runs two
NEGATIVE CONTROLS, both of which are spellings that ASSEMBLE CLEANLY and are the
wrong instruction:
  N1  the unsigned displacement (`ld (xbc+0xff), a`)  -> 5-byte f3-prefixed form
  N2  the literal zero displacement (`ld (xix+0x00), wa`) -> 2-byte 0xB0+r form
A control that cannot fail is not a control, so both are reported as counts.

Run:  python3 verify_bit_dri_and_ld_regdisp.py           (blocking sites only)
      python3 verify_bit_dri_and_ld_regdisp.py --all     (every site of the three forms)
"""
import importlib.util, json, os, re, sys, collections

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
BASE = 0xE00000
ALL = "--all" in sys.argv

spec = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
crr = importlib.util.module_from_spec(spec)
sys.argv = [sys.argv[0]]
spec.loader.exec_module(crr)
cc = crr.cc

_RIDX = {"XIX": 0xF0, "XIY": 0xF4, "XIZ": 0xF8, "XSP": 0xFC,
         "XWA": 0xE0, "XBC": 0xE4, "XDE": 0xE8, "XHL": 0xEC,
         "IX": 0xF0, "IY": 0xF4, "IZ": 0xF8, "SP": 0xFC,
         "WA": 0xE0, "BC": 0xE4, "DE": 0xE8, "HL": 0xEC,
         "A": 0xE0, "C": 0xE4, "E": 0xE8, "L": 0xEC}

RD = re.compile(r'^\(([A-Za-z]{2,3})\+(0x[0-9a-fA-F]+)\)$')
RR = re.compile(r'^\(([A-Za-z]{2,3})\+([A-Za-z]{1,3})\)$')


def signed(rn, dp, width):
    """Spell a displacement the way llvm-mc wants it: SIGNED."""
    lim = 0x80 if width == 1 else 0x8000
    mod = 0x100 if width == 1 else 0x10000
    if dp >= lim:
        return f"({rn} - 0x{mod - dp:0{2*width}x})"
    return f"({rn} + 0x{dp:0{2*width}x})"


def proposed(text):
    """The candidates the three PROPOSED rules would add. Yields (label, spelling)."""
    parts = text.split(None, 1)
    if len(parts) != 2 or parts[1].count(",") != 1:
        return
    mn = parts[0].lower()
    a, b = [x.strip() for x in parts[1].split(",")]

    # RULE A -- bit/res/set/ldcf/xorcf with a REGISTER-INDEXED memory operand.
    m = RR.match(b)
    if mn in ("bit", "res", "set", "ldcf", "xorcf") and m and re.match(r'^(0x[0-7]|[0-7])$', a):
        bs, ix = _RIDX.get(m.group(1).upper()), _RIDX.get(m.group(2).upper())
        if bs is not None and ix is not None:
            for mode in (0x07, 0x03):          # 0x07 = 16-bit index, 0x03 = 8-bit
                yield "A", f"{mn}_dri {a}, 0x{mode:02x}, 0x{bs:02x}, 0x{ix:02x}"

    m = RD.match(a)
    if not m:
        return
    rn, dp = m.group(1).lower(), int(m.group(2), 16)
    w = 1 if len(m.group(2)) - 2 <= 2 else 2

    # RULE B -- ld (<XRR>+<disp>),<REG>
    if mn == "ld" and re.match(r'^[A-Za-z]{1,3}$', b):
        if dp == 0 and w == 1:
            yield "B", f"ld ({rn}+0x100), {b.lower()}"   # zero-displacement sentinel
        yield "B", f"ld {signed(rn, dp, w)}, {b.lower()}"

    # RULE C -- ld (<XRR>+<disp>),<IMM>, the SIGNED displacement the existing
    # rule never offers.
    if mn == "ld" and re.match(r'^0x[0-9a-fA-F]+$', b):
        if dp != 0:
            yield "C", f"ld {signed(rn, dp, w)}, {b}"
            yield "C", f"ldw {signed(rn, dp, w)}, {b}"


def negatives(text):
    """Spellings that assemble but are the WRONG instruction (controls)."""
    parts = text.split(None, 1)
    if len(parts) != 2 or parts[1].count(",") != 1:
        return
    mn = parts[0].lower()
    a, b = [x.strip() for x in parts[1].split(",")]
    m = RD.match(a)
    if mn == "ld" and m:
        rn, dp = m.group(1).lower(), int(m.group(2), 16)
        # ⚠ ONLY an EIGHT-BIT displacement can be misread as unsigned. unidasm
        # prints a 16-bit displacement with 3-4 hex digits, and there 0x0114 is
        # genuinely +276 -- offering that as a "wrong" control made 71 sites
        # report the control as toothless when nothing was wrong with them.
        if dp >= 0x80 and len(m.group(2)) - 2 <= 2:
            yield "N1-unsigned", f"ld ({rn}+{m.group(2)}), {b.lower()}"
        if dp == 0:
            yield "N2-zero-folds", f"ld ({rn}+0x00), {b.lower()}"


def formkey(text):
    mn = text.split()[0]
    rest = text.split(None, 1)[1] if len(text.split(None, 1)) > 1 else ""
    return mn + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                             re.sub(r'\b[A-Z]{1,4}\b', 'r', rest))


WANT = {"bit 7,(r+r)", "ld (r+imm),r", "ld (r+imm),imm"}


def main():
    rom = open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
    s2 = importlib.util.spec_from_file_location(
        "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
    spans = importlib.util.module_from_spec(s2); s2.loader.exec_module(spans)
    os.chdir(REPO)
    terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
    targets = json.load(open(os.path.join(
        REPO, "analysis/v7-reachability/v7_call_targets.json")))["targets"]

    seen, rows = set(), []
    for t in sorted(targets):
        insns = crr.decode_range(rom, terr, t)
        if len(insns) < 3:
            continue
        off = t - BASE
        run = 0
        while off + run < len(terr) and terr[off + run] == 2:
            run += 1
        run_end = t + run
        for addr, n, text in insns:
            if formkey(text) not in WANT or addr in seen:
                continue
            seen.add(addr)
            raw = rom[addr - BASE: addr - BASE + n]
            over = addr + n > run_end
            old = any(cc.encode(c) == raw
                      for c in list(cc.translate(text)) + [cc.canonical(text)])
            rows.append((addr, n, text, raw, over, old, t))

    stat = collections.Counter()
    print(f"{len(rows)} site(s) of the three forms in the reachable decode\n")
    for addr, n, text, raw, over, old, t in sorted(rows):
        if over:
            stat["phantom (decode overshoots the run; bytes are not the ROM's)"] += 1
            print(f"0x{addr:06X}  PHANTOM   unidasm read {n} B past the end of the "
                  f"undisassembled run starting at 0x{t:06X}; printed `{text}` "
                  f"is built from zero-fill, ROM holds {raw.hex(' ')}")
            continue
        if old and not ALL:
            continue
        hit = None
        for lab, cand in proposed(text):
            e = cc.encode(cand)
            if e == raw:
                hit = (lab, cand, e)
                break
        if hit is None and old:
            stat["already spellable (existing rules)"] += 1
            _w = [c for c in list(cc.translate(text)) + [cc.canonical(text)]
                  if cc.encode(c) == raw]
            print(f"0x{addr:06X}  {raw.hex(' '):<20}  {text:<28}  "
                  f"EXISTING RULE: `{_w[0]}`")
            continue
        if hit is None:
            stat["STILL UNSPELLABLE"] += 1
            print(f"0x{addr:06X}  {raw.hex(' '):<20}  {text:<28}  NO SPELLING FOUND")
            continue
        lab, cand, e = hit
        assert bytes(e) == raw
        stat[f"fixed by rule {lab}"] += 1
        print(f"0x{addr:06X}  {raw.hex(' '):<20}  {text:<28}  "
              f"rule {lab}: `{cand}`  ->  [{','.join('0x%02x' % c for c in e)}]  MATCH")
        for nlab, ncand in negatives(text):
            ne = cc.encode(ncand)
            if ne is None:
                stat[f"{nlab}: rejected by llvm-mc"] += 1
            elif bytes(ne) == raw:
                stat[f"{nlab}: WOULD ALSO MATCH (control is toothless)"] += 1
            else:
                stat[f"{nlab}: assembles, wrong bytes ({len(ne)} B)"] += 1

    print()
    for k, v in sorted(stat.items()):
        print(f"  {v:4}  {k}")


main()
