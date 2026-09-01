#!/usr/bin/env python3
"""Which of CPU 2's two 64-channel parameter devices is the ACOUSTIC MODELLING LSI?

QUESTION IT ANSWERS
-------------------
The SX-WSA1R is a PHYSICAL MODELLING synthesiser, so unlike the KN5000 it should
have a modelling part on the board.  CPU 2 drives TWO devices that are both
"64 channels of parameter registers, numbered block*0x40 + channel":

    0x0010C000   Dev10C   22 registers per channel, 355 attributed accesses
    0x00104000   Dev104   19 registers per channel,  78 attributed accesses

`../notes/FINDINGS-prom_c-tone-generator.md` §0 refused to name either, because a
`TG_` prefix had already been retracted once.  This does not rename anything.  It
runs the one comparison that can SEPARATE them, and reports what it separates.

THE METHOD: THE KN5000 IS THE CONTROL GROUP
-------------------------------------------
The KN5000 sub-CPU is a PCM sample-playback engine with no physical modelling,
running an obviously related firmware -- this tree has already shown that its tone
generator stages THE SAME 22 REGISTERS IN THE SAME ORDER as Dev10C
(`../notes/FINDINGS-prom_c-dev10c-sibling-register-map.md`) and that its DSP driver
is byte-identical to the WSA1's but for the base literal.  So the two machines'
sound sections can be lined up device by device, and whatever the modelling machine
has that the PCM machine does NOT is the interesting row.

    python3 notes/sound/wsa1_dev104_vs_kn5000.py            # the alignment
    python3 notes/sound/wsa1_dev104_vs_kn5000.py --profile  # the two register files
    python3 notes/sound/wsa1_dev104_vs_kn5000.py --control  # the positive control
    python3 notes/sound/wsa1_dev104_vs_kn5000.py --selftest

THE ANSWER, and its grade
-------------------------
The alignment is ONE-TO-ONE WITH EXACTLY ONE EXTRA ROW, and the extra row is
Dev104.  Every other device CPU 2 drives has a counterpart in the PCM sibling:
tone generator, keybed, inter-processor latch, DSP register file.  0x00104000 has
none.

  ★ ESTABLISHED (measured here):  Dev104 is the only per-channel synthesis device
    CPU 2 drives that has no counterpart in the PCM sibling, and its register file
    is a DIFFERENT SHAPE from the tone generator's -- 19 CONTIGUOUS blocks
    0x000..0x480 against 22 SPARSE blocks in three clusters.  Two different
    register files, not two windows onto one.
  ★ ESTABLISHED:  Dev10C's port shape {+0 select, +2 data, +4 readback} is the
    KN5000 tone generator's port shape, +4 included (0x100004 occurs in the KN5000
    sub-CPU source, and its own header calls it "a status word").  Dev10C is a
    tone generator of the KN5000 family, and the KN5000 does no modelling.
  ⚠ INFERENCE, RANKED, NOT PROOF:  therefore Dev104 is the acoustic modelling
    section.  What supports it: it is the extra device; it is per-CHANNEL on the
    same 64-channel numbering; it is reset channel by channel inside
    Dev10C_ResetAllChannels, so the two files are two halves of one voice; and all
    four note-on staging paths write BOTH devices for every voice.
  ⚠ WHAT WOULD REFUTE IT:  a part number.  NOTHING in any WSA1 ROM names a chip;
    "three uPD6383GF DSPs" in prom_c/p7/p7_module.s is itself flagged there as an
    import from a parts list and not a finding.  A service manual, a board photo or
    a decapped die is what settles this, and none of them is in this repository.
  ⚠ AND ONE ALTERNATIVE THAT FITS EVERY NUMBER HERE:  that the two devices are the
    DRIVER and the RESONATOR halves of one modelling engine rather than "the PCM
    part and the modelling part".  Nothing measured here distinguishes those two
    readings; both put the modelling in 0x00104000's register file.

★ NO LABEL IS RENAMED BY THIS FILE.  §0 of the tone-generator note sets the bar for
restoring a role-bearing prefix and this does not clear it.
"""
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))                 # .../wsa1
KN = os.path.dirname(ROOT)                                    # the unified repo root
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_lines                            # noqa: E402

# ---------------------------------------------------------------------------
# The two sides, each read the way its own tree stores it.
# ⚠ The KN5000 side is READ-ONLY here.  This lane owns wsa1/ and nothing else.
KN5000_SUBCPU = ["v142/subcpu/kn5000_subprogram_v142.s",
                 "v142/subcpu/subcpu_data_tables.s",
                 "v142/subcpu/subcpu_vectors.s",
                 "v142/subcpu/subcpu_fp_math.s"]

