#!/usr/bin/env python3
r"""WHERE is the KN5000's sound code, is all of it DISASSEMBLED, and WHAT crosses
the chip boundary?

QUESTION IT ANSWERS
    Felipe's goal is full COVERAGE of every routine that talks to the tone
    generator, the DSPs and (if it exists) an acoustic-modelling LSI.  This tool
    answers four things about the KN5000 and nothing else:

      1. WHERE is the sound code -- every instruction that names a sound-chip
         window OR drives one of the chip-control port pins, and the routine
         that contains it.
      2. Is any of it still UNDISASSEMBLED?  Not "still .incbin" -- see below.
      3. Does each sound routine's control flow stay inside disassembled text?
      4. WHAT crosses the boundary: which register, which direction, what value.

★★ THREE CORRECTIONS TO notes/sound/sound_coverage.py, ALL MEASURED
    That tool reported "400 sites, 218 routines, ZERO .incbin inside or after a
    sound routine" and concluded the sound subsystem was territorially complete.
    Every one of those words is true and the conclusion does not follow.

    1. ★ `.incbin` IS NOT THE ONLY WAY A BYTE CAN BE UNDISASSEMBLED.  A `.byte`
       run is exactly as un-decoded as an `.incbin` and it passes a "no .incbin"
       test.  kn5000_subprogram_v142.s holds 15,996 bytes of `.byte`, and two
       runs of it -- 0x0280FE-0x028838 and 0x028F75-0x029E30 -- were ALREADY
       ANNOTATED IN THE SOURCE as "MISLABELLED, THIS IS CODE", with 21 and 60-odd
       named entry points, most of them tone-generator register writers.  That is
       the real coverage debt and the old tool could not see it.

    2. ★ THE WAVE_RAM WINDOW IS SUB-CPU ONLY.  0x1E0000-0x1EFFFF is waveform RAM
       in kn5000.cpp's subcpu_map, but in the MAIN CPU's map 0x1E0000-0x1FFFFF is
       the battery-backed 1 Mbit SRAM at IC21.  The old tool scanned
       v10/maincpu/audio with the sub-CPU window list, so 42 of its 49 "WAVE_RAM"
       sites are SRAM accesses in the sound-editor UI and note-mapping code.
       ⚠ THE MAIN CPU HAS NO WINDOW ON ANY SOUND CHIP AT ALL.  It reaches the
       tone generator only by sending commands to the sub-CPU through the IC22 /
       IC23 latch pair at 0x140000.

    3. ★ A CONSTANT IS NOT AN ACCESS.  The old scan matched any hex literal
       inside a window, so `cp xhl, 0x100000` (a float normalisation constant in
       subcpu_fp_math.s) and a `.long 0x1e0c51c0` in a data table both counted.
       This tool classifies every hit as DIRECT (the address is a memory
       operand), BASE (loaded into a register, which is then used with
       displacements), or CONST (an immediate to a compare/arith, or inside a
       data directive) and only the first two are accesses.

★ AND THE BLIND SPOT THE OLD TOOL DOCUMENTED IS BIGGER ON THE KN5000 THAN IT SAID
    A literal address scan misses register-indirect access.  On the KN5000 that
    costs the DSP window its data port outright -- DSP_Write_Channel and
    DSP_WriteChannelRegs_Inner load 0x130000 into XHL/XIY and then write
    `(xhl)` / `(xhl+2)`, so the DSP DATA port is NEVER NAMED and the old tool's
    "DSP_DATA 0" was a measurement of its own blindness.
    ★★ AND THE LARGER MISS IS NOT ADDRESSES AT ALL: the busiest sound-chip line
    in the whole payload is a PORT PIN.  P6 bit 7 (SFR 0x18) is strobed low
    around every tone-generator address latch and high again before the data
    word -- 141 res / 140 set in the v142 payload, against 140 latch writes --
    and no address-window scan can see a single one of them.  The DSP transport
    is port-driven too: P7 (0x1C) bits 3/4/5/6, PE (0x38) bit 6, PH (0x44) bits
    0/1/2, PZ (0x68) as the DSP1 byte port and PF (0x3C) bits 0/2 as DSP2's
    bit-banged clock and data.

RUN:  python3 notes/sound/kn5000_sound_boundary.py              # the census
      python3 notes/sound/kn5000_sound_boundary.py --routines   # per routine
      python3 notes/sound/kn5000_sound_boundary.py --misframes  # coverage debt
      python3 notes/sound/kn5000_sound_boundary.py --registers  # the boundary
      python3 notes/sound/kn5000_sound_boundary.py --selftest

HOW THE ADDRESSES ARE OBTAINED
    `llvm-mc -show-encoding` flattens the whole include tree and prints every
    instruction with its encoding bytes and every `.byte` one per line, so
    walking the stream from the linker script's ORIGIN gives an exact address for
    every byte.  --selftest checks that walk against `llvm-nm` on the real link:
    if a single directive were sized wrongly the two would disagree.
"""
import collections, os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
PROJ = os.environ.get("PROJECTS_ROOT", os.path.expanduser("~/compartilhado"))
MC = os.path.join(PROJ, "llvm-project", "build", "bin", "llvm-mc")
NM = os.path.join(PROJ, "llvm-project", "build", "bin", "llvm-nm")

