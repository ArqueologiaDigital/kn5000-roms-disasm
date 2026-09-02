#!/usr/bin/env python3
r"""THREE-WAY SPLIT for the NAKA-widget / shared-include lane (v10 maincpu).

QUESTION ANSWERED
-----------------
For every byte this lane owns, is it

  (a) REAL CODE   -- executed, so instructions are the right spelling;
  (b) TYPEABLE    -- structured data that a real directive (`.asciz` /
                     `aligned_string` / `.long`) would state correctly, but
                     which the tree currently writes as raw `.byte` *or* as
                     fake instructions;
  (c) BYTES-OK    -- a genuine byte-valued table, already correct as `.byte`?

and, orthogonally, HOW IS IT SPELLED TODAY?  The quadrant this tool exists to
expose is **data spelled as instructions**.  Re-assembling a wrong reading
reproduces the same bytes, so `make gate-all` cannot object to it in either
direction; only an independent argument can.

THE INDEPENDENT ARGUMENT
------------------------
  T1  REFERENCE KIND.  A label names CODE only if some line in the v10 tree
      transfers control to it (`call/calr/jp/jr/jrl/djnz`).  A label that is
      only ever address-taken (`.long L`, `ld xrr,L`) names DATA.  References
      from inside a candidate data region do not count -- a misframe must not
      be allowed to cite itself.
  T2  BYTE GRAMMAR.  Re-derive the region's shape FROM THE BYTES, ignoring
      what the source says, with a three-token grammar:
        STR   >=1 chars from a restricted alphabet, NUL-terminated, plus the
              0xFF that `aligned_string` (= `.asciz` + `.p2align 1,0xff`)
              emits when the NUL lands on an odd address;
        PTR   a 4-aligned u32 inside a pointer domain this image really uses;
        BYTE  anything else.
      Report the fraction of the region STR and PTR explain.

CONTROLS -- both directions, because a test that cannot fail is not a test
-------------------------------------------------------------------------
  C1  NEGATIVE, on the data.  Byte-shuffle each region and re-run T2.  A
      shuffle keeps the byte histogram and destroys the ordering, so any
      structure score that survives it was never about structure.
  C2  POSITIVE, on known code.  Run the identical pipeline over regions T1
      proves are `call`ed.  If those score as data, the data verdicts here
      are worthless and the classifier is just saying "data" to everything.

WHAT THE CONTROLS ACTUALLY SAY -- including where one of them is WEAK
---------------------------------------------------------------------
C2 separates cleanly and in the right direction: known-code regions score
STR 0.00-0.12 / PTR 0.00-0.08 and T1 finds 5..652 control-transfer targets in
each, while every region in this lane has ZERO.  The pipeline can say "code".

C1 separates for PTR (real 0.11-0.28 vs shuffled 0.00-0.12, no overlap) but
NOT for STR.  On naka_property_descriptors.s the shuffle actually scores
HIGHER than the real bytes (0.48 vs 0.44).  That is not noise, it is the
control doing its job: in a region that is mostly printable ASCII, a shuffle
is still mostly printable ASCII, so "printable-then-NUL" is a property of the
byte HISTOGRAM, not of the ordering.

**Therefore: do not convert a run to strings on the STR score.**  The
evidence that survives a null is the one used for the chord table below --
does an independent pointer table land on the run's string BOUNDARIES?  A
shuffle destroys that immediately (64/64 -> 0/64).  STR is reported here as
a triage hint only, and is labelled as such rather than deleted, because a
number whose weakness is documented is worth more than one quietly dropped.

WHAT THIS TOOL FOUND (2026-09-02), and how to re-check it
---------------------------------------------------------
`--chordtable` runs the sharpest single measurement in the lane: the
extension_data.s chord-type pointer table is framed in the tree at 0xED0008
with 26 entries, and NOT ONE of those 26 u32 values is even inside the ROM
region the strings live in.  Re-framed at 0xECFF6A with 64 entries, 64/64
point exactly at the first byte of a NUL-terminated string, and every phase
shift of +/-1..3 scores 0/64.  A wrong START OFFSET framing fake records is
the hazard the lane brief names; this is one, in the tree, today.

RUN
    make llvm-all                                        # generated/*.bin first
    python3 scripts/analysis/naka_lane_split.py             # the split
    python3 scripts/analysis/naka_lane_split.py --controls  # C1 and C2
    python3 scripts/analysis/naka_lane_split.py --chordtable
    python3 scripts/analysis/naka_lane_split.py --runs v10/maincpu/extensions/extension_data.s

Address<->line mapping is delegated to scripts/analysis/address_line_map.py,
whose --selftest asserts the marked mirror still assembles byte-identically to
original_ROMs/kn5000_v10_program.rom.  Its dump is cached in
scripts/analysis/.amap_v10.json (untracked; delete it to rebuild).
"""
import json
import os
import random
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM = os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom")
BASE = 0xE00000
AMAP_CACHE = os.path.join(ROOT, "scripts/analysis/.amap_v10.json")

