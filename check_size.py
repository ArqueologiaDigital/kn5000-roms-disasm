import subprocess

subprocess.run(['git', 'checkout', 'maincpu/kn5000_v10_program.s'])
with open('maincpu/kn5000_v10_program.s', 'r') as f:
    orig = f.readlines()

subprocess.run(['python3', 'scripts/refactor_llvm_strings.py'])
with open('maincpu/kn5000_v10_program.s', 'r') as f:
    mod = f.readlines()
    
# Since my script only modifies data blocks, I can't easily compare line-by-line.
# Let's count the number of bytes in each file!
import re

def count_bytes(lines):
    total = 0
    for line in lines:
        code = line.split(';')[0].strip()
        if code.startswith('.byte'):
            parts = code[5:].split(',')
            for p in parts:
                if p.strip(): total += 1
        elif code.startswith('.asciz'):
            m = re.search(r'"(.*)"', code)
            if m:
                # Need exact string length, but wait...
                pass
    return total

print("Lengths won't match exactly without a proper parser.")
