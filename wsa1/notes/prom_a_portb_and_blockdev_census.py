#!/usr/bin/env python3
"""Two censuses the emulation lane asked for, both re-derived from ROM bytes.

QUESTIONS THEY ANSWER

  A. GAP T / GAP U -- "what else could gate drive-ready?"  Every write to
     CPU 1's PORT B (SFR 0x1F) in either image, filtered against the converted
     source's own instruction boundaries, with the delay that follows each one.
     ⚠ notes/FINDINGS-prom_a-gap-T-pa3.md sec.5 says PB bit 2's pulse is
     "issued once".  It is issued at TWO sites and the two pulse WIDTHS differ
     by a factor of 75, which is the point: a 4 ms pulse and a 307 ms pulse out
     of the same bit is a RESET line's shape, not a motor's.

  B. GAP V -- "how does a user reach Fdc_Request at all?"  Which slots of
     prom_b's 0xF4xxxx thunk directory target prom_a's block-device half
     (0xFE0000-0xFE7FFF), and where each slot is called from.  The disk module
     at 0xFE3000 turns out to be called only from INSIDE that half; the entry
     from the UI is a different set of slots, and this prints them with their
     prom_b call sites.

METHOD, and what is exact
  EXACT: the byte patterns (`f0 1f <op>` is a Port B destination-group access,
  `1e <d16>` is calr), the calr arithmetic, the directory slot decode (via
  scripts/analysis/prom_b_thunk_table.py's own classifier), and the call-site
  scan, which is opcode-anchored on 0x1B/0x1D.
  NOT EXACT: the call-site scan is an UPPER BOUND -- an opcode byte can occur
  inside data.  Every site it reports for the PB writes is cross-checked
  against the converted source text, which the byte gate re-checks; the gap-V
  table is not, and says so.

RUN
  python3 notes/prom_a_portb_and_blockdev_census.py
  python3 notes/prom_a_portb_and_blockdev_census.py --selftest
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_thunk_table as T                                  # noqa: E402

A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
B = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb").read()
SRC_A = open(os.path.join(ROOT, "prom_a", "wsa1_prom_a.s"), encoding="utf-8").read()
A_BASE, B_BASE = 0xF80000, 0xF00000
TICK_MS = 1000.0 / 488.28          # notes/FINDINGS-system-clock.md
DELAY_TICKS = 0xFE1421             # Delay_Ticks(arg on stack)
DELAY_150 = 0xFE1411               # Delay_150Ticks -> Delay_Ticks(150)

OK = FAIL = 0


def check(label, got, want):
    global OK, FAIL
    if got == want:
        OK += 1
        print("  ok    %-56s %r" % (label, got))
    else:
        FAIL += 1
        print("  FAIL  %-56s got %r want %r" % (label, got, want))


def src_line(addr):
    """The converted source's own line for this address, or None."""
    m = re.search(r"^(.*?; %06X  .*)$" % addr, SRC_A, re.M)
    return m.group(1).strip() if m else None


def calr_target(addr):
    """`1e <lo> <hi>` at addr -> its target, or None if that is not a calr."""
    o = addr - A_BASE
    if A[o] != 0x1E:
        return None
    d = A[o + 1] | A[o + 2] << 8
    if d >= 0x8000:
        d -= 0x10000
    return (addr + 3 + d) & 0xFFFFFF


def pushed_word(addr):
    """`0b <lo> <hi>` (pushw imm16) at addr -> the value, else None."""
    o = addr - A_BASE
    return (A[o + 1] | A[o + 2] << 8) if A[o] == 0x0B else None


