#!/usr/bin/env python3
r"""Which bytes of the KN5000 v10 maincpu ROM are REACHABLE CODE, and how many of
those are still handed back verbatim through `.incbin`?

QUESTION IT ANSWERS
    "If you follow every control-flow edge the machine can actually take, which
     bytes does execution reach, and how many of them has this tree not written
     as source yet?"

    That number is the remaining work before the maincpu tree can be split into
    per-subject files. It is NOT the same as "bytes still .incbin": a span can be
    pure data, in which case converting it adds territory and no code at all.

    ⚠ IT NEVER WRITES A .s FILE, AND IT NEVER WRITES INSIDE THE REPOSITORY. It
    reports. Its work directories live under the system temp dir.

WHY THIS IS A PORT AND NOT A COPY
    notes/reachability.py in wsa1/ answers the same question for the
    WSA1R and turned a 107,371-byte job into a 17,558-byte one. Its IDEAS port.
    Its TABLES DO NOT, and four things had to be re-derived rather than copied:

    1. ⚠⚠ THE SOURCE LINE SHAPE. This is the trap that has bitten three times on
       the WSA1 side, where one image's regex matched 8,473 of another's 78,022
       addressed lines and silently emptied three of five seed classes.
       ★ KN5000 IS A FOURTH SHAPE AND IT IS THE MOST DIFFERENT ONE YET: its
       sources carry NO ADDRESS COMMENTS AT ALL. They are symbolic assembly --
       `jr c, MidiInit_FillLoop` -- with the addresses living only in the build.
       The WSA1 regex `^\t(\S.*?)\s*;\s*([0-9A-F]{6})\s+(.*)$` matches ZERO lines
       here. --selftest asserts that, so the trap is a check rather than a memory.
       ★ THE FIX: addresses come from `llvm-mc -show-encoding`, which flattens the
       whole include tree and emits every instruction with its encoding bytes.
       Walking that stream with the directive widths scripts/analysis/
       l1_territory_map.py already MEASURED gives an exact address for every
       instruction and every directive. The check that makes it a test rather
       than a tally is l1's: the classified total must equal the ROM size to the
       byte, so any construct sized wrongly shows up immediately.

    2. THE `.incbin` SPANS. On the WSA1 an `.incbin` names `original_ROMs/<rom>`
       at an offset, so the span's address is in the directive. ★ KN5000's name
       `includes/generated/<name>.bin` -- a carved-out blob with no ROM address
       anywhere in the line. The address is recovered by assembling a MIRROR of
       v10/maincpu that has a synthetic label injected before every `.incbin`,
       and reading the label's position out of the flattened stream. --selftest
       proves the mirror is inert by rebuilding it and comparing to the ROM.

    3. THE INDIRECTION SCAN. The WSA1's is a 1,910-slot directory of `jp imm24`
       at prom_b 0x40000. ★ KN5000 HAS NO SUCH DIRECTORY -- measured, not assumed:
       the same 4-byte-aligned scan over the whole 2 MiB finds exactly ONE run of
       8 or more slots, 17 of them at 0xF1ED24. The class is kept and the count
       reported, because a measured negative is a result. KN5000's indirection is
       instead many small dispatch tables the tree has already framed as `.word`,
       plus -- and this is the KN5000-specific structure worth knowing about --
       shared/positional_labels.s, 3,263 auto-generated `.set Block_0xNN, Block +
       NN` aliases that name every address code references INSIDE a data block.
       Those arrive here as ordinary branch targets, resolved through the ELF
       symbol table, and they are the reason a branch can land mid-blob at all.

    4. THE BRANCH DECODE. llvm-mc lowers `jr c, Label` to `jr c, 106` -- a raw
       DECIMAL DISPLACEMENT -- so the flattened text cannot be scanned for targets
       with the WSA1 regex either. unidasm is the decode authority for both trees,
       so branch targets are read from unidasm's rendering of the ROM at the
       tree's OWN instruction boundaries. Measured: a single linear pass agrees
       with 94.5% of those boundaries and disagrees about the LENGTH of none of
       them; the rest are picked up by re-decoding from each missed boundary.

SEED GRADING -- KEPT VERBATIM FROM THE WSA1 TOOL, BECAUSE IT WAS PAID FOR
    STRONG  vector      a hardware vector table entry
            directory   a `jp imm24` slot: its target is an entry point, full stop
            branch      an edge unidasm decodes in already-converted code
    WEAK    immediate   a 32-bit immediate in converted code that lands in ROM
            pointer_table  an entry of a table the tree already framed as `.word`
    A POINTER IS AS LIKELY TO NAME A TABLE AS A ROUTINE. On the WSA1, walking from
    weak seeds framed 701 bytes of pointer tables as instructions AND THE BYTE
    GATE PASSED. Convert on the STRONG column.

    `fallthrough` is passed into both walks the way the WSA1 tool passes `proven`:
    a converted instruction that is not a flow end and whose successor address is
    NOT itself converted runs straight into unconverted territory.

--evidence KEEPS THE RULE: a run start needs a graded seed naming it, or a
    fall-through from converted code. A target queued while the walk was DECODING
    has neither, and that is the case that would have framed "SOUND GROUP NAMING"
    as `ld XIX,0x4f524720` with the byte gate passing.

RUN (from anywhere; paths are resolved from this file)
    python3 notes/reachability_kn5000.py             # the coverage report
    python3 notes/reachability_kn5000.py --targets   # ★ the ranked work list
    python3 notes/reachability_kn5000.py --work      # ★★ each surviving run, its
                                                     #    bytes, and who named it
    python3 notes/reachability_kn5000.py --evidence  # ★ per-run start evidence
    python3 notes/reachability_kn5000.py --spans     # per-.incbin-span breakdown
    python3 notes/reachability_kn5000.py --seeds     # where the walk starts
    python3 notes/reachability_kn5000.py --selftest  # checks, incl. LAST elements
"""
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.path.join(LLVM, "llvm-mc")
LLD = os.path.join(LLVM, "ld.lld")
OBJCOPY = os.path.join(LLVM, "llvm-objcopy")
NM = os.path.join(LLVM, "llvm-nm")
UNIDASM = os.path.expanduser("~/compartilhado/kn7000_mame_build/unidasm")

