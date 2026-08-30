#!/usr/bin/env python3
"""What do the WSA1 and the KN5000 SHARE at the TLCS-900 level -- chips, protocols, code?

QUESTION IT ANSWERS
    The project goal asks for a cross-reference against the other Technics keyboard
    disassembly efforts to find common CHIPS, PROTOCOLS and shared SNIPPETS OF CODE.
    `scripts/analysis/kn5000_shared_runs.py` already answers "which BYTES are shared".
    This answers the three questions that byte identity cannot:

      1. Do the two CPUs present the same peripherals at the same addresses?  (--sfr)
      2. Is the inter-processor link the same PROTOCOL?                        (--link)
      3. Is serial channel 0 driven by the same ROUTINE?                       (--serial)
      4. What KIND of thing are the 32,795 byte-identical bytes?               (--runs)
      5. Does the within-tree routine-diff method transfer across trees?       (--method)
      6. For each off-CPU device, which tree has the better note?              (--chips)

    plus `--diff A B N`, which runs notes/prom_c_prom_a_routine_diff.py's alignment on
    any two sites in either tree.  ⚠ Section E is the answer to question 5 and it is
    NEGATIVE: positional alignment survives one build with a substituted constant and
    falls apart across two builds of the same source.  Do not quote its "identical text"
    count as evidence that two routines are unrelated.

THE FOUR HEADLINES, each reproduced by a --selftest check

  ★★ A.  THE TWO PARTS SHARE THE PERIPHERAL VOCABULARY AND ALMOST NONE OF THE MAP.
      68 register names appear in both trees' SFR includes.  Exactly ONE, PBFC, lands
      at the same address (0x2F), and nothing distinguishes it from a coincidence.
      So: a KN5000 SFR address transplanted into this tree is wrong 67 times out of 68,
      and byte-identical code between the two ROMs essentially cannot contain an SFR
      access.  Three further traps the diff exposes:
        * CAP4L/CAP4H is the SAME NAME for DIFFERENT HARDWARE -- timer 6/7's capture
          registers on the TMP95C061 (0x46/0x47), timer 4/5's on the TMP94C241
          (0x94/0x95).
        * INTET10 / INTET01 (and 32/23, 54/45, 76/67) are the SAME REGISTER spelled in
          the opposite order, so a name-keyed cross-reference under-counts by four.
        * The block-chip-select register is 8 bits wide with 4 areas on the TMP95C061
          and 16 bits wide with 6 areas on the TMP94C241, and the MSAR/MAMR pair is in
          the OPPOSITE ORDER (MSAR first at 0x3C, MAMR first at 0x142).  That is
          structural support for notes/FINDINGS-memory-map.md's refusal to import the
          sibling's MAMR reading: it is not the same register.

  ★★ B.  THE INTER-PROCESSOR LINK IS ONE PROTOCOL, IMPLEMENTED FOUR TIMES.
      KN5000 sub-CPU boot 0xFF881F, KN5000 sub-CPU payload 0x020E86, WSA1 prom_a
      0xF8E47F and WSA1 prom_c 0xF99BBE are the same state machine: guard on bit 2 of
      the handshake port, read the latch, dispatch on the command byte, arm micro-DMA,
      clear bit 1 of the same port.  Identical across both machines: command 0xE1 = 6
      bytes and selector 2, 0xE2 = 10 bytes and selector 3, anything else = (b & 0x1F)+1
      bytes and selector 1, and the DMA start-vector value 0x0A -- interrupt number 10,
      INT0, on BOTH parts -- which re-points the interrupt that announced the message
      at the DMA engine.
      ★ What the sibling adds: it NAMES the handshake bits.  docs/subcpu_boot_protocol.md
      calls PD bit 2 MSTAT0 (main->sub, input to the receiver) and PD bit 1 SSTAT1
      (sub->main, output).  Those are the same bit numbers this tree tests and clears on
      P7, so P7.2 = "the far side is asserting" and P7.1 = the acknowledge.
      ⚠ Bit-number agreement across two different ports on two different boards is
      CORROBORATION, not proof; no WSA1 schematic is in these trees.

  ★★ C.  (0x77) IS NOT A MAILBOX.  IT IS INTES0, AND THE SIBLING WRITES THE SAME BYTES.
      notes/FINDINGS-midi-port.md says "it writes 0xFD to (0x77) ... so (0x77) is a
      one-byte mailbox to the foreground, not a register", and prom_a's
      MIDI_PostSendWork / MIDI_UART_Configure headers repeat it.  0x77 is INTES0 in this
      tree's OWN include/tmp95c061_sfr.inc, and MAME maps 0x70-0x7A to inte_r/inte_w
      (tmp95c061.cpp:171).  Decoded against tmp95c061.cpp:521-529 (levels) and :1272-1281
      (inte_w keeps a flag written as 1, clears it written as 0):
          0xFD  INTTX0 level 7 -- check_irqs scans 1..6 only, so TX-ready is DISABLED
          0xDD  INTTX0 level 5 -- TX-ready RE-ENABLED  ("wake the transmitter")
          0x5D  same, with bit 7 = 0: clear a stale TX request, then enable
      And KN5000 SC0Init_EnableRegisters (0xFCF940, v10 main CPU) writes 0x5D to ITS
      INTES0 (0xEA) in the same position of the same routine, MIDI_SC0_ENABLE_TX writes
      0xDD -- the same two constants, correctly named there.
      The routine pair is 8 shared steps in the same order with the same constants
      (ei 6 / SC0MOD=0x29 / SC0CR=0x00 / BR0CR / INTES0=0x5D / SC0BUF=0xFE / ei 0 / ret),
      which also answers prom_a's stated "Unknown: why SC0BUF is written 0xFE at the
      end" -- it is not a WSA1 quirk, both machines prime the transmitter with a byte
      after enabling INTTX0.  ⚠ That 0xFE was chosen because it is MIDI ACTIVE SENSING
      is a READING; what is established is that the step is shared.

  ★  D.  THE SHARED BYTES ARE DSP TABLES AND MATH, NOT DRIVERS.
      --runs maps every surviving run onto the nearest preceding KN5000 symbol.  The
      mass is in the DSP algorithm/curve tables and the floating-point helpers; the
      link, serial and port drivers are NOT in it -- which is exactly what A predicts,
      because a driver names an SFR and an SFR address does not survive the crossing.

BASES AND HOW THEY ARE PINNED (nothing here is assumed)
    WSA1     prom_a 0xF80000, prom_b 0xF00000, prom_c 0xF80000
    KN5000   main-CPU program ROM 0xE00000 (v10/maincpu/maincpu.ld)
             sub-CPU boot ROM     0xFE0000 (128 KiB, reset at 0xFFFF00)
             sub-CPU payload      file offset 0x000-0x0FF -> 0x000400,
                                  file offset >= 0x100    -> file + 0x00EF00
             The payload mapping is DERIVED here, not quoted: check S17 finds the 81
             bytes of DSP_WriteChannelRegs_Inner in the payload file and solves for the
             base against the symbol table's 0x0001FD27.

  ★  E.  A SECOND ROUTINE TWIN, AND TWO LEADS ON prom_a's OWN OPEN QUESTIONS.
      MIDI_PostSendWork (prom_a 0xFA590F) and MIDI_SC0_ENABLE_TX (KN5000 main
      0xFCF991) are the same seven steps: push SR / ei 6 / compare a RAM byte against
      a sentinel / branch / INTES0 = 0xDD / pop SR / ret, with the taken branch calling
      a MIDI-OUT BUFFER INITIALISER and storing zero.  This tree calls its callee
      Ring601432_Init from its own conversion; the sibling calls its
      SeqBuf_MidiOut_Init.  Two names, one role, derived independently.

  ★  F.  THE DOCUMENTATION DEBT RUNS BOTH WAYS -- see --chips.  The FDC
      identification transfers WSA1 -> KN5000 (this tree proved uPD765 with a 32-value
      truth table; that one says "likely uPD765 or equivalent").  A part number
      transfers KN5000 -> WSA1 as a LEAD only: the device whose channel-register
      writer is 35-of-36 identical to this tree's is that tree's IC311, an NEC
      uPD6383GF.  ⚠ Identical driver code does not identify a part; prom_c's refusal
      to name the 0x00E00000 device still stands.

RUN
    python3 notes/wave7_xref_tlcs900_family.py            # all six sections
    python3 notes/wave7_xref_tlcs900_family.py --sfr
    python3 notes/wave7_xref_tlcs900_family.py --link
    python3 notes/wave7_xref_tlcs900_family.py --serial
    python3 notes/wave7_xref_tlcs900_family.py --runs
    python3 notes/wave7_xref_tlcs900_family.py --method
    python3 notes/wave7_xref_tlcs900_family.py --chips
    python3 notes/wave7_xref_tlcs900_family.py --diff wsa1:a:0xF8E47F kn5000:subboot:0xFF881F 0x7B
    python3 notes/wave7_xref_tlcs900_family.py --selftest   # 53 checks

READ-ONLY.  This script opens ROM images, SFR includes, symbol tables and findings
documents in both trees.  It writes nothing and it does not touch any .s file.
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SIB = "/home/fsanches/compartilhado/kn5000-roms-disasm"
UNIDASM = os.environ.get("UNIDASM",
                         "/home/fsanches/compartilhado/kn7000_mame_build/unidasm")

# ---------------------------------------------------------------- images ----
# name -> (path, base) for the flat images; the KN5000 payload is special-cased.
IMAGES = {
    "wsa1:a":  (os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), 0xF80000),
    "wsa1:b":  (os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), 0xF00000),
    "wsa1:c":  (os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), 0xF80000),
    "kn5000:main":    (os.path.join(SIB, "original_ROMs", "kn5000_v10_program.rom"), 0xE00000),
    "kn5000:subboot": (os.path.join(SIB, "original_ROMs", "kn5000_subcpu_boot.ic30"), 0xFE0000),
}
PAYLOAD = os.path.join(SIB, "original_ROMs", "kn5000_subprogram_v142.rom")
PAYLOAD_SPLIT = 0x100          # file offsets below this are the 0x400 trampoline page
PAYLOAD_BASE_LO = 0x000400     # addr = off + this,   for off <  PAYLOAD_SPLIT
PAYLOAD_BASE_HI = 0x00EF00     # addr = off + this,   for off >= PAYLOAD_SPLIT

WSA1_SFR = os.path.join(ROOT, "include", "tmp95c061_sfr.inc")
KN_SFR = os.path.join(SIB, "v142", "subcpu", "shared", "sfr_tmp94c241.s")
KN_SUBSYMS = os.path.join(SIB, "symbols", "subcpu_symbols_reference.txt")
# A sibling symbol whose name contains one of these is a DATA object by that
# tree's own naming, not a routine.  Used only to CLASSIFY the shared runs; the
# classification is printed in full so it can be checked rather than trusted.
DATA_WORDS = ("Table", "Curve", "Bytecode", "Records", "Bitmap", "_Ptr",
              "ConstPool", "Pool")
KN_MAINSYMS = os.path.join(SIB, "symbols", "maincpu_v10_symbols_reference.txt")

# Names in include/tmp95c061_sfr.inc that are NOT registers (documented as such
# in that file's own trailing section: register-address bytes for the (R+) forms).
NOT_SFR = {"MEM_XIX_PI2", "MEM_XIX_PI4"}

# The four INTETxx registers whose two trees spell the same register in opposite
# digit order.  Left = this tree's spelling, right = the sibling's.
TRANSPOSED = [("INTET10", "INTET01"), ("INTET32", "INTET23"),
              ("INTET54", "INTET45"), ("INTET76", "INTET67")]


def payload_addr(off):
    return off + (PAYLOAD_BASE_LO if off < PAYLOAD_SPLIT else PAYLOAD_BASE_HI)


def payload_off(addr):
    if addr < 0x000500:
        return addr - PAYLOAD_BASE_LO
    return addr - PAYLOAD_BASE_HI


def read(name):
    path, base = IMAGES[name]
    return open(path, "rb").read(), base


def fetch(name, addr, n):
    """n bytes at `addr` from image `name` ('kn5000:payload' handled specially)."""
    if name == "kn5000:payload":
        d = open(PAYLOAD, "rb").read()
        o = payload_off(addr)
    else:
        d, base = read(name)
        o = addr - base
    if o < 0 or o + n > len(d):
        raise IndexError("0x%06X + %d outside %s" % (addr, n, name))
    return d[o:o + n]


# -------------------------------------------------------------- disasm -----
LINE = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')


def dis(name, addr, n):
    """[(addr, [bytes], text)] -- unidasm over exactly the n bytes at addr."""
    blob = fetch(name, addr, n)
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(blob)
        tmp = f.name
    try:
        p = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(addr)],
                           capture_output=True, text=True)
    finally:
        os.unlink(tmp)
    out = []
    for ln in p.stdout.splitlines():
        m = LINE.match(ln)
        if m:
            out.append((int(m.group(1), 16), m.group(2).split(), m.group(3).strip()))
    return out


# ----------------------------------------------------------------- SFR -----
EQU = re.compile(r'^\s*\.equ\s+([A-Za-z_][A-Za-z_0-9]*)\s*,\s*(0x[0-9A-Fa-f]+|\d+)')


def sfr_map(path, drop=()):
    d = {}
    for ln in open(path):
        m = EQU.match(ln)
        if m and m.group(1) not in drop:
            d[m.group(1)] = int(m.group(2), 0)
    return d


def sfr_compare():
    w = sfr_map(WSA1_SFR, NOT_SFR)
    k = sfr_map(KN_SFR)
    both = sorted(set(w) & set(k))
    same = [n for n in both if w[n] == k[n]]
    diff = [n for n in both if w[n] != k[n]]
    return w, k, both, same, diff


def section_sfr(verbose=True):
    w, k, both, same, diff = sfr_compare()
    print("=" * 78)
    print("A. SFR MAPS -- TMP95C061 (WSA1) vs TMP94C241 (KN5000)")
    print("=" * 78)
    print("  %-46s %s" % (os.path.relpath(WSA1_SFR, ROOT), len(w)))
    print("  %-46s %s" % (os.path.relpath(KN_SFR, SIB), len(k)))
    print("  register names present in BOTH:            %d" % len(both))
    print("  ... at the SAME address:                   %d   %s"
          % (len(same), ", ".join("%s=0x%02X" % (n, w[n]) for n in same)))
    print("  ... at a DIFFERENT address:                %d" % len(diff))
    print()
    print("  So a sibling SFR address imported into this tree is wrong %d times in %d."
          % (len(diff), len(both)))
    print()
    print("  ⚠ TRAP 1 -- one name, two different peripherals:")
    for n in ("CAP4L", "CAP4H"):
        if n in both:
            print("      %-6s  TMP95C061 0x%02X (timer 6/7 capture)   "
                  "TMP94C241 0x%02X (timer 4/5 capture)" % (n, w[n], k[n]))
    print()
    print("  ⚠ TRAP 2 -- the same register spelled in the opposite order")
    print("      (so a name-keyed cross-reference under-counts the overlap by 4):")
    for a, b in TRANSPOSED:
        print("      %-8s 0x%02X   ==   %-8s 0x%02X" % (a, w.get(a, -1), b, k.get(b, -1)))
    print()
    print("  ⚠ TRAP 3 -- the memory controller is NOT the same register:")
    print("      TMP95C061  B0CS..B3CS  0x%02X..0x%02X   4 areas, ONE byte each"
          % (w["B0CS"], w["B3CS"]))
    print("                 MSAR0 0x%02X then MAMR0 0x%02X   (MSAR FIRST)"
          % (w["MSAR0"], w["MAMR0"]))
    print("      TMP94C241  B0CSL..B5CSH 0x%03X..0x%03X  6 areas, TWO bytes each"
          % (k["B0CSL"], k["B5CSH"]))
    print("                 MAMR0 0x%03X then MSAR0 0x%03X  (MAMR FIRST)"
          % (k["MAMR0"], k["MSAR0"]))
    print("      -> notes/FINDINGS-memory-map.md was right to eliminate rather than")
    print("         import the sibling's MAMR reading: different width, different")
    print("         area count, opposite field order.")
    if verbose:
        print()
        print("  every shared name that moved:")
        for n in diff:
            print("      %-9s  95C061 0x%03X   94C241 0x%03X" % (n, w[n], k[n]))
        print()
        print("  only in the TMP95C061 map (%d): %s" % (len(set(w) - set(k)),
                                                        " ".join(sorted(set(w) - set(k)))))
        print("  only in the TMP94C241 map (%d): %s" % (len(set(k) - set(w)),
                                                        " ".join(sorted(set(k) - set(w)))))
    print()


# ---------------------------------------------------------------- LINK -----
# The four implementations of one protocol.  Lengths are the byte extents this
# script disassembles, each ending on the routine's own reti.
LINK_SITES = [
    ("KN5000 sub-CPU boot ROM", "kn5000:subboot", 0xFF881F, 0x7B, "PD (0x34)", "DMA0V (0x100)"),
    ("KN5000 sub-CPU payload",  "kn5000:payload", 0x020E86, 0x7A, "PD (0x34)", "DMA0V (0x100)"),
    ("WSA1 prom_a (CPU 1)",     "wsa1:a",         0xF8E47F, 0xAE, "P7 (0x13)", "DMA3V (0x7F)"),
    ("WSA1 prom_c (CPU 2)",     "wsa1:c",         0xF99BBE, 0x140, "PA (0x1E)", "DMA3V (0x7F)"),
]


def link_facts(name, addr, n):
    """Read the protocol constants back OFF the instruction text, not off prose."""
    ins = dis(name, addr, n)
    txt = [t for _a, _b, t in ins]
    f = {}
    f["guard_bit2"] = [int(m.group(1), 16) for m in
                       (re.match(r'bit 2,\(0x([0-9a-f]+)\)$', t) for t in txt) if m]
    f["ack_res_bit1"] = [int(m.group(1), 16) for m in
                         (re.match(r'res 1,\(0x([0-9a-f]+)\)$', t) for t in txt) if m]
    # How the command byte is dispatched.  Three of the four use a compare chain;
    # prom_c range-checks (cmd - 0xE1) and indexes a jump table -- the same
    # protocol, a later dispatch.
    f["cmp_E1"] = any(re.search(r'cp \w+,0x0*e1$', t) for t in txt)
    f["cmp_E2"] = any(re.search(r'cp \w+,0x0*e2$', t) for t in txt)
    f["sub_E1"] = any(re.search(r'sub \w+,0x0*e1$', t) for t in txt)
    f["base_E1"] = f["cmp_E1"] or f["sub_E1"]
    f["dispatch"] = "compare chain" if f["cmp_E1"] else "sub 0xE1 + jump table"
    f["mask_1f"] = any(re.search(r'and \w+,0x1f$', t) for t in txt)
    f["inc_1"] = any(re.search(r'inc 1,\w+$', t) for t in txt)
    imm = [(int(m.group(1), 16), int(m.group(2), 16))
           for m in (re.match(r'ld \(0x([0-9a-f]+)\),0x([0-9a-f]+)$', t) for t in txt) if m]
    f["dma_vector_0A"] = sorted({a for a, v in imm if v == 0x0A})
    # (selector, payload count) pairs, in program order: a small immediate store
    # is the selector, and the next literal count is that arm's byte count.
    pairs, pend = [], None
    NUM = re.compile(r'^(?:ld W?A,|push )(?:0x)?([0-9a-f]+)$')
    for t in txt:
        m = re.match(r'ld \(0x[0-9a-f]+\),0x0*([0-9a-f])$', t)
        if m:
            pend = int(m.group(1), 16)
            continue
        m = NUM.match(t)
        if m and pend is not None:
            v = m.group(1)
            pairs.append((pend, int(v, 16) if t.count("0x") else int(v)))
            pend = None
    f["arms"] = pairs
    f["ins"] = ins
    return f


# The byte-level handshake, read off the TRANSMIT routines rather than the receive
# ones: (image, name, address, length, port SFR address, the tree's port name).
HANDSHAKE_SITES = [
    ("WSA1 prom_a (CPU 1)", "wsa1:a", 0xF8E086, 0x4E, 0x13, "P7"),
    ("WSA1 prom_c (CPU 2)", "wsa1:c", 0xF999D0, 0x4E, 0x1E, "PA"),
]


def handshake_bits(img, addr, n, port):
    """{bit: set(ops)} for every bit operation on `port` in [addr, addr+n)."""
    out = {}
    for _a, _b, t in dis(img, addr, n):
        m = re.match(r'(bit|res|set) ([0-7]),\(0x%02x\)$' % port, t)
        if m:
            out.setdefault(int(m.group(2)), set()).add(m.group(1))
    return out


# prom_c does not compare: it range-checks (cmd - 0xE1) and indexes this table.
PROMC_CMD_TABLE = 0xF99BF6
PROMC_CMD_BASE = 0xE1
PROMC_CMD_N = 7


def promc_command_table():
    """[(command byte, arm address, selector, payload bytes)] for prom_c's INT0.

    Reads the 7 LE32 entries off the ROM and then reads each arm's own selector
    store and payload count off ITS disassembly -- so the command-to-selector
    mapping is derived, not asserted.  This independently reproduces the table in
    notes/FINDINGS-prom_c-link-receive.md section 2.
    """
    blob = fetch("wsa1:c", PROMC_CMD_TABLE, 4 * PROMC_CMD_N)
    out = []
    for i in range(PROMC_CMD_N):
        tgt = int.from_bytes(blob[4 * i:4 * i + 4], "little")
        arm = link_facts("wsa1:c", tgt, 0x24)["arms"]
        sel, cnt = arm[0] if arm else (None, None)
        out.append((PROMC_CMD_BASE + i, tgt, sel, cnt))
    return out


def section_link():
    print("=" * 78)
    print("B. THE INTER-PROCESSOR LINK -- one protocol, four implementations")
    print("=" * 78)
    print("  %-26s %-8s %-10s %-11s %-22s %s"
          % ("implementation", "addr", "handshake", "dma vector", "dispatch",
             "default arm / (selector, payload bytes)"))
    for label, img, addr, n, port, dv in LINK_SITES:
        f = link_facts(img, addr, n)
        print("  %-26s 0x%06X %-10s %-11s %-22s %s  %s"
              % (label, addr, port, dv, f["dispatch"],
                 "(b&0x1F)+1" if (f["mask_1f"] and f["inc_1"]) else "----------",
                 " ".join("sel%d/%dB" % (s, c) for s, c in f["arms"])))
    print()
    print("  All four: guard on bit 2 of the handshake port, ack by clearing bit 1 of")
    print("  the SAME port, dispatch on the command byte, arm micro-DMA with the")
    print("  start-vector value 0x0A.")
    print()
    print("  ★ 0x0A is INTERRUPT NUMBER 10 = INT0 on BOTH parts, by two independent")
    print("    citations:")
    print("      TMP95C061  tlcs900_process_hdma computes (DMAnV & 0x1f) << 2 and the")
    print("                 vector map gives INT0 = 0x28; 0x0A << 2 = 0x28.")
    print("                 mame/src/devices/cpu/tlcs900/tmp95c061.cpp:353 and :322-346")
    print("      TMP94C241  the sibling's own reconstruction of the 45-entry vector")
    print("                 table: 'vec 10  INT0 (main->sub latch)'.")
    print("                 kn5000-roms-disasm/v142/subcpu/subcpu_vectors.s:47")
    print("    So both firmwares hand the interrupt that announced the message to the")
    print("    DMA engine, and the CPU is not interrupted again until the count runs out.")
    print()
    print("  The command byte, as each side decodes it:")
    print("      0xE1  ->  6 bytes,  selector 2     both machines")
    print("      0xE2  -> 10 bytes,  selector 3     both machines")
    print("      other -> (b & 0x1F) + 1 bytes, selector 1     both machines")
    print("      the 'no payload, set/clear a flag bit' command differs:")
    print("          KN5000  0xE3  set 6,(0x04FE)   -- boot; 0x04FE = payload-ready")
    print("          WSA1    0xE6  res 6,(0x008A)   -- prom_a")
    print()
    print("  prom_c's 7-entry jump table at 0x%06X, resolved from the ROM and then from"
          % PROMC_CMD_TABLE)
    print("  each arm's own selector store (this reproduces the table in")
    print("  notes/FINDINGS-prom_c-link-receive.md section 2 without quoting it):")
    for cmd, arm, sel, cnt in promc_command_table():
        print("      0x%02X -> arm 0x%06X   selector %-4s payload %s"
              % (cmd, arm, sel, ("%d bytes" % cnt) if cnt is not None else
                 "(b & 0x1F) + 1, computed"))
    print("      so prom_c is the SUPERSET, and its 0xE1/0xE2 arms carry the SAME")
    print("      selector/length pairs the other three implementations do.")
    print()
    print("  ★ WHAT THE SIBLING ADDS AND THIS TREE LACKS: the handshake bits have names")
    print("    there.  kn5000-roms-disasm/docs/subcpu_boot_protocol.md, 'Status Signals':")
    print("        MSTAT0  main CPU Port Z bit 0 (out)  ->  sub CPU Port D bit 2 (in)")
    print("        SSTAT1  sub CPU Port D bit 1 (out)   ->  main CPU Port Z bit 3 (in)")
    print("    Those are the same two bit numbers this tree's INT0_LinkByte tests and")
    print("    clears on P7, so P7.2 reads 'the far side is asserting' and P7.1 is the")
    print("    acknowledge this tree's note calls 'an acknowledge, presumably'.")
    print("    ⚠ CORROBORATION, NOT PROOF: same bit numbers, different port, different")
    print("      board, no WSA1 schematic in these trees.")
    print()
    print("  ★ AND THE WSA1'S OWN TWO CPUs AGREE WITH EACH OTHER, BIT FOR BIT, ON TWO")
    print("    DIFFERENT PORTS.  Bit operations inside the two TRANSMIT routines:")
    for label, img, addr, n, port, pname in HANDSHAKE_SITES:
        hb = handshake_bits(img, addr, n, port)
        print("      %-22s %s (0x%02X)   %s"
              % (label, pname, port,
                 "  ".join("bit %d: %s" % (b, "/".join(sorted(hb[b])))
                           for b in sorted(hb))))
    print("    plus, in the RECEIVE handlers above, bit 2 tested and bit 1 cleared on the")
    print("    same port.  So both WSA1 processors use one 4-wire assignment --")
    print("      bit 0  strobe  (out, res/set)      bit 2  far-side strobe (in, tested)")
    print("      bit 1  ack     (out, cleared)      bit 3  far-side busy   (in, tested)")
    print("    -- and the KN5000 sub-CPU's Port D agrees on bits 0 and 1 as outputs and")
    print("    bit 2 as an input, differing only in putting its second input on bit 4.")
    print()


# -------------------------------------------------------------- SERIAL -----
# The MIDI UART configure routine, both machines.
SER_WSA1 = ("wsa1:a", 0xFA58F0, 0x1F)      # MIDI_UART_Configure .. ret
SER_KN = ("kn5000:main", 0xFCF940, 0x21)   # SC0Init_EnableRegisters .. ret

# A SECOND twin in the same subsystem: "wake the transmitter".
POST_WSA1 = ("wsa1:a", 0xFA590F, 0x17)     # MIDI_PostSendWork .. ret
POST_KN = ("kn5000:main", 0xFCF991, 0x1C)  # MIDI_SC0_ENABLE_TX .. ret

# INTES0 constants and what they mean, decoded against MAME's tmp95c061.
INTES0_VALUES = [
    (0x5D, "TX level 5, TX request flag CLEARED (bit7=0); RX level 5 kept",
     "clear a stale TX request, then enable"),
    (0xDD, "TX level 5, both flags kept", "TX-ready interrupt ENABLED -- wake the sender"),
    (0xFD, "TX level 7, both flags kept", "TX-ready interrupt DISABLED (levels 1..6 only)"),
]


def section_serial():
    w = sfr_map(WSA1_SFR, NOT_SFR)
    k = sfr_map(KN_SFR)
    print("=" * 78)
    print("C. SERIAL CHANNEL 0 -- the same UART-configure routine, and (0x77) = INTES0")
    print("=" * 78)
    a = dis(*SER_WSA1)
    b = dis(*SER_KN)
    print("  WSA1   MIDI_UART_Configure        prom_a 0x%06X" % SER_WSA1[1])
    print("  KN5000 SC0Init_EnableRegisters    main   0x%06X"
          " (symbols/maincpu_v10_symbols_reference.txt)" % SER_KN[1])
    print()
    print("  %-40s | %s" % ("WSA1 prom_a", "KN5000 main CPU"))
    for i in range(max(len(a), len(b))):
        la = "0x%06X  %s" % (a[i][0], a[i][2]) if i < len(a) else ""
        lb = "0x%06X  %s" % (b[i][0], b[i][2]) if i < len(b) else ""
        print("  %-40s | %s" % (la, lb))
    print()
    print("  Same eight steps, same order, same constants:")
    print("      ei 0x06 / SC0MOD=0x29 / SC0CR=0x00 / BR0CR / INTES0=0x5D /")
    print("      SC0BUF=0xFE / ei 0x00 / ret")
    print("  differing only in (a) every SFR address -- SC0MOD 0x%02X vs 0x%02X, SC0CR"
          % (w["SC0MOD"], k["SC0MOD"]))
    print("      0x%02X vs 0x%02X, BR0CR 0x%02X vs 0x%02X, INTES0 0x%02X vs 0x%02X,"
          % (w["SC0CR"], k["SC0CR"], w["BR0CR"], k["BR0CR"], w["INTES0"], k["INTES0"]))
    print("      SC0BUF 0x%02X vs 0x%02X -- and (b) where BR0CR comes from: an immediate"
          % (w["SC0BUF"], k["SC0BUF"]))
    print("      0x0E on the WSA1 (fixed 31250 baud), a RAM byte (0xB7DC) on the KN5000,")
    print("      which has a COM_SELECT switch with MIDI / MAC / PC1 / PC2 positions")
    print("      (kn5000-roms-disasm/v10/maincpu/midi/midi_serial_routines.s:20-24).")
    print("      The WSA1's second BR0CR arm (0x0C) is guarded by a compare that its own")
    print("      source marks NOT REACHED -- a sibling-shaped feature this machine drops.")
    print()
    print("  ★★ CORRECTION OWED TO THIS TREE: (0x77) is INTES0, not a mailbox.")
    print("     notes/FINDINGS-midi-port.md: 'When nothing at all is left it writes 0xFD")
    print("     to (0x77) ... so (0x77) is a one-byte mailbox to the foreground, not a")
    print("     register.'  prom_a's MIDI_PostSendWork and MIDI_UART_Configure headers")
    print("     repeat it.  But include/tmp95c061_sfr.inc itself says '.equ INTES0, 0x77',")
    print("     and MAME maps 0x70-0x7A to inte_r/inte_w (tmp95c061.cpp:171).")
    print()
    print("     Bit layout, from tmp95c061.cpp:322-346 (which flag bit belongs to which")
    print("     interrupt) and :521-529 (level = (reg>>4)&7 for the 0x80 flag, reg&7 for")
    print("     the 0x08 flag): INTES0 bits[2:0] = INTRX0 level, bit 3 = INTRX0 request,")
    print("     bits[6:4] = INTTX0 level, bit 7 = INTTX0 request.  inte_w (:1272-1281)")
    print("     KEEPS a flag written as 1 and CLEARS it written as 0.  check_irqs scans")
    print("     levels 1..6 only (:537), so level 7 is 'never taken'.")
    print()
    for v, decode, meaning in INTES0_VALUES:
        print("       0x%02X  %-58s" % (v, decode))
        print("             -> %s" % meaning)
    print()
    print("     Sites in prom_a (grep 'ldio 0x77' in prom_a/wsa1_prom_a.s):")
    print("       0xFA5491  0xFD   MIDI_TX_Ready, queue empty        -> stop interrupting")
    print("       0xFA56B6  0xDD   MIDI_RT_Start queuer              -> wake the sender")
    print("       0xFA56C5  0xDD   MIDI_RT_Continue queuer           -> wake the sender")
    print("       0xFA5906  0x5D   MIDI_UART_Configure               -> clear, then enable")
    print("       0xFA5918  0xDD   MIDI_PostSendWork                 -> wake the sender")
    print("     The sibling writes the SAME constants to ITS INTES0 (0x%02X): 0x5D in"
          % k["INTES0"])
    print("     SC0Init_EnableRegisters and 0xDD in MIDI_SC0_ENABLE_TX")
    print("     (v10/maincpu/midi/midi_serial_routines.s:987), and names the register.")
    print()
    print("  A SECOND TWIN IN THE SAME SUBSYSTEM -- 'wake the transmitter':")
    print("    WSA1   MIDI_PostSendWork    prom_a 0x%06X" % POST_WSA1[1])
    print("    KN5000 MIDI_SC0_ENABLE_TX   main   0x%06X" % POST_KN[1])
    pa = dis(*POST_WSA1)
    pb = dis(*POST_KN)
    print()
    print("    %-40s | %s" % ("WSA1 prom_a", "KN5000 main CPU"))
    for i in range(max(len(pa), len(pb))):
        la = "0x%06X  %s" % (pa[i][0], pa[i][2]) if i < len(pa) else ""
        lb = "0x%06X  %s" % (pb[i][0], pb[i][2]) if i < len(pb) else ""
        print("    %-40s | %s" % (la, lb))
    print()
    print("    Same seven steps: push SR / ei 0x06 / compare a RAM byte against a")
    print("    sentinel / branch / write INTES0 = 0xDD / pop SR / ret, with the taken")
    print("    branch calling a MIDI-OUT BUFFER INITIALISER and then storing 0 into a")
    print("    RAM byte.  The sentinel differs (0xFF at (0x89) here, 0x55 at (0x0474)")
    print("    there) and so do all the addresses.")
    print("    ★ Both callees are the same ROLE, named independently in the two trees:")
    print("        WSA1    0xFA591D call 0xF41E00 -> prom_b thunk `jp 0xF84854` ->")
    print("                Ring601432_Init   (this tree's own name, from its own")
    print("                conversion of the 0x601432 ring)")
    print("        KN5000  0xFCF9A2 call 0xEF286B -> SeqBuf_MidiOut_Init")
    print("                (symbols/maincpu_v10_symbols_reference.txt:10626)")
    print("    ★ LEAD on prom_a's other stated Unknown -- 'what (0x89) == 0xFF means.")
    print("      It selects the whole second arm, so it is not a detail.'  In the twin")
    print("      the same arm re-initialises the MIDI-out buffer, so (0x89) == 0xFF is")
    print("      the state 'do not enable the transmitter, reset the output buffer")
    print("      instead'.  ⚠ A READING from a structural twin, not a decode: nothing")
    print("      here shows WHO sets (0x89) to 0xFF.")
    print()
    print("  ★ This also retires prom_a's stated 'Unknown: why SC0BUF is written 0xFE at")
    print("    the end.'  Both machines write 0xFE to SC0BUF as the LAST step, straight")
    print("    after enabling INTTX0: it is the priming byte that makes the transmitter")
    print("    raise INTTX0 the first time.  ⚠ That 0xFE was picked because it is MIDI")
    print("    ACTIVE SENSING (a byte a receiver may ignore) is a READING, not a finding.")
    print()


# ---------------------------------------------------------------- RUNS -----
def kn_symbols(path):
    out = []
    for ln in open(path):
        m = re.match(r'^(\S+)\s+([0-9A-Fa-f]{8})\s*$', ln)
        if m:
            out.append((int(m.group(2), 16), m.group(1)))
    out.sort()
    return out


def nearest_symbol(syms, addr):
    lo, hi = 0, len(syms) - 1
    best = None
    while lo <= hi:
        mid = (lo + hi) // 2
        if syms[mid][0] <= addr:
            best = syms[mid]
            lo = mid + 1
        else:
            hi = mid - 1
    return best


def shared_runs():
    """Re-run scripts/analysis/kn5000_shared_runs.py and parse its 'longest' table."""
    p = subprocess.run([sys.executable,
                        os.path.join(ROOT, "scripts", "analysis", "kn5000_shared_runs.py")],
                       capture_output=True, text=True, cwd=ROOT)
    rows, totals = [], {}
    for ln in p.stdout.splitlines():
        m = re.match(r'\s+(prom_[abcd])\s+0x([0-9A-F]+)\s+->\s+payload\s+0x([0-9A-F]+)\s+(\d+) B',
                     ln)
        if m:
            rows.append((m.group(1), int(m.group(2), 16), int(m.group(3), 16), int(m.group(4))))
        m2 = re.match(r'\s+(prom_[abcd])\s+(\d+) runs\s+kept\s+([\d,]+) B', ln)
        if m2:
            totals[m2.group(1)] = (int(m2.group(2)), int(m2.group(3).replace(",", "")))
        m3 = re.match(r'\s+TOTAL kept ([\d,]+) B', ln)
        if m3:
            totals["TOTAL"] = int(m3.group(1).replace(",", ""))
    return rows, totals, p.stdout


def classify_runs(rows, syms):
    """(data runs, code runs) by the sibling's own symbol naming."""
    data, code = [], []
    for img, wa, poff, n in rows:
        ka = payload_addr(poff)
        sym = nearest_symbol(syms, ka)
        name = sym[1] if sym else "(none)"
        (data if any(w in name for w in DATA_WORDS) else code).append(
            (img, wa, ka, n, name))
    return data, code


