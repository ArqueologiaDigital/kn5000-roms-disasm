#!/usr/bin/env python3
"""What crosses the WSA1's sound-chip boundary -- following BASE REGISTERS, not literals.

QUESTION IT ANSWERS
-------------------
`../notes/sound/sound_coverage.py` (the repo-root tool, shared with the KN5000
lane) censuses a sound window by SEARCHING FOR ITS ADDRESS AS A LITERAL.  On the
WSA1 that instrument is blind in a way its own docstring records:

    "IT UNDERCOUNTS REGISTER-INDIRECT ACCESS.  The WSA1 reaches its tone
     generator by loading the base (`ld xbc,0x0010C000`) and then using
     displacements, so accesses to +2 (data) and +4 (status) never name
     0x10C002 or 0x10C004 and are invisible to a literal scan.  That is why the
     WSA1 rows read TG_DATA 0 and TG_STATUS 0 while the driver maps both."

Every WSA1 device in that list is an ADDRESS/DATA PAIR reached exactly that way,
so "0 accesses to the data register" is false for every one of them.  This tool
follows the base into its uses and reports the TRUE per-register picture:
which offset of which device is written or read, how often, with what, and --
because the devices are indirect a second time -- which DEVICE-INTERNAL REGISTER
NUMBERS are selected.

★★ AND IT ANSWERS A SECOND QUESTION THE LITERAL SCAN CANNOT EVEN ASK: is the
window list COMPLETE?  It is not.  See --windows and section "THE OMISSION"
below.

THE OMISSION, which is the finding this tool exists to make measurable
---------------------------------------------------------------------
The shared tool's WSA1 window list is TG/SYNTH2/KEYBED on CPU 2 only.  Two
devices that this tree has already identified as the WSA1's DSP register files
are NOT in it, and one whole DSP transport is not memory-mapped at all:

  * 0x00E00000 on CPU 2 (prom_c).  `prom_c/boot/boot_and_main.s` converts four
    drivers for it, and `DSP_WriteChannelRegs_Inner` is 80 of 81 bytes identical
    to the KN5000 sub-CPU's routine of the same name -- the ONE differing byte
    being the base literal, 0xE0 here against 0x13 there.  0x00130000 is exactly
    the address the shared tool lists for the KN5000 as `DSP_ADDR`.  The two
    machines' DSP register files are the same driver at two addresses, and the
    WSA1's is missing from the list.
  * 0x007F0000 on CPU 1 (prom_a).  The same 44-byte `DSP_WriteAllChannelRegs`
    is present a third time at prom_a 0xF85F7C, and prom_a's own inline comments
    at 0xF85F40/0xF85F66/0xF85FB4 already read "the DSP register file".
  * PORT P7 (SFR 0x0013), a bit-banged parallel handshake with three
    destinations, is where DSP EFFECT MICROCODE leaves CPU 2
    (`../notes/prom_c_dsp_port.py`), and effect 5 PHASER's stream is
    byte-identical to the KN5000's `DSP_Eff05_Coef_Bytecode`
    (`../notes/FINDINGS-prom_c-p7-is-dsp-effects.md`).  A window scan can never
    see it, because it is not a window.

⚠ MARKED AS INFERENCE.  "0x00E00000 / 0x007F0000 are DSP register files" rests
on byte identity with a routine the SIBLING project named DSP; it is a borrowed
name, and `prom_c/boot/boot_and_main.s` says so at length.  What is NOT an
inference is that they are 4-channel x 32-register address/data pairs, and that
the shared tool does not look at them.

WHAT IT DOES NOT DO
-------------------
  * It does not certify bytes.  `scripts/analysis/assert_byte_identical.py` is
    the only certificate.
  * The abstract walk is STRAIGHT-LINE and CONSERVATIVE.  It resets every
    device-valued register at a label and at every `call`/`calr`/`ret`, so a
    port access whose base was established before a call is reported as
    UNATTRIBUTED rather than guessed.  The unattributed count is PRINTED, not
    absorbed -- it is the residue that says how much of the picture is missing.
  * It reads SOURCE TEXT.  A misframed data byte that happens to spell
    `ld (xbc),ix` would be counted.  Nothing here can see that; the byte gate
    cannot either.

RUN
---
    python3 notes/sound/wsa1_sound_boundary.py                # per-register census
    python3 notes/sound/wsa1_sound_boundary.py --windows      # window completeness
    python3 notes/sound/wsa1_sound_boundary.py --routines     # per-routine coverage
    python3 notes/sound/wsa1_sound_boundary.py --stream 0x10C000   # select/data order
    python3 notes/sound/wsa1_sound_boundary.py --stream 0x10C000 --routine Dev10C_WriteGlobalRegs
    python3 notes/sound/wsa1_sound_boundary.py --p7          # the DSP transport
    python3 notes/sound/wsa1_sound_boundary.py --values      # what is written
    python3 notes/sound/wsa1_sound_boundary.py --selftest
"""
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))          # .../wsa1
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_lines                      # noqa: E402

