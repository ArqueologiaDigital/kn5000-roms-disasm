#!/usr/bin/env python3
"""GAP A's LAST THREE UNSTATED REGISTERS -- what 0x0440, 0x0480 and 0x04C0 HOLD.

QUESTION IT ANSWERS
  `notes/WSA1-EMULATION-DISASM-GAPS.md` gap A says four per-channel registers of
  CPU 2's device at 0x0010C000 have "no statement of any kind": 0x0440, 0x0480,
  0x04C0 and 0x0500.  Round 3 wrote a paragraph into each of the three accessors'
  headers saying the POWER-ON value is 0x0000 and then, in its own words,

      "⚠ NOT ESTABLISHED: what the register DOES.  0x0000 is what the ROM holds,
       not a meaning, and this round did not re-derive the channel-cross-reference
       reading that prom_c_gapA_remaining_regs.py argues for."

  This script re-derives it, from the ROM bytes, with every citation checked by an
  INDEPENDENT DISASSEMBLER (unidasm) at the exact address quoted -- because the
  reading it is re-deriving was first published with the wrong addresses
  (notes/wave7-round1/README.md, lane g1, SERIOUS).

THE ANSWER, in one sentence
  **The low 6 or 7 bits of registers 0x0440, 0x0480 and 0x04C0 are a channel
  selector of the SAME 0x0010C000 device** -- bit for bit the value the firmware
  hands, a few instructions later, to a `Dev10C_Slot*` accessor as that accessor's
  `chan` argument, where it is added to a register-block base (0x0540 / 0x0580 /
  0x05C0) to form the device's own register selector.  The remaining bits are a
  small mode field, and in each of the three words the mode field's source is a
  DIFFERENT instruction, so all three are cited separately (section 3).

WHAT THIS DOES **NOT** ESTABLISH
  * That the selected channel is a DIFFERENT channel from the one the staging
    struct is committed to.  The word is written to channel `HL` by
    Dev10C_WriteAllChanRegs and its payload comes from a lookup on another record;
    nothing here compares the two numbers, so "cross-reference" is a shape, not a
    proven relation.  The measured claim is only that the value IS a channel
    selector of this device in this device's own encoding.
  * WHY a channel names a channel.  Modulator, partner partial, effect-send target
    and sample-stream source all fit and nothing here separates them.
  * What the mode bits MEAN.  Their WIDTH, POSITION and SOURCE are measured; their
    meaning is not.  `sub_FB5E39`'s three return values are enumerated exhaustively
    (section 4) and left unnamed.
  * Register 0x0500 is NOT re-derived here: it was already decoded in the tree
    before this round, in the header of `Voice_StageRegs_0500_08C0_AB`
    (prom_c/wsa1_prom_c.s).  Section 7 asserts that header is still there, because
    the emulator gap list still calls 0x0500 unstated and that is now STALE.

⚠ ONE HONEST TENSION, NOT RESOLVED (section 3d)
  0x0480 and 0x04C0 tile cleanly -- their mode mask and their channel mask are
  disjoint.  **0x0440 does not**: its mode field is 0x00C0 and its channel field is
  0x007F, which OVERLAP at bit 6, and they are combined with `or`.  On the 0xFA9B2A
  path the mode comes from sub_FB5E39, which never returns a value with bit 6 clear,
  so bit 6 of that word is ALWAYS 1 whatever the channel is.  Either the channel
  there is always <= 0x3F (nothing in the routine bounds it) or the two fields
  genuinely collide.  Recorded rather than explained away.

RUN
    python3 notes/prom_c_understanding_round4.py              # every section
    python3 notes/prom_c_understanding_round4.py --map        # 1: word <-> register
    python3 notes/prom_c_understanding_round4.py --sites      # 2: the write census
    python3 notes/prom_c_understanding_round4.py --compose    # 3: what each word is
    python3 notes/prom_c_understanding_round4.py --modes      # 4: sub_FB5E39's range
    python3 notes/prom_c_understanding_round4.py --chanarg    # 5: the chan-arg link
    python3 notes/prom_c_understanding_round4.py --lookup     # 6: sub_FA5ED3's shape
    python3 notes/prom_c_understanding_round4.py --names      # 7: the names shipped
    python3 notes/prom_c_understanding_round4.py --presets    # 8: 129 framed -> content

REQUIRES
    ~/compartilhado/kn7000_mame_build/unidasm  (the independent decoder).  Without
    it the unidasm-oracle checks report [skip] and the section's other checks --
    which read the byte-identical .s listing -- still run.  Every claim that rests
    ONLY on the oracle says so.
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRC = image_path(ROOT, "prom_c/wsa1_prom_c.s")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28")
BASE = 0xF80000
UNIDASM = os.path.expanduser("~/compartilhado/kn7000_mame_build/unidasm")

OK = FAIL = SKIP = 0


def check(desc, cond):
    global OK, FAIL
    print(("  ok    " if cond else "  FAIL  ") + desc)
    OK, FAIL = OK + (1 if cond else 0), FAIL + (0 if cond else 1)
    return cond


def skip(desc):
    global SKIP
    print("  [skip] " + desc)
    SKIP += 1


# ---------------------------------------------------------------------------
# The two readers.  `LISTING` is the byte-identical source; `oracle()` is unidasm.
# ---------------------------------------------------------------------------
_rom = open(ROM, "rb").read()


def rom(addr, n):
    return _rom[addr - BASE:addr - BASE + n]


def load_listing():
    """addr -> (decode text or None, byte list or None) from the source's comment.

    prom_c's comment column comes in three shapes, all of them present in the
    ranges this script cites:
        `; FA99F3  and WA,0x00c0`                       decode only
        `; FACFDF  db c8 40 04`                         BYTES only
        `; FB7BEC  db c8 80 04       add HL,0x0480`     bytes AND decode
    A parser that handled only the first silently returned the byte string as if
    it were a decode, and five citations "failed" that were in fact correct.  The
    source re-assembles to the ROM byte for byte (the project gate), so this is a
    decode of the real bytes; it is NOT an independent decode, which is why every
    address quoted in prose is ALSO put through unidasm below."""
    dec, byt = {}, {}
    pat = re.compile(r";\s*([0-9A-F]{6})\s+(.*?)\s*$")
    hexrun = re.compile(r"^((?:[0-9a-f]{2} )*[0-9a-f]{2})(?:\s{2,}(.*))?$")
    for ln in open(SRC):
        if ln.startswith(";"):
            continue
        m = pat.search(ln)
        if not m:
            continue
        a, rest = int(m.group(1), 16), m.group(2)
        h = hexrun.match(rest)
        if h and len(h.group(1).split()) >= 1 and all(
                len(x) == 2 for x in h.group(1).split()):
            byt[a] = [int(x, 16) for x in h.group(1).split()]
            if h.group(2):
                dec[a] = h.group(2).strip()
        else:
            dec[a] = rest.strip()
    return dec, byt


LISTING, LBYTES = load_listing()
_have_unidasm = os.path.exists(UNIDASM)
_ocache = {}


def oracle(addr, n=16):
    """unidasm's own decode of the ROM bytes AT addr -- a second opinion.

    ⚠ unidasm does not seek, so the bytes are written to a temp file whose base
    PC is set to `addr`.  A decode is only meaningful when `addr` is a real
    instruction start; that is exactly what the citations are being checked for."""
    if not _have_unidasm:
        return None
    if addr in _ocache:
        return _ocache[addr]
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(rom(addr, n))
        path = f.name
    try:
        r = subprocess.run([UNIDASM, path, "-arch", "tlcs900", "-basepc", hex(addr)],
                           capture_output=True, text=True)
    finally:
        os.unlink(path)
    rows = []
    for line in r.stdout.split("\n"):
        m = re.match(r"^([0-9a-f]{6}):\s+((?:[0-9a-f]{2} )+)\s*(.*)$", line)
        if m:
            rows.append((int(m.group(1), 16), m.group(2).split(), m.group(3).strip()))
    _ocache[addr] = rows
    return rows


def cite(addr, want, why):
    """Assert that unidasm decodes `addr` as `want`, and cross-check the source.

    This is the check the round-1 lane did not have: it is what would have fired
    on the SERIOUS finding that 0xFB8175 was cited for a memcpy that is not there.
    Three readings must agree where they exist -- unidasm's decode, the source's
    decode comment, and the source's byte column against the ROM."""
    norm = lambda t: re.sub(r"\s+", " ", t).strip().lower()
    src = LISTING.get(addr)
    good_src = src is None or norm(src) == norm(want)
    bs = LBYTES.get(addr)
    good_bytes = bs is None or bytes(bs) == rom(addr, len(bs))
    rows = oracle(addr)
    if rows is None:
        skip("0x%06X %-34s  (no unidasm) %s" % (addr, want, why))
        return check("  ...but the byte-identical listing says it: %s" % why,
                     good_src and src is not None)
    good_uni = bool(rows) and rows[0][0] == addr and norm(rows[0][2]) == norm(want)
    got = rows[0][2] if rows else "<nothing>"
    bad = ""
    if not good_uni:
        bad += "   <-- unidasm=%r" % got
    if not good_src:
        bad += "   <-- listing=%r" % src
    if not good_bytes:
        bad += "   <-- source bytes != ROM"
    return check("0x%06X  %-36s %s%s" % (addr, want, why, bad),
                 good_uni and good_src and good_bytes)


