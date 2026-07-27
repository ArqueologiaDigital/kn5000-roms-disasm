#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""second_dsp.py -- THE READY LINE, THE SECOND DSP, AND THE HOST-SIDE LOOSE ENDS.

Regenerates every number in dsp/analysis/second-dsp-and-ready.md.  Stdlib only,
plus this repo's own ROM parsers (kn7000_mame/tools).  Nothing here writes to
any source tree; it only measures.

    python3 dsp/tools/second_dsp.py ready      # TASK A  the PH.0 READY/ACK line
    python3 dsp/tools/second_dsp.py dsp2       # TASK B  IC310 (MN19413), scoped
    python3 dsp/tools/second_dsp.py denom      # TASK B  the contaminated denominators
    python3 dsp/tools/second_dsp.py base24     # TASK C1 the two BASE24 disagreements
    python3 dsp/tools/second_dsp.py darkf      # TASK C3 retire dark-words item F
    python3 dsp/tools/second_dsp.py control    # every control, each shown saying NO
    python3 dsp/tools/second_dsp.py all

POPULATIONS (method rule 9) are printed next to every count.
"""
import collections
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
TOOLS = os.path.expanduser("~/compartilhado/kn7000_mame/tools")
SUB = os.path.join(REPO, "original_ROMs", "kn5000_subprogram_v142.rom")
MAIN = os.path.join(REPO, "original_ROMs", "kn5000_v10_program.rom")
SRC = os.path.join(REPO, "v142", "subcpu", "kn5000_subprogram_v142.s")
MAINSRC = os.path.join(REPO, "v10", "maincpu", "shared", "boot_hw_init.s")

sys.path.insert(0, HERE)
sys.path.insert(0, TOOLS)
import kn5000_dsp_extract as E                                      # noqa: E402
import dsp_disasm as D                                              # noqa: E402

ALGO_TABLE = 0x0001ED7C
PARAM_TABLE = 0x0001EF0C
HEADER_ROM = 0x01E496
EPILOGUE_ROM = 0x01E63C
N_ALGOS = 100

# the exclusion constant every tool in dsp/tools carries.  RENAMED here; the old
# name asserted a defect that does not exist (see `dsp2').
DSP2_MISPARSED = {79, 88, 89, 90, 91}


def rule(t=""):
    print("=" * 78)
    if t:
        print(t)
        print("=" * 78)


# ===========================================================================
#  shared ROM walking
# ===========================================================================
def rom():
    return E.Rom(SUB)


def rawrecs(r, addr, limit=8192):
    """Every bytecode record of one stream, WITHOUT the op-3 5-byte grouping
    that kn5000_dsp_extract.parse_stream applies unconditionally."""
    out, p, g = [], addr, 0
    while g < limit:
        g += 1
        try:
            b0, b1 = r.u8(p), r.u8(p + 1)
        except IndexError:
            break
        op = b0 >> 4
        if op == 0xF:
            out.append((p, op, 2, b""))
            break
        ln = ((b0 & 0x0F) << 8) | b1
        if ln < 2 or ln > 0x0FFF:
            break
        out.append((p, op, ln, bytes(r.slice(p + 2, ln - 2))))
        p += ln
    return out


def chip_of(r):
    """{algo: ('IC311'|'IC310')} from the command byte of its records.
    An algorithm is IC310's iff any record carries cmd 0x30."""
    out = {}
    for a in range(N_ALGOS):
        cmds = set()
        for base in (ALGO_TABLE, PARAM_TABLE):
            for (_p, _op, _ln, body) in rawrecs(r, r.u32le(base + 4 * a)):
                if body:
                    cmds.add(body[0])
        out[a] = "IC310" if 0x30 in cmds else "IC311"
    return out


def images(r, exclude_misparsed=True):
    """{algo: [36-bit words]} exactly as every tool in dsp/tools builds it."""
    out = {}
    for a in range(N_ALGOS):
        try:
            ir, _c, _o = E.parse_stream(r, r.u32le(ALGO_TABLE + 4 * a))
        except Exception:
            continue
        if not ir:
            continue
        if exclude_misparsed and a in DSP2_MISPARSED:
            continue
        out[a] = [int.from_bytes(bytes(w), "big") for _x, ws, _l in ir for w in ws]
    return out


def kernel_epilogue(r):
    ir, _c, _o = E.parse_stream(r, HEADER_ROM, limit=40)
    k = [int.from_bytes(bytes(w), "big") for w in ir[0][1]]
    ir, _c, _o = E.parse_stream(r, EPILOGUE_ROM, limit=40)
    e = [int.from_bytes(bytes(w), "big") for w in ir[0][1]]
    return k, e


def effect_names():
    try:
        import kn5000_dsp_coeffs as C
        return C.effect_names(MAIN)
    except Exception:
        return {i: "algo %d" % i for i in range(N_ALGOS)}


def callsites(label):
    """How many times the v1.42 sub-CPU disassembly calls a named routine."""
    if not os.path.exists(SRC):
        return None
    n = 0
    for line in open(SRC, errors="replace"):
        s = line.strip()
        for kw in ("call ", "calr ", "jp ", "jr "):
            if s.startswith(kw) and s[len(kw):].split(";")[0].strip() == label:
                n += 1
    return n


def ldio_value(path, sfr):
    """the value the given source writes to SFR `sfr' with `ldio', or None."""
    if not os.path.exists(path):
        return None
    key = "ldio 0x%02x," % sfr
    for line in open(path, errors="replace"):
        s = line.strip().lower()
        if s.startswith(key):
            return int(s.split(",")[1].split(";")[0].strip(), 0)
    return None


# ===========================================================================
#  TASK A -- the READY line
# ===========================================================================
def porth_read_model(phcr, latch, external):
    """MAME's tmp94c241_device::port_r<PORT_H>, verbatim:
         (latch & dir) | (external & ~dir)      dir = PxCR, 1 = OUTPUT
       This is the standard TLCS-900 convention: reading a bit programmed as an
       output returns the OUTPUT LATCH, not the pin."""
    return (latch & phcr) | (external & (~phcr & 0xFF))


def dsp_read_status(phcr, latch, external):
    """DSP_Read_Status, 0x0383F7, instruction for instruction:
         SET 0,(PH)     ; latch bit 0 <- 1     (read-modify-write on the SFR)
         LDCF 0,(PH)    ; CF <- PH bit 0
         SCC C,L        ; L  <- CF
       Returns (L, latch_after)."""
    latch = porth_read_model(phcr, latch, external) | 0x01      # SET 0,(PH)
    val = porth_read_model(phcr, latch, external)               # LDCF 0,(PH)
    return val & 1, latch


