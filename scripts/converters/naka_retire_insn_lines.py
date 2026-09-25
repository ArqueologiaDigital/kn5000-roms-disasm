#!/usr/bin/env python3
r"""Retire instruction lines from the ui_widgets/naka_* data files: spell their bytes as data.

QUESTION ANSWERED
    The naka_* files of this lane hold NAKA widget records, strings and
    registration tables -- no routine.  Every instruction statement in them
    is a data byte run decoded as code (`jr gt, 0` for "j>"..., `swi 7` for
    0xFF, `incf` for 0x0C, `normal` for 0x01 ...).  This script replaces each
    maximal run of instruction and `.byte` lines (no label, comment or other
    directive inside) that contains at least one instruction with the run's
    ROM bytes: printable text of >= 3 characters followed by NUL becomes
    `aligned_string` (or `.asciz` where the pad byte is not 0xFF), the rest
    `.byte` rows.  Bytes come from the line map (file_line_addresses.py),
    so the image cannot change; `make gate` confirms.

RUN
    python3 scripts/converters/naka_retire_insn_lines.py --check v10 v9 v7
    python3 scripts/converters/naka_retire_insn_lines.py --apply v10 v9 v7
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import file_line_addresses as fla  # noqa: E402

FILES = ["ui_widgets/naka_property_descriptors.s", "ui_widgets/naka_direct_play_property_tables.s",
         "ui_widgets/naka_direct_play_dispatch.s", "ui_widgets/naka_effects_eq_dispatch.s",
         "ui_widgets/naka_screen_dispatch.s", "ui_widgets/naka_sound_technichord_dispatch.s",
         "ui_widgets/naka_widget_desc_dispatch.s"]
MACROS = ("aligned_string", "naka_header", "addr24")


def kind(line):
    t = line.split(";")[0].strip() if not line.lstrip().startswith(".ascii") else line.strip()
    if not line.strip():
        return "blank"
    if line.lstrip().startswith((";", "//")):
        return "comment"
    if re.match(r"^[A-Za-z_.$][\w.$]*:", line):
        return "label"
    if t.startswith(".byte") and ";" not in line:
        return "byte"
    if t.startswith(".") or t.startswith(MACROS):
        return "other"
    if ";" in line:
        return "other"           # an instruction with a comment: leave it for a person
    return "insn"


def render(data, addr):
    out, i, row = [], 0, []

    def flush():
        for k in range(0, len(row), 8):
            out.append("\t.byte " + ", ".join("0x%02x" % b for b in row[k:k + 8]))
        row.clear()
    while i < len(data):
        j = i
        while j < len(data) and 0x20 <= data[j] < 0x7F and data[j] != 0x22 and data[j] != 0x5C:
            j += 1
        if j - i >= 3 and j < len(data) and data[j] == 0:
            end = j + 1
            s = data[i:j].decode("latin-1")
            if (addr + end) % 2 == 1:
                if end < len(data) and data[end] == 0xFF:
                    flush()
                    out.append('\taligned_string "%s"' % s)
                    i = end + 1
                    continue
                flush()
                out.append('\t.asciz "%s"' % s)
                i = end
                continue
            flush()
            out.append('\taligned_string "%s"' % s)
            i = end
            continue
        row.append(data[i])
        i += 1
    flush()
    return out


def run(v, apply_it):
    tot_runs = tot_ins = 0
    for rel in FILES:
        lm = fla.build(v, rel)
        by = {e["line"]: (e["addr"], bytes.fromhex(e["bytes"])) for e in lm}
        path = os.path.join(ROOT, v, "maincpu", rel)
        lines = open(path, "rb").read().decode("latin-1").split("\n")
        edits, i = [], 0
        while i < len(lines):
            k = kind(lines[i])
            if k not in ("insn", "byte") or (i + 1) not in by:
                i += 1
                continue
            j = i
            while j < len(lines) and kind(lines[j]) in ("insn", "byte") and (j + 1) in by:
                j += 1
            ins = sum(1 for x in range(i, j) if kind(lines[x]) == "insn")
            if ins:
                a0 = by[i + 1][0]
                data = b"".join(by[x + 1][1] for x in range(i, j))
                assert by[j][0] + len(by[j][1]) == a0 + len(data)
                edits.append((i, j, render(data, a0), ins))
            i = j
        n_ins = sum(e[3] for e in edits)
        tot_runs += len(edits)
        tot_ins += n_ins
        print("%s %s: %d runs, %d instruction lines" % (v, rel, len(edits), n_ins))
        if apply_it and edits:
            for i, j, new, _ in sorted(edits, reverse=True):
                lines[i:j] = new
            open(path, "wb").write("\n".join(lines).encode("latin-1"))
    print("%s total: %d runs, %d instruction lines retired" % (v, tot_runs, tot_ins))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", nargs="*")
    ap.add_argument("--apply", nargs="+")
    a = ap.parse_args()
    for v in (a.apply or a.check or ["v10", "v9", "v7"]):
        run(v, bool(a.apply))
    return 0


if __name__ == "__main__":
    sys.exit(main())
