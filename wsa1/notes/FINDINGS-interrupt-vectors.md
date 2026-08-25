# CPU 1's 33 interrupt vectors, and where every one of them ends up

**Established 2026-08-24.** Regenerate the whole table with
`python3 notes/vector_map.py` (`--unconverted` for what is still `.incbin`).
Nothing below is typed by hand.

## Why 33

The table at `0xFFFF00` is 33 slots of 32 bits, `0x00`-`0x80`:

* the reset PC is fetched from `0xFFFF00` (`../mame/src/devices/cpu/tlcs900/tlcs900.cpp:215-217`),
* NMI is slot `0x20` (`.../tmp95c061.cpp:505`),
* slots `0x28`-`0x80` are the maskable interrupts, named by
  `tmp95c061_irq_vector_map[]` (`.../tmp95c061.cpp:322-346`),
* slots `0x04`-`0x1C` and `0x24` are the conventional SWI1-SWI7 and INTWD
  positions. MAME does not name those, and no databook is in these trees, so
  they are **convention, not a citation** — prom_c corroborates the shape but
  that is corroboration.

## Two levels of thunk, not one

Most slots do not point at code. They point at a `jp nnn` slot of prom_b's
thunk table (`notes/FINDINGS-prom_b-thunk-table.md`), and **two of those point at
a second `jp` table** at prom_a `0xFE3000` — the eight-entry entry directory of
whatever module owns the `0xFE3000`-`0xFE68xx` block:

```
0xFE3000 jp 0xFE3020   0xFE3004 jp 0xFE3032   0xFE3008 jp 0xFE6866
0xFE300C jp 0xFE30D8   0xFE3010 jp 0xFE6851   0xFE3014 jp 0xFE3042
0xFE3018 jp 0xFE308D   0xFE301C jp 0xFE6866
```

`vector_map.py` follows any chain of `1B lo mid hi` to depth 4, which is why
INT5 and INTTC0 resolve.

## The map

```
slot  name            vector      chain
0x00  RESET           0xF826A9                           converted, inside another routine
0x04  SWI1            0xF82D02                           converted, inside another routine
0x08  SWI2/INTUNDEF   0xF82D03                           converted, inside another routine
0x0C  SWI3            0xF82D04                           converted, inside another routine
0x10  SWI4            0xF82D05                           converted, inside another routine
0x14  SWI5            0xF82D06                           converted, inside another routine
0x18  SWI6            0xF82D07                           converted, inside another routine
0x1C  SWI7            0xF400A4  0xF8E9A5                 SWI7_ServiceCall_Dispatch
0x20  NMI             0xF8306E                           NMI_PowerFail_SaveAndHalt
0x24  INTWD           0xF82CFF                           INTWD_Reboot
0x28  INT0            0xF40EDC  0xF8E47F                 INT0_LinkByte
0x2C  INT4            0xF82D08                           converted, inside another routine
0x30  INT5            0xF42D28  0xFE3008 -> 0xFE6866     INT5_Dev7B_Receive
0x34  INT6            0xF40F0C  0xF5AC0A                 in prom_b -- not this lane
0x38  INT7            0xF82D09                           IRQ_UnusedVector_Hang
0x3C  (reserved)      0xF82D09                           IRQ_UnusedVector_Hang
0x40  INTT0           0xF82D09                           IRQ_UnusedVector_Hang
0x44  INTT1           0xF82D0B                           INTT1_Tick
0x48  INTT2           0xF40EE0  0xF57D45                 in prom_b -- not this lane
0x4C  INTT3           0xF42D64  0xF85600                 INTT3_KernelTick
0x50  INTTR4          0xF82EA2                           INTTR4_SequencerTick
0x54  INTTR5          0xF82D09                           IRQ_UnusedVector_Hang
0x58  INTTR6          0xF82D09                           IRQ_UnusedVector_Hang
0x5C  INTTR7          0xF82D09                           IRQ_UnusedVector_Hang
0x60  INTRX0          0xF40714  0xFA5496                 MIDI_RX_Byte
0x64  INTTX0          0xF40718  0xFA542F                 MIDI_TX_Ready
0x68  INTRX1          0xF40F10  0xF5ACBB                 in prom_b -- not this lane
0x6C  INTTX1          0xF40F14  0xF5AC93                 in prom_b -- not this lane
0x70  INTAD           0xF82D09                           IRQ_UnusedVector_Hang
0x74  INTTC0          0xF42D30  0xFE3010 -> 0xFE6851     INTTC0_uDMA0Done
0x78  INTTC1          0xF82D09                           IRQ_UnusedVector_Hang
0x7C  INTTC2          0xF40EE4  0xF8E52D                 INTTC2_uDMA2Done
0x80  INTTC3          0xF40EE8  0xF8E54F                 INTTC3_LinkDmaDone
```

