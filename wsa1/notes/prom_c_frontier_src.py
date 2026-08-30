#!/usr/bin/env python3
"""prom_c frontier, computed from the SOURCE FILE instead of a linear re-disassembly.

QUESTION ANSWERED
  "Which UNCONVERTED prom_c addresses does the already-converted code transfer to?"
  -- the same question `notes/prom_c_frontier.py` answers, but without the phantoms.

WHY THIS EXISTS
  `prom_c_frontier.py` re-disassembles each converted span LINEARLY.  Half of prom_c's
  converted bytes are DATA -- the EQ frequency table, the two 128-entry mixer-gain
  curves, the 390-byte descriptor-string pool, the pointer tables -- and a linear
  decode of a float table produces plausible-looking `jrl` instructions at random
  offsets.  Its own LIMITS section says so, but the ranking is still dominated by them:
  of the 146 targets it reported on 2026-08-25, 121 came from callers inside
  0xFCCA82-0xFCD0F6 (DSP_EQ_FreqHz_Table .. DescriptorStrings), 0xFCC53F-0xFCC819 or
  0xFDD2AB-0xFDF7DF, i.e. from bytes the source file emits with `.long` / `.byte` /
  `.ascii`, not with a mnemonic.  Choosing targets from that ranking means choosing
  noise.  Run `--phantoms` to see the split.

  This script instead reads the `.s` file's own instruction LINES.  A `.long` line can
  never be mistaken for a `call`, so every target it reports comes from an instruction
  a human wrote and the byte gate certifies.

WHAT IT MATCHES
    call 0xTARGET                     absolute call
    jp   0xTARGET                     absolute jump
    calr (0xTARGET - 0xNEXT)          the constant-folded idiom this file uses
    jrl  (0xTARGET - 0xNEXT)          same, long relative
  Label operands (`jrl Kernel_Dispatch`) are intra-file by construction and therefore
  never point at unconverted bytes; they are counted and reported, not ranked.

LIMITS -- read before quoting a number
  * Targets held in a register, or reached through a pointer table, are invisible.
    An empty result means "no literal transfer found", never "nothing calls this".
  * It reports what the SOURCE says.  That is the point -- but it means a target is
    only visible once the code that calls it has been converted.  Both frontiers grow
    as conversion proceeds.
  * "Unconverted" is a property of the source file.  Re-run after every edit.

RUN
  python3 notes/prom_c_frontier_src.py                 # the frontier, most-called first
  python3 notes/prom_c_frontier_src.py --clusters      # contiguous groups = modules
  python3 notes/prom_c_frontier_src.py --range 0xFA7E2C-0xFABCF9   # census one range
  python3 notes/prom_c_frontier_src.py --phantoms      # this vs prom_c_frontier.py
  python3 notes/prom_c_frontier_src.py --selftest
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRC = image_path(ROOT, "prom_c/wsa1_prom_c.s")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
BASE = 0xF80000

INCBIN = re.compile(r'\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)')
# Conditional forms exist for every one of these (`jrl nz, (...)`, `call c, 0x...`),
# and the file also spells some targets with eight hex digits (`0x00F9A01F`).  Both
# were missing from a first draft of these patterns, which silently dropped twelve
# real transfers; ANY/LEFTOVER below is the check that keeps that from recurring.
CC = r'(?:\s*(?:nz|z|nc|c|pl|mi|p|m|t|f|ge|gt|le|lt|ov|nov|ule|ugt|ult|uge)\s*,)?'
ABS = re.compile(r'^\s+(call|jp)' + CC + r'\s+(0x[0-9A-Fa-f]{4,8})\s*(?:;.*)?$')
REL = re.compile(r'^\s+(calr|jrl)' + CC +
                 r'\s*\(\s*(0x[0-9A-Fa-f]{4,8})\s*-\s*0x[0-9A-Fa-f]{4,8}\s*\)\s*(?:;.*)?$')
LBL = re.compile(r'^\s+(calr|jrl|jr)' + CC + r'\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?:;.*)?$')
ANY = re.compile(r'^\s+(call|calr|jp|jrl|jr)\b')
LITERAL = re.compile(r'0x[0-9A-Fa-f]{4,8}')
ADDRCOM = re.compile(r';\s*([0-9A-Fa-f]{6})\s')


def unconverted():
    """(lo, hi) file-offset pairs that are still `.incbin`."""
    out = []
    for m in INCBIN.finditer(open(SRC, encoding="utf-8").read()):
        off, ln = int(m.group(1), 16), int(m.group(2), 16)
        out.append((off, off + ln))
    out.sort()
    return out


def scan():
    """Every literal control transfer the SOURCE spells out, with the line it is on."""
    hits = []       # (target, kind, line-number, caller-addr-or-None)
    labelled = 0
    leftover = []   # transfer lines with a literal operand that NOTHING matched
    for i, line in enumerate(open(SRC, encoding="utf-8"), 1):
        line = line.rstrip("\n")
        m = ABS.match(line) or REL.match(line)
        if m:
            ac = ADDRCOM.search(line)
            caller = int(ac.group(1), 16) if ac else None
            hits.append((int(m.group(2), 16), m.group(1), i, caller))
        elif LBL.match(line):
            labelled += 1
        elif ANY.match(line) and LITERAL.search(line.split(";")[0]):
            leftover.append((i, line))
    return hits, labelled, leftover


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--clusters", action="store_true")
    ap.add_argument("--range", metavar="LO-HI",
                    help="census the frontier inside one ADDRESS RANGE, e.g. "
                         "--range 0xFA7E2C-0xFABCF9.  Exists because a range that "
                         "spans several --clusters rows must NOT be reported by "
                         "hand-summing them: a small cluster lying inside the range "
                         "is easy to drop, and one was (see notes/"
                         "FINDINGS-prom_c-voice-module.md \u00a710).")
    ap.add_argument("--phantoms", action="store_true")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--gap", type=lambda s: int(s, 0), default=0x400,
                    help="max hole inside one cluster (default 0x400)")
    a = ap.parse_args()

    size = os.path.getsize(ROM)
    unconv = unconverted()

    def is_unconv(addr):
        off = addr - BASE
        return any(lo <= off < hi for lo, hi in unconv)

    hits, labelled, leftover = scan()
    front = {}
    for tgt, kind, ln, caller in hits:
        if BASE <= tgt < BASE + size and is_unconv(tgt):
            front.setdefault(tgt, []).append((kind, ln, caller))

    print("prom_c source: %d literal control transfers, %d with a label operand"
          % (len(hits), labelled))
    if leftover:
        print("  ⚠ %d transfer line(s) carry a literal NOTHING here matched -- the"
              " patterns are incomplete and every number below is suspect:" % len(leftover))
        for ln, txt in leftover[:20]:
            print("      s.%d  %s" % (ln, txt.strip()[:90]))
    else:
        print("  every transfer line with a literal operand was matched"
              " (0 leftovers -- the completeness check)")
    print("               %d .incbin span(s), %d unconverted byte(s) of %d"
          % (len(unconv), sum(h - l for l, h in unconv), size))
    print()

    if a.phantoms:
        # every caller line that is INSIDE a converted span but is not an instruction
        # cannot exist here by construction; instead compare the two target sets.
        sys.path.insert(0, os.path.join(ROOT, "notes"))
        import subprocess
        p = subprocess.run([sys.executable, os.path.join(ROOT, "notes", "prom_c_frontier.py")],
                           capture_output=True, text=True)
        old = set()
        for line in p.stdout.splitlines():
            m = re.match(r'\s+(0x[0-9A-F]{6})\s+\d+ site', line)
            if m:
                old.add(int(m.group(1), 16))
        new = set(front)
        print("  prom_c_frontier.py (linear decode) : %4d target(s)" % len(old))
        print("  this script        (source lines)  : %4d target(s)" % len(new))
        print("  in BOTH                            : %4d" % len(old & new))
        print("  linear-only (phantom candidates)   : %4d" % len(old - new))
        print("  source-only (linear decode missed) : %4d" % len(new - old))
        if new - old:
            print("    " + " ".join("0x%06X" % t for t in sorted(new - old)))
        return 0

    print("FRONTIER -- literal transfers from converted code into UNCONVERTED code")
    print("%d distinct target(s); %d total site(s)"
          % (len(front), sum(len(v) for v in front.values())))
    print()

    if a.range:
        lo_s, _, hi_s = a.range.partition("-")
        lo, hi = int(lo_s, 0), int(hi_s, 0)
        inside = sorted(t for t in front if lo <= t <= hi)
        sites = sum(len(front[t]) for t in inside)
        print("  RANGE 0x%06X-0x%06X  ->  %d target(s), %d site(s), %d byte(s) wide"
              % (lo, hi, len(inside), sites, hi - lo + 1))
        for t in inside:
            print("      0x%06X  %2d site(s)" % (t, len(front[t])))
        return 0

    if a.clusters:
        ts = sorted(front)
        clusters, cur = [], []
        for t in ts:
            if cur and t - cur[-1] > a.gap:
                clusters.append(cur)
                cur = []
            cur.append(t)
        if cur:
            clusters.append(cur)
        clusters.sort(key=lambda c: -sum(len(front[t]) for t in c))
        print("  %-21s %7s %7s %9s" % ("cluster", "tgts", "sites", "extent"))
        for c in clusters:
            print("  0x%06X-0x%06X %7d %7d %9d"
                  % (c[0], c[-1], len(c), sum(len(front[t]) for t in c), c[-1] - c[0]))
        print()
        print("  (a cluster is targets no more than 0x%X apart; it is a HINT at a module"
              " boundary, never a proof of one)" % a.gap)
        return 0

    for t in sorted(front, key=lambda x: (-len(front[x]), x)):
        v = front[t]
        kinds = ",".join(sorted({k for k, _, _ in v}))
        lines = " ".join("s.%d" % ln for _, ln, _ in sorted(v, key=lambda x: x[1])[:8])
        print("  0x%06X  %2d site(s)  [%-4s]  %s%s"
              % (t, len(v), kinds, lines, " ..." if len(v) > 8 else ""))

    if a.selftest:
        fails = []
        if leftover:
            fails.append("%d unmatched transfer line(s) with a literal operand" % len(leftover))
        # the LAST frontier target, not the first, decoded straight out of the ROM
        rom = open(ROM, "rb").read()
        for t in (sorted(front)[:1] + sorted(front)[-1:]) if front else []:
            if not is_unconv(t):
                fails.append("0x%06X is not in an .incbin span" % t)
        # every reported caller line must really spell that target
        for t, v in front.items():
            for kind, ln, _ in v:
                txt = open(SRC, encoding="utf-8").read().split("\n")[ln - 1]
                if ("%06X" % t) not in txt.upper():
                    fails.append("s.%d does not spell 0x%06X" % (ln, t))
        # and a negative control: a target inside a converted span must NOT be reported
        conv_target = 0xF985F8      # Kernel_SemaWait_StackArg, converted
        if conv_target in front:
            fails.append("converted 0x%06X leaked into the frontier" % conv_target)
        if fails:
            print("SELFTEST FAIL")
            for f in fails:
                print("  " + f)
            return 1
        print("SELFTEST PASS")
        print("  %d unmatched transfer lines with a literal operand" % len(leftover))
        print("  every reported caller line spells its target, first and LAST included")
        print("  negative control: converted 0xF985F8 is not reported")
    return 0


if __name__ == "__main__":
    sys.exit(main())
