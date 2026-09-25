#!/usr/bin/env python3
r"""lane_reframe_islands.py -- re-frame `.byte` islands (and the misframed
instructions that follow them) inside CODE, one maincpu source file at a time.

QUESTION ANSWERED
-----------------
"This `.byte` run sits between two stretches of instructions.  Is it code the
old toolchain could not spell -- and the few `instructions` printed right after
it the tail of a real instruction read one byte late -- and if so, what are the
instructions?"

The old converter, when it met a form it could not spell, wrote
`.byte <first opcode byte>` and resumed ONE BYTE LATER, so the lines after an
island are often phantom (the symboliser's R5 refusals are exactly these: a
second decoder does not see an instruction start there).  This tool decodes
from the island's first byte straight through, past the island's end, until
the decode CONVERGES with the tree's own framing again, and replaces that whole
window.

WHAT IT REQUIRES BEFORE IT TOUCHES A WINDOW  (every refusal is reported)
  1. START.  The island is entered by fall-through from an instruction that is
     not an unconditional terminator (ret/reti/retd/jp/jr/jrl without a
     condition), OR a label inside the island is the target of a control
     transfer somewhere in the image (call/calr/jp/jr/jrl/djnz operand).
     Otherwise the bytes may be data after a `ret` and are refused
     ("unreached").
  2. CONVERGENCE.  The decode reaches an address >= the island's end that is
     the first byte of a source CODE line or a label, and from there the next
     source code lines (up to 3, stopping at a label) have exactly the lengths
     the decoder gives them.  Overrun past the island is capped at 48 bytes.
  3. DECODER.  `llvm-mc --disassemble` decodes every byte of the window with no
     warning, and re-assembling the printed text reproduces the ROM bytes of
     the window exactly (the whole window, not per-instruction encodings).
  4. SECOND DECODER.  MAME `unidasm`, swept linearly from up to 10 source code
     lines BEFORE the island, agrees with the tree's framing up to the island
     and with this decode inside the window (same instruction boundaries), and
     for every branch/call the two decoders compute the same target.
  5. NOT DATA.  The decode contains none of the data-as-code markers counted by
     scripts/analysis/lane_worklists.py (halt/incf/decf/ldf/normal/max/min/swi,
     `jr cc,0`, never-taken `jr f`, nop-nop) and no `reti`.
  6. LABELS.  Every label defined inside the window lands on an instruction
     boundary of the new decode.
  7. TARGETS.  No branch in the window targets the middle of a new instruction,
     or the middle of a source line of the same file.
  8. Islands made only of `.ascii` are left alone (real strings live in code
     files too).

Relative branch operands are written as the raw displacement the decoder
prints (`jr z, 51` -> 66 33) -- run symbolize_numeric_branches.py afterwards
to turn them into labels.  Every comment inside a replaced window is kept, in
order, as a whole-line comment before the instruction at its address.

INPUT MAP: produced by scripts/analysis/lane_line_map.py and REFUSED if any
line's first ROM byte differs from what that line says it emits (the
stale-map guard of BRIEF-2026-09-01).

RUN
    python3 scripts/analysis/lane_line_map.py --image v7 --files F --json M
    python3 scripts/converters/lane_reframe_islands.py --image v7 --file F --map M [--apply] [--report R]
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LLVM = os.path.join(os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado")),
                    "llvm-project", "build", "bin")
MC, OBJCOPY = os.path.join(LLVM, "llvm-mc"), os.path.join(LLVM, "llvm-objcopy")
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE = 0xE00000

ABS = re.compile(r'^(halt|incf|decf|ldf|normal|max|min|swi|reti)\b'
                 r'|^(jr|jrl)\s+[a-z]+\s*,\s*(0x)?0+$|^(jr|jrl)\s+f\s*,')
LABEL_RE = re.compile(r'^\s*([A-Za-z_.$][\w.$@]*):')
TERM_RE = re.compile(r'^(ret|reti|retd)\b|^(jp|jr|jrl)\s+[^,]+$')
DATA_DIRS = (".byte", ".ascii", ".asciz", ".incbin")
CTRL_RE = re.compile(r'^\s*(?:[A-Za-z_.$][\w.$@]*:\s*)?(call|calr|jp|jr|jrl|djnz\w*)\s+(.*)$', re.I)
IDENT_RE = re.compile(r'\b([A-Za-z_][\w.$]*)\b')
REL = {"jr": 2, "jrl": 3, "calr": 3}


def strip_comment(line):
    out, q = [], None
    for ch in line:
        if q:
            out.append(ch)
            if ch == q:
                q = None
            continue
        if ch in "\"'":
            q = ch
        elif ch == ";":
            break
        out.append(ch)
    return "".join(out)


def comment_of(line):
    q = None
    for i, ch in enumerate(line):
        if q:
            if ch == q:
                q = None
            continue
        if ch == '"':
            q = ch
        elif ch == ";":
            return line[i:].rstrip()
    return None


def kind_of(text):
    c = strip_comment(text).strip()
    labels = []
    while True:
        m = re.match(r'^([A-Za-z_.$][\w.$@]*):\s*', c)
        if not m:
            break
        labels.append(m.group(1))
        c = c[m.end():]
    if not c:
        return "label", labels, c
    if c.startswith("."):
        d = c.split()[0].lower()
        return ("data" if d in DATA_DIRS else "dir"), labels, c
    return "code", labels, c


# ---------------------------------------------------------------- decoders
def llvm_decode(blob, base):
    """-> list of (addr, len, text) or raises ValueError(offset) on first bad byte."""
    toks = " ".join("0x%02x" % b for b in blob)
    r = subprocess.run([MC, "--triple=tlcs900", "--disassemble", "-show-encoding"],
                       input=toks, capture_output=True, text=True)
    bad = None
    for ln in r.stderr.split("\n"):
        m = re.match(r'<stdin>:1:(\d+): warning', ln)
        if m:
            off = (int(m.group(1)) - 1) // 5
            bad = off if bad is None else min(bad, off)
    out, pos = [], 0
    for ln in r.stdout.split("\n"):
        m = re.match(r'^\s*(.*?)\s*; encoding: \[(.*)\]\s*$', ln)
        if not m:
            continue
        n = len(m.group(2).split(","))
        txt = m.group(1).strip()
        out.append((base + pos, n, txt))
        pos += n
    return out, bad


def assemble(lines):
    with tempfile.TemporaryDirectory() as d:
        s, o, b = (os.path.join(d, x) for x in ("a.s", "a.o", "a.bin"))
        open(s, "w").write("\n".join("\t" + l for l in lines) + "\n")
        r = subprocess.run([MC, "--triple=tlcs900", "-filetype=obj", "-o", o, s],
                           capture_output=True, text=True)
        if r.returncode:
            return None
        subprocess.run([OBJCOPY, "-O", "binary", "-j", ".text", o, b], check=True)
        return open(b, "rb").read()


def unidasm_sweep(rom_path, start, end):
    """-> dict addr -> (len, text) for a linear sweep start..end."""
    r = subprocess.run([UNIDASM, rom_path, "-arch", "tlcs900", "-basepc", hex(start),
                        "-skip", str(start - BASE), "-count", str(end - start + 8)],
                       capture_output=True, text=True)
    out, prev = {}, None
    for ln in r.stdout.split("\n"):
        m = re.match(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$', ln)
        if not m:
            continue
        a = int(m.group(1), 16)
        n = len(m.group(2).split())
        out[a] = (n, m.group(3).strip())
    return out


def uni_target(text):
    m = re.search(r'\b0x([0-9a-f]{5,6})\b', text)
    return int(m.group(1), 16) if m else None


def llvm_target(addr, n, text):
    m = re.match(r'^(jr|jrl|calr)\s+(?:([a-z]+)\s*,\s*)?(-?\d+)$', text)
    if m:
        mn, disp = m.group(1), int(m.group(3))
        w = 8 if mn == "jr" else 16
        if disp >= (1 << (w - 1)):
            disp -= 1 << w
        return addr + n + disp
    m = re.match(r'^djnz\w*\s+\w+\s*,\s*(-?\d+)$', text)
    if m:
        d = int(m.group(1))
        if d >= 128:
            d -= 256
        return addr + n + d
    m = re.match(r'^(call|jp)\s+(?:([a-z]+)\s*,\s*)?(\d+)$', text)
    if m:
        return int(m.group(3))
    return None


# ------------------------------------------------------- decoder fallback
# llvm-mc's DISASSEMBLER cannot read the SRI (register-indexed) ALU family,
# although its ASSEMBLER spells every form with a raw-byte mnemonic
# (add_sril_rm XWA, 0x07, 0xe8, 0xe4 ...).  When llvm-mc stops on a byte, ask
# unidasm for the instruction there (its length and operation), then try every
# SRI mnemonic the backend defines (TLCS900InstrInfo.td, listed below) with the
# instruction's own raw bytes and every register name, plus unidasm's own text
# with a width-annotated address; keep a candidate only if llvm-mc encodes it to
# EXACTLY the ROM bytes AND its operation word agrees with unidasm's.
SRI_MNS = ["adc_sril_mr", "add_srib_mr", "add_sril_mr", "add_sril_rm", "add_sriw_mr",
           "add_sriw_rm", "and_srib_im", "and_srib_mr", "and_srib_rm", "and_sriw_im",
           "and_sriw_mr", "and_sriw_rm", "cpb_sri_mr", "cpb_sri_rm", "cpib_sri",
           "cpiw_sri", "cpl_sri_mr", "cpl_sri_rm", "cpw_sri_mr", "cpw_sri_rm",
           "dec_srib", "dec_sriw", "ex_sriw", "inc_srib", "inc_sriw", "ldb_sri",
           "ldmm_srib", "ldmm_sriw", "ld_srib1", "ld_sril1", "ld_sril3", "ld_sriw1",
           "ldw_sri", "or_srib_im", "or_srib_mr", "or_srib_rm", "or_sril_rm",
           "or_sriw_im", "or_sriw_mr", "or_sriw_rm", "push_sriw", "sub_srib_im",
           "sub_srib_mr", "sub_sril_mr", "sub_sril_rm", "sub_sriw_rm", "xor_srib_rm"]
REGS = ["W", "A", "B", "C", "D", "E", "H", "L", "WA", "BC", "DE", "HL", "IX", "IY",
        "IZ", "SP", "XWA", "XBC", "XDE", "XHL", "XIX", "XIY", "XIZ", "XSP"]
OPWORD = {"cpb": "cp", "cpl": "cp", "cpw": "cp", "cpib": "cp", "cpiw": "cp",
          "ldb": "ld", "ldw": "ld", "ldmm": "ld"}


def sri_candidates(b):
    raw = ["0x%02x" % x for x in b[1:4]]
    tail = ["0x%02x" % x for x in b[5:]]
    out = []
    for mn in SRI_MNS:
        for r in REGS:
            out.append("%s\t%s" % (mn, ", ".join([r] + raw)))
            out.append("%s\t%s" % (mn, ", ".join(raw + [r])))
        if tail:
            out.append("%s\t%s" % (mn, ", ".join(raw + tail)))
        out.append("%s\t%s" % (mn, ", ".join(raw)))
        for nn in range(0, 9):
            out.append("%s\t%s" % (mn, ", ".join([str(nn)] + raw)))
    return out


def text_candidates(u):
    t = u.lower().replace(",", ", ")
    out = [t]
    for w in (8, 16, 24):
        out.append(re.sub(r'\((0x[0-9a-f]+)\)', r'(\1:%d)' % w, t))
    return out


def fallback_insn(rom_path, rom, addr):
    """-> (length, text) or None."""
    u = unidasm_sweep(rom_path, addr, addr + 8).get(addr)
    if not u or u[1].startswith("db"):
        return None
    n, utext = u
    b = rom[addr - BASE:addr - BASE + n]
    uop = utext.split()[0].lower()
    cands = sri_candidates(b) + text_candidates(utext)
    enc = encodings(cands)
    want = ",".join("0x%02x" % x for x in b)
    for c, e in zip(cands, enc):
        if e is None or e.replace(" ", "") != want:
            continue
        mn = c.split("\t")[0].split(" ")[0]
        w = mn.split("_")[0]
        if OPWORD.get(w, w) != uop and not (uop == "ld" and w == "ld"):
            continue
        return n, c
    return None


def robust_decode(rom_path, rom, start, length):
    """llvm-mc decode of rom[start:start+length], patching undecodable
    instructions with fallback_insn.  -> (list of (addr, n, text), bad) where
    bad is the offset of the first byte nothing could decode (or None)."""
    out, pos = [], start
    end = start + length
    while pos < end:
        dec, bad = llvm_decode(rom[pos - BASE:end - BASE], pos)
        for ad, n, t in dec:
            if bad is not None and ad - pos >= bad:
                break
            out.append((ad, n, t))
        if bad is None:
            return out, None
        at = pos + bad
        fb = fallback_insn(rom_path, rom, at)
        if fb is None:
            return out, at - start
        out.append((at, fb[0], fb[1]))
        pos = at + fb[0]
    return out, None


def ptr_run_overlap(rom, S, E, k=3):
    """True when [S, E) overlaps a run of >= k consecutive little-endian 32-bit
    words, at one alignment, whose values are all in 0xE00000..0xFFFFFF (a
    pointer table).  Looked for in the 64 bytes on either side as well, so a
    window that is a FRAGMENT of a table is caught (a 3-byte window inside
    `.long` entries is not itself 4 pointers long)."""
    lo, hi = max(S - 64, BASE), E + 64
    for o in range(4):
        p = lo + o
        run_start, run = None, 0
        while p + 4 <= hi:
            v = int.from_bytes(rom[p - BASE:p - BASE + 4], "little")
            if 0xE00000 <= v <= 0xFFFFFF:
                if run == 0:
                    run_start = p
                run += 1
            else:
                if run >= k and run_start < E and p > S:
                    return True
                run = 0
            p += 4
        if run >= k and run_start < E and p > S:
            return True
    return False


# ------------------------------------------------------------ respelling
# The decoder prints the backend's SYNTHETIC names (stdi8, ldb_d8, bitda ...).
# The tree's convention is the native mnemonic plus a width annotation
# (`ld (0x3338:16), 4`).  Candidates come from convert_direct_address_family's
# MAP plus the few d8/d16/mi8 names it does not cover; each candidate is KEPT
# ONLY IF llvm-mc encodes it to the same bytes as the decoded line.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
try:
    import convert_direct_address_family as cdaf
except Exception:          # pragma: no cover
    cdaf = None
EXTRA = {"ldb_d8": ("ld", 1), "ldw_d16": ("ld", 1), "ldl_d16": ("ld", 1),
         "stb_d8": ("ld", 0), "stw_d16": ("ld", 0), "lda_d16": ("lda", 1)}
MEMNAT = {"andmi8": "and", "ormi8": "or", "xormi8": "xor", "cpmi8": "cp",
          "addmi8": "add", "submi8": "sub", "bitm": "bit", "setm": "set",
          "resm": "res", "chgm": "chg", "incm8": "inc", "decm8": "dec"}


def hexaddr(a):
    a = a.strip()
    return "0x%x" % int(a, 0) if re.match(r'^-?(0x[0-9a-fA-F]+|\d+)$', a) else a


def candidates(text):
    mn, _, ops = text.partition("\t")
    mn, ops = mn.strip(), ops.strip()
    out = []
    if cdaf and mn in cdaf.MAP:
        spec = cdaf.MAP[mn]
        o = cdaf.split_ops(ops)
        if len(o) == spec.get("nops", 2):
            ai = spec["addr"]
            inner = cdaf.unparen(o[ai])
            if inner and not inner.startswith("("):
                o2 = list(o)
                o2[ai] = "(%s:%d)" % (hexaddr(inner), spec["width"])
                rm = spec["regmap"]
                if not rm:
                    out.append(spec["native"] + "\t" + ", ".join(o2))
                else:
                    oi = 1 - ai
                    for name, why in cdaf.reg_candidates(rm, o2[oi]):
                        o3 = list(o2)
                        o3[oi] = name
                        out.append(spec["native"] + "\t" + ", ".join(o3))
    elif mn in EXTRA:
        nat, ai = EXTRA[mn]
        o = [x.strip() for x in ops.split(",", 1)] if "," in ops else [ops]
        if len(o) == 2:
            inner = o[ai].strip()
            if inner.startswith("(") and inner.endswith(")"):
                o[ai] = "(%s:16)" % hexaddr(inner[1:-1])
                out.append(nat + "\t" + ", ".join(o))
    elif mn in MEMNAT:
        out.append(MEMNAT[mn] + "\t" + ops)
    return out


def encodings(lines):
    """-> list of encoding strings "0x..,0x.." (None where a line does not
    assemble).  Each line is preceded by a sentinel `.ascii "@i@"` so the
    output can be attributed line by line: llvm-mc may print an encoding for a
    line it ALSO reports an error on, so errors are taken from stderr."""
    src = []
    for i, l in enumerate(lines):
        src += ['.ascii "@%d@"' % i, l]
    r = subprocess.run([MC, "--triple=tlcs900", "-show-encoding"],
                       input="\n".join(src) + "\n", capture_output=True, text=True)
    bad = set()
    for ln in r.stderr.split("\n"):
        m = re.match(r'<stdin>:(\d+):\d+: error', ln)
        if m:
            bad.add((int(m.group(1)) - 2) // 2)
    out = [None] * len(lines)
    cur = None
    for ln in r.stdout.split("\n"):
        m = re.search(r'\.ascii\s+"@(\d+)@"', ln)
        if m:
            cur = int(m.group(1))
            continue
        m = re.search(r'encoding: \[([^\]]*)\]', ln)
        if m and cur is not None and cur not in bad and out[cur] is None:
            out[cur] = m.group(1)
    return out


def respell(texts):
    """Replace synthetic spellings by native ones that encode identically."""
    slots, trial = [], []
    for i, t in enumerate(texts):
        for c in candidates(t):
            slots.append((i, c))
            trial += [t, c]
    if not trial:
        return list(texts), 0
    enc = encodings(trial)
    out, n, done = list(texts), 0, set()
    for k, (i, c) in enumerate(slots):
        if i in done:
            continue
        e_old, e_new = enc[2 * k], enc[2 * k + 1]
        if e_old is not None and e_old == e_new:
            out[i] = c
            done.add(i)
            n += 1
    return out, n


# ------------------------------------------------------------------- main
LONG_RE = re.compile(r'^\s*(?:[A-Za-z_.$][\w.$@]*:\s*)?\.long\s+(.*)$')


def ptr_targets(image):
    """Every identifier stored by a `.long` anywhere in the image (dispatch tables)."""
    tg = set()
    src = os.path.join(ROOT, image, "maincpu")
    for dp, _, fn in os.walk(src):
        for f in fn:
            if not f.endswith(".s"):
                continue
            for ln in open(os.path.join(dp, f), encoding="latin-1"):
                m = LONG_RE.match(strip_comment(ln))
                if m:
                    tg.update(IDENT_RE.findall(m.group(1)))
    return tg


def twin_code_labels(L):
    """{label: True} for every label of the twin version's file that is followed
    (after labels, blank and comment lines) by an instruction line."""
    out = {}
    pend = []
    for x in L:
        k, labs, body = kind_of(x)
        if not strip_comment(x).strip():
            continue
        pend += labs
        if k == "label":
            continue
        for lab in pend:
            out[lab] = (k == "code")
        pend = []
    return out


def referenced_idents(image):
    """Every identifier that appears anywhere OUTSIDE a label definition in the
    image's sources (operands, .long, .set right-hand sides ...)."""
    ids = set()
    src = os.path.join(ROOT, image, "maincpu")
    for dp, _, fn in os.walk(src):
        for f in fn:
            if not f.endswith(".s"):
                continue
            for ln in open(os.path.join(dp, f), encoding="latin-1"):
                c = strip_comment(ln)
                c = re.sub(r'^\s*([A-Za-z_.$][\w.$@]*:\s*)+', '', c)
                ids.update(IDENT_RE.findall(c))
    return ids


