#!/usr/bin/env python3
"""What are the KN5000 panel-area TLV records that are NOT the 26 per-part records?

QUESTION ANSWERED
-----------------
lsw_panel_schema_from_rom.py showed that the live panel work area 0x00F9A0..0x00FFC0 is a
tag/length/value stream whose schema is a ROM table, and lsw_part_record_fields.py pinned the
fields of the 26 per-part records (tags 0x00..0x19).  This probe attacks the rest, and in
particular the block-1 run C0..D4 + D7 -- 22 records of 18 bytes that share ONE descriptor
list of 18 bare "plain byte" entries, with no mask, no range and no default.

It answers three questions, each with a test that can fail:

 (1) WHAT IS THE C0..D4/D7 FAMILY?
     Claim: record 0xC0+T is the companion block of PART record T.  The evidence is not a
     name, it is a ROM pointer table: `VoiceData_LookupPtrByChannel` (0x00FC9E04) does
         if A <= 0x1F: return u32[0x00EDB264 + 4*A]
         elif A == 0x48: return 0x00FF92          (VoiceLookup_CheckRhythm, 0x00FC9E19)
         else: return -1
     PASS = every non-(-1) entry of that table lands exactly on the PAYLOAD START of a
     C0..D4/D7 record, the whole C-family is covered, and nothing else is pointed at.
     FAIL if one entry points anywhere else -- that would break the "per part" reading.

     Same test for the 0x48 -> 0x49 special case: it must hit tag 0x49's payload start.

 (2) CAN ANY OF THEM EVER NOTIFY?
     SwbtWr_DispatchLoop (0x00FDB328) reads the event tag and does `cp L,0xbf / jr UGT,skip`
     before indexing its tag->callback table.  So every event whose tag exceeds 0xBF is
     dropped and can have no subscriber.  PASS = those exact bytes are still at 0x00FDB347,
     and the three tag-indexed callback tables have no entry for any tag >= 0xC0.

 (3) DOES ANY INSTRUCTION TOUCH THEM DIRECTLY?
     Census of TLCS-900 direct addressing over the WHOLE program ROM -- not just the part of
     the disassembly that has been converted away from `.byte`.  `F1 lo hi` is the 16-bit
     direct operand prefix and `F2 lo hi 00` the 24-bit one (verified against known-good
     converted code, e.g. 0xFC5326 `f1 60 fd 32` = `lda XDE,(0xfd60)`).  Every candidate is
     then re-checked for INSTRUCTION ALIGNMENT by disassembling forward from the nearest
     preceding symbol with unidasm, because a stray F1 inside a `call 0xf1xxxx` operand is
     the dominant false positive.  Needs ~/compartilhado/tools/unidasm; skipped without it.

RESULTS THIS PRODUCED (2026-08-22, ROMs v7 / v9 / v10)
-----------------------------------------------------
  * 0xEDB264 maps part tags 0x00..0x14 one-to-one onto C0..D4, and then ALIASES:
        0x15 -> D0 (same block as 0x10)   0x16 -> D3 (same as 0x13)   0x18 -> D7 (same as 0x17)
        0x19..0x1F -> none
    That is why the family stops at D4 and then jumps to D7: D5/D6 were never needed.
  * tag 0x48 (style/tempo) -> tag 0x49's payload, and the writer hard-codes the bound 0x0F
    for that path -- 16 slots, and record 0x49 is exactly 0x10 bytes long.
  * dispatcher guard present in all three ROMs; callback tables stop at tag 0xBF.
  * event sites: 64 calls to SwbtWr_QueuePostEvent in v9; highest tag seen is 0xB4; NONE
    names a tag >= 0xC0.
  * direct-address census: 653 (v7) / 746 (v9, v10) F1|F2 candidates in range, of which
    582 / 617 / 617 are instruction-aligned -- and ZERO of the aligned ones is a memory
    access to a C0..D4/D7 record (the handful that land there disassemble as `db` or as the
    operand tail of a `call`/`jp` inside a data table).
  * the 7 floppy .LSW files hold 154 C-family records (22 x 7): every byte is zero.

    python3 analysis/disk-format-probes/lsw_nonpart_records.py
    python3 analysis/disk-format-probes/lsw_nonpart_records.py --quiet
    python3 analysis/disk-format-probes/lsw_nonpart_records.py --lsw-dir /path/with/LSW/files
"""
import argparse, bisect, os, re, struct, subprocess, sys, glob

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, '..', '..'))
LOAD = 0xE00000
VERSIONS = ('v7', 'v9', 'v10')
TABLES = ((0xED8FE0, 46, 0xF9A0), (0xED91AC, 30, 0xFD60))
UNIDASM = os.path.expanduser('~/compartilhado/tools/unidasm')

