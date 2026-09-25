#!/usr/bin/env python3
r"""WHO READS THE 29 "CHARACTER MAPPING TABLES", AND AS WHAT?  (maincpu v10/v9/v7)

QUESTION ANSWERED
    ui/charmap_dispatch_table.s holds 42 pointers to 128-byte byte maps in
    ui_widgets/widget_dispatch.s (0xEEC318-0xEED117 plus 0xEED118).  No ROM word
    and no instruction operand names the table's ROM address, because the table
    is never read from ROM: it is the LAST object of the second work-RAM
    initialisation image, which Boot_InitWorkRAM_ROMCopy2_Start copies to RAM,
    and the code reads the RAM copy:

      v10/v9  copy 0x95B bytes ROM 0xEEFA66 -> RAM 0xE35E   (table 0xEF0319 -> RAM 0xEC11)
      v7      copy 0x931 bytes ROM 0xEEFA66 -> RAM 0xE2C2   (table 0xEF02EF -> RAM 0xEB4B)

    Readers (v10 addresses; the same bytes exist in v9, and at 0xFEE35D/0xFEE3E2 in v7):
      SndParam_LoadTableConverge   0xFEEB2C  `lda xde,(0xec11); ld xde,(xde+hl);
                                            ld b,0; extz xbc; add xbc,xde; ld l,(xbc)`
      SndParam_LookupTableConverge 0xFEEBA9  `lda xbc,(0xec11); ld xbc,(xbc+hl);
                                            ... ld a,(xsp); add xwa,xbc; ld l,(xwa)`
    with hl = row * 0x18 + column offset (`muls hl,0x18`), so the table is a
    grid of 7 rows x 6 u32 (24-byte stride, 42 entries = 168 bytes) and each
    entry is a 128-byte map value -> value.  Column offsets come from two
    6-entry s16 switch tables in widget_dispatch.s:
      SndParamChan_SwitchOffsets (0xEED3C6) -> +0, +4, +8, +12, NoteMap_ConvergeMapA, NoteMap_ConvergeMapB
      SndParamOffs_SwitchOffsets (0xEED3D2) -> +16, +20, +8, +12, NoteMap_ConvergeMapA, NoteMap_ConvergeMapB
    The row is the byte SndParam_LookupAndDispatch (0xFEEA24) returns; 0xFF
    means "no map" and the input is passed through.  The reader does not bound
    the row; 7 rows is the table's own extent (it ends where the RAM image ends).

    --probe prints and asserts all of the above from the three ROM images, plus
    for every map: which grid cells hold it, how many of its 128 bytes are
    defined (not 0xFF), the index and value ranges, whether it is a permutation,
    and that within every row the maps in columns (0,1), (2,3) and (4,5) are
    mutual inverses on their defined entries.

    --apply rewrites, per version, the header comments above each map label,
    the block banner and the two switch tables' headers in
    <v>/maincpu/ui_widgets/widget_dispatch.s, and the header of
    <v>/maincpu/ui/charmap_dispatch_table.s.  It expects the labels already
    renamed by scripts/renaming/rename_sndparam_valuemaps.sed and refuses a
    file that already carries its headers.  Needs a built tree (llvm-nm).

RUN
    python3 scripts/generators/gen_sndparam_valuemap_headers.py --probe
    sed -i -f scripts/renaming/rename_sndparam_valuemaps.sed \
        v{10,9,7}/maincpu/ui_widgets/widget_dispatch.s v{10,9,7}/maincpu/ui/charmap_dispatch_table.s
    python3 scripts/generators/gen_sndparam_valuemap_headers.py --apply v10 v9 v7
    make gate
"""
import argparse
import collections
import os
import re
import struct
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
B = 0xE00000
ROWS, COLS = 7, 6
TAG = "; SndParam value map:"
SWITCH = {0xEED3C6: "SndParamChan_SwitchOffsets", 0xEED3D2: "SndParamOffs_SwitchOffsets"}


def rom(v):
    return open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()


def u32(d, a):
    return struct.unpack_from("<I", d, a - B)[0]


def elf_names(v):
    out = subprocess.run([NM, "--defined-only", os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % v)],
                         capture_output=True, text=True, check=True).stdout
    by = collections.defaultdict(list)
    for ln in out.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] == "t":
            by[int(p[0], 16)].append(p[2])
    return by


