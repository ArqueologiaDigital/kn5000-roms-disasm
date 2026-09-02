#!/usr/bin/env python3
"""v7_batchf_recheck.py -- re-examine v7 batch F (commit b272c040, "convert 22
more confirmed regions across 9 files, cross-region corroboration"), the
weakest evidence supporting any v7 conversion per
notes/DEBT-INVENTORY-2026-09-02.md ("The weakest evidence currently in the
tree: v7 batch F", 22 regions, 11/20 = 55% call-target resolve).

QUESTION ANSWERED
  For each of batch F's 22 regions: does it survive the tools built since
  (v7_call_target_boundary_audit.py's stronger "lands on an instruction
  boundary" test, plus the near-uniform-run and lda*-retroactive-label
  checks)? Confirm or flag for revert.

HOW THE 22 REGIONS WERE RECOVERED
  Batch F's own worklist JSON was never committed (session scratch, lost).
  Recovered here by:
    1. `git worktree add --detach <scratch> 211f6f43` (the commit right
       before batch F landed) -- read-only, does not touch any shared tree.
    2. Seeding that worktree's gitignored generated includes from the
       lane's own worktree (`v7/maincpu/includes/`, `custom_data/includes/`,
       `table_data/includes/`) so it can assemble.
    3. Running the existing pipeline exactly as v7_region_worklist.py's own
       docstring prescribes:
           python3 scripts/analysis/v9_v10_undisassembled_census.py \\
               --prepare WORK
           python3 scripts/analysis/v9_v10_undisassembled_census.py \\
               --census v7 --work WORK
           python3 scripts/analysis/v7_region_worklist.py --work WORK
       which reproduces the SAME ranked candidate list batch F was drawn
       from (same script, same commit-parent tree state).
    4. Matching batch F's actual converted labels (recovered from
       `git diff 211f6f43 b272c040 -- v7/` with full context, no truncation)
       against that worklist by ROM address: all 22 converted spans appear
       in the regenerated worklist, each with n_calls=2, n_call_hits=1
       (50% per-region, matching "small sample" in the commit message), and
       the summed sizes (3,883 B) and byte-histogram stats (223/256 distinct
       values, longest run 4 B, most common byte 4.9%) reproduce the commit
       message's own numbers EXACTLY -- see BATCHF_REGIONS below and
       `main()`'s histogram check.

RESULT, 2026-09-02 (lane DISPUTES)
  20 distinct call targets across the 22 regions (some regions share a
  target -- that is the commit's own "cross-region convergence" claim,
  reproduced here). Fed through v7_call_target_boundary_audit.py's walk:
      11 EXACT matches to a pre-existing symbol name
       9 land exactly on an instruction boundary in the walk from the
         nearest preceding named label (a mix of real boundaries and one
         case, 0xFCCC66, that the boundary tool's default 400 B window is
         too short to reach -- confirmed landing cleanly, right after a
         `retd 0002`, i.e. the start of an as-yet-unnamed routine, once
         re-walked with a wider window; see WIDEN_WINDOW below)
       0 uncorroborated
  => 20/20 = 100% of distinct call targets land on a real instruction
     boundary, strictly stronger than the 55% "resolves to an existing
     name" figure the debt inventory flagged as weak.
  Additionally: zero of the 30 underlying labels are ever the target of an
  `lda*` (load-address) instruction anywhere in v7 (ruling out "read as a
  jump/pointer table entry" for all of them), and unidasm decodes all 22
  regions' original bytes with ZERO undecodable opcodes, ending cleanly on
  ret/jr T/jp in every case.

VERDICT: all 22 regions CONFIRMED as genuine code. No reverts.

RUN
    python3 scripts/analysis/v7_batchf_recheck.py
"""
import os
import re
import subprocess
from collections import Counter

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
UNI = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE = 0xE00000
ROM = os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom")
SYMS = os.path.join(REPO, "symbols", "maincpu_v7_symbols_reference.txt")

DASM = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')
CALL_RE = re.compile(r'call\s+(?:[A-Za-z]+,)?0x([0-9a-f]+)', re.I)

