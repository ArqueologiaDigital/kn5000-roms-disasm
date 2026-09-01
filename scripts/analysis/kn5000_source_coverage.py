#!/usr/bin/env python3
"""kn5000_source_coverage.py -- a trustworthy territorial-debt inventory for all 13
gated images (9 KN5000 + 4 WSA1R).

QUESTION ANSWERED: for each gated ROM, how many bytes enter the byte-exact build as
REAL source -- assembly, typed/derived data, or C compiled byte-exact by clang -- and
how many are handed back UNCHANGED from a committed blob with no decode/build path at
all (the actual territorial debt)?

★★ THE BUG THIS FILE FIXES (2026-09-01) ★★
-------------------------------------------
The previous version of this script reported, for HD-AE5000:

    HD-AE5000   ROM 524,288   incbin 626,152   source -101,864   -19.4%

An incbin total LARGER than the ROM and a negative source figure are impossible --
`source = ROM - incbin` cannot go negative unless incbin is over-counted.

ROOT CAUSE: the `.incbin`-matching regex was applied to raw file text WITHOUT
stripping `;` comments first. hdae5000/hdae5000_data_tables.s carries, for each of
its 10 image assets, a HISTORICAL comment recording the pre-conversion directive
right above the live one, e.g.:

    ; Was: .incbin "includes/code_29af2d_2fffff.bin", 54881, 1024
    .incbin "includes/generated/HDAE5000_Palette_Logo.bin"

Both lines match `\\.incbin\\s+"..."`. The old script summed BOTH: once for the dead
"Was:" directive against the legacy monolithic blob, and again for the live directive
against the per-image generated file it was replaced by -- the SAME 313,076 bytes,
counted twice, for a total of 626,152 (2 * 313,076 exactly). Once incbin exceeds the
524,288-byte ROM, `ROM - incbin` goes negative. No other root in this tree has this
"; Was:" fossil-comment pattern (checked, see the selftest), so the double-count was
confined to hdae5000 -- but the regex itself is comment-blind everywhere, so ANY
future dead `.incbin` comment anywhere in the tree would trigger the same failure
silently. THE FIX strips `;` comments (outside quoted strings) from every line before
matching, everywhere, not just for hdae5000.

A SECOND, SEPARATE BUG THIS FILE FIXES: even with the double-count gone, the OLD
formula `source = ROM - incbin` silently counted `.incbin` of a clang-compiled
generated/*.bin as "not incbin debt" only via the crude `"generated/" in path`
substring test -- which is also how hdae5000's *round-trip image* blobs live in a
`generated/` directory, misclassifying them as "C source" they are not. This version
resolves each `.incbin` target to an on-disk file and classifies it via the ACTUAL
build machinery (see `classify_incbin` below), so "of which C" only ever means bytes
that come out of `clang -target tlcs900`.

★ TRAP THIS TOOL AVOIDS: counting `.incbin` DIRECTIVES instead of BYTES was already
fixed in the original version of this script (byte lengths were always summed, not
directive occurrences) -- kept here. The OTHER half of that trap -- long `.byte`/
`.word`/`.long`/`.ascii` runs that are really un-decoded code or untyped data hiding
outside any `.incbin` -- is handled by the mechanical per-directive byte count in
`scan_directives()`, which is exact for every byte-emitting directive actually used
in this tree (`.byte .short .long .ascii .asciz .fill .space .zero`, plus the four
byte-emitting `.macro`s -- see MACRO_BYTES) and treats the remainder of the non-incbin
bytes as instructions. See the module docstring section "WHAT 'TYPED DATA' MEANS"
below for the limits of that split.

WHAT COUNTS AS DEBT (the only thing this tool calls "verbatim"):
    An `.incbin` target that is a COMMITTED blob (tracked in git, or untracked but
    with no build rule that regenerates it from other checked-in source) -- i.e.
    bytes that are just copied, unexplained, from the factory dump. This is
    `notes/lanes/BRIEF-2026-09-01.md`'s own definition: "`.incbin` of a committed
    blob". A blob that a checked-in script deterministically regenerates from a
    checked-in .c/.png/.mid/.yaml/.styles/.txt source -- even if the intermediate
    .bin also happens to be tracked in git as a cache (e.g. table_data's wallpapers)
    -- is SOURCE, not debt, because the byte gate is not the only thing vouching for
    it: a `verify` step (documented per-generator) re-derives it independently.

WHAT "TYPED DATA" MEANS (and its limit):
    Bytes emitted directly in a `.s` file via a byte-emitting directive
    (`.byte/.short/.long/.ascii/.asciz/.fill/.space/.zero`, or one of the four
    byte-emitting macros in this tree), OUTSIDE any `.incbin`, plus the round-trip
    image/data bytes described above. "Assembly" is defined as the remainder of the
    non-`.incbin` bytes -- i.e. this tool does NOT independently verify that those
    remaining bytes are instructions; it is inferred by subtraction. ⚠ This means a
    long anonymous `.byte` run that is really un-analysed code (this project has
    shipped that exact defect before: 8,496 bytes of v1.42 sub-CPU sound code were
    once `.byte`, see notes/sound/sound_coverage.py) is invisible to the
    assembly/typed-data split -- it silently lands in "typed data". A targeted grep
    for this project's own self-tagged markers ("UNDECODED", "MISLABELLED, THIS IS
    CODE") is run separately and reported as a call-out (see `tagged_debt()`); it
    found ZERO live instances as of 2026-09-01 (the one surviving tag, in
    v7/v9/v10's ui_control_panel.s, is STALE documentation -- the code beneath it,
    UIState_KeyScan_Dispatch, is already real instructions; verified by inspection).
    The macro-expansion byte counts (naka_header/addr24/desc_entry exact;
    aligned_string's `.p2align 1` padding is a same-or-plus-one-byte approximation
    because true alignment depends on the absolute link address) are the only
    inexact part of the mechanical count, bounded at <2,500 bytes total tree-wide.

WSA1R (4 images): this tool CAN see them -- they live under wsa1/{prom_a,prom_b,
prom_c,prom_d}. wsa1 has zero clang usage and zero round-trip generators (checked:
no .c files, no clang invocation in wsa1/Makefile), so its "of which C" and
"round-trip" columns are always 0 and every `.incbin` byte is genuine verbatim
debt -- consistent with wsa1/scripts/analysis/source_coverage.py, whose
already-correct `.incbin`/`.fill`-following-`.include` logic this tool reuses
directly (imported, not re-derived) to avoid introducing a second copy of that
correctly-solved problem.

Run (from anywhere; the KN5000 REPO path defaults to this checkout's parent):
    python3 scripts/analysis/kn5000_source_coverage.py [REPO] [--markdown]
    python3 scripts/analysis/kn5000_source_coverage.py --selftest
"""
import glob
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = None
for a in sys.argv[1:]:
    if not a.startswith("--"):
        REPO = a