TARGETS = [
    "v10/maincpu/includes/gui_format_strings.s",
    "v10/maincpu/includes/gui_display_struct_data.s",
    "v10/maincpu/msp_factory_defaults.s",
    "v10/maincpu/extensions/extension_data.s",
    "v10/maincpu/ui_widgets/control_menu_screens.s",
    "v10/maincpu/ui_widgets/naka_debug_proc_names.s",
    "v10/maincpu/ui_widgets/naka_direct_play_dispatch.s",
    "v10/maincpu/ui_widgets/naka_direct_play_property_tables.s",
    "v10/maincpu/ui_widgets/naka_effects_eq_dispatch.s",
    "v10/maincpu/ui_widgets/naka_property_descriptors.s",
    "v10/maincpu/ui_widgets/naka_screen_dispatch.s",
    "v10/maincpu/ui_widgets/naka_sound_technichord_dispatch.s",
    "v10/maincpu/ui_widgets/naka_widget_desc_dispatch.s",
]

# Regions this tree already agrees are executable, used as the POSITIVE control.
KNOWN_CODE = [
    "v10/maincpu/shared/boot_routines.s",
    "v10/maincpu/shared/vga_io.s",
    "v10/maincpu/boot/system_handlers.s",
    "v10/maincpu/midi/sysex_routines.s",
]

TYPED = ("long", "word", "dword", "hword", "short", "ascii", "asciz",
         "zero", "fill", "incbin", "p2align", "align", "space")
LBL_RE = re.compile(r'^\s*([A-Za-z_.$][\w.$]*):')
DIR_RE = re.compile(r'^\s*\.(\w+)')
XFER_RE = re.compile(r'^\s*(call|calr|jp|jr|jrl|djnz)\b', re.I)
IDENT_RE = re.compile(r'[A-Za-z_.$][\w.$]*')

# The pointer domains this image actually uses: program ROM, and the DRAM
# window the NAKA widget records bind their live state into.
PTR_DOMAINS = ((0x00E00000, 0x00FFFFFF), (0x00030000, 0x000FFFFF))

# Alphabet the NAKA / chord / parameter strings are drawn from.  Deliberately
# NOT "all printable": `20 20 20 20` would otherwise read as a string and the
# grammar would explain padding as structure.
STR_ALPHA = set(range(0x20, 0x7F))


# ---------------------------------------------------------------- address map
def address_map():
    if not os.path.exists(AMAP_CACHE):
        subprocess.check_call([sys.executable,
                               os.path.join(ROOT, "scripts/analysis/address_line_map.py"),
                               "--dump", AMAP_CACHE])
    per = {}
    for e in json.load(open(AMAP_CACHE)):
        per.setdefault(e["src"], {})[e["line"]] = e["addr"]
    return per


def rom():
    return open(ROM, "rb").read()


# ------------------------------------------------------------------ line kind
def line_kind(text):
    """RAW_BYTE | RAW_INSTR | TYPED | INCLUDE | LABEL_ONLY | NONE, + label."""
    lab = LBL_RE.match(text)
    label = lab.group(1) if lab else None
    body = text[lab.end():] if lab else text
    body = body.split(";")[0].strip()
    if not body:
        return ("LABEL_ONLY" if label else "NONE"), label
    d = DIR_RE.match(body)
    if d:
        n = d.group(1)
        if n == "byte":
            return "RAW_BYTE", label
        if n == "include":
            return "INCLUDE", label      # its bytes belong to the OTHER file
        if n in TYPED:
            return "TYPED", label
        return "NONE", label             # .equ/.set/.globl ... emit nothing
    if body.split()[0] in ("aligned_string", "naka_header"):
        return "TYPED", label
    return "RAW_INSTR", label


def scan_file(path, amap):
    """[(lineno, addr, size, kind, label, text)] in address order."""
    lines = open(os.path.join(ROOT, path), encoding="latin-1").read().split("\n")
    marked = sorted(amap.get(path, {}).items())
    out = []
    for i, (ln, addr) in enumerate(marked):
        nxt = marked[i + 1][1] if i + 1 < len(marked) else addr
        text = lines[ln - 1]
        kind, label = line_kind(text)
        out.append((ln, addr, nxt - addr, kind, label, text))
    return out


