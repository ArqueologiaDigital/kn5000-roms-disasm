#!/usr/bin/env python3
"""Map every block of a `.LSW` file onto the KN5000 RAM region it comes from / goes to.

QUESTION ANSWERED
-----------------
`docs/IS-IT-DONE.md` item 1: "the handler moves 0x640 + 0x800 bytes and the file is
0x5800, so the region-to-block mapping is unread."

It is readable, and the firmware states it twice -- once as a WRITER and once as a
READER, and the two describe DIFFERENT files:

  * `FileIO_SaveRegion0_VRAM` (type 0 = `.LSW`) writes the KN5000's OWN `.LSW`:
    0x640 bytes from 0x00F980 followed by 0x800 bytes from 0x1E7800, raw, no header,
    no packing -> 0xE40 bytes total.

  * `FileIO_LoadRegion0_VRAM` first runs `FileIO_CheckRegionSignature(0)`, which
    demands the two bytes `"HK"` at FILE OFFSET 4 (table at 0xEA0104).  When that
    FAILS it does not give up: it calls `FileData_AllocLoadAndParse`, which reads the
    32-byte header, classifies it on bytes [4],[5] --

        'M','4' -> format 1      'M','6' -> format 2      'N','N' -> format 3

    -- and for formats 1 and 2 runs a two-stage IMPORTER whose hard-coded offsets are
    exactly the 22,528-byte layout of the seven floppies in `KN7000/floppy-archive`.
    Those files open `5A 5A 01 00 "M60" 0A`, i.e. bytes [4],[5] = 'M','6' = format 2.

So the 0x5800 file is not a foreign format this firmware cannot read.  It is the
"M60" revision of the same format, and the KN5000 has a converter for it.

WHAT THE PROBE CHECKS (all of it exits non-zero on failure)
-----------------------------------------------------------
ROM side, on v7 + v9 + v10:
  R1  the type-0 signature table entry is  ptr->"HK", offset 4, length 2
  R2  the factory-default panel image is ROM 0xEDB3DC (0x20 header) + 0xEDB3FC
      (0x620 TLV), copied to 0x00F980 / 0x00F9A0 by one routine; it parses as two
      TLV blocks whose terminators land at +0x3DE and +0x63E, and its own bytes
      [4],[5] are "HK" -- i.e. the DEFAULT PANEL AREA SATISFIES THE LOADER'S OWN
      TYPE-0 SIGNATURE CHECK.  That is what proves 0x00F980..0x00F9A0 is the file
      header rather than 32 unexplained bytes.
  R3  the header classifier really tests ('M','4'), ('M','6'), ('N','N')
  R4  stage 1 of the importer allocates 0x680, reads 0x660 after the 32-byte header,
      and carries 37 (source, destination) offset constants in a fixed order
  R5  stage 2 reads 0x300 per panel memory into 0x1ED400 + 960*j, 24 of them for
      format 1 and 10 for format 2; 960 == the size of TLV block 0, and
      (0x200000 - 0x1ED400) / 960 == 80 panel memories exactly
  R6  the 0x1E7800 region's factory default (ROM 0xE47F7F, 0x7E0 bytes) opens
      `5A 5A 5A` + `48 00 4B` + u16 count, and 0x10 + 10*count == 0x7E0 exactly

FILE side, on every `.LSW` given:
  F1  header bytes [4],[5] == 'M','6' -> classifier says format 2, so the KN5000
      takes the importer path and NOT the native path
  F2  every one of the 37 stage-1 source constants lands exactly on the start of a
      TLV record in file block 0, and the tag there equals the tag the matching
      destination constant lands on in the firmware's own panel image
  F3  the same for stage 2 against every 0x300 slot block: 37 constants, 37 tags
  F4  size accounting for the whole 0x5800

USAGE
    python3 analysis/disk-format-probes/lsw_region_to_block_map.py            # ROM only
    python3 analysis/disk-format-probes/lsw_region_to_block_map.py /tmp/disk/*/
    python3 analysis/disk-format-probes/lsw_region_to_block_map.py --quiet /tmp/disk/*/

Recreate the corpus with:
    mkdir -p /tmp/disk && cd /tmp/disk
    for z in ~/compartilhado/KN7000/floppy-archive/*.zip; do
        n=$(basename "$z" .zip); mkdir -p "$n"; unzip -o -q -d "$n" "$z"; done
"""
import os, struct, sys, glob

