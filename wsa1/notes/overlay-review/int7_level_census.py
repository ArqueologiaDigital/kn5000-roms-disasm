#!/usr/bin/env python3
"""Can CPU 1's INT7 ever be dispatched to the CPU?  (lane O1, overlay gap review)

QUESTION IT ANSWERS
-------------------
Two documents disagree.

  * notes/FINDINGS-interrupt-vectors.md, "What that says", carries a RETRACTION:
    "INT7's trap is unreachable by design" is withdrawn, on the grounds that
    MAME clears the micro-DMA vector at end of count
    (kn7000_mame/src/devices/cpu/tlcs900/tmp95c061.cpp, `m_dma_vector[channel] = 0;`
    inside the `if (m_dmac[channel].w.l == 0)` arm) so that "in the window
    between completion and re-arm, DMA0V is 0 and an INT7 is dispatched to
    0xFFFF38, i.e. to the hang."

  * the overlay driver kn7000_mame/src/mame/matsushita/wsa1.cpp, block comment
    above fdc_ctrl_w(): "INT7's own INTERRUPT LEVEL is never programmed, so it
    stays 0 and tlcs900_check_irqs() never dispatches it -- which is what makes
    vector slot 0x38 pointing at the deliberate hang (0xF82D09) harmless."

Only one can be right, and it matters: if the retraction is right, every floppy
DMA burst risks wedging CPU 1 on `IRQ_UnusedVector_Hang`.

METHOD
------
On the TMP95C061, INT7's interrupt LEVEL lives in bits 4-6 of INTE67 (SFR 0x72);
MAME reads it as `(m_int_reg[reg] >> 4) & 0x07` for the 0x80-iff entries
(tmp95c061.cpp, tlcs900_check_irqs).  Its priority scan is

    for (int i = std::max(1, ((m_sr.b.h & 0x70) >> 4)); i < 7; i++)

which starts at 1, so `irq_vectors[0]` -- level field zero -- is NEVER selected.
A level of 0 therefore means "masked", independently of DMAnV.

So the question reduces to: does either CPU-1 image EVER write INTE67 with a
non-zero value in bits 4-6?  Census every `ldio INTE67,imm` (08 72 imm) in the
two CPU-1 images and print the imm and its INT7 level field.

⚠ A raw byte census over a whole ROM has false positives inside data.  Cross-check:
the converted sources prom_a/wsa1_prom_a.s and prom_b/wsa1_prom_b.s between them
contain exactly 18 `ldio (0x72),imm` instructions, all in prom_b's SC1 module,
with imm in {0x05, 0x85, 0x8F} -- and prom_a contains none.  This script reports
the byte hits so the two counts can be compared.

Run:  python3 int7_level_census.py

WHAT A PASS LOOKS LIKE
----------------------
Every value written has bits 4-6 == 0.  Then INT7's level is never programmed,
tlcs900_check_irqs() can never select it, and the overlay's comment is correct
while the note's retraction is not.
"""
import os

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "original_ROMs")
IMAGES = [("wsa1_prom_b.ic13", 0xF00000, "prom_b (CPU 1)"),
          ("wsa1_prom_a.ic12", 0xF80000, "prom_a (CPU 1)")]

INTE67 = 0x72
vals = {}
for fn, base, label in IMAGES:
    data = open(os.path.join(BASE, fn), "rb").read()
    print(f"\n=== {label}: candidate `ldio INTE67,imm` (08 72 imm) ===")
    n = 0
    for i in range(len(data) - 2):
        if data[i] == 0x08 and data[i+1] == INTE67:
            imm = data[i+2]
            lvl7 = (imm >> 4) & 0x07
            lvl6 = imm & 0x07
            print(f"  0x{base+i:06X}  INTE67 := 0x{imm:02X}   INT6 level {lvl6}, INT7 level {lvl7}")
            vals[imm] = vals.get(imm, 0) + 1
            n += 1
    if not n:
        print("  (none)")

print("\n--- verdict ---")
print(f"distinct values written: {sorted('0x%02X' % v for v in vals)}")
bad = [v for v in vals if (v >> 4) & 0x07]
if bad:
    print("FAIL: INT7's level field is programmed non-zero somewhere: " +
          ", ".join("0x%02X" % v for v in bad))
else:
    print("PASS: every value leaves INTE67 bits 4-6 == 0, so INT7's interrupt")
    print("      LEVEL is never programmed.  tlcs900_check_irqs()'s priority scan")
    print("      starts at index 1, so a level-0 source is never selected, whatever")
    print("      DMA0V holds.  The hang at vector 0x38 (0xF82D09) is unreachable.")
