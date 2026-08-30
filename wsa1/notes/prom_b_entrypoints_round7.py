#!/usr/bin/env python3
"""prom_b's 0xF7D000 stub block: the 103 directory entry points that carry NO
LABEL AT ALL, what each one IS, and what it can be called.

QUESTION IT ANSWERS
    Round 6's census (notes/prom_b_thunks_round6.py --unnamed) ended with a list
    nobody had acted on: 115 slots of prom_b's routine directory point at an
    address the .s ALREADY DISASSEMBLES and that carries no label of any kind.
    An entry point the machine's own directory says exists, and that a reader
    cannot even refer to.  This script asks, for each of them:
      (a) WHAT is it -- what shape does the stub have, and what does it reach?
      (b) WHOSE is it -- which object does the directory say it belongs to?
      (c) can it therefore be NAMED, and from what evidence?

★★ THE ANSWER: THEY ARE THE METHODS OF 25 PANEL-SCREEN OBJECTS
    prom_a already documented the consumer side (`PanelScreen_VtableTable` at
    prom_a 0xF86EC1: 256 LE32 pointers, one screen object each, methods at
    +0 Enter, +4 Leave, +8 Button).  What nobody had done is look at where 25 of
    those pointers LAND: inside prom_b's routine directory, at 0xF43040-0xF431AF,
    in FOUR-WORD runs.  Every one of the 103 unlabelled stub-block entry points
    is a member of one of those runs, or one of the 8 `jrl` veneers at 0xF7D000.

    Run the script for the table.  The shape, per screen object S:

        directory        stub in 0xF7D000 block          role
        S+0x00           calls the painter               Enter
        S+0x04           calls a small routine           Leave
        S+0x08           ld XIX,<a 32-entry table>       Button
                         [cp (0x207E),0x00 / jr Z /
                          ld XIX,<a second table>]
                         call T_F41B08
        S+0x0C           a bare `ret`, or `calr <a       ⚠ NO READER FOUND
                         bare ret>` then `ret`

★ AND THE 32 TABLES ARE BUTTON TABLES.  FINDINGS-prom_b-dispatch-layers.md ends
    "⚠ NOT ESTABLISHED: what the 32 tables enumerate, what the index in HL is".
    They are enumerated by PANEL BUTTON, and the index is the button number:
      * every `ld XIX,<table>` stub in this block is the +8 word of a
        PanelScreen_VtableTable entry (check R5);
      * prom_a's PanelButton_Route is the ONLY reader of +8 (`add XBC,8` at
        0xF8621E, per prom_a's own header) and it masks the button index with
        `and L,0x1f` at 0xF861AE;
      * the stub's callee, T_F41B08 -> prom_a 0xF8BDC5, masks the SAME five bits
        (`and L,0x1f / sla 2,L / ld XIX,(XIX+L) / call XIX`).
    Two independent 5-bit masks, one at the caller and one at the callee, and a
    128-byte table: 32 buttons.

★ THE FOURTH WORD DOES NOTHING, AND THAT IS MEASURED, NOT ASSUMED
    23 runs have a +0x0C word.  ALL 23 of its stubs are no-ops: 18 are a single
    `ret`, and the other 5 are `calr <address>` + `ret` where the address holds a
    single `ret` too -- 0xF7EA55, 0xF7EC70, 0xF7EE07, 0xF7E600, 0xF7E76F, all
    five inside the 0xF7E2D8 `.incbin`, read from the ROM.  ⚠ THREE of those five
    (0xF7EC70, 0xF7EE07, 0xF7E600) sit exactly one byte below ANOTHER run's Enter
    target, i.e. they are that routine's predecessor's tail `ret` borrowed as an
    empty body; the other TWO (0xF7EA55, 0xF7E76F) do not, and an earlier draft
    of this paragraph said "each", which was wrong.  Checks R6 and R6b.
    No instruction in either image reads +0x0C: prom_a's three method offsets are
    `ld BC,0x0000`, `ld BC,0x0004` and `add XBC,0x00000008`, and there is no
    `ld BC,0x000C` and no `add XBC,0x0000000C` anywhere (check R7).  So the word
    is real, uniform and unexplained, and the labels say so.

★ HOW A SCREEN GETS ITS NAME -- the same rule prom_a used, re-derived here
    The Enter method calls the display-list interpreter (0xF417F0 = A,
    0xF417F4 = B) with XIY = list start, XIX = list end.  A display list is a
    chain of `op,len` records; the leading run of op-0x1C records carries the
    screen's title in large text.  The name is that title, CamelCased.
    ⚠ THE ROM SPELLS SOME O's AS THE DIGIT ZERO ("S0NG C0PY", "AFTER T0UCH"),
    and the names keep the ROM's spelling.  That is not a typo here or there.

    THE RULE IS CALIBRATED, NOT ASSERTED.  Seven of the 25 Enter methods call a
    routine prom_a named independently, months ago, from the SAME screens'
    text: Paint_MeasureC0py, Paint_MeasureInsert, Paint_S0ngC0py,
    Paint_N0teChange, Paint_SequencerMedley, Paint_StepRecordPartSelect,
    Paint_S0ngSelectName.  Check R8 runs this script's rule on those seven and
    requires the title it derives to match prom_a's existing name.  If a later
    edit breaks the rule, that check fails.

⚠ WHAT THIS PASS REFUSED
    R1  Naming a screen after its VTABLE INDEX.  The index is a bare number and
        `ScreenEnter_43` grades content while stating nothing -- the same defect
        round 6 refused as Write3602_Index5.  Screens whose title cannot be read
        keep `sub_XXXXXX` or a framed `Veneer_<destination>`.
    R2  Naming the six unnamed `jrl` veneers after their destination's function.
        Their destinations (prom_a 0xF81ACB, 0xF81C15, 0xF81C33, 0xF81C90,
        0xF81D41, 0xF81E7E) are unlabelled in prom_a and prom_a is another
        lane's file.  They get `Veneer_<destination address>`, which is framed on
        purpose: the mechanism is known and the destination is not.
    R3  Two of the "115" are NOT code.  T_F42FE8 -> 0xF19E4F and T_F42FEC ->
        0xF19EA4 land INSIDE the display list `DL_Inter` (0xF19DDA-0xF19ED5), on
        a record boundary.  Round 6 counted them as "an address the .s
        disassembles" because its test is whether the .s prints that address in
        a trailing comment -- and a display-list record header does.  They are
        entry points into a LIST, not routines, and this pass labels them with
        the tree's internal-target spelling `DL_Inter__F19E4F`.  See --outoflane.

⚠ NINE OF THE 115 ARE OUT OF LANE.  Their targets are in prom_a, which belongs
    to another lane this round.  `--outoflane` prints them with the proposal a
    prom_a lane could apply; this script does not touch prom_a/wsa1_prom_a.s.

RUN
    python3 notes/prom_b_entrypoints_round7.py              # the census
    python3 notes/prom_b_entrypoints_round7.py --runs       # the 26 runs + titles
    python3 notes/prom_b_entrypoints_round7.py --proposals  # every label proposed
    python3 notes/prom_b_entrypoints_round7.py --outoflane  # the 12 non-stub-block
    python3 notes/prom_b_entrypoints_round7.py --blockshapes # shapes + mnemonics
    python3 notes/prom_b_entrypoints_round7.py --refused    # R1-R3, re-measured
    python3 notes/prom_b_entrypoints_round7.py --apply      # edit prom_b/wsa1_prom_b.s
    python3 notes/prom_b_entrypoints_round7.py --refresh    # unapply, then apply again
    python3 notes/prom_b_entrypoints_round7.py --selftest   # checks, incl. the LAST
`--apply` is idempotent.  Run the gate afterwards:
    python3 scripts/analysis/assert_byte_identical.py
"""
import collections
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path, write_part  # noqa: E402
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import wave7_documentation_metrics as M                            # noqa: E402

