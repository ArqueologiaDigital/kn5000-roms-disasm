#!/usr/bin/env python3
"""Dump SITE ADDRESS + ROM BYTES for every instruction whose unidasm text
matches a requested blocking form, using the converter's OWN decode.

Question it answers: "for form F, which v7 ROM addresses does it occur at, and
what are the exact bytes there?"  unidasm's printed text is lossy, so the bytes
are the only thing that can be used to pick a spelling.

Usage:
  python3 blocking_bit_dri_and_ld_regdisp.py 'bit 7,(r+r)' 'ld (r+imm),r' 'ld (r+imm),imm'
"""
import importlib.util, json, os, re, sys, collections

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
BASE = 0xE00000
sys.path.insert(0, os.path.join(REPO, "scripts/converters"))

ARGS = [a for a in sys.argv[1:] if a != "--all"]
ONLY_BLOCKING = "--all" not in sys.argv
WANT = set(ARGS) if ARGS else None

spec = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
crr = importlib.util.module_from_spec(spec)
sys.argv = [sys.argv[0]]          # keep the converter out of --apply mode
spec.loader.exec_module(crr)
cc = crr.cc


def formkey(text):
    """Same normalisation main() uses to bucket unspellable instructions."""
    mn = text.split()[0]
    rest = text.split(None, 1)[1] if len(text.split(None, 1)) > 1 else ""
    return mn + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                             re.sub(r'\b[A-Z]{1,4}\b', 'r', rest))


def main():
    rom = open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
    s2 = importlib.util.spec_from_file_location(
        "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
    spans = importlib.util.module_from_spec(s2); s2.loader.exec_module(spans)
    os.chdir(REPO)
    terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
    targets = json.load(open(os.path.join(
        REPO, "analysis/v7-reachability/v7_call_targets.json")))["targets"]
    syms = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
    addr2name = dict(syms)

    hits = collections.defaultdict(list)
    for t in sorted(targets):
        insns = crr.decode_range(rom, terr, t)
        if len(insns) < 3:
            continue
        # END OF THE UNDISASSEMBLED RUN. unidasm reads the temp buffer with
        # ZERO FILL past its end, so the last decoded instruction can be a
        # phantom built from bytes that are not in the ROM at all. Flag it.
        _off = t - BASE
        _run = 0
        while _off + _run < len(terr) and terr[_off + _run] == 2:
            _run += 1
        run_end = t + _run
        for addr, n, text in insns:
            k = formkey(text)
            if WANT and k not in WANT:
                continue
            raw = rom[addr - BASE: addr - BASE + n]
            if ONLY_BLOCKING:
                # Report ONLY sites the converter genuinely cannot spell: try
                # every candidate it would try and keep the site only if none
                # reproduces the ROM bytes.
                if any(cc.encode(c) == raw
                       for c in list(cc.translate(text)) + [cc.canonical(text)]):
                    continue
            # dedupe: the same address can be reached from several entries
            over = "OVERSHOOT" if addr + n > run_end else ""
            rec = (addr, raw.hex(" "), text, t, addr2name.get(t, ""), over)
            if rec not in hits[k]:
                hits[k].append(rec)

    for k in sorted(hits):
        print(f"=== {k}  ({len(set(h[0] for h in hits[k]))} distinct sites) ===")
        for addr, hx, text, ent, nm, over in sorted(hits[k]):
            print(f"  0x{addr:06X}  {hx:<24}  {text:<32}  (entry 0x{ent:06X} {nm}) {over}")
        print()


main()
