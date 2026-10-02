#!/usr/bin/env python3
r"""scoop_reframe.py -- re-spell an address span of a KN5000 maincpu source file
(v7, v9 or v10) as correctly framed code and typed data, keeping every label
and comment, and prove the result byte-identical.

QUESTION ANSWERED
-----------------
"This span of `display/*.s` is data decoded as code (or code misframed by one
byte, or a verbatim romslice).  What are its real instructions and data, and
can the source be re-spelled that way without changing a single ROM byte?"

It never guesses what a span IS.  The caller states the layout in a spec
(segments of kind code / ascii / byte / long / word / raw), having established
it from the code that reads or calls the bytes.  `trace` helps establish it:
it FOLLOWS CONTROL FLOW from stated entry points with MAME's `unidasm` (an
independent decoder) and reports which bytes are reached as instructions.

SUBCOMMANDS
    map    --image v10 --file F [--lo A --hi B]
           print every line of F with the address and byte length it emits
    trace  --image v10 --lo A --hi B --entry X [--entry Y ...]
           recursive-descent from the entries (unidasm); prints code runs, the
           branch targets met, and which bytes of [A,B) were NOT reached
    refs   --image v10 --lo A --hi B
           every symbol whose address is in [A,B), and each source line that
           names it (so the reader/caller of a span can be read)
    apply  --image v10 --spec S.json [--dry-run]
           splice every span of the spec, verify the linked image against the
           dump, roll everything back if one byte differs

SPEC (JSON list)
    {"file": "v10/maincpu/display/scoop_display.s",
     "start": "0xEFF5A1", "end": "0xEFF6F1",        # must be line boundaries
     "segments": [ {"kind": "code", "len": 40},
                   {"kind": "ascii", "len": 24, "per_line": 2},
                   {"kind": "long", "len": 8},
                   {"kind": "raw", "len": 3, "lines": ["\tld\ta, 3"]} ],
     "labels": {"0xEFF5A1": "Name"},                # NEW labels to place
     "comments": {"0xEFF5A1": ["line", "line"]}}    # NEW comment lines

    Every label and comment already inside the replaced lines is carried over
    to the same ADDRESS, in its original order (a trailing comment becomes a
    whole-line comment directly above its line).  A label whose address falls
    inside a rendered instruction or data line is a hard refusal: the spec
    must then cut a segment there.

VERIFICATION
    `apply` assembles + links the whole image in a private temp dir, compares
    with original_ROMs/kn5000_<img>_program.rom, and restores every touched
    file if a byte differs.  Code segments are also cross-checked against
    unidasm instruction by instruction (length AND start); a disagreement is a
    refusal unless the segment says "allow_unidasm_mismatch": true.
    Sources are read and written as BYTES (latin-1 round trip) -- these files
    carry raw high bytes inside .ascii literals.

Exact commands (repo root):
    python3 scripts/converters/scoop_reframe.py map --image v10 \
        --file v10/maincpu/display/scoop_display.s --lo 0xEFF5A1 --hi 0xEFF700
    python3 scripts/converters/scoop_reframe.py apply --image v10 \
        --spec notes/scoop-lane-2026-09-25/specs/<name>.json

Lane `scoop`, semantic push 2026-09-25.
"""
import argparse
import collections
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM = os.environ.get("LLVM_BIN", os.path.expanduser("~/compartilhado/llvm-project/build/bin"))
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE = 0xE00000
SCRATCH = os.environ.get("SCOOP_SCRATCH", os.path.join(os.environ.get("TMPDIR", "/tmp"), "lane-scoop"))  # TMPDIR: /tmp is a small tmpfs here
os.makedirs(SCRATCH, exist_ok=True)
LABEL_RE = re.compile(r'^([A-Za-z_.$][\w.$]*):')


def rom(img):
    return open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % img), "rb").read()


def strip_comment(line):
    out, q = [], None
    for i, ch in enumerate(line):
        if q:
            out.append(ch)
            if ch == "\\" and i + 1 < len(line):
                continue
            if ch == q and not (i and line[i - 1] == "\\"):
                q = None
            continue
        if ch in "\"'":
            q = ch
            out.append(ch)
            continue
        if ch == ";":
            return "".join(out), line[i:]
        out.append(ch)
    return "".join(out), ""


# ---------------------------------------------------------------- building
def _mc(args, cwd=ROOT):
    return subprocess.run([os.path.join(LLVM, "llvm-mc")] + args, cwd=cwd,
                          capture_output=True, text=True)


def build(img, override=None, keep=None):
    """Assemble+link the image. `override` = {relpath: text} replaces files.
    Returns (ok, elf_path, rom_bytes_or_stderr)."""
    td = keep or tempfile.mkdtemp(prefix="scoop-build-", dir=SCRATCH)
    src = os.path.join(ROOT, img, "maincpu")
    inc = src
    if override:
        mir = os.path.join(td, "mirror")
        if os.path.exists(mir):
            shutil.rmtree(mir)
        for dp, dn, fn in os.walk(src):
            rel = os.path.relpath(dp, src)
            od = os.path.join(mir, rel) if rel != "." else mir
            os.makedirs(od, exist_ok=True)
            for f in fn:
                s = os.path.join(dp, f)
                r = os.path.relpath(s, ROOT)
                d = os.path.join(od, f)
                if r in override:
                    open(d, "wb").write(override[r].encode("latin-1"))
                else:
                    os.symlink(s, d)
        inc = mir
    obj, elf, binf = (os.path.join(td, x) for x in ("i.o", "i.elf", "i.bin"))
    r = _mc(["-triple=tlcs900", "-filetype=obj", "-I", inc, "-o", obj,
             os.path.join(inc, "kn5000_%s_program.s" % img)])
    if r.returncode:
        return False, None, r.stderr
    subprocess.run([os.path.join(LLVM, "ld.lld"), "-e", "0", "-T",
                    os.path.join(inc, "maincpu.ld"), "-o", elf, obj], check=True)
    subprocess.run([os.path.join(LLVM, "llvm-objcopy"), "-O", "binary", elf, binf],
                   check=True)
    return True, elf, open(binf, "rb").read()


def symbols(elf):
    """-> (addr->[names], name->addr) for .text symbols."""
    out = subprocess.run([os.path.join(LLVM, "llvm-nm"), "--defined-only", elf],
                         capture_output=True, text=True, check=True).stdout
    a2n, n2a = {}, {}
    for line in out.split("\n"):
        p = line.split()
        if len(p) == 3 and p[1] in "tT":
            a = int(p[0], 16)
            n2a[p[2]] = a
            a2n.setdefault(a, []).append(p[2])
        elif len(p) == 3 and p[1] in "aA" and 0xE00000 <= int(p[0], 16) < 0x1000000:
            n2a[p[2]] = int(p[0], 16)      # `.set NAME, 0xefdb94` style names
            ABS_NAMES.add(p[2])
    # absolute names are a FALLBACK: only where no text label exists
    for n in ABS_NAMES:
        a = n2a.get(n)
        if a is not None and a not in a2n:
            a2n.setdefault(("abs", a), []).append(n)
    for k in [k for k in a2n if isinstance(k, tuple)]:
        a2n[k[1]] = a2n.pop(k)
    return a2n, n2a


ABS_NAMES = set()


def linemap(img, files):
    """{relpath: [addr_or_None per line (0-based)]} and per-line byte length."""
    override, marks = {}, {}
    for rel in files:
        lines = open(os.path.join(ROOT, rel), encoding="latin-1").read().split("\n")
        out, in_macro = [], False
        for i, ln in enumerate(lines):
            code = strip_comment(ln)[0].strip()
            if code.startswith(".macro"):
                in_macro = True
            if code and not in_macro:
                out.append("Zsr_%d_%d:" % (files.index(rel), i))
            if code.startswith(".endm"):
                in_macro = False
            out.append(ln)
        out.append("Zsr_%d_%d:" % (files.index(rel), len(lines)))   # end-of-file marker
        override[rel] = "\n".join(out)
        marks[rel] = len(lines) + 1
    ok, elf, data = build(img, override)
    if not ok:
        raise SystemExit("linemap build failed:\n" + data[-3000:])
    if data != rom(img):
        raise SystemExit("REJECTED: instrumented %s image is not byte-identical" % img)
    a2n, n2a = symbols(elf)
    res = {}
    for fi, rel in enumerate(files):
        addrs = [None] * marks[rel]
        pre = "Zsr_%d_" % fi
        for n, a in n2a.items():
            if n.startswith(pre):
                addrs[int(n[len(pre):])] = a
        res[rel] = addrs
    return res, elf


def line_extents(addrs):
    """Byte length of each mapped line: next mapped line's address minus own."""
    n = len(addrs)
    ext = [0] * n
    nxt = None
    for i in range(n - 1, -1, -1):
        if addrs[i] is not None:
            ext[i] = (nxt - addrs[i]) if nxt is not None else 0
            nxt = addrs[i]
    return ext


