#!/usr/bin/env python3
"""
ROM Status Visualization Generator

Generates pixel-based images showing the disassembly status of each memory
address in the KN5000 ROM set. Each pixel represents a fixed number of bytes,
ensuring ROM sizes are accurately represented by pixel area.

This script is part of the project's mandatory documentation workflow.
Run after making significant disassembly progress to update the website.

Usage:
    python generate_rom_status_diagram.py

Output:
    ../kn5000-docs/assets/images/rom-status-diagram.png
"""

import os
import re
import math
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

# Color scheme for each status (RGB) - high contrast, distinct hues
STATUS_COLORS = {
    RegionStatus.DISASSEMBLED_CODE: (0, 160, 0),        # Green
    RegionStatus.KNOWN_DATA: (0, 100, 220),             # Blue
    RegionStatus.RAW_BYTES_UNKNOWN: (220, 40, 40),      # Red
    RegionStatus.RAW_BYTES_CODE: (255, 140, 0),         # Orange
    RegionStatus.PADDING_UNUSED: (140, 140, 140),       # Gray
    RegionStatus.STRING_DATA: (0, 190, 190),            # Cyan
    RegionStatus.BINARY_INCLUDE: (160, 70, 200),        # Purple
    RegionStatus.POINTER_TABLE: (180, 180, 0),          # Yellow-olive (distinct from green)
    RegionStatus.UNDETERMINED: (240, 200, 120),         # Tan/beige
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
    total_pixels = rom_size // bytes_per_pixel
    height = (total_pixels + width - 1) // width

    # Initialize with undetermined color
    pixels = [[STATUS_COLORS[RegionStatus.UNDETERMINED] for _ in range(width)] for _ in range(height)]

    # Build a lookup for address -> status
    status_map = []
    for region in regions:
        status_map.append((region.start_addr, region.end_addr, region.status))

    # Fill pixels
    for y in range(height):
        for x in range(width):
            pixel_index = y * width + x
            byte_offset = pixel_index * bytes_per_pixel
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

    # Common bytes_per_pixel for all ROMs to ensure accurate proportions
    BYTES_PER_PIXEL = 8

    # Define ROM components
    rom_components = [
        {
            'name': 'Main CPU',
            'size': 2 * 1024 * 1024,  # 2MB
            'asm_file': 'maincpu/kn5000_v10_program.asm',
            'base_addr': 0xE00000,
        },
        {
            'name': 'Table Data',
            'size': 2 * 1024 * 1024,  # 2MB
            'asm_file': 'table_data/kn5000_table_data.asm',
            'base_addr': 0x800000,
        },
        {
            'name': 'Sub CPU Boot',
            'size': 128 * 1024,  # 128KB
            'asm_file': 'subcpu_boot/kn5000_subcpu_boot.asm',
            'base_addr': 0xFE0000,
        },
        {
            'name': 'Sub CPU Payload',
            'size': 192 * 1024,  # 192KB
            'asm_file': 'subcpu/kn5000_subprogram_v142.asm',
            'base_addr': 0x000000,
        },
        {
            'name': 'HDAE5000',
            'size': 512 * 1024,  # 512KB
            'asm_file': 'hdae5000/hd-ae5000_v2_06i.asm',
            'base_addr': 0x280000,
        },
    ]

    # Parse all ROMs and create pixel maps
    rom_data = {}
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Target width for large ROMs (Main CPU, Table Data)
    large_rom_width = 512

    for comp in rom_components:
        asm_path = os.path.join(script_dir, comp['asm_file'])
        regions = parse_assembly_file(asm_path, comp['base_addr'], comp['size'])
        regions = merge_adjacent_regions(regions)

        # Calculate dimensions
        total_pixels = comp['size'] // BYTES_PER_PIXEL

        # Use fixed width for large ROMs, calculate for smaller ones to fit nicely
        if comp['size'] >= 1024 * 1024:  # 1MB or larger
            width = large_rom_width
        else:
            # For smaller ROMs, use a width that gives reasonable aspect ratio
            width = int(math.sqrt(total_pixels * 1.5))
            width = ((width + 7) // 8) * 8  # Round to multiple of 8

        height = (total_pixels + width - 1) // width

        pixel_map = create_rom_pixel_map(
            regions, comp['base_addr'], comp['size'],
            width, BYTES_PER_PIXEL
        )

        stats = calculate_status_stats(regions, comp['size'])

        # Format size string
        size_kb = comp['size'] // 1024
        if size_kb >= 1024:
            size_str = f"{size_kb // 1024}MB"
        else:
            size_str = f"{size_kb}KB"

        rom_data[comp['name']] = {
            'name': comp['name'],
            'size': comp['size'],
            'size_str': size_str,
            'width': width,
            'height': len(pixel_map),
            'pixels': pixel_map,
            'stats': stats,
            'bytes_per_pixel': BYTES_PER_PIXEL,
        }

    # Layout configuration
    margin = 25
    spacing_h = 30  # Horizontal spacing between columns
    spacing_v = 20  # Vertical spacing between ROMs in same column
    label_height = 50
    legend_height = 130
    title_height = 45

    # Calculate column dimensions
    # Left column: Main CPU + Table Data (stacked vertically)
    left_width = rom_data['Main CPU']['width']
    left_height = (rom_data['Main CPU']['height'] + label_height + spacing_v +
                   rom_data['Table Data']['height'] + label_height)

    # Right column: Sub CPU Boot + Sub CPU Payload + HDAE5000 (stacked vertically)
    right_width = max(rom_data['Sub CPU Boot']['width'],
                      rom_data['Sub CPU Payload']['width'],
                      rom_data['HDAE5000']['width'])
    right_height = (rom_data['Sub CPU Boot']['height'] + label_height + spacing_v +
                    rom_data['Sub CPU Payload']['height'] + label_height + spacing_v +
                    rom_data['HDAE5000']['height'] + label_height)

    # Total image dimensions
    content_height = max(left_height, right_height)
    img_width = margin * 2 + left_width + spacing_h + right_width
    img_height = title_height + content_height + legend_height + margin * 2

    # Create image
    img = Image.new('RGB', (img_width, img_height), (255, 255, 255))

    # Try to load fonts - larger sizes for readability
    try:
        title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 18)
        label_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 13)
        info_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 11)
        legend_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12)
    except:
        title_font = ImageFont.load_default()
        label_font = title_font
        info_font = title_font
        legend_font = title_font

    draw = ImageDraw.Draw(img)

    # Draw title
    title = f"KN5000 ROM Set - Disassembly Status"
    subtitle = f"(1 pixel = {BYTES_PER_PIXEL} bytes, area proportional to ROM size)"
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    draw.text(((img_width - title_width) // 2, margin // 2 + 2), title, fill=(0, 0, 0), font=title_font)

    subtitle_bbox = draw.textbbox((0, 0), subtitle, font=info_font)
    subtitle_width = subtitle_bbox[2] - subtitle_bbox[0]
    draw.text(((img_width - subtitle_width) // 2, margin // 2 + 24), subtitle, fill=(80, 80, 80), font=info_font)

    def draw_rom(rom, x, y):
        """Draw a ROM block with its pixels and label"""
        # Draw pixel map
        for py, row in enumerate(rom['pixels']):
            for px, color in enumerate(row):
                img.putpixel((x + px, y + py), color)

        # Draw border
        draw.rectangle(
            [x - 1, y - 1, x + rom['width'], y + rom['height']],
            outline=(0, 0, 0), width=1
        )

        # Draw label below
        label_y = y + rom['height'] + 4
        center_x = x + rom['width'] // 2

        # ROM name and size
        name_size = f"{rom['name']} ({rom['size_str']})"
        name_bbox = draw.textbbox((0, 0), name_size, font=label_font)
        name_width = name_bbox[2] - name_bbox[0]
        draw.text((center_x - name_width // 2, label_y), name_size, fill=(0, 0, 0), font=label_font)

        # Code percentage
        code_bytes, code_pct = rom['stats'].get(RegionStatus.DISASSEMBLED_CODE, (0, 0))
        pct_str = f"{code_pct:.1f}% disassembled"
        pct_bbox = draw.textbbox((0, 0), pct_str, font=info_font)
        pct_width = pct_bbox[2] - pct_bbox[0]
        color = (0, 130, 0) if code_pct > 30 else (100, 100, 100)
        draw.text((center_x - pct_width // 2, label_y + 18), pct_str, fill=color, font=info_font)

        return rom['height'] + label_height

    # Draw left column (Main CPU on top, Table Data below)
    left_x = margin
    left_y = title_height + margin

    h = draw_rom(rom_data['Main CPU'], left_x, left_y)
    left_y += h + spacing_v
    draw_rom(rom_data['Table Data'], left_x, left_y)

    # Draw right column (Sub CPU Boot, Sub CPU Payload, HDAE5000)
    right_x = margin + left_width + spacing_h
    right_y = title_height + margin

    h = draw_rom(rom_data['Sub CPU Boot'], right_x, right_y)
    right_y += h + spacing_v
    h = draw_rom(rom_data['Sub CPU Payload'], right_x, right_y)
    right_y += h + spacing_v
    draw_rom(rom_data['HDAE5000'], right_x, right_y)

    # Draw legend
    legend_y = title_height + content_height + margin + 15
    legend_x = margin

    draw.text((legend_x, legend_y), "Legend:", fill=(0, 0, 0), font=label_font)
    legend_y += 22

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
        ly = legend_y + row * 24

        color = STATUS_COLORS[status]
        draw.rectangle([lx, ly, lx + 16, ly + 16], fill=color, outline=(0, 0, 0))
        draw.text((lx + 22, ly + 1), label, fill=(0, 0, 0), font=legend_font)

    # Save image
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path, 'PNG')
    print(f"Generated: {output_path}")
    print(f"Image size: {img_width}x{img_height} pixels")

    # Print statistics
    print("\nROM Status Statistics:")
    print("=" * 70)
    print(f"\nBytes per pixel: {BYTES_PER_PIXEL} (constant for all ROMs)")

    for name in ['Main CPU', 'Table Data', 'Sub CPU Boot', 'Sub CPU Payload', 'HDAE5000']:
        rom = rom_data[name]
        print(f"\n{rom['name']} ({rom['size_str']}, {rom['width']}×{rom['height']} px):")
        for status, (bytes_count, pct) in sorted(rom['stats'].items(), key=lambda x: -x[1][1]):
            if pct > 0.1:
                print(f"  {status.value}: {pct:.1f}% ({bytes_count:,} bytes)")

if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(script_dir, '..', 'kn5000-docs', 'assets', 'images', 'rom-status-diagram.png')
    generate_rom_status_diagram(output_path)
