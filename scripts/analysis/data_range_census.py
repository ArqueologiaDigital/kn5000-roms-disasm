#!/usr/bin/env python3
r"""data_range_census.py -- a per-range census of EVERY BYTE of all 12 gated images.

QUESTION ANSWERED
-----------------
"Now that every byte reproduces from real source, which bytes are CODE, which
are DATA WHOSE PURPOSE WE CAN STATE, which are DATA NOBODY HAS EXPLAINED, and
which are filler?"  Zero verbatim debt is a statement about `.incbin`, not about
understanding.  This tool measures the understanding.

Every byte of every image lands in exactly ONE bucket and the per-image totals
are RECONCILED against the dump size.  A run that does not add up is a hard
failure, not a warning -- an unreconciled census is this project's documented
failure mode.

BUCKETS
    CODE            instruction statements (and instruction-emitting macros)
    DATA-KNOWN-A    data whose documentation states what it represents AND
                    points at evidence (a reader, a record layout, a field
                    meaning, a findings file, a call site)
    DATA-KNOWN-B    data under a descriptive (non-address-derived) name with a
                    section header that says something about it, but without
                    the evidence citation grade A requires
    DATA-UNKNOWN    everything else: address-derived labels, bare `.byte` runs
                    with no explanatory header, and anything whose own header
                    admits it is not established
    FILLER          fill directives (.fill/.space/.zero/.org/.align) whose ROM
                    bytes are VERIFIED uniform and at least 16 bytes long

HOW THE MAP IS BUILT (and why it can be trusted)
    The same instrument as scripts/analysis/address_line_map.py, generalised to
    all twelve images: mirror each image's source tree, insert a synthetic label
    `__drc_<n>:` in front of every byte-emitting line, assemble and LINK the
    mirror with the real linker script, and read the marker addresses out of the
    ELF symbol table.  Byte [addr(marker n), addr(marker n+1)) is emitted by the
    source line marker n was written in front of.

    ★ THE MIRROR IS PROVEN INERT.  For every image the linked mirror is
      objcopy'd to a raw binary and asserted byte-identical to the original
      dump.  A label emits no bytes, so a still-matching ROM is the proof that
      the map describes THIS tree and not a perturbed variant of it.  If it does
      not match, the run aborts for that image rather than reporting numbers.

    ⚠ This is a map of the SOURCE'S OWN CLAIM.  It says which directive emits a
      byte, not whether that directive is the right one.  Data framed as code
      (the third kind of debt, notes/DEBT-INVENTORY-2026-09-02.md) counts here as
      CODE, and code framed as `.byte` counts as DATA.  The CODE-SUSPECT column
      is the only thing here that pushes back, and it is a flag, not a verdict.

RUN
    python3 scripts/analysis/data_range_census.py                 # all images
    python3 scripts/analysis/data_range_census.py --images v10,prom_d
    python3 scripts/analysis/data_range_census.py --markdown OUT.md
    python3 scripts/analysis/data_range_census.py --json OUT.json
    python3 scripts/analysis/data_range_census.py --selftest
    python3 scripts/analysis/data_range_census.py --sample 40     # FP-rate sample
"""
import argparse
import bisect
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
PROJECTS = os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado"))
LLVM = os.path.join(PROJECTS, "llvm-project", "build", "bin")
MC = os.path.join(LLVM, "llvm-mc")
LLD = os.path.join(LLVM, "ld.lld")
OBJCOPY = os.path.join(LLVM, "llvm-objcopy")
NM = os.path.join(LLVM, "llvm-nm")
MARK = "__drc_"
# How far above an object its banner may sit and still be credited to it.
ANCHOR_SLACK = 6

# ---------------------------------------------------------------- the 12 images
# `mirror` is the directory copied and marked; `root` and `incs` are relative to
# it.  `split` (v142 only) maps a linked-image offset to a ROM offset, because
# that image's ROM is two slices of the linked binary spliced by `dd`.
IMAGES = [
    dict(key="v10", title="KN5000 maincpu v10", mirror="v10/maincpu",
         root="kn5000_v10_program.s", ld="maincpu.ld", incs=[""],
         rom="original_ROMs/kn5000_v10_program.rom", base=0xE00000, size=2097152),
    dict(key="v9", title="KN5000 maincpu v9", mirror="v9/maincpu",
         root="kn5000_v9_program.s", ld="maincpu.ld", incs=[""],
         rom="original_ROMs/kn5000_v9_program.rom", base=0xE00000, size=2097152),
    dict(key="v7", title="KN5000 maincpu v7", mirror="v7/maincpu",
         root="kn5000_v7_program.s", ld="maincpu.ld", incs=[""],
         rom="original_ROMs/kn5000_v7_program.rom", base=0xE00000, size=2097152),
    dict(key="v142", title="KN5000 subcpu payload v1.42", mirror="v142/subcpu",
         root="kn5000_subprogram_v142.s", ld="subcpu.ld", incs=[""],
         rom="original_ROMs/kn5000_subprogram_v142.rom", base=0x0400, size=196608,
         split=(256, 60416)),
    dict(key="subboot", title="KN5000 subcpu boot IC30", mirror="subcpu/boot",
         root="kn5000_subcpu_boot.s", ld="subcpu_boot.ld", incs=[""],
         rom="original_ROMs/kn5000_subcpu_boot.ic30", base=0xFE0000, size=131072),
    dict(key="tabledata", title="KN5000 table data", mirror="table_data",
         root="kn5000_table_data.s", ld="table_data.ld", incs=[""],
         rom="original_ROMs/kn5000_table_data.rom", base=0x800000, size=2097152),
    dict(key="customdata", title="KN5000 custom data IC19", mirror="custom_data",
         root="kn5000_custom_data.s", ld="custom_data.ld", incs=[""],
         rom="original_ROMs/kn5000_custom_data.ic19", base=0x300000, size=1048576),
    dict(key="hdae5000", title="HD-AE5000 v2.06i", mirror="hdae5000",
         root="hd-ae5000_v2_06i.s", ld="hdae5000.ld", incs=[""],
         rom="original_ROMs/hd-ae5000_v2_06i.ic4", base=0x280000, size=524288),
    dict(key="prom_a", title="SX-WSA1R prom_a IC12", mirror="wsa1",
         root="prom_a/wsa1_prom_a.s", ld="prom_a/prom_a.ld", incs=["", "prom_a"],
         rom="wsa1/original_ROMs/wsa1_prom_a.ic12", base=0xF80000, size=524288),
    dict(key="prom_b", title="SX-WSA1R prom_b IC13", mirror="wsa1",
         root="prom_b/wsa1_prom_b.s", ld="prom_b/prom_b.ld", incs=["", "prom_b"],
         rom="wsa1/original_ROMs/wsa1_prom_b.ic13", base=0xF00000, size=524288),
    dict(key="prom_c", title="SX-WSA1R prom_c IC28", mirror="wsa1",
         root="prom_c/wsa1_prom_c.s", ld="prom_c/prom_c.ld", incs=["", "prom_c"],
         rom="wsa1/original_ROMs/wsa1_prom_c.ic28", base=0xF80000, size=524288),
    dict(key="prom_d", title="SX-WSA1R prom_d", mirror="wsa1",
         root="prom_d/wsa1_prom_d.s", ld="prom_d/prom_d.ld", incs=["", "prom_d"],
         rom="wsa1/original_ROMs/wsa1_prom_d.bin", base=0x000000, size=524288),
]
TOTAL_BYTES = 12386304          # sum of the twelve dumps; asserted in selftest