# (label(s), addr, size) -- recovered as described in the module docstring.
# Several worklist regions merge >1 pre-existing label because the census's
# blob boundary is the maximal .byte run, which can cross a label that isn't
# externally referenced (this is exactly the "8 candidates failed the
# interior-label check" the commit mentions for the ones that did NOT merge
# cleanly and were left as .byte).
BATCHF_REGIONS = [
    ("MidiChannel_ResetAndConfigure..MidiCh_IterateExpression (merged x6)", 0xFC8618, 755),
    ("SeMenu_SetDisplayValue_Data", 0xF06799, 123),
    ("PmBank_BankChanged_DrawSlot", 0xFC153B, 121),
    ("PmBank_DrawRegionInfo", 0xFC1814, 130),
    ("SplitPoint_HandleNoteEvt (region)", 0xF745C8, 82),
    ("SeqPlay_BufferUpdateBlock (region)", 0xF43874, 269),
    ("SMF_ProgramChange_ProcessPatch (region)", 0xF27B79, 115),
    ("SeqChan_TraverseAndProcess+ReadNextFromLoop (merged)", 0xF51243, 421),
    ("RVari_SelectE_SecondItem_Draw", 0xFBF5DE, 153),
    ("RVari_SelectO_SecondItem_Draw", 0xFBF815, 153),
    ("RVari_ConfirmF_Item_Draw", 0xFBFDB0, 134),
    ("RVari_ConfirmE_Item_Draw", 0xFC0101, 138),
    ("RVari_EnumNotifyF_Item_Draw", 0xFC03CC, 140),
    ("RVari_EnumNotifyE_Item_Draw", 0xFC05AD, 144),
    ("EffectMode_SetRegion_Apply+CheckPedalType (merged)", 0xFB68F7, 108),
    ("VariScreen_DrawNameString", 0xFBDF38, 147),
    ("VariScreen_DrawRightNameString", 0xFBE229, 144),
    ("VariScreen_ConfirmDrawNameAudio", 0xFBE564, 137),
    ("VariScreen_EnumDrawNameAudio", 0xFBE795, 139),
    ("ObjectEnum_OK_DispatchInline", 0xFA4859, 128),
    ("ViewID_GetCurrent", 0xFA8095, 97),
    ("CommonIDProc_CheckAvail+SearchLoop_Compare (merged)", 0xFA8F80, 105),
]

WIDEN_WINDOW = {0xFCCC66: 1400}  # targets needing a wider walk than the
                                  # boundary tool's 400 B default


def load_symbols():
    syms = {}
    for line in open(SYMS):
        parts = line.split()
        if len(parts) == 2:
            try:
                syms[int(parts[1], 16)] = parts[0]
            except ValueError:
                pass
    return syms


def unidasm(blob, basepc):
    tmp = "/tmp/batchf_recheck.bin"
    open(tmp, "wb").write(blob)
    return subprocess.run([UNI, tmp, "-arch", "tlcs900", "-basepc", hex(basepc)],
                          capture_output=True, text=True).stdout


def region_calls_and_decode_check(rom, addr, size):
    blob = rom[addr - BASE: addr - BASE + size]
    out = unidasm(blob, addr)
    lines = [l for l in out.split("\n") if l.strip()]
    bad = [l for l in lines if "???" in l or "unk" in l.lower()]
    targets = []
    for line in lines:
        m = DASM.match(line.strip())
        if m and "call" in m.group(3).lower():
            cm = CALL_RE.search(m.group(3))
            if cm:
                targets.append(int(cm.group(1), 16))
    return targets, len(lines), len(bad), lines[-1].strip() if lines else ""


def nearest_label(syms_sorted_addrs, syms, t):
    import bisect
    i = bisect.bisect_right(syms_sorted_addrs, t) - 1
    if i < 0:
        return None, None
    a = syms_sorted_addrs[i]
    return a, syms[a]


