# LZSS Compressed Payload Analysis Report

## Summary

**The compressed data at Table Data ROM offset 0x0E0000 (address 0x8E0000) is NOT the Sub CPU program payload.**

## Compressed Data Analysis

### Location: 0x8E0000 (Table Data ROM offset 0x0E0000)

| Property | Value |
|----------|-------|
| Header | `SLIDE4K\0` |
| Compressed size | 131,072 bytes (128KB) |
| Decompressed size | 262,153 bytes (~256KB) |
| Size field in header | 0x009500 (38,144) |
| First bytes (decompressed) | `5A 5A 5A 01 01 08 00 0C...` |

### Sub CPU Program (kn5000_subprogram_v142.rom)

| Property | Value |
|----------|-------|
| Size | 196,608 bytes (192KB) |
| First bytes | `1B 24 F9 01 0E 1B BC FB...` |

### Comparison Result

```
Decompressed payload: 5a5a5a010108000c00000000000000000000000000012e00...
Built subprogram:     1b24f9010e1bbcfb010e1bbcfb010e1bbcfb010e1bbcfb01...

Result: COMPLETELY DIFFERENT DATA
```

## Search Results

### Subprogram Signature Search

Searched for subprogram signature `1b24f9010e1bbcfb010e1bbcfb010e1b` in:

| ROM | Result |
|-----|--------|
| Table Data ROM (2MB) | **NOT FOUND** |
| Custom Data Flash (1MB) | **NOT FOUND** |

### SLIDE4K Headers in Table Data ROM

Found 19 SLIDE4K compressed blocks, all in the Feature Demo area:

| Offset | Address | Size Field |
|--------|---------|------------|
| 0x0E0000 | 0x8E0000 | 0x9500 |
| 0x1C4050 | 0x9C4050 | 0x6900 |
| 0x1C9018 | 0x9C9018 | 0x7100 |
| 0x1CE17C | 0x9CE17C | 0x4A00 |
| ... | ... | ... |

These appear to be compressed graphics/UI data for the Feature Demo, not the subprogram.

## Analysis of SubCPU_Send_Payload

The `SubCPU_Send_Payload` routine at 0xEF068A reads from:

| Source Address | Table Data Offset | Content |
|----------------|-------------------|---------|
| 0x830000 | 0x030000 | `ffffffff00010000001b0000...` |
| 0x840000 | 0x040000 | `000f1700000040091b120901...` |
| 0x850000 | 0x050000 | `141728000f1700000f170000...` |
| 0x860000 | 0x060000 | `3000f8cb3000f7cc3000f7cd...` |
| 0x870000 | 0x070000 | `00000000000000000000000...` |

**This data does NOT match the subprogram.** The content appears to be lookup tables or configuration data, not executable code.

## Conclusions

1. **The subprogram is NOT stored in the Table Data ROM** - neither compressed nor uncompressed.

2. **The compressed data at 0x8E0000 is Feature Demo/UI data**, not the subprogram. It decompresses to "ZZZ"-prefixed blocks used by the Feature Demo system.

3. **The subprogram must come from elsewhere:**
   - Possibly programmed directly into a separate flash chip not dumped
   - Possibly loaded from floppy disk during firmware updates
   - The `kn5000_subprogram_v142.rom` file in MAME may be extracted/reconstructed from a different source

4. **The SubCPU_Send_Payload addresses (0x830000-0x870000) in our ROM dumps don't contain the subprogram**, suggesting our dumps may represent a different system state than expected.

## Implications

- Adding LZSS compression of the subprogram to the Makefile is **not applicable** - the subprogram isn't stored compressed in the Table Data ROM.
- The relationship between the subprogram ROM and the Table Data ROM needs further investigation.
- The MAME driver may use a different mechanism to provide the subprogram to the emulated Sub CPU.
