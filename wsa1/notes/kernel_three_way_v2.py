#!/usr/bin/env python3
"""Is the WSA1's shared kernel ALSO in the KN5000?  v2 -- STRUCTURAL, on proven extents.

QUESTION IT ANSWERS
    prom_a and prom_c run the same kernel (36 routine pairs, 35 with ZERO structural
    differences -- notes/prom_c_kernel_map.py --pairs).  Does a THIRD processor run it
    too?  If it does, one kernel source could serve three CPUs across two instruments.

WHY v2 EXISTS -- v1's negative was an artefact of the instrument, not a fact
    notes/kernel_three_way.py reported "0 kernel routines found in 41 KN5000 images"
    with THREE defects, each of which this script fixes and then measures:

      1. IT MEASURED ALMOST NOTHING.  Its extents came from a label-prefix walk that
         split the block at every internal label, so 32 of its 37 candidates were
         under 24 bytes and only FIVE were long enough to count.  v2 uses the 36
         extents from prom_c_kernel_map.py, whose tiling is checked from the first row
         through the LAST against the published block end.  24 of those 36 are >= 24 B.
      2. IT TESTED BYTE-IDENTITY.  The WSA1's own two copies are only 91.5% identical
         (notes/kernel_shared_source_probe.py); every difference is a RAM address, an
         SFR address or a sizing constant.  A third machine with a different RAM map
         must differ at least that much, so byte-identity could only ever return 0.
         v2's load-bearing tier compares INSTRUCTION SHAPE: mnemonic and register
         operands kept, every numeric literal wildcarded.
      3. ITS "41 IMAGES" INCLUDED 4 TEXT FILES.  v1 took every file over 4,096 bytes,
         which swept in the FOUR *.unidasm disassembly LISTINGS (10.4 MB, 4.6 MB,
         3.4 MB and 43.6 MB of ASCII) and dropped three real binaries for being small:
         41 = 40 binaries - 3 small + 4 listings.  v2 enumerates binaries and says so.

METHOD -- three tiers of strictness, each with its own null, one pass per image
    T1  whole routine byte-identical                    (what v1 measured)
    T2  longest byte-identical WINDOW of the routine    (survives operand swaps)
    T3  longest run of identical INSTRUCTION SHAPES     (survives address swaps)
    T4  at every T3 hit, the instruction-level alignment: identical text / same
        mnemonic different operand / different mnemonic / inserted / deleted -- the
        same four-way split notes/prom_c_prom_a_routine_diff.py reports, generalised
        with difflib so that an INSERTED instruction does not desynchronise the rest.

    T2 and T3 both work by one pass over the image: build the anchor set from the
    ROUTINES (small), stream the image once, extend at every anchor hit.  No
    quadratic search and no per-offset subprocess.

    ⚠ THE ALIGNMENT PROBLEM, and why it is not a guessed boundary.  A TLCS-900 decode
    needs a start.  v2 decodes each image from PHASES 0..N-1 and takes the best run
    over all phases; --selftest checks that the phases agree at the two boundaries
    that are known independently, which is what makes one phase enough in practice.
    The routine side is never guessed: its extents are prom_c_kernel_map.py's.

RESULT (2026-08-30, and this is the answer A2 was asked for)
    ★★ THE KERNEL IS IN THE KN5000, IN BOTH OF ITS CPUs.  Six of the 40 binaries carry
    it -- the three maincpu builds (v7/v9/v10, at 0xEF194D-0xEF23xx) and the three
    sub-CPU payload builds (v140/v141/v142, at 0x01FDDA-0x0206xx).  Nothing else does:
    subcpu_boot, hd-ae5000, custom_data, table_data, every compressed payload and the
    WSA1's own prom_b all score below the anchor.

        of the 26 routines long enough to test, 24 have a counterpart, 2 do not
        (Kernel_Start, Kernel_ExitTask)
        Kernel_ResumeTask is BYTE-IDENTICAL, all 9 bytes, in all six images
        longest byte-identical window     34 B      (shuffle null 0)
        longest identical shape run       29 instr  (shuffle null < 6)
        best whole-routine alignment      61 of 80 instructions identical in TEXT
                                          (MsgQueue_Send_NoDispatch)

    ★ AND THE TWO TREES AGREE ON THE NAMES, having never exchanged one.  --correspondence
    prints the table; --selftest asserts that no KN5000 scheduler name appears anywhere in
    the WSA1 sources, so the agreement is evidence and not an echo:

        Kernel_InitRam        <-> TaskSched_Init          Kernel_StartTask <-> TaskSched_SpawnTask
        Kernel_ResumeTask     <-> TaskSched_ContextRestore  Kernel_ReadyTask <-> TaskSched_Wake_Task
        Kernel_SemaWait       <-> TaskSched_Wait          MsgQueue_Send    <-> TaskMsgQ_Send
        Kernel_YieldRotate    <-> TaskSched_PreemptiveYield  SoftTimer_Register <-> TaskTimer_Register
        Kernel_SetTaskLevel   <-> TaskSched_ChangePriority

    ⚠ Two KN5000 MAINCPU labels disagree with the KN5000 SUB-CPU's own labels for the
    same code, and the WSA1 sides with the sub-CPU.  Reported, not applied -- this lane
    is read-only:
        maincpu Audio_Lock_Acquire / Audio_Lock_Release   = a general counting semaphore
                                                            (subcpu: TaskSched_Wait)
        maincpu Show_ScreenGroup_Entry                    = the task-spawn routine
                                                            (subcpu: TaskSched_SpawnTask)

CONTROLS -- a negative is only worth reporting from an instrument that finds a positive
    positive T1/T2 : the already-measured shared run at prom_c 0xFDE32B is in a KN5000 image
    negative T1/T2 : a synthetic 32-byte run is in none of them
    positive T3    : prom_a is searched as if it were an unknown image, and must give a
                     FULL-LENGTH shape run for every routine -- it is the known sibling
    null T2        : the routines' bytes shuffled (same byte histogram), same search
    null T3        : the routines' shapes shuffled (same shape histogram), same search
    ⚠ prom_b (the WSA1 maincpu LOW half, which does not hold the kernel) and the KN5000
      data images are searched too and are reported as themselves -- they are the
      in-corpus controls for "what does a machine that lacks this code score?"

RUN
    python3 notes/kernel_three_way_v2.py                 # the full three-way report
    python3 notes/kernel_three_way_v2.py --selftest      # the controls, 18 checks
    python3 notes/kernel_three_way_v2.py --phases 4      # more decode phases
    python3 notes/kernel_three_way_v2.py --correspondence # WSA1 vs both KN5000 CPUs
    python3 notes/kernel_three_way_v2.py --align kn5000_v7_program.rom Kernel_InitRam
                                                         # one routine's T4 alignment

WHAT IT CANNOT DO
    * It compares unidasm's TEXT, exactly as prom_c_prom_a_routine_diff.py does.  Two
      different encodings that render the same text are called equal.  The T4 tables
      print the full operand lists so that stays checkable.
    * A shape run says "the same instructions in the same order with different
      numbers".  It does not prove one source produced both; it proves that a claim of
      independent authorship has to explain N consecutive instructions.  The null
      columns are there so N can be judged instead of admired.
    * READ-ONLY.  It opens ROM images, notes/prom_c_kernel_map.py and the KN5000
      symbol reference files.  It never touches a .s in either tree.
"""
import ast
import os
import random
import re
import subprocess
import sys
import tempfile
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KN_ROOT = "/home/fsanches/compartilhado/kn5000-roms-disasm"
KN_ROMS = os.path.join(KN_ROOT, "original_ROMs")
KN_SYMS = os.path.join(KN_ROOT, "symbols")
UNIDASM = os.environ.get("UNIDASM",
                         os.path.expanduser("~/compartilhado/kn7000_mame_build/unidasm"))