# ---------------------------------------------------------------- directives
DATA_DIRS = {".byte", ".short", ".word", ".hword", ".2byte", ".long", ".4byte",
             ".int", ".quad", ".8byte", ".ascii", ".asciz", ".string", ".incbin",
             ".single", ".float", ".double", ".sleb128", ".uleb128"}
FILL_DIRS = {".fill", ".space", ".skip", ".zero", ".org", ".align", ".p2align",
             ".balign", ".balignw", ".balignl"}
# Directives that emit nothing.  Anything not in the three sets above and not an
# instruction is treated as emitting nothing and asserted to do so by the map.
NOEMIT_DIRS = {".text", ".data", ".section", ".globl", ".global", ".local",
               ".set", ".equ", ".equiv", ".type", ".size", ".include", ".macro",
               ".endm", ".if", ".ifdef", ".ifndef", ".else", ".endif", ".rept",
               ".endr", ".irp", ".endif", ".file", ".line", ".loc", ".ident",
               ".weak", ".hidden", ".protected", ".comm", ".lcomm", ".purgem",
               ".altmacro", ".noaltmacro", ".err", ".error", ".warning",
               ".cfi_startproc", ".cfi_endproc", ".end", ".list", ".nolist"}

LABEL_RE = re.compile(r'^([A-Za-z_.$][\w.$@]*):')
NUMLABEL_RE = re.compile(r'^(\d+):')
CTRL_RE = re.compile(r'^(call|calr|jp|jr|jrl|djnz)\b', re.I)
IDENT_RE = re.compile(r'\b([A-Za-z_][\w.$]{2,})\b')

# Generic stems that carry no meaning once the hex address is stripped off.
GENERIC = {"data", "unk", "unknown", "blob", "byte", "bytes", "word", "words",
           "long", "tbl", "table", "tables", "arr", "array", "arrays", "region",
           "span", "chunk", "block", "blocks", "buf", "buffer", "pad", "padding",
           "fill", "filler", "gap", "slice", "rom", "rest", "misc", "body",
           "head", "tail", "extra", "residue", "remnant", "dat", "loc", "sub",
           "off", "seg", "lbl", "label", "code", "raw", "bin", "record",
           "records", "rec", "entry", "entries", "list", "lists", "item",
           "items", "value", "values", "vals", "struct", "structs", "pool",
           "part", "parts", "sect", "section", "sections", "tab", "img",
           "d", "b", "w", "l", "x"}
# Phrases whose presence in a header is an ADMISSION about the region itself.
# ⚠ KEPT NARROW ON PURPOSE.  An earlier version listed the bare word "unknown",
# and prom_b's font headers use `Unknown: -` as a TEMPLATE FIELD meaning "nothing
# is unknown here" -- so the best-documented data in the whole tree was being
# graded UNKNOWN by the presence of the word.  Template fields with an empty
# value are stripped by normalise_header() before this list is applied.
ADMISSIONS = ("not established", "purpose unclear", "purpose is unclear",
              "purpose not known", "unidentified", "todo:", "to do:",
              "extent is the reachability walk", "reachability walk's",
              "not analysed", "not analyzed", "no reader", "readers: none",
              "unexplained", "meaning unknown", "meaning is unknown",
              "not understood", "no known reader", "not yet identified",
              "not yet understood", "cannot be established", "no evidence",
              "purpose is unknown", "purpose unknown", "role unknown",
              "content unknown", "contents unknown", "nothing is known",
              "unknown:", "unknown -", "unknown =", "not known")

# ★ CODE-SHAPED LABEL NAMES.  A `.byte` run under `Sprintf_MainLoop_ReadNext`
# or `CharMap_ActivePreamb_Prologue` is not data with a known purpose; it is a
# routine somebody named and nobody disassembled.  These tokens are the ones a
# ROUTINE gets named after -- control flow and verbs -- not the ones a table
# gets named after.  ⚠ It is a HEURISTIC and is reported WITH ITS NULL: the same
# rate measured over the three pure-data images (table_data, custom_data,
# prom_d), where a hit can only be a false positive.
CODE_NAME_TOKENS = {
    "loop", "prologue", "epilogue", "dispatch", "handler", "isr", "retry",
    "fallthrough", "fallthru", "branch", "jump", "resume", "continue",
    "breakout", "entry", "exit", "return", "done", "skip", "next", "begin",
    "proc", "routine", "func", "subr", "mainloop", "case", "else", "then",
    "init", "initialize", "process", "compute", "calc", "apply", "check",
    "verify", "update", "refresh", "restore", "save", "send", "recv",
    "receive", "transmit", "parse", "convert", "scan", "clear", "reset",
    "toggle", "enable", "disable", "execute", "invoke", "wait", "poll",
    "advance", "rewind", "step", "abort", "cancel", "finish", "cleanup",
}


def label_is_code_shaped(name):
    if not name:
        return False
    toks = [t.lower() for t in re.split(r'[_.$0-9]|(?<=[a-z])(?=[A-Z])', name) if t]
    return any(t in CODE_NAME_TOKENS for t in toks)


EMPTY_FIELD = re.compile(
    r'^\s*(unknown|open|todo|to do|gaps?|caveats?|risks?)\s*[:=-]\s*'
    r'(-+|none|n/?a|\(none\)|nothing|\.)?\s*$', re.I)


def normalise_header(header):
    """Drop template fields whose value is empty (`Unknown: -`), so the word in
    the FIELD NAME is not read as an admission about the region."""
    out = []
    for ln in (header or "").split("\n"):
        if EMPTY_FIELD.match(ln):
            continue
        out.append(ln)
    return "\n".join(out)
# Tokens that make a header EVIDENCE-BEARING (grade A).
EVIDENCE = ("read by", "written by", "used by", "consumed by", "reader",
            "consumer", "handler", "call site", "callsite", "called from",
            "loaded by", "walks", "indexed by", "record", "entry", "field",
            "+0x", "offset", "stride", "bytes each", "per entry", "format",
            "layout", "0x", "findings-", "findings_", ".md", ".py", "see ",
            "evidence", "proof", "proven", "confirmed", "verified",
            "bpp", "palette", "header", "magic", "checksum", "struct")


def sh(cmd, **kw):
    r = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if r.returncode != 0:
        raise RuntimeError("FAILED: %s\n%s" % (" ".join(cmd), (r.stderr or r.stdout)[-4000:]))
    return r.stdout


def strip_comment(line):
    """Drop a `;` comment, respecting quotes (an .ascii literal may hold `;`)."""
    out, q = [], None
    for ch in line:
        if q:
            out.append(ch)
            if ch == q:
                q = None
            continue
        if ch in "\"'":
            q = ch
            out.append(ch)
            continue
        if ch == ";":
            break
        out.append(ch)
    return "".join(out)