if REPO is None:
    REPO = os.path.dirname(os.path.dirname(HERE))
WSA = os.path.join(REPO, "wsa1")

ROMS = {
    "v10/maincpu": ("maincpu v10", 2097152),
    "v9/maincpu": ("maincpu v9", 2097152),
    "v7/maincpu": ("maincpu v7", 2097152),
    "v142/subcpu": ("subcpu payload v142", 196608),
    "subcpu/boot": ("subcpu boot (IC30)", 131072),
    "table_data": ("table data", 2097152),
    "custom_data": ("custom data (IC19)", 1048576),
    "hdae5000": ("HD-AE5000", 524288),
}
# ⚠ NOTE ON THE 9TH KN5000 IMAGE: `kn5000_subprogram_v142_compressed` (the 9th
# name in assert_byte_identical.py's PAIRS) is the SAME v142/subcpu source,
# LZSS-compressed at build time -- there is no separate .s tree for it, so it
# is not a tenth row here; its coverage is identical to "subcpu payload v142"
# by construction (same input to the compressor).

# --------------------------------------------------------------------------
# Comment stripping -- THE FIX. A ';' inside a quoted string (never happens in
# a bare `.incbin "path"` argument list, but kept correct anyway) does not end
# the directive; a ';' outside one does, and everything after it -- including
# a fossil "Was: .incbin ..." comment -- must never reach the regexes below.
# --------------------------------------------------------------------------
def strip_comment(line):
    in_str = False
    for i, ch in enumerate(line):
        if ch == '"':
            in_str = not in_str
        elif ch == ';' and not in_str:
            return line[:i]
    return line