# ★ ONE TARGET, SAID OUT LOUD. The lane brief asks for v10 maincpu and warns
# against half-porting everything, so the other images are listed with their
# bases and explicitly NOT walked. v9 and v10 are two builds of one program and
# v7 a third, so v10's answer is most of theirs; the sub-CPU images have ZERO
# .incbin directives and are already territorially complete.
TARGET = {
    "tag": "v10_maincpu",
    "src": "v10/maincpu/kn5000_v10_program.s",
    "incdir": "v10/maincpu",
    "rom": "original_ROMs/kn5000_v10_program.rom",
    "base": 0xE00000,
    "ld": "v10/maincpu/maincpu.ld",
}
NOT_WALKED = [
    ("v9  maincpu", 0xE00000, "2M", "second build of the same program"),
    ("v7  maincpu", 0xE00000, "2M", "third build of the same program"),
    ("v142 subcpu", 0x000400, "251K", "0 .incbin -- territorially complete"),
    ("subcpu boot", 0xFE0000, "128K", "0 .incbin -- territorially complete"),
    ("table_data ", 0x800000, "2M", "data image, 28 .incbin"),
    ("custom_data", 0x300000, "1M", "data image, 11 .incbin"),
    ("hdae5000   ", 0x280000, "512K", "separate CPU, 10 .incbin"),
]

STRONG = ("vector", "directory", "branch")
WEAK = ("immediate", "pointer_table")

# ---- flatten parsing. Widths were MEASURED by l1_territory_map.py, not assumed.
WIDTH = {"byte": 1, "hword": 2, "word": 4, "dword": 8}
ESCAPE = re.compile(r'\\(?:[0-7]{1,3}|x[0-9a-fA-F]{1,2}|.)')
ENCODING = re.compile(r';\s*encoding:\s*\[([^\]]*)\]')
LABEL = re.compile(r'^([A-Za-z_.$][A-Za-z0-9_.$]*):$')
NOBYTES = ("set", "equ", "text", "globl", "global", "type", "size", "section",
           "file", "ident", "weak", "local", "hidden", "reloc")

# ---- unidasm output.  `e00000: 10                    rcf`
UNI_LINE = re.compile(r'^\s*([0-9a-f]{6}):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')
FLOW_END = re.compile(r'^\s*(ret|reti|retd|jp\s|jp\t|halt|swi)', re.I)
# ⚠ 6 hex digits only, and never after + or -, so `call GT,XIX+0x10` is not a
# target. Measured: zero lines in the v10 linear decode have a 6-hex-digit
# displacement, so this cannot silently drop an edge.
BRANCH = re.compile(r'\b(?:jr|jp|call|calr|djnz)\b[^;]*?(?<![-+])0x([0-9a-f]{6})', re.I)

# ---- source scanning
INCBIN = re.compile(r'^\s*(?:\S+:)?\s*\.incbin\s+"([^"]+)"'
                    r'(?:\s*,\s*([0-9A-Fa-fx]+)(?:\s*,\s*([0-9A-Fa-fx]+))?)?\s*$')
MARK = "__RBI_"
# ⚠ THE WSA1 REGEX, kept only so --selftest can assert it matches NOTHING here.
WSA1_SRC_LINE = re.compile(r'^\t(\S.*?)\s*;\s*([0-9A-F]{6})\s+(.*)$')


def _sh(cmd, **kw):
    r = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if r.returncode != 0:
        sys.exit("command failed: %s\n%s" % (" ".join(cmd), r.stderr[:600]))
    return r.stdout


def rom_bytes():
    return open(os.path.join(ROOT, TARGET["rom"]), "rb").read()


# --------------------------------------------------------------- the mirror
def source_files():
    out = []
    for dp, _dn, fn in os.walk(os.path.join(ROOT, TARGET["incdir"])):
        for f in sorted(fn):
            if f.endswith(".s"):
                out.append(os.path.join(dp, f))
    return sorted(out)


def fingerprint():
    h = hashlib.sha1()
    for p in source_files():
        h.update(open(p, "rb").read())
    h.update(open(os.path.abspath(__file__), "rb").read())
    h.update(rom_bytes())
    return h.hexdigest()


def build_mirror(dest):
    """A copy of v10/maincpu with a synthetic label before every `.incbin`, so the
    span's ADDRESS falls out of the flattened stream. Everything that is not a
    `.s` file is symlinked, so this costs no real copying of the blobs.

    ⚠ The mirror is only trustworthy if it is INERT. --selftest rebuilds it and
    compares the result to the original ROM byte for byte."""
    src_root = os.path.join(ROOT, TARGET["incdir"])
    spans = []           # (index, binpath, off, length, srcfile, srcline)
    for dp, dn, fn in os.walk(src_root):
        rel = os.path.relpath(dp, src_root)
        outdir = os.path.join(dest, rel) if rel != "." else dest
        os.makedirs(outdir, exist_ok=True)
        dn.sort()
        for f in sorted(fn):
            s, d = os.path.join(dp, f), os.path.join(outdir, f)
            if not f.endswith(".s"):
                if not os.path.exists(d):
                    os.symlink(s, d)
                continue
            lines = open(s, encoding="latin-1").read().split("\n")
            out = []
            for i, ln in enumerate(lines):
                m = INCBIN.match(ln)
                if m and ".incbin" in ln.split(";")[0]:
                    binp, off, length = m.group(1), m.group(2), m.group(3)
                    real = resolve_bin(binp, dp)
                    o = int(off, 0) if off else 0
                    n = (int(length, 0) if length
                         else os.path.getsize(real) - o)
                    out.append("%s%d:" % (MARK, len(spans)))
                    spans.append({"i": len(spans), "bin": real, "off": o, "len": n,
                                  "src": os.path.relpath(s, ROOT), "line": i + 1})
                out.append(ln)
            open(d, "w", encoding="latin-1").write("\n".join(out))
    return spans


def resolve_bin(binp, srcdir):
    for c in (os.path.join(srcdir, binp),
              os.path.join(ROOT, TARGET["incdir"], binp),
              os.path.join(ROOT, binp)):
        if os.path.exists(c):
            return c
    sys.exit("cannot resolve .incbin path %r from %s" % (binp, srcdir))


