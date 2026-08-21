#!/usr/bin/env python3
"""L2: do the committed symbol reference files agree with the build, and how
many symbols carry a MEANINGFUL name rather than a positional one?

docs/IS-IT-DONE.md scored L2 as PARTIAL because
symbols/maincpu_symbols_reference.txt matched the build on 1,332 of 39,449 rows
(3.4%) and said so in its own header: 35,924 rows were still LABEL_*, which the
built ELF does not contain at all, and 2,062 more were case-mangled.

The build is the source of truth -- its ELF is byte-identical to the original
ROM -- so the reference files are regenerated FROM it rather than hand-patched.

    --check   (default) compare each reference file to its ELF, report agreement
    --regen             rewrite the reference files from the ELFs

The naming metric, which is the part that actually scores L2, counts a symbol as
POSITIONAL when its name only restates where it lives:

    ends in _0xHEX          e.g. Resource_Region3_Start_0x10
    ends in a bare hex tail e.g. Something_1A3F2
    LABEL_* / loc_ / sub_ / unk_ / .L*      (the build currently has none)

Everything else is SEMANTIC. This is a lower bound on naming quality, not a
judgement of whether a name is APT -- no script can check that. A name like
FileIO_ReadHeader counts as semantic even though this session found it actually
builds a path rather than reading a header.

Run:  python3 scripts/analysis/l2_symbol_reference.py [--regen]
Exits non-zero if any reference file disagrees with its ELF.
"""
import os, re, subprocess, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")

PAIRS = {
    "maincpu":     "kn5000_v10_program.llvm.elf",
    "subcpu":      "kn5000_subprogram_v142.llvm.elf",
    "subcpu_boot": "kn5000_subcpu_boot.llvm.elf",
    "table_data":  "kn5000_table_data.llvm.elf",
    "hdae5000":    "hd-ae5000_v2_06i.llvm.elf",
}

POSITIONAL = [re.compile(p) for p in (
    r'_0x[0-9A-Fa-f]+$', r'_[0-9A-F]{4,}$', r'^LABEL_', r'^(loc|sub|unk)_', r'^\.L')]


def elf_symbols(elf):
    out = subprocess.run([NM, "--defined-only", elf], capture_output=True, text=True, cwd=ROOT)
    if out.returncode != 0:
        sys.exit(f"llvm-nm failed on {elf}")
    syms = []
    for line in out.stdout.split("\n"):
        f = line.split()
        if len(f) == 3 and f[1] in ("t", "T"):
            syms.append((int(f[0], 16), f[2]))
    return sorted(syms)


def is_positional(name):
    return any(p.search(name) for p in POSITIONAL)


def ref_path(tag):
    return os.path.join(ROOT, "symbols", f"{tag}_symbols_reference.txt")


def write_ref(tag, syms):
    sem = sum(1 for _, n in syms if not is_positional(n))
    with open(ref_path(tag), "w") as fh:
        fh.write("# Symbol Reference File\n# Format: SYMBOL_NAME ADDRESS\n#\n")
        fh.write(f"# GENERATED from rebuilt_ROMs/{PAIRS[tag]} by\n")
        fh.write("# scripts/analysis/l2_symbol_reference.py --regen\n")
        fh.write("# Do not hand-edit: rename in the sources and regenerate.\n#\n")
        fh.write(f"#   symbols .................. {len(syms):,}\n")
        fh.write(f"#   semantic names ........... {sem:,} ({100.0*sem/max(len(syms),1):.1f}%)\n")
        fh.write(f"#   positional names ......... {len(syms)-sem:,}\n#\n")
        for addr, name in syms:
            fh.write(f"{name} {addr:08X}\n")


def main():
    regen = "--regen" in sys.argv
    ok = True
    for tag, elf in PAIRS.items():
        path = os.path.join(ROOT, "rebuilt_ROMs", elf)
        if not os.path.exists(path):
            print(f"{tag:12} ELF missing ({elf}) -- run `make all` first"); ok = False; continue
        syms = elf_symbols(os.path.join("rebuilt_ROMs", elf))
        sem = sum(1 for _, n in syms if not is_positional(n))
        if regen:
            write_ref(tag, syms)
            print(f"{tag:12} wrote {len(syms):,} symbols  "
                  f"({100.0*sem/max(len(syms),1):.1f}% semantic)")
            continue
        have = {}
        if os.path.exists(ref_path(tag)):
            for line in open(ref_path(tag)):
                if line.startswith("#") or not line.strip():
                    continue
                f = line.split()
                if len(f) == 2:
                    have[f[0]] = int(f[1], 16)
        agree = sum(1 for a, n in syms if have.get(n) == a)
        match = agree == len(syms) == len(have)
        print(f"{tag:12} ELF {len(syms):>6,} symbols | file {len(have):>6,} rows | "
              f"agree {agree:>6,} ({100.0*agree/max(len(syms),1):5.1f}%) | "
              f"semantic {100.0*sem/max(len(syms),1):5.1f}%  {'OK' if match else 'STALE'}")
        ok &= match
    if not regen:
        print("\nPASS: every reference file matches its build." if ok
              else "\nFAIL: at least one reference file is stale -- rerun with --regen.")
    return 0 if ok or regen else 1


if __name__ == "__main__":
    sys.exit(main())
