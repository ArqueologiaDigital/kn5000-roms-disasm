# MAME KN5000 Driver Architecture

Reference documentation summarizing the MAME KN5000 driver source code, derived from reading the actual implementation files. This saves time when working on firmware or driver changes by providing quick lookup of register mappings, wiring, and known quirks.

## Source Files

| File | Description | Details |
|------|-------------|---------|
| `mame_driver/src/mame/matsushita/kn5000.cpp` | Machine config, memory maps, device wiring | [machine-config.md](machine-config.md) |
| `mame_driver/src/mame/matsushita/kn5000_cpanel.cpp` | Control panel HLE (buttons + LEDs) | [control-panel-hle.md](control-panel-hle.md) |
| `mame_driver/src/devices/cpu/tlcs900/tmp94c241.cpp` | CPU device: timers, interrupts, SFR map | [cpu-peripherals.md](cpu-peripherals.md) |
| `mame_driver/src/devices/cpu/tlcs900/tmp94c241_serial.cpp` | Serial channels (SC0/SC1) | [serial-channels.md](serial-channels.md) |
| `mame_driver/src/devices/cpu/tlcs900/tmp94c241.h` | CPU header: port/interrupt enums, members | [cpu-peripherals.md](cpu-peripherals.md) |

## Quick Reference

### Memory Map (Main CPU)

| Address Range | Size | Device |
|--------------|------|--------|
| `0x000000-0x0FFFFF` | 1 MB | DRAM (NVRAM) @ IC9/IC10 |
| `0x140000-0x14FFFF` | 64 KB | Inter-CPU latches @ IC22/IC23 |
| `0x1703B0-0x1703DF` | 48 B | MN89304 VGA I/O registers |
| `0x1A0000-0x1DFFFF` | 512 KB | VGA VRAM (framebuffer) |
| `0x1E0000-0x1FFFFF` | 128 KB | Backup SRAM @ IC21 |
| `0x300000-0x3FFFFF` | 1 MB | Custom data flash @ IC19 |
| `0x400000-0x7FFFFF` | 4 MB | Rhythm data ROM @ IC14 |
| `0x800000-0x9FFFFF` | 2 MB | Table data ROM @ IC1/IC3 (mirrored to 0xA00000) |
| `0xE00000-0xFFFFFF` | 2 MB | Program ROM @ IC4/IC6 |

### Serial Wiring (SC1 to Control Panel)

```
CPU SC1 TXD  ──→  cpanel RXD
CPU SC1 SCLK ──→  cpanel SIOCLK
cpanel TXD   ──→  CPU SC1 RXD
```

CPU is master (drives SCLK). Synchronous I/O mode. 250 kHz baud rate.

### Known MAME Quirks

1. **Prescaler divisions differ from datasheet** — see [cpu-peripherals.md](cpu-peripherals.md#prescaler-quirk)
2. **Timer 1 fires TO2_trigger on BOTH serial channels** — see [serial-channels.md](serial-channels.md#to2-trigger-pitfall)
3. **DEC instruction doesn't set flags correctly** — use DJNZ instead
4. **4-bit palette DAC** (MN89304), not 6-bit VGA standard
