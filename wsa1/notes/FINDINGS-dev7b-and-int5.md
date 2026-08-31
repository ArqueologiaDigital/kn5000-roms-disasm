# The CS0 device at 0x7B0004/0x7B0005, and the INT5 handler that reads it

> ## ★★ SUPERSEDED IN ONE RESPECT, 2026-08-25: THE DEVICE IS NOW NAMED
> The section "⚠ What the device IS has not been established" below is
> **WITHDRAWN**. Converting the 4,720 bytes underneath these accessors
> (prom_a `0xFE54EC-0xFE594B` and `0xFE5A41-0xFE6850`) identified it as a
> **uPD765-family floppy disk controller**: `0x7B0004` read is the Main Status
> Register, `0x7B0005` is the Data Register, and `0x7A0000` is the same data
> register on the DMA-acknowledged decode. The decisive evidence is that the
> driver's own opcode validator accepts 15 of the 32 five-bit opcode values and
> rejects the other 17, and that truth table is exactly MAME's uPD765 command
> decoder's. See **`notes/FINDINGS-prom_a-fdc.md`**, checked by
> `notes/prom_a_fdc_checks.py`.
>
> Everything else in this note stands, and two of its statements are now
> explained rather than corrected: the "ten direction codes" are uPD765 command
> opcodes, and the `0x08` that INT5 writes to the data register is SENSE
> INTERRUPT STATUS. The three routines listed below as "still `.incbin`" are all
> converted now.

**Established 2026-08-24 while converting prom_a `0xFE54B6-0xFE54EB` and
`0xFE6851-0xFE68F2`.** `notes/FINDINGS-memory-map.md` already listed the two
addresses as "byte registers" with three example instructions. This is what the
code around them says — and what it still does not.

## Every access, and there are only five

A byte census over prom_a and prom_b of the 24-bit memory-operand form
(`C2/D2/E2/F2 <lo> <mid> <hi> <op>`) for each of `0x7B0000`-`0x7B000F` finds
**five hits in total**, all in prom_a and all inside one 54-byte block:

| site | instruction | routine |
|---|---|---|
| `0xFE54B6` | `ld L,(0x7B0004)` | `Dev7B_ReadStatus` |
| `0xFE54BC` | `ld L,(0x7B0005)` | `Dev7B_ReadData` |
| `0xFE54C5` | `ld (0x7B0004),A` | `Dev7B_WriteControl` |
| `0xFE54DD` | `ld (0x7B0004),A` | `Dev7B_WriteControl_Shadowed` |
| `0xFE54E6` | `ld (0x7B0005),A` | `Dev7B_WriteData` |

No other address in `0x7B0000`-`0x7B000F` is referenced at all, and prom_b never
touches the device. So those five accessors — all converted — are the **entire**
software interface, and every argument arrives on the stack at `(XSP+0x04)`.

`Dev7B_WriteControl_Shadowed` additionally keeps the previous control byte at
`(0x605B08)` and the new one at `(0x605B09)`: the register is write-only and
software has to remember it.

`python3 notes/prom_a_byte_checks.py` re-runs that census and fails if the
count is ever not five.

## Which register is which — read off the caller, not assumed

`INT5_Dev7B_Receive` (prom_a `0xFE6866`) never stores the byte it reads from
`0x7B0004`; it tests bit 7 or bit 6 of it and branches, every single time. It
reads `0x7B0005` exactly once per received byte and stores each one straight into
a buffer. That is what makes `0x7B0004` the **control/status** register and
`0x7B0005` the **data** register.

* **status bit 7** — a byte is ready. Every wait loop in the handler is
  `read status; bit 7; jr z` back.
* **status bit 6** — more bytes follow. It ends the inner packet loop.

## The handler

`INT5` (vector slot `0x30`) reaches `0xFE6866` through **two** thunks — prom_b
`0xF42D28` → prom_a `0xFE3008` → `0xFE6866`; see `FINDINGS-interrupt-vectors.md`.
It saves all seven long registers, then:

1. waits up to **100 tries** for status bit 7; gives up if it never comes;
2. waits for bit 7 again; if bit 6 is clear, spins until `status & 0xF0 == 0x80`
   and writes **`0x08`** to the data register;
