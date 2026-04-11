#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in widget_dispatch.s (Batch 2).
Covers display script nodes, ToneKit params, widget params, UIState configs.
Uses binary I/O to preserve Latin-1 bytes."""

import os
import re

REPO = '/home/fsanches/compartilhado/kn5000-roms-disasm'
TARGET_FILE = os.path.join(REPO, 'maincpu/ui_widgets/widget_dispatch.s')

# Read file to discover remaining labels and build renames
def build_renames():
    renames = {}

    # Read the file to get all remaining LABEL_ definitions
    with open(TARGET_FILE, 'rb') as f:
        content = f.read().decode('latin-1')

    # Find all remaining LABEL_ definitions
    defined = re.findall(r'^(LABEL_([0-9A-F]{6})):', content, re.MULTILINE)

    for label, addr_hex in defined:
        addr = int(addr_hex, 16)

        # Display script nodes: EE4278 - EE426C (already done in batch 1 up to EE426C)
        # These are continuation of display script nodes
        if 0xEE4278 <= addr <= 0xEE44CA:
            idx = (addr - 0xEE4278) // 0x12  # rough index
            renames[label] = f'DisplayScript_Node_Cont_{addr_hex}'

        # ToneKit parameter data blocks: EE4A10
        elif addr == 0xEE4A10:
            renames[label] = 'ToneKit_FrequencyTable'

        # Widget parameter self-ref: EE4E1C
        elif addr == 0xEE4E1C:
            renames[label] = 'WidgetParam_SelfRef_Table'

        # ToneKit parameter blocks: EE4FD2 - EE5F__
        elif 0xEE4FD2 <= addr <= 0xEE5FC8:
            # These are ToneKit param data records
            idx = 0
            # Compute sequential index
            block_labels = [(l, int(a, 16)) for l, a in defined
                           if 0xEE4FD2 <= int(a, 16) <= 0xEE5FC8]
            block_labels.sort(key=lambda x: x[1])
            for i, (bl, ba) in enumerate(block_labels):
                if bl == label:
                    idx = i
                    break
            renames[label] = f'ToneKit_ParamBlock_{idx:03d}'

        # Widget parameter data: EE63BA - EE75C0
        elif 0xEE63BA <= addr <= 0xEE75C0:
            block_labels = [(l, int(a, 16)) for l, a in defined
                           if 0xEE63BA <= int(a, 16) <= 0xEE75C0]
            block_labels.sort(key=lambda x: x[1])
            for i, (bl, ba) in enumerate(block_labels):
                if bl == label:
                    idx = i
                    break
            renames[label] = f'WidgetParam_Config_{idx:03d}'

        # UIState config entries A: EE7A87 - EE7C9B
        elif 0xEE7A87 <= addr <= 0xEE7C9B:
            block_labels = [(l, int(a, 16)) for l, a in defined
                           if 0xEE7A87 <= int(a, 16) <= 0xEE7C9B]
            block_labels.sort(key=lambda x: x[1])
            for i, (bl, ba) in enumerate(block_labels):
                if bl == label:
                    idx = i
                    break
            renames[label] = f'UIState_ConfigA_{idx:03d}'

        # UIState handler tables: EE8120 - EE82F4
        elif 0xEE8120 <= addr <= 0xEE82F4:
            block_labels = [(l, int(a, 16)) for l, a in defined
                           if 0xEE8120 <= int(a, 16) <= 0xEE82F4]
            block_labels.sort(key=lambda x: x[1])
            for i, (bl, ba) in enumerate(block_labels):
                if bl == label:
                    idx = i
                    break
            renames[label] = f'UIState_HandlerTable_{idx:02d}'

        # UIState config entries B: EE8310 - EE86AC
        elif 0xEE8310 <= addr <= 0xEE86AC:
            block_labels = [(l, int(a, 16)) for l, a in defined
                           if 0xEE8310 <= int(a, 16) <= 0xEE86AC]
            block_labels.sort(key=lambda x: x[1])
            for i, (bl, ba) in enumerate(block_labels):
                if bl == label:
                    idx = i
                    break
            renames[label] = f'UIState_ConfigB_{idx:03d}'

        # UIState config entries C: EE89D1 - EE8C71
        elif 0xEE89D1 <= addr <= 0xEE8C71:
            block_labels = [(l, int(a, 16)) for l, a in defined
                           if 0xEE89D1 <= int(a, 16) <= 0xEE8C71]
            block_labels.sort(key=lambda x: x[1])
            for i, (bl, ba) in enumerate(block_labels):
                if bl == label:
                    idx = i
                    break
            renames[label] = f'UIState_ConfigC_{idx:03d}'

        # Display script nodes continuation: EE4530 - EE491A
        elif 0xEE4530 <= addr <= 0xEE491A:
            block_labels = [(l, int(a, 16)) for l, a in defined
                           if 0xEE4530 <= int(a, 16) <= 0xEE491A]
            block_labels.sort(key=lambda x: x[1])
            for i, (bl, ba) in enumerate(block_labels):
                if bl == label:
                    idx = i
                    break
            renames[label] = f'WidgetParam_Entry_{idx:03d}'

    return renames


def main():
    renames = build_renames()
    if not renames:
        print("No renames to perform")
        return

    # Verify no collisions in new names
    new_names = list(renames.values())
    if len(new_names) != len(set(new_names)):
        dupes = [n for n in new_names if new_names.count(n) > 1]
        print(f"ERROR: Duplicate new names: {set(dupes)}")
        return

    print(f"Renaming {len(renames)} labels")

    # Read all .s files in maincpu/
    maincpu_dir = os.path.join(REPO, 'maincpu')
    all_files = {}
    for root, dirs, files in os.walk(maincpu_dir):
        for fname in files:
            if not fname.endswith('.s'):
                continue
            fpath = os.path.join(root, fname)
            with open(fpath, 'rb') as f:
                all_files[fpath] = f.read()

    # Perform renames
    updated = 0
    for fpath, fcontent in all_files.items():
        original = fcontent
        for old_name, new_name in renames.items():
            fcontent = fcontent.replace(old_name.encode('ascii'), new_name.encode('ascii'))
        if fcontent != original:
            with open(fpath, 'wb') as f:
                f.write(fcontent)
            relpath = os.path.relpath(fpath, REPO)
            print(f"  Updated: {relpath}")
            updated += 1

    print(f"Done! Updated {updated} files.")


if __name__ == '__main__':
    main()
