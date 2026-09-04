#!/usr/bin/env python3
"""
QUESTION THIS ANSWERS
=====================
"Where is the DATA-dial / value-key EDIT routine for each field of the tone
editor's MODELING pages, and what are that field's LIMITS and STEP?"

`notes/wsa1_toneedit_pages.py` (wave 21) mapped every MODELING page field by
field, but located per-field editors for only six of them, and said so:

    "The whole region 0xFD40B6-0xFD5B5E contains editors for only RESONATOR
     TYPE, GROUP, POSITION, the two MUTING values and the six key-follow
     notes; the other fields must be written from somewhere this pass did
     not find."

The reason it missed them is a shape, not an absence.  The six it found write
the tone message INLINE (`sub_FD6CE1` then `sub_FD616A`/`sub_FD6704`).  The
others hand the same work to a SHARED COMMIT ROUTINE, `sub_FD7435`, which takes
the RAM index and the parameter number as ARGUMENTS -- so a census keyed on the
inline shape sees nothing.  And no editor is reached by a `call`: every one of
them is an entry in a TABLE OF HANDLER POINTERS that a per-screen dispatcher
indexes with the panel event code.

WHAT IT ESTABLISHES, AND HOW
============================
1. THE DISPATCH.  Twelve routines in prom_a share one body:

       ldb  C,0x04
       mul  (XIZ-4),C          ; event index * 4
       extz XBC
       add  XBC,<TABLE>        ; a literal, different per screen
       ld   XBC,(XBC)
       lda  XIY,<return>
       push XIY
       jp   (XBC)              ; <-- the computed call

   The script finds them by that byte pattern, not by adjacency, and reads the
   17 pointers + NULL sentinel of each table straight out of the ROM.  Seven of
   the twelve tables are the MODELING screens'.

2. THE EVENT INDEX.  `sub_FD7905` turns the panel event code into that index:
   code<=0x10 -> index=code; 0x11..0x18 -> index=code-0x11 with a flag; 0x19 ->
   16.  So a row has 17 usable slots.

3. THE EDIT DESCRIPTOR.  Every editor builds the same 11-byte struct and hands
   it to `sub_FD6CE1` (directly or through `sub_FD7435`).  `sub_FD6CE1` and its
   two workers `sub_FD6D21` (unsigned) / `sub_FD6DD4` (signed) read it as:

       D[0]  the PACKED byte the field lives in   (from Arr27A6[index])
       D[3]  OUT: the new packed byte
       D[6]  MASK   -- must be non-zero or the edit is refused
       D[7]  SHIFT  -- must be <= 7 or the edit is refused
       D[8]  MAX
       D[9]  MIN    -- if negative, the SIGNED worker is used
       D[10] STEP   -- signed; written by sub_FD7C2D from the key/dial event;
                       zero is refused

   field = (D[0] >> D[7]) & D[6];  field += STEP, clamped to [MIN,MAX];
   D[3] = (D[0] & ~(D[6]<<D[7])) | (field << D[7]).

   So MASK/SHIFT/MIN/MAX are IMMEDIATES IN THE EDITOR, and they are this
   script's answer for a field's limits and step granularity.

4. THE COMMIT.  `sub_FD7435(screen, ramIndex, layer, param, D)` calls
   `sub_FD6CE1(D)`, and on a change sends `sub_FD616A(layer, param, &D[3],
   mask<<shift)` (melodic) or `sub_FD6704(...)` (drum kit), stores D[3] at
   `((u8 *)0x27A6)[ramIndex]` and repaints `screen`.  The screen code it is
   handed is a LITERAL in the editor, which is what binds an editor to a page
   -- no adjacency is used anywhere below.

HOW THE HANDLERS ARE READ
=========================
Each handler is walked as a CFG from its table entry, over the framing of the
committed `original_ROMs/wsa1_prom_a.ic12.unidasm` (see original_ROMs/
README-unidasm.md: the listing certifies a BYTE STRING, and every address this
walk steps to must be a line of it -- the walk asserts that).  Both sides of
every conditional branch are taken, so the MAIN-row and SUB-row constant blocks
are both recovered.  A tiny abstract interpreter tracks byte registers, XIZ
frame slots and the argument stack, so a `call` yields its actual arguments.

RUN
===
    cd <tree>/wsa1
    python3 notes/wsa1_toneedit_field_editors.py            # sections 1-4
    python3 notes/wsa1_toneedit_field_editors.py --raw      # + every handler's trace
    python3 notes/wsa1_toneedit_field_editors.py --selftest # assertions; 0 = OK

WHAT IT READS
=============
original_ROMs/wsa1_prom_a.ic12          the tables and all immediates
original_ROMs/wsa1_prom_a.ic12.unidasm  framing only
No .s file is an input.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
A_BASE = 0xF80000

# helper routines, by address.  Named from their bodies, not from the .s file.
ARR27A6_GET = 0xFD6C7B          # *(u8*)a2 = ((u8*)0x27A6)[a1]
ARR27A6_SET = 0xFD6C65          # ((u8*)0x27A6)[a1] = a2
VAR27F5_GET = 0xFDA0CA          # *(u8*)a1 = (0x27F5)   -- the drum-kit flag
EDIT_APPLY = 0xFD6CE1           # apply the step to the descriptor
EDIT_COMMIT = 0xFD7435          # descriptor -> message -> 0x27A6 -> repaint
STEP_FROM_KEY = 0xFD7C2D        # write D[10] from the panel event
NOTE_EDIT = 0xFDA3E2            # the same edit, MIN/MAX taken from two neighbours
MSG_MELODIC = 0xFD616A          # tone-parameter message, melodic
MSG_DRUM = 0xFD6704             # tone-parameter message, drum kit
REPAINT = 0xF41ED4              # T_Dispatch_Code80(screen, field)
POST_REQ = 0xFD608B             # PanelScreen_PostRequest(screen, arg)
DEFAULT_H = 0xFD6C93            # a bare `ret` -- the table's "nothing here"

ROW_LEN = 18                    # 17 handlers + a NULL sentinel


def rom():
    with open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb") as f:
        return f.read()


def listing():
    """address -> (nbytes, text) from the committed unidasm listing."""
    out = {}
    path = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12.unidasm")
    pat = re.compile(r"^([0-9a-f]{6}): ((?:[0-9a-f]{2} )+)\s*(.*)$")
    with open(path) as f:
        for line in f:
            m = pat.match(line.rstrip("\n"))
            if m:
                out[int(m.group(1), 16)] = (len(m.group(2).split()), m.group(3).strip())
    return out


# ---------------------------------------------------------------- section 1
DISPATCH_BODY = bytes.fromhex("23 04".replace(" ", ""))          # ldb C,0x04


def find_dispatchers(d):
    """Every site that does `add XBC,imm32 / ld XBC,(XBC) / ... / jp (XBC)`
    with the `ldb C,4 / mul / extz XBC` index computation in front of it."""
    out = []
    i = 0
    while True:
        j = d.find(bytes([0xE9, 0xC8]), i)          # add XBC,imm32
        if j < 0:
            break
        i = j + 1
        table = int.from_bytes(d[j + 2:j + 6], "little")
        # the four instructions that must precede it
        if d[j - 7:j - 5] != bytes([0x23, 0x04]):   # ldb C,0x04
            continue
        if d[j - 5] != 0x8E or d[j - 2:j] != bytes([0xE9, 0x12]):  # mul / extz XBC
            continue
        # and the computed jump that must follow
        tail = d[j + 6:j + 6 + 15]
        if tail[0:2] != bytes([0xA1, 0x21]):        # ld XBC,(XBC)
            continue
        if tail[2] != 0xF2 or tail[7] != 0x3D:      # lda XIY,imm24 / push XIY
            continue
        if tail[8:10] != bytes([0xB1, 0xD8]):       # jp (XBC)
            continue
        out.append((j - 7 + A_BASE, table))
    return out


def read_row(d, table):
    return [int.from_bytes(d[table - A_BASE + 4 * i:table - A_BASE + 4 * i + 4],
                           "little") for i in range(ROW_LEN)]


# ---------------------------------------------------------------- section 2
#  a very small abstract interpreter over the unidasm text
BYTE_REGS = ("A", "W", "B", "C", "D", "E", "H", "L")


class Machine(object):
    def __init__(self):
        self.r = {}                 # byte registers -> int
        self.wr = {}                # BC/WA/DE/HL as words -> int
        self.mem = {}               # XIZ frame slot (unsigned disp) -> int
        self.stack = []             # pushed argument values
        self.calls = []             # (target, [args])
        self.desc = {}              # descriptor offset -> immediate
        self.descbase = None        # XIZ disp of the descriptor, if via XIX
        self.xix_call = None        # a helper address parked in XIX
        self.retaddr = False        # the next `push XIY` is a return address

    def clone(self):
        m = Machine()
        m.r = dict(self.r); m.wr = dict(self.wr); m.mem = dict(self.mem)
        m.stack = list(self.stack); m.calls = list(self.calls)
        m.desc = dict(self.desc); m.descbase = self.descbase
        m.xix_call = self.xix_call; m.retaddr = self.retaddr
        return m


IMM = r"0x([0-9a-f]+)"


def step(m, text):
    """Interpret one instruction.  Anything not matched is ignored -- the
    tracked state is only what the argument-recovery below needs."""
    t = text
    mo = re.match(r"^lda XIX,XIZ\+" + IMM + "$", t)
    if mo:
        m.descbase = int(mo.group(1), 16)
        return
    # A HELPER HELD IN A REGISTER.  Three of the editors load Arr27A6_Get into
    # XIX once and reach it with `lda XIY,<ret> / push XIY / jp T,XIX` -- a
    # computed call that matches no `call` pattern at all.
    mo = re.match(r"^lda XIX,(0x[0-9a-f]+)$", t)
    if mo:
        m.xix_call = int(mo.group(1), 16)
        return
    mo = re.match(r"^lda XIY,(0x[0-9a-f]+)$", t)
    if mo:
        m.retaddr = True
        return
    if t in ("jp T,XIX", "jp XIX"):
        if m.xix_call is not None:
            args = list(reversed(m.stack))
            m.calls.append((m.xix_call, args))
            m.stack = []
            _taint(m, m.xix_call, args)
        return
    mo = re.match(r"^lda XBC,XIZ\+" + IMM + "$", t)
    if mo:
        m.wr["BC"] = ("&", int(mo.group(1), 16))
        return
    mo = re.match(r"^ld ([A-Z]),(0x[0-9a-f]+)$", t)
    if mo and mo.group(1) in BYTE_REGS:
        m.r[mo.group(1)] = int(mo.group(2), 16)
        return
    mo = re.match(r"^ld ([A-Z]),([A-Z])$", t)
    if mo and mo.group(1) in BYTE_REGS and mo.group(2) in BYTE_REGS:
        m.r[mo.group(1)] = m.r.get(mo.group(2))
        return
    mo = re.match(r"^ld \(XI([XZ])\+" + IMM + r"\),(0x[0-9a-f]+)$", t)
    if mo:
        off, val = int(mo.group(2), 16), int(mo.group(3), 16)
        if mo.group(1) == "X":
            m.desc[off] = val
        else:
            m.mem[off] = val
            if m.descbase is not None:
                rel = (off - m.descbase) & 0xFF
                if rel < 16:
                    m.desc[rel] = val
        return
    mo = re.match(r"^ld \(XIZ\+" + IMM + r"\),(BC|WA|DE|HL)$", t)
    if mo:
        m.mem[int(mo.group(1), 16)] = m.wr.get(mo.group(2))
        return
    mo = re.match(r"^ld (BC|WA|DE|HL),\(XIZ\+" + IMM + r"\)$", t)
    if mo:
        v = m.mem.get(int(mo.group(2), 16), ("frame", int(mo.group(2), 16)))
        m.wr[mo.group(1)] = v
        m.r[{"BC": "C", "WA": "A", "DE": "E", "HL": "L"}[mo.group(1)]] = \
            v & 0xFF if isinstance(v, int) else v
        return
    mo = re.match(r"^ld (BC|WA|DE|HL),(BC|WA|DE|HL)$", t)
    if mo:
        m.wr[mo.group(1)] = m.wr.get(mo.group(2))
        return
    if t in ("extz BC", "extz WA", "extz DE", "extz HL",
             "exts BC", "exts WA", "exts DE", "exts HL"):
        w = t.split()[1]
        lo = {"BC": "C", "WA": "A", "DE": "E", "HL": "L"}[w]
        m.wr[w] = m.r.get(lo)
        return
    mo = re.match(r"^ld ([A-Z]),\(XIZ\+" + IMM + r"\)$", t)
    if mo and mo.group(1) in BYTE_REGS:
        m.r[mo.group(1)] = m.mem.get(int(mo.group(2), 16))
        return
    mo = re.match(r"^push (0x[0-9a-f]+)$", t)
    if mo:
        m.stack.append(int(mo.group(1), 16))
        return
    mo = re.match(r"^pushw \(XIZ\+" + IMM + r"\)$", t)
    if mo:
        m.stack.append(m.mem.get(int(mo.group(1), 16)))
        return
    mo = re.match(r"^push (BC|WA|DE|HL|XBC|XWA|XDE|XHL|XIX|XIY)$", t)
    if mo:
        w = mo.group(1)
        if w == "XIY" and m.retaddr:
            m.retaddr = False          # a pushed RETURN ADDRESS, not an argument
            return
        if w == "XIX":
            m.stack.append("DESC")
        elif w.startswith("X"):
            m.stack.append(m.wr.get(w[1:]))
        else:
            m.stack.append(m.wr.get(w))
        return
    mo = re.match(r"^(?:call|calr) (0x[0-9a-f]+)", t)
    if mo:
        tgt = int(mo.group(1), 16)
        # This ABI pushes arguments right-to-left and the caller pops them
        # after the call, so the run of pushes since the PREVIOUS call is
        # exactly this call's argument list, last push first.  Modelling the
        # `inc n,XSP` / `add XSP,n` pops is not needed and would be fragile.
        args = list(reversed(m.stack))
        m.calls.append((tgt, args))
        m.stack = []
        _taint(m, tgt, args)
        return


def _taint(m, tgt, args):
    """Remember that a frame slot now holds ((u8 *)0x27A6)[k]."""
    if tgt == ARR27A6_GET and len(args) >= 2 \
       and isinstance(args[1], tuple) and args[1][0] == "&":
        m.mem[args[1][1]] = ("A27A6", args[0])


JUMP = re.compile(r"^(jr|jrl|jp) ([A-Z]+),(0x[0-9a-f]+)$")
UJUMP = re.compile(r"^(jr|jrl|jp) (?:T,)?(0x[0-9a-f]+)$")


def walk(lst, start, maxpaths=64, maxlen=600):
    """Enumerate paths from `start` to `ret`.  Returns a list of Machines."""
    out = []
    stack = [(start, Machine(), set())]
    while stack and len(out) < maxpaths:
        pc, m, seen = stack.pop()
        n = 0
        while True:
            n += 1
            if pc not in lst:
                raise AssertionError("walk left the listing at %06x" % pc)
            if n > maxlen or pc in seen:
                break
            seen = seen | {pc}
            nb, text = lst[pc]
            if text == "ret":
                out.append(m)
                break
            mo = JUMP.match(text)
            if mo and mo.group(2) != "T":
                stack.append((int(mo.group(3), 16), m.clone(), set(seen)))
                pc += nb
                continue
            mo = UJUMP.match(text)
            if mo:
                pc = int(mo.group(2), 16)
                continue
            step(m, text)
            pc += nb
    return out


# ---------------------------------------------------------------- section 3
def descriptor(m):
    """The MASK/SHIFT/MAX/MIN immediates of the edit descriptor on one path.

    They are written either through XIX (when the editor keeps the descriptor
    address in XIX) or straight into the XIZ frame.  In the second case the
    descriptor base is recovered by looking for four consecutive frame slots
    that satisfy the gate `sub_FD6CE1` applies: MASK non-zero and SHIFT <= 7.
    """
    if all(k in m.desc for k in (6, 7, 8, 9)):
        return {"mask": m.desc[6], "shift": m.desc[7],
                "hi": m.desc[8], "lo": m.desc[9]}
    for d0 in range(0x100):
        ks = [(d0 + 6 + k) & 0xFF for k in range(4)]
        if all(k in m.mem for k in ks):
            mask, shift, hi, lo = (m.mem[k] for k in ks)
            if isinstance(mask, int) and isinstance(shift, int) \
               and mask and shift <= 7:
                return {"mask": mask, "shift": shift, "hi": hi, "lo": lo}
    return {"mask": None, "shift": None, "hi": None, "lo": None}


def analyse(lst, addr):
    """-> (edits, sends, navs) for one handler, de-duplicated over paths.

    An edit is credited to the repaint that immediately precedes its message,
    which is how the (RAM index, parameter) pair is recovered for the editors
    that do not go through sub_FD7435.
    """
    edits, sends, navs = [], [], []
    for m in walk(lst, addr):
        d = descriptor(m)
        cs = m.calls
        rp = [(k, a) for k, (t, a) in enumerate(cs)
              if t == REPAINT and len(a) >= 2 and isinstance(a[0], int)]
        pend = None
        for k, (tgt, args) in enumerate(cs):
            if tgt == EDIT_COMMIT and len(args) >= 4:
                r = dict(screen=args[0], index=args[1], layer=args[2],
                         param=args[3], via="sub_FD7435", **d)
                if r not in edits:
                    edits.append(r)
            elif tgt == NOTE_EDIT and len(args) >= 4:
                pend = dict(index=args[1], lo=args[2], hi=args[3])
            elif tgt in (MSG_MELODIC, MSG_DRUM) and len(args) >= 2:
                if pend is not None:
                    # sub_FDA3E2 repaints BEFORE it sends
                    prev = [a for j, a in rp if j < k]
                    r = dict(screen=prev[-1][0] if prev else None,
                             index=pend["index"], param=args[1],
                             via="sub_FDA3E2", mask=0x7F, shift=0,
                             lo=pend["lo"], hi=pend["hi"])
                    pend = None
                else:
                    # the inline editors repaint AFTER they send
                    nxt = [a for j, a in rp if j > k]
                    r = dict(screen=nxt[0][0] if nxt else None,
                             index=nxt[0][1] if nxt else None,
                             param=args[1], via="inline", **d)
                if r not in sends:
                    sends.append(r)
            elif tgt == POST_REQ and args and isinstance(args[0], int):
                if args[0] not in navs:
                    navs.append(args[0])
    return edits, sends, navs


def s8(v):
    return v - 256 if v is not None and v >= 128 else v


def fmt(e):
    def h(x):
        return "--" if x is None else "0x%02X" % x
    lo, hi = e.get("lo"), e.get("hi")
    span = "?"
    if isinstance(lo, tuple) or isinstance(hi, tuple):
        span = "%s..%s" % (_sym(lo), _sym(hi))
    elif lo is not None and hi is not None:
        span = "%d..%d" % (s8(lo), hi)
    return "mask %s shift %s range %s" % (h(e.get("mask")), h(e.get("shift")), span)



# ---------------------------------------------------------------- section 4
# THE PAGE MAP THIS PASS IS CHECKED AGAINST.
#
# (screen code, RAM index into ((u8 *)0x27A6)) -> (parameter, caption).
# Every entry is copied from `notes/FINDINGS-l7a1429-editor-pages.md` sections
# 3a-3e, which derived it from the ENTER routines' read-back ORDER and the
# display-RAM addresses of the drawn values.  NOTHING here is derived from the
# editors -- that is the point: the editors are an INDEPENDENT instrument, and
# section 4 below is a disagreement test between the two.  A row that goes red
# is a real contradiction and must be reported, not smoothed away.
PAGE_MAP = {
    (0xC3, 0): (0x0D, "P0SITI0N"),
    (0xC3, 1): (0x0E, "DEPTH (bits 0-6) / FORMANT (bit 7)"),
    (0xC3, 2): (0x13, "INTERACTION GAIN"),
    (0xC4, 0): (0x10, "TOUCH"),
    (0xC4, 1): (0x11, "WIDTH"),
    (0xC4, 2): (0x12, "SPEED (bits 0-6) / S-H (bit 7)"),
    (0xC5, 1): (0x15, "MAIN FITTING"),
    (0xC5, 2): (0x16, "MAIN MUTING (bits 0-6) / MAIN RESO SCALE (bit 7)"),
    (0xC5, 3): (0x1D, "MAIN KEY SHIFT"),
    (0xC5, 4): (0x1E, "MAIN DETUNE"),
    (0xC5, 5): (0x1F, "SUB FITTING"),
    (0xC5, 6): (0x20, "SUB MUTING (bits 0-6) / SUB RESO SCALE (bit 7)"),
    (0xC5, 7): (0x29, "SUB KEY SHIFT"),
    (0xC5, 8): (0x2A, "SUB DETUNE"),
    (0xC6, 1): (0x17, "MAIN FITTING touch depth"),
    (0xC6, 2): (0x18, "MAIN MUTING touch depth"),
    (0xC6, 3): (0x21, "SUB GAIN"),
    (0xC6, 4): (0x22, "SUB FITTING touch depth"),
    (0xC6, 5): (0x23, "SUB MUTING touch depth"),
    (0xC6, 6): (0x24, "SUB GAIN touch depth"),
    (0xC7, 1): (0x15, "MAIN RESO MODE (bit 7)"),
    (0xC7, 2): (0x1F, "SUB RESO MODE (bit 7)"),
    (0xC7, 3): (0x19, "MAIN KEY FOLLOW break"),
    (0xC7, 4): (0x1A, "MAIN KEY FOLLOW low"),
    (0xC7, 5): (0x1B, "MAIN KEY FOLLOW high"),
    (0xC7, 6): (0x1C, "MAIN MUTING SLOPE"),
    (0xC7, 7): (0x25, "SUB KEY FOLLOW break"),
    (0xC7, 8): (0x26, "SUB KEY FOLLOW low"),
    (0xC7, 9): (0x27, "SUB KEY FOLLOW high"),
    (0xC7, 10): (0x28, "SUB MUTING SLOPE"),
}
MODELING_TABLES = [0xFCF974 + 0x48 * k for k in range(7)]

# Editors that the (screen, index) test cannot judge, each with its reason
# printed rather than skipped silently.
EXCEPTIONS = {
    0xFD414E: "RESONATOR TYPE p0B: its value lives in ((u8 *)0x2808)[layer], "
              "not in 0x27A6, and it refreshes by re-requesting rather than "
              "through T_Dispatch_Code80 -- so it has no RAM index to test.",
    0xFD422B: "GROUP p0B: a bespoke 0..4 encoder, not an EditDesc; already "
              "established in FINDINGS-l7a1429-editor-pages.md section 1a.",
    0xFD44C7: "P0SITI0N p0D: it edits Arr27A6[0] but then writes the DISPLAYED "
              "/5 split into indices 4 and 5, so the repaint that follows names "
              "index 4.  p0D does match PAGE_MAP[(0xC3, 0)].",
    0xFD5C63: "screen 0xA8, selector 0 -- the 300-byte PART record, not the "
              "arm-4 wave-select record.  p10 there is a different byte.",
    0xFD5D01: "screen 0xA8, selector 0 -- as above.",
}


def crosscheck(allfacts):
    """-> (agreements, contradictions, unmapped) between the editors and the
    read-back-order page map."""
    agree, clash, unmapped = [], [], []
    for (table, i), (h, edits, sends, navs) in sorted(allfacts.items()):
        if table not in MODELING_TABLES:
            continue
        for e in edits + sends:
            scr, idx, par = e.get("screen"), e.get("index"), e.get("param")
            if h in EXCEPTIONS or not isinstance(scr, int) \
               or not isinstance(idx, int) or not isinstance(par, int):
                unmapped.append((h, i, e))
                continue
            if h in EXCEPTIONS:
                unmapped.append((h, i, e))
                continue
            want = PAGE_MAP.get((scr, idx))
            if want is None:
                unmapped.append((h, i, e))
            elif want[0] == par:
                agree.append((h, i, e, want[1]))
            else:
                clash.append((h, i, e, want))
    return agree, clash, unmapped


# ---------------------------------------------------------------- main
def main(argv):
    d = rom()
    lst = listing()
    disp = find_dispatchers(d)
    print("=" * 74)
    print("1. THE COMPUTED-CALL DISPATCHERS (found by byte pattern, not by name)")
    print("=" * 74)
    rows = []
    for site, table in disp:
        row = read_row(d, table)
        live = sum(1 for v in row[:17] if v not in (DEFAULT_H, 0))
        print("   %06X  table %06X  live handlers %2d  sentinel %s"
              % (site, table, live, "OK" if row[17] == 0 else "MISSING"))
        rows.append((site, table, row))
    print()

    print("=" * 74)
    print("2. EVERY HANDLER IN EVERY ROW, AND WHAT IT DOES")
    print("=" * 74)
    allfacts = {}
    for site, table, row in rows:
        print("-- dispatcher %06X, table %06X" % (site, table))
        for i, h in enumerate(row[:17]):
            if h in (DEFAULT_H, 0):
                continue
            edits, sends, navs = analyse(lst, h)
            allfacts[(table, i)] = (h, edits, sends, navs)
            tag = []
            for e in edits:
                tag.append("EDIT screen 0x%02X idx %s param %s  %s"
                           % (e["screen"], e["index"], _p(e["param"]), fmt(e)))
            for e in sends:
                tag.append("EDIT(inline) screen %s idx %s param %s  %s"
                           % (_p(e["screen"]), e["index"], _p(e["param"]), fmt(e)))
            if not tag and navs:
                tag.append("nav -> " + " ".join("0x%02X" % n for n in navs
                                                if isinstance(n, int)))
            if not tag:
                tag.append("(no edit descriptor, no nav)")
            print("   [%2d] %06X  %s" % (i, h, tag[0]))
            for extra in tag[1:]:
                print("        %s" % extra)
        print()

    print("=" * 74)
    print("3. THE MODELING PAGES' FIELD EDITORS, BY PAGE")
    print("   (section 2 above is the whole census; this is the seven tables")
    print("    the tone editor's MODELING screens dispatch through)")
    print("=" * 74)
    bypage = {}
    for (table, i), (h, edits, sends, navs) in sorted(allfacts.items()):
        if table not in MODELING_TABLES:
            continue
        for e in edits:
            bypage.setdefault(e["screen"], []).append((i, h, e))
        for e in sends:
            bypage.setdefault(e["screen"], []).append((i, h, e))
    for scr in sorted(bypage, key=lambda x: (x is None, x if x is not None else 0)):
        print("   screen 0x%02X" % scr if scr is not None else "   (no repaint)")
        seen = set()
        for i, h, e in sorted(bypage[scr], key=lambda t: (t[0], t[1])):
            k = (i, e.get("index"), e.get("param"))
            if k in seen:
                continue
            seen.add(k)
            print("      key %2d  %06X  Arr27A6[%s] <- p%s   %s   [%s]"
                  % (i, h, e.get("index"), _p(e["param"]), fmt(e), e["via"]))
        print()

    print("=" * 74)
    print("4. THE EDITORS AGAINST THE READ-BACK-ORDER PAGE MAP")
    print("   (two independent instruments; a clash below is a contradiction)")
    print("=" * 74)
    agree, clash, unmapped = crosscheck(allfacts)
    for h, i, e, cap in agree:
        print("   ok      %06X key %2d  screen 0x%02X idx %2d p%02X  %-42s %s"
              % (h, i, e["screen"], e["index"], e["param"], cap, fmt(e)))
    print()
    for h, i, e, want in clash:
        print("   CLASH   %06X key %2d  screen 0x%02X idx %2d editor says p%02X, "
              "the page map says p%02X (%s)"
              % (h, i, e["screen"], e["index"], e["param"], want[0], want[1]))
    for h, i, e in unmapped:
        print("   outside the test: %06X key %2d  screen %s idx %s p%s  %s"
              % (h, i, _p(e.get("screen")), e.get("index"), _p(e.get("param")),
                 fmt(e)))
        if h in EXCEPTIONS:
            print("        reason: %s" % EXCEPTIONS[h])
    print()
    print("   AGREEMENTS %d   CONTRADICTIONS %d   UNMAPPED %d"
          % (len(agree), len(clash), len(unmapped)))
    print()

    if "--raw" in argv:
        print("=" * 74)
        print("4. RAW CALL TRACES")
        print("=" * 74)
        for (table, i), (h, edits, sends, navs) in sorted(allfacts.items()):
            print("-- %06X (table %06X slot %d)" % (h, table, i))
            for m in walk(lst, h):
                print("     path: " + ", ".join(
                    "%06X%s" % (t, a) for t, a in m.calls))
    return 0


def _sym(v):
    if isinstance(v, tuple) and v[0] == "A27A6":
        return "Arr27A6[%s]" % v[1]
    return "%r" % (v,)


def _p(v):
    return "??" if not isinstance(v, int) else "%02X" % v


# ---------------------------------------------------------------- selftest
def _facts():
    d, lst = rom(), listing()
    out = {}
    for site, table in find_dispatchers(d):
        for i, h in enumerate(read_row(d, table)[:17]):
            if h in (DEFAULT_H, 0):
                continue
            out[(table, i)] = (h,) + analyse(lst, h)
    return d, lst, out


def selftest():
    d, lst, facts = _facts()
    checks, fails = [], 0
    disp = find_dispatchers(d)
    checks.append(("30 dispatchers share the computed-call shape",
                   len(disp) == 30, len(disp)))
    checks.append(("the 7 tables from 0xFCF974 are 0x48 apart and all present",
                   set(MODELING_TABLES) <= set(t for _, t in disp), None))
    for _, t in disp:
        checks.append(("row %06X ends in a NULL sentinel" % t,
                       read_row(d, t)[17] == 0, read_row(d, t)[17]))

    agree, clash, unmapped = crosscheck(facts)
    checks.append(("33 editor bindings agree with the page map",
                   len(agree) == 33, len(agree)))
    checks.append(("no editor CONTRADICTS the page map",
                   len(clash) == 0, [c[:2] for c in clash]))
    checks.append(("exactly the 5 declared exceptions fall outside the test",
                   sorted(set(h for h, _, _ in unmapped)) ==
                   sorted(EXCEPTIONS), sorted(set(h for h, _, _ in unmapped))))

    # >>> THE CONTROL.  The agreement above is worth nothing unless the
    # instrument can register a disagreement, so run it once against a page map
    # with two entries swapped and require the clashes to appear.
    global PAGE_MAP
    keep = dict(PAGE_MAP)
    PAGE_MAP[(0xC5, 1)], PAGE_MAP[(0xC5, 5)] = keep[(0xC5, 5)], keep[(0xC5, 1)]
    _, clash2, _ = crosscheck(facts)
    PAGE_MAP = keep
    checks.append(("NULL: swapping MAIN/SUB FITTING in the map DOES clash",
                   len(clash2) == 2, len(clash2)))

    def one(table, i):
        h, e, sn, _ = facts[(table, i)]
        return h, (e + sn)

    # the limits this pass is quoting, each re-read from the ROM
    lim = {
        (0xFCF9BC, 2): (0x7F, 0, 0x7F, 0x00),     # DEPTH
        (0xFCF9BC, 3): (0x01, 7, 0x01, 0x00),     # FORMANT
        (0xFCF9BC, 5): (0x7F, 0, 0x7F, 0x00),     # INTERACTION GAIN
        (0xFCFA04, 1): (0x7F, 0, 0x32, 0x00),     # WIDTH
        (0xFCFA04, 2): (0x7F, 0, 0x32, 0x00),     # SPEED
        (0xFCFA04, 3): (0x01, 7, 0x01, 0x00),     # S/H
        (0xFCFA04, 5): (0xFF, 0, 0x32, 0xCE),     # TOUCH
        (0xFCFA4C, 1): (0x7F, 0, 0x7F, 0x00),     # FITTING
        (0xFCFA4C, 3): (0xFF, 0, 0x3C, 0xC4),     # KEY SHIFT
        (0xFCFA4C, 4): (0xFF, 0, 0x7F, 0x80),     # DETUNE
        (0xFCFA4C, 5): (0x01, 7, 0x01, 0x00),     # RESO SCALE
        (0xFCFA94, 5): (0xFF, 0, 0x64, 0x9C),     # SUB GAIN
        (0xFCFADC, 1): (0x01, 7, 0x01, 0x00),     # RESO MODE
        (0xFCFADC, 2): (0xFF, 0, 0x32, 0xCE),     # MUTING SLOPE
    }
    for k, (mask, shift, hi, lo) in lim.items():
        h, recs = one(*k)
        ok = bool(recs) and all(r["mask"] == mask and r["shift"] == shift and
                                r["hi"] == hi and r["lo"] == lo for r in recs)
        checks.append(("%06X limits %02X/%d %02X..%02X" % (h, mask, shift, lo, hi),
                       ok, [(r["mask"], r["shift"], r["lo"], r["hi"]) for r in recs]))

    # the three KEY FOLLOW notes bound EACH OTHER, which is what orders them
    h, recs = one(0xFCFADC, 3)      # low: 0 .. Arr27A6[break]
    checks.append(("KEY FOLLOW low is 0..Arr27A6[break]",
                   [(r["lo"], r["hi"]) for r in recs] ==
                   [(0, ("A27A6", 3)), (0, ("A27A6", 7))], None))
    h, recs = one(0xFCFADC, 4)      # break: Arr27A6[low] .. Arr27A6[high]
    checks.append(("KEY FOLLOW break is Arr27A6[low]..Arr27A6[high]",
                   [(r["lo"], r["hi"]) for r in recs] ==
                   [(("A27A6", 4), ("A27A6", 5)), (("A27A6", 8), ("A27A6", 9))],
                   None))
    h, recs = one(0xFCFADC, 5)      # high: Arr27A6[break] .. 127
    checks.append(("KEY FOLLOW high is Arr27A6[break]..127",
                   [(r["lo"], r["hi"]) for r in recs] ==
                   [(("A27A6", 3), 0x7F), (("A27A6", 7), 0x7F)], None))

    # the step: sub_FD7C2D writes +/-1, tripled when the event's bit 7 is set
    body = d[0xFD7C2D - A_BASE:0xFD7C5A - A_BASE]
    checks.append(("sub_FD7C2D writes +1 / -1", b"\xb4\x00\x01" in body and
                   b"\xb4\x00\xff" in body, None))
    checks.append(("sub_FD7C2D triples it on bit 7",
                   b"\xcb\x09\x03" in body, None))

    # slot 6 of the three two-row pages is one shared routine
    for t in (0xFCFA4C, 0xFCFA94, 0xFCFADC):
        h = read_row(d, t)[6]
        checks.append(("row %06X slot 6 tail-calls 0xFD4FE0" % t,
                       d[h - A_BASE] == 0x1E and
                       h + 3 + int.from_bytes(d[h + 1 - A_BASE:h + 3 - A_BASE],
                                              "little", signed=True) == 0xFD4FE0,
                       None))

    for name, ok, got in checks:
        if not ok:
            fails += 1
            print("FAIL: %s   (got %r)" % (name, got))
    print("checks: %d   FAILURES: %d" % (len(checks), fails))
    return 1 if fails else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    sys.exit(main(sys.argv))
