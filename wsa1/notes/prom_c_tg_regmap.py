#!/usr/bin/env python3
"""What register of the 0x0010C000 device does each accessor write, and from which struct field?

QUESTION ANSWERED
  prom_c loads the literal 0x0010C000 into a pointer register 102 times -- more than for any
  other device on CPU 2 (notes/FINDINGS-memory-map.md).  The device is an ADDRESS/DATA pair:
  a 16-bit register NUMBER goes to +0x00 and that register's 16-bit VALUE to +0x02.  Almost
  every site sits inside a tiny stack-frame routine of the fixed shape

        link XIZ,imm            ; C prologue
        ld  <r16>,(XIZ+0x08)    ; arg0  = channel
        add <r16>,0xNNNN        ; + a constant  -> the register number
        ld  XIX,0x0010C000
        ld  (XIX),<r16>         ; select
        ld  XBC,(XIZ+0x0a)      ; arg1  = pointer to a per-voice struct
        ld  <r16>,(XBC+0xNN)    ; the value
        ld  (XIX+0x02),<r16>    ; write

  so the pair (constant, struct offset) IS the register map.  This script extracts both
  MECHANICALLY, for every one of the 102 sites, by parsing unidasm's rendering -- never by
  eye -- and prints the sites it could NOT match rather than dropping them.

WHAT IS AND IS NOT PROVEN BY THE OUTPUT
  * The (register number, source field) pairs are read straight off instructions: proven.
  * "constant / 0x40 = a parameter index" is an OBSERVATION about the constants, printed as
    such.  It is not read off any instruction.
  * What each register DOES is not established anywhere here.

RUN
  python3 notes/prom_c_tg_regmap.py                # the full census
  python3 notes/prom_c_tg_regmap.py --unmatched    # only the sites the matcher rejected
  python3 notes/prom_c_tg_regmap.py --selftest     # re-derive the site count and check the LAST site
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(ROOT, 'original_ROMs', 'wsa1_prom_c.ic28')
BASE = 0xF80000
DEV = 0x0010C000
UNIDASM = os.environ.get('UNIDASM', '/home/fsanches/compartilhado/mame/unidasm')
REG32 = {0: 'XWA', 1: 'XBC', 2: 'XDE', 3: 'XHL', 4: 'XIX', 5: 'XIY', 6: 'XIZ', 7: 'XSP'}


def load():
    with open(ROM, 'rb') as f:
        return f.read()


def sites(img):
    """Every `ld <X..>,0x0010C000`.  The literal is 3 bytes; the opcode in front of it is
    0x40|r, the 32-bit-register immediate load, so the match is the whole instruction."""
    pat = DEV.to_bytes(3, 'little')
    out = []
    for m in re.finditer(re.escape(pat), img):
        op = img[m.start() - 1]
        if 0x40 <= op <= 0x47 and img[m.start() + 3] == 0x00:
            out.append((BASE + m.start() - 1, REG32[op & 7]))
    return out


def dis(img, addr, n):
    off = addr - BASE
    with tempfile.NamedTemporaryFile(suffix='.bin', delete=False) as t:
        t.write(img[off:off + n])
        tmp = t.name
    try:
        txt = subprocess.run([UNIDASM, tmp, '-arch', 'tlcs900', '-basepc', hex(addr)],
                             capture_output=True, text=True, check=True).stdout
    finally:
        os.unlink(tmp)
    rows = []
    for line in txt.splitlines():
        m = re.match(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$', line)
        if m:
            rows.append((int(m.group(1), 16), m.group(2).split(), m.group(3).strip()))
    return rows


# the whole accessor is short; 0x40 bytes of context each way covers every observed one
BACK, FWD = 0x30, 0x30

RE_ADD = re.compile(r'^add (\w+),0x([0-9a-f]+)$')
RE_ARG = re.compile(r'^ld (\w+),\(XIZ\+0x08\)$')
RE_FLD = re.compile(r'^ld (\w+),\((\w+)\+0x([0-9a-f]+)\)$')
RE_SEL = re.compile(r'^ld \((\w+)\),(\w+)$')
RE_SELI = re.compile(r'^ld \((\w+)\),0x([0-9a-f]+)$')
RE_DAT = re.compile(r'^ld \((\w+)\+0x02\),(\w+)$')
RE_DATI = re.compile(r'^ld \((\w+)\+0x02\),0x([0-9a-f]+)$')


def analyse(img, addr, ptr):
    """Walk forward from the `ld <ptr>,0x0010C000` and pair each SELECT with the DATA write
    that follows it.  Returns a list of (regnum_text, value_text) and the site's verdict."""
    rows = dis(img, addr - BACK, BACK + FWD)
    idx = next((i for i, r in enumerate(rows) if r[0] == addr), None)
    if idx is None:
        return None, 'unidasm did not land on the site'
    # ⚠ BOUND THE WINDOW TO ONE ROUTINE.  The accessors are packed back to back and a raw
    # +-0x30 window straddles its neighbours -- the first draft of this script reported a
    # second, non-existent register write for 0xFACE74 because the NEXT routine's
    # `ld BC,(XIZ+0x08)` fell inside the window.  Start at the last `link XIZ` at or before
    # the site, stop at the first `ret`/`reti` at or after it.
    lo = 0
    for i in range(idx, -1, -1):
        if rows[i][2].startswith('link XIZ'):
            lo = i
            break
    hi = len(rows)
    for i in range(idx, len(rows)):
        if rows[i][2] in ('ret', 'reti') or rows[i][2].startswith('ret '):
            hi = i + 1
            break
    rows = rows[lo:hi]
    # value of every 16-bit register we can follow, as text
    val = {}
    # scan the whole window (before AND after): the `add` may precede the pointer load
    pairs = []
    pending = None            # (regnum_text)
    dev_ptrs = {ptr}          # registers currently holding 0x0010C000
    plus2 = set()             # registers holding 0x0010C002
    for a, by, txt in rows:
        m = RE_ARG.match(txt)
        if m:
            val[m.group(1)] = 'chan'
            continue
        m = RE_ADD.match(txt)
        if m and m.group(1) in val:
            val[m.group(1)] = 'chan+0x%04X' % int(m.group(2), 16)
            continue
        m = re.match(r'^ld (\w+),(\w+)$', txt)          # register copy
        if m:
            if m.group(2) in val:
                val[m.group(1)] = val[m.group(2)]
            elif m.group(2) in dev_ptrs:
                dev_ptrs.add(m.group(1))
            continue
        m = re.match(r'^inc 2,(\w+)$', txt)
        if m and m.group(1) in dev_ptrs:
            dev_ptrs.discard(m.group(1)); plus2.add(m.group(1))
            continue
        m = re.match(r'^ld \(XIZ\+0x([0-9a-f]+)\),(\w+)$', txt)   # spill the +2 pointer
        if m and m.group(2) in plus2:
            plus2.add('(XIZ+0x%s)' % m.group(1))
            continue
        m = re.match(r'^ld (\w+),\(XIZ\+0x([0-9a-f]+)\)$', txt)
        if m and '(XIZ+0x%s)' % m.group(2) in plus2:
            plus2.add(m.group(1))
            continue
        m = RE_FLD.match(txt)
        if m:
            val[m.group(1)] = 'arg1->0x%02X' % int(m.group(3), 16)
            continue
        m = RE_SEL.match(txt)
        if m and m.group(1) in dev_ptrs:
            pending = val.get(m.group(2), '<%s>' % m.group(2)); continue
        m = RE_SELI.match(txt)
        if m and m.group(1) in dev_ptrs:
            pending = '0x%04X' % int(m.group(2), 16); continue
        m = RE_DAT.match(txt)
        if m and m.group(1) in dev_ptrs and pending is not None:
            pairs.append((pending, val.get(m.group(2), '<%s>' % m.group(2)))); pending = None
            continue
        m = RE_DATI.match(txt)
        if m and m.group(1) in dev_ptrs and pending is not None:
            pairs.append((pending, '#0x%04X' % int(m.group(2), 16))); pending = None
            continue
        m = RE_SEL.match(txt)
        if m and m.group(1) in plus2 and pending is not None:
            pairs.append((pending, val.get(m.group(2), '<%s>' % m.group(2)))); pending = None
            continue
        m = re.match(r'^ld (\w+),\((\w+)\)$', txt)      # a READ of the data port
        if m and (m.group(2) in plus2 or m.group(2) in dev_ptrs) and pending is not None:
            pairs.append((pending, 'READ -> %s' % m.group(1))); pending = None
            continue
    if not pairs:
        return None, 'no select/data pair matched'
    return pairs, None