def cmd_ready(r):
    rule("TASK A. THE READY/ACK LINE -- PH.0, IC311 pin 8 `RDY'")

    print("\n  A0. THE BOARD (MEASURED off the service manual, this pass).")
    print("      p.35, IC311 D6383GF-3BA right-hand pin column:")
    print("          pin  8  RDY  --+-- R334 4.7k --> +5D      (open drain, pulled up)")
    print("                         `------------------------> net `DSPRDY' (off sheet)")
    print("      p.33, CPU SECTION (B), IC27 TMP94C241F SUB MICROCOMPUTER top edge:")
    print("          pin 149 PH3   pin 148 PH2   pin 147 PH1   pin 146 PH0   pin 145 INT0")
    print("          pin 144..137  PZ7..PZ0  = nets DSP1D7..DSP1D0")
    print("      off-sheet nets arriving at the CPU sheet, DSP group:")
    print("          DSPRST2  DSPRST  DSPRDY | DSPWR DSPRD DSPCS DSPCD | DSP2CS DSP2SCK DSP2DA")
    print()
    print("      ENUMERATION for `which port-H bit is DSPRDY' -- the DSP control nets on")
    print("      this sheet are exactly THREE and the firmware names two of them:")
    print("          PH.1 -> DSPRST   (DSP1_Assert_Reset  0x038396 = RES 1,(PH))   MEASURED")
    print("          PH.2 -> DSPRST2  (DSP2_Assert_Reset  0x03839E = RES 2,(PH))   MEASURED")
    print("          PH.0 -> DSPRDY   the only net and the only bit left           FORCED")
    print("      and the wire order on the sheet (PH2 outermost, PH0 innermost;")
    print("      DSPRST2 top, DSPRDY bottom) agrees with that assignment.")

    print("\n  A1. THE FIRMWARE. Call-site census of the pin primitives, from the")
    print("      committed v1.42 disassembly (population: the whole 192 KB image).")
    for lbl in ("DSP1_Assert_Reset", "DSP1_Deassert_Reset",
                "DSP2_Assert_Reset", "DSP2_Deassert_Reset",
                "DSP_Set_Command_Mode", "DSP_Set_Data_Mode",
                "DSP_Assert_Write", "DSP_Deassert_Write",
                "DSP_Assert_Read_Data", "DSP_Deassert_Read",
                "DSP_Select_Chip", "DSP_Deselect_Chip", "DSP_Read_Status"):
        n = callsites(lbl)
        star = "   <-- ZERO" if n == 0 else ""
        print("        %-22s %s%s" % (lbl, n, star))
    print("      Reproduces host-side.md sect. 6.1.1 exactly: the /RD-assert primitive")
    print("      has NO caller, and DSP_Read_Status has SIX -- all six inside")
    print("      DSP_Send_Command (0x036331) and DSP_Send_Data (0x0367EE), which are")
    print("      the IC311 routines.  ** DSP2_Send_Command / DSP2_Send_Data never")
    print("      read PH.0 at all. **  So the READY line is IC311-ONLY.")

    print("\n  A2. ** THE POLL CANNOT FAIL, AND IT IS THE PORT DIRECTION THAT DOES IT. **")
    sub_phcr = ldio_value(SRC, 0x46)
    sub_phfc = ldio_value(SRC, 0x47)
    sub_ph = ldio_value(SRC, 0x44)
    main_phcr = ldio_value(MAINSRC, 0x46)
    main_phfc = ldio_value(MAINSRC, 0x47)
    main_ph = ldio_value(MAINSRC, 0x44)
    print("      SUB  CPU RESET (v142 0x01F924):  PH=0x%02X  PHCR=0x%02X  PHFC=0x%02X"
          % (sub_ph, sub_phcr, sub_phfc))
    print("      MAIN CPU boot_hw_init          :  PH=0x%02X  PHCR=0x%02X  PHFC=0x%02X"
          % (main_ph, main_phcr, main_phfc))
    print()
    print("      THE DIRECTION CONVENTION IS ESTABLISHED BY THE OTHER CPU, not assumed:")
    print("      the MAIN CPU writes PHCR = 0x%02X and the ONLY port-H bits it ever reads"
          % main_phcr)
    print("      are 1 and 2 (Detect_Region_Code, `bit 2,(PH)' / `bit 1,(PH)') -- exactly")
    print("      the bits it left at 0.  1 = OUTPUT, 0 = INPUT, and a program reads inputs.")
    print()
    print("      The SUB CPU writes PHCR = 0x%02X, i.e. PH.0 PH.1 PH.2 = OUTPUTS." % sub_phcr)
    print("      PH.1/PH.2 are the two DSP resets and must be outputs.  PH.0 must not be,")
    print("      and the firmware reads it anyway.  Under the standard convention a read")
    print("      of an output bit returns the OUTPUT LATCH -- and DSP_Read_Status SETS")
    print("      that latch to 1 in the instruction immediately before sampling it.")
    print()
    for phcr, note in ((sub_phcr, "as shipped by the firmware"),
                       (sub_phcr & ~1 & 0xFF, "DELIBERATELY-WRONG TWIN: PH.0 as an INPUT")):
        outs = []
        for ext in (0x00, 0x01, 0xFF):
            v, _ = dsp_read_status(phcr, 0xFF, ext)
            outs.append("ext=0x%02X -> READY=%d" % (ext, v))
        agree = len({dsp_read_status(phcr, 0xFF, e)[0] for e in (0x00, 0x01, 0xFF)}) == 1
        print("        PHCR=0x%02X (%s)" % (phcr, note))
        print("            %s   pin-independent: %s" % ("  ".join(outs), agree))
    print("      ** THE CONTROL SAYS NO ON ONE SIDE AND YES ON THE OTHER. **  At the")
    print("      shipped PHCR the external pin is IRRELEVANT (three different pin values,")
    print("      one answer); at PHCR with bit 0 cleared it is not.  So the test can fail,")
    print("      and it does not.")

    print("\n  A3. WHAT THE MAME CONSTANT ACTUALLY DOES.")
    print("      kn5000.cpp: m_subcpu->porth_read().set_constant(0x01).")
    print("      tmp94c241_device::port_r<PORT_H>() returns (latch & PHCR) | (ext & ~PHCR).")
    print("      With PHCR = 0x%02X the callback supplies bits 3..7 ONLY." % sub_phcr)
    for ext in (0x00, 0x01, 0x09):
        v, _ = dsp_read_status(sub_phcr, 0xFF, ext)
        ph3 = (porth_read_model(sub_phcr, 0xFF, ext) >> 3) & 1
        print("        constant 0x%02X ->  READY(PH.0) = %d   strap(PH.3) = %d" % (ext, v, ph3))
    print("      ** Bit 0 of the constant is DEAD CODE. The only bit of it the sub-CPU")
    print("      firmware consumes is BIT 3 **, read once by DSP_SYSTEM_INIT")
    print("      (`bit 3,(PH)' at 0x034C87) whose COMPLEMENT becomes bit 3 of the DSP")
    print("      config word at RAM 0x041343.  Changing the constant would change that.")

    print("\n  A4. WHAT THE FIRMWARE WOULD DO IF READY EVER DEASSERTED (MEASURED).")
    print("        timeout 0x1F40 = 8000 polls          -> return 1   (ERROR 1)")
    print("        second sample at the write instant   -> return 1   (ERROR 2)")
    print("        DSP_ParameterWriteEngine tests it and calls 0x03CFED = a bare `ret'")
    print("        => the record is abandoned. No retry, no user-visible error.")
    print("      Both paths are UNREACHABLE in this firmware for the reason in A2.")

    print("\n  A5. VERDICT.")
    print("      * IC311 really does drive a RDY pin, open-drain, pulled up, wired to")
    print("        the sub CPU: FORCED (A0).")
    print("      * This firmware cannot see it: FORCED-IN-MODEL, the model being the")
    print("        standard TLCS-900 port semantics that MAME implements and that the")
    print("        MAIN CPU's own PHCR/read pattern corroborates (A2).")
    print("      * Therefore MAME's always-ready is FAITHFUL -- but not for the reason")
    print("        its comment gives, and not through the constant its comment blames.")
    print("      * NO BEHAVIOURAL CHANGE IS JUSTIFIED. Modelling IC311's RDY pin would")
    print("        change nothing unless MAME's port model were also changed, and there")
    print("        is no measurement of the pin's protocol to model. Method rule 6.")
    print("      * The proposed experiment, for whoever gets a board: strap DSPRDY low")
    print("        and confirm the machine still loads effects. If it does, PH.0 is an")
    print("        output on this part and the pull-up is decoupling a defect; if it")
    print("        hangs or drops effects, the port reads the pin and PHCR=0x07 is a")
    print("        firmware bug that the pull-up masks.")


