#!/usr/bin/env python3
"""The code/data LAYOUT of prom_b 0xF4F000-0xF54FFF -- wave 7, lane B2.

WHAT THE SPAN IS.  Two modules and a screen.  0xF4F000-0xF5220D is a table-heavy
block whose three biggest objects are tables of PROM_A addresses; 0xF53000-0xF54247
is code, entered through the twelve slots of the thunk run T_F42E40-T_F42E6C and
through thirteen display-list call sites of its own; 0xF542E1-0xF54FBE is that
code's screen -- fifteen display lists whose text reads `PERCUSSIVE T0NE DECAY  :`,
`PERCUSSIVE T0NE LEVEL  :`, `DRAWBAR ATTACK TIME    :`, `DRAWBAR RELEASE TIME   :`
and `SOUND MODE`, followed by the bitmaps three of their records point at.
⚠ That is what the STRINGS and the record pointers say.  No routine in the span is
named here; every one is `sub_XXXXXX`, per this tree's rule.

QUESTION IT ANSWERS
  "Which bytes of 0xF4F000-0xF55000 are instructions, which are tables, which are
   display lists, and WHY is each code byte code?"  Every byte of the span is
   assigned, in address order, with no gap and no overlap.  Nothing is typed by
   hand: `--python` prints the layout, `--selftest` re-derives it.

WHAT IS DIFFERENT FROM notes/prom_b_f0ea9f_layout.py, WHICH THIS IMPORTS
  Round 5's rule set transferred to round 6's span unchanged; it does NOT transfer
  to this one.  Five things are new and every one of them exists because the
  round-5/6 set, applied here, produced a WRONG boundary that the byte gate cannot
  see.  Each carries its own null.

  1. ROMTAB (`rom_tables`, >= 7 entries, window 0x00F00000-0x00FFFFFF).
     Round 5 widened L's PTRTAB window from one 64 KiB bank to prom_b's whole
     image; this span's three largest tables point into PROM_A.  1,420 bytes.
     `--null-romtab`.
  2. LINK (`link_tables`).  A self-referential 6-byte record table at 0xF4FF61:
     782 records `[u16 key][u32 pointer]`, 779 non-zero pointers, ALL 779 landing
     exactly on a record boundary of the table itself.  4,692 bytes -- 19% of the
     span -- that no earlier rule frames.  `--null-link`.
  3. FILL must not swallow an ENTRY POINT (`fill_runs_ex`).  0x0E is `ret`, so a
     padding run and a one-instruction handler are the same byte.  Worth ONE byte
     here and it is the span's first entry point.  `--null-fill`.
  4. INTERSTITIAL DISPLAY LISTS (`dl_interstitials`).  A gap that the interpreter's
     own framing walk consumes exactly, landing on a call-site-proven list, is a
     display list.  `--null-interstitial`.
  5. FALSE SEEDS (`far_calls_ex`).  `L.far_calls` is a byte scan; two of its
     twenty in-span targets are `1B`/`1D` bytes INSIDE a display-list record.  One
     of them, 0xF54710, is named as a DATA pointer by the very record it sits in,
     and following it decoded 260 bytes of bitmap as instructions.  `--null-seed`.

  Plus one idiom rule, `stub_idiom()`, which is a correction to L's RAMTAB.

THE NULL CORPORA
  * CONTENT rules (PTRTAB/RAMTAB/BITTAB/IDENT/ASCII/BYTEMAP/ROMTAB/LINK): proven
    CODE -- a content rule that fires inside proven instruction text is a false
    positive.  `--null-ptr`, `--null-romtab`, `--null-link`.
  * `accept()`, which promotes an unreached run TO code: proven DATA (the 4,011
    display-list records).  `--null-accept`, inherited from round 5.
  * STRIDED, which demotes a table: proven DISPATCH TABLES.  `--null-stride`.
  * The INTERSTITIAL rule: proven CODE again, as windows ending at a run's end.
    `--null-interstitial`.
  * FILL truncation and the seed filter: the whole of prom_b.  `--null-fill`,
    `--null-seed`.

RUN
  python3 notes/prom_b_f4f000_layout.py                  # the LAYOUT table
  python3 notes/prom_b_f4f000_layout.py --null           # every null, one process
  python3 notes/prom_b_f4f000_layout.py --selftest       # 40 checks, incl. the LAST
  python3 notes/prom_b_f4f000_layout.py --provenance     # WHY each segment is code
  python3 notes/prom_b_f4f000_layout.py --dl             # the display lists
  python3 notes/prom_b_f4f000_layout.py --holes          # what is NOT claimed, and why
  python3 notes/prom_b_f4f000_layout.py --conflicts      # descent-vs-barrier (0)
  python3 notes/prom_b_f4f000_layout.py --residue        # unsplit runs, with hex
  python3 notes/prom_b_f4f000_layout.py --python         # paste-ready LAYOUT
  python3 notes/prom_b_f4f000_layout.py --all            # all of it, one process
Exit status is non-zero if a --null or --conflicts or --selftest run finds
something it must not.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_f65000_layout as L                                   # noqa: E402
import prom_b_f0ea9f_layout as LY                                  # noqa: E402
import prom_b_module_trace as MT                                   # noqa: E402
import prom_b_thunk_table as TT                                    # noqa: E402
import prom_b_display_lists as DL                                  # noqa: E402
import prom_b_dl_call_shapes as CS                                 # noqa: E402
import prom_b_dl_length_audit as LA                                # noqa: E402
import trace_code as TC                                            # noqa: E402

LO, HI = 0xF4F000, 0xF55000
LY.LO, LY.HI = LO, HI          # every LY helper reads these at call time
B_BASE, A_BASE = 0xF00000, 0xF80000

ROMTAB_MIN = 7                 # entries; measured, see null_romtab()
ROM_LO, ROM_HI = 0x00F00000, 0x01000000
LINK_MIN = 8                   # records; measured, see null_link()
INTER_MIN = 2                  # records; measured, see null_interstitial()

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-62s %-26s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


# ============================================================ display lists
_dl = {}


def images():
    if "img" not in _dl:
        _dl["img"] = DL.load()
    return _dl["img"]


def handler_tables():
    if "tab" not in _dl:
        _dl["tab"] = LA.tables(images()[1])
    return _dl["tab"]


def loose_walk(s, e):
    """The committed framing walk: opcode < 0x24, length >= 2, land exactly."""
    d = L.rom()
    p, n = s, 0
    while p < e:
        op, ln = d[p - B_BASE], d[p + 1 - B_BASE]
        if op >= 0x24 or ln < 2 or p + ln > e:
            return None
        p += ln
        n += 1
    return n if p == e else None


def strict_walk(s, e, interp):
    """loose_walk() PLUS the length rule of notes/prom_b_dl_length_audit.py.

    Every record's opcode must index a handler that lane has disassembled, and
    the record's length byte must equal (or reach) the length that handler's own
    instructions imply.  On 74,669 windows of proven instruction text the loose
    walk lands exactly 124 times and the strict walk 63 -- and all 63 are
    ONE-record walks, so at INTER_MIN = 2 records the strict rule's measured
    false-positive rate on proven code is ZERO.  `--null-interstitial`."""
    d = L.rom()
    ta, tb = handler_tables()
    tab, imp = (ta, LA.IMPLIED_A) if interp == "A" else (tb, LA.IMPLIED_B)
    p, n = s, 0
    while p < e:
        op, ln = d[p - B_BASE], d[p + 1 - B_BASE]
        if op >= len(tab) or ln < 2 or p + ln > e:
            return None
        good, _h = LA.check(op, ln, tab, imp)
        if good is not True:
            return None
        p += ln
        n += 1
    return n if p == e else None


def framed_sites(lo=None, hi=None):
    """[(shape, site, start, end, interp)] for EVERY call site whose list frames.

    ⚠ Kept separate from call_site_lists(), which is keyed by list START and
    therefore collapses two sites that name the same list.  Two do:  0xF5373D and
    0xF53750 both name 0xF543C4-0xF543D5, and keying by start dropped one of them
    from the seed set, which cost 19 bytes of code at 0xF5373D."""
    lo = LO if lo is None else lo
    hi = HI if hi is None else hi
    a, b = images()
    _ta, tb = handler_tables()
    out = []
    for shape, site, s, e, t in CS.scan(a, b):
        interp = "B" if t in (CS.RUN_B, CS.STACK_B, CS.RUN_ONE_B) else "A"
        if shape == 3:
            if not (B_BASE <= s < B_BASE + len(b) - 2):
                continue
            op, ln = b[s - B_BASE], b[s - B_BASE + 1]
            if op >= len(tb):
                continue
            kind, want = LA.IMPLIED_B[tb[op]]
            if not (ln >= want if kind == "min" else ln == want):
                continue
            e = s + ln
        elif not (B_BASE <= s < e <= B_BASE + len(b) and loose_walk(s, e)):
            continue
        if lo <= s and e <= hi:
            out.append((shape, site, s, e, interp))
    return sorted(out)


def call_site_lists(lo=None, hi=None):
    """{start: (end, interpreter, shape, site, records)} for every display list
    a CALL SITE names whose framing walk lands exactly, restricted to [lo,hi).

    The scanner is notes/prom_b_dl_call_shapes.py's, imported rather than copied.
    Shape 3 names ONE interpreter-B record with no end pointer, so there is no
    framing walk: it is accepted only if the record's length byte equals the
    length its handler implies."""
    lo = LO if lo is None else lo
    hi = HI if hi is None else hi
    a, b = images()
    _ta, tb = handler_tables()
    out = {}
    for shape, site, s, e, t in CS.scan(a, b):
        interp = "B" if t in (CS.RUN_B, CS.STACK_B, CS.RUN_ONE_B) else "A"
        if shape == 3:
            if not (B_BASE <= s < B_BASE + len(b) - 2):
                continue
            op, ln = b[s - B_BASE], b[s - B_BASE + 1]
            if op >= len(tb):
                continue
            kind, want = LA.IMPLIED_B[tb[op]]
            if not (ln >= want if kind == "min" else ln == want):
                continue
            e, n = s + ln, 1
        else:
            n = loose_walk(s, e) if B_BASE <= s < e <= B_BASE + len(b) else None
            if not n:
                continue
        if lo <= s and e <= hi:
            out[s] = (e, interp, shape, site, n)
    return out


def dl_interstitials(claimed, lists):
    """Gaps that the framing walk turns into display lists, to a fixpoint.

    THE RULE.  Take the maximal run of bytes NO other rule claims that ends
    exactly where an accepted display list begins.  If the strict walk under
    THAT list's own interpreter consumes the run exactly in >= INTER_MIN
    records, the run is a display list too, and it becomes an accepted list so
    the next gap can be tested against it.

    ⚠ WHAT IT DELIBERATELY DOES NOT DO.  It never re-starts the walk at an
    inner offset of the gap: the run is taken whole or not at all.  A rule that
    slid the start until something framed would fit anything.  The cost is
    stated in --holes: three gaps of this span (0xF542E1, 0xF542F9, 0xF546FA)
    frame as exactly ONE record each, which is the case whose measured
    false-positive rate is 0.084% rather than zero, so they stay `data`."""
    acc = dict(lists)
    for _ in range(8):
        cov = set(claimed)
        for s, (e, _i, _sh, _si, _n) in acc.items():
            cov |= set(range(s, e))
        grew = False
        for T in sorted(acc):
            interp = acc[T][1]
            if not (LO <= T < HI):
                continue
            s = T
            while s - 1 >= LO and (s - 1) not in cov:
                s -= 1
            if s == T:
                continue
            n = strict_walk(s, T, interp)
            if n is not None and n >= INTER_MIN:
                acc[s] = (T, interp, 0, 0, n)
                cov |= set(range(s, T))
                grew = True
        if not grew:
            break
    return acc


def dl_pointer_values(lists):
    """Every prom_b address spelled as a 32-bit LE word ANYWHERE inside an
    accepted display-list record.

    These are DATA pointers -- the op-3 handler at 0xF31ABE does
    `ld XIY,(XIY+2) / swi 7`, so the word at record+2 is a bitmap source -- and
    they are what `far_calls_ex()` subtracts.  Scanned at EVERY offset, not only
    at a record's known pointer field, because only two handlers of the
    interpreter pair have had their field layout established."""
    d = L.rom()
    out = set()
    for s, (e, _i, _sh, _si, _n) in lists.items():
        for p in range(s, e - 3):
            v = L.w32(d, p)
            if B_BASE <= v < 0xF80000:
                out.add(v)
    return out


def dl_sites_in(lists, lo=None, hi=None):
    """Call-site ADDRESSES inside [lo,hi) -- a code SEED, not a data rule.

    A shape-2 site is `lda XBC,end / push XBC / lda XWA,start / push XWA /
    call 0xF42E0x`: thirteen bytes of which four are fixed opcodes and two are
    ROM addresses the framing walk then confirms are a display list.  That is an
    instruction boundary on far better evidence than a linear decode, and this
    span's 0xF536C5-0xF538A8 block is reached from these and from nothing else.

    ⚠ The site counts only if ITS OWN list framed.  An earlier draft tested
    membership in the MERGED range list instead, which dropped 8 of this span's
    13 sites and left 250 bytes of obvious code (0xF536FF-0xF537F8: nine `calr`s
    and a `ret`) inside a `data` segment."""
    lo = LO if lo is None else lo
    hi = HI if hi is None else hi
    return set(site for _sh, site, s, _e, _i in framed_sites(0, 0x1000000)
               if lo <= site < hi and s in lists)


def dl_ranges(lists=None):
    """The accepted lists as maximal merged intervals -- the barrier."""
    lists = call_site_lists() if lists is None else lists
    ivs = sorted((s, v[0]) for s, v in lists.items())
    out = []
    for s, e in ivs:
        if out and s <= out[-1][1]:
            out[-1][1] = max(out[-1][1], e)
        else:
            out.append([s, e])
    return [(s, e) for s, e in out]


# ==================================================== the widened POINTER rule
def rom_tables(d, lo, hi, minent=None):
    """Maximal chains of >= ROMTAB_MIN consecutive 4-byte LE words anywhere in
    the CPU-1 ROM window 0x00F00000-0x00FFFFFF -- prom_a AND prom_b.

    THE RULE THIS SPAN NEEDED AND NO EARLIER prom_b ROUND DID.  Round 5 widened
    L's PTRTAB window to prom_b's own image and stopped there.  The three largest
    tables in this span point the OTHER way: 0xF4F800 (68 entries), 0xF4F916 (89)
    and 0xF4FB1C (199) hold PROM_A addresses -- 0x00FB22C8, 0x00FB2820,
    0x00FB4BDD -- and prom_b's window cannot see one of them.  1,420 bytes came
    out as `data` until this rule was added.

    WHY THE THRESHOLD IS SEVEN AND NOT THREE (a measurement, not a preference;
    `--null-romtab` prints it).  0xF511E9-0xF51E1F is an array of variable-length
    records that BEGINS with three or four prom_a pointers and ends with parameter
    bytes, and a record's tail `01 00 ff 00` reads as the word 0x00FF0001, which
    is inside the window.  The chain the rule then finds starts FOUR BYTES BEFORE
    the record it belongs to.  Over this span:

        >= 3 entries   114 objects, 109 of them inside that record array
        >= 5 entries    16 objects,  13 of them inside it
        >= 6 entries     7 objects,   1 of them inside it (0xF51E04, whose
                                       record starts at 0xF51E08)
        >= 7 entries     6 objects,   0 inside it

    Seven is the smallest threshold at which the rule frames nothing inside the
    record array, and the six objects it does frame have 68, 89, 199, 7, 225 and
    23 entries.  The record array itself is therefore NOT framed here; it is
    reported as `data` with the hole stated, per this tree's rule that an honest
    hole beats a plausible guess."""
    minent = ROMTAB_MIN if minent is None else minent
    out, p = [], lo
    while p < hi - 3:
        k, q = 0, p
        while q <= hi - 4 and ROM_LO <= L.w32(d, q) < ROM_HI:
            k += 1
            q += 4
        if k >= minent:
            out.append((p, p + 4 * k))
            p += 4 * k
        else:
            p += 1
    return out


# ============================================ the self-referential LINK table
def _link_walk(d, a, hi):
    """(end, records, non-null pointers) for the link-table walk from `a`."""
    p, n, ptrs = a, 0, []
    while p + 6 <= hi:
        v = L.w32(d, p + 2)
        if v:
            if v < a or (v - a) % 6:
                break
            ptrs.append(v)
        p += 6
        n += 1
    e = p
    while ptrs and ptrs[-1] >= e:      # a pointer past the end retracts the walk
        n -= 1
        e -= 6
        ptrs = ptrs[:-1]
    if any(v >= e for v in ptrs):
        return a, 0, 0
    return e, n, len(ptrs)


def link_tables(d, lo, hi, minrec=None):
    """Maximal runs of 6-byte records `[u16 key][u32 pointer]` where every
    non-zero pointer lands on a record boundary OF THE RUN ITSELF.

    A SELF-CHECKING structure, the strongest kind of framing evidence this tree
    accepts (the same argument as the display-list walk).  In this span it frames
    0xF4FF61-0xF511B4: 782 records, 779 non-zero pointers, and all 779 land
    exactly on a 6-byte boundary measured from 0xF4FF61; the other three are
    0x00000000.

    That is also how the framing DIRECTION is pinned.  Read the other way round
    -- `[u32 pointer][u16 key]` starting at 0xF4FF63 -- the same bytes tile just
    as tidily, but then every pointer would land two bytes BEFORE a record start.
    They do not, so the key comes first.

    NULL (`--null-link`): ZERO hits in the proven-instruction-text corpus at every
    threshold from 8 to 64 records, and exactly ONE hit in the whole 512 KiB of
    prom_b -- this one."""
    minrec = LINK_MIN if minrec is None else minrec
    out, p = [], lo
    while p < hi:
        e, n, np = _link_walk(d, p, hi)
        if n >= minrec and np >= n // 2:
            out.append((p, e))
            p = e
        else:
            p += 1
    return out


# ==================================== FILL must not swallow an ENTRY POINT
def thunk_slots(lo=0xF00000, hi=0xF80000):
    """[(slot, kind, target)] for every thunk-table slot naming [lo,hi).

    SLOTS, not targets: this span's run T_F42E40-T_F42E6C has TWELVE slots and
    ELEVEN distinct targets, because T_F42E58 and T_F42E5C both name 0xF5301A.
    Quoting one number for the other is how a handler count of 35 became 34 in
    this project's error list."""
    b = L.rom()
    out = []
    for slot in range(0x40000, 0x44018, 4):
        k, v = TT.classify(b, slot)
        if k in ("jp", "ptr") and lo <= v < hi:
            out.append((B_BASE + slot, k, v))
    return out


