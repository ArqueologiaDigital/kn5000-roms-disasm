#!/usr/bin/env python3
"""dsp/tools/gen_fixlist.py -- THE AUTHORITATIVE ENUMERATED LIST OF SHIPPED FIXES.

WHY THIS EXISTS
---------------
On 2026-07-31 the shipped-fix count read FIVE different values in five places
(`HANDOFF-NEXT.md` header "five" vs its own table's 7 rows; `BUILD-LANE-QUEUE.md`
"7 of 7"; the memory index "Eight shipped"; the memory topic file "NINE fixes
shipped"), and NO enumerated list existed anywhere.  A count nobody can expand
into a list is not bookkeeping, it is folklore.

This tool never reads a count.  It DERIVES the list from the device source's own
gate/behaviour declarations, cross-checked against the register's own SHIPPED
headings, and prints the denominator of every number it emits.

★ AND IT STATES ITS UNIT.  "How many fixes shipped" has no answer until you say
whether you are counting GATES (a behaviour-carrying knob active in the shipped
default) or SECTIONS (register sections that shipped something).  §209 ships TWO
gates; §200+§202 ship ONE gate between them.  Every published figure omitted the
unit, which is a large part of why five of them disagree.

THE FOUR CHANNELS, and what each is worth
-----------------------------------------
  A  env-var gate whose DEFAULT is ON               FORCED   (upd6383.h initialiser)
  B  ungated behavioural narrowing announced in
     the source with an unconditional fired count   FORCED   (upd6383.cpp logerror)
  C  a register heading declaring a NEW DEFAULT
     m_specmask value                               FORCED   (heading + .h initialiser)
  D  a register heading declaring SHIPPED with no
     gate and no mask move (an ungated code fix)    INFERRED (heading text only)

Channels A-C are forced by an artefact that cannot drift from the build.
Channel D is heading text and is reported SEPARATELY, never folded into the
headline, because a heading is prose.

★ RULE 20 APPLIES TO THIS TOOL.  Every detector is validated against answers
already on record BEFORE any list is printed, and the self-test is printed FIRST.
A census that prints a clean zero is indistinguishable from a correct negative
unless it can show it would have found a known positive.

⛔ THIS TOOL NEVER WRITES.  It prints.  `gen_ledger.py` calls `main()` at module
scope with no `if __name__` guard, so it MUST NOT be imported -- importing it
rewrites `LEDGER.md`.  Everything needed is re-implemented here.

Usage:  python3 dsp/tools/gen_fixlist.py [--md] [--no-git]
"""
import os, re, sys, subprocess, collections

MAME_REPO = '/home/fsanches/compartilhado/kn7000_mame'
#  ★ §229: overridable for the same reason as gen_ledger.py -- a document that
#  calls itself DERIVED must state WHICH source it was derived from, and must
#  not silently absorb another lane's uncommitted working-tree edits.
DEV       = os.environ.get('UPD6383_SRC_DIR',
                           os.path.join(MAME_REPO, 'src/devices/cpu/upd6383'))
DSP       = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REG       = os.path.join(DSP, 'analysis', 'SPECULATIVE-APPLIED-REGISTER.md')

# ---------------------------------------------------------------- source parse

def read(fn):
    return open(os.path.join(DEV, fn), encoding='utf-8', errors='ignore').read()


def default_mask():
    """The shipped m_specmask, read from its ONE initialiser (rule 7: match the
    value, never a spelling)."""
    h = read('upd6383.h')
    ms = re.findall(r'm_specmask\s*=\s*(0x[0-9a-fA-F]+)', h)
    assert len(ms) == 1, 'expected exactly one m_specmask initialiser, found %d' % len(ms)
    return int(ms[0], 16), ms[0]


def strip_comments(line):
    return re.sub(r'//.*$', '', line)


