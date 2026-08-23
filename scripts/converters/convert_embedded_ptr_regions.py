#!/usr/bin/env python3
"""Rewrite pointer tables EMBEDDED INSIDE `.incbin` blobs as `.long <symbol>`.

QUESTION ANSWERED
-----------------
`l3_embedded_structure_scan.py` found 45 regions holding ROM-range u32s inside
blobs the binary-include audit passes as OPAQUE, and
`qualify_embedded_ptr_regions.py` narrowed that to 24 regions / 13,056 B whose
words resolve to REAL v7/v9/v10 symbol addresses far above the 1.79% null and
whose blob has exactly one `.incbin` site.

Neither existing converter reaches them: `convert_v7_ptr_tables.py` handles a
blob that is a pointer table WHOLE, and `convert_embedded_tables.py` handles
tables inside `.byte` runs. These are tables inside a BINARY INCLUDE.

METHOD -- split the DIRECTIVE, never the file:

    Label:                              Label:
        .incbin "X.bin"          ->         .incbin "X.bin", 0, <s>
                                        Label_PtrTable_<s>:
                                            .long Sym1
                                            .long Sym2
                                            ...
                                            .incbin "X.bin", <e>, <len-e>

`.incbin "file", skip, count` is already used in this tree and llvm-mc accepts
it, so the blob FILE stays byte-for-byte the dump it was -- which matters,
because the file is the artefact and only the directive is our description of it.

TWO INDEPENDENT QUALIFICATION PATHS. A table is accepted if EITHER holds:

  P1 SYMBOL  >= 90% of words hit an exact ELF symbol address (null 1.79%).
  P4 RESOLVE-DOMINANT  >=10x the 1.9% symbol-resolution null among non-null
     words, regardless of the in-range fraction. Landing in ROM range is WEAK
     evidence (that range is a sixth of the u32 space); hitting a defined symbol
     is strong. `naka_sequencer_channels` 0x000d00 resolves 95.2% -- 50x the
     null -- and was rejected only because its in-range figure was 95.2% against
     a 98% floor, i.e. the weak test was vetoing the strong one.

  P3 NON-NULL   >=98% of the NON-ZERO words land in ROM range, and they resolve
     far above the 1.9% null. A zero is an EMPTY SLOT, not a failed pointer;
     counting nulls against the table is how a region the sources themselves
     call `IconBitmapNamePtrTable` scored 69%.
  P2 STRUCTURE  >= 60% of targets carry a recognised RECORD SIGNATURE in the
     ROM -- currently `XX 00 60 01`, what this tree's own `naka_header` macro
     emits (null 0.165%, measured over random ROM offsets).

⚠ P2 EXISTS BECAUSE P1 IS STRUCTURALLY BLIND TO A WHOLE CLASS. The largest
region in the set, `naka_effects_seq.bin` 0x006700 (2,560 B), scores 0% on P1 --
not because it is not a pointer table, but because its targets are INTERIOR
addresses of other `.incbin` blobs, and a blob interior has no symbol by
construction. It scores 82% on P2 against a 0.165% null, a ~500x enrichment. A
floor on symbol resolution alone would have excluded the clearest table here
forever, and would have looked principled doing it.

When P2 qualifies a region, its words are emitted as numeric `.long 0x00ABCDEF`:
byte-identical, explicitly an address table rather than a byte soup, and honest
about the fact that no symbol exists to name.

⚠ RESOLUTION DISCIPLINE, inherited from convert_v7_ptr_tables.py: only an EXACT
hit on a symbol address counts. "Inside a symbol" is not evidence -- 38,988
symbols over 2 MB put most random addresses shortly after some symbol, so a rule
that accepts interior hits cannot fail. A word that does not resolve exactly is
emitted as a numeric `.long 0x00ABCDEF`, which is byte-identical and still names
the address, rather than being guessed at.

⚠ Each revision resolves against ITS OWN ELF. v7, v9 and v10 are different links
and the same table sits at different addresses in each; resolving v9 words in the
v7 address space is a category error that reports a real table as not one.

VERIFICATION: before writing, every emitted line is resolved in Python and the
concatenation compared byte-for-byte against the blob region. Then the usual
`assert_byte_identical.py` gate must pass.

Run:  python3 scripts/converters/convert_embedded_ptr_regions.py [--apply]
      (default is a dry run that writes nothing)
      python3 scripts/converters/convert_embedded_ptr_regions.py --controls
      re-measures BOTH nulls quoted above, so the enrichment figures that
      justify P1 and P2 are reproducible rather than asserted.
"""
import argparse, glob, importlib.util, os, pathlib, re, struct, sys

REPO = pathlib.Path("/home/fsanches/compartilhado/kn5000-roms-disasm")
os.chdir(REPO); sys.path.insert(0, str(REPO))
MIN_RESOLVE = 0.90          # P1 floor
ROM_LO, ROM_HI = 0xE00000, 0x1000000
MIN_NONNULL = 0.98          # P3: share of NON-NULL words that must be in ROM range
MIN_P3_RESOLVE = 0.20       # P3: and they must resolve far above the 1.9% null


