# The KN5000 control-panel serial link (boot-time driver)

Status: specified from the disassembly, with the parts needing a real instrument named separately.
Everything here is read out of `table_data/boot_cpserial.s` (ROM 0x9FEC6E-0x9FF228),
`boot_cpserial_isr.s` (0x9FF229-0x9FF2F1) and `boot_cpserial_states.s` (0x9FF2F2-0x9FFB2E).

⚠ SCOPE. This is the **first-stage bootloader's** driver. It is independent of the runtime
`CPanel_*` protocol stack in the program ROM, which is a separate implementation of a link to the
same hardware. Do not assume a detail here holds there without checking.

## Physical layer

Serial channel 1 of the TMP94C241, programmed by `BootSerial_FullInit`:

    SC1MOD (I/O 0xD6) = 0x00     channel-1 mode
    BR1CR  (I/O 0xD7) = 0x14     baud rate control
    SC1CR  (I/O 0xD5) = 0x01     serial control
    TAMOD  (I/O 0xC8) |= 0x10, &= ~0x08     baud clock source = timer A
    INTEAB (I/O 0xE3) = 0x07     enable INTA
    INTES1 (I/O 0xEB) = 0xFF     channel-1 RX + TX interrupts, maximum priority

Port F/E pin functions are programmed alongside, with shadows of PFCR/PFFC kept at RAM 0x0F66 and
0x0F67 because those registers are write-only.

**Decode the three SC1 values against the TMP94C241 datasheet before quoting a bit rate.** They are
recorded here as the literals the firmware writes; this document deliberately does not translate
them into a baud figure it cannot verify.

## Interrupt roles

    INTA     external interrupt A. The PANEL pulls this line, both to OPEN a receive
             transfer and to PACE one while it is in progress.
    INTTX1   channel-1 transmit buffer empty -- drives the transmit states
    INTRX1   channel-1 receive buffer full  -- drives the receive states

All three epilogues write the same three values to INTCLR: 0x12, 0x22, 0x23. Those are interrupt
**vector numbers**, not addresses (numbering reconstructed in `v142/subcpu/subcpu_vectors.s`:
vector 34 = INTRX1, 35 = INTTX1, 10..19 = INT0/INT3..INTB, putting INTA at 18 = 0x12). **So
whichever handler runs discards the other two's pending requests as well** -- an emulator that
models INTCLR per-source will not reproduce this link's behaviour.

## State machine

One byte at RAM 0x0F62 holds the state, stored as a RAW DISPATCH-TABLE OFFSET in steps of 4
(0x00..0x28) and advanced with `inc 4` / `dec 4`, so no scaling happens before the lookup.
`BootSerial_StateDispatchTable` is 11 `.long` entries:

    0x00  Abort / idle
    0x04  TxLineRequest        request the line
    0x08  TxFirstByte          first byte of a frame
    0x0C  TxByteGap            inter-byte gap
    0x10  TxNextByte           subsequent bytes
    0x14  TxTail               frame tail
    0x18  TxFrameDone          frame complete
    0x1C  Abort
    0x20  RxFirstByte          first byte of an inbound frame
    0x24  RxNextByte           subsequent bytes
    0x28  Abort

Transmit states return through `BootSerial_TxIsrEpilogue`, receive states through
`BootSerial_RxIsrEpilogue`. Three of the eleven slots are the same abort handler.

## Framing

The FIRST BYTE of a frame determines its length, and the countdown lives at RAM 0x0F63:

    plain frame            2 bytes
    variable-length run    (first_byte & 0x0F) + 3 bytes

## Link state and buffers

    0x0F62   state byte (raw table offset, above)
    0x0F63   per-frame byte countdown
    0x0F64   link flags: bit0 RX active, bit1 TX pending, bit2 RX busy,
             bit4 decode-collapse sentinel
    0x0F6A   status / abort bits
    0x0F79   RX serial ring, 0x5C bytes; tail at 0x0F75, head at 0x0F77
    0x0FD9   TX serial ring, 0x3C bytes; send index at 0x0FD5, pending count at 0x0FD7

Above the byte rings sit two transfer-control blocks -- RX at 0x988A, TX at 0x9914 -- each a
0x80-byte PACKET ring at the base address with three words below it:

    base-8   tail word
    base-4   head word
    base-2   FREE-SLOT COUNT, initialised to the ring size 0x0080

The packet parser and encoder step the free-slot count as they fill and drain, so it is part of
the protocol's flow control and not a debugging aid.

## Startup

`BootSerial_FullInit` resets both transfer-control blocks, programs the pins and SC1, enables the
interrupts, clears the link state bytes, sends the opening frame **`0x1F 0xDA`**, and falls into
`BootSerial_HandshakeSequence`, which sends four further frames.

## What an implementer could and could not do with this

**Could**: write a device model that speaks this link -- the register programming, the interrupt
semantics including the shared INTCLR behaviour, the eleven states and their transitions, the
frame-length rule, the ring geometry and the handshake are all here.

**Could not, without the real instrument**: know what the PANEL puts on the wire in response.
That is where this project's open defect lives -- the data-wheel steady state is unresolved, and
the `kn5000-30` fix that shipped for it was subsequently falsified. No amount of reading this ROM
settles the panel's own behaviour; that needs a logic analyser on a real KN5000. The distinction
matters, and was blurred in this project's own notes until 2026-08-21: the KN5000 side of the
protocol is specifiable from the firmware, the panel side is not.
