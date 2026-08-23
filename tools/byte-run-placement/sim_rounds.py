#!/usr/bin/env python3
"""Iterate the proposed rule to a fixpoint on a private COPY of the tree.

Each round: (1) derive an address for EVERY source line by labelling a copy,
assembling and linking it and reading llvm-nm -- the incbin_index() trick
generalised; (2) run convert_reachable_ranges.py --apply with `.byte` runs the
block index cannot address added from that map (ROM-verified); (3) rebuild the
copy the Makefile's way and byte-compare against original_ROMs.

The map must be re-derived every round: converting a range splices lines, so
line numbers move.

  python3 sim_rounds.py [rounds]
"""
import glob, importlib.util, json, os, re, shutil, subprocess, sys, tempfile

ROUNDS = int(sys.argv[1]) if len(sys.argv) > 1 else 3
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.environ.get("KN5000_PROBE_DIR",
                     os.path.join(tempfile.gettempdir(), "kn5000-byte-run-placement"))
os.makedirs(OUT, exist_ok=True)
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
BASE = 0xE00000
SIM = os.path.join(OUT, "sim_rounds")

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
SRC = os.path.join(SIM, "v7", "maincpu")
ROM = open(os.path.join(REPO, "original_ROMs/kn5000_v7_program.rom"), "rb").read()


def line_map():
    """(relpath, line0) -> ROM address, for every line of SRC, from the linker."""
    work = tempfile.mkdtemp(prefix="lnloc_", dir=OUT)
    copy = os.path.join(work, "maincpu")
    shutil.copytree(SRC, copy, symlinks=True)
    tags, n = {}, 0
    for root, _d, files in os.walk(copy):
        for fn in sorted(files):
            if not fn.endswith(".s"):
                continue
            cp = os.path.join(root, fn)
            rel = os.path.relpath(cp, copy)
            lines = open(cp, "rb").read().decode("latin-1").split("\n")
            out, in_macro = [], False
            for i, ln in enumerate(lines):
                s = ln.strip(); low = s.lower()
                if low.startswith(".macro"):
                    in_macro = True
                if in_macro:
                    out.append(ln)
                    if low.startswith(".endm"):
                        in_macro = False
                    continue
                if s and not s.startswith((";", "#")):
                    out.append(f"__ln_{n}:"); tags[n] = (rel, i); n += 1
                out.append(ln)
            open(cp, "wb").write("\n".join(out).encode("latin-1"))
    obj, elf = os.path.join(work, "l.o"), os.path.join(work, "l.elf")
    r = subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900", "-filetype=obj",
                        "-I", copy, "-o", obj, os.path.join(copy, "kn5000_v7_program.s")],
                       capture_output=True, text=True)
    assert r.returncode == 0, r.stderr[:2000]
    r = subprocess.run([os.path.join(LLVM, "ld.lld"), "-e", "0", "-T",
                        os.path.join(SRC, "maincpu.ld"), "-o", elf, obj],
                       capture_output=True, text=True)
    assert r.returncode == 0, r.stderr[:2000]
    lm = {}
    for line in subprocess.run([os.path.join(LLVM, "llvm-nm"), "--no-sort", elf],
                               capture_output=True, text=True).stdout.splitlines():
        p = line.split()
        if len(p) == 3 and p[2].startswith("__ln_"):
            lm.setdefault(tags[int(p[2][5:])], int(p[0], 16))
    shutil.rmtree(work, ignore_errors=True)
    return lm


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


