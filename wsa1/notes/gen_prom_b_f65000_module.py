#!/usr/bin/env python3
"""Emit the assembly for prom_b 0xF65000-0xF6D001 -- the three modules at the
head of the `.incbin` span 0x065000-0x078000.

QUESTION IT ANSWERS
    "What is the assembly text for the four thunk-table runs that live in the
     0xF65000 span, in a form the byte gate accepts, with every label and header
     attached to the right address?"  This is the emitter whose output is pasted
     into prom_b/wsa1_prom_b.s.

WHY THIS BLOCK (round 4, chosen with the frontier tool, not by address order)
    notes/prom_b_module_frontier.py ranks whole thunk RUNS by CONTIGUOUS
    unconverted target extent.  Its top four runs by that measure all point into
    this one `.incbin` span:
        T_F42ED0-T_F42F04  14 slots  extent 20,977  targets 0xF67434-0xF6C625
        T_F42EC0-T_F42EC8   3 slots  extent 14,463  targets 0xF675CC-0xF6AE4B
        T_F42B70-T_F42C2C  48 slots  extent  2,648  targets 0xF65C00-0xF66658
        T_F432C0-T_F432CC   4 slots  extent      9  targets 0xF65000-0xF65009
    69 slots between them.  Converting 0xF65000-0xF6D001 as one span retires all
    four: every one of their targets is inside it.
    notes/prom_b_f65000_frontier_delta.py re-derives that from the ROM and from
    the .s, before and after.

WHERE THE BOUNDARIES COME FROM
    notes/prom_b_f65000_layout.py, and NOT from a linear decode -- see
    notes/prom_a_linear_decode_check.py for why a linear decode pins nothing.
    Five CONTENT rules run first and become BARRIERS the code walk may not enter
    (pointer table, RAM-pointer table, bit-weight table, index map, string), then
    a recursive descent from the thunk targets and from every opcode-anchored
    `call`/`jp` site in prom_a+prom_b fills in the code.  Each content rule was
    calibrated against every maximal run of PROVEN instruction text already in
    prom_b/wsa1_prom_b.s -- 54,814 bytes -- and fires ZERO times there:
        python3 notes/prom_b_f65000_layout.py --null
    checks() re-derives the whole LAYOUT from that script on every emit and
    refuses to print if one segment differs.

    ⚠ The ASCII threshold is TWENTY bytes, not eight or ten, because at 8 the
    same null corpus produces 7 false positives and at 10 it produces 3.  The
    cost is stated rather than hidden: the 9-byte string `VOLUME = ` at 0xF67DC6
    is NOT promoted; it sits inside a CODE segment and comes out as `db` bytes.

RUN
    python3 notes/gen_prom_b_f65000_module.py            # the assembly
    python3 notes/gen_prom_b_f65000_module.py --layout   # the segment table
    python3 notes/gen_prom_b_f65000_module.py --checks   # REFUSES to emit on fail
    python3 notes/gen_prom_b_f65000_module.py --tables   # every data object
"""
import os
import re
import subprocess
import sys
import textwrap

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
AUTOFORCE = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")
IMGB = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
IMGA = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
B_BASE, A_BASE = 0xF00000, 0xF80000
LO, HI = 0xF65000, 0xF6D002
TBL_LO, TBL_HI = 0x40000, 0x44018

import prom_b_f65000_layout as LY                                  # noqa: E402
import prom_b_module_trace as MT                                    # noqa: E402

LAYOUT = [
    ("code", 0xF65000, 0x07B2),
    ("data", 0xF657B2, 0x0001),
    ("fill", 0xF657B3, 0x044D),
    ("code", 0xF65C00, 0x01CC),
    ("data", 0xF65DCC, 0x0006),
    ("code", 0xF65DD2, 0x001F),
    ("data", 0xF65DF1, 0x0006),
    ("code", 0xF65DF7, 0x005E),
    ("ident", 0xF65E55, 0x003E),
    ("data", 0xF65E93, 0x0001),
    ("code", 0xF65E94, 0x0938),
    ("ident", 0xF667CC, 0x0060),
    ("code", 0xF6682C, 0x0206),
    ("fill", 0xF66A32, 0x09CE),
    ("code", 0xF67400, 0x00CE),
    ("ptrtab", 0xF674CE, 0x0010),
    ("code", 0xF674DE, 0x006A),
    ("ptrtab", 0xF67548, 0x0010),
    ("code", 0xF67558, 0x0063),
    ("ptrtab", 0xF675BB, 0x0010),
    ("code", 0xF675CB, 0x0028),
    ("ptrtab", 0xF675F3, 0x0010),
    ("code", 0xF67603, 0x0013),
    ("ptrtab", 0xF67616, 0x0080),
    ("code", 0xF67696, 0x008D),
    ("ptrtab", 0xF67723, 0x004C),
    ("code", 0xF6776F, 0x001A),
    ("ptrtab", 0xF67789, 0x004C),
    ("code", 0xF677D5, 0x001A),
    ("ptrtab", 0xF677EF, 0x0080),
    ("code", 0xF6786F, 0x00CA),
    ("ptrtab", 0xF67939, 0x0080),
    ("code", 0xF679B9, 0x001A),
    ("ptrtab", 0xF679D3, 0x0080),
    ("code", 0xF67A53, 0x0027),
    ("ptrtab", 0xF67A7A, 0x0080),
    ("code", 0xF67AFA, 0x001A),
    ("ptrtab", 0xF67B14, 0x0080),
    ("code", 0xF67B94, 0x001A),
    ("ptrtab", 0xF67BAE, 0x0080),
    ("code", 0xF67C2E, 0x0027),
    ("ptrtab", 0xF67C55, 0x0080),
    ("code", 0xF67CD5, 0x001A),
    ("ptrtab", 0xF67CEF, 0x0080),
    ("code", 0xF67D6F, 0x007A),
    ("ptrtab", 0xF67DE9, 0x0080),
    ("code", 0xF67E69, 0x005F),
    ("ident", 0xF67EC8, 0x0020),
    ("ramtab", 0xF67EE8, 0x0080),
    ("code", 0xF67F68, 0x002E),
    ("ptrtab", 0xF67F96, 0x0080),
    ("code", 0xF68016, 0x0275),
    ("ptrtab", 0xF6828B, 0x0080),
    ("code", 0xF6830B, 0x02B6),
    ("ptrtab", 0xF685C1, 0x0080),
    ("code", 0xF68641, 0x001A),
    ("ptrtab", 0xF6865B, 0x0080),
    ("code", 0xF686DB, 0x001A),
    ("ptrtab", 0xF686F5, 0x0080),
    ("code", 0xF68775, 0x015B),
    ("ptrtab", 0xF688D0, 0x0010),
    ("code", 0xF688E0, 0x0092),
    ("ptrtab", 0xF68972, 0x0010),
    ("code", 0xF68982, 0x0632),
    ("ptrtab", 0xF68FB4, 0x0010),
    ("code", 0xF68FC4, 0x0578),
    ("ptrtab", 0xF6953C, 0x0010),
    ("code", 0xF6954C, 0x06D8),
    ("ptrtab", 0xF69C24, 0x0010),
    ("code", 0xF69C34, 0x0821),
    ("ident", 0xF6A455, 0x0020),
    ("data", 0xF6A475, 0x0028),
    ("code", 0xF6A49D, 0x023E),
    ("ptrtab", 0xF6A6DB, 0x0010),
    ("code", 0xF6A6EB, 0x02BF),
    ("ident", 0xF6A9AA, 0x0020),
    ("code", 0xF6A9CA, 0x01C8),
    ("ptrtab", 0xF6AB92, 0x0014),
    ("fill", 0xF6ABA6, 0x0010),
    ("code", 0xF6ABB6, 0x001C),
    ("ptrtab", 0xF6ABD2, 0x0010),
    ("code", 0xF6ABE2, 0x0122),
    ("ident", 0xF6AD04, 0x0020),
    ("code", 0xF6AD24, 0x02E2),
    ("data", 0xF6B006, 0x0018),
    ("code", 0xF6B01E, 0x01E0),
    ("data", 0xF6B1FE, 0x002B),
    ("code", 0xF6B229, 0x1049),
    ("ptrtab", 0xF6C272, 0x0010),
    ("code", 0xF6C282, 0x0575),
    ("bittab", 0xF6C7F7, 0x0080),
    ("code", 0xF6C877, 0x01C4),
    ("ascii", 0xF6CA3B, 0x0028),
    ("ramtab", 0xF6CA63, 0x0080),
    ("code", 0xF6CAE3, 0x010B),
    ("ptrtab", 0xF6CBEE, 0x0080),
    ("code", 0xF6CC6E, 0x0394),
]

