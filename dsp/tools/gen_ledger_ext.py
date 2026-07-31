#!/usr/bin/env python3
"""dsp/tools/gen_ledger_ext.py -- sweep the REPO-EXTERNAL notes for GRADED VERDICTS
and report which of them have no representation in `dsp/analysis/`.

WHY THIS EXISTS
---------------
`LEDGER.md` TIER 0b exists so a refuted idea is never re-proposed.  It is built by
`gen_ledger.py`, which reads exactly two things: `upd6383.cpp/.h` and
`SPECULATIVE-APPLIED-REGISTER.md`.  Both live in THIS repo.

The evidence does not.  ~213 notes in `kn7000_mame/notes/` carry graded verdicts,
and on 2026-07-31 a review found the eleventh instance of the failure the LEDGER
exists to prevent: a **KN7000 cross-model coefficient comparison, run 2026-07-22,
VERDICT: NEGATIVE** (`notes/kn5000-dsp-coefficients.md` §5/§5.2 -- "zero arbitrary
coefficient is shared", delay lengths FALSIFIED, intersection `{200}` over 962
pairs) was re-proposed by an external auditor as the highest-value unopened
channel, because it appears NOWHERE in `dsp/analysis/`.

**The index is repo-scoped; the evidence is not.**  That is the defect, and this
tool measures its size.

⛔ THIS TOOL DOES NOT MODIFY `gen_ledger.py` AND MUST NOT BE IMPORTED ALONGSIDE IT
-- `gen_ledger.py` calls `main()` at module scope with no `if __name__` guard, so
importing it REWRITES `LEDGER.md`.  This file is standalone and WRITE-FREE: it
prints a proposed TIER 0b extension; a human pastes it.

THE PRESENCE TEST, and why it is not a grep
-------------------------------------------
A verdict is REPRESENTED in `dsp/analysis/` iff **NEED (=3) of its DISCRIMINATING
tokens co-occur in ONE analysis file**.  A token is discriminating when it is rare
BOTH across the notes corpus (document frequency <= DF_MAX) AND within its own
note (it does not occur in any other section of that file), so neither shared
vocabulary nor the note's own subject matter can carry a match.

★ RULE 20.  The detector is validated against a known ABSENT verdict and a known
PRESENT one BEFORE any count is emitted, and the self-test is printed first.  A
sweep that prints "N missing" is worthless until it has shown it can print
"present" for something that is.

⚠ GRADE THE COUNT HONESTLY.  `NEED` and `DF_MAX` were CALIBRATED on exactly TWO
known answers (T1 absent, T3 present).  Two controls pin a threshold weakly, so:
  * "the KN7000 cross-model NEGATIVE is absent"  -- **MEASURED**, and independently
    confirmed by hand: `0.5614`, `0.618`, `0.876`, `0.2435` and `{200}` return ZERO
    hits anywhere under `dsp/analysis/`;
  * the aggregate "N verdicts absent"            -- **INFERRED**, a lower bound on
    the exposure, not a precise inventory.  Report it as an order of magnitude and
    a work queue, never as a statistic.

Usage:  python3 dsp/tools/gen_ledger_ext.py [--all] [--drafts]
"""
import os, re, sys, math, collections

DSP   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ANA   = os.path.join(DSP, 'analysis')
NOTES = '/home/fsanches/compartilhado/kn7000_mame/notes'

VERDICT = re.compile(
    r'VERDICT:|\bFALSIFIED\b|\bREFUTED\b|\bNEGATIVE\b|\bRETRACTED\b|\bDEAD[ -]END\b'
    r'|\bdead end\b|\bMOOT\b|\bDISPROVE[DN]?\b|\bNOT SUPPORTED\b')
DF_MAX = 4          # a token in <=4 notes is discriminating
NEED   = 3          # how many must co-occur in ONE analysis file to count as present

