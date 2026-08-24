# How CPU 1 receives a message from the other processor

**Established 2026-08-24 from prom_a `0xF8E47F` (INT0), converted.**
`notes/FINDINGS-memory-map.md` lists `0x7C0000` as an "inter-processor link port
(strobe P7.0, busy P7.3)". This is the receiving half of the protocol on that
port, and the mechanism is worth writing down because it is not a polling loop
and not a per-byte interrupt.

## The trick: INT0 re-points itself at the micro-DMA engine

1. **The first byte of a message raises INT0.** `INT0_LinkByte` reads it from
   `0x7C0000`, keeps a copy at `(0x600780)`, and treats it as a **command**.
2. From the command it derives **how many more bytes will follow and where they
   go**, and programmes micro-DMA channel 3 with that destination and count
   (through the stack-argument helper `uDMA3_SetDest`, prom_a `0xF8E6C9`).
3. It then writes **`DMA3V = 0x0A`**. `tlcs900_process_hdma` computes a channel's
   trigger as `(DMAnV & 0x1f) << 2`
   (`../mame/src/devices/cpu/tlcs900/tmp95c061.cpp:353`), and `0x0A << 2 = 0x28`
   — **INT0's own vector**. So from that moment every further byte of the message
   is absorbed by the DMA engine and the CPU never sees the interrupt at all.
4. The CPU next hears about the message when the transfer completes and raises
   **INTTC3** (vector `0x80` → prom_b thunk → prom_a `0xF8E54F`). `(0x6007DA)`,
   set on the way in, tells that handler which message it is finishing.

That is a genuinely economical design: one interrupt per *message* rather than
one per byte, with the message length carried in the first byte.

## The command byte

| command | payload | lands at | `(0x6007DA)` |
|---|---|---|---|
| `0xE1` | 6 bytes | `0x6007D3` | 2 |
| `0xE2` | 10 bytes | `0x600788` | 3 |
| `0xE6` | none | — (also clears bit 6 of `(0x8A)`) | 0 |
| anything else | `(byte & 0x1F) + 1` bytes | `0x6007B3` | 1 |

⚠ **What the commands MEAN is not established** — only their payload sizes and
destinations. Do not name them from this evidence.

The self-describing-length rule (`(byte & 0x1F) + 1`) means the general case
carries a 5-bit length in the command byte and 3 bits of opcode, which is
probably the real encoding and `0xE1`/`0xE2`/`0xE6` the exceptions to it. That is
a reading, not a finding.

## Handshake lines

P7 (SFR `0x13`) carries the handshake, and prom_a uses more of it than the memory
map note records:

* **bit 2** is tested first thing in `INT0_LinkByte`; when set, the interrupt is
  taken and dropped without the port being read at all.
* **bit 1** is cleared after the DMA is armed, on all three paths that arm one —
  an acknowledge, presumably.
* bits 0 and 3 are the strobe/busy the memory-map note already records.
* `NMI_PowerFail_SaveAndHalt` sets bits 4 and 5 of P7 as its very first act.

## The other side: channel 2

Micro-DMA **channel 2** is the transmit engine, and RESET's comment already
points at it: `0xF8E166` writes `DMA2V = 0x12` (`0x12 << 2 = 0x48 = INTT2`) and
starts timer 2, so the timer paces the outgoing transfer. `INTTC2_uDMA2Done`
(prom_a `0xF8E52D`, converted) stops timer 2 again and steps `(0x6007D9)` down
2 → 1 → 0; the arming code at `0xF8E173` spins on that byte reaching 0.

## Not yet converted

* `0xF8E54F` — **INTTC3**, the completion handler. It dispatches on `(0x6007DA)`
  and is where the received messages are actually acted on. This is the obvious
  next thing to read: it is what turns the four command classes above into
  behaviour.
* `0xF8E100`-`0xF8E180` — the transmit path that arms channel 2.
