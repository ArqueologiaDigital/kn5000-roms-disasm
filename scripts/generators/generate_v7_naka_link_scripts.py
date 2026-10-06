#!/usr/bin/env python3
"""generate_v7_naka_link_scripts.py -- give v7's NAKA link scripts v7 addresses, where v7's own bytes agree.

QUESTION IT ANSWERS
  v7's naka_*.c sources (and the EXTRA list below: sepaout_config.c, SEPA_ADDR) are shared with v9/v10 and
  spell code pointers as NAKA_ADDR(Name); each
  v7/maincpu/ui_widgets/naka_<stem>_link.ld defines Name.  Until 2026-10-06 those files were copies of v10's, so
  every pointer compiled to its v10 address and scripts/build/apply_v7_c_divergence.py relocated it afterwards
  (v7_c_divergence.json).  This script sets each symbol to its v7 address -- the v7 ELF's value of the same
  name -- but only when the v7 bytes agree: compile the C with the current script, read the object's
  relocations (which offset uses which symbol), and look at the FINAL v7 bin (the patched build product the gate
  certifies) at every such offset.
      every site holds the v7 ELF address  -> the symbol becomes its v7 address
      every site holds the current value    -> unchanged
      anything else                         -> unchanged, and listed: the v7 ELF's label of that name is not
                                               where v7's own pointers go (a naming drift between versions)
  Absolute constants (not .text symbols of the v7 ELF) are never touched.

RUN (repository root; a built tree, so that the v7 ELF and the patched v7 bins exist)
  python3 scripts/generators/generate_v7_naka_link_scripts.py            # report
  python3 scripts/generators/generate_v7_naka_link_scripts.py --apply    # rewrite the link scripts
  then: python3 scripts/build/regenerate_v7_c_divergence.py --apply ; make all ; make gate-all
"""
import glob
import os
import re
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BIN = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
WID = os.path.join(REPO, "v7", "maincpu", "ui_widgets")
GEN = os.path.join(REPO, "v7", "maincpu", "includes", "generated")
# other compiled-C bins of v7 whose link script defines code pointers the same way: (link script, C, bin)
EXTRA = [("ui/sepaout_config_link.ld", "ui/sepaout_config.c", "sepaout_config.bin")]
ASSIGN = re.compile(r'^(\w+)(\s*=\s*)0x([0-9A-Fa-f]+);', re.M)


def v7_symbols():
    out = subprocess.run([BIN + "/llvm-nm", "--defined-only",
                          os.path.join(REPO, "rebuilt_ROMs", "kn5000_v7_program.llvm.elf")],
                         capture_output=True, text=True, check=True).stdout
    return {f[2]: int(f[0], 16) for f in (l.split() for l in out.splitlines()) if len(f) == 3 and f[1] in "tT"}


def relocations(c_path, ld_path, tmp):
    o = os.path.join(tmp, "x.o")
    e = os.path.join(tmp, "x.elf")
    subprocess.run([BIN + "/clang", "-target", "tlcs900", "-ffreestanding", "-c", "-O2", "-I", WID, "-o", o, c_path],
                   check=True)
    subprocess.run([BIN + "/ld.lld", "-T", ld_path, "-o", e, o], check=True)
    txt = subprocess.run([BIN + "/llvm-readobj", "-r", o], capture_output=True, text=True, check=True).stdout
    sites = []
    for m in re.finditer(r'0x([0-9A-Fa-f]+)\s+R_\w+\s+(\w+)\s+(?:0x([0-9A-Fa-f]+))?', txt):
        sites.append((int(m.group(1), 16), m.group(2), int(m.group(3), 16) if m.group(3) else 0))
    return sites


def main():
    apply = "--apply" in sys.argv
    v7 = v7_symbols()
    moved = kept_drift = 0
    drift = []
    with tempfile.TemporaryDirectory(dir=os.environ.get("TMPDIR")) as tmp:
        jobs = [(ld, os.path.join(WID, os.path.basename(ld)[:-len("_link.ld")] + ".c"),
                 os.path.join(GEN, os.path.basename(ld)[:-len("_link.ld")] + ".bin"))
                for ld in sorted(glob.glob(os.path.join(WID, "naka_*_link.ld")))]
        jobs += [(os.path.join(REPO, "v7/maincpu", a), os.path.join(REPO, "v7/maincpu", b), os.path.join(GEN, n))
                 for a, b, n in EXTRA]
        for ld, c, final in jobs:
            stem = os.path.basename(ld)[:-len("_link.ld")]
            if not (os.path.exists(c) and os.path.exists(final)):
                continue
            text = open(ld, encoding="latin-1").read()
            cur = {m.group(1): int(m.group(3), 16) for m in ASSIGN.finditer(text)}
            fb = open(final, "rb").read()
            uses = {}
            for off, sym, addend in relocations(c, ld, tmp):
                if sym in cur and off + 4 <= len(fb):
                    uses.setdefault(sym, []).append((int.from_bytes(fb[off:off + 4], "little") - addend) & 0xFFFFFFFF)
            new = dict(cur)
            for sym, vals in uses.items():
                if sym not in v7 or v7[sym] == cur[sym]:
                    continue
                if all(v == v7[sym] for v in vals):
                    new[sym] = v7[sym]
                    moved += 1
                elif not all(v == cur[sym] for v in vals):
                    kept_drift += 1
                    drift.append((stem, sym, cur[sym], v7[sym], sorted(set(vals))[:3]))
            if apply and new != cur:
                text2 = ASSIGN.sub(lambda m: "%s%s0x%08X;" % (m.group(1), m.group(2), new[m.group(1)]), text)
                if "v7 addresses" not in text2:
                    text2 = text2.replace("*/", " * v7 addresses where v7's own bytes agree:\n"
                                                " * scripts/generators/generate_v7_naka_link_scripts.py\n */", 1)
                open(ld + ".tmp", "w", encoding="latin-1").write(text2)
                os.replace(ld + ".tmp", ld)
    print("%d symbols take their v7 address; %d keep the old value because v7's bytes point elsewhere"
          % (moved, kept_drift))
    for d in drift[:40]:
        print("  drift %-28s %-40s ld 0x%06X  v7 ELF 0x%06X  v7 bytes %s" % (d[0], d[1], d[2], d[3],
                                                                          ["0x%06X" % x for x in d[4]]))


if __name__ == "__main__":
    main()
