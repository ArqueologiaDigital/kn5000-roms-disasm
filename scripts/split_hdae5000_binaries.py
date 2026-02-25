#!/usr/bin/env python3
"""Split HDAE5000 binary includes at known routine boundaries.

Uses .incbin offset/count parameters to expose labels at known routine
addresses without creating separate files. This makes the code navigable
by adding symbolic labels at documented routine entry points.
"""

import re
import sys

# Binary includes: filename -> (start_addr, end_addr_inclusive)
BINARIES = {
    'includes/code_28f90c_2953e1.bin': (0x28F90C, 0x2953E1),
    'includes/code_295642_2971a2.bin': (0x295642, 0x2971A2),
    'includes/code_2971b7_29ae9e.bin': (0x2971B7, 0x29AE9E),
    'includes/code_29af2d_2fffff.bin': (0x29AF2D, 0x2FFFFF),
}

# Known routine addresses: addr -> (label_name, comment)
SPLIT_POINTS = {
    # Display routines in code_28f90c_2953e1.bin
    0x28F97E: ('HDAE5000_Calc_Offset_16', 'Calculate 16-byte offset in table'),
    0x28F98B: ('HDAE5000_Copy_To_Table', 'Copy data to table at 0x201632'),
    0x28F9AD: ('HDAE5000_Get_Display_Dimensions_A1_2F', 'Memory check routine'),
    0x28F9EB: ('HDAE5000_Count_Invalid_Cells', 'Count invalid entries'),
    0x28FA1E: ('HDAE5000_Calculate_Row_Address', 'Calculate address with 0x4C multiplier'),
    0x28FA56: ('HDAE5000_Copy_Display_Cell', 'Copy table entry'),
    0x28FAA0: ('HDAE5000_Calculate_Tile_Address', 'Calculate address with 0x90 multiplier'),
    0x28FABA: ('HDAE5000_Copy_Display_Cell_90', 'Copy 0x90-stride entry'),
    0x28FAE9: ('HDAE5000_Validate_Cell_Coords', 'Check table entry validity'),
    0x28FB26: ('HDAE5000_Resolve_Cell_Address', 'Get entry address with validation'),
    0x28FBB1: ('HDAE5000_Cell_In_Bounds', 'Validate entry at coordinates'),
    0x295009: ('HDAE5000_PPORT_Util', 'PPORT utility function'),
    0x29501C: ('HDAE5000_PPORT_Handler', 'PPORT state machine entry'),
    0x295046: ('HDAE5000_PPORT_Status', 'PPORT status check'),
    0x295058: ('HDAE5000_PPORT_Init', 'PPORT initialization'),
    0x2950CC: ('HDAE5000_PPORT_Dispatch', 'Command dispatcher'),
    0x2950F8: ('HDAE5000_Display_String', 'Display string routine (heavily used)'),
    0x29511C: ('HDAE5000_PPORT_Setup', 'PPORT setup routine'),
    0x2952D6: ('HDAE5000_PPORT_Menu', 'PPORT menu handler'),
    0x2952F8: ('HDAE5000_PPORT_Execute', 'Execute PPORT command'),

    # PPORT command handlers in code_295642_2971a2.bin
    0x2958D6: ('HDAE5000_Cmd01_SendInfo', 'Handler: Send HD info'),
    0x295914: ('HDAE5000_Cmd02_Exit', 'Handler: Exit PPORT'),
    0x2959F6: ('HDAE5000_Cmd03_ReadFSB', 'Handler: Read FSB from HD'),
    0x295D3C: ('HDAE5000_Cmd04_SendFSB', 'Handler: Send FSB to PC'),
    0x29605A: ('HDAE5000_Cmd05_RcvFSB', 'Handler: Receive FSB from PC'),
    0x296294: ('HDAE5000_Cmd06_WriteFSB', 'Handler: Write FSB to HD'),
    0x29632A: ('HDAE5000_PPORT_Cmd_LoadHDtoMemory', 'Load HD to Memory'),
    0x29633C: ('HDAE5000_PPORT_Cmd_SendDataBlock', 'Send data block to PC'),
    0x2964A6: ('HDAE5000_PPORT_Cmd_SendFileList', 'Send file list to PC'),
    0x296588: ('HDAE5000_PPORT_Cmd_ReceiveDataBlock', 'Receive data from PC'),
    0x29659A: ('HDAE5000_PPORT_Cmd_WriteMemoryToHD', 'Save memory to HD'),
    0x296680: ('HDAE5000_PPORT_Cmd_Reserved', '(reserved/placeholder)'),
    0x2967B4: ('HDAE5000_Render_Display_Region', 'Display region rendering'),
    0x2967E4: ('HDAE5000_Render_Display_Region2', 'Display region rendering 2'),
    0x296A9C: ('HDAE5000_PPORT_Ready_Check', 'Check PPORT readiness'),
    0x296AB6: ('HDAE5000_PPORT_Cleanup', 'PPORT cleanup routine'),
    0x2966BE: ('PPORT_Utility_1', 'PPORT utility routine 1'),
    0x2966FA: ('PPORT_Utility_2', 'PPORT utility routine 2'),
    0x29670C: ('PPORT_Utility_3', 'PPORT utility routine 3'),

    # Version info in code_2971b7_29ae9e.bin
    0x2999B0: ('HDAE5000_Version_Info', 'Version/author strings'),

    # Routines and data in code_29af2d_2fffff.bin
    0x29AF71: ('HDAE5000_Display_Buffer_Validate', 'Buffer validation'),
    0x29AFBE: ('HDAE5000_MemCompare_Block', 'Memory block compare'),
    0x29AFF0: ('HDAE5000_MemCopy_Reverse', 'Memory copy (reverse direction)'),
    0x29B72D: ('HDAE5000_Multiply', '32-bit multiply routine'),
    0x29BFE0: ('HDAE5000_UI_Config', 'UI configuration strings'),
    0x29C0AA: ('HDAE5000_RECORD_TABLE', 'Record/entry data table'),
    0x29D97E: ('HDAE5000_RECORD_COUNT', 'Record count data'),
    0x2A5D2C: ('HDAE5000_GFX_DATA_1', 'Graphics data block 1'),
    0x2A6984: ('HDAE5000_GFX_DATA_2', 'Graphics data block 2'),
    0x2A849A: ('HDAE5000_GFX_INIT_PARAMS', 'Graphics initialization parameters'),
    0x2E5DCE: ('HDAE5000_Palette_Data', 'VGA palette data (256 entries)'),
    0x2F8DCE: ('HDAE5000_Display_Params', 'Display configuration parameters'),
    0x2F94B2: ('HDAE5000_Init_Data', 'Data copied to 0x23952A (0xC82 bytes)'),
}