# ------------------------------------------------------------------ the mirror
def collect_macros(srcroot):
    """name -> 'code'|'data'|'none', judged from the macro BODY."""
    macros = {}
    for dp, _, fn in os.walk(srcroot):
        for f in sorted(fn):
            if not f.endswith((".s", ".inc")):
                continue
            try:
                txt = open(os.path.join(dp, f), encoding="latin-1").read()
            except OSError:
                continue
            cur, body = None, []
            for ln in txt.split("\n"):
                c = strip_comment(ln).strip()
                m = re.match(r'^\.macro\s+([\w.$]+)', c)
                if m:
                    cur, body = m.group(1), []
                    continue
                if cur is not None:
                    if re.match(r'^\.endm\b', c):
                        kinds = set()
                        for b in body:
                            b = b.strip()
                            while LABEL_RE.match(b):
                                b = b.split(":", 1)[1].strip()
                            if not b:
                                continue
                            if b.startswith("."):
                                d = b.split()[0].lower()
                                if d in DATA_DIRS or d in FILL_DIRS:
                                    kinds.add("data")
                            else:
                                kinds.add("code")
                        macros[cur] = "code" if "code" in kinds else (
                            "data" if "data" in kinds else "none")
                        cur = None
                    else:
                        body.append(strip_comment(ln))
    return macros


def mirror_tree(srcroot, dest):
    """Copy srcroot to dest, marking every non-blank source line.  Returns marks."""
    marks = []
    for dp, dn, fn in os.walk(srcroot):
        rel = os.path.relpath(dp, srcroot)
        outdir = os.path.join(dest, rel) if rel != "." else dest
        os.makedirs(outdir, exist_ok=True)
        dn.sort()
        for f in sorted(fn):
            s, d = os.path.join(dp, f), os.path.join(outdir, f)
            if not f.endswith(".s"):
                if not os.path.exists(d):
                    try:
                        os.symlink(os.path.abspath(s), d)
                    except OSError:
                        pass
                continue
            lines = open(s, encoding="latin-1").read().split("\n")
            out, in_macro = [], False
            for i, ln in enumerate(lines):
                code = strip_comment(ln).strip()
                if re.match(r'^\.macro\b', code):
                    in_macro = True
                if code and not in_macro:
                    out.append("%s%d:" % (MARK, len(marks)))
                    marks.append((os.path.relpath(s, srcroot), i))
                if re.match(r'^\.endm\b', code):
                    in_macro = False
                out.append(ln)
            open(d, "w", encoding="latin-1").write("\n".join(out))
    return marks


def link_mirror(mirror, img, tmp):
    obj = os.path.join(tmp, img["key"] + ".o")
    elf = os.path.join(tmp, img["key"] + ".elf")
    cmd = [MC, "-triple=tlcs900", "-filetype=obj"]
    for inc in img["incs"]:
        cmd += ["-I", os.path.join(mirror, inc) if inc else mirror]
    # ⚠ SOME `.incbin` PATHS LEAVE THE MIRRORED DIRECTORY -- table_data reaches
    # `../v10/maincpu/images/*.bin`, which no amount of copying table_data/ can
    # provide.  The REAL source dir is appended as a LAST-RESORT search path so
    # those resolve.  It is last, so every mirrored (marked) `.s` still wins;
    # and if an unmarked real source were ever picked up instead, its lines
    # would have no markers and the reconciliation would go red -- the two
    # checks cover each other.
    for inc in img["incs"]:
        real = os.path.join(ROOT, img["mirror"], inc) if inc else \
            os.path.join(ROOT, img["mirror"])
        cmd += ["-I", real]
    cmd += ["-o", obj, os.path.join(mirror, img["root"])]
    sh(cmd)
    sh([LLD, "-e", "0", "-T", os.path.join(mirror, img["ld"]), "-o", elf, obj])
    return elf


def marker_addresses(elf):
    addrs = {}
    for line in sh([NM, "-n", elf]).split("\n"):
        p = line.split()
        if len(p) >= 3 and p[2].startswith(MARK):
            addrs[int(p[2][len(MARK):])] = int(p[0], 16)
    return addrs


# ------------------------------------------------------- source-text accessors
class Sources:
    def __init__(self, srcroot):
        self.root = srcroot
        self.cache = {}
        self.docs = {}

    def doc(self, rel):
        if rel not in self.docs:
            self.docs[rel] = DocIndex(self.lines(rel))
        return self.docs[rel]

    def lines(self, rel):
        if rel not in self.cache:
            self.cache[rel] = open(os.path.join(self.root, rel),
                                   encoding="latin-1").read().split("\n")
        return self.cache[rel]

    def text(self, rel, i):
        L = self.lines(rel)
        return L[i] if 0 <= i < len(L) else ""


def classify_line(text, macros):
    """-> (bucket_hint, detail).  bucket_hint in code/data/fill/none."""
    c = strip_comment(text).strip()
    if not c:
        return "none", "blank"
    while True:
        m = LABEL_RE.match(c) or NUMLABEL_RE.match(c)
        if not m:
            break
        c = c[m.end():].strip()
    if not c:
        return "none", "label"
    if c.startswith("."):
        d = c.split()[0].split(",")[0].lower()
        if d in DATA_DIRS:
            return "data", d
        if d in FILL_DIRS:
            return "fill", d
        return "none", d
    tok = re.split(r'[\s,]', c, maxsplit=1)[0]
    if tok in macros:
        k = macros[tok]
        return ("code" if k == "code" else "data" if k == "data" else "none",
                "macro:" + tok)
    return "code", "insn"


# ------------------------------------------------------------ region assembly
class DocIndex:
    """Per-file precomputation: for any line, the enclosing label and the nearest
    preceding SECTION HEADER (a contiguous run of >= 2 comment-only lines).

    Precomputed in one forward pass per file so the census does not re-scan 400
    lines of source per region -- with ~10^5 regions that difference is hours.
    """

    def __init__(self, lines):
        n = len(lines)
        self.lines = lines
        self.label = [None] * n          # index -> (line, name) or None
        self.hdr = [None] * n            # index -> (start, end) of a comment run
        cur_label = None
        cur_hdr = None
        run_start = None
        run_len = 0
        for i, ln in enumerate(lines):
            t = ln.strip()
            c = strip_comment(ln).strip()
            self.label[i] = cur_label
            self.hdr[i] = cur_hdr
            if t.startswith(";"):
                if run_start is None:
                    run_start = i
                run_len += 1
                if run_len == 2:
                    cur_hdr = (run_start, None)
                if run_len >= 2:
                    cur_hdr = (run_start, i + 1)
                continue
            if not c:
                if run_len < 2:
                    run_start, run_len = None, 0
                continue
            run_start, run_len = None, 0
            m = LABEL_RE.match(c)
            if m and not m.group(1).startswith(MARK):
                # ⚠ ASSIGNED TO LINE i ITSELF, not only to the lines below it.
                # `Bitmap_1bit_Illegal_Disk: .incbin "..."` is one line, and an
                # earlier version recorded the PREVIOUS label for it -- so every
                # `label: directive` one-liner in the tree (there are thousands)
                # was graded on a neighbour's name.  Found by the FP sample:
                # a 616 B bitmap was reported as `SLIDE_STRING_2`.
                cur_label = (i, m.group(1))
                self.label[i] = cur_label
        # file header: the leading comment block
        fh = []
        for t in lines[:80]:
            s = t.strip()
            if s.startswith(";"):
                fh.append(s.lstrip("; ").rstrip())
            elif s and not s.startswith(".text"):
                break
        self.fileheader = "\n".join(fh)

    def context(self, i, back=400):
        lab = self.label[i]
        label = lab[1] if lab else None
        h = self.hdr[i]
        block = []
        # ⚠ A HEADER IS CREDITED ONLY IF IT SITS DIRECTLY ABOVE THE OBJECT.
        # Anchor = the enclosing label if there is one, else the region's own
        # first line; the header must end no more than ANCHOR_SLACK lines above
        # it.  Without this a banner propagates DOWN through every later object
        # in the file: the FP sample found a run of 1-bit bitmaps credited to a
        # "DMA ISR event router" header belonging to a table far above them.
        anchor = lab[0] if (lab and lab[0] >= i - back) else i
        if h and h[1] is not None and h[0] >= i - back and h[1] >= anchor - ANCHOR_SLACK:
            block = [self.lines[k].strip().lstrip("; ").rstrip()
                     for k in range(h[0], min(h[1], i + 1))]
        # comment lines immediately above the region, if any
        imm = []
        k = i - 1
        while k >= 0:
            t = self.lines[k].strip()
            if t.startswith(";"):
                imm.append(t.lstrip("; ").rstrip())
                k -= 1
                continue
            if not t:
                k -= 1
                continue
            break
        imm.reverse()
        seen, merged = set(), []
        for x in block + imm:
            if x not in seen:
                seen.add(x)
                merged.append(x)
        return label, "\n".join(merged), self.fileheader


