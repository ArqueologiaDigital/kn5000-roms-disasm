#!/usr/bin/env python3
"""L2 aptness: does a routine NAMED for a return value actually return it?

Companion to l2_name_vs_fopen_mode.py.  docs/IS-IT-DONE.md scores L2 as
"coverage complete, aptness open" and says no script can judge aptness.  That is
true in general and false for particular classes: this measures a second class
where the name states a fact the code can be checked against.

GROUND TRUTH
  512 labels in the v10 tree end in a suffix that states, as a NUMBER, what the
  routine leaves in the return register -- *_ReturnZero, *_ReturnOne,
  *_ReturnFFFF, *_ReturnFalse, *_ReturnNull, *_ReturnTwo ...
  The return register is XHL.  That is not assumed, it is measured two ways:
    * 450 of the 512 labels open with `lds32 xhl, <imm>` and fall into a shared
      `ret` epilogue;
    * callers test it -- ui_widget_defs.s MainSendEvent does
          calr MainGetEvent / cps hl, 0 / jr z, ...
      i.e. it branches on HL to decide whether an event was dequeued.

METHOD  (mode `returns`, the default)
  Straight-line abstract interpretation of XHL from the label to the `ret`:
    ld/lds/lds32/ldw/ldb <hl>, <imm>   -> track that value
    xor <hl>, <hl>                     -> 0
    call/calr/swi, or any other
      instruction naming an HL register -> value becomes UNKNOWN
    unconditional jr/jrl/jp <label>    -> follow it (depth 24)
    a CONDITIONAL branch               -> the path forks; give up (UNMEASURED)
    ret/reti/retd                      -> report the tracked value
  Biased so anything unclear is UNMEASURED, never a flag.  Every flag is then
  read out of the ROM by hand before it is believed.

STANDING RESULT (v10, 2026-08-22)
  512 symbols in class, 488 measured, 484 confirmed, **4 CONTRADICTED**:
    MainGetEvent_ReturnZero      00FA9C6A   returns 1
    MainGetEvent_ReturnZeroAlt   00FA9C6F   returns 1
    PostEvent_ReturnZero         00FA9856   returns 1
    NakaWidget_ReturnZero        00FA4AFD   returns 0x01600006
  The first three are the SAME defect twice: in both event-queue routines the
  label sits on the `lds hl, 1` ("an event was dequeued / posted") path, while
  the genuine zero exit a few lines above is unnamed.  MainSendEvent branches on
  exactly that value, so a reader trusting the name reads the event loop
  backwards.  The fourth is a jump-table entry loading an event id, not zero.

CALIBRATION  (--calibrate) -- the check can distinguish values, not just spot 0:
  ReturnOne 27/27, ReturnFFFF 3/3, ReturnTwo 1/1, ReturnThree 1/1, ReturnFF 1/1
  all agree with their names, and of the 31 routines measured as returning
  non-zero the audit assigns 27 to correctly-named ones and flags 4.

WHAT IS NOT MEASURABLE, and why -- report these rather than let someone retry:
  * `_Return<digit>` (37 symbols).  The digit is AMBIGUOUS between "returns N"
    and "the Nth return path".  Read as a value it scores 12 agree / 7 disagree,
    and all 7 disagreements load zero -- so in this tree the trailing digit is a
    disambiguator, exactly like ReturnZero2 / ReturnAlt3.  Excluded from the
    measurement.  `--digits` shows the evidence.
  * "*Interrupt* routines no vector points to" (mode `vectors`).  The vector
    direction IS measurable and is clean: all 19 distinct targets of
    InterruptVectorTable @ 00FFFF00 are named *_HANDLER, 0 contradictions.  The
    REVERSE direction is not: the firmware's own widget-name table contains
    "SetInterruptTime" and "IvInterruptProc" (strings at 00EB085A / 00EB086C),
    so "Interrupt" is a KN5000 FEATURE name here as well as a CPU term, and no
    check on the token can tell the two senses apart.

  * mode `ownership` is a LEAD LIST, not a measurement: sub-labels whose name
    claims a parent routine other than the one they physically sit in.  164
    flags, precision NOT established (shared epilogues produce false ones).  It
    independently rediscovers the PostEvent/GetEvent defect above.

RUN
  python3 scripts/analysis/l2_name_vs_return_value.py [returns|vectors|ownership]
                                                     [--calibrate] [--digits]
Exits non-zero if any routine's name contradicts the value it returns.
"""
import os, re, sys, struct, argparse, collections

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
TREE = os.path.join(ROOT, "v10", "maincpu")
ROM  = os.path.join(ROOT, "original_ROMs", "kn5000_v10_program.rom")
SYMS = os.path.join(ROOT, "symbols", "maincpu_symbols_reference.txt")
BASE = 0xE00000

