#!/usr/bin/env python3
"""Generate semantic instruction definitions for all raw encoding wrappers.

Scans all .s files, identifies raw wrapper instances, determines the correct
sub-opcode position for each pattern, and generates:
1. TableGen instruction definitions (for TLCS900InstrInfo.td)
2. Converter suffix maps (for asl_to_llvm.py)

Key insight about sub-opcode position:
- The sub-opcode (operation code) position depends on the addressing mode:
  - Simple modes (erp, spi/spd/dpi/dpd, sd8/dd8): 1 addressing byte → sub-opc at pos 1
  - 16-bit direct (sd16/dd16): 2 addressing bytes → sub-opc at pos 2
  - 24-bit direct (sd24/dd24): 3 addressing bytes → sub-opc at pos 3
  - Register-indirect (sri/dri) mode 0 (r32): 1 addr byte → sub-opc at pos 1
  - Register-indirect (sri/dri) mode 1 (r32+d16): 3 addr bytes → sub-opc at pos 3
  - Register-indirect (sri/dri) mode 3 (r32+r8/r32+r16/PC+d16): 3 addr bytes → sub-opc at pos 3
"""

import os
import re
import sys
from collections import defaultdict, Counter

ROMS_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S_DIRS = [
    os.path.join(ROMS_DIR, 'maincpu'),
    os.path.join(ROMS_DIR, 'hdae5000'),
    os.path.join(ROMS_DIR, 'subcpu'),
    os.path.join(ROMS_DIR, 'table_data'),
    os.path.join(ROMS_DIR, 'custom_data'),
]

RAW_WRAPPER_RE = re.compile(
    r'^\s+(erp[bwl]\d|sri[bwl]\d|spi[bwl]\d|spd[bwl]\d|'
    r'sd8[bwl]\d|sd16[bwl]\d|sd24[bwl]\d|'
    r'dd8\d|dd16\d|dd24\d|dri\d|dpi\d|dpd\d)\s+(.+?)(?:\s*//.*)?$',
    re.MULTILINE
)

# Category → (base_opcode, is_source)
CATEGORY_INFO = {
    'sd8':  (0xC0, True),
    'sd16': (0xC1, True),
    'sd24': (0xC2, True),
    'sri':  (0xC3, True),
    'spd':  (0xC4, True),
    'spi':  (0xC5, True),
    'erp':  (0xC7, True),
    'dd8':  (0xF0, False),
    'dd16': (0xF1, False),
    'dd24': (0xF2, False),
    'dri':  (0xF3, False),
    'dpd':  (0xF4, False),
    'dpi':  (0xF5, False),
}

SIZE_OFFSET = {'b': 0, 'w': 1, 'l': 2}


def parse_operands(operand_str):
    operand_str = re.split(r'\s*(?://|;|\t)', operand_str)[0].strip()
    parts = operand_str.split(',')
    result = []
    for p in parts:
        p = p.strip()
        if not p:
            continue
        p = re.split(r'\s*(?://|;)', p)[0].strip()
        if not p:
            continue
        if p.startswith('0x') or p.startswith('0X'):
            result.append(int(p, 16))
        else:
            try:
                result.append(int(p))
            except ValueError:
                result.append(0)
    return result


def parse_mnemonic(mnemonic):
    m = re.match(r'^(erp|sri|spi|spd|sd8|sd16|sd24)([bwl])(\d+)$', mnemonic)
    if m:
        return m.group(1), m.group(2), int(m.group(3))
    m = re.match(r'^(dd8|dd16|dd24|dri|dpi|dpd)(\d+)$', mnemonic)
    if m:
        return m.group(1), None, int(m.group(2))
    return None, None, 0


