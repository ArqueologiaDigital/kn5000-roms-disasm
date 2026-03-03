#!/usr/bin/env python3
"""
rename_hama_code_labels.py — Rename LABEL_* symbols in hama_code.s
                               (and cross-references in kn5000_v10_program.s)

All 39 LABEL_* symbols defined in hama_code.s are replaced with descriptive
names.  Three of those symbols are also referenced from kn5000_v10_program.s:

    LABEL_F1E9A3  →  GetAprStatus_Entry      (called at lines 231347, 234229, 234246)
    LABEL_F1E9D0  →  CallExtIfActive_Entry   (called at line  44612)
    LABEL_F1E9E0  →  LoadAndRunXapr_Entry    (jumped-to at line 326407)

The script uses binary I/O throughout.  hama_code.s contains 27 non-ASCII
bytes (UTF-8 em-dashes in comments); treating the file as raw bytes guarantees
those are preserved unchanged.  kn5000_v10_program.s contains Latin-1 encoded
strings and must likewise be handled as bytes.

All renames are performed as plain byte-string substitutions — no parsing.

Usage:
    python3 scripts/rename_hama_code_labels.py [--dry-run]

Options:
    --dry-run   Print every substitution that would be made, but do not write
                any files.
"""

import sys
import os

# ---------------------------------------------------------------------------
# Rename map: LABEL_old  →  new_name
# ---------------------------------------------------------------------------
RENAMES = {
    # TestTitleFunc internals (event 0x1C00013 / 0x1C00007 dispatch)
    "LABEL_F1E3DA": "TitleFunc_ActionDispatch",      # Action dispatch table body (event 0x1C00013, xde=2..6)
    "LABEL_F1E41C": "TitleFunc_LifecycleDispatch",   # Lifecycle event handler branch (event 0x1C00007)
    "LABEL_F1E43B": "TitleFunc_LifecycleTable",      # Lifecycle dispatch table body (xde=0..6)
    "LABEL_F1E4BD": "TitleFunc_Return",              # Common exit: hl=0, pop xiz, ret

    # ListDir2 — second directory-listing function (ListDirectoryEntries2)
    "LABEL_F1E4C1": "ListDir2_Entry",                # Function entry: open dir, iterate entries
    "LABEL_F1E4E2": "ListDir2_LogEntry",             # Dir opened OK; log first entry
    "LABEL_F1E4F7": "ListDir2_NextEntry",            # Loop: read and log next entry
    "LABEL_F1E50C": "ListDir2_CloseDir",             # All entries read; close directory handle
    "LABEL_F1E514": "ListDir2_Return",               # Function exit: pop xiz, restore xsp, ret

    # RunTestCounters — check FD status, run test, update TOTAL/OK/NG counters
    "LABEL_F1E51B": "RunTestCounters_Entry",         # Function entry: call 0xF525EC for FD status
    "LABEL_F1E527": "RunTestCounters_RunTest",       # Status 2 or 3: increment TOTAL, run FDLoadSaveTest
    "LABEL_F1E53A": "RunTestCounters_BadStatus",     # Status neither 2 nor 3: return l=0xFF
    "LABEL_F1E53D": "RunTestCounters_IncrNG",        # Test failed: increment NG counter
    "LABEL_F1E542": "RunTestCounters_Display",       # Display TOTAL/OK/NG via NAKA widget (shared exit)

    # CreateRunFDOp — build stack param struct, execute FD operation via 0xF97CCA
    "LABEL_F1E589": "CreateRunFDOp_Entry",           # Function entry: allocate 16-byte stack frame
    "LABEL_F1E5CE": "CreateRunFDOp_Fail",            # Operation returned non-zero (failure): print fail msg
    "LABEL_F1E5D6": "CreateRunFDOp_Return",          # Common exit: restore xsp, ret

    # RegisterHamaTitle1 / RegisterHamaTitle2 — register titles with the NAKA widget system
    "LABEL_F1E89A": "RegHamaTitle1_Entry",           # Register widget table 0x7F (FDD/HD ext test)
    "LABEL_F1E8AC": "RegHamaTitle2_Entry",           # Register widget table 0xFC (extension APR test)

    # SendEvent — send event 0x1C00025 with parameter via 0xFA9660
    "LABEL_F1E8BE": "SendEvent_Entry",               # Function entry: ld xde,xwa; jp 0xFA9660

    # HamaEvtDisp — top-level event dispatcher for HAMA subsystem
    "LABEL_F1E8CE": "HamaEvtDisp_Entry",             # Function entry: check xbc for 0x1C00007 / 0x1E00085
    "LABEL_F1E8E1": "HamaEvtDisp_LifecycleCheck",   # Event 0x1C00007: check xde for 0x8A / 0x8B
    "LABEL_F1E906": "HamaEvtDisp_ExtBootstrap",      # xde=0x8B: send bootstrap events, call LoadExtROM_Entry
    "LABEL_F1E919": "HamaEvtDisp_Return",            # Common exit: hl=0, ret

    # CheckFDStatusLoad — check FD status; load file into extension DRAM if ready
    "LABEL_F1E91C": "CheckFDStatusLoad_Entry",       # Function entry: call 0xF525EC, check status 2/3
    "LABEL_F1E935": "CheckFDStatusLoad_DoLoad",      # Status 2 or 3: open file handle via 0xF4EB97
    "LABEL_F1E957": "CheckFDStatusLoad_Transfer",    # Handle valid: transfer file data to DRAM 0x200000
    "LABEL_F1E970": "CheckFDStatusLoad_Return",      # Function exit: pop xiz, ret

    # LoadExtROM — load 4 bytes from extension ROM path into DRAM 0x200000, jump to entry point
    "LABEL_F1E972": "LoadExtROM_Entry",              # Function entry: push path/dest args, call 0xFF0CC1
    "LABEL_F1E997": "LoadExtROM_JumpEntry",          # Load succeeded (hl=0): jp (xhl) at 0x200008

    # GetAprStatus — read APR presence/status byte at 0x03DD04
    # Cross-referenced from kn5000_v10_program.s (3 calls)
    "LABEL_F1E9A3": "GetAprStatus_Entry",            # Function entry: ld8_24 l, 0x03DD04; ret

    # LoadXaprInit — load "XAPR" magic from extension ROM into 0x280000; set presence flag
    "LABEL_F1E9A9": "LoadXaprInit_Entry",            # Function entry: call 0xFF0CC1 with XAPR path args

    # Stub functions — empty (single ret) placeholders
    "LABEL_F1E9CD": "HamaStub1_Entry",               # Stub: ret (first of three consecutive stubs)
    "LABEL_F1E9CE": "HamaStub2_Entry",               # Stub: ret
    "LABEL_F1E9CF": "HamaStub3_Entry",               # Stub: ret

    # CallExtIfActive — dispatch to extension code at 0x280010 if APR flag set
    # Cross-referenced from kn5000_v10_program.s (main loop, 1 call)
    "LABEL_F1E9D0": "CallExtIfActive_Entry",         # Function entry: cpi8_24 0x03DD04, 0; call (xhl) if set

    # LoadAndRunXapr — load "XAPR" from alternate path and call extension at 0x280008
    # Cross-referenced from kn5000_v10_program.s (reset path, 1 jp)
    "LABEL_F1E9E0": "LoadAndRunXapr_Entry",          # Function entry: call 0xFF0CC1 with second XAPR path
    "LABEL_F1EA05": "LoadAndRunXapr_ClearFlag",      # Load failed: sti8_24 0x03DD04, 0
    "LABEL_F1EA0B": "LoadAndRunXapr_CallIfActive",   # Check flag; call (xhl=0x280008) with entry addr if set
}