SRCA = os.path.join(ROOT, "prom_a", "wsa1_prom_a.s")
# ⚠ A WRITE THROUGH THIS NAME IS GUARDED AND WILL REFUSE while the text
# it is handed is the whole image: write_part() sees the master's
# .include lines disappear.  That refusal is correct and is not the fix.
# The fix for a RENAME is asm_source.edit_image(ROOT, <primary>, fn),
# which applies the transform to every constituent file; for a SPLICE it
# is asm_source.locate() on the block's anchor.  See notes/asm_source.py.
SRCB_MASTER = os.path.join(ROOT, "prom_b/wsa1_prom_b.s")   # the WRITE path: write_part() guards it
SRCB = image_path(ROOT, "prom_b/wsa1_prom_b.s")  # the READ path: the image, not the master
UNIDASM = os.path.expanduser("~/compartilhado/kn7000_mame_build/unidasm")

BLOCK_LO, BLOCK_HI = 0xF7D000, 0xF7D2D8        # the stub block, [lo, hi)
DIR_LO, DIR_HI = 0xF43040, 0xF431E0            # the run of directory slots
VENEER_LO, VENEER_HI = 0xF431B0, 0xF431D0      # the 8 jrl veneer slots
VT_LO, VT_HI = 0xF86EC1, 0xF872C1              # prom_a PanelScreen_VtableTable
INTERP = {0xF417F0: "A", 0xF417F4: "B"}
BOUNDS_CHECKED_CALL = 0xF41B08                 # -> prom_a 0xF8BDC5

ADDR = re.compile(r';\s*([0-9A-F]{6})\b')
LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')


def load():
    r = lambda n: open(os.path.join(ROOT, "original_ROMs", n), "rb").read()
    return r("wsa1_prom_a.ic12"), r("wsa1_prom_b.ic13")


A, B = load()


def byte(addr):
    return A[addr - 0xF80000] if addr >= 0xF80000 else B[addr - 0xF00000]


def word32(addr):
    return sum(byte(addr + i) << (8 * i) for i in range(4))


# ------------------------------------------------------------------ the runs
def vtable_targets():
    """Every PanelScreen_VtableTable entry that lands in the directory run.

    Derived from prom_a's ROM BYTES, not from its .s text, so a comment there
    cannot propagate into a name here."""
    out = {}
    for addr in range(VT_LO, VT_HI, 4):
        v = word32(addr)
        if DIR_LO <= v < DIR_HI:
            out.setdefault(v, []).append(addr)
    return out


def runs():
    """[(base, [slot addresses])] -- the four-word runs, from the vtable bases.

    A base is a value prom_a's table holds; the run is base..base+0x0C.  The two
    bases 0xF43040 and 0xF43048 are only 8 apart and their 3-method extents
    OVERLAP -- that is in the ROM, not a bug here, and check R4 asserts it."""
    bases = sorted(vtable_targets())
    out = []
    for i, b in enumerate(bases):
        nxt = bases[i + 1] if i + 1 < len(bases) else DIR_HI
        n = 4 if nxt - b >= 0x10 else (nxt - b) // 4
        out.append((b, [b + 4 * k for k in range(n)]))
    return out


def slot_target(slot):
    """The address a directory slot names: `jp nnn` (1B) or a bare LE32 pointer."""
    s = [byte(slot + i) for i in range(4)]
    if s[0] == 0x1B and 0xF0 <= s[3] <= 0xFF:
        return s[1] | s[2] << 8 | s[3] << 16
    if s[3] == 0x00 and 0xF0 <= s[2] <= 0xFF:
        return s[0] | s[1] << 8 | s[2] << 16
    return None


