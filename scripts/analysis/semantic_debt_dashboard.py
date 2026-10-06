#!/usr/bin/env python3
"""semantic_debt_dashboard.py -- how much semantic debt that the byte gate and the data census
cannot see is left in each source tree, at a git revision?

QUESTION THIS ANSWERS
  The goal is a *fully semantic* disassembly. `data_range_census.py` grades bytes
  (CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER) but cannot see several kinds of debt that live in
  the TEXT of the sources. This script counts them per tree, reading git blobs (never the work
  tree or the build), so it is safe to run while a build is in progress and can be run at any
  past revision to draw a trend.

COLUMNS (each is a count of source lines or tokens; lower is better)
  numbr    branch/call operands that are numbers, not labels (`jr z, 17`, `call 0xe12345`).
           Same regex as technics-docs tools/branch_operand_counts.py.
  addrlbl  label DEFINITIONS whose name is an address placeholder: `LABEL_E04FB9:`,
           `sub_E04FB9:`, `loc_...`, `Unknown_...`, `Unk_...`, `Data_E04FB9:`, `Label_...`,
           i.e. a name that says "I am at this address" rather than what the thing is.
           Positional sub-labels of a named parent (`Foo_0x32D`, `Foo_Loop`) are NOT counted.
  numaddr  NON-branch instruction operands that are a numeric address inside the tree's OWN
           ROM (maincpu 0xE00000-0xFFFFFF, table data 0x800000-0x9FFFFF, HD-AE5000
           0x280000-0x2FFFFF, prom_a 0xF80000-0xFFFFFF, prom_b 0xF00000-0xF7FFFF, prom_c
           0xF80000-0xFFFFFF; trees with no ROM range here count 0).  Until 2026-10-02 this
           counted any value 0x800000..0xFFFFFF, which in v10 was mostly NOT addresses --
           packed (group << 16 | index) parameters such as `ld xwa, 0xb8001b`, the flash
           unlock address 0x815554 = 0x800000 + 0x5555*4 -- or other ROMs' addresses:
           `lda xix, 0xeec044`, `ld xiy, 16165950`, `lda_24 xix, (0xfea84f)` -- data references
           the branch metric above does not count (found by the 2026-10-02 review of Wave 2).
           ROM-range only, so RAM/SFR addresses and small constants are never counted; on wsa1
           and maincpu trees every hit is a cross-reference that should be a label.
  numevt   instruction operands that are a numeric firmware EVENT CODE / class id
           (0x01000000 <= value < 0x02000000: `cp xbc, 0x1e10000`, `ld xbc, 0x1c00001`).
           CLAUDE.md "Event Code Freshness" wants these spelled as EVT_* / class constants.
           On 2026-10-02 these were 9,230 of the 9,909 "big" operands in v10, so they are
           counted apart from numaddr rather than inflating it.
  numdata  numeric addresses inside the tree's own ROM in DATA: values on `.long` / `.4byte`
           lines (`.long 0x00EB2AAE` in a pointer table) and absolute address constants
           written `.set` (`.set BmpFile_i18_bmp, 0xeb2a16`; a hand-written `.equ` names a
           hardware constant and is not counted).  numaddr above sees instruction operands only;
           this column was added on 2026-10-02, when v10 held 1,028 such `.long` values and
           600 such constants (notes/data-pointer-symbolization-2026-10-02/).
  numfar   numeric FAR POINTERS into the tree's own ROM that the operand columns cannot see,
           because each half is below the ROM range: adjacent `pushw HI` / `pushw LO` lines
           (HI <= 0xff; the C compiler's far-pointer argument, `pushw 0xe4 / pushw 0x5126` =
           0xe45126), plus numeric address arguments of the NAKA registration macros
           (`RegTitle 0x3, 0xe5, 0xac98, ...`, `RegObjTabl ..., 0xe55210, ...`).  The assembler
           spells them `Sym@hi16` / `Sym@lo16` since TOOLCHAIN_VERSION UPDATE 20 (2026-10-02).
  posalias positional alias DEFINITIONS, `.set Base_0x1C1A, Base + 7194`: a second name that says
           only where it is (scripts/converters/split_blobs_at_far_pointers.py retires those
           that land on a string, a table or a label).
  bytecmt  `.byte` lines whose comment carries an instruction reading (`; ld a, (xwa)`,
           `; MAME: ...`, WSA1's `; F80F3E  d1 34 21 3e 02 00   or (0x2134),0x0002`) -- code still
           held as bytes. An upper bound: some are data annotated with a decode on purpose.
           (The WSA1 form was not counted before 2026-10-03.)
  field    `field_XXXX` / `unk_XXXX` / `pad_XXXX` member names in C sources (*.c, *.h):
           structures that compile byte-exact but whose members have no meaning yet.
  todo     comment markers that admit a gap: TODO, FIXME, "unknown", "purpose unknown", "???".

USAGE
  python3 scripts/analysis/semantic_debt_dashboard.py [REV] [--trees v10,v9,...] [--csv]
  REV defaults to HEAD. Example trend: run at 3958235e (before Wave 2), 5fc8d5bd (after).
"""
import argparse
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."

