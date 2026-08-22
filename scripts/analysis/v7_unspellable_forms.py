#!/usr/bin/env python3
"""Which instruction forms block v7 conversion, and how many instances each?

⚠ SUPERSEDED for that question by
    python3 scripts/converters/convert_reachable_ranges.py --forms
This script probes translate()/canonical() ONLY. The converter also resolves
branches to labels, so every `jr`/`jrl`/`calr` counted here is one it would
actually handle -- which is why this reports 8,875 instances led by `jr r,imm`
(2,106) while the converter's own census reports 562 with no branch in the top
fourteen. Both numbers are correct about what they measure; only the second is
about what blocks conversion.

Kept because it answers a narrower question honestly -- what the SPELLING layer
alone cannot express -- which is the right measure when working on translate()
itself.

The range converter (scripts/converters/convert_reachable_ranges.py) skips a
range when any one of its instructions cannot be spelled in a way that
re-assembles to the original bytes. This census says WHICH forms those are,
ranked, so the work is targeted rather than guessed at.

MEASURED 2026-08-22, over all 808 reachable call targets: 8,875 instances.

    2106  jr r,imm        e.g. jr NZ,0xef1371
     793  calr imm        e.g. calr 0xef16c4
     725  ld r,(imm)      e.g. ld L,(0x0462)
     678  jrl r,imm       e.g. jrl NZ,0xef61e8
     434  cp (imm),imm    e.g. cp (0xce43),0x00
     408  ld (imm),imm    e.g. ld (0xbca0),0xff
     376  ld (imm),r      e.g. ld (0x045d),L

⚠ This number MOVES as the converter learns spellings -- it measures what the
translator cannot currently spell, not a property of the ROM. The first run was
9,463; adding the absolute-operand suffixes (`ldw_d16`, `stda16`) took it to
8,875 by fixing 315 of the `ld r,(imm)` cases and 269 of the `ld (imm),r` ones.
Quoting it anywhere means quoting the date and the converter state with it.

Two classes, needing different work:

  SPELLING   absolute memory operands take a suffixed mnemonic in this tree --
             `ldw_d16 wa, (0x0460)` and `stda16 (0x045e), wa`. The converter now
             offers every plausible suffix and lets the BYTE MATCH choose, which
             is safe only because selection never trusts "it assembled".

  BRANCHES   `jr`/`jrl`/`calr` (3,577 instances) cannot be spelled numerically at
             all. ⚠ `jr nz, 0xef1371` assembles happily to [0x6e,0x71] -- it
             takes the LOW BYTE as a displacement, which is wrong and silent.
             The working sources always write a SYMBOL: `jr z, SomeLabel`.
             Converting these needs local labels emitted for intra-range targets
             and symbol names for external ones. That is real work, not a lookup.

Run:  python3 scripts/analysis/v7_unspellable_forms.py [--top N]
      Needs rebuilt_ROMs/ (run `make all` first) and ~/compartilhado/tools/unidasm.
      Takes several minutes: it decodes every reachable range and probes each
      instruction against llvm-mc.
"""
import collections, importlib.util, json, os, re, sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(REPO)

_cr = importlib.util.spec_from_file_location(
    "cr", "scripts/converters/convert_reachable_ranges.py")
cr = importlib.util.module_from_spec(_cr); _cr.loader.exec_module(cr)
_sp = importlib.util.spec_from_file_location(
    "spans", "scripts/analysis/v7_undisassembled_spans.py")
spans = importlib.util.module_from_spec(_sp); _sp.loader.exec_module(spans)


def main():
    # This needs the GENERATED includes as well as the ROMs: v7's root source
    # pulls in files that `make clean-all` removes, and llvm-mc then fails with a
    # message that says nothing about the cause. Check first and say so.
    missing = [p for p in ("rebuilt_ROMs/kn5000_v7_program.llvm.elf",
                           "analysis/v7-reachability/v7_call_targets.json")
               if not os.path.exists(p)]
    if missing:
        sys.exit("missing build products: " + ", ".join(missing) +
                 "\nRun `make all` first (a previous `make clean-all` removes them).")
    top = int(sys.argv[sys.argv.index("--top") + 1]) if "--top" in sys.argv else 16
    rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
    terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
    targets = json.load(open("analysis/v7-reachability/v7_call_targets.json"))["targets"]

    fails, example = collections.Counter(), {}
    for t in sorted(targets):
        insns = cr.decode_range(rom, terr, t)
        if len(insns) < 3:
            continue
        span = sum(n for _, n, _ in insns)
        want = rom[t - 0xE00000: t - 0xE00000 + span]
        pos = 0
        for _a, n, x in insns:
            target, pos = want[pos:pos + n], pos + n
            if any(cr.cc.encode(c) == target
                   for c in list(cr.cc.translate(x)) + [cr.cc.canonical(x)]):
                continue
            mn = x.split()[0]
            rest = x.split(None, 1)[1] if len(x.split(None, 1)) > 1 else ""
            key = mn + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                                    re.sub(r'\b[A-Z]{1,4}\b', 'r', rest))
            fails[key] += 1
            example.setdefault(key, x)
    print(f"unspellable forms ({sum(fails.values())} instances):")
    for k, v in fails.most_common(top):
        print(f"  {v:5}  {k:26} e.g. {example[k]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
