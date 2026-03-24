#!/usr/bin/env python3
"""
Create positional .set labels for unresolvable ROM hex addresses in maincpu .s files,
and replace all references in both v9 and v10.
"""

import os
import re
import subprocess
import sys
import tempfile
import bisect

REPO = '/mnt/shared/kn5000-roms-disasm'
LLVM_NM = '/mnt/shared/llvm-project/build/bin/llvm-nm'
ELF = os.path.join(REPO, 'rebuilt_ROMs/kn5000_v10_program.llvm.elf')
V10_MAINCPU = os.path.join(REPO, 'v10/maincpu')
V9_MAINCPU = os.path.join(REPO, 'v9/maincpu')
V10_POSITIONAL = os.path.join(REPO, 'v10/maincpu/shared/positional_labels.s')
V9_POSITIONAL = os.path.join(REPO, 'v9/maincpu/shared/positional_labels.s')

ROM_START = 0xe00000
ROM_END = 0xffffff

BITMASKS = {
    0xff0000, 0xffffff, 0xff00ff, 0xffff00, 0xe00000, 0xf00000,
    0xff0001, 0xff0002, 0xff0004, 0xff0008, 0xff0010, 0xff0020,
    0xff0040, 0xff0080, 0xfffe00, 0xfffc00, 0xfff800, 0xfff000,
    0xffe000, 0xffc000, 0xff8000,
}

SKIP_MACROS_RE = re.compile(
    r'RegObjTable|RegTitle|RegMode|RegDisplay|RegGroup|'
    r'RegWidget|RegItem|RegList|RegBitmap|RegValue|'
    r'RegSlider|RegLabel|RegContainer|RegPage|RegPanel|'
    r'addr24|aligned_string|naka_header|NAKA_ADDR|NAKA_HDR|'
    r'Reg_|RegObj'
)

DATA_DIRECTIVES_RE = re.compile(
    r'^\s*\.(byte|long|set|equ|word|short|hword|ascii|asciz|fill|zero|space)\b', re.IGNORECASE
)

SKIP_INSTR_RE = re.compile(r'^\s*(calr|jr|jrl|addm32_24)\b', re.IGNORECASE)

# Match 0xNNNNNN (6 hex digits) in ROM range, with proper context
HEX_ADDR_RE = re.compile(r'(?<=[\s,=(])0x([0-9a-fA-F]{6})(?=[\s,)\n]|$)')


def load_elf_symbols():
    """Load all symbols from ELF."""
    result = subprocess.run(
        [LLVM_NM, '--no-sort', ELF],
        capture_output=True, text=True
    )
    symbols = {}
    abs_symbols = set()

    for line in result.stdout.splitlines():
        parts = line.split()
        if len(parts) >= 3:
            try:
                addr = int(parts[0], 16)
                sym_type = parts[1]
                name = parts[2]
                if sym_type == 'a':
                    abs_symbols.add(name)
                symbols[addr] = name
            except ValueError:
                continue

    return symbols, abs_symbols


def load_source_labels(maincpu_dir):
    """Find all labels defined as 'name:' in source."""
    source_labels = set()
    label_re = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)\s*:')
    for root, dirs, files in os.walk(maincpu_dir):
        for f in files:
            if not f.endswith('.s'):
                continue
            filepath = os.path.join(root, f)
            with open(filepath, 'rb') as fh:
                for line in fh:
                    decoded = line.decode('latin-1').strip()
                    m = label_re.match(decoded)
                    if m:
                        source_labels.add(m.group(1))
    return source_labels


def should_skip_line(line):
    """Check if a line should be skipped for replacement."""
    stripped = line.strip()
    if not stripped or stripped.startswith(';') or stripped.startswith('//'):
        return True
    if DATA_DIRECTIVES_RE.match(line):
        return True
    if SKIP_MACROS_RE.search(line):
        return True
    if SKIP_INSTR_RE.match(line):
        return True
    if 'addm32_24' in line:
        return True
    return False


def scan_for_unresolvable(maincpu_dir, known_addrs):
    """Scan .s files for hex ROM addresses not in symbol table."""
    found = set()

    for root, dirs, files in os.walk(maincpu_dir):
        for f in files:
            if not f.endswith('.s') or 'positional_labels.s' in f:
                continue
            filepath = os.path.join(root, f)
            with open(filepath, 'rb') as fh:
                content = fh.read().decode('latin-1')

            for line in content.splitlines():
                if should_skip_line(line):
                    continue
                code_part = line.split(';')[0] if ';' in line else line
                for m in HEX_ADDR_RE.finditer(code_part):
                    addr = int(m.group(1), 16)
                    if ROM_START <= addr <= ROM_END and addr not in BITMASKS and addr not in known_addrs:
                        found.add(addr)

    return found


def resolve_positional(addresses, symbols, abs_symbols, source_labels):
    """For each address, find nearest source-defined label before it."""
    # Build sorted source label addresses
    source_addrs = []
    source_names = {}
    for addr, name in symbols.items():
        if name in source_labels and name not in abs_symbols:
            source_addrs.append(addr)
            source_names[addr] = name
    source_addrs.sort()

    positional = {}
    for addr in sorted(addresses):
        idx = bisect.bisect_right(source_addrs, addr) - 1
        if idx < 0:
            print(f"WARNING: No parent for 0x{addr:06x}", file=sys.stderr)
            continue
        parent_addr = source_addrs[idx]
        parent_name = source_names[parent_addr]
        offset = addr - parent_addr
        if offset < 0 or offset > 0xFFFF:
            print(f"WARNING: Offset {offset} too large for 0x{addr:06x}", file=sys.stderr)
            continue
        set_name = f"{parent_name}_0x{offset:X}"
        positional[addr] = (parent_name, offset, set_name)

    return positional


