#!/usr/bin/env python3
"""census_stale_markers.py -- declare the WSA1 tables that are not this build's entry points to the dispatch census.

QUESTION IT ANSWERS
  On 2026-10-06 every KN5000 image of the dispatch-table census (scripts/analysis/dispatch_table_census) was
  all-zero.  WSA1 still had 11 tables counted not used, and each of them is already documented in the source as
  dead or older-build:
    prom_a  AddrTable_F8E77C, AddrTable_F8E7A9         no reader; several targets mid-instruction
            ParamModule_PhaseVector_StaleCopy          the stale copy of the param module's phase vector
    prom_b  PtrTable_F00340, PtrTable_F00762,          the orphaned older-build PITCH module and its arrays,
            PtrArray_F00C4E, PtrArray_F014EE           whose prom_a targets are another build's
                                                       (FINDINGS-prom_b-f00c4d-orphan-cluster.md)
            OldBuild_DLHandlerTables_Tail,             an older build's display-list data, live - 0x23000/1
            OldBuild_ValueGlyph_Table
            routine directory: T_F41184 group, T_F42FD0 group   stale thunk slots (mid-instruction / into display lists)
    prom_c  UNREFERENCED_TRAMPOLINES                   unreferenced, every target mid-instruction
  No label can make such a table used, and a label at one of its targets would be wrong: it would plant an
  entry point inside an instruction, or from a coincidence.  The census's STALE rule (census.py docstring) takes
  such a group out of NOT only when it is declared by a `; census: stale -- <why>` line and two checks hold: at
  least one target lands where no live entry can, and the distinct targets hit instruction starts no more often
  than chance.  This script writes the declarations: one comment line each, appended to the comment block nearest
  above the table's first entry (or above the first stale directory slot).  Nothing is deleted or reworded.  The
  why text restates evidence already in that block; the census does its own checks and lists every group.
  ⚠ The why text avoids data_range_census.py's ADMISSIONS phrases ("no reader" ...): a marker is a positive
  finding (nothing reads it), and on 2026-10-06 a first wording with "no reader" moved 49 B of prom_a KNOWN-A -> B.

RUN (from wsa1/)
  python3 notes/census_stale_markers.py            # where each marker would go
  python3 notes/census_stale_markers.py --apply    # insert them (idempotent)
  then, from the repository root:
  python3 scripts/analysis/dispatch_table_census/census.py --stale prom_b   (and prom_a, prom_c)
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# (file, anchor: the line the marker's block must sit directly above, after skipping non-comment lines, marker text)
MARKERS = [
    ("prom_a/wsa1_prom_a.s", "AddrTable_F8E77C:",
     "; census: stale -- nothing in the image reads it, and 5 of its 8 targets are mid-instruction, where no live entry "
     "can land."),
    ("prom_a/wsa1_prom_a.s", "\t.byte 0x6e, 0xf7, 0x0e, 0x07 ",
     "; census: stale -- AddrTable_F8E7A9 below: nothing in the image reads it, and 2 of its 9 targets are "
     "mid-instruction."),
    ("prom_a/wsa1_prom_a.s", "ParamModule_PhaseVector_StaleCopy:",
     "; census: stale -- nothing reaches this copy (no directory slot names it); 4 of its 5 targets are now mid-instruction."),
    ("prom_b/wsa1_prom_b.s", "PtrTable_F00340:",
     "; census: stale -- read only inside the orphaned older-build PITCH module (sub_F00D65); its 0xFDB10E slots are that "
     "build's prom_a stub, mid-instruction here (notes/FINDINGS-prom_b-f00c4d-orphan-cluster.md)."),
    ("prom_b/wsa1_prom_b.s", "PtrTable_F00762:",
     "; census: stale -- nothing in the image reads it; its sentinel 0xFDB10E is the older build's stub (PtrTable_F00340), and 6 of its 21 "
     "distinct targets land on instruction starts, chance level."),
    ("prom_b/wsa1_prom_b.s", "\t.byte\t0x00\t; F00C4D  high byte of the pointer at 0xF00C4A",
     "; census: stale -- the orphaned older-build module's array: its targets are that build's prom_a "
     "(notes/FINDINGS-prom_b-f00c4d-orphan-cluster.md, N2)."),
    ("prom_b/wsa1_prom_b.s", "PtrArray_F014EE:",
     "; census: stale -- the same module's 196-slot array; its targets are that build's prom_a (FINDINGS N2: 58 of 155 on "
     "an instruction start, and no constant offset fixes it)."),
    ("prom_b/wsa1_prom_b.s", "OldBuild_DLHandlerTables_Tail:",
     "; census: stale -- each entry is an older build's handler address (live - 0x23000 / - 0x23001); nothing reads it "
     "(notes/promb-2026-09-25/stale_dl_tables_f0ed50.py)."),
    ("prom_b/wsa1_prom_b.s", "OldBuild_ValueGlyph_Table:",
     "; census: stale -- ValueGlyph_Table - 0x23001, the older build's glyph pointers; nothing in this build indexes it."),
    ("prom_b/wsa1_prom_b.s", "T_F41184:\tjp 0xFC0427 ",
     "; census: stale -- T_F41184, T_F4118C and T_F41190-T_F41198 (the live slots between them still count as live)."),
    ("prom_b/wsa1_prom_b.s", "T_F42FD0:\tjp DL_CombinationNaming_F19BE5 + 0x33 ",
     "; census: stale -- the thirteen slots below."),
    ("prom_c/boot/reset_and_vectors.s", "UNREFERENCED_TRAMPOLINES:",
     "; census: stale -- unreferenced, and every target is mid-instruction (above)."),
]


def main():
    files = {}
    for rel, anchor, text in MARKERS:
        L = files.setdefault(rel, open(os.path.join(ROOT, rel), "rb").read().decode("latin-1").split("\n"))
        hits = [i for i, x in enumerate(L) if x.startswith(anchor)]
        assert len(hits) == 1, (rel, anchor, len(hits))
        k = hits[0]
        assert L[k - 1].lstrip().startswith(";"), (rel, anchor, "no comment block directly above")
        j = k
        while L[j - 1].lstrip().startswith(";"):
            j -= 1
        if text in L[j:k]:
            print("present  %-32s %s" % (rel, anchor.strip()[:50]))
            continue
        print("insert   %-32s above line %d  %s" % (rel, k + 1, anchor.strip()[:50]))
        if "--apply" in sys.argv:
            L[k:k] = [text]
    if "--apply" in sys.argv:
        for rel, L in files.items():
            p = os.path.join(ROOT, rel)
            data = "\n".join(L).encode("latin-1")
            with open(p + ".tmp", "wb") as fh:
                fh.write(data)
            os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