def get_addr_len(category, operands):
    """Determine number of addressing bytes before the sub-opcode.

    Returns addr_len (the sub-opcode position within operands).
    """
    if category in ('erp', 'spi', 'spd', 'dpi', 'dpd'):
        return 1  # 1 register byte
    if category in ('sd8', 'dd8'):
        return 1  # 1 address byte
    if category in ('sd16', 'dd16'):
        return 2  # 2 address bytes
    if category in ('sd24', 'dd24'):
        return 3  # 3 address bytes
    if category in ('sri', 'dri'):
        if not operands:
            return 0
        addr_mode = operands[0]
        mode_type = addr_mode & 0x03
        if mode_type == 0:
            return 1  # (r32) — just register encoding byte
        elif mode_type in (1, 3):
            return 3  # (r32+d16), (r32+r8), (r32+r16), (PC+d16) — 3 addr bytes
        else:
            return 0  # Unknown mode type 2
    return 0


def collect_all_wrappers():
    instances = []
    for s_dir in S_DIRS:
        if not os.path.isdir(s_dir):
            continue
        rom_name = os.path.basename(s_dir)
        for root, dirs, files in os.walk(s_dir):
            for fname in sorted(files):
                if not fname.endswith('.s'):
                    continue
                fpath = os.path.join(root, fname)
                with open(fpath, 'r') as f:
                    content = f.read()
                for m in RAW_WRAPPER_RE.finditer(content):
                    mnemonic = m.group(1)
                    operands_str = m.group(2).strip()
                    instances.append({
                        'rom': rom_name,
                        'file': fname,
                        'mnemonic': mnemonic,
                        'operands_str': operands_str,
                    })
    return instances


def analyze_patterns(instances):
    """Group instances into unique patterns and analyze sub-opcode positions.

    Returns a list of pattern dicts with:
    - category, size_char, nops (total operand bytes)
    - addr_len (addressing bytes before sub-opcode)
    - sub_opc (the operation sub-opcode value)
    - trail (trailing bytes after sub-opcode)
    - count (number of instances)
    - is_suffix (True if sub-opcode is at end, False if in middle)
    """
    # Group by (mnemonic, addr_len, sub_opc, trail)
    pattern_groups = defaultdict(list)

    for inst in instances:
        mnemonic = inst['mnemonic']
        operands = parse_operands(inst['operands_str'])
        category, size_char, nops = parse_mnemonic(mnemonic)
        if category is None:
            continue

        addr_len = get_addr_len(category, operands)
        if addr_len == 0 or addr_len >= len(operands):
            # Can't determine sub-opcode — mark as unknown
            key = (mnemonic, 'unknown', tuple(operands))
            pattern_groups[key].append(inst)
            continue

        sub_opc = operands[addr_len]
        trail = len(operands) - addr_len - 1  # bytes after sub-opcode

        key = (category, size_char, nops, addr_len, sub_opc, trail)
        pattern_groups[key].append(inst)

    # Convert to pattern list
    patterns = []
    for key, group in sorted(pattern_groups.items(), key=lambda x: (-len(x[1]), str(x[0]))):
        if isinstance(key[1], str) and key[1] == 'unknown':
            # Unknown pattern
            patterns.append({
                'category': key[0].rstrip('0123456789').rstrip('bwl'),
                'size_char': None,
                'nops': 0,
                'addr_len': 0,
                'sub_opc': None,
                'trail': 0,
                'count': len(group),
                'is_suffix': False,
                'is_unknown': True,
                'mnemonic': key[0],
                'example_operands': group[0]['operands_str'],
            })
            continue

        category, size_char, nops, addr_len, sub_opc, trail = key
        is_suffix = (trail == 0)

        patterns.append({
            'category': category,
            'size_char': size_char,
            'nops': nops,
            'addr_len': addr_len,
            'sub_opc': sub_opc,
            'trail': trail,
            'count': len(group),
            'is_suffix': is_suffix,
            'is_unknown': False,
            'mnemonic': f"{category}{size_char or ''}{nops}",
            'example_operands': group[0]['operands_str'],
        })

    return patterns


def gen_tablegen_name(p):
    """Generate a unique TableGen definition name for a pattern."""
    cat = p['category'].upper()
    sc = (p['size_char'] or '').upper()
    sub = p['sub_opc']
    nops = p['nops']
    trail = p['trail']

    if p['is_suffix']:
        return f"X_{cat}{sc}{nops}_S{sub:02X}"
    else:
        return f"X_{cat}{sc}{nops}_O{sub:02X}_T{trail}"


