#!/usr/bin/env python3
r"""unanchored_context_probe.py -- M2: locate the unanchored ACT codes' role by their
PROGRAM CONTEXT in SINGLE DELAY (the one program with a validated answer).

QUESTION IT ANSWERS
    The input-route ALU codes (ACT 0x0D/0x0E, SRC 0x08/0x11) execute addressing-only,
    so captures can't observe their ALU. But their PLACEMENT in a known program is
    observable. This parses a .dsm, finds the unanchored-code words, and prints their
    immediate neighbours -- especially the decoded external delay-DRAM read/write
    words (class-1 escape, addr8 0x30 = first access / bit 6 = 0x60 write) -- so the
    codes' STRUCTURAL role is on record even though the exact op stays enumerated.

FINDING (prog09_single_delay.dsm): ACT 0x0D (SRC 0x07=mem[ptr]) and ACT 0x0E
    (SRC 0x10=acc) occur as a PAIR, 3x (w1-2, w21-22, w44-45), each pair IMMEDIATELY
    adjacent to a decoded delay-DRAM read (w0 addr8=0x30) or write (w46 addr8=0x60).
    => in the ground-truth program the pair is the DELAY-LINE I/O MIXING: mem (dry /
    input) and acc (wet / feedback) combined around the delay tap. This LOCATES the
    input-route codes structurally (STRONG); the exact ALU op stays one of the
    enumerated readings (SPECULATIVE) -- consistent with "ACT 0x0D: acc<-bus,
    ACT 0x0E: P<-bus". SINGLE DELAY cannot decode the op itself (its validated
    lag/gain is invariant to the reading, unblocking-and-discriminators.md result B),
    but the placement is ground-truth structure.

    Run: python3 dsp/tools/unanchored_context_probe.py [dsp/disasm/prog09_single_delay.dsm]
"""
import re, os, sys

UN_SRC = {0x08, 0x11}
UN_ACT = {0x08, 0x0D, 0x0E, 0x17}
HERE = os.path.dirname(os.path.abspath(__file__))
DEF = os.path.join(HERE, "..", "disasm", "prog09_single_delay.dsm")

def parse(path):
    words = []
    for ln in open(path):
        wm = re.search(r"^\s*(w\d+)\s+([0-9A-Fa-f]{10})", ln)
        fm = re.search(r";\s*([0-9A-Fa-f]{3})\.([0-9A-Fa-f])\.([0-9A-Fa-f]{2})\.([0-9A-Fa-f]{3})", ln)
        if not (wm and fm):
            continue
        cls = int(fm.group(2), 16); addr8 = int(fm.group(3), 16); lo12 = int(fm.group(4), 16)
        words.append(dict(w=wm.group(1), cls=cls, addr8=addr8,
                          src=(lo12 >> 6) & 0x1F, act=lo12 & 0x1F,
                          text=ln.split(";")[0].strip()))
    return words

def role(x):
    if x["cls"] == 1 and x["addr8"] == 0x30:
        return "  <-- delay-DRAM READ (first access)"
    if x["cls"] == 1 and (x["addr8"] & 0x40):
        return "  <-- delay-DRAM WRITE (addr8 bit6)"
    if x["src"] in UN_SRC or x["act"] in UN_ACT:
        return f"  <== UNANCHORED (SRC=0x{x['src']:02X} ACT=0x{x['act']:02X})"
    return ""

def main():
    path = sys.argv[1] if len(sys.argv) > 1 else DEF
    words = parse(path)
    idx = [i for i, x in enumerate(words) if x["src"] in UN_SRC or x["act"] in UN_ACT]
    print(f"unanchored_context_probe: {os.path.basename(path)}  "
          f"({len(idx)} unanchored words of {len(words)})")
    shown = set()
    for i in idx:
        for j in range(max(0, i - 1), min(len(words), i + 2)):
            if j in shown:
                continue
            shown.add(j)
            x = words[j]
            print(f"  {x['w']:>4}  cls={x['cls']} addr8=0x{x['addr8']:02X} "
                  f"SRC=0x{x['src']:02X} ACT=0x{x['act']:02X}  {x['text']:<22}{role(x)}")
        print("  --")
    # summary: how many unanchored words are adjacent to a delay read/write
    adj = 0
    for i in idx:
        for j in (i - 1, i + 1):
            if 0 <= j < len(words) and words[j]["cls"] == 1 and \
               (words[j]["addr8"] == 0x30 or (words[j]["addr8"] & 0x40)):
                adj += 1; break
    print(f"\n  {adj}/{len(idx)} unanchored words are adjacent to a decoded delay-DRAM read/write")
    print("  => the input-route codes bracket the delay taps (STRUCTURAL, ground-truth program).")

if __name__ == "__main__":
    main()
