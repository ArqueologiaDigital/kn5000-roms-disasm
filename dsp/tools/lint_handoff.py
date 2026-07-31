#!/usr/bin/env python3
"""dsp/tools/lint_handoff.py -- fail when a HANDOVER document quotes a value that
disagrees with the source or with the current logs.

★★ SCOPE IS THE WHOLE POINT, AND IT IS DELIBERATELY NARROW.

    LINTED:  analysis/HANDOFF-NEXT.md
             analysis/LEDGER.md          (+ its hand-curated head, LEDGER-HEAD.md)
             analysis/BUILD-LANE-QUEUE.md

    ⛔ NEVER LINTED:  analysis/SPECULATIVE-APPLIED-REGISTER.md

The register is an APPEND-ONLY LABORATORY NOTEBOOK.  Its older sections quote
values that later sections retract IN PLACE, and that is correct behaviour -- §130
*should* still read `default 0x46A39B440F', because that was the default when §130
ran.  Linting it would produce hundreds of findings, every one of them wrong, and
the linter would be turned off within a day.  The three files above are different:
they are HANDOVERS.  A handover exists to be believed without reading the tail, so
a stale number in one is a defect by definition.

⚠ This scoping is the review's own kill-condition for the tool.  Do not widen it.

WHAT IT CHECKS
--------------
  C1  MASK LITERALS      a hex mask quoted with a CURRENCY marker must equal
                         `upd6383.h`'s single `m_specmask' initialiser
  C2  CLIP RATES         a clip percentage quoted in the present tense must be
                         one the CURRENT SHIPPED-DEFAULT log actually prints
  C3  GATE DEFAULTS      "`UPD6383_X` ... DEFAULT OFF/ON" must match `upd6383.h'
  C4  RULES INDEX        every `rule N' cited must be DEFINED in LEDGER TIER 0c
  C5  DECLARED COUNTS    "SHIPPED this session -- <word>" must equal the number of
                         rows in the table that follows it

SUPERSESSION IS RESPECTED.  A finding inside a heading marked ⛔ / SUPERSEDED /
prev- / RETRACTED is reported as INFO, not FAIL: those blocks are kept ON PURPOSE
so a closure stays legible, exactly like the register's tail-retraction rule.

★ RULE 20 APPLIES TO THIS TOOL TOO, AND IT CAUGHT THIS TOOL ONCE ALREADY.
Its first five controls were the five LIVE defects of 2026-07-31.  §228 applied
the patch plan that repaired them, and the self-test promptly fell from 8/8 to
3/8 -- because its known answers had been fixed.  ⇒ a tool whose controls are the
bugs it exists to find is validated exactly once, and is unvalidated from the
moment it succeeds.  The controls are now SYNTHETIC FIXTURES (see `DIRTY_FIXTURE'
/ `CLEAN_FIXTURE'), linted through the same `lint()' the report uses, and they are
TWO-SIDED: the repaired fixture must produce ZERO findings, or a linter that
flagged every line would score full marks.  The self-test is printed FIRST.
A linter that reports a clean zero is indistinguishable from a linter whose regex
never matched.

Exit status: 1 if any FAIL, else 0.
Usage:  python3 dsp/tools/lint_handoff.py [--all] [--quiet]
"""
import os, re, sys, gzip, glob, collections

DSP  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ANA  = os.path.join(DSP, 'analysis')
DATA = os.path.join(ANA, 'data')
DEV  = '/home/fsanches/compartilhado/kn7000_mame/src/devices/cpu/upd6383'

TARGETS = ['HANDOFF-NEXT.md', 'LEDGER.md', 'LEDGER-HEAD.md', 'BUILD-LANE-QUEUE.md']
FORBIDDEN = 'SPECULATIVE-APPLIED-REGISTER.md'      # ⛔ never lint this

HIST = re.compile(r'⛔|SUPERSEDED|prev-\d|RETRACTED|~~|DO NOT RE-OPEN|kept for its'
                  r'|Kept only|kept only|ANSWERED BY|RETRACTION', re.I)


# ------------------------------------------------------------------ the sources