def name_is_descriptive(name):
    if not name:
        return False
    base = name
    base = re.sub(r'_?(0x)?[0-9A-Fa-f]{4,8}$', '', base)
    base = re.sub(r'\d+$', '', base)
    toks = [t for t in re.split(r'[_.$]|(?<=[a-z])(?=[A-Z])', base) if t]
    toks = [t.lower() for t in toks if len(t) >= 2]
    good = [t for t in toks if t not in GENERIC]
    return bool(good)


def grade_purpose(label, header, fileheader):
    """-> (grade, reason, self_admitted).

    GRADES, and why there are three rather than two.  The project owner's test
    is "can a reader say what this represents?", and two very different things
    pass it: a header that names the READER and the RECORD SHAPE (grade A), and
    a bare descriptive label like `Font_Svc07_8x16` or `DrumKitNames` with no
    header at all (grade B).  The second is real understanding -- it is not a
    `Data_F12345` address label -- but it rests on somebody's naming judgement
    and nothing else, so it is counted separately and it is the bucket the
    false-positive sample is drawn from.

    ⚠ SELF-ADMITTED IGNORANCE IS TRACKED SEPARATELY FROM THE GRADE.  A header
    saying "role NOT established" or "Readers: NONE IN THE CENSUS" is a research
    target whatever its label says, so it caps the grade at B AND sets a flag
    that puts the region on the target list regardless.  Without the flag those
    regions would hide inside a "known" bucket on the strength of their name.
    """
    header = normalise_header(header)
    h = (header or "").lower()
    fh = (fileheader or "").lower()
    words = len(re.findall(r'[A-Za-z]{2,}', header or ""))
    ev = sum(1 for t in EVIDENCE if t in h)
    desc = name_is_descriptive(label)
    admits = any(a in h for a in ADMISSIONS)

    if admits and words < 40:
        return "C", "header admits the purpose is not established", True
    if words >= 8 and ev >= 2 and not admits:
        return "A", "documented + evidence", False
    if desc and words >= 6 and ev >= 1 and not admits:
        return "A", "descriptive name + documented + evidence", False
    if desc:
        return "B", ("descriptive name + header" if words >= 4
                     else "descriptive name only"), admits
    if words >= 10 and ev >= 1:
        return "B", "section header only (address-derived label)", admits
    if len(re.findall(r'[A-Za-z]{2,}', fileheader or "")) >= 30 and words >= 4:
        return "B", "file header + local header", admits
    return "C", ("no explanatory header and an address-derived label"
                 if not desc else "named but undocumented"), admits


# --------------------------------------------------------------- format hints
def format_hints(blob, label, detail):
    hints = []
    if not blob:
        return hints
    n = len(blob)
    if blob[:2] == b"BM" and n > 54:
        hints.append("bmp")
    if b"MThd" in blob[:64]:
        hints.append("midi")
    pr = sum(1 for b in blob if 32 <= b < 127)
    if n >= 16 and pr / n >= 0.75:
        hints.append("text")
    zf = sum(1 for b in blob if b in (0x00, 0xFF))
    if n >= 64 and zf / n >= 0.55 and len(set(blob)) > 1:
        hints.append("bitmap-like")
    if n >= 32 and n % 4 == 0:
        tops = [blob[i + 3] for i in range(0, n, 4)]
        if len(set(tops)) <= 2 and tops[0] in (0x00, 0xE0, 0xE1, 0xF0, 0xF8, 0xFF):
            hints.append("ptr-table")
    lab = (label or "").lower() + " " + (detail or "").lower()
    for k, v in (("font", "glyph"), ("glyph", "glyph"), ("icon", "bitmap"),
                 ("bitmap", "bitmap"), ("wallpaper", "bitmap"), ("image", "bitmap"),
                 ("palette", "palette"), ("pallete", "palette"),
                 ("wave", "pcm"), ("pcm", "pcm"), ("sample", "pcm"),
                 ("midi", "midi"), ("song", "sequence"), ("preset", "sequence"),
                 ("string", "text"), ("text", "text"), ("name", "text"),
                 ("coeff", "coefficients"), ("param", "coefficients")):
        if k in lab and v not in hints:
            hints.append("name:" + v)
    return hints


# ------------------------------------------------------------------ the census
def rom_offset_fn(img):
    base, size = img["base"], img["size"]
    if "split" in img:
        head, skip = img["split"]
        def f(addr):
            o = addr - base
            if o < 0:
                return None
            if o < head:
                return o
            if o >= skip:
                r = o - skip + head
                return r if r < size else None
            return None
        return f
    def f(addr):
        o = addr - base
        return o if 0 <= o < size else None
    return f


def clip_to_rom(a, b, img):
    """Intersect [a,b) with the address ranges that land in the ROM file.
    -> list of (rom_lo, rom_hi).  Interval arithmetic, not a per-byte loop."""
    base, size = img["base"], img["size"]
    if "split" not in img:
        lo, hi = max(a, base) - base, min(b, base + size) - base
        return [(lo, hi)] if hi > lo else []
    head, skip = img["split"]
    out = []
    for (alo, ahi, roff) in ((base, base + head, 0),
                             (base + skip, base + skip + size - head, head - skip)):
        lo, hi = max(a, alo), min(b, ahi)
        if hi > lo:
            out.append((lo - base + roff, hi - base + roff))
    return out


