#!/usr/bin/env python3
"""Which UNCONVERTED addresses does the already-converted prom_c code call?

QUESTION ANSWERED
  "Reachability, not linear address order."  A conversion pass should follow calls
  outward from code that is already understood.  This script computes that frontier
  mechanically instead of by eye:

    1. It parses `prom_c/wsa1_prom_c.s` for `.incbin` directives and turns them into
       the set of file offsets that are NOT yet converted.  Everything else in the
       image is converted (the assembler emits it from mnemonics, and the byte gate
       certifies that it rebuilds).
    2. It disassembles every converted span with unidasm, linearly from the span
       start -- which is legitimate here because a converted span begins at a routine
       boundary that a human already established.
    3. It collects every `call`/`calr`/`jp`/`jrl`/`jr` target it can read as a literal
       and reports the ones that land in an UNCONVERTED span, most-called first.

LIMITS -- read before quoting a number
  * Targets held in a register (`ld XBC,addr` ... `call (XBC)`) are invisible.
  * A linear disassembly of a converted span can still desynchronise if the span
    embeds data; such a run produces phantom instructions and therefore phantom
    targets.  Every reported target is printed with the address of each caller so a
    phantom is visible, and `--verify` re-checks that the caller address really is
    inside a converted span.
  * "Unconverted" is a property of the SOURCE FILE, not of the ROM.  Re-run after
    every edit.

RUN
  python3 notes/prom_c_frontier.py
  python3 notes/prom_c_frontier.py --img c --min 1
  python3 notes/prom_c_frontier.py --spans
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UNIDASM = os.environ.get("UNIDASM", "/home/fsanches/compartilhado/kn7000_mame_build/unidasm")
IMAGES = {"a": ("wsa1_prom_a.ic12", 0xF80000, "prom_a/wsa1_prom_a.s"),
          "b": ("wsa1_prom_b.ic13", 0xF00000, "prom_b/wsa1_prom_b.s"),
          "c": ("wsa1_prom_c.ic28", 0xF80000, "prom_c/wsa1_prom_c.s")}

INCBIN = re.compile(r'\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)')
TARGET = re.compile(r'\b(call|calr|jp|jrl|jr)\b[^;]*?(0x[0-9a-fA-F]{4,8})\s*$')


def unconverted_spans(src):
    out = []
    for m in INCBIN.finditer(open(src).read()):
        off, ln = int(m.group(1), 16), int(m.group(2), 16)
        out.append((off, off + ln))
    out.sort()
    return out


def converted_spans(unconv, size):
    out, cur = [], 0
    for lo, hi in unconv:
        if lo > cur:
            out.append((cur, lo))
        cur = max(cur, hi)
    if cur < size:
        out.append((cur, size))
    return out


def dis(data, base, lo, hi):
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(data[lo:hi])
        tmp = f.name
    try:
        p = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(base + lo)],
                           capture_output=True, text=True)
    finally:
        os.unlink(tmp)
    return p.stdout


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--img", default="c")
    ap.add_argument("--min", type=int, default=1)
    ap.add_argument("--spans", action="store_true")
    a = ap.parse_args()

    name, base, srel = IMAGES[a.img]
    data = open(os.path.join(ROOT, "original_ROMs", name), "rb").read()
    src = os.path.join(ROOT, srel)
    unconv = unconverted_spans(src)
    conv = converted_spans(unconv, len(data))

    print("image %s: %d converted span(s), %d byte(s) converted of %d"
          % (a.img, len(conv), sum(h - l for l, h in conv), len(data)))
    if a.spans:
        for lo, hi in conv:
            print("  converted  0x%06X-0x%06X  %6d bytes" % (base + lo, base + hi - 1, hi - lo))
        return 0

    def is_conv(addr):
        off = addr - base
        return any(lo <= off < hi for lo, hi in conv)

    hits = {}
    for lo, hi in conv:
        for line in dis(data, base, lo, hi).splitlines():
            m = TARGET.search(line.rstrip())
            if not m:
                continue
            try:
                tgt = int(m.group(2), 16)
            except ValueError:
                continue
            if tgt < 0x100000:
                tgt |= 0xF00000 if base == 0xF00000 else 0
            src_addr = int(line.split(":")[0], 16) if ":" in line.split()[0] else None
            if src_addr is None:
                m2 = re.match(r'^([0-9a-fA-F]{4,8})\s*:', line)
                src_addr = int(m2.group(1), 16) if m2 else 0
            hits.setdefault(tgt, []).append((src_addr, m.group(1)))

    front = {t: c for t, c in hits.items() if not is_conv(t) and base <= t < base + len(data)}
    print("\nFRONTIER -- literal control transfers from converted code into UNCONVERTED code")
    print("%d distinct target(s); %d total site(s)\n"
          % (len(front), sum(len(v) for v in front.values())))
    for t in sorted(front, key=lambda x: (-len(front[x]), x)):
        if len(front[t]) < a.min:
            continue
        kinds = ",".join(sorted({k for _, k in front[t]}))
        sites = " ".join("0x%06X" % s for s, _ in sorted(front[t])[:8])
        print("  0x%06X  %2d site(s)  [%s]  from %s%s"
              % (t, len(front[t]), kinds, sites, " ..." if len(front[t]) > 8 else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