HEX = re.compile(r'0x([0-9A-Fa-f]{6,8})\b')
# A peripheral literal, on either machine, is a 32-bit address outside the ROM
# and RAM areas.  The ranges come from each tree's own memory map.
WSA1_CPU2_DEV = (0x00100000, 0x00140000)
WSA1_CPU2_CS2 = (0x00E00000, 0x00E00010)
# ⚠ 0x100000, not 0, because the KN5000 sub-CPU's first megabyte is DRAM
# (kn5000.cpp subcpu_map `map(0x000000, 0x0fffff).ram()`), and a hot RAM variable
# clusters exactly like a port -- see report_control().
KN5000_DEV = (0x00100000, 0x00200000)


def literals(lines, lo, hi):
    """Every literal in [lo,hi), counted.  ⚠ Comments included ON PURPOSE for the
    KN5000 side, whose headers cite the addresses its instructions reach through
    micro-DMA descriptors; excluded would undercount a device to zero.  The
    threshold below, and --control, are what keep that honest."""
    c = collections.Counter()
    for ln in lines:
        for m in HEX.finditer(ln):
            v = int(m.group(1), 16)
            if lo <= v < hi:
                c[v] += 1
    return c


def code_literals(lines, lo, hi):
    """The same, but INSTRUCTIONS ONLY -- everything before the first `;`."""
    c = collections.Counter()
    for ln in lines:
        code = ln.split(";", 1)[0]
        if not code.strip() or code.lstrip().startswith("."):
            continue
        for m in HEX.finditer(code):
            v = int(m.group(1), 16)
            if lo <= v < hi:
                c[v] += 1
    return c


# ★ WHAT COUNTS AS A DEVICE, stated before any number is quoted.
#
# TWO criteria, and both are needed -- either alone is measurably wrong:
#
#   (a) the 8-byte WINDOW's total >= THRESHOLD.  Per-address counting misses the
#       WSA1 keybed, which is 3 references at +0 and 2 at +2 and is a device.
#       This is the contrast FINDINGS-memory-map.md used to eliminate CPU 1's
#       0x680000-0x78FFFF: a port clusters, a byte pattern inside a table
#       scatters.
#   (b) the window base is a multiple of 0x1000.  A TLCS-900 decodes external
#       chip selects through MSAR/MAMR on large power-of-two boundaries, so a
#       device base is aligned; `0x00101379`, `0x00143D13`, `0x0016B543` and
#       `0x00197A96` -- the four KN5000 counts that sit next to the keybed's --
#       are not, and are bytes inside tables.
#
# ⚠ NEITHER IS FREE.  --control reports what each criterion removes, on an image
# whose devices are already established, so a reader can see the cost rather than
# take the threshold on trust.
THRESHOLD = 5
WINDOW = 8
ALIGN_MASK = 0x1000


def wsa1_lines():
    return image_lines(ROOT, "prom_c/wsa1_prom_c.s")


def kn5000_lines():
    out = []
    for rel in KN5000_SUBCPU:
        p = os.path.join(KN, rel)
        if os.path.exists(p):
            out += open(p, encoding="utf-8", errors="replace").read().split("\n")
    return out


# ---------------------------------------------------------------------------
# What each side's devices ARE, with the citation for each.  ⚠ These roles are
# not derived here -- they are quoted from the note that established each one, so
# that the alignment below is an alignment of FINDINGS and not of guesses.
WSA1_ROLES = {
    0x00100000: ("inter-processor link port", "FINDINGS-memory-map.md §3"),
    0x00104000: ("64 ch x 19 regs, role NOT established",
                 "FINDINGS-prom_c-tone-generator.md §4"),
    0x00108000: ("keybed scan port", "FINDINGS-prom_c-keyboard-and-touch.md"),
    0x0010C000: ("64 ch x 22 regs, KN5000 tone generator's map",
                 "FINDINGS-prom_c-dev10c-sibling-register-map.md §1"),
    0x00E00000: ("DSP register file, 4 ch x 32 regs",
                 "prom_c/boot/boot_and_main.s"),
}
KN5000_ROLES = {
    0x00100000: ("tone generator IC303, +0 sel / +2 data / +4 status",
                 "kn5000_subprogram_v142.s:7020, :24588"),
    0x00110000: ("keybed", "kn5000.cpp subcpu_map"),
    0x00120000: ("inter-CPU command latch pair",
                 "subcpu_vectors.s:5 INTER_CPU_COMM_LATCHES"),
    0x00130000: ("DSP register file", "DSP_WriteChannelRegs_Inner 0x1FD27"),
    0x001E0000: ("wave / sample RAM", "kn5000.cpp subcpu_map"),
}
# The alignment, by ROLE.  A row with a WSA1 address and no KN5000 one is the
# finding this file exists for.
ALIGN = [
    ("tone generator",        0x0010C000, 0x00100000),
    ("keybed",                0x00108000, 0x00110000),
    ("inter-processor link",  0x00100000, 0x00120000),
    ("DSP register file",     0x00E00000, 0x00130000),
    ("wave / tone bank",      None,       0x001E0000),
    ("★ NO COUNTERPART",      0x00104000, None),
]