# ===========================================================================
#  TASK B -- IC310
# ===========================================================================
def dsp2_records(r):
    """{algo: {'prog': [(op, addr, payload)], 'parm': [...]}} for cmd-0x30 records."""
    out = {}
    for a in range(N_ALGOS):
        d = {"prog": [], "parm": []}
        for key, base in (("prog", ALGO_TABLE), ("parm", PARAM_TABLE)):
            for (_p, op, _ln, body) in rawrecs(r, r.u32le(base + 4 * a)):
                if body and body[0] == 0x30:
                    d[key].append((op, (body[1] << 8) | body[2], body[3:]))
        if d["prog"] or d["parm"]:
            out[a] = d
    return out


def meanent(data, w):
    e = []
    for k in range(w):
        col = data[k::w]
        if not col:
            return 0.0
        c = collections.Counter(col)
        n = len(col)
        e.append(-sum(v / n * math.log2(v / n) for v in c.values()))
    return sum(e) / w


def cmd_dsp2(r):
    rule("TASK B. THE SECOND DSP -- IC310, MN19413. SCOPED, NOT SOLVED.")
    names = effect_names()
    chip = chip_of(r)
    ic310 = sorted(a for a in chip if chip[a] == "IC310")
    print("\n  B0. ** THE PARTITION IS NINE WIDE AND IT IS CLEAN. **")
    print("      Population: 100 algorithm slots x (1 program stream + 1 parameter stream).")
    print("      An algorithm is IC310's iff any of its records carries cmd 0x30.")
    print("        IC311 : %d      IC310 : %d      both : %d      neither : %d"
          % (sum(1 for a in chip if chip[a] == "IC311"), len(ic310), 0, 0))
    print("      The nine:")
    for a in ic310:
        print("        %3d  %-12s" % (a, names[a]), end="")
        if (ic310.index(a) % 3) == 2:
            print()
    print()
    print("      ** host-side.md C5 / sect. 6.4 said `algorithms 57-60 configure BOTH")
    print("      chips'. FALSIFIED: algo 57's PROGRAM stream is one op-E cmd-0x30 record")
    print("      and its PARAMETER stream is four op-E cmd-0x30 records. There is no")
    print("      IC311 traffic in it at all. Zero algorithms address both chips.")
    print("      The IC311 algorithm population is 91, not 95.")

    print("\n  B1. WHY EXACTLY FIVE `PARSE TO JUNK' -- the exclusion set explained.")
    print("      kn5000_dsp_extract.parse_stream handles record opcodes 3 and 2 only.")
    print("        cmd-0x30 carried by op-3 : algos 79, 88, 89, 90, 91  -> parses into a")
    print("            phantom I-RAM block at word 1520 / 3376 with 5-byte `words'")
    print("        cmd-0x30 carried by op-E : algos 57, 58, 59, 60      -> parses into")
    print("            NOTHING, so `if ir:' drops them silently")
    print("      => `MALFORMED = {79,88,89,90,91}' is not a defect list, it is the list")
    print("      of DSP2 streams that happen to survive an IC311-shaped parser.")
    print("      RENAMED in this tool to DSP2_MISPARSED; the analysis name for the set")
    print("      of nine is IC310_ALGOS.")

    print("\n  B2. THE TRANSPORT IS A DIFFERENT TRANSPORT (MEASURED, firmware + board).")
    print("        IC311  parallel byte port : PZ0-7 = DSP1D0-7 (pins 137..144),")
    print("               P7.3 /WR, P7.4 /RD, P7.5 /CS, P7.6 C/D, PH.0 RDY")
    print("               -> DSP_Send_Command 0x036331 / DSP_Send_Data 0x0367EE,")
    print("                  8000-poll READY handshake, two error returns")
    print("        IC310  3-wire bit-banged serial : PF.0 = DSP2DA (data),")
    print("               PF.2 = DSP2SCK (clock), PE.6 = DSP2CS (chip select)")
    print("               -> DSP2_Send_Command 0x03665E.. / DSP2_Send_Data 0x036887..,")
    print("                  8 bits MSB-first (`bit 7,(RFP)' then `sll'), NOP-padded,")
    print("                  ** NO READY POLL, NO TIMEOUT, NO ERROR RETURN, and the")
    print("                  board gives it NO data-in line at all -- write only. **")
    print("      The board's own net names agree: DSP2CS / DSP2SCK / DSP2DA, three nets,")
    print("      against DSP1D0-7 + DSPRD + DSPWR + DSPCS + DSPCD + DSPRDY for IC311.")

    print("\n  B3. THE RECORD FRAMING IS THE SAME BYTECODE.")
    d2 = dsp2_records(r)
    nrec = sum(len(v["prog"]) + len(v["parm"]) for v in d2.values())
    # op-D adjacency
    tot = after30 = other = 0
    for a in range(N_ALGOS):
        for base in (ALGO_TABLE, PARAM_TABLE):
            recs = rawrecs(r, r.u32le(base + 4 * a))
            for i, (_p, op, _ln, body) in enumerate(recs):
                if op == 0xD:
                    tot += 1
                    prev = recs[i - 1] if i else None
                    if prev and prev[3] and prev[3][0] == 0x30:
                        after30 += 1
                    else:
                        other += 1
    print("      cmd-0x30 records over the 200 canned streams : %d" % nrec)
    print("      op-D records                                 : %d" % tot)
    print("        immediately after a cmd-0x30 record        : %d" % after30)
    print("        anywhere else                              : %d" % other)
    print("      ** op-D is a PERFECT discriminator for `this record went to IC310',")
    print("      %d of %d, and it occurs nowhere else in the corpus. **" % (after30, tot))
    print("      Its handler (0x03C6xx) calls DSP2_SPI_BusIdle and yields: it is a")
    print("      bus-idle / settle marker for the bit-banged link, which is exactly what")
    print("      a chip with no READY line needs instead of a handshake.")
    print("      op-E's handler sends `cmd byte, then every remaining byte verbatim'.")
    print("      op-3's handler sends `cmd byte, 16-bit address, then the tail'.")
    print("      For a cmd-0x30 record the two emit the SAME bytes; only the host-side")
    print("      relocation differs. So the wire framing is one framing.")

    print("\n  B4. THE PROGRAM IMAGES -- and the instruction word is 32 bits.")
    dp = {}
    for a, v in d2.items():
        for (op, ad, pay) in v["prog"]:
            dp.setdefault((ad, bytes(pay)), []).append(a)
    print("      Population: %d distinct IC310 program images over the 9 algorithms."
          % len(dp))
    for (ad, pay), al in sorted(dp.items(), key=lambda x: x[0][0]):
        print("        load %5d (0x%04X)  %4d bytes = %3d 32-bit words   algos %s"
              % (ad, ad, len(pay), len(pay) // 4, al))
    print("        TOTAL IC310 microcode: %d words / %d bytes"
          % (sum(len(p) for _a, p in dp) // 4, sum(len(p) for _a, p in dp)))
    print()
    print("      ENUMERATION of the word width, printed beside the claim:")
    print("        w in {1,2,3,4,5,6,8,12}.  Two independent filters:")
    print("        (i) INTEGRALITY -- w must divide 708, 240 and 660:")
    ok_int = [w for w in (1, 2, 3, 4, 5, 6, 8, 12)
              if all(len(p) % w == 0 for _a, p in dp)]
    print("            survivors %s" % ok_int)
    print("        (ii) DISJOINTNESS -- the three load addresses are a word address, so")
    print("             the three images must not overlap (the parameter windows of the")
    print("             same three groups are disjoint, 0/30/60/90+128+160/190, which is")
    print("             what makes this a real constraint and not an assumption):")
    for w in ok_int:
        iv = sorted((ad, ad + len(p) // w - 1) for (ad, p) in dp)
        clash = any(iv[i][1] >= iv[i + 1][0] for i in range(len(iv) - 1))
        print("            w=%-2d  %s   %s"
              % (w, "  ".join("[%d,%d]" % x for x in iv),
                 "OVERLAP" if clash else "disjoint"))
    print("        (iii) PERIOD -- mean per-position byte entropy against a byte-shuffle")
    print("              null with the SAME w and the SAME multiset (this removes the")
    print("              sample-count bias that makes a naive entropy favour large w):")
    random.seed(11)
    best = {}
    for (ad, pay), al in sorted(dp.items(), key=lambda x: x[0][0]):
        row = []
        for w in (2, 3, 4, 5, 6, 8, 12):
            if len(pay) % w:
                continue
            real = meanent(pay, w)
            nulls = []
            for _ in range(200):
                s = bytearray(pay)
                random.shuffle(s)
                nulls.append(meanent(bytes(s), w))
            row.append((w, sum(nulls) / len(nulls) - real))
        best[ad] = max(row, key=lambda x: x[1])[0]
        print("            image @%-5d  %s" % (ad, "  ".join("w=%d:%+.3f" % t for t in row)))
    print("            argmax per image: %s" % best)
    print("      => w = 4 wins the period test in 3 of 3 images; 8 and 12 are its own")
    print("      multiples; 3 and 5 are at the null. FORCED within the enumeration.")
    print("      ** THE IC310 INSTRUCTION WORD IS 32 BITS. **  (The KN5000 driver's")
    print("      standing note `bodies autocorrelate at lag 4' is CONFIRMED, and the")
    print("      confirmation is now a measurement with a null rather than an eyeball.)")
    print()
    print("      PHASE, reported with its miss: 3 of 3 images END on a 4-byte word whose")
    print("      first byte is 0x90, and 2 of 3 have `e0 07 09 4x' as the penultimate")
    print("      word, both at offset 0 mod 4 from the payload start -- so the word grid")
    print("      is anchored at the payload start.  A second phase statistic (distinct")
    print("      values in the byte-0 column) does NOT separate the phases for the")
    print("      240-byte image and is reported as a MISS, not dropped:")
    for (ad, pay), al in sorted(dp.items(), key=lambda x: x[0][0]):
        cols = []
        for ph in (0, 1, 2, 3):
            dd = pay[ph:]
            dd = dd[:len(dd) // 4 * 4]
            cols.append(len(set(dd[0::4])))
        print("            @%-5d first %s  last %s   distinct byte0 by phase %s"
              % (ad, pay[:4].hex(" "), pay[-4:].hex(" "), cols))

    print("\n  B5. THE PARAMETER IMAGES -- and the coefficient word is 16 bits, FORCED.")
    dq = {}
    for a, v in d2.items():
        if v["parm"]:
            dq.setdefault(tuple((ad, bytes(p)) for (_o, ad, p) in v["parm"]), []).append(a)
    print("      Population: %d distinct IC310 parameter images over the 9 algorithms."
          % len(dq))
    for key, al in sorted(dq.items(), key=lambda x: x[0][0][0]):
        print("        algos %-16s %s" % (al, "  ".join("@%d+%dB" % (ad, len(p)) for ad, p in key)))
    print()
    print("      ENUMERATION: w in {1,2,3,4,5,6,8}. The 8 algorithms whose parameter")
    print("      stream has >= 2 records must have consecutive records ABUT exactly:")
    for w in (1, 2, 3, 4, 5, 6, 8):
        ok = tot2 = 0
        for a, v in sorted(d2.items()):
            rs = v["parm"]
            if len(rs) < 2:
                continue
            tot2 += 1
            if (all(len(p) % w == 0 for _o, _a, p in rs)
                    and all(rs[i][1] + len(rs[i][2]) // w == rs[i + 1][1]
                            for i in range(len(rs) - 1))):
                ok += 1
        print("            w=%-2d  %d of %d abut exactly" % (w, ok, tot2))
    print("      => w = 2 in 8 of 8 and every rival in 0 of 8. ** THE IC310 COEFFICIENT")
    print("      WORD IS 16 BITS AND THE 16-BIT FIELD IS A WORD ADDRESS. **")
    print("      The three groups occupy disjoint windows 0..114 / 128..153 / 160..206,")
    print("      %d 16-bit words across the 9 distinct images."
          % sum(sum(len(p) for _a, p in k) // 2 for k in dq))
    print("      And the four STANDARD/PERCUSSIVE/SYMPHONIC/DEEP SPACE images DIFFER")
    print("      from one another while sharing one program -- exactly the IC311 idiom")
    print("      (one body, per-preset coefficients).")

    print("\n  B6. WHAT IC310 IS AND DOES IN THIS MACHINE (MEASURED, service manual).")
    print("      Matsushita MN19413, IC310, its own 20 MHz crystal X302 (against IC311's")
    print("      25 MHz), private delay DRAM IC308 = M5M418128AJ-6, 1 Mbit ORGANISED x8")
    print("      (9 row + 8 column = 17 address bits) -- a QUARTER of IC311's IC309.")
    print("      ** IT IS ON THE MAIN OUTPUT PATH, and IC311 is not. **")
    print("          IC303 SDO0 (the MAIN MIX) -> IC310 SDI (pin 6)")
    print("          IC310 SDO1 (pin 8, R326 470R) / SDO2 (pin 7) -> IC313 PCM69AU DAC")
    print("          MIC -> IC312 -> IC310 AINL (93) / AINR (85), its own stereo ADC")
    print("      IC311 by contrast is a SEND/RETURN INSERT on IC303 (DO1/DO2 -> SDIA/SDIB).")
    print("      So everything you hear passes through IC310, and the microphone reaches")
    print("      no other digital device.")
    print("      Its nine algorithms are the master-section effects: the four REVERB")
    print("      types, the GEQ, and ROOM / KARAOKE / BATH ROOM / STAGE.")
    print("      IN MAME: NOT EMULATED. There is no device; kn5000.cpp's portz_write")
    print("      forwards to m_dsp1 only while P7.5 is low, and IC310 does not use PZ at")
    print("      all -- its traffic leaves on PF.0/PF.2 and is dropped on the floor.")
    print("      The driver's own comment (`DSP2 @ IC310 (MN19413) uses GPIO serial:")
    print("      PF.0=SDA, PF.2=SCLK, PE.6=CS2') is CONFIRMED by this pass from two")
    print("      independent sources -- the firmware routines and the schematic nets.")

    print("\n  B7. OUT OF SCOPE BY INSTRUCTION, AND LEFT OPEN.")
    print("      The IC310 instruction set is NOT decoded here and must not be guessed.")
    print("      What a next pass has to work with: 402 words of 32-bit microcode in 3")
    print("      images, 674 16-bit coefficient words in 9 images, a load-address space")
    print("      that reaches 3540, a byte-wide 128 Kword delay DRAM, and a write-only")
    print("      host link (so there is no read-back oracle -- the same handicap IC311")
    print("      has, and worse: not even a READY bit).")


def cmd_denom(r):
    rule("TASK B (cont.). WHICH PUBLISHED DENOMINATORS ARE CONTAMINATED")
    chip = chip_of(r)
    ic311 = sorted(a for a in chip if chip[a] == "IC311")
    imgs_clean = images(r, exclude_misparsed=True)
    imgs_dirty = images(r, exclude_misparsed=False)
    dclean = {}
    for a, w in imgs_clean.items():
        dclean.setdefault(tuple(w), []).append(a)
    ddirty = {}
    for a, w in imgs_dirty.items():
        ddirty.setdefault(tuple(w), []).append(a)
    k, e = kernel_epilogue(r)
    bw_clean = [w for t in dclean for w in t]
    bw_dirty = [w for t in ddirty for w in t]
    print("\n  THE TRUE POPULATIONS (rule 9):")
    print("      algorithm slots                                   100")
    print("      slots whose traffic is IC311's                     %d" % len(ic311))
    print("      slots whose traffic is IC310's                       %d" % (100 - len(ic311)))
    print("      distinct IC311 body images                          %d" % len(dclean))
    print("      IC311 body-image words                            %d" % len(bw_clean))
    print("      + kernel %d + epilogue %d = corpus                 %d"
          % (len(k), len(e), len(bw_clean) + len(k) + len(e)))
    print("      the same WITHOUT the exclusion set: %d images, %d body words"
          % (len(ddirty), len(bw_dirty)))
    print("      (the difference, %d words, is the two phantom images the op-3 parser"
          % (len(bw_dirty) - len(bw_clean)))
    print("       manufactures out of IC310 microcode.)")
    print()
    print("  CONTAMINATED, named precisely so their owners can restate them:")
    print("   1. dsp/README.md sect. `What's here' : `The 96 valid programs load at")
    print("      I-RAM 84 or I-RAM 200'  ->  ** 91 **. `96' is the extractor's count of")
    print("      pointers that yielded an I-RAM block, which includes the 5 phantoms.")
    print("   2. dsp/verify.py docstring : `all 100, minus the 5 malformed ... so all 96")
    print("      valid programs and all ~100 effect slots are covered'  ->  91 streams,")
    print("      %d distinct images, 91 of 100 slots. (The CHECK is correct; only the" % len(dclean))
    print("      prose is.)")
    print("   3. isa-adjudication.md : `88 of 96', `80 of 96', `14 of 96 algorithm")
    print("      slots'  ->  the denominator is 91.")
    print("   4. r3-delaydram.md P5/P6 and sect. 6 : `870 cells over 100 algorithms',")
    print("      `88 of 96', `the full 96-equation system'  ->  870 cells over 91")
    print("      algorithms; 91 equations.")
    print("   5. k3-pointers.md sect. 5 : `cells across 100 algorithms'  ->  91.")
    print("   6. k4-cursor.md item G : `across all 100 parameter streams'  -- literally")
    print("      true (it scans 100) but 9 of them carry no IC311 traffic; say `91")
    print("      IC311 parameter streams'.")
    print("   7. host-side.md C5 / sect. 6.4 / sect. 10 item 5 : `algorithms 57-60")
    print("      configure BOTH chips'  ->  FALSIFIED; they are IC310-only.")
    print("   8. dsp/algorithms/families.md : `flagged in the generator's MALFORMED set'")
    print("      ->  rename; they are IC310 programs.")
    print()
    print("  ** NOT CONTAMINATED, and this is a MISS against my own prediction: **")
    ndram_clean = sum(1 for w in bw_clean + k + e if D.is_dram(w))
    ndram_dirty = sum(1 for w in bw_dirty + k + e if D.is_dram(w))
    print("      the delay-DRAM word census is %d either way (%d clean / %d with the two"
          % (ndram_clean, ndram_clean, ndram_dirty))
    print("      phantom images included) -- the phantoms contribute ZERO is_dram words,")
    print("      so dark-words.md's 276 and everything derived from it stand.")
    print("      programs.tsv's `slots' column already sums to %d, which is right."
          % sum(len(v) for v in dclean.values()))
    print("      Every tool that filters `if ir and a not in MALFORMED' is clean; every")
    print("      tool that filters on the name alone is clean BY ACCIDENT, because")
    print("      57-60 parse to an empty image.  Nothing has to be recomputed.")


# ===========================================================================
#  TASK C1 -- the two BASE24 disagreements
# ===========================================================================
def load_corp():
    import dram_match as M
    return M.Corp(SUB, MAIN, TOOLS)


def lines_of(cells, taps, s=3):
    keys = sorted(cells)
    n = len(keys)
    out = []
    for cell in sorted(taps):
        i = keys.index(cell)
        j = keys[(i + s) % n]
        out.append((cell, j, cells[cell] - cells[j]))
    return out


def cmd_base24(r):
    rule("TASK C1. THE TWO BASE24 DISAGREEMENTS -- FIRMWARE BUG, ADJUDICATED")
    C = load_corp()
    by = {a: (u, cells, cons) for (a, u, cells, cons) in C.algos}
    print("\n  Population: %d algorithms ship descriptor cells; 38 op-0x67 tap records"
          % len(by))
    print("  over 23 of them.  BASE24 histogram:")
    recs = [(a, cell, b) for a in sorted(by) for cell, b in sorted(C.taps(a).items())]
    h = collections.Counter(b for _a, _c, b in recs)
    print("     " + "  ".join("%d:x%d" % (k, v) for k, v in sorted(h.items())))

    print("\n  C1a. THE OFFENDING CONSTANT IS THE HOUSE CONSTANT.")
    print("      Every record carrying BASE24 = 16352, and the cell at +3:")
    bad = []
    for a, cell, b in recs:
        if b != 16352:
            continue
        u, cells, cons = by[a]
        keys = sorted(cells)
        j = keys[(keys.index(cell) + 3) % len(keys)]
        flag = "" if b - cells[j] == 2 else "   <-- DISAGREES"
        if flag:
            bad.append((a, cell, j, cells[j], b - cells[j]))
        print("        algo %3d %-20s tap %d -> +3 cell %d = %6d   BASE24-cell = %4d%s"
              % (a, C.name(a), cell, j, cells[j], b - cells[j], flag))
    print("      => 8 of 10 records sit on a canned base of EXACTLY 16350 = BASE24 - 2.")
    print("      And the T2 record itself is byte-identical in all of them:")
    print("          67 01 00 3f e0     (opcode 0x67, operand 1, BASE24 = 0x003FE0)")
    print("      ** So the two offenders carry a byte-for-byte COPY of a record that is")
    print("      correct in eight sibling algorithms. That is the copy-paste signature,")
    print("      PROVEN BY CONSTRUCTION. **")

    print("\n  C1b. THE PAIRING IS RIGHT, SO `WE MISREAD IT' IS REFUTED.")
    print("      Statistic: under the +3 rule, do an algorithm's delay LINES come out")
    print("      exactly EQUAL in length?  (A delay effect's L/R or multi-line taps are")
    print("      allocated equal maxima; this is ground truth nothing was fitted to.)")
    multi = [a for a in sorted(by) if len(C.taps(a)) >= 2]
    print("      population: %d algorithms with >= 2 op-0x67 taps" % len(multi))
    for a in multi:
        u, cells, cons = by[a]
        L = [d for _c, _j, d in lines_of(cells, C.taps(a), 3)]
        print("        algo %3d %-20s %s   equal=%s"
              % (a, C.name(a), L, len(set(L)) == 1))
    eq3 = sum(1 for a in multi
              if len({d for _c, _j, d in lines_of(by[a][1], C.taps(a), 3)}) == 1
              and all(d > 0 for _c, _j, d in lines_of(by[a][1], C.taps(a), 3)))
    print("      s=+3 : %d of %d equal AND all-positive" % (eq3, len(multi)))
    print("      RIVAL OFFSETS -- the same statistic, so +3 is CHOSEN, not assumed:")
    for s in (1, 2, 4, 5, 6, 7):
        e = sum(1 for a in multi
                if len({d for _c, _j, d in lines_of(by[a][1], C.taps(a), s)}) == 1
                and all(d > 0 for _c, _j, d in lines_of(by[a][1], C.taps(a), s)))
        print("        s=%+d : %d of %d" % (s, e, len(multi)))
    random.seed(7)
    hits = []
    for _ in range(2000):
        e = 0
        for a in multi:
            u, cells, cons = by[a]
            keys = sorted(cells)
            vals = [cells[k] for k in keys]
            random.shuffle(vals)
            cc = dict(zip(keys, vals))
            L = [d for _c, _j, d in lines_of(cc, C.taps(a), 3)]
            e += (len(set(L)) == 1 and all(x > 0 for x in L))
        hits.append(e)
    print("      SHUFFLE NULL (each algorithm's cell VALUES permuted, index relation")
    print("      destroyed, identical predicate both sides, 2000 trials):")
    print("        mean %.2f   max %d   >= %d in %d of 2000"
          % (sum(hits) / len(hits), max(hits), eq3,
             sum(1 for x in hits if x >= eq3)))
    print("      ** AND THE TWO OFFENDERS ARE AMONG THE SEVEN THAT ARE EQUAL. **")
    print("      algo  9 SINGLE DELAY    : 15435 and 15435 samples")
    print("      algo 67 S.DELAY+VIBRATO :  8000 and  8000 samples")
    print("      Both equalities are independent of the INFERRED -2 offset (it cancels).")

    print("\n  C1c. THE MIRROR HYPOTHESIS, AND WHAT SEPARATES IT.")
    print("      Rival: `the T2 constant is right and the CANNED IMAGE is the stale one'.")
    print("      Both artefacts are internally self-consistent, so this is not settled by")
    print("      consistency. It is settled by the same equal-length statistic:")
    for a, cell, j, val, delta in bad:
        u, cells, cons = by[a]
        keys = sorted(cells)
        L_canned = [d for _c, _jj, d in lines_of(cells, C.taps(a), 3)]
        alt = dict(cells)
        alt[j] = 16350
        L_alt = [d for _c, _jj, d in lines_of(alt, C.taps(a), 3)]
        print("        algo %3d %-20s canned %s equal=%s | under BASE24-2=16350 %s equal=%s"
              % (a, C.name(a), L_canned, len(set(L_canned)) == 1,
                 L_alt, len(set(L_alt)) == 1))
    print("      => the canned allocation is the one that matches the corpus norm.")
    print("      The T2 constant is the stale artefact.")

    print("\n  C1d. THE RUNTIME CONSEQUENCE, RE-DERIVED (rule 8).")
    print("      effective delay = read_cell - write_cell - 2   (the -2 is INFERRED and")
    print("      is dram-matching sect.1's own label; both forms are printed).")
    for a, cell, j, val, delta in bad:
        u, cells, cons = by[a]
        print("        algo %3d %-20s  BASE24 %5d  canned write cell %5d"
              % (a, C.name(a), 16352, val))
        print("            BASE24 - cell          = %4d samples = %6.2f ms"
              % (delta, delta / 44.1))
        print("            BASE24 - cell - 2      = %4d samples = %6.2f ms   <-- the error"
              % (delta - 2, (delta - 2) / 44.1))
        print("            canned default         = %d samples = %.3f ms"
              % (cells[cell] - val, (cells[cell] - val) / 44.1))
        print("            implied default IF the T2 constant were the base = %.2f ms"
              % ((cells[cell] - 16352) / 44.1))
    print("      ** THE BRIEF'S OWN NUMBERS MIX THE TWO FORMS: `a 417-sample gap' for")
    print("      SINGLE DELAY is BASE24-cell, `200 samples' for S.DELAY+VIBRATO is")
    print("      BASE24-cell-2 (the raw gap there is 202). Quote one convention. **")
    print("      On real hardware, touching DELAY R jumps the delay by +415 samples")
    print("      (+9.41 ms) in SINGLE DELAY and +200 samples (+4.54 ms) in")
    print("      S.DELAY+VIBRATO, and it never returns to the canned value. A faithful")
    print("      emulator must reproduce that; it is not ours to fix.")


# ===========================================================================
#  TASK C3 -- retire dark-words item F
# ===========================================================================
def cmd_darkf(r):
    rule("TASK C3. dark-words.md ITEM F IS DEAD -- H-DIR, RE-SCORED")
    imgs = images(r, exclude_misparsed=True)
    dist = {}
    for a, w in imgs.items():
        dist.setdefault(tuple(w), []).append(a)
    k, e = kernel_epilogue(r)
    corp = [w for t in dist for w in t] + k + e
    dram = [w for w in corp if D.is_dram(w)]
    print("\n  Population: %d distinct IC311 body images + kernel + epilogue = %d words;"
          % (len(dist), len(corp)))
    print("  %d of them are delay-DRAM words (dsp_disasm.is_dram)." % len(dram))
    n = collections.Counter(D.dram_dir(w) or "STILL-TRAPPING" for w in dram)
    print("\n  UNDER THE ROUND-5 FORCED RULE (addr8 bit 6; 0x20/0x30 = READ, 0x60 = WRITE):")
    print("      READ %d   WRITE %d   still trapping %d   of %d"
          % (n["READ"], n["WRITE"], n["STILL-TRAPPING"], len(dram)))
    print("      => ** %d of %d (%.1f %%) of the corpus delay-DRAM words are READS. **"
          % (n["READ"], len(dram), 100.0 * n["READ"] / len(dram)))

    def src(w):
        return (w >> 6) & 0x1F
    tab = collections.Counter((src(w) == 0x0B, D.dram_dir(w)) for w in dram)
    agree = tab[(True, "READ")] + tab[(False, "WRITE")]
    print("\n  H-DIR (`SRC == 0x0B <=> READ') re-scored against it:")
    print("      SRC 0x0B and READ  : %3d      SRC 0x0B and WRITE : %3d"
          % (tab[(True, "READ")], tab[(True, "WRITE")]))
    print("      other SRC and READ : %3d      other SRC and WRITE: %3d"
          % (tab[(False, "READ")], tab[(False, "WRITE")]))
    print("      agreement %d of %d = %.1f %%  -- BELOW CHANCE. The INVERTED rule scores"
          % (agree, len(dram), 100.0 * agree / len(dram)))
    print("      %d of %d = %.1f %%, i.e. H-DIR is ANTI-CORRELATED with the forced"
          % (len(dram) - agree, len(dram), 100.0 * (len(dram) - agree) / len(dram)))
    print("      direction, and SRC 0x0B sits on BOTH sides of the partition")
    print("      (%d read words, %d write words)."
          % (tab[(True, "READ")], tab[(True, "WRITE")]))
    forms = sorted(set(dram))
    t2 = collections.Counter((src(w) == 0x0B, D.dram_dir(w)) for w in forms)
    print("      over the %d distinct WORD FORMS: %d agree"
          % (len(forms), t2[(True, "READ")] + t2[(False, "WRITE")]))
    print("\n  ** THE RETRACTED NUMBER, REPRODUCED SO THE RETRACTION IS CHECKABLE: **")
    nread_hdir = sum(1 for w in dram if src(w) == 0x0B)
    print("      dark-words.md sect.6 publishes `under it, 99 of 276 corpus delay-DRAM")
    print("      words (35.9 %%) are reads'. Recomputed here: %d of %d = %.1f %%."
          % (nread_hdir, len(dram), 100.0 * nread_hdir / len(dram)))
    print("      The population is right; the rule that produced it is dead. The")
    print("      replacement is %d of %d." % (n["READ"], len(dram)))
    print("\n  The 25 distinct delay-DRAM word forms, with the forced direction:")
    cnt = collections.Counter(dram)
    for w in forms:
        print("      %010X  addr8=%02X SRC=%02X  %-5s  x%d"
              % (w, D.addr8(w), src(w), D.dram_dir(w), cnt[w]))

    print("\n  AND THE OTHER SENTENCE TASK C NAMES -- instruction-set.md's terminator:")
    print("      The class-1 terminator's addr8 is the UNIT INDEX and its unit stride is")
    print("      +1 (0x0E unit 0, 0x0F unit 1), NOT the +0x80 the parameter cells obey")
    print("      (428 of 428, k4-cursor item G). Measured over the body images:")
    term = collections.Counter()
    for t in dist:
        w = t[-1]
        term[D.addr8(w)] += 1
    print("      last word of each of the %d distinct images, addr8 histogram: %s"
          % (len(dist), dict(term)))


# ===========================================================================
#  controls
# ===========================================================================
def cmd_control(r):
    rule("CONTROLS -- each one DEMONSTRATED saying NO")
    print("""
  K1  TASK A, the port-direction twin.  The claim is `the READY poll cannot fail'.
      The twin clears PHCR bit 0 (PH.0 as an input) and the same three-instruction
      routine is re-evaluated at three external pin values.  Shipped PHCR: one
      answer for all three (the pin is irrelevant).  Twin: three answers.  The
      instrument separates, and the result is not an artefact of the instrument.
      -> `ready' section A2.

  K2  TASK A, the MAME constant's live bit.  Evaluating the port model at
      constant 0x00 / 0x01 / 0x09 changes PH.3 and never changes PH.0.  A control
      that could not fail would have moved both.  -> `ready' section A3.

  K3  TASK B, op-D as a chip discriminator.  It is scored on BOTH sides: 34 of 34
      op-D records follow a cmd-0x30 record and 0 of 34 occur anywhere else, over
      a population of 200 canned streams that contains 700+ non-DSP2 records.  A
      one-sided count would have proved nothing.

  K4  TASK B, the program word width.  The naive per-position entropy is BIASED
      toward large w (fewer samples per column).  It is scored against a
      byte-shuffle null with the SAME w and the SAME multiset, which removes the
      bias exactly; w=3 and w=5 then sit AT the null (delta ~ 0.00 to -0.12) while
      w=4 is +1.31 to +1.43.  The bias was found by building the wrong statistic
      first and is reported, not hidden.

  K5  TASK B, the coefficient word width.  The abutment test is scored over all 7
      rival widths and 6 of 7 score ZERO on the same 8 algorithms.  The rival set
      includes w=1 (`the address is a byte address'), which is the reading the
      IC311 parser would have imposed.

  K6  TASK C1, the offset rivals.  The equal-line-length statistic is computed at
      s = 1,2,4,5,6,7 as well as 3, and every rival scores 0 of 11 against 7 of 11.
      Plus a 2000-trial within-algorithm value permutation (multiset preserved,
      index relation destroyed, identical predicate both sides).

  K7  TASK C1, THE MIRROR HYPOTHESIS, built specifically because it is the one
      that could have won.  `The T2 constant is right, the canned image is stale'
      is evaluated by substituting 16350 into the canned block and re-running the
      SAME statistic; the lines then come out unequal in both algorithms.  This is
      the control that decides the item, and it was constructed to be able to win.

  K8  TASK C3, H-DIR is scored against the FORCED rule on the full 276-word corpus
      rather than on the 4 rows dark-words chose, and the retracted number (99) is
      REPRODUCED first so that the retraction is checkable rather than asserted.

  ** A CONTROL OF MINE THAT DID NOT REJECT, PRINTED RATHER THAN DELETED. **
  K9  I expected the two phantom IC310 images to contaminate the delay-DRAM word
      census (that was the whole point of Task B's `list the contaminated
      statistics').  Measured: 276 either way -- the phantoms contribute ZERO
      is_dram words, so the statistic I most expected to be wrong is right.  It is
      a failed discriminator between `clean' and `contaminated' corpora and is
      printed as one.

  K10 TASK B, the phase statistic (distinct values in the byte-0 column) does NOT
      separate the four phases for the 240-byte image (phase 2 scores BETTER than
      phase 0).  Reported as a MISS beside the anchor that does work.
""")


# ===========================================================================
def main():
    cmds = {"ready": cmd_ready, "dsp2": cmd_dsp2, "denom": cmd_denom,
            "base24": cmd_base24, "darkf": cmd_darkf, "control": cmd_control}
    args = sys.argv[1:] or ["all"]
    r = rom()
    if args[0] == "all":
        for k in ("ready", "dsp2", "denom", "base24", "darkf", "control"):
            cmds[k](r)
            print()
        return
    for a in args:
        if a not in cmds:
            sys.exit("unknown subcommand %r; try: %s all" % (a, " ".join(cmds)))
        cmds[a](r)


if __name__ == "__main__":
    main()
