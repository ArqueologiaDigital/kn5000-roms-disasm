#!/usr/bin/env python3
"""io_address_census.py -- which hardware addresses does the KN5000 firmware touch?

QUESTION ANSWERED
    Every byte of the nine gated KN5000 images is now real source, so every
    absolute-address memory operand the firmware uses is visible in the tree.
    This script enumerates those operands, splits them into reads / writes /
    read-modify-writes, and buckets them against the MAME driver's address map,
    so an address the firmware touches but the driver does not map shows up as an
    explicit hole.

    It reports STATIC SITES (one instruction operand = one site), not dynamic
    access counts.  A single site inside a wrapper routine can be the whole
    machine's access path to a device.

COMMAND
    cd ~/compartilhado/disasm-lanes/drvkn5000
    python3 scripts/analysis/io_address_census.py v10/maincpu --map main
    python3 scripts/analysis/io_address_census.py v9/maincpu  --map main
    python3 scripts/analysis/io_address_census.py v7/maincpu  --map main
    python3 scripts/analysis/io_address_census.py subcpu      --map sub
    python3 scripts/analysis/io_address_census.py v142        --map sub
    # add --list LO-HI to print the individual sites in a range:
    python3 scripts/analysis/io_address_census.py v10/maincpu --map main --list 0x160000-0x16000f

KNOWN BLIND SPOT -- READ THIS BEFORE QUOTING A ZERO
    Only DIRECT-ADDRESSING operands are counted.  Firmware that loads a base into
    a register and then uses register-indirect stores is INVISIBLE to the default
    mode -- e.g. the sub-CPU's DSP1 driver does
        ld xhl, 0x130000 ; ld (xhl), a ; ld (xhl + 2), e
    and contributes ZERO direct-addressing sites at 0x130000.  A zero here is
    therefore NOT evidence that an address is untouched.  Use --bases to list the
    immediates in device ranges that are loaded into a register (which catches
    exactly that idiom) before concluding anything is unused.

HOW AN ADDRESS IS RECOGNISED
    TLCS-900 direct addressing appears in this tree in two spellings --
        ldb_da  l, (0x110008)        stb_da  (0x11000a), a       [parenthesised]
        ldw_da  xhl, 0x100000        stw_da  0x100000, xwa       [bare]
    -- plus the 24-bit direct RMW forms (setda_24 / chgda_24 / incdi16_24 / ...).
    The mnemonic PREFIX gives the direction: ld/cp/push = read, st/sti = write,
    inc/dec/set/res/chg/add/sub/and/or/xor to memory = read-modify-write.
    `lda_24` is load-effective-address, NOT a memory access, and is excluded; so
    is a bare `ld xhl, 0x120000`, which only computes a pointer.

WHAT THE OUTPUT MEANS
    Each row is  <address>  R=<reads> W=<writes> M=<rmw>  <driver bucket>.
    "UNMAPPED" = outside every entry of the driver's address_map as transcribed in
    DRIVER_MAP below (kn5000.cpp maincpu_mem/subcpu_mem, read 2026-09-02).  The
    KN5000 EXTENSION SLOT installs more on top of the main map when a card is
    fitted; --map main+hdae adds the HD-AE5000 card's own card_map so the two
    cases can be told apart.

NOTE: these sources are latin-1, not UTF-8.  Always decode explicitly.
"""
import argparse, os, re, sys, collections

# Transcribed from ~/compartilhado/kn7000_mame/src/mame/matsushita/kn5000.cpp
# (maincpu_mem / subcpu_mem) and src/devices/bus/technics/kn5000/hdae5000.cpp
# (card_map), both read 2026-09-02.
MAIN = [
    (0x000000, 0x0fffff, 'DRAM work RAM (IC9/IC10)'),
    (0x110008, 0x110008, 'FDC MSR / auxcmd'),
    (0x11000a, 0x11000a, 'FDC data FIFO'),
    (0x120000, 0x12ffff, 'FDC DMA acknowledge'),
    (0x140000, 0x14ffff, 'sub-CPU latch (IC22/IC23)'),
    (0x1703b0, 0x1703df, 'MN89304 VGA io_map'),
    (0x1a0000, 0x1dffff, 'MN89304 VGA linear framebuffer'),
    (0x1e0000, 0x1fffff, 'battery SRAM IC21 (nvram)'),
    (0x300000, 0x3fffff, 'custom_data flash IC19'),
    (0x400000, 0x7fffff, 'rhythm_data ROM IC14'),
    (0x800000, 0xbfffff, 'table_data ROM IC1/IC3 (+mirror)'),
    (0xe00000, 0xffffff, 'program flash IC4/IC6'),
]
HDAE = [
    (0x130010, 0x13001f, 'HD-AE5000 ATA cs0'),
    (0x130020, 0x13002f, 'HD-AE5000 ATA cs1'),
    (0x160000, 0x160007, 'HD-AE5000 uPD71055 PPI (i8255)'),
    (0x200000, 0x27ffff, 'HD-AE5000 SRAM IC5/IC6'),
    (0x280000, 0x2fffff, 'HD-AE5000 ROM IC4'),
]
SUB = [
    (0x000000, 0x0fffff, 'DRAM work RAM (IC28/IC29)'),
    (0x100000, 0x100001, 'tonegen status_r / addr_w'),
    (0x100002, 0x100003, 'tonegen data'),
    (0x110000, 0x110001, 'tonegen keybed data'),
    (0x110002, 0x110003, 'tonegen keybed status'),
    (0x120000, 0x12ffff, 'main-CPU latch (IC22/IC23)'),
    (0x130000, 0x130001, 'DSP1 IC311 reg address'),
    (0x130002, 0x130003, 'DSP1 IC311 reg data'),
    (0x1e0000, 0x1effff, 'waveform/sample RAM -- noprw() STUB'),
    (0xfe0000, 0xffffff, 'sub-CPU mask ROM IC30'),
]
DRIVER_MAP = {'main': MAIN, 'main+hdae': MAIN + HDAE, 'sub': SUB}