def gen_asm_mnemonic(p):
    """Generate a unique assembly mnemonic for a pattern."""
    cat = p['category']
    sc = p['size_char'] or ''
    sub = p['sub_opc']
    nops = p['nops']
    trail = p['trail']

    if p['is_suffix']:
        return f"x_{cat}{sc}{nops}_s{sub:02x}"
    else:
        return f"x_{cat}{sc}{nops}_o{sub:02x}_t{trail}"


def gen_tablegen_defs(patterns):
    """Generate TableGen instruction definitions."""
    lines = []
    lines.append("// === Auto-generated semantic extended addressing mode instructions ===")
    lines.append("// Generated by scripts/gen_semantic_instrs.py")
    lines.append("// Each definition replaces one or more raw ExtAddrModeInst wrappers.")
    lines.append("")

    # Group by category for organized output
    by_cat = defaultdict(list)
    for p in patterns:
        if not p['is_unknown']:
            by_cat[p['category']].append(p)

    cat_order = ['erp', 'sri', 'spi', 'spd', 'sd8', 'sd16', 'sd24',
                 'dri', 'dpi', 'dpd', 'dd8', 'dd16', 'dd24']

    for cat in cat_order:
        if cat not in by_cat:
            continue
        entries = sorted(by_cat[cat], key=lambda p: (p['sub_opc'], p['nops']))
        base_opc, is_source = CATEGORY_INFO[cat]

        lines.append(f"// --- {cat.upper()} (base opcode 0x{base_opc:02X}) ---")

        for p in entries:
            tg_name = gen_tablegen_name(p)
            asm_name = gen_asm_mnemonic(p)
            sub_opc = p['sub_opc']
            nops = p['nops']
            addr_len = p['addr_len']
            trail = p['trail']
            size_char = p['size_char']
            nbytes = nops + 1  # total instruction bytes = prefix + operands

            # Determine number of assembly operands (excluding sub-opcode)
            num_asm_ops = nops - 1  # nops includes sub-opcode byte; assembly ops exclude it
            # Actually: nops = addr_len + 1 (sub-opc) + trail
            # Assembly operands = addr_len + trail (sub-opc is in TSFlags)
            num_asm_ops = addr_len + trail

            # Generate operand list
            op_names = [f"$b{i}" for i in range(num_asm_ops)]
            ins_list = ', '.join(f'i32imm:$b{i}' for i in range(num_asm_ops))
            args_str = ', '.join(op_names)

            if p['is_suffix']:
                # ExtAddrModeSuffixInst
                lines.append(
                    f'def {tg_name} : ExtAddrModeSuffixInst<{nbytes}, 0x{sub_opc:02X}, (outs),')
                lines.append(
                    f'    (ins {ins_list}),')
                lines.append(
                    f'    "{asm_name}", "{args_str}", []> {{')
            else:
                # ExtAddrModeOpImmInst
                lines.append(
                    f'def {tg_name} : ExtAddrModeOpImmInst<{nbytes}, 0x{sub_opc:02X}, {addr_len}, (outs),')
                lines.append(
                    f'    (ins {ins_list}),')
                lines.append(
                    f'    "{asm_name}", "{args_str}", []> {{')

            lines.append(f'  let Opcode = 0x{base_opc:02X};')
            if is_source and size_char:
                size_val = {'b': 'OpSize8.Value', 'w': 'OpSize16.Value', 'l': 'OpSize32.Value'}[size_char]
                lines.append(f'  let OpSize = {size_val};')
            lines.append('}')

        lines.append("")

    return '\n'.join(lines)


def gen_converter_maps(patterns):
    """Generate converter suffix map entries."""
    lines = []
    lines.append("# === Auto-generated semantic suffix maps ===")
    lines.append("# Generated by scripts/gen_semantic_instrs.py")
    lines.append("# Key: (category, size_char, sub_opc, nops) → (asm_mnemonic, addr_len)")
    lines.append("")
    lines.append("SEMANTIC_MAP = {")

    for p in sorted(patterns, key=lambda p: (p['category'], p.get('size_char', ''),
                                              p['sub_opc'] or 0, p['nops'])):
        if p['is_unknown']:
            continue
        asm_name = gen_asm_mnemonic(p)
        cat = p['category']
        sc = repr(p['size_char'])
        sub = p['sub_opc']
        nops = p['nops']
        addr_len = p['addr_len']
        lines.append(
            f"    ('{cat}', {sc}, 0x{sub:02X}, {nops}): ('{asm_name}', {addr_len}),")

    lines.append("}")
    return '\n'.join(lines)


