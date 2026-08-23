#!/usr/bin/env python3
"""Convert v7 .byte ADDRESS RANGES to instructions, starting from reachable entries.

Block-level conversion is exhausted -- see scripts/analysis/v7_conversion_sweep.sh.
Both criteria tried there are sound and both are the wrong SHAPE, because the
.byte blocks in these sources are delimited by LABELS and labels are not function
entries: in midi_dispatch_handlers.s, 615 of 616 block starts are not call
targets. Whatever the evidence, a converter keyed on block starts has almost
nothing to bite on.

This one is keyed on addresses instead:

  ENTRY      a call target from analysis/v7-reachability/v7_call_targets.json,
             i.e. an address something already disassembled calls. That makes it
             code, and makes it an instruction boundary by construction -- which
             matters because a label is NOT one, and a mis-framed decode produces
             garbage that still round-trips byte-exactly, so the build gate is
             blind to it.
  EXTENT     decode forward until a `ret`/`reti`, or until the run reaches
             territory the sources already express as instructions.
  REWRITE    replace exactly the source lines covering [entry, end), keeping any
             labels that fall inside the range at their correct offsets.
  PROOF      the emitted text is re-assembled and must reproduce the original
             bytes exactly, or the range is skipped.

Run:  python3 scripts/converters/convert_reachable_ranges.py [--apply] [--limit N]
      --dry-run          place and check every range, write nothing
      --no-incbin        do not split `.incbin` ROM slices
      --no-plausibility  keep decodes that read as table data (see below)

⚠ A range that starts mid-block leaves the leading bytes of that block as .byte,
which is correct: those bytes have not been shown to be code.
"""
import importlib.util, json, os, re, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
BASE = 0xE00000
LLVM = os.path.expanduser("~/compartilhado/llvm-project/build/bin")
MC = os.path.join(LLVM, "llvm-mc")
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
ENC_RE = re.compile(r'[;#] encoding: \[([^\]]+)\]')

_cc = importlib.util.spec_from_file_location(
    "cc", os.path.join(HERE, "convert_corroborated_blocks.py"))
cc = importlib.util.module_from_spec(_cc); _cc.loader.exec_module(cc)

TERMINATORS = ("ret", "reti", "retd")
# An UNCONDITIONAL jump ends a routine just as a `ret` does -- it is a tail call
# or a jump to a continuation, and nothing after it is reached by falling
# through. Requiring `ret` alone refused 167 ranges for a reason about the
# instruction's spelling rather than about the control flow.
#
# ⚠ CONDITIONAL jumps are NOT terminators: after `jr nz, X` execution continues
# at the next instruction, so a range ending there is truncated, not finished.
# unidasm marks the unconditional forms with the `t` (always-true) condition --
# `jr t, 0x...` and `jrl t, 0x...` -- while a bare `jp <target>` carries no
# condition at all. Counted in committed v7 code: 326 `jr t,`, 80 `jrl t,`, and
# 842 bare `jp`, against thousands of conditional `jr z,` / `jr nz,`.
UNCOND_JUMP = re.compile(r'^(?:jp\s+(?!(?:z|nz|c|nc|t|f|lt|ge|le|gt|ult|uge|ule|ugt|ov|nov|mi|pl)\s*,)'
                         r'|(?:jr|jrl)\s+t\s*,)', re.I)
BRANCHES = ("jr", "jrl", "calr", "djnz")
BRANCH_RE = re.compile(r'^(jr|jrl|calr|djnz)\s+(?:(\w+),\s*)?0x([0-9a-fA-F]+)$', re.I)
# ⚠ `djnz` is a BRANCH whose first operand is a REGISTER, not a condition, and
# whose mnemonic carries the register width: `djnz BC,0xef8480` = d9 1c f9 =
# `djnz16 bc, <label>`, and `djnz C,0xf0f9af` = cb 1c ac = `djnz8 c, <label>`.
# Treating it as an ordinary branch emits `djnz bc, <label>`, which llvm-mc does
# not accept, so the width has to be chosen from the register.
# ⚠ Verifying these needed assembling to an OBJECT FILE and reading .text --
# `--show-encoding` prints only the `A` fixup placeholder for a symbolic branch,
# so it cannot confirm the bytes. (tools/spelling-probes/class-a-sweep/)
DJNZ_W16 = {"WA", "BC", "DE", "HL", "IX", "IY", "IZ", "SP"}


def resolve_branches(insns, t, span, addr2name):
    """Rewrite PC-relative branch targets as SYMBOLS, emitting local labels.

    `jr`/`jrl`/`calr` cannot be written numerically. `jr nz, 0xef1371` assembles
    cleanly to [0x6e,0x71] -- it takes the LOW BYTE of the address as the
    displacement, which is wrong and silent. The working sources always name a
    symbol. So: targets inside the range get a local `.Lc_<addr>` label emitted
    at the right instruction, targets outside use the ELF symbol if there is one,
    and a range with an unresolvable target is refused.

    Returns (texts, labels_at) or None.

    ⚠ A symbolic branch encodes as a FIXUP, so its final bytes are decided at
    link time and cannot be byte-matched here the way every other instruction is.
    The displacement is the assembler's job; what this must not get wrong is
    WHICH label, and that comes straight from unidasm's decoded target. The full
    byte-match gate is the check that closes the loop.
    """
    addrs = {a for a, _n, _x in insns}
    needed, texts = {}, []
    for a, n, x in insns:
        m = BRANCH_RE.match(x.strip())
        if not m:
            texts.append(None); continue
        mn, cc_, tgt = m.group(1).lower(), m.group(2), int(m.group(3), 16)
        if t <= tgt < t + span:
            if tgt not in addrs:
                return None                    # target is mid-instruction
            needed[tgt] = f".Lc_{tgt:06x}"
            name = needed[tgt]
        elif tgt in addr2name:
            name = addr2name[tgt]
        else:
            return None                        # no way to name it
        if mn == "djnz" and cc_:
            _w = "16" if cc_.upper() in DJNZ_W16 else "8"
            texts.append(f"djnz{_w} {cc_.lower()}, {name}")
        else:
            texts.append(f"{mn} {cc_.lower()}, {name}" if cc_ else f"{mn} {name}")
    return texts, needed


DROPPED = []


