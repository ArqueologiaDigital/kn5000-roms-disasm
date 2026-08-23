#!/usr/bin/env python3
"""Instruction-start map for a whole source tree, by flattening it through llvm-mc.

Same walk as scripts/analysis/l1_territory_map.py (which is gated on the
classified total equalling the rebuilt ROM to the byte), but it RECORDS the
byte offset of every instruction start, not just the totals.  Result: for each
target, a set of ROM offsets that the committed sources say are instruction
boundaries, and a per-byte CODE/DATA/PAD map.
"""
import os, pickle, re, subprocess, sys

ROOT = "/home/fsanches/compartilhado/kn5000-roms-disasm"
MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
S = os.environ["SCRATCH"]
TARGETS = {
    "v7":  ("v7/maincpu/kn5000_v7_program.s",  "v7/maincpu"),
    "v9":  ("v9/maincpu/kn5000_v9_program.s",  "v9/maincpu"),
    "v10": ("v10/maincpu/kn5000_v10_program.s", "v10/maincpu"),
}
WIDTH = {"byte": 1, "hword": 2, "word": 4, "dword": 8}
ESCAPE = re.compile(r'\\(?:[0-7]{1,3}|x[0-9a-fA-F]{1,2}|.)')
ENCODING = re.compile(r';\s*encoding:\s*\[([^\]]*)\]')


def ascii_len(op):
    t = 0
    for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', op):
        t += len(ESCAPE.sub("X", m.group(1)))
    return t


def run(name):
    root_s, incdir = TARGETS[name]
    out = subprocess.run([MC, "-triple=tlcs900", "-show-encoding", "-I", incdir, root_s],
                         capture_output=True, text=True, cwd=ROOT)
    if out.returncode:
        sys.exit(out.stderr[:400])
    pos = 0
    starts = set()
    terr = bytearray()          # 2 = CODE, 1 = DATA, 0 = PAD
    unknown = []

    def emit(n, k):
        nonlocal pos
        terr.extend(bytes([k]) * n)
        pos += n

    for line in out.stdout.split("\n"):
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        enc = ENCODING.search(line)
        if enc:
            n = len([b for b in enc.group(1).split(",") if b.strip()])
            starts.add(pos)
            emit(n, 2)
            continue
        if s.endswith(":") or s.startswith(";"):
            continue
        m = re.match(r'\.(\w+)\s*(.*)$', s)
        if not m:
            unknown.append(s); continue
        d, rest = m.group(1), m.group(2).strip()
        if d in WIDTH:
            emit(WIDTH[d] * (len([x for x in rest.split(",") if x.strip()]) or 1), 1)
        elif d in ("ascii", "asciz"):
            emit(ascii_len(rest) + (1 if d == "asciz" else 0), 1)
        elif d in ("zero", "fill", "space"):
            p = [x.strip() for x in rest.split(",")]
            n = int(p[0], 0)
            if d == "fill" and len(p) >= 2:
                n *= int(p[1], 0)
            emit(n, 0)
        elif d == "p2align":
            a = 1 << int(rest.split(",")[0].strip(), 0)
            emit((-pos) % a, 0)
        elif d == "org":
            t = int(rest.split(",")[0].strip(), 0)
            if t > pos:
                emit(t - pos, 0)
        elif d in ("set", "equ", "text", "globl", "global", "type", "size",
                   "section", "file", "ident", "weak", "local", "hidden", "reloc"):
            continue
        else:
            unknown.append(s)
    return starts, bytes(terr), unknown


res = {}
for n in sys.argv[1:] or ["v7", "v9", "v10"]:
    st, tr, unk = run(n)
    rom = open(os.path.join(ROOT, f"original_ROMs/kn5000_{n}_program.rom"), "rb").read()
    print(f"{n}: {len(tr):,} bytes classified (ROM {len(rom):,}) "
          f"{'MATCH' if len(tr)==len(rom) else 'MISMATCH'}; "
          f"{len(st):,} instruction starts; {len(unk)} unclassified")
    res[n] = {"starts": st, "terr": tr}
pickle.dump(res, open(os.path.join(S, "flat.pkl"), "wb"))
