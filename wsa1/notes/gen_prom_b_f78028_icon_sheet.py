#!/usr/bin/env python3
"""prom_b 0xF78028-0xF7A19F -- THE UI ICON SHEET, 119 CELLS OF 24x24.

QUESTION THIS ANSWERS
  "Two lanes framed the same 6,591 bytes two incompatible ways -- a 72-byte
   24x24 glyph grid fixed by DLHandler_Glyph24x24, and 121 variable-size
   objects bounded by the pointer table at 0xF003F9.  Which is right, on the
   consuming code's arithmetic rather than on which one draws nicer pictures?"

  Answer: THE GRID.  And the pointer table is not an index of this sheet -- it
  is not an index of anything this tree can resolve, in either of the two
  regions it points into.  Section 3 states that as a measurement, not as an
  impression.

  `--emit` writes the assembly for 0xF78028-0xF7A19F.  `--evidence` prints
  every number below from the ROMs.  `--selftest` refuses if any of them moved.

  Run:
      python3 notes/gen_prom_b_f78028_icon_sheet.py --evidence
      python3 notes/gen_prom_b_f78028_icon_sheet.py --selftest
      python3 notes/gen_prom_b_f78028_icon_sheet.py --emit > /tmp/block.s

--------------------------------------------------------------------------------
1. WHAT FIXES THE GRID -- four independent things, none of them a picture
--------------------------------------------------------------------------------
  (a) THE HANDLER'S OWN ARITHMETIC.  DLHandler_Glyph24x24, prom_b 0xF31ACE,
      display-list opcode 0x23:

          ld A,(XIY+0x02)      ; the record's index byte
          extz WA
          mul WA,0x0048        ; * 72
          ld XIY,0x00F78028    ; the base
          add XIY,XWA
          ldw BC,0x0003        ; 3 columns
          ldw HL,0x0018        ; 24 rows
          ldb A,0x03 / swi 7   ; LCD_Svc_03_BlitColumns

      3 columns x 8 px = 24 wide, 24 tall, and 3 * 24 = 72 = the stride.  The
      stride and the blit size agree, which a coincidence does not do.

  (b) THE ONLY REFERENCE.  Scanning all four ROM images for the 24-bit
      immediate 0xF78028 returns EXACTLY ONE hit -- the `ld XIY` at 0xF31AE1
      above.  Nothing else in the machine names the base of this array.

  (c) THE ARRAY ENDS EXACTLY ON THE GRID.  The 0x0E (`ret`) padding that runs
      to the end of prom_b's used space begins at 0xF7A1A0, and

          0xF7A1A0 - 0xF78028 = 8568 = 119 * 72     exactly, remainder 0

      The highest index any op-0x23 record in the tree carries is 118, i.e.
      119 cells.  Two numbers that were derived from different things -- the
      end of the data and the largest index the UI ever asks for -- agree.
      A wrong stride has a 1-in-72 chance of dividing the span at all.

  (d) THE PHASE, from the pixels, on a test that CAN fail.  A 24x24 icon
      usually leaves its first and last raster line blank, so for each of the
      72 possible grid phases count how often the six bytes at cell offsets
      0, 23, 24, 47, 48, 71 (row 0 and row 23 of each of the three columns)
      are zero.  Phase 0 -- the handler's -- wins, tied only with 24 and 48,
      which are the same phase shifted by a whole column and cannot be
      distinguished by a test symmetric in the columns.  See --evidence.
      (This is NOT the edge-density statistic that notes/FINDINGS-image-files.md
      section 1.2 shows cannot find grid phase; it is a different quantity and
      it is offered as corroboration of an answer the code already gives.)

--------------------------------------------------------------------------------
2. WHAT THE CELLS ARE
--------------------------------------------------------------------------------
  The machine's UI icon set: MIDI plugs, EDIT / ROM-ORIG / GENERAL MIDI /
  PRESET / SONGS / SMF / DISK / SOUND / COMBI labels, a keyboard, a tuning
  fork, a metronome, a clock, disks, waveforms, envelope curves, a grand
  piano, a mixer.  Every cell is exported as a PNG by
  scripts/build/wsa1_bitmaps.py (`DLGlyph_<n>_<addr>.png`), and
  `make images-check` asserts the `.byte` rows below still equal those PNGs.

  Pixel format (LCD_Svc_03_BlitColumns, prom_a 0xF8EDB4): COLUMN-MAJOR, one
  byte = 8 horizontal pixels, MSB leftmost,

      pixel (x, y) = bit (7 - x%8) of byte (x//8) * 24 + y

  so each of the three `.byte` lines per cell below is ONE 8-pixel-wide
  column, top to bottom.

--------------------------------------------------------------------------------
3. ⚠ WHY `PtrTable_F003F9` IS **NOT** THIS SHEET'S INDEX
--------------------------------------------------------------------------------
  The tree previously carried 110 `Bitmap_F78*` labels whose extents came from
  the 4-byte pointers at 0xF003F9.  That framing is refuted, and not by taste:

  * ITS TARGETS ARE NOT ON THE GRID.  121 distinct targets land in this span;
    exactly ONE of them is a multiple of 72 from 0xF78028.  Chance alone would
    give 121/72 = 1.7.  The targets are at chance level with respect to the
    grid the handler computes -- i.e. they carry no information about it.

  * IT FAILS THE SAME WAY IN ITS OTHER TARGET REGION.  The same table (see
    below: it is ONE 18-column table, not the "181 slots + 35 slots" this tree
    used to say) also points into prom_a's DisplayList_FC4000, whose record
    framing IS proven -- a strict op/len walk from 0xFC4000 reaches 0xFC482F
    with zero resyncs.  Of its 24 targets there, 3 land on a record boundary,
    against 1.8 expected by chance.  Chance level again.  A table that indexes
    neither of the two things it points at is not an index of either.

  * NOTHING LOADS ITS ADDRESS.  Scanning all four images for the immediate
    0xF003F9 (3-byte and 4-byte forms) returns 0 hits.

  * THE CONTROL.  The table 185 bytes earlier at 0xF00340, in the same span
    and built the same way, DOES have a consumer -- `add XBC,0x00F0033C` at
    0xF00D51 and `add XBC,0x00F00384` at 0xF00D92 -- and 25 of its 26 distinct
    targets begin `EE 0C` (`link XIZ,0x0000`), a function prologue.  So the
    instrument used here can find a live table when there is one; it is not
    returning "no" to everything.

  WHAT THE TABLE ACTUALLY IS, as far as it can be taken: 216 consecutive
  4-byte slots at 0xF003F9-0xF00758, shaped 18 COLUMNS x 12 ROWS.  Every row
  has 0x00000000 in column 17 and the "absent" filler 0x00FDB10E in columns 13
  and 14; columns 15 and 16 are always in DESCENDING address order; and the
  delta between consecutive targets is near-constant DOWN a column (column 15
  is 52 bytes in six successive rows, then 32 in three).  Rows 0-9 point into
  this icon sheet, rows 10-11 into prom_a 0xFC4082-0xFC4454.  So the table has
  real structure and is not noise -- but the structure describes objects that
  are not in either region under any framing this tree can prove, and the
  0x00FDB10E filler is not even an instruction boundary (it is the second byte
  of `lda XBC,(XIZ-12)` at prom_a 0xFDB10C).

  ⚠ THIS IS THEREFORE STILL AN OPEN RESEARCH TARGET -- but a sharper one than
  "nobody can say what this is": the question is no longer *what does the icon
  sheet contain* (it contains 119 icons) but *what did 0xF003F9's 216 slots
  index, given that in this build they resolve to nothing in either of the two
  regions they name*.  A vestigial index left by the authoring tool after the
  resources it described were relaid out is the hypothesis this file cannot
  test, because there is no second build of this firmware to compare against.
"""
import argparse
import pathlib
import re
import struct
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent            # .../wsa1
IMAGES = {
    'prom_a': (0xF80000, ROOT / 'original_ROMs' / 'wsa1_prom_a.ic12'),
    'prom_b': (0xF00000, ROOT / 'original_ROMs' / 'wsa1_prom_b.ic13'),
    'prom_c': (None,     ROOT / 'original_ROMs' / 'wsa1_prom_c.ic28'),
    'prom_d': (None,     ROOT / 'original_ROMs' / 'wsa1_prom_d.bin'),
}
SRC_B = ROOT / 'prom_b' / 'wsa1_prom_b.s'

