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

⚠ A range that starts mid-block leaves the leading bytes of that block as .byte,
which is correct: those bytes have not been shown to be code.
"""
import importlib.util, json, os, re, subprocess, sys, tempfile

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
BRANCHES = ("jr", "jrl", "calr")
BRANCH_RE = re.compile(r'^(jr|jrl|calr)\s+(?:(\w+),\s*)?0x([0-9a-fA-F]+)$', re.I)


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
        texts.append(f"{mn} {cc_.lower()}, {name}" if cc_ else f"{mn} {name}")
    return texts, needed


def source_index(syms):
    """file -> list of (label, addr, line_index, bytes) for every .byte block."""
    import glob
    idx = {}
    for f in sorted(glob.glob(os.path.join(REPO, "v7/maincpu/*/*.s"))
                    + glob.glob(os.path.join(REPO, "v7/maincpu/*.s"))):
        lines, blocks = cc.blocks_of(f, syms)
        keep = [(l, a, s, e, raw) for (l, a, s, e, raw) in blocks if a is not None]
        if keep:
            idx[f] = (lines, keep)
    return idx


def decode_range(rom, terr, start, limit=16384):
    """Decode from `start` until a terminator or until reaching CODE territory."""
    off = start - BASE
    end = off
    while end < len(terr) and terr[end] == 2 and end - off < limit:
        end += 1
    tmp = os.path.join(tempfile.gettempdir(), "_range.bin")
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
import collections
FORMS = None
FORM_EX = {}


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
            return None
        # A label inside the lead or tail region cannot be placed between
        # emitted .byte lines, so refuse rather than move or drop it.
        for bk in touched:
            if bk[0] and (bk[1] < t or bk[1] >= t + span) and bk[1] != first[1]:
                REFUSED["a label falls in the lead/tail region"] = \
                    REFUSED.get("a label falls in the lead/tail region", 0) + 1
                return None
        # Every line in the replaced span must be a .byte line or a label we can
        # re-emit -- nothing else may be silently dropped.
        for ln in lines[first[2]:last[3] + 1]:
            if not re.match(r'^\s*\.byte\s', ln) and not re.match(r'^[A-Za-z_][\w]*:', ln):
                REFUSED["replaced span holds a non-.byte, non-label line"] = \
                    REFUSED.get("replaced span holds a non-.byte, non-label line", 0) + 1
                return None
        out = []

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
            return None
        lines[first[2]:last[3] + 1] = out
        open(path, "wb").write("\n".join(lines).encode("latin-1"))
        return path
    return None


def main():
    global FORMS
    apply_ = "--apply" in sys.argv
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
        if insns[-1][2].split()[0].lower() not in TERMINATORS and not ends_at_code:
            skipped += 1; skip("no `ret`, and does not end at a code boundary"); continue
        span = sum(n for _, n, _ in insns)
        want = rom[t - BASE: t - BASE + span]
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
            skipped += 1; skip("an instruction cannot be spelled to match its bytes"); continue
        if not br_labels:
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
        placed = []
        for t, span, insns, texts, _bl in pending:
            for path, (lines, blocks) in idx.items():
                if any(bk[1] <= t < bk[1] + len(bk[4]) for bk in blocks):
                    placed.append((path, t, span, insns, texts, _bl)); break
        for path in {p for p, *_ in placed}:
            mine = [x for x in placed if x[0] == path]
            mine.sort(key=lambda x: -x[1])          # highest address first
            wrote_here = 0
            for _, t, span, insns, texts, bl in mine:
                if rewrite({path: idx[path]}, t, span, insns, texts, addr2name, bl):
                    wrote_here += 1
            # Count files ACTUALLY written. This previously counted files a range
            # was merely assigned to, so it reported "rewrote 8 file(s)" while
            # every rewrite was refused and nothing changed on disk.
            if wrote_here:
                touched_files.add(path)
        print(f"rewrote {len(touched_files)} file(s)")
        for r, n in sorted(REFUSED.items(), key=lambda kv: -kv[1]):
            print(f"   refused {n:4}  {r}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