KERNEL_MAP = os.path.join(ROOT, "notes", "prom_c_kernel_map.py")

PROM_BASE = 0xF80000
BYTE_ANCHOR = 8          # T2: bytes.  A shorter anchor is noise -- see the null column
SHAPE_ANCHOR = 6         # T3: instructions
BYTE_EVIDENCE = 24       # v1's bar, kept so the two runs are comparable
SHAPE_EVIDENCE = 12      # T3: instructions.  Justified by the null, not by taste

# KN5000 load addresses.  Sources: kn5000-roms-disasm/{v7,v9,v10}/maincpu/maincpu.ld
# ORIGIN 0xE00000, v142/subcpu/subcpu.ld ORIGIN 0x0400, subcpu/boot/subcpu_boot.ld
# ORIGIN 0xFE0000, and the Makefile's --rom-base for table_data/custom_data/hdae5000.
# ⚠⚠ THE SUB-CPU PAYLOAD IMAGE IS SPLICED, NOT FLAT.  ../kn5000-roms-disasm/Makefile:635-641
# builds it as .full[0:256] ++ .full[60416:], where .full starts at address 0x0400 -- so the
# file has a 60,160-byte hole and
#       file offset  < 0x100 :  address = 0x0400 + offset
#       file offset >= 0x100 :  address = 0xEF00 + offset
# A flat "base 0x400" reading is wrong by 0xEB00 over 99.8% of the file.  ★ THIS TREE HAS
# ALREADY PAID FOR THAT EXACT ERROR: it is the retraction at the top of
# notes/kn5000-label-transplant.md, where all 8 proposals named the wrong object, and the
# corrected map lives in notes/prom_c_kn5000_xref.py:58.  The formula below is that one, not
# a re-derivation -- and this lane's own first draft reproduced the bug for an hour and was
# one step from reporting that the KN5000's curve-table labels were wrong when it was the
# ADDRESS ARITHMETIC that was wrong.
# --selftest checks the map against content the KN5000 tree describes independently.
SPLICED = {"kn5000_subprogram_v140.rom", "kn5000_subprogram_v141.rom",
           "kn5000_subprogram_v142.rom"}
SPLICE_FILE_CUT = 0x100      # file bytes below this are the 0x0400 page
SPLICE_ADDR_HI = 0xEF00      # ... and above it, address = SPLICE_ADDR_HI + file offset
KN_BASES = {
    "kn5000_v7_program.rom":      0xE00000,
    "kn5000_v9_program.rom":      0xE00000,
    "kn5000_v10_program.rom":     0xE00000,
    # the decode basepc for the SPLICED images IS the splice constant, so every address
    # in the 99.8% segment comes out true; only the first 256 bytes decode 0xEB00 low,
    # and addr_from_off() is what the report uses for those.
    "kn5000_subprogram_v140.rom": SPLICE_ADDR_HI,
    "kn5000_subprogram_v141.rom": SPLICE_ADDR_HI,
    "kn5000_subprogram_v142.rom": SPLICE_ADDR_HI,
    "kn5000_subcpu_boot.ic30":    0xFE0000,
    "kn5000_table_data.rom":      0x800000,
    "kn5000_custom_data.ic19":    0x300000,
    "hd-ae5000_v2_06i.ic4":       0x280000,
}
# address -> label, for naming a hit in the KN5000's own terms
KN_SYMFILE = {
    "kn5000_v7_program.rom":      "maincpu_v7_symbols_reference.txt",
    "kn5000_v9_program.rom":      "maincpu_v9_symbols_reference.txt",
    "kn5000_v10_program.rom":     "maincpu_v10_symbols_reference.txt",
    "kn5000_subprogram_v142.rom": "subcpu_symbols_reference.txt",
    "kn5000_subcpu_boot.ic30":    "subcpu_boot_symbols_reference.txt",
    "hd-ae5000_v2_06i.ic4":       "hdae5000_symbols_reference.txt",
    "kn5000_table_data.rom":      "table_data_symbols_reference.txt",
}
# images that are LZSS/deflate payloads or interleaved halves: a match is not
# expected and their absence is not evidence about the machine.
def _role(name, size):
    if name.endswith(".unidasm"):
        return "TEXT LISTING (not an image)"
    if "_compressed" in name or name.startswith("demo_preset") or name.startswith("help_db"):
        return "compressed payload"
    if name.endswith("_even.ic3") or name.endswith("_odd.ic1"):
        return "interleaved half"
    if name in KN_BASES:
        return "code/data image"
    return "image"


NUM = re.compile(r'0x[0-9a-fA-F]+|\b\d+\b')


def shape(text):
    """The instruction with every numeric literal wildcarded.  `ld (0xbf),WA` and
    `ld (0x0487),WA` are the same shape; `ld XSP,#` and `ld XIX,#` are not."""
    return NUM.sub('#', text)


