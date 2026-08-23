#!/usr/bin/env python3
"""ADDRESS -> (file, line, text) for EVERY line of v7/maincpu, from the assembler.

Same trick as convert_reachable_ranges.incbin_index(), generalised from
`.incbin` directives to EVERY source line: copy the tree, put a unique
`__ln_N:` label above each line that can emit bytes, assemble and link the copy
with the real maincpu.ld, and read the addresses out with llvm-nm.  A line's
extent is [its own address, the next distinct address).

Lines inside a `.macro ... .endm` body are NOT labelled (the label would be
defined once per expansion).

⚠ Read-only with respect to the repo: labels go into a COPY under /tmp.

Writes line_map.pkl next to this script:  {tag: (relpath, lineno0, text, addr)}
"""
import os, pickle, re, shutil, subprocess, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
BASE = 0xE00000
OUT = os.environ.get("KN5000_PROBE_DIR",
                     os.path.join(tempfile.gettempdir(), "kn5000-byte-run-placement"))
os.makedirs(OUT, exist_ok=True)
SRC = os.path.join(REPO, "v7", "maincpu")

work = tempfile.mkdtemp(prefix="lnloc_", dir=OUT)
copy = os.path.join(work, "maincpu")
shutil.copytree(SRC, copy, symlinks=True)

tags = {}
n = 0
for root, _d, files in os.walk(copy):
    for fn in sorted(files):
        if not fn.endswith(".s"):
            continue
        cp = os.path.join(root, fn)
        rel = os.path.relpath(cp, copy)
        lines = open(cp, "rb").read().decode("latin-1").split("\n")
        out, in_macro = [], False
        for i, ln in enumerate(lines):
            s = ln.strip()
            low = s.lower()
            if low.startswith(".macro"):
                in_macro = True
            if in_macro:
                out.append(ln)
                if low.startswith(".endm"):
                    in_macro = False
                continue
            if s and not s.startswith((";", "#")):
                out.append(f"__ln_{n}:")
                tags[n] = (rel, i, ln)
                n += 1
            out.append(ln)
        open(cp, "wb").write("\n".join(out).encode("latin-1"))

print(f"labelled {n} line(s) across the copy")
obj, elf = os.path.join(work, "loc.o"), os.path.join(work, "loc.elf")
r = subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900",
                    "-filetype=obj", "-I", copy, "-o", obj,
                    os.path.join(copy, "kn5000_v7_program.s")],
                   capture_output=True, text=True)
if r.returncode:
    print("llvm-mc FAILED\n", r.stderr[:4000]); sys.exit(1)
r = subprocess.run([os.path.join(LLVM, "ld.lld"), "-T",
                    os.path.join(SRC, "maincpu.ld"), "-o", elf, obj],
                   capture_output=True, text=True)
if r.returncode:
    print("ld.lld FAILED\n", r.stderr[:4000]); sys.exit(1)

addr = {}
for line in subprocess.run([os.path.join(LLVM, "llvm-nm"), "--no-sort", elf],
                           capture_output=True, text=True).stdout.splitlines():
    p = line.split()
    if len(p) == 3 and p[2].startswith("__ln_"):
        addr[int(p[2][5:])] = int(p[0], 16)
print(f"{len(addr)} of {n} labels located by the linker")

rom = open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
recs = [(a, t) + tags[t] for t, a in addr.items()]
recs.sort()
with open(os.path.join(OUT, "line_map.pkl"), "wb") as fh:
    pickle.dump(recs, fh)
print("wrote", os.path.join(OUT, "line_map.pkl"), len(recs), "records")
shutil.rmtree(work, ignore_errors=True)
