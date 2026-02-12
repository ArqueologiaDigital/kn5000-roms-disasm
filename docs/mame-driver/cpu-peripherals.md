# CPU Peripherals (tmp94c241.cpp / tmp94c241.h)

## SFR Address Map

### Port I/O (0x00-0x6A)

Each port has up to three registers: Data, Control (CR), Function (FC).

| Address | Register | Description |
|---------|----------|-------------|
| 0x00 | PORT_0 | Data bus D0-D7 |
| 0x04 | PORT_1 | Data bus D8-D15 |
| 0x08 | PORT_2 | Data bus D16-D23 |
| 0x0C | PORT_3 | Data bus D24-D31 |
| 0x10 | PORT_4 | Address bus A0-A7 |
| 0x14 | PORT_5 | Address bus A8-A15 |
| 0x18 | PORT_6 | Address bus A16-A23 |
| 0x1C | PORT_7 | External memory/bus signals |
| 0x20 | PORT_8 | Chip-select signals |
| 0x28 | PORT_A | DRAM channel 0 |
| 0x2C | PORT_B | DRAM channel 1 |
| 0x30 | PORT_C | 8/16-bit timer outputs |
| 0x34 | PORT_D | 16-bit timer I/O + interrupt |
| 0x38 | PORT_E | 8/16-bit timer + interrupt |
| 0x3C | PORT_F | Serial interface functions |
| 0x40 | PORT_G | A/D converter (input only) |
| 0x44 | PORT_H | INT0 + micro-DMA |
| 0x68 | PORT_Z | General purpose |

### Timer Control (0x80-0xC9)

| Address | Register | Description |
|---------|----------|-------------|
| 0x80 | T8RUN | 8-bit timer run bits (bits 0-3 = T0-T3) |
| 0x81 | TRDC | Timer redirect |
| 0x82 | T02FFCR | Timer 0/1 flip-flop control |
| 0x84 | T01MOD | Timer 0/1 mode |
| 0x85 | T23MOD | Timer 2/3 mode |
| 0x88 | TREG0 | Timer 0 match register |
| 0x89 | TREG1 | Timer 1 match register |
| 0x8A | TREG2 | Timer 2 match register |
| 0x8B | TREG3 | Timer 3 match register |
| 0x9E | T16RUN | 16-bit timer run + prescaler enable (bit 7 = PRRUN) |

### Serial (0xD0-0xD7)

| Address | Register | Channel | Description |
|---------|----------|---------|-------------|
| 0xD0 | SC0BUF | 0 | Data buffer (R: RX, W: TX) |
| 0xD1 | SC0CR | 0 | Control (bit 0: RXE, bit 1: IOC) |
| 0xD2 | SC0MOD | 0 | Mode (bits 1-0: clock source) |
| 0xD3 | BR0CR | 0 | Baud rate |
| 0xD4 | SC1BUF | 1 | Data buffer |
| 0xD5 | SC1CR | 1 | Control |
| 0xD6 | SC1MOD | 1 | Mode |
| 0xD7 | BR1CR | 1 | Baud rate |

### Interrupts (0xE0-0xF8)

| Address | Register | Description |
|---------|----------|-------------|
| 0xE0 | INTE45 | External INT4/INT5 |
| 0xE1 | INTE67 | External INT6/INT7 |
| 0xE2 | INTE89 | External INT8/INT9 |
| 0xE3 | INTEAB | External INTA/INTB |
| 0xE4 | INTET01 | Timer 0/1 |
| 0xE5 | INTET23 | Timer 2/3 |
| 0xE6 | INTET45 | Timer 4/5 |
| 0xE7 | INTET67 | Timer 6/7 |
| 0xE8 | INTET89 | Timer 8/9 |
| 0xE9 | INTETAB | Timer A/B |
| 0xEA | INTES0 | Serial channel 0 (RX: bit 3, TX: bit 7) |
| 0xEB | INTES1 | Serial channel 1 (RX: bit 3, TX: bit 7) |
| 0xEC-0xEF | INTETC01-67 | Micro-DMA completion |
| 0xF0 | INTE0AD | INT0 / A/D converter |
| 0xF6 | IIMC | Interrupt input mode control |
| 0xF7 | INTNMWDT | NMI / Watchdog |
| 0xF8 | INTCLR | Interrupt clear (write DMA vector to clear flag) |