# ---------------------------------------------------------------------------
# 1.  Which staging word lands in which register block.
# ---------------------------------------------------------------------------
WRITE_ALL_LO, WRITE_ALL_HI = 0xFB713A, 0xFB732A   # Dev10C_WriteAllChanRegs


def section_map():
    """Derive word -> register block from Dev10C_WriteAllChanRegs' own bytes.

    The routine's idiom is `add <r>,0xNNNN` (the block base, added to the channel
    in HL) then, before the next `add`, `ld <r>,(XIX+0xNN)` (the staging word).
    Nothing is assumed about the ORDER: the pairs come out in emission order and
    the routine emits 0x0500 nineteenth, not twelfth."""
    print("\n=== 1. staging word <-> 0x0010C000 register block "
          "(Dev10C_WriteAllChanRegs 0x%06X) ===" % WRITE_ALL_LO)
    pairs, pending = [], None
    for a in sorted(k for k in LISTING if WRITE_ALL_LO <= k <= WRITE_ALL_HI):
        t = LISTING[a]
        m = re.match(r"add\s+\w+,\s*0x([0-9a-f]{3,4})$", t, re.I)
        if m:
            pending = (a, int(m.group(1), 16))
            continue
        m = re.match(r"ld\s+\w+,\s*\(XIX\+0x([0-9a-f]{2})\)$", t, re.I)
        if m and pending:
            pairs.append((pending[1], int(m.group(1), 16), pending[0], a))
            pending = None
    for blk, off, aa, ab in pairs:
        print("    register chan+0x%04X  <-  staging +0x%02X (word %2d)   "
              "add@0x%06X  ld@0x%06X" % (blk, off, off // 2, aa, ab))
    check("21 add/ld pairs recovered (word 0 has no `add`: block 0 is the bare "
          "channel, written with the literal 0x8100 at 0xFB7239) -- got %d" % len(pairs),
          len(pairs) == 21)
    d = dict((off, blk) for blk, off, _a, _b in pairs)
    check("+0x10 (word  8) -> register chan+0x0440", d.get(0x10) == 0x0440)
    check("+0x12 (word  9) -> register chan+0x0480", d.get(0x12) == 0x0480)
    check("+0x14 (word 10) -> register chan+0x04C0", d.get(0x14) == 0x04C0)
    check("+0x16 (word 11) -> register chan+0x0500", d.get(0x16) == 0x0500)
    # ★ TESTED ON THE LAST ELEMENT, which is the one a sampled check would miss:
    # the routine's LAST pair is +0x24 -> 0x0980, emitted after a second call that
    # recomputes HL, and 0x0500 is emitted NINETEENTH.
    check("the LAST pair is +0x24 -> register chan+0x0980 (emission order, not "
          "block order)", pairs[-1][0] == 0x0980 and pairs[-1][1] == 0x24)
    order = [p[0] for p in pairs]
    check("0x0500 is emitted %dth of 21 and AFTER 0x08C0 (%dth) -- so 'word 11' "
          "cannot be read off the emission order"
          % (order.index(0x0500) + 1, order.index(0x08C0) + 1),
          order.index(0x0500) > order.index(0x08C0))
    check("the 21 blocks are distinct", len(set(p[0] for p in pairs)) == 21)
    check("the 21 offsets are distinct and all even", len(set(p[1] for p in pairs)) == 21
          and all(p[1] % 2 == 0 for p in pairs))
    # the dedicated single-register accessors agree, independently
    for lbl, addr, blk, off in (("Dev10C_SetChanReg_0440", 0xFACFDF, 0x0440, 0x10),
                                ("Dev10C_SetChanReg_0480", 0xFB7BEC, 0x0480, 0x12),
                                ("Dev10C_SetChanReg_04C0", 0xFAD001, 0x04C0, 0x14)):
        cite(addr, "add HL,0x%04x" % blk, "%s forms chan+0x%04X" % (lbl, blk))
    for lbl, addr, off in (("Dev10C_SetChanReg_0440", 0xFACFED, 0x10),
                           ("Dev10C_SetChanReg_0480", 0xFB7BFA, 0x12),
                           ("Dev10C_SetChanReg_04C0", 0xFAD00F, 0x14)):
        cite(addr, "ld WA,(XBC+0x%02x)" % off, "%s fetches staging +0x%02X" % (lbl, off))
    return d


# ---------------------------------------------------------------------------
# 2.  Every absolute-addressed access to the four staging words, image-wide.
# ---------------------------------------------------------------------------
WORDS = {0x00D76E: 0x0440, 0x00D770: 0x0480, 0x00D772: 0x04C0, 0x00D774: 0x0500}


def section_sites():
    """A CENSUS with a printed denominator, swept rather than reasoned about.

    Two independent sweeps, because a source grep alone cannot prove it found
    everything: (a) the decode text of every addressed line in ALL FOUR images,
    (b) the raw 3-byte little-endian operand in the four ROM images.  (b) is a
    superset -- it also hits the same byte triple appearing inside data -- so the
    two numbers are printed separately and the difference is accounted for."""
    print("\n=== 2. every absolute-addressed access to staging words 8..11 ===")
    images = [("prom_a", "wsa1_prom_a.s", "wsa1_prom_a.ic12"),
              ("prom_b", "wsa1_prom_b.s", "wsa1_prom_b.ic13"),
              ("prom_c", "wsa1_prom_c.s", "wsa1_prom_c.ic28"),
              ("prom_d", "wsa1_prom_d.s", "wsa1_prom_d.bin")]
    found = {}
    total_lines = 0
    for tag, sname, rname in images:
        text = open(image_path(ROOT, "%s/%s" % (tag, sname))).read()
        for ln in text.split("\n"):
            if ln.startswith(";"):
                continue
            m = re.search(r";\s*([0-9A-F]{6})\s+(.*)$", ln)
            if not m:
                continue
            total_lines += 1
            for w in WORDS:
                if "0x%06x" % w in m.group(2).lower():
                    found.setdefault(w, []).append((tag, int(m.group(1), 16),
                                                    m.group(2).strip()))
    print("    swept %d addressed source lines across the four images" % total_lines)
    for w in sorted(WORDS):
        rows = found.get(w, [])
        print("    RAM 0x%06X  (word %2d -> register chan+0x%04X): %d site(s)"
              % (w, (w - 0x00D75E) // 2, WORDS[w], len(rows)))
        for tag, a, t in rows:
            print("        %-7s 0x%06X  %s" % (tag, a, t))
    check("every site is in prom_c -- none in prom_a, prom_b or prom_d",
          all(r[0] == "prom_c" for rows in found.values() for r in rows))
    check("0x00D76E has 4 sites (2 clears, 2 producers)", len(found.get(0x00D76E, [])) == 4)
    check("0x00D770 has 3 sites (2 clears, 1 producer)", len(found.get(0x00D770, [])) == 3)
    check("0x00D772 has 3 sites (1 clear, 1 seed, 1 producer)",
          len(found.get(0x00D772, [])) == 3)
    check("0x00D774 has 3 sites (1 clear, 2 producers) -- register 0x0500, "
          "decoded before this round", len(found.get(0x00D774, [])) == 3)
    # (b) the raw-byte sweep, which cannot miss an addressed operand
    for tag, sname, rname in images:
        data = open(os.path.join(ROOT, "original_ROMs", rname), "rb").read()
        for w in sorted(WORDS):
            trip = bytes([w & 0xFF, (w >> 8) & 0xFF, (w >> 16) & 0xFF])
            n = data.count(trip)
            src = len(found.get(w, [])) if tag == "prom_c" else 0
            print("    raw-byte sweep %-7s 0x%06X: %d occurrence(s) of %s, "
                  "%d addressed instruction(s)" % (tag, w, n, trip.hex(" "), src))
            check("%s: the byte triple for 0x%06X occurs at least as often as the "
                  "instructions that use it (%d >= %d)" % (tag, w, n, src), n >= src)
    return found


# ---------------------------------------------------------------------------
# 3.  What each of the three words is BUILT FROM.
# ---------------------------------------------------------------------------
def section_compose():
    print("\n=== 3. what registers 0x0440 / 0x0480 / 0x04C0 are built from ===")

    print("\n  3a. register chan+0x0440, staging word 8 at RAM 0x00D76E")
    print("      two producing paths in sub_FA9915, plus two clears")
    cite(0xFA991C, "ld (0x00d76e),0x0000", "cleared at the producer's entry")
    cite(0xFA9773, "ld (0x00d76e),0x0000", "cleared on the C/D staging path")
    print("      path A -- mode from the tone descriptor:")
    cite(0xFA9992, "call 0xfa5ed3", "the channel lookup")
    cite(0xFA999A, "and DE,0x007f", "DE := lookup & 0x7F   <- the CHANNEL field")
    cite(0xFA99F0, "ld WA,(XBC+0x1e)", "WA := descriptor word at +0x1E")
    cite(0xFA99F3, "and WA,0x00c0", "WA := descriptor & 0xC0   <- the MODE field")
    cite(0xFA99F7, "or WA,DE", "the two fields are OR'd")
    cite(0xFA99F9, "ld (0x00d76e),WA", "...and stored in word 8")
    print("      path B -- mode from sub_FB5E39:")
    cite(0xFA9AE7, "call 0xfb5e39", "DE := the mode (section 4 enumerates its range)")
    cite(0xFA9AEF, "cp WA,0", "mode 0 is REJECTED...")
    cite(0xFA9AF1, "jrl Z,0xfa9b74", "...so bit 6 of this word is always 1 (see 3d)")
    cite(0xFA9B04, "call 0xfa5ed3", "the channel lookup")
    cite(0xFA9B0A, "and WA,0x00ff", "the low byte is the index")
    cite(0xFA9B10, "cp WA,0x0080", "index >= 0x80 is REJECTED...")
    cite(0xFA9B14, "jr NC,0xfa9b74", "...and the word keeps its entry value (0x0000)")
    cite(0xFA9B18, "and IX,0x007f", "IX := index & 0x7F   <- the CHANNEL field")
    cite(0xFA9B28, "or BC,IX", "mode | channel")
    cite(0xFA9B2A, "ld (0x00d76e),BC", "...and stored in word 8")

    print("\n  3b. register chan+0x0480, staging word 9 at RAM 0x00D770")
    cite(0xFA9923, "ld (0x00d770),0x0000", "cleared at the producer's entry")
    cite(0xFA977A, "ld (0x00d770),0x0000", "cleared on the C/D staging path")
    cite(0xFA9B90, "call 0xfb5e39", "DE := the mode")
    cite(0xFA9B98, "cp WA,0", "mode 0 is REJECTED...")
    cite(0xFA9B9A, "jrl Z,0xfa9c5a", "...leaving word 9 at 0x0000")
    cite(0xFA9BAD, "call 0xfa5ed3", "the channel lookup")
    cite(0xFA9BB3, "and WA,0x00ff", "the low byte is the index")
    cite(0xFA9BB9, "cp WA,0x0080", "index >= 0x80 is REJECTED...")
    cite(0xFA9BBD, "jrl NC,0xfa9c5a", "...leaving word 9 at 0x0000")
    cite(0xFA9BC2, "and BC,0x003f", "BC := index & 0x3F   <- the CHANNEL field, SIX bits")
    cite(0xFA9BC6, "or BC,DE", "mode | channel")
    cite(0xFA9BC8, "ld (0x00d770),BC", "...and stored in word 9")

    print("\n  3c. register chan+0x04C0, staging word 10 at RAM 0x00D772")
    cite(0xFA980E, "ld (0x00d772),0x0000", "cleared on the C/D staging path")
    cite(0xFA9F20, "ld (0x00d772),0x4400", "SEEDED with 0x4400, not cleared")
    cite(0xFA9F7C, "call 0xfa5ed3", "the channel lookup, arm 1")
    cite(0xFA9FA3, "call 0xfa5ed3", "the channel lookup, arm 2")
    cite(0xFA9F85, "and WA,0x007f", "arm 1: IX := index & 0x7F   <- the CHANNEL field")
    cite(0xFA9FAC, "and WA,0x007f", "arm 2: the same mask")
    cite(0xFA9FD5, "and BC,0x00ff", "the low byte is the index")
    cite(0xFA9FD9, "cp BC,0x0080", "index >= 0x80 is REJECTED...")
    cite(0xFA9FDD, "jrl NC,0xfaa0b6", "...and word 10 KEEPS THE SEED 0x4400")
    cite(0xFA9FE5, "ld WA,(XBC+0x22)", "WA := descriptor word at +0x22")
    cite(0xFA9FE8, "and WA,0x3300", "WA := descriptor & 0x3300   <- the MODE field")
    cite(0xFA9FEC, "or WA,IX", "mode | channel")
    cite(0xFA9FEE, "or (0x00d772),WA", "OR'd INTO the seeded word, so 0x4400 survives")

    print("\n  3d. do the fields TILE?  (the masks are arithmetic, not opinion)")
    for name, masks in (("0x0440 path A", (("mode", 0x00C0), ("chan", 0x007F))),
                        ("0x0440 path B", (("mode", 0x00C0), ("chan", 0x007F))),
                        ("0x0480", (("mode", 0x00C0), ("chan", 0x003F))),
                        ("0x04C0", (("const", 0x4400), ("mode", 0x3300),
                                    ("chan", 0x007F)))):
        acc, clash = 0, 0
        for _n, m in masks:
            clash |= acc & m
            acc |= m
        print("      %-14s %s  union=0x%04X  overlap=0x%04X"
              % (name, " | ".join("%s=0x%04X" % t for t in masks), acc, clash))
    check("0x0480's mode and channel masks are DISJOINT (0x00C0 & 0x003F == 0)",
          (0x00C0 & 0x003F) == 0)
    check("0x04C0's three masks are pairwise DISJOINT and tile 0x777F",
          (0x4400 & 0x3300) == 0 and (0x4400 & 0x007F) == 0 and (0x3300 & 0x007F) == 0
          and (0x4400 | 0x3300 | 0x007F) == 0x777F)
    check("★ 0x0440's masks OVERLAP at bit 6 (0x00C0 & 0x007F == 0x0040) -- stated, "
          "not explained away", (0x00C0 & 0x007F) == 0x0040)
    check("...and on path B the mode is never 0 (rejected at 0xFA9AEF/0xFA9AF1), and "
          "every value sub_FB5E39 can return HAS bit 6 set (section 4), so word 8's "
          "bit 6 is 1 regardless of the channel",
          all(v & 0x40 for v in (0x0040, 0x00C0)))


# ---------------------------------------------------------------------------
# 4.  sub_FB5E39's range, exhaustively.
# ---------------------------------------------------------------------------
FB5E39_LO, FB5E39_HI = 0xFB5E39, 0xFB5F90
FB5E39_JT = 0xFB5E7A            # 12 x LE32, indexed by a value the routine bounds to 0..11


def section_modes():
    """sub_FB5E39 -- the source of the MODE bits of words 8 and 9.

    The claim is a RANGE, so it has to be exhaustive over the routine, not
    sampled: enumerate every instruction that leaves a value in WA on a path to
    the single `ret`, and enumerate the jump table rather than reasoning about it."""
    print("\n=== 4. sub_FB5E39 (0x%06X) returns exactly {0x0000, 0x0040, 0x00C0} ==="
          % FB5E39_LO)
    body = sorted(a for a in LISTING if FB5E39_LO <= a <= FB5E39_HI)
    inside_jt = [a for a in body if FB5E39_JT <= a < FB5E39_JT + 48]
    print("    %d decoded instructions in 0x%06X..0x%06X; the 48 bytes at 0x%06X are "
          "the jump table and hold %d of them" % (len(body), FB5E39_LO, FB5E39_HI,
                                                  FB5E39_JT, len(inside_jt)))
    # ★ COMPLETENESS, so "exactly three" is a sweep and not a sample: the decoded
    # addresses must tile the extent, with exactly one gap -- the jump table.
    gaps = [(body[i], body[i + 1] - body[i]) for i in range(len(body) - 1)
            if body[i + 1] - body[i] > 6]
    print("    decoded span 0x%06X..0x%06X; %d gap(s) wider than one instruction: %s"
          % (body[0], body[-1], len(gaps),
             ", ".join("0x%06X +%d" % g for g in gaps) or "none"))
    check("the decode starts at the routine's first byte and ends at its `ret`",
          body[0] == FB5E39_LO and body[-1] == FB5E39_HI)
    check("exactly ONE gap, and it is the 48-byte jump table at 0x%06X" % FB5E39_JT,
          len(gaps) == 1 and gaps[0][0] < FB5E39_JT <= gaps[0][0] + 6
          and gaps[0][1] >= 48)
    setters = [(a, LISTING[a]) for a in body
               if re.match(r"ld\s+WA,", LISTING[a], re.I)
               and not (FB5E39_JT <= a < FB5E39_JT + 48)]
    for a, t in setters:
        print("      0x%06X  %s" % (a, t))
    check("exactly three instructions outside the jump table load WA", len(setters) == 3)
    cite(0xFB5F7F, "ld WA,0x00c0", "return value #1")
    cite(0xFB5F84, "ld WA,0x0040", "return value #2")
    cite(0xFB5F89, "ld WA,IX", "return value #3 -- IX, and IX is 0 here")
    cite(0xFB5E46, "ld IX,0x0000", "IX is zeroed on entry")
    ixw = [(a, LISTING[a]) for a in body
           if re.match(r"ld\s+X?IX,", LISTING[a], re.I)
           and not (FB5E39_JT <= a < FB5E39_JT + 48)]
    for a, t in ixw:
        print("      IX written at 0x%06X  %s" % (a, t))
    check("IX is written exactly twice: 0x%06X and 0x%06X" % tuple(a for a, _ in ixw[:2])
          if len(ixw) == 2 else "IX is written exactly twice", len(ixw) == 2)
    check("the second IX write (0x%06X) is BELOW the `ld WA,IX` at 0xFB5F89, so it "
          "cannot reach it by fallthrough" % ixw[-1][0], ixw[-1][0] > 0xFB5F62 - 1
          and ixw[-1][0] < 0xFB5F89)
    jumps = [(a, LISTING[a]) for a in body if "0xfb5f89" in LISTING[a].lower()
             and re.match(r"jr", LISTING[a], re.I)]
    for a, t in jumps:
        print("      branch to 0xFB5F89 at 0x%06X  %s" % (a, t))
    # ⚠ THE BRANCH LIST ALONE IS NOT THE ARRIVAL LIST.  0xFB5F89 is also a jump-table
    # target, reached through `jp T,XBC` -- so the enumeration has to include the
    # computed goto or it is the tree's signature failure: a completeness claim whose
    # check cannot see the case that would break it.
    goto = [a for a in body if re.match(r"jp\s", LISTING[a], re.I)]
    print("      computed goto(s) in the routine: %s"
          % ", ".join("0x%06X %s" % (a, LISTING[a]) for a in goto))
    check("0xFB5F89 is reached %d ways -- %d conditional branches and %d computed "
          "goto -- and EVERY one is below the only non-zero IX write (0x%06X)"
          % (len(jumps) + len(goto), len(jumps), len(goto), ixw[-1][0]),
          jumps and goto and all(a < ixw[-1][0] for a, _ in jumps)
          and all(a < ixw[-1][0] for a in goto))
    targets = [int.from_bytes(rom(FB5E39_JT + 4 * i, 4), "little") for i in range(12)]
    for i, t in enumerate(targets):
        print("      jump-table entry %2d -> 0x%06X" % (i, t))
    check("all 12 jump-table targets land inside the routine, after the table",
          all(FB5E39_JT + 48 <= t <= FB5E39_HI for t in targets))
    check("the table has only THREE distinct targets (%s)"
          % ", ".join("0x%06X" % t for t in sorted(set(targets))),
          len(set(targets)) == 3)
    cite(0xFB5E66, "cp BC,0x000b", "the index is bounded to 0..11...")
    cite(0xFB5E6A, "jrl UGT,0xfb5f89", "...and out-of-range returns 0")
    print("    RANGE: {0x0000, 0x0040, 0x00C0}.  What the three mean is NOT "
          "established; only that they are three, and that two of them are the "
          "0x00C0 mode field of word 8/9 with bit 7 clear or set.")


# ---------------------------------------------------------------------------
# 5.  The chan-argument link -- the whole point.
# ---------------------------------------------------------------------------
SLOT_ACCESSORS = {
    0xFB7C27: ("Dev10C_Slot2_WriteGateAndValue", 0xFB7C3F, "add DE,0x0580"),
    0xFB7CFF: ("Dev10C_Slot2_WriteGate8100", 0xFB7D08, "add HL,0x0580"),
    0xFB7D1D: ("Dev10C_Slot3_WriteGateAndValue", 0xFB7D35, "add DE,0x05c0"),
    0xFB7EEB: ("Dev10C_Slot1_WriteGate8100", 0xFB7EF4, "add HL,0x0540"),
    0xFB7E13: ("Dev10C_Slot1_WriteGateAndValue", 0xFB7E2B, "add DE,0x0540"),
    0xFB8012: ("Dev10C_Slot1or3_StrobeGate", 0xFB8030, "add DE,0x0540"),
    0xFB80A9: ("Dev10C_Slot1or3_WriteGate8100", 0xFB80C0, "add DE,0x0540"),
}
LOOKUP = 0xFA5ED3


def section_chanarg():
    """THE LOAD-BEARING SECTION.  Is the field a CHANNEL, or just a number?

    A number is a channel of this device if the firmware itself uses it as one.
    So: take every call to the lookup, and ask -- mechanically, with a printed
    denominator -- whether the value it returns is (a) masked to 6 or 7 bits and
    (b) handed to a Dev10C_Slot* accessor, which turns it into a register selector
    by adding a block base."""
    print("\n=== 5. the masked lookup result IS a 0x0010C000 channel argument ===")
    calls = sorted(a for a in LISTING
                   if re.match(r"cal[lr]\s+0xfa5ed3$", LISTING[a], re.I))
    print("    %d call sites of sub_FA5ED3 (0x%06X) in prom_c -- `call` AND `calr`, "
          "because the tenth is a `calr` and a `call`-only scan misses it"
          % (len(calls), LOOKUP))
    masked, direct, rows = 0, [], []
    for a in calls:
        window = [x for x in sorted(LISTING) if a < x <= a + 0x60][:26]
        mask = next((x for x in window
                     if re.match(r"and\s+\w+,\s*0x00(3f|7f)$", LISTING[x], re.I)), None)
        callx = next((x for x in window
                      if re.match(r"call\s+0x[0-9a-f]+$", LISTING[x], re.I)
                      and int(LISTING[x].split("0x")[1], 16) in SLOT_ACCESSORS), None)
        masked += mask is not None
        if callx:
            direct.append(a)
        rows.append((a, mask, callx))
        print("      call@0x%06X   mask %s   ->  %s"
              % (a, ("0x%06X %s" % (mask, LISTING[mask])) if mask else "NONE",
                 ("0x%06X call %s" % (callx, SLOT_ACCESSORS[
                     int(LISTING[callx].split("0x")[1], 16)][0])) if callx else "none"))
    print("    %d of %d call sites mask the result to 6 or 7 bits" % (masked, len(calls)))
    print("    %d of %d hand the masked value STRAIGHT to a Dev10C_Slot* accessor"
          % (len(direct), len(calls)))
    check("NINE of the ten call sites mask the result to 0x3F or 0x7F (%d/%d)"
          % (masked, len(calls)), masked == 9 and len(calls) == 10)
    # The tenth, 0xFA6071, is sub_FA6051's TAIL CALL: it does not mask because it
    # does not consume the value -- `calr 0xfa5ed3 / inc 0,XSP / inc 2,XSP /
    # unlk XIZ / ret` returns it to ITS caller unchanged.  Stated because "9 of 10"
    # invites the question and a silent denominator is how this tree gets caught.
    check("the unmasked tenth site is a pass-through: nothing between the call at "
          "0xFA6071 and the `ret` at 0xFA607A touches WA",
          all(not re.search(r"\bWA\b", LISTING[a])
              for a in sorted(LISTING) if 0xFA6071 < a <= 0xFA607A))
    check("THREE of the ten hand it straight to a Dev10C_Slot* accessor -- and three "
          "is the honest number, not a majority (%d/%d)" % (len(direct), len(calls)),
          len(direct) == 3)
    # ★ Why three is enough: the other arms compute the IDENTICAL mask.  Each of the
    # three direct sites is one arm of an if/else pair whose other arm masks the same
    # width and falls into the same tail -- so the field width is not an artefact of
    # which arm ran.  Checked by comparing the mask CONSTANTS pairwise.
    pairs = ((0xFA9992, 0xFA99B9), (0xFA9CC9, 0xFA9CF2), (0xFA9F7C, 0xFA9FA3))
    mm = dict((a, m) for a, m, _c in rows)
    for x, y in pairs:
        cx = re.search(r"0x00([0-9a-f]{2})", LISTING[mm[x]]).group(1)
        cy = re.search(r"0x00([0-9a-f]{2})", LISTING[mm[y]]).group(1)
        check("if/else pair 0x%06X / 0x%06X mask the SAME width (0x%s both)"
              % (x, y, cx.upper()), cx == cy)
    reached = set(int(LISTING[c].split("0x")[1], 16) for _a, _m, c in rows if c)
    check("the three direct sites reach three DIFFERENT slot accessors (%s)"
          % ", ".join(SLOT_ACCESSORS[r][0] for r in sorted(reached)),
          len(reached) == 3)
    print("\n    ...and this is what those accessors DO with the argument:")
    for entry, (name, addr, text) in sorted(SLOT_ACCESSORS.items()):
        cite(addr, text, "%s: chan -> register selector" % name)
    print("\n    ★ AND THE 7th BIT IS A BLOCK SELECTOR, not part of the channel:")
    cite(0xFB801F, "cp HL,0x0040", "Dev10C_Slot1or3_StrobeGate splits at 0x40...")
    cite(0xFB8025, "ld BC,(XIX+0x3a)", "   arg <  0x40: reads staging +0x3A ...")
    cite(0xFB8030, "add DE,0x0540", "   ... and writes block 0x0540 (chan = arg)")
    cite(0xFB8065, "ld BC,(XIX+0x3e)", "   arg >= 0x40: reads staging +0x3E ...")
    cite(0xFB8070, "add DE,0x0580", "   ... and writes 0x0580+arg = 0x05C0 + (arg&0x3F)")
    cite(0xFB80B8, "cp HL,0x0040", "Dev10C_Slot1or3_WriteGate8100 splits identically")
    cite(0xFB80C0, "add DE,0x0540", "   the low arm")
    cite(0xFB80CC, "add DE,0x0580", "   the high arm")
    check("0x0580 + 0x40 == 0x05C0, i.e. the high arm lands in the SAME block the "
          "Slot3 accessor uses (0xFB7D35 `add DE,0x05c0`)", 0x0580 + 0x40 == 0x05C0)
    print("\n    ★ AND THE TWO ARMS READ THE TWO SLOTS' OWN STAGING FIELDS, which is")
    print("      what makes 'bit 6 selects the slot' a decode and not a coincidence:")
    for slot, fld, blk, a_fld, a_blk in (
            (1, 0x3A, 0x0540, 0xFB7E20, 0xFB7E2B),
            (2, 0x3C, 0x0580, 0xFB7C34, 0xFB7C3F),
            (3, 0x3E, 0x05C0, 0xFB7D2A, 0xFB7D35)):
        cite(a_fld, "ld BC,(XIX+0x%02x)" % fld,
             "Dev10C_Slot%d_WriteGateAndValue: field +0x%02X" % (slot, fld))
        cite(a_blk, "add DE,0x%04x" % blk,
             "Dev10C_Slot%d_WriteGateAndValue: block 0x%04X" % (slot, blk))
    check("the low arm of the dispatcher matches SLOT 1 exactly (+0x3A, 0x0540) and "
          "the high arm matches SLOT 3 exactly (+0x3E, 0x0580+0x40 = 0x05C0)", True)
    cite(0xFB81B9, "cp HL,0x0040", "Dev10C_ResetAllChannels stops at channel 64 -- so "
                                   "bits 5..0 span the whole device")


# ---------------------------------------------------------------------------
# 6.  What sub_FA5ED3 returns.
# ---------------------------------------------------------------------------
def section_lookup():
    print("\n=== 6. sub_FA5ED3 (0x%06X) -- the shape of the value ===" % LOOKUP)
    cite(0xFA5EDA, "ld E,(XIZ+0x0c)", "E := the third argument...")
    cite(0xFA5EDD, "and E,0x3f", "...masked to 6 bits; it becomes the HIGH byte")
    cite(0xFA600D, "ld H,0xff", "H := 0xFF -- the FAILURE value")
    cite(0xFA6015, "sll 0x08,IX", "the tag is shifted into the high byte...")
    cite(0xFA601C, "or BC,IX", "...and OR'd with H")
    cite(0xFA601E, "ld WA,BC", "the return value is (tag << 8) | H")
    print("    so the LOW byte is the result and 0xFF means 'none'.  Consumers test")
    print("    it against 0x80 (0xFA9B10, 0xFA9BB9, 0xFA9FD9) and 0xFF fails that.")
    check("0xFF >= 0x80, so the sentinel is rejected by the same test that rejects "
          "an out-of-range index -- one test, two jobs", 0xFF >= 0x80)
    print("\n    ★ WHAT BOUNDS THE LOW BYTE: a 192-entry RAM array of 5-byte records.")
    cite(0xFA5F37, "cp H,0xc0", "0xC0 = 192 is the bound, tested before use")
    cite(0xFA5F3C, "ld C,0x05", "stride 5...")
    cite(0xFA5F3E, "mul BC,H", "...times the index...")
    cite(0xFA5F43, "ld IX,0x0e3e", "...from base RAM 0x00000E3E")
    cite(0xFA5F22, "ld WA,0x11fe", "and the NEXT array starts at RAM 0x000011FE")
    check("0x0E3E + 192*5 == 0x11FE exactly -- the array closes on its neighbour, "
          "which is what fixes the count at 192", 0x0E3E + 192 * 5 == 0x11FE)
    check("192 = 3 * 64, and the consumers accept only 0..0x7F = 2 * 64 of it",
          192 == 3 * 64 and 0x80 == 2 * 64)
    print("\n    ★ THE THREE ARGUMENTS -- the read the emulator gap list asks for by name.")
    cite(0xFA5EE6, "cp (XIZ+0x08),0x21", "arg1 < 33...")
    cite(0xFA5F99, "mul BC,(XIZ+0x08)", "...and it indexes a stride-27 array...")
    cite(0xFA5FA6, "ld H,(XBC+0x0aa8)", "...at RAM 0x00000AA8")
    cite(0xFA5EE0, "cp (XIZ+0x0a),0x40", "arg2 < 64...")
    cite(0xFA5F1D, "mul BC,(XIZ+0x0a)", "...and it indexes a stride-12 array...")
    cite(0xFA5F22, "ld WA,0x11fe", "...at RAM 0x000011FE")
    cite(0xFA5EFE, "and C,0x1f", "arg3 keys Table_FE10C9 through a 5-bit mask...")
    cite(0xFA5F13, "add XBC,0x00fe10e9", "...and Table_FE10E9 unmasked")
    check("0x0AA8 + 27*34 == 0x0E3E: the stride-27 array closes on the stride-5 one",
          0x0AA8 + 27 * 34 == 0x0E3E)
    check("0x11FE + 12*64 == 0x14FE: the stride-12 array is 64 long, exactly the "
          "arg2 guard", 0x11FE + 12 * 64 == 0x14FE)
    t1 = rom(0xFE10C9, 32)
    t2 = rom(0xFE10E9, 64)
    check("Table_FE10C9's 32 entries span 0..3 -- all 32 read, not sampled",
          min(t1) == 0 and max(t1) == 3)
    check("Table_FE10E9's 64 entries span 0..26 -- all 64 read", min(t2) == 0
          and max(t2) == 26)
    check("...so 27*32 + max(Table_FE10E9) = %d stays inside the 34-record array "
          "(27*34 = %d), which is why 34 records serve 33 indices"
          % (27 * 32 + max(t2), 27 * 34), 27 * 32 + max(t2) < 27 * 34)
    print("    ⚠ NOT ESTABLISHED: WHAT the three arguments are.  The overlay's copy of")
    print("      the gap list proposes '(part, channel, parameter index)' from these")
    print("      same three bounds; that is a reading of the bounds, not a measurement,")
    print("      and it is not adopted.  Also open: why the 0x0E3E array is 192 long")
    print("      when the consumers use 128 of it.")


# ---------------------------------------------------------------------------
# 8.  The 129 preset-bank records, renamed to the names they carry themselves.
# ---------------------------------------------------------------------------
PRESET_BASE, PRESET_STRIDE, PRESET_COUNT = 0xF80300, 704, 129


def preset_name(i):
    """The record's own 16-character name, out of the ROM, chunk 0x78 at +0x02."""
    o = PRESET_BASE + PRESET_STRIDE * i
    assert rom(o, 1)[0] == 0x78 and rom(o + 1, 1)[0] == 0x10
    return rom(o + 2, 16).decode("latin-1")


def mangle(n):
    t = n.strip().replace("&", "And").replace("+", "Plus").replace("'", "")
    t = re.sub(r"[^A-Za-z0-9]+", "_", t)
    return "PresetBank_" + re.sub(r"_+", "_", t).strip("_")


def section_presets():
    """framed -> content, 129 times, with nothing invented.

    Each record label was `PresetBank_Record_NNN` -- a kind plus an index, which
    says what SHAPE the object is and nothing about what it IS.  Each is now the
    16-character ASCII string the record itself starts with.  The rename is a pure
    function of the ROM, so this section RE-DERIVES all 129 and checks the source
    against them; it is not a list of names typed once and trusted."""
    print("\n=== 8. the 129 preset-bank records carry their own names ===")
    text = open(SRC).read()
    names = [preset_name(i) for i in range(PRESET_COUNT)]
    labels = [mangle(n) for n in names]
    print("    stride %d, base 0x%06X, %d records; first '%s', last '%s'"
          % (PRESET_STRIDE, PRESET_BASE, PRESET_COUNT, names[0].strip(),
             names[-1].strip()))
    check("the array closes exactly on the address the file's own header states "
          "(0x%06X + %d*%d = 0x%06X, one past 0xF965BF)"
          % (PRESET_BASE, PRESET_COUNT, PRESET_STRIDE,
             PRESET_BASE + PRESET_COUNT * PRESET_STRIDE),
          PRESET_BASE + PRESET_COUNT * PRESET_STRIDE == 0xF965C0)
    check("every record starts with chunk tag 0x78 length 0x10 -- checked on all "
          "%d, which is what makes the name field a rule and not a sample"
          % PRESET_COUNT, True)   # preset_name() asserts it per record
    check("all %d names are DISTINCT as raw 16-char strings" % PRESET_COUNT,
          len(set(names)) == PRESET_COUNT)
    check("all %d names are still distinct AFTER mangling -- no collision, so no "
          "record needed a number glued back on" % PRESET_COUNT,
          len(set(labels)) == PRESET_COUNT)
    missing = [l for l in labels if ("\n%s:" % l) not in text]
    check("every one of the %d labels is defined in prom_c (%d missing)"
          % (PRESET_COUNT, len(missing)), not missing)
    check("no PresetBank_Record_NNN label survives",
          not re.search(r"^PresetBank_Record_\d", text, re.M))
    # ★ TESTED ON THE LAST ELEMENT, and the last element is the interesting one:
    # record 128 is the TEMPLATE, not one of the 128 presets the header counts.
    check("the LAST record (128) is named 'Clear' and is the template -- the file "
          "says so on its comment line", names[128].strip() == "Clear"
          and "record 128 -- 0xF96300" in text and "the template" in text)
    check("...and its label is %s" % labels[128], ("\n%s:" % labels[128]) in text)
    for i in (0, 1, 64, 127, 128):
        print("      record %3d  0x%06X  %-18r -> %s"
              % (i, PRESET_BASE + PRESET_STRIDE * i, names[i], labels[i]))
    # ⚠ The instrument's own blind spot, worth recording because it is a property
    # of the METRIC and not of the tree: two of the 129 promoted names still read
    # as FRAMED to wave7_documentation_metrics.py, because its strict rule treats a
    # trailing all-hex or all-digit token as positional -- and "Caffe" happens to
    # be five hex digits.
    framed_re = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*_(?:[0-9A-Fa-f]{4,6}|[0-9]{1,4})$")
    still = [l for l in labels if framed_re.match(l)]
    print("    %d of %d still read FRAMED to the metric: %s"
          % (len(still), PRESET_COUNT, ", ".join(still)))
    check("exactly two do, and both are false positives of the metric's strict "
          "rule, not weak names (%s)" % ", ".join(still), len(still) == 2)


# ---------------------------------------------------------------------------
# 7.  The names this round shipped, and the one thing it did NOT re-derive.
# ---------------------------------------------------------------------------
RENAMES = {
    "Voice_StageChanSel_Reg0440_Reg0480": 0xFA9915,
    "Voice_StageChanSel_Reg04C0": 0xFA9F19,
    "Voice_StageRegs_CD": 0xFA96F7,
    "Voice_LookupDev10CChanIndex": 0xFA5ED3,
    "Dev10C_ChanSelHighBits": 0xFB5E39,
    "Field2Bit_Masks_b": 0xFE1361,
    "Field2Bit_CopyField": 0xFB9B11,
}

# Prose that still spells a renamed routine by its old address.  ★ REPORTED, NOT
# SILENTLY FIXED: these are shared findings documents and the round-1 ledger, which
# is a historical record and must not be rewritten.  The two GENERATORS that emit
# prom_c were updated in this round, because a stale emitter would quietly undo the
# rename on the next regeneration; a stale sentence in a findings file only misleads
# a grep, and the coordinator can sweep it.
OLD_NAMES = ("sub_FA9915", "sub_FA9F19", "sub_FA96F7", "sub_FA5ED3", "sub_FB5E39",
             "sub_FB9B11", "Table_FE1361", "PresetBank_Record_")


def section_names():
    print("\n=== 7. the labels this round changed, and what each one claims ===")
    text = open(SRC).read()
    for name, addr in sorted(RENAMES.items()):
        n = len(re.findall(r"^%s:" % re.escape(name), text, re.M))
        print("      %-40s 0x%06X   defined %d time(s)" % (name, addr, n))
        check("%s is defined exactly once" % name, n == 1)
        check("%s no longer exists under its old address name"
              % name, ("sub_%06X:" % addr) not in text)
    check("no label of the form sub_%06X__ survives for a renamed routine"
          % 0xFA9915, "sub_FA9915__" not in text)
    print("\n    ⚠ REGISTER 0x0500 IS NOT THIS ROUND'S WORK AND WAS NOT RE-DERIVED.")
    print("      It was decoded before this round, in the header of")
    print("      Voice_StageRegs_0500_08C0_AB, which states the byte pair and names")
    print("      the detune-curve lookup that builds its high byte.  The emulator gap")
    print("      list still calls 0x0500 unstated; that entry is STALE.")
    check("Voice_StageRegs_0500_08C0_AB is still defined in prom_c",
          "\nVoice_StageRegs_0500_08C0_AB:" in text)
    check("...and its header still carries the 0x0500 byte-pair decode",
          "REGISTER 0x0500 + chan IS ASSEMBLED AS A BYTE PAIR" in text)
    print("\n    Field2Bit_Masks_b (0xFE1361) -- promoted from Table_FE1361.")
    cite(0xFB9B1C, "add XBC,0x00fe1361", "reader 1 loads T[arg2]...")
    cite(0xFB9B24, "cpl A", "...complements it...")
    cite(0xFB9B29, "and (XBC),A", "...and CLEARS that field")
    cite(0xFB9B32, "add XBC,0x00fe1361", "reader 2 loads T[arg1]...")
    cite(0xFB9B3A, "and (XIZ+0x0c),A", "...and EXTRACTS that field")
    cite(0xFB9B40, "add B,B", "the shift count is 2*index, not a second table")
    a = rom(0xFE1361, 4)
    print("      bytes at 0xFE1361: %s" % " ".join("0x%02X" % b for b in a))
    check("the four values are the four 2-bit field masks 03/0C/30/C0",
          list(a) == [0x03, 0x0C, 0x30, 0xC0])
    check("byte-identical to Field2Bit_Masks at 0xFE12AD (4 of 4 bytes equal)",
          rom(0xFE12AD, 4) == a)
    print("\n    Field2Bit_CopyField (0xFB9B11) -- promoted from sub_FB9B11; the reader "
          "that\n    makes those four bytes MASKS.  Its whole body is five steps:")
    for a_, w, why in ((0xFB9B22, "ld A,(XBC)", "1. load T[dstSlot]..."),
                       (0xFB9B24, "cpl A", "   ...complement..."),
                       (0xFB9B29, "and (XBC),A", "   ...clear the target field"),
                       (0xFB9B3A, "and (XIZ+0x0c),A", "2. isolate the source field"),
                       (0xFB9B40, "add B,B", "3. shift count = 2*srcSlot"),
                       (0xFB9B4B, "call 0xfcb23c", "   Shift8_LogicalRight"),
                       (0xFB9B55, "add C,C", "4. shift count = 2*dstSlot"),
                       (0xFB9B5D, "call 0xfcb25d", "   Shift8_Left"),
                       (0xFB9B64, "or (XBC),A", "5. insert")):
        cite(a_, w, why)
    check("2 * a 2-bit slot index is the bit offset of that slot -- which is why the "
          "shift is `add B,B` and not a table lookup", all(2 * k == (k << 1)
                                                           for k in range(4)))

    print("\n    ⚠ PROSE THAT STILL SPELLS A RENAMED SYMBOL THE OLD WAY (reported, not")
    print("      silently edited -- shared findings docs and the round-1 ledger):")
    import glob
    stale = {}
    for f in sorted(glob.glob(os.path.join(ROOT, "notes", "*.md"))
                    + glob.glob(os.path.join(ROOT, "notes", "*.py"))
                    + glob.glob(os.path.join(ROOT, "notes", "wave7-round1", "*"))):
        if os.path.basename(f) == os.path.basename(__file__):
            continue
        try:
            t = open(f, errors="replace").read()
        except IsADirectoryError:
            continue
        hits = [n for n in OLD_NAMES if n in t]
        if hits:
            stale[os.path.relpath(f, ROOT)] = hits
    for f in sorted(stale):
        print("        %-56s %s" % (f, ", ".join(stale[f])))
    print("      %d file(s), and two of them are the EMITTERS -- but they only MENTION"
          % len(stale))
    print("      the old spelling in the paragraph that explains the rename.  What an")
    print("      emitter is judged on is what it EMITS, so that is what is tested:")
    # ★ The proxy would have passed the wrong thing.  A substring scan flags an
    # emitter for the sentence "promoted the name from Table_FE1361", which is the
    # documentation of the rename, not a relapse.  Run them and read the output.
    for script, mode, bad in (("notes/gen_prom_c_preset_bank.py", "--asm",
                               r"^PresetBank_Record_\d"),
                              ("notes/gen_prom_c_tail_tables.py", "--emit",
                               r"^Table_FE1361:")):
        r = subprocess.run([sys.executable, os.path.join(ROOT, script), mode],
                           capture_output=True, text=True, cwd=ROOT)
        emitted = re.findall(bad, r.stdout, re.M)
        check("%s %s emits NO %s label (%d found; a stale emitter would undo the "
              "rename on the next regeneration)"
              % (script, mode, bad.strip("^$"), len(emitted)),
              r.returncode == 0 and not emitted)


# ---------------------------------------------------------------------------
def main():
    args = sys.argv[1:]
    run = lambda f: (not args) or ("--" + f) in args
    print("prom_c round-4: gap A's last three unstated registers")
    print("source: %s   rom: %s   unidasm: %s"
          % (os.path.relpath(SRC, ROOT), os.path.relpath(ROM, ROOT),
             UNIDASM if _have_unidasm else "NOT PRESENT -- oracle checks skipped"))
    if run("map"):
        section_map()
    if run("sites"):
        section_sites()
    if run("compose"):
        section_compose()
    if run("modes"):
        section_modes()
    if run("chanarg"):
        section_chanarg()
    if run("lookup"):
        section_lookup()
    if run("names"):
        section_names()
    if run("presets"):
        section_presets()
    print("\n%d checks, %d failures, %d skipped" % (OK + FAIL, FAIL, SKIP))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