LABEL = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.]*):')
INSN  = re.compile(r'^\s+(\S+)\s*(.*)$')
IDENT = re.compile(r'\b([A-Za-z_][A-Za-z0-9_]*)\b')
BRANCH = re.compile(r'^(jr|jrl|jp|jp_24|jp_ind|djnz)')

CLAIMS = [
    (re.compile(r'Return(Zero|Null|False)[A-Za-z]*\d*$'), 0),
    (re.compile(r'ReturnOne\d*$'),   1),
    (re.compile(r'ReturnTwo\d*$'),   2),
    (re.compile(r'ReturnThree\d*$'), 3),
    (re.compile(r'ReturnFFFF\d*$'),  0xFFFF),
    (re.compile(r'ReturnFF\d*$'),    0xFF),
    (re.compile(r'ReturnMinus1$|ReturnNeg1$'), 0xFFFFFFFF),
]
DIGIT = re.compile(r'Return([1-9])$')

HLREG = re.compile(r'\b(xhl|hl|h|l)\b', re.I)
IMM   = re.compile(r'^(0x[0-9a-fA-F]+|-?\d+)$')
STORE = re.compile(r'^(st|push|cp|bit|jr|jp|jrl|nop|ei|di|scf|rcf|ccf|halt|res|'
                   r'set|chg|link|unlk|ldcf|stcf|tset|djnz)', re.I)
CLOBBER = ('call', 'calr', 'swi', 'trap')
UNCOND = re.compile(r'^(jr|jrl|jp)$', re.I)
RET    = re.compile(r'^(ret|reti|retd)$', re.I)
COND = set('z nz c nc pl mi ne eq ov nov pe po ge lt gt le uge ult ugt ule t f '
           'pe/ov po/nov'.split())
DATA_DIRECTIVES = ('.byte', '.ascii', '.asciz', '.word', '.long', '.short',
                   '.fill', '.space', '.incbin')


def sources():
    out = []
    for d, _, fs in os.walk(TREE):
        for f in sorted(fs):
            if f.endswith('.s'):
                out.append(os.path.join(d, f))
    return sorted(out)


def read(fn):
    # NEVER Path.read_text(): 65 files in this tree hold bytes > 127 in .ascii
    return open(fn, 'rb').read().decode('latin-1').split('\n')


def load():
    prog, index = [], {}
    for fn in sources():
        for ln, line in enumerate(read(fn), 1):
            m = LABEL.match(line)
            if m:
                index.setdefault(m.group(1), len(prog))
                prog.append(('L', m.group(1), fn, ln))
                continue
            m = INSN.match(line)
            if m:
                mn, ops = m.group(1).lower(), m.group(2).split(';')[0].strip()
                prog.append((('D' if mn.startswith('.') else 'I'),
                             (mn if mn.startswith('.') else (mn, ops)), fn, ln))
    return prog, index


def imm(tok):
    tok = tok.strip()
    return int(tok, 0) & 0xFFFFFFFF if IMM.match(tok) else None


def step(mn, ops, val):
    parts = [p.strip() for p in ops.split(',')] if ops else []
    if mn in ('ld', 'lds', 'lds32', 'ldw', 'ldb') and len(parts) == 2:
        if HLREG.fullmatch(parts[0] or ''):
            return imm(parts[1])
        if not HLREG.search(ops):
            return val
    if mn == 'xor' and len(parts) == 2 and parts[0] == parts[1] \
            and HLREG.fullmatch(parts[0]):
        return 0
    if mn in CLOBBER:
        return None
    if STORE.match(mn):
        return val
    if HLREG.search(ops):
        return None
    return val