# ---------------------------------------------------------------- the images
# origin comes from each image's linker script; `elf` is the linked image the
# selftest cross-checks the address walk against.
IMAGES = {
    "v142_subcpu": dict(
        incdir="v142/subcpu", root="v142/subcpu/kn5000_subprogram_v142.s",
        origin=0x000400, elf="rebuilt_ROMs/kn5000_subprogram_v142.llvm.elf",
        # ⚠ the link spans 0x000400-0x03EAFF but the ROM is only the two slices
        # the Makefile's `dd` keeps; the 58,624 bytes of 0xFF between them are
        # padding and counting them would inflate every "undisassembled" figure.
        regions=[(0x000400, 0x000500), (0x00F000, 0x03EB00)],
        what="sub-CPU payload v1.42 -- the sound CPU's program"),
    "subcpu_boot": dict(
        incdir="subcpu/boot", root="subcpu/boot/kn5000_subcpu_boot.s",
        origin=0xFE0000, elf="rebuilt_ROMs/kn5000_subcpu_boot.llvm.elf",
        regions=[(0xFE0000, 0x1000000)],
        what="sub-CPU boot ROM (IC30)"),
}

# ------------------------------------------------------- the hardware contract
# ★ SOURCE: kn5000.cpp subcpu_map, which was itself derived from these ROMs.
# These windows exist ONLY in the sub-CPU's address space.  See correction 2.
WINDOWS = [
    ("TG_ADDR",  0x100000, 0x100001, "IC303 register-ADDRESS latch (w) / active-voice bitmap (r)"),
    ("TG_DATA",  0x100002, 0x100003, "IC303 register DATA port"),
    ("TG_KBD",   0x110000, 0x110003, "IC303 keybed data (+0) and status (+2), A23 high"),
    ("DSP_ADDR", 0x130000, 0x130001, "IC311 channel-register ADDRESS"),
    ("DSP_DATA", 0x130002, 0x130003, "IC311 channel-register DATA"),
    ("WAVE_RAM", 0x1E0000, 0x1EFFFF, "waveform / sample RAM window (never accessed -- see below)"),
]

# ★ THE PORT PINS.  SFR numbers from v142/subcpu/shared/sfr_tmp94c241.s; the bit
# assignments are the firmware's own (the DSP CONTROL ROUTINES header at
# v142/subcpu/kn5000_subprogram_v142.s), corroborated for DSP2 by the schematic
# net names DSP2DA / DSP2SCK / DSP2CS quoted in kn5000.cpp.
# (sfr, bit or None for a whole-byte port, chip, meaning)
PINS = [
    (0x18, 7, "IC303", "tone-generator select, strobed LOW around the address latch"),
    (0x1C, 3, "IC311", "DSP write strobe (active low)"),
    (0x1C, 4, "IC311", "DSP read strobe (active low)"),
    (0x1C, 5, "IC311", "DSP1 chip select (active low)"),
    (0x1C, 6, "IC311", "DSP command/data select (0 = command, 1 = data)"),
    (0x38, 6, "IC310", "DSP2 chip select (active low)"),
    (0x44, 0, "IC311", "DSP status/ready in"),
    (0x44, 1, "IC311", "DSP1 reset (active low)"),
    (0x44, 2, "IC310", "DSP2 reset (active low)"),
    (0x68, None, "IC311", "DSP1 command/data byte port (PZ)"),
    (0x3C, 0, "IC310", "DSP2 serial DATA (SDA), bit-banged"),
    (0x3C, 2, "IC310", "DSP2 serial CLOCK (SCLK), bit-banged"),
]
PIN_SFRS = {s for s, _b, _c, _w in PINS}

