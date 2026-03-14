#!/usr/bin/env python3
"""Rename LABEL_XXXXXX placeholders in NAKA ui_widgets files to semantic names.

This script analyzes the NAKA widget structure to determine semantic names for labels.
Each NAKA widget entry typically has:
  .long NakaInst   # instance name string (contains handler/widget name)
  .long NakaDesc   # descriptor string (layout encoding)
  .long ParamStr   # parameter string table
  .long Proc       # handler procedure

Labels at the bottom of the file contain the actual string data.
Labels whose aligned_string contains a recognizable name (like "AcMstSong2GridBox")
become NakaInst_<name>. Their paired descriptor labels become NakaDesc_<name>.

Usage:
  python3 scripts/rename_naka_labels.py <file.s> [--dry-run]
  python3 scripts/rename_naka_labels.py <file.s> --apply

The script uses binary I/O to preserve Latin-1 encoding.
"""

import sys
import re
import os
from collections import OrderedDict


def read_file_binary(path):
    """Read file as binary, return lines as byte strings."""
    with open(path, 'rb') as f:
        return f.read()


def write_file_binary(path, data):
    """Write binary data to file."""
    with open(path, 'wb') as f:
        f.write(data)


def find_label_definitions(content_str):
    """Find all LABEL_XXXXXX: definitions and their associated content."""
    labels = {}
    for m in re.finditer(r'^(LABEL_[0-9A-F]{6}):\s*(.*)', content_str, re.MULTILINE):
        label = m.group(1)
        rest = m.group(2).strip()
        labels[label] = rest
    return labels


def find_label_references(content_str):
    """Find all .long LABEL_XXXXXX references and their context."""
    refs = []
    lines = content_str.split('\n')
    for i, line in enumerate(lines):
        m = re.match(r'\s*\.long\s+(LABEL_[0-9A-F]{6})\b', line)
        if m:
            refs.append((i, m.group(1)))
    return refs


def extract_aligned_string(rest):
    """Extract the string from an aligned_string directive."""
    m = re.match(r'aligned_string\s+"([^"]*)"', rest)
    if m:
        return m.group(1)
    return None


def analyze_widget_entries(content_str):
    """Parse NAKA widget entries to find paired instance/descriptor labels.

    Each widget entry has a pattern like:
        naka_header NAKA_TYPE_XXX
        .byte ...
        .long <inst_label>     # 1st .long: instance name
        .long <desc_label>     # 2nd .long: descriptor
        .long <param_label>    # 3rd .long: param string table
        .long <proc_handler>   # 4th .long: handler procedure

    Returns list of (inst_label, desc_label, proc_name) tuples.
    """
    lines = content_str.split('\n')
    entries = []

    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith('naka_header'):
            # Found a widget entry, scan forward for .long references
            longs = []
            j = i + 1
            while j < len(lines) and not lines[j].strip().startswith('naka_header'):
                lm = re.match(r'\s*\.long\s+(\S+)', lines[j])
                if lm:
                    longs.append(lm.group(1))
                # Stop if we hit a label definition (we're past the header area)
                if re.match(r'^[A-Za-z_].*:', lines[j]):
                    break
                j += 1

            if len(longs) >= 4:
                inst_label = longs[0]
                desc_label = longs[1]
                param_label = longs[2]
                proc_name = longs[3]
                entries.append((inst_label, desc_label, proc_name))
            elif len(longs) >= 2:
                # Some entries might have fewer .long refs
                entries.append((longs[0], longs[1] if len(longs) > 1 else None, None))

            i = j
        else:
            i += 1

    return entries


def determine_semantic_names(content_str, label_defs, widget_entries):
    """Determine semantic names for each LABEL_XXXXXX.

    Strategy:
    1. Labels with aligned_string containing a known name → NakaInst_<name>
    2. Labels paired as descriptors → NakaDesc_<name>
    3. Labels with empty strings that are descriptors → NakaDesc_<paired_inst_name>
    4. Labels that are just data → keep as is or use context
    """
    renames = {}

    # First pass: identify instance labels (those with meaningful name strings)
    inst_name_map = {}  # label -> extracted name
    for label, rest in label_defs.items():
        name = extract_aligned_string(rest)
        if name and len(name) > 2 and not all(c in 'XxJjCcKkNn^' for c in name):
            # This looks like a meaningful name (not a descriptor encoding)
            inst_name_map[label] = name

    # Second pass: use widget entries to pair inst/desc labels
    for inst_label, desc_label, proc_name in widget_entries:
        if not inst_label.startswith('LABEL_') and not desc_label:
            continue

        # Determine the base name from the instance label's string content
        base_name = None
        if inst_label in inst_name_map:
            base_name = inst_name_map[inst_label]
        elif proc_name and not proc_name.startswith('LABEL_'):
            # Use proc name minus "Proc" suffix
            base_name = proc_name.replace('Proc', '')

        if base_name and inst_label.startswith('LABEL_'):
            new_inst = f'NakaInst_{base_name}'
            if new_inst not in renames.values():
                renames[inst_label] = new_inst

        if base_name and desc_label and desc_label.startswith('LABEL_'):
            new_desc = f'NakaDesc_{base_name}'
            if new_desc not in renames.values():
                renames[desc_label] = new_desc

    # Third pass: handle remaining labels not in widget entries
    # These might be string labels referenced by the container or non-standard entries
    for label, rest in label_defs.items():
        if label in renames:
            continue
        name = extract_aligned_string(rest)
        if name and len(name) > 0:
            # Check if it's a descriptor string (contains layout chars)
            if all(c in 'XxJjCcKkNnPp^' for c in name) or name == '':
                continue  # Skip descriptor strings, they should be paired
            # It's a meaningful name not yet paired
            candidate = f'NakaInst_{name}'
            if candidate not in renames.values():
                renames[label] = candidate

    return renames


def apply_renames(content_bytes, renames):
    """Apply all renames to the file content, preserving binary encoding."""
    result = content_bytes
    # Sort by length descending to avoid partial replacements
    for old_name, new_name in sorted(renames.items(), key=lambda x: -len(x[0])):
        result = result.replace(old_name.encode('ascii'), new_name.encode('ascii'))
    return result


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    filepath = sys.argv[1]
    dry_run = '--dry-run' in sys.argv or '--apply' not in sys.argv

    content_bytes = read_file_binary(filepath)
    content_str = content_bytes.decode('latin-1')

    # Analyze
    label_defs = find_label_definitions(content_str)
    widget_entries = analyze_widget_entries(content_str)
    renames = determine_semantic_names(content_str, label_defs, widget_entries)

    if not renames:
        print(f"No labels to rename in {filepath}")
        return

    print(f"\nFile: {filepath}")
    print(f"Total LABEL_ definitions: {len(label_defs)}")
    print(f"Widget entries found: {len(widget_entries)}")
    print(f"Proposed renames: {len(renames)}")
    print()

    for old, new in sorted(renames.items()):
        print(f"  {old} -> {new}")

    if dry_run:
        print(f"\n[DRY RUN] No changes written. Use --apply to apply.")
    else:
        new_content = apply_renames(content_bytes, renames)
        write_file_binary(filepath, new_content)
        print(f"\nApplied {len(renames)} renames to {filepath}")


if __name__ == '__main__':
    main()
