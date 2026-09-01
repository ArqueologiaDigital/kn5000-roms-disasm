#!/usr/bin/env python3
"""Is the SOUND SUBSYSTEM code fully disassembled, in both machines?

QUESTION IT ANSWERS: Felipe's goal is full disassembly coverage of every routine
that talks to the sound chips -- the tone generator, the DSPs and the acoustic
modelling LSI -- in the KN5000 and the SX-WSA1R.  Semantics are optional; COVERAGE
is the goal.  So this tool answers three things and nothing else:

  1. WHERE is the sound code?  Every instruction naming a sound-chip window, and
     the routine that contains it.
  2. Is any of it STILL `.incbin`?  A routine that falls off the end of converted
     text into an unconverted span is the debt this goal exists to clear.
  3. WHAT crosses the boundary?  Which chip register each site writes or reads --
     the raw material for understanding parts with no datasheet.

RUN:  python3 notes/sound/sound_coverage.py              # both machines
      python3 notes/sound/sound_coverage.py --machine kn5000
      python3 notes/sound/sound_coverage.py --routines   # per-routine census
      python3 notes/sound/sound_coverage.py --registers  # what is sent to each chip
      python3 notes/sound/sound_coverage.py --selftest

WHAT IS ESTABLISHED (2026-09-01, first pass):

  * The SOUND-BEARING IMAGES ARE TERRITORIALLY COMPLETE.  KN5000 `v142/subcpu`,
    KN5000 `subcpu/boot` and WSA1 `prom_c` contain **zero** `.incbin` -- every
    byte is source.  Those three hold essentially all of the sound code.
  * ZERO unconverted spans sit inside or immediately after any routine that
    touches a sound chip, in either machine.
  * The remaining unconverted territory is elsewhere (KN5000 maincpu UI/graphics,
    WSA1 prom_a/prom_b) and has ALREADY BEEN ADJUDICATED by the reachability
    tools: KN5000 maincpu's 176 STRONG-with-evidence bytes were all refused as
    data, and WSA1's final 17 likewise.  Unreached, unconverted bytes that were
    examined and found to be data cannot be hiding sound routines.

⚠ TWO LIMITS OF THIS TOOL, BOTH MEASURED, NEITHER PAPERED OVER:

  1. IT UNDERCOUNTS REGISTER-INDIRECT ACCESS.  The WSA1 reaches its tone
     generator by loading the base (`ld xbc,0x0010C000` at prom_c 0xFAC125) and
     then using displacements, so accesses to +2 (data) and +4 (status) never
     name 0x10C002 or 0x10C004 and are invisible to a literal scan.  That is why
     the WSA1 rows read TG_DATA 0 and TG_STATUS 0 while the driver maps both.
     The ROUTINE is still found, via the base load, so COVERAGE figures hold;
     the per-register breakdown does not.
  2. A BYTE-PATTERN SEARCH FOR SOUND CODE IN UNCONVERTED SPANS DOES NOT WORK,
     and the null says so.  Searching 11,155,461 unconverted bytes for the
     little-endian encodings of the five KN5000 sound addresses gives 272 span
     hits; the same search for five CONTROL addresses of identical shape that no
     sound chip decodes (0x150000, 0x160000, 0x170000, 0x190000, 0x1A0000) gives
     188.  A 1.45x ratio is noise in zero-heavy data.  ★ Do not reintroduce that
     search without its null.

★ THE WINDOWS BELOW ARE THE HARDWARE CONTRACT, taken from the MAME drivers'
address maps, which were themselves derived from these ROMs.  They are the one
input a reader must check: if a window is wrong, every figure here is wrong in
the same direction, and nothing else in the tool can notice.
"""
import os, re, sys, collections

HERE = os.path.dirname(os.path.abspath(__file__))
KN   = os.path.dirname(os.path.dirname(HERE))          # the unified repo root
WSA  = os.path.join(KN, "wsa1")

# (name, first, last, what it is).  Sources: kn5000.cpp subcpu_map, wsa1.cpp cpu2_map.
MACHINES = {
    "kn5000": dict(root=KN, dirs=["v142", "subcpu", "v10/maincpu/audio"], windows=[
        ("TG_ADDR",   0x100000, 0x100001, "tone generator: register-address latch (w) / active-voice bitmap (r)"),
        ("TG_DATA",   0x100002, 0x100003, "tone generator: register data"),
        ("TG_KBD",    0x110000, 0x110003, "tone generator: keybed data and status"),
        ("DSP_ADDR",  0x130000, 0x130001, "DSP: register address"),
        ("DSP_DATA",  0x130002, 0x130003, "DSP: register data"),
        ("WAVE_RAM",  0x1E0000, 0x1EFFFF, "waveform / sample RAM"),
    ]),
    "wsa1": dict(root=WSA, dirs=["prom_a", "prom_b", "prom_c"], windows=[
        ("TG_ADDR",   0x10C000, 0x10C001, "tone generator: address register (64 voices)"),
        ("TG_DATA",   0x10C002, 0x10C003, "tone generator: data register"),
        ("TG_STATUS", 0x10C004, 0x10C005, "tone generator: status read-back"),
        ("SYNTH2",    0x104000, 0x104003, "second synthesis device: address / data"),
        ("KEYBED",    0x108000, 0x108003, "keybed data and status"),
    ]),
}

LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
INCBIN = re.compile(r'^\s*\.incbin\b')
HEX    = re.compile(r'0x([0-9A-Fa-f]{4,8})\b')


def sources(m):
    out = []
    for d in m["dirs"]:
        base = os.path.join(m["root"], d)
        for dp, _dirs, fns in os.walk(base):
            if os.sep + ".git" in dp:
                continue
            for fn in sorted(fns):
                # ⚠ dotfiles: asm_source writes expansion caches as .image-*.s inside
                # the tree.  Counting them doubles every figure -- see the 2026-09-01
                # incident in notes/llvm/.
                if fn.startswith(".") or not fn.endswith(".s"):
                    continue
                out.append(os.path.join(dp, fn))
    return out


def census(m):
    """-> sites[], per_routine{}, incbin_after_site[]"""
    wins = m["windows"]
    sites, per_routine, risky = [], collections.Counter(), []
    for path in sources(m):
        cur = None
        pending = None          # a routine that had a site and has not ended yet
        for n, line in enumerate(open(path, errors="replace"), 1):
            lm = LABEL.match(line)
            if lm:
                cur = lm.group(1)
                pending = None
            if INCBIN.match(line):
                # ★ THE COVERAGE QUESTION: unconverted bytes inside, or immediately
                # after, a routine known to touch a sound chip.
                if pending:
                    risky.append((path, n, pending))
                continue
            code = line.split(";")[0]
            for h in HEX.findall(code):
                v = int(h, 16)
                for name, lo, hi, _what in wins:
                    if lo <= v <= hi:
                        sites.append((path, n, cur or "?", name, v, code.strip()))
                        per_routine[cur or "?"] += 1
                        pending = cur
    return sites, per_routine, risky


def report(key, m):
    sites, per_routine, risky = census(m)
    bywin = collections.Counter(s[3] for s in sites)
    print(f"\n=== {key.upper()} ===")
    print(f"  sound-chip sites : {len(sites):,}")
    print(f"  routines touching a sound chip : {len([r for r in per_routine if r != '?']):,}")
    for name, lo, hi, what in m["windows"]:
        print(f"    {name:<10} {bywin.get(name,0):5d}  0x{lo:06X}-0x{hi:06X}  {what}")
    print(f"  ★ UNCONVERTED (.incbin) inside/after a sound routine: {len(risky)}")
    for path, n, rt in risky[:8]:
        print(f"      {os.path.relpath(path, m['root'])}:{n}  in {rt}")
    return sites, per_routine, risky


def main():
    only = None
    if "--machine" in sys.argv:
        only = sys.argv[sys.argv.index("--machine") + 1]
    if "--selftest" in sys.argv:
        f = 0
        def ck(d, c, extra=""):
            nonlocal f
            print(("  ok   " if c else "  FAIL ") + d + (("   " + extra) if extra else ""))
            f += not c
        for key, m in MACHINES.items():
            ck(f"{key}: its source dirs exist", all(
                os.path.isdir(os.path.join(m["root"], d)) for d in m["dirs"]))
            s, pr, _r = census(m)
            ck(f"{key}: the tone generator is referenced at all", any(
                x[3].startswith("TG") for x in s), f"{len(s)} site(s) total")
            ck(f"{key}: sites resolve to NAMED routines, not just '?'",
               len([r for r in pr if r != "?"]) > 0)
        # a dotfile control: the expansion caches must never be counted
        wsa = MACHINES["wsa1"]
        ck("expansion caches (.image-*.s) are excluded from the walk",
           not any(os.path.basename(p).startswith(".") for p in sources(wsa)))
        print(f"\n{4*2} checks, {f} failures")
        return 1 if f else 0
    for key, m in MACHINES.items():
        if only and key != only:
            continue
        sites, per_routine, risky = report(key, m)
        if "--routines" in sys.argv:
            print("  busiest routines:")
            for r, c in per_routine.most_common(15):
                print(f"    {c:5d}  {r}")
        if "--registers" in sys.argv:
            print("  distinct chip addresses touched:")
            for v, c in collections.Counter(s[4] for s in sites).most_common(12):
                print(f"    0x{v:06X}  {c:5d} site(s)")
    return 0

sys.exit(main())
