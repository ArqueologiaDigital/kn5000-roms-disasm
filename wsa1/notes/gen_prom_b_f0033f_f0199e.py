#!/usr/bin/env python3
"""Emit the assembly for the two `.incbin` spans prom_b 0xF0033F-0xF007FF and
0xF0199E-0xF01E71 -- FOUR POINTER TABLES, three small byte objects, two 12x16
icons and six 40x40 response-curve bitmaps.

QUESTION IT ANSWERS
  "What is the assembly text for these two spans (1,217 + 1,236 = 2,453 bytes),
   in a form the byte gate accepts -- and what, honestly, is in them?"

────────────────────────────────────────────────────────────────────────────────
★ THE RECORDED REASON THESE SPANS WERE LEFT, AND WHY IT IS OVERTURNED
────────────────────────────────────────────────────────────────────────────────
  Both sit under a `=== COVER-R1 ... ===` banner that says "Everything else here
  is NOT reachable and stays `.incbin`".  That verdict is CORRECT and is not
  disputed: nothing the round-1 walk decoded branches into either span, and the
  scan below confirms it independently -- **0 `call nnn` / `jp nnn` operands in
  all four ROM images land in either span, and 0 routine-directory slots point
  in.**

  What is overturned is the verdict's use as a reason to leave the bytes
  verbatim.  Reachability decides whether a span is CODE.  It does not decide
  whether the span can be TYPED: both of these are DATA, and data is typed from
  what REFERENCES it.  Every object below is bounded by a pointer some other
  part of the firmware holds, or by a grid that such a pointer pins.

  ⚠ The COVER-R1 comments are kept, and REWRITTEN rather than deleted, so the
  round-1 reasoning stays legible next to the reason it no longer blocks.

────────────────────────────────────────────────────────────────────────────────
SPAN 1 -- 0xF0033F-0xF007FF, 1,217 bytes: FOUR TABLES OF 4-BYTE LE POINTERS
────────────────────────────────────────────────────────────────────────────────
      1   0xF0033F            one 0x00 pad, after the `ret` at 0xF0033E
    140   0xF00340-0xF003CB    35 slots -> routines at 0xF01200-0xF014CE
     45   0xF003CC-0xF003F8    three short byte objects, shape NOT established
    724   0xF003F9-0xF006CC   181 slots -> the 0xF78029 bitmap sheet
    140   0xF006CD-0xF00758    35 slots -> prom_a display lists at 0xFC4082+
      9   0xF00759-0xF00761   eight powers of two and a 0x00
    156   0xF00762-0xF007FD    39 slots -> prom_a 0xFE28B2-0xFE2F8C
      2   0xF007FE-0xF007FF   two bytes that complete no slot; NOT identified
  -----
  1,217

  WHY "4-BYTE LE POINTER".  290 consecutive 4-byte little-endian words are each
  either 0x00000000, the repeated sentinel 0x00FDB10E, or an address inside the
  1 MiB CS2 window 0xF00000-0xFFFFFF.  A 24-bit address space is 16 MiB, so a
  random word lands in that window with probability 2**-4 at best; 290 in a row
  is not a coincidence.

  ⚠ NO SINGLE PHASE EXPLAINS THE SPAN, which is why one alignment never fit it:
  scored across the whole span the four byte phases give 222, 51, 42 and 6 of
  ~303.  The span is FOUR runs at THREE different phases, because the byte
  objects at 0xF003CC (45 B) and 0xF00759 (9 B) are both odd-length.

  ⚠ THE PHASE IS NOT CONSTANT, and that is the whole reason this span looked
  structureless.  The byte objects at 0xF003CC (45 bytes) and 0xF00759 (9 bytes)
  are both ODD-length, so each shifts the 4-byte phase of everything after it.
  A parse that assumes one alignment for the span decodes two thirds of it as
  garbage.  --layout prints the four runs.

  0x00FDB10E IS A SENTINEL, NOT A TARGET.  It fills 82 of the 290 slots, and it
  is not an instruction boundary in prom_a's transcription: it lands INSIDE
  `lda xbc,(xiz-12)` at 0xFDB10C (`be f4 31`, three bytes).  It cannot be
  entered and cannot be an object start; it means "absent".  (The tree already
  called it "the default entry" in the 0xF78029 module header; this is the
  first check of what it actually points at.)

  ★ THE TABLE AT 0xF00340 IS A ROUTINE VECTOR TABLE.  25 of its 26 distinct
  targets begin with the byte pair `EE 0C` -- `link XIZ,0x0000`, the standard
  stack-frame prologue, spelled that way 100+ times in prom_a's transcription.
  Null: that pair occurs at 28 of the 744 byte positions in 0xF01200-0xF014E8,
  i.e. 3.8%; a chance agreement of 25 of 26 has probability ~1e-36.  Its target
  block, 0xF01200-0xF014E8, is still `.incbin` (span 0x000C4D+0x000BB3, another
  lane's) -- these 25 addresses are proven entry points for whoever converts it.

  THE TABLE AT 0xF003F9 IS THE ONE THIS TREE ALREADY USES.  It is the index that
  bounds the 121 objects of the bitmap sheet at 0xF78029; see the banner at
  `0xF78029-0xF7A3FF` in the .s and notes/gen_prom_b_f78029_module.py.  Until
  now the tree read it out of the ROM through a still-`.incbin` address.  --
  selftest re-derives the sheet's object starts from the table THIS file emits
  and checks them against the `Bitmap_F7xxxx:` labels in the source.

  THE TABLE AT 0xF006CD points into prom_a's DisplayList_FC4000 (2,095 bytes of
  DSP-effect / SOUND EDIT label text, already converted there).  0 of its 24
  distinct targets is an instruction boundary in prom_a, which is right: the
  region is data there too, and 0 of its 979 addresses is a boundary.

  ⚠ WHAT THE TABLE AT 0xF00762 POINTS AT IS **NOT** ESTABLISHED.  Its 21
  distinct targets lie in prom_a 0xFE28B2-0xFE2F8C, which prom_a's current
  transcription frames as CODE -- but only 6 of the 21 land on an instruction
  boundary there, against 35.7% of all addresses in that range, i.e. BELOW
  chance.  So this table lends prom_a's framing no support, and this file
  claims only that the slots are pointers.  Whether prom_a has that region
  misframed is a question for a prom_a lane, and is left open here.

────────────────────────────────────────────────────────────────────────────────
SPAN 2 -- 0xF0199E-0xF01E71, 1,236 bytes: TWO ICON PAGES AND SIX 40x40 CURVES
────────────────────────────────────────────────────────────────────────────────
     12   0xF0199E-0xF019A9   the LOWER page of the 12x16 icon at 0xF01992
     24   0xF019AA-0xF019C1   one whole 12x16 icon
  1,200   0xF019C2-0xF01E71   six 40x40 bitmaps, 200 bytes each
  -----
  1,236

  ★★ THE SIX 200-BYTE OBJECTS ARE PINNED BY ALREADY-CONVERTED CODE IN THIS FILE.
  0xF5BECE-0xF5BEFA reads

        ld XIZ,0x00f5befb      ; the table base
        xor W,W / sll 0x02,WA  ; index * 4
        ld XIY,(XIZ+WA)        ; XIY = table[index]
        ...
        ld BC,0x0005           ; 5 pages
        ld HL,0x0028           ; 40 columns
        ld A,0x03 / swi 7      ; blit

  5 * 40 = 200, exactly the stride between the seven table entries' six distinct
  targets, and the six objects tile 0xF019C2-0xF01E71 with no gap and no
  remainder.  Rendering each as 5 pages of 40 columns (MSB = top row of a page)
  gives six framed 40x40 boxes each containing one monotone rising curve --
  `--render` prints them.  The shape was NOT assumed: BC and HL come from the
  blitter call, and the boundaries come from the table.

  ⚠ THE TABLE AT 0xF5BEFB IS ITSELF STILL MIS-FRAMED AS CODE, at .s lines
  reading `cp XWA,(XDE+0x1d)` / `nop` / four `[llvm-mc cannot encode this]`
  rows.  It is 28 bytes = 7 * 4 and every word is one of these six addresses.
  It is OUTSIDE both of this lane's spans and is NOT touched here; it is
  reported so the lane that owns it can retype it.

  ★ THE 24-BYTE ICON GRID IS PINNED BY TEN EXTERNAL REFERENCES.  0x00F019AA
  appears as a 32-bit word ten times in the display-list region (0xF03ACF
  0xF03AE7 0xF03AFF 0xF03B17 0xF03B81 0xF03B96 0xF03C1F 0xF03C37 0xF03C4F
  0xF03C67), and 0xF0191A -- the start of Data_F0191A above -- appears six
  times.  0xF019AA - 0xF0191A = 144 = 6 * 24, so the two references agree on a
  24-byte grid, and 0xF019C2 (the first curve) is 0xF0191A + 7 * 24: the grid
  ends exactly where the curves begin.  Rendering a 24-byte cell as 12 columns
  * 2 pages gives a 12x16 icon, and the last two cells are a filled and a
  hollow circle (`--render`).

  ⚠ Data_F0191A above is 132 bytes, which is 5.5 cells: its extent is the
  round-1 REACHABILITY walk's, not an object's, exactly as its own header warns.
  So the icon that starts at 0xF01992 has its upper page inside Data_F0191A and
  its lower page here, and this file labels the lower page for what it is
  rather than pretending the split is an object boundary.  Data_F0191A is NOT
  edited: it belongs to no span and re-cutting it is a separate change.

NOTHING HERE CAN BREAK THE GATE
  Every byte is printed from the ROM.  verify_region() assembles the emitted
  text for each span with llvm-mc and compares all 1,217 / 1,236 bytes against
  the ROM; --splice refuses to write if either differs or if any check fails.

RUN
  python3 notes/gen_prom_b_f0033f_f0199e.py            # both spans' assembly
  python3 notes/gen_prom_b_f0033f_f0199e.py --layout   # the segment table
  python3 notes/gen_prom_b_f0033f_f0199e.py --evidence # every measurement above
  python3 notes/gen_prom_b_f0033f_f0199e.py --render   # the icons and curves
  python3 notes/gen_prom_b_f0033f_f0199e.py --selftest # the checks
  python3 notes/gen_prom_b_f0033f_f0199e.py --splice   # write into the .s
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
from asm_source import image_path, write_part  # noqa: E402

B_BASE, A_BASE = 0xF00000, 0xF80000
R1 = (0xF0033F, 0xF00800)
R2 = (0xF0199E, 0xF01E72)
SENTINEL = 0x00FDB10E
CS2_LO, CS2_HI = 0x00F00000, 0x01000000
SRCB_MASTER = os.path.join(ROOT, "prom_b/wsa1_prom_b.s")
SRCB = image_path(ROOT, "prom_b/wsa1_prom_b.s")
FAIL = []

# The four pointer runs and the byte objects between them.  Offsets are FILE
# offsets into wsa1_prom_b.ic13; they were found by the greedy phase-aware walk
# in --evidence ("segments"), not typed in by hand -- checks() re-runs it.
SEG = [
    ("pad", 0x00033F, 1),
    ("ptr", 0x000340, 140),
    ("byt", 0x0003CC, 45),
    ("ptr", 0x0003F9, 724),
    ("ptr", 0x0006CD, 140),
    ("byt", 0x000759, 9),
    ("ptr", 0x000762, 156),
    ("byt", 0x0007FE, 2),
]


def rom(which="b"):
    n = {"a": "wsa1_prom_a.ic12", "b": "wsa1_prom_b.ic13",
         "c": "wsa1_prom_c.ic28", "d": "wsa1_prom_d.bin"}[which]
    return open(os.path.join(ROOT, "original_ROMs", n), "rb").read()


_rom = {}


def at(addr, n=1, which="b"):
    if which not in _rom:
        _rom[which] = rom(which)
    base = {"a": A_BASE, "b": B_BASE, "c": A_BASE, "d": 0}[which]
    return _rom[which][addr - base: addr - base + n]


def w32(a, which="b"):
    return int.from_bytes(at(a, 4, which), "little")


def is_slot(v):
    return v == 0 or CS2_LO <= v < CS2_HI


# ------------------------------------------------------------------ structure
def segments(lo=R1[0], hi=R1[1], minrun=3):
    """The phase-aware greedy walk that found SEG.  A run of >= `minrun`
    consecutive plausible 4-byte slots opens a pointer table; anything else is
    a byte object, which may be odd-length and so may shift the phase."""
    out, o = [], lo
    while o < hi:
        n = 0
        while o + 4 * (n + 1) <= hi and is_slot(w32(o + 4 * n)):
            n += 1
        if n >= minrun:
            out.append(("ptr", o, 4 * n))
            o += 4 * n
            continue
        s = o
        o += 1
        while o < hi:
            m = 0
            while o + 4 * (m + 1) <= hi and is_slot(w32(o + 4 * m)):
                m += 1
            if m >= minrun:
                break
            o += 1
        out.append(("byt", s, o - s))
    return out


def tables():
    """The pointer runs as (addr, nslots), with the 0xF003F9 run SPLIT at the
    index where its targets stop being bitmap-sheet addresses and start being
    prom_a display-list addresses.  The split is a statement about the TARGETS,
    not about how the firmware indexes them: no reader for either run has been
    found."""
    return [(B_BASE + o, n // 4) for k, o, n in SEG if k == "ptr"]


def slots(addr, n):
    return [w32(addr + 4 * i) for i in range(n)]


def curve_starts():
    return [0xF019C2 + 200 * k for k in range(6)]


def curve_table():
    """The seven entries of the selector at 0xF5BEFB, read from the ROM."""
    return [w32(0xF5BEFB + 4 * i) for i in range(7)]


# ------------------------------------------------------------------ rendering
def render(addr, pages, cols):
    """`pages` pages of `cols` columns; a byte is one column of 8 rows, MSB the
    top row of its page.  This is the format the 0xF5BECE blitter is handed:
    BC = pages, HL = columns."""
    out = []
    for p in range(pages):
        row = at(addr + p * cols, cols)
        for b in range(8):
            out.append("".join("#" if (c >> (7 - b)) & 1 else "." for c in row))
    return out


# ------------------------------------------------------------------ evidence
def phase_scores(lo=R1[0], hi=R1[1]):
    """How many 4-byte words are plausible slots, at each of the four phases."""
    out = []
    for ph in range(4):
        s = lo + ph
        n = t = 0
        while s + 4 <= hi:
            t += 1
            n += is_slot(w32(s))
            s += 4
        out.append((ph, n, t))
    return out


def code_refs(lo, hi):
    """`call nnn` (0x1D) and `jp nnn` (0x1B) whose 24-bit operand lands in
    [lo,hi), at EVERY byte offset of all four images."""
    n = 0
    for k in "abcd":
        d = rom(k)
        for off in range(len(d) - 3):
            if d[off] in (0x1D, 0x1B):
                t = int.from_bytes(d[off + 1:off + 4], "little")
                if lo <= t < hi:
                    n += 1
    return n


def directory_slots(lo, hi):
    """0xF40000-0xF44018 holds `jp nnn` slots; how many jump into [lo,hi)."""
    d = rom("b")
    n = 0
    for off in range(0x40000, 0x44018, 4):
        if d[off] == 0x1B and lo <= int.from_bytes(d[off + 1:off + 4], "little") < hi:
            n += 1
    return n


def word_refs(lo, hi):
    """Every 4-byte LE word in the four images whose value lands in [lo,hi).
    ⚠ prom_c/prom_d are a different CPU's address space, so a hit there is a
    byte coincidence and is reported separately, never as a reference."""
    out = {}
    for k in "abcd":
        d = rom(k)
        hits = []
        for off in range(len(d) - 3):
            if lo <= int.from_bytes(d[off:off + 4], "little") < hi:
                hits.append(off)
        out[k] = hits
    return out


def prom_a_boundaries():
    txt = open(os.path.join(ROOT, "prom_a/wsa1_prom_a.s"), encoding="utf-8").read()
    return set(int(m, 16) for m in re.findall(r"; ([0-9A-F]{6})  ", txt))


def prologue_stat():
    """25 of 26 targets of the 0xF00340 table start `EE 0C` = `link XIZ,0`."""
    tg = sorted(set(slots(0xF00340, 35)) - {0, SENTINEL})
    hit = sum(1 for t in tg if at(t, 2) == b"\xEE\x0C")
    win = at(0xF01200, 0x2E9)
    null = sum(1 for i in range(len(win) - 1)
               if win[i] == 0xEE and win[i + 1] == 0x0C)
    return tg, hit, null, len(win) - 1


def evidence():
    print("PHASE -- plausible 4-byte slots in 0xF0033F-0xF007FF, per byte phase")
    for ph, n, t in phase_scores():
        print("    phase %d: %3d of %3d" % (ph, n, t))
    print("  (no single phase fits: the byte objects at 0xF003CC and 0xF00759")
    print("   are odd-length and shift it.  --layout has the four runs.)")
    print()
    print("SEGMENTS -- the phase-aware greedy walk")
    for k, o, n in segments():
        print("    %-4s 0x%06X %5d" % (k, o, n))
    print()
    for lo, hi, nm in ((R1[0], R1[1], "0xF0033F-0xF007FF"),
                       (R2[0], R2[1], "0xF0199E-0xF01E71")):
        print("CODE REFERENCES into %s" % nm)
        print("    `call nnn`/`jp nnn` operands, four images, every offset: %d"
              % code_refs(lo, hi))
        print("    routine-directory (0xF40000-0xF44018) slots:              %d"
              % directory_slots(lo, hi))
    print()
    print("SENTINEL 0x%08X" % SENTINEL)
    b = prom_a_boundaries()
    print("    fills %d of the 290 slots" % sum(
        1 for a, n in tables() for v in slots(a, n) if v == SENTINEL))
    print("    is an instruction boundary in prom_a's transcription? %s"
          % (SENTINEL in b))
    print("    the instruction that contains it: 0xFDB10C `lda xbc,(xiz-12)`,"
          " bytes %s" % at(0xFDB10C, 3, "a").hex(" "))
    print()
    tg, hit, null, pos = prologue_stat()
    print("TABLE 0xF00340 -- %d distinct targets, %d begin `EE 0C` (`link XIZ,0`)"
          % (len(tg), hit))
    print("    null: `EE 0C` at %d of %d byte positions in 0xF01200-0xF014E8"
          " (%.2f%%)" % (null, pos, 100.0 * null / pos))
    print()
    print("TABLE 0xF006CD and TABLE 0xF00762 -- targets vs prom_a boundaries")
    for a, n, lo, hi in ((0xF006CD, 35, 0xFC4082, 0xFC4455),
                         (0xF00762, 39, 0xFE28B2, 0xFE2F8D)):
        tg = sorted(set(slots(a, n)) - {0, SENTINEL})
        onb = sum(1 for t in tg if t in b)
        loc = sum(1 for x in range(lo, hi) if x in b)
        print("    0x%06X: %2d of %2d targets on a boundary (%4.1f%%);"
              " local null %5.1f%% of 0x%06X-0x%06X"
              % (a, onb, len(tg), 100.0 * onb / len(tg),
                 100.0 * loc / (hi - lo), lo, hi))
    print()
    print("SPAN 2 -- the selector at 0xF5BEFB and the 200-byte stride")
    t = curve_table()
    print("    entries: " + " ".join("0x%06X" % v for v in t))
    print("    distinct, sorted: " + " ".join("0x%06X" % v for v in sorted(set(t))))
    print("    consecutive differences: %s"
          % [b_ - a_ for a_, b_ in zip(sorted(set(t)), sorted(set(t))[1:])])
    print("    blitter arguments at 0xF5BEF1/0xF5BEF4: BC=%d pages, HL=%d columns"
          " -> %d bytes" % (at(0xF5BEF1 + 1, 1)[0], at(0xF5BEF4 + 1, 1)[0],
                            at(0xF5BEF1 + 1, 1)[0] * at(0xF5BEF4 + 1, 1)[0]))
    print("    six objects tile 0x%06X-0x%06X with no remainder"
          % (curve_starts()[0], curve_starts()[-1] + 199))
    print()
    print("SPAN 2 -- the 24-byte icon grid")
    for target in (0xF019AA, 0xF0191A):
        w = word_refs(target, target + 1)
        print("    0x%08X named as a 32-bit word: prom_b %d, prom_a %d"
              " (prom_c %d / prom_d %d are a different address space)"
              % (target, len(w["b"]), len(w["a"]), len(w["c"]), len(w["d"])))
        print("        prom_b sites: "
              + " ".join("0x%06X" % (B_BASE + o) for o in w["b"]))
    print("    0xF019AA - 0xF0191A = %d = %d * 24"
          % (0xF019AA - 0xF0191A, (0xF019AA - 0xF0191A) // 24))
    print("    0xF019C2 - 0xF0191A = %d = %d * 24"
          % (0xF019C2 - 0xF0191A, (0xF019C2 - 0xF0191A) // 24))
    return 0


def show_render():
    print("The two 12x16 icons whose cells this span holds (12 columns, 2 pages):")
    a, b_ = render(0xF01992, 2, 12), render(0xF019AA, 2, 12)
    print("   0xF01992 (upper page in Data_F0191A)   0xF019AA")
    for x, y in zip(a, b_):
        print("   " + x + "   " + y)
    print()
    print("The six 40x40 objects (40 columns, 5 pages), left to right:")
    print("   " + "  ".join("0x%06X" % s for s in curve_starts()))
    imgs = [render(s, 5, 40) for s in curve_starts()]
    for r in range(40):
        print("  ".join(i[r] for i in imgs))
    return 0


def layout():
    print("  bytes  span                 what")
    names = {"pad": "alignment pad", "ptr": "4-byte LE pointer slots",
             "byt": "byte object"}
    for k, o, n in SEG:
        print("  %5d  0x%06X-0x%06X  %s%s"
              % (n, B_BASE + o, B_BASE + o + n - 1, names[k],
                 " (%d slots)" % (n // 4) if k == "ptr" else ""))
    print("  -----")
    print("  %5d  0xF0033F-0xF007FF" % (R1[1] - R1[0]))
    print()
    print("     12  0xF0199E-0xF019A9  lower page of the 12x16 icon at 0xF01992")
    print("     24  0xF019AA-0xF019C1  one 12x16 icon")
    for s in curve_starts():
        print("    200  0x%06X-0x%06X  40x40 bitmap" % (s, s + 199))
    print("  -----")
    print("  %5d  0xF0199E-0xF01E71" % (R2[1] - R2[0]))
    return 0


# ------------------------------------------------------------------ emitters
def brow(a, n, per=16, tag=""):
    out = []
    for i in range(0, n, per):
        k = min(per, n - i)
        out.append("\t.byte " + ", ".join("0x%02X" % c for c in at(a + i, k))
                   + "\t; %06X%s" % (a + i, tag))
    return out


def slot_note(v):
    if v == 0:
        return "empty"
    if v == SENTINEL:
        return "absent (sentinel)"
    return ""


def ptr_block(addr, n, label, headline):
    out = [""]
    out += headline
    out.append("%s:" % label)
    for i in range(n):
        v = w32(addr + 4 * i)
        note = slot_note(v)
        out.append("\t.long 0x%08X\t; %06X  [%3d]%s"
                   % (v, addr + 4 * i, i, ("  " + note) if note else ""))
    return out


def emit_r1():
    L = []
    L.append("; " + "=" * 76)
    L.append("; 0xF0033F-0xF007FF -- FOUR TABLES OF 4-BYTE LITTLE-ENDIAN POINTERS,")
    L.append("; AND THE THREE SHORT BYTE OBJECTS BETWEEN THEM")
    L.append("; " + "=" * 76)
    L.append(";")
    L.append("; 1,217 bytes.  DATA: 0 `call nnn` / `jp nnn` operands in any of the four")
    L.append("; ROM images land in this span, and 0 routine-directory slots point in.")
    L.append(";")
    L.append("; ⚠ THE COVER-R1 BANNER ABOVE STILL APPLIES AND IS NOT WITHDRAWN: nothing")
    L.append("; the round-1 walk decoded reaches here, so the span is not CODE.  What is")
    L.append("; withdrawn is `unreachable, therefore leave it verbatim'.  Data is typed")
    L.append("; from what REFERENCES it, and every object below is bounded that way.")
    L.append(";")
    L.append("; 290 consecutive 4-byte little-endian words are each 0x00000000, the")
    L.append("; repeated sentinel 0x00FDB10E, or an address in the 1 MiB CS2 window")
    L.append("; 0xF00000-0xFFFFFF -- in a 16 MiB address space, and 290 in a row.")
    L.append(";")
    L.append("; ⚠ THE PHASE IS NOT CONSTANT ACROSS THE SPAN, which is why one alignment")
    L.append("; never fit it: scored across the whole span the four byte phases give 222,")
    L.append("; 51, 42 and 6 of ~303.  These are FOUR runs at THREE phases, because the")
    L.append("; byte objects at 0xF003CC (45 B) and 0xF00759 (9 B) are both odd-length.")
    L.append(";")
    L.append("; 0x00FDB10E means ABSENT.  It fills 82 of the 290 slots and is NOT an")
    L.append("; instruction boundary in prom_a: it lands inside `lda xbc,(xiz-12)` at")
    L.append("; 0xFDB10C (be f4 31).  It cannot be entered and cannot start an object.")
    L.append(";")
    L.append("; Re-derive all of it with")
    L.append(";     python3 notes/gen_prom_b_f0033f_f0199e.py --evidence")
    L.append("; " + "=" * 76)
    L.append("")
    L.append("\t.byte 0x%02X\t; F0033F  pad: the byte after the `ret` at 0xF0033E,"
             % at(0xF0033F, 1)[0])
    L.append("\t\t\t;          aligning the table below to a 4-byte boundary")

    L += ptr_block(0xF00340, 35, "PtrTable_F00340", [
        "; --------------------------------------------------------------------------",
        "; PtrTable_F00340 -- 35 slots, A ROUTINE VECTOR TABLE",
        "; Evidence: 25 of the 26 distinct targets begin with the byte pair `EE 0C` --",
        ";           `link XIZ,0x0000`, the stack-frame prologue prom_a's transcription",
        ";           spells that way over a hundred times.  Null: that pair occurs at 28",
        ";           of the 744 byte positions in 0xF01200-0xF014E8 (3.8%), so 25 of 26",
        ";           is not chance.  The odd one out is slot [0], 0xF01200, which begins",
        ";           `C9 D8`.",
        "; ⚠ Its target block 0xF01200-0xF014E8 is STILL `.incbin` (the span at file",
        ";   0x000C4D+0x000BB3).  These are 25 proven entry points for whoever converts",
        ";   it; this file converts the TABLE, not the routines.",
        "; Unknown: what the routines do, and what selects a slot.  No reader for this",
        ";          table has been found -- 0x00F00340 is not a 32-bit word anywhere in",
        ";          the four images -- so the index is presumably computed.",
        "; --------------------------------------------------------------------------",
    ])

    L.append("")
    L.append("; --------------------------------------------------------------------------")
    L.append("; Data_F003CC -- 45 bytes, EMITTED AS DATA.  ⚠ SHAPE NOT ESTABLISHED.")
    L.append("; Evidence: it is bounded on both sides -- the pointer run above ends at")
    L.append(";           0xF003CB and the one below begins at 0xF003F9 -- and its own")
    L.append(";           content is small ascending indices, not addresses.  Nothing")
    L.append(";           names it and no consumer has been found.")
    L.append("; Measured: three groups separated by zero padding, printed one per line")
    L.append(";           below.  The line breaks are a READING and are not proven; the")
    L.append(";           bytes are the ROM's.  The third group is 13 bytes, not the 16")
    L.append(";           the first two are, so `three 16-byte rows' is WRONG and is not")
    L.append(";           claimed.")
    L.append("; --------------------------------------------------------------------------")
    L.append("Data_F003CC:")
    L += brow(0xF003CC, 16, 16, "  00-05, then zero padding")
    L += brow(0xF003DC, 16, 16, "  06-0C, then zero padding")
    L += brow(0xF003EC, 13, 13, "  00-05 then 10-16")

    L += ptr_block(0xF003F9, 181, "PtrTable_F003F9", [
        "; --------------------------------------------------------------------------",
        "; PtrTable_F003F9 -- 181 slots, THE INDEX OF THE 0xF78029 BITMAP SHEET",
        "; ★ THIS TABLE IS ALREADY LOAD-BEARING IN THIS TREE.  The banner at",
        ";   `0xF78029-0xF7A3FF -- A 121-OBJECT BITMAP SHEET, INDEXED FROM prom_b",
        ";   0xF003F9' bounds all 120 bounded objects there by abutment of these",
        ";   entries, and notes/gen_prom_b_f78029_module.py read them straight out of",
        ";   the ROM because the address was inside an `.incbin`.  It no longer is.",
        "; Evidence: 121 of the slots are a distinct address in 0xF7828A-0xF799E8, 50",
        ";           are the sentinel and 10 are zero; slot 181 leaves that range, which",
        ";           is where this run is cut.",
        "; ⚠ The cut at 181 is a statement about the TARGETS, not about how the firmware",
        ";   indexes them: no reader for either run has been found.  The two runs are",
        ";   labelled separately because their target sets do not overlap at all.",
        "; Unknown: what the 121 images depict -- see the 0xF78029 banner, which says so",
        ";          at length.  Nothing is guessed here either.",
        "; --------------------------------------------------------------------------",
    ])

    L += ptr_block(0xF006CD, 35, "PtrTable_F006CD", [
        "; --------------------------------------------------------------------------",
        "; PtrTable_F006CD -- 35 slots -> prom_a's DisplayList_FC4000",
        "; Evidence: 24 distinct targets, all in 0xFC4082-0xFC4454, which prom_a's",
        ";           source already carries as DisplayList_FC4000 (2,095 bytes of",
        ";           DSP-effect / SOUND EDIT label text).  0 of the 24 is an instruction",
        ";           boundary there -- correct, since 0 of that region's 979 addresses",
        ";           is one: prom_a frames it as data too.  11 slots are the sentinel.",
        "; Unknown: what selects a slot.  No reader found.",
        "; --------------------------------------------------------------------------",
    ])

    L.append("")
    L.append("; --------------------------------------------------------------------------")
    L.append("; Data_F00759 -- 9 bytes: the eight powers of two, then one 0x00")
    L.append("; Evidence: bounded by the pointer runs on either side.  The values are")
    L.append(";           0x01 0x02 0x04 0x08 0x10 0x20 0x40 0x80 -- a single-bit mask")
    L.append(";           per index, the shape a bit-numbered lookup has.  The trailing")
    L.append(";           0x00 is what restores the 4-byte phase for the run below.")
    L.append("; Unknown: what indexes it.  No reader found.")
    L.append("; --------------------------------------------------------------------------")
    L.append("Data_F00759:")
    L += brow(0xF00759, 8, 8, "  1 << 0 .. 1 << 7")
    L += brow(0xF00761, 1, 1, "  phase pad")

    L += ptr_block(0xF00762, 39, "PtrTable_F00762", [
        "; --------------------------------------------------------------------------",
        "; PtrTable_F00762 -- 39 slots -> prom_a 0xFE28B2-0xFE2F8C",
        "; Evidence: 21 distinct targets, all inside a 1,755-byte prom_a window; 16",
        ";           slots are the sentinel and 2 are zero.  The SLOTS are pointers on",
        ";           the same 290-word test as the rest of the span.",
        "; ⚠ WHAT THE TARGETS ARE IS NOT ESTABLISHED.  prom_a's current transcription",
        ";   frames 0xFE28B2-0xFE2F8C as CODE, but only 6 of the 21 targets land on an",
        ";   instruction boundary there -- against 35.7% of ALL addresses in that range,",
        ";   i.e. BELOW chance.  So this table lends prom_a's framing no support, and no",
        ";   claim is made here about whether that region is code or data.  A prom_a",
        ";   lane should look: 21 pointers into a span is what an object index looks",
        ";   like, and 6/21 is what a misframe looks like.",
        "; --------------------------------------------------------------------------",
    ])

    L.append("")
    L.append("; --------------------------------------------------------------------------")
    L.append("; Data_F007FE -- 2 bytes.  ⚠ NOT IDENTIFIED.")
    L.append("; Evidence: they complete no 4-byte slot (the run above ends at 0xF007FD)")
    L.append(";           and they are not a plausible slot themselves.  They sit")
    L.append(";           immediately below sub_F00800, which starts on the 0x800")
    L.append(";           boundary, so `padding to the module boundary' fits -- but the")
    L.append(";           image's filler byte is 0x0E and only the first of the two is,")
    L.append(";           so that is a guess and is not asserted.")
    L.append("; --------------------------------------------------------------------------")
    L.append("Data_F007FE:")
    L += brow(0xF007FE, 2, 2, "  purpose unknown")
    L.append("")
    return L


def emit_r2():
    L = []
    L.append("; " + "=" * 76)
    L.append("; 0xF0199E-0xF01E71 -- ONE ICON PAGE, ONE WHOLE 12x16 ICON, AND SIX 40x40")
    L.append("; BITMAPS THE 0xF5BECE BLITTER DRAWS")
    L.append("; " + "=" * 76)
    L.append(";")
    L.append("; 1,236 bytes.  DATA: 0 `call nnn` / `jp nnn` operands in any of the four")
    L.append("; ROM images land in this span, and 0 routine-directory slots point in.")
    L.append(";")
    L.append("; ★★ THE SIX 200-BYTE OBJECTS ARE PINNED BY CONVERTED CODE IN THIS FILE.")
    L.append("; 0xF5BECE-0xF5BEFA reads, in this transcription:")
    L.append(";")
    L.append(";       ld XIZ,0x00f5befb      ; the selector table's base")
    L.append(";       xor W,W / sll 0x02,WA  ; index * 4")
    L.append(";       ld XIY,(XIZ+WA)        ; XIY = table[index] -- the source bitmap")
    L.append(";       ld WA,(0x2350) / div A,0x08 / ld HL,(0x2352) / mul L,0x28")
    L.append(";       add HL,WA / ld IX,HL   ; destination = y*40 + x/8")
    L.append(";       ld BC,0x0005           ; 5 pages")
    L.append(";       ld HL,0x0028           ; 40 columns")
    L.append(";       ld A,0x03 / swi 7      ; blit")
    L.append(";")
    L.append("; 5 * 40 = 200, which is exactly the stride between the seven selector")
    L.append("; entries' six distinct targets, and the six objects tile 0xF019C2-0xF01E71")
    L.append("; with no gap and no remainder.  Rendered as 5 pages of 40 columns (a byte")
    L.append("; is one column, MSB the top row of its page) each is a framed 40x40 box")
    L.append("; holding one monotone rising curve -- see below, and `--render`.")
    L.append(";")
    L.append("; ⚠ THE SELECTOR TABLE AT 0xF5BEFB IS ITSELF STILL MIS-FRAMED AS CODE in")
    L.append(";   this file (`cp XWA,(XDE+0x1d)`, `nop`, and four rows marked `[llvm-mc")
    L.append(";   cannot encode this]`).  It is 28 bytes = 7 * 4 and every word is one of")
    L.append(";   the six addresses below.  It is OUTSIDE this span and is deliberately")
    L.append(";   NOT touched here.")
    L.append(";")
    L.append("; ★ THE 24-BYTE ICON GRID IS PINNED BY TEN EXTERNAL REFERENCES.  0x00F019AA")
    L.append("; appears as a 32-bit word ten times in the display-list region, and")
    L.append("; 0x00F0191A -- Data_F0191A above -- six times.  Their difference is 144 =")
    L.append("; 6 * 24, and 0xF019C2 is 0xF0191A + 7 * 24, so the grid ends exactly where")
    L.append("; the curves begin.  A 24-byte cell rendered as 12 columns * 2 pages is a")
    L.append("; 12x16 icon; the last two cells are a filled and a hollow circle.")
    L.append(";")
    L.append("; ⚠ Data_F0191A above is 132 bytes = 5.5 cells, because its extent is the")
    L.append("; round-1 REACHABILITY walk's and not an object's -- its own header says so.")
    L.append("; The icon starting at 0xF01992 therefore has its upper page inside")
    L.append("; Data_F0191A and its lower page here.  Data_F0191A is NOT re-cut by this")
    L.append("; pass: it is not part of any `.incbin` span and re-cutting it is a")
    L.append("; separate change with its own evidence.")
    L.append(";")
    L.append("; Re-derive all of it with")
    L.append(";     python3 notes/gen_prom_b_f0033f_f0199e.py --evidence --render")
    L.append("; " + "=" * 76)
    L.append("")
    L.append("; --------------------------------------------------------------------------")
    L.append("; Bitmap_F0199E -- 12 bytes: the LOWER page of the 12x16 icon at 0xF01992,")
    L.append(";                  whose upper page is the last 12 bytes of Data_F0191A.")
    L.append("; Evidence: the 24-byte grid above; 0xF01992 = 0xF0191A + 5 * 24.")
    L.append("; Rendered (12 columns, this page only -- rows 8-15 of the icon):")
    for line in render(0xF0199E, 1, 12):
        L.append(";     " + line)
    L.append("; --------------------------------------------------------------------------")
    L.append("Bitmap_F0199E:")
    L += brow(0xF0199E, 12, 12, "  page 1 of the icon at 0xF01992")

    L.append("")
    L.append("; --------------------------------------------------------------------------")
    L.append("; Bitmap_F019AA -- 24 bytes, one whole 12x16 icon (12 columns, 2 pages)")
    L.append("; Evidence: 0x00F019AA is named as a 32-bit word ten times in the display-")
    L.append(";           list region (0xF03ACF 0xF03AE7 0xF03AFF 0xF03B17 0xF03B81")
    L.append(";           0xF03B96 0xF03C1F 0xF03C37 0xF03C4F 0xF03C67), which is what")
    L.append(";           pins the grid.  The next object, 0xF019C2, bounds it.")
    L.append("; Rendered:")
    for line in render(0xF019AA, 2, 12):
        L.append(";     " + line)
    L.append("; --------------------------------------------------------------------------")
    L.append("Bitmap_F019AA:")
    L += brow(0xF019AA, 12, 12, "  page 0 (rows 0-7)")
    L += brow(0xF019B6, 12, 12, "  page 1 (rows 8-15)")

    tbl = curve_table()
    for k, s in enumerate(curve_starts()):
        idx = [i for i, v in enumerate(tbl) if v == s]
        L.append("")
        L.append("; --------------------------------------------------------------------------")
        L.append("; Bitmap_%06X -- 200 bytes, 40 columns * 5 pages = 40x40" % s)
        L.append("; Evidence: selector slot%s %s at 0xF5BEFB name%s it; the blitter at"
                 % ("" if len(idx) == 1 else "s",
                    ", ".join("[%d]" % i for i in idx),
                    "s" if len(idx) == 1 else ""))
        # (slot [3] and slot [6] both hold 0xF019C2; the caller's `cp A,3 /
        #  jr NZ` sends index 3 down a different path, so [3] is never read.)
        L.append(";           0xF5BEF1 is handed BC=5 pages, HL=40 columns.")
        L.append("; Rendered:")
        for line in render(s, 5, 40):
            L.append(";     " + line)
        L.append("; --------------------------------------------------------------------------")
        L.append("Bitmap_%06X:" % s)
        for p in range(5):
            L += brow(s + p * 40, 20, 20, "  page %d, columns 0-19" % p)
            L += brow(s + p * 40 + 20, 20, 20, "  page %d, columns 20-39" % p)
    L.append("")
    return L


# ------------------------------------------------------------------ verify
def verify_region(lines, lo, hi):
    import llvm_roundtrip as RT
    body = [l + "\n" for l in lines if not l.startswith(";") and l.strip()]
    got, err = RT.assemble(body)
    if got is None:
        return False, "llvm-mc refused the emitted text:\n" + err[-2000:]
    want = at(lo, hi - lo)
    if got != want:
        for i in range(min(len(got), len(want))):
            if got[i] != want[i]:
                return False, ("first difference at 0x%06X: emitted 0x%02X, ROM 0x%02X"
                               % (lo + i, got[i], want[i]))
        return False, "length differs: emitted %d, ROM %d" % (len(got), len(want))
    return True, "%d bytes re-assemble to the ROM exactly" % len(got)


def c(desc, got, want, verbose=True):
    ok = got == want
    if not ok:
        FAIL.append("%s: got %r, want %r" % (desc, got, want))
    if verbose:
        print("  %s %-64s %s" % ("ok " if ok else "FAIL", desc, got))
    return ok


def checks(verbose=True):
    del FAIL[:]
    if verbose:
        print("checks")
    # ⚠ the walk cannot see the cut at 0xF006CD -- that cut comes from the
    # TARGETS, not from the bytes -- so SEG's two abutting `ptr` runs are merged
    # back before the comparison.  Merging is what makes this a real check of
    # the walk rather than a check of a hand-typed table.
    merged = []
    for k, o, n in SEG:
        if merged and k == "ptr" and merged[-1][0] == "ptr" \
                and merged[-1][1] + merged[-1][2] == B_BASE + o:
            merged[-1] = ("ptr", merged[-1][1], merged[-1][2] + n)
        else:
            merged.append(("byt" if k == "pad" else k, B_BASE + o, n))
    c("segment walk reproduces SEG (abutting ptr runs merged)",
      segments(), [tuple(x) for x in merged], verbose)
    c("span 1 length", sum(n for _, _, n in SEG), R1[1] - R1[0], verbose)
    total = sum(n // 4 for k, _, n in SEG if k == "ptr")
    c("pointer slots in span 1", total, 290, verbose)
    c("every slot is 0, sentinel, or CS2",
      all(is_slot(v) for a, n in tables() for v in slots(a, n)), True, verbose)
    c("sentinel is not a prom_a instruction boundary",
      SENTINEL in prom_a_boundaries(), False, verbose)
    tg, hit, null, pos = prologue_stat()
    c("0xF00340: distinct targets", len(tg), 26, verbose)
    c("0xF00340: targets with the `link XIZ,0` prologue", hit, 25, verbose)
    c("0xF00340: `EE 0C` null in 0xF01200-0xF014E8 stays under 5%",
      null / pos < 0.05, True, verbose)
    c("0xF003F9: distinct bitmap-sheet targets",
      len(set(slots(0xF003F9, 181)) - {0, SENTINEL}), 121, verbose)
    c("0xF003F9: slot 181 leaves the sheet",
      0xF7828A <= w32(0xF003F9 + 181 * 4) <= 0xF799E8, False, verbose)
    # the sheet's object labels in the .s must be exactly this table's targets
    src = open(SRCB, encoding="utf-8").read()
    # ⚠ NOT equality: the sheet's 121st target, 0xF799E8, is bounded by nothing,
    # so gen_prom_b_f78029_module.py labels it `Data_F799E8` and not `Bitmap_`.
    # And `Data_F78029` -- the sheet's unreferenced head -- is a label that is
    # NOT a target.  The honest assertion is CONTAINMENT: every target of this
    # table already carries a label at exactly that address in the .s.
    lab = set(int(m, 16) for m in
              re.findall(r"^(?:Bitmap|Data)_(F7[0-9A-F]{4}):", src, re.M))
    tg = set(slots(0xF003F9, 181)) - {0, SENTINEL}
    c("every 0xF003F9 target already carries a label in the .s",
      sorted("%06X" % x for x in tg - lab), [], verbose)
    c("...and 120 of the 121 are `Bitmap_` (the 121st, 0xF799E8, is unbounded)",
      len(set(int(m, 16) for m in
              re.findall(r"^Bitmap_(F7[0-9A-F]{4}):", src, re.M)) & tg), 120, verbose)
    c("no call/jp into span 1", code_refs(*R1), 0, verbose)
    c("no call/jp into span 2", code_refs(*R2), 0, verbose)
    c("no directory slot into span 1", directory_slots(*R1), 0, verbose)
    c("no directory slot into span 2", directory_slots(*R2), 0, verbose)
    t = curve_table()
    c("0xF5BEFB holds 7 slots, 6 distinct", (len(t), len(set(t))), (7, 6), verbose)
    c("its distinct targets are the six 200-byte objects",
      sorted(set(t)), curve_starts(), verbose)
    c("blitter pages * columns", at(0xF5BEF1 + 1, 1)[0] * at(0xF5BEF4 + 1, 1)[0],
      200, verbose)
    c("the six objects end exactly at the span's end",
      curve_starts()[-1] + 200, R2[1], verbose)
    c("0x00F019AA is named as a 32-bit word in prom_b",
      len(word_refs(0xF019AA, 0xF019AB)["b"]), 10, verbose)
    c("0xF019AA sits on the 24-byte grid from 0xF0191A",
      (0xF019AA - 0xF0191A) % 24, 0, verbose)
    c("0xF019C2 sits on it too", (0xF019C2 - 0xF0191A) % 24, 0, verbose)
    for lines, (lo, hi) in ((emit_r1(), R1), (emit_r2(), R2)):
        good, msg = verify_region(lines, lo, hi)
        c("0x%06X re-assembles" % lo, good, True, verbose)
        if verbose:
            print("       " + msg)
    if verbose:
        print("%d check(s) failed" % len(FAIL))
        for f in FAIL:
            print("  " + f)
    return not FAIL


# ------------------------------------------------------------------ splice
def splice():
    if not checks(verbose=False):
        checks()
        raise SystemExit("refusing to splice: a check failed (see above)")
    # ⚠ READ THE MASTER, NOT image_path(): prom_b's master carries three
    # `.include` directives, and writing the EXPANDED image back over it drops
    # them.  write_part() refuses that, correctly -- the fix is to edit the file
    # that owns the text.  asm_source.locate() confirms both `.incbin` lines are
    # in prom_b/wsa1_prom_b.s itself.
    src = open(SRCB_MASTER, encoding="utf-8").read().split("\n")
    for lines, (lo, hi) in ((emit_r2(), R2), (emit_r1(), R1)):
        good, msg = verify_region(lines, lo, hi)
        if not good:
            raise SystemExit("refusing to splice: " + msg)
        want = ('\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x%06X, 0x%06X'
                % (lo - B_BASE, hi - lo))
        hit = [i for i, l in enumerate(src) if l == want]
        if len(hit) != 1:
            raise SystemExit("expected exactly one `%s`, found %d" % (want, len(hit)))
        i = hit[0]
        src = src[:i] + lines + src[i + 1:]
        print("spliced 0x%06X: %d lines over the `.incbin`; %s" % (lo, len(lines), msg))
    write_part(SRCB_MASTER, "\n".join(src))
    return 0


def main():
    a = sys.argv[1:]
    if "--splice" in a:
        return splice()
    if "--selftest" in a:
        return 0 if checks() else 1
    if "--evidence" in a:
        evidence()
        if "--render" in a:
            print()
            show_render()
        return 0
    if "--render" in a:
        return show_render()
    if "--layout" in a:
        return layout()
    print("\n".join(emit_r1()))
    print("\n".join(emit_r2()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
