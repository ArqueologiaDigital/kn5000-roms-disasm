#!/usr/bin/env python3
"""
audit_byte_code.py — Audit all .byte sequences across ROMs to identify code vs data.

For each .byte block found between native instructions:
  1. Attempts llvm-mc --triple=tlcs900 --disassemble
  2. Round-trip verifies via --show-encoding
  3. Classifies: (a) decodable now, (b) needs LLVM addition, (c) data
  4. Groups code .byte by opcode prefix (first byte)
  5. Outputs a detailed report

Usage:
    python scripts/audit_byte_code.py [--verbose] [--csv report.csv] [--file PATH]
"""

import os
import re
import sys
import csv
import subprocess
import struct
import argparse
from pathlib import Path
from collections import defaultdict, Counter

LLVM_MC = "/mnt/shared/llvm-project/build/bin/llvm-mc"
REPO_ROOT = Path("/mnt/shared/kn5000-roms-disasm")

ROM_DIRS = [
    "maincpu",
    "subcpu",
    "hdae5000",
    "table_data",
    "custom_data",
]

# Regex for .byte line
BYTE_LINE_RE = re.compile(r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+)', re.IGNORECASE)
BYTE_VAL_RE = re.compile(r'0x([0-9a-fA-F]{2})')

# Regex for label
LABEL_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)\s*:')

# Regex for native instruction (tab-indented mnemonic, not a directive)
DIRECTIVE_RE = re.compile(r'^\s*\.(byte|long|short|ascii|asciz|zero|fill|incbin|include|global|type|section|align|org|space|set|equ|if|else|endif|macro|endm|file|loc|size)', re.IGNORECASE)
COMMENT_RE = re.compile(r'^\s*[;#]')
EMPTY_RE = re.compile(r'^\s*$')

# Known data label patterns (heuristic)
DATA_LABEL_PATTERNS = [
    re.compile(r'(?:Data|Table|Block|String|Text|Bitmap|Icon|Image|Palette|Font|Pattern|Array|List|Map|Config|Param|Buffer|Const|Default|Init|Template|Wallpaper|Screen|Widget|Descriptor|Msg|Message)', re.IGNORECASE),
]

# Known code label patterns (heuristic)
CODE_LABEL_PATTERNS = [
    re.compile(r'(?:Handler|Routine|Func|Init|Process|Dispatch|Loop|Send|Read|Write|Wait|Check|Verify|Validate|Execute|Run|Start|Stop|Reset|Clear|Setup|Update|Calc|Convert|Parse|Scan|Search|Sort|Copy|Move|Fill|Load|Store|Save|Restore|Push|Pop|Call|Jump|Return|Entry|Exit|Main|Sub|Int|IRQ|NMI|DMA|Timer|Serial|UART|SPI|I2C|ADC|DAC|PWM|GPIO)', re.IGNORECASE),
]


def find_s_files():
    """Find all .s files in ROM directories."""
    files = []
    for rom_dir in ROM_DIRS:
        d = REPO_ROOT / rom_dir
        if d.is_dir():
            for root, dirs, filenames in os.walk(d):
                for fn in sorted(filenames):
                    if fn.endswith('.s'):
                        files.append(Path(root) / fn)
    # Also check shared/
    shared = REPO_ROOT / "shared"
    if shared.is_dir():
        for root, dirs, filenames in os.walk(shared):
            for fn in sorted(filenames):
                if fn.endswith('.s'):
                    files.append(Path(root) / fn)
    return sorted(files)


def parse_bytes_from_line(line):
    """Extract bytes from a .byte directive line."""
    m = BYTE_LINE_RE.match(line)
    if not m:
        return None
    vals = BYTE_VAL_RE.findall(m.group(1))
    return [int(v, 16) for v in vals]


def is_native_instruction(line):
    """Check if a line is a native assembly instruction (not directive, not comment, not empty)."""
    stripped = line.strip()
    if not stripped:
        return False
    if stripped.startswith(';') or stripped.startswith('#'):
        return False
    if LABEL_RE.match(stripped):
        return False
    if DIRECTIVE_RE.match(stripped):
        return False
    # Must be tab-indented (instruction)
    if line and (line[0] == '\t' or line.startswith('  ')):
        return True
    return False