3. reads bytes into a buffer starting at **`0x605A51`**, one per pass, while
   status bit 6 says more follow;
4. calls `0xFE5B5E`, which re-reads the buffer and switches on the **top two
   bits of byte 1** (`0x40` / `0x80` / other);
5. repeats from 2 until `(0x605A51) == 0x80`;
6. writes 0 to `(0x605A50)` and returns with RETI.

## ~~⚠ What the device IS has not been established~~ — WITHDRAWN 2026-08-25

**The text below was true of the evidence this note had, and is kept so the
retraction is legible.** It reasoned from the five accessors and the INT5
handler alone, which really do not identify anything; the identification came
from the driver underneath them, which was `.incbin` when this was written.

> ~~Nothing in the firmware names it, no string is near it, and no databook is in
> these trees. What can be said is only the shape: a two-register byte-wide
> peripheral on CS0 with a ready/more status pair and a packet framing whose
> terminator is `0x80` in the second buffer byte. **Do not name it.** In
> particular this note does not claim it is a floppy controller, a panel scanner,
> or anything else.~~

What that packet framing actually is: INT5 is the FDC's **result-phase**
interrupt. The bytes it collects into `0x605A51..` are ST0, ST1, ST2, C, H, R, N
— and the `0x80` terminator is ST0's IC field reading "invalid command", which
is how the post-reset drain of SENSE INTERRUPT STATUS ends.

~~Two routines that would settle a lot are still `.incbin`:~~ **Both converted
2026-08-25, and they did settle it:**

* `0xFE5A41` is `Fdc_WaitRqm` — it waits for `MSR & (RQM|DIO|EXM)` to be `0x80`
  or `0xC0`;
* `0xFE5B5E` is `Fdc_ClassifyResultStatus` — it decodes ST0's IC field and then
  ST0 bits 3 and 4 and all six defined ST1 bits.

## The other handler in the same block — and it turned out NOT to be unrelated

**Updated 2026-08-25** (round 2 converted prom_a `0xFE594C-0xFE5A40`; the old
text of this section is quoted and corrected below).

`INTTC0_uDMA0Done` (`0xFE6851`, vector slot `0x74`) shares the `0xFE3000` entry
table with INT5. It calls two leaves: `PortB3_Pulse` (`0xFE594C`) pulses bit 3
of PB (SFR `0x1F`) with five NOPs in between, and `uDMA0_ArmOnINT7` (`0xFE5966`)
is `ldio DMA0V, 0x0E` and nothing else. `0x0E << 2 = 0x38` = **INT7**, so the
handler re-arms micro-DMA channel 0 to be driven by INT7.

⚠ Two things in the old wording are now withdrawn.

* "**unrelated to the device**" — it is not. The code that programmes the rest of
  channel 0 sits immediately above those two leaves, and it moves bytes between
  **`0x7A0000`** and a RAM buffer:

  | routine | DMAS0 | DMAD0 | DMAM0 | meaning |
  |---|---|---|---|---|
  | `Dev7A_Dma_DeviceToRam` `0xFE59BB` | `0x007A0000` | `(0x605A3C)` | `0x00` | byte, **destination** increments |
  | `Dev7A_Dma_RamToDevice` `0xFE59D2` | `(0x605A3C)` | `0x007A0000` | `0x08` | byte, **source** increments |

  Mode meanings are MAME's micro-DMA decoder
  (`../mame/src/devices/cpu/tlcs900/tmp95c061.cpp:368-372` and `:398-402`). One
  side fixed and one side walking is a **data port**, and `0x7A0000` sits on the
  same CS0 window as `0x7B0000`. So the two-register command/status interface
  documented above is one half of a subsystem whose other half is a DMA'd bulk
  data port at `0x7A0000`, with INT7 as the per-byte request line. `Dev7A_` is
  used as a positional name for that window, exactly as `Dev7B_` is for the
  other; neither is a part name.

  Corroboration from the other direction: `Dev7B_WaitStatus_8x_Cx` (`0xFE59F3`,
  converted) sits inside this same block and polls **`0x7B0004`** through
  `Dev7B_ReadStatus`. One block, both windows.

  And the 0x7A window gets the same treatment the 0x7B one got. Censusing
  `0x7A0000`-`0x7A000F` over prom_a and prom_b for the 24-bit memory-operand
  forms **and** for `ld XRR,imm32` finds **four** sites, every one of them naming
  `0x7A0000` and none naming any other address in the window:

  | site | instruction | path |
  |---|---|---|
  | `0xFE59BB` | `ld XHL,0x007A0000` → `DMAS0` | micro-DMA, device → RAM |
  | `0xFE59DA` | `ld XHL,0x007A0000` → `DMAD0` | micro-DMA, RAM → device |
  | `0xFE680F` | `ld C,(0x7A0000)` | programmed I/O read — converted 2026-08-25, inside `Fdc_ServiceDataByte` |
  | `0xFE682B` | `ld (0x7A0000),C` | programmed I/O write — same routine |

  Two paths to **one** address is the strongest single argument that `0x7A0000`
  is a data register and not a range. ⚠ The DMA path walks `(0x605A3C)` and the
  programmed-I/O path walks `(0x605A3E)`; those two 32-bit slots **overlap** in
  RAM. Recorded as observed, not explained. `notes/prom_a_byte_checks.py` re-runs
  this census and fails if the count is ever not four.