def source_defaults():
    h = open(os.path.join(DEV, 'upd6383.h'), errors='ignore').read()
    c = open(os.path.join(DEV, 'upd6383.cpp'), errors='ignore').read()
    ms = re.findall(r'm_specmask\s*=\s*(0x[0-9a-fA-F]+)', h)
    assert len(ms) == 1, 'expected one m_specmask initialiser, found %d' % len(ms)
    mask = int(ms[0], 16)
    DECL = re.compile(r'^\s*(?:bool|u8|u16|u32|u64|s32|s64|int|double)\s+'
                      r'(m_[a-z0-9_]+)\s*=\s*([^;,/=]+?)\s*[;,]', re.M)
    inits = {}
    for nm, v in DECL.findall(h):
        inits.setdefault(nm, v.strip())
    gates = {}
    cl = c.split('\n')
    for i, ln in enumerate(cl):
        m = re.search(r'getenv\("(UPD6383_[A-Z0-9_]+)"\)', ln)
        if not m:
            continue
        mm = re.search(r'\b(m_[a-z0-9_]+)\s*=', '\n'.join(cl[i:i + 6]))
        if mm:
            gates[m.group(1)] = inits.get(mm.group(1), '?')
    return mask, ms[0], gates


def current_clip_rates():
    """The clip rates the CURRENT SHIPPED-DEFAULT build prints.

    ★ The arm is identified FORCIBLY, not by filename: a log is a shipped-default
    log iff every gate it announces equals the source default AND it carries no
    `UPD6383_SPEC' mask override.  (`K_lfowrap_default_225' is named for the arm,
    but a filename is prose.)"""
    _, _, gates = source_defaults()
    want = {}
    for g, v in gates.items():
        if v == 'true':
            want[g] = 1
        elif v == 'false':
            want[g] = 0
        elif re.fullmatch(r'\d+', v):
            want[g] = int(v)
    #  ★★ §229: ONLY GIT-TRACKED ARMS COUNT.  This function picks the NEWEST
    #  matching log by mtime, so before this guard the linter's single authority
    #  quantity -- "the current shipped-default clip rate" -- was whatever file
    #  had most recently APPEARED in a shared directory.  On 2026-07-31 that was
    #  `E_229.log.gz', dropped mid-pass by a concurrent lane whose device is not
    #  in any commit; the linter graded four documents against an arm nobody
    #  could reproduce, and said PASS.  An untracked log is not evidence.
    #  `UPD6383_LINT_UNTRACKED=1' restores the old behaviour for a live bisect.
    tracked = None
    if os.environ.get('UPD6383_LINT_UNTRACKED') != '1':
        try:
            out = os.popen('git -C %s ls-files -- analysis/data 2>/dev/null'
                           % os.path.join(DSP)).read().split('\n')
            tracked = {os.path.basename(x) for x in out if x.strip()}
        except Exception:
            tracked = None
    best, rates, arms = None, set(), []
    for p in sorted(glob.glob(os.path.join(DATA, '*.log.gz'))):
        if tracked is not None and os.path.basename(p) not in tracked:
            continue                                   # untracked -> not evidence
        try:
            t = gzip.open(p, 'rt', errors='ignore').read()
        except Exception:
            continue
        if 'bisection mask UPD6383_SPEC' in t:
            continue                                   # a mask override -> not default
        ok = True
        for g, v in re.findall(r'(UPD6383_[A-Z0-9_]+) = (\d+)\s', t):
            if g in want and int(v) != want[g]:
                ok = False
                break
        if not ok:
            continue
        m = re.search(r'TOTALS\s+quiet\s+\d+\s+clip\s*/\s*\d+\s+conversions\s*\(([\d.]+)\s*%\)'
                      r'.*?loud\s+\d+\s+clip\s*/\s*\d+\s+conversions\s*\(([\d.]+)\s*%\)', t)
        if not m:
            continue
        mt = os.path.getmtime(p)
        arms.append((mt, os.path.basename(p), m.group(1), m.group(2)))
        if best is None or mt > best[0]:
            best = (mt, os.path.basename(p), m.group(1), m.group(2))
    if best:
        rates = {best[2], best[3]}
    return best, rates, arms


def defined_rules():
    """The rule numbers DEFINED in LEDGER TIER 0c (an ordered numbered list under
    the `TIER 0c' heading), read from LEDGER.md and its hand-curated head."""
    out = set()
    for fn in ('LEDGER.md', 'LEDGER-HEAD.md'):
        p = os.path.join(ANA, fn)
        if not os.path.exists(p):
            continue
        t = open(p, errors='ignore').read()
        m = re.search(r'^## TIER 0c.*?$(.*?)(?=^## |\Z)', t, re.S | re.M)
        if not m:
            continue
        for n in re.findall(r'^\s{0,4}(\d{1,2})\.\s+\*\*', m.group(1), re.M):
            out.add(int(n))
    return out


WORDNUM = dict(one=1, two=2, three=3, four=4, five=5, six=6, seven=7, eight=8,
               nine=9, ten=10, eleven=11, twelve=12)


# ------------------------------------------------------------------ the checks

