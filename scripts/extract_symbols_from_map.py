import sys
import re

def extract_symbols(map_file, output_file):
    symbols = []
    in_code_segment = False
    
    with open(map_file, 'r') as f:
        for line in f:
            # Check for CODE segment start
            if 'Symbols in Segment CODE' in line:
                in_code_segment = True
                continue
            
            # Check for end of segment (next segment or empty line pattern)
            if in_code_segment and line.startswith('Symbols in Segment'):
                in_code_segment = False
                continue
            
            if in_code_segment:
                # Parse symbol line: NAME    Int    ADDRESS    ...
                match = re.match(r'^(\S+)\s+Int\s+([0-9A-Fa-f]+)\s+', line)
                if match:
                    name = match.group(1)
                    addr = int(match.group(2), 16)
                    # Skip internal/local labels (containing dots that aren't at start)
                    if '.' not in name or name.startswith('.'):
                        symbols.append((name, addr))
    
    # Sort by address
    symbols.sort(key=lambda x: x[1])
    
    # Write output
    with open(output_file, 'w') as f:
        f.write("# Symbol Reference File\n")
        f.write("# Format: SYMBOL_NAME ADDRESS\n")
        f.write(f"# Generated from: {map_file}\n")
        f.write("#\n")
        for name, addr in symbols:
            f.write(f"{name} 0x{addr:06X}\n")
    
    return len(symbols)

if __name__ == '__main__':
    count = extract_symbols(sys.argv[1], sys.argv[2])
    print(f"Extracted {count} symbols")
