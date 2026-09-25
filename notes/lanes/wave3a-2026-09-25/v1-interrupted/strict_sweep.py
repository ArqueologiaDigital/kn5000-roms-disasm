#!/usr/bin/env python3
"""strict_sweep.py -- adversarial verifier for wave-3a stage T1.

Question: for the instruction families T1 touched (post-inc/pre-dec, displacement
width, direct-address forms, MUL/DIV, ERP LD, di/ei), does the llvm decoder print
text whose OPERANDS (registers, direction, displacement values, addresses,
immediates) mean what MAME's unidasm reads from the same bytes, and does that
text re-encode to exactly those bytes?

Unlike two_decoder_sweep.py (register-name multiset only, one register per
prefix), this compares every operand, including numeric values, and varies the
register byte / mode byte / displacement over the whole field.

Run: python3 strict_sweep.py [family ...]   (families: autoinc disp direct muldiv erp ei)
Output: per-family counts + every mismatch to out_<family>.tsv
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
        with tempfile.TemporaryDirectory(dir=HERE) as td:
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


def llvm_encode(texts):
    res = [None] * len(texts)
    for start in range(0, len(texts), CHUNK):
        part = texts[start:start + CHUNK]
        src = []
        for i, t in enumerate(part):
            src.append('.section .q%d,"ax"' % i)
            src.append("\t" + (t or "nop"))
        with tempfile.TemporaryDirectory(dir=HERE) as td:
            s = os.path.join(td, "a.s")
            open(s, "w").write("\n".join(src) + "\n")
            r = subprocess.run([MC, "-triple=tlcs900", "--show-encoding", s],
                               capture_output=True, text=True)
        cur = None
        for line in r.stdout.splitlines():
            st = line.strip()
            if st.startswith(".section\t.q") or st.startswith(".section .q"):
                cur = int(st.split(".q")[1].split(",")[0])
                continue
            m = ENC_RE.match(line)
            if m and cur is not None and res[start + cur] is None:
                raw = [x.strip() for x in m.group(2).split(",") if x.strip()]
                try:
                    res[start + cur] = bytes(int(x, 16) for x in raw)
                except ValueError:
                    res[start + cur] = b"<fixup>"
    return res


def mame_decode(blobs):
    res = [None] * len(blobs)
    img = bytearray()
    for b in blobs:
        img += b + bytes(SLOT - len(b))
    with tempfile.TemporaryDirectory(dir=HERE) as td:
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


def num(s):
    s = s.strip()
    neg = s.startswith("-")
    if neg or s.startswith("+"):
        s = s[1:]
    v = int(s, 16) if s.startswith("0x") else int(s)
    return -v if neg else v


def norm_llvm_op(op):
    o = op.strip().lower()
    inner = o[1:-1].strip() if o.startswith("(") and o.endswith(")") else None
    paren = inner is not None
    body = inner if paren else o
    m = re.fullmatch(r'-\s*([a-z][a-z0-9]*)(?::(\d))?', body)
    if m and paren:
        return ("pre", m.group(1))
    m = re.fullmatch(r'([a-z][a-z0-9]*)\s*\+\s*(?::(\d))?', body)
    if m and paren:
        return ("post", m.group(1))
    m = re.fullmatch(r'([a-z][a-z0-9]*)\s*([+-])\s*(' + NUM + r')(?::(8|16))?', body)
    if m and paren:
        d = num(m.group(3)) * (-1 if m.group(2) == "-" else 1)
        return ("mem", m.group(1), None, d)
    m = re.fullmatch(r'([a-z][a-z0-9]*)\s*\+\s*([a-z][a-z0-9]*)', body)
    if m and paren:
        return ("idx", m.group(1), m.group(2))
    m = re.fullmatch(r'([a-z][a-z0-9]*)', body)
    if m and paren:
        return ("mem", m.group(1), None, 0)
    m = re.fullmatch(r'(-?' + NUM + r')(?::(8|16|24))?', body)
    if m and paren:
        return ("abs", num(m.group(1)) & 0xffffff)
    if not paren:
        m = re.fullmatch(r'(-?' + NUM + r')', body)
        if m:
            return ("imm", num(m.group(1)))
        m = re.fullmatch(r'[a-z][a-z0-9]*', body)
        if m:
            return ("reg", body)
    return ("?", op)


def norm_mame_op(op, mnem):
    o = op.strip()
    ol = o.lower()
    inner = ol[1:-1] if ol.startswith("(") and ol.endswith(")") else None
    paren = inner is not None
    body = inner if paren else ol
    # MAME prints the LDA / JP / CALL source effective address without parens
    lda_like = mnem in ("lda", "jp", "call")
    if paren or lda_like:
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
            return ("mem", m.group(1), None, v)
        m = re.fullmatch(r'([a-z][a-z0-9]*)\+([a-z][a-z0-9]*)', body)
        if m:
            return ("idx", m.group(1), m.group(2))
        m = re.fullmatch(r'0x([0-9a-f]+)', body)
        if m:
            return ("abs", int(m.group(1), 16))
        m = re.fullmatch(r'([a-z][a-z0-9]*)', body)
        if m and (paren or (lda_like and body.startswith("x"))):
            return ("mem", body, None, 0)
    if not paren:
        m = re.fullmatch(r'0x([0-9a-f]+)', body)
        if m:
            return ("imm", int(m.group(1), 16))
        m = re.fullmatch(r'[0-9]+', body)
        if m:
            return ("imm", int(body))
        m = re.fullmatch(r'[a-z][a-z0-9]*', body)
        if m:
            return ("reg", body)
    return ("?", op)


def fam(m):
    m = m.lower()
    for a, b in (("ldw", "ld"), ("ldl", "ld"), ("pushw", "push"), ("popw", "pop"),
                 ("cpw", "cp"), ("addw", "add"), ("adcw", "adc"), ("subw", "sub"),
                 ("sbcw", "sbc"), ("andw", "and"), ("orw", "or"), ("xorw", "xor"),
                 ("incw", "inc"), ("decw", "dec"), ("rlcw", "rlc"), ("rrcw", "rrc"),
                 ("rlw", "rl"), ("rrw", "rr"), ("slaw", "sla"), ("sraw", "sra"),
                 ("sllw", "sll"), ("srlw", "srl"), ("ldiw", "ldi"), ("ldirw", "ldir"),
                 ("lddw", "ldd"), ("lddrw", "lddr"), ("cpiw", "cpi"), ("cpirw", "cpir"),
                 ("cpdw", "cpd"), ("cpdrw", "cpdr"), ("exw", "ex")):
        if m == a:
            return b
    return m


def canon_imm_pair(lops, mops):
    """MAME prints immediates unsigned; llvm may print signed. Compare mod 2^32."""
    out = []
    for a, b in zip(lops, mops):
        if a[0] == "imm" and b[0] == "imm":
            if (a[1] - b[1]) % (1 << 32) == 0 or (a[1] & 0xffff) == b[1] or (a[1] & 0xff) == b[1]:
                out.append(True); continue
        out.append(a == b)
    return all(out)


def compare(ltext, mtext):
    lm, _, lo = ltext.partition(" ")
    mm, _, mo = mtext.partition(" ")
    lm, mm = lm.lower(), mm.lower()
    lops = [norm_llvm_op(x) for x in split_ops(lo)] if lo.strip() else []
    ms = split_ops(mo) if mo.strip() else []
    mops = []
    for i, x in enumerate(ms):
        ea = (mm == "lda" and i == 1) or (mm in ("jp", "call") and i == len(ms) - 1)
        mops.append(norm_mame_op(x, mm if ea else "-"))
    # INC/DEC #3: a field of 0 means 8 (MAME prints the raw field)
    if mm in ("inc", "dec", "incw", "decw", "incl", "decl") and mops and mops[0] == ("imm", 0):
        mops[0] = ("imm", 8)
    # condition code T / F on jp/call
    if mm in ("jp", "call", "ret", "jr", "jrl") and mops and mops[0] == ("reg", "t"):
        mops = mops[1:]
    if any(o[0] == "?" for o in lops):
        return "UNPARSED_LLVM", lops, mops
    if any(o[0] == "?" for o in mops):
        return "UNPARSED_MAME", lops, mops
    if fam(lm) != fam(mm):
        return "MNEM", lops, mops
    if len(lops) != len(mops):
        return "NOPS", lops, mops
    if not canon_imm_pair(lops, mops):
        return "OPERAND", lops, mops
    return "OK", lops, mops


# ---------------------------------------------------------------- probe sets
REP_SUBS = sorted(set(list(range(0x00, 0x08)) + [0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0e, 0x10, 0x11,
                  0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1c, 0x20, 0x21, 0x27, 0x28, 0x29,
                  0x30, 0x31, 0x33, 0x37, 0x38, 0x39, 0x3c, 0x3f, 0x40, 0x41, 0x44, 0x48, 0x50, 0x51, 0x58,
                  0x60, 0x61, 0x67, 0x68, 0x70, 0x78, 0x80, 0x81, 0x88, 0x90, 0x98, 0xa0, 0xa7, 0xa8,
                  0xb0, 0xb7, 0xb8, 0xc0, 0xc7, 0xc8, 0xcf, 0xd0, 0xd8, 0xe0, 0xe8, 0xf0, 0xf1, 0xf8, 0xff]))


def probes(family):
    out = []
    if family == "autoinc":
        for p in (0xC4, 0xC5, 0xD4, 0xD5, 0xE4, 0xE5, 0xF4, 0xF5):
            for rb in range(256):
                for s in REP_SUBS:
                    out.append(("%02x" % p, bytes([p, rb, s] + TAIL)))
            for rb in (0x00, 0x01, 0x02, 0x03, 0x10, 0x31, 0x3e, 0xe0, 0xe1, 0xe2, 0xe3, 0xe5, 0xe9,
                       0xee, 0xf0, 0xf4, 0xf8, 0xfc, 0xfd, 0xfe, 0xff):
                for s in range(256):
                    if s not in REP_SUBS:
                        out.append(("%02x-all" % p, bytes([p, rb, s] + TAIL)))
    elif family == "disp":
        for base in (0x88, 0x98, 0xA8, 0xB8):
            for r in range(8):
                for d in (0x00, 0x01, 0x05, 0x7f, 0x80, 0x81, 0xfb, 0xff):
                    for s in REP_SUBS:
                        out.append(("%02x+r:d8" % base, bytes([base + r, d, s] + TAIL)))
        for base in (0x80, 0x90, 0xA0, 0xB0):
            for r in range(8):
                for s in REP_SUBS:
                    out.append(("%02x+r" % base, bytes([base + r, s] + TAIL)))
        for p in (0xC3, 0xD3, 0xE3, 0xF3):
            for mb in range(256):
                for d16 in (0x0000, 0x0005, 0x007f, 0x0080, 0x00ff, 0x0100, 0x7fff, 0x8000,
                            0xff7f, 0xff80, 0xfffb, 0xffff):
                    for s in (0x20, 0x21, 0x04, 0x30, 0x31, 0x38, 0x40, 0x41, 0x50, 0x60, 0x00,
                              0x80, 0xc8, 0x14, 0x19):
                        out.append(("%02x" % p, bytes([p, mb, d16 & 0xff, d16 >> 8, s] + TAIL[:3])))
    elif family == "direct":
        addrs = {0xC0: [[0x00], [0x1e], [0xff]], 0xC1: [[0x00, 0x00], [0x1e, 0x23], [0xff, 0xff], [0xff, 0x00]],
                 0xC2: [[0x00, 0x00, 0x00], [0x1e, 0x23, 0x00], [0xff, 0xff, 0xff], [0x56, 0x34, 0x12], [0xff, 0x00, 0x00]]}
        for hi in (0xC0, 0xD0, 0xE0, 0xF0):
            for lo in (0, 1, 2):
                for a in addrs[0xC0 + lo]:
                    for s in range(256):
                        out.append(("%02x" % (hi + lo), bytes([hi + lo] + a + [s] + TAIL)))
    elif family == "muldiv":
        for p in list(range(0xC8, 0xD0)) + list(range(0xD8, 0xE0)) + list(range(0xE8, 0xF0)):
            for s in list(range(0x08, 0x0c)) + list(range(0x40, 0x60)):
                out.append(("%02x" % p, bytes([p, s] + TAIL)))
        for p in (0xC7, 0xD7, 0xE7):
            for rb in range(256):
                for s in list(range(0x08, 0x0c)) + list(range(0x40, 0x60)):
                    out.append(("%02x" % p, bytes([p, rb, s] + TAIL)))
        for p in list(range(0x80, 0x88)) + list(range(0x90, 0x98)) + [0xC1, 0xD1, 0xC5, 0xD5, 0xC4, 0xD4]:
            extra = {0xC1: [0x1e, 0x23], 0xD1: [0x1e, 0x23], 0xC5: [0xe9], 0xD5: [0xe9],
                     0xC4: [0xe9], 0xD4: [0xe9]}.get(p, [])
            for s in range(0x40, 0x60):
                out.append(("%02x-mem" % p, bytes([p] + extra + [s] + TAIL)))
    elif family == "erp":
        for p in (0xC7, 0xD7, 0xE7):
            for rb in range(256):
                for s in list(range(0x88, 0xa0)):
                    out.append(("%02x" % p, bytes([p, rb, s] + TAIL)))
    elif family == "ei":
        for v in range(256):
            out.append(("06", bytes([0x06, v] + TAIL)))
    return out


def main():
    fams = sys.argv[1:] or ["autoinc", "disp", "direct", "muldiv", "erp", "ei"]
    for f in fams:
        pr = probes(f)
        blobs = [b for _, b in pr]
        ld = llvm_decode(blobs)
        md = mame_decode(blobs)
        texts = [(x[1] if x and not x[1].startswith("<unknown>") else None) for x in ld]
        enc = llvm_encode([t or "nop" for t in texts])
        c = collections.Counter()
        rows = []
        for (g, b), l, m, t, e in zip(pr, ld, md, texts, enc):
            if t is None:
                v = "BOTH_REFUSE" if (m is None or m[1].split()[0].lower() in ("db",) or "??" in m[1]) else "MAME_ONLY"
                c[v] += 1
                if v == "MAME_ONLY":
                    rows.append((v, g, b.hex(" "), "", m[1] if m else "", ""))
                continue
            asym = ""
            if e is None:
                asym = "NOREENC"
            elif e != b"<fixup>" and e != b[:l[0]]:
                asym = "ASYM:" + e.hex(" ")
            if m is None or m[1].split()[0].lower() == "db":
                v = "LLVM_ONLY"
            elif m[0] != l[0]:
                v = "LEN"
            else:
                v, lo, mo = compare(t, m[1])
            c[v] += 1
            if asym:
                c["ASYM"] += 1
            if v != "OK" or asym:
                rows.append((v, g, b[:l[0]].hex(" "), t, m[1] if m else "", asym))
        print("== %s: %d probes" % (f, len(pr)))
        for k, n in sorted(c.items()):
            print("   %-14s %7d" % (k, n))
        with open(os.path.join(HERE, "out_%s.tsv" % f), "w") as fo:
            fo.write("class\tgroup\tbytes\tllvm\tmame\tasym\n")
            for r in rows:
                fo.write("\t".join(r) + "\n")


if __name__ == "__main__":
    main()
