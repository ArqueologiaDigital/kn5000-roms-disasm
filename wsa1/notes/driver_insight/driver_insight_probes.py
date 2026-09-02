#!/usr/bin/env python3
"""Probes behind notes/DRIVER-INSIGHT-wsa1-2026-09-02.md.

WHAT QUESTION EACH SECTION ANSWERS, and the exact command:

  python3 wsa1/notes/driver_insight/driver_insight_probes.py --hdd
      "Does the ROM itself say what the unit-1 back end at 0x7E0008 is?"
      Decodes the FAT16 BPB at prom_a 0xFE69BF and the MBR partition entry at
      0xFE6DBF straight out of the EPROM image, and checks that the geometry
      they state is the same geometry the ATA INITIALIZE DEVICE PARAMETERS
      operands and the 0xFE31xx compares use.

  python3 wsa1/notes/driver_insight/driver_insight_probes.py --dev7f
      "How much of the traffic to the 4 x 32 register files at 0x7F0000
      (CPU 1) and 0x00E00000 (CPU 2) is reachable?"
      Counts the `ld <Xrr>,imm32` sites that name each base, and counts
      `call`/`jp` (abs24) and `calr` (disp16) references to the entry points
      that drive them.

  python3 wsa1/notes/driver_insight/driver_insight_probes.py --dev104
      "What constants does the firmware put into the 0x00104000 register
      file, and does the unrolled writer really span 19 blocks?"
      Dumps the three ROM images Dev10C_ResetAllChannels and
      Dev104_LoadStageBImage hand out, and re-derives the block list of
      Dev104_WriteAllChanRegs from the prom_c bytes.

  python3 wsa1/notes/driver_insight/driver_insight_probes.py --selftest
      Runs every assertion in all three sections and exits non-zero on the
      first failure.  Includes negative controls.

Reads ONLY wsa1/original_ROMs/*, never the .s listings.  Run from the
repository root (the directory that holds wsa1/).
"""
import struct
import sys
import os

ROM = os.path.join(os.path.dirname(__file__), '..', '..', 'original_ROMs')

BASES = {
    'a': ('wsa1_prom_a.ic12', 0xF80000),
    'b': ('wsa1_prom_b.ic13', 0xF00000),
    'c': ('wsa1_prom_c.ic28', 0xF80000),
}

_cache = {}


def image(k):
    if k not in _cache:
        fn, base = BASES[k]
        _cache[k] = (open(os.path.join(ROM, fn), 'rb').read(), base)
    return _cache[k]


def rd(k, addr, n):
    data, base = image(k)
    off = addr - base
    assert 0 <= off and off + n <= len(data), 'address 0x%06X outside %s' % (addr, k)
    return data[off:off + n]


def u16(b, o=0):
    return struct.unpack_from('<H', b, o)[0]


def u32(b, o=0):
    return struct.unpack_from('<I', b, o)[0]


FAIL = []


def check(name, got, want):
    ok = got == want
    print('  %-58s %-22s %s' % (name, repr(got), 'OK' if ok else 'FAIL want ' + repr(want)))
    if not ok:
        FAIL.append(name)


# ---------------------------------------------------------------- --hdd

BPB_ADDR = 0xFE69BF          # DiskImage_HardDisk_BootSector
MBR_ADDR = 0xFE6DBF          # the master boot record that follows it


