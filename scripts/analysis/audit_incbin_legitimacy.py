#!/usr/bin/env python3
"""audit_incbin_legitimacy.py -- is every .incbin in this tree a JUSTIFIED one?

QUESTION ANSWERED: §3 of DISASSEMBLY-COMPLETENESS-SPEC.md says a binary include is legitimate
only when the bytes have no better human-readable representation. This checks that claim instead
of leaving it to memory, and FAILS if an unclassified include appears.

Categories, and why each is legitimate:

    generated/ or romslices/   built by a committed generator, or a committed slice that is
                               honestly documented as having no source (v7's 288)
    demo_preset / help_db      compressed streams whose codec has a committed DECODER **and**
                               ENCODER and rebuilds byte-exactly
    images/                    rebuilt from a committed PNG or palette text by one of the
                               round-trip converters in scripts/build/
    section_*                  style banks rebuilt from committed .styles event listings
    FTBMP                      genuine Windows BMP files, stored verbatim by the firmware
    icons_to_strings.bin       two SLIDE8K-compressed remnants (the stale German help DB, and
                               the copy of the English DB's tail that style_records.s calls
                               residue) -- compressed, documented, legitimately opaque

TWO METHODOLOGY TRAPS, both hit while writing this, both worth keeping:

  * `.incbin` also appears inside COMMENTS -- this tree deliberately keeps `; Was: .incbin ...`
    lines recording what a directive used to be. Counting raw matches reports ten hdae5000
    includes that do not exist.
  * a directive is frequently written on a LABEL LINE (`Font0_Glyphs:\t.incbin "..."`), so a
    regex anchored at line start misses 382 of the 873.

    python3 scripts/analysis/audit_incbin_legitimacy.py
"""
import os
import pathlib
import re
import sys
from collections import Counter

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
INC = re.compile(r'\.incbin\s+"([^"]+)"')
RULES = [
    (('generated/', 'romslices/'), 'generated or committed no-source slice'),
    (('demo_preset', 'help_db'), 'compressed, codec has a committed encoder'),
    (('FTBMP',), 'genuine Windows BMP stored verbatim'),
    (('images/',), 'rebuilt from a committed PNG or palette text'),
    (('section_',), 'style bank rebuilt from committed .styles'),
    (('icons_to_strings.bin',), 'SLIDE8K remnant, compressed and documented'),
]


def main():
    rows, kind, other = [], Counter(), []
    for s in REPO.rglob('*.s'):
        rel = s.relative_to(REPO).as_posix()
        if rel.startswith('archive/'):
            continue
        for line in s.read_bytes().decode('latin1').splitlines():
            if line.lstrip().startswith(';'):
                continue                      # a comment is not a directive
            m = INC.search(line)              # NOT match(): labels precede the directive
            if not m:
                continue
            p = m.group(1)
            rows.append((rel, p))
            for keys, label in RULES:
                if any(k in p for k in keys):
                    kind[label] += 1
                    break
            else:
                other.append((rel, p))
    print(f"active .incbin directives outside archive/: {len(rows)}\n")
    for k, v in kind.most_common():
        print(f"  {v:4d}  {k}")
    if other:
        print(f"\n*** {len(other)} UNCLASSIFIED -- each must be justified under §3 or converted:")
        for f, p in sorted(set(other)):
            print(f"    {f}: {p}")
        sys.exit(1)
    print("\nEvery include falls in a justified category: 0 illegitimate blob bytes.")

    # ------------------------------------------------------------------
    # ⚠ THE CATEGORY TEST ABOVE CANNOT FAIL FOR MOST INCLUDES, so on its own it
    # is bookkeeping, not a measurement. `generated/` and `romslices/` justify
    # 741 of 824 directives by the DIRECTORY THE FILE SITS IN. Nothing about the
    # bytes is examined, and §3's own second clause -- "with its format
    # documented" -- was never tested at all.
    #
    # That blindness was real and cost real bytes: 61 blobs holding 8,440 B of
    # ROM ADDRESSES sat inside the passing category until a separate tool went
    # looking. `.long <symbol>` is strictly the better form for those, and it
    # exposes the call graph as a side effect.
    #
    # So the audit now runs the structure triage and FAILS on any blob still
    # carrying pointer-table structure. Only PTR_TABLE is enforced, because it
    # is the only class that survives the byte-shuffle control -- WORD_TABLE,
    # SPARSE and TEXT are byte-frequency artefacts and would be false alarms.
    # See scripts/analysis/l3_slice_structure_triage.py.
    # ------------------------------------------------------------------
    import importlib.util
    tri = os.path.join(REPO, "scripts", "analysis", "l3_slice_structure_triage.py")
    spec = importlib.util.spec_from_file_location("_triage", tri)
    mod = importlib.util.module_from_spec(spec)
    saved, sys.argv = sys.argv, [tri]
    try:
        spec.loader.exec_module(mod)
    finally:
        sys.argv = saved

    # These are PROVEN not to be pointer tables and are allowed to keep scoring
    # as one; each needs its reason, so the exemption cannot be used as a dump.
    KNOWN_NOT_TABLES = {
        "sound_data_organ_accordion.bin":
            "16-bit drawbar table: u16 pairs 0x00f0,0x00f0 read as u32 0x00f000f0, "
            "which lands in ROM range by coincidence. Also compiler output from a committed .c.",
        "v7_transplant_FlashWrite_BlockRef_Type3.bin":
            "5 words, only 2 exact symbol hits -- not significant against symbol density.",
        "v7_transplant_FlashWrite_BlockRef_Type4.bin":
            "5 words, only 2 exact symbol hits -- not significant against symbol density.",
    }
    offenders = []
    for f in mod.blobs():
        k, why = mod.classify(f.read_bytes())
        if k != "PTR_TABLE":
            continue
        if os.path.basename(str(f)) in KNOWN_NOT_TABLES:
            continue
        offenders.append((f, why))

    print(f"\nstructure check: {len(offenders)} blob(s) still hold pointer-table structure")
    if offenders:
        print("*** these have a BETTER FORM available (`.long <symbol>`) and are NOT justified")
        print("*** convert with scripts/converters/convert_v7_ptr_tables.py --apply")
        for f, why in sorted(offenders, key=lambda r: str(r[0])):
            print(f"    {f}   [{why}]")
        sys.exit(1)
    print("and none of them carries a structure a better format would expose.")
    # PROOF THAT THIS CHECK CAN FAIL (2026-08-22), because a passing check whose
    # failure has never been observed is worth nothing -- that is the whole
    # lesson of this file. Run the audit against the tree as it stood BEFORE the
    # pointer tables were converted:
    #
    #     git worktree add --detach /tmp/wt 056a9a1^
    #     cp scripts/analysis/audit_incbin_legitimacy.py \
    #        scripts/analysis/l3_slice_structure_triage.py /tmp/wt/scripts/analysis/
    #     cd /tmp/wt && python3 scripts/analysis/audit_incbin_legitimacy.py; echo $?
    #
    # It EXITS 1 and names the offenders (UIState_HandlerTable_*, Naka_*_Table,
    # VoiceParam_ModeDispatch_Table, ...). The category test above passes on that
    # same tree, which is exactly the blindness this section was added to remove.


if __name__ == '__main__':
    main()