DATA_KINDS = ("data", "ident", "ptrtab", "ramtab", "bittab", "ascii")
PREFIX = {"data": "Data", "ident": "IndexMap", "ptrtab": "DispatchTable",
          "ramtab": "RamPtrTable", "bittab": "BitWeight", "ascii": "Text"}
# The module's own do-nothing entry: 0xF675CB is a single 0x0E byte, i.e. `ret`,
# and it is what most dispatch-table slots point at.  ⚠ It is NOT the image-wide
# default thunk slot 0x00F42C70 (notes/prom_b_default_slot_census.py); the first
# draft of this file subtracted THAT one when counting "distinct other targets"
# and printed 3 where the answer is 2, in a header the byte gate cannot see.
STUB = 0x00F675CB
DEFAULT_SLOT = 0x00F42C70

_cache = {}


def rom(which="b"):
    if which not in _cache:
        _cache[which] = open(IMGA if which == "a" else IMGB, "rb").read()
    return _cache[which]


def at(addr, n=1):
    return rom("b")[addr - B_BASE: addr - B_BASE + n]


def w32(a):
    return int.from_bytes(at(a, 4), "little")


def transcribe(start, length):
    key = ("t", start, length)
    if key not in _cache:
        out = subprocess.run(
            [sys.executable, AUTOFORCE, "b", hex(start), hex(length), "--quiet"],
            capture_output=True, text=True, cwd=ROOT)
        if out.returncode != 0:
            raise SystemExit("autoforce failed at 0x%06X:\n%s" % (start, out.stderr))
        _cache[key] = out.stdout.rstrip("\n").split("\n")
    return _cache[key]


def code_lines():
    if "cl" not in _cache:
        out = []
        for kind, s, n in LAYOUT:
            if kind == "code":
                for ln in transcribe(s, n):
                    m = re.search(r";\s*([0-9A-F]{6})\s", ln)
                    out.append((int(m.group(1), 16), ln))
        _cache["cl"] = out
    return _cache["cl"]


def mame_text(a):
    for ad, ln in code_lines():
        if ad == a:
            t = ln.split(";", 1)[1].strip()
            return t[7:].strip()
    return ""


def boundaries():
    return {a for a, _ in code_lines()}


def thunks():
    """{target: [slot, ...]} for `jp nnn` slots of 0xF40000 landing in range."""
    d, out = rom("b"), {}
    for o in range(TBL_LO, TBL_HI, 4):
        if d[o] == 0x1B:
            t = d[o + 1] | d[o + 2] << 8 | d[o + 3] << 16
            if LO <= t < HI:
                out.setdefault(t, []).append(B_BASE + o)
    return out


def slot_refs():
    """Opcode-anchored UPPER BOUND on references to each thunk SLOT address."""
    cnt = {}
    for blob in (rom("a"), rom("b")):
        for i in range(len(blob) - 3):
            if blob[i] in (0x1D, 0x1B):
                t = blob[i + 1] | blob[i + 2] << 8 | blob[i + 3] << 16
                if B_BASE + TBL_LO <= t < B_BASE + TBL_HI and t % 4 == 0:
                    cnt[t] = cnt.get(t, 0) + 1
    return cnt


def direct_refs(addr):
    """Every byte offset in prom_a+prom_b spelling `addr` as a 32-bit LE word.
    An UPPER BOUND -- the scan is at every byte, not at instruction boundaries."""
    tgt = addr.to_bytes(4, "little")
    out = []
    for blob, base in ((rom("a"), A_BASE), (rom("b"), B_BASE)):
        i = 0
        while True:
            i = blob.find(tgt, i)
            if i < 0:
                break
            out.append(base + i)
            i += 1
    return out


