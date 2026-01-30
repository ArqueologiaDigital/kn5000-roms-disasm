# HD-TechManager5000

This directory contains the HD-TechManager5000 Windows software and documentation
for the HD-AE5000 hard disk expansion for the Technics KN5000 keyboard.

## Source

Downloaded from the Internet Archive:
https://archive.org/details/technics-kn5000-system-update-disks

## Files

### Installer Files (Windows 3.1 Self-Extracting Archives)

| File | Description |
|------|-------------|
| `HDTMD120.EXE` | HD-TechManager Demo Disk 1/2 |
| `HDTMD120.W02` | HD-TechManager Demo Disk 2/2 |
| `setup.EXE` | HD-TechManager Setup Disk 1/2 |
| `setup.W02` | HD-TechManager Setup Disk 2/2 |
| `CUSTDATA.INI` | Registration data file |

### Documentation

| File | Description |
|------|-------------|
| `hd-tm5000manual.pdf` | HD-TechManager5000 User Manual |
| `hd-ae5000manual-e.pdf` | HD-AE5000 User Manual (English) |
| `hd-ae5000manual-e-2.pdf` | HD-AE5000 User Manual (alternate) |
| `HD-AE5000 leaflet e&f.pdf` | HD-AE5000 Marketing Leaflet (English/French) |
| `hd-ae5000comparison.pdf` | HD-AE5000 Feature Comparison |
| `KN5000.pdf` | KN5000 Overview Document |

### Parallel Port DLL (Key for Reverse Engineering)

| File | Description |
|------|-------------|
| `ppkn50.dll` | **Parallel Port KN5000 DLL** - PE32 Windows DLL containing the PC-side protocol implementation |

### Other

| File | Description |
|------|-------------|
| `hd-ae5000installed.jpg` | Photo of installed HD-AE5000 |
| `intro.mid` | Demo MIDI file |

## ppkn50.dll - Parallel Port Protocol DLL

The `ppkn50.dll` is a 32-bit Windows DLL (PE32, Windows 95/NT compatible) that implements
the PC side of the parallel port communication protocol with the HDAE5000.

### Exported Functions

| Function | Purpose |
|----------|---------|
| `InitializeTheDllPP50` | Initialize the DLL |
| `OpenThePortNumberPP50` | Open/select parallel port |
| `CloseThePortPP50` | Close the parallel port |
| `TestTheKNPPPP50` | Test connection to KN5000 |
| `TestParallelModusPP50` | Test parallel port mode |
| `ReadFsbFromKnHdToKnMemPP50` | Read FSB from HD to KN memory |
| `WriteFsbFromKnMemToKnHd...` | Write FSB from KN memory to HD |
| `SendFsbFromKnMemToPCPP50` | Transfer FSB from KN to PC |
| `SendFsbFromPCToKnMemPP50` | Transfer FSB from PC to KN |
| `LoadFileFromKnHdToKnMemPP50` | Load file from HD to KN memory |
| `LoadFileFromKnHdToPCPP50` | Load file from HD to PC |
| `LoadFileFromKnHdDirectToPCPP50` | Direct file transfer HD→PC |
| `SaveFileFromKNMemToKNHdPP50` | Save file from KN memory to HD |
| `SaveFileFromPCDirectToKNHdPP50` | Direct file transfer PC→HD |
| `SavePCMemDirectToKNHdPP50` | Save PC memory to HD |
| `SendFileFromPCToKNHDPP50` | Send file from PC to KN HD |
| `SendFileFromPCToKNMemPP50` | Send file from PC to KN memory |
| `SendSeveralFileDirectToKNHDPP50` | Batch file transfer to HD |
| `DeleteFileOnKnHdPP50` | Delete file from HD |
| `FormatTheKn50HardDiskPP50` | Format the hard disk |
| `TurnOffTheKn50HdMotorPP50` | Spin down HD motor |
| `TestSongInfoFromKnHdPP50` | Read song info from HD |
| `EscapeKeyboardToPlayPP50` | Release keyboard for playback |
| `AskTheConvMemOpenThisFilePP50` | Query file conversion |

These functions directly correspond to the protocol commands implemented in the
HDAE5000 firmware's PPI handler at 0x160000.

## Extracting the Software

The installer files are Windows 3.1 NE (New Executable) self-extracting archives.
To extract the actual program files (including DLLs useful for reverse engineering),
you need to run them on Windows 3.1/95/98 or use Wine:

```bash
# Using Wine (may require winetricks for Win16 support)
wine HDTMD120.EXE
wine setup.EXE
```

## Reverse Engineering Notes

The HD-TechManager software communicates with the HD-AE5000 via the PC's parallel
port. The `ppkn50.dll` contains the complete PC-side protocol implementation.

### Key Areas for Analysis

1. **ppkn50.dll** - The main protocol DLL
   - Disassemble with IDA Pro, Ghidra, or x64dbg
   - Focus on exported functions listed above
   - Look for parallel port I/O (inb/outb at 0x378, 0x379, 0x37A)

2. **Protocol Correlation**
   - DLL functions map to HDAE5000 firmware commands at PPI (0x160000)
   - `SendFsbFromPCToKnMemPP50` ↔ Firmware command "05>Rcv FSB from PC"
   - `ReadFsbFromKnHdToKnMemPP50` ↔ Firmware command "03>Read FSB from HD"
   - `TurnOffTheKn50HdMotorPP50` ↔ Firmware command "18>Switch HD-motor off"

3. **Parallel Port Signals**
   - Port A (0x160000): Data byte bidirectional
   - Port B (0x160002): Status from PC
   - Port C (0x160004): Control signals

## Protocol Commands (from HDAE5000 firmware)

| Code | Command | Description |
|------|---------|-------------|
| 01 | Send Infos About HD | Report CHS parameters and model |
| 03 | Read FSB from HD | Read filesystem block |
| 04 | Send FSB to PC | Transfer FSB to PC |
| 05 | Rcv FSB from PC | Receive FSB from PC |
| 06 | Write FSB to HD | Write filesystem block |
| 07 | Load HD to Memory | Load file into KN5000 RAM |
| 08 | Send data to PC | Send data block to PC |
| 10 | Rcv data from PC | Receive data from PC |
| 11 | Save memory to HD | Save RAM contents to file |
| 16 | Delete files | Remove files from disk |
| 17 | Format HD | Low-level disk format |
| 18 | Switch HD-motor off | Spin down drive motor |
