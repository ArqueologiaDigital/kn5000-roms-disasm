#!/usr/bin/env python3
r"""RE-TYPE the raw runs in the NAKA-widget lane, byte-exactly.

QUESTION ANSWERED
-----------------
scripts/analysis/naka_lane_split.py establishes that not one region in this
lane has a single control-transfer target (T1: 0 `call`/`jp`/`jr` targets
across 12 regions, against 5..652 in each known-code control).  So every byte
the tree currently spells as an INSTRUCTION here is data-as-code, and every
raw `.byte` run is either structured data or a genuine byte table.

This script asks, per raw run: **what directive states these bytes
correctly?** and rewrites the run to it, changing not one byte.

  STR    the bytes parse EXACTLY as NUL-terminated strings over 0x20..0x7E
         with the 0xFF that `aligned_string` (`.asciz` + `.p2align 1,0xff`)
         emits when the NUL lands on an odd address.  A raw run is allowed to
         MERGE with the `aligned_string` items on either side of it, because
         the tree's misframes routinely eat a string's first two bytes -- the
         real "nowalphmaxpage" is spelled `jr nz,0x6f` + `aligned_string
         "walphmaxpage"` today.  The greedy parse of a byte stream into
         NUL-terminated strings is unique, so the merged split is not a
         choice.  Emitted as `aligned_string "..."`.
  PTR    4-aligned, a whole number of u32s, every one inside a pointer domain
         the image really uses, AND the run is ADJACENT TO AN EXISTING
         `.long`/`.word` item -- i.e. it is demonstrably inside a pointer
         table rather than merely 4-divisible.  Emitted as `.long 0x...`.
  BYTE   everything else.  Emitted as `.byte` -- which for a run currently
         spelled as instructions is still a REAL change: it withdraws a false
         claim that the bytes are executed.

REFUSALS ARE THE POINT.  A run that does not parse exactly, or whose interior
label would land inside a token, is left alone and counted with its reason.
Do not widen a rule to make a refusal disappear.

WHAT IS PRESERVED
  * every label, at its exact address.  If re-typing would move a label into
    the middle of a token the whole run is REFUSED rather than relabelled.
  * every comment, whole-line and trailing.
  * every symbolic operand (`.long SomeSymbol`) -- never touched, because the
    byte value cannot be recovered from the symbol.

RUN
    python3 scripts/converters/naka_lane_retype.py --report            # dry run
    python3 scripts/converters/naka_lane_retype.py --apply [file ...]
    rm -f scripts/analysis/.amap_v10.json     # the map is now stale
    make llvm-all && make gate-all                                     # certify

The byte gate is the only certification, and it CANNOT see a wrong reading
that reproduces the same bytes.  The framing evidence therefore lives in
scripts/analysis/naka_lane_split.py (T1 reference kinds, the two controls, and
--chordtable) and scripts/analysis/blind_start_enrichment_control.py, not here.

WHAT THIS LANE FOUND, 2026-09-02
  * 0 of the 12 regions has a single control-transfer target; the known-code
    controls have 5..652 each.  Bucket (a), real code spelled as `.byte`, is
    EMPTY here, so `extensions/extension_data.s` is data despite scoring worst
    in the image on the run-start enrichment probe -- see
    blind_start_enrichment_control.py for why that probe does not discriminate
    inside v10 (a PROVEN-DATA block scores 68.4% against known code's 14.8%).
  * 23,771 B re-typed: 750 B strings, 92 B pointer entries, and 22,929 B that
    claimed to be instructions and are not.
  * 6,681 B left as `.byte`: genuine byte tables, already correct, not debt.
  * REFUSED: the u16 re-typing of naka_sound_technichord_dispatch.s (550 B).
    The u16 phase would be chosen from the same bytes being typed, with no
    independent null -- the wrong-start-offset hazard, and `.byte` is not debt.
"""
import importlib.util
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))

_spec = importlib.util.spec_from_file_location(
    "naka_lane_split", os.path.join(ROOT, "scripts/analysis/naka_lane_split.py"))
split = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(split)

BASE = split.BASE
PTR_DOMAINS = split.PTR_DOMAINS
STR_MIN, STR_MAX = 0x20, 0x7E