def sec_hdd(selftest=False):
    print('\n=== 0x7E0008: what the ROM says the second block-device unit is ===')
    bpb = rd('a', BPB_ADDR, 0x200)
    print('  prom_a 0x%06X, 512 bytes' % BPB_ADDR)
    fields = [
        ('x86 jump', bpb[0:3].hex()),
        ('OEM name', bpb[3:11].decode('latin-1')),
        ('bytes per sector', u16(bpb, 0x0B)),
        ('sectors per cluster', bpb[0x0D]),
        ('reserved sectors', u16(bpb, 0x0E)),
        ('number of FATs', bpb[0x10]),
        ('root dir entries', u16(bpb, 0x11)),
        ('total sectors (16-bit)', u16(bpb, 0x13)),
        ('media descriptor', hex(bpb[0x15])),
        ('sectors per FAT', u16(bpb, 0x16)),
        ('sectors per track', u16(bpb, 0x18)),
        ('heads', u16(bpb, 0x1A)),
        ('hidden sectors', u32(bpb, 0x1C)),
        ('total sectors (32-bit)', u32(bpb, 0x20)),
        ('BIOS drive number', hex(bpb[0x24])),
        ('filesystem type', bpb[0x36:0x3E].decode('latin-1')),
        ('boot signature', bpb[0x1FE:0x200].hex()),
    ]
    for n, v in fields:
        print('    %-24s %s' % (n, v))

    spt = u16(bpb, 0x18)
    heads = u16(bpb, 0x1A)
    tot = u32(bpb, 0x20)
    hidden = u32(bpb, 0x1C)
    cyl = (tot + hidden) // (spt * heads)
    print('    (%d + %d) / (%d * %d) = %d cylinders, remainder %d'
          % (tot, hidden, spt, heads, cyl, (tot + hidden) % (spt * heads)))
    print('    capacity %d bytes = %.1f MB' % (tot * 512, tot * 512 / 1e6))

    data, base = image('a')
    for s in (b'This is Technics HDD.', b'Non-System disk or disk error'):
        i = data.find(s)
        print('    %-32s at prom_a 0x%06X' % (s.decode(), i + base))

    # The three operands the ATA path itself uses, read as bytes at the
    # instruction addresses prom_a_census_round8.py --ata reports.
    print('  the same geometry, from the ATA path rather than from the image:')
    ata = [
        ('INITIALIZE DEVICE PARAMETERS sector count, pushed at 0xFE5144',
         0xFE5144, u16(rd('a', 0xFE5144 + 1, 2))),
        ('INITIALIZE DEVICE PARAMETERS device/head, pushed at 0xFE5177',
         0xFE5177, u16(rd('a', 0xFE5177 + 1, 2))),
        ('cylinders compared at 0xFE31AA', 0xFE31AA, u16(rd('a', 0xFE31AA + 5, 2))),
        ('heads compared at 0xFE31B3', 0xFE31B3, u16(rd('a', 0xFE31B3 + 5, 2))),
        ('sectors compared at 0xFE31BC', 0xFE31BC, u16(rd('a', 0xFE31BC + 5, 2))),
    ]
    for n, addr, v in ata:
        print('    %-56s 0x%04X (%d)' % (n, v, v))

    if selftest:
        print('  checks:')
        check('BPB media descriptor is 0xF8 (fixed disk)', bpb[0x15], 0xF8)
        check('BPB BIOS drive number is 0x80 (first hard disk)', bpb[0x24], 0x80)
        check('BPB filesystem type', bpb[0x36:0x3E], b'FAT16   ')
        check('BPB sectors per track', spt, 60)
        check('BPB heads', heads, 15)
        check('BPB total+hidden is a whole number of cylinders',
              (tot + hidden) % (spt * heads), 0)
        check('cylinder count', cyl, 568)
        check('boot signature', bpb[0x1FE:0x200], b'\x55\xaa')
        check('ATA INIT DEV PARAMS sector count == BPB sectors per track',
              u16(rd('a', 0xFE5144 + 1, 2)), spt)
        check('ATA INIT DEV PARAMS device/head == BPB heads - 1',
              u16(rd('a', 0xFE5177 + 1, 2)), heads - 1)
        check('geometry compare at 0xFE31B3 == BPB heads', u16(rd('a', 0xFE31B3 + 5, 2)), heads)
        check('geometry compare at 0xFE31BC == BPB sectors per track',
              u16(rd('a', 0xFE31BC + 5, 2)), spt)
        check('geometry compare at 0xFE31AA is 0x0239 = 569',
              u16(rd('a', 0xFE31AA + 5, 2)), 0x0239)
        check('"This is Technics HDD." is present in prom_a',
              image('a')[0].find(b'This is Technics HDD.') >= 0, True)
        # NEGATIVE CONTROL: the same string must not be in the other images.
        check('NULL: "This is Technics HDD." absent from prom_b',
              image('b')[0].find(b'This is Technics HDD.'), -1)
        check('NULL: "This is Technics HDD." absent from prom_c',
              image('c')[0].find(b'This is Technics HDD.'), -1)


# --------------------------------------------------------------- --dev7f

def imm32_sites(k, value):
    """Every `ld <Xrr>,imm32` (opcodes 0x40..0x47) whose immediate is `value`."""
    data, base = image(k)
    want = struct.pack('<I', value)
    out = []
    for i in range(len(data) - 5):
        if 0x40 <= data[i] <= 0x47 and data[i + 1:i + 5] == want:
            out.append(base + i)
    return out


