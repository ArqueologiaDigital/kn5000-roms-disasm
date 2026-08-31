#!/usr/bin/env python3
"""What do CPU 1's SC1 serial registers actually get PROGRAMMED with?

QUESTION IT ANSWERS
  notes/FINDINGS-prom_b-sc1-link.md establishes that the SC1 module contains
  twelve BR1CR writes, "all `ld (0x57),#8`", and explicitly does NOT give the
  values -- so the bit rate is unknown.  The same note leaves SC1MOD's contents
  open, i.e. whether SC1 is a UART at all.  Those two are entries E.1 and E.2 of
  kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md.  This reads every write to
  SC1BUF (0x54), SC1CR (0x55), SC1MOD (0x56) and BR1CR (0x57) out of the PROVEN
  transcription in prom_b/wsa1_prom_b.s and prom_a/wsa1_prom_a.s and prints them.

WHY THE .s AND NOT THE ROM
  A byte scan for `08 57 nn` finds those bytes inside data as readily as inside
  code (the same trap notes/FINDINGS-prom_b-sc1-link.md records for the
  fourteen-spelling census).  Every line this script reads is one llvm-mc has
  re-assembled to the ROM's own bytes, so its framing is not in question.
  ⚠ The converse: a write that lives in a range still `.incbin` is INVISIBLE
  here.  The script prints how much of each image is transcribed so that bound is
  visible rather than implied.

THE BIT LAYOUT, AND WHAT PINS IT
  SCxMOD  | 7 TB8 | 6 CTSE | 5 RXE | 4 WU | 3 SM1 | 2 SM0 | 1 SC1 | 0 SC0 |
  SM (bits 3-2): 0 = I/O interface (clocked synchronous), 1 = 7-bit UART,
                 2 = 8-bit UART, 3 = 9-bit UART
  SC (bits 1-0): 0 = timer-output trigger, 1 = baud-rate generator,
                 2 = internal clock, 3 = SCLK pin
  BRxCR   | 7 - | 6 ADDE | 5 CK1 | 4 CK0 | 3..0 divisor N |

  This is NOT taken from a datasheet nobody in this tree has.  It is pinned on
  THIS machine: notes/FINDINGS-system-clock.md reads CPU 2's `ldio SC0MOD,0x29`
  at 0xF991B3 as "8-bit UART, baud-rate generator", and that reading is what
  makes MIDI come out at 31250 baud with fc = 28 MHz -- a figure lever B of that
  note reaches independently.  Under this layout 0x29 gives SM = 2 (8-bit UART)
  and SC = 1 (baud-rate generator), which is exactly that.  Under the competing
  layout (SM at bits 2-1, SC at bits 4-3) the same byte would be an I/O-interface
  port and MIDI would not work at all.  The same field split is what
  ../kn7000_mame/src/devices/cpu/tlcs900/tmp94c241_serial.cpp uses on the
  sibling part (`mode = (m_serial_mode >> 2) & 3`).

WHAT IT DOES NOT ANSWER
  The absolute bit rate.  BR1CR's CK field selects one of four prescaler taps and
  nothing in this tree has established the four divide ratios for this part --
  MAME's own tmp95c061 prescaler is documented as 16x slow
  (kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md, appendix item 2), so it is
  not usable as the authority.  What the script CAN say is that all twelve writes
  select the SAME tap and differ only in N.

RUN
  python3 notes/prom_b_sc1_serial_regs.py
  python3 notes/prom_b_sc1_serial_regs.py --sites
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRCS = {"prom_b": image_path(ROOT, "prom_b/wsa1_prom_b.s"),
        "prom_a": image_path(ROOT, "prom_a/wsa1_prom_a.s")}
REGS = {0x54: "SC1BUF", 0x55: "SC1CR", 0x56: "SC1MOD", 0x57: "BR1CR",
        0x50: "SC0BUF", 0x51: "SC0CR", 0x52: "SC0MOD", 0x53: "BR0CR"}
SM = {0: "I/O interface (clocked synchronous)", 1: "7-bit UART",
      2: "8-bit UART", 3: "9-bit UART"}
SC = {0: "timer-output trigger", 1: "baud-rate generator",
      2: "internal clock", 3: "SCLK pin"}


def sites():
    """[(image, addr, mnemonic)] for every transcribed instruction naming an SC
    register, taken off the .s's own `; ADDR  <mame text>` comments."""
    out = []
    for img, path in SRCS.items():
        if not os.path.exists(path):
            continue
        for l in open(path):
            body = l.split(";")[0]
            m = re.search(r";\s*([0-9A-F]{6})\s\s(.*)$", l.rstrip())
            if not m or not body.startswith("\t"):
                continue
            txt = m.group(2)
            txt = re.sub(r"\s+\[llvm-mc.*$", "", txt).strip()
            for r in REGS:
                if re.search(r"\(0x%02x\)" % r, txt):
                    out.append((img, int(m.group(1), 16), r, txt))
    return out