STRDIR_RE = re.compile(r'^\s*(aligned_string|\.asciz|\.ascii)\b')
LONGDIR_RE = re.compile(r'^\s*\.(long|word)\b')

DEFAULT_FILES = [f for f in split.TARGETS
                 if f != "v10/maincpu/includes/gui_display_struct_data.s"]


# --------------------------------------------------------------------- tokens
def parse_strings(b, addr):
    """Exact parse of b as `aligned_string` records starting at addr.
    Returns [(text, offset, nbytes)] or None if it does not consume b exactly.
    The greedy read is unique: a string ends at its NUL and nowhere else."""
    out, i, n = [], 0, len(b)
    while i < n:
        j = i
        while j < n and STR_MIN <= b[j] <= STR_MAX:
            j += 1
        if j >= n or b[j] != 0x00:
            return None
        text = b[i:j].decode("latin-1")
        j += 1                                     # the NUL
        if (addr + j) % 2:                         # .p2align 1, 0xff
            if j >= n or b[j] != 0xFF:
                return None
            j += 1
        out.append((text, i, j - i))
        i = j
    return out or None


def parse_ptrs(b, addr):
    """[value] if b is a whole number of in-domain u32s.

    NOTE: NO natural-alignment requirement.  These tables are PACKED and the
    ones in this lane routinely sit at odd phases -- the chord table starts at
    0xECFF6A (phase 2) and the NAKA screen tables at 0xE1B7EE (also phase 2).
    Requiring `addr % 4 == 0` silently refused every one of them.  The phase
    evidence comes instead from the caller's `near_long` test: the run is
    contiguous with a real `.long` item, so it shares that item's phase by
    construction."""
    if len(b) % 4 or not b:
        return None
    out = []
    for i in range(0, len(b), 4):
        v = int.from_bytes(b[i:i + 4], "little")
        if not any(lo <= v <= hi for lo, hi in PTR_DOMAINS):
            return None
        out.append(v)
    return out


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def emitted_size(lines, addr):
    """Bytes the replacement lines will emit, computed the way the assembler
    will.  Compared against the span the edit replaces -- see `claim`.

    ⚠ THIS CHECK EXISTS BECAUSE ITS ABSENCE SHIPPED A RED GATE (9,287 bytes).
    A converter that reads bytes from the ROM and writes them back cannot be
    wrong about VALUES, so the only way it can break the gate is by emitting
    the wrong NUMBER of bytes -- and that is cheap to check here, in a second,
    instead of after a ten-minute rebuild."""
    n = 0
    for ln in lines:
        body = ln.split(";")[0]
        body = body.split(":", 1)[-1].strip() if ":" in body.split("\t")[0] else body.strip()
        if not body:
            continue
        if body.startswith(".byte"):
            n += len([x for x in body[5:].split(",") if x.strip()])
        elif body.startswith(".long"):
            n += 4
        elif body.startswith("aligned_string"):
            q = body[body.index('"') + 1:body.rindex('"')]
            q = q.replace('\\"', '"').replace("\\\\", "\\")
            n += len(q) + 1
            if (addr + n) % 2:
                n += 1
        else:
            raise SystemExit("emitted_size: unknown directive %r" % body)
    return n


# ---------------------------------------------------------------------- items
def items_of(path, amap):
    """[(lineno, addr, size, kind, label, text)] with the file's own bytes only."""
    return [r for r in split.scan_file(path, amap) if r[3] != "INCLUDE"]


def trailing_comment(text):
    c = text.split(";", 1)
    return c[1].strip() if len(c) > 1 and c[1].strip() else None


