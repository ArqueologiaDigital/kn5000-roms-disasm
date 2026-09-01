#!/usr/bin/env python3
"""Can any of CPU 1's EIGHT "hang trap" interrupt vectors ever be dispatched?
(lane O1, overlay gap review)

WHY THIS EXISTS
---------------
`notes/FINDINGS-interrupt-vectors.md` establishes that eight of CPU 1's 33
vectors point at `IRQ_UnusedVector_Hang` (prom_a 0xF82D09), which is `jr T,self`
and never executes RETI -- so if one of them is ever dispatched, THE MACHINE
STOPS.  The note's own summary calls that "a deliberate trap", and lane N1's
driver note repeats it as something "anyone debugging a hang in this driver will
want on the record".

The note then carries a RETRACTION of "INT7's trap is unreachable by design",
arguing that MAME clears the micro-DMA vector at end of count
(`m_dma_vector[channel] = 0;` in tmp95c061.cpp) so "in the window between
completion and re-arm, DMA0V is 0 and an INT7 is dispatched to 0xFFFF38".

The overlay driver `~/compartilhado/kn7000_mame/src/mame/matsushita/wsa1.cpp`
says the opposite in the block comment above `fdc_ctrl_w()`: "INT7's own
INTERRUPT LEVEL is never programmed, so it stays 0 and tlcs900_check_irqs()
never dispatches it".

THE ARGUMENT THIS SCRIPT CHECKS
-------------------------------
Every maskable source on this part carries a 3-bit interrupt LEVEL in an
enable register.  MAME's tlcs900_check_irqs() bins sources by that level and
then scans

    for (int i = std::max(1, ((m_sr.b.h & 0x70) >> 4)); i < 7; i++)

starting at index 1, so `irq_vectors[0]` -- level field ZERO -- is never
selected.  Level 0 therefore means MASKED, independently of DMAnV, of the
request flip-flop, and of anything a device does on the pin.

So each trap is unreachable iff its level field is never written non-zero.
This script censuses `ldio <enable reg>,imm` (08 <sfr> <imm>) over both CPU-1
images and decodes the relevant field for each of the eight traps.

The map (MAME tmp95c061.cpp: enum + tmp95c061_irq_vector_map[] + the SFR name
table; m_int_reg[i] is SFR 0x70+i):

    vector 0x38  INT7    INTE67   (0x72) iff 0x80 -> bits 4-6
    vector 0x3C  --      no source at all
    vector 0x40  INTT0   INTET10  (0x73) iff 0x08 -> bits 0-2
    vector 0x54  INTTR5  INTET54  (0x75) iff 0x80 -> bits 4-6
    vector 0x58  INTTR6  INTET76  (0x76) iff 0x08 -> bits 0-2
    vector 0x5C  INTTR7  INTET76  (0x76) iff 0x80 -> bits 4-6
    vector 0x70  INTAD   INTE0AD  (0x70) iff 0x80 -> bits 4-6
    vector 0x78  INTTC1  INTETC01 (0x79) iff 0x80 -> bits 4-6

(INT4, vector 0x2C, is included as a ninth row: it points at 0xF82D08, which
falls straight into the same hang.)

CAVEATS, both real
------------------
* A raw byte census over a whole ROM has FALSE POSITIVES inside data.  Every
  hit below is a candidate; the converted sources are the arbiter.  Where a hit
  is inside emitted data it is still harmless to this argument, because a
  spurious hit can only make the verdict MORE conservative, never less.
* This census covers only the `ldio reg,imm8` form.  A write through
  `ld (0x7x),r`, `or (0x7x),imm` or a `set b,(0x7x)` would be missed.  The
  script therefore ALSO reports every 8-bit-direct memory-operand prefix
  (C0/D0/E0/F0) naming one of these SFRs, so that a non-immediate write cannot
  hide.  As of 2026-09-01 the converted sources contain no such write.

Run:  python3 hang_trap_reachability.py
"""
import os, re

HERE  = os.path.dirname(os.path.abspath(__file__))
BASE  = os.path.join(HERE, "..", "..", "original_ROMs")
SRC   = os.path.join(HERE, "..", "..")

IMAGES = [("wsa1_prom_b.ic13", 0xF00000, "prom_b (CPU 1)", "prom_b/wsa1_prom_b.s"),
          ("wsa1_prom_a.ic12", 0xF80000, "prom_a (CPU 1)", "prom_a/wsa1_prom_a.s")]

SFRNAME = {0x70: "INTE0AD", 0x71: "INTE45", 0x72: "INTE67", 0x73: "INTET10",
           0x74: "INTET32", 0x75: "INTET54", 0x76: "INTET76", 0x77: "INTES0",
           0x78: "INTES1", 0x79: "INTETC01", 0x7a: "INTETC23"}