# ------------------------------------------------- the stub block, from the .s
def stub_lines():
    """{address: (mnemonic text, line index)} for every instruction in the block,
    read from prom_b's own already-converted assembly."""
    out, i = {}, 0
    for i, ln in enumerate(open(SRCB)):
        m = ADDR.search(ln)
        if not m:
            continue
        a = int(m.group(1), 16)
        if BLOCK_LO <= a < BLOCK_HI:
            rest = ln[m.end():].strip()
            out[a] = (rest.split("[llvm-mc")[0].strip(), i)
    return out


_STUBS = None


def stubs():
    global _STUBS
    if _STUBS is None:
        _STUBS = stub_lines()
    return _STUBS


def stub_body(entry, limit=24):
    """The instructions from `entry` to its first `ret` or `jrl`, inclusive."""
    s = stubs()
    seq, a = [], entry
    order = sorted(s)
    idx = order.index(a) if a in s else None
    if idx is None:
        return seq
    while idx < len(order) and len(seq) < limit:
        a = order[idx]
        seq.append((a, s[a][0]))
        if s[a][0] == "ret" or s[a][0].startswith("jrl"):
            break
        idx += 1
    return seq


def shape(entry):
    """('veneer'|'fwd'|'table'|'null'|'other', detail) for the stub at `entry`."""
    body = stub_body(entry)
    if not body:
        return ("absent", None)
    texts = [t for _a, t in body]
    if texts[0].startswith("jrl"):
        m = re.search(r'0x([0-9a-f]+)', texts[0])
        return ("veneer", int(m.group(1), 16))
    if texts == ["ret"]:
        return ("null", None)
    if len(texts) == 2 and texts[1] == "ret":
        m = re.search(r'0x([0-9a-f]+)', texts[0])
        if m and texts[0].split()[0] in ("call", "calr"):
            t = int(m.group(1), 16)
            # a forwarder whose destination is a single `ret` is also a no-op
            return ("null" if byte(t) == 0x0E else "fwd", t)
    if texts[0].startswith("ld XIX,"):
        tabs = [int(re.search(r'0x([0-9a-f]+)', t).group(1), 16)
                for t in texts if t.startswith("ld XIX,")]
        flag = None
        for t in texts:
            m = re.search(r'cp \(0x([0-9a-f]+)\),0x00', t)
            if m:
                flag = int(m.group(1), 16)
        return ("table", (tabs, flag))
    return ("other", texts)


# ------------------------------------------------------- display-list titles
_DIS = {}


def disasm(addr, length=0x120):
    """unidasm the `length` bytes at `addr`, as [(addr, bytes, text)]."""
    key = (addr, length)
    if key in _DIS:
        return _DIS[key]
    img, base = ("wsa1_prom_a.ic12", 0xF80000) if addr >= 0xF80000 else \
                ("wsa1_prom_b.ic13", 0xF00000)
    src = open(os.path.join(ROOT, "original_ROMs", img), "rb").read()
    o = addr - base
    tmp = "/tmp/wsa1_ep_round7.bin"
    open(tmp, "wb").write(src[o:o + length])
    txt = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", "0x%06X" % addr],
                         capture_output=True, text=True).stdout
    out = []
    for ln in txt.split("\n"):
        m = re.match(r'^([0-9a-f]{6}): ((?:[0-9a-f]{2} )+)\s*(.*)$', ln)
        if m:
            out.append((int(m.group(1), 16), m.group(2).split(), m.group(3).strip()))
    _DIS[key] = out
    return out


def display_lists(entry):
    """[(list_lo, list_hi, interpreter)] the routine at `entry` draws, scanning
    linearly to its first `ret`.  XIY/XIX are the LAST such immediates loaded
    before the interpreter call -- prom_a's own rule, FINDINGS-ui-display-list."""
    ins = disasm(entry, 0x180)
    xiy = xix = None
    out = []
    for _a, _b, t in ins:
        m = re.match(r'ld XIY,0x00([0-9a-f]{6})$', t)
        if m:
            xiy = int(m.group(1), 16)
            continue
        m = re.match(r'ld XIX,0x00([0-9a-f]{6})$', t)
        if m:
            xix = int(m.group(1), 16)
            continue
        m = re.match(r'call 0x([0-9a-f]+)$', t)
        if m and int(m.group(1), 16) in INTERP and xiy is not None and xix is not None:
            out.append((xiy, xix, INTERP[int(m.group(1), 16)]))
            continue
        if t == "ret":
            break
    return out


def records(lo, hi):
    """The display list's `op,len` records.  Returns [(addr, op, len, payload)]."""
    out, a = [], lo
    while a < hi:
        op, ln = byte(a), byte(a + 1)
        if ln < 2 or a + ln > hi:
            break
        out.append((a, op, ln, bytes(byte(a + 2 + i) for i in range(ln - 2))))
        a += ln
    return out


def title_of(lo, hi):
    """The screen title a display list draws: the first contiguous run of op-0x1C
    records, whose payload is 4 bytes of coordinates then text."""
    recs = records(lo, hi)
    i = 0
    while i < len(recs) and recs[i][1] != 0x1C:
        i += 1
    parts = []
    while i < len(recs) and recs[i][1] == 0x1C:
        s = recs[i][3][4:].decode("latin-1").strip()
        if s:
            parts.append(s)
        i += 1
    return " ".join(parts)


def slug(text):
    """CamelCase the ROM's own text.  Keeps the ROM's spelling, digits included --
    "S0NG C0PY" becomes S0ngC0py, which is how prom_a spells the same screen."""
    words = re.split(r'[^A-Za-z0-9#]+', text)
    return "".join(w[:1].upper() + w[1:].lower() for w in words if w)


