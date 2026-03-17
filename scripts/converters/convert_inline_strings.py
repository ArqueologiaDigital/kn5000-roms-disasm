#!/usr/bin/env python3
"""Convert .byte lines with embedded ASCII strings to .asciz/aligned_string.

Detects null-terminated ASCII strings in .byte directives (identified by
'; DB ... "str" ...' comments) and converts them to proper string directives.

Handles:
- Pure string+null: .byte 0x4d,0x49,0x43,0x00 -> .asciz "MIC"
- String+null+0xff: .byte 0x4e,0x4f,0x00,0xff -> aligned_string "NO"
- Prefix bytes + string: splits into .byte prefix + string directive
- Multiple strings per line: .asciz "ON " / .asciz "OFF"
- Split strings across lines: merges "NAMI"+"NG" -> "NAMING"
"""

import re
import sys


def parse_byte_values(line_text):
    """Extract byte values from a .byte directive line."""
    # Get the part before any comment
    code_part = line_text.split(';')[0].strip()
    if not code_part.startswith('.byte'):
        return None
    vals_str = code_part[5:].strip()
    vals = []
    for v in vals_str.split(','):
        v = v.strip()
        if v:
            vals.append(int(v, 0))
    return vals


def bytes_to_strings(byte_vals):
    """Parse byte values into a sequence of segments: strings and raw bytes.

    Returns list of tuples:
        ('string', "text", has_ff_pad)  - null-terminated string
        ('bytes', [val, ...])           - non-string bytes
    """
    segments = []
    i = 0
    n = len(byte_vals)

    while i < n:
        # Try to find a printable ASCII string starting at i
        # String must be at least 1 printable char + null terminator
        j = i
        while j < n and 0x20 <= byte_vals[j] <= 0x7e:
            j += 1

        str_len = j - i
        if str_len >= 1 and j < n and byte_vals[j] == 0x00:
            # Found a valid string
            # First, emit any prefix bytes before the string start
            # (already handled by iteration)

            text = ''.join(chr(b) for b in byte_vals[i:j])
            # Check for 0xFF padding after the null
            has_ff = (j + 1 < n and byte_vals[j + 1] == 0xFF)
            segments.append(('string', text, has_ff))
            i = j + 1  # skip null
            if has_ff:
                i += 1  # skip 0xFF pad
        else:
            # Not a string, emit as raw byte
            segments.append(('bytes', [byte_vals[i]]))
            i += 1

    # Merge consecutive raw byte segments
    merged = []
    for seg in segments:
        if seg[0] == 'bytes' and merged and merged[-1][0] == 'bytes':
            merged[-1] = ('bytes', merged[-1][1] + seg[1])
        else:
            merged.append(seg)

    return merged


def format_segments(segments, indent='\t'):
    """Convert segments to assembly lines."""
    lines = []
    for seg in segments:
        if seg[0] == 'string':
            text = seg[1]
            has_ff = seg[2]
            # Escape any special chars in the string
            escaped = text.replace('\\', '\\\\').replace('"', '\\"')
            if has_ff:
                lines.append(f'{indent}aligned_string "{escaped}"')
            else:
                lines.append(f'{indent}.asciz "{escaped}"')
        elif seg[0] == 'bytes':
            vals = seg[1]
            hex_vals = ', '.join(f'0x{v:02x}' for v in vals)
            lines.append(f'{indent}.byte {hex_vals}')
    return lines


def check_prev_line_continuation(prev_bytes, cur_bytes):
    """Check if prev_bytes ends with printable ASCII that continues into cur_bytes.

    Returns (merge_count, string_text) if a cross-line string is found,
    where merge_count is how many bytes from end of prev to include.
    Returns None if no cross-line string.
    """
    if prev_bytes is None:
        return None

    # Find trailing printable ASCII in prev_bytes
    trail_start = len(prev_bytes)
    while trail_start > 0 and 0x20 <= prev_bytes[trail_start - 1] <= 0x7e:
        trail_start -= 1

    trail_len = len(prev_bytes) - trail_start
    if trail_len == 0:
        return None

    # Check if cur_bytes starts with printable ASCII continuing the string
    j = 0
    while j < len(cur_bytes) and 0x20 <= cur_bytes[j] <= 0x7e:
        j += 1

    # Must end with null terminator
    if j > 0 and j < len(cur_bytes) and cur_bytes[j] == 0x00:
        full_text = ''.join(chr(b) for b in prev_bytes[trail_start:]) + \
                    ''.join(chr(b) for b in cur_bytes[:j])
        return (trail_len, full_text)

    return None