# --------------------------------------------------- record boundaries (T3')
def pointer_targets(romb, minrun=8):
    """Every address some POINTER TABLE in this image points at.

    A "pointer table" is a maximal run of >= `minrun` consecutive u32s, at a
    fixed 4-byte stride, that all land inside the program ROM.  The set of
    their values is an independent statement of where records BEGIN --
    independent because it is read off a different part of the image than the
    records themselves.  This is the instrument that settles the chord table
    (naka_lane_split.py --chordtable: 64/64 vs 0/64 at every nearby phase).

    ALL FOUR PHASES ARE SCANNED.  Scanning only phase 0 is how the tree
    acquired the misframe in the first place: the chord table starts at
    0xECFF6A, which is phase 2, and a phase-0-only scan cannot see it at all.
    """
    n = len(romb)
    out = set()
    for phase in range(4):
        addrs = list(range(phase, n - 3, 4))
        vals = [int.from_bytes(romb[i:i + 4], "little") for i in addrs]
        good = [1 if 0x00E00000 <= v <= 0x00FFFFFF else 0 for v in vals]
        i, m = 0, len(good)
        while i < m:
            if not good[i]:
                i += 1
                continue
            j = i
            while j < m and good[j]:
                j += 1
            if j - i >= minrun:
                out.update(vals[i:j])
            i = j
    return out


