#!/usr/bin/env python3
"""verify_converted_call_targets.py -- does a converted region actually
BEHAVE like code, independent of the byte gate?

QUESTION ANSWERED: convert_region.py's own header says it plainly -- "a
clean decode is a candidate, not a verdict", because data can decode into
plausible, byte-round-trippable TLCS-900 instructions in this ROM family
(the HD-AE5000 lane hit exactly this: 309 bytes of a version string
disassembled as ~35 syntactically valid instructions chained by fabricated
local labels referencing nothing outside the span). The byte gate cannot
tell a real routine from that kind of illusion, because both reproduce the
same bytes.

This script asks a question the gate cannot: for every `call`/`calr` target
inside a converted region, does that address land on an ALREADY-NAMED
routine that existed in the tree BEFORE this conversion (from
symbols/maincpu_v9_symbols_reference.txt, generated from the ELF, not from
anything this session wrote)? A closed loop of fabricated labels cannot do
this -- there is nothing outside the span for it to reach. A real function
calling other real, independently-named functions can, and should, hit this
check often.

⚠ IT DOES NOT PROVE the region is code by itself -- an absolute number that
happens to fall inside the .text range is not automatically a call the CPU
takes. But a HIGH hit rate across MANY distinct targets, especially where
adjacent targets resolve to semantically related routines, is exactly the
kind of external corroboration the byte gate cannot provide. A LOW hit rate,
or targets landing in the middle of unrelated named routines rather than at
their start, is reason to distrust the region -- treat it as re-opened,
not converted.

Run:
    python3 scripts/analysis/verify_converted_call_targets.py <file> [<file> ...]
    python3 scripts/analysis/verify_converted_call_targets.py --git-diff          # working-tree changes
    python3 scripts/analysis/verify_converted_call_targets.py --git-diff REV REV2 # a historical range

2026-09-01 run (the 14 regions converted this session; diffed against the
commit before them, v9 copy -- v10 is byte-identical to v9's source after
conversion by construction, see convert_region.py):

    python3 scripts/analysis/verify_converted_call_targets.py \
        --git-diff 11a48aca 244bde7b

  30 distinct absolute `call` targets (this check cannot resolve `calr`,
  see CALL_RE below), 21 hit / 9 miss = 70%. Of the 9 misses:
    - 8 cluster at 0xF5E717-0xF5E7C2, immediately after the named entry
      AccTone_LookupByProgram_Dispatch at 0xF5E700: they are that routine's
      OTHER stub entry points, 7-23 bytes apart, called in the exact
      case-dispatch shape convert_region.py's output shows -- not a hit
      against this check's method, but its natural blind spot (a dispatch
      table's interior entries have no symbol of their own);
    - 1 (0xF64F5C) is this session's OWN leftover `.byte` residue -- the
      instruction right after it in the same converted region calls
      straight into the tail this session did NOT finish decoding. Self-
      consistent (the call and its target are both real, adjacent code),
      but it is not independent corroboration the way the 21 hits are.
  Every `call` target that COULD have a pre-existing symbol has one:
  Util_FindLowestSetBit, MIDI_DispatchCC_Guarded, MIDI_WriteVoiceParamCC,
  MIDI_WriteVoiceParamDirect, SwbtWr_WriteVoiceParam_PreserveRegs,
  MainRamPut, MainRamAdd, GetViewInstance, SetBox, SndParam_LookupReadOnly,
  SeqData_AdvancePosition, SeqData_CopyBlockToBuffer, SeqData_ReadNextByte,
  VoicePreset_LoadAndInitPan, NoteEditSy_SendModeScrollCmd,
  Seq_DispatcherEntry, AccWrap_PlayModeStartAccPlay,
  RegBitManip_Handler_4_0x8, MIDI_ParamValidate_CheckBit2,
  PartCtrl_CheckBitmaskBit, AccTone_LookupByProgram_Dispatch itself.
  Separately, of 12 `lda`/`lda_24`/`lda_d16` (load-ADDRESS, i.e. a pointer
  to DATA, not a call) targets, 6 land on named Display_FontPalette_Table_*
  entries and 6 are unnamed data -- expected either way, reported for
  completeness rather than as a pass/fail signal.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent

# Only `call` takes an ABSOLUTE target we can look up directly. `calr` takes
# a PC-RELATIVE displacement (target = next-instruction-address + disp); this
# script does not track instruction addresses, so calr targets are not
# resolvable here and are deliberately excluded rather than mis-scored as
# absolute addresses (a -6217 displacement is not a ROM address).
CALL_RE = re.compile(r'^\s*call\t(-?\d+)\s*$')
JR_RE = re.compile(r'^\s*(jr|jrl)\t(?:\w+,\s*)?(-?\d+)\s*$')
LDA_RE = re.compile(r'^\s*lda(?:_24|_d16)?\t\w+,\s*(-?\d+)\s*$')


def load_symbols(tag='v9'):
    path = REPO / 'symbols' / f'maincpu_{tag}_symbols_reference.txt'
    syms = {}
    for line in path.read_text().splitlines():
        if line.startswith('#') or not line.strip():
            continue
        parts = line.split()
        if len(parts) != 2:
            continue
        name, addr = parts
        try:
            syms[int(addr, 16)] = name
        except ValueError:
            continue
    return syms


def targets_in_text(text):
    calls, ptrs = [], []
    for line in text.splitlines():
        m = CALL_RE.match(line)
        if m:
            calls.append(int(m.group(1)))
            continue
        m = LDA_RE.match(line)
        if m:
            ptrs.append(int(m.group(1)))
    return calls, ptrs


def report(calls, ptrs, syms, base=0xE00000):
    print(f"{len(set(calls))} distinct call/calr targets:")
    hit = miss = 0
    for addr in sorted(set(calls)):
        name = syms.get(addr)
        if name:
            hit += 1
            print(f"  {addr:#08x}  HIT   {name}")
        else:
            miss += 1
            print(f"  {addr:#08x}  miss  (no pre-existing symbol)")
    print(f"  => {hit} hit, {miss} miss  ({100.0 * hit / max(hit + miss, 1):.0f}% resolve "
          f"to an already-named routine)")
    if ptrs:
        print(f"{len(set(ptrs))} distinct lda/lda_24/lda_d16 (load-ADDRESS, not "
              f"call) targets -- these point at DATA and are not expected to "
              f"resolve to a routine name:")
        for addr in sorted(set(ptrs)):
            name = syms.get(addr)
            print(f"  {addr:#08x}  {'named: ' + name if name else '(unnamed data)'}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('files', nargs='*', help='.s files to scan whole (all '
                     'call/calr/lda lines in the file, not just converted ones)')
    ap.add_argument('--git-diff', nargs='*', metavar='REV',
                     help='scan only ADDED lines from `git diff [REV [REV2]] '
                          '-- <tag>/` (no revs: working-tree changes)')
    ap.add_argument('--tag', default='v9', choices=['v9', 'v10', 'v7'])
    a = ap.parse_args()
    syms = load_symbols(a.tag)
    if a.git_diff is not None:
        out = subprocess.run(['git', 'diff', *a.git_diff, '--', f'{a.tag}/'],
                              cwd=REPO, capture_output=True).stdout.decode('latin-1')
        added = '\n'.join(l[1:] for l in out.splitlines() if l.startswith('+') and not l.startswith('+++'))
        calls, ptrs = targets_in_text(added)
    elif a.files:
        calls, ptrs = [], []
        for f in a.files:
            c, p = targets_in_text(Path(f).read_text(encoding='latin-1'))
            calls += c
            ptrs += p
    else:
        sys.exit("specify files or --git-diff")
    report(calls, ptrs, syms)


if __name__ == '__main__':
    main()
