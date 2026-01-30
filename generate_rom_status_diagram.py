#!/usr/bin/env python3
"""
ROM Status Visualization Generator

Generates pixel-based images showing the disassembly status of each memory
address in the KN5000 ROM set. Each pixel represents a memory region,
colored by its disassembly status.

This script is part of the project's mandatory documentation workflow.
Run after making significant disassembly progress to update the website.

Usage:
    python generate_rom_status_diagram.py

Output:
    ../kn5000-docs/assets/images/rom-status-diagram.png
"""

import os
import re
from dataclasses import dataclass
from typing import List, Dict, Tuple
from enum import Enum
from PIL import Image, ImageDraw, ImageFont

class RegionStatus(Enum):
    """Categories for memory region status"""
    DISASSEMBLED_CODE = "Disassembled Code"
    KNOWN_DATA = "Known Data (documented)"
    RAW_BYTES_UNKNOWN = "Raw Bytes (unknown)"
    RAW_BYTES_CODE = "Raw Bytes (known code, not disassembled)"
    PADDING_UNUSED = "Padding / Unused"
    STRING_DATA = "String Data"
    BINARY_INCLUDE = "Binary Include (external)"
    POINTER_TABLE = "Pointer/Jump Table"
    UNDETERMINED = "Undetermined"

# Color scheme for each status (RGB)
STATUS_COLORS = {
    RegionStatus.DISASSEMBLED_CODE: (0, 180, 0),       # Green
    RegionStatus.KNOWN_DATA: (0, 120, 200),            # Blue
    RegionStatus.RAW_BYTES_UNKNOWN: (220, 60, 60),     # Red
    RegionStatus.RAW_BYTES_CODE: (255, 140, 0),        # Orange
    RegionStatus.PADDING_UNUSED: (128, 128, 128),      # Gray
    RegionStatus.STRING_DATA: (0, 200, 200),           # Cyan
    RegionStatus.BINARY_INCLUDE: (160, 100, 200),      # Purple
    RegionStatus.POINTER_TABLE: (100, 180, 100),       # Light green
    RegionStatus.UNDETERMINED: (255, 220, 80),         # Yellow
}

@dataclass
class MemoryRegion:
    """Represents a memory region with its status"""
    start_addr: int
    end_addr: int
    status: RegionStatus
    label: str = ""

    @property
    def size(self) -> int:
        return self.end_addr - self.start_addr

@dataclass
class ROMInfo:
    """Information about a ROM component"""
    name: str
    size: int
    regions: List[MemoryRegion]
    base_addr: int = 0

# Instruction patterns that indicate disassembled code
CODE_INSTRUCTIONS = {
    'CALL', 'JP', 'JR', 'JRL', 'RET', 'RETI', 'RETD',
    'LD', 'LDA', 'LDW', 'LDC', 'LDAR',
    'PUSH', 'POP', 'PUSH_WORD',
    'ADD', 'SUB', 'MUL', 'DIV', 'INC', 'DEC',
    'AND', 'OR', 'XOR', 'CPL', 'NEG',
    'CP', 'CPW', 'BIT', 'SET', 'RES',
    'SLA', 'SLL', 'SRA', 'SRL', 'RLC', 'RRC', 'RL', 'RR',
    'NOP', 'HALT', 'EI', 'DI',
    'EXTZ', 'EXTS', 'EX',
    'CALR', 'DJNZ',
    'LDI', 'LDIR', 'LDD', 'LDDR',
}

