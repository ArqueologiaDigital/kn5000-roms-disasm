#!/usr/bin/env python3
"""Where is v7's disassembly thinner than v9's, and is that gap real CODE?

The L1 territory map (l1_territory_map.py) measured v7 at 25.86% CODE against
v9/v10's 47.83% -- roughly 460 KB less code and 469 KB more data. The 288
committed ROM slices explain 136,775 B of it. This script locates the rest.

It builds a per-BYTE territory map for v7 and for v9 and reports every span of
at least 256 bytes that v7 carries as DATA while v9 carries the same offsets as
CODE. Those are candidates for code that is present in v7 but not yet expressed
as instructions.

MEASURED 2026-08-21:  258 spans, 158,902 bytes.

⚠ Same offset is not the same function. v7 and v9 are different firmware
revisions, so this is a CANDIDATE list, not a proof, and a span only becomes
evidence when it disassembles. Four were checked by hand at the time of writing
and all four are unmistakably real TLCS-900 code:

    0xFD3095  5,030 B  an unrolled bit-extraction loop -- ldcf 7,(XHL) / scc C,A
                       / and A,0x01 / sla 0x07,A / and (XIX),0x7f / or (XIX),A,
                       repeating for bits 6, 5, 4 ...
    0xF2D29A  4,520 B  function prologue: lda XSP,XSP+0xf2 then a struct set-up
    0xF19608  3,317 B  the same prologue shape, a near-twin of the above
    0xFDE939  2,816 B  a table lookup: lda XIX,0xee8ea2 / ld A,(XIX+WA)

Run:  python3 scripts/analysis/v7_undisassembled_spans.py [--min BYTES] [--top N]
      python3 scripts/analysis/v7_undisassembled_spans.py --disasm 5
          also disassembles the head of the N largest spans, so a reviewer can
          see for themselves rather than take the list on trust.
"""
import importlib.util, os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("l1", os.path.join(HERE, "l1_territory_map.py"))
l1 = importlib.util.module_from_spec(spec); spec.loader.exec_module(l1)

BASE, SIZE = 0xE00000, 2097152
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")


def runs(root_s, incdir):
    out = subprocess.run([l1.MC, "-triple=tlcs900", "-show-encoding", "-I", incdir, root_s],
                         capture_output=True, text=True, cwd=l1.ROOT)
    if out.returncode != 0:
        sys.exit(f"llvm-mc failed on {root_s}")
    pos, res = 0, []
    for line in out.stdout.split("\n"):
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        enc = l1.ENCODING.search(line)
        if enc:
            n = len([b for b in enc.group(1).split(",") if b.strip()]); t = "CODE"
        else:
            if s.endswith(":") or s.startswith(";"):
                continue
            m = re.match(r'\.(\w+)\s*(.*)$', s)
            if not m:
                continue
            d, rest = m.group(1), m.group(2).strip()
            if d in l1.WIDTH:
                n = l1.WIDTH[d] * (len([x for x in rest.split(",") if x.strip()]) or 1); t = "DATA"
            elif d in ("ascii", "asciz"):
                n = l1.ascii_len(rest) + (1 if d == "asciz" else 0); t = "DATA"
            elif d in ("zero", "fill", "space"):
                p = [x.strip() for x in rest.split(",")]; n = int(p[0], 0)
                if d == "fill" and len(p) >= 2:
                    n *= int(p[1], 0)
                t = "PADDING"
            elif d == "p2align":
                n = (-pos) % (1 << int(rest.split(",")[0].strip(), 0)); t = "PADDING"
            elif d == "org":
                n = max(0, int(rest.split(",")[0].strip(), 0) - pos); t = "PADDING"
            else:
                continue
        if n:
            res.append((pos, pos + n, t)); pos += n
    return res


def territory(rs):
    code = {"CODE": 1, "DATA": 2, "PADDING": 3}
    m = bytearray(SIZE)
    for a, b, t in rs:
        m[a:b] = bytes([code[t]]) * (b - a)
    return m


def main():
    argv = sys.argv
    minlen = int(argv[argv.index("--min") + 1]) if "--min" in argv else 256
    top = int(argv[argv.index("--top") + 1]) if "--top" in argv else 15
    ndis = int(argv[argv.index("--disasm") + 1]) if "--disasm" in argv else 0

    m7 = territory(runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
    m9 = territory(runs("v9/maincpu/kn5000_v9_program.s", "v9/maincpu"))
    spans, start = [], None
    for i in range(SIZE):
        hit = (m7[i] == 2 and m9[i] == 1)
        if hit and start is None:
            start = i
        elif not hit and start is not None:
            if i - start >= minlen:
                spans.append((start, i))
            start = None
    if start is not None and SIZE - start >= minlen:
        spans.append((start, SIZE))
    total = sum(b - a for a, b in spans)
    print(f"v7 DATA where v9 has CODE: {len(spans)} spans >= {minlen} B, {total:,} bytes")
    big = sorted(spans, key=lambda x: -(x[1] - x[0]))
    for a, b in big[:top]:
        print(f"   0x{BASE+a:06X}..0x{BASE+b:06X}   {b-a:>8,} B")
    for a, b in big[:ndis]:
        print(f"\n--- head of 0x{BASE+a:06X} ({b-a:,} B)")
        rom = os.path.join(l1.ROOT, "original_ROMs", "kn5000_v7_program.rom")
        blob = open(rom, "rb").read()[a:a + 40]
        tmp = "/tmp/_v7span.bin"; open(tmp, "wb").write(blob)
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(BASE + a)],
                             capture_output=True, text=True).stdout
        print("\n".join(out.split("\n")[:8]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