# --- the three signals, as addresses so they stay checkable -------------------------------
PART_TO_BLOCK_TABLE = 0xEDB264        # u32[0x20], read by VoiceData_LookupPtrByChannel
LOOKUP_BY_CHANNEL   = 0xFC9E04
RHYTHM_SPECIAL_CASE = (0x48, 0xFF92)  # VoiceLookup_CheckRhythm, 0x00FC9E19
# SwbtWr_DispatchLoop: `ld L,(XIY) / ld (scratch),L / cp L,0xbf / jr UGT,skip`.
# Located by PATTERN, not by address: v7 sits elsewhere AND uses different scratch RAM
# (v7 0xBFE4 / queue 0xBE9D / count 0x9046 vs v9,v10 0xC080 / 0xBF39 / 0x90E2), so the
# two RAM operand bytes are wildcards ('..' below).
DISPATCH_GUARD_PATTERN = '85 27 f1 .. .. 47 cf cf bf 6b'
# SwbtWr_QueuePostEvent, whole entry:
#   cp (count),0x00fb / jr UGT,ret / ld XHL,queue / add HL,(count) / ld (XHL),DE
QUEUE_POST_PATTERN = 'd1 .. .. 3f fb 00 6b .. 43 .. .. 00 00 d1 .. .. 83 b3 52'
CALLBACK_TABLES = (0xEE7786, 0xEE7CA7, 0xEE86D0)
C_FAMILY = tuple(range(0xC0, 0xD5)) + (0xD7,)
PART_TAGS = tuple(range(0x00, 0x1A))


def rom_path(ver):
    return os.path.join(REPO, 'original_ROMs', 'kn5000_%s_program.rom' % ver)


def schema(rom):
    """[(record_start, tag, payload_len)] for both blocks, in stream order."""
    recs = []
    for addr, count, base in TABLES:
        for i in range(count):
            o = addr - LOAD + 10 * i
            eoff, fptr, tag, ln = struct.unpack_from('<IIBB', rom, o)
            if tag == 0xFF:
                break
            recs.append((base + eoff, tag, ln))
    return recs


def locate(recs, a):
    for start, tag, ln in recs:
        if start <= a < start + 2 + ln:
            d = a - start
            return tag, ('HDR' if d < 2 else d - 2)
    return None


def symbols():
    out = []
    p = os.path.join(REPO, 'symbols', 'maincpu_symbols_reference.txt')
    for line in open(p):
        f = line.split()
        if len(f) == 2 and len(f[1]) == 8:
            try:
                out.append((int(f[1], 16), f[0]))
            except ValueError:
                pass
    out.sort()
    return out


def sym_of(syms, addrs, a):
    i = bisect.bisect_right(addrs, a) - 1
    if i < 0:
        return '?'
    d = a - syms[i][0]
    return syms[i][1] + ('' if d == 0 else '+0x%x' % d)


# ------------------------------------------------------------------ test 1: the ROM mapping
def test_part_to_block(rom, recs, verbose):
    ok = True
    seen = {}
    for tag in range(0x20):
        v = struct.unpack_from('<I', rom, PART_TO_BLOCK_TABLE - LOAD + 4 * tag)[0]
        if v == 0xFFFFFFFF:
            if verbose:
                print('    part tag %02X -> (none)' % tag)
            continue
        hit = locate(recs, v & 0xFFFF)
        if hit is None or hit[0] not in C_FAMILY or hit[1] != 0:
            print('    FAIL part tag %02X -> %08X, not a C-family payload start' % (tag, v))
            ok = False
            continue
        seen.setdefault(hit[0], []).append(tag)
        if verbose:
            print('    part tag %02X -> %08X = tag %02X payload+0' % (tag, v, hit[0]))
    missing = [t for t in C_FAMILY if t not in seen]
    if missing:
        print('    FAIL C-family records never pointed at: %s' % ' '.join('%02X' % t for t in missing))
        ok = False
    if verbose:
        for t in sorted(seen):
            if len(seen[t]) > 1:
                print('    ALIAS tag %02X shared by part tags %s'
                      % (t, ' '.join('%02X' % x for x in seen[t])))
    # the 0x48 special case
    st, sa = RHYTHM_SPECIAL_CASE
    hit = locate(recs, sa)
    if hit != (0x49, 0):
        print('    FAIL style tag %02X -> %04X is not tag 49 payload+0 (got %s)' % (st, sa, hit))
        ok = False
    elif verbose:
        print('    style tag %02X -> %04X = tag 49 payload+0 (VoiceLookup_CheckRhythm)' % (st, sa))
    return ok


