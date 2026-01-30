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

def calculate_dimensions(rom_size: int, bytes_per_pixel: int, target_aspect: float = 1.5) -> Tuple[int, int]:
    """Calculate width and height for a ROM to maintain aspect ratio"""
    total_pixels = rom_size // bytes_per_pixel
    # Target aspect ratio (width/height)
    # width * height = total_pixels
    # width / height = target_aspect
    # width = target_aspect * height
    # target_aspect * height * height = total_pixels
    # height = sqrt(total_pixels / target_aspect)
    height = int(math.sqrt(total_pixels / target_aspect))
    width = total_pixels // height
    # Adjust to be divisible by 8 for cleaner display
    width = ((width + 7) // 8) * 8
    height = (total_pixels + width - 1) // width
    return width, height

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
            'name': 'Sub CPU Payload',
            'size': 192 * 1024,  # 192KB
            'asm_file': 'subcpu/kn5000_subprogram_v142.asm',
            'base_addr': 0x000000,
        },
        {
            'name': 'Sub CPU Boot',
            'size': 128 * 1024,  # 128KB
            'asm_file': 'subcpu_boot/kn5000_subcpu_boot.asm',
            'base_addr': 0xFE0000,
        },
        {
            'name': 'Table Data',
            'size': 2 * 1024 * 1024,  # 2MB
            'asm_file': 'table_data/kn5000_table_data.asm',
            'base_addr': 0x800000,
        },
        {
            'name': 'HDAE5000',
            'size': 512 * 1024,  # 512KB
            'asm_file': 'hdae5000/hd-ae5000_v2_06i.asm',
            'base_addr': 0x280000,
        },
    ]

    # Parse all ROMs and create pixel maps
    rom_data = []
    script_dir = os.path.dirname(os.path.abspath(__file__))

    for comp in rom_components:
        asm_path = os.path.join(script_dir, comp['asm_file'])
        regions = parse_assembly_file(asm_path, comp['base_addr'], comp['size'])
        regions = merge_adjacent_regions(regions)

        # Calculate dimensions with consistent bytes_per_pixel
        width, height = calculate_dimensions(comp['size'], BYTES_PER_PIXEL)

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

        rom_data.append({
            'name': comp['name'],
            'size': comp['size'],
            'size_str': size_str,
            'width': width,
            'height': len(pixel_map),
            'pixels': pixel_map,
            'stats': stats,
            'bytes_per_pixel': BYTES_PER_PIXEL,
        })

    # Calculate image dimensions
    margin = 20
    spacing = 25
    label_height = 55
    legend_height = 100
    title_height = 35

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
        title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 14)
        label_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 10)
        small_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 9)
    except:
        title_font = ImageFont.load_default()
        label_font = title_font
        small_font = title_font

    draw = ImageDraw.Draw(img)

    # Draw title
    title = f"KN5000 ROM Set - Disassembly Status (1 pixel = {BYTES_PER_PIXEL} bytes, area proportional to ROM size)"
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

        # ROM name and size
        name_size = f"{rom['name']} ({rom['size_str']})"
        name_bbox = draw.textbbox((0, 0), name_size, font=label_font)
        name_width = name_bbox[2] - name_bbox[0]
        draw.text((center_x - name_width // 2, label_y), name_size, fill=(0, 0, 0), font=label_font)

        # Dimensions
        dim_str = f"{rom['width']}×{rom['height']} px"
        dim_bbox = draw.textbbox((0, 0), dim_str, font=small_font)
        dim_width = dim_bbox[2] - dim_bbox[0]
        draw.text((center_x - dim_width // 2, label_y + 14), dim_str, fill=(100, 100, 100), font=small_font)

        # Code percentage
        code_bytes, code_pct = rom['stats'].get(RegionStatus.DISASSEMBLED_CODE, (0, 0))
        pct_str = f"{code_pct:.1f}% code"
        pct_bbox = draw.textbbox((0, 0), pct_str, font=small_font)
        pct_width = pct_bbox[2] - pct_bbox[0]
        color = (0, 140, 0) if code_pct > 50 else (0, 100, 0)
        draw.text((center_x - pct_width // 2, label_y + 28), pct_str, fill=color, font=small_font)

        x_offset += rom['width'] + spacing

    # Draw legend
    legend_y = rom_y + max_rom_height + label_height + 5
    legend_x = margin

    draw.text((legend_x, legend_y), "Legend:", fill=(0, 0, 0), font=label_font)
    legend_y += 18

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
        ly = legend_y + row * 20

        color = STATUS_COLORS[status]
        draw.rectangle([lx, ly, lx + 12, ly + 12], fill=color, outline=(0, 0, 0))
        draw.text((lx + 16, ly), label, fill=(0, 0, 0), font=small_font)

    # Save image
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path, 'PNG')
    print(f"Generated: {output_path}")
    print(f"Image size: {img_width}x{img_height} pixels")

    # Print statistics and verify proportions
    print("\nROM Status Statistics:")
    print("=" * 70)
    print(f"\nBytes per pixel: {BYTES_PER_PIXEL} (constant for all ROMs)")
    print("\nProportions verification:")
    for rom in rom_data:
        pixel_area = rom['width'] * rom['height']
        print(f"  {rom['name']}: {rom['size_str']} = {rom['size']:,} bytes → {pixel_area:,} pixels ({rom['width']}×{rom['height']})")

    print("\nSize ratios:")
    base_rom = rom_data[0]  # Main CPU as reference
    for rom in rom_data[1:]:
        size_ratio = base_rom['size'] / rom['size']
        pixel_ratio = (base_rom['width'] * base_rom['height']) / (rom['width'] * rom['height'])
        print(f"  Main CPU / {rom['name']}: size={size_ratio:.2f}x, pixels={pixel_ratio:.2f}x")

    print("\n" + "=" * 70)
    for rom in rom_data:
        print(f"\n{rom['name']} ({rom['size_str']}):")
        for status, (bytes_count, pct) in sorted(rom['stats'].items(), key=lambda x: -x[1][1]):
            if pct > 0.1:
                print(f"  {status.value}: {pct:.1f}% ({bytes_count:,} bytes)")

if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(script_dir, '..', 'kn5000-docs', 'assets', 'images', 'rom-status-diagram.png')
    generate_rom_status_diagram(output_path)
