#!/usr/bin/env python3
"""v1a_sweep.py -- V1a adversarial verifier, ENCODING TRUTH lens (wave 3a, stage T1).

Question: for every instruction family T1 touched, over the WHOLE register /
mode / displacement / sub-opcode field, does
  (1) llvm's decoder print the operation and every operand (register, order,
      displacement value, address, immediate, post-inc step) that MAME's
      unidasm reads from the same bytes, at the same length; and
  (2) does llvm's printed text re-assemble to exactly those bytes?

Built on notes/lanes/wave3a-2026-09-25/v1-interrupted/strict_sweep.py (V1's
unreviewed head start), with: full cross products, a post-increment STEP
check (MAME does not print the step, so the expected step is computed from the
register byte, 1 << (rb & 3), and compared with the step the llvm text states,
written or implied by the instruction's data size), and width-aware d8/d16.

Run:   python3 v1a_sweep.py [family ...]
       families: autoinc disp disp16full sri direct muldiv erp ei
Env:   MC=, OBJDUMP= pick a build (default: the pinned build/bin).
Out:   out/<family>.tsv (every non-OK or ASYM probe) + counts on stdout.
"""
import collections, os, re, subprocess, sys, tempfile

LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.environ.get("MC", LLVM + "/llvm-mc")
OBJDUMP = os.environ.get("OBJDUMP", LLVM + "/llvm-objdump")
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
SLOT = 16
TAIL = [0x34, 0x12, 0x78, 0x56]
CHUNK = 4000
HERE = os.path.dirname(os.path.abspath(__file__))
SCRATCH = os.environ.get("TMPDIR", os.path.expanduser("~/compartilhado/tmp"))
OUT = os.environ.get("OUTDIR", os.path.join(SCRATCH, "wave3a-fixround-out"))

OBJDUMP_RE = re.compile(r'^\s*([0-9a-f]+):\s((?:[0-9a-f]{2} )+)\s*(.*)$')
ENC_RE = re.compile(r'^\s*(.*?)\s*;\s*encoding:\s*\[([^\]]*)\]\s*$')
UNI_RE = re.compile(r'^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s*(.*)$')


def llvm_decode(blobs):
    res = [None] * len(blobs)
    for start in range(0, len(blobs), CHUNK):
        part = blobs[start:start + CHUNK]
        src = []
        for i, b in enumerate(part):
            src.append('.section .p%d,"ax"' % i)
            src.append(".byte " + ",".join(str(x) for x in b))
        with tempfile.TemporaryDirectory() as td:
            s, o = os.path.join(td, "b.s"), os.path.join(td, "b.o")
            open(s, "w").write("\n".join(src) + "\n")
            subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-o", o, s],
                           check=True, capture_output=True)
            r = subprocess.run([OBJDUMP, "-d", "--triple=tlcs900", o],
                               capture_output=True, text=True)
        cur = None
        for line in r.stdout.splitlines():
            if line.startswith("Disassembly of section .p"):
                cur = int(line[len("Disassembly of section .p"):].rstrip(":"))
                continue
            m = OBJDUMP_RE.match(line)
            if cur is not None and m and int(m.group(1), 16) == 0 and res[start + cur] is None:
                res[start + cur] = (len(m.group(2).split()), m.group(3).strip().replace("\t", " "))
    return res


def _encode_part(part):
    """Assemble one batch; if llvm-mc CRASHES (signal), split and retry so only the crashing
    line is lost -- it is reported as ("CRASH", ...)."""
    res = [None] * len(part)
    src = []
    for i, t in enumerate(part):
        src.append('.section .q%d,"ax"' % i)
        src.append("\t" + (t or "nop"))
    with tempfile.TemporaryDirectory() as td:
        s = os.path.join(td, "a.s")
        open(s, "w").write("\n".join(src) + "\n")
        r = subprocess.run([MC, "-triple=tlcs900", "--show-encoding", s],
                           capture_output=True, text=True)
    if r.returncode < 0:
        if len(part) == 1:
            return [("CRASH", (r.stderr.strip().splitlines() or ["signal %d" % -r.returncode])[0][:160])]
        h = len(part) // 2
        return _encode_part(part[:h]) + _encode_part(part[h:])
    cur = None
    for line in r.stdout.splitlines():
        st = line.strip()
        if st.startswith(".section\t.q") or st.startswith(".section .q"):
            cur = int(st.split(".q")[1].split(",")[0])
            continue
        m = ENC_RE.match(line)
        if m and cur is not None and res[cur] is None:
            raw = [x.strip() for x in m.group(2).split(",") if x.strip()]
            # a fixup placeholder is a bare letter ("A"), which int(x, 16) would read as 0x0a
            if all(x.lower().startswith("0x") for x in raw):
                res[cur] = bytes(int(x, 16) for x in raw)
            else:
                res[cur] = b"<fixup>"
    # errors: map line numbers back (2 lines per probe, text on line 2i+2)
    for line in r.stderr.splitlines():
        m = re.match(r'^.*?:(\d+):\d+: error: (.*)$', line)
        if m:
            i = (int(m.group(1)) - 2) // 2
            if 0 <= i < len(part):
                res[i] = ("ERR", m.group(2))   # an error wins over any bytes printed
    return res