def census_image(img, tmp, verbose=True):
    srcroot = os.path.join(ROOT, img["mirror"])
    rom = open(os.path.join(ROOT, img["rom"]), "rb").read()
    assert len(rom) == img["size"], "%s dump is %d bytes, expected %d" % (
        img["key"], len(rom), img["size"])

    mdir = os.path.join(tmp, "mirror_" + os.path.basename(img["mirror"]) + "_"
                        + str(abs(hash(img["mirror"])) % 10 ** 6))
    if not os.path.isdir(mdir):
        marks = mirror_tree(srcroot, mdir)
        with open(mdir + ".marks.json", "w") as fh:
            json.dump(marks, fh)
    else:
        marks = json.load(open(mdir + ".marks.json"))

    elf = link_mirror(mdir, img, tmp)

    # INERTNESS PROOF -- the marked mirror must still be the dump.
    raw = os.path.join(tmp, img["key"] + ".bin")
    sh([OBJCOPY, "-O", "binary", elf, raw])
    got = open(raw, "rb").read()
    if "split" in img:
        head, skip = img["split"]
        got = got[:head] + got[skip:]
    inert = (got == rom)

    addrs = marker_addresses(elf)
    src = Sources(srcroot)
    macros = collect_macros(srcroot)
    off = rom_offset_fn(img)

    ent = sorted(((a, i) for i, a in addrs.items()), key=lambda t: (t[0], t[1]))
    # ⚠ SEVERAL MARKERS SHARE AN ADDRESS whenever a line emits nothing there --
    # a label, a `.set`, a `.text`, and above all an `.include`, whose marker
    # sits at the same address as the first line of the file it pulls in.  The
    # span between two addresses belongs to whichever of them actually EMITS,
    # and marker index is not that order: files are walked alphabetically, so an
    # included file's markers can be numbered before OR after the `.include`
    # that pulls it in.  Keeping only the emitting entry of each address group
    # is what makes the census reconcile; without it prom_d lost 36 B to three
    # `.include` lines.  A tie between two emitting lines can only happen when
    # one of them emits zero bytes (an already-satisfied `.org`/`.align`), so a
    # non-fill line wins the tie.
    kept, k = [], 0
    while k < len(ent):
        j = k
        while j + 1 < len(ent) and ent[j + 1][0] == ent[k][0]:
            j += 1
        group = ent[k:j + 1]
        scored = []
        for (a, i) in group:
            rel, li = marks[i]
            bk, _ = classify_line(src.text(rel, li), macros)
            scored.append((0 if bk in ("data", "code") else 1 if bk == "fill" else 2, i, a))
        scored.sort()
        kept.append((scored[0][2], scored[0][1]))
        k = j + 1
    ent = kept
    # collapse to spans
    spans = []
    for k, (a, i) in enumerate(ent):
        nxt = ent[k + 1][0] if k + 1 < len(ent) else img["base"] + (
            img["size"] if "split" not in img else img["split"][1] + img["size"] - img["split"][0])
        if nxt <= a:
            continue
        rel, li = marks[i]
        spans.append((a, nxt, rel, li))
    return dict(img=img, rom=rom, spans=spans, src=src, macros=macros,
                off=off, inert=inert, nmarks=len(marks), nres=len(addrs))


DROPPED = []


def build_regions(c):
    """Merge adjacent spans into named regions and classify them."""
    img, src, macros, off, rom = c["img"], c["src"], c["macros"], c["off"], c["rom"]
    del DROPPED[:]
    regions = []
    cur = None
    for (a, b, rel, li) in c["spans"]:
        bucket, detail = classify_line(src.text(rel, li), macros)
        if bucket == "none":
            if b > a:
                DROPPED.append((a, b, rel, li, detail, src.text(rel, li)[:90]))
            continue
        pieces = clip_to_rom(a, b, img)
        if not pieces:
            continue
        for (plo, phi) in pieces:
            key = (rel, bucket)
            # ⚠ FILL LINES ARE NEVER MERGED.  Merging `.zero 30` with three
            # `.fill n,1,0xFF` runs produced ONE 73,556 B "non-uniform fill"
            # region that then fell through to the data grader -- the uniformity
            # test is only meaningful per directive.
            if bucket != "fill" and cur and cur["key"] == key and cur["hi"] == plo and \
                    cur["detail_set"] and _same_region(cur, src, rel, li):
                cur["hi"] = phi
                cur["lines"].append(li)
                cur["details"].add(detail)
            else:
                if cur:
                    regions.append(cur)
                cur = dict(key=key, rel=rel, bucket=bucket, lo=plo, hi=phi,
                           first_line=li, lines=[li], details={detail},
                           detail_set=True)
    if cur:
        regions.append(cur)
    return regions


def _same_region(cur, src, rel, li):
    """A region breaks at a label or at a section header (>=2 comment lines)."""
    prev = cur["lines"][-1]
    if rel != cur["rel"]:
        return False
    L = src.lines(rel)
    run = 0
    for k in range(prev + 1, li + 1):
        c = strip_comment(L[k]).strip()
        if LABEL_RE.match(c):
            return False
        t = L[k].strip()
        if t.startswith(";"):
            run += 1
            if run >= 2:
                return False
        elif c:
            run = 0
    return True


def annotate(c, regions, ctrl_targets, label_index):
    img, src, rom = c["img"], c["src"], c["rom"]
    out = []
    for r in regions:
        n = r["hi"] - r["lo"]
        blob = rom[r["lo"]:r["hi"]]
        label, header, fileheader = src.doc(r["rel"]).context(r["first_line"])
        rec = dict(image=img["key"], rel=r["rel"], line=r["first_line"] + 1,
                   lo=r["lo"], hi=r["hi"], size=n, bucket=r["bucket"],
                   details=sorted(r["details"]), label=label,
                   addr=img["base"] + r["lo"] if "split" not in img else None,
                   header=header[:1200], grade=None, reason=None, hints=[],
                   code_suspect=False, admits=False, embedded_in_code=False,
                   code_name=False,
                   words=len(re.findall(r'[A-Za-z]{2,}', normalise_header(header) or "")))
        if r["bucket"] == "code":
            rec["grade"] = "CODE"
            rec["reason"] = "instruction statements"
        elif r["bucket"] == "fill":
            uniform = len(set(blob)) <= 1
            if uniform and n >= 16:
                rec["grade"] = "FILLER"
                rec["reason"] = "verified uniform 0x%02X x %d" % (blob[0] if blob else 0, n)
            else:
                g, why, adm = grade_purpose(label, header, fileheader)
                rec["grade"] = {"A": "KNOWN-A", "B": "KNOWN-B", "C": "UNKNOWN"}[g]
                rec["reason"] = ("short/non-uniform fill: " + why)
                rec["admits"] = adm
        else:
            g, why, adm = grade_purpose(label, header, fileheader)
            rec["grade"] = {"A": "KNOWN-A", "B": "KNOWN-B", "C": "UNKNOWN"}[g]
            rec["reason"] = why
            rec["admits"] = adm
            rec["hints"] = format_hints(blob, label, " ".join(rec["details"]))
            rec["code_name"] = label_is_code_shaped(label)
            labs = label_index.get(r["rel"], [])
            i = bisect.bisect_left([x[0] for x in labs], r["first_line"])
            for (ln, nm) in labs[max(0, i - 1):i + 4]:
                if r["first_line"] - 3 <= ln <= r["first_line"] + len(r["lines"]) + 1:
                    if nm in ctrl_targets:
                        rec["code_suspect"] = True
        out.append(rec)
    # ★ EMBEDDED-IN-CODE: a data region with an instruction region on BOTH sides
    # and no explanatory header of its own.  This is the shape of undecoded code
    # spelled as `.byte` -- the sample found `Sprintf_MainLoop_ReadNext`,
    # `SndParam_ProcessEntry` and `InitializeKubo`, all of them plainly TLCS-900
    # instruction bytes sitting between two decoded routines under a routine
    # name.  They pass the "descriptive label" test and are NOT data at all, so
    # the flag is subtracted from the explained figure rather than left to a
    # sample to find.  ⚠ It is a FLAG, not a verdict: an embedded jump table or
    # a small constant pool has the same shape, which is why it is reported
    # separately instead of being reclassified.
    for i, rec in enumerate(out):
        if rec["grade"] not in ("KNOWN-A", "KNOWN-B", "UNKNOWN"):
            continue
        if rec["words"] >= 4:
            continue
        prv = out[i - 1] if i else None
        nxt = out[i + 1] if i + 1 < len(out) else None
        if prv and nxt and prv["grade"] == "CODE" and nxt["grade"] == "CODE" \
                and prv["rel"] == rec["rel"] == nxt["rel"]:
            rec["embedded_in_code"] = True
    return out


