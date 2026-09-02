#!/usr/bin/env python3
"""v7tabletail_line_probe.py -- ground-truth ROM address of every source line of the v7 maincpu
tree, adapted from scripts/analysis/v10dac2_line_probe.py for lane V7TABLETAIL.

WHY: this lane's 32 target regions carry src_line HINTS from a census run made in a scratch
work dir at an earlier point in this session (possibly by a sibling lane, possibly in a
different worktree) -- the lane brief explicitly warns those line numbers may have SHIFTED
because sibling lanes (v7islands, v7regions2, v7verbatim) are editing v7/maincpu concurrently.
The ROM ADDRESS is ground truth (original_ROMs/kn5000_v7_program.rom never changes); the
CURRENT line number holding that address's bytes in THIS worktree does not follow from it
without asking the assembler. This script asks the assembler, exactly the technique
v10dac2_line_probe.py used: label every source line, rebuild, confirm byte-identical, read
back real addresses via llvm-nm.

RUN (from this worktree's root, ~/compartilhado/disasm-lanes/v7tabletail):
    python3 scripts/analysis/v7tabletail_line_probe.py --build
    python3 scripts/analysis/v7tabletail_line_probe.py --lookup 0xF2BBCF 0xF2BEE7

Cache: notes/v7-table-tail-32/line_probe_cache.json (regenerable, not committed).
"""
import argparse, json, os, re, shutil, subprocess, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MAINCPU_DIR = os.path.join(REPO, "v7", "maincpu")
ORIGINAL_ROM = os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom")
ROM_SIZE = 2097152
LLVM_BIN = os.environ.get("LLVM_BIN", os.path.expanduser("~/compartilhado/llvm-project/build/bin"))
CACHE = os.path.join(REPO, "notes", "v7-table-tail-32", "line_probe_cache.json")

MACRO_START = re.compile(r'^\s*\.macro\b', re.IGNORECASE)
MACRO_END = re.compile(r'^\s*\.endm\b', re.IGNORECASE)


def instrument_tree(probe_root):
    index = []
    s_files = []
    for dirpath, _, filenames in os.walk(probe_root):
        for fn in filenames:
            if fn.endswith(".s"):
                s_files.append(os.path.join(dirpath, fn))
    for path in sorted(s_files):
        relpath = os.path.relpath(path, probe_root)
        with open(path, encoding="latin-1") as f:
            lines = f.readlines()
        out = []
        in_macro = False
        for i, line in enumerate(lines, 1):
            if in_macro:
                out.append(line)
                if MACRO_END.match(line):
                    in_macro = False
                continue
            if MACRO_START.match(line):
                out.append(line)
                in_macro = True
                continue
            idx = len(index)
            index.append((relpath, i))
            out.append(f"LPROBE_{idx}:\n")
            out.append(line)
        with open(path, "w", encoding="latin-1") as f:
            f.writelines(out)
    return index


