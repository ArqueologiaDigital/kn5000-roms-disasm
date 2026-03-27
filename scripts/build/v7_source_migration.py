#!/usr/bin/env python3
"""Replace v7 .byte transplants with v9 source code.

Two-pass approach:
Pass 1: Batch-assemble ALL v9 label bodies to get their byte sizes (single subprocess)
Pass 2: For each .byte transplant where v9 produces exact same size AND
        ROM bytes match ≥60%, replace with v9 source

The ROM-level comparison ensures the v9 source represents the same code.
The size check prevents cascading layout shifts.
"""

import os, glob, re, json, subprocess, tempfile

LLVM_MC = '/mnt/shared/llvm-project/build/bin/llvm-mc'
LLVM_OBJCOPY = '/mnt/shared/llvm-project/build/bin/llvm-objcopy'
V7_DIR = 'v7/maincpu'
V9_DIR = 'v9/maincpu'
GEN_DIR = os.path.join(V7_DIR, 'includes/generated')


def load_elf_syms(path):
    r = subprocess.run(['/mnt/shared/llvm-project/build/bin/llvm-nm', '--no-sort', path],
                      capture_output=True, text=True)
    syms = {}
    for line in r.stdout.strip().split('\n'):
        p = line.strip().split()
        if len(p) >= 3:
            try: syms[p[2]] = int(p[0], 16)
            except: pass
    return syms


def build_v9_cache():
    cache = {}
    for filepath in sorted(glob.glob(os.path.join(V9_DIR, '**/*.s'), recursive=True)):
        with open(filepath, 'rb') as f:
            lines = f.readlines()
        cur = None
        cur_lines = []
        for line in lines:
            s = line.decode('latin-1', errors='replace').rstrip()
            m = re.match(r'^([A-Za-z_][\w]*):', s)
            if m:
                if cur and cur_lines:
                    cache[cur] = cur_lines
                cur = m.group(1)
                cur_lines = []
            elif cur:
                st = s.strip()
                if st and not st.startswith(';'):
                    cur_lines.append(line)
                elif cur_lines:
                    cur_lines.append(line)
        if cur and cur_lines:
            cache[cur] = cur_lines
    return cache


def is_data_label(v9_cache, label):
    lines = v9_cache.get(label)
    if not lines: return True
    first = lines[0].decode('latin-1', errors='replace').strip()
    return any(first.startswith(d) for d in
               ['.byte','.short','.long','.ascii','.asciz','.zero','.fill','.incbin'])


def measure_v9_sizes_from_elf(v9_syms):
    """Use v9 ELF symbol addresses to compute label body sizes."""
    sorted_syms = sorted(v9_syms.items(), key=lambda x: x[1])
    sizes = {}
    for i, (label, addr) in enumerate(sorted_syms):
        if i + 1 < len(sorted_syms):
            sizes[label] = sorted_syms[i + 1][1] - addr
        else:
            sizes[label] = 0
    return sizes