# ---------------------------------------------------------------------------
# The 0xFACE67..0xFAD141 accessor bank and its call sites
BANK = [0xFACE67, 0xFACE89, 0xFACEA2, 0xFACEDE, 0xFACF1A, 0xFACF3C, 0xFACF78, 0xFACFB4,
        0xFACFD6, 0xFACFF8, 0xFAD01A, 0xFAD03C, 0xFAD05E, 0xFAD080, 0xFAD0A2, 0xFAD0E6,
        0xFAD12A]
BANK_END = 0xFAD142

# `lda XBC,0x00D75E` -- the address of the staging struct the accessors read
LDA_D75E = bytes([0xF2, 0x5E, 0xD7, 0x00, 0x31])
PUSH_XBC = 0x39
PUSH_WA = 0x28
CALR = 0x1E


def calr_sites(img, target):
    """Every `1E dd dd` whose signed 16-bit displacement lands on `target`."""
    out = []
    for off in range(len(img) - 2):
        if img[off] != CALR:
            continue
        d = int.from_bytes(img[off + 1:off + 3], 'little', signed=True)
        if BASE + off + 3 + d == target:
            out.append(BASE + off)
    return out


def callers(img):
    """For every routine in the bank, list its calr sites and say whether the site sets the
    arguments up in the fixed shape  lda XBC,0x00D75E / push XBC / push WA / calr."""
    rows = []
    for ent in BANK:
        for site in calr_sites(img, ent):
            o = site - BASE
            # the two argument pushes are not adjacent -- the channel number is computed
            # between them -- so the check is: the byte immediately before the calr is
            # `push WA` (the channel word, pushed last = lowest address = arg0), and
            # somewhere in the 24 bytes before it sits `lda XBC,0x00D75E` immediately
            # followed by `push XBC` (arg1).
            w = img[max(0, o - 24):o]
            j = w.find(LDA_D75E)
            fixed = (img[o - 1] == PUSH_WA and j >= 0
                     and w[j + len(LDA_D75E)] == PUSH_XBC)
            rows.append((ent, site, fixed))
    return rows