BASE = 0xF78028          # DLHandler_Glyph24x24's `ld XIY,0x00F78028`
STRIDE = 72              # its `mul WA,0x0048`
BC, HL = 3, 24           # its `ldw BC,0x0003` / `ldw HL,0x0018`
FILL_START = 0xF7A1A0    # where the 0x0E `ret` padding begins
NCELLS = (FILL_START - BASE) // STRIDE       # 119, asserted below
PTRTAB = 0xF003F9
PTRTAB_SLOTS = 216       # 18 columns x 12 rows, ends at 0xF00758
DL_FC4000 = (0xFC4000, 0xFC482F)


def load(name):
    base, path = IMAGES[name]
    return base, path.read_bytes()


def rb(name, addr, n=1):
    base, d = load(name)
    return d[addr - base:addr - base + n]


# ---------------------------------------------------------------- evidence
def imm_hits(value):
    """Every offset in any of the four images holding `value` as a 24-bit LE
    immediate (the encoding `ld XIY,0x00F78028` uses: 3 bytes + a 0x00)."""
    pat = struct.pack('<I', value)[:3]
    out = []
    for name, (base, path) in IMAGES.items():
        d = path.read_bytes()
        for m in re.finditer(re.escape(pat), d):
            o = m.start()
            out.append((name, f"0x{base + o:06X}" if base else f"+0x{o:06X}"))
    return out


