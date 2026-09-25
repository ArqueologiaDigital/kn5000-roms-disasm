#!/usr/bin/env python3
r"""v142_line_map.py -- which source line of the v1.42 sub-CPU payload emits the byte at address X?

QUESTION THIS ANSWERS
    The v142 sources carry no address comments (policy), so "which line is 0x02412E?" has no
    grep answer.  This builds one: the v142/subcpu tree is mirrored to a temp dir, a marker
    label is inserted before every byte-emitting line of every .s file, the mirror is assembled
    and LINKED with the real subcpu.ld, and the markers' addresses are read back with llvm-nm.

    ★ STALE-MAP GUARD: the mirror's ROM image is asserted byte-identical to
    original_ROMs/kn5000_subprogram_v142.rom before any address is reported (a label emits no
    bytes, so a matching image proves the map is a map of THIS tree).

    Importable: `line_map()` -> {(file, 0-based line index): address}, `addr_to_line()`.

RUN
    python3 scripts/analysis/v142_line_map.py 0x02412E [0x02413A ...]   # file:line of each
"""
import bisect
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TREE = os.path.join(ROOT, "v142/subcpu")
ROM = os.path.join(ROOT, "original_ROMs/kn5000_subprogram_v142.rom")
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
FILES = ["kn5000_subprogram_v142.s", "subcpu_data_tables.s", "subcpu_fp_math.s", "subcpu_vectors.s"]
MARK = "__v142lm_"
DIRECTIVE_EMIT = re.compile(r"^\s*\.(byte|short|word|long|ascii|asciz|string|zero|fill|space|incbin|align)\b")
LABEL = re.compile(r"^\s*[A-Za-z_.$][\w.$@]*:\s*")


def strip_comment(s):
    out, q = [], False
    for ch in s:
        if ch == '"':
            q = not q
        if ch == ";" and not q:
            break
        out.append(ch)
    return "".join(out)


def emits(line):
    c = strip_comment(line)
    while True:
        m = LABEL.match(c)
        if not m:
            break
        c = c[m.end():]
    c = c.strip()
    if not c or c.startswith("//"):
        return False
    if c.startswith("."):
        return bool(DIRECTIVE_EMIT.match(c))
    return True


def line_map():
    d = tempfile.mkdtemp(prefix="v142lm_")
    t = os.path.join(d, "t")
    shutil.copytree(TREE, t)
    info, n = {}, 0
    for f in FILES:
        L = open(os.path.join(t, f), "rb").read().decode("latin-1").split("\n")
        out, in_macro = [], False
        for i, ln in enumerate(L):
            s = strip_comment(ln).strip()
            if s.startswith(".macro"):
                in_macro = True
            if not in_macro and emits(ln):
                out.append("%s%d:" % (MARK, n))
                info[n] = (f, i)
                n += 1
            if s.startswith(".endm"):
                in_macro = False
            out.append(ln)
        open(os.path.join(t, f), "wb").write("\n".join(out).encode("latin-1"))
    o, e, b = (os.path.join(d, x) for x in ("m.o", "m.elf", "m.bin"))
    subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900", "-filetype=obj", "-I", t, "-o", o,
                    os.path.join(t, "kn5000_subprogram_v142.s")], check=True, capture_output=True)
    subprocess.run([os.path.join(LLVM, "ld.lld"), "-T", os.path.join(t, "subcpu.ld"), "-o", e, o],
                   check=True, capture_output=True)
    subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary", e, b], check=True)
    full = open(b, "rb").read()
    if full[:256] + full[60416:] != open(ROM, "rb").read():
        sys.exit("marked mirror is NOT byte-identical to the dump -- map would lie; abort")
    nm = subprocess.run([os.path.join(LLVM, "llvm-nm"), e], check=True, capture_output=True, text=True).stdout
    addr = {}
    for ln in nm.splitlines():
        p = ln.split()
        if len(p) == 3 and p[2].startswith(MARK):
            addr[info[int(p[2][len(MARK):])]] = int(p[0], 16)
    shutil.rmtree(d)
    return addr


def addr_to_line(amap):
    """-> sorted list of (address, file, line index) for bisecting."""
    return sorted((a, f, i) for (f, i), a in amap.items())


def main():
    amap = line_map()
    rows = addr_to_line(amap)
    keys = [r[0] for r in rows]
    for x in sys.argv[1:]:
        a = int(x, 0)
        j = bisect.bisect_right(keys, a) - 1
        ad, f, i = rows[j]
        print("0x%06X  %s:%d%s" % (a, f, i + 1, "" if ad == a else "  (line starts at 0x%06X, +%d)" % (ad, a - ad)))


if __name__ == "__main__":
    main()
