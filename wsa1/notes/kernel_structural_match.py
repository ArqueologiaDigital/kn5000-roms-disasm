#!/usr/bin/env python3
"""Is the WSA1's shared multitasking kernel ALSO present in the KN5000 firmware?

QUESTION IT ANSWERS
    notes/kernel_three_way.py asked this as a BYTE-IDENTITY question and answered
    "no matches".  That answer is not evidence of absence and this tool supersedes
    it, for a reason the kernel/ lane proved: prom_a and prom_c run ONE kernel
    source and still differ in 81 of 941 instruction slots -- 21 constants, every
    one a RAM address, an array size or a ROM pointer.  Two processors in the SAME
    product, from the SAME build, are not byte-identical.  A third processor in a
    different product cannot be.  So the test has to be STRUCTURAL.

WHAT "STRUCTURAL" MEANS HERE
    * Both sides are decoded from RAW ROM BYTES by the SAME disassembler
      (MAME's unidasm, -arch tlcs900).  Neither tree's .s text is read for
      instruction spelling.  ★ That is deliberate and it removes a whole class of
      error: the two trees spell the same three bytes `9c 00 23` as
      `m_ld_rm MWD+r4, 0x00, r3` (WSA1) and `ld hl, (xix + 256)` (KN5000), and a
      source-to-source comparison would have scored that as a difference.  It is
      one instruction, `ld HL,(XIX+0x00)`, and --selftest pins exactly that.
    * A token is the disassembled text with every `0x...` literal replaced by `#`.
      Register names are KEPT -- XIX and XIY are different code.  Opcode-embedded
      decimal operands (`inc 4,IX`, `swi 7`, `ei 6`) are KEPT: they are part of
      the instruction, not data.
    * Similarity = LCS(query tokens, candidate tokens) / len(query tokens).  LCS,
      not positional alignment: notes/wave7_xref_tlcs900_family.py section E
      measured that positional alignment falls apart across two builds, and it is
      right -- the KN5000 scheduler has whole instructions the WSA1 one does not.
    * Control-flow shape is scored SEPARATELY, on the LCS alignment: for each
      aligned pair of branch instructions, does the branch cross the same number
      of instructions on both sides?  A mnemonic bag cannot fake that.

THE NULL, and why there are four of them
    A similarity score with no null is not evidence.  Four controls, all printed:
      N1  every one of the KN5000 sub-CPU's ~4,800 named symbols, scored as a
          candidate start.  This is the null the answer rests on: it asks "how
          well does WSA1's Kernel_Dispatch match a KN5000 routine that is not a
          scheduler?", over the whole ROM, at a window length matched to the query.
      N2  random windows in kn5000_table_data.rom -- an image that is DATA, so
          any score it produces is pure chance.
      N3  the query with its token order SHUFFLED, re-run against N1's candidates.
          Separates "same instructions" from "same code".
      N4  a length-matched random-offset sweep of the sub-CPU payload itself.

    Positive controls matter as much: a test that cannot fail is not a pass, and
    a test that cannot SUCCEED is not a failure.  Three homologs established by
    other lanes, independently of this tool, must be recovered:
      P1  prom_c kernel -> prom_a  (one source, two CPUs, one build)
      P2  prom_a 0xF8E47F INT0 link receiver -> KN5000 sub-CPU boot 0xFF881F
          (two products, two builds -- this is what a TRUE cross-product positive
           looks like, and it sets the bar the kernel result has to clear)
      P3  prom_a 0xFA58F0 SC0 UART configure -> KN5000 main CPU 0xFCF940

RUN     (each section is independent; with no flags they all run, on the sub-CPU)
    python3 notes/kernel_structural_match.py --selftest    # 14 invariant checks
    python3 notes/kernel_structural_match.py --controls    # P0-P3: what a score MEANS
    python3 notes/kernel_structural_match.py --null        # N1-N5 distributions
    python3 notes/kernel_structural_match.py --negative    # ★ prom_b: code with NO kernel
    python3 notes/kernel_structural_match.py --order       # the layout-order test
    python3 notes/kernel_structural_match.py --sweep       # name-free whole-image search
    python3 notes/kernel_structural_match.py --table       # per-routine best hit
    python3 notes/kernel_structural_match.py --assign      # routine-for-routine, ordered
    python3 notes/kernel_structural_match.py --constants   # the three RAM maps
    python3 notes/kernel_structural_match.py --align Kernel_Dispatch   # instruction by
                                                           # instruction, one routine

    --target=kn5000:payload | kn5000:main | kn5000:subboot   (default: payload)
    --region=LO:HI          skip --assign's candidate-region survey (hex addresses);
                            needed on the 2 MB main ROM, where the survey is slow.

    The findings this produced are written up in
        notes/FINDINGS-kernel-in-the-kn5000.md

READ-ONLY in both trees.  It opens ROM images, kernel/kernel.s and the KN5000
symbol tables, and writes only to a scratch cache under /tmp.
"""
import os
import random
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SIB = "/home/fsanches/compartilhado/kn5000-roms-disasm"
UNIDASM = os.environ.get(
    "UNIDASM", "/home/fsanches/compartilhado/kn7000_mame_build/unidasm")
CACHE = os.path.join(tempfile.gettempdir(), "wsa1_structural_match_cache")

# ---------------------------------------------------------------- images ----
# key -> (path, base).  The KN5000 sub-CPU payload is a SPLICE and needs a
# piecewise base; see payload_addr().  Bases are the ones pinned by
# notes/wave7_xref_tlcs900_family.py ("BASES AND HOW THEY ARE PINNED").
IMAGES = {
    "wsa1:a":         (os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), 0xF80000),
    "wsa1:b":         (os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), 0xF00000),
    "wsa1:c":         (os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), 0xF80000),
    "kn5000:main":    (os.path.join(SIB, "original_ROMs", "kn5000_v10_program.rom"), 0xE00000),
    "kn5000:subboot": (os.path.join(SIB, "original_ROMs", "kn5000_subcpu_boot.ic30"), 0xFE0000),
    "kn5000:payload": (os.path.join(SIB, "original_ROMs", "kn5000_subprogram_v142.rom"), None),
    "kn5000:table":   (os.path.join(SIB, "original_ROMs", "kn5000_table_data.rom"), 0x000000),
}
PAYLOAD_SPLIT = 0x100
PAYLOAD_BASE_LO = 0x000400
PAYLOAD_BASE_HI = 0x00EF00
KN_SUBSYMS = os.path.join(SIB, "symbols", "subcpu_symbols_reference.txt")
KN_MAINSYMS = os.path.join(SIB, "symbols", "maincpu_v10_symbols_reference.txt")
# which symbol table names a given image.  Used ONLY to place candidate starts
# and to label output; never as evidence -- see --sweep, which uses none of it.
SYMS_FOR = {"kn5000:payload": KN_SUBSYMS, "kn5000:main": KN_MAINSYMS,
            "kn5000:subboot": os.path.join(SIB, "symbols",
                                           "subcpu_boot_symbols_reference.txt")}
TARGET_IMAGE = "kn5000:payload"
KERNEL_S = os.path.join(ROOT, "kernel", "kernel.s")


def payload_addr(off):
    return off + (PAYLOAD_BASE_LO if off < PAYLOAD_SPLIT else PAYLOAD_BASE_HI)


