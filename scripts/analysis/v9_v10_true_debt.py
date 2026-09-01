#!/usr/bin/env python3
"""v9_v10_true_debt.py -- the actual remaining debt for v9/v10 maincpu, in
bytes, per the lane brief's definition: "any byte not reproduced by real
source" -- counting BOTH `.incbin` and un-decoded `.byte`/`.word` runs, not
`.incbin` alone.

WHY THIS EXISTS: kn5000_source_coverage.py's headline for these two images
(851,780 B .incbin, 846,852 B of which clang-compiled C) undercounts debt in
two ways this script corrects or flags:

  1. IT SILENTLY UNDERCOUNTS WHEN THE ROM ISN'T FRESHLY BUILT. It resolves
     each `.incbin` path relative to the source tree and `continue`s past
     any that does not exist yet -- `generated/*.bin` are build products
     from `clang -target tlcs900`, not committed files, so on a tree that
     has never run `make`, kn5000_source_coverage.py reported 4,928 B of
     .incbin for v10 instead of the true 851,780 B. MEASURED 2026-09-01,
     confirmed by re-running it before and after `make
     rebuilt_ROMs/kn5000_v10_program.llvm.rom`. This script requires the
     ROM to already exist and refuses to guess otherwise, rather than
     silently reporting a partial total. (Reproduces the exact under-report
     the task brief's warning #2 describes in spirit, just in a different
     tool: a coverage number the tool literally cannot see the whole of.)

  2. `.incbin` ON A LABEL LINE IS INVISIBLE TO A LINE-ANCHORED REGEX.
     scripts/analysis/audit_incbin_legitimacy.py documented this trap for
     itself; v9_v10_undisassembled_census.py's `inject()` has the exact same
     blind spot (`INCB_RE = re.compile(r'^\\s*\\.incbin\\b')`, anchored at
     line start) -- 10,817 B per image of `.incbin` sits on a label line
     (`Name:\\t.incbin "..."`) and was silently mis-bucketed by that tool as
     "non-.incbin DATA" instead of legitimate incbin. This script's INC
     regex is `.search()`, not line-anchored, so it counts both.

  3. `.incbin` BYTE COUNT ALONE IS STILL THE WRONG INSTRUMENT (brief warning
     #1). Long `.byte`/`.word` runs of un-decoded code count as debt too.
     This script reports the non-.incbin DATA territory total (via the same
     llvm-mc -show-encoding flatten as l1_territory_map.py) as a ceiling,
     and cites v9_v10_undisassembled_census.py's calibrated --judge stage
     (already committed, unchanged by this script) for the best current
     estimate of how much of that ceiling is genuinely undecoded CODE.

`.incbin` legitimacy: bytes handed back through `.incbin` are NOT debt when
a committed, round-trip-verified source produced them -- `generated/*.bin`
(clang -target tlcs900, rebuilt every `make`) or `images/*.bin` with a
sibling `.png` and a committed encoder (scripts/build/mono_images.py etc,
audited in full by audit_incbin_legitimacy.py). Anything else is raw debt.

Run (ROM must already be built -- `make rebuilt_ROMs/kn5000_v9_program.llvm.rom
rebuilt_ROMs/kn5000_v10_program.llvm.rom` first):
    python3 scripts/analysis/v9_v10_true_debt.py [v9] [v10]
"""
import glob
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM_MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
SIZE = 2097152

INC = re.compile(r'\.incbin\s+"([^"]+)"(?:\s*,\s*([0-9a-fA-Fx]+)\s*(?:,\s*([0-9a-fA-Fx]+))?)?')
WIDTH = {"byte": 1, "hword": 2, "word": 4, "dword": 8}
ESCAPE = re.compile(r'\\(?:[0-7]{1,3}|x[0-9a-fA-F]{1,2}|.)')
ENCODING = re.compile(r';\s*encoding:\s*\[([^\]]*)\]')


def ascii_len(operand):
    total = 0
    for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', operand):
        total += len(ESCAPE.sub("X", m.group(1)))
    return total


