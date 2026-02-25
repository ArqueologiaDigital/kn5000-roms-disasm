#!/usr/bin/env python3
"""
Refactor LLVM assembly string literals:
- Merge split .ascii/.asciz across 8-byte boundaries
- Convert .asciz + .byte 0xff to aligned_string macro
- Promote standalone .byte sequences to strings (strict criteria)
- Revert false .ascii in data tables back to .byte
- Preserve all comments
"""

import re
import os
import sys

MACRO_DEF = "\n.macro aligned_string str:vararg\n\t.asciz \\str\n\t.p2align 1, 0xff\n.endm\n"


def unescape(s):
    """Unescape assembly string to raw characters."""
    res = []
    i = 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            c = s[i + 1]
            if c == 'n':
                res.append('\n'); i += 2
            elif c == 'r':
                res.append('\r'); i += 2
            elif c == 't':
                res.append('\t'); i += 2
            elif c == '"':
                res.append('"'); i += 2
            elif c == '\\':
                res.append('\\'); i += 2
            elif c.isdigit():
                # Octal escape \NNN
                octal = c
                j = i + 2
                while j < len(s) and j < i + 4 and s[j].isdigit():
                    octal += s[j]
                    j += 1
                res.append(chr(int(octal, 8)))
                i = j
            else:
                res.append(c); i += 2
        else:
            res.append(s[i]); i += 1
    return ''.join(res)


def escape_string(s):
    """Escape raw string for assembly .ascii/.asciz directive."""
    result = []
    for c in s:
        o = ord(c)
        if c == '"':
            result.append('\\"')
        elif c == '\\':
            result.append('\\\\')
        elif c == '\n':
            result.append('\\n')
        elif c == '\r':
            result.append('\\r')
        elif c == '\t':
            result.append('\\t')
        elif 0x20 <= o <= 0x7E:
            result.append(c)
        else:
            result.append(f'\\{o:03o}')
    return ''.join(result)


def extract_comment(line):
    """Extract trailing comment from line, respecting string quotes."""
    in_quote = False
    i = 0
    while i < len(line):
        c = line[i]
        if in_quote:
            if c == '\\':
                i += 2
                continue
            elif c == '"':
                in_quote = False
        else:
            if c == '"':
                in_quote = True
            elif c == ';':
                return line[:i].rstrip(), line[i:].rstrip()
        i += 1
    return line.rstrip(), ''


def parse_data_line(raw):
    """Parse a data directive line.

    Returns (kind, indent, data, comment) or None if not a data directive.
    kind: 'ascii', 'asciz', 'byte'
    data: string text (for ascii/asciz) or list of ints (for byte)
    """
    stripped = raw.rstrip('\n\r')
    code, comment = extract_comment(stripped)
    code_s = code.strip()

    indent_m = re.match(r'^(\s*)', raw)
    indent = indent_m.group(1) if indent_m else ''

    if code_s.startswith('.byte ') or code_s.startswith('.byte\t'):
        byte_str = code_s[5:].strip()
        if not byte_str:
            return None
        vals = []
        for p in byte_str.split(','):
            p = p.strip()
            if not p:
                continue
            try:
                vals.append(int(p, 0))
            except ValueError:
                return None
        if vals:
            return ('byte', indent, vals, comment)
        return None

    m = re.match(r'\.(ascii|asciz)\s+"((?:[^"\\]|\\.)*)"', code_s)
    if m:
        is_z = m.group(1) == 'asciz'
        text = unescape(m.group(2))
        return ('asciz' if is_z else 'ascii', indent, text, comment)

    return None


def is_printable(b):
    return 0x20 <= b <= 0x7E


def bytes_to_hex(vals):
    return ', '.join(f'0x{b:02x}' for b in vals)


def format_string_line(indent, kind, text, comment=''):
    safe = escape_string(text)
    c = f"\t{comment}" if comment else ''
    if kind == 'aligned':
        return f'{indent}aligned_string "{safe}"{c}\n'
    elif kind == 'asciz':
        return f'{indent}.asciz "{safe}"{c}\n'
    else:
        return f'{indent}.ascii "{safe}"{c}\n'


