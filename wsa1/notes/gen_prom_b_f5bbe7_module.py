#!/usr/bin/env python3
"""Emit the assembly for prom_b 0xF5BBE7-0xF62BFF -- the whole remaining
`.incbin` span between the two selector dispatchers and the block store.

QUESTION IT ANSWERS
    "What is the assembly text for the thunk-table run T_F426E0-T_F42720 and the
     code that shares its `.incbin` span, in a form the byte gate accepts, with
     every label and header attached to the right address?"
    This is the emitter whose output is pasted into prom_b/wsa1_prom_b.s.

WHY THIS BLOCK
    notes/prom_b_module_frontier.py ranks thunk runs by CONTIGUOUS unconverted
    target extent.  T_F426E0-T_F42720 is 17 slots, 16,244 bytes of extent, all
    inside ONE `.incbin` span, with the highest summed reference upper bound of
    any run in the image (62) -- and it owns 0xF5EBD0, which
    notes/prom_b_call_graph.py ranks the SECOND most-referenced unconverted
    target in prom_b (x25, through T_BStore_ReadCursorAdvance_Call).

    The span it sits in is 0xF5BBE7-0xF62BFF, and those 17 slots are the ONLY
    thunk slots that point anywhere into it, so the run and the span are the same
    module boundary seen twice.  Converting the whole span closes it.

WHERE THE EXTENT COMES FROM, AND WHY THE START IS PINNED
    ⚠ notes/prom_a_linear_decode_check.py's warning applies here: a linear decode
    resynchronises, so "it decodes cleanly" does NOT pin where a span begins.
    What pins this one is the converted code above it -- prom_b/wsa1_prom_b.s
    already transcribes through 0xF5BBE6, and that byte is a `ret`.  0xF5BBE7 is
    the next byte after a proven instruction, not a guess.
    The end is the `.incbin`'s own end, 0xF62C00, where the block store starts.

HOW THE CODE/DATA SPLIT WAS MADE
    * notes/prom_b_module_trace.py 0xF5BBE7 0xF62C00 does a recursive descent
      from the span's own thunk entry points and reports the runs it never
      reaches.  17 runs came back.
    * Every one was read.  Eleven are ordinary code the descent could not reach
      (arms of `jr` ladders, and the 0x0E `ret` bytes between routines).  Two are
      `ret` padding.  FOUR are data, and each one's END is pinned by a real
      transfer decoded in this transcription, never by where the decode happens
      to resynchronise:
        0xF5D802 RoundMap_96..RoundMap_8   ends at 0xF5DAA2 = thunk target T_Quantize_Execute
        0xF5DBB4 RoundMap_Table            ends at 0xF5DBD0 = `jr T` at 0xF5DBB2
        0xF5EE75 IdentityMap_0_31          ends at 0xF5EE95 = `calr` x2 (0xF5ED63, 0xF5F373)
        0xF621B9 RoundMap_Bounds_A/_B      ends at 0xF62201 = `calr` at 0xF621AE
    * Asserted on every emit: all 17 thunk targets land on an instruction
      boundary of the transcription.  A data island mistaken for code
      resynchronises silently; a thunk target off a boundary is one symptom.
      ⚠ IT IS NOT SUFFICIENT ON ITS OWN, and the probe that shows this is in
      notes/FINDINGS-prom_b-round-maps.md: growing an island by one byte, so the
      code segment after it starts one byte LATE, leaves all 17 thunk targets on
      boundaries -- the decode resynchronises.  What caught it was the LABEL
      checks (every FORCE label, every data label and every in-module `call`
      target must be an emittable instruction boundary, and no code label may
      fall inside a data segment).  The two together are the split's proof.
    * Code runs go through notes/llvm_roundtrip_autoforce.py, which assembles the
      candidate listing and compares it byte for byte with the ROM before
      printing.  Both `.fill` runs are re-asserted to be pure 0x0E.

RUN
    python3 notes/gen_prom_b_f5bbe7_module.py            # the assembly
    python3 notes/gen_prom_b_f5bbe7_module.py --layout   # the segment table
    python3 notes/gen_prom_b_f5bbe7_module.py --checks    # the assertions only
    python3 notes/gen_prom_b_f5bbe7_module.py --maps      # the round-map census
"""
import os
import re
import subprocess
import sys
import textwrap

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUTOFORCE = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")
IMGB = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
IMGA = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
B_BASE, A_BASE = 0xF00000, 0xF80000
LO, HI = 0xF5BBE7, 0xF62C00
TBL_LO, TBL_HI = 0x40000, 0x44018