def classify_label(label_name):
    """Heuristic: classify a label as likely 'code' or 'data' based on name."""
    for pat in DATA_LABEL_PATTERNS:
        if pat.search(label_name):
            # But some data-named things can also be code
            for cpat in CODE_LABEL_PATTERNS:
                if cpat.search(label_name):
                    return 'ambiguous'
            return 'data'
    for pat in CODE_LABEL_PATTERNS:
        if pat.search(label_name):
            return 'code'
    return 'unknown'


class ByteBlock:
    """A consecutive block of .byte directives."""
    def __init__(self, file_path, start_line, label=None, preceding_comment=None):
        self.file_path = file_path
        self.start_line = start_line  # 1-indexed
        self.end_line = start_line
        self.label = label
        self.preceding_comment = preceding_comment or ""
        self.raw_bytes = []
        self.line_bytes = []  # [(line_no, [bytes])]
        self.preceded_by_instruction = False
        self.followed_by_instruction = False
        self.followed_by = ""  # first non-.byte thing after block

    def add_line(self, line_no, byte_values):
        self.end_line = line_no
        self.raw_bytes.extend(byte_values)
        self.line_bytes.append((line_no, byte_values))

    @property
    def num_bytes(self):
        return len(self.raw_bytes)

    @property
    def num_lines(self):
        return self.end_line - self.start_line + 1

    @property
    def rom_dir(self):
        rel = self.file_path.relative_to(REPO_ROOT)
        return str(rel).split('/')[0]


def extract_byte_blocks(file_path):
    """Extract all .byte blocks from a file."""
    try:
        with open(file_path, 'rb') as f:
            raw = f.read()
        lines = raw.decode('latin-1').splitlines()
    except Exception as e:
        print(f"  Warning: cannot read {file_path}: {e}", file=sys.stderr)
        return []

    blocks = []
    current_block = None
    last_label = None
    last_comment_lines = []
    last_was_instruction = False

    for i, line in enumerate(lines, 1):
        # Track labels
        lm = LABEL_RE.match(line)
        if lm:
            last_label = lm.group(1)
            last_comment_lines = []
            last_was_instruction = False
            continue

        # Track comments (accumulate for block documentation)
        if COMMENT_RE.match(line):
            last_comment_lines.append(line.strip())
            continue

        # Track empty lines
        if EMPTY_RE.match(line):
            last_comment_lines = []
            continue

        # Check for .byte
        byte_vals = parse_bytes_from_line(line)
        if byte_vals is not None:
            if current_block is None:
                current_block = ByteBlock(
                    file_path, i, last_label,
                    '\n'.join(last_comment_lines[-5:]) if last_comment_lines else None
                )
                current_block.preceded_by_instruction = last_was_instruction
            current_block.add_line(i, byte_vals)
            last_was_instruction = False
            continue

        # Not a .byte line — close current block if any
        if current_block is not None:
            current_block.followed_by_instruction = is_native_instruction(line)
            current_block.followed_by = line.strip()[:80]
            blocks.append(current_block)
            current_block = None

        # Track if this is a native instruction
        if is_native_instruction(line):
            last_was_instruction = True
            last_comment_lines = []
        elif DIRECTIVE_RE.match(line.strip()):
            last_was_instruction = False
            last_comment_lines = []
        last_label = None  # Reset label after non-label non-comment lines

    # Close final block
    if current_block is not None:
        blocks.append(current_block)

    return blocks


def try_disassemble(raw_bytes):
    """Try to disassemble bytes using llvm-mc. Returns (instructions, warnings, error)."""
    if not raw_bytes:
        return [], 0, None

    hex_input = ' '.join(f'0x{b:02x}' for b in raw_bytes)
    try:
        result = subprocess.run(
            [LLVM_MC, '--triple=tlcs900', '--disassemble'],
            input=hex_input,
            capture_output=True, text=True, timeout=10
        )
    except subprocess.TimeoutExpired:
        return [], 0, "timeout"
    except FileNotFoundError:
        return [], 0, "llvm-mc not found"

    instructions = []
    warnings = 0
    for line in result.stdout.splitlines():
        stripped = line.strip()
        if stripped and not stripped.startswith('.text'):
            instructions.append(stripped)
    for line in result.stderr.splitlines():
        if 'warning' in line.lower() or 'invalid' in line.lower():
            warnings += 1

    return instructions, warnings, None


