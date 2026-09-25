#!/usr/bin/env python3
r"""Measure how far each v7 label sits from the code it is named after.

QUESTION THIS ANSWERS
    Many v7 maincpu labels were transplanted from v10 by name.  Is each one at
    the v7 address of the v10 code bearing that name, or displaced?  For every
    label defined in the chosen v7 source files that also exists in v10, this
    finds where the v10 bytes at that label occur in the v7 dump and compares
    with where the v7 ELF puts the label.

HOW
    For a v10 label at address A, take the v10 ROM bytes [A, A+L) and look
    for them in the v7 ROM within +-WINDOW of the v7 label address.  L starts
    at 12 and grows to 32 until the match is unique.  Operand bytes that differ
    between versions (addresses, RAM cells) make some anchors miss; those are
    reported as `nomatch`, never guessed.  A label whose v7 bytes equal its
    v10 bytes at the SAME v7 address is `aligned`; a unique match elsewhere is
    `drift <delta>`.

RUN
    make rebuilt_ROMs/kn5000_v10_program.llvm.elf rebuilt_ROMs/kn5000_v7_program.llvm.elf
    python3 scripts/analysis/v7_label_drift.py audio/note_voice_mapping.s audio/sprintf_core.s ...
    python3 scripts/analysis/v7_label_drift.py --runs FILE...   # contiguous runs by delta

SIGNAL
    delta = (v7 address of the matching bytes) - (v7 label address).  A run of
    labels sharing one negative delta is a block of v7 labels placed |delta|
    bytes above their code.

RESULT 2026-09-25 (lane audio; toolchain tlcs900_backend@4d7fa4f6b37c)
    python3 scripts/analysis/v7_label_drift.py audio/tonegen_fileio_handlers.s \
        audio/audio_control_engine.s audio/sndparam_routines.s \
        midi/midi_serial_routines.s midi/midi_dispatch_handlers.s \
        audio/dsp_config_sysex.s audio/audioinit_routines.s \
        audio/note_voice_mapping.s audio/sprintf_core.s

    v7 file (include order)          aligned  drift  nomatch  v7-only  delta
    audio/tonegen_fileio_handlers.s       67      0       26        6
    audio/audio_control_engine.s         226      6      537      128  scattered
    audio/sndparam_routines.s              0     85       28       38  -0x41a x85
    midi/midi_serial_routines.s            0     80       15       15  -0x41a x80
    midi/midi_dispatch_handlers.s          0    236      498       96  -0x41a x236
    audio/dsp_config_sysex.s               0    250      159       37  -0x41a x250
    audio/audioinit_routines.s             0     24      115        2  -0x41a x24
    audio/note_voice_mapping.s             0    996     1031      197  -0x41a x996
    audio/sprintf_core.s                   0    274       33        9  -0x41a x274

    From SoundParam_NotifyChange (the romslice between
    interrupt_vector_trampolines.s and sndparam_routines.s in
    kn5000_v7_program.s) to the end of sprintf_core.s, EVERY locatable v7
    label sits 0x41A bytes above the code it is named after; not one is
    aligned.  The files before that point are aligned.

    Why the byte gate never saw it: the zone is almost all `.byte` runs with
    labels between them, so a label can sit anywhere without changing a byte,
    and no v7 instruction references these names symbolically -- v7 has 343
    `call 0xFCCC66` (the real SndParam_LookupReadOnly) and none to its label's
    address 0xFCD080; the name occurs in the v7 tree only at its definition.
    (The call counts: python3 -c "r=open('original_ROMs/kn5000_v7_program.rom',
    'rb').read(); print([r.count(bytes([0x1d,t&255,t>>8&255,t>>16])) for t in
    (0xFCCC66, 0xFCD080)])"  ->  [343, 0].)
    Labels that ARE referenced from other v7 files (78 in note_voice_mapping.s,
    4 in sprintf_core.s, mostly `*_Helper` names made at real call targets)
    are at real entry points, since a symbolic reference could not otherwise
    assemble to the ROM's bytes.

    The fix is not to slide the labels (byte-neutral inside `.byte` runs, but
    the zone would stay ~100 KB of undecoded code) but to PORT the v10 source
    by alignment: every v10 line whose bytes recur in v7 (v10 - 0x7CF around the
    sound-descriptor readers, v10 - 0x7DD in sprintf) emitted at its v7 address
    under its v10 name, `.byte` only where v7 differs, every externally
    referenced v7 label kept where it is.  The zone spans files of several
    lanes (audio, midi, the owner of sndparam_routines.s).
"""
import argparse
import collections
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
BASE = 0xE00000
WINDOW = 0x2000