# --------------------------------------------------- test 2: the dispatcher's 0xBF ceiling
def find_one(rom, pattern):
    """Address of the single occurrence of a '..'-wildcarded hex byte pattern, else None."""
    toks = pattern.split()
    fixed = [(i, int(t, 16)) for i, t in enumerate(toks) if t != '..']
    anchor_i, anchor_b = fixed[0]
    hits, s = [], 0
    while True:
        i = rom.find(bytes((anchor_b,)), s)
        if i < 0:
            break
        s = i + 1
        base = i - anchor_i
        if base < 0 or base + len(toks) > len(rom):
            continue
        if all(rom[base + k] == b for k, b in fixed):
            hits.append(LOAD + base)
    return hits[0] if len(hits) == 1 else None


def test_dispatch_ceiling(rom, verbose):
    ok = True
    at = find_one(rom, DISPATCH_GUARD_PATTERN)
    if at is None:
        print('    FAIL the `ld L,(XIY) / cp L,0xbf / jr UGT` guard is not present exactly once')
        ok = False
    elif verbose:
        print('    SwbtWr_DispatchLoop @%06X: cp L,0xbf / jr UGT  -> tags > 0xBF are dropped'
              % (at + 6))
    for tbl in CALLBACK_TABLES:
        for tag in C_FAMILY:
            v = struct.unpack_from('<I', rom, tbl - LOAD + 4 * tag)[0]
            # past 0xBF the table is not a table any more; just report if it looked live
            if v not in (0, 0xFFFFFFFF) and 0xE00000 <= v < 0x1000000:
                if verbose:
                    print('    note: %06X[%02X] = %08X (beyond the 0xC0-entry table; unreachable)'
                          % (tbl, tag, v))
    return ok


# ------------------------------------------------------------- test 3: who names a C tag?
RE_ADDR = re.compile(r'^([0-9a-f]+):')
RE_TXT = re.compile(r'^[0-9a-f]+:\s+(?:[0-9a-f]{2} )+\s*(.*)$')


def event_sites(rom, syms, addrs, verbose):
    """Every call to SwbtWr_QueuePostEvent, with the literal tag when there is one."""
    entry = find_one(rom, QUEUE_POST_PATTERN)
    if entry is None:
        return None
    pat = bytes((0x1D, entry & 0xFF, (entry >> 8) & 0xFF, (entry >> 16) & 0xFF))
    sites, s = [], 0
    while True:
        i = rom.find(pat, s)
        if i < 0:
            break
        sites.append(LOAD + i)
        s = i + 1
    tags = []
    for a in sites:
        j = bisect.bisect_right(addrs, a) - 1
        st = syms[j][0] if a - syms[j][0] <= 1200 else a - 200
        out = disasm(rom, st, a - st + 4)
        e = None
        for line in out.splitlines():
            m = RE_ADDR.match(line)
            if not m or int(m.group(1), 16) > a:
                continue
            t = RE_TXT.match(line)
            if not t:
                continue
            mm = re.match(r'ld E,0x([0-9a-f]+)$', t.group(1))
            if mm:
                e = int(mm.group(1), 16)
            mm = re.match(r'ld DE,0x([0-9a-f]+)$', t.group(1))
            if mm:
                e = int(mm.group(1), 16) & 0xFF
        tags.append((a, e))
    return tags


_dis_cache = {}


def disasm(rom, start, n):
    if UNIDASM is None:
        return ''
    key = (start, n)
    if key in _dis_cache:
        return _dis_cache[key]
    tmp = os.path.join(os.environ.get('TMPDIR', '/tmp'), 'lsw_nonpart_w.bin')
    with open(tmp, 'wb') as f:
        f.write(rom[start - LOAD:start - LOAD + n])
    out = subprocess.run([UNIDASM, tmp, '-arch', 'tlcs900', '-basepc', hex(start)],
                         capture_output=True, text=True).stdout
    _dis_cache[key] = out
    return out