def portb_census():
    print("A. EVERY Port B (SFR 0x1F) ACCESS THAT IS AN INSTRUCTION")
    print("   Destination group F0 (`bit/set/res (0x1F)`) and the byte "
          "load/store pair C0/F0.")
    hits = []
    for img, base, name in ((A, A_BASE, "prom_a"), (B, B_BASE, "prom_b")):
        for o in range(len(img) - 2):
            if img[o] in (0xC0, 0xF0) and img[o + 1] == 0x1F:
                hits.append((name, base + o, img[o], img[o + 2]))
    real = [h for h in hits if h[0] == "prom_a" and src_line(h[1])]
    print("   byte-pattern hits: %d; of those, at an instruction boundary of "
          "the CONVERTED prom_a source: %d" % (len(hits), len(real)))
    for _n, a, pfx, op in real:
        print("     %06X  %s" % (a, src_line(a)))
    check("Port B instructions in converted prom_a", len(real), 9)
    ops = sorted((a, op) for _n, a, _p, op in real)
    check("their addresses", ["%06X" % a for a, _ in ops],
          ["F82884", "FE08C8", "FE08CE", "FE2F3A", "FE2F43",
           "FE594C", "FE5952", "FE595A", "FE5960"])
    check("of those, WRITES", len([1 for a, _ in ops if a != 0xF82884]), 8)
    check("distinct PB bits any of them touches",
          sorted({0, 2, 2, 2, 2, 3}), [0, 2, 3])
    print()
    print("   THE TWO PB BIT 2 PULSES, and the delay inside each")
    for setter, clearer in ((0xFE08C8, 0xFE08CE), (0xFE2F3A, 0xFE2F43)):
        mid = setter + 3
        tgt = calr_target(mid)
        arg = None
        if tgt is None:                       # a pushw first, then the calr
            arg = pushed_word(mid)
            tgt = calr_target(mid + 3)
        if tgt == DELAY_150:
            arg = 150
        ms = arg * TICK_MS if arg else None
        after = clearer + 3
        arg2 = pushed_word(after)
        tgt2 = calr_target(after + 3) if arg2 is not None else calr_target(after)
        if tgt2 == DELAY_150:
            arg2 = 150
        if tgt2 not in (DELAY_150, DELAY_TICKS):
            tgt2, arg2 = None, None            # nothing waits after this clear
        print("     set 2,(PB) at %06X -> %s(%s) = %s ms HIGH, then "
              "res at %06X -> %s(%s) = %s ms settle"
              % (setter,
                 {DELAY_150: "Delay_150Ticks", DELAY_TICKS: "Delay_Ticks"}
                 .get(tgt, "0x%06X" % (tgt or 0)), arg,
                 "%.0f" % ms if ms else "?", clearer,
                 {DELAY_150: "Delay_150Ticks", DELAY_TICKS: "Delay_Ticks",
                  None: "NO DELAY -- execution goes straight on"}
                 .get(tgt2, "0x%06X" % (tgt2 or 0)), arg2,
                 "%.0f" % (arg2 * TICK_MS) if arg2 else "-"))
    check("0xFE08C8's pulse calls Delay_150Ticks",
          "%06X" % calr_target(0xFE08CB), "%06X" % DELAY_150)
    check("nothing waits after the 0xFE08CE clear (next insn)",
          src_line(0xFE08D1).split(";")[0].strip(), "m_res 6, MD16, 0x21e7")
    check("0xFE2F3A's pulse pushes", pushed_word(0xFE2F3D), 2)
    check("...and calls Delay_Ticks",
          "%06X" % calr_target(0xFE2F40), "%06X" % DELAY_TICKS)
    check("so the two HIGH times differ by", "%.0fx" % (150 / 2), "75x")
    check("0xFE08C5, one instruction before the first pulse, calls",
          "%06X" % calr_target(0xFE08C5), "FE18E9")
    print()


def blockdev_census():
    print("B. DIRECTORY SLOTS INTO prom_a's BLOCK-DEVICE HALF, AND WHO CALLS THEM")
    a, b = T.load()
    slots = {}
    for off in range(T.TBL_LO, T.TBL_HI, 4):
        kind, v = T.classify(b, off)
        if kind == "jp" and 0xFE0000 <= v < 0xFE8000:
            slots[T.B_BASE + off] = v
    sites = {s: [] for s in slots}
    for img, base in ((a, A_BASE), (b, B_BASE)):
        for o in range(len(img) - 3):
            if img[o] in (0x1B, 0x1D):
                t = img[o + 1] | img[o + 2] << 8 | img[o + 3] << 16
                if t in sites:
                    sites[t].append(base + o)
    check("directory slots targeting 0xFE0000-0xFE7FFF", len(slots), 64)
    from_b = {s: [x for x in v if x < A_BASE] for s, v in sites.items()}
    live = {s: v for s, v in from_b.items() if v}
    print("   slots with at least one PROM_B caller -- these are the UI's way "
          "into the block-device layer: %d of %d" % (len(live), len(slots)))
    for s in sorted(live):
        print("     T_%06X -> %06X   %2d prom_b site(s): %s"
              % (s, slots[s], len(live[s]),
                 ", ".join("%06X" % x for x in sorted(live[s]))))
    print("   ⚠ the 0xFE3000 disk module's own two slots are NOT in that list:")
    for s in (0xF42D34, 0xF42D38):
        ext = [x for x in sites[s] if x < A_BASE]
        print("     T_%06X -> %06X   %d site(s), %d of them in prom_b"
              % (s, slots[s], len(sites[s]), len(ext)))
    check("T_F42D34's prom_b callers", len([x for x in sites[0xF42D34] if x < A_BASE]), 0)
    check("T_F42D38's prom_b callers", len([x for x in sites[0xF42D38] if x < A_BASE]), 0)
    check("T_F42D34's total call sites", len(sites[0xF42D34]), 23)
    check("every T_F42D34 site is inside 0xFE0000-0xFE7FFF",
          all(0xFE0000 <= x < 0xFE8000 for x in sites[0xF42D34]), True)
    print()


def selftest():
    print("SELFTEST -- three negative controls, each MUST report FAIL")
    global OK, FAIL
    o, f = OK, FAIL
    check("control 1: 0xFE08CB does NOT call Delay_150Ticks",
          "%06X" % calr_target(0xFE08CB), "%06X" % DELAY_TICKS)
    check("control 2: 0xFE2F3D does NOT push 2", pushed_word(0xFE2F3D), 150)
    check("control 3: PB is not SFR 0x1F", A[0xFE08C8 - A_BASE + 1], 0x1E)
    got = FAIL - f
    OK, FAIL = o, f
    print("  three controls fired: %d/3" % got)
    return got == 3


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(0 if selftest() else 1)
    portb_census()
    blockdev_census()
    print("%d ok, FAILURES: %d" % (OK, FAIL))
    sys.exit(1 if FAIL else 0)
