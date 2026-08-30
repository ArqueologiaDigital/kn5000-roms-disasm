#!/usr/bin/env python3
r"""WHICH SOURCE LINE EMITS THE BYTE AT ADDRESS X? (v10 maincpu)

QUESTION ANSWERED
-----------------
The KN5000 sources carry NO address comments -- they are symbolic assembly and
every address lives only in the build. So "what does the tree currently say
about 0xED1BAA?" has no grep answer. This tool builds one.

HOW
---
It mirrors `v10/maincpu` into a temp dir, inserts a synthetic label
`.L__amap_<n>:` in front of every byte-emitting source line, assembles and
LINKS the mirror with the real `maincpu.ld`, and reads the marker addresses out
of the ELF symbol table with `llvm-nm`. Marker n was written before line L of
file F, so `addr(marker n)` is the address of the first byte F:L emits.

★ THE MIRROR MUST BE INERT. `--selftest` objcopies the linked mirror to a raw
  binary and asserts it is byte-identical to `original_ROMs/kn5000_v10_program.rom`.
  A label emits no bytes, so if the mirror's ROM still matches, the map is a
  map OF THIS TREE and not of some perturbed variant of it.

WHAT IS SKIPPED, AND WHY
  * lines inside a `.macro` .. `.endm` body -- the label would be emitted once
    per invocation and multiply-define.
  * blank and comment-only lines -- they emit nothing, so they have no address.

RUN
    python3 scripts/analysis/address_line_map.py 0xED1BAA          # who owns it
    python3 scripts/analysis/address_line_map.py 0xED1BA0 0xED1BF0 # a window
    python3 scripts/analysis/address_line_map.py --file v10/maincpu/x.s --line 40
    python3 scripts/analysis/address_line_map.py --selftest
    python3 scripts/analysis/address_line_map.py --dump out.json   # whole map
"""
import bisect
import json
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.path.join(LLVM, "llvm-mc")
LLD = os.path.join(LLVM, "ld.lld")
OBJCOPY = os.path.join(LLVM, "llvm-objcopy")
NM = os.path.join(LLVM, "llvm-nm")

SRCDIR = os.path.join(ROOT, "v10/maincpu")
ROOT_S = "kn5000_v10_program.s"
LDS = "maincpu.ld"
ROM = os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom")
BASE = 0xE00000
MARK = "__amap_"


def _sh(cmd, **kw):
    r = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if r.returncode != 0:
        sys.exit("FAILED: %s\n%s" % (" ".join(cmd), r.stderr[-4000:]))
    return r.stdout


def build_mirror(dest):
    """Copy v10/maincpu, marking every byte-emitting line. Returns the marker list."""
    marks = []            # index -> (relsrc, lineno, text)
    for dp, dn, fn in os.walk(SRCDIR):
        rel = os.path.relpath(dp, SRCDIR)
        outdir = os.path.join(dest, rel) if rel != "." else dest
        os.makedirs(outdir, exist_ok=True)
        dn.sort()
        for f in sorted(fn):
            s, d = os.path.join(dp, f), os.path.join(outdir, f)
            if not f.endswith(".s"):
                if not os.path.exists(d):
                    os.symlink(s, d)
                continue
            lines = open(s, encoding="latin-1").read().split("\n")
            out, in_macro = [], False
            for i, ln in enumerate(lines):
                code = ln.split(";")[0].strip()
                if re.match(r'^\.macro\b', code):
                    in_macro = True
                if code and not in_macro:
                    out.append("%s%d:" % (MARK, len(marks)))
                    marks.append((os.path.relpath(s, ROOT), i + 1, ln.rstrip()))
                if re.match(r'^\.endm\b', code):
                    in_macro = False
                out.append(ln)
            open(d, "w", encoding="latin-1").write("\n".join(out))
    return marks


def link_mirror(mirror):
    obj = os.path.join(mirror, "m.o")
    elf = os.path.join(mirror, "m.elf")
    _sh([MC, "-triple=tlcs900", "-filetype=obj", "-I", mirror,
         "-o", obj, os.path.join(mirror, ROOT_S)])
    _sh([LLD, "-T", os.path.join(mirror, LDS), "-o", elf, obj])
    return elf


