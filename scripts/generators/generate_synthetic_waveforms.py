#!/usr/bin/env python3
"""
Generate synthetic waveform ROMs for KN5000 IC304, IC305, IC306.

These ROMs are NOT authentic -- they provide minimal valid data so the
tone generator has something to read instead of all-zeros/all-FFs.

Format (matching IC307):
  - 198-entry index table (4 bytes each: param_ptr + wave_offset*16)
  - Variable-length parameter records (key zone definitions)
  - Signed 16-bit LE PCM waveform data
  - 0xFF padding at end

Each synthetic ROM gets 198 entries with simple waveforms:
  IC304: Sine waves at various sample lengths
  IC305: Sawtooth waves at various sample lengths
  IC306: Square/triangle waves at various sample lengths

This gives the tone generator valid waveform data to play back,
even though it won't sound like the original instrument samples.
"""

import struct
import math
import os
import sys

ROM_SIZE = 4 * 1024 * 1024  # 4 MB per chip
NUM_ENTRIES = 198
INDEX_TABLE_SIZE = NUM_ENTRIES * 4  # 792 bytes = 0x318
ALIGNMENT = 16  # wave_offset granularity (byte address = wave_offset * 16)


def generate_sine(num_samples, amplitude=32000):
    """Generate one cycle of sine wave, signed 16-bit."""
    samples = []
    for i in range(num_samples):
        t = 2 * math.pi * i / num_samples
        samples.append(int(amplitude * math.sin(t)))
    return samples


def generate_sawtooth(num_samples, amplitude=32000):
    """Generate one cycle of sawtooth wave, signed 16-bit."""
    samples = []
    for i in range(num_samples):
        # Ramp from -amplitude to +amplitude
        t = i / num_samples
        samples.append(int(amplitude * (2 * t - 1)))
    return samples


def generate_square(num_samples, amplitude=28000):
    """Generate one cycle of square wave, signed 16-bit."""
    samples = []
    half = num_samples // 2
    for i in range(num_samples):
        samples.append(amplitude if i < half else -amplitude)
    return samples


def generate_triangle(num_samples, amplitude=32000):
    """Generate one cycle of triangle wave, signed 16-bit."""
    samples = []
    for i in range(num_samples):
        t = i / num_samples
        if t < 0.25:
            v = 4 * t
        elif t < 0.75:
            v = 2 - 4 * t
        else:
            v = 4 * t - 4
        samples.append(int(amplitude * v))
    return samples


def samples_to_bytes(samples):
    """Convert list of signed 16-bit integers to little-endian bytes."""
    return b''.join(struct.pack('<h', max(-32768, min(32767, s))) for s in samples)


