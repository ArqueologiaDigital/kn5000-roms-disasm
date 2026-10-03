#!/usr/bin/env python3
"""label_far_pointer_targets.py -- a far pointer into the middle of an object gets a label of its own there.

QUESTION THIS ANSWERS / JOB IT DOES
  scripts/converters/symbolize_far_pointer_pushes.py spells `pushw 0x00ff / pushw 0x00f7` as
  `pushw Sym@hi16 / pushw Sym@lo16` only when a column-0 label sits exactly at the pointer; it
  reports the rest "inside <object>+<offset>" (165 in v10 on 2026-10-02, after the far-pointer
  pipeline of the same day had split the string blobs).  CLAUDE.md wants a reference inside an
  object to split it there and name the new piece.  For each such report row this places a
  label at the pointer (scripts/tools/place_labels.py: in front of the line, or by cutting the
  `.incbin` slice / list there; a pointer inside an instruction is left and reported) named
  after the routine that pushes it -- the nearest non-structural column-0 label above the push
  -- as `<Reader>_Code` when a code line starts there (a callback or handler address loaded as
  a value: structural on purpose, what it does is not established here), `<Reader>_Str_<Text>`
  when a NUL-terminated ASCII string starts there (split_blobs_at_far_pointers.c_string_at /
  text_token), else `<Reader>_Data`; unique with _2, _3 ...  Then run
  symbolize_far_pointer_pushes.py --apply (after `make`) to spell the pushes.
  It also takes symbolize_kn5000_rom_operands.py's report: its "no-symbol" rows are numeric
  operands (`lda xix, 0xed9d30`) at addresses with no label; follow with that script --apply.
  A label emits no byte: `make gate-all` proves it.

USAGE
  make all
  python3 scripts/converters/symbolize_far_pointer_pushes.py --image v10 --report FAR.json
  python3 scripts/tools/label_far_pointer_targets.py --tree v10 FAR.json [--apply]
  python3 scripts/converters/symbolize_kn5000_rom_operands.py --image v10 --report OPS.json
  python3 scripts/tools/label_far_pointer_targets.py --tree v10 OPS.json [--apply]
"""
import argparse
import collections
import json
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.join(REPO, "scripts", "converters"))
sys.path.insert(0, os.path.join(REPO, "scripts", "tools"))
import place_labels                           # noqa: E402
import split_blobs_at_far_pointers as sb      # noqa: E402
import symbolize_far_pointer_pushes as fp     # noqa: E402

COL0 = re.compile(r'^([A-Za-z_][\w.$]*):')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=("v10", "v9", "v7", "hdae5000", "prom_a", "prom_b", "prom_c"))
    ap.add_argument("report")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    # far-pointer report rows "inside <obj>+<off>", or operand report rows "no-symbol"
    # (scripts/converters/symbolize_kn5000_rom_operands.py --report)
    rows = [x for x in json.load(open(a.report))
            if str(x.get("result", "")).startswith("inside ") or x.get("result") == "no-symbol"]
    elf, src, _ = fp.IMAGES[a.tree]
    rom_path, base = sb.ROM[a.tree]
    rom = open(os.path.join(REPO, rom_path), "rb").read()
    syms = fp.elf_symbols(elf)
    taken = set(n for ns in syms.values() for n in ns)
    planner = place_labels.Planner(a.tree)
    cache, st, want = {}, collections.Counter(), {}

    def reader(path, line):
        if path not in cache:
            cache[path] = open(os.path.join(REPO, path), "rb").read().decode("latin-1").split("\n")
        for l in reversed(cache[path][:line]):
            m = COL0.match(l)
            if m and not m.group(1).startswith("__") and (not fp.STRUCT.search(m.group(1)) or
                                                          re.match(r'^sub_[0-9A-F]{6}$', m.group(1))):
                return m.group(1)               # WSA1: sub_<ADDR> IS the routine's name
        return None
    for x in sorted(rows, key=lambda x: (x["file"], x["line"])):
        v = int(x["value"], 16)
        if v in want:
            continue
        r = reader(x["file"], x["line"])
        if not r:
            st["no reader"] += 1
            continue
        s = sb.c_string_at(rom, base, v)
        good = s is not None and len(s) >= 1 and rom[v - base - 1] in (0, 0xff)
        w = planner.where(v)
        code = bool(w) and w[0] == v and \
            place_labels.snb.drc.classify_line(planner.lines(w[1])[w[2]], planner.macros)[0] == "code"
        if code and str(x.get("result", "")).startswith("inside "):
            # a PUSH-PAIR "pointer" onto an unlabelled code line, in a tree where every routine
            # entry is labelled, is two word arguments that happen to make a code address --
            # SeMenu's `pushw 121 / 254 / 73 / 48`, a DrawString colour pair whose call is
            # reached by a jump (0xFF00F5 ...).  2026-10-03: three such labels were placed and
            # reverted.  Reported, not placed.
            st["push pair onto unlabelled code: not a pointer, not placed"] += 1
            continue
        want[v] = "%s_Code" % r if code else "%s_Str_%s" % (r, sb.text_token(s)) if good else "%s_Data" % r
    for v, nm in sorted(want.items()):
        b, k = nm, 2
        while nm in taken:
            nm, k = "%s_%d" % (b, k), k + 1
        how = planner.add(v, nm)
        if how in ("line-start", "incbin", "list", "ascii"):
            taken.add(nm)
        st["placed: " + how] += 1
    print("%s: %d pointers into objects; %s%s" % (a.tree, len(want), dict(st), "" if a.apply else " (dry run)"))
    if a.apply:
        planner.apply()
    return 0


if __name__ == "__main__":
    sys.exit(main())