def payload_off(addr):
    return addr - (PAYLOAD_BASE_LO if addr < 0x000500 else PAYLOAD_BASE_HI)


_IMG = {}


def image(key):
    if key not in _IMG:
        _IMG[key] = open(IMAGES[key][0], "rb").read()
    return _IMG[key]


def off_of(key, addr):
    if key == "kn5000:payload":
        return payload_off(addr)
    return addr - IMAGES[key][1]


def addr_of(key, off):
    if key == "kn5000:payload":
        return payload_addr(off)
    return off + IMAGES[key][1]


# --------------------------------------------------------------- decode ----
DISLINE = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*?)\s*$')


def _unidasm(data, basepc):
    """Decode a bytes object linearly.  Returns [(addr, nbytes, text), ...]."""
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(data)
        path = f.name
    try:
        out = subprocess.run(
            ["timeout", "600", UNIDASM, path, "-arch", "tlcs900",
             "-basepc", "0x%X" % basepc],
            capture_output=True, text=True, check=True).stdout
    finally:
        os.unlink(path)
    res = []
    for line in out.split("\n"):
        m = DISLINE.match(line)
        if m:
            res.append((int(m.group(1), 16),
                        len(m.group(2).split()),
                        m.group(3)))
    return res


# ★ THE SLICE TRICK.  To decode N arbitrary start offsets exactly (each one a
#   real instruction boundary), concatenate WINDOW bytes from each start and pad
#   every slice with PAD 0x00 bytes.  0x00 is `nop`, one byte, so however far an
#   instruction straddles the end of a slice the decoder re-synchronises to the
#   next slice boundary before reaching it.  One unidasm call for the lot.
#   --selftest checks the re-synchronisation on real ROM data.
WINDOW = 320
PAD = 16
STRIDE = WINDOW + PAD


def decode_starts(key, starts, window=WINDOW):
    """{start_off: Seq} -- one exact decode per requested start, in ONE call."""
    data = image(key)
    stride = window + PAD
    blob = bytearray()
    keep = []
    seen = set()
    for s in starts:
        if s < 0 or s >= len(data) or s in seen:
            continue
        seen.add(s)
        chunk = data[s:s + window]
        blob += chunk + bytes(window - len(chunk)) + bytes(PAD)
        keep.append(s)
    if not keep:
        return {}
    rows = {s: [] for s in keep}
    for a, n, t in _unidasm(bytes(blob), 0):
        i, rel = divmod(a, stride)
        if i < len(keep) and rel < window:
            rows[keep[i]].append((rel, n, t))
    return {s: Seq(rows[s], addr_of(key, s), text_base=i * stride)
            for i, s in enumerate(keep)}


def decode_linear(key, phase):
    """Whole-image linear decode starting `phase` bytes in.  Cached on disk."""
    os.makedirs(CACHE, exist_ok=True)
    st = os.stat(IMAGES[key][0])
    tag = "%s.%d.%d.%d" % (key.replace(":", "_"), st.st_size, int(st.st_mtime), phase)
    path = os.path.join(CACHE, tag)
    if not os.path.exists(path):
        data = image(key)[phase:]
        rows = _unidasm(data, 0)
        with open(path, "w") as f:
            for a, n, t in rows:
                f.write("%d\t%d\t%s\n" % (a + phase, n, t))
    out = []
    for line in open(path):
        a, n, t = line.rstrip("\n").split("\t", 2)
        out.append((int(a), int(n), t))
    return out


# ------------------------------------------------------------ normalise ----
HEX = re.compile(r'0x[0-9a-f]+')


def tok(text):
    """One instruction -> one comparable token.

    Absolute addresses, displacements and data immediates all print as `0x...`
    in this disassembler, so folding `0x...` to `#` is exactly the "operands may
    differ, mnemonics and registers may not" rule.  Bare decimals are opcode
    fields (`inc 4,IX`, `swi 7`) and are kept.
    """
    return HEX.sub("#", text)


BRANCH = re.compile(r'^(jr|jrl|jp|call|calr|djnz)\b')
TARGET_RE = re.compile(r'0x([0-9a-f]+)\s*$')


def cf_kind(text):
    m = BRANCH.match(text)
    if m:
        return m.group(1)
    if text.startswith("ret") or text.startswith("reti"):
        return "ret"
    return None


def cf_target(text):
    m = TARGET_RE.search(text)
    return int(m.group(1), 16) if m else None


class Seq(object):
    """A decoded run: tokens plus enough to score control flow.

    `rows` are (relative offset, byte length, text) and `base_addr` is the ROM
    address of relative offset 0.  ⚠ `text_base` exists because a BATCHED decode
    (decode_starts) runs unidasm over a concatenation, so the addresses PRINTED
    INSIDE branch texts are blob addresses, not ROM addresses.  Subtracting
    text_base turns a printed target back into a window offset.  Getting this
    wrong is silent -- it does not affect a single token, only the control-flow
    score -- so --selftest S13 pins it.
    """

    def __init__(self, rows, base_addr, text_base=0):
        self.base = base_addr
        self.text_base = text_base
        self.addr = [base_addr + r[0] for r in rows]
        self.n = [r[1] for r in rows]
        self.text = [r[2] for r in rows]
        self.tok = [tok(t) for t in self.text]

    def __len__(self):
        return len(self.tok)

    def index_of_addr(self, a):
        try:
            return self.addr.index(a)
        except ValueError:
            return None

    def cf_deltas(self):
        """{instruction index: delta in INSTRUCTION units} for in-window branches."""
        out = {}
        for i, t in enumerate(self.text):
            k = cf_kind(t)
            if k is None or k == "ret":
                continue
            tg = cf_target(t)
            if tg is None:
                continue
            j = self.index_of_addr(self.base + (tg - self.text_base))
            if j is not None:
                out[i] = j - i
        return out


# ------------------------------------------------------------------ LCS ----
def lcs_len(qids, cids, nq, mask):
    """Bit-parallel LCS length (Crochemore/Iliopoulos/Pinzon/Reid).

    `mask` is {symbol id: bitmask of its positions in the query}, built once per
    query.  --selftest checks this against a naive DP on random inputs.
    """
    V = (1 << nq) - 1
    for s in cids:
        U = V & mask.get(s, 0)
        V = (V + U) | (V - U)
    return nq - bin(V & ((1 << nq) - 1)).count("1")


def lcs_naive(a, b):
    prev = [0] * (len(b) + 1)
    for x in a:
        cur = [0]
        for j, y in enumerate(b):
            cur.append(prev[j] + 1 if x == y else max(prev[j + 1], cur[j]))
        prev = cur
    return prev[-1]


def lcs_pairs(a, b):
    """Full LCS with traceback -> [(i, j), ...] aligned index pairs."""
    na, nb = len(a), len(b)
    dp = [[0] * (nb + 1) for _ in range(na + 1)]
    for i in range(na - 1, -1, -1):
        for j in range(nb - 1, -1, -1):
            dp[i][j] = dp[i + 1][j + 1] + 1 if a[i] == b[j] else max(dp[i + 1][j], dp[i][j + 1])
    out, i, j = [], 0, 0
    while i < na and j < nb:
        if a[i] == b[j]:
            out.append((i, j))
            i += 1
            j += 1
        elif dp[i + 1][j] >= dp[i][j + 1]:
            i += 1
        else:
            j += 1
    return out


