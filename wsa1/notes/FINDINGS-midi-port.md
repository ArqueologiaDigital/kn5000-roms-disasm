# Serial channel 0 is the MIDI port — the two interrupt handlers, and (0xA0)

**Established 2026-08-24 while converting prom_a.** `prom_a/wsa1_prom_a.s`
already asserted "serial channel 0 = the MIDI port" from traffic. This note
converts the two interrupt handlers that carry that traffic and reads the RAM
protocol out of them.

Both handler bodies are in **prom_a**, reached through prom_b thunks:

| vector | slot | thunk | body |
|---|---|---|---|
| INTRX0 (receive) | `0xFFFF60` | `0xF40714` → | `MIDI_RX_Byte` @ `0xFA5496` |
| INTTX0 (transmit) | `0xFFFF64` | `0xF40718` → | `MIDI_TX_Ready` @ `0xFA542F` |

## (0xA0) is the System Real Time transmit-request bitmap

`MIDI_TX_Ready` is a five-way priority test on `(0xA0)`, and each arm writes one
byte into `SC0BUF` and clears its bit:

| bit | byte | MIDI message | written at |
|---|---|---|---|
| 0 | `0xF8` | TIMING CLOCK | `0xFA5457` |
| 1 | `0xFA` | START | `0xFA5467` |
| 2 | `0xFB` | CONTINUE | `0xFA546F` |
| 3 | `0xFC` | STOP | `0xFA544F` |
| 4 | `0xFE` | ACTIVE SENSING | `0xFA545F` |

The **priority order is not the bit order**: clock, then active sensing, then
start, continue, stop. Timing clock first is the right choice — it is the one
message whose jitter is audible.

When no bit is set, it pulls a byte from the output queue through the prom_b
routine at `0xF41DF0` (`0xFFFF` means empty). When nothing at all is left it
writes `0xFD` to `(0x77)`; the work poster at `0xFA590F` writes `0xDD` to the
same byte, so `(0x77)` is a one-byte mailbox to the foreground, not a register.

**This names an idiom that appears all over the timer handlers.**
`or (0xA0),n` followed by `call 0xF40724` (a thunk for `0xFA590F`) is
*"queue this MIDI real-time byte and wake the sender"*. Sites converted so far:

| site | bit | message |
|---|---|---|
| `INTT1_Tick` `0xF82D3F` | 4 | ACTIVE SENSING |
| `INTT1_Tick` `0xF82D92` | 3 | STOP |
| `INTT1_Tick` `0xF82DC0` | 0 | TIMING CLOCK |
| sequencer tick `0xF82F7D` | 1 | START |

## Active Sensing, both directions

* **Send.** `INTT1_Tick` runs a counter at `(0x9D)` from 0 to `0x86` and requests
  bit 4 on the wrap — **every 135 timer-1 ticks**.
* **Receive timeout.** `MIDI_RX_Byte` zeroes `(0x9C)` on *every* incoming byte
  (`0xFA54AE`), and `0xFA5509` sets bit 7 of `(0x9E)` when a `0xFE` arrives.
  While that bit is set, `INTT1_Tick` counts `(0x9C)` up and gives up at `0xA5` —
  **166 ticks** — clearing bit 7 and setting bit 5 of `(0x9E)`.

At the 488.28 Hz that `notes/FINDINGS-system-clock.md` derives for timer 1, that
is **send every 277 ms, give up after 340 ms** — one either side of MIDI 1.0's
300 ms active-sensing rule, which is what a correct implementation looks like.

⚠ **This is a consistency check, not a fourth lever on fc.** The window is wide.
At 24 MHz the same counts give 323 ms and 397 ms; the *timeout* would still be on
the right side of 300 ms, only the send interval would not. Treat it as
corroboration of the note that already settles fc, not as a new derivation. That
note's lever B — `(0xA1)`, the gap between incoming `0xF8` bytes, converted to
TREG5 at `0xFA553E` — is the strong argument and it is already written up there.

## The receive side's three paths

`MIDI_RX_Byte` saves all seven 32-bit registers and splits on the byte:

| byte | path | target |
|---|---|---|
| bit 7 clear | data byte | `0xFA5763` |
| `0x80`-`0xF7` | status byte | inline: becomes running status in `(0x9A)`; `0xF7` (END OF EXCLUSIVE) closes an in-progress SysEx through `0xF41E3C` |
| `0xF8`-`0xFF` | System Real Time | `0xFA5504` |

Before any of that it tests `SC0CR & 0x1C`; if any of those three bits is set it
takes `MIDI_RX_ErrorReset` (`0xFA5418`) instead, which reads `SC0BUF` to clear
the condition, drops running status, sets bit 3 of `(0x9E)`, bumps a 16-bit error
counter at `(0x0931)` and returns — **the parser never sees a byte that arrived
with an error**.

`(0xA9)` is the SysEx state byte: bit 0 armed, bit 1 in-message, bit 5 seen.
⚠ Those three meanings are read off this one routine's branches and are not
corroborated elsewhere yet.

## Not yet converted

* `0xFA5504` — the System Real Time receive handler. Its head is converted in
  spirit only: `0xFE` sets the sensing flag, `0xFD` and above are ignored, `0xF8`
  drives the tempo tracker at `0xFA553E`, and `0xFA5562` onward drives the
  transport state bytes `(0x94)`/`(0x95)`/`(0x96)` that `INTT1_Tick` also writes.
* `0xFA5763` — the data-byte path (the actual MIDI parser).
* `0xFA5884` / `0xFA58A1` — called at the top and bottom of every receive.
* `0xFA58F2` — the runtime UART re-init that overwrites `BR0CR`; already
  described in the RESET block's comment and in the clock note.
