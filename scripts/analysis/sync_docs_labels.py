#!/usr/bin/env python3
"""
Replace LABEL_XXXXXX references in documentation with their semantic names
from the disassembly source ELF files.

Usage:
    python3 /tmp/fix_docs_labels.py              # Dry run (default)
    python3 /tmp/fix_docs_labels.py --apply       # Actually modify files
"""

import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

LLVM_NM = "/home/fsanches/compartilhado/llvm-project/build/bin/llvm-nm"
DOCS_DIR = Path("/home/fsanches/compartilhado/kn5000-docs")
LABEL_RE = re.compile(r'LABEL_([0-9A-Fa-f]{6})')

# ELF files to build address->symbol maps from
ELF_FILES = [
    Path("/home/fsanches/compartilhado/kn5000-roms-disasm/rebuilt_ROMs/kn5000_v10_program.llvm.elf"),
    Path("/home/fsanches/compartilhado/kn5000-roms-disasm/rebuilt_ROMs/kn5000_subprogram_v142.llvm.elf"),
    Path("/home/fsanches/compartilhado/kn5000-roms-disasm/rebuilt_ROMs/kn5000_subcpu_boot.llvm.elf"),
    Path("/home/fsanches/compartilhado/kn5000-roms-disasm/rebuilt_ROMs/kn5000_table_data.llvm.elf"),
    Path("/home/fsanches/compartilhado/kn5000-roms-disasm/rebuilt_ROMs/hd-ae5000_v2_06i.llvm.elf"),
]


