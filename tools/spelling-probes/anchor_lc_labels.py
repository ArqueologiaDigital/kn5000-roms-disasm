#!/usr/bin/env python3
"""Place a mis-placed LcX_ label by anchoring on the NEAREST CORRECT label.

The earlier attempts anchored on named ELF symbols only. For these three the
nearest correct anchor is another LcX_ label a few dozen bytes away -- e.g.
LcX_fe7680 is only 0x2C past LcX_fe7654, which is already correct. A short walk
succeeds where a 2,932-byte one cannot.
"""
import re, os, sys, glob, importlib.util, subprocess, tempfile, functools

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
os.chdir(REPO); sys.path.insert(0, REPO)
c = importlib.util.spec_from_file_location(
    "cc", "scripts/converters/convert_corroborated_blocks.py")
cc = importlib.util.module_from_spec(c); c.loader.exec_module(cc)
sy = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
cur = {n: a for a, n in sy.items() if n.startswith("LcX_")}
good = {n: a for n, a in cur.items() if a == int(n[4:], 16)}
bad = {n: a for n, a in cur.items() if a != int(n[4:], 16)}
BYTE = re.compile(r'^\t\.byte\s+(.*)$')
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
OBJC = LLVM.replace("llvm-mc", "llvm-objcopy")


@functools.lru_cache(maxsize=None)
def width(text):
    src = text
    if re.search(r'\b(jr|jrl|calr|djnz)\b', text):
        src = "_t:\n" + re.sub(r'([A-Za-z_.][\w.]*)\s*$', '_t', text)
    with tempfile.NamedTemporaryFile('w', suffix='.s', delete=False) as fh:
        fh.write(src + "\n"); p = fh.name
    try:
        if subprocess.run([LLVM, "-triple=tlcs900", "-filetype=obj", "-o", p + ".o", p],
                          capture_output=True).returncode:
            return None
        if subprocess.run([OBJC, "-O", "binary", "-j", ".text", p + ".o", p + ".bin"],
                          capture_output=True).returncode:
            return None
        return os.path.getsize(p + ".bin")
    finally:
        for e in ("", ".o", ".bin"):
            try: os.unlink(p + e)
            except OSError: pass


placed = 0
for f in sorted(glob.glob("v7/maincpu/**/*.s", recursive=True)):
    lines = open(f, encoding="latin1").read().split("\n")
    pos = {l[:-1]: i for i, l in enumerate(lines) if re.match(r'^[\w.]+:$', l)}
    for name, at in sorted(bad.items(), key=lambda kv: -abs(kv[1] - int(kv[0][4:], 16))):
        if name not in pos:
            continue
        T = int(name[4:], 16)
        cands = sorted(((T - a, n) for n, a in good.items()
                        if n in pos and 0 < T - a <= 8192), key=lambda t: t[0])
        done = False
        for dist, anch in cands:
            k = pos[anch]; off = 0; hit = None
            j = k + 1
            while j < len(lines) and off <= dist:
                if off == dist:
                    hit = (j, 0); break
                m = BYTE.match(lines[j])
                if m:
                    vals = re.findall(r'0x[0-9a-fA-F]{2}', m.group(1))
                    if off + len(vals) > dist:
                        hit = (j, dist - off); break
                    off += len(vals); j += 1
                elif re.match(r'^[\w.]+:$', lines[j]) or not lines[j].strip() \
                        or lines[j].strip().startswith(";"):
                    j += 1
                else:
                    w = width(lines[j])
                    if w is None or off + w > dist:
                        break
                    off += w; j += 1
            if hit is None:
                continue
            jj, cut = hit
            old = pos[name]
            m = BYTE.match(lines[jj])
            rep = []
            if m:
                vals = re.findall(r'0x[0-9a-fA-F]{2}', m.group(1))
                if cut: rep.append("\t.byte " + ", ".join(vals[:cut]))
                rep.append(name + ":")
                if cut < len(vals): rep.append("\t.byte " + ", ".join(vals[cut:]))
                lines[jj:jj+1] = rep
            else:
                lines.insert(jj, name + ":")
            occ = [i for i, l in enumerate(lines) if l == name + ":"]
            if len(occ) > 1:
                del lines[occ[-1] if occ[-1] != jj else occ[0]]
            print(f"  {name}: placed at {anch}+{dist}")
            placed += 1; done = True
            pos = {l[:-1]: i for i, l in enumerate(lines) if re.match(r'^[\w.]+:$', l)}
            break
        if done:
            open(f, "w", encoding="latin1").write("\n".join(lines))
            lines = open(f, encoding="latin1").read().split("\n")
            pos = {l[:-1]: i for i, l in enumerate(lines) if re.match(r'^[\w.]+:$', l)}
print(f"placed {placed}")
