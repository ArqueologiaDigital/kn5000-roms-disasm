#!/usr/bin/env python3
r"""hdae5000_symbolize_fn_tables.py -- which main-CPU function does each
`(workspace + 0x0E0A / 0x0E88)[off]` call of the HD-AE5000 reach?

QUESTION ANSWERED / JOB IT DOES
-------------------------------
The HD-AE5000 code never calls the main CPU by address.  It loads the
workspace pointer (HDAE5000_RAM_MainWorkspacePtr), then a table pointer at
+0x0E0A or +0x0E88, then a function pointer at a fixed offset of that table:

    ld  xwa, (HDAE5000_RAM_MainWorkspacePtr:24)
    ld  xwa, (xwa + 0x0e0a)
    ld  xhl, (xwa + 0x0100)
    call (xhl)

Which function that is follows from the main CPU's own code and data:

  * the workspace is the object table at 0x027ED2: RegisterObjectTable
    (v10/maincpu/ui/ui_widget_defs.s) stores a 14-byte record
    {id, proc, count, data pointer} at 0x027ED2 + 14 * index, the data
    pointer at +10.  So +0x0E0A = 14 * 0x100 + 10 is the data pointer of
    table 0x100, and +0x0E88 = 14 * 0x109 + 10 that of table 0x109.
  * InitializeRoot (v10/maincpu/display/graphics_text_vga.s) registers
    table 0x100 as `RegObjTabl 0x1600001, FunctionProc, 0x160, 0xeafa6e,
    0x100` and its NAME table as `..., WidgetName_InitPtrTable, 0x400`.
  * InitializeHama (v10/maincpu/factory_test/test_init.s, called at boot from
    ui_widget_defs.s) registers table 0x109 as `RegObjTablHama 0x1600001,
    FunctionProc, 0x4b, 0xe1f0ec, 0x109` and its names as
    `..., Hama_ModeParam_Table, 0x409`.

So for every offset used, this tool reads, from original_ROMs/
kn5000_v10_program.rom, the function pointer (table + off) and the name
string the firmware itself files under the same index (name table + off),
and checks that the two agree with the main-CPU build's label at that
address (llvm-nm of rebuilt_ROMs/kn5000_v10_program.llvm.elf).  The names
are the FIRMWARE'S OWN (Matsushita) function names, not ours.

It then gives every offset used a constant, `RootFn_<name>` (table 0x100) or
`HamaFn_<name>` (table 0x109), plus `WS_RootFnTable` = 0x0E0A and
`WS_HamaFnTable` = 0x0E88, written as one .equ block after the RAM block of
hd-ae5000_v2_06i.s (before any code), and rewrites the operands.  Values are
unchanged, so encodings are too; --apply re-links through
scripts/analysis/hdae5000_line_map.py, which refuses unless byte-identical.

RUN (repo root, after `make` has built the v10 ELF)
    python3 scripts/converters/hdae5000_symbolize_fn_tables.py          # table
    python3 scripts/converters/hdae5000_symbolize_fn_tables.py --apply
"""
import collections
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import hdae5000_line_map as hlm  # noqa: E402

ROM = os.path.join(ROOT, "original_ROMs", "kn5000_v10_program.rom")
ELF = os.path.join(ROOT, "rebuilt_ROMs", "kn5000_v10_program.llvm.elf")
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
OBJTAB, RECSZ, DATAPTR = 0x027ED2, 14, 10
# workspace offset: (constant, prefix, table index, function table, name table symbol, evidence)
TABLES = {
    0x0E0A: ("WS_RootFnTable", "RootFn_", 0x100, 0xEAFA6E, "WidgetName_InitPtrTable",
             "InitializeRoot: RegObjTabl 0x1600001, FunctionProc, 0x160, 0xeafa6e, 0x100"),
    0x0E88: ("WS_HamaFnTable", "HamaFn_", 0x109, 0xE1F0EC, "Hama_ModeParam_Table",
             "InitializeHama: RegObjTablHama 0x1600001, FunctionProc, 0x4b, 0xe1f0ec, 0x109"),
}
EVIDENCE_TEXT = [  # (file, text) that must still be in the main-CPU sources
    ("v10/maincpu/display/graphics_text_vga.s", "RegObjTabl 0x1600001, FunctionProc, 0x160, 0xeafa6e, 0x100"),
    ("v10/maincpu/display/graphics_text_vga.s", "RegObjTabl 0x1600001, FunctionProc, 0x160, WidgetName_InitPtrTable, 0x400"),
    ("v10/maincpu/factory_test/test_init.s", "RegObjTablHama 0x1600001, FunctionProc, 0x4b, 0xe1f0ec, 0x109"),
    ("v10/maincpu/factory_test/test_init.s", "RegObjTablHama 0x1600001, FunctionProc, 0x4b, Hama_ModeParam_Table, 0x409"),
    ("v10/maincpu/ui/ui_widget_defs.s", "call InitializeHama"),
]
FILES = ("hd-ae5000_v2_06i.s", "hdae5000_hd_driver.s", "hdae5000_filesystem.s",
         "hdae5000_ui_display.s", "hdae5000_utilities.s")
NUM = r"(0x[0-9a-fA-F]+|\d+)"
T_LOAD = re.compile(r"^(?P<pre>\s*(?:[\w.$]+:)?\s*ld\s+x(?P<dst>\w+)\s*,\s*\(\s*x(?P<base>\w+)\s*\+\s*)"
                    r"(?P<num>0x0e0a|0x0e88)(?P<post>\s*\).*)$", re.I)
O_LOAD = re.compile(r"^(?P<pre>\s*(?:[\w.$]+:)?\s*(?:ld|ld_sril)\s+x?\w+\s*,\s*\(\s*x(?P<base>\w+)\s*\+\s*)"
                    r"(?P<num>" + NUM + r")(?P<post>\s*\).*)$", re.I)