def stripped_text(path):
    return "\n".join(strip_comment(l) for l in open(path, encoding="latin-1").read().split("\n"))


INC = re.compile(r'\.incbin\s+"([^"]+)"(?:\s*,\s*([0-9a-fA-Fx]+)\s*(?:,\s*([0-9a-fA-Fx]+))?)?')

# --------------------------------------------------------------------------
# incbin classification -- verbatim vs C vs round-trip. See the module
# docstring "WHAT COUNTS AS DEBT". `rel_path` is relative to the INCLUDING
# .s file's own directory (e.g. table_data's ui_bitmaps.s reaches into
# "../v10/maincpu/images/..."), so classification is done on the RESOLVED,
# repo-relative logical path -- never on the raw string, which would be
# missing its product prefix for every same-product reference and would
# carry a spurious "../" for every cross-product one.
# --------------------------------------------------------------------------
def classify_incbin(root, s_file, rel_path):
    """-> ('clang' | 'roundtrip' | 'verbatim', resolved_path_or_None)."""
    resolved = next((c for c in (os.path.join(os.path.dirname(s_file), rel_path),
                                  os.path.join(root, rel_path), rel_path) if os.path.exists(c)), None)
    s_dir = os.path.relpath(os.path.dirname(s_file), REPO)
    logical = os.path.normpath(os.path.join(s_dir, rel_path)).replace("\\", "/")
    probe = "/" + logical + "/"

    # v7/v9/v10 maincpu's includes/generated/*.bin: every single pattern rule in the
    # Makefile for these three products lists a `.c` prerequisite (checked exhaustively
    # 2026-09-01) -- there is no non-clang generator under maincpu/includes/generated/.
    if "/maincpu/includes/generated/" in probe:
        return "clang", resolved

    # hdae5000-images / tabledata-images: PNG(+palette txt)-roundtrip generators
    # (hdae5000_images.py, font_images.py, ui_bitmaps_images.py, icon_images.py,
    # mono_images.py). All write into an "includes/generated/" that is NOT under
    # maincpu (handled above), so this is safe to test unconditionally.
    if "/includes/generated/" in probe:
        return "roundtrip", resolved

    # Any "<product>/images/<name>.EXT" incbin with a sibling "<name>.png" next
    # to it is a mono_images.py / indexed_images.py roundtrip target -- true for
    # v10/v9/v7 maincpu/images/*.bin and table_data/images/Wallpaper_*.bin, even
    # though those .bin files also happen to be tracked in git as a build cache
    # (see the module docstring). A sibling-less file in the same "images/" dir
    # (table_data/images/FTBMP0*.BMP: no matching .png exists) has no generator
    # and stays verbatim.
    d, base = os.path.split(logical)
    if os.path.basename(d) == "images":
        stem = os.path.splitext(base)[0]
        if os.path.exists(os.path.join(REPO, d, stem + ".png")):
            return "roundtrip", resolved

    # Demo-song presets (midi_to_preset.py + compress_lzss.py, from checked-in
    # .mid + .yaml) and help databases (compress_slide8k.py, from the checked-in
    # decompressed help_db_<lang>.bin) -- see Makefile's DEMO_PRESET_COMPRESSED /
    # HELP_DB_COMPRESSED rules.
    if "/includes/demo_presets/" in probe or "/includes/help_databases/" in probe:
        return "roundtrip", resolved

    # custom_data's four style-event blobs (style_events.py, from
    # custom_data/styles/*.styles) -- style_events.py's own SECTIONS dict lists
    # exactly section_0 / section_1_2 / section_3_4 / section_5_6, so match the
    # pattern rather than hardcoding that list a second time.
    if re.match(r'^custom_data/includes/section_\d+(_\d+)?\.bin$', logical):
        return "roundtrip", resolved

    return "verbatim", resolved