def gate(tag):
    obj, elf, binf = (os.path.join(OUT, f"r{tag}{x}") for x in (".o", ".elf", ".bin"))
    r = subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900", "-filetype=obj",
                        "-I", SRC, "-o", obj, os.path.join(SRC, "kn5000_v7_program.s")],
                       capture_output=True, text=True)
    if r.returncode: return f"llvm-mc FAILED: {r.stderr[:500]}"
    r = subprocess.run([os.path.join(LLVM, "ld.lld"), "-e", "0", "-T",
                        os.path.join(SRC, "maincpu.ld"), "-o", elf, obj],
                       capture_output=True, text=True)
    if r.returncode: return f"ld.lld FAILED: {r.stderr[:500]}"
    subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary", elf, binf], check=True)
    got = open(binf, "rb").read()
    bad = sum(1 for i in range(min(len(got), len(ROM))) if got[i] != ROM[i])
    for f in (obj, elf, binf):
        os.remove(f)
    return f"{bad} incorrect byte(s), length {len(got):,}"


total = 0
for rnd in range(1, ROUNDS + 1):
    print(f"\n{'=' * 70}\nROUND {rnd}")
    LM = line_map()
    print(f"   line map: {len(LM):,} lines located")
    os.chdir(SIM)
    sys.argv = [sys.argv[0], "--apply"]
    spec = importlib.util.spec_from_file_location(
        f"crr{rnd}", os.path.join(REPO, "scripts/converters/convert_reachable_ranges.py"))
    mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
    mod.REPO = SIM                      # ⚠ WITHOUT THIS the converter indexes -- and
    mod.cc.REPO = SIM                   # WRITES -- the REAL tree.  Belt and braces:
    _ro = open                          # any write outside SIM is an error, not a file.

    def guarded_open(path, mode="r", *a, **kw):
        if any(c in mode for c in "wax+"):
            ap = os.path.abspath(str(path))
            if not (ap.startswith(SIM + os.sep) or ap.startswith(OUT + os.sep)
                    or ap.startswith(tempfile.gettempdir() + os.sep)):
                raise AssertionError(f"REFUSING a write outside the sandbox: {ap}")
        return _ro(path, mode, *a, **kw)
    mod.open = guarded_open
    mod.cc.open = guarded_open
    real_index = mod.source_index

    def w_index(syms, _m=mod):
        idx = real_index(syms)
        n = nb = 0
        for f in sorted(glob.glob(os.path.join(SRC, "*/*.s")) + glob.glob(os.path.join(SRC, "*.s"))):
            rel = os.path.relpath(f, SRC)
            lines = open(f, "rb").read().decode("latin-1").split("\n")
            have = idx.get(f)
            blocks = list(have[1]) if have else []
            starts = {bk[2] for bk in blocks}
            for (lb, s, e, vals) in raw_runs(lines):
                if s in starts or any(v is None for v in vals):
                    continue
                a = LM.get((rel, s))
                if a is None: continue
                blob = bytes(v & 0xFF for v in vals)
                if ROM[a - BASE:a - BASE + len(blob)] != blob: continue
                blocks.append((lb, a, s, e, blob)); n += 1; nb += len(blob)
            if blocks:
                blocks.sort(key=lambda bk: bk[2])
                idx[f] = ((have[0] if have else lines), blocks)
        print(f"   [sim] +{n} assembler-addressed run(s), {nb:,} bytes")
        return idx
    mod.source_index = w_index
    import io, contextlib
    cap = io.StringIO()
    with contextlib.redirect_stdout(cap):
        mod.main()
    log = cap.getvalue()
    for ln in log.splitlines():
        if ln.startswith("converted ") or ln.startswith("rewrote ") or "refused" in ln \
           or "bytes behind" in ln or ln.startswith("   [sim]") or "ranges decode" in ln:
            print("  ", ln.strip())
    m = re.search(r'^converted (\d+) range\(s\), ([\d,]+) bytes', log, re.M)
    got = int(m.group(2).replace(",", "")) if m else 0
    total += got
    print(f"   GATE: {gate(rnd)}")
    os.chdir(REPO)
    for d in glob.glob(os.path.join(tempfile.gettempdir(), "kn5000_conv_*")):
        shutil.rmtree(d, ignore_errors=True)
    if got == 0:
        print("   fixpoint")
        break
print(f"\nTOTAL converted across rounds: {total:,} bytes")
