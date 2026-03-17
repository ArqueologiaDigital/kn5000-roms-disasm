#!/usr/bin/env python3
"""
Rename codename-based directories and files to descriptive names.

Developer codenames in the KN5000 firmware:
  naka/  -> ui_widgets/     (UI widget descriptor system)
  toshi/ -> extensions/     (Extension device registration)
  hama/  -> factory_test/   (Factory diagnostic tests)

File renames within each directory also applied.
All include paths updated using binary I/O to preserve Latin-1.
"""

import os
import subprocess
import sys

MAINCPU_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'maincpu')
REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# All path renames, relative to maincpu/
# Format: old_path -> new_path
RENAMES = {
    # === naka/ -> ui_widgets/ ===
    # Main files get descriptive names
    'naka/naka_descriptors.s': 'ui_widgets/widget_descriptors.s',
    'naka/naka_dispatch.s': 'ui_widgets/widget_dispatch.s',
    'naka/naka_style_bitmap.s': 'ui_widgets/style_bitmaps.s',
    'naka/naka_block_007.s': 'ui_widgets/block_007.s',
    'naka/naka_block_012.s': 'ui_widgets/block_012.s',
    # Address-range files: drop naka_ prefix, keep address ranges
    'naka/naka_e0e974_e15b20.s': 'ui_widgets/e0e974_e15b20.s',
    'naka/naka_e176e4_e1a704.s': 'ui_widgets/e176e4_e1a704.s',
    'naka/naka_e1ab58_e1b7d2.s': 'ui_widgets/e1ab58_e1b7d2.s',
    'naka/naka_e2107c_e24034.s': 'ui_widgets/e2107c_e24034.s',
    'naka/naka_e27408_e27556.s': 'ui_widgets/e27408_e27556.s',
    'naka/naka_e27fa4_e30932.s': 'ui_widgets/e27fa4_e30932.s',
    'naka/naka_e55e38_e5a38e.s': 'ui_widgets/e55e38_e5a38e.s',
    'naka/naka_e812e8_e818e6.s': 'ui_widgets/e812e8_e818e6.s',
    'naka/naka_e81cce_e85f46.s': 'ui_widgets/e81cce_e85f46.s',
    'naka/naka_ea13cc_ea8c9e.s': 'ui_widgets/ea13cc_ea8c9e.s',
    'naka/naka_eb2afe_eb71be.s': 'ui_widgets/eb2afe_eb71be.s',
    'naka/naka_ed2a9c_ed2b96.s': 'ui_widgets/ed2a9c_ed2b96.s',
    'naka/naka_ed333c_ed35e4.s': 'ui_widgets/ed333c_ed35e4.s',
    'naka/naka_ed3cc0_ed665a.s': 'ui_widgets/ed3cc0_ed665a.s',
    'naka/naka_ed803c_eda02c.s': 'ui_widgets/ed803c_eda02c.s',
    'naka/naka_eee718_eef588.s': 'ui_widgets/eee718_eef588.s',

    # === toshi/ -> extensions/ ===
    'toshi/toshi_code.s': 'extensions/extension_init.s',
    'toshi/toshi_data.s': 'extensions/extension_data.s',

    # === hama/ -> factory_test/ ===
    'hama/hama_code.s': 'factory_test/test_init.s',
    'hama/hama_data.s': 'factory_test/test_data.s',
    'hama/fd_test_code.s': 'factory_test/fd_test_code.s',
    'hama/fd_test_data.s': 'factory_test/fd_test_data.s',
}


def create_directories():
    """Create new directories."""
    new_dirs = set()
    for new_path in RENAMES.values():
        d = os.path.dirname(new_path)
        if d:
            new_dirs.add(d)
    for d in sorted(new_dirs):
        full_path = os.path.join(MAINCPU_DIR, d)
        if not os.path.exists(full_path):
            os.makedirs(full_path)
            print(f"  Created: maincpu/{d}/")


def move_files():
    """Move files using git mv."""
    for old_path, new_path in sorted(RENAMES.items()):
        old_full = os.path.join(MAINCPU_DIR, old_path)
        new_full = os.path.join(MAINCPU_DIR, new_path)
        if not os.path.exists(old_full):
            print(f"  WARNING: {old_path} does not exist, skipping")
            continue
        result = subprocess.run(
            ['git', 'mv', old_full, new_full],
            cwd=REPO_DIR, capture_output=True, text=True
        )
        if result.returncode != 0:
            print(f"  ERROR: {result.stderr.strip()}")
            sys.exit(1)
        print(f"  {old_path} -> {new_path}")

    # Remove empty old directories
    for old_dir in ['naka', 'toshi', 'hama']:
        full = os.path.join(MAINCPU_DIR, old_dir)
        if os.path.exists(full):
            try:
                os.rmdir(full)
                print(f"  Removed empty directory: maincpu/{old_dir}/")
            except OSError:
                print(f"  WARNING: maincpu/{old_dir}/ not empty, skipping removal")


def update_includes():
    """Update all include paths in all .s files using binary I/O."""
    # Collect all .s files
    s_files = []
    for root, dirs, files in os.walk(MAINCPU_DIR):
        for f in files:
            if f.endswith('.s'):
                s_files.append(os.path.join(root, f))

    total_updates = 0
    for filepath in sorted(s_files):
        with open(filepath, 'rb') as f:
            content = f.read()

        original = content
        for old_path, new_path in RENAMES.items():
            old_bytes = f'"{old_path}"'.encode('ascii')
            new_bytes = f'"{new_path}"'.encode('ascii')
            if old_bytes in content:
                content = content.replace(old_bytes, new_bytes)

        if content != original:
            with open(filepath, 'wb') as f:
                f.write(content)
            rel = os.path.relpath(filepath, MAINCPU_DIR)
            changes = sum(
                original.count(f'"{old}"'.encode('ascii')) -
                content.count(f'"{old}"'.encode('ascii'))
                for old in RENAMES
            )
            total_updates += changes
            print(f"  Updated: maincpu/{rel} ({changes} paths)")

    print(f"  Total path updates: {total_updates}")


def main():
    print("=== Rename Codename Directories & Files ===\n")

    if not os.path.exists(os.path.join(MAINCPU_DIR, 'kn5000_v10_program.s')):
        print("ERROR: Cannot find kn5000_v10_program.s")
        sys.exit(1)

    print("Step 1: Create directories")
    create_directories()
    print()

    print("Step 2: Move files (git mv)")
    move_files()
    print()

    print("Step 3: Update include paths")
    update_includes()
    print()

    print("Done! Run: make clean && make all")


if __name__ == '__main__':
    main()