def ptr_table():
    _, b = load('prom_b')
    off = PTRTAB - 0xF00000
    return [struct.unpack('<I', b[off + 4 * k:off + 4 * k + 4])[0]
            for k in range(PTRTAB_SLOTS)]


def sheet_targets():
    return sorted({v for v in ptr_table() if BASE <= v < FILL_START + 0x260})


def prom_a_targets():
    return [v for v in ptr_table() if DL_FC4000[0] <= v < DL_FC4000[1]]


def dl_boundaries():
    """Record starts of prom_a's DisplayList_FC4000, by the strict op/len walk
    the prom_a lane proved reaches 0xFC482F with zero resyncs."""
    base, d = load('prom_a')
    a, out = DL_FC4000[0], []
    while a < DL_FC4000[1]:
        out.append(a)
        ln = d[a - base + 1]
        if ln == 0:
            break
        a += ln
    return out


def phase_scores():
    """For each of the 72 possible grid phases, the fraction of the six
    'blank margin' byte positions per cell that are zero."""
    _, b = load('prom_b')
    span = b[BASE - 0xF00000:FILL_START - 0xF00000]
    n = len(span) // STRIDE
    out = []
    for phi in range(STRIDE):
        z = t = 0
        for k in range(n - 1):
            c = phi + STRIDE * k
            for p in (0, HL - 1, HL, 2 * HL - 1, 2 * HL, 3 * HL - 1):
                if c + p < len(span):
                    t += 1
                    z += (span[c + p] == 0)
        out.append((z / t, phi))
    return out


def op23_indices():
    """Every op-0x23 display-list record in the committed sources, as
    {index: count}.  The sources are byte-exact against the dumps (the build
    gate), so this is a reading of the ROMs through a transcription, not a
    guess: a record is `23 05 <index> <pos16>`."""
    hits = {}
    for p in (SRC_B, ROOT / 'prom_a' / 'wsa1_prom_a.s'):
        if not p.exists():
            continue
        lines = p.read_text(encoding='latin-1').split('\n')
        for i, l in enumerate(lines):
            if '.byte 0x23, 0x05' in l and '0xF31ACE' in l:
                m = re.search(r'\.byte\s+(0x[0-9A-Fa-f]+)', lines[i + 1])
                if m:
                    k = int(m.group(1), 16)
                    hits[k] = hits.get(k, 0) + 1
    return hits


