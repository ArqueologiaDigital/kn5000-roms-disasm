#!/usr/bin/env python3
r"""Type the count words and one-entry function tables at the ends of the Suna and Yoko object tables.

QUESTION ANSWERED
    InitializeSuna (storage/flash_floppy_handlers.s) and InitializeYoko
    (sequencer/sequencer_ui.s) register object tables with RegObjTable /
    RegObjTabl; several of the operands point at bytes the tree spells as
    "padding" rows or (v9/v7) as instructions decoded from them:

      Suna  0xE17322  u16 41   count of the class table 0xE16C86   (RegObjTable 0x1600004, id 0x164)
            0xE17324  u32 0    empty table                          (RegObjTable 0x160000c, id 0x1c4)
            0xE17328  u16 0    its count
            0xE176D2  u16 50   count of the method table 0xE1732A  (RegObjTable 0x160000d, id 0x1e4)
            0xE176D4  {routine, 0}      function table              (RegObjTabl 0x1600001, count 1, id 0x104)
            0xE176DC  {"PaintArrowProc", ""} its name table         (RegObjTabl 0x1600001, count 1, id 0x404)
      Yoko  0xE20E22  u16 20   count of the event table 0xE20CB0   (RegObjTable 0x160000c, id 0x1c7)
            0xE20E24  the method table (27 entries) starts here, one entry before the
                      label MtName_PtrTable -- its first entry, -> "MT_DemoSongSel", was
                      part of the "padding" row
            0xE2106A  u16 27   its count                            (RegObjTable 0x160000d, id 0x1e7)
            0xE2106C  {routine, 0}      function table              (RegObjTabl 0x1600001, count 1, id 0x107)
            0xE21074  {"PsSongSelBoxProc", ""} its name table       (RegObjTabl 0x1600001, count 1, id 0x407)

    The addresses are the same in v10, v9 and v7 (checked against each ROM:
    the values above are read from it, and --check asserts them).  This script
    rewrites exactly those byte ranges as typed lines with labels; the
    registration headers are then written by gen_regobj_table_headers.py.

RUN
    python3 scripts/converters/retype_regobj_tails.py --check
    python3 scripts/converters/retype_regobj_tails.py --apply v10 v9 v7
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
PD, DP = "ui_widgets/naka_property_descriptors.s", "ui_widgets/naka_direct_play_dispatch.s"


def rom(v):
    return open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()


def syms(v):
    out = subprocess.run([NM, "--defined-only", os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % v)],
                         capture_output=True, text=True, check=True).stdout
    by_name, by_addr = {}, {}
    for ln in out.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] == "t":
            by_name[p[2]] = int(p[0], 16)
            if "_0x" not in p[2]:
                by_addr.setdefault(int(p[0], 16), []).append(p[2])
    return by_name, by_addr


def u16(d, a):
    return struct.unpack_from("<H", d, a - B)[0]


def u32(d, a):
    return struct.unpack_from("<I", d, a - B)[0]


def ref(v, by_addr, names, preferred=None):
    if preferred and preferred in names and names[preferred] == v:
        return preferred
    if v in by_addr:
        return sorted(by_addr[v])[0]
    return "0x%08x" % v


def cstr(d, a):
    return d[a - B:d.index(b"\0", a - B)].decode("latin-1")


def spots(v):
    d = rom(v)
    names, by_addr = syms(v)
    assert u16(d, 0xE17322) == 41 and u32(d, 0xE17324) == 0 and u16(d, 0xE17328) == 0
    assert u16(d, 0xE176D2) == 50 and u32(d, 0xE176D8) == 0
    assert cstr(d, u32(d, 0xE176DC)) == "PaintArrowProc" and cstr(d, u32(d, 0xE176E0)) == ""
    assert u16(d, 0xE20E22) == 20 and cstr(d, u32(d, 0xE20E24)) == "MT_DemoSongSel"
    assert u16(d, 0xE2106A) == 27 and u32(d, 0xE21070) == 0
    assert cstr(d, u32(d, 0xE21074)) == "PsSongSelBoxProc" and cstr(d, u32(d, 0xE21078)) == ""
    r1, r2 = u32(d, 0xE176D4), u32(d, 0xE2106C)
    a_song = names["MtName_SongNameSet"]
    assert cstr(d, a_song) == "MT_SongNameSet" and a_song + 16 == u32(d, 0xE20E24)
    return {
        (PD, 0xE17322, 0xE1732A): [
            "Suna_ClassCount_164:", "\t.short 41",
            "Suna_ResEventTable_1C4:", "\t.long 0",
            "Suna_ResEventCount_1C4:", "\t.short 0"],
        (PD, 0xE176D2, 0xE176E4): [
            "Suna_ResMethodCount_1E4:", "\t.short 50",
            "Suna_FunctionTable_104:",
            "\t.long %s\t; the routine named \"PaintArrowProc\" by the next table" % ref(r1, by_addr, names),
            "\t.long 0",
            "Suna_FunctionTable_404:",
            "\t.long NakaStr_PaintArrowProc_Empty + 2\t; -> \"PaintArrowProc\" name string",
            "\t.long NakaStr_PaintArrowProc_Empty\t; -> \"\", the end of the list"],
        (DP, 0xE20E22, 0xE20E28): [
            "Yoko_ResEventCount_1C7:", "\t.short 20",
            "MtName_PtrTable:", "\t.long MtName_DemoSongSel"],
        (DP, a_song, 0xE21078): [
            "MtName_SongNameSet:\t\taligned_string \"MT_SongNameSet\"",
            "MtName_DemoSongSel:\t\taligned_string \"MT_DemoSongSel\"",
            "Yoko_ResMethodCount_1E7:", "\t.short 27",
            "Yoko_FunctionTable_107:",
            "\t.long %s\t; the routine named \"PsSongSelBoxProc\" by the next table" % ref(r2, by_addr, names),
            "\t.long 0",
            "Yoko_FunctionTable_407:",
            "\t.long 0x%08x\t; -> \"PsSongSelBoxProc\" name string (next file)" % u32(d, 0xE21074)],
    }


def apply(v, dry):
    todo = spots(v)
    for rel in (PD, DP):
        lm = fla.build(v, rel)
        first = {}
        for e in lm:
            first.setdefault(e["addr"], e["line"])
        path = os.path.join(ROOT, v, "maincpu", rel)
        lines = open(path, "rb").read().decode("latin-1").split("\n")
        edits = []
        for (r, lo, hi), new in todo.items():
            if r != rel:
                continue
            assert lo in first, (v, rel, hex(lo))
            if hi in first:
                fl, ll = first[lo], first[hi] - 1
            else:
                # hi is the end of the file's bytes: replace through its last byte line
                last = max(lm, key=lambda e: e["addr"])
                assert last["addr"] + len(last["bytes"]) // 2 == hi or last["addr"] < hi, hex(hi)
                assert all(e["addr"] < hi for e in lm), hex(hi)
                fl, ll = first[lo], last["line"]
            # the label line of `lo` (if on its own line) belongs to the replaced block
            while fl > 1 and lines[fl - 2].rstrip().endswith(":") and not lines[fl - 2].startswith(("\t", ";")):
                fl -= 1
            # a label on its own line right before `hi` stays (it names hi) -- except MtName_PtrTable,
            # which moves to lo here
            while ll >= fl and lines[ll - 1].rstrip().endswith(":") and not lines[ll - 1].startswith(("\t", ";")):
                if lines[ll - 1].startswith("MtName_PtrTable:"):
                    break
                ll -= 1
            # MtName_PtrTable moves from hi to lo: drop its old label line
            if ll < len(lines) and lines[ll].startswith("MtName_PtrTable:"):
                ll += 1
            # the two header lines above the Suna tail describe it as "dispatch fields
            # (5) + zero padding (5) + two pointers (8)" -- proven false: they go too
            if lo == 0xE176D2:
                assert lines[fl - 3].startswith("; PaintArrowProc dispatch entry") and \
                    lines[fl - 2].startswith("; 18 bytes: dispatch fields (5)"), lines[fl - 3:fl - 1]
                fl -= 2
            old = lines[fl - 1:ll]
            print("%s %s 0x%06X-0x%06X: lines %d..%d" % (v, rel, lo, hi, fl, ll))
            for x in old:
                print("   - " + x)
            for x in new:
                print("   + " + x)
            edits.append((fl, ll, new))
        if not dry:
            for fl, ll, new in sorted(edits, key=lambda e: -e[0]):
                lines[fl - 1:ll] = new
            open(path, "wb").write("\n".join(lines).encode("latin-1"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--apply", nargs="+")
    a = ap.parse_args()
    for v in (a.apply or ["v10", "v9", "v7"]):
        apply(v, not a.apply)
    return 0


if __name__ == "__main__":
    sys.exit(main())