#  ⚠ THIS PROJECT WRITES LARGE NUMBERS WITH DIGIT-GROUP SPACES ("962 880"), so a
#  naive `\b\d{3,}\b' extracts the FRAGMENTS `962' and `880'.  That is precisely
#  how the KN7000 verdict's tap value `962' matched the register's frame total and
#  faked a representation.  Normalise the grouping before tokenising, and require
#  four digits.
NORMSP = re.compile(r'(?<=\d)[\s  ](?=\d)')
TOKEN  = re.compile(r'`([^`\n]{4,40})`|(\b0x[0-9A-Fa-f]{4,}\b)|(\b\d+\.\d{3,}\b)'
                    r'|(\b\d{4,}\b)')


def toks(text):
    text = NORMSP.sub('', text)
    out = set()
    for a, b, c, d in TOKEN.findall(text):
        t = (a or b or c or d).strip()
        if t and not t.isspace():
            out.add(t)
    return out


# ------------------------------------------------------------------- the corpus

def walk(root, ext='.md'):
    for dp, dn, fn in os.walk(root):
        if '.git' in dp:
            continue
        for f in sorted(fn):
            if f.endswith(ext):
                yield os.path.join(dp, f)


def notes_corpus():
    docs = {}
    for p in walk(NOTES):
        try:
            docs[p] = open(p, errors='ignore').read()
        except Exception:
            pass
    return docs


#  ⚠ A REPORT ABOUT THE GAP MUST NOT CLOSE THE GAP ON PAPER.
#  `BOOKKEEPING-REPAIR_findings.md' quotes the missing verdicts verbatim in order to
#  DRAFT them as TIER 0b rows.  Index it and every drafted verdict instantly reads
#  "represented", while `LEDGER.md' still carries none of them -- the gap would be
#  measured as closed by the document that measured it.  The gap closes when TIER 0b
#  carries the rows, not when a findings file describes them.
#  ★ Self-tests T1 and T1b are the TWO-SIDED control for exactly this: T1 asserts the
#  KN7000 verdict is ABSENT with the drafts excluded, T1b asserts the same detector
#  reports it PRESENT once they are counted.  A detector that cannot see a filing
#  cannot be trusted to report an absence.
SELF = {'BOOKKEEPING-REPAIR_findings.md'}


def analysis_index(exclude=SELF):
    """token -> set(analysis files).  Built once; the presence test is a lookup."""
    idx = collections.defaultdict(set)
    files = 0
    for p in walk(ANA):
        b = os.path.basename(p)
        if b in exclude:
            continue
        t = open(p, errors='ignore').read()
        files += 1
        for k in toks(t):
            idx[k].add(b)
    return idx, files


def is_dsp(path, text):
    b = os.path.basename(path).lower()
    return 'dsp' in b or 'upd6383' in text or 'IC311' in text


# ------------------------------------------------------------------ the extract

def verdicts(docs):
    """One record per verdict-bearing HEADING SECTION, not per line -- a section is
    the unit a dead-end entry would be written about, and it keeps the fingerprint
    wide enough to be discriminating."""
    out = []
    for p, t in docs.items():
        lines = t.split('\n')
        #  ⚠ SLICE AT THE NEXT HEADING OF THE SAME OR HIGHER LEVEL, never at the
        #  next heading of ANY level.  The first draft did the latter and truncated
        #  `## 5. The KN7000 correlation' at `### 5.1', leaving a two-line body with
        #  ONE discriminating token -- which would have reported the verdict absent
        #  for the wrong reason.  Self-test T2 exists because that happened.
        heads = [(i, len(re.match(r'^#+', l).group(0)))
                 for i, l in enumerate(lines) if re.match(r'^#{2,4}\s', l)]
        for k, (i, lvl) in enumerate(heads):
            end = len(lines)
            for j, lv2 in heads[k + 1:]:
                if lv2 <= lvl:
                    end = j
                    break
            seg = lines[i:end]
            body = '\n'.join(seg)
            if not VERDICT.search(body):
                continue
            #  the verdict line itself, for the report
            vl = next((l.strip() for l in seg if VERDICT.search(l)), seg[0])
            out.append(dict(path=p, head=lines[i].strip('# ').strip(),
                            line=i + 1, verdict=vl, body=body,
                            dsp=is_dsp(p, t)))
        #  a verdict before the first heading still counts
        if heads and VERDICT.search('\n'.join(lines[:heads[0][0]])):
            body = '\n'.join(lines[:heads[0][0]])
            vl = next((l.strip() for l in lines[:heads[0][0]] if VERDICT.search(l)), '')
            out.append(dict(path=p, head='(preamble)', line=1, verdict=vl,
                            body=body, dsp=is_dsp(p, t)))
    return out


