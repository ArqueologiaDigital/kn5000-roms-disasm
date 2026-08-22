#!/usr/bin/env python3
"""Name the 168 options of the .LSW per-part voice selector (payload byte +0).

QUESTION ANSWERED
-----------------
lsw_panel_schema_from_rom.py shows that the accompaniment part records of the
KN5000 panel work area (TLV tags 0x10 0x11 0x12 0x13) carry a type-3 field
descriptor on payload byte +0 with min=0, max=167, default=21 (tag 0x13: 40),
and a second one on +1 with min=0, max=7, default=0.  That is a 168-option
selector.  WHICH 168 SOUNDS?

ANSWER (all three claims are checked below, each in a form that can fail):

  1. +0 is a flat PANEL SOUND NUMBER and +1 is its VARIATION BANK.  The panel
     resolves the pair through a reverse map in the PROGRAM ROM,

         SoundData_CategoryDesc = 0xE023A0            (RAM 0x00E14E points here)
         map = *(SoundData_CategoryDesc + 0x10) = 0xE02510
         entry = map + 0x80 + bank*0x400 + number*4   -> u16 category, u16 index
         category name = 16*category bytes into SOUND_CATEGORY_NAMES (0xE023F0,
                         stride 16, 18 entries, space-padded and centred)

     Consumer: ApplyProgramChangeAs_LoadDRAM2 (v9 note_voice_mapping.s), reached
     from SndParam_FetchOscTableEntry <- MainGetSoundName / Sound_Navigate_Init
     (v9 audio/sound_navigation.s).

  2. The map's own contents END AT 167.  In variation bank 0: numbers 0..127
     hit the 15 factory categories, 128..147 hit MEMORY A slots 1..20, 148..167
     hit MEMORY B slots 1..20, 168..239 are filler (one dummy entry repeated)
     and 240..255 are the 16 DRUM KITS.  Banks 1..6 stop at 127 and bank 7 at
     129 (its two DIGITAL DRAWBAR presets).  Over ALL EIGHT BANKS the highest
     index below the drum-kit block that is not the filler entry is 167,
     exactly.  That is why a melodic part can select 168 things and no more:
     the descriptor's max is this table's domain.

  3. The NAME of options 0..127 comes from the tone database in the TABLE-DATA
     ROM (mapped at 0x800000), by the same walk the Sub CPU uses:

         b    = ToneDB_BankMap_Main[bank]                 (0x830100, 128 bytes)
         tone = ToneDB_ToneNumBanks_Main[b*128 + number]  (0x830180, LE16)
         name = 16 bytes at 0x830000 + ToneDB_ToneOffsetTable[tone]
                                                          (0x831B00, 629 x LE32)

     Options 128..167 have NO ROM name: they are the user Sound Memories, held
     in battery-backed RAM (Sub-CPU user tone areas, ToneDB_Find_PatchRecord
     bank selectors 0x10/0x15).  That is a negative result, not a gap in the
     search.

HOW TO RUN
----------
    python3 analysis/disk-format-probes/lsw_voice_selector_names.py            # full listing + checks
    python3 analysis/disk-format-probes/lsw_voice_selector_names.py --quiet    # checks only
    python3 analysis/disk-format-probes/lsw_voice_selector_names.py --corpus DIR
        # DIR = a directory tree holding .LSW files, or the *.zip they live in;
        #       default ~/compartilhado/KN7000/floppy-archive (7 zips, 1 .LSW each)

CHECKS (each fails loudly; exit status is non-zero on any failure)
-----------------------------------------------------------------
  C1  boundary, for every program ROM (v7/v9/v10):
      (a) bank 0 map[128..147] == (MEMORY A, 0..19) and map[148..167] ==
          (MEMORY B, 0..19);
      (b) map[240..255] holds only category DRUM KITS in banks 0, 1 and 6,
          only DIGITAL DRAWBAR in bank 7, and only the filler in banks 2..5;
      (c) for every bank 0..7, max{ n <= 239 : map[n] != map[200] } is 167 for
          bank 0, 129 for bank 7, 127 otherwise -- so the union is 167.
      Falsified if any of those cells says something else, and (c) in
      particular fails if the selector's 167 is a coincidence.
  C2  the 128 factory slots of variation bank 0 resolve to 128 tone-record names
      with no out-of-range tone number.
  C3  corpus semantics: in the seven floppy .LSW files, the accompaniment BASS
      part (tag 0x13) must resolve overwhelmingly into the BASS category.
      NULL: only 8 of the 168 options (4.8%) are BASS, so a wrong table would
      score near 5%.  Falsified if the observed share is below 80%.
  C4  discrimination sweep for C3 -- the same score recomputed with the selector
      value shifted by -1,+1,+2,+8 and with the bank shifted by 1..3.  This is
      printed, not asserted, BECAUSE IT SHOWS THE LIMIT OF C3: the eight BASS
      slots are contiguous (40..47) in every bank, so a +-1 misalignment still
      scores 97.7%.  C3 rules out the WRONG TABLE (shift +8 scores 0.0%); what
      pins the exact alignment is C1, where the map's last meaningful index is
      167 and the descriptor's max is 167 -- an off-by-one would make one of
      them 166.

NUMBERS THIS PRODUCED (2026-08-22, v9 program ROM + kn5000_table_data.rom)
-------------------------------------------------------------------------
  C1 PASS   3 ROMs; last non-filler index per bank = [167,127,127,127,127,
            127,127,129], union max 167; 240..255 categories per bank =
            [[15],[15],[0],[0],[0],[0],[15],[12]]
  C2 PASS   128/128 named, 117 distinct tone records
  C3 PASS   tag 0x13 (accompaniment bass) = 175 records over 7 disks, 171
            (97.7%) resolve into the BASS category, the other 4 into BRASS
            (Orchestral Tuba x3, Bright Trombone x1), 0 anything else.
            Null expectation 4.8% (8 of the 168 options are BASS).
  C4        index shift -1/+1/+2/+8 -> 49.1 / 97.7 / 70.3 / 0.0 %
            bank  shift +1/+2/+3      -> 70.3 / 97.7 / 97.7 %
  Selector defaults: 21 -> "Jazz Ac.Guitar" (GUITAR 11), 40 -> "Electric Bass"
            (BASS 3).
"""
import glob
import os
import struct
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
TABLE_DATA = os.path.join(ROOT, 'original_ROMs', 'kn5000_table_data.rom')
PROGRAM = {v: os.path.join(ROOT, 'original_ROMs', 'kn5000_%s_program.rom' % v)
           for v in ('v7', 'v9', 'v10')}
