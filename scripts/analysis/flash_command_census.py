#!/usr/bin/env python3
"""flash_command_census.py -- which KN5000 "ROM" regions are really writable FLASH?

QUESTION ANSWERED
    The MAME kn5000 driver maps custom_data (IC19 @0x300000), rhythm_data
    (IC14 @0x400000), table_data (IC1/IC3 @0x800000) and the program ROMs
    (IC4/IC6 @0xE00000) with .rom(), i.e. read-only.  Now that the main-CPU
    image is complete source, does the firmware issue JEDEC/AMD flash command
    sequences to any of them -- identify, sector erase, program?

    This script finds the AMD-command-set signature in the disassembly:
      * the two unlock ADDRESS offsets a routine adds to a base register, and
      * the command DATA values it writes there,
    then reports the device IDs the firmware accepts.  It does not guess: it
    prints file:line for every hit so each one can be read in context.

COMMAND
    cd ~/compartilhado/disasm-lanes/drvkn5000
    python3 scripts/analysis/flash_command_census.py v10/maincpu

WHAT THE SIGNATURE MEANS
    An AMD/Fujitsu-command-set flash is unlocked by writing 0xAA to word
    address 0x5555 and 0x55 to word address 0x2AAA, then a command byte to
    0x5555 again:
        0x90 = autoselect (read manufacturer at +0, device at +1)
        0xA0 = program one word     0x80,0x30 = sector erase
        0x80,0x10 = chip erase      0xF0 = reset to read mode
    The BYTE offsets those word addresses land on tell you the bus width of the
    array:
        0xAAAA / 0x5554   -> word address * 2  -> ONE x16 device (16-bit bus)
        0x15554 / 0xAAA8  -> word address * 4  -> TWO x16 devices (32-bit bus)
    and the command DATA replicated per 16-bit lane says the same thing
    (0x00AA for one device, 0x00AA00AA for a pair).

NOTE: these sources are latin-1, not UTF-8.  Always decode explicitly.
"""
import os, re, sys, collections

UNLOCK_OFF = {0xaaaa: 'word 0x5555 * 2  -> ONE x16 device (16-bit array)',
              0x5554: 'word 0x2AAA * 2  -> ONE x16 device (16-bit array)',
              0x15554: 'word 0x5555 * 4 -> TWO x16 devices (32-bit array)',
              0xaaa8: 'word 0x2AAA * 4  -> TWO x16 devices (32-bit array)'}
CMD = {0x00aa: 'unlock #1 (AA), 16-bit lane',
       0x0055: 'unlock #2 (55), 16-bit lane',
       0x0090: 'autoselect (90), 16-bit lane',
       0x00a0: 'program (A0), 16-bit lane',
       0x0080: 'erase setup (80), 16-bit lane',
       0x0030: 'sector erase (30), 16-bit lane',
       0x0010: 'chip erase (10), 16-bit lane',
       0x00f0: 'reset to read (F0), 16-bit lane',
       0xaa00aa: 'unlock #1 (AA) on BOTH lanes -> 32-bit array',
       0x550055: 'unlock #2 (55) on BOTH lanes -> 32-bit array',
       0x900090: 'autoselect (90) on BOTH lanes -> 32-bit array',
       0xa000a0: 'program (A0) on BOTH lanes -> 32-bit array',
       0x800080: 'erase setup (80) on BOTH lanes -> 32-bit array',
       0x300030: 'sector erase (30) on BOTH lanes -> 32-bit array',
       0x100010: 'chip erase (10) on BOTH lanes -> 32-bit array'}
# JEDEC device IDs the firmware compares against (x16 parts).
DEVID = {0x2223: 'Am29F400BT / MBM29F400TC  (4 Mbit, TOP boot)',
         0x22ab: 'Am29F400BB / MBM29F400BC  (4 Mbit, BOTTOM boot)',
         0x22d6: 'Am29F800BT / MBM29F800TA  (8 Mbit, TOP boot)',
         0x2258: 'Am29F800BB / MBM29F800BA  (8 Mbit, BOTTOM boot)'}
MFR = {1: 'AMD', 4: 'Fujitsu'}

