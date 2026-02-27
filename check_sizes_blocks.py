import sys, ast

def strip_comment(line):
    in_quote = False
    for i, c in enumerate(line):
        if c == '"':
            in_quote = not in_quote
        elif c == ';' and not in_quote:
            return line[:i].strip()
    return line.strip()

def get_line_size(line):
    code = strip_comment(line)
    if not code: return 0
    if code.startswith('.byte'):
        parts = code[5:].split(',')
        c = 0
        for p in parts:
            if p.strip(): c += 1
        return c
    elif code.startswith('.asciz'):
        try:
            text = ast.literal_eval('b' + code[6:].strip())
            return len(text) + 1
        except:
            return 0
    elif code.startswith('.ascii'):
        try:
            text = ast.literal_eval('b' + code[6:].strip())
            return len(text)
        except:
            return 0
    return 0

def extract_blocks(lines):
    blocks = []
    current_block = []
    current_block_size = 0
    current_start_line = 0
    in_macro = False
    
    for i, line in enumerate(lines):
        code = strip_comment(line)
        if code.startswith('.macro'):
            in_macro = True
            continue
        if code.startswith('.endm'):
            in_macro = False
            continue
        if in_macro:
            continue
            
        is_data = code.startswith('.byte') or code.startswith('.ascii') or code.startswith('.asciz') or code.startswith('aligned_string')
        
        if is_data:
            if not current_block:
                current_start_line = i
            current_block.append(line)
            current_block_size += get_line_size(line)
        else:
            if current_block:
                blocks.append((current_start_line, current_block, current_block_size))
                current_block = []
                current_block_size = 0
                
    if current_block:
        blocks.append((current_start_line, current_block, current_block_size))
        
    return blocks

with open('maincpu/kn5000_v10_program.s') as f:
    orig = f.readlines()

import subprocess
subprocess.run(['python3', 'scripts/refactor_llvm_strings.py'])

with open('maincpu/kn5000_v10_program.s') as f:
    mod = f.readlines()

orig_blocks = extract_blocks(orig)
mod_blocks = extract_blocks(mod)

if len(orig_blocks) != len(mod_blocks):
    print(f"Block count mismatch! Orig: {len(orig_blocks)}, Mod: {len(mod_blocks)}")
    # This might happen if a string was split across a non-data line? No.

for i in range(min(len(orig_blocks), len(mod_blocks))):
    o_start, o_lines, o_size = orig_blocks[i]
    m_start, m_lines, m_size = mod_blocks[i]
    if o_size != m_size:
        print(f"Size mismatch in block {i} (orig line {o_start})!")
        print(f"Orig size: {o_size}")
        for l in o_lines: print("  " + l.strip())
        print(f"Mod size: {m_size}")
        for l in m_lines: print("  " + l.strip())
        break