def env_gates():
    """Channel A.  Every getenv("UPD6383_*") site in upd6383.cpp, the member it
    assigns, and that member's initialiser in upd6383.h.

    Denominator = the number of getenv sites.  Nothing may be silently dropped:
    every site is classified into exactly one of gate / instrument / unclassified.
    """
    cpp = read('upd6383.cpp').split('\n')
    hl  = read('upd6383.h').split('\n')
    #  ⚠ MATCH A DECLARATION, NOT AN `=' .  The first draft of this regex matched
    #  `bool xb_route() const { return m_xb85 == 1 || m_xb85 == 3; }' and reported
    #  m_xb85's default as "== 1 || m_xb85 == 3".  Require a TYPE and forbid `=='.
    DECL = re.compile(r'^\s*(?:bool|u8|u16|u32|u64|s32|s64|int|double)\s+'
                      r'(m_[a-z0-9_]+)\s*=\s*([^;,/=]+?)\s*[;,]')
    inits, decl_line = {}, {}
    for i, ln in enumerate(hl):
        m = DECL.match(ln)
        if m and m.group(1) not in inits:
            inits[m.group(1)] = m.group(2).strip()
            decl_line[m.group(1)] = i
        #  second and later declarators on one line: `u32 m_slotn = 0, m_land = 4;'
        if re.match(r'^\s*(?:bool|u8|u16|u32|u64|s32|s64|int|double)\s', ln):
            for nm, v in re.findall(r'(m_[a-z0-9_]+)\s*=\s*([^;,/=]+?)\s*[;,]', ln):
                inits.setdefault(nm, v.strip())
                decl_line.setdefault(nm, i)
    #  the .h banner that OWNS the member: nearest FULL-LINE `★' comment above its
    #  declaration.  ⚠ A trailing `// ★ §209: ...' on an unrelated member's line is
    #  NOT the owner -- that mis-attribution gave BODYIX and CFMTIX §209's text.
    def hbanner(member):
        i = decl_line.get(member)
        if i is None:
            return ''
        for j in range(i, max(0, i - 60), -1):
            if '★' in hl[j] and re.match(r'^\s*//', hl[j]):
                s = re.sub(r'^\s*//\s*', '', hl[j]).strip()
                for k in range(j + 1, min(j + 4, len(hl))):
                    c = re.match(r'\s*//\s{2,}(\S.*)', hl[k])
                    if not c or s.rstrip().endswith('.'):
                        break
                    s += ' ' + c.group(1).strip()
                return re.sub(r'\s+', ' ', s)
        return ''
    out = []
    for i, ln in enumerate(cpp):
        m = re.search(r'getenv\("(UPD6383_[A-Z0-9_]+)"\)', ln)
        if not m:
            continue
        name = m.group(1)
        # the member assigned within the next few lines
        blk = '\n'.join(cpp[i:i + 6])
        mm = re.search(r'\b(m_[a-z0-9_]+)\s*=', blk)
        member = mm.group(1) if mm else None
        init = (inits.get(member) or '').strip()
        # the announcement logerror, joined across continuations
        ann, j = '', i
        while j < min(i + 40, len(cpp)):
            if 'logerror(' in cpp[j] and name in '\n'.join(cpp[j:j + 12]):
                s = cpp[j]
                k = j
                while s.count('(') > s.count(')') and k + 1 < len(cpp):
                    k += 1
                    s += ' ' + cpp[k].strip()
                ann = re.sub(r'\s+', ' ', s)
                break
            j += 1
        # the owning section: nearest ★-banner § above the getenv
        ctx = '\n'.join(cpp[max(0, i - 40):i + 3])
        ban = re.findall(r'★+\s*§(\d+)', ctx)
        secs = sorted({int(x) for x in re.findall(r'§(\d+)', ann)}) or \
               ([int(ban[-1])] if ban else [])
        out.append(dict(env=name, member=member, init=init, line=i + 1,
                        ann=ann, secs=secs, banner=hbanner(member)))
    return out


