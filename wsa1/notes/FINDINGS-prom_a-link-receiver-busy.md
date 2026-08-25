# Why CPU 1 stops releasing the link's receiver-busy line — emulation gap C, answered

**Written 2026-08-25.** This answers, from prom_a's already-converted link block,
the question `kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md` gap C asks:

> After CPU 2 sends its first packet, CPU 1 leaves P7 bit 1 low forever. Which
> arm of `INT0_LinkByte` (prom_a `0xF8E47F`) drops it, which arm is supposed to
> raise it, and what does `INTTC3_LinkDmaDone` (`0xF8E54F`) require before it
> runs?

No new bytes had to be converted: `0xF8E000-0xF8E6A1` was already assembly. What
was missing was the census. `python3 notes/prom_a_p7_link_census.py` produces
every number below and fails if any of them drifts.

## The complete set of sites — 3 clear, 6 set, 1 test, and nothing in prom_b

P7 is SFR `0x13`. Censusing `F0 13 <B0|n / B8|n / C8|n>` over **both** images
for **all eight bits** finds, for bit 1:

```
res 1,(P7)   3 sites   0xF8E4CD  0xF8E4EC  0xF8E522
set 1,(P7)   6 sites   0xF8E258  0xF8E5A8  0xF8E5D6  0xF8E5EB  0xF8E663  0xF8E68C
bit 1,(P7)   1 site    0xF8E627
```

prom_b touches it **nowhere**, and every one of those ten sites is inside
`0xF8E000-0xF8E6A1`, which is converted assembly — so these are instruction
boundaries, not byte-window candidates, and the counts are exact.

## Which arm drops it

All three `res` sites are in `INT0_LinkByte`, and they are **the three arms that
arm micro-DMA channel 3** — one per message shape:

| site | arm | payload |
|---|---|---|
| `0xF8E4CD` | command `0xE1` | 6 bytes → `0x6007D3`, selector 2 |
| `0xF8E4EC` | command `0xE2` | 10 bytes → `0x600788`, selector 3 |
| `0xF8E522` | any other command | `(cmd & 0x1F) + 1` bytes → `0x6007B3`, selector 1 |

Each is `ldio DMA3V,0x0A` immediately followed by `res 1,(P7)`. The `0xE6` arm
(no payload) and the early-out when P7 bit **2** is already set never touch it.

**So bit 1 low means exactly one thing: a micro-DMA channel-3 receive is in
flight.** It is a receiver-busy line in the literal sense, and `INT0_LinkByte`
is right to leave it low.

## Which arm raises it

Three NORMAL releases, all in `INTTC3_LinkDmaDone`, one per selector:

| site | selector | reached when |
|---|---|---|
| `0xF8E5A8` | 1 | the general-command payload landed and its prom_b handler returned |
| `0xF8E5D6` | 3 | an `0xE2` read request landed |
| `0xF8E5EB` | 4 | the payload of an `0xE1` block landed |

and three RECOVERY releases, each with its own error counter:

| site | routine | condition | counter |
|---|---|---|---|
| `0xF8E258` | `sub_F8E222` | bit 6 of `(0x8A)` still set after **2500** ticks | `(0x6007DB)` |
| `0xF8E663` | `Link_ServiceTask` | **eleven** consecutive equal `DMAC3` samples | `(0x6007DC)` |
| `0xF8E68C` | `Link_WaitBlockDone` | bit 7 of `(0x8A)` still set after **500** ticks | `(0x6007E1)` |

Selector **2** — the `0xE1` header — deliberately does **not** release it: it
re-arms channel 3 for the block's payload and sets selector 4, so the line stays
low across the two-burst transfer. That is correct behaviour, not a leak.

## What `INTTC3_LinkDmaDone` requires before it runs

Micro-DMA channel 3 must reach **end of count**. And the trigger it counts on is
`DMA3V = 0x0A`, i.e. `0x0A << 2 = 0x28`, which is **INT0's own vector**
(`tlcs900_process_hdma` computes the trigger as `(DMAnV & 0x1F) << 2`,
`../mame/src/devices/cpu/tlcs900/tmp95c061.cpp:353`). So:

> **every payload byte must raise INT0 again, exactly as the header byte did,
> while `DMA3V` is armed.** The DMA engine absorbs those interrupts instead of
> the CPU, and only when the count runs out does `INTTC3` fire.

## Applied to the measured wedge

The gap note measures one packet getting through: link channel 6, header `0xC0`,
length 1, sent by `MIDI_Watchdogs_And_TransportSwitch`. Walk it:

1. `0xC0` is not `0xE1`, `0xE2` or `0xE6`, so `INT0_LinkByte` takes the "other"
   arm: length `= (0xC0 & 0x1F) + 1 = 1`, destination `0x6007B3`, selector 1;
2. `DMA3V = 0x0A`; **`res 1,(P7)`** — this is the observed drop at t=82;
3. the link must now deliver **one more byte**, whose INT0 the DMA engine takes;
4. count hits zero → `INTTC3` → selector 1 → the payload's top three bits
   (`0xC0 >> 5 = 6`) pick entry 6 of the eight-entry LE32 table at prom_b
   `0xF57D4F`, which is `0x00F57C72` → return → **`set 1,(P7)`**.

The line is never raised because **step 3 never completes**. That is the thing
to fix, and it is one of exactly two possibilities:

* the emulated link never presents the payload byte's INT0 to the micro-DMA
  engine — the driver's one-byte INT0 latch is the obvious suspect, and the
  question to ask it is whether a DMA read of `0x7C0000` counts as the CPU
  having consumed the byte; or
* the byte is presented but the DMA does not consume it (a `DMA3V` that MAME
  cleared, or a channel-3 count that was never loaded).

## Three cheap probes that tell those apart, in RAM

Nothing here needs new disassembly; all four addresses are established above.

| read | meaning |
|---|---|
| `(0x6007DA)` | the selector. Non-zero and stuck ⇒ `INTTC3` never fired |
| `DMAC3` (control register `0x2C`) | the residual count. 1 and unchanging ⇒ the payload byte never reached the DMA engine |
| `(0x6007DC)` | `Link_ServiceTask`'s abort counter. **Zero while the line is stuck is itself a finding** — it means the main-loop watchdog is not running, because it would have released the line after eleven passes |
| `(0x6007DB)`, `(0x6007E1)` | the other two recovery counters |

★ The watchdog point is worth stating on its own: `Link_ServiceTask`
(`0xF8E5F6`, reached from prom_b thunk `0xF40ED8`, called at prom_a `0xF82165`
inside a `tset 5,(0x88)` arm of the main-loop rota) tests `bit 1,(P7)` — the
single test site — and **only counts a stall while the line is low**. A firmware
that is running its rota cannot leave bit 1 low forever; it aborts after eleven
passes and releases it. So "low forever" says the rota arm is not being reached
either, and that is a second, independent symptom to chase.

## What is NOT established

* what the eight prom_b handlers behind selector 1 do, including entry 6, the
  one channel-6 packets reach;
* what P7 bit **2** is driven by. It is tested exactly once, at `0xF8E489`, and
  **no bit-form write to it exists in either image** (`set 2,(P7)` and
  `res 2,(P7)` both censused: zero hits in prom_a and prom_b); the only
  whole-register write to P7 anywhere is `ldio P7,0xFF` in RESET at
  `0xF826C4`. So it reads like an INPUT, and it gates the whole receive path:
  when it is set, INT0 is taken and dropped without the port being read at all.
  ⚠ Whether P7CR/P7FC configure it as an input is not checked here.