HEXTOK = re.compile(r'0x[0-9a-fA-F]+')
# A command word only counts when it is the SOURCE of a store into a memory
# operand -- `ldw (xwa), 0xaa`, `ld (xbc), xwa`, `stiw_da (0xNNNN), 0x..`.  Without
# this the small values (0x10, 0x55, 0xaa) match every data table in the tree:
# the unfiltered run reported 1,919 sites for 0x10 alone, essentially all of them
# `.byte` rows.  Immediates loaded into a register on the way to such a store are
# caught by the `ld xwa, 0x..` arm.
STORE = re.compile(r'\(\s*(?:x?[a-z]{1,3}|0x[0-9a-fA-F]+)[^)]*\)\s*,')
LOADIMM = re.compile(r'^\s*(?:ld|ldw|ldl)\s+x?[a-z]{1,3}\s*,\s*0x[0-9a-fA-F]+\s*$')

PROXIMITY = 14   # lines: a 16-bit command word counts only this close to an unlock offset

def scan(root):
    hits = collections.defaultdict(list)
    for dp, _, ns in os.walk(root):
        for n in sorted(ns):
            if not n.endswith('.s'):
                continue
            p = os.path.join(dp, n)
            text = open(p, encoding='latin-1').read().split('\n')
            unlock_lines = set()
            for i, l in enumerate(text, 1):
                b = l.split(';', 1)[0]
                for h in HEXTOK.finditer(b):
                    if int(h.group(0), 16) in UNLOCK_OFF:
                        unlock_lines.add(i)
            lines_seen = []
            for ln, line in enumerate(open(p, encoding='latin-1'), 1):
                body = line.split(';', 1)[0]
                if body.lstrip().startswith(('.byte', '.word', '.long', '.set',
                                             '.equ', '.ascii', '.short', '.incbin',
                                             '.org', '.zero', '.space')):
                    continue
                is_store = bool(STORE.search(body)) or 'stiw_ind' in body
                is_loadimm = bool(LOADIMM.match(body.rstrip()))
                lines_seen.append((ln, body))
                for h in HEXTOK.finditer(body):
                    v = int(h.group(0), 16)
                    for tbl, kind in ((UNLOCK_OFF, 'unlock-offset'),
                                      (CMD, 'command-word'),
                                      (DEVID, 'device-id')):
                        if v not in tbl:
                            continue
                        if kind == 'command-word':
                            if not (is_store or is_loadimm):
                                continue
                            # the small 16-bit values (0x10, 0x55, 0xAA, 0x30, 0x80)
                            # occur all over ordinary code, so require an unlock
                            # offset within PROXIMITY lines -- the flash sequences are
                            # always written as one tight block.  Unfiltered, 0x10
                            # alone scored 1,919 sites, almost all `.byte` rows.
                            if v <= 0xffff and not any(
                                    abs(u - ln) <= PROXIMITY for u in unlock_lines):
                                continue
                        hits[(kind, v)].append(f'{p}:{ln}: {line.rstrip()}')
    return hits

def main():
    root = sys.argv[1] if len(sys.argv) > 1 else 'v10/maincpu'
    hits = scan(root)
    for kind, title, tbl in (('unlock-offset', 'UNLOCK ADDRESS OFFSETS (base + N)', UNLOCK_OFF),
                             ('command-word', 'COMMAND DATA WORDS', CMD),
                             ('device-id', 'DEVICE IDs THE FIRMWARE ACCEPTS', DEVID)):
        print(f'\n===== {title} =====')
        for v in sorted(tbl):
            sites = hits.get((kind, v), [])
            if not sites:
                continue
            print(f'\n{v:#x}  {tbl[v]}   [{len(sites)} site(s)]')
            for s in sites:
                print('   ' + s)
    print(f'\n===== manufacturer IDs =====')
    print('   the identify routines compare the manufacturer word against '
          + ', '.join(f'{k} ({v})' for k, v in sorted(MFR.items()))
          + '  -- see Flash_IdentifyAndValidateChip / HDAE5000_Detect')

if __name__ == '__main__':
    main()