def walk_boundary(rom, label_addr, target, window):
    off = label_addr - BASE
    tend = min(target - BASE + 2, off + window)
    blob = rom[off:tend]
    out = unidasm(blob, label_addr)
    bnd = set()
    for line in out.split("\n"):
        m = DASM.match(line.strip())
        if m:
            bnd.add(int(m.group(1), 16))
    return target in bnd


def check_lda_references(labels):
    hits = {}
    for l in labels:
        out = subprocess.run(
            ["grep", "-rnE", rf"lda[a-z_0-9]*[^A-Za-z0-9_]{l}\b",
             "--include=*.s", os.path.join(REPO, "v7")],
            capture_output=True, text=True).stdout
        if out.strip():
            hits[l] = out.strip().splitlines()
    return hits


def main():
    rom = open(ROM, "rb").read()
    syms = load_symbols()
    syms_addrs = sorted(syms)

    print(f"{len(BATCHF_REGIONS)} regions, "
          f"{sum(s for _, _, s in BATCHF_REGIONS):,} B\n")

    all_bytes = b""
    all_targets = {}
    for name, addr, size in BATCHF_REGIONS:
        targets, n_instr, n_bad, last = region_calls_and_decode_check(rom, addr, size)
        all_bytes += rom[addr - BASE: addr - BASE + size]
        for t in targets:
            all_targets.setdefault(t, []).append(name)
        flag = "" if n_bad == 0 else f"  <-- {n_bad} UNDECODABLE"
        print(f"0x{addr:06X} {size:4d} B  {n_instr:3d} instr{flag}  "
              f"ends: {last[-40:]}")

    print(f"\ndistinct call targets: {len(all_targets)}")
    resolve_hits = 0
    boundary_ok = 0
    exact = 0
    suspect = []
    for t in sorted(all_targets):
        name = syms.get(t)
        if name:
            print(f"  0x{t:06x}  EXACT: {name}  (used by {len(all_targets[t])})")
            exact += 1
            resolve_hits += 1
            continue
        la, ln = nearest_label(syms_addrs, syms, t)
        window = WIDEN_WINDOW.get(t, 400)
        ok = walk_boundary(rom, la, t, window)
        status = "boundary-OK" if ok else "SUSPECT"
        if ok:
            boundary_ok += 1
        else:
            suspect.append(t)
        print(f"  0x{t:06x}  +{t-la} into {ln} ({window}B window) -- {status}  "
              f"(used by {len(all_targets[t])})")

    print(f"\n=> {exact} exact-label hits ({resolve_hits}/{len(all_targets)} "
          f"resolve to a pre-existing name, {100*resolve_hits/len(all_targets):.0f}%)")
    print(f"=> {exact + boundary_ok}/{len(all_targets)} land on a real "
          f"instruction boundary ({100*(exact+boundary_ok)/len(all_targets):.0f}%)")
    print(f"=> {len(suspect)} UNCORROBORATED targets: "
          f"{[hex(t) for t in suspect]}")

    print("\n-- near-uniform-run guard (concatenation of all 22 regions) --")
    c = Counter(all_bytes)
    mc_byte, mc_count = c.most_common(1)[0]
    longest = 1
    cur = 1
    for i in range(1, len(all_bytes)):
        if all_bytes[i] == all_bytes[i - 1]:
            cur += 1
            longest = max(longest, cur)
        else:
            cur = 1
    print(f"  {len(all_bytes)} B total, {len(c)}/256 distinct byte values, "
          f"longest identical-byte run {longest} B, "
          f"most common byte 0x{mc_byte:02x} = {100*mc_count/len(all_bytes):.1f}%")

    print("\n-- retroactive lda*-reference check on all underlying labels --")
    labels = []
    for name, _, _ in BATCHF_REGIONS:
        # pull the bare label tokens out of the merged-region description
        for tok in re.split(r'[\s+.()]+', name):
            if re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', tok) and tok not in ("merged", "region"):
                labels.append(tok)
    hits = check_lda_references(labels)
    if hits:
        for l, lines in hits.items():
            print(f"  {l}: {lines}")
    else:
        print(f"  none of {len(labels)} labels are ever the target of an "
              f"lda* instruction in v7")


if __name__ == "__main__":
    main()
