#!/usr/bin/env python3
"""gen_sndparam_desc_names.py -- name the part sound-parameter descriptors by part and field.

QUESTION IT ANSWERS / WHAT IT DOES
  audio/sndparam_records/run_*.c hold the sound-parameter descriptors (sndparam_types.h): each has a key, the
  record it edits (bank_index = the panel TLV tag), the byte (bank_offset) and the bits (mask).  The asm names
  each descriptor by a reader and an index (`.set MidiChParam_Entry_031, SndParamRun_EDC2A4 + 0`).
  analysis/disk-format-probes/README-lsw-param-namespace-map.md proved the part keys are 0x8000 + 0x400*T + k
  (T the part tag); section 5 there (2026-10-06) shows that k is the parameter's MIDI controller number --
  k = 0x07 lands on the part record's volume byte, 0x0A on pan, 0x20 on the bank byte, 0x5B / 0x5D on the
  reverb / chorus sends, 0x40 on the bit the SUSTAIN button sets, 0x5E on the bit DIGITAL EFFECT sets -- and the
  drawbar keys (0x280..0x288 of parts 0..2) are the nine footages of README-lsw-drawbar-records.md.  k = 0x08
  (byte 3, bit 7) is the part's MUTE flag: the mixer widget's channel table pairs it with k = 0x07 for every part
  and draws "MUTE" when it is 1 (scripts/converters/mixer_channel_table_retype.py; README section 6).
  The firmware's own part-parameter ApFunctions settle more of k (README section 7): on EVT_GET_LSW_DATA_NO,
  LswVolume answers 0x07, LswMute 0x08, LswPan 0x0A, LswReverb 0x5B, LswDSPEffect 0x5D, LswDigitalEffect 0x5E,
  LswSustain 0x40, LswBendRange 0x80, LswTuning 0x81 and LswKeyShift 0x82.  So k = 0x5D is named DspEffect,
  the firmware's name (it was ChorusSend, after General MIDI's CC 93), and 0x80 / 0x81 / 0x82 are BendRange /
  Tuning / KeyShift (bytes 11 / 10 / 9: ranges 0-12, 0-255, 64 +/- 12).
  For every descriptor whose key is in the part namespace and whose field is in FIELDS below, this script
  writes a rule  <old alias> -> SndParam_Part<TT>_<Field>  into scripts/renaming/rename_sndparam_desc_<tree>.sed.
  Fields without such a basis (k = 0x78, 0x1B0, 0x1B2, the drawbar switches) keep their names.

RUN (repository root)
  python3 scripts/renaming/gen_sndparam_desc_names.py        # writes the three sed files
  then per tree: sed -i -f scripts/renaming/rename_sndparam_desc_<tree>.sed <files that use the names>
"""
import glob
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
# field constant k -> name; the basis of each is in README-lsw-param-namespace-map.md section 3
FIELDS = {0x00: "Sound", 0x20: "Bank", 0x07: "Volume", 0x0A: "Pan", 0x5B: "ReverbSend", 0x5D: "DspEffect",
          0x80: "BendRange", 0x81: "Tuning", 0x82: "KeyShift",
          0x01: "Modulation", 0x0B: "Expression", 0x40: "Sustain", 0x5E: "DigitalEffect", 0x08: "Mute",
          0x280: "Drawbar16", 0x281: "Drawbar8", 0x282: "Drawbar5_1_3", 0x283: "Drawbar4", 0x284: "Drawbar2_2_3",
          0x285: "Drawbar2", 0x286: "Drawbar1_3_5", 0x287: "Drawbar1_1_3", 0x288: "Drawbar1"}
ENTRY = re.compile(r'/\* \[\s*\d+\] 0x[0-9A-F]+\s+(\S+) \*/\s*\{ \.key = 0x([0-9A-F]+), \.bank_index = 0x([0-9A-F]+),'
                   r' \.bank_offset = 0x([0-9A-F]+),\s*\.mask = 0x([0-9A-F]+)')
