#!/usr/bin/env python3
"""Convert .byte code blocks to native TLCS-900 instructions in audio_control_engine.s.

Uses llvm-mc to disassemble and verify round-trip encoding.
Uses binary I/O to preserve Latin-1 bytes.
"""

import subprocess
import re
import sys
import os

LLVM_MC = "/mnt/shared/llvm-project/build/bin/llvm-mc"
TARGET_FILE = "maincpu/audio/audio_control_engine.s"

# Labels that mark DATA sections - skip conversion
DATA_LABELS = {
    "FileIO_BytecodeData",
    "VoiceMode_ParamConfigTables",
    "MidiStream_SysExJumpTable",
    "MidiStream_CtrlJumpTable",
    "MidiStream_CmdJumpTable",
    "MidiSeqBuf_ProcessorTable",
    "TempoRing_ProcessorTable",
    "MidiCtrl_ModeDispatch_Table",
    "VoiceMode3_DispatchTable",
    "VoiceParam_ModeDispatch_Table",
    "MidiVoiceNote_Dispatch_Table",
    "MidiStream_Processor_Table",
    "RegisterBit_Manipulate_Table",
}

# Cache for assembly results
_asm_cache = {}


def read_file_binary(path):
    with open(path, 'rb') as f:
        return f.read()


def write_file_binary(path, data):
    with open(path, 'wb') as f:
        f.write(data)


def parse_byte_line(line_text):
    """Extract hex bytes from a .byte line."""
    text = line_text.strip()
    if not text.startswith('.byte 0x'):
        return None
    # Strip comments (everything after ; or // or #)
    # Be careful: only strip line-end comments, not hex values
    comment_pos = text.find(';')
    if comment_pos >= 0:
        text = text[:comment_pos]
    comment_pos = text.find('//')
    if comment_pos >= 0:
        text = text[:comment_pos]
    vals = re.findall(r'0x([0-9a-fA-F]{2})', text)
    if not vals:
        return None
    return [int(v, 16) for v in vals]


def assemble_instruction(inst):
    """Assemble instruction, return encoding bytes or None. Cached."""
    if inst in _asm_cache:
        return _asm_cache[inst]

    try:
        result = subprocess.run(
            [LLVM_MC, "--triple=tlcs900", "--show-encoding"],
            input=inst, capture_output=True, text=True, timeout=5
        )
    except subprocess.TimeoutExpired:
        _asm_cache[inst] = None
        return None

    if result.returncode != 0 or "error" in result.stderr.lower():
        _asm_cache[inst] = None
        return None

    for line in result.stdout.strip().split('\n'):
        m = re.search(r'encoding:\s*\[(.*?)\]', line)
        if m:
            enc_str = m.group(1)
            bytes_out = []
            for b in enc_str.split(','):
                b = b.strip()
                if b.startswith('0x'):
                    bytes_out.append(int(b, 16))
            _asm_cache[inst] = bytes_out
            return bytes_out

    _asm_cache[inst] = None
    return None


# Cache for disassembly results: tuple(bytes) -> (inst, length) or None
_disasm_cache = {}


def try_disasm_exact(byte_list):
    """Try byte lengths 1-7 to find exact instruction with round-trip verification."""
    key = tuple(byte_list[:7])
    if key in _disasm_cache:
        return _disasm_cache[key]

    for length in range(1, min(8, len(byte_list) + 1)):
        subset = byte_list[:length]
        hex_str = ' '.join(f'0x{b:02x}' for b in subset)

        try:
            result = subprocess.run(
                [LLVM_MC, "--triple=tlcs900", "--disassemble"],
                input=hex_str, capture_output=True, text=True, timeout=5
            )
        except subprocess.TimeoutExpired:
            continue

        stdout = result.stdout.strip()
        stderr = result.stderr.strip()

        if 'invalid instruction encoding' in stderr:
            continue
        if not stdout:
            continue

        lines = [l.strip() for l in stdout.split('\n') if l.strip()]
        if len(lines) != 1:
            continue  # Must decode to exactly one instruction from these bytes

        inst = lines[0]

        # Round-trip verification
        enc = assemble_instruction(inst)
        if enc is None:
            continue

        if enc == subset:
            _disasm_cache[key] = (inst, length)
            return inst, length

    _disasm_cache[key] = None
    return None