def source_index(syms):
    """file -> list of (label, addr, line_index, bytes) for every .byte block."""
    import glob
    global ROM
    ROM = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
    idx = {}
    for f in sorted(glob.glob(os.path.join(REPO, "v7/maincpu/*/*.s"))
                    + glob.glob(os.path.join(REPO, "v7/maincpu/*.s"))):
        lines, blocks = cc.blocks_of(f, syms)
        # VERIFY EVERY BLOCK AGAINST THE ROM. A block whose recorded bytes do
        # not match the ROM at its claimed address has the wrong base address,
        # and using it writes the right number of bytes in the wrong places --
        # invisible to the length invariant and to the per-instruction byte
        # match, caught only by a full rebuild. Two parser defects produced
        # exactly that (a label carried across intervening instructions, and a
        # label reused for every .byte run after a blank line). Rather than
        # trust that those were the last two, refuse any block that disagrees.
        # FIX A -- give UNLABELLED `.byte` runs an address from a cursor.
        #
        # blocks_of() can only address a run that has a label the ELF knows
        # sitting immediately above it. 5,597 runs / 87,170 bytes have none, and
        # dropping them made three refusal buckets permanent: a range would
        # decode and re-assemble byte-exactly, then be refused because the bytes
        # it needed lived in the very next run, unlabelled -- 23 ranges "extend
        # past its blocks", 3 "non-.byte line", 1 "do not tile", 1,187 bytes in
        # all, unmoved across ten closure rounds.
        #
        # A run that follows a placed block with nothing but BLANK or COMMENT
        # lines between them starts exactly where the previous one ended. That
        # is an inference, so it is not trusted: the ROM check below applies to
        # these exactly as to labelled blocks, and a wrong cursor cannot survive
        # it. Anything else (an instruction, an .incbin, an .ascii) resets the
        # cursor to None, because then the next run's address is unknown.
        blocks = sorted(blocks, key=lambda b: b[2])
        cursor, prev_end = None, None
        placed = []
        for (l, a, st, e, raw) in blocks:
            if a is None and cursor is not None and prev_end is not None:
                gap = lines[prev_end + 1:st]
                if all(not x.strip() or x.lstrip().startswith((';', '#')) for x in gap):
                    a = cursor
            placed.append((l, a, st, e, raw))
            cursor = (a + len(raw)) if a is not None else None
            prev_end = e

        keep = []
        for (l, a, st, e, raw) in placed:
            if a is None:
                continue
            if raw != ROM[a - BASE: a - BASE + len(raw)]:
                DROPPED.append((os.path.basename(f), l, a))
                continue
            keep.append((l, a, st, e, raw))
        if keep:
            idx[f] = (lines, keep)
    return idx


# --------------------------------------------------------------- .incbin sites
#
# 82 accepted ranges / 7,101 bytes had their ENTRY inside an `.incbin` ROM slice
# rather than in a `.byte` run, so the apply loop could not place them at all
# (scripts/analysis/README-rewrite-refusals.md, "the two buckets with no counter").
# A slice is a committed blob with no source; the bytes inside it are still ROM,
# and a range proven to be code there is exactly as convertible as one in a
# `.byte` run -- provided the directive can be SPLIT: head slice, instructions,
# tail slice.
#
# convert_v7_ptr_tables.py already does that split for pointer tables and is the
# working model for the mechanics (residue slices, `own_label`).
INCBIN_ANY_RE = re.compile(r'\.incbin\s+"([^"]+)"')
# A site is only rewritable if its LINE holds nothing but an optional label, the
# directive, and an optional comment. Anything else on the line would emit bytes
# that the replacement silently drops.
INCBIN_SITE_RE = re.compile(
    r'^(?:([A-Za-z_][\w]*):)?[ \t]*\.incbin\s+"([^"]+)"[ \t]*(?:[;#].*)?$')


def incbin_index():
    """Every `.incbin` site under v7/maincpu, with its EXACT ROM address.

    An `.incbin`'s address cannot be read off the source line, and searching the
    ROM for its content is ambiguous whenever a blob repeats or is included
    twice -- probe_rewrite_refusals.py places only 279 of 322 that way. So ASK
    THE ASSEMBLER: copy the tree, put a unique `__incloc_N:` label immediately
    above every directive, assemble and link with the real linker script, and
    read the addresses out with llvm-nm. That is the same address the real build
    gives, by construction.

    Every site is then checked against the ROM (`blob == ROM[addr:addr+len]`)
    and dropped on disagreement, so a location this cannot corroborate is not
    used. Measured 2026-08-22: 312 sites, 311 located, 311/311 ROM-verified.

    ⚠ Read-only with respect to the repo: the labels go into a COPY.
    """
    src_root = os.path.join(REPO, "v7", "maincpu")
    work = tempfile.mkdtemp(prefix="incloc_", dir=_SCRATCH)
    copy = os.path.join(work, "maincpu")
    shutil.copytree(src_root, copy, symlinks=True)
    sites, n = [], 0
    for root, _dirs, files in os.walk(copy):
        for fn in sorted(files):
            if not fn.endswith(".s"):
                continue
            cp = os.path.join(root, fn)
            lines = open(cp, "rb").read().decode("latin-1").split("\n")
            hit = False
            for i, ln in enumerate(lines):
                if ln.lstrip().startswith((";", "#")):
                    continue                      # `; Was: .incbin ...` is not a directive
                m = INCBIN_ANY_RE.search(ln)
                if not m:
                    continue
                sites.append(dict(tag=n, line=i, text=ln, target=m.group(1),
                                  path=os.path.join(src_root, os.path.relpath(cp, copy))))
                lines[i] = f"__incloc_{n}:\n" + ln
                n += 1
                hit = True
            if hit:
                open(cp, "wb").write("\n".join(lines).encode("latin-1"))
    obj, elf = os.path.join(work, "loc.o"), os.path.join(work, "loc.elf")
    r = subprocess.run([MC, "-triple=tlcs900", "-filetype=obj", "-I", copy,
                        "-o", obj, os.path.join(copy, "kn5000_v7_program.s")],
                       capture_output=True, text=True)
    if r.returncode:
        print(f"   .incbin index: llvm-mc failed, no sites indexed\n{r.stderr[:300]}")
        return []
    r = subprocess.run([os.path.join(LLVM, "ld.lld"), "-T",
                        os.path.join(src_root, "maincpu.ld"), "-o", elf, obj],
                       capture_output=True, text=True)
    if r.returncode:
        print(f"   .incbin index: ld.lld failed, no sites indexed\n{r.stderr[:300]}")
        return []
    addr = {}
    for line in subprocess.run([os.path.join(LLVM, "llvm-nm"), "--no-sort", elf],
                               capture_output=True, text=True).stdout.splitlines():
        parts = line.split()
        if len(parts) == 3 and parts[2].startswith("__incloc_"):
            addr[int(parts[2][9:])] = int(parts[0], 16)
    out, unplaced, disagree = [], 0, 0
    for site in sites:
        if site["tag"] not in addr:
            unplaced += 1
            continue
        cands = [os.path.join(os.path.dirname(site["path"]), site["target"]),
                 os.path.join(src_root, site["target"])]
        blob_path = next((c for c in cands if os.path.isfile(c)), None)
        if blob_path is None:
            unplaced += 1
            continue
        blob = open(blob_path, "rb").read()
        a = addr[site["tag"]]
        if not blob or ROM[a - BASE: a - BASE + len(blob)] != blob:
            disagree += 1
            continue
        site.update(addr=a, blob=blob, blob_path=blob_path)
        out.append(site)
    print(f"   .incbin index: {len(out)} of {len(sites)} site(s) located and "
          f"ROM-verified ({unplaced} unplaced, {disagree} disagreed with the ROM)")
    return out