def build():
    llvm_mc = os.path.join(LLVM_BIN, "llvm-mc")
    ld_lld = os.path.join(LLVM_BIN, "ld.lld")
    llvm_objcopy = os.path.join(LLVM_BIN, "llvm-objcopy")
    llvm_nm = os.path.join(LLVM_BIN, "llvm-nm")
    for tool in (llvm_mc, ld_lld, llvm_objcopy, llvm_nm):
        if not os.path.exists(tool):
            sys.exit(f"missing tool: {tool} (set LLVM_BIN)")

    with open(ORIGINAL_ROM, "rb") as f:
        original = f.read()
    if len(original) != ROM_SIZE:
        sys.exit(f"original_ROMs/kn5000_v7_program.rom is {len(original)} B, expected "
                 f"{ROM_SIZE} B -- refusing to compare against a wrong/truncated file.")

    with tempfile.TemporaryDirectory(prefix="v7tabletail_lineprobe_") as tmp:
        probe_dir = os.path.join(tmp, "maincpu")
        shutil.copytree(MAINCPU_DIR, probe_dir)
        index = instrument_tree(probe_dir)
        print(f"instrumented {len(index):,} lines across the v7/maincpu tree", file=sys.stderr)

        obj = os.path.join(tmp, "probe.o")
        elf = os.path.join(tmp, "probe.elf")
        rom = os.path.join(tmp, "probe.rom")

        r = subprocess.run([llvm_mc, "-triple=tlcs900", "-filetype=obj", "-I", probe_dir,
                             "-o", obj, os.path.join(probe_dir, "kn5000_v7_program.s")],
                            capture_output=True, text=True)
        if r.returncode:
            sys.exit(f"llvm-mc failed:\n{r.stderr[:4000]}")
        r = subprocess.run([ld_lld, "-T", os.path.join(probe_dir, "maincpu.ld"),
                             "-o", elf, obj], capture_output=True, text=True)
        if r.returncode:
            sys.exit(f"ld.lld failed:\n{r.stderr[:4000]}")
        subprocess.run([llvm_objcopy, "-O", "binary", elf, rom], check=True)

        with open(rom, "rb") as f:
            built = f.read()
        if len(built) != ROM_SIZE:
            sys.exit(f"probe build produced {len(built)} B, expected {ROM_SIZE} B -- broken.")
        if built != original:
            first_diff = next((i for i in range(ROM_SIZE) if built[i] != original[i]), None)
            sys.exit("PROBE BUILD IS NOT BYTE-IDENTICAL to the original ROM -- the probe labels "
                     f"perturbed the image (first diff at 0x{first_diff:06X}). Aborting without "
                     "writing a cache that would be untrustworthy.")
        print(f"probe build verified byte-identical to original_ROMs/ ({ROM_SIZE:,} B) -- "
              "addresses below are trustworthy.", file=sys.stderr)

        result = subprocess.run([llvm_nm, elf], check=True, capture_output=True, text=True)
        addr_by_idx = {}
        for line in result.stdout.splitlines():
            parts = line.split()
            if len(parts) == 3 and parts[2].startswith("LPROBE_"):
                idx = int(parts[2][len("LPROBE_"):])
                addr_by_idx[idx] = int(parts[0], 16)
        if len(addr_by_idx) != len(index):
            missing = len(index) - len(addr_by_idx)
            print(f"NOTE: {missing:,} of {len(index):,} probe labels produced no symbol -- "
                  "expected, from .s files never reached via .include. "
                  "Proceeding with the resolved subset only.", file=sys.stderr)

    by_addr = {}
    for idx, (relpath, lineno) in enumerate(index):
        addr = addr_by_idx.get(idx)
        if addr is None:
            continue
        by_addr.setdefault(addr, []).append([relpath, lineno])

    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    with open(CACHE, "w") as f:
        json.dump({"rom_size": ROM_SIZE, "num_probes": len(index),
                   "by_addr": {str(k): v for k, v in sorted(by_addr.items())}}, f)
    print(f"wrote {CACHE} ({len(by_addr):,} distinct addresses, {len(index):,} probed lines)",
          file=sys.stderr)


def load_cache():
    if not os.path.exists(CACHE):
        sys.exit(f"{CACHE} does not exist -- run with --build first.")
    with open(CACHE) as f:
        d = json.load(f)
    by_addr = {int(k): v for k, v in d["by_addr"].items()}
    return by_addr


def lookup(by_addr, addr_lo, addr_hi):
    addrs = sorted(a for a in by_addr if addr_lo <= a <= addr_hi)
    out = []
    for a in addrs:
        for relpath, lineno in by_addr[a]:
            out.append((relpath, lineno, a))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--build", action="store_true")
    ap.add_argument("--lookup", nargs=2, metavar=("ADDR_LO", "ADDR_HI"))
    ap.add_argument("--lookup-file", metavar="PATH")
    args = ap.parse_args()

    if args.build:
        build()
        return

    by_addr = load_cache()

    def do_range(lo_s, hi_s):
        lo, hi = int(lo_s, 16), int(hi_s, 16)
        rows = lookup(by_addr, lo, hi)
        print(f"[{lo_s}, {hi_s}) :")
        for relpath, lineno, a in rows:
            marker = " <-- START" if a == lo else (" <-- END (next content)" if a == hi else "")
            print(f"  0x{a:06X}  {relpath}:{lineno}{marker}")

    if args.lookup:
        do_range(*args.lookup)
    elif args.lookup_file:
        with open(args.lookup_file) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                lo_s, hi_s = line.split()[:2]
                do_range(lo_s, hi_s)
    else:
        ap.print_help()


if __name__ == "__main__":
    main()