def incbin_breakdown(root):
    """Returns (total, legit, raw_list) -- legit = generated/ (C-compiled) or
    images/*.bin with a sibling .png (round-trip verified elsewhere by
    mono_images.py / indexed_images.py etc). raw_list = [(file, path, size)]
    for anything else -- true .incbin debt."""
    total = legit = 0
    raw = []
    for f in glob.glob(root + "/**/*.s", recursive=True):
        for line in open(f, encoding="latin-1"):
            if line.lstrip().startswith(';'):
                continue
            for m in INC.finditer(line):
                path, off, ln = m.groups()
                real = next((c for c in (os.path.join(os.path.dirname(f), path),
                                         os.path.join(root, path), path)
                            if os.path.exists(c)), None)
                if not real:
                    sys.exit(f"FATAL: {f}: .incbin {path!r} does not exist on "
                             f"disk -- build the ROM first (see module docstring)")
                fsz = os.path.getsize(real)
                size = int(ln, 0) if ln else (fsz - int(off, 0) if off else fsz)
                total += size
                is_legit = "generated/" in path or (
                    "images/" in path and os.path.exists(
                        os.path.splitext(real)[0] + ".png"))
                if is_legit:
                    legit += size
                else:
                    raw.append((f, path, size))
    return total, legit, raw


def territory(target_s, include_dir):
    out = subprocess.run([LLVM_MC, "-triple=tlcs900", "-show-encoding",
                          "-I", include_dir, target_s],
                         capture_output=True, text=True)
    if out.returncode:
        sys.exit(out.stderr[:1000])
    tal = {"CODE": 0, "DATA": 0, "PADDING": 0}
    pos = 0
    for line in out.stdout.split("\n"):
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        e = ENCODING.search(line)
        if e:
            n = len([b for b in e.group(1).split(",") if b.strip()])
            t, k = 1, "CODE"
        else:
            if s.endswith(":") or s.startswith(";"):
                continue
            mm = re.match(r'\.(\w+)\s*(.*)$', s)
            if not mm:
                continue
            d, rest = mm.group(1), mm.group(2).strip()
            if d in WIDTH:
                n = WIDTH[d] * (len([x for x in rest.split(",") if x.strip()]) or 1)
                t, k = 2, "DATA"
            elif d in ("ascii", "asciz"):
                n = ascii_len(rest) + (1 if d == "asciz" else 0)
                t, k = 2, "DATA"
            elif d in ("zero", "fill", "space"):
                p = [x.strip() for x in rest.split(",")]
                n = int(p[0], 0)
                if d == "fill" and len(p) >= 2:
                    n *= int(p[1], 0)
                t, k = 3, "PADDING"
            elif d == "p2align":
                n = (-pos) % (1 << int(rest.split(",")[0].strip(), 0))
                t, k = 3, "PADDING"
            elif d == "org":
                n = max(0, int(rest.split(",")[0].strip(), 0) - pos)
                t, k = 3, "PADDING"
            else:
                continue
        if n:
            tal[k] += n
            pos += n
    return tal


def report(tag):
    root = os.path.join(REPO, tag, "maincpu")
    rom = os.path.join(REPO, "rebuilt_ROMs", f"kn5000_{tag}_program.llvm.rom")
    if not os.path.exists(rom):
        sys.exit(f"{tag}: {rom} missing -- run `make {os.path.relpath(rom, REPO)}` first")
    inc_total, inc_legit, inc_raw = incbin_breakdown(root)
    raw_bytes = sum(sz for _, _, sz in inc_raw)
    tal = territory(os.path.join(root, f"kn5000_{tag}_program.s"), root)
    non_incbin_data = tal["DATA"] - inc_total
    print(f"=== {tag} maincpu ({SIZE:,} B) ===")
    print(f"  .incbin total          {inc_total:>10,} B")
    print(f"    of which legit       {inc_legit:>10,} B  (generated/ C-compiled, "
          f"or images/*.bin with a sibling .png)")
    print(f"    of which RAW (debt)  {raw_bytes:>10,} B", end="")
    if inc_raw:
        print(":")
        for f, path, sz in inc_raw:
            print(f"      {sz:>6,} B  {path}  ({os.path.relpath(f, REPO)})")
    else:
        print("  (none)")
    print(f"  CODE (real instructions)        {tal['CODE']:>10,} B")
    print(f"  PADDING (must be proven filler) {tal['PADDING']:>10,} B")
    print(f"  DATA total                      {tal['DATA']:>10,} B")
    print(f"    of which .incbin               {inc_total:>10,} B")
    print(f"    of which literal .byte/.ascii/  {non_incbin_data:>10,} B  <- "
          f"ceiling for undecoded-code-as-data; see "
          f"v9_v10_undisassembled_census.py --judge for the calibrated estimate "
          f"of how much of this is genuinely CODE")
    print(f"  TRUE DEBT (raw incbin, definite) {raw_bytes:>10,} B")
    print()
    return raw_bytes, non_incbin_data


if __name__ == "__main__":
    tags = sys.argv[1:] or ["v9", "v10"]
    for t in tags:
        report(t)