def process_byte_block(byte_list):
    """Process a block of bytes, converting what we can.
    Returns list of (type, data, size)."""
    result = []
    pos = 0
    pending_bytes = []

    while pos < len(byte_list):
        remaining = byte_list[pos:]
        res = try_disasm_exact(remaining)
        if res:
            if pending_bytes:
                result.append(('bytes', list(pending_bytes), len(pending_bytes)))
                pending_bytes = []
            inst, n = res
            result.append(('inst', inst, n))
            pos += n
        else:
            pending_bytes.append(byte_list[pos])
            pos += 1

    if pending_bytes:
        result.append(('bytes', list(pending_bytes), len(pending_bytes)))

    return result


def find_byte_blocks(lines_text):
    """Find all contiguous .byte blocks."""
    blocks = []
    in_block = False
    block_start = 0
    block_bytes = []
    current_label = ""
    in_data = False

    for i, line in enumerate(lines_text):
        stripped = line.strip()

        label_match = re.match(r'^([A-Za-z_]\w*):', stripped)
        if label_match:
            current_label = label_match.group(1)
            in_data = current_label in DATA_LABELS

        byte_vals = parse_byte_line(stripped)

        if byte_vals is not None:
            if not in_block:
                in_block = True
                block_start = i
                block_bytes = []
                block_in_data = in_data
            block_bytes.extend(byte_vals)
        else:
            if in_block:
                blocks.append((block_start, i, block_bytes, block_in_data))
                in_block = False
                block_bytes = []

    if in_block:
        blocks.append((block_start, len(lines_text), block_bytes, in_data))

    return blocks


def main():
    os.chdir("/mnt/shared/kn5000-roms-disasm")

    data = read_file_binary(TARGET_FILE)
    lines_raw = data.split(b'\n')
    lines_text = [l.decode('latin-1') for l in lines_raw]

    blocks = find_byte_blocks(lines_text)

    print(f"Found {len(blocks)} .byte blocks")

    code_blocks = [(s, e, b, d) for s, e, b, d in blocks if not d]
    data_blocks = [(s, e, b, d) for s, e, b, d in blocks if d]

    print(f"  Code blocks (to convert): {len(code_blocks)}")
    print(f"  Data blocks (skip): {len(data_blocks)}")

    total_converted = 0
    total_remaining = 0
    total_inst_count = 0

    replacements = {}

    for block_idx, (start, end, byte_list, _) in enumerate(code_blocks):
        if not byte_list:
            continue

        result = process_byte_block(byte_list)

        # Verify total size preserved
        total_size = 0
        for rtype, rdata, rsize in result:
            if rtype == 'inst':
                enc = assemble_instruction(rdata)
                if enc is None:
                    print(f"  ERROR: Cannot re-assemble {rdata!r}")
                    sys.exit(1)
                total_size += len(enc)
            else:
                total_size += len(rdata)

        if total_size != len(byte_list):
            print(f"  SIZE MISMATCH at lines {start+1}-{end}: expected {len(byte_list)}, got {total_size}")
            sys.exit(1)

        inst_count = sum(1 for t, _, _ in result if t == 'inst')
        byte_count = sum(s for t, _, s in result if t == 'bytes')

        if inst_count == 0:
            continue

        total_converted += sum(s for t, _, s in result if t == 'inst')
        total_remaining += byte_count
        total_inst_count += inst_count

        # Generate replacement lines
        new_lines = []
        for rtype, rdata, rsize in result:
            if rtype == 'inst':
                new_lines.append(f"\t{rdata}")
            else:
                for i in range(0, len(rdata), 8):
                    chunk = rdata[i:i+8]
                    parts = ", ".join(f"0x{b:02x}" for b in chunk)
                    new_lines.append(f"\t.byte {parts}")

        replacements[(start, end)] = new_lines

        near_label = ""
        for j in range(start, max(0, start - 20), -1):
            m = re.match(r'^([A-Za-z_]\w*):', lines_text[j].strip())
            if m:
                near_label = m.group(1)
                break
        print(f"  Block {start+1}-{end} ({near_label}): {inst_count} inst, {byte_count} remaining bytes")

    if not replacements:
        print("No conversions found!")
        return

    print(f"\nTotal: {total_inst_count} instructions ({total_converted} bytes) converted, {total_remaining} bytes remaining")

    # Apply replacements in reverse order
    new_lines_text = list(lines_text)
    for (start, end), new_lines in sorted(replacements.items(), reverse=True):
        new_lines_text[start:end] = new_lines

    output = '\n'.join(new_lines_text)
    write_file_binary(TARGET_FILE, output.encode('latin-1'))

    print(f"\nWrote {len(new_lines_text)} lines to {TARGET_FILE}")


if __name__ == "__main__":
    main()