def site_of(sites, t):
    """The .incbin site whose ROM slice contains address `t`, if any."""
    for s in sites:
        if s["addr"] <= t < s["addr"] + len(s["blob"]):
            return s
    return None


def _slice_name(target, suffix, used):
    """A residue slice path that collides with nothing on disk or in this run."""
    d, base = os.path.split(target)
    stem, ext = os.path.splitext(base)
    for cand in [f"{stem}_{suffix}{ext}"] + [f"{stem}_{suffix}{k}{ext}" for k in range(2, 40)]:
        rel = f"{d}/{cand}" if d else cand
        if rel not in used and not os.path.exists(
                os.path.join(REPO, "v7", "maincpu", rel)):
            used.add(rel)
            return rel
    raise AssertionError(f"no free residue slice name for {target}")


def rewrite_incbin(site, rows, addr2name, used, dry=False):
    """Split an `.incbin` ROM slice around one or more converted ranges.

    Emits, in place of the single directive:

        OwnLabel:                       (only if the label was ON that line)
                .incbin "..._head.bin"  (the bytes before the first range)
        <instructions>
                .incbin "..._mid1.bin"  (bytes between two ranges)
        <instructions>
                .incbin "..._tail.bin"  (the bytes after the last range)

    ⚠ BYTE-IDENTITY IS STRUCTURAL HERE, not a hope: the residues are cut from the
    BLOB ITSELF and the converted spans are checked against the blob at the same
    offsets, so head + span + ... + tail is asserted equal to the original blob
    before anything is written. What the `make clean-all && make all` gate still
    has to settle is the same thing it settles for every other converted range:
    the link-time bytes of symbolic operands.

    ⚠ A LABEL ON THE DIRECTIVE'S OWN LINE MUST BE RE-EMITTED (it names the first
    byte of the blob and its definition would otherwise vanish -- `undefined
    symbol`), and a label on an EARLIER line must NOT be, or it is defined twice.
    Same rule, and same reason, as convert_v7_ptr_tables.py.
    """
    if "romslices/" not in site["target"]:
        REFUSED[".incbin slice(s) that are generated/, not a committed romslice"] = \
            REFUSED.get(".incbin slice(s) that are generated/, not a committed romslice", 0) + 1
        REFUSED_BYTES[".incbin slice(s) that are generated/, not a committed romslice"] = \
            REFUSED_BYTES.get(".incbin slice(s) that are generated/, not a committed romslice", 0) \
            + sum(r[1] for r in rows)
        return None
    path = site["path"]
    lines = open(path, "rb").read().decode("latin-1").split("\n")
    # Locate the directive AFTER the .byte pass has already spliced this file:
    # its line index moved. The line text is the anchor, and it must be unique.
    hits = [i for i, ln in enumerate(lines) if ln == site["text"]]
    if len(hits) != 1:
        REFUSED[".incbin line is not uniquely findable after the .byte pass"] = \
            REFUSED.get(".incbin line is not uniquely findable after the .byte pass", 0) + 1
        return None
    li = hits[0]
    m = INCBIN_SITE_RE.match(lines[li])
    if not m:
        REFUSED[".incbin line carries something besides label/directive/comment"] = \
            REFUSED.get(".incbin line carries something besides label/directive/comment", 0) + 1
        return None
    own_label = m.group(1)
    blob, a = site["blob"], site["addr"]
    rows = sorted(rows)
    out, slices, pos, kept = [], {}, 0, []
    if own_label:
        out.append(f"{own_label}:")
    cuts = []                        # (kind, payload) in emission order
    for (t, span, insns, texts, br_labels) in rows:
        off = t - a
        if off < pos or off + span > len(blob):
            # DROP THE ONE RANGE, NOT THE SITE. Two call targets in the same
            # slice can overlap (one entry falls inside another's decoded span);
            # refusing the whole directive threw away every other range in it.
            REFUSED["range overlaps an earlier range in the same .incbin slice"] = \
                REFUSED.get("range overlaps an earlier range in the same .incbin slice", 0) + 1
            REFUSED_BYTES["range overlaps an earlier range in the same .incbin slice"] = \
                REFUSED_BYTES.get("range overlaps an earlier range in the same .incbin slice", 0) + span
            continue
        if blob[off:off + span] != ROM[t - BASE: t - BASE + span]:
            REFUSED[".incbin blob disagrees with the ROM at the range offset"] = \
                REFUSED.get(".incbin blob disagrees with the ROM at the range offset", 0) + 1
            return None
        if off > pos:
            cuts.append(("res", (pos, off)))
        cuts.append(("code", (t, span, insns, texts, br_labels)))
        pos = off + span
        kept.append((t, span, insns, texts, br_labels))
    if not kept:
        return None
    if pos < len(blob):
        cuts.append(("res", (pos, len(blob))))
    nres = 0
    for kind, payload in cuts:
        if kind == "res":
            lo, hi = payload
            suffix = "head" if lo == 0 else ("tail" if hi == len(blob) else f"mid{nres}")
            nres += 1
            rel = _slice_name(site["target"], suffix, used)
            slices[rel] = blob[lo:hi]
            out.append(f'\t.incbin "{rel}"')
        else:
            t, span, insns, texts, br_labels = payload
            for (ia, _n, _x), text in zip(insns, texts):
                if ia in br_labels:
                    out.append(f"{br_labels[ia]}:")
                out.append("\t" + cc.symbolise(text, addr2name))
    # STRUCTURAL BYTE-IDENTITY CHECK: reassemble the emitted plan from the blob's
    # own bytes and the ROM spans, and require it to equal the blob exactly.
    check, pos = bytearray(), 0
    for kind, payload in cuts:
        if kind == "res":
            lo, hi = payload
            check += blob[lo:hi]
        else:
            t, span = payload[0], payload[1]
            check += ROM[t - BASE: t - BASE + span]
    assert bytes(check) == blob, f"{site['target']}: split would change {len(blob)} bytes"
    if dry:
        return kept
    for rel, data in slices.items():
        dest = os.path.join(REPO, "v7", "maincpu", rel)
        assert not os.path.exists(dest), dest
        open(dest, "wb").write(data)
    lines[li:li + 1] = out
    open(path, "wb").write("\n".join(lines).encode("latin-1"))
    return kept