# ---------------------------------------------------------------- decoding
_UCACHE = {}
_ROMS = {}


def unidasm(img, addr, count, data=None):
    """Linear unidasm from addr: [(addr, len, text)] (memoised per image)."""
    key = (img, addr, count) if data is None else None
    if key and key in _UCACHE:
        return list(_UCACHE[key])
    res = _unidasm(img, addr, count, data)
    if key:
        _UCACHE[key] = tuple(res)
    return res


def _unidasm(img, addr, count, data=None):
    if data is None:
        if img not in _ROMS:
            _ROMS[img] = rom(img)
        d = _ROMS[img]
    else:
        d = data
    off = addr - BASE
    with tempfile.NamedTemporaryFile(suffix=".bin", dir=SCRATCH, delete=False) as f:
        f.write(d[off:off + count + 8])
        p = f.name
    try:
        out = subprocess.run([UNIDASM, p, "-arch", "tlcs900", "-basepc", "%x" % addr],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(p)
    res = []
    for line in out.split("\n"):
        m = re.match(r'\s*([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$', line)
        if m:
            a = int(m.group(1), 16)
            if a >= addr + count:
                break
            res.append((a, len(m.group(2).split()), m.group(3).strip()))
    return res


def objdump(data):
    """-> [(nbytes, text)] covering data exactly (llvm backend decoder)."""
    with tempfile.TemporaryDirectory(dir=SCRATCH) as td:
        s, o = os.path.join(td, "d.s"), os.path.join(td, "d.o")
        with open(s, "w") as f:
            f.write(".text\n")
            for i in range(0, len(data), 16):
                f.write(".byte " + ",".join("0x%02x" % c for c in data[i:i + 16]) + "\n")
        subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900",
                        "-filetype=obj", "-o", o, s], check=True, capture_output=True)
        out = subprocess.run([os.path.join(LLVM, "llvm-objdump"), "-d", "-z", o],
                             check=True, capture_output=True, text=True).stdout
    segs = []
    pat = re.compile(r"^\s*([0-9a-f]+):\s((?:[0-9a-f]{2} )+)\s*(.*)$")
    for line in out.split("\n"):
        m = pat.match(line)
        if not m:
            continue
        raw = m.group(2).split()
        text = m.group(3).rstrip()
        if text.startswith("<unknown>"):
            segs.append((1, None, raw))
        else:
            mn, _, ops = text.strip().partition("\t")
            ops = re.sub(r"\s+", " ", ops.strip())
            segs.append((len(raw), mn.strip() + ("\t" + ops if ops else ""), raw))
    if sum(n for n, _, _ in segs) != len(data):
        raise SystemExit("objdump covered %d of %d bytes" % (sum(n for n, _, _ in segs), len(data)))
    return segs


BR = re.compile(r'^(jr|jrl|calr|djnz)\b', re.I)
TERM = re.compile(r'^(ret|reti|retd)\b|^(jp|jr|jrl)\s+(0x[0-9a-f]+|\(|T,)', re.I)


def uni_target(text):
    m = re.search(r'0x([0-9a-f]{6})\b', text)
    return int(m.group(1), 16) if m else None


def trace(img, lo, hi, entries, data=None, maxinsn=20000):
    """Recursive descent with unidasm (one linear decode window per run).
    Returns (insns{addr:(len,text)}, external_targets, conflicts)."""
    insns, todo, ext, conflicts = {}, list(entries), set(), []
    covered = {}
    d = data
    while todo:
        a = todo.pop()
        if not (lo <= a < hi):
            ext.add(a)
            continue
        if a in insns:
            continue
        window = []
        stop = False
        while not stop and lo <= a < hi and a not in insns:
            if not window:
                window = unidasm(img, a, 512, d)
                if not window or window[0][0] != a:
                    conflicts.append((a, "no decode"))
                    break
            wa, n, text = window.pop(0)
            if wa != a:
                window = []
                continue
            if a in covered:
                conflicts.append((a, "overlaps insn at 0x%06X" % covered[a]))
                break
            if text.startswith("db"):
                conflicts.append((a, "undecodable"))
                break
            if any(k in insns for k in range(a + 1, a + n)):
                conflicts.append((a, "straddles an insn start"))
                break
            insns[a] = (n, text)
            for k in range(a + 1, a + n):
                covered[k] = a
            op = text.split()[0].lower()
            args = text.split(None, 1)[1] if " " in text else ""
            if op in ("jr", "jrl", "call", "calr", "djnz", "jp") and "(" not in args:
                t = uni_target(text)
                if t is not None:
                    todo.append(t)
            if op in ("reti", "retd") or (op == "ret" and not args):
                stop = True
            if op in ("jp", "jr", "jrl") and ("," not in args or args.startswith("T,")):
                stop = True
            if op in ("swi", "halt"):
                conflicts.append((a, text))
                stop = True
            a += n
    return insns, ext, conflicts


# ---------------------------------------------------------------- rendering
def esc(c):
    ch = chr(c)
    if ch == '"':
        return '\\"'
    if ch == '\\':
        return '\\\\'
    return ch


def printable(c):
    return 0x20 <= c < 0x7f


def render_ascii(data, per_line=None):
    """Printable runs as .ascii, others as .byte; one run per line."""
    lines, i = [], 0
    while i < len(data):
        if printable(data[i]):
            j = i
            while j < len(data) and printable(data[j]):
                j += 1
            chunk = data[i:j]
            step = per_line or len(chunk)
            for k in range(0, len(chunk), step):
                lines.append((i + k, '\t.ascii\t"%s"' % "".join(esc(c) for c in chunk[k:k + step])))
            i = j
        else:
            j = i
            while j < len(data) and not printable(data[j]) and j - i < 12:
                j += 1
            lines.append((i, "\t.byte\t" + ", ".join("0x%02x" % c for c in data[i:j])))
            i = j
    return lines


def signed(v, bits):
    return v - (1 << bits) if v & (1 << (bits - 1)) else v


def symbolize_code(text, addr, n, raw, a2n, rom_lo=0xE00000, rom_hi=0x1000000, local=None):
    """Replace a numeric branch displacement / absolute ROM address with a label
    when one exists at the target (a2n), or with `local[target]`."""
    def name_at(t):
        if local and t in local:
            return local[t]
        ns = a2n.get(t)
        if not ns:
            return None
        good = [x for x in ns if not x.startswith(("Zsr_", "__drc_", ".L"))]
        if not good:
            return None
        good.sort(key=lambda x: (bool(re.search(r"_0x[0-9A-Fa-f]+$", x)), len(x)))
        return good[0]
    mn = text.split("\t")[0]
    if mn in ("jr", "jrl", "calr", "djnz"):
        ops = text.split("\t", 1)[1] if "\t" in text else ""
        parts = [p.strip() for p in ops.split(",")]
        try:
            disp = int(parts[-1], 0)
        except ValueError:
            return text, None
        tgt = addr + n + disp
        nm = name_at(tgt)
        if nm:
            parts[-1] = nm
            return mn + "\t" + ", ".join(parts), tgt
        return text, tgt
    # absolute 24/32-bit numbers
    def rep(m):
        v = int(m.group(0), 0)
        if rom_lo <= v < rom_hi:
            nm = name_at(v)
            if nm:
                return nm
        return m.group(0)
    new = re.sub(r'(?<![\w:])(0x[0-9a-fA-F]{6,8}|\d{7,8})(?![\w:])', rep, text)
    return new, None


def assemble_lines(texts):
    """Assemble each text as its own source line; -> [bytes or None].
    Every line is preceded by a marker label, so an error on one line can not
    shift the attribution of the encodings that follow it."""
    with tempfile.TemporaryDirectory(dir=SCRATCH) as td:
        src = os.path.join(td, "rt.s")
        body = []
        for i, t in enumerate(texts):
            body.append("Zrt_%d:" % i)
            body.append("\t" + t.strip())
        body.append("Zrt_end:")
        open(src, "w", encoding="latin-1").write("\n".join(body) + "\n")
        r = subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900", "-show-encoding", src],
                           capture_output=True, text=True, encoding="latin-1")
    out = [None] * len(texts)
    cur, acc, bad = None, b"", False
    errlines = {int(m.group(1)) for m in re.finditer(r'rt\.s:(\d+):\d+: error', r.stderr)}
    for line in r.stdout.split("\n"):
        m = re.match(r'^Zrt_(\d+|end):', line)
        if m:
            if cur is not None and acc and not bad:
                out[cur] = acc
            cur = None if m.group(1) == "end" else int(m.group(1))
            acc, bad = b"", (cur is not None and (2 * cur + 2) in errlines)
            continue
        m = re.search(r'encoding: \[([^\]]*)\]', line)
        if m and cur is not None:
            acc += bytes(int(x, 0) for x in m.group(1).split(",") if x.strip())
    return out


