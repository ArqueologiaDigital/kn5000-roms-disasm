#!/usr/bin/env python3
r"""Regenerate v7's dsp_config_sysex.s .. sprintf_core.s span from the v10 sources.

QUESTION THIS ANSWERS
    v7 maincpu 0xFDA78D-0xFF2153 (audio/dsp_config_sysex.s, which includes
    boot/screen_group_dispatch.s and audio/audioinit_routines.s, then
    audio/note_voice_mapping.s, which includes audio/sprintf_core.s) was ~84 KB
    of `.byte` rows carrying labels transplanted from v10 that sit 0x41A bytes
    above their code (scripts/analysis/v7_label_drift.py).  The same code is
    disassembled and named in v10.  This tool ports the v10 text onto the v7
    bytes by BYTE ALIGNMENT and refuses anything it cannot show byte-identical.

HOW
  1. Address maps of both trees (every byte-emitting line -> address), built
     with scripts/analysis/address_line_map.py's marker technique.
  2. difflib matching blocks between v10 and v7 bytes for two regions:
     A = before the boot/screen_group_dispatch.s include, B = after it up to
     the start of sprintf's erased-flash fill.  The v10 side of each region
     starts HEAD bytes early, so the 0x41A-byte drift head (code whose v10
     source is in the preceding, foreign file) is aligned too.  Equal blocks
     and EQUAL-LENGTH replace spans between them define a piecewise delta.
  3. A v10 line whose bytes all map with one delta is PORTED to v7 address
     a+delta.  Identical bytes: the v10 text is kept.  Different bytes (an
     operand moved between versions): each symbol/number operand whose v10
     value is found little-endian in the line's bytes is replaced by the v7
     value at the same offset; relative branch targets become the v7 raw
     displacement.  Every other v7 byte is emitted as `.byte` (a GAP).
  4. EVERY ported line is verified in isolation: the text with all symbols
     replaced by their required numeric values is assembled by llvm-mc and
     must reproduce the v7 bytes exactly; a line that does not becomes `.byte`.
     A symbolic operand is then kept only if the symbol's v7 value (in the new
     layout, or from the v7 build for names defined elsewhere) equals the
     required value; otherwise the number is written.
  5. Labels: v10 labels of the four span files land at their mapped address;
     a label of a FOREIGN v10 file (the drift heads) is not emitted (its name
     is defined, drifted, in that file's v7 copy).  v7 labels of the span that
     any OTHER v7 file references are kept at their current addresses; if a
     ported v10 label has the same name, the ported one is dropped.
  6. --apply writes the four files, rebuilds v7 and compares with the dump;
     lines still mismatching are demoted to `.byte` and the loop repeats.

RUN
    python3 scripts/converters/port_v10_span_to_v7.py            # analysis only
    python3 scripts/converters/port_v10_span_to_v7.py --apply    # write + verify
    PORT_REPOINT=1 ... --apply, then scripts/converters/repoint_v7_after_port.py: drop the old v7 labels
    other files reference and re-aim those references by address instead.
    PORT_CACHE=<dir> caches the two address maps and the alignment (the v7
    map must be rebuilt -- delete <dir>/v7_map.json -- after the v7 files change).
"""
import argparse
import collections
import difflib
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import address_line_map as alm  # noqa: E402

BASE = 0xE00000
HEAD = 0x480
SPANS = {
    # v7 0xFDA78D-0xFF2153, the 0x41A-drift zone of the audio lane
    "dsp": {"files": ["audio/dsp_config_sysex.s", "audio/audioinit_routines.s",
                      "audio/note_voice_mapping.s", "audio/sprintf_core.s"],
            "foreign": ["boot/screen_group_dispatch.s"],
            "end10": lambda e: e[1] == "audio/sprintf_core.s" and e[3].startswith("Sprintf_FillToEnd:"),
            "end7": lambda e: e[1] == "audio/sprintf_core.s" and ".org 0xfffe80" in e[3],
            "tail": "ERASED FLASH"},
    # v7 tonegen_fileio_handlers.s + audio_control_engine.s (labels aligned,
    # but ~6 KB of .byte and 9 romslice .incbin's)
    "ace": {"files": ["audio/tonegen_fileio_handlers.s", "audio/audio_control_engine.s"],
            "foreign": ["midi/midi_encoder_routines.s", "ui/led_panel_write.s"],
            "end10": None, "end7": None, "tail": None},
    # v7 audio/sndparam_routines.s: 225 v7-only labels and 69 drifted (35 at -0x41A) on 2026-10-03;
    # its last 0x41A bytes are v10 midi/midi_serial_routines.s code (the drift head; "foreign" lists
    # files INCLUDED inside a span, and sndparam_routines.s includes none)
    # sndparam_routines.s + midi_serial_routines.s as one span: the v7 sndparam tail IS the start of
    # v10's serial code, so porting sndparam alone leaves that tail as `.byte`
    "sndser": {"files": ["audio/sndparam_routines.s", "midi/midi_serial_routines.s"],
               "foreign": [], "end10": None, "end7": None, "tail": None},
    "snd": {"files": ["audio/sndparam_routines.s"],
            "foreign": [],
            "end10": None, "end7": None, "tail": None},
}
CFG = SPANS["dsp"]
SPAN = CFG["files"]
CACHE = os.environ.get("PORT_CACHE", "/tmp/claude-1000/lane-audio/port_cache")
MC = alm.MC
NM = alm.NM
OBJCOPY = alm.OBJCOPY
REL = {"jr", "jrl", "calr", "djnz", "djnz16", "djnz8"}
REL_W = {"jr": 1, "djnz": 1, "djnz8": 1, "jrl": 2, "calr": 2, "djnz16": 2}
RESERVED = set("""a w b c d e h l wa bc de hl ix iy iz sp xwa xbc xde xhl xix xiy xiz xsp
    ixl ixh iyl iyh izl izh qa qw qb qc qd qe qh ql qwa qbc qde qhl qix qiy qiz qsp
    ra rw rb rc rd re rh rl t f z nz nc ov nov pl mi ge lt gt le uge ult ugt ule eq ne
    v nv m p sr pc opc i3 io""".split())