def format_byte_line(indent, vals, comment=''):
    c = f"\t{comment}" if comment else ''
    return f'{indent}.byte {bytes_to_hex(vals)}{c}\n'


# === Processing passes ===

def revert_false_ascii(raw_lines):
    """Pass 1: Revert .ascii strings that are actually numerical data.

    Heuristic: <=5 chars, no spaces, no lowercase, surrounded by .byte
    with non-printable values.
    """
    result = list(raw_lines)

    for i in range(len(result)):
        parsed = parse_data_line(result[i])
        if not parsed or parsed[0] != 'ascii':
            continue

        _, indent, text, comment = parsed

        if len(text) > 5 or ' ' in text:
            continue
        if any(c.islower() for c in text):
            continue

        # Check: surrounded by .byte with non-printable values
        has_byte_before = False
        has_byte_after = False

        for j in range(i - 1, max(i - 3, -1), -1):
            p = parse_data_line(result[j])
            if p and p[0] == 'byte':
                if any(not is_printable(b) for b in p[2]):
                    has_byte_before = True
                break
            elif p and p[0] in ('ascii', 'asciz'):
                break
            elif result[j].strip():
                break  # non-data, non-blank line

        for j in range(i + 1, min(i + 3, len(result))):
            p = parse_data_line(result[j])
            if p and p[0] == 'byte':
                if any(not is_printable(b) for b in p[2]):
                    has_byte_after = True
                break
            elif p and p[0] in ('ascii', 'asciz'):
                break
            elif result[j].strip():
                break

        if has_byte_before and has_byte_after:
            vals = [ord(c) for c in text]
            result[i] = format_byte_line(indent, vals, comment)

    return result


def merge_strings(raw_lines):
    """Pass 2: Merge split .ascii/.asciz and extend with adjacent .byte."""
    result = []
    i = 0
    n = len(raw_lines)

    while i < n:
        parsed = parse_data_line(raw_lines[i])

        if not parsed or parsed[0] not in ('ascii', 'asciz'):
            # Check standalone .byte promotion
            if parsed and parsed[0] == 'byte':
                promoted = try_promote_byte_line(parsed)
                if promoted:
                    result.append(promoted)
                    i += 1
                    continue
            result.append(raw_lines[i])
            i += 1
            continue

        # Start merging from this string line
        kind, indent, text, comment = parsed
        has_null = (kind == 'asciz')
        merged_comment = comment
        j = i + 1
        remaining_byte_parts = []  # list of (indent, vals, comment)

        # Extend the string by consuming following compatible lines
        while j < n and not has_null:
            next_parsed = parse_data_line(raw_lines[j])

            if not next_parsed:
                break  # non-data line = barrier

            next_kind, next_indent, next_data, next_comment = next_parsed

            # Both have comments? Don't merge.
            if merged_comment and next_comment:
                break

            if next_kind == 'ascii':
                text += next_data
                if not merged_comment:
                    merged_comment = next_comment
                j += 1

            elif next_kind == 'asciz':
                text += next_data
                has_null = True
                if not merged_comment:
                    merged_comment = next_comment
                j += 1

            elif next_kind == 'byte':
                byte_vals = next_data
                consumed = 0
                extra = ''

                for bval in byte_vals:
                    if is_printable(bval):
                        extra += chr(bval)
                        consumed += 1
                    elif bval == 0x00:
                        has_null = True
                        consumed += 1
                        break
                    else:
                        break

                if consumed > 0 and (extra or has_null):
                    remaining = byte_vals[consumed:]

                    if merged_comment and next_comment and remaining:
                        break  # Can't split comment between merged and remaining

                    text += extra
                    if not merged_comment:
                        merged_comment = next_comment

                    if remaining:
                        rem_comment = next_comment if merged_comment != next_comment else ''
                        remaining_byte_parts.append((indent, remaining, rem_comment))
                        j += 1
                        break  # Stop merging — remaining non-printable bytes must stay in place

                    j += 1
                else:
                    break
            else:
                break

        # Did we actually merge anything?
        if j == i + 1 and not remaining_byte_parts:
            result.append(raw_lines[i])
            i = j
            continue

        # Emit the merged string
        str_kind = 'asciz' if has_null else 'ascii'
        result.append(format_string_line(indent, str_kind, text, merged_comment))

        # Emit remaining byte parts from partially consumed .byte lines
        for r_indent, r_vals, r_comment in remaining_byte_parts:
            result.append(format_byte_line(r_indent, r_vals, r_comment))

        i = j

    return result


