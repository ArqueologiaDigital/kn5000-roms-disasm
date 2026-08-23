#!/usr/bin/env python3
"""L2 aptness, third harness: name-declared FACTS checked against the ROM.

Companion to l2_name_vs_return_value.py and l2_name_vs_fopen_mode.py.  Same
principle, new classes: a name that DECLARES a checkable fact can be tested.
General aptness is NOT measurable and is not attempted here.

Unlike the two earlier scripts this one reads the **ROM**, not the source text,
because in the v7 tree roughly half the code is still `.byte` blobs -- the
source cannot say whether `Foo_CheckBit6` tests bit 6, but the bytes can.
Every window is decoded by unidasm anchored AT the label address (never a
linear sweep of the whole image, which desyncs in data).

CLASSES  (each: what the name declares -> what would count as a violation)

  bits      `...Bit<N>...`      declares WHICH BIT.  Violation: the window
            holds bit-addressed instructions and none of them names bit N.
  bitop     `...ClearBit7...`   declares the OPERATION on that bit.  Violation:
            a Clear-name whose only op on bit N is `set`, and the reverse.
  stub      `...Stub/NoOp...`   declares the routine DOES NOTHING.  Violation:
            the body calls, stores, or branches.
  loop      `..._Loop`          declares the label is a LOOP HEAD.  Violation:
            nothing branches back to it.
  pad       `__pad_ADDR`        declares an address AND that the bytes are
            padding.  Violation: wrong address, or non-padding bytes.
  addrname  `..._JumpTo<ADDR>`  declares a transfer target.  Violation: no
            call/jump to that address in the routine.
  hexconst  `..._Check0x91`     declares a constant.  Violation: the constant
            appears nowhere in the window.
  lonret    `..._Ret`           declares the label is a bare return.
  jumptable `..._JumpTable`     declares a table of code entry points.

Bias: everything unclear is UNMEASURED, never a flag.  A window whose first
instruction decodes as `db` (invalid) is data -> UNMEASURED.  A linear decode
that reaches a `db` stops there.

CALIBRATION -- `--calibrate` runs the permutation null for the `bits` class:
every measured label is re-scored against a name it does NOT have (bit N+1
mod 8).  If the wrong-name flag rate is not far above the true-name rate the
criterion cannot fail and the class is worthless.  Report both numbers.

STANDING RESULT (v7, 2026-08-23) -- checked / contradicted
  align       23,202 /      7   labels proven to sit INSIDE an instruction
  erased      39,216 /    351   named labels on erased flash (v10: 296; the
                                v7-only excess is ONE run, 00FF2154..00FFFE7F,
                                56,620 bytes, carrying 67 `Sprintf_*` labels)
  bits (A)        88 /      7   all 7 = the bit is tested in the block ABOVE
  bitop           63 /      1
  stub            35 /      2   AccPatch_InitByteStub, DrumVoice_InlineStub
  loop         1,061 /     43
  pad            136 /    136   EVERY __pad_ADDR name is the v10 address,
                                uniformly +0x404; in v10 all 136 are correct
  addrname       178 /     10   7 of them correct in v10 -> same transplant
  hexconst     3,261 /      0   `_0xNN` = OFFSET FROM THE STEM, not a constant
                                (offset reading 3254/3254, imm reading 37/3081)
  lonret          41 /      1
  jumptable       97 /     50   real but noisy: `X_JumpTable` also names the
                                DISPATCHER, not only the table

RUN
  python3 scripts/analysis/l2_name_vs_code_facts.py [class ...] [--calibrate]
  python3 scripts/analysis/l2_name_vs_code_facts.py --tree v10 bits
  python3 scripts/analysis/l2_name_vs_code_facts.py --sweep bytes align
Exits non-zero if any class flags.
"""
import os, re, sys, argparse, subprocess, tempfile, collections
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
UNIDASM = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE = 0xE00000

TREES = {
    "v7":  (os.path.join(ROOT, "v7", "maincpu"),
            os.path.join(ROOT, "original_ROMs", "kn5000_v7_program.rom"),
            os.path.join(ROOT, "symbols", "maincpu_v7_symbols_reference.txt")),
    "v10": (os.path.join(ROOT, "v10", "maincpu"),
            os.path.join(ROOT, "original_ROMs", "kn5000_v10_program.rom"),
            os.path.join(ROOT, "symbols", "maincpu_v10_symbols_reference.txt")),
}

SWEEP = ['code']   # 'code' = only source-converted instruction spans;
                   # 'bytes' = also .byte blobs (undisassembled code)
LABEL = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.]*):')
INSN = re.compile(r'^\s+(\S+)\s*(.*)$')
DASM = re.compile(r'^([0-9a-f]+): ((?:[0-9a-f]{2} )+)\s*(\S+)\s*(.*)$')

# ---------------------------------------------------------------- environment

