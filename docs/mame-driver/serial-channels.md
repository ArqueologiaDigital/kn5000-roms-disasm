# Serial Channels (tmp94c241_serial.cpp)

Two independent synchronous serial channels (SC0, SC1), implemented as sub-devices of the TMP94C241.

## Clock Source Selection (SCxMOD bits 1:0)

| Value | Source | Status |
|-------|--------|--------|
| 00 | TO2 trigger (Timer 1 match) | Implemented |
| 01 | Baud rate generator | Implemented |
| 10 | Internal clock phi1 | Not implemented |
| 11 | External SCLK | Not implemented |

## Serial Control Register (SCxCR)

| Bit | Name | Description |
|-----|------|-------------|
| 0 | RXE | RX enable |
| 1 | IOC | 0 = SCLK output (master), 1 = SCLK input (slave) |

Writing to SCxCR resets the RX clock counter to 8 (byte boundary sync).

## Baud Rate Register (BRxCR)

| Bits | Field | Description |
|------|-------|-------------|
| 3:0 | Divisor | Clock divider (0 = timer disabled) |
| 5:4 | Clock source | 00=T1, 01=T4, 10=T16, 11=T256 |

Formula: `Hz = (fCPU >> (((bits54 + 1) * 2))) / divisor`

Example: BR1CR = 0x14 at 16 MHz:
- Clock source = 01 (T4), shift = (1+1)*2 = 4
- Divisor = 4
- Hz = (16000000 >> 4) / 4 = 250,000 Hz

## Synchronous Serial Protocol

### Bit Timing

- **Rising edge**: Sample RXD, shift into RX shift register (LSB first)
- **Falling edge**: Output TXD, shift out from TX shift register (LSB first)
- 8 bits per byte

### TX Sequence

1. Write byte to SCxBUF → loads TX shift register, sets tx_clock_count = 7
2. Bit 0 is pre-output **immediately** via TXD callback
3. `m_tx_skip_first_falling` flag set if clock is currently HIGH (prevents double-output)
4. Subsequent falling edges: shift right, output next bit, decrement counter
5. After 8 bits sent: set INTTX flag in INTESx register

### RX Sequence

1. Each rising edge: shift RX register right, OR in sampled RXD bit at position 7
2. Decrement rx_clock_count
3. After 8 bits received: store to rx_buffer, set INTRX flag, reset counter to 8

### Interrupt Flags

| Flag | Register | Bit | Set When |
|------|----------|-----|----------|
| INTRX0 | INTES0 | 0x08 | SC0 byte received |
| INTTX0 | INTES0 | 0x80 | SC0 byte transmitted |
| INTRX1 | INTES1 | 0x08 | SC1 byte received |
| INTTX1 | INTES1 | 0x80 | SC1 byte transmitted |

Clear INTRX1 by writing 0x22 to INTCLR. Clear INTTX1 by writing 0x23 to INTCLR.

## Baud Rate Generator Timer

The serial device has its own internal timer (`m_timer`) that drives `sioclk()` when the baud rate generator is active. This is independent of the TO2 trigger mechanism.

The timer toggles sioclk state each tick, creating a square wave at the configured baud rate. It only runs when:
- `m_hz > 0` (baud rate configured)
- TX or RX is in progress (`m_tx_clock_count > 0` or `m_rx_clock_count != 8`)
- Port F function bit is set for the channel (bit 2 for SC0, bit 6 for SC1)

## Port F Function Bits

Serial channels share Port F with other functions. The serial clock only operates when the corresponding Port F function bit is enabled:

| Channel | Function Bit | PORT_F Mask |
|---------|-------------|-------------|
| SC0 | Bit 2 | 0x04 |
| SC1 | Bit 6 | 0x40 |

Firmware sets `PFFC = 0x73` to enable both channels: `0x73 = 0100_0011` → SC1 bit 6 set, SC0 bit 2 not set (but bits 0-1 for SC0 TXD/RXD are set).

<a id="to2-trigger-pitfall"></a>
## TO2 Trigger Pitfall

**Problem**: Timer 1 fires `TO2_trigger()` on both serial channels whenever it matches. If SCxMOD bits 1:0 = 00 (TO2 trigger selected) AND IOC = 0 (master mode), these trigger calls drive sioclk, injecting phantom clock edges.

**Impact**: If Timer 0/1 is used as a system tick (e.g., for game frame timing), Timer 1 overflows at high frequency (e.g., 200 kHz), injecting hundreds of clock edges per millisecond into the serial channel. This corrupts byte framing, causing garbled bytes that get interpreted as LED commands or wrong button data.

**Solution**: Set SCxMOD bits 1:0 = 01 (baud rate generator) instead of 00 (TO2 trigger) when using the baud rate generator for serial timing. This prevents TO2_trigger from driving sioclk.

**Firmware init**:
```asm
LD (SC1MOD), 001h    ; Clock source = baud rate generator (NOT 000h = TO2 trigger!)
LD (BR1CR), 014h     ; 250 kHz
LD (SC1CR), 001h     ; RXE=1, IOC=0 (master)
```

## RX/TX Cross-Coupling

When master and slave are connected bidirectionally, a timing issue exists:

On rising edge, the master samples RXD **before** forwarding the clock to the slave. This is critical because if the slave's rising-edge handler completes an RX byte and calls `send_byte()`, it would pre-output bit 0 via its TXD callback — changing the master's RXD before sampling.

The code captures `rxd_sample` before calling `m_sclk_out_cb(state)` to prevent this race.