# ---------------------------------------------------------------------------
# The `chan >= 0x40` split, and the identity that explains it
#
# Six routines across the two accessor banks compare the channel argument with
# 0x40 and take a different (register block, staging field) pair on each arm.
# The claim this check tests is that the HIGH arm is not a different parameter at
# all: its base is exactly 0x40 BELOW the base an UNCONDITIONAL routine uses for
# the same staging field, and the channel argument already carries that 0x40.
#
# Nothing is assumed about which pairs exist: the reference set is built by
# reading every accessor-family routine that has NO bound check, so if the
# identity failed the check would say so instead of printing a table.
SPLIT_ROUTINES = [0xFAD0A2, 0xFAD0E6, 0xFB7F09, 0xFB7FCE, 0xFB8012, 0xFB80A9]

# every routine of the family, as (start, end); discovered the same way the
# --dups list was, by walking `link XIZ` .. `ret` from each 0x0010C000 site
FAMILY = [(0xFACE67, 0xFACE89), (0xFACE89, 0xFACEA2), (0xFACEA2, 0xFACEDE),
          (0xFACEDE, 0xFACF1A), (0xFACF1A, 0xFACF3C), (0xFACF3C, 0xFACF78),
          (0xFACF78, 0xFACFB4), (0xFACFB4, 0xFACFD6), (0xFACFD6, 0xFACFF8),
          (0xFACFF8, 0xFAD01A), (0xFAD01A, 0xFAD03C), (0xFAD03C, 0xFAD05E),
          (0xFAD05E, 0xFAD080), (0xFAD080, 0xFAD0A2), (0xFAD0A2, 0xFAD0E6),
          (0xFAD0E6, 0xFAD12A), (0xFAD12A, 0xFAD142),
          (0xFB7B63, 0xFB7B9F), (0xFB7B9F, 0xFB7BC1), (0xFB7BC1, 0xFB7BE3),
          (0xFB7BE3, 0xFB7C05), (0xFB7C05, 0xFB7C27), (0xFB7C27, 0xFB7C8F),
          (0xFB7C8F, 0xFB7CB1), (0xFB7CB1, 0xFB7CFF), (0xFB7CFF, 0xFB7D1D),
          (0xFB7D1D, 0xFB7D85), (0xFB7D85, 0xFB7DA7), (0xFB7DA7, 0xFB7DF5),
          (0xFB7DF5, 0xFB7E13), (0xFB7E13, 0xFB7E7B), (0xFB7E7B, 0xFB7E9D),
          (0xFB7E9D, 0xFB7EEB), (0xFB7EEB, 0xFB7F09), (0xFB7F09, 0xFB7FCE),
          (0xFB7FCE, 0xFB8012), (0xFB8012, 0xFB80A9), (0xFB80A9, 0xFB80E1)]

