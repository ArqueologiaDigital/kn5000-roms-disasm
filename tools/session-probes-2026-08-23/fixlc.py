#!/usr/bin/env python3
"""Define the .Lc_ labels that are referenced but never emitted.

A converted range was truncated after emitting `jr z, .Lc_XXXXXX` but before
reaching the instruction that carries the label, so the symbol is undefined and
the link fails. The label name encodes the target ADDRESS, so the fix is to emit
it at that address -- byte-neutral, since a label adds no bytes.

Each file's `.byte`/instruction stream is a contiguous ROM image, so the address
of any line can be found by anchoring on a long byte run and counting.
"""
import re, glob, os, sys, struct

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
os.chdir(REPO)
BASE = 0xE00000
rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
BYTE = re.compile(r'^\t\.byte\s+(.*)$')

fixed = 0
for f in sorted(glob.glob("v7/maincpu/**/*.s", recursive=True)):
    lines = open(f, encoding="latin1").read().splitlines()
    refs, defs = set(), set()
    for ln in lines:
        s = ln.strip()
        m = re.match(r'^(\.Lc_[0-9a-f]+):', s)
        if m:
            defs.add(m.group(1))
        for r in re.finditer(r'(\.Lc_[0-9a-f]+)\b', ln):
            if not s.startswith(r.group(1) + ':'):
                refs.add(r.group(1))
    undef = sorted(refs - defs)
    if not undef:
        continue
    # anchor: find a long .byte run and locate it uniquely in the ROM
    anchor_i = anchor_off = None
    for i, ln in enumerate(lines):
        m = BYTE.match(ln)
        if not m:
            continue
        vals = [int(x, 16) for x in re.findall(r'0x([0-9a-fA-F]{2})', m.group(1))]
        if len(vals) < 8:
            continue
        blob = bytes(vals)
        if rom.count(blob) == 1:
            anchor_i, anchor_off = i, rom.find(blob)
            break
    if anchor_i is None:
        print(f"  {os.path.basename(f)}: no unique anchor -- skipped ({len(undef)} undefined)")
        continue
    # walk outward computing each line's byte offset
    pos = {}
    off = anchor_off
    for i in range(anchor_i, len(lines)):
        pos[i] = off
        m = BYTE.match(lines[i])
        if m:
            off += len(re.findall(r'0x[0-9a-fA-F]{2}', m.group(1)))
        elif lines[i].startswith("\t") and not lines[i].strip().startswith("."):
            off += 0   # instruction: unknown width, stop trusting after this
    want = {}
    for u in undef:
        want[int(u.split("_")[1], 16) - BASE] = u
    out, cur, ins = [], None, 0
    off = anchor_off
    for i, ln in enumerate(lines):
        if i >= anchor_i:
            m = BYTE.match(ln)
            if m:
                vals = re.findall(r'0x[0-9a-fA-F]{2}', m.group(1))
                hit = [k for k in range(len(vals)) if (off + k) in want]
                if hit:
                    prev = 0
                    for k in hit:
                        if k > prev:
                            out.append("\t.byte " + ", ".join(vals[prev:k]))
                        out.append(f"{want[off + k]}:")
                        ins += 1
                        prev = k
                    if prev < len(vals):
                        out.append("\t.byte " + ", ".join(vals[prev:]))
                    off += len(vals)
                    continue
                off += len(vals)
        out.append(ln)
    if ins:
        open(f, "w", encoding="latin1").write("\n".join(out) + "\n")
        print(f"  {os.path.basename(f)}: defined {ins}/{len(undef)} missing labels")
        fixed += ins
print(f"total labels defined: {fixed}")