_SYM = {}


def sym_id(t):
    if t not in _SYM:
        _SYM[t] = len(_SYM)
    return _SYM[t]


class Query(object):
    def __init__(self, name, key, addr, seq):
        self.name, self.key, self.addr, self.seq = name, key, addr, seq
        self.ids = [sym_id(t) for t in seq.tok]
        self.nq = len(self.ids)
        self.mask = {}
        for i, s in enumerate(self.ids):
            self.mask[s] = self.mask.get(s, 0) | (1 << i)

    def score_tokens(self, cand_tokens):
        if self.nq == 0:
            return 0.0
        cids = [sym_id(t) for t in cand_tokens]
        return lcs_len(self.ids, cids, self.nq, self.mask) / float(self.nq)


def cf_agreement(qseq, cseq):
    """(agreed, total) branch deltas over the LCS alignment of two Seqs."""
    pairs = lcs_pairs(qseq.tok, cseq.tok)
    fwd = dict(pairs)
    qd, cd = qseq.cf_deltas(), cseq.cf_deltas()
    agree = total = 0
    for i, d in qd.items():
        if i not in fwd:
            continue
        j = fwd[i]
        if j not in cd:
            continue
        total += 1
        # map the query's branch target through the alignment when possible;
        # otherwise compare raw instruction deltas.
        tgt = i + d
        if tgt in fwd:
            if fwd[tgt] - j == cd[j]:
                agree += 1
        elif cd[j] == d:
            agree += 1
    return agree, total


# --------------------------------------------------- the WSA1 kernel -------
KLINE = re.compile(r';\s*([0-9A-F]{6})/([0-9A-F]{6})\s+((?:a=)?[0-9a-f]{2}(?: [0-9a-f]{2})*)')
DATA_DIR = ("\t.short", "\t.long", "\t.byte", "\t.ascii", "\t.incbin", "\t.space")


def kernel_lines():
    """[(label_or_None, prom_a_addr, prom_c_addr, is_data), ...] in ROM order."""
    rows, pending = [], None
    for line in open(KERNEL_S):
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', line)
        if m:
            if pending is None or not pending.startswith("sub_"):
                pending = m.group(1) if pending is None else pending
            continue
        m = KLINE.search(line)
        if not m:
            continue
        rows.append((pending, int(m.group(1), 16), int(m.group(2), 16),
                     line.startswith(DATA_DIR)))
        pending = None
    return rows


def kernel_routines():
    """Top-level kernel routines: name -> (prom_a addr, prom_c addr, byte length).

    A routine STARTS at a label that is not an internal `__` continuation and is
    not a `sub_XXXXXX` alias, and runs to the next such start.
    """
    rows = kernel_lines()
    starts = []
    for idx, (lab, a, c, _d) in enumerate(rows):
        if lab and "__" not in lab and not lab.startswith("sub_"):
            starts.append((idx, lab, a, c))
    out = []
    for k, (idx, lab, a, c) in enumerate(starts):
        end_idx = starts[k + 1][0] if k + 1 < len(starts) else len(rows)
        alen = (rows[end_idx][1] if end_idx < len(rows) else rows[-1][1] + 1) - a
        out.append((lab, a, c, alen, rows[idx:end_idx]))
    return out


def routine_seq(key, addr, rows, which):
    """Decode one kernel routine off the real ROM, skipping its inline data.

    Data lines split the routine into contiguous code runs; each run is decoded
    seeded at its own address so no data can desynchronise the decode.
    """
    runs, cur = [], []
    for lab, a, c, is_data in rows:
        pc = a if which == 0 else c
        if is_data:
            if cur:
                runs.append(cur)
                cur = []
        else:
            cur.append(pc)
    if cur:
        runs.append(cur)
    # base 0 / text_base 0: each run below is decoded seeded at its own real
    # address, so both the recorded addresses and the printed branch targets are
    # absolute and `base + (target - text_base)` is the identity.
    seq = Seq([], 0)
    for run in runs:
        start = off_of(key, run[0])
        end = off_of(key, run[-1]) + 8
        rows2 = _unidasm(image(key)[start:end], run[0])
        want = set(run)
        for a2, n2, t2 in rows2:
            if a2 in want:
                seq.addr.append(a2)
                seq.n.append(n2)
                seq.text.append(t2)
                seq.tok.append(tok(t2))
    return seq


_KQ = None


def kernel_queries(which=1, minlen=8):
    """The WSA1 kernel's routines as queries.  which: 0 = prom_a, 1 = prom_c."""
    global _KQ
    ck = (which, minlen)
    if _KQ and _KQ[0] == ck:
        return _KQ[1]
    key = "wsa1:a" if which == 0 else "wsa1:c"
    out = []
    for lab, a, c, alen, rows in kernel_routines():
        seq = routine_seq(key, a if which == 0 else c, rows, which)
        if len(seq) >= minlen:
            out.append(Query(lab, key, a if which == 0 else c, seq))
    out.sort(key=lambda q: -q.nq)
    _KQ = (ck, out)
    return out


# ------------------------------------------------------------ candidates ---
def read_symbols(path):
    out = []
    for line in open(path):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        p = line.split()
        if len(p) == 2 and re.fullmatch(r'[0-9A-Fa-f]+', p[1]):
            out.append((p[0], int(p[1], 16)))
    return out


def symbol_candidates(key, symfile):
    """[(name, addr, off)] for every named symbol that lands inside the image."""
    data = image(key)
    out = []
    for name, addr in read_symbols(symfile):
        try:
            o = off_of(key, addr)
        except Exception:
            continue
        if 0 <= o < len(data) - 8:
            out.append((name, addr, o))
    return out


_DEC = {}


def decode_starts_cached(key, starts, maxwindow=512):
    """decode_starts, memoised on (image, candidate set).

    ★ A linear decode of the first `w` bytes from a start is a PREFIX of the
    decode of the first 512 bytes from the same start -- same bytes, same
    decoder, same seed -- so ONE wide decode serves every query and each query
    clips it to its own length-matched window.  --selftest S14 pins that the
    clipped stream equals a decode done at the narrow width.
    """
    ck = (key, maxwindow, tuple(starts))
    if ck not in _DEC:
        _DEC.clear()          # one candidate set at a time; these are large
        _DEC[ck] = decode_starts(key, list(starts), maxwindow)
    return _DEC[ck]


def clip(seq, window):
    """The prefix of `seq` lying wholly inside the first `window` bytes."""
    k = 0
    while k < len(seq.tok) and (seq.addr[k] - seq.base) + seq.n[k] <= window:
        k += 1
    out = Seq([], seq.base, seq.text_base)
    out.addr, out.n, out.text, out.tok = (seq.addr[:k], seq.n[:k],
                                          seq.text[:k], seq.tok[:k])
    return out


def query_window(q):
    """★ The candidate window is LENGTH-MATCHED to the query.

    A longer window can only raise an LCS score, so a fixed window would reward
    long queries and inflate every score in a data-rich region.  Twice the
    query's own byte length plus a little is enough to hold a homolog that has
    grown a few instructions, and it is applied identically to the real search
    and to all four nulls.
    """
    nbytes = sum(q.seq.n) or 32
    return max(64, min(512, 2 * nbytes + 32))