def lint(path, mask, mask_txt, gates, rates, ruleset):
    """Returns a list of (severity, check, line-no, predicate, said, want)."""
    name = os.path.basename(path)
    lines = open(path, errors='ignore').read().split('\n')
    out = []
    head = ''
    generated = False
    for i, ln in enumerate(lines, 1):
        if re.match(r'^#{1,6}\s', ln):
            head = ln
            #  ★ LEDGER.md = LEDGER-HEAD.md + TIERS 1-2 GENERATED FROM THE REGISTER.
            #  Everything from `## TIER 1' on is a register EXCERPT, and the register
            #  is exempt by design -- linting it here would smuggle the exemption's
            #  violation in through the generator.  Fix the register or the heading,
            #  never LEDGER.md, which cannot be hand-edited anyway.
            if name == 'LEDGER.md' and re.match(r'^## TIER 1\b', ln):
                generated = True
        hist = bool(HIST.search(ln) or HIST.search(head))
        sev = 'INFO' if (hist or generated) else 'FAIL'

        # ---- C1  mask literals quoted as CURRENT
        if re.search(r'Default is now|the default is|shipped default is|current default'
                     r'|m_specmask\s*(?:is|=)', ln, re.I):
            for lit in re.findall(r'0x[0-9A-Fa-f]{8,}', ln):
                if int(lit, 16) != mask:
                    out.append((sev, 'C1 mask', i,
                                'a mask quoted with a CURRENCY marker must equal '
                                "upd6383.h's sole m_specmask initialiser",
                                lit, mask_txt))

        # ---- C2  clip rates quoted in the present tense
        if re.search(r'\bclip|§S1|accumulator conversions', ln, re.I) and rates:
            transition = '->' in ln or '→' in ln or 'falls' in ln or 'fell' in ln
            for pct in re.findall(r'(\d+\.\d{2,3})\s*%', ln):
                if pct in rates:
                    continue
                if transition:
                    continue          # "5.303 % -> 4.924 %" states the move, correctly
                out.append((sev, 'C2 clip rate', i,
                            'a clip rate quoted in the present tense must be one the '
                            'current shipped-default log prints',
                            pct + ' %', ' / '.join(sorted(rates)) + ' %'))

        # ---- C3  gate defaults
        for g in re.findall(r'`?(UPD6383_[A-Z0-9_]+)`?', ln):
            if g not in gates:
                continue
            m = re.search(re.escape(g) + r'[^.\n]{0,60}?\bDEFAULT\s+(ON|OFF)\b', ln, re.I)
            if not m:
                continue
            said = m.group(1).upper()
            real = {'true': 'ON', 'false': 'OFF'}.get(gates[g],
                    'OFF' if gates[g] in ('0',) else 'ON')
            if said != real:
                out.append((sev, 'C3 gate default', i,
                            'a stated gate default must equal the .h initialiser',
                            '%s DEFAULT %s' % (g, said),
                            '%s = %s -> %s' % (g, gates[g], real)))

        # ---- C4  rule index completeness
        for n in re.findall(r'\b(?:standing\s+)?rules?\s+(\d{1,2})\b', ln, re.I):
            n = int(n)
            if n not in ruleset:
                out.append(('FAIL', 'C4 undefined rule', i,
                            'every rule cited by number must be DEFINED in LEDGER '
                            'TIER 0c',
                            'rule %d cited' % n,
                            'defined; TIER 0c currently holds %s'
                            % ('1..%d' % max(ruleset) if ruleset else 'nothing')))

        # ---- C5  declared counts vs the table that follows
        m = re.search(r'SHIPPED[^\n]*?—\s*(\w+)\b', ln)
        if m and m.group(1).lower() in WORDNUM:
            said = WORDNUM[m.group(1).lower()]
            rows = 0
            for j in range(i, min(i + 25, len(lines))):
                l2 = lines[j]
                if l2.startswith('|') and not re.match(r'^\|[\s:|-]+\|$', l2) \
                        and not re.match(r'^\|\s*§?\s*\|', l2):
                    if re.match(r'^\|\s*\*?\*?\s*(\d+|§\d+)', l2):
                        rows += 1
                elif rows and not l2.startswith('|'):
                    break
            if rows and rows != said:
                out.append((sev, 'C5 declared count', i,
                            'a declared count must equal the rows of the table it heads',
                            '"%s" = %d' % (m.group(1), said), '%d table rows' % rows))
    return [(name,) + o for o in out]


# ------------------------------------------------------------------- self-test