class Env:
    def __init__(self, tree):
        self.tdir, self.rompath, self.spath = TREES[tree]
        self.rom = open(self.rompath, 'rb').read()
        self.sym = {}
        for l in open(self.spath):
            if l.startswith('#') or not l.strip():
                continue
            p = l.split()
            if len(p) == 2:
                try:
                    self.sym[p[0]] = int(p[1], 16)
                except ValueError:
                    pass
        self.addrs = sorted(set(self.sym.values()))
        self.byaddr = collections.defaultdict(list)
        for n, a in self.sym.items():
            self.byaddr[a].append(n)
        self.files = []
        for d, _, fs in os.walk(self.tdir):
            for f in sorted(fs):
                if f.endswith('.s'):
                    self.files.append(os.path.join(d, f))
        self.files.sort()
        self._src = {}
        self._dcache = {}
        self.kind = self._label_kinds()
        self.anchors = self._anchors()
        self.code_spans = self._code_spans()
        self._bmap = None
        self._jt = None

    DATA_DIR = ('.byte', '.ascii', '.asciz', '.word', '.long', '.short',
                '.fill', '.space', '.zero', '.incbin', '.4byte', '.2byte')
    # `.byte` runs in this tree are mostly UNDISASSEMBLED CODE, so the sweep is
    # allowed into them; `.ascii`/`.incbin` are genuinely not code and a stray
    # decode there would manufacture boundaries inside strings.
    TEXT_DIR = ('.ascii', '.asciz', '.incbin', '.fill', '.space', '.zero')

    def _label_kinds(self):
        """'code' if the label is followed by a real instruction, 'blob' if by
        a data directive.  The v7 tree still carries whole routines as `.byte`
        runs; a label inside one is NOT known to sit on an instruction
        boundary, so every class below reports those as UNMEASURED instead of
        decoding from an arbitrary byte."""
        kinds = {}
        self.prevkind = {}
        for fn in self.files:
            pend, last = [], None
            for line in self.lines(fn):
                m = LABEL.match(line)
                if m:
                    pend.append(m.group(1)); continue
                m = INSN.match(line)
                if not m:
                    continue
                mn = m.group(1).lower()
                if mn.startswith('.'):
                    if mn in self.DATA_DIR:
                        k = 'blob'
                    else:
                        continue          # .align/.globl/.equ: not a boundary
                else:
                    k = 'code'
                for n in pend:
                    kinds[n] = k
                    self.prevkind[n] = last
                pend = []
                last = k
        return kinds

    def measurable(self, name, addr):
        """May a code-fact class decode from this label?

        YES if the boundary sweep proved the address is an instruction start,
        or if the SOURCE has converted instructions on BOTH sides of the label
        (so the assembler, which reproduces the ROM byte-for-byte, put it
        between two instructions).  A label on a blob/code SEAM is refused:
        `SeqBuf3_EnableTx_Stub` 00FDB54C follows `.byte 0x1d, 0x3b, 0x04` and
        is really the 4th byte of `call 0xff043b`.  Anything the sweep DISPROVED
        is refused outright.
        """
        a = self.aligned(addr)
        if a == 'YES':
            return True
        if a == 'NO':
            return False
        return (self.kind.get(name) == 'code'
                and self.prevkind.get(name) == 'code')

    def _code_spans(self):
        """Sorted [lo,hi) ranges the SOURCE converted to real instructions.

        The recursive sweep below must not wander into `.ascii` blobs: a
        mis-decoded byte pair reads as `jp <string>` and would then declare
        string bytes to be instruction boundaries.  Restricting the sweep to
        source-converted ranges makes that impossible.
        """
        spans = []
        for fn in self.files:
            seq = []          # (addr|None, kind) in file order
            pend, kinds = [], []
            for line in self.lines(fn):
                m = LABEL.match(line)
                if m:
                    pend.append(self.sym.get(m.group(1))); continue
                m = INSN.match(line)
                if not m:
                    continue
                mn = m.group(1).lower()
                if mn.startswith('.') and mn not in self.DATA_DIR:
                    continue
                k = ('text' if mn in self.TEXT_DIR
                     else 'blob') if mn.startswith('.') else 'code'
                for a in pend:
                    seq.append((a, k))
                pend = []
                if seq:
                    seq[-1] = (seq[-1][0], seq[-1][1]) if seq[-1][1] == k \
                        else (seq[-1][0], 'mixed')
                kinds.append(k)
            known = [(a, k) for a, k in seq if a is not None]
            for i, (a, k) in enumerate(known):
                hi = known[i + 1][0] if i + 1 < len(known) else None
                allow = ('code',) if SWEEP[0] == 'code' else ('code', 'blob')
                if k in allow and hi is not None and 0 < hi - a <= 4096:
                    spans.append((a, hi))
        spans.sort()
        out = []
        for lo, hi in spans:
            if out and lo <= out[-1][1]:
                out[-1] = (out[-1][0], max(out[-1][1], hi))
            else:
                out.append((lo, hi))
        return out

    def jt_targets(self):
        if self._jt is None:
            st, _ = (self._bmap if self._bmap is not None
                     else self._boundary_map())
            if self._bmap is None:
                self._bmap = (st, _)
            self._jt = set(self.addrs) | st
        return self._jt

    def in_code_span(self, a):
        import bisect
        i = bisect.bisect_right(self.code_spans, (a, float('inf'))) - 1
        return i >= 0 and self.code_spans[i][0] <= a < self.code_spans[i][1]

    def _anchors(self):
        """Addresses PROVEN to be instruction boundaries in the real program.

        A label used as the operand of a call/jr/jp in a converted instruction
        is an address the program transfers control to; since the tree
        assembles byte-identically to the ROM, that address is an instruction
        start.  Plus the reachability pass's own call-target dump and the
        interrupt vectors.  These anchor the alignment check below -- a label
        is only measured if a linear decode from a nearby anchor lands on it.
        """
        a = set()
        for fn in self.files:
            for line in self.lines(fn):
                m = INSN.match(line)
                if not m:
                    continue
                mn = m.group(1).lower().split('_')[0]
                if mn not in ('call', 'calr', 'jr', 'jrl', 'jp', 'djnz'):
                    continue
                for t in re.findall(r'[A-Za-z_.][A-Za-z0-9_.]*',
                                    m.group(2).split(';')[0]):
                    if t in self.sym:
                        a.add(self.sym[t])
        try:
            import json
            j = os.path.join(ROOT, 'analysis', 'v7-reachability',
                             'v7_call_targets.json')
            a.update(json.load(open(j))['targets'])
        except Exception:
            pass
        import struct as _s
        off = 0xFFFF00 - BASE
        if off + 0xB4 <= len(self.rom):
            for i in range(0, 0xB4, 4):
                a.add(_s.unpack_from('<I', self.rom, off + i)[0])
        return sorted(x for x in a if BASE <= x < BASE + len(self.rom))

    def _boundary_map(self):
        """Recursive-descent sweep from the anchors: decode each basic block,
        follow every branch/call target it names, and remember every
        instruction START and every byte strictly INSIDE an instruction.
        Never a blind linear sweep -- each block starts at an address the
        program provably transfers control to."""
        starts, interiors = set(), set()
        seen, front = set(), list(self.anchors)
        rounds = 0
        while front and rounds < 24:
            rounds += 1
            batch = [t for t in front if t not in seen
                     and BASE <= t < BASE + len(self.rom)
                     and self.in_code_span(t)]
            seen.update(batch)
            nxt = set()
            with ThreadPoolExecutor(max_workers=12) as ex:
                for ins in ex.map(lambda t: decode_block(self, t, 384), batch):
                    for ad, by, mn, ops in ins:
                        starts.add(ad)
                        for k in range(1, len(by.split())):
                            interiors.add(ad + k)
                        t = branch_target(mn, ops)
                        if t is not None:
                            nxt.add(t)
            front = list(nxt - seen)
        return starts, interiors

    def aligned(self, addr):
        """('YES'|'NO'|'CONFLICT'|'UNKNOWN')"""
        if self._bmap is None:
            self._bmap = self._boundary_map()
        st, it = self._bmap
        if addr in st and addr in it:
            return 'CONFLICT'
        if addr in st:
            return 'YES'
        if addr in it:
            return 'NO'
        return 'UNKNOWN'

    def lines(self, fn):
        # NEVER read_text(): 65 files in this tree hold bytes > 127
        if fn not in self._src:
            self._src[fn] = open(fn, 'rb').read().decode('latin-1').split('\n')
        return self._src[fn]

    def prev_sym(self, a):
        import bisect
        i = bisect.bisect_left(self.addrs, a)
        return self.addrs[i - 1] if i > 0 else None

    def next_sym(self, a):
        import bisect
        i = bisect.bisect_right(self.addrs, a)
        return self.addrs[i] if i < len(self.addrs) else BASE + len(self.rom)

    def bytes_at(self, a, n):
        o = a - BASE
        return self.rom[o:o + n]

    def decode(self, a, n):
        """unidasm anchored AT `a`; returns [(addr, bytehex, mn, ops)]."""
        key = (a, n)
        if key in self._dcache:
            return self._dcache[key]
        blob = self.bytes_at(a, n)
        with tempfile.NamedTemporaryFile(suffix='.bin', delete=False) as t:
            t.write(blob); tmp = t.name
        try:
            out = subprocess.run([UNIDASM, tmp, '-arch', 'tlcs900',
                                  '-basepc', hex(a)],
                                 capture_output=True, text=True).stdout
        finally:
            os.unlink(tmp)
        res = []
        for line in out.split('\n'):
            m = DASM.match(line)
            if m:
                res.append((int(m.group(1), 16), m.group(2).strip(),
                            m.group(3), m.group(4).strip()))
        self._dcache[key] = res
        return res