# (kind, start, length).  Contiguity, the 0xF62C00 end and the purity of both
# `fill` runs are asserted in checks() -- this table is never trusted as typed.
LAYOUT = [
    ("code", 0xF5BBE7, 0x1C08),
    ("fill", 0xF5D7EF, 0x013),
    ("data", 0xF5D802, 0x2A0),
    ("code", 0xF5DAA2, 0x112),
    ("data", 0xF5DBB4, 0x01C),
    ("code", 0xF5DBD0, 0x12A5),
    ("data", 0xF5EE75, 0x020),
    ("code", 0xF5EE95, 0x3324),
    ("data", 0xF621B9, 0x048),
    ("code", 0xF62201, 0x0D5),
    ("fill", 0xF622D6, 0x92A),
]

# The seven round-maps, in the order RoundMap_Table names them.  The GRID of
# each is DERIVED in grids() from the table's own distinct values, never typed;
# the addresses come from RoundMap_Table, also read from the ROM.
MAPS_AT = 0xF5D802
MAPS_TABLE = 0xF5DBB4
MAPS_END = 0xF5DAA2
BOUNDS = 0xF621B9

_cache = {}


def rom(which="b"):
    if which not in _cache:
        _cache[which] = open(IMGA if which == "a" else IMGB, "rb").read()
    return _cache[which]


def at(addr, n=1):
    return rom("b")[addr - B_BASE: addr - B_BASE + n]


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


def transcribe_pairs(s, n):
    for ln in transcribe(s, n):
        m = re.search(r";\s*([0-9A-F]{6})\s", ln)
        yield int(m.group(1), 16), ln


def code_lines():
    out = []
    for kind, s, n in LAYOUT:
        if kind != "code":
            continue
        out += list(transcribe_pairs(s, n))
    return out


def text_at(a):
    for ad, ln in code_lines():
        if ad == a:
            return ln.split(";", 1)[1].strip().split("  ", 1)[-1].strip()
    return ""


def boundaries():
    return {a for a, _ in code_lines()}


def thunks():
    """{target: [slot, ...]} for `jp nnn` slots landing in this range."""
    d, out = rom("b"), {}
    for o in range(TBL_LO, TBL_HI, 4):
        s = d[o:o + 4]
        if s[0] == 0x1B:
            t = s[1] | s[2] << 8 | s[3] << 16
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
    """Every byte offset in prom_a+prom_b that spells `addr` as a 32-bit LE word.
    An UPPER BOUND -- the scan is at every byte, not at instruction boundaries."""
    tgt = addr.to_bytes(4, "little")
    out = []
    for nm, blob, base in (("prom_a", rom("a"), A_BASE), ("prom_b", rom("b"), B_BASE)):
        i = 0
        while True:
            i = blob.find(tgt, i)
            if i < 0:
                break
            out.append(base + i)
            i += 1
    return out


def internal_calls():
    """{callee: [caller, ...]} from the PROVEN transcription's own comments.
    Exact, not a byte window: every entry comes off a decoded instruction."""
    out = {}
    for a, ln in code_lines():
        m = re.search(r";\s*[0-9A-F]{6}\s+(call|calr)\s+(?:\w+,)?0x([0-9a-f]{6})", ln)
        if m:
            out.setdefault(int(m.group(2), 16), []).append(a)
    return out


# ---------------------------------------------------------------- round maps
def map_ptrs():
    """The seven map addresses, read out of RoundMap_Table."""
    return [int.from_bytes(at(MAPS_TABLE + 4 * i, 4), "little")
            for i in range(map_count())]


def map_count():
    """How many entries RoundMap_Table has.  NOT the byte extent divided by 4 as
    an assumption: the `jr T,0xF5DBD0` at 0xF5DBB2 jumps OVER the table, so the
    distance from the table to that target IS its length, and 28/4 = 7."""
    m = re.match(r"jr T,0x([0-9a-f]{6})$", text_at(0xF5DBB2))
    assert m, "0xF5DBB2 is not the `jr T` that steps over the table"
    end = int(m.group(1), 16)
    assert (end - MAPS_TABLE) % 4 == 0
    return (end - MAPS_TABLE) // 4


def grids():
    """(address, grid, entries) per map.  The grid is the spacing of the map's own
    distinct values below 127 -- derived, not typed."""
    out = []
    for p in map_ptrs():
        t = list(at(p, 96))
        vals = sorted(set(t) - {0x7F})
        out.append((p, (vals[1] - vals[0]) if len(vals) > 1 else 96, t))
    return out


