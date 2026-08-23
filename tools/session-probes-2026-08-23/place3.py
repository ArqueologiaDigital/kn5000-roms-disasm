#!/usr/bin/env python3
"""Place three badly-misplaced labels by anchoring on a NEARBY named symbol.

LcX_fe7680, LcX_fe99a2 and LcX_feb9ef sit 2,932 / 4,199 / 5,595 bytes past their
true addresses, which forces llvm-mc to relax `jr` to `jrl` and shifts everything
after them. Walking that far from their current position is hopeless; anchoring
on the named symbol immediately BEFORE the target address is a short walk.
"""
import re, os, sys, importlib.util, glob

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
os.chdir(REPO); sys.path.insert(0, REPO)
c = importlib.util.spec_from_file_location(
    "cc", "scripts/converters/convert_corroborated_blocks.py")
cc = importlib.util.module_from_spec(c); c.loader.exec_module(cc)
sy = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
inv = {n: a for a, n in sy.items()}
BYTE = re.compile(r'^\t\.byte\s+(.*)$')

JOBS = [("LcX_fe7680", "ProcessLayeredNoteOn_WriteReg2", 77),
        ("LcX_fe99a2", "NoteBuffer_CompactEn_Block2", 28),
        ("LcX_feb9ef", "SeqVoice_CheckAndRet_Data_0x101", 73)]

for f in sorted(glob.glob("v7/maincpu/**/*.s", recursive=True)):
    lines = open(f, encoding="latin1").read().split("\n")
    changed = False
    for name, anchor, want in JOBS:
        try:
            src = next(i for i, l in enumerate(lines) if l == name + ":")
            ak = next(i for i, l in enumerate(lines) if l == anchor + ":")
        except StopIteration:
            continue
        off, hit, ok = 0, None, True
        j = ak + 1
        while j < len(lines):
            if off == want:
                hit = (j, 0); break
            m = BYTE.match(lines[j])
            if m:
                vals = re.findall(r'0x[0-9a-fA-F]{2}', m.group(1))
                if off + len(vals) > want:
                    hit = (j, want - off); break
                off += len(vals); j += 1
            elif re.match(r'^[\w.]+:$', lines[j]) or not lines[j].strip() \
                    or lines[j].strip().startswith(";"):
                j += 1
            else:
                ok = False; break
            
        if not ok or hit is None:
            print(f"  {name}: could not reach +{want} from {anchor} -- left alone")
            continue
        jj, k = hit
        m = BYTE.match(lines[jj])
        rep = []
        if m:
            vals = re.findall(r'0x[0-9a-fA-F]{2}', m.group(1))
            if k: rep.append("\t.byte " + ", ".join(vals[:k]))
            rep.append(name + ":")
            if k < len(vals): rep.append("\t.byte " + ", ".join(vals[k:]))
            lines[jj:jj+1] = rep
        else:
            lines.insert(jj, name + ":")
        src = next(i for i, l in enumerate(lines) if l == name + ":" and i != jj + (0 if m else 0))
        # remove the OLD definition (the one further away)
        occ = [i for i, l in enumerate(lines) if l == name + ":"]
        if len(occ) > 1:
            drop = max(occ) if max(occ) > jj else min(occ)
            del lines[drop]
        print(f"  {name}: placed at {anchor}+{want}")
        changed = True
    if changed:
        open(f, "w", encoding="latin1").write("\n".join(lines))
