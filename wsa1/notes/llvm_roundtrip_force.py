#!/usr/bin/env python3
"""llvm_roundtrip.py, plus the ability to force chosen instructions to `.byte`.

WHY THIS EXISTS
  scripts/analysis/llvm_roundtrip.py demotes an instruction to `.byte` when the
  assembled output differs from the ROM, and it finds the offender by locating
  the first differing BYTE.  That only works while the candidate listing has the
  same LENGTH as the range: if some instruction assembles to a different number
  of bytes, every later byte shifts, the "first difference" is byte 0, and the
  loop demotes the first instruction over and over and gives up with
  "cannot converge at byte 0".

  prom_b 0xF5533C hits exactly that: `push 0x00` (ROM `09 00`) is spelled by the
  LLVM disassembler in a form its assembler encodes at a different width.

  This wrapper reuses the committed script's own functions -- same unidasm, same
  llvm_spell, same assemble-and-compare -- and adds `--force`, plus a fallback
  that demotes EVERY instruction whose own bytes do not round-trip individually
  when the length-based search cannot make progress.  A listing it prints has
  still been proven byte-for-byte against the ROM before printing.

RUN
  python3 notes/llvm_roundtrip_force.py b 0xF5533C 0x1F
  python3 notes/llvm_roundtrip_force.py b 0xF5533C 0x1F --force 0xF55341
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import llvm_roundtrip as LR


def build(blk, addr, ins, forced):
    lines, meta = [], []
    for a, n, txt in ins:
        bs = bytes(blk[a - addr:a - addr + n])
        sp = None if a in forced else LR.llvm_spell(bs)
        if sp:
            lines.append("\t%s\t; %06X  %s\n" % (sp, a, txt))
        else:
            lines.append("\t.byte %s\t; %06X  %s   [llvm-mc cannot encode this]\n"
                         % (", ".join("0x%02X" % x for x in bs), a, txt))
        meta.append((a, n))
    return lines, meta


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        return 2
    img, addr, ln = sys.argv[1], int(sys.argv[2], 0), int(sys.argv[3], 0)
    forced = set()
    if "--force" in sys.argv:
        forced = {int(x, 0) for x in sys.argv[sys.argv.index("--force") + 1].split(",")}
    name, base = LR.IMAGES[img]
    data = open(os.path.join(ROOT, "original_ROMs", name), "rb").read()
    blk = data[addr - base:addr - base + ln]
    ins = LR.unidasm(blk, addr)

    for attempt in range(len(ins) + 2):
        lines, meta = build(blk, addr, ins, forced)
        out, err = LR.assemble(lines)
        if out is None:
            print(err, file=sys.stderr)
            return 3
        if out == blk:
            break
        if len(out) != len(blk):
            # a width mismatch: demote every instruction that does not
            # individually re-assemble to its own bytes
            grew = False
            for a, n, txt in ins:
                if a in forced:
                    continue
                bs = bytes(blk[a - addr:a - addr + n])
                sp = LR.llvm_spell(bs)
                one, _ = LR.assemble(["\t%s\n" % sp]) if sp else (None, "")
                if one != bs:
                    forced.add(a)
                    grew = True
            if not grew:
                print("  width mismatch and nothing left to demote", file=sys.stderr)
                return 4
            continue
        i = next(k for k in range(len(blk)) if out[k] != blk[k])
        cum, victim = 0, None
        for a, n in meta:
            if cum <= i < cum + n:
                victim = a
                break
            cum += n
        if victim is None or victim in forced:
            print("  cannot converge at byte %d" % i, file=sys.stderr)
            return 4
        forced.add(victim)
    else:
        print("  did not converge", file=sys.stderr)
        return 4

    nb = sum(1 for l in lines if l.lstrip().startswith(".byte"))
    print("  %d instructions, %d verified by llvm-mc, %d left as .byte  (forced: %s)"
          % (len(lines), len(lines) - nb, nb,
             ", ".join("0x%06X" % x for x in sorted(forced)) or "none"),
          file=sys.stderr)
    sys.stdout.write("".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
