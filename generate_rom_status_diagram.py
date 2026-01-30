#!/usr/bin/env python3
"""
ROM Status Visualization Generator

Generates SVG diagrams showing the disassembly status of each memory
region in the KN5000 ROM set. Colors represent different status categories.

This script is part of the project's mandatory documentation workflow.
Run after making significant disassembly progress to update the website.

Usage:
    python generate_rom_status_diagram.py

Output:
    ../kn5000-docs/assets/images/rom-status-diagram.svg
"""

import os
import re
from dataclasses import dataclass
from typing import List, Dict
from enum import Enum

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

# Color scheme for each status (hex colors for SVG)
STATUS_COLORS = {
    RegionStatus.DISASSEMBLED_CODE: "#00b400",       # Green
    RegionStatus.KNOWN_DATA: "#0078c8",              # Blue
    RegionStatus.RAW_BYTES_UNKNOWN: "#dc3c3c",       # Red
    RegionStatus.RAW_BYTES_CODE: "#ff8c00",          # Orange
    RegionStatus.PADDING_UNUSED: "#808080",          # Gray
    RegionStatus.STRING_DATA: "#00c8c8",             # Cyan
    RegionStatus.BINARY_INCLUDE: "#a064c8",          # Purple
    RegionStatus.POINTER_TABLE: "#64b464",           # Light green
    RegionStatus.UNDETERMINED: "#ffdc50",            # Yellow
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

    # Track what we find
    consecutive_db_lines = 0

    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
    except FileNotFoundError:
        # Return single undetermined region for missing files
        return [MemoryRegion(base_addr, base_addr + rom_size, RegionStatus.UNDETERMINED)]

    for line_num, line in enumerate(lines):
        line = line.strip()

        # Skip empty lines and pure comments
        if not line or line.startswith(';'):
            continue

        # Check for ORG directive to track address
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
        label_match = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', line)
        if label_match:
            continue

        # Check for binclude (binary include)
        if 'binclude' in line.lower():
            if current_status != RegionStatus.BINARY_INCLUDE:
                if current_addr != region_start:
                    regions.append(MemoryRegion(region_start, current_addr, current_status))
                region_start = current_addr
                current_status = RegionStatus.BINARY_INCLUDE
            # Try to determine size from filename pattern like e02510_e0458f.bin
            filename_match = re.search(r'([0-9a-f]+)_([0-9a-f]+)\.bin', line, re.IGNORECASE)
            if filename_match:
                try:
                    start = int(filename_match.group(1), 16)
                    end = int(filename_match.group(2), 16)
                    current_addr += (end - start + 1)
                except ValueError:
                    current_addr += 1024  # Default estimate
            else:
                current_addr += 1024  # Default estimate
            continue

        # Check for dup pattern (padding/repeated data)
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
        string_match = re.match(r'^\s*db\s+"[^"]*"', line)
        if string_match:
            if current_status != RegionStatus.STRING_DATA:
                if current_addr != region_start:
                    regions.append(MemoryRegion(region_start, current_addr, current_status))
                region_start = current_addr
                current_status = RegionStatus.STRING_DATA
            # Estimate string length
            str_content = re.findall(r'"([^"]*)"', line)
            str_len = sum(len(s) for s in str_content)
            # Count additional bytes (null terminators, etc.)
            hex_bytes = re.findall(r'0[0-9A-Fa-f]+h', line)
            current_addr += str_len + len(hex_bytes)
            continue

        # Check for pointer/jump tables (dd with labels)
        ptr_match = re.match(r'^\s*dd\s+[A-Za-z_][A-Za-z0-9_]*', line)
        if ptr_match:
            if current_status != RegionStatus.POINTER_TABLE:
                if current_addr != region_start:
                    regions.append(MemoryRegion(region_start, current_addr, current_status))
                region_start = current_addr
                current_status = RegionStatus.POINTER_TABLE
            current_addr += 4  # dd is 4 bytes
            continue

        # Check for raw db/dw/dd data (hex bytes)
        raw_data_match = re.match(r'^\s*d[bwd]\s+([0-9A-Fa-f]+h)', line)
        if raw_data_match:
            # Count bytes in this line
            if line.strip().startswith('db'):
                byte_count = len(re.findall(r'[0-9A-Fa-f]+h', line))
                current_addr += byte_count
                consecutive_db_lines += 1

                # Multiple consecutive db lines with hex = raw bytes
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

        # Check for disassembled code instructions
        for instr in CODE_INSTRUCTIONS:
            if re.match(rf'^\s*{instr}\b', line, re.IGNORECASE):
                if current_status != RegionStatus.DISASSEMBLED_CODE:
                    if current_addr != region_start:
                        regions.append(MemoryRegion(region_start, current_addr, current_status))
                    region_start = current_addr
                    current_status = RegionStatus.DISASSEMBLED_CODE
                # Estimate instruction size (average ~3 bytes for TLCS-900)
                current_addr += 3
                break

    # Add final region
    if current_addr != region_start:
        regions.append(MemoryRegion(region_start, current_addr, current_status))

    # Fill to ROM size if needed
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

def calculate_status_stats(regions: List[MemoryRegion], rom_size: int) -> Dict[RegionStatus, float]:
    """Calculate percentage of ROM for each status"""
    stats = {status: 0 for status in RegionStatus}
    for region in regions:
        stats[region.status] += region.size

    # Convert to percentages
    for status in stats:
        stats[status] = (stats[status] / rom_size) * 100 if rom_size > 0 else 0

    return stats

def generate_svg_diagram(rom_infos: List[ROMInfo], output_path: str):
    """Generate an SVG diagram showing ROM status"""

    # Image dimensions
    img_width = 900
    img_height = 650
    margin = 40
    legend_height = 150
    rom_area_height = img_height - legend_height - margin * 2 - 30

    # Calculate total ROM size for proportional scaling
    total_size = sum(rom.size for rom in rom_infos)

    # Start SVG
    svg_parts = [
        f'<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{img_width}" height="{img_height}" viewBox="0 0 {img_width} {img_height}">',
        f'  <rect width="{img_width}" height="{img_height}" fill="white"/>',
        f'  <style>',
        f'    .title {{ font: bold 16px sans-serif; }}',
        f'    .rom-label {{ font: 11px sans-serif; text-anchor: middle; }}',
        f'    .legend-text {{ font: 10px sans-serif; }}',
        f'    .legend-title {{ font: bold 12px sans-serif; }}',
        f'    .stat-text {{ font: 9px sans-serif; text-anchor: middle; fill: #666; }}',
        f'  </style>',
    ]

    # Title
    svg_parts.append(f'  <text x="{img_width // 2}" y="25" class="title" text-anchor="middle">KN5000 ROM Set - Disassembly Status</text>')

    # Calculate rectangle positions
    total_width = img_width - margin * 2 - (len(rom_infos) - 1) * 20
    x_offset = margin

    for rom in rom_infos:
        # Width proportional to size ratio
        rom_width = int((rom.size / total_size) * total_width)
        rom_width = max(rom_width, 80)  # Minimum width

        rect_x = x_offset
        rect_y = margin + 30
        rect_height = rom_area_height - 60

        # Draw ROM rectangle border
        svg_parts.append(f'  <rect x="{rect_x}" y="{rect_y}" width="{rom_width}" height="{rect_height}" fill="none" stroke="black" stroke-width="2"/>')

        # Draw regions as horizontal bands
        current_y = rect_y
        for region in rom.regions:
            region_height = (region.size / rom.size) * rect_height
            if region_height < 0.5:
                region_height = 0.5

            color = STATUS_COLORS.get(region.status, "#c8c8c8")
            svg_parts.append(f'  <rect x="{rect_x}" y="{current_y:.1f}" width="{rom_width}" height="{region_height:.1f}" fill="{color}"/>')
            current_y += region_height

            if current_y >= rect_y + rect_height:
                break

        # ROM name (multi-line)
        name_lines = rom.name.split('\n')
        name_y = rect_y + rect_height + 15
        center_x = rect_x + rom_width // 2
        for i, line in enumerate(name_lines):
            svg_parts.append(f'  <text x="{center_x}" y="{name_y + i * 14}" class="rom-label">{line}</text>')

        # Calculate stats and show code percentage
        stats = calculate_status_stats(rom.regions, rom.size)
        code_pct = stats.get(RegionStatus.DISASSEMBLED_CODE, 0)
        stat_y = name_y + len(name_lines) * 14 + 5
        svg_parts.append(f'  <text x="{center_x}" y="{stat_y}" class="stat-text">{code_pct:.1f}% code</text>')

        x_offset += rom_width + 20

    # Legend
    legend_y = img_height - legend_height + 20
    legend_x = margin
    items_per_row = 3
    item_width = (img_width - margin * 2) // items_per_row

    svg_parts.append(f'  <text x="{legend_x}" y="{legend_y - 10}" class="legend-title">Legend:</text>')

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

    for i, (status, label) in enumerate(legend_items):
        row = i // items_per_row
        col = i % items_per_row
        lx = legend_x + col * item_width
        ly = legend_y + row * 28

        color = STATUS_COLORS[status]
        svg_parts.append(f'  <rect x="{lx}" y="{ly}" width="15" height="15" fill="{color}" stroke="black" stroke-width="1"/>')
        svg_parts.append(f'  <text x="{lx + 20}" y="{ly + 12}" class="legend-text">{label}</text>')

    # Close SVG
    svg_parts.append('</svg>')

    # Write to file
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        f.write('\n'.join(svg_parts))

    print(f"Generated: {output_path}")

    # Print statistics
    print("\nROM Status Statistics:")
    print("=" * 60)
    for rom in rom_infos:
        stats = calculate_status_stats(rom.regions, rom.size)
        name = rom.name.replace('\n', ' ')
        print(f"\n{name}:")
        for status, pct in sorted(stats.items(), key=lambda x: -x[1]):
            if pct > 0.1:
                print(f"  {status.value}: {pct:.1f}%")

def generate_rom_status_diagram(output_path: str):
    """Generate the complete ROM status diagram"""

    # Define ROM components with their sizes and source files
    rom_components = [
        {
            'name': 'Main CPU\n(2MB)',
            'size': 2 * 1024 * 1024,  # 2MB
            'asm_file': 'maincpu/kn5000_v10_program.asm',
            'base_addr': 0xE00000,
        },
        {
            'name': 'Sub CPU\nPayload\n(192KB)',
            'size': 192 * 1024,  # 192KB
            'asm_file': 'subcpu/kn5000_subprogram_v142.asm',
            'base_addr': 0x000000,
        },
        {
            'name': 'Sub CPU\nBoot\n(128KB)',
            'size': 128 * 1024,  # 128KB
            'asm_file': 'subcpu_boot/kn5000_subcpu_boot.asm',
            'base_addr': 0xFE0000,
        },
        {
            'name': 'Table Data\n(2MB)',
            'size': 2 * 1024 * 1024,  # 2MB (combined odd+even)
            'asm_file': 'table_data/kn5000_table_data.asm',
            'base_addr': 0x800000,
        },
        {
            'name': 'HDAE5000\n(512KB)',
            'size': 512 * 1024,  # 512KB
            'asm_file': 'hdae5000/hd-ae5000_v2_06i.asm',
            'base_addr': 0x280000,
        },
    ]

    # Parse all ROMs
    rom_infos = []
    for comp in rom_components:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        asm_path = os.path.join(script_dir, comp['asm_file'])
        regions = parse_assembly_file(asm_path, comp['base_addr'], comp['size'])
        regions = merge_adjacent_regions(regions)
        rom_infos.append(ROMInfo(
            name=comp['name'],
            size=comp['size'],
            regions=regions,
            base_addr=comp['base_addr']
        ))

    # Generate SVG
    generate_svg_diagram(rom_infos, output_path)

if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(script_dir, '..', 'kn5000-docs', 'assets', 'images', 'rom-status-diagram.svg')
    generate_rom_status_diagram(output_path)
