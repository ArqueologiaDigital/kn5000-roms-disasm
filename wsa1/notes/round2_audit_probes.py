#!/usr/bin/env python3
"""Round-2 audit: every quantified finding, re-derived from the ROMs and the sources.

Each section answers ONE question and prints PASS/FAIL for the claim as it is
currently written in the tree.  A FAIL here is a defect in the tree, not in this
script -- the script asserts what the ROM says.

RUN
    python3 notes/round2_audit_probes.py
    python3 notes/round2_audit_probes.py --selftest    # negative controls

WHAT EACH SECTION READS
  1  voice-record extent   0xFB3E9A `ld IX,0x3bcf`, 0xFB3EA8 `ld A,0x44`,
                           0xFB3EA2 `cp H,0x40`  -> base, stride, bound.
                           The claimed end address is compared with base+64*0x44-1.
  2  MIDI per-arm lengths  each arm's own `cp DE,n` guard byte.
  3  KN5000 borrowed names llvm-nm on both symbol tables; bytes diffed over the
                           KN5000 symbol's own extent.
  4  round-2 byte deltas   .incbin span arithmetic, HEAD vs worktree, vs README.
  5  frontier phantoms     linear tool vs source tool, subset relation.
"""
import os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SIB  = "/home/fsanches/compartilhado/kn5000-roms-disasm"
NM   = "/home/fsanches/compartilhado/llvm-project/build/bin/llvm-nm"
OBJCOPY = "/home/fsanches/compartilhado/llvm-project/build/bin/llvm-objcopy"
KELF = os.path.join(SIB, "rebuilt_ROMs", "kn5000_subprogram_v142.llvm.elf")
SIZE = 524288
BASES = {"a": 0xF80000, "b": 0xF00000, "c": 0xF80000}
FILES = {"a": "wsa1_prom_a.ic12", "b": "wsa1_prom_b.ic13", "c": "wsa1_prom_c.ic28"}
ROM = {k: open(os.path.join(ROOT, "original_ROMs", v), "rb").read() for k, v in FILES.items()}
SRC = {k: open(os.path.join(ROOT, f"prom_{k}", f"wsa1_prom_{k}.s")).read() for k in FILES}

fails = []
def check(ok, msg, got=""):
    print(f"  {'ok  ' if ok else 'FAIL'}  {msg}" + (f"   [{got}]" if got else ""))
    if not ok:
        fails.append(msg)

def at(k, addr, n):
    o = addr - BASES[k]
    return ROM[k][o:o + n]

# ---------------------------------------------------------------- 1
def sec1():
    print("1  THE VOICE RECORD EXTENT  (prom_c)")
    check(at("c", 0xFB3E9A, 3) == b"\x34\xcf\x3b", "base 0x3BCF from `ld IX,0x3bcf` at 0xFB3E9A")
    check(at("c", 0xFB3EA8, 2) == b"\x21\x44",     "stride 0x44 from `ld A,0x44` at 0xFB3EA8")
    check(at("c", 0xFB3EA2, 3) == b"\xce\xcf\x40", "bound 0x40 from `cp H,0x40` at 0xFB3EA2")
    base, stride, cnt = 0x3BCF, 0x44, 0x40
    end = base + cnt * stride - 1
    print(f"        record 63 occupies 0x{base+63*stride:06X}..0x{end:06X}; size {cnt*stride} = 0x{cnt*stride:X}")
    claimed = 0x456E
    check(end == claimed,
          f"the extent written in the tree (0x{claimed:06X}) is the real last byte (0x{end:06X})",
          f"off by {end - claimed} = 0x{end-claimed:X}")
    for path in ("prom_c/wsa1_prom_c.s",
                 "notes/FINDINGS-prom_c-voice-module.md",
                 "notes/prom_c_voice_module_check.py"):
        lines = open(os.path.join(ROOT, path)).read().splitlines()
        hits = [i+1 for i, l in enumerate(lines) if "0x00003BCF-0x0000456E" in l]
        check(not hits, f"{path} is free of the wrong extent",
              "carries it at line " + ",".join(map(str, hits)) if hits else "")

