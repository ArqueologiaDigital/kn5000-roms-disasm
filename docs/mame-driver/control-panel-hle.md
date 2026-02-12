# Control Panel HLE (kn5000_cpanel.cpp)

High-level emulation of the two Mitsubishi M37471M2196S MCUs on the control panel PCB. ROM not dumped, so HLE is the only option.

## Serial Protocol

Synchronous serial, CPU is master (drives SCLK). Protocol uses 2-byte command sequences.

### Command Format

Byte 0 (command):
- `0x00-0x0C` — Right panel LED control
- `0x1D-0x1F` — Initialization commands
- `0x20` — Query left panel
- `0x2B` — Init left panel button state
- `0xC0-0xC8` — Left panel LED control
- `0xDD` — Initialization command
- `0xE0` — Query right panel
- `0xEB` — Init right panel button state

Byte 1 (parameter):
- For queries: segment number (0x01-0x0A) or status (0x0B, 0x10)
- For LED commands: bitmap of LEDs to set

### Query Protocol (0x20/0xE0)

To read buttons from a panel segment:

1. Send 2-byte command: `[0x20/0xE0, segment]`
2. Send 2 dummy bytes (`0xFF`) to clock in response
3. Response arrives during dummy bytes: byte 0 = header, byte 1 = button bitmap

Each panel has 11 segments (SEG0-SEG10), each with 8 buttons = 88 buttons per panel.

### Response Packet Format

Byte 0 header bits:
- Bits 7-6: Not used for button packets
- Bit 6: Panel (0 = right, 1 = left)
- Bits 5-3: Packet type (000/001 = button state)
- Bits 3-0: Segment number

Byte 1: 8-bit button bitmap (one bit per button)

### LED Commands

| Command | Panel | LED Row |
|---------|-------|---------|
| `0x00-0x04` | Right | Effects, sound groups, part select rows |
| `0x08` | Right | Sequencer |
| `0x0A-0x0C` | Right | Menu, octave, tempo |
| `0xC0-0xC4` | Right | Composer, arranger, stylist, rhythm |
| `0xC8` | Left | Fill-in/intro/ending |

The parameter byte is a bitmap of which LEDs in the row to turn on.

### Dummy Byte Filtering

The HLE filters `0xFF` bytes received at command position 0 (cmd_index == 0). These are dummy/idle bytes that should not be interpreted as commands.

## Button Input Ports

22 input ports defined in kn5000.cpp:

| Port Group | Ports | Description |
|-----------|-------|-------------|
| CPL_SEG0-10 | 11 | Left panel (rhythm, variations, sequences, memory, menu) |
| CPR_SEG0-10 | 11 | Right panel (effects, sounds, part select, conductor) |

### Commonly Used Segments for Another World

| Segment | Port Name | Notable Buttons |
|---------|-----------|-----------------|
| CPR_SEG4 | Right panel seg 4 | Bit 1: Part Select RIGHT 2, Bit 4: CONDUCTOR LEFT, Bit 5: CONDUCTOR RIGHT 2, Bit 6: CONDUCTOR RIGHT 1 |
| CPL_SEG4 | Left panel seg 4 | Bit 3: VARIATION 4 |

## Internal State

- `m_cpl_ports[11]` / `m_cpr_ports[11]` — ioport_port pointers to input ports
- `m_cpl_leds` / `m_cpr_leds` — LED output finders
- `m_last_button_state[2][11]` — Previous button state for change detection
- `m_tx_queue` — Outgoing byte queue for pipelined responses
- `m_cmd_index` — Tracks position within 2-byte command (0 or 1)

## Serial Timing Details

- Rising edge: Sample RXD, shift into RX shift register
- Falling edge: Output TXD, shift out next bit
- 8 bits per byte, MSB-first (actually LSB-first based on `>>= 1` shifts)
- First byte of transmission pre-outputs bit 0 immediately on scNbuf_w
- `m_tx_skip_first_falling` flag prevents double-outputting bit 0

### Idle Transition

When TX completes and no more bytes queued, TXD returns to idle state. The HLE does NOT drive TXD high on idle — this was a bug fix (driving TXD high corrupted the last bit of the final byte).