# ------------------------------------------------------------------ T1 refkind
def reference_kinds(labels, exclude):
    """label -> set of {'XFER','PTR','OTHER'}, gathered over the whole v10 tree.
    `exclude` is the set of source files whose own lines may not vote (a
    misframe must not be allowed to cite itself)."""
    kinds = {l: set() for l in labels}
    for dp, _dn, fn in os.walk(os.path.join(ROOT, "v10/maincpu")):
        for f in sorted(fn):
            if not f.endswith(".s"):
                continue
            p = os.path.join(dp, f)
            selfcite = os.path.relpath(p, ROOT) in exclude
            for line in open(p, encoding="latin-1"):
                s = line.split(";")[0]
                hits = set(IDENT_RE.findall(s)) & labels
                if not hits:
                    continue
                m = LBL_RE.match(s)
                body = s[m.end():] if m else s
                if m and m.group(1) in hits and m.group(1) not in IDENT_RE.findall(body):
                    hits -= {m.group(1)}         # the bare definition line
                if not hits:
                    continue
                if XFER_RE.match(body.strip()):
                    if not selfcite:
                        for h in hits:
                            kinds[h].add("XFER")
                elif re.match(r'\s*\.(long|word|dword)\b', body):
                    for h in hits:
                        kinds[h].add("PTR")
                else:
                    for h in hits:
                        kinds[h].add("OTHER")
    return kinds


# ------------------------------------------------------------------ T2 grammar
def grammar(b, base_addr):
    """Greedy STR / PTR / BYTE parse of b.  Returns (n_str, n_ptr, n_byte)."""
    i, n = 0, len(b)
    ns = np_ = nb = 0
    while i < n:
        # STR: >=1 alphabet chars then NUL, plus aligned_string's 0xff filler.
        j = i
        while j < n and b[j] in STR_ALPHA:
            j += 1
        if j > i and j < n and b[j] == 0x00:
            j += 1
            if (base_addr + j) % 2 and j < n and b[j] == 0xFF:
                j += 1
            ns += j - i
            i = j
            continue
        # PTR: 4-aligned u32 in a real pointer domain.
        if (base_addr + i) % 4 == 0 and i + 4 <= n:
            v = int.from_bytes(b[i:i + 4], "little")
            if any(lo <= v <= hi for lo, hi in PTR_DOMAINS):
                np_ += 4
                i += 4
                continue
        nb += 1
        i += 1
    return ns, np_, nb


# ------------------------------------------------------------------- the split
def split_file(path, amap, romb, refkinds):
    rows = scan_file(path, amap)
    if not rows:
        return None
    tally = {"RAW_BYTE": 0, "RAW_INSTR": 0, "TYPED": 0}
    own = 0
    lo = rows[0][1]
    hi = rows[-1][1]
    for _ln, addr, size, kind, _label, _text in rows:
        if kind == "INCLUDE" or size == 0:
            continue
        if kind in tally:
            tally[kind] += size
            own += size
    ns, np_, nb = grammar(romb[lo - BASE:hi - BASE], lo)
    tot = max(1, ns + np_ + nb)
    labels = {r[4] for r in rows if r[4]}
    xfer = sorted(l for l in labels if "XFER" in refkinds.get(l, ()))
    return {"path": path, "lo": lo, "hi": hi, "span": hi - lo, "own": own,
            "raw_byte": tally["RAW_BYTE"], "raw_instr": tally["RAW_INSTR"],
            "typed": tally["TYPED"], "labels": len(labels),
            "xfer": xfer, "str": ns / tot, "ptr": np_ / tot, "byte": nb / tot,
            "blob": romb[lo - BASE:hi - BASE]}


def verdict(r):
    if r["xfer"]:
        return "a-CODE"
    if r["str"] + r["ptr"] >= 0.50:
        return "b-TYPEABLE"
    return "c-BYTES-OK"


# --------------------------------------------------------------- the chordtable
def chordtable(romb):
    """The sharpest measurement in this lane -- see the module docstring."""
    def u32(a):
        return int.from_bytes(romb[a - BASE:a - BASE + 4], "little")

    def str_start(v):
        p = v - BASE
        if not (0 <= p < len(romb)):
            return False
        j = p
        while j < len(romb) and romb[j] in STR_ALPHA:
            j += 1
        return j > p and j < len(romb) and romb[j] == 0x00

    print("EXTENSION_DATA CHORD-TYPE POINTER TABLE -- which framing is real?\n")
    print("  %-34s %6s %8s %10s" % ("framing", "n", "in-ROM", "at str start"))
    for name, start, cnt in (("tree, extension_data.s head", 0xED0008, 26),
                             ("proposed  (0xECFF6A, 64)", 0xECFF6A, 64)):
        vals = [u32(start + 4 * i) for i in range(cnt)]
        inrom = sum(1 for v in vals if 0xED0000 <= v <= 0xED0400)
        ss = sum(1 for v in vals if str_start(v))
        print("  %-34s %6d %8d %10d" % (name, cnt, inrom, ss))
    print("\n  NULL -- the same 64-entry read at every nearby phase:")
    for sh in (-3, -2, -1, 1, 2, 3):
        vals = [u32(0xECFF6A + sh + 4 * i) for i in range(64)]
        print("    phase %+d: %2d/64 at a string start" %
              (sh, sum(1 for v in vals if str_start(v))))
    print("\n  A wrong START OFFSET frames fake records indefinitely and the")
    print("  byte gate cannot object.  Only this kind of two-sided count can.")