def thunk_targets(lo=0xF00000, hi=0xF80000):
    """Targets of EVERY thunk-table slot -- the `jp` slots AND the `ptr` slots.

    notes/prom_b_module_trace.py's thunk_entries() takes only slots holding
    `jp addr24` (opcode 0x1B).  T_F42E40, the FIRST slot of this span's whole
    thunk run, holds the bare word 0x00F53000 instead, which
    scripts/analysis/prom_b_thunk_table.py classifies as `ptr`.  An entry-point
    count of 11 here instead of 12 is that difference, and 0xF53000 is exactly
    the byte the FILL correction below is about."""
    b = L.rom()
    out = set()
    for slot in range(0x40000, 0x44018, 4):
        k, v = TT.classify(b, slot)
        if k in ("jp", "ptr") and lo <= v < hi:
            out.add(v)
    return out


def fill_runs_ex(d, lo, hi, n=None):
    """L.fill_runs(), TRUNCATED at any thunk-table target inside the run.

    THE CORRECTION THIS SPAN FORCED, and it is worth exactly one byte.  0x0E is
    `ret`, so a padding run and a one-instruction do-nothing handler are the same
    byte; L.fill_runs() therefore swallows a `ret` stub a thunk slot points at.
    Here it swallows 0xF53000 -- the LAST byte of the 3,571-byte run at 0xF5220E,
    the target of slot T_F42E40, and the first byte of a module that starts on a
    0x1000 boundary and whose next twenty bytes are more `ret` stubs.

    NULL (`--null-fill`): over all 109 fill runs of prom_b (63,277 bytes) and all
    714 thunk-table targets in prom_b, this truncation fires ONCE -- here.
    ⚠ It is keyed on thunk-table targets only, NOT on L.far_calls(): that scanner
    is an opcode-anchored byte scan and finds three `call`/`jp` targets inside
    prom_b fill runs (0xF414E0, 0xF4BE01, 0xF4F5F4) which are 0x0E bytes read as
    an address, not entry points."""
    tg = thunk_targets()
    lim = n or L.FILL_MIN
    out = []
    for s, e in L.fill_runs(d, lo, hi, lim):
        cut = sorted(t for t in tg if s <= t < e)
        e2 = cut[0] if cut else e
        if e2 - s >= lim:
            out.append((s, e2))
    return out