def syms(elf):
    out = {}
    for ln in subprocess.run([NM, "--defined-only", elf], capture_output=True, text=True).stdout.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] in "tT":
            out[p[2]] = int(p[0], 16)
    return out


def labels_in(path):
    L = []
    for ln in open(path, encoding="latin-1"):
        m = re.match(r'^([A-Za-z_.$][\w.$]*):', ln)
        if m:
            L.append(m.group(1))
    return L


def locate(v10, v7, a10, a7):
    for L in (12, 16, 20, 24, 32):
        pat = v10[a10 - BASE:a10 - BASE + L]
        if len(pat) < L:
            return None
        lo = max(0, a7 - BASE - WINDOW)
        hi = a7 - BASE + WINDOW
        hits = []
        i = v7.find(pat, lo, hi + L)
        while i >= 0:
            hits.append(i + BASE)
            i = v7.find(pat, i + 1, hi + L)
        if len(hits) == 1:
            return hits[0]
        if not hits:
            return None
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+", help="paths relative to v7/maincpu")
    ap.add_argument("--runs", action="store_true")
    a = ap.parse_args()
    v10 = open(os.path.join(ROOT, "original_ROMs/kn5000_v10_program.rom"), "rb").read()
    v7 = open(os.path.join(ROOT, "original_ROMs/kn5000_v7_program.rom"), "rb").read()
    s10 = syms(os.path.join(ROOT, "rebuilt_ROMs/kn5000_v10_program.llvm.elf"))
    s7 = syms(os.path.join(ROOT, "rebuilt_ROMs/kn5000_v7_program.llvm.elf"))
    for f in a.files:
        rows = []
        for name in labels_in(os.path.join(ROOT, "v7/maincpu", f)):
            if name not in s7 or name not in s10:
                rows.append((name, s7.get(name), None, "v7-only" if name not in s10 else "?"))
                continue
            a7, a10 = s7[name], s10[name]
            hit = locate(v10, v7, a10, a7)
            if hit is None:
                rows.append((name, a7, None, "nomatch"))
            elif hit == a7:
                rows.append((name, a7, 0, "aligned"))
            else:
                rows.append((name, a7, hit - a7, "drift"))
        c = collections.Counter(r[3] for r in rows)
        d = collections.Counter(r[2] for r in rows if r[3] == "drift")
        print("== %s: %d labels; %s; drift deltas %s" % (
            f, len(rows), dict(c), ", ".join("%+#x x%d" % (k, n) for k, n in d.most_common(6))))
        if a.runs:
            run = None
            for name, a7, dl, kind in rows + [("<end>", None, None, "end")]:
                key = (kind, dl) if kind in ("aligned", "drift") else None
                if key is None:
                    continue
                if run and run[0] == key:
                    run[2] = (name, a7)
                    run[3] += 1
                else:
                    if run and run[3] >= 3:
                        print("   %-8s %+7s  %5d labels  %s 0x%06X .. %s 0x%06X" % (
                            run[0][0], ("%+#x" % run[0][1]) if run[0][1] else "", run[3],
                            run[1][0], run[1][1], run[2][0], run[2][1]))
                    run = [key, (name, a7), (name, a7), 1]
    return 0


if __name__ == "__main__":
    sys.exit(main())