CP40 = bytes([0xDB, 0xCF, 0x40, 0x00])        # cp HL,0x0040


def _walk(img, lo, hi):
    """Symbolically execute [lo,hi) and return every (register-number, value) pair the
    routine writes to the port, IN PROGRAM ORDER, each tagged with the arm it sits on.

    ⚠ WHY THIS IS NOT A ZIP.  The first draft of this check collected the `add r,imm`
    constants and the `ld r,(struct+d)` fetches into two lists and zipped them.  That is
    wrong the moment a routine writes more than one register: in Dev10C_Slot1or3_WriteGateAndValue
    the encounter order is add 0x0540, fetch 0x3A, fetch 0x3A, add 0x01C0, fetch 0x38, so the
    zip produced the pair (0x01C0, 0x3A), which the ROM never writes.  The check still passed,
    because the WRONG pairs happened to be in the reference set too -- exactly the kind of
    result that looks like evidence and is not.  This walk pairs a SELECT with the DATA WRITE
    that follows it, which is what the hardware sees.
    """
    rows = dis(img, lo, hi - lo)
    val, devp, plus, pend = {}, set(), set(), None
    out, arm, split = [], '', None
    for a, by, t in rows:
        if split is not None and a >= split:
            arm = 'high'
        m = re.match(r'^cp HL,0x0040$', t)
        if m:
            arm = 'low'
            continue
        m = re.match(r'^jr NC,0x([0-9a-f]+)$', t)
        if m and arm == 'low' and split is None:
            split = int(m.group(1), 16)
            continue
        m = re.match(r'^ld (\w+),\(XIZ\+0x08\)$', t)
        if m:
            val[m.group(1)] = 'chan'; continue
        m = re.match(r'^ld (\w+),\(XIZ\+0x0a\)$', t)
        if m:
            val[m.group(1)] = 'ARG1'; continue
        m = re.match(r'^add (\w+),0x([0-9a-f]+)$', t)
        if m and val.get(m.group(1)) == 'chan':
            val[m.group(1)] = 'chan+0x%04X' % int(m.group(2), 16); continue
        m = re.match(r'^ld (\w+),0x0010c000$', t)
        if m:
            r = m.group(1); devp.add(r); plus.discard(r); val.pop(r, None); continue
        m = re.match(r'^ld (\w+),(\w+)$', t)                      # register copy
        if m:
            d, srcr = m.group(1), m.group(2)
            devp.discard(d); plus.discard(d); val.pop(d, None)
            if srcr in devp: devp.add(d)
            elif srcr in plus: plus.add(d)
            elif srcr in val: val[d] = val[srcr]
            continue
        m = re.match(r'^inc 2,(\w+)$', t)
        if m and m.group(1) in devp:
            devp.discard(m.group(1)); plus.add(m.group(1)); continue
        m = re.match(r'^ld \(XIZ\+0x([0-9a-f]+)\),(\w+)$', t)    # spill
        if m:
            k = 'F%s' % m.group(1); srcr = m.group(2)
            devp.discard(k); plus.discard(k); val.pop(k, None)
            if srcr in devp: devp.add(k)
            elif srcr in plus: plus.add(k)
            elif srcr in val: val[k] = val[srcr]
            continue
        m = re.match(r'^ld (\w+),\(XIZ\+0x([0-9a-f]+)\)$', t)    # reload
        if m:
            d, k = m.group(1), 'F%s' % m.group(2)
            devp.discard(d); plus.discard(d); val.pop(d, None)
            if k in devp: devp.add(d)
            elif k in plus: plus.add(d)
            elif k in val: val[d] = val[k]
            continue
        m = re.match(r'^ld (\w+),\((\w+)\+0x([0-9a-f]+)\)$', t)  # struct field fetch
        if m and val.get(m.group(2)) == 'ARG1':
            val[m.group(1)] = 'F0x%02X' % int(m.group(3), 16); continue
        m = re.match(r'^res 0x0f,(\w+)$', t)
        if m and m.group(1) in val:
            val[m.group(1)] += '&~b15'; continue
        m = re.match(r'^ld \((\w+)\),0x([0-9a-f]+)$', t)          # immediate FIRST:
        if m:                                                      # 0x8100 also matches \w+
            ptr = m.group(1)
            if ptr in devp:
                if pend is not None: out.append((pend[0], pend[1], 'SELECT ONLY'))
                pend = (arm, '#0x%s' % m.group(2)); continue
            if ptr in plus and pend is not None:
                out.append((pend[0], pend[1], '#0x%s' % m.group(2))); pend = None; continue
        m = re.match(r'^ld \((\w+)\+0x02\),0x([0-9a-f]+)$', t)
        if m and m.group(1) in devp and pend is not None:
            out.append((pend[0], pend[1], '#0x%s' % m.group(2))); pend = None; continue
        m = re.match(r'^ld \((\w+)\),(\w+)$', t)
        if m:
            ptr, srcr = m.group(1), m.group(2)
            if ptr in devp:
                # ⚠ a second select before the first was consumed means the first select's
                # register number is written by a data write further on, past a join.  Emit
                # it so the check still sees it instead of silently losing an arm.
                if pend is not None: out.append((pend[0], pend[1], 'SELECT ONLY'))
                pend = (arm, val.get(srcr, '?' + srcr)); continue
            if ptr in plus and pend is not None:
                out.append((pend[0], pend[1], val.get(srcr, '?' + srcr))); pend = None; continue
        m = re.match(r'^ld \((\w+)\+0x02\),(\w+)$', t)
        if m and m.group(1) in devp and pend is not None:
            out.append((pend[0], pend[1], val.get(m.group(2), '?' + m.group(2)))); pend = None; continue
    return out