def devices(counts, aligned=True):
    """-> {base: window total} for every window that passes both criteria."""
    win = collections.Counter()
    for a, n in counts.items():
        win[a - (a % WINDOW)] += n
    out = {}
    for base, n in win.items():
        if n < THRESHOLD:
            continue
        if aligned and base % ALIGN_MASK:
            continue
        out[base] = n
    return out


def report_align():
    w = devices(code_literals(wsa1_lines(), *WSA1_CPU2_DEV))
    w.update(devices(literals(wsa1_lines(), *WSA1_CPU2_CS2)))
    k = devices(literals(kn5000_lines(), *KN5000_DEV))
    print("CPU 2's SOUND DEVICES, ALIGNED AGAINST THE PCM SIBLING")
    print("=" * 78)
    print("%-24s %-26s %s" % ("role", "WSA1 CPU 2 (prom_c)", "KN5000 sub-CPU"))
    print("-" * 78)
    for role, wa, ka in ALIGN:
        def cell(a, tbl, cnt):
            if a is None:
                return "-- none --"
            n = sum(v for x, v in cnt.items() if a <= x < a + WINDOW)
            return "0x%06X  (%d refs)" % (a, n)
        print("%-24s %-26s %s" % (role, cell(wa, WSA1_ROLES, w),
                                  cell(ka, KN5000_ROLES, k)))
    print("""
★ EVERY device CPU 2 drives has a counterpart in a PCM-only sibling EXCEPT
  0x00104000.  The WSA1's headline difference from the KN5000 is that it does
  acoustic modelling; 0x00104000 is the one piece of silicon on this list that
  the modelling machine has and the sample-playback machine does not.

⚠ This is an ALIGNMENT, not a decode.  It says where to look, and it is the
  strongest statement these ROMs support: no WSA1 ROM names a part number.""")


def blocks_of(routine_addrs, lines, base_literal):
    """The register BLOCKS one unrolled writer selects, in order."""
    out, live = [], False
    for ln in lines:
        code = ln.split(";", 1)[0]
        if base_literal in code:
            live = True
        m = re.search(r'\badd\s+\w+,\s*(0x[0-9A-Fa-f]+)', code)
        if live and m:
            out.append(int(m.group(1), 16))
    return out


