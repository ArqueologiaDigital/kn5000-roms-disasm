#!/usr/bin/env python3
r"""sequi_symbolize_macro_args.py -- ROM-address arguments of RegObjTable /
RegObjTabl / RegMode / RegTitle macro calls -> the label at that address.

QUESTION THIS ANSWERS
    CLAUDE.md's symbolic-reference policy covers macro operands too, and the
    symboliser only rewrites branch operands.  Which numeric ADDRESS arguments
    of RegObjTable / RegObjTabl calls in this lane's files (B, D, and
    RegObjTable's C -- the positions the macro bodies use as addresses) does
    the linked ELF already name, and do the files rebuild byte-identical?
    (RegMode / RegTitle arguments are values: an 0xE00000 there is a title id,
    and naming it LED_patterns_indicating_firmware_version would be wrong.)

RULES
    * only RegObjTable / RegObjTabl lines, only their address positions;
    * only arguments that are a plain number >= 0xE00000 and <= 0xFFFFFF;
    * only `t` (section) labels, never `.L`/`__` locals, never positional
      `*_0xNNN` aliases, never `Str_<hex digest>` names (misframe leftovers);
    * --apply rebuilds the image and compares it with the dump; restores the
      file on any difference.

RUN
    python3 scripts/converters/sequi_symbolize_macro_args.py --image v10 FILE... [--apply]
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
MAC = re.compile(r'^(\s*)(RegObjTable|RegObjTabl|RegMode|RegTitle)(\s+)(.*?)(\s*;.*)?$')


def labels(image):
    out = subprocess.run([NM, "--defined-only",
                          os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % image)],
                         capture_output=True, text=True, check=True).stdout
    lab = {}
    for ln in out.split("\n"):
        p = ln.split()
        if len(p) != 3 or p[1] not in "tT":
            continue
        n = p[2]
        if n.startswith((".L", "__")) or re.search(r"_0x[0-9A-Fa-f]+$", n) \
                or re.match(r"^Str_[0-9a-f]{8,}$", n):
            continue
        lab.setdefault(int(p[0], 16), n)
    return lab


def main():
    args = sys.argv[1:]
    image = args[args.index("--image") + 1]
    apply = "--apply" in args
    files = [a for a in args if a not in ("--apply", "--image", image)]
    lab = labels(image)
    saved = {}
    total = 0
    for f in files:
        src = open(f, encoding="latin-1").read()
        L = src.split("\n")
        n = 0
        for i, ln in enumerate(L):
            m = MAC.match(ln)
            if not m:
                continue
            parts = [x.strip() for x in m.group(4).split(",")]
            # which argument positions are ADDRESSES, from the macro bodies in
            # display/scoop_display.s: RegObjTable B (lda_24), C (ldw_da), D
            # (lda_24); RegObjTabl B and D.  RegMode/RegTitle take values
            # (an 0xE00000 there is an id, not an address), so none.
            addr_pos = {"RegObjTable": (1, 2, 3), "RegObjTabl": (1, 3)}.get(m.group(2), ())
            new = []
            for k, x in enumerate(parts):
                if k in addr_pos and re.match(r"^0x[0-9a-fA-F]+$", x) \
                        and 0xE00000 <= int(x, 16) <= 0xFFFFFF and int(x, 16) in lab:
                    new.append(lab[int(x, 16)])
                    n += 1
                else:
                    new.append(x)
            L[i] = m.group(1) + m.group(2) + m.group(3) + ", ".join(new) + (m.group(5) or "")
        print("%s: %d argument(s)" % (f, n))
        total += n
        if apply and n:
            saved[f] = src
            open(f, "w", encoding="latin-1").write("\n".join(L))
    if not apply or not total:
        return
    r = subprocess.run(["make", "rebuilt_ROMs/kn5000_%s_program.llvm.rom" % image], cwd=ROOT,
                       capture_output=True, text=True)
    ok = r.returncode == 0 and open(os.path.join(
        ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.rom" % image), "rb").read() == open(
        os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % image), "rb").read()
    if not ok:
        for f, s in saved.items():
            open(f, "w", encoding="latin-1").write(s)
        sys.exit("REJECTED: image differs or build failed; files restored")
    print("VERIFIED: %s byte-identical" % image)


if __name__ == "__main__":
    main()
