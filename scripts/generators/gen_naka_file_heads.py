#!/usr/bin/env python3
r"""Headers (and v9/v7 re-typing) for the first bytes of three ui_widgets/naka_* files.

QUESTION ANSWERED
    Three lane files begin in the middle of an object that starts in the
    previous file, with no label and no header (census: UNKNOWN):

    naka_effects_eq_dispatch.s (0xE27558-0xE27595): name / instance-code
        strings of InitializeKubo's 26 class records at 0xE27180
        (`RegObjTable 0x1600004, ClassProc, 0xe27596, 0xe27180, 0x168`); the
        records' 32-bit pointers to them are listed by --probe.  The first
        two bytes end "^^j", which starts at 0xE27556.  v9/v7 decode two of
        the strings as `jr gt` instructions.
    naka_screen_dispatch.s (0xE1B7EE-0xE1B80D): entries 26-32 and the NULL
        end of the 33-entry table at 0xE1B786 that InitializeSuna registers
        (`RegObjTabl 0x1600010, ViewableProc, 0x21, 0xe1b786, 0xb8`).  Four
        entries are RAM addresses 0x3D896.. (widgets initialised from
        WorkRamInit_Image); v10 tagged them "; padding", v9/v7 decoded them as
        instructions.
    naka_sound_technichord_dispatch.s (0xE818EC..): the tail of the NAKA
        record whose header (type 0x25) is at 0xE818E6; a pointer to it is at
        0xE85474.  Only a header is added (its lines are already typed).

RUN
    python3 scripts/generators/gen_naka_file_heads.py --probe
    python3 scripts/generators/gen_naka_file_heads.py --apply v10 v9 v7
    make gate
"""
import argparse
import os
import struct
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import file_line_addresses as fla  # noqa: E402

NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
B = 0xE00000
EQ, SCR, TC = ("ui_widgets/naka_effects_eq_dispatch.s", "ui_widgets/naka_screen_dispatch.s",
               "ui_widgets/naka_sound_technichord_dispatch.s")


def rom(v):
    return open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()


def labels(v):
    out = subprocess.run([NM, "--defined-only", os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % v)],
                         capture_output=True, text=True, check=True).stdout
    at = {}
    for ln in out.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] == "t" and "_0x" not in p[2]:
            at.setdefault(int(p[0], 16), []).append(p[2])
    return at


def ptrs_into(d, lo, hi):
    out = []
    for i in range(0, len(d) - 3):
        t = struct.unpack_from("<I", d, i)[0]
        if lo <= t < hi:
            out.append((B + i, t))
    return out


def strings(d, a, stop):
    res = []
    while a < stop:
        e = d.index(b"\0", a - B)
        s = d[a - B:e].decode("latin-1")
        n = len(s) + 1 + ((len(s) + 1) % 2)
        if (len(s) + 1) % 2:
            assert d[e + 1] == 0xFF
        res.append(s)
        a += n
    assert a == stop
    return res


def eq_lines(v, d):
    assert d[0xE27556 - B:0xE2755A - B] == b"^^j\0"
    sites = ptrs_into(d, 0xE27558, 0xE27596)
    rec = [s for s, t in sites if 0xE27180 <= s < 0xE27180 + 26 * 24]
    head = [
        "; Name and instance-code strings of the 26 class records at 0xE27180 that",
        "; InitializeKubo registers (`RegObjTable 0x1600004, ClassProc, 0xe27596, 0xe27180,",
        "; 0x168`, sequencer/sequencer_ui.s): %d record fields point into these bytes" % len(rec),
        "; (32-bit pointers at 0x%06X..0x%06X).  The first two bytes end \"^^j\", which" % (min(rec), max(rec)),
        "; starts at 0xE27556 in the previous file.",
        "\t.byte 0x6a, 0x00"]
    return head + ["\taligned_string \"%s\"" % s for s in strings(d, 0xE2755A, 0xE27596)]