IDENT = re.compile(r'(?<![\w.$])([A-Za-z_.$][\w.$]*)')
NUM = re.compile(r'(?<![\w.$])(-?0x[0-9a-fA-F]+|-?\d+)(?![\w.$])')
LABEL = re.compile(r'^([A-Za-z_.$][\w.$]*):')


# --------------------------------------------------------------- maps
def rom(img):
    return open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % img), "rb").read()


def amap(img):
    alm.SRCDIR = os.path.join(ROOT, "%s/maincpu" % img)
    alm.ROOT_S = "kn5000_%s_program.s" % img
    ent, tmp, elf = alm.build()
    pos = {}
    for a, src, line, text in ent:
        rel = os.path.relpath(os.path.join(ROOT, src), alm.SRCDIR)
        pos[(rel, line)] = a
    order = []   # every line (marked or not) of every file, in emission order

    def walk(rel):
        lines = open(os.path.join(alm.SRCDIR, rel), encoding="latin-1").read().split("\n")
        for i, ln in enumerate(lines):
            order.append([pos.get((rel, i + 1)), rel, i + 1, ln])
            m = re.match(r'^\s*\.include\s+"([^"]+)"', ln.split(";")[0])
            if m:
                walk(m.group(1))
    walk(alm.ROOT_S)
    syms = {}
    for line in subprocess.run([NM, "--defined-only", elf], capture_output=True, text=True).stdout.splitlines():
        p = line.split()
        if len(p) == 3 and not p[2].startswith(alm.MARK):
            syms[p[2]] = int(p[0], 16)
    shutil.rmtree(tmp, ignore_errors=True)
    return order, syms


def load(img):
    os.makedirs(CACHE, exist_ok=True)
    f = os.path.join(CACHE, "%s_map.json" % img)
    if os.path.exists(f):
        d = json.load(open(f))
        return d["order"], d["syms"]
    order, syms = amap(img)
    json.dump({"order": order, "syms": syms}, open(f, "w"))
    return order, syms


def fill_sizes(order):
    """Give every line an address (inherit the next marked one) and a size."""
    nxt = None
    for e in reversed(order):
        if e[0] is None:
            e[0] = nxt
        else:
            nxt = e[0]
    marked = [i for i, e in enumerate(order) if e[0] is not None]
    size = [0] * len(order)
    for k, i in enumerate(marked):
        code = order[i][3].split(";")[0].strip()
        body = LABEL.sub("", code).strip()
        if not body or body.startswith(".include"):
            continue
        j = marked[k + 1] if k + 1 < len(marked) else None
        size[i] = (order[j][0] - order[i][0]) if j is not None else 0
    return size


# --------------------------------------------------------------- alignment
def blocks_for(r10, r7, a10, b10, a7, b7, tag):
    f = os.path.join(CACHE, "match2_%s_%x_%x_%x_%x.json" % (tag, a10, b10, a7, b7))
    if os.path.exists(f):
        return [tuple(x) for x in json.load(open(f))]
    sm = difflib.SequenceMatcher(None, r10[a10 - BASE:b10 - BASE], r7[a7 - BASE:b7 - BASE], autojunk=False)
    bl = [(a10 + i, a7 + j, n) for i, j, n in sm.get_matching_blocks() if n]
    json.dump(bl, open(f, "w"))
    return bl


def delta_map(blocks, a10, b10, a7, b7):
    """-> dict v10addr -> delta for every mapped v10 byte (equal blocks and
    equal-length replace gaps between them)."""
    dm = {}
    i, j = a10, a7
    for (x, y, n) in list(blocks) + [(b10, b7, 0)]:
        di, dj = x - i, y - j
        if di and di == dj:
            for k in range(di):
                dm[i + k] = j - i
        for k in range(n):
            dm[x + k] = y - x
        i, j = x + n, y + n
    return dm


# --------------------------------------------------------------- line parsing
def split_line(text):
    """-> (labels, body, comment)."""
    code, sep, com = text.partition(";")
    # a ';' inside a string literal is rare in these files; guard anyway
    if code.count('"') % 2 == 1:
        code, com = text, ""
    labels = []
    rest = code
    while True:
        m = LABEL.match(rest.strip())
        if not m:
            break
        labels.append(m.group(1))
        rest = rest.strip()[m.end():]
    return labels, rest.strip(), (";" + com) if sep and com is not None and text.count(";") else ""


def operands(body):
    p = body.split(None, 1)
    return (p[0].lower(), p[1] if len(p) > 1 else "")


def le(b, off, w):
    return int.from_bytes(b[off:off + w], "little")


def sval(v, w):
    return v - (1 << (8 * w)) if v >= 1 << (8 * w - 1) else v


