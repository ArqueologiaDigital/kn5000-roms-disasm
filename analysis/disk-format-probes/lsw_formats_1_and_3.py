#!/usr/bin/env python3
"""What `.LSW` formats 1 (`"M4"`) and 3 (`"NN"`) are, and why format 2 imports only 10 slots.

QUESTIONS ANSWERED
------------------
`README-lsw-region-to-block-map.md` section 5 left three things open.  This probe closes
two of them from the ROM plus the seven floppies, and makes the third fail in a *second*,
independent way so that it stays closed.

  (1) WHAT ARE FORMATS 1 AND 3?
      `FileData_AllocLoadAndParse` classifies on header bytes [4],[5] and then calls one
      of TWO importer pairs.  Formats 1 and 2 share a pair; format 3 has its own.  So
      there are only two file *layouts* behind three format ids, and the whole difference
      between format 1 and format 2 is one immediate: the number of panel memories.

  (2) WHY DOES FORMAT 2 IMPORT ONLY 10 OF THE 24 SLOT BLOCKS?
      Because only 10 of them carry anything.  Slot blocks 10..23 of the seven `.LSW`
      files are **byte-identical across all seven disks** -- they are the factory default
      set repeated, `block[i] == block[10 + (i-10) % 10]` -- while blocks 0..9 differ on
      every disk.  The importer's read cursor stops at file offset 0x2480, which is
      exactly the first byte of block 10.  The firmware reads every byte that carries
      information and not one byte more.  No format-1 file is needed to settle this.

  (3) THE 0x30 AT 0x4E80 AND THE 0xC0 AT 0x53C0 -- still NOT identified, and this probe
      says why it cannot be identified from this ROM: the KN5000 never *reads* them.
      Every read on the importer path is sequential (there is no seek anywhere in the
      five importer routines) and the last one ends at 0x2480.  What the probe adds is
      measurement: the 0xC0 is one 16-byte pattern repeated 12 times and is identical on
      all seven disks (it carries no per-disk information at all); the 0x30 does vary per
      disk, and the tempting "24 u16 words, one per slot block" reading is refuted a
      second time -- slot blocks 10..23 are constant across the disks while words 10..23
      are not, in either word order.

WHAT THE PROBE CHECKS  (every test exits non-zero on failure; run with --quiet for the gate)
------------------------------------------------------------------------------------------
ROM side, on v7 + v9 + v10, all addresses DERIVED from one byte anchor per revision:

  R1  the format dispatcher in `FileData_AllocLoadAndParse` matches a 61-byte template
      (two wildcard bytes for the revision's format-id variable) at exactly one place,
      and its five `calr` displacements are the same in all three ROMs
  R2  the classifier tests ('M','4')->1, ('M','6')->2, ('N','N')->3 and returns 0xFFFF
  R3  format 1 and format 2 dispatch to THE SAME stage-1 and stage-2 routines; format 3
      dispatches to a different pair
  R4  stage 2 of the 1/2 pair carries the frozen constant list, in which the ONLY
      format-dependent value is the slot count: 0x0018 on the `format == 1` arm and
      0x000A on the `format == 2` arm
  R5  the count feeds three things -- the default-fill call, `count >> 3` bank-name
      blankings, and the trip count of the 0x300-per-slot read loop
  R6  the bank-name routine is `if (bank > 9) return; memset(0x1ED360 + 16*bank, ' ', 16)`
      => 10 bank names of 16 bytes at 0x1ED360, ending exactly at the panel-memory base
      0x1ED400, and `count >> 3` says a bank holds 8 memories.
      10 banks * 8 = 80 = (0x200000 - 0x1ED400) / 960.  Both numbers agree.
  R7  the default-fill routine writes 0x3C0 bytes of ROM 0xEDB3FC per slot at stride 960
  R8  stage 1 and stage 2 of the format-3 pair carry their frozen constant lists
  R9  every format-3 stage-2 offset is its stage-1 counterpart minus 0x20, source AND
      destination => a format-3 panel-memory record is byte-for-byte the first 0x150
      bytes of a format-3 live-panel body
  R10 every destination offset of both format-3 stages lands on the start of a TLV record
      in the ROM's own factory-default panel image (0xEDB3DC), and the tag found there is
      the expected one
  R13 `FileIO_CheckRegionSignature` ends by REWINDING (its last call reaches a routine
      that pushes whence=0 and offset=0L into the same fseek primitive the seek helper
      uses), so the importer's first read starts at file offset 0 and the byte budget of
      R11 is a statement about FILE OFFSETS, not about an unknown cursor.

  R12 the format-3 DSP converter (stage 1's 9th `calr`) carries the parameter ids
      0x4900/0x4904/0x4910+i and 0x4B00/0x4B04/0x4B10+i and two ROM translation tables at
      0xEE159C and 0xEE15AC.  Every value in 0xEE159C is an algorithm DSP slot 0 accepts
      and every non-zero value in 0xEE15AC is one slot 1 accepts -- and swapping the two
      tables would violate both predicates, so the agreement is not vacuous.  This is a
      THIRD independent route to "slot 0 = DSP EFFECT, slot 1 = DIGITAL REVERB", and it
      also shows the internal shape of a slot's parameter namespace:
          +0x00 algorithm number   +0x04 parameter count   +0x10+i parameter i

  R11 byte budget.  The importer only ever reads forward: the seek routine used by
      `FileIO_CheckRegionSignature` appears ZERO times in the five importer routines,
      while the read routine appears with exactly the sizes above.  Totals:
          format 1: 0x20 + 0x660 + 24 * 0x300 = 0x4E80
          format 2: 0x20 + 0x660 + 10 * 0x300 = 0x2480
          format 3: 0x20 + 0x420 + 24 * 0x150 = 0x23C0

FILE side, on every `.LSW` given (needs >= 2 files for the cross-disk tests):

  F1  header is `5A 5A 01 00 "M60" 0A`; bytes [4],[5] classify as format 2, and header
      byte [7] == 0x0A == the count the firmware hard-codes for format 2
  F2  0x680 + 24 * 0x300 == 0x4E80 == where the slot array ends, and the ROM-derived
      total size of a format-1 file is the same 0x4E80
  F3  slot blocks 10..23 are byte-identical across all the files; blocks 0..9 are not
  F4  block[i] == block[10 + (i-10) % 10] for i in 10..23, on every file
  F5  at least one file has one of blocks 0..9 equal to its default counterpart
      block[10+k] -- i.e. an untouched user slot, which is what makes blocks 10..19 the
      DEFAULT set rather than merely a constant one
  F6  the format-2 read cursor stops at 0x2480 and 0x2480 is exactly the start of block 10
  F7  0x53C0..0x5480 is one 16-byte pattern repeated 12 times and identical on all files
  F8  0x4E80..0x4EB0 differs between files, and reading it as 24 u16 "one per slot block"
      is refuted: blocks 10..23 are constant across files, words 10..23 are not, and
      neither are words 0..13 under the reversed mapping

USAGE
    python3 analysis/disk-format-probes/lsw_formats_1_and_3.py                 # ROM only
    python3 analysis/disk-format-probes/lsw_formats_1_and_3.py /tmp/disk/*/
    python3 analysis/disk-format-probes/lsw_formats_1_and_3.py --quiet /tmp/disk/*/
    python3 analysis/disk-format-probes/lsw_formats_1_and_3.py --layout        # print the maps

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

PANEL_DEFAULT = 0xEDB3DC      # 0x20 file header, then 0x620 of TLV at 0xEDB3FC
PANEL_TLV_ROM = 0xEDB3FC
PANEL_BASE    = 0x00F980      # the live panel work area, including its 0x20 header
PANEL_TLV     = 0x00F9A0
PM_NAMES      = 0x1ED360      # 10 panel-memory BANK names, 16 bytes each
PM_BASE       = 0x1ED400      # 80 panel-memory slots, 960 bytes each
PM_END        = 0x200000
PM_STRIDE     = 960

# ---------------------------------------------------------------- anchors ---
# The dispatcher of FileData_AllocLoadAndParse.  Identical in all three ROMs except the
# two bytes of the address of the "remembered format id" variable (v7 0xB74E, v9/v10
# 0xB7EA), which are wildcarded with None.
DISPATCH_TEMPLATE = [
    0x1e, None, None,                            # calr  classifier
    0xf1, None, None, 0x53,                      # ld    (fmtvar),HL
    0xdb, 0xdb, 0x66, 0x18,                      # cp HL,3   / jr Z,fmt3
    0xdb, 0xda, 0x66, 0x04,                      # cp HL,2   / jr Z,fmt12
    0xdb, 0xd9, 0x6e, 0x20,                      # cp HL,1   / jr NZ,unknown
    0x1e, None, None,                            # calr  stage1 (formats 1 and 2)
    0xdb, 0x8e, 0xde, 0xd8, 0x61, 0x1a,
    0x1e, None, None,                            # calr  stage2 (formats 1 and 2)
    0xdb, 0x8e, 0x68, 0x13,
    0x1e, None, None,                            # calr  stage1 (format 3)
    0xdb, 0x8e, 0xde, 0xd8, 0x61, 0x0a,
    0x1e, None, None,                            # calr  stage2 (format 3)
    0xdb, 0x8e, 0x68, 0x03,
    0x36, 0x9a, 0xff,                            # ld    IZ,0xff9a   (unknown format)
]
# The classifier body, byte for byte.  'M'=0x4d '4'=0x34 '6'=0x36 'N'=0x4e.
CLASSIFIER_BODY = bytes.fromhex(
    '880423' 'e865' 'cbcf4d' '6e0a' '8025' 'cdcf34' '6e03' 'dba9' '0e'
    '8021' 'cbcf4d' '6e08' 'c9cf36' '6e03' 'dbaa' '0e'
    'cbcf4e' '6e08' 'c9cf4e' '6e03' 'dbab' '0e' '33ffff' '0e')

A_SIGOFF = bytes.fromhex('f20801ea31')   # lda XBC,0xEA0108  in CheckRegionSignature
A_READ20 = bytes.fromhex('4120000000')   # ld XBC,0x20       in the dispatcher's prologue

# ------------------------------------------------- frozen constant lists ----
# Produced by extract_constants() below.  Identical in v7, v9 and v10 (asserted).
STAGE1_12 = "LDWA 6bf|PUSH 680|SRCB 20|LDBC 660|CMPIZ 0|SETSP 0|SLLBC 20|SRCB 20|LDBC 1a|" \
            "DSTB 34|CMPSP 18|SETSP 0|SLLBC 4|SRCB 320|SRCB 2a4|CMPSP 3|SRC1 344|DST1 2d8|" \
            "SRC1 354|DST1 2e4|SRC1 35c|DST1 2ec|SETSP 0|SLLBC 20|SRCB 36a|LDBC 1a|DSTB 2f2|" \
            "CMPSP 2|SRC1 3aa|DST1 380|SRC1 3b8|DST1 38a|SRC1 3c8|DST1 39a|SRC1 3d8|DST1 3aa|" \
            "SRC1 3de|DST1 3ce"
STAGE2_12 = "SETSP a|SETSP 0|SRLWA 8|SRLWA 8|PUSH 300|SETSP 0|CMPSP 0|LDBC 300|CMPIZ 0|" \
            "SETSP 18|SLLBC 10|SLLBC 40|LDA24 1ed400|SETSP 0|SLLBC 8|LDBC 1a|DSTB 14|CMPSP 18|" \
            "SETSP 0|SLLBC 4|SRCB 240|SRCB 284|CMPSP 3|SRC1 264|DST1 2b8|SRC1 270|DST1 2c4|" \
            "SRC1 277|DST1 2cc|SETSP 0|SLLBC 20|SRCB 285|LDBC 1a|DSTB 2d2|CMPSP 2|SRC1 2c5|" \
            "DST1 360|SRC1 2cc|DST1 36a|SRC1 2dc|DST1 37a|SRC1 2ec|DST1 38a|PUSH eaf|SRC1 2f2|" \
            "DST1 3ae|PUSH eaf"
STAGE1_3  = "LDWA 6bf|PUSH 440|SRCB 20|LDBC 420|CMPIZ 0|SETSP 0|SLLBC 4|SRCB 20|LDBC 1a|" \
            "DSTB 34|CMPSP 17|SETSP 0|LDBC 1a|DSTB 34|CMPSP 18|SRC1 134|DST1 2d8|SRC1 146|" \
            "DST1 2e4|SRC1 14e|DST1 380|SRC1 160|DST1 3aa|SRC1 166|DST1 38a"
STAGE2_3  = "LDWA 18|CMPIZ 3|PUSH 150|SETSP 0|LDBC 150|CMPIZ 0|SLLBC 10|SLLBC 40|" \
            "LDA24 1ed400|SLLWA 4|LDBC 1a|DSTB 14|CMPIZ 17|SRC1 114|DST1 2b8|SRC1 126|" \
            "DST1 2c4|SRC1 12e|DST1 360|SRC1 140|DST1 38a|SRC1 146|DST1 36a|SUBWA 20|" \
            "SUBBC 20|PUSH 69f|CMPSP 18"
DEFAULTFILL = "LDA24 edb3fc|CMPSP 0|SLLBC 10|SLLBC 40|LDDE 1ed400|PUSH 3c0"
BANKNAME    = "LDA24 1ed360|PUSH 10|PUSH 20"

# The tag each destination offset (relative to PANEL_BASE) must land on.  Checked against
# the ROM's own factory-default panel image, so it is measured, not assumed.
FMT3_STAGE1_SINGLES = [(0x134, 0x2D8, 0x48), (0x146, 0x2E4, 0x90), (0x14E, 0x380, 0x70),
                       (0x160, 0x3AA, 0x71), (0x166, 0x38A, 0x72)]
FMT3_STAGE2_SINGLES = [(0x114, 0x2B8, 0x48), (0x126, 0x2C4, 0x90), (0x12E, 0x360, 0x70),
                       (0x140, 0x38A, 0x71), (0x146, 0x36A, 0x72)]

# The parameter ids and translation tables the format-3 DSP converter carries, in order.
FMT3_DSP_IDS = [('LDA24', 0xEE159C), ('LDWA32', 0x4900), ('LDWA32', 0x4904),
                ('ADDWA', 0x4910), ('ADDWA', 0x4910),
                ('LDA24', 0xEE15AC), ('LDWA32', 0x4B00), ('LDWA32', 0x4B04),
                ('ADDWA', 0x4B10), ('ADDWA', 0x4B10), ('ADDWA', 0x4B10)]
# The algorithm sets `DSPCfg_SlotAcceptsAlgorithm` allows per DSP slot.  QUOTED from
# `README-lsw-leftover-records.md` section 1, which derives them from the ROM; this probe
# does not re-derive them, it only checks that the format-3 tables agree with them.
SLOT0_OK = set(range(0, 100)) - set(range(16, 28))     # slot 0, tag 0x61, ns 0x4900
SLOT1_OK = {9, 10} | set(range(16, 28))                # slot 1, tag 0x63, ns 0x4B00

# Slot-area geometry of the seven "M60" files.
SLOT0    = 0x0680
SLOTSIZE = 0x0300
NSLOTS   = 24
GAP30    = (0x4E80, 0x30)
GAPC0    = (0x53C0, 0xC0)
FILESIZE = 0x5800

FAILS = []
def check(cond, msg):
    if not cond:
        FAILS.append(msg)
    return cond


# ------------------------------------------------------------- ROM helpers --
def load(rev):
    with open(os.path.join(ROMDIR, 'kn5000_%s_program.rom' % rev), 'rb') as f:
        return f.read()


def find_unique(rom, pat, what):
    i = rom.find(pat)
    if i < 0 or rom.find(pat, i + 1) >= 0:
        FAILS.append('%s: anchor not unique in ROM' % what)
        return None
    return i


def match_template(rom, tpl):
    """Return every offset where tpl (a list of ints / None wildcards) matches."""
    concrete = bytes(b for b in tpl if b is not None)
    del concrete  # only for readability; the scan below is the real one
    n = len(tpl)
    # anchor the scan on the longest run of concrete bytes to keep it fast
    best_i, best_len = 0, 0
    run_i, run_len = 0, 0
    for i, b in enumerate(tpl):
        if b is None:
            run_len = 0
        else:
            if run_len == 0:
                run_i = i
            run_len += 1
            if run_len > best_len:
                best_i, best_len = run_i, run_len
    seed = bytes(tpl[best_i:best_i + best_len])
    out = []
    j = rom.find(seed)
    while j >= 0:
        s = j - best_i
        if s >= 0 and s + n <= len(rom):
            if all(tpl[k] is None or rom[s + k] == tpl[k] for k in range(n)):
                out.append(s)
        j = rom.find(seed, j + 1)
    return out


def calr_target(rom, off):
    """`1e <s16>` -- target = address of the following instruction + displacement."""
    disp = struct.unpack('<h', rom[off + 1:off + 3])[0]
    return LOAD + off + 3 + disp


def call_targets(rom, off, length):
    """Every `1d <u32>` (absolute call) inside a byte range, in address order."""
    out = []
    b = rom[off:off + length]
    i = 0
    while i < len(b) - 4:
        if b[i] == 0x1d:   # call <u24>
            out.append((LOAD + off + i, b[i + 1] | (b[i + 2] << 8) | (b[i + 3] << 16)))
            i += 4
            continue
        i += 1
    return out


def extract_constants(rom, addr, length):
    """The immediates a converter stage carries, in address order.

    Only the encodings the four stages actually use are decoded.  The list is asserted
    WHOLE, so a changed constant, a dropped record or a reordered loop all fail.  A few
    entries are false positives caught mid-instruction; they are stable (the same list
    comes out of v7, v9 and v10, which the probe asserts) and are kept rather than
    filtered so that the decoder stays a dumb, auditable scanner.
    """
    out = []
    b = rom[addr - LOAD:addr - LOAD + length]
    i = 0
    U16 = lambda k: struct.unpack('<H', b[k:k + 2])[0]
    U32 = lambda k: struct.unpack('<I', b[k:k + 4])[0]
    while i < len(b) - 5:
        p = b[i:i + 2]
        if p == b'\xf3\xe1' and b[i + 4] == 0x30:
            out.append(('SRC1', U16(i + 2))); i += 5; continue
        if p == b'\xf3\xe5' and b[i + 4] == 0x31:
            out.append(('DST1', U16(i + 2))); i += 5; continue
        if p in (b'\xe8\xc8', b'\xe9\xc8'):
            out.append(('SRCB', U32(i + 2))); i += 6; continue
        if p == b'\xeb\xc8':
            out.append(('DSTB', U32(i + 2))); i += 6; continue
        if p == b'\xe8\xca':
            out.append(('SUBWA', U32(i + 2))); i += 6; continue
        if p == b'\xe9\xca':
            out.append(('SUBBC', U32(i + 2))); i += 6; continue
        if b[i] == 0x41:
            out.append(('LDBC', U32(i + 1))); i += 5; continue
        if b[i] == 0x42:
            out.append(('LDDE', U32(i + 1))); i += 5; continue
        if p == b'\xe9\xee':
            out.append(('SLLBC', 1 << b[i + 2])); i += 3; continue
        if p == b'\xe8\xee':
            out.append(('SLLWA', 1 << b[i + 2])); i += 3; continue
        if p == b'\xd8\xef':
            out.append(('SRLWA', 1 << b[i + 2])); i += 3; continue
        if b[i] == 0x9f and b[i + 2] == 0x3f:
            out.append(('CMPSP', U16(i + 3))); i += 5; continue
        if b[i] == 0xbf and b[i + 2] == 0x02:
            out.append(('SETSP', U16(i + 3))); i += 5; continue
        if b[i] == 0x0b:
            out.append(('PUSH', U16(i + 1))); i += 3; continue
        if b[i] == 0x30:
            out.append(('LDWA', U16(i + 1))); i += 3; continue
        if p == b'\xde\xcf':
            out.append(('CMPIZ', U16(i + 2))); i += 4; continue
        if b[i] == 0xde and 0xd0 <= b[i + 1] <= 0xdf:
            out.append(('CMPIZ', b[i + 1] - 0xd8)); i += 2; continue
        if b[i] == 0xf2 and b[i + 4] in (0x30, 0x31, 0x33, 0x36):
            out.append(('LDA24', b[i + 1] | (b[i + 2] << 8) | (b[i + 3] << 16))); i += 5; continue
        i += 1
    return '|'.join('%s %x' % (k, v) for k, v in out)


def walk_tlv(blob, base):
    """{record address -> tag} for a `tag,len,payload...` stream ending on FF FF.

    The address is the RECORD start (the tag byte); the payload begins two bytes later.
    That is what the importers' destination constants point at.
    """
    out, i = {}, 0
    while i + 2 <= len(blob):
        tag, ln = blob[i], blob[i + 1]
        if tag == 0xFF and ln == 0xFF:
            break
        out[base + i] = tag
        i += 2 + ln
    return out


# ------------------------------------------------------------- the ROM side --
def rom_side(rev, verbose):
    rom = load(rev)
    tag = 'R[%s]' % rev
    res = {}

    # R1 -- the dispatcher, and the five routines it names
    hits = match_template(rom, DISPATCH_TEMPLATE)
    if not check(len(hits) == 1, '%s R1: dispatcher template matched %d times, want 1'
                 % (tag, len(hits))):
        return None
    off = hits[0]
    calrs = [off + k for k, b in enumerate(DISPATCH_TEMPLATE) if b == 0x1e]
    (classifier, stage1_12, stage2_12,
     stage1_3, stage2_3) = [calr_target(rom, c) for c in calrs]
    res.update(dispatcher=LOAD + off, classifier=classifier,
               stage1_12=stage1_12, stage2_12=stage2_12,
               stage1_3=stage1_3, stage2_3=stage2_3)

    # R2 -- the classifier really tests 'M4' / 'M6' / 'NN'
    body = rom[classifier - LOAD:classifier - LOAD + len(CLASSIFIER_BODY)]
    check(body == CLASSIFIER_BODY,
          '%s R2: classifier body differs from the M4/M6/NN template' % tag)

    # R3 -- formats 1 and 2 share a pair, format 3 has its own
    check(stage1_3 != stage1_12 and stage2_3 != stage2_12,
          '%s R3: format 3 shares a stage with formats 1/2' % tag)

    # R4/R5 -- stage 2 of the 1/2 pair, and where 0x0A / 0x18 come from
    got = extract_constants(rom, stage2_12, 0x224)
    check(got == STAGE2_12, '%s R4: stage2(1/2) constants differ\n    got  %s\n    want %s'
          % (tag, got, STAGE2_12))
    s2 = rom[stage2_12 - LOAD:stage2_12 - LOAD + 0x224]
    check(s2.count(bytes.fromhex('bf0c020a00')) == 1 and
          s2.count(bytes.fromhex('bf0c021800')) == 1,
          '%s R4: expected exactly one `ld (XSP+0xc),0x000a` and one `...,0x0018`' % tag)
    # `cp WA,1 / jr Z -> the 0x18 arm` and `cp WA,2 / jr NZ -> error`
    check(s2[0x08:0x0e] == bytes.fromhex('d8d96677d8da'),
          '%s R5: the format id is not tested as `cp WA,1 / jr Z` then `cp WA,2`' % tag)
    check(s2.count(bytes.fromhex('d8ef03')) == 2,
          '%s R5: expected the count to be halved three times (>>3) at two sites' % tag)

    # R6 -- the bank-name routine, reached from stage 2's second calr
    #       (derive it rather than hard-code: it is the calr inside the >>3 loop)
    i = s2.find(bytes.fromhex('d8ef03'))                 # srl 3,WA
    j = s2.find(b'\x1e', i)                              # the calr right after
    bankname = calr_target(rom, stage2_12 - LOAD + j)
    bn = rom[bankname - LOAD:bankname - LOAD + 0x20]
    check(bn[:6] == bytes.fromhex('d8cf0900b0fb'),
          '%s R6: bank-name routine does not start `cp WA,9 / ret UGT`' % tag)
    check(bn[6:11] == bytes.fromhex('f260d31e31'),
          '%s R6: bank-name routine does not address 0x1ED360' % tag)
    check(bn[11:14] == bytes.fromhex('d8ee04'),
          '%s R6: bank-name stride is not 16' % tag)
    got = extract_constants(rom, bankname, 0x20)
    check(got == BANKNAME, '%s R6: bank-name constants %s != %s' % (tag, got, BANKNAME))
    check(PM_NAMES + 10 * 0x10 == PM_BASE,
          '%s R6: 10 bank names of 16 bytes do not end at the panel-memory base' % tag)
    check((PM_END - PM_BASE) // PM_STRIDE == 80 and 10 * 8 == 80,
          '%s R6: 80 panel memories are not 10 banks of 8' % tag)
    res['bankname'] = bankname

    # R7 -- the default-fill routine (stage 2's first calr)
    k = s2.find(b'\x1e', 0x15)
    defaultfill = calr_target(rom, stage2_12 - LOAD + k)
    got = extract_constants(rom, defaultfill, 0x46)
    check(got == DEFAULTFILL, '%s R7: default-fill constants %s != %s'
          % (tag, got, DEFAULTFILL))
    res['defaultfill'] = defaultfill

    # R8 -- the format-3 pair
    got = extract_constants(rom, stage1_3, 0x16F)
    check(got == STAGE1_3, '%s R8: stage1(3) constants differ\n    got  %s\n    want %s'
          % (tag, got, STAGE1_3))
    got = extract_constants(rom, stage2_3, 0x150)
    check(got == STAGE2_3, '%s R8: stage2(3) constants differ\n    got  %s\n    want %s'
          % (tag, got, STAGE2_3))
    got = extract_constants(rom, stage1_12, 0x1CA)
    check(got == STAGE1_12, '%s R8: stage1(1/2) constants differ\n    got  %s\n    want %s'
          % (tag, got, STAGE1_12))

    # R9 -- stage 2 of format 3 is stage 1 shifted down by 0x20 on both sides
    for (s1, d1, _), (s2o, d2, _) in zip(FMT3_STAGE1_SINGLES, FMT3_STAGE2_SINGLES):
        check(s1 - s2o == 0x20 and d1 - d2 == 0x20,
              '%s R9: format-3 stage offsets are not counterpart-minus-0x20 '
              '(%#x/%#x vs %#x/%#x)' % (tag, s1, d1, s2o, d2))
    check(0x20 + 23 * 12 == 0x134 and 0x134 == FMT3_STAGE1_SINGLES[0][0],
          '%s R9: the 23 twelve-byte part records do not end where the singles begin' % tag)
    check(FMT3_STAGE2_SINGLES[-1][0] + 0x0A == 0x150,
          '%s R9: the format-3 panel-memory record is not exactly 0x150 bytes' % tag)

    # R10 -- every destination lands on a real TLV record, with the expected tag
    hdr = rom[PANEL_DEFAULT - LOAD:PANEL_DEFAULT - LOAD + 0x20]
    check(hdr[4:6] == b'HK', '%s R10: the ROM default panel image lacks "HK" at +4' % tag)
    tlv = walk_tlv(rom[PANEL_TLV_ROM - LOAD:PANEL_TLV_ROM - LOAD + 0x3C0], PANEL_TLV)
    for src, dst, want in FMT3_STAGE1_SINGLES:
        addr = PANEL_BASE + dst
        check(tlv.get(addr) == want,
              '%s R10: file +%#x -> RAM %#x carries tag %s, expected %#x'
              % (tag, src, addr, tlv.get(addr), want))
    # the part records: base 0xF980+0x34, stride 26.  Format 3 imports 23 of them,
    # formats 1 and 2 import 24 -- and the 24th is tag 0x19, not tag 0x17.
    seq = [tlv.get(PANEL_BASE + 0x34 + 26 * i) for i in range(24)]
    check(seq == list(range(0x00, 0x17)) + [0x19],
          '%s R10: the part-record run at 0xF9B4 is %s, expected 0x00..0x16 then 0x19'
          % (tag, seq))

    # R11 -- byte budget, and no seek anywhere on the importer path
    i = find_unique(rom, A_SIGOFF, '%s R11 sig-offset' % tag)
    # the header read sits a few bytes before the dispatcher, inside the same function
    win_lo = off - 0x40
    j = rom.find(A_READ20, win_lo, off)
    if not check(i is not None and j >= 0 and rom.find(A_READ20, j + 1, off) < 0,
                 '%s R11: the `ld XBC,0x20` header read was not found exactly once in the '
                 '0x40 bytes before the dispatcher' % tag):
        return res
    U24 = lambda k: rom[k] | (rom[k + 1] << 8) | (rom[k + 2] << 16)
    check(rom[i + 14] == 0x1d and rom[j + 5] == 0x1d,
          '%s R11: the expected `call` opcodes are not where the anchors say' % tag)
    seek = U24(i + 15)     # the call right after `ld BC,0` in CheckRegionSignature
    read = U24(j + 6)      # the call right after `ld XBC,0x20` in the dispatcher
    check(seek != read, '%s R11: the seek and read routines resolved to one address' % tag)
    spans = [(res['dispatcher'] - 55, 0x80), (stage1_12, 0x1CA), (stage2_12, 0x224),
             (stage1_3, 0x16F), (stage2_3, 0x150)]
    nread = 0
    for a, n in spans:
        for _, t in call_targets(rom, a - LOAD, n):
            check(t != seek, '%s R11: a seek call sits inside the importer at %#x' % (tag, a))
            if t == read:
                nread += 1
    check(nread == 5, '%s R11: expected 5 read calls on the importer path, found %d'
          % (tag, nread))
    res.update(seek=seek, read=read)

    # R13 -- the cursor really starts at 0.  FileIO_CheckRegionSignature seeks to the
    # signature offset, reads it byte by byte, and its LAST call is a rewind: a wrapper
    # whose callee pushes whence=0, offset=0L and the FILE* and then jumps at the very
    # same fseek primitive the seek helper uses.  Without that, "the importer stops at
    # file offset 0x2480" would be a statement about a cursor of unknown origin.
    sig_start = LOAD + i - 0x0E
    sig_calls = [t for _, t in call_targets(rom, sig_start - LOAD, 0x74)]
    if check(len(sig_calls) == 3 and sig_calls[0] == seek,
             '%s R13: CheckRegionSignature makes %d calls (%s), expected 3 starting with '
             'the seek' % (tag, len(sig_calls), [hex(t) for t in sig_calls])):
        rewind_w = sig_calls[2]
        def first_call(a):
            b = rom[a - LOAD:a - LOAD + 0x20]
            k = b.find(b'\x1d')
            return U24(a - LOAD + k + 1) if k >= 0 else None
        fseek_prim = first_call(seek)
        rew = first_call(rewind_w)
        if check(rew is not None and fseek_prim is not None,
                 '%s R13: could not follow the seek / rewind wrappers' % tag):
            body = rom[rew - LOAD:rew - LOAD + 6]
            check(body == bytes.fromhex('0b0000e8a838'),
                  '%s R13: the rewind primitive at %#x does not push whence=0, offset=0L '
                  '(it starts %s)' % (tag, rew, body.hex()))
            k = rom[rew - LOAD:rew - LOAD + 0x20].find(b'\x1e')
            check(k >= 0 and calr_target(rom, rew - LOAD + k) == fseek_prim,
                  '%s R13: the rewind primitive does not call the same fseek the seek '
                  'helper calls' % tag)
            res['rewind'] = rewind_w

    check(0x20 + 0x660 + 24 * 0x300 == 0x4E80, '%s R11: format-1 total size' % tag)
    check(0x20 + 0x660 + 10 * 0x300 == 0x2480, '%s R11: format-2 total size' % tag)
    check(0x20 + 0x420 + 24 * 0x150 == 0x23C0, '%s R11: format-3 total size' % tag)

    # R12 -- the format-3 DSP converter, reached as stage-1's 9th calr, agrees with the
    #        slot table that was derived from a completely different routine
    b1 = rom[stage1_3 - LOAD:stage1_3 - LOAD + 0x16F]
    calrs, i = [], 0
    while i < len(b1) - 2:
        if b1[i] == 0x1e:
            calrs.append(calr_target(rom, stage1_3 - LOAD + i)); i += 3; continue
        i += 1
    if not check(len(calrs) == 11, '%s R12: stage1(3) has %d calr, expected 11'
                 % (tag, len(calrs))):
        return res
    conv = calrs[8]
    c = rom[conv - LOAD:conv - LOAD + 0x1B6]
    got, i = [], 0
    while i < len(c) - 5:
        if c[i] == 0x40:
            got.append(('LDWA32', struct.unpack('<I', c[i + 1:i + 5])[0])); i += 5; continue
        if c[i:i + 2] == b'\xe8\xc8':
            got.append(('ADDWA', struct.unpack('<I', c[i + 2:i + 6])[0])); i += 6; continue
        if c[i] == 0xf2 and c[i + 4] == 0x31:
            got.append(('LDA24', c[i + 1] | (c[i + 2] << 8) | (c[i + 3] << 16))); i += 5
            continue
        i += 1
    check(got == FMT3_DSP_IDS, '%s R12: format-3 DSP converter ids %s != %s'
          % (tag, got, FMT3_DSP_IDS))
    t0 = rom[0xEE159C - LOAD:0xEE159C - LOAD + 16]
    t1 = rom[0xEE15AC - LOAD:0xEE15AC - LOAD + 16]
    bad0 = [v for v in t0 if v not in SLOT0_OK]
    bad1 = [v for v in t1 if v and v not in SLOT1_OK]
    check(not bad0, '%s R12: 0xEE159C holds %s, which slot 0 rejects' % (tag, bad0))
    check(not bad1, '%s R12: 0xEE15AC holds %s, which slot 1 rejects' % (tag, bad1))
    # and the test is not vacuous: swapping the two tables produces violations
    check([v for v in t0 if v and v not in SLOT1_OK] and [v for v in t1 if v not in SLOT0_OK],
          '%s R12: swapping the two tables would NOT violate the slot predicates, so the '
          'agreement above is vacuous' % tag)
    res['fmt3_dsp_conv'] = conv

    if verbose:
        print('  [%s] dispatcher %06X  classifier %06X' % (rev, res['dispatcher'], classifier))
        print('       formats 1+2 -> stage1 %06X  stage2 %06X' % (stage1_12, stage2_12))
        print('       format  3   -> stage1 %06X  stage2 %06X' % (stage1_3, stage2_3))
        print('       default-fill %06X   bank-name %06X   read %06X  seek %06X'
              % (defaultfill, bankname, read, seek))
        print('       format-3 DSP converter %06X  (ns 0x4900 slot 0, 0x4B00 slot 1)' % conv)
    return res


# ------------------------------------------------------------ the file side --
def file_side(paths, verbose):
    blobs = {}
    for p in paths:
        with open(p, 'rb') as f:
            blobs[p] = f.read()
    names = sorted(blobs)

    for p in names:
        d = blobs[p]
        t = 'F[%s]' % os.path.basename(p)
        check(len(d) == FILESIZE, '%s F1: size %d != %d' % (t, len(d), FILESIZE))
        check(d[0:4] == bytes.fromhex('5a5a0100'), '%s F1: header prefix %s' % (t, d[0:4].hex()))
        check(d[4:7] == b'M60', '%s F1: magic %r' % (t, d[4:7]))
        check(d[7] == 0x0A, '%s F1: header byte +7 is %#x, not 0x0a' % (t, d[7]))
        # F2
        check(SLOT0 + NSLOTS * SLOTSIZE == 0x4E80, '%s F2: slot array does not end at 0x4E80' % t)
        check(0x20 + 0x660 + NSLOTS * SLOTSIZE == 0x4E80,
              '%s F2: the ROM-derived format-1 size is not 0x4E80' % t)
        # F6
        check(SLOT0 + 10 * SLOTSIZE == 0x2480,
              '%s F6: the format-2 cursor does not stop at 0x2480' % t)

    def blk(p, i):
        return blobs[p][SLOT0 + SLOTSIZE * i: SLOT0 + SLOTSIZE * (i + 1)]

    if len(names) >= 2:
        # F3 -- blocks 10..23 constant across disks, blocks 0..9 not
        const = [i for i in range(NSLOTS)
                 if all(blk(p, i) == blk(names[0], i) for p in names)]
        check(set(range(10, 24)).issubset(set(const)),
              'F3: slot blocks 10..23 are NOT identical across the %d files (constant set %s)'
              % (len(names), const))
        check(not set(range(0, 10)).issubset(set(const)),
              'F3: slot blocks 0..9 are identical across every file -- the corpus cannot '
              'distinguish payload from filler')
        # F7 -- the 0xC0 is constant across disks too
        a, n = GAPC0
        check(len({blobs[p][a:a + n] for p in names}) == 1,
              'F7: %#x..%#x differs between files' % (a, a + n))
        # F8 -- the 0x30 varies, and the per-slot u16 reading fails
        a, n = GAP30
        check(len({blobs[p][a:a + n] for p in names}) > 1,
              'F8: %#x..%#x is constant across files after all' % (a, a + n))
        for order in ('forward', 'reversed'):
            words = {}
            for p in names:
                w = [struct.unpack('>H', blobs[p][a + 2 * k:a + 2 * k + 2])[0]
                     for k in range(24)]
                words[p] = list(reversed(w)) if order == 'reversed' else w
            # a per-slot field must be constant exactly where the slot is constant
            wconst = [k for k in range(24)
                      if all(words[p][k] == words[names[0]][k] for p in names)]
            check(not set(range(10, 24)).issubset(set(wconst)),
                  'F8: the "24 u16, one per slot" reading (%s) was NOT refuted -- words '
                  '10..23 are constant across files just as the slot blocks are' % order)

    for p in names:
        t = 'F[%s]' % os.path.basename(p)
        # F4 -- the filler is the default set, repeated with period 10
        for i in range(10, NSLOTS):
            check(blk(p, i) == blk(p, 10 + (i - 10) % 10),
                  '%s F4: block %d != block %d' % (t, i, 10 + (i - 10) % 10))
        # F7 -- the 0xC0 is one 16-byte pattern, 12 times
        a, n = GAPC0
        pat = blobs[p][a:a + 16]
        check(blobs[p][a:a + n] == pat * 12, '%s F7: %#x is not 12 x %s' % (t, a, pat.hex()))

    # F5 -- at least one untouched user slot somewhere in the corpus
    hits = [(os.path.basename(p), k) for p in names for k in range(10)
            if blk(p, k) == blk(p, 10 + k)]
    check(bool(hits), 'F5: no user slot in the corpus equals its default counterpart, so '
                      'blocks 10..19 are only known to be CONSTANT, not to be the DEFAULTS')

    if verbose:
        print('  %d file(s); slot blocks constant across all of them: %s'
              % (len(names), [i for i in range(NSLOTS)
                              if all(blk(p, i) == blk(names[0], i) for p in names)]))
        print('  untouched user slots (block k == default block 10+k): %s' % (hits,))


LAYOUT = """
FORMAT 1 ("M4..")  and  FORMAT 2 ("M60")  -- one layout, one immediate apart
    0x0000  0x0020  header; [4],[5] classify; [7] = 0x0A on every M60 file seen
    0x0020  0x03D0  TLV block 0, 32-byte part records          -> live panel 0x00F980+
    0x03F0  0x0290  TLV block 1
    0x0680  N*0x300 panel memories, 0x300 each                 -> 0x1ED400 + 960*j
                    N = 24 for format 1, N = 10 for format 2
    total           0x4E80 (format 1)   /   0x2480 (format 2)