#  ★★★★ §228 REBUILT THIS FUNCTION, AND WHY IS THE POINT.
#
#  Its first four controls were the four LIVE defects of 2026-07-31.  §228 then
#  applied the patch plan that fixes all four -- and the linter's self-test
#  collapsed from 8/8 to 3/8, because its known answers had been REPAIRED.  A
#  tool whose controls are the bugs it exists to find is validated exactly once,
#  and is unvalidated from the moment it succeeds.
#
#  That is verbatim the failure mode of the rule this same pass DEFINED:
#  ⇒ TIER 0c rule 20 -- "a control must be a case whose answer is known
#    INDEPENDENTLY of the thing under test."
#
#  So the controls are now SYNTHETIC FIXTURES: a scratch document written here,
#  with one planted defect per check, linted through the SAME `lint()' the real
#  report uses.  They are two-sided -- a CLEAN fixture must produce ZERO
#  findings, or the checks are firing on everything and prove nothing.
DIRTY_FIXTURE = """\
# fixture — a synthetic handover document with one planted defect per check

* Default is now **`0x46A39B440F`**, `m_specmask` is u64.
* `§S1` measures **5.303 %** of all accumulator conversions clipping on the shipped default.
* `UPD6383_LFOWRAP` (DEFAULT OFF) — the wrap word's operand as a modulus.
* This follows from standing rule 97, which nothing defines.

### ★ SHIPPED this session — five, each with a control

| § | what | control |
|---|---|---|
| §188 | a | b |
| §197 | a | b |
| §201 | a | b |
| §202 | a | b |
| §204 | a | b |
| §208 | a | b |
| §209 | a | b |
"""

CLEAN_FIXTURE = """\
# fixture — the same document with every defect repaired

* The default is **`%s`**, `m_specmask` is u64.
* `§S1` measures **%s %%** quiet of all accumulator conversions clipping on the shipped default.
* `UPD6383_LFOWRAP` (DEFAULT ON) — the wrap word's operand as a modulus.
* This follows from standing rule 20, which TIER 0c defines.

### ★ SHIPPED this session — two, each with a control

| § | what | control |
|---|---|---|
| §188 | a | b |
| §197 | a | b |
"""


def _fixture_findings(text, mask, mask_txt, gates, rates, ruleset):
    """Lint a scratch document through the REAL lint(), and return its FAILs."""
    import tempfile
    d = tempfile.mkdtemp(prefix='lint_handoff_fixture_')
    p = os.path.join(d, 'FIXTURE.md')
    open(p, 'w').write(text)
    try:
        return [f for f in lint(p, mask, mask_txt, gates, rates, ruleset) if f[1] == 'FAIL']
    finally:
        try: os.remove(p); os.rmdir(d)
        except OSError: pass


def self_test(findings, rates, best, ruleset, mask_txt, mask, gates):
    """★ RULE 20.  Controls are SYNTHETIC and two-sided, so they stay valid after
    the live corpus is repaired.  Printed BEFORE the report."""
    R = []

    def chk(tag, ok, said, want):
        R.append((tag, 'PASS' if ok else '**FAIL**', str(said)[:90], want))

    quiet_rate = sorted(rates)[0] if rates else '4.924'
    D = _fixture_findings(DIRTY_FIXTURE, mask, mask_txt, gates, rates, ruleset)
    C = _fixture_findings(CLEAN_FIXTURE % (mask_txt, quiet_rate),
                          mask, mask_txt, gates, rates, ruleset)
    dck = lambda c: [f for f in D if f[2].startswith(c)]
    cck = lambda c: [f for f in C if f[2].startswith(c)]

    chk('T1  C1 fires on a planted stale mask literal (`0x46A39B440F`)',
        bool(dck('C1')), sorted(f[5] for f in dck('C1')) or 'nothing', 'at least one')
    chk('T2  C2 fires on a planted stale clip rate (`5.303 %`)',
        any(f[5].startswith('5.303') for f in dck('C2')),
        sorted(f[5] for f in dck('C2')) or 'nothing', '5.303 % flagged')
    chk('T3  C3 fires on a planted wrong gate default (LFOWRAP DEFAULT OFF)',
        bool(dck('C3')), sorted(f[5] for f in dck('C3')) or 'nothing', 'flagged')
    chk('T4  C4 fires on a planted undefined rule number (rule 97)',
        any('97' in f[5] for f in dck('C4')),
        sorted(f[5] for f in dck('C4')) or 'nothing', 'rule 97 flagged')
    chk('T5  C5 fires on a planted count ("five" over 7 rows)',
        bool(dck('C5')), sorted(f[5] + ' vs ' + f[6] for f in dck('C5')) or 'nothing',
        'flagged')
    #  ★ THE OTHER SIDE.  Without this, every check above is satisfied by a linter
    #  that flags EVERY line.
    chk('T6  ⚠ THE NEGATIVE SIDE: the REPAIRED fixture produces ZERO findings',
        not C, '%d findings: %s' % (len(C), sorted({f[2] for f in C})), '0')
    chk('T7  ⛔ the REGISTER is not linted (the tool\'s kill-condition)',
        FORBIDDEN not in TARGETS and not any(f[0] == FORBIDDEN for f in findings),
        'targets=%s' % TARGETS, 'register absent')
    chk('T8  the current clip rate came from a FORCIBLY-identified default arm',
        best is not None, best[1] if best else 'none found', 'a shipped-default log')
    chk('T9  the mask is read from the .h, not from a doc',
        mask_txt.lower().startswith('0x') and len(mask_txt) >= 10,
        mask_txt, "upd6383.h's initialiser")
    chk('T10 TIER 0c defines rules 19/20/21 (the §228 repair, and it CAN regress)',
        {19, 20, 21} <= set(ruleset),
        'TIER 0c defines 1..%d' % (max(ruleset) if ruleset else 0),
        '19, 20 and 21 all present')
    return R