def scan_refs(srcroot):
    """-> (set of symbols targeted by a control transfer, {rel: [(line, label)]})."""
    ctrl, index = set(), {}
    for dp, _, fn in os.walk(srcroot):
        for f in sorted(fn):
            if not f.endswith(".s"):
                continue
            p = os.path.join(dp, f)
            rel = os.path.relpath(p, srcroot)
            labs = []
            for i, ln in enumerate(open(p, encoding="latin-1").read().split("\n")):
                c = strip_comment(ln).strip()
                m = LABEL_RE.match(c)
                if m:
                    labs.append((i, m.group(1)))
                    c = c[m.end():].strip()
                if CTRL_RE.match(c):
                    ops = c.split(None, 1)[1] if " " in c else ""
                    for g in IDENT_RE.findall(ops):
                        ctrl.add(g)
            index[rel] = labs
    return ctrl, index


# --------------------------------------------------------------------- report
BUCKETS = ["CODE", "KNOWN-A", "KNOWN-B", "UNKNOWN", "FILLER"]


def run(keys, verbose=True):
    results, allrecs = [], []
    tmp = tempfile.mkdtemp(prefix="drc-")
    try:
        refs_cache = {}
        for img in IMAGES:
            if keys and img["key"] not in keys:
                continue
            if verbose:
                print("  %-12s building map ..." % img["key"], flush=True)
            c = census_image(img, tmp)
            srcroot = os.path.join(ROOT, img["mirror"])
            if srcroot not in refs_cache:
                refs_cache[srcroot] = scan_refs(srcroot)
            ctrl, index = refs_cache[srcroot]
            regions = build_regions(c)
            recs = annotate(c, regions, ctrl, index)
            tot = {b: 0 for b in BUCKETS}
            for r in recs:
                tot[r["grade"]] += r["size"]
            covered = sum(tot.values())
            results.append(dict(key=img["key"], title=img["title"],
                                size=img["size"], inert=c["inert"],
                                totals=tot, covered=covered,
                                nregions=len(recs)))
            allrecs += recs
            if verbose:
                print("    inert=%s  covered %d / %d  regions %d" %
                      (c["inert"], covered, img["size"], len(recs)), flush=True)
                if DROPPED:
                    print("    ⚠ %d span(s) / %d B fell on a no-emit line:" % (
                        len(DROPPED), sum(b - a for a, b, *_ in DROPPED)), flush=True)
                    for (a, b, rel, li, det, txt) in DROPPED[:12]:
                        print("       0x%06X..0x%06X %5d  %s:%d  %s | %s" % (
                            a, b, b - a, rel, li + 1, det, txt.strip()), flush=True)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    return results, allrecs


def reconcile(results, hard=True):
    ok = True
    print("\nRECONCILIATION")
    print("  %-12s %10s %10s %10s  %s" % ("image", "dump", "census", "delta", "inert"))
    for r in results:
        d = r["covered"] - r["size"]
        bad = (d != 0) or not r["inert"]
        ok &= not bad
        print("  %-12s %10d %10d %10d  %s%s" % (
            r["key"], r["size"], r["covered"], d,
            "yes" if r["inert"] else "NO", "   <-- FAIL" if bad else ""))
    ts, tc = sum(r["size"] for r in results), sum(r["covered"] for r in results)
    print("  %-12s %10d %10d %10d" % ("TOTAL", ts, tc, tc - ts))
    if not ok:
        print("\nRECONCILIATION FAILED -- do not quote any number above.")
        if hard:
            sys.exit(2)
    else:
        print("  every byte of every image is in exactly one bucket.")
    return ok


def report(results, recs):
    print("\nPER-IMAGE CENSUS (bytes)")
    hdr = "  %-12s %9s %9s %9s %9s %9s" % ("image", "CODE", "KNOWN-A", "KNOWN-B",
                                           "UNKNOWN", "FILLER")
    print(hdr)
    agg = {b: 0 for b in BUCKETS}
    for r in results:
        t = r["totals"]
        for b in BUCKETS:
            agg[b] += t[b]
        print("  %-12s %9d %9d %9d %9d %9d" % (r["key"], t["CODE"], t["KNOWN-A"],
                                              t["KNOWN-B"], t["UNKNOWN"], t["FILLER"]))
    print("  " + "-" * 62)
    print("  %-12s %9d %9d %9d %9d %9d" % ("TOTAL", agg["CODE"], agg["KNOWN-A"],
                                          agg["KNOWN-B"], agg["UNKNOWN"], agg["FILLER"]))
    tot = sum(agg.values())
    expl = tot - agg["UNKNOWN"]
    print("\n  explained (CODE + KNOWN-A/B + FILLER) : %d / %d = %.2f%%" %
          (expl, tot, 100.0 * expl / tot))
    print("  strict (CODE + KNOWN-A + FILLER)      : %d / %d = %.2f%%" %
          (tot - agg["UNKNOWN"] - agg["KNOWN-B"], tot,
           100.0 * (tot - agg["UNKNOWN"] - agg["KNOWN-B"]) / tot))
    print("\nLARGEST PURPOSE-UNKNOWN RANGES")
    unk = sorted([r for r in recs if r["grade"] == "UNKNOWN"],
                 key=lambda r: -r["size"])[:40]
    for r in unk:
        print("  %-11s 0x%06X-0x%06X %8d  %-28s %s:%d  [%s]%s" % (
            r["image"], r["lo"], r["hi"], r["size"], (r["label"] or "-")[:28],
            r["rel"], r["line"], ",".join(r["hints"])[:40],
            " CODE-SUSPECT" if r["code_suspect"] else ""))
    print("\n  KNOWN-B by reason (bytes) -- the bucket the FP sample is drawn from:")
    br = {}
    for r in recs:
        if r["grade"] == "KNOWN-B":
            br[r["reason"]] = br.get(r["reason"], 0) + r["size"]
    for k, v in sorted(br.items(), key=lambda t: -t[1]):
        print("    %-52s %9d" % (k, v))
    # code-shaped label names, WITH THE NULL that says what the flag is worth
    dataimgs = {"tabledata", "customdata", "prom_d"}
    cn = [r for r in recs if r.get("code_name") and r["grade"] != "CODE"
          and r["grade"] != "FILLER"]
    dpool = [r for r in recs if r["image"] in dataimgs and r["grade"]
             not in ("CODE", "FILLER")]
    dhit = [r for r in dpool if r.get("code_name")]
    cpool = [r for r in recs if r["grade"] == "CODE"]
    chit = [r for r in cpool if label_is_code_shaped(r["label"])]
    print("\n  CODE-SHAPED LABEL on a DATA region: %d regions, %d B" %
          (len(cn), sum(r["size"] for r in cn)))
    print("    positive control (regions the source itself frames as CODE): "
          "%.1f%% of %d" % (100.0 * len(chit) / max(1, len(cpool)), len(cpool)))
    print("    NULL (data regions of table_data/custom_data/prom_d, where a hit"
          " can only be wrong): %.1f%% of %d"
          % (100.0 * len(dhit) / max(1, len(dpool)), len(dpool)))
    emb = [r for r in recs if r.get("embedded_in_code")]
    ebg = {}
    for r in emb:
        ebg[r["grade"]] = ebg.get(r["grade"], 0) + r["size"]
    print("\n  EMBEDDED-IN-CODE (undocumented data between two instruction "
          "regions in the same file):\n    %d regions, %d B -- %s" % (
              len(emb), sum(r["size"] for r in emb),
              ", ".join("%s %d B" % (k, v) for k, v in sorted(ebg.items()))))
    adm = [r for r in recs if r.get("admits")]
    print("\n  self-admitted-ignorance regions: %d (%d B) -- research targets"
          " whatever their grade" % (len(adm), sum(r["size"] for r in adm)))
    ncs = [r for r in recs if r["code_suspect"]]
    print("\n  code-suspect data regions: %d (%d B)" %
          (len(ncs), sum(r["size"] for r in ncs)))
    fh = {}
    for r in recs:
        if r["grade"].startswith("KNOWN") or r["grade"] == "UNKNOWN":
            for h in r["hints"]:
                fh[h] = fh.get(h, 0) + r["size"]
    print("  format hints (bytes): " + ", ".join(
        "%s=%d" % (k, v) for k, v in sorted(fh.items(), key=lambda t: -t[1])))
    return agg