def parse_assembly_file(filepath: str, base_addr: int, rom_size: int) -> List[MemoryRegion]:
    """Parse an assembly file and identify memory regions by status"""
    regions = []
    current_addr = base_addr
    current_status = RegionStatus.UNDETERMINED
    region_start = base_addr

    consecutive_db_lines = 0

    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
    except FileNotFoundError:
        return [MemoryRegion(base_addr, base_addr + rom_size, RegionStatus.UNDETERMINED)]

    for line in lines:
        line = line.strip()

        if not line or line.startswith(';'):
            continue

        # Check for ORG directive
        org_match = re.match(r'^\s*ORG\s+([0-9A-Fa-fx]+)h?\s*', line, re.IGNORECASE)
        if org_match:
            addr_str = org_match.group(1).replace('0x', '').replace('h', '')
            try:
                new_addr = int(addr_str, 16)
                if current_addr != region_start:
                    regions.append(MemoryRegion(region_start, current_addr, current_status))
                current_addr = new_addr
                region_start = new_addr
                current_status = RegionStatus.UNDETERMINED
            except ValueError:
                pass
            continue

        # Check for label definitions
        if re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', line):
            continue

        # Check for binclude
        if 'binclude' in line.lower():
            if current_status != RegionStatus.BINARY_INCLUDE:
                if current_addr != region_start:
                    regions.append(MemoryRegion(region_start, current_addr, current_status))
                region_start = current_addr
                current_status = RegionStatus.BINARY_INCLUDE
            filename_match = re.search(r'([0-9a-f]+)_([0-9a-f]+)\.bin', line, re.IGNORECASE)
            if filename_match:
                try:
                    start = int(filename_match.group(1), 16)
                    end = int(filename_match.group(2), 16)
                    current_addr += (end - start + 1)
                except ValueError:
                    current_addr += 1024
            else:
                current_addr += 1024
            continue

        # Check for dup pattern (padding)
        dup_match = re.match(r'^\s*db\s+([0-9A-Fa-f]+)h?\s+dup\s*\(\s*([0-9A-Fa-fx]+h?)\s*\)', line, re.IGNORECASE)
        if dup_match:
            count_str = dup_match.group(1).replace('h', '')
            try:
                count = int(count_str, 16) if len(count_str) > 2 else int(count_str)
                if current_status != RegionStatus.PADDING_UNUSED:
                    if current_addr != region_start:
                        regions.append(MemoryRegion(region_start, current_addr, current_status))
                    region_start = current_addr
                    current_status = RegionStatus.PADDING_UNUSED
                current_addr += count
            except ValueError:
                pass
            continue

        # Check for string data
        if re.match(r'^\s*db\s+"[^"]*"', line):
            if current_status != RegionStatus.STRING_DATA:
                if current_addr != region_start:
                    regions.append(MemoryRegion(region_start, current_addr, current_status))
                region_start = current_addr
                current_status = RegionStatus.STRING_DATA
            str_content = re.findall(r'"([^"]*)"', line)
            str_len = sum(len(s) for s in str_content)
            hex_bytes = re.findall(r'0[0-9A-Fa-f]+h', line)
            current_addr += str_len + len(hex_bytes)
            continue

        # Check for pointer tables
        if re.match(r'^\s*dd\s+[A-Za-z_][A-Za-z0-9_]*', line):
            if current_status != RegionStatus.POINTER_TABLE:
                if current_addr != region_start:
                    regions.append(MemoryRegion(region_start, current_addr, current_status))
                region_start = current_addr
                current_status = RegionStatus.POINTER_TABLE
            current_addr += 4
            continue

        # Check for raw data
        raw_data_match = re.match(r'^\s*d[bwd]\s+([0-9A-Fa-f]+h)', line)
        if raw_data_match:
            if line.strip().startswith('db'):
                byte_count = len(re.findall(r'[0-9A-Fa-f]+h', line))
                current_addr += byte_count
                consecutive_db_lines += 1
                if consecutive_db_lines > 2:
                    if current_status != RegionStatus.RAW_BYTES_UNKNOWN:
                        if current_addr != region_start:
                            regions.append(MemoryRegion(region_start, current_addr - byte_count * 3, current_status))
                        region_start = current_addr - byte_count * 3
                        current_status = RegionStatus.RAW_BYTES_UNKNOWN
            elif line.strip().startswith('dw'):
                current_addr += 2 * len(re.findall(r'[0-9A-Fa-f]+h', line))
            elif line.strip().startswith('dd'):
                current_addr += 4 * len(re.findall(r'[0-9A-Fa-f]+h', line))
            continue
        else:
            consecutive_db_lines = 0

        # Check for code instructions
        for instr in CODE_INSTRUCTIONS:
            if re.match(rf'^\s*{instr}\b', line, re.IGNORECASE):
                if current_status != RegionStatus.DISASSEMBLED_CODE:
                    if current_addr != region_start:
                        regions.append(MemoryRegion(region_start, current_addr, current_status))
                    region_start = current_addr
                    current_status = RegionStatus.DISASSEMBLED_CODE
                current_addr += 3  # Average instruction size
                break

    # Add final region
    if current_addr != region_start:
        regions.append(MemoryRegion(region_start, current_addr, current_status))

    # Fill to ROM size
    end_addr = base_addr + rom_size
    if regions and regions[-1].end_addr < end_addr:
        regions.append(MemoryRegion(regions[-1].end_addr, end_addr, RegionStatus.UNDETERMINED))
    elif not regions:
        regions.append(MemoryRegion(base_addr, end_addr, RegionStatus.UNDETERMINED))

    return regions