# ============================== the `jp` OVER A `ret`-STUB TABLE idiom
def stub_idiom(d, lo, hi, minslots=2):
    """`jp T` followed immediately by 4-byte slots of `0E 00 00 00` ending at T.

    SELF-CHECKING, and that is why it is allowed to overrule a content rule: the
    jump's target is read out of the instruction, the run's end is counted from
    the bytes, and the rule fires only when the two agree.  It occurs EXACTLY
    ONCE in the whole 512 KiB of prom_b, at 0xF4F2C2 -> 0xF4F2DA over five slots
    (`--null-idiom`), and there it is the fix for a wrong boundary: L's RAMTAB
    rule frames 0xF4F2C5-0xF4F2D8 as a table of five RAM addresses, starting one
    byte inside the `jp` and reading the five `ret` stubs as the value 0x00000E00.

    ⚠ THE SAME DEFECT IS ALREADY IN THE TREE and this lane may not fix it:
    gen_prom_b_f0ea9f_module.py's frozen LAYOUT carries `("ramtab", 0xF0EFFF, 6)`,
    which is 0xF0F000's six `0E 00 00 00` stubs read one byte early as six RAM
    addresses of 0x0E00.  `--null-idiom` prints the bytes."""
    out = []
    for a in range(lo, hi - 8):
        if d[a - B_BASE] != 0x1B:
            continue
        t = d[a + 1 - B_BASE] | d[a + 2 - B_BASE] << 8 | d[a + 3 - B_BASE] << 16
        p, k = a + 4, 0
        while p + 4 <= hi and d[p - B_BASE] == 0x0E and \
                d[p + 1 - B_BASE] == 0 and d[p + 2 - B_BASE] == 0 and \
                d[p + 3 - B_BASE] == 0:
            p += 4
            k += 1
        if k >= minslots and p == t:
            out.append((a, t, k))
    return out


def ram_tables_ex2(d, lo, hi):
    """L.ram_tables_ex() minus any chain that overlaps a stub_idiom() range."""
    bad = [(a, t) for a, t, _k in stub_idiom(d, lo, hi)]
    return [(a, e) for a, e in L.ram_tables_ex(d, lo, hi)
            if not any(a < y and x < e for x, y in bad)]


