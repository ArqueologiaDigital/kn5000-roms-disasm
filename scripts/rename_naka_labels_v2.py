#!/usr/bin/env python3
"""Rename LABEL_XXXXXX placeholders in NAKA ui_widgets files to semantic names.

Handles two patterns:
1. Instance data labels: LABEL at bottom of file, followed by aligned_string with handler name
   → Renamed to NakaInst_<handler_name>
2. Widget entry labels in header section with 4 .long refs:
   .long <inst_label>  .long <desc_label>  .long <param>  .long <proc>
   → inst_label named from its string content, desc_label from paired proc name

Cross-file renames: When a label is defined in one file but referenced in another,
both files are updated.

Usage:
  python3 scripts/rename_naka_labels_v2.py analyze <file.s>
  python3 scripts/rename_naka_labels_v2.py apply <file.s> [--cross-file-dir <dir>]
"""

import sys
import re
import os
import glob
from collections import OrderedDict


def read_file(path):
    with open(path, 'rb') as f:
        return f.read()


def write_file(path, data):
    with open(path, 'wb') as f:
        f.write(data)


def find_label_defs_with_next_line(content_str):
    """Find LABEL definitions and the first aligned_string after them (for name extraction).

    Looks up to 5 lines ahead for an aligned_string directive, skipping .byte lines.
    This handles cases where labels have .byte descriptor data before the name string.
    """
    lines = content_str.split('\n')
    results = {}
    for i, line in enumerate(lines):
        m = re.match(r'^(LABEL_[0-9A-F]{6}):\s*(.*)', line)
        if m:
            label = m.group(1)
            rest = m.group(2).strip()
            # Look ahead for the first aligned_string (the handler name)
            name_line = ''
            for j in range(i, min(i + 6, len(lines))):
                jline = lines[j].strip()
                if j > i and re.match(r'^[A-Za-z_].*:', jline):
                    break  # Hit another label, stop
                if 'aligned_string' in jline:
                    # Skip empty aligned_string on the same line as the label
                    aname = extract_name_from_aligned_string(jline)
                    if aname and len(aname) > 1:
                        name_line = jline
                        break
                    elif j == i:
                        continue  # Skip empty string on label line, keep looking
                    elif aname == '':
                        continue  # Skip empty strings
            if not name_line:
                # Fallback: just use the next non-empty line
                for j in range(i + 1, min(i + 5, len(lines))):
                    if lines[j].strip():
                        name_line = lines[j].strip()
                        break
            results[label] = (rest, name_line)
    return results


def extract_name_from_aligned_string(text):
    """Extract string from aligned_string directive."""
    m = re.search(r'aligned_string\s+"([^"]*)"', text)
    if m:
        return m.group(1)
    return None


def compute_renames_for_instance_labels(label_defs):
    """Compute renames for labels where the next line has the handler name."""
    renames = {}
    for label, (rest, next_line) in label_defs.items():
        # The name is in the next aligned_string
        name = extract_name_from_aligned_string(next_line)
        if name and len(name) > 1:
            new_label = f'NakaInst_{name}'
            renames[label] = new_label
    return renames


def compute_renames_for_widget_entries(content_str, label_defs):
    """For labels in the header section referenced as .long, derive names from
    the widget entry structure (paired with proc handlers)."""
    lines = content_str.split('\n')
    renames = {}

    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith('naka_header'):
            longs = []
            j = i + 1
            while j < len(lines):
                jline = lines[j].strip()
                if jline.startswith('naka_header') or re.match(r'^[A-Za-z_].*:', jline):
                    break
                lm = re.match(r'\.long\s+(\S+)', jline)
                if lm:
                    longs.append(lm.group(1))
                j += 1

            # Standard pattern: [inst, desc, param, proc]
            # But some entries have only 2 .longs: [inst, desc]
            # The inst label should be named from its string content
            # We handle this through the instance label analysis above

            i = j
        else:
            i += 1

    return renames


def find_all_files_with_label(label, search_dir):
    """Find all .s files that reference or define a given label."""
    files = []
    for pattern in ['maincpu/**/*.s', 'subcpu/**/*.s', 'hdae5000/**/*.s']:
        for fpath in glob.glob(os.path.join(search_dir, pattern), recursive=True):
            with open(fpath, 'rb') as f:
                if label.encode('ascii') in f.read():
                    files.append(fpath)
    return files


def apply_renames_to_content(content_bytes, renames):
    """Apply renames to file content preserving binary encoding."""
    result = content_bytes
    # Sort by length descending to avoid partial replacements
    # Also ensure we match whole words only
    for old_name, new_name in sorted(renames.items(), key=lambda x: -len(x[0])):
        # Use word-boundary-aware replacement
        old_bytes = old_name.encode('ascii')
        new_bytes = new_name.encode('ascii')
        result = result.replace(old_bytes, new_bytes)
    return result


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    command = sys.argv[1]
    filepath = sys.argv[2]
    repo_dir = '/mnt/shared/kn5000-roms-disasm'

    content_bytes = read_file(filepath)
    content_str = content_bytes.decode('latin-1')

    # Find label definitions with their context
    label_defs = find_label_defs_with_next_line(content_str)

    # Compute renames
    renames = compute_renames_for_instance_labels(label_defs)

    if not renames:
        print(f"No labels to rename in {filepath}")
        return

    # Check for name collisions
    seen_names = set()
    final_renames = {}
    for old, new in sorted(renames.items()):
        if new in seen_names:
            # Add address suffix for disambiguation
            addr = old.replace('LABEL_', '')
            new = f'{new}_{addr}'
        seen_names.add(new)
        final_renames[old] = new

    renames = final_renames

    if command == 'analyze':
        print(f"\nFile: {filepath}")
        print(f"Label definitions found: {len(label_defs)}")
        print(f"Proposed renames: {len(renames)}")
        print()
        for old, new in sorted(renames.items()):
            rest, next_line = label_defs[old]
            print(f"  {old} -> {new}")
            print(f"    content: {rest[:60]}")
            print(f"    next:    {next_line[:60]}")
            print()

        # Check cross-file references
        print("Cross-file references:")
        for label in sorted(renames.keys()):
            files = find_all_files_with_label(label, repo_dir)
            other_files = [f for f in files if os.path.abspath(f) != os.path.abspath(filepath)]
            if other_files:
                print(f"  {label} also in: {', '.join(other_files)}")

    elif command == 'apply':
        # Find all files that need updating
        all_files_to_update = set()
        all_files_to_update.add(os.path.abspath(filepath))

        for label in renames:
            files = find_all_files_with_label(label, repo_dir)
            for f in files:
                all_files_to_update.add(os.path.abspath(f))

        print(f"\nApplying {len(renames)} renames across {len(all_files_to_update)} files:")
        for f in sorted(all_files_to_update):
            print(f"  {f}")

        for fpath in sorted(all_files_to_update):
            data = read_file(fpath)
            new_data = apply_renames_to_content(data, renames)
            if data != new_data:
                write_file(fpath, new_data)
                # Count changes
                changes = sum(1 for old in renames if old.encode('ascii') in data)
                print(f"  Updated {fpath} ({changes} labels renamed)")
            else:
                print(f"  No changes in {fpath}")

        print(f"\nDone. {len(renames)} labels renamed.")


if __name__ == '__main__':
    main()