def score_candidates(q, key, cands, window=None):
    """cands = [(name, addr, off)].  -> sorted [(score, name, addr, Seq)]."""
    window = window or query_window(q)
    dec = decode_starts_cached(key, tuple(c[2] for c in cands),
                               max(512, window))
    res = []
    for name, addr, off in cands:
        seq = dec.get(off)
        if seq is None:
            res.append((0.0, name, addr, Seq([], addr)))
            continue
        seq = clip(seq, window)
        res.append((q.score_tokens(seq.tok), name, addr, seq))
    res.sort(key=lambda r: -r[0])
    return res


def match_site(q, cseq):
    """Where inside a candidate window the match actually STARTS.

    ⚠ LCS is a CONTAINMENT measure, so a candidate that starts a few
    instructions EARLY scores just as well as the exact entry point -- the
    window still holds the whole homolog.  Reporting the candidate's start
    address would therefore name the wrong routine.  This reports the candidate
    instruction aligned with the query's first aligned instruction.
    """
    pairs = lcs_pairs(q.seq.tok, cseq.tok)
    if not pairs:
        return None, 0
    return cseq.addr[pairs[0][1]], pairs[0][1]


def rank_of(res, addr):
    """1-based rank of `addr`, counting ties as equal-best.  Also returns how
    many candidates tie with it, because a rank with ties is not a rank."""
    hit = next(r for r in res if r[2] == addr)
    better = sum(1 for r in res if r[0] > hit[0] + 1e-12)
    ties = sum(1 for r in res if abs(r[0] - hit[0]) <= 1e-12) - 1
    return better + 1, ties, hit


def pct(sorted_desc, p):
    if not sorted_desc:
        return 0.0
    i = min(len(sorted_desc) - 1, int(round((1.0 - p) * (len(sorted_desc) - 1))))
    return sorted_desc[i]


def report_null(scores, best):
    s = sorted(scores, reverse=True)
    n = len(s)
    above = sum(1 for x in s if x >= best - 1e-12)
    return dict(n=n, max=s[0] if s else 0.0, p999=pct(s, 0.999), p99=pct(s, 0.99),
                p95=pct(s, 0.95), median=pct(s, 0.5),
                mean=sum(s) / n if n else 0.0, at_or_above=above,
                p_window=above / float(n) if n else 1.0)


# =============================================================== SECTIONS ===
def hdr(t):
    print("=" * 78)
    print(t)
    print("=" * 78)


CONTROLS = [
    # (label, query image, addr, bytes, target image, target symbols, expected addr,
    #  what this control is calibrating)
    ("P0  prom_c DSP channel-register writer -> KN5000 sub-CPU payload",
     "wsa1:c", 0xF98099, 81, "kn5000:payload", "sub", 0x01FD27,
     "ONE routine, two peripheral bases -- the cross-product CEILING"),
    ("P1  prom_c Kernel_Dispatch -> prom_a",
     "wsa1:c", 0xF9827A, 0x4E, "wsa1:a", None, 0xF85715,
     "ONE source, two CPUs, one build -- the within-product ceiling"),
    ("P2  prom_a INT0 link receiver -> KN5000 sub-CPU boot",
     "wsa1:a", 0xF8E47F, 0x7B, "kn5000:subboot", "subboot", 0xFF881F,
     "SAME PROTOCOL, INDEPENDENTLY WRITTEN -- the score to BEAT, not to match"),
    ("P3  prom_a SC0 UART configure -> KN5000 main CPU",
     "wsa1:a", 0xFA58F0, 0x1F, "kn5000:main", "main", 0xFCF940,
     "one small routine, two builds"),
]

SYMFILES = {"sub": KN_SUBSYMS, "main": KN_MAINSYMS,
            "subboot": os.path.join(SIB, "symbols",
                                    "subcpu_boot_symbols_reference.txt")}


def raw_query(name, key, addr, nbytes):
    off = off_of(key, addr)
    rows = _unidasm(image(key)[off:off + nbytes], addr)
    # text_base=addr: this decode was seeded at `addr`, so the addresses printed
    # inside its branches are already absolute ROM addresses.
    return Query(name, key, addr,
                 Seq([(a - addr, n, t) for a, n, t in rows], addr, text_base=addr))


def section_controls():
    hdr("POSITIVE CONTROLS -- what a TRUE match scores, and can this tool find one?")
    print("  Every row is a homolog established by ANOTHER lane, without this tool")
    print("  (notes/wave7_xref_tlcs900_family.py sections B/D/E, and the kernel/ byte")
    print("  gate).  They calibrate the scale:  P0/P1 say what SHARED SOURCE scores,")
    print("  ★ P2 says what SAME IDEA, DIFFERENT CODE scores -- and that is the number")
    print("  the kernel result has to beat before 'present' means anything.")
    print()
    out = []
    for label, qk, qa, qn, tk, sf, ta, why in CONTROLS:
        q = raw_query(label, qk, qa, qn)
        if sf is None:
            cands = [("0x%06X" % a, a, off_of(tk, a))
                     for _l, a, _c, _n, _r in kernel_routines()]
        else:
            cands = symbol_candidates(tk, SYMFILES[sf])
        if not any(c[1] == ta for c in cands):
            cands.append(("<expected site>", ta, off_of(tk, ta)))
        res = score_candidates(q, tk, cands)
        rank, ties, hit = rank_of(res, ta)
        others = [r for r in res if r[2] != ta]
        ag, tot = cf_agreement(q.seq, hit[3])
        print("  %s" % label)
        print("      %s   (%d instructions)" % (why, q.nq))
        print("      %s:0x%06X -> %s:0x%06X   score %.3f   rank %d of %d (%d tied)"
              % (qk, qa, tk, ta, hit[0], rank, len(res), ties))
        if others:
            print("      best OTHER candidate  %-26s %.3f"
                  % (others[0][1][:26], others[0][0]))
        print("      control flow: %d of %d aligned branches cross the same number"
              " of instructions" % (ag, tot))
        print()
        out.append(dict(label=label, score=hit[0], rank=rank, ties=ties,
                        n=len(res), cf=(ag, tot), why=why))
    return out