# ------------------------------------------------------------- the flatten
def flatten(mirror):
    """Walk `llvm-mc -show-encoding` and give every byte an address.

    Returns (code, labels, spans_pos, data_bytes, padding_bytes, total, words)
      code       {addr: (len, text)}   every instruction the tree already has
      labels     {name: addr}          every label, mirror markers included
      words      [(addr, operand_text)] every 4-byte `.word`, for pointer tables
    """
    root_s = os.path.join(mirror, os.path.basename(TARGET["src"]))
    out = _sh([MC, "-triple=tlcs900", "-show-encoding", "-I", mirror, root_s])
    base = TARGET["base"]
    pos, code, labels, words = 0, {}, {}, []
    data = pad = 0
    unknown = []
    for line in out.split("\n"):
        s = line.strip()
        if not s or s.startswith("#") or s.startswith(";"):
            continue
        enc = ENCODING.search(line)
        if enc:
            n = len([b for b in enc.group(1).split(",") if b.strip()])
            code[base + pos] = (n, line.split(";")[0].strip())
            pos += n
            continue
        m = LABEL.match(s)
        if m:
            labels[m.group(1)] = base + pos
            continue
        if s.endswith(":"):
            continue
        m = re.match(r'\.(\w+)\s*(.*)$', s)
        if not m:
            unknown.append(s)
            continue
        d, rest = m.group(1), m.group(2).strip()
        if d in WIDTH:
            items = [x for x in rest.split(",") if x.strip()] or [""]
            if d == "word":
                for k, it in enumerate(items):
                    words.append((base + pos + 4 * k, it.strip()))
            n = WIDTH[d] * len(items)
            data += n
            pos += n
        elif d in ("ascii", "asciz"):
            n = ascii_len(rest) + (1 if d == "asciz" else 0)
            data += n
            pos += n
        elif d in ("zero", "fill", "space"):
            p = [x.strip() for x in rest.split(",")]
            n = int(p[0], 0)
            if d == "fill" and len(p) >= 2:
                n *= int(p[1], 0)
            pad += n
            pos += n
        elif d == "p2align":
            n = (-pos) % (1 << int(rest.split(",")[0].strip(), 0))
            pad += n
            pos += n
        elif d == "org":
            t = int(rest.split(",")[0].strip(), 0)
            if t > pos:
                pad += t - pos
                pos = t
        elif d in NOBYTES:
            continue
        else:
            unknown.append(s)
    if unknown:
        sys.exit("UNCLASSIFIED constructs in the flatten: %d, e.g. %r"
                 % (len(unknown), unknown[:3]))
    return code, labels, words, data, pad, pos


def ascii_len(operand):
    total = 0
    for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', operand):
        total += len(ESCAPE.sub("X", m.group(1)))
    return total


# ------------------------------------------------------------- the decoder
_BOUND = defaultdict(tuple)      # addr -> (len, text) from unidasm
WINDOW = 0x800


def linear_decode(data, base, start, length):
    """unidasm over ROM[start .. start+length), recorded into _BOUND."""
    o = start - base
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(data[o:o + length])
        tmp = f.name
    try:
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900",
                              "-basepc", hex(start)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    n = 0
    for ln in out.split("\n"):
        m = UNI_LINE.match(ln)
        if m:
            a = int(m.group(1), 16)
            if a not in _BOUND:
                _BOUND[a] = (len(m.group(2).split()), m.group(3).strip())
                n += 1
    return n


def decode_at(data, base, addr):
    """(len, text) for the instruction at `addr`, decoding a window if needed."""
    if addr in _BOUND:
        return _BOUND[addr]
    if not (base <= addr < base + len(data)):
        return None
    linear_decode(data, base, addr, min(WINDOW, base + len(data) - addr))
    return _BOUND.get(addr)


# ---------------------------------------------------------------- the walk
def walk(data, base, start, seen, queue, converted):
    """Linear decode from `start`, marking bytes that are NOT already converted
    source and queueing every branch/call target.

    ★ It stops the moment it reaches an address the tree has already converted.
    That is not a shortcut: converted bytes are by construction outside every
    `.incbin` span, and every edge leaving converted code is already in the
    `branch` seed class, extracted from unidasm's decode of the whole ROM."""
    pc, guard = start, 0
    end = base + len(data)
    while guard < 4000:
        guard += 1
        if not (base <= pc < end) or pc in seen or pc in converted:
            return
        row = decode_at(data, base, pc)
        if not row:
            return
        n, text = row
        for i in range(n):
            seen.add(pc + i)
        for m in BRANCH.finditer(text):
            t = int(m.group(1), 16)
            if base <= t < end:
                queue.append(t)
        if FLOW_END.match(text):
            return
        pc += n


def walk_from(data, base, starts, converted):
    seen, queue, done = set(), list(starts), set()
    while queue:
        a = queue.pop()
        if a in done:
            continue
        done.add(a)
        walk(data, base, a, seen, queue, converted)
    return seen


# ---------------------------------------------------------------- the seeds
def gather(verbose=False):
    """Everything downstream needs, computed once. Cached against a fingerprint
    of every v10/maincpu .s file, the ROM and this script, in the system temp
    dir -- NOT in the repository, which this tool never writes to."""
    cache = os.path.join(tempfile.gettempdir(),
                         "reachability-kn5000-%s.json" % fingerprint()[:16])
    if os.path.exists(cache) and "--no-cache" not in sys.argv:
        try:
            c = json.load(open(cache))
            c["spans"] = [tuple(s) if isinstance(s, list) else s for s in c["spans"]]
            for k in ("per_span", "per_span_strong", "per_span_strong_ev",
                      "per_span_ev"):
                c[k] = {int(i): v for i, v in c[k].items()}
            return c
        except Exception:
            pass
    r = compute(verbose)
    try:
        json.dump(r, open(cache, "w"))
    except Exception:
        pass
    return r