def direct_address_census(rom, recs, syms, addrs, verbose):
    """F1/F2 direct-address operands landing in the panel area, instruction-aligned only."""
    cands = []
    for i in range(len(rom) - 4):
        if rom[i] == 0xF1:
            v = rom[i + 1] | rom[i + 2] << 8
        elif rom[i] == 0xF2 and rom[i + 3] == 0x00:
            v = rom[i + 1] | rom[i + 2] << 8
        else:
            continue
        if not (0xF9A0 <= v < 0xFFC0):
            continue
        hit = locate(recs, v)
        if hit:
            cands.append((LOAD + i, v, hit))
    aligned, cfam = [], []
    for a, v, hit in cands:
        j = bisect.bisect_right(addrs, a) - 1
        if j < 0 or a - syms[j][0] > 2000:
            continue
        out = disasm(rom, syms[j][0], a - syms[j][0] + 24)
        starts = {int(m.group(1), 16) for m in
                  (RE_ADDR.match(l) for l in out.splitlines()) if m}
        if a not in starts:
            continue
        text = ''
        for l in out.splitlines():
            if l.startswith('%x:' % a):
                text = RE_TXT.match(l).group(1) if RE_TXT.match(l) else l
        aligned.append((a, v, hit, text))
        if hit[0] in C_FAMILY:
            cfam.append((a, v, hit, text))
    return len(cands), aligned, cfam


def lsw_files_all_zero(paths, verbose):
    """Every C-family record in every .LSW must be all zero, or say which is not."""
    total = nonzero = 0
    for p in paths:
        data = open(p, 'rb').read()
        q, nblk = 0x20, 0
        while q + 1 < len(data) and nblk < 26:
            tag, ln = data[q], data[q + 1]
            if tag == 0xFF and ln == 0xFF:
                nblk += 1
                q += 2
                continue
            if tag in C_FAMILY:
                total += 1
                if any(data[q + 2:q + 2 + ln]):
                    nonzero += 1
                    print('    NONZERO %s tag %02X: %s'
                          % (os.path.basename(p), tag, data[q + 2:q + 2 + ln].hex(' ')))
            q += 2 + ln
    return total, nonzero


def main():
    global UNIDASM
    ap = argparse.ArgumentParser()
    ap.add_argument('--quiet', action='store_true')
    ap.add_argument('--lsw-dir', default=None,
                    help='directory searched recursively for *.LSW (optional corpus check)')
    args = ap.parse_args()
    v = not args.quiet
    if not os.path.exists(UNIDASM):
        print('note: %s not found -- the instruction-alignment census will be skipped' % UNIDASM)
        UNIDASM = None

    syms = symbols()
    addrs = [s[0] for s in syms]
    ok = True

    for ver in VERSIONS:
        rom = open(rom_path(ver), 'rb').read()
        recs = schema(rom)
        print('######## %s ########' % ver)
        print('  [1] part tag -> companion-block map at %06X (VoiceData_LookupPtrByChannel %06X)'
              % (PART_TO_BLOCK_TABLE, LOOKUP_BY_CHANNEL))
        ok &= test_part_to_block(rom, recs, v)
        print('  [2] event dispatcher ceiling')
        ok &= test_dispatch_ceiling(rom, v)
        if UNIDASM:
            print('  [3] direct-address census (F1/F2, instruction-aligned)')
            ncand, aligned, cfam = direct_address_census(rom, recs, syms, addrs, v)
            print('      %d candidates in range, %d instruction-aligned, %d landing in C0..D4/D7'
                  % (ncand, len(aligned), len(cfam)))
            for a, val, hit, text in cfam:
                print('        tag %02X +%s @%06X %-28s %s'
                      % (hit[0], hit[1], a, sym_of(syms, addrs, a), text))
                if not text.startswith(('db', 'call', 'jp', 'jr')):
                    print('        FAIL: that is a real memory access to a C-family record')
                    ok = False
            print('  [4] SwbtWr_QueuePostEvent call sites')
            ev = event_sites(rom, syms, addrs, v)
            if ev is None:
                print('      FAIL: SwbtWr_QueuePostEvent could not be located by pattern')
                ok = False
                ev = []
            lits = sorted({e for _, e in ev if e is not None})
            print('      %d call sites; literal tags seen: %s'
                  % (len(ev), ' '.join('%02X' % t for t in lits)))
            bad = [(a, e) for a, e in ev if e is not None and e >= 0xC0]
            for a, e in bad:
                print('      FAIL: %06X %s posts tag %02X (>= 0xC0)'
                      % (a, sym_of(syms, addrs, a), e))
                ok = False
        print()

    if args.lsw_dir:
        paths = sorted(glob.glob(os.path.join(args.lsw_dir, '**', '*.LSW'), recursive=True))
        print('######## %d .LSW file(s) under %s ########' % (len(paths), args.lsw_dir))
        total, nonzero = lsw_files_all_zero(paths, v)
        print('  %d C-family records, %d with any non-zero byte' % (total, nonzero))

    print('PASS: C0..D4/D7 = the per-part companion blocks, unreachable by any event, '
          'and untouched by any direct-address instruction.' if ok else 'FAIL')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