def section_null(queries=None, target=None, verbose=True):
    target = target or TARGET_IMAGE
    """N1-N4 for every kernel routine, against the best real hit.

    The loops are candidate-set-OUTER on purpose: each set costs one unidasm
    call over a ~2.5 MB blob, and there are only four of them.
    """
    if queries is None:
        queries = kernel_queries()
    named = symbol_candidates(target, SYMS_FOR[target])
    rnd = random.Random(20260830)
    dl = len(image("kn5000:table"))
    n2 = [("data%d" % i, i, i) for i in
          sorted(rnd.sample(range(0, dl - 600), 4000))]
    pl = len(image(target))
    n4 = [("rand%d" % i, addr_of(target, i), i) for i in
          sorted(rnd.sample(range(PAYLOAD_SPLIT, pl - 600), 4000))]

    shuf = {}
    for q in queries:
        t = list(q.seq.tok)
        rnd.shuffle(t)
        qs = Query(q.name + "#shuffled", q.key, q.addr, Seq([], 0))
        qs.seq.tok, qs.seq.n = t, list(q.seq.n)
        qs.ids = [sym_id(x) for x in t]
        qs.nq = len(t)
        qs.mask = {}
        for i, sym in enumerate(qs.ids):
            qs.mask[sym] = qs.mask.get(sym, 0) | (1 << i)
        shuf[q.name] = qs

    R = {q.name: {} for q in queries}
    for q in queries:                                   # N1 + N3, one decode
        res = score_candidates(q, target, named)
        R[q.name]["res1"] = res
        R[q.name]["s3"] = [x[0] for x in
                           score_candidates(shuf[q.name], target, named)]
    for q in queries:
        R[q.name]["s2"] = [x[0] for x in score_candidates(q, "kn5000:table", n2)]
    for q in queries:
        R[q.name]["res4"] = score_candidates(q, target, n4)

    # ---- the winners' geometric span, used by N5.  Name-free: it is derived
    # from where the matches land, not from what the sibling tree calls them.
    sites = []
    for q in queries:
        st, _ = match_site(q, R[q.name]["res1"][0][3])
        if st:
            sites.append(st)
    span_lo, span_hi = (min(sites) - 512, max(sites) + 512) if sites else (0, 0)

    rows = []
    if verbose:
        hdr("THE NULL -- how well does each WSA1 kernel routine match KN5000 code"
            " that is NOT it?")
        print("  N1  all %d named sub-CPU symbols, MINUS every candidate whose window"
              % len(named))
        print("      overlaps the winner's (an overlapping window contains the same")
        print("      code, so counting it as null would poison the null with the hit)")
        print("  N2  4000 random windows in kn5000_table_data.rom -- an image that is DATA")
        print("  N3  N1's candidates against the query with its token ORDER SHUFFLED")
        print("  N4  4000 random offsets in the sub-CPU payload itself")
        print()
        print("  N5  the named candidates lying OUTSIDE the winners' own address span")
        print("      0x%06X-0x%06X -- i.e. the rest of the ROM with the matching"
              % (span_lo, span_hi))
        print("      region deleted.  ★ N1's own top hits are INSIDE that span, and that")
        print("      is a result, not a nuisance: they are the sibling routines.")
        print()
        print("  %-30s %4s %6s %8s | %-29s | %s"
              % ("WSA1 kernel routine", "n", "best", "site",
                 "null max N1/N2/N3/N4/N5", "N1 max lands at"))
        print("  " + "-" * 108)
    for q in queries:
        res = R[q.name]["res1"]
        best, baddr = res[0][0], res[0][2]
        w = query_window(q)
        s1 = [x[0] for x in res[1:] if abs(x[2] - baddr) > w]
        n1top = [x for x in res[1:] if abs(x[2] - baddr) > w][:1]
        s5 = [x[0] for x in res if not (span_lo <= x[2] <= span_hi)]
        s2 = R[q.name]["s2"]
        s3 = R[q.name]["s3"]
        # ⚠ N4 must exclude a random offset that happened to land ON the hit:
        # 4000 samples over 190 KB at a ~190-byte window lands there ~4 times,
        # and without this the "random" null reports the true positive back.
        s4 = [x[0] for x in
              score_candidates(q, target, n4) if True] if False else \
             [sc for sc, _nm, ad, _sq in R[q.name]["res4"]
              if not (span_lo <= ad <= span_hi)]
        n1 = report_null(s1, best)
        site, _sk = match_site(q, res[0][3])
        rows.append(dict(q=q, best=best, addr=baddr, site=site,
                         n1=n1, s1=s1, s2=s2, s3=s3, s4=s4, s5=s5,
                         span=(span_lo, span_hi),
                         nullmax=max([max(x) for x in (s1, s2, s3, s4, s5) if x])))
        if verbose:
            print("  %-30s %4d %6.3f 0x%06X | %.3f %.3f %.3f %.3f %.3f | 0x%06X"
                  % (q.name[:30], q.nq, best, site or 0, n1["max"], max(s2),
                     max(s3), max(s4) if s4 else 0.0, max(s5) if s5 else 0.0,
                     n1top[0][2] if n1top else 0))
    if verbose:
        print()
        print("  A routine is PRESENT only where 'best' stands clear of ALL FOUR null")
        print("  maxima.  ★ N3 is the sharpest: it holds the instruction MIX constant")
        print("  and destroys only the ORDER, so the gap between 'best' and N3 is the")
        print("  part of the score that is CODE rather than vocabulary.")
    return rows


def sweep(q, target, top=4000, k=4):
    """Name-free whole-image search: k-gram seeding, then LCS on the survivors."""
    votes = {}
    for phase in range(0, 8):
        rows = decode_linear(target, phase)
        toks = [tok(t) for _a, _n, t in rows]
        idx = {}
        for i in range(len(toks) - k + 1):
            idx.setdefault(tuple(toks[i:i + k]), []).append(i)
        for i in range(q.nq - k + 1):
            for j in idx.get(tuple(q.seq.tok[i:i + k]), ()):
                start = j - i
                if start < 0:
                    continue
                votes[rows[start][0]] = votes.get(rows[start][0], 0) + 1
    order = sorted(votes.items(), key=lambda kv: -kv[1])[:top]
    cands = [("0x%06X" % addr_of(target, o), addr_of(target, o), o) for o, _v in order]
    if not cands:
        return []
    return score_candidates(q, target, cands)


def section_sweep(queries=None, target=None):
    target = target or TARGET_IMAGE
    hdr("NAME-FREE SWEEP -- the KN5000 tree's labels are not used at all")
    print("  Candidate starts come from k-gram seeding over EIGHT phase-shifted linear")
    print("  decodes of the whole image, not from any symbol table.  If the winner is")
    print("  the same site the null section found, the result does not rest on the")
    print("  sibling tree's naming.")
    print()
    if queries is None:
        queries = kernel_queries()[:10]
    out = []
    for q in queries:
        res = sweep(q, target)
        if not res:
            print("  %-34s  no seed" % q.name)
            continue
        print("  %-34s  best 0x%06X  score %.3f   (2nd 0x%06X %.3f)"
              % (q.name[:34], res[0][2], res[0][0],
                 res[1][2] if len(res) > 1 else 0, res[1][0] if len(res) > 1 else 0))
        out.append((q, res))
    return out


def section_table(queries=None, target=None):
    target = target or TARGET_IMAGE
    hdr("THE ANSWER, PER ROUTINE")
    if queries is None:
        queries = kernel_queries()
    cands = symbol_candidates(target, SYMS_FOR[target])
    print("  %-30s %4s %-26s %8s %6s %9s" %
          ("WSA1 kernel routine", "n", "KN5000 site the match STARTS at",
           "addr", "score", "ctrl-flow"))
    print("  " + "-" * 92)
    rows = []
    sym_by_addr = {}
    for name, addr, _o in cands:
        sym_by_addr.setdefault(addr, name)
    for q in queries:
        res = score_candidates(q, target, cands)
        best = res[0]
        ag, tot = cf_agreement(q.seq, best[3])
        site, skipped = match_site(q, best[3])
        label = sym_by_addr.get(site, "(unnamed, +%d into %s)" % (skipped, best[1]))
        print("  %-30s %4d %-26s 0x%06X %6.3f %9s"
              % (q.name[:30], q.nq, label[:26], site or 0, best[0],
                 "%d/%d" % (ag, tot)))
        rows.append(dict(q=q, score=best[0], site=site, label=label, cf=(ag, tot)))
    return rows