def main():
    print("Collecting all raw wrapper instances...")
    instances = collect_all_wrappers()
    print(f"Found {len(instances)} instances")

    print("Analyzing patterns...")
    patterns = analyze_patterns(instances)
    known_patterns = [p for p in patterns if not p['is_unknown']]
    unknown_patterns = [p for p in patterns if p['is_unknown']]

    print(f"Found {len(known_patterns)} known patterns, {len(unknown_patterns)} unknown")

    suffix_patterns = [p for p in known_patterns if p['is_suffix']]
    opimm_patterns = [p for p in known_patterns if not p['is_suffix']]

    print(f"  Suffix (sub-opcode at end): {len(suffix_patterns)} ({sum(p['count'] for p in suffix_patterns)} instances)")
    print(f"  OpImm (sub-opcode in middle): {len(opimm_patterns)} ({sum(p['count'] for p in opimm_patterns)} instances)")

    # Print summary by category
    print("\nBy category:")
    by_cat = defaultdict(lambda: {'suffix': 0, 'opimm': 0, 'total': 0})
    for p in known_patterns:
        cat = p['category']
        by_cat[cat]['total'] += p['count']
        if p['is_suffix']:
            by_cat[cat]['suffix'] += 1
        else:
            by_cat[cat]['opimm'] += 1

    for cat in ['erp', 'sri', 'spi', 'spd', 'sd8', 'sd16', 'sd24',
                'dri', 'dpi', 'dpd', 'dd8', 'dd16', 'dd24']:
        if cat in by_cat:
            d = by_cat[cat]
            print(f"  {cat:6s}: {d['suffix']:3d} suffix + {d['opimm']:3d} opimm = {d['suffix']+d['opimm']:3d} defs ({d['total']:5d} instances)")

    # Print detailed pattern list
    print("\n" + "="*100)
    print("ALL PATTERNS")
    print("="*100)

    for p in sorted(known_patterns, key=lambda p: (p['category'], p['sub_opc'] or 0, p['nops'])):
        fmt = "SUFFIX" if p['is_suffix'] else "OPIMM "
        sc = p['size_char'] or '-'
        sub = p['sub_opc']
        asm = gen_asm_mnemonic(p)
        tg = gen_tablegen_name(p)
        print(f"  {fmt} {p['category']:6s}{sc} sub=0x{sub:02X} nops={p['nops']} "
              f"addr={p['addr_len']} trail={p['trail']} "
              f"({p['count']:4d}x) → {asm:30s} [{tg}]")

    if unknown_patterns:
        print(f"\nUNKNOWN PATTERNS ({len(unknown_patterns)}):")
        for p in unknown_patterns:
            print(f"  {p['mnemonic']:12s} ({p['count']:4d}x) example: {p['example_operands']}")

    # Generate output files
    tablegen_output = gen_tablegen_defs(known_patterns)
    converter_output = gen_converter_maps(known_patterns)

    tg_path = os.path.join(ROMS_DIR, 'scripts', 'generated_instrs.td')
    conv_path = os.path.join(ROMS_DIR, 'scripts', 'generated_maps.py')

    with open(tg_path, 'w') as f:
        f.write(tablegen_output)
    print(f"\nGenerated TableGen defs: {tg_path}")

    with open(conv_path, 'w') as f:
        f.write(converter_output)
    print(f"Generated converter maps: {conv_path}")

    print(f"\nTotal: {len(known_patterns)} instruction definitions to add")
    print(f"  {len(suffix_patterns)} ExtAddrModeSuffixInst")
    print(f"  {len(opimm_patterns)} ExtAddrModeOpImmInst")


if __name__ == '__main__':
    main()