# ======================================================== the seed filter
def far_calls_ex(d, lo, hi, ptrvals):
    """L.far_calls() minus every target a display-list record NAMES as a pointer.

    L.far_calls scans EVERY byte for opcode 0x1B/0x1D and is documented as an
    upper bound used only to seed.  Two of its twenty in-span targets are that
    bound being wrong: 0xF546CA `jp 0xF546DA` and 0xF54700 `jp 0xF54710` are both
    bytes INSIDE a display-list record, and 0xF54710 is named as a data pointer
    by the very record the fake `jp` lies in.  Following it decoded 260 bytes of
    bitmap as instructions.

    NULL (`--null-seed`): image-wide the filter removes 32 of prom_b's 1,931
    far_calls targets (1.7%); in this span it removes exactly those two and
    nothing else."""
    return set(t for t in L.far_calls(d, lo, hi) if t not in ptrvals)


# ============================================================== the layout
def barriers(d, lo, hi, lists=None):
    """Every byte a content rule claims -- the set the code walk may not enter.

    ⚠ This does NOT call LY.barriers(), and that is the point: LY.barriers()
    calls L.fill_runs(), the UNTRUNCATED one, so 0xF53000 stayed inside the
    barrier and the descent could not take it as a seed even after fill_runs_ex()
    had stopped calling it padding.  The layout then showed `data 0xF53000` and
    `code 0xF53001` -- a one-byte hole exactly at the span's first entry point.
    The rule list is spelled out here so that swapping a rule cannot leave its
    predecessor in the barrier."""
    b = set()
    for rule in (L.ptr_tables, ram_tables_ex2, L.bit_tables, L.ident_runs,
                 L.ascii_runs, LY.monotone_maps, rom_tables, link_tables,
                 fill_runs_ex):
        for a, e in rule(d, lo, hi):
            b |= set(range(a, e))
    for a, e in dl_ranges(lists):
        b |= set(range(a, e))
    return b


_built = []


def build():
    """The layout, cached (it costs ~40 s).

    ORDER MATTERS AND IS STATED.  The content rules paint in the order below and
    a later one overwrites an earlier one, so the LAST rule wins where two
    disagree:

      ascii, ident, bytemap, ramtab, bittab, ptrtab  -- round 5's set, unchanged
      romtab   -- the widened pointer window; it CONTAINS the three prom_b-window
                  ptrtab objects it overlaps (0xF51E6C, 0xF51E8A, 0xF54248), so
                  painting it later merges them rather than splitting them
      fill     -- truncated at a thunk-table target
      link     -- the self-referential 6-byte record table
      dl       -- the display lists, call-site-proven and interstitial

    `dl` paints last because four of this span's seven ASCII runs are TEXT
    OPERANDS INSIDE display-list records -- `PERCUSSIVE T0NE DECAY  :` and its
    three neighbours all sit inside 0xF544AD-0xF546A3 -- and letting ASCII win
    there would split one call-site-proven object into five."""
    if _built:
        return _built[0]
    d = L.rom()
    proven = call_site_lists()
    block0 = barriers(d, LO, HI, proven)
    lists = dl_interstitials(block0 - set(
        x for s, v in proven.items() for x in range(s, v[0])), proven)
    dls = dl_ranges(lists)
    block = barriers(d, LO, HI, lists)
    idiom = stub_idiom(d, LO, HI)
    ptrvals = dl_pointer_values(lists)
    seed = (LY.proven_call_sites(LO, HI) | thunk_targets(LO, HI)
            | far_calls_ex(d, LO, HI, ptrvals) | LY.table_entry_seeds(d, LO, HI)
            | dl_sites_in(lists))
    seen = LY.descend_no_immediates(d, LO, HI, sorted(seed), block)
    for a, t, k in idiom:                       # the `jp` and the stubs it skips
        seen |= set(range(a, t))
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
                       (ram_tables_ex2, "ramtab"), (L.bit_tables, "bittab"),
                       (L.ptr_tables, "ptrtab"), (rom_tables, "romtab"),
                       (fill_runs_ex, "fill"), (link_tables, "link"),
                       (lambda _d, _lo, _hi: dls, "dl")):
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
    _built.append((segs, conflicts, pend, ok, seen, lists, idiom, ptrvals))
    return _built[0]


def seg_boundaries():
    """Instruction START addresses of every `code` segment (see
    notes/prom_b_f6d002_layout.py: LY.provenance() decodes every code BYTE and
    spawns a unidasm per miss, which does not finish on a span this size)."""
    out = []
    for kind, a, n in build()[0]:
        if kind != "code":
            continue
        p = a
        while p < a + n:
            dec = MT.decode_at(p)
            if dec is None:
                break
            out.append((p, dec[1]))
            p += dec[0]
    return out


def provenance():
    """WHY is each code segment's first byte code?  Graded, strongest first.

      PROVEN  an instruction ALREADY IN THE .s calls or jumps to it
      THUNK   a slot of the 0xF40000 routine directory names it (jp OR ptr)
      CALL    an opcode-anchored `call`/`jp addr24` that survives far_calls_ex
      DLSITE  a display-list call sequence starts there, and its list frames
      IDIOM   `jp` over a `ret`-stub table whose end the `jp` target confirms
      BRANCH  a branch decoded inside this span targets it
      FALL    the previous code segment runs into it (no data between)
      TABLE   only an entry of a table the firmware TRANSFERS to points at it
      ACCEPT  nothing points at it; it decodes cleanly and ends in a flow end
      NONE    none of the above -- must be empty"""
    d = L.rom()
    segs, _c, _p, ok, _seen, lists, idiom, ptrvals = build()
    proven = LY.proven_call_sites(LO, HI)
    thunk = thunk_targets(LO, HI)
    far = far_calls_ex(d, LO, HI, ptrvals)
    tab = LY.table_entry_seeds(d, LO, HI)
    site = dl_sites_in(lists)
    idi = set(a for a, _t, _k in idiom)
    branch = set()
    for a, txt in seg_boundaries():
        for t in TC.branch_targets(txt):
            branch.add(t)
    accepted = set(s for s, _ in ok)
    grades, rows = {}, []
    prev_end, prev_kind = None, None
    for kind, s, n in segs:
        if kind != "code":
            prev_kind, prev_end = kind, s + n
            continue
        g = ("PROVEN" if s in proven else
             "THUNK" if s in thunk else "CALL" if s in far else
             "DLSITE" if s in site else "IDIOM" if s in idi else
             "BRANCH" if s in branch else
             "FALL" if prev_kind == "code" and prev_end == s else
             "TABLE" if s in tab else
             "ACCEPT" if s in accepted else "NONE")
        grades[g] = grades.get(g, 0) + 1
        rows.append((g, s, n))
        prev_kind, prev_end = kind, s + n
    order = ["PROVEN", "THUNK", "CALL", "DLSITE", "IDIOM", "BRANCH", "FALL",
             "TABLE", "ACCEPT", "NONE"]
    print("code segments by the STRONGEST reason their entry point is code:")
    for g in order:
        if g in grades:
            b = sum(n for gg, _, n in rows if gg == g)
            print("  %-7s %3d segments  %6d bytes" % (g, grades[g], b))
    print("\nevery code segment, with its grade:")
    for g, s, n in rows:
        print("  %-7s 0x%06X  %5d bytes" % (g, s, n))
    return sum(1 for g, _, _ in rows if g == "NONE")


