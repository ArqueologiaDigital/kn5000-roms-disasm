# Fix DMA macro names: DMAC = counter registers, DMAM = mode registers
# These macros were incorrectly named (DMAC↔DMAM swapped)

# Mode register macros (8-bit, CR offsets 0x42/0x4A/0x4E) — rename to DMAM
s/LDC_DMAC0_A/LDC_DMAM0_A/g
s/LDC_DMAC2_XWA/LDC_DMAM2_A/g
s/LDC_DMAC2_A/LDC_DMAM2_A/g
s/LDC_DMAC3_A/LDC_DMAM3_A/g

# Counter register macros (16-bit, CR offsets 0x40/0x48/0x4C) — rename to DMAC
s/LDC_DMAM0_WA/LDC_DMAC0_WA/g
s/LDC_WA_DMAM0/LDC_WA_DMAC0/g
s/LDC_DMAM2_WA/LDC_DMAC2_WA/g
s/LDC_DMAM2_BC/LDC_DMAC2_BC/g
s/LDC_DMAM3_BC/LDC_DMAC3_BC/g