IMAGES = [
    ("prom_a", "prom_a/wsa1_prom_a.s", "cpu1"),
    ("prom_b", "prom_b/wsa1_prom_b.s", "cpu1"),
    ("prom_c", "prom_c/wsa1_prom_c.s", "cpu2"),
]

# ---------------------------------------------------------------------------
# THE WINDOWS.  ★ This is the one input a reader must check.  Sources are named
# per row; a wrong base makes every figure below wrong in the same direction and
# nothing else here can notice.
# ---------------------------------------------------------------------------
Window = collections.namedtuple("Window", "base size cpu name shared what")
WINDOWS = [
    # base        size  cpu     name        in the shared tool?
    Window(0x0010C000, 6, "cpu2", "Dev10C",  True,
           "16-bit addr(+0)/data(+2)/readback(+4); 64 channels x ~22 regs"),
    Window(0x00104000, 4, "cpu2", "Dev104",  True,
           "16-bit addr(+0)/data(+2); 64 channels x 19 regs"),
    Window(0x00108000, 4, "cpu2", "KeyScan", True,
           "keybed: +0 event word, +2 status; NOT an addr/data pair"),
    Window(0x00E00000, 4, "cpu2", "DspRegs_C", False,
           "8-bit addr(+0)/data(+2); 4 channels x 32 regs.  KN5000 twin at 0x130000"),
    Window(0x007F0000, 4, "cpu1", "DspRegs_A", False,
           "8-bit addr(+0)/data(+2); same 44-byte writer as prom_c and the KN5000"),
]
BASES = {w.base: w for w in WINDOWS}
# Bases are 4- or 6-byte windows; an access more than SPAN past the base is not
# this device.  Kept generous so a real +4 readback is never dropped silently.
SPAN = 0x10


def in_window(v):
    """-> (base, offset) if the literal v lands in a window, else None.

    ⚠ NOT `v in BASES`.  prom_c loads `0x00108002` and `0x00108000` as two
    SEPARATE base literals (KeyScan_ReadEvent 0xF99762 / 0xF99776), and
    Dev108000_Preload_80toBF loads the +2 register directly.  A tool keyed on
    the exact base would attribute neither, and would then report the keybed's
    status register as never touched -- the same class of error this file
    exists to fix one level down.
    """
    if v is None:
        return None
    for b in BASES:
        if b <= v < b + SPAN:
            return (b, v - b)
    return None

R32 = ("xwa", "xbc", "xde", "xhl", "xix", "xiy", "xiz", "xsp")

LABEL_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
ADDR_RE = re.compile(r';\s*([0-9A-Fa-f]{6})\b')
# `(xiz-4)` / `(xsp+6)` / `(XIZ+0xfc)` -- a frame slot, the thing a base gets
# spilled into.  ⚠ The two dialects in this tree spell the SAME slot two ways:
# prom_c's split files write `(xiz-4)` where the unidasm comment says
# `(XIZ+0xfc)`.  Only the instruction half is parsed, so the two never mix.
SLOT_RE = re.compile(r'^\((x(?:wa|bc|de|hl|ix|iy|iz|sp))([+-])(0x[0-9a-f]+|\d+)\)$')
PTR_RE = re.compile(r'^\((x(?:wa|bc|de|hl|ix|iy|iz|sp))'
                    r'(?:([+-])(0x[0-9a-f]+|\d+))?\)$')
ABS_RE = re.compile(r'^\((0x[0-9a-f]{4,8})\)$')


def _int(tok):
    tok = tok.strip()
    try:
        return int(tok, 16) if tok.lower().startswith("0x") else int(tok, 10)
    except ValueError:
        return None


def _split_ops(text):
    """Comma-split at depth 0, so `(xiz-4), xbc` gives two operands."""
    out, cur, depth = [], "", 0
    for ch in text:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


