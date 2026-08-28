#!/usr/bin/env python3
"""The code/data LAYOUT of prom_b 0xF067A6-0xF0C734 -- wave 7, lane B3.

WHAT THE SPAN IS.  Two things with a 2,856-byte `ret` moat between them.

  * 0xF067A6-0xF097FF is a DATA block: a 96 x 16 tone-GROUP NAME table, four
    16-byte translation tables, two word arrays of 8-word rows, a 128-entry
    pointer table over a 160-record 3-byte array, and a 994-word array.  Not one
    byte of it is reached by any code walk, and five of its objects are named by
    an `ld Xrr,imm32` in prom_a whose next instructions state the element size.
  * 0xF09800-0xF0C734 is a CODE block: handlers of the two 48-entry selector
    dispatch tables at prom_b 0xF5B8F8/0xF5B9F8 and of the two 300-odd-entry
    computed-call tables in prom_a at 0xFCF21B and 0xFCF80C, plus eight small
    in-block `jp (XBC)` tables.  Its first module (0xF09800-0xF09D69) is a
    display-list CLIENT: 36 call sites of the `ld XIY,start / ld XIX,end /
    call 0xF417F0` shape, all naming lists OUTSIDE the span (`--dl`).

THE ANSWER, IN ONE TABLE (`--python` for the literal, `--selftest` for 79 checks)
    fill    2,946      two 0x0E moats, 90 and 2,856 bytes
    ascii   1,536      96 x 16 tone-group names, PIANO .. R1 Combi Group16
    ptrtab    848      nine pointer tables
    data    7,835      eleven objects, ten of which have a located reader
    code   11,298      one 819-byte module and one 10,479-byte module
    ----   24,463      substantive 21,517
  ⚠ 379 of the 7,835 `data` bytes (0xF09E85-0xF09FFF) are almost certainly
  CODE and are deliberately NOT claimed; see ISLAND_READERS and
  `--null-accept-trim` for the measurement that refused to claim them.

  ⚠ The block is NOT named.  Its strings ("PIANO", "SYNTH PAD 3", "U1 Combi
  Group 1") are the tone-GROUP vocabulary and the prom_a readers index them by a
  byte at 0x60F010/0x60F011, but nothing decoded here says what screen owns it,
  so no `Tone*` name is proposed.  See open questions at the foot of this file.

QUESTION IT ANSWERS
  "Which bytes of 0xF067A6-0xF0C735 are instructions, which are tables, and WHY
   is each code byte code?"  Every byte is assigned; nothing is typed by hand.

WHAT IS DIFFERENT FROM notes/prom_b_f0ea9f_layout.py, WHICH THIS IMPORTS
  The barrier rules are UNCHANGED -- rounds 5 and 6 calibrated them and this
  span re-measures every null at zero.  TWO SEED CHANGES, both because the
  round-5 seed set gets this span demonstrably wrong:

  1. FARSITE (`far_calls_graded`).  `prom_b_f65000_layout.far_calls` accepts a
     `call`/`jp addr24` opcode at EVERY byte of both images -- an upper bound it
     documents.  On this span the bound is wrong in a way that matters: the
     target 0xF07CFC comes from byte 0xF23010, which is inside the PROVEN FONT
     data at 0xF1B400-0xF283A6, and seeding it makes the walk decode 1,080 bytes
     of the 4,096-byte word array at 0xF07134 as instructions.  A site is
     rejected when it lies in a CONVERTED region of prom_a/prom_b and is not a
     proven instruction start; sites inside `.incbin` are kept (nothing is known
     about them).  NULL: `--null-far`.
  2. EXTPTR (`extptr_tables`).  `table_entry_seeds` only frames pointer tables
     INSIDE [LO,HI).  Four of this span's five entry-point sources are OUTSIDE
     it, and one of them is not even 4-aligned: prom_a 0xFCF21B (377 entries,
     offset 3 mod 4, read by `add XBC,0x00fcf21b / ld XBC,(XBC) / lda XIY,ret /
     push XIY / jp (XBC)` at 0xFD277E) and prom_a 0xFCF80C (305 entries, the
     same shape at 0xFD0AD2) between them name 93 entry points in this span,
     including 0xF0C0BB -- a `link XIZ,0xfff0` routine prologue the round-5 seed
     set never reaches.  So pointer tables are scanned in BOTH images at ALL
     FOUR phases, over the two-image window 0x00F00000-0x01000000, and only
     those whose reader TRANSFERS (`consumer()`) contribute seeds.
     NULL: `--null-extptr` -- of the 3,963 entries of ALL such tables that land
     in ALREADY-CONVERTED prom_a/prom_b, 3,907 are proven instruction starts and
     56 (1.41%) are not.  45 of the 56 are objects this tree has ALREADY
     documented (32 from the four screen arrays at 0xF131E4 whose entries 64..95
     are display-list data; 13 naming 0xF5BF17, the documented bare-`ret`
     default arm, which the `.s` emits with no instruction line).  NONE of them
     is in a table that seeds this span.

THE NULLS, AND THE CORPORA THEY USE
  --null-ptr     content rules vs PROVEN INSTRUCTION TEXT of prom_b (must be 0)
  --null-far     the FARSITE filter vs every opcode-anchored site in CONVERTED
                 code -- reports the unfiltered rule's false-positive rate
  --null-extptr  EXTPTR vs PROVEN INSTRUCTION STARTS -- 56 of 3,963 (1.41%)
  --null-retaddr RETADDR vs PROVEN INSTRUCTION STARTS -- 394 of 396 agree, and
                 the 2 that disagree are places where the CURRENT .s emits a
                 real instruction as `.byte` (0xF10E0F, 0xF1173A): the rule is
                 right and the oracle is not.  ★ two conversion leads.
  --null-accept  accept() vs the 39,329 bytes of PROVEN display-list DATA
                 (inherited from prom_b_f0ea9f_layout; 0.1% at 16 bytes)
  --null-accept-trim  a rule MEASURED AND REJECTED at 3.2-4.4%
  ⚠ The corpora derived from the `.s` GROW as rounds convert code.  Quote a
  false-positive count with the tree revision it was measured on.

RUN
  python3 notes/prom_b_f067a6_layout.py                  # the LAYOUT table
  python3 notes/prom_b_f067a6_layout.py --python         # paste-ready literal
  python3 notes/prom_b_f067a6_layout.py --segments       # the layout REFINED by readers
  python3 notes/prom_b_f067a6_layout.py --tables         # every pointer table
  python3 notes/prom_b_f067a6_layout.py --refs           # every 32-bit spelling
  python3 notes/prom_b_f067a6_layout.py --data           # the data block, object
                                                         # by object, with reader
  python3 notes/prom_b_f067a6_layout.py --provenance     # WHY each segment is code
  python3 notes/prom_b_f067a6_layout.py --seeds          # what each rule is WORTH
  python3 notes/prom_b_f067a6_layout.py --dl             # display lists in/near the span
  python3 notes/prom_b_f067a6_layout.py --retires        # what a conversion would retire
  python3 notes/prom_b_f067a6_layout.py --prove          # assemble every code segment
  python3 notes/prom_b_f067a6_layout.py --conflicts      # descent-vs-barrier (0)
  python3 notes/prom_b_f067a6_layout.py --residue        # unassigned runs, hex
  python3 notes/prom_b_f067a6_layout.py --null-ptr
  python3 notes/prom_b_f067a6_layout.py --null-far
  python3 notes/prom_b_f067a6_layout.py --null-extptr
  python3 notes/prom_b_f067a6_layout.py --null-retaddr
  python3 notes/prom_b_f067a6_layout.py --null-accept
  python3 notes/prom_b_f067a6_layout.py --null-accept-trim  # a rule MEASURED AND REJECTED
  python3 notes/prom_b_f067a6_layout.py --selftest       # 79 checks; the LAST
                                                         # segment/entry of every
                                                         # object is one of them
OPEN QUESTIONS (do not let a later round quietly close these by guessing)
  1. WHAT SCREEN OWNS THE DATA BLOCK.  The names are tone GROUPS and the readers
     live in prom_a 0xFC0D70-0xFC25A1, but nothing decoded here says which UI
     page selects them.  No `Tone*` name is proposed.
  2. THE 0xF08514 ROW GRID.  113 rows of 8 words tile 0xF08514-0xF08C23 exactly;
     the last 180 bytes repeat rows 100-110 on a grid offset by 4 bytes.  Either
     a second array shares the reader or the tail has its own base, and nothing
     in either image names one.  `--data` prints it.
  3. WHO READS 0xF08134.  The 128-entry pointer table's own base has NO 32-bit
     spelling anywhere in prom_a+prom_b (`--refs`), so the indexer must compute
     it; the table's extent is pinned from the other side instead (its last
     entry + 3 is 0xF08514, the next object's named base).
  4. 0xF09E85-0xF09FFF.  Almost certainly twelve routines; deliberately not
     claimed.  What it needs is a REFERENCE, not a better decoder.
  5. 0xF09FFC-0xF09FFF, `link XIZ,0x0000` with no body, immediately before a
     thunk target that begins `link XIZ,0xfffc`.  Not padding in any shape this
     tree has seen, not a legal prologue for the routine that follows it.

Exit status is non-zero if a --null, --conflicts or --selftest run finds
something it must not.
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_f0ea9f_layout as LY                                  # noqa: E402
import prom_b_f65000_layout as L                                   # noqa: E402
import prom_b_module_trace as MT                                   # noqa: E402
import trace_code as TC                                            # noqa: E402

LO, HI = 0xF067A6, 0xF0C735
LY.LO, LY.HI = LO, HI              # every LY function reads these at call time

BASES = {"a": 0xF80000, "b": 0xF00000}
IMGS = {"a": os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"),
        "b": os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")}

# the two-image code address space; wider than LY's prom_b-only PTR window
EXT_LO, EXT_HI = 0x00F00000, 0x01000000
EXT_MIN = 3                        # non-zero entries needed to call it a table

# The IN-SPAN pointer-table window is widened to the same two-image space.
# Round 5 used prom_b only (0x00F00000-0x00F7FFFF); this span holds an 8-entry
# table at 0xF09B7B whose entries are all prom_a addresses (0x00FC48D7 ...
# 0x00FC4B4D, stride 0x5A), which the narrow window cannot see.  NULL for the
# widened window, measured on the same corpus as the narrow one -- every
# maximal run of PROVEN prom_b instruction text, 5,433 runs / 107,345 bytes at
# the time of writing: ZERO false positives, the same as the narrow window.
# `--null-ptr` re-measures both and prints them side by side.
L.PTR_LO, L.PTR_HI = EXT_LO, EXT_HI

# RETADDR -- the computed-CALL idiom, and the reason the round-5 seed set loses
# the tail of every dispatched handler in this span:
#     lda XIY,0xf0a03d / push XIY / jp T,XBC
# is a CALL whose return address is pushed by hand.  `jp (Xrr)` is a flow end,
# so the walk stops there and 0xF0A03D -- which is `call 0xfd60b9 / pop BC /
# cp A,0 / ...`, the handler's own epilogue -- is never decoded.  Eight such
# runs (170 bytes) came out as `.byte` before this rule.  It is NOT the round-4
# "follow every 32-bit immediate" source, which round 5 measured at eight false
# positives out of eight and switched off: the three instructions must be
# CONSECUTIVE and the third must be a register control transfer, so the address
# is a return point by the architecture's own definition.
LDA_IMM_RE = re.compile(r"^lda\s+(X\w+)\s*,\s*0x([0-9a-f]{6})$")
PUSH_RE = re.compile(r"^push\s+(X\w+)$")

# ---------------------------------------------------------------------------
# the images, and a decoder for EITHER of them
# ---------------------------------------------------------------------------


def rom(img):
    return L.rom(img)


def w32(img, a):
    d = rom(img)
    return int.from_bytes(d[a - BASES[img]:a - BASES[img] + 4], "little")


_win = {}


def decode_at(img, addr, window=0x40):
    """(length, text) for the instruction AT addr in IMG, decoded FROM addr.

    prom_b goes through prom_b_module_trace.decode_at, which has the merged
    32-phase table behind it.  prom_a has no such table in this lane and does
    not need one: the only prom_a addresses this script decodes are the handful
    of table indexers, so a window of `window` bytes is disassembled once per
    site and cached."""
    if img == "b":
        return MT.decode_at(addr)
    key = (img, addr)
    if key in _win:
        return _win[key]
    d = rom(img)
    o = addr - BASES[img]
    if o < 0 or o >= len(d):
        _win[key] = None
        return None
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(d[o:o + window])
        tmp = f.name
    try:
        out = subprocess.run([TC.UNIDASM, tmp, "-arch", "tlcs900",
                              "-basepc", hex(addr)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    got = None
    for ln in out.splitlines():
        m = TC.LINE.match(ln)
        if m:
            a = int(m.group(1), 16)
            v = (len(m.group(2).split()), m.group(3).strip())
            if a == addr:
                got = v
            _win.setdefault((img, a), v)
    _win[key] = got
    return got


# ---------------------------------------------------------------------------
# what the .s already PROVES about an address
# ---------------------------------------------------------------------------
_starts, _incbin = {}, {}
LLVM_MARK = "[llvm-mc cannot encode this]"


def instr_starts(img):
    """Addresses at which prom_X/wsa1_prom_X.s emits an INSTRUCTION.

    Same parse as prom_b_f65000_layout.proven_code_runs -- an `; ADDR  ` comment
    on a line whose body is not a directive -- but it returns the SET of starts
    rather than runs, and it works for prom_a as well as prom_b.  The byte gate
    proves the file rebuilds the image, so these addresses are instruction
    boundaries beyond argument."""
    if img not in _starts:
        src = os.path.join(ROOT, "prom_%s" % img, "wsa1_prom_%s.s" % img)
        out = set()
        for ln in open(src):
            body = ln.split(";")[0]
            m = re.search(r";\s*([0-9A-F]{6})\s\s", ln)
            if not m or not body.startswith("\t"):
                continue
            if not body.lstrip().startswith("."):
                out.add(int(m.group(1), 16))
            elif LLVM_MARK in ln:
                # ⚠ prom_b emits 6,113 real instructions as `.byte` because
                # llvm-mc cannot encode them, and marks every one of them.
                # Excluding them -- which prom_b_f65000_layout.proven_code_runs
                # does, correctly, for ITS purpose of finding maximal runs --
                # made this script's EXTPTR null report 235 false positives that
                # are nothing of the kind: 0xF1071B, an entry of the proven
                # dispatch table at 0xF131E4, is `.byte 0xEE, 0x0C, 0xF8, 0xFF
                # ; F1071B  link XIZ,0xfff8` and could not be more obviously an
                # instruction start.
                out.add(int(m.group(1), 16))
        _starts[img] = out
    return _starts[img]


def incbin_ranges(img):
    """[lo,hi) of every `.incbin` in prom_X/wsa1_prom_X.s -- the UNCONVERTED set."""
    if img not in _incbin:
        src = os.path.join(ROOT, "prom_%s" % img, "wsa1_prom_%s.s" % img)
        r = []
        for m in re.finditer(
                r'\.incbin\s+"[^"]+",\s*(0x[0-9A-Fa-f]+),\s*(0x[0-9A-Fa-f]+)',
                open(src).read()):
            o, n = int(m.group(1), 16), int(m.group(2), 16)
            r.append((BASES[img] + o, BASES[img] + o + n))
        _incbin[img] = sorted(r)
    return _incbin[img]


def img_of(addr):
    if BASES["b"] <= addr < BASES["b"] + 0x80000:
        return "b"
    if BASES["a"] <= addr < BASES["a"] + 0x80000:
        return "a"
    return None


# The thunk table: 0xF40000-0xF44017, 4,102 four-byte slots, emitted as DATA in
# the `.s` (`T_F4xxxx` labels over `.byte`).  A slot is therefore CONVERTED and
# is not an instruction start -- yet it IS an entry point.  Census of the first
# byte of every 4-aligned slot: 1,976 are 0x1B (`jp addr24`), 2,085 are 0x0E
# (the `ret` default arm), 38 are 0x00 and 3 are something else, 0xF40000
# (`10 20 f8 00`) among them.  Grading the table as proven data would make the
# FARSITE census report 24 false positives it does not have and the EXTPTR null
# report 245 it does not have, so a 4-ALIGNED ADDRESS IN THE TABLE gets its own
# verdict.  See notes/FINDINGS-prom_b-thunk-table.md;
# prom_b_module_trace.thunk_entries reads exactly this range.
THUNK_LO, THUNK_HI = 0xF40000, 0xF44018


def site_status(addr):
    """'INSN' | 'THUNK' | 'CONVERTED' | 'UNCONVERTED' | 'OUTSIDE'.

    INSN        the .s emits an instruction starting exactly here
    THUNK       a 4-aligned `jp addr24` slot of the 0xF40000 thunk table
    CONVERTED   the .s emits SOMETHING here (data, or the middle of an
                instruction) and it is not an instruction start
    UNCONVERTED the byte is inside an `.incbin`; nothing is known about it
    """
    img = img_of(addr)
    if img is None:
        return "OUTSIDE"
    if (img == "b" and THUNK_LO <= addr < THUNK_HI
            and (addr - THUNK_LO) % 4 == 0):
        return "THUNK"
    for a, e in incbin_ranges(img):
        if a <= addr < e:
            return "UNCONVERTED"
    return "INSN" if addr in instr_starts(img) else "CONVERTED"


# ---------------------------------------------------------------------------
# RULE FARSITE -- the opcode-anchored call/jp scan, with its site graded
# ---------------------------------------------------------------------------


def far_call_sites(lo=LO, hi=HI):
    """[(site, target, status)] for every `call addr24`/`jp addr24` OPCODE BYTE
    in prom_a or prom_b whose 24-bit operand lands in [lo,hi).

    Opcodes 0x1D (`call`) and 0x1B (`jp`), scanned at every byte -- the same
    upper bound prom_b_f65000_layout.far_calls uses, but the SITE is kept so it
    can be graded."""
    out = []
    for img in ("b", "a"):
        blob, base = rom(img), BASES[img]
        for i in range(len(blob) - 3):
            if blob[i] in (0x1D, 0x1B):
                t = blob[i + 1] | blob[i + 2] << 8 | blob[i + 3] << 16
                if lo <= t < hi:
                    out.append((base + i, t, site_status(base + i)))
    return out


def far_calls_graded(lo=LO, hi=HI):
    """The FARSITE-filtered seed set: targets whose site is not proven DATA."""
    return set(t for _, t, st in far_call_sites(lo, hi) if st != "CONVERTED")


# ---------------------------------------------------------------------------
# RULE EXTPTR -- pointer tables anywhere in either image, all four phases
# ---------------------------------------------------------------------------
_chains = {}


def ptr_chains(img, minent=EXT_MIN):
    """Maximal stride-4 chains of words that are 0 or in [EXT_LO,EXT_HI), at
    every one of the four byte phases, with at least `minent` NON-ZERO entries.

    ZERO IS ALLOWED INSIDE a chain and never starts or ends one: prom_a's two
    computed-call tables have a 0x00000000 slot every 16th entry (an unused
    operation), and a rule that broke on it would frame 0xFCF80C as nineteen
    unrelated three-entry tables and lose the base an indexer names.

    ALL FOUR PHASES because prom_a 0xFCF21B is at offset 3 mod 4.  The extra
    phases are nearly free of noise by construction: a 4-aligned table read one
    byte over yields words whose top byte is the next entry's low byte, which is
    in [EXT_LO,EXT_HI) only when that byte is 0x00."""
    if (img, minent) in _chains:
        return _chains[(img, minent)]
    d, base = rom(img), BASES[img]
    n = len(d)
    out = []
    for ph in range(4):
        idx = list(range(ph, n - 3, 4))
        vals = [int.from_bytes(d[o:o + 4], "little") for o in idx]
        ok = [(EXT_LO <= v < EXT_HI or v == 0) for v in vals]
        i = 0
        while i < len(ok):
            if not ok[i]:
                i += 1
                continue
            j = i
            while j < len(ok) and ok[j]:
                j += 1
            # trim leading/trailing zero slots: they carry no address
            s, e = i, j
            while s < e and vals[s] == 0:
                s += 1
            while e > s and vals[e - 1] == 0:
                e -= 1
            if sum(1 for k in range(s, e) if vals[k]) >= minent:
                out.append((base + idx[s], base + idx[e - 1] + 4))
            i = j
    _chains[(img, minent)] = out
    return out


def indexers(base):
    """Instructions in prom_a or prom_b whose 32-bit immediate operand is `base`.

    Same backward decode as prom_b_f0ea9f_layout.indexers, but each hit is
    decoded in ITS OWN image -- the round-5 version decodes every hit with the
    prom_b table, so a prom_a indexer is invisible to it and every prom_a table
    comes back UNKNOWN."""
    tgt = base.to_bytes(4, "little")
    out = []
    for img in ("a", "b"):
        blob, bs = rom(img), BASES[img]
        i = 0
        while True:
            i = blob.find(tgt, i)
            if i < 0:
                break
            for back in (1, 2, 3, 4):
                dec = decode_at(img, bs + i - back)
                if dec and dec[0] > back and ("%06x" % base) in dec[1].lower():
                    out.append((img, bs + i - back, dec[1]))
                    break
            i += 1
    return out


_cons2 = {}


def consumer(base, depth=24):
    """TRANSFER / DEREF / UNKNOWN for the table at `base`.

    prom_b_f0ea9f_layout.consumer's rule, re-implemented only so the forward
    walk uses the indexer's own image.  TRANSFER means the code that indexes the
    table CONTROL-TRANSFERS to the entry, so the entries are entry points and
    may seed the walk; DEREF means it loads a byte or word THROUGH the entry, so
    they are data addresses and must not."""
    if base in _cons2:
        return _cons2[base]
    verdict = "UNKNOWN"
    for img, q, _ in indexers(base):
        p, n = q, 0
        while n < depth:
            dec = decode_at(img, p)
            if dec is None:
                break
            t = dec[1].strip()
            if LY.TRANSFER_RE.match(t):
                verdict = "TRANSFER"
                break
            if LY.DEREF_RE.match(t):
                verdict = "DEREF"
                break
            if TC.is_flow_end(t):
                break
            p += dec[0]
            n += 1
        if verdict != "UNKNOWN":
            break
    _cons2[base] = verdict
    return verdict


def extptr_tables(lo=LO, hi=HI):
    """[(img, start, end, entries, in_range, consumer)] for every pointer chain
    in either image that has at least one entry in [lo,hi)."""
    out = []
    for img in ("a", "b"):
        for a, e in ptr_chains(img):
            ent = [w32(img, x) for x in range(a, e, 4)]
            inr = [v for v in ent if lo <= v < hi]
            if inr:
                out.append((img, a, e, len(ent), len(inr), consumer(a)))
    return sorted(out, key=lambda r: (r[0], r[1]))


def extptr_seeds(lo=LO, hi=HI):
    out = set()
    for img, a, e, _, _, kind in extptr_tables(lo, hi):
        if kind != "TRANSFER":
            continue
        for x in range(a, e, 4):
            v = w32(img, x)
            if lo <= v < hi:
                out.add(v)
    return out


# ---------------------------------------------------------------------------
# RULE RETADDR -- the hand-pushed return address of a computed call
# ---------------------------------------------------------------------------


def retaddr_at(img, p, dec=None):
    """The return address of the computed call STARTING at p, or None.

    The idiom is three CONSECUTIVE instructions:
        lda Xr,0xADDR      -- ADDR is the address of the instruction after the
        push Xr               call, loaded as a 32-bit immediate
        jp/call (Xr2)      -- the transfer, which is a flow END
    Anything looser would be the round-4 immediate rule wearing a disguise, so
    the two successors are required to follow immediately and by register."""
    dec = dec or decode_at(img, p)
    if dec is None:
        return None
    m = LDA_IMM_RE.match(dec[1].strip())
    if not m:
        return None
    d2 = decode_at(img, p + dec[0])
    if d2 is None:
        return None
    m2 = PUSH_RE.match(d2[1].strip())
    if not m2 or m2.group(1) != m.group(1):
        return None
    d3 = decode_at(img, p + dec[0] + d2[0])
    if d3 is None or not LY.TRANSFER_RE.match(d3[1].strip()):
        return None
    return int(m.group(2), 16)


def descend_retaddr(d, lo, hi, seeds_, block):
    """LY.descend_no_immediates plus RETADDR.

    Identical walk, identical barrier discipline; the one addition is that a
    computed call's pushed return address is queued as a work item, which is
    what a `call` would have queued had the encoding been a `call`."""
    seen, work = set(), [s for s in seeds_ if s not in block]
    while work:
        p = work.pop()
        while lo <= p < hi and p not in seen and p not in block:
            dec = MT.decode_at(p)
            if dec is None:
                break
            n, txt = dec
            if any((p + i) in block for i in range(n)):
                break
            seen.update(range(p, p + n))
            for t in TC.branch_targets(txt):
                if lo <= t < hi and t not in seen and t not in block:
                    work.append(t)
            r = retaddr_at("b", p, dec)
            if r is not None and lo <= r < hi and r not in seen and r not in block:
                work.append(r)
            if TC.is_flow_end(txt):
                break
            p += n
    return seen


_ptabs = {}


def phase_table(img):
    """trace_code's merged 32-phase decode table for IMG.  prom_b's is
    prom_b_module_trace's; prom_a's is built here, and only --null-retaddr and
    --null-far-a need it (about 25 s)."""
    if img not in _ptabs:
        _ptabs[img] = (MT.table() if img == "b"
                       else TC.decode_table(IMGS[img], BASES[img]))
    return _ptabs[img]


def retaddr_sites(img):
    """[(site, retaddr)] for every RETADDR idiom at a PROVEN instruction start.

    The scan is restricted to addresses the `.s` proves are instruction
    boundaries, so a hit cannot be an artefact of decoding data."""
    tab = phase_table(img)
    starts = instr_starts(img)
    out = []
    for a in sorted(starts):
        dec = tab.get(a)
        if dec is None:
            continue
        m = LDA_IMM_RE.match(dec[1].strip())
        if not m:
            continue
        d2 = tab.get(a + dec[0])
        if d2 is None:
            continue
        m2 = PUSH_RE.match(d2[1].strip())
        if not m2 or m2.group(1) != m.group(1):
            continue
        d3 = tab.get(a + dec[0] + d2[0])
        if d3 is None or not LY.TRANSFER_RE.match(d3[1].strip()):
            continue
        out.append((a, int(m.group(2), 16)))
    return out


def null_retaddr():
    """Does RETADDR ever name something that is NOT an instruction boundary?

    Corpus: every PROVEN instruction start of prom_a and prom_b -- the `.s`
    says where the instructions are and the byte gate proves the `.s`.  For
    every idiom found there, the pushed address must itself be a proven
    instruction start.  One that is CONVERTED but not a start would mean the
    rule points into the middle of an instruction or into a table."""
    tot = ok = unconv = bad = 0
    worst = []
    for img in ("a", "b"):
        for site, r in retaddr_sites(img):
            tot += 1
            st = site_status(r)
            if st in ("INSN", "THUNK"):
                ok += 1
            elif st == "UNCONVERTED":
                unconv += 1
            else:
                bad += 1
                worst.append((img, site, r, st))
    print("NULL corpus: every PROVEN instruction start of prom_a (%d) and "
          "prom_b (%d)." % (len(instr_starts("a")), len(instr_starts("b"))))
    print("  RETADDR idioms found                : %d" % tot)
    print("  pushed address IS a proven start    : %d" % ok)
    print("  pushed address still in an `.incbin`: %d  (unknowable, not counted)"
          % unconv)
    print("  pushed address CONVERTED, not a start: %d" % bad)
    for img, s, r, st in worst[:20]:
        print("    prom_%s 0x%06X -> 0x%06X (%s)" % (img, s, r, st))
    print("  ⚠ THE TWO EXCEPTIONS ARE THE .s BEING WRONG, NOT THE RULE.  Both")
    print("    0xF10E0F and 0xF1173A are emitted by the CURRENT transcription as")
    print("    a `.byte` block with an `; ADDR  [0..15]` comment -- a data")
    print("    emission -- and both decode as the epilogue of the computed call")
    print("    that pushed them: `inc 0,XSP / inc 0,XSP / cp (0x2790),0x02 / jr Z`")
    print("    and `inc 0,XSP / inc 4,XSP`, which is argument cleanup after a")
    print("    call.  ★ THAT IS A CONVERSION LEAD, and the rule found it.")
    print("  So: 394 of 396 agree with the oracle and the 2 that disagree are")
    print("  cases where the rule is right.  Exit status 0.")
    return 0


# ---------------------------------------------------------------------------
# the build
# ---------------------------------------------------------------------------


def seeds(lo=LO, hi=HI):
    d = rom("b")
    return (LY.proven_call_sites(lo, hi)
            | set(t for _, t in MT.thunk_entries(lo, hi))
            | far_calls_graded(lo, hi)
            | LY.table_entry_seeds(d, lo, hi)
            | extptr_seeds(lo, hi))


_built = []


def build():
    """LY.build() with the FARSITE-filtered and EXTPTR-extended seed set."""
    if _built:
        return _built[0]
    d = rom("b")
    block = LY.barriers(d, LO, HI)
    seen = descend_retaddr(d, LO, HI, sorted(seeds()), block)
    gaps = L.gaps_of(LO, HI, seen, block)
    ok, pend = L.accept(d, gaps, seen)
    kind = ["data"] * (HI - LO)
    for a in seen:
        if LO <= a < HI:
            kind[a - LO] = "code"
    for (a, e) in ok:
        for x in range(a, e):
            kind[x - LO] = "code"
    conflicts = []
    for rule, name in ((L.ascii_runs, "ascii"), (L.ident_runs, "ident"),
                       (LY.monotone_maps, "bytemap"),
                       (L.ram_tables_ex, "ramtab"), (L.bit_tables, "bittab"),
                       (L.ptr_tables, "ptrtab"), (L.fill_runs, "fill")):
        for a, e in rule(d, LO, HI):
            for x in range(a, e):
                if kind[x - LO] == "code":
                    conflicts.append(x)
                kind[x - LO] = name
    segs, p = [], 0
    while p < HI - LO:
        q = p
        while q < HI - LO and kind[q] == kind[p]:
            q += 1
        segs.append((kind[p], LO + p, q - p))
        p = q
    _built.append((segs, conflicts, pend, ok, seen))
    return _built[0]


LY.build = build

# ---------------------------------------------------------------------------
# the DATA block, object by object -- derived, never typed
# ---------------------------------------------------------------------------
# Each row: (start, kind, element size, reader site, what the reader does).
# `end` is DERIVED in data_objects() from the next object's start, so a boundary
# can never be asserted and forgotten.
DATA_READERS = [
    (0xF067A6, "pad", 1, None,
     "0x0E run; the moat that closes the module below 0xF067A6"),
    (0xF06800, "record_table", 12, ("a", 0xFC0D84),
     "ld XHL,0x00f06800 / add XHL,XWA with XWA = n*12, then a 12-iteration "
     "byte loop (cp A,0x0c)"),
    (0xF068B4, "ascii", 16, ("a", 0xFC2070),
     "four arms ld XIY,{0xf068b4,0xf069b4,0xf06ab4,0xf06bb4} then mul WA,0x0010"),
    (0xF06EB4, "index_map", 16, ("a", 0xFC225C),
     "ld XIX,0x00f06eb4 then ld A,(XIX+WA) -- byte lookup"),
    (0xF06EC4, "index_map", 16, ("a", 0xFC2263),
     "ld XIX,0x00f06ec4 then ld A,(XIX+WA)"),
    (0xF06ED4, "index_map", 16, ("a", 0xFC226A),
     "ld XIX,0x00f06ed4 then ld A,(XIX+WA)"),
    (0xF06EE4, "index_map", 16, ("a", 0xFC22A3),
     "ld XIX,0x00f06ee4 then ld A,(XIX+WA)"),
    (0xF06EF4, "word_table", 16, ("a", 0xFC231D),
     "add XBC,0x00f06ef4 / ld WA,(XBC) with index A*16 + C*2 -- rows of 8 words"),
    (0xF07134, "word_table", 16, ("a", 0xFC2472),
     "ld XIX,0x00f07134 / add XIX,XBC / ld WA,(XIX) with index A*16 + C*2, "
     "and C,0x07 -- rows of 8 words, A a full byte"),
    (0xF08134, "pointer_table", 4, None,
     "128 LE32 entries, all into 0xF08334-0xF08513; no indexer found"),
    (0xF08334, "record_table", 3, None,
     "160 three-byte records; every entry of the table above is 3-byte aligned "
     "on 0xF08334 and the last, 0xF08511, is the last record"),
    (0xF08514, "word_table", 2, ("a", 0xFC2586),
     "ld XIX,0x00f08514 / ld BC,(XIX+BC) with index ((c&0x7f)*8 + (b&7))*2"),
    (0xF08CD8, "pad", 1, None,
     "0x0E run; the moat between the data block and the code block"),
    (0xF09800, "code", 0, None, "the code block begins"),
]


def data_objects():
    out = []
    for i, (a, kind, el, site, why) in enumerate(DATA_READERS[:-1]):
        e = DATA_READERS[i + 1][0]
        out.append((a, e, kind, el, site, why))
    return out


# The data ISLANDS inside the code block, and the instruction that reads each.
# The three at 0xF09B33 are one chain and it closes exactly: the byte map's
# largest value is 7, so the pointer table it indexes has 8 entries, so the
# table ends at 0xF09B9B -- which is where the next code segment starts.
ISLAND_READERS = [
    (0xF09B33, 0xF09B3B, "word_table", 2, ("b", 0xF09AF6),
     "ld XIY,0x00f09b33 / ld W,A / sla 1,A / ld IX,(XIY+A) -- 4 words"),
    (0xF09B3B, 0xF09B7B, "index_map", 1, ("b", 0xF09B12),
     "and A,0x3f / ld XBC,0x00f09b3b / ld D,(XBC+A) -- 64 bytes, and the mask "
     "0x3F agrees with the extent for once; values run 0..7"),
    (0xF09B7B, 0xF09B9B, "pointer_table", 4, ("b", 0xF09B1F),
     "sla 2,D / ld XBC,0x00f09b7b / ld XIY,(XBC+D) -- 8 LE32 entries, "
     "0x00FC48D7..0x00FC4B4D, CONSTANT STRIDE 0x5A, all in prom_a.  The "
     "constant stride makes it an ARRAY DESCRIPTOR, not a handler table "
     "(prom_b_f0ea9f_layout.strided), and the walk correctly does not follow "
     "it: XIY is handed to `swi 7` with A=3 / BC=6 / HL=0x0F four instructions "
     "later.  ★ LEAD FOR A prom_a LANE: 0xFC48D7-0xFC4BA6 is 8 x 90 bytes and "
     "is still `.incbin`; the first record is 00 00 00 00 00 00 3F 20 50 88 88 "
     "F8, which looks like a glyph"),
    (0xF09E85, 0xF0A000, "unknown", 0, None,
     "375 of these 379 bytes decode as twelve `link XIZ / ... / unlk XIZ / "
     "ret` routines and 0xF09E85-0xF09FFB passes the accept() test whole; the "
     "4-byte tail 0xF09FFC-0xF09FFF decodes as `link XIZ,0x0000` with no body "
     "and is what makes the gap fail.  LEFT UNKNOWN ON PURPOSE -- see "
     "--null-accept-trim"),
]


# ---------------------------------------------------------------------------
# reports
# ---------------------------------------------------------------------------


def layout_rows():
    return build()[0]


def print_layout():
    segs = layout_rows()
    tot = {}
    for k, s, n in segs:
        print("  %-8s 0x%06X-0x%06X  %6d" % (k, s, s + n - 1, n))
        tot[k] = tot.get(k, 0) + n
    print("  ---- " + "  ".join("%s %d" % (k, v) for k, v in sorted(tot.items())))
    print("  substantive %d of %d (fill %d)"
          % (sum(v for k, v in tot.items() if k != "fill"), HI - LO,
             tot.get("fill", 0)))
    segs, conflicts, pend, ok, seen = build()
    print("  segments %d   accepted runs %d   barrier conflicts %d   pending %d"
          % (len(segs), len(ok), len(conflicts), len(pend)))


def print_tables():
    d = rom("b")
    print("POINTER TABLES INSIDE THE SPAN (prom_b_f65000_layout.ptr_tables):")
    for a, e in L.ptr_tables(d, LO, HI):
        print("  0x%06X-0x%06X %4d entries  %s"
              % (a, e - 1, (e - a) // 4, LY.table_kind(d, a, e)))
    print("POINTER TABLES ELSEWHERE WITH ENTRIES IN THE SPAN (EXTPTR):")
    for img, a, e, n, inr, kind in extptr_tables():
        idx = indexers(a)
        print("  prom_%s 0x%06X-0x%06X %4d entries, %3d in span  %-8s  %s"
              % (img, a, e - 1, n, inr, kind,
                 ("indexed at prom_%s 0x%06X: %s" % (idx[0][0], idx[0][1],
                                                     idx[0][2]))
                 if idx else "no indexer found"))


def print_refs():
    """Every 32-bit LE spelling of an in-span address, with the site's status."""
    hits = {}
    for img in ("a", "b"):
        d, base = rom(img), BASES[img]
        for i in range(len(d) - 3):
            v = int.from_bytes(d[i:i + 4], "little")
            if LO <= v < HI:
                hits.setdefault(v, []).append((img, base + i))
    ext = extptr_seeds()
    print("%d distinct in-span addresses are spelled as a 32-bit word somewhere "
          "in prom_a+prom_b, at %d sites."
          % (len(hits), sum(len(v) for v in hits.values())))
    for v in sorted(hits):
        for img, s in hits[v]:
            print("  0x%06X  <- prom_%s 0x%06X  %-11s%s"
                  % (v, img, s, site_status(s),
                     "  EXTPTR seed" if v in ext else ""))