def abs_call_sites(images, target):
    """`call abs24` (0x1D) and `jp abs24` (0x1B) sites naming `target`."""
    want = struct.pack('<I', target)[:3]
    out = []
    for k in images:
        data, base = image(k)
        for i in range(len(data) - 4):
            if data[i] in (0x1B, 0x1D) and data[i + 1:i + 4] == want:
                out.append((k, base + i, 'jp' if data[i] == 0x1B else 'call'))
    return out


def calr_sites(k, target):
    """`calr disp16` (0x1E) sites whose resolved target is `target`."""
    data, base = image(k)
    out = []
    for i in range(len(data) - 3):
        if data[i] == 0x1E:
            disp = struct.unpack_from('<h', data, i + 1)[0]
            if base + i + 3 + disp == target:
                out.append(base + i)
    return out


DEV7F_ROUTINES = [
    # (image, entry, label, how it is published)
    ('a', 0xF83171, 'Dev7F_WriteSlot8_Slot0', 'prom_b thunk 0xF40004'),
    ('a', 0xF83179, 'Dev7F_WriteSlot8_Slot1', 'prom_b thunk 0xF40008'),
    ('a', 0xF83181, 'Dev7F_WriteSlot8_Slot2', 'prom_b thunk 0xF4000C'),
    ('a', 0xF83189, 'Dev7F_WriteSlot8_Slot3', 'prom_b thunk 0xF40010'),
    ('a', 0xF831B3, 'sub_F831B3 (writes all four slots at boot)', 'direct'),
    ('a', 0xF85F0F, 'DSP_ChannelRegs_Init', 'direct'),
    ('a', 0xF85F59, 'DSP_ChannelRegs_Write8', 'prom_b thunk 0xF42DE0'),
    ('a', 0xF85F7C, 'DSP_WriteAllChannelRegs', 'prom_b thunk 0xF42DE4'),
    ('a', 0xFA6068, 'sub_FA6068 (calls all four slots)', 'direct'),
    ('a', 0xFA6112, 'sub_FA6112 (byte-identical twin)', 'direct'),
    ('a', 0xFADF0D, 'Dev7F_WriteAllFourSlots', 'direct'),
]

DEV7F_THUNKS = [
    (0xF40004, 'T_Dev7F_WriteSlot8_Slot0'),
    (0xF40008, 'T_Dev7F_WriteSlot8_Slot1'),
    (0xF4000C, 'T_Dev7F_WriteSlot8_Slot2'),
    (0xF40010, 'T_Dev7F_WriteSlot8_Slot3'),
    (0xF42DE0, 'T_DSP_ChannelRegs_Write8'),
    (0xF42DE4, 'T_DSP_WriteAllChannelRegs'),
]

# The thirteen 4-byte `calr Dev7F_WriteAllFourSlots / ret` stubs of the
# 0xFAD800 module, from that module's own header in prom_a/wsa1_prom_a.s.
DEV7F_STUBS = [0xFAD801, 0xFAD806, 0xFAD819, 0xFAD846, 0xFAD86C, 0xFAD886,
               0xFAD89D, 0xFAD8B8, 0xFAD8D9, 0xFAD8FA, 0xFAD98B, 0xFAD9AC,
               0xFAD9C7]