def decode_stop_at_db(env, a, n):
    """Linear decode from a, truncated at the first invalid (`db`) byte."""
    ins = env.decode(a, n)
    out = []
    for e in ins:
        if e[2] == 'db':
            return out, True          # desynced / data
        out.append(e)
    return out, False


TERM = ('ret', 'reti', 'retd', 'swi', 'halt')


def decode_block(env, a, n):
    """Decode from a to the end of the BASIC BLOCK: stop after a return or an
    unconditional transfer.  Past those the next byte need not be code, and
    running on is how a linear sweep manufactures phantom boundaries."""
    ins, desync = decode_stop_at_db(env, a, n)
    out = []
    for e in ins:
        out.append(e)
        mn, ops = e[2], e[3]
        if mn in TERM:
            break
        if mn in ('jr', 'jrl', 'jp') and (',' not in ops
                                          or ops.split(',')[0].strip() == 'T'):
            break
    return out

# ------------------------------------------------------------------ utilities

IMMRE = re.compile(r'0x[0-9a-fA-F]+|\b\d+\b')
BITOPS = ('bit', 'res', 'set', 'chg', 'tset', 'stcf', 'ldcf', 'andcf', 'orcf',
          'xorcf', 'rlc', 'rrc')
BRANCH = ('jr', 'jrl', 'jp', 'djnz', 'calr', 'call')


def first_imm(ops):
    m = IMMRE.match(ops.split(',')[0].strip())
    return int(m.group(0), 0) if m else None


def all_imms(ops):
    return [int(x, 0) for x in IMMRE.findall(ops)]


def branch_target(mn, ops):
    if mn not in BRANCH:
        return None
    t = ops.split(',')[-1].strip()
    if re.fullmatch(r'0x[0-9a-fA-F]+', t):
        return int(t, 16)
    return None


def pow2bit(v, width=8):
    m = (1 << width) - 1
    v &= m
    if v and (v & (v - 1)) == 0:
        return v.bit_length() - 1
    return None

# ==================================================================== classes

BITNAME = re.compile(r'Bit([0-9]|1[0-5])(?![0-9])')
# A qualifier immediately before the token moves the claim OFF this block:
# `..._AfterBit1Check` says the bit-1 test is ABOVE the label, `..._NoBit5`
# denies it.  Excluded, with the count reported, rather than counted as flags.
BIT_CONTEXT = re.compile(r'(After|Post|Before|Pre|No|Not|Non|Skip|Without|'
                         r'Else|Fail|Done|End|Exit|Ret)$')
BIT_WINDOW = 64


def bit_claims(name):
    """Every bit index the name asserts, and the ones a qualifier disowns."""
    claims, waived = [], []
    for m in BITNAME.finditer(name):
        (waived if BIT_CONTEXT.search(name[:m.start()]) else claims).append(
            int(m.group(1)))
    return claims, waived


DIRECT_BITOPS = ('bit', 'res', 'set', 'chg', 'tset', 'stcf', 'ldcf',
                 'andcf', 'orcf', 'xorcf')


def bits_of_window(ins, direct_only=False, first_only=False):
    """{bit index -> set of ops naming it} over decoded instructions.

    TIERS OF EVIDENCE, sharpest first:
      first_only  -- the label's FIRST instruction is bit-addressed.  The name
                     cannot be describing preceding context.
      direct_only -- any `bit/res/set/chg/tset/ldcf/stcf` in the block: the
                     operand IS a bit index, no inference.
      (neither)   -- also infers an index from and/or/xor with a power-of-two
                     immediate.  WEAKEST: `and A,0x7f` is a field mask, not a
                     bit-4 operation, and this tier mistakes the two.
    """
    out = collections.defaultdict(set)
    seq = ins[:1] if first_only else ins
    for _, _, mn, ops in seq:
        if mn in DIRECT_BITOPS:
            n = first_imm(ops)
            if n is not None and 0 <= n <= 15:
                out[n].add(mn)
        elif not direct_only and mn in ('and', 'or', 'xor'):
            im = all_imms(ops)
            if len(im) == 1:
                v = im[0]
                w = 16 if v > 0xFF else 8
                b = pow2bit(v, w)
                if b is not None:
                    out[b].add(mn + '/mask')
                b = pow2bit(~v, w)
                if b is not None:
                    out[b].add(mn + '/~mask')
    return out


def class_bits(env, a):
    """returns (state, payload) for every label carrying Bit<N>."""
    rows = []
    for name, addr in sorted(env.sym.items(), key=lambda kv: kv[1]):
        if not env.measurable(name, addr):
            continue
        claims, waived = bit_claims(name)
        if not claims:
            if waived:
                rows.append((name, addr, None, [], False))
            continue
        end = min(env.next_sym(addr), addr + BIT_WINDOW)
        ln = max(end - addr, 2)
        ins, desync = decode_stop_at_db(env, addr, min(ln, BIT_WINDOW))
        # the block PHYSICALLY ABOVE the label, for the off-by-one-block test
        prev = env.prev_sym(addr)
        pins = []
        if prev is not None and addr - prev <= BIT_WINDOW:
            pins, _ = decode_stop_at_db(env, prev, addr - prev)
        rows.append((name, addr, claims, ins, pins))
    return rows