# ================================================================== nulls
def null_romtab():
    """Does ROMTAB fire inside PROVEN INSTRUCTION TEXT, and why 7 entries?"""
    d = L.rom()
    runs = L.proven_code_runs()
    tot = sum(e - s for s, e in runs)
    print("NULL corpus: %d runs, %d bytes of proven prom_b instruction text."
          % (len(runs), tot))
    bad = 0
    for m in (3, 4, ROMTAB_MIN):
        hits = []
        for s, e in runs:
            hits += rom_tables(d, s, e, m)
        if m == ROMTAB_MIN:
            bad = len(hits)
        print("  romtab window 0x%08X-0x%08X, >= %d entries: false positives %d"
              % (ROM_LO, ROM_HI - 1, m, len(hits)))
    print("  and WHY the threshold is %d -- objects framed in THIS span, and how"
          % ROMTAB_MIN)
    print("  many of them fall inside the variable-length record array")
    print("  0xF511E9-0xF51E1F, whose record tails read as the word 0x00FF0001:")
    for m in (3, 5, 6, 7, 8):
        objs = rom_tables(d, LO, HI, m)
        inrec = [x for x in objs if 0xF511E9 <= x[0] < 0xF51E20]
        print("    >= %d entries: %3d objects, %3d inside the record array"
              % (m, len(objs), len(inrec)))
    print("  the objects the chosen threshold frames:")
    for a, e in rom_tables(d, LO, HI):
        print("    0x%06X-0x%06X  %4d entries" % (a, e - 1, (e - a) // 4))
    return bad


def null_link():
    """Does the LINK rule fire inside proven code, or anywhere else at all?"""
    d = L.rom()
    runs = L.proven_code_runs()
    print("NULL corpus: %d runs, %d bytes of proven prom_b instruction text."
          % (len(runs), sum(e - s for s, e in runs)))
    bad = 0
    for m in (8, 16, 32, 64):
        hits = []
        for s, e in runs:
            hits += link_tables(d, s, e, m)
        if m == LINK_MIN:
            bad = len(hits)
        print("  link >= %2d records: false positives %d" % (m, len(hits)))
    img = link_tables(d, 0xF00000, 0xF80000)
    print("  and in the WHOLE 512 KiB of prom_b the rule fires %d time(s):" % len(img))
    for a, e in img:
        _e, n, np = _link_walk(d, a, 0xF80000)
        print("    0x%06X-0x%06X  %d records, %d non-null pointers, %d bytes"
              % (a, e - 1, n, np, e - a))
    return bad


def null_fill():
    """How often does truncating a fill run at a thunk target change anything?"""
    d = L.rom()
    tg = thunk_targets()
    runs = L.fill_runs(d, 0xF00000, 0xF80000)
    hits = [(s, e, t) for s, e in runs for t in sorted(tg) if s <= t < e]
    print("NULL corpus: all %d fill runs of prom_b (%d bytes) against all %d"
          % (len(runs), sum(e - s for s, e in runs), len(tg)))
    print("thunk-table targets in prom_b.")
    print("  fill runs a thunk target falls inside: %d" % len(hits))
    for s, e, t in hits:
        print("    0x%06X-0x%06X (%d B) contains 0x%06X -- byte %d of %d, %d "
              "after it" % (s, e - 1, e - s, t, t - s, e - s, e - 1 - t))
    print("  ⚠ the same test against L.far_calls() instead would hit 3 runs;")
    print("  those are 0x0E bytes read as an address, which is why the rule is")
    print("  keyed on the thunk table and not on the byte scan:")
    fc = L.far_calls(d, 0xF00000, 0xF80000)
    for s, e in runs:
        for t in sorted(fc):
            if s <= t < e:
                print("    0x%06X-0x%06X <- far_calls 0x%06X" % (s, e - 1, t))
    return 0 if hits else 1          # a rule that never fires is not calibrated


def null_idiom():
    """How often does the `jp`-over-stub-table idiom occur, and what does it fix?"""
    d = L.rom()
    print("NULL corpus: the whole 512 KiB of prom_b.")
    for m in (2, 3, 4, 5):
        r = stub_idiom(d, 0xF00000, 0xF80000, m)
        print("  idiom with >= %d stub slots: %d occurrence(s)  %s"
              % (m, len(r), " ".join("0x%06X->0x%06X(%d)" % x for x in r)))
    print("  what it overrules here -- L.ram_tables_ex over 0xF4F2A0-0xF4F2E0:")
    for a, e in L.ram_tables_ex(d, 0xF4F2A0, 0xF4F2E0):
        print("    ramtab 0x%06X-0x%06X, entries %s"
              % (a, e - 1, ["0x%08X" % L.w32(d, x) for x in range(a, e, 4)]))
    print("  after ram_tables_ex2: %s"
          % [("0x%06X-0x%06X" % (a, e - 1)) for a, e in
             ram_tables_ex2(d, 0xF4F2A0, 0xF4F2E0)])
    print("  ⚠ the SAME defect stands in gen_prom_b_f0ea9f_module.py's frozen")
    print("  LAYOUT as (\"ramtab\", 0xF0EFFF, 6).  0xF0EFF8-0xF0F01B reads:")
    print("    %s" % d[0xF0EFF8 - B_BASE:0xF0F01C - B_BASE].hex(" "))
    print("  -- six `0E 00 00 00` stubs at 0xF0F000, framed one byte early as six")
    print("  RAM addresses of 0x0E00.  This lane is read-only and reports it.")
    return 0


def null_seed():
    """What does far_calls_ex() remove, image-wide and here?"""
    d = L.rom()
    _s, _c, _p, _o, _n, lists, _i, ptrvals = build()
    allfc = L.far_calls(d, 0xF00000, 0xF80000)
    kept = far_calls_ex(d, 0xF00000, 0xF80000, ptrvals)
    print("NULL corpus: every far_calls target in prom_b.")
    print("  targets: %d   removed as a display-list pointer: %d (%.1f%%)"
          % (len(allfc), len(allfc) - len(kept),
             100.0 * (len(allfc) - len(kept)) / len(allfc)))
    ins = sorted(L.far_calls(d, LO, HI))
    rem = [t for t in ins if t in ptrvals]
    print("  in THIS span: %d targets, %d removed -- %s"
          % (len(ins), len(rem), " ".join("0x%06X" % t for t in rem)))
    for t in rem:
        for s, (e, _i2, _sh, _si, _n) in sorted(lists.items()):
            for p in range(s, e - 3):
                if L.w32(d, p) == t:
                    print("    0x%06X is named at offset +%d of the display-list "
                          "record run 0x%06X-0x%06X" % (t, p - s, s, e - 1))
                    break
            else:
                continue
            break
    return 0 if rem else 1


def null_interstitial():
    """Does the framing walk consume PROVEN INSTRUCTION TEXT?

    Every window [i, run end) of >= 8 bytes of every proven-code run is offered
    to the loose walk and to the strict one.  An acceptance is a false positive:
    the bytes are instructions the byte gate proves."""
    runs = L.proven_code_runs()
    tot = hl = hs = 0
    bycount = {}
    for a, b in runs:
        for i in range(a, b):
            if b - i < 8:
                break
            tot += 1
            if loose_walk(i, b) is not None:
                hl += 1
            r = strict_walk(i, b, "A")
            if r is not None:
                hs += 1
                bycount[r] = bycount.get(r, 0) + 1
    print("NULL corpus: %d proven-code runs, %d bytes; %d windows tested."
          % (len(runs), sum(e - s for s, e in runs), tot))
    print("  loose walk  (op < 0x24, len >= 2)        lands exactly: %4d (%.3f%%)"
          % (hl, 100.0 * hl / tot))
    print("  STRICT walk (+ the implied-length rule)  lands exactly: %4d (%.3f%%)"
          % (hs, 100.0 * hs / tot))
    print("  strict acceptances by record count: %s" % sorted(bycount.items()))
    bad = sum(v for k, v in bycount.items() if k >= INTER_MIN)
    print("  at INTER_MIN = %d records the false-positive count is %d."
          % (INTER_MIN, bad))
    print("  ⚠ the 1-record acceptances are why INTER_MIN is 2 and why the")
    print("  three 1-record gaps of this span stay `data` -- see --holes.")
    return bad


def null_dl():
    """Does a call-site-framed display list ever overlap proven instruction text?"""
    runs = L.proven_code_runs()
    lists = call_site_lists(0, 0x1000000)
    bad = []
    for s, (e, _i, sh, si, _n) in sorted(lists.items()):
        for a, b in runs:
            if s < b and a < e:
                bad.append((s, e, sh, si))
                break
    print("NULL corpus: %d runs, %d bytes of proven prom_b instruction text."
          % (len(runs), sum(e - s for s, e in runs)))
    print("  framed display lists (all shapes): %d   overlapping proven code: %d"
          % (len(lists), len(bad)))
    for s, e, sh, si in bad[:8]:
        print("    0x%06X-0x%06X shape %d site 0x%06X" % (s, e - 1, sh, si))
    return len(bad)


def null():
    """Every null this layout rests on, in one process."""
    bad = 0
    print("=== 1. content rules (round 5's set), on PROVEN CODE ===")
    bad += LY.null_ptr()
    print("\n=== 2. ROMTAB, on PROVEN CODE ===")
    bad += null_romtab()
    print("\n=== 3. LINK, on PROVEN CODE and on the whole image ===")
    bad += null_link()
    print("\n=== 4. the display lists, on PROVEN CODE ===")
    bad += null_dl()
    print("\n=== 5. the INTERSTITIAL rule, on PROVEN CODE ===")
    bad += null_interstitial()
    print("\n=== 6. the FILL truncation, on the whole image ===")
    bad += null_fill()
    print("\n=== 7. the `jp`-over-stub idiom, on the whole image ===")
    bad += null_idiom()
    print("\n=== 8. the seed filter, on the whole image ===")
    bad += null_seed()
    print("\n=== 9. STRIDED (demotes a table), on PROVEN DISPATCH TABLES ===")
    bad += LY.null_stride()
    print("\n=== 10. accept() (promotes a run TO code), on PROVEN DATA ===")
    n = LY.null_accept()
    bad += 1 if n > 1 else 0
    print("\nTOTAL findings a null must not have: %d" % bad)
    return bad


# ============================================ what ALREADY-PROVEN code names
_OPRE = re.compile(r";\s*([0-9A-F]{6})\s")


def proven_operands(lo=None, hi=None):
    """{address in [lo,hi): [(image, site, source text)]} for every address an
    instruction ALREADY IN prom_a/wsa1_prom_a.s or prom_b/wsa1_prom_b.s names.

    THE STRONGEST EVIDENCE THIS SPAN HAS, and no earlier tool in this lane
    collects it.  The byte gate proves both .s files rebuild their ROMs, so an
    address written in one of their instruction lines is an address the firmware
    really forms.

    ⚠ IT SCANS THE WHOLE LINE, and that is not cosmetic.  The two files carry
    DIFFERENT comment conventions: prom_b puts the MAME text in the `; ADDR ...`
    comment, prom_a puts the raw bytes there and keeps the mnemonic in the source
    column.  notes/prom_b_f0ea9f_layout.py's proven_call_sites() matches on the
    comment, so it finds ZERO prom_a sites; and its indexers() decodes through
    prom_b_module_trace.decode_at(), which indexes the PROM_B image, so it
    returns None for every prom_a address.  Both limits are silent.  For this
    span they matter: all 134 proven references into it are in PROM_A."""
    lo = LO if lo is None else lo
    hi = HI if hi is None else hi
    out = {}
    for img in ("a", "b"):
        path = image_path(ROOT, "prom_%s/wsa1_prom_%s.s" % (img, img))
        for ln in open(path):
            m = _OPRE.search(ln)
            if not m:
                continue
            site = int(m.group(1), 16)
            if lo <= site < hi:
                continue
            for v in set(re.findall(r"0x0*([0-9a-fA-F]{5,6})\b", ln)):
                a = int(v, 16)
                if lo <= a < hi:
                    out.setdefault(a, []).append(
                        (img, site, ln.split(";")[0].strip()))
    return out


def refs():
    """Every address in the span that already-proven code names, with its site."""
    P = proven_operands()
    segs = build()[0]
    kindof = {}
    for k, s, n in segs:
        for x in range(s, s + n):
            kindof[x] = k
    tot = sum(len(v) for v in P.values())
    print("addresses in 0x%06X-0x%06X named by an instruction already in the .s:"
          % (LO, HI))
    print("  %d distinct addresses, %d reference lines" % (len(P), tot))
    for a in sorted(P):
        img, site, txt = P[a][0]
        print("  0x%06X  %-7s x%-2d  prom_%s 0x%06X  %s"
              % (a, kindof.get(a, "?"), len(P[a]), img, site, txt))
    return 0


# =============================================================== the holes
HOLES = {
    0xF4F273: "11-byte index table `00 01 08 09 10 20 28 29 18 19 1a`; IDENT "
              "needs 12.  Two proven instructions name it: `ld XIX,0x00f4f273` "
              "at prom_b 0xF4F10E and 0xF4F146.",
    0xF4F2B2: "two 8-byte tables, `00..07` ascending and `00 ff fe .. f9` "
              "descending; IDENT needs 12 and neither reaches it.  A linear "
              "decode of these 16 bytes does NOT end in a flow end, which is "
              "what keeps accept() off them.",
    0xF4F910: "6 bytes `88 00 18 00 00 00` between two prom_a pointer tables; "
              "prom_a 0xFB31D4 does `lda_24 xiy,(0xf4f910)`, so it is an object, "
              "not slack.",
    0xF4FA7A: "33 bytes, all zero, but NOT slack: prom_a takes the address of "
              "nine points inside it (0xF4FA7C, 0xF4FA81, 0xF4FA84, 0xF4FA87, "
              "0xF4FA8A, 0xF4FA8D, 0xF4FA90, 0xF4FA95 and the run's own start) "
              "with `lda_24 xiy`.  A block of zeroed defaults at 3- and 5-byte "
              "spacing; the record size is NOT established.",
    0xF4FE38: "297 bytes of 5- and 7-byte records starting 0xF0 (`f0 50 23 7e "
              "f7`), apparent terminator 0xF7.  THIRTY-ONE distinct addresses "
              "inside it are named by proven prom_a instructions -- 0xF4FE38, "
              "0xF4FE50, 0xF4FE68, 0xF4FE6A, 0xF4FE76, 0xF4FE82, 0xF4FEA4, and "
              "0xF4FEB4 upwards at 5-, 6- and 12-byte spacing.  The record "
              "framing is NOT established, so it stays data.",
    0xF511B5: "18 bytes `00 01 01 02 03 03 04 05 05 05 06 07 07 07 08 09 09 0a` "
              "-- NON-decreasing, so BYTEMAP (which requires strictly greater) "
              "cannot see it.  prom_a 0xFB7C76 and 0xFB7CA4 both do "
              "`add XWA,0x00f511b5`, so the base is right and only the rule is "
              "missing.",
    0xF511DD: "3,139 bytes: an array of VARIABLE-LENGTH records whose heads are "
              "0x00FB4D61/0x00FB4D62 (a prom_a callback) followed by two or three "
              "more prom_a pointers and then parameter bytes.  109 heads, "
              "0xF51209 to 0xF51E08, head-to-head strides 28 (x98), 32 (x7), "
              "30 (x2) and 43 (x1) -- so NO constant stride, and the record "
              "boundary is not pinned by anything this lane could measure.  "
              "prom_a 0xFB801A does `lda_24 xiy,(0xf511e9)`, which is where the "
              "segment starts, and 0xF511F9 is named seven times.",
    0xF51E2C: "64 bytes of 6-byte records `[u16][u16][u16]` whose first field "
              "looks like a RAM address (0x7F38, 0x7FD6); prom_a names 0xF51E58 "
              "six times, 0xF51E34 three times, 0xF51E30 and 0xF51E46 once each.",
    0xF51E88: "2 bytes `02 00`, named by prom_a 0xFB4288 (`add XBC,0x00f51e88`) "
              "-- a count word in front of the 225-entry table at 0xF51E8A.",
    0xF536BC: "9 bytes that decode EXACTLY as `call 0xf42e10 / ld (0x2540),0x00` "
              "and run into proven code at 0xF536C5, but end in a load, so "
              "accept()'s flow-end rule refuses them.  Almost certainly code; "
              "nothing points at them.",
    0xF53722: "27 bytes that decode EXACTLY as a routine prologue (`push HL / "
              "push XIX / lda XIX,0x2540 / set 0,(0xc6) / ld C,(0x289e) / cp C,"
              "(0x289f) / jrl Z,0xf537cd / ld (0x289f),C / ld (XIX),0x00`), whose "
              "`jrl` target IS an instruction boundary of the proven code below, "
              "and which runs into proven code at 0xF5373D.  Same refusal.  "
              "Almost certainly code.",
    0xF53884: "21 bytes that decode EXACTLY as five RAM moves "
              "(`ld (0x2540),0x00 / ld C,(0x2890) / ld (0x2640),C / "
              "ld C,(0x2891) / ld (0x2641),C`) and run into proven code at "
              "0xF53899.  Same refusal.  Almost certainly code.",
    0xF542A4: "9 words of 0x00000000 followed by 8 descending bytes `6e 62 54 46 "
              "38 2a 1c 0e`.  If the 9 zeros are empty slots of the dispatch "
              "table at 0xF54248 that table has 32 entries and ends at 0xF542C8; "
              "the chain rule stops at 23 because a zero is not an address, and "
              "nothing in the code bounds the index -- see the open question.",
    0xF542E1: "a display list of ONE record (op 0x03, len 12, handler 0xF31ABE), "
              "identical in shape to the call-site-proven records at 0xF542ED and "
              "0xF54305 that it tiles with at stride 12.  INTER_MIN is 2 records "
              "because the 1-record case is the one with a non-zero measured "
              "false-positive rate, so it stays data.",
    0xF542F9: "the same: ONE 12-byte op-0x03 record between two proven ones.",
    0xF546DA: "two objects the layout does not split: 0xF546DA-0xF546F9 is four "
              "8-byte records `29 00 xx 00 10 01 yy 00`, named by the proven "
              "interpreter-B record at 0xF546C4 (the word 0x00F546DA sits at its "
              "offset +18); 0xF546FA-0xF54704 is a display list of ONE "
              "interpreter-B record (op 0x08, len 11) landing exactly on the "
              "proven B list at 0xF54705, which INTER_MIN = 2 refuses.",
    0xF54710: "2,223 bytes of BITMAP data.  Three op-0x03 display-list records "
              "name 0x00F54718, 0x00F54790 and 0x00F54D7E, and that handler "
              "(0xF31ABE) does `ld IX,(XIY+6) / ld BC,(XIY+8) / ld HL,(XIY+10) / "
              "ld XIY,(XIY+2) / swi 7`, so the word at record+2 is a graphic "
              "source and the other three are its placement.  Two of the three "
              "start `0f 18`; cell extents are NOT established.",
}


def holes():
    """Every byte the layout leaves as `data`, with what is known about it."""
    segs = build()[0]
    tot = 0
    print("bytes this layout does NOT claim, in address order:")
    for k, s, n in segs:
        if k != "data":
            continue
        tot += n
        print("  0x%06X-0x%06X  %5d  %s"
              % (s, s + n - 1, n, HOLES.get(s, "⚠ UNDESCRIBED")))
    print("  ---- %d bytes of %d (%.1f%%)" % (tot, HI - LO, 100.0 * tot / (HI - LO)))
    miss = [s for k, s, _n in segs if k == "data" and s not in HOLES]
    print("  data segments with no description: %d %s"
          % (len(miss), ["0x%06X" % s for s in miss]))
    return len(miss)


# ============================================================== selftest
def selftest():
    print("prom_b_f4f000_layout.py --selftest")
    d = L.rom()
    segs, conflicts, _pend, _ok, _seen, lists, idiom, ptrvals = build()
    src = open(image_path(ROOT, "prom_b/wsa1_prom_b.s")).read()

    check("the span is one `.incbin` in prom_b/wsa1_prom_b.s",
          '.incbin "original_ROMs/wsa1_prom_b.ic13", 0x04F000, 0x006000' in src,
          True)

    # the segments TILE the span: no gap, no overlap, first and last exact
    p, holes_ = LO, 0
    for _k, s, n in segs:
        if s != p:
            holes_ += 1
        p = s + n
    check("segments tile the span with no gap or overlap", (holes_, p), (0, HI))
    check("first segment starts at LO", "0x%06X" % segs[0][1], "0x%06X" % LO)
    check("sum of segment lengths", sum(n for _k, _s, n in segs), HI - LO)

    # THE LAST SEGMENT, re-read from the ROM
    lk, ls, ln = segs[-1]
    check("LAST segment kind", lk, "fill")
    check("LAST segment start", "0x%06X" % ls, "0x%06X" % 0xF54FBF)
    check("LAST segment length", ln, 65)
    check("LAST segment ends on the span's last byte", "0x%06X" % (ls + ln - 1),
          "0x%06X" % (HI - 1))
    check("LAST segment is pure 0x0E",
          set(d[ls - B_BASE:ls + ln - B_BASE]), {0x0E})
    check("the byte BEFORE the last fill segment (so the run is maximal)",
          "0x%02X" % d[ls - 1 - B_BASE], "0x00")
    lastdata = [x for x in segs if x[0] == "data"][-1]
    check("LAST data segment", "0x%06X %d" % (lastdata[1], lastdata[2]),
          "0xF54710 2223")

    check("barrier conflicts (descent bytes a content rule reclaimed)",
          len(conflicts), 0)
    check("code segments graded NONE by --provenance", provenance(), 0)

    # every thunk target of the span is code, FIRST AND LAST
    th = sorted(thunk_targets(LO, HI))
    kindof = {}
    for k, s, n in segs:
        for x in range(s, s + n):
            kindof[x] = k
    sl = thunk_slots(LO, HI)
    check("thunk-table SLOTS naming the span (jp + ptr)", len(sl), 12)
    check("  ... of which are `ptr` slots, invisible to module_trace",
          [("0x%06X" % a) for a, k, _v in sl if k == "ptr"], ["0xF42E40"])
    check("  ... and module_trace's jp-only census sees",
          len(MT.thunk_entries(LO, HI)), 11)
    check("DISTINCT targets (T_F42E58 and T_F42E5C share 0xF5301A)", len(th), 11)
    check("FIRST thunk target 0x%06X is code" % th[0], kindof[th[0]], "code")
    check("LAST  thunk target 0x%06X is code" % th[-1], kindof[th[-1]], "code")
    check("every thunk target is code",
          sorted(set(kindof[t] for t in th)), ["code"])
    bnds = set(a for a, _ in seg_boundaries())
    check("every thunk target is an instruction BOUNDARY",
          sorted(set(t in bnds for t in th)), [True])
    check("the FIRST thunk target decodes as", MT.decode_at(th[0])[1], "ret")

    # the fill run above it stops one byte short
    f = [x for x in segs if x[0] == "fill"]
    check("fill segments", len(f), 3)
    check("the fill run before 0xF53000 ends at",
          "0x%06X" % (f[1][1] + f[1][2] - 1), "0x%06X" % (th[0] - 1))
    check("  ... and L.fill_runs (untruncated) would end at",
          "0x%06X" % (max(e for s, e in L.fill_runs(d, LO, HI) if s < th[0]) - 1),
          "0x%06X" % th[0])

    # the display lists, first and LAST
    dls = dl_ranges(lists)
    check("merged display-list ranges in the span", len(dls), 4)
    check("FIRST display-list range",
          "0x%06X-0x%06X" % (dls[0][0], dls[0][1] - 1), "0xF542ED-0xF542F8")
    check("LAST  display-list range",
          "0x%06X-0x%06X" % (dls[-1][0], dls[-1][1] - 1), "0xF54705-0xF5470F")
    check("every display-list byte is kind `dl`",
          sorted(set(kindof[x] for s, e in dls for x in range(s, e))), ["dl"])
    check("call sites in the span whose list frames", len(framed_sites()), 13)
    check("  ... naming this many DISTINCT lists (0xF543C4 is named twice)",
          len(set(x[2] for x in framed_sites())), 12)
    check("accepted lists (distinct starts + interstitials)", len(lists), 13)
    inter = [s for s, v in lists.items() if v[2] == 0]
    check("of which INTERSTITIAL", sorted("0x%06X" % s for s in inter),
          ["0xF54416"])
    check("the interstitial's record count", lists[0xF54416][4], 17)
    check("  ... it lands exactly on the proven list at",
          "0x%06X" % lists[0xF54416][0], "0xF544AD")
    lastl = max(lists)
    check("LAST accepted list 0x%06X frames" % lastl,
          loose_walk(lastl, lists[lastl][0]) or lists[lastl][4], lists[lastl][4])

    ds = sorted(dl_sites_in(lists))
    check("display-list call sites INSIDE the span", len(ds), 13)
    check("FIRST call site", "0x%06X" % ds[0], "0xF536C5")
    check("LAST  call site", "0x%06X" % ds[-1], "0xF53899")
    check("FIRST call site is code", kindof[ds[0]], "code")
    check("LAST  call site is code", kindof[ds[-1]], "code")
    check("LAST call site decodes as an `lda`", MT.decode_at(ds[-1])[1].split()[0],
          "lda")

    # the link table, first and LAST record
    lt = link_tables(d, LO, HI)
    check("link tables in the span", len(lt), 1)
    check("link table extent", "0x%06X-0x%06X" % (lt[0][0], lt[0][1] - 1),
          "0xF4FF61-0xF511B4")
    e, n, np = _link_walk(d, lt[0][0], HI)
    check("link records / non-null pointers", (n, np), (782, 779))
    check("FIRST link record's pointer", "0x%06X" % L.w32(d, lt[0][0] + 2),
          "0xF4FF61")
    check("LAST  link record's pointer", "0x%06X" % L.w32(d, lt[0][1] - 4),
          "0xF4FF61")
    check("every non-null pointer is 6-aligned on the table start",
          sorted(set((L.w32(d, x + 2) - lt[0][0]) % 6
                     for x in range(lt[0][0], lt[0][1], 6)
                     if L.w32(d, x + 2))), [0])

    # the romtab objects, first and LAST
    rt = rom_tables(d, LO, HI)
    check("romtab objects in the span", len(rt), 6)
    check("FIRST romtab", "0x%06X %d entries" % (rt[0][0], (rt[0][1] - rt[0][0]) // 4),
          "0xF4F800 68 entries")
    check("LAST  romtab", "0x%06X %d entries" % (rt[-1][0], (rt[-1][1] - rt[-1][0]) // 4),
          "0xF54248 23 entries")
    check("LAST romtab's LAST entry is a ROM address",
          "0x%06X" % L.w32(d, rt[-1][1] - 4), "0xF42C70")
    check("none of them lies inside the record array",
          [x for x in rt if 0xF511E9 <= x[0] < 0xF51E20], [])

    # the idiom
    check("`jp`-over-stub idiom occurrences in the span", len(idiom), 1)
    check("  ... its jp, target and slot count",
          "0x%06X->0x%06X x%d" % idiom[0], "0xF4F2C2->0xF4F2DA x5")
    check("  ... the jp really decodes there", MT.decode_at(0xF4F2C2)[1],
          "jp 0xf4f2da")
    check("  ... and its target is the first byte of a code segment",
          kindof[0xF4F2DA], "code")
    check("  ... L.ram_tables_ex would frame 0xF4F2C5; ram_tables_ex2 does not",
          [("0x%06X" % a) for a, _e in ram_tables_ex2(d, 0xF4F2A0, 0xF4F2E0)], [])

    # the seed filter
    check("far_calls targets the DL-pointer filter removes here",
          sorted("0x%06X" % t for t in L.far_calls(d, LO, HI) if t in ptrvals),
          ["0xF546DA", "0xF54710"])

    # fills are pure
    bad = [hex(s) for k, s, n in segs if k == "fill"
           and set(d[s - B_BASE:s + n - B_BASE]) != {0x0E}]
    check("every `fill` segment is pure 0x0E", bad, [])

    # every data segment is described
    check("data segments with no --holes description", holes(), 0)

    # the nulls
    check("content rules on proven code: false positives", LY.null_ptr(), 0)
    check("ROMTAB on proven code: false positives", null_romtab(), 0)
    check("LINK on proven code: false positives", null_link(), 0)
    check("display lists overlapping proven code", null_dl(), 0)
    check("INTERSTITIAL on proven code at >= %d records" % INTER_MIN,
          null_interstitial(), 0)

    print("FAILURES: %d" % len(FAIL))
    return 1 if FAIL else 0


# =================================================================== main
def main():
    if "--selftest" in sys.argv:
        return selftest()
    if "--null" in sys.argv:
        return 1 if null() else 0
    for flag, fn in (("--null-romtab", null_romtab), ("--null-link", null_link),
                     ("--null-fill", null_fill), ("--null-idiom", null_idiom),
                     ("--null-seed", null_seed), ("--null-dl", null_dl),
                     ("--null-interstitial", null_interstitial),
                     ("--null-ptr", LY.null_ptr), ("--null-stride", LY.null_stride),
                     ("--null-accept", LY.null_accept)):
        if flag in sys.argv:
            return 1 if fn() else 0
    segs, conflicts, pend, ok, _seen, lists, idiom, _pv = build()
    d = L.rom()
    if "--provenance" in sys.argv:
        return 1 if provenance() else 0
    if "--holes" in sys.argv:
        return 1 if holes() else 0
    if "--dl" in sys.argv:
        print("display lists inside 0x%06X-0x%06X:" % (LO, HI))
        for s in sorted(lists):
            e, i, sh, si, n = lists[s]
            print("  0x%06X-0x%06X %5d B  %3d records  interp %s  %s"
                  % (s, e - 1, e - s, n, i,
                     "shape %d, site 0x%06X" % (sh, si) if sh else
                     "INTERSTITIAL (lands on 0x%06X)" % e))
        print("merged into %d barrier ranges:" % len(dl_ranges(lists)))
        for s, e in dl_ranges(lists):
            print("  0x%06X-0x%06X %5d" % (s, e - 1, e - s))
        return 0
    if "--conflicts" in sys.argv:
        print("descent bytes reclaimed by a barrier rule: %d  (MUST be 0)"
              % len(conflicts))
        for a in conflicts[:80]:
            print("  0x%06X" % a)
        return 1 if conflicts else 0
    if "--residue" in sys.argv:
        print("runs that are neither code, table, string, list nor padding: "
              "%d (%d bytes)" % (len(pend), sum(e - s for s, e in pend)))
        for s, e in pend:
            raw = d[s - B_BASE:e - B_BASE]
            for i in range(0, len(raw), 16):
                print("   %06X  %-47s |%s|"
                      % (s + i, raw[i:i + 16].hex(" "),
                         "".join(chr(c) if 32 <= c < 127 else "."
                                 for c in raw[i:i + 16])))
            print()
        return 0
    if "--python" in sys.argv or "--all" in sys.argv:
        print("LAYOUT = [")
        for k, s, n in segs:
            print('    ("%s", 0x%06X, 0x%04X),' % (k, s, n))
        print("]")
        if "--all" not in sys.argv:
            return 0
        tot = {}
        for k, s, n in segs:
            tot[k] = tot.get(k, 0) + n
        print("# ---- " + "  ".join("%s %d" % (k, v) for k, v in sorted(tot.items())))
        print("# segments %d  accepted %d  conflicts %d  pending %d"
              % (len(segs), len(ok), len(conflicts), len(pend)))
        print("# PROVENANCE")
        provenance()
        print("# HOLES")
        holes()
        return 0
    tot = {}
    for k, s, n in segs:
        print("  %-7s 0x%06X-0x%06X  %6d" % (k, s, s + n - 1, n))
        tot[k] = tot.get(k, 0) + n
    print("  ---- " + "  ".join("%s %d" % (k, v) for k, v in sorted(tot.items())))
    print("  substantive %d of %d"
          % (sum(v for k, v in tot.items() if k != "fill"), HI - LO))
    print("  segments %d   accepted runs %d   barrier conflicts %d   pending %d"
          % (len(segs), len(ok), len(conflicts), len(pend)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