def lis_len(xs):
    """Longest strictly increasing subsequence length."""
    import bisect
    tails = []
    for x in xs:
        i = bisect.bisect_left(tails, x)
        if i == len(tails):
            tails.append(x)
        else:
            tails[i] = x
    return len(tails)


def section_order(target=None, trials=200000):
    target = target or TARGET_IMAGE
    """★ THE ORDER TEST -- the one instrument that uses no score threshold.

    If the KN5000's scheduler were merely a similar piece of code, its routines
    would be laid out in ITS OWN order.  If it came off the same source, the
    routines appear in the SAME ORDER.  So: take the WSA1 kernel's routines in
    prom_c ROM order, ask each one independently where its best match is, and
    count how long an INCREASING run those answers form.  Nothing here depends
    on a similarity threshold, on a name, or on the previous sections.

    Null: the same 'best site' values randomly permuted, `trials` times.
    """
    hdr("THE ORDER TEST -- do the matches come out in the SAME ORDER?")
    qs = sorted(kernel_queries(), key=lambda q: q.addr)
    cands = symbol_candidates(target, SYMS_FOR[target])
    sites, rows = [], []
    for q in qs:
        res = score_candidates(q, target, cands)
        st, _ = match_site(q, res[0][3])
        sites.append(st or 0)
        rows.append((q, res[0][0], st))
    L = lis_len(sites)
    rnd = random.Random(4242)
    pool = list(sites)
    hits = 0
    dist = {}
    for _ in range(trials):
        rnd.shuffle(pool)
        v = lis_len(pool)
        dist[v] = dist.get(v, 0) + 1
        if v >= L:
            hits += 1
    print("  %-32s %-10s %-10s" % ("WSA1 kernel routine (ROM order)", "prom_c", "KN5000"))
    print("  " + "-" * 60)
    for q, sc, st in rows:
        print("  %-32s 0x%06X   0x%06X   %.3f" % (q.name[:32], q.addr, st or 0, sc))
    print()
    print("  %d routines.  Longest INCREASING run of KN5000 sites: %d" % (len(sites), L))
    print("  Null: the same %d sites randomly permuted, %d times."
          % (len(sites), trials))
    print("    mean %.2f   max %d   times >= %d: %d  (p <= %.1e)"
          % (sum(k * v for k, v in dist.items()) / float(trials),
             max(dist), L, hits, max(hits, 1) / float(trials)))
    return L, hits, trials


REGION = None      # set by --region=LO:HI to skip the (expensive) survey below


def matched_region(target, cands, margin=0x400):
    if REGION:
        return REGION
    """The address span the kernel queries actually land in, +/- margin.

    Derived from where the matches fall, not from any label.  Used to build a
    DENSE candidate set for the assignment: one candidate per BYTE, so the
    assignment is not limited to addresses the sibling tree happens to have
    named.
    """
    sites = []
    for q in kernel_queries():
        res = score_candidates(q, target, cands)
        st, _ = match_site(q, res[0][3])
        if st:
            sites.append(st)
    return min(sites) - margin, max(sites) + margin


def dense_candidates(target, lo, hi):
    return [("", addr_of(target, o), o)
            for o in range(off_of(target, lo), off_of(target, hi))]


def best_sites(q, target, cands, k=48, mindist=6):
    """The query's top distinct match SITES: [(site, score, Seq), ...]."""
    res = score_candidates(q, target, cands)
    out = []
    for sc, _nm, _ad, seq in res[:400]:
        if seq is None or not len(seq):
            continue
        site, _ = match_site(q, seq)
        if site is None:
            continue
        if any(abs(site - s2) < mindist for s2, _s, _q in out):
            continue
        out.append((site, sc, seq))
        if len(out) >= k:
            break
    return out


def section_assign(target=None):
    target = target or TARGET_IMAGE
    """★ ROUTINE-FOR-ROUTINE, resolved by ORDER instead of by greed.

    Taking each WSA1 routine's single best site independently puts two of them
    on the same KN5000 address: LCS is a containment measure, so a short routine
    that is a subsequence of a longer neighbour scores just as well inside it.
    The fix uses no names and no thresholds -- only the claim the order test
    already measured, that the two layouts run in the same direction.  Assign
    every routine at once, maximising the total score subject to the sites being
    STRICTLY INCREASING.
    """
    hdr("ROUTINE FOR ROUTINE -- best total score under a strictly increasing layout")
    qs = sorted(kernel_queries(), key=lambda q: q.addr)
    named = symbol_candidates(target, SYMS_FOR[target])
    lo, hi = matched_region(target, named)
    cands = dense_candidates(target, lo, hi)
    print("  candidate starts: EVERY byte of 0x%06X-0x%06X (%d of them), so the"
          % (lo, hi, len(cands)))
    print("  placement is not restricted to addresses the sibling tree named.")
    print()
    opts = [best_sites(q, target, cands) for q in qs]
    NEG = -1e9
    n = len(qs)
    dp = [[NEG] * len(opts[i]) for i in range(n)]
    bk = [[None] * len(opts[i]) for i in range(n)]
    for j, (site, sc, _s) in enumerate(opts[0]):
        dp[0][j] = sc
    for i in range(1, n):
        for j, (site, sc, _s) in enumerate(opts[i]):
            best, arg = NEG, None
            for j2, (s2, _sc2, _q2) in enumerate(opts[i - 1]):
                if s2 < site and dp[i - 1][j2] > best:
                    best, arg = dp[i - 1][j2], j2
            if arg is not None:
                dp[i][j], bk[i][j] = best + sc, arg
    j = max(range(len(opts[n - 1])), key=lambda x: dp[n - 1][x])
    chain = [None] * n
    for i in range(n - 1, -1, -1):
        chain[i] = j
        j = bk[i][j] if i else None
        if j is None and i:
            break
    syms = sorted((a, n) for n, a, _o in
                  symbol_candidates(target, SYMS_FOR[target]))

    def label_at(a):
        import bisect
        i = bisect.bisect_right(syms, (a, "\xff")) - 1
        if i < 0:
            return ""
        base, name = syms[i]
        return name if base == a else "%s+%d" % (name, a - base)

    print("  %-32s %-9s %-9s %6s %6s %s"
          % ("WSA1 kernel routine", "prom_c", "KN5000", "score", "cflow",
             "the sibling tree's own label there"))
    print("  " + "-" * 104)
    rows = []
    for i, q in enumerate(qs):
        if chain[i] is None:
            print("  %-32s 0x%06X   --" % (q.name[:32], q.addr))
            continue
        site, sc, seq = opts[i][chain[i]]
        ag, tot = cf_agreement(q.seq, seq)
        lbl = label_at(site)
        print("  %-32s 0x%06X   0x%06X %6.3f %6s  %s"
              % (q.name[:32], q.addr, site, sc, "%d/%d" % (ag, tot), lbl))
        rows.append((q, site, sc, seq, ag, tot))
    tot = sum(r[2] for r in rows)
    print()
    print("  %d of %d routines placed; mean score %.3f" %
          (len(rows), n, tot / max(1, len(rows))))
    return rows


