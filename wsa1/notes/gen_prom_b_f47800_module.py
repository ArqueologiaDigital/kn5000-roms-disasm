#!/usr/bin/env python3
"""Emit the assembly for prom_b 0xF47800-0xF4EFFF -- the eight-module block that
opens the `.incbin` span 0x047800-0x054FFF.

QUESTION IT ANSWERS
    "What is the assembly text for the nine thunk-table runs that live in the
     0xF47800 span, in a form the byte gate accepts, with every label and header
     attached to the right address?"
    This is the emitter whose output is pasted into prom_b/wsa1_prom_b.s.

WHY THIS BLOCK (round 3, chosen with the frontier tools, not by address order)
    * notes/prom_b_call_graph.py --n 30 ranks the unconverted thunk SLOTS by an
      opcode-anchored reference upper bound.  Of the ELEVEN unconverted slots at
      x13 or more, EIGHT pointed into this range -- 0xF4E56F (x24), 0xF4D01D
      (x21), 0xF4D0DB (x18), 0xF4D02C (x15), 0xF4E524 (x14), 0xF4D0FB (x14),
      0xF48580 (x13), 0xF48464 (x13) -- all in the SAME `.incbin` span,
      0x047800-0x054FFF.
      ⚠ Stated at a THRESHOLD, not as "N of the top ten": two slots tie at x13,
      two at x14 and two at x15, so a top-N phrasing depends on how the sort
      broke the ties.  notes/prom_b_round3_frontier_delta.py re-derives 11 and 8
      from the ROM and also asserts that nothing else sits at exactly 13.
    * notes/prom_b_module_frontier.py ranks whole RUNS; this span holds nine of
      them (T_F40B40, T_SeqRecord_LoadTakeCursor_Veneer, T_BStore_StepCursorOneByte, T_F40CB0, T_F40CE0, T_SeqTrack_PlayOnWhileStopped,
      T_BStore_CompactBlocks_Veneer, T_ScreenEnter_CreatorSelectController and, past the end of this block, T_F42E40).
    * Summed over the eight modules converted here that is 92 thunk slots -- the
      largest single-span slot count left in prom_b.

    ⚠ The span is NOT closed by this block: 0xF4F000-0xF54FFF stays `.incbin`.
      The reason is stated under WHAT IS LEFT below, and the frontier delta this
      block claims is 92 slots, not the span's whole count.

WHERE THE BOUNDARIES COME FROM
    ⚠ notes/prom_a_linear_decode_check.py's warning applies: a TLCS-900 linear
    decode resynchronises, so "it decodes cleanly" pins nothing.  Every segment
    edge in LAYOUT below is one of:
      * the `.incbin`'s own start (0xF47800), which is also thunk target
        T_F40B40's target, i.e. an entry point the hardware uses;
      * the first byte of a maximal run of 0x0E, with the run's purity re-read on
        every emit (the `fill` rows);
      * a thunk target -- 0xF48C1A ends the 0xF48C00 data island and is the
        target of thunk slot T_DiskFile_CheckSignature, which is as hard a pin as this tree has.
        ⚠ The slot NAME is computed by thunks() wherever it is printed: the
        first draft of this file typed "T_SeqTrackCursors_SaveTrack" here and in the Table_F48C00
        header, and T_SeqTrackCursors_SaveTrack's target is 0xF483B2.  The Table_F48C00 header now
        reads the slot out of thunks(); the one remaining typed occurrence, in
        the block BANNER, is pinned by a checks() row that asserts the slot set
        of 0xF48C1A is exactly {T_DiskFile_CheckSignature};
      * an address that a decoded instruction of this transcription names.
    checks() re-derives all of them from the ROM.

HOW THE CODE/DATA SPLIT WAS MADE
    notes/prom_b_module_trace.py 0xF47800 0xF55000 does a recursive descent from
    the 103 thunk entry points in the span and reports what it never reached.
    27 runs came back.  Every one inside this block was read:
      * eleven are ordinary code the descent could not reach (arms of `jr`
        ladders, and routines entered only through a pointer table);
      * eight are the 0x0E padding runs;
      * TEN are data, and each one's extent is pinned by something outside
        itself -- a reader instruction, a thunk target, or the record framing:
          0xF48C00  Table_F48C00       ends at thunk target 0xF48C1A
          0xF4B7AD  IdentityMap_F4B7AD ends where the 0x0E padding starts;
                                       read by `ld XIX,0x00F4B7AD` at 0xF4A533
          0xF4C000  DL_F4C000          81 records whose own length bytes walk
                                       from 0xF4C000 onto 0xF4C38D exactly
          0xF4C38D  ScreenButtonHandlers_CreatorSelectController  23 pointers, all into prom_b
          0xF4C3E9  BitMask_F4C3E9     9 bytes, ends at thunk target 0xF4C3F2
          0xF4E5DC  IdentityMap_F4E5DC 32 bytes, read at 0xF4E234
          0xF4E5FC  BitWeight_F4E5FC   16 words, read at 0xF4E510
          0xF4EF2F  Table_F4EF2F       9 bytes
          0xF4EF38  Table_F4EF38       8 bytes, bound by the `and A,0x07` at
                                       0xF4EDF0 in front of its reader
          0xF4EF40  Table_F4EF40       36 bytes, byte-identical to
                                       0xF4EF1C-0xF4EF3F
    Code runs go through notes/llvm_roundtrip_autoforce.py, which assembles the
    candidate listing and compares it byte for byte with the ROM before printing.

WHAT IS LEFT, AND WHY
    0xF4F000-0xF54FFF (24,576 bytes) stays `.incbin`.  notes/prom_b_module_trace
    reaches NONE of 0xF4EF14-0xF53019: those modules have no thunk slot pointing
    at them, so the descent has no seed and the split would rest on a linear
    decode -- the one thing this tree's rules forbid as a boundary argument.

RUN
    python3 notes/gen_prom_b_f47800_module.py            # the assembly
    python3 notes/gen_prom_b_f47800_module.py --layout   # the 26-segment table
    python3 notes/gen_prom_b_f47800_module.py --checks   # it REFUSES to emit if one fails
    python3 notes/gen_prom_b_f47800_module.py --records  # the 81 DL_F4C000 records
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
LO, HI = 0xF47800, 0xF4F000
TBL_LO, TBL_HI = 0x40000, 0x44018

# (kind, start, length).  Contiguity, the 0xF4F000 end and the purity of every
# `fill` run are asserted in checks() -- this table is never trusted as typed.
LAYOUT = [
    ("code", 0xF47800, 0x0FEA),
    ("fill", 0xF487EA, 0x0416),
    ("data", 0xF48C00, 0x001A),
    ("code", 0xF48C1A, 0x089E),
    ("fill", 0xF494B8, 0x0348),
    ("code", 0xF49800, 0x1FAD),
    ("data", 0xF4B7AD, 0x0020),
    ("fill", 0xF4B7CD, 0x0833),
    ("data", 0xF4C000, 0x038D),
    ("data", 0xF4C38D, 0x005C),
    ("data", 0xF4C3E9, 0x0009),
    ("code", 0xF4C3F2, 0x0344),
    ("fill", 0xF4C736, 0x00CA),
    ("code", 0xF4C800, 0x035B),
    ("fill", 0xF4CB5B, 0x04A5),
    ("code", 0xF4D000, 0x094A),
    ("fill", 0xF4D94A, 0x06B6),
    ("code", 0xF4E000, 0x05DC),
    ("data", 0xF4E5DC, 0x0020),
    ("data", 0xF4E5FC, 0x0020),
    ("fill", 0xF4E61C, 0x05E4),
    ("code", 0xF4EC00, 0x032F),
    ("data", 0xF4EF2F, 0x0009),
    ("data", 0xF4EF38, 0x0008),
    ("data", 0xF4EF40, 0x0024),
    ("fill", 0xF4EF64, 0x009C),
]

DL_AT, DL_END = 0xF4C000, 0xF4C38D          # the display list and its end
PTBL_AT, PTBL_N = 0xF4C38D, 23              # the pointer table
DEAD_AT, DEAD_SRC = 0xF4EF40, 0xF4EF1C      # the 36-byte duplicate and its twin

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
        if kind == "code":
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
    """(instruction address, mnemonic) of the transcribed instruction that
    CONTAINS the 32-bit reference at `a`.

    ⚠ NOT `a - 1`.  That shortcut is why the first draft of this file shipped two
    OFF-BY-2 header lines that notes/prom_b_audit_callsites.py caught: `ld
    XIX,imm32` is a ONE-byte opcode, so the operand starts at a-1, but `add
    XWA,imm32` is TWO bytes and the operand starts at a-2.  This walks the proven
    transcription instead, so the answer is whatever the decode says."""
    best = None
    for ad, ln in code_lines():
        if ad <= a and (best is None or ad > best[0]):
            best = (ad, ln)
    if best is None:
        return None, ""
    return best[0], text_at(best[0])


def reader_line(a, what="Read by"):
    """A `; Read by:` sentence that names the INSTRUCTION and, separately, the
    operand field -- phrased so the word OPERAND follows the operand address,
    which is the form notes/prom_b_audit_callsites.py recognises."""
    ia, it = reader(a)
    return ("one site: `%s` at 0x%06X.  (The byte scan for the address hits "
            "0x%06X, which is that instruction's OPERAND field, %d byte%s in.)"
            % (it, ia, a, a - ia, "" if a - ia == 1 else "s"))


def internal_calls():
    """{callee: [caller, ...]} from the PROVEN transcription's own comments.
    Exact, not a byte window: every entry comes off a decoded instruction."""
    out = {}
    for a, ln in code_lines():
        m = re.search(r";\s*[0-9A-F]{6}\s+(call|calr)\s+(?:\w+,)?0x([0-9a-f]{6})", ln)
        if m:
            out.setdefault(int(m.group(2), 16), []).append(a)
    return out


# ------------------------------------------------------------------ the data
def dl_records():
    """The 81 records of DL_F4C000, framed by their own length bytes."""
    out, a = [], DL_AT
    while a < DL_END:
        op, ln = at(a, 1)[0], at(a + 1, 1)[0]
        if ln == 0:
            break
        out.append((a, op, ln))
        a += ln
    return out, a


def ptrs():
    return [int.from_bytes(at(PTBL_AT + 4 * i, 4), "little") for i in range(PTBL_N)]


DATA_LABEL = {
    0xF48C00: "Table_F48C00",
    0xF4B7AD: "IdentityMap_F4B7AD",
    0xF4C000: "DL_F4C000",
    0xF4C38D: "ScreenButtonHandlers_CreatorSelectController",
    0xF4C3E9: "BitMask_F4C3E9",
    0xF4E5DC: "IdentityMap_F4E5DC",
    0xF4E5FC: "BitWeight_F4E5FC",
    0xF4EF2F: "Table_F4EF2F",
    0xF4EF38: "Table_F4EF38",
    0xF4EF40: "Table_F4EF40",
}

NAMES = {}

# Addresses that are neither a thunk target nor a call target but do start a
# routine.  Each one needs its own reason, stated here and re-checked in
# checks(): nothing may be forced into the label set on taste alone.
FORCE = {}


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


def ascii_of(a, n):
    return "".join(chr(x) if 32 <= x < 127 else "." for x in at(a, n))


def block_F48C00(lab):
    rd = direct_refs(0xF48C00)
    out = ["; " + "-" * 74]
    out += wrap("; Table_F48C00 -- ",
                "26 bytes: sixteen ASCII bytes '%s', then the four ASCII bytes "
                "'%s', then six bytes %s.  The name claims nothing beyond that; "
                "what the six trailing bytes mean is NOT established."
                % (ascii_of(0xF48C00, 16), ascii_of(0xF48C10, 4),
                   " ".join("0x%02X" % x for x in at(0xF48C14, 6))))
    out += wrap("; Read by: ",
                "the routine that starts at the very next byte.  `lda "
                "XIY,0xf48c00` at 0xF48C24 followed by `ldirw` with BC = 8 copies "
                "the first SIXTEEN bytes (8 words) to XIZ+0xC6, and `ld "
                "XBC,(0xf48c10)` at 0xF48C2E takes the next FOUR to XIZ+0xDC.  "
                "That is 20 of the 26 accounted for by decoded instructions.  "
                "(`lda` computes the address, so no 32-bit reference to it exists "
                "anywhere in prom_a or prom_b -- direct_refs() returns %d.)"
                % len(rd))
    out += wrap("; Entry count: ",
                "26 bytes, and the END is not a reading: 0xF48C1A is the target "
                "of thunk slot %s, so the byte after this island is an entry "
                "point the hardware itself uses (the slot name is read out of "
                "the thunk table, not typed).  The START is the first byte after "
                "the 0x0E padding run that closes the module above."
                % ", ".join("T_%06X" % x for x in thunks()[0xF48C1A]))
    out += wrap("; Evidence: ",
                "both ASCII runs are re-read and compared on every emit, and so "
                "are the two instructions above (0xF48C24 `lda XIY,0xf48c00`, "
                "0xF48C2E `ld XBC,(0xf48c10)`), taken out of the proven "
                "transcription rather than typed.")
    out += wrap("; Unknown: ",
                "what the object IS.  'WSA SOUND RAM S0' and 'WSA1' read like the "
                "title and the format magic of a saved-data header, and the "
                "routine below copies them into a stack frame -- but nothing "
                "decoded here follows that frame to a device, so the name stays "
                "Table_XXXXXX.")
    out.append("; " + "-" * 74)
    out.append("Table_F48C00:")
    out.append("\t.ascii\t\"%s\"\t; F48C00  16 bytes" % ascii_of(0xF48C00, 16))
    out.append("\t.ascii\t\"%s\"\t; F48C10  4 bytes" % ascii_of(0xF48C10, 4))
    out += byte_rows(0xF48C14, 6, 16)
    return out


def block_identity(a, lab):
    rd = direct_refs(a)
    out = ["; " + "-" * 74]
    out += wrap("; %s -- " % lab[a],
                "32 bytes, and entry k = k for every k.  The name describes the "
                "CONTENT and claims nothing about the purpose.")
    out += wrap("; Read by: ", reader_line(rd[0]) if rd else "nothing")
    out += wrap("; Entry count: ",
                "32, from the island's own extent: %s"
                % ("the next byte, 0x%06X, opens the 0x0E padding run that closes "
                   "the module." % (a + 32) if a == 0xF4B7AD else
                   "0x%06X starts BitWeight_F4E5FC, whose own reader is at "
                   "0xF4E510." % (a + 32)))
    out += wrap("; Evidence: ",
                "all 32 bytes are re-read and compared with 0..31 on every emit.")
    out += wrap("; Unknown: ",
                "why an identity map exists at all.  A table that returns its own "
                "index changes nothing at run time.  prom_b has a THIRD one at "
                "0xF5EE75 (IdentityMap_0_31, converted in round 2) with the same "
                "content and the same open question; three copies is a fact this "
                "records, not an explanation.")
    out.append("; " + "-" * 74)
    out.append("%s:" % lab[a])
    out += byte_rows(a, 32, 16)
    return out


def block_bitweight(lab):
    a = 0xF4E5FC
    rd = direct_refs(a)
    out = ["; " + "-" * 74]
    out += wrap("; BitWeight_F4E5FC -- ",
                "sixteen 16-bit little-endian words, entry k = 1 << k: 0x0001, "
                "0x0002, 0x0004 ... 0x8000.  Content-descriptive name, asserted "
                "word for word on every emit.")
    out += wrap("; Read by: ", reader_line(rd[0]))
    out += wrap("; Entry count: ",
                "16 words = 32 bytes.  The island runs from the end of "
                "IdentityMap_F4E5DC to 0xF4E61C, where the module's 0x0E padding "
                "starts, and 32 bytes hold exactly sixteen 1<<k weights with "
                "nothing left over -- a seventeenth would need the padding byte.")
    out += wrap("; Evidence: ", "every word is unpacked and compared with 1 << k "
                "on every emit.")
    out += wrap("; Unknown: ", "which 16 flags the weights index.")
    out.append("; " + "-" * 74)
    out.append("BitWeight_F4E5FC:")
    for i in range(16):
        out.append("\t.short\t0x%04X\t; %06X  [%d] = 1 << %d"
                   % (int.from_bytes(at(a + 2 * i, 2), "little"), a + 2 * i, i, i))
    return out


def block_dl(lab):
    recs, end = dl_records()
    ops = sorted(set(o for _, o, _ in recs))
    txt = [r for r in recs if any(32 <= c < 127 for c in at(r[0] + 2, r[2] - 2))]
    out = ["; " + "-" * 74]
    out += wrap("; DL_F4C000 -- ",
                "a UI DISPLAY LIST: %d records in the byte-coded format "
                "scripts/analysis/prom_b_display_lists.py documents (+0 opcode, "
                "+1 length of the WHOLE record, +2 operands and, for the text "
                "opcodes, characters).  Opcodes present: %s."
                % (len(recs), " ".join("0x%02X" % o for o in ops)))
    out += wrap("; Entry count: ",
                "%d records, and the count is SELF-CHECKING rather than measured: "
                "starting at 0xF4C000 and advancing by each record's own length "
                "byte lands on 0x%06X, which is exactly where "
                "ScreenButtonHandlers_CreatorSelectController begins.  A miscount anywhere in the walk "
                "would end somewhere else."
                % (len(recs), end))
    out += wrap("; Text it draws: ",
                "; ".join(sorted(set(
                    re.sub(r"[^ -~]", ".", ascii_of(a + 2, n - 2)).strip()
                    for a, _, n in txt
                    if len(re.sub(r"[^A-Za-z]", "", ascii_of(a + 2, n - 2))) >= 4))
                    ) or "no run of four or more letters")
    out += wrap("; Called from: ",
                "NOT established.  No site in prom_a or prom_b spells 0xF4C000 as "
                "a 32-bit word (direct_refs() returns %d), so whatever passes this "
                "list to the interpreter computes the address.  The list is "
                "therefore emitted as `.byte` rows framed by the length bytes, "
                "NOT rendered record by record the way the lists with known call "
                "sites are." % len(direct_refs(DL_AT)))
    out += wrap("; Evidence: ",
                "the framing walk above, re-run on every emit; it must consume "
                "every byte from 0x%06X to 0x%06X and stop exactly there."
                % (DL_AT, end))
    out += wrap("; Unknown: ",
                "which interpreter runs it.  Four records carry 32-bit pointers "
                "back INTO the list (0x00F4C2E3, 0x00F4C2E9, 0x00F4C2EF, "
                "0x00F4C32F), which is the sub-list shape of opcodes 3 and 4; but "
                "the record at 0xF4C2F8 frames as opcode 0x00 with length 134, a "
                "shape nothing else in prom_b shows.  It is recorded, not "
                "smoothed: the walk still lands on the pointer table.")
    out.append("; " + "-" * 74)
    out.append("DL_F4C000:")
    for a, op, n in recs:
        txt_ = ascii_of(a + 2, n - 2)
        out += ["\t.byte\t%s\t; %06X  op 0x%02X len %d%s"
                % (", ".join("0x%02X" % x for x in at(a, n)), a, op, n,
                   ("  |%s|" % txt_) if re.search(r"[A-Za-z]{3}", txt_) else "")]
    return out


def block_ptbl(lab):
    ps, rd = ptrs(), direct_refs(PTBL_AT)
    default = 0xF42C70
    out = ["; " + "-" * 74]
    out += wrap("; ScreenButtonHandlers_CreatorSelectController -- ",
                "%d 32-bit pointers.  %d of them are the DEFAULT thunk slot "
                "0x00F42C70 (see notes/prom_b_default_slot_census.py); the other "
                "%d point into this module, at %s."
                % (PTBL_N, ps.count(default), PTBL_N - ps.count(default),
                   ", ".join("0x%06X" % x for x in sorted(set(ps) - {default}))))
    out += wrap("; Read by: ", reader_line(rd[0]) +
                "  It is the ONLY site in prom_a or prom_b that spells this "
                "address.")
    out += wrap("; Entry count: ",
                "%d, and it is not a byte extent divided by four.  The table "
                "starts where the display list's framing walk stops (0x%06X) and "
                "the FIRST byte that is not part of a 4-byte prom_b address is "
                "0x%06X, which is BitMask_F4C3E9 -- and 0x%06X - 0x%06X = %d = "
                "%d x 4 with nothing over.  Entry %d, the last, is 0x%08X."
                % (PTBL_N, PTBL_AT, PTBL_AT + 4 * PTBL_N, PTBL_AT + 4 * PTBL_N,
                   PTBL_AT, 4 * PTBL_N, PTBL_N, PTBL_N - 1, ps[-1]))
    out += wrap("; Evidence: ",
                "every one of the %d words is re-read on every emit and asserted "
                "to be an address in prom_b's own 0xF00000-0xFFFFFF window; the "
                "three non-default targets are additionally asserted to be "
                "instruction boundaries of this transcription." % PTBL_N)
    out += wrap("; Unknown: ",
                "what indexes it.  %d of the %d slots being the default stub says "
                "the index space is sparse, but nothing decoded here gives its "
                "bound." % (ps.count(default), PTBL_N))
    out.append("; " + "-" * 74)
    out.append("ScreenButtonHandlers_CreatorSelectController:")
    for i, p in enumerate(ps):
        tag = "default stub" if p == default else (lab.get(p) or "0x%06X" % p)
        out.append("\t.long\t0x00%06X\t; %06X  [%d] -> %s"
                   % (p, PTBL_AT + 4 * i, i, tag))
    return out


def block_bitmask(lab):
    a, rd = 0xF4C3E9, direct_refs(0xF4C3E9)
    out = ["; " + "-" * 74]
    out += wrap("; BitMask_F4C3E9 -- ",
                "9 bytes: entry 0 is 0x00 and entry k is 1 << (k-1) for k = 1..8, "
                "i.e. 00 01 02 04 08 10 20 40 80.  Content-descriptive name, "
                "asserted byte for byte on every emit.")
    out += wrap("; Read by: ", reader_line(rd[0]) +
                "  It is the only site in either ROM that spells the address.")
    out += wrap("; Entry count: ",
                "9, and the END is a thunk target: 0xF4C3F2 is T_ScreenEnter_CreatorSelectController's target, "
                "so the byte after this island is an entry point the hardware "
                "uses.  The START is where ScreenButtonHandlers_CreatorSelectController's 23 pointers "
                "stop.")
    out += wrap("; Evidence: ", "the nine bytes are compared with [0] + [1<<k] on "
                "every emit, and 0xF4C3F2's thunk slot is re-read from the table.")
    out += wrap("; Unknown: ",
                "why index 0 maps to no bit.  A 1-based bit selector with a dead "
                "zero entry is the usual shape, but nothing here fixes it.")
    out.append("; " + "-" * 74)
    out.append("BitMask_F4C3E9:")
    out += byte_rows(a, 9, 16)
    return out


def block_F4EF2F(lab):
    out = ["; " + "-" * 74]
    out += wrap("; Table_F4EF2F -- ",
                "9 bytes: %s." % " ".join("0x%02X" % x for x in at(0xF4EF2F, 9)))
    out += wrap("; Read by: ",
                "NOTHING that this tree can find.  No site in prom_a or prom_b "
                "spells 0xF4EF2F as a 32-bit word.  It sits between the `ret` at "
                "0xF4EF2E that closes the routine above and Table_F4EF38, which "
                "does have a reader.")
    out += wrap("; Entry count: ",
                "9 bytes, bounded below by that `ret` and above by 0xF4EF38, "
                "whose address a decoded instruction names.  Nothing establishes "
                "an ENTRY size, so the object is emitted as bytes.")
    out += wrap("; Evidence: ", "the extent only.  The name is the address and "
                "claims nothing else.")
    out += wrap("; Unknown: ", "everything except the bytes.  Note that "
                "Table_F4EF38's eight bytes are 0x01 0x01 0x02 ... 0x07, i.e. "
                "these nine minus the trailing 0x08 -- a near-duplicate, in a "
                "module whose tail also carries the 36-byte exact duplicate "
                "Table_F4EF40.  Recorded, not explained.")
    out.append("; " + "-" * 74)
    out.append("Table_F4EF2F:")
    out += byte_rows(0xF4EF2F, 9, 16)
    return out


def block_F4EF38(lab):
    rd = direct_refs(0xF4EF38)
    out = ["; " + "-" * 74]
    out += wrap("; Table_F4EF38 -- ",
                "8 bytes: %s." % " ".join("0x%02X" % x for x in at(0xF4EF38, 8)))
    out += wrap("; Read by: ", reader_line(rd[0]) +
                "  The value comes out at the `ld A,(XIX+IY)` two instructions "
                "later.")
    out += wrap("; Entry count: ",
                "8, and it is the CODE that fixes it, not the extent: the reader "
                "is preceded at 0xF4EDF0 by `and A,0x07` and 0xF4EDF3 by `ld "
                "IY,WA`, so the index can only be 0..7.  Both instructions are "
                "read back out of the proven transcription on every emit.")
    out += wrap("; Evidence: ", "the two instructions above plus the reader, all "
                "taken from the transcription rather than typed.")
    out += wrap("; Unknown: ", "what the eight values select.")
    out.append("; " + "-" * 74)
    out.append("Table_F4EF38:")
    out += byte_rows(0xF4EF38, 8, 16)
    return out


def block_F4EF40(lab):
    out = ["; " + "-" * 74]
    out += wrap("; Table_F4EF40 -- ",
                "36 bytes that are BYTE-IDENTICAL to 0xF4EF1C-0xF4EF3F, the tail "
                "of the routine at 0xF4EF14 together with the two tables after "
                "it.  The equality is asserted on every emit.")
    out += wrap("; Read by: ",
                "nothing.  No site in prom_a or prom_b spells 0xF4EF40, 0xF4EF53 "
                "or 0xF4EF5C as a 32-bit word.")
    out += wrap("; Why it is DATA and not code: ",
                "decoded from its own first byte it reads `jrl GT,0xF52E63` -- a "
                "jump into the 3,571-byte run of 0x0E padding at "
                "0xF5220E-0xF52FFF.  It is the SOURCE run that starts on an "
                "instruction: 0xF4EF1C is inside the transcribed routine at "
                "0xF4EF14, and 0xF4EF40's copy begins EIGHT bytes into that "
                "routine's first instruction pair, so no entry point can land on "
                "it.")
    out += wrap("; Entry count: ",
                "36 bytes, from the duplicate's own extent: it starts at the byte "
                "after Table_F4EF38 and the byte after it, 0xF4EF64, opens the "
                "156-byte 0x0E padding run that closes the module.  36 is also "
                "exactly len(0xF4EF14..0xF4EF3F) - 8.")
    out += wrap("; Evidence: ", "at(0xF4EF40, 36) == at(0xF4EF1C, 36), re-read "
                "and compared on every emit.")
    out += wrap("; Unknown: ", "how it got here.  A build that emitted a routine "
                "twice and a link that dropped the first eight bytes of the "
                "second copy would produce exactly this; so would a hand-patched "
                "object.  Nothing in the ROM decides between them.")
    out.append("; " + "-" * 74)
    out.append("Table_F4EF40:")
    out += byte_rows(DEAD_AT, 0x24, 16)
    return out


def data_block(a, n, lab):
    fn = {0xF48C00: block_F48C00,
          0xF4B7AD: lambda l: block_identity(0xF4B7AD, l),
          0xF4C000: block_dl,
          0xF4C38D: block_ptbl,
          0xF4C3E9: block_bitmask,
          0xF4E5DC: lambda l: block_identity(0xF4E5DC, l),
          0xF4E5FC: block_bitweight,
          0xF4EF2F: block_F4EF2F,
          0xF4EF38: block_F4EF38,
          0xF4EF40: block_F4EF40}.get(a)
    if not fn:
        raise AssertionError("no data block for 0x%06X" % a)
    return fn(lab)


# ------------------------------------------------------------------- checks
FAIL = []


def check(msg, got, want, verbose=True):
    ok = got == want
    if verbose:
        print("  %-70s %-30s %s"
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
    c("LAYOUT ends at 0xF4F000", "0x%06X" % pos, "0x%06X" % HI)
    c("LAYOUT covers 0x7800 bytes", pos - LO, 0x7800)
    # 2. THE CHECK THAT MATTERS: every thunk target is an instruction boundary
    b, th = boundaries(), thunks()
    c("92 thunk slots point into this range", sum(len(v) for v in th.values()), 92)
    c("every thunk target is an instruction boundary of the transcription",
      sorted("0x%06X" % t for t in th if t not in b), [])
    last = max(th)
    c("the LAST thunk target (0x%06X) is on a boundary" % last, last in b, True)
    # 3. every padding run is pure 0x0E, and the raw run's reach back is stated
    for kind, s, n in LAYOUT:
        if kind != "fill":
            continue
        c("0x%06X-0x%06X is %d bytes of 0x0E" % (s, s + n - 1, n),
          (len(at(s, n)), sorted(set(at(s, n)))), (n, [0x0E]))
        run = 0
        while at(s - 1 - run, 1)[0] == 0x0E:
            run += 1
        # ⚠ `ret` IS 0x0E, so the raw run always reaches one byte further back
        # than the padding does.  Where the routine stops and the padding starts
        # is a READING; this states how far back the raw run goes so it is
        # visible rather than hidden.  1 = the closing `ret`, 0 = the segment
        # before is data.
        c("  the raw 0x0E run before 0x%06X reaches back %d byte(s)" % (s, run),
          run in (0, 1), True)
    # 4. the data islands, each one re-read
    c("Table_F48C00 is 'WSA SOUND RAM S0' + 'WSA1' + 6 bytes",
      (ascii_of(0xF48C00, 16), ascii_of(0xF48C10, 4)),
      ("WSA SOUND RAM S0", "WSA1"))
    c("  and its reader is the `lda XIY,0xf48c00` at 0xF48C24",
      text_at(0xF48C24), "lda XIY,0xf48c00")
    c("  and `ld XBC,(0xf48c10)` at 0xF48C2E takes the next four",
      text_at(0xF48C2E), "ld XBC,(0xf48c10)")
    c("  and 0xF48C1A, the byte after it, is thunk slot T_DiskFile_CheckSignature's target",
      sorted("T_%06X" % x for x in th.get(0xF48C1A, [])), ["T_DiskFile_CheckSignature"])
    for a in (0xF4B7AD, 0xF4E5DC):
        c("IdentityMap_%06X is 0..31" % a, list(at(a, 32)), list(range(32)))
        rd = direct_refs(a)
        c("  its reader spells it once, at 0x%06X" % (rd[0] if rd else 0),
          len(rd), 1)
        # ⚠ the instruction START comes from the transcription, never from a-1:
        # `ld XIX,imm32` is a 1-byte opcode but `add XWA,imm32` is 2, and the
        # first draft of this file cited two readers one byte early because of it.
        ia, it = reader(rd[0])
        c("  and its reader instruction is `%s`" % it,
          it.endswith("0x00%06x" % a), True)
        c("  ...whose operand field starts %d byte(s) in" % (rd[0] - ia),
          rd[0] - ia in (1, 2), True)
    for nm, a in (("BitWeight_F4E5FC", 0xF4E5FC),
                  ("ScreenButtonHandlers_CreatorSelectController", PTBL_AT),
                  ("BitMask_F4C3E9", 0xF4C3E9),
                  ("Table_F4EF38", 0xF4EF38)):
        r0 = direct_refs(a)[0]
        ia, it = reader(r0)
        c("%s's reader instruction is `%s`" % (nm, it),
          it.endswith("0x00%06x" % a), True)
        c("  ...and the header cites 0x%06X, not 0x%06X" % (ia, r0 - 1),
          reader_line(r0).count("0x%06X" % ia), 1)
    c("BitWeight_F4E5FC is 1<<k for k = 0..15",
      [int.from_bytes(at(0xF4E5FC + 2 * i, 2), "little") for i in range(16)],
      [1 << i for i in range(16)])
    c("  and exactly one site spells it", len(direct_refs(0xF4E5FC)), 1)
    recs, end = dl_records()
    c("DL_F4C000's own length bytes walk onto ScreenButtonHandlers_CreatorSelectController",
      "0x%06X" % end, "0x%06X" % PTBL_AT)
    c("  in %d records" % len(recs), len(recs), 81)
    c("  and nothing spells 0xF4C000 as a 32-bit word",
      len(direct_refs(DL_AT)), 0)
    ps = ptrs()
    c("ScreenButtonHandlers_CreatorSelectController's %d entries are all prom_b addresses" % PTBL_N,
      sorted(set("0x%06X" % p for p in ps if not 0xF00000 <= p <= 0xFFFFFF)), [])
    c("  the word one entry past the table is NOT a prom_b address",
      0xF00000 <= int.from_bytes(at(PTBL_AT + 4 * PTBL_N, 4), "little") <= 0xFFFFFF,
      False)
    c("  its three non-default targets are instruction boundaries",
      sorted("0x%06X" % p for p in set(ps) - {0xF42C70} if p not in b), [])
    c("  and exactly one site spells the table", len(direct_refs(PTBL_AT)), 1)
    c("BitMask_F4C3E9 is 0x00 then 1<<(k-1)", list(at(0xF4C3E9, 9)),
      [0] + [1 << k for k in range(8)])
    c("  and 0xF4C3F2, the byte after it, is a thunk target", 0xF4C3F2 in th, True)
    c("Table_F4EF38's reader is `ld XIX,0x00f4ef38` at 0xF4EDF5",
      text_at(0xF4EDF5), "ld XIX,0x00f4ef38")
    c("  bounded by the `and A,0x07` at 0xF4EDF0", text_at(0xF4EDF0), "and A,0x07")
    c("  and `ld IY,WA` at 0xF4EDF3 makes that the index",
      text_at(0xF4EDF3), "ld IY,WA")
    c("Table_F4EF40 is byte-identical to 0x%06X-0x%06X"
      % (DEAD_SRC, DEAD_SRC + 0x23), at(DEAD_AT, 0x24), at(DEAD_SRC, 0x24))
    c("  and nothing spells 0xF4EF40, 0xF4EF53 or 0xF4EF5C",
      sum(len(direct_refs(x)) for x in (0xF4EF40, 0xF4EF53, 0xF4EF5C)), 0)
    c("  its first byte decodes as a jump into the 0xF5220E padding run",
      at(DEAD_AT, 3) == bytes([0x7A, 0x20, 0x3F])
      and sorted(set(at(0xF5220E, 0xDF2))) == [0x0E], True)
    # 5. label hygiene -- the checks that caught real defects in round 2
    lab_ = labels()
    for a_, why in FORCE.items():
        c("FORCE 0x%06X: boundary, reason, and IN the label set" % a_,
          (a_ in b, bool(why), a_ in lab_), (True, True, True))
    c("every DATA label is in the label set",
      sorted("0x%06X" % x for x in DATA_LABEL if x not in lab_), [])
    c("every CURATED address is in the label set",
      sorted("0x%06X" % x for x in CURATED if x not in lab_), [])
    dataspan = [(s, s + n) for k, s, n in LAYOUT if k in ("data", "fill")]
    c("no code label falls inside a data or fill segment",
      sorted("0x%06X" % a_ for a_ in lab_ if a_ not in DATA_LABEL
             and any(s <= a_ < e for s, e in dataspan)), [])
    # every label must be EMITTABLE: emit() attaches a label only when its
    # address is a line of the transcription, so a label that is not an
    # instruction boundary is SILENTLY DROPPED and the byte gate stays green.
    codespan = [(s_, s_ + n_) for k_, s_, n_ in LAYOUT if k_ == "code"]
    c("every non-data label is an instruction boundary",
      sorted("0x%06X" % x for x in lab_ if x not in DATA_LABEL and x not in b), [])
    c("every non-data label is inside a code segment",
      sorted("0x%06X" % a_ for a_ in lab_ if a_ not in DATA_LABEL
             and not any(s_ <= a_ < e_ for s_, e_ in codespan)), [])
    c("every data label is the START of a data segment",
      sorted("0x%06X" % a_ for a_ in DATA_LABEL
             if not any(k == "data" and s == a_ for k, s, _ in LAYOUT)), [])
    if verbose:
        print("\n%s (%d failed)" % ("CHECKS PASS" if not FAIL else "CHECKS FAIL",
                                    len(FAIL)))
    return not FAIL


BANNER = """
; ==============================================================================
; 0xF47800-0xF4EFFF -- EIGHT MODULES AT THE HEAD OF THE 0x047800 `.incbin` SPAN
;   92 thunk slots, including six of prom_b's ten most-referenced unconverted
;   targets, converted as one contiguous block
; ==============================================================================
;
; WHY THIS BLOCK.  notes/prom_b_call_graph.py ranks the unconverted thunk SLOTS
; of the whole image by an opcode-anchored reference upper bound.  Of the ELEVEN
; unconverted slots at x13 or more, EIGHT pointed here -- 0xF4E56F (x24),
; 0xF4D01D (x21), 0xF4D0DB (x18), 0xF4D02C (x15), 0xF4E524 (x14), 0xF4D0FB (x14),
; 0xF48580 (x13), 0xF48464 (x13) -- all inside this one `.incbin` span.
; ⚠ That is a THRESHOLD, not "N of the top ten": two slots tie at x13, two at x14
; and two at x15, so a top-N phrasing would depend on how the sort broke the ties.
; notes/prom_b_round3_frontier_delta.py re-derives both 11 and 8 from the ROM and
; asserts the threshold is tie-free.  notes/prom_b_module_frontier.py ranks whole
; RUNS, and the span holds nine of them; the eight modules converted here own 92
; thunk slots between them, the largest single-span slot count left in prom_b.
;
; ⚠ WHERE THE BOUNDARIES COME FROM.  notes/prom_a_linear_decode_check.py's
; warning applies: a TLCS-900 linear decode resynchronises within a couple of
; instructions, so "it decodes cleanly" pins nothing.  Every segment edge here is
; the `.incbin`'s own start, the first byte of a maximal 0x0E run whose purity is
; re-read on every emit, a THUNK TARGET, or an address a decoded instruction of
; this transcription names.  The split itself came from
; notes/prom_b_module_trace.py 0xF47800 0xF55000 -- a recursive descent from the
; span's 103 thunk entry points -- and every run it never reached was read by
; hand before being called code or data.
;
; LAYOUT.  Eight code modules, each closed by a run of 0x0E (`ret`) padding:
;   0xF47800-0xF487E9  code     0xF487EA-0xF48BFF  1,046 bytes of padding
;   0xF48C00-0xF48C19  data     Table_F48C00
;   0xF48C1A-0xF494B7  code     0xF494B8-0xF497FF    840 bytes of padding
;   0xF49800-0xF4B7AC  code     0xF4B7AD-0xF4B7CC  IdentityMap_F4B7AD
;                               0xF4B7CD-0xF4BFFF  2,099 bytes of padding
;   0xF4C000-0xF4C3F1  data     DL_F4C000, ScreenButtonHandlers_CreatorSelectController, BitMask_F4C3E9
;   0xF4C3F2-0xF4C735  code     0xF4C736-0xF4C7FF    202 bytes of padding
;   0xF4C800-0xF4CB5A  code     0xF4CB5B-0xF4CFFF  1,189 bytes of padding
;   0xF4D000-0xF4D949  code     0xF4D94A-0xF4DFFF  1,718 bytes of padding
;   0xF4E000-0xF4E5DB  code     0xF4E5DC-0xF4E61B  IdentityMap_F4E5DC,
;                                                  BitWeight_F4E5FC
;                               0xF4E61C-0xF4EBFF  1,508 bytes of padding
;   0xF4EC00-0xF4EF2E  code     0xF4EF2F-0xF4EF63  Table_F4EF2F / _F4EF38 /
;                                                  _F4EF40
;                               0xF4EF64-0xF4EFFF    156 bytes of padding
;
; THE DATA, AND WHAT IT IS
;
;   0xF48C00  Table_F48C00 -- 'WSA SOUND RAM S0', then 'WSA1', then six bytes.
;             The routine at the very next address copies the first sixteen to a
;             stack frame with `ldirw` and the next four with `ld XBC,(...)`.
;             The island's END is 0xF48C1A, the target of thunk slot T_DiskFile_CheckSignature, so
;             it is pinned by an entry point the hardware uses, not by a reading.
;
;   0xF4C000  DL_F4C000 -- 81 UI display-list records.  Their own length bytes
;             walk from 0xF4C000 onto 0xF4C38D exactly, which is where the
;             pointer table starts; that walk IS the record count's proof and it
;             is re-run on every emit.  Nothing spells 0xF4C000 as a 32-bit word,
;             so the list's caller is not established and the records are emitted
;             as framed `.byte` rows rather than rendered.
;
;   0xF4C38D  ScreenButtonHandlers_CreatorSelectController -- 23 pointers, 19 of them the default thunk
;             stub 0x00F42C70.
;
;   0xF4B7AD / 0xF4E5DC  two more IDENTITY MAPS, 32 bytes of 0..31 each, joining
;             the one at 0xF5EE75 that round 2 converted.  Three copies is a fact
;             recorded here, not an explanation.
;
;   0xF4EF40  Table_F4EF40 -- 36 bytes byte-identical to 0xF4EF1C-0xF4EF3F, with
;             no reference anywhere in either ROM.  Decoded as code its first
;             byte is `jrl GT,0xF52E63`, a jump into a padding run.  Dead
;             duplicate, recorded and not explained.
;
; ⚠ WHAT IS NOT ESTABLISHED.  What any of the eight modules is FOR.  Every
; routine here is `sub_XXXXXX` with a computed header claiming only its entry
; point and what it touches, per this tree's rule that a stated gap beats a
; plausible guess.
;
; ⚠ WHAT IS LEFT.  0xF4F000-0xF54FFF stays `.incbin`.
; notes/prom_b_module_trace.py reaches NONE of 0xF4EF14-0xF53019: those modules
; have no thunk slot pointing at them, so a code/data split there would rest on a
; linear decode, which this tree does not accept as a boundary argument.
;
; REGENERATE:  python3 notes/gen_prom_b_f47800_module.py
; CHECKS:      python3 notes/gen_prom_b_f47800_module.py --checks
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
        tot = {"code": 0, "data": 0, "fill": 0}
        for kind, s, n in LAYOUT:
            print("  %-4s 0x%06X-0x%06X  %6d" % (kind, s, s + n - 1, n))
            tot[kind] += n
        print("  ---- code %d  data %d  fill %d  (substantive %d of %d)"
              % (tot["code"], tot["data"], tot["fill"],
                 tot["code"] + tot["data"], sum(tot.values())))
        return 0
    if "--records" in sys.argv:
        recs, end = dl_records()
        for a, op, n in recs:
            print("  %06X  op 0x%02X  len %3d  |%s|" % (a, op, n, ascii_of(a + 2, n - 2)))
        print("  %d records, walk ends at 0x%06X" % (len(recs), end))
        return 0
    if not checks(verbose=False):
        checks()
        raise SystemExit("refusing to emit: a check failed (see above)")
    print("\n".join(emit()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