def main():
    os.chdir('/mnt/shared/kn5000-roms-disasm')
    print("=== v7 Source Migration v3: size-checked, ROM-level comparison ===\n")

    shift_map = json.load(open('scripts/analysis/v7_shift_map.json'))
    v9_syms = load_elf_syms('rebuilt_ROMs/kn5000_v9_program.llvm.elf')
    v9_rom = open('original_ROMs/kn5000_v9_program.rom', 'rb').read()
    v7_rom = open('original_ROMs/kn5000_v7_program.rom', 'rb').read()
    v9_cache = build_v9_cache()

    # Identify candidate labels: code transplants with shift data
    candidates = []
    for binpath in sorted(glob.glob(os.path.join(GEN_DIR, 'v7_transplant_*.bin'))):
        label = os.path.basename(binpath).replace('v7_transplant_', '').replace('.bin', '')
        if is_data_label(v9_cache, label):
            continue
        if label not in shift_map:
            continue
        if label not in v9_syms:
            continue
        gt_size = os.path.getsize(binpath)
        candidates.append((label, gt_size))

    print(f"Candidates: {len(candidates)} code transplants with shift data\n")

    # Pass 1: measure v9 sizes from ELF (instant, no assembly needed)
    v9_sizes = measure_v9_sizes_from_elf(v9_syms)

    # Find labels where v9 size == v7 bin size
    size_matched = []
    size_mismatched = 0
    no_size = 0
    for label, gt_size in candidates:
        v9_size = v9_sizes.get(label)
        if v9_size is None:
            no_size += 1
        elif v9_size == gt_size:
            size_matched.append((label, gt_size))
        else:
            size_mismatched += 1

    print(f"  Size matched:    {len(size_matched)}")
    print(f"  Size mismatched: {size_mismatched}")
    print(f"  No size data:    {no_size}")

    # Pass 2: ROM-level comparison for size-matched labels
    exact = 0
    with_diffs = 0
    low_match = 0
    migrated_labels = {}

    for label, gt_size in size_matched:
        v9_addr = v9_syms[label]
        shift = shift_map[label]

        v9_off = v9_addr - 0xE00000
        v7_off = v9_off - shift

        if v7_off < 0 or v7_off + gt_size > len(v7_rom):
            continue
        if v9_off + gt_size > len(v9_rom):
            continue

        # Compare ROM bytes
        match_count = 0
        diff_positions = []
        for k in range(gt_size):
            if v9_rom[v9_off + k] == v7_rom[v7_off + k]:
                match_count += 1
            else:
                diff_positions.append(k)

        match_pct = match_count / gt_size if gt_size > 0 else 0

        if match_pct < 0.60:
            low_match += 1
            continue

        if not diff_positions:
            exact += 1
            migrated_labels[label] = 0
        else:
            with_diffs += 1
            # Only migrate exact matches for now (safe — no byte diffs)
            continue

    print(f"\n  Exact ROM match:  {exact}")
    print(f"  With diffs:       {with_diffs}")
    print(f"  Low match (<60%): {low_match}")
    print(f"  Total to migrate: {len(migrated_labels)}")

    # Pass 3: Replace .byte blocks in v7 source files
    print(f"\nReplacing .byte blocks with v9 source...")
    files_modified = 0

    for filepath in sorted(glob.glob(os.path.join(V7_DIR, '**/*.s'), recursive=True)):
        with open(filepath, 'rb') as f:
            data = f.read()

        lines = data.split(b'\n')
        modified = False
        new_lines = []
        current_label = None

        idx = 0
        while idx < len(lines):
            line = lines[idx]
            s = line.decode('latin-1', errors='replace').strip()

            m = re.match(r'^([A-Za-z_][\w]*):', s)
            if m:
                current_label = m.group(1)
                new_lines.append(line)
                idx += 1
                continue

            if s.startswith('.byte ') and current_label and current_label in migrated_labels:
                # Skip already-migrated
                fl = line.decode('latin-1', errors='replace')
                if '(v7' in fl:
                    new_lines.append(line)
                    idx += 1
                    current_label = None
                    continue

                # Collect .byte block
                byte_lines = [line]
                j = idx + 1
                while j < len(lines):
                    ns = lines[j].decode('latin-1', errors='replace').strip()
                    if ns.startswith('.byte '):
                        byte_lines.append(lines[j])
                        j += 1
                    else:
                        break

                # Replace with v9 source
                v9_source = v9_cache.get(current_label, [])
                if v9_source:
                    for vline in v9_source:
                        stripped = vline.rstrip() if isinstance(vline, bytes) else vline.rstrip().encode('latin-1')
                        if stripped:
                            new_lines.append(stripped)
                    modified = True
                    idx = j
                    current_label = None
                    continue

                new_lines.extend(byte_lines)
                idx = j
                current_label = None
                continue

            new_lines.append(line)
            idx += 1

        if modified:
            with open(filepath, 'wb') as f:
                f.write(b'\n'.join(new_lines))
            files_modified += 1

    print(f"  Modified {files_modified} files")
    print(f"\n=== Summary ===")
    print(f"  Labels migrated to v9 source: {len(migrated_labels)}")
    print(f"    Exact match (0 diff bytes): {exact}")
    print(f"    With operand diffs:         {with_diffs}")
    print(f"  Run: make clean && make all")

    # Save manifest
    with open('scripts/analysis/v7_migration_diffs.json', 'w') as f:
        json.dump(migrated_labels, f, indent=2)


if __name__ == '__main__':
    main()