# --------------------------------------------------------------------------
# the routine table, taken from prom_c_kernel_map.py rather than re-derived
# --------------------------------------------------------------------------
def load_routines():
    """[(name, prom_c addr, prom_a addr, length)] for the 36 pairs, plus the constants.

    ⚠ prom_c_kernel_map.py calls sys.exit() at import time, so this reads its AST
    instead of importing it.  The tiling is then re-asserted here: a boundary that
    moves there and not here would be exactly the desynchronising guess this project
    has already paid for."""
    tree = ast.parse(open(KERNEL_MAP).read())
    got = {}
    for node in tree.body:
        if isinstance(node, ast.Assign) and len(node.targets) == 1 \
           and isinstance(node.targets[0], ast.Name):
            name = node.targets[0].id
            if name in ("PAIRS", "INTT3_PAIR", "BLOCK_DELTA", "BLOCK_END_C"):
                got[name] = ast.literal_eval(node.value)
    for k in ("PAIRS", "INTT3_PAIR", "BLOCK_DELTA", "BLOCK_END_C"):
        if k not in got:
            raise SystemExit("FAIL: %s not found in %s" % (k, KERNEL_MAP))
    pairs, intt3 = got["PAIRS"], got["INTT3_PAIR"]
    delta, end_c = got["BLOCK_DELTA"], got["BLOCK_END_C"]
    # re-assert the tiling, INCLUDING the last row against the published block end
    for i, (ca, aa, n, name, _x) in enumerate(pairs):
        nxt = pairs[i + 1][0] if i + 1 < len(pairs) else end_c
        if ca + n != nxt:
            raise SystemExit("FAIL: %s does not end where the next row begins" % name)
        if ca - aa != delta:
            raise SystemExit("FAIL: %s is offset by 0x%X, not 0x%X" % (name, ca - aa, delta))
    rows = [(name, ca, aa, n) for ca, aa, n, name, _x in pairs]
    ca, aa, n, name, _x = intt3
    if ca - aa != delta:
        raise SystemExit("FAIL: INTT3 row offset is 0x%X" % (ca - aa))
    rows.append((name, ca, aa, n))
    rows.sort(key=lambda r: r[1])
    return rows, delta, end_c


def rom(path):
    return open(path, "rb").read()


def wsa1(which):
    f = {"a": "wsa1_prom_a.ic12", "b": "wsa1_prom_b.ic13",
         "c": "wsa1_prom_c.ic28", "d": "wsa1_prom_d.bin"}[which]
    return os.path.join(ROOT, "original_ROMs", f)


# --------------------------------------------------------------------------
# decoding
# --------------------------------------------------------------------------
def decode_bytes(blob, base):
    """[(addr, bytes, text)] for a blob decoded linearly from `base`."""
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(blob)
        tmp = f.name
    try:
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(base)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    return parse_unidasm(out)


def decode_file(path, base, phase):
    """One phase of a whole-image decode.  -skip N drops N bytes but leaves basepc
    alone, so basepc is advanced by the same N to keep addresses true."""
    out = subprocess.run([UNIDASM, path, "-arch", "tlcs900",
                          "-basepc", hex(base + phase), "-skip", str(phase)],
                         capture_output=True, text=True).stdout
    return parse_unidasm(out)


def parse_unidasm(out):
    rows = []
    for ln in out.splitlines():
        m = re.match(r'^\s*([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$', ln)
        if m:
            rows.append((int(m.group(1), 16),
                         bytes.fromhex(m.group(2).replace(" ", "")),
                         m.group(3).strip()))
    return rows


# --------------------------------------------------------------------------
# the corpus
# --------------------------------------------------------------------------
def kn_images():
    """Every FILE in the KN5000 original_ROMs directory, classified.  v1 filtered on
    size > 4096 and so counted three *.unidasm text listings as images; they are kept
    in the inventory here but flagged and not searched."""
    out = []
    for f in sorted(os.listdir(KN_ROMS)):
        p = os.path.join(KN_ROMS, f)
        if not os.path.isfile(p):
            continue
        size = os.path.getsize(p)
        out.append((f, p, size, _role(f, size), KN_BASES.get(f)))
    return out


def addr_from_off(fname, off):
    """File offset -> load address, honouring the spliced sub-CPU payload."""
    if fname in SPLICED:
        return (0x400 + off) if off < SPLICE_FILE_CUT else (SPLICE_ADDR_HI + off)
    b = KN_BASES.get(fname)
    return None if b is None else b + off


def kn_symbols(fname):
    sf = KN_SYMFILE.get(fname)
    if not sf:
        return []
    p = os.path.join(KN_SYMS, sf)
    if not os.path.exists(p):
        return []
    syms = []
    for ln in open(p):
        ln = ln.strip()
        if not ln or ln.startswith("#"):
            continue
        parts = ln.split()
        if len(parts) == 2:
            try:
                syms.append((int(parts[1], 16), parts[0]))
            except ValueError:
                pass
    syms.sort()
    return syms


def sym_at(syms, addr):
    """The label whose address is the greatest <= addr, i.e. the routine the hit is in."""
    if not syms:
        return ""
    lo, hi = 0, len(syms)
    while lo < hi:
        mid = (lo + hi) // 2
        if syms[mid][0] <= addr:
            lo = mid + 1
        else:
            hi = mid
    if lo == 0:
        return ""
    a, n = syms[lo - 1]
    return "%s+0x%X" % (n, addr - a) if addr != a else n


# --------------------------------------------------------------------------
# T2 -- longest byte-identical window, one pass per image
# --------------------------------------------------------------------------
def byte_scan(seqs, data):
    """seqs: [(key, bytes)].  Returns {key: (best run length, offset in data)}.
    One pass: the anchors come from the (small) sequences, the (large) image is
    streamed once."""
    anchors = {}
    for key, b in seqs:
        for i in range(len(b) - BYTE_ANCHOR + 1):
            anchors.setdefault(b[i:i + BYTE_ANCHOR], []).append((key, i))
    best = {}
    n = len(data)
    for j in range(n - BYTE_ANCHOR + 1):
        g = data[j:j + BYTE_ANCHOR]
        hits = anchors.get(g)
        if not hits:
            continue
        for key, i in hits:
            b = seq_by_key[key]
            l = 0
            while i - l - 1 >= 0 and j - l - 1 >= 0 and b[i - l - 1] == data[j - l - 1]:
                l += 1
            r = 0
            while i + BYTE_ANCHOR + r < len(b) and j + BYTE_ANCHOR + r < n \
                    and b[i + BYTE_ANCHOR + r] == data[j + BYTE_ANCHOR + r]:
                r += 1
            run = l + BYTE_ANCHOR + r
            if run > best.get(key, (0, 0))[0]:
                best[key] = (run, j - l)
    return best