def is_target(r):
    """A range the project cannot currently explain, in the owner's sense."""
    return (r["grade"] == "UNKNOWN" or r.get("admits") or
            r.get("embedded_in_code"))


def print_targets(recs, n):
    """Merge CONTIGUOUS research targets in the same image into one range.
    The owner asked for RANGES, and a 30-byte-at-a-time list of a 4 KB hole is
    not a range."""
    by = {}
    for r in recs:
        if is_target(r):
            by.setdefault(r["image"], []).append(r)
    merged = []
    for img, rs in by.items():
        rs.sort(key=lambda r: r["lo"])
        cur = None
        for r in rs:
            if cur and r["lo"] == cur["hi"] and r["rel"] == cur["rel"]:
                cur["hi"] = r["hi"]
                cur["parts"] += 1
                cur["labels"].append(r["label"] or "-")
                cur["why"].add(_whytag(r))
                cur["hints"] |= set(r["hints"])
            else:
                if cur:
                    merged.append(cur)
                cur = dict(image=img, rel=r["rel"], line=r["line"], lo=r["lo"],
                           hi=r["hi"], parts=1, labels=[r["label"] or "-"],
                           why={_whytag(r)}, hints=set(r["hints"]),
                           header=r["header"], grade=r["grade"])
        if cur:
            merged.append(cur)
    merged.sort(key=lambda m: -(m["hi"] - m["lo"]))
    tot = sum(m["hi"] - m["lo"] for m in merged)
    print("\nRESEARCH TARGETS -- ranges whose purpose is NOT established")
    print("  %d merged ranges, %d bytes total (%.2f%% of 12,386,304)"
          % (len(merged), tot, 100.0 * tot / TOTAL_BYTES))
    print("  %-11s %-19s %8s %-30s %s" % ("image", "range", "bytes", "label(s)", "why"))
    for m in merged[:n]:
        labs = m["labels"][0] if m["parts"] == 1 else \
            "%s .. %s (%d)" % (m["labels"][0][:14], m["labels"][-1][:14], m["parts"])
        print("  %-11s 0x%06X-0x%06X %8d %-30s %s%s" % (
            m["image"], m["lo"], m["hi"], m["hi"] - m["lo"], labs[:30],
            "+".join(sorted(m["why"])),
            ("  [" + ",".join(sorted(m["hints"]))[:34] + "]") if m["hints"] else ""))
    return merged


def _whytag(r):
    if r.get("embedded_in_code"):
        return "embedded-in-code"
    if r["grade"] == "UNKNOWN":
        return "no-explanation"
    return "self-admitted"


