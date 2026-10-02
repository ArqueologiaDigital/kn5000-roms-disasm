#!/usr/bin/env python3
"""split_blobs_at_far_pointers.py -- give each string that code reaches inside a blob its own label.

QUESTION THIS ANSWERS / JOB IT DOES
  symbolize_far_pointer_pushes.py turns `pushw 0x00e4 / pushw 0x5126` into `pushw Sym@hi16 /
  pushw Sym@lo16` only when a symbol sits EXACTLY at the pointer.  Most of the rest (about 500
  per KN5000 maincpu version) point INSIDE an object: a C string literal -- " %3d ", "A:\\",
  ".left" -- in the middle of a NAKA `.incbin` slice that the C compiler laid out as one run of
  NUL-terminated strings.  The same strings are also reached by positional aliases
  (`.set Str_No_0x38, Str_No + 56` in shared/positional_labels.s, used as `ld xix, Str_No_0x38`)
  whose names say only where they are.  CLAUDE.md's Binary Include Splitting policy
  (MANDATORY): a reference inside a binary include splits the include there, and the reference
  names the new label.

  This does that, for the one shape it can do safely:
    * the target lies inside an `.incbin "F", OFF, LEN` slice: a labelled one (label and
      directive on one line, or the directive on the next line), or an unlabelled one that
      follows such a slice with only comments between (the "[nakarest]" runs), whose address is
      the previous slice's end;
    * the target is the START of a NUL-terminated string in the image's own ROM: the slice's
      first byte, or the byte before it is 0x00 / 0xff (the 0xff alignment pad), and the bytes
      up to the NUL are text (0x20..0x7e, or >= 0x80 for the LCD font's glyphs).
  Targets are (a) far-pointer push pairs with no symbol at the pointer, (b) numeric address
  arguments of the NAKA registration macros (RegTitle/RegMode/RegObjTabl ..., see
  symbolize_far_pointer_pushes.REG_ADDR_ARGS) and (c) positional `.set A, B + N` aliases whose
  B + N is such a string.  Each slice is cut into one `.incbin`
  per target (a labelled slice's first piece keeps its label) and each new piece is labelled
  `<Reader>_Str_<Text>` (or `<Reader>_PtrTable` where the target is a run of 32-bit pointers
  into the image, a C `char *table[]`; or, for a table / count a registration macro passes,
  `<Module>_<Class>Table_<id>` / `<Module>_<Class>Count_<id>` after the NAKA class and base id
  of the call, the convention of East_MainFuncTable_143 and Kubo_ClassCount_168): Reader is the routine that reaches it first in address order (the
  nearest preceding column-0 non-structural label of the push or of the alias's use), Text is
  the string's words (`%3d` -> `Fmt3d`, all blanks -> `BlankN`, "" -> `Empty`, punctuation by
  name), made unique with _2, _3 ...  An alias that lands on a new piece, or on a slice that
  already has a label (a second name for one address, against the canonical-label policy), is
  retired and every use of it -- code and comments, in every file of the tree -- takes the
  label's name.
  A NAMED alias (`.equ DspEffectName_PtrTable, NakaData_WidgetDescriptors + 0x1C1A`, any name
  not ending in _0xHEX) inside a slice is promoted the same way under its own name, so v7 --
  which lacks some of those aliases -- inherits the name through --names-from.
  Anything else (a target inside code or a non-string, an `.ascii`/`aligned_string` run) is
  REPORTED and left alone.

  Splitting a slice changes no byte (`make gate-all`), and a follow-up run of
  symbolize_far_pointer_pushes.py then names every reached string.

USAGE
  make all
  python3 scripts/converters/split_blobs_at_far_pointers.py --image v10 [--apply] [--report OUT]
      [--names-from OTHER_REPORT]   (v9/v7 take v10's names for the same piece -- diff hygiene)
  python3 scripts/converters/symbolize_far_pointer_pushes.py --image v10 --apply
  images: v10 v9 v7 hdae5000 prom_a
"""
import argparse
import bisect
import collections
import glob
import json
import os
import re
import subprocess
import sys

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True).stdout.strip() or "."
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import symbolize_far_pointer_pushes as fp  # noqa: E402

