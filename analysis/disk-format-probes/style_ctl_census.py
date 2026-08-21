#!/usr/bin/env python3
"""Per-chain census of the 0xDn controller statuses in the IC19 style corpus.

QUESTION: is the low nibble of a style-stream 0xDn status a PART/CHANNEL id
(then one chain would use a single nibble) or a CONTROLLER SELECTOR (then one
chain mixes nibbles)?
"""
import pathlib, collections, sys

REPO = pathlib.Path('/home/fsanches/compartilhado/kn5000-roms-disasm')
SECTIONS = ['section_0', 'section_1_2', 'section_3_4', 'section_5_6']
ARGS = {0x90: 5, 0x91: 7, 0xD1: 2, 0xD2: 2, 0xD3: 2, 0xD4: 2, 0xD5: 2, 0xD7: 2,
        0xC0: 5, 0x81: 0, 0x83: 0, 0x84: 0}

def sections(d):
    hks = [i for i in range(0, len(d) - 4, 0x100) if d[i:i+4] == b'H\x00K\x00']
    for k, s in enumerate(hks):
        yield s, (hks[k+1] if k+1 < len(hks) else len(d))

def cells_of(d, start, end):
    return [o for o in range(start, end - 255, 256) if d[o] == 0x80 and d[o+5] == 0x87]

chains = []
for sec in SECTIONS:
    d = (REPO / 'custom_data' / 'includes' / f'{sec}.bin').read_bytes()
    for start, end in sections(d):
        cells = cells_of(d, start, end)
        if not cells: continue
        cs, base = set(cells), cells[0] >> 8
        for o in cells:
            if (d[o+1] | (d[o+2] << 8)) != 0xFFFF:
                continue           # not a chain head
            buf, cur = bytearray(), o
            seen = set()
            while cur is not None and cur not in seen:
                seen.add(cur)
                buf += d[cur+6:cur+0xFF]
                nx = d[cur+3] | (d[cur+4] << 8)
                cur = None if nx == 0xFFFF else ((nx & 0xFFF) + base) * 256
            chains.append((sec, o, bytes(buf)))

tot = collections.Counter(); bad = 0
per_chain = []
valstats = collections.defaultdict(collections.Counter)
argpair  = collections.defaultdict(collections.Counter)
for sec, o, buf in chains:
    i = 0; nib = collections.Counter()
    while i < len(buf):
        s = buf[i]
        if s < 0x80:
            bad += 1; i += 1; continue
        if s == 0x83: tot[0x83] += 1; break
        n = ARGS.get(s)
        if n is None:
            bad += 1; i += 1; continue
        a = buf[i+1:i+1+n]
        if len(a) < n: break
        tot[s] += 1
        if 0xD0 <= s <= 0xDF:
            nib[s & 0xF] += 1
            valstats[s][a[1]] += 1
            argpair[s][(a[0], a[1])] += 1
        i += 1 + n
    per_chain.append((sec, o, nib))

print("event counts:", {hex(k): v for k, v in sorted(tot.items())}, "malformed:", bad)
print("chains:", len(chains))
mix = collections.Counter()
for sec, o, nib in per_chain:
    if nib:
        mix[tuple(sorted(nib))] += 1
print("\nD-nibble SETS per chain (how many chains use exactly this set of nibbles):")
for k, v in sorted(mix.items(), key=lambda x: -x[1]):
    print("   ", k, v)
print("\nchains containing any D event:", sum(mix.values()))
for s in (0xD1, 0xD2, 0xD3):
    vs = valstats[s]
    print(f"\n0x{s:02X}: {sum(vs.values())} events, arg1 distinct={len(vs)}, "
          f"top={vs.most_common(8)}")