def report_bits(env, rows, calibrate=False):
    waived = [r for r in rows if r[2] is None]
    rows = [r for r in rows if r[2] is not None]
    total_flags = 0
    print('  (%d further labels carry a Bit token behind a qualifier'
          ' -- After/No/Skip/... -- and are excluded)' % len(waived))
    for tier, kw in (('A  first instruction is bit-addressed',
                      dict(direct_only=True, first_only=True)),
                     ('B  any direct bit-addressed op in the block',
                      dict(direct_only=True)),
                     ('C  B + index inferred from and/or/xor masks',
                      dict())):
        ok = bad = un = 0
        flags, shifted = [], []
        per_reason = collections.Counter()
        for name, addr, claims, ins, pins in rows:
            if not ins:
                un += 1; per_reason['label decodes as data/db'] += 1; continue
            b = bits_of_window(ins, **kw)
            if not b:
                un += 1
                per_reason['no qualifying instruction at this tier'] += 1
                continue
            if any(c in b for c in claims):
                ok += 1
                continue
            bad += 1
            pb = bits_of_window(pins, direct_only=True) if pins else {}
            if any(c in pb for c in claims):
                shifted.append((name, addr, claims, sorted(b), sorted(pb), ins))
            else:
                flags.append((name, addr, claims, sorted(b), ins))
        print('== class `bits`: name declares WHICH BIT -- tier %s ==' % tier)
        print('  labels in class ............ %d' % len(rows))
        print('  measured ................... %d' % (ok + bad))
        print('  name CONFIRMED by code ..... %d' % ok)
        print('  name CONTRADICTED .......... %d  (%d of them = the bit is '
              'tested in the block ABOVE the label)' % (bad, len(shifted)))
        print('  unmeasured ................. %d' % un)
        for r, k in per_reason.most_common():
            print('      %-44s %d' % (r, k))
        for name, addr, claims, got, ins in flags:
            print('    FLAG %-46s %08X  name says bit %s, block names %s'
                  % (name, addr, claims, got))
            for ad, by, mn, ops in ins[:6]:
                print('           %06X  %-18s %s %s' % (ad, by, mn, ops))
        for name, addr, claims, got, pb, ins in shifted:
            print('    SHIFT %-45s %08X  name says bit %s; this block names'
                  ' %s, the block ABOVE names %s'
                  % (name, addr, claims, got, pb))
            for ad, by, mn, ops in ins[:3]:
                print('           %06X  %-18s %s %s' % (ad, by, mn, ops))
        if calibrate:
            nb = nok = 0
            for name, addr, claims, ins, pins in rows:
                if not ins:
                    continue
                b = bits_of_window(ins, **kw)
                if not b:
                    continue
                w = [(c + 1) % 8 for c in claims]
                if any(x in b for x in w):
                    nok += 1
                else:
                    nb += 1
            tot = nok + nb
            print('  -- permutation null (each label re-scored as bit N+1 mod 8):')
            print('     wrong-name CONTRADICTED %d/%d = %.1f%%   '
                  '(true-name %d/%d = %.1f%%)'
                  % (nb, tot, 100.0 * nb / max(tot, 1), bad, ok + bad,
                     100.0 * bad / max(ok + bad, 1)))
        print()
        if kw.get('first_only'):
            total_flags = len(flags)   # tier A, shift-class excluded, is the gate
    return total_flags


# ---------------------------------------------------------------- bit polarity
# ⚠ Set/Off/On/Enable/Disable/Toggle are KN5000 FEATURE words as well as bit
# operations -- `AccPedal_Bit2_Off` is the pedal-off path and only TESTS bit 2;
# `SndParam_SetResBit0_Via028100` is a set-OR-reset routine.  Reading a verb
# off those names measures nothing.  The class is therefore restricted to a
# verb IMMEDIATELY prefixed to the Bit token, and names carrying verbs from
# two different polarity groups are dropped (counted, not flagged).
VERB_TEST = r'(Check|Test|If|Is|Poll|Verify)'
VERB_SET = r'(Set|Mark|Raise|Assert)'
VERB_CLR = r'(Clear|Clr|Res|Reset|Unset)'
VERB_TGL = r'(Toggle|Flip|Invert)'
POL = [('test', VERB_TEST, {'bit', 'ldcf', 'stcf', 'tset', 'and/mask'}),
       ('set',  VERB_SET,  {'set', 'or/mask', 'tset'}),
       ('clear', VERB_CLR, {'res', 'and/~mask'}),
       ('toggle', VERB_TGL, {'chg', 'xor/mask'})]


def polarity_of(name, n):
    """The verb must be glued to the front of the Bit token, and unambiguous."""
    m = BITNAME.search(name)
    if not m:
        return None
    pre = name[:m.start()]
    hits = [k for k, rx, _ in POL if re.search(rx + r'$', pre)]
    if len(hits) != 1:
        return None
    groups = sum(1 for k, rx, _ in POL if re.search(rx, name))
    return hits[0] if groups == 1 else None


def report_bitop(env, rows):
    ok = bad = un = 0
    flags = []
    inclass = 0
    for name, addr, claims, ins, pins in rows:
        if claims is None:
            continue
        n = claims[0]
        kind = polarity_of(name, n)
        if kind is None:
            continue
        inclass += 1
        if not ins:
            un += 1; continue
        b = bits_of_window(ins)
        if n not in b:
            un += 1; continue
        want = dict((k, s) for k, _, s in POL)[kind]
        got = b[n]
        if got & want:
            ok += 1
        else:
            bad += 1
            flags.append((name, addr, n, kind, sorted(got), ins))
    print('== class `bitop`: name declares the OPERATION on that bit ==')
    print('  labels in class ............ %d' % inclass)
    print('  measured ................... %d' % (ok + bad))
    print('  name CONFIRMED by code ..... %d' % ok)
    print('  name CONTRADICTED .......... %d' % bad)
    print('  unmeasured ................. %d' % un)
    for name, addr, n, kind, got, ins in flags:
        print('    FLAG %-46s %08X  name says %s bit %d, block does %s'
              % (name, addr, kind, n, got))
        for ad, by, mn, ops in ins[:6]:
            print('           %06X  %-18s %s %s' % (ad, by, mn, ops))
    return len(flags)