HERE = os.path.dirname(os.path.abspath(__file__))
ROMDIR = os.path.join(HERE, '..', '..', 'original_ROMs')
LOAD = 0xE00000
REVS = ('v7', 'v9', 'v10')

# ---- addresses that are the same in every revision (data, not code) ---------
SIGTABLE      = 0xEA0104      # 8 entries { u32 ptr ; u16 file offset ; u16 length }
PANEL_DEFAULT = 0xEDB3DC      # 0x20 header, then 0x620 of TLV at 0xEDB3FC
PANEL_BASE    = 0x00F980      # where the writer starts
PANEL_TLV     = 0x00F9A0
PANEL_END     = 0x00FFC0
STYLEVOICE    = 0x1E7800      # the writer's second region
STYLEVOICE_END= 0x1E8000
PM_BASE       = 0x1ED400      # panel memories
PM_END        = 0x200000
PM_STRIDE     = 960

# ---- anchors used to find the two importer stages in any revision -----------
A_WRITER     = bytes.fromhex('bfea373ebf1660f1c0ff31f180f930')  # type-0 save handler prologue
A_CLASSIFIER = bytes.fromhex('880423e865cbcf4d')   # ld C,(XWA+4) / inc 5,XWA / cp C,0x4d
A_STAGE1     = bytes.fromhex('0b8006')             # push 0x0680        at stage1 + 0x12
A_STAGE2     = bytes.fromhex('bf0c020a00')         # ld (XSP+0xc),0x000a at stage2 + 0x10
STAGE1_LEN   = 0x1CA
STAGE2_LEN   = 0x224

# ---- the record sequence both stages walk, in the order the code walks it ---
# (tag, how many, "single" or the loop it belongs to).  Tags are asserted, not assumed.
EXPECTED_TAGS = ([0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,
                  0x0C,0x0D,0x0E,0x0F,0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x19]
                 + [0x44,0x45,0x46] + [0x48] + [0x90] + [0x60] + [0x61,0x63]
                 + [0x70] + [0x72] + [0x92] + [0x71] + [0x80])

# The exact immediate sequence each stage carries, in address order, as extracted by
# extract_constants() below.  Asserting the WHOLE list pins every constant in the
# converter; the (file -> RAM) plan underneath is then built from named indices into it.
STAGE1_CONSTS = [('SRCB', 0x20), ('DSTS', 0x660),
                 ('SRCS', 0x20), ('SRCB', 0x20), ('DSTS', 0x1A), ('DSTB', 0x34), ('CNT', 0x18),
                 ('SRCS', 0x04), ('SRCB', 0x320), ('SRCB', 0x2A4), ('CNT', 0x03),
                 ('SRC1', 0x344), ('DST1', 0x2D8),
                 ('SRC1', 0x354), ('DST1', 0x2E4),
                 ('SRC1', 0x35C), ('DST1', 0x2EC),
                 ('SRCS', 0x20), ('SRCB', 0x36A), ('DSTS', 0x1A), ('DSTB', 0x2F2), ('CNT', 0x02),
                 ('SRC1', 0x3AA), ('DST1', 0x380),
                 ('SRC1', 0x3B8), ('DST1', 0x38A),
                 ('SRC1', 0x3C8), ('DST1', 0x39A),
                 ('SRC1', 0x3D8), ('DST1', 0x3AA),
                 ('SRC1', 0x3DE), ('DST1', 0x3CE)]

STAGE2_CONSTS = [('DSTS', 0x300),
                 ('SRCS', 0x10), ('SRCS', 0x40),
                 ('SRCS', 0x08), ('DSTS', 0x1A), ('DSTB', 0x14), ('CNT', 0x18),
                 ('SRCS', 0x04), ('SRCB', 0x240), ('SRCB', 0x284), ('CNT', 0x03),
                 ('SRC1', 0x264), ('DST1', 0x2B8),
                 ('SRC1', 0x270), ('DST1', 0x2C4),
                 ('SRC1', 0x277), ('DST1', 0x2CC),
                 ('SRCS', 0x20), ('SRCB', 0x285), ('DSTS', 0x1A), ('DSTB', 0x2D2), ('CNT', 0x02),
                 ('SRC1', 0x2C5), ('DST1', 0x360),
                 ('SRC1', 0x2CC), ('DST1', 0x36A),
                 ('SRC1', 0x2DC), ('DST1', 0x37A),
                 ('SRC1', 0x2EC), ('DST1', 0x38A),
                 ('SRC1', 0x2F2), ('DST1', 0x3AE)]