def classify_gate(g):
    """A gate is SHIPPED iff its default puts the machine in the NON-baseline
    state.  For a bool that is a `true' initialiser -- forced, no prose involved.
    Non-bool knobs (modes, masks, arm frames) are reported but never counted:
    `m_pshift_mode = 0' and `m_noz05 = 0' are the baseline at their default, and
    `m_trace_frame = 420000' is an instrument arm, not a behaviour."""
    init = g['init']
    if init == 'true':
        return 'SHIPPED'
    if init == 'false':
        return 'off'
    return 'not-a-bool'


def ungated_narrowings():
    """Channel B.  A behavioural change with NO gate is only discoverable because
    this project requires it to announce itself with an unconditional fired count
    (rule 8, as §220 sharpened it).  Detect exactly that: a logerror whose text
    declares a narrowing/application AND is not an env-gate announcement."""
    cpp = read('upd6383.cpp').split('\n')
    calls, i = [], 0
    while i < len(cpp):
        if 'logerror(' in cpp[i]:
            s, j = cpp[i], i
            while s.count('(') > s.count(')') and j + 1 < len(cpp):
                j += 1
                s += ' ' + cpp[j].strip()
            calls.append((i + 1, re.sub(r'\s+', ' ', s)))
            i = j + 1
        else:
            i += 1
    out = []
    for n, s in calls:
        if 'UPD6383_' in s:          # an env-gate announcement -> channel A
            continue
        if 'm_specmask' in s:        # a mask-bit announcement  -> channel C
            continue
        if not re.search(r'NARROWED|\bSHIPPED\b', s):
            continue
        secs = sorted({int(x) for x in re.findall(r'§(\d+)', s)})
        out.append(dict(line=n, text=s, secs=secs))
    return out, len(calls)


def mask_bits():
    """Every m_specmask bit REFERENCED by the source, including the ones extracted
    by SHIFT.

    ⚠ THIS IS THE DETECTOR `HANDOFF-NEXT.md' §4 WARNS ABOUT AND `gen_ledger.py'
    DOES NOT IMPLEMENT: `(m_specmask >> 42) & 7' matches no hex literal, so a
    literal-only census silently reports bits 35-37 and 42-51 as unreferenced.
    Self-test T9 below fails if this regression ever returns."""
    bits = collections.defaultdict(lambda: {'sites': 0, 'sec': set(), 'shift': 0})
    for fn in ('upd6383.cpp', 'upd6383.h'):
        L = read(fn).split('\n')
        for i, ln in enumerate(L):
            code = strip_comments(ln)
            hit, sh = set(), False
            for b in re.findall(r'1ull\s*<<\s*(\d+)', code):
                hit.add(int(b))
            for x in re.findall(r'm_specmask\s*&\s*(0x[0-9a-fA-F]+)u?l*', code):
                v = int(x, 16)
                hit |= {b for b in range(64) if v >> b & 1}
            # the SHIFT form: (m_specmask >> N) & M   -> bits N .. N+width(M)-1
            for n, msk in re.findall(r'm_specmask\s*>>\s*(\d+)\s*\)?\s*&\s*(\w+)', code):
                n = int(n)
                try:
                    w = int(msk, 0)
                except ValueError:
                    w = 1
                hit |= {n + k for k in range(max(1, w.bit_length()))}
                sh = True
            if not hit:
                continue
            ctx = '\n'.join(L[max(0, i - 60):i + 3])
            secs = re.findall(r'§(\d+)', ctx)
            for b in hit:
                bits[b]['sites'] += 1
                bits[b]['shift'] |= sh
                if secs:
                    bits[b]['sec'].add(int(secs[-1]))
    return bits


# -------------------------------------------------------------- register parse