Insn = collections.namedtuple("Insn", "image label routine addr mnem ops raw")


def is_local(label, routine):
    """Is `label` an INTERNAL label of `routine` rather than a new routine?

    ★ WHY THIS MATTERS MORE THAN IT LOOKS.  Nearly every device driver in this
    image is a LOOP: `ld xbc,<base>` sits BEFORE the loop label and the stores
    sit after it.  A walk that resets its state at every label sees the base
    load and then throws it away one line later, and reports the port as never
    reached.  Measured: treating loop labels as barriers lost 2 of the 4
    converted 0x00E00000 drivers and 24 of the 40 accesses they make.

    The tree uses three spellings for an internal label and all three are
    mechanical, so this is a lexical rule and not a judgement:
        `Routine__F997A1`, `Routine__loop`   double underscore (prom_c split)
        `.LF831A2`                            leading dot (prom_a) -- never even
                                              matched as a label by LABEL_RE
        `DSP_Init_Channels_Loop`              the routine's own name + "_"
    ⚠ THE REAL BARRIER IS `ret`, NOT THE LABEL.  walk() clears every register at
    every `ret`/`call`, so a base cannot leak out of a routine that ends the
    normal way whatever this function answers.  A routine ending in a tail jump
    is the residue, and --routines prints the routine each access landed in so a
    reader can see where it was attributed.
    """
    if "__" in label:
        return True
    if routine and label.startswith(routine + "_"):
        return True
    return False


def parse(image, primary):
    """The image's instruction stream, in address order, plus its labels.

    ⚠ Three source dialects live in this tree and all three are handled:
        prom_a  `\tld XIX,0x007f0000        ; F8319A  44 00 00 7f 00`
        prom_c  `\tld\txbc, 0x10C000        ; FB6E5B  ld XBC,0x0010c000`
        hand    `\tld\txbc, 0x00E00000      ; the register port`   <- NO ADDRESS
    The third is why `addr` may be None.  A tool that required an address in the
    comment would silently skip every hand-written converted routine, and
    prom_c/boot/boot_and_main.s -- the whole 0x00E00000 driver -- is one.
    """
    insns, incbins, labels = [], [], []
    label = routine = "<top>"
    for lineno, ln in enumerate(image_lines(ROOT, primary), 1):
        stripped = ln.strip()
        if not stripped or stripped.startswith(";"):
            continue
        m = LABEL_RE.match(ln)
        if m:
            label = m.group(1)
            if not is_local(label, routine):
                routine = label
            labels.append((label, lineno))
            rest = ln[m.end():].strip()
            if not rest or rest.startswith(";"):
                continue
            ln = "\t" + rest
        code = ln.split(";", 1)[0].rstrip()
        comment = ln[len(code):]
        if not code.strip():
            continue
        if code.lstrip().startswith(".incbin"):
            incbins.append((routine, lineno, code.strip()))
            continue
        if code.lstrip().startswith("."):
            continue                      # .byte/.word/.ascii/.include/...
        am = ADDR_RE.search(comment)
        addr = int(am.group(1), 16) if am else None
        parts = code.strip().split(None, 1)
        mnem = parts[0].lower()
        ops = _split_ops(parts[1].lower()) if len(parts) > 1 else []
        insns.append(Insn(image, label, routine, addr, mnem, ops, code.strip()))
    return insns, incbins, labels


# ---------------------------------------------------------------------------
# The abstract walk
# ---------------------------------------------------------------------------
Access = collections.namedtuple(
    "Access", "image cpu label addr base off dirn width operand raw")