def sec_dev7f(selftest=False):
    print('\n=== 0x7F0000 (CPU 1) and 0x00E00000 (CPU 2): who reaches them ===')
    for k, val, name in (('a', 0x007F0000, 'prom_a  0x007F0000'),
                         ('b', 0x007F0000, 'prom_b  0x007F0000'),
                         ('c', 0x00E00000, 'prom_c  0x00E00000'),
                         ('a', 0x00E00000, 'prom_a  0x00E00000 (null)'),
                         ('c', 0x007F0000, 'prom_c  0x007F0000 (null)')):
        s = imm32_sites(k, val)
        print('  %-30s %d `ld <Xrr>,imm32` site(s)  %s'
              % (name, len(s), ' '.join('0x%06X' % x for x in s)))

    print('\n  reachability of the CPU 1 drivers (abs call/jp + calr, prom_a + prom_b):')
    for k, entry, label, pub in DEV7F_ROUTINES:
        abs_s = abs_call_sites(['a', 'b'], entry)
        rel_s = calr_sites('a', entry)
        print('    0x%06X %-44s abs %d  calr %d   (%s)'
              % (entry, label, len(abs_s), len(rel_s), pub))
        for kk, addr, kind in abs_s:
            print('        %s %s 0x%06X' % (kk, kind, addr))
        for addr in rel_s:
            print('        a calr 0x%06X' % addr)

    print('\n  reachability of the prom_b thunk slots that publish them:')
    for slot, label in DEV7F_THUNKS:
        s = abs_call_sites(['a', 'b'], slot)
        print('    0x%06X %-34s %d site(s)  %s'
              % (slot, label, len(s), ' '.join('%s:0x%06X' % (k, x) for k, x, _ in s)))

    print('\n  reachability of the thirteen `calr Dev7F_WriteAllFourSlots / ret` stubs:')
    tot = 0
    for st in DEV7F_STUBS:
        n = len(abs_call_sites(['a', 'b'], st)) + len(calr_sites('a', st))
        tot += n
        print('    0x%06X  %d reference(s)' % (st, n))
    print('    total references to all thirteen stubs: %d' % tot)

    if selftest:
        print('  checks:')
        check('prom_a names 0x007F0000 at 5 sites', len(imm32_sites('a', 0x007F0000)), 5)
        check('prom_b names 0x007F0000 nowhere', len(imm32_sites('b', 0x007F0000)), 0)
        check('prom_c names 0x00E00000 at 3 sites', len(imm32_sites('c', 0x00E00000)), 3)
        check('NULL: prom_a never names 0x00E00000', len(imm32_sites('a', 0x00E00000)), 0)
        check('NULL: prom_c never names 0x007F0000', len(imm32_sites('c', 0x007F0000)), 0)
        check('T_DSP_WriteAllChannelRegs (0xF42DE4) has no caller',
              len(abs_call_sites(['a', 'b'], 0xF42DE4)), 0)
        check('T_DSP_ChannelRegs_Write8 (0xF42DE0) has exactly one caller',
              [x[1] for x in abs_call_sites(['a', 'b'], 0xF42DE0)], [0xF8287B])
        check('DSP_ChannelRegs_Init (0xF85F0F) has no caller at all',
              len(abs_call_sites(['a', 'b'], 0xF85F0F)) + len(calr_sites('a', 0xF85F0F)), 0)
        check('sub_FA6068 has no caller',
              len(abs_call_sites(['a', 'b'], 0xFA6068)) + len(calr_sites('a', 0xFA6068)), 0)
        check('sub_FA6112 has no caller',
              len(abs_call_sites(['a', 'b'], 0xFA6112)) + len(calr_sites('a', 0xFA6112)), 0)
        check('the thirteen 0xFAD800 stubs have no reference between them',
              sum(len(abs_call_sites(['a', 'b'], s)) + len(calr_sites('a', s))
                  for s in DEV7F_STUBS), 0)
        check('sub_F831B3 is called exactly once, from the boot block',
              [x[1] for x in abs_call_sites(['a', 'b'], 0xF831B3)], [0xF825E1])
        # POSITIVE CONTROL: a routine that is certainly reached must score > 0,
        # or the xref scanner proves nothing by returning zero.
        check('POSITIVE CONTROL: Fdc_Request (0xFE66C7) has 8 abs callers',
              len(abs_call_sites(['a', 'b'], 0xFE66C7)), 8)


# -------------------------------------------------------------- --dev104

# Dev104_WriteAllChanRegs, prom_c 0xFB77EF-0xFB796D.
DEV104_WRITER = (0xFB77EF, 0x17F)
DEV104_RESET_WORD = 0xFE1313      # register 0x0800 at power-on
DEV104_STAGEB_IMAGE = 0xFE1315    # the 19-word constant image VoiceRegs_Stage_B loads
DEV10C_GLOBAL_IMAGE = 0xFE12B5    # the 13 global registers of 0x0010C000
DEV10C_STAGING_IMAGE = 0xFE12CF   # 68 bytes, the per-channel staging reset image


def dev104_blocks():
    """Re-derive the block list of Dev104_WriteAllChanRegs from the bytes.

    The routine forms every register number as `add bc,imm16` on the channel
    (opcode d9 c8 lo hi) except block 0, which is the bare channel in HL.
    """
    body = rd('c', *DEV104_WRITER)
    out = []
    i = 0
    while i < len(body) - 3:
        if body[i] == 0xD9 and body[i + 1] == 0xC8:
            out.append(u16(body, i + 2))
            i += 4
        elif body[i] == 0xDA and body[i + 1] == 0xC8:      # add de,imm16
            out.append(u16(body, i + 2))
            i += 4
        else:
            i += 1
    return out