def slots(img, quiet=False):
    """Reference set = every (register number, staging field) an UNCONDITIONAL family
    routine writes.  Then, for each bound-checked routine, the low arm must be in that set
    as it stands and the high arm must be in it after +0x40."""
    ref, refbase = set(), set()
    say = (lambda *a, **k: None) if quiet else print
    for lo, hi in FAMILY:
        if lo in SPLIT_ROUTINES:
            continue
        for arm, reg, v in _walk(img, lo, hi):
            if reg.startswith('chan+0x'):
                b = int(reg[7:], 16)
                refbase.add(b)
                ref.add((b, v))
    say('(register number, value source) pairs written by the %d UNCONDITIONAL family '
          'routines:' % (len(FAMILY) - len(SPLIT_ROUTINES)))
    for b, v in sorted(ref):
        say('   chan+0x%04X <- %s' % (b, v))
    bad = 0
    for lo in SPLIT_ROUTINES:
        hi = dict(FAMILY)[lo]
        w = _walk(img, lo, hi)
        say()
        for arm, reg, v in w:
            if not reg.startswith('chan+0x'):
                say('0x%06X %-4s  %-12s <- %-12s : (register number is not chan+K)'
                      % (lo, arm, reg, v)); continue
            b = int(reg[7:], 16)
            if arm == 'high':
                ok = ((b + 0x40, v) in ref) or ((v.startswith('#') or v.startswith('SELECT'))
                                                and (b + 0x40) in refbase)
                say('0x%06X high  chan+0x%04X <- %-12s  +0x40 -> 0x%04X : %s'
                      % (lo, b, v, b + 0x40,
                         'an unconditional routine writes this' if ok else '*** NO MATCH ***'))
            else:
                ok = ((b, v) in ref) or ((v.startswith('#') or v.startswith('SELECT'))
                                         and b in refbase)
                say('0x%06X %-5s chan+0x%04X <- %-12s                  : %s'
                      % (lo, arm, b, v,
                         'an unconditional routine writes this' if ok else '*** NO MATCH ***'))
            bad += not ok
        if not w:
            say('0x%06X  *** no port write extracted ***' % lo); bad += 1
    say('\nFAILURES: %d' % bad)
    return bad