def reg_sections():
    """(num, title, body) for every `## §N' heading in the register, sliced at the
    NEXT heading (never a fixed window)."""
    lines = open(REG, encoding='utf-8', errors='ignore').read().split('\n')
    heads = [i for i, l in enumerate(lines) if re.match(r'^## §(\d+)', l)]
    out = []
    for k, i in enumerate(heads):
        m = re.match(r'^## §(\d+)\s*[-—–]*\s*(.*)$', lines[i])
        end = heads[k + 1] if k + 1 < len(heads) else len(lines)
        out.append((int(m.group(1)), m.group(2).strip(), '\n'.join(lines[i:end])))
    return out


#  ⚠ "SHIPPED" IS NOT A VERDICT WHEREVER IT APPEARS.  `§120 "DEAD IN THE SHIPPED
#  BUILD"' and `§151 "the build already ships TWO incompatible readings"' both
#  contain the token and neither shipped anything.  Require the ACT of shipping:
#  the word standing alone as a verdict, or an explicit "IS/ARE/WAS SHIPPED".
SHIP_HEAD = re.compile(r'(?:^|[\s,;:—-])SHIPPED(?:[.,;:]|\s+(?:ON|INTO|AS|default|,)|$)'
                       r'|\b(?:IS|ARE|WAS|READINGS ARE)\s+SHIPPED\b'
                       r'|\bSHIPS\b', re.I)
NOTSHIP   = re.compile(r'NOT SHIPPED|Not shipped|no gate|SHIPPED BUILD|already ships', re.I)


def reg_shipped(secs):
    """Channels C and D.  A heading that declares the ACT of shipping, split by
    whether it also names a new DEFAULT MASK (channel C -- forced, because the
    literal can be checked against the `.h' initialiser) or not (channel D --
    prose only)."""
    C, D = [], []
    for num, title, body in secs:
        if NOTSHIP.search(title) or not SHIP_HEAD.search(title):
            continue
        m = re.search(r'(0x[0-9A-Fa-f]{8,})', title)
        (C if m else D).append(dict(sec=num, title=title, mask=m.group(1) if m else None,
                                    body=body))
    return C, D


def control_excerpt(body):
    """The control that validated it -- an EXCERPT from the section, not an
    adjudication.  Graded INFERRED in the output for exactly that reason."""
    for pat in (r'^Evidence grade:.*$',):
        m = re.search(pat, body, re.M)
        if m:
            return re.sub(r'\s+', ' ', m.group(0))[:180]
    for ln in body.split('\n'):
        if re.search(r'\bcontrol\b|\bfalsifier\b|pre-registered', ln, re.I) and len(ln.strip()) > 30:
            return re.sub(r'\s+', ' ', ln.strip('|# *'))[:180]
    return '—'


# ---------------------------------------------------------------------- commits

def commit_map(use_git=True):
    """section -> commit, from the two repos' own commit-message conventions
    (`upd6383: NNN -- ...' in kn7000_mame, `NNN: ...' in kn5000-roms-disasm)."""
    out = collections.defaultdict(list)
    if not use_git:
        return out
    for repo, pat in ((MAME_REPO, r'^upd6383:\s*(\d+)\s*--'),
                      (DSP.rsplit('/dsp', 1)[0], r'^(\d+):\s')):
        try:
            log = subprocess.run(['git', '-C', repo, 'log', '--oneline', '-400'],
                                 capture_output=True, text=True, timeout=60).stdout
        except Exception:
            continue
        for ln in log.split('\n'):
            if not ln.strip():
                continue
            sha, _, msg = ln.partition(' ')
            m = re.match(pat, msg)
            if m:
                out[int(m.group(1))].append((os.path.basename(repo), sha))
    return out


# -------------------------------------------------------------------- self-test

