#!/usr/bin/env python3
"""Move my mis-placed .Lc_ labels to the addresses their names encode.

My BUILD FIX placed them by counting .byte payloads from an anchor, which loses
track the moment an INSTRUCTION line intervenes (unknown width). .Lc_fcfdb9
landed 542 bytes late, so llvm-mc relaxed `jr` to `jrl` and the block grew --
11 such length errors, cascading into 132,945 differing bytes.

Correct method: for target address T, find the NAMED symbol S with the largest
ELF address <= T, locate S in the file, then walk forward counting ONLY .byte
payloads, and require that the walk reaches exactly T-S without crossing an
instruction line. If it cannot, the label is left where it is and reported --
better an honest failure than another wrong placement.
"""
import re, glob, os, sys, importlib.util, bisect

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
os.chdir(REPO); sys.path.insert(0, REPO)
c = importlib.util.spec_from_file_location(
    "cc", "scripts/converters/convert_corroborated_blocks.py")
cc = importlib.util.module_from_spec(c); c.loader.exec_module(cc)
sy = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
addrs = sorted(sy)
BYTE = re.compile(r'^\t\.byte\s+(.*)$')

moved = failed = 0
for f in sorted(glob.glob("v7/maincpu/**/*.s", recursive=True)):
    lines = open(f, encoding="latin1").read().split("\n")
    lc = [(i, l[:-1]) for i, l in enumerate(lines)
          if re.match(r'^\.Lc_[0-9a-f]+:$', l)]
    if not lc:
        continue
    plan = []
    for i, name in lc:
        T = int(name.split("_")[1], 16)
        j = bisect.bisect_right(addrs, T) - 1
        if j < 0:
            continue
        S, Sname = addrs[j], sy[addrs[j]]
        want = T - S
        # locate Sname in this file
        try:
            k = next(x for x, l in enumerate(lines) if l == Sname + ":")
        except StopIteration:
            continue
        off = 0; hit = None; ok = True
        for x in range(k + 1, len(lines)):
            l = lines[x]
            if off == want and (BYTE.match(l) or re.match(r'^\w+:$', l)):
                hit = x; break
            m = BYTE.match(l)
            if m:
                vals = re.findall(r'0x[0-9a-fA-F]{2}', m.group(1))
                if off + len(vals) > want:
                    hit = ('split', x, want - off); break
                off += len(vals)
            elif re.match(r'^\w+:$', l) or l.strip() == "" or l.strip().startswith(";"):
                continue
            else:
                ok = False; break      # instruction line -- cannot count past it
        if not ok or hit is None:
            failed += 1
            continue
        plan.append((i, name, hit))
    if not plan:
        continue
    drop = {i for i, _n, _h in plan}
    ins = {}
    for _i, name, hit in plan:
        if isinstance(hit, tuple):
            ins.setdefault(hit[1], []).append((name, hit[2]))
        else:
            ins.setdefault(hit, []).append((name, 0))
    out = []
    for x, l in enumerate(lines):
        if x in drop:
            continue
        if x in ins:
            for name, cut in sorted(ins[x], key=lambda t: t[1]):
                if cut == 0:
                    out.append(name + ":")
                else:
                    m = BYTE.match(l)
                    vals = re.findall(r'0x[0-9a-fA-F]{2}', m.group(1))
                    out.append("\t.byte " + ", ".join(vals[:cut]))
                    out.append(name + ":")
                    l = "\t.byte " + ", ".join(vals[cut:])
            moved += len(ins[x])
        out.append(l)
    open(f, "w", encoding="latin1").write("\n".join(out))
    print(f"  {os.path.basename(f)}: repositioned {len(plan)}")
print(f"moved {moved}, could not place {failed}")