def ideal(g):
    """Round-to-nearest on a 96-step index, with the out-of-range top step
    written as 0x7F instead of 96."""
    return [0x7F if g * ((k + g // 2) // g) >= 96 else g * ((k + g // 2) // g)
            for k in range(96)]


def bound_groups():
    """The half-grid boundary list of each map, in RoundMap_Table order."""
    return [[g // 2 + k * g for k in range(96 // g) if g // 2 + k * g < 96]
            for _, g, _ in grids()]


def rot1(xs):
    return xs[-1:] + xs[:-1]


# ------------------------------------------------------------------- labels
DATA_LABEL = {
    0xF5D802: "RoundMap_96",
    0xF5D862: "RoundMap_48",
    0xF5D8C2: "RoundMap_24",
    0xF5D922: "RoundMap_12",
    0xF5D982: "RoundMap_32",
    0xF5D9E2: "RoundMap_16",
    0xF5DA42: "RoundMap_8",
    0xF5DBB4: "RoundMap_Table",
    0xF5EE75: "IdentityMap_0_31",
    0xF621B9: "RoundMap_Bounds_A",
    0xF621DD: "RoundMap_Bounds_B",
}

NAMES = {}

# Addresses that are neither a thunk target nor a call target but do start a
# routine.  Each one needs its own reason, stated here and re-checked in
# checks(): nothing may be forced into the label set on taste alone.
FORCE = {
    0xF5DBD0: "target of `jr T,0xF5DBD0` at 0xF5DBB2, the jump that steps over "
              "the 28 bytes of RoundMap_Table",
    0xF5EE95: "target of `calr 0xF5EE95` at 0xF5ED63 and at 0xF5F373, the two "
              "calls that step past the 32 bytes of IdentityMap_0_31",
    0xF62201: "target of `calr 0xF62201` at 0xF621AE, the call that steps past "
              "the 72 bytes of RoundMap_Bounds_A and _B",
}


def labels():
    got = {}
    for t in thunks():
        got[t] = None
    for callee in internal_calls():
        if LO <= callee < HI:
            got[callee] = None
    got.update({a: None for a in DATA_LABEL})
    got.update({a: None for a in FORCE})
    for a in got:
        got[a] = NAMES.get(a) or DATA_LABEL.get(a) or "sub_%06X" % a
    return got


# ------------------------------------------------------------------ headers
def wrap(prefix, text, width=76):
    body = textwrap.wrap(text, width - len(prefix))
    return [prefix + body[0]] + ["; " + " " * (len(prefix) - 2) + x for x in body[1:]]


def touched(lo, hi):
    small, big = set(), set()
    for a, ln in code_lines():
        if not (lo <= a < hi):
            continue
        t = ln.split(";", 1)[1] if ";" in ln else ""
        for m in re.findall(r"\(0x([0-9a-f]{4})\)", t):
            small.add(int(m, 16))
        for m in re.findall(r"0x00([0-9a-f]{6})", t):
            v = int(m, 16)
            if not (LO <= v < HI):
                big.add(v)
    return sorted(small), sorted(big)


def calls_out(lo, hi, lab):
    out = []
    for a, ln in code_lines():
        if not (lo <= a < hi):
            continue
        m = re.search(r";\s*[0-9A-F]{6}\s+(?:call|calr)\s+(?:\w+,)?0x([0-9a-f]{6})", ln)
        if m:
            t = int(m.group(1), 16)
            out.append(lab.get(t) or ("T_%06X" % t if 0xF40000 <= t < 0xF44018
                                      else "0x%06X" % t))
    seen = []
    for x in out:
        if x not in seen:
            seen.append(x)
    return seen


CURATED = {}


def header(a, end, lab, th, sr, ic):
    """The header.  Every list in it is computed, never typed."""
    L = ["; " + "-" * 74]
    cur = CURATED.get(a)
    name = lab[a]
    if cur:
        L += wrap("; %s -- " % name, cur["what"])
    else:
        L.append("; %s" % name)
    parts = []
    if a in th:
        parts.append(", ".join("T_%06X (x%d)" % (s, sr.get(s, 0)) for s in th[a]))
    inb = ic.get(a, [])
    if inb:
        parts.append("in-module: " + " ".join("0x%06X" % x for x in inb[:8]) +
                     (" +%d more" % (len(inb) - 8) if len(inb) > 8 else ""))
    L += wrap("; Called from: ", "; ".join(parts) if parts else
              "no thunk slot and no in-module call site -- reached only by a "
              "branch from the routine above, or by a computed transfer")
    if cur:
        L += wrap("; Inputs:  ", cur["inputs"])
        L += wrap("; Outputs: ", cur["outputs"])
    sm, bg = touched(a, end)
    tt = " ".join("(0x%04X)" % x for x in sm[:10]) + \
         (" +%d more" % (len(sm) - 10) if len(sm) > 10 else "")
    if bg:
        tt += "  |  " + " ".join("0x%06X" % x for x in bg[:6]) + \
              (" +%d more" % (len(bg) - 6) if len(bg) > 6 else "")
    L += wrap("; Touches: ", tt or "nothing with an absolute address")
    co = calls_out(a, end, lab)
    if co:
        L += wrap("; Calls:   ", " ".join(co[:12]) +
                  (" +%d more" % (len(co) - 12) if len(co) > 12 else ""))
    if cur:
        L += wrap("; Evidence: ", cur["evidence"])
        L += wrap("; Unknown: ", cur["unknown"])
    else:
        ev = FORCE.get(a)
        if ev:
            L += wrap("; Evidence: ", "the label is here because it is the " + ev +
                      "; the address is an instruction boundary of this "
                      "transcription (re-asserted on every emit)")
        elif a in th:
            L += wrap("; Evidence: ", "thunk slot T_%06X holds `jp 0x00%06X`, and "
                      "0x%06X is an instruction boundary of this transcription "
                      "(re-asserted on every emit).  That is ALL the name rests "
                      "on -- the name IS the address." % (th[a][0], a, a))
        else:
            L += wrap("; Evidence: ", "reached by a `call`/`calr` decoded in this "
                      "transcription (the sites are listed above), so 0x%06X is an "
                      "instruction boundary.  The name IS the address." % a)
        L += wrap("; Unknown: ", "what the routine is FOR.  Left as sub_XXXXXX "
                  "with the gap stated, per this tree's rule that a stated gap "
                  "beats a plausible guess.")
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


def map_block(a, lab):
    g = dict((p, gg) for p, gg, _ in grids())[a]
    t = list(at(a, 96))
    bad = [k for k in range(96) if t[k] != ideal(g)[k]]
    steps = sorted(set(t) - {0x7F})
    out = ["; " + "-" * 74]
    out += wrap("; %s -- " % lab[a],
                "96 bytes, one per index.  Entry k = %d * round(k / %d), i.e. the "
                "index rounded to the nearest multiple of %d; the value 96, which "
                "is off the end of the index range, is written as 0x7F instead.  "
                "Steps: %s, then 0x7F."
                % (g, g, g, ", ".join(str(x) for x in steps)))
    out += wrap("; Entry count: ",
                "96, and it is not the byte extent divided by anything -- the "
                "seven maps TILE 0x%06X-0x%06X (%d bytes) at 96 bytes each, the "
                "first address is RoundMap_Table[0] and the last map's last byte "
                "abuts 0x%06X, which is thunk target T_Quantize_Execute.  96 x 7 = %d = the "
                "extent, and 95 or 97 does not tile it."
                % (MAPS_AT, MAPS_END - 1, MAPS_END - MAPS_AT, MAPS_END,
                   MAPS_END - MAPS_AT))
    out += wrap("; Read by: ",
                "`ld XHL,(0x0E12) / ld A,(XHL+IX)` at 0xF5DC65-0xF5DC69, with IX "
                "the zero-extended byte the routine has just read from the buffer "
                "at (0x126E) and stored to (0x0E25); the result goes to (0x0E26).  "
                "(0x0E12) is loaded from RoundMap_Table by the sequence at "
                "0xF5DB97-0xF5DBAE.")
    out += wrap("; Evidence: ",
                "the grid g is read off this map's OWN distinct values, not typed, "
                "and all 96 entries are then compared with `g * round(k / g)` byte "
                "for byte on every emit -- %s.  The address comes from "
                "RoundMap_Table[%d], also read from the ROM."
                % ("%d of the 96 disagree, and they are listed on the ANOMALY line "
                   "below" % len(bad) if bad else "all 96 agree",
                   map_ptrs().index(a)))
    if bad:
        out += wrap("; ⚠ ANOMALY: ",
                    "%d of the 96 entries do NOT match that formula: %s.  They are "
                    "one greater than the arithmetic gives.  Recorded, not "
                    "corrected -- these are the ROM's bytes."
                    % (len(bad), ", ".join("[%d]=%d (formula %d)"
                                           % (k, t[k], ideal(g)[k]) for k in bad[:3])
                       + (" ... and %d more, all the same step" % (len(bad) - 3)
                          if len(bad) > 3 else "")))
    out += wrap("; Unknown: ",
                "what the 96 steps count.  The maps are selected by (0x0C7F), "
                "which this module tests only against even values, and the seven "
                "grids are 96, 48, 24, 12, 32, 16 and 8 -- the divisions of 96 "
                "into halves and into thirds.  Nothing here says what a step IS.")
    out.append("; " + "-" * 74)
    out.append("%s:" % lab[a])
    out += byte_rows(a, 96, 16)
    return out


def table_block(lab):
    n = map_count()
    out = ["; " + "-" * 74]
    out += wrap("; RoundMap_Table -- ",
                "%d pointers, one per round-map, selected by (0x0C7F)." % n)
    out += wrap("; Entry count: ",
                "%d, from the `jr T,0x%06X` at 0xF5DBB2 that jumps OVER the table: "
                "the distance from the table to that target is %d bytes and every "
                "entry is 4.  Not from the byte extent of anything else."
                % (n, MAPS_TABLE + 4 * n, 4 * n))
    out += wrap("; Read by: ",
                "one site: `ld XDE,0x00F5DBB4` at 0xF5DBA3 (a byte scan for the "
                "address reports 0xF5DBA4, that instruction's OPERAND field, one "
                "byte in), then `ld XIY,(XDE+HL)` at 0xF5DBA8 with HL = (0x0C7F) "
                "shifted left once at 0xF5DB9F.  The result is stored to (0x0E12) "
                "at 0xF5DBAE.")
    out += wrap("; Why the index is doubled: ",
                "(0x0C7F) is only ever tested against EVEN values in this module "
                "(`cp A,0` / `cp A,2` / `cp A,4` / `cp A,6` / `cp A,0x08` / "
                "`cp A,0x0a` at 0xF5DAD5-0xF5DAF3), so `sla 0x01,XHL` turns 0, 2, "
                "4 ... into the 4-byte offsets 0, 4, 8 ...  ⚠ that the selector's "
                "highest legal value is 0x0C is NOT established here; %d entries "
                "is established, by the jump-over above." % n)
    out += wrap("; Evidence: ",
                "the seven pointers read out of the ROM, each of which is the "
                "start of one 96-byte map, and the maps tile 0x%06X-0x%06X exactly."
                % (MAPS_AT, MAPS_END - 1))
    out += wrap("; Unknown: ", "what selects (0x0C7F).")
    out.append("; " + "-" * 74)
    out.append("RoundMap_Table:")
    for i, p in enumerate(map_ptrs()):
        out.append("\t.long\t0x00%06X\t; [%d] -> %s" % (p, i, lab.get(p, "?")))
    return out


def identity_block(lab):
    rd = direct_refs(0xF5EE75)
    out = ["; " + "-" * 74]
    out += wrap("; IdentityMap_0_31 -- ",
                "32 bytes, and entry k = k for every k.  The name describes the "
                "CONTENT and claims nothing about the purpose.")
    out += wrap("; Entry count: ",
                "32, fixed by the two `calr 0x00F5EE95` sites at 0xF5ED63 and "
                "0xF5F373: 0xF5EE95 - 0xF5EE75 = 32, and both of those calls are "
                "decoded instructions of this transcription, not resynchronised "
                "guesses.")
    out += wrap("; Read by: ",
                "three sites, each `ld XIX,0x00F5EE75` followed by "
                "`ld L,(XIX+HL)`: the instructions at 0x%06X, 0x%06X and 0x%06X.  "
                "(A byte scan for the address reports 0x%06X, 0x%06X and 0x%06X -- "
                "those are the OPERAND fields, one byte into each instruction.)  "
                "All three store the result to (0x0D44)."
                % tuple([x - 1 for x in rd] + list(rd)))
    out += wrap("; Evidence: ",
                "all 32 bytes are re-read and compared with 0..31 on every emit, "
                "and the 32 comes from the two `calr 0x00F5EE95` above -- both of "
                "them decoded instructions of this transcription, so the length is "
                "a transfer target and not a place where a linear decode happened "
                "to resynchronise.")
    out += wrap("; Unknown: ",
                "why an identity map exists at all.  A table that returns its own "
                "index changes nothing at run time, so either it is a hook a later "
                "build was meant to fill in, or the index has a meaning the map "
                "documents rather than alters.  Nothing here decides which, and "
                "the name deliberately does not.")
    out.append("; " + "-" * 74)
    out.append("IdentityMap_0_31:")
    out += byte_rows(0xF5EE75, 32, 16)
    return out


def bounds_block(a, which, lab):
    gs = grids()
    grp = bound_groups()
    rot = which == "B"
    out = ["; " + "-" * 74]
    out += wrap("; RoundMap_Bounds_%s -- " % which,
                "36 bytes: the seven round-maps' STEP BOUNDARIES, concatenated in "
                "RoundMap_Table order, %s"
                % ("each map's list rotated right by one (the last boundary moved "
                   "to the front)." if rot else "in ascending order."))
    out += wrap("; Layout: ",
                "seven groups, one per map, of %s entries -- that is 96/g rounded "
                "to the boundaries below 96, i.e. exactly the number of half-grid "
                "step edges map g has.  1+2+4+8+3+6+12 = 36."
                % "+".join(str(len(x)) for x in grp))
    for i, ((p, g, _), lst) in enumerate(zip(gs, grp)):
        vals = rot1(lst) if rot else lst
        out.append(";   +0x%02X  [%d] g=%-2d  %s"
                   % (sum(len(x) for x in grp[:i]), i, g,
                      " ".join(str(v) for v in vals)))
    out += wrap("; Entry count: ",
                "36, and it is DERIVED, not measured off the island: the group "
                "sizes come from the seven maps' own grids, and the concatenation "
                "is compared byte for byte with the ROM on every emit.  The two "
                "lists together are the island's whole 72 bytes.")
    out += wrap("; Evidence: ",
                "twelve sites in prom_b spell an address inside this island as a "
                "32-bit word, and every one of the twelve is exactly a GROUP "
                "START -- six in _A and six in _B, groups 1..6 of each (group 0 "
                "has a single entry and is not addressed).  The group sizes were "
                "derived from the maps before those addresses were looked at, so "
                "the agreement is a check and not a fit.")
    out += wrap("; Unknown: ",
                "which list is used for what.  _B is _A rotated, which is the "
                "shape of a 'previous boundary' table beside a 'next boundary' "
                "one, but nothing decoded here says which way round.")
    out.append("; " + "-" * 74)
    out.append("RoundMap_Bounds_%s:" % which)
    off = 0
    for i, lst in enumerate(grp):
        vals = rot1(lst) if rot else lst
        raw = list(at(a + off, len(lst)))
        assert raw == vals, "bounds group %d mismatch at 0x%06X" % (i, a + off)
        out.append("\t.byte\t%s\t; [%d] g=%d"
                   % (", ".join("0x%02X" % x for x in raw), i, grids()[i][1]))
        off += len(lst)
    return out


def data_block(a, n, lab):
    if a == MAPS_AT:                    # one LAYOUT segment, seven objects
        out = []
        for p in map_ptrs():
            out += map_block(p, lab) + [""]
        return out[:-1]
    if a == MAPS_TABLE:
        return table_block(lab)
    if a == 0xF5EE75:
        return identity_block(lab)
    if a == BOUNDS:
        return bounds_block(BOUNDS, "A", lab) + [""] + \
               bounds_block(BOUNDS + 36, "B", lab)
    raise AssertionError("no data block for 0x%06X" % a)


# ------------------------------------------------------------------- checks
FAIL = []


def check(msg, got, want, verbose=True):
    ok = got == want
    if verbose:
        print("  %-70s %-26s %s"
              % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def checks(verbose=True):
    del FAIL[:]
    c = lambda *a: check(*a, verbose=verbose)
    # 1. the LAYOUT tiles the whole range, in order, with no gap and no overlap
    pos = LO
    for kind, s, n in LAYOUT:
        c("LAYOUT: %-4s 0x%06X starts where the last segment ended" % (kind, s),
          "0x%06X" % s, "0x%06X" % pos)
        pos = s + n
    c("LAYOUT ends at the .incbin's end", "0x%06X" % pos, "0x%06X" % HI)
    c("LAYOUT covers the .incbin's length", pos - LO, 0x7019)
    # 2. THE CHECK THAT MATTERS: every thunk target is an instruction boundary
    b, th = boundaries(), thunks()
    c("17 thunk slots point into this range", len(th), 17)
    c("every thunk target is an instruction boundary of the transcription",
      sorted("0x%06X" % t for t in th if t not in b), [])
    last = max(th)
    c("the LAST thunk target (0x%06X) is on a boundary" % last, last in b, True)
    # 3. the padding runs
    for s, n in ((0xF5D7EF, 0x13), (0xF622D6, 0x92A)):
        c("0x%06X-0x%06X is %d bytes of 0x0E" % (s, s + n - 1, n),
          (len(at(s, n)), sorted(set(at(s, n)))), (n, [0x0E]))
    # ⚠ the byte BEFORE each run is also 0x0E, because `ret` IS 0x0E.  The
    # transcription reads that byte as the `ret` closing the routine above, for
    # the same reason the songstore module does: a routine reached by `call` must
    # return.  Where the routine stops and the padding starts is a READING; the
    # check below states exactly how far back the raw run reaches so the reading
    # is visible rather than hidden.
    for s in (0xF5D7EF, 0x0F622D6 & 0xFFFFFF):
        run = 0
        while at(s - 1 - run, 1)[0] == 0x0E:
            run += 1
        c("the raw 0x0E run before 0x%06X reaches back exactly 1 byte" % s, run, 1)
    # 4. the round maps
    n = map_count()
    c("RoundMap_Table has %d entries (from the jump-over)" % n, n, 7)
    ps = map_ptrs()
    c("the seven maps tile 0x%06X-0x%06X at 96 bytes each" % (MAPS_AT, MAPS_END - 1),
      ps, [MAPS_AT + 96 * i for i in range(7)])
    c("and the last one abuts thunk target T_Quantize_Execute", ps[-1] + 96, MAPS_END)
    gs = [g for _, g, _ in grids()]
    c("the seven grids, read off each map's own values", gs, [96, 48, 24, 12, 32, 16, 8])
    for p, g, t in grids():
        bad = [k for k in range(96) if t[k] != ideal(g)[k]]
        if p == 0xF5D922:
            c("RoundMap_12: exactly 12 entries differ from round-to-nearest",
              len(bad), 12)
            c("...and every one of them is +1 on the same step (value 73 for 72)",
              sorted(set((t[k], ideal(g)[k]) for k in bad)), [(73, 72)])
        else:
            c("%s matches g*round(k/g) for all 96 entries" % DATA_LABEL[p], bad, [])
        c("%s's top step is 0x7F, not 96" % DATA_LABEL[p], t[95], 0x7F)
    # 5. the boundary island, derived from the maps and then compared
    grp = bound_groups()
    c("group sizes derived from the grids", [len(x) for x in grp], [1, 2, 4, 8, 3, 6, 12])
    flat = [v for x in grp for v in x]
    c("RoundMap_Bounds_A IS that concatenation, byte for byte",
      list(at(BOUNDS, 36)), flat)
    flatb = [v for x in grp for v in rot1(x)]
    c("RoundMap_Bounds_B IS the same with every group rotated right by one",
      list(at(BOUNDS + 36, 36)), flatb)
    starts = []
    off = 0
    for x in grp:
        starts.append(off)
        off += len(x)
    want = sorted([BOUNDS + s for s in starts[1:]] + [BOUNDS + 36 + s for s in starts[1:]])
    got = sorted(set(t for t in range(BOUNDS, BOUNDS + 72) if direct_refs(t)))
    c("every address referenced inside the island is a GROUP START",
      ["0x%06X" % x for x in got], ["0x%06X" % x for x in want])
    # 6. the identity map
    c("IdentityMap_0_31 is 0..31", list(at(0xF5EE75, 32)), list(range(32)))
    c("its three readers", ["0x%06X" % x for x in direct_refs(0xF5EE75)],
      ["0xF5ED51", "0xF5F361", "0xF600DE"])
    # the operand-vs-instruction step, asserted rather than assumed -- this is the
    # defect finding F2 was about, one module over.
    c("each reader's instruction byte is 0x44 (`ld XIX,imm32`), one before the hit",
      [at(x - 1, 1)[0] for x in direct_refs(0xF5EE75)], [0x44, 0x44, 0x44])
    c("RoundMap_Table's reader is 0x42 (`ld XDE,imm32`) at 0xF5DBA3",
      (at(0xF5DBA3, 1)[0], direct_refs(MAPS_TABLE)), (0x42, [0xF5DBA4]))
    c("its end 0xF5EE95 is a `calr` target twice over",
      (text_at(0xF5ED63), text_at(0xF5F373)),
      ("calr 0xf5ee95", "calr 0xf5ee95"))
    # 7. every FORCE label has a reason, is on a boundary, AND is emitted
    lab_ = labels()
    for a_, why in FORCE.items():
        c("FORCE 0x%06X: boundary, reason, and IN the label set" % a_,
          (a_ in b, bool(why), a_ in lab_), (True, True, True))
    c("every DATA label is in the label set",
      sorted("0x%06X" % x for x in DATA_LABEL if x not in lab_), [])
    c("every CURATED address is in the label set",
      sorted("0x%06X" % x for x in CURATED if x not in lab_), [])
    # 8. no label lands inside a data segment except the data labels themselves
    dataspan = [(s, s + n) for k, s, n in LAYOUT if k in ("data", "fill")]
    stray = [a_ for a_ in lab_ if a_ not in DATA_LABEL
             and any(s <= a_ < e for s, e in dataspan)]
    c("no code label falls inside a data or fill segment",
      sorted("0x%06X" % x for x in stray), [])
    # 9. EVERY label must be emittable.  emit() attaches a label only when its
    #    address is a line of the transcription, so a label that is not an
    #    instruction boundary is SILENTLY DROPPED -- the byte gate stays green and
    #    a routine the header list promises never appears.  That is exactly how
    #    gen_prom_b_songstore_module.py lost BStore_LatchHeapBase in its first
    #    draft, so the same check is repeated here for every label, not only FORCE.
    codespan = [(s_, s_ + n_) for k_, s_, n_ in LAYOUT if k_ == "code"]
    missing = [a_ for a_ in lab_ if a_ not in DATA_LABEL and a_ not in b]
    c("every non-data label is an instruction boundary",
      sorted("0x%06X" % x for x in missing), [])
    c("every non-data label is inside a code segment",
      sorted("0x%06X" % a_ for a_ in lab_
             if a_ not in DATA_LABEL and not any(s_ <= a_ < e_ for s_, e_ in codespan)),
      [])
    if verbose:
        print("\n%s (%d failed)" % ("CHECKS PASS" if not FAIL else "CHECKS FAIL",
                                    len(FAIL)))
    return not FAIL


BANNER = """
; ==============================================================================
; 0xF5BBE7-0xF62BFF -- THE 96-STEP ROUNDING MAPS AND THE CODE THAT USES THEM
;   the last unconverted `.incbin` span between the selector dispatchers at
;   0xF5B8B6 and the block store at 0xF62C00, converted whole
; ==============================================================================
;
; WHY THIS BLOCK.  notes/prom_b_module_frontier.py ranks thunk runs by CONTIGUOUS
; unconverted target extent.  T_F426E0-T_F42720 is 17 slots over 16,244 bytes,
; all inside ONE `.incbin` span, with the highest summed reference upper bound of
; any run in the image (62); it owns 0xF5EBD0, which notes/prom_b_call_graph.py
; ranks the SECOND most-referenced unconverted target in prom_b (x25, through
; T_BStore_ReadCursorAdvance_Call).  Those 17 slots are the ONLY thunk slots pointing anywhere into the
; span, so the run and the span are the same boundary seen twice, and converting
; the span closes it entirely.
;
; ⚠ WHERE THE START COMES FROM.  notes/prom_a_linear_decode_check.py's warning
; applies: a TLCS-900 linear decode resynchronises within a couple of
; instructions, so "it decodes cleanly" does not pin where a span BEGINS.  What
; pins this one is the converted code above it -- this file already transcribes
; through 0xF5BBE6, and that byte is a `ret`.  0xF5BBE7 is the next byte after a
; proven instruction.  The end is the `.incbin`'s own end.
;
; EXTENT.  Code and data run 0xF5BBE7-0xF5D7EE and 0xF5D802-0xF622D5;
; 0xF5D7EF-0xF5D801 (19 bytes) and 0xF622D6-0xF62BFF (2,346 bytes) are 0x0E
; (`ret`) padding, re-asserted pure on every emit.
;
; THE DATA, AND WHAT IT IS
;
;   0xF5D802  SEVEN 96-ENTRY ROUNDING MAPS.  Each is 96 bytes and each entry k is
;             `g * round(k / g)` for that map's own g -- the index rounded to the
;             nearest multiple of g -- except that the value 96, which is off the
;             end of the index range, is written as 0x7F.  The seven g are
;             96, 48, 24, 12, 32, 16, 8: the divisions of 96 into halves and into
;             thirds.  The grid is DERIVED from each map's own distinct values,
;             and the whole 96-entry table is then compared with the formula byte
;             for byte on every emit.
;             ⚠ ONE ANOMALY, recorded and not corrected: RoundMap_12's entries
;             66..77 read 73 where the formula gives 72.  Twelve bytes, one whole
;             step, all off by the same +1.
;
;   0xF5DBB4  RoundMap_Table, the seven pointers, selected by (0x0C7F).  Its
;             entry count comes from the `jr T,0xF5DBD0` at 0xF5DBB2 that jumps
;             OVER it: 28 bytes / 4.
;
;   0xF5EE75  IdentityMap_0_31 -- 32 bytes, entry k = k.  Read by three sites,
;             and its length is fixed by the two `calr 0xF5EE95` that step past
;             it.  Why an identity map exists is NOT established, and the name
;             deliberately describes the content instead of guessing a purpose.
;
;   0xF621B9  RoundMap_Bounds_A and _B -- 36 bytes each: the seven maps' step
;             BOUNDARIES concatenated in RoundMap_Table order, group sizes
;             1+2+4+8+3+6+12, _B being _A with each group rotated right by one.
;             The group sizes are derived from the maps' grids; the twelve sites
;             that address the island then land, all twelve, exactly on group
;             starts.  The agreement is a check, not a fit -- the sizes were
;             derived before the addresses were looked at.
;
; ⚠ WHAT IS NOT ESTABLISHED.  What the 96 steps COUNT.  Nothing decoded here says
; it; the module's own code only ever selects a map with (0x0C7F) and indexes it
; with a byte read out of the buffer at (0x126E).  Neither is what selects
; (0x0C7F).  The routines are `sub_XXXXXX` with a computed header claiming only
; the entry point, per this tree's rule that a stated gap beats a plausible
; guess.
;
; REGENERATE:  python3 notes/gen_prom_b_f5bbe7_module.py
; CHECKS:      python3 notes/gen_prom_b_f5bbe7_module.py --checks
; ==============================================================================
"""


def emit():
    lab, th, sr, ic = labels(), thunks(), slot_refs(), internal_calls()
    keys = sorted(lab)
    ends = {a: (keys[i + 1] if i + 1 < len(keys) else HI) for i, a in enumerate(keys)}
    out = BANNER.strip("\n").split("\n")
    out.append("")
    for kind, s, n in LAYOUT:
        if kind == "fill":
            out += ["\t.fill\t%d, 1, 0x0E\t; %06X-%06X  `ret` padding (asserted "
                    "pure 0x0E)" % (n, s, s + n - 1), ""]
            continue
        if kind == "data":
            out += [""] + data_block(s, n, lab) + [""]
            continue
        for a, ln in transcribe_pairs(s, n):
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
        for kind, s, n in LAYOUT:
            print("  %-4s 0x%06X-0x%06X  %6d" % (kind, s, s + n - 1, n))
        return 0
    if "--maps" in sys.argv:
        for i, (p, g, t) in enumerate(grids()):
            rle, j = [], 0
            while j < 96:
                k = j
                while k < 96 and t[k] == t[j]:
                    k += 1
                rle.append("%d x%d" % (t[j], k - j))
                j = k
            print("[%d] 0x%06X g=%-3d %s" % (i, p, g, "  ".join(rle)))
        return 0
    if not checks(verbose=False):
        checks()
        raise SystemExit("refusing to emit: a check failed (see above)")
    print("\n".join(emit()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