def nonnull_stats(words, syms):
    """P3. A NULL entry is legitimate content in a pointer table -- an empty
    slot -- but my P1/P2 tests counted every zero as a failure, which is how
    IconBitmapNamePtrTable (named as a pointer table by the sources) scored 69%
    'in range' when 177 of 177 NON-NULL words are in range and only the 79 nulls
    dragged it down. Score the non-null words alone."""
    nn = [w for w in words if w != 0]
    if len(nn) < 16:
        return None
    inr = sum(1 for w in nn if ROM_LO <= w < ROM_HI) / len(nn)
    res = sum(1 for w in nn if w in syms) / len(nn)
    return inr, res, len(nn), len(words) - len(nn)
MIN_STRUCT = 0.60           # P2 floor
NAKA_SIG = (0x00, 0x60, 0x01)   # bytes 1..3 of `naka_header <type>`
ROM = open("original_ROMs/kn5000_v7_program.rom", "rb").read()
BASE = 0xE00000


def struct_hits(words):
    """Fraction of targets carrying the naka_header record signature."""
    n = 0
    for w in words:
        o = w - BASE
        if 0 <= o < len(ROM) - 3 and tuple(ROM[o + 1:o + 4]) == NAKA_SIG:
            n += 1
    return n / max(1, len(words))

_s = importlib.util.spec_from_file_location(
    "cc", REPO / "scripts/converters/convert_corroborated_blocks.py")
cc = importlib.util.module_from_spec(_s); _s.loader.exec_module(cc)
_e = importlib.util.spec_from_file_location(
    "scan", REPO / "scripts/analysis/l3_embedded_structure_scan.py")
scan = importlib.util.module_from_spec(_e); _e.loader.exec_module(scan)
_t = importlib.util.spec_from_file_location(
    "tri", REPO / "scripts/analysis/l3_slice_structure_triage.py")
tri = importlib.util.module_from_spec(_t); _t.loader.exec_module(tri)

ELF = {"v7": "rebuilt_ROMs/kn5000_v7_program.llvm.elf",
       "v9": "rebuilt_ROMs/kn5000_v9_program.llvm.elf",
       "v10": "rebuilt_ROMs/kn5000_v10_program.llvm.elf"}
SYMS = {r: cc.elf_syms(p) for r, p in ELF.items() if os.path.exists(p)}


