#!/usr/bin/env python3
"""Fix policy violations in roms-disasm .s files.

b1: Lowercase hex in instruction operands
b2: Hex ROM addresses -> ELF symbols (instructions only, not macros)

Uses binary I/O throughout to preserve Latin-1 encoding.
"""

import os
import re
import sys

ROMS_DISASM = '/mnt/shared/kn5000-roms-disasm'
V10_MAINCPU = os.path.join(ROMS_DISASM, 'v10/maincpu')
V9_MAINCPU = os.path.join(ROMS_DISASM, 'v9/maincpu')
ELF_SYMBOLS_FILE = '/tmp/elf_symbols.txt'

DIFF_FILES = {
    'audio/note_voice_mapping.s',
    'audio/sprintf_core.s',
    'boot/rom_end_structure.s',
    'boot/system_handlers.s',
    'demo/file_demo_proc.s',
    'factory_test/test_data.s',
    'midi/computer_interface_pcg.s',
    'sequencer/seq_audio_mode.s',
    'sequencer/smf_event_processor.s',
    'storage/flash_floppy_handlers.s',
    'ui/drawbar_panel_ui.s',
    'ui/ui_control_panel.s',
    'ui_widgets/widget_dispatch.s',
}

CONDITIONAL_MACROS = {
    'RegObjTable', 'RegObjTabl', 'RegMode', 'RegTitle',
    'RegObjTableHama', 'RegObjTablHama', 'RegTitleHama',
}


def load_elf_symbols():
    symbols = {}
    with open(ELF_SYMBOLS_FILE) as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) == 2:
                addr = int(parts[0], 16)
                name = parts[1]
                if 0xe00000 <= addr <= 0xffffff:
                    if addr not in symbols:
                        symbols[addr] = name
    return symbols


def get_target_files():
    targets = []
    for root, dirs, files in os.walk(V10_MAINCPU):
        if 'generated' in root:
            continue
        for fn in sorted(files):
            if not fn.endswith('.s'):
                continue
            rel = os.path.relpath(os.path.join(root, fn), V10_MAINCPU)
            if rel in DIFF_FILES or rel == 'kn5000_v10_program.s':
                continue
            targets.append(rel)
    return targets


def lowercase_hex_in_code(code):
    """Lowercase hex digits in 0xHEX values, not when 0x is part of an identifier."""
    result = []
    i = 0
    while i < len(code):
        if i + 1 < len(code) and code[i] == '0' and code[i+1] in 'xX':
            if i > 0 and (code[i-1].isalnum() or code[i-1] == '_'):
                result.append(code[i])
                i += 1
                continue
            result.append('0x')
            i += 2
            hex_start = i
            while i < len(code) and code[i] in '0123456789abcdefABCDEF':
                i += 1
            hex_part = code[hex_start:i]
            result.append(hex_part.lower())
            continue
        if code[i] in ('"', "'"):
            quote = code[i]
            result.append(code[i])
            i += 1
            while i < len(code) and code[i] != quote:
                result.append(code[i])
                i += 1
            if i < len(code):
                result.append(code[i])
                i += 1
            continue
        result.append(code[i])
        i += 1
    return ''.join(result)


def fix_line(line_str, elf_symbols):
    """Fix a single line string. Returns modified line string."""
    stripped = line_str.strip()
    if not stripped or stripped.startswith(';'):
        return line_str

    if re.match(r'^[A-Za-z_][A-Za-z0-9_]*:\s*(;.*)?$', stripped):
        return line_str

    # Find where comment starts
    code_end = len(line_str)
    in_string = False
    quote_char = None
    for i, c in enumerate(line_str):
        if in_string:
            if c == quote_char:
                in_string = False
        else:
            if c in ('"', "'"):
                in_string = True
                quote_char = c
            elif c == ';':
                code_end = i
                break

    code_part = line_str[:code_end]
    comment_part = line_str[code_end:]

    lstripped = code_part.lstrip()

    if re.match(r'\.(ascii|asciz)\s', lstripped):
        return line_str

    is_directive = bool(re.match(
        r'\.(set|equ|byte|long|short|word|zero|fill|incbin|include|'
        r'section|global|type|size|align|macro|endm|p2align|org)', lstripped))

    is_macro_invocation = False
    if not is_directive:
        first_token = lstripped.split()[0] if lstripped.split() else ''
        if not first_token.endswith(':') and first_token in CONDITIONAL_MACROS:
            is_macro_invocation = True

    # b2: Replace ROM hex addresses with symbols
    if not is_directive and not is_macro_invocation:
        def replace_rom_addr(m):
            full_match = m.group(0)
            hex_str = m.group(1)
            start = m.start()
            if start > 0 and (code_part[start-1].isalnum() or code_part[start-1] == '_'):
                return full_match
            try:
                addr = int(hex_str, 16)
            except:
                return full_match
            if 0xe00000 <= addr <= 0xffffff:
                if addr in elf_symbols:
                    return elf_symbols[addr]
            return full_match

        code_part = re.sub(r'0x([0-9a-fA-F]{6,})', replace_rom_addr, code_part)

    # b1: Lowercase hex values
    code_part = lowercase_hex_in_code(code_part)

    return code_part + comment_part


def process_file(rel_path, elf_symbols):
    v10_path = os.path.join(V10_MAINCPU, rel_path)
    v9_path = os.path.join(V9_MAINCPU, rel_path)

    with open(v10_path, 'rb') as f:
        original = f.read()

    lines = original.decode('latin-1').split('\n')
    new_lines = []
    changed = False

    for line_str in lines:
        new_line = fix_line(line_str, elf_symbols)
        new_lines.append(new_line)
        if new_line != line_str:
            changed = True

    if changed:
        new_content = '\n'.join(new_lines).encode('latin-1')
        # Write v10 using atomic temp-file + replace (virtiofs workaround)
        _atomic_write(v10_path, new_content)
        # Copy to v9
        if os.path.exists(v9_path):
            _atomic_write(v9_path, new_content)
        return True
    return False


def _atomic_write(path, content):
    """Write content atomically using temp file + os.replace.

    Direct open('wb') writes get silently reverted on virtiofs.
    Writing to a new file and replacing works reliably.
    """
    tmp_path = path + '.fixing'
    with open(tmp_path, 'wb') as f:
        f.write(content)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp_path, path)


def main():
    print("Loading ELF symbols...")
    elf_symbols = load_elf_symbols()
    print(f"  {len(elf_symbols)} ROM-range symbols loaded")

    print("Finding target files...")
    targets = get_target_files()
    print(f"  {len(targets)} files to process")

    changed = 0
    unchanged = 0

    for i, rel_path in enumerate(targets):
        if process_file(rel_path, elf_symbols):
            changed += 1
        else:
            unchanged += 1
        if (i + 1) % 20 == 0 or i == len(targets) - 1:
            print(f"  Processed {i+1}/{len(targets)} ({changed} changed)")

    print(f"\nDone! {changed} files changed, {unchanged} unchanged")
    os.sync()


if __name__ == '__main__':
    main()
