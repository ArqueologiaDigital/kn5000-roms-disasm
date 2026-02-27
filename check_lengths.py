import re

with open('maincpu/kn5000_v10_program.s', 'r') as f:
    lines = f.readlines()
    
for i in range(len(lines)):
    line = lines[i].strip()
    if line.startswith('.asciz'):
        m = re.search(r'"(.*)"', line)
        if m:
            text = m.group(1).encode('utf-8').decode('unicode_escape')
            length = len(text) + 1 # +1 for null
            
            # Check if next line is .byte 0xff
            if i + 1 < len(lines):
                next_line = lines[i+1].strip()
                if next_line.startswith('.byte 0xff'):
                    print(f"Found .asciz + 0xff: length={length}, even={length%2==0}, text='{text}'")