TRAPS = [
    (0x2C, "INT4  -> 0xF82D08, falls into the hang", 0x71, False),
    (0x38, "INT7  -> IRQ_UnusedVector_Hang",         0x72, True),
    (0x3C, "(reserved) -> IRQ_UnusedVector_Hang",    None, None),
    (0x40, "INTT0 -> IRQ_UnusedVector_Hang",         0x73, False),
    (0x54, "INTTR5 -> IRQ_UnusedVector_Hang",        0x75, True),
    (0x58, "INTTR6 -> IRQ_UnusedVector_Hang",        0x76, False),
    (0x5C, "INTTR7 -> IRQ_UnusedVector_Hang",        0x76, True),
    (0x70, "INTAD -> IRQ_UnusedVector_Hang",         0x70, True),
    (0x78, "INTTC1 -> IRQ_UnusedVector_Hang",        0x79, True),
]

# --- instruction boundaries, straight out of the gate-verified sources --------
# Every emitted instruction line carries its own address in the comment column,
# e.g.   "\tldio 0x73, 0x30    ; F827C8  08 73 30".  Data rows (.byte/.long/
# .ascii) carry an address too, so the kind of the row is taken from the
# mnemonic, and only NON-data rows count as instruction starts.
ADDR = re.compile(r";\s*([0-9A-F]{6})\s")
DATA = re.compile(r"^\s*\.(byte|word|long|short|ascii|asciz|space|fill|incbin)\b")

def instruction_addrs(path):
    out = set()
    with open(path, errors="replace") as fh:
        for line in fh:
            if not line[:1].isspace():
                continue                      # a label, a directive at column 0
            if line.lstrip().startswith(";"):
                continue                      # a comment
            if DATA.match(line):
                continue                      # emitted data, not code
            m = ADDR.search(line)
            if m:
                out.add(int(m.group(1), 16))
    return out

writes = {}
other  = []
skipped = 0

for fn, base, label, src in IMAGES:
    data = open(os.path.join(BASE, fn), "rb").read()
    code = instruction_addrs(os.path.join(SRC, src))
    print(f"\n=== {label}: `ldio <int enable>,imm` AT A CONVERTED INSTRUCTION BOUNDARY ===")
    print(f"    ({len(code)} instruction addresses read from {src})")
    n = 0
    for i in range(len(data) - 2):
        b = data[i]
        addr = base + i
        if b == 0x08 and data[i+1] in SFRNAME:
            if addr not in code:
                skipped += 1
                continue
            sfr, imm = data[i+1], data[i+2]
            print(f"  0x{addr:06X}  {SFRNAME[sfr]:<9} := 0x{imm:02X}"
                  f"   [low field {imm & 7}, high field {(imm >> 4) & 7}]")
            writes.setdefault(sfr, set()).add(imm)
            n += 1
        elif b in (0xC0, 0xD0, 0xE0, 0xF0) and data[i+1] in SFRNAME:
            if addr in code:
                other.append((addr, SFRNAME[data[i+1]], b, data[i+2]))
            else:
                skipped += 1
    if not n:
        print("  (none)")

print(f"\nbyte-pattern hits REJECTED as not-an-instruction: {skipped}")
print("   (that is the false-positive floor a raw ROM census would have reported)")

print("\n=== non-immediate accesses to the same SFRs, at instruction boundaries ===")
for a, name, g, op in other:
    print(f"  0x{a:06X}  group 0x{g:02X} ({name})  opcode byte 0x{op:02X}"
          f"   <-- READ THE SOURCE AT THIS ADDRESS")
if not other:
    print("  (none -- every access to these registers is an `ldio reg,imm8`)")

print("\n=== VERDICT, per trap ===")
fails = 0
for vec, what, sfr, high in TRAPS:
    print(f"  vector 0x{vec:02X}  {what}")
    if sfr is None:
        print("      UNREACHABLE: no interrupt source is mapped to this slot at all.")
        continue
    vals = writes.get(sfr, set())
    bad = sorted(v for v in vals if ((v >> 4) & 7 if high else v & 7))
    field = "bits 4-6" if high else "bits 0-2"
    print(f"      {SFRNAME[sfr]} {field}; values ever written: "
          + (", ".join("0x%02X" % v for v in sorted(vals))
             or "NONE -- the register is never written, so it keeps its reset value"))
    if bad:
        print("      *** REACHABLE: level programmed non-zero by "
              + ", ".join("0x%02X" % v for v in bad))
        fails += 1
    else:
        print("      UNREACHABLE: the level field is never non-zero, so"
              " tlcs900_check_irqs() can never select it.")

print(f"\nTRAPS THAT COULD FIRE: {fails}")
if fails == 0:
    print("PASS -- every hang trap (and INT4) is masked by its own level field,")
    print("whatever a device does on the pin and whatever DMAnV holds.")