def transcribed():
    """bytes of each image that are PROVEN instruction text (for the bound)."""
    tot = {}
    for img, path in SRCS.items():
        if not os.path.exists(path):
            continue
        n = 0
        for l in open(path):
            body = l.split(";")[0]
            if body.startswith("\t") and not body.lstrip().startswith(".") \
                    and re.search(r";\s*[0-9A-F]{6}\s\s", l):
                n += 1
        tot[img] = n
    return tot


def main():
    s = sites()
    if "--sites" in sys.argv:
        for img, a, r, t in sorted(s, key=lambda x: x[1]):
            print("  %-7s 0x%06X  %-6s  %s" % (img, a, REGS[r], t))
        return 0
    print("SC register accesses in the PROVEN transcription")
    for img, n in sorted(transcribed().items()):
        print("  %s: %d transcribed instruction lines" % (img, n))
    print()
    fail = 0
    for r in (0x56, 0x57, 0x55, 0x54):
        rows = [x for x in s if x[2] == r]
        whole = [x for x in rows if re.match(r"ld \(0x%02x\),0x" % r, x[3])]
        bitop = [x for x in rows if re.match(r"(or|and|set|res|bit) \(0x%02x\)" % r, x[3])]
        other = [x for x in rows if x not in whole and x not in bitop]
        st = [x for x in other if re.match(r"ld \(0x%02x\)," % r, x[3])]
        ld = [x for x in other if re.match(r"ld \w+,\(0x%02x\)" % r, x[3])]
        print("%s (0x%02X): %d access%s -- %d whole-byte write%s, %d bit op%s, "
              "%d other (%d register stores, %d register loads)"
              % (REGS[r], r, len(rows), "" if len(rows) == 1 else "es",
                 len(whole), "" if len(whole) == 1 else "s",
                 len(bitop), "" if len(bitop) == 1 else "s", len(other),
                 len(st), len(ld)))
        vals = {}
        for img, a, _, t in whole:
            v = int(re.search(r",0x([0-9a-f]+)$", t).group(1), 16)
            vals.setdefault(v, []).append(a)
        for v in sorted(vals):
            note = ""
            if r == 0x56:
                note = "  -> SM=%d %s | SC=%d %s | RXE=%d WU=%d CTSE=%d TB8=%d" % (
                    (v >> 2) & 3, SM[(v >> 2) & 3], v & 3, SC[v & 3],
                    (v >> 5) & 1, (v >> 4) & 1, (v >> 6) & 1, (v >> 7) & 1)
            if r == 0x57:
                note = "  -> tap CK=%d, divisor N=%d, ADDE=%d" % (
                    (v >> 4) & 3, v & 0x0F, (v >> 6) & 1)
            if r == 0x55:
                note = "  -> IOC=%d (%s), SCLKS=%d" % (
                    v & 1, "SCLK is an INPUT" if v & 1 else "SCLK is an OUTPUT",
                    (v >> 1) & 1)
            print("    = 0x%02X  x%-2d  at %s%s"
                  % (v, len(vals[v]), " ".join("0x%06X" % a for a in sorted(vals[v])),
                     note))
        for img, a, _, t in sorted(bitop, key=lambda x: x[1]):
            print("    bit  0x%06X  %s" % (a, t))
        print()
    # the two claims this exists to settle, asserted
    br = [x for x in s if x[2] == 0x57 and re.match(r"ld \(0x57\),0x", x[3])]
    taps = {(int(re.search(r",0x([0-9a-f]+)$", t).group(1), 16) >> 4) & 3
            for _, _, _, t in br}
    mod = [x for x in s if x[2] == 0x56 and re.match(r"ld \(0x56\),0x", x[3])]
    print("ASSERTIONS")
    print("  BR1CR whole-byte writes: %d  (FINDINGS-prom_b-sc1-link.md says 12) %s"
          % (len(br), "PASS" if len(br) == 12 else "FAIL"))
    fail += 0 if len(br) == 12 else 1
    print("  all twelve select the SAME prescaler tap: %s  %s"
          % (sorted(taps), "PASS" if len(taps) == 1 else "FAIL"))
    fail += 0 if len(taps) == 1 else 1
    print("  SC1MOD is written whole exactly once: %d  %s"
          % (len(mod), "PASS" if len(mod) == 1 else "FAIL"))
    fail += 0 if len(mod) == 1 else 1
    if mod:
        v = int(re.search(r",0x([0-9a-f]+)$", mod[0][3]).group(1), 16)
        print("  and that value is 0x%02X -> SM=%d, i.e. %s  %s"
              % (v, (v >> 2) & 3, SM[(v >> 2) & 3],
                 "PASS" if (v >> 2) & 3 == 0 else "FAIL"))
        fail += 0 if (v >> 2) & 3 == 0 else 1
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