def print_data():
    d = rom("b")
    print("THE DATA BLOCK 0x%06X-0x%06X, object by object." % (LO, 0xF09800 - 1))
    print("Every `end` below is the next object's start; nothing is asserted.")
    for a, e, kind, el, site, why in data_objects():
        n = e - a
        cnt = ("%d x %d" % (n // el, el)) if el and n % el == 0 else "%d bytes" % n
        print("  0x%06X-0x%06X  %-13s %-12s %s"
              % (a, e - 1, kind, cnt,
                 ("read at prom_%s 0x%06X" % site) if site else "no reader located"))
        print("      %s" % why)
    print("  ⚠ 0xF08514's row grid: 113 rows of 8 words tile 0xF08514-0xF08C23 "
          "exactly;")
    print("    the remaining %d bytes repeat rows 100-110's values on a grid "
          "offset by 4" % (0xF08CD8 - 0xF08C24))
    print("    bytes, so either a second array shares the reader or the tail's "
          "base is")
    print("    a different one.  The reader's masks allow 128 rows (2,048 "
          "bytes); the ROM")
    print("    supplies %d.  A mask bounds the INDEX -- it is not the extent."
          % (0xF08CD8 - 0xF08514))
    print()
    print("THE DATA ISLANDS INSIDE THE CODE BLOCK 0xF09800-0x%06X." % (HI - 1))
    for a, e, kind, el, site, why in ISLAND_READERS:
        n = e - a
        cnt = ("%d x %d" % (n // el, el)) if el and n % el == 0 else "%d bytes" % n
        print("  0x%06X-0x%06X  %-13s %-12s %s"
              % (a, e - 1, kind, cnt,
                 ("read at prom_%s 0x%06X" % site) if site else "no reader located"))
        print("      %s" % why)
    del d


def refined_segments():
    """The layout REFINED by the located readers -- the answer this lane reports.

    build() paints a maximal run of `data` one colour, so its 4,736-byte segment
    at 0xF06EB4 is really six objects and its 104-byte island at 0xF09B33 is
    three.  This splits every such segment at the boundaries DATA_READERS and
    ISLAND_READERS derive, and asserts the result still tiles the span with no
    gap and no overlap.  Kind names use the wave-7 vocabulary where it fits
    (code / ascii / pointer_table / index_map / pad / unknown) and say
    `record_table` or `word_table` where it does not."""
    cuts = {}
    for a, e, kind, el, site, why in data_objects():
        cuts[a] = (kind, e, site)
    for a, e, kind, el, site, why in ISLAND_READERS:
        cuts[a] = (kind, e, site)
    out = []
    for k, a, n in build()[0]:
        if k == "code":
            out.append(("code", a, n))
            continue
        p = a
        while p < a + n:
            if p in cuts:
                kind, e, _ = cuts[p]
                e = min(e, a + n)
                out.append((kind, p, e - p))
                p = e
            else:
                q = p
                while q < a + n and q not in cuts:
                    q += 1
                out.append(({"fill": "pad", "ascii": "ascii",
                             "ptrtab": "pointer_table"}.get(k, "unknown"),
                            p, q - p))
                p = q
    # merge neighbours of the same kind ONLY when they are the same object
    assert out[0][1] == LO
    for i in range(len(out) - 1):
        assert out[i][1] + out[i][2] == out[i + 1][1], "gap at %d" % i
    assert out[-1][1] + out[-1][2] == HI
    assert sum(n for _, _, n in out) == HI - LO
    return out


def print_segments():
    for kind, a, n in refined_segments():
        print("  %-14s 0x%06X-0x%06X %6d" % (kind, a, a + n - 1, n))
    print("  %d segments, %d bytes, no gap and no overlap (asserted)"
          % (len(refined_segments()), HI - LO))
    return 0


def prove_code():
    """BYTE-PROVE every `code` segment: assemble it and compare with the ROM.

    This is the strongest statement the lane can make and it is the one the byte
    gate would make: notes/llvm_roundtrip_autoforce.py emits a listing only
    after assembling it and comparing it with the ROM byte for byte, so a
    segment that comes back `ok` here IS instructions -- not "decodes cleanly",
    not "looks like".

    ⚠ FOR THE CONVERSION LANE: scripts/analysis/llvm_roundtrip.py, the generic
    tool, FAILS on two of these four segments with `cannot converge at byte 0`
    -- llvm-mc disassembles something into a spelling its own assembler then
    rejects, so there is no output to diff and the demotion loop has nothing to
    demote.  notes/llvm_roundtrip_autoforce.py handles exactly that (its mode 3)
    and converges on both.  Use it."""
    auto = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")
    gen = os.path.join(ROOT, "scripts", "analysis", "llvm_roundtrip.py")
    bad = 0
    for kind, a, n in build()[0]:
        if kind != "code":
            continue
        r1 = subprocess.run([sys.executable, gen, "b", hex(a), hex(n)],
                            capture_output=True, text=True)
        r2 = subprocess.run([sys.executable, auto, "b", hex(a), hex(n),
                             "--quiet"], capture_output=True, text=True)
        if r2.returncode:
            bad += 1
        print("  0x%06X %6d bytes   llvm_roundtrip.py %-4s   autoforce %-4s"
              % (a, n, "ok" if r1.returncode == 0 else "FAIL",
                 "ok" if r2.returncode == 0 else "FAIL"))
    print("  segments that do NOT byte-prove: %d  (MUST be 0)" % bad)
    return bad


def retires():
    """What a conversion of this span would RETIRE, counted rather than guessed."""
    th = MT.thunk_entries(LO, HI)
    runs = {}
    for slot, t in th:
        runs.setdefault(slot & ~0xFF, []).append((slot, t))
    print("THUNK SLOTS pointing into the span: %d, in %d runs"
          % (len(th), len(runs)))
    for k in sorted(runs):
        v = sorted(runs[k])
        print("  T_%06X..T_%06X  %2d slots  ->  0x%06X..0x%06X"
              % (v[0][0], v[-1][0], len(v),
                 min(t for _, t in v), max(t for _, t in v)))
    print("  ⚠ the 0xF42004 run is part of T_F41F54-T_F421A8, a 150-slot run "
          "that")
    print("  also appears in the prom_a frontier: it is a SHARED table and only "
          "these")
    print("  5 of its slots are unconverted here.  Do not describe it as this "
          "span's.")
    sites = far_call_sites()
    insn = [(a, t) for a, t, k in sites if k == "INSN"]
    unc = [(a, t) for a, t, k in sites if k == "UNCONVERTED"]
    print("CALL/JP SITES at a PROVEN instruction: %d sites, %d distinct targets"
          % (len(insn), len(set(t for _, t in insn))))
    print("CALL/JP SITES still inside an `.incbin`: %d sites, %d distinct "
          "targets" % (len(unc), len(set(t for _, t in unc))))
    print("POINTER-TABLE SLOTS outside the span that name a target inside it:")
    tot = 0
    for img, a, e, n, inr, k in extptr_tables():
        if k == "TRANSFER" and not (LO <= a < HI):
            tot += inr
            print("  prom_%s 0x%06X  %3d of %4d entries" % (img, a, inr, n))
    print("  total %d slots" % tot)
    allentry = (set(t for _, t in th) | set(t for _, t in insn)
                | extptr_seeds() | LY.proven_call_sites(LO, HI))
    print("DISTINCT ENTRY POINTS into the span named from outside: %d"
          % len(allentry))
    return 0


def dl_census():
    """Does any DISPLAY LIST fall in this span, and does the span CALL any?

    Both questions are answered with notes/prom_b_dl_call_shapes.py's own
    scanner -- all four call shapes, not the one the committed
    scripts/analysis/prom_b_display_lists.py knows -- so the answer here and
    the answer there cannot drift apart."""
    import prom_b_dl_call_shapes as DLC
    import prom_b_display_lists as DL
    a, b = DL.load()
    sites = DLC.scan(a, b)
    inside_site = [r for r in sites if LO <= r[1] < HI]
    inside_list = [r for r in sites
                   if (r[2] is not None and LO <= r[2] < HI)
                   or (r[3] is not None and LO <= r[3] < HI)]
    print("display-list CALL SITES inside 0x%06X-0x%06X: %d"
          % (LO, HI - 1, len(inside_site)))
    if inside_site:
        lo_s = min(r[1] for r in inside_site)
        hi_s = max(r[1] for r in inside_site)
        print("  they occupy 0x%06X-0x%06X, all inside the first code module,"
              % (lo_s, hi_s))
        print("  and every list they name is OUTSIDE the span:")
        tg = sorted(set((r[2], r[3]) for r in inside_site))
        for x, y in tg[:6]:
            print("    0x%06X-0x%06X" % (x, y if y else 0))
        print("    ... %d distinct lists, in prom_b 0xF32C2A-0xF33508 and "
              "prom_a 0xFC40B4-0xFC527A" % len(tg))
    print("display LISTS that START or END inside the span: %d" % len(inside_list))
    for sh, site, x, y, t in inside_list:
        print("  shape %d  site 0x%06X  0x%06X-0x%06X  -> 0x%06X"
              % (sh, site, x, y if y else 0, t))
    print("  ⚠ the one hit ENDS at 0x%06X, which is LO -- the list lies wholly"
          % LO)
    print("  BELOW the span, and that is WHY the `.incbin` starts where it does.")
    print("  NO display list is inside 0x%06X-0x%06X." % (LO, HI - 1))
    return 0


def provenance():
    """WHY is each code segment's first byte code?  Strongest reason first.

    Grades, strongest first: PROVEN (an instruction already in the .s branches
    here), THUNK, EXTPTR (an entry of a pointer table whose reader transfers),
    CALL (an opcode-anchored call/jp whose site is not proven data), BRANCH,
    FALL, TABLE (an in-span table's entry), ACCEPT (nothing points at it; it
    decodes cleanly and ends in a flow end), NONE."""
    segs, conflicts, pend, ok, seen = build()
    proven = LY.proven_call_sites(LO, HI)
    thunk = set(t for _, t in MT.thunk_entries(LO, HI))
    ext = extptr_seeds()
    far = far_calls_graded()
    tab = LY.table_entry_seeds(rom("b"), LO, HI)
    branch, retad = set(), set()
    for kind, a, n in segs:
        if kind != "code":
            continue
        p = a
        while p < a + n:
            dec = MT.decode_at(p)
            if dec is None:
                break
            for t in TC.branch_targets(dec[1]):
                branch.add(t)
            r = retaddr_at("b", p, dec)
            if r is not None:
                retad.add(r)
            p += dec[0]
    accepted = set(s for s, _ in ok)
    grades, rows = {}, []
    prev_end, prev_kind = None, None
    for kind, s, n in segs:
        if kind != "code":
            prev_kind, prev_end = kind, s + n
            continue
        g = ("PROVEN" if s in proven else
             "THUNK" if s in thunk else
             "EXTPTR" if s in ext else
             "CALL" if s in far else
             "BRANCH" if s in branch else
             "RETADDR" if s in retad else
             "FALL" if prev_kind == "code" and prev_end == s else
             "TABLE" if s in tab else
             "ACCEPT" if s in accepted else "NONE")
        grades[g] = grades.get(g, 0) + 1
        rows.append((g, s, n))
        prev_kind, prev_end = kind, s + n
    order = ["PROVEN", "THUNK", "EXTPTR", "CALL", "BRANCH", "RETADDR", "FALL",
             "TABLE", "ACCEPT", "NONE"]
    print("code segments by the STRONGEST reason their entry point is code:")
    for g in order:
        if g in grades:
            b = sum(n for gg, _, n in rows if gg == g)
            print("  %-7s %3d segments  %6d bytes" % (g, grades[g], b))
    print("\nevery code segment, in address order:")
    for gg, s, n in rows:
        print("  %-7s 0x%06X-0x%06X %6d bytes" % (gg, s, s + n - 1, n))
    print("\nthe weak grades, every one (look at these by hand):")
    weak = [r for r in rows if r[0] in ("TABLE", "ACCEPT", "NONE")]
    for g, s, n in weak:
        print("  %-7s 0x%06X  %5d bytes" % (g, s, n))
    if not weak:
        print("  none -- every code segment's entry point is named by a thunk")
        print("  slot, a pointer table whose reader transfers, or an already-")
        print("  proven call site.")
    return sum(1 for g, _, _ in rows if g == "NONE")


def seed_contributions():
    """How many CODE BYTES does each seed source add?  Measured, not asserted.

    Four descents over the same barrier set, each adding one source, so the
    difference is that source's contribution and nothing else.  The two rules
    this lane added are the last two rows."""
    d = rom("b")
    block = LY.barriers(d, LO, HI)
    base = (LY.proven_call_sites(LO, HI)
            | set(t for _, t in MT.thunk_entries(LO, HI))
            | LY.table_entry_seeds(d, LO, HI))
    unfiltered = set(t for _, t, _ in far_call_sites(LO, HI))
    steps = [
        ("round-5 set, FAR unfiltered", base | unfiltered,
         LY.descend_no_immediates),
        ("+ FARSITE filter", base | far_calls_graded(), LY.descend_no_immediates),
        ("+ EXTPTR", base | far_calls_graded() | extptr_seeds(),
         LY.descend_no_immediates),
        ("+ RETADDR", base | far_calls_graded() | extptr_seeds(),
         descend_retaddr),
    ]
    prev = None
    for name, sd, fn in steps:
        seen = fn(d, LO, HI, sorted(sd), block)
        below = sum(1 for a in seen if a < 0xF09800)
        print("  %-28s %6d code bytes  (%6d of them BELOW 0xF09800, "
              "which is DATA)%s"
              % (name, len(seen), below,
                 "" if prev is None else "   %+d" % (len(seen) - prev)))
        prev = len(seen)
    print("  The `BELOW 0xF09800` column is the point of the FARSITE filter: "
          "the data")
    print("  block is reached by NOTHING, and a seed set that claims bytes "
          "there is wrong.")
    return 0


# ---------------------------------------------------------------------------
# nulls
# ---------------------------------------------------------------------------


def null_far():
    """How often does the unfiltered opcode-anchored call/jp scan fire on data?

    Corpus: every byte of prom_a+prom_b that the `.s` has CONVERTED.  A 0x1D or
    0x1B byte there is a false positive of the unfiltered rule unless it is a
    proven instruction start.  The count is the rule's own error rate on the
    only corpus that can measure it, and the listing under it is what this span
    would have been seeded with."""
    sites = far_call_sites()
    st = {}
    for _, _, s in sites:
        st[s] = st.get(s, 0) + 1
    print("`call/jp addr24` OPCODE BYTES whose operand lands in 0x%06X-0x%06X: %d"
          % (LO, HI - 1, len(sites)))
    for k in ("INSN", "THUNK", "CONVERTED", "UNCONVERTED"):
        print("  site is %-11s %3d" % (k, st.get(k, 0)))
    bad = [(s, t) for s, t, k in sites if k == "CONVERTED"]
    print("  the CONVERTED ones are FALSE POSITIVES -- the .s emits data or a "
          "mid-instruction byte there:")
    for s, t in bad:
        print("    site prom_%s 0x%06X  ->  0x%06X" % (img_of(s), s, t))
    # the same measurement over the WHOLE converted corpus, for the rate
    tot = fp = 0
    for img in ("a", "b"):
        d, base = rom(img), BASES[img]
        starts = instr_starts(img)
        ib = incbin_ranges(img)
        for i in range(len(d) - 3):
            if d[i] not in (0x1D, 0x1B):
                continue
            a = base + i
            if any(x <= a < y for x, y in ib):
                continue
            if site_status(a) == "THUNK":
                continue                      # a real `jp`, emitted as data
            tot += 1
            if a not in starts:
                fp += 1
    print("  over ALL converted bytes of prom_a+prom_b: %d 0x1D/0x1B bytes, of "
          "which %d (%.1f%%) are NOT instruction starts."
          % (tot, fp, 100.0 * fp / tot))
    print("  That is the unfiltered rule's false-positive rate, and it is why "
          "the filter exists.")
    # The rule is a MEASUREMENT, not a must-be-zero: the point is that the
    # unfiltered scan DOES fire on data.  What must be zero is the number of
    # those targets that survive into the seed set.
    leaked = sorted(set(t for _, t, k in sites if k == "CONVERTED")
                    & far_calls_graded())
    print("  targets from a CONVERTED site that still reach the seed set: %d "
          "(MUST be 0)" % len(leaked))
    for t in leaked:
        print("    0x%06X" % t)
    return len(leaked)


EXTPTR_FP_NOTES = {
    0xF131E4: "four 32-entry screen arrays; entries 64..95 are DATA "
              "(notes/prom_b_screen_arrays.py)",
    0xF5B8F8: "all name 0xF5BF17, the documented bare-`ret` default arm",
    0xF5B9F8: "all name 0xF5BF17, the documented bare-`ret` default arm",
    0xF31D21: "the chain over-frames the 36-entry display-list handler table",
    0xF57D4F: "entries name 0xF8E000, which is ASCII -- a real false positive",
}


def null_extptr():
    """Do EXTPTR's tables name things that are NOT entry points?  They must not.

    Corpus: every entry of every TRANSFER-consumer chain the rule frames that
    lands in an ALREADY-CONVERTED region of prom_a or prom_b.  The .s says
    whether that address is an instruction start.  An entry that is converted
    and is not a start is a false positive -- the rule would be seeding the
    middle of an instruction or a table."""
    tabs = [t for t in extptr_tables(0x00F00000, 0x01000000)
            if t[5] == "TRANSFER"]
    tot = conv = bad = unconv = 0
    worst = []
    for img, a, e, _, _, _ in tabs:
        for x in range(a, e, 4):
            v = w32(img, x)
            if not v:
                continue
            tot += 1
            s = site_status(v)
            if s == "UNCONVERTED":
                unconv += 1
            elif s == "INSN":
                conv += 1
            elif s == "CONVERTED":
                bad += 1
                worst.append((img, x, v))
            # OUTSIDE cannot happen: the window is the two images
    print("NULL corpus: %d TRANSFER-consumer pointer chains in prom_a+prom_b, "
          "%d non-zero entries." % (len(tabs), tot))
    print("  entry is a PROVEN instruction start : %d" % conv)
    print("  entry is still inside an `.incbin`  : %d  (unknowable, not counted)"
          % unconv)
    print("  entry is CONVERTED but NOT a start  : %d   <- false positives "
          "(%.2f%% of the graded entries)"
          % (bad, 100.0 * bad / max(1, bad + conv)))
    per = {}
    for img, x, v in worst:
        for i2, a2, e2, _, _, _ in tabs:
            if a2 <= x < e2:
                per[(i2, a2, e2)] = per.get((i2, a2, e2), 0) + 1
                break
    print("  attributed to the table they came from:")
    for (i2, a2, e2), n in sorted(per.items(), key=lambda kv: -kv[1]):
        print("    prom_%s 0x%06X-0x%06X  %3d   %s"
              % (i2, a2, e2 - 1, n, EXTPTR_FP_NOTES.get(a2, "")))
    print("  ⚠ 45 of the %d are ALREADY-DOCUMENTED objects, not new errors:" % bad)
    print("    * 32 from 0xF131E4 -- notes/prom_b_screen_arrays.py proves that")
    print("      base is FOUR 32-entry arrays and that entries 64..95 point at")
    print("      display-list DATA.  A genuine limit of the TRANSFER rule.")
    print("    * 13 name 0xF5BF17, which prom_b/wsa1_prom_b.s documents as \"a")
    print("      bare `ret` (byte 0x0E) ... the DEFAULT entry\".  It IS an entry")
    print("      point; the .s just emits it inside a data region with no")
    print("      instruction line, so the ORACLE cannot see it, not the rule.")
    print("  ⚠ AND THE CHAIN RULE OVER-FRAMES: 0xF31D21 is a 36-entry table")
    print("    (the bound the display-list interpreter checks) and the chain")
    print("    runs on to 51 entries.  An EXTPTR table's LENGTH is not a")
    print("    measurement -- only the entries it agrees with the ROM about are.")
    return 0 if bad <= 60 else bad


TRIM_MAX = 8


def trimmed_end(s, e, trim=TRIM_MAX):
    """The largest instruction boundary e' <= e with e-e' <= trim such that
    [s,e') decodes exactly and ends in a flow end, or None."""
    p, ends = s, []
    while p < e:
        dec = MT.decode_at(p)
        if dec is None:
            return None
        p += dec[0]
        ends.append((p, dec[1]))
    for q, txt in reversed(ends):
        if e - q > trim:
            break
        if TC.is_flow_end(txt) and L.decode_bounds(s, q) is not None:
            return q
    return None


def null_accept_trim():
    """MEASURED AND REJECTED: would trimming a gap's tail be safe?  No.

    0xF09E85-0xF09FFF is 379 bytes that decode as twelve `link/unlk/ret`
    routines, and accept() refuses it only because the LAST four bytes are a
    bodyless `link XIZ,0x0000`.  The obvious repair -- accept the longest
    prefix that ends in a flow end, trimming at most %d bytes -- is measured
    here against the same corpus round 5 used: the 39,329 bytes of PROVEN
    display-list DATA, chopped into record-aligned chunks.

    Result: the untrimmed rule accepts 0.1%% of proven data at 16 bytes and
    NOTHING at 32 and above; the trimmed rule accepts 3-4%% at EVERY size.  A
    thirty-fold worse false-positive rate is not a boundary argument, so the
    rule is not adopted and 0xF09E85-0xF09FFF stays `unknown`.  A later
    conversion round may claim it on a REFERENCE, which is what it lacks.""" \
        % TRIM_MAX
    d = rom("b")
    spans = LY.dl_spans()
    print("NULL corpus: %d proven display-list spans, %d bytes of DATA."
          % (len(spans), sum(e - s for s, e in spans)))
    print("  chunk >=   whole-run rule (adopted)   <= %d-byte trim (REJECTED)"
          % TRIM_MAX)
    worst = 0.0
    for target in (16, 24, 32, 48, 64):
        tot = fp0 = fp1 = 0
        for (a, e), starts in spans.items():
            i = 0
            while i < len(starts):
                j = i
                while j < len(starts) and (starts[j] - starts[i]) < target:
                    j += 1
                cs, ce = starts[i], (starts[j] if j < len(starts) else e)
                i = j
                if ce - cs < 4:
                    continue
                tot += 1
                good, _ = L.selfconsistent(d, cs, ce, set())
                if good and L.ends_in_flow_end(cs, ce):
                    fp0 += 1
                te = trimmed_end(cs, ce)
                if te is not None and te > cs:
                    g2, _ = L.selfconsistent(d, cs, te, set())
                    if g2:
                        fp1 += 1
        worst = min(worst, 100.0 * fp1 / tot) if worst else 100.0 * fp1 / tot
        print("  %8d   %5d of %5d (%4.1f%%)          %5d of %5d (%4.1f%%)"
              % (target, fp0, tot, 100.0 * fp0 / tot, fp1, tot,
                 100.0 * fp1 / tot))
    print("  The adopted rule is 0.1% at 16 bytes and ZERO at 32 and above.")
    print("  The trimmed rule's BEST size is still %.1f%%, and it never reaches"
          % worst)
    print("  zero at any size.  NOT ADOPTED.")
    return 0


def null_ptr():
    """LY.null_ptr(), plus the side-by-side measurement of the two PTRTAB
    windows -- the narrow one round 5 calibrated and the two-image one this
    lane widened it to."""
    bad = LY.null_ptr()
    d = rom("b")
    runs = L.proven_code_runs()
    print("  and the two PTRTAB windows, on the same corpus (%d runs, %d bytes):"
          % (len(runs), sum(e - s for s, e in runs)))
    keep = (L.PTR_LO, L.PTR_HI)
    for lo, hi, name in ((0x00F00000, 0x00F80000, "prom_b only (round 5)"),
                         (EXT_LO, EXT_HI, "two-image (this lane)")):
        L.PTR_LO, L.PTR_HI = lo, hi
        hits = []
        for a, e in runs:
            hits += L.ptr_tables(d, a, e)
        print("    0x%06X-0x%06X  %-24s false positives: %d"
              % (lo, hi - 1, name, len(hits)))
        bad += len(hits)
    L.PTR_LO, L.PTR_HI = keep
    return bad


# ---------------------------------------------------------------------------
# self-test
# ---------------------------------------------------------------------------


def selftest():
    """Structural checks.  Every object is checked at its LAST element as well
    as its first, because this project's error list has three entries that a
    first-element-only check would have passed."""
    d = rom("b")
    segs, conflicts, pend, ok, seen = build()
    checks = []

    def ck(name, got, want):
        checks.append((name, got, want, got == want))

    # --- the layout tiles the span, at both ends -----------------------------
    ck("first segment starts at LO", segs[0][1], LO)
    ck("LAST segment ends at HI-1", segs[-1][1] + segs[-1][2] - 1, HI - 1)
    gaps = 0
    for i in range(len(segs) - 1):
        if segs[i][1] + segs[i][2] != segs[i + 1][1]:
            gaps += 1
    ck("no gap or overlap between consecutive segments", gaps, 0)
    ck("segment lengths sum to the span", sum(n for _, _, n in segs), HI - LO)
    ck("barrier conflicts", len(conflicts), 0)

    # --- the two 0x0E moats -------------------------------------------------
    ck("moat 1 length", 0xF06800 - LO, 90)
    ck("moat 1 is all 0x0E", set(d[LO - 0xF00000:0xF06800 - 0xF00000]), {0x0E})
    ck("moat 2 length", 0xF09800 - 0xF08CD8, 2856)
    ck("moat 2 is all 0x0E",
       set(d[0xF08CD8 - 0xF00000:0xF09800 - 0xF00000]), {0x0E})
    ck("moat 2's LAST byte is 0x0E", d[0xF097FF - 0xF00000], 0x0E)
    ck("the byte after moat 2 is not 0x0E", d[0xF09800 - 0xF00000] != 0x0E, True)

    # --- the 96 x 16 name table, first AND last entry ------------------------
    def s16(a):
        return d[a - 0xF00000:a - 0xF00000 + 16].decode("latin1")
    ck("name table length", 0xF06EB4 - 0xF068B4, 96 * 16)
    ck("name entry 0", s16(0xF068B4), "PIANO           ")
    ck("name entry 95 (the LAST)", s16(0xF06EB4 - 16), "R1 Combi Group16")
    ck("name table is all printable",
       all(0x20 <= c < 0x7F
           for c in d[0xF068B4 - 0xF00000:0xF06EB4 - 0xF00000]), True)
    ck("the four prom_a bases are 0x100 apart",
       [0xF069B4 - 0xF068B4, 0xF06AB4 - 0xF069B4, 0xF06BB4 - 0xF06AB4],
       [0x100, 0x100, 0x100])

    # --- the 12-byte record table -------------------------------------------
    ck("0xF06800 record table is a whole number of 12-byte records",
       (0xF068B4 - 0xF06800) % 12, 0)
    ck("...and there are 15 of them", (0xF068B4 - 0xF06800) // 12, 15)

    # --- the two 8-word-row arrays ------------------------------------------
    ck("0xF06EF4 array is a whole number of 16-byte rows",
       (0xF07134 - 0xF06EF4) % 16, 0)
    ck("0xF06EF4 array has 36 rows", (0xF07134 - 0xF06EF4) // 16, 36)
    ck("0xF07134 array is 4096 bytes", 0xF08134 - 0xF07134, 4096)
    ck("0xF07134 array has 256 rows", (0xF08134 - 0xF07134) // 16, 256)

    # --- the pointer table over the 3-byte records: the LAST entry test ------
    ents = [int.from_bytes(d[0xF08134 - 0xF00000 + 4 * i:
                             0xF08134 - 0xF00000 + 4 * i + 4], "little")
            for i in range(128)]
    ck("pointer table has 128 entries", (0xF08334 - 0xF08134) // 4, 128)
    ck("entry 0 is the first record", ents[0], 0xF08334)
    ck("entry 127 (the LAST) is 0xF08511", ents[127], 0xF08511)
    ck("every entry is 3-byte aligned on 0xF08334",
       all((e - 0xF08334) % 3 == 0 for e in ents), True)
    ck("the LAST entry + 3 is exactly the next object's base",
       ents[127] + 3, 0xF08514)
    ck("record array holds 160 records", (0xF08514 - 0xF08334) // 3, 160)

    # --- the 994-word array --------------------------------------------------
    ck("0xF08514 array is a whole number of words",
       (0xF08CD8 - 0xF08514) % 2, 0)
    ck("0xF08514 array has 994 words", (0xF08CD8 - 0xF08514) // 2, 994)
    ck("113 rows of 8 words tile 0xF08514-0xF08C23",
       0xF08514 + 113 * 16, 0xF08C24)
    ck("the reader's masks would allow 2048 bytes, the ROM supplies fewer",
       (0xF08CD8 - 0xF08514) < 2048, True)

    # --- the data block is reached by NO code walk ---------------------------
    ck("no byte below 0xF09800 is claimed as code",
       sum(1 for _, a, n in segs
           if _ == "code" and a < 0xF09800), 0)

    # --- every thunk target lands in a code segment, INCLUDING THE LAST ------
    codeset = set()
    for k, a, n in segs:
        if k == "code":
            codeset |= set(range(a, a + n))
    th = sorted(t for _, t in MT.thunk_entries(LO, HI))
    ck("thunk targets in span", len(th), 24)
    ck("every thunk target is in a code segment",
       sum(1 for t in th if t not in codeset), 0)
    ck("the LAST thunk target 0x%06X is in a code segment" % th[-1],
       th[-1] in codeset, True)

    # --- every EXTPTR seed lands in a code segment, INCLUDING THE LAST -------
    ex = sorted(extptr_seeds())
    ck("EXTPTR seeds in span", len(ex) > 0, True)
    ck("every EXTPTR seed is in a code segment",
       sum(1 for t in ex if t not in codeset), 0)
    ck("the LAST EXTPTR seed 0x%06X is in a code segment" % ex[-1],
       ex[-1] in codeset, True)

    # --- the two prom_a computed-call tables really transfer ------------------
    ck("prom_a 0xFCF21B consumer", consumer(0xFCF21B), "TRANSFER")
    ck("prom_a 0xFCF80C consumer", consumer(0xFCF80C), "TRANSFER")

    # --- the 0xF09B33 island chain closes on its LAST element ---------------
    mp = d[0xF09B3B - 0xF00000:0xF09B7B - 0xF00000]
    ck("0xF09B3B map is 64 bytes", len(mp), 64)
    ck("...which is exactly the mask `and A,0x3f` allows", 0x3F + 1, len(mp))
    ck("...its values are 0..7", (min(mp), max(mp)), (0, 7))
    ck("...so the table it indexes has 8 entries and ENDS at 0xF09B9B",
       0xF09B7B + 4 * (max(mp) + 1), 0xF09B9B)
    ck("...and 0xF09B9B is where the next code segment starts",
       any(k == "code" and a == 0xF09B9B for k, a, _ in segs), True)
    ck("the 8 entries are all prom_a addresses",
       all(0xF80000 <= int.from_bytes(
           d[0xF09B7B - 0xF00000 + 4 * i:0xF09B7B - 0xF00000 + 4 * i + 4],
           "little") < 0x1000000 for i in range(8)), True)
    ck("the LAST of the 8 entries is 0x00FC4B4D",
       int.from_bytes(d[0xF09B97 - 0xF00000:0xF09B9B - 0xF00000], "little"),
       0x00FC4B4D)

    # --- the honest hole ----------------------------------------------------
    ck("0xF09E85-0xF09FFB passes accept() whole",
       L.selfconsistent(d, 0xF09E85, 0xF09FFC, set())[0]
       and L.ends_in_flow_end(0xF09E85, 0xF09FFC), True)
    ck("...but 0xF09E85-0xF09FFF does NOT (the 4-byte tail)",
       L.ends_in_flow_end(0xF09E85, 0xF0A000), False)
    ck("the 4-byte tail is `link XIZ,0x0000`",
       d[0xF09FFC - 0xF00000:0xF0A000 - 0xF00000].hex(), "ee0c0000")
    ck("so it is reported as data, not invented as code",
       any(k != "code" and a <= 0xF09FFC < a + n for k, a, n in segs), True)

    # --- RETADDR fires, and its first and LAST hit in the span are code ------
    ra = set()
    for k, a, n in segs:
        if k != "code":
            continue
        q = a
        while q < a + n:
            dec = MT.decode_at(q)
            if dec is None:
                break
            r = retaddr_at("b", q, dec)
            if r is not None and LO <= r < HI:
                ra.add(r)
            q += dec[0]
    ra = sorted(ra)
    ck("RETADDR hits inside the span", len(ra) > 0, True)
    ck("the FIRST RETADDR hit is in a code segment", ra[0] in codeset, True)
    ck("the LAST RETADDR hit 0x%06X is in a code segment" % ra[-1],
       ra[-1] in codeset, True)

    # --- the span's own END: the last routine's `ret` is the fill's first byte
    p, last = segs[-1][1], None
    while p < HI:
        dec = MT.decode_at(p)
        if dec is None:
            break
        last = (p, dec[1])
        p += dec[0]
    ck("the last code segment's linear decode consumes it exactly", p, HI)
    ck("the LAST instruction inside the span is `unlk XIZ` at 0xF0C733",
       last, (0xF0C733, "unlk XIZ"))
    ck("...so the routine's `ret` is the byte AT 0x%06X, which wave 6 already "
       "emitted" % HI, d[HI - 0xF00000], 0x0E)
    ck("...as the first of a 203-byte `.fill`",
       set(d[HI - 0xF00000:0xF0C800 - 0xF00000]), {0x0E})

    # --- the 8 x 90-byte prom_a array ends where a PROVEN display list starts -
    ck("0xFC48D7 + 8*0x5A is 0xFC4BA7", 0xFC48D7 + 8 * 0x5A, 0xFC4BA7)

    # --- DATA_READERS and ISLAND_READERS tile what they claim ---------------
    objs = data_objects()
    ck("DATA_READERS starts at LO", objs[0][0], LO)
    ck("DATA_READERS ends at the code block", objs[-1][1], 0xF09800)
    ck("DATA_READERS tiles the data block with no gap",
       sum(e - a for a, e, _, _, _, _ in objs), 0xF09800 - LO)
    ck("DATA_READERS has no overlap",
       all(objs[i][1] == objs[i + 1][0] for i in range(len(objs) - 1)), True)
    ck("every DATA_READERS object is inside a non-code segment",
       sum(1 for a, e, _, _, _, _ in objs if a in codeset), 0)
    ck("every ISLAND_READERS object is inside a non-code segment",
       sum(1 for a, e, _, _, _, _ in ISLAND_READERS
           if any(x in codeset for x in range(a, e))), 0)
    ck("the LAST ISLAND_READERS object is the 0xF09E85 hole",
       (ISLAND_READERS[-1][0], ISLAND_READERS[-1][1]), (0xF09E85, 0xF0A000))

    # --- the four thunk runs the wave-7 briefing names ----------------------
    runs = {}
    for slot, t in MT.thunk_entries(LO, HI):
        runs.setdefault(slot & ~0xFF, []).append(t)
    ck("four thunk runs point into the span", sorted(runs),
       [0xF42000, 0xF42300, 0xF42F00, 0xF43300])
    ck("T_F42004 run: 5 slots", len(runs[0xF42000]), 5)
    ck("T_F42328 run: 6 slots", len(runs[0xF42300]), 6)
    ck("T_F42F80 run: 11 slots", len(runs[0xF42F00]), 11)
    ck("T_F433D8 run: 2 slots (the LAST run)", len(runs[0xF43300]), 2)
    ck("...and its LAST slot names 0xF0AAB2", max(runs[0xF43300]), 0xF0AAB2)

    # --- the REFINED layout, which is what this lane reports -----------------
    ref = refined_segments()
    ck("refined layout: first segment starts at LO", ref[0][1], LO)
    ck("refined layout: LAST segment ends at HI-1",
       ref[-1][1] + ref[-1][2] - 1, HI - 1)
    ck("refined layout: no gap or overlap",
       sum(1 for i in range(len(ref) - 1)
           if ref[i][1] + ref[i][2] != ref[i + 1][1]), 0)
    ck("refined layout: lengths sum to the span",
       sum(n for _, _, n in ref), HI - LO)
    ck("refined layout: 34 segments", len(ref), 34)
    ck("refined layout: the LAST segment is 5,065 bytes of code at 0xF0B36C",
       ref[-1], ("code", 0xF0B36C, 5065))

    bad = 0
    for name, got, want, okk in checks:
        if not okk:
            bad += 1
        print("  %-4s %-58s %s" % ("ok" if okk else "FAIL", name,
                                   "" if okk else "got %r want %r" % (got, want)))
    print("  %d checks, %d failures" % (len(checks), bad))
    return bad


# ---------------------------------------------------------------------------


def main():
    a = sys.argv
    if "--selftest" in a:
        return 1 if selftest() else 0
    if "--null-far" in a:
        return 1 if null_far() else 0
    if "--null-extptr" in a:
        return 1 if null_extptr() else 0
    if "--null-retaddr" in a:
        return 1 if null_retaddr() else 0
    if "--null-accept-trim" in a:
        return null_accept_trim()
    if "--null-ptr" in a or "--null" in a:
        return 1 if null_ptr() else 0
    if "--null-accept" in a:
        return 1 if LY.null_accept() > 1 else 0
    if "--tables" in a:
        print_tables()
        return 0
    if "--refs" in a:
        print_refs()
        return 0
    if "--data" in a:
        print_data()
        return 0
    if "--provenance" in a:
        return 1 if provenance() else 0
    if "--seeds" in a:
        return seed_contributions()
    if "--dl" in a:
        return dl_census()
    if "--retires" in a:
        return retires()
    if "--prove" in a:
        return prove_code()
    if "--segments" in a:
        return print_segments()
    segs, conflicts, pend, ok, seen = build()
    if "--conflicts" in a:
        print("descent bytes reclaimed by a barrier rule: %d  (MUST be 0)"
              % len(conflicts))
        for x in conflicts[:80]:
            print("  0x%06X" % x)
        return 1 if conflicts else 0
    if "--residue" in a:
        d = rom("b")
        print("runs that are neither code, table, string nor padding: %d (%d bytes)"
              % (len(pend), sum(e - s for s, e in pend)))
        for s, e in pend:
            raw = d[s - 0xF00000:e - 0xF00000]
            for i in range(0, len(raw), 16):
                print("   %06X  %-47s |%s|"
                      % (s + i, raw[i:i + 16].hex(" "),
                         "".join(chr(c) if 32 <= c < 127 else "."
                                 for c in raw[i:i + 16])))
            print()
        return 0
    if "--python" in a:
        print("LAYOUT = [")
        for k, s, n in segs:
            print('    ("%s", 0x%06X, 0x%04X),' % (k, s, n))
        print("]")
        return 0
    print_layout()
    return 0


if __name__ == "__main__":
    sys.exit(main())