seq_by_key = {}


# --------------------------------------------------------------------------
# T3 -- longest identical SHAPE run, one pass per image phase
# --------------------------------------------------------------------------
class ShapeCoder:
    """Maps an instruction shape to one character so a stream becomes a string and
    the search becomes str slicing."""

    def __init__(self):
        self.tok = {}

    def enc(self, shapes):
        out = []
        for s in shapes:
            c = self.tok.get(s)
            if c is None:
                i = len(self.tok)
                cp = 0x100 + i
                if 0xD800 <= cp <= 0xDFFF:
                    cp += 0x800
                c = chr(cp)
                self.tok[s] = c
            out.append(c)
        return "".join(out)


def shape_scan(seqs, stream):
    """seqs: [(key, encoded string)].  stream: encoded string of the image phase.
    Returns {key: (best run in instructions, index into the stream)}."""
    anchors = {}
    for key, s in seqs:
        for i in range(len(s) - SHAPE_ANCHOR + 1):
            anchors.setdefault(s[i:i + SHAPE_ANCHOR], []).append((key, i))
    best = {}
    n = len(stream)
    for j in range(n - SHAPE_ANCHOR + 1):
        hits = anchors.get(stream[j:j + SHAPE_ANCHOR])
        if not hits:
            continue
        for key, i in hits:
            s = shape_by_key[key]
            l = 0
            while i - l - 1 >= 0 and j - l - 1 >= 0 and s[i - l - 1] == stream[j - l - 1]:
                l += 1
            r = 0
            while i + SHAPE_ANCHOR + r < len(s) and j + SHAPE_ANCHOR + r < n \
                    and s[i + SHAPE_ANCHOR + r] == stream[j + SHAPE_ANCHOR + r]:
                r += 1
            run = l + SHAPE_ANCHOR + r
            if run > best.get(key, (0, 0, 0))[0]:
                # (run, where the run starts in the stream, where it starts in the
                # routine).  The third element is what lets the caller line the
                # routine's FIRST instruction up with the image instead of reporting
                # the middle of the run as if it were the entry point.
                best[key] = (run, j - l, i - l)
    return best


shape_by_key = {}


# --------------------------------------------------------------------------
# T4 -- the instruction-level alignment at a hit
# --------------------------------------------------------------------------
def align(rows_c, rows_k):
    """difflib alignment of two decoded runs on SHAPE, then a four-way count.
    Generalises notes/prom_c_prom_a_routine_diff.py's positional pairing, which
    desynchronises the moment one side has an extra instruction -- and the KN5000
    does have extra instructions."""
    import difflib
    sc = [shape(t) for _, _, t in rows_c]
    sk = [shape(t) for _, _, t in rows_k]
    sm = difflib.SequenceMatcher(a=sc, b=sk, autojunk=False)
    same = operand = ins = dele = 0
    rowsout = []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            for k in range(i2 - i1):
                c, kk = rows_c[i1 + k], rows_k[j1 + k]
                if c[2] == kk[2]:
                    same += 1
                    rowsout.append(("IDENTICAL", c, kk))
                else:
                    operand += 1
                    rowsout.append(("OPERAND", c, kk))
        elif tag == "replace":
            for k in range(max(i2 - i1, j2 - j1)):
                c = rows_c[i1 + k] if i1 + k < i2 else None
                kk = rows_k[j1 + k] if j1 + k < j2 else None
                if c is not None and kk is not None:
                    rowsout.append(("MNEMONIC", c, kk))
                elif c is not None:
                    dele += 1
                    rowsout.append(("ONLY-WSA1", c, None))
                else:
                    ins += 1
                    rowsout.append(("ONLY-KN5000", None, kk))
        elif tag == "delete":
            dele += i2 - i1
            for k in range(i1, i2):
                rowsout.append(("ONLY-WSA1", rows_c[k], None))
        elif tag == "insert":
            ins += j2 - j1
            for k in range(j1, j2):
                rowsout.append(("ONLY-KN5000", None, rows_k[k]))
    mism = sum(1 for t, _, _ in rowsout if t == "MNEMONIC")
    return dict(same=same, operand=operand, mnemonic=mism, only_wsa1=dele,
                only_kn=ins, rows=rowsout)


def align_at(rows_c, rows, j_est):
    """align_trimmed() around an estimated entry index, widening the window until the
    routine's FIRST instruction finds a partner.  ⚠ The estimate is `run start in the
    image` minus `run start in the routine`, which is short by however many
    instructions the image has that the WSA1 does not -- for Kernel_InitRam that is 2
    and the first attempt clipped six real pairs off the front.  Widening until slot 0
    is aligned is what stops the window choice from changing the counts."""
    res = None
    for lead in (8, 24, 56, 120):
        j0 = max(0, j_est - lead)
        j1 = min(len(rows), j_est + len(rows_c) + lead + 12)
        res = align_trimmed(rows_c, rows[j0:j1])
        if res["entry_exact"]:
            break
    return res


def align_trimmed(rows_c, rows_k):
    """align() with the KN5000 side's leading and trailing surplus dropped.  The
    window handed in is deliberately longer than the routine, so without this the
    slack would be counted as "extra KN5000 instructions"."""
    res = align(rows_c, rows_k)
    rws = res["rows"]
    while rws and rws[0][0] == "ONLY-KN5000":
        rws.pop(0)
    while rws and rws[-1][0] == "ONLY-KN5000":
        rws.pop()
    c = Counter(t for t, _a, _b in rws)
    # Where does the routine's FIRST instruction land?  The shape run alone cannot say
    # (it may start in the middle of the routine, and an instruction inserted before it
    # shifts the arithmetic), so the answer is taken from the alignment: the image row
    # that slot 0 was aligned to.  `entry_exact` is False when slot 0 has no partner and
    # the first aligned pair had to stand in for it.
    entry, exact = None, False
    for _t, cc, kk in rws:
        if cc is not None and kk is not None:
            if cc is rows_c[0]:
                entry, exact = kk[0], True
            else:
                entry = entry if entry is not None else kk[0]
            break
    return dict(same=c["IDENTICAL"], operand=c["OPERAND"], mnemonic=c["MNEMONIC"],
                only_wsa1=c["ONLY-WSA1"], only_kn=c["ONLY-KN5000"], rows=rws,
                entry=entry, entry_exact=exact)