LINE = re.compile(r'^\s*([a-z][a-z0-9_]*)\s+(.*)$')
HEX  = re.compile(r'0x[0-9a-fA-F]{4,8}')

READ_PREFIX  = ('ld', 'cp', 'push')
WRITE_PREFIX = ('st',)
RMW_PREFIX   = ('inc', 'dec', 'set', 'res', 'chg', 'bit', 'add', 'sub',
                'and', 'or', 'xor', 'mul', 'div')

def direction(mn):
    """'r', 'w', 'm' or None for a direct-addressing mnemonic."""
    if mn.startswith('lda'):        # load effective address: no memory access
        return None
    if not ('_da' in mn or 'da' in mn.split('_')[0][-2:] or
            re.search(r'd[aim]\d*_24$', mn) or mn.endswith('_da')):
        return None
    if mn.startswith(WRITE_PREFIX):
        return 'w'
    if mn.startswith(READ_PREFIX):
        return 'r'
    if mn.startswith(RMW_PREFIX):
        return 'm'
    return None

def bucket(addr, table):
    for lo, hi, label in table:
        if lo <= addr <= hi:
            return label
    return 'UNMAPPED'

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('root')
    ap.add_argument('--map', choices=sorted(DRIVER_MAP), required=True)
    ap.add_argument('--list', default=None, help='LO-HI: also print each site')
    ap.add_argument('--bases', action='store_true',
                    help='instead of direct-addressing sites, list immediates in device '
                         'ranges loaded into a register (ld/lda REG, 0xNNNNNN) -- these are '
                         'the bases of register-indirect access, invisible to the default mode')
    ap.add_argument('--min-addr', default='0x100000',
                    help='ignore operands below this (default 0x100000: below that is '
                         'DRAM on both CPUs, not a device)')
    a = ap.parse_args()
    lo_hi = None
    if a.list:
        s, e = a.list.split('-')
        lo_hi = (int(s, 16), int(e, 16))
    minaddr = int(a.min_addr, 16)

    counts = collections.defaultdict(lambda: [0, 0, 0])
    sites = collections.defaultdict(list)
    files = 0
    for dirpath, _, names in os.walk(a.root):
        for n in sorted(names):
            if not n.endswith('.s'):
                continue
            files += 1
            p = os.path.join(dirpath, n)
            with open(p, encoding='latin-1') as f:
                for ln, line in enumerate(f, 1):
                    body = line.split(';', 1)[0]
                    m = LINE.match(body)
                    if not m:
                        continue
                    if a.bases:
                        if m.group(1) not in ('ld', 'lda', 'lda_24', 'ldl'):
                            continue
                        ops = m.group(2)
                        if ',' not in ops:
                            continue
                        d = 'r'
                        for h in HEX.finditer(ops.split(',', 1)[1]):
                            addr = int(h.group(0), 16)
                            if addr < minaddr:
                                continue
                            counts[addr][0] += 1
                            if lo_hi and lo_hi[0] <= addr <= lo_hi[1]:
                                sites[addr].append(f'{p}:{ln}: {line.rstrip()}')
                        continue
                    d = direction(m.group(1))
                    if d is None:
                        continue
                    for h in HEX.finditer(m.group(2)):
                        addr = int(h.group(0), 16)
                        if addr < minaddr:
                            continue
                        counts[addr]['rwm'.index(d)] += 1
                        if lo_hi and lo_hi[0] <= addr <= lo_hi[1]:
                            sites[addr].append(f'{p}:{ln}: {line.rstrip()}')

    table = DRIVER_MAP[a.map]
    print(f'# root={a.root}  files={files}  distinct addresses >= {minaddr:#08x}: {len(counts)}')
    print(f'# driver map: {a.map}')
    tot = [0, 0, 0]
    for addr in sorted(counts):
        r, w, mm = counts[addr]
        b = bucket(addr, table)
        if b == 'UNMAPPED':
            tot[0] += r; tot[1] += w; tot[2] += mm
        print(f'{addr:#08x}  R={r:<4d} W={w:<4d} M={mm:<4d} {b}')
    print(f'# UNMAPPED totals: {tot[0]} reads, {tot[1]} writes, {tot[2]} read-modify-writes')
    if lo_hi:
        print('# --- sites ---')
        for addr in sorted(sites):
            for s in sites[addr]:
                print(s)

if __name__ == '__main__':
    main()
