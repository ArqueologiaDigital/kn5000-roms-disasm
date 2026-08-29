#!/usr/bin/env python3
"""The code/data/fill LAYOUT of prom_a 0xFAD800-0xFB2000, derived from the ROM.

QUESTION IT ANSWERS
  "Which bytes of prom_a's largest remaining `.incbin` are instructions, which
   are tables, and which are padding?"  A later lane converts the span; a linear
   decode of it desynchronises inside the first module -- there are TEN inline
   jump tables in it -- so the boundaries have to be pinned FIRST.  This is that
   pinning, and every boundary below is the output of a rule, not of an eye.

  The span is one `.incbin`: prom_a/wsa1_prom_a.s line 49272,
  `.incbin "original_ROMs/wsa1_prom_a.ic12", 0x02D800, 0x004800`
  = 0xFAD800-0xFB1FFF, 18,432 bytes.  notes/prom_a_module_frontier.py ranks it
  NOT top by contiguous unconverted extent -- summed, this span's runs give
  3,216 + 2,595 + 0 = 5,811, where 0xFA5AEB-0xFAA000's give 16,799 and T_F43350
  alone (8,886) outranks anything here.  It was picked because it is prom_a's
  LARGEST remaining .incbin (18,432 B), which is a perfectly good reason and is
  what WAVE7-BRIEFING.md actually says.  Reproduce the ranking with
  `python3 notes/wave7_frontier_table.py --sums`.  This line used to claim the
  frontier ranked it
  into it -- T_F40850-T_F4089C (20 slots, 2,595 B, ref bound 35),
  T_F41F10-T_F41F3C (12 slots, 3,216 B, 17) and T_F40840 (1 slot) = 33
  directory slots, all of which converting the span retires.

METHOD -- notes/prom_b_f65000_layout.py's, which wave 7 was told to copy:
  CONTENT RULES first, each with a false-positive count measured on a NULL
  CORPUS of already-proven instruction text; those regions become BARRIERS; and
  only then a recursive descent for the code.

THE RULES, IN PRIORITY ORDER, AND THE NULL MEASURED FOR EACH
  `--null` prints the live numbers and `--null --rev REV` pins them.  The
  figures below were measured on the WORKING TREE at wave 7 round 1: 10,509
  runs, 287,291 bytes of proven prom_a instruction text.

  1. FILL   -- a maximal run of >= 16 bytes of 0x0E (`ret`).  NULL: THREE
     (0xF99B71/17, 0xF99E6A/27, 0xF99EF3/17).  All three are runs the .s wrote
     out as consecutive `ret` LINES -- pad transcribed as code -- and `--null`
     says so per firing rather than rounding the cost to zero.
  2. ZFILL / FFILL -- a maximal run of >= 32 bytes of 0x00 / of 0xFF.  NULL:
     TWO for 0x00 (0xFE7A86/1323 and 0xFF7A4D/536, both written out as runs of
     `nop`), ZERO for 0xFF.  16 was rejected: it costs two more (0xFE2FEC/20,
     0xFE7055/25).
  3. PTRTAB -- a chain of 4-byte little-endian words all inside the SPAN
     (0x00FAD800-0x00FB2000), with >= 2 of them real; 0xFFFFFFFF counts as an
     EMPTY slot inside a chain but may not begin one.  NULL: ZERO, and still
     ZERO at the 2-entry minimum, which is why the minimum is 2: it is the
     measurement that lets the rule frame the two-entry jump tables at
     0xFADDA0 and 0xFADDC1 (both bounded `cp L,1 / jr UGT` by their readers),
     which a 3-entry minimum leaves inside a code segment.  The tight WINDOW is
     what the zero rests on: at 0xFA0000-0xFC0000 the same rule costs one false
     positive and over all of prom_a seven.
  4. PTRBLOB -- the PAYLOAD of a pointer table whose entries strictly increase
     with a CONSTANT stride (checked on the LAST entry) and whose first entry is
     the byte after the table.  Two qualify; see ptr_blobs() for the two guards
     and --tables for the evidence.
  5. IDENT  -- a run where byte[k] == byte[0]+k without wrapping, >= 12 long.
     NULL: ZERO (at 8 it costs five, at 4 thirty-seven).  Two fire, and both are
     addresses that code LOADS -- `--readers`.
  6. ASCII  -- a maximal run of >= 20 bytes in 0x20-0x7E.  NULL: FIVE, of which
     four are strings the .s wrote as repeated `ldb w,0x2020` and one
     (0xF94C79/27) is a genuine false positive in mixed instruction text.  The
     rule fires ZERO times inside this span, so it costs nothing here; it is
     kept and measured so its silence is a result and not an omission.
  7. CODE   -- a TWO-PHASE recursive descent that treats rules 1-6 (and, in
     phase 2, rule 8) as BARRIERS.
       phase 1: seeds are the 33 thunk targets, every in-span entry of every
         PTRTAB, and every opcode-anchored `call`/`jp` addr24 whose SITE is a
         proven instruction of prom_a/wsa1_prom_a.s or prom_b/wsa1_prom_b.s.
         32-bit immediates are RECORDED, not followed.
       phase 2: the same seeds without the proven-site filter, immediates
         followed, and the rule-8 lists added to the barrier.
     Both filters are load-bearing and both were added because the walk did the
     wrong thing without them -- see far_calls_proven() and descend().
  8. RECLIST -- three register-poke lists, each closed by a 4-byte back-pointer
     that phase-1 code loads.  A residue rule, guarded so it cannot swallow
     code; see reclists() and --reclists.
  9. ALIGN  -- a residue run of 1-3 bytes, all 0x00, left between a routine's
     `ret` and an even-aligned table.  Nine fire, every one a single byte.
  Anything still left over is `unknown` and the report says so.  There is none.

RESULT (default report; regenerate rather than quoting this)
  63 segments, 0 unknown, 0 barrier conflicts.  code 7,107 - pointer_table
  1,476 - blob 6,820 - reclist 1,166 - index_map 64 - pad 1,790 - align 9.
  All 21 code segments decode EXACTLY under a linear decode and every one ends
  in a flow end; all 183 published entry points land on an instruction boundary.
  ⚠ Necessary, not sufficient -- see the byte tables below.

  INDEPENDENT CONFIRMATION OF EVERY TABLE SIZE.  17 of the 21 pointer tables
  have a reader that STATES an index bound (`cp L,0x0b`, `and L,0x03`,
  `cp A,0xbf`, ...); for all 17 the bound implies exactly the entry count the
  content rule measured, and `--selftest` re-decodes each bound instruction at
  the address cited to check the citation itself.  Of the remaining four, two
  (0xFAF7E8, 0xFB0700) are proved 33 by their payload's own stride, and two
  (0xFAE802, 0xFAE82A) have NO reader anywhere -- see below.  `--bounds`.

WHAT IS NOT CLAIMED
  * The 1,020-byte 0x00 run at 0xFB1394 and the 350 bytes at 0xFAE6A2 are
    `pad` because they are constant-byte runs, NOT because a reader was found.
    None was.  Same for the 112- and 308-byte 0x0E runs.
  * The two 8-entry pointer tables at 0xFAE802 and 0xFAE82A are framed by the
    content rule and their entries are valid code entry points, but NO
    instruction in prom_a or prom_b loads either base address -- `--readers`
    prints that, and it is an open question, not a defect of the rule.
  * 26 code runs totalling 261 bytes (3.7% of the 7,107 code bytes) are
    `accept()`-promoted, i.e. code
    by SHAPE and not by a control-flow path.  `--accepted` lists them.
  * ★ TWO BYTE TABLES SIT INSIDE `code` SEGMENTS AND THIS LAYOUT DOES NOT FRAME
    THEM.  The content rules find POINTER tables; a table of BYTES is
    indistinguishable from instructions by shape.  `--tablebases` finds them by
    a different route -- every in-span address decoded code LOADS -- and exactly
    two of the 26 land in a `code` segment:
      0xFADA20  `01 02 04 08 10 20`, a bit-weight table, indexed
                `ld E,(XIX+E)` at 0xFADA10 after `and E,0x3f` at 0xFADA08.
                Its length IS pinned, at SIX bytes, and not by content: 0xFADA26
                is the target of thunk slot T_F40898, so the byte after the
                table is a published entry point.
      0xFADD30  the inverse map -- non-zero entries at offsets 0,2,4,8,0x10,0x20
                holding 0,1,2,3,4,5 -- indexed `ld A,(XIX+A)` at 0xFADD1D after
                `and A,0x3f` at 0xFADD15.  Its length is NOT pinned.  Content
                needs 0x21 bytes; the mask allows 0x40; the next rule-framed
                object is the pointer table at 0xFADD77, 71 bytes on; and a
                DISPATCHER starts at 0xFADD60 (`cp L,3 / jr UGT,0xFADD87 /
                sll 0x02,HL / ld XIX,0x00fadd77 / ld XIX,(XIX+HL) / jp T,XIX`),
                which caps the table at 0x30.  So it is 0x21..0x30 bytes and
                this file does not choose.
    ⚠ Both are `code` in the layout ONLY because phase 2 follows loaded
    immediates: the walk seeded at the table base and decoded 0x00 as `nop`.
    0xFADD60 is reached by NOTHING ELSE in either ROM -- no thunk, no call, no
    branch, no table entry -- so the code segment 0xFADCCA-0xFADD76 is partly
    that artefact.  A converting lane MUST carve both tables out by hand.
    `--tablebases` prints all four bounding numbers and `--selftest` asserts the
    list is exactly these two, so a change is loud.
  * Nothing here is a NAME.  This lane produced a layout; the meaning of the
    tables is stated only where a reader in the ROM states it.

RUN
  python3 notes/prom_a_fad800_layout.py              # the LAYOUT table
  python3 notes/prom_a_fad800_layout.py --null       # rule calibration
  python3 notes/prom_a_fad800_layout.py --null --rev HEAD
  python3 notes/prom_a_fad800_layout.py --tables     # PTRTAB/PTRBLOB evidence
  python3 notes/prom_a_fad800_layout.py --reclists   # the three poke lists
  python3 notes/prom_a_fad800_layout.py --readers    # who loads each table base
  python3 notes/prom_a_fad800_layout.py --tablebases # ★ the unframed byte tables
  python3 notes/prom_a_fad800_layout.py --bounds     # reader-stated entry counts
  python3 notes/prom_a_fad800_layout.py --accepted   # code by shape only
  python3 notes/prom_a_fad800_layout.py --barrier    # what the barrier removes
  python3 notes/prom_a_fad800_layout.py --conflicts  # descent-vs-barrier (0)
  python3 notes/prom_a_fad800_layout.py --residue    # unexplained runs, hex
  python3 notes/prom_a_fad800_layout.py --seeds      # where the descent starts
  python3 notes/prom_a_fad800_layout.py --python     # paste-ready LAYOUT
  python3 notes/prom_a_fad800_layout.py --selftest   # 57 checks, incl. the
                                                     # LAST element of every
                                                     # table and the LAST
                                                     # segment of the span
Exit status is non-zero if --selftest fails.
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import trace_code as TC                                            # noqa: E402

A_BASE = 0xF80000
B_BASE = 0xF00000
LO, HI = 0xFAD800, 0xFB2000
IMGA = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
IMGB = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
SRC = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")

FILL_MIN = 16          # 0x0E == ret
CONST_MIN = 32         # 0x00 / 0xFF -- see the docstring, 16 costs a false positive
PTR_MIN = 2
IDENT_MIN = 12
ASCII_MIN = 20
BLOB_MIN = 8
PTR_LO, PTR_HI = LO, HI          # the PTRTAB window: the span itself

_rom = {}
_dec = {}
FAIL = []


def rom(which="a"):
    if which not in _rom:
        _rom[which] = open(IMGA if which == "a" else IMGB, "rb").read()
    return _rom[which]


def base(which="a"):
    return A_BASE if which == "a" else B_BASE


def byte(a):
    return rom("a")[a - A_BASE]


def w32(a):
    return int.from_bytes(rom("a")[a - A_BASE:a - A_BASE + 4], "little")


# ---------------------------------------------------------------- decoding ---
def decode_at(addr, window=0x40):
    """(length, text) for the instruction AT addr, decoded from addr itself.

    One unidasm run per MISS, over a 0x40-byte window, and every line of that
    window is cached -- a TLCS-900 instruction decodes identically whatever the
    sweep that found it started from, and the first line of the window starts
    at addr by construction.  The LAST line of a window may be truncated by the
    window edge, so it is dropped."""
    if addr in _dec:
        return _dec[addr]
    o = addr - A_BASE
    d = rom("a")
    if o < 0 or o >= len(d):
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
    rows = []
    for ln in out.splitlines():
        m = TC.LINE.match(ln)
        if m:
            rows.append((int(m.group(1), 16), len(m.group(2).split()),
                         m.group(3).strip()))
    for a, n, txt in rows[:-1]:
        if a not in _dec:
            _dec[a] = (n, txt)
    return _dec.get(addr)


# ----------------------------------------------------------- content rules ---
def const_runs(d, lo, hi, val, n, off):
    out, p = [], lo
    while p < hi:
        if d[p - off] == val:
            q = p
            while q < hi and d[q - off] == val:
                q += 1
            if q - p >= n:
                out.append((p, q))
            p = q
        else:
            p += 1
    return out


def fill_runs(d, lo, hi, n=FILL_MIN, off=A_BASE):
    return const_runs(d, lo, hi, 0x0E, n, off)


def zero_runs(d, lo, hi, n=CONST_MIN, off=A_BASE):
    return const_runs(d, lo, hi, 0x00, n, off)


def ff_runs(d, lo, hi, n=CONST_MIN, off=A_BASE):
    return const_runs(d, lo, hi, 0xFF, n, off)


def ptr_tables(d, lo, hi, minent=PTR_MIN, plo=PTR_LO, phi=PTR_HI, off=A_BASE,
               sparse=True):
    """Maximal chains of LE32 words inside [plo,phi), with >= minent of them.

    SPARSE (the default, and it is a correction).  A dense chain rule frames the
    192-entry dispatch table at 0xFAE3A2 as FOUR fragments -- 64 entries, then
    two of 5 and 6 -- because 116 of its slots hold 0xFFFFFFFF, which the reader
    at 0xFADB69 tests for explicitly (`cp XIY,0xffffffff / jr Z`) as "no
    handler".  So 0xFFFFFFFF counts as an EMPTY ENTRY inside a chain, but a
    chain may not begin or end on one, and it still needs `minent` real
    in-window entries.  A chain may not BEGIN on an empty entry -- otherwise it
    would start anywhere inside a 0xFF pad run -- but it may END on one, and it
    runs to the first word that is neither.  With that, one rule frames
    0xFAE3A2-0xFAE6A1 = 192 entries.

    ★ The trailing-empty clause is the only part of this rule that could
    over-claim, and here it is CONFIRMED INDEPENDENTLY: the reader bounds the
    index at 0xBF (`cp A,0xbf / jr UGT,0xFADB89` at 0xFADB55) and scales it by 4
    (`sll 0x02,WA` at 0xFADB5C) before `ld XIY,(XIY+WA)` at 0xFADB64, so the
    table has exactly 0xC0 = 192 entries and ends at 0xFAE6A2.  Without the
    clause the rule stops at the last non-empty entry, 0xFAE69A, and reports the
    last 8 bytes as `unknown`; with it, the rule and the reader agree exactly.
    `--null` measures the sparse and the dense form separately."""
    def word(a):
        return int.from_bytes(d[a - off:a - off + 4], "little")

    def real(a):
        return plo <= word(a) < phi

    def empty(a):
        return sparse and word(a) == 0xFFFFFFFF
    best = {}
    for p in range(lo, hi - 3):
        if not real(p):
            continue
        k, q = 0, p
        while q <= hi - 4 and (real(q) or empty(q)):
            if real(q):
                k += 1
            q += 4
        if k >= minent:
            best[p] = (q - p) // 4
    out, p = [], lo
    while p < hi - 3:
        if p in best:
            out.append((p, p + 4 * best[p]))
            p += 4 * best[p]
        else:
            p += 1
    return out


def ident_runs(d, lo, hi, n=IDENT_MIN, off=A_BASE):
    out, p = [], lo
    while p < hi:
        q = p + 1
        while (q < hi and d[p - off] + (q - p) <= 0xFF
               and d[q - off] == d[p - off] + (q - p)):
            q += 1
        if q - p >= n:
            out.append((p, q))
            p = q
        else:
            p += 1
    return out


def ascii_runs(d, lo, hi, n=ASCII_MIN, off=A_BASE):
    out, p = [], lo
    while p < hi:
        if 32 <= d[p - off] < 127:
            q = p
            while q < hi and 32 <= d[q - off] < 127:
                q += 1
            if q - p >= n:
                out.append((p, q))
            p = q
        else:
            p += 1
    return out


def ptr_blobs(d, lo, hi):
    """(table, payload_lo, payload_hi, stride, nentries) for every PTRTAB whose
    entries strictly increase with a CONSTANT stride and whose FIRST entry is
    the byte just past the table.

    The stride is verified on EVERY entry including the last, which is the
    check this project's error list says gets skipped.  The payload runs to
    e_last + stride -- the last entry names a real block, not a sentinel -- and
    is then clipped to the first PTRTAB or constant-byte run starting at or
    after e_last, so a payload can never swallow the next table.

    TWO GUARDS, both of which this span needed:
      * >= BLOB_MIN (8) entries.  At 3 the rule ALSO fires on the 4-entry table
        at 0xFAF410, whose "payload" is four 17-byte ROUTINES (each begins
        `ld XIY,0x00faf7c7`) -- a jump table into equal-sized code looks exactly
        like a table into equal-sized records.
      * block 0 must not be self-consistent code ending in a flow end.  That is
        notes/prom_b_f0ea9f_layout.py's --null-accept discriminator, measured
        there at 1 false accept in 1,884 chunks of proven DATA; it rejects
        0xFAF410 on its own, so the two guards are independent and the entry
        threshold is not load-bearing by itself."""
    tabs = ptr_tables(d, lo, hi)
    stops = sorted([a for a, _ in tabs]
                   + [a for a, _ in fill_runs(d, lo, hi)]
                   + [a for a, _ in zero_runs(d, lo, hi)]
                   + [a for a, _ in ff_runs(d, lo, hi)])
    out = []
    for a, e in tabs:
        ent = [int.from_bytes(d[x - A_BASE:x - A_BASE + 4], "little")
               for x in range(a, e, 4)]
        if len(ent) < BLOB_MIN or ent[0] != e:
            continue
        stride = ent[1] - ent[0]
        if stride <= 0 or any(ent[i + 1] - ent[i] != stride
                              for i in range(len(ent) - 1)):
            continue
        if selfconsistent(ent[0], ent[0] + stride, set()) \
                and ends_in_flow_end(ent[0], ent[0] + stride):
            continue                       # block 0 is a ROUTINE, not a record
        end = ent[-1] + stride
        for s in stops:
            if s >= ent[-1]:
                end = min(end, s)
                break
        out.append((a, ent[0], min(end, hi), stride, len(ent)))
    return out


def barriers(d, lo=LO, hi=HI):
    b = set()
    for a, e in (fill_runs(d, lo, hi) + zero_runs(d, lo, hi)
                 + ff_runs(d, lo, hi) + ptr_tables(d, lo, hi)
                 + ident_runs(d, lo, hi) + ascii_runs(d, lo, hi)):
        b |= set(range(a, e))
    for _, s, e, _, _ in ptr_blobs(d, lo, hi):
        b |= set(range(s, e))
    return b


# ------------------------------------------------------------------ seeds ---
def thunk_entries(lo=LO, hi=HI):
    """prom_b thunk-table `jp` slots (0xF40000-0xF44018) landing in [lo,hi)."""
    b = rom("b")
    out = []
    for slot in range(0x40000, 0x44018, 4):
        if b[slot] == 0x1B:
            t = b[slot + 1] | b[slot + 2] << 8 | b[slot + 3] << 16
            if lo <= t < hi:
                out.append((B_BASE + slot, t))
    return out


def far_calls(lo=LO, hi=HI):
    """`call addr24` / `jp addr24` sites in prom_a+prom_b targeting [lo,hi).
    Opcode-anchored at every byte: an UPPER BOUND, used only to SEED."""
    out = {}
    for which in ("a", "b"):
        blob = rom(which)
        for i in range(len(blob) - 3):
            if blob[i] in (0x1D, 0x1B):
                t = blob[i + 1] | blob[i + 2] << 8 | blob[i + 3] << 16
                if lo <= t < hi:
                    out.setdefault(t, []).append((which, base(which) + i))
    return out


SLINE = re.compile(r";\s*([0-9A-F]{6})\s\s")
_proven = {}


def proven_addrs(which):
    """Every address a converted INSTRUCTION line of prom_a/wsa1_prom_a.s or
    prom_b/wsa1_prom_b.s claims, i.e. every address the byte gate has already
    certified as an instruction boundary.

    The two files write the comment differently -- prom_a `; ADDR  <bytes>
    <text>`, prom_b `; ADDR  <text>` -- so the address is all that is matched.
    Directive lines (`.byte`, `.short`, `.fill`, `.incbin`) are excluded by
    requiring the mnemonic not to start with a dot, and label lines by requiring
    the line to start with a tab."""
    if which not in _proven:
        f = SRC if which == "a" else os.path.join(ROOT, "prom_b",
                                                  "wsa1_prom_b.s")
        out = set()
        for l in open(f):
            body = l.split(";")[0]
            if not body.startswith("\t") or body.lstrip().startswith("."):
                continue
            m = SLINE.search(l)
            if m:
                out.add(int(m.group(1), 16))
        _proven[which] = out
    return _proven[which]


def far_calls_proven(lo=LO, hi=HI):
    """far_calls() restricted to sites that are PROVEN instruction boundaries.

    ⚠ This filter is not cosmetic.  The unfiltered scan produces three seeds in
    this span that are not call sites at all -- 0xFB0F02 (from three sites),
    0xFB1B1B (from prom_b 0xF788D6, inside an `.incbin`) and 0xFB1BFE (from
    0xF4262A, two bytes into a thunk slot) -- and all three land INSIDE a data
    table.  Phase 1 has no barrier there yet, so one of them made the walk
    decode 904 bytes of register-poke list as instructions.  Phase 2 may use the
    full upper bound again, because by then the tables are barriers."""
    fc = far_calls(lo, hi)
    out = {}
    for t, sites in fc.items():
        keep = [(w, a) for w, a in sites if a in proven_addrs(w)]
        if keep:
            out[t] = keep
    return out


def table_entry_seeds(d, lo=LO, hi=HI):
    out = set()
    for a, e in ptr_tables(d, lo, hi):
        for x in range(a, e, 4):
            t = int.from_bytes(d[x - A_BASE:x - A_BASE + 4], "little")
            if lo <= t < hi:
                out.add(t)
    return out


def seeds_of(d, lo=LO, hi=HI, proven_only=False):
    fc = far_calls_proven(lo, hi) if proven_only else far_calls(lo, hi)
    return (set(t for _, t in thunk_entries(lo, hi)) | set(fc)
            | table_entry_seeds(d, lo, hi))


# ------------------------------------------------------------ code descent ---
IMM32 = re.compile(r"0x00([0-9a-f]{6})")


def descend(lo, hi, seeds, block, imm_out=None, follow_imm=True):
    """Recursive descent that refuses to enter a barrier byte.

    `follow_imm=False` records the 32-bit immediates the code loads without
    treating them as entry points.  That is PHASE 1 (see build()): a loaded
    immediate is as often a data address as a routine address, and following
    one into a table that no content rule framed is what makes a walk decode a
    poke list as instructions -- it did exactly that here, claiming all 904
    bytes of the list at 0xFB1B48 as code, because 0xFB1EC8 is an immediate."""
    seen, work = set(), [s for s in seeds if s not in block]
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
            for t in TC.branch_targets(txt):
                if lo <= t < hi and t not in seen and t not in block:
                    work.append(t)
            for m in IMM32.findall(txt):
                v = int(m, 16)
                if imm_out is not None:
                    imm_out.setdefault(v, set()).add(p)
                if follow_imm and lo <= v < hi and v not in seen \
                        and v not in block:
                    work.append(v)
            if TC.is_flow_end(txt):
                break
            p += n
    return seen


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


def selfconsistent(s, e, seen):
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
            if t not in bounds and t not in seen:
                return False
    return True


def ends_in_flow_end(s, e):
    """Does a linear decode of [s,e) consume it exactly AND end in a flow end?

    Imported wholesale from notes/prom_b_f65000_layout.py, where it is a
    CORRECTION, not a refinement: selfconsistent() alone accepts 13.9% of
    known-DATA chunks as code and this drops that to 0.1%.  A residue run is
    promoted to code only if it looks like a real routine tail."""
    p, last = s, None
    while p < e:
        dec = decode_at(p)
        if dec is None:
            return False
        last = dec[1]
        p += dec[0]
    return p == e and last is not None and TC.is_flow_end(last)


def accept(gaps, seen, imm_out=None):
    """Iterate selfconsistent() to a fixpoint over the WHOLE pending set."""
    ok, pending = [], list(gaps)
    for _ in range(20):
        cand = set(seen)
        for s, e in pending:
            b = decode_bounds(s, e)
            if b:
                cand |= b
        grew, still = False, []
        for s, e in pending:
            if selfconsistent(s, e, cand) and ends_in_flow_end(s, e):
                ok.append((s, e))
                p = s
                while p < e:
                    seen.add(p)
                    if imm_out is not None:
                        for m in IMM32.findall(decode_at(p)[1]):
                            imm_out.setdefault(int(m, 16), set()).add(p)
                    p += decode_at(p)[0]
                grew = True
            else:
                still.append((s, e))
        pending = still
        if not grew:
            break
    return ok, pending


# ---------------------------------------------------- residue: RECLIST rule ---
def reclists(d, block, seen1, imm, lo=LO, hi=HI):
    """The three back-pointer-closed record lists, framed WITHOUT following any
    immediate as an entry point.

    RULE.  A 4-byte slot at P is a list terminator if
      (a) P is a 32-bit immediate that PHASE-1 code loads,
      (b) P is not already inside a content-rule region,
      (c) P is not code phase 1 reached,
      (d) the word at P is W with lo <= W < P, and
      (e) NO byte of [W,P) is code phase 1 reached.
    Then [W, P+4) is the list plus its terminator.

    (e) is what stops the rule from swallowing code: the SAME shape at
    0xFAE3A2 (loaded at 0xFADB60, word 0x00FADB91 pointing backwards into the
    module) is a 192-entry dispatch table whose "body" is 2,065 bytes of proven
    instructions, and (b) and (e) both reject it.
    Output: (list_lo, slot_addr, nbytes, sorted list of loading instructions)."""
    out = []
    for P in sorted(imm):
        if not (lo <= P and P + 4 <= hi):
            continue
        if P in block or P in seen1:
            continue
        W = int.from_bytes(d[P - A_BASE:P - A_BASE + 4], "little")
        if not (lo <= W < P):
            continue
        if any(x in seen1 or x in block for x in range(W, P)):
            continue
        out.append((W, P, P + 4 - W, sorted(imm[P])))
    return out


def align_pads(d, pending):
    """Residue runs of 1-3 bytes that are ALL 0x00 and that butt up against the
    start of a rule-framed object.  They are alignment bytes the compiler put
    between a routine's `ret` and an even-aligned table; there are nine in this
    span and every one is a single 0x00.  A residue rule, so it can never take
    a byte away from the code walk."""
    out = []
    for s, e in pending:
        if e - s <= 3 and all(d[x - A_BASE] == 0x00 for x in range(s, e)):
            out.append((s, e))
    return out


# ------------------------------------------------------------------ build ---
def build(lo=LO, hi=HI):
    """PHASE 1 finds the code that real control flow reaches without following
    immediates; the RECLIST rule then frames the poke lists using the
    immediates phase 1 recorded; PHASE 2 re-walks with those as barriers and
    with immediates followed, which is what reaches routines entered only
    through a table."""
    d = rom("a")
    block = barriers(d, lo, hi)
    imm = {}
    seen1 = descend(lo, hi, sorted(seeds_of(d, lo, hi, proven_only=True)),
                    block, imm, follow_imm=False)
    rl = reclists(d, block, seen1, imm, lo, hi)
    block2 = set(block)
    for s, _, n, _ in rl:
        block2 |= set(range(s, s + n))
    seen = descend(lo, hi, sorted(seeds_of(d, lo, hi)), block2, imm,
                   follow_imm=True)
    block = block2
    gaps = gaps_of(lo, hi, seen, block)
    ok, pending = accept(gaps, seen, imm)
    ap = align_pads(d, pending)
    pending = [g for g in pending if g not in ap]

    kind = ["unknown"] * (hi - lo)
    for a in seen:
        if lo <= a < hi:
            kind[a - lo] = "code"
    for a, e in ok:
        for x in range(a, e):
            kind[x - lo] = "code"
    conflicts = []

    def paint(regions, name):
        for a, e in regions:
            for x in range(a, e):
                if kind[x - lo] == "code":
                    conflicts.append(x)
                kind[x - lo] = name

    # Painted lowest priority FIRST.  The constant-byte runs go first because a
    # table may legitimately CONTAIN one: 116 of the 192 slots at 0xFAE3A2 are
    # 0xFFFFFFFF, which is 352 contiguous bytes of 0xFF, and painting the pad
    # last split one table into three segments with pad between them.
    paint(zero_runs(d, lo, hi), "pad_00")
    paint(ff_runs(d, lo, hi), "pad_ff")
    paint(fill_runs(d, lo, hi), "pad_0e")
    paint([(s, e) for _, s, e, _, _ in ptr_blobs(d, lo, hi)], "blob")
    paint(ptr_tables(d, lo, hi), "pointer_table")
    paint(ident_runs(d, lo, hi), "index_map")
    paint(ascii_runs(d, lo, hi), "ascii")
    paint([(s, s + n) for s, _, n, _ in rl], "reclist")
    paint(ap, "align")

    # Three of the poke lists are adjacent and would merge into one 1,166-byte
    # `reclist` segment; each is a separate object with its own record count and
    # stride, so their starts force a segment break.
    hard = set(s_ for s_, _, _, _ in rl)
    segs, p = [], 0
    while p < hi - lo:
        q = p + 1
        while q < hi - lo and kind[q] == kind[p] and (lo + q) not in hard:
            q += 1
        segs.append((kind[p], lo + p, q - p))
        p = q
    return segs, conflicts, pending, ok, seen, rl, imm


# ------------------------------------------------------------- null corpus ---
def source_text(rev=None):
    if rev is None:
        return open(SRC).read()
    return subprocess.run(["git", "show", "%s:prom_a/wsa1_prom_a.s" % rev],
                          cwd=ROOT, check=True, capture_output=True,
                          text=True).stdout


ADDRC = re.compile(r";\s*([0-9A-F]{6})\s\s([0-9a-f]{2}(?: [0-9a-f]{2})*)")


def proven_code_runs(rev=None):
    """Maximal runs of PROVEN instruction text in prom_a/wsa1_prom_a.s.

    Every instruction line carries `; ADDR  <bytes>  <mame text>` and the byte
    gate proves the file rebuilds the ROM, so these addresses are code beyond
    argument.  Directive lines (`.byte`, `.ascii`, `.long`, `.fill`) carry the
    same comment shape and are excluded by requiring the mnemonic not to start
    with a dot -- without that the corpus silently contains the data islands it
    is supposed to be a null for.

    ⚠ The run END is the last instruction's address PLUS ITS LENGTH, taken from
    its own byte list.  prom_b's twin stops at the last instruction's address
    and therefore under-reports its corpus by a few bytes per run."""
    seq = []
    for l in source_text(rev).splitlines():
        body = l.split(";")[0]
        m = ADDRC.search(l)
        if m and body.startswith("\t") and not body.lstrip().startswith("."):
            seq.append((int(m.group(1), 16), len(m.group(2).split())))
        else:
            seq.append(None)
    runs, cur = [], []
    for it in seq:
        if it is None or (cur and it[0] <= cur[-1][0]):
            if len(cur) > 1:
                runs.append((cur[0][0], cur[-1][0] + cur[-1][1]))
            cur = []
        if it is not None:
            cur.append(it)
    if len(cur) > 1:
        runs.append((cur[0][0], cur[-1][0] + cur[-1][1]))
    return runs


def source_lines(rev=None):
    """addr -> (mnemonic, nbytes) for every proven INSTRUCTION line of prom_a."""
    out = {}
    for l in source_text(rev).splitlines():
        body = l.split(";")[0]
        m = ADDRC.search(l)
        if m and body.startswith("\t") and not body.lstrip().startswith("."):
            out[int(m.group(1), 16)] = (body.split()[0].lower(),
                                        len(m.group(2).split()))
    return out


def classify_fp(lines, a, e):
    """Is this false positive a place where the TRANSCRIPTION wrote padding out
    as instructions?

    Mechanical, no judgement: collect the mnemonic of every proven instruction
    line whose address is inside [a,e).  ONE distinct mnemonic means the run is
    a repetition of a single instruction -- 1,323 `nop`s, 27 `ret`s, 48
    `ldb w,0x20`s -- which is what padding and strings look like when a
    converter emits them as code, and the rule firing there is the rule being
    RIGHT about the bytes and the .s being loose.  More than one mnemonic is a
    genuine false positive and is reported as MIXED so it gets read."""
    mn, nline, cov = {}, 0, 0
    for x in range(a, e):
        if x in lines:
            mn[lines[x][0]] = mn.get(lines[x][0], 0) + 1
            nline += 1
            cov += lines[x][1]
    if not mn:
        return "no instruction line covers it"
    if len(mn) == 1:
        return "%d x `%s`, %d of %d bytes (pad/string written as code)" % (
            nline, list(mn)[0], min(cov, e - a), e - a)
    return "MIXED: " + ", ".join("%s x%d" % kv for kv in
                                 sorted(mn.items(), key=lambda t: -t[1])[:5])


def null(rev=None):
    d = rom("a")
    runs = proven_code_runs(rev)
    tot = sum(e - s for s, e in runs)
    print("NULL corpus: every maximal run of PROVEN instruction text in")
    print("prom_a/wsa1_prom_a.s @ %s -- %d runs, %d bytes.  A rule that fires"
          % (rev or "WORKING TREE", len(runs), tot))
    print("inside one of these runs is a FALSE POSITIVE.")
    if rev is None:
        print("  ⚠ this corpus GROWS as rounds convert code; quote it with"
              " --rev REV.")
    tests = [
        ("fill 0x0E >= %d" % FILL_MIN, lambda a, b: fill_runs(d, a, b)),
        ("zero 0x00 >= %d" % CONST_MIN, lambda a, b: zero_runs(d, a, b)),
        ("zero 0x00 >= 16 (rejected)", lambda a, b: zero_runs(d, a, b, 16)),
        ("zero 0x00 >=  8 (rejected)", lambda a, b: zero_runs(d, a, b, 8)),
        ("ffff 0xFF >= %d" % CONST_MIN, lambda a, b: ff_runs(d, a, b)),
        ("ffff 0xFF >= 16 (rejected)", lambda a, b: ff_runs(d, a, b, 16)),
        ("ptrtab >= %d, window = the span (ADOPTED)" % PTR_MIN,
         lambda a, b: ptr_tables(d, a, b)),
        ("ptrtab >= 3, window = 0xFA0000-0xFC0000 (rejected)",
         lambda a, b: ptr_tables(d, a, b, 3, 0xFA0000, 0xFC0000)),
        ("ptrtab >= 3, window = all of prom_a (rejected)",
         lambda a, b: ptr_tables(d, a, b, 3, 0xF80000, 0x1000000)),
        ("ptrtab >= 3, window = the span (also zero, but misses two)",
         lambda a, b: ptr_tables(d, a, b, 3)),
        ("ident  >= %d" % IDENT_MIN, lambda a, b: ident_runs(d, a, b)),
        ("ident  >=  8 (rejected)", lambda a, b: ident_runs(d, a, b, 8)),
        ("ident  >=  4 (rejected)", lambda a, b: ident_runs(d, a, b, 4)),
        ("ascii  >= %d" % ASCII_MIN, lambda a, b: ascii_runs(d, a, b)),
        ("ascii  >= 10 (rejected)", lambda a, b: ascii_runs(d, a, b, 10)),
        ("ascii  >=  8 (rejected)", lambda a, b: ascii_runs(d, a, b, 8)),
    ]
    res, adopted = {}, []
    for name, f in tests:
        hits = []
        for s, e in runs:
            hits += f(s, e)
        res[name] = hits
        print("  %-52s FP: %3d   %s"
              % (name, len(hits),
                 " ".join("0x%06X(%d)" % (a, b - a) for a, b in hits[:4])))
        if "rejected" not in name and hits:
            adopted.append((name, hits))
    print("  The rejected thresholds are printed so each choice is visible as a")
    print("  MEASUREMENT and not a preference.")
    if adopted:
        lines = source_lines(rev)
        print()
        print("  ⚠ THE ADOPTED THRESHOLDS ARE NOT AT ZERO.  Every firing is")
        print("  listed here with what the transcription says those bytes are,")
        print("  so the cost is visible instead of rounded down:")
        for name, hits in adopted:
            for a, e in hits:
                print("    %-22s 0x%06X %5d bytes   %s"
                      % (name.split()[0], a, e - a, classify_fp(lines, a, e)))
    return runs, tot, res


# ---------------------------------------------------------------- reporting ---
def check(msg, got, want):
    ok = got == want
    print("  %-64s %-22s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def selftest():
    d = rom("a")
    segs, conflicts, pending, ok, seen, rl, imm = build()
    print("SELFTEST -- the FIRST and the LAST segment are both asserted, plus")
    print("the interior boundaries that a wrong answer would move.")
    print()
    check("segments cover the span exactly (sum of lengths)",
          sum(n for _, _, n in segs), HI - LO)
    gapless = all(segs[i][1] + segs[i][2] == segs[i + 1][1]
                  for i in range(len(segs) - 1))
    check("no gaps and no overlaps between consecutive segments", gapless, True)
    check("first segment starts at the span start",
          "0x%06X" % segs[0][1], "0x%06X" % LO)
    check("FIRST segment is code 0xFAD800", (segs[0][0], "0x%06X" % segs[0][1]),
          ("code", "0x%06X" % LO))
    last = segs[-1]
    check("LAST segment ends at the span end",
          "0x%06X" % (last[1] + last[2]), "0x%06X" % HI)
    check("LAST segment is the 0x0E pad 0xFB1ECC-0xFB1FFF",
          (last[0], "0x%06X" % last[1], last[2]),
          ("pad_0e", "0x%06X" % 0xFB1ECC, 308))
    check("LAST segment really is all 0x0E",
          sorted(set(d[last[1] - A_BASE:last[1] + last[2] - A_BASE])), [0x0E])
    check("descent bytes reclaimed by a content rule (MUST be 0)",
          len(conflicts), 0)
    # the three thunk runs this span retires
    th = dict((t, s) for s, t in thunk_entries())
    check("thunk slots pointing into the span", len(th), 33)
    kindof = {}
    for k, s, n in segs:
        for x in range(s, s + n):
            kindof[x] = k
    check("every thunk target is inside a `code` segment",
          sorted(set(kindof[t] for t in th)), ["code"])
    check("T_F40840's target 0xFB1800 is code", kindof[0xFB1800], "code")
    # the two payload blobs, checked on their LAST entry
    blobs = ptr_blobs(d, LO, HI)
    check("PTRBLOB count", len(blobs), 2)
    # ⚠ Guarded: when PTRBLOB detection breaks, the [0] indexing used to raise an
    # uncaught IndexError here, so the remaining ~40 checks never ran and no failure
    # summary was printed.  A self-test that dies on its first failure hides the rest.
    _b0 = [b for b in blobs if b[0] == 0xFAF7E8]
    _b1 = [b for b in blobs if b[0] == 0xFB0700]
    if not _b0 or not _b1:
        FAIL.append("PTRBLOB bases missing (0xFAF7E8 found=%d, 0xFB0700 found=%d) -- "
                    "skipping the blob checks, the rest still run" % (len(_b0), len(_b1)))
        b0 = b1 = None
    else:
        b0, b1 = _b0[0], _b1[0]
    if b0 is not None:
        check("blob 0xFAF7E8: entries, stride, payload",
              (b0[4], hex(b0[3]), "0x%06X-0x%06X" % (b0[1], b0[2])),
              (33, "0x74", "0x%06X-0x%06X" % (0xFAF86C, 0xFB0700)))
    if b1 is not None:
        check("blob 0xFB0700: entries, stride, payload",
              (b1[4], hex(b1[3]), "0x%06X-0x%06X" % (b1[1], b1[2])),
              (33, "0x60", "0x%06X-0x%06X" % (0xFB0784, 0xFB1394)))
    check("blob 0xFAF7E8 LAST entry is where the stride says",
          "0x%06X" % w32(0xFAF7E8 + 32 * 4), "0x%06X" % (0xFAF86C + 32 * 0x74))
    check("blob 0xFB0700 LAST entry is where the stride says",
          "0x%06X" % w32(0xFB0700 + 32 * 4), "0x%06X" % (0xFB0784 + 32 * 0x60))
    # the 192-entry dispatch table, whose bound its reader states
    pt = dict((a, (e - a) // 4) for a, e in ptr_tables(d, LO, HI))
    check("dispatch table at 0xFAE3A2 has 192 entries", pt.get(0xFAE3A2), 192)
    check("...and its LAST entry (index 191, 0xFAE69E) is the empty marker",
          "0x%08X" % w32(0xFAE69E), "0x%08X" % 0xFFFFFFFF)
    check("...and 0xFAE6A2, one past it, is not a pointer",
          "0x%08X" % w32(0xFAE6A2), "0x%08X" % 0)
    # ⚠ These three checks exist because the wave-7 skeptic found the prose claiming
    # "88 of its slots hold 0xFFFFFFFF" when the ROM says 116, and NO mode of this
    # script printed either number.  A quantified claim no check reproduces is
    # exactly the shape of this project's recorded "handler count of 35 that was 34".
    _slots = [w32(0xFAE3A2 + 4 * i) for i in range(192)]
    check("dispatch table: empty markers", sum(1 for v in _slots if v == 0xFFFFFFFF), 116)
    check("dispatch table: filled slots", sum(1 for v in _slots if v != 0xFFFFFFFF), 76)
    check("dispatch table: DISTINCT handlers behind those 76 slots",
          len(set(v for v in _slots if v != 0xFFFFFFFF)), 14)
    # ⚠ Also from the wave-7 skeptic: the prose said "19 inline jump tables" and the
    # docstring said module 1 held "eight".  Both were counted by eye.  Pinned here.
    _pt = sorted(a for a, _e in ptr_tables(d, LO, HI))
    _inline = [a for a in _pt if a not in (0xFAE3A2, 0xFAF7E8, 0xFB0700)]
    check("pointer_table segments in the span", len(_pt), 21)
    check("...of which INLINE jump tables (not the dispatch table, not the 2 blob tables)",
          len(_inline), 18)
    check("...ten of them in module 1 (0xFAD800-0xFAE3A0)",
          sum(1 for a in _inline if a < 0xFAE3A2), 10)
    check("...and eight in module 2 (0xFAE800-0xFAF7A5)",
          sum(1 for a in _inline if a > 0xFAE6A1), 8)
    # the three poke lists
    check("RECLIST count", len(rl), 3)
    check("RECLIST addresses",
          ["0x%06X-0x%06X" % (s, s + n) for s, _, n, _ in rl],
          ["0x%06X-0x%06X" % x for x in ((0xFB1A3E, 0xFB1A84),
                                         (0xFB1A84, 0xFB1B48),
                                         (0xFB1B48, 0xFB1ECC))])
    # each list's length is (count x stride) as its reader states
    for lo_, hi_, cnt, stride, rdr in ((0xFB1A3E, 0xFB1A80, 11, 6, 0xFB1887),
                                       (0xFB1A84, 0xFB1B44, 32, 6, 0xFB18EC),
                                       (0xFB1B48, 0xFB1EC8, 32, 28, 0xFB195E)):
        check("list 0x%06X: %d records x %d = its measured length"
              % (lo_, cnt, stride), cnt * stride, hi_ - lo_)
    check("unknown (unexplained) segments", len(pending), 0)
    # every code segment must decode EXACTLY, and every published entry point
    # must land on one of its instruction boundaries -- the desync test
    codesegs = [(a, a + n) for k, a, n in segs if k == "code"]
    bad_dec = [(a, e) for a, e in codesegs if decode_bounds(a, e) is None]
    check("code segments", len(codesegs), 21)
    check("code segments a linear decode does NOT consume exactly",
          bad_dec, [])
    bad_end = [(a, e) for a, e in codesegs if not ends_in_flow_end(a, e)]
    check("code segments whose last instruction is not a flow end",
          ["0x%06X-0x%06X" % (a, e - 1) for a, e in bad_end], [])
    bounds = set()
    for a, e in codesegs:
        bounds |= decode_bounds(a, e) or set()
    ep = set(th)
    for a, e in ptr_tables(d, LO, HI):
        for x in range(a, e, 4):
            v = w32(x)
            if LO <= v < HI:
                ep.add(v)
    check("published entry points (thunk targets + in-span table entries)",
          len(ep), 183)
    bykind = {}
    for x in ep:
        bykind[kindof[x]] = bykind.get(kindof[x], 0) + 1
    check("...by the segment kind they land in (blob = a payload block base)",
          sorted(bykind.items()), [("blob", 66), ("code", 117)])
    check("...that do NOT land on an instruction boundary of a code segment",
          sorted("0x%06X" % x for x in ep
                 if x not in bounds and kindof.get(x) == "code"), [])
    # ★ the honest hole, asserted so it cannot quietly change
    unframed = sorted(v for v in imm
                      if LO <= v < HI and kindof.get(v) == "code")
    check("in-span immediates that land in a `code` segment (BYTE TABLES this "
          "layout does not frame)",
          ["0x%06X" % v for v in unframed], ["0xFADA20", "0xFADD30"])
    # ★ every pointer table's entry count against its READER's own bound.
    # The bound instruction and its text are asserted against the ROM, so this
    # is not a table of remembered numbers; --bounds prints the raw evidence.
    READER_BOUNDS = [
        (0xFADBA9,  12, 0xFADB95, "cp L,0x0b"),
        (0xFADCBE,   3, 0xFADCAB, "cp L,2"),      # after `sub L,0x18`
        (0xFADD77,   4, 0xFADD64, "cp L,3"),
        (0xFADDA0,   2, 0xFADD8D, "cp L,1"),
        (0xFADDC1,   2, 0xFADDAE, "cp L,1"),
        (0xFADDF1,   4, 0xFADDDF, "and L,0x03"),
        (0xFADF77,   4, 0xFADF65, "and L,0x03"),
        (0xFAE04D,   4, 0xFAE036, "and L,0x03"),
        (0xFAE28F,   4, 0xFAE27D, "and B,0x03"),
        (0xFAE30E,   4, 0xFAE2FB, "and L,0x03"),
        (0xFAE3A2, 192, 0xFADB55, "cp A,0xbf"),
        (0xFAE9D0,  16, 0xFAE9A0, "and W,0x0f"),
        (0xFAEDF0,   8, 0xFAEDDB, "and L,0x70"),  # then `srl 0x02,HL`
        (0xFAEE5C,  16, 0xFAEE48, "and L,0x0f"),
        (0xFAF16C,   4, 0xFAF158, "and A,0x03"),
        (0xFAF410,   4, 0xFAF3FE, "and L,0x03"),
        (0xFAF6B8,   4, 0xFAF6A5, "and L,0x03"),
    ]
    counts = dict((a, (e - a) // 4) for a, e in ptr_tables(d, LO, HI))
    check("tables whose measured entry count differs from the count their "
          "READER's bound implies",
          [("0x%06X" % t, counts.get(t), n) for t, n, _, _ in READER_BOUNDS
           if counts.get(t) != n], [])
    check("bound instructions that are not at the address / text cited",
          [("0x%06X" % a, decode_at(a)[1] if decode_at(a) else None)
           for _, _, a, txt in READER_BOUNDS
           if not decode_at(a) or decode_at(a)[1] != txt], [])
    check("pointer tables with a bound cited, of %d found" % len(counts),
          len(READER_BOUNDS), 17)
    print()
    print("  -- and now the LAST element of every table, which is the check")
    print("     this project's error list says gets skipped --")
    # index maps: first and last byte
    check("index map 0xFAF7A6: first byte, LAST byte (0xFAF7C5)",
          (byte(0xFAF7A6), byte(0xFAF7C5)), (0x00, 0x1F))
    check("index map 0xFAF7C7: first byte, LAST byte (0xFAF7E6)",
          (byte(0xFAF7C7), byte(0xFAF7E6)), (0x00, 0x1F))
    check("the two maps are 0x21 apart, so each is 33 bytes",
          0xFAF7C7 - 0xFAF7A6, 0x21)
    # blob 1: block 0 and block 31 have the same record shape, and block 32 is
    # a real (short) block, not a sentinel
    check("blob 0xFAF7E8 block  0 (0xFAF86C) ends in the 0xFF terminator "
          "record", "0x%08X" % w32(0xFAF86C + 0x6C), "0x%08X" % 0xFFFFFFFF)
    check("blob 0xFAF7E8 block 31 (0xFB0678) ends in the 0xFF terminator "
          "record", "0x%08X" % w32(0xFB0678 + 0x6C), "0x%08X" % 0xFFFFFFFF)
    check("blob 0xFAF7E8 LAST block (0xFB06EC) is a real 1-record block",
          ("0x%08X" % w32(0xFB06EC), "0x%08X" % w32(0xFB06F0)),
          ("0x02FF007A", "0x%08X" % 0xFFFFFFFF))
    check("blob 0xFB0700 block  0 (0xFB0784) ends in the 0xFF terminator "
          "record", "0x%08X" % w32(0xFB0784 + 0x58), "0x%08X" % 0xFFFFFFFF)
    check("blob 0xFB0700 block 31 (0xFB1324) ends in the 0xFF terminator "
          "record", "0x%08X" % w32(0xFB1324 + 0x58), "0x%08X" % 0xFFFFFFFF)
    check("blob 0xFB0700 LAST block (0xFB1384) is an immediate terminator",
          "0x%08X" % w32(0xFB1384), "0x%08X" % 0xFFFFFFFF)
    # the poke lists: LAST record of each is where the progression says
    check("list 0xFB1A3E targets are 0x7F32..0x7F3C, step 1, LAST = 0x7F3C",
          [w32(0xFB1A3E + 6 * k) for k in range(11)],
          [0x7F32 + k for k in range(11)])
    # lists B and C address 32 blocks on a 0x40 stride with ONE HOLE: index 8
    # of the arithmetic progression is skipped, so record 8 jumps by 0x80 and
    # the LAST record sits at base + 0x40*32, not base + 0x40*31.  Asserting
    # the naive progression FAILS here; that is the check earning its keep.
    def blocks(b):
        return [b + 0x40 * i for i in range(33) if i != 8]
    check("list 0xFB1A84 targets = 0x76AE + 0x40*i, i in 0..32 minus i=8; "
          "LAST 0x7EAE",
          [w32(0xFB1A84 + 6 * k) for k in range(32)], blocks(0x76AE))
    check("list 0xFB1B48 targets = 0x76CD + 0x40*i, i in 0..32 minus i=8; "
          "LAST 0x7ECD",
          [w32(0xFB1B48 + 28 * k) for k in range(32)], blocks(0x76CD))
    check("list 0xFB1A84 record byte 5 counts 0x00..0x1F on the LAST record too",
          [byte(0xFB1A84 + 6 * k + 5) for k in range(32)], list(range(32)))
    print()
    print("  -- and the record counts and strides come from the READER's own")
    print("     immediates, read back out of the ROM --")
    for a, want, what in ((0xFB1894, b"\x26\x0b", "ld H,0x0b   list A count 11"),
                          (0xFB18D0, b"\xda\x66", "inc 6,DE    list A stride 6"),
                          (0xFB18F9, b"\x26\x20", "ld H,0x20   list B count 32"),
                          (0xFB1942, b"\xda\x66", "inc 6,DE    list B stride 6"),
                          (0xFB196E, b"\x27\x20", "ld L,0x20   list C count 32"),
                          (0xFB198A, b"\x26\x0c", "ld H,0x0c   12 (and,or) pairs"),
                          (0xFB19B3, b"\x40\x1c\x00\x00\x00",
                           "ld XWA,0x1c list C stride 28")):
        got = rom("a")[a - A_BASE:a - A_BASE + len(want)]
        check("0x%06X  %s" % (a, what), got.hex(" "), want.hex(" "))
    check("dispatch-table bound at 0xFADB55 is `cp A,0xbf` (192 entries)",
          rom("a")[0xFADB55 - A_BASE:0xFADB58 - A_BASE].hex(" "), "c9 cf bf")
    check("...and 0xFADB5C scales the index by 4 (`sll 0x02,WA`)",
          rom("a")[0xFADB5C - A_BASE:0xFADB5F - A_BASE].hex(" "), "d8 ee 02")
    print()
    print("  checks run: %d   failures: %d" % (CHECKS[0], len(FAIL)))
    return 1 if FAIL else 0


CHECKS = [0]
_orig_check = check


def check(msg, got, want):                                       # noqa: F811
    CHECKS[0] += 1
    return _orig_check(msg, got, want)


def main():
    d = rom("a")
    if "--null" in sys.argv:
        rev = None
        if "--rev" in sys.argv:
            rev = sys.argv[sys.argv.index("--rev") + 1]
        null(rev)
        return 0
    if "--selftest" in sys.argv:
        return selftest()
    if "--tables" in sys.argv:
        print("PTRTABs (>= %d consecutive LE32 words inside 0x%06X-0x%06X):"
              % (PTR_MIN, PTR_LO, PTR_HI))
        for a, e in ptr_tables(d, LO, HI):
            ent = [w32(x) for x in range(a, e, 4)]
            print("  0x%06X  %3d entries  ends 0x%06X  first 0x%06X  last 0x%06X"
                  % (a, len(ent), e, ent[0], ent[-1]))
        print()
        print("PTRBLOBs (a table whose entries rise by a constant stride and")
        print("whose first entry is the byte after the table):")
        for a, s, e, st, n in ptr_blobs(d, LO, HI):
            print("  table 0x%06X  %d entries  stride 0x%X" % (a, n, st))
            print("      payload 0x%06X-0x%06X  (%d bytes = %d x 0x%X + tail %d)"
                  % (s, e, e - s, (e - s) // st, st, (e - s) % st))
            print("      stride verified on the LAST entry: 0x%06X == 0x%06X"
                  % (w32(a + 4 * (n - 1)), s + (n - 1) * st))
        return 0
    if "--reclists" in sys.argv:
        segs, conflicts, pending, ok, seen, rl, imm = build()
        print("RECLISTs -- residue runs closed by a back-pointer that the")
        print("decoded code loads as a 32-bit immediate:")
        for s, P, n, rdr in rl:
            print("  list 0x%06X-0x%06X  %d bytes   slot 0x%06X -> 0x%06X"
                  % (s, P, P - s, P, w32(P)))
            print("      slot address loaded at: %s"
                  % ", ".join("0x%06X" % r for r in rdr))
        return 0
    if "--seeds" in sys.argv:
        th = thunk_entries()
        fc = far_calls()
        print("thunk slots into the span: %d  (%d distinct targets)"
              % (len(th), len(set(t for _, t in th))))
        for s, t in th:
            print("    T_%06X -> 0x%06X" % (s, t))
        print("opcode-anchored call/jp targets in the span: %d" % len(fc))
        for t in sorted(fc):
            print("    0x%06X  from %s%s"
                  % (t, ", ".join("%s:0x%06X" % x for x in fc[t][:3]),
                     " ..." if len(fc[t]) > 3 else ""))
        print("PTRTAB entries landing in the span: %d"
              % len(table_entry_seeds(d)))
        return 0
    if "--barrier" in sys.argv:
        segs, _, _, _, _, rl, _ = build()
        block = barriers(d, LO, HI)
        for s_, _, n_, _ in rl:
            block |= set(range(s_, s_ + n_))
        sd = sorted(seeds_of(d))
        wb = descend(LO, HI, sd, block)
        nb = descend(LO, HI, sd, set())
        print("code walk WITH the barrier:    %6d bytes (%.1f%% of %d)"
              % (len(wb), 100.0 * len(wb) / (HI - LO), HI - LO))
        print("code walk WITHOUT the barrier: %6d bytes (%.1f%%)"
              % (len(nb), 100.0 * len(nb) / (HI - LO)))
        print("of those, %d bytes are inside an object a content rule framed --"
              % len(nb & block))
        print("that is what the barrier removes.")
        return 0
    segs, conflicts, pending, ok, seen, rl, imm = build()
    if "--tablebases" in sys.argv:
        segs, _, _, _, seen, _, imm = build()
        kindof = {}
        for k, a, n in segs:
            for x in range(a, a + n):
                kindof[x] = k
        bounds = set()
        for k, a, n in segs:
            if k == "code":
                bounds |= decode_bounds(a, a + n) or set()
        print("Every in-span address DECODED CODE loads as a 32-bit immediate,")
        print("with the segment it lands in.  ★ A row that says `code` and NOT")
        print("A BOUNDARY is a DATA OBJECT THIS LAYOUT DOES NOT FRAME: the")
        print("content rules find POINTER tables, not BYTE tables, and a byte")
        print("table sits inside a code segment looking like instructions.")
        print("A converter must carve these out by hand.")
        unframed = []
        for v in sorted(imm):
            if not (LO <= v < HI):
                continue
            r = sorted(imm[v])
            note = kindof.get(v, "?")
            if note == "code":
                note += "  BOUNDARY" if v in bounds else "  ** NOT A BOUNDARY **"
                unframed.append(v)
            print("  0x%06X  %-26s loaded at %s"
                  % (v, note, ", ".join("0x%06X" % x for x in r[:4])
                     + (" ..." if len(r) > 4 else "")))
        if not unframed:
            return 0
        # what bounds each unframed base, so a converter does not have to guess
        ep = set(t for _, t in thunk_entries())
        for a, e in ptr_tables(d, LO, HI):
            for x in range(a, e, 4):
                if LO <= w32(x) < HI:
                    ep.add(w32(x))
        for k, a, n in segs:
            if k != "code":
                continue
            for p2 in sorted(decode_bounds(a, a + n) or ()):
                for t in TC.branch_targets(decode_at(p2)[1]):
                    if LO <= t < HI:
                        ep.add(t)
        framed = sorted(a for k, a, n in segs if k not in ("code", "align"))
        print()
        print("  WHAT BOUNDS EACH ONE (all four numbers read off the ROM):")
        for v in unframed:
            nxt_ep = min([x for x in ep if x > v] or [HI])
            nxt_ob = min([x for x in framed if x > v] or [HI])
            cap = min(nxt_ep, nxt_ob)
            lastnz = max([x for x in range(v, cap)
                          if d[x - A_BASE]] or [v])
            print("    0x%06X  loaded at 0x%06X" % (v, sorted(imm[v])[0]))
            print("       next published entry point : 0x%06X" % nxt_ep)
            print("       next rule-framed object    : 0x%06X" % nxt_ob)
            print("       last non-zero byte before  : 0x%06X  -> a table of"
                  " %d bytes if the trailing 0x00 run belongs to it"
                  % (lastnz, cap - v))
            print("       bytes: %s"
                  % d[v - A_BASE:min(v + 16, cap) - A_BASE].hex(" "))
        return 0
    if "--bounds" in sys.argv:
        segs, _, _, _, _, _, imm = build()
        print("Does the READER of each pointer table state an index bound, and")
        print("does that bound agree with the entry count the content rule")
        print("measured?  For each table with a loader, the 40 bytes ending at")
        print("the loader are decoded and every `cp R,imm` / `and R,imm` is")
        print("printed; a `cp R,n` guarded by an UGT/NC branch means n+1")
        print("entries, an `and R,m` means m+1.")
        for a, e in ptr_tables(d, LO, HI):
            n = (e - a) // 4
            rd = sorted(imm.get(a, ()))
            if not rd:
                print("  0x%06X %3d entries   NO LOADER" % (a, n))
                continue
            r = rd[0]
            found = []
            p2 = r - 40
            while p2 < r:
                dec = decode_at(p2)
                if dec is None:
                    p2 += 1
                    continue
                if re.match(r"^(cp|and)\s+\w+,(0x[0-9a-f]+|\d+)$",
                            dec[1]):
                    found.append((p2, dec[1]))
                p2 += dec[0]
            print("  0x%06X %3d entries   loader 0x%06X   %s"
                  % (a, n, r,
                     "; ".join("0x%06X %s" % f for f in found[-4:]) or "-"))
        return 0
    if "--accepted" in sys.argv:
        segs, _, _, ok, _, _, _ = build()
        print("Runs the DESCENT never reached that accept() promoted to code by")
        print("shape alone -- self-consistent linear decode, every relative")
        print("branch on a boundary, and a flow end at the tail.  These are the")
        print("least-evidenced code in the span; a converter should read them.")
        print("(The discriminator's measured false-accept rate on proven DATA")
        print(" is 1 in 1,884 chunks -- notes/prom_b_f0ea9f_layout.py")
        print(" --null-accept -- and 0 above 32 bytes.)")
        tot = 0
        for a, e in sorted(ok):
            tot += e - a
            print("  0x%06X-0x%06X  %5d bytes" % (a, e - 1, e - a))
        ncode = sum(n for k, _, n in segs if k == "code")
        print("  %d runs, %d bytes (%.1f%% of the %d code bytes)"
              % (len(ok), tot, 100.0 * tot / ncode, ncode))
        return 0
    if "--readers" in sys.argv:
        print("For every object a content rule framed: does DECODED CODE load")
        print("its base address as a 32-bit immediate?  The address printed is")
        print("the address of the LOADING INSTRUCTION, not one byte past it.")
        for k, a, n in segs:
            if k in ("code", "align"):
                continue
            r = sorted(imm.get(a, ()))
            print("  %-14s 0x%06X %5d  %s"
                  % (k, a, n,
                     ("loaded at " + ", ".join("0x%06X" % x for x in r))
                     if r else "NO in-span instruction loads this address"))
        return 0
    if "--conflicts" in sys.argv:
        print("descent bytes reclaimed by a content rule: %d  (MUST be 0)"
              % len(conflicts))
        for a in conflicts[:80]:
            print("  0x%06X" % a)
        return 0
    if "--residue" in sys.argv:
        print("runs that no rule and no code walk explains: %d (%d bytes)"
              % (len(pending), sum(e - s for s, e in pending)))
        for s, e in pending:
            raw = d[s - A_BASE:e - A_BASE]
            for i in range(0, len(raw), 16):
                print("   %06X  %-47s |%s|"
                      % (s + i, raw[i:i + 16].hex(" "),
                         "".join(chr(c) if 32 <= c < 127 else "."
                                 for c in raw[i:i + 16])))
            print()
        print("segments the report calls `unknown`:")
        for k, s, n in segs:
            if k == "unknown":
                print("   0x%06X-0x%06X  %d bytes" % (s, s + n - 1, n))
        return 0
    if "--python" in sys.argv:
        print("LAYOUT = [")
        for k, s, n in segs:
            print('    ("%s", 0x%06X, 0x%04X),' % (k, s, n))
        print("]")
        return 0
    tot = {}
    for k, s, n in segs:
        print("  %-14s 0x%06X-0x%06X  %6d" % (k, s, s + n - 1, n))
        tot[k] = tot.get(k, 0) + n
    print("  ---- " + "  ".join("%s %d" % (k, v) for k, v in sorted(tot.items())))
    print("  substantive %d of %d"
          % (sum(v for k, v in tot.items() if not k.startswith("pad")),
             HI - LO))
    print("  segments %d   accepted self-consistent runs %d   "
          "barrier conflicts %d   unknown runs %d"
          % (len(segs), len(ok), len(conflicts), len(pending)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