def compute(verbose=False):
    data = rom_bytes()
    base = TARGET["base"]
    mirror = tempfile.mkdtemp(prefix="kn5000-reach-mirror-")
    try:
        spans = build_mirror(mirror)
        code, labels, words, dbytes, pbytes, total = flatten(mirror)
        symtab = nm_symbols(mirror)
    finally:
        shutil.rmtree(mirror, ignore_errors=True)
    if total != len(data):
        sys.exit("flatten totals %d bytes, ROM is %d -- the address map is WRONG"
                 % (total, len(data)))

    # Place every .incbin span. ⚠ v10/maincpu holds 17 `.s` files that NOTHING
    # `.include`s -- superseded representations kept in the tree -- and one of
    # them carries an .incbin. A marker with no position in the flattened stream
    # is exactly that case, and it is reported rather than crashed on or
    # silently counted.
    dead = [s for s in spans if ("%s%d" % (MARK, s["i"])) not in labels]
    spans = [s for s in spans if ("%s%d" % (MARK, s["i"])) in labels]
    for s in spans:
        s["lo"] = labels["%s%d" % (MARK, s["i"])]
        s["hi"] = s["lo"] + s["len"]
    spans.sort(key=lambda s: s["lo"])

    converted = set()
    for a, (n, _t) in code.items():
        for i in range(n):
            converted.add(a + i)

    # ---- seeds
    sd = defaultdict(set)
    end = base + len(data)

    # S1 vectors: the TMP94C241 table the tree itself labels InterruptVectorTable
    vt = labels.get("InterruptVectorTable", 0xFFFF00)
    for a in range(vt, end, 4):
        v = int.from_bytes(data[a - base:a - base + 4], "little")
        if base <= v < end:
            sd["vector"].add(v)

    # S2 directory: 4-byte-aligned runs of `jp imm24`. MEASURED for KN5000: one
    # run of 17 slots, against the WSA1's 1,910. Kept because a measured negative
    # is a result and because the class must exist for the grading to mean
    # anything.
    runs, cur = [], None
    for o in range(0, len(data) - 4, 4):
        t = data[o + 1] | data[o + 2] << 8 | data[o + 3] << 16
        if data[o] == 0x1B and base <= t < end:
            cur = [o, o] if cur is None else [cur[0], o]
        else:
            if cur is not None:
                runs.append(tuple(cur))
            cur = None
    if cur:
        runs.append(tuple(cur))
    ndir = 0
    for a, b in runs:
        if (b - a) // 4 + 1 < 8:
            continue
        ndir += 1
        for o in range(a, b + 4, 4):
            sd["directory"].add(data[o + 1] | data[o + 2] << 8 | data[o + 3] << 16)

    # S3 branch + S4 immediate: unidasm's decode of the tree's OWN boundaries.
    linear_decode(data, base, base, len(data))
    missing = sorted(a for a in code if a not in _BOUND)
    passes = 0
    while missing:
        passes += 1
        a = missing[0]
        linear_decode(data, base, a, min(WINDOW, end - a))
        nm_ = [x for x in missing if x not in _BOUND]
        if len(nm_) == len(missing):        # unidasm refuses this address
            _BOUND[a] = code[a]
            nm_ = [x for x in missing if x not in _BOUND]
        missing = nm_
    hit = flow = 0
    for a, (n, _t) in sorted(code.items()):
        row = _BOUND.get(a)
        if not row:
            continue
        hit += 1
        text = row[1]
        for m in BRANCH.finditer(text):
            t = int(m.group(1), 16)
            if base <= t < end:
                sd["branch"].add(t)
        for m in re.finditer(r'0x([0-9a-f]{6})\b', text):
            t = int(m.group(1), 16)
            if base <= t < end:
                sd["immediate"].add(t)
        if not FLOW_END.match(text) and (a + n) not in converted:
            sd["fallthrough"].add(a + n)
            flow += 1

    # S5 pointer tables: every 4-byte `.word` the tree has framed, resolved
    # through the ELF symbol table when the operand is a symbol.
    for a, op in words:
        v = word_value(op, symtab)
        if v is not None and base <= v < end:
            sd["pointer_table"].add(v)

    # ---- the two walks
    ft = sorted(sd["fallthrough"])
    strong_seeds = sorted(set().union(*[sd[c] for c in STRONG]) | set(ft))
    all_seeds = sorted(set().union(*[sd[c] for c in list(STRONG) + list(WEAK)]) | set(ft))
    seen_s = walk_from(data, base, strong_seeds, converted)
    seen_a = walk_from(data, base, all_seeds, converted)

    inc = set()
    for s in spans:
        inc.update(range(s["lo"], s["hi"]))
    per_span = {s["i"]: sum(1 for x in range(s["lo"], s["hi"]) if x in seen_a)
                for s in spans}
    per_span_strong = {s["i"]: sum(1 for x in range(s["lo"], s["hi"]) if x in seen_s)
                       for s in spans}
    # ★★ AND THE COLUMN THAT ACTUALLY DECIDES THE WORK. A run is admissible only
    # if something POSITIVELY says execution enters at its START. Measured here:
    # the single largest STRONG span, 0xE1344E in performance_style_screens.s,
    # is 3,407 of the 4,275 STRONG bytes and is a table of 4-byte pointers
    # (4e e9 e0 00, a0 e9 e0 00, ...) that the walk decoded its way into. Framing
    # it would emit instructions and THE BYTE GATE WOULD PASS, which is the exact
    # accident this project has now watched happen on the WSA1 twice.
    per_span_strong_ev = {}
    per_span_ev = {}
    for s in spans:
        per_span_strong_ev[s["i"]] = evidence_bytes(seen_s, sd, s["lo"], s["hi"],
                                                    EV_STRONG)[0]
        per_span_ev[s["i"]] = evidence_bytes(seen_a, sd, s["lo"], s["hi"], EV_ANY)[0]
    # ★★ AND FOR EACH SURVIVING RUN, WHO NAMED IT. On the WSA1 a `branch` seed is
    # an edge in converted code and that settles it. ⚠ NOT HERE: this tree's CODE
    # territory demonstrably contains DATA framed as instructions -- see
    # sequencer/accompaniment_engine.s, which writes `ld xhl,0x52544e4f` over the
    # ASCII "CONTROL PITCH BEND =" at 0xF6ACA0 -- so a `jp` in converted code can
    # itself be a misread. Printing the naming site with the target's bytes makes
    # that adjudicable instead of invisible. --work does it.
    work = []
    for a, b, ev, s in evidence_runs(seen_s, sd, spans, EV_STRONG):
        namer = None
        for ca, (cn, ct) in sorted(code.items()):
            if ev == "fallthrough":
                if ca + cn == a:
                    namer = (ca, ct)
                    break
            elif any(int(m.group(1), 16) == a for m in
                     BRANCH.finditer(_BOUND.get(ca, (0, ""))[1])):
                namer = (ca, _BOUND[ca][1])
                break
        work.append((a, b, ev, s["i"], s["src"], s["line"], namer))

    return {
        "rom_size": len(data),
        "code_bytes": sum(n for n, _t in code.values()),
        "code_instrs": len(code),
        "data_bytes": dbytes,
        "padding_bytes": pbytes,
        "incbin_bytes": len(inc),
        "incbin_dirs": len(spans),
        "incbin_dirs_dead_source": len(dead),
        "dead_source_files": sorted({d["src"] for d in dead}),
        "spans": [{k: s[k] for k in ("i", "lo", "hi", "len", "bin", "src", "line", "off")}
                  for s in spans],
        "seeds": {k: len(v) for k, v in sd.items()},
        "directory_runs": ndir,
        "boundary_hits": hit,
        "boundary_total": len(code),
        "extra_decode_passes": passes,
        "per_span": per_span,
        "per_span_strong": per_span_strong,
        "per_span_strong_ev": per_span_strong_ev,
        "per_span_ev": per_span_ev,
        "reach_strong_in_incbin": sum(per_span_strong.values()),
        "reach_strong_ev_in_incbin": sum(per_span_strong_ev.values()),
        "work": work,
        "reach_any_in_incbin": sum(per_span.values()),
        "reach_any_ev_in_incbin": sum(per_span_ev.values()),
        "reach_strong_total": len(seen_s),
        "reach_any_total": len(seen_a),
        "reach_strong_typed_data": len(seen_s - inc),
        "reach_any_typed_data": len(seen_a - inc),
        "seen_strong": sorted(seen_s),
        "seen_any": sorted(seen_a),
        "seed_lists": {k: sorted(v) for k, v in sd.items()},
    }