# ------------------------------------------------------------------------ stub
STUBNAME = re.compile(r'(Stub|NoOp|Noop|NoOperation|DoNothing)', re.I)
TRIVIAL = {'nop', 'ret', 'reti', 'retd', 'ld', 'lds', 'ldw', 'ldb', 'xor',
           'ldx'}


def class_stub(env):
    ok = bad = un = 0
    flags = []
    n_in = 0
    for name, addr in sorted(env.sym.items(), key=lambda kv: kv[1]):
        if not STUBNAME.search(name) or not env.measurable(name, addr):
            continue
        n_in += 1
        ins, desync = decode_stop_at_db(env, addr, 32)
        if not ins:
            un += 1; continue
        body, saw_ret = [], False
        for e in ins:
            body.append(e)
            if e[2] in ('ret', 'reti', 'retd'):
                saw_ret = True; break
        if not saw_ret:
            un += 1; continue
        heavy = [e for e in body
                 if e[2] not in TRIVIAL
                 or (e[2] == 'xor' and ',' in e[3]
                     and e[3].split(',')[0] != e[3].split(',')[1])]
        if heavy:
            bad += 1; flags.append((name, addr, body, heavy))
        else:
            ok += 1
    print('== class `stub`: name declares the routine DOES NOTHING ==')
    print('  labels in class ............ %d' % n_in)
    print('  measured ................... %d' % (ok + bad))
    print('  name CONFIRMED by code ..... %d' % ok)
    print('  name CONTRADICTED .......... %d' % bad)
    print('  unmeasured ................. %d' % un)
    for name, addr, body, heavy in flags:
        print('    FLAG %-46s %08X  body is not inert' % (name, addr))
        for ad, by, mn, ops in body[:8]:
            print('           %06X  %-18s %s %s' % (ad, by, mn, ops))
    return len(flags)


# ------------------------------------------------------------------------ loop
# The claim "this label is a loop HEAD" is only made by names whose LAST
# underscore segment is the Loop token.  `MainLoop_AfterInput` puts Loop in the
# module prefix and claims nothing about the label; `..._LoopEnd`, `_LoopBody`,
# `_LoopHelper` name a different point of the loop.  Both are dropped -- a
# criterion that flags them measures the name grammar, not the code.
LOOPNAME = re.compile(r'Loop')
LOOP_NOTHEAD = re.compile(
    r'(End|Exit|Done|Break|Ret|Return|Helper|Init|Setup|Entry|Table|Data|'
    r'Count|Cnt|Ptr|Var|Flag|Idx|Index|Body|Next|Skip|After|Post|Pre|Cont|'
    r'Continue|Check|Alt|Fail|Err|Max|Limit|Base|Addr|Buf|State)')
LOOP_WINDOW = 1024


def is_loop_head_name(name):
    seg = name.split('_')[-1]
    return 'Loop' in seg and not LOOP_NOTHEAD.search(seg.replace('Loop', ''))


def class_loop(env):
    cands = []
    for name, addr in sorted(env.sym.items(), key=lambda kv: kv[1]):
        if not is_loop_head_name(name):
            continue
        if not env.measurable(name, addr):
            continue
        cands.append((name, addr))
    # source-level back references: same file, later line, branch operand
    srcref = collections.defaultdict(list)
    for fn in env.files:
        cur = []
        for ln, line in enumerate(env.lines(fn), 1):
            m = LABEL.match(line)
            if m:
                cur.append((m.group(1), ln)); continue
            m = INSN.match(line)
            if not m:
                continue
            mn, ops = m.group(1).lower(), m.group(2).split(';')[0]
            if mn.split('_')[0] in ('jr', 'jrl', 'jp', 'djnz'):
                for t in re.findall(r'[A-Za-z_.][A-Za-z0-9_.]*', ops):
                    srcref[t].append((fn, ln))
    labpos = {}
    for fn in env.files:
        for ln, line in enumerate(env.lines(fn), 1):
            m = LABEL.match(line)
            if m:
                labpos.setdefault(m.group(1), (fn, ln))

    def rom_backedge(name, addr):
        """Two readings, reported separately:
             HEAD    -- a branch targets this very label (it is the loop head);
             INSIDE  -- a back-edge B->T exists with T <= addr <= B, i.e. the
                        label lies within a loop's span.  Many `_Loop` labels
                        sit on the loop's LATCH (`VoiceAlloc_SortInnerLoop`
                        F3DC2D ends `jr ULE,0xf3dc14`, so the head is F3DC14);
                        those are inside a loop and only fail the HEAD reading.
        """
        ins, desync = decode_stop_at_db(env, addr, LOOP_WINDOW)
        head = inside = None
        for ad, by, mn, ops in ins:
            if mn in ('ret', 'reti', 'retd') and ops.strip() in ('', 'T'):
                break        # UNCONDITIONAL return only -- `ret NZ` (b0 fe) is
                             # a conditional exit and the loop may follow it.
                             # past the routine's first return, a loop below
                             # belongs to something else
            if mn not in ('jr', 'jrl', 'jp', 'djnz'):
                continue
            t = branch_target(mn, ops)
            if t is None or t >= ad:
                continue
            if t == addr:
                head = head or (ad, by, mn, ops)
            if t <= addr <= ad or addr <= t:
                inside = inside or (ad, by, mn, ops)
        st = 'DESYNC' if (desync and not inside) else 'OK'
        return (st, head, inside)

    res = []
    with ThreadPoolExecutor(max_workers=8) as ex:
        for (name, addr), r in zip(cands,
                                   ex.map(lambda c: rom_backedge(*c), cands)):
            res.append((name, addr, r))
    ok = bad = un = 0
    heads = 0
    flags = []
    for name, addr, (st, head, inside) in res:
        srcok = False
        if name in labpos:
            fn, ln = labpos[name]
            srcok = any(f == fn and l > ln for f, l in srcref.get(name, []))
        if head or srcok:
            heads += 1
        if inside or head or srcok:
            ok += 1
        elif st == 'DESYNC':
            un += 1
        else:
            bad += 1
            flags.append((name, addr,
                          [(f, l) for f, l in srcref.get(name, [])]))
    print('== class `loop`: name declares the label is a LOOP HEAD ==')
    print('  labels in class ............ %d' % len(cands))
    print('  measured ................... %d' % (ok + bad))
    print('  heads/precedes/inside a loop  %d' % ok)
    print('     of which the loop HEAD ... %d' % heads)
    print('  no loop at all (CONTRADICTED) %d' % bad)
    print('  unmeasured (decode desync) . %d' % un)
    for name, addr, refs in flags[:40]:
        print('    FLAG %-46s %08X  refs=%d' % (name, addr, len(refs)))
    if len(flags) > 40:
        print('    ... %d more' % (len(flags) - 40))
    return len(flags)


