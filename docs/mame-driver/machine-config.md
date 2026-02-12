# Machine Config (kn5000.cpp)

## CPUs

| CPU | Chip | IC | Clock | Address Bus |
|-----|------|----|-------|-------------|
| Main | TMP94C241 | IC5 | 16 MHz (2 x 8 MHz XTAL) | 32-bit |
| Sub | TMP94C241 | IC27 | 20 MHz (2 x 10 MHz XTAL) | 8-bit |

## Main CPU Port Mappings

| Port | Bit | Dir | Signal | Notes |
|------|-----|-----|--------|-------|
| PORT_7 | 5 | IN | ~BUSRQ | Hardwired to 1 (always ready) |
| PORT_A | 0 | OUT | Sub CPU ~RESET | Active low |
| PORT_C | 0 | IN | CN11 check terminal | Self-test switch |
| PORT_C | 1 | OUT | LED | Status LED |
| PORT_D | 0 | OUT | FDCRST | Floppy reset |
| PORT_D | 6 | IN | FD.I/O | Floppy I/O |
| PORT_E | 0 | IN | +5V | Constant high |
| PORT_E | 2 | IN | HDDRDY | Hard disk ready |
| PORT_F | 6 | IN | Constant 1 | |
| PORT_H | — | IN | AREA | Regional selection |
| PORT_Z | 0-1 | OUT | MSTAT0/1 | Status to sub CPU |
| PORT_Z | 2-3 | IN | SSTAT0/1 | Status from sub CPU |
| PORT_Z | 4-7 | IN | COM select | MIDI/MAC/PC1/PC2 |

## Main CPU Interrupts

| IRQ | Source | Notes |
|-----|--------|-------|
| INT4 | FDC INTRQ | Floppy interrupt request |
| INT5 | FDC DRQ | Floppy DMA request |
| INT6/7 | FDC H/D, I/O | Empty handlers |
| INT9 | Extension IRQ | HDAE5000 expansion |
| INTA | cpanel SCLK edge | Not used in current firmware |

## Sub CPU Port Mappings

| Port | Bit | Dir | Signal |
|------|-----|-----|--------|
| PORT_C | 0 | IN | CN12 check terminal |
| PORT_C | 1 | OUT | LED |
| PORT_D | 0-1 | OUT | SSTAT0/1 |
| PORT_D | 2,4 | IN | MSTAT0/1 |

## VGA (MN89304)

- IC206, crystal 40 MHz
- Screen: 424x262 total, 320x240 active, 60 Hz
- VRAM: 512 KB at `0x1A0000`, linear 8bpp palette mode
- I/O: `0x1703B0-0x1703DF` (standard VGA register offsets)
- **4-bit palette DAC** — uses `pal4bit()` conversion, NOT standard 6-bit VGA
- Framebuffer offset has 3-bit left shift (divide by 8)

## FDC (UPD72067)

- IC208, clocked at 32 MHz
- INTRQ → INT4, DRQ → INT5
- FDCRST tied to main CPU PORT_D bit 0

## Inter-CPU Communication

Two generic 8-bit latches (IC22, IC23):
- Main CPU writes `0x140000` → Sub CPU reads `0x120000`
- Sub CPU writes `0x120000` → Main CPU reads `0x140000`

## Serial Wiring

| CPU Port | Direction | Connected To |
|----------|-----------|--------------|
| SC0 RXD | IN | MIDI port input |
| SC0 TXD | OUT | Not connected (commented out) |
| SC1 TXD | OUT | cpanel RXD |
| SC1 SCLK | OUT | cpanel SIOCLK |
| SC1 RXD | IN | cpanel TXD |

## NVRAM

- NVRAM1 @ `0x000000` (1 MB DRAM with battery backup)
- NVRAM2 @ `0x1E0000` (SRAM with battery backup, contains error messages)

## Extension Connector

- KN5000_EXTENSION device
- IRQ → INT9
- Shares main CPU address space (can override program logic)
