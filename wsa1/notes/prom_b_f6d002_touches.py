#!/usr/bin/env python3
"""What does the 0xF6D002-0xF77FFF block TOUCH -- and what does it demonstrably
NOT touch?

QUESTION IT ANSWERS
  Round 6's findings note makes two NEGATIVE claims, and a negative claim with no
  script behind it is exactly what this tree's defect list is made of:

    * "this block has ZERO operands naming the control panel's change-mask
      shadow at RAM 0x2B20-0x2B3F", which is why round 6 does NOT close
      emulation gap O;
    * "the block touches no device: every absolute operand that is neither a
      16-bit RAM address (< 0x10000) nor an address in the images themselves
      (>= 0xF00000, i.e. this block's own tables and strings) lies in
      0x600000-0x6177FF, which notes/FINDINGS-memory-map.md calls CPU 1 work
      DRAM on CS3.  ⚠ The ROM exclusion is not a fudge: `ld XIY,0x00f6f528`
      names this module's own `MThdMTrk` template and is not a bus cycle to a
      peripheral.  The device windows this would have caught are prom_a's
      0x7A0000/0x7B0004 floppy registers and 0x7E0008 -- all in
      0x700000-0x7FFFFF, all below 0xF00000, none of them present."

  Both are censuses over the TRANSCRIPTION, not over the raw bytes: every
  instruction line in prom_b/wsa1_prom_b.s carries its MAME text in a
  `; ADDR  <text>` comment and the byte gate proves the file rebuilds the image,
  so an operand read off those comments is an operand the CPU really sees.  A
  byte-window scan would be an upper bound; this is not one.

  A third and a fourth claim are checked here too, because it is the one the block is NAMED
  for: the 31 screen strings quoted in notes/FINDINGS-prom_b-f6d002-module.md §3
  are each asserted to be present in 0xF6D002-0xF77FFF, byte for byte.  A quoted
  string is a hand transcription and hand transcriptions drift.  And the
  status/error word (0x2880) is censused, because the findings note names three
  of its values on the SMF path and the block writes ELEVEN distinct values in
  all -- naming three without saying how many there are would be the same defect
  in a different place.

RUN
    python3 notes/prom_b_f6d002_touches.py            # all three claims, checked
    python3 notes/prom_b_f6d002_touches.py --list     # every hit, with its line
    python3 notes/prom_b_f6d002_touches.py --top      # heaviest RAM words
    python3 notes/prom_b_f6d002_touches.py --strings  # the 31, with addresses
    python3 notes/prom_b_f6d002_touches.py --status   # every (0x2880) literal
Exit status is non-zero if a claim fails.
"""
import os
import re
import sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRC = image_path(ROOT, "prom_b/wsa1_prom_b.s")
LO, HI = 0xF6D002, 0xF78000
PANEL_LO, PANEL_HI = 0x2B20, 0x2B40      # the panel change-mask shadow
RAM_HI = 0x10000                          # 16-bit absolute addressing window
ROM_LO = 0xF00000                         # the images themselves
DRAM_LO, DRAM_HI = 0x600000, 0x617800     # CPU 1 work DRAM on CS3
FAIL = []

# The strings notes/FINDINGS-prom_b-f6d002-module.md §3 quotes, verbatim.
SCREEN_STRINGS = [
    "  TEMPO  ",
    "START   STOP    FILL IN1FILL IN2INTRO1  COUNT INENDING1 END",
    "P 1 P 2 P 3", "VOLUME=", "PANPOT=", "KEY SHIFT=", "TUNING=", "BEND SENS=",
    "SUSTAIN ON  OFF ", "DSP EFFECT ", "EFFECT1=", "REVERB=", "PANEL MEMORY=",
    "APC OFF         ONE FINGER      FINGERED        PIANIST",
    "ACCOMP PART1 ON", "DYNAMIC ACCOMP ON ", "TECHNI-CHORD ON ",
    "<G ><Ab><A ><Bb><B ><C ><Db><D ><Eb><E ><F ><F#>",
    "ACC. TOTAL VOL.=   BASS VOLUME =  DRUMS VOLUME =", "TREMOLO ",
    "EXT.TAB EFFECT:EN  DIS ", "TOTAL REVERB ", "      MELLOWNORMALBRIGHT",
    "M.S.A. OFF ON  #2  #3  ", "TIME SIGNATURE: /4", "MODULATION2=",
    "CTRL.PEDAL=", "R.T.CREAT.X=", "R.T.CTRL.Y=",
    "Maj7 aug  min  min7 dim  m7", "5 mM7  7sus46    aug7",
]


def rom():
    return open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"),
                "rb").read()


def string_hits():
    """[(text, address or None)] -- where each quoted string really is."""
    d, out = rom(), []
    for t in SCREEN_STRINGS:
        i = d.find(t.encode(), LO - 0xF00000, HI - 0xF00000)
        out.append((t, None if i < 0 else 0xF00000 + i))
    return out