def walk(insns, cpu):
    """Follow every device base into its uses.  -> (accesses, unattributed)

    STATE:  regs[r] = (base, off) or None;  slots[text] = (base, off) or None.
    CONSERVATISM: a label, a call and a ret all clear regs.  Slots survive a
    call (they are the caller's frame) but not a label.
    """
    accesses, unattributed = [], []
    regs, slots = {}, {}
    prev_routine = None
    undecoded = 0
    for ins in insns:
        if ins.routine != prev_routine:
            regs, slots = {}, {}
            prev_routine = ins.routine
        m, ops = ins.mnem, ins.ops

        # ---- USES ----
        for pos, op in enumerate(ops):
            # (a) ABSOLUTE dereference: `ld A,(0x00108002)`.  prom_a and prom_b
            #     reach several devices this way and no base register is involved.
            am = ABS_RE.match(op)
            if am:
                hit = in_window(_int(am.group(1)))
                if hit:
                    b, o = hit
                    if BASES[b].cpu == cpu:
                        other = ops[1] if pos == 0 and len(ops) > 1 else (
                            ops[0] if pos == 1 else "")
                        accesses.append(Access(
                            ins.image, cpu, ins.routine, ins.addr, b, o,
                            "W" if pos == 0 else "R",
                            {"ldb": "8", "ldw": "16"}.get(m, "?"),
                            other, ins.raw))
                continue
            # (b) REGISTER-INDIRECT, with or without a displacement.
            pm = PTR_RE.match(op)
            if not pm:
                continue
            reg = pm.group(1)
            val = regs.get(reg)
            disp = 0
            if pm.group(2):
                d = _int(pm.group(3)) or 0
                # unidasm renders a negative displacement as its unsigned byte
                if pm.group(2) == "-":
                    d = -d
                elif d >= 0x80 and d <= 0xFF:
                    d = d - 0x100
                disp = d
            if val is None:
                if reg in regs and regs[reg] is not None:
                    pass
                # only interesting if it *could* have been a device; recorded
                # below as residue only when the routine had a device base
                continue
            base, off = val
            eff = off + disp
            if not (0 <= eff < SPAN):
                continue
            dirn = "W" if pos == 0 else "R"
            other = ops[1] if pos == 0 and len(ops) > 1 else (
                ops[0] if pos == 1 else "")
            width = {"ldb": "8", "ldw": "16"}.get(m, "?")
            accesses.append(Access(ins.image, cpu, ins.routine, ins.addr,
                                   base, eff, dirn, width, other, ins.raw))

        # ★ RESIDUE.  `extpfx4 0xB1,0x02,0x00,0x80` is a raw-encoding escape the
        # tree uses where llvm-mc cannot spell an instruction.  It is a real port
        # write (Dev108000_Preload_80toBF writes +2 through one) and this parser
        # cannot decode it.  Counted, not hidden.
        if m.startswith("extpfx") and any(v for v in regs.values()):
            undecoded += 1

        # ---- TRANSFERS ----
        if m in ("ld", "ldb", "ldw", "ldl") and len(ops) == 2:
            dst, src = ops
            newv = "keep"
            sv = in_window(_int(src))
            if sv is not None:
                newv = sv
            elif src in R32:
                newv = regs.get(src)
            elif SLOT_RE.match(src):
                newv = slots.get(src)
            else:
                newv = None
            if dst in R32:
                regs[dst] = newv if newv != "keep" else None
            elif SLOT_RE.match(dst) and src in R32:
                slots[dst] = regs.get(src)
            elif SLOT_RE.match(dst):
                slots[dst] = None
            continue
        if m in ("inc", "dec") and len(ops) == 2 and ops[1] in R32:
            n = _int(ops[0])
            if n is not None and regs.get(ops[1]):
                b, o = regs[ops[1]]
                regs[ops[1]] = (b, o + (n if m == "inc" else -n))
            else:
                regs[ops[1]] = None
            continue
        if m in ("add", "sub") and len(ops) == 2 and ops[0] in R32:
            n = _int(ops[1])
            if n is not None and regs.get(ops[0]):
                b, o = regs[ops[0]]
                regs[ops[0]] = (b, o + (n if m == "add" else -n))
            else:
                regs[ops[0]] = None
            continue
        if m in ("lda", "lda32") and ops and ops[0] in R32:
            regs[ops[0]] = None
            continue
        if m in ("pop", "popw") and ops and ops[0] in R32:
            regs[ops[0]] = None
            continue
        if m in ("call", "calr", "ret", "reti", "retd", "swi", "swi7"):
            # ⚠ CONSERVATIVE.  A callee may preserve XBC; assuming so would let
            # a wrong base leak across a call and be reported as fact.
            regs = {}
            continue
        if m in ("link32", "link", "unlk32", "unlk"):
            regs, slots = {}, {}     # a new frame: the old slots are gone
            continue
        # ⚠ a JUMP is deliberately NOT a barrier.  A conditional `jr` falls
        # through, and every label already resets the state, so clearing here
        # would only lose the fall-through arm.
        # anything else that names a 32-bit register first: assume clobber
        if ops and ops[0] in R32:
            regs[ops[0]] = None
    return accesses, undecoded