ROM = {"v10": ("original_ROMs/kn5000_v10_program.rom", 0xE00000),
       "v9": ("original_ROMs/kn5000_v9_program.rom", 0xE00000),
       "v7": ("original_ROMs/kn5000_v7_program.rom", 0xE00000),
       "hdae5000": ("original_ROMs/hd-ae5000_v2_06i.ic4", 0x280000),
       "prom_a": ("wsa1/original_ROMs/wsa1_prom_a.ic12", 0xF80000)}
NUM = r'(0x[0-9a-fA-F]+|\d+)'
INCBIN_SAME = re.compile(r'^([A-Za-z_][\w.$]*):\s*\.incbin\s+"([^"]+)"\s*,\s*' + NUM + r'\s*,\s*' +
                         NUM + r'\s*(;.*)?$')
INCBIN_BARE = re.compile(r'^\s*\.incbin\s+"([^"]+)"\s*,\s*' + NUM + r'\s*,\s*' + NUM + r'\s*(;.*)?$')
LABEL = re.compile(r'^([A-Za-z_][\w.$]*):')
SET = re.compile(r'^\s*\.(?:set|equ)\s+([A-Za-z_][\w.$]*)\s*,\s*([A-Za-z_][\w.$]*)\s*\+\s*' + NUM +
                 r'\s*(;.*)?$')
WORD = re.compile(r'[A-Za-z_][\w.$]*')
POSITIONAL = re.compile(r'_0x[0-9A-Fa-f]+$')            # Base_0x1C1A: a name that only says where
STRUCTURAL = re.compile(r'_(Skip|Join|Loop|Return|Helper|Epilogue|Tail|Next|Done|Exit|End|'
                        r'Data\d*|Block|Bytes|Code|Cont|Case\w*|Default)\d*$|_0x[0-9A-Fa-f]+$|'
                        r'^LABEL_|^sub_|^loc_|^\.')
NOT_TEXT = re.compile(r'^(Bitmap|Palette|Icon|Font|Image|Glyph|Logo|Pixel)', re.I)
PUNCT = {"{": "LBrace", "}": "RBrace", "[": "LBracket", "]": "RBracket", "(": "LParen",
         ")": "RParen", ":": "Colon", "\\": "Backslash", "/": "Slash", "-": "Dash", "*": "Star",
         "+": "Plus", ",": "Comma", ".": "Dot", "=": "Eq", "<": "Lt", ">": "Gt", "#": "Hash",
         "?": "Query", "!": "Bang", "&": "Amp", "'": "Quote", '"': "DQuote", "_": "Under",
         "|": "Bar", "@": "At", "$": "Dollar", ";": "Semi", "^": "Caret", "~": "Tilde"}


def c_string_at(rom, base, addr):
    """The NUL-terminated text at addr, or None.  Printable ASCII only: on 2026-10-02 every
    candidate holding a byte >= 0x80 was a 24-bit pointer read as text ("B_" + 0xe9 is
    42 5f e9 00 = 0xe95f42).  The bytes around it (16 each side) must be mostly text too: a
    bitmap or a table that happens to hold "~9b" + NUL is not a string table."""
    o = addr - base
    if not 0 <= o < len(rom):
        return None
    end = rom.find(b"\0", o, o + 160)
    if end < 0:
        return None
    s = rom[o:end]
    if any(b < 0x20 or b >= 0x7f for b in s):
        return None                                # every high-byte "string" seen was a pointer
    win = rom[max(0, o - 16):end + 16]
    if sum(1 for b in win if 0x20 <= b < 0x7f or b == 0) < 0.6 * len(win):
        return None
    if s == b"" and sum(1 for b in rom[max(0, o - 8):o] if 0x20 <= b < 0x7f) < 4:
        return None                                # "" only at the end of a run of text
    return s


GAP = r'(?:\s|;)+'                                  # a word gap may cross a `; ` line break
HDR_FIXES = [
    # the old "nothing reaches it" wording, and fix_unread_claims.py's interim replacement
    (re.compile(r'(?:that' + GAP + r')?(?:no' + GAP + r'registration' + GAP + r'or' + GAP + r'code' + GAP +
                r'reference' + GAP + r'reaches' + GAP + r'them|code' + GAP + r'DOES' + GAP + r'reach' + GAP +
                r'\(Readers' + GAP + r'below\))' + GAP + r'\(searched:[^)]*\)\.?'),
     "that code reaches: the labels below name each string after the routine that reaches it "
     "first (scripts/converters/split_blobs_at_far_pointers.py)."),
    (re.compile(r'\s*Which' + GAP + r'code' + GAP + r'uses' + GAP + r'them' + GAP + r'is' + GAP + r'not' + GAP +
                r'established\.'), ""),
]