def try_promote_byte_line(parsed):
    """Try to promote standalone .byte to string. Returns new line(s) or None.

    Only promotes if: 8+ printable chars, contains lowercase or space,
    null-terminated, and line has no comment.
    """
    _, indent, vals, comment = parsed

    if comment:
        return None  # Don't touch commented .byte lines

    start = 0
    while start < len(vals):
        if not is_printable(vals[start]):
            start += 1
            continue

        end = start
        while end < len(vals) and is_printable(vals[end]):
            end += 1

        # Need null terminator
        if end < len(vals) and vals[end] == 0x00:
            text = ''.join(chr(b) for b in vals[start:end])

            # Strict: 8+ chars AND lowercase or space
            if len(text) >= 8 and any(c.islower() or c == ' ' for c in text):
                parts = []
                if start > 0:
                    parts.append(format_byte_line(indent, vals[:start]))
                parts.append(format_string_line(indent, 'asciz', text))
                after = end + 1
                if after < len(vals):
                    parts.append(format_byte_line(indent, vals[after:]))
                return ''.join(parts)

        start = end + 1

    return None


def convert_aligned_strings(lines):
    """Pass 3: Convert .asciz + .byte 0xff to aligned_string."""
    result = []
    i = 0
    n = len(lines)

    while i < n:
        if i + 1 < n:
            p1 = parse_data_line(lines[i])
            p2 = parse_data_line(lines[i + 1])

            if (p1 and p1[0] == 'asciz' and
                    p2 and p2[0] == 'byte' and
                    len(p2[2]) == 1 and p2[2][0] == 0xff):

                _, indent, text, comment1 = p1
                _, _, _, comment2 = p2

                # p2align 1,0xff only adds a byte when position is odd
                total_bytes = len(text) + 1  # string + null
                if total_bytes % 2 == 1:
                    # Both have comments? Don't merge.
                    if comment1 and comment2:
                        result.append(lines[i])
                        i += 1
                        continue

                    merged_comment = comment1 or comment2
                    result.append(format_string_line(indent, 'aligned', text, merged_comment))
                    i += 2
                    continue

        result.append(lines[i])
        i += 1

    return result


def inject_macro(lines):
    """Pass 4: Inject aligned_string macro after .text if needed."""
    has_macro = any('.macro aligned_string' in line for line in lines)
    has_usage = any(
        'aligned_string "' in line and '.macro' not in line
        for line in lines
    )

    if not has_usage or has_macro:
        return lines

    result = []
    injected = False
    for line in lines:
        result.append(line)
        if not injected and line.strip() == '.text':
            result.append(MACRO_DEF)
            injected = True

    return result


def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        raw_lines = f.readlines()

    # Pass 1: Revert false .ascii to .byte
    raw_lines = revert_false_ascii(raw_lines)
    # Pass 2: Merge split strings and extend into adjacent .byte
    result = merge_strings(raw_lines)
    # Pass 3: Convert .asciz + .byte 0xff -> aligned_string
    result = convert_aligned_strings(result)
    # Pass 4: Inject macro if needed
    result = inject_macro(result)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(result)


def main():
    exclude_files = {'msp_factory_defaults.s'}
    target_dirs = ['maincpu', 'subcpu', 'hdae5000', 'table_data', 'custom_data']

    for tdir in target_dirs:
        if not os.path.exists(tdir):
            continue
        for root, dirs, files in os.walk(tdir):
            for fname in files:
                if (fname.endswith('.s') and
                        fname not in exclude_files and
                        'test_' not in fname):
                    path = os.path.join(root, fname)
                    print(f"Processing {path}...")
                    process_file(path)


if __name__ == '__main__':
    main()