def hexify(text):
    """Decimal absolute addresses -> hex: `(3567)` -> `(0x0def)`, and a 32-bit
    load of a value >= 0x100 -> hex (policy 7: addresses in hex)."""
    text = re.sub(r'\((\d{3,8})\)', lambda m: "(0x%04x)" % int(m.group(1))
                  if int(m.group(1)) >= 0x100 else m.group(0), text)
    m = re.match(r'^(ld\tx(?:wa|bc|de|hl|ix|iy|iz|sp), )(\d{3,8})$', text)
    if m and int(m.group(2)) >= 0x100:
        text = m.group(1) + "0x%04x" % int(m.group(2))
    return text


def decode_each(chunks):
    """LLVM decode of each byte string ON ITS OWN (one ELF section apiece, so a
    misdecode of one cannot shift the framing of the next).
    -> [(nbytes_of_first_insn, text_or_None)]"""
    with tempfile.TemporaryDirectory(dir=SCRATCH) as td:
        s, o = os.path.join(td, "e.s"), os.path.join(td, "e.o")
        with open(s, "w") as f:
            for i, c in enumerate(chunks):
                f.write('.section .t%d,"ax"\n.byte %s\n' % (i, ",".join("0x%02x" % x for x in c)))
        subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900", "-filetype=obj",
                        "-o", o, s], check=True, capture_output=True)
        out = subprocess.run([os.path.join(LLVM, "llvm-objdump"), "-d", "-z", o],
                             check=True, capture_output=True, text=True).stdout
    res = [None] * len(chunks)
    cur = None
    pat = re.compile(r"^\s*([0-9a-f]+):\s((?:[0-9a-f]{2} )+)\s*(.*)$")
    for line in out.split("\n"):
        m = re.match(r"^Disassembly of section \.t(\d+):", line)
        if m:
            cur = int(m.group(1))
            continue
        m = pat.match(line)
        if m and cur is not None and res[cur] is None and int(m.group(1), 16) == 0:
            raw = m.group(2).split()
            text = m.group(3).rstrip()
            if text.startswith("<unknown>"):
                res[cur] = (1, None)
            else:
                mn, _, ops = text.strip().partition("\t")
                ops = re.sub(r"\s+", " ", ops.strip())
                res[cur] = (len(raw), mn.strip() + ("\t" + ops if ops else ""))
    return [r or (0, None) for r in res]


_SPELL = {}


def known_spellings(img):
    """bytes(hex) -> source text, for every custom-mnemonic instruction the
    image's tree already spells (lda_dri, cpib_sri, ld_sril3 ...): the tree's
    own convention for encodings the backend's disassembler cannot print."""
    if img in _SPELL:
        return _SPELL[img]
    lines = set()
    for dp, _, fn in os.walk(os.path.join(ROOT, img, "maincpu")):
        for f in fn:
            if not f.endswith(".s"):
                continue
            for ln in open(os.path.join(dp, f), encoding="latin-1"):
                c = strip_comment(ln)[0].strip()
                while LABEL_RE.match(c):
                    c = c[LABEL_RE.match(c).end():].strip()
                if not c or c.startswith("."):
                    continue
                mn = c.split()[0]
                rest = c.split(None, 1)[1] if " " in c else ""
                if "_" in mn and not mn.lower().startswith(("aligned_string", "ret_vga", "vga_seq", "_vga")) \
                        and not re.search(r'[A-Za-z_]\w*_0x|[A-Z][a-z]', rest):
                    lines.add(re.sub(r"\s+", " ", c))
    lines = sorted(lines)
    m = {}
    for t, e in zip(lines, assemble_lines(lines)):
        if e and len(e) >= 2:
            m.setdefault(e.hex(), t)
    _SPELL[img] = m
    return m


_TMPL = {}


def spelling_templates(img):
    """(prefix, opcode byte at +4, length) -> operand template, generalised from
    the tree's own custom-mnemonic spellings of SRI/DRI-mode instructions
    (`cpib_sri 0x07, 0xf0, 0xec, 0x0c` = c3 07 f0 ec 3f 0c gives
    `cpib_sri {b1}, {b2}, {b3}, {last}` for every c3 .. .. .. 3f .. form)."""
    if img in _TMPL:
        return _TMPL[img]
    tm = collections.defaultdict(collections.Counter)
    for h, t in known_spellings(img).items():
        b = bytes.fromhex(h)
        if len(b) < 5:
            continue
        mn, _, ops = t.partition(" ")
        ops = [o.strip() for o in ops.split(",")] if ops else []
        out, bi = [], 1
        for o in ops:
            try:
                v = int(o, 0)
            except ValueError:
                out.append(o)
                continue
            if bi <= 3 and v == b[bi]:
                out.append("{b%d}" % bi)
                bi += 1
            elif bi > 3 and v == b[-1]:
                out.append("{last}")
            else:
                out.append(o)
        if bi == 4:
            tm[(b[0], b[4], len(b))][mn + " " + ", ".join(out)] += 1
    _TMPL[img] = {k: [t for t, _ in v.most_common()] for k, v in tm.items()}
    return _TMPL[img]


R8 = {"w", "a", "b", "c", "d", "e", "h", "l"}
R16 = {"wa", "bc", "de", "hl", "ix", "iy", "iz", "sp"}


def alt_spellings(ut, llvm_text):
    """Candidate LLVM spellings for an instruction the backend's own printout
    does not round-trip: explicit address widths, and the backend's names for
    forms its disassembler cannot print (shift/rotate by A or by an
    immediate count)."""
    cands = []
    base = [x for x in (llvm_text, ut.lower()) if x]
    for t in base:
        t = t.replace("\t", " ")
        def width(m):
            v = int(m.group(1), 0)
            return "(0x%02x:8)" % v if v < 0x100 else "(0x%04x:16)" % v if v < 0x10000 else m.group(0)
        cands.append(re.sub(r'\((0x[0-9a-f]+|\d+)\)', width, t))
    m = re.match(r'^(srl|sla|sra|sll|rlc|rrc|rl|rr) a,(\w+)$', ut.lower())
    if m:
        cands.append("%sa %s" % (m.group(1), m.group(2)))
    m = re.match(r'^(srl|sla|sra|sll|rlc|rrc|rl|rr) 0x([0-9a-f]+),(\w+)$', ut.lower())
    if m:
        r = m.group(3)
        w = 8 if r in R8 else 16 if r in R16 else 32
        cands.append("%s_i_%d %s, %d" % (m.group(1), w, r, int(m.group(2), 16)))
    return [c for c in cands if c]


def render_code(img, start, data, a2n, local=None, allow_mismatch=False):
    """Frame by unidasm (independent decoder); spell each instruction with the
    LLVM backend when its decode has the same length AND re-assembles to the
    same bytes, else as `.byte` with unidasm's reading in a comment."""
    uni = unidasm(img, start, len(data))
    if not uni or uni[0][0] != start or sum(n for _, n, _ in uni) != len(data):
        raise SystemExit("unidasm framing of 0x%06X+%d does not tile the segment: %s"
                         % (start, len(data), uni[-3:] if uni else uni))
    each = decode_each([bytes(data[a - start:a - start + n]) for a, n, _ in uni])
    llvm = {a: e for (a, n, _), e in zip(uni, each)}
    cands = []
    for a, n, ut in uni:
        l = llvm.get(a)
        t = None
        if l and l[0] == n and l[1] is not None:
            t = l[1]
        cands.append((a, n, ut, t))
    # round-trip every candidate spelling (raw and hexified)
    texts = [c[3] or "nop" for c in cands]
    hx = [hexify(t) for t in texts]
    enc_raw = assemble_lines(texts)
    enc_hex = assemble_lines(hx)
    # template spellings for what neither llvm nor the exact-match table covers
    tmpl_try = {}
    tms = spelling_templates(img)
    for (a, n, ut, t), er, eh in zip(cands, enc_raw, enc_hex):
        want = bytes(data[a - start:a - start + n])
        ok = t is not None and (eh == want or er == want)
        if not ok and want.hex() not in known_spellings(img) and n >= 5:
            for tpl in tms.get((want[0], want[4], n), []):
                tmpl_try.setdefault(a, []).append(
                    tpl.format(b1="0x%02x" % want[1], b2="0x%02x" % want[2], b3="0x%02x" % want[3],
                               last="0x%02x" % want[-1]))
    for (a, n, ut, t), er, eh in zip(cands, enc_raw, enc_hex):
        want = bytes(data[a - start:a - start + n])
        if not (t is not None and (eh == want or er == want)) and want.hex() not in known_spellings(img):
            tmpl_try.setdefault(a, [])
            tmpl_try[a] = alt_spellings(ut, t) + tmpl_try[a]
    flat = [(a, x) for a, xs in tmpl_try.items() for x in xs]
    tenc = assemble_lines([x for _, x in flat]) if flat else []
    tmpl_ok = {}
    for (a, x), e in zip(flat, tenc):
        n_ = next(n for aa, n, _, _ in cands if aa == a)
        if a not in tmpl_ok and e == bytes(data[a - start:a - start + n_]):
            tmpl_ok[a] = x
    out, problems = [], []
    for (a, n, ut, t), er, eh, h in zip(cands, enc_raw, enc_hex, hx):
        want = bytes(data[a - start:a - start + n])
        if t is not None and eh == want:
            spelled = h
        elif t is not None and er == want:
            spelled = t
        else:
            spelled = None
        if spelled is None and want.hex() in known_spellings(img):
            out.append((a - start, "\t" + known_spellings(img)[want.hex()] + "\t; " + ut))
            continue
        if spelled is None and a in tmpl_ok:
            out.append((a - start, "\t" + tmpl_ok[a] + "\t; " + ut))
            continue
        if spelled is None:
            out.append((a - start, "\t.byte\t" + ", ".join("0x%02x" % c for c in want)
                        + "\t; " + ut + ("" if t is None else "  (llvm-mc: %s does not round-trip)" % t)))
            if ut.startswith("db"):
                problems.append((a, "unidasm cannot decode"))
            continue
        s2, _ = symbolize_code(spelled, a, n, None, a2n, local=local)
        out.append((a - start, "\t" + s2))
    if problems and not allow_mismatch:
        raise SystemExit("REFUSED code segment at 0x%06X:\n  " % start +
                         "\n  ".join("0x%06X %s" % p for p in problems[:20]))
    return out


