#!/usr/bin/env python3
"""Census of demo-song statuses 0x80 / 0x85 / 0x86.

Question answered: where do 0x80, 0x85 and 0x86 occur in the 19 committed demo
songs, on which track, at which beat, and with what arguments?

Run:
  python3 demo_status_census.py \
      /home/fsanches/compartilhado/kn5000-roms-disasm/table_data/includes/demo_presets

Container rules used (see docs): cell c at +0x800+(c-1)*256, payload bytes
[5..255] (251 B), next-cell u16 LE at +3, 0xFFFF = end, 0x82 ends a track,
0x81 = advance one beat, running status for 0x9n note records (5 args each).
"""
import glob, os, sys
from collections import Counter

D = sys.argv[1] if len(sys.argv) > 1 else '.'

def walk(b, start):
    c, seen = start, set()
    while c not in (0xFFFF, 0) and c not in seen:
        seen.add(c); off = 0x800 + (c - 1) * 256
        if off + 256 > len(b): return
        nxt = b[off+3] | (b[off+4] << 8)
        for i in range(5, 256): yield b[off+i]
        c = nxt

def events(b, start):
    ev, cur, args = [], None, []
    for v in walk(b, start):
        if v & 0x80:
            if cur is not None and args: ev.append((cur, args))
            if v in (0x81, 0x82):
                ev.append((v, [])); args = []
                if v == 0x82: return ev
                continue
            cur, args = v, []
        else:
            if cur is None: continue
            args.append(v)
            if (cur & 0xF0) == 0x90 and len(args) == 5:
                ev.append((cur, args)); args = []
    if cur is not None and args: ev.append((cur, args))
    return ev

tot = Counter()
for f in sorted(glob.glob(os.path.join(D, 'demo_preset_??.bin'))):
    b = open(f, 'rb').read(); song = os.path.basename(f)[12:14]
    for t in range(16):
        o = 0xD0 + t*3; flags = b[o]; start = b[o+1] | (b[o+2] << 8)
        if not (flags & 0x80): continue
        ev = events(b, start); beat = 0
        for i, (s, a) in enumerate(ev):
            if s == 0x81: beat += 1
            elif s in (0x80, 0x85, 0x86):
                tot[s] += 1
                extra = f"  BPM={a[1]+128*a[2]}" if s == 0x80 else ""
                print(f"song {song} trk {t:2d} type 0x{b[0x20+t]:02x} "
                      f"ev#{i:5d}/{len(ev)} beat {beat:4d}  {s:02X} {a}{extra}")
print({f"0x{k:02X}": v for k, v in sorted(tot.items())})