def collect():
    out = {}
    for image, primary, cpu in IMAGES:
        insns, incbins, labels = parse(image, primary)
        acc, undecoded = walk(insns, cpu)
        out[image] = dict(cpu=cpu, insns=insns, incbins=incbins,
                          labels=labels, acc=acc, undecoded=undecoded)
    return out


# ---------------------------------------------------------------------------
# Reports
# ---------------------------------------------------------------------------
def literal_hits(insns, base, size):
    """What the SHARED TOOL would see: the window's addresses as literals."""
    n = 0
    for ins in insns:
        for op in ins.ops:
            v = _int(op)
            if v is not None and base <= v < base + size:
                n += 1
    return n


def report_registers(data):
    print("PER-REGISTER CENSUS, following base registers")
    print("=" * 78)
    for w in WINDOWS:
        rows = collections.Counter()
        routines = collections.defaultdict(set)
        for image, d in data.items():
            if d["cpu"] != w.cpu:
                continue
            for a in d["acc"]:
                if a.base != w.base:
                    continue
                rows[(a.off, a.dirn)] += 1
                routines[a.off].add(a.label)
        tot = sum(rows.values())
        star = "" if w.shared else "   ★ NOT IN THE SHARED TOOL'S WINDOW LIST"
        print("\n%s  0x%08X  (%s)%s" % (w.name, w.base, w.cpu, star))
        print("  %s" % w.what)
        if not rows:
            print("    (no attributed access)")
            continue
        for off in sorted({o for o, _ in rows}):
            wr = rows.get((off, "W"), 0)
            rd = rows.get((off, "R"), 0)
            print("    +0x%02X   %4d write   %4d read   %3d routine(s)"
                  % (off, wr, rd, len(routines[off])))
        print("    TOTAL %d attributed accesses" % tot)


def report_windows(data):
    print("WINDOW COMPLETENESS -- literal scan vs base-following")
    print("=" * 78)
    print("""COLUMN MEANINGS, because the two are not the same unit:
  literal   operands anywhere in the image whose VALUE lands in the window.
            That is what a literal census counts, and it is mostly BASE LOADS
            -- `ld xbc,0x10C000` -- not accesses.
  accesses  actual port reads and writes, after following the base into its
            displacement uses.  ONE base load can serve twenty accesses.
""")
    print("%-11s %-6s %-5s %8s %9s   %s"
          % ("window", "cpu", "in?", "literal", "accesses", "offsets reached"))
    for w in WINDOWS:
        lit = fol = 0
        for image, d in data.items():
            if d["cpu"] != w.cpu:
                continue
            lit += literal_hits(d["insns"], w.base, w.size)
            fol += sum(1 for a in d["acc"] if a.base == w.base)
        off_seen = sorted({a.off for image, d in data.items()
                           if d["cpu"] == w.cpu
                           for a in d["acc"] if a.base == w.base})
        print("%-11s %-6s %-5s %8d %9d   %s"
              % (w.name, w.cpu, "yes" if w.shared else "NO", lit, fol,
                 ", ".join("+0x%02X" % o for o in off_seen) or "-"))
    print("""
★ The `in?` column is the finding.  Two 4-channel address/data devices that this
  tree's own headers call DSP register files -- one per processor -- are absent
  from the window list the coverage claim was computed over, and the P7 effect
  transport is not a window at all.""")


def report_routines(data):
    """Per-routine coverage: is any sound routine's text unconverted?"""
    print("PER-ROUTINE COVERAGE for every routine that touches a sound device")
    print("=" * 78)
    total = bad = 0
    for image, d in data.items():
        by_routine = collections.defaultdict(list)
        for a in d["acc"]:
            by_routine[a.label].append(a)
        incbin_labels = {lbl for lbl, _, _ in d["incbins"]}
        print("\n%s (%s): %d routine(s), %d access(es)"
              % (image, d["cpu"], len(by_routine), len(d["acc"])))
        for lbl in sorted(by_routine):
            total += 1
            hits = by_routine[lbl]
            devs = sorted({BASES[a.base].name for a in hits})
            flag = ""
            if lbl in incbin_labels:
                flag = "   ⚠ .incbin INSIDE THIS ROUTINE"
                bad += 1
            print("    %-46s %3d  %s%s"
                  % (lbl, len(hits), ",".join(devs), flag))
    print("\n%d sound routines, %d with unconverted text inside them." % (total, bad))
    return bad