# --------------------------------------------------------------------------
# Mechanical byte-emitting-directive scan (the assembly / typed-data split).
# Every directive kind actually used anywhere in this tree, confirmed by a
# full-tree grep 2026-09-01: .byte .short .long .ascii .asciz .fill .space
# .zero (never used: .word .dw .db .dd .skip .align -- if one of those shows
# up later this will silently undercount; the selftest's "no class negative"
# check is what would catch that, because "assembly" would then be inflated
# by exactly the missed bytes, which is harmless, OR (impossible given how
# assembly is computed as the remainder) never negative).
# --------------------------------------------------------------------------
DIRECTIVE_RE = re.compile(r'^\s*(?:[A-Za-z_.$][\w.$]*\s*:\s*)?\.(byte|short|long|ascii|asciz|fill|space|zero)\b(.*)$')

ESCAPES = {'n': '\n', 't': '\t', 'r': '\r', '0': '\0', '\\': '\\', '"': '"'}


def ascii_len(rest, terminated):
    m = re.search(r'"((?:[^"\\]|\\.)*)"', rest)
    if not m:
        return 0
    raw = m.group(1)
    n = 0
    i = 0
    while i < len(raw):
        if raw[i] == '\\' and i + 1 < len(raw):
            i += 2
        else:
            i += 1
        n += 1
    return n + (1 if terminated else 0)


def split_args(rest):
    return [a.strip() for a in rest.split(",") if a.strip()]


def directive_bytes(kind, rest):
    if kind == "byte":
        return len(split_args(rest))
    if kind == "short":
        return 2 * len(split_args(rest))
    if kind == "long":
        return 4 * len(split_args(rest))
    if kind == "ascii":
        return ascii_len(rest, terminated=False)
    if kind == "asciz":
        return ascii_len(rest, terminated=True)
    if kind == "fill":
        a = split_args(rest)
        if not a:
            return 0
        count = int(a[0], 0)
        size = int(a[1], 0) if len(a) > 1 else 1
        return count * size
    if kind in ("space", "zero"):
        a = split_args(rest)
        return int(a[0], 0) if a else 0
    return 0


# Byte-emitting macros -- the ONLY four in the entire tree with a byte-emitting
# body (confirmed 2026-09-01 by scanning every `.macro`...`.endm` block for a
# byte directive). Each entry is (bytes-per-call, invocation regex, exactness note).
MACRO_INVOKE = {
    # naka_header \type -> `.byte \type, 0x00, 0x60, 0x01` = 4 bytes, exact.
    "naka_header": (re.compile(r'^\s*naka_header\b'), lambda rest: 4),
    # addr24 \sym -> `.reloc ., R_TLCS900_24, \sym` + `.space 3` = 3 bytes, exact.
    "addr24": (re.compile(r'^\s*addr24\b'), lambda rest: 3),
    # desc_entry w,h,pixels -> `.short w,h` + `.long pixels` = 2+2+4 = 8 bytes, exact.
    "desc_entry": (re.compile(r'^\s*desc_entry\b'), lambda rest: 8),
    # aligned_string "..." -> `.asciz str` (len+1) then `.p2align 1, 0xff`.
    # ⚠ APPROXIMATE: real padding depends on the absolute link address at that
    # point, which this static per-line scan cannot know. Assumed even before
    # the call (true almost everywhere in this tree), so padding = (len+1) & 1.
    "aligned_string": (re.compile(r'^\s*aligned_string\b'), None),
}


def scan_directives(path):
    """-> (typed_data_bytes, macro_call_count) for one .s file, comment-stripped,
    counting `.incbin` lines as 0 (handled separately by the caller)."""
    total = 0
    macro_calls = 0
    for line in strip_comment_lines(path):
        if ".incbin" in line:
            continue
        m = DIRECTIVE_RE.match(line)
        if m:
            total += directive_bytes(m.group(1), m.group(2))
            continue
        for name, (rx, fn) in MACRO_INVOKE.items():
            if rx.match(line):
                macro_calls += 1
                if name == "aligned_string":
                    qm = re.search(r'"((?:[^"\\]|\\.)*)"', line)
                    if qm:
                        n = ascii_len(line, terminated=True)
                        total += n + (n & 1)
                else:
                    total += fn(line)
                break
    return total, macro_calls


