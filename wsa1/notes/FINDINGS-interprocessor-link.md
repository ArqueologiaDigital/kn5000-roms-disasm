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

## ★ 0xE1 and 0xE2 are a REMOTE BLOCK READ — added 2026-08-24

`INTTC3_LinkDmaDone` (prom_a `0xF8E54F`) and `Link_ServiceTask` (`0xF8E5F6`) are
now converted, and with them the two commands decode. Four routines agree field
for field, which is why this is stated rather than guessed:

1. `INT0_LinkByte` puts an `0xE2` message's **ten** payload bytes at `0x600788`.
2. `Link_ServiceTask` reads exactly those ten bytes back as **three fields** —
   long `(0x600788)`, word `(0x600790)`, long `(0x60078C)` — and hands them to
   the `0xE1` transmitter at `0xF8E26F`.
3. That transmitter sends a **six-byte header** built as long `(0x6007A1)` = its
   `XIZ+0x0E` argument and word `(0x6007A5)` = its `XIZ+0x0C` argument, then a
   second micro-DMA burst of `(XIX+4)` bytes read from `(XIX)` — the `XIZ+0x0C`
   count and the `XIZ+0x08` address.
4. `INTTC3_LinkDmaDone` selector 2 takes the **six bytes** an `0xE1` message left
   at `0x6007D3` and feeds long `(0x6007D3)` to `DMAD3` and word `(0x6007D7)` to
   `DMAC3` — destination then count, the same two fields in the same order.

So:

| command | meaning |
|---|---|
| `0xE2` | "send me `count` bytes from `src`, and put them at `dst` in your memory" |
| `0xE1` | "here is a block: `dst`, `count`, then the bytes" |

and the answer to an `0xE2` is composed in the **main loop**, not in interrupt
context: `INTTC3` only sets bit 7 of `(0x600792)`, and `Link_ServiceTask` — which
prom_a calls at `0xF82165` from a `tset 5,(0x88)` arm of the rota — is what
actually transmits.

⚠ **What the blocks CONTAIN is still not established.**

## `(0x6007DA)`, the completion selector

| value | set by | what `INTTC3` then does |
|---|---|---|
| 0 | command `0xE6`, and every completed exchange | nothing; returns |
| 1 | any other command | dispatch on the command's **top three bits** through an eight-entry LE32 table at prom_b `0xF57D4F`, passing the payload buffer `0x6007B3` and the length `(cmd & 0x1F)+1` as stack arguments |
| 2 | command `0xE1` | re-arm channel 3 for the payload named by the six-byte header, `DMA3V = 0x0A` again, selector := 4 |
| 3 | command `0xE2` | flag `(0x600792)` bit 7 for the main loop |
| 4 | the `0xE1` payload finishing | clear bit 7 of `(0x8A)`, releasing `Link_WaitBlockDone` |

The eight-entry table is `0x00F57C3F 0x00F57C2D 0x00F8E000 0x00F57C50 0x00F57C61
0x00F57C97 0x00F57C72 0x00F8E000`; all eight have a `0x00` high byte and land
inside `0xF00000-0xFFFFFF`, which is what says it is eight entries wide.

## Three error counters, and nothing reads them

| byte | incremented when |
|---|---|
| `(0x6007DB)` | the `0xE5`/`0xE6` handshake at `0xF8E222` timed out (2500 ticks) |
| `(0x6007DC)` | `Link_ServiceTask`'s stall watchdog aborted a receive |
| `(0x6007E1)` | `Link_WaitBlockDone` timed out (500 ticks) |

The stall watchdog is worth a line of its own: once per rota pass,
`Link_ServiceTask` samples `DMAC3` through `uDMA3_GetCount` and compares it with
the previous sample in `(0x6007DF)`. Eleven equal samples in a row and it gives
up — `DMA3V = 0`, selector 0, P7 bit 1 back to idle. It only counts while P7
bit 1 says a transfer is in flight.

## `(0x8A)` — the nine instructions that touch it

Produced by `python3 notes/prom_a_addr_census.py 0x00008A`, which searches **all
twelve** direct-address spellings the TLCS-900 has (four prefix groups x 8/16/24-bit
absolute) over prom_a and prom_b, and then filters byte matches by backward-
disassembly convergence:

```
  prom_a  0xF8E16C  F2+d24   22/64  set 7,(0x00008a)
  prom_a  0xF8E1EA  F2+d24   21/64  set 7,(0x00008a)
  prom_a  0xF8E22B  F2+d24   22/64  set 6,(0x00008a)
  prom_a  0xF8E23C  F2+d24   22/64  bit 6,(0x00008a)
  prom_a  0xF8E25B  F2+d24   20/64  res 7,(0x00008a)
  prom_a  0xF8E4F7  F2+d24   20/64  res 6,(0x00008a)
  prom_a  0xF8E5E6  F2+d24   17/64  res 7,(0x00008a)
  prom_a  0xF8E671  F2+d24   20/64  bit 7,(0x00008a)
  prom_a  0xF8E68F  F2+d24   20/64  res 7,(0x00008a)
     (seven further byte matches, F1+d16, all 0/64 and none decodable)
```

**Bit 7** — "a link transfer is outstanding":

* **set** at `0xF8E16C` and `0xF8E1EA`, both immediately after micro-DMA
  channel 2 has been armed and timer 2 started, i.e. as an outgoing transfer
  begins;
* **tested** at `0xF8E671`, inside `Link_WaitBlockDone`;
* **cleared** at `0xF8E25B` (a timeout path), at `INTTC3` selector 4
  (`0xF8E5E6`) and in `Link_WaitBlockDone`'s own timeout (`0xF8E68F`).

**Bit 6** is a second, independent flag in the same byte: set at `0xF8E22B`,
tested at `0xF8E23C` (both in the `0xE5`/`0xE6` handshake at `0xF8E222`) and
cleared by `INT0_Cmd_E6` at `0xF8E4F7`. So `(0x8A)` is a flag byte, not a
one-bit variable — worth knowing before anyone writes the whole byte.

`Link_WaitBlockDone` (`0xF8E66D`, reached through prom_b thunk `0xF4123C`) is the
wait for bit 7, with a 500-tick limit measured on `(0x80)`, the counter
`INTT1_Tick` increments.

⚠ **Corrected 2026-08-25 (audit round 1, F6).** This section used to be headed
"`(0x8A)` bit 7 — every site that touches it" over a census of ONE spelling,
`F2 8A 00 00 <op>`. Completeness was claimed from a search that covered a twelfth
of the encodings. Re-running it properly changes the list twice over: the
bit-7 test at `0xF8E671` was missing (the prose named it, the "every site" list
did not), and three bit-6 sites were not mentioned at all. As it happens the
compiler used only the 24-bit form for this address, so the old *method* would
have found all nine had it been applied without the bit-7 filter — the claim was
lucky, not proven, and `prom_a_addr_census.py --selftest` now asserts both lists.

## Not yet converted


* `0xF8E0FE`-`0xF8E31F` — the transmit path: a command-with-10-byte-record
  sender (`0xE2`), a command-with-32-bit-argument sender (`0xE1`-family, `0xF8E181`),
  the `0xE3` and `0xE5` wrappers at `0xF8E1FE`/`0xF8E222`, and the `0xE1` block
  transmitter at `0xF8E26F`. All disassembled while decoding the above, none
  converted.
* The eight prom_b handlers the selector-1 table names.
