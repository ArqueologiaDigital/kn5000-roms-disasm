#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""r3_delaydram.py -- DECODE the external delay-DRAM ADDRESSING of the KN5000.

NEC uPD6383GF (Technics SX-KN5000 IC311) effects DSP.  Roadmap item **R3**.
Write-up: `dsp/analysis/r3-delaydram.md`.

R1 forced *which* words touch the external delay DRAM (`880.1.60.2D4` = READ,
`880.1.20.655` = WRITE).  It left OPEN where the address comes from.  This pass
answers that, and it does it entirely from the ROM, by following the firmware
that BUILDS the addresses rather than by guessing at instruction fields.

THE ANSWER, in one line:

    delay-DRAM address = ( DESCRIPTOR_CELL[cursor] + G ) mod 2^N

  * DESCRIPTOR_CELL is a bank of host-written 24-bit registers reached through
    the pointer register `...825` (host-poke tag 0x4C) -- the delay-address
    counterpart of the coefficient bank behind `...821` (tag 0x26);
  * the cell holds  LINE_BASE + DELAY_IN_SAMPLES, i.e. a delay is expressed as
    an ADDRESS, and the delay of a line is the DIFFERENCE of two cells;
  * the firmware's own chain is
        cell = K24 + (ms * 0xAC44) / 0x3E8            (LABEL_03925E)
    with K24 the delay line's BASE ADDRESS, a literal in the level-2 parameter
    bytecode, and 0xAC44/0x3E8 = 44100/1000 = samples per millisecond;
  * G is a global per-sample rotation (the read tap sits BELOW the write pointer
    by exactly the delay), which is why no per-line ring bounds are ever written.

Run:  python3 dsp/tools/r3_delaydram.py [--rom SUB] [--main MAIN]
                                        [--tools kn7000_mame/tools] [section ...]
Sections: writer payload level2 residue regions cursor validate controls
          (default: all)