def llvm_encode(texts):
    """-> bytes, b'<fixup>', ('ERR', message) or ('CRASH', message) per text."""
    res = []
    for start in range(0, len(texts), CHUNK):
        res += _encode_part(texts[start:start + CHUNK])
    return res


def mame_decode(blobs):
    res = [None] * len(blobs)
    img = bytearray()
    for b in blobs:
        img += b + bytes(SLOT - len(b))
    with tempfile.TemporaryDirectory() as td:
        f = os.path.join(td, "u.bin")
        open(f, "wb").write(img)
        r = subprocess.run([UNIDASM, f, "-arch", "tlcs900", "-basepc", "0"],
                           capture_output=True, text=True)
    for line in r.stdout.splitlines():
        m = UNI_RE.match(line)
        if not m:
            continue
        addr = int(m.group(1), 16)
        if addr % SLOT == 0 and addr // SLOT < len(blobs):
            res[addr // SLOT] = (len(m.group(2).split()), m.group(3).strip())
    return res


# ---------------------------------------------------------------- normaliser
def split_ops(s):
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur.strip()); cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


NUM = r'(?:0x[0-9a-f]+|[0-9]+)'
R8 = set("a w c b e d l h ixl ixh iyl iyh izl izh spl sph qa qw qc qb qe qd ql qh".split())
R16 = set("wa bc de hl ix iy iz sp qwa qbc qde qhl qix qiy qiz qsp".split())
R32 = set("xwa xbc xde xhl xix xiy xiz xsp".split())


def num(s):
    s = s.strip()
    neg = s.startswith("-")
    if neg or s.startswith("+"):
        s = s[1:]
    v = int(s, 16) if s.startswith("0x") else int(s)
    return -v if neg else v


def norm_llvm_op(op):
    o = op.strip().lower()
    o = re.sub(r':opc$|:imm\d*$', '', o)          # encoding selectors on immediates
    inner = o[1:-1].strip() if o.startswith("(") and o.endswith(")") else None
    paren = inner is not None
    body = inner if paren else o
    if paren:
        m = re.fullmatch(r'-\s*([a-z][a-z0-9]*)(?::(\d))?', body)
        if m:
            return ("pre", m.group(1)), (int(m.group(2)) if m.group(2) else None)
        m = re.fullmatch(r'([a-z][a-z0-9]*)\s*\+\s*(?::(\d))?', body)
        if m:
            return ("post", m.group(1)), (int(m.group(2)) if m.group(2) else None)
        m = re.fullmatch(r'([a-z][a-z0-9]*)\s*([+-])\s*(' + NUM + r')(?::(8|16))?', body)
        if m:
            d = num(m.group(3)) * (-1 if m.group(2) == "-" else 1)
            return ("mem", m.group(1), d), None
        m = re.fullmatch(r'([a-z][a-z0-9]*)\s*\+\s*([a-z][a-z0-9]*)', body)
        if m:
            return ("idx", m.group(1), m.group(2)), None
        m = re.fullmatch(r'([a-z][a-z0-9]*)', body)
        if m:
            return ("mem", m.group(1), 0), None
        m = re.fullmatch(r'(-?' + NUM + r')(?::(8|16|24))?', body)
        if m:
            return ("abs", num(m.group(1)) & 0xffffff), None
    else:
        m = re.fullmatch(r'(-?' + NUM + r')', body)
        if m:
            return ("imm", num(m.group(1))), None
        m = re.fullmatch(r'[a-z][a-z0-9]*', body)
        if m:
            return ("reg", body), None
    return ("?", op), None