def align_to(offset, alignment):
    """Round up to next multiple of alignment."""
    return ((offset + alignment - 1) // alignment) * alignment


def build_waveform_lengths():
    """
    Generate 186 unique waveform lengths (matching IC307's 186 unique waveforms).

    CONSTRAINT: wave_offset is a 16-bit value (max 0xFFFF) with x16 byte multiplier,
    so total addressable range is ~1 MB. All waveform data must fit within this.
    IC307 itself only uses about 1 MB of its 4 MB ROM for waveform data.

    We create entries 0-197 pointing to 186 unique waveforms
    (entries 185-190 share one waveform, 191-197 share another, like IC307).
    """
    lengths = []
    # Entry 0: 256-sample sine (matches IC307 exactly)
    lengths.append(256)

    # Entries 1-50: short waveforms (136-528 samples) - pitched tones
    for i in range(1, 51):
        lengths.append(128 + i * 8)

    # Entries 51-120: medium waveforms (512-2168 samples) - fuller sounds
    for i in range(51, 121):
        lengths.append(512 + (i - 51) * 24)

    # Entries 121-183: longer waveforms (2048-5072 samples) - complex timbres
    for i in range(121, 184):
        lengths.append(2048 + (i - 121) * 48)

    # Entry 184: long waveform (~6000 samples, shared by entries 185-190)
    lengths.append(6000)

    # Entry 185: long waveform (~8000 samples, shared by entries 191-197)
    lengths.append(8000)

    return lengths  # 186 unique waveforms


def build_param_record(wave_offset, key_zones=None):
    """
    Build a parameter record for one index entry.

    Format: wave_offset (16-bit LE), then key zone words.
    Each key zone word: [flags:8][key_number:8]

    key_zones is a list of (flags, key_number) tuples.
    If None, creates a simple single-zone record.
    """
    record = struct.pack('<H', wave_offset)
    if key_zones:
        for flags, key in key_zones:
            record += struct.pack('<H', (flags << 8) | key)
    return record


def generate_key_zones_for_entry(entry_idx):
    """
    Generate key zone parameters matching IC307's patterns.
    Uses the same distribution of record sizes as IC307.
    """
    if entry_idx == 0:
        # Entry 0: no params (like IC307's sine wave)
        return []

    if entry_idx < 32:
        # Single key zone boundary (4-byte records)
        return [(0x00, 0x40)]  # key 64 (middle C area)

    if entry_idx < 57:
        # Two key zone boundaries (6-byte records)
        return [(0x00, 0x40), (0x00, 0x30)]

    if entry_idx < 101:
        # Three zones (8-byte records) - like split instruments
        base_key = 0x20 + (entry_idx % 4) * 8
        return [(0x00, base_key + 0x20), (0x00, base_key + 0x10), (0xC0, base_key)]

    if entry_idx < 147:
        # Four zones (10-byte records)
        base_key = 0x10 + (entry_idx % 5) * 8
        return [
            (0x00, base_key + 0x30),
            (0x00, base_key + 0x20),
            (0x00, base_key + 0x10),
            (0xC0, base_key),
        ]

    if entry_idx < 185:
        # Multi-zone with per-key tuning (12-14 byte records)
        zones = [
            (0x00, 0x48),
            (0x00, 0x38),
            (0x00, 0x28),
            (0x01, 0xFF),  # per-key tuning adjustment
            (0xC0, 0x18),
        ]
        return zones

    if entry_idx < 191:
        # Shared waveform group (entries 185-190, like IC307)
        offset = entry_idx - 185
        base = 0x10 + offset * 8
        return [
            (0x00, base + 0x30),
            (0x00, base + 0x20),
            (0x00, base + 0x10),
            (0xC0, base),
        ]

    # Entries 191-197: shared waveform group
    offset = entry_idx - 191
    base = 0x00 + offset * 8
    return [
        (0x00, base + 0x38),
        (0x00, base + 0x28),
        (0xC0, base + 0x00),
    ]


def generate_rom(rom_name, waveform_generator, output_path):
    """
    Generate a complete 4MB synthetic waveform ROM.

    Args:
        rom_name: identifier for logging (e.g., "IC304")
        waveform_generator: function(num_samples) -> list of int16 samples
        output_path: where to write the ROM file
    """
    waveform_lengths = build_waveform_lengths()  # 186 unique lengths

    # Phase 1: Generate all waveform PCM data and compute offsets
    # PCM data starts right after the index table + param records.
    # We need to compute param record sizes first.

    # Build all parameter records first (to know where PCM data starts)
    param_records = []
    # Map from entry index to unique waveform index
    entry_to_wave = list(range(184))  # entries 0-183 -> waves 0-183
    entry_to_wave.append(184)  # entry 184 -> wave 184
    # Entries 185-190 share wave 184
    for _ in range(185, 191):
        entry_to_wave.append(184)
    # Entries 191-197 share wave 185
    for _ in range(191, 198):
        entry_to_wave.append(185)

    # Generate PCM data for all 186 unique waveforms
    pcm_data_list = []
    for i, length in enumerate(waveform_lengths):
        samples = waveform_generator(length)
        pcm_data_list.append(samples_to_bytes(samples))

    # Calculate where PCM data starts
    # First pass: build param records with placeholder wave_offsets to get sizes
    temp_records = []
    for i in range(NUM_ENTRIES):
        zones = generate_key_zones_for_entry(i)
        record = build_param_record(0x0000, zones)  # placeholder
        temp_records.append(record)

    total_param_size = sum(len(r) for r in temp_records)
    pcm_start_offset = INDEX_TABLE_SIZE + total_param_size
    pcm_start_offset = align_to(pcm_start_offset, ALIGNMENT)

    # Now compute actual wave_offset values for each unique waveform
    wave_byte_offsets = []
    current_offset = pcm_start_offset
    for pcm_data in pcm_data_list:
        # Align to 16-byte boundary
        current_offset = align_to(current_offset, ALIGNMENT)
        wave_byte_offsets.append(current_offset)
        current_offset += len(pcm_data)

    # Convert byte offsets to wave_offset values (divide by 16)
    wave_offsets = [off // ALIGNMENT for off in wave_byte_offsets]

    # Rebuild param records with correct wave_offsets
    final_records = []
    for i in range(NUM_ENTRIES):
        wave_idx = entry_to_wave[i]
        wo = wave_offsets[wave_idx]
        zones = generate_key_zones_for_entry(i)
        record = build_param_record(wo, zones)
        final_records.append(record)

    # Build the ROM image
    rom = bytearray(ROM_SIZE)
    # Fill with 0xFF (like IC307's padding)
    for i in range(ROM_SIZE):
        rom[i] = 0xFF

    # Write index table
    param_offset = INDEX_TABLE_SIZE
    for i in range(NUM_ENTRIES):
        wave_idx = entry_to_wave[i]
        wo = wave_offsets[wave_idx]
        struct.pack_into('<HH', rom, i * 4, param_offset, wo)
        param_offset += len(final_records[i])

    # Write parameter records
    offset = INDEX_TABLE_SIZE
    for record in final_records:
        rom[offset:offset + len(record)] = record
        offset += len(record)

    # Write PCM data
    for i, pcm_data in enumerate(pcm_data_list):
        byte_off = wave_byte_offsets[i]
        if byte_off + len(pcm_data) > ROM_SIZE:
            print(f"  WARNING: Waveform {i} exceeds ROM size, truncating")
            pcm_data = pcm_data[:ROM_SIZE - byte_off]
        rom[byte_off:byte_off + len(pcm_data)] = pcm_data

    # Write to file
    with open(output_path, 'wb') as f:
        f.write(rom)

    # Report stats
    total_pcm = sum(len(d) for d in pcm_data_list)
    total_params = sum(len(r) for r in final_records)
    print(f"  {rom_name}: {output_path}")
    print(f"    Index table: {INDEX_TABLE_SIZE} bytes (198 entries)")
    print(f"    Param records: {total_params} bytes")
    print(f"    PCM data starts at: 0x{pcm_start_offset:06X}")
    print(f"    Total PCM: {total_pcm} bytes ({total_pcm // 2} samples)")
    print(f"    Unique waveforms: {len(pcm_data_list)}")
    print(f"    ROM size: {ROM_SIZE} bytes (4 MB)")


def main():
    # Default output directory: alongside the original ROMs
    output_dir = '/mnt/shared/kn5000_original_roms/kn5000'

    if len(sys.argv) > 1:
        output_dir = sys.argv[1]

    if not os.path.isdir(output_dir):
        print(f"Error: Output directory does not exist: {output_dir}")
        sys.exit(1)

    print("Generating synthetic waveform ROMs for KN5000...")
    print(f"Output directory: {output_dir}")
    print()

    # IC304: Sine waves (cleanest, most universal)
    print("IC304 (Sine waves):")
    generate_rom(
        "IC304",
        generate_sine,
        os.path.join(output_dir, "kn5000_waveform_rom.ic304"),
    )
    print()

    # IC305: Sawtooth waves (harmonically rich, good for brass/strings)
    print("IC305 (Sawtooth waves):")
    generate_rom(
        "IC305",
        generate_sawtooth,
        os.path.join(output_dir, "kn5000_waveform_rom.ic305"),
    )
    print()

    # IC306: Mixed square/triangle waves
    # Alternate between square and triangle for variety
    def mixed_generator(num_samples):
        # Use triangle for shorter waveforms, square for longer
        if num_samples < 2048:
            return generate_triangle(num_samples)
        else:
            return generate_square(num_samples)

    print("IC306 (Square/Triangle mix):")
    generate_rom(
        "IC306",
        mixed_generator,
        os.path.join(output_dir, "kn5000_waveform_rom.ic306"),
    )
    print()

    # Verify against IC307 format
    ic307_path = os.path.join(output_dir, "kn5000_waveform_rom.ic307")
    if os.path.exists(ic307_path):
        with open(ic307_path, 'rb') as f:
            ic307 = f.read()
        # Read IC307's first entry
        pp, wo = struct.unpack_from('<HH', ic307, 0)
        print(f"IC307 reference: entry 0 param_ptr=0x{pp:04X}, wave_offset=0x{wo:04X}")

        # Read our IC304 first entry
        ic304_path = os.path.join(output_dir, "kn5000_waveform_rom.ic304")
        with open(ic304_path, 'rb') as f:
            ic304 = f.read(0x400)
        pp, wo = struct.unpack_from('<HH', ic304, 0)
        print(f"IC304 synthetic: entry 0 param_ptr=0x{pp:04X}, wave_offset=0x{wo:04X}")
        print(f"  PCM byte offset: 0x{wo * 16:06X}")
    print()
    print("Done! Synthetic waveform ROMs generated successfully.")
    print()
    print("These ROMs use the same index table structure as IC307 but with")
    print("simple synthesized waveforms (sine, sawtooth, square/triangle).")
    print("They will allow the tone generator to produce sound, though")
    print("the timbres will not match the original instrument samples.")


if __name__ == '__main__':
    main()