## What that says

* **Eight slots are a deliberate trap.** `IRQ_UnusedVector_Hang` is `jr T,self`;
  it never executes RETI, so the interrupt stays acknowledged and the machine
  stops. Slots `0x38`, `0x3C`, `0x40`, `0x54`, `0x58`, `0x5C`, `0x70` and `0x78`
  point straight at it — that is **eight**, and `python3 notes/vector_map.py |
  grep -c IRQ_UnusedVector_Hang` prints 8. (This bullet said "nine" until the
  round-1 audit; the enumeration in the same sentence has always been the same
  eight, and nothing in the tree ever printed nine. Corrected 2026-08-25.)
  Separately, slots `0x04`-`0x18` and `0x2C` land on seven NOPs one byte apart
  that fall into it. It is a trap, not a stub — worth knowing when reading a
  hang.
* **~~INT7's trap is unreachable by design.~~ RETRACTED 2026-08-25 (audit F2).**
  What holds: `INTTC0_uDMA0Done` (`0xFE6851`) ends by writing `DMA0V = 0x0E`,
  MAME computes a micro-DMA channel's trigger as `(DMAnV & 0x1f) << 2`
  (`tmp95c061.cpp:353`), and `0x0E << 2 = 0x38` = INT7's own slot, so channel 0
  is armed to be driven by INT7.
  What does **not** follow is "so INT7 never reaches the CPU and the hang is
  unreachable". The same MAME routine **clears** the vector when the count
  expires — `m_dma_vector[channel] = 0;` (`tmp95c061.cpp:450`) inside
  `if ( m_dmac[channel].w.l == 0 )` (`:448`), just before the INTTC0 flag is
  set at `:452`. That is exactly why this handler has to write DMA0V back at
  all. In the window between completion and re-arm, DMA0V is 0 and an INT7 is
  dispatched to `0xFFFF38`, i.e. to the hang.
  The analogue below argues the same way rather than the opposite way:
  `INT0_LinkByte` does the identical trick with `DMA3V = 0x0A`
  (`0x0A << 2 = 0x28` = INT0) at `0xF8E4CA`, `0xF8E4E9` and `0xF8E51F` — and
  slot `0x28` holds a **live handler**, `INT0_LinkByte` itself. Same chip, same
  trick, handler plainly reachable. See `FINDINGS-interprocessor-link.md`.
  **The lesson, not just the correction:** "a peripheral consumes this
  interrupt" is a statement about one steady state, and a vector slot is
  reachable if there is *any* state in which it is used. Ruling a slot out needs
  the whole state space, which this argument never had.
* **INTTR5 hangs even though the tempo code writes TREG5.** Recorded because a
  reader expects that slot to matter.
* **Every prom_a-side handler is now converted.** The four that are not are
  `INT6`, `INTT2`, `INTRX1` and `INTTX1`, and all four land in prom_b.
  `INTT2`'s target, prom_b `0xF57D45`, is a bare `reti` — consistent with timer 2
  existing only to pace micro-DMA channel 2, which absorbs the interrupt.

## Three handlers do not RETI

`INTT1_Tick`, `INTTR4_SequencerTick` and `INTT3_KernelTick` all end by jumping
to `IRQ_Epilogue` (`0xF857B7`), where the decision to reschedule is taken once
for all of them. `INTT3_KernelTick` is the smallest handler in the machine: it
increments `(0xBE)` and jumps. `(0xBE)` is the kernel's pending-tick count —
`Kernel_Dispatch__drain_ticks` decrements it one at a time, running
`Kernel_ServiceSoftTimers` per decrement, and only three instructions in the
whole 1 MiB CPU-1 image touch it:

```
$ python3 notes/prom_a_addr_census.py 0xBE
  prom_a  0xF85600  C0+d8    64/64  inc 1,(0xbe)
  prom_a  0xF85735  C0+d8    24/64  ld A,(0xbe)
  prom_a  0xF8573E  F0+d8    25/64  ld (0xbe),A
  (nine further byte matches, all 0/64 and none of them decodable — coincidences
   inside longer instructions)
```

⚠ The earlier wording here was "a byte census of the three memory-operand
prefixes", and no script in the tree did that. `notes/prom_a_addr_census.py`
now does, over all **twelve** direct spellings rather than three, and
`--selftest` asserts this exact three-site result. The count is unchanged; what
changed is that it is now reproducible.