def norm_mame_op(op, ea):
    o = op.strip()
    ol = o.lower()
    inner = ol[1:-1] if ol.startswith("(") and ol.endswith(")") else None
    paren = inner is not None
    body = inner if paren else ol
    if paren or ea:
        m = re.fullmatch(r'-([a-z][a-z0-9]*)', body)
        if m:
            return ("pre", m.group(1))
        m = re.fullmatch(r'([a-z][a-z0-9]*)\+', body)
        if m:
            return ("post", m.group(1))
        m = re.fullmatch(r'([a-z][a-z0-9]*)\+0x([0-9a-f]+)', body)
        if m:
            h = m.group(2)
            v = int(h, 16)
            bits = 4 * len(h)
            if v >= 1 << (bits - 1):
                v -= 1 << bits
            return ("mem", m.group(1), v)
        m = re.fullmatch(r'([a-z][a-z0-9]*)\+([a-z][a-z0-9]*)', body)
        if m:
            return ("idx", m.group(1), m.group(2))
        m = re.fullmatch(r'0x([0-9a-f]+)', body)
        if m and (paren or ea):
            return ("abs", int(m.group(1), 16))
        m = re.fullmatch(r'([a-z][a-z0-9]*)', body)
        if m and (paren or body.startswith("x")):
            return ("mem", body, 0)
    if not paren:
        m = re.fullmatch(r'0x([0-9a-f]+)', body)
        if m:
            return ("imm", int(m.group(1), 16))
        m = re.fullmatch(r'[0-9]+', body)
        if m:
            return ("imm", int(body))
        m = re.fullmatch(r'[a-z][a-z0-9\']*', body)
        if m:
            return ("reg", body)
    return ("?", op)


FAM = {"ldw": "ld", "ldl": "ld", "pushw": "push", "popw": "pop", "cpw": "cp", "addw": "add",
       "adcw": "adc", "subw": "sub", "sbcw": "sbc", "andw": "and", "orw": "or", "xorw": "xor",
       "incw": "inc", "decw": "dec", "rlcw": "rlc", "rrcw": "rrc", "rlw": "rl", "rrw": "rr",
       "slaw": "sla", "sraw": "sra", "sllw": "sll", "srlw": "srl", "ldiw": "ldi", "ldirw": "ldir",
       "lddw": "ldd", "lddrw": "lddr", "cpiw": "cpi", "cpirw": "cpir", "cpdw": "cpd",
       "cpdrw": "cpdr", "exw": "ex"}


def fam(m):
    return FAM.get(m.lower(), m.lower())


def imm_eq(a, b):
    return (a - b) % (1 << 32) == 0 or (a & 0xffff) == b or (a & 0xff) == b


def human_step(mnem, lops):
    """The step a reader takes from an llvm (R+)/(-R) written WITHOUT :N."""
    m = mnem.lower()
    if m in ("lda", "jp", "call"):
        return None  # no data size: the text must state the step
    regs = [o[1] for o in lops if o[0] == "reg"]
    sizes = [1 if r in R8 else 2 if r in R16 else 4 if r in R32 else 0 for r in regs]
    sizes = [s for s in sizes if s]
    if m in ("mul", "muls", "div", "divs") and sizes:
        return sizes[0] // 2
    if m in ("andcf", "orcf", "xorcf", "ldcf", "stcf", "bit", "set", "res", "chg", "tset"):
        return 1
    if sizes:
        return max(sizes)
    if m.endswith("w"):
        return 2
    return 1


def compare(ltext, mtext, rbyte_step=None):
    lm, _, lo = ltext.partition(" ")
    mm, _, mo = mtext.partition(" ")
    lm, mm = lm.lower(), mm.lower()
    lparsed = [norm_llvm_op(x) for x in split_ops(lo)] if lo.strip() else []
    lops = [p[0] for p in lparsed]
    steps = [p[1] for p in lparsed]
    ms = split_ops(mo) if mo.strip() else []
    mops = []
    for i, x in enumerate(ms):
        ea = (mm == "lda" and i == 1) or (mm in ("jp", "call") and i == len(ms) - 1)
        mops.append(norm_mame_op(x, ea))
    if mm in ("inc", "dec", "incw", "decw", "incl", "decl") and mops and mops[0] == ("imm", 0):
        mops[0] = ("imm", 8)
    if mm in ("jp", "call", "ret", "jr", "jrl") and mops and mops[0] == ("reg", "t"):
        mops = mops[1:]
    if any(o[0] == "?" for o in lops):
        return "UNPARSED_LLVM"
    if any(o[0] == "?" for o in mops):
        return "UNPARSED_MAME"
    if fam(lm) != fam(mm):
        return "MNEM"
    if len(lops) != len(mops):
        return "NOPS"
    for a, b in zip(lops, mops):
        if a[0] == "imm" and b[0] == "imm":
            if not imm_eq(a[1], b[1]):
                return "OPERAND"
        elif a != b:
            return "OPERAND"
    if rbyte_step is not None:
        for o, st in zip(lops, steps):
            if o[0] in ("pre", "post"):
                said = st if st is not None else human_step(lm, lops)
                if said is None:
                    return "STEP_MISSING"
                if said != rbyte_step:
                    return "STEP"
    return "OK"