def doc_freq(docs):
    df = collections.Counter()
    for t in docs.values():
        for k in toks(t):
            df[k] += 1
    return df


def fingerprint(rec, df, sibling=None):
    """The tokens that discriminate THIS VERDICT, on two axes:

      (a) CORPUS-WIDE: document frequency <= DF_MAX across the notes, so shared
          vocabulary cannot carry a match;
      (b) ⚠ WITHIN THE DOCUMENT: a token that also occurs in ANOTHER section of
          the SAME note belongs to the note's subject matter, not to this verdict.

    (b) is not decoration.  Without it, `kn5000-dsp-coefficients.md' §5 (the
    cross-model NEGATIVE) matched on §3's KN5000 delay-tap list -- which the
    analysis tree DOES carry -- and the tool certified a missing verdict as
    present.  Self-test T1 exists because that happened.  `sibling` is the union
    of the file's other sections' tokens."""
    fp = {k for k in toks(rec['body']) if df.get(k, 0) <= DF_MAX}
    if sibling:
        fp -= sibling
    return fp


def annotate_siblings(recs, docs):
    """Attach to every record the tokens that occur OUTSIDE its own section in the
    same note -- computed by deleting the section's text from the document, so a
    token present both inside and outside is correctly counted as outside."""
    for r in recs:
        rest = docs[r['path']].replace(r['body'], '\n', 1)
        r['_sib'] = toks(rest)


def represented(fp, idx, need=NEED):
    """PRESENT iff >= `need` fingerprint tokens co-occur in ONE analysis file."""
    hit = collections.Counter()
    for k in fp:
        for f in idx.get(k, ()):
            hit[f] += 1
    if not hit:
        return None, 0
    f, n = hit.most_common(1)[0]
    return (f, n) if n >= need else (None, n)


# ------------------------------------------------------------------- self-test