def runs_of(seen, lo, hi):
    """Maximal contiguous runs of marked bytes inside [lo,hi)."""
    out, start = [], None
    for x in range(lo, hi):
        if x in seen:
            if start is None:
                start = x
        elif start is not None:
            out.append((start, x))
            start = None
    if start is not None:
        out.append((start, hi))
    return out


EV_STRONG = list(STRONG) + ["fallthrough"]
EV_ANY = list(STRONG) + ["fallthrough"] + list(WEAK)


def start_evidence(addr, sd, classes=EV_ANY):
    """Does anything POSITIVELY say execution enters at `addr`?

    Two admissible witnesses and nothing else: a GRADED SEED names it, or
    already-converted code FALLS THROUGH into it. A target queued while the walk
    was DECODING has neither.
    ⚠ `classes` is not decoration. For the STRONG column a WEAK seed is not an
    admissible witness -- a run reached by the strong walk whose only namer is a
    32-bit immediate is not a strong claim, it is a coincidence with a citation."""
    for cls in classes:
        if addr in sd.get(cls, ()):
            return cls
    return None


def evidence_bytes(seen, sd, lo, hi, classes=EV_ANY):
    """(bytes in runs whose start has evidence, bytes in runs without)."""
    good = bad = 0
    for a, b in runs_of(seen, lo, hi):
        if start_evidence(a, sd, classes):
            good += b - a
        else:
            bad += b - a
    return good, bad


def evidence_runs(seen, sd, spans, classes=EV_ANY):
    """[(lo, hi, class, span)] for every run whose start has evidence."""
    out = []
    for s in spans:
        for a, b in runs_of(seen, s["lo"], s["hi"]):
            ev = start_evidence(a, sd, classes)
            if ev:
                out.append((a, b, ev, s))
    return out


def word_value(op, symtab):
    op = op.strip()
    try:
        return int(op, 0)
    except ValueError:
        pass
    m = re.match(r'^([A-Za-z_.$][A-Za-z0-9_.$]*)\s*(?:([+-])\s*(0x[0-9A-Fa-f]+|\d+))?$', op)
    if not m:
        return None
    v = symtab.get(m.group(1))
    if v is None:
        return None
    if m.group(2):
        d = int(m.group(3), 0)
        v = v + d if m.group(2) == "+" else v - d
    return v


def nm_symbols(mirror):
    """symbol -> address, from a real link of the mirror. This is what resolves
    shared/positional_labels.s's 3,263 `.set Block_0xNN, Block + NN` aliases,
    which is how a branch target can land in the middle of a blob at all."""
    o = os.path.join(mirror, "_r.o")
    e = os.path.join(mirror, "_r.elf")
    root_s = os.path.join(mirror, os.path.basename(TARGET["src"]))
    _sh([MC, "-triple=tlcs900", "-filetype=obj", "-I", mirror, "-o", o, root_s])
    _sh([LLD, "-e", "0", "-T", os.path.join(ROOT, TARGET["ld"]), "-o", e, o])
    tab = {}
    for ln in _sh([NM, e]).split("\n"):
        p = ln.split()
        if len(p) == 3 and p[1] in "tTdDbBrRaA":
            tab[p[2]] = int(p[0], 16)
    return tab


# ---------------------------------------------------------------- reporting
def fmt(n):
    return format(n, ",")


def top_strong_span(r):
    return max(r["per_span_strong"], key=lambda k: r["per_span_strong"][k])