def ctrl_targets(image):
    """Every identifier used as a control-transfer operand anywhere in the image."""
    tg = set()
    src = os.path.join(ROOT, image, "maincpu")
    for dp, _, fn in os.walk(src):
        for f in fn:
            if not f.endswith(".s"):
                continue
            for ln in open(os.path.join(dp, f), encoding="latin-1"):
                m = CTRL_RE.match(strip_comment(ln))
                if m:
                    tg.update(IDENT_RE.findall(m.group(2)))
    return tg


def _analyse_island(isl):
    """One island -> (result dict, edit or None).  Runs in a worker; reads the
    per-file state main() published in the module globals."""
    res = dict(line=isl["firstdata"], lastline=isl["lastdata"])
    fd, ld_ = info[isl["firstdata"]], info[isl["lastdata"]]
    S = fd["addr"]
    X = ld_["addr"] + (ld_["size"] or 0)
    res.update(S="0x%06X" % S, X="0x%06X" % X, size=X - S)
    prev, nxt = isl["prev"], isl["nxt"]
    next_code = nxt is not None and nxt["kind"] == "code"
    if prev is None or prev["kind"] not in ("code",):
        prevok = False
    else:
        prevok = not TERM_RE.match(prev["body"].lower())
    # the data lines themselves: skip islands of pure .ascii
    span = order[pos_of[isl["first"]]:pos_of[isl["lastdata"]] + 1]
    dls = [ln for ln in span if ln >= isl["firstdata"] and info[ln]["kind"] == "data"]
    if all(info[ln]["body"].startswith((".ascii", ".asciz")) for ln in dls):
        res["verdict"] = "refused: only .ascii"
        return res, None
    labs_in = [lab for ln in span for lab in info[ln]["labels"]]
    tgt_in = [lab for lab in labs_in if lab in tg]
    ptr_in = [lab for lab in labs_in if lab in ptg]
    twin_in = [lab for lab in labs_in if twin_code.get(lab)]
    num_in = S in numtg
    if not next_code and not twin_in:
        res["verdict"] = "refused: not followed by code and no code twin"
        return res, None
    if not prevok and not tgt_in and not ptr_in and not twin_in and not num_in:
        res["verdict"] = "refused: unreached (no fall-through, no control-transfer label)"
        return res, None
    # ---- decode from S
    dec, bad = robust_decode(rom_path, rom, S, X - S + 64)
    # walk to convergence
    conv, used = None, []
    for n_i, (ad, n, txt) in enumerate(dec):
        if bad is not None and ad - S >= bad:
            break
        used.append((ad, n, txt))
        e = ad + n
        if e < X:
            continue
        if e - X > 48:
            break
        if e == X and not next_code:
            # the island ends at a non-code line: accept an exact landing
            # only with twin corroboration (checked above)
            conv = (e, boundaries.get(e, isl["after"]))
            break
        if e not in boundaries:
            continue
        bl = boundaries[e]
        # source code lines from e must agree with the decode
        agree, cnt, ri = True, 0, 0
        rest = dec[n_i + 1:]
        for x in order[pos_of[bl]:pos_of[bl] + 12]:
            s_ = info[x]
            if s_["kind"] == "label":
                if cnt:
                    break
                continue
            if s_["kind"] != "code":
                agree = cnt > 0
                break
            if ri >= len(rest) or (bad is not None and rest[ri][0] - S >= bad):
                break
            if rest[ri][0] != s_["addr"] or rest[ri][1] != s_["size"]:
                agree = False
                break
            ri += 1
            cnt += 1
            if cnt >= 3:
                break
        has_label = any(info[x]["labels"] for x in order[pos_of[bl]:pos_of[bl] + 4]
                        if info[x]["addr"] == e)
        if agree and (cnt >= 1 or has_label):
            conv = (e, bl)
            break
    if conv is None:
        res["verdict"] = "refused: no convergence" + (" (undecodable byte at 0x%06X)" % (S + bad) if bad is not None else "")
        return res, None
    E, Eline = conv
    res["E"] = "0x%06X" % E
    texts = [t for (_, _, t) in used]
    # marker check
    prevt = ""
    mk = None
    for t in texts:
        tt = re.sub(r'\s+', ' ', t.lower())
        if ABS.match(tt) or (tt == "nop" and prevt == "nop"):
            mk = t
            break
        prevt = tt
    if mk:
        res["verdict"] = "refused: data-as-code marker %r" % mk
        return res, None
    # R6-style guard (as symbolize_numeric_branches.py): text or a pointer
    # table decodes cleanly too
    wb = rom[S - BASE:E - BASE]
    if len(wb) >= 8 and sum(1 for c in wb if 0x20 <= c < 0x7f) >= 0.8 * len(wb):
        res["verdict"] = "refused: window is >=80% printable text"
        return res, None
    if ptr_run_overlap(rom, S, E):
        res["verdict"] = "refused: window overlaps a run of >=3 ROM pointers"
        return res, None
    # round trip
    got = assemble(texts)
    if got != rom[S - BASE:E - BASE]:
        res["verdict"] = "refused: round trip differs"
        return res, None
    # labels inside window must land on boundaries
    starts = set(ad for (ad, _, _) in used)
    win_lines = order[pos_of[isl["firstdata"]]:pos_of[Eline]]
    badlab = [lab for x in win_lines for lab in info[x]["labels"] if info[x]["addr"] not in starts]
    if [b for b in badlab if b in refd]:
        res["verdict"] = "refused: referenced label(s) mid-instruction: %s" % ",".join(
            b for b in badlab if b in refd)
        return res, None
    # an UNREFERENCED label that lands mid-instruction was placed by an
    # earlier misframe (policy 6: labels only on instruction boundaries);
    # it is dropped, and reported
    res["dropped_labels"] = badlab
    # second decoder
    ctx = order[max(0, pos_of[isl["first"]] - 40):pos_of[isl["first"]]]
    cl = []
    for x in reversed(ctx):
        if info[x]["kind"] == "code":
            cl.append(x)
            if len(cl) >= 10:
                break
        elif info[x]["kind"] == "label":
            if cl:
                break
        else:
            break
    A = info[cl[-1]]["addr"] if cl else S
    uni = unidasm_sweep(rom_path, A, E + 8)
    ok2, why2 = True, ""
    for x in cl:
        if info[x]["addr"] not in uni:
            ok2, why2 = False, "unidasm disagrees with the tree before the island at 0x%06X" % info[x]["addr"]
            break
    if ok2:
        if S not in uni:
            ok2, why2 = False, "unidasm has no boundary at island start"
    if ok2:
        ustarts = set(u for u in uni if S <= u < E)
        if ustarts != starts or E not in uni:
            ok2, why2 = False, "unidasm framing differs inside window"
    if ok2:
        for (ad, n, t) in used:
            lt = llvm_target(ad, n, t)
            if lt is None:
                continue
            ut = uni_target(uni[ad][1])
            if ut is not None and ut != lt:
                ok2, why2 = False, "branch target disagrees at 0x%06X (%s vs %s)" % (ad, t, uni[ad][1])
                break
    if not ok2:
        res["verdict"] = "refused: " + why2
        return res, None
    # branch targets
    lo_file, hi_file = info[order[0]]["addr"], info[order[-1]]["addr"]
    bt = None
    for (ad, n, t) in used:
        lt = llvm_target(ad, n, t)
        if lt is None:
            continue
        if S <= lt < E:
            if lt not in starts:
                bt = "target 0x%06X mid-instruction" % lt
                break
        elif lo_file <= lt <= hi_file and lt not in line_starts and lt not in boundaries:
            bt = "target 0x%06X mid-line" % lt
            break
    if bt:
        res["verdict"] = "refused: " + bt
        return res, None
    sp, nres = respell([t for (_, _, t) in used])
    if assemble(sp) != rom[S - BASE:E - BASE]:
        sp, nres = [t for (_, _, t) in used], 0
    used = [(ad, n, t) for (ad, n, _), t in zip(used, sp)]
    res["respelled"] = nres
    res["verdict"] = "ACCEPT"
    res["ninsn"] = len(used)
    res["replaced_lines"] = [isl["firstdata"], Eline - 1]
    res["reached"] = ("fall-through" if prevok else "target:" + ",".join(tgt_in) if tgt_in
                      else "numeric-branch" if num_in
                      else "ptr:" + ",".join(ptr_in) if ptr_in else "twin:" + ",".join(twin_in))
    res["twin"] = twin_in
    return res, (isl["firstdata"], Eline, used, S, E, set(badlab))
    return res, None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--map", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--report")
    ap.add_argument("--verbose", action="store_true")
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--twin", help="twin image (v10/v9) whose same-named labels corroborate code")
    a = ap.parse_args()

    rom_path = os.path.join(ROOT, "original_ROMs", "kn5000_%s_program.rom" % a.image)
    rom = open(rom_path, "rb").read()
    mp = json.load(open(a.map))
    assert mp["image"] == a.image
    rows = mp["files"][os.path.normpath(a.file)]
    path = os.path.join(ROOT, a.image, "maincpu", a.file)
    L = open(path, encoding="latin-1").read().split("\n")

    info = {}           # lineno -> dict
    for ln, addr, size, text in rows:
        if L[ln - 1] != text:
            sys.exit("STALE MAP: line %d text differs from the map; regenerate it" % ln)
        k, labels, body = kind_of(text)
        info[ln] = dict(ln=ln, addr=addr, size=size, kind=k, labels=labels, body=body)
    order = sorted(info)
    pos_of = {ln: k for k, ln in enumerate(order)}
    # stale-map guard on the bytes: a .byte line's first value must be the ROM's
    for ln in order:
        it = info[ln]
        if it["kind"] == "data" and it["body"].startswith(".byte") and it["size"]:
            v = it["body"][5:].split(",")[0].strip()
            try:
                v = int(v, 0)
            except ValueError:
                continue
            if rom[it["addr"] - BASE] != v & 0xff:
                sys.exit("STALE MAP: line %d says 0x%02x, ROM has 0x%02x" % (ln, v, rom[it["addr"] - BASE]))
    boundaries = {}      # addr -> lineno of first emitting-or-label line there
    for ln in order:
        boundaries.setdefault(info[ln]["addr"], ln)
    line_starts = set(info[ln]["addr"] for ln in order if info[ln]["kind"] in ("code", "data"))
    label_addr = {}
    for ln in order:
        for lab in info[ln]["labels"]:
            label_addr[lab] = info[ln]["addr"]
    tg = ctrl_targets(a.image)
    refd = referenced_idents(a.image)
    # numeric branch targets of this file's own code lines (the symboliser
    # leaves a branch numeric when its target is not a line start -- exactly
    # the targets that land inside islands)
    numtg = set()
    for ln in order:
        it = info[ln]
        if it["kind"] != "code" or not it["size"]:
            continue
        t = re.sub(r'\s+', ' ', it["body"].strip().lower())
        t = re.sub(r'^(\w+) ', lambda m: m.group(1) + "\t", t, 1)
        t = t.replace(", ", ", ")
        m = re.match(r'^(jr|jrl|calr|call|jp|djnz\w*)\t(.*)$', t)
        if not m:
            continue
        ops = [x.strip() for x in m.group(2).split(",")]
        if not re.match(r'^-?(0x[0-9a-f]+|\d+)$', ops[-1]):
            continue
        v = int(ops[-1], 0)
        mn = m.group(1)
        if mn in ("call", "jp"):
            numtg.add(v)
            continue
        w = 8 if mn in ("jr",) or mn.startswith("djnz") else 16
        if v >= (1 << (w - 1)):
            v -= 1 << w
        numtg.add(it["addr"] + it["size"] + v)
    ptg = ptr_targets(a.image)
    twin_code = {}
    if a.twin:
        twin_code = twin_code_labels(open(os.path.join(ROOT, a.twin, "maincpu", a.file),
                                          encoding="latin-1").read().split("\n"))

    # ---- find islands
    islands = []
    i = 0
    while i < len(order):
        it = info[order[i]]
        if it["kind"] != "data":
            i += 1
            continue
        j = i
        while j < len(order) and info[order[j]]["kind"] in ("data", "label"):
            j += 1
        # [i, j) = data/label run; leading labels before i belong to the run too
        k = i
        while k > 0 and info[order[k - 1]]["kind"] == "label":
            k -= 1
        prev = info[order[k - 1]] if k > 0 else None
        nxt = info[order[j]] if j < len(order) else None
        # trailing labels are fine; the run ends at the last data line
        last = j - 1
        while info[order[last]]["kind"] == "label":
            last -= 1
        islands.append(dict(first=order[k], firstdata=order[i], lastdata=order[last],
                            after=order[j] if j < len(order) else None,
                            prev=prev, nxt=nxt))
        i = j
    globals().update(dict(info=info, order=order, pos_of=pos_of, boundaries=boundaries,
                          line_starts=line_starts, tg=tg, ptg=ptg, twin_code=twin_code,
                          refd=refd, numtg=numtg, rom=rom, rom_path=rom_path, a=a))
    import multiprocessing as mp
    if a.jobs > 1:
        with mp.get_context("fork").Pool(a.jobs) as pool:
            outs = pool.map(_analyse_island, islands, chunksize=4)
    else:
        outs = [_analyse_island(isl) for isl in islands]
    results, edits, covered = [], [], 0
    for isl, (res, ed) in zip(islands, outs):
        results.append(res)
        S = int(res["S"], 16)
        if S < covered:
            # an earlier window decoded straight through this island
            res["verdict"] = "covered by the previous window"
            continue
        if ed is None:
            continue
        edits.append(ed)
        covered = ed[4]
        if a.verbose:
            print("ACCEPT %s..%s lines %d-%d" % (res["S"], res["E"], ed[0], ed[1] - 1))
            for (ad, n, t) in ed[2]:
                print("   %06X  %s" % (ad, t))

    # ---- report
    acc = [r for r in results if r.get("verdict") == "ACCEPT"]
    from collections import Counter
    cnt = Counter(re.sub(r'0x[0-9A-F]+|\(.*', '', r["verdict"]) for r in results)
    print("%s %s: %d islands, %d accepted (%d B of island, %d B window)" % (
        a.image, a.file, len(results), len(acc), sum(r["size"] for r in acc),
        sum(int(r["E"], 16) - int(r["S"], 16) for r in acc)))
    for k, v in cnt.most_common():
        print("   %5d  %s" % (v, k))
    if a.report:
        json.dump(results, open(a.report, "w"), indent=1)

    if not a.apply or not edits:
        return
    # ---- apply, bottom-up so line numbers stay valid
    se = sorted(edits)
    for (a0, a1, _, _, _, _), (b0, b1, _, _, _, _) in zip(se, se[1:]):
        if b0 < a1:
            sys.exit("overlapping windows at lines %d-%d and %d-%d" % (a0, a1, b0, b1))
    for (l0, l1, used, S, E, drop) in sorted(edits, reverse=True):
        # l0..l1-1 (1-based) replaced; keep labels and comments
        seg = list(range(l0, l1))
        items = []   # (addr, lineno, text)
        for x in seg:
            t = L[x - 1]
            if x in info:
                it = info[x]
                for lab in it["labels"]:
                    if lab in drop:
                        continue
                    items.append((it["addr"], x, lab + ":"))
                c = comment_of(t)
                if c:
                    items.append((it["addr"], x, "\t" + c))
            else:
                c = comment_of(t)
                if c:
                    # comment-only line: it belongs before the next mapped line
                    nx = [y for y in seg if y > x and y in info]
                    ad = info[nx[0]]["addr"] if nx else E
                    items.append((ad, x, t.rstrip()))
                elif t.strip():
                    sys.exit("unexpected unmapped line %d: %r" % (x, t))
        out = []
        ii = sorted(items)
        k = 0
        for (ad, n, t) in used:
            while k < len(ii) and ii[k][0] <= ad:
                out.append(ii[k][2])
                k += 1
            parts = re.split(r'\s+', t.strip(), maxsplit=1)
            mn, ops = parts[0], (parts[1] if len(parts) > 1 else "")
            out.append("\t" + mn + ("\t" + ops.strip() if ops.strip() else ""))
        while k < len(ii):
            out.append(ii[k][2])
            k += 1
        L[l0 - 1:l1 - 1] = out
    data = "\n".join(L)
    tmpp = path + ".tmp"
    open(tmpp, "w", encoding="latin-1").write(data)
    os.replace(tmpp, path)
    print("applied %d windows to %s" % (len(edits), path))


if __name__ == "__main__":
    main()
