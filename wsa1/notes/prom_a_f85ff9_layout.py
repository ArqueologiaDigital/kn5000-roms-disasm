#!/usr/bin/env python3
"""The code/data/fill LAYOUT of prom_a 0xF85FF9-0xF89800, derived from the ROM.

QUESTION IT ANSWERS
  "Which bytes of prom_a's fourth-largest `.incbin` span are instructions, which
   are tables, and which are padding?"  Every byte of the span is assigned, in
   address order, with no gaps and no overlaps.  A later conversion round takes
   this table and emits source from it; nothing here is typed by hand.

WHY THIS SPAN (re-derived, not copied from a briefing)
  python3 notes/prom_a_module_frontier.py   ranks the prom_b directory's thunk
  RUNS by contiguous unconverted target extent.  Two of its rows point here:
      T_F40F34-T_F40F50   8 slots  targets 0xF86066-0xF86AE9  extent 2691  refs 125
      T_F40F58-T_F40F94  16 slots  targets 0xF8659B-0xF86C5C  extent 1729  refs   6
  125 is by a wide margin the largest reference count of any unconverted prom_a
  run (next is 35, T_F40850).  `--rank` re-derives that table.

THE RULES, IN PRIORITY ORDER, AND THE NULL MEASURED FOR EACH
  The method is notes/prom_b_f65000_layout.py's: CONTENT rules first, each with
  a measured false-positive rate against a corpus of already-PROVEN instruction
  text, then those rules become BARRIERS that a recursive descent may neither
  enter nor take a seed inside.  A linear decode pins nothing here -- see
  notes/prom_a_linear_decode_check.py, whose own docstring names
  0xF86000-0xF8969B as its negative control, the span that really does fail.

  Measured on 264,982 bytes of proven prom_a instruction text (10,509 runs,
  working tree of 2026-08-28), the six rules fire 17 times in total, and
  `--null` adjudicates every one of the 17 mechanically: 15 are runs the
  transcription emits as N identical instruction lines (`nop` padding, `ret`
  padding, blank-fill written as `ldb w,0x20`) or are the target table of an
  `add XBC,imm32 / ld XBC,(XBC) / jp (xbc)` dispatch.  The other 2 are ASCII
  hits, and both are real strings -- 0xF94C79 is " BY (c)masa,toshi --- ><;:D".
  So the corpus, not the rule, is what is wrong in all 17 cases; but the RAW
  count is 17 and that is the number to quote.

  1. FILL0E -- a maximal run of >= 16 bytes of 0x0E.  0x0E is `ret`, so a SHORT
     run of it is ordinary inter-routine padding and stays inside a code
     segment; only the long runs that close a module become `.fill`.
  2. FILL00 -- a maximal run of >= 24 bytes of 0x00.
  3. FILLFF -- a maximal run of >= 24 bytes of 0xFF.  0xFF is the erased state of
     the flash AND the list terminator this module uses, so a long run of it is
     a run of EMPTY LISTS; the header a converter writes must say that rather
     than "padding".  See --lists.
  4. PTRTAB -- a maximal chain of >= 5 consecutive 4-byte little-endian words all
     inside 0x00F00000-0x01000000 (the CPU-1 ROM window: prom_b at 0xF00000 and
     prom_a at 0xF80000).  ⚠ THE THRESHOLD IS 5 BECAUSE 3 IS NOISY: at 3 the
     rule fires 8 times in the null corpus and 5 of those are a run of
     `ld (xiz-N),imm8` read one byte late (`be fX 00 vv` -> 0x00fXbevv, which
     lands in the window).  At 5 it fires twice and both are real jump tables.
  5. IDENT -- a maximal run of >= 12 bytes where byte[k] == byte[0]+k without
     wrapping past 0xFF: an index map.
  6. ASCII -- a maximal run of >= 20 bytes in 0x20-0x7E.
  7. CODE -- a recursive descent that treats every region rules 1-6 found as a
     BARRIER.  Its seeds are: the prom_b thunk-table targets that land in the
     span; every call/jp/calr/jr/jrl target of a PROVEN instruction of
     prom_a/wsa1_prom_a.s or prom_b/wsa1_prom_b.s that lands in the span (exact
     -- those instructions are certified by the byte gate); every
     opcode-anchored `call addr24`/`jp addr24` site in either image (an upper
     bound, used only to seed); every 32-bit immediate a decoded instruction
     LOADS; and every in-range entry of every table rule 4 framed.
  8. Anything still unreached that a linear decode consumes exactly, holds no
     undefined opcode, whose relative branches all land on instruction
     boundaries, and that ENDS IN A FLOW END, is accepted as code -- the
     `accept()` fixpoint of the prom_b tool, including the ends-in-flow-end
     correction that tool's round 5 had to make.
  Anything left over is DATA, and the segment kind says only that.

THE NULL CORPUS GROWS -- CITE IT WITH A REVISION
  The corpus is every maximal run of PROVEN instruction text in the CURRENT
  prom_a/wsa1_prom_a.s, so it grows every time any round converts anything, and
  a false-positive count quoted without a revision rots.

      python3 notes/prom_a_f85ff9_layout.py --null
      python3 notes/prom_a_f85ff9_layout.py --null --rev HEAD

  Bare --null uses the working tree and prints the corpus size it used.  Quote
  BOTH the count and the corpus, or quote neither.

RUN
  python3 notes/prom_a_f85ff9_layout.py              # the LAYOUT table
  python3 notes/prom_a_f85ff9_layout.py --null       # rule calibration
  python3 notes/prom_a_f85ff9_layout.py --conflicts  # descent-vs-barrier overlaps (MUST be 0)
  python3 notes/prom_a_f85ff9_layout.py --residue    # data runs, with hex
  python3 notes/prom_a_f85ff9_layout.py --lists      # the 3 x 192 list directories
  python3 notes/prom_a_f85ff9_layout.py --dispatch   # the 0xF86EC1 dispatch tables
  python3 notes/prom_a_f85ff9_layout.py --callsites  # who calls the 8 hot thunk slots
  python3 notes/prom_a_f85ff9_layout.py --rank       # re-derive the target ranking
  python3 notes/prom_a_f85ff9_layout.py --misframed  # jump tables the tree emits as code
  python3 notes/prom_a_f85ff9_layout.py --barrier    # what the barrier removes
  python3 notes/prom_a_f85ff9_layout.py --python     # paste-ready LAYOUT literal
  python3 notes/prom_a_f85ff9_layout.py --selftest   # every check, incl. the LAST segment
"""
import hashlib
import os
import pickle
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
from asm_source import image_text_at_rev  # noqa: E402  (the image at a revision)
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import trace_code as TC                                            # noqa: E402

A_BASE, B_BASE = 0xF80000, 0xF00000
LO, HI = 0xF85FF9, 0xF89800
IMGA = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
IMGB = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
SRCA = image_path(ROOT, "prom_a/wsa1_prom_a.s")
SRCB = image_path(ROOT, "prom_b/wsa1_prom_b.s")
PTR_LO, PTR_HI = 0x00F00000, 0x01000000
THUNK_LO, THUNK_HI = 0xF40000, 0xF44018
FILL0E_MIN, FILL00_MIN, FILLFF_MIN = 16, 8, 6
PTR_MIN, IDENT_MIN, ASCII_MIN = 5, 12, 20

# ⚠ A CORRECTION TO scripts/analysis/trace_code.py, MADE LOCALLY
#
# TC.is_flow_end() decides whether a `jp`/`jr`/`jrl` is unconditional by testing
# the operand against the condition list
#     NZ|Z|NC|C|PO|PE|P|M|NV|V|GE|LT|GT|LE|UGE|ULT|UGT|ULE|F
# but MAME's disassembler spells four of the sixteen conditions with a slash --
# `s_cond[16]` in ../mame/src/devices/cpu/tlcs900/dasm900.cpp:1409-1411 is
#     F, LT, LE, ULE, PE/OV, M/MI, Z, C, T, GE, GT, UGT, PO/NOV, P/PL, NZ, NC
# -- and none of `PE/OV`, `M/MI`, `PO/NOV`, `P/PL` matches that alternation.  So
# TC.is_flow_end reads `jr PE/OV,0xf86b58` as an UNCONDITIONAL jump and every
# descent built on it stops dead at one.  Three of the holes an earlier draft of
# this script reported as `unknown` -- 0xF86B52, 0xF86B64, 0xF86B88 -- are
# ordinary instructions on the fall-through side of exactly such a branch.
# `--flowend` measures what the correction is worth on this span.
#
# ⚠ NOT FIXED IN trace_code.py: that file belongs to another lane this round and
# the fix would change what every other tool reports.  It is reported instead.
COND = (r"(?:PE/OV|PO/NOV|M/MI|P/PL|ULE|UGT|NZ|NC|GE|GT|LT|LE|F|Z|C|T)")