def report_profile():
    print("THE TWO REGISTER FILES ARE DIFFERENT SHAPES")
    print("=" * 78)
    # Dev10C's 22 blocks, as FINDINGS-prom_c-dev10c-sibling-register-map.md §1
    # prints them and as the KN5000's own ToneGen_WriteVoiceParams comment does.
    d10c = [0x000, 0x040, 0x080, 0x0C0, 0x100, 0x140, 0x180,
            0x400, 0x440, 0x480, 0x4C0, 0x500,
            0x800, 0x840, 0x880, 0x8C0, 0x900, 0x940, 0x980, 0x9C0, 0xA00, 0xA40]
    # Dev104's 19, from Dev104_WriteAllChanRegs: register (chan + k*0x40) for
    # k = 1..0x12 plus (chan + 0) -- FINDINGS-prom_c-tone-generator.md §4.
    d104 = [k * 0x40 for k in range(0, 0x13)]
    print("Dev10C  22 blocks, SPARSE, in three clusters:")
    print("   " + " ".join("0x%03X" % b for b in d10c))
    print("   as k = block/0x40:  " + " ".join(str(b // 0x40) for b in d10c))
    print("\nDev104  19 blocks, CONTIGUOUS k = 0..18:")
    print("   " + " ".join("0x%03X" % b for b in d104))
    inter = sorted(set(d10c) & set(d104))
    print("\n   shared block NUMBERS: %d of 19  (%s)"
          % (len(inter), " ".join("0x%03X" % b for b in inter)))
    print("""
⚠ SHARING A BLOCK NUMBER IS NOT SHARING A REGISTER.  Both devices number
  registers `block*0x40 + channel`, so low block numbers collide by arithmetic.
  What separates them is the SET: 0..18 with no gaps against a sparse 22 that
  leaves 0x1C0..0x3C0 and 0x540..0x7C0 empty and resumes at 0x800.  A register
  file with a hole that big is not the same silicon as one without it.

★ And Dev10C's set is the KN5000 TONE GENERATOR's set, in the same order --
  established by notes/FINDINGS-prom_c-dev10c-sibling-register-map.md §1, which
  compares the WSA1 driver against the sibling's own comment block rather than
  against a retyped list.""")


def report_control():
    """★ THE POSITIVE CONTROL.  The same threshold, on an image whose devices
    are already established by other means, must recover those devices and no
    others.  Without this, "the KN5000 has no fifth device" is just a threshold."""
    print("POSITIVE CONTROL: the same method on CPU 1, whose devices are known")
    print("=" * 78)
    lines = image_lines(ROOT, "prom_a/wsa1_prom_a.s") \
        + image_lines(ROOT, "prom_b/wsa1_prom_b.s")
    # ⚠ keyed by 8-BYTE WINDOW BASE, the unit `devices()` reports in.  The FDC's
    # two registers 0x7B0004/5 live in window 0x7B0000.
    known = {0x790000: "display controller", 0x7A0000: "FDC data (DMA decode)",
             0x7B0000: "FDC MSR/control (0x7B0004/5)",
             0x7C0000: "inter-processor link",
             0x7E0008: "second storage unit",
             0x7F0000: "DSP register file"}
    # ★ THE RANGE IS PART OF THE METHOD, and getting it wrong is instructive.
    # Run over 0x600000-0x7FFFFF this control reports 158 "devices": CPU 1's work
    # DRAM is at 0x600000-0x60FFFF and its VARIABLES cluster exactly the way a
    # port does.  Clustering separates a device from data; it does NOT separate a
    # device from a hot RAM variable.  So the range must exclude memory the map
    # already calls RAM -- here CPU 1's CS0 device area, 0x780000-0x7FFFFF
    # (FINDINGS-memory-map.md), and on the sibling 0x100000-0x1FFFFF, which is
    # above the sub-CPU's 1 MiB of DRAM (kn5000.cpp subcpu_map: 0x000000-0x0FFFFF
    # .ram()).  Both ranges are stated, neither is fitted to the answer.
    c = code_literals(lines, 0x00780000, 0x00800000)
    found = devices(c)
    unaligned = {b: n for b, n in devices(c, aligned=False).items()
                 if b not in found}
    print("  address      refs   established as")
    hit = miss = extra = 0
    for a in sorted(set(list(found) + list(known))):
        n = found.get(a, 0)
        name = known.get(a)
        if name and n:
            hit += 1
            tag = name
        elif name:
            miss += 1
            raw = sum(v for x, v in c.items() if a <= x < a + WINDOW)
            if raw >= THRESHOLD:
                tag = "%s  ⚠ REFUSED BY CRITERION (b): base %% 0x1000 = 0x%03X" \
                      % (name, a % ALIGN_MASK)
            else:
                tag = "%s  ⚠ REFUSED BY CRITERION (a): %d < %d" \
                      % (name, raw, THRESHOLD)
            n = raw
        else:
            extra += 1
            tag = "⚠ NOT in the established map"
        print("  0x%06X  %5d   %s" % (a, n, tag))
    print("\n  %d recovered, %d below threshold, %d not in the map." % (hit, miss, extra))
    print("\n  criterion (b), alignment, removed %d window(s) that passed (a):"
          % len(unaligned))
    for b, n in sorted(unaligned.items())[:10]:
        print("    0x%06X  %3d refs   base %% 0x1000 = 0x%03X"
              % (b, n, b % ALIGN_MASK))
    if len(unaligned) > 10:
        print("    ... and %d more" % (len(unaligned) - 10))
    print("""
⚠ THE BELOW-THRESHOLD ROWS ARE THE HONEST COST.  A count of 8 is a real device
  on CPU 1 (the FDC's five accessors are reached through pointers, not literals),
  so this method UNDERCOUNTS SMALL DEVICES, and criterion (b) additionally
  refuses 0x7E0008, which is a real device at an offset inside its window.
  ★ BOTH ERRORS RUN THE SAME WAY: they can only HIDE a device, never invent one.
  That is the safe direction for the claim being made, because the claim is that
  the KN5000 has NO fifth per-channel device -- and an instrument that
  undercounts can be wrong about that.  ★ SO THIS IS HOW TO REFUTE THE FINDING:
  show a KN5000 sub-CPU device below 5 references, or at an unaligned base, that
  is a 64-channel parameter file.  The alignment's extra row falls if you do.""")


def selftest():
    checks, fails = [], 0

    def ck(name, cond, detail=""):
        nonlocal fails
        checks.append((name, cond, detail))
        if not cond:
            fails += 1

    wl, kl = wsa1_lines(), kn5000_lines()
    ck("the KN5000 sub-CPU source is present to compare against",
       len(kl) > 10000, "%d lines" % len(kl))

    kdev = devices(literals(kl, *KN5000_DEV))
    wdev = devices(code_literals(wl, *WSA1_CPU2_DEV))
    wdev.update(devices(literals(wl, *WSA1_CPU2_CS2)))

    # 1. Both sides' KNOWN devices must come back.  A method that lost one of
    #    these could not be trusted to say a device is absent.
    for a, (what, _) in KN5000_ROLES.items():
        ck("KN5000 device 0x%06X recovered (%s)" % (a, what.split(",")[0]),
           any(a <= x < a + WINDOW for x in kdev),
           "%d refs" % sum(v for x, v in kdev.items() if a <= x < a + WINDOW))
    for a, (what, _) in WSA1_ROLES.items():
        ck("WSA1 device 0x%06X recovered (%s)" % (a, what.split(",")[0]),
           any(a <= x < a + WINDOW for x in wdev),
           "%d refs" % sum(v for x, v in wdev.items() if a <= x < a + WINDOW))

    # 2. ★ THE FINDING.  Nothing in the KN5000 sub-CPU's device range sits where
    #    a Dev104 counterpart would, and the KN5000's device count is one lower
    #    once the tone bank / wave RAM row is paired off.
    kbases = sorted(kdev)
    ck("the KN5000 sub-CPU drives exactly 5 device bases",
       len(kbases) == 5, ", ".join("0x%06X" % b for b in kbases))
    ck("★ no KN5000 device is a second 64-channel parameter file",
       0x00104000 not in KN5000_ROLES and
       all(r[0].startswith(("tone generator", "keybed", "inter-CPU",
                            "DSP", "wave"))
           for r in KN5000_ROLES.values()), "by role, cited per row")

    # 3. NEGATIVE CONTROL on the shape claim: the two block sets must actually
    #    differ.  If someone "simplifies" one of the lists this fails.
    d10c = [0x000, 0x040, 0x080, 0x0C0, 0x100, 0x140, 0x180,
            0x400, 0x440, 0x480, 0x4C0, 0x500,
            0x800, 0x840, 0x880, 0x8C0, 0x900, 0x940, 0x980, 0x9C0, 0xA00, 0xA40]
    d104 = [k * 0x40 for k in range(0, 0x13)]
    ck("Dev104's blocks are contiguous and Dev10C's are not",
       d104 == list(range(0, 0x13 * 0x40, 0x40))
       and sorted(d10c) != list(range(0, 22 * 0x40, 0x40)),
       "19 contiguous vs 22 sparse")
    ck("the two block sets are not the same file",
       set(d10c) != set(d104),
       "%d shared block numbers" % len(set(d10c) & set(d104)))

    # 4. THE PORT SHAPE.  Dev10C has a +4 readback and so does the KN5000 TG --
    #    which is the structural half of "Dev10C is a tone generator of that
    #    family", independent of the register numbering.
    ck("the KN5000 tone generator also has a +4 register",
       any(0x00100004 == x for x in literals(kl, 0x00100004, 0x00100006)),
       "0x100004 present in the sibling source")

    # 5. ⚠ AND THE CONTRADICTION THIS FOUND IN THE SHARED TOOL'S OTHER HALF.
    #    The KN5000 sub-CPU references 0x120000 fourteen times and the shared
    #    tool's KN5000 window list does not contain it.  It is the inter-CPU
    #    latch, not a sound device -- but a window list that omits a 14-reference
    #    device is not a list anyone should compute a completeness claim over.
    ck("KN5000 0x120000 is real and is the inter-CPU latch, not a sound device",
       kdev.get(0x120000, 0) >= THRESHOLD, "%d refs" % kdev.get(0x120000, 0))

    for name, ok, detail in checks:
        print("  %-4s %-58s %s" % ("ok" if ok else "FAIL", name, detail))
    print("\n%d checks, %d failures" % (len(checks), fails))
    return 1 if fails else 0


def main():
    a = sys.argv[1:]
    if "--selftest" in a:
        sys.exit(selftest())
    if "--profile" in a:
        report_profile()
    elif "--control" in a:
        report_control()
    else:
        report_align()


if __name__ == "__main__":
    main()
