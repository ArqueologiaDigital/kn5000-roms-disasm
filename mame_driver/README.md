# MAME Driver Source Files

This directory contains a subset of MAME source files for the KN5000 driver. These are **reference copies** used for sketching driver improvements - NOT the complete MAME codebase.

## Purpose

These files serve as a workspace for:
1. Planning control panel HLE (High Level Emulation) improvements
2. Designing protocol implementations based on reverse engineering findings
3. Drafting code changes before submitting to upstream MAME

## Files

| File | Description |
|------|-------------|
| `src/mame/matsushita/kn5000.cpp` | Main KN5000 driver - machine configuration, address maps, ROM definitions |
| `src/mame/matsushita/kn5000_cpanel.cpp` | Control panel HLE device implementation |
| `src/mame/matsushita/kn5000_cpanel.h` | Control panel HLE device header |

## KN5000 Driver Architecture

The MAME driver emulates:

- **Main CPU**: TMP94C241F (TLCS-900/H2) at 20 MHz
- **Sub CPU**: Second TMP94C241F
- **Control Panel**: HLE device (no MCU ROM dumps available)
- **Memory**: 16MB address space with ROM, RAM, and I/O regions
- **Serial**: UART communication between main CPU and control panel

### Control Panel HLE (`kn5000_cpanel_device`)

The control panel uses High Level Emulation because the Mitsubishi M37471M2196S MCUs do not have ROM dumps available. The HLE device:

- Implements serial communication via shift registers (RX and TX)
- Uses a timer-driven baud rate generator (31,250 Hz default during init, 250 kHz normal operation)
- Provides callbacks for TXD (transmit data) and SCLK (serial clock) signals
- Sends initial command 0xE2 on startup (matches firmware expectations)

### Communication Protocol

The main CPU communicates with the control panel via serial at address `0x120000` (latch registers). The protocol uses:

- **Commands**: E1, E2, E3, 00-1F (see control-panel-protocol.md in kn5000-docs)
- **Responses**: Button states, encoder values, acknowledgments
- **Packet types**: Single-byte, multi-byte, and special encoder packets

## Workflow

1. **Study**: Analyze reverse engineering findings from the disassembly
2. **Design**: Draft improvements to HLE based on protocol understanding
3. **Implement**: Update these reference files with proposed changes
4. **Test**: Build MAME with the modified driver and test
5. **Submit**: Create pull request to upstream MAME repository

## Related Documentation

- `../kn5000-docs/control-panel-protocol.md` - Complete protocol analysis
- `../kn5000-docs/memory-map.md` - Hardware register addresses
- `../maincpu/kn5000_v10_program.asm` - Main CPU disassembly (control panel routines at FC4xxx)

## License

These files are from MAME and are licensed under GPL-2.0-or-later. See individual file headers for copyright information.