TREES = {
    "v10": "v10/maincpu", "v9": "v9/maincpu", "v7": "v7/maincpu",
    "v142": "v142/subcpu", "subboot": "subcpu/boot", "tabledata": "table_data",
    "customdata": "custom_data", "hdae5000": "hdae5000",
    "prom_a": "wsa1/prom_a", "prom_b": "wsa1/prom_b", "prom_c": "wsa1/prom_c",
    "prom_d": "wsa1/prom_d",
}

NUMBR = re.compile(rb'^\s*(\S+:)?\s*(jr|jrl|calr|call|jp|djnz)\s+([a-z]+,\s*)?(-?[0-9]+|0x[0-9a-fA-F]+)\s*(;.*)?$', re.M)
ADDRLBL = re.compile(rb'^(?:LABEL|Label|label|sub|SUB|loc|LOC|Unknown|UNKNOWN|Unk|UNK|unk|Data|DATA|data|byte|word|off|Sub|Loc)_(?:0x)?[0-9A-Fa-f]{4,8}:', re.M)
BYTECMT = re.compile(rb'^\s*(\S+:)?\s*\.byte\b[^;\n]*;\s*(?:MAME:|unidasm:|=\s*|[0-9A-F]{6}\s+[0-9a-f]{2}(?: [0-9a-f]{2})*\s{2,})?\s*(ld|lda|ldw|ldb|push|pop|call|calr|jp|jr|jrl|ret|reti|add|sub|and|or|xor|cp|inc|dec|bit|set|res|tset|ex|mul|div|sll|srl|sla|sra|rlc|rrc|rl|rr|ldir|lddr|ldi|ldd|swi|ei|nop|halt|link|unlk|djnz|scc|neg|cpl|extz|exts|mirr|paa|incf|decf|ldf|ldc|ldx)\b', re.M | re.I)
NUMADDR = re.compile(rb'^\s*(?:\S+:)?\s*(?!jr\b|jrl\b|calr\b|call\b|jp\b|djnz\b|\.)([a-z_][a-z0-9_]*)\s+([^;\n]*)', re.M)
LIT = re.compile(rb'(?<![\w.$])(0x[0-9a-fA-F]+|\d{7,})(?![\w.$])')
COLOUR_CALL = re.compile(rb'\bcall\s+(DrawString|DrawStringCentered|DrawStringLeftJustify|'
                         rb'DrawStringRightJustify|DrawStringAlignment|DrawStringReverse)\b')
