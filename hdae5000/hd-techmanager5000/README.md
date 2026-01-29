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

### Other

| File | Description |
|------|-------------|
| `hd-ae5000installed.jpg` | Photo of installed HD-AE5000 |
| `intro.mid` | Demo MIDI file |

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
port. The software contains routines for:

- File transfer to/from the HD-AE5000 hard disk
- FSB (File System Block) manipulation
- Disk formatting
- Backup and restore operations

Any DLL files extracted from the installer may contain the parallel port protocol
implementation that mirrors the HDAE5000 firmware's PPI handling at 0x160000.

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