def reader(a):
    """(address, mnemonic) of the transcribed instruction CONTAINING the 32-bit
    reference at `a`.  ⚠ NOT `a-1`: `ld XIX,imm32` is a one-byte opcode but
    `add XWA,imm32` is two, so the operand starts a different distance in."""
    best = None
    for ad, _ in code_lines():
        if ad <= a and (best is None or ad > best):
            best = ad
    return (best, mame_text(best)) if best is not None else (None, "")


def classify_ref(a):
    """What KIND of thing is the 32-bit spelling of an address at byte offset a?

    direct_refs() is a byte scan, so its hits are of three kinds, and the first
    draft of this file reported all of them the same way -- it printed
    "`ret` at 0xF677EE" as the READER of Data_F67D6F, because a 4-byte window
    straddling the last byte of a routine and the first three bytes of the table
    after it happens to spell 0xF67D6F.  `ret` has no operand.
    notes/prom_b_audit_callsites.py flags exactly that as `??`.

    ⚠ The decode here is done from the address itself with
    notes/prom_b_module_trace.decode_at, NOT by looking the address up in this
    file's own transcription.  The second draft did the latter and mis-called
    the real reader of StepRecordSub09_ButtonTable a coincidence, because that reader
    (`ld XIX,0x00f67de9` at 0xF67DDB) lives inside Data_F67D6F -- a run this
    block emits as `.byte` and therefore has no instruction line for.

    Returns (kind, detail); kind in {"operand", "entry", "straddle"}."""
    for kind, s, n in LAYOUT:
        if kind == "ptrtab" and s <= a < s + n and (a - s) % 4 == 0:
            return "entry", "DispatchTable_%06X[%d]" % (s, (a - s) // 4)
    want = int.from_bytes(at(a, 4), "little") & 0xFFFFFF
    for back in (1, 2, 3, 4):
        dec = MT.decode_at(a - back)
        if not dec:
            continue
        n, txt = dec
        if n > back and re.search(r"0x0*%06x" % want, txt):
            inside = ""
            for kind, s_, n_ in LAYOUT:
                if kind != "code" and s_ <= a - back < s_ + n_:
                    inside = " -- inside %s_%06X, a run this block emits as " \
                             "bytes, so it has no instruction line here" \
                             % (PREFIX[kind], s_)
            return "operand", "`%s` at 0x%06X (operand field %d byte%s in)%s" % (
                txt, a - back, back, "" if back == 1 else "s", inside)
    return "straddle", "0x%06X" % a


def reader_line(a_unused, addr=None):
    """A `Read by:` sentence that separates the three kinds of byte-scan hit."""
    if addr is None:
        addr = a_unused
    hits = direct_refs(addr)
    ops, ent, strad = [], [], []
    for h in hits:
        k, det = classify_ref(h)
        (ops if k == "operand" else ent if k == "entry" else strad).append(det)
    parts = []
    if ops:
        parts.append("%d instruction operand%s -- %s"
                     % (len(ops), "" if len(ops) == 1 else "s",
                        "; ".join(ops[:4]) + (" +%d more" % (len(ops) - 4)
                                              if len(ops) > 4 else "")))
    if ent:
        parts.append("%d dispatch-table entr%s (%s)"
                     % (len(ent), "y" if len(ent) == 1 else "ies",
                        " ".join(ent[:6]) + (" +%d more" % (len(ent) - 6)
                                             if len(ent) > 6 else "")))
    if strad:
        parts.append("%d byte-scan coincidence%s that straddle an object "
                     "boundary and are NOT references (%s)"
                     % (len(strad), "" if len(strad) == 1 else "s",
                        " ".join(strad[:4])))
    if not parts:
        return ("nothing in prom_a or prom_b spells this address as a 32-bit "
                "word, so whatever reaches it computes the address")
    return "%d byte-scan hit%s: %s" % (len(hits), "" if len(hits) == 1 else "s",
                                       "; ".join(parts))


def internal_calls():
    """{callee: [caller, ...]} from the PROVEN transcription's own comments."""
    out = {}
    for a, ln in code_lines():
        m = re.search(r";\s*[0-9A-F]{6}\s+(call|calr|jp)\s+(?:\w+,)?0x([0-9a-f]{6})", ln)
        if m:
            t = int(m.group(2), 16)
            if LO <= t < HI:
                out.setdefault(t, []).append(a)
    return out


# ------------------------------------------------------------------ the data
def seg_of(a):
    for kind, s, n in LAYOUT:
        if s <= a < s + n:
            return kind, s, n
    return None, None, None


def ident_subruns(s, n):
    """The maximal no-wrap identity runs inside one `ident` segment."""
    out, p = [], s
    d = rom("b")
    while p < s + n:
        q = p + 1
        while (q < s + n and d[p - B_BASE] + (q - p) <= 0xFF
               and d[q - B_BASE] == d[p - B_BASE] + (q - p)):
            q += 1
        out.append((p, q - p, d[p - B_BASE], d[q - 1 - B_BASE]))
        p = q
    return out


def labels():
    got = {}
    for t in thunks():
        got[t] = None
    for callee in internal_calls():
        got[callee] = None
    for kind, s, n in LAYOUT:
        if kind in DATA_KINDS:
            got[s] = None
    b = boundaries()
    data_starts = {s for k, s, _ in LAYOUT if k in DATA_KINDS}
    for a in list(got):
        if a not in b and a not in data_starts:
            del got[a]                      # not emittable: no line carries it
            continue
        got[a] = ("%s_%06X" % (PREFIX[seg_of(a)[0]], a)) if a in data_starts \
            else "sub_%06X" % a
    return got


# ------------------------------------------------------------------ headers
def wrap(prefix, text, width=76):
    body = textwrap.wrap(text, width - len(prefix)) or [""]
    return [prefix + body[0]] + ["; " + " " * (len(prefix) - 2) + x for x in body[1:]]


def touched(lo, hi):
    small, big = {}, {}
    for a, ln in code_lines():
        if not (lo <= a < hi):
            continue
        t = ln.split(";", 1)[1] if ";" in ln else ""
        for m in re.findall(r"\(0x([0-9a-f]{4})\)", t):
            small[int(m, 16)] = small.get(int(m, 16), 0) + 1
        for m in re.findall(r"0x00([0-9a-f]{6})", t):
            v = int(m, 16)
            if not (LO <= v < HI) and v >= 0x600000:
                big[v] = big.get(v, 0) + 1
    return small, big


def calls_out(lo, hi, lab):
    out = []
    for a, ln in code_lines():
        if not (lo <= a < hi):
            continue
        m = re.search(r";\s*[0-9A-F]{6}\s+(?:call|calr)\s+(?:\w+,)?0x([0-9a-f]{6})", ln)
        if m:
            t = int(m.group(1), 16)
            x = lab.get(t) or ("T_%06X" % t if 0xF40000 <= t < 0xF44018
                               else "0x%06X" % t)
            if x not in out:
                out.append(x)
    return out


def header(a, end, lab, th, sr, ic):
    L = ["; " + "-" * 74, "; %s" % lab[a]]
    parts = []
    if a in th:
        parts.append(", ".join("T_%06X (x%d)" % (s, sr.get(s, 0)) for s in th[a]))
    inb = ic.get(a, [])
    if inb:
        parts.append("in-module: " + " ".join("0x%06X" % x for x in inb[:8]) +
                     (" +%d more" % (len(inb) - 8) if len(inb) > 8 else ""))
    L += wrap("; Called from: ", "; ".join(parts) if parts else
              "no thunk slot and no in-module call or jp site -- reached only by "
              "a branch from the routine above, or by a computed transfer")
    sm, bg = touched(a, end)
    tt = " ".join("(0x%04X)" % x for x in sorted(sm)[:10]) + \
         (" +%d more" % (len(sm) - 10) if len(sm) > 10 else "")
    if bg:
        tt += "  |  " + " ".join("0x%06X" % x for x in sorted(bg)[:6]) + \
              (" +%d more" % (len(bg) - 6) if len(bg) > 6 else "")
    L += wrap("; Touches: ", tt or "nothing with an absolute address")
    co = calls_out(a, end, lab)
    if co:
        L += wrap("; Calls:   ", " ".join(co[:12]) +
                  (" +%d more" % (len(co) - 12) if len(co) > 12 else ""))
    if a in th:
        L += wrap("; Evidence: ", "thunk slot T_%06X holds `jp 0x00%06X`, and "
                  "0x%06X is an instruction boundary of this transcription "
                  "(re-asserted on every emit).  That is ALL the name rests on "
                  "-- the name IS the address." % (th[a][0], a, a))
    else:
        L += wrap("; Evidence: ", "reached by a `call`/`calr`/`jp` decoded in "
                  "this transcription (the sites are listed above), so 0x%06X is "
                  "an instruction boundary.  The name IS the address." % a)
    L += wrap("; Unknown: ", "what the routine is FOR.  Left as sub_XXXXXX with "
              "the gap stated, per this tree's rule that a stated gap beats a "
              "plausible guess.")
    L.append("; " + "-" * 74)
    return L


# --------------------------------------------------------------- data blocks
def byte_rows(a, n, per=16):
    out = []
    for off in range(0, n, per):
        k = min(per, n - off)
        out.append("\t.byte\t%s\t; %06X  [%d..%d]"
                   % (", ".join("0x%02X" % x for x in at(a + off, k)),
                      a + off, off, off + k - 1))
    return out


def ascii_of(a, n):
    return "".join(chr(x) if 32 <= x < 127 else "." for x in at(a, n))


def data_block(kind, s, n, lab):
    name = lab[s]
    rd = direct_refs(s)
    out = ["; " + "-" * 74]
    if kind == "ptrtab":
        ps = [w32(s + 4 * i) for i in range(n // 4)]
        nd = sorted(set(ps) - {STUB})
        nde = ps.count(DEFAULT_SLOT)
        out += wrap("; %s -- " % name,
                    "%d 32-bit pointers, every one of them an address in "
                    "0x00F60000-0x00F6FFFF.  %d of the %d entries are the "
                    "module's own do-nothing stub 0x%06X (a single 0x0E byte, "
                    "`ret`), leaving %d distinct other target%s%s."
                    % (n // 4, ps.count(STUB), n // 4, STUB, len(nd),
                       "" if len(nd) == 1 else "s",
                       "" if not nde else
                       "; %d entries are the image-wide default thunk slot "
                       "0x%08X" % (nde, DEFAULT_SLOT)))
        out += wrap("; Read by: ", reader_line(s))
        out += wrap("; Entry count: ",
                    "%d, and it is NOT a byte extent divided by four.  The chain "
                    "rule that finds it (notes/prom_b_f65000_layout.py, PTRTAB) "
                    "stops at the first word that is not a 0x00F6xxxx address; "
                    "0x%06X is that word's address and it is the first byte of "
                    "%s.  Entry %d, the last, is 0x%08X."
                    % (n // 4, s + n,
                       "the next segment", n // 4 - 1, ps[-1]))
        out += wrap("; Evidence: ",
                    "every one of the %d words is re-read on every emit and "
                    "asserted to lie in 0x00F60000-0x00F6FFFF; the rule that "
                    "framed the table fires ZERO times over the 54,814 bytes of "
                    "already-proven prom_b instruction text "
                    "(`python3 notes/prom_b_f65000_layout.py --null`)." % (n // 4))
        out += wrap("; Unknown: ", "what indexes it, and what the handlers do.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        for i, p in enumerate(ps):
            tag = lab.get(p) or ("0x%06X" % p)
            if p == STUB:
                tag = "ret stub"
            out.append("\t.long\t0x00%06X\t; %06X  [%d] -> %s"
                       % (p, s + 4 * i, i, tag))
        return out
    if kind == "ramtab":
        vs = [w32(s + 4 * i) for i in range(n // 4)]
        dif = sorted(set(vs[i + 1] - vs[i] for i in range(len(vs) - 1)))
        out += wrap("; %s -- " % name,
                    "%d 32-bit words, every one of them below 0x10000, i.e. a "
                    "16-bit RAM address stored one per long word.  First 0x%04X, "
                    "last 0x%04X; the step between neighbours takes %d distinct "
                    "value%s (%s)."
                    % (n // 4, vs[0], vs[-1], len(dif), "" if len(dif) == 1 else "s",
                       " ".join("0x%X" % x for x in dif)))
        out += wrap("; Read by: ", reader_line(s))
        out += wrap("; Entry count: ",
                    "%d.  The chain stops at the first word that is not below "
                    "0x10000, at 0x%06X." % (n // 4, s + n))
        out += wrap("; Evidence: ",
                    "every word is re-read and range-asserted on every emit.  "
                    "The RAMTAB rule fires ZERO times over the 54,814 bytes of "
                    "proven prom_b instruction text.")
        out += wrap("; Unknown: ", "what lives at those RAM addresses.  The name "
                    "describes the CONTENT of the table, not its purpose.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        for i, v in enumerate(vs):
            out.append("\t.long\t0x%08X\t; %06X  [%d] -> RAM 0x%04X"
                       % (v, s + 4 * i, i, v))
        return out
    if kind == "bittab":
        vs = [w32(s + 4 * i) for i in range(n // 4)]
        out += wrap("; %s -- " % name,
                    "%d 32-bit words, entry k = 1 << k: 0x%08X, 0x%08X ... "
                    "0x%08X.  Content-descriptive name, asserted word for word "
                    "on every emit." % (n // 4, vs[0], vs[1], vs[-1]))
        out += wrap("; Read by: ", reader_line(s))
        out += wrap("; Entry count: ",
                    "%d, which is every bit of a 32-bit word with nothing left "
                    "over: a 33rd entry would need 1 << 32." % (n // 4))
        out += wrap("; Evidence: ", "each word is compared with 1 << k on every "
                    "emit; a wrong entry stops the emit.")
        out += wrap("; Unknown: ", "which 32 flags the weights index.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        for i, v in enumerate(vs):
            out.append("\t.long\t0x%08X\t; %06X  [%d] = 1 << %d" % (v, s + 4 * i, i, i))
        return out
    if kind == "ident":
        subs = ident_subruns(s, n)
        out += wrap("; %s -- " % name,
                    "%s.  The name describes the CONTENT and claims nothing about "
                    "the purpose."
                    % "; ".join("%d bytes at 0x%06X counting 0x%02X..0x%02X"
                                % (ln, a, v0, v1) for a, ln, v0, v1 in subs))
        out += wrap("; Read by: ", reader_line(s))
        left = ("the run starts at 0x00 and the rule does not wrap, so it "
                "cannot extend left at all" if subs[0][2] == 0 else
                "the byte before 0x%06X is 0x%02X, not the 0x%02X that would "
                "extend it" % (s, at(s - 1, 1)[0], subs[0][2] - 1))
        right = ("the run ends at 0xFF" if subs[-1][3] == 0xFF else
                 "the byte at 0x%06X is 0x%02X, not the 0x%02X that would "
                 "extend it" % (s + n, at(s + n, 1)[0], subs[-1][3] + 1))
        out += wrap("; Entry count: ",
                    "%d byte%s.  The run is maximal: %s, and %s."
                    % (n, "" if n == 1 else "s", left, right))
        out += wrap("; Evidence: ",
                    "every byte is compared with its predecessor + 1 on every "
                    "emit.  The IDENT rule (no wraparound past 0xFF) fires ZERO "
                    "times over the 54,814 bytes of proven prom_b instruction "
                    "text; ⚠ WITH wraparound allowed it eats the 0xFF that ends "
                    "the `jrl` at 0xF6A9A7, which is why the no-wrap clause is "
                    "in the rule.")
        out += wrap("; Unknown: ", "why an index map that returns its own index "
                    "exists at all.  prom_b now has several; that is recorded, "
                    "not explained.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        out += byte_rows(s, n)
        return out
    if kind == "ascii":
        out += wrap("; %s -- " % name,
                    "%d ASCII bytes: '%s'." % (n, ascii_of(s, n)))
        out += wrap("; Read by: ", reader_line(s))
        out += wrap("; Entry count: ",
                    "%d bytes; the byte before is 0x%02X and the byte after is "
                    "0x%02X, neither printable, so the run is maximal."
                    % (n, at(s - 1, 1)[0], at(s + n, 1)[0]))
        out += wrap("; Evidence: ", "the text is re-read and compared on every "
                    "emit.  The ASCII rule at its 20-byte threshold fires ZERO "
                    "times over 54,814 bytes of proven prom_b instruction text; "
                    "at 10 it fires 3 times and at 8, seven.")
        out += wrap("; Unknown: ", "which screen draws it.  The four colon-"
                    "separated fields are 10 characters each, which is a column "
                    "layout, but no interpreter here is decoded.")
        out.append("; " + "-" * 74)
        out.append("%s:" % name)
        out.append('\t.ascii\t"%s"\t; %06X  %d bytes' % (ascii_of(s, n), s, n))
        return out
    # plain data
    clean = LY.selfconsistent(rom("b"), s, s + n, set())[0]
    out += wrap("; %s -- " % name,
                "%d byte%s this block could not split.  It is neither a pointer "
                "table, a RAM-pointer table, a bit-weight table, an index map "
                "nor a 20-byte string, and the code walk never reached it, so it "
                "is emitted as bytes rather than guessed."
                % (n, "" if n == 1 else "s"))
    if clean:
        out += wrap("; \u26a0 ",
                    "these bytes DO decode cleanly as instructions, and round 4 "
                    "of this lane emitted them as instructions for that reason.  "
                    "The decode does not end in a `ret`/`reti`/unconditional "
                    "transfer, and the rule that ignores that -- round 4's "
                    "selfconsistent() -- accepts 13.9% of record-aligned chunks "
                    "of PROVEN display-list data as code "
                    "(`python3 notes/prom_b_f0ea9f_layout.py --null-accept`).  "
                    "Adding the tail requirement takes that to 1 of 1,884.  So "
                    "this run is data until something reaches it.")
    if any(32 <= c < 127 for c in at(s, n)):
        out += wrap("; Contains: ", "printable text |%s|" % ascii_of(s, n))
    out += wrap("; Read by: ", reader_line(s))
    out += wrap("; Evidence: ", "the bytes are re-read on every emit; the "
                "classification is NEGATIVE (no rule matched) and is stated as "
                "such.")
    out += wrap("; Unknown: ", "everything about it except its bytes.")
    out.append("; " + "-" * 74)
    out.append("%s:" % lab[s])
    out += byte_rows(s, n)
    return out


# ------------------------------------------------------------------- checks
FAIL = []


def c(name, got, want, verbose=True):
    ok = got == want
    if not ok:
        FAIL.append((name, got, want))
    if verbose:
        print("  %-72s %s" % (name, "PASS" if ok else "FAIL got=%r want=%r"
                              % (got, want)))
    return ok


def checks(verbose=True):
    del FAIL[:]
    d = rom("b")
    # 1. the LAYOUT literal must equal what the layout script derives, segment
    #    for segment.  This is the one check that matters most: it means the
    #    table below is a RECORD of a measurement, not a typed guess.
    segs, conflicts, pend, ok, seen = LY.build()
    c("LAYOUT equals notes/prom_b_f65000_layout.py's derivation", segs, LAYOUT, verbose)
    c("  the layout's barrier rules reclaim no descent byte", len(conflicts), 0, verbose)
    c("  LAYOUT is contiguous and covers 0x%06X-0x%06X" % (LO, HI),
      [(LAYOUT[0][1], sum(n for _, _, n in LAYOUT))], [(LO, HI - LO)], verbose)
    # 2. every `fill` run is pure 0x0E
    for kind, s, n in LAYOUT:
        if kind == "fill":
            c("  fill 0x%06X..0x%06X is pure 0x0E" % (s, s + n - 1),
              sorted(set(at(s, n))), [0x0E], verbose)
    # 3. the four thunk runs this block retires
    th = thunks()
    c("thunk slots of 0xF40000 landing in this block",
      sum(len(v) for v in th.values()), 69, verbose)
    for run, lo_, hi_ in (("T_F432C0-T_F432CC", 0xF432C0, 0xF432CC),
                          ("T_F42B70-T_F42C2C", 0xF42B70, 0xF42C2C),
                          ("T_F42EC0-T_F42EC8", 0xF42EC0, 0xF42EC8),
                          ("T_F42ED0-T_F42F04", 0xF42ED0, 0xF42F04)):
        tg = [w32(x) >> 8 for x in range(lo_, hi_ + 4, 4)]   # `1B lo mid hi`
        c("  every target of %s is inside this block" % run,
          [t for t in tg if not (LO <= t < HI)], [], verbose)
    # 4. the data objects, re-read
    for kind, s, n in LAYOUT:
        if kind == "ptrtab":
            c("  ptrtab 0x%06X: all %d words are 0x00F6xxxx" % (s, n // 4),
              [i for i in range(n // 4)
               if not (0x00F60000 <= w32(s + 4 * i) < 0x00F70000)], [], verbose)
        if kind == "ptrtab":
            ps = [w32(s + 4 * i) for i in range(n // 4)]
            c("  ptrtab 0x%06X: stub count + non-stub entries == %d"
              % (s, n // 4),
              ps.count(STUB) + sum(1 for x in ps if x != STUB), n // 4, verbose)
        if kind == "ramtab":
            c("  ramtab 0x%06X: all %d words are below 0x10000" % (s, n // 4),
              [i for i in range(n // 4) if not (0 < w32(s + 4 * i) < 0x10000)],
              [], verbose)
        if kind == "bittab":
            c("  bittab 0x%06X: entry k == 1 << k, %d entries" % (s, n // 4),
              [i for i in range(n // 4) if w32(s + 4 * i) != 1 << i], [], verbose)
        if kind == "ident":
            bad = []
            for a, ln, v0, v1 in ident_subruns(s, n):
                if [at(a + k, 1)[0] for k in range(ln)] != list(range(v0, v0 + ln)):
                    bad.append(hex(a))
            c("  ident 0x%06X: every sub-run counts up by one" % s, bad, [], verbose)
        if kind == "ascii":
            c("  ascii 0x%06X: every byte printable, neighbours are not" % s,
              (all(32 <= x < 127 for x in at(s, n)),
               32 <= at(s - 1, 1)[0] < 127, 32 <= at(s + n, 1)[0] < 127),
              (True, False, False), verbose)
    c("the module stub 0x%06X is one byte and it is `ret` (0x0E)" % STUB,
      (at(STUB, 1)[0], at(STUB - 1, 1)[0] == 0x0E), (0x0E, False), verbose)
    # 5. label hygiene
    lab, b = labels(), boundaries()
    data_starts = {s for k, s, _ in LAYOUT if k in DATA_KINDS}
    c("every data segment start has a label",
      sorted("0x%06X" % x for x in data_starts if x not in lab), [], verbose)
    c("every non-data label is an instruction boundary",
      sorted("0x%06X" % x for x in lab if x not in data_starts and x not in b),
      [], verbose)
    c("no label falls inside a fill segment",
      sorted("0x%06X" % a for a in lab
             if any(k == "fill" and s <= a < s + n for k, s, n in LAYOUT)),
      [], verbose)
    # 6. every code segment's transcription starts and ends where LAYOUT says
    for kind, s, n in LAYOUT:
        if kind == "code":
            ls = [a for a, _ in code_lines() if s <= a < s + n]
            c("  code 0x%06X..0x%06X transcribed, %d lines, first==start"
              % (s, s + n - 1, len(ls)), (min(ls), len(transcribe(s, n))),
              (s, len(ls)), verbose)
    if verbose:
        print("\n%s (%d failed)" % ("CHECKS PASS" if not FAIL else "CHECKS FAIL",
                                    len(FAIL)))
    return not FAIL


def counts():
    """Every number the banner quotes, computed from LAYOUT and the ROM."""
    k = {}
    for kind, _, n in LAYOUT:
        k[kind] = k.get(kind, 0) + 1
    b = {}
    for kind, _, n in LAYOUT:
        b[kind] = b.get(kind, 0) + n
    d = rom("b")
    left_slots = {}
    for o in range(TBL_LO, TBL_HI, 4):
        if d[o] == 0x1B:
            t = d[o + 1] | d[o + 2] << 8 | d[o + 3] << 16
            if HI <= t < 0xF78000:
                left_slots.setdefault(t, []).append(B_BASE + o)
    # screen-text density of the range this block stops short of
    txt, p = [], HI
    while p < 0xF6F000:
        if 32 <= d[p - B_BASE] < 127:
            q = p
            while q < 0xF6F000 and 32 <= d[q - B_BASE] < 127:
                q += 1
            if q - p >= 10:
                txt.append((p, q - p))
            p = q
        else:
            p += 1
    return k, b, left_slots, txt


def banner():
    k, b, left, txt = counts()
    sm, bg = touched(LO, HI)
    top_small = sorted(sm.items(), key=lambda x: -x[1])[:5]
    top_big = sorted(bg.items(), key=lambda x: -x[1])[:5]
    nslots = sum(len(v) for v in thunks().values())
    wb, nbar, ov = LY.barrier_effect()
    return """
; ==============================================================================
; 0xF65000-0xF6D001 -- THREE MODULES AT THE HEAD OF THE 0x065000 `.incbin` SPAN
;   %d thunk slots -- the top FOUR runs of notes/prom_b_module_frontier.py --
;   converted as one contiguous block
; ==============================================================================
;
; WHY THIS BLOCK.  notes/prom_b_module_frontier.py ranks whole thunk RUNS by the
; CONTIGUOUS unconverted extent of their targets, and its top four runs all point
; into this one `.incbin` span:
;
;   T_F42ED0-T_F42F04  14 slots  extent 20,977  targets 0xF67434-0xF6C625
;   T_F42EC0-T_F42EC8   3 slots  extent 14,463  targets 0xF675CC-0xF6AE4B
;   T_F42B70-T_F42C2C  48 slots  extent  2,648  targets 0xF65C00-0xF66658
;   T_F432C0-T_F432CC   4 slots  extent      9  targets 0xF65000-0xF65009
;
; %d slots.  Every target of all four is inside 0xF65000-0xF6D001, which is what
; checks() asserts run by run, so this one span retires all four.
; notes/prom_b_f65000_frontier_delta.py re-derives the before/after from the ROM
; and from this file.
;
; @@ WHERE THE BOUNDARIES COME FROM.  Not from a linear decode -- see
; notes/prom_a_linear_decode_check.py for why one pins nothing.  Five CONTENT
; rules run FIRST and become barriers the code walk may not enter, then a
; recursive descent seeded from the thunk targets and from every opcode-anchored
; `call`/`jp` site in prom_a+prom_b fills in the rest:
;
;   PTRTAB  >= 3 consecutive 4-byte LE words, all in 0x00F60000-0x00F6FFFF
;   RAMTAB  >= 4 consecutive 4-byte LE words, all below 0x10000
;   BITTAB  >= 8 consecutive 4-byte LE words with w[k] == w[0] << k
;   IDENT   >= 12 bytes counting up by one WITHOUT wrapping past 0xFF
;   ASCII   >= 20 consecutive bytes in 0x20-0x7E
;
; Each was calibrated against every maximal run of PROVEN instruction text
; already in this file -- 2,948 runs, 54,814 bytes AT COMMIT 2707125, which is
; the revision to quote because that corpus grows every time a round converts
; anything -- and each fires ZERO times there
; (`python3 notes/prom_b_f65000_layout.py --null --rev 2707125`).  @@ The ASCII threshold
; is TWENTY because at ten the same corpus yields three false positives and at
; eight, seven.  The cost is real and is not hidden: the 9-byte string
; `VOLUME = ` at 0xF67DC6 is NOT promoted; it sits inside the %s segment that
; starts at 0x%06X and comes out as `db` bytes.
;
; @@ CORRECTED 2026-08-25 (round 5): A SIXTH RULE, AND IT DEMOTED FOUR RUNS.
; An unreached run whose linear decode consumes it exactly, holds no undefined
; opcode and lands every relative branch on a boundary was accepted as CODE.
; That rule was calibrated only against pointer tables, strings and 0x0E padding.
; Measured against proven DATA it had never seen -- the 4,011 display-list
; records of notes/FINDINGS-ui-display-list.md, 39,329 bytes whose framing is
; self-checking -- it accepts 13.9%% of record-aligned 16-byte chunks as code.
; Requiring the decode to END IN A FLOW END (`ret`, `reti`, an unconditional
; `jp`/`jr`) takes that to 1 of 1,884 chunks, and to ZERO at 32 bytes and above:
;     python3 notes/prom_b_f0ea9f_layout.py --null-accept
; Four runs of this block failed the new rule and are now `.byte` with the reason
; in their headers: 0xF65DCC (6), 0xF65DF1 (6), 0xF6A475 (40) and 0xF6B006 (24).
; 0xF6A475 is the one that matters -- 40 bytes reading
; `10 ff 11 19 1a 17 ff 12 13 14 15 16 ff 18 ff ...`, a lookup table over the
; same 0x00-0x1F alphabet as IndexMap_F6A455 immediately above it, which round 4
; printed as `rcf / swi 7 / scf / pop F / jp 0xff17 / ...`.
;
; @@ AND THE BARRIER IS NOT COSMETIC.  Two of the descent's four seed sources are
; ADDRESSES THE FIRMWARE STORES rather than jumps it makes -- the 32-bit
; immediates an instruction loads, and every in-range entry of every table the
; PTRTAB rule frames.  Together they are what makes the walk reach most of the
; block (`python3 notes/prom_b_f65000_layout.py --seeds` prices the table
; entries; without them the 122-byte handler at 0xF67D6F -- entry [8] of FIVE
; dispatch tables -- came out as `.byte`).  But a stored address is as often a
; DATA address.  Measured on
; this exact range
; (`python3 notes/prom_b_f65000_layout.py --barrier`): with the barrier the walk
; claims %d bytes; without it, %d, of which %d fall inside an object a content
; rule framed -- whole 32-entry pointer tables at 0xF6828B and 0xF685C1 among
; them.  `--conflicts` is the count that caught it and checks() asserts it is
; zero.
;
; LAYOUT.  %d segments: %d code (%d bytes), %d dispatch tables (%d bytes),
; %d RAM-pointer tables (%d bytes), %d bit-weight table (%d bytes), %d index maps
; (%d bytes), %d string (%d bytes), %d unsplit `.byte` runs (%d bytes) and
; %d runs of 0x0E `ret` padding (%d bytes).  Substantive: %d of %d.
;
; WHAT THE BLOCK TOUCHES, measured over the transcription itself.  Heaviest
; absolute operands: %s.
; Heaviest 16-bit RAM words: %s.
; 0x603400-0x6034FF and 0x610000 are the SONG STORE's bank workspace and
; directory (notes/FINDINGS-prom_b-song-store.md, notes/FINDINGS-memory-map.md);
; (0x2075) is the UI redraw-request byte of notes/FINDINGS-prom_b-field-blink.md.
; That is a measurement of what the code ADDRESSES, not a claim about what the
; block IS, and no routine here is given a semantic name on the strength of it.
;
; @@ WHAT IS NOT ESTABLISHED.  What any of the three modules is FOR.  Every
; routine is `sub_XXXXXX` with a computed header claiming only its entry point,
; what it touches and what it calls.
;
; @@ WHAT IS LEFT.  0xF6D002-0xF77FFF stays `.incbin`.  0xF6D002-0xF6EFFF is the
; screen-TEXT block -- %d runs of %d or more printable bytes in %d bytes,
; interleaved with code the descent enters THROUGH them -- and splitting text
; from code there needs an ASCII rule with a null this round does not have (at
; 20 bytes the rule misses most of those runs; at 10 it has three false
; positives).  Above that, only %d thunk slot(s) point anywhere into
; 0xF6D002-0xF77FFF at all%s, so a split there would rest on a linear decode.
;
; REGENERATE:  python3 notes/gen_prom_b_f65000_module.py
; CHECKS:      python3 notes/gen_prom_b_f65000_module.py --checks
; AUDIT:       python3 notes/prom_b_f65000_header_audit.py
; ==============================================================================
""" % (nslots, nslots, seg_of(0xF67DC6)[0], seg_of(0xF67DC6)[1],
       wb, nbar, ov,
       len(LAYOUT), k.get("code", 0), b.get("code", 0),
       k.get("ptrtab", 0), b.get("ptrtab", 0),
       k.get("ramtab", 0), b.get("ramtab", 0),
       k.get("bittab", 0), b.get("bittab", 0),
       k.get("ident", 0), b.get("ident", 0),
       k.get("ascii", 0), b.get("ascii", 0),
       k.get("data", 0), b.get("data", 0),
       k.get("fill", 0), b.get("fill", 0),
       sum(v for kk, v in b.items() if kk != "fill"), HI - LO,
       " ".join("0x%06X (x%d)" % t for t in top_big),
       " ".join("(0x%04X) (x%d)" % t for t in top_small),
       len(txt), 10, 0xF6F000 - HI,
       sum(len(v) for v in left.values()),
       (" -- " + ", ".join("T_%06X -> 0x%06X" % (v[0], t)
                           for t, v in sorted(left.items()))) if left else "")


def emit():
    lab, th, sr, ic = labels(), thunks(), slot_refs(), internal_calls()
    keys = sorted(lab)
    ends = {a: (keys[i + 1] if i + 1 < len(keys) else HI) for i, a in enumerate(keys)}
    out = banner().replace("@@", "\u26a0").strip("\n").split("\n")
    out.append("")
    for kind, s, n in LAYOUT:
        if kind == "fill":
            out += ["\t.fill\t%d, 1, 0x0E\t; %06X-%06X  `ret` padding (asserted "
                    "pure 0x0E)" % (n, s, s + n - 1), ""]
            continue
        if kind in DATA_KINDS:
            out += [""] + data_block(kind, s, n, lab) + [""]
            continue
        for a, ln in [(a, l) for a, l in code_lines() if s <= a < s + n]:
            if a in lab:
                out += [""] + header(a, ends[a], lab, th, sr, ic)
                tag = "\t\t; <- %s" % ", ".join("T_%06X" % x for x in th[a]) \
                      if a in th else ""
                out.append("%s:%s" % (lab[a], tag))
            out.append(ln)
    return out


def main():
    if "--checks" in sys.argv:
        return 0 if checks() else 1
    if "--layout" in sys.argv:
        tot = {}
        for kind, s, n in LAYOUT:
            print("  %-6s 0x%06X-0x%06X  %6d" % (kind, s, s + n - 1, n))
            tot[kind] = tot.get(kind, 0) + n
        print("  ---- " + "  ".join("%s %d" % (k, v) for k, v in sorted(tot.items())))
        print("  substantive %d of %d"
              % (sum(v for k, v in tot.items() if k != "fill"), HI - LO))
        return 0
    if "--stats" in sys.argv:
        import collections
        vals = []
        for kind, s_, n in LAYOUT:
            if kind == "ptrtab":
                vals += [w32(s_ + 4 * i) for i in range(n // 4)]
        c = collections.Counter(vals)
        print("dispatch tables: %d, entries: %d"
              % (sum(1 for k, _, _ in LAYOUT if k == "ptrtab"), len(vals)))
        print("  the module stub 0x%06X: %d entries (%.1f%%)"
              % (STUB, c[STUB], 100.0 * c[STUB] / len(vals)))
        print("  distinct targets: %d" % len(c))
        print("  the IMAGE-WIDE default thunk slot 0x%08X: %d entries"
              % (DEFAULT_SLOT, c[DEFAULT_SLOT]))
        print("  most-referenced: %s"
              % " ".join("0x%06X x%d" % t for t in c.most_common(6)))
        return 0
    if "--tables" in sys.argv:
        lab = labels()
        for kind, s, n in LAYOUT:
            if kind in DATA_KINDS:
                print("  %-8s %-22s 0x%06X  %5d bytes  refs %d"
                      % (kind, lab[s], s, n, len(direct_refs(s))))
        return 0
    if not checks(verbose=False):
        checks()
        raise SystemExit("refusing to emit: a check failed (see above)")
    print("\n".join(emit()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