PUSHW = re.compile(rb'^\s*(?:[A-Za-z_.$][\w.$]*:)?\s*pushw\s+(0x[0-9a-fA-F]+|\d+)\s*(?:;.*)?$')
# Calls whose stacked words are VALUES, so a `pushw <=0xff / pushw w` pair before them is not a far pointer
# (2026-10-03; an earlier pass had labelled six such "targets" mid-table and mid-routine in WSA1 prom_a):
#   Dev7E_WriteByte (value, ATA command-block register); T_[Pending]EventQueue_AppendStackArgs (four
#   stacked words = one 0x2C00/0x2E00 queue record); T_Gfx_EraseRect (four coordinates, prom_b's header);
#   TuneScale_AdjustUserKey (a key pair, 0xFF = no key); sub_FC5CDA ((0xFF, 0/1, 7/8) -- 0x00FF000x would
#   land inside sub_FEFFF3); ByteField_AddOrSub_Clamped (mask, high bound, low bound, its prom_c header).
#   KN5000: SeGfx_DrawLine / SeMenu_ClearRect (were SeMenu_ApplyPartEdit_AltStore_Helper/_Helper3) store their
#   four words at 1740-1746 (a rectangle) for SeGfx_StaticOp00/1B_FromBuf.
# Each callee is listed under every name it has had, newest first, so that a run at an older rev still matches.
# A rename that is not added here silently turns the callee's value pairs back into numfar debt (it happened with
# the 2026-10-06 naming waves); main() therefore warns when no name of a callee is defined in its measured tree.
#   The window also follows one unconditional `jr` (sub_FC5CDA's calls are jumped to); so does the
#   DrawString colour check (drawbar_panel_ui's PsMixer_CtlTypeProc5/6 jump to their DrawStringReverse).
VALUE_ARG_CALLEES = {   # tree -> callees, each a tuple of the names it has had
    "prom_a": [("Dev7E_WriteByte",), ("TuneScale_AdjustUserKey",), ("NoteRouting_QueueChange", "sub_FC5CDA")],
    "prom_b": [("T_PendingEventQueue_AppendStackArgs",), ("T_EventQueue_AppendStackArgs",), ("T_Gfx_EraseRect",)],
    "prom_c": [("ByteField_AddOrSub_Clamped",)],
    "v10": [("SeGfx_DrawLine", "SeMenu_ApplyPartEdit_AltStore_Helper"),
            ("SeMenu_ClearRect", "SeMenu_ApplyPartEdit_AltStore_Helper3")],
}
VALUE_ARG_CALL = re.compile(rb'\b(?:call|calr)\s+(%s)\b' % "|".join(
    n for cs in VALUE_ARG_CALLEES.values() for c in cs for n in c).encode())
JR_ALWAYS = re.compile(rb'^\s*jr\s+([A-Za-z_.$][\w.$]*)\s*(?:;.*)?$')
LABEL_DEF = re.compile(rb'^([A-Za-z_.$][\w.$]*):')
REGMAC = re.compile(rb'^\s+(RegObjTable|RegObjTabl|RegModeHiLo|RegTitleHiLo|RegMode|RegTitle|'
                    rb'RegObjTableHama|RegObjTablHama|RegTitleHama)\s+([^;\n]*)', re.M)
REG_ADDR_ARGS = {b"RegObjTable": (1, 2, 3), b"RegObjTabl": (1, 3), b"RegObjTableHama": (1, 2, 3),
                 b"RegObjTablHama": (1, 3), b"RegTitleHama": (1,), b"RegMode": (1,),
                 b"RegTitle": (1,), b"RegModeHiLo": (1,), b"RegTitleHiLo": (1,)}
NUMLIT = re.compile(rb'^(0x[0-9a-fA-F]+|\d+)$')
DATALONG = re.compile(rb'^[ \t]*(?:[A-Za-z_.$][\w.$]*:)?[ \t]*\.(?:long|4byte)[ \t]+([^;\n]*)', re.M)
# `.set` only: the conversion emitted its address constants as `.set NAME, 0xADDR`; a hand-written
# `.equ` (TABLE_DATA_ROM__BASE_ADDR, TD_FLASH_BASE, a flash command word that merely falls in the
# range) names a hardware constant and is not debt.
ABSSET = re.compile(rb'^[ \t]*\.set[ \t]+[A-Za-z_]\w*[ \t]*,[ \t]*(0x[0-9a-fA-F]+)[ \t]*(?:;.*)?$', re.M)
POSALIAS = re.compile(rb'^\s*\.(?:set|equ)\s+[A-Za-z_][\w.$]*_0x[0-9A-Fa-f]+\s*,\s*[A-Za-z_][\w.$]*\s*\+', re.M)
FIELD = re.compile(rb'\b(?:field|unk|unknown|pad)_(?:0x)?[0-9A-Fa-f]{2,6}\b')
TODO = re.compile(rb'(?:;|//|/\*|#).*?(?:\bTODO\b|\bFIXME\b|\bunknown\b|\bpurpose unknown\b|\?\?\?)', re.I)