# ------------------------------------------------------------------- rewriting
def rewrite(path, amap, romb, apply_it, ptargets):
    src = open(os.path.join(ROOT, path), encoding="latin-1").read().split("\n")
    rows = items_of(path, amap)

    stats = {"STR": 0, "PTR": 0, "BYTE": 0, "KEPT": 0}
    nruns = {"STR": 0, "PTR": 0, "BYTE": 0, "KEPT": 0}
    refusals = []
    keptruns = []         # category (c): already-correct `.byte` runs
    edits = {}            # first lineno -> (lines_to_drop, replacement_lines)
    claimed = set()       # source lines already consumed by an edit
    covered = []          # (lo, size) per edit, for the conservation check

    def claim(ext, lo, size, lines):
        """Record an edit, refusing any that overlaps one already made.

        ⚠ THIS GUARD EXISTS BECAUSE ITS ABSENCE SHIPPED A RED GATE.  A string
        run is allowed to extend over its neighbours, so two runs could both
        claim the same source line; the writer then emitted BOTH replacements
        and 0x144 bytes of string table appeared twice.  9,287 bytes differed.
        Overlap is refused, never merged."""
        lns = [r[0] for r in ext]
        if claimed.intersection(lns):
            refusals.append((lo, size, "overlaps an edit already made"))
            return False
        got = emitted_size(lines, lo)
        if got != size:
            refusals.append((lo, size,
                             "would emit %d B for a %d B span" % (got, size)))
            return False
        claimed.update(lns)
        covered.append((lo, size))
        edits[lns[0]] = (lns, lines)
        return True


    def blob(lo, size):
        return romb[lo - BASE: lo - BASE + size]

    def labels_ok(group, starts):
        for _ln, addr, _s, _k, label, _t in group:
            if label and addr not in starts:
                return False
        return True

    def lab_map(group):
        d = {}
        for _ln, addr, _s, _k, label, _t in group:
            if label:
                d.setdefault(addr, label)
        return d

    def with_label(labels, addr, body):
        return ("%s:\t%s" % (labels[addr], body)) if addr in labels else ("\t" + body)

    def comment_map(group):
        """addr -> comment.  Comments are re-attached to the OUTPUT token that
        covers the address they were written at, never to whatever line
        happens to come last: a `; padding` note migrating onto a string is a
        comment silently made wrong."""
        d = {}
        for _ln, addr, _s, _k, _lab, text in group:
            c = trailing_comment(text)
            if c:
                d.setdefault(addr, []).append(c)
        return {a: " / ".join(dict.fromkeys(v)) for a, v in d.items()}

    def attach(lines, spans, cmts):
        """lines[i] covers spans[i] = (start_addr, end_addr).  Append each
        comment to the line whose span contains its address."""
        per = {}
        orphan = []
        for a, c in sorted(cmts.items()):
            for i, (s0, s1) in enumerate(spans):
                if s0 <= a < s1:
                    per.setdefault(i, []).append(c)
                    break
            else:
                orphan.append("\t\t\t; 0x%06X: %s" % (a, c))
        for i, cs in per.items():
            lines[i] += "\t\t; " + " / ".join(dict.fromkeys(cs))
        return lines + orphan

    # ---- maximal runs of RAW items, with the file-order index kept ----------
    # ⚠ CONTIGUITY IS PART OF THE DEFINITION.  `items_of` drops `.include`
    # items because their bytes belong to the included file -- which leaves
    # the item before an include ADJACENT IN THE LIST to the item after it,
    # while being thousands of bytes apart in the ROM.  Joining those two into
    # one "run" and then reading `size` contiguous bytes from `lo` re-emits the
    # included file's bytes in the wrong place.  That shipped a red gate:
    # 9,287 bytes, an 0x144 shift starting at 0xED3480, inside the incbin that
    # ui_widgets/normal_mode_layout.s contributes through this file's include.
    runs, cur = [], []
    for idx, r in enumerate(rows):
        raw = r[3] in ("RAW_BYTE", "RAW_INSTR") and r[2] > 0
        if raw and cur and cur[-1][1][1] + cur[-1][1][2] != r[1]:
            runs.append(cur)                      # a gap: start a new run
            cur = []
        if raw:
            cur.append((idx, r))
        else:
            if cur:
                runs.append(cur)
            cur = []
    if cur:
        runs.append(cur)

    def is_strdir(r):
        return r[3] == "TYPED" and STRDIR_RE.match(r[5].split(":", 1)[-1])

    for run in runs:
        i0, i1 = run[0][0], run[-1][0]
        group = [r for _i, r in run]
        lo = group[0][1]
        size = sum(r[2] for r in group)

        # ---- STR, allowing the run to absorb up to 3 already-typed string
        # items on either side.  The tree's misframes routinely swallow a
        # string's first two bytes, so the run alone will not parse.
        best = None
        for back in range(0, 4):
            for fwd in range(0, 4):
                a, b_ = i0 - back, i1 + fwd
                if a < 0 or b_ >= len(rows):
                    continue
                ext = rows[a:b_ + 1]
                if any((not is_strdir(r)) and r[3] not in ("RAW_BYTE", "RAW_INSTR")
                       for r in ext):
                    continue
                if any(r[2] == 0 for r in ext):
                    continue
                if any(x[1] + x[2] != y[1] for x, y in zip(ext, ext[1:])):
                    continue                      # the extension is not contiguous
                elo = ext[0][1]
                esz = sum(r[2] for r in ext)
                st = parse_strings(blob(elo, esz), elo)
                if st is None:
                    continue
                starts = {elo + off for _t, off, _n in st}
                if not labels_ok(ext, starts):
                    continue
                # EVIDENCE GATE.  Without it, `00 ff` padding parses as
                # `aligned_string ""` and a 4-byte record whose bytes happen to
                # end in NUL becomes a string -- both observed in the dry run.
                # A string claim needs either an independent pointer table
                # landing on its start, or an existing `aligned_string` in the
                # merge (the tree already asserts a string there and the merge
                # only reunites the head a misframe split off).
                nonempty = [(t, off) for t, off, _n in st if t]
                if not nonempty:
                    continue
                by_ptr = all((elo + off) in ptargets for _t, off in nonempty)
                # The one merge allowed without pointer evidence: the raw part
                # is a pure PREFIX of a string the tree already types.  It must
                # contain no NUL at all -- a raw run that ends in a NUL could
                # be a record of its own, and calling it a string would be a
                # new claim rather than the repair of a split one.
                head = [r for r in ext if r[3] in ("RAW_BYTE", "RAW_INSTR")]
                tail = [r for r in ext if r[3] == "TYPED"]
                prefix_repair = (
                    bool(tail)
                    and ext[:len(head)] == head          # all raw items first
                    and 0x00 not in blob(head[0][1], sum(r[2] for r in head)))
                if not (by_ptr or prefix_repair):
                    continue
                if best is None or esz < best[1]:
                    best = (ext, esz, st, elo)
                break
            if best:
                break
        if best:
            ext, esz, st, elo = best
            labels = lab_map(ext)
            lines = [with_label(labels, elo + off,
                                'aligned_string "%s"' % esc(t))
                     for t, off, _n in st]
            spans = [(elo + off, elo + off + n) for _t, off, n in st]
            if not claim(ext, elo, esz, attach(lines, spans, comment_map(ext))):
                continue
            stats["STR"] += size
            nruns["STR"] += 1
            continue

        # ---- PTR: 4-aligned u32s in domain, and demonstrably inside a
        # pointer table (a `.long`/`.word` item immediately before or after).
        near_long = False
        for j, touching in ((i0 - 1, lambda r: r[1] + r[2] == lo),
                            (i1 + 1, lambda r: r[1] == lo + size)):
            if 0 <= j < len(rows) and touching(rows[j]) \
               and LONGDIR_RE.match(rows[j][5].split(":", 1)[-1]):
                near_long = True
        pt = parse_ptrs(blob(lo, size), lo) if near_long else None
        if pt is not None:
            starts = {lo + 4 * k for k in range(len(pt))}
            if labels_ok(group, starts):
                labels = lab_map(group)
                lines = [with_label(labels, lo + 4 * k, ".long 0x%08X" % v)
                         for k, v in enumerate(pt)]
                spans = [(lo + 4 * k, lo + 4 * k + 4) for k in range(len(pt))]
                if not claim(group, lo, size,
                             attach(lines, spans, comment_map(group))):
                    continue
                stats["PTR"] += size
                nruns["PTR"] += 1
                continue
            refusals.append((lo, size, "PTR: an interior label would land mid-word"))

        # ---- BYTE.  Only worth a diff if the run currently CLAIMS to be code.
        # A run that is already `.byte` and answered no to STR and PTR is
        # category (c): a genuine byte table, already correctly written.
        if all(r[3] == "RAW_BYTE" for r in group):
            stats["KEPT"] += size
            nruns["KEPT"] += 1
            keptruns.append((lo, size))
            continue
        b = blob(lo, size)
        labels = lab_map(group)
        # Break rows where an independent pointer table says a record begins,
        # and where a label sits; otherwise every 16 bytes.
        breaks = sorted({0, size} |
                        {a - lo for a in labels if lo <= a < lo + size} |
                        {k for k in range(1, size) if (lo + k) in ptargets})
        lines, spans = [], []
        for s0, s1 in zip(breaks, breaks[1:]):
            for k in range(s0, s1, 16):
                kk = min(k + 16, s1)
                body = ".byte " + ", ".join("0x%02x" % c for c in b[k:kk])
                lines.append(with_label(labels, lo + k, body))
                spans.append((lo + k, lo + kk))
        missing = [a for a in labels if (a - lo) not in breaks]
        if missing:
            refusals.append((lo, size, "BYTE: label not on a row boundary"))
            continue
        if not claim(group, lo, size, attach(lines, spans, comment_map(group))):
            continue
        stats["BYTE"] += size
        nruns["BYTE"] += 1

    print("%-42s STR %4d/%6dB  PTR %4d/%5dB  BYTE %4d/%6dB  KEPT %4d/%6dB  refused %d"
          % (os.path.basename(path), nruns["STR"], stats["STR"], nruns["PTR"],
             stats["PTR"], nruns["BYTE"], stats["BYTE"],
             nruns["KEPT"], stats["KEPT"], len(refusals)))
    if os.environ.get("NAKA_SHOW_KEPT"):
        for lo, size in keptruns[:12]:
            b = romb[lo - BASE: lo - BASE + size]
            print("      KEPT 0x%06X %4dB  %s" % (lo, size, b.hex(" ")[:70]))
    for lo, size, why in refusals[:6]:
        print("      REFUSED 0x%06X %5dB  %s" % (lo, size, why))

    # INVARIANT: the addresses the edits cover must be disjoint, and their
    # total must equal the bytes accounted for.  A violation means an edit
    # emitted content for a range another edit also emits -- the exact defect
    # the `claim` guard above was added for.
    cov = sorted(covered)
    for (a0, n0), (a1, _n1) in zip(cov, cov[1:]):
        if a0 + n0 > a1:
            raise SystemExit("BUG: edits overlap at 0x%06X..0x%06X and 0x%06X"
                             % (a0, a0 + n0, a1))
    acc = stats["STR"] + stats["PTR"] + stats["BYTE"]
    if sum(n for _a, n in cov) < acc:
        raise SystemExit("BUG: covered %d B < accounted %d B"
                         % (sum(n for _a, n in cov), acc))

    if apply_it and edits:
        drop = set()
        for lns, _new in edits.values():
            drop |= set(lns)
        out = []
        for n, line in enumerate(src, 1):
            if n in edits:
                out.extend(edits[n][1])
            elif n in drop:
                continue
            else:
                out.append(line)
        open(os.path.join(ROOT, path), "w", encoding="latin-1").write("\n".join(out))
        print("      rewrote %s" % path)
    return stats, refusals