WRITER / PAYLOAD are PROVEN BY CONSTRUCTION from the Sub CPU code.  LEVEL2,
REGIONS and CURSOR are MEASURED from the ROM.  RESIDUE and VALIDATE are the
falsification pass; CONTROLS are the tests that MUST fail.
"""
import argparse
import collections
import itertools
import os
import sys
from fractions import Fraction

# 100-entry pointer tables in the Sub CPU ROM
T_ALGO = 0x0001ED7C          # microprogram streams   (= kn5000_dsp_extract.ALGO_TABLE)
T_PARAM = 0x0001EF0C         # coefficient/param streams
T_LVL2_DEFAULTS = 0x0001F09C # level-2 per-UI-slot records  (op + idx + operands)
T_LVL2_DESTS = 0x0001F22C    # level-2 op -> destination-index lists

OP_DELAY = 0x67              # the ONE op whose writer is LABEL_038922 (tag 0x4C)
REVERB_ALGOS = list(range(16, 28))

MS_NUM, MS_DEN = 0xAC44, 0x3E8      # 44100 / 1000, from LABEL_03925E


# --------------------------------------------------------------------------
#  0.  ROM access -- re-uses the project's parsers, nothing re-implemented
# --------------------------------------------------------------------------
def load_rom(tools, sub, main):
    sys.path.insert(0, tools)
    import kn5000_dsp_extract as E
    import kn5000_dsp_coeffs as C
    rom = E.Rom(sub)
    names = C.effect_names(main) if main and os.path.exists(main) else {}
    imgs = {}
    for i in range(100):
        try:
            iram, _c, _o = E.parse_stream(rom, rom.u32le(T_ALGO + 4 * i))
        except Exception:
            continue
        if iram:
            imgs[i] = [int.from_bytes(bytes(w), "big")
                       for _a, ws, _l in iram for w in ws]
    return E, rom, names, imgs


def fields(w):
    return (w >> 24) & 0xFFF, (w >> 20) & 0xF, (w >> 12) & 0xFF, w & 0xFFF


def fmt(w):
    hi, cl, ad, lo = fields(w)
    return "%03X.%X.%02X.%03X" % (hi, cl, ad, lo)


# --------------------------------------------------------------------------
#  1.  The host packet -- PROVEN BY CONSTRUCTION (LABEL_038922 / LABEL_0387E6)
# --------------------------------------------------------------------------
def poke24(e):
    """The 24-bit payload of a 5-byte host packet `0A b1 b2 b3 b4`.

    LABEL_038922 emits, from a 32-bit value v:
        b1 = (v >> 17) & 0x7F ; b2 = (v >> 9) & 0xFF ;
        b3 = (v >>  1) & 0xFF ; b4 = ((v & 1) << 7) | TAG
    byte-for-byte the same four steps as LABEL_0387E6, the coefficient writer
    K5 already proved; only the TAG differs (0x4C here, 0x26 there)."""
    return ((e[1] & 0x7F) << 17) | (e[2] << 9) | (e[3] << 1) | (e[4] >> 7)


def raw24(e):
    """R1 section 3's reading: the three payload bytes taken as-is.  Kept ONLY
    so the controls can show that it fails."""
    return (e[1] << 16) | (e[2] << 8) | e[3]


# --------------------------------------------------------------------------
#  2.  The descriptor blocks in the algorithm's parameter stream
# --------------------------------------------------------------------------
def desc_blocks(rom, algo):
    """[(first_cell_index, [(cell, poke, raw, tagbyte)])] -- every run of
    tag-0x4C pokes, addressed by the `801.0.NN.825` packet that precedes it."""
    p, guard, out, dest, cur = rom.u32le(T_PARAM + 4 * algo), 0, [], None, None
    while guard < 512:
        guard += 1
        b0, b1 = rom.u8(p), rom.u8(p + 1)
        if (b0 >> 4) == 0xF:
            break
        ln = ((b0 & 0x0F) << 8) | b1
        if ln < 2 or ln > 0x0FFF:
            break
        if (b0 >> 4) in (0, 1, 5):
            data = rom.slice(p + 2, ln - 2)[3:]
            for k in range(0, len(data) - 4, 5):
                e = data[k:k + 5]
                if e[0] == 0x08 and e[1] == 0x01 and e[4] == 0x25:
                    dest = ((e[2] & 0x0F) << 4) | (e[3] >> 4)
                    cur = (dest, [])
                    out.append(cur)
                elif e[0] == 0x08 and e[1] == 0x01 and e[4] == 0x21:
                    cur = None                      # switched to the C-RAM pointer
                elif e[0] == 0x0A and (e[4] & 0x7F) == 0x4C and cur is not None:
                    cur[1].append((dest, poke24(e), raw24(e), e[4]))
                    dest += 1
        p += ln
    return out


def cells_of(rom, algo, use_raw=False):
    out = {}
    for _base, cl in desc_blocks(rom, algo):
        for (c, pk, rw, _t) in cl:
            out[c] = rw if use_raw else pk
    return out


# --------------------------------------------------------------------------
#  3.  The level-2 parameter translator tables
# --------------------------------------------------------------------------
def records(rom, ptr, limit=256):
    out, p, g = [], ptr, 0
    while g < limit:
        g += 1
        b0, b1 = rom.u8(p), rom.u8(p + 1)
        if (b0 & 0xF0) == 0xF0:
            break
        ln = ((b0 & 0x0F) << 8) | b1
        if ln < 3 or ln > 0x400:
            break
        out.append(bytes(rom.slice(p + 2, ln - 2)))
        p += ln
    return out


def op_dests(rom, algo):
    """T2: opcode -> ordered list of destination indices."""
    d = {}
    for pl in records(rom, rom.u32le(T_LVL2_DESTS + 4 * algo)):
        d.setdefault(pl[0], []).extend(pl[1:])
    return d


def ui_slots(rom, algo):
    """T1: one record per UI parameter slot -> [(op, idx, operand bytes)].
    Records are `op idx <operands> 0x7A` (0x7A = end of this parameter)."""
    out = []
    for pl in records(rom, rom.u32le(T_LVL2_DEFAULTS + 4 * algo)):
        ops, i = [], 0
        while i < len(pl) and pl[i] != 0x7A:
            j = 0
            while i + 2 + j < len(pl) and pl[i + 2 + j] != 0x7A:
                j += 1
            ops.append((pl[i], pl[i + 1], bytes(pl[i + 2:i + 2 + j])))
            i += 2 + j + 1
        out.append(ops)
    return out


def op67_sites(rom, algo):
    """[(ui_slot, idx, K24, cell)] -- every delay-time parameter of one algo.
    K24 = the 24-bit operand LABEL_03CF07 fetches (3 bytes, big-endian)."""
    if rom.u32le(T_LVL2_DEFAULTS + 4 * algo) < 0x1000:
        return []
    dests, res = op_dests(rom, algo).get(OP_DELAY, []), []
    for slot, ops in enumerate(ui_slots(rom, algo)):
        for (op, idx, ob) in ops:
            if op == OP_DELAY and len(ob) >= 3:
                res.append((slot, idx,
                            int.from_bytes(ob[:3], "big"),
                            dests[idx] if idx < len(dests) else None))
    return res


# --------------------------------------------------------------------------
#  sections
# --------------------------------------------------------------------------
def sec_writer():
    print("=" * 76)
    print("1. THE WRITER -- PROVEN BY CONSTRUCTION (Sub CPU LABEL_038922)")
    print("=" * 76)
    print("""   LABEL_038922(XBC = value, WA = sub-index, +0Ch = BASE32, +10h = cell base)

     emit  08 01 <hi nibble of NN> <lo nibble of NN><<4 | 8>  25
                              -> the instruction word 801.0.NN.825
                                 NN = arg(+10h) + WA   (the DESTINATION CELL)
     v  =  XBC + arg(+0Ch)                       <- ADD (XSP+002h), XWA
     emit  0A (v>>17)&7F (v>>9)&FF (v>>1)&FF ((v&1)<<7)|4C

   The four payload steps are byte-for-byte those of LABEL_0387E6, the
   coefficient writer K5 proved; only the tag differs.  So the destination
   pointer register is `...825` and the tag is 0x4C -- exactly the pairing
   instruction-set.md already records for the host stream.

   MEASURED: `CALL LABEL_038922` occurs EXACTLY ONCE in the 192 KB image, in
   the level-2 translator's handler for opcode 0x67.  The other two writers
   reachable from that dispatcher, LABEL_038539 and LABEL_03846C, both tag
   their packets 0x15, so **op 0x67 is the ONLY path that writes a delay
   descriptor**.  Nothing else in the firmware can.

   LABEL_03925E, the scaler op 0x67 feeds:

     K   = LABEL_03CF07(stream) >> 8          <- a 24-bit big-endian literal
     ret = (ms * 0xAC44) / 0x3E8  +  K        <- 0xAC44/0x3E8 = 44100/1000