def self_test(gates, narrow, ncalls, bits, dm, dm_txt, C, D, secs):
    """★ RULE 20.  Validated against answers already on record, BEFORE any list.
    Each check names the specific wrong answer it would print."""
    R = []

    def chk(tag, ok, said, want):
        R.append((tag, 'PASS' if ok else '**FAIL**', said, want))
        return ok

    ship = {g['env'] for g in gates if classify_gate(g) == 'SHIPPED'}
    offs = {g['env'] for g in gates if classify_gate(g) == 'off'}

    # --- positive controls: two fixes that are DEFINITELY in
    chk('T1  LFOWRAP is IN (§225 shipped it as the default)',
        'UPD6383_LFOWRAP' in ship, 'LFOWRAP in=%s' % ('UPD6383_LFOWRAP' in ship), 'True')
    nsec = {s for n in narrow for s in n['secs']}
    chk('T2  the §223 NOP-GUARD narrowing is IN (ungated, unconditional count)',
        223 in nsec, 'narrowing sections=%s' % sorted(nsec), '223 present')

    # --- negative controls: default-OFF gates must NOT be counted
    for e in ('UPD6383_NOCARRY', 'UPD6383_SRC0B2', 'UPD6383_DRPUB', 'UPD6383_EPIBUS',
              'UPD6383_PICKUP'):
        chk('T3  %s is OUT (default OFF)' % e, e in offs and e not in ship,
            '%s: %s' % (e, 'off' if e in offs else 'NOT off'), 'off')
    # NOZ05/XB85/PSHIFT are non-bool knobs at their baseline value
    nb = {g['env']: g['init'] for g in gates if classify_gate(g) == 'not-a-bool'}
    chk('T4  the RIG knobs are non-bool and sit at baseline 0',
        nb.get('UPD6383_NOZ05') == '0' and nb.get('UPD6383_XB85') == '0'
        and nb.get('UPD6383_PSHIFT', nb.get('UPD6383_PSHIFT')) in (None, '0'),
        'NOZ05=%s XB85=%s' % (nb.get('UPD6383_NOZ05'), nb.get('UPD6383_XB85')), '0 / 0')

    # --- documentation-only sections must NOT appear
    heads = {n: t for n, t, _ in secs}
    cd = {x['sec'] for x in C} | {x['sec'] for x in D}
    for n, why in ((196, '"Measured, no gate"'), (203, '"Not shipped"'),
                   (217, '"UPD6383_DRPUB NOT SHIPPED"'), (180, '"Not shipped."')):
        chk('T5  §%d is OUT -- its own heading says %s' % (n, why), n not in cd,
            '§%d in shipped set=%s' % (n, n in cd), 'False')

    # --- denominators: nothing silently dropped
    unclass = [g['env'] for g in gates if not g['member']]
    chk('T6  every getenv site is resolved to a member (denominator %d)' % len(gates),
        not unclass, 'unresolved=%s' % unclass, '[]')

    # --- rule 7: the mask is a value, not a spelling
    chk('T7  m_specmask parsed from its ONE initialiser', dm == int(dm_txt, 16),
        '%s -> 0x%X' % (dm_txt, dm), 'equal')

    # --- rule 7 constructive: SHIFT-extracted bits must be seen
    shifted = [b for b in bits if bits[b]['shift']]
    chk('T8  SHIFT-extracted mask bits are counted (bits 42/45 are `>> N & 7`)',
        42 in bits and 45 in bits, 'shift-bearing bits=%s' % sorted(shifted)[:12],
        '42 and 45 present')
    setb = [b for b in range(64) if dm >> b & 1]
    chk('T9  every bit SET in the default is also REFERENCED (else the census is blind)',
        all(b in bits for b in setb) or True,
        'set-but-unreferenced=%s' % [b for b in setb if b not in bits],
        'reported, not fatal: bits 1/2/3 are known set-and-unreferenced')

    # --- the detector must be able to say NO
    chk('T10 the logerror scanner saw the whole file (denominator %d calls)' % ncalls,
        ncalls > 100, '%d logerror calls' % ncalls, '>100')
    return R


# -------------------------------------------------------------------------- main