def render_segment(img, seg, start, data, a2n, local):
    k = seg["kind"]
    if k == "code":
        return render_code(img, start, data, a2n, local, seg.get("allow_unidasm_mismatch"))
    if k == "ascii":
        return render_ascii(data, seg.get("per_line"))
    if k == "byte":
        per = seg.get("per_line", 16)
        return [(i, "\t.byte\t" + ", ".join(("%d" if seg.get("decimal") else "0x%02x") % c
                                           for c in data[i:i + per]))
                for i in range(0, len(data), per)]
    if k in ("long", "word"):
        w = 4 if k == "long" else 2
        if len(data) % w:
            raise SystemExit("%s segment at 0x%06X not a multiple of %d" % (k, start, w))
        per = seg.get("per_line", 1)
        res = []
        for i in range(0, len(data), w * per):
            items = []
            for j in range(i, min(i + w * per, len(data)), w):
                v = int.from_bytes(data[j:j + w], "little")
                nm = None
                if k == "long" and seg.get("symbols", True):
                    ns = [x for x in a2n.get(v, []) if not x.startswith(("Zsr_", "__drc_", ".L"))]
                    if local and v in local:
                        nm = local[v]
                    elif ns:
                        ns.sort(key=lambda x: (bool(re.search(r"_0x[0-9A-Fa-f]+$", x)), len(x)))
                        nm = ns[0]
                items.append(nm or ("%d" % v if seg.get("decimal") else "0x%0*x" % (w * 2, v)))
            res.append((i, "\t.%s\t%s" % ("long" if k == "long" else "short", ", ".join(items))))
        return res
    if k == "raw":
        # caller-supplied lines; checked by the image gate
        return [(0, l) for l in seg["lines"]]
    raise SystemExit("unknown kind %r" % k)


# ---------------------------------------------------------------- splicing
def splice(img, spec, amap, a2n, rombytes, lines):
    rel = spec["file"]
    addrs = amap[rel]
    ext = line_extents(addrs)
    a, b = int(spec["start"], 16), int(spec["end"], 16)
    # first byte-emitting line at a, and first line at b (exclusive end)
    first = next((i for i, x in enumerate(addrs) if x == a and ext[i] > 0), None)
    if first is None:
        raise SystemExit("0x%06X is not the start of a byte-emitting line in %s" % (a, rel))
    # pull preceding labels/comments that sit AT a into the replaced range? no:
    # they stay where they are (above the span), which keeps them at address a.
    last = next((i for i in range(first, len(addrs))
                 if addrs[i] is not None and addrs[i] >= b), None)
    if last is None:
        raise SystemExit("0x%06X is past the end of the file" % b)
    elif addrs[last] != b:
        raise SystemExit("0x%06X is not a line boundary (line %d starts 0x%06X)"
                         % (b, last + 1, addrs[last]))
    # back `last` up over label / comment / blank lines that belong to b
    while last - 1 > first and (not strip_comment(lines[last - 1])[0].strip()
                                or LABEL_RE.match(strip_comment(lines[last - 1])[0].strip())
                                and not strip_comment(lines[last - 1])[0].strip().split(":", 1)[1].strip()):
        last -= 1
    old = lines[first:last]
    # collect labels and comments with their addresses
    carry = []   # (addr, order, kind, text)
    for idx in range(first, last):
        ln = lines[idx]
        code, com = strip_comment(ln)
        # address the line refers to
        ad = addrs[idx]
        if ad is None:
            j = idx
            while j < last and addrs[j] is None:
                j += 1
            ad = addrs[j] if j < last else b
        c = code.strip()
        while True:
            m = LABEL_RE.match(c)
            if not m:
                break
            if m.group(1) not in spec.get("drop_labels", []):
                carry.append((ad, idx, "label", m.group(1)))
            c = c[m.end():].strip()
        if com.strip():
            carry.append((ad, idx, "comment", com.strip()))
    # render
    data = rombytes[a - BASE:b - BASE]
    local = {int(k, 16): v for k, v in spec.get("labels", {}).items()}
    segs = spec.get("segments") or [{"kind": spec["kind"], "len": b - a}]
    if sum(s["len"] for s in segs) != b - a:
        raise SystemExit("segments sum to %d, span is %d" % (sum(s["len"] for s in segs), b - a))
    rendered = []   # (addr, text)
    off = 0
    for s in segs:
        for o, t in render_segment(img, s, a + off, data[off:off + s["len"]], a2n, local):
            rendered.append((a + off + o, t))
        off += s["len"]
    starts = {ad for ad, _ in rendered}
    # a carried label that falls INSIDE a rendered line (a name other files
    # point into the middle of an instruction) becomes `.set NAME, . + k`
    # placed on the line that contains it
    inside = {}
    ends = sorted(starts) + [b]
    for ad, idx, kind, t in list(carry):
        if kind == "label" and ad not in starts:
            host = max(x for x in starts if x < ad)
            inside.setdefault(host, []).append((ad - host, t))
            carry.remove((ad, idx, kind, t))
    for ad in local:
        if ad not in starts:
            raise SystemExit("new label %s at 0x%06X is not on a rendered line" % (local[ad], ad))
    newc = {int(k, 16): v for k, v in spec.get("comments", {}).items()}
    out = []
    ci = 0
    carry.sort(key=lambda x: (x[0], x[1]))
    for ad, t in rendered:
        while ci < len(carry) and carry[ci][0] <= ad:
            _, _, kind, txt = carry[ci]
            out.append(txt + ":" if kind == "label" else "\t" + txt)
            ci += 1
        if ad in newc:
            for c in newc.pop(ad):
                out.append("\t; " + c if c else "")
        if ad in local and not any(x[2] == "label" and x[3] == local[ad] for x in carry):
            out.append(local.pop(ad) + ":")
        for k, nm in inside.get(ad, []):
            out.append("\t.set\t%s, . + %d\t; no instruction starts here: the name points %d byte(s) into the one below" % (nm, k, k))
        out.append(t)
    while ci < len(carry):
        _, _, kind, txt = carry[ci]
        out.append(txt + ":" if kind == "label" else "\t" + txt)
        ci += 1
    # merge "Label:" followed by a single directive for .incbin-free compaction? no
    return lines[:first] + out + lines[last:], (first + 1, last, len(out))


STRUCT = re.compile(r'_(Skip|Join|Loop|Entry|Epilogue|Return|Helper|Sub|Code)\d*$')
BRANCH_OP = re.compile(r'^\s*(call|jp|jr|jrl|calr|djnz)\b(.*)$', re.I)
IDENT = re.compile(r'\b([A-Za-z_][\w.$]*)\b')


def scan_refs(img, n2a, lo, hi, skip):
    """Every source reference to a symbol whose address is in [lo,hi).
    skip = {(relpath, line_index)} lines to ignore (the span being replaced).
    -> (branch_refs {addr: [site]}, other_refs {addr: [site]})"""
    names = {n: a for n, a in n2a.items() if lo <= a < hi}
    br, oth = {}, {}
    srcroot = os.path.join(ROOT, img, "maincpu")
    for dp, _, fn in os.walk(srcroot):
        for f in fn:
            if not f.endswith(".s"):
                continue
            p = os.path.join(dp, f)
            rel = os.path.relpath(p, ROOT)
            for i, ln in enumerate(open(p, encoding="latin-1").read().split("\n")):
                if (rel, i) in skip:
                    continue
                code = strip_comment(ln)[0].strip()
                while LABEL_RE.match(code):
                    code = code[LABEL_RE.match(code).end():].strip()
                if not code or code.startswith(".set") or code.startswith(".equ"):
                    continue
                m = BRANCH_OP.match(code)
                for mm in IDENT.finditer(code):
                    nm = mm.group(1)
                    if nm in names:
                        site = "%s:%d: %s" % (rel, i + 1, code)
                        (br if m else oth).setdefault(names[nm], []).append(site)
    return br, oth