def locate(v):
    """-> dict: RAM copy, reader addresses, the grid's ROM address and pointers,
    and the two switch tables (reader address, jump base, targets)."""
    d = rom(v)
    copies = []
    for m in re.finditer(rb"\x42(...)\x00\x43(...)\x00\x41(...)\x00", d, re.S):
        de, hl, bc = (int.from_bytes(m.group(i), "little") for i in (1, 2, 3))
        if 0xEE0000 <= hl < 0xF00000 and de < 0x40000:
            copies.append((B + m.start(), de, hl, bc))
    readers = {}
    for kind, pat in (("load", rb"\xf1(..)\x32\xe3\x07\xe8\xec\x22"),
                      ("lookup", rb"\xf1(..)\x31\xe3\x07\xe4\xec\x21")):
        hits = [(B + m.start(), int.from_bytes(m.group(1), "little")) for m in re.finditer(pat, d, re.S)]
        assert len(hits) == 1, (v, kind, hits)
        readers[kind] = hits[0]
    ram = {r[1] for r in readers.values()}
    assert len(ram) == 1, ram
    ram = ram.pop()
    cp = [c for c in copies if c[1] <= ram < c[1] + c[3]]
    assert len(cp) == 1, (v, copies)
    at, dest, src, n = cp[0]
    table = src + (ram - dest)
    assert table + 4 * ROWS * COLS == src + n, "grid is not the last object of the RAM image"
    sw = {}
    for tab in SWITCH:
        hits = [m.start() for m in re.finditer(re.escape(b"\xf2" + tab.to_bytes(3, "little") + b"\x34"), d)]
        assert len(hits) == 1, (v, hex(tab), hits)
        k = hits[0] + 5
        assert d[k:k + 5] in (b"\xd3\x07\xf0\xe0\x20", b"\xd3\x07\xf0\xe8\x22"), d[k:k + 5].hex()
        assert d[k + 5] == 0xF2 and d[k + 9] == 0x34
        base = int.from_bytes(d[k + 6:k + 9], "little")
        offs = struct.unpack_from("<6h", d, tab - B)
        sw[tab] = {"at": B + hits[0], "base": base, "targets": [base + o for o in offs], "offs": offs}
    return {"copy_at": at, "dest": dest, "src": src, "len": n, "ram": ram, "table": table,
            "readers": readers, "grid": [u32(d, table + 4 * i) for i in range(ROWS * COLS)], "rom": d,
            "switch": sw}