def main():
    quiet = '--quiet' in sys.argv
    mask, mask_txt, gates = source_defaults()
    best, rates, arms = current_clip_rates()
    ruleset = defined_rules()

    findings = []
    for t in TARGETS:
        p = os.path.join(ANA, t)
        if os.path.exists(p):
            findings += lint(p, mask, mask_txt, gates, rates, ruleset)

    print('# lint_handoff — handover documents vs the source and the current logs')
    print()
    print('scope: %s' % ', '.join('`%s`' % t for t in TARGETS))
    print('⛔ NOT linted: `%s` (append-only notebook; later sections retract earlier '
          'ones in place)' % FORBIDDEN)
    print('source mask `%s` · TIER 0c defines rules %s · current shipped-default arm: %s'
          % (mask_txt,
             '%d..%d' % (min(ruleset), max(ruleset)) if ruleset else 'NONE',
             ('`%s` (%s %% quiet / %s %% loud)' % (best[1], best[2], best[3])) if best
             else '**NONE FOUND**'))
    print()
    print('## 0. RULE 20 — the self-test, printed BEFORE the report')
    print()
    R = self_test(findings, rates, best, ruleset, mask_txt, mask, gates)
    print('| check | result | what it read | what it demanded |')
    print('|---|---|---|---|')
    for tag, res, said, want in R:
        print('| %s | %s | `%s` | %s |' % (tag, res, said, want))
    npass = sum(1 for _, r, _, _ in R if r == 'PASS')
    print()
    print('**%d of %d self-tests PASS.**' % (npass, len(R)))
    print()

    print('## 1. FINDINGS')
    print()
    fails = [f for f in findings if f[1] == 'FAIL']
    infos = [f for f in findings if f[1] == 'INFO']
    print('**%d FAIL**, %d INFO (inside a ⛔/SUPERSEDED heading, kept on purpose).'
          % (len(fails), len(infos)))
    print()
    #  GROUP: 21 of the 25 findings are one fact ("rule 21 is undefined") repeated
    #  once per citation.  Collapse to (file, check, said) with the line list, so
    #  the report counts DEFECTS and the lines stay quotable.
    print('| sev | file | check | said | source says | lines (n) |')
    print('|---|---|---|---|---|---|')
    grp = collections.OrderedDict()
    for f in fails + ([] if quiet else infos):
        grp.setdefault((f[1], f[0], f[2], f[5], f[6]), []).append(f[3])
    for (sev, fn, chk, said, want), ls in grp.items():
        print('| %s | `%s` | %s | `%s` | `%s` | %s (%d) |'
              % (sev, fn, chk, said[:40], want[:60],
                 ', '.join(str(x) for x in ls[:6]) + (' …' if len(ls) > 6 else ''),
                 len(ls)))
    ndef = len({k for k in grp if k[0] == 'FAIL'})
    print()
    print('**%d distinct FAIL defects** across %d citations. '
          '⚠ `LEDGER.md`\'s tier 0 is a VERBATIM COPY of `LEDGER-HEAD.md`, so every '
          'tier-0 defect is reported twice by construction — **edit `LEDGER-HEAD.md` '
          'and regenerate**, never `LEDGER.md`.' % (ndef, len(fails)))
    print()
    by = collections.Counter(f[2] for f in fails)
    print('by check: %s' % (', '.join('%s=%d' % kv for kv in sorted(by.items())) or 'none'))
    return 1 if fails else 0


if __name__ == '__main__':
    sys.exit(main())
