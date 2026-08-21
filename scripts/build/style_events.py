#!/usr/bin/env python3
"""style_events.py -- IC19 accompaniment style data <-> readable event listings, ROUND TRIP.

QUESTION ANSWERED: can the KN5000's custom accompaniment styles be read as music instead of as
four opaque 160KB blobs, and still rebuild the ROM byte for byte?

The format is documented in docs/accompaniment-style-format.md and proved by
scripts/analysis/style_cell_chains.py. In short: 256-byte cells in doubly-linked chains, a
249-byte event payload each, and a self-delimiting event grammar.

    status         args  meaning
    0x81 BEAT         0  advance one beat
    0x83 END          -  end of the chain's stream
    0x90 NOTE         5  pos, note, velocity, dur_ticks, dur_beats   (96 ticks per beat)
    0x91 NOTE2        7  the same five, plus two trailing bytes (range 0..25)
    0xD1 CTL1         2  pos, value
    0xD2 CTL2         2  pos, value  -- value clusters 61..64
    0xD3 CTL3         2  pos, value  -- value is 0 or 127 only, i.e. a switch

Events are emitted per CHAIN, because an event may straddle a cell boundary; the listing records
which cells a chain occupies so `build` can re-split the rendered bytes at 249-byte boundaries
and put them back. Bytes after 0x83 are preserved verbatim as PAD -- they are not always zero.

    python3 scripts/build/style_events.py export   # blobs -> .styles listings (run once)
    python3 scripts/build/style_events.py build    # listings -> blobs (build step)
    python3 scripts/build/style_events.py verify   # assert the round trip is byte-exact

⚠ WHAT THIS DOES NOT CLAIM. NOTE2's two trailing bytes and the three controller values are
NAMED, not understood: the argument counts are confirmed across all 50,245 events but nobody has
established what they select. They are emitted as numbers, never as invented labels.
"""
import pathlib
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
INC = REPO / 'custom_data' / 'includes'
OUT = REPO / 'custom_data' / 'styles'
# blob -> (offset into original_ROMs/kn5000_custom_data.ic19, length). The chip is the 1 MB
# at ROM 0x300000, so the offset is the section's ROM address minus 0x300000.
SECTIONS = {'section_0':    (0x00000, 0x17000),
            'section_1_2':  (0x19000, 0x2E000),
            'section_3_4':  (0x49000, 0x2E000),
            'section_5_6':  (0x79000, 0x2E000)}
ROM = REPO / 'original_ROMs' / 'kn5000_custom_data.ic19'
PAYLOAD = 249
ARGS = {0x90: 5, 0x91: 7, 0x81: 0, 0xD1: 2, 0xD2: 2, 0xD3: 2}
NAME = {0x90: 'NOTE', 0x91: 'NOTE2', 0x81: 'BEAT', 0x83: 'END',
        0xD1: 'CTL1', 0xD2: 'CTL2', 0xD3: 'CTL3'}
CODE = {v: k for k, v in NAME.items()}


def hk_sections(d):
    hks = [i for i in range(0, len(d) - 4, 0x100) if d[i:i + 4] == b'H\x00K\x00']
    for k, s in enumerate(hks):
        yield s, (hks[k + 1] if k + 1 < len(hks) else len(d))


def cells_of(d, s, e):
    return [o for o in range(s, e - 255, 256) if d[o] == 0x80 and d[o + 5] == 0x87]


def chains_of(d, cells, base):
    cs = set(cells)
    out = []
    for h in [o for o in cells if (d[o + 1] | (d[o + 2] << 8)) == 0xFFFF]:
        seq, o, seen = [], h, set()
        while o is not None and o not in seen:
            seen.add(o)
            seq.append(o)
            nx = d[o + 3] | (d[o + 4] << 8)
            o = ((nx & 0xFFF) + base) * 256 if nx != 0xFFFF else None
            if o is not None and o not in cs:
                break
        out.append(seq)
    return out


