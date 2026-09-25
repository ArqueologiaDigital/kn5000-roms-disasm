#!/usr/bin/env python3
r"""Symbolise the table-data bootloader's numeric boot-alias operands.

QUESTION THIS ANSWERS
    The first-stage bootloader in table_data runs while the table-data ROM is
    mapped at 0xE00000-0xFFFFFF, so its absolute operands are BOOT-TIME
    addresses: ROM label + 0x600000 (0x9FB700 is called as 0xFFB700).  The
    tree already writes that form symbolically in places
    (`call Boot_sbrk + 0x600000`, `.long BootSerial_Init + 0x600000`); this
    tool finds the remaining NUMERIC ones (`call 0xFFB700`,
    `lda xix, (0xffb496:24)`, `ld xwa, 0xFFAAF6`, decimal `(16776944:24)`)
    in lane tdata's files and rewrites each to `<label> + 0x600000` when a
    label sits EXACTLY at operand - 0x600000 in the linked table-data ELF.

    Refused (left numeric and listed): operands with no label at the target,
    targets inside another label's object (mid-object), and the two
    Program-ROM handoff constants 0xFFFEDC / 0xFFFED8, which are jumped to
    AFTER the program ROM is mapped over 0xE00000 and so do not name a
    table-data address at all.

    Byte-neutral by construction (the assembler folds label + constant to the
    same value); certify with the byte gate anyway.

RUN
    make rebuilt_ROMs/kn5000_table_data.llvm.elf
    python3 scripts/converters/tabledata_boot_alias_symbolize.py            # report
    python3 scripts/converters/tabledata_boot_alias_symbolize.py --apply    # rewrite
"""
import argparse
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
ELF = os.path.join(ROOT, "rebuilt_ROMs/kn5000_table_data.llvm.elf")
FILES = ["table_data/kn5000_table_data.s", "table_data/boot_clib.s", "table_data/boot_cpserial.s",
         "table_data/boot_cpserial_isr.s", "table_data/boot_cpserial_states.s",
         "table_data/boot_debug.s", "table_data/boot_disk_probe.s", "table_data/boot_fdc_driver.s",
         "table_data/shared/boot_call_init_handlers.s", "table_data/shared/boot_hw_init.s",
         "table_data/shared/boot_routines.s", "table_data/shared/vga_init.s",
         "table_data/shared/vga_io.s"]
ALIAS = 0x600000
LO, HI = 0xFFA000, 0x1000000
PROGRAM_ROM_HANDOFF = {0xFFFEDC, 0xFFFED8}
# instruction shapes whose operand is an address: call/jp (bare or cc,(...)),
# lda/ld/cp* with (N:24), and ld xrr, N (immediate address load)
NUM = r'(0x[0-9A-Fa-f]+|\d+)'
SHAPES = [
    re.compile(r'^(\s*(?:call|jp)\s+)' + NUM + r'(\s*)$', re.I),
    re.compile(r'^(\s*(?:call|jp)\s+[a-z]+\s*,\s*\()' + NUM + r'(:24\)\s*)$', re.I),
    re.compile(r'^(\s*(?:lda|ld|cpw|cp)\s+[^,]*,\s*\()' + NUM + r'(:24\)\s*)$', re.I),
    re.compile(r'^(\s*(?:cpw|cp)\s+\()' + NUM + r'(:24\)\s*,.*)$', re.I),
    re.compile(r'^(\s*ld\s+x(?:wa|bc|de|hl|ix|iy|iz)\s*,\s*)' + NUM + r'(\s*)$', re.I),
]


def symbols():
    out = subprocess.run([NM, "--defined-only", ELF], capture_output=True, text=True, check=True).stdout
    at = {}
    starts = []
    for ln in out.split("\n"):
        p = ln.split()
        if len(p) == 3 and p[1] in "tT":
            a = int(p[0], 16)
            at.setdefault(a, []).append(p[2])
            starts.append(a)
    return at, sorted(set(starts))


def split_comment(line):
    q = None
    for i, ch in enumerate(line):
        if q:
            if ch == q:
                q = None
            continue
        if ch in "\"'":
            q = ch
        elif ch == ";":
            return line[:i], line[i:]
    return line, ""


def pick(names):
    good = [n for n in names if not n.startswith(("__", "."))]
    return sorted(good, key=lambda n: (("_0x" in n), len(n)))[0] if good else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    at, _ = symbols()
    done, refused = [], []
    for rel in FILES:
        path = os.path.join(ROOT, rel)
        raw = open(path, "rb").read()
        lines = raw.split(b"\n")
        changed = False
        for i, bl in enumerate(lines):
            line = bl.decode("latin-1")
            code, com = split_comment(line)
            for sh in SHAPES:
                m = sh.match(code)
                if not m:
                    continue
                tok = m.group(2)
                v = int(tok, 0)
                if not (LO <= v < HI):
                    break
                if v in PROGRAM_ROM_HANDOFF:
                    refused.append((rel, i + 1, tok, "program-ROM handoff constant"))
                    break
                names = at.get(v - ALIAS)
                lab = pick(names) if names else None
                if not lab:
                    refused.append((rel, i + 1, tok, "no label at 0x%06X" % (v - ALIAS)))
                    break
                new = m.group(1) + lab + " + 0x600000" + m.group(3) + com
                done.append((rel, i + 1, tok, lab))
                lines[i] = new.encode("latin-1")
                changed = True
                break
        if changed and a.apply:
            open(path, "wb").write(b"\n".join(lines))
    for r in done:
        print("  %-44s:%-5d %-12s -> %s + 0x600000" % r)
    for r in refused:
        print("  REFUSED %-36s:%-5d %-12s %s" % r)
    print("%s: %d rewritten, %d refused" % ("APPLIED" if a.apply else "DRY RUN", len(done), len(refused)))


if __name__ == "__main__":
    sys.exit(main())