SRC_EXT = (".s", ".S", ".inc")
C_EXT = (".c", ".h")


def blobs(rev, path):
    """Yield (name, bytes) for every source file under `path` at `rev`, via one cat-file process."""
    names = subprocess.run(["git", "-C", REPO, "ls-tree", "-r", "--name-only", rev, "--", path],
                           capture_output=True, text=True, check=True).stdout.split("\n")
    names = [n for n in names if n.endswith(SRC_EXT + C_EXT)]
    if not names:
        return
    p = subprocess.Popen(["git", "-C", REPO, "cat-file", "--batch"], stdin=subprocess.PIPE,
                         stdout=subprocess.PIPE)
    for n in names:
        p.stdin.write(("%s:%s\n" % (rev, n)).encode())
        p.stdin.flush()
        hdr = p.stdout.readline().split()
        size = int(hdr[2])
        data = p.stdout.read(size)
        p.stdout.read(1)
        yield n, data
    p.stdin.close()
    p.wait()


OWN_ROM = {"v10/maincpu": (0xE00000, 0xFFFFFF), "v9/maincpu": (0xE00000, 0xFFFFFF),
           "v7/maincpu": (0xE00000, 0xFFFFFF), "table_data": (0x800000, 0x9FFFFF),
           "hdae5000": (0x280000, 0x2FFFFF), "wsa1/prom_a": (0xF80000, 0xFFFFFF),
           "wsa1/prom_b": (0xF00000, 0xF7FFFF), "wsa1/prom_c": (0xF80000, 0xFFFFFF)}


# DrawString colour pairs by value (scripts/tools/unsymbolize_color_pairs.py)
COLOUR_VALUES = {0x00FF0008, 0x00FF00F2, 0x00FF00F5, 0x00FF00F7, 0x00FB00F5, 0x00FB00F7, 0x00F400F7}


def numfar(data, rng):
    lo, hi = rng
    n = 0
    lines = data.split(b"\n")
    labels = {m.group(1): k for k, x in enumerate(lines) for m in [LABEL_DEF.match(x)] if m}
    for i in range(len(lines) - 1):
        m1, m2 = PUSHW.match(lines[i]), PUSHW.match(lines[i + 1])
        if m1 and m2:
            near, ctx = lines[i + 2:i + 8], lines[i + 2:i + 14]   # 12: ByteField_AddOrSub_Clamped's 7 words
            for x in ctx[:3]:
                j = JR_ALWAYS.match(x)
                if j and j.group(1) in labels:
                    after = lines[labels[j.group(1)] + 1:labels[j.group(1)] + 7]
                    near, ctx = near + after, ctx + after
                    break
            if COLOUR_CALL.search(b" ".join(x.split(b";")[0] for x in near)):
                continue    # a DrawString* colour pair, not a far pointer (2026-10-03)
            if VALUE_ARG_CALL.search(b" ".join(x.split(b";")[0] for x in ctx)):
                continue    # value arguments of a callee listed above, not a far pointer (2026-10-03)
        if m1 and m2:
            h, l = int(m1.group(1), 0), int(m2.group(1), 0)
            if h <= 0xff and l <= 0xffff and lo <= (h << 16 | l) <= hi and \
                    (h << 16 | l) not in COLOUR_VALUES:     # a colour pair whose call is jumped to
                n += 1
    for m in REGMAC.finditer(data):
        args = [x.strip() for x in m.group(2).split(b",")]
        if m.group(1) in (b"RegMode", b"RegTitle", b"RegModeHiLo", b"RegTitleHiLo") and len(args) == 6:
            if NUMLIT.match(args[1]) and NUMLIT.match(args[2]) and \
                    lo <= (int(args[1], 0) << 16 | int(args[2], 0)) <= hi:
                n += 1
            continue
        for k in REG_ADDR_ARGS[m.group(1)]:
            if k < len(args) and NUMLIT.match(args[k]) and lo <= int(args[k], 0) <= hi:
                n += 1
    return n


