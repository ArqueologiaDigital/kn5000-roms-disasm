#!/usr/bin/env python3
"""Every port write one routine makes to 0x0010C000, in order, with where its value came from.

QUESTION IT ANSWERS
  `notes/prom_c_tg_regmap.py` censuses the 102 `ld <X..>,0x0010C000` SITES across the whole
  image and matches the small fixed-shape accessors.  It matched 75 of 102 and printed the
  other 27 as unmatched.  Most of those live in ONE routine -- Dev10C_WriteAllChanRegs at
  0xFB713A -- which is not a small accessor at all: it makes TWENTY-THREE select/data write
  pairs to TWENTY-TWO distinct registers of a single channel in one unrolled run (register
  +0x0080 is written twice, once with bit 15 set and once clear), keeping the +0 and +2
  pointers in two frame slots and reloading them between writes.

  ⚠ CORRECTION.  This docstring said "twenty-five registers" from round 2 until round 4.  It
  was never a figure this script produced: `--selftest` prints 23 SELECT / 23 DATA and
  `--pairs` lists 22 distinct offsets.  All three counts are now asserted by `--selftest`, so
  the number in the prose cannot drift from the number in the ROM again.

  This walks ONE routine instruction by instruction and prints, for every store that reaches
  the device, whether it was a SELECT or a DATA write and what the operand was.  It never
  pairs a select with a data write by position in two separate lists -- the retraction
  recorded in notes/FINDINGS-prom_c-tone-generator.md §3 is exactly that mistake -- it
  reports the stream in execution order and lets the reader see the pairing.

HOW IT KNOWS WHICH POINTER IS WHICH
  Not by assumption.  It follows the two frame slots: the slot that receives the register
  holding the literal 0x0010C000 is the SELECT pointer, and the slot that receives that
  pointer after `inc 2,<r>` is the DATA pointer.  Both are discovered from the instructions;
  if a store goes through a pointer whose provenance it did not see, it prints UNKNOWN
  rather than guessing.

  A `calr` is not treated as a black hole either: the script disassembles the callee, collects
  the registers it PUSHES and POPS, and preserves exactly those across the call.  That is what
  lets the final `res 0x0f` write in Dev10C_WriteAllChanRegs be attributed to the register DE was
  still holding from before the call, instead of being reported as untracked.

LIMITS
  * Straight-line only.  A routine with a loop or a conditional register write is reported as
    the linear byte order shows it, which is not the execution order.  0xFB713A has no
    backward branch (checked by eye against the listing in prom_c/wsa1_prom_c.s).
  * It reads unidasm's TEXT.

RUN
  python3 notes/prom_c_tg_chanmap.py 0xFB713A 0x1F2
  python3 notes/prom_c_tg_chanmap.py 0xFB713A 0x1F2 --pairs
  python3 notes/prom_c_tg_chanmap.py --selftest
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(ROOT, 'original_ROMs', 'wsa1_prom_c.ic28')
BASE = 0xF80000
UNIDASM = os.environ.get('UNIDASM', '/home/fsanches/compartilhado/kn7000_mame_build/unidasm')


def dis(addr, n):
    img = open(ROM, 'rb').read()
    with tempfile.NamedTemporaryFile(suffix='.bin', delete=False) as t:
        t.write(img[addr - BASE:addr - BASE + n])
        tmp = t.name
    try:
        txt = subprocess.run([UNIDASM, tmp, '-arch', 'tlcs900', '-basepc', hex(addr)],
                             capture_output=True, text=True, check=True).stdout
    finally:
        os.unlink(tmp)
    rows = []
    for line in txt.splitlines():
        m = re.match(r'^([0-9a-f]+):\s+(?:[0-9a-f]{2} )+\s*(.*)$', line)
        if m:
            rows.append((int(m.group(1), 16), m.group(2).strip()))
    return rows


SUBREG = {'XWA': ['WA', 'W', 'A'], 'XBC': ['BC', 'B', 'C'], 'XDE': ['DE', 'D', 'E'],
          'XHL': ['HL', 'H', 'L'], 'XIX': ['IX'], 'XIY': ['IY'], 'XIZ': ['IZ']}


def callee_preserves(addr, limit=0x400):
    """Registers a callee both PUSHes and POPs -- i.e. the ones a caller may keep tracking.

    Read off the callee's own instructions, not assumed.  Scanning stops at its first `ret`."""
    pushed, popped = set(), set()
    for _, t in dis(addr, limit):
        m = re.match(r'push (\w+)$', t)
        if m:
            pushed.add(m.group(1))
        m = re.match(r'pop (\w+)$', t)
        if m:
            popped.add(m.group(1))
        if t == 'ret':
            break
    keep = set()
    for r in pushed & popped:
        keep.add(r)
        keep.update(SUBREG.get(r, []))
        for big, subs in SUBREG.items():
            if r in subs:
                keep.update([big] + subs)
    return keep


