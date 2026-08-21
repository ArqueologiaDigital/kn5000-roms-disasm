#!/usr/bin/env python3
"""Which v7 .byte regions are CALLED by code the disassembly already expresses?

Corroboration by v9 content (convert_corroborated_blocks.py) is sound but far too
strict to do the bulk: it needs a block's exact bytes to appear in a different
firmware revision at a code location, and most v7 code simply differs. It caps
out around 500 bytes of the ~158,900 still carried as .byte.

Reachability is the approach that scales, and it fixes the other problem too:

  * IS IT CODE?      If something already disassembled calls this address, it is
                     code. That is evidence about this ROM, not a resemblance to
                     another one.
  * IS IT ALIGNED?   A call target is an instruction boundary by construction.
                     That matters -- a label is NOT necessarily a boundary, and a
                     block decoded from the wrong offset produces garbage that
                     still round-trips byte-exactly, so the build gate cannot
                     catch it. This criterion cannot make that mistake.

Method: take the L1 territory map, collect every `call` target appearing in CODE
territory, and report those landing in DATA territory.

    TLCS-900 call encodings scanned:
        1D <addr24>   call to a 24-bit absolute address
        1E <disp16>   calr, PC-relative

Run:  python3 scripts/analysis/v7_reachable_from_code.py [--top N]

MEASURED 2026-08-22, walking 3,678 contiguous CODE runs:

    808 call targets land in DATA territory
     69 of them (9%) open with a stack-frame prologue

⚠ The 9% is a LOWER bound on real function entries, not a quality ceiling: the
prologue pattern only matches frame set-up (`lda XSP,XSP+...`, `push XIZ`,
`dec N,XSP`), and plenty of leaf functions open with `ld` or `cp` instead. It is
a confidence signal for ranking, not a verdict.

⚠ The remainder does contain junk. `0xED40A7` decodes to `nop ; nop` and
`0xED5465` to `swi 7 ; pop SR` -- those are calls into data, or calls found
inside a CODE run that was itself mis-framed. Read a target before converting it.

⚠ FIRST VERSION OF THIS SCRIPT WAS WRONG and the mistake is worth keeping. It
scanned BYTES in code territory for the call opcodes rather than walking
instructions. 0x1D and 0x1E occur constantly inside other instructions' operands,
so it reported 1,069 "targets" whose first instructions were `reti ; reti`,
`nop ; nop`, `halt ; halt` -- and a total span of 2,247,403 bytes in a 2,097,152
byte ROM, which was the tell. An opcode byte is not an instruction.
"""
import importlib.util, os, re, struct, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
BASE = 0xE00000
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")

spec = importlib.util.spec_from_file_location("spans", os.path.join(HERE, "v7_undisassembled_spans.py"))
spans = importlib.util.module_from_spec(spec); spec.loader.exec_module(spans)


def main():
    top = int(sys.argv[sys.argv.index("--top") + 1]) if "--top" in sys.argv else 20
    rom = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
    terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))

    # Walk instructions, do not scan bytes. A byte scan for the call opcodes
    # reports mostly noise -- 0x1D and 0x1E occur inside other instructions'
    # operands -- and the first version of this script produced 1,069 "targets"
    # decoding to `reti ; reti`, `nop ; nop`, `halt ; halt`, with a total span
    # larger than the ROM itself. Decoding each contiguous CODE run and reading
    # the call targets out of the disassembly removes that entire class.
    runs = []
    i = 0
    while i < len(terr):
        if terr[i] == 1:
            j = i
            while j < len(terr) and terr[j] == 1:
                j += 1
            if j - i >= 8:
                runs.append((i, j))
            i = j
        else:
            i += 1
    call_re = re.compile(r'\b(?:call|calr)\s+(?:\w+,\s*)?0x([0-9a-f]+)')
    targets = {}
    tmp = "/tmp/_reach_run.bin"
    for a, b in runs:
        open(tmp, "wb").write(rom[a:b])
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(BASE + a)],
                             capture_output=True, text=True).stdout
        for m in call_re.finditer(out):
            t = int(m.group(1), 16)
            off = t - BASE
            if 0 <= off < len(rom) and terr[off] == 2:
                targets[t] = targets.get(t, 0) + 1
    print(f"walked {len(runs)} contiguous CODE runs")

    # how far does each target run before leaving DATA territory?
    rows = []
    for t, n in targets.items():
        off = t - BASE
        end = off
        while end < len(terr) and terr[end] == 2:
            end += 1
        rows.append((t, n, end - off))
    rows.sort(key=lambda r: -r[2])
    total = sum(r[2] for r in rows)

    # A target that opens with a stack-frame prologue is very likely a real
    # function entry; one that opens with `nop ; nop` or `swi 7` is very likely
    # a call into data or a misdecoded run. Counting them separates the two
    # rather than presenting 808 addresses as uniformly trustworthy.
    PROLOGUE = re.compile(r'^(lda\s+XSP,XSP|push\s+XIZ|dec\s+\d+,XSP|'
                          r'lda\s+XBC,XSP|pushw?\s)', re.I)
    good = 0
    for t, n, run in rows:
        tmp = "/tmp/_reach_head.bin"
        open(tmp, "wb").write(rom[t - BASE: t - BASE + 12])
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(t)],
                             capture_output=True, text=True).stdout
        head = [l.split(None, 2)[-1].strip() for l in out.split("\n")[:1] if ":" in l]
        if head and PROLOGUE.match(head[0]):
            good += 1
    print(f"   of which open with a function prologue: {good} "
          f"({100.0*good/max(len(rows),1):.0f}%)")
    print(f"{len(rows)} call targets land in DATA territory, "
          f"spanning {total:,} bytes of .byte to the next code boundary")
    print(f"{'address':>10}  {'callers':>7}  {'run':>8}   first instructions")
    for t, n, run in rows[:top]:
        tmp = "/tmp/_reach.bin"
        open(tmp, "wb").write(rom[t - BASE: t - BASE + 24])
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(t)],
                             capture_output=True, text=True).stdout
        first = [l.split(None, 2)[-1] for l in out.split("\n")[:2] if ":" in l]
        print(f"  0x{t:06X}  {n:7}  {run:8,}   {' ; '.join(first)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
