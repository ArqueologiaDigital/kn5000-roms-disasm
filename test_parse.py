import sys, re
def parse_data_lines(lines):
    data = []
    for line in lines:
        line = line.split(';')[0].strip()
        if not line: continue
        if line.startswith('.byte'):
            parts = line[5:].split(',')
            for p in parts:
                p = p.strip()
                if not p: continue
                data.append((int(p, 0), False))
        elif line.startswith('.ascii') or line.startswith('.asciz'):
            is_z = line.startswith('.asciz')
            m = re.search(r'"(.*)"', line)
            if m:
                text = m.group(1).encode('utf-8').decode('unicode_escape')
                for c in text:
                    data.append((ord(c), True))
                if is_z:
                    data.append((0, True))
    return data

lines = [
    '\t.ascii "LCD PANE"',
    '\t.asciz "L TEST"',
    '\t.byte 0xff'
]
print(parse_data_lines(lines))