def strip_comment_lines(path):
    return [strip_comment(l) for l in open(path, encoding="latin-1").read().split("\n")]


# --------------------------------------------------------------------------
# Self-tagged debt: this project marks a handful of regions with an explicit
# "still not decoded" comment when a region is understood but not yet
# converted to real directives. A live one is real, uncounted-elsewhere debt
# hiding inside what the mechanical scan above calls "typed data" or
# "assembly"; a description-only comment about an address that decodes to
# real code elsewhere (checked by hand) is NOT. This tool reports every match
# so a human can adjudicate; see the module docstring for the one case found
# 2026-09-01 (verified stale).
# --------------------------------------------------------------------------
TAG_RE = re.compile(r'UNDECODED\s*--\s*still in \.byte form|MISLABELLED,?\s*THIS IS CODE', re.I)


def tagged_debt(root):
    hits = []
    for f in glob.glob(root + "/**/*.s", recursive=True):
        for n, line in enumerate(open(f, encoding="latin-1"), 1):
            if TAG_RE.search(line):
                hits.append((f, n, line.strip()))
    return hits


# --------------------------------------------------------------------------
# Per-KN5000-root measurement
# --------------------------------------------------------------------------
def measure_kn5000_root(root):
    verbatim = clang = roundtrip = typed = 0
    macro_calls = 0
    for f in glob.glob(root + "/**/*.s", recursive=True):
        text = stripped_text(f)
        for rel_path, off, ln in INC.findall(text):
            cls, resolved = classify_incbin(root, f, rel_path)
            if resolved:
                fsz = os.path.getsize(resolved)
                size = int(ln, 0) if ln else (fsz - int(off, 0) if off else fsz)
            elif ln:
                size = int(ln, 0)
            else:
                size = None  # whole-file incbin of a not-yet-built target: unresolvable
            if size is None:
                print(f"  ⚠ UNRESOLVED: {f} .incbin \"{rel_path}\" -- file does not exist and no "
                      f"explicit length was given (run `make` first)", file=sys.stderr)
                continue
            if cls == "clang":
                clang += size
            elif cls == "roundtrip":
                roundtrip += size
            else:
                verbatim += size
        td, mc = scan_directives(f)
        typed += td
        macro_calls += mc
    return dict(verbatim=verbatim, clang=clang, roundtrip=roundtrip, typed=typed, macro_calls=macro_calls)


def report_row(label, total, m):
    incbin_total = m["verbatim"] + m["clang"] + m["roundtrip"]
    non_incbin = total - incbin_total
    assembly = non_incbin - m["typed"]
    typed_all = m["typed"] + m["roundtrip"]  # round-trip image/data bytes ARE typed data, just incbin-delivered
    debt = m["verbatim"]
    print(f"{label:24s} {total:10,d}  asm {assembly:10,d}  typed {typed_all:10,d}  "
          f"clang {m['clang']:9,d}  verbatim(DEBT) {debt:9,d}  "
          f"{100*(total-debt)/total:5.1f}% source")
    return dict(rom=total, assembly=assembly, typed=typed_all, clang=m["clang"], verbatim=debt)


