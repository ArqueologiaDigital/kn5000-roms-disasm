# prom_c's serial channel 0 is the MIDI port

Scope: `prom_c` (IC28, CPU 2), the interrupt handlers converted at `0xF991FF-0xF992A6`,
`0xF99BBE-0xF99C11`, `0xF99CFE-0xF99D6E` and `0xF99E5E`. All of it is in
`prom_c/wsa1_prom_c.s` and certified by `scripts/analysis/assert_byte_identical.py`.

## The claim

Serial channel 0 on CPU 2 carries **MIDI**, and `INTRX0_HANDLER` at `0xF991FF` is the MIDI
input ISR.

## The evidence, all of it visible in the handler itself

The receive ISR reads `SC0CR` (0x51) and `SC0BUF` (0x50), then does three things that are each
MIDI-specific and are together conclusive.

**1. It tests the receive-error flags.** `and c,0x1c` masks exactly bits 4..2 of `SC0CR` — the
three receive error flags of a TLCS-900 serial channel. On error the status byte is stored at
`0x00F327` and the data byte is dropped.

**2. The range filter is MIDI's, exactly.** Two SIGNED compares:

```
    cp (xiz-1),0x00 / jr ge   ->  0x00..0x7F  enqueued
    cp (xiz-1),0xf8 / jr lt   ->  0x80..0xF7  enqueued
                                  0xF8..0xFF  DROPPED
```

`0xF8-0xFF` is the MIDI **System Real-Time** range, which by the standard may appear *between*
the bytes of another message and therefore must not be queued with it. A serial protocol that
was not MIDI would have no reason to carve out that particular eight-value window, and a naive
implementation would use an unsigned compare — this one is signed, so `0x80..0xF7` (−128..−9)
passes and `0xF8..0xFF` (−8..−1) does not, which is the cheapest possible way to express
"everything except the top eight codes".

**3. The one byte singled out for a flag is `0xFE`** — MIDI **Active Sensing**. It sets
`0x00F2F8 = 1` and is then dropped like the rest of its range.

**Independent corroboration.** `notes/FINDINGS-system-clock.md` already establishes that the
firmware recomputes `BR0CR` from the fc byte at `0xFFFFEF` by a rule that makes the channel-0
bit rate come out at **31250** for any fc — the MIDI rate — and that this is how fc = 28 MHz is
asserted in the first place. That finding was made without reference to this handler; this
handler was decoded without reference to that finding.

**⚠ NOT ESTABLISHED:** which physical connector SC0 reaches. The identification is from the
protocol this code implements, not from a trace of the board.

## The transmit side

`INTTX0_HANDLER` at `0xF99265` is the mirror: it calls `0xF9942F` with the descriptor address
`0x00F311`, and either gets `0xFFFF` (queue empty — it then sets `0x00F2F9 = 2`) or writes the
byte to `SC0BUF`. The receive side uses the same calling convention with `0x00F2FB`, so those
two addresses are presumably ring-buffer descriptors — **presumably**; neither `0xF9932E` nor
`0xF9942F` has been traced.

Both handlers copy the 32-bit value at `0x00F2F3` into adjacent destinations (`0x007ED6` on
receive, `0x007ED2` on transmit) on every non-error interrupt.

## ✅ ANSWERED, 2026-08-24: `0x00F2F3` counts INTT1 interrupts

This note used to close with *"What `0x00F2F3` counts is NOT ESTABLISHED; being read as a
32-bit value on every serial interrupt is what a free-running timestamp would look like."*
It is a free-running timestamp, and the thing that runs it is **timer 1**.

`INTT1_HANDLER` at `0xF99063` — now converted in `prom_c/wsa1_prom_c.s` — begins

```
	sub	xbc, xbc
	inc	1, xbc
	addl_da	0x00F2F3, xbc		; 0x00F2F3 += 1
```

and a census of every literal-addressed reference to it in prom_c shows this is the **only
one of twenty-one that writes it**; the other twenty are `ld reg,(0x00F2F3)` or
`pushw (0x00F2F3)`. Reproduce:

```
python3 notes/prom_c_xrefs.py 0x00F2F3 --no-window --classify
```

which ends with `TOTAL literal-addressed sites: 21`.