def rev_of(path):
    return next((r for r in ("v7", "v9", "v10") if r in str(path).split(os.sep)), None)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--controls", action="store_true",
                    help="measure the P1 and P2 nulls and exit")
    a = ap.parse_args()

    if a.controls:
        import random
        rng = random.Random(5)
        N = 200000
        # P2 null: how often does a RANDOM ROM offset carry the record
        # signature? This is the number that makes 82% mean something.
        hit = 0
        for _ in range(N):
            o = rng.randrange(0, len(ROM) - 4)
            if tuple(ROM[o + 1:o + 4]) == NAKA_SIG:
                hit += 1
        print(f"  P2 null  (random ROM offset carries {NAKA_SIG}) : "
              f"{100*hit/N:.3f}%   n={N:,}")
        # P1 null: how often does a uniform ROM-range address hit a symbol?
        v7 = SYMS.get("v7", {})
        hit2 = sum(1 for _ in range(N)
                   if rng.randrange(0xE00000, 0x1000000) in v7)
        print(f"  P1 null  (uniform ROM address hits a v7 symbol): "
              f"{100*hit2/N:.3f}%   n={N:,}  over {len(v7):,} symbols")
        # And the measured region, for the enrichment ratio.
        f = REPO / "v7/maincpu/includes/generated/naka_effects_seq.bin"
        if f.exists():
            b = open(f, "rb").read()
            w = [struct.unpack("<I", b[i:i + 4])[0] for i in range(0x6700, 0x7100, 4)]
            sh = struct_hits(w)
            print(f"\n  naka_effects_seq 0x006700: {100*sh:.0f}% of {len(w)} targets "
                  f"carry it  ->  enrichment {sh/max(1e-9,hit/N):.0f}x over the null")
            print(f"  words hitting a v7 symbol: "
                  f"{sum(1 for x in w if x in v7)}/{len(w)}"
                  f"   (P1 is blind here: the targets are blob interiors)")
        return 0

    # one .incbin site per (revision, basename)
    sites = {}
    for f in sorted(set(glob.glob("*/**/*.s", recursive=True))):
        rev = rev_of(f)
        try:
            txt = open(f, encoding="latin1").read()
        except OSError:
            continue
        # ⚠ Accept `.incbin "f"` AND `.incbin "f", skip, count`. Matching only
        # the bare form meant a blob became unreachable the moment its FIRST
        # region was converted -- 4,608 B across 12 blobs sat behind that.
        for m in re.finditer(r'^(\s*)\.incbin\s+"([^"]+)"(\s*,[^\n]*)?$', txt, re.M):
            sites.setdefault((rev, os.path.basename(m.group(2))), []).append(f)

    done = skipped = 0
    tot_bytes = tot_named = tot_words = 0
    for f in tri.blobs():
        b = open(f, "rb").read()
        if len(b) < scan.WIN:
            continue
        k, _ = tri.classify(b)
        if k != "OPAQUE":
            continue
        rev = rev_of(f)
        syms = SYMS.get(rev)
        if not syms:
            continue
        base = os.path.basename(str(f))
        where = sites.get((rev, base), [])
        if len(where) != 1:
            continue
        for s, e, kind in scan.scan(b):
            if kind != "PTR_TABLE" or e - s < 256:
                continue
            words = [struct.unpack("<I", b[i:i + 4])[0] for i in range(s, e - 3, 4)]
            if not words:
                continue
            named = sum(1 for w in words if w in syms)
            p1 = named / len(words) >= MIN_RESOLVE
            sh = struct_hits(words)
            p2 = sh >= MIN_STRUCT
            st = nonnull_stats(words, syms)
            p3 = bool(st and st[0] >= MIN_NONNULL and st[1] >= MIN_P3_RESOLVE)
            p4 = bool(st and st[1] >= 0.19)      # 10x the 1.9% null
            if not (p1 or p2 or p3 or p4):
                skipped += 1
                continue
            why = ("P1 symbol" if p1 else
                   f"P2 structure {100*sh:.0f}%" if p2 else
                   f"P3 non-null {100*st[0]:.0f}% in range, {100*st[1]:.0f}% resolve, "
                   f"{st[3]} nulls" if p3 else
                   f"P4 resolve {100*st[1]:.0f}% = {st[1]/0.019:.0f}x null")
            lines = []
            for w in words:
                lines.append(f"\t.long {syms[w]}" if w in syms
                             else f"\t.long 0x{w:08X}")
            # VERIFY IN PYTHON before touching the file: resolve the EMITTED
            # LINES back to bytes and compare with the blob.
            #
            # ⚠ The first version built this from `words`, which came from `b` --
            # so it compared b against b and could not fail. The check has to go
            # through the text actually being written, resolving each symbol
            # NAME through the ELF, or it tests nothing. (spec anti-pattern 10)
            addr_of = {n: ad for ad, n in syms.items()}
            emitted = b""
            bad = False
            for ln in lines:
                arg = ln.split(None, 1)[1].strip()
                if arg.startswith("0x"):
                    val = int(arg, 16)
                elif arg in addr_of:
                    val = addr_of[arg]
                else:
                    bad = True; break
                emitted += struct.pack("<I", val)
            if bad or emitted != b[s:s + 4 * len(words)]:
                print(f"  !! round-trip check FAILED for {base} 0x{s:06x} -- skipped")
                skipped += 1
                continue
            src = where[0]
            txt = open(src, encoding="latin1").read()
            end4 = s + 4 * len(words)
            # Find the .incbin SLICE that actually covers [s, end4) -- the file
            # may already carry several slices of this blob from an earlier pass.
            pat = re.compile(
                r'^([ \t]*)\.incbin\s+"([^"]*' + re.escape(base) + r')"'
                r'(?:[ \t]*,[ \t]*(0x[0-9A-Fa-f]+|\d+)[ \t]*,[ \t]*(0x[0-9A-Fa-f]+|\d+))?'
                r'[ \t]*$', re.M)
            m = None
            for cand in pat.finditer(txt):
                sk = int(cand.group(3), 0) if cand.group(3) else 0
                cnt = int(cand.group(4), 0) if cand.group(4) else len(b) - sk
                if sk <= s and end4 <= sk + cnt:
                    m = cand; sl_skip, sl_count = sk, cnt
                    break
            if m is None:
                skipped += 1
                continue
            ind, inc = m.group(1), m.group(2)
            new = []
            if s > sl_skip:                       # bytes before the table
                new.append(f'{ind}.incbin "{inc}", 0x{sl_skip:X}, 0x{s-sl_skip:X}')
            new.append(f'EmbeddedPtrTable_{rev}_{base.replace(".bin","")}_{s:06X}:')
            new += lines
            if end4 < sl_skip + sl_count:         # bytes after it
                new.append(f'{ind}.incbin "{inc}", 0x{end4:X}, '
                           f'0x{sl_skip+sl_count-end4:X}')
            print(f"  {base:40} 0x{s:06x}-0x{end4:06x} {len(words):4}w "
                  f"{named:4} named ({100*named//len(words):3}%)  [{why}]")
            tot_bytes += end4 - s; tot_named += named; tot_words += len(words)
            done += 1
            if a.apply:
                open(src, "w", encoding="latin1").write(
                    txt[:m.start()] + "\n".join(new) + txt[m.end():])
            break        # one region per blob per pass; re-run to continue

    print()
    print(f"  regions {'converted' if a.apply else 'convertible (DRY RUN)'} : {done}")
    print(f"  bytes                                : {tot_bytes:,}")
    if tot_words:
        print(f"  words resolved to a SYMBOL           : {tot_named}/{tot_words}"
              f"  ({100*tot_named//tot_words}%)")
    print(f"  regions below the {int(100*MIN_RESOLVE)}% resolve floor  : {skipped}")
    if not a.apply:
        print("\n  dry run -- nothing written. Re-run with --apply.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