def main():
    src = "maincpu/kn5000_v10_program.s"
    if len(sys.argv) > 1:
        src = sys.argv[1]

    with open(src, 'rb') as f:
        data = f.read()

    lines = data.split(b'\n')
    new_lines = []
    count = 0
    prev_byte_vals = None
    prev_line_idx = None

    for i, line_bytes in enumerate(lines):
        line = line_bytes.decode('latin-1')

        # Check if this line has the string-in-comment marker
        if '; DB' not in line or '"' not in line.split('; DB')[1] if '; DB' in line else True:
            # Not a target line - but track .byte values for cross-line detection
            stripped = line.strip()
            if stripped.startswith('.byte') and '; DB' not in line:
                prev_byte_vals = parse_byte_values(stripped)
                prev_line_idx = len(new_lines)
            else:
                prev_byte_vals = None
                prev_line_idx = None
            new_lines.append(line_bytes)
            continue

        # This is a target line with string data in comment
        byte_vals = parse_byte_values(line.strip())
        if byte_vals is None:
            new_lines.append(line_bytes)
            prev_byte_vals = None
            prev_line_idx = None
            continue

        # Detect label prefix on this line
        label_prefix = ''
        stripped = line.lstrip('\t ')
        if ':' in stripped and stripped.index(':') < stripped.index('.byte'):
            label_prefix = stripped[:stripped.index(':') + 1]

        # Check for cross-line string continuation
        merge_info = check_prev_line_continuation(prev_byte_vals, byte_vals)

        if merge_info:
            trail_len, full_text = merge_info
            # Modify the previous line to remove trailing bytes
            remaining_prev = prev_byte_vals[:-trail_len]

            # Check if null+0xff follows the merged string
            # The string text from cross-line is full_text
            # Find where in cur_bytes the string ends
            str_in_cur = len(full_text) - (len(prev_byte_vals) - (len(prev_byte_vals) - trail_len))
            # Actually, let's find the null terminator position in cur_bytes
            j = 0
            while j < len(byte_vals) and 0x20 <= byte_vals[j] <= 0x7e:
                j += 1
            # byte_vals[j] should be 0x00 (null terminator)
            has_ff = (j + 1 < len(byte_vals) and byte_vals[j + 1] == 0xFF)
            after_null = j + 1
            if has_ff:
                after_null = j + 2
            remaining_cur = byte_vals[after_null:]

            # Rebuild previous line
            if remaining_prev:
                hex_vals = ', '.join(f'0x{v:02x}' for v in remaining_prev)
                new_prev = f'\t.byte {hex_vals}'.encode('latin-1')
            else:
                new_prev = None

            if prev_line_idx is not None:
                if new_prev is not None:
                    new_lines[prev_line_idx] = new_prev
                else:
                    new_lines[prev_line_idx] = b''  # Will be a blank line

            # Build replacement for current line
            escaped = full_text.replace('\\', '\\\\').replace('"', '\\"')
            result_lines = []
            if has_ff:
                result_lines.append(f'\taligned_string "{escaped}"')
            else:
                result_lines.append(f'\t.asciz "{escaped}"')

            if remaining_cur:
                # Process remaining bytes for more strings
                segs = bytes_to_strings(remaining_cur)
                result_lines.extend(format_segments(segs))

            for rl in result_lines:
                new_lines.append(rl.encode('latin-1'))
            count += 1
        else:
            # No cross-line merge needed - process this line standalone
            segments = bytes_to_strings(byte_vals)
            result_lines = format_segments(segments)

            for j, rl in enumerate(result_lines):
                if j == 0 and label_prefix:
                    rl = label_prefix + rl.lstrip('\t')
                new_lines.append(rl.encode('latin-1'))
            count += 1

        prev_byte_vals = None
        prev_line_idx = None

    with open(src, 'wb') as f:
        f.write(b'\n'.join(new_lines))

    print(f"Converted {count} inline string lines in {src}")


if __name__ == "__main__":
    main()