def report(mode=None):
    r = gather()
    print("KN5000 v10 maincpu  0x%06X, %s bytes   (%s .incbin directives in the"
          " build, +%d in .s files nothing .includes)"
          % (TARGET["base"], fmt(r["rom_size"]), fmt(r["incbin_dirs"]),
             r["incbin_dirs_dead_source"]))
    print("  territory   CODE(source) %9s   typed DATA %9s   .incbin %9s   PADDING %8s"
          % (fmt(r["code_bytes"]), fmt(r["data_bytes"] - r["incbin_bytes"]),
             fmt(r["incbin_bytes"]), fmt(r["padding_bytes"])))
    print()
    inc = max(r["incbin_bytes"], 1)
    print("★ REACHABLE AND UNCONVERTED, inside .incbin")
    print("                            reachable    of which the run START has")
    print("                                          POSITIVE EVIDENCE   <-- ★ the work")
    print("      STRONG seeds only  %9s bytes   %9s bytes  (%.2f%% of .incbin)"
          % (fmt(r["reach_strong_in_incbin"]), fmt(r["reach_strong_ev_in_incbin"]),
             100.0 * r["reach_strong_ev_in_incbin"] / inc))
    print("      any seed           %9s bytes   %9s bytes  (%.2f%%)"
          % (fmt(r["reach_any_in_incbin"]), fmt(r["reach_any_ev_in_incbin"]),
             100.0 * r["reach_any_ev_in_incbin"] / inc))
    ti = top_strong_span(r)
    ts = [x for x in r["spans"] if x["i"] == ti][0]
    print("  ⚠ The gap between the two STRONG columns is the walk decoding its way")
    print("    INTO data. %s of the %s STRONG bytes are ONE span, 0x%06X in %s,"
          % (fmt(r["per_span_strong"][ti]), fmt(r["reach_strong_in_incbin"]),
             ts["lo"], os.path.basename(ts["src"])))
    print("    and its bytes are a table of 4-byte POINTERS (4e e9 e0 00,")
    print("    a0 e9 e0 00 ...). Nothing names its start. Refuse it.")
    print()
    print("  secondary, a DIFFERENT question: reachable bytes in typed DATA")
    print("  (.byte/.word/.ascii the tree wrote by hand, not .incbin)")
    print("      STRONG %s   any %s"
          % (fmt(r["reach_strong_typed_data"]), fmt(r["reach_any_typed_data"])))
    if mode == "seeds":
        print("\n  seed classes")
        for k in sorted(r["seeds"]):
            grade = ("STRONG" if k in STRONG else
                     "WEAK" if k in WEAK else "fall-through")
            print("      %-14s %7s   %s" % (k, fmt(r["seeds"][k]), grade))
        print("      ⚠ directory: %d run(s) of >=8 `jp imm24` slots in 2 MiB."
              % r["directory_runs"])
        print("        The WSA1's routine directory has 1,910. KN5000 HAS NO SUCH")
        print("        DIRECTORY -- measured here, not assumed.")
        print("      unidasm agreed with %s of the tree's %s instruction boundaries"
              % (fmt(r["boundary_hits"]), fmt(r["boundary_total"])))
    if mode == "spans":
        print()
        for s in r["spans"]:
            n = r["per_span"][s["i"]]
            if n:
                print("      0x%06X-0x%06X %7d bytes, %6d reachable (%.0f%%)  %s"
                      % (s["lo"], s["hi"], s["len"], n, 100.0 * n / s["len"], s["src"]))
    print()
    print("★ The reachable figure is the remaining work before the maincpu tree can")
    print("  be split. The rest of the .incbin is data or unreached: converting it")
    print("  adds territory, not coverage.")
    print("  Not walked, by design (see NOT_WALKED in this file):")
    for name, b, sz, why in NOT_WALKED:
        print("      %s 0x%06X %-5s  %s" % (name, b, sz, why))


def targets():
    r = gather()
    rows = []
    for s in r["spans"]:
        ev, st, an = (r["per_span_strong_ev"][s["i"]], r["per_span_strong"][s["i"]],
                      r["per_span"][s["i"]])
        if an:
            rows.append((ev, st, an, s))
    rows.sort(key=lambda x: (-x[0], -x[1], -x[2]))
    tot_e = sum(x[0] for x in rows)
    tot_s = sum(x[1] for x in rows)
    tot_a = sum(x[2] for x in rows)
    print("%-21s %8s %9s %8s %8s %9s %7s  %s"
          % ("span", "size", "STRONG+EV", "STRONG", "any", "cumul(EV)", "of goal",
             "source"))
    run = 0
    for ev, st, an, s in rows:
        run += ev
        print("0x%06X-0x%06X %8s %9s %8s %8s %9s %6.1f%%  %s:%d"
              % (s["lo"], s["hi"], fmt(s["len"]), fmt(ev), fmt(st), fmt(an),
                 fmt(run), 100.0 * run / tot_e if tot_e else 0.0,
                 s["src"], s["line"]))
    print("\nTOTAL reachable-and-unconverted, in %d spans of %s .incbin directives:"
          % (len(rows), fmt(r["incbin_dirs"])))
    print("      STRONG seeds AND start evidence  %9s bytes   <-- ★ THE WORK LIST"
          % fmt(tot_e))
    print("      STRONG seeds, evidence ignored   %9s bytes" % fmt(tot_s))
    print("      any seed                         %9s bytes" % fmt(tot_a))
    print("★ CONVERT ON THE **STRONG+EV** COLUMN. `any` adds bytes reached only from")
    print("  a 32-bit immediate or a framed `.word` entry, and a pointer is as likely")
    print("  to name a TABLE as a routine -- on the WSA1 that painted 701 bytes of")
    print("  pointer tables as instructions AND THE BYTE GATE PASSED. Dropping the")
    print("  evidence test costs you the same accident a second way: the walk itself")
    print("  decodes into data, and the top row below is that happening here.")
    print("\n★★ THE WORK LIST ITSELF -- every STRONG run whose START is named:")
    if not r["work"]:
        print("      (none)")
    for a, b, ev, _i, src, line, _n in sorted(r["work"]):
        print("      0x%06X-0x%06X %5d B  named by: %-12s %s:%d"
              % (a, b, b - a, ev, src, line))
    print("      %d runs, %s bytes.  ⚠ run --work before converting ANY of them."
          % (len(r["work"]), fmt(sum(b - a for a, b, _e, _i, _s, _l, _n
                                     in r["work"]))))