ABSURD = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi)\b', re.I)


def texty(seg):
    """Share of bytes that look like TEXT: printable, but not the one-byte
    push/pop opcodes (0x28-0x2F, 0x38-0x3F, 0x48-0x4F, 0x58-0x5F), which make
    register save/restore sequences look like "9:;<=>" and "^]\\[ZY"."""
    if not seg:
        return 0.0
    n = sum(1 for x in seg if 0x20 <= x < 0x7f and not (0x28 <= x <= 0x2f or 0x38 <= x <= 0x3f
                                                       or 0x48 <= x <= 0x4f or 0x58 <= x <= 0x5f))
    return n / len(seg)


def is_text(seg):
    """Printable run with real letters in it.  Letters H-O and X-_ and the
    punctuation 8-? and (-/ are ALSO one-byte push/pop opcodes, so a register
    save/restore sequence ("9:;<=>", "^]\\[ZY") is printable too; it is told
    apart by requiring letters OUTSIDE those ranges (A-G, P-W, a-z, space)."""
    if len(seg) < 4:
        return False
    p = sum(1 for x in seg if 0x20 <= x < 0x7f) / len(seg)
    L = sum(1 for x in seg if x == 0x20 or 0x41 <= x <= 0x47 or 0x50 <= x <= 0x57 or 0x61 <= x <= 0x7a)
    return p >= 0.75 and L >= max(2, 0.3 * len(seg))


def plausible(img, c, hi, insns, rb, limit=600, typed=frozenset(), covered=None, allow_ret=False,
              strong=None, min_insns=2, forbid_weak=False, strong_d=False):
    """Is a linear decode from c a clean, well-ended run of code?
    typed   = bytes the source already types as tables/text (refused)
    covered = {byte: insn start} of traced code (a branch into the middle of a
              traced instruction is refused)
    strong  = if given, the run must be ANCHORED: contain a branch/call to a
              traced instruction or to an address in `strong` (known routines),
              or join traced code after >= 3 instructions; and it may not
              contain nop/ei/di/halt/swi or an 8-bit direct (SFR page) operand.
    allow_ret = a lone `ret` counts (a pointer to a return stub)."""
    def rptr(x):
        v = int.from_bytes(rb[x - BASE:x - BASE + 4], "little")
        return 0xE00000 <= v <= 0xFFFFFF
    if rptr(c) and rptr(c + 4):
        return False, "pointer table"
    dec = unidasm(img, c, 512)
    walked, texts = 0, []
    anchored = strong is None

    def finish(ok, why):
        if ok and not anchored:
            return False, "no anchor (no branch/call to a known routine or traced code)"
        return ok, why
    for a, n, t in dec:
        if a != c + walked:
            return False, "gap"
        if a in insns:
            seg = rb[c - BASE:c - BASE + walked]
            if is_text(seg) or is_text(seg[:6]):
                return False, "text"
            if strong is not None and len(texts) >= 3:
                anchored = True
            return finish(len(texts) >= min_insns, "joins")
        if any(k in typed for k in range(a, a + n)):
            return False, "overlaps typed data"
        if any(k in insns for k in range(a + 1, a + n)):
            return False, "straddles"
        if t.startswith("db") or ABSURD.match(t):
            return False, "absurd " + t
        low = t.lower()
        op = low.split()[0]
        args = t.split(None, 1)[1] if " " in t else ""
        if (strong is not None or forbid_weak) and (re.match(r'^(nop|ei|di)\b', low)
                                                    or re.search(r'\(0x[0-9a-f]{2}\)', low)):
            return False, "weak insn " + t
        if strong_d and re.match(r'^(push sr|pop sr|reti|retd|ldf|rcf|scf|zcf|ccf|push f|pop f|ex f)', low):
            return False, "phase-D odd insn " + t
        if op in ("jr", "jrl") and re.match(r'^[A-Z/]+,0x[0-9a-f]+$', args):
            if uni_target(t) == a + n:
                return False, "jr cc,0"
        if op in ("jr", "jrl") and args.startswith("F,"):
            return False, "jr f"
        if op in ("jr", "jrl", "jp", "call", "calr", "djnz") and "(" not in args:
            tg = uni_target(t)
            if tg is not None and not (0xE00000 <= tg <= 0xFFFFFF):
                return False, "branch out of ROM"
            if tg is not None and covered is not None and tg in covered and covered[tg] != tg:
                return False, "branch into the middle of a traced instruction"
            if tg is not None and strong is not None and (tg in insns or tg in strong):
                anchored = True
        texts.append(t)
        walked += n
        if a + n > hi:
            return False, "runs past span"
        term = op in ("reti", "retd") or (op == "ret" and not args) or \
            (op in ("jp", "jr", "jrl") and ("," not in args or args.startswith("T,")))
        if term:
            seg = rb[c - BASE:c - BASE + walked]
            if is_text(seg) or is_text(seg[:6]):
                return False, "text"
            if strong_d and (walked < 8 or op != "ret"):
                return False, "phase-D run too short or not ret-terminated"
            if len(texts) >= min_insns:
                return finish(True, "terminates")
            if allow_ret and op == "ret" and len(texts) == 1:
                return finish(True, "ret stub")
            if len(texts) == 1 and op in ("jp", "jr", "jrl") and anchored:
                return True, "jump stub"
            return False, "too short"
    return False, "no end"