# ------------------------------------------------------------------------- pad
PADNAME = re.compile(r'^__pad_([0-9A-Fa-f]{4,8})$')


def class_pad(env):
    ok = bad = un = 0
    flags = []
    n_in = 0
    for name, addr in sorted(env.sym.items(), key=lambda kv: kv[1]):
        m = PADNAME.match(name)
        if not m:
            continue
        n_in += 1
        claimed = int(m.group(1), 16)
        end = env.next_sym(addr)
        blob = env.bytes_at(addr, min(end - addr, 64))
        problems = []
        if claimed != addr:
            problems.append('name says %06X, symbol is at %06X'
                            % (claimed, addr))
        junk = set(blob) - {0x00, 0xFF}
        if junk:
            problems.append('non-padding bytes %s'
                            % ' '.join('%02x' % b for b in sorted(junk)[:6]))
        if not blob:
            un += 1; continue
        if problems:
            bad += 1; flags.append((name, addr, blob, problems))
        else:
            ok += 1
    print('== class `pad`: name declares its own ADDRESS and that it is padding ==')
    print('  labels in class ............ %d' % n_in)
    print('  measured ................... %d' % (ok + bad))
    print('  name CONFIRMED by code ..... %d' % ok)
    print('  name CONTRADICTED .......... %d' % bad)
    print('  unmeasured ................. %d' % un)
    for name, addr, blob, problems in flags:
        print('    FLAG %-30s %08X  %s' % (name, addr, '; '.join(problems)))
        print('           bytes %s' % ' '.join('%02x' % b for b in blob[:16]))
    return len(flags)


# -------------------------------------------------------------------- addrname
# The tree's convention is an UPPERCASE 6-digit tail: __pad_F61565,
# CDlikeSwTtl_JumpToFA9D58, SeqData_EF07A2.  Requiring uppercase and a
# non-hex-digit predecessor throws out `Slider_Case1E00066` (tail "E00066"
# preceded by the hex digit '1') and `..._Update64607` (lowercase 'e'), which
# are a case number and a decimal, not addresses.
ADDRTAIL = re.compile(r'(?<![0-9A-Fa-f])([0-9A-F]{6})$')
XFER = re.compile(r'(JumpTo|JmpTo|Jump|Via|Call|Goto|Branch|Tail|Dispatch)$')


def class_addrname(env):
    ok = bad = un = 0
    flags = []
    rows = []
    for name, addr in sorted(env.sym.items(), key=lambda kv: kv[1]):
        if name.startswith('__pad_') or name.startswith('.L'):
            continue
        m = ADDRTAIL.search(name)
        if not m:
            continue
        claimed = int(m.group(1), 16)
        if not (BASE <= claimed < BASE + len(env.rom)):
            continue
        stem = name[:m.start()].rstrip('_')
        rows.append((name, addr, claimed, bool(XFER.search(stem))))
    for name, addr, claimed, isxfer in rows:
        if isxfer and env.kind.get(name) != 'code':
            un += 1
        elif isxfer:
            ins, desync = decode_stop_at_db(
                env, addr, max(min(env.next_sym(addr) - addr, 128), 8))
            if not ins:
                un += 1; continue
            hit = [e for e in ins if branch_target(e[2], e[3]) == claimed]
            if hit:
                ok += 1
            else:
                bad += 1; flags.append((name, addr, claimed, 'transfer', ins))
        else:
            if addr == claimed:
                ok += 1
            else:
                bad += 1
                flags.append((name, addr, claimed, 'position', []))
    print('== class `addrname`: name declares an ADDRESS ==')
    print('  labels in class ............ %d' % len(rows))
    print('  measured ................... %d' % (ok + bad))
    print('  name CONFIRMED by code ..... %d' % ok)
    print('  name CONTRADICTED .......... %d' % bad)
    print('  unmeasured ................. %d' % un)
    for name, addr, claimed, kind, ins in flags:
        print('    FLAG %-46s %08X  name claims %06X (%s)'
              % (name, addr, claimed, kind))
        for ad, by, mn, ops in ins[:6]:
            print('           %06X  %-18s %s %s' % (ad, by, mn, ops))
    return len(flags)


# -------------------------------------------------------------------- hexconst
HEXC = re.compile(r'0[xX]([0-9A-Fa-f]{1,8})(?![0-9A-Fa-f])')


def class_hexconst(env):
    """`Foo_0xNN` -- what does the NN claim?

    Two readings, both testable, and the census settles which convention the
    tree actually uses:
      `imm`    the routine loads/compares the constant NN;
      `offset` the label sits NN bytes past the nearest preceding label whose
               name is its stem (`SOUND_DATA_DRUM_KITS_0x1A` 0x1A bytes after
               `SOUND_DATA_DRUM_KITS`).
    """
    rows = []
    for name, addr in sorted(env.sym.items(), key=lambda kv: kv[1]):
        if name.startswith('__pad_') or name.startswith('.L'):
            continue
        m = re.search(r'_0[xX]([0-9A-Fa-f]{1,8})$', name)
        if not m:
            continue
        rows.append((name, addr, int(m.group(1), 16), name[:m.start()]))
    r_imm = [0, 0, 0]
    r_off = [0, 0, 0]
    flags = []
    for name, addr, want, stem in rows:
        ins, desync = decode_stop_at_db(env, addr, 48)
        if not ins:
            r_imm[2] += 1
        else:
            seen = set()
            for _, _, mn, ops in ins:
                seen.update(all_imms(ops))
            r_imm[0 if want in seen else 1] += 1
        base = env.sym.get(stem)
        if base is None:
            r_off[2] += 1
        elif addr - base == want:
            r_off[0] += 1
        else:
            r_off[1] += 1
            flags.append((name, addr, want, base))
    print('== class `hexconst`: what does a trailing _0xNN claim? ==')
    print('  labels in class ............ %d' % len(rows))
    print('  reading `imm`    confirmed %d  contradicted %d  unmeasured %d'
          % tuple(r_imm))
    print('  reading `offset` confirmed %d  contradicted %d  unmeasured %d'
          % tuple(r_off))
    print('  -> the convention is `%s`'
          % ('offset' if r_off[0] > r_imm[0] else 'imm'))
    if r_off[0] > r_imm[0]:
        for name, addr, want, base in flags[:40]:
            print('    FLAG %-46s %08X  stem %08X, name says +0x%X, real +0x%X'
                  % (name, addr, base, want, addr - base))
        if len(flags) > 40:
            print('    ... %d more' % (len(flags) - 40))
        return len(flags)
    return 0


