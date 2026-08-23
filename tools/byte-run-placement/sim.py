#!/usr/bin/env python3
"""Run convert_reachable_ranges.py --apply against a private COPY of v7/maincpu,
optionally with `.byte` runs addressed BY THE ASSEMBLER, then rebuild the copy
the way the Makefile does and byte-compare it with the original ROM.

  python3 sim.py base       # control: the converter exactly as committed
  python3 sim.py augment    # + assembler-addressed .byte runs (the proposal)

Needs line_map.pkl from line_locator.py.  Writes <tag>_outcomes.json.
"""
import glob, importlib.util, json, os, pickle, re, shutil, subprocess, sys, tempfile

TAG = sys.argv[1] if len(sys.argv) > 1 else "base"
AUG = TAG == "augment"
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.environ.get("KN5000_PROBE_DIR",
                     os.path.join(tempfile.gettempdir(), "kn5000-byte-run-placement"))
os.makedirs(OUT, exist_ok=True)
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
BASE = 0xE00000
SIM = os.path.join(OUT, "sim_" + TAG)

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

os.chdir(REPO)
sys.argv = [sys.argv[0], "--apply"]
spec = importlib.util.spec_from_file_location(
    "crr", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
mod.REPO = SIM

# ---------- record every range's outcome ----------
OUTCOMES = []
CUR = {"t": None}
real_site_of = mod.site_of
def w_site_of(sites, t):
    CUR["t"] = t
    return real_site_of(sites, t)
mod.site_of = w_site_of
class LogDict(dict):
    def __init__(self): dict.__init__(self); self.log = []
    def __setitem__(self, k, v):
        self.log.append((k, v - self.get(k, 0), CUR["t"]))
        dict.__setitem__(self, k, v)
RB = LogDict(); mod.REFUSED_BYTES = RB
real_rewrite = mod.rewrite
def w_rewrite(idx, t, span, insns, texts, addr2name, bl=None):
    (path, _), = idx.items()
    before = dict(mod.REFUSED)
    res = real_rewrite(idx, t, span, insns, texts, addr2name, bl)
    moved = [k for k, v in mod.REFUSED.items() if v != before.get(k, 0)]
    OUTCOMES.append({"entry": t, "span": span,
                     "file": os.path.relpath(path, os.path.join(SIM, "v7/maincpu")),
                     "bucket": moved[0] if moved else ("APPLIED" if res else "SILENT")})
    return res
mod.rewrite = w_rewrite

if AUG:
    recs = pickle.load(open(os.path.join(OUT, "line_map.pkl"), "rb"))
    LM = {}
    for (a, _g, rel, ln, _t) in recs:
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
    def w_index(syms):
        idx = real_index(syms)
        ROM = mod.ROM
        n = nb = 0
        for f in sorted(glob.glob(os.path.join(SIM, "v7/maincpu/*/*.s"))
                        + glob.glob(os.path.join(SIM, "v7/maincpu/*.s"))):
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
                    continue
                blocks.append((lb, a, s, e, blob)); n += 1; nb += len(blob)
            if blocks:
                blocks.sort(key=lambda bk: bk[2])
                idx[f] = ((have[0] if have else lines), blocks)
        print(f"   [sim] +{n} assembler-addressed run(s), {nb:,} bytes in the index")
        return idx
    mod.source_index = w_index

mod.main()

for (k, d, t) in RB.log:
    if k.startswith("entry is in no indexed"):
        OUTCOMES.append({"entry": t, "span": d, "file": "?", "bucket": "NO BLOCK"})
json.dump(OUTCOMES, open(os.path.join(OUT, TAG + "_outcomes.json"), "w"), indent=1)

src = os.path.join(SIM, "v7", "maincpu")
obj, elf, binf = (os.path.join(OUT, TAG + x) for x in (".o", ".elf", ".bin"))
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
bad = [i for i in range(min(len(got), len(want))) if got[i] != want[i]]
print(f"rebuilt {len(got):,} B; BYTE GATE: {len(bad)} incorrect byte(s)")
for i in bad[:10]:
    print(f"   0x{BASE + i:06X}: {got[i]:02x} != {want[i]:02x}")