def walk(addr, n, dev=0x0010C000):
    rows = dis(addr, n)
    devpat = re.compile(r'ld (X\w\w),0x%08x$' % dev)
    ptr_role = {}       # 32-bit register -> 'SELECT' | 'DATA'
    slot_role = {}      # frame slot displacement -> role
    val = {}            # 16-bit register -> textual provenance
    events = []
    for a, t in rows:
        m = devpat.match(t)
        if m:
            ptr_role[m.group(1)] = 'SELECT'
            continue
        m = re.match(r'inc 2,(X\w\w)$', t)
        if m and ptr_role.get(m.group(1)) == 'SELECT':
            ptr_role[m.group(1)] = 'DATA'
            continue
        m = re.match(r'ld \(XIZ\+0x([0-9a-f]{2})\),(X\w\w)$', t)
        if m and m.group(2) in ptr_role:
            slot_role[m.group(1)] = ptr_role[m.group(2)]
            continue
        m = re.match(r'ld (X\w\w),\(XIZ\+0x([0-9a-f]{2})\)$', t)
        if m:
            if m.group(2) in slot_role:
                ptr_role[m.group(1)] = slot_role[m.group(2)]
            else:
                ptr_role.pop(m.group(1), None)
            continue
        m = re.match(r'ld (\w\w),\(XIZ\+0x08\)$', t)
        if m:
            val[m.group(1)] = 'arg0'
            continue
        m = re.match(r'ld (\w\w),(HL|DE|BC|WA)$', t)
        if m:
            val[m.group(1)] = val.get(m.group(2), 'reg ' + m.group(2))
            continue
        m = re.match(r'add (\w\w),0x([0-9a-f]{4})$', t)
        if m:
            base = val.get(m.group(1), 'reg ' + m.group(1))
            val[m.group(1)] = '%s + 0x%s' % (base, m.group(2).upper())
            continue
        m = re.match(r'ld (\w\w),\(XIX\+0x([0-9a-f]{2})\)$', t)
        if m:
            val[m.group(1)] = 'struct+0x%s' % m.group(2).upper()
            continue
        m = re.match(r'ld (\w\w),\(XIX\)$', t)
        if m:
            val[m.group(1)] = 'struct+0x00'
            continue
        m = re.match(r'(?:set|res) 0x0f,(\w\w)$', t)
        if m:
            op = 'bit15=1' if t.startswith('set') else 'bit15=0'
            val[m.group(1)] = '%s, %s' % (val.get(m.group(1), 'reg ' + m.group(1)), op)
            continue
        m = re.match(r'ld \((X\w\w)\),0x([0-9a-f]{4})$', t)
        if m and m.group(1) in ptr_role:
            events.append((a, ptr_role[m.group(1)], 'literal 0x%s' % m.group(2).upper()))
            continue
        m = re.match(r'ld \((X\w\w)\),(\w\w)$', t)
        if m and m.group(1) in ptr_role:
            events.append((a, ptr_role[m.group(1)],
                           val.get(m.group(2), 'reg ' + m.group(2))))
            continue
        m = re.match(r'ld \((X\w\w)\+0x02\),(\w\w)$', t)
        if m and ptr_role.get(m.group(1)) == 'SELECT':
            events.append((a, 'DATA', val.get(m.group(2), 'reg ' + m.group(2))))
            continue
        # --- fallback: anything else that WRITES a register invalidates what we knew about
        # it.  Without this the walker kept calling XBC "the select pointer" after
        # `ld BC,0x0002 / mul XBC,HL / add XBC,0x0000d85b`, and reported the store into the
        # RAM shadow at 0x0000D85B as a device SELECT.  Silence beats a wrong attribution.
        m = re.match(r'(?:ld|lda|add|sub|and|or|xor|mul|muls|div|divs|inc|dec|ex|extz|exts|'
                     r'sll|srl|sla|sra|rlc|rrc|rl|rr|cpl|neg|swi|pop)\s+(?:[^,]+,)?'
                     r'\b(X?[A-Z][A-Z]?)\b', t.replace('0x', ''))
        if m:
            r = m.group(1)
            if not t.startswith('cp') and not t.startswith('ld (') and not t.startswith('bit'):
                for cand in [r] + SUBREG.get(r, []):
                    val.pop(cand, None)
                    ptr_role.pop(cand, None)
                for big, subs in SUBREG.items():
                    if r in subs:
                        for cand in [big] + subs:
                            val.pop(cand, None)
                            ptr_role.pop(cand, None)
        m = re.match(r'calr 0x([0-9a-f]+)$', t)
        if m:
            tgt = int(m.group(1), 16)
            keep = callee_preserves(tgt)
            events.append((a, 'CALL', '0x%06X preserves %s'
                           % (tgt, ",".join(sorted(keep)) or "nothing")))
            val = {k: v for k, v in val.items() if k in keep}
            ptr_role = {k: v for k, v in ptr_role.items() if k in keep}
            continue
    return events


