#!/usr/bin/env python3
"""Emit the annotated assembly for prom_a's CONTINUOUS-CONTROL NORMALISER,
0xF89800-0xF89FFF.

QUESTION IT ANSWERS
    "What text goes into prom_a/wsa1_prom_a.s for the module reached through
     prom_b thunk T_F405F0 -- the one emulation gap E asks about?"

HOW IT IS SAFE
    Instruction text comes from prom_a/roundtrip.py --block (assembled and
    byte-compared before printing).  The eight response-curve tables and the
    34-entry handler table are emitted FROM THE ROM, not typed.  The handler
    table is emitted SYMBOLICALLY -- `.long Ctrl_Ch0_Normalise` and so on -- so
    that if a label is wrong the byte gate fails instead of a comment lying.
    The trailing 0x0E pad is emitted only after checking every byte of it.

RUN
    python3 notes/gen_prom_a_ctrl_module.py --out-dir /tmp/frag
    python3 prom_a/insert_region.py 0xF89800 0xF8A000 /tmp/frag/ctrl.s
    python3 scripts/analysis/assert_byte_identical.py
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
BASE = 0xF80000
LO, HI = 0xF89800, 0xF8A000
CODE1 = (0xF89800, 0xF89825)
TABLE = (0xF89825, 0xF898AD)
CODE2 = (0xF898AD, 0xF89AB4)
CURVES = 0xF89AB4
PAD = (0xF89FBF, 0xF8A000)


def rom(addr, n):
    return A[addr - BASE:addr - BASE + n]


def u32(addr):
    return int.from_bytes(rom(addr, 4), "little")


HANDLERS = {
    0xF898AD: "Ctrl_Ch0_Normalise",
    0xF898E0: "Ctrl_Ch1_Normalise",
    0xF89913: "Ctrl_Ch2_Normalise",
    0xF8997C: "Ctrl_Ch3_Normalise",
    0xF899B2: "Ctrl_Ch4_Normalise",
    0xF899D6: "Ctrl_Ch5_Normalise",
    0xF899FA: "Ctrl_G3Ch1_Normalise",
    0xF89A2A: "Ctrl_G3Ch0_Normalise",
    0xF89A5B: "Ctrl_G3Ch2_Normalise",
    0xF89A8B: "Ctrl_G3Ch3_Normalise",
    0xF89AAD: "Ctrl_ReportChanged",
    0xF89AB0: "Ctrl_ReportUnchanged",
    0xF89AB1: "Ctrl__return",
}

BANNER = """
; ==============================================================================
; 0xF89800-0xF89FFF -- the CONTINUOUS-CONTROL NORMALISER
; ==============================================================================
;
; ★★ THIS IS THE ROUTINE emulation gap E asks about.
; kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md, gap E.3: "What does prom_a
; 0xF89800 (reached through thunk 0xF405F0) do with a received byte?  Its carry
; result decides whether the byte is kept, and it is the module's only call out
; of itself."  And notes/FINDINGS-prom_b-sc1-link.md ends its own open-questions
; list with "What would settle it: ... 0xF89800."
;
; WHAT IT IS.  One routine that turns a RAW 8-bit reading of a continuous
; control into a COOKED value through a per-channel response curve, remembers
; the cooked value, and returns CARRY SET only when it changed.  That is why
; every caller is `call T_F405F0 / jr nc,skip`: the carry means "this control
; actually moved".
;
; THE CHANNEL SELECTOR is in W, the raw reading in A.  The dispatcher builds
;     index = ((W & 0xC0) >> 1) | ((W & 0x07) << 2)
; -- so bits 7-6 are a GROUP and bits 2-0 a CHANNEL, bits 5-3 are ignored, and
; the result is a byte offset into a 32-entry LE32 table.  Ten of the 32 slots
; are live; twenty-one go to Ctrl_ReportUnchanged and one to Ctrl_ReportChanged.
;
; ★ GROUP 0 IS THE ON-BOARD ANALOGUE SCAN, and that is proved by its call sites,
; not inferred: the EIGHT converted calls in AnalogScan (0xF8DC00-0xF8DDE5) pass
; W = 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x04, 0x05 -- four from ADREG0-ADREG3
; and two from (0x600000)/(0x600001) -- which is exactly slots 0.0 to 0.5.
; ⚠ EIGHT sites for SIX channels: 0xF8DDBC-0xF8DDE5 is BYTE-IDENTICAL to
; 0xF8DD4D-0xF8DD76, so AnalogScan carries two copies of the scan routine for
; channel 4 and two for channel 5.  Stated as measured (the two 21-byte runs
; compare equal); nothing here says why.  notes/FINDINGS-prom_a-ring-buffers.md
; already said "all six report through directory slot T_F405F0"; this is the
; other end of that sentence.
;
; ★ GROUP 3 IS FOUR MORE CONTROLS OF THE SAME KIND, with their own raw slots
; (0x24E8-0x24EB), their own cooked slots and their own curves.  ⚠ WHO SENDS
; THEM IS NOT ESTABLISHED HERE.  What is established is that prom_b's SC1
; receive decoder calls this same routine twice (prom_b 0xF5B14C and 0xF5B1D6)
; with W taken from a RECEIVED BYTE -- so a control arriving over SC1 and a
; control read from the CPU's own A/D are normalised by one routine, with one
; table of curves, into one bank of cooked values.  Which group SC1's bytes land
; in depends on those bytes and is not read off the ROM.  So the cross-note lead
; gap E flags ("if it is one slot, the analogue controls and the SC1 peer are
; the same board") resolves to: IT IS ONE SLOT, and the two sources share the
; whole normalising path -- but the ROM distinguishes them by group, and that is
; as far as the evidence goes.
;
; THE RAM BANK
;   0x24D0-0x24D5   raw readings, group 0 channels 0-5
;   0x24E8-0x24EB   raw readings, group 3 channels 0-3
;   0x24F2 0x24F3 0x24F4 0x24F5 0x24F6 0x24FF 0x2503 0x2504 0x2505 0x2506
;                   the ten cooked values, one per live slot
;   (0xC4)          a mode byte.  When it is 2, six of the ten handlers skip the
;                   curve entirely and force an IDLE value -- 0x40 for slots 0.0,
;                   0.1 and 3.2, 0x00 for 0.2, 0.3 and 3.0, 0x80 for 3.1 -- and
;                   return carry CLEAR.  Slots 0.4, 0.5 and 3.3 have no such arm.
;                   ⚠ What mode 2 is is not established.
;
; THE CURVES.  Eight tables tile 0xF89AB4-0xF89FBE with no gap:
;
;   0xF89AB4  128  identity 0..127                     slot 3.3
;   0xF89B34  128  a compressed curve, 0..127          slots 0.4, 0.5, 3.2
;   0xF89BB4  128  the same curve, 40 bytes off by ±1  slots 0.0, 0.1
;   0xF89C34  128  BYTE-IDENTICAL to 0xF89AB4          slot 3.0
;   0xF89CB4  256  0..255, indexed by the raw byte     slot 3.1
;   0xF89DB4  128  0..127                              slot 0.3
;   0xF89E34  128  0..127, and NOTHING REFERENCES IT   (see below)
;   0xF89EB4  256  0..255, indexed by the raw byte     slot 0.2
;   0xF89FB4   11  a span table, indexed by (0x7F5F)   slot 0.2's calibration
;
;   Seven of the eight are indexed by `raw >> 1`, so they are 128-entry maps
;   over a 7-bit position; the two 256-entry ones are indexed by the raw byte
;   whole.  ⚠ 0xF89E34 has NO reference: censusing the 4-byte little-endian
;   immediate 0x00F89E34 over prom_a AND prom_b finds zero sites, while the same
;   census finds every other table at exactly the `ld XIX,imm32` that uses it.
;   ⚠ 0xF89BB4 is 0xF89B34 with 40 of its 128 bytes changed by exactly ±1 --
;   21 higher and 19 lower, all of them between indices 37 and 89, the other 88
;   equal.  Two roundings of one curve, not two curves.
;   ⚠ 0xF89B34 and 0xF89BB4 share a single NON-MONOTONE entry at index 20 --
;   0x2C where its neighbours are 0x21 and 0x24.  Recorded as read; nothing here
;   claims it is a defect.
;
; SLOT 0.2 IS THE ONE CALIBRATED CHANNEL.  It reads a two-byte record at
; 0x007F5A: (+6) is subtracted from the curve output with a floor, and (+5)
; indexes the 11-entry span table at 0xF89FB4; the result is
; `((raw_curved - floor) * 0x100 / 0xEC) * span / 0x14`, clamped to 0x7F.
; ⚠ The 11-entry count is the number of non-0x0E bytes before the module's pad;
; the use site does NOT range-check (0x7F5F), so the ROM does not bound it.
;
; Every number above is re-derived by notes/prom_a_ctrl_checks.py.
; ==============================================================================
"""

HEADERS = {
    0xF89800: """
; ---------------------------------------------------------------------
; Ctrl_Normalise -- the published entry: normalise one control reading
;
; Called from: prom_b thunk slots T_F405F0 (`jp 0xF89800`) and T_F405F4
;          (`jp 0xF89804`).  The eight converted call sites of T_F405F0 are all
;          in AnalogScan and there are EIGHT of them, not six: 0xF8DC63 (W=0),
;          0xF8DC96 (1), 0xF8DCC9 (2), 0xF8DCFC (3), 0xF8DD54 (4), 0xF8DD69 (5),
;          0xF8DDC3 (4) and 0xF8DDD8 (5) -- the last two inside a byte-identical
;          duplicate of the two routines before them.  prom_b calls it at
;          0xF5B14C and 0xF5B1D6, from the SC1 receive decoder.
; Inputs:  W = the channel selector, A = the raw 8-bit reading.
; Outputs: CARRY SET if the cooked value changed, CLEAR if not; A = the cooked
;          value on the "changed" path.  XHL and XIX are saved by the dispatcher.
; Evidence: the callers are the proof of the convention -- AnalogScan loads
;          `ldb w,0x00` .. `ldb w,0x05` immediately before each call and tests
;          `jr nc` immediately after.
; ---------------------------------------------------------------------""",
    0xF89804: """
; Ctrl_Nop_Ret -- T_F405F4's target: a bare RET.  Kept as a label because the
; thunk table publishes it separately.""",
    0xF89805: """
; ---------------------------------------------------------------------
; Ctrl_Normalise_Dispatch -- index = ((W & 0xC0) >> 1) | ((W & 7) << 2)
;
; Called from: Ctrl_Normalise.
; Evidence: the index is built in four instructions and used as a BYTE offset
;          into an LE32 table, so its maximum, 0x60 | 0x1C = 0x7C, is entry 31 --
;          that is what makes the table 32 entries and not more.  ⚠ There is NO
;          bounds check, and none is needed: the arithmetic cannot exceed 0x7C.
; ---------------------------------------------------------------------""",
    0xF898AD: """
; ---------------------------------------------------------------------
; The TEN live handlers.  Every one has the same shape, and the differences
; between them are the whole content of this module:
;
;   slot  raw slot  curve      cooked   idle value when (0xC4) == 2
;   0.0   0x24D0    0xF89BB4   0x2505   0x40
;   0.1   0x24D1    0xF89BB4   0x2506   0x40
;   0.2   0x24D2    0xF89EB4   0x24FF   0x00     + the 0x007F5A calibration
;   0.3   0x24D3    0xF89DB4   0x24F2   0x00     + the raw byte is INVERTED first
;   0.4   0x24D4    0xF89B34   0x2503   (no idle arm)
;   0.5   0x24D5    0xF89B34   0x2504   (no idle arm)
;   3.0   0x24E8    0xF89C34   0x24F5   0x00
;   3.1   0x24E9    0xF89CB4   0x24F4   0x80     + indexed by the RAW byte
;   3.2   0x24EA    0xF89B34   0x24F6   0x40
;   3.3   0x24EB    0xF89AB4   0x24F3   (no idle arm)
;
; and the tail is shared: `scf` then return means "changed", `rcf` then return
; means "no change, ignore this reading".
; ---------------------------------------------------------------------""",
}


def roundtrip(lo, hi):
    out = subprocess.run([sys.executable,
                          os.path.join(ROOT, "prom_a", "roundtrip.py"),
                          "0x%06X" % lo, "0x%06X" % hi, "--block"],
                         capture_output=True, text=True, check=True)
    if "round-trip: OK" not in out.stderr:
        sys.exit("roundtrip.py did not certify 0x%06X-0x%06X" % (lo, hi))
    return out.stdout.splitlines()


ADDR_RE = re.compile(r';\s*([0-9A-F]{6})\b')


def annotate(lines):
    out, pending = [], []
    for line in lines:
        if re.match(r'^\.L[0-9A-F]+:\s*$', line):
            pending.append(line)
            continue
        m = ADDR_RE.search(line)
        a = int(m.group(1), 16) if m else None
        if a in HEADERS:
            out.append("")
            out.extend(HEADERS[a].strip("\n").split("\n"))
        if a in HANDLERS:
            out.append(HANDLERS[a] + ":")
        elif a == 0xF89800:
            out.append("Ctrl_Normalise:")
        elif a == 0xF89804:
            out.append("Ctrl_Nop_Ret:")
        elif a == 0xF89805:
            out.append("Ctrl_Normalise_Dispatch:")
        out.extend(pending)
        pending = []
        out.append(line)
    out.extend(pending)
    return out


CURVE_TABLES = [
    (0xF89AB4, 128, "Ctrl_Curve_Identity128",
     "identity 0..127; used by slot 3.3 (0xF89A96 `ld XIX,0x00F89AB4`)"),
    (0xF89B34, 128, "Ctrl_Curve_Compressed",
     "slots 0.4, 0.5 and 3.2 (0xF899BD, 0xF899E1, 0xF89A74)"),
    (0xF89BB4, 128, "Ctrl_Curve_Compressed_PlusMinus1",
     "slots 0.0 and 0.1 (0xF898C7, 0xF898FA).  40 of its 128 bytes DIFFER "
     "from Ctrl_Curve_Compressed -- 21 are one HIGHER and 19 one LOWER, all "
     "between indices 37 and 89 -- and the other 88 are equal.  CORRECTED "
     "2026-08-25 (audit F2): the old name and comment said \"one higher\", "
     "which is half of it (notes/prom_a_ctrl_checks.py asserts 21 up, 19 down)"),
    (0xF89C34, 128, "Ctrl_Curve_Identity128_Copy",
     "slot 3.0 (0xF89A44).  BYTE-IDENTICAL to Ctrl_Curve_Identity128 -- two "
     "copies of the same 128 bytes, 0x180 apart"),
    (0xF89CB4, 256, "Ctrl_Curve_Wide256_A",
     "slot 3.1 (0xF89A11).  Indexed by the RAW byte, so all 256 entries are "
     "reachable; range 0..255"),
    (0xF89DB4, 128, "Ctrl_Curve_Concave128",
     "slot 0.3 (0xF89999).  CORRECTED 2026-08-25 (audit F3): this was "
     "`Ctrl_Curve_Expo128`, a shape claim the bytes contradict.  Evidence, "
     "re-derived by notes/prom_a_ctrl_checks.py: monotone non-decreasing, "
     "spans 0..127, and ABOVE the diagonal -- 32->54, 64->80, 96->104, "
     "deviation -1..+22, mean +11.9.  That is CONCAVE; the convex tables in "
     "this tiling are 0xF89E34 (mean -5.8) and 0xF89EB4 (mean -46.7)"),
    (0xF89E34, 128, "Ctrl_Curve_Unreferenced128",
     "⚠ NOTHING REFERENCES THIS.  A census of the little-endian immediate "
     "0x00F89E34 over prom_a AND prom_b finds zero sites, and the same census "
     "finds every other table here at the `ld XIX,imm32` that uses it "
     "(notes/prom_a_ctrl_checks.py)"),
    (0xF89EB4, 256, "Ctrl_Curve_Wide256_B",
     "slot 0.2 (0xF89926).  Indexed by the RAW byte; range 0..255"),
    (0xF89FB4, 11, "Ctrl_SpanTable",
     "slot 0.2's calibration span, indexed by (0x7F5F); the base is formed by "
     "`add XHL,0x00F89FB4` at 0xF89953, not by an `ld XIX`.  ⚠ ELEVEN is "
     "the number of bytes before the module's 0x0E pad, NOT a bound the ROM "
     "checks: the use site does not range-check the index"),
]


def emit_bytes(lo, n, label, note):
    out = ["", "; " + note.replace("\n", "\n; "), label + ":"]
    for i in range(0, n, 16):
        chunk = rom(lo + i, min(16, n - i))
        out.append("\t.byte " + ", ".join("0x%02X" % b for b in chunk)
                   + " " * 3 + "; %06X" % (lo + i))
    return out


def main():
    outdir = sys.argv[sys.argv.index("--out-dir") + 1]
    os.makedirs(outdir, exist_ok=True)
    body = [BANNER.strip("\n")]
    body += annotate(roundtrip(*CODE1))

    # ---- the handler table, emitted symbolically ---------------------------
    n_entries = (TABLE[1] - TABLE[0]) // 4
    body += ["", "; ---------------------------------------------------------------------",
             "; Ctrl_HandlerTable -- %d LE32 entries." % n_entries,
             "; The dispatcher can form byte offsets 0x00..0x7C, so entries 0..31 are the",
             "; reachable ones; entries 32 and 33 lie beyond the largest index the",
             "; arithmetic at 0xF89805 can produce and are both the ignore handler.",
             "; Emitted SYMBOLICALLY: if a label below is at the wrong address the byte",
             "; gate fails, so this table checks the names rather than describing them.",
             "; ---------------------------------------------------------------------",
             "Ctrl_HandlerTable:"]
    for i in range(n_entries):
        v = u32(TABLE[0] + 4 * i)
        if v not in HANDLERS:
            sys.exit("table entry %d -> 0x%06X has no label" % (i, v))
        body.append("\t.long %-24s ; %06X  grp %d ch %d"
                    % (HANDLERS[v], TABLE[0] + 4 * i, i // 8, i % 8)
                    + ("   ⚠ beyond index 0x7C" if i >= 32 else ""))

    body += annotate(roundtrip(*CODE2))

    # ---- the curve tables --------------------------------------------------
    body += ["", "; ====================================================================",
             "; The eight response curves and the span table, 0x%06X-0x%06X."
             % (CURVES, PAD[0] - 1),
             "; They tile with no gap.  Each table's extent is the distance to the",
             "; next one's own base address, and the last runs to the module pad.",
             "; ===================================================================="]
    cur = CURVES
    for lo, n, label, note in CURVE_TABLES:
        if lo != cur:
            sys.exit("curve tables do not tile: expected 0x%06X, got 0x%06X"
                     % (cur, lo))
        body += emit_bytes(lo, n, label, note)
        cur += n
    if cur != PAD[0]:
        sys.exit("curve tables end at 0x%06X, pad starts at 0x%06X" % (cur, PAD[0]))

    # ---- the pad -----------------------------------------------------------
    npad = PAD[1] - PAD[0]
    if set(rom(PAD[0], npad)) != {0x0E}:
        sys.exit("the range 0x%06X-0x%06X is not uniform 0x0E" % (PAD[0], PAD[1] - 1))
    body += ["",
             "; 0x%06X-0x%06X -- %d bytes of 0x0E (RET), module padding."
             % (PAD[0], PAD[1] - 1, npad),
             "; Checked byte by byte, not sampled: notes/gen_prom_a_ctrl_module.py",
             "; refuses to emit this directive unless set(ROM[lo:hi]) == {0x0E}.",
             "\t.fill %d, 1, 0x0E" % npad]

    path = os.path.join(outdir, "ctrl.s")
    open(path, "w").write("\n".join(body) + "\n")
    print("wrote %s (%d bytes of ROM: 0x%06X-0x%06X)" % (path, HI - LO, LO, HI - 1))


if __name__ == "__main__":
    main()