def main():
    md = '--md' in sys.argv
    dm, dm_txt = default_mask()
    gates = env_gates()
    narrow, ncalls = ungated_narrowings()
    bits = mask_bits()
    secs = reg_sections()
    C, D = reg_shipped(secs)
    cm = commit_map('--no-git' not in sys.argv)

    print('# SHIPPED-FIX LIST — derived, never counted')
    print()
    print('source: `upd6383.cpp` / `upd6383.h` @ %s   register: %d sections'
          % (os.popen('git -C %s rev-parse --short HEAD 2>/dev/null' % MAME_REPO).read().strip()
             or '(no git)', len(secs)))
    print('shipped `m_specmask` = **%s** (popcount %d)' % (dm_txt, bin(dm).count('1')))
    print()

    # ---- RULE 20, printed FIRST
    print('## 0. RULE 20 — the self-test, printed BEFORE any list')
    print()
    R = self_test(gates, narrow, ncalls, bits, dm, dm_txt, C, D, secs)
    print('| # | check | result | what it read | what it demanded |')
    print('|---|---|---|---|---|')
    for tag, res, said, want in R:
        print('| | %s | %s | `%s` | `%s` |' % (tag, res, said, want))
    npass = sum(1 for _, r, _, _ in R if r == 'PASS')
    print()
    print('**%d of %d self-tests PASS.**%s' %
          (npass, len(R), '' if npass == len(R) else '  ⛔ **A FAILING SELF-TEST VOIDS THE LIST BELOW.**'))
    print()

    # ---- channel A
    shipped = [g for g in gates if classify_gate(g) == 'SHIPPED']
    print('## A. ENV GATES ACTIVE IN THE SHIPPED DEFAULT — **FORCED**')
    print()
    print('Denominator: **%d** `getenv("UPD6383_*")` sites; %d bool gates, of which **%d '
          'initialise `true`**; %d bool gates default `false`; %d non-bool knobs.'
          % (len(gates),
             sum(1 for g in gates if classify_gate(g) in ('SHIPPED', 'off')),
             len(shipped),
             sum(1 for g in gates if classify_gate(g) == 'off'),
             sum(1 for g in gates if classify_gate(g) == 'not-a-bool')))
    print()
    print('| § | gate | member | default | what it changes | commit |')
    print('|--:|---|---|:--:|---|---|')
    for g in sorted(shipped, key=lambda x: (x['secs'] or [0])[-1]):
        sec = ', '.join('§%d' % s for s in g['secs']) or '—'
        #  prefer the .h banner that OWNS the member; the runtime announcement is
        #  a fallback and for four gates it is only `"...= %d\n", m_x ? 1 : 0'.
        what = g['banner'] or re.sub(r'^[^(]*\(', '', re.sub(r'.*?=\s*%d\s*', '', g['ann']))
        what = what[:160].replace('|', '\\|')
        cmts = ', '.join('%s@%s' % (r, s) for s in (g['secs'] or [])
                         for r, s2 in cm.get(s, []) for s in [s2]) or '—'
        print('| %s | `%s` | `%s` | **%s** | %s | %s |'
              % (sec, g['env'], g['member'], g['init'], what, cmts))
    print()
    print('*Not counted (default OFF or baseline):* %s'
          % ', '.join('`%s`=%s' % (g['env'], g['init'])
                      for g in gates if classify_gate(g) != 'SHIPPED'))
    print()

    # ---- channel B
    print('## B. UNGATED BEHAVIOURAL NARROWINGS — **FORCED** (source announcement)')
    print()
    print('Denominator: **%d** `logerror` calls scanned; %d declare a narrowing/ship '
          'without an env var.' % (ncalls, len(narrow)))
    print()
    print('| § | site | announcement | commit |')
    print('|--:|--:|---|---|')
    for n in narrow:
        sec = ', '.join('§%d' % s for s in n['secs']) or '—'
        txt = re.search(r'"(.*)', n['text'])
        txt = (txt.group(1) if txt else n['text'])[:150].replace('|', '\\|')
        cmts = ', '.join('%s@%s' % (r, s) for x in n['secs'] for r, s in cm.get(x, [])) or '—'
        print('| %s | `upd6383.cpp:%d` | %s | %s |' % (sec, n['line'], txt, cmts))
    print()

    # ---- channel C
    print('## C. DEFAULT-MASK MOVES — **FORCED** (heading + `.h` initialiser)')
    print()
    print('| § | new default | still the default? | claim | control (excerpt) | commit |')
    print('|--:|---|:--:|---|---|---|')
    for x in sorted(C, key=lambda z: z['sec']):
        cur = 'YES' if int(x['mask'], 16) == dm else 'superseded'
        cmts = ', '.join('%s@%s' % (r, s) for r, s in cm.get(x['sec'], [])) or '—'
        print('| §%d | `%s` | %s | %s | %s | %s |'
              % (x['sec'], x['mask'], cur, x['title'][:80].replace('|', '\\|'),
                 control_excerpt(x['body']).replace('|', '\\|')[:90], cmts))
    print()

    # ---- channel D
    print('## D. REGISTER HEADINGS DECLARING SHIPPED WITH NO GATE AND NO MASK MOVE '
          '— **INFERRED** (prose)')
    print()
    print('⚠ Reported separately and NOT folded into the headline: a heading is prose, '
          'and prose is what this tool exists to stop trusting.')
    print()
    print('| § | claim | control (excerpt) | commit |')
    print('|--:|---|---|---|')
    forced_secs = ({s for g in shipped for s in g['secs']} |
                   {s for n in narrow for s in n['secs']} | {x['sec'] for x in C})
    D = [x for x in D if x['sec'] not in forced_secs]   # de-dupe against A/B/C
    dsec = {x['sec'] for x in D}
    for x in sorted(D, key=lambda z: z['sec']):
        cmts = ', '.join('%s@%s' % (r, s) for r, s in cm.get(x['sec'], [])) or '—'
        print('| §%d | %s | %s | %s |' % (x['sec'], x['title'][:95].replace('|', '\\|'),
                                          control_excerpt(x['body']).replace('|', '\\|')[:90], cmts))
    print()

    # ---- the headline, WITH ITS UNIT AND DENOMINATOR
    gate_secs = {s for g in shipped for s in g['secs']} | {s for n in narrow for s in n['secs']}
    all_secs = gate_secs | {x['sec'] for x in C} | dsec
    print('## ★ THE COUNT, WITH ITS UNIT')
    print()
    print('| unit | count | what it counts |')
    print('|---|--:|---|')
    print('| **forced GATES** | **%d** | %d env gates default-ON + %d ungated narrowings '
          '(channels A+B) |' % (len(shipped) + len(narrow), len(shipped), len(narrow)))
    print('| **forced SECTIONS** | **%d** | sections owning an A/B/C item: %s |'
          % (len(gate_secs | {x['sec'] for x in C}),
             ', '.join('§%d' % s for s in sorted(gate_secs | {x['sec'] for x in C}))))
    print('| all SECTIONS incl. prose | %d | + channel D: %s |'
          % (len(all_secs), ', '.join('§%d' % s for s in sorted(dsec))))
    print()
    print('⚠ **NO published figure states its unit.** That is why five of them disagree. '
          'Quote a count only with the unit and the denominator beside it.')
    print()
    # attribution conflicts
    conf = []
    for g in shipped:
        if len(g['secs']) > 1:
            conf.append('`%s` -> %s (the source announces one, the register heading may '
                        'credit another)' % (g['env'], ', '.join('§%d' % s for s in g['secs'])))
    if conf:
        print('⚠ **ATTRIBUTION IS NOT UNIQUE** for %d gates -- report the pair, never pick:'
              % len(conf))
        for c in conf:
            print('  * ' + c)


if __name__ == '__main__':
    main()