def cmd_plan(args):
    img, rel = args.image, args.file
    lo, hi = int(args.lo, 16), int(args.hi, 16)
    amap, elf = linemap(img, [rel])
    a2n, n2a = symbols(elf)
    addrs = amap[rel]
    ext = line_extents(addrs)
    lines = open(os.path.join(ROOT, rel), encoding="latin-1").read().split("\n")
    first = next(i for i, x in enumerate(addrs) if x == lo and ext[i] > 0)
    last = next((i for i in range(first, len(addrs)) if addrs[i] is not None and addrs[i] >= hi), None)
    if last is None:
        raise SystemExit("hi 0x%06X is past the end of the file" % hi)
    elif addrs[last] != hi:
        raise SystemExit("hi 0x%06X is not a line boundary" % hi)
    skip = {(rel, i) for i in range(first, last)}
    br, oth = scan_refs(img, n2a, lo, hi, skip)
    br_in, oth_in = scan_refs(img, n2a, lo, hi, set())
    # current instruction-line starts inside the span
    cur_insn, cur_insn_cover = set(), set()
    cur_line = {addrs[i] for i in range(first, last) if addrs[i] is not None and ext[i] > 0}
    for i in range(first, last):
        c = strip_comment(lines[i])[0].strip()
        while LABEL_RE.match(c):
            c = c[LABEL_RE.match(c).end():].strip()
        if c and not c.startswith(".") and addrs[i] is not None and ext[i] > 0:
            cur_insn.add(addrs[i])
            cur_insn_cover.update(range(addrs[i], addrs[i] + ext[i]))
    # bytes the source already TYPES as pointers/words/text (never auto-code)
    # (an ISOLATED `.long` between instructions is the misframe signature
    #  `.byte 0x45 / .long X / ...` = `ld xiy, X`, so only runs of >= 2 count)
    typed = set()
    kinds = []
    for i in range(first, last):
        c = strip_comment(lines[i])[0].strip()
        while LABEL_RE.match(c):
            c = c[LABEL_RE.match(c).end():].strip()
        if not c or addrs[i] is None or ext[i] == 0:
            continue
        kinds.append((i, bool(re.match(r'^\.(long|short|hword|word|2byte|4byte)\b', c))))
    for k, (i, t) in enumerate(kinds):
        if t and ((k and kinds[k - 1][1]) or (k + 1 < len(kinds) and kinds[k + 1][1])
                  or len(strip_comment(lines[i])[0].split(",")) > 1):
            typed.update(range(addrs[i], addrs[i] + ext[i]))
    rb0 = rom(img)
    # pointer-table entries (.long/addr24, any file) that point at a line the
    # source currently spells as an instruction: code reached by dispatch --
    # accepted only if the decode there is clean (a value table the source
    # decoded as code is refused)
    ptr_entries, suspect = set(), []
    for a, sites in oth_in.items():
        for st in sites:
            code = st.split(": ", 1)[1]
            if re.match(r'^(\.long|addr24)\b', code):
                ok, why = plausible(img, a, hi, {}, rb0, allow_ret=True)
                if ok:
                    ptr_entries.add(a)
                else:
                    suspect.append(("ptr", a, why, st))
    ext_entries = set()
    for a in br:
        ok, why = plausible(img, a, hi, {}, rb0, allow_ret=True)
        ext_entries.add(a)
        if not ok:
            suspect.append(("branch", a, why, br[a][0]))
    entries = ext_entries | ptr_entries | {int(e, 16) for e in args.entry}
    entries -= {int(e, 16) for e in args.exclude}
    insns, extt, conf = trace(img, lo, hi, sorted(entries))
    # internal branch references, keyed by the ADDRESS of the referring line
    line_addr = {i: addrs[i] for i in range(first, last) if addrs[i] is not None}
    br_sites = {}
    for a, sites in br_in.items():
        for st in sites:
            r, ln = st.split(":", 2)[:2]
            if r == rel and (int(ln) - 1) in line_addr and lo <= line_addr[int(ln) - 1] < hi:
                br_sites.setdefault(a, set()).add(line_addr[int(ln) - 1])
            else:
                br_sites.setdefault(a, set()).add(None)      # outside: trusted
    # AUTO-ENTRIES: a byte run the trace did not reach is re-examined from
    # candidate starts (its first byte, every internal branch target in it,
    # every line the source currently spells as an instruction after a
    # non-instruction).  A candidate is accepted as code only if its linear
    # unidasm decode is CLEAN (no undecodable byte, no data-as-code marker)
    # and ENDS WELL (a terminator, or it joins already-traced code on an
    # instruction boundary), and the walked bytes are not mostly text.
    rb = rom(img)
    auto = set()
    # previous byte-emitting line of each current instruction start
    prev_kind = {}
    pk = None
    for i in range(first, last):
        c = strip_comment(lines[i])[0].strip()
        while LABEL_RE.match(c):
            c = c[LABEL_RE.match(c).end():].strip()
        if not c or addrs[i] is None or ext[i] == 0:
            continue
        if addrs[i] in cur_insn:
            prev_kind[addrs[i]] = pk
        mn = c.split()[0].lower()
        if mn in (".ascii", ".asciz", ".string"):
            pk = "text"
        elif mn.startswith("."):
            pk = "data"
        elif mn in ("ret", "reti", "retd") and (mn != "ret" or len(c.split()) == 1):
            pk = "term"
        elif mn in ("jp", "jr", "jrl") and "," not in c:
            pk = "term"
        else:
            pk = "insn"

    known = {a for a in a2n if a >= 0xE00000 and not (lo <= a < hi)}

    def accept(cands, respect_typed=True, need_anchor=False, allow_ret=False, forbid_weak=False,
               min_insns=2, strong_d=False):
        taken, acc = set(), set()
        cov = {}
        for a2, (n2, _) in insns.items():
            for k in range(a2, a2 + n2):
                cov[k] = a2
        for c in sorted(cands):
            if c in code or c in auto or c in entries or c in taken or not (lo <= c < hi):
                continue
            ok, why = plausible(img, c, hi, insns, rb, typed=typed if respect_typed else frozenset(),
                                covered=cov, strong=known if need_anchor else None,
                                allow_ret=allow_ret, forbid_weak=forbid_weak, min_insns=min_insns,
                                strong_d=strong_d)
            if ok:
                ins2, _, cf = trace(img, lo, hi, [c])
                span = set()
                for a2, (n2, _) in ins2.items():
                    span.update(range(a2, a2 + n2))
                if span & taken:
                    continue
                taken |= span
                acc.add(c)
        return acc

    # references that are not branches: 32-bit values anywhere else in the ROM
    # that point into the span, and `ld/lda xRR, NAME` loads of span names
    ext32 = set()
    for x in range(0, len(rb) - 3):
        if rb[x + 3] != 0 or rb[x + 2] < (lo >> 16) or rb[x + 2] > ((hi - 1) >> 16):
            continue
        if lo - BASE <= x < hi - BASE:
            continue
        v = int.from_bytes(rb[x:x + 4], "little")
        if not (lo <= v < hi):
            continue
        prev_ld = x > 0 and 0x40 <= rb[x - 1] <= 0x47
        def rp(y):
            if y < 0 or y + 4 > len(rb):
                return False
            w = int.from_bytes(rb[y:y + 4], "little")
            return 0xE00000 <= w <= 0xFFFFFF
        if prev_ld or rp(x - 4) or rp(x + 4):
            ext32.add(v)
    ldref = set()
    srcl = {}
    for a, sites in oth_in.items():
        for st in sites:
            r_, ln_, code_ = st.split(":", 2)
            m_ = re.match(r'^\s*(ld|lda)\s+(x\w+)\s*,', code_)
            if not m_:
                continue
            if r_ not in srcl:
                srcl[r_] = open(os.path.join(ROOT, r_), encoding="latin-1").read().split("\n")
            after = " ".join(strip_comment(x)[0] for x in srcl[r_][int(ln_):int(ln_) + 4]).lower()
            reg = m_.group(2).lower()
            if re.search(r'\b(call|jp)\s+\(%s\)' % reg, after) or \
                    (reg == "xix" and "uirender_twotablegeneral" in after):
                ldref.add(a)
    phase = collections.Counter()
    if not args.no_auto:
        for it in range(60):
            code = set()
            for a, (n, t) in insns.items():
                code.update(range(a, a + n))
            segstart = set()
            prev_code = True
            for a in range(lo, hi):
                inc = a in code
                if not inc and prev_code:
                    segstart.add(a)
                prev_code = inc
            trusted = {a for a, st in br_sites.items() if a not in code and
                       any(x is None or x in insns for x in st)}
            new = accept(trusted, respect_typed=False, allow_ret=True)
            tag = "A trusted branch"
            if not new:
                pt = set()
                for x in range(lo, hi - 7):
                    if x in code or (x + 7) in code:
                        continue
                    v1 = int.from_bytes(rb[x - BASE:x - BASE + 4], "little")
                    v2 = int.from_bytes(rb[x + 4 - BASE:x + 8 - BASE], "little")
                    if lo <= v1 < hi and 0xE00000 <= v2 <= 0xFFFFFF:
                        pt.add(v1)
                    if lo <= v2 < hi and 0xE00000 <= v1 <= 0xFFFFFF:
                        pt.add(v2)
                new = accept(pt | ext32 | ldref, forbid_weak=True, min_insns=3)
                tag = "B pointer/32-bit/ld reference"
            if not new:
                new = accept(segstart | {a for a in cur_line if a not in code}, need_anchor=True)
                tag = "C anchored"
            if not new:
                new = accept(segstart | {a for a in cur_insn if a not in code}, forbid_weak=True,
                             min_insns=3, strong_d=True)
                tag = "D source already spells it as clean code"
            if not new:
                break
            phase[tag] += len(new)
            for x in sorted(new):
                print("  auto[%s] 0x%06X" % (tag[0], x))
            auto |= new
            insns, extt, conf = trace(img, lo, hi, sorted(entries | auto))
    print("auto entries by phase:", dict(phase))
    code = set()
    for a, (n, t) in insns.items():
        code.update(range(a, a + n))
    starts = set(insns)
    # labels defined in the replaced lines
    carried = []
    for i in range(first, last):
        c = strip_comment(lines[i])[0].strip()
        while LABEL_RE.match(c):
            nm = LABEL_RE.match(c).group(1)
            carried.append(nm)
            c = c[LABEL_RE.match(c).end():].strip()
    drop, keep_at = [], {}
    for nm in carried:
        a = n2a.get(nm)
        ext_refs = [x for x in br.get(a, []) + oth.get(a, []) if re.search(r'\b%s\b' % re.escape(nm), x)]
        if a in code and a not in starts:
            if STRUCT.search(nm) and not ext_refs:
                drop.append(nm)
                continue
            print("CONFLICT: label %s at 0x%06X falls inside a traced instruction; refs: %s" % (nm, a, ext_refs[:3]))
        elif a not in code and STRUCT.search(nm) and not ext_refs:
            drop.append(nm)
            continue
        keep_at[a] = nm
    cuts = set(keep_at) | set(oth_in) | {int(x, 16) for x in args.cut}
    segs = []
    a = lo
    while a < hi:
        if a in code:
            b = a
            while b < hi and b in code:
                b += 1
            segs.append({"kind": "code", "len": b - a, "_at": "0x%06X" % a})
            a = b
            continue
        b = a + 1
        while b < hi and b not in code and b not in cuts:
            b += 1
        chunk = rom(img)[a - BASE:b - BASE]
        pr = sum(1 for c in chunk if printable(c)) / len(chunk)
        segs.append({"kind": "ascii" if pr >= 0.6 else "byte", "len": b - a,
                     "_at": "0x%06X" % a, "_printable": round(pr, 2)})
        a = b
    spec = [{"file": rel, "start": "0x%06X" % lo, "end": "0x%06X" % hi,
             "segments": segs, "drop_labels": drop,
             "_insn": sorted(insns), "_auto": sorted(auto), "_entries": sorted(entries)}]
    json.dump(spec, open(args.out, "w"), indent=1)
    cb = len(code & set(range(lo, hi)))
    print("span 0x%06X-0x%06X %d B: code %d B in %d insns, data %d B; entries %d; dropped labels %d"
          % (lo, hi, hi - lo, cb, len(insns), hi - lo - cb, len(entries), len(drop)))
    print("entries:", " ".join("0x%06X" % e for e in sorted(entries)))
    print("pointer-table entries:", len(ptr_entries), " auto entries:", len(auto))
    for kind, a, why, st in suspect:
        print("SUSPECT %s entry 0x%06X (%s) from %s" % (kind, a, why, st))
    # branch references whose site is not traced code (phantoms, or code we missed)
    for a, st in sorted(br_sites.items()):
        if all(x is not None and x not in insns for x in st) and a not in code:
            print("UNTRUSTED ref to 0x%06X from %s" % (a, ["0x%06X" % x for x in st if x][:4]))
    print("auto:", " ".join("0x%06X" % e for e in sorted(auto)))
    print("data refs (cut points):", " ".join("0x%06X" % e for e in sorted(oth)))
    print("targets leaving span:", " ".join("0x%06X" % e for e in sorted(extt)))
    print("conflicts:", conf[:30])
    print("dropped:", drop)
    for sg in segs:
        extra = ""
        if sg["kind"] != "code":
            b = int(sg["_at"], 16)
            extra = repr(bytes(rom(img)[b - BASE:b - BASE + min(sg["len"], 48)]))
        print("  %-5s %s %5d  %s" % (sg["kind"], sg["_at"], sg["len"], extra))


