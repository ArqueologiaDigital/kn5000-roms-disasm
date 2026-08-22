#!/usr/bin/env python3
"""Of the `cp r,(imm)` sites STILL sitting in .byte blobs, which are real
instructions a converter should emit, and which are data (or misframes)?

QUESTION ANSWERED
  blob_cp_reg_direct_alltrees.py counts them.  Counting is the easy half: a
  linear scan of a pointer table or a DSP bytecode stream decodes to this same
  printed form.  This script attributes each remaining site instead of counting
  it -- it prints, per site:

    * the owning LABEL (nearest preceding label in the .s file that contains the
      run), which is the project's own statement about what those bytes are;
    * the reframe window: unidasm output from the RUN START, which is
      instruction-aligned by construction because the source line before the run
      is a real instruction that ends there;
    * whether the site's prefix is spellable (low nibble 1 or 2) or is the
      8-bit-direct class c0/d0/e0 that has no mnemonic at all.

  A site inside a run whose label says "Bytecode"/"Table"/"Curve"/"Descriptors",
  or whose neighbours are 4-byte little-endian pointers into nearby code, is
  data.  A site whose window reads as ordinary control flow is code.

RUN
  python3 tools/spelling-probes/frame_cp_reg_direct_blobs.py            # all trees
  python3 tools/spelling-probes/frame_cp_reg_direct_blobs.py v9/maincpu

RESULT 2026-08-22 (unidasm from ~/compartilhado/tools; sources at b081be6)

  Outside v7 -- whose 346 sites are one big separate job -- the remaining
  blocking set is 17 sites in v9 and the SAME 17 in v10 (the revisions differ by
  3 bytes), 54 in the v142 sub-CPU payload, 8 in table_data and 2 in hdae5000.
  Totals over all eight trees: 388 spellable + 56 with no spelling.  Attributed:

  CODE, and the rule already spells them (emit `cpda8`/`cpda16`/...):
    v9/v10   15 x c1  `cp A,(0x33xx)` etc. in accompaniment_engine.s,
             seq_audio_mode.s, scoop_display.s -- windows read as plain control
             flow (`ld A,(0x0433)` / `cp A,(0x3366)` / `jr Z`).
    v142      5 (1 d1 + 4 d2) under RingBuf_* and ToneGen_Voice_Active_Bitmap,
             e.g. 020842 `d1 40 10 f0` between `add WA,(0x1040)` and `jr GT`.
    table_data 6 (1 c1 + 4 c2 + 1 d1), hdae5000 1 (e2).
    v7       346, the separate big job.

  DATA -- do not convert:
    v142     49 x d0/e0, ALL inside ONE run that starts at the label
             DSP_Eff32_Algo_Bytecode in subcpu_data_tables.s.  These are DSP
             microprogram streams for IC309/IC310, not TLCS-900 code; the 0xF0
             that unidasm reads as the compare's register byte is the stream's
             END MARKER (the file's own comment: "1 instruction: op3(215);
             0xf0 end").
    v9/v10    1 x d0 at f5ae01, inside an 8-entry table of 4-byte little-endian
             pointers at f5adf9..f5ae18 -- the run's own label is
             AccPlayMode_Dispatch_Table -- 00f5ae19 00f5af4d 00f5afd0 00f5b004
             00f5afb7 00f5af3c 00f5afb2 00f5af9d, every one in range, and the
             first equal to the address just past the table.  The "instruction"
             is bytes 0-2 of entry #2.
    table_data 2 x c0/e0 at 85c713 / 85c71f under ToneDB_VelocityCurve_0, in a
             6-byte record stream whose first field counts 01 02 03 04 05.
    hdae5000  1 x c0 at 29f6e2 under HDAE5000_UI_Page_Titles, three
             bytes before the 4-byte pointer 0029f6f0.

  MISFRAME -- neither code nor data at that address:
    v9/v10    1 x e0 at fc8e73, inside MidiCh_ConfigVoiceAndParts.  The real
              instruction stream is
                fc8e6f: c1 e4 8e 19 e0 8e   ld (0x8ee0),(0x8ee4)
                fc8e75: f1 e4 8e bf         set 7,(0x8ee4)
                fc8e79: f1 e4 8e cf         bit 7,(0x8ee4)
              The source (audio_control_engine.s:4975) splits that 6-byte
              memory-to-memory load, emitting `pop_f` for its interior 0x19
              byte, so the blob restarts at fc8e73 in mid-instruction and the
              `cp XBC,(0x8e)` is an artefact of the split.  The real gap there
              is a spelling for `ld (nn),(nn)`, NOT for the 8-bit-direct
              compare.

  So: 0 of the 56 blob-resident c0/d0/e0 sites in any tree is a real 8-bit-
  direct compare.  Same verdict the whole-ROM census reached, now from the
  converter's side.
"""
import os, re, subprocess, glob, sys, tempfile