def evidence(verbose=True):
    n = {}
    _, b = load('prom_b')

    n['span'] = FILL_START - BASE
    n['ncells'] = NCELLS
    n['span_mod_stride'] = (FILL_START - BASE) % STRIDE
    fill = b[FILL_START - 0xF00000:0xF7A400 - 0xF00000]
    n['fill_pure'] = set(fill) == {0x0E}
    n['fill_len'] = len(fill)
    n['byte_below_fill'] = b[FILL_START - 0xF00000 - 1]

    n['base_imm_hits'] = imm_hits(BASE)
    n['ptrtab_imm_hits'] = imm_hits(PTRTAB)

    idx = op23_indices()
    n['op23_records'] = sum(idx.values())
    n['op23_distinct'] = len(idx)
    n['op23_max'] = max(idx)

    t = sheet_targets()
    n['sheet_targets'] = len(t)
    n['on_grid'] = sum(1 for v in t if (v - BASE) % STRIDE == 0)
    n['on_grid_expected'] = len(t) / STRIDE

    bnd = set(dl_boundaries())
    pat = prom_a_targets()
    n['dl_boundaries'] = len(bnd)
    n['dl_bytes'] = DL_FC4000[1] - DL_FC4000[0]
    n['proma_targets'] = len(pat)
    n['proma_on_boundary'] = sum(1 for v in pat if v in bnd)
    n['proma_expected'] = len(pat) * len(bnd) / n['dl_bytes']

    ph = sorted(phase_scores(), reverse=True)
    n['phase_top'] = ph[:4]
    n['phase_of_0'] = [p for _, p in ph].index(0) + 1

    # the control: the neighbouring table that DOES have a consumer
    tbl0 = [struct.unpack('<I', b[0x340 + 4 * k:0x340 + 4 * k + 4])[0]
            for k in range(35)]
    tg = sorted({v for v in tbl0 if 0xF01200 <= v < 0xF014E8})
    n['f00340_targets'] = len(tg)
    n['f00340_prologue'] = sum(1 for v in tg if b[v - 0xF00000:v - 0xF00000 + 2] == b'\xee\x0c')

    if verbose:
        print(f"span 0x{BASE:06X}-0x{FILL_START:06X} = {n['span']} B "
              f"= {n['ncells']} * {STRIDE}, remainder {n['span_mod_stride']}")
        print(f"0x0E padding after it: {n['fill_len']} B, pure={n['fill_pure']}, "
              f"byte below it = 0x{n['byte_below_fill']:02X} (not 0x0E)")
        print(f"immediate 0x{BASE:06X} in the four images: {n['base_imm_hits']}")
        print(f"immediate 0x{PTRTAB:06X} in the four images: {n['ptrtab_imm_hits']}")
        print(f"op-0x23 records: {n['op23_records']} using {n['op23_distinct']} "
              f"distinct indices, max index {n['op23_max']}  -> {n['op23_max']+1} cells")
        print(f"phase test: phase 0 ranks {n['phase_of_0']} of 72; top four "
              f"{[(round(s,4), p) for s, p in n['phase_top']]}")
        print(f"PtrTable_F003F9: {n['sheet_targets']} targets in the sheet, "
              f"{n['on_grid']} on the 72-byte grid (chance {n['on_grid_expected']:.1f})")
        print(f"PtrTable_F003F9: {n['proma_targets']} targets in DisplayList_FC4000, "
              f"{n['proma_on_boundary']} on a record boundary "
              f"(chance {n['proma_expected']:.1f}; {n['dl_boundaries']} boundaries "
              f"in {n['dl_bytes']} B)")
        print(f"CONTROL, the live table at 0xF00340: {n['f00340_prologue']} of "
              f"{n['f00340_targets']} distinct targets start `EE 0C` (link XIZ,0)")
    return n


def layout():
    """Print PtrTable_F003F9 as the 18-column x 12-row table it is."""
    tbl = ptr_table()
    t = sheet_targets()
    ends = dict(zip(t, t[1:] + [t[-1]]))
    for r in range(12):
        row = tbl[r * 18:(r + 1) * 18]
        cells = []
        for v in row:
            if v == 0:
                cells.append('  ----  ')
            elif v == 0x00FDB10E:
                cells.append('  ....  ')
            elif v in ends and ends[v] != v:
                cells.append(f'{v:06X}+{ends[v]-v:<2d}'[:8].ljust(8))
            else:
                cells.append(f'{v:06X}  ')
        print(f"row{r:2d} @0x{PTRTAB + r*72:06X} " + ' '.join(cells))