DEFAULT_CORPUS = os.path.expanduser('~/compartilhado/KN7000/floppy-archive')

PROG_LOAD = 0xE00000
TD_LOAD = 0x800000

# program ROM
SOUND_DATA_CATEGORY_DESC = 0xE023A0     # RAM 0x00E14E holds this address
CATEGORY_NAMES = 0xE023F0               # 18 x 16 chars, space padded
CATEGORY_COUNT = 18
REVERSE_MAP = 0xE02510                  # *(desc + 0x10)
MAP_HEADER = 0x80                       # 8 sub-bank bytes + zero pad
MAP_BANK_STRIDE = 0x400                 # 256 records x 4 bytes

# table-data ROM (tone database, base ToneDB_Base = 0x830000)
TONEDB_BASE = 0x830000
BANKMAP_MAIN = 0x830100                 # 128 bytes
TONENUM_BANKS_MAIN = 0x830180           # 11 banks x 128 LE16
TONE_OFFSET_TABLE = 0x831B00            # 629 LE32
TONE_OFFSET_COUNT = 629

CAT_MEMORY_A, CAT_MEMORY_B, CAT_DRUM_KITS, CAT_BASS = 16, 17, 15, 11
MELODIC_TAGS = (0x10, 0x11, 0x12, 0x13)
BASS_TAG = 0x13


def prog(rom, addr, n):
    return rom[addr - PROG_LOAD: addr - PROG_LOAD + n]


def td(rom, addr, n):
    return rom[addr - TD_LOAD: addr - TD_LOAD + n]


def category_names(rom):
    blob = prog(rom, CATEGORY_NAMES, 16 * CATEGORY_COUNT)
    return [blob[16 * i:16 * i + 16].decode('latin1').strip() for i in range(CATEGORY_COUNT)]


def map_entry(rom, bank, number):
    off = REVERSE_MAP - PROG_LOAD + MAP_HEADER + bank * MAP_BANK_STRIDE + 4 * number
    return struct.unpack_from('<HH', rom, off)