* "**which is why INT7's vector points at the deliberate hang and never fires**"
  — retracted, see `FINDINGS-interrupt-vectors.md`. The argument was that the DMA
  engine absorbs INT7; MAME clears `DMA0V` at end-of-count
  (`tmp95c061.cpp:450`), which is exactly why this handler has to write it back,
  so there is a window in which INT7 reaches the CPU. Round 2 also removes the
  last thing that made the old claim comfortable: INT7 now has an identified
  **requester** — a peripheral raising it once per transferred byte.

## The direction selector, and ten command codes

`Dev7A_StartDma` (`0xFE596A`) loads `DMAC0` from `(0x605A0E)` and then runs a
flat compare chain on the byte at `(0x605A18)`:

```
RAM -> device : 0x4D 0xC9 0xC5
device -> RAM : 0xDD 0xD9 0xD1 0x4A 0x42 0xCC 0xC6
anything else : return, with DMAC0 already written
```

~~⚠ **What those ten codes mean is not established.**~~ **ESTABLISHED
2026-08-25: they are uPD765 command opcodes**, and the split is exactly the
direction each command moves data — `0x4D` FORMAT TRACK, `0xC9` WRITE DELETED
DATA, `0xC5` WRITE DATA out; `0xDD`/`0xD9`/`0xD1` the three SCANs, `0x4A`
READ ID, `0x42` READ TRACK, `0xCC` READ DELETED DATA, `0xC6` READ DATA in.
`(0x605A18)`, the byte this chain reads, is the FDC command byte.
`notes/prom_a_fdc_checks.py` asserts that all ten are in the driver's own
accepted-opcode set. The old caveat, kept because it was right at the time:
they are recorded as the ten literals the ROM compares against, in ROM order. `notes/prom_a_byte_checks.py` **parses** the
chain out of the ROM rather than repeating this list, so a miscount fails.

## Still `.incbin`, and still the two that would settle the most

~~* `0xFE5A41` … `0xFE5B5E` … `0xFE5E84` …~~ **All three converted 2026-08-25**:
`Fdc_WaitRqm`, `Fdc_ClassifyResultStatus` and `Fdc_SetError` — which is indeed
the error reporter, and keeps the first code raised. Its code list is in
`notes/FINDINGS-prom_a-fdc.md` §7.

## The tick counter these timeouts run on

`(0x605A00)` is a 16-bit counter. `python3 notes/prom_a_addr_census.py 0x605A00`
finds **17** instructions touching it in prom_a + prom_b, all in prom_a, all
converging under backward disassembly, and exactly **one** of them writes:

```
  prom_a  0xF82D14  D2+d24   34/64  incw 1,(0x605a00)     <- INTT1_Tick
  ... 16 more, every one a read
```

So `(0x605A00)` counts INTT1 ticks and nothing else moves it, which is what makes
`elapsed = (0x605A00) - snapshot` a timeout and not a race.
