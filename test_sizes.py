import sys, re

def get_real_size(line):
    line = line.strip()
    # Handle comments that aren't inside strings
    # A robust way is to find the first semicolon not inside quotes
    in_quote = False
    comment_idx = -1
    escaped = False
    for i, c in enumerate(line):
        if escaped:
            escaped = False
            continue
        if c == '':
            escaped = True
            continue
        if c == '"':
            in_quote = not in_quote
        elif c == ';' and not in_quote:
            comment_idx = i
            break
            
    if comment_idx != -1:
        line = line[:comment_idx].strip()
        
    if not line: return 0
    
    if line.startswith('.byte'):
        parts = line[5:].split(',')
        c = 0
        for p in parts:
            if p.strip(): c += 1
        return c
    elif line.startswith('.asciz'):
        # Parse the string manually
        m = re.search(r'"(.*)"', line)
        if not m: return 0
        s = m.group(1)
        # count bytes
        c = 0
        i = 0
        while i < len(s):
            if s[i] == '':
                if i+1 < len(s):
                    c += 1
                    i += 2
                else:
                    c += 1
                    i += 1
            else:
                c += 1
                i += 1
        return c + 1 # +1 for null
    elif line.startswith('.ascii'):
        m = re.search(r'"(.*)"', line)
        if not m: return 0
        s = m.group(1)
        c = 0
        i = 0
        while i < len(s):
            if s[i] == '':
                if i+1 < len(s):
                    c += 1
                    i += 2
                else:
                    c += 1
                    i += 1
            else:
                c += 1
                i += 1
        return c
    elif line.startswith('aligned_string'):
        # aligned_string is .asciz + .p2align 1, 0xff
        # We can't know the exact size without the address, but let's assume the user was right and it replaces an .asciz + .byte 0xff perfectly.
        # Wait, if we just want to find where the size changes, we can return the length + padding.
        # Actually, let's just return the unpadded length and compare it to the original unpadded length?
        # NO, aligned_string replaced a block. We need to compare the block sizes!
        pass
    return 0

print("Ready.")
