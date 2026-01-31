#!/usr/bin/env python3
"""
Create a test Table Data ROM with Sub CPU payload embedded.

This script creates a modified table_data ROM for testing the MAME driver's
Sub CPU payload transfer functionality.

The SubCPU_Send_Payload routine (0xEF068A) transfers data from table_data to
Sub CPU RAM at these locations:

1. 5x64KB from 0x830000 → Sub CPU 0x050000-0x0A0000 (offset 0x30000 in table_data)
2. 64KB from 0x800100 → Sub CPU 0x00F000-0x01F000 (offset 0x100 in table_data)
3. 64KB from 0x810100 → Sub CPU 0x01F000-0x02F000 (offset 0x10100 in table_data)
4. 65280 bytes from 0x820100 → Sub CPU 0x02F000-0x03EF00 (offset 0x20100 in table_data)
5. 256 bytes from 0x800000 → Sub CPU 0x000400 (offset 0x0 in table_data, entry point)

The subprogram file format:
- Bytes 0-255: Interrupt vectors (org 0x0400)
- Bytes 256+: Code starting at org 0xF000 (gap 0x0500-0xEFFF not stored)

Usage:
    python create_test_table_data_rom.py [options]

Options:
    --table-data PATH   Original table_data.rom (default: original_ROMs/kn5000_table_data.rom)
    --subprogram PATH   Subprogram payload (default: original_ROMs/kn5000_subprogram_v142.rom)
    --output PATH       Output test ROM (default: test_ROMs/test_table_data.rom)
    --verbose           Show detailed transfer information
"""

import argparse
import os
import sys

def create_test_rom(table_data_path, subprogram_path, output_path, verbose=False):
    """Create a test table_data ROM with subprogram embedded."""

    # Read the original table_data ROM
    if verbose:
        print(f"Reading original table_data from: {table_data_path}")
    with open(table_data_path, 'rb') as f:
        table_data = bytearray(f.read())

    if len(table_data) != 2097152:  # 2MB
        print(f"Warning: table_data size is {len(table_data)}, expected 2097152")

    # Read the subprogram payload
    if verbose:
        print(f"Reading subprogram from: {subprogram_path}")
    with open(subprogram_path, 'rb') as f:
        subprogram = f.read()

    if len(subprogram) != 196608:  # 192KB
        print(f"Warning: subprogram size is {len(subprogram)}, expected 196608")

    # Split subprogram into parts
    # Part A: First 256 bytes (interrupt vectors at org 0x0400)
    part_a = subprogram[:256]
    # Part B: Rest of file (code starting at org 0xF000)
    part_b = subprogram[256:]

    if verbose:
        print(f"\nSubprogram split:")
        print(f"  Part A (interrupt vectors): {len(part_a)} bytes → table_data[0x00000]")
        print(f"  Part B (code at org 0xF000): {len(part_b)} bytes → table_data[0x00100]")

    # Place Part A: Interrupt vectors (0x800000 → Sub CPU 0x0400)
    # Offset 0x00000 in table_data, transferred last as 256 bytes
    offset_a = 0x00000
    table_data[offset_a:offset_a + len(part_a)] = part_a
    if verbose:
        print(f"\nPlaced Part A at offset 0x{offset_a:05X}")
        print(f"  First bytes: {' '.join(f'{b:02X}' for b in part_a[:16])}")

    # Place Part B: Main code (0x800100+ → Sub CPU 0xF000+)
    # The transfers are:
    #   0x800100 (64KB) → 0xF000
    #   0x810100 (64KB) → 0x1F000
    #   0x820100 (65280 bytes) → 0x2F000
    # Total: 64KB + 64KB + 65280 = 196352 bytes = len(part_b)
    offset_b = 0x00100
    table_data[offset_b:offset_b + len(part_b)] = part_b
    if verbose:
        print(f"\nPlaced Part B at offset 0x{offset_b:05X}")
        print(f"  Size: {len(part_b)} bytes ({len(part_b)/1024:.1f} KB)")
        print(f"  First bytes: {' '.join(f'{b:02X}' for b in part_b[:16])}")

    # The 5x64KB transfers from 0x830000 (offset 0x30000) go to Sub CPU 0x050000+
    # This region is NOT part of the subprogram file - it may contain other data
    # or be empty. For testing, we leave the original table_data content there.
    if verbose:
        print(f"\nNote: Region at offset 0x30000 (5x64KB → Sub CPU 0x50000+)")
        print(f"  Left unchanged from original table_data")
        print(f"  Original bytes: {' '.join(f'{b:02X}' for b in table_data[0x30000:0x30010])}")

    # Create output directory if needed
    output_dir = os.path.dirname(output_path)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)
        if verbose:
            print(f"\nCreated output directory: {output_dir}")

    # Write the combined test ROM
    with open(output_path, 'wb') as f:
        f.write(table_data)

    print(f"\nCreated test ROM: {output_path}")
    print(f"  Size: {len(table_data)} bytes ({len(table_data)/1024/1024:.1f} MB)")

    # Also create split odd/even ROMs for MAME (IC1=odd, IC3=even)
    base_name = output_path.rsplit('.', 1)[0]
    odd_path = f"{base_name}_odd.rom"
    even_path = f"{base_name}_even.rom"

    odd_bytes = bytearray()
    even_bytes = bytearray()
    for i in range(0, len(table_data), 2):
        even_bytes.append(table_data[i])
        if i + 1 < len(table_data):
            odd_bytes.append(table_data[i + 1])

    with open(odd_path, 'wb') as f:
        f.write(odd_bytes)
    with open(even_path, 'wb') as f:
        f.write(even_bytes)

    print(f"\nCreated split ROMs for MAME:")
    print(f"  {odd_path} (IC1, odd bytes): {len(odd_bytes)} bytes")
    print(f"  {even_path} (IC3, even bytes): {len(even_bytes)} bytes")

    # Summary of what was patched
    print("\nPatched regions:")
    print(f"  0x{offset_a:05X}-0x{offset_a + len(part_a) - 1:05X}: Interrupt vectors ({len(part_a)} bytes)")
    print(f"  0x{offset_b:05X}-0x{offset_b + len(part_b) - 1:05X}: Main code ({len(part_b)} bytes)")

    return True


def main():
    parser = argparse.ArgumentParser(
        description='Create a test Table Data ROM with Sub CPU payload embedded.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Transfer mapping (table_data offset → Sub CPU address):
  0x00000 (256 bytes)     → 0x000400 (interrupt vectors)
  0x00100 (64KB)          → 0x00F000 (main code)
  0x10100 (64KB)          → 0x01F000
  0x20100 (65280 bytes)   → 0x02F000
  0x30000 (5x64KB)        → 0x050000 (not from subprogram file)
        """
    )
    parser.add_argument('--table-data', default='original_ROMs/kn5000_table_data.rom',
                        help='Original table_data.rom path')
    parser.add_argument('--subprogram', default='original_ROMs/kn5000_subprogram_v142.rom',
                        help='Subprogram payload path')
    parser.add_argument('--output', default='test_ROMs/test_table_data.rom',
                        help='Output test ROM path')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Show detailed transfer information')

    args = parser.parse_args()

    # Check input files exist
    if not os.path.exists(args.table_data):
        print(f"Error: Table data ROM not found: {args.table_data}")
        sys.exit(1)
    if not os.path.exists(args.subprogram):
        print(f"Error: Subprogram not found: {args.subprogram}")
        sys.exit(1)

    success = create_test_rom(
        args.table_data,
        args.subprogram,
        args.output,
        args.verbose
    )

    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