def sec_dev104(selftest=False):
    print('\n=== 0x00104000: the register file, and the constants the ROM holds ===')
    blocks = dev104_blocks()
    print('  Dev104_WriteAllChanRegs block offsets, re-derived from prom_c bytes:')
    print('    ' + ' '.join('0x%04X' % b for b in blocks))
    print('    %d `add <rr>,imm16` blocks + block 0 written last = %d registers'
          % (len(blocks), len(blocks) + 1))
    print('    staging word for block k*0x40 is 2*k:')
    for n, b in enumerate([0] + blocks):
        print('      block 0x%04X  k=%2d  staging offset 0x%02X'
              % (b, b // 0x40, 2 * (b // 0x40)))

    w = u16(rd('c', DEV104_RESET_WORD, 2))
    print('\n  power-on: 0x00104000 register 0x0800 := 0x%04X   (ROM 0x%06X)'
          % (w, DEV104_RESET_WORD))

    img = struct.unpack('<19H', rd('c', DEV104_STAGEB_IMAGE, 38))
    print('  the 19-word constant image at ROM 0x%06X that VoiceRegs_Stage_B loads' % DEV104_STAGEB_IMAGE)
    print('  into the 0x00104000 staging struct (part mode 0x40 runs the device from a constant):')
    for k, v in enumerate(img):
        print('      block 0x%04X (word 0x%02X) = 0x%04X' % (k * 0x40, 2 * k, v))

    g = struct.unpack('<13H', rd('c', DEV10C_GLOBAL_IMAGE, 26))
    names = ['0x0200', '0x0201', '0x0202', '0x0203', '0x0204', '0x0205',
             '0x0C00', '0x0C01', '0x0C02', '0x0C03', '0x0C04', '0x0C05', '0x0E00']
    print('\n  for contrast, the 0x0010C000 GLOBAL register reset image, ROM 0x%06X:' % DEV10C_GLOBAL_IMAGE)
    for n, v in zip(names, g):
        print('      register %s = 0x%04X' % (n, v))

    s = struct.unpack('<34H', rd('c', DEV10C_STAGING_IMAGE, 68))
    print('\n  the 68-byte per-channel staging reset image, ROM 0x%06X:' % DEV10C_STAGING_IMAGE)
    print('    ' + ' '.join('%04X' % x for x in s))

    if selftest:
        print('  checks:')
        check('Dev104_WriteAllChanRegs writes 18 add-formed blocks', len(blocks), 18)
        check('they are 0x40..0x480 in 0x40 steps',
              blocks, list(range(0x40, 0x4C0, 0x40)))
        check('with block 0 that is 19 registers', len(blocks) + 1, 19)
        check('19 blocks x 64 channels + the single 0x0800 = 1217 registers',
              19 * 64 + 1, 1217)
        check('the Stage_B image is 19 words', len(img), 19)
        check('the global image is 13 words', len(g), 13)
        check('68 bytes is the exact gap 0xFE12CF..0xFE1313',
              DEV104_RESET_WORD - DEV10C_STAGING_IMAGE, 68)
        # NEGATIVE CONTROL: the same scan over a routine that is NOT this one
        # must not produce the same ladder.
        other = rd('c', 0xFB7715, 0xDA)      # Dev10C_WriteGlobalRegs
        n = sum(1 for i in range(len(other) - 3)
                if other[i] == 0xD9 and other[i + 1] == 0xC8)
        check('NULL: Dev10C_WriteGlobalRegs forms no register number by adding',
              n, 0)


def main():
    args = sys.argv[1:]
    if not args:
        args = ['--hdd', '--dev7f', '--dev104']
    st = '--selftest' in args
    if st:
        args = ['--hdd', '--dev7f', '--dev104']
    if '--hdd' in args:
        sec_hdd(st)
    if '--dev7f' in args:
        sec_dev7f(st)
    if '--dev104' in args:
        sec_dev104(st)
    if st:
        print('\nFAILURES: %d' % len(FAIL))
        for f in FAIL:
            print('  ' + f)
        sys.exit(1 if FAIL else 0)


if __name__ == '__main__':
    main()
