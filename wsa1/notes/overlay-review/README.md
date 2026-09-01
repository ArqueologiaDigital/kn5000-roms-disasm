# overlay-review: probes written while checking the OVERLAY driver against this tree

Lane O1, 2026-09-01.  These exist so that the two adjudications made in the
overlay gap review can be re-run by anyone.  They are deliberately in their own
directory: `wsa1/notes/*.py` was being edited by another lane at the time.

The overlay driver is `~/compartilhado/kn7000_mame/src/mame/matsushita/wsa1.cpp`
(the development version), NOT the `technics-wsa1` PR extract.

| script | the question it decides | verdict |
|---|---|---|
| `p6_bit5_census.py` | Is "P6 bit 5 = EEPROM chip select" (the overlay) in conflict with "P6 bit 5 is a power-control output" (`FINDINGS-prom_a-for-the-mame-driver.md` §5)? | **NO CONFLICT — two different processors.** CPU 1 (prom_a+prom_b) has exactly ONE P6 bit instruction in 1 MiB, `set 5,(P6)` at 0xF830B0 in the power-fail NMI handler, and NO `res 5,(P6)` anywhere.  CPU 2 (prom_c) has 11, all paired set/res inside the EEPROM bit-banger 0xFC89CA-0xFC8B9D. |
| `int7_level_census.py` | Can CPU 1's INT7 ever be dispatched to the CPU (i.e. into `IRQ_UnusedVector_Hang` at 0xFFFF38)? | **NO.** INTE67 is never written with a non-zero INT7 level field (bits 4-6): prom_a writes it never, prom_b writes only 0x05/0x85/0x8F.  MAME's priority scan starts at index 1, so a level-0 source is never selected, whatever DMA0V holds.  ★ This CONTRADICTS the retraction in `FINDINGS-interrupt-vectors.md`, "What that says", which withdrew "INT7's trap is unreachable by design" on DMA-vector grounds alone and did not check the interrupt level. |

Run either with `python3 <script>`; each prints its own evidence.
Both read `wsa1/original_ROMs/` only and write nothing.