def process_file(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()

    # Group split points by binary
    bin_splits = {}
    for addr, (name, comment) in sorted(SPLIT_POINTS.items()):
        for bin_path, (bin_start, bin_end) in BINARIES.items():
            if bin_start < addr <= bin_end:
                if bin_path not in bin_splits:
                    bin_splits[bin_path] = []
                bin_splits[bin_path].append((addr, name, comment))
                break

    changes = []

    for i, line in enumerate(lines):
        stripped = line.strip()
        if not stripped.startswith('.incbin '):
            continue

        m = re.search(r'"([^"]+)"', stripped)
        if not m:
            continue
        filename = m.group(1)

        if filename not in bin_splits:
            continue

        # Skip if already has offset/count parameters
        if ',' in stripped:
            print(f"  Skipping {filename} (already split)")
            continue

        bin_start, bin_end = BINARIES[filename]
        total_size = bin_end - bin_start + 1
        splits = bin_splits[filename]

        new_lines = []
        prev_offset = 0

        for addr, name, comment in splits:
            offset = addr - bin_start

            # Emit .incbin for bytes before this label
            if offset > prev_offset:
                count = offset - prev_offset
                new_lines.append(
                    f'\t.incbin "{filename}", {prev_offset}, {count}\n')

            # Emit label and comment
            new_lines.append(f'\n{name}:\t; 0x{addr:06X}\n')
            new_lines.append(f'\t; {comment}\n')

            prev_offset = offset

        # Emit remaining bytes
        if prev_offset < total_size:
            remaining = total_size - prev_offset
            new_lines.append(
                f'\t.incbin "{filename}", {prev_offset}, {remaining}\n')

        changes.append((i, new_lines))
        print(f"  {filename}: {len(splits)} labels, "
              f"{len(new_lines)} output lines")

    # Apply changes in reverse
    for line_idx, new_lines in reversed(changes):
        lines[line_idx:line_idx + 1] = new_lines

    with open(filepath, 'w') as f:
        f.writelines(lines)

    total_labels = sum(len(s) for s in bin_splits.values())
    print(f"\nDone! Split {len(changes)} binaries, "
          f"{total_labels} labels inserted.")


if __name__ == '__main__':
    process_file('hdae5000/hd-ae5000_v2_06i.s')