def try_roundtrip(instruction):
    """Try to assemble an instruction and get its encoding. Returns bytes or None."""
    try:
        result = subprocess.run(
            [LLVM_MC, '--triple=tlcs900', '--show-encoding'],
            input=instruction + '\n',
            capture_output=True, text=True, timeout=5
        )
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return None

    for line in result.stdout.splitlines():
        m = re.search(r'# encoding:\s*\[(.*?)\]', line)
        if m:
            hex_vals = re.findall(r'0x([0-9a-fA-F]{2})', m.group(1))
            return [int(v, 16) for v in hex_vals]
    return None


def classify_block(block, verbose=False):
    """Classify a block as code/data and check LLVM decodability.

    Returns dict with classification info.
    """
    result = {
        'file': str(block.file_path.relative_to(REPO_ROOT)),
        'start_line': block.start_line,
        'end_line': block.end_line,
        'num_bytes': block.num_bytes,
        'num_lines': block.num_lines,
        'label': block.label or '',
        'rom_dir': block.rom_dir,
        'label_class': classify_label(block.label) if block.label else 'unknown',
        'context_class': 'unknown',
        'first_byte': f'0x{block.raw_bytes[0]:02x}' if block.raw_bytes else '',
        'disasm_status': 'untested',
        'decodable_count': 0,
        'undecodable_count': 0,
        'roundtrip_ok': 0,
        'roundtrip_fail': 0,
        'sample_instructions': [],
        'undecodable_prefixes': [],
        'classification': 'unknown',
    }

    # Context-based heuristics
    if block.preceded_by_instruction or block.followed_by_instruction:
        result['context_class'] = 'code_context'
    elif block.label and 'BlockData' in block.label:
        result['context_class'] = 'data_likely'
    elif block.label and 'Table' in block.label:
        result['context_class'] = 'data_likely'

    # Small single-byte blocks (1-2 bytes) between labels = likely padding/data
    if block.num_bytes <= 2 and not block.preceded_by_instruction:
        result['classification'] = 'data_padding'
        result['disasm_status'] = 'skipped_small'
        return result

    # Try disassembly
    instructions, warnings, error = try_disassemble(block.raw_bytes)
    if error:
        result['disasm_status'] = f'error_{error}'
        return result

    if not instructions:
        result['disasm_status'] = 'no_output'
        result['classification'] = 'data_likely'
        return result

    # Check if disassembly looks like code
    code_like_ops = {'ld', 'ldw', 'ldb', 'add', 'sub', 'and', 'or', 'xor', 'cp', 'cpw',
                     'push', 'pop', 'pushw', 'call', 'calr', 'ret', 'jp', 'jr', 'jrl',
                     'djnz', 'bit', 'set', 'res', 'sla', 'sra', 'srl', 'sll', 'rr', 'rl',
                     'rrc', 'rlc', 'inc', 'dec', 'mul', 'div', 'neg', 'cpl', 'lda',
                     'ei', 'di', 'halt', 'nop', 'swi', 'reti', 'ldc', 'stc',
                     'ldir', 'lddr', 'cpir', 'cpdr', 'ex', 'extz', 'exts',
                     'st8_24', 'ld8_24', 'stdi8', 'stdi16'}
    control_ops = {'ret', 'call', 'calr', 'jp', 'jr', 'jrl', 'djnz', 'reti'}

    has_control = False
    code_count = 0
    total_insts = len(instructions)

    for inst in instructions:
        mnemonic = inst.split()[0].lower() if inst.split() else ''
        # Strip condition codes
        base = mnemonic.rstrip('0123456789').split('.')[0]
        if base in code_like_ops or any(base.startswith(c) for c in code_like_ops):
            code_count += 1
        if base in control_ops:
            has_control = True

    # Avg instruction length
    if total_insts > 0:
        avg_len = block.num_bytes / total_insts
    else:
        avg_len = 0

    # Code heuristics
    is_code = False
    if warnings == 0 and total_insts >= 2:
        if has_control and code_count / max(total_insts, 1) >= 0.3:
            is_code = True
        elif avg_len > 1.5 and code_count / max(total_insts, 1) >= 0.5:
            is_code = True
    if result['context_class'] == 'code_context':
        is_code = True  # Trust context
    if result['label_class'] == 'code':
        is_code = True

    # For code blocks: try round-trip on each instruction
    decodable = 0
    undecodable = 0
    roundtrip_ok = 0
    roundtrip_fail = 0
    undecodable_prefixes = Counter()

    if is_code and total_insts > 0:
        result['disasm_status'] = 'decoded'
        result['sample_instructions'] = instructions[:5]

        # Check round-trip for each instruction
        for inst in instructions:
            rt_bytes = try_roundtrip(inst)
            if rt_bytes is not None:
                decodable += 1
                roundtrip_ok += 1
            else:
                undecodable += 1
                roundtrip_fail += 1
    elif warnings > 0:
        # Partial decode — some bytes couldn't decode
        result['disasm_status'] = 'partial_decode'
        result['sample_instructions'] = instructions[:5]

        # Identify which prefixes failed
        # We can't easily map warnings to specific bytes, so track first bytes of block
        if block.raw_bytes:
            undecodable_prefixes[f'0x{block.raw_bytes[0]:02x}'] += 1
    else:
        result['disasm_status'] = 'data_heuristic'

    result['decodable_count'] = decodable
    result['undecodable_count'] = undecodable
    result['roundtrip_ok'] = roundtrip_ok
    result['roundtrip_fail'] = roundtrip_fail
    result['undecodable_prefixes'] = dict(undecodable_prefixes)

    if is_code:
        if undecodable == 0 and roundtrip_ok > 0:
            result['classification'] = 'code_decodable'
        elif decodable > 0:
            result['classification'] = 'code_partial'
        else:
            result['classification'] = 'code_needs_llvm'
    elif result['context_class'] == 'data_likely' or result['label_class'] == 'data':
        result['classification'] = 'data'
    else:
        result['classification'] = 'unknown'

    return result