# the (record, byte, mask) each named field must have, so a key that broke the pattern stops the script
EXPECT = {0x00: (0, 0xFF), 0x20: (1, 0x7F), 0x07: (3, 0x7F), 0x0A: (8, 0x7F), 0x5B: (7, 0x7F), 0x5D: (5, 0x7F),
          0x40: (4, 0x08), 0x5E: (4, 0x40), 0x08: (3, 0x80), 0x80: (11, 0x7F), 0x81: (10, 0xFF), 0x82: (9, 0x7F)}


def elf_symbols(tree):
    import subprocess
    nm = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
    out = subprocess.run([nm, "--defined-only", os.path.join(REPO, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % tree)],
                         capture_output=True, text=True, check=True).stdout
    return {f[2]: int(f[0], 16) for f in (l.split() for l in out.splitlines()) if len(f) == 3}


def main():
    v10_keys = {}
    for tree in ("v10", "v9", "v7"):
        rules, seen = {}, set()
        if tree != "v10":
            # v9 / v7 hold the runs as asm with the same alias names: take v10's rule for an alias only when the
            # descriptor key at that alias's address in this tree's own ROM is v10's key
            syms = elf_symbols(tree)
            rom = open(os.path.join(REPO, "original_ROMs/kn5000_%s_program.rom" % tree), "rb").read()
            for alias, (key, new) in v10_keys.items():
                a = syms.get(alias)
                if a is not None and int.from_bytes(rom[a - 0xE00000:a - 0xE00000 + 4], "little") == key:
                    rules[alias] = new
            missed = len(v10_keys) - len(rules)
            out = os.path.join(REPO, "scripts/renaming/rename_sndparam_desc_%s.sed" % tree)
            with open(out, "w") as f:
                f.write("# %s: part sound-parameter descriptors named by part tag and field (gen_sndparam_desc_names.py;\n"
                        "# v10's map, each alias checked against the key at its address in this ROM).\n" % tree)
                for a_, b_ in sorted(rules.items(), key=lambda x: -len(x[0])):
                    f.write("s/\\b%s\\b/%s/g\n" % (a_, b_))
            print("%s: %d descriptors (%d of v10's not confirmed here) -> %s" % (tree, len(rules), missed,
                                                                             os.path.relpath(out, REPO)))
            continue
        for c in sorted(glob.glob(os.path.join(REPO, tree, "maincpu/audio/sndparam_records/run_*.c"))):
            for m in ENTRY.finditer(open(c, encoding="latin-1").read()):
                alias, key, tag, off, mask = m.group(1), int(m.group(2), 16), int(m.group(3), 16), \
                    int(m.group(4), 16), int(m.group(5), 16)
                if not 0x8000 <= key < 0xE400:
                    continue
                part, k = (key - 0x8000) >> 10, key & 0x3FF
                if k not in FIELDS:
                    continue
                if k in EXPECT:
                    assert tag == part and (off, mask) == EXPECT[k], (tree, alias, hex(key), tag, off, mask)
                if k >= 0x280:
                    assert part in (0, 1, 2) and tag == 0x44 + part, (tree, alias, hex(key))
                new = "SndParam_Part%02X_%s" % (part, FIELDS[k])
                assert new not in seen, (tree, new)
                seen.add(new)
                if alias != new:
                    rules[alias] = new
                    v10_keys[alias] = (key, new)
        out = os.path.join(REPO, "scripts/renaming/rename_sndparam_desc_%s.sed" % tree)
        with open(out, "w") as f:
            f.write("# %s: part sound-parameter descriptors named by part tag and field (gen_sndparam_desc_names.py;\n"
                    "# basis: analysis/disk-format-probes/README-lsw-param-namespace-map.md section 5).\n" % tree)
            for a, b in sorted(rules.items(), key=lambda x: -len(x[0])):
                f.write("s/\\b%s\\b/%s/g\n" % (a, b))
        print("%s: %d descriptors -> %s" % (tree, len(rules), os.path.relpath(out, REPO)))


if __name__ == "__main__":
    main()