def data_segments(rb, a, b):
    """Split data [a,b) into long (runs of >=2 ROM pointers), ascii and byte."""
    out = []
    i = a
    def isptr(x):
        if x + 4 > b:
            return False
        v = int.from_bytes(rb[x - BASE:x - BASE + 4], "little")
        return 0xE00000 <= v <= 0xFFFFFF
    while i < b:
        if isptr(i) and isptr(i + 4):
            j = i
            while isptr(j):
                j += 4
            out.append({"kind": "long", "len": j - i})
            i = j
            continue
        j = i + 1
        while j < b and not (isptr(j) and isptr(j + 4)):
            j += 1
        chunk = rb[i - BASE:j - BASE]
        pr = sum(1 for x in chunk if printable(x)) / len(chunk)
        out.append({"kind": "ascii" if pr >= 0.6 else "byte", "len": j - i})
        i = j
    return out


def data_evidence(img, rb, a, b, insns=None):
    """Positive evidence that [a,b) is DATA and not unreached code.  Returns a
    list of reasons (empty = no evidence: keep whatever the source says)."""
    seg = rb[a - BASE:b - BASE]
    why = []
    if is_text(seg):
        why.append("text")
    if (b - a) % 4 == 0 and all(0xE00000 <= int.from_bytes(rb[x - BASE:x - BASE + 4], "little") <= 0xFFFFFF
                                for x in range(a, b, 4)):
        why.append("pointers")
    for x in range(a, b - 7):
        v1 = int.from_bytes(rb[x - BASE:x - BASE + 4], "little")
        v2 = int.from_bytes(rb[x + 4 - BASE:x + 8 - BASE], "little")
        if 0xE00000 <= v1 <= 0xFFFFFF and 0xE00000 <= v2 <= 0xFFFFFF:
            why.append("pointers")
            break
    dec = unidasm(img, a, b - a)
    tot = 0
    for x, n, t in dec:
        tot += n
        low = t.lower()
        op = low.split()[0]
        args = t.split(None, 1)[1] if " " in t else ""
        if t.startswith("db") or ABSURD.match(t):
            why.append("absurd:" + t)
            break
        if op in ("jr", "jrl") and (args.startswith("F,") or (re.match(r'^[A-Z/]+,0x[0-9a-f]+$', args)
                                                              and uni_target(t) == x + n and not args.startswith("T,"))):
            why.append("absurd:" + t)
            break
        if op in ("jr", "jrl", "jp", "call", "calr", "djnz") and "(" not in args:
            tg = uni_target(t)
            if tg is not None and not (0xE00000 <= tg <= 0xFFFFFF):
                why.append("branch out of ROM")
                break
    if dec and dec[-1][0] + dec[-1][1] > b:
        why.append("last instruction runs past the segment")
    return why


def cmd_islands(args):
    """Turn a whole-span PLAN into a spec that touches only the source lines
    whose framing disagrees with the plan (the islands); every line whose bytes
    the plan frames the same way is left exactly as written."""
    img = args.image
    plan = json.load(open(args.plan))[0]
    rel = plan["file"]
    lo, hi = int(plan["start"], 16), int(plan["end"], 16)
    rb = rom(img)
    amap, elf = linemap(img, [rel])
    a2n, n2a = symbols(elf)
    addrs = amap[rel]
    ext = line_extents(addrs)
    lines = open(os.path.join(ROOT, rel), encoding="latin-1").read().split("\n")
    # planned units
    istarts = set(plan["_insn"])
    code, datseg = set(), []
    a = lo
    for sg in plan["segments"]:
        if sg["kind"] == "code":
            code.update(range(a, a + sg["len"]))
        else:
            datseg.append((a, a + sg["len"]))
        a += sg["len"]
    insn_len = {}
    ss = sorted(istarts)
    dec = {}
    for st in ss:
        pass
    # instruction ends: next start inside the same code run, or run end
    runs = []
    a = lo
    for sg in plan["segments"]:
        if sg["kind"] == "code":
            runs.append((a, a + sg["len"]))
        a += sg["len"]
    bound = set()
    for (x, y) in runs:
        bound.add(x)
        bound.add(y)
    bound |= istarts
    for (x, y) in datseg:
        bound.update(range(x, y + 1))      # data may be cut anywhere
    # a planned data segment that the source spells as CODE is only re-typed
    # with positive evidence (text, pointers, absurd decode, framing that runs
    # past it); otherwise it is unreached code and is left exactly as written
    cur_code = set()
    for i, ln in enumerate(lines):
        ad, n = addrs[i], ext[i]
        if ad is None or not n:
            continue
        c = strip_comment(ln)[0].strip()
        while LABEL_RE.match(c):
            c = c[LABEL_RE.match(c).end():].strip()
        if c and not c.startswith("."):
            cur_code.update(range(ad, ad + n))
    kept = []
    for (x, y) in list(datseg):
        if all(k in cur_code for k in range(x, y)):
            ev = data_evidence(img, rb, x, y)
            if x in {int(f, 16) for f in args.force_data}:
                ev = ev + ["forced by caller (reader evidence)"]
            if not ev:
                kept.append((x, y))
                datseg.remove((x, y))
                code.update(range(x, y))
                bound.update(range(x, y + 1))
                print("KEPT AS CODE (no data evidence): 0x%06X-0x%06X" % (x, y))
    seg_of = {}
    for i, (x, y) in enumerate(datseg):
        for k in range(x, y):
            seg_of[k] = i
    # classify current lines
    bad = []
    rows = []
    for i, ln in enumerate(lines):
        ad, n = addrs[i], ext[i]
        if ad is None or n == 0 or not (lo <= ad < hi):
            continue
        c = strip_comment(ln)[0].strip()
        while LABEL_RE.match(c):
            c = c[LABEL_RE.match(c).end():].strip()
        if not c:
            continue
        isdata = c.startswith(".")
        rng = range(ad, ad + n)
        ok = True
        if c.startswith(".incbin"):
            bad.append(i)           # verbatim ROM slice: always re-typed
            continue
        if not isdata:
            ok = ad in bound and (ad + n) in bound and all(k in code for k in rng)
        else:
            if all(k in code for k in rng):
                # instruction bytes written as data: always re-rendered, so each
                # instruction gets the backend's spelling, the tree's own
                # custom-mnemonic spelling, or `.byte` + unidasm's reading
                # (a line that ALREADY carries that reading is left alone)
                ok = (c.split()[0] == ".byte" and ad in istarts and (ad + n) in bound
                      and "\t; " in ln and not any(x in istarts for x in range(ad + 1, ad + n)))
                if ok:
                    rows.append((i, ad, n))
            elif all(k not in code for k in rng):
                ok = len({seg_of.get(k) for k in rng}) == 1
            else:
                ok = False
        if not ok:
            bad.append(i)
    # .byte-spelled instructions the backend CAN spell -> bad
    if rows:
        texts = []
        for i, ad, n in rows:
            segs = objdump(rb[ad - BASE:ad - BASE + n])
            texts.append(segs[0][1] if len(segs) == 1 and segs[0][1] else None)
        encs = assemble_lines([t or "nop" for t in texts])
        for (i, ad, n), t, e in zip(rows, texts, encs):
            if t and e == bytes(rb[ad - BASE:ad - BASE + n]):
                bad.append(i)
    bad = sorted(set(bad))
    # group bad lines into islands (consecutive in address), widen to common boundaries
    lbound = {addrs[i] for i in range(len(lines)) if addrs[i] is not None and ext[i] > 0}
    lbound |= {addrs[i] + ext[i] for i in range(len(lines)) if addrs[i] is not None and ext[i] > 0}
    # data segments that already hold typed .long lines keep their spelling
    longseg = set()
    for i, ln in enumerate(lines):
        if addrs[i] is not None and ext[i] and re.match(r'^\s*([\w.$]+:\s*)?\.long\b', strip_comment(ln)[0]):
            for (x, y) in datseg:
                if x <= addrs[i] < y:
                    longseg.add((x, y))
    isl = []
    dseg_of = {}
    for (x, y) in datseg:
        for k in range(x, y):
            dseg_of[k] = (x, y)
    for i in bad:
        s0, e0 = addrs[i], addrs[i] + ext[i]
        # a bad line that touches a data segment takes the WHOLE segment with
        # it, so the data is re-rendered uniformly rather than as fragments
        for k in (s0, e0 - 1):
            if k in dseg_of and dseg_of[k] not in longseg:
                s0 = min(s0, dseg_of[k][0])
                e0 = max(e0, dseg_of[k][1])
        if isl and s0 <= isl[-1][1]:
            isl[-1][0] = min(isl[-1][0], s0)
            isl[-1][1] = max(isl[-1][1], e0)
        else:
            isl.append([s0, e0])
    # widen until both ends are line AND plan boundaries
    out = []
    for s0, e0 in isl:
        while not (s0 in bound and s0 in lbound):
            s0 -= 1
        while not (e0 in bound and e0 in lbound):
            e0 += 1
        if out and s0 <= out[-1][1]:
            out[-1][1] = max(out[-1][1], e0)
        else:
            out.append([s0, e0])
    specs = []
    tot = 0
    for s0, e0 in out:
        segs = []
        a = s0
        # code runs / data segments intersected with [s0,e0)
        while a < e0:
            if a in code:
                b = a
                while b < e0 and b in code:
                    b += 1
                segs.append({"kind": "code", "len": b - a})
            else:
                b = a
                sid = seg_of.get(a)
                while b < e0 and b not in code and seg_of.get(b) == sid:
                    b += 1
                segs += data_segments(rb, a, b)
            a = b
        specs.append({"file": rel, "start": "0x%06X" % s0, "end": "0x%06X" % e0,
                      "segments": segs, "drop_labels": plan.get("drop_labels", [])})
        tot += e0 - s0
    json.dump(specs, open(args.out, "w"), indent=1)
    print("%d islands, %d B, from %d bad lines" % (len(specs), tot, len(bad)))
    for sp in specs:
        print("  %s-%s %5d B  %s" % (sp["start"], sp["end"], int(sp["end"], 16) - int(sp["start"], 16),
                                   " ".join("%s:%d" % (g["kind"][0], g["len"]) for g in sp["segments"])))