def section_runs():
    syms = kn_symbols(KN_SUBSYMS)
    rows, totals, _raw = shared_runs()
    print("=" * 78)
    print("D. WHAT THE BYTE-IDENTICAL RUNS ARE")
    print("=" * 78)
    for img in ("prom_a", "prom_b", "prom_c", "prom_d"):
        if img in totals:
            print("  %-8s %5d runs, %7d B kept" % (img, totals[img][0], totals[img][1]))
    print("  TOTAL kept %d B (shuffle null 0 -- see that script)" % totals.get("TOTAL", -1))
    print()
    print("  The longest surviving runs, each labelled with the KN5000 symbol it starts")
    print("  in (nearest preceding entry of symbols/subcpu_symbols_reference.txt):")
    print()
    print("  %-8s %-10s %-10s %6s  %s" % ("image", "wsa1", "kn5000 addr", "bytes", "kn5000 symbol"))
    for img, wa, poff, n in rows:
        ka = payload_addr(poff)
        s = nearest_symbol(syms, ka)
        tag = "%s +0x%X" % (s[1], ka - s[0]) if s else "(no symbol below)"
        print("  %-8s 0x%06X  0x%06X   %6d  %s" % (img, wa, ka, n, tag))
    print()
    data, code = classify_runs(rows, syms)
    print("  By the SIBLING'S OWN symbol names, %d of these %d longest runs start inside"
          % (len(data), len(rows)))
    print("  an object it calls a table, curve, bytecode, record array, bitmap or pool.")
    print("  The exception%s:" % ("" if len(code) == 1 else "s"))
    for img, wa, ka, n, name in code:
        print("      %-8s 0x%06X  %6d B  %s" % (img, wa, n, name))
    print()
    print("  Int_SignedDiv is the compiler's signed-division runtime -- SFR-free by")
    print("  nature -- and this tree already imported it, with the divergence point")
    print("  re-derived: notes/prom_a_div_runtime_check.py, prom_a/wsa1_prom_a.s:125629.")
    print()
    print("  So no link, serial, port or timer DRIVER is in the shared mass at all --")
    print("  which is what section A predicts, since a driver names an SFR and 67 of the")
    print("  68 shared SFR names sit at different addresses on the two parts.")
    print()


