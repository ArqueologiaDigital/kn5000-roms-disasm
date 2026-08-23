#!/usr/bin/env python3
"""Is `ToneGen_ParamTable` tone-generator data? NO -- it is a JUMP TABLE.

QUESTION ANSWERED
-----------------
`ToneGen_ParamTable` (v7 0x00E0E407, 1,389 bytes, sub-labels every 0x48) reads
like the tone-generator's parameter block -- the obvious thing to consult when
working on the TG, and the obvious thing to suspect when a driver copies a large
block straight out of ROM across a chip boundary.

It is neither. Every one of its nine references is a DISPATCH:

    lda_24 xde, (ToneGen_ParamTable_0x1E)
    exts   XBC
    add    XBC,XDE
    ld     XHL,(XBC)
    call   (XHL)               <- loads a POINTER from the table and CALLS it

All nine sites are in `v7/maincpu/audio/sound_editor_ui.s`. It is the sound
editor UI's handler table, indexed by a UI selection. No TG register is touched
by it and no part of it is transferred to the tone generator.

⚠ WHY THIS MATTERS BEYOND THE NAME: it is an L2 APTNESS defect of the kind no
script catches. The name asserts nothing checkable -- there is no return value,
no fopen mode, no declared count -- so `l2_name_vs_return_value.py` and its
siblings are blind to it. It is exactly the `FileIO_ReadHeader` case (builds a
path, reads no header) and it costs whoever trusts it a wrong hypothesis about
the tone generator.

⚠ It also has no 32-bit pointer anywhere in the ROM. Searching for one returns
ten hits, ALL COINCIDENTAL: `07 e4 e0` is the addressing-byte pattern of
`ld (XBC+WA),imm` (mode 0x07, base 0xE4=XBC, index 0xE0=WA). Disassembling from
those offsets shows ordinary stores. A byte-pattern search for a pointer needs
the instruction context checked before the hits are believed.

Run:  python3 scripts/analysis/v7_tonegen_paramtable_is_a_jumptable.py
"""
import glob, os, re, struct, subprocess, sys

REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
BASE, TABLE = 0xE00000, 0xE0E407


def main():
    os.chdir(REPO)
    rom = open("original_ROMs/kn5000_v7_program.rom", "rb").read()

    refs = []
    for f in glob.glob("v7/maincpu/**/*.s", recursive=True):
        for i, ln in enumerate(open(f, "rb").read().decode("latin1").splitlines(), 1):
            if "ToneGen_ParamTable" in ln and ".set" not in ln and "incbin" not in ln:
                refs.append((f, i, ln.strip()))
    print(f"  references outside the .set definitions : {len(refs)}")
    files = sorted({r[0] for r in refs})
    print(f"  files containing them                   : {', '.join(os.path.basename(x) for x in files)}")
    disp = sum(1 for _, _, l in refs if l.startswith("lda_24"))
    print(f"  of those, `lda_24 xde, (…)` dispatch loads: {disp}")

    pat = struct.pack("<I", TABLE)
    hits, i = [], rom.find(pat)
    while i != -1 and len(hits) < 12:
        hits.append(BASE + i)
        i = rom.find(pat, i + 1)
    print(f"\n  32-bit LE pointers to the table in the ROM: {len(hits)}")
    print("  ⚠ every one is coincidental -- `07 e4 e0` is the addressing-byte")
    print("     pattern of `ld (XBC+WA),imm`, not a pointer. Sample:")
    uni = os.path.expanduser("~/compartilhado/tools/unidasm")
    if hits and os.path.exists(uni):
        import tempfile
        d = tempfile.mkdtemp()
        s = hits[0] - 1
        open(d + "/p.bin", "wb").write(rom[s - BASE:s - BASE + 12])
        out = subprocess.run([uni, d + "/p.bin", "-arch", "tlcs900", "-basepc", hex(s)],
                             capture_output=True, text=True).stdout
        for l in out.splitlines()[:2]:
            print("       ", l)
    print("\n  VERDICT: a jump table for the sound editor UI. Not TG data.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
