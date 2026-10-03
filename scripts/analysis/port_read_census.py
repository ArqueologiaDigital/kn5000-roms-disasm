#!/usr/bin/env python3
"""port_read_census.py -- which TMP94C241 I/O PORT bits does the firmware READ?

QUESTION ANSWERED
    The MAME kn5000 driver wires some of the two CPUs' I/O ports to real sources,
    some to `set_constant(...)`, and some not at all.  A port the firmware reads
    and BRANCHES on, but the driver leaves unwired, is a silently wrong input:
    MAME's tmp94c241 `port_r` returns `(latch & CR) | (external & ~CR)` and an
    unbound `m_port_read` returns 0, so the firmware sees all-zero pins.

    This script enumerates every read of a port DATA register in a disassembled
    image and reports, per port, how many sites there are and which routines they
    are in, so the list can be compared against the driver's port bindings.

COMMAND
    cd ~/compartilhado/disasm-lanes/drvkn5000
    python3 scripts/analysis/port_read_census.py v10/maincpu
    python3 scripts/analysis/port_read_census.py v142 subcpu

WHAT COUNTS AS A PORT READ
    On TLCS-900/H the on-chip SFRs are reached with 8-bit direct addressing.  In
    this tree that is spelled with the `_dd8` family (bit tests and flag loads:
    `bit_dd8 5, 0x1c`, `ldcf_dd8 4, 0x38`) and the `_sd8b` family (byte loads:
    `ld_sd8b A, 0x40`).  ⚠ `ldb_d8` / `stdi8` / `cpdi8` in this tree are the
    SIXTEEN-bit direct forms and address DRAM, NOT the SFRs -- counting them as
    port access is the mistake this script exists to avoid.  ⚠ `lda_dd8l` is load
    effective address: it materialises the CONSTANT, it does not read the port.

    Only the port DATA registers are counted, not the CR/FC configuration
    registers -- writing those is configuration, not input.

NOTE: these sources are latin-1, not UTF-8.  Always decode explicitly.
"""
import os, re, sys, collections

# TMP94C241 port DATA registers (from v142/subcpu/shared/sfr_tmp94c241.s).
PORTS = {0x00: 'P0', 0x04: 'P1', 0x08: 'P2', 0x0c: 'P3', 0x10: 'P4', 0x14: 'P5',
         0x18: 'P6', 0x1c: 'P7', 0x20: 'P8', 0x28: 'PA', 0x2c: 'PB', 0x30: 'PC',
         0x34: 'PD', 0x38: 'PE', 0x3c: 'PF', 0x40: 'PG', 0x44: 'PH', 0x68: 'PZ'}

# Mnemonics that READ an 8-bit-direct SFR operand.  `lda*` is excluded: it loads
# the address, not the contents.
READ_MN = re.compile(r'^(bit_dd8|ldcf_dd8|ld_sd8b|cp_dd8|and_dd8|or_dd8|xor_dd8|'
                     r'tset_dd8|ldb_sd8b|ldw_sd8b)$')
# The same reads in native spelling, which respell_raw_pseudos.py writes (2026-10-03: `bit_dd8 5,
# 0x1c` -> `bit 5, (0x1c:8)`, `ld_sd8b A, 0x40` -> `ld a, (0x40:8)`), and with the address by its
# SFR name once symbolised (`(P7:8)`).  Before this was added the census silently reported 0 sites
# for every native line -- v142's payload had been respelled earlier, so its count was already
# only the boot ROM's 2.  A native line is a read when the port is a SOURCE: the memory operand
# of bit/ldcf/tset/cp, or the second operand of ld/and/or/xor (`and (P7:8), 0xfe` is a
# read-modify-write, which the pseudo census did not count either).
NATIVE_MN = re.compile(r'^(bit|ldcf|tset|cp|cpw|ld|ldw|and|or|xor)$', re.I)
MEMOP = re.compile(r'^\((0x[0-9a-fA-F]+|\d+|[A-Za-z_]\w*)(?::(?:8|16|24))?\)$')
PORT_BY_NAME = {v: k for k, v in PORTS.items()}
LINE = re.compile(r'^\s*(?:[A-Za-z_][A-Za-z0-9_.]*:)?\s*([a-z][a-z0-9_]*)\s+(.*)$')
HEX  = re.compile(r'0x[0-9a-fA-F]+')
LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_.]*):')