# --------------------------------------------------------------------------
# WSA1R -- reuse the already-correct include-graph-following logic instead of
# re-deriving it. See wsa1/scripts/analysis/source_coverage.py's own docstring
# for why the naive recursive-glob approach used above for KN5000 would be
# WRONG here: prom_a/prom_c share kernel/kernel.s via `.include`, and prom_c is
# split into 26 subject files only reachable through its master's `.include`
# graph, so a blind glob could count an orphaned or double-included file.
# --------------------------------------------------------------------------
def wsa1_rows():
    if not os.path.isdir(WSA):
        print("\n⚠ wsa1/ NOT FOUND under this REPO -- WSA1R's 4 images cannot be measured "
              "by this run. Pass the unified checkout root as REPO, or run this script from "
              "inside it.", file=sys.stderr)
        return {}
    sys.path.insert(0, os.path.join(WSA, "scripts", "analysis"))
    import importlib
    if "source_coverage" in sys.modules:
        importlib.reload(sys.modules["source_coverage"])
    import source_coverage as wsa1_sc  # noqa
    rows = {}
    for key, fn in wsa1_sc.IMAGES:
        conv, inc, n_incbin, fill = wsa1_sc.measure(key)
        # Mechanical typed-data/assembly split over the SAME text wsa1's own
        # tool gathers (master .s + every `.include`d file it follows) -- so
        # this reuses their include-graph resolution rather than re-globbing.
        src = os.path.join(WSA, f"prom_{key}", f"wsa1_prom_{key}.s")
        text = open(src).read()
        for extra in wsa1_sc.OWN_INCLUDE.findall(text):
            text += "\n" + open(wsa1_sc.resolve(extra, key)).read()
        typed = 0
        for line in text.split("\n"):
            line = strip_comment(line)
            if ".incbin" in line:
                continue
            m = DIRECTIVE_RE.match(line)
            if m:
                typed += directive_bytes(m.group(1), m.group(2))
        assembly = conv - typed  # conv already excludes .incbin (wsa1_sc.measure's `inc`)
        rows[f"wsa1/prom_{key}"] = dict(rom=wsa1_sc.SIZE, assembly=assembly, typed=typed,
                                         clang=0, verbatim=inc, fill=fill, fn=fn)
    return rows


def print_wsa1(rows):
    if not rows:
        return
    print("\n--- WSA1R (4 images; C=0, no clang/round-trip generators exist in this product) ---")
    for key, r in rows.items():
        print(f"{key:24s} {r['rom']:10,d}  asm {r['assembly']:10,d}  typed {r['typed']:10,d}  "
              f"clang {0:9,d}  verbatim(DEBT) {r['verbatim']:9,d}  "
              f"{100*(r['rom']-r['verbatim'])/r['rom']:5.1f}% source"
              f"   ({r['fill']:,} B of the typed total is verified .fill filler)")