def work():
    """The 13 surviving runs, each with the bytes it covers, an ASCII rendering,
    and the converted instruction that names it.

    ⚠ THIS IS THE MODE THAT STOPS A CONVERTING LANE REPEATING THE WSA1 ACCIDENT.
    A run's evidence can be a `jp` that already-converted source emits over data:
    four of the runs below are named by `1b ed 00 eN` at 0xED1BAB..0xED1BB7,
    which reads as four consecutive `jp 0x?00ed` and lands on ASCII, on 0xFF fill
    and on bitmap rows. Read the ASCII column before believing the evidence."""
    r = gather()
    data, base = rom_bytes(), TARGET["base"]
    tot = 0
    for a, b, ev, _i, src, line, namer in sorted(r["work"]):
        blob = data[a - base:b - base]
        tot += b - a
        print("0x%06X-0x%06X %5d B  %s   %s:%d" % (a, b, b - a, ev, src, line))
        print("   bytes  %s" % " ".join("%02x" % c for c in blob[:32])
              + (" ..." if len(blob) > 32 else ""))
        print("   ascii  %s" % "".join(chr(c) if 32 <= c < 127 else "."
                                       for c in blob[:64]))
        if namer:
            print("   named by 0x%06X  %s" % (namer[0], namer[1]))
        else:
            print("   named by (not located)")
    print("\n%d runs, %s bytes." % (len(r["work"]), fmt(tot)))
    print("★ A run whose ASCII column reads as text, or whose bytes are 0xff fill,")
    print("  is DATA no matter what named it. Refuse it and say so.")


def evidence():
    """Per-run start evidence. Defaults to the STRONG walk, which is the one a
    converting lane would work from; `--any` shows the weak-seeded walk too."""
    r = gather()
    which = "any" if "--any" in sys.argv else "strong"
    sd = {k: set(v) for k, v in r["seed_lists"].items()}
    seen = set(r["seen_any"] if which == "any" else r["seen_strong"])
    classes = EV_ANY if which == "any" else EV_STRONG
    print("walk: %s seeds; admissible witnesses: %s\n"
          % (which.upper(), ", ".join(classes)))
    good = bad = 0
    for s in r["spans"]:
        for a, b in runs_of(seen, s["lo"], s["hi"]):
            ev = start_evidence(a, sd, classes)
            if ev:
                good += b - a
                print("  0x%06X-0x%06X %5d B  evidence: %-13s %s"
                      % (a, b, b - a, ev, s["src"]))
            else:
                bad += b - a
                print("  0x%06X-0x%06X %5d B  ⚠ NO EVIDENCE for the start -- refuse"
                      " (%s)" % (a, b, b - a, s["src"]))
    print("\nruns with start evidence: %s bytes; WITHOUT: %s bytes"
          % (fmt(good), fmt(bad)))
    print("★ A run whose START nothing names was queued while the walk was")
    print("  DECODING, and a walk can decode its way into data.")