def self_test(recs, df, idx, nana, idx_self=None):
    """★ RULE 20.  Known ABSENT and known PRESENT, both named in advance."""
    R = []

    def chk(tag, ok, said, want):
        R.append((tag, 'PASS' if ok else '**FAIL**', str(said)[:110], want))

    def find(sub, headsub=None):
        for r in recs:
            if sub in r['path'] and (headsub is None or headsub.lower() in r['head'].lower()):
                return r
        return None

    # --- ★★★★ §228 FLIPPED T1's POLARITY, AND THAT IS THE RESULT, NOT A REPAIR.
    #
    #  T1 used to demand the KN7000 cross-model verdict be reported ABSENT.  §228
    #  FILED IT -- it is TIER 0b dead-end row 31 -- so T1 immediately started
    #  failing, for the one reason a control must never fail: the thing it asserted
    #  had been FIXED.  The same thing happened to `lint_handoff.py' in the same
    #  hour, whose five controls were the five live defects the patch plan repaired.
    #
    #  ⇒ TIER 0c RULE 20, THE CLAUSE THIS EARNED: a control must be a case whose
    #    answer is known INDEPENDENTLY of the thing under test.  A control that is
    #    ITSELF the open defect is validated exactly once, and is invalidated by
    #    its own success.
    #
    #  The pair is now polarity-STABLE and still two-sided:
    #    T1  the FILED verdict must come back PRESENT   (and it can regress: unfile
    #        row 31 and this fails, which is the point)
    #    T1c a SYNTHETIC fingerprint of tokens that occur nowhere must come back
    #        ABSENT -- so "PRESENT" can never mean "this detector matches anything".
    kn = find('kn5000-dsp-coefficients.md', 'KN7000 correlation')
    if kn:
        fp = fingerprint(kn, df, kn.get('_sib'))
        f, n = represented(fp, idx)
        chk('T1  the KN7000 cross-model NEGATIVE is reported PRESENT — §228 FILED it '
            'as TIER 0b row 31 (was "must be ABSENT" until 2026-07-31)',
            f is not None, 'best analysis file=%s with %d shared tokens' % (f, n),
            'not None -- the filing must be visible to the detector')
        chk('T2  ...and its fingerprint is not empty (an empty one would fake either verdict)',
            len(fp) >= 5, '%d discriminating tokens: %s'
            % (len(fp), sorted(fp)[:6]), '>= 5')
        #  ★ THE OTHER SIDE, and it is now SYNTHETIC so no repair can consume it.
        bogus = {'zzq%04dxx' % k for k in range(11)}
        fb, nb = represented(bogus, idx)
        chk('T1c ⚠ THE NEGATIVE SIDE: a SYNTHETIC fingerprint present in no file is '
            'reported ABSENT (so PRESENT cannot mean "matches anything")',
            fb is None, 'best=%s (%d shared)' % (fb, nb), 'None')
        if idx_self is not None:
            f2, n2 = represented(fp, idx_self)
            chk('T1b ...and the verdict is ALSO visible with the drafts counted '
                '(consistency of the two index builds)',
                f2 is not None, 'best=%s (%d shared)' % (f2, n2),
                'not None')
    else:
        chk('T1  the KN7000 cross-model NEGATIVE was EXTRACTED', False,
            'not found by the extractor', 'a record from kn5000-dsp-coefficients.md')
        chk('T2  fingerprint', False, '—', '—')

    # --- KNOWN PRESENT: a verdict the analysis tree demonstrably carries.
    #  `dsp-register-space-applied.md' is the note recording what was APPLIED from
    #  `analysis/register-space.md'; its verdict MUST come back PRESENT.  If it does
    #  not, the detector cannot see representation at all and every "ABSENT" below
    #  is an artefact rather than a finding.
    #  ⚠ THE FIRST DRAFT'S CONTROL WAS BROKEN: it selected `§5.2 Delay lengths ...
    #  FALSIFIED', which is itself one of the KNOWN-ABSENT verdicts, and so demanded
    #  PRESENT for something that must be ABSENT.  A control has to be a case whose
    #  answer is known INDEPENDENTLY of the thing being tested.
    ctl = find('dsp-register-space-applied.md')
    if ctl:
        f, n = represented(fingerprint(ctl, df, ctl.get('_sib')), idx)
        chk('T3  a verdict the analysis tree DOES carry is reported PRESENT '
            '(dsp-register-space-applied.md <-> analysis/register-space.md)',
            f is not None, 'best=%s (%d shared)' % (f, n), 'not None')
    else:
        chk('T3  the known-PRESENT control was extracted', False, 'not found',
            'a record from dsp-register-space-applied.md')

    # --- the sweep must be able to say "present" more than once
    pres = sum(1 for r in recs if r.get('_present'))
    chk('T4  the detector says PRESENT for a non-trivial share of the corpus',
        pres > 0, '%d of %d records PRESENT' % (pres, len(recs)), '>0')

    # --- denominators
    chk('T5  the analysis index actually loaded', nana > 50,
        '%d analysis files indexed' % nana, '>50')
    chk('T6  the notes sweep actually loaded', len(recs) > 30,
        '%d verdict records' % len(recs), '>30')
    return R


# ----------------------------------------------------------------------- drafts

def draft(rec):
    """A paste-ready TIER 0b row."""
    why = re.sub(r'\s+', ' ', rec['verdict']).strip('>*# ')[:300]
    return ('| ? | %s | ⛔ %s | `kn7000_mame/notes/%s` §%s |'
            % (rec['head'][:90].replace('|', '\\|'), why.replace('|', '\\|'),
               os.path.relpath(rec['path'], NOTES), rec['line']))