# --------------------------------------------------------------------------
# the report
# --------------------------------------------------------------------------
def build_routines():
    rows, delta, end_c = load_routines()
    c = rom(wsa1("c"))
    out = []
    for name, ca, aa, n in rows:
        blob = c[ca - PROM_BASE: ca - PROM_BASE + n]
        dec = decode_bytes(blob, ca)
        out.append(dict(name=name, ca=ca, aa=aa, n=n, bytes=blob, dec=dec,
                        shapes=[shape(t) for _, _, t in dec]))
    return out, delta, end_c


def main(argv):
    phases = 2
    if "--phases" in argv:
        phases = int(argv[argv.index("--phases") + 1])
    routines, delta, end_c = build_routines()
    lo = min(r["ca"] for r in routines)
    total_b = sum(r["n"] for r in routines)
    total_i = sum(len(r["dec"]) for r in routines)
    print("WSA1 prom_c kernel, on notes/prom_c_kernel_map.py's PROVEN tiling extents")
    print("  %d routines, 0x%06X-0x%06X, %d bytes, %d instructions "
          "(prom_a = prom_c - 0x%X)" % (len(routines), lo, end_c, total_b, total_i, delta))
    nb = sum(1 for r in routines if r["n"] >= BYTE_EVIDENCE)
    ni = sum(1 for r in routines if len(r["dec"]) >= SHAPE_EVIDENCE)
    print("  long enough to be evidence:  %d of %d at >= %d bytes   "
          "(v1 managed 5 of 37)" % (nb, len(routines), BYTE_EVIDENCE))
    print("                               %d of %d at >= %d instructions"
          % (ni, len(routines), SHAPE_EVIDENCE))

    # nulls: same histogram, no structure
    rnd = random.Random(20260830)
    for r in routines:
        b = bytearray(r["bytes"])
        rnd.shuffle(b)
        r["null_bytes"] = bytes(b)
        s = list(r["shapes"])
        rnd.shuffle(s)
        r["null_shapes"] = s

    coder = ShapeCoder()
    for r in routines:
        r["enc"] = coder.enc(r["shapes"])
        r["null_enc"] = coder.enc(r["null_shapes"])

    global seq_by_key, shape_by_key
    seq_by_key = {}
    shape_by_key = {}
    byte_seqs, shape_seqs = [], []
    for i, r in enumerate(routines):
        seq_by_key[("R", i)] = r["bytes"]
        seq_by_key[("N", i)] = r["null_bytes"]
        byte_seqs.append((("R", i), r["bytes"]))
        byte_seqs.append((("N", i), r["null_bytes"]))
        shape_by_key[("R", i)] = r["enc"]
        shape_by_key[("N", i)] = r["null_enc"]
        shape_seqs.append((("R", i), r["enc"]))
        shape_seqs.append((("N", i), r["null_enc"]))

    inv = kn_images()
    searched = [(f, p, s, role, base) for f, p, s, role, base in inv
                if role != "TEXT LISTING (not an image)"]
    listings = len(inv) - len(searched)
    print()
    print("KN5000 corpus: %d files in %s" % (len(inv), KN_ROMS))
    print("  %d binary images searched; %d *.unidasm TEXT LISTINGS excluded "
          "(v1 counted them)" % (len(searched), listings))
    print("  decode phases per image: %d" % phases)

    # the two WSA1 controls travel with the corpus
    targets = [("wsa1_prom_a.ic12 [POSITIVE CONTROL]", wsa1("a"), 0x80000,
                "WSA1 CPU1 high -- the KNOWN sibling", PROM_BASE),
               ("wsa1_prom_b.ic13 [in-corpus control]", wsa1("b"), 0x80000,
                "WSA1 CPU1 low -- has no kernel", 0xF00000)] + searched

    print()
    print("%-42s %5s %6s %6s %6s %6s" %
          ("image", "T1", "T2 max", "null", "T3 max", "null"))
    print("%-42s %5s %6s %6s %6s %6s" %
          ("", "hits", "bytes", "bytes", "instr", "instr"))
    results = []
    for fname, path, size, role, base in targets:
        data = rom(path)
        bb = byte_scan(byte_seqs, data)
        t1 = sum(1 for i, r in enumerate(routines)
                 if bb.get(("R", i), (0, 0))[0] >= r["n"])
        t2 = max([bb.get(("R", i), (0, 0))[0] for i in range(len(routines))] + [0])
        t2n = max([bb.get(("N", i), (0, 0))[0] for i in range(len(routines))] + [0])
        # T3 over the phases
        best3 = {}
        stream_rows = {}
        if role in ("interleaved half",):
            t3 = t3n = -1          # not linearly decodable; do not pretend to decode it
        else:
            for ph in range(phases):
                rowsk = decode_file(path, base if base is not None else 0, ph)
                st = coder.enc([shape(t) for _, _, t in rowsk])
                got = shape_scan(shape_seqs, st)
                for k, (run, idx, slot) in got.items():
                    if run > best3.get(k, (0, 0, 0, 0))[0]:
                        best3[k] = (run, idx, slot, ph)
                stream_rows[ph] = rowsk
            t3 = max([best3.get(("R", i), (0,))[0] for i in range(len(routines))] + [0])
            t3n = max([best3.get(("N", i), (0,))[0] for i in range(len(routines))] + [0])

        def fmt(v):
            # 0 does not mean "nothing matched", it means "nothing matched for as
            # long as the anchor", so it is printed as the bound it really is.
            return "n/a" if v < 0 else ("<%d" % SHAPE_ANCHOR if v == 0 else str(v))
        print("%-42s %5d %6d %6d %6s %6s"
              % (fname[:42], t1, t2, t2n, fmt(t3), fmt(t3n)))
        results.append((fname, path, base, role, bb, best3, stream_rows))
    print()
    print("  T1 = routines found byte-identical over their WHOLE extent")
    print("  T2 = longest byte-identical window of ANY routine, and of the shuffled null")
    print("  T3 = longest identical instruction-SHAPE run, and of the shuffled null")

    # ---- the per-routine detail for every image that beat the evidence bar ----
    print()
    print("=" * 78)
    for fname, path, base, role, bb, best3, stream_rows in results:
        hits = [(i, best3[("R", i)]) for i in range(len(routines))
                if best3.get(("R", i), (0,))[0] >= SHAPE_ANCHOR]
        t1rows = [(i, bb[("R", i)]) for i in range(len(routines))
                  if bb.get(("R", i), (0, 0))[0] >= routines[i]["n"]]
        if not hits and not t1rows:
            continue
        syms = kn_symbols(os.path.basename(path))
        print()
        print("%s" % fname)
        if t1rows:
            print("  T1 -- byte-identical over the WHOLE routine:")
            for i, (run, off) in t1rows:
                a = addr_from_off(os.path.basename(path), off)
                if a is None:
                    a = (base or 0) + off
                print("      %-34s %3d B  at 0x%06X  %s"
                      % (routines[i]["name"], routines[i]["n"], a, sym_at(syms, a)))
        if not hits:
            continue
        strong = [h for h in hits if h[1][0] >= SHAPE_EVIDENCE]
        print("  T3/T4 -- %d of %d routines with a shape run >= %d instructions (the anchor),"
              % (len(hits), len(routines), SHAPE_ANCHOR))
        print("           of which %d reach the >= %d bar and are marked *."
              % (len(strong), SHAPE_EVIDENCE))
        print("     `at` is the routine's ENTRY, taken from the T4 alignment (a leading ~")
        print("     means slot 0 had no partner and the first aligned pair stood in).")
        print("     The five counts are T4 over the whole aligned extent, not the run --")
        print("     ⚠ the run UNDERSTATES the correspondence: SoftTimer_Register runs only")
        print("     11 but aligns 18 identical + 2 operand + 0 different out of 20.")
        print("  %-32s %5s %4s %-10s %-26s %5s %5s %5s %4s %4s"
              % ("WSA1 prom_c routine", "instr", "run", "at", "KN5000 label",
                 "ident", "oper", "diff", "+KN", "-WSA"))
        for i, (run, idx, slot, ph) in sorted(hits, key=lambda h: -h[1][0]):
            r = routines[i]
            rows = stream_rows[ph]
            res = align_at(r["dec"], rows, max(0, idx - slot))
            addr = res["entry"] if res["entry"] is not None else rows[idx][0]
            print("%s %-32s %5d %4d %s0x%06X %-26s %5d %5d %5d %4d %4d"
                  % ("*" if run >= SHAPE_EVIDENCE else " ",
                     r["name"], len(r["dec"]), run,
                     " " if res["entry_exact"] else "~", addr, sym_at(syms, addr)[:26],
                     res["same"], res["operand"], res["mnemonic"],
                     res["only_kn"], res["only_wsa1"]))
        missing = [routines[i]["name"] for i in range(len(routines))
                   if best3.get(("R", i), (0,))[0] < SHAPE_ANCHOR]
        # ⚠ Most of the "missing" are shims of 1-3 instructions that the anchor cannot
        # reach by construction, so the honest denominator is the TESTABLE routines.
        testable = [i for i in range(len(routines)) if len(routines[i]["dec"]) >= SHAPE_ANCHOR]
        tmiss = [routines[i]["name"] for i in testable
                 if best3.get(("R", i), (0,))[0] < SHAPE_ANCHOR]
        print("  no run of even %d instructions (%d of %d): %s"
              % (SHAPE_ANCHOR, len(missing), len(routines), ", ".join(missing)))
        print("  ★ of the %d routines LONG ENOUGH to test (>= %d instructions), %d have a"
              % (len(testable), SHAPE_ANCHOR, len(testable) - len(tmiss)))
        print("    counterpart here and %d do not: %s"
              % (len(tmiss), ", ".join(tmiss) or "none"))
    return 0


