#!/usr/bin/env python3
"""split_byte_runs_by_decode.py -- a run of `.byte` rows inside code becomes one `.byte` row per decoded
instruction, each carrying unidasm's reading, so respell_raw_pseudos.py --bytes can respell it.

QUESTION THIS ANSWERS / JOB IT DOES
  A port (port_v10_span_to_v7.py) emits as `.byte` every v7 byte with no byte-identical v10 line --
  v7 code that differs from v10, as well as data.  respell_raw_pseudos.py --bytes turns a `.byte` row
  into an instruction only when the row is ONE instruction with its reading in the comment.  This
  splits a maximal run of `.byte` rows (in the given files) at unidasm's instruction boundaries,
  decoding from the run's first byte, when -- and only when -- the decode TILES the run exactly (no
  instruction crosses the run's end) and no reading is `db` (undecodable).  Each piece is written
  `.byte b0, b1, ...  ; <reading>`.  Bytes, labels and comments of the run are kept: a run holding a
  label is split only where the label falls on an instruction boundary (labels stay on their byte).
  The respell then keeps only spellings llvm-mc reproduces, and only with code on both sides of a run.

USAGE (repository root, after a successful build of the tree)
  python3 scripts/converters/split_byte_runs_by_decode.py --tree v7 FILE.s [FILE.s ...] [--apply]
  python3 scripts/converters/respell_raw_pseudos.py --tree v7/maincpu --bytes --apply
"""
import argparse
import collections
import os
import re
import subprocess
import sys
import tempfile

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip()
sys.path.insert(0, os.path.join(REPO, "scripts", "tools"))
import place_labels as P          # noqa: E402

UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
BYTEROW = re.compile(r'^(?P<lab>[A-Za-z_][\w.$]*:)?(?P<sp>\s*)\.byte\s+(?P<ops>[^;]*?)\s*(?P<c>;.*)?$')


def decode(blob, base):
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(blob)
        p = f.name
    out = subprocess.run([UNIDASM, p, "-arch", "tlcs900", "-basepc", "%x" % base],
                         capture_output=True, text=True).stdout
    os.unlink(p)
    rows = []
    for l in out.split("\n"):
        m = re.match(r'^\s*([0-9a-fA-F]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$', l)
        if m:
            rows.append((int(m.group(1), 16), len(m.group(2).split()), m.group(3).strip()))
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True)
    ap.add_argument("files", nargs="+")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    pl = P.Planner(a.tree)
    rom = open(os.path.join(REPO, pl.img["rom"]), "rb").read()
    base = 0xE00000 if a.tree.startswith("v") else 0
    addr_of = {}
    for (sa, se, rel, li) in pl.spans:
        addr_of[(rel, li)] = (sa, se)
    st = collections.Counter()
    for rel in a.files:
        L = pl.lines(rel)
        out, i = [], 0
        while i < len(L):
            m = BYTEROW.match(L[i])
            if not m or (rel, i) not in addr_of:
                out.append(L[i])
                i += 1
                continue
            j = i
            while j < len(L) and BYTEROW.match(L[j]) and (rel, j) in addr_of:
                j += 1
            start, end = addr_of[(rel, i)][0], addr_of[(rel, j - 1)][1]
            cont = all(addr_of[(rel, k)][1] == addr_of[(rel, k + 1)][0] for k in range(i, j - 1))
            labs = {addr_of[(rel, k)][0]: BYTEROW.match(L[k]).group("lab") for k in range(i, j)
                    if BYTEROW.match(L[k]).group("lab")}
            rows = decode(rom[start - base:end - base], start) if cont else []
            tiles = rows and rows[-1][0] + rows[-1][1] == end and \
                all(rows[k][0] + rows[k][1] == rows[k + 1][0] for k in range(len(rows) - 1))
            ok = tiles and not any(r[2].startswith("db") for r in rows) and \
                set(labs) <= {r[0] for r in rows}
            if not ok:
                st["runs left (no clean tiling)"] += 1
                out.extend(L[i:j])
                i = j
                continue
            st["runs split"] += 1
            for (ad, n, txt) in rows:
                bs = ", ".join("0x%02x" % x for x in rom[ad - base:ad - base + n])
                lab = labs.get(ad)
                out.append("%s\t.byte %s\t; %s" % (lab or "", bs, txt))
                st["rows written"] += 1
            i = j
        if a.apply and out != L:
            data = "\n".join(out).encode("latin-1")
            full = os.path.join(pl.srcroot, rel)
            open(full + ".tmp", "wb").write(data)
            os.replace(full + ".tmp", full)
    print("%s%s" % (dict(st), "" if a.apply else " (dry run)"))


if __name__ == "__main__":
    sys.exit(main())