def section_constants(target=None):
    target = target or TARGET_IMAGE
    """Every operand that differs, once the two routines are aligned.

    This is the third processor's answer to kernel/kernel_subcpu.inc: if the
    kernel is ever shared across all three, these are the values that have to
    become equates.
    """
    hdr("THE CONSTANTS -- what actually differs, once the code is aligned")
    rows = section_assign(target)
    print()
    seen = {}
    same = diff = 0
    for q, site, sc, seq, _a, _t in rows:
        fwd = dict(lcs_pairs(q.seq.tok, seq.tok))
        for i, j in fwd.items():
            if q.seq.text[i] == seq.text[j]:
                same += 1
                continue
            diff += 1
            # ⚠ a branch or call operand is a RELOCATION, not a constant, and in
            # a batched decode its printed target is blob-relative anyway.
            if cf_kind(q.seq.text[i]):
                continue
            a = HEX.findall(q.seq.text[i])
            b = HEX.findall(seq.text[j])
            if len(a) == len(b):
                for x, y in zip(a, b):
                    if x != y:
                        seen.setdefault((x, y), []).append(q.name)
    print("  aligned instruction pairs: %d identical text, %d differing only in operands"
          % (same, diff))
    print()
    print("  %-12s %-12s %4s  %s" % ("WSA1", "KN5000", "n", "routines"))
    print("  " + "-" * 74)
    for (x, y), who in sorted(seen.items(), key=lambda kv: -len(kv[1]))[:40]:
        print("  %-12s %-12s %4d  %s"
              % (x, y, len(who), ", ".join(sorted(set(who))[:3])))
    return seen


NEGATIVE_TARGETS = [
    ("wsa1:b", "★ prom_b -- the SAME product, the SAME compiler, the SAME era, and"
               " NO kernel:\n      it reaches the kernel through prom_a's thunk table"
               " (FINDINGS-prom_a-kernel-lifecycle.md).\n      If kernel routines"
               " scored high here, the tool would be measuring the compiler."),
    ("kn5000:main", "the KN5000's OTHER processor -- same product as the target,"
                    " different CPU"),
    ("kn5000:subboot", "the KN5000 sub-CPU's BOOT ROM -- same processor as the"
                       " target, different image"),
]


def section_negative(nsamples=8000):
    """Negative controls: real TLCS-900 code that must NOT contain the kernel."""
    hdr("NEGATIVE CONTROLS -- code that must NOT match, and does not")
    qs = kernel_queries()[:12]
    rnd = random.Random(99)
    print("  %d random offsets per image, the same length-matched window as the"
          " real search." % nsamples)
    print()
    print("  %-30s %4s %6s | %s" % ("WSA1 kernel routine", "n", "KN5000",
                                    "  ".join("%-12s" % k for k, _ in NEGATIVE_TARGETS)))
    print("  " + "-" * 96)
    payload = symbol_candidates(TARGET_IMAGE, SYMS_FOR[TARGET_IMAGE])
    real = {}
    for q in qs:
        real[q.name] = score_candidates(q, TARGET_IMAGE, payload)[0][0]
    cols = {}
    for key, _why in NEGATIVE_TARGETS:
        n = len(image(key))
        cands = [("r%d" % o, addr_of(key, o), o) for o in
                 sorted(rnd.sample(range(0, n - 600), nsamples))]
        for q in qs:
            cols[(q.name, key)] = max(x[0] for x in
                                      score_candidates(q, key, cands))
    for q in qs:
        print("  %-30s %4d %6.3f | %s"
              % (q.name[:30], q.nq, real[q.name],
                 "  ".join("%-12.3f" % cols[(q.name, k)] for k, _ in NEGATIVE_TARGETS)))
    print()
    for key, why in NEGATIVE_TARGETS:
        print("  %-16s %s" % (key, why))
    return cols


def section_align(names=None, target=None):
    target = target or TARGET_IMAGE
    """Instruction-for-instruction alignment, and WHICH CONSTANTS DIFFER.

    This is the part a future lane needs in order to share one source across all
    three processors: for every aligned pair whose tokens agree, the operands
    that do not agree are the per-CPU constants -- exactly the shape
    kernel/kernel_maincpu.inc and kernel_subcpu.inc already have for the WSA1's
    two CPUs.
    """
    hdr("ALIGNMENT -- the per-CPU constants, routine by routine")
    cands = symbol_candidates(target, SYMS_FOR[target])
    qs = kernel_queries()
    if names:
        qs = [q for q in qs if q.name in names]
    for q in qs:
        res = score_candidates(q, target, cands)
        best = res[0]
        cseq = best[3]
        pairs = lcs_pairs(q.seq.tok, cseq.tok)
        fwd = dict(pairs)
        ag, tot = cf_agreement(q.seq, cseq)
        print()
        print("  %s  (WSA1 %s 0x%06X, %d instructions)"
              % (q.name, q.key, q.addr, q.nq))
        site, skipped = match_site(q, cseq)
        print("  window start %s 0x%06X; the match STARTS at 0x%06X   score %.3f"
              "   control flow %d/%d"
              % (best[1], best[2], site or 0, best[0], ag, tot))
        print("  %-9s %-34s %-9s %s" % ("WSA1", "", "KN5000", ""))
        j_prev = -1
        for i in range(q.nq):
            j = fwd.get(i)
            if j is None:
                print("  %06X    %-34s %-9s %s"
                      % (q.seq.addr[i], q.seq.text[i], "--", "(no counterpart)"))
                continue
            for jj in range(j_prev + 1, j):
                print("  %-9s %-34s %06X    %s   (extra)"
                      % ("--", "", cseq.addr[jj], cseq.text[jj]))
            mark = "" if q.seq.text[i] == cseq.text[j] else "   <- operand"
            print("  %06X    %-34s %06X    %s%s"
                  % (q.seq.addr[i], q.seq.text[i], cseq.addr[j], cseq.text[j], mark))
            j_prev = j
    return