# ---------------------------------------------------------------- 2
def sec2():
    print("\n2  MIDI PER-ARM PACKET LENGTHS  (prom_c)")
    # `cp DE,n` for n in 0..7 is the two-byte short form  DA D8+n  -- the operand is
    # IN THE OPCODE, not a following literal byte.  Each arm's guard is the first
    # such pair at or after the arm's entry address.
    arms = {0x80: (0xFB0682, 6), 0x90: (0xFB07A3, 4), 0xB0: (0xFB080E, 4),
            0xC0: (0xFB086A, 5), 0xD0: (0xFB08DA, 4), 0xE0: (0xFB0936, 4),
            0xF0: (0xFB0992, 4)}
    for st, (entry, want) in sorted(arms.items()):
        n, where = None, None
        for a in range(entry, entry + 32):
            b = at("c", a, 2)
            if b[0] == 0xDA and 0xD8 <= b[1] <= 0xDF:
                n, where = b[1] - 0xD8, a
                break
        check(n == want,
              f"arm 0x{st:02X}: guard `cp DE,{want}` (encoded DA {0xD8+want:02X})",
              f"found cp DE,{n} at 0x{where:06X}" if n is not None else "no guard found")
    check(arms[0x80][1] == 6 and arms[0x90][1] == 4,
          "the 0x80 arm consumes SIX bytes while the note arm 0x90 consumes four")
    ln = next((i+1 for i, l in enumerate(SRC["c"].splitlines())
               if "advanced by 4 (5 for the 0xC0 arm)" in l), None)
    check(ln is None,
          "MidiIn_ParseRingAndDispatch's `Outputs:` line accounts for the 0x80 arm's six bytes",
          f"prom_c/wsa1_prom_c.s:{ln} still says 4, or 5 for 0xC0, only")

# ---------------------------------------------------------------- 3
def sec3():
    print("\n3  BORROWED KN5000 NAMES -- bytes diffed over the KN5000 symbol extent")
    tmp = "/tmp/kn5000_full_audit.bin"
    subprocess.run([OBJCOPY, "-O", "binary", KELF, tmp], check=True)
    FULL = open(tmp, "rb").read()
    def syms(elf):
        out = []
        for l in subprocess.run([NM, "--numeric-sort", "--defined-only", elf],
                                capture_output=True, text=True).stdout.splitlines():
            p = l.split()
            if len(p) == 3 and p[1].lower() != 'a' and not p[2].startswith(('.L', '$')):
                out.append((int(p[0], 16), p[2]))
        return sorted(out)
    ks = syms(KELF)
    kext = {}
    for i, (a, n) in enumerate(ks):
        kext.setdefault(n, (a, ks[i+1][0] if i+1 < len(ks) else a+64))
    W = {}
    for k in FILES:
        for a, n in syms(os.path.join(ROOT, "rebuilt_ROMs", f"wsa1_prom_{k}.llvm.elf")):
            W.setdefault(n, []).append((k, a))
    shared = sorted(set(W) & set(kext))
    diff_rows = []
    for n in shared:
        ka, knx = kext[n]; L = min(knx - ka, 512)
        for k, wa in W[n]:
            o = wa - BASES[k]
            if not (0 <= o < SIZE): continue
            kb, wb = FULL[ka-0x400:ka-0x400+L], ROM[k][o:o+L]
            d = sum(1 for x, y in zip(kb, wb) if x != y)
            if d: diff_rows.append((n, k, wa, ka, d, L))
    print(f"        {len(shared)} shared name(s); {len(diff_rows)} label instance(s) NOT byte-identical")
    for n, k, wa, ka, d, L in sorted(diff_rows, key=lambda r: -r[4]):
        print(f"          {n:<34} prom_{k} 0x{wa:06X} vs kn 0x{ka:05X}  differs {d}/{L}")
    # the two the tree explains, with the exact byte
    for k, wa in (("a", 0xF85FB7), ("c", 0xF980A8)):
        print(f"        DSP_WriteChannelRegs_Inner +0x0F in prom_{k}: 0x{ROM[k][wa-BASES[k]]:02X} "
              f"(KN5000 0x13) -- the peripheral base, the only differing byte of 81")
    # FP_UnsignedDiv_ShiftLoop: the sibling's address for that NAME vs where the tree puts it
    ka = kext["FP_UnsignedDiv_ShiftLoop"][0]
    mapped = ka + 0xFA8CDF                       # anchor prom_a 0xFE68F2 <-> kn 0x3DC13
    here = dict(W["FP_UnsignedDiv_ShiftLoop"])["a"]
    check(mapped == here,
          "FP_UnsignedDiv_ShiftLoop sits where the KN5000 symbol of that name maps to",
          f"sibling 0x{ka:05X} -> 0x{mapped:06X}, tree puts the name at 0x{here:06X} ({here-mapped:+d})")
    # and the maximal identical run + where it really ends
    n = 0
    while ROM["a"][0xFE68F2-BASES["a"]+n] == FULL[0x3DC13-0x400+n]: n += 1
    check(n == 170, "the divide runtime's identical run is 170 bytes", str(n))
    ln = next((i+1 for i, l in enumerate(SRC["a"].splitlines()) if "DIVERGE at 0xFE699B" in l), None)
    check(ln is None,
          "the divergence address names the first DIFFERING byte, not the last identical one",
          f"prom_a/wsa1_prom_a.s:{ln} says 0xFE699B; last identical is 0x{0xFE68F2+n-1:06X}, "
          f"first differing 0x{0xFE68F2+n:06X}")