def do_align(argv):
    """--align <image> <routine>: the T4 table for one routine's best hit."""
    which = argv[argv.index("--align") + 1]
    rname = argv[argv.index("--align") + 2]
    phases = 2
    if "--phases" in argv:
        phases = int(argv[argv.index("--phases") + 1])
    routines, delta, end_c = build_routines()
    r = next((x for x in routines if x["name"] == rname), None)
    if r is None:
        raise SystemExit("FAIL: no routine %r; have %s"
                         % (rname, ", ".join(x["name"] for x in routines)))
    path = os.path.join(KN_ROMS, which)
    if not os.path.exists(path):
        path = wsa1({"wsa1_prom_a.ic12": "a", "wsa1_prom_b.ic13": "b"}.get(which, "a"))
    base = KN_BASES.get(which, PROM_BASE if "prom_a" in which else 0)
    coder = ShapeCoder()
    global shape_by_key
    shape_by_key = {("R", 0): coder.enc(r["shapes"])}
    seqs = [(("R", 0), shape_by_key[("R", 0)])]
    best = (0, 0, 0, None)
    for ph in range(phases):
        rows = decode_file(path, base, ph)
        st = coder.enc([shape(t) for _, _, t in rows])
        got = shape_scan(seqs, st)
        if ("R", 0) in got and got[("R", 0)][0] > best[0]:
            best = (got[("R", 0)][0], got[("R", 0)][1] - got[("R", 0)][2], ph, rows)
    run, idx, ph, rows = best
    if not run:
        print("no shape run found for %s in %s" % (rname, which))
        return 1
    # take the KN5000 side generously: the run, plus the routine's own length
    res = align_at(r["dec"], rows, idx)
    syms = kn_symbols(which)
    print("%s  (WSA1 prom_c 0x%06X, %d bytes, %d instructions)"
          % (rname, r["ca"], r["n"], len(r["dec"])))
    print("vs %s @ 0x%06X  %s   [phase %d, longest shape run %d instructions]"
          % (which, res["entry"], sym_at(syms, res["entry"]), ph, run))
    print("  identical text                    %4d" % res["same"])
    print("  same shape, different literal     %4d" % res["operand"])
    print("  DIFFERENT instruction             %4d" % res["mnemonic"])
    print("  only in WSA1                      %4d" % res["only_wsa1"])
    print("  only in KN5000                    %4d" % res["only_kn"])
    print()
    for tag, c, k in res["rows"]:
        cs = "%06X %-30s" % (c[0], c[2]) if c else " " * 37
        ks = "%06X %-30s" % (k[0], k[2]) if k else ""
        print("  %-12s %s | %s" % (tag, cs, ks))
    return 0


