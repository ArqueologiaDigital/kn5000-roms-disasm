#!/usr/bin/env python3
"""Question answered: of the raw `.byte` operands in a v10 maincpu source file,
how many are (a) real CODE the source failed to decode, (b) STRUCTURED DATA
that is not typed, and (c) a genuine byte-valued table that is already
correctly represented?

Why this is not just a grep.  `.byte` count alone is the wrong instrument in
both directions:

  * a `.byte` inside an instruction stream is usually one un-decoded opcode
    whose *neighbours are also misframed* -- the lines printed around it are
    resync garbage that happens to re-emit the right bytes, so the byte gate
    is blind to it;
  * a long `.byte` run may be a perfectly good byte table, i.e. not debt at
    all;
  * and a long `.byte` run may be a pointer array that a previous pass carved
    at the WRONG START OFFSET, leaving the first bytes of the array spelled as
    fake instructions before the run begins.

The classifier therefore works on label-delimited REGIONS, and asks two
independent questions of each region:

  POINTER-ARRAY TEST -- for each start alignment k in 0..3, read the region as
  little-endian u32 and find the longest run of consecutive words that all lie
  in a plausible target window (ROM 0x00E00000-0x00FFFFFF, or work RAM
  0x00000000-0x0001FFFF).  A run of >= MIN_PTRS words is decisive: random code
  does not produce 8 consecutive in-range 32-bit pointers.  The winning k is
  the TRUE start offset of the array, which is how the off-by-one carves in
  this tree are detected.

  DECODE TEST -- linear-sweep the region through `llvm-mc -disassemble` and
  count bytes the current toolchain cannot decode.  A region that decodes with
  zero invalid bytes is a region whose `.byte` lines are pure representation
  debt: the assembler CAN spell every instruction in it today.

CLASSIFICATION
  (b) DATA-UNTYPED  pointer-array test fires (>= MIN_PTRS in-range words)
  (a) CODE-AS-BYTE  otherwise, and the region decodes with 0 invalid bytes
  (a-partial)       otherwise, and the region decodes with some invalid bytes
                    -- the decodable part is (a), the invalid bytes stay .byte
  (c) BYTE-TABLE    otherwise, and the region is >= 90% `.byte` with no
                    pointer structure -- already correctly represented

HOW THIS CAN BE WRONG, AND THE CONTROL
  The decode test is the data-as-code trap in person: DATA disassembles into
  plausible instructions and re-assembles to the same bytes, so "decodes
  cleanly" is NOT evidence of code.  That is why the pointer test runs FIRST
  and wins.  It can still be wrong two ways:
    - false DATA: a code region that happens to contain MIN_PTRS consecutive
      in-range words.  Measured below against known-code control regions.
    - false CODE: a data region with no pointer structure (a coordinate or
      glyph table) that decodes cleanly.  This is why nothing is converted to
      instructions on the decode test alone -- see --control.

  --control measures both error rates against regions of KNOWN class in the
  same files:
      known DATA  = regions already typed `.long` / `.ascii` by the tree
      known CODE  = regions with zero `.byte`, entered by a call/jp/jr
  and reports how often the classifier disagrees with the known label.

Exact commands (from the repo root):

    python3 scripts/analysis/v10_line_address_map.py \
        v10/maincpu/midi/midi_dispatch_handlers.s \
        v10/maincpu/display/scoop_display.s --out /tmp/linemap.json
    python3 scripts/analysis/v10_byte_run_classifier.py --linemap /tmp/linemap.json \
        v10/maincpu/midi/midi_dispatch_handlers.s \
        v10/maincpu/display/scoop_display.s
    python3 scripts/analysis/v10_byte_run_classifier.py --linemap /tmp/linemap.json \
        --control v10/maincpu/midi/midi_dispatch_handlers.s \
        v10/maincpu/display/scoop_display.s
"""
import argparse
import json
import os
import re
import subprocess
import sys

ROM_BASE = 0xE00000
LLVM = os.environ.get("LLVM_BIN",
                      os.path.expanduser("~/compartilhado/llvm-project/build/bin"))
MIN_PTRS = 8            # consecutive in-range u32 that make a pointer array
ROM_LO, ROM_HI = 0x00E00000, 0x00FFFFFF
RAM_LO, RAM_HI = 0x00000000, 0x0001FFFF

LABEL_RE = re.compile(r"^([A-Za-z_.$][A-Za-z0-9_.$]*):\s*(;.*)?$")


def load_rom(root):
    return open(os.path.join(root, "original_ROMs/kn5000_%s_program.rom"
                             % os.environ.get("KN5000_IMAGE", "v10")), "rb").read()


def parse(path, lm):
    """Return list of regions: dict(label, start_line, end_line, addr, end_addr)."""
    lines = open(path, encoding="latin-1").read().split("\n")
    labels = []
    for i, l in enumerate(lines, 1):
        m = LABEL_RE.match(l)
        if m and i in lm:
            labels.append((i, m.group(1)))
    regions = []
    for idx, (ln, name) in enumerate(labels):
        end_line = labels[idx + 1][0] if idx + 1 < len(labels) else len(lines)
        addr = lm[ln]
        end_addr = lm[labels[idx + 1][0]] if idx + 1 < len(labels) else None
        if end_addr is None:
            nxt = [lm[k] for k in lm if k > ln]
            end_addr = max(nxt) if nxt else addr
        regions.append(dict(label=name, ln=ln, end_line=end_line,
                            addr=addr, end=end_addr))
    return lines, regions


def in_target(v):
    return (ROM_LO <= v <= ROM_HI) or (RAM_LO <= v <= RAM_HI)