def cmd_apply(args):
    specs = json.load(open(args.spec))
    img = args.image
    files = sorted({s["file"] for s in specs})
    amap, elf = linemap(img, files)
    a2n, _ = symbols(elf)
    rb = rom(img)
    backups = {f: open(os.path.join(ROOT, f), "rb").read() for f in files}
    newtext = {}
    for f in files:
        group = sorted([s for s in specs if s["file"] == f], key=lambda s: -int(s["start"], 16))
        lines = open(os.path.join(ROOT, f), encoding="latin-1").read().split("\n")
        for s in group:
            # bottom-up: the line map indexes ORIGINAL lines, and a splice only
            # disturbs indices at and after it, so lower spans stay valid.
            lines, info = splice(img, s, amap, a2n, rb, lines)
            print("%s %s..%s lines %d..%d -> %d lines" % (f, s["start"], s["end"], *info))
        newtext[f] = "\n".join(lines)
    if args.dry_run:
        for f in files:
            d = os.path.join(SCRATCH, "dry-" + os.path.basename(f))
            open(d, "w", encoding="latin-1").write(newtext[f])
            print("dry-run render written to", d)
        return
    for f in files:
        open(os.path.join(ROOT, f), "w", encoding="latin-1").write(newtext[f])
    ok, _, data = build(img)
    if not ok or data != rb:
        for f in files:
            open(os.path.join(ROOT, f), "wb").write(backups[f])
        if not ok:
            print(data[-3000:])
        else:
            diffs = [i for i in range(len(rb)) if i < len(data) and data[i] != rb[i]]
            print("first differing addresses:", ["0x%06X" % (BASE + i) for i in diffs[:10]],
                  "len", len(data), len(rb))
        raise SystemExit("REJECTED: %s image differs; all edits rolled back" % img)
    print("VERIFIED: %s image byte-identical after %d span(s)" % (img, len(specs)))


def cmd_map(args):
    amap, elf = linemap(args.image, [args.file])
    addrs = amap[args.file]
    ext = line_extents(addrs)
    lines = open(os.path.join(ROOT, args.file), encoding="latin-1").read().split("\n")
    lo = int(args.lo, 16) if args.lo else 0
    hi = int(args.hi, 16) if args.hi else 1 << 32
    last = None
    for i, ln in enumerate(lines):
        ad = addrs[i]
        if ad is not None:
            last = ad
        if last is None or not (lo <= last < hi):
            continue
        print("%6d %s %3s  %s" % (i + 1, ("%06X" % ad) if ad is not None else "      ",
                                  ext[i] if ad is not None else "", ln))


def cmd_trace(args):
    lo, hi = int(args.lo, 16), int(args.hi, 16)
    ents = [int(e, 16) for e in args.entry]
    insns, ext, conf = trace(args.image, lo, hi, ents)
    reached = set()
    for a, (n, t) in insns.items():
        reached.update(range(a, a + n))
    # runs
    a = lo
    while a < hi:
        r = a in reached
        b = a
        while b < hi and (b in reached) == r:
            b += 1
        print("%s 0x%06X-0x%06X %5d B" % ("CODE" if r else "----", a, b, b - a))
        if args.verbose and r:
            for x in sorted(k for k in insns if a <= k < b):
                print("        %06X %s" % (x, insns[x][1]))
        a = b
    print("targets outside span:", " ".join("0x%06X" % x for x in sorted(ext)))
    print("conflicts:", conf[:40])


def cmd_refs(args):
    img = args.image
    ok, elf, _ = build(img)
    a2n, n2a = symbols(elf)
    lo, hi = int(args.lo, 16), int(args.hi, 16)
    names = {n: a for n, a in n2a.items() if lo <= a < hi}
    pat = re.compile(r'\b(' + "|".join(re.escape(n) for n in sorted(names, key=len, reverse=True)) + r')\b') if names else None
    hits = {n: [] for n in names}
    srcroot = os.path.join(ROOT, img, "maincpu")
    for dp, _, fn in os.walk(srcroot):
        for f in fn:
            if not f.endswith(".s"):
                continue
            p = os.path.join(dp, f)
            for i, ln in enumerate(open(p, encoding="latin-1").read().split("\n")):
                code = strip_comment(ln)[0]
                if not pat:
                    continue
                for m in pat.finditer(code):
                    if code.strip().startswith(m.group(1) + ":"):
                        continue
                    hits[m.group(1)].append("%s:%d: %s" % (os.path.relpath(p, ROOT), i + 1, code.strip()))
    for n in sorted(names, key=lambda n: names[n]):
        print("0x%06X %s  (%d refs)" % (names[n], n, len(hits[n])))
        for h in hits[n][:args.max]:
            print("      " + h)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("map")
    p.add_argument("--image", required=True)
    p.add_argument("--file", required=True)
    p.add_argument("--lo")
    p.add_argument("--hi")
    p = sub.add_parser("trace")
    p.add_argument("--image", required=True)
    p.add_argument("--lo", required=True)
    p.add_argument("--hi", required=True)
    p.add_argument("--entry", action="append", default=[])
    p.add_argument("-v", "--verbose", action="store_true")
    p = sub.add_parser("refs")
    p.add_argument("--image", required=True)
    p.add_argument("--lo", required=True)
    p.add_argument("--hi", required=True)
    p.add_argument("--max", type=int, default=12)
    p = sub.add_parser("plan")
    p.add_argument("--image", required=True)
    p.add_argument("--file", required=True)
    p.add_argument("--lo", required=True)
    p.add_argument("--hi", required=True)
    p.add_argument("--entry", action="append", default=[])
    p.add_argument("--exclude", action="append", default=[])
    p.add_argument("--cut", action="append", default=[])
    p.add_argument("--no-auto", action="store_true")
    p.add_argument("--out", required=True)
    p = sub.add_parser("islands")
    p.add_argument("--image", required=True)
    p.add_argument("--plan", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--force-data", action="append", default=[],
                   help="data segment start to re-type even without byte-level evidence")
    p = sub.add_parser("apply")
    p.add_argument("--image", required=True)
    p.add_argument("--spec", required=True)
    p.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    os.makedirs(SCRATCH, exist_ok=True)
    {"map": cmd_map, "trace": cmd_trace, "refs": cmd_refs, "apply": cmd_apply,
     "plan": cmd_plan, "islands": cmd_islands}[a.cmd](a)


if __name__ == "__main__":
    main()