def detype(path, amap, romb, ptargets, apply_it):
    """WITHDRAW a type the tree asserts and the evidence does not support.

    The converter's string rule demands that an independent pointer table land
    on a string's first byte.  Applying that rule SYMMETRICALLY means a
    `.asciz` nothing points at, sitting in the middle of a byte stream, is a
    false claim in exactly the way a fake `jr` is -- and `.byte` is the honest
    directive for it.

    Used for msp_factory_defaults.s: one style cell delimited by
    `80 ff ff ff ff 87` ... `87`, reached only by `ld xiy, MSP_FACTORY_DEFAULTS`
    (address-taken, never called), whose 4-character "strings" are bytes 2..5 of
    6-byte `9X vv vv vv vv 00` events -- the NUL that ends the "string" is the
    event's own terminator.

    Only items with `.byte` on BOTH sides are touched, so an isolated typed item
    in a genuine string block is left alone.
    """
    src = open(os.path.join(ROOT, path), encoding="latin-1").read().split("\n")
    rows = items_of(path, amap)
    out, n, nb = {}, 0, 0
    for i, r in enumerate(rows):
        ln, addr, size, kind, label, text = r
        if kind != "TYPED" or size == 0 or addr in ptargets:
            continue
        body = text.split(";")[0].split(":", 1)[-1].strip()
        if not re.match(r'(\.asciz|\.ascii|\.short|\.long|\.word|aligned_string)\b', body):
            continue
        nbrs = [rows[j] for j in (i - 1, i + 1) if 0 <= j < len(rows)]
        if not nbrs or not all(x[3] == "RAW_BYTE" for x in nbrs):
            continue
        b = romb[addr - BASE: addr - BASE + size]
        line = ".byte " + ", ".join("0x%02x" % c for c in b)
        c = trailing_comment(text)
        if c:
            line += "\t\t; " + c
        out[ln] = ("%s:\t%s" % (label, line)) if label else ("\t" + line)
        n += 1
        nb += size
    print("%-42s DETYPE %d item(s), %d B: a type the evidence does not support"
          % (os.path.basename(path), n, nb))
    if apply_it and out:
        open(os.path.join(ROOT, path), "w", encoding="latin-1").write(
            "\n".join(out.get(i, l) for i, l in enumerate(src, 1)))
        print("      rewrote %s" % path)
    return nb


