#!/usr/bin/env python3
r"""gen_hdae5000_rodata.py -- the HD-AE5000 program's .rodata, object by object.

QUESTION ANSWERED / JOB IT DOES
-------------------------------
0x2E1C82-0x2E3703 holds the read-only data of the compiled C program: each
function's string literals, `switch` offset tables (typed earlier by
scripts/converters/hdae5000_switch_tables.py), string-pointer tables and text
templates, then the button bitmap of HDAE5000_BitmapButt01 and its palette.
Earlier passes labelled it in six coarse blocks named by guess
(HDAE5000_Config_Strings, _Test_Strings, _Dir_Strings, _Char_Tables,
_Path_Strings, _UI_Icons) and typed the bytes as text, so pointer tables read
as `.ascii "("` / `.byte 0x1e` / `.asciz "."`.

This script rebuilds the block from the ROM, one object per address the code
names:
  * READERS: every code line whose operand holds an address in the block --
    `lda xREG,(0x2e....:24)`, `ld xREG,0x002e....`, `ld REG,(0x2e....)`,
    `add xwa,0x002e....`, and the `pushw 0x002e / pushw 0x....` pair that pushes
    a 32-bit pointer as two halves -- with the routine that contains it.
  * POINTER TABLES: an object whose bytes are consecutive little-endian longs
    that all point at strings inside the block (e.g. {"---","NO ","YES"} read
    by HDAE5000_TypeSel_ShowSaveFlags as `(0x2E2922 + 4*flag)`) becomes
    `.long <label>` rows; the strings they point at become objects too.
  * everything else is split into typed runs: `.asciz` text (TAB as \t), `.zero`
    runs, `.byte` for the rest.  An object nobody names keeps an address label
    and says so.
  * the switch tables already typed are copied through unchanged; the bitmap
    (42 x 15, 8 bpp, from BitmapButt01's EVT_ALLOC_* answers) and the 256-entry
    palette before it are written as rows.
Each object gets a label and a one-line note naming its readers.

With no argument the tool prints the object list and checks that its byte model
of the new text equals the ROM; --write rewrites hdae5000_data_tables.s and
re-links through scripts/analysis/hdae5000_line_map.py (refuses unless the
tree is byte-identical to the dump).  Then `make gate`.
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import hdae5000_line_map as hlm  # noqa: E402

B0 = 0x280000
LO, HI = 0x2E1C82, 0x2E3704
PAL, BMP, BMP_W, BMP_H = 0x2E3064, 0x2E3464, 42, 15
SRC = os.path.join(hlm.HDAE, "hdae5000_data_tables.s")
LABEL = re.compile(r"^([.A-Za-z_][\w.$]*):")
STRUCT = re.compile(r"_(Skip|Join|Loop|Sub|Return|Epilogue|Entry|Exit|Done|Fail|Read|Store|Copy)\d*$|"
                    r"_Ev[0-9A-F]{8}$|_Case\d+(_\d+)?$|_Default\d*$|_Msg\d+$|_SwitchBase\d*$|^\.L")


def fail(m):
    sys.exit("REFUSED: " + m)


def printable(c):
    return 0x20 <= c < 0x7F and c not in (0x22, 0x5C) or c == 0x09


def readers(rows):
    """{target: [(code addr, routine, form)]} for code references into the block"""
    out = collections.defaultdict(list)
    owner, hi = None, None
    for a, rel, n, t in rows:
        m = LABEL.match(t)
        if m:
            nm = m.group(1)
            if rel != "hdae5000_data_tables.s" and a < 0x29BAFC and not STRUCT.search(nm) and "__" not in nm:
                owner = nm
            t = t[m.end():]
        b = t.split(";")[0].strip()
        if not b or a >= 0x29BAFC or rel in ("hdae5000_data_tables.s", "hdae5000_init_data.s"):
            hi = None
            continue
        mm = re.match(r"pushw\s+0x([0-9a-fA-F]{4})$", b)
        if mm:
            v = int(mm.group(1), 16)
            if hi is not None:
                full = (hi << 16) | v
                if LO <= full < HI:
                    out[full].append((a, owner, "pushed"))
                hi = None
                continue
            if v == 0x2E:
                hi = v
                continue
        hi = None
        for form, rx in (("lda", r"^lda\s+x\w+,\s*\(0x([0-9a-fA-F]+):24\)"),
                         ("ld #", r"^ld\s+x\w+,\s*0x0*([0-9a-fA-F]+)$"),
                         ("ld (mem)", r"^ld\s+x?\w+,\s*\(0x([0-9a-fA-F]+)(:24)?\)"),
                         ("add #", r"^add\s+x\w+,\s*0x0*([0-9a-fA-F]+)$")):
            mm = re.match(form == "lda" and rx or rx, b)
            if mm:
                v = int(mm.group(1), 16)
                if LO <= v < HI:
                    out[v].append((a, owner, form))
    return out


def switch_tables(rows, lines):
    """(start, end, first_line, last_line) of the typed switch tables in the block"""
    tabs = []
    names = {}
    for a, rel, n, t in rows:
        if rel == "hdae5000_data_tables.s" and LO <= a < HI:
            m = LABEL.match(t)
            if m and m.group(1).endswith(("_CaseTable", "_CaseTable1", "_CaseTable2")) or \
               (m and re.search(r"_CaseTable\d*$", m.group(1))):
                names[a] = (n, m.group(1))
    for a, (n, name) in sorted(names.items()):
        # header comment block above the label, then `.short` rows below it
        first = n
        while first > 1 and lines[first - 2].startswith(";") and not lines[first - 2].startswith(";;"):
            first -= 1
        last = n
        while last < len(lines) and re.match(r"\s*\.short\b", lines[last]):
            last += 1
        count = last - n
        tabs.append((a, a + 2 * count, first, last, name))
    return tabs


def main(write):
    rows, rom = hlm.build_map()
    b = lambda a: rom[a - B0]
    u32 = lambda a: int.from_bytes(rom[a - B0:a - B0 + 4], "little")
    lines = open(SRC, encoding="latin-1").read().split("\n")
    rd = readers(rows)
    tabs = switch_tables(rows, lines)
    fixed = {s: (s, e, "switch", name) for s, e, fl, ll, name in tabs}
    fixed[PAL] = (PAL, BMP, "palette", None)
    fixed[BMP] = (BMP, BMP + BMP_W * BMP_H, "bitmap", None)

    def in_fixed(a):
        return any(s <= a < e for s, e, k, nm in fixed.values())

    starts = set(t for t in rd if not in_fixed(t))
    # pointer tables: an object whose longs all point at string starts in the block
    ptrtabs = {}
    changed = True
    while changed:
        changed = False
        for s in sorted(starts):
            if s in ptrtabs:
                continue
            k, tg = 0, []
            while True:
                a = s + 4 * k
                if a + 4 > HI or in_fixed(a) or (k and a in starts):
                    break
                v = u32(a)
                if not (LO <= v < HI) or in_fixed(v):
                    break
                # a pointer into the block (byte 3 = 0x00, byte 2 = 0x2E) at an object
                # boundary: preceded by a NUL, or an address the code already names
                if not (b(v - 1) == 0 or v in starts) or b(v) == 0:
                    break
                tg.append(v)
                k += 1
            if k >= 2 or (k == 1 and (tg[0] in starts or tg[0] == s + 4)):
                ptrtabs[s] = tg
                for v in tg:
                    if v not in starts:
                        starts.add(v)
                        changed = True
    for s in fixed:
        starts.add(s)
    # a string object ends at its NUL (+ zero padding); text after that, up to the
    # next named object, is an object of its own (with no reader)
    extra = set()
    srt = sorted(starts)
    for i, s in enumerate(srt):
        e = srt[i + 1] if i + 1 < len(srt) else HI
        if s in fixed or s in ptrtabs or not printable(b(s)) or is_objids(rom, s, e) or s in OVERRIDE:
            continue
        a = s
        while a < e:
            while a < e and b(a) != 0:
                a += 1
            while a < e and b(a) == 0:
                a += 1
            if a < e:
                extra.add(a)
                if not printable(b(a)):
                    break
    starts |= extra
    starts = sorted(starts)
    ends = {s: (starts[i + 1] if i + 1 < len(starts) else HI) for i, s in enumerate(starts)}
    # the first object must start at LO (the block's first bytes are read: "V2.06i")
    if starts[0] != LO:
        fail("first object 0x%06X is not the block start" % starts[0])
    return rows, rom, lines, rd, tabs, fixed, ptrtabs, starts, ends


def is_objids(rom, s, e):
    """the bytes [s, e) are UI object ids: longs 0x007FNNNN"""
    if e <= s or (e - s) % 4:
        return False
    return all(int.from_bytes(rom[a - B0:a - B0 + 4], "little") >> 16 == 0x007F for a in range(s, e, 4))


# objects whose shape the generic rules cannot see; each note names the reader
OVERRIDE = {
    0x2E21AE: ("u16", 6, "u16 x 6, indexed by (0x22A032 * 3 + 0x22A02A) * 2 and compared"
                         " with the column (`cp iz,(xbc)`) by HDAE5000_AcHddNamingWindowProc:"
                         " the last column of each name-editor character page"),
    0x2E22AA: ("f32", 1, "IEEE single 100.0 (0x42C80000): the divisor HDAE5000_HardTest_HddIdRead"
                         " passes to HDAE5000_FloatDiv to turn the free space (units of 10,000"
                         " bytes) into MB for \"Fre Capa: %3.1f [MB]\""),
    0x2E2CD0: ("f32", 1, "IEEE single 100.0: a divisor of HDAE5000_SetupPage_BuildDriveInfo"
                         " (10,000-byte units -> MB)"),
    0x2E2CD4: ("f32", 1, "IEEE single 100.0: a divisor of HDAE5000_SetupPage_BuildDriveInfo"),
    0x2E2CD8: ("f32", 1, "IEEE single 100.0: a divisor of HDAE5000_SetupPage_BuildDriveInfo"),
    0x2E1C8A: ("bytes", 12, "a part-selection record template (HDAE5000_TypeSel_Init copies 12 bytes:"
                            " u16 mask, nine part flags, pad): mask 0, every flag 1 (\"NO \")"),
    0x2E1C96: ("bytes", 12, "a part-selection record template: mask 0, every flag 0 (\"---\")"),
    0x2E1E08: ("bytes", 12, "the delete-option record template: mask 0, every flag 0 (\"---\")"),
    0x2E1CA2: ("bytes", 10, "the 10-byte load-by-number block copied to 0x22AA58 by"
                            " HDAE5000_UiState_Reset (5 words, all 0)"),
}
FIXED_NAMES = {0x2E22C4: "HDAE5000_TitleInfo_Template",        # "WRITE PROTECTION :ON ..."
               0x2E2B84: "HDAE5000_DriveInfo_Template",        # "HD-TYPE : ... SOFTWARE RELEASE"
               0x2E23D8: "HDAE5000_PartNames_Text",            # "CURRENT PANEL\t PANEL MEMORY\t..."
               0x2E2458: "HDAE5000_PartNames_BlankText",
               0x2E24D8: "HDAE5000_PartName_Blank",
               0x2E22B4: "HDAE5000_Str_AllFilesPattern",       # "*.*"
               0x2E1CF4: "HDAE5000_FdList_RowsTemplate",       # "01:        \t02: ..."
               0x2E1E50: "HDAE5000_SelectList_Text",           # "01:SelectList\t02\t..."
               0x2E1C8A: "HDAE5000_TypeSel_TemplateAllNo", 0x2E1C96: "HDAE5000_TypeSel_TemplateBlank",
               0x2E1E08: "HDAE5000_DelOpt_TemplateBlank", 0x2E1CA2: "HDAE5000_Lbn_BlockTemplate",
               0x2E22AA: "HDAE5000_Float_100_HddIdRead", 0x2E2CD0: "HDAE5000_Float_100_DriveInfo",
               0x2E2CD4: "HDAE5000_Float_100_DriveInfo_2", 0x2E2CD8: "HDAE5000_Float_100_DriveInfo_3"}


def esc(bs):
    out = []
    for c in bs:
        out.append("\\t" if c == 9 else chr(c))
    return "".join(out)


def pieces(rom, s, e):
    """typed directives for the bytes [s, e)"""
    out, a = [], s
    while a < e:
        c = rom[a - B0]
        if c == 0:
            j = a
            while j < e and rom[j - B0] == 0:
                j += 1
            if j - a == 1 and a % 2 == 1 and out and out[-1][0].startswith("\t.asciz"):
                # a lone NUL after a string that brings the next object to an even address
                out.append(("\t.balign 2, 0x00                       ; word-align pad (proven: see convert_align_pads.py header)", 1))
            else:
                out.append(("\t.zero %d" % (j - a), j - a))
            a = j
        elif printable(c):
            j = a
            while j < e and printable(rom[j - B0]):
                j += 1
            if j < e and rom[j - B0] == 0:
                out.append(('\t.asciz "%s"' % esc(rom[a - B0:j - B0]), j - a + 1))
                a = j + 1
            else:
                out.append(('\t.ascii "%s"' % esc(rom[a - B0:j - B0]), j - a))
                a = j
        else:
            j = a
            while j < e and not (rom[j - B0] == 0 or printable(rom[j - B0])) and j - a < 16:
                j += 1
            out.append(("\t.byte " + ", ".join("0x%02x" % x for x in rom[a - B0:j - B0]), j - a))
            a = j
    return out


def words(bs):
    txt = bs.decode("latin-1")
    ws = re.findall(r"[A-Za-z0-9]+", txt)
    return ws


def sym(bs):
    """a label fragment for any byte string"""
    ws = words(bs)
    if ws:
        return "".join(w.capitalize() if not w.isupper() else w for w in ws)[:28]
    if not bs:
        return "Empty"
    if bs and all(c in (0x20, 0x09) for c in bs):
        return "Blank%d" % bs.count(0x20) + ("Tab" if 0x09 in bs else "")
    return "Chr" + "".join("%02X" % c for c in bs[:6])


def name_for(rom, s, e, kind, rd, used, ptrs=None):
    def uniq(base):
        n, k = base, 2
        while n in used:
            n = "%s_%d" % (base, k)
            k += 1
        used.add(n)
        return n
    rs = sorted({r[1] for r in rd.get(s, []) if r[1]})
    short = rs[0].replace("HDAE5000_", "") if rs else None
    if kind == "ptrtab" and any(v in PTRTABS for v in ptrs):
        return uniq("HDAE5000_TablePtrs_%s" % (short or "%06X" % s))
    if kind == "ptrtab":
        def first(v):
            z = rom.index(0, v - B0)
            return sym(rom[v - B0:z]) if z > v - B0 else "Ptrs"
        if len(ptrs) > 4:
            return uniq("HDAE5000_TextPtrs_%s_to_%s" % (first(ptrs[0]), first(ptrs[-1])))
        return uniq("HDAE5000_TextPtrs_" + "_".join(first(v) for v in ptrs)[:40])
    if is_objids(rom, s, e):
        return uniq("HDAE5000_%s_ObjIds" % short if short else "HDAE5000_ObjIds_%06X" % s)
    z = rom.index(0, s - B0) if 0 in rom[s - B0:e - B0] else e - B0
    bs = rom[s - B0:z]
    if all(printable(c) for c in bs) and (bs or s + 1 <= e):
        if re.search(rb"%[-+ #0-9.]*l?[sdiuxXcfeEgG]", bs):
            core = re.sub(r"[^A-Za-z0-9]+", "_", bs.decode("latin-1")).strip("_")
            base = "HDAE5000_Fmt_" + (core or "Pct")[:24]
        else:
            base = "HDAE5000_Str_" + sym(bs)
        if base in used and short:
            base = base + "_" + short
        return uniq(base)
    if is_objids(rom, s, e):
        return uniq("HDAE5000_%s_ObjIds" % short if short else "HDAE5000_ObjIds_%06X" % s)
    return uniq("HDAE5000_%s_Data" % short if short else "HDAE5000_Rodata_%06X" % s)


PTRTABS = {}


def build(rom, rd, tabs, fixed, ptrtabs, starts, ends, lines):
    PTRTABS.update(ptrtabs)
    uinames = {}
    for ln in lines:
        m = re.search(r'; \[ *(\d+)\] "([^"]*)"', ln)
        if m and "HdaeUiName_" in ln:
            uinames[int(m.group(1))] = m.group(2)
    used = set()
    out = []
    names = {}
    for s in starts:
        if s in fixed and fixed[s][2] == "switch":
            names[s] = fixed[s][3]
            continue
        if s == PAL:
            names[s] = "HDAE5000_Palette_Button01"
        elif s == BMP:
            names[s] = "HDAE5000_Bitmap_Button01"
        elif s in FIXED_NAMES:
            names[s] = FIXED_NAMES[s]
            used.add(names[s])
        elif s in ptrtabs:
            names[s] = name_for(rom, s, ends[s], "ptrtab", rd, used, ptrtabs[s])
        else:
            names[s] = name_for(rom, s, ends[s], "obj", rd, used)
    tab_lines = {s: (fl, ll) for s, e, fl, ll, name in tabs}
    model = bytearray()
    for s in starts:
        e = ends[s]
        if s in fixed and fixed[s][2] == "switch":
            fl, ll = tab_lines[s]
            out.extend(lines[fl - 1:ll])
            model += rom[s - B0:fixed[s][1] - B0]
            if fixed[s][1] < e:          # bytes after the table and before the next object
                gap = fixed[s][1]
                out.append("HDAE5000_Rodata_%06X:" % gap)
                out.append("\t; no code reference found (searched: lda/ld/add immediates, (mem) loads,"
                           " pushw 0x002e/lo pairs, .long pointers in this block)")
                for txt, n in pieces(rom, gap, e):
                    out.append(txt)
                model += rom[gap - B0:e - B0]
            continue
        rs = rd.get(s, [])
        who = sorted({(r[1] or "?").replace("HDAE5000_", "") for r in rs})
        forms = sorted({r[2] for r in rs})
        site = ("at 0x%06X" % min(r[0] for r in rs)) if rs else ""
        if s == PAL:
            out += [";",
                    "; HDAE5000_Palette_Button01 (0x2E3064, 1024 B): 256 RGBX entries, entry i =",
                    "; (i, i, i, 0) -- a grey ramp -- placed, as everywhere in this ROM's",
                    "; graphics bank, immediately before its bitmap (HDAE5000_Bitmap_Button01).",
                    "; No code in this ROM reads it; whether the main CPU does (at the bitmap",
                    "; pointer - 0x400) is not established.",
                    ";", "HDAE5000_Palette_Button01:"]
            for i in range(256):
                a = PAL + 4 * i
                if i % 4 == 0:
                    out.append("\t.byte " + ", ".join("0x%02x" % x for x in rom[a - B0:a - B0 + 16]))
            model += rom[PAL - B0:BMP - B0]
            continue
        if s == BMP:
            out += [";",
                    "; HDAE5000_Bitmap_Button01 (0x2E3464, 42 x 15 = 630 B, 8 bpp, one row per",
                    "; line): the image of UI object \"BitmapButt01\".  Its handler",
                    "; HDAE5000_BitmapButt01 (0x28B527) answers EVT_ALLOC_DATA_PTR 0x01E000A1 with",
                    "; this address, EVT_ALLOC_WIDTH 0x01E000A2 with 42 and EVT_ALLOC_HEIGHT",
                    "; 0x01E000A3 with 15 (the same protocol the main CPU's bitmap objects use).",
                    ";", "HDAE5000_Bitmap_Button01:"]
            for r in range(BMP_H):
                a = BMP + r * BMP_W
                out.append("\t.byte " + ", ".join("0x%02x" % x for x in rom[a - B0:a - B0 + BMP_W]))
            model += rom[BMP - B0:BMP - B0 + BMP_W * BMP_H]
            after = BMP + BMP_W * BMP_H
            if after < e:
                fail("bytes after the bitmap before the next object")
            continue
        owners = [t for t, v in ptrtabs.items() if s in v]
        if owners:
            t = owners[0]
            tw = sorted({(r[1] or "?").replace("HDAE5000_", "") for r in rd.get(t, [])})
            note = "\t; pointed at by entry %d of %s%s" % (ptrtabs[t].index(s), names[t],
                                               (", a table read by %s" % ", ".join(tw)) if tw else "")
            if who:
                note += "; also read by %s %s (%s operand)" % (", ".join(who), site, ", ".join(forms))
        elif who:
            note = "\t; read by %s %s (%s operand)" % (", ".join(who), site, ", ".join(forms))
        else:
            note = ("\t; no code reference found (searched: lda/ld/add immediates, (mem) loads,"
                    " pushw 0x002e/lo pairs, .long pointers in this block)")
        if s in ptrtabs:
            n = len(ptrtabs[s])
            out.append("%s:\t; 0x%06X, %d x .long -> string" % (names[s], s, n))
            out.append(note + "; %d string pointer%s, 4 bytes each, entry i at +4*i" % (n, "s" if n > 1 else ""))
            for v in ptrtabs[s]:
                out.append("\t.long\t%s" % names[v])
            model += rom[s - B0:s - B0 + 4 * n]
            rest = s + 4 * n
            for txt, k in pieces(rom, rest, e):
                out.append(txt)
            model += rom[rest - B0:e - B0]
            continue
        out.append("%s:\t; 0x%06X" % (names[s], s))
        if s in OVERRIDE:
            kind, cnt, desc = OVERRIDE[s]
            out.append(note)
            out.append("\t; " + desc)
            if kind == "u16":
                vals = [int.from_bytes(rom[s - B0 + 2 * i:s - B0 + 2 * i + 2], "little") for i in range(cnt)]
                out.append("\t.short " + ", ".join(str(v) for v in vals))
                rest = s + 2 * cnt
            elif kind == "bytes":
                out.append("\t.byte " + ", ".join("0x%02x" % x for x in rom[s - B0:s - B0 + cnt]))
                rest = s + cnt
            else:
                out.append("\t.long 0x%08x\t\t; 100.0f" % int.from_bytes(rom[s - B0:s - B0 + 4], "little"))
                rest = s + 4
            for txt, k in pieces(rom, rest, e):
                out.append(txt)
        elif is_objids(rom, s, e):
            out.append(note + "; UI object ids (0x007F0000 + index into"
                       " HDAE5000_UiObjectName_PtrTable), 4 bytes each")
            for a in range(s, e, 4):
                v = int.from_bytes(rom[a - B0:a - B0 + 4], "little")
                nm = uinames.get(v & 0xFFFF)
                out.append("\t.long 0x%08x\t\t; UI object %d%s" % (v, v & 0xFFFF, (' "%s"' % nm) if nm else ""))
        else:
            out.append(note)
            for txt, k in pieces(rom, s, e):
                out.append(txt)
        model += rom[s - B0:e - B0]
    if bytes(model) != rom[LO - B0:HI - B0]:
        k = next(i for i in range(min(len(model), HI - LO)) if model[i] != rom[LO - B0 + i])
        fail("byte model differs at 0x%06X" % (LO + k))
    return out, names


def run(write):
    rows, rom, lines, rd, tabs, fixed, ptrtabs, starts, ends = main(write)
    out, names = build(rom, rd, tabs, fixed, ptrtabs, starts, ends, lines)
    nread = sum(1 for s in starts if rd.get(s))
    print("objects %d (%d named by code, %d pointer tables with %d entries, %d switch tables kept)"
          % (len(starts), nread, len(ptrtabs), sum(len(v) for v in ptrtabs.values()), len(tabs)))
    unref = [s for s in starts if not rd.get(s) and s not in fixed
             and not any(s in v for v in ptrtabs.values())]
    print("objects with no reader: %d (%d B)" % (len(unref), sum(ends[s] - s for s in unref)))
    if not write:
        for s in starts:
            print("  %06X %5d %s" % (s, ends[s] - s, names[s]))
        return
    # the replaced line range: first line at LO .. last line below HI
    dl = [(a, n, t) for a, rel, n, t in rows if rel == "hdae5000_data_tables.s"]
    first = min(n for a, n, t in dl if a >= LO and LABEL.match(t))
    last = max(n for a, n, t in dl if a < HI)
    hdr = ["; ============================================================================",
           "; HD-AE5000 PROGRAM .RODATA, 0x2E1C82-0x2E3703 (the C program's read-only data)",
           "; Rebuilt object by object by scripts/generators/gen_hdae5000_rodata.py: every",
           "; object starts at an address the code names (lda / ld # / ld (mem) / add #",
           "; operands and pushw 0x002e/low pairs) or that a pointer table here points",
           "; at, and its note names the routines that read it.  String-pointer tables",
           "; are `.long <label>`; the compiled `switch` tables (their own headers) are",
           "; kept from scripts/converters/hdae5000_switch_tables.py.  This replaces six",
           "; coarse blocks named by guess (HDAE5000_Config_Strings, _Test_Strings,",
           "; _Dir_Strings, _Char_Tables, _Path_Strings, _UI_Icons) whose bytes were",
           "; typed as text throughout.",
           "; ============================================================================"]
    lines[first - 1:last] = hdr + out
    open(SRC, "w", encoding="latin-1").write("\n".join(lines))
    hlm.build_map()
    print("written; relinked mirror byte-identical")


if __name__ == "__main__":
    run("--write" in sys.argv[1:])