def parse_existing_positional(filepath):
    """Parse existing positional_labels.s."""
    existing = {}
    if not os.path.exists(filepath):
        return existing
    pat = re.compile(r'\s*\.set\s+(\S+)\s*,\s*(\S+)\s*\+\s*(\d+)')
    with open(filepath, 'rb') as f:
        for line in f:
            m = pat.match(line.decode('latin-1'))
            if m:
                existing[m.group(1)] = (m.group(2), int(m.group(3)))
    return existing


def write_positional_file(filepath, all_sets):
    """Write positional_labels.s."""
    lines = ['; Auto-generated positional labels for intra-block references\n']
    for name in sorted(all_sets.keys()):
        parent, offset = all_sets[name]
        lines.append(f'\t.set {name}, {parent} + {offset}\n')

    content = ''.join(lines)
    tmpfd, tmppath = tempfile.mkstemp(dir=os.path.dirname(filepath))
    with os.fdopen(tmpfd, 'wb') as f:
        f.write(content.encode('latin-1'))
    os.replace(tmppath, filepath)
    print(f"  Wrote {filepath} ({len(all_sets)} definitions)")


def replace_in_dir(maincpu_dir, addr_to_name):
    """Replace all hex addresses with symbolic names in all .s files.
    Single-pass replacement using a unified regex."""
    # Build lookup: lowercase hex string -> replacement name
    hex_lookup = {}
    for addr, name in addr_to_name.items():
        hex_lookup[f'0x{addr:06x}'] = name

    total = 0
    for root, dirs, files in os.walk(maincpu_dir):
        for f in sorted(files):
            if not f.endswith('.s') or 'positional_labels.s' in f:
                continue
            filepath = os.path.join(root, f)
            with open(filepath, 'rb') as fh:
                content = fh.read()

            text = content.decode('latin-1')
            lines = text.split('\n')
            modified = False
            file_count = 0

            new_lines = []
            for line in lines:
                if should_skip_line(line):
                    new_lines.append(line)
                    continue

                # Split code and comment
                semi_idx = line.find(';')
                if semi_idx >= 0:
                    code_part = line[:semi_idx]
                    comment_part = line[semi_idx:]
                else:
                    code_part = line
                    comment_part = ''

                # Replace all hex addresses in code part
                def replace_match(m):
                    nonlocal file_count, modified
                    hex_str = '0x' + m.group(1).lower()
                    if hex_str in hex_lookup:
                        file_count += 1
                        modified = True
                        return hex_lookup[hex_str]
                    return m.group(0)

                new_code = HEX_ADDR_RE.sub(replace_match, code_part)
                new_lines.append(new_code + comment_part)

            if modified:
                new_text = '\n'.join(new_lines)
                tmpfd, tmppath = tempfile.mkstemp(dir=os.path.dirname(filepath))
                with os.fdopen(tmpfd, 'wb') as fh:
                    fh.write(new_text.encode('latin-1'))
                os.replace(tmppath, filepath)
                relpath = os.path.relpath(filepath, REPO)
                print(f"  {relpath}: {file_count} replacements")
                total += file_count

    return total


def main():
    print("1. Loading ELF symbols...")
    symbols, abs_symbols = load_elf_symbols()
    known_addrs = set(symbols.keys())
    print(f"   {len(symbols)} symbols ({len(abs_symbols)} absolute)")

    print("2. Loading source labels...")
    source_labels = load_source_labels(V10_MAINCPU)
    print(f"   {len(source_labels)} source labels")

    print("3. Scanning for unresolvable addresses...")
    unresolvable = scan_for_unresolvable(V10_MAINCPU, known_addrs)
    print(f"   {len(unresolvable)} unique unresolvable addresses")

    print("4. Resolving to positional labels...")
    positional = resolve_positional(unresolvable, symbols, abs_symbols, source_labels)
    print(f"   {len(positional)} resolved")

    unresolved = unresolvable - set(positional.keys())
    if unresolved:
        print(f"   WARNING: {len(unresolved)} unresolved:")
        for a in sorted(unresolved)[:10]:
            print(f"     0x{a:06x}")

    print("5. Merging with existing definitions...")
    existing = parse_existing_positional(V10_POSITIONAL)
    all_sets = dict(existing)
    for addr, (parent, offset, name) in positional.items():
        all_sets[name] = (parent, offset)
    new_count = len(all_sets) - len(existing)
    print(f"   Existing: {len(existing)}, New: {new_count}, Total: {len(all_sets)}")

    print("6. Writing positional_labels.s (identical for v9 and v10)...")
    write_positional_file(V10_POSITIONAL, all_sets)
    write_positional_file(V9_POSITIONAL, all_sets)

    print("7. Building replacement map...")
    addr_to_name = {addr: info[2] for addr, info in positional.items()}
    print(f"   {len(addr_to_name)} addresses to replace")

    print("8. Replacing in v10...")
    total_v10 = replace_in_dir(V10_MAINCPU, addr_to_name)
    print(f"   Total v10: {total_v10}")

    print("9. Replacing in v9...")
    total_v9 = replace_in_dir(V9_MAINCPU, addr_to_name)
    print(f"   Total v9: {total_v9}")

    print(f"\nDone! New: {new_count}, Total: {len(all_sets)}, v10: {total_v10}, v9: {total_v9}")


if __name__ == '__main__':
    main()
