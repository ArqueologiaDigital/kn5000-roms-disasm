#!/usr/bin/env python3
"""Rename LABEL_XXXXXX placeholders in NAKA ui_widgets files to semantic names.

Uses widget entry structure to properly pair instance labels (NakaInst_*) with
descriptor labels (NakaDesc_*).

Widget entry pattern:
    naka_header NAKA_TYPE_XXX
    .byte ...
    .long <inst_label>     # 1st .long
    .long <desc_label>     # 2nd .long
    [.long <param_label>]  # optional
    [.long <proc_handler>] # optional — proc name used as base name

Label naming:
    - Instance labels: NakaInst_<handler_name>
    - Descriptor labels: NakaDesc_<handler_name>
    - Other labels: contextual naming

Usage:
    python3 scripts/rename_naka_labels_v3.py analyze <file.s>
    python3 scripts/rename_naka_labels_v3.py apply <file.s>
"""

import sys
import re
import os
import glob


def read_file(path):
    with open(path, 'rb') as f:
        return f.read()


def write_file(path, data):
    with open(path, 'wb') as f:
        f.write(data)


def extract_aligned_string(text):
    m = re.search(r'aligned_string\s+"([^"]*)"', text)
    return m.group(1) if m else None


def find_name_after_label(lines, start_idx):
    """Look for the first aligned_string with a meaningful name after a label definition."""
    for j in range(start_idx, min(start_idx + 6, len(lines))):
        line = lines[j].strip()
        # Stop at next label definition (unless it's the same line)
        if j > start_idx and re.match(r'^[A-Za-z_].*:', line):
            break
        name = extract_aligned_string(line)
        if name and len(name) > 1:
            return name
    return None


def parse_widget_entries(content_str):
    """Parse widget entries to find (inst_label, desc_label, proc_name) tuples.

    Returns list of entries and a map from label→role+base_name.
    """
    lines = content_str.split('\n')
    entries = []

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
                lm = re.match(r'\s*\.long\s+(\S+)', jline)
                if lm:
                    longs.append(lm.group(1))
                j += 1

            entries.append(longs)
            i = j
        else:
            i += 1

    return entries


def collect_existing_naka_defs(repo_dir):
    """Collect all existing NakaInst/NakaDesc/NakaParam/NakaStr definitions."""
    existing = set()
    for pattern in ['maincpu/**/*.s', 'subcpu/**/*.s', 'hdae5000/**/*.s']:
        for fpath in glob.glob(os.path.join(repo_dir, pattern), recursive=True):
            with open(fpath, 'rb') as f:
                content = f.read().decode('latin-1')
            for m in re.finditer(r'^(Naka(?:Inst|Desc|Param|Str)_\w+):', content, re.MULTILINE):
                existing.add(m.group(1))
    return existing


def compute_renames(content_str, existing_defs=None):
    """Compute all label renames using widget entry structure."""
    lines = content_str.split('\n')
    renames = {}

    # Parse widget entries
    entries = parse_widget_entries(content_str)

    # Find label definitions and their string content
    label_defs = {}
    for i, line in enumerate(lines):
        m = re.match(r'^(LABEL_[0-9A-F]{6}):\s*(.*)', line)
        if m:
            label = m.group(1)
            name = find_name_after_label(lines, i)
            label_defs[label] = name

    # Build rename map using widget entries
    # Each entry: [inst_label, desc_label, param, proc]
    used_names = set(existing_defs) if existing_defs else set()

    for longs in entries:
        if len(longs) < 2:
            continue

        inst_label = longs[0]
        desc_label = longs[1]
        proc_name = longs[3] if len(longs) >= 4 else None

        # Determine the base name
        # Priority: proc name (minus "Proc" suffix) > instance label string
        # Proc name is more reliable because string content can belong to a
        # different widget (data is shared/reused across entries)
        base_name = None

        if proc_name and not proc_name.startswith('LABEL_'):
            base_name = re.sub(r'Proc$', '', proc_name)

        if not base_name and inst_label.startswith('LABEL_') and inst_label in label_defs:
            name = label_defs[inst_label]
            if name and not is_descriptor_string(name):
                base_name = name

        if not base_name:
            # Try desc label name
            if desc_label.startswith('LABEL_') and desc_label in label_defs:
                name = label_defs[desc_label]
                if name and not is_descriptor_string(name):
                    base_name = name

        if not base_name:
            continue

        # Sanitize base name for use in assembly labels
        base_name = sanitize_label_name(base_name)
        if not base_name or len(base_name) < 2:
            continue

        # Rename instance label
        if inst_label.startswith('LABEL_'):
            new_name = f'NakaInst_{base_name}'
            if new_name in used_names:
                new_name = f'{new_name}_{inst_label[-6:]}'
            used_names.add(new_name)
            renames[inst_label] = new_name

        # Rename descriptor label
        if desc_label.startswith('LABEL_'):
            new_name = f'NakaDesc_{base_name}'
            if new_name in used_names:
                new_name = f'{new_name}_{desc_label[-6:]}'
            used_names.add(new_name)
            renames[desc_label] = new_name

        # Rename param label if it's a LABEL_
        if len(longs) >= 3 and longs[2].startswith('LABEL_'):
            param_label = longs[2]
            if param_label not in renames:
                new_name = f'NakaParam_{base_name}'
                if new_name in used_names:
                    new_name = f'{new_name}_{param_label[-6:]}'
                used_names.add(new_name)
                renames[param_label] = new_name

    # Handle remaining label definitions not covered by widget entries
    # These are labels defined in this file but only referenced from other entries
    for label, name in label_defs.items():
        if label in renames:
            continue
        if name and len(name) > 1 and not is_descriptor_string(name):
            clean_name = sanitize_label_name(name)
            if not clean_name or len(clean_name) < 2:
                continue
            new_name = f'NakaInst_{clean_name}'
            if new_name in used_names:
                new_name = f'{new_name}_{label[-6:]}'
            used_names.add(new_name)
            renames[label] = new_name

    return renames