# ------------------------------------------------------------------- selftest
def selftest():
    f = 0

    def ck(d, cond, extra=""):
        nonlocal f
        print(("  ok   " if cond else "  FAIL ") + d + (("   " + extra) if extra else ""))
        f += not cond

    ck("the pinned llvm-mc exists", os.path.exists(MC), MC)
    ck("twelve images are declared", len(IMAGES) == 12, str(len(IMAGES)))
    ck("declared sizes sum to the known total",
       sum(i["size"] for i in IMAGES) == TOTAL_BYTES,
       "%d vs %d" % (sum(i["size"] for i in IMAGES), TOTAL_BYTES))
    for i in IMAGES:
        p = os.path.join(ROOT, i["rom"])
        ck("dump present and the right size: " + i["key"],
           os.path.exists(p) and os.path.getsize(p) == i["size"], p)

    # strip_comment must not eat a `;` inside a string literal
    ck("strip_comment respects quotes",
       strip_comment('\t.ascii "a;b"\t; note').strip() == '.ascii "a;b"',
       repr(strip_comment('\t.ascii "a;b"\t; note')))

    m = {"naka_header": "data", "VGA_WRITE": "code"}
    ck("classify: instruction", classify_line("\tld XWA,0x1234", m)[0] == "code")
    ck("classify: .byte is data", classify_line("\t.byte 1,2,3", m)[0] == "data")
    ck("classify: .fill is fill", classify_line("\t.fill 16,1,0xFF", m)[0] == "fill")
    ck("classify: .org is fill", classify_line("\t.org 0x100, 0xFF", m)[0] == "fill")
    ck("classify: label+data", classify_line("Foo:\t.long 1", m)[0] == "data")
    ck("classify: .set emits nothing", classify_line("\t.set A, 1", m)[0] == "none")
    ck("classify: data macro", classify_line("\tnaka_header 3", m)[0] == "data")
    ck("classify: code macro", classify_line("\tVGA_WRITE 1, 2", m)[0] == "code")

    ck("address-derived names are NOT descriptive",
       not name_is_descriptive("Data_F12345") and not name_is_descriptive("unk_1234")
       and not name_is_descriptive("LABEL_F16A57"))
    ck("real names ARE descriptive",
       name_is_descriptive("HelpDB_English") and name_is_descriptive("ToneDB_EnvDescTable"))

    ck("an admission forces UNKNOWN and sets the flag",
       grade_purpose("ToneTable", "The extent is the reachability walk's, not the "
                     "object's; read by 0xF31ABE with BC*HL", "")[:1] == ("C",)
       and grade_purpose("ToneTable", "extent is the reachability walk's", "")[2])
    ck("evidence-bearing header grades A",
       grade_purpose("ToneDB_EnvDescTable",
                     "48-entry envelope descriptor table, 8 bytes each; read by "
                     "prom_c 0xFB429D which adds the base at +0x08. See "
                     "FINDINGS-prom_d.md", "")[0] == "A")
    ck("bare address label with no header grades C",
       grade_purpose("Data_F3C37D", "", "")[0] == "C")
    ck("a descriptive label with no header grades B, never A",
       grade_purpose("Font_Svc07_8x16", "", "")[0] == "B"
       and grade_purpose("DrumKitNames", "", "")[0] == "B")
    ck("an empty template field is not an admission",
       grade_purpose("Font_Svc07_8x16",
                     "Font_Svc07_8x16 -- SWI7 service 0x07's font: 200 cells of "
                     "16 bytes, 8 x 16 pixels, 0xF1BEF0-0xF1CB6F.\nRole: Latin, "
                     "8 x 16.\nEvidence: prom_a LCD_Svc_07_ loads 0x00F1BEF0 at "
                     "0xF8F14C.\nUnknown: -\nEntry count: 200, exact.", "")[0] == "A"
       and not grade_purpose("Font_Svc07_8x16", "Role: Latin.\nUnknown: -", "")[2])
    ck("a FILLED Unknown: field IS an admission",
       grade_purpose("Font_Svc07_8x16", "Role: a font.  Unknown: which service "
                     "selects it, and where the 200th cell ends.", "")[2])
    ck("a wholly generic-stem address label is still C",
       grade_purpose("RecordArray_F511DD", "", "")[0] == "C"
       and grade_purpose("Data_F7681C", "", "")[0] == "C"
       and grade_purpose(".LFAF7A5", "", "")[0] == "C")
    ck("one non-generic stem is enough for B, never for A",
       grade_purpose("LinkTable_F4FF61", "", "") == ("B", "descriptive name only", False))
    ck("a code-shaped label is recognised",
       label_is_code_shaped("Sprintf_MainLoop_ReadNext")
       and label_is_code_shaped("CharMap_ActivePreamb_Prologue")
       and not label_is_code_shaped("Font_Svc07_8x16")
       and not label_is_code_shaped("ToneDB_EnvDescTable"))
    ck("a same-line label belongs to its own line",
       DocIndex(["Foo:", "\t.byte 1", "Bar:\t.incbin \"x.bin\""]
                ).context(2)[0] == "Bar")
    ck("a banner far above another object is NOT inherited",
       DocIndex(["; ---- a banner about something else", "; two lines of it",
                 "Other:", "\t.byte 1"] + ["\t.byte 2"] * 20 +
                ["Mine:", "\t.byte 3"]).context(25)[1] == "")

    # the v142 splice map
    v142 = [i for i in IMAGES if i["key"] == "v142"][0]
    off = rom_offset_fn(v142)
    ck("v142 splice: first byte", off(0x0400) == 0)
    ck("v142 splice: last head byte", off(0x0400 + 255) == 255)
    ck("v142 splice: the hole is a hole", off(0x0400 + 256) is None)
    ck("v142 splice: body starts at 256", off(0x0400 + 60416) == 256)
    ck("v142 splice: last byte", off(0x0400 + 60416 + 196608 - 256 - 1) == 196607)

    off10 = rom_offset_fn([i for i in IMAGES if i["key"] == "v10"][0])
    ck("plain map: base -> 0", off10(0xE00000) == 0)
    ck("plain map: end is exclusive", off10(0xE00000 + 2097152) is None)

    # A CHECK THAT CAN FAIL: run the whole pipeline on the smallest image and
    # require BOTH the inertness proof and an exact reconciliation.
    print("  -- end-to-end on custom_data (smallest image) --")
    res, recs = run({"customdata"}, verbose=True)
    ck("custom_data mirror is inert (still the dump)", res and res[0]["inert"])
    ck("custom_data reconciles to 1,048,576 B",
       res and res[0]["covered"] == 1048576,
       str(res[0]["covered"]) if res else "no result")
    ck("custom_data produced regions", res and res[0]["nregions"] > 0)

    print("\nSELFTEST " + ("PASS" if not f else "FAIL (%d)" % f))
    return 0 if not f else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--images", default="")
    ap.add_argument("--json", default="")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--sample", type=int, default=0)
    ap.add_argument("--load", default="", help="read a previous --json run "
                    "instead of rebuilding every map (for --sample)")
    ap.add_argument("--targets", type=int, default=0,
                    help="print the N largest RESEARCH TARGETS -- purpose-unknown"
                         " ranges, self-admitted gaps and embedded-in-code spans,"
                         " merged where they are contiguous")
    ap.add_argument("--grade", default="KNOWN-A,KNOWN-B",
                    help="which grades --sample draws from")
    ap.add_argument("--seed", type=int, default=20260902)
    a = ap.parse_args()
    if a.selftest:
        sys.exit(selftest())
    keys = set(x for x in a.images.split(",") if x)
    if a.load:
        d = json.load(open(a.load))
        res, recs = d["results"], d["regions"]
        print("loaded %s (%d regions)" % (a.load, len(recs)))
        reconcile(res, hard=False)
    else:
        res, recs = run(keys)
        reconcile(res, hard=not keys)
        report(res, recs)
    if a.json:
        json.dump(dict(results=res, regions=recs), open(a.json, "w"))
        print("\nwrote %s (%d regions)" % (a.json, len(recs)))
    if a.targets:
        print_targets(recs, a.targets)
    if a.sample:
        import random
        rnd = random.Random(a.seed)
        want = set(a.grade.split(","))
        # ⚠ EMBEDDED-IN-CODE REGIONS ARE EXCLUDED FROM THE POOL.  They are
        # counted EXACTLY by the flag, so leaving them in would measure the same
        # error twice -- once by census and once by sample -- and would make the
        # sampled rate depend on how many of them happened to be drawn.
        pool = [r for r in recs if r["grade"] in want
                and not r.get("embedded_in_code")]
        # size-weighted: sample bytes, not regions, so the rate applies to the
        # figure that is actually quoted.
        tot = sum(r["size"] for r in pool)
        print("\nFALSE-POSITIVE SAMPLE (%d of %d %s regions, size-weighted:"
              " a byte is as likely to be drawn as any other byte in the pool,"
              " so the rate applies to the FIGURE, not to region count)"
              % (a.sample, len(pool), a.grade))
        for _ in range(a.sample):
            x = rnd.randrange(tot)
            acc = 0
            for r in pool:
                acc += r["size"]
                if acc > x:
                    break
            print("\n--- %s %s:%d  0x%06X..0x%06X (%d B)  grade %s (%s)"
                  % (r["image"], r["rel"], r["line"], r["lo"], r["hi"], r["size"],
                     r["grade"], r["reason"]))
            print("    label: %s   hints: %s" % (r["label"], ",".join(r["hints"])))
            for ln in (r["header"] or "(no header)").split("\n")[:14]:
                print("    | " + ln[:150])


if __name__ == "__main__":
    main()