def measure(rev, path):
    c = dict(numbr=0, numaddr=0, numdata=0, numevt=0, numfar=0, posalias=0, addrlbl=0, bytecmt=0, field=0,
             todo=0, files=0)
    c["labels"] = set()
    for name, data in blobs(rev, path):
        c["files"] += 1
        c["labels"].update(re.findall(rb'^([A-Za-z_.$][\w.$]*):', data, re.M))
        if name.endswith(C_EXT):
            c["field"] += len(set(FIELD.findall(data))) if False else len(FIELD.findall(data))
            c["todo"] += len(TODO.findall(data))
            continue
        c["numbr"] += len(NUMBR.findall(data))
        for m in NUMADDR.finditer(data):
            vals = [int(x, 0) for x in LIT.findall(m.group(2))]
            lo, hi = OWN_ROM.get(path, (1, 0))
            if any(lo <= v <= hi for v in vals):
                c["numaddr"] += 1
            if any(0x1000000 <= v < 0x2000000 for v in vals):
                c["numevt"] += 1
        lo, hi = OWN_ROM.get(path, (1, 0))
        for m in DATALONG.finditer(data):
            c["numdata"] += sum(1 for x in m.group(1).split(b",")
                                if NUMLIT.match(x.strip()) and lo <= int(x.strip(), 0) <= hi)
        c["numdata"] += sum(1 for m in ABSSET.finditer(data) if lo <= int(m.group(1), 0) <= hi)
        c["numfar"] += numfar(data, OWN_ROM.get(path, (1, 0)))
        c["posalias"] += len(POSALIAS.findall(data))
        c["addrlbl"] += len(ADDRLBL.findall(data))
        c["bytecmt"] += len(BYTECMT.findall(data))
        c["todo"] += len(TODO.findall(data))
    return c


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    ap.add_argument("rev", nargs="?", default="HEAD")
    ap.add_argument("--trees", default=",".join(TREES))
    ap.add_argument("--csv", action="store_true")
    a = ap.parse_args()
    short = subprocess.run(["git", "-C", REPO, "rev-parse", "--short", a.rev],
                           capture_output=True, text=True, check=True).stdout.strip()
    cols = ["files", "numbr", "numaddr", "numdata", "numevt", "numfar", "posalias", "addrlbl", "bytecmt",
            "field", "todo"]
    tot = dict.fromkeys(cols, 0)
    rows = []
    for t in a.trees.split(","):
        c = measure(a.rev, TREES[t])
        rows.append((t, c))
        for k in cols:
            tot[k] += c[k]
    for t, c in rows:
        for names in VALUE_ARG_CALLEES.get(t, []):
            if not any(n.encode() in c["labels"] for n in names):
                print("WARNING: %s defines none of %s -- a rename not added to VALUE_ARG_CALLEES (numfar is "
                      "overcounted)" % (t, "/".join(names)), file=sys.stderr)
    if a.csv:
        print("rev,tree," + ",".join(cols))
        for t, c in rows + [("TOTAL", tot)]:
            print("%s,%s,%s" % (short, t, ",".join(str(c[k]) for k in cols)))
        return
    print("semantic debt at %s (lower is better; see the docstring for each column)" % short)
    print("%-11s" % "tree" + "".join("%9s" % k for k in cols))
    for t, c in rows + [("TOTAL", tot)]:
        print("%-11s" % t + "".join("%9d" % c[k] for k in cols))


if __name__ == "__main__":
    sys.exit(main())