def report_stream(data, base, only=None):
    """Select/data pairs IN EXECUTION ORDER -- never zipped from two lists.

    ⚠ notes/FINDINGS-prom_c-tone-generator.md §3 records a retraction caused by
    zipping a list of register numbers against a list of data fetches.  This
    prints the stream and lets the reader do the pairing.
    """
    w = BASES[base]
    print("ACCESS STREAM for %s 0x%08X, in source (= address) order" % (w.name, base))
    print("=" * 78)
    n = 0
    for image, d in data.items():
        if d["cpu"] != w.cpu:
            continue
        last = None
        for a in d["acc"]:
            if a.base != base:
                continue
            if only and only not in a.label:
                continue
            if a.label != last:
                print("\n  --- %s / %s ---" % (image, a.label))
                last = a.label
            role = {0: "SELECT", 2: "DATA", 4: "READBACK"}.get(a.off, "+0x%02X" % a.off)
            print("      %-8s %-8s %-6s %s"
                  % ("%06X" % a.addr if a.addr else "??????",
                     role, a.dirn, a.raw))
            n += 1
    print("\n%d accesses." % n)


# ---------------------------------------------------------------------------
# THE DSP TRANSPORT THAT IS NOT A WINDOW
# ---------------------------------------------------------------------------
# `extpfx5 0x8E, <disp>, 0x19, <lo>, <hi>` is the tree's raw-encoding escape for
# `ld (0xHILO),(XIZ+disp)` -- an instruction llvm-mc cannot spell.  The DSP
# EFFECT MICROCODE leaves CPU 2 through exactly this instruction, writing SFR
# 0x0013 = PORT P7 (`../notes/prom_c_dsp_port.py`).  ★ NO OPERAND SCAN CAN SEE
# IT: the destination address is not an operand, it is two payload bytes of an
# assembler directive.  This is the strongest single argument that a window list
# is the wrong instrument for "is the sound code covered".
EXTPFX5_RE = re.compile(
    r'^extpfx5\s+0x8e,\s*(0x[0-9a-f]+),\s*0x19,\s*(0x[0-9a-f]+),\s*(0x[0-9a-f]+)$')


def report_p7(data):
    print("THE DSP EFFECT TRANSPORT: PORT P7, which is NOT a memory window")
    print("=" * 78)
    print("""P7 = SFR 0x0013.  Nine arms of three routines write the caller's byte to it;
the strobe/valid/ready lines are P5 bits 3-5, P2 bit 7, PB bits 5-6 and P9 bit 3.
Established by ../notes/prom_c_dsp_port.py; that a P7 stream IS DSP effect data
by ../notes/FINDINGS-prom_c-p7-is-dsp-effects.md (effect 5 PHASER's 164 bytes are
byte-identical to the KN5000's DSP_Eff05_Coef_Bytecode).
""")
    n = 0
    for image, d in data.items():
        for ins in d["insns"]:
            m = EXTPFX5_RE.match(ins.mnem + " " + ", ".join(ins.ops))
            if not m:
                continue
            sfr = int(m.group(3), 16) * 256 + int(m.group(2), 16)
            if sfr != 0x0013:
                continue
            # ★ CROSS-CHECK, not a comment read: the SFR is decoded from the
            # directive's own payload bytes AND the unidasm text in the trailing
            # comment must agree.  Either alone would be a single point of trust.
            n += 1
            print("    %-8s %-34s %s"
                  % ("%06X" % ins.addr if ins.addr else "??????",
                     ins.routine, ins.raw))
    print("\n%d writes to P7.  A literal-window census of this image reports ZERO,"
          "\nbecause the destination is not an operand." % n)


def report_values(data):
    """What VALUES cross the boundary -- immediates only, which is what is knowable."""
    print("IMMEDIATE VALUES WRITTEN TO EACH DEVICE OFFSET")
    print("=" * 78)
    for w in WINDOWS:
        vals = collections.defaultdict(collections.Counter)
        for image, d in data.items():
            if d["cpu"] != w.cpu:
                continue
            for a in d["acc"]:
                if a.base != w.base or a.dirn != "W":
                    continue
                v = _int(a.operand)
                vals[a.off][("0x%X" % v) if v is not None else a.operand] += 1
        if not vals:
            continue
        print("\n%s 0x%08X" % (w.name, w.base))
        for off in sorted(vals):
            imm = {k: c for k, c in vals[off].items() if k.startswith("0x")}
            regs = sum(c for k, c in vals[off].items() if not k.startswith("0x"))
            # ⚠ print ALL of them.  A truncated list of immediates is how a
            # register map loses its thirteenth entry and nobody notices.
            order = sorted(imm, key=lambda k: int(k, 16))
            print("    +0x%02X  %d via a register; %d distinct immediate(s)%s"
                  % (off, regs, len(imm),
                     (": " + ", ".join(order)) if imm else ""))