def is_flow_end(txt):
    t = txt.split()
    if not t:
        return True
    op = t[0]
    if op in ("ret", "reti", "retd"):
        if len(t) == 1:
            return True
        m = re.match(COND + r"$", t[1])
        return (not m) or m.group(0) == "T"
    if op in ("jp", "jrl", "jr"):
        if len(t) == 1:
            return True
        arg = txt.split(None, 1)[1]
        m = re.match(COND + r",", arg)
        return (not m) or m.group(0)[:-1] == "T"
    return False


_rom = {}


def rom(which="a"):
    if which not in _rom:
        _rom[which] = open(IMGA if which == "a" else IMGB, "rb").read()
    return _rom[which]


def d():
    return rom("a")


def w32(a):
    return int.from_bytes(d()[a - A_BASE:a - A_BASE + 4], "little")


def byte(a):
    return d()[a - A_BASE]


# ---------------------------------------------------------------- decoder ----
_tab = None


def table():
    """addr -> (length, text) for prom_a, from trace_code's phase-merged sweep.

    Cached on disk because the 32-phase sweep costs ~40 s and every mode of this
    script needs it.  The cache carries the SHA-1 of the image it was built from,
    so a re-dumped ROM invalidates it instead of silently answering for the old
    one."""
    global _tab
    if _tab is not None:
        return _tab
    h = hashlib.sha1(d()).hexdigest()
    cd = os.environ.get("WSA1_CACHE_DIR", tempfile.gettempdir())
    cf = os.path.join(cd, "wsa1_prom_a_dectab.pkl")
    try:
        with open(cf, "rb") as f:
            got, tb = pickle.load(f)
        if got == h:
            _tab = tb
            return _tab
    except Exception:
        pass
    _tab = TC.decode_table(IMGA, A_BASE)
    try:
        with open(cf, "wb") as f:
            pickle.dump((h, _tab), f)
    except Exception:
        pass
    return _tab