def lines():
    """[(addr, mame_text, source_line_no)] for every EMITTED line in range.

    ⚠ Not "instruction lines": a `.long`/`.byte`/`.ascii` row of a data object
    carries a `; ADDR` comment too, so this is 12,118 lines where
    notes/prom_b_instr_census.py counts 11,299 INSTRUCTIONS.  Including the data
    rows makes the two negative claims STRONGER, not weaker -- a panel address
    stored in a table would be found as well as one in an operand."""
    out = []
    for i, ln in enumerate(open(SRC), 1):
        if ";" not in ln or ln.lstrip().startswith(";"):
            continue
        m = re.search(r";\s*([0-9A-F]{6})\s\s?(.*)$", ln.rstrip("\n"))
        if not m:
            continue
        a = int(m.group(1), 16)
        if LO <= a < HI:
            out.append((a, m.group(2).strip(), i))
    return out


STATUS_WORD = 0x2880


def status_writes():
    """{value: [addresses]} for every `ld (0x2880),imm` in the block."""
    out = {}
    for a, txt, _ in lines():
        m = re.match(r"ld \(0x%04x\),0x([0-9a-f]+)$" % STATUS_WORD, txt)
        if m:
            out.setdefault(int(m.group(1), 16), []).append(a)
    return out


def check(name, got, want):
    ok = got == want
    if not ok:
        FAIL.append(name)
    print("  %-66s %s" % (name, "PASS" if ok else "FAIL got=%r want=%r"
                          % (got, want)))


def main():
    ls = lines()
    if not ls:
        print("⚠ NO transcribed lines found in 0x%06X-0x%06X -- the block is not "
              "converted, or the line format changed.  Refusing to report a "
              "vacuous zero." % (LO, HI - 1))
        return 1
    panel, dev, small = [], Counter(), Counter()
    for a, txt, i in ls:
        for m in re.finditer(r"\(0x([0-9a-f]{4})\)", txt):
            v = int(m.group(1), 16)
            small[v] += 1
            if PANEL_LO <= v < PANEL_HI:
                panel.append((a, txt, i))
        for m in re.finditer(r"0x00([0-9a-f]{6})", txt):
            v = int(m.group(1), 16)
            if RAM_HI <= v < ROM_LO:
                dev[v] += 1
    if "--status" in sys.argv:
        for v, addrs in sorted(status_writes().items()):
            print("  (0x%04X) <- 0x%02X  at %s"
                  % (STATUS_WORD, v, " ".join("0x%06X" % x for x in addrs)))
        return 0
    if "--strings" in sys.argv:
        for t, a in string_hits():
            print("  %-60s %s" % (repr(t), "0x%06X" % a if a else "NOT FOUND"))
        return 0
    if "--top" in sys.argv:
        for v, n in small.most_common(20):
            print("  (0x%04X)  x%d" % (v, n))
        return 0
    if "--list" in sys.argv:
        for v, n in sorted(dev.items()):
            print("  0x%06X  x%d" % (v, n))
        for a, txt, i in panel:
            print("  PANEL 0x%06X  %s   (line %d)" % (a, txt, i))
        return 0
    print("emitted lines in 0x%06X-0x%06X: %d  (instruction lines are 11,299 of "
          "them -- notes/prom_b_instr_census.py --module f6d002)"
          % (LO, HI - 1, len(ls)))
    check("operands naming the panel change-mask shadow 0x2B20-0x2B3F",
          len(panel), 0)
    outside = sorted(v for v in dev if not (DRAM_LO <= v < DRAM_HI))
    check("absolute operands in 0x010000-0xEFFFFF that are NOT CPU 1 work DRAM "
          "(0x%06X-0x%06X)" % (DRAM_LO, DRAM_HI - 1),
          ["0x%06X" % v for v in outside], [])
    print("  distinct work-DRAM addresses named: %s"
          % " ".join("0x%06X" % v for v in sorted(dev)))
    print("  heaviest 16-bit RAM words: %s"
          % " ".join("(0x%04X) x%d" % t for t in small.most_common(6)))
    sw = status_writes()
    check("distinct literal values written to (0x%04X) in the block"
          % STATUS_WORD, len(sw), 11)
    check("  the three VALUES the SMF header path writes, at all four of its "
          "sites",
          sorted((v, a) for v in (0x26, 0x30, 0x31) for a in sw.get(v, [])
                 if 0xF6F500 <= a < 0xF6F700),
          [(0x26, 0xF6F578), (0x30, 0xF6F613), (0x31, 0xF6F5C8),
           (0x31, 0xF6F669)])
    hits = string_hits()
    check("all %d screen strings quoted in the findings note are present in "
          "0x%06X-0x%06X" % (len(hits), LO, HI - 1),
          [t for t, a in hits if a is None], [])
    # LAST-ELEMENT TEST: name the last string and its address, so a loop that
    # stopped early cannot pass silently.
    t, a = hits[-1]
    check("LAST quoted string %r is at 0x%06X" % (t, a or 0), a is not None, True)
    print("\n%s (%d failed)" % ("TOUCHES PASS" if not FAIL else "TOUCHES FAIL",
                                len(FAIL)))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