def tone_number(tdrom, bank, number):
    b = td(tdrom, BANKMAP_MAIN + bank, 1)[0]
    off = TONENUM_BANKS_MAIN - TD_LOAD + 2 * (b * 128 + number)
    return b, struct.unpack_from('<H', tdrom, off)[0]


def tone_name(tdrom, tone):
    if tone >= TONE_OFFSET_COUNT:
        return None
    rel = struct.unpack_from('<I', tdrom, TONE_OFFSET_TABLE - TD_LOAD + 4 * tone)[0]
    return td(tdrom, TONEDB_BASE + rel, 16).decode('latin1').strip()


def option_name(tdrom, bank, number):
    """The 168-option selector value -> displayed sound name (or a RAM-slot label)."""
    if number < 128:
        _b, tone = tone_number(tdrom, bank, number)
        return tone_name(tdrom, tone), tone
    if number < 148:
        return 'MEMORY A %d  <user RAM>' % (number - 127), None
    if number < 168:
        return 'MEMORY B %d  <user RAM>' % (number - 147), None
    return None, None


# ----------------------------------------------------------------- checks ---
EXPECTED_TOPS = [167, 127, 127, 127, 127, 127, 127, 129]
EXPECTED_TAIL_CATS = [[15], [15], [0], [0], [0], [0], [15], [12]]   # banks 0..7, indices 240..255


def check_boundary():
    """C1 -- the reverse map's own contents stop being meaningful at 167."""
    bad, tops_seen = [], {}
    for ver, path in PROGRAM.items():
        rom = open(path, 'rb').read()
        for n in range(128, 148):
            if map_entry(rom, 0, n) != (CAT_MEMORY_A, n - 128):
                bad.append((ver, 0, n, map_entry(rom, 0, n), 'MEMORY A'))
        for n in range(148, 168):
            if map_entry(rom, 0, n) != (CAT_MEMORY_B, n - 148):
                bad.append((ver, 0, n, map_entry(rom, 0, n), 'MEMORY B'))
        tops = []
        for bank in range(8):
            filler = map_entry(rom, bank, 200)
            tail = sorted({map_entry(rom, bank, n)[0] for n in range(240, 256)})
            if tail != EXPECTED_TAIL_CATS[bank]:
                bad.append((ver, bank, '240..255 categories', tail, EXPECTED_TAIL_CATS[bank]))
            tops.append(max(n for n in range(240) if map_entry(rom, bank, n) != filler))
        tops_seen[ver] = tops
        if tops != EXPECTED_TOPS:
            bad.append((ver, 'last-non-filler-per-bank', tops, EXPECTED_TOPS))
    return bad, tops_seen


def check_names(tdrom):
    """C2 -- every factory slot of bank 0 resolves to a real tone record."""
    bad, tones = [], []
    for n in range(128):
        _b, tone = tone_number(tdrom, 0, n)
        nm = tone_name(tdrom, tone)
        tones.append(tone)
        if not nm or not nm.strip():
            bad.append((n, tone, nm))
    return bad, len(set(tones))


def lsw_blocks(data, start=0x20, limit=26):
    p, blocks, cur = start, [], []
    while p + 1 < len(data) and len(blocks) < limit:
        tag, ln = data[p], data[p + 1]
        if tag == 0xFF and ln == 0xFF:
            blocks.append(cur)
            cur = []
            p += 2
            continue
        cur.append((tag, ln, data[p + 2:p + 2 + ln]))
        p += 2 + ln
    return blocks


def corpus_files(corpus):
    """Every .LSW under `corpus`, reading straight out of *.zip if that is what is there."""
    out = []
    for path in sorted(glob.glob(os.path.join(corpus, '**', '*.LSW'), recursive=True)):
        out.append((path, open(path, 'rb').read()))
    for path in sorted(glob.glob(os.path.join(corpus, '**', '*.zip'), recursive=True)):
        with zipfile.ZipFile(path) as z:
            for n in z.namelist():
                if n.upper().endswith('.LSW'):
                    out.append((path + '!' + n, z.read(n)))
    return out


def check_corpus(rom, tdrom, corpus):
    """C3 -- the bass part must resolve into the BASS category, not at chance."""
    files = corpus_files(corpus)
    per_tag = {t: {} for t in MELODIC_TAGS}
    for _path, blob in files:
        for blk in lsw_blocks(blob):
            for tag, ln, pay in blk:
                if tag in per_tag and ln >= 2:
                    number, bank = pay[0], pay[1] & 0x0F
                    cat = map_entry(rom, bank, number)[0] if bank < 8 else None
                    per_tag[tag].setdefault((number, bank, cat), 0)
                    per_tag[tag][(number, bank, cat)] += 1
    return files, per_tag