# ---------------------------------------------------------------------------
# Files to update
# ---------------------------------------------------------------------------
ROMS_DISASM = "/mnt/shared/kn5000-roms-disasm"

FILES = [
    # Primary file — contains all 39 definitions plus internal references
    os.path.join(ROMS_DISASM, "maincpu/hama/hama_code.s"),
    # Top-level program file — references 3 of the 39 labels
    os.path.join(ROMS_DISASM, "maincpu/kn5000_v10_program.s"),
]

# Labels that are cross-referenced outside hama_code.s (sanity documentation)
CROSS_REFERENCED = {
    "LABEL_F1E9A3",   # GetAprStatus_Entry    — kn5000_v10_program.s:231347,234229,234246
    "LABEL_F1E9D0",   # CallExtIfActive_Entry — kn5000_v10_program.s:44612
    "LABEL_F1E9E0",   # LoadAndRunXapr_Entry  — kn5000_v10_program.s:326407
}


def rename_in_bytes(data: bytes, old: str, new: str) -> tuple[bytes, int]:
    """Replace all occurrences of *old* (ASCII) with *new* (ASCII) in *data*.

    Returns (new_data, count_of_replacements).
    """
    old_b = old.encode("ascii")
    new_b = new.encode("ascii")
    count = data.count(old_b)
    return data.replace(old_b, new_b), count


def process_file(path: str, renames: dict, dry_run: bool) -> None:
    print(f"\n{'[DRY RUN] ' if dry_run else ''}Processing: {path}")

    with open(path, "rb") as fh:
        original = fh.read()

    data = original
    total_replacements = 0

    for old, new in renames.items():
        data, count = rename_in_bytes(data, old, new)
        if count:
            marker = " [CROSS-REF]" if old in CROSS_REFERENCED else ""
            print(f"  {old:30s} -> {new:35s}  ({count} occurrence{'s' if count != 1 else ''}){marker}")
            total_replacements += count

    if total_replacements == 0:
        print("  (no matching labels found — file skipped)")
        return

    print(f"  Total replacements: {total_replacements}")

    if not dry_run:
        with open(path, "wb") as fh:
            fh.write(data)
        print(f"  Written: {path}")
    else:
        print(f"  [DRY RUN] Would write {len(data)} bytes to {path}")


def main() -> None:
    dry_run = "--dry-run" in sys.argv

    if dry_run:
        print("=== DRY RUN — no files will be modified ===")

    print(f"Rename map: {len(RENAMES)} labels")
    print(f"Cross-referenced labels (appear in multiple files): {len(CROSS_REFERENCED)}")

    for path in FILES:
        if not os.path.exists(path):
            print(f"\nWARNING: file not found, skipping: {path}")
            continue
        process_file(path, RENAMES, dry_run)

    print("\nDone.")
    if dry_run:
        print("Re-run without --dry-run to apply changes.")


if __name__ == "__main__":
    main()