# ---------------------------------------------------------------- probe sets
ALL = list(range(256))
REP_SUBS = sorted(set(list(range(0x00, 0x08)) + [0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0e, 0x10, 0x11,
                  0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1c, 0x20, 0x21, 0x27, 0x28, 0x29,
                  0x2b, 0x2c, 0x30, 0x31, 0x33, 0x37, 0x38, 0x39, 0x3c, 0x3f, 0x40, 0x41, 0x44, 0x48, 0x50,
                  0x51, 0x58, 0x60, 0x61, 0x67, 0x68, 0x70, 0x78, 0x80, 0x81, 0x88, 0x90, 0x98, 0xa0, 0xa7,
                  0xa8, 0xb0, 0xb7, 0xb8, 0xc0, 0xc7, 0xc8, 0xcf, 0xd0, 0xd8, 0xe0, 0xe8, 0xf0, 0xf1, 0xf8,
                  0xff]))


def probes(family):
    out = []
    if family == "autoinc":
        for p in (0xC4, 0xC5, 0xD4, 0xD5, 0xE4, 0xE5, 0xF4, 0xF5):
            for rb in ALL:
                for s in ALL:
                    out.append(("%02x" % p, bytes([p, rb, s] + TAIL)))
    elif family == "disp":
        # (Xrr+d8): whole d8 field x representative subs, and edge d8 x every sub
        for base in (0x88, 0x98, 0xA8, 0xB8):
            for r in range(8):
                for d in ALL:
                    for s in REP_SUBS:
                        out.append(("%02x+r:d8" % base, bytes([base + r, d, s] + TAIL)))
                for d in (0x00, 0x7f, 0x80, 0xff):
                    for s in ALL:
                        if s not in REP_SUBS:
                            out.append(("%02x+r:d8e" % base, bytes([base + r, d, s] + TAIL)))
        for base in (0x80, 0x90, 0xA0, 0xB0):
            for r in range(8):
                for s in ALL:
                    out.append(("%02x+r" % base, bytes([base + r, s] + TAIL)))
    elif family == "sri":
        # (Xrr+d16) / (Xrr) / indexed through C3/D3/E3/F3: whole mode byte x d16 edges x subs
        D16 = (0x0000, 0x0001, 0x0005, 0x007f, 0x0080, 0x00ff, 0x0100, 0x7fff, 0x8000,
               0xff7f, 0xff80, 0xff81, 0xfffb, 0xffff)
        for p in (0xC3, 0xD3, 0xE3, 0xF3):
            for mb in ALL:
                for d16 in D16:
                    for s in REP_SUBS:
                        out.append(("%02x" % p, bytes([p, mb, d16 & 0xff, d16 >> 8, s] + TAIL[:3])))
            for mb in (0xe1, 0xe5, 0xf9, 0xfd):
                for d16 in (0x0000, 0x007f, 0x0080, 0xff80, 0x0100):
                    for s in ALL:
                        if s not in REP_SUBS:
                            out.append(("%02x-all" % p, bytes([p, mb, d16 & 0xff, d16 >> 8, s] + TAIL[:3])))
    elif family == "disp16full":
        # the whole d16 field on four representative instructions
        for d16 in range(65536):
            lo, hi = d16 & 0xff, d16 >> 8
            out.append(("f3fd..30", bytes([0xF3, 0xFD, lo, hi, 0x30] + TAIL[:3])))
            out.append(("c3e5..21", bytes([0xC3, 0xE5, lo, hi, 0x21] + TAIL[:3])))
            out.append(("d3f1..88", bytes([0xD3, 0xF1, lo, hi, 0x89] + TAIL[:3])))
            out.append(("e3e9..60", bytes([0xE3, 0xE9, lo, hi, 0x60] + TAIL[:3])))
    elif family == "direct":
        addrs = {0: [[0x00], [0x1e], [0x7f], [0x80], [0xff]],
                 1: [[0x00, 0x00], [0x1e, 0x23], [0xff, 0xff], [0xff, 0x00], [0x00, 0x01], [0x80, 0x00]],
                 2: [[0x00, 0x00, 0x00], [0x1e, 0x23, 0x00], [0xff, 0xff, 0xff], [0x56, 0x34, 0x12],
                     [0xff, 0x00, 0x00], [0xff, 0xff, 0x00], [0x00, 0x00, 0x01]]}
        for hi in (0xC0, 0xD0, 0xE0, 0xF0):
            for lo in (0, 1, 2):
                for a in addrs[lo]:
                    for s in ALL:
                        out.append(("%02x" % (hi + lo), bytes([hi + lo] + a + [s] + TAIL)))
    elif family == "muldiv":
        for p in list(range(0xC8, 0xD0)) + list(range(0xD8, 0xE0)) + list(range(0xE8, 0xF0)):
            for s in list(range(0x08, 0x10)) + list(range(0x40, 0x60)):
                out.append(("%02x" % p, bytes([p, s] + TAIL)))
        for p in (0xC7, 0xD7, 0xE7):
            for rb in ALL:
                for s in list(range(0x08, 0x10)) + list(range(0x40, 0x60)):
                    out.append(("%02x" % p, bytes([p, rb, s] + TAIL)))
        mems = [[0x80 + r] for r in range(8)] + [[0x88 + r, d] for r in range(8) for d in (0, 5, 0x80)]
        mems += [[0xC0, 0x1e], [0xC1, 0x1e, 0x23], [0xC2, 0x1e, 0x23, 0x00], [0xC3, 0xe5, 0x05, 0x00],
                 [0xC4, 0xe9], [0xC5, 0xe9], [0xC5, 0x35], [0xC4, 0x02]]
        for mm in mems:
            for size in (0, 0x10, 0x20):
                pre = [mm[0] + size] + mm[1:]
                for s in range(0x40, 0x60):
                    out.append(("%02x-mem" % pre[0], bytes(pre + [s] + TAIL)))
    elif family == "erp":
        for p in (0xC7, 0xD7, 0xE7):
            for rb in ALL:
                for s in ALL:
                    out.append(("%02x" % p, bytes([p, rb, s] + TAIL)))
    elif family == "ei":
        for v in ALL:
            out.append(("06", bytes([0x06, v] + TAIL)))
    return out