def scr_lines(v, d, at):
    vals = struct.unpack_from("<8I", d, 0xE1B7EE - B)
    assert vals[-1] == 0 and struct.unpack_from("<I", d, 0xE1B786 - B + 4 * 33)[0] == 0
    out = ["; Entries 26-32 and the NULL end of the 33-entry table at 0xE1B786 (it starts",
           "; in the previous file) that InitializeSuna registers: `RegObjTabl 0x1600010,",
           "; ViewableProc, 0x21, 0xe1b786, 0xb8` (storage/flash_floppy_handlers.s).",
           "; 0x0003Dxxx entries are RAM addresses of widgets that Boot_InitWorkRAM_ROMCopy1",
           "; initialises from WorkRamInit_Image (RAM 0x3D524 + k <- ROM 0xEED8C8 + k)."]
    for x in vals[:-1]:
        if 0x3D524 <= x < 0x3D524 + 8606:
            out.append("\t.long 0x%08X\t; RAM; from ROM 0x%06X" % (x, 0xEED8C8 + x - 0x3D524))
        else:
            names = sorted(at.get(x, []))
            out.append("\t.long %s" % (names[0] if names else "0x%08x" % x))
    out.append("\t.long 0\t; end of the table")
    return out


def tc_header(d):
    assert d[0xE818E6 - B:0xE818EA - B] == bytes([0x25, 0x00, 0x60, 0x01])
    sites = [s for s, t in ptrs_into(d, 0xE818E6, 0xE818E7)]
    return ["; Tail of the NAKA record whose header (naka_header type 0x25) is at 0xE818E6,",
            "; in the previous file; a 32-bit pointer to that record is at %s." % ", ".join(
                "0x%06X" % s for s in sites)]


def apply(v, dry):
    d = rom(v)
    at = labels(v)
    todo = [(EQ, 0xE27558, 0xE27596, eq_lines(v, d)), (SCR, 0xE1B7EE, 0xE1B80E, scr_lines(v, d, at))]
    for rel, lo, hi, new in todo:
        lm = fla.build(v, rel)
        first = {}
        for e in lm:
            first.setdefault(e["addr"], e["line"])
        path = os.path.join(ROOT, v, "maincpu", rel)
        lines = open(path, "rb").read().decode("latin-1").split("\n")
        fl = first[lo]
        while lines[fl - 1].startswith(("//", ";")) or not lines[fl - 1].strip():
            fl += 1              # keep the file's own header comments
        ll = first[hi] - 1
        while lines[ll - 1].startswith(";") or not lines[ll - 1].strip() or \
                (lines[ll - 1].rstrip().endswith(":") and not lines[ll - 1].startswith("\t")):
            ll -= 1
        old = lines[fl - 1:ll]
        print("%s %s: lines %d..%d (%d) -> %d" % (v, rel, fl, ll, len(old), len(new)))
        if not dry:
            lines[fl - 1:ll] = new
            open(path, "wb").write("\n".join(lines).encode("latin-1"))
    # technichord: header only, above the first data line
    lm = fla.build(v, TC)
    first = min(lm, key=lambda e: e["addr"])
    assert first["addr"] == 0xE818EC, hex(first["addr"])
    path = os.path.join(ROOT, v, "maincpu", TC)
    lines = open(path, "rb").read().decode("latin-1").split("\n")
    print("%s %s: header above line %d" % (v, TC, first["line"]))
    if not dry:
        lines[first["line"] - 1:first["line"] - 1] = tc_header(d)
        open(path, "wb").write("\n".join(lines).encode("latin-1"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--probe", action="store_true")
    ap.add_argument("--apply", nargs="+")
    a = ap.parse_args()
    for v in (a.apply or ["v10", "v9", "v7"]):
        apply(v, not a.apply)
    return 0


if __name__ == "__main__":
    sys.exit(main())
