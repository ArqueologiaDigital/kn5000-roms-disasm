#!/usr/bin/env python3
"""Where does a WSA1 prom_c byte range occur in the KN5000 sub-CPU image, and what is it called there?

QUESTION ANSWERED
  "I am about to write a routine header for prom_c 0xF9806D.  The transplant table
   offers a KN5000 name for it.  Is that name really on THESE bytes, how far does
   the identity actually extend, and which sibling SOURCE LINE do I cite?"

  The transplant table (notes/kn5000-label-transplant-generated.md) answers the first
  half.  It does not tell you where the identical run STOPS, and stopping is where the
  meaning changes -- prom_c 0xF980A5 loads the DSP base 0x00E00000 where the sibling
  loads 0x130000, and that single difference is the whole reason the WSA1's tone
  generator is not the KN5000's.  A header that copied the sibling's comment without
  checking would have written the wrong peripheral address into this tree.

  ⚠ It proves BYTE IDENTITY and nothing else.  Identical code in a different machine
  can still mean something different; every header that uses this must say so.

HOW
  The KN5000 side is the ELF's own unspliced image (addr = 0x400 + file offset holds
  everywhere in it), NEVER original_ROMs/kn5000_subprogram_v142.rom, which the sibling
  Makefile builds with a 60,160-byte hole -- see notes/FINDINGS-kn5000-transplant-offset.md
  and the retraction in scripts/analysis/transplant_kn5000_labels.py.

RUN
  python3 notes/prom_c_sibling_map.py --addr 0xF9806D --len 68
  python3 notes/prom_c_sibling_map.py --addr 0xF9806D --len 68 --source   # print sibling source
  python3 notes/prom_c_sibling_map.py --sym DSP_WriteAllChannelRegs
  python3 notes/prom_c_sibling_map.py --runs --minrun 64
  python3 notes/prom_c_sibling_map.py --addr 0xF98099 --len 81 --diff 0x1FD27
  python3 notes/prom_c_sibling_map.py --selftest
"""
import argparse
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SIB = "/home/fsanches/compartilhado/kn5000-roms-disasm"
ELF = os.path.join(SIB, "rebuilt_ROMs", "kn5000_subprogram_v142.llvm.elf")
SRC = os.path.join(SIB, "v142/subcpu/kn5000_subprogram_v142.s")
BIN = "/home/fsanches/compartilhado/llvm-project/build/bin"
LINK_BASE = 0x0400
IMAGES = {"a": ("wsa1_prom_a.ic12", 0xF80000), "b": ("wsa1_prom_b.ic13", 0xF00000),
          "c": ("wsa1_prom_c.ic28", 0xF80000)}


def kn5000_image():
    tmp = os.path.join(os.environ.get("TMPDIR", "/tmp"), "kn5000_v142_full.bin")
    subprocess.run([os.path.join(BIN, "llvm-objcopy"), "-O", "binary", ELF, tmp], check=True)
    return open(tmp, "rb").read()


def kn5000_symbols():
    out = subprocess.run([os.path.join(BIN, "llvm-nm"), "--numeric-sort", "--defined-only", ELF],
                         capture_output=True, text=True).stdout
    syms = []
    for line in out.splitlines():
        p = line.split()
        if len(p) != 3:
            continue
        addr, typ, name = p
        if typ.lower() == 'a' or name.startswith('.L') or name.startswith('$'):
            continue
        syms.append((int(addr, 16), name))
    return sorted(syms)


def source_lines():
    """label -> 1-based line number in the sibling source, for the file:line citations."""
    out = {}
    with open(SRC, errors="replace") as f:
        for i, ln in enumerate(f, 1):
            m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", ln)
            if m and m.group(1) not in out:
                out[m.group(1)] = i
    return out


def wsa1_image(img):
    fn, base = IMAGES[img]
    return open(os.path.join(ROOT, "original_ROMs", fn), "rb").read(), base