def decode_range(rom, terr, start, limit=16384):
    """Decode from `start` until a terminator or until reaching CODE territory.

    ⚠ `limit` bounds the SPAN handed to unidasm, not the decode. A range that
    comes back at exactly 16,384 bytes therefore means an entire undisassembled
    run decoded with no terminator and no `db` -- which is what a runaway decode
    through data looks like, not what a routine looks like. Two such ranges exist
    (0xE400ED and 0xE600ED).
    ⚠ Those interact with the `ends_at_code` acceptance path in main(), which
    accepts a decode that never found a terminator PROVIDED it consumed exactly
    the whole run. When the run is longer than the limit the length check saves
    us (16,384 != run length, so it is refused); when a run is shorter and fully
    consumed, the range is accepted on the strength of "it tiles" alone. That is
    defensible -- the surrounding sources really do continue as instructions --
    but it is the weakest acceptance rule here, and the plausibility screen
    (anti-pattern 13) is what stands behind it.
    """
    off = start - BASE
    end = off
    while end < len(terr) and terr[end] == 2 and end - off < limit:
        end += 1
    tmp = os.path.join(_SCRATCH, "_range.bin")
    open(tmp, "wb").write(rom[off:end])
    out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900", "-basepc", hex(start)],
                         capture_output=True, text=True, timeout=120).stdout
    insns = []
    for line in out.split("\n"):
        m = re.match(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.+)$', line)
        if not m:
            continue
        addr, raw_hex, text = int(m.group(1), 16), m.group(2).split(), m.group(3).strip()
        if text.split()[0].lower() == "db":
            break                     # unidasm declined: stop, do not guess
        insns.append((addr, len(raw_hex), text))
        if text.split()[0].lower() in TERMINATORS:
            break
    return insns


REFUSED = {}
REFUSED_BYTES = {}
TRUNC_LOST = 0
DIAG = "--diag" in sys.argv
import collections

# ⚠ PRIVATE scratch dir, not a fixed path. These decoders used
# tempfile.gettempdir()/"_<name>.bin", so two processes running the converter at
# once overwrote each other's bytes between the write and the unidasm read. A
# parallel agent caught it: its census reported `inc 1,WA` at 0xF04E98 where the
# ROM holds `1d 09`, a call. The byte-match check would reject such a decode, so
# no bad conversion could land -- but a silently wrong DECODE is exactly the
# input this converter must be able to trust.
_SCRATCH = tempfile.mkdtemp(prefix="kn5000_conv_")

FORMS = None
FORM_EX = {}


# ------------------------------------------------- is this decode PLAUSIBLE?
#
# ⚠ THE BYTE GATE CANNOT SEE A MIS-FRAMED DECODE. The bytes are reproduced
# exactly whether the framing is right or wrong, so `make clean-all && make all`
# reports 100.00% for a table of numbers "decoded" as instructions just as
# readily as for a real function. The ENTRY criterion is what is supposed to
# prevent that, and v7_reachable_from_code.py's own docstring says it does not
# always: "0xED40A7 decodes to `nop ; nop` and 0xED5465 to `swi 7 ; pop SR` --
# those are calls into data, or calls found inside a CODE run that was itself
# mis-framed. Read a target before converting it."
#
# So read it mechanically. These mnemonics are what ROM TABLE BYTES decode to,
# not what this firmware's routines contain:
#
#   swi           0xF8..0xFF. 0xFF is the commonest filler byte in the ROM, and
#                 v7_reachable_from_code.py already names `swi 7` as its own tell
#   normal, max   register-bank / saturation-mode switches -- 5 and 1 occurrences
#                 across all 210,320 instruction lines v7 already carries
#   halt, ldio,   CPU-state and I/O-space forms
#   ldwio
#   retd > 0xff   a stack unwind larger than any frame in this firmware
#
# MEASURED on the 70 `.incbin` ranges of the first --apply run: 6 contain a
# CPU-control mnemonic at all, and 5 of the 6 are demonstrably data --
# ToneKit_FrequencyTable (a frequency TABLE, decoded as `nop / swi 7 / max /
# ei 0x04 / ldwio / normal / popw wa / halt`), WidgetParam_Entry_018,
# CharMap_ValueData_B (`rcf / incf / retd 0x1009` inside a character map) and
# SeqStep_ByteBlockEA5F. The 6th, AccState_ReadAccompParams, is real code whose
# second instruction is `ei 0x06` -- which is exactly why `ei`/`di` are NOT in
# the set. The other 64 ranges are untouched by the rule.
#
# ⚠ This is a screen, not a proof: it can only refuse: it never accepts anything
# the byte match did not already accept. `--no-plausibility` turns it off.
IMPLAUSIBLE = ("swi", "normal", "max", "halt", "ldio", "ldwio")


def implausible(texts):
    """The mnemonic marking this decode as table data rather than code, or None."""
    for t in texts:
        parts = t.split(None, 1)
        mn = parts[0].lower()
        if mn in IMPLAUSIBLE:
            return mn
        if mn == "retd" and len(parts) > 1:
            try:
                if int(parts[1].strip(), 0) > 0xFF:
                    return "retd with a frame > 0xff"
            except ValueError:
                pass
    return None