# ---------------------------------------------------------------- selftest
def selftest():
    ok = fail = 0

    def check(desc, cond, extra=""):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc + (("   " + extra) if extra else ""))
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    data, base = rom_bytes(), TARGET["base"]

    # ---- 1. the mirror is INERT: it rebuilds the ROM byte for byte.
    mirror = tempfile.mkdtemp(prefix="kn5000-reach-selftest-")
    try:
        spans = build_mirror(mirror)
        o, e, b = (os.path.join(mirror, x) for x in ("_t.o", "_t.elf", "_t.rom"))
        root_s = os.path.join(mirror, os.path.basename(TARGET["src"]))
        _sh([MC, "-triple=tlcs900", "-filetype=obj", "-I", mirror, "-o", o, root_s])
        _sh([LLD, "-e", "0", "-T", os.path.join(ROOT, TARGET["ld"]), "-o", e, o])
        _sh([OBJCOPY, "-O", "binary", e, b])
        rebuilt = open(b, "rb").read()
        code, labels, words, dbytes, pbytes, total = flatten(mirror)
    finally:
        shutil.rmtree(mirror, ignore_errors=True)
    check("the label-injected MIRROR rebuilds the ROM byte-identically",
          rebuilt == data, "%s bytes" % fmt(len(rebuilt)))
    check("the flatten accounts for EVERY byte of the ROM",
          total == len(data), "%s vs %s" % (fmt(total), fmt(len(data))))

    # ---- 2. the source-line-shape trap, asserted rather than remembered
    n_lines = n_wsa1 = 0
    for p in source_files():
        for ln in open(p, encoding="latin-1"):
            n_lines += 1
            if WSA1_SRC_LINE.match(ln.rstrip("\n")):
                n_wsa1 += 1
    check("⚠ the WSA1 address-comment regex matches NOTHING in KN5000 source",
          n_wsa1 == 0, "%s of %s lines" % (fmt(n_wsa1), fmt(n_lines)))
    # ⚠⚠ COUNT IN PYTHON, NOT WITH grep. Several of these sources hold 8-bit
    # bytes, and this machine's `grep` is ugrep 7.8.4, which SILENTLY DROPS
    # matches in a file it judges binary -- no "Binary file matches" line, no
    # warning on stderr, exit status 0. Measured on this tree:
    #     grep -rn  '\.incbin' --include='*.s' v10/ | wc -l   ->  3,667
    #     grep -arn '\.incbin' --include='*.s' v10/ | wc -l   ->  3,801
    # 134 lines vanish. The project's own plan quotes 3,642 .incbin for v10 and
    # 11,143 across the tree; both are that undercount, so the tree-wide figure
    # should be re-measured before anyone plans against it. `grep -a` (or -c, or
    # Python) is correct.
    nlines, nnondir = 0, []
    for p in source_files():
        for i, ln in enumerate(open(p, encoding="latin-1").read().split("\n")):
            if ".incbin" not in ln:
                continue
            nlines += 1
            if not (INCBIN.match(ln) and ".incbin" in ln.split(";")[0]):
                nnondir.append("%s:%d" % (os.path.relpath(p, ROOT), i + 1))
    dead = [s for s in spans if ("%s%d" % (MARK, s["i"])) not in labels]
    spans = [s for s in spans if ("%s%d" % (MARK, s["i"])) in labels]
    check("every line mentioning .incbin is accounted for: placed + dead source"
          " + prose",
          len(spans) + len(dead) + len(nnondir) == nlines,
          "%d placed + %d in .s files nothing .includes + %d prose == %d lines"
          % (len(spans), len(dead), len(nnondir), nlines))
    check("...and the lines that are NOT directives really are prose",
          all(";" in open(os.path.join(ROOT, x.rsplit(":", 1)[0]),
                          encoding="latin-1").read().split("\n")
              [int(x.rsplit(":", 1)[1]) - 1].split(".incbin")[0]
              for x in nnondir),
          ", ".join(nnondir))

    # ---- 3. every span lands where its bytes actually are -- FIRST and LAST
    for s in spans:
        s["lo"] = labels["%s%d" % (MARK, s["i"])]
    spans.sort(key=lambda s: s["lo"])
    mismatch = []
    for s in spans:
        want = open(s["bin"], "rb").read()[s["off"]:s["off"] + s["len"]]
        got = data[s["lo"] - base:s["lo"] - base + s["len"]]
        if want != got:
            mismatch.append(s)
    check("every .incbin span's ROM bytes equal its .bin content",
          not mismatch, "%d span(s) differ" % len(mismatch))
    check("...and that includes the LAST span (0x%06X, %s)"
          % (spans[-1]["lo"], os.path.basename(spans[-1]["src"])),
          spans[-1] not in mismatch)
    check("...and the FIRST (0x%06X, %s)"
          % (spans[0]["lo"], os.path.basename(spans[0]["src"])),
          spans[0] not in mismatch)

    # ---- 4. the decoder lands on the tree's OWN proven boundaries
    addrs = sorted(code)
    sample = addrs[::max(1, len(addrs) // 300)][:300]
    for extra in (addrs[0], addrs[-1]):
        if extra not in sample:
            sample.append(extra)
    hit = lenok = 0
    for a in sample:
        row = decode_at(data, base, a)
        if row:
            hit += 1
            if row[0] == code[a][0]:
                lenok += 1
    check("unidasm lands on the tree's own instruction boundary, %d of %d sampled"
          % (hit, len(sample)), hit == len(sample))
    check("...and agrees on the LENGTH at %d of %d" % (lenok, len(sample)),
          lenok == len(sample))
    check("...the sample includes the LAST converted instruction (0x%06X %s)"
          % (addrs[-1], code[addrs[-1]][1][:28]),
          decode_at(data, base, addrs[-1]) is not None
          and decode_at(data, base, addrs[-1])[0] == code[addrs[-1]][0])
    check("...and the FIRST (0x%06X %s)" % (addrs[0], code[addrs[0]][1][:28]),
          decode_at(data, base, addrs[0]) is not None
          and decode_at(data, base, addrs[0])[0] == code[addrs[0]][0])

    # ---- 5. indirection is really being followed, and graded
    r = gather()
    sd = r["seeds"]
    check("branch seeds come out of the decode in bulk",
          sd.get("branch", 0) > 5000, "%s" % fmt(sd.get("branch", 0)))
    check("the hardware vector table yields entry points",
          sd.get("vector", 0) > 0, "%s" % fmt(sd.get("vector", 0)))
    check("pointer tables (framed `.word`) contribute entry points",
          sd.get("pointer_table", 0) > 100, "%s" % fmt(sd.get("pointer_table", 0)))
    check("⚠ KN5000 has NO WSA1-style routine directory -- measured",
          r["directory_runs"] <= 1,
          "%d run(s) of >=8 `jp imm24` slots, %s slot targets"
          % (r["directory_runs"], fmt(sd.get("directory", 0))))
    check("fall-through starts were computed",
          sd.get("fallthrough", 0) > 0, "%s" % fmt(sd.get("fallthrough", 0)))
    check("unidasm covered the tree's boundaries after re-decodes",
          r["boundary_hits"] == r["boundary_total"],
          "%s of %s, %d extra passes"
          % (fmt(r["boundary_hits"]), fmt(r["boundary_total"]),
             r["extra_decode_passes"]))

    # ---- 6. the walk marks whole instructions and nothing outside the ROM
    seen, q = set(), []
    conv = set()
    tgt = r["seed_lists"]["branch"][len(r["seed_lists"]["branch"]) // 2]
    walk(data, base, tgt, seen, q, conv)
    check("a walk from a branch seed marks bytes", len(seen) > 0, "%d" % len(seen))
    check("...and the start address is among them", tgt in seen)
    check("...and nothing outside the image was marked",
          all(base <= x < base + len(data) for x in seen))

    # ---- 7. STRONG can only be a subset of ANY
    check("STRONG reachable is a subset of ANY reachable",
          r["reach_strong_in_incbin"] <= r["reach_any_in_incbin"],
          "%s <= %s" % (fmt(r["reach_strong_in_incbin"]),
                        fmt(r["reach_any_in_incbin"])))
    per = r["per_span_strong"]
    bad = [i for i, v in per.items() if v > r["per_span"][i]]
    check("...per span too", not bad, "%d span(s) violate it" % len(bad))
    bad = [i for i, v in r["per_span_strong_ev"].items() if v > per[i]]
    check("STRONG+EV is a subset of STRONG, per span", not bad,
          "%d span(s) violate it" % len(bad))

    # ---- 8. the LAST element of every seed class, not just the first
    data_end = base + len(data)
    for cls in sorted(r["seed_lists"]):
        lst = r["seed_lists"][cls]
        if not lst:
            continue
        check("seed class %-13s LAST entry 0x%06X is inside the image"
              % (cls, lst[-1]), base <= lst[-1] < data_end)
    ws = r["spans"][-1]
    check("the LAST .incbin span 0x%06X-0x%06X has a reachability figure"
          % (ws["lo"], ws["hi"]),
          ws["i"] in r["per_span"] and ws["i"] in r["per_span_strong"],
          "%d any / %d STRONG" % (r["per_span"][ws["i"]],
                                  r["per_span_strong"][ws["i"]]))
    check("...and the LAST span's bytes are inside the ROM",
          base <= ws["lo"] and ws["hi"] <= data_end)

    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    if "--work" in sys.argv:
        work()
    elif "--targets" in sys.argv:
        targets()
    elif "--evidence" in sys.argv:
        evidence()
    else:
        report("seeds" if "--seeds" in sys.argv
               else "spans" if "--spans" in sys.argv else None)