> **⚠ CORRECTION, round 2 — this figure was NINETEEN and was wrong.** The census behind it
> searched the 24-bit-direct spelling of the address only. TLCS-900 spells a direct memory
> operand as `prefix = 0xC0 | (size << 4) | width`, where *width* 0/1/2 selects a 1-, 2- or
> 3-byte address field — **twelve spellings of one address, not one**. `0x00F2F3` fits in 16
> bits, so the `0xD1` (word, 16-bit-address) form encodes it too, and two sites use it:
>
> ```
> f99fc2: d1 f3 f2 23   ld HL,(0xf2f3)
> f99fcd: d1 f3 f2 21   ld BC,(0xf2f3)
> ```
>
> Both are inside `Link_WaitDeviceIdle_500` (`0xF99FC1`, converted in round 2) and both are
> **reads**, so the load-bearing conclusion — one writer, therefore this address counts INTT1
> interrupts — survives; only the number was wrong. `notes/prom_c_xrefs.py` now sweeps all
> twelve spellings and prints the total, and its docstring carries the encoding rule.
> Re-censused with the fixed tool, the other addresses this tree quotes counts for —
> `0x007ED1` (14), `0x00F32A` (3), `0x00F32B` (2) — are **unchanged**, because those are only
> ever spelled 24-bit.

Its boot value is **0** (`notes/FINDINGS-prom_c-ram-image.md`), so it really does count from
reset. ⚠ Two limits remain: no search here can see a write through a **pointer register**;
and the timer-1 **rate** is still unknown, because `Timer1_SetPeriodAndStart` (`0xF990FA`)
writes TREG1 but nothing located so far writes T01MOD. So the two serial handlers stamp each
byte with a monotonic tick count whose *unit* is not established.

One thing the tick number does buy immediately: `sub_F9915C`'s guard `cp XBC,0x000000FA`
means "250 ticks after reset", not "250 of something else".

## The other three handlers converted in this pass

| handler | vector | what it does |
|---|---|---|
| `INT0_HANDLER` `0xF99BBE` | 0x28 | reads a command byte from the CPU-1 link port at `0x00100000` and dispatches commands **0xE1..0xE7** through a 7-entry table at `0xF99BF6`; anything else goes to `0xF99CCF`. The range is read off `sub bc,0x00E1 / cps bc,6 / jrl ugt`. |
| `INTTC2_HANDLER` `0xF99CFE` | 0x7C | micro-DMA channel 2 completion: clears a `TRUN` bit and steps a state byte at `0x00F32C` 2 → 1 → 0. |
| `INTTC3_HANDLER` `0xF99D20` | 0x80 | micro-DMA channel 3 completion: dispatches a **9-state** machine from `0x00F32D` through a table at `0xF99D4B`. The state range is read off `dec 1,bc / cp bc,0x0008 / jrl ugt`, and 9 entries is also exactly the space before the first target. |
| `INTT2_HANDLER` `0xF99E5E` | 0x48 | a single `RETI`. Not dead code: the vector-table note for slot 0x48 records that this is the interrupt CPU 2's micro-DMA channel 2 is armed on (`DMA2V = 0x12` at `0xF99A2A`), and a micro-DMA channel needs its interrupt to fire and be dismissed for the transfer to be paced. The byte before it is a different routine's `RETI`, so this really is a one-instruction handler and not a tail. |

⚠ On `INT0_HANDLER`: the KN5000 sub-CPU's INT0 handler
(`../kn5000-roms-disasm/v142/subcpu/kn5000_subprogram_v142.s:2429`) reads its own link port the
same way and also special-cases 0xE1/0xE2/0xE3 — but it is **not** byte-identical to this one,
and it dispatches with a chain of compares rather than a table. The command numbers agreeing
across the two machines is suggestive; it is not proof that they mean the same thing.

## Vectors still not converted — none, as of 2026-08-24

The previous version of this section said `INT4`, `INTT1` and `INTT3` were still inside
`.incbin` and picked `INTT1` as the obvious next one. All three are now converted:

| vector | handler | what it turned out to be |
|---|---|---|
| `INT4` 0x2C | `0xF995C2` | a bare `RETI`, like `INTT2`. Nothing in the converted code arms a micro-DMA channel on it, so unlike `INTT2` there is no explanation for why it is armed. |
| `INTT1` 0x44 | `0xF99063` | the tick counter above, plus a **six-phase** work schedule posted into `0x007ED1`. The 6-way table at `0xF990C8` was correctly located; the count is fixed twice over, by `cps bc,5 / jr ugt` and by the table's 24 bytes ending exactly on the next instruction. |
| `INTT3` 0x4C | `0xF98165` | two instructions — increment `0x000090`, then `jrl 0xF9831C`, which is where the `reti` lives. Timer 3 is started by `Timer3_Init` at `0xF98B6D` with TREG3 = 0x2E. |

**And the consumer of the schedule is converted too.** `MAIN` at `0xF98B7D` test-and-clears
bits 4, 5 and 3 of `0x007ED1`, one pair each. Those six sites plus `INTT1_HANDLER`'s eight
`set` instructions are ALL fourteen references to `0x007ED1` in prom_c
(`python3 notes/prom_c_xrefs.py 0x007ED1 --no-window`), which leaves a real gap: ⚠ INTT1
also sets bits **6 and 7**, and nothing that names `0x007ED1` outright ever reads them.
