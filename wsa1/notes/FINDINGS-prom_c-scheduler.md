# CPU 2 runs a six-phase tick scheduler, and the loop that consumes it

Scope: `prom_c` (IC28, CPU 2).  Every routine named here is converted in
`prom_c/wsa1_prom_c.s` and certified by `scripts/analysis/assert_byte_identical.py`.
Every reference count is reproducible with `notes/prom_c_xrefs.py`.

## The shape

```
  timer 1  --INTT1-->  INTT1_HANDLER (0xF99063)
                          0x00F2F3 += 1                (the tick counter)
                          phase = 0x00E2E3             (0..5, wraps)
                          set bits in 0x007ED1 per phase
                          phase = (phase + 1) mod 6

  MAIN (0xF98B7D), endless:
        drain MIDI in -> 32-byte buffer -> 0xF9997E(buf, len, 6)
        if 0x007ED1 bit 4:  clear it; 0xF99E5F, 0xFB05EC, a period-14 counter
                            at 0x00E2DF, a countdown at 0x00F2F1, the 0x007ECC
                            latch
        if 0x007ED1 bit 5:  clear it; 0xF98A75
        if 0x007ED1 bit 3:  clear it; sub_F9915C
        0xF98CB9; 0xFB060A; 0xF994E4
        repeat
```

## The schedule, read off the six blocks

| phase | bits set in `0x007ED1` |
|---|---|
| 0 | 7, 4 |
| 1 | 6 |
| 2 | 5 |
| 3 | 7, 3 |
| 4 | 6 |
| 5 | 5 |

Bits 7/6/5 repeat with period **three**; bits 4 and 3 fire once per **six** ticks, on
opposite halves of the cycle.  So there is one job that runs every third tick in three
variants, plus two jobs that alternate.

**Six is not a guess.**  It is fixed twice: `cps bc,5 / jr ugt` rejects any phase above 5,
and the jump table's six 4-byte entries at `0xF990C8` end exactly on `0xF990E0`, the first
instruction after it.  The wrap is `inc` / `cp ...,0x06` / reset.

## ★ Two bits are posted and never collected

`python3 notes/prom_c_xrefs.py 0x007ED1 --no-window` finds **fourteen** references in prom_c:
the eight `set` instructions in `INTT1_HANDLER` and six in `MAIN`, which are three matched
test/clear pairs on bits **4, 5 and 3**.  Bits **6 and 7** are set by the handler and read by
nothing that names the address outright.

⚠ Read that as what it is.  The scan searches for the 24-bit literal, so a read through a
pointer register would not appear.  It is "no literal-addressed reader", not "dead".

## The tick counter

`0x00F2F3` is a 32-bit counter incremented by exactly one instruction in the whole image:

```
  0xF9906D  e2 f3 f2 00 89   add (0x00f2f3),XBC     (XBC = 1)
```

The other **eighteen** references are reads (`python3 notes/prom_c_xrefs.py 0x00F2F3
--no-window --classify`).  Its boot value is 0.  Both serial ISRs copy it to an adjacent word
on every non-error interrupt, which is how `notes/FINDINGS-prom_c-serial-midi.md` came to
suspect a timestamp; it is one, in units of INTT1 ticks.

⚠ **The tick RATE is not established.**  `Timer1_SetPeriodAndStart` (0xF990FA) writes
`TREG1` — with the fc byte from `0xFFFFEF`, so the period tracks the clock the same way the
UART's baud divisor does — but nothing located so far writes `T01MOD`, so the timer's input
clock is unknown and 28 counts cannot be turned into a time.

## What the phase-3 job does, and why it runs once

`sub_F9915C` early-outs unless the tick counter has passed 250 **and** the byte at `0x00E2E4`
is non-zero; then it decrements that byte.  `0x00E2E4`'s boot value is **1**
(`notes/FINDINGS-prom_c-ram-image.md`), so the body runs on the first phase-3 tick after tick
250 and never again.  It samples bit 0 of `0x0000FFF8`, writes 1 or 2 to `0x00F35F`, and sets
bit 7 of `0x007ECC` — which `MAIN` tests at `0xF98C52`.

⚠ What `0x0000FFF8` holds is unknown; it is work DRAM and its writer has not been found.  The
routine therefore keeps its address for a name.

## Three entry points, only one of which is `MAIN`

`EntryPoint_Records` at `0xF980EA` is three 12-byte records:

| entry | second field | third |
|---|---|---|
| `0x00F98B7D` — `MAIN` | `0x0000FFF0` | `0x00028800` |
| `0x00FA54DB` | `0x0000F980` | `0x00028800` |
| `0x00F98118` — `DSP_ChannelRefresh_Loop` | `0x0000F480` | `0x00018800` |

Two of the three code addresses are converted routines and both are genuine entry points
(one is `MAIN`; the other disables interrupts, opens a frame and loops for ever).  The second
column is three descending addresses at the top of work DRAM, and the first of them,
`0x0000FFF0`, is **exactly** the value `RESET` installs in XSP.  So `{entry point, initial
stack pointer, ?}` is the natural reading.

⚠ It is a reading.  Nothing in prom_c references `0xF980EA`, so the consumer that would prove
it has not been found, and the third column is not decoded.  The neighbouring `INTT3` handler
jumps to `0xF9831C`, which pushes seven register pairs and jumps again — the shape of a
context switch — but that code is not converted and nothing here connects the two.

> ⚠ **2026-08-25 weakened the "initial stack pointer" reading a little.**  `0x0000FFF0` appears
> as a 32-bit literal in exactly three places in prom_c: here, in `RESET`'s
> `ld XSP,0x0000FFF0`, and at ROM `0xFCC81A`, where it is the base of the **key-state bitmap**
> (`notes/FINDINGS-prom_c-keyboard-and-touch.md`).  `RESET` moves the stack down to
> `0x0000FA00` at 0xF9816B before `MAIN` runs, and the bitmap is not built until `MAIN`'s init
> chain reaches 0xF997FA, so the two uses do not collide in time — but the same value having a
> second, unrelated job means the reading now rests only on the first record matching `RESET`,
> not on the value being distinctive.

## Reproduce

```
python3 notes/prom_c_xrefs.py 0x007ED1 --no-window
python3 notes/prom_c_xrefs.py 0x00F2F3 --no-window --classify
python3 notes/prom_c_ram_image.py
```