def val(s):
    return int(s, 16) if s.lower().startswith("0x") else int(s)


def main(apply):
    for rel, text in EVIDENCE_TEXT:
        if text not in open(os.path.join(ROOT, rel), encoding="latin-1").read():
            sys.exit("REFUSED: evidence line gone from %s: %r" % (rel, text))
    for off, (_, _, idx, _, _, _) in TABLES.items():
        assert idx * RECSZ + DATAPTR == off, hex(off)
    rom = open(ROM, "rb").read()
    lab = {}
    byname = {}
    for ln in subprocess.run([NM, "--defined-only", ELF], capture_output=True, text=True, check=True).stdout.split("\n"):
        p = ln.split()
        if len(p) == 3:
            lab.setdefault(int(p[0], 16), p[2])
            byname[p[2]] = int(p[0], 16)

    def u32(a):
        o = a - 0xE00000
        return int.from_bytes(rom[o:o + 4], "little")

    def cstr(a):
        o = a - 0xE00000
        return rom[o:rom.index(b"\x00", o)].decode("latin-1")

    src = {rel: open(os.path.join(hlm.HDAE, rel), encoding="latin-1").read().split("\n") for rel in hlm.FILES}
    used = collections.Counter()
    sites = []          # (rel, table line, off line, table ws offset, fn offset)
    for rel in FILES:
        L = src[rel]
        for i, ln in enumerate(L):
            code = ln.split(";")[0]
            m = T_LOAD.match(code)
            if not m:
                continue
            ws = val(m.group("num"))
            dst = m.group("dst").lower()
            for j in range(i + 1, min(i + 4, len(L))):
                mo = O_LOAD.match(L[j].split(";")[0])
                if mo and mo.group("base").lower() == dst:
                    off = val(mo.group("num"))
                    used[(ws, off)] += 1
                    sites.append((rel, i, j, ws, off))
                    break
            else:
                sites.append((rel, i, None, ws, None))
    names = {}
    print("%-6s %-6s %5s %-9s %-22s %-22s %s" % ("table", "off", "uses", "address", "firmware name", "v10 build label", ""))
    bad = 0
    for (ws, off), n in sorted(used.items()):
        const, pre, idx, ftab, ntab, ev = TABLES[ws]
        fn = u32(ftab + off)
        nm = cstr(u32(byname[ntab] + off))
        if not re.match(r"^[A-Za-z_]\w*$", nm):
            sys.exit("REFUSED: name %r at %s+0x%X is not an identifier" % (nm, ntab, off))
        bl = lab.get(fn, "?")
        note = "" if bl == nm else "<- the v10 build calls it %s" % bl
        print("0x%04X 0x%03X %5d 0x%06X %-22s %-22s %s" % (ws, off, n, fn, nm, bl, note))
        names[(ws, off)] = (pre + nm, fn, nm, bl)
        if fn < 0xE00000:
            bad += 1
    if bad:
        sys.exit("REFUSED: a function pointer outside the program ROM")
    if len({v[0] for v in names.values()}) != len(names):
        sys.exit("REFUSED: two offsets share a name")
    orphans = [s for s in sites if s[2] is None]
    print("sites %d, of which the table pointer is loaded with no call offset after it: %d"
          % (len(sites), len(orphans)))
    for rel, i, j, ws, off in orphans:
        print("   %s:%d %s" % (rel, i + 1, src[rel][i].strip()))
    if not apply:
        return
    for rel, i, j, ws, off in sites:
        L = src[rel]
        code, sep, com = L[i].partition(";")
        m = T_LOAD.match(code)
        L[i] = m.group("pre") + TABLES[ws][0] + m.group("post") + sep + com
        if j is None:
            continue
        code, sep, com = L[j].partition(";")
        mo = O_LOAD.match(code)
        L[j] = mo.group("pre") + names[(ws, off)][0] + mo.group("post") + sep + com
    L = src["hd-ae5000_v2_06i.s"]
    at = max(i for i, ln in enumerate(L) if ln.startswith("\t.equ HDAE5000_RAM_"))
    block = ["",
             "; ----------------------------------------------------------------------------",
             "; The main CPU's function tables, as the HD-AE5000 reaches them: workspace",
             "; (= object table 0x027ED2, 14-byte records {id, proc, count, data}) + 0x0E0A",
             "; is the data pointer of table 0x100, + 0x0E88 that of table 0x109.  The",
             "; constant names are the firmware's own, read from the name table the main",
             "; CPU registers beside each function table (0x400 / 0x409); generated by",
             "; scripts/converters/hdae5000_symbolize_fn_tables.py, which checks each",
             "; against original_ROMs/kn5000_v10_program.rom.",
             "; ----------------------------------------------------------------------------"]
    for ws, (const, pre, idx, ftab, ntab, ev) in sorted(TABLES.items()):
        block.append("\t.equ %s, 0x%04x\t; 14 * 0x%03x + 10: table 0x%03X = 0x%06X (%s)"
                     % (const, ws, idx, idx, ftab, ev))
    for (ws, off), (const, fn, nm, bl) in sorted(names.items()):
        extra = "" if bl == nm else "; v10 build label %s" % bl
        block.append("\t.equ %s, 0x%04x\t; -> 0x%06X (index %d)%s" % (const, off, fn, off // 4, extra))
    L[at + 1:at + 1] = block
    for rel, L in src.items():
        open(os.path.join(hlm.HDAE, rel), "w", encoding="latin-1").write("\n".join(L))
    hlm.build_map()
    print("applied; relinked mirror byte-identical")


if __name__ == "__main__":
    main("--apply" in sys.argv[1:])