def main():
    quiet = '--quiet' in sys.argv
    corpus = DEFAULT_CORPUS
    if '--corpus' in sys.argv:
        corpus = sys.argv[sys.argv.index('--corpus') + 1]

    rom = open(PROGRAM['v9'], 'rb').read()
    tdrom = open(TABLE_DATA, 'rb').read()
    cats = category_names(rom)
    ok = True

    if not quiet:
        print('SOUND_CATEGORY_NAMES @0x%06X  stride 16  %d entries' % (CATEGORY_NAMES, CATEGORY_COUNT))
        for i, c in enumerate(cats):
            print('   %2d  %s' % (i, c))
        print()
        for bank in range(8):
            print('######## voice selector +0 = 0..167, variation bank +1 = %d ########' % bank)
            for n in range(168):
                nm, tone = option_name(tdrom, bank, n)
                cat, idx = map_entry(rom, bank, n)
                where = '%s %d' % (cats[cat], idx + 1) if cat < CATEGORY_COUNT else '?'
                print('  %3d  %-18s %-16s %s' % (n, nm, where,
                                                 ('tone %d' % tone) if tone is not None else ''))
            print()

    bad, tops = check_boundary()
    print('C1 boundary (v7/v9/v10): %s  last non-filler index per bank %r, union max %d%s'
          % ('PASS' if not bad else 'FAIL', tops['v9'], max(tops['v9']),
             '' if not bad else ' %r' % bad[:5]))
    ok &= not bad

    bad, distinct = check_names(tdrom)
    print('C2 bank-0 factory slots named: %s  128 slots, %d distinct tone records%s'
          % ('PASS' if not bad else 'FAIL', distinct, '' if not bad else ' %r' % bad[:5]))
    ok &= not bad

    files, per_tag = check_corpus(rom, tdrom, corpus)
    if not files:
        print('C3 corpus: SKIPPED (no .LSW under %s)' % corpus)
    else:
        tot = sum(per_tag[BASS_TAG].values())
        bass = sum(c for (n, b, cat), c in per_tag[BASS_TAG].items() if cat == CAT_BASS)
        share = 100.0 * bass / tot if tot else 0.0
        null = 100.0 * sum(1 for n in range(168) if map_entry(rom, 0, n)[0] == CAT_BASS) / 168.0
        print('C3 corpus (%d files): tag 0x13 = %d records, %d BASS (%.1f%%), null %.1f%%  -> %s'
              % (len(files), tot, bass, share, null, 'PASS' if share >= 80.0 else 'FAIL'))
        ok &= share >= 80.0
        sweep_i = []
        for sh in (-1, 1, 2, 8):
            hit = sum(c for (n, b, _c), c in per_tag[BASS_TAG].items()
                      if map_entry(rom, b, (n + sh) & 0xFF)[0] == CAT_BASS)
            sweep_i.append('%+d:%.1f%%' % (sh, 100.0 * hit / tot))
        sweep_b = []
        for sh in (1, 2, 3):
            hit = sum(c for (n, b, _c), c in per_tag[BASS_TAG].items()
                      if map_entry(rom, (b + sh) & 7, n)[0] == CAT_BASS)
            sweep_b.append('%+d:%.1f%%' % (sh, 100.0 * hit / tot))
        print('C4 discrimination (informational): index shift %s | bank shift %s'
              % (' '.join(sweep_i), ' '.join(sweep_b)))
        print('   -> C3 rules out a WRONG table (+8 collapses to ~0%); the exact')
        print('      alignment is pinned by C1, not by C3.')
        if not quiet:
            for tag in MELODIC_TAGS:
                print('  tag 0x%02X:' % tag)
                for (n, b, cat), c in sorted(per_tag[tag].items()):
                    nm, _t = option_name(tdrom, b, n)
                    print('     +0=%3d +1=%d  n=%3d  %-18s [%s]'
                          % (n, b, c, nm, cats[cat] if cat is not None and cat < CATEGORY_COUNT else '?'))

    print('OVERALL: %s' % ('PASS' if ok else 'FAIL'))
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