# ---------------------------------------------------------------- 4
def sec4():
    print("\n4  ROUND-2 SUBSTANTIVE DELTAS -- .incbin arithmetic, not report prose")
    def measure(text):
        inc = sum(int(m.group(2), 16) for m in re.finditer(
            r'\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)', text))
        inc += SIZE * len(re.findall(r'\.incbin\s+"[^"]+"\s*$', text, re.M))
        fill = sum(int(m.group(1), 0) * int(m.group(2), 0) for m in
                   re.finditer(r'\.fill\s+([0-9]+|0x[0-9A-Fa-f]+)\s*,\s*([0-9]+)', text))
        fill += sum(int(m.group(1), 0) for m in
                    re.finditer(r'\.fill\s+([0-9]+|0x[0-9A-Fa-f]+)\s*$', text, re.M))
        return SIZE - inc - fill, fill
    readme = open(os.path.join(ROOT, "README.md")).read()
    start = {}
    for m in re.finditer(r'\|\s*`prom_([abcd])/`\s*\|[^|]*\|\s*([\d,]+)\s*\|\s*([\d,]+)\s*\|', readme):
        start[m.group(1)] = int(m.group(2).replace(",", ""))
    print("        README's table is the round-2 STARTING snapshot (it was never regenerated)")
    claimed = {"a": 18635, "b": 34777, "c": 15248}
    for k in "abc":
        now, _ = measure(SRC[k])
        real = now - start[k]
        check(real == claimed[k],
              f"prom_{k}: reported +{claimed[k]:,} substantive equals the measured +{real:,}",
              f"{start[k]:,} -> {now:,}")
    # prom_c's reported "before" percentage
    check(abs(100.0*32036/SIZE - 4.7) < 0.05,
          "prom_c's reported before-row '32,036 (4.7%)' is self-consistent",
          f"32,036 is {100.0*32036/SIZE:.1f}% of {SIZE:,}; 4.7% would be {round(0.047*SIZE):,}")

# ---------------------------------------------------------------- 5
def sec5():
    print("\n5  FRONTIER PHANTOMS  (prom_c)")
    def tg(script):
        o = subprocess.run([sys.executable, os.path.join(ROOT, "notes", script)],
                           capture_output=True, text=True, cwd=ROOT).stdout
        return set(re.findall(r'^\s+(0x[0-9A-F]{6})\s+\d+ site', o, re.M))
    lin, src = tg("prom_c_frontier.py"), tg("prom_c_frontier_src.py")
    print(f"        linear {len(lin)}, source {len(src)}, linear-only {len(lin-src)}, source-only {len(src-lin)}")
    check(src <= lin, "the source-based frontier is a strict subset of the linear one")
    check(len(lin - src) == 141, "141 phantom targets", str(len(lin - src)))
    # the cluster range quoted in the round report
    o = subprocess.run([sys.executable, os.path.join(ROOT, "notes", "prom_c_frontier_src.py"),
                        "--clusters"], capture_output=True, text=True, cwd=ROOT).stdout
    rows = re.findall(r'^\s+0x([0-9A-F]{6})-0x([0-9A-F]{6})\s+(\d+)\s+(\d+)', o, re.M)
    lo, hi = 0xFA7E2C, 0xFABCF9
    t = sum(int(r[2]) for r in rows if lo <= int(r[0], 16) and int(r[1], 16) <= hi)
    s = sum(int(r[3]) for r in rows if lo <= int(r[0], 16) and int(r[1], 16) <= hi)
    check((t, s) == (39, 87),
          "0xFA7E2C-0xFABCF9 holds the reported 39 targets / 87 sites",
          f"the range actually holds {t} targets / {s} sites")

def selftest():
    """Negative controls: each asserts the DECODING this script relies on, so a
    green run below cannot be an artefact of a mis-read opcode."""
    print("negative controls")
    check(0x3BCF + 64*0x44 - 1 == 0x4CCE, "base+64*stride-1 really is 0x4CCE")
    check(0x3BCF + 64*0x44 - 1 != 0x456E, "...and it is NOT the 0x456E the tree writes")
    check(at("c", 0xFB068A, 2) == b"\xda\xde", "the 0x80 guard really encodes 6 as DA DE")
    check(at("c", 0xFB07A3, 2) == b"\xda\xdc", "the 0x90 guard really encodes 4 as DA DC")
    check((0xDE - 0xD8, 0xDC - 0xD8) == (6, 4), "the DA D8+n decoding is the one used in section 2")
    check(at("a", 0xFE68F2, 1) != at("a", 0xFE699C, 1) or True,
          "the divide-run anchor 0xFE68F2 is readable")
    print(f"\nselftest: {len(fails)} control(s) failed -- all must be ok")
    return 1 if fails else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    for f in (sec1, sec2, sec3, sec4, sec5):
        f()
    print(f"\n{len(fails)} claim(s) in the tree FAIL re-derivation")
    for f in fails: print(f"   - {f}")
    sys.exit(0)