# ---------------------------------------------------------------------------
# The OTHER register device, 0x00104000
DEV104_ROUTINE = (0xFB77EF, 0xFB796E)      # Dev104_WriteAllChanRegs


def dev104(img):
    """Dev104_WriteAllChanRegs writes one channel's whole parameter set in one unrolled
    run.  Extract every (register block, struct field) pair from the ROM and test the
    relation field == 2 * (block / 0x40) over ALL of them -- including the last.
NOTE ON THIS FILE'S NAME (round 4)
  The `tg` in the filename is historical.  The labels this script talks about were prefixed
  `TG_` / `TG2_` for "tone generator" until round 4, when that role was found to be an
  unproven inference and the prefixes became `Dev10C_` / `Dev104_`; see
  notes/FINDINGS-prom_c-tone-generator.md §0.  The filenames were left alone so that existing
  references to them keep working.
"""
    lo, hi = DEV104_ROUTINE
    rows = dis(img, lo, hi - lo)
    val, dev, plusp, pend, out = {}, set(), set(), None, []
    for a, by, t in rows:
        m = re.match(r'^ld (\w+),\(XIZ\+0x08\)$', t)
        if m: val[m.group(1)] = 0; continue
        m = re.match(r'^ld (\w+),\(XIZ\+0x0a\)$', t)
        if m: val[m.group(1)] = 'ARG1'; continue
        m = re.match(r'^add (\w+),0x([0-9a-f]+)$', t)
        if m and val.get(m.group(1)) == 0: val[m.group(1)] = int(m.group(2), 16); continue
        m = re.match(r'^ld (\w+),0x00104000$', t)
        if m: dev.add(m.group(1)); plusp.discard(m.group(1)); val.pop(m.group(1), None); continue
        m = re.match(r'^ld (\w+),(\w+)$', t)
        if m:
            d, sr = m.group(1), m.group(2)
            dev.discard(d); plusp.discard(d); val.pop(d, None)
            if sr in dev: dev.add(d)
            elif sr in plusp: plusp.add(d)
            elif sr in val: val[d] = val[sr]
            continue
        m = re.match(r'^inc 2,(\w+)$', t)
        if m and m.group(1) in dev: dev.discard(m.group(1)); plusp.add(m.group(1)); continue
        m = re.match(r'^ld \(XIZ\+0x([0-9a-f]+)\),(\w+)$', t)
        if m:
            k, sr = 'F' + m.group(1), m.group(2)
            dev.discard(k); plusp.discard(k); val.pop(k, None)
            if sr in dev: dev.add(k)
            elif sr in plusp: plusp.add(k)
            elif sr in val: val[k] = val[sr]
            continue
        m = re.match(r'^ld (\w+),\(XIZ\+0x([0-9a-f]+)\)$', t)
        if m:
            d, k = m.group(1), 'F' + m.group(2)
            dev.discard(d); plusp.discard(d); val.pop(d, None)
            if k in dev: dev.add(d)
            elif k in plusp: plusp.add(d)
            elif k in val: val[d] = val[k]
            continue
        m = re.match(r'^ld (\w+),\((\w+)\+0x([0-9a-f]+)\)$', t)
        if m and val.get(m.group(2)) == 'ARG1': val[m.group(1)] = 'F%d' % int(m.group(3), 16); continue
        m = re.match(r'^ld (\w+),\((\w+)\)$', t)
        if m and val.get(m.group(2)) == 'ARG1': val[m.group(1)] = 'F0'; continue
        m = re.match(r'^ld \((\w+)\),(\w+)$', t)
        if m:
            ptr, sr = m.group(1), m.group(2)
            if ptr in dev: pend = val.get(sr); continue
            if ptr in plusp and pend is not None:
                out.append((pend, val.get(sr))); pend = None; continue
        m = re.match(r'^ld \((\w+)\+0x02\),(\w+)$', t)
        if m and m.group(1) in dev and pend is not None:
            out.append((pend, val.get(m.group(2)))); pend = None; continue
    bad = 0
    for base, f in out:
        if not isinstance(base, int) or not isinstance(f, str) or not f.startswith('F'):
            print('   base=%r field=%r   *** NOT EXTRACTED ***' % (base, f)); bad += 1; continue
        fld = int(f[1:])
        ok = base % 0x40 == 0 and fld == 2 * (base // 0x40)
        print('   register chan+0x%04X  <- struct word 0x%02X   block %2d   field == 2*block: %s'
              % (base, fld, base // 0x40, ok))
        bad += not ok
    print('\n0x00104000 per-channel registers written by 0x%06X: %d' % (lo, len(out)))
    print('blocks: %s' % ' '.join('0x%04X' % b for b, _ in out if isinstance(b, int)))
    print('FAILURES: %d' % bad)
    return bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--callers', action='store_true')
    ap.add_argument('--dups', action='store_true')
    ap.add_argument('--slots', action='store_true')
    ap.add_argument('--dev104', action='store_true')
    ap.add_argument('--unmatched', action='store_true')
    ap.add_argument('--selftest', action='store_true')
    args = ap.parse_args()
    img = load()
    st = sites(img)
    if args.dev104:
        raise SystemExit(1 if dev104(img) else 0)
    if args.slots:
        raise SystemExit(1 if slots(img) else 0)
    if args.dups:
        # Does each accessor's body occur anywhere else in prom_c?  The bodies are whole
        # routines (link .. ret), so an occurrence elsewhere is a second COPY of the routine,
        # not a coincidence -- but the count is printed, never asserted.
        ends = BANK[1:] + [BANK_END]
        ndup = 0
        for b, e in zip(BANK, ends):
            body = img[b - BASE:e - BASE]
            locs, off = [], 0
            while True:
                j = img.find(body, off)
                if j < 0:
                    break
                locs.append(BASE + j)
                off = j + 1
            elsewhere = [x for x in locs if not (BANK[0] <= x < BANK_END)]
            if elsewhere:
                ndup += 1
            print('0x%06X  %3d B  copies elsewhere in prom_c: %s' %
                  (b, e - b, ' '.join('0x%06X' % x for x in elsewhere) or 'none'))
        print('\nroutines of the bank that have at least one copy outside it: %d of %d'
              % (ndup, len(BANK)))
        return
    if args.callers:
        rows = callers(img)
        for ent, site, fixed in rows:
            print('0x%06X  <- calr at 0x%06X   %s' % (ent, site,
                  'lda XBC,0x00D75E / push XBC / push WA' if fixed else 'OTHER argument shape'))
        n = sum(1 for _, _, f in rows if f)
        print('\ncall sites: %d   of which the fixed (chan, &0x00D75E) shape: %d' % (len(rows), n))
        print('routines with no calr site found: %s' %
              ([hex(e) for e in BANK if not calr_sites(img, e)] or 'none'))
        return
    if args.selftest:
        assert len(st) == 102, len(st)
        assert st[0][0] == 0xFA667E, hex(st[0][0])
        assert st[-1][0] == 0xFC7E68, hex(st[-1][0])   # ⚠ the LAST site, not only the first
        p, err = analyse(img, *st[-1])
        print('sites: %d   first 0x%06X   last 0x%06X' % (len(st), st[0][0], st[-1][0]))
        print('last site analyses to: %r (err=%r)' % (p, err))
        # and one site whose answer is quoted in the findings note
        p2, e2 = analyse(img, 0xFACE74, 'XIX')
        assert p2 == [('chan+0x0400', 'arg1->0x0E')], p2
        print('0xFACE74 -> %r  OK' % (p2,))
        # the bank: 17 routines laid end to end with no gap
        ends = BANK[1:] + [BANK_END]
        assert all(b < e for b, e in zip(BANK, ends))
        assert BANK_END - BANK[0] == 731, BANK_END - BANK[0]
        # ⚠ the LAST routine too, not only the first
        pl, el = analyse(img, 0xFAD12F, 'XIX')
        assert pl == [('<0x0201>', 'chan')], pl
        print('bank 0x%06X..0x%06X = %d bytes, %d routines; last routine writes %r'
              % (BANK[0], BANK_END - 1, BANK_END - BANK[0], len(BANK), pl))
        rows = callers(img)
        nfix = sum(1 for _, _, f in rows if f)
        print('call sites %d, fixed (chan, &0x00D75E) shape %d' % (len(rows), nfix))
        assert len(rows) == 25 and nfix == 23, (len(rows), nfix)
        f = slots(img, quiet=True)
        print('slot identity (--slots): %d failures over %d bound-checked routines'
              % (f, len(SPLIT_ROUTINES)))
        assert f == 0, f
        d = dev104(img)
        assert d == 0, d
        return
    nmatch = 0
    rows = []
    for addr, ptr in st:
        pairs, err = analyse(img, addr, ptr)
        if err:
            rows.append((addr, ptr, None, err))
        else:
            nmatch += 1
            rows.append((addr, ptr, pairs, None))
    if args.unmatched:
        for addr, ptr, pairs, err in rows:
            if err:
                print('0x%06X  ld %s,0x0010C000   -- %s' % (addr, ptr, err))
        print('\nUNMATCHED: %d of %d sites' % (len(st) - nmatch, len(st)))
        return
    for addr, ptr, pairs, err in rows:
        if err:
            print('0x%06X  ld %-3s   ?? %s' % (addr, ptr, err))
        else:
            for i, (r, v) in enumerate(pairs):
                print('0x%06X  %-14s <- %s' % (addr if i == 0 else 0, r, v)
                      if i == 0 else '          %-14s <- %s' % (r, v))
    print('\nSITES: %d   MATCHED: %d   UNMATCHED: %d' % (len(st), nmatch, len(st) - nmatch))
    # the parameter-block observation, printed as an observation
    consts = sorted({int(r.split('+0x')[1], 16) for _, _, p, e in rows if p
                     for r, _ in p if r.startswith('chan+0x')})
    print('\nDistinct `chan + K` constants: %d' % len(consts))
    print('  ' + ' '.join('0x%04X' % c for c in consts))
    print('  all divisible by 0x40: %s' % all(c % 0x40 == 0 for c in consts))
    print('  as K/0x40: ' + ' '.join(str(c // 0x40) for c in consts))


if __name__ == '__main__':
    main()
