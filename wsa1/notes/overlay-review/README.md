# overlay-review: probes written while checking the OVERLAY driver against this tree

Lane O1, 2026-09-01.  These exist so that the two adjudications made in the
overlay gap review can be re-run by anyone.  They are deliberately in their own
directory: `wsa1/notes/*.py` was being edited by another lane at the time.

The overlay driver is `~/compartilhado/kn7000_mame/src/mame/matsushita/wsa1.cpp`
(the development version), NOT the `technics-wsa1` PR extract.

| script | the question it decides | verdict |
|---|---|---|
| `p6_bit5_census.py` | Is "P6 bit 5 = EEPROM chip select" (the overlay) in conflict with "P6 bit 5 is a power-control output" (`FINDINGS-prom_a-for-the-mame-driver.md` §5)? | **NO CONFLICT — two different processors.** CPU 1 (prom_a+prom_b) has exactly ONE P6 bit instruction in 1 MiB, `set 5,(P6)` at 0xF830B0 in the power-fail NMI handler, and NO `res 5,(P6)` anywhere.  CPU 2 (prom_c) has 11, all paired set/res inside the EEPROM bit-banger 0xFC89CA-0xFC8B9D. |
| `hang_trap_reachability.py` | Can CPU 1's INT7 ever be dispatched to the CPU (i.e. into `IRQ_UnusedVector_Hang` at 0xFFFF38)? | **NO.** INTE67 is never written with a non-zero INT7 level field (bits 4-6): prom_a writes it never, prom_b writes only 0x05/0x85/0x8F.  MAME's priority scan starts at index 1, so a level-0 source is never selected, whatever DMA0V holds.  ★ This CONTRADICTS the retraction in `FINDINGS-interrupt-vectors.md`, "What that says", which withdrew "INT7's trap is unreachable by design" on DMA-vector grounds alone and did not check the interrupt level. |

| `cpu2_timer1_rate.py` | Is CPU 2's INTT1 tick rate really "NOT ESTABLISHED"? | **NO -- it is 488.28 Hz, the same as CPU 1's.** prom_c's reset block writes `ldio T01MOD,0x0D` at 0xFFF06C, exactly as prom_a does at 0xF826EB: timer 1 on phiT256 = fc/2048, TREG1 = fc-in-MHz = 28, so 28e6/2048/28 = 488.28 Hz and a tick is 2.048 ms.  ★ SUPERSEDES the "not established" in `prom_c/midi/midi_serial_port.s`'s `Timer1_SetPeriodAndStart` header and in `FINDINGS-prom_c-scheduler.md`.  Corollary: CPU 2's 135-tick active-sensing interval is 276.5 ms, the same figure `FINDINGS-midi-port.md` derives for CPU 1 from a different counter. |

Run each with `python3 <script>`; each prints its own evidence.
All three read `wsa1/original_ROMs/` (and, for two of them, the gate-verified
`.s` sources) and write nothing.

## A note on method, because two of these had to be redone

A raw byte census over a 512 KiB image finds `08 24 xx` 104 times in prom_a and
`08 72 xx` 22 times in prom_b; the real instruction counts are 1 and 18.  Every
script here therefore pairs the byte census with a second, independent count --
either instruction-start addresses read out of the emitted source, or the
symbolic mnemonic grepped from it -- and reports the rejected hits as the
false-positive floor rather than hiding them.  The verdicts above all survive
the strictest reading of their own censuses.