# ---------------------------------------------------------------- DIFF -----
def parse_site(s):
    """'wsa1:a:0xF8E47F' -> ('wsa1:a', 0xF8E47F)"""
    i = s.rindex(":")
    return s[:i], int(s[i + 1:], 0)


def routine_diff(sa, sb, n, quiet=False):
    na, aa = parse_site(sa)
    nb, ab = parse_site(sb)
    A = dis(na, aa, n)
    B = dis(nb, ab, n)
    k = min(len(A), len(B))
    same = diffop = diffmn = 0
    rows = []
    for i in range(k):
        ta, tb = A[i][2], B[i][2]
        ma = ta.split()[0] if ta else ""
        mb = tb.split()[0] if tb else ""
        if ta == tb:
            same += 1
        elif ma == mb:
            diffop += 1
            rows.append(("OPERAND", A[i][0], ta, B[i][0], tb))
        else:
            diffmn += 1
            rows.append(("MNEMONIC", A[i][0], ta, B[i][0], tb))
    print("  %s 0x%06X  vs  %s 0x%06X   over %d bytes" % (na, aa, nb, ab, n))
    print("    instruction slots compared: %d  (%s decoded %d, %s decoded %d)"
          % (k, na, len(A), nb, len(B)))
    print("    identical text:                   %d" % same)
    print("    same mnemonic, different operand: %d" % diffop)
    print("    DIFFERENT MNEMONIC:               %d   <- structural difference" % diffmn)
    if not quiet:
        for kind, a1, t1, b1, t2 in rows:
            print("      %-8s  0x%06X %-32s | 0x%06X %s" % (kind, a1, t1, b1, t2))
    return same, diffop, diffmn, len(A), len(B)