# --------------------------------------------------------------- verification by assembly
def assemble_lines(texts):
    """Assemble each text (one instruction/directive) in isolation, in one
    llvm-mc run; -> list of bytes or None when it did not assemble."""
    d = tempfile.mkdtemp(prefix="port-")
    src = ['\t.include "shared/macros.s"', "\t.text"]
    for i, t in enumerate(texts):
        src.append("__t%d:" % i)
        src.append("\t" + t)
    src.append("__t%d:" % len(texts))
    open(os.path.join(d, "t.s"), "w", encoding="latin-1").write("\n".join(src) + "\n")
    r = subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-I", os.path.join(ROOT, "v7/maincpu"),
                        "-o", os.path.join(d, "t.o"), os.path.join(d, "t.s")], capture_output=True, text=True)
    if r.returncode != 0:
        bad = set()
        for m in re.finditer(r't\.s:(\d+):\d+: error', r.stderr):
            ln = int(m.group(1))
            bad.add((ln - 4) // 2)
        shutil.rmtree(d)
        return None, bad
    subprocess.run([OBJCOPY, "-O", "binary", "-j", ".text", os.path.join(d, "t.o"), os.path.join(d, "t.bin")],
                   check=True)
    blob = open(os.path.join(d, "t.bin"), "rb").read()
    off = {}
    for line in subprocess.run([NM, os.path.join(d, "t.o")], capture_output=True, text=True).stdout.splitlines():
        p = line.split()
        if len(p) == 3 and p[2].startswith("__t"):
            off[int(p[2][3:])] = int(p[0], 16)
    shutil.rmtree(d)
    out = []
    for i in range(len(texts)):
        out.append(blob[off[i]:off[i + 1]] if i in off and i + 1 in off else None)
    return out, set()


def assemble_all(texts):
    """assemble_lines, retrying without lines that fail to assemble at all."""
    idx = list(range(len(texts)))
    dead = set()
    for _ in range(50):
        live = [i for i in idx if i not in dead]
        res, bad = assemble_lines([texts[i] for i in live])
        if res is not None:
            out = [None] * len(texts)
            for k, i in enumerate(live):
                out[i] = res[k]
            return out
        if not bad:
            return [None] * len(texts)
        for b in bad:
            if 0 <= b < len(live):
                dead.add(live[b])
    return [None] * len(texts)


# --------------------------------------------------------------- main build
class Port:
    def __init__(self):
        self.r10, self.r7 = rom("v10"), rom("v7")
        self.o10, self.s10 = load("v10")
        self.o7, self.s7 = load("v7")
        self.z10 = fill_sizes(self.o10)
        self.z7 = fill_sizes(self.o7)

    # ---- bounds
    def bounds(self, order, img):
        first = next(i for i, e in enumerate(order) if e[1] == SPAN[0])
        incs, i = [], first
        for f in CFG["foreign"]:
            inc = next(k for k in range(i, len(order)) if order[k][1] in SPAN
                       and ".include" in order[k][3] and f in order[k][3])
            fore = [k for k in range(inc, len(order)) if order[k][1] == f]
            incs.append((inc, fore[-1] + 1))
            i = fore[-1] + 1
        end = CFG["end10"] if img == "v10" else CFG["end7"]
        if end is not None:
            last = next(k for k in range(first, len(order)) if end(order[k]))
        else:
            last = None
            for k in range(first, len(order)):
                e = order[k]
                if e[1] in SPAN or e[1] in CFG["foreign"]:
                    continue
                t = e[3].strip()
                if not t or t.startswith(";"):
                    continue
                m = re.match(r'^\.include\s+"([^"]+)"', t)
                if m and m.group(1) in SPAN:
                    continue
                last = k
                break
        return {"first": first, "incs": incs, "last": last}

    def run(self, verbose=True):
        b10, b7 = self.bounds(self.o10, "v10"), self.bounds(self.o7, "v7")
        o10, o7 = self.o10, self.o7
        V10A, V10E = o10[b10["first"]][0] - HEAD, o10[b10["last"]][0]
        # v7 segments between the foreign includes; the foreign files' own
        # bytes are left out of the alignment entirely.
        cuts = [o7[b7["first"]][0]]
        for inc, after in b7["incs"]:
            cuts += [o7[inc][0], o7[after][0]]
        cuts.append(o7[b7["last"]][0])
        segs = [(cuts[k], cuts[k + 1]) for k in range(0, len(cuts), 2)]
        self.segs7 = segs
        self.R = {"%d" % k: (V10A, V10E, lo, hi) for k, (lo, hi) in enumerate(segs)}
        self.b10, self.b7 = b10, b7
        seq7 = b"".join(self.r7[lo - BASE:hi - BASE] for lo, hi in segs)
        starts, acc = [], 0
        for lo, hi in segs:
            starts.append(acc)
            acc += hi - lo
        junctions = starts[1:]

        def addr7(j):
            k = max(x for x in range(len(starts)) if starts[x] <= j)
            return segs[k][0] + (j - starts[k])
        key = "_".join("%x" % x for x in [V10A, V10E] + cuts)
        f = os.path.join(CACHE, "match4_%s.json" % key)
        if os.path.exists(f):
            bl = [tuple(x) for x in json.load(open(f))]
        else:
            sm = difflib.SequenceMatcher(None, self.r10[V10A - BASE:V10E - BASE], seq7, autojunk=False)
            bl = [(i, j, n) for i, j, n in sm.get_matching_blocks() if n]
            json.dump(bl, open(f, "w"))
        blocks = []
        for i, j, n in bl:
            cut = [x for x in junctions if j < x < j + n]
            for x in cut:
                k = x - j
                blocks.append((i, j, k))
                i, j, n = i + k, x, n - k
            blocks.append((i, j, n))
        dm = {}
        pi, pj = 0, 0
        for (i, j, n) in blocks + [(V10E - V10A, len(seq7), 0)]:
            di, dj = i - pi, j - pj
            if di and di == dj and not any(pj < x < j for x in junctions):
                for k in range(di):
                    dm[V10A + pi + k] = addr7(pj + k) - (V10A + pi + k)
            for k in range(n):
                dm[V10A + i + k] = addr7(j + k) - (V10A + i + k)
            pi, pj = i + n, j + n
        self.dm = dm
        rows = []
        for i, (a, rel, ln, text) in enumerate(o10):
            if a is None:
                continue
            if V10A <= a < V10E or (a == V10E and self.z10[i] == 0 and rel in SPAN and i < b10["last"]):
                rows.append(("X", i))
        self.rows = rows
        return self

    # ---- per line mapping
    def map_line(self, i):
        a, rel, ln, text = self.o10[i]
        n = self.z10[i]
        if n == 0:
            d = self.dm.get(a)
            return (a + d) if d is not None else None
        ds = {self.dm.get(a + k) for k in range(n)}
        if len(ds) != 1 or None in ds:
            return None
        return a + ds.pop()



# --------------------------------------------------------------- emission
def old_v7_labels(P):
    """labels currently defined in the four v7 span files -> v7 address."""
    out = {}
    for (a, rel, ln, text) in P.o7:
        if rel in SPAN and a is not None:
            for lab in split_line(text)[0]:
                out[lab] = a
    return out


def v7_defs_elsewhere():
    """names defined (label or .set/.equ) in v7 files OUTSIDE the span."""
    names = set()
    for f in glob.glob(os.path.join(ROOT, "v7/maincpu/**/*.s"), recursive=True):
        rel = os.path.relpath(f, os.path.join(ROOT, "v7/maincpu"))
        if rel in SPAN:
            continue
        for ln in open(f, encoding="latin-1"):
            code = ln.split(";")[0]
            m = LABEL.match(code.strip())
            if m:
                names.add(m.group(1))
            m = re.match(r'^\s*\.(?:set|equ)\s+([A-Za-z_.$][\w.$]*)\s*,', code)
            if m:
                names.add(m.group(1))
    return names


def external_refs(old):
    """old span labels referenced from any v7 file outside the span
    -> {name: set(files)}.  Text inside string literals is not a reference."""
    keep = collections.defaultdict(set)
    tok = re.compile(r'[A-Za-z_.$][\w.$]*')
    for f in glob.glob(os.path.join(ROOT, "v7/maincpu/**/*"), recursive=True):
        if not f.endswith((".s", ".c", ".ld", ".h")):
            continue
        rel = os.path.relpath(f, os.path.join(ROOT, "v7/maincpu"))
        if rel in SPAN:
            continue
        for ln in open(f, encoding="latin-1"):
            code = ln.split(";")[0] if f.endswith(".s") else ln
            code = re.sub(r'"(?:[^"\\]|\\.)*"', '""', code)
            for t in tok.findall(code):
                if t in old:
                    keep[t].add(rel)
    return keep


OBSOLETE = ("=== end v7 block ===", "v7: First part replaced by .incbin",
            # proven false by unidasm and by re-assembly: v7 0xFF13F5 is
            # `add wa,(xsp+0x14)` and 0xFF1B1C is `pushw (xsp+0x06)`
            "; sub (xsp + 10), iz (v7 displacement)", "; decm 1, (xsp + 18) (v7 displacement)")


def _obsolete_note(c):
    import importlib.util
    spec = importlib.util.spec_from_file_location("dropnotes", os.path.join(os.path.dirname(os.path.dirname(
        os.path.abspath(__file__))), "tools", "drop_obsolete_v7_port_notes.py"))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m.obsolete(c)


def carry_old_v7_comments(P):
    """Every comment of the pre-port v7 span files that is not part of a file
    header (kept by write_files) is re-emitted at the address it annotated,
    under a lead-in line saying so.  Two comments that describe the removed
    romslice/transplant layout (OBSOLETE) are not carried."""
    started = set()
    tail = False
    for (a, rel, ln, text) in P.o7:
        if rel not in SPAN:
            continue
        labels, body, com = split_line(text)
        whole = text.strip().startswith(";")
        if CFG["tail"] and rel == SPAN[-1] and CFG["tail"] in text:
            tail = True
        if CFG["tail"] and rel == SPAN[-1] and tail:
            continue
        if body or labels:
            started.add(rel)
        if rel not in started:
            continue                      # file header: write_files keeps it
        c = text.strip() if whole else (com.strip() if com else "")
        # and the raw-byte-era notes scripts/tools/drop_obsolete_v7_port_notes.py removed (2026-10-03):
        # they described the transcription this port replaces and are false after it
        if not c or any(o in c for o in OBSOLETE) or a is None or _obsolete_note(c):
            continue
        lst = P.notes[a]
        lead = "; (pre-port v7 note about the bytes at 0x%06X:)" % a
        if lead not in lst:
            lst.append(lead)
        lst.append(c)


class Item:
    __slots__ = ("a7", "n", "kind", "text", "labels", "comments", "src", "i10", "test")

    def __init__(self, a7, n, kind, text, src, i10=None):
        self.a7, self.n, self.kind, self.text, self.src, self.i10 = a7, n, kind, text, src, i10
        self.labels, self.comments, self.test = [], [], None


def build_items(P, demoted=frozenset()):
    old = old_v7_labels(P)
    keep = external_refs(old)
    elsewhere = v7_defs_elsewhere()
    # v10 symbol values (ELF + every label line of the tree, for .L labels)
    sv10 = dict(P.s10)
    for (a, rel, ln, text) in P.o10:
        if a is not None:
            for lab in split_line(text)[0]:
                sv10.setdefault(lab, a)
    items = []
    P.orphans = collections.defaultdict(list)
    pending_comments = []
    pending_src = None
    pending_labels = []            # (name, v10 addr)
    seen_code = set()              # v10 files whose first byte line has been seen
    for k, i in P.rows:
        a10, rel, ln, text = P.o10[i]
        labels, body, com = split_line(text)
        in_span = rel in SPAN
        header = in_span and rel not in seen_code
        if in_span and not header and not body and not labels and text.strip().startswith(";"):
            pending_comments.append(("post" if pending_labels else "line", text.rstrip()))
            pending_src = rel
        for lab in labels:
            if in_span:
                pending_labels.append((lab, a10))
        if not body or body.startswith(".include"):
            if com and not header and in_span and labels:
                pending_comments.append(("post", com.rstrip()))
                pending_src = rel
            continue
        n = P.z10[i]
        if n == 0:
            continue
        if pending_comments and pending_src != rel:
            # a comment trailing file F must not migrate into the next file:
            # emit it at this address, but as a note of F
            d = P.dm.get(a10)
            if d is not None:
                P.orphans[a10 + d].extend(c for _, c in pending_comments)
            pending_comments = []
        seen_code.add(rel) if in_span else None
        a7 = P.map_line(i)
        it = None
        if a7 is not None and i not in demoted:
            b10 = P.r10[a10 - BASE:a10 - BASE + n]
            b7 = P.r7[a7 - BASE:a7 - BASE + n]
            it = Item(a7, n, "same" if b10 == b7 else "diff", body, rel, i)
            if com:
                it.comments.append(("trail", com.rstrip()))
        # labels / comments attach to the address they precede
        for lab, la in pending_labels:
            d = P.dm.get(la)
            if d is not None:
                items.append(Item(la + d, 0, "label", lab, rel))
        pending_labels = []
        if it is not None:
            it.comments = list(pending_comments) + it.comments
            items.append(it)
        elif pending_comments:
            # a v10 comment whose line did not port still goes where its
            # address maps, if it maps
            d = P.dm.get(a10)
            if d is not None:
                P.orphans[a10 + d].extend(c for _, c in pending_comments)
        pending_comments = []
    return items, old, keep, elsewhere, sv10


def resolve(P, items, old, keep, elsewhere, sv10, verbose=True):
    """Decide final text of every ported line; returns (layout labels, stats)."""
    newlab = {}      # name -> v7 addr
    dropped = collections.Counter()
    P.notes = collections.defaultdict(list)
    for a, lst in getattr(P, "orphans", {}).items():
        P.notes[a].extend(lst)
    carry_old_v7_comments(P)
    for it in items:
        if it.kind != "label":
            continue
        nm = it.text
        if nm in keep:
            dropped["kept-v7-name-wins"] += 1
            if old[nm] != it.a7:
                P.notes[it.a7].append("; v10 name for this address: %s -- not a label here: v7 keeps that"
                                      " name at 0x%06X for %s" % (nm, old[nm], ", ".join(sorted(keep[nm]))))
                P.notes[old[nm]].append("; %s is kept at this address only for %s; v10's %s is the"
                                        " code at 0x%06X" % (nm, ", ".join(sorted(keep[nm])), nm, it.a7))
            continue
        if nm in elsewhere:
            dropped["defined-elsewhere-in-v7"] += 1
            v = P.s7.get(nm)
            P.notes[it.a7].append("; v10 name for this address: %s -- not a label here: v7 defines that"
                                  " name outside this span%s" % (nm, (" (= 0x%06X)" % v) if v else ""))
            continue
        if nm in newlab and newlab[nm] != it.a7:
            dropped["duplicate"] += 1
            continue
        newlab[nm] = it.a7
    for nm in keep:
        newlab[nm] = old[nm]
    # v7 values of names outside the span (ELF), minus the old span labels
    ext7 = {k: v for k, v in P.s7.items() if k not in old}
    by_addr = collections.defaultdict(list)
    for nm, v in newlab.items():
        by_addr[v].append(nm)

    def v7val(nm):
        if nm in newlab:
            return newlab[nm]
        return ext7.get(nm)

    tests = []
    for it in items:
        if it.kind == "label":
            continue
        mnem, ops = operands(it.text)
        b10 = P.r10[P.o10[it.i10][0] - BASE:P.o10[it.i10][0] - BASE + it.n]
        b7 = P.r7[it.a7 - BASE:it.a7 - BASE + it.n]
        rel = mnem in REL
        toks = []
        quoted = [(m.start(), m.end()) for m in re.finditer(r'"(?:[^"\\]|\\.)*"', ops)]

        def inq(x):
            return any(q0 <= x < q1 for q0, q1 in quoted)
        for m in IDENT.finditer(ops):
            if inq(m.start()):
                continue
            nm = m.group(1)
            if nm.lower() in RESERVED:
                continue
            if nm in sv10:
                toks.append((m.start(), m.end(), "sym", nm, sv10[nm]))
        for m in NUM.finditer(ops):
            if inq(m.start()):
                continue
            if m.start() > 0 and ops[m.start() - 1] == ":":
                continue
            v = int(m.group(1), 0)
            toks.append((m.start(), m.end(), "num", m.group(1), v))
        toks.sort()
        # the relative-branch target is the LAST operand token
        new_ops, test_ops, pos = [], [], 0
        ok = True
        for (s, e, kind, raw, v10) in toks:
            new_ops.append(ops[pos:s])
            test_ops.append(ops[pos:s])
            pos = e
            is_target = rel and (s, e) == (toks[-1][0], toks[-1][1])
            if is_target:
                w = REL_W.get(mnem, 1)
                disp = sval(le(b7, it.n - w, w), w)
                tgt = it.a7 + it.n + disp
                test_ops.append(str(disp))
                names = [x for x in by_addr.get(tgt, [])]
                if kind == "sym" and v7val(raw) == tgt:
                    new_ops.append(raw)
                elif names:
                    new_ops.append(sorted(names)[0])
                else:
                    new_ops.append(str(disp))
                continue
            req = v10
            if it.kind == "diff":
                # find the token's v10 value in the bytes, at an offset that differs
                found = None
                for w in (4, 3, 2, 1):
                    if v10 < 0 or v10 >= 1 << (8 * w):
                        continue
                    offs = [o for o in range(it.n - w + 1) if le(b10, o, w) == v10]
                    offs = [o for o in offs if b10[o:o + w] != b7[o:o + w]]
                    if len(offs) == 1:
                        found = (offs[0], w)
                        break
                if found:
                    req = le(b7, found[0], found[1])
            test_ops.append(hex(req) if req >= 0 else str(req))
            if kind == "sym" and v7val(raw) == req:
                new_ops.append(raw)
            elif kind == "sym" and by_addr.get(req):
                new_ops.append(sorted(by_addr[req])[0])
            elif kind == "num":
                new_ops.append(raw if req == v10 else hex(req))
            else:
                new_ops.append(hex(req))
        new_ops.append(ops[pos:])
        test_ops.append(ops[pos:])
        sep = "\t" if ops else ""
        body_mn = it.text.split(None, 1)[0]
        it.test = body_mn + (" " + "".join(test_ops) if ops else "")
        newtext = body_mn + (sep + "".join(new_ops) if ops else "")
        tests.append((it, newtext, b7))
    enc = assemble_all([t[0].test for t in tests])
    bad = 0
    for (it, newtext, b7), got in zip(tests, enc):
        if got == b7:
            it.text = newtext
        else:
            it.kind = "gap"
            bad += 1
    if verbose:
        print("  ported lines: %d, failed isolated re-assembly -> .byte: %d" % (len(tests), bad))
        print("  label decisions:", dict(dropped), " kept v7 names:", len(keep))
    return newlab


# --------------------------------------------------------------- layout + writer
def byte_rows(bs):
    out = []
    for k in range(0, len(bs), 8):
        out.append("\t.byte " + ", ".join("0x%02x" % x for x in bs[k:k + 8]))
    return out


SUFFIX = re.compile(r'^(.*?)(_(?:Skip|Loop|Join|Return|Exit|Done|Next)\d*)$')
TOKEN = re.compile(r'(?<![\w.$@])([A-Za-z_][\w.$@]*)(?![\w.$@])')
DATA_DIR = re.compile(r'^\.(byte|short|hword|2byte|long|word|4byte)\b')


def old_span_symbols(P):
    """name -> v7 address for every label and `.set` the pre-port span files defined."""
    if not hasattr(P, "_olddefs"):
        names = set()
        rows = []
        for idx, (ad, rel, ln, text) in enumerate(P.o7):
            if rel not in SPAN:
                continue
            m = LABEL.match(text) or re.match(r'^\s*\.set\s+([A-Za-z_][\w.$@]*)\s*,', text)
            if m:
                names.add(m.group(1))
            if ad is not None:
                rows.append((ad, P.z7[idx], text))
        P._olddefs = {n: P.s7[n] for n in names if n in P.s7}
        P._old7 = rows
    return P._olddefs


def keep_old_labels(P, newlab, code):
    """PORT_GAPFILL: the pre-port labels (`NAME:` lines) at addresses no new label holds and no
    ported instruction covers -- they head v7 code the port could not match to v10 and will refill
    from the old lines.  A label keeps its old name unless that name, or its stem before a
    structural suffix (`_Skip2`), now names a v10 label placed elsewhere, or is a v10 name whose
    v10 bytes are found at another v7 address nearby (drifted(), v7_label_drift.py's test); then it
    is renamed under the nearest new label at or before it (`INTTX0_HANDLER_Skip2`)."""
    olddefs = old_span_symbols(P)
    import bisect as _b
    starts = [it.a7 for it in code]
    inside = lambda v: (lambda k: k >= 0 and code[k].a7 < v < code[k].a7 + code[k].n)(_b.bisect_right(starts, v) - 1)
    held = set(newlab.values())
    stems = sorted(set(newlab.values()))
    first = {}
    for nm, v in newlab.items():
        first.setdefault(v, nm)
        first[v] = min(first[v], nm)
    def drifted(name, ad):
        """v10 defines `name`: is it a DRIFTED name here?  The test of scripts/analysis/
        v7_label_drift.py: v10's bytes at `name` found exactly once near this v7 address, but at a
        different one.  Not found (v7's code differs there, operands moved): kept -- the pre-port
        file placed it, and nothing shows it wrong."""
        s10 = P.s10.get(name)
        if s10 is None:
            return False
        sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
        import v7_label_drift as _D
        hit = _D.locate(P.r10, P.r7, s10, ad)
        return hit is not None and hit != ad
    extra, used = {}, set(newlab)
    for ad, n, text in sorted(P._old7):
        m = LABEL.match(text)
        if not m or ad in held or inside(ad):
            continue
        nm = m.group(1)
        sm = SUFFIX.match(nm)
        stem = sm.group(1) if sm else nm
        if nm in newlab or stem in newlab or nm in used or drifted(nm, ad):
            k = _b.bisect_right(stems, ad) - 1
            if k < 0:
                continue
            base = first[stems[k]] + (sm.group(2) if sm else "_Part")
            new, i = base, 2
            while new in used:
                new, i = "%s_%d" % (base, i), i + 1
        else:
            new = nm
        used.add(new)
        extra[nm] = (ad, new)
    return extra


def gap_fill(P, a, end, labels_at, extra):
    """The pre-port v7 lines for the gap [a, end), when they TILE it exactly; else None.

    A gap is v7 code (or data) with no byte-identical v10 line.  Emitting it as `.byte` would throw
    away the instructions the pre-port file already had (CLAUDE.md: never replace disassembled code
    with raw bytes) -- e.g. v7's INTTX0 handler at 0xFCE98A.  So the old lines are reused when their
    instructions and data rows (.byte/.short/.long) cover [a, end) exactly; `.set X, . + k` aliases
    are dropped; label lines are not copied (keep_old_labels put them in labels_at, so the gap is
    split at them); an operand naming an old span symbol is re-aimed by ADDRESS at the label that
    stands there now, and if none does the gap stays `.byte`."""
    if not hasattr(P, "_gapwhy"):
        P._gapwhy = collections.Counter()
    olddefs = old_span_symbols(P)
    ent = [r for r in P._old7 if a <= r[0] < end]
    if not ent:
        P._gapwhy["no old lines"] += 1
        return None
    name_at = {v: sorted(ns)[0] for v, ns in labels_at.items() if ns}
    ren = {o: nw for o, (v, nw) in extra.items()}

    def sub(mm):
        t = mm.group(1)
        if t in ren:
            return ren[t]
        if t in olddefs:
            there = name_at.get(olddefs[t])
            if there is None:
                if os.environ.get("PORT_GAPDEBUG"):
                    print("    gap 0x%06X-0x%06X: operand %s (old 0x%06X) has no label now" % (a, end, t, olddefs[t]))
                raise KeyError(t)
            return there
        return t
    out, pos = [], a
    for ad, n, text in ent:
        m = LABEL.match(text)
        if m:
            text = text[m.end():]
        code = text.split(";")[0].strip()
        if not code or code.startswith(".set"):
            continue
        if code.startswith(".") and not DATA_DIR.match(code):
            if os.environ.get("PORT_GAPDEBUG"):
                print("    gap 0x%06X-0x%06X: directive %s" % (a, end, code[:60]))
            P._gapwhy["directive"] += 1
            return None
        if ad != pos or n <= 0:
            P._gapwhy["not tiling"] += 1
            return None
        try:
            mn, sep, ops = re.match(r'^(\S+)(\s*)(.*)$', code).groups()
            code = mn + ("\t" + TOKEN.sub(sub, ops) if ops else "")
        except KeyError:
            P._gapwhy["operand with no label"] += 1
            return None
        out.append("\t" + code)
        pos += n
    if pos != end:
        P._gapwhy["short"] += 1
        return None
    P._gapwhy["filled"] += 1
    return out


def layout(P, items, old, keep, newlab):
    """-> {file: [lines]} and per-emitted-line (addr, size, item) for the verify loop."""
    r7 = P.r7
    labels_at = collections.defaultdict(set)
    for nm, v in newlab.items():
        labels_at[v].add(nm)
    code = sorted([it for it in items if it.kind in ("same", "diff", "gap")], key=lambda it: it.a7)
    # drop overlaps and code items that would split a kept label
    clean, last_end = [], None
    for it in code:
        if last_end is not None and it.a7 < last_end:
            it.kind = "gap"
            continue
        if any(it.a7 < v < it.a7 + it.n for v in labels_at):
            it.kind = "gap"
        clean.append(it)
        last_end = it.a7 + it.n
    code = [it for it in clean if it.kind in ("same", "diff")]
    starts = [it.a7 for it in code]
    import bisect as _b
    for v in sorted(list(getattr(P, "notes", {}).keys())):
        k = _b.bisect_right(starts, v) - 1
        if k >= 0 and code[k].a7 < v < code[k].a7 + code[k].n:
            P.notes[code[k].a7] = P.notes[code[k].a7] + P.notes.pop(v)
    extra = keep_old_labels(P, newlab, code) if os.environ.get("PORT_GAPFILL") else {}
    for o, (v, nw) in extra.items():
        labels_at[v].add(nw)
    regions = [(k, lo, hi) for k, (lo, hi) in enumerate(P.segs7)]
    files = {f: [] for f in SPAN}
    emitted = []
    order = {f: k for k, f in enumerate(SPAN)}
    cur = SPAN[0]
    used_gap = set()
    for tag, lo, hi in regions:
        a = lo
        region_code = [it for it in code if lo <= it.a7 < hi]
        j = 0
        while a < hi:
            nxt_code = region_code[j] if j < len(region_code) else None
            if nxt_code is not None and nxt_code.a7 == a:
                it = nxt_code
                # carried pre-port notes stay in the file they came from (the
                # one current BEFORE this item), and a note identical to the
                # item's own (v10) comment is not repeated
                own = {c.strip() for k2, c in it.comments}
                allnotes = [c for c in getattr(P, "notes", {}).get(a, []) if c.strip() not in own]
                gen = [c for c in allnotes if c.startswith("; v10 name for this address:")
                       or " is kept at this address only for " in c]
                notes = [c for c in allnotes if c not in gen]
                if notes and not any(not c.startswith("; (pre-port v7 note") for c in notes):
                    notes = []
                files[cur].extend(notes)
                if it.src in order and order[it.src] >= order[cur]:
                    cur = it.src
                files[cur].extend(gen)
                files[cur].extend(c for kind, c in it.comments if kind == "line")
                for nm in sorted(labels_at.get(a, ())):
                    files[cur].append("%s:" % nm)
                files[cur].extend(c for kind, c in it.comments if kind == "post")
                trail = [c for k2, c in it.comments if k2 == "trail"]
                files[cur].append("\t" + it.text + (("\t" + trail[0]) if trail else ""))
                emitted.append((a, it.n, it))
                a += it.n
                j += 1
                continue
            stop = nxt_code.a7 if nxt_code is not None else hi
            # labels inside the gap split it
            inner = sorted(v for v in set(labels_at) | set(getattr(P, "notes", {})) if a < v < stop)
            end = inner[0] if inner else stop
            files[cur].extend(getattr(P, "notes", {}).get(a, []))
            for nm in sorted(labels_at.get(a, ())):
                files[cur].append("%s:" % nm)
            rows = gap_fill(P, a, end, labels_at, extra) if os.environ.get("PORT_GAPFILL") else None
            if rows is None:
                rows = byte_rows(r7[a - BASE:end - BASE])
            files[cur].extend(rows)
            emitted.append((a, end - a, None))
            a = end
        if tag < len(regions) - 1:
            files[cur].append('\t.include "%s"' % CFG["foreign"][tag])
    if getattr(P, "_gapwhy", None):
        print("  gap fill: %s" % dict(P._gapwhy))
    return files, emitted


PORT_NOTE = [
    "; Ported from v10 by scripts/converters/port_v10_span_to_v7.py: every",
    "; instruction below was re-assembled to the v7 bytes; `.byte` rows are v7",
    "; bytes with no byte-identical v10 counterpart.  Comments carried over",
    "; from v10 may cite v10 addresses."]


def header_of(lines):
    h = []
    for ln in lines:
        if ln.strip().startswith(";") or not ln.strip():
            h.append(ln)
        else:
            break
    while h and not h[-1].strip():
        h.pop()
    return h


def write_files(P, files):
    if CFG is not SPANS["dsp"]:          # the dsp writer is specific to that span's includes
        return write_files_ace(P, files)
    v7 = os.path.join(ROOT, "v7/maincpu")
    old = {f: open(os.path.join(v7, f), encoding="latin-1").read().split("\n") for f in SPAN}

    def header(lines):
        h = []
        for ln in lines:
            if ln.strip().startswith(";") or not ln.strip():
                h.append(ln)
            else:
                break
        while h and not h[-1].strip():
            h.pop()
        return h
    dsp = header(old[SPAN[0]]) + [
        "; Ported from v10 by scripts/converters/port_v10_span_to_v7.py: every",
        "; instruction below was re-assembled to the v7 bytes; `.byte` rows are v7",
        "; bytes with no byte-identical v10 counterpart.  Comments carried over",
        "; from v10 may cite v10 addresses.", ""]
    body = files[SPAN[0]]
    dsp += body + ['\t.include "audio/audioinit_routines.s"']
    ai = files[SPAN[1]]
    nvm = header(old[SPAN[2]]) + [
        "; Ported from v10 by scripts/converters/port_v10_span_to_v7.py (see the",
        "; header of audio/dsp_config_sysex.s).", ""] + files[SPAN[2]] + ['\t.include "audio/sprintf_core.s"']
    sp_old = old[SPAN[3]]
    tail_at = next(k for k, ln in enumerate(sp_old) if "ERASED FLASH" in ln) - 1
    sp = header(sp_old) + [""] + files[SPAN[3]] + sp_old[tail_at:]
    out = {SPAN[0]: dsp, SPAN[1]: ai, SPAN[2]: nvm, SPAN[3]: sp}
    for f, lines in out.items():
        data = "\n".join(lines)
        if not data.endswith("\n"):
            data += "\n"
        open(os.path.join(v7, f), "wb").write(data.encode("latin-1"))


def write_files_ace(P, files):
    v7 = os.path.join(ROOT, "v7/maincpu")
    for f in SPAN:
        old = open(os.path.join(v7, f), encoding="latin-1").read().split("\n")
        lines = header_of(old) + PORT_NOTE + [""] + files[f]
        data = "\n".join(lines)
        if not data.endswith("\n"):
            data += "\n"
        raw = data.encode("latin-1")         # encode first: open("wb") truncates
        open(os.path.join(v7, f) + ".tmp", "wb").write(raw)
        os.replace(os.path.join(v7, f) + ".tmp", os.path.join(v7, f))


def build_v7():
    r = subprocess.run(["make", "rebuilt_ROMs/kn5000_v7_program.llvm.rom"], cwd=ROOT,
                       capture_output=True, text=True)
    if r.returncode != 0:
        return None, (r.stderr or r.stdout)[-3000:]
    return open(os.path.join(ROOT, "rebuilt_ROMs/kn5000_v7_program.llvm.rom"), "rb").read(), ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--span", default="dsp", choices=sorted(SPANS))
    a = ap.parse_args()
    global CFG, SPAN
    CFG = SPANS[a.span]
    SPAN = CFG["files"]
    P = Port().run()
    for k, v in P.R.items():
        print("region %s v10 0x%06X-0x%06X  v7 0x%06X-0x%06X" % ((k,) + v))
    demoted = set()
    for it_round in range(8):
        items, old, keep, elsewhere, sv10 = build_items(P, frozenset(demoted))
        if os.environ.get("PORT_REPOINT"):
            # PORT_REPOINT=1: an old v7 label that other files reach ONLY as `Name + k` is a drifted
            # base, not an entry point -- it sits 0x41A off and v10's name belongs elsewhere -- so it
            # is not kept; scripts/converters/repoint_v7_after_port.py then re-aims those references
            # at the label now at the address they meant.  A label some other file names bare
            # (`call Name`, `.long Name`) is an entry point and is kept, as before.
            bare = set()
            for f in glob.glob(os.path.join(ROOT, "v7/maincpu/**/*.s"), recursive=True):
                if os.path.relpath(f, os.path.join(ROOT, "v7/maincpu")) in SPAN:
                    continue
                for ln in open(f, "rb").read().decode("latin-1").split("\n"):
                    code = ln.split(";")[0]
                    for nm in keep:
                        if re.search(r'(?<![\w.$])%s(?![\w.$])(?!\s*[+-])' % re.escape(nm), code) and \
                                not re.match(r'^\s*%s:' % re.escape(nm), code):
                            bare.add(nm)
            keep = {nm: v for nm, v in keep.items() if nm in bare}
        newlab = resolve(P, items, old, keep, elsewhere, sv10)
        files, emitted = layout(P, items, old, keep, newlab)
        cov = collections.Counter()
        for addr, n, it in emitted:
            cov["code" if it is not None else "byte"] += n
        print("round %d: v7 bytes as ported lines %d, as .byte %d; labels %d" % (
            it_round, cov["code"], cov["byte"], len(newlab)))
        if not a.apply:
            return 0
        write_files(P, files)
        built, err = build_v7()
        if built is None:
            print("BUILD FAILED:\n" + err)
            # demote lines named in assembler errors is not possible by address;
            # stop so a human can look
            return 1
        if built == P.r7:
            print("v7 IDENTICAL after round %d" % it_round)
            return 0
        bad = [k for k in range(len(built)) if built[k] != P.r7[k]]
        print("  %d bytes differ, first at 0x%06X" % (len(bad), bad[0] + BASE))
        badaddr = {x + BASE for x in bad}
        hit = 0
        for addr, n, it in emitted:
            if it is not None and any(addr <= x < addr + n for x in badaddr if addr <= x < addr + n):
                demoted.add(it.i10)
                hit += 1
        if not hit:
            print("  no ported line covers the differing bytes; stopping")
            return 1
        print("  demoting %d lines" % hit)
    return 1


if __name__ == "__main__":
    sys.exit(main())