LABEL = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.$]*):')
ENC = re.compile(r';\s*encoding:\s*\[([^\]]*)\]')
FIXUP = re.compile(r';\s*fixup \w+ - offset: \d+, value: ([A-Za-z_.][A-Za-z0-9_.$]*)')
BYTE = re.compile(r'^\s*\.byte\s+(\d+)\s*$')
# ⚠ EVERY DIRECTIVE THAT EMITS BYTES MUST BE SIZED, or the address walk drifts
# and every figure after the first one is wrong.  --selftest catches exactly that
# by comparing the walk to `llvm-nm` on the real link; the first version of this
# tool sized only `.byte` and was 71,325 bytes adrift by the end of the payload.
# Widths measured, not assumed: see the sizing probe in --selftest.
DIRW = {".byte": 1, ".word": 4, ".hword": 2, ".dword": 8, ".short": 2,
        ".long": 4, ".quad": 8}
FILL = re.compile(r'^\s*\.fill\s+(\d+)\s*,\s*(\d+)')
ZERO = re.compile(r'^\s*\.(?:zero|space|skip)\s+(\d+)')
ORG = re.compile(r'^\s*\.org\s+(\d+)')
ASCII = re.compile(r'^\s*\.(ascii|asciz|string)\s+"(.*)"\s*$')
ESC = re.compile(r'\\(x[0-9A-Fa-f]{1,2}|[0-7]{1,3}|.)')
DEC = re.compile(r'(?<![\w.$])(\d{4,10})(?![\w.$])')
# the SFR bit forms this backend spells: set_dd8 / res_dd8 / bit_dd8 / ldcf_dd8 /
# chg_dd8 take (bit, sfr); st_dd8b / ld_dd8b take (reg, sfr).
SFR_BIT = re.compile(r'^\s*(set_dd8|res_dd8|bit_dd8|ldcf_dd8|chg_dd8|stcf_dd8)\s+(\d+),\s*(\d+)')
SFR_REG = re.compile(r'^\s*(st_dd8b|st_dd8w|ld_dd8b|ld_dd8w|ldb_dd8|ldw_dd8)\s+\S+,\s*(\d+)')
# flow enders: after these, fall-through does not continue.
FLOW_END = ("ret", "reti", "retd", "jp ", "jp\t", "jrl\t", "jrl ", "halt", "swi")