def decode_at(addr, window=0x40):
    """(length, text) for the instruction AT addr, decoded FROM addr.

    The phase-merged table resynchronises long before it reaches any given
    module, so an address no sweep landed on has no entry; this decodes a window
    that starts exactly at addr, which by construction puts addr on a boundary.
    Same reason as notes/prom_b_module_trace.decode_at."""
    tb = table()
    if addr in tb:
        return tb[addr]
    data = d()
    o = addr - A_BASE
    if o < 0 or o >= len(data):
        return None
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(data[o:o + window])
        tmp = f.name
    try:
        out = subprocess.run([TC.UNIDASM, tmp, "-arch", "tlcs900",
                              "-basepc", hex(addr)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    for ln in out.splitlines():
        m = TC.LINE.match(ln)
        if m and int(m.group(1), 16) == addr:
            tb[addr] = (len(m.group(2).split()), m.group(3).strip())
            return tb[addr]
    return None


# ----------------------------------------------------------- content rules ----
def byte_runs(val, lo, hi, n):
    out, p = [], lo
    while p < hi:
        if byte(p) == val:
            q = p
            while q < hi and byte(q) == val:
                q += 1
            if q - p >= n:
                out.append((p, q))
            p = q
        else:
            p += 1
    return out


def fill0e_runs(lo, hi, n=FILL0E_MIN):
    return byte_runs(0x0E, lo, hi, n)


def fill00_runs(lo, hi, n=FILL00_MIN):
    return byte_runs(0x00, lo, hi, n)


def fillff_runs(lo, hi, n=FILLFF_MIN):
    return byte_runs(0xFF, lo, hi, n)


def ptr_tables(lo, hi, minent=PTR_MIN):
    best = {}
    for p in range(lo, hi - 3):
        k, q = 0, p
        while q <= hi - 4 and PTR_LO <= w32(q) < PTR_HI:
            k += 1
            q += 4
        if k >= minent:
            best[p] = k
    out, p = [], lo
    while p < hi - 3:
        if p in best:
            out.append((p, p + 4 * best[p]))
            p += 4 * best[p]
        else:
            p += 1
    return out


def ident_runs(lo, hi, n=IDENT_MIN):
    out, p = [], lo
    while p < hi:
        q = p + 1
        while q < hi and byte(p) + (q - p) <= 0xFF and byte(q) == byte(p) + (q - p):
            q += 1
        if q - p >= n:
            out.append((p, q))
            p = q
        else:
            p += 1
    return out


def ascii_runs(lo, hi, n=ASCII_MIN):
    out, p = [], lo
    while p < hi:
        if 32 <= byte(p) < 127:
            q = p
            while q < hi and 32 <= byte(q) < 127:
                q += 1
            if q - p >= n:
                out.append((p, q))
            p = q
        else:
            p += 1
    return out


RULES = [("fill", fill0e_runs), ("zero", fill00_runs), ("erased", fillff_runs),
         ("ptrtab", ptr_tables), ("ident", ident_runs), ("ascii", ascii_runs)]


def barriers(lo=LO, hi=HI):
    b = set()
    for _, f in RULES:
        for a, e in f(lo, hi):
            b |= set(range(a, e))
    return b


# ------------------------------------------------------------------ seeds ----
def proven_instructions(src, base):
    """[(addr, nbytes)] for every PROVEN instruction line of a transcription.

    Every instruction line carries a `; ADDR  <hex bytes>` comment and the byte
    gate proves the file rebuilds the ROM, so these are instruction boundaries
    beyond argument.  Directive lines (.byte/.ascii/.long/.fill) carry the same
    comment shape and are excluded by requiring the mnemonic not to start with a
    dot -- without that the corpus silently includes the data islands it is
    meant to be a null for."""
    out = []
    for l in open(src, encoding="utf-8").read().splitlines():
        body = l.split(";")[0]
        m = re.search(r";\s*([0-9A-F]{6})\s\s+((?:[0-9a-f]{2} )*[0-9a-f]{2})", l)
        if not m or not body.startswith("\t") or body.lstrip().startswith("."):
            continue
        out.append((int(m.group(1), 16), len(m.group(2).split())))
    return out


def proven_targets(lo, hi):
    """Branch/call targets in [lo,hi) of instructions the byte gate certifies.

    EXACT, not an upper bound: each address here is the operand of an
    instruction that is already transcribed and rebuilds to the right bytes.
    Cited at the address of the INSTRUCTION, never one byte past it."""
    out = {}
    for src, base, which in ((SRCA, A_BASE, "a"), (SRCB, B_BASE, "b")):
        for a, n in proven_instructions(src, base):
            dec = decode_at(a) if which == "a" else decode_b(a)
            if dec is None or dec[0] != n:
                continue
            for t in TC.branch_targets(dec[1]):
                if lo <= t < hi:
                    out.setdefault(t, []).append((a, dec[1]))
    return out


_tabb = None


def decode_b(addr, window=0x40):
    global _tabb
    if _tabb is None:
        h = hashlib.sha1(rom("b")).hexdigest()
        cd = os.environ.get("WSA1_CACHE_DIR", tempfile.gettempdir())
        cf = os.path.join(cd, "wsa1_prom_b_dectab.pkl")
        _tabb = None
        try:
            with open(cf, "rb") as f:
                got, tb = pickle.load(f)
            if got == h:
                _tabb = tb
        except Exception:
            pass
        if _tabb is None:
            _tabb = TC.decode_table(IMGB, B_BASE)
            try:
                with open(cf, "wb") as f:
                    pickle.dump((h, _tabb), f)
            except Exception:
                pass
    if addr in _tabb:
        return _tabb[addr]
    data = rom("b")
    o = addr - B_BASE
    if o < 0 or o >= len(data):
        return None
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(data[o:o + window])
        tmp = f.name
    try:
        out = subprocess.run([TC.UNIDASM, tmp, "-arch", "tlcs900",
                              "-basepc", hex(addr)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    for ln in out.splitlines():
        m = TC.LINE.match(ln)
        if m and int(m.group(1), 16) == addr:
            _tabb[addr] = (len(m.group(2).split()), m.group(3).strip())
            return _tabb[addr]
    return None


def thunk_slots():
    """{slot_addr: target} for every `jp addr24` slot of prom_b's directory."""
    b = rom("b")
    out = {}
    for slot in range(THUNK_LO - B_BASE, THUNK_HI - B_BASE, 4):
        if b[slot] == 0x1B:
            out[B_BASE + slot] = b[slot + 1] | b[slot + 2] << 8 | b[slot + 3] << 16
    return out


def thunk_entries(lo, hi):
    return sorted((s, t) for s, t in thunk_slots().items() if lo <= t < hi)


def far_calls(lo, hi):
    """`call addr24` / `jp addr24` sites in prom_a+prom_b targeting [lo,hi).

    Opcode-anchored, scanned at every byte offset: an UPPER BOUND, used only to
    SEED the descent, never quoted as a call count."""
    out = set()
    for blob in (rom("a"), rom("b")):
        for i in range(len(blob) - 3):
            if blob[i] in (0x1D, 0x1B):
                t = blob[i + 1] | blob[i + 2] << 8 | blob[i + 3] << 16
                if lo <= t < hi:
                    out.add(t)
    return out


def table_entry_seeds(lo, hi):
    """Every in-range entry of every table the PTRTAB rule frames."""
    out = set()
    for a, e in ptr_tables(lo, hi):
        for x in range(a, e, 4):
            t = w32(x)
            if lo <= t < hi:
                out.add(t)
    return out


def seeds(lo=LO, hi=HI):
    s = set(t for _, t in thunk_entries(lo, hi))
    s |= set(proven_targets(lo, hi))
    s |= far_calls(lo, hi)
    s |= table_entry_seeds(lo, hi)
    return s


# ---------------------------------------------------------------- descent ----
def descend(lo, hi, sd, block, seed_immediates=False):
    """Recursive descent that refuses to enter a barrier byte.

    ⚠ `seed_immediates` is OFF by default and that is a DELIBERATE departure
    from notes/prom_b_f65000_layout.py, which always seeds from every 32-bit
    immediate a decoded instruction loads.  In this span twenty of those
    immediates are TABLE BASES loaded with `ld XIY,0x00f87681` and friends, and
    seeding from them walks the descent straight into the tables: with them on,
    the walk claimed the third fallback list and 391 bytes of zero padding as
    instructions.  A `ld R,imm32` loads a POINTER; control reaches a computed
    address through `jp (R)` after a LOAD from the table, and that target is
    covered by the PTRTAB-entry seeds instead.  Pass 1 turns the flag on only to
    enumerate the immediates, never to classify them.

    Returns (bytes_reached, instruction_start_addresses)."""
    seen, starts, work = set(), set(), [x for x in sd if x not in block]
    while work:
        p = work.pop()
        while lo <= p < hi and p not in seen and p not in block:
            dec = decode_at(p)
            if dec is None:
                break
            n, txt = dec
            if any((p + i) in block for i in range(n)):
                break
            seen.update(range(p, p + n))
            starts.add(p)
            for t in TC.branch_targets(txt):
                if lo <= t < hi and t not in seen and t not in block:
                    work.append(t)
            if seed_immediates:
                for m in re.findall(r"0x00([0-9a-f]{6})", txt):
                    v = int(m, 16)
                    if lo <= v < hi and v not in seen and v not in block:
                        work.append(v)
            if is_flow_end(txt):
                break
            p += n
    return seen, starts


def gaps_of(lo, hi, seen, block):
    out, p = [], lo
    while p < hi:
        if p in seen or p in block:
            p += 1
            continue
        q = p
        while q < hi and q not in seen and q not in block:
            q += 1
        out.append((p, q))
        p = q
    return out


def decode_bounds(s, e):
    p, out = s, set()
    while p < e:
        dec = decode_at(p)
        if dec is None:
            return None
        out.add(p)
        p += dec[0]
    return out if p == e else None


def ends_in_flow_end(s, e):
    p, last = s, None
    while p < e:
        dec = decode_at(p)
        if dec is None:
            return False
        last = dec[1]
        p += dec[0]
    return p == e and last is not None and is_flow_end(last)


def selfconsistent(s, e, cand):
    p, bounds, ins = s, set(), []
    while p < e:
        dec = decode_at(p)
        if dec is None:
            return False
        bounds.add(p)
        ins.append((p, dec[0], dec[1]))
        p += dec[0]
    if p != e:
        return False
    for a, n, txt in ins:
        if txt.strip().startswith("db"):
            return False
        if not re.match(r"^(jr|jrl|calr)\b", txt):
            continue
        for t in TC.branch_targets(txt):
            if t not in bounds and t not in cand:
                return False
    return True


def accept(gaps, seen):
    ok, pending = {}, list(gaps)
    for _ in range(20):
        cand = set(seen)
        for s, e in pending:
            b = decode_bounds(s, e)
            if b:
                cand |= b
        grew, still = False, []
        for s, e in pending:
            good = selfconsistent(s, e, cand) and ends_in_flow_end(s, e)
            if good:
                ok[(s, e)] = 1
                p = s
                while p < e:
                    seen.add(p)
                    p += decode_at(p)[0]
                grew = True
            else:
                still.append((s, e))
        pending = still
        if not grew:
            break
    return ok, pending


# ------------------------------------------------------------------ build ----
_built = None


def loaded_immediates(starts):
    """Every 32-bit immediate that a DECODED instruction of the span loads.

    Read off the descent's own instruction START addresses, never off a byte
    scan: an address here is the operand of an instruction the walk actually
    reached, so it is cited at the address of the INSTRUCTION.  These are the
    module's own table bases -- `ld XIY,0x00f87681` and its fifteen siblings --
    and they are what pins the data objects the content rules cannot see."""
    out = {}
    for p in sorted(starts):
        dec = decode_at(p)
        if dec is None:
            continue
        for m in re.findall(r"0x00([0-9a-f]{6})", dec[1]):
            v = int(m, 16)
            if LO <= v < HI:
                out.setdefault(v, []).append((p, dec[1]))
    return out


def list_directories(lo=LO, hi=HI):
    """The (directory, list-area) pairs, DERIVED not guessed.

    A directory is a table the PTRTAB rule already framed, with >= 32 entries,
    whose entry[0] is exactly one byte past the table's own last byte -- and
    that spare byte is 0xFF in every case.  Its entries are the heads of
    0xFFFFFFFF-terminated lists that live in one contiguous area starting at
    entry[0]; the area ends where the list at max(entry) ends.
    Returns [(dir_lo, dir_hi, area_lo, area_hi)], half-open."""
    out = []
    for a, e in ptr_tables(lo, hi):
        n = (e - a) // 4
        if n < 32:
            continue
        ents = [w32(a + 4 * k) for k in range(n)]
        if ents[0] != e + 1 or not all(e + 1 <= v < hi for v in ents):
            continue
        _, end = walk_list(max(ents))
        out.append((a, e, ents[0], end))
    return out


def lone_lists(imms, taken):
    """A loaded immediate that is not code and whose word chain is a LIST.

    Three of the module's sixteen table bases are single 0xFFFFFFFF-terminated
    lists sitting on their own -- the fallback list of each directory.  They are
    4, 28 and 4 bytes long, far below any content rule's threshold, and only the
    instruction that loads them says they are there."""
    out = []
    for v in sorted(imms):
        if v in taken:
            continue
        items, end = walk_list(v, limit=16)
        if items is None:
            continue
        if not all(PTR_LO <= x < PTR_HI for x in items):
            continue
        out.append((v, end))
    return out


def classify_gap(a, e, imms):
    """What a run the descent never reached IS, said as weakly as the evidence.

    * `object`  -- it STARTS at an address the code loads into a register.  The
      instruction that loads it is the evidence; what its entries mean is not
      claimed here and the converter's header must not claim it either.
    * `pad`     -- every byte is the same value.  0x0E is `ret`, 0x00 and 0xFF
      are the two fill values this image uses; a uniform run shorter than a
      content rule's threshold is still uniform.
    * `unknown` -- anything else.  An honest hole.
    """
    if a in imms:
        return "object"
    if len(set(d()[a - A_BASE:e - A_BASE])) == 1:
        return "pad"
    return "unknown"


# ONE object whose extent the trailing-fill rule gets wrong, and why
#
# 0xF8679A is loaded at 0xF86696 and indexed by exactly the same BC that
# 0xF8671A is indexed by at 0xF8665E -- `ld C,(0x20b8) / extz BC /
# sll 0x02,BC` at 0xF86650-0xF86656 computes it once and nothing writes BC
# between the two uses.  0xF8671A is 32 words of 1<<k, so the index runs 0..31
# and 0xF8679A is 32 words too: 0xF8679A + 128 = 0xF86819+1, which is the first
# byte the descent proves is code.  Its entries 8..31 are ZERO, and zero is a
# legitimate mask -- so the 96 trailing zero bytes are TABLE, not padding, and
# trailing_uniform() must not take them away.  Pinned in selftest().
PARALLEL = {0xF8679A: 0xF8681A}

FILLVALS = (0x00, 0x0E, 0xFF)
RULE_MIN = {"fill": FILL0E_MIN, "zero": FILL00_MIN, "erased": FILLFF_MIN}


def trailing_uniform(a, e, n=8):
    """Start of the maximal run of one repeated fill byte that ENDS at `e`.

    An object's START is pinned by the instruction that loads its base; nothing
    generic pins its END.  What CAN be said is that a long run of one fill value
    running up to the next object is padding rather than table entries, so it is
    split off.  An interior run is NOT split off: the 30-byte word table at
    0xF86C8C holds eleven 0xFFFF `no entry` slots in the MIDDLE of it, and the
    loop at 0xF86C6C indexes past them."""
    v = byte(e - 1)
    if v not in FILLVALS:
        return e
    q = e
    while q > a and byte(q - 1) == v:
        q -= 1
    return q if e - q >= n and q > a else e


def head_pad(lo=LO):
    """The alignment pad this span opens with, if it has one.

    0xF85FF8 is the `ret` that closes DSP_WriteChannelRegs_Inner (already
    transcribed, prom_a/wsa1_prom_a.s), 0xF86000 is a 16-byte-aligned entry
    directory of six `jp`, and every byte between is 0x0E.  That is alignment
    padding, not seven return instructions, and it is asserted in selftest()."""
    q = lo
    while byte(q) == 0x0E:
        q += 1
    return (lo, q) if q > lo and q % 16 == 0 else None


def build(lo=LO, hi=HI):
    """Two passes.

    PASS 1 runs the content rules as barriers and descends WITH immediate
    seeding, only to learn which 32-bit immediates the code loads.  PASS 2 turns
    the eighteen table bases that pass 1 found into derived barriers -- list
    directories, list areas, lone lists, untyped objects -- and descends again
    WITHOUT immediate seeding.  It has to be two passes: the descent seeds itself
    from loaded immediates, so without the derived barrier it walks INTO the very
    tables the immediates name, and that is what made a first draft of this
    script report 42 bytes of the third fallback list, and 391 bytes of zero
    padding, as instructions."""
    global _built
    if _built is not None:
        return _built
    block1 = barriers(lo, hi)
    seen1, starts1 = descend(lo, hi, sorted(seeds(lo, hi)), block1,
                             seed_immediates=True)
    imms = loaded_immediates(starts1)

    dirs = list_directories(lo, hi)
    derived, taken = {}, set()
    for dlo, dhi, alo, ahi in dirs:
        derived[(alo, ahi)] = "list_area"
        taken |= set(range(dlo, dhi)) | set(range(alo, ahi))
    # a framed pointer table whose base the code LOADS and whose next word is
    # the 0xFFFFFFFF terminator is a LIST, and the terminator belongs to it
    for a, e in ptr_tables(lo, hi):
        if a in imms and not (set(range(a, e)) & taken) and w32(e) == 0xFFFFFFFF:
            derived[(a, e + 4)] = "list"
            taken |= set(range(a, e + 4))
    for a, e in ptr_tables(lo, hi):
        taken |= set(range(a, e))
    for a, e in lone_lists(imms, taken):
        derived[(a, e)] = "list"
        taken |= set(range(a, e))
    hp = head_pad(lo)
    if hp:
        derived[hp] = "pad"
        taken |= set(range(*hp))

    block2 = set(block1)
    for (a, e) in derived:
        block2 |= set(range(a, e))
    seen, starts = descend(lo, hi, sorted(seeds(lo, hi)), block2)
    gaps = gaps_of(lo, hi, seen, block2)
    ok, pend = accept(gaps, seen)
    # widen the table-base census with pass 2's own instruction boundaries and
    # with a linear decode of each residue run that decodes exactly -- the five
    # bytes at 0xF86B88 are `ld XIY,0x00f86bb8` and nothing else, and without
    # this the fourth of the four 8-byte curve tables has no anchor at all
    extra = set(starts)
    for a, e in list(pend) + list(ok):
        b = decode_bounds(a, e)
        if b:
            extra |= b
    imms = loaded_immediates(starts1 | extra)
    # an object's extent stops at the next table base, the next byte the descent
    # proved is code, or the next framed object -- never at a fill run, because
    # a fill run can be the INSIDE of the object (0xF86C8C holds eleven 0xFFFF
    # `no entry` slots in its middle)
    hard = sorted(set(imms) | seen | {a for (a, e) in derived}
                  | {a for a, e in ptr_tables(lo, hi)} | {hi})
    for v in sorted(imms):
        if v in seen or v in taken:
            continue
        nxt = min(x for x in hard if x > v)
        e = PARALLEL[v] if v in PARALLEL else trailing_uniform(v, nxt)
        if e > v:
            derived[(v, e)] = "object"
            taken |= set(range(v, e))
    kind = ["data"] * (hi - lo)
    for a in seen:
        if lo <= a < hi:
            kind[a - lo] = "code"
    for (a, e) in ok:
        for x in range(a, e):
            kind[x - lo] = "code"
    conflicts = []
    for name, f in RULES:
        for a, e in f(lo, hi):
            for x in range(a, e):
                if kind[x - lo] == "code":
                    conflicts.append(x)
                kind[x - lo] = name
    for (a, e), nm in sorted(derived.items()):
        for x in range(a, e):
            if kind[x - lo] == "code":
                conflicts.append(x)
            kind[x - lo] = nm
    # every residue run is cut at each interior table base, then classified; an
    # object run gives its trailing fill back to the padding it belongs to
    cutset = set(a for (a, e) in derived)
    for s0, e0 in pend:
        if all(x in taken for x in range(s0, e0)):
            continue          # a derived object now covers this residue run
        cuts = sorted({s0, e0} | {v for v in imms if s0 < v < e0})
        for i in range(len(cuts) - 1):
            a, e = cuts[i], cuts[i + 1]
            nm = classify_gap(a, e, imms)
            cutset.add(a)
            for x in range(a, e):
                kind[x - lo] = nm
    segs, p = [], 0
    while p < hi - lo:
        q = p + 1
        while q < hi - lo and kind[q] == kind[p] and (lo + q) not in cutset:
            q += 1
        segs.append((kind[p], lo + p, q - p))
        p = q
    # a content-fill label that survived on FEWER bytes than its own threshold is
    # the remnant of a run a derived object ate; call it what it is
    segs = [((classify_gap(a, a + n, imms) if k in RULE_MIN and n < RULE_MIN[k]
              else k), a, n) for k, a, n in segs]
    out, i = [], 0
    while i < len(segs):
        k, a, n = segs[i]
        while (i + 1 < len(segs) and segs[i + 1][0] == k
               and segs[i + 1][1] not in cutset):
            n += segs[i + 1][2]
            i += 1
        out.append((k, a, n))
        i += 1
    segs = out
    _built = (segs, conflicts, pend, ok, seen, imms, dirs, derived)
    return _built


# ------------------------------------------------------------------- null ----
def source_text(src, rev=None):
    """The image's text, from the working tree or from a revision.

    ⚠ THE IMAGE ON BOTH SIDES.  `src` is what image_path() returned, which since
    the split is the materialised expansion `notes/.image-wsa1_prom_a.s` -- a
    derived file that is not committed, so `git show <rev>:notes/.image-...`
    asked for something no revision has ever held.  image_text_at_rev resolves
    the `.include`s THROUGH GIT, so the calibration corpus is the same object as
    the working-tree one."""
    if rev is None:
        return open(src, encoding="utf-8").read()
    return image_text_at_rev(ROOT, "prom_a/wsa1_prom_a.s", rev)


def proven_code_runs(rev=None):
    """Maximal runs of PROVEN instruction text in prom_a/wsa1_prom_a.s."""
    seq = []
    for l in source_text(SRCA, rev).splitlines():
        body = l.split(";")[0]
        m = re.search(r";\s*([0-9A-F]{6})\s\s", l)
        ok = bool(m) and body.startswith("\t") and not body.lstrip().startswith(".")
        seq.append(int(m.group(1), 16) if ok else None)
    runs, cur = [], []
    for a in seq:
        if a is None or (cur and a <= cur[-1]):
            if len(cur) > 1:
                runs.append((cur[0], cur[-1]))
            cur = []
        if a is not None:
            cur.append(a)
    if len(cur) > 1:
        runs.append((cur[0], cur[-1]))
    return runs


def null(rev=None):
    runs = proven_code_runs(rev)
    tot = sum(e - s for s, e in runs)
    print("NULL corpus: every maximal run of PROVEN instruction text in")
    print("prom_a/wsa1_prom_a.s @ %s -- %d runs, %d bytes.  A rule that fires"
          % (rev or "WORKING TREE", len(runs), tot))
    print("inside one of these runs is a FALSE POSITIVE.")
    if rev is None:
        print("  ⚠ this corpus GROWS as rounds convert code; quote it with --rev REV.")
    tests = [("fill0E >= %d" % FILL0E_MIN, lambda a, b: fill0e_runs(a, b)),
             ("fill0E >=  8 (rejected)", lambda a, b: fill0e_runs(a, b, 8)),
             ("fill0E >=  4 (rejected)", lambda a, b: fill0e_runs(a, b, 4)),
             ("fill00 >= %d" % FILL00_MIN, lambda a, b: fill00_runs(a, b)),
             ("fill00 >= 16 (rejected)", lambda a, b: fill00_runs(a, b, 16)),
             ("fillFF >= %d" % FILLFF_MIN, lambda a, b: fillff_runs(a, b)),
             ("fillFF >= 16 (rejected)", lambda a, b: fillff_runs(a, b, 16)),
             ("ptrtab >= %d" % PTR_MIN, lambda a, b: ptr_tables(a, b)),
             ("ptrtab >=  2 (rejected)", lambda a, b: ptr_tables(a, b, 2)),
             ("ident  >= %d" % IDENT_MIN, lambda a, b: ident_runs(a, b)),
             ("ident  >=  8 (rejected)", lambda a, b: ident_runs(a, b, 8)),
             ("ascii  >= %d" % ASCII_MIN, lambda a, b: ascii_runs(a, b)),
             ("ascii  >= 10 (rejected)", lambda a, b: ascii_runs(a, b, 10)),
             ("ascii  >=  8 (rejected)", lambda a, b: ascii_runs(a, b, 8))]
    res = {}
    for name, f in tests:
        hits = []
        for s, e in runs:
            hits += f(s, e)
        res[name.split()[0] + name.split()[1] + name.split()[2]] = len(hits)
        print("  %-24s false positives: %3d   %s"
              % (name, len(hits),
                 " ".join("0x%06X(%d)" % (a, b - a) for a, b in hits[:4])))
    print("  The `(rejected)` rows are printed so each threshold is visible as a")
    print("  MEASUREMENT rather than a preference.")
    print()
    print("ADJUDICATION of every hit of the CHOSEN thresholds.  A hit is not")
    print("automatically a rule failure: the corpus is `what the transcription")
    print("emits as instruction lines`, and this tree emits padding, blank-fill")
    print("and three jump tables that way.  Two mechanical tests separate them:")
    print("  UNIFORM   -- every .s line covering the hit has the same mnemonic")
    print("               text, i.e. the run is pad written out as N `nop`/`ret`")
    print("  DISPATCH  -- the hit address is the imm32 of an `add XBC,imm32 /")
    print("               ld XBC,(XBC) / jp (xbc)` within 12 bytes above it")
    print("Anything neither is a GENUINE false positive.")
    lines = {}
    for l in source_text(SRCA).splitlines():
        body = l.split(";")[0]
        m = re.search(r";\s*([0-9A-F]{6})\s\s", l)
        if m and body.startswith("\t"):
            lines[int(m.group(1), 16)] = body.strip()
    disp = set(t for _, t, _ in misframed_jump_tables())
    genuine = 0
    for name, f in [("fill0E", fill0e_runs), ("fill00", fill00_runs),
                    ("fillFF", fillff_runs), ("ptrtab", ptr_tables),
                    ("ident", ident_runs), ("ascii", ascii_runs)]:
        hits = []
        for s0, e0 in runs:
            hits += f(s0, e0)
        for a, e in hits:
            txt = set(lines[x] for x in range(a, e) if x in lines)
            uni = len(txt) == 1
            dsp = any(d0 in disp for d0 in range(a - 12, a + 1))
            tag = ("UNIFORM" if uni else ("DISPATCH" if dsp else "GENUINE"))
            if tag == "GENUINE":
                genuine += 1
            print("  %-7s 0x%06X(%4d)  %-8s  %s"
                  % (name, a, e - a, tag, sorted(txt)[0][:44] if txt else ""))
    print("  GENUINE false positives at the chosen thresholds: %d" % genuine)
    res["genuine"] = genuine
    return res


# --------------------------------------------------------------- readings ----
def l1_tables():
    """The three parallel 192-entry list directories, read out of the ROM.

    Each is a table of 4-byte little-endian pointers; entry[k] is the head of a
    0xFFFFFFFF-terminated LIST of prom_b thunk addresses.  The structure is
    self-checking three ways and the checks are in selftest():
      * entry[0] == (table end) + 1 for all three, and the one byte between is
        0xFF;
      * entry[191] == entry[190] in all three;
      * every entry is >= entry[0] and < the start of the next object.
    Returned as [(base, [entries])]."""
    out = []
    for base in (0xF87681, 0xF87E91, 0xF88EC1):
        out.append((base, [w32(base + 4 * k) for k in range(192)]))
    return out


def walk_list(head, limit=64):
    """The 0xFFFFFFFF-terminated list at `head`: ([entries], end_address).

    Returns (None, head) when no terminator appears within `limit` words -- so a
    caller can tell a real list from a table that merely happens to start here.
    The 192-entry directories ARE followed by a 0xFFFFFFFF, so the limit is what
    keeps `lone_lists()` from swallowing one; it is set to 16 there and to 64
    only for the deliberate walk of a directory's own last list."""
    out, p = [], head
    while p < HI and len(out) <= limit:
        v = w32(p)
        p += 4
        if v == 0xFFFFFFFF:
            return out, p
        out.append(v)
    return None, head


def handler_table():
    """The 256-entry handler table at 0xF86EC1, and the two bases that index it.

    ⚠ CORRECTED WHILE THIS SCRIPT WAS BEING WRITTEN.  A first reading called it
    "eight tables of 32", because 0xF86EC1 + 8*32*4 lands exactly on 0xF872C1
    and 0xF86F41 is 32 entries in.  It is not eight tables.  The two accessors
    bound their index before using it --
        0xF864EC  ld XIY,0x00f86ec1   guarded by `cp L,0x2f / jr UGT` (0xF864E7)
        0xF86520  ld XIY,0x00f86ec1   guarded by `cp L,0x2f / jr UGT` (0xF8651B)
        0xF864CE  ld XIY,0x00f86f41   guarded by `cp L,0xdf / jr UGT` (0xF864C9)
        0xF86535  ld XIY,0x00f86f41   guarded by `cp L,0xdf / jr UGT` (0xF86530)
        0xF86215  ld XBC,0x00f86f41   guarded by `cp C,0xdf / jr UGT` (0xF8620B)
    -- so one index space is 0..0x2F from 0xF86EC1 (48 entries) and the other
    0..0xDF from 0xF86F41 (224 entries), and 0xF86F41 is entry 32 of the first.
    The two ranges OVERLAP on entries 32-47.  What the ROM pins is the union:
    0xF86EC1 .. 0xF86EC1+0x400 = 0xF872C1, which is exactly the address that
    fills every unused slot AND the first byte after the run.
    Returns (base, [entries], default_target)."""
    base = 0xF86EC1
    return base, [w32(base + 4 * k) for k in range(256)], 0xF872C1


def hot_thunk_callsites():
    """PROVEN call sites of the eight slots of the T_F40F34 run, by target.

    Exact: every site here is an instruction the byte gate certifies, and it is
    reported at the address of the INSTRUCTION.  Compare with the frontier
    tool's opcode-anchored counts, which are upper bounds."""
    slots = thunk_slots()
    run = [s for s in sorted(slots) if 0xF40F34 <= s <= 0xF40F94]
    hits = {s: [] for s in run}
    for src, which in ((SRCA, "a"), (SRCB, "b")):
        for a, n in proven_instructions(src, 0):
            dec = decode_at(a) if which == "a" else decode_b(a)
            if dec is None or dec[0] != n:
                continue
            for t in TC.branch_targets(dec[1]):
                if t in hits:
                    hits[t].append((which, a, dec[1]))
    return run, slots, hits


def misframed_jump_tables():
    """Computed-jump tables that the CURRENT transcription emits as instructions.

    A by-product of the null calibration, and the reason the PTRTAB threshold is
    5 rather than 3.  At threshold 5 the rule fires TWICE inside the proven-code
    corpus, and both hits sit immediately after

        add XBC,<imm32>      E9 C8 <imm32>
        ld  XBC,(XBC)        A1 21
        jp  (xbc)            B1 D8

    whose immediate IS the address of the run the rule framed.  So neither is a
    false positive: they are jump tables that prom_a/wsa1_prom_a.s currently
    writes out as `jr mi, 0x15` and friends.

    ⚠ notes/prom_a_jumptables.py does NOT find these.  It matches the OTHER
    spelling of the same dispatch, `jp T,XBC`, and reports 13 tables; this shape
    is a different opcode pair and is invisible to it.  Reported, not fixed --
    that file belongs to another lane.

    Entry count is NOT guessed: it is read out of the reader's own `cp BC,n`
    bound, matched by TEXT within 30 bytes above the `add`.  ⚠ Weaker than
    notes/prom_a_jumptables.py's version of the same idea, which requires the
    bound instruction to end exactly on the next one; that stricter form does
    not fire here because this spelling puts `jrl UGT` and `sll 0x02,BC` between
    the bound and the `add`.  A `?` means no bound was matched and the count is
    NOT established -- do not fill it in by eye."""
    a = rom("a")
    out = []
    pat = bytes([0xE9, 0xC8])
    i = 0
    while True:
        i = a.find(pat, i + 1)
        if i < 0:
            break
        if a[i + 6:i + 10] != bytes([0xA1, 0x21, 0xB1, 0xD8]):
            continue
        tbl = int.from_bytes(a[i + 2:i + 6], "little")
        rd = A_BASE + i
        if tbl != rd + 10:
            continue
        # the entry count is the READER'S OWN bound, never a guess: scan back
        # for the `cp BC,n` whose length lands exactly on the `add`
        n = None
        for k in range(2, 30):
            dec = decode_at(rd - k)
            if dec:
                m = re.match(r"^cp BC,(0x[0-9a-f]+|\d+)$", dec[1])
                if m:
                    n = int(m.group(1), 0) + 1
                    break
        out.append((rd, tbl, n))
    return out


def show_misframed():
    rows = misframed_jump_tables()
    runs = proven_code_runs()

    def inside(t):
        return any(s <= x < e for s, e in runs for x in (t, t + 4, t + 8))
    print("computed-jump tables of the `jp (xbc)` shape in prom_a: %d" % len(rows))
    print("  reader     table     entries  transcribed as instructions today?")
    for rd, tbl, n in rows:
        print("  0x%06X  0x%06X  %s      %s"
              % (rd, tbl, ("%3d" % n) if n else "  ?",
                 "YES -- MIS-FRAMED" if inside(tbl) else "no"))
    bad = [r for r in rows if inside(r[1])]
    print()
    print("%d of the %d have their table INSIDE the proven-code corpus, i.e. the"
          % (len(bad), len(rows)))
    print("transcription writes those table entries out as instructions today:")
    for rd, tbl, n in bad:
        print("   reader 0x%06X  table 0x%06X  %s entries" % (rd, tbl, n or "?"))
    print("notes/prom_a_jumptables.py reports 13 tables and finds none of these")
    print("three: it matches the `jp T,XBC` spelling of the same dispatch.")
    return 0


# ------------------------------------------------------------------- main ----
def rank():
    import prom_a_module_frontier as MF
    rows = sorted(MF.survey(), key=lambda r: -r["refs"])
    print("prom_a thunk runs with unconverted targets, ranked by REFERENCE COUNT")
    print("(re-derived from notes/prom_a_module_frontier.py; refs are that")
    print(" tool's opcode-anchored UPPER BOUND -- they rank, they do not count)")
    print("  run                  slots  unc   extent   refs   targets")
    for r in rows[:14]:
        print("  T_%06X-T_%06X %4d %4d %8d %6d   0x%06X-0x%06X%s"
              % (r["first"], r["last"], r["n"], r["nunc"], r["extent"],
                 r["refs"], r["lo"], r["hi"],
                 "   <== this lane" if LO <= r["lo"] < HI else ""))
    return 0


def show_lists():
    for base, ents in l1_tables():
        lo, hi = min(ents), max(ents)
        _, end = walk_list(hi)
        n_empty = sum(1 for e in ents if walk_list(e)[0] == [])
        print("list directory 0x%06X: 192 entries, 0x%06X-0x%06X, lists in "
              "0x%06X-0x%06X" % (base, base, base + 767, lo, end - 1))
        print("   byte at 0x%06X (table end + 1) = 0x%02X;  entry[0] = 0x%06X"
              % (base + 768, byte(base + 768), ents[0]))
        print("   entry[190] = 0x%06X   entry[191] = 0x%06X   empty lists: %d/192"
              % (ents[190], ents[191], n_empty))
        seen = set()
        for k, e in enumerate(ents):
            if e in seen:
                continue
            seen.add(e)
            items, _ = walk_list(e)
            if items:
                print("     [%3d] 0x%06X -> %s" % (k, e, " ".join("%06X" % v for v in items)))
        print()
    return 0


def show_dispatch():
    base, ents, dflt = handler_table()
    live = [(k, v) for k, v in enumerate(ents) if v != dflt]
    print("handler table 0x%06X-0x%06X   256 entries, %d live, %d = the "
          "do-nothing stub 0x%06X" % (base, base + 1023, len(live),
                                      256 - len(live), dflt))
    print("the stub is the FIRST BYTE AFTER the run: 0x%06X + 0x400 = 0x%06X"
          % (base, base + 0x400))
    print("index space A: base 0x%06X, bound 0x2F (48 entries)" % base)
    print("index space B: base 0x%06X = entry 32, bound 0xDF (224 entries)"
          % (base + 0x80))
    print()
    print("live entries (k is the index from 0x%06X):" % base)
    for k, v in live:
        tag = ""
        if THUNK_LO <= v < THUNK_HI:
            b = rom("b")
            ok = all(b[v - B_BASE + 4 * j] == 0x1B for j in range(3))
            tag = "  thunk slots %s+0/+4/+8%s" % ("T_%06X" % v,
                                                 "" if ok else "  (NOT 3 jp slots)")
        print("   [%3d] 0x%06X%s" % (k, v, tag))
    return 0


def show_callsites():
    run, slots, hits = hot_thunk_callsites()
    for s in run:
        h = hits[s]
        by = {}
        for which, a, txt in h:
            by[which] = by.get(which, 0) + 1
        print("T_%06X -> 0x%06X   proven sites: %d  (%s)"
              % (s, slots[s], len(h),
                 ", ".join("%s:%d" % (k, v) for k, v in sorted(by.items())) or "none"))
        for which, a, txt in h[:6]:
            print("      prom_%s 0x%06X  %s" % (which, a, txt))
        if len(h) > 6:
            print("      ... %d more" % (len(h) - 6))
    return 0


def show_residue():
    segs, conflicts, pend, ok, seen, imms, dirs, derived = build()
    print("runs that are neither code nor a framed object: %d (%d bytes)"
          % (len(pend), sum(e - s for s, e in pend)))
    for s, e in pend:
        raw = d()[s - A_BASE:e - A_BASE]
        for i in range(0, min(len(raw), 256), 16):
            print("   %06X  %-47s |%s|"
                  % (s + i, raw[i:i + 16].hex(" "),
                     "".join(chr(c) if 32 <= c < 127 else "." for c in raw[i:i + 16])))
        if len(raw) > 256:
            print("   ... %d more bytes" % (len(raw) - 256))
        print()
    return 0


def show_barrier():
    block = barriers(LO, HI)
    sd = sorted(seeds(LO, HI))
    wb = descend(LO, HI, sd, block)[0]
    nb = descend(LO, HI, sd, set())[0]
    print("code walk WITH the barrier:    %6d bytes (%.1f%% of %d)"
          % (len(wb), 100.0 * len(wb) / (HI - LO), HI - LO))
    print("code walk WITHOUT the barrier: %6d bytes (%.1f%%)"
          % (len(nb), 100.0 * len(nb) / (HI - LO)))
    print("of those, %d bytes are inside an object a content rule framed --"
          % len(nb & block))
    print("that is what the barrier removes.")
    return 0


def main():
    a = sys.argv[1:]
    if "--null" in a:
        rev = a[a.index("--rev") + 1] if "--rev" in a else None
        null(rev)
        return 0
    if "--misframed" in a:
        return show_misframed()
    if "--rank" in a:
        return rank()
    if "--lists" in a:
        return show_lists()
    if "--dispatch" in a:
        return show_dispatch()
    if "--callsites" in a:
        return show_callsites()
    if "--conflicts" in a:
        segs, conflicts, pend, ok, seen, imms, dirs, derived = build()
        print("descent bytes reclaimed by a content rule or a derived object: "
              "%d  (MUST be 0)" % len(conflicts))
        for x in conflicts[:80]:
            print("  0x%06X" % x)
        return 0
    if "--residue" in a:
        return show_residue()
    if "--barrier" in a:
        return show_barrier()
    if "--selftest" in a:
        return selftest()
    segs, conflicts, pend, ok, seen, imms, dirs, derived = build()
    if "--python" in a:
        print("LAYOUT = [")
        for k, s, n in segs:
            print('    ("%s", 0x%06X, 0x%04X),' % (k, s, n))
        print("]")
        return 0
    tot = {}
    for k, s, n in segs:
        print("  %-6s 0x%06X-0x%06X  %6d" % (k, s, s + n - 1, n))
        tot[k] = tot.get(k, 0) + n
    print("  ---- " + "  ".join("%s %d" % (k, v) for k, v in sorted(tot.items())))
    print("  substantive %d of %d"
          % (sum(v for k, v in tot.items() if k not in ("fill",)), HI - LO))
    print("  segments %d   accepted self-consistent runs %d   barrier conflicts %d"
          % (len(segs), len(ok), len(conflicts)))
    return 0


def selftest():
    """Every quantified claim this lane makes, re-derived from the ROM.

    ★ The LAST element is checked as well as the first, everywhere it means
    anything: the last segment of the layout, the last entry of each of the
    three 192-entry directories, the last entry of the 256-entry handler table,
    and the last slot of each of the two thunk runs."""
    fails = []

    def ck(msg, got, want):
        ok = got == want
        print("  %-66s %-24s %s"
              % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
        if not ok:
            fails.append(msg)
        return ok

    n = [0]

    def chk(*a):
        n[0] += 1
        return ck(*a)

    segs, conflicts, pend, ok, seen, imms, dirs, derived = build()

    print("-- the layout covers the span exactly")
    chk("first segment starts at LO", "0x%06X" % segs[0][1], "0x%06X" % LO)
    last = segs[-1]
    chk("LAST segment ends at HI-1", "0x%06X" % (last[1] + last[2] - 1),
        "0x%06X" % (HI - 1))
    chk("LAST segment is (kind, base, size)",
        (last[0], "0x%06X" % last[1], last[2]), ("fill", "0xF8969B", 357))
    chk("every byte of the LAST segment is 0x0E",
        sorted(set(d()[last[1] - A_BASE:last[1] + last[2] - A_BASE])), [0x0E])
    chk("the byte before the LAST segment is not 0x0E",
        "0x%02X" % byte(last[1] - 1), "0x00")
    p = LO
    contig = True
    for k, a, sz in segs:
        if a != p:
            contig = False
        p = a + sz
    chk("segments are contiguous (no gaps, no overlaps)", contig, True)
    chk("segments cover the whole span", "0x%06X" % p, "0x%06X" % HI)
    chk("barrier conflicts", len(conflicts), 0)
    chk("segment count", len(segs), 45)
    chk("bytes assigned", sum(sz for _, _, sz in segs), HI - LO)

    print("-- the head is alignment pad, not seven return instructions")
    hp = head_pad()
    chk("head pad", ("0x%06X" % hp[0], hp[1] - hp[0]), ("0xF85FF9", 7))
    chk("every byte of the head pad is 0x0E",
        sorted(set(d()[hp[0] - A_BASE:hp[1] - A_BASE])), [0x0E])
    chk("it ends on the 16-byte-aligned module entry", "0x%06X" % hp[1],
        "0xF86000")

    print("-- the three 192-entry list directories")
    for base, ents in l1_tables():
        chk("0x%06X entry[0] == table end + 1" % base,
            "0x%06X" % ents[0], "0x%06X" % (base + 768 + 1))
        chk("0x%06X the spare byte at the table end is 0xFF" % base,
            "0x%02X" % byte(base + 768), "0xFF")
        chk("0x%06X entry[191] == entry[190]  (LAST entry)" % base,
            "0x%06X" % ents[191], "0x%06X" % ents[190])
        chk("0x%06X the LAST entry's list is empty" % base,
            walk_list(ents[191])[0], [])
        chk("0x%06X all 192 entries lie inside the span" % base,
            all(LO <= e < HI for e in ents), True)
        chk("0x%06X every list is 0xFFFFFFFF-terminated" % base,
            all(walk_list(e)[0] is not None for e in ents), True)

    print("-- the consumer's own bound proves the directories are 192 long")
    chk("0xF869FB decodes as the id bound", decode_at(0xF869FB)[1], "cp L,0xbf")
    chk("0xF869FE takes the skip branch above it",
        decode_at(0xF869FE)[1], "jr UGT,0xf86a61")
    chk("0xBF + 1 == the directory entry count", 0xBF + 1, 192)
    chk("0xF86A00-0xF86A03 is the directory lookup",
        [decode_at(0xF86A00)[1], decode_at(0xF86A03)[1]],
        ["sla 0x02,HL", "ld XHL,(XIX+HL)"])

    print("-- the 256-entry handler table")
    hbase, hents, dflt = handler_table()
    chk("handler table base", "0x%06X" % hbase, "0xF86EC1")
    chk("base + 256 entries == the do-nothing stub",
        "0x%06X" % (hbase + 0x400), "0x%06X" % dflt)
    chk("LAST entry (index 255) is the stub", "0x%06X" % hents[255],
        "0x%06X" % dflt)
    chk("entries equal to the stub", sum(1 for v in hents if v == dflt), 81)
    chk("live entries", sum(1 for v in hents if v != dflt), 175)
    chk("every entry is a valid CPU-1 ROM address",
        all(PTR_LO <= v < PTR_HI for v in hents), True)
    b = rom("b")
    live = [v for v in hents if v != dflt]
    trip = [v for v in live
            if THUNK_LO <= v < THUNK_HI - 8
            and all(b[v - B_BASE + 4 * j] == 0x1B for j in range(3))]
    chk("live entries naming three consecutive `jp` directory slots",
        len(trip), 172)
    odd = sorted(set(v for v in live if v not in trip))
    chk("the three that do not", ["0x%06X" % v for v in odd],
        ["0xF406C4", "0xF406CC", "0xF406DC"])
    chk("and each of those +0..+11 is twelve 0x0E (empty directory slots)",
        sorted(set(x for v in odd
                   for x in b[v - B_BASE:v - B_BASE + 12])), [0x0E])
    chk("the stub is four `jr` onto one `ret`",
        [decode_at(x)[1] for x in (0xF872C1, 0xF872C3, 0xF872C5, 0xF872C7,
                                   0xF872C9)],
        ["jr T,0xf872c9", "jr T,0xf872c9", "jr T,0xf872c9", "jr T,0xf872c9",
         "ret"])
    chk("index-space A is bounded at 0x2F", decode_at(0xF864E7)[1], "cp L,0x2f")
    chk("index-space B is bounded at 0xDF", decode_at(0xF864C9)[1], "cp L,0xdf")

    print("-- the queue record and the three producers")
    chk("0xF86AA3 caps the write index", decode_at(0xF86AA3)[1],
        "cp (0x60f004),0x00fb")
    chk("0xF86AB6 stores DE at record+0", decode_at(0xF86AB6)[1], "ld (XHL),DE")
    chk("0xF86AB8 stores WA at record+2", decode_at(0xF86AB8)[1],
        "ld (XHL+0x02),WA")
    chk("0xF86ABB writes the 0xFF end marker at record+4",
        decode_at(0xF86ABB)[1], "ld (XHL+0x04),0xff")
    chk("0xF86ABF advances the index by 4", decode_at(0xF86ABF)[1],
        "add (0x60f004),0x0004")
    chk("the consumer reads the same three fields",
        [decode_at(0xF869F5)[1], decode_at(0xF86A08)[1], decode_at(0xF86A0B)[1]],
        ["ld L,(XIY)", "ld WA,(XIY+0x01)", "ld C,(XIY+0x03)"])
    chk("and steps by the same 4", decode_at(0xF86A61)[1],
        "add (0x20b2),0x0004")

    print("-- the thunk runs the frontier ranked")
    th = thunk_entries(LO, HI)
    chk("thunk targets landing in the span", len(th), 24)
    chk("thunk targets the descent did NOT reach",
        [t for _, t in th if t not in seen], [])
    sl = thunk_slots()
    chk("FIRST slot of the hot run",
        "T_F40F34->0x%06X" % sl[0xF40F34], "T_F40F34->0xF86066")
    chk("LAST slot of the hot run",
        "T_F40F50->0x%06X" % sl[0xF40F50], "T_F40F50->0xF860A6")
    chk("FIRST slot of the second run",
        "T_F40F58->0x%06X" % sl[0xF40F58], "T_F40F58->0xF8659B")
    chk("LAST slot of the second run",
        "T_F40F94->0x%06X" % sl[0xF40F94], "T_F40F94->0xF86C5B")
    run, slots, hits = hot_thunk_callsites()
    chk("PROVEN call sites of T_F40F3C (converted code only, a LOWER bound)",
        len(hits[0xF40F3C]), 58)
    chk("PROVEN call sites of the whole T_F40F34 run",
        sum(len(hits[x]) for x in sorted(hits) if x <= 0xF40F50), 88)

    print("-- the twenty table bases")
    chk("table bases the code loads", len(imms), 20)
    chk("FIRST table base", "0x%06X" % min(imms), "0xF8671A")
    chk("LAST table base", "0x%06X" % max(imms), "0xF89671")
    chk("0xF8671A is 32 words of 1<<k, k=0..31",
        [w32(0xF8671A + 4 * k) for k in range(32)] ==
        [1 << k for k in range(32)], True)
    chk("its LAST word is 1<<31", "0x%08X" % w32(0xF8671A + 4 * 31),
        "0x80000000")
    chk("0xF8679A is indexed by the SAME BC as 0xF8671A",
        [decode_at(x)[1] for x in (0xF86650, 0xF86656, 0xF86659, 0xF8665E,
                                   0xF86696, 0xF8669B)],
        ["ld C,(0x20b8)", "sll 0x02,BC", "ld XWA,0x00f8671a", "add WA,BC",
         "ld XWA,0x00f8679a", "add WA,BC"])
    chk("so it is 32 words too, and ends on the next code byte",
        "0x%06X" % (0xF8679A + 128), "0x%06X" % 0xF8681A)
    chk("its entries 8..31 are zero (a legitimate mask, not padding)",
        sorted(set(w32(0xF8679A + 4 * k) for k in range(8, 32))), [0])
    chk("its LAST non-zero entry is 1<<24", "0x%08X" % w32(0xF8679A + 4 * 7),
        "0x01000000")
    chk("0xF86CC9 by contrast really is 2 bytes -- its reader says so",
        [decode_at(0xF86B24)[1], decode_at(0xF86B29)[1], decode_at(0xF86B2E)[1],
         decode_at(0xF86B33)[1]],
        ["ld XIX,0x00f86cc9", "ld XBC,0x00000002", "cp A,(XIX+)",
         "djnz BC,0xf86b2e"])

    print("-- the two 32-byte index maps, sized by their own readers")
    chk("0xF86E81's reader bounds the index at 0x1F",
        [decode_at(0xF86CB4)[1], decode_at(0xF86CB7)[1], decode_at(0xF86CBB)[1],
         decode_at(0xF86CC0)[1]],
        ["cp L,0x1f", "jr ULE,0xf86cbb", "ld XIY,0x00f86e81", "add IY,HL"])
    chk("0x1F + 1 == 32, so 0xF86E81 ends where 0xF86EA1 begins",
        "0x%06X" % (0xF86E81 + 32), "0xF86EA1")
    chk("0xF86EA1 is read with the byte 0xF86E81 produced",
        [decode_at(0xF86CC4)[1], decode_at(0xF8638F)[1], decode_at(0xF86388)[1]],
        ["ld (0x2076),A", "ld A,(0x2078)", "ld XHL,0x00f86ea1"])
    chk("0xF86EA1 + 32 == the handler table", "0x%06X" % (0xF86EA1 + 32),
        "0xF86EC1")

    print("-- the null calibration, and what it turned up")
    corp = proven_code_runs()
    chk("null corpus runs / bytes",
        (len(corp), sum(e - a for a, e in corp)), (10509, 264982))
    hits = []
    for a2, e2 in corp:
        hits += ptr_tables(a2, e2)
    chk("PTRTAB >= 5 hits inside the proven-code corpus", len(hits), 2)
    disp = set(t for _, t, _ in misframed_jump_tables())
    chk("every one of them is a `jp (xbc)` dispatch table",
        all(a2 in disp for a2, _ in hits), True)
    chk("PTRTAB >= 3 would have 8 hits, 5 of them genuine noise",
        len([1 for a2, e2 in corp for _ in ptr_tables(a2, e2, 3)]), 8)
    mis = [r for r in misframed_jump_tables()
           if any(s2 <= x < e2 for s2, e2 in corp
                  for x in (r[1], r[1] + 4, r[1] + 8))]
    chk("jump tables the tree currently emits as instructions", len(mis), 3)
    chk("and each is 5 entries", sorted(set(r[2] for r in mis)), [5])

    print()
    print("%d checks, %d failed" % (n[0], len(fails)))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