def sanitize_label_name(name, max_len=50):
    """Sanitize a string to be a valid assembly label name.
    Replace spaces and special chars with underscores, strip non-alphanumeric.
    Truncate to max_len to avoid absurdly long label names."""
    if not name:
        return name
    # Replace spaces and special chars
    result = re.sub(r'[^A-Za-z0-9_]', '_', name)
    # Collapse multiple underscores
    result = re.sub(r'_+', '_', result)
    # Strip trailing underscores
    result = result.strip('_')
    # Truncate if too long (cut at last underscore before limit)
    if len(result) > max_len:
        truncated = result[:max_len]
        last_underscore = truncated.rfind('_')
        if last_underscore > 20:
            result = truncated[:last_underscore]
        else:
            result = truncated
    return result


def is_valid_label_name(name):
    """Check if a name is valid for use in an assembly label."""
    if not name or len(name) < 2:
        return False
    # Must not contain spaces or special chars
    if not re.match(r'^[A-Za-z0-9_]+$', name):
        return False
    return True


def is_descriptor_string(s):
    """Check if a string is a descriptor encoding (layout chars only)."""
    if not s:
        return True
    # Descriptor strings consist mainly of layout chars like X, j, n, c, k, ^, etc.
    desc_chars = set('XxJjCcKkNnPp^')
    return all(c in desc_chars for c in s)


def find_all_files_with_label(label, search_dir):
    """Find all .s files referencing a label."""
    files = []
    label_bytes = label.encode('ascii')
    for pattern in ['maincpu/**/*.s', 'subcpu/**/*.s', 'hdae5000/**/*.s']:
        for fpath in glob.glob(os.path.join(search_dir, pattern), recursive=True):
            with open(fpath, 'rb') as f:
                if label_bytes in f.read():
                    files.append(fpath)
    return files


def apply_renames_to_content(content_bytes, renames):
    """Apply renames preserving binary encoding.

    Uses regex word-boundary matching to avoid substring replacement issues
    (e.g., replacing LABEL_E80048 inside LABEL_E80048_suffix).
    """
    import re as _re
    content_str = content_bytes.decode('latin-1')
    # Sort by length descending to handle longer names first
    for old_name, new_name in sorted(renames.items(), key=lambda x: -len(x[0])):
        # Word boundary: label chars are [A-Za-z0-9_], so match only whole tokens
        pattern = _re.escape(old_name) + r'(?![A-Za-z0-9_])'
        content_str = _re.sub(pattern, new_name, content_str)
    return content_str.encode('latin-1')


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    command = sys.argv[1]
    filepath = sys.argv[2]
    repo_dir = '/mnt/shared/kn5000-roms-disasm'

    content_bytes = read_file(filepath)
    content_str = content_bytes.decode('latin-1')

    # Collect existing definitions to avoid cross-file collisions
    existing_defs = collect_existing_naka_defs(repo_dir)
    renames = compute_renames(content_str, existing_defs)

    if not renames:
        print(f"No labels to rename in {filepath}")
        return

    if command == 'analyze':
        print(f"\nFile: {filepath}")
        print(f"Proposed renames: {len(renames)}")
        print()
        for old, new in sorted(renames.items()):
            print(f"  {old} -> {new}")
        print()

        # Cross-file references
        print("Cross-file references:")
        for label in sorted(renames.keys()):
            files = find_all_files_with_label(label, repo_dir)
            other_files = [f for f in files if os.path.abspath(f) != os.path.abspath(filepath)]
            if other_files:
                for f in other_files:
                    print(f"  {label} also in: {f}")

    elif command == 'apply':
        all_files = set()
        all_files.add(os.path.abspath(filepath))
        for label in renames:
            for f in find_all_files_with_label(label, repo_dir):
                all_files.add(os.path.abspath(f))

        print(f"\nApplying {len(renames)} renames across {len(all_files)} files:")
        for fpath in sorted(all_files):
            data = read_file(fpath)
            new_data = apply_renames_to_content(data, renames)
            if data != new_data:
                write_file(fpath, new_data)
                changes = sum(1 for old in renames if old.encode('ascii') in data)
                print(f"  Updated {fpath} ({changes} labels)")
            else:
                print(f"  No changes: {fpath}")

        print(f"\nDone. {len(renames)} labels renamed.")


if __name__ == '__main__':
    main()
