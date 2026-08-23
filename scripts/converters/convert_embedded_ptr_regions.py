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
"""
import argparse, glob, importlib.util, os, pathlib, re, struct, sys

REPO = pathlib.Path("/home/fsanches/compartilhado/kn5000-roms-disasm")
os.chdir(REPO); sys.path.insert(0, str(REPO))
MIN_RESOLVE = 0.90

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
    a = ap.parse_args()

    # one .incbin site per (revision, basename)
    sites = {}
    for f in sorted(set(glob.glob("*/**/*.s", recursive=True))):
        rev = rev_of(f)
        try:
            txt = open(f, encoding="latin1").read()
        except OSError:
            continue
        for m in re.finditer(r'^(\s*)\.incbin\s+"([^"]+)"\s*$', txt, re.M):
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
            if named / len(words) < MIN_RESOLVE:
                skipped += 1
                continue
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
            pat = re.compile(r'^([ \t]*)\.incbin\s+"([^"]*' + re.escape(base) + r')"[ \t]*$', re.M)
            m = pat.search(txt)
            if not m:
                skipped += 1
                continue
            ind, inc = m.group(1), m.group(2)
            end4 = s + 4 * len(words)
            new = [f'{ind}.incbin "{inc}", 0, 0x{s:X}',
                   f'EmbeddedPtrTable_{rev}_{base.replace(".bin","")}_{s:06X}:']
            new += lines
            if end4 < len(b):
                new.append(f'{ind}.incbin "{inc}", 0x{end4:X}, 0x{len(b)-end4:X}')
            print(f"  {base:44} 0x{s:06x}-0x{end4:06x}  "
                  f"{len(words):4} words, {named} named ({100*named//len(words)}%)")
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