def run(family):
    pr = probes(family)
    blobs = [b for _, b in pr]
    ld = llvm_decode(blobs)
    md = mame_decode(blobs)
    texts = [(x[1] if x and not x[1].startswith("<unknown>") else None) for x in ld]
    enc = llvm_encode([t or "nop" for t in texts])
    c = collections.Counter()
    bygroup = collections.defaultdict(collections.Counter)
    rows = []
    for (g, b), l, m, t, e in zip(pr, ld, md, texts, enc):
        if t is None:
            mt = m[1] if m else ""
            v = "BOTH_REFUSE" if (m is None or mt.split()[0].lower() == "db" or "??" in mt) else "MAME_ONLY"
            c[v] += 1
            bygroup[g][v] += 1
            if v == "MAME_ONLY":
                rows.append((v, g, b.hex(" "), "", mt, ""))
            continue
        asym = ""
        if e is None:
            asym = "NOREENC"
        elif isinstance(e, tuple):
            asym = "REENC_ERR:" + e[1]
        elif e != b"<fixup>" and e != b[:l[0]]:
            asym = "ASYM:" + e.hex(" ")
        step = None
        if family == "autoinc" or (b[0] in (0xC4, 0xC5, 0xD4, 0xD5, 0xE4, 0xE5, 0xF4, 0xF5)):
            step = 1 << (b[1] & 3)
        if m is None or m[1].split()[0].lower() == "db" or "??" in m[1]:
            v = "LLVM_ONLY"
        elif m[0] != l[0]:
            v = "LEN"
        else:
            v = compare(t, m[1], step)
        c[v] += 1
        bygroup[g][v] += 1
        if asym:
            c["ASYM"] += 1
            bygroup[g]["ASYM"] += 1
        if v != "OK" or asym:
            rows.append((v, g, b[:l[0]].hex(" "), t, m[1] if m else "", asym))
    print("== %s: %d probes" % (family, len(pr)))
    for k, n in sorted(c.items()):
        print("   %-14s %7d" % (k, n))
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "%s.tsv" % family), "w") as fo:
        fo.write("class\tgroup\tbytes\tllvm\tmame\tasym\n")
        for r in rows:
            fo.write("\t".join(r) + "\n")
    with open(os.path.join(OUT, "%s.counts" % family), "w") as fo:
        fo.write("total %d\n" % len(pr))
        for k, n in sorted(c.items()):
            fo.write("%s %d\n" % (k, n))
        for g in sorted(bygroup):
            fo.write("[%s] %s\n" % (g, " ".join("%s=%d" % kv for kv in sorted(bygroup[g].items()))))


if __name__ == "__main__":
    for f in sys.argv[1:] or ["ei", "direct", "muldiv", "disp", "sri", "disp16full", "autoinc", "erp"]:
        run(f)