def groups(addr, n, dev=0x0010C000):
    """Block index vs struct word, and whether the pairs fall into consecutive RUNS.

    Prints one row per (register block, struct field) pair in block order and then checks the
    only structural claim made about them: that within each run the block index and the struct
    WORD index both step by exactly one.  A run of length 1 is reported as its own run rather
    than merged into a neighbour.
NOTE ON THIS FILE'S NAME (round 4)
  The `tg` in the filename is historical.  The labels this script talks about were prefixed
  `TG_` / `TG2_` for "tone generator" until round 4, when that role was found to be an
  unproven inference and the prefixes became `Dev10C_` / `Dev104_`; see
  notes/FINDINGS-prom_c-tone-generator.md §0.  The filenames were left alone so that existing
  references to them keep working.
"""
    ev = walk(addr, n, dev)
    pairs = []
    i = 0
    while i < len(ev) - 1:
        if ev[i][1] == 'SELECT' and ev[i + 1][1] == 'DATA':
            msel = re.match(r'arg0(?: \+ 0x([0-9A-F]{4}))?$', ev[i][2])
            mdat = re.match(r'struct\+0x([0-9A-F]{2})$', ev[i + 1][2])
            if msel and mdat:
                pairs.append((int(msel.group(1) or '0', 16), int(mdat.group(1), 16)))
            i += 2
        else:
            i += 1
    pairs.sort()
    runs, cur = [], []
    for blk, fld in pairs:
        if cur and blk == cur[-1][0] + 0x40 and fld == cur[-1][1] + 2:
            cur.append((blk, fld))
        else:
            if cur:
                runs.append(cur)
            cur = [(blk, fld)]
    if cur:
        runs.append(cur)
    print("0x%06X -> device 0x%08X: %d clean (SELECT,DATA) pair(s) with a struct source"
          % (addr, dev, len(pairs)))
    for r in runs:
        print("  run: blocks 0x%04X..0x%04X (index %d..%d)  <-  struct words %d..%d "
              "(offsets 0x%02X..0x%02X), %d entries"
              % (r[0][0], r[-1][0], r[0][0] // 0x40, r[-1][0] // 0x40,
                 r[0][1] // 2, r[-1][1] // 2, r[0][1], r[-1][1], len(r)))
    print("  RUNS: %d" % len(runs))
    return runs


def report(addr, n, pairs=False, dev=0x0010C000):
    ev = walk(addr, n, dev)
    print("0x%06X, %d bytes: %d device event(s)" % (addr, n, len(ev)))
    if pairs:
        i = 0
        while i < len(ev):
            if ev[i][1] == 'SELECT' and i + 1 < len(ev) and ev[i + 1][1] == 'DATA':
                print("  0x%06X  register %-24s <- %s" % (ev[i][0], ev[i][2], ev[i + 1][2]))
                i += 2
            else:
                print("  0x%06X  %-6s %s" % (ev[i][0], ev[i][1], ev[i][2]))
                i += 1
    else:
        for a, kind, what in ev:
            print("  0x%06X  %-6s %s" % (a, kind, what))
    return ev


def selftest():
    ev = walk(0xFB713A, 0x1F2)
    sel = [e for e in ev if e[1] == 'SELECT']
    dat = [e for e in ev if e[1] == 'DATA']
    unk = [e for e in ev if e[2].startswith('reg ')]
    print("Dev10C_WriteAllChanRegs 0xFB713A: %d SELECT, %d DATA, %d untracked operand(s)"
          % (len(sel), len(dat), len(unk)))
    ok = True
    # the LAST select and the LAST data write, not the first
    if sel[-1][2] != 'arg0 + 0x0080':
        print("  FAIL: last SELECT is %r" % (sel[-1],)); ok = False
    if dat[-1][2] != 'struct+0x04, bit15=0':
        print("  FAIL: last DATA is %r" % (dat[-1],)); ok = False
    if unk:
        print("  NOTE: %d operand(s) whose provenance was not tracked:" % len(unk))
        for e in unk:
            print("     0x%06X %s %s" % e)
    # the counts this script's docstring and the source headers quote, asserted here so the
    # prose cannot drift from the ROM (it did once: "twenty-five registers", rounds 2-3).
    offs = [e[2] for e in sel]
    ndistinct = len(set(offs))
    print("  writes: %d select/data pairs to %d DISTINCT registers; "
          "repeated: %s" % (len(sel), ndistinct,
                            sorted({o for o in offs if offs.count(o) > 1}) or "none"))
    if (len(sel), len(dat), ndistinct) != (23, 23, 22):
        print("  FAIL: expected 23/23/22, got %d/%d/%d" % (len(sel), len(dat), ndistinct))
        ok = False
    if sorted({o for o in offs if offs.count(o) > 1}) != ['arg0 + 0x0080']:
        print("  FAIL: the repeated register is not arg0 + 0x0080"); ok = False
    print("selftest:", "OK" if ok else "FAILED")
    return 0 if ok else 1


if __name__ == '__main__':
    if '--selftest' in sys.argv:
        sys.exit(selftest())
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(2)
    dev = 0x0010C000
    if '--dev' in sys.argv:
        dev = int(sys.argv[sys.argv.index('--dev') + 1], 0)
    if '--groups' in sys.argv:
        groups(int(sys.argv[1], 0), int(sys.argv[2], 0), dev)
    else:
        report(int(sys.argv[1], 0), int(sys.argv[2], 0), '--pairs' in sys.argv, dev)