def run_report(img, addr, length, want_source):
    data, base = wsa1_image(img)
    off = addr - base
    if off < 0 or off + length > len(data):
        sys.exit(f"address 0x{addr:X}+{length} outside prom_{img}")
    needle = data[off:off + length]
    kn, syms = kn5000_image(), kn5000_symbols()
    lines = source_lines()

    hits = []
    i = kn.find(needle)
    while i >= 0:
        hits.append(i)
        i = kn.find(needle, i + 1)
    print(f"prom_{img} 0x{addr:06X}..0x{addr + length - 1:06X}  ({length} bytes)")
    if not hits:
        print("  NO occurrence of this exact run in the KN5000 sub-CPU image.")
        return 1
    for off_kn in hits:
        a = LINK_BASE + off_kn
        print(f"  identical at KN5000 0x{a:05X} (file offset 0x{off_kn:05X})")
        # how much further does the identity go, in each direction?
        fwd = 0
        while (off + length + fwd < len(data) and off_kn + length + fwd < len(kn)
               and data[off + length + fwd] == kn[off_kn + length + fwd]):
            fwd += 1
        back = 0
        while (off - back - 1 >= 0 and off_kn - back - 1 >= 0
               and data[off - back - 1] == kn[off_kn - back - 1]):
            back += 1
        print(f"    run extends {back} bytes BEFORE and {fwd} bytes AFTER the range asked for")
        print(f"    -> maximal identical run: prom_{img} 0x{addr - back:06X}..0x{addr + length + fwd - 1:06X}"
              f"  ==  KN5000 0x{a - back:05X}..0x{a + length + fwd - 1:05X}  ({back + length + fwd} bytes)")
        inside = [(s, n) for s, n in syms if a <= s < a + length]
        for s, n in inside:
            cite = f"kn5000_subprogram_v142.s:{lines[n]}" if n in lines else "(no source line found)"
            print(f"    KN5000 0x{s:05X}  {n:40s} -> WSA1 0x{addr + (s - a):06X}   {cite}")
        if not inside:
            prev = [(s, n) for s, n in syms if s <= a]
            if prev:
                s, n = prev[-1]
                print(f"    (no symbol starts inside; nearest preceding is {n} at 0x{s:05X}, {a - s} bytes back)")
        if want_source and inside:
            first = lines.get(inside[0][1])
            last = lines.get(inside[-1][1])
            if first:
                end = (last or first) + 40
                print(f"    ---- {SRC}:{first}..{end} ----")
                with open(SRC, errors="replace") as f:
                    for i2, ln in enumerate(f, 1):
                        if first - 12 <= i2 <= end:
                            print(f"    {i2:6d} | {ln.rstrip()}")
    return 0


def sym_report(name):
    kn, syms = kn5000_image(), kn5000_symbols()
    lines = source_lines()
    match = [(s, n) for s, n in syms if n == name]
    if not match:
        sys.exit(f"no KN5000 symbol named {name}")
    a = match[0][0]
    nxt = [s for s, n in syms if s > a]
    end = nxt[0] if nxt else a + 64
    body = kn[a - LINK_BASE:end - LINK_BASE]
    print(f"KN5000 {name} @ 0x{a:05X}, {len(body)} bytes to the next symbol"
          f"   ({SRC}:{lines.get(name, '?')})")
    for img in ("a", "b", "c"):
        data, base = wsa1_image(img)
        i = data.find(body)
        while i >= 0:
            print(f"  prom_{img} 0x{base + i:06X}  identical over all {len(body)} bytes")
            i = data.find(body, i + 1)
    return 0


def diff_report(img, addr, length, kn_addr):
    """Byte-by-byte difference between a WSA1 range and the KN5000 range it corresponds to.

    For the case the transplant table cannot express: two routines that are the SAME code
    except for a handful of bytes.  Prints every differing offset, so a header can say
    "identical except for the 4-byte peripheral base at 0xF980A5" and have that be a
    counted fact rather than an impression.
    """
    data, base = wsa1_image(img)
    kn = kn5000_image()
    off, koff = addr - base, kn_addr - LINK_BASE
    d1, d2 = data[off:off + length], kn[koff:koff + length]
    if len(d2) < length:
        sys.exit("KN5000 range runs off the end of the image")
    diffs = [i for i in range(length) if d1[i] != d2[i]]
    print(f"prom_{img} 0x{addr:06X}..0x{addr + length - 1:06X}  vs  KN5000 0x{kn_addr:05X}..0x{kn_addr + length - 1:05X}"
          f"   ({length} bytes)")
    print(f"  {length - len(diffs)} of {length} bytes identical; {len(diffs)} differ")
    for i in diffs:
        print(f"    +0x{i:03X}  WSA1 0x{addr + i:06X} = 0x{d1[i]:02X}   KN5000 0x{kn_addr + i:05X} = 0x{d2[i]:02X}")
    return 0