# ---------------------------------------------------------------------- lonret
LONRET = re.compile(r'(^|_)(Ret|Rts|ReturnOnly|JustRet|OnlyRet)[0-9]*$')
EPILOGUE_OK = {'pop', 'popw', 'lda', 'ld', 'lds', 'ldw', 'ldb', 'nop', 'ex',
               'xor', 'ei', 'di', 'normal', 'unlk', 'ldx', 'scf', 'rcf'}
GARBAGE = re.compile(r'^(swi|db)$')


def class_lonret(env):
    """`..._Ret` -- the label is the routine's RETURN PATH: a `ret` is reached
    with no call and no conditional branch in between.  (The stricter reading
    `a bare ret instruction` is wrong for this tree: 4 of its first flags are
    ordinary `pop XIZ / lda XSP,XSP+n / ret` epilogues, which the name fits.)"""
    ok = bad = un = 0
    flags = []
    rows = [(n, a) for n, a in sorted(env.sym.items(), key=lambda kv: kv[1])
            if LONRET.search(n) and env.kind.get(n) == 'code'
            and env.measurable(n, a)]
    for name, addr in rows:
        ins, desync = decode_stop_at_db(env, addr, 24)
        if not ins or any(GARBAGE.match(e[2]) for e in ins) \
                or any(e[3].endswith('0x000000') for e in ins):
            un += 1; continue        # window is data / the decode desynced
        verdict, why = None, ''
        for ad, by, mn, ops in ins[:10]:
            if mn in ('ret', 'reti', 'retd'):
                verdict = 'ok'; break
            if mn in ('call', 'calr'):
                verdict, why = 'bad', 'calls %s' % ops; break
            if mn in ('jr', 'jrl', 'jp', 'djnz') :
                verdict, why = 'bad', 'branches (%s %s)' % (mn, ops); break
            if mn not in EPILOGUE_OK:
                verdict, why = 'bad', 'does work (%s %s)' % (mn, ops); break
        if verdict == 'ok':
            ok += 1
        elif verdict == 'bad':
            bad += 1; flags.append((name, addr, why, ins))
        else:
            un += 1
    print('== class `lonret`: name declares the label is the RETURN PATH ==')
    print('  labels in class ............ %d' % len(rows))
    print('  measured ................... %d' % (ok + bad))
    print('  name CONFIRMED by code ..... %d' % ok)
    print('  name CONTRADICTED .......... %d' % bad)
    print('  unmeasured (data/desync) ... %d' % un)
    for name, addr, why, ins in flags:
        print('    FLAG %-46s %08X  %s' % (name, addr, why))
        for ad, by, mn, ops in ins[:4]:
            print('           %06X  %-18s %s %s' % (ad, by, mn, ops))
    return len(flags)


# ------------------------------------------------------------------- jumptable
JTNAME = re.compile(r'(Jump|Jmp|Dispatch|Vector|Handler|Func|Proc|Branch|Call)'
                    r'[A-Za-z]*_?(Table|Tbl)|(Table|Tbl)[A-Za-z]*$')
JT_STRICT = re.compile(r'(Jump|Jmp|Dispatch)[A-Za-z]*_?(Table|Tbl)')


def jt_interpretations(env, addr, span):
    """{scheme: n leading entries that resolve to a plausible code entry}.

    Entry-validity is the whole difficulty and it took three tries:
      1. "value in the ROM range"        -- null 778/778 = 100%: a 16-bit entry
         ORed with 0xE00000 always passes, so the criterion could not fail.
      2. "value is a known symbol or a swept boundary" -- flagged 220 labels
         whose entries are visibly good addresses in regions the sweep never
         reaches (half of v7 is still `.byte`).  Sound but hopelessly partial.
      3. (this one) "in the ROM range AND within 0x10000 of the first entry" --
         real tables are locally clustered.  Null on 1000 non-table labels:
         2.7%.  Falsifiable, and cheap.
    Schemes: LE32 / LE24 pointer arrays, `jp addr24` x4 and `call addr24 / ret`
    x5 thunk arrays (the KN5000 uses both -- AccDir_JumpTable 00F5BB3E is
    `1d 4a bb f5 0e` repeated).
    ⚠ `k >= 3` plus a short span between symbols under-counts: AccPlay_JumpTable
    00F71A26 is a genuine `jp x4` table but only 8 bytes fit before the next
    symbol, so it scores 2 and is flagged.
    """
    d = env.rom
    o = addr - BASE
    out = {}
    for nm, stride, op, voff in (('le32', 4, None, 0), ('le24', 3, None, 0),
                                 ('jp x4', 4, (0x1B, None), 1),
                                 ('call/ret x5', 5, (0x1D, 0x0E), 1)):
        k, first = 0, None
        while (k + 1) * stride <= span:
            p = o + k * stride
            if op:
                if d[p] != op[0]:
                    break
                if op[1] is not None and d[p + stride - 1] != op[1]:
                    break
                v = int.from_bytes(d[p + 1:p + 4], 'little')
            else:
                v = int.from_bytes(d[p:p + stride], 'little')
            if not (BASE <= v < BASE + len(d)):
                break
            if first is None:
                first = v
            if abs(v - first) > 0x10000:
                break
            k += 1
        out[nm] = k
    return out


