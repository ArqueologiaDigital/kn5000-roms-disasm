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
SCRATCH = os.environ.get("SCOOP_SCRATCH", "/tmp/claude-1000/lane-scoop")
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
    return a2n, n2a


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
        override[rel] = "\n".join(out)
        marks[rel] = len(lines)
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
def unidasm(img, addr, count, data=None):
    """Linear unidasm from addr: [(addr, len, text)]."""
    d = data or rom(img)
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
    """Recursive descent with unidasm.  Returns (insns{addr:(len,text)},
    external_targets, conflicts)."""
    insns, todo, ext, conflicts = {}, list(entries), set(), []
    covered = {}
    while todo:
        a = todo.pop()
        if a in insns or not (lo <= a < hi):
            if not (lo <= a < hi):
                ext.add(a)
            continue
        while lo <= a < hi and a not in insns:
            if a in covered:
                conflicts.append((a, covered[a]))
                break
            dec = unidasm(img, a, 16, data)
            if not dec:
                conflicts.append((a, None))
                break
            _, n, text = dec[0]
            if text.startswith("db"):
                conflicts.append((a, "undecodable"))
                break
            insns[a] = (n, text)
            for k in range(a + 1, a + n):
                covered[k] = a
            op = text.split()[0].lower()
            if op in ("jr", "jrl", "call", "calr", "djnz", "jp") and "(" not in text \
                    and "+" not in text.split(",")[-1]:
                t = uni_target(text)
                if t is not None:
                    todo.append(t)
            if op in ("ret", "reti", "retd"):
                if op in ("ret",) and "," in text:
                    pass              # conditional ret
                elif len(text.split()) == 1 or op != "ret":
                    break
            if op in ("jp", "jr", "jrl") and ("," not in text or text.split(None, 1)[1].startswith("T,")):
                break
            if op == "swi" or op == "halt":
                conflicts.append((a, text))
                break
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
    """Assemble each text as its own source line; -> [bytes or None]."""
    with tempfile.TemporaryDirectory(dir=SCRATCH) as td:
        src = os.path.join(td, "rt.s")
        open(src, "w", encoding="latin-1").write("\n".join(t.strip() for t in texts) + "\n")
        r = subprocess.run([os.path.join(LLVM, "llvm-mc"), "-triple=tlcs900", "-show-encoding", src],
                           capture_output=True, text=True)
    bad = {int(m.group(1)) for m in re.finditer(r'rt\.s:(\d+):\d+: error', r.stderr)}
    encs = [bytes(int(x, 0) for x in m.group(1).split(",") if x.strip())
            for m in re.finditer(r'encoding: \[([^\]]*)\]', r.stdout)]
    out, k = [], 0
    for i in range(len(texts)):
        if i + 1 in bad:
            out.append(None)
        else:
            out.append(encs[k] if k < len(encs) else None)
            k += 1
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


def render_code(img, start, data, a2n, local=None, allow_mismatch=False):
    """Frame by unidasm (independent decoder); spell each instruction with the
    LLVM backend when its decode has the same length AND re-assembles to the
    same bytes, else as `.byte` with unidasm's reading in a comment."""
    uni = unidasm(img, start, len(data))
    if not uni or uni[0][0] != start or sum(n for _, n, _ in uni) != len(data):
        raise SystemExit("unidasm framing of 0x%06X+%d does not tile the segment: %s"
                         % (start, len(data), uni[-3:] if uni else uni))
    llvm = {}
    off = 0
    for n, text, raw in objdump(data):
        llvm[start + off] = (n, text)
        off += n
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
    out, problems = [], []
    for (a, n, ut, t), er, eh, h in zip(cands, enc_raw, enc_hex, hx):
        want = bytes(data[a - start:a - start + n])
        if t is not None and eh == want:
            spelled = h
        elif t is not None and er == want:
            spelled = t
        else:
            spelled = None
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
                 if addrs[i] is not None and addrs[i] >= b and ext[i] > 0), None)
    if last is None:
        raise SystemExit("no line starts at/after 0x%06X" % b)
    if addrs[last] != b:
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
    for ad, _, kind, t in carry:
        if kind == "label" and ad not in starts:
            raise SystemExit("label %s at 0x%06X would fall inside a rendered line" % (t, ad))
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


def cmd_plan(args):
    img, rel = args.image, args.file
    lo, hi = int(args.lo, 16), int(args.hi, 16)
    amap, elf = linemap(img, [rel])
    a2n, n2a = symbols(elf)
    addrs = amap[rel]
    ext = line_extents(addrs)
    lines = open(os.path.join(ROOT, rel), encoding="latin-1").read().split("\n")
    first = next(i for i, x in enumerate(addrs) if x == lo and ext[i] > 0)
    last = next(i for i in range(first, len(addrs)) if addrs[i] is not None and addrs[i] >= hi and ext[i] > 0)
    if addrs[last] != hi:
        raise SystemExit("hi 0x%06X is not a line boundary" % hi)
    skip = {(rel, i) for i in range(first, last)}
    br, oth = scan_refs(img, n2a, lo, hi, skip)
    entries = set(br) | {int(e, 16) for e in args.entry}
    entries -= {int(e, 16) for e in args.exclude}
    insns, extt, conf = trace(img, lo, hi, sorted(entries))
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
    cuts = set(keep_at) | set(oth) | {int(x, 16) for x in args.cut}
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
             "segments": segs, "drop_labels": drop}]
    json.dump(spec, open(args.out, "w"), indent=1)
    cb = len(code & set(range(lo, hi)))
    print("span 0x%06X-0x%06X %d B: code %d B in %d insns, data %d B; entries %d; dropped labels %d"
          % (lo, hi, hi - lo, cb, len(insns), hi - lo - cb, len(entries), len(drop)))
    print("entries:", " ".join("0x%06X" % e for e in sorted(entries)))
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
    p.add_argument("--out", required=True)
    p = sub.add_parser("apply")
    p.add_argument("--image", required=True)
    p.add_argument("--spec", required=True)
    p.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    os.makedirs(SCRATCH, exist_ok=True)
    {"map": cmd_map, "trace": cmd_trace, "refs": cmd_refs, "apply": cmd_apply,
     "plan": cmd_plan}[a.cmd](a)


if __name__ == "__main__":
    main()