def routine_diff_quiet(sa, sb, n):
    """(identical, operand-only, structural, lenA, lenB) with no printing."""
    import io
    import contextlib
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        return routine_diff(sa, sb, n, quiet=True)


def byte_diff(sa, sb, n):
    na, aa = parse_site(sa)
    nb, ab = parse_site(sb)
    x = fetch(na, aa, n)
    y = fetch(nb, ab, n)
    d = [i for i in range(n) if x[i] != y[i]]
    return d, x, y


# ------------------------------------------------------------- SELFTEST ----
def selftest():
    checks = []

    def ck(name, cond, detail=""):
        checks.append((name, bool(cond), detail))

    # ---- A: the SFR maps
    w, k, both, same, diff = sfr_compare()
    ck("S01 WSA1 SFR include parses (>=100 registers)", len(w) >= 100, "%d" % len(w))
    ck("S02 KN5000 SFR include parses (>=180 registers)", len(k) >= 180, "%d" % len(k))
    ck("S03 68 register names in both maps", len(both) == 68, "%d" % len(both))
    ck("S04 exactly ONE lands at the same address", len(same) == 1, str(same))
    ck("S05 that one is PBFC at 0x2F",
       same == ["PBFC"] and w["PBFC"] == 0x2F == k["PBFC"], str(same))
    ck("S06 CAP4L/CAP4H are the SAME NAME at different addresses",
       w["CAP4L"] == 0x46 and k["CAP4L"] == 0x94 and w["CAP4H"] == 0x47 and k["CAP4H"] == 0x95)
    ck("S07 four INTETxx pairs are transposed spellings of one register",
       all(a in w and b in k and a not in k and b not in w for a, b in TRANSPOSED))
    ck("S08 block-CS is 1 byte / 4 areas here, 2 bytes / 6 areas there",
       ("B0CS" in w and "B0CSL" in k and "B5CSH" in k and "B4CSL" in k
        and "B4CSL" not in w and k["B0CSH"] - k["B0CSL"] == 1))
    ck("S09 MSAR/MAMR order is REVERSED between the parts",
       w["MSAR0"] < w["MAMR0"] and k["MAMR0"] < k["MSAR0"],
       "95C061 MSAR0=0x%02X MAMR0=0x%02X ; 94C241 MAMR0=0x%03X MSAR0=0x%03X"
       % (w["MSAR0"], w["MAMR0"], k["MAMR0"], k["MSAR0"]))

    # ---- B: the link.  Tested on the FIRST and the LAST of the four sites.
    facts = {}
    for label, img, addr, n, _p, _d in LINK_SITES:
        facts[label] = link_facts(img, addr, n)
    first = LINK_SITES[0][0]
    last = LINK_SITES[-1][0]
    ck("S10 all four link handlers guard on bit 2 of a port",
       all(f["guard_bit2"] for f in facts.values()),
       "; ".join("%s=%s" % (l.split()[0] + l.split()[-1],
                            [hex(x) for x in f["guard_bit2"]])
                 for l, f in facts.items()))
    ck("S11 all four acknowledge by clearing bit 1 of the SAME port",
       all(f["ack_res_bit1"] and set(f["ack_res_bit1"]) == set(f["guard_bit2"])
           for f in facts.values()))
    ck("S12 all four dispatch with 0xE1 as the base of the command space",
       all(f["base_E1"] for f in facts.values()),
       "; ".join("%s" % f["dispatch"] for f in facts.values()))
    ck("S12b three use a compare chain, prom_c a sub-0xE1 jump table",
       sum(1 for f in facts.values() if f["cmp_E1"]) == 3
       and sum(1 for f in facts.values() if f["sub_E1"]) == 1)
    ck("S12c all four give selector 2 a 6-byte payload and selector 3 a 10-byte one",
       all((2, 6) in f["arms"] and (3, 10) in f["arms"] for f in facts.values()),
       "; ".join(str(f["arms"]) for f in facts.values()))
    ck("S13 all four compute (b & 0x1F) + 1 for the default arm",
       all(f["mask_1f"] and f["inc_1"] for f in facts.values()))
    ck("S14 all four write the DMA start vector 0x0A",
       all(f["dma_vector_0A"] for f in facts.values()),
       "; ".join("%s->%s" % (lbl, [hex(x) for x in f["dma_vector_0A"]])
                 for lbl, f in facts.items()))
    ck("S15 FIRST site (%s) writes 0x0A to DMA0V=0x100" % first,
       facts[first]["dma_vector_0A"] == [0x100])
    ck("S16 LAST site (%s) writes 0x0A to DMA3V=0x7F" % last,
       facts[last]["dma_vector_0A"] == [0x7F])

    hb = {lbl: handshake_bits(img, a, n, port)
          for lbl, img, a, n, port, _pn in HANDSHAKE_SITES}
    ck("S14b both WSA1 transmit routines use bit 0 as an output strobe (res AND set)",
       all({"res", "set"} <= h.get(0, set()) for h in hb.values()),
       str({k: {b: sorted(v) for b, v in h.items()} for k, h in hb.items()}))
    ck("S14c both WSA1 transmit routines TEST bit 3 and never write it",
       all(h.get(3) == {"bit"} for h in hb.values()))
    ck("S14d neither transmit routine touches any other bit of that port",
       all(set(h) == {0, 3} for h in hb.values()))

    tbl = promc_command_table()
    ck("S16b prom_c's jump table resolves 7 arms, all inside 0xF99C00-0xF99D00",
       len(tbl) == 7 and all(0xF99C00 <= a < 0xF99D00 for _c, a, _s, _n in tbl),
       str([(hex(c), hex(a)) for c, a, _s, _n in tbl]))
    ck("S16c prom_c command 0xE1 -> selector 2 / 6 bytes and 0xE2 -> selector 3 / 10",
       (0xE1, 2, 6) in [(c, s_, n_) for c, _a, s_, n_ in tbl]
       and (0xE2, 3, 10) in [(c, s_, n_) for c, _a, s_, n_ in tbl],
       str([(hex(c), s_, n_) for c, _a, s_, n_ in tbl]))
    ck("S16d prom_c's LAST table entry (0xE7) is a distinct arm with selector 8",
       tbl[-1][0] == 0xE7 and tbl[-1][2] == 8, str(tbl[-1]))

    # ---- the payload base, derived rather than quoted
    frag = fetch("wsa1:c", 0xF98099, 81)
    pay = open(PAYLOAD, "rb").read()
    hits = [(sum(1 for a, b in zip(frag, pay[i:i + 81]) if a != b), i)
            for i in range(len(pay) - 81)]
    d_best, off_best = min(hits)
    ck("S17 payload base derived: the 81-byte DSP writer is 1 byte from a payload copy",
       d_best == 1, "diff=%d at file 0x%05X" % (d_best, off_best))
    ck("S18 ... and that copy sits at the symbol table's 0x0001FD27",
       payload_addr(off_best) == 0x0001FD27, "0x%06X" % payload_addr(off_best))
    ck("S19 the one differing byte is the peripheral base (0xE0 here, 0x13 there)",
       [i for i in range(81) if frag[i] != pay[off_best + i]] == [0x0F]
       and frag[0x0F] == 0xE0 and pay[off_best + 0x0F] == 0x13)

    # ---- C: serial
    a = dis(*SER_WSA1)
    b = dis(*SER_KN)
    ta = [t for _x, _y, t in a]
    tb = [t for _x, _y, t in b]
    ck("S20 both UART-configure routines open with ei 0x06 and close with ret",
       ta[0] == "ei 0x06" and tb[0] == "ei 0x06" and ta[-1] == "ret" and tb[-1] == "ret",
       "%s..%s | %s..%s" % (ta[0], ta[-1], tb[0], tb[-1]))
    ck("S21 both write SC0MOD=0x29, SC0CR=0x00, INTES0=0x5D, SC0BUF=0xFE",
       ("ld (0x52),0x29" in ta and "ld (0x51),0x00" in ta
        and "ld (0x77),0x5d" in ta and "ld (0x50),0xfe" in ta
        and "ld (0x00d2),0x29" in tb and "ld (0x00d1),0x00" in tb
        and "ld (0x00ea),0x5d" in tb and "ld (0x00d0),0xfe" in tb))
    ck("S22 INTES0 is 0x77 in THIS tree's own SFR include",
       w["INTES0"] == 0x77 and k["INTES0"] == 0xEA)
    # the INTES0 decode, computed rather than asserted
    fields = {v: ((v >> 4) & 7, (v >> 7) & 1, v & 7, (v >> 3) & 1)
              for v, _d, _m in INTES0_VALUES}
    ck("S22b INTES0 field arithmetic: TX level 7/5/5 and RX level 5 for FD/DD/5D",
       fields[0xFD][0] == 7 and fields[0xDD][0] == 5 and fields[0x5D][0] == 5
       and all(f[2] == 5 for f in fields.values()),
       str({hex(k): v for k, v in fields.items()}))
    ck("S22c only 0x5D writes bit 7 = 0, i.e. only it CLEARS the INTTX0 request flag",
       fields[0x5D][1] == 0 and fields[0xFD][1] == 1 and fields[0xDD][1] == 1)
    ck("S22d MAME really scans levels 1..6 only (the line the decode rests on)",
       "for ( int i = std::max( 1, ( ( m_sr.b.h & 0x70 ) >> 4 ) ); i < 7; i++ )"
       in open("/home/fsanches/compartilhado/mame/src/devices/cpu/tlcs900/"
               "tmp95c061.cpp", errors="replace").read())

    src = open(image_path(ROOT, "prom_a/wsa1_prom_a.s")).read()
    sites = re.findall(r'ldio 0x77, 0x([0-9a-f]{2})', src)
    ck("S23 prom_a has exactly five ldio-to-0x77 sites, values {5d,dd,fd}",
       len(sites) == 5 and set(sites) == {"5d", "dd", "fd"},
       "%d sites %s" % (len(sites), sorted(set(sites))))
    ck("S24 the 'mailbox' wording is still in the tree, i.e. this correction is unapplied",
       "mailbox" in open(os.path.join(ROOT, "notes",
                                      "FINDINGS-midi-port.md")).read())

    pa = [t for _x, _y, t in dis(*POST_WSA1)]
    pb = [t for _x, _y, t in dis(*POST_KN)]
    ck("S24b both 'wake the transmitter' twins are push SR / ei 0x06 ... pop SR / ret",
       pa[0] == pb[0] == "push SR" and pa[1] == pb[1] == "ei 0x06"
       and pa[-2] == pb[-2] == "pop SR" and pa[-1] == pb[-1] == "ret",
       "%s|%s" % (pa[:2] + pa[-2:], pb[:2] + pb[-2:]))
    ck("S24c both write 0xDD to their own INTES0 on the not-taken arm",
       "ld (0x77),0xdd" in pa and "ld (0x00ea),0xdd" in pb)
    ck("S24d both compare a RAM byte against a sentinel, and the sentinels differ",
       any(re.match(r'cp \(0x0*89\),0xff$', t) for t in pa)
       and any(re.match(r'cp \(0x0474\),0x55$', t) for t in pb),
       "%s | %s" % ([t for t in pa if t.startswith("cp ")],
                    [t for t in pb if t.startswith("cp ")]))
    ck("S24e the WSA1 second arm's thunk 0xF41E00 really is `jp 0xF84854`",
       fetch("wsa1:b", 0xF41E00, 4) == bytes([0x1B, 0x54, 0x48, 0xF8]),
       fetch("wsa1:b", 0xF41E00, 4).hex(" "))

    # ---- D: runs, tested on the LAST row as well as the first
    syms = kn_symbols(KN_SUBSYMS)
    ck("S25 KN5000 sub-CPU symbol table parses (>=4000 symbols)", len(syms) >= 4000,
       "%d" % len(syms))
    rows, totals, _ = shared_runs()
    ck("S26 shared-run total is 32,795 B as the existing script reports",
       totals.get("TOTAL") == 32795, str(totals.get("TOTAL")))
    ck("S27 FIRST longest run resolves to a KN5000 symbol",
       nearest_symbol(syms, payload_addr(rows[0][2])) is not None,
       "%s" % (nearest_symbol(syms, payload_addr(rows[0][2])),))
    ck("S28 LAST longest run resolves to a KN5000 symbol",
       nearest_symbol(syms, payload_addr(rows[-1][2])) is not None,
       "%s" % (nearest_symbol(syms, payload_addr(rows[-1][2])),))

    data, code = classify_runs(rows, syms)
    ck("S28b all but one of the longest shared runs land in a sibling DATA object",
       len(code) == 1, "%d data, %d code: %s" % (len(data), len(code),
                                                 [c[4] for c in code]))
    ck("S28c the one code run is Int_SignedDiv, the compiler divide runtime",
       code and code[0][4] == "Int_SignedDiv" and code[0][1] == 0xFE68F3,
       str(code))

    # ---- E: the method question, tested on the first and the last pair
    r_first = routine_diff_quiet(*METHOD_PAIRS[0][1:])
    r_last = routine_diff_quiet(*METHOD_PAIRS[-1][1:])
    ck("S29 FIRST method pair (one build): 35 of 36 slots identical, 1 operand, 0 structural",
       r_first[:3] == (35, 1, 0), str(r_first))
    ck("S30 LAST method pair (two builds): positional alignment scores <=1 identical",
       r_last[0] <= 1, str(r_last))
    ck("S31 the middle pair scores ZERO identical slots although it is one protocol",
       routine_diff_quiet(*METHOD_PAIRS[1][1:])[0] == 0)

    for rel, needle, ok in check_sib_cites():
        ck("S32 sibling citation live: %s" % rel, ok, needle)

    bad = [c for c in checks if not c[1]]
    for name, ok, detail in checks:
        print("  %-4s %s%s" % ("PASS" if ok else "FAIL", name,
                               ("   [%s]" % detail) if detail else ""))
    print("\n  %d checks, %d failed" % (len(checks), len(bad)))
    return 1 if bad else 0