# Two strides are computed with add/add/shift rather than a single immediate, so they
# are asserted as instruction bytes instead:
MUL12 = bytes.fromhex('e981e881e9ee02')      # XBC = 3*i << 2   -> stride 12
MUL24 = bytes.fromhex('e981e881e9ee03')      # XBC = 3*i << 3   -> stride 24
MUL960 = bytes.fromhex('e9ee04e8a1e9ee06')   # XBC = ((i<<4)-i) << 6 -> stride 960


def build_plan(C, file_base_of_first_loop, first_loop_stride):
    """(file_offset, ram_offset) plan, built from named indices into the constant list."""
    v = [x[1] for x in C]
    return [('LOOP', file_base_of_first_loop, first_loop_stride, v[5], v[4], v[6]),
            ('LOOP', v[8], 12, v[9], 12, v[10]),
            ('ONE', v[11], v[12]),
            ('ONE', v[13], v[14]),
            ('ONE', v[15], v[16]),
            ('LOOP', v[18], v[17], v[20], v[19], v[21]),
            ('ONE', v[22], v[23]),
            ('ONE', v[24], v[25]),
            ('ONE', v[26], v[27]),
            ('ONE', v[28], v[29]),
            ('ONE', v[30], v[31])]


FAILS = []
def check(cond, msg):
    if not cond:
        FAILS.append(msg)
    return cond


def find_one(rom, pat, what):
    i = rom.find(pat)
    if i < 0 or rom.find(pat, i + 1) >= 0:
        FAILS.append('%s: anchor not unique in ROM' % what)
        return None
    return LOAD + i


def extract_constants(rom, start, length):
    """Pull the (src, dst, count) immediates out of a converter stage, in address order.

    Only five encodings matter, and they are the ones the two stages use:
        f3 e1 <u16> 30   lda XWA,XWA+d16   -> SRC, a single record
        f3 e5 <u16> 31   lda XBC,XBC+d16   -> DST, a single record
        e8/e9 c8 <u32>   add XWA/XBC,imm   -> SRC base of a loop
        eb c8 <u32>      add XHL,imm       -> DST base of a loop
        41 <u32>         ld  XBC,imm       -> DST stride of a loop (26)
        e9 ee <n>        sll n,XBC         -> SRC stride of a loop (1<<n)
        9f 0X 3f <u16>   cp (XSP+X),imm16  -> loop trip count
    """
    out = []
    b = rom[start - LOAD:start - LOAD + length]
    i = 0
    while i < len(b) - 5:
        if b[i:i + 2] == b'\xf3\xe1' and b[i + 4] == 0x30:
            out.append(('SRC1', struct.unpack('<H', b[i + 2:i + 4])[0])); i += 5; continue
        if b[i:i + 2] == b'\xf3\xe5' and b[i + 4] == 0x31:
            out.append(('DST1', struct.unpack('<H', b[i + 2:i + 4])[0])); i += 5; continue
        if b[i:i + 2] in (b'\xe8\xc8', b'\xe9\xc8'):
            out.append(('SRCB', struct.unpack('<I', b[i + 2:i + 6])[0])); i += 6; continue
        if b[i:i + 2] == b'\xeb\xc8':
            out.append(('DSTB', struct.unpack('<I', b[i + 2:i + 6])[0])); i += 6; continue
        if b[i] == 0x41:
            out.append(('DSTS', struct.unpack('<I', b[i + 1:i + 5])[0])); i += 5; continue
        if b[i:i + 2] == b'\xe9\xee':
            out.append(('SRCS', 1 << b[i + 2])); i += 3; continue
        if b[i:i + 3] in (b'\x9f\x04\x3f', b'\x9f\x08\x3f'):
            out.append(('CNT', struct.unpack('<H', b[i + 3:i + 5])[0])); i += 5; continue
        i += 1
    return out


