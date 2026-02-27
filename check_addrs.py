import re

with open('maincpu/kn5000_v10_program.s', 'r') as f:
    lines = f.readlines()
    
addr = 0
for i in range(len(lines)):
    line = lines[i].strip()
    
    # Very rough address tracking based on comments
    m = re.search(r'; ([0-9A-Fa-f]+)', line)
    if m:
        try:
            addr = int(m.group(1), 16)
        except:
            pass
            
    if line.startswith('.asciz'):
        m = re.search(r'"(.*)"', line)
        if m:
            text = m.group(1).encode('utf-8').decode('unicode_escape')
            length = len(text) + 1
            
            if i + 1 < len(lines):
                next_line = lines[i+1].strip()
                if next_line.startswith('.byte 0xff'):
                    even_start = (addr % 2 == 0)
                    even_len = (length % 2 == 0)
                    ends_at = (addr + length)
                    even_end = (ends_at % 2 == 0)
                    print(f"Address: {hex(addr)} (even={even_start}), length={length}, ends_at={hex(ends_at)} (even={even_end}), text='{text}'")
                    addr += length + 1 # +1 for 0xff