# Pairs used by --method: (label, site A, site B, bytes, what to expect).
METHOD_PAIRS = [
    ("DSP channel-register writer (ONE build, two peripheral bases)",
     "wsa1:c:0xF98099", "kn5000:payload:0x01FD27", 81),
    ("INT0 link receive handler (two builds, one protocol)",
     "wsa1:a:0xF8E47F", "kn5000:subboot:0xFF881F", 0x7B),
    ("SC0 UART configure (two builds, one routine)",
     "wsa1:a:0xFA58F0", "kn5000:main:0xFCF940", 0x1F),
]


def section_method():
    print("=" * 78)
    print("E. DOES notes/prom_c_prom_a_routine_diff.py's METHOD TRANSFER ACROSS TREES?")
    print("=" * 78)
    print("  That tool aligns two routines POSITIONALLY -- slot i against slot i -- and")
    print("  reports 'same mnemonic, different operand' as the signature of one routine")
    print("  built for two peripheral bases.  Within this tree (prom_a vs prom_c, one")
    print("  build) it works.  Across the two trees it does NOT, and the numbers say")
    print("  exactly where it stops working:")
    print()
    for label, a, b, n in METHOD_PAIRS:
        print("  %s" % label)
        routine_diff(a, b, n, quiet=True)
        print()
    print("  Reading: positional alignment survives only when the two images came from")
    print("  ONE build with a substituted constant (the DSP writer: 35 of 36 slots")
    print("  identical, the one difference the peripheral base).  The link handler and")
    print("  the UART routine are the SAME PROTOCOL and the SAME ROUTINE, and the method")
    print("  scores them 0/40 and 1/8 identical -- because the two builds differ in how")
    print("  many registers the prologue saves, in whether the micro-DMA setup is inlined")
    print("  or reached through a stack-argument helper, and in register allocation.")
    print()
    print("  ★ So the cross-tree instrument is NOT this diff.  It is a comparison of the")
    print("    CONSTANTS and the ORDER OF OPERATIONS -- which is what section B does and")
    print("    what --selftest S10..S16 assert.  Quoting a low 'identical text' count as")
    print("    evidence that two routines are unrelated would be wrong in two of the three")
    print("    pairs above, and this section exists so that nobody does it.")
    print()
    print("  ⚠ Also note where the differing byte of the DSP writer is: the INSTRUCTION")
    print("    is at 0xF980A5 (`ld XIY,0x00E00000`), the differing BYTE is at 0xF980A8,")
    print("    inside its literal.  prom_c's header correctly says 'byte'; anyone")
    print("    re-quoting 0xF980A8 as a call/instruction site would be repeating round")
    print("    1's off-by-N citation bug.")
    print()