def main():
    roots = sys.argv[1:] or ['v10/maincpu']
    hits = collections.defaultdict(list)
    for root in roots:
        for dp, _, ns in os.walk(root):
            for n in sorted(ns):
                if not n.endswith('.s'):
                    continue
                p = os.path.join(dp, n)
                label = '(top of file)'
                for ln, line in enumerate(open(p, encoding='latin-1'), 1):
                    m = LABEL.match(line)
                    if m:
                        label = m.group(1)
                    body = line.split(';', 1)[0]
                    lm = LINE.match(body)
                    if lm and NATIVE_MN.match(lm.group(1)):
                        ops = [o.strip() for o in lm.group(2).split(',')]
                        mn = lm.group(1).lower()
                        src = [1] if mn in ('ld', 'ldw', 'and', 'or', 'xor') else range(len(ops))
                        for i in src:
                            mm = MEMOP.match(ops[i]) if i < len(ops) else None
                            if not mm:
                                continue
                            t = mm.group(1)
                            a = PORT_BY_NAME.get(t) if t[0].isalpha() else int(t, 0)
                            if a in PORTS:
                                bit = None
                                if mn in ('bit', 'ldcf', 'tset') and ops[0].isdigit() and int(ops[0]) <= 7:
                                    bit = int(ops[0])
                                hits[PORTS[a]].append((p, ln, bit, label, line.rstrip()))
                                break
                        continue
                    if not lm or not READ_MN.match(lm.group(1)):
                        continue
                    ops = [o.strip() for o in lm.group(2).split(',')]
                    vals = []
                    for o in ops:
                        try:
                            vals.append(int(o, 16) if o.lower().startswith('0x') else int(o))
                        except ValueError:
                            vals.append(None)
                    # the SFR address is the operand equal to a known port register;
                    # for the bit forms the OTHER numeric operand is the bit number.
                    # the port operand may also be the SFR name: symbolize_v142_sfr_operands.py
                    # turned v142's `bit_dd8 4, 0x34` into `bit_dd8 4, PD`, and the census, which
                    # required `0x`, fell from 20 sites to 2 without a word (found 2026-10-03)
                    for i, o in enumerate(ops):
                        if o in PORT_BY_NAME:
                            vals[i] = PORT_BY_NAME[o]
                            ops[i] = '0x%02x' % vals[i]
                    for i, v in enumerate(vals):
                        if v in PORTS and ops[i].lower().startswith('0x'):
                            bit = next((w for j, w in enumerate(vals)
                                        if j != i and w is not None and 0 <= w <= 7
                                        and not ops[j].lower().startswith('0x')), None)
                            hits[PORTS[v]].append((p, ln, bit, label, line.rstrip()))
                            break
    print(f'# roots: {", ".join(roots)}')
    total = 0
    for port in sorted(hits, key=lambda k: list(PORTS.values()).index(k)):
        sites = hits[port]
        total += len(sites)
        bits = sorted({b for _, _, b, _, _ in sites if b is not None})
        bitstr = ('bits ' + ','.join(str(b) for b in bits)) if bits else 'whole byte'
        print(f'\n{port}  {len(sites)} read site(s)  ({bitstr})')
        for p, ln, b, label, text in sites:
            print(f'   {p}:{ln}  [{label}]  {text.strip()}')
    print(f'\n# total port-data read sites: {total}')
    print('# ports NEVER read: ' + ', '.join(v for v in PORTS.values() if v not in hits))

if __name__ == '__main__':
    main()