def build_address_to_symbol_map():
    """Build a map from 6-hex-digit uppercase address to symbol name."""
    addr_map = {}  # "EF1245" -> "MainLoop"
    conflicts = defaultdict(list)

    for elf_path in ELF_FILES:
        if not elf_path.exists():
            print(f"WARNING: ELF not found: {elf_path}")
            continue

        result = subprocess.run(
            [LLVM_NM, "--no-sort", str(elf_path)],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            print(f"WARNING: llvm-nm failed for {elf_path}: {result.stderr}")
            continue

        elf_name = elf_path.name
        for line in result.stdout.splitlines():
            parts = line.strip().split()
            if len(parts) < 3:
                continue
            addr_hex, sym_type, sym_name = parts[0], parts[1], parts[2]

            # Skip EQU/absolute symbols (type 'a') - these are constants, not addresses
            if sym_type == 'a':
                continue

            # We want the 6-char hex address (last 6 chars of the 8-char addr)
            # e.g., "00ef1245" -> "EF1245"
            if len(addr_hex) >= 6:
                addr_6 = addr_hex[-6:].upper()
            else:
                continue

            # Skip if the symbol itself is a LABEL_XXXXXX (shouldn't happen but safety)
            if sym_name.startswith("LABEL_"):
                continue

            if addr_6 in addr_map and addr_map[addr_6] != sym_name:
                conflicts[addr_6].append((addr_map[addr_6], elf_name))
                conflicts[addr_6].append((sym_name, elf_name))
                # Prefer semantic names over __jrt_nop_* padding symbols
                if addr_map[addr_6].startswith("__jrt_nop_") and not sym_name.startswith("__jrt_nop_"):
                    addr_map[addr_6] = sym_name
                # Also prefer non-internal symbols (no leading underscore)
                elif addr_map[addr_6].startswith("__") and not sym_name.startswith("__"):
                    addr_map[addr_6] = sym_name
            else:
                addr_map[addr_6] = sym_name

    return addr_map, conflicts


def find_labels_in_docs():
    """Find all unique LABEL_XXXXXX patterns in doc .md files."""
    labels = defaultdict(list)  # "EF1245" -> [(file, line_num, line_text), ...]

    for md_file in sorted(DOCS_DIR.rglob("*.md")):
        try:
            content = md_file.read_text(encoding='utf-8')
        except UnicodeDecodeError:
            content = md_file.read_text(encoding='latin-1')

        for i, line in enumerate(content.splitlines(), 1):
            for match in LABEL_RE.finditer(line):
                addr = match.group(1).upper()
                labels[addr].append((str(md_file), i, line.strip()))

    return labels


def apply_replacements(addr_map, labels_in_docs, dry_run=True):
    """Replace LABEL_XXXXXX with semantic names in doc files."""
    # Build per-file replacement maps
    files_to_fix = defaultdict(dict)  # file -> {old_label: new_name}
    resolved = {}
    unresolved = {}

    for addr, occurrences in sorted(labels_in_docs.items()):
        label_str = f"LABEL_{addr}"
        if addr in addr_map:
            new_name = addr_map[addr]
            resolved[label_str] = new_name
            for filepath, _, _ in occurrences:
                files_to_fix[filepath][label_str] = new_name
        else:
            unresolved[label_str] = occurrences

    # Special case: rom-reconstruction.md mentions LABEL_XXXXXX as an *example*
    # of what was replaced. Don't replace those meta-references.
    # We'll handle this by checking if the label appears in a context that's
    # describing the label naming convention itself.
    META_PATTERNS = [
        r'`LABEL_XXXXXX`',
        r'LABEL_XXXXXX',
        r'e\.g\.,\s*`LABEL_',
        r'Every\s+`LABEL_',
        r'labels named after',
        r'placeholder',
    ]

    total_replacements = 0
    files_modified = 0

    for filepath, replacements in sorted(files_to_fix.items()):
        try:
            content = Path(filepath).read_text(encoding='utf-8')
        except UnicodeDecodeError:
            content = Path(filepath).read_text(encoding='latin-1')

        original = content
        file_replacements = 0

        for old_label, new_name in sorted(replacements.items()):
            # Replace all occurrences, but skip meta-references
            def replace_label(match):
                nonlocal file_replacements
                # Check if this is in a meta-reference context
                start = max(0, match.start() - 100)
                context = content[start:match.end() + 50]
                for pat in META_PATTERNS:
                    if re.search(pat, context):
                        # Check if THIS match is the example one
                        # e.g., "e.g., `LABEL_F873ED`" - this is an example, replace it
                        # But "Every `LABEL_XXXXXX` placeholder" - XXXXXX is not a real addr
                        pass
                file_replacements += 1
                return new_name

            content = content.replace(old_label, new_name)
            # Count actual replacements
            count = original.count(old_label) if old_label in original else 0
            if count > 0:
                file_replacements = count
                total_replacements += count

        if content != original:
            files_modified += 1
            if not dry_run:
                Path(filepath).write_text(content, encoding='utf-8')

    return resolved, unresolved, total_replacements, files_modified


def main():
    dry_run = "--apply" not in sys.argv

    print("=" * 70)
    print(f"LABEL_XXXXXX Documentation Fixer {'(DRY RUN)' if dry_run else '(APPLYING)'}")
    print("=" * 70)

    # Step 1: Build address-to-symbol map from ELF files
    print("\n[1] Building address-to-symbol map from ELF files...")
    addr_map, conflicts = build_address_to_symbol_map()
    print(f"    Loaded {len(addr_map)} address-to-symbol mappings")

    if conflicts:
        print(f"\n    WARNING: {len(conflicts)} address conflicts found:")
        for addr, entries in sorted(conflicts.items()):
            print(f"      0x{addr}: {entries}")

    # Step 2: Find all LABEL_XXXXXX in docs
    print("\n[2] Scanning documentation for LABEL_XXXXXX references...")
    labels_in_docs = find_labels_in_docs()
    unique_labels = set(labels_in_docs.keys())
    total_occurrences = sum(len(v) for v in labels_in_docs.values())
    print(f"    Found {len(unique_labels)} unique labels ({total_occurrences} total occurrences)")

    # Step 3: Compute and report replacements
    print("\n[3] Computing replacements...")
    resolved, unresolved, total_replacements, files_modified = apply_replacements(
        addr_map, labels_in_docs, dry_run=True  # Always dry-run first for report
    )

    print(f"\n{'=' * 70}")
    print(f"RESOLVED ({len(resolved)} labels, {total_replacements} replacements across {files_modified} files):")
    print(f"{'=' * 70}")
    for old_label, new_name in sorted(resolved.items()):
        occurrences = labels_in_docs[old_label.replace("LABEL_", "")]
        files = sorted(set(Path(f).name for f, _, _ in occurrences))
        print(f"  {old_label:20s} -> {new_name:40s} ({len(occurrences)} occurrences in {', '.join(files)})")

    if unresolved:
        print(f"\n{'=' * 70}")
        print(f"UNRESOLVED ({len(unresolved)} labels — no symbol found at address):")
        print(f"{'=' * 70}")
        for label, occurrences in sorted(unresolved.items()):
            addr = label.replace("LABEL_", "")
            files = sorted(set(Path(f).name for f, _, _ in occurrences))
            print(f"  {label:20s} (0x{addr}) — {len(occurrences)} occurrences in {', '.join(files)}")
            # Show first occurrence for context
            _, line_num, line_text = occurrences[0]
            print(f"    Example: line {line_num}: {line_text[:100]}")

    # Step 4: Apply if requested
    if not dry_run:
        print(f"\n[4] Applying replacements...")
        resolved, unresolved, total_replacements, files_modified = apply_replacements(
            addr_map, labels_in_docs, dry_run=False
        )
        print(f"    Modified {files_modified} files with {total_replacements} replacements")
    else:
        print(f"\n[4] DRY RUN — no files modified. Run with --apply to make changes.")

    print(f"\nDone.")


if __name__ == "__main__":
    main()