def refresh_header(L, i):
    """The comment block above line i describes the whole run that was just cut: say so."""
    end = i
    if end > 0 and re.match(r'^;\s*-{5,}', L[end - 1]):  # the header's closing rule
        end -= 1
    j = end
    while j > 0 and L[j - 1].lstrip().startswith(";") and not re.match(r'^;\s*-{5,}', L[j - 1]):
        j -= 1
    if j == end:
        return False
    i = end
    blk = "\n".join(L[j:i])
    new = blk
    for pat, rep in HDR_FIXES:
        new = pat.sub(rep, new)
    if new == blk:
        return False
    out = []
    for l in new.split("\n"):
        if l.strip() not in (";", "") or (out and out[-1].strip() != ";"):
            l = l if l.startswith(";") else "; " + l.lstrip()
            while len(l) > 100 and " " in l[2:100]:     # wrap what the substitution lengthened
                k = l.rindex(" ", 2, 100)
                out.append(l[:k])
                l = "; " + l[k + 1:]
            out.append(l)
    L[j:i] = out
    return True


def ptr_table_at(rom, base, addr, lo, hi):
    """Entries of a table of 32-bit pointers into [lo, hi] at addr (>= 2), else 0."""
    o, n = addr - base, 0
    while o + 4 <= len(rom) and lo <= int.from_bytes(rom[o:o + 4], "little") <= hi:
        n, o = n + 1, o + 4
    return n if n >= 2 else 0


