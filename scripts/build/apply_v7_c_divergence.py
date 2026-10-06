#!/usr/bin/env python3
"""apply_v7_c_divergence.py -- relocate the v7 pointers the shared C source gets wrong.

QUESTION ANSWERED: where, and why, does the committed C fail to reproduce the v7 ROM?

76 of v7's data bins are compiled from C shared with v9/v10. 53 match the v7 ROM exactly. The
other 23 differ, and the difference is now EXPLAINED rather than merely recorded:

    2,365 of them are POINTER RELOCATIONS -- a 32-bit little-endian address that the C emits
    with its v9/v10 target, where v7's is lower by a fixed amount. The deltas are piecewise and
    map to disjoint address ranges:

        v9/v10 address range          v7 delta   sites
        0x00F01C29 .. 0x00F35DE9          -0x2A     986   (the known v7 code offset)
        0x00F3ECB3                        -0x1C       8
        0x00F42DF8 .. 0x00F477DA          -0x0E      69
        0x00F4E778 .. 0x00F87614         -0x404     333
        0x00F8784D .. 0x00FB3062         -0x40D     715
        0x00FB8B0B .. 0x00FC6DEE         -0x7CB     309
        0x00FCF11B .. 0x00FCF13C         -0x7D1       4
        0x00003991 .. 0x00003A3C          -0x9C      15   (a RAM-space table)

    1,334 bytes remain raw, and two files fall back to a whole-file byte diff -- one of them
    because v7's version is a different LENGTH (naka_sequencer_channels is 7,894 B against
    v9's 7,936).

A BLIND SCAN-AND-RELOCATE DOES NOT WORK, and was tried: applying the map to every 32-bit value
in range corrupts data that merely looks like an address, reproducing only 8 of 23 files. The
sites are therefore recorded explicitly. That is the honest form -- each entry says "this
offset holds a pointer, move it by D" -- rather than an opaque byte blob.

WHY THIS EXISTS AT ALL. The build used to run extract_v7_bins.py, slicing the ORIGINAL v7 ROM
into its own inputs, so the byte-match gate could not fail for 979,096 B (46.69%) of v7. That
is gone; verify with `python3 scripts/analysis/rom_provenance_poison.py v7`, which must report
0 differing bytes.

    python3 scripts/build/apply_v7_c_divergence.py

THE REMAINING WORK is to make the C v7-aware so this file empties: the relocations say exactly
which pointers need it. Do NOT grow the raw section to paper over new divergence.

UPDATE 2026-10-06. The figures above are the file as first written. v7's naka_*_link.ld files were
copies of v10's; scripts/generators/generate_v7_naka_link_scripts.py gave 1,105 of their symbols the
v7 address, in each case where every v7 site using the symbol holds exactly that address. Then
scripts/build/regenerate_v7_c_divergence.py recomputed the json from the build's certified bins,
without reading the ROM. Now:
- 1,162 relocations and 1,180 raw bytes remain;
- 8 of the 23 bins need nothing;
- the naka bins still patched are: naka_disk_warning 25, naka_extension_device 150, naka_master_style 27, naka_sequencer_channels 1179 raw,
  naka_sequencer_exit 13, naka_style_bitmaps 1 raw, naka_technichord_strings 40, naka_widget_descriptors 50, naka_widget_names_charmap 1.
The C files without a link script (gui_display_struct_data, tonegen_param_table, sepaout_config,
style_ui_screendata_ctlonly, se_name_editor, sound_config_lookup) still spell their pointers as v10
numbers. Run regenerate_v7_c_divergence.py after any change to v7's C or link scripts.
"""
import json
import pathlib
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
GEN = REPO / 'v7' / 'maincpu' / 'includes' / 'generated'
PATCH = REPO / 'v7' / 'maincpu' / 'includes' / 'v7_c_divergence.json'


def main():
    patch = json.loads(PATCH.read_text())
    nrel = nraw = 0
    nskip = 0
    for name, ent in sorted(patch.items()):
        target = GEN / name
        if not target.exists():
            sys.exit(f"apply_v7_c_divergence: {target} missing -- build the C bins first")
        # !! IDEMPOTENCY STAMP. The relocations below are RELATIVE (v += delta),
        # so running this twice applies delta twice. The .bin is regenerated from
        # C only when the .c is newer, so on an incremental build make skips the
        # regeneration and this script patches an ALREADY-PATCHED file. Measured
        # 2026-08-23: style_ui_screendata_ctlonly.bin drifted -42 per build, and
        # after seven builds the v7 ROM differed from the original by 136,782
        # bytes -- entirely from this, not from any source edit.
        #
        # It cannot be made absolute: reading the ROM to compute the target value
        # would make the ROM an input to its own reconstruction, which is exactly
        # what the poison rule forbids. So instead the script records what it
        # produced and refuses to patch that same content twice.
        import hashlib
        stamp = target.with_suffix(target.suffix + '.patched')
        cur = target.read_bytes()
        if stamp.exists() and stamp.read_text().strip() == hashlib.sha256(cur).hexdigest():
            nskip += 1
            continue
        data = bytearray(cur)
        size = ent['size']
        if len(data) < size:
            data.extend(b'\x00' * (size - len(data)))
        del data[size:]
        for off, delta in ent.get('reloc', []):
            v = int.from_bytes(data[off:off + 4], 'little')
            data[off:off + 4] = ((v + delta) & 0xFFFFFFFF).to_bytes(4, 'little')
            nrel += 1
        for off, val in ent.get('raw', {}).items():
            data[int(off)] = val
            nraw += 1
        target.write_bytes(bytes(data))
        import hashlib as _h
        stamp.write_text(_h.sha256(bytes(data)).hexdigest() + "\n")
    print(f"apply_v7_c_divergence: {len(patch)} bins, {nskip} already patched (skipped), "
          f"{nrel:,} pointer relocations, "
          f"{nraw:,} raw bytes ({(nrel * 4 + nraw) * 100.0 / 2097152:.2f}% of the v7 ROM)")


if __name__ == '__main__':
    main()