def runs_report(img, minrun, code_only):
    """Every maximal shared run >= minrun between this WSA1 image and the KN5000 image.

    Built on the ELF image, so the KN5000 addresses printed are LINK addresses and can be
    handed straight to the sibling source.  Low-entropy runs (erase fill, padding, short
    repeating periods) are rejected by the same rule scripts/analysis/kn5000_shared_runs.py
    uses -- without it nine tenths of the "shared" mass is 0xFF and 0x00.
    """
    import collections
    data, base = wsa1_image(img)
    kn, syms = kn5000_image(), kn5000_symbols()
    index = collections.defaultdict(list)
    K = 16
    for i in range(len(kn) - K):
        index[kn[i:i + K]].append(i)
    runs, i = [], 0
    while i < len(data) - K:
        cands = index.get(data[i:i + K])
        if not cands:
            i += 1
            continue
        best = (0, None)
        for j in cands:
            n = K
            while i + n < len(data) and j + n < len(kn) and data[i + n] == kn[j + n]:
                n += 1
            b = 0
            while i - b - 1 >= 0 and j - b - 1 >= 0 and data[i - b - 1] == kn[j - b - 1]:
                b += 1
            if n + b > best[0]:
                best = (n + b, j - b, i - b)
        total, j0, i0 = best
        runs.append((i0, j0, total))
        i = i0 + total
    kept = 0
    print(f"# maximal shared runs >= {minrun} B between prom_{img} and the KN5000 sub-CPU ELF image")
    print(f"# {'WSA1':<10} {'KN5000':<9} {'len':>6}  symbols starting inside the run")
    for i0, j0, total in runs:
        if total < minrun:
            continue
        run = data[i0:i0 + total]
        c = collections.Counter(run)
        if len(c) < 12 or c.most_common(1)[0][1] / total > 0.60:
            continue
        a = LINK_BASE + j0
        inside = [n for s, n in syms if a <= s < a + total]
        if code_only and not inside:
            continue
        kept += total
        print(f"  0x{base + i0:06X}   0x{a:05X}   {total:6d}  {', '.join(inside) if inside else '-'}")
    print(f"# {kept:,} bytes in the runs listed")
    return 0


def selftest():
    """The two facts this tool would be useless without."""
    kn = kn5000_image()
    syms = dict((n, s) for s, n in kn5000_symbols())
    ok = True
    # 1. addr = 0x400 + offset really holds in the ELF image: check a known symbol's bytes
    #    against the sibling ROM's spliced position, which must DIFFER by 0xEB00.
    rom = open(os.path.join(SIB, "original_ROMs", "kn5000_subprogram_v142.rom"), "rb").read()
    same = kn[60416:60416 + 64] == rom[256:256 + 64]
    naive = kn[256:256 + 64] == rom[256:256 + 64]
    print(f"  ELF[60416:+64] == ROM[256:+64] : {same}  <- the splice relation")
    print(f"  ELF[256:+64]   == ROM[256:+64] : {naive}  <- must be False")
    ok &= same and not naive
    # 2. a symbol's own first bytes must be at LINK_BASE + offset in the ELF image.
    #    44 = the distance from DSP_WriteAllChannelRegs to the next KN5000 symbol.  It is
    #    NOT the 68 that notes/kn5000-label-transplant-generated.md prints for this row:
    #    that 68 is the length of the whole shared RUN, which starts 9 bytes earlier and
    #    ends inside the next routine's base-address literal.  Confusing the two is how a
    #    reader ends up believing a name covers bytes it does not.
    a = syms["DSP_WriteAllChannelRegs"]
    data, base = wsa1_image("c")
    n = 44
    hit = data[0xF9806D - base:0xF9806D - base + n] == kn[a - LINK_BASE:a - LINK_BASE + n]
    print(f"  prom_c 0xF9806D..+{n} == KN5000 DSP_WriteAllChannelRegs (0x{a:05X}) : {hit}")
    ok &= hit
    # 3. and the run really does extend past the symbol and then break on ONE byte.
    b = data[0xF980A8 - base] != kn[(a + 0xF980A8 - 0xF9806D) - LINK_BASE]
    print(f"  prom_c 0xF980A8 differs from its KN5000 counterpart : {b}"
          "   <- the DSP base address, 0xE0 vs 0x13")
    ok &= b
    print("PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--img", default="c", choices=list(IMAGES))
    ap.add_argument("--addr", type=lambda x: int(x, 0))
    ap.add_argument("--len", type=lambda x: int(x, 0), default=64)
    ap.add_argument("--sym")
    ap.add_argument("--source", action="store_true")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--runs", action="store_true")
    ap.add_argument("--minrun", type=int, default=48)
    ap.add_argument("--code-only", action="store_true")
    ap.add_argument("--diff", type=lambda x: int(x, 0), metavar="KN5000_ADDR",
                    help="byte-diff --addr/--len against this KN5000 link address")
    a = ap.parse_args()
    if a.selftest:
        sys.exit(selftest())
    if a.diff is not None:
        sys.exit(diff_report(a.img, a.addr, a.len, a.diff))
    if a.runs:
        sys.exit(runs_report(a.img, a.minrun, a.code_only))
    if a.sym:
        sys.exit(sym_report(a.sym))
    if a.addr is None:
        ap.error("need --addr or --sym or --selftest")
    sys.exit(run_report(a.img, a.addr, a.len, a.source))