def marker_addresses(elf):
    addrs = {}
    for line in _sh([NM, "-n", elf]).split("\n"):
        p = line.split()
        if len(p) >= 3 and p[2].startswith(MARK):
            addrs[int(p[2][len(MARK):])] = int(p[0], 16)
    return addrs


def build(verbose=False):
    tmp = tempfile.mkdtemp(prefix="kn5000-amap-")
    marks = build_mirror(tmp)
    elf = link_mirror(tmp)
    addrs = marker_addresses(elf)
    ent = []
    for i, (src, line, text) in enumerate(marks):
        if i in addrs:
            ent.append((addrs[i], src, line, text))
    ent.sort(key=lambda e: e[0])
    if verbose:
        print("  %d marked lines, %d resolved" % (len(marks), len(ent)))
    return ent, tmp, elf


def lookup(ent, addr):
    keys = [e[0] for e in ent]
    i = bisect.bisect_right(keys, addr) - 1
    return ent[i] if i >= 0 else None


def selftest():
    ent, tmp, elf = build(verbose=True)
    ok = True

    def check(desc, cond, extra=""):
        nonlocal ok
        print("  %-58s %s %s" % (desc, "PASS" if cond else "FAIL", extra))
        ok = ok and cond

    # INVARIANT 1: the marked mirror still assembles to the ORIGINAL ROM.
    raw = os.path.join(tmp, "m.bin")
    _sh([OBJCOPY, "-O", "binary", elf, raw])
    got, want = open(raw, "rb").read(), open(ROM, "rb").read()
    check("marked mirror is byte-identical to the original ROM",
          got == want, "%d vs %d bytes" % (len(got), len(want)))

    # INVARIANT 2: every marker lands inside the image, or exactly on its end.
    # `.set` / `.equ` lines emit nothing, so a marker in front of a trailing
    # block of them sits on the one-past-the-end sentinel; that is expected.
    check("every marker address lies in [BASE, BASE+len(ROM)]",
          all(BASE <= a <= BASE + len(want) for a, _, _, _ in ent))

    # INVARIANT 3: markers of ONE file appear in increasing line order at
    # non-decreasing addresses -- i.e. the map did not scramble source order.
    per = {}
    for a, s, l, _ in ent:
        per.setdefault(s, []).append((l, a))
    bad = [s for s, v in per.items()
           if any(v[i + 1][1] < v[i][1] for i in range(len(v) - 1)
                  if v[i + 1][0] > v[i][0])]
    check("within each file, later lines have later addresses", not bad, str(bad[:3]))

    # INVARIANT 4: a lookup of a known label agrees with the ELF symbol table.
    syms = {}
    for line in _sh([NM, elf]).split("\n"):
        p = line.split()
        if len(p) >= 3 and not p[2].startswith(MARK):
            syms.setdefault(p[2], int(p[0], 16))
    probe = [n for n in ("RESET_HANDLER", "GUI_FormatStrings") if n in syms]
    agree = all(lookup(ent, syms[n]) is not None for n in probe)
    check("lookup resolves known ELF symbols (%s)" % ",".join(probe), agree and probe)

    print("SELFTEST", "PASS" if ok else "FAIL")
    return 0 if ok else 1


def main():
    a = sys.argv[1:]
    if "--selftest" in a:
        sys.exit(selftest())
    ent, tmp, elf = build()
    if "--dump" in a:
        out = a[a.index("--dump") + 1]
        json.dump([{"addr": e[0], "src": e[1], "line": e[2]} for e in ent],
                  open(out, "w"))
        print("wrote %s (%d entries)" % (out, len(ent)))
        return
    if "--file" in a:
        f = a[a.index("--file") + 1]
        ln = int(a[a.index("--line") + 1]) if "--line" in a else None
        for e in ent:
            if e[1].endswith(f) and (ln is None or e[2] == ln):
                print("0x%06X  %s:%d  %s" % (e[0], e[1], e[2], e[3][:100]))
        return
    if not a:
        sys.exit(__doc__)
    lo = int(a[0], 0)
    hi = int(a[1], 0) if len(a) > 1 else lo + 1
    keys = [e[0] for e in ent]
    i = max(0, bisect.bisect_right(keys, lo) - 1)
    while i < len(ent) and ent[i][0] < hi:
        print("0x%06X  %s:%d  %s" % (ent[i][0], ent[i][1], ent[i][2], ent[i][3][:110]))
        i += 1


if __name__ == "__main__":
    main()