def walk(prog, index, start, depth=24):
    i, val, seen, hops = start + 1, None, set(), 0
    while True:
        if i >= len(prog):
            return ('UNKNOWN', 'end-of-program')
        k = prog[i][0]
        if k == 'L':
            i += 1; continue
        if k == 'D':
            if prog[i][1] in DATA_DIRECTIVES:
                return ('UNKNOWN', 'falls into data ' + prog[i][1])
            i += 1; continue
        mn, ops = prog[i][1]
        if RET.fullmatch(mn):
            return ('VALUE', val) if val is not None \
                else ('UNKNOWN', 'value not an immediate')
        if UNCOND.fullmatch(mn):
            parts = [p.strip() for p in ops.split(',')]
            if len(parts) == 2 and parts[0].lower() in COND:
                return ('UNKNOWN', 'conditional branch %s %s' % (mn, ops))
            tgt = parts[-1]
            if not re.fullmatch(r'[A-Za-z_.][A-Za-z0-9_.]*', tgt):
                return ('UNKNOWN', 'computed/numeric jump ' + ops)
            if tgt not in index:
                return ('UNKNOWN', 'jump to unknown label ' + tgt)
            hops += 1
            if hops > depth or tgt in seen:
                return ('UNKNOWN', 'loop/too deep')
            seen.add(tgt); i = index[tgt] + 1; continue
        val = step(mn, ops, val)
        i += 1


def symbols():
    out = {}
    for l in open(SYMS, 'rb').read().decode('latin-1').split('\n'):
        p = l.split()
        if len(p) == 2 and not l.startswith('#'):
            try:
                out[p[0]] = int(p[1], 16)
            except ValueError:
                pass
    return out


def mode_returns(a):
    prog, index = load()
    syms = symbols()
    rows, drows = [], []
    for i, ent in enumerate(prog):
        if ent[0] != 'L' or 'Return' not in ent[1]:
            continue
        stem = re.sub(r'_0[xX][0-9A-Fa-f]+$', '', ent[1])
        claim = next((v for rx, v in CLAIMS if rx.search(stem)), None)
        dm = DIGIT.search(stem)
        if claim is None and not dm:
            continue
        st, got = walk(prog, index, i)
        row = (ent[1], ent[2], ent[3], claim if claim is not None
               else int(dm.group(1)), st, got)
        (rows if claim is not None else drows).append(row)

    def report(title, data):
        ok = [r for r in data if r[4] == 'VALUE' and r[5] == r[3]]
        bad = [r for r in data if r[4] == 'VALUE' and r[5] != r[3]]
        un = [r for r in data if r[4] != 'VALUE']
        print('== %s ==' % title)
        for lab, n in (('symbols in class', len(data)),
                       ('measured', len(ok) + len(bad)),
                       ('name CONFIRMED by code', len(ok)),
                       ('name CONTRADICTED', len(bad)),
                       ('unmeasured', len(un))):
            print('  %-26s %d' % (lab + ' ' + '.' * (26 - len(lab)), n))
        for n, f, ln, c, st, g in sorted(bad):
            print('    FLAG %-30s %08X  %s:%d  name says %s, code returns %s'
                  % (n, syms.get(n, 0), os.path.relpath(f, ROOT), ln,
                     hex(c), hex(g)))
        return ok, bad, un

    ok, bad, un = report('named return value (word-spelled)', rows)
    if a.calibrate:
        per = collections.defaultdict(lambda: [0, 0, 0])
        for n, f, l, c, st, g in rows:
            per[c][0 if (st == 'VALUE' and g == c) else
                   1 if st == 'VALUE' else 2] += 1
        print('  -- per claimed value: confirmed / contradicted / unmeasured')
        for c in sorted(per):
            print('     %-10s %4d %4d %4d' % (hex(c), *per[c]))
        print('  -- measured values seen across the class:')
        for v, k in collections.Counter(
                g for n, f, l, c, st, g in rows if st == 'VALUE').most_common():
            print('     %-12s %d' % (hex(v), k))
        print('  -- unmeasured reasons:')
        for w, k in collections.Counter(r[5] for r in un).most_common(8):
            print('     %-44s %d' % (w[:44], k))
    if a.digits:
        print()
        report('_ReturnN bare digit -- AMBIGUOUS, excluded from the measurement',
               drows)
        print('  (all disagreements load zero: the digit is a path'
              ' disambiguator, not a value)')
    return 1 if bad else 0