def painter_label(base):
    """The prom_a `Paint_<X>` label of this screen's painter, if prom_a has one.

    Where it exists it WINS, so one screen has one spelling across both images.
    Check R8 requires the title this script derives to be a PREFIX of it."""
    ent = slot_target(base)
    if ent is None:
        return None
    for _a, t in stub_body(ent):
        m = re.match(r'(?:call|calr) 0x([0-9a-f]+)', t)
        if m:
            tgt = int(m.group(1), 16)
            lab = label_at(tgt, SRCA) if tgt >= 0xF80000 else label_at(tgt, SRCB)
            return lab[len("Paint_"):] if lab and lab.startswith("Paint_") else None
    return None


def screen_title(base):
    """(title text, list address) for the screen object whose run starts at base."""
    ent = slot_target(base)
    if ent is None:
        return (None, None)
    body = stub_body(ent)
    tgt = None
    for _a, t in body:
        m = re.match(r'(?:call|calr) 0x([0-9a-f]+)', t)
        if m:
            tgt = int(m.group(1), 16)
            break
    if tgt is None:
        return (None, None)
    for lo, hi, _i in display_lists(tgt):
        t = title_of(lo, hi)
        if t:
            return (t, lo)
    return (None, None)


# ----------------------------------------------------------------- proposals
ROLE = {0: "Enter", 1: "Leave", 2: "Button", 3: "Null"}


def proposals():
    """{target address: (label, role, base, title)} for the stub-block entries."""
    out = {}
    for base, slots in runs():
        title, _lst = screen_title(base)
        s = painter_label(base) or (slug(title) if title else None)
        if s and (M.FRAMED.match("X_" + s) or M.UNNAMED.match("X_" + s)):
            s = None                      # a title that would grade FRAMED is unusable
        for k, slot in enumerate(slots):
            t = slot_target(slot)
            if t is None or not (BLOCK_LO <= t < BLOCK_HI):
                continue
            if t in out:                  # a shared word (the 0xF43040/48 overlap)
                continue
            role = ROLE[k]
            out[t] = ("Screen%s_%s" % (role, s) if s else "sub_%06X" % t,
                      role, base, title)
    # the 8 jrl veneers
    for slot in range(VENEER_LO, VENEER_HI, 4):
        t = slot_target(slot)
        if t is None or t in out:
            continue
        kind, dest = shape(t)
        # 0xF7D000 already carries StubBlock_F7D000 and keeps it; the labels this
        # pass writes all start Veneer_, so the proposal set is the same before
        # and after --apply (checks R9/R10 depend on that).
        have = existing_label(t)
        if have and not have.startswith("Veneer_"):
            continue
        dl = label_at(dest, SRCA) if dest is not None else None
        out[t] = ("Veneer_%s" % (dl if dl else "%06X" % dest), "Veneer", None, None)
    return out


EXTRA = {
    0xF19E4F: ("DL_Inter__F19E4F",
               ["; Evidence: directory slot T_F42FE8 names this address, but it is not code:",
                ";           it is record 17 of the display list DL_Inter (0xF19DDA-0xF19ED5),"
                " op 0x06, 5 bytes.  An INTERNAL point of a named object.  [round7-entrypoints]"]),
    0xF19EA4: ("DL_Inter__F19EA4",
               ["; Evidence: directory slot T_F42FEC names this address, but it is not code:",
                ";           it is record 26 of the display list DL_Inter (0xF19DDA-0xF19ED5),"
                " op 0x01, 10 bytes.  An INTERNAL point of a named object.  [round7-entrypoints]"]),
    0xF53000: ("RetStub_F53000",
               ["; Evidence: one `ret` at the head of a run of `0E 00 00 00` four-byte slots --",
                ";           the fill convention of 0xF55000 and of the thunk table itself."
                "  Named by directory slot T_F42E40, the ONLY reference to 0x00F53000 in"
                " either image (1 occurrence in prom_b, 0 in prom_a).  [round7-entrypoints]"]),
}


def existing_label(addr):
    """The label prom_b's .s already defines at `addr`, if any."""
    return label_at(addr, SRCB)


_LABMAP = {}


def label_at(addr, path):
    if path not in _LABMAP:
        at, pend = {}, []
        for ln in open(path):
            ln = ln.rstrip("\n")
            m = LABEL.match(ln)
            rest = ln
            if m:
                pend.append(m.group(1))
                rest = ln[m.end():]
            if rest.lstrip().startswith(";") or rest.strip() == "":
                continue
            a = ADDR.search(rest)
            if a and pend:
                at.setdefault(int(a.group(1), 16), []).extend(pend)
            pend = []
        _LABMAP[path] = at
    labs = _LABMAP[path].get(addr)
    return labs[0] if labs else None


# -------------------------------------------------------------------- report
def report():
    rr = runs()
    print("prom_b 0xF7D000 stub block -- the entry points prom_a's "
          "PanelScreen_VtableTable names")
    print()
    print("  four-word runs in the directory 0x%06X-0x%06X : %d"
          % (DIR_LO, DIR_HI, len(rr)))
    print("  of those, screens whose title the rule reads        : %d"
          % sum(1 for b, _s in rr if screen_title(b)[0]))
    props = proposals()
    print("  stub-block entry points with no label, now named    : %d" % len(props))
    g = collections.Counter()
    for name, role, _b, _t in props.values():
        g[("sub" if M.UNNAMED.match(name) else
           "framed" if M.FRAMED.match(name) else "content")] += 1
    for k in ("content", "framed", "sub"):
        print("      %-8s %d" % (k, g[k]))
    print()
    sh = collections.Counter(shape(t)[0] for t in props)
    print("  stub shapes: " + ", ".join("%s %d" % kv for kv in sorted(sh.items())))


def show_runs():
    print("  %-9s %-9s %-7s %s" % ("base", "enter", "role", "screen title"))
    for base, slots in runs():
        title, lst = screen_title(base)
        print("  %06X    %06X    %-7s %s"
              % (base, slot_target(base) or 0, "%d slots" % len(slots),
                 ("%-34s (list 0x%06X)" % (title, lst)) if title else "-- no titled list"))
    print("  %d runs" % len(runs()))