def plan_to_pairs(plan):
    """Flatten to [(file_offset, ram_offset)] in record order."""
    out = []
    for e in plan:
        if e[0] == 'LOOP':
            _, fb, fs, rb, rs, n = e
            out += [(fb + fs * k, rb + rs * k) for k in range(n)]
        else:
            out.append((e[1], e[2]))
    return out


def tlv_records(buf, start, limit=None):
    """Walk one TLV block; return [(offset, tag, len)] and the terminator offset."""
    recs, p = [], start
    end = len(buf) if limit is None else limit
    while p + 1 < end:
        t, l = buf[p], buf[p + 1]
        if t == 0xFF and l == 0xFF:
            return recs, p
        recs.append((p, t, l))
        p += 2 + l
    return recs, None


def rom_side(rev, quiet):
    path = os.path.join(ROMDIR, 'kn5000_%s_program.rom' % rev)
    rom = open(path, 'rb').read()
    R = lambda a, n: rom[a - LOAD:a - LOAD + n]

    # R0 -- the type-0 WRITER: two raw regions, one fwrite each, nothing else
    w = find_one(rom, A_WRITER, '%s writer' % rev)
    if w:
        check(R(w + 0x15, 5) == b'\xf2\x00\x78\x1e\x31' and R(w + 0x1a, 5) == b'\xf2\x00\x80\x1e\x36',
              '%s R0: writer does not size 0x1E7800..0x1E8000' % rev)
        check(R(w + 0x59, 5) == b'\x40\x80\xf9\x00\x00',
              '%s R0: first fwrite source is not 0x00F980' % rev)
        check(R(w + 0x65, 5) == b'\x40\x00\x78\x1e\x00',
              '%s R0: second fwrite source is not 0x1E7800' % rev)
        check(R(w + 0x61, 4) == R(w + 0x6c, 4),
              '%s R0: the two writes do not call the same routine' % rev)

    # R1 -- the type-0 signature the loader demands
    ptr, off, ln = struct.unpack('<IHH', R(SIGTABLE, 8))
    sig = R(ptr, ln)
    check((sig, off, ln) == (b'HK', 4, 2),
          '%s R1: type-0 signature is %r @+%d len %d, expected b"HK" @+4 len 2' % (rev, sig, off, ln))

    # R2 -- the factory-default panel image
    img = R(PANEL_DEFAULT, 0x20) + R(PANEL_DEFAULT + 0x20, 0x620)
    check(len(img) == 0x640, '%s R2: default image is not 0x640 bytes' % rev)
    check(img[4:6] == b'HK',
          '%s R2: default panel header bytes [4:6] are %r, not the b"HK" the loader checks' % (rev, img[4:6]))
    b0, t0 = tlv_records(img, 0x20)
    b1, t1 = tlv_records(img, t0 + 2 if t0 else 0)
    check(t0 == 0x3DE, '%s R2: block-0 terminator at %r, expected 0x3DE' % (rev, t0))
    check(t1 == 0x63E, '%s R2: block-1 terminator at %r, expected 0x63E' % (rev, t1))
    check(t1 is not None and t1 + 2 == 0x640, '%s R2: TLV does not end at 0x640' % rev)
    fwmap = {o: (t, l) for o, t, l in b0 + b1}

    # the copy that installs it -- Mem_Copy(0xF980, 0xEDB3DC, 0x20) then (0xF9A0, 0xEDB3FC, 0x620)
    copy = (bytes.fromhex('0b2000') + b'\x0b\xed\x00' + b'\x0b\xdc\xb3'          # push 0x20, 0x00ed, 0xb3dc
            + b'\x0b\x00\x00' + b'\x0b\x80\xf9')                                 # push 0x0000, 0xf980
    # push order differs slightly between revisions; check both immediates are present together
    hit = rom.find(b'\x0b\xdc\xb3')
    check(hit >= 0 and rom.find(b'\x0b\xfc\xb3', hit, hit + 0x40) > 0,
          '%s R2: no site copies 0xEDB3DC and 0xEDB3FC together' % rev)

    # R3 -- the header classifier
    a = find_one(rom, A_CLASSIFIER, '%s classifier' % rev)
    if a:
        c = R(a, 0x30)
        check((c[0x07], c[0x0E]) == (0x4D, 0x34), '%s R3: format 1 is not ("M","4")' % rev)
        check((c[0x18], c[0x1D]) == (0x4D, 0x36), '%s R3: format 2 is not ("M","6")' % rev)
        check((c[0x25], c[0x2A]) == (0x4E, 0x4E), '%s R3: format 3 is not ("N","N")' % rev)

    # R4 -- importer stage 1 (the current-panel block)
    s1a = find_one(rom, A_STAGE1, '%s stage1' % rev)
    s1 = s1a - 0x12 if s1a else None
    plan1 = []
    if s1:
        check(R(s1, 4) == b'\xbf\xf6\x37\x3e', '%s R4: stage 1 prologue mismatch' % rev)
        check(R(s1 + 0x34, 5) == b'\x41\x60\x06\x00\x00',
              '%s R4: stage 1 does not read 0x660 after the 32-byte header' % rev)
        c1 = extract_constants(rom, s1, STAGE1_LEN)
        check(c1 == STAGE1_CONSTS, '%s R4: stage-1 immediates differ\n   got %r' % (rev, c1))
        check(MUL12 in R(s1, STAGE1_LEN), '%s R4: stage 1 has no *12 stride' % rev)
        if c1 == STAGE1_CONSTS:
            plan1 = build_plan(c1, c1[3][1], c1[2][1])

    # R5 -- importer stage 2 (the panel memories)
    s2a = find_one(rom, A_STAGE2, '%s stage2' % rev)
    s2 = s2a - 0x10 if s2a else None
    plan2 = []
    if s2:
        check(R(s2, 4) == b'\xbf\xf2\x37\x3e', '%s R5: stage 2 prologue mismatch' % rev)
        check(R(s2 + 0x83, 5) == b'\xbf\x0c\x02\x18\x00',
              '%s R5: format-1 panel-memory count is not 24' % rev)
        check(R(s2 + 0x65, 5) == b'\x41\x00\x03\x00\x00',
              '%s R5: stage 2 does not read 0x300 per panel memory' % rev)
        check(R(s2 + 0x9f, 5) == b'\xf2\x00\xd4\x1e\x30',
              '%s R5: panel-memory base is not 0x1ED400' % rev)
        c2 = extract_constants(rom, s2, STAGE2_LEN)
        check(c2 == STAGE2_CONSTS, '%s R5: stage-2 immediates differ\n   got %r' % (rev, c2))
        check(MUL12 in R(s2, STAGE2_LEN), '%s R5: stage 2 has no *12 stride' % rev)
        check(MUL24 in R(s2, STAGE2_LEN), '%s R5: stage 2 has no *24 stride' % rev)
        check(MUL960 in R(s2, STAGE2_LEN), '%s R5: stage 2 has no *960 panel-memory stride' % rev)
        if c2 == STAGE2_CONSTS:
            plan2 = build_plan(c2, 0, 24)
    blk0 = (t0 + 2 - 0x20) if t0 else 0
    check(blk0 == PM_STRIDE,
          '%s R5: panel-memory stride %d != TLV block-0 size %d' % (rev, PM_STRIDE, blk0))
    check((PM_END - PM_BASE) % PM_STRIDE == 0 and (PM_END - PM_BASE) // PM_STRIDE == 80,
          '%s R5: 0x1ED400..0x200000 is not exactly 80 panel memories' % rev)

    # R6 -- the second saved region's factory default
    sv = R(0xE47F7F, 0x10)
    n = struct.unpack('<H', sv[6:8])[0]
    check(sv[0:3] == b'ZZZ' and sv[3:6] == b'\x48\x00\x4b',
          '%s R6: 0x1E7800 default does not open ZZZ + 48 00 4B (%r)' % (rev, sv[0:6]))
    check(0x10 + 10 * n == 0x7E0,
          '%s R6: header count %d does not describe the 0x7E0 the initialiser copies' % (rev, n))

    # tags must agree between the plan and the firmware image
    tags1 = []
    for f, r in plan_to_pairs(plan1):
        rec = fwmap.get(r)
        if rec is None:
            FAILS.append('%s R4: destination +0x%X is not a record start in the panel image' % (rev, r))
            tags1.append(None)
        else:
            tags1.append(rec[0])
    check(tags1 == EXPECTED_TAGS,
          '%s R4: stage-1 destinations do not name the expected 37 tags\n   %r' % (rev, tags1))

    if not quiet:
        print('--- %s ---' % rev)
        print('  type-0 signature      : %r at file +%d, length %d' % (sig, off, ln))
        print('  panel default image   : ROM 0x%06X..0x%06X -> RAM 0x%06X..0x%06X'
              % (PANEL_DEFAULT, PANEL_DEFAULT + 0x640, PANEL_BASE, PANEL_BASE + 0x640))
        print('  block 0: %2d records, terminator at file +0x%03X (RAM 0x%04X), 0x%03X bytes'
              % (len(b0), t0, PANEL_BASE + t0, blk0))
        print('  block 1: %2d records, terminator at file +0x%03X (RAM 0x%04X), 0x%03X bytes'
              % (len(b1), t1, PANEL_BASE + t1, t1 + 2 - (t0 + 2)))
        print('  0x1E7800 default      : ZZZ + 48 00 4B + count=%d -> 0x10 + %d*10 = 0x%X' % (n, n, 0x10 + 10 * n))
        print('  writer at 0x%06X: 0x%03X from 0x%06X then 0x%03X from 0x%06X = 0x%X bytes'
              % (w, PANEL_END - PANEL_BASE, PANEL_BASE, STYLEVOICE_END - STYLEVOICE, STYLEVOICE,
                 (PANEL_END - PANEL_BASE) + (STYLEVOICE_END - STYLEVOICE)))
        print('  importer stage 1 at 0x%06X, stage 2 at 0x%06X, classifier at 0x%06X' % (s1, s2, a))
        print('  panel memories        : 0x%06X + %d*j, %d slots'
              % (PM_BASE, PM_STRIDE, (PM_END - PM_BASE) // PM_STRIDE))
    return plan1, plan2, fwmap


def file_side(paths, plan1, plan2, fwmap, quiet):
    for p in paths:
        d = open(p, 'rb').read()
        name = os.path.basename(p)

        # F1 -- which path the KN5000 takes
        fmt = {(0x4D, 0x34): 1, (0x4D, 0x36): 2, (0x4E, 0x4E): 3}.get((d[4], d[5]))
        check(fmt == 2, '%s F1: header [4],[5] = %r -> format %r, expected 2 ("M6")'
              % (name, d[4:6], fmt))
        check(d[4:6] != b'HK', '%s F1: file claims the NATIVE signature' % name)

        # F2 -- stage 1 against block 0
        b0, t0 = tlv_records(d, 0x20)
        starts = {o: (t, l) for o, t, l in b0}
        bad = []
        for f, r in plan_to_pairs(plan1):
            fw = fwmap.get(r)
            fr = starts.get(f)
            if fr is None or fw is None or fr[0] != fw[0]:
                bad.append((f, r, fr, fw))
        check(not bad, '%s F2: %d of 37 stage-1 offsets miss or disagree: %r' % (name, len(bad), bad[:4]))
        check(len(b0) == 37, '%s F2: block 0 has %d records, expected 37' % (name, len(b0)))

        # block 1 and the slot blocks
        b1, t1 = tlv_records(d, t0 + 2)
        slot0 = t1 + 2
        check(slot0 == 0x680, '%s F2: slots start at 0x%X, expected 0x680 (the stage-1 malloc)'
              % (name, slot0))

        # F3 -- stage 2 against every 0x300 slot block
        nslot, off = 0, slot0
        while off + 0x300 <= len(d):
            blk = d[off:off + 0x300]
            recs, term = tlv_records(blk, 0)
            if term is None or term + 2 != 0x300 or len(recs) != 37:
                break
            st = {o: (t, l) for o, t, l in recs}
            for f, r in plan_to_pairs(plan2):
                fw = fwmap.get(r + 0x20)          # slot layout == live layout minus the 0x20 header
                fr = st.get(f)
                if fr is None or fw is None or fr[0] != fw[0]:
                    FAILS.append('%s F3: slot %d offset 0x%X tag %r != %r' % (name, nslot, f, fr, fw))
                    break
            nslot += 1
            off += 0x300
        check(nslot == 24, '%s F3: %d slot blocks of 0x300 parsed, expected 24' % (name, nslot))

        # F4 -- size accounting
        tailstart = off
        z = d.find(b'ZZZLKE', tailstart)
        cnt = struct.unpack('<H', d[z + 6:z + 8])[0] if z > 0 else -1
        check(z > 0, '%s F4: no ZZZ+LKE style-voice header in the tail' % name)
        check(z + 0x10 + 10 * cnt <= len(d),
              '%s F4: style-voice count %d overruns the file' % (name, cnt))
        acct = [('header',                 0x00,        0x20),
                ('TLV block 0',            0x20,        t0 + 2 - 0x20),
                ('TLV block 1',            t0 + 2,      t1 + 2 - (t0 + 2)),
                ('24 panel memories',      slot0,       0x300 * nslot),
                ('unidentified',           tailstart,   z - tailstart),
                ('style-voice table',      z,           0x10 + 10 * cnt),
                ('unidentified',           z + 0x10 + 10 * cnt, 0),
                ]
        acct[-1] = ('unidentified', z + 0x10 + 10 * cnt, 0x5480 - (z + 0x10 + 10 * cnt))
        acct.append(('mirror of this disk\'s .MSP', 0x5480, len(d) - 0x5480))
        total = sum(s for _, _, s in acct)
        check(total == len(d), '%s F4: accounting sums to 0x%X, file is 0x%X' % (name, total, len(d)))

        if not quiet:
            print('--- %s  (%d bytes) ---' % (name, len(d)))
            for what, o, s in acct:
                print('   0x%04X..0x%04X  0x%04X  %s' % (o, o + s, s, what))


def print_map(plan1, plan2, fwmap, sample):
    print('\nFULL RECORD MAP  ("M60" file offset -> KN5000 RAM address)\n')
    print('  %-8s %-4s %-5s   %-10s %-4s   %s' % ('file', 'tag', 'flen', 'RAM', 'flen', 'where'))
    st = None
    if sample:
        d = open(sample, 'rb').read()
        b0, t0 = tlv_records(d, 0x20)
        st = {o: (t, l) for o, t, l in b0}
        b1, t1 = tlv_records(d, t0 + 2)
        sl, _ = tlv_records(d[0x680:0x980], 0)
        sm = {o: (t, l) for o, t, l in sl}
    for f, r in plan_to_pairs(plan1):
        tag, ln = fwmap[r]
        fl = st[f][1] if st else -1
        print('  0x%04X   %02X   %3d     0x%06X   %3d    current panel, TLV block 0'
              % (f, tag, fl, PANEL_BASE + r, ln))
    if sample:
        for o, t, l in b1:
            print('  0x%04X   %02X   %3d     %-10s %3s    current panel, TLV block 1'
                  % (o, t, l, '-', '-'))
    print()
    for f, r in plan_to_pairs(plan2):
        tag, ln = fwmap[r + 0x20]
        fl = sm[f][1] if st else -1
        print('  +0x%03X   %02X   %3d     +0x%03X       %3d    each panel memory (0x1ED400 + 960*j)'
              % (f, tag, fl, r, ln))


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    quiet = '--quiet' in sys.argv
    paths = []
    for a in args:
        paths += sorted(glob.glob(os.path.join(a, '*.LSW'))) if os.path.isdir(a) else [a]

    plan1 = plan2 = fwmap = None
    for rev in REVS:
        p1, p2, fm = rom_side(rev, quiet)
        if plan1 is None:
            plan1, plan2, fwmap = p1, p2, fm
        else:
            check((p1, p2) == (plan1, plan2), '%s: importer plan differs from v7' % rev)

    if paths:
        file_side(paths, plan1, plan2, fwmap, quiet)
    if '--map' in sys.argv:
        print_map(plan1, plan2, fwmap, paths[0] if paths else None)
    elif not quiet:
        print('(no .LSW files given -- ROM side only)')

    if FAILS:
        print('\nFAIL (%d):' % len(FAILS))
        for f in FAILS:
            print('  * ' + f)
        return 1
    print('\nPASS: the .LSW region-to-block mapping holds on v7/v9/v10'
          + (' and on %d file(s).' % len(paths) if paths else '.'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
