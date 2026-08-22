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


def rewrite(idx, t, span, insns, texts, addr2name):
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
        out = []
        # leading bytes of the first block that precede the range
        lead = t - first[1]
        if lead > 0:
            raw = first[4][:lead]
            for i in range(0, len(raw), 8):
                out.append("\t.byte " + ", ".join(f"0x{b:02x}" for b in raw[i:i + 8]))
        for (addr, _n, _x), text in zip(insns, texts):
            if addr in label_at and addr != first[1]:
                out.append(f"{label_at[addr]}:")
            # Emit symbol names for call/branch targets that have one. The
            # NUMERIC form is what was round-tripped, so the decode is proven;
            # the symbolic form's bytes are settled at link time, which the full
            # byte-match gate checks. Only exact symbol addresses substitute.
            out.append("\t" + cc.symbolise(text, addr2name))
        # trailing bytes of the last block that follow the range
        tail_start = t + span
        last_end = last[1] + len(last[4])
        if last_end > tail_start:
            raw = last[4][tail_start - last[1]:]
            for i in range(0, len(raw), 8):
                out.append("\t.byte " + ", ".join(f"0x{b:02x}" for b in raw[i:i + 8]))
        # NO head label. blocks_of() records the first `.byte` LINE as the block
        # start, so the label sits on the line above and is outside the replaced
        # span -- re-emitting it produced "symbol is already defined" for every
        # converted range and failed the build.
        lines[first[2]:last[3] + 1] = out
        open(path, "wb").write("\n".join(lines).encode("latin-1"))
        return path
    return None


def main():
    apply_ = "--apply" in sys.argv
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
    for t in sorted(targets):
        if limit and ok >= limit:
            break
        insns = decode_range(rom, terr, t)
        if len(insns) < 3:
            skipped += 1; continue
        if insns[-1][2].split()[0].lower() not in TERMINATORS:
            skipped += 1; continue                    # no clean function end
        span = sum(n for _, n, _ in insns)
        want = rom[t - BASE: t - BASE + span]
        # Choose each spelling by MATCHING BYTES, never by "it assembled".
        # canonical() parenthesises lda sources, which is right for
        # `lda XHL,XDE+0x0a` and WRONG for `lda XSP,XSP+0xf2`: the latter is
        # `bf f2 37` in the ROM, and the parenthesised form assembles happily to
        # something else entirely. A candidate that assembles is not a candidate
        # that is correct, and only the byte comparison can tell them apart.
        texts, pos, bad = [], 0, False
        for _, n, x in insns:
            target = want[pos:pos + n]
            chosen = None
            for cand in list(cc.translate(x)) + [cc.canonical(x)]:
                e = cc.encode(cand)
                if e == target:
                    chosen = cand; break
            if chosen is None:
                bad = True; break
            texts.append(chosen); pos += n
        if bad:
            skipped += 1; continue
        encs = cc.encode_block(texts)
        if encs is None or b"".join(encs) != want:
            skipped += 1; continue
        ok += 1
        total_bytes += span
        if apply_:
            pending.append((t, span, insns, texts))
        if ok <= 8:
            nm = addr2name.get(t, "")
            print(f"  0x{t:06X}  {span:5} B  {len(insns):4} insns  {nm}")
    print(f"\n{ok} ranges decode to a clean `ret` and re-assemble exactly, "
          f"{total_bytes:,} bytes")
    print(f"{skipped} skipped (no terminator, too short, or bytes differ)")
    if apply_:
        # Apply BOTTOM-UP within each file. Rewriting splices `lines` in place,
        # which shifts every later index, so the block records go stale the
        # moment one range is written. Applying a second range to the same file
        # with stale indices cut at the wrong offset and deleted label
        # definitions -- the build then failed with `undefined symbol` for
        # InitializeSuna and seven others.
        placed = []
        for t, span, insns, texts in pending:
            for path, (lines, blocks) in idx.items():
                if any(bk[1] <= t < bk[1] + len(bk[4]) for bk in blocks):
                    placed.append((path, t, span, insns, texts)); break
        for path in {p for p, *_ in placed}:
            mine = [x for x in placed if x[0] == path]
            mine.sort(key=lambda x: -x[1])          # highest address first
            for _, t, span, insns, texts in mine:
                rewrite({path: idx[path]}, t, span, insns, texts, addr2name)
            touched_files.add(path)
        print(f"rewrote {len(touched_files)} file(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