def scan_image(routines, coder, fname, phases=2):
    """Best shape hit + T4 alignment for every routine against one image."""
    path = os.path.join(KN_ROMS, fname) if os.path.exists(os.path.join(KN_ROMS, fname)) \
        else fname
    base = KN_BASES.get(fname, 0)
    global shape_by_key
    shape_by_key = {}
    seqs = []
    for i, r in enumerate(routines):
        shape_by_key[("R", i)] = coder.enc(r["shapes"])
        seqs.append((("R", i), shape_by_key[("R", i)]))
    best, rowsby = {}, {}
    for ph in range(phases):
        rows = decode_file(path, base, ph)
        st = coder.enc([shape(t) for _, _, t in rows])
        for k, (run, idx, slot) in shape_scan(seqs, st).items():
            if run > best.get(k, (0,))[0]:
                best[k] = (run, idx, slot, ph)
        rowsby[ph] = rows
    syms = kn_symbols(fname)
    out = {}
    for i, r in enumerate(routines):
        if ("R", i) not in best:
            continue
        run, idx, slot, ph = best[("R", i)]
        res = align_at(r["dec"], rowsby[ph], max(0, idx - slot))
        addr = res["entry"] if res["entry"] is not None else rowsby[ph][idx][0]
        out[r["name"]] = dict(run=run, addr=addr, label=sym_at(syms, addr), **res)
    return out


def do_correspondence(argv):
    """--correspondence: the WSA1 kernel routine, the KN5000 MAINCPU label and the
    KN5000 SUB-CPU label side by side, each with its own identical/total count.

    ★ The two trees named these independently, so the column of KN5000 names is not an
    input to this measurement -- it is a check ON it.  Where the three disagree, the
    disagreement is printed rather than resolved: this lane is read-only."""
    phases = 2
    if "--phases" in argv:
        phases = int(argv[argv.index("--phases") + 1])
    routines, delta, end_c = build_routines()
    coder = ShapeCoder()
    mc = scan_image(routines, coder, "kn5000_v7_program.rom", phases)
    sc = scan_image(routines, coder, "kn5000_subprogram_v142.rom", phases)
    print("WSA1 prom_c kernel routine -> the KN5000's own labels for the same code")
    print("  ident/instr = instructions whose unidasm TEXT is identical, over the "
          "routine's length")
    print()
    print("  %-32s %5s  %-30s %-8s %-30s %-8s"
          % ("WSA1 prom_c (and prom_a)", "instr",
             "KN5000 maincpu v7", "id/instr", "KN5000 sub-CPU v142", "id/instr"))
    hit = 0
    for r in routines:
        a, b = mc.get(r["name"]), sc.get(r["name"])
        if not a and not b:
            continue
        hit += 1
        n = len(r["dec"])
        print("  %-32s %5d  %-30s %-8s %-30s %-8s"
              % (r["name"], n,
                 (a["label"] or "0x%06X" % a["addr"])[:30] if a else "-",
                 ("%d/%d" % (a["same"], n)) if a else "-",
                 (b["label"] or "0x%06X" % b["addr"])[:30] if b else "-",
                 ("%d/%d" % (b["same"], n)) if b else "-"))
    print()
    print("  %d of %d routines have a counterpart in at least one KN5000 image."
          % (hit, len(routines)))
    print("  ⚠ A label is the KN5000 tree's, at the address the alignment lands on; where")
    print("    it carries a +0xNN the alignment did not land on that label's first byte.")
    return 0