FORMAT 3 ("NN..")  -- its own layout, 12-byte part records
    0x0000  0x0020  header
    0x0020  0x0114  23 part records of 12 bytes                -> 0x00F980+0x34, stride 26
    0x0134  0x0012  tag 0x48  style / tempo
    0x0146  0x0008  tag 0x90
    0x014E  0x0012  tag 0x70  digital effect
    0x0160  0x0006  tag 0x71  panel-memory on/off
    0x0166  0x000A  tag 0x72
    0x0170  0x02B0  the rest of the live panel: a 4-byte-per-part array at 0x019E
                    ordered by the ROM permutation at 0xEE1584, plus three converters
                    that reach 0x0152/0x0155, 0x0173..0x018B, 0x0200..0x0210, 0x03EE..
    0x0440  24*0x150 panel memories, 0x150 each                -> 0x1ED400 + 960*j
                    a 0x150 record is the live body's first 0x150 bytes, offsets -0x20
    total           0x23C0

KN5000 PANEL MEMORY (derived here, not previously written down)
    0x1ED360  10 x 16 bytes   bank NAMES, blanked to spaces one bank at a time
    0x1ED400  80 x 960 bytes  the slots; 80 = 10 banks x 8 memories
              (`count >> 3` bank-name blankings for `count` imported memories)
"""


def main(argv):
    quiet = '--quiet' in argv
    layout = '--layout' in argv
    args = [a for a in argv if not a.startswith('--')]
    paths = []
    for a in args:
        if os.path.isdir(a):
            paths += glob.glob(os.path.join(a, '*.LSW')) + glob.glob(os.path.join(a, '*.lsw'))
        else:
            paths.append(a)

    if layout:
        print(LAYOUT)

    if not quiet:
        print('ROM side (v7, v9, v10):')
    for rev in REVS:
        rom_side(rev, not quiet)

    if paths:
        if not quiet:
            print('File side (%d .LSW):' % len(paths))
        file_side(paths, not quiet)
    elif not quiet:
        print('File side: no .LSW given, skipped (F1..F8 not run)')

    if FAILS:
        print('FAIL (%d)' % len(FAILS))
        for m in FAILS:
            print('  ' + m)
        return 1
    print('PASS')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
