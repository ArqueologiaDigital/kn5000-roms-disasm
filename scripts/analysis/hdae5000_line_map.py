#!/usr/bin/env python3
r"""hdae5000_line_map.py -- which hdae5000 source line emits the byte at address X?

QUESTION ANSWERED
-----------------
The HD-AE5000 sources are split over seven `.s` files that `.include` each
other, and since the 2026-09-25 branch symbolisation most labels no longer
carry an address comment.  "What does the tree say at 0x2974DD?" and "at what
address does line N of hdae5000_ui_display.s assemble?" therefore have no grep
answer.  This tool builds one for ALL seven files at once.

HOW
---
Mirror `hdae5000/` into a temp dir, insert a synthetic label `__hlm_<f>_<n>:`
in front of every non-blank, non-comment line of every hdae5000 source (outside
`.macro` bodies), assemble and LINK the mirror with the real `hdae5000.ld`,
and read the marker addresses back out of the ELF with `llvm-nm`.

★ THE MIRROR IS PROVEN INERT: the linked mirror is objcopy'd and compared
  byte-for-byte with `original_ROMs/hd-ae5000_v2_06i.ic4`.  A label emits no
  bytes, so a matching ROM proves the map describes THIS tree.  A mismatch is a
  hard failure -- no map is written.

PREREQUISITE: the generated image blobs (`make hdae5000-images`, or any build
of `rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom`) must exist; they are copied into
the mirror.

RUN
    python3 scripts/analysis/hdae5000_line_map.py --dump OUT.tsv
        # one row per marked line: ADDR<TAB>FILE<TAB>LINE<TAB>TEXT
    python3 scripts/analysis/hdae5000_line_map.py 0x2974DD [0x297500]
        # the lines that emit an address (or a window)
"""
import bisect
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM = os.environ.get("LLVM_BIN", os.path.expanduser("~/compartilhado/llvm-project/build/bin"))
MC, LLD, OBJCOPY, NM = (os.path.join(LLVM, t) for t in ("llvm-mc", "ld.lld", "llvm-objcopy", "llvm-nm"))
HDAE = os.path.join(ROOT, "hdae5000")
DUMP = os.path.join(ROOT, "original_ROMs", "hd-ae5000_v2_06i.ic4")
FILES = ["hd-ae5000_v2_06i.s", "hdae5000_hd_driver.s", "hdae5000_filesystem.s",
         "hdae5000_ui_display.s", "hdae5000_utilities.s", "hdae5000_data_tables.s",
         "hdae5000_init_data.s", "shared/event_codes.s"]
SKIP = re.compile(r"^\s*(\.(include|set|equ|equiv|macro|endm|text|section|global|globl|type|size)\b|$|;)", re.I)


def sh(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True, errors="replace")
    if r.returncode:
        raise SystemExit("FAILED: %s\n%s" % (" ".join(cmd), (r.stderr or r.stdout)[-3000:]))
    return r.stdout


def build_map():
    tmp = tempfile.mkdtemp(prefix="hlm-")
    try:
        mirror = os.path.join(tmp, "hdae5000")
        shutil.copytree(HDAE, mirror)
        texts = {}
        for fi, rel in enumerate(FILES):
            p = os.path.join(mirror, rel)
            lines = open(p, encoding="latin-1").read().split("\n")
            texts[rel] = lines
            out, inmac = [], False
            for n, ln in enumerate(lines, 1):
                s = ln.strip()
                if re.match(r"\.macro\b", s):
                    inmac = True
                if not inmac and not SKIP.match(ln) and not s.startswith(";"):
                    out.append("__hlm_%d_%d:" % (fi, n))
                out.append(ln)
                if re.match(r"\.endm\b", s):
                    inmac = False
            open(p, "w", encoding="latin-1").write("\n".join(out))
        obj, elf, rom = (os.path.join(tmp, x) for x in ("h.o", "h.elf", "h.rom"))
        sh([MC, "-triple=tlcs900", "-filetype=obj", "-I", mirror, "-o", obj,
            os.path.join(mirror, "hd-ae5000_v2_06i.s")])
        sh([LLD, "-T", os.path.join(mirror, "hdae5000.ld"), "-o", elf, obj])
        sh([OBJCOPY, "-O", "binary", elf, rom])
        built = open(rom, "rb").read()
        dump = open(DUMP, "rb").read()
        if built != dump[:len(built)] or dump[len(built):].strip(b"\x00"):
            raise SystemExit("MIRROR NOT INERT: linked mirror != %s -- no map" % DUMP)
        rows = []
        for ln in sh([NM, "--defined-only", elf]).splitlines():
            parts = ln.split()
            if len(parts) == 3 and parts[2].startswith("__hlm_"):
                _, fi, n = parts[2].split("_")[-3:]
                rel = FILES[int(fi)]
                rows.append((int(parts[0], 16), rel, int(n), texts[rel][int(n) - 1]))
        rows.sort()
        return rows, dump
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main(argv):
    rows, _ = build_map()
    if argv and argv[0] == "--dump":
        with open(argv[1], "w", encoding="latin-1") as f:
            for a, rel, n, t in rows:
                f.write("%06X\t%s\t%d\t%s\n" % (a, rel, n, t))
        print("wrote %d rows to %s (mirror byte-identical to dump)" % (len(rows), argv[1]))
        return
    addrs = [r[0] for r in rows]
    lo = int(argv[0], 16)
    hi = int(argv[1], 16) if len(argv) > 1 else lo
    i = max(0, bisect.bisect_right(addrs, lo) - 1)
    while i < len(rows) and rows[i][0] <= hi:
        a, rel, n, t = rows[i]
        print("%06X  %s:%d\t%s" % (a, rel, n, t))
        i += 1


if __name__ == "__main__":
    main(sys.argv[1:])