# ---------------------------------------------------------------- emitter
def emit():
    _, b = load('prom_b')
    idx = op23_indices()
    out = []
    w = out.append
    w("; ==============================================================================")
    w("; 0xF78028-0xF7A19F -- THE UI ICON SHEET: 119 CELLS OF 24x24, 72 BYTES EACH")
    w("; ==============================================================================")
    w(";")
    w("; 8,568 bytes.  DATA: no instruction in any of the four ROM images calls or")
    w("; jumps into it, and the 0xF40000 routine directory has 0 slots pointing here.")
    w(";")
    w("; ★ THE GRID IS THE HANDLER'S OWN ARITHMETIC, not a stride read off the data.")
    w(";   DLHandler_Glyph24x24 (display-list opcode 0x23, prom_b 0xF31ACE) is")
    w(";")
    w(";       ld A,(XIY+0x02) / extz WA / mul WA,0x0048 / ld XIY,0x00F78028")
    w(";       add XIY,XWA / ldw BC,0x0003 / ldw HL,0x0018 / ldb A,0x03 / swi 7")
    w(";")
    w(";   0x48 = 72 = 3 * 24, so the stride equals the blit size: 3 columns of 8")
    w(";   pixels by 24 rows.  Scanning all four images for the 24-bit immediate")
    w(";   0xF78028 returns EXACTLY ONE hit -- that `ld XIY` -- so this is the only")
    w(";   code in the machine that names the array at all.")
    w(";")
    w("; ★ AND THE ARRAY ENDS EXACTLY ON THAT GRID.  The 0x0E (`ret`) padding below")
    w(";   begins at 0xF7A1A0, and 0xF7A1A0 - 0xF78028 = 8568 = 119 * 72 with no")
    w(";   remainder; the highest index any op-0x23 record in the tree carries is 118,")
    w(";   i.e. 119 cells.  The end of the data and the largest index the UI asks for")
    w(";   are different measurements and they give the same count.")
    w(";")
    w("; PIXEL FORMAT (LCD_Svc_03_BlitColumns, prom_a 0xF8EDB4): COLUMN-MAJOR, one")
    w("; byte = 8 horizontal pixels, MSB leftmost:")
    w(";       pixel (x, y) = bit (7 - x%8) of byte (x//8) * 24 + y")
    w("; so each `.byte` line below is ONE 8-pixel-wide column, top row first.")
    w("; Every cell is also a PNG under prom_b/images/; `make images-check` asserts")
    w("; these rows and those PNGs are the same pixels.")
    w(";")
    w("; ⚠ WHAT THIS BLOCK REPLACES, AND WHY.  Until now these bytes carried 110")
    w(";   `Bitmap_F78*` labels whose extents came from the pointer table at")
    w(";   0xF003F9.  That framing is REFUTED: of the 121 targets that table has in")
    w(";   this span exactly ONE is a multiple of 72 from 0xF78028, against 1.7")
    w(";   expected by chance, so the targets carry no information about the grid;")
    w(";   the same table fails identically in its other target region (3 of its 24")
    w(";   targets in prom_a's DisplayList_FC4000 land on a record boundary, against")
    w(";   1.8 by chance); and no immediate in any of the four images equals")
    w(";   0xF003F9.  See the header on PtrTable_F003F9 and")
    w(";   notes/gen_prom_b_f78028_icon_sheet.py --evidence.")
    w(";")
    w("; Re-derive all of it, and this text, with")
    w(";     python3 notes/gen_prom_b_f78028_icon_sheet.py --evidence --selftest")
    w("; ==============================================================================")
    for i in range(NCELLS):
        ad = BASE + i * STRIDE
        used = idx.get(i, 0)
        w("")
        w("; ---------------------------------------------------------------------")
        if used:
            u = (f"named by {used} op-0x23 display-list record"
                 f"{'s' if used != 1 else ''}")
        else:
            u = "no op-0x23 record in the four images carries this index"
        w(f"; DLGlyph_{i:03d}_{ad:06X} -- icon sheet cell {i}.  24x24, 72 bytes, column-major.")
        w(f"; Evidence: DLHandler_Glyph24x24 (0xF31ACE) computes 0xF78028 + {i} * 0x48;")
        w(f";           {u}.")
        w(f"; Image:    prom_b/images/DLGlyph_{i:03d}_{ad:06X}.png")
        w("; ---------------------------------------------------------------------")
        w(f"DLGlyph_{i:03d}_{ad:06X}:")
        for c in range(BC):
            col = b[ad - 0xF00000 + c * HL:ad - 0xF00000 + (c + 1) * HL]
            vals = ', '.join(f'0x{v:02X}' for v in col)
            w(f"\t.byte {vals}\t; {ad + c*HL:06X}  column {c} (x {c*8}-{c*8+7}), rows 0-23")
    return '\n'.join(out)