def show_proposals():
    props = proposals()
    for t in sorted(props):
        name, role, base, title = props[t]
        k, d = shape(t)
        print("  0x%06X  %-8s %-40s %s" % (t, role, name, k))
    print("  %d labels" % len(props))


def show_outoflane():
    """The 12 of the 115 that are not stub-block entry points."""
    sys.path.insert(0, os.path.join(ROOT, "notes"))
    import prom_b_thunks_round6 as R6
    rows = [r for r in R6.census() if r[4] == "disassembled"]
    outside = [r for r in rows if not (BLOCK_LO <= r[2] < BLOCK_HI)]
    print("  %d of the 115 are outside prom_b's 0xF7D000 block "
          "(this count is stable after --apply, which retires the other 103):"
          % len(outside))
    for slot, kind, t, name, g, where in sorted(rows, key=lambda r: r[2]):
        if BLOCK_LO <= t < BLOCK_HI:
            continue
        note = ""
        if where == "prom_a":
            note = "OUT OF LANE -- prom_a belongs to another lane this round"
        elif t in (0xF19E4F, 0xF19EA4):
            note = "inside the display list DL_Inter (0xF19DDA-0xF19ED5): a LIST entry, not a routine"
        else:
            note = "prom_b, outside the block"
        print("    T_%06X -> 0x%06X  %s" % (slot, t, note))


def show_blockshapes():
    """The stub block by SHAPE, and the mnemonic census the block header quotes.

    ⚠ This mode exists because the header written for 0xF7D000 in round 5 said
    the stubs "come in three shapes, and nothing else" and that the block holds
    "one `ld BC,HL`".  Both are wrong: there is a FOURTH shape (a bare `ret`,
    27 of them among the entry points) and there are THREE `ld BC,HL`."""
    eps = set()
    for base, slots in runs():
        for sl in slots:
            t = slot_target(sl)
            if t is not None and BLOCK_LO <= t < BLOCK_HI:
                eps.add(t)
    for sl in range(VENEER_LO, VENEER_HI, 4):
        eps.add(slot_target(sl))
    print("  entry points the directory names in 0x%06X-0x%06X: %d"
          % (BLOCK_LO, BLOCK_HI, len(eps)))
    for k, v in sorted(collections.Counter(shape(t)[0] for t in eps).items()):
        print("      %-8s %d" % (k, v))
    print()
    c = collections.Counter()
    for _a, (t, _i) in stubs().items():
        c[t.split()[0] if t else "?"] += 1
    print("  instruction mnemonics in the 728-byte block: %s"
          % ", ".join("%s %d" % kv for kv in sorted(c.items())))
    n = sum(1 for _a, (t, _i) in stubs().items() if t == "ld BC,HL")
    print("  `ld BC,HL` instructions: %d (the header used to say one)" % n)