def rewrite(idx, t, span, insns, texts, addr2name, branch_labels=None):
    branch_labels = branch_labels or {}
    """Replace the source lines covering [t, t+span) with instruction lines.

    Labels inside the range are re-emitted at their correct addresses, and bytes
    outside it stay as .byte -- a range that starts or ends mid-block leaves the
    surrounding bytes alone, because only the decoded range has been shown to be
    code.
    """
    for path, (lines, blocks) in idx.items():
        covering = [bk for bk in blocks if bk[1] <= t < bk[1] + len(bk[4])]
        if not covering:
            continue
        # blocks the range touches, in file order
        touched = [bk for bk in blocks if bk[1] < t + span and bk[1] + len(bk[4]) > t]
        touched.sort(key=lambda bk: bk[2])
        first, last = touched[0], touched[-1]
        label_at = {bk[1]: bk[0] for bk in touched if bk[0]}
        # NEVER DROP A LABEL. Any label inside the range must land exactly on a
        # decoded instruction, or it cannot be re-emitted and its definition
        # would vanish -- which is how Display_BytecodeBlock_F disappeared and
        # the link failed with `undefined symbol`. A label that is not an
        # instruction boundary also means the decode disagrees with the existing
        # framing, which is reason enough to leave the range alone.
        insn_addrs = {a for a, _n, _x in insns}
        for la in label_at:
            if la != first[1] and not (la < t or la >= t + span) and la not in insn_addrs:
                return None
        # Also scan the RAW LINES being replaced for any label definition, not
        # just the ones the block index knows about. source_index() drops blocks
        # whose label has no ELF address, but their lines still sit inside the
        # replaced span and were being spliced away -- that is how
        # Display_BytecodeBlock_F vanished twice. If a label in the span cannot
        # be placed on a decoded instruction, refuse the range.
        known = set(label_at.values())
        for ln in lines[first[2]:last[3] + 1]:
            lm = re.match(r'^([A-Za-z_][\w]*):', ln)
            if lm and lm.group(1) not in known:
                REFUSED["a label in the span cannot be placed"] = \
                    REFUSED.get("a label in the span cannot be placed", 0) + 1
                return None
        # EXACT FIT ONLY. The lead/tail re-emission path -- keeping the bytes of
        # a partly-covered first or last block as .byte around the instructions
        # -- failed in six different ways: duplicated labels, deleted labels,
        # deleted unindexed blocks, and byte losses that resynchronised a few
        # bytes later. Each fix revealed another case. So the path is gone: a
        # range is converted only when it covers its blocks exactly, start and
        # end. That converts less and cannot silently misplace a byte.
        # Partial coverage is allowed again, but ONLY behind the three
        # invariants that caught the six bugs this path had when it was
        # unguarded: byte-count preservation measured from the replaced LINES,
        # every label in the span placeable, and no non-.byte line silently
        # dropped. Exact-fit-only was the safe response before those existed;
        # with them, refusing partial ranges just leaves work undone -- it
        # refused all 17 remaining candidates and converted nothing.
        lead = t - first[1]
        last_end = last[1] + len(last[4])
        tail = last_end - (t + span)
        if lead < 0 or tail < 0:
            REFUSED["range extends past its blocks"] = \
                REFUSED.get("range extends past its blocks", 0) + 1
            REFUSED_BYTES["extends past blocks"] = REFUSED_BYTES.get("extends past blocks", 0) + span
            return None
        # The touched blocks must TILE the address range with no gap. lead/span/
        # tail arithmetic assumes byte N+1 of one block is byte 0 of the next,
        # and that is not always true -- bytes inside the span can belong to a
        # block source_index() filtered out (its label has no ELF address), so
        # `lead + span + tail` over-counts what the replaced LINES actually hold.
        # Measured: 2 of 114 multi-block lead cases, over-counting by 2 and 4
        # bytes. This is the defect the two earlier attempts kept tripping over.
        for _i in range(len(touched) - 1):
            if touched[_i][1] + len(touched[_i][4]) != touched[_i + 1][1]:
                REFUSED["touched blocks do not tile contiguously"] = \
                    REFUSED.get("touched blocks do not tile contiguously", 0) + 1
                return None

        # LEAD RE-ENABLED once the ROOT CAUSE was found. It was never the
        # lead arithmetic: blocks_of() was giving some blocks the WRONG BASE
        # ADDRESS, so the emission wrote the right number of bytes in the wrong
        # places. Two parser defects, both of which could only appear AFTER
        # earlier rounds had converted something -- which is why this path
        # seemed to work at first and then did not:
        #   * a label kept applying across intervening instruction lines, so a
        #     .byte run got the label's address instead of its own;
        #   * a label was reused for every .byte run after a blank line.
        # Both fixed, and source_index() now refuses any block whose bytes
        # disagree with the ROM rather than assuming those were the last two.
        # Previous note, kept for the record:
        #
        # Re-emitting the bytes of a first block that PRECEDE the range keeps
        # failing in ways the length invariant cannot see. Restoring it cleared
        # all 44 length refusals and gated at 103 wrong bytes in 4 runs -- the
        # totals matched, the content was displaced by a few bytes. Tail-only
        # has gated clean every time.
        #
        # Whatever is wrong is in the ORDER of what gets emitted around the
        # label of a partly-covered first block, and I have not found it. Two
        # attempts, two subtle corruptions, so the path stays off until someone
        # can explain it rather than patch it. Ranges that start mid-block are
        # simply not converted.

        # A label inside the lead or tail region cannot be placed between
        # emitted .byte lines, so refuse rather than move or drop it.
        for bk in touched:
            if bk[0] and (bk[1] < t or bk[1] >= t + span) and bk[1] != first[1]:
                REFUSED["a label falls in the lead/tail region"] = \
                    REFUSED.get("a label falls in the lead/tail region", 0) + 1
                return None
        # Every line in the replaced span must be a .byte line, a label we can
        # re-emit, or a line that CONTRIBUTES NO BYTES -- nothing that carries
        # data may be silently dropped.
        #
        # FIX B, and it must ship with Fix A. Fix A lets a range span several
        # runs, and consecutive runs are separated by exactly the blank lines
        # this check used to reject. Measured: 36 of the 37 offending lines
        # across all refused ranges were BLANK. The 37th is an `.incbin`, which
        # must keep failing -- it is a ROM slice whose bytes would vanish.
        # Comments are dropped with the span; they describe bytes that are being
        # replaced by the instructions those bytes decode to.
        for ln in lines[first[2]:last[3] + 1]:
            if not ln.strip() or ln.lstrip().startswith((';', '#')):
                continue
            if not re.match(r'^\s*\.byte\s', ln) and not re.match(r'^[A-Za-z_][\w]*:', ln):
                REFUSED["replaced span holds a non-.byte, non-label line"] = \
                    REFUSED.get("replaced span holds a non-.byte, non-label line", 0) + 1
                REFUSED_BYTES["non-.byte line"] = REFUSED_BYTES.get("non-.byte line", 0) + span
                return None
        out = []
        # Leading bytes of the first block that precede the range. This was
        # MISSING: when partial ranges were re-enabled the tail block was
        # restored and the lead was not, so every partial range silently
        # dropped its leading bytes. The length invariant refused all 44 of
        # them with "would change the byte count", which was exactly true --
        # the guard was reporting a real defect, not being over-strict.
        if lead:
            raw = first[4][:lead]
            for i in range(0, len(raw), 8):
                out.append("\t.byte " + ", ".join(f"0x{b:02x}" for b in raw[i:i + 8]))
        for (addr, _n, _x), text in zip(insns, texts):
            if addr in label_at and addr != first[1]:
                out.append(f"{label_at[addr]}:")
            if addr in branch_labels:
                out.append(f"{branch_labels[addr]}:")
            # Emit symbol names for call/branch targets that have one. The
            # NUMERIC form is what was round-tripped, so the decode is proven;
            # the symbolic form's bytes are settled at link time, which the full
            # byte-match gate checks. Only exact symbol addresses substitute.
            out.append("\t" + cc.symbolise(text, addr2name))
        # trailing bytes of the last block that follow the range

        # NO head label. blocks_of() records the first `.byte` LINE as the block
        # start, so the label sits on the line above and is outside the replaced
        # span -- re-emitting it produced "symbol is already defined" for every
        # converted range and failed the build.
        if tail:
            raw = last[4][len(last[4]) - tail:]
            for i in range(0, len(raw), 8):
                out.append("\t.byte " + ", ".join(f"0x{b:02x}" for b in raw[i:i + 8]))
        # LENGTH-PRESERVING INVARIANT. The replaced lines must emit exactly as
        # many bytes as they did before, or every symbol after this point moves
        # and the whole ROM shifts. A conversion that grew a region by 13 bytes
        # put maincpu v7 at 73.60% with 553,561 wrong bytes -- the byte-match
        # gate caught it, but only as a huge downstream diff, so the invariant is
        # asserted here where the cause is visible.
        # Count `before` from the ACTUAL LINES being replaced, not from the
        # indexed blocks. source_index() drops blocks whose label has no ELF
        # address, so their .byte lines sit inside the replaced span, are
        # invisible to the block sum, and get deleted -- which shrinks the region
        # and shifts every symbol after it. Summing the blocks put maincpu v7 at
        # 73.62%; summing the lines is the only measure that sees everything the
        # splice actually removes.
        before = 0
        for ln in lines[first[2]:last[3] + 1]:
            bm0 = re.match(r'^\s*\.byte\s+(.*)$', ln)
            if bm0:
                body0 = re.split(r'[;#]', bm0.group(1))[0]
                before += len([x for x in body0.split(",") if x.strip()])
        after = span
        for ln in out:
            bm = re.match(r'^\s*\.byte\s+(.*)$', ln)
            if bm:
                after += len([x for x in bm.group(1).split(",") if x.strip()])
        if before != after:
            REFUSED["rewrite would change the byte count"] = \
                REFUSED.get("rewrite would change the byte count", 0) + 1
            if DIAG:
                blocks_bytes = sum(len(bk[4]) for bk in touched)
                print(f"   len-refuse 0x{t:06X}: lines hold {before} B, "
                      f"emitting {after} B (span {span} + lead {lead} + tail {tail}); "
                      f"touched blocks hold {blocks_bytes} B across "
                      f"{len(touched)} block(s), lines {first[2]}..{last[3]}")
            return None
        lines[first[2]:last[3] + 1] = out
        open(path, "wb").write("\n".join(lines).encode("latin-1"))
        return path
    return None