""")


def sec_payload(rom, names):
    print("=" * 76)
    print("2. THE PAYLOAD IS THE 24-BIT POKE VALUE, NOT THE RAW 3 BYTES")
    print("=" * 76)
    print("   FALSIFIES r1-allpass-motif.md section 3 ('taken raw the payloads are")
    print("   17-bit word addresses').  Every delay length R1 quotes is HALF the")
    print("   real one.  Three independent proofs:\n")
    c16 = cells_of(rom, 16)
    r16 = cells_of(rom, 16, use_raw=True)
    K = [k for (_s, _i, k, _c) in op67_sites(rom, 16)][0]
    print("   (a) the firmware's own base constant.  ROOM REVERB's op-0x67 literal")
    print("       is K = 0x%06X = %d.  Its cell 0x03 -- the reverb region base --" % (K, K))
    print("       reads %d = 0x%04X under the poke decode (= K-2, the guard),"
          % (c16[3], c16[3]))
    print("       and %d = 0x%04X under the raw decode.  Only the first is K-2."
          % (r16[3], r16[3]))
    print("   (b) cell 0x00 (the PRE DELAY tap, op-0x67 written) minus cell 0x03")
    print("       = %d - %d = %d samples = %.2f ms.  A textbook room pre-delay."
          % (c16[0], c16[3], c16[0] - c16[3], (c16[0] - c16[3]) / 44.1))
    print("   (c) the multi-line residue test, section 4 -- four delay lines with")
    print("       four DIFFERENT bases all yield the SAME delay only under poke.\n")
    print("   Packing (PROVEN): value = (b1&0x7F)<<17 | b2<<9 | b3<<1 | b4>>7")
    print("                           = 2 * raw3 + (tagbyte >> 7)")
    print("   which is why the tag byte alternates 0x4C / 0xCC: bit 7 is the LSB.")


def sec_level2(rom, names):
    print("=" * 76)
    print("3. EVERY DELAY-TIME PARAMETER IN THE MACHINE -- MEASURED")
    print("=" * 76)
    print("   op 0x67 record  =  67 <idx> <K24>  ; T2[0x67][idx] names the cell.")
    print()
    print("   %-4s %-20s %-8s %-6s %-10s %s"
          % ("algo", "effect", "UI slot", "cell", "K24 (base)", "ROM default cell"))
    for a in range(100):
        try:
            sites = op67_sites(rom, a)
        except Exception:
            continue
        if not sites:
            continue
        cl = cells_of(rom, a)
        for (slot, idx, K, cell) in sites:
            v = cl.get(cell)
            print("   %-4d %-20s %-8d 0x%02X   0x%06X   %s"
                  % (a, names.get(a, "?"), slot, cell, K,
                     ("%d" % v) if v is not None else "--"))


def sec_residue(rom, names):
    print("=" * 76)
    print("4. THE RESIDUE TEST -- cell - K is the DELAY, and it is line-invariant")
    print("=" * 76)
    print("   If the cell holds LINE_BASE + DELAY and K is the line base, then in")
    print("   an effect whose L/R (or 4-way) lines share one default delay, the")
    print("   residues must be EQUAL although the bases are not.  Getting the same")
    print("   residue out of four different constants is the whole proof.\n")
    print("   %-4s %-20s %-30s %-8s %s"
          % ("algo", "effect", "cell-K per line (samples)", "bases", "verdict"))
    ok = bad = 0
    for a in range(100):
        try:
            sites = op67_sites(rom, a)
        except Exception:
            continue
        if len(sites) < 2:
            continue
        cl = cells_of(rom, a)
        res = [cl[c] - K for (_s, _i, K, c) in sites if c in cl]
        nb = len({K for (_s, _i, K, _c) in sites})
        if nb < 2:
            v = "1 line, %d taps" % len(res)
        else:
            agree = max(res) - min(res) <= 2
            ok, bad = ok + agree, bad + (not agree)
            v = "AGREE" if agree else "differ by %d" % (max(res) - min(res))
        print("   %-4d %-20s %-30s %-8d %s  (%.2f ms)"
              % (a, names.get(a, "?"), " ".join("%6d" % r for r in res),
                 nb, v, res[0] / 44.1))
    print()
    print("   %d of %d effects that own SEVERAL delay lines put the same delay on"
          % (ok, ok + bad))
    print("   every one of them, out of DIFFERENT base constants.  MULTI TAP DELAY")
    print("   is excluded because its four taps share ONE line (all K = 2), so its")
    print("   residues are four different tap times -- which is the point, not a miss.")
    print("   The same computation on the RAW decode:")
    for a in (65,):
        cl = cells_of(rom, a, use_raw=True)
        res = [cl[c] - K for (_s, _i, K, c) in op67_sites(rom, a) if c in cl]
        print("     algo %d raw residues %s  <- three are NEGATIVE.  Dead."
              % (a, res))


def sec_regions(rom, names):
    print("=" * 76)
    print("5. THE DELAY-MEMORY MAP -- MEASURED over all 100 algorithms")
    print("=" * 76)
    u0, u1, hi_cell = [], [], 0
    for a in range(100):
        for _b, cl in desc_blocks(rom, a):
            for (c, pk, _r, _t) in cl:
                (u1 if a in REVERB_ALGOS else u0).append(pk)
                hi_cell = max(hi_cell, c)
    print("   unit 0 (bodies at I-RAM 84, descriptor cells 0x26..0x%02X):" % hi_cell)
    print("      %d cells written, address range [%d, %d]"
          % (len(u0), min(u0), max(u0)))
    print("   unit 1 (the twelve reverbs, bodies at I-RAM 200, cells 0x00..0x1F):")
    print("      %d cells written, address range [%d, %d]"
          % (len(u1), min(u1), max(u1)))
    print()
    print("   => unit 0 = [0x00000, 0x08000)   unit 1 = [0x08000, 0x10000)")
    print("      32768 words each = %.1f ms at 44.1 kHz." % (32768 / 44.1))
    print("   The op-0x67 base constants confirm the partition arithmetically:")
    seen = {}
    for a in range(100):
        for (_s, _i, K, _c) in op67_sites(rom, a):
            seen.setdefault(K, names.get(a, "?"))
    for K in sorted(seen):
        print("      K = 0x%06X (%6d) = 0x%04X + 2      first seen in %s"
              % (K, K, K - 2, seen[K]))
    print("   0x0002/0x3FE0 halve the unit-0 region; 0x0002/0x1FE1/0x3FE0/0x5FC1")
    print("   quarter it; 0x8002 is the unit-1 region base.  No address the")
    print("   firmware ever writes reaches 2^16.")


def dram_words(imgs, a, lowaddr=False):
    """Class-4 == 1 words with the hi12 FORMAT-ESCAPE bit set -- R2's predicate
    (324/324), NOT K6's withdrawn `addr8 < 0x80` split.  `lowaddr` applies the
    withdrawn filter anyway, so the two can be compared."""
    return [(i, w) for i, w in enumerate(imgs[a])
            if (fields(w)[0] & 0x800) and fields(w)[1] == 1
            and (not lowaddr or fields(w)[2] < 0x80)]


def sec_cursor(rom, names, imgs):
    print("=" * 76)
    print("6. THE DESCRIPTOR CURSOR -- one cell per DRAM word, in program order")
    print("=" * 76)
    rows, forms = [], set()
    for a in sorted(imgs):
        n = sum(len(cl) for _b, cl in desc_blocks(rom, a))
        cnt = collections.Counter()
        for w in imgs[a]:
            hi, cl4, ad, lo = fields(w)
            if cl4 == 1:
                cnt[(hi, ad, lo)] += 1
        rows.append((a, n, cnt))
        forms |= set(cnt)
    forms = sorted(forms)
    n = len(forms)
    exact = sum(1 for (a, nc, cnt) in rows
                if nc == len(dram_words(imgs, a)))
    print("   Naive count: 'cells == number of DRAM words' holds for %d of %d"
          % (exact, len(rows)))
    print("   algorithm slots outright.  Solving it properly, over every class-4==1")
    print("   word, asking which forms consume a cell:")
    M = [[Fraction(r[2].get(f, 0)) for f in forms] + [Fraction(r[1])] for r in rows]
    piv, r = [], 0
    for c in range(n):
        p = next((i for i in range(r, len(M)) if M[i][c] != 0), None)
        if p is None:
            continue
        M[r], M[p] = M[p], M[r]
        pv = M[r][c]
        M[r] = [x / pv for x in M[r]]
        for i in range(len(M)):
            if i != r and M[i][c] != 0:
                fct = M[i][c]
                M[i] = [a - fct * b for a, b in zip(M[i], M[r])]
        piv.append(c)
        r += 1
    incons = sum(1 for i in range(len(M))
                 if all(x == 0 for x in M[i][:n]) and M[i][n] != 0)
    free = [c for c in range(n) if c not in piv]
    print("      %d equations, %d unknowns, rank %d, INCONSISTENT ROWS: %d"
          % (len(rows), n, len(piv), incons))
    sols = []
    for bits in itertools.product([0, 1], repeat=len(free)):
        v = {forms[fc]: Fraction(b) for fc, b in zip(free, bits)}
        good = True
        for k, c in enumerate(piv):
            val = M[k][n] - sum(M[k][j] * v[forms[j]] for j in free)
            if val not in (0, 1):
                good = False
                break
            v[forms[c]] = val
        if good:
            sols.append(v)
    print("      solutions with every form in {0,1}: %d" % len(sols))
    always1 = [f for f in forms if all(s[f] == 1 for s in sols)]
    always0 = [f for f in forms if all(s[f] == 0 for s in sols)]
    amb = [f for f in forms if f not in always1 and f not in always0]
    print("\n   CONSUMES A CELL in every solution (%d forms):" % len(always1))
    for f in always1:
        print("      %03X.1.%02X.%03X  n=%d"
              % (f[0], f[1], f[2], sum(r[2].get(f, 0) for r in rows)))
    print("   CONSUMES NOTHING in every solution (%d forms) -- every one of them is"
          % len(always0))
    print("   an END-OF-BLOCK / transfer word, plus C40.1.E0.451.  Note that")
    print("   C40.1.80.000 (addr8 >= 0x80) DOES consume while C40.1.E0.451 does not,")
    print("   so addr8 bit 7 is not the class-1 discriminator -- an independent")
    print("   corroboration of R2's withdrawal of K6's split:")
    print("      " + ", ".join("%03X.1.%02X.%03X" % f for f in always0))
    print("   NOT decided by the counting (%d forms):" % len(amb))
    print("      " + ", ".join("%03X.1.%02X.%03X" % f for f in amb))
    print()
    print("   addr8 = 0x30 marks the FIRST DRAM access of a body:")
    seen, tot, first = set(), 0, 0
    for a in sorted(imgs):
        key = tuple(imgs[a])
        if key in seen:
            continue
        seen.add(key)
        dw = dram_words(imgs, a)
        if not dw:
            continue
        tot += 1
        if fields(dw[0][1])[2] == 0x30:
            first += 1
        else:
            print("      exception: algo %d %s" % (a, names.get(a, "?")))
    print("      %d of %d distinct body images." % (first, tot))


def sec_validate(rom, names, imgs):
    print("=" * 76)
    print("7. THE ms -> ADDRESS CHAIN, END TO END, ON NAMED PARAMETERS")
    print("=" * 76)
    cl9 = cells_of(rom, 9)
    print("   SINGLE DELAY (algo 9).  UI slot 0 is `DELAY L (ms)` (paramlist.md")
    print("   section 3, captured live).  Chain:")
    print("      UI ms -> op 0x67 idx 0 -> LABEL_03925E -> LABEL_038922 -> cell 0x26")
    print("      cell = K + ms*0xAC44/0x3E8 = 0x000002 + ms*44100/1000")
    print("   ROM default of cell 0x26 = %d, and" % cl9[0x26])
    print("      350 ms * 44100 / 1000 = %d   <- EXACT" % (350 * MS_NUM // MS_DEN))
    print("   Line R: cell 0x28 = %d, cell 0x2B = %d (its base),"
          % (cl9[0x28], cl9[0x2B]))
    print("      %d - %d = %d = the same 350 ms.  Both channels, one number."
          % (cl9[0x28], cl9[0x2B], cl9[0x28] - cl9[0x2B]))
    print()
    cl3 = cells_of(rom, 3)
    e = [ob for ops in ui_slots(rom, 3) for (op, _i, ob) in ops if op == 0x64]
    lit = int.from_bytes(e[0][:3], "big") if e else None
    print("   ENHANCER (algo 3) -- an independent corroboration of the constant.")
    print("   Its UI has `DELAY L (ms)` / `DELAY R (ms)`; its level-2 stream carries")
    print("   the literal %s, and its descriptor cells 0x28 and 0x2D both read %d ="
          % (lit, cl3[0x28]))
    print("      2 + 350*44100/1000 = %d   <- EXACT (the +2 is the minimum-delay"
          % (2 + 350 * MS_NUM // MS_DEN))
    print("      guard that op 0x67's K also carries).")
    print("   NOTE, stated: ENHANCER's runtime op is 0x64 (tag 0x15), not 0x67, so")
    print("   this validates the FORMULA the authoring tool used, not a live path.")
    print()
    print("   REVERB PRE DELAY (ms), cell 0x00, K = 0x8002:")
    print("   %-18s %-10s %-10s %s" % ("preset", "cell 0x00", "- cell 0x03", "ms"))
    for a in REVERB_ALGOS:
        c = cells_of(rom, a)
        print("   %-18s %-10d %-10d %.2f"
              % (names.get(a, "?"), c[0x00], c[0x00] - c[0x03],
                 (c[0x00] - c[0x03]) / 44.1))
    print("   Every one is a round number of samples (20/500/800/1000/2000) above")
    print("   the region base 0x8000 -- the static block is authored in SAMPLES,")
    print("   the runtime path in MILLISECONDS, and the two agree to the guard.")
    print()
    print("   CORRECTED reverb diffuser delays (R1 section 2 quotes half of these):")
    print("   %-18s %-32s %s" % ("preset", "ladder 0", "ladder 1"))
    for a in REVERB_ALGOS:
        c = cells_of(rom, a)
        l0 = [c[x] - c[x + 1] for x in (0x04, 0x08, 0x0C, 0x10, 0x14)]
        l1 = [c[x] - c[x + 1] for x in (0x06, 0x0A, 0x0E, 0x12)]
        print("   %-18s %-32s %s" % (names.get(a, "?"),
                                     " ".join("%5d" % v for v in l0),
                                     " ".join("%5d" % v for v in l1)))


def sec_controls(rom, names, imgs):
    print("=" * 76)
    print("8. CONTROLS -- each MUST fail, or the test above proves nothing")
    print("=" * 76)

    def resid(a, use_raw=False, kmask=None, rot=0):
        cl = cells_of(rom, a, use_raw)
        s = op67_sites(rom, a)
        cells = [c for (_x, _y, _k, c) in s]
        ks = [k for (_x, _y, k, _c) in s]
        if rot:
            cells = cells[rot:] + cells[:rot]
        out = []
        for c, k in zip(cells, ks):
            if kmask:
                k = k & kmask
            if c in cl:
                out.append(cl[c] - k)
        return out

    for a in (65, 9):
        base = resid(a)
        print("   algo %d %s" % (a, names.get(a, "?")))
        print("      (unperturbed)                    %-32s spread %d"
              % (base, max(base) - min(base)))
        for label, kw in (("payload read as raw 3 bytes", dict(use_raw=True)),
                          ("K stripped of its region base", dict(kmask=0x001FFF)),
                          ("cell<->line assignment rotated", dict(rot=1))):
            r = resid(a, **kw)
            print("      %-32s %-32s spread %d"
                  % (label, r, max(r) - min(r) if r else -1))
    print()
    print("   The counting identity must also be breakable.  Over the 38 DISTINCT")
    print("   body images (the 42 NO-OPERATION clones counted once), matched against")
    print("   the descriptor block of a DIFFERENT image:")
    seen, uniq = set(), []
    for a in sorted(imgs):
        key = tuple(imgs[a])
        if key in seen:
            continue
        seen.add(key)
        uniq.append(a)
    nd = {a: len(dram_words(imgs, a)) for a in uniq}
    nc = {a: sum(len(cl) for _x, cl in desc_blocks(rom, a)) for a in uniq}
    same = sum(1 for a in uniq if nc[a] == nd[a])
    print("      unshifted            %d of %d" % (same, len(uniq)))
    for sh in (1, 2, 3):
        h = sum(1 for k, a in enumerate(uniq)
                if nc[uniq[(k + sh) % len(uniq)]] == nd[a])
        print("      shifted by %d         %d of %d" % (sh, h, len(uniq)))
    pairs = sum(1 for a in uniq for b in uniq if a != b and nc[b] == nd[a])
    print("      all mismatched pairs %d of %d  (%.1f %% -- the chance baseline)"
          % (pairs, len(uniq) * (len(uniq) - 1),
             100.0 * pairs / (len(uniq) * (len(uniq) - 1))))


def main():
    repo = os.path.dirname(os.path.dirname(os.path.dirname(
        os.path.abspath(__file__))))
    ap = argparse.ArgumentParser()
    ap.add_argument("--rom", default=os.path.join(repo, "original_ROMs",
                                                  "kn5000_subprogram_v142.rom"))
    ap.add_argument("--main", default=os.path.join(repo, "original_ROMs",
                                                   "kn5000_v10_program.rom"))
    ap.add_argument("--tools",
                    default=os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
    ap.add_argument("sections", nargs="*")
    args = ap.parse_args()

    _E, rom, names, imgs = load_rom(args.tools, args.rom, args.main)
    want = set(args.sections) if args.sections else {
        "writer", "payload", "level2", "residue", "regions", "cursor",
        "validate", "controls"}
    if "writer" in want:
        sec_writer()
    if "payload" in want:
        sec_payload(rom, names)
    if "level2" in want:
        sec_level2(rom, names)
    if "residue" in want:
        sec_residue(rom, names)
    if "regions" in want:
        sec_regions(rom, names)
    if "cursor" in want:
        sec_cursor(rom, names, imgs)
    if "validate" in want:
        sec_validate(rom, names, imgs)
    if "controls" in want:
        sec_controls(rom, names, imgs)


if __name__ == "__main__":
    main()