### Memory Controller (0x140-0x157)

| Address | Register | Description |
|---------|----------|-------------|
| 0x140-0x14B | B0CSL/H - B5CSL/H | Block chip-select config |
| 0x14C-0x151 | MAMR0-5 | Address mask registers |
| 0x152-0x157 | MSAR0-5 | Start address registers |

## Timer Architecture

### Prescaler

The prescaler divides the CPU clock into four output taps:

| Tap Name | MAME Division | Datasheet Division | At 16 MHz |
|----------|--------------|-------------------|-----------|
| T1 | /8 | /4 | 2 MHz |
| T4 | /32 | /16 | 500 kHz |
| T16 | /128 | /64 | 125 kHz |
| T256 | /2048 | /1024 | 7.8 kHz |

<a id="prescaler-quirk"></a>
**MAME quirk**: Prescaler divisions differ from the TMP94C241F datasheet. All timer calculations for MAME must use the MAME values.

**Prescaler enable**: Requires `T16RUN` bit 7 (PRRUN) to be set. `T8RUN` alone is NOT sufficient — without `LD (T16RUN), 080h`, the prescaler never runs and timers never count.

### T01MOD Register Layout (MAME interpretation)

| Bits | Field | Description |
|------|-------|-------------|
| 1:0 | T0CLK | Timer 0 clock source |
| 3:2 | T1CLK | Timer 1 clock source |
| 7:6 | Mode | 00 = two 8-bit, 01 = 16-bit cascade |

**MAME quirk**: This differs from the SFR datasheet which says bit 0 = PRRUN, bits 2:1 = T0CLK. Use the MAME interpretation since that's what the emulator implements.

### T0CLK Source Selection

| Value | Source |
|-------|--------|
| 00 | Timer A underflow |
| 01 | Prescaler T1 output |
| 10 | Prescaler T4 output |
| 11 | Prescaler T16 output |

### Timer Cascade (T0/T1)

When T01MOD bits 7:6 = 00 (8-bit mode): T0 and T1 are independent 8-bit timers.
When T01MOD bits 7:6 = 01 (cascade): T0 counts, T1 increments when T0 matches.

### TO2 Trigger

When Timer 1 matches (overflows), `tmp94c241.cpp` fires `TO2_trigger()` on **both** serial channels (line 1200-1203):

```cpp
if (timer_index == 1)
{
    m_serial[0]->TO2_trigger(match);
    m_serial[1]->TO2_trigger(match);
}
```

This drives the serial clock when SCxMOD bits 1:0 = 00 (TO2 trigger clock source). See [serial-channels.md](serial-channels.md#to2-trigger-pitfall) for the pitfall this creates.

## Interrupt Controller

### Priority Resolution

- IRQ priorities are set in the upper 3 bits of each INTExx register
- Priority 0 = non-maskable (NMI)
- Priority 1-7 = maskable (higher number = lower priority)
- SR bits 4-6 set the current interrupt mask level

### INTCLR Mechanism

Writing a DMA start vector value to INTCLR (0xF8) clears the corresponding interrupt flag. The mapping is defined in `irq_vector_map`:

| INTCLR Value | Register | Bit Cleared | Interrupt |
|-------------|----------|-------------|-----------|
| 0x0A | INTE45 | 0x08 | INT4 |
| 0x0B | INTE45 | 0x80 | INT5 |
| 0x22 | INTES1 | 0x08 | INTRX1 |
| 0x23 | INTES1 | 0x80 | INTTX1 |

(This is a partial list — see `tmp94c241.cpp` lines 20-63 for the complete mapping.)

## HDMA (Cycle-Steal DMA)

- 4 channels with m_dma_vector[0-3] start triggers
- Supports byte/word/long transfers
- Source/destination can be fixed, incrementing, or decrementing
- On completion, sets INTTC interrupt and clears DMA vector
- Processed before regular instruction execution

## Known MAME Bugs

- **DEC instruction flag setting**: `DEC 1, rr; JP NZ` doesn't work because DEC may not set flags correctly. Use `DJNZ rr, label` instead.
- **SLA/INC encoding**: Only supports values 1, 2, 4, 8 (2-bit field). ASL assembler accepts any value but encodes raw bits. MAME treats the 3-bit field literally.
