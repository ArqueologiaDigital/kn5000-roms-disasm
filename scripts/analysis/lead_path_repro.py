#!/usr/bin/env python3
"""Reproduce the .byte lead-path corruption WITHOUT a full build.

convert_reachable_ranges.py refuses ranges that start mid-block. This is why,
and this is the harness for whoever fixes it.

THE PATH: when a converted range starts partway into a .byte block, the bytes
BEFORE it must be re-emitted as .byte, then the instructions, then any bytes
after. Three attempts at this produced silent corruption -- content displaced a
few bytes with the byte totals intact, so the length invariant saw nothing and
the byte-match gate reported wrong bytes only after a full rebuild (103, then
183). The conversion CONTENT was never wrong; every instruction is byte-matched.

WHAT THIS HARNESS DOES: rebuilds `lead + assembled instructions + tail` in
memory and compares it against the block's real bytes, so the emission logic is
isolated from the assembler, the linker and the rest of the tree. A round trip
that takes minutes as a build takes seconds here.

WHAT IT ALREADY FOUND, which was necessary and NOT sufficient:

    the touched blocks are assumed to TILE the address range -- byte N+1 of one
    block being byte 0 of the next -- and 2 of 114 multi-block cases do not.
    Bytes inside the span belong to a block source_index() filtered out because
    its label has no ELF address, so lead+span+tail over-counts what the
    replaced LINES hold (121 vs 119 at 0xFDBDDA, 193 vs 189 at 0xFF0295).

Requiring contiguity fixes those two and the gate STILL reports 183 wrong bytes,
so at least one more defect remains in this path. Single-block lead cases
reconstruct exactly; the problem lives in the multi-block case.

Run:  python3 scripts/analysis/lead_path_repro.py [--all]
      Needs `make all` first.
"""
import importlib.util, json, os, re, sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(REPO)
BASE = 0xE00000

_cr = importlib.util.spec_from_file_location(
    "cr", "scripts/converters/convert_reachable_ranges.py")
cr = importlib.util.module_from_spec(_cr); _cr.loader.exec_module(cr)
_sp = importlib.util.spec_from_file_location(
    "spans", "scripts/analysis/v7_undisassembled_spans.py")
spans = importlib.util.module_from_spec(_sp); _sp.loader.exec_module(spans)


def main():
    rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
    terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
    syms = cr.cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
    idx = cr.source_index(syms)
    targets = json.load(open("analysis/v7-reachability/v7_call_targets.json"))["targets"]

    single_ok = multi_ok = mismatch = 0
    for t in sorted(targets):
        insns = cr.decode_range(rom, terr, t)
        if len(insns) < 3:
            continue
        span = sum(n for _, n, _ in insns)
        for path, (lines, blocks) in idx.items():
            cov = [b for b in blocks if b[1] <= t < b[1] + len(b[4])]
            if not cov:
                continue
            first = cov[0]
            lead = t - first[1]
            touched = sorted([b for b in blocks
                              if b[1] < t + span and b[1] + len(b[4]) > t],
                             key=lambda b: b[2])
            if lead <= 0:
                break
            last = touched[-1]
            held = 0
            for ln in lines[first[2]:last[3] + 1]:
                m = re.match(r'^\s*\.byte\s+(.*)$', ln)
                if m:
                    held += len([x for x in re.split(r'[;#]', m.group(1))[0].split(",")
                                 if x.strip()])
            tail = last[1] + len(last[4]) - (t + span)
            assumed = lead + span + tail
            if held != assumed:
                mismatch += 1
                if mismatch <= 5 or "--all" in sys.argv:
                    print(f"MISMATCH 0x{t:06X} {os.path.basename(path)}: "
                          f"lines hold {held} B, lead+span+tail = "
                          f"{lead}+{span}+{tail} = {assumed}, {len(touched)} block(s)")
            elif len(touched) == 1:
                single_ok += 1
            else:
                multi_ok += 1
            break
    print(f"\nlead cases: {single_ok} single-block consistent, "
          f"{multi_ok} multi-block consistent, {mismatch} MISMATCHED")
    print("Contiguity explains the mismatches; it does NOT explain the 183 wrong")
    print("bytes the gate still reports, so keep looking.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