def merge_adjacent_regions(regions: List[MemoryRegion]) -> List[MemoryRegion]:
    """Merge adjacent regions with the same status"""
    if not regions:
        return regions

    merged = [regions[0]]
    for region in regions[1:]:
        if region.status == merged[-1].status and region.start_addr == merged[-1].end_addr:
            merged[-1] = MemoryRegion(merged[-1].start_addr, region.end_addr, region.status)
        else:
            merged.append(region)
    return merged

def calculate_status_stats(regions: List[MemoryRegion], rom_size: int) -> Dict[RegionStatus, Tuple[int, float]]:
    """Calculate bytes and percentage of ROM for each status"""
    stats = {status: 0 for status in RegionStatus}
    for region in regions:
        stats[region.status] += region.size

    # Convert to (bytes, percentage) tuples
    result = {}
    for status in stats:
        bytes_count = stats[status]
        pct = (bytes_count / rom_size) * 100 if rom_size > 0 else 0
        result[status] = (bytes_count, pct)

    return result

def create_rom_pixel_map(regions: List[MemoryRegion], base_addr: int, rom_size: int,
                         width: int, bytes_per_pixel: int) -> List[List[Tuple[int, int, int]]]:
    """Create a 2D pixel map for a ROM based on its regions"""
    height = (rom_size + bytes_per_pixel * width - 1) // (bytes_per_pixel * width)

    # Initialize with undetermined color
    pixels = [[STATUS_COLORS[RegionStatus.UNDETERMINED] for _ in range(width)] for _ in range(height)]

    # Build a lookup for address -> status
    status_map = []
    for region in regions:
        status_map.append((region.start_addr, region.end_addr, region.status))

    # Fill pixels
    for y in range(height):
        for x in range(width):
            byte_offset = (y * width + x) * bytes_per_pixel
            addr = base_addr + byte_offset

            if byte_offset >= rom_size:
                pixels[y][x] = (40, 40, 40)  # Dark gray for beyond ROM
                continue

            # Find the region containing this address
            for start, end, status in status_map:
                if start <= addr < end:
                    pixels[y][x] = STATUS_COLORS[status]
                    break

    return pixels