def ptr_run(data):
    """Longest run of consecutive in-range LE u32, over start alignments 0..3.
    Returns (best_run_len, best_k, run_start_index)."""
    best = (0, 0, 0)
    for k in range(4):
        run = 0
        start = k
        i = k
        while i + 4 <= len(data):
            v = int.from_bytes(data[i:i + 4], "little")
            if in_target(v):
                if run == 0:
                    start = i
                run += 1
                if run > best[0]:
                    best = (run, k, start)
            else:
                run = 0
            i += 4
    return best


def decode(rom, addr, end):
    data = rom[addr - ROM_BASE:end - ROM_BASE]
    if not data:
        return 0, 0, []
    inp = " ".join("0x%02x" % c for c in data)
    r = subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900",
                        "-disassemble"], input=inp, capture_output=True, text=True)
    bad = set()
    for m in re.finditer(r"^<stdin>:1:(\d+): warning: invalid instruction encoding",
                         r.stderr, re.M):
        col = int(m.group(1))
        bad.add((col - 1) // 5)
    text = [l for l in r.stdout.split("\n") if l.strip()]
    return len(data), len(bad), text


def byte_bytes(lines, a, b):
    n = 0
    for l in lines[a - 1:b - 1]:
        s = l.strip()
        if s.startswith(".byte"):
            n += len(s[5:].split(","))
    return n


def classify(rom, lines, reg):
    data = rom[reg["addr"] - ROM_BASE:reg["end"] - ROM_BASE]
    nb = byte_bytes(lines, reg["ln"], reg["end_line"])
    reg["size"] = len(data)
    reg["nbyte"] = nb
    run, k, start = ptr_run(data)
    reg["ptrrun"] = run
    reg["ptrk"] = k
    reg["ptrstart"] = start
    if run >= MIN_PTRS:
        reg["cls"] = "b-DATA-UNTYPED"
        return reg
    size, bad, _ = decode(rom, reg["addr"], reg["end"])
    reg["bad"] = bad
    if bad == 0:
        reg["cls"] = "a-CODE-AS-BYTE"
    elif nb and len(data) and nb / len(data) >= 0.9:
        reg["cls"] = "c-BYTE-TABLE"
    else:
        reg["cls"] = "a-partial"
    return reg


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+")
    ap.add_argument("--linemap", required=True)
    ap.add_argument("--control", action="store_true")
    ap.add_argument("--json", default=None)
    args = ap.parse_args()

    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    rom = load_rom(root)
    maps = json.load(open(args.linemap))
    allregs = {}

    for rel in args.files:
        lm = {int(k): v for k, v in maps[rel].items()}
        lines, regions = parse(os.path.join(root, rel), lm)
        if args.control:
            run_control(rom, lines, regions, rel)
            continue
        out = []
        for reg in regions:
            if byte_bytes(lines, reg["ln"], reg["end_line"]) == 0:
                continue
            if reg["end"] <= reg["addr"]:
                continue
            out.append(classify(rom, lines, reg))
        allregs[rel] = out
        report(rel, out)
    if args.json:
        json.dump(allregs, open(args.json, "w"), indent=1)


def report(rel, regs):
    print("=" * 78)
    print(rel)
    tot = {}
    for r in regs:
        c = r["cls"]
        t = tot.setdefault(c, [0, 0, 0])
        t[0] += 1
        t[1] += r["nbyte"]
        t[2] += r["size"]
    print("  %-18s %6s %12s %12s" % ("class", "regs", ".byte bytes", "region bytes"))
    for c in sorted(tot):
        print("  %-18s %6d %12d %12d" % (c, tot[c][0], tot[c][1], tot[c][2]))
    print("  %-18s %6d %12d %12d" % ("TOTAL", len(regs),
                                     sum(t[1] for t in tot.values()),
                                     sum(t[2] for t in tot.values())))


def run_control(rom, lines, regions, rel):
    """Measure the classifier against regions whose class the tree already states."""
    known_data, known_code = [], []
    src = lines
    for reg in regions:
        seg = [l.strip() for l in src[reg["ln"]:reg["end_line"] - 1]]
        seg = [s for s in seg if s and not s.startswith(";")]
        if not seg or reg["end"] <= reg["addr"]:
            continue
        if any(s.startswith(".byte") for s in seg):
            continue          # not a known-class region: it is what we are judging
        if all(s.startswith((".long", ".word", ".ascii", ".asciz", ".fill", ".zero"))
               for s in seg):
            known_data.append(reg)
        elif not any(s.startswith(".") for s in seg):
            known_code.append(reg)
    res = {"data": [0, 0], "code": [0, 0]}
    for reg in known_data:
        c = classify(rom, lines, dict(reg))["cls"]
        res["data"][0] += 1
        if c.startswith("b"):
            res["data"][1] += 1
    for reg in known_code:
        c = classify(rom, lines, dict(reg))["cls"]
        res["code"][0] += 1
        if c.startswith("a"):
            res["code"][1] += 1
    print("=" * 78)
    print("CONTROL  " + rel)
    print("  known-DATA regions (.long/.word/.ascii only, no .byte): %d" % res["data"][0])
    print("    classifier says DATA:                                 %d  (%.1f%%)"
          % (res["data"][1], 100.0 * res["data"][1] / max(1, res["data"][0])))
    print("  known-CODE regions (instructions only, no directives):  %d" % res["code"][0])
    print("    classifier says CODE:                                 %d  (%.1f%%)"
          % (res["code"][1], 100.0 * res["code"][1] / max(1, res["code"][0])))
    print("  => false-DATA rate on known code: %.2f%%"
          % (100.0 * (res["code"][0] - res["code"][1]) / max(1, res["code"][0])))


if __name__ == "__main__":
    main()