def main():
    parser = argparse.ArgumentParser(description='Audit .byte code in ROM disassembly')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    parser.add_argument('--csv', type=str, help='Write CSV report to file')
    parser.add_argument('--file', type=str, help='Audit only this file')
    parser.add_argument('--min-bytes', type=int, default=3, help='Min bytes per block to audit (default: 3)')
    parser.add_argument('--no-disasm', action='store_true', help='Skip disassembly (fast count only)')
    args = parser.parse_args()

    if args.file:
        p = Path(args.file)
        if not p.is_absolute():
            p = REPO_ROOT / p
        files = [p]
    else:
        files = find_s_files()

    print(f"Scanning {len(files)} .s files...", file=sys.stderr)

    all_blocks = []
    for f in files:
        blocks = extract_byte_blocks(f)
        all_blocks.extend(blocks)

    print(f"Found {len(all_blocks)} .byte blocks ({sum(b.num_bytes for b in all_blocks)} total bytes)", file=sys.stderr)

    # Filter by minimum size
    blocks_to_audit = [b for b in all_blocks if b.num_bytes >= args.min_bytes]
    print(f"Auditing {len(blocks_to_audit)} blocks (>= {args.min_bytes} bytes)...", file=sys.stderr)

    results = []
    for i, block in enumerate(blocks_to_audit):
        if (i + 1) % 100 == 0:
            print(f"  [{i+1}/{len(blocks_to_audit)}]", file=sys.stderr)

        if args.no_disasm:
            result = {
                'file': str(block.file_path.relative_to(REPO_ROOT)),
                'start_line': block.start_line,
                'end_line': block.end_line,
                'num_bytes': block.num_bytes,
                'num_lines': block.num_lines,
                'label': block.label or '',
                'rom_dir': block.rom_dir,
                'first_byte': f'0x{block.raw_bytes[0]:02x}' if block.raw_bytes else '',
                'classification': 'unaudited',
            }
        else:
            result = classify_block(block, verbose=args.verbose)

        results.append(result)

        if args.verbose and result.get('classification', '').startswith('code'):
            print(f"  CODE: {result['file']}:{result['start_line']}-{result['end_line']} "
                  f"({result['num_bytes']}B) label={result['label']} "
                  f"class={result['classification']}", file=sys.stderr)

    # === Summary Report ===
    print("\n" + "=" * 80)
    print("RAW BYTE CODE AUDIT REPORT")
    print("=" * 80)

    # By ROM
    by_rom = defaultdict(lambda: {'blocks': 0, 'bytes': 0, 'code_blocks': 0, 'code_bytes': 0})
    for r in results:
        rom = r['rom_dir']
        by_rom[rom]['blocks'] += 1
        by_rom[rom]['bytes'] += r['num_bytes']
        if r.get('classification', '').startswith('code'):
            by_rom[rom]['code_blocks'] += 1
            by_rom[rom]['code_bytes'] += r['num_bytes']

    print(f"\n{'ROM':<15} {'Blocks':>8} {'Bytes':>10} {'Code Blk':>10} {'Code Bytes':>12}")
    print("-" * 60)
    for rom in sorted(by_rom.keys()):
        d = by_rom[rom]
        print(f"{rom:<15} {d['blocks']:>8} {d['bytes']:>10} {d['code_blocks']:>10} {d['code_bytes']:>12}")

    # By classification
    by_class = Counter()
    bytes_by_class = Counter()
    for r in results:
        c = r.get('classification', 'unknown')
        by_class[c] += 1
        bytes_by_class[c] += r['num_bytes']

    print(f"\n{'Classification':<25} {'Blocks':>8} {'Bytes':>10}")
    print("-" * 45)
    for cls in sorted(by_class.keys()):
        print(f"{cls:<25} {by_class[cls]:>8} {bytes_by_class[cls]:>10}")

    # Code blocks by first byte (opcode prefix)
    code_results = [r for r in results if r.get('classification', '').startswith('code')]
    if code_results:
        prefix_count = Counter()
        prefix_bytes = Counter()
        for r in code_results:
            fb = r.get('first_byte', '??')
            prefix_count[fb] += 1
            prefix_bytes[fb] += r['num_bytes']

        print(f"\nCode .byte blocks by first byte (opcode prefix):")
        print(f"{'Prefix':<10} {'Blocks':>8} {'Bytes':>10}")
        print("-" * 30)
        for prefix, count in prefix_count.most_common(30):
            print(f"{prefix:<10} {count:>8} {prefix_bytes[prefix]:>10}")

    # Decodable now (free wins)
    decodable = [r for r in results if r.get('classification') == 'code_decodable']
    if decodable:
        print(f"\n=== FREE WINS: {len(decodable)} blocks ({sum(r['num_bytes'] for r in decodable)} bytes) already decodable by LLVM ===")
        for r in sorted(decodable, key=lambda x: -x['num_bytes'])[:20]:
            print(f"  {r['file']}:{r['start_line']} ({r['num_bytes']}B) label={r['label']}")

    # Needs LLVM work
    needs_llvm = [r for r in results if r.get('classification') in ('code_needs_llvm', 'code_partial')]
    if needs_llvm:
        print(f"\n=== NEEDS LLVM: {len(needs_llvm)} blocks ({sum(r['num_bytes'] for r in needs_llvm)} bytes) need backend additions ===")
        for r in sorted(needs_llvm, key=lambda x: -x['num_bytes'])[:20]:
            print(f"  {r['file']}:{r['start_line']} ({r['num_bytes']}B) label={r['label']} "
                  f"decode={r.get('decodable_count',0)}/{r.get('decodable_count',0)+r.get('undecodable_count',0)}")

    # Top files by code bytes
    file_code_bytes = defaultdict(int)
    file_code_blocks = defaultdict(int)
    for r in code_results:
        file_code_bytes[r['file']] += r['num_bytes']
        file_code_blocks[r['file']] += 1

    if file_code_bytes:
        print(f"\nTop files by code .byte bytes:")
        print(f"{'File':<60} {'Blocks':>8} {'Bytes':>10}")
        print("-" * 80)
        for f, b in sorted(file_code_bytes.items(), key=lambda x: -x[1])[:20]:
            print(f"{f:<60} {file_code_blocks[f]:>8} {b:>10}")

    # Write CSV
    if args.csv:
        fieldnames = ['file', 'start_line', 'end_line', 'num_bytes', 'num_lines',
                       'label', 'rom_dir', 'first_byte', 'classification',
                       'disasm_status', 'decodable_count', 'undecodable_count',
                       'roundtrip_ok', 'roundtrip_fail', 'sample_instructions']
        with open(args.csv, 'w', newline='') as csvf:
            writer = csv.DictWriter(csvf, fieldnames=fieldnames, extrasaction='ignore')
            writer.writeheader()
            for r in results:
                row = dict(r)
                row['sample_instructions'] = '; '.join(r.get('sample_instructions', []))
                writer.writerow(row)
        print(f"\nCSV report written to {args.csv}", file=sys.stderr)

    print(f"\nTotal: {len(results)} blocks, {sum(r['num_bytes'] for r in results)} bytes", file=sys.stderr)
    print(f"Code: {len(code_results)} blocks, {sum(r['num_bytes'] for r in code_results)} bytes", file=sys.stderr)


if __name__ == '__main__':
    main()