def generate_rom_status_diagram(output_path: str):
    """Generate the complete ROM status diagram with pixel representation"""

    # Define ROM components
    rom_components = [
        {
            'name': 'Main CPU (2MB)',
            'short_name': 'Main CPU',
            'size': 2 * 1024 * 1024,
            'asm_file': 'maincpu/kn5000_v10_program.asm',
            'base_addr': 0xE00000,
            'width': 512,  # pixels wide
            'bytes_per_pixel': 8,  # each pixel = 8 bytes
        },
        {
            'name': 'Sub CPU Payload (192KB)',
            'short_name': 'Sub Payload',
            'size': 192 * 1024,
            'asm_file': 'subcpu/kn5000_subprogram_v142.asm',
            'base_addr': 0x000000,
            'width': 256,
            'bytes_per_pixel': 4,
        },
        {
            'name': 'Sub CPU Boot (128KB)',
            'short_name': 'Sub Boot',
            'size': 128 * 1024,
            'asm_file': 'subcpu_boot/kn5000_subcpu_boot.asm',
            'base_addr': 0xFE0000,
            'width': 256,
            'bytes_per_pixel': 4,
        },
        {
            'name': 'Table Data (2MB)',
            'short_name': 'Table Data',
            'size': 2 * 1024 * 1024,
            'asm_file': 'table_data/kn5000_table_data.asm',
            'base_addr': 0x800000,
            'width': 512,
            'bytes_per_pixel': 8,
        },
        {
            'name': 'HDAE5000 (512KB)',
            'short_name': 'HDAE5000',
            'size': 512 * 1024,
            'asm_file': 'hdae5000/hd-ae5000_v2_06i.asm',
            'base_addr': 0x280000,
            'width': 256,
            'bytes_per_pixel': 4,
        },
    ]

    # Parse all ROMs and create pixel maps
    rom_data = []
    script_dir = os.path.dirname(os.path.abspath(__file__))

    for comp in rom_components:
        asm_path = os.path.join(script_dir, comp['asm_file'])
        regions = parse_assembly_file(asm_path, comp['base_addr'], comp['size'])
        regions = merge_adjacent_regions(regions)

        pixel_map = create_rom_pixel_map(
            regions, comp['base_addr'], comp['size'],
            comp['width'], comp['bytes_per_pixel']
        )

        stats = calculate_status_stats(regions, comp['size'])

        rom_data.append({
            'name': comp['name'],
            'short_name': comp['short_name'],
            'size': comp['size'],
            'width': comp['width'],
            'height': len(pixel_map),
            'pixels': pixel_map,
            'stats': stats,
            'bytes_per_pixel': comp['bytes_per_pixel'],
        })

    # Calculate image dimensions
    margin = 20
    spacing = 30
    label_height = 60
    legend_height = 140
    title_height = 40

    # Find max height among all ROMs
    max_rom_height = max(r['height'] for r in rom_data)

    # Total width = sum of all ROM widths + spacing + margins
    total_rom_width = sum(r['width'] for r in rom_data) + spacing * (len(rom_data) - 1)
    img_width = total_rom_width + margin * 2
    img_height = title_height + max_rom_height + label_height + legend_height + margin * 2

    # Create image
    img = Image.new('RGB', (img_width, img_height), (255, 255, 255))

    # Try to load fonts
    try:
        title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 16)
        label_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 11)
        small_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 9)
    except:
        title_font = ImageFont.load_default()
        label_font = title_font
        small_font = title_font

    draw = ImageDraw.Draw(img)

    # Draw title
    title = "KN5000 ROM Set - Disassembly Status (each pixel = memory region)"
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    draw.text(((img_width - title_width) // 2, margin // 2), title, fill=(0, 0, 0), font=title_font)

    # Draw each ROM
    x_offset = margin
    rom_y = title_height + margin

    for rom in rom_data:
        # Draw pixel map
        for y, row in enumerate(rom['pixels']):
            for x, color in enumerate(row):
                img.putpixel((x_offset + x, rom_y + y), color)

        # Draw border
        draw.rectangle(
            [x_offset - 1, rom_y - 1, x_offset + rom['width'], rom_y + rom['height']],
            outline=(0, 0, 0), width=1
        )

        # Draw label below
        label_y = rom_y + max_rom_height + 5
        center_x = x_offset + rom['width'] // 2

        # ROM name
        name_bbox = draw.textbbox((0, 0), rom['short_name'], font=label_font)
        name_width = name_bbox[2] - name_bbox[0]
        draw.text((center_x - name_width // 2, label_y), rom['short_name'], fill=(0, 0, 0), font=label_font)

        # Size info
        size_str = f"{rom['size'] // 1024}KB"
        if rom['size'] >= 1024 * 1024:
            size_str = f"{rom['size'] // (1024*1024)}MB"
        size_bbox = draw.textbbox((0, 0), size_str, font=small_font)
        size_width = size_bbox[2] - size_bbox[0]
        draw.text((center_x - size_width // 2, label_y + 14), size_str, fill=(80, 80, 80), font=small_font)

        # Code percentage
        code_bytes, code_pct = rom['stats'].get(RegionStatus.DISASSEMBLED_CODE, (0, 0))
        pct_str = f"{code_pct:.1f}% code"
        pct_bbox = draw.textbbox((0, 0), pct_str, font=small_font)
        pct_width = pct_bbox[2] - pct_bbox[0]
        draw.text((center_x - pct_width // 2, label_y + 28), pct_str, fill=(0, 140, 0), font=small_font)

        # Resolution info
        res_str = f"1px = {rom['bytes_per_pixel']} bytes"
        res_bbox = draw.textbbox((0, 0), res_str, font=small_font)
        res_width = res_bbox[2] - res_bbox[0]
        draw.text((center_x - res_width // 2, label_y + 42), res_str, fill=(100, 100, 100), font=small_font)

        x_offset += rom['width'] + spacing

    # Draw legend
    legend_y = rom_y + max_rom_height + label_height + 10
    legend_x = margin

    draw.text((legend_x, legend_y), "Legend:", fill=(0, 0, 0), font=label_font)
    legend_y += 20

    legend_items = [
        (RegionStatus.DISASSEMBLED_CODE, "Disassembled Code"),
        (RegionStatus.KNOWN_DATA, "Known Data"),
        (RegionStatus.STRING_DATA, "String Data"),
        (RegionStatus.POINTER_TABLE, "Pointer/Jump Tables"),
        (RegionStatus.BINARY_INCLUDE, "Binary Includes"),
        (RegionStatus.RAW_BYTES_UNKNOWN, "Raw Bytes (unknown)"),
        (RegionStatus.RAW_BYTES_CODE, "Raw Bytes (known code)"),
        (RegionStatus.PADDING_UNUSED, "Padding/Unused"),
        (RegionStatus.UNDETERMINED, "Undetermined"),
    ]

    items_per_row = 3
    item_width = (img_width - margin * 2) // items_per_row

    for i, (status, label) in enumerate(legend_items):
        row = i // items_per_row
        col = i % items_per_row
        lx = legend_x + col * item_width
        ly = legend_y + row * 22

        color = STATUS_COLORS[status]
        draw.rectangle([lx, ly, lx + 14, ly + 14], fill=color, outline=(0, 0, 0))
        draw.text((lx + 18, ly + 1), label, fill=(0, 0, 0), font=small_font)

    # Save image
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path, 'PNG')
    print(f"Generated: {output_path}")

    # Print statistics
    print("\nROM Status Statistics:")
    print("=" * 70)
    for rom in rom_data:
        print(f"\n{rom['name']} ({rom['width']}x{rom['height']} pixels, 1px = {rom['bytes_per_pixel']} bytes):")
        for status, (bytes_count, pct) in sorted(rom['stats'].items(), key=lambda x: -x[1][1]):
            if pct > 0.1:
                print(f"  {status.value}: {pct:.1f}% ({bytes_count:,} bytes)")

if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(script_dir, '..', 'kn5000-docs', 'assets', 'images', 'rom-status-diagram.png')
    generate_rom_status_diagram(output_path)