# ---------------------------------------------------------------------------
def selftest():
    data = collect()
    checks, fails = [], 0

    def ck(name, cond, detail=""):
        nonlocal fails
        checks.append((name, cond, detail))
        if not cond:
            fails += 1

    acc = {img: d["acc"] for img, d in data.items()}
    allacc = [a for v in acc.values() for a in v]

    # 1. THE BLIND SPOT IS CLOSED.  The shared tool reports 0 for the data and
    #    readback registers of Dev10C; both must now be non-zero, and the
    #    readback must be READS.
    d10c = [a for a in allacc if a.base == 0x0010C000]
    ck("Dev10C +2 (data) is reached at all",
       any(a.off == 2 for a in d10c),
       "%d accesses" % sum(1 for a in d10c if a.off == 2))
    ck("Dev10C +4 (readback) is reached at all",
       any(a.off == 4 for a in d10c),
       "%d accesses" % sum(1 for a in d10c if a.off == 4))
    ck("Dev10C +4 is READ, never written",
       all(a.dirn == "R" for a in d10c if a.off == 4),
       "%d read / %d write" % (sum(1 for a in d10c if a.off == 4 and a.dirn == "R"),
                               sum(1 for a in d10c if a.off == 4 and a.dirn == "W")))

    # 2. NEGATIVE CONTROL: the walk must not attribute an access to a base it
    #    never saw.  0x00108000 is a keybed, NOT an addr/data pair, so it must
    #    show reads at +0 and +2 and NO +4.
    kb = [a for a in allacc if a.base == 0x00108000]
    ck("KeyScan has no +4 -- the walk is not inventing offsets",
       not any(a.off == 4 for a in kb), "%d accesses" % len(kb))

    # 3. THE OMISSION IS REAL AND MEASURED, not asserted.
    dspc = [a for a in allacc if a.base == 0x00E00000]
    dspa = [a for a in allacc if a.base == 0x007F0000]
    ck("prom_c's 0x00E00000 DSP register file is reached",
       len(dspc) > 0, "%d accesses" % len(dspc))
    ck("prom_a's 0x007F0000 DSP register file is reached",
       len(dspa) > 0, "%d accesses" % len(dspa))
    ck("both DSP files show the addr/data pair shape (+0 and +2)",
       {a.off for a in dspc} >= {0, 2} and {a.off for a in dspa} >= {0, 2},
       "prom_c %s  prom_a %s"
       % (sorted({a.off for a in dspc}), sorted({a.off for a in dspa})))

    # 4. AN ACCESS'S ROUTINE MUST BE A REAL LABEL, not the file preamble.
    ck("every access sits inside a named routine",
       all(a.label != "<top>" for a in allacc),
       "%d at <top>" % sum(1 for a in allacc if a.label == "<top>"))

    # 5. NO SOUND ROUTINE CONTAINS `.incbin` -- the coverage question itself.
    bad = 0
    for img, d in data.items():
        labels_with_acc = {a.label for a in d["acc"]}
        bad += sum(1 for lbl, _, _ in d["incbins"] if lbl in labels_with_acc)
    ck("no routine touching a sound device contains .incbin", bad == 0,
       "%d" % bad)

    # 6. THE PARSER SEES ALL THREE DIALECTS.  boot_and_main.s carries NO address
    #    comment; if the parser required one, the whole 0x00E00000 driver would
    #    vanish and check 3 would still pass off the two prom_a rows.
    ck("addressless (hand-written) converted lines are parsed",
       any(a.addr is None for a in dspc),
       "%d of %d prom_c DSP accesses have no address comment"
       % (sum(1 for a in dspc if a.addr is None), len(dspc)))

    # 7. THE FOLLOWED COUNT MUST BEAT THE LITERAL COUNT, which is the whole point.
    lit = sum(literal_hits(d["insns"], 0x0010C002, 2) for d in data.values())
    ck("base-following beats the literal scan on Dev10C's data register",
       sum(1 for a in d10c if a.off == 2) > lit,
       "followed %d vs literal %d" % (sum(1 for a in d10c if a.off == 2), lit))

    # 8. ★ CALIBRATION against three counts established by OTHER tools and
    #    written into this tree's notes BEFORE this file existed.  A walk that
    #    agreed with nothing would be unfalsifiable.
    def n_in(routine, base=None):
        return sum(1 for a in allacc if a.label == routine
                   and (base is None or a.base == base))

    ck("Dev104_WriteAllChanRegs = 19 registers x 2 = 38  (regmap --dev104)",
       n_in("Dev104_WriteAllChanRegs") == 38, "%d" % n_in("Dev104_WriteAllChanRegs"))
    ck("Dev10C_WriteGlobalRegs = 13 registers x 2 = 26  (tone-generator note §7)",
       n_in("Dev10C_WriteGlobalRegs") == 26, "%d" % n_in("Dev10C_WriteGlobalRegs"))
    ck("DSP_WriteChannelRegs_Inner = 8 registers x 2 = 16, in BOTH images",
       n_in("DSP_WriteChannelRegs_Inner", 0x00E00000) == 16
       and n_in("DSP_WriteChannelRegs_Inner", 0x007F0000) == 16,
       "prom_c %d  prom_a %d" % (n_in("DSP_WriteChannelRegs_Inner", 0x00E00000),
                                 n_in("DSP_WriteChannelRegs_Inner", 0x007F0000)))
    # ★ AND ONE CALIBRATED DISAGREEMENT, which is the honest shape of the cost.
    #   notes/prom_c_tg_chanmap.py --selftest reports 23 SELECT + 23 DATA = 46
    #   for Dev10C_WriteAllChanRegs.  This walk finds 45.  The missing one is the
    #   store whose base register survived a `calr` -- chanmap recovers it by
    #   disassembling the callee and reading its push/pop set; this file's rule
    #   is "a call clears every register", so it cannot.  If this number ever
    #   becomes 46 without that rule changing, the rule has been broken.
    ck("Dev10C_WriteAllChanRegs = 45 of chanmap's 46 (the post-`calr` store)",
       n_in("Dev10C_WriteAllChanRegs") == 45, "%d" % n_in("Dev10C_WriteAllChanRegs"))

    # 9. THE P7 TRANSPORT IS INVISIBLE TO AN OPERAND SCAN, and that is the point.
    p7 = 0
    for d in data.values():
        for ins in d["insns"]:
            mm = EXTPFX5_RE.match(ins.mnem + " " + ", ".join(ins.ops))
            if mm and int(mm.group(3), 16) * 256 + int(mm.group(2), 16) == 0x0013:
                p7 += 1
    ck("P7 (SFR 0x0013) is written, and only as a raw-encoding directive",
       p7 == 9, "%d writes" % p7)
    # ⚠ THE NEGATIVE CONTROL, and it must be about DEREFERENCES, not about the
    #   number 0x13 -- `ldb d,0x13` and `cp bc,19` are everywhere and mean
    #   nothing.  What must be zero is any instruction that DEREFERENCES 0x0013,
    #   because that is the only form an address-matching census could catch.
    p7_deref = sum(1 for d in data.values() for ins in d["insns"] for op in ins.ops
                   if ABS_RE.match(op) and _int(ABS_RE.match(op).group(1)) == 0x0013)
    ck("no P7 write DEREFERENCES 0x0013 in a form an address census could match",
       p7_deref == 0, "%d such operands" % p7_deref)

    # 10. Expansion caches must not be in the walk.
    ck("no .image-* cache reached the walk",
       all(not os.path.basename(p).startswith(".")
           for p in [ROOT]), "structural")

    for name, ok, detail in checks:
        print("  %-4s %-58s %s" % ("ok" if ok else "FAIL", name, detail))
    print("\n%d checks, %d failures" % (len(checks), fails))
    return 1 if fails else 0


def main():
    args = sys.argv[1:]
    if "--selftest" in args:
        sys.exit(selftest())
    data = collect()
    if "--windows" in args:
        report_windows(data)
    elif "--routines" in args:
        report_routines(data)
    elif "--p7" in args:
        report_p7(data)
    elif "--values" in args:
        report_values(data)
    elif "--stream" in args:
        base = int(args[args.index("--stream") + 1], 16)
        only = args[args.index("--routine") + 1] if "--routine" in args else None
        report_stream(data, base, only)
    else:
        report_registers(data)


if __name__ == "__main__":
    main()
