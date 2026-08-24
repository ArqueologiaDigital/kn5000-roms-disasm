#!/usr/bin/env python3
"""MEASURE the proposed rule: address every `.byte` run with the ASSEMBLER.

The refusal bucket "entry is in no indexed .byte block and in no located
.incbin" is, in every case, a `.byte` run that has no label of its own and is
separated from the previous run by INSTRUCTION lines, so neither blocks_of()'s
label rule nor source_index()'s blank/comment cursor can give it an address.

The proposal: locate `.byte` runs the same way incbin_index() locates `.incbin`
directives -- label them in a COPY of the tree, assemble, link with the real
maincpu.ld, read the addresses from llvm-nm, and ROM-verify each one.

This script measures what that yields WITHOUT touching the repo: it runs the
real converter with `source_index()` wrapped to add the assembler-addressed
runs, applied to a private COPY of v7/maincpu, and then rebuilds that copy the
way the Makefile does (llvm-mc | ld.lld -e 0 | objcopy -O binary) and compares
the result with original_ROMs/kn5000_v7_program.rom byte for byte.

  python3 sim_asm_addressed_index.py            # needs line_map.pkl (line_locator.py)
"""
import glob, importlib.util, os, pickle, re, shutil, subprocess, sys

REPO = "/home/fsanches/compartilhado/kn5000-roms-disasm"
OUT = os.path.dirname(os.path.abspath(__file__))
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
BASE = 0xE00000
SIM = os.path.join(OUT, "sim")

# ---- build a shadow repo: symlinks everywhere, a real copy of v7/maincpu
shutil.rmtree(SIM, ignore_errors=True)
os.makedirs(SIM)
for e in os.listdir(REPO):
    if e != "v7":
        os.symlink(os.path.join(REPO, e), os.path.join(SIM, e))
os.makedirs(os.path.join(SIM, "v7"))
for e in os.listdir(os.path.join(REPO, "v7")):
    if e != "maincpu":
        os.symlink(os.path.join(REPO, "v7", e), os.path.join(SIM, "v7", e))
shutil.copytree(os.path.join(REPO, "v7", "maincpu"),
                os.path.join(SIM, "v7", "maincpu"), symlinks=True)

os.chdir(REPO)                      # relative reads (the ELF, the span map) stay real
sys.argv = [sys.argv[0], "--apply"]
spec = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
mod.REPO = SIM                      # every write lands in the copy

recs = pickle.load(open(os.path.join(OUT, "line_map.pkl"), "rb"))
LM = {}
for (a, _tag, rel, ln, _t) in recs:
    LM.setdefault((rel, ln), a)

def raw_runs(lines):
    runs, cur, start, label = [], [], None, None
    for i, ln in enumerate(lines):
        m = re.match(r'^\s*\.byte\s+(.*)$', ln)
        if m:
            if start is None: start = i
            body = re.split(r'[;#]', m.group(1))[0]
            for tok in body.split(","):
                tok = tok.strip()
                if not tok: continue
                try: cur.append(int(tok, 0))
                except ValueError: cur.append(None)
            continue
        if cur:
            runs.append((label, start, i - 1, cur)); cur, start, label = [], None, None
        l2 = re.match(r'^([A-Za-z_][\w]*):', ln)
        if l2: label = l2.group(1)
        elif ln.strip() and not ln.lstrip().startswith((';', '#')): label = None
    if cur: runs.append((label, start, len(lines) - 1, cur))
    return runs

real_index = mod.source_index
ADDED = [0, 0]
def w_index(syms):
    idx = real_index(syms)                       # also sets mod.ROM
    ROM = mod.ROM
    files = sorted(glob.glob(os.path.join(SIM, "v7/maincpu/*/*.s"))
                   + glob.glob(os.path.join(SIM, "v7/maincpu/*.s")))
    for f in files:
        rel = os.path.relpath(f, os.path.join(SIM, "v7/maincpu"))
        lines = open(f, "rb").read().decode("latin-1").split("\n")
        have = idx.get(f)
        blocks = list(have[1]) if have else []
        starts = {bk[2] for bk in blocks}
        for (lb, s, e, vals) in raw_runs(lines):
            if s in starts or any(v is None for v in vals):
                continue
            a = LM.get((rel, s))
            if a is None:
                continue
            blob = bytes(v & 0xFF for v in vals)
            if ROM[a - BASE:a - BASE + len(blob)] != blob:
                continue                          # same ROM check as source_index()
            blocks.append((lb, a, s, e, blob))
            ADDED[0] += 1; ADDED[1] += len(blob)
        if blocks:
            blocks.sort(key=lambda bk: bk[2])
            idx[f] = (have[0] if have else lines, blocks)
    print(f"   [sim] added {ADDED[0]} assembler-addressed run(s), {ADDED[1]:,} bytes "
          f"to the block index")
    return idx
mod.source_index = w_index

mod.main()

# ---- rebuild the copy exactly as the Makefile does, and compare with the ROM
src = os.path.join(SIM, "v7", "maincpu")
obj, elf, binf = (os.path.join(OUT, x) for x in ("sim.o", "sim.elf", "sim.bin"))
r = subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900", "-filetype=obj",
                    "-I", src, "-o", obj, os.path.join(src, "kn5000_v7_program.s")],
                   capture_output=True, text=True)
print("\nllvm-mc:", "ok" if r.returncode == 0 else "FAILED\n" + r.stderr[:3000])
if r.returncode: sys.exit(1)
r = subprocess.run([os.path.join(LLVM, "ld.lld"), "-e", "0", "-T",
                    os.path.join(src, "maincpu.ld"), "-o", elf, obj],
                   capture_output=True, text=True)
print("ld.lld:", "ok" if r.returncode == 0 else "FAILED\n" + r.stderr[:3000])
if r.returncode: sys.exit(1)
subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary", elf, binf], check=True)
want = open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
got = open(binf, "rb").read()
print(f"rebuilt {len(got):,} bytes vs ROM {len(want):,} bytes")
if len(got) != len(want):
    print("LENGTH MISMATCH")
bad = [i for i in range(min(len(got), len(want))) if got[i] != want[i]]
print(f"BYTE GATE: {len(bad)} incorrect byte(s)")
for i in bad[:20]:
    print(f"   0x{BASE + i:06X}: rebuilt {got[i]:02x} != rom {want[i]:02x}")