def main():
    show_all = '--all' in sys.argv
    docs = notes_corpus()
    recs = verdicts(docs)
    df   = doc_freq(docs)
    idx, nana = analysis_index()

    annotate_siblings(recs, docs)
    for r in recs:
        fp = fingerprint(r, df, r.get('_sib'))
        f, n = represented(fp, idx)
        r['_fp'], r['_present'], r['_hits'] = fp, f, n

    print('# gen_ledger_ext — repo-EXTERNAL graded verdicts vs `dsp/analysis/`')
    print()
    print('swept `%s`: **%d** notes, **%d** verdict-bearing sections. '
          'indexed **%d** files under `dsp/analysis/`.'
          % (NOTES, len(docs), len(recs), nana))
    print('presence test: >= %d tokens that are rare corpus-wide (document frequency '
          '<= %d) AND absent from the rest of their own note, co-occurring in ONE '
          'analysis file.' % (NEED, DF_MAX))
    print()
    print('⚠ **`%s` is EXCLUDED from the index by design** — it quotes the missing verdicts in '
          'order to DRAFT them, and a report about the gap must not close the gap on paper. '
          'The gap closes when TIER 0b carries the rows -- §228 filed eleven (rows 31-41). '
          'Self-tests **T1/T1c** are the two-sided control for this exclusion.' % ', '.join(sorted(SELF)))
    print()
    print('⚠ **GRADE:** the KN7000 cross-model case was **MEASURED** absent (hand-confirmed: '
          '`0.5614`, `0.618`, `0.876`, `0.2435` returned zero hits under `dsp/analysis/`) and '
          'is now **FILED** as TIER 0b row 31 -- which is why T1 asserts PRESENT, and why the '
          'negative side had to become SYNTHETIC (T1c): a control that IS the open defect is '
          'invalidated by its own repair (rule 20). '
          'The aggregate count is **INFERRED** -- the threshold is calibrated on two '
          'controls, so read it as a LOWER-BOUND WORK QUEUE, not a statistic.')
    print()

    print('## 0. RULE 20 — the self-test, printed BEFORE the count')
    print()
    idx_self, _ = analysis_index(exclude=set())
    R = self_test(recs, df, idx, nana, idx_self)
    print('| check | result | what it read | what it demanded |')
    print('|---|---|---|---|')
    for tag, res, said, want in R:
        print('| %s | %s | `%s` | %s |' % (tag, res, said, want))
    npass = sum(1 for _, r, _, _ in R if r == 'PASS')
    print()
    print('**%d of %d self-tests PASS.**%s' % (npass, len(R), '' if npass == len(R)
          else '  ⛔ **A FAILING SELF-TEST VOIDS THE COUNT.**'))
    print()

    dsp   = [r for r in recs if r['dsp']]
    miss  = [r for r in recs if not r['_present']]
    dmiss = [r for r in dsp  if not r['_present']]

    print('## 1. ★ THE COUNT — and the count IS the finding')
    print()
    print('| population | total | represented in `dsp/analysis/` | **ABSENT** |')
    print('|---|--:|--:|--:|')
    print('| all verdict sections | %d | %d | **%d** |'
          % (len(recs), len(recs) - len(miss), len(miss)))
    print('| DSP-relevant only | %d | %d | **%d** |'
          % (len(dsp), len(dsp) - len(dmiss), len(dmiss)))
    print()
    print('⇒ **%d DSP-relevant graded verdicts live only in `kn7000_mame/notes/` and have '
          'no representation in the analysis tree.** `gen_ledger.py` reads neither, so '
          'none of them can ever reach TIER 0b. The KN7000 cross-model NEGATIVE is one '
          'of them; §228 filed it and the count fell by one, which is what progress looks like here.' % len(dmiss))
    print()

    print('## 2. THE ABSENT DSP VERDICTS (draft TIER 0b rows)')
    print()
    print('| # | note | § heading | the verdict, as the note states it |')
    print('|--:|---|---|---|')
    for i, r in enumerate(sorted(dmiss, key=lambda x: x['path']), 1):
        if not show_all and i > 40:
            print('| … | *(%d more; run with `--all`)* | | |' % (len(dmiss) - 40))
            break
        v = re.sub(r'\s+', ' ', r['verdict']).strip('>*# ')[:150].replace('|', '\\|')
        print('| %d | `%s` | %s | %s |'
              % (i, os.path.relpath(r['path'], NOTES), r['head'][:60].replace('|', '\\|'), v))
    print()

    if '--drafts' in sys.argv:
        print('## 3. PASTE-READY TIER 0b ROWS')
        print()
        for r in sorted(dmiss, key=lambda x: x['path']):
            print(draft(r))


if __name__ == '__main__':
    main()