def main():
    global FORMS
    apply_ = "--apply" in sys.argv
    no_incbin = "--no-incbin" in sys.argv
    no_plausibility = "--no-plausibility" in sys.argv
    # --dry-run does everything --apply does EXCEPT write: same placement, same
    # refusal tally, same structural byte-identity assertion in rewrite_incbin().
    dry = "--dry-run" in sys.argv
    apply_ = apply_ or dry
    if "--forms" in sys.argv:
        FORMS = collections.Counter()
    limit = int(sys.argv[sys.argv.index("--limit") + 1]) if "--limit" in sys.argv else 0
    rom = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
    spec = importlib.util.spec_from_file_location(
        "spans", os.path.join(REPO, "scripts/analysis/v7_undisassembled_spans.py"))
    spans = importlib.util.module_from_spec(spec); spec.loader.exec_module(spans)
    terr = spans.territory(spans.runs("v7/maincpu/kn5000_v7_program.s", "v7/maincpu"))
    targets = json.load(open(os.path.join(
        REPO, "analysis/v7-reachability/v7_call_targets.json")))["targets"]
    syms = cc.elf_syms("rebuilt_ROMs/kn5000_v7_program.llvm.elf")
    addr2name = dict(syms)

    idx = source_index(syms)
    if DROPPED:
        print(f"dropped {len(DROPPED)} block(s) whose bytes disagree with the ROM "
              f"(wrong base address -- would corrupt silently)")
    touched_files = set()
    pending = []
    ok = skipped = 0
    total_bytes = 0
    why = {}
    def skip(reason, n=1):
        why[reason] = why.get(reason, 0) + n
    for t in sorted(targets):
        if limit and ok >= limit:
            break
        insns = decode_range(rom, terr, t)
        if len(insns) < 3:
            skipped += 1; skip("decoded fewer than 3 instructions"); continue
        # A `ret` is one valid end. So is FALLING THROUGH into territory the
        # sources already express as instructions: the function continues there,
        # already disassembled, and the DATA part of it ends exactly at that
        # boundary. Requiring `ret` refused 400 ranges for a reason that was
        # about where the .byte happens to stop, not about the code.
        _off = t - BASE
        _run = 0
        while _off + _run < len(terr) and terr[_off + _run] == 2:
            _run += 1
        ends_at_code = sum(n for _, n, _ in insns) == _run
        _last = insns[-1][2].strip()
        if (_last.split()[0].lower() not in TERMINATORS
                and not UNCOND_JUMP.match(_last) and not ends_at_code):
            skipped += 1; skip("no `ret`, and does not end at a code boundary"); continue
        span = sum(n for _, n, _ in insns)
        want = rom[t - BASE: t - BASE + span]
        full_span = span
        # Choose each spelling by MATCHING BYTES, never by "it assembled".
        # canonical() parenthesises lda sources, which is right for
        # `lda XHL,XDE+0x0a` and WRONG for `lda XSP,XSP+0xf2`: the latter is
        # `bf f2 37` in the ROM, and the parenthesised form assembles happily to
        # something else entirely. A candidate that assembles is not a candidate
        # that is correct, and only the byte comparison can tell them apart.
        br = resolve_branches(insns, t, span, addr2name)
        if br is None:
            skipped += 1; skip("a branch target cannot be named"); continue
        br_texts, br_labels = br
        texts, pos, bad = [], 0, False
        for bi, (_, n, x) in enumerate(insns):
            target = want[pos:pos + n]
            if br_texts[bi] is not None:
                # A branch: verify only that the symbolic form assembles to the
                # same LENGTH; the gate settles the displacement bytes.
                e = cc.encode(br_texts[bi])
                if e is None or len(e) != n:
                    bad = True; break
                texts.append(br_texts[bi]); pos += n
                continue
            chosen = None
            for cand in list(cc.translate(x)) + [cc.canonical(x)]:
                e = cc.encode(cand)
                if e == target:
                    chosen = cand; break
            if chosen is None:
                bad = True
                if FORMS is not None:
                    mn = x.split()[0]
                    rest = x.split(None, 1)[1] if len(x.split(None, 1)) > 1 else ""
                    FORMS[mn + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                                            re.sub(r'\b[A-Z]{1,4}\b', 'r', rest))] += 1
                    FORM_EX.setdefault(mn + " " + re.sub(r'0x[0-9a-fA-F]+', 'imm',
                                       re.sub(r'\b[A-Z]{1,4}\b', 'r', rest)), x)
                break
            texts.append(chosen); pos += n
        if bad:
            # TRUNCATE rather than discard. One unspellable instruction used to
            # throw away the whole range, but everything decoded BEFORE it is
            # still verified code -- each of those was byte-matched. Convert the
            # prefix and leave the rest as .byte, which is exactly what a
            # partial range already supports.
            kept = len(texts)
            if kept < 3:
                skipped += 1
                skip("an instruction cannot be spelled to match its bytes")
                continue
            insns = insns[:kept]
            span = sum(n for _, n, _ in insns)
            want = want[:span]
            br_texts = br_texts[:kept]
            # A branch in the kept prefix may target an instruction PAST the
            # cut, whose .Lc_ label no longer gets emitted -- that would link
            # as an undefined symbol. Keep only labels still inside the range,
            # and refuse if any kept branch now names a missing one.
            end = t + span
            br_labels = {a: l for a, l in br_labels.items() if t <= a < end}
            live = set(br_labels.values())
            if any(bt and ".Lc_" in bt and bt.rsplit(None, 1)[-1] not in live
                   for bt in br_texts):
                skipped += 1
                skip("truncation would orphan a branch label")
                continue
            bad = False
            # Report how much a truncation COSTS, so the value of chasing more
            # spellings is measurable rather than assumed.
            global TRUNC_LOST
            TRUNC_LOST += full_span - span
            skip("truncated at an unspellable instruction")
        # ⚠ THE WHOLE-BLOCK RE-CHECK MUST NOT RUN OVER A FIXUP.
        #
        # This used to read `if not br_labels:`. `br_labels` holds only the
        # LOCAL `.Lc_` labels -- targets inside the range. A branch to an
        # EXTERNAL symbol adds nothing to it, so a range whose branches all
        # leave the range looked label-free, fell into the byte comparison, and
        # was compared against a LINK-TIME PLACEHOLDER: llvm-mc emits
        # `; encoding: [0x6e,A]` for a symbolic branch, and the `A` reads back
        # as 0x0A. Those ranges could never pass, however correct they were.
        #
        # Cost of the bug, measured by scripts/analysis/v7_blocking_forms_census.py:
        # 361 ranges / 18,412 bytes -- about SEVEN TIMES the entire remaining
        # spelling backlog, which is why the census that found it was worth more
        # than the spellings it was asked to rank.
        #
        # The per-instruction loop above already checks each branch the only way
        # a branch can be checked here (same LENGTH), and the full `make all`
        # byte-match gate settles the displacements against the real ROM. So the
        # correct condition is "no branch anywhere in the block", not "no local
        # label".
        bad_mn = None if no_plausibility else implausible(texts)
        if bad_mn:
            skipped += 1
            skip(f"decode contains `{bad_mn}`, so it reads as table data, not code")
            continue
        has_branch = any(x is not None for x in br_texts)
        if not br_labels and not has_branch:
            encs = cc.encode_block(texts)
            if encs is None or b"".join(encs) != want:
                skipped += 1; skip("block re-assembly did not reproduce the bytes"); continue
        ok += 1
        total_bytes += span
        if apply_:
            pending.append((t, span, insns, texts, br_labels))
        if ok <= 8:
            nm = addr2name.get(t, "")
            print(f"  0x{t:06X}  {span:5} B  {len(insns):4} insns  {nm}")
    print(f"\n{ok} ranges decode to a clean `ret` and re-assemble exactly, "
          f"{total_bytes:,} bytes")
    if FORMS is not None:
        print(f"\nforms the converter cannot spell ({sum(FORMS.values())} instances),")
        print("measured with the converter's OWN logic, branch resolution included --")
        print("unlike v7_unspellable_forms.py, which probes translate()/canonical()")
        print("only and therefore counts branches it would in fact resolve:")
        for k, v in FORMS.most_common(14):
            print(f"  {v:5}  {k:26} e.g. {FORM_EX[k]}")
        print()
    if TRUNC_LOST:
        print(f"bytes lost to truncation (would be gained by more spellings): "
              f"{TRUNC_LOST:,}")
    print(f"{skipped} skipped:")
    for r, n in sorted(why.items(), key=lambda kv: -kv[1]):
        print(f"   {n:5}  {r}")
    if apply_:
        # Apply BOTTOM-UP within each file. Rewriting splices `lines` in place,
        # which shifts every later index, so the block records go stale the
        # moment one range is written. Applying a second range to the same file
        # with stale indices cut at the wrong offset and deleted label
        # definitions -- the build then failed with `undefined symbol` for
        # InitializeSuna and seven others.
        # ⚠ EVERY DROP MUST BE COUNTED. This loop used to be a bare `for ... break`
        # with no `else`: a range whose entry sits in no indexed block simply
        # vanished, silently. At the 2026-08-22 fixpoint that was 103 ranges /
        # 8,828 bytes -- with a further 29 ranges / 2,053 bytes lost to rewrite()
        # returning None without recording a reason. So 10,881 of the 12,068 bytes
        # the converter accepted were MISSING from the report whose entire purpose
        # is to explain why a round gained nothing. A refusal bucket that cannot
        # pass (anti-pattern 12) at least appears; this did not appear at all.
        # A range whose entry is in no `.byte` block may still be placeable: 82
        # of the 103 (7,101 B) sit inside an `.incbin` ROM slice. Those go to
        # rewrite_incbin(), which splits the directive around them.
        sites = [] if no_incbin else incbin_index()
        placed = []
        byte_path = [0, 0]                     # ranges, bytes converted in .byte runs
        inc_rows = collections.defaultdict(list)
        by_tag = {s["tag"]: s for s in sites}
        for t, span, insns, texts, _bl in pending:
            for path, (lines, blocks) in idx.items():
                if any(bk[1] <= t < bk[1] + len(bk[4]) for bk in blocks):
                    placed.append((path, t, span, insns, texts, _bl)); break
            else:
                site = site_of(sites, t)
                if site is None:
                    REFUSED["entry is in no indexed .byte block and in no located .incbin"] = REFUSED.get("entry is in no indexed .byte block and in no located .incbin", 0) + 1
                    REFUSED_BYTES["entry is in no indexed .byte block and in no located .incbin"] = REFUSED_BYTES.get("entry is in no indexed .byte block and in no located .incbin", 0) + span
                elif t + span > site["addr"] + len(site["blob"]):
                    REFUSED["range starts in an .incbin slice but runs past its end"] = REFUSED.get("range starts in an .incbin slice but runs past its end", 0) + 1
                    REFUSED_BYTES["range starts in an .incbin slice but runs past its end"] = REFUSED_BYTES.get("range starts in an .incbin slice but runs past its end", 0) + span
                else:
                    inc_rows[site["tag"]].append((t, span, insns, texts, _bl))
        for path in {p for p, *_ in placed}:
            mine = [x for x in placed if x[0] == path]
            mine.sort(key=lambda x: -x[1])          # highest address first
            wrote_here = 0
            for _, t, span, insns, texts, bl in mine:
                byte_path[0] += 1; byte_path[1] += span
                _before = sum(REFUSED.values())
                if dry or rewrite({path: idx[path]}, t, span, insns, texts, addr2name, bl):
                    wrote_here += 1
                elif sum(REFUSED.values()) == _before:
                    byte_path[0] -= 1; byte_path[1] -= span
                    # rewrite() declined without recording a reason. Nearly all of
                    # these are the "NEVER DROP A LABEL" guard, which is real
                    # protection -- but 25 of 29 measured cases were blocked by
                    # labels NOTHING in v7/maincpu/*.s references (transplant-pass
                    # artefacts such as `Audio_NullRet1:` / `Audio_NullRet1_Data:`
                    # sitting on the two bytes `ca 8b`, which are one `ld C,B`).
                    REFUSED["rewrite declined silently (usually a label it will not drop)"] = REFUSED.get("rewrite declined silently (usually a label it will not drop)", 0) + 1
                    REFUSED_BYTES["rewrite declined silently (usually a label it will not drop)"] = REFUSED_BYTES.get("rewrite declined silently (usually a label it will not drop)", 0) + span
                else:
                    byte_path[0] -= 1; byte_path[1] -= span
            # Count files ACTUALLY written. This previously counted files a range
            # was merely assigned to, so it reported "rewrote 8 file(s)" while
            # every rewrite was refused and nothing changed on disk.
            if wrote_here:
                touched_files.add(path)
        # ⚠ THE `.incbin` PASS RUNS LAST, and re-reads each file from disk. The
        # loop above splices `idx[path]`'s line list in place and writes it out,
        # so every recorded line index for that file is stale the moment it does;
        # rewrite_incbin() therefore re-finds its directive BY LINE TEXT.
        inc_ranges = inc_bytes = split_sites = 0
        used_names, manifest = set(), []
        for tag, rows in sorted(inc_rows.items()):
            site = by_tag[tag]
            # COUNT WHAT WAS CONVERTED, NOT WHAT WAS OFFERED. This counted
            # `rows`, which includes any range rewrite_incbin() dropped as
            # overlapping -- so the reported byte total exceeded the CODE gain
            # l1_territory_map.py measured, by exactly the dropped range.
            kept = rewrite_incbin(site, rows, addr2name, used_names, dry=dry)
            if kept:
                split_sites += 1
                touched_files.add(site["path"])
                inc_ranges += len(kept)
                inc_bytes += sum(r[1] for r in kept)
                for t, span, insns, texts, _b in kept:
                    manifest.append({
                        "entry": f"0x{t:06X}", "bytes": span,
                        "instructions": len(insns),
                        "slice": site["target"],
                        "slice_addr": f"0x{site['addr']:06X}",
                        "slice_bytes": len(site["blob"]),
                        "source": os.path.relpath(site["path"], REPO),
                        "first": " ; ".join(texts[:4])})
        # EVERY CONVERTED RANGE, NAMED. A split that turns table bytes into
        # instructions is invisible to the build gate, so the only way anyone can
        # review this pass is a list of what it did -- which range, in which
        # slice, opening with what.
        if manifest and not dry:
            mp = os.path.join(REPO, "analysis/v7-reachability/v7_incbin_range_splits.json")
            old_rows = []
            if os.path.exists(mp):
                old_rows = json.load(open(mp)).get("splits", [])
            seen = {r["entry"] for r in old_rows}
            json.dump({"generated_by": "scripts/converters/convert_reachable_ranges.py --apply",
                       "splits": old_rows + [r for r in manifest if r["entry"] not in seen]},
                      open(mp, "w"), indent=1)
            print(f"   manifest: analysis/v7-reachability/v7_incbin_range_splits.json")
        if sites:
            # SITES ACTUALLY SPLIT, not sites a range was offered to: this
            # printed len(inc_rows), which counts the refused ones too.
            print(f"split {split_sites} of {len(inc_rows)} .incbin slice(s) offered, "
                  f"around {inc_ranges} range(s), {inc_bytes:,} bytes")
        # THE TOTAL THAT MUST MATCH l1_territory_map.py's CODE GAIN. Every byte
        # below moved from DATA to CODE; if the two numbers disagree, one of them
        # is counting something it did not convert.
        print(f"converted {byte_path[0] + inc_ranges} range(s), "
              f"{byte_path[1] + inc_bytes:,} bytes  "
              f"(.byte runs {byte_path[0]}/{byte_path[1]:,}, "
              f".incbin slices {inc_ranges}/{inc_bytes:,})")
        print(f"rewrote {len(touched_files)} file(s)")
        for r, n in sorted(REFUSED.items(), key=lambda kv: -kv[1]):
            print(f"   refused {n:4}  {r}")
        for r, n in sorted(REFUSED_BYTES.items(), key=lambda kv: -kv[1]):
            print(f"   ... {n:,} bytes behind: {r}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