# --------------------------------------------------------------------------
def selftest():
    ok = fail = 0

    def check(desc, cond, extra=""):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc + (("   " + extra) if extra else ""))
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    routines, delta, end_c = load_routines()
    check("the routine table loads from prom_c_kernel_map.py and TILES",
          len(routines) == 36, "%d routines" % len(routines))
    check("...and its LAST row ends at the published block end 0x%06X" % end_c,
          max(ca + n for _n, ca, _a, n in routines) == end_c)
    c = rom(wsa1("c"))
    check("WSA1 prom_c is 512 KiB", len(c) == 0x80000)

    inv = kn_images()
    listings = [f for f, _p, _s, role, _b in inv if role.startswith("TEXT")]
    check("the corpus separates TEXT LISTINGS from images",
          len(listings) == 4, "%d listings: %s" % (len(listings), ", ".join(listings)))
    bins = [(f, p) for f, p, _s, role, _b in inv if not role.startswith("TEXT")]
    check("KN5000 binary images are readable", len(bins) > 30, "%d" % len(bins))
    blobs = {f: rom(p) for f, p in bins}

    # the spliced sub-CPU map, checked against content the KN5000 tree describes on its
    # own terms: v142/subcpu/subcpu_data_tables.s calls 0x0114DE DSP_ChanFreq_IndexMap,
    # "Identity through 0x15, then bowing up to 0x7F".  Under the map it IS that ramp;
    # under a flat 0x400 reading it is not, which is what makes this check able to fail.
    sp = blobs["kn5000_subprogram_v142.rom"]
    off = next(o for o in range(len(sp))
               if addr_from_off("kn5000_subprogram_v142.rom", o) == 0x0114DE)
    check("the SPLICED sub-CPU map puts DSP_ChanFreq_IndexMap's identity ramp at 0x0114DE",
          sp[off:off + 8] == bytes(range(8)), "file 0x%05X = %s" % (off, sp[off:off + 8].hex(" ")))
    check("...and a FLAT base-0x400 reading of the same address does NOT",
          sp[0x0114DE - 0x400:0x0114DE - 0x400 + 8] != bytes(range(8)))

    # T1/T2 controls
    import hashlib
    probe = hashlib.sha256(b"negative-control").digest()[:32]
    check("NEGATIVE: a synthetic 32-byte run is in NO KN5000 image",
          not any(probe in b for b in blobs.values()))
    shared = c[0xFDE32B - PROM_BASE:0xFDE32B - PROM_BASE + 64]
    where = [f for f, b in blobs.items() if shared in b]
    check("POSITIVE: the known shared run at 0xFDE32B IS in a KN5000 image",
          bool(where), ", ".join(where[:3]))

    # T3 control: prom_a must give a FULL-LENGTH shape run for every routine.
    # This is the check that says the structural instrument can see what it claims.
    coder = ShapeCoder()
    global shape_by_key
    shape_by_key = {}
    seqs = []
    full = []
    decs = {}
    for i, (name, ca, aa, n) in enumerate(routines):
        blob = c[ca - PROM_BASE:ca - PROM_BASE + n]
        dec = decode_bytes(blob, ca)
        decs[i] = (name, dec)
        e = coder.enc([shape(t) for _, _, t in dec])
        shape_by_key[("R", i)] = e
        seqs.append((("R", i), e))
    rows_a = decode_file(wsa1("a"), PROM_BASE, 0)
    st = coder.enc([shape(t) for _, _, t in rows_a])
    got = shape_scan(seqs, st)
    for i, (name, dec) in decs.items():
        run = got.get(("R", i), (0,))[0]
        if len(dec) >= SHAPE_ANCHOR:
            full.append((name, run, len(dec)))
    bad = [(n, r, l) for n, r, l in full if r < l]
    check("POSITIVE: every long-enough routine has a FULL-LENGTH shape run in prom_a",
          [n for n, _r, _l in bad] == ["Kernel_InitRam"],
          "%d of %d full; the one exception is %s"
          % (len(full) - len(bad), len(full),
             ", ".join("%s %d/%d" % b for b in bad) or "none"))
    # ⚠ Kernel_InitRam is the documented exception in BOTH sibling scripts: it carries
    # an 8-byte inline data block (SoftTimer_Request_Boot) that a linear decoder frames
    # differently on each side.  Pinning 26 of 26 would be pinning a wrong expectation.
    check("...and that exception reaches 82 of its 86 instructions",
          bool(bad) and bad[0][1] == 82 and bad[0][2] == 86, str(bad[0] if bad else None))
    # ... and the runs land at the addresses prom_c_kernel_map.py says they should.
    # The LAST row of the table is checked as well as the first: that is the element
    # this tree has got wrong before.
    fullnames = [n for n, r, l in full if r == l]
    i0 = next(i for i in sorted(decs) if decs[i][0] == fullnames[0])
    idx0 = got[("R", i0)][1]
    check("...the FIRST full routine (%s) lands at prom_a 0x%06X"
          % (decs[i0][0], routines[i0][2]),
          rows_a[idx0][0] == routines[i0][2], "got 0x%06X" % rows_a[idx0][0])
    iL = next(i for i in sorted(decs, reverse=True) if decs[i][0] == fullnames[-1])
    idxL = got[("R", iL)][1]
    check("...and so does the LAST (%s), at prom_a 0x%06X" % (decs[iL][0], routines[iL][2]),
          rows_a[idxL][0] == routines[iL][2], "got 0x%06X" % rows_a[idxL][0])

    # the phases agree: the two boundaries known independently are found by all of them
    agree = []
    for ph in range(4):
        ra = decode_file(wsa1("a"), PROM_BASE, ph)
        agree.append(any(a == routines[0][2] for a, _b, _t in ra))
    check("all 4 decode phases resynchronise onto prom_a's kernel boundary",
          all(agree), "%s" % agree)

    # the regression anchor: the hit v1 could not see
    v7 = os.path.join(KN_ROMS, "kn5000_v7_program.rom")
    rows7 = decode_file(v7, 0xE00000, 0)
    st7 = coder.enc([shape(t) for _, _, t in rows7])
    ir = next(i for i in decs if decs[i][0] == "Kernel_InitRam")
    got7 = shape_scan([(("R", ir), shape_by_key[("R", ir)])], st7)
    run7, idx7, slot7 = got7.get(("R", ir), (0, 0, 0))
    idx7 = max(0, idx7 - slot7)
    check("REGRESSION: Kernel_InitRam's shape run in kn5000_v7_program.rom is >= %d"
          % SHAPE_EVIDENCE, run7 >= SHAPE_EVIDENCE, "%d instructions" % run7)
    res7 = align_at(decs[ir][1], rows7, idx7)
    lbl7 = sym_at(kn_symbols("kn5000_v7_program.rom"), res7["entry"])
    check("...and it lands inside the KN5000's OWN TaskSched_* block",
          lbl7.startswith("TaskSched_"), "entry 0x%06X = %s" % (res7["entry"], lbl7))

    # ⚠ THE INDEPENDENCE CLAIM, checked rather than asserted.  The report says the two
    # trees named these routines independently.  That is only true if no KN5000 scheduler
    # name was ever transplanted into the WSA1 sources -- and a transplant DOES exist
    # (scripts/analysis/transplant_kn5000_labels.py, 15 names applied to prom_c).  Every
    # one of those is a DATA TABLE; if a TaskSched_/TaskMsgQ_/TaskTimer_ name ever appears
    # on this side, the agreement stops being evidence and this check must fail.
    import glob
    borrowed = []
    for f in glob.glob(os.path.join(ROOT, "prom_*", "*.s")):
        txt = open(f, errors="replace").read()
        for tag in ("TaskSched_", "TaskMsgQ_", "TaskTimer_", "TaskMsg_", "TaskQueue_"):
            if tag in txt:
                borrowed.append((os.path.basename(f), tag))
    check("the WSA1 sources contain NO KN5000 scheduler name -- so the naming agreement "
          "is independent", not borrowed, str(borrowed[:4]))

    # the LAST row of the pair table, measured against the KN5000 as well as prom_a
    lastname = routines[-1][0]
    coder2 = ShapeCoder()
    rs = [dict(name=n, ca=ca, aa=aa, n=nn,
               dec=decode_bytes(c[ca - PROM_BASE:ca - PROM_BASE + nn], ca))
          for n, ca, aa, nn in routines if n == lastname]
    rs[0]["shapes"] = [shape(t) for _, _, t in rs[0]["dec"]]
    got2 = scan_image(rs, coder2, "kn5000_v7_program.rom", 1)
    r2 = got2.get(lastname)
    check("the LAST row of the table (%s) also aligns in kn5000_v7_program.rom" % lastname,
          bool(r2) and r2["same"] >= 15,
          "" if not r2 else "%d/%d identical at 0x%06X %s"
          % (r2["same"], len(rs[0]["dec"]), r2["addr"], r2["label"]))

    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    if "--align" in sys.argv:
        sys.exit(do_align(sys.argv))
    if "--correspondence" in sys.argv:
        sys.exit(do_correspondence(sys.argv))
    sys.exit(main(sys.argv))