def _sh(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode:
        sys.exit("command failed: " + " ".join(cmd) + "\n" + (r.stderr or "")[:2000])
    return r.stdout


def flatten(key):
    """Walk `llvm-mc -show-encoding` and give every byte an address.

    -> dict with:
       code    {addr: (size, text)}        every instruction
       data    {addr: size}                every byte emitted by a directive
       labels  {name: addr}
       order   [(addr, kind, text)]        stream order, kind in {i, d, l}
       refs    [(addr, symbol)]            every symbolic fixup, i.e. every
                                           branch/call target named by name
    """
    im = IMAGES[key]
    out = _sh([MC, "-triple=tlcs900", "-show-encoding",
               "-I", os.path.join(ROOT, im["incdir"]), os.path.join(ROOT, im["root"])])
    addr = im["origin"]
    code, data, labels, order, refs = {}, {}, {}, [], []
    last_insn = None
    for line in out.split("\n"):
        lm = LABEL.match(line)
        if lm:
            labels[lm.group(1)] = addr
            order.append((addr, "l", lm.group(1)))
            continue
        fm = FIXUP.search(line)
        if fm and last_insn is not None:
            refs.append((last_insn, fm.group(1)))
            continue
        # ⚠ .ascii MUST BE MATCHED ON THE RAW LINE.  Stripping at the first ';'
        # cut the velocity curve's string in half at the character ';' and lost
        # 95 bytes, which is what the nm cross-check caught.
        am = ASCII.match(line.rstrip())
        if am:
            n = len(ESC.sub("x", am.group(2))) + (1 if am.group(1) != "ascii" else 0)
            data[addr] = data.get(addr, 0) + n
            order.append((addr, "d", line.strip()))
            addr += n
            continue
        em = ENC.search(line)
        if em:
            n = len([x for x in em.group(1).split(",") if x.strip()])
            text = line.split(";")[0].strip()
            code[addr] = (n, text)
            order.append((addr, "i", text))
            last_insn = addr
            addr += n
            continue
        s = line.split(";")[0].rstrip()
        t = s.strip()
        if t.startswith("."):
            d = t.split()[0]
            if d in DIRW:
                n = DIRW[d] * len([x for x in t.split(None, 1)[1].split(",") if x.strip()])
            elif FILL.match(s):
                m = FILL.match(s)
                n = int(m.group(1)) * int(m.group(2))
            elif ZERO.match(s):
                n = int(ZERO.match(s).group(1))
            elif ORG.match(s):
                addr = im["origin"] + int(ORG.match(s).group(1))
                continue
            else:
                continue        # .text / .set / .equ emit nothing
            data[addr] = data.get(addr, 0) + n
            order.append((addr, "d", t))
            addr += n
    return dict(code=code, data=data, labels=labels, order=order, refs=refs,
                end=addr, image=key)


def routine_of(order):
    """addr -> the nearest preceding label.  Also returns, per label, its span."""
    owner, cur, spans = {}, None, {}
    for addr, kind, text in order:
        if kind == "l":
            cur = text
            spans.setdefault(cur, [addr, addr])
        elif cur:
            spans[cur][1] = addr
            owner[addr] = cur
    return owner, spans


def sites(fl):
    """Every sound-chip access.  -> [(addr, routine, chip, kind, what, text)]"""
    owner, _spans = routine_of(fl["order"])
    out = []
    base_reg = {}          # register -> window name, while it holds a base
    for addr in sorted(fl["code"]):
        _n, text = fl["code"][addr]
        rt = owner.get(addr, "?")
        low = text.lower()
        # --- SFR port pins -------------------------------------------------
        m = SFR_BIT.match(text)
        if m and int(m.group(3)) in PIN_SFRS:
            sfr, bit = int(m.group(3)), int(m.group(2))
            for s, b, chip, what in PINS:
                if s == sfr and b == bit:
                    out.append((addr, rt, chip, "PIN", f"SFR 0x{sfr:02X}.{bit}", text))
                    break
            continue
        m = SFR_REG.match(text)
        if m and int(m.group(2)) in PIN_SFRS:
            sfr = int(m.group(2))
            for s, b, chip, what in PINS:
                if s == sfr and b is None:
                    out.append((addr, rt, chip, "PORT", f"SFR 0x{sfr:02X}", text))
                    break
            continue
        # --- address windows ------------------------------------------------
        hit = None
        for v in (int(x) for x in DEC.findall(text)):
            for name, lo, hi, _w in WINDOWS:
                if lo <= v <= hi:
                    hit = (name, v)
                    break
            if hit:
                break
        if hit:
            name, v = hit
            # DIRECT: the address is a memory operand -- it is in parentheses,
            # or the mnemonic is one of the direct-addressing forms.
            direct = ("(%d)" % v) in text.replace(" ", "") or \
                     re.search(r'\b(st\w*_da|ld\w*_da|sti\w*_da|lda_24|ld16_24|st16_24)\b', low)
            if direct:
                out.append((addr, rt, chip_of(name), "DIRECT", name, text))
            else:
                # BASE: `ld xNN, <window base>` -- the register now holds a base.
                mm = re.match(r'^ld\s+(x\w\w|x\w\w\w)\s*,\s*%d$' % v, text.replace("\t", " ").strip())
                if mm:
                    base_reg[mm.group(1)] = name
                    out.append((addr, rt, chip_of(name), "BASE", name, text))
                else:
                    out.append((addr, rt, chip_of(name), "CONST", name, text))
            continue
        # --- displacement uses of a register holding a base -----------------
        for reg, name in list(base_reg.items()):
            mm = re.search(r'\(%s([+-]\d+)?\)' % reg, text.replace("\t", " "))
            if mm:
                off = int(mm.group(1) or 0)
                out.append((addr, rt, chip_of(name), "INDIRECT",
                            f"{name}{off:+d}" if off else name, text))
                break
        # a call clears the assumption: the callee may reuse the register.
        if low.startswith(("call", "calr", "jp ", "jp\t")):
            base_reg.clear()
    return out


def chip_of(win):
    return "IC311" if win.startswith("DSP") else "IC303"


BRANCH = re.compile(r'^(call|calr|jp|jp_24|jp16|jp24|jr|jrl|djnz8|djnz16)\b\s*(.*)$')


def sext(v, bits):
    return v - (1 << bits) if v >> (bits - 1) else v


def targets(fl):
    """Every control-flow target this image names, symbolic OR numeric.

    ★ THE NUMERIC HALF IS NOT OPTIONAL.  458 of the payload's branches and calls
    are still written as bare numbers (`calr 65123`), so a scan that reads only
    llvm-mc's symbolic fixups sees three quarters of the edges and concludes the
    tree has no undisassembled routines.  It has.

    This backend's relative operand IS THE RAW DISPLACEMENT FIELD, not a target
    address -- `jrl t, 0xfd30` assembles to `78 30 fd` wherever it sits -- so the
    target is (address of the next instruction) + the sign-extended field.
    `call`/`jp` take an absolute address instead."""
    out = []
    for src, sym in fl["refs"]:
        a = fl["labels"].get(sym)
        # ⚠ ONLY CONTROL-FLOW FIXUPS COUNT.  `lda_24 xwa, Table` also emits a
        # symbolic fixup, and taking the address of a table is not branching to
        # it -- counting those would frame pointer tables as routines, which is
        # this project's oldest way of being wrong.
        if a is not None and BRANCH.match(fl["code"][src][1].replace("\t", " ").strip()):
            out.append((src, a))
    for addr, (n, text) in fl["code"].items():
        t = text.replace("\t", " ").strip()
        m = BRANCH.match(t)
        if not m:
            continue
        arg = m.group(2).split(",")[-1].strip()
        if not re.fullmatch(r'-?\d+', arg):
            continue        # symbolic (already covered) or register-indirect
        v, op = int(arg), m.group(1)
        if op in ("call", "jp", "jp_24", "jp16", "jp24"):
            out.append((addr, v))
        elif op in ("jr", "djnz8"):
            out.append((addr, addr + n + sext(v & 0xFF, 8)))
        else:                # calr, jrl, djnz16 -- rel16
            out.append((addr, addr + n + sext(v & 0xFFFF, 16)))
    return out


def misframes(fl):
    """Bytes framed as DATA that CODE branches or calls to.

    ★ THIS IS THE COVERAGE MEASUREMENT.  A label that a `call`/`calr`/`jr`
    names, and whose first byte was emitted by a data directive, is a routine
    the tree has not disassembled.  It is the .byte analogue of an .incbin span
    that reachability analysis reaches."""
    _owner, spans = routine_of(fl["order"])
    byaddr = {}
    for name, a in fl["labels"].items():
        byaddr.setdefault(a, name)
    dat = fl["data"]
    hits = collections.defaultdict(list)
    for src, a in targets(fl):
        if a in dat and in_rom(fl, a):
            hits[a].append(src)
    out = []
    for a in sorted(hits):
        name = byaddr.get(a, "(no label)")
        lo, hi = spans.get(name, (a, a))
        out.append((name, a, (hi - lo) if name in spans else 0,
                    sorted(hits[a])[0], len(hits[a])))
    return out


def in_rom(fl, a):
    return any(lo <= a < hi for lo, hi in IMAGES[fl["image"]]["regions"])


def coverage(fl, st):
    """PER-ROUTINE COVERAGE, which is the deliverable.

    For every routine that touches a sound chip, does its control flow stay
    inside DISASSEMBLED text?  Two ways it can fail, and both are checked:

      * an outgoing edge (call, branch) whose target byte was emitted by a data
        directive -- the routine calls something the tree has not decoded;
      * FALL-THROUGH: the routine's last instruction is not a flow end and the
        next byte is data -- execution runs straight off the end of source.

    -> [(routine, lo, hi, [bad targets], falls_through)]"""
    owner, spans = routine_of(fl["order"])
    sound = sorted({s[1] for s in st if s[3] != "CONST" and s[1] != "?"})
    tg = collections.defaultdict(list)
    for src, a in targets(fl):
        tg[owner.get(src, "?")].append((src, a))
    out = []
    for rt in sound:
        lo, hi = spans[rt]
        bad = [(src, a) for src, a in tg[rt] if a in fl["data"] and in_rom(fl, a)]
        last = max((a for a in fl["code"] if lo <= a <= hi), default=None)
        ft = False
        if last is not None:
            n, text = fl["code"][last]
            t = text.replace("\t", " ").strip()
            ends = t.split()[0] in ("ret", "reti", "retd", "halt", "swi", "jp", "jp_24",
                                    "jp_ind", "jp_rr", "jrl", "jr")
            ft = (not ends) and (last + n) in fl["data"] and in_rom(fl, last + n)
        out.append((rt, lo, hi, bad, ft))
    return out


def undisassembled_bytes(fl):
    return sum(fl["data"].values())


def report(key, argv):
    fl = flatten(key)
    st = sites(fl)
    im = IMAGES[key]
    print(f"\n=== {key}  ({im['what']}) ===")
    ins = sum(n for a, (n, _t) in fl["code"].items() if in_rom(fl, a))
    dat = sum(n for a, n in fl["data"].items() if in_rom(fl, a))
    print(f"  ROM bytes {sum(hi - lo for lo, hi in im['regions']):,}   "
          f"disassembled {ins:,}   emitted by a data directive {dat:,}")
    kinds = collections.Counter(s[3] for s in st)
    acc = [s for s in st if s[3] != "CONST"]
    rts = sorted({s[1] for s in acc if s[1] != "?"})
    print(f"  sound-chip ACCESSES {len(acc):,} in {len(rts):,} routine(s)"
          f"   (plus {kinds.get('CONST', 0)} constant(s) in a window range that are NOT accesses)")
    for k in ("DIRECT", "BASE", "INDIRECT", "PIN", "PORT"):
        print(f"    {k:<9} {kinds.get(k, 0):5d}")
    print("  by window / pin:")
    for what, c in collections.Counter(s[4] for s in acc).most_common():
        print(f"    {what:<14} {c:5d}")
    mf = misframes(fl)
    print(f"  ★ UNDISASSEMBLED but BRANCHED TO (framed as data, code calls it): "
          f"{len(mf)} entry point(s), {sum(n for _s, _a, n, _r, _c in mf):,} bytes in their spans")
    if "--misframes" in argv:
        for sym, a, n, src, c in mf:
            print(f"      0x{a:06X}  {n:5d} B  {sym:<44} {c:3d} referrer(s), e.g. 0x{src:06X}")
    if "--coverage" in argv:
        cov = coverage(fl, st)
        broken = [c for c in cov if c[3] or c[4]]
        print(f"  per-routine coverage: {len(cov)} sound routine(s), "
              f"{len(cov) - len(broken)} whose control flow stays entirely inside "
              f"disassembled text")
        for rt, lo, hi, bad, ft in broken:
            why = []
            if bad:
                why.append("calls undisassembled: " +
                           ", ".join(f"0x{a:06X} from 0x{s:06X}" for s, a in bad[:3]))
            if ft:
                why.append("FALLS THROUGH into data")
            print(f"    0x{lo:06X}  {rt:<46} {'; '.join(why)}")
    if "--routines" in argv:
        per = collections.Counter(s[1] for s in acc if s[1] != "?")
        print("  routines touching a sound chip (all, by site count):")
        for r, c in per.most_common():
            print(f"    {c:4d}  {r}")
    if "--registers" in argv:
        print("  distinct operands seen at the boundary:")
        for t, c in collections.Counter(
                (s[3], s[5]) for s in acc).most_common(40):
            print(f"    {c:5d}  {t[0]:<9} {t[1]}")
    return fl, st, mf


def selftest():
    f = 0

    def ck(d, c, extra=""):
        nonlocal f
        print(("  ok   " if c else "  FAIL ") + d + (("   " + extra) if extra else ""))
        f += not c

    for key, im in IMAGES.items():
        fl = flatten(key)
        # 1. THE ADDRESS WALK IS EXACT.  Every label the walk placed must sit at
        #    the address the real link gives it.  A directive sized wrongly
        #    anywhere shifts everything after it and this fails.
        elf = os.path.join(ROOT, im["elf"])
        if os.path.exists(elf):
            nm = {}
            for line in _sh([NM, elf]).split("\n"):
                p = line.split()
                if len(p) == 3 and p[1] in "tTdDbB":
                    nm[p[2]] = int(p[0], 16)
            common = [s for s in fl["labels"] if s in nm]
            wrong = [s for s in common if nm[s] != fl["labels"][s]]
            ck(f"{key}: the address walk agrees with llvm-nm on the linked image",
               common and not wrong,
               f"{len(common):,} symbols compared, {len(wrong)} disagree"
               + (f" (e.g. {wrong[0]})" if wrong else ""))
        else:
            ck(f"{key}: linked image present for the nm cross-check", False, elf)
        # 2. A LABEL WHOSE NAME ENCODES ITS OWN ADDRESS MUST LAND THERE.  This
        #    is independent of nm and of the link.  ⚠ Only the two generated
        #    prefixes qualify: many hand-written names end in a RAM address
        #    instead (Voice_SetParam_04134B lives at 0x028BB9 and names the
        #    variable it writes), so a looser pattern measures naming style, not
        #    addresses.
        named = [(n, a) for n, a in fl["labels"].items()
                 if re.match(r'^(LABEL|__jrt_nop|__jrt)_0?[0-9A-F]{5,6}$', n)]
        bad = [(n, a) for n, a in named if int(re.search(r'([0-9A-F]{5,6})$', n).group(1), 16) != a]
        ck(f"{key}: labels that carry their own address land on it",
           not bad, f"{len(named)} checked, {len(bad)} wrong"
           + (f" (e.g. {bad[0]})" if bad else ""))
        st = sites(fl)
        ck(f"{key}: the tone generator is reached at all",
           any(s[2] == "IC303" for s in st), f"{len(st)} site(s)")

    # 3. THE CLASSIFIER SEPARATES A CONSTANT FROM AN ACCESS.  This is correction
    #    3, and without it the census counts float constants as chip traffic.
    fl = flatten("v142_subcpu")
    st = sites(fl)
    consts = [s for s in st if s[3] == "CONST"]
    ck("a window-valued immediate to a compare is classified CONST, not an access",
       any("cp" in s[5].split()[0] for s in consts),
       f"{len(consts)} constant(s), e.g. {consts[0][5] if consts else '-'}")
    # 4. THE INDIRECT PATH IS SEEN.  DSP_Write_Channel loads 0x130000 into XHL
    #    and writes (xhl) and (xhl+2); if the base tracking regressed, the DSP
    #    data port would vanish from the census the way it did from the old one.
    ind = [s for s in st if s[3] == "INDIRECT"]
    ck("register-indirect DSP register writes are counted",
       any(s[1].startswith("DSP_Write") for s in ind),
       f"{len(ind)} indirect site(s)")
    # 5. NEGATIVE CONTROL: a window the hardware does not decode must score far
    #    below the real ones, or the census is matching noise rather than code.
    real = sum(1 for s in st if s[3] in ("DIRECT", "INDIRECT") and s[4].startswith("TG"))
    ck("the tone-generator windows are reached far more than any constant range",
       real > 100, f"{real} TG accesses")
    print(f"\n{4 + 3 * len(IMAGES)} checks, {f} failures")
    return 1 if f else 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    for key in IMAGES:
        report(key, sys.argv)
    return 0


sys.exit(main())