def selftest():
    n = evidence(verbose=False)
    fails = []

    def chk(cond, msg):
        if not cond:
            fails.append(msg)

    chk(n['span_mod_stride'] == 0,
        "0xF7A1A0-0xF78028 is not a whole number of 72-byte cells")
    chk(n['ncells'] == 119, f"cell count is {n['ncells']}, expected 119")
    chk(n['fill_pure'], "the 0x0E run below the sheet is not pure 0x0E")
    chk(n['byte_below_fill'] != 0x0E,
        "the byte below the 0x0E run is itself 0x0E -- the fill boundary is not "
        "where this file says")
    chk(n['base_imm_hits'] == [('prom_b', '0xF31AE1')],
        f"immediate 0xF78028 hits moved: {n['base_imm_hits']}")
    chk(n['ptrtab_imm_hits'] == [],
        f"something now loads 0xF003F9: {n['ptrtab_imm_hits']} -- the refutation "
        "in section 3 must be revisited")
    chk(n['op23_max'] == 118, f"max op-0x23 index is {n['op23_max']}, expected 118")
    chk(n['op23_max'] + 1 == n['ncells'],
        "the largest op-0x23 index and the cell count no longer agree")
    chk(n['on_grid'] <= 3,
        f"{n['on_grid']} of the pointer table's targets are on the 72-byte grid "
        "-- more than chance; section 3 must be revisited")
    chk(n['proma_on_boundary'] <= 4,
        f"{n['proma_on_boundary']} of the pointer table's prom_a targets are record "
        "boundaries -- more than chance; section 3 must be revisited")
    chk(n['phase_of_0'] <= 3, f"grid phase 0 ranks {n['phase_of_0']} of 72")
    chk(n['f00340_prologue'] >= 24,
        f"the CONTROL table at 0xF00340 now hits only {n['f00340_prologue']} "
        f"prologues of {n['f00340_targets']} -- the instrument may be broken")

    # the emitted block must be the ROM
    _, b = load('prom_b')
    got = bytearray()
    for line in emit().split('\n'):
        m = re.match(r'\t\.byte (.*?)\t;', line)
        if m:
            got += bytes(int(v, 16) for v in m.group(1).split(', '))
    want = b[BASE - 0xF00000:FILL_START - 0xF00000]
    chk(bytes(got) == want,
        f"emitted bytes != ROM ({len(got)} vs {len(want)})")

    for f in fails:
        print("FAIL:", f)
    print("selftest:", "OK" if not fails else f"{len(fails)} FAILURE(S)")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--evidence', action='store_true')
    ap.add_argument('--layout', action='store_true',
                    help='print PtrTable_F003F9 as its 18x12 grid')
    ap.add_argument('--emit', action='store_true')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if not any(vars(a).values()):
        ap.print_help()
        return 0
    if a.evidence:
        evidence()
    if a.layout:
        layout()
    if a.emit:
        print(emit())
    if a.selftest:
        return selftest()
    return 0


if __name__ == '__main__':
    sys.exit(main())