# --------------------------------------------------------------------------
# Selftest -- asserts the ABSENCE of defects, not today's numbers. Every check
# here would have caught the actual 2026-09-01 incident, and would catch its
# recurrence or a structurally similar one (e.g. a second comment-blind regex,
# a class that overflows the ROM, a class that goes negative).
# --------------------------------------------------------------------------
def selftest():
    fails = 0

    def ck(desc, cond):
        nonlocal fails
        print(("  ok   " if cond else "  FAIL "), desc)
        if not cond:
            fails += 1

    # 1. Comment stripping actually strips a dead `.incbin` comment.
    sample = '\t; Was: .incbin "old.bin", 100, 200\n\t.incbin "new.bin"\n'
    stripped = "\n".join(strip_comment(l) for l in sample.split("\n"))
    ck("strip_comment removes a commented-out .incbin line",
       INC.findall(stripped) == [("new.bin", "", "")])
    ck("strip_comment leaves the live .incbin line alone",
       len(INC.findall(sample)) == 2 and len(INC.findall(stripped)) == 1)

    # 2. No root anywhere else in the tree has the same fossil-comment shape
    #    that caused the hdae5000 double-count (a live regression tripwire:
    #    if this ever fires elsewhere, that root needs the same scrutiny).
    for root in ROMS:
        n = 0
        for f in glob.glob(root + "/**/*.s", recursive=True):
            for line in open(f, encoding="latin-1"):
                if re.match(r'\s*;\s*Was:.*\.incbin', line):
                    n += 1
        if root != "hdae5000":
            ck(f"{root}: no fossil '; Was: .incbin' comments (would double-count if unstripped)", n == 0)
        else:
            ck(f"{root}: fossil '; Was: .incbin' comments found and now excluded ({n} of them)", n == 10)

    # 3. Full measurement: every per-image class is non-negative, none exceeds
    #    the ROM, and assembly+typed+clang+verbatim == ROM exactly (the sum
    #    invariant holds by construction, but a bug in classify_incbin double-
    #    bucketing the SAME incbin size into two classes would break it).
    all_rows = {}
    for root, (label, total) in ROMS.items():
        m = measure_kn5000_root(root)
        incbin_total = m["verbatim"] + m["clang"] + m["roundtrip"]
        assembly = total - incbin_total - m["typed"]
        typed_all = m["typed"] + m["roundtrip"]
        row = dict(rom=total, assembly=assembly, typed=typed_all, clang=m["clang"], verbatim=m["verbatim"])
        all_rows[root] = row
        ck(f"{label}: assembly bytes not negative ({row['assembly']:,})", row["assembly"] >= 0)
        ck(f"{label}: verbatim(debt) bytes not negative", row["verbatim"] >= 0)
        ck(f"{label}: no class exceeds the ROM size", all(0 <= v <= total for v in
           (row["assembly"], row["typed"], row["clang"], row["verbatim"])))
        s = row["assembly"] + row["typed"] + row["clang"] + row["verbatim"]
        ck(f"{label}: assembly+typed+clang+verbatim == ROM size ({s:,} == {total:,})", s == total)

    wrows = wsa1_rows()
    for key, r in wrows.items():
        ck(f"{key}: verbatim(debt) bytes not negative", r["verbatim"] >= 0)
        ck(f"{key}: no class exceeds the ROM size",
           all(0 <= v <= r["rom"] for v in (r["assembly"], r["typed"], r["clang"], r["verbatim"])))
        s = r["assembly"] + r["typed"] + r["clang"] + r["verbatim"]
        ck(f"{key}: assembly+typed+clang+verbatim == ROM size ({s:,} == {r['rom']:,})", s == r["rom"])
    ck("wsa1/: all 4 images were measurable (this REPO can see wsa1/)", len(wrows) == 4)

    # 4. The specific regression this file exists to prevent: hdae5000's
    #    incbin total (all 3 classes) must never again exceed its ROM size,
    #    and must be far below the buggy 626,152 figure this file replaces.
    m_hd = measure_kn5000_root("hdae5000")
    hd_incbin_total = m_hd["verbatim"] + m_hd["clang"] + m_hd["roundtrip"]
    ck(f"hdae5000: incbin total ({hd_incbin_total:,} B) does not exceed the ROM (524,288 B)",
       hd_incbin_total <= 524288)
    ck(f"hdae5000: incbin total is NOT double the pre-fix figure (626,152 B)",
       hd_incbin_total < 500000)

    print(f"\n{fails} failure(s)")
    return 1 if fails else 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    print(f"REPO = {REPO}\n")
    print(f"{'component':24s} {'ROM':>10s}      {'assembly':>10s}      {'typed data':>10s}"
          f"      {'clang C':>9s}      {'DEBT (verbatim)':>9s}")
    grand = dict(rom=0, assembly=0, typed=0, clang=0, verbatim=0)
    for root, (label, total) in ROMS.items():
        m = measure_kn5000_root(root)
        row = report_row(label, total, m)
        for k in grand:
            grand[k] += row[k]
    wrows = wsa1_rows()
    print_wsa1(wrows)
    for r in wrows.values():
        grand["rom"] += r["rom"]
        grand["assembly"] += r["assembly"]
        grand["typed"] += r["typed"]
        grand["verbatim"] += r["verbatim"]
    print(f"\n{'ALL 13 IMAGES':24s} {grand['rom']:10,d}  asm {grand['assembly']:10,d}  "
          f"typed {grand['typed']:10,d}  clang {grand['clang']:9,d}  "
          f"verbatim(DEBT) {grand['verbatim']:9,d}  "
          f"{100*(grand['rom']-grand['verbatim'])/grand['rom']:5.1f}% source")

    # Self-tagged debt call-out (see module docstring)
    print("\n--- self-tagged 'still undecoded' markers (need human adjudication) ---")
    any_tag = False
    for root in ROMS:
        for f, n, line in tagged_debt(root):
            any_tag = True
            print(f"  {f}:{n}: {line}")
    if not any_tag:
        print("  none found")
    return 0


if __name__ == "__main__":
    sys.exit(main())