def main():
    args = sys.argv[1:]
    apply_it = "--apply" in args
    files = [a for a in args if not a.startswith("--")] or DEFAULT_FILES
    amap = split.address_map()
    romb = split.rom()
    ptargets = pointer_targets(romb)
    print("pointer-table target set: %d distinct record starts\n" % len(ptargets))
    tot = {"STR": 0, "PTR": 0, "BYTE": 0, "KEPT": 0}
    nref = 0
    if "--detype" in args:
        tot_d = 0
        for f in files:
            tot_d += detype(f, amap, romb, ptargets, apply_it)
        print("-" * 104)
        print("TOTAL de-typed: %d B" % tot_d)
        return 0
    for f in files:
        st, rf = rewrite(f, amap, romb, apply_it, ptargets)
        for k in tot:
            tot[k] += st[k]
        nref += len(rf)
    print("-" * 104)
    print("TOTAL  (b) re-typed: STR %6dB  PTR %6dB  BYTE(was code) %6dB"
          % (tot["STR"], tot["PTR"], tot["BYTE"]))
    print("       (c) kept as-is, already correct `.byte`: %6dB   (%d refusals)"
          % (tot["KEPT"], nref))
    if apply_it:
        print("\nNOW: rm -f scripts/analysis/.amap_v10.json && make llvm-all && make gate-all")
    return 0


if __name__ == "__main__":
    sys.exit(main())