REPO = os.path.expanduser('~/compartilhado/kn5000-roms-disasm')
UNI  = os.path.expanduser('~/compartilhado/tools/unidasm')

TREES = [('v7/maincpu',   'kn5000_v7_program.rom',      0xE00000),
         ('v9/maincpu',   'kn5000_v9_program.rom',      0xE00000),
         ('v10/maincpu',  'kn5000_v10_program.rom',     0xE00000),
         ('v142/subcpu',  'kn5000_subprogram_v142.rom', 0x00EF00),
         ('subcpu',       'kn5000_subcpu_boot.ic30',    0xFE0000),
         ('table_data',   'kn5000_table_data.rom',      0x800000),
         ('custom_data',  'kn5000_custom_data.ic19',    0x300000),
         ('hdae5000',     'hd-ae5000_v2_06i.ic4',       0x280000)]

BYTE  = re.compile(r'^\s*\.byte\s+(.*)$')
LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
LINE  = re.compile(r'^([0-9a-f]+): ([0-9a-f]{2}(?: [0-9a-f]{2})*)\s{2,}(.*)$')
TEXT  = re.compile(r'^cp ([A-Za-z]+),\((0x[0-9a-f]+)\)$')

want = sys.argv[1] if len(sys.argv) > 1 else None
tot_sp = tot_un = 0

for tree, binname, base in TREES:
    if want and tree != want:
        continue
    rom = open(os.path.join(REPO, 'original_ROMs', binname), 'rb').read()
    for f in sorted(glob.glob(f'{REPO}/{tree}/**/*.s', recursive=True)):
        lines = open(f, errors='replace').readlines()
        labels = [(i + 1, LABEL.match(l).group(1))
                  for i, l in enumerate(lines) if LABEL.match(l)]
        runs, cur, start = [], b'', None
        for i, line in enumerate(lines, 1):
            m = BYTE.match(line)
            if m:
                vals = [v.strip() for v in m.group(1).split(';')[0].split(',') if v.strip()]
                try:
                    b = bytes(int(v, 0) & 0xFF for v in vals)
                except ValueError:
                    if cur: runs.append((start, cur)); cur, start = b'', None
                    continue
                if not cur: start = i
                cur += b
            else:
                s = line.strip()
                if s.startswith(';') or s.endswith(':') or not s: continue
                if cur: runs.append((start, cur)); cur, start = b'', None
        if cur: runs.append((start, cur))

        for ln, b in runs:
            if len(b) < 8: continue
            i = rom.find(b)
            if i < 0 or rom.find(b, i + 1) >= 0: continue
            tf = tempfile.NamedTemporaryFile(suffix='.bin', delete=False)
            tf.write(b); tf.close()
            out = subprocess.run([UNI, tf.name, '-arch', 'tlcs900',
                                  '-basepc', hex(base + i)],
                                 capture_output=True, text=True).stdout
            os.unlink(tf.name)
            rows = [l for l in out.split('\n') if LINE.match(l)]
            hits = [l for l in rows if TEXT.match(LINE.match(l).group(3))]
            if not hits: continue
            owner = '(none)'
            for lab_ln, lab in labels:
                if lab_ln <= ln: owner = lab
            sp = sum(1 for h in hits if int(LINE.match(h).group(2)[:2], 16) & 0xF)
            un = len(hits) - sp
            tot_sp += sp; tot_un += un
            print(f'### {os.path.relpath(f, REPO)}:{ln}  run @{base + i:06x} '
                  f'len {len(b)}  label {owner}   {sp} spellable + {un} no-spelling')
            first = rows.index(hits[0])
            for l in rows[max(0, first - 4): first + 8]:
                print('    ' + l + ('   <<< HIT' if l in hits else ''))
            print()

print(f'TOTAL {tot_sp} spellable + {tot_un} with no spelling, in blob runs')