def analyse(L):
    d, grid = L["rom"], L["grid"]
    cells = collections.defaultdict(list)
    for i, p in enumerate(grid):
        cells[p].append((i // COLS, i % COLS))
    info = {}
    for p, cl in cells.items():
        t = d[p - B:p - B + 128]
        dfn = [i for i in range(128) if t[i] != 0xFF]
        info[p] = {"cells": cl, "defined": len(dfn), "perm": sorted(t) == list(range(128)),
                   "ident": list(t) == list(range(128)),
                   "idx": (dfn[0], dfn[-1]) if dfn else None,
                   "val": (min(t[i] for i in dfn), max(t[i] for i in dfn)) if dfn else None,
                   "fixed": sum(1 for i in range(128) if t[i] == i)}
    inv = collections.defaultdict(set)
    for r in range(ROWS):
        for c in (0, 2, 4):
            a, b = grid[r * COLS + c], grid[r * COLS + c + 1]
            ta, tb = d[a - B:a - B + 128], d[b - B:b - B + 128]
            ok = all(tb[ta[i]] == i for i in range(128) if ta[i] != 0xFF) and \
                all(ta[tb[i]] == i for i in range(128) if tb[i] != 0xFF)
            assert ok, (r, c)
            inv[a].add(b)
            inv[b].add(a)
    return info, inv


def names_for(grid):
    """label per map address: grid position of its first appearance (row-major)."""
    out = {}
    for i, p in enumerate(grid):
        if p in out:
            continue
        r, c = i // COLS, i % COLS
        out[p] = "SndParam_ValueMap_Identity" if r == 0 else \
            "SndParam_ValueMap_R%dP%d%s" % (r, c // 2, "_Inv" if c % 2 else "")
    return out


def probe():
    Ls = {v: locate(v) for v in ("v10", "v9", "v7")}
    for v, L in Ls.items():
        print("%s: RAM image copy at 0x%06X: 0x%X bytes ROM 0x%06X -> RAM 0x%04X; grid ROM 0x%06X = RAM 0x%04X;"
              " readers %s" % (v, L["copy_at"], L["len"], L["src"], L["dest"], L["table"], L["ram"],
                              ", ".join("%s 0x%06X" % (k, a) for k, (a, _) in sorted(L["readers"].items()))))
        for tab, s in sorted(L["switch"].items()):
            print("    %s 0x%06X: read at 0x%06X, base 0x%06X, offsets %s -> %s" % (
                SWITCH[tab], tab, s["at"], s["base"], list(s["offs"]),
                " ".join("0x%06X" % t for t in s["targets"])))
    assert Ls["v9"]["grid"] == Ls["v10"]["grid"] == Ls["v7"]["grid"]
    for v in ("v9", "v7"):
        for p in set(Ls["v10"]["grid"]):
            assert Ls[v]["rom"][p - B:p - B + 128] == Ls["v10"]["rom"][p - B:p - B + 128], (v, hex(p))
    print("grid pointers and every map's 128 bytes identical in v10, v9, v7")
    info, inv = analyse(Ls["v10"])
    nm = names_for(Ls["v10"]["grid"])
    for p in sorted(info):
        i = info[p]
        print("0x%06X %-28s cells %-22s defined %3d idx %-9s val %-9s perm %-5s inverse %s" % (
            p, nm[p], " ".join("R%dC%d" % rc for rc in i["cells"]), i["defined"],
            "%d..%d" % i["idx"], "%d..%d" % i["val"], i["perm"],
            ",".join(nm[q] for q in sorted(inv[p]))))
    print("every row: columns (0,1), (2,3), (4,5) are mutual inverses on their defined entries")
    return 0


def reader_phrase(L, v):
    ld, lk = L["readers"]["load"][0], L["readers"]["lookup"][0]
    if v == "v7":
        return ("the `lda` at 0x%06X and the one at 0x%06X (v10's SndParam_LoadTableConverge" % (ld, lk),
                "and SndParam_LookupTableConverge; the v7 tree does not label them)")
    return ("SndParam_LoadTableConverge (`lda` at 0x%06X) and" % ld,
            "SndParam_LookupTableConverge (`lda` at 0x%06X)" % lk)


def map_header(p, i, inv, nm, L, v):
    cells = " ".join("R%dC%d" % rc for rc in i["cells"])
    if i["ident"]:
        shape = "Identity map: byte i holds i, all 128 defined."
    elif i["perm"]:
        shape = "Permutation of 0..127 with %d fixed points." % i["fixed"]
    else:
        shape = "%d of 128 bytes defined (0xFF = none): indices %d..%d -> values %d..%d." % (
            i["defined"], i["idx"][0], i["idx"][1], i["val"][0], i["val"][1])
    h = ["%s 128 x u8; SndParam_ValueMapGrid cell(s) %s (row, column)." % (TAG, cells),
         "; " + shape]
    others = sorted(nm[q] for q in inv[p] if q != p)
    if others:
        h.append("; Inverse (same row, paired column): %s." % ", ".join(others))
    if i["defined"] == 61 and i["val"] == (27, 87):
        h.append("; [INFERENCE] values 27..87 are exactly the General MIDI percussion key range.")
    if i["defined"] == 61 and i["idx"] == (27, 87):
        h.append("; [INFERENCE] indices 27..87 are exactly the General MIDI percussion key range.")
    a, b = reader_phrase(L, v)
    h += ["; Read through the grid's RAM copy by", "; " + a, "; " + b + "."]
    return h


BANNER_TITLE = "; Character Mapping Tables (EEC288-EED198)"
BANNER_FALSE = (
    "; 30 tables of 128 bytes each, mapping keyboard scan codes to character codes.",
    "; Used by the text input system for different keyboard layouts/input modes.",
    "; Sparse tables use 0xff for unmapped scan code positions.",
)


def banner(L, v):
    a, b = reader_phrase(L, v)
    return [
        "; Sound-parameter value maps (0xEEC318-0xEED117, and 0xEED118 further down)",
        "; =============================================================================",
        "; Formerly titled \"Character Mapping Tables\" and described as keyboard scan",
        "; code -> character code maps for text input; the readers show otherwise.",
        "; 29 maps of 128 bytes, 0xFF = no mapping.  Read by",
        "; %s" % a,
        "; %s, which map one byte value through" % b,
        "; the map a cell of SndParam_ValueMapGrid (ui/charmap_dispatch_table.s, 7 rows",
        "; x 6 u32) points at.  The grid is read from its RAM copy (0x%04X, made by" % L["ram"],
        "; Boot_InitWorkRAM_ROMCopy2_Start at 0x%06X), which is why no ROM word names it." % L["copy_at"],
        "; Regenerate with scripts/generators/gen_sndparam_valuemap_headers.py.",
    ]


def switch_header(tab, L, v, names):
    s = L["switch"][tab]
    nm = [sorted(n for n in names.get(t, []) if "_0x" not in n)[:1] if v != "v7" else [] for t in s["targets"]]
    nm = [x[0] if x else None for x in nm]
    rr = "wa" if tab == 0xEED3C6 else "de"
    who = "SndParam_LookupByChannel" if tab == 0xEED3C6 else "SndParam_OffsetHandler"
    cols = "+0, +4, +8, +12" if tab == 0xEED3C6 else "+16, +20, +8, +12"
    conv = "SndParam_LoadTableConverge" if tab == 0xEED3C6 else "SndParam_LookupTableConverge"
    h = ["; 6 x s16 switch offsets from 0x%06X, indexed by (selector 1..6) - 1:" % s["base"],
         "; `lda xix,(<this>)` at 0x%06X%s, `ld %s,(xix+%s)`," % (
             s["at"], (" (in %s)" % who) if v != "v7" else "", rr, rr),
         "; then `lda xix,(0x%06X); jp t,xix+%s`." % (s["base"], rr)]
    if all(nm):
        h.append("; Targets: %s, %s," % (nm[0], nm[1]))
        h.append("; %s, %s," % (nm[2], nm[3]))
        h.append("; %s, %s." % (nm[4], nm[5]))
    else:
        h.append("; Targets: %s" % ", ".join("0x%06X" % t for t in s["targets"][:3]) + ",")
        h.append("; %s (no labels in this tree)." % ", ".join("0x%06X" % t for t in s["targets"][3:]))
    h.append("; Entries 0-3 pick grid column %s of SndParam_ValueMapGrid for" % cols)
    h.append("; %s; entries 4-5 use NoteMap_ConvergeMapA / NoteMap_ConvergeMapB." % (
        conv if v != "v7" else "the converge code"))
    return h


def grid_header(L, v):
    a, b = reader_phrase(L, v)
    return [
        "; =============================================================================",
        "; SndParam_ValueMapGrid (formerly \"Character Map Mode Dispatch Table\"):",
        "; 7 rows x 6 u32 pointers to the 128-byte value maps in",
        "; ui_widgets/widget_dispatch.s (SndParam_ValueMap_*).  Never read here in ROM:",
        "; it is the last object of the RAM image Boot_InitWorkRAM_ROMCopy2_Start",
        "; (0x%06X) copies, 0x%X bytes ROM 0x%06X -> RAM 0x%04X, so the grid lives" % (
            L["copy_at"], L["len"], L["src"], L["dest"]),
        "; at RAM 0x%04X (= 0x%04X + 0x%06X - 0x%06X) and is read there by" % (
            L["ram"], L["dest"], L["table"], L["src"]),
        "; %s" % a,
        "; %s:" % b,
        "; `lda xde,(0x%04x); ld xde,(xde+hl)` (xbc in the second) with" % L["ram"],
        "; hl = row * 0x18 (`muls hl,0x18`) + column offset 0/4/8/12/16/20, then",
        "; `ld l,(map + value)`.  The row is the byte SndParam_LookupAndDispatch",
        "; returns (0xFF: no map, the value passes through; the row is not",
        "; bounds-checked, 7 rows is the grid's extent, which ends where the RAM image",
        "; ends).  Column offsets come from SndParamChan_SwitchOffsets (+0,+4,+8,+12)",
        "; and SndParamOffs_SwitchOffsets (+16,+20,+8,+12), indexed by the caller's",
        "; selector 1..6; selectors 5 and 6 use NoteMap_ConvergeMapA/B instead.",
        "; In every row the maps in columns 0/1, 2/3 and 4/5 are mutual inverses on",
        "; their defined entries.  Row 0 is the identity map throughout.",
        "; Pinned by scripts/generators/gen_sndparam_valuemap_headers.py --probe",
        "; (v10, v9 and v7: same pointers, same map bytes).",
        "; Extracted from kn5000_v10_program.s",
        "; =============================================================================",
    ]


def apply_widget(v, L, info, inv, nm, names):
    path = os.path.join(ROOT, v, "maincpu/ui_widgets/widget_dispatch.s")
    lines = open(path, "rb").read().decode("latin-1").split("\n")
    if any(l.startswith(TAG) for l in lines):
        sys.exit("%s already carries the value-map headers" % path)
    bylabel = {n: p for p, n in nm.items()}
    swlabel = {n: t for t, n in SWITCH.items()}
    out, maps, sws, ban = [], 0, 0, 0
    k = 0
    while k < len(lines):
        ln = lines[k]
        if ln == BANNER_TITLE:
            # title, rule, then the three lines the readers prove false; the
            # two true lines after them are kept
            assert lines[k + 1].startswith("; ====") and tuple(lines[k + 2:k + 5]) == BANNER_FALSE, lines[k:k + 6]
            out.extend(banner(L, v))
            k += 5
            ban += 1
            continue
        m = re.match(r"^([A-Za-z_]\w*):", ln)
        if m and (m.group(1) in bylabel or m.group(1) in swlabel):
            while out and out[-1].startswith(";") and not out[-1].startswith("; ===="):
                out.pop()
            if m.group(1) in bylabel:
                p = bylabel[m.group(1)]
                out.extend(map_header(p, info[p], inv, nm, L, v))
                maps += 1
            else:
                out.extend(switch_header(swlabel[m.group(1)], L, v, names))
                sws += 1
            out.append(ln)
            if m.group(1) == "SndParam_ValueMap_R1P2_Inv":
                out.append("; Legacy name kept: shared/positional_labels.s derives the")
                out.append("; CharMap_FullPermutation_0xNN names from it.")
                out.append("\t.set CharMap_FullPermutation, SndParam_ValueMap_R1P2_Inv")
            k += 1
            continue
        out.append(ln)
        k += 1
    assert maps == len(nm), (maps, len(nm))
    assert sws == 2
    open(path, "wb").write("\n".join(out).encode("latin-1"))
    print("%s: banner %d, %d map headers, %d switch headers" % (path, ban, maps, sws))


def apply_grid(v, L):
    path = os.path.join(ROOT, v, "maincpu/ui/charmap_dispatch_table.s")
    lines = open(path, "rb").read().decode("latin-1").split("\n")
    at = lines.index("SndParam_ValueMapGrid:")
    body = [l for l in lines[at + 1:] if l.startswith("\t.long")]
    assert len(body) == ROWS * COLS, len(body)
    rest = lines[at + 1 + ROWS * COLS:]
    out = grid_header(L, v) + ["SndParam_ValueMapGrid:"]
    for r in range(ROWS):
        out.append("; row %d%s" % (r, " (identity)" if r == 0 else ""))
        out.extend(body[r * COLS:(r + 1) * COLS])
    out.extend(rest)
    open(path, "wb").write("\n".join(out).encode("latin-1"))
    print("%s: header + %d row comments" % (path, ROWS))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--probe", action="store_true")
    ap.add_argument("--apply", nargs="+")
    a = ap.parse_args()
    if not a.apply:
        return probe()
    for v in a.apply:
        L = locate(v)
        info, inv = analyse(L)
        nm = names_for(L["grid"])
        apply_widget(v, L, info, inv, nm, elf_names(v))
        apply_grid(v, L)
    return 0


if __name__ == "__main__":
    sys.exit(main())