def mode_vectors(a):
    d = open(ROM, 'rb').read()
    syms = symbols()
    byaddr = {}
    for n, v in syms.items():
        byaddr.setdefault(v, []).append(n)   # addresses can carry ALIASES
    off = 0xFFFF00 - BASE
    tgts = collections.OrderedDict()
    for i in range(0, 0xB4, 4):
        v = struct.unpack('<I', d[off + i:off + i + 4])[0]
        tgts.setdefault(v, []).append(i // 4)
    bad = 0
    print('== InterruptVectorTable @ 00FFFF00: %d slots, %d distinct targets =='
          % (sum(len(x) for x in tgts.values()), len(tgts)))
    for v, slots in tgts.items():
        names = byaddr.get(v, ['<no symbol>'])
        n = '/'.join(sorted(names))
        claims = any(re.search(r'HANDLER|Handler|Irq|Isr|Interrupt|RESET|NMI|'
                               r'BOOT_ENTRY', x) for x in names)
        if not claims:
            bad += 1
        print('   %08X  slots %-26s %-32s %s'
              % (v, ','.join(map(str, slots))[:26], n,
                 'ok' if claims else 'NAME DOES NOT CLAIM INTERRUPT DUTY'))
    print('  contradictions: %d' % bad)
    return 1 if bad else 0


def mode_ownership(a):
    """LEAD LIST, not a measurement -- precision is not established."""
    calls, datar, labels, perfile = set(), set(), set(), []
    for fn in sources():
        items = []
        for ln, line in enumerate(read(fn), 1):
            m = LABEL.match(line)
            if m:
                items.append(('L', m.group(1), ln)); labels.add(m.group(1))
                continue
            m = INSN.match(line)
            if not m:
                continue
            mn, ops = m.group(1).lower(), m.group(2).split(';')[0]
            items.append(('I', mn, ln))
            ids = IDENT.findall(ops)
            if mn in ('call', 'calr'):
                calls.update(ids)
            elif mn.startswith('.') or not BRANCH.match(mn):
                datar.update(ids)
        perfile.append((fn, items))
    E = (calls | datar) & labels
    flags = 0
    print('== sub-label ownership LEADS (precision NOT established) ==')
    pairs = collections.Counter()
    for fn, items in perfile:
        cur = None
        for k, v, ln in items:
            if k != 'L':
                continue
            if v in E:
                cur = v; continue
            if cur is None:
                continue
            P = next((v[:i] for i in range(len(v) - 1, 0, -1)
                      if v[i] == '_' and v[:i] in E), None)
            if P is None or cur.startswith(P + '_') or P.startswith(cur + '_'):
                continue
            if P != cur:
                flags += 1; pairs[(P, cur)] += 1
    print('  entry set %d, flags %d, distinct (claimed, actual) pairs %d'
          % (len(E), flags, len(pairs)))
    for (P, R), k in pairs.most_common(20):
        print('    %-32s claimed, sits inside %-34s x%d' % (P, R, k))
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('mode', nargs='?', default='returns',
                    choices=['returns', 'vectors', 'ownership'])
    ap.add_argument('--calibrate', action='store_true')
    ap.add_argument('--digits', action='store_true')
    a = ap.parse_args()
    return {'returns': mode_returns, 'vectors': mode_vectors,
            'ownership': mode_ownership}[a.mode](a)


if __name__ == '__main__':
    sys.exit(main())
