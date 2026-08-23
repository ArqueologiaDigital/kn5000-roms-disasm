#!/usr/bin/env python3
"""Move each mis-placed LcX_ label by its measured delta.

The labels were renamed .Lc_ -> LcX_ so they reach the symbol table; the ELF then
gives each one's ACTUAL address, and its name gives the intended one. The delta
is exact -- no counting from anchors, no guessing.

Moving a label `d` bytes EARLIER means walking back over `d` bytes of `.byte`
payload. A label is moved only when the whole path is `.byte` lines; if an
instruction line intervenes its width is unknown from the text and the label is
left alone and reported. That refusal is the reason the previous attempt placed
one label 542 bytes late.
"""
import re, glob, os, sys, importlib.util

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
os.chdir(REPO); sys.path.insert(0, REPO)
c = importlib.util.spec_from_file_location(
    "cc", "scripts/converters/convert_corroborated_blocks.py")
cc = importlib.util.module_from_spec(c); c.loader.exec_module(cc)
sy = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
cur = {n: a for a, n in sy.items() if n.startswith("LcX_")}
BYTE = re.compile(r'^\t\.byte\s+(.*)$')

import subprocess, tempfile, functools
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")


@functools.lru_cache(maxsize=None)
def insn_width(text):
    """Width of one instruction line, from the assembler.

    The previous walker gave up at any instruction because its width is not in
    the text. That refusal is why 42 labels stayed mis-placed. A symbolic branch
    is assembled against a local dummy target so it still encodes.
    """
    src = text
    if re.search(r'\b(jr|jrl|calr|djnz)\b', text) and re.search(r'[A-Za-z_.][\w.]*\s*$', text):
        src = "_t:\n" + re.sub(r'([A-Za-z_.][\w.]*)\s*$', '_t', text)
    with tempfile.NamedTemporaryFile('w', suffix='.s', delete=False) as fh:
        fh.write(src + "\n"); path = fh.name
    try:
        r = subprocess.run([LLVM, "-triple=tlcs900", "-filetype=obj", "-o", path + ".o", path],
                           capture_output=True, text=True)
        if r.returncode:
            return None
        r2 = subprocess.run([LLVM.replace("llvm-mc", "llvm-objcopy"),
                             "-O", "binary", "-j", ".text", path + ".o", path + ".bin"],
                            capture_output=True, text=True)
        if r2.returncode:
            return None
        return os.path.getsize(path + ".bin")
    finally:
        for e in ("", ".o", ".bin"):
            try: os.unlink(path + e)
            except OSError: pass

moved = refused = 0
for f in sorted(glob.glob("v7/maincpu/**/*.s", recursive=True)):
    lines = open(f, encoding="latin1").read().split("\n")
    todo = []
    for i, l in enumerate(lines):
        m = re.match(r'^(LcX_[0-9a-f]+):$', l)
        if not m:
            continue
        n = m.group(1)
        if n not in cur:
            continue
        d = cur[n] - int(n[4:], 16)      # >0 => label is LATE, move it back d bytes
        if d:
            todo.append((i, n, d))
    if not todo:
        continue
    out = list(lines)
    for i, n, d in sorted(todo, reverse=True):
        if d > 0:                         # walk BACKWARD over d bytes of .byte
            need, j, cut = d, i - 1, None
            while j >= 0 and need > 0:
                m = BYTE.match(out[j])
                if m:
                    vals = re.findall(r'0x[0-9a-fA-F]{2}', m.group(1))
                    if len(vals) >= need:
                        cut = (j, len(vals) - need); need = 0; break
                    need -= len(vals); j -= 1
                elif re.match(r'^\w+:$', out[j]) or not out[j].strip() \
                        or out[j].strip().startswith(";"):
                    j -= 1
                else:
                    w = insn_width(out[j])
                    if w is None:
                        break             # genuinely cannot size it
                    if w > need:
                        break             # label would land mid-instruction
                    need -= w; j -= 1
            if need or cut is None:
                refused += 1; continue
            jj, k = cut
            m = BYTE.match(out[jj]); vals = re.findall(r'0x[0-9a-fA-F]{2}', m.group(1))
            rep = []
            if k: rep.append("\t.byte " + ", ".join(vals[:k]))
            rep.append(n + ":")
            if k < len(vals): rep.append("\t.byte " + ", ".join(vals[k:]))
            del out[i]
            out[jj:jj+1] = rep
            moved += 1
        else:
            refused += 1
    open(f, "w", encoding="latin1").write("\n".join(out))
print(f"moved {moved}, refused {refused}")