# ------------------------------------------------------------- selftest ----
def selftest():
    fails = []

    def check(name, ok, detail=""):
        print("  %-4s %s%s" % ("PASS" if ok else "FAIL", name,
                               ("   " + detail) if detail and not ok else ""))
        if not ok:
            fails.append(name)

    # S1  bit-parallel LCS == naive DP, on random inputs
    rnd = random.Random(7)
    ok = True
    for _ in range(300):
        a = [rnd.randrange(6) for _ in range(rnd.randrange(1, 25))]
        b = [rnd.randrange(6) for _ in range(rnd.randrange(1, 25))]
        mask = {}
        for i, s in enumerate(a):
            mask[s] = mask.get(s, 0) | (1 << i)
        if lcs_len(a, b, len(a), mask) != lcs_naive(a, b):
            ok = False
            break
    check("S1  bit-parallel LCS agrees with a naive DP (300 random pairs)", ok)

    # S2  LCS traceback is a real common subsequence of both, of the right length
    ok = True
    for _ in range(200):
        a = [rnd.randrange(5) for _ in range(rnd.randrange(1, 20))]
        b = [rnd.randrange(5) for _ in range(rnd.randrange(1, 20))]
        p = lcs_pairs(a, b)
        if len(p) != lcs_naive(a, b):
            ok = False
            break
        if any(a[i] != b[j] for i, j in p):
            ok = False
            break
        if any(p[t][0] >= p[t + 1][0] or p[t][1] >= p[t + 1][1] for t in range(len(p) - 1)):
            ok = False
            break
    check("S2  LCS traceback is strictly increasing and matches its own length", ok)

    # S3  the normaliser folds operands but NOT opcode fields
    check("S3  `ld (0x91),WA` and `ld (0x1046),WA` are one token",
          tok("ld (0x91),WA") == tok("ld (0x1046),WA"))
    check("S4  `inc 4,IX` and `inc 1,IX` stay DIFFERENT tokens",
          tok("inc 4,IX") != tok("inc 1,IX"))
    check("S5  `ld WA,(XIX+0x00)` and `ld WA,(XIY+0x00)` stay DIFFERENT tokens",
          tok("ld WA,(XIX+0x00)") != tok("ld WA,(XIY+0x00)"))

    # S6  ★ the reason this tool decodes BYTES and not the two trees' .s text:
    #     the same three bytes are spelled differently in the two trees.
    d = _unidasm(bytes([0x9c, 0x00, 0x23]), 0)
    check("S6  bytes 9c 00 23 decode to ONE instruction, whatever the tree calls it",
          len(d) == 1 and d[0][2] == "ld HL,(XIX+0x00)",
          repr(d))
    wsa1_spelling = "m_ld_rm MWD+r4, 0x00, r3"
    kn_spelling = "ld hl, (xix + 256)"
    a_ok = any(wsa1_spelling in l for l in open(KERNEL_S))
    kn_src = os.path.join(SIB, "v142", "subcpu", "kn5000_subprogram_v142.s")
    c_ok = any(kn_spelling in l for l in open(kn_src)) if os.path.exists(kn_src) else False
    check("S7  ...and the two trees really do spell it differently in their sources",
          a_ok and c_ok, "wsa1=%s kn5000=%s" % (a_ok, c_ok))

    # S8  slice-decode re-synchronisation on real ROM data
    data = image("kn5000:payload")
    rnd2 = random.Random(11)
    starts = sorted(rnd2.sample(range(PAYLOAD_SPLIT, len(data) - WINDOW), 200))
    dec = decode_starts("kn5000:payload", starts)
    bad = [s for s in starts
           if s not in dec or not len(dec[s])
           or dec[s].addr[0] != addr_of("kn5000:payload", s)]
    check("S8  every batched slice decode begins exactly at its own start (200 slices)",
          not bad, "first bad: %r" % (bad[:3],))

    # S9  ★ the byte gate's consequence: ONE kernel source, two CPUs, so the two
    #     copies MUST normalise to the same token sequence.  A normaliser that
    #     leaked an address would break this.  Pinned to an invariant of the
    #     ROMs, not to a number.
    qa = kernel_queries(which=0)
    _KQg = None
    globals()["_KQ"] = None
    qc = kernel_queries(which=1)
    globals()["_KQ"] = None
    same = {q.name: q.seq.tok for q in qa}
    diff = [q.name for q in qc if same.get(q.name) != q.seq.tok]
    check("S9  prom_a and prom_c normalise to IDENTICAL token sequences for every"
          " kernel routine", not diff, "differ: %r" % (diff[:4],))

    # S10 the payload base really is +0xEF00 above the trampoline page
    check("S10 payload address mapping (off>=0x100 -> +0xEF00) is self-consistent",
          payload_off(payload_addr(0x11021)) == 0x11021 and payload_addr(0) == 0x400)

    # S11 a query must score 1.000 against itself and less against a shuffle
    q = kernel_queries()[0]
    self_score = q.score_tokens(q.seq.tok)
    sh = list(q.seq.tok)
    random.Random(3).shuffle(sh)
    check("S11 a query scores 1.000 on itself and strictly less on its own shuffle",
          abs(self_score - 1.0) < 1e-9 and q.score_tokens(sh) < 1.0,
          "self=%.3f shuf=%.3f" % (self_score, q.score_tokens(sh)))

    # S14 clipping a wide decode == decoding narrow in the first place
    o14 = off_of("kn5000:payload", 0x01FF21)
    wide = decode_starts("kn5000:payload", [o14], 512)[o14]
    narrow = decode_starts("kn5000:payload", [o14], 96)[o14]
    check("S14 a 512-byte decode clipped to 96 bytes equals a 96-byte decode",
          clip(wide, 96).tok == narrow.tok and len(narrow.tok) > 5)

    # S13 ★ a batched slice decode must produce the SAME control-flow deltas as
    #     an unbatched decode of the same bytes.  This is the check that would
    #     have caught the blob-relative branch targets: it changes no token, so
    #     nothing else in this file notices.
    bad13 = []
    for a in (0xF85715, 0xF8E47F, 0xFA58F0):
        o = off_of("wsa1:a", a)
        # a decoy slice first, so the checked slice is NOT at blob offset 0 and
        # its printed branch targets really are blob-relative.
        batched = decode_starts("wsa1:a", [0x100, 0x200, o])[o]
        rows = _unidasm(image("wsa1:a")[o:o + WINDOW], a)
        direct = Seq([(x - a, n, t) for x, n, t in rows], a, text_base=a)
        if batched.cf_deltas() != direct.cf_deltas() or not direct.cf_deltas():
            bad13.append(hex(a))
    check("S13 batched and unbatched decodes agree on every branch delta", not bad13,
          "disagree at %r" % (bad13,))

    # S12 the null must be non-degenerate: a scorer that returns 0 or 1 for
    #     everything would pass every other check and be useless.
    cands = symbol_candidates("kn5000:payload", KN_SUBSYMS)[:600]
    s = [x[0] for x in score_candidates(q, "kn5000:payload", cands)]
    check("S12 the null distribution is non-degenerate (0 < median < max < 1)",
          bool(s) and 0.0 < sorted(s)[len(s) // 2] < max(s) < 1.0,
          "median=%.3f max=%.3f" % (sorted(s)[len(s) // 2], max(s)) if s else "empty")

    print()
    print("%d check(s) FAILED" % len(fails) if fails else "all checks passed")
    return 1 if fails else 0


def main():
    global TARGET_IMAGE
    args = sys.argv[1:]
    global REGION
    for a in list(args):
        if a.startswith("--region="):
            lo, hi = a.split("=", 1)[1].split(":")
            REGION = (int(lo, 16), int(hi, 16))
            args.remove(a)
    for a in list(args):
        if a.startswith("--target="):
            TARGET_IMAGE = a.split("=", 1)[1]
            args.remove(a)
    if TARGET_IMAGE not in SYMS_FOR:
        print("unknown --target %r; pick one of %s" % (TARGET_IMAGE, sorted(SYMS_FOR)))
        return 2
    print("TARGET IMAGE: %s   (%s)" % (TARGET_IMAGE, IMAGES[TARGET_IMAGE][0]))
    print()
    if "--selftest" in args:
        return selftest()
    todo = [a for a in args if a.startswith("--")]
    if not todo:
        todo = ["--controls", "--null", "--negative", "--order", "--sweep",
                "--assign", "--constants"]
    if "--controls" in todo:
        section_controls()
    if "--null" in todo:
        section_null()
    if "--sweep" in todo:
        section_sweep()
    if "--table" in todo:
        section_table()
    if "--negative" in todo:
        section_negative()
    if "--assign" in todo:
        section_assign()
    if "--constants" in todo:
        section_constants()
    if "--order" in todo:
        section_order()
    if "--align" in todo:
        names = [a for a in args if not a.startswith("--")] or None
        section_align(names)
    return 0


if __name__ == "__main__":
    sys.exit(main())