# ------------------------------------------------------------- OFF-CHIP ----
# Claims about the SIBLING tree are pinned to a string that must be present in a
# named sibling file, so a stale citation fails loudly instead of ageing quietly.
SIB_CITES = [
    ("v142/subcpu/subcpu_data_tables.s", "IC311 (NEC uPD6383GF"),
    ("analysis/tonegen-register-interface/FINDINGS-tg-register-interface.md",
     "IC303 (TC183C230002)"),
    ("v10/maincpu/fdc_constants.s", "likely uPD765 or equivalent"),
    ("docs/subcpu_boot_protocol.md", "Main\u2192Sub | 0x140000 (write) | 0x120000 (read) | IC22"),
    ("v10/maincpu/midi/midi_serial_routines.s", "0x00 = MIDI"),
]


def check_sib_cites():
    out = []
    for rel, needle in SIB_CITES:
        path = os.path.join(SIB, rel)
        ok = os.path.exists(path) and needle in open(path, errors="replace").read()
        out.append((rel, needle, ok))
    return out


def section_chips():
    print("=" * 78)
    print("F. OFF-CPU DEVICES -- who has the better note, and which way the debt runs")
    print("=" * 78)
    print("  inter-processor latch")
    print("    WSA1    0x7C0000 on CPU 1 / 0x100000 on CPU 2, handshake P7 / PA")
    print("    KN5000  0x140000 on main / 0x120000 on sub, handshake Port Z / Port D,")
    print("            latches IC22 (main->sub) and IC23 (sub->main)")
    print("    -> THIS tree has the fuller PROTOCOL note (command decode, the three")
    print("       error counters, the stall watchdog).  The SIBLING has the SIGNAL")
    print("       NAMES and the two latch part designators, which this tree lacks.")
    print()
    print("  floppy controller")
    print("    WSA1    0x7B0004/0x7B0005 + 0x7A0000; uPD765-family IDENTIFIED by a")
    print("            32-value opcode truth table checked against MAME's")
    print("            upd765_family_device::check_command (notes/FINDINGS-prom_a-fdc.md,")
    print("            notes/prom_a_fdc_checks.py, 138 checks)")
    print("    KN5000  0x110000; its own fdc_constants.s says only 'likely uPD765 or")
    print("            equivalent', and docs/fdc_disassembly.md is still marked TODO")
    print("    -> DEBT RUNS WSA1 -> KN5000.  The identification METHOD transfers whole:")
    print("       find that tree's opcode validator and run the same 32-value table.")
    print("       Its own doc already writes 'SEEK (0x0F)', which is the uPD765 opcode.")
    print()
    print("  the four-channel register file this tree calls Dev/'DSP'")
    print("    WSA1    0x00E00000, address at +0, data at +2, 4 channels x 32 registers")
    print("    KN5000  0x00130000 -- and the sibling NAMES THE PART: 'IC311 (NEC")
    print("            uPD6383GF, primary' (v142/subcpu/subcpu_data_tables.s), with a")
    print("            second DSP IC310 (MN19413) beside it")
    print("    -> DEBT RUNS KN5000 -> WSA1, but the import is NOT automatic.  What is")
    print("       byte-proven is that 35 of 36 instruction slots of the channel-register")
    print("       writer are identical and the one difference is the base literal")
    print("       (--diff wsa1:c:0xF98099 kn5000:payload:0x01FD27 81).  Identical DRIVER")
    print("       code is consistent with the same part AND with the same driver reused")
    print("       for a compatible successor.  prom_c's header already refuses to name")
    print("       the device on this evidence and that refusal still stands; what is new")
    print("       here is the part number of the device the twin code drives, which is")
    print("       the right lead for notes/WSA1-EMULATION-DISASM-GAPS.md gap A.")
    print()
    print("  tone generator -- NOT the same interface, do not cross-import")
    print("    WSA1    Dev10C 0x0010C000 and Dev104 0x00104000: a FLAT per-channel")
    print("            register file, 64 channels, addressed as channel + offset")
    print("    KN5000  IC303 (TC183C230002) at 0x100000 / 0x100002: an ADDRESS LATCH")
    print("            plus a DATA port, one 16-bit word at a time")
    print("    -> different shapes.  A name borrowed here would be a wrong name.")
    print()
    print("  MIDI UART: both machines use serial channel 0, and section C shows the")
    print("  configure routine is one routine.  The KN5000 adds a COM_SELECT switch")
    print("  (MIDI / MAC / PC1 / PC2) that drives BR0CR from RAM; the WSA1 hard-codes")
    print("  BR0CR = 0x0E and keeps a second, unreachable 0x0C arm.")
    print()
    print("  citation check (each sibling claim above is pinned to a live string):")
    for rel, needle, ok in check_sib_cites():
        print("    %-4s %s :: %s" % ("OK" if ok else "STALE", rel, needle))
    print()


def main():
    av = sys.argv[1:]
    if "--selftest" in av:
        return selftest()
    if "--diff" in av:
        i = av.index("--diff")
        routine_diff(av[i + 1], av[i + 2], int(av[i + 3], 0), "--quiet" in av)
        return 0
    want = [a for a in av if a in ("--sfr", "--link", "--serial", "--runs",
                                   "--method", "--chips")]
    if not want:
        want = ["--sfr", "--link", "--serial", "--runs", "--method", "--chips"]
    if "--sfr" in want:
        section_sfr(verbose="--sfr" in av)
    if "--link" in want:
        section_link()
    if "--serial" in want:
        section_serial()
    if "--runs" in want:
        section_runs()
    if "--method" in want:
        section_method()
    if "--chips" in want:
        section_chips()
    return 0


if __name__ == "__main__":
    sys.exit(main())
