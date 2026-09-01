#!/usr/bin/env python3
"""get_lprobe_addrs.py -- ground-truth ROM address of every line of hdae5000_data_tables.s

QUESTION ANSWERED: what is the real, linked ROM address of line N of hdae5000_data_tables.s?

WHY: several bare `.byte` debt bytes only make sense once you know their exact address (is a
lone `.byte 0x00` at an ODD or EVEN offset? does a `.set` offset documented in
hdae5000_init_data.s really land on the string it claims to?). Computing that by hand-parsing
`.asciz`/`.ascii` escape sequences and `.fill`/`.zero` counts is exactly the kind of thing a
one-off script gets subtly wrong (backslash escapes, extended-ASCII bytes hiding inside quoted
strings, etc). Instead this tool asks the PINNED ASSEMBLER ITSELF: it clones hdae5000/, inserts a
unique label before every source line of hdae5000_data_tables.s, rebuilds the full ROM image with
those labels in place, confirms the build is STILL byte-identical to the original dump (i.e. the
probe labels changed nothing), and then reads every probe label's linked address back out of the
ELF symbol table. No address in the output is a guess; every one came out of llvm-mc + ld.lld.

RUN (from the hdae5000 lane worktree root):
    python3 hdae5000/tools/get_lprobe_addrs.py > /tmp/lprobe.txt
    wc -l /tmp/lprobe.txt        # one line per source line of hdae5000_data_tables.s

Output format (one line per probe, same as `llvm-nm`):
    <8-hex-digit-address> t Lprobe_<source-line-number>

Requires the same LLVM build the rest of this tree is pinned to (see TOOLCHAIN_VERSION at the
worktree root); reads LLVM_BIN from the environment if set, else assumes
~/compartilhado/llvm-project/build/bin.
"""
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HDAE_DIR = os.path.join(ROOT, "hdae5000")
ORIGINAL_ROM = os.path.join(ROOT, "original_ROMs", "hd-ae5000_v2_06i.ic4")
LLVM_BIN = os.environ.get("LLVM_BIN", os.path.expanduser("~/compartilhado/llvm-project/build/bin"))
TARGET_FILE = "hdae5000_data_tables.s"


def instrument(path):
    with open(path, encoding="latin-1") as f:
        lines = f.readlines()
    out = []
    for i, line in enumerate(lines, 1):
        out.append(f"Lprobe_{i}:\n")
        out.append(line)
    with open(path, "w", encoding="latin-1") as f:
        f.writelines(out)
    return len(lines)


def main():
    llvm_mc = os.path.join(LLVM_BIN, "llvm-mc")
    ld_lld = os.path.join(LLVM_BIN, "ld.lld")
    llvm_objcopy = os.path.join(LLVM_BIN, "llvm-objcopy")
    llvm_nm = os.path.join(LLVM_BIN, "llvm-nm")
    for tool in (llvm_mc, ld_lld, llvm_objcopy, llvm_nm):
        if not os.path.exists(tool):
            sys.exit(f"missing tool: {tool} (set LLVM_BIN)")

    with tempfile.TemporaryDirectory(prefix="hdae5000_probe_") as tmp:
        probe_dir = os.path.join(tmp, "hdae5000")
        shutil.copytree(HDAE_DIR, probe_dir)
        n = instrument(os.path.join(probe_dir, TARGET_FILE))

        obj = os.path.join(tmp, "probe.o")
        elf = os.path.join(tmp, "probe.elf")
        rom = os.path.join(tmp, "probe.rom")

        subprocess.run([llvm_mc, "-triple=tlcs900", "-filetype=obj", "-I", probe_dir,
                         "-o", obj, os.path.join(probe_dir, "hd-ae5000_v2_06i.s")], check=True)
        subprocess.run([ld_lld, "-e", "0", "-T", os.path.join(probe_dir, "hdae5000.ld"),
                         "-o", elf, obj], check=True)
        subprocess.run([llvm_objcopy, "-O", "binary", elf, rom], check=True)

        with open(rom, "rb") as f:
            built = f.read()
        with open(ORIGINAL_ROM, "rb") as f:
            original = f.read()
        if built != original:
            sys.exit("PROBE BUILD IS NOT BYTE-IDENTICAL to original_ROMs/hd-ae5000_v2_06i.ic4 -- "
                     "the probe labels perturbed the image; addresses below would be untrustworthy. "
                     "Aborting without printing any output.")

        result = subprocess.run([llvm_nm, elf], check=True, capture_output=True, text=True)
        printed = 0
        for line in result.stdout.splitlines():
            parts = line.split()
            if len(parts) == 3 and parts[2].startswith("Lprobe_"):
                print(line)
                printed += 1
        if printed != n:
            sys.exit(f"expected {n} probe symbols, found {printed}")


if __name__ == "__main__":
    main()