def export():
    OUT.mkdir(parents=True, exist_ok=True)
    for sec in SECTIONS:
        d = (INC / f'{sec}.bin').read_bytes()
        lines = [f'# {sec}: {len(d)} bytes, {len(d) // 256} blocks of 256',
                 '# Produced by scripts/build/style_events.py -- see',
                 '# docs/accompaniment-style-format.md for the format.', '']
        cellset = {}
        for s, e in hk_sections(d):
            cells = cells_of(d, s, e)
            if not cells:
                continue
            base = cells[0] >> 8
            for seq in chains_of(d, cells, base):
                for n, o in enumerate(seq):
                    cellset[o] = (seq[0], n)
        # every block, in address order
        for off in range(0, len(d), 256):
            blk = off >> 8
            b = d[off:off + 256]
            if off in cellset:
                head, n = cellset[off]
                lines.append(f'CELL {blk:03X} hdr={b[:6].hex()} tail={b[255]:02X} '
                             f'chain={head >> 8:03X} seq={n}')
            else:
                lines.append(f'RAW {blk:03X}')
                for i in range(0, 256, 32):
                    lines.append('  ' + b[i:i + 32].hex())
        lines.append('')
        # one event listing per chain
        for s, e in hk_sections(d):
            cells = cells_of(d, s, e)
            if not cells:
                continue
            base = cells[0] >> 8
            for seq in chains_of(d, cells, base):
                pay = b''.join(d[o + 6:o + 255] for o in seq)
                lines.append(f'CHAIN {seq[0] >> 8:03X} cells={len(seq)}')
                i = 0
                while i < len(pay):
                    st = pay[i]
                    if st == 0x83:
                        lines.append('  END')
                        i += 1
                        break
                    n = ARGS[st]
                    a = list(pay[i + 1:i + 1 + n])
                    lines.append(f'  {NAME[st]}' + (' ' + ' '.join(str(x) for x in a) if a else ''))
                    i += 1 + n
                if i < len(pay):
                    rest = pay[i:]
                    for k in range(0, len(rest), 32):
                        lines.append('  PAD ' + rest[k:k + 32].hex())
                lines.append('')
        (OUT / f'{sec}.styles').write_text('\n'.join(lines) + '\n')
        print(f"  wrote {sec}.styles")


def rebuild(sec):
    txt = (OUT / f'{sec}.styles').read_text().splitlines()
    nblocks = int([l for l in txt if l.startswith('#') and 'blocks of 256' in l][0].split()[2]) // 256
    out = bytearray(b'\x00' * (nblocks * 256))
    cellinfo = {}
    chains = {}
    i = 0
    while i < len(txt):
        l = txt[i]
        if l.startswith('RAW '):
            blk = int(l.split()[1], 16)
            data = bytes.fromhex(''.join(txt[i + 1 + k].strip() for k in range(8)))
            out[blk * 256:blk * 256 + 256] = data
            i += 9
            continue
        if l.startswith('CELL '):
            p = l.split()
            blk = int(p[1], 16)
            hdr = bytes.fromhex(p[2].split('=')[1])
            tail = int(p[3].split('=')[1], 16)
            head = int(p[4].split('=')[1], 16)
            seq = int(p[5].split('=')[1])
            cellinfo[blk] = (hdr, tail, head, seq)
            i += 1
            continue
        if l.startswith('CHAIN '):
            head = int(l.split()[1], 16)
            body = bytearray()
            i += 1
            while i < len(txt) and txt[i].startswith('  '):
                t = txt[i].strip()
                if t.startswith('PAD '):
                    body += bytes.fromhex(t[4:])
                elif t == 'END':
                    body.append(0x83)
                else:
                    parts = t.split()
                    body.append(CODE[parts[0]])
                    body += bytes(int(x) for x in parts[1:])
                i += 1
            chains[head] = bytes(body)
            continue
        i += 1
    # place each chain's bytes into its cells
    bychain = {}
    for blk, (hdr, tail, head, seq) in cellinfo.items():
        bychain.setdefault(head, []).append((seq, blk))
    for head, members in bychain.items():
        members.sort()
        body = chains[head]
        assert len(body) == len(members) * PAYLOAD, \
            f'{sec} chain {head:03X}: {len(body)} B for {len(members)} cells'
        for seq, blk in members:
            hdr, tail, _, _ = cellinfo[blk]
            o = blk * 256
            out[o:o + 6] = hdr
            out[o + 6:o + 6 + PAYLOAD] = body[seq * PAYLOAD:(seq + 1) * PAYLOAD]
            out[o + 255] = tail
    return bytes(out)


def build():
    tot = 0
    for sec in SECTIONS:
        d = rebuild(sec)
        (INC / f'{sec}.bin').write_bytes(d)
        tot += len(d)
    print(f"style_events: rebuilt {len(SECTIONS)} style banks, {tot:,} B from event listings")


def verify():
    """Compare against the ORIGINAL ROM, not the .bin -- the .bin is a build product now."""
    rom = ROM.read_bytes()
    bad = 0
    for sec, (off, ln) in SECTIONS.items():
        want = rom[off:off + ln]
        got = rebuild(sec)
        if got == want:
            print(f"  ok  {sec:<14} {len(want):>8,} B")
        else:
            bad += 1
            n = sum(1 for a, b in zip(got, want) if a != b) if len(got) == len(want) else -1
            print(f"  *** {sec}: MISMATCH ({n} bytes)" if n >= 0 else f"  *** {sec}: LENGTH")
    if bad:
        sys.exit(f"{bad} bank(s) do not round-trip")
    print("ROUND TRIP EXACT: the event listings rebuild all four style banks")


if __name__ == '__main__':
    {'export': export, 'build': build, 'verify': verify}[sys.argv[1] if len(sys.argv) > 1 else 'verify']()