def text_token(s):
    t = s.decode("latin-1")
    if t == "":
        return "Empty"
    if t.strip() == "":
        return "Blank%d" % len(t)
    t = re.sub(r'%[-+ #0]*(\d*)(?:\.(\d+))?[hlL]?([a-zA-Z%])',
               lambda m: " Fmt%s%s%s " % (m.group(1), ("p" + m.group(2)) if m.group(2) else "",
                                         "Pct" if m.group(3) == "%" else m.group(3)), t)
    words = re.findall(r'[A-Za-z0-9]+', t)
    if not words:
        words = [PUNCT.get(ch, "Chr%02X" % ord(ch)) for ch in t.strip()][:4]
    tok = "_".join(words)
    if len(tok) > 32:
        out = ""
        for w in words:
            if len(out) + len(w) + 1 > 32:
                break
            out = (out + "_" + w) if out else w
        tok = out or tok[:32]
    if not re.match(r'[A-Za-z_]', tok):
        tok = "N" + tok
    return tok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True, choices=sorted(ROM))
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--report")
    ap.add_argument("--names-from", help="another version's --report: reuse its name for the "
                    "same piece (same labelled anchor slice + offset), when free here")
    a = ap.parse_args()
    elf, tree, (lo, hi) = fp.IMAGES[a.image]
    romfile, base = ROM[a.image]
    rom = open(os.path.join(REPO, romfile), "rb").read()
    files = sorted(glob.glob(os.path.join(REPO, tree, "**", "*.s"), recursive=True))
    syms = fp.elf_symbols(elf)
    addr_of = {n: ad for ad, ns in syms.items() for n in ns}
    texts = {f: open(f, "rb").read().decode("latin-1").split("\n") for f in files}
    col0 = set()
    for f, L in texts.items():
        for l in L:
            m = LABEL.match(l)
            if m:
                col0.add(m.group(1))
    taken = set(col0) | set(addr_of)

    # 1. slices: labelled .incbin slices from the ELF, and the unlabelled ones after them
    slices = []                       # (addr, len, file, line index, label or None, kind, groups)
    for f, L in texts.items():
        i = 0
        while i < len(L):
            m = INCBIN_SAME.match(L[i])
            lab, g, kind = None, None, None
            if m and m.group(1) in addr_of:
                lab, g, kind = m.group(1), m.groups()[1:], "same"
            else:
                m = LABEL.match(L[i])
                if m and L[i].rstrip() == m.group(0) and i + 1 < len(L) and m.group(1) in addr_of:
                    m2 = INCBIN_BARE.match(L[i + 1])
                    if m2:
                        lab, g, kind = m.group(1), m2.groups(), "next"
            if not lab:
                i += 1
                continue
            ad = addr_of[lab]
            ln = int(g[2], 0)
            anchor = (lab, ad)
            slices.append((ad, ln, f, i, lab, kind, g, lab, 0))
            j = i + (1 if kind == "same" else 2)
            ad += ln
            while j < len(L):                          # unlabelled continuation slices
                s = L[j].strip()
                if s == "" or s.startswith(";"):
                    j += 1
                    continue
                m3 = INCBIN_BARE.match(L[j])
                if not m3:
                    break
                ln = int(m3.group(3), 0)
                slices.append((ad, ln, f, j, None, "bare", m3.groups(), anchor[0], ad - anchor[1]))
                ad += ln
                j += 1
            i = j
    slices.sort()
    keys = [s[0] for s in slices]

    def slice_of(v):
        k = bisect.bisect_right(keys, v) - 1
        return slices[k] if k >= 0 and v < slices[k][0] + slices[k][1] else None

    def reader_index():
        idx = {}
        for f, L in texts.items():
            reader = None
            for i, l in enumerate(L):
                m = LABEL.match(l)
                if m and not STRUCTURAL.search(m.group(1)) and m.group(1) in addr_of:
                    reader = m.group(1)
                idx[(f, i)] = reader
        return idx
    rdx = reader_index()

    # 2. targets: far-pointer pushes with no symbol at the pointer, and positional aliases
    targets = collections.defaultdict(list)            # addr -> [(reader addr, reader, how)]
    for f, L in texts.items():
        i = 0
        while i < len(L) - 1:
            m1, m2 = fp.PUSH.match(L[i]), fp.PUSH.match(L[i + 1])
            if m1 and m2:
                h, l = int(m1.group(2), 0), int(m2.group(2), 0)
                v = (h << 16) | l
                if h <= 0xff and lo <= v <= hi and v not in syms:
                    rd = rdx[(f, i)]
                    targets[v].append((addr_of.get(rd, 1 << 30), rd or "?", "push"))
                    i += 2
                    continue
            i += 1
    klass = {}                                          # NAKA class id -> name
    for f, L in texts.items():
        for l in L:
            m = re.match(r'^\s*\.equ\s+NAKA_CLASS_(\w+)\s*,\s*(0x[0-9a-fA-F]+)', l)
            if m:
                klass[int(m.group(2), 16)] = m.group(1)
    role_name = {}                                      # addr -> name its registration implies
    for f, L in texts.items():                          # Reg* macro address arguments
        for i, l in enumerate(L):
            mm, found = fp.reg_macro_addresses(l)
            for k, v in found:
                if not (lo <= v <= hi and v not in syms):
                    continue
                rd = rdx[(f, i)] or "?"
                role = fp.REG_ROLE[mm.group(2)].get(k)
                if role == "proc":
                    continue                            # code: not this tool's to label
                if role in ("table", "count") and v not in role_name:
                    args = [x.strip() for x in mm.group(4).split(",")]
                    a0 = args[0]
                    kind = a0[len("NAKA_CLASS_"):] if a0.startswith("NAKA_CLASS_") else \
                        klass.get(int(a0, 0)) if re.match(r'^(0x[0-9a-fA-F]+|\d+)$', a0) else None
                    ident = args[-1]
                    if kind and re.match(r'^(0x[0-9a-fA-F]+|\d+)$', ident):
                        pre = rd[len("Initialize"):] if rd.startswith("Initialize") and len(rd) > 10 else rd
                        role_name[v] = "%s_%s%s_%03X" % (pre, kind, "Table" if role == "table" else "Count",
                                                         int(ident, 0))
                targets[v].append((addr_of.get(rd, 1 << 30), rd, "macro"))
    aliases = {}                                        # alias -> (addr, file, line)
    alias_note = {}
    for f, L in texts.items():
        for i, l in enumerate(L):
            m = SET.match(l)
            if m and m.group(2) in addr_of:
                aliases[m.group(1)] = (addr_of[m.group(2)] + int(m.group(3), 0), f, i)
                note = re.sub(r'^;\s*(0x[0-9A-Fa-f]{6},?\s*)?', "", m.group(4) or "").strip()
                if note and not note.startswith("historical label"):   # keep what it said
                    alias_note[m.group(1)] = note
    if aliases:
        apat = re.compile(r'(?<![\w.$])(%s)(?![\w$]|\.\w)' % "|".join(map(re.escape, sorted(aliases))))
        for f, L in texts.items():
            for i, l in enumerate(L):
                code = l.split(";", 1)[0]
                if SET.match(l) or LABEL.match(l) and code.rstrip().endswith(":"):
                    continue
                for mm in apat.finditer(code):
                    v = aliases[mm.group(1)][0]
                    rd = rdx[(f, i)]
                    targets[v].append((addr_of.get(rd, 1 << 30), rd or "?", "alias"))

    stats, rows = collections.Counter(), []
    plan = collections.defaultdict(dict)   # slice key -> {offset: (reader, text, nptr, reg, keep)}
    dup_alias = {}
    # a NAMED alias (`.equ DspEffectName_PtrTable, NakaData_WidgetDescriptors + 0x1C1A`) inside a
    # slice becomes the label of its own piece, under its own name
    by_v = collections.defaultdict(list)
    for al, (v, f, i) in aliases.items():
        if not POSITIONAL.search(al):
            by_v[v].append(al)
    for v, als in sorted(by_v.items()):
        sl = slice_of(v)
        if not sl:
            continue
        off = v - sl[0]
        keep = fp.pick(als, col0)
        if off == 0 and sl[4]:
            stats["named-alias-on-a-label"] += 1    # two good names for one address: a human's call
            rows.append({"value": hex(v), "result": "named alias %s on label %s, left" % (keep, sl[4])})
            continue
        plan[(sl[2], sl[3])][off] = ("", None, 0, None, keep)
        stats["named-alias-promoted"] += 1
        rows.append({"value": hex(v), "result": "label", "named": keep})
    for v in sorted(targets):
        rd = sorted(targets[v])[0][1]
        hows = sorted({h for _, _, h in targets[v]})
        row = {"value": hex(v), "reader": rd, "sites": len(targets[v]), "via": hows}
        sl = slice_of(v)
        if not sl:
            stats["not-in-an-incbin-slice"] += 1
            rows.append(dict(row, result="not in an .incbin slice")); continue
        off = v - sl[0]
        if off == 0 and sl[4]:
            stats["already-labelled"] += 1
            for al, (av, _, _) in aliases.items():
                if av == v and al != sl[4] and POSITIONAL.search(al):
                    dup_alias[al] = sl[4]           # a second name for a labelled slice
            continue
        if off in plan.get((sl[2], sl[3]), {}):
            stats["named-alias-there"] += 1
            continue
        where = "slice at %s:%d +0x%x" % (os.path.relpath(sl[2], REPO), sl[3] + 1, off)
        if v in role_name:                              # the registration call says what it is
            plan[(sl[2], sl[3])][off] = (rd, None, 0, role_name[v], None)
            stats["new-label-registered"] += 1
            rows.append(dict(row, result="label", registered=role_name[v])); continue
        if sl[4] and NOT_TEXT.match(sl[4]) or any(NOT_TEXT.match(n) for n in syms.get(sl[0], [])):
            stats["not-text-object"] += 1
            rows.append(dict(row, result=where + ", image/bitmap object")); continue
        npt = ptr_table_at(rom, base, v, lo, hi)
        s = None if npt else c_string_at(rom, base, v)
        if not npt and lo <= int.from_bytes(rom[v - base:v - base + 4], "little") <= hi:
            stats["single-pointer"] += 1           # one pointer field, not a table or text
            rows.append(dict(row, result=where + ", a single 32-bit pointer")); continue
        if npt:
            plan[(sl[2], sl[3])][off] = (rd, None, npt, None, None)
            stats["new-label-ptrtable"] += 1
            rows.append(dict(row, result="label", ptrtable=npt)); continue
        if s is None or (off and rom[v - base - 1] not in (0x00, 0xff)) or \
                (s == b"" and hows == ["alias"]):
            stats["not-a-string-start"] += 1
            rows.append(dict(row, result=where + ", not a string start")); continue
        plan[(sl[2], sl[3])][off] = (rd, s, 0, None, None)
        stats["new-label-string"] += 1
        rows.append(dict(row, result="label", text=s.decode("latin-1")))

    # 3. names, unique across the image
    names, pieces_out = {}, {}
    by_key = {(s[2], s[3]): s for s in slices}
    prefer = json.load(open(a.names_from))["pieces"] if a.names_from else {}
    for key in sorted(plan, key=lambda k: by_key[k][0]):
        for off in sorted(plan[key]):
            rd, s, npt, reg, keep = plan[key][off]
            where = "%s+0x%x" % (by_key[key][7], by_key[key][8] + off)
            if keep:
                names[(key, off)] = pieces_out[where] = keep
                continue
            n = prefer.get(where)
            if n and n in taken:
                stats["names-from-taken"] += 1
                n = None
            if n:
                stats["names-from-used"] += 1
            else:
                stem = reg or ("%s_PtrTable" % rd if npt else "%s_Str_%s" % (rd, text_token(s)))
                n, k = stem, 2
                while n in taken:
                    n, k = "%s_%d" % (stem, k), k + 1
            taken.add(n)
            names[(key, off)] = n
            pieces_out[where] = n
    addr_name = {by_key[k][0] + off: n for (k, off), n in names.items()}

    # 4. rewrite each planned slice, bottom-up per file
    for f in sorted({k[0] for k in plan}):
        L = texts[f]
        for key in sorted((k for k in plan if k[0] == f), key=lambda k: -k[1]):
            ad, ln, _, i, lab, kind, g = by_key[key][:7]
            fname, off0 = g[0], int(g[1], 0)
            com0 = g[3]
            cuts = sorted(set([0]) | set(plan[key]))
            pieces = []
            for c, nxt in zip(cuts, cuts[1:] + [ln]):
                pl = lab if c == 0 and lab else names.get((key, c))
                sl = '.incbin "%s", 0x%X, 0x%X' % (fname, off0 + c, nxt - c)
                com = ""
                if c in plan[key] and plan[key][c][4]:
                    note = alias_note.get(plan[key][c][4])
                    com = "\t; " + note if note else ""
                elif c in plan[key] and plan[key][c][3]:
                    com = ""
                elif c in plan[key] and plan[key][c][2]:
                    com = "\t; %d x 32-bit pointer" % plan[key][c][2]
                elif c in plan[key]:
                    com = "\t; \"%s\"" % plan[key][c][1].decode("latin-1").replace("\\", "\\\\")
                pieces.append((pl, sl, com))
            width = max((len(p[0]) + 1 for p in pieces if p[0]), default=0)
            col = (width // 8 + 1) * 8
            out = []
            for pl, sl, com in pieces:
                if pl:
                    pad = "\t" * max(1, (col - (len(pl) + 1) + 7) // 8)
                    out.append("%s:%s%s%s" % (pl, pad, sl, com))
                else:
                    out.append("\t%s%s" % (sl, com))
            if com0:
                out[0] += "\t" + com0
            if kind == "next":
                L[i:i + 2] = out
            else:
                L[i:i + 1] = out
            stats["slices-split"] += 1
            if lab and refresh_header(L, i):
                stats["headers-refreshed"] += 1

    # 5. retire the aliases that now name a label; their uses take the label's name
    retire = {al: addr_name[v] for al, (v, f, i) in aliases.items() if v in addr_name}
    retire.update(dup_alias)
    if retire:
        rpat = re.compile(r'(?<![\w.$])(%s)(?![\w$]|\.\w)' % "|".join(map(re.escape, sorted(retire))))
        for f, L in texts.items():
            out = []
            for l in L:
                m = SET.match(l)
                if m and m.group(1) in retire:
                    stats["aliases-retired"] += 1
                    continue
                if rpat.search(l):
                    l = rpat.sub(lambda mm: retire[mm.group(1)], l)
                    stats["alias-use-lines"] += 1
                out.append(l)
            texts[f] = out
    if a.apply:
        for f, L in texts.items():
            new = "\n".join(L).encode("latin-1")
            if new != open(f, "rb").read():
                open(f, "wb").write(new)
    print("image %s: %s%s" % (a.image, dict(stats), "" if a.apply else " (dry run)"))
    if a.report:
        json.dump({"rows": rows, "labels": {hex(v): n for v, n in sorted(addr_name.items())},
                   "pieces": pieces_out,
                   "aliases_retired": retire}, open(a.report, "w"), indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