def class_jumptable(env, strict=True):
    rows = []
    rx = JT_STRICT if strict else JTNAME
    for name, addr in sorted(env.sym.items(), key=lambda kv: kv[1]):
        # `X_Table_0x140` claims an OFFSET INTO X_Table, not that it is itself
        # a table -- that claim is the `hexconst` class's business.  Leaving
        # them in put 220 slices of one ExtDevice data blob on the flag list.
        if rx.search(name) and not re.search(r'_0[xX][0-9A-Fa-f]+$', name):
            rows.append((name, addr))
    ok = bad = un = 0
    flags = []
    for name, addr in rows:
        span = min(env.next_sym(addr) - addr, 256)
        if span < 6:
            un += 1; continue
        it = jt_interpretations(env, addr, span)
        best = max(it.items(), key=lambda kv: kv[1])
        if best[1] >= 3:
            ok += 1
        else:
            bad += 1; flags.append((name, addr, span, it))
    print('== class `jumptable`: name declares a table of CODE ENTRY POINTS ==')
    print('  labels in class ............ %d' % len(rows))
    print('  measured ................... %d' % (ok + bad))
    print('  name CONFIRMED by code ..... %d' % ok)
    print('  name CONTRADICTED .......... %d' % bad)
    print('  unmeasured ................. %d' % un)
    # NULL: the same procedure on labels whose name claims NO table.  If they
    # confirm as often, the criterion cannot fail and the class is worthless.
    import random
    pool = [(n, a) for n, a in env.sym.items() if not JTNAME.search(n)]
    random.Random(7).shuffle(pool)
    nok = nbad = 0
    for name, addr in pool[:1000]:
        span = min(env.next_sym(addr) - addr, 256)
        if span < 6:
            continue
        it = jt_interpretations(env, addr, span)
        if max(it.values()) >= 3:
            nok += 1
        else:
            nbad += 1
    print('  -- null on 1000 non-table labels: %d/%d = %.1f%% would "confirm"'
          % (nok, nok + nbad, 100.0 * nok / max(nok + nbad, 1)))
    for name, addr, span, it in flags:
        blob = env.bytes_at(addr, min(span, 16))
        print('    FLAG %-46s %08X  span %d  best=%s'
              % (name, addr, span, sorted(it.items(), key=lambda kv: -kv[1])[0]))
        print('           bytes %s' % ' '.join('%02x' % b for b in blob))
    return len(flags)


def class_erased(env):
    """A NAME asserts there is something at the address.  Erased flash (a run
    of 0xFF) is nothing.  Decision: the bytes from the label to the next symbol
    (capped at 64) are >= 4 bytes and all 0xFF.
    Violation: `Sprintf_DivByTen_Loop` 00FF2219 -- v7 holds 0xFF from 00FF2154
    to 00FFFE7F (56,620 bytes); v10 holds real code there.
    """
    rows = []
    for name, addr in sorted(env.sym.items(), key=lambda kv: kv[1]):
        end = min(env.next_sym(addr), addr + 64)
        b = env.bytes_at(addr, end - addr)
        if len(b) >= 4 and set(b) == {0xFF}:
            rows.append((name, addr, len(b)))
    print('== class `erased`: the name asserts content; the flash is erased ==')
    print('  symbols in tree ............ %d' % len(env.sym))
    print('  on a >=4-byte 0xFF run ..... %d' % len(rows))
    runs = collections.Counter()
    for name, addr, n in rows:
        o = addr - BASE
        lo = o
        while lo > 0 and env.rom[lo - 1] == 0xFF:
            lo -= 1
        runs[BASE + lo] += 1
    print('  distinct erased runs ....... %d' % len(runs))
    for base, k in runs.most_common(8):
        o = base - BASE
        hi = o
        while hi < len(env.rom) and env.rom[hi] == 0xFF:
            hi += 1
        print('     run %06X..%06X (%6d bytes) holds %d named labels'
              % (base, BASE + hi - 1, hi - o, k))
    for name, addr, n in rows[:15]:
        print('    FLAG %-46s %08X' % (name, addr))
    if len(rows) > 15:
        print('    ... %d more' % (len(rows) - 15))
    return len(rows)


def self_kind_skip(env, name):
    return env.kind.get(name) == 'text'


def class_align(env):
    """Is the label placed at an instruction boundary at all?

    Not aptness -- but it GATES aptness: a label a byte inside an instruction
    makes every other class here decode garbage from it.  `NO` is proven: a
    linear decode from an address the program provably branches to steps over
    the label.
    """
    c = collections.Counter()
    bad = []
    for name, addr in sorted(env.sym.items(), key=lambda kv: kv[1]):
        if env.kind.get(name) != 'code':
            continue
        v = env.aligned(addr)
        c[v] += 1
        if v in ('NO', 'CONFLICT'):
            bad.append((name, addr, v))
    print('== class `align`: the label sits on an instruction boundary ==')
    print('  code-kind labels ........... %d' % sum(c.values()))
    print('  boundary PROVEN (YES) ...... %d' % c['YES'])
    print('  boundary DISPROVEN (NO) .... %d' % c['NO'])
    print('  conflicting decodes ........ %d' % c['CONFLICT'])
    print('  not reached from an anchor . %d' % c['UNKNOWN'])
    for name, addr, v in bad[:40]:
        ins, _ = decode_stop_at_db(env, addr, 12)
        print('    FLAG %-46s %08X  %s' % (name, addr, v))
        for ad, by, mn, ops in ins[:2]:
            print('           %06X  %-18s %s %s' % (ad, by, mn, ops))
    if len(bad) > 40:
        print('    ... %d more' % (len(bad) - 40))
    return len(bad)


# ====================================================================== driver

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('classes', nargs='*',
                    default=['align', 'erased', 'bits', 'bitop', 'stub', 'loop', 'pad',
                             'addrname', 'hexconst', 'lonret', 'jumptable'])
    ap.add_argument('--tree', default='v7', choices=list(TREES))
    ap.add_argument('--calibrate', action='store_true')
    ap.add_argument('--loose-jt', action='store_true')
    ap.add_argument('--sweep', default='code', choices=['code', 'bytes'],
                    help='how far the boundary sweep may follow branches')
    a = ap.parse_args()
    SWEEP[0] = a.sweep
    env = Env(a.tree)
    print('tree=%s  rom=%s  symbols=%d\n'
          % (a.tree, os.path.basename(env.rompath), len(env.sym)))
    total = 0
    bitrows = None
    for c in a.classes:
        if c in ('bits', 'bitop') and bitrows is None:
            bitrows = class_bits(env, a)
        if c == 'bits':
            total += report_bits(env, bitrows, a.calibrate)
        elif c == 'bitop':
            total += report_bitop(env, bitrows)
        elif c == 'stub':
            total += class_stub(env)
        elif c == 'loop':
            total += class_loop(env)
        elif c == 'pad':
            total += class_pad(env)
        elif c == 'addrname':
            total += class_addrname(env)
        elif c == 'hexconst':
            total += class_hexconst(env)
        elif c == 'lonret':
            total += class_lonret(env)
        elif c == 'erased':
            total += class_erased(env)
        elif c == 'align':
            total += class_align(env)
        elif c == 'jumptable':
            total += class_jumptable(env, strict=not a.loose_jt)
        print()
    print('TOTAL FLAGS: %d' % total)
    return 1 if total else 0


if __name__ == '__main__':
    sys.exit(main())