def show_refused():
    rr = runs()
    print("R1  name a screen after its PanelScreen_VtableTable index")
    idx = [(b, (a - VT_LO) // 4) for b, addrs in sorted(vtable_targets().items())
           for a in addrs]
    print("      yield: +%d screens, e.g. ScreenEnter_%d" % (len(idx), idx[0][1]))
    print("      -> refused: the distinguishing part is a bare number; the metric")
    print("         would grade it CONTENT while it states nothing.  Same defect")
    print("         round 6 refused as Write3602_Index5.")
    print()
    print("R2  name the jrl veneers after their destination.  8 slots; 0xF7D000")
    print("    keeps StubBlock_F7D000, one destination is labelled in prom_a, and")
    print("    the remaining SIX destinations are not:")
    for slot in range(VENEER_LO, VENEER_HI, 4):
        t = slot_target(slot)
        k, dest = shape(t)
        print("        0x%06X -> prom_a 0x%06X  label there: %s"
              % (t, dest, label_at(dest, SRCA) or "(none)"))
    print("      -> refused for the six with no label: prom_a is another lane's")
    print("         file this round, so nothing here may name them.  They get")
    print("         Veneer_<destination>, which is FRAMED on purpose.")
    print()
    print("R3  treat 0xF19E4F / 0xF19EA4 as routines")
    for t in (0xF19E4F, 0xF19EA4):
        recs = records(0xF19DDA, 0xF19ED5)
        hit = [r for r in recs if r[0] == t]
        print("        0x%06X is record start %d of DL_Inter, op 0x%02X, %d bytes"
              % (t, recs.index(hit[0]), hit[0][1], hit[0][2]) if hit else
              "        0x%06X is NOT a record start" % t)
    print("      -> refused: they are entry points into a display LIST.  Round 6")
    print("         called them 'disassembled' because its test is whether the .s")
    print("         prints the address in a trailing comment, and a display-list")
    print("         record header does.")


# --------------------------------------------------------------------- apply
MARK = "round7-entrypoints"


def header_for(base, slots, title, lst):
    """The multi-line header written above a run's Enter label.  ONE per screen
    object -- the other three members get a two-line evidence block, so this pass
    cannot inflate the header count with 103 copies of one sentence."""
    ent = slot_target(base)
    btn = slot_target(slots[2]) if len(slots) > 2 else None
    tabs, flag = (None, None)
    if btn is not None:
        k, d = shape(btn)
        if k == "table":
            tabs, flag = d
    L = []
    L.append("; ---------------------------------------------------------------------")
    L.append("; Screen object %06X -- the panel screen whose own title text reads \"%s\""
             % (base, title))
    L.append("; Reached by: prom_a PanelScreen_VtableTable holds 0x%06X at %s, and its"
             % (base, ", ".join("0x%06X" % a for a in vtable_targets()[base])))
    L.append(";             three readers take +0 Enter, +4 Leave, +8 Button.")
    painter = None
    for _a, t in stub_body(ent):
        m = re.match(r'(?:call|calr) 0x([0-9a-f]+)', t)
        if m:
            painter = int(m.group(1), 16)
            break
    seen = (label_at(painter, SRCA) if painter >= 0xF80000 else label_at(painter, SRCB)) \
        if painter else None
    L.append("; Enter is `call 0x%06X` -- %s." % (painter, seen if seen else
             ("prom_a, unlabelled" if painter >= 0xF80000
              else "prom_b, still inside the 0xF7E2D8 .incbin")))
    L.append(";        That routine draws display list 0x%06X, whose leading" % lst)
    L.append(";        op-0x1C records spell")
    L.append(";        \"%s\" -- that text is where this name comes from and it is" % title)
    L.append(";        the ROM's own spelling, zeros for O's included.")
    if tabs:
        L.append("; Button dispatches on the panel button index through")
        if len(tabs) > 1:
            L.append(";        one of two 32-entry tables, 0x%06X and 0x%06X, chosen"
                     % (tabs[0], tabs[1]))
            L.append(";        on (0x%04X)." % flag)
        else:
            L.append(";        the 32-entry table 0x%06X." % tabs[0])
        L.append(";        T_F41B08 -> prom_a 0xF8BDC5 masks the index to 5 bits, and")
        L.append(";        so does prom_a's PanelButton_Route (`and L,0x1f`, 0xF861AE).")
    L.append("; Evidence: the vtable pointer above (prom_a ROM bytes, not its .s text);")
    L.append(";           the `ld XIY,0x00%06X` immediate inside 0x%06X, decoded from"
             % (lst, painter))
    L.append(";           the ROM -- %s;"
             % ("visible in this file" if seen or painter >= 0xF80000
                else "NOT visible here, that routine is still .incbin"))
    L.append(";           and the record walk of that list.  All three:")
    L.append(";           notes/prom_b_entrypoints_round7.py")
    if flag:
        L.append("; Unknown:  what (0x%04X) MEANS -- which of this screen's two button"
                 % flag)
        L.append(";           maps it picks, and when.")
    elif tabs:
        L.append("; Unknown:  nothing selects between maps here: this screen has ONE")
        L.append(";           button table, 0x%06X." % tabs[0])
    else:
        L.append("; Unknown:  this screen's +8 word is NOT a table dispatch -- its stub")
        L.append(";           is transcribed below, and what it dispatches on is unread.")
    L.append(";           Also unknown: what the run's fourth word is for.  Nothing")
    L.append(";           reads +0x0C and its stub is a no-op, in all 23 runs that")
    L.append(";           have one.")
    L.append(";           [%s]" % MARK)
    L.append("; ---------------------------------------------------------------------")
    return L


def evidence_for(t, name, role, base, title):
    """The TWO-line block written above a non-Enter member."""
    k, d = shape(t)
    if role == "Veneer":
        return ["; Evidence: a 3-byte `jrl` long-branch veneer, slot of the "
                "0xF7D000 veneer table;",
                ";           destination prom_a 0x%06X.  Named for the destination "
                "only.  [%s]" % (d, MARK)]
    if role == "Enter":
        return ["; Evidence: the +0 word of screen object %06X, which prom_a's "
                "PanelScreen_VtableTable" % base,
                ";           names at %s.  ⚠ NO NAME: its body reaches no display "
                "list, so nothing says which screen this is.  %s"
                % (", ".join("0x%06X" % x for x in vtable_targets()[base]), "[" + MARK + "]")]
    what = {"Leave": "the +4 word of screen object %06X" % base,
            "Button": "the +8 word of screen object %06X" % base,
            "Null":   "the +0x0C word of screen object %06X" % base}[role]
    if k == "null":
        body = "its body is a no-op (`ret`, or `calr` to a `ret` then `ret`)"
    elif k == "fwd":
        body = "its body is `call 0x%06X` then `ret`" % d
    elif k == "table":
        body = ("its body loads the %d-word button table%s at %s and calls "
                "T_F41B08" % (32, "s" if len(d[0]) > 1 else "",
                              " / ".join("0x%06X" % x for x in d[0])))
    else:
        body = "its body is transcribed below"
    tail = ("  NO READER of +0x0C exists in either image."
            if role == "Null" else "")
    return ["; Evidence: %s (prom_a's PanelScreen_VtableTable);" % what,
            ";           %s.%s  [%s]" % (body, tail, MARK)]


def unapply():
    """Remove every block this pass wrote, so --apply can write them again.

    A block is a run of consecutive comment lines containing the marker,
    immediately above one of this pass's labels, plus the blank line a header
    block is preceded by.  --refresh = unapply + apply, and it is what makes the
    prose regenerable instead of hand-patched."""
    names = set(n for n, _r, _b, _t in proposals().values()) | \
        set(v[0] for v in EXTRA.values())
    src = open(SRCB, encoding="utf-8").read().split("\n")
    kill = set()
    for i, ln in enumerate(src):
        m = LABEL.match(ln)
        if not m or m.group(1) not in names or ln.strip() != m.group(1) + ":":
            continue
        j = i - 1
        block = []
        while j >= 0 and src[j].startswith(";"):
            block.append(j)
            j -= 1
        if not any(MARK in src[k] for k in block):
            continue
        kill.add(i)
        kill.update(block)
        if j >= 0 and src[j].strip() == "":
            kill.add(j)
    out = [l for k, l in enumerate(src) if k not in kill]
    write_part(SRCB_MASTER, "\n".join(out))
    print("  removed %d lines (%d labels)" % (len(kill), sum(
        1 for k in kill if LABEL.match(src[k]))))
    return len(kill)


def apply_():
    """Insert the 103 labels into prom_b/wsa1_prom_b.s.  Idempotent: if the
    marker is already in the file, nothing is written."""
    props = proposals()
    text = open(SRCB, encoding="utf-8").read()
    todo = {a for a in list(props) + list(EXTRA) if existing_label(a) is None}
    if not todo:
        print("  already applied; nothing written")
        return 0
    names = [props[a][0] if a in props else EXTRA[a][0] for a in todo]
    dup = [n for n in names if re.search(r'(?m)^%s:' % re.escape(n), text)]
    if dup:
        print("  REFUSING: %d proposed names already exist in prom_b: %s"
              % (len(dup), dup[:5]))
        return 0
    src = text.split("\n")
    line_of = {}
    for i, ln in enumerate(src):
        m = ADDR.search(ln)
        if not m:
            continue
        a = int(m.group(1), 16)
        if a in todo and a not in line_of:
            line_of[a] = i
    at_line = {}
    for a, i in line_of.items():
        at_line.setdefault(i, a)
    run_of = {}
    for base, slots in runs():
        title, lst = screen_title(base)
        for k, slot in enumerate(slots):
            t = slot_target(slot)
            if t is not None:
                run_of.setdefault(t, (base, slots, title, lst, k))
    out, inserted, headers = [], 0, 0
    for i, ln in enumerate(src):
        t = at_line.get(i)
        if t is not None and t in EXTRA:
            out.extend(EXTRA[t][1])
            out.append(EXTRA[t][0] + ":")
            inserted += 1
        elif t is not None:
            name, role, base, title = props[t]
            if role == "Enter" and run_of.get(t) and run_of[t][3]:
                b, slots, ti, lst, _k = run_of[t]
                out.append("")
                out.extend(header_for(b, slots, ti, lst))
                headers += 1
            else:
                out.extend(evidence_for(t, name, role, base, title))
            out.append(name + ":")
            inserted += 1
        out.append(ln)
    write_part(SRCB_MASTER, "\n".join(out))
    print("  inserted %d labels, %d of them under a per-screen header "
          "(the other %d carry a TWO-line evidence block, which the metric does "
          "NOT count as a header)" % (inserted, headers, inserted - headers))
    return inserted


# ------------------------------------------------------------------ selftest
def selftest():
    ok = fail = 0

    def check(msg, cond):
        nonlocal ok, fail
        print("  %s %s" % ("PASS" if cond else "FAIL", msg))
        ok, fail = ok + bool(cond), fail + (not cond)

    rr = runs()
    check("R0  the directory run 0x%06X-0x%06X holds %d slots"
          % (DIR_LO, DIR_HI, (DIR_HI - DIR_LO) // 4), (DIR_HI - DIR_LO) // 4 == 104)
    check("R1  prom_a's vtable names %d distinct bases here" % len(rr), len(rr) == 25)
    vt = vtable_targets()
    check("R2  every base is inside the directory run",
          all(DIR_LO <= b < DIR_HI for b in vt))
    check("R3  the LAST base, 0x%06X, is one of them" % max(vt), max(vt) == 0xF431D0)
    check("R4  0xF43040 and 0xF43048 are BOTH bases, 8 apart -- so prom_a's "
          "3-method extents OVERLAP there and the first run holds 2 words, not 4",
          0xF43040 in vt and 0xF43048 in vt
          and len(dict(rr)[0xF43040]) == 2 and len(dict(rr)[0xF43048]) == 2)
    # R5 -- every table stub is a +8 word
    plus8 = set()
    for base, slots in rr:
        if len(slots) > 2:
            plus8.add(slot_target(slots[2]))
    eps = set()
    for base, slots in rr:
        for sl in slots:
            t = slot_target(sl)
            if t is not None and BLOCK_LO <= t < BLOCK_HI:
                eps.add(t)
    tabstubs = set(a for a in eps if shape(a)[0] == "table")
    check("R5  all %d table-dispatch ENTRY POINTS are +8 words of a screen object"
          % len(tabstubs), tabstubs and tabstubs <= plus8)
    # R6 -- every fourth word is a no-op
    fourth = [slot_target(s[3]) for _b, s in rr if len(s) > 3]
    kinds = [shape(t)[0] for t in fourth]
    check("R6  all %d fourth words are no-ops (%s)"
          % (len(fourth), collections.Counter(kinds)),
          set(kinds) == {"null"})
    # R6b -- the two-hop no-ops, and how many really do borrow the next routine's
    # predecessor's tail `ret`.  An earlier draft of the docstring said all five.
    enters = {slot_target(sl[0]) for _b, sl in rr}
    twohop = []
    for t in fourth:
        body = stub_body(t)
        if len(body) == 2:
            m = re.search(r'0x([0-9a-f]+)', body[0][1])
            twohop.append(int(m.group(1), 16))
    reached = set()
    for e in enters:
        for _a, tx in stub_body(e):
            m = re.match(r'(?:call|calr) 0x([0-9a-f]+)', tx)
            if m:
                reached.add(int(m.group(1), 16))
    below = [x for x in twohop if (x + 1) in reached]
    check("R6b %d of the 23 are two-hop (`calr <a ret>` then `ret`): %s -- and %d "
          "of them sit one byte below another run's Enter routine, not all %d"
          % (len(twohop), ["0x%06X" % x for x in twohop], len(below), len(twohop)),
          len(twohop) == 5 and len(below) == 3
          and all(byte(x) == 0x0E for x in twohop))
    # R7 -- the method offsets prom_a's OWN vtable readers use.  ⚠ The first
    # draft of this check asked whether `ld BC,0x000C` occurs ANYWHERE, and it
    # fails: there are 16 such sites across the four images (prom_a 0xFE3192,
    # 0xFE86D8, ... prom_c 0xFC34B5).  None is a vtable reader.  The claim that
    # can be made is about the readers, so that is what is measured.
    offs = set()
    for a in range(0xF86200, 0xF86560):
        w = bytes(byte(a + i) for i in range(6))
        if w[0] == 0x31:                                   # ld BC,imm16
            offs.add(w[1] | w[2] << 8)
        if w[:2] == b"\xe9\xc8":                           # add XBC,imm32
            offs.add(int.from_bytes(w[2:6], "little"))
    check("R7  prom_a's vtable readers (0xF86200-0xF86560) apply only the offsets "
          "%s -- +0x0C is not among them" % sorted(offs), 0x0C not in offs)
    # R7b -- the denominator R7 is scoped against.  These 16 sites are REAL; the
    # point is that none of them is inside a vtable reader, which is why the
    # claim is "no reader of +0x0C", not "the instruction does not occur".
    sites = []
    for k, name in (("a", "wsa1_prom_a.ic12"), ("b", "wsa1_prom_b.ic13"),
                    ("c", "wsa1_prom_c.ic28"), ("d", "wsa1_prom_d.bin")):
        d = open(os.path.join(ROOT, "original_ROMs", name), "rb").read()
        for pat in (b"\x31\x0c\x00", b"\xe9\xc8\x0c\x00\x00\x00"):
            o = d.find(pat)
            while o >= 0:
                sites.append((k, o))
                o = d.find(pat, o + 1)
    inreader = [x for x in sites
                if x[0] == "a" and 0xF86200 - 0xF80000 <= x[1] < 0xF86560 - 0xF80000]
    check("R7b `ld BC,0x000C` / `add XBC,0x0000000C` occurs %d times across the four "
          "images, and NONE is inside a vtable reader" % len(sites),
          len(sites) == 16 and inreader == [])
    # R8 -- the title rule reproduces prom_a's seven independent Paint_ names
    cal, bad = 0, []
    for base, slots in rr:
        ent = slot_target(base)
        body = stub_body(ent)
        tgt = None
        for _a, t in body:
            m = re.match(r'(?:call|calr) 0x([0-9a-f]+)', t)
            if m:
                tgt = int(m.group(1), 16)
                break
        lab = label_at(tgt, SRCA) if tgt and tgt >= 0xF80000 else None
        if lab and lab.startswith("Paint_"):
            cal += 1
            want = re.sub(r'[^A-Za-z0-9]', '', lab[len("Paint_"):]).upper()
            got = re.sub(r'[^A-Za-z0-9]', '', slug(screen_title(base)[0] or "")).upper()
            if not want.startswith(got) or not got:
                bad.append((lab, screen_title(base)[0]))
    check("R8  the derived title is a PREFIX of all %d prom_a Paint_ names (%s)"
          % (cal, bad or "no mismatch"), cal >= 7 and not bad)
    exact = 0
    for base, slots in rr:
        lab = painter_label(base)
        if lab:
            got = re.sub(r'[^A-Za-z0-9]', '', slug(screen_title(base)[0] or "")).upper()
            exact += (re.sub(r'[^A-Za-z0-9]', '', lab).upper() == got)
    check("R8b it reproduces %d of %d prom_a names EXACTLY; the one that differs "
          "is StepRecord, where prom_a's name also absorbs the op-0x07 subtitle "
          "': PART SELECT'" % (exact, cal), exact == cal - 1)
    props = proposals()
    check("R9  103 stub-block entry points proposed, got %d" % len(props),
          len(props) == 103)
    applied = MARK in open(SRCB, encoding="utf-8").read()
    check("R10 %s" % ("applied: every one of the 103 carries the proposed label"
                      if applied else "not yet applied: none carries a label"),
          all((existing_label(t) == props[t][0]) if applied
              else existing_label(t) is None for t in props))
    check("R14 the three non-block members of the 115 are labelled too "
          "(%s)" % ", ".join(EXTRA[a][0] for a in sorted(EXTRA)),
          all((existing_label(a) == EXTRA[a][0]) if applied
              else existing_label(a) is None for a in EXTRA))
    check("R15 106 of the 115 are prom_b's and now carry a label; the other 9 "
          "target prom_a and are OUT OF LANE",
          len(props) + len(EXTRA) == 106)
    last = max(props)
    name, role, base, title = props[last]
    check("R11 the LAST entry point 0x%06X is %s (%s)" % (last, name, role),
          last == 0xF7D2D7 and role == "Null")
    lastrun = rr[-1]
    lastnames = [props[slot_target(s)][0] for s in lastrun[1]
                 if slot_target(s) in props]
    check("R12 the LAST run 0x%06X has 4 slots, NO titled list, and therefore "
          "keeps sub_XXXXXX on all four: %s" % (lastrun[0], lastnames),
          len(lastrun[1]) == 4 and screen_title(lastrun[0])[0] is None
          and len(lastnames) == 4 and all(M.UNNAMED.match(n) for n in lastnames))
    # R13 -- the 0xF7D000 block is exactly the stubs the runs name, plus veneers
    named = set(props) | {0xF7D000}
    entrypoints = set()
    for base, slots in rr:
        for s in slots:
            t = slot_target(s)
            if t is not None and BLOCK_LO <= t < BLOCK_HI:
                entrypoints.add(t)
    for s in range(VENEER_LO, VENEER_HI, 4):
        entrypoints.add(slot_target(s))
    check("R13 every entry point the directory names in the block is covered",
          entrypoints <= named)
    print("  %d passed, %d failed" % (ok, fail))
    return fail


if __name__ == "__main__":
    a = sys.argv[1:]
    if "--runs" in a:
        show_runs()
    elif "--proposals" in a:
        show_proposals()
    elif "--outoflane" in a:
        show_outoflane()
    elif "--blockshapes" in a:
        show_blockshapes()
    elif "--refused" in a:
        show_refused()
    elif "--refresh" in a:
        unapply()
        _LABMAP.clear()
        apply_()
    elif "--unapply" in a:
        unapply()
    elif "--apply" in a:
        apply_()
    elif "--selftest" in a:
        sys.exit(1 if selftest() else 0)
    else:
        report()