# --------------------------------------------------------------------- reports
def show_runs(path, amap, romb, limit=40):
    rows = scan_file(path, amap)
    runs, cur = [], None
    for _ln, addr, size, kind, label, _text in rows:
        if kind == "INCLUDE":
            cur = None
            continue
        if kind in ("RAW_BYTE", "RAW_INSTR") and size and not label:
            if cur is None:
                cur = [addr, 0]
            cur[1] += size
        else:
            if cur:
                runs.append(tuple(cur))
            cur = [addr, size] if (kind in ("RAW_BYTE", "RAW_INSTR") and size) else None
    if cur:
        runs.append(tuple(cur))
    import collections
    hist = collections.Counter(n for _a, n in runs)
    print("%s: %d raw runs, %d bytes" % (path, len(runs), sum(n for _a, n in runs)))
    print("  run-length histogram (top 12): %s" % hist.most_common(12))
    for a, n in runs[:limit]:
        b = romb[a - BASE:a - BASE + n]
        ns, np_, nb = grammar(b, a)
        print("  0x%06X %4dB str=%3d ptr=%3d byte=%3d  |%s|" %
              (a, n, ns, np_, nb,
               "".join(chr(c) if 32 <= c < 127 else "." for c in b[:48])))


def main():
    args = sys.argv[1:]
    romb = rom()
    if "--chordtable" in args:
        chordtable(romb)
        return 0
    amap = address_map()
    if "--runs" in args:
        show_runs(args[args.index("--runs") + 1], amap, romb)
        return 0

    all_labels = set()
    for p in TARGETS:
        for line in open(os.path.join(ROOT, p), encoding="latin-1"):
            m = LBL_RE.match(line)
            if m:
                all_labels.add(m.group(1))
    refkinds = reference_kinds(all_labels, set(TARGETS))

    hdr = ("file", "own B", "raw.byte", "rawinstr", "typed", "STR", "PTR",
           "BYTE", "verdict")
    print("%-40s %8s %8s %8s %8s %5s %5s %5s  %s" % hdr)
    results = []
    for p in TARGETS:
        r = split_file(p, amap, romb, refkinds)
        if r is None:
            print("%-40s      -- NOT IN THE BUILD (0 address-map entries): this "
                  "file emits nothing" % os.path.basename(p))
            continue
        results.append(r)
        print("%-40s %8d %8d %8d %8d %5.2f %5.2f %5.2f  %s%s" %
              (os.path.basename(p), r["own"], r["raw_byte"], r["raw_instr"],
               r["typed"], r["str"], r["ptr"], r["byte"], verdict(r),
               (" [" + ",".join(r["xfer"][:3]) + "]") if r["xfer"] else ""))
    print("-" * 110)
    print("%-40s %8d %8d %8d %8d" %
          ("TOTAL in the build", sum(r["own"] for r in results),
           sum(r["raw_byte"] for r in results),
           sum(r["raw_instr"] for r in results),
           sum(r["typed"] for r in results)))

    if "--controls" in args:
        print("\nC1  NEGATIVE CONTROL: byte-shuffle the region, re-run T2.")
        print("    %-38s %13s %13s" % ("region", "STR real/shuf", "PTR real/shuf"))
        rnd = random.Random(20260902)
        for r in results:
            sh = bytearray(r["blob"])
            rnd.shuffle(sh)
            s2, p2, _ = grammar(bytes(sh), r["lo"])
            t2 = max(1, len(sh))
            print("    %-38s %5.2f /%5.2f %5.2f /%5.2f" %
                  (os.path.basename(r["path"]), r["str"], s2 / t2,
                   r["ptr"], p2 / t2))

        print("\nC2  POSITIVE CONTROL: the identical pipeline over KNOWN CODE.")
        for p in KNOWN_CODE:
            if not os.path.exists(os.path.join(ROOT, p)):
                continue
            labs = set()
            for line in open(os.path.join(ROOT, p), encoding="latin-1"):
                m = LBL_RE.match(line)
                if m:
                    labs.add(m.group(1))
            r = split_file(p, amap, romb, reference_kinds(labs, set()))
            if r:
                print("    %-38s own=%6dB STR=%.2f PTR=%.2f xfer_labels=%4d -> %s" %
                      (os.path.basename(p), r["own"], r["str"], r["ptr"],
                       len(r["xfer"]), verdict(r)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
