#!/usr/bin/env python3
"""Generate analysis/LEDGER.md -- the progressive-disclosure index of every
hypothesis, its mask bit, and its verdict.

Rationale (Felipe, 2026-07-30): ten passes on this project have been lost to
re-asking a question the notes already answered, or re-trying an approach a
previous section refuted.  A flat 6000-line register does not prevent that; an
index read FIRST does.  This file is generated so it cannot drift from the source.

Tiers:
  0  the blocker + the dead-ends       (hand-curated, in LEDGER-HEAD.md)
  1  the mask-bit table                (generated from upd6383.cpp/.h -- authoritative)
  2  the section index                 (generated from the register's headings)
  3  the register sections themselves
"""
import re, os, sys, collections

DSP  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAME = '/home/fsanches/compartilhado/kn7000_mame/src/devices/cpu/upd6383'
REG  = os.path.join(DSP, 'analysis', 'SPECULATIVE-APPLIED-REGISTER.md')
HEAD = os.path.join(DSP, 'analysis', 'LEDGER-HEAD.md')
OUT  = os.path.join(DSP, 'analysis', 'LEDGER.md')

def default_mask():
    h = open(os.path.join(MAME, 'upd6383.h')).read()
    m = re.search(r'm_specmask\s*=\s*(0x[0-9a-fA-F]+)', h)
    return int(m.group(1), 16)

def mask_bits():
    """bit -> (list of §refs, list of one-line descriptions) from the C++ sources."""
    bits = collections.defaultdict(lambda: {'sec': set(), 'desc': set(), 'blk': ''})
    for fn in ('upd6383.cpp', 'upd6383.h'):
        lines = open(os.path.join(MAME, fn)).read().split('\n')
        for i, ln in enumerate(lines):
            hit = set()
            for b in re.findall(r'1ull\s*<<\s*(\d+)', ln):
                hit.add(int(b))
            for h in re.findall(r'm_specmask\s*&\s*(0x[0-9a-fA-F]+)u?l*', ln):
                v = int(h, 16)
                for b in range(64):
                    if v >> b & 1: hit.add(b)
            if not hit: continue
            # look backwards for the nearest "§NNN" and a headline in the comment block
            #  ★ Attribute to the OWNING section, not merely the last one mentioned:
            #  prefer a "★★★ §N" / "§N SPECULATIVE" banner, which is how this file
            #  marks the section that introduced a gate.  Fall back to any §ref only
            #  if no banner is in scope.
            ctx = lines[max(0, i - 60):i + 3]
            banner = [int(x) for ln2 in ctx
                      for x in re.findall(r'(?:★★★\s*)?§(\d+)\s*(?:SPECULATIVE|\()', ln2)]
            secs = banner or [int(x) for ln2 in ctx for x in re.findall(r'§(\d+)', ln2)]
            #  the headline: the ★ banner's text, joined across continuation lines so
            #  it does not truncate mid-phrase.
            desc = ''
            for j in range(i, max(0, i - 60), -1):
                m = re.search(r'★+\s*§?\d*\s*(?:SPECULATIVE\s*)?\(?(?:mask )?bit[^)]*\)?\s*:?\s*(.+)', lines[j])
                if not m or len(m.group(1).strip()) <= 12: continue
                desc = m.group(1).strip()
                for k in range(j + 1, min(j + 4, len(lines))):   # join continuations
                    c = re.match(r'\s*//\s{2,}([A-Za-z`\'"(].*)', lines[k])
                    if not c or desc.rstrip().endswith('.'): break
                    desc += ' ' + c.group(1).strip()
                desc = re.sub(r'\s+', ' ', desc).strip().rstrip('.').lstrip(': ')
                break
            blk = '\n'.join(ctx)
            for b in hit:
                if secs: bits[b]['sec'].add(int(secs[-1]))
                if desc: bits[b]['desc'].add(desc[:120])
                bits[b]['blk'] = bits[b].get('blk', '') + '\n' + blk
    return bits

def sections():
    out = []
    lines = open(REG).read().split('\n')
    heads = [i for i, l in enumerate(lines) if re.match(r'^## §(\d+)', l)]
    for k, i in enumerate(heads):
        m = re.match(r'^## §(\d+)\s*[-—–]*\s*(.*)$', lines[i])
        num, title = int(m.group(1)), m.group(2).strip()
        #  ★ §220: slice the body at the NEXT section heading, not at a fixed 200
        #  lines.  The old window silently dropped the `Evidence grade:' line of any
        #  section longer than 200 lines (§218, §219, §220 all lost theirs) and could
        #  read the NEXT section's grade for any section shorter than it.
        end = heads[k + 1] if k + 1 < len(heads) else len(lines)
        body = '\n'.join(lines[i:end])
        grade = ''
        g = re.search(r'Evidence grade:\s*(.+)', body)
        if g: grade = re.sub(r'\s+', ' ', g.group(1))[:160]
        verdict = 'OPEN'
        t = title.upper()
        #  ★ §220: an EXPLICIT marker wins over the keyword heuristic, which called
        #  §220 "SHIPPED" because arm A's description contains the word "shipped".
        #  Opt-in, so no existing row moves: <!-- LEDGER-VERDICT: ... -->
        vm = re.search(r'<!--\s*LEDGER-VERDICT:\s*(.+?)\s*-->', body)
        if vm: verdict = vm.group(1)
        elif 'REFUT' in t or 'RETRACT' in t or '⛔' in title: verdict = 'REFUTED/RETRACTED'
        elif 'SHIP' in t or 'SHIPPED' in body[:1200].upper(): verdict = 'SHIPPED'
        elif 'CORRECTION' in t: verdict = 'CORRECTION'
        out.append((num, title, verdict, grade))
    return out

def main():
    dm = default_mask()
    bits = mask_bits()
    secs = sections()
    w = []
    w.append(open(HEAD).read().rstrip() if os.path.exists(HEAD) else '# LEDGER')
    w.append('\n---\n')
    w.append('## TIER 1 — the mask-bit register  (generated from `upd6383.cpp/.h`; authoritative)\n')
    w.append('Default `m_specmask` = **`0x%X`**.  `ON` = in the shipped default; `off` = implemented\n'
             'but not armed.  ⚠ `REFUTED` means **stop**; `⚠ UNTESTED` means **this is owed a run**;\n'
             'plain `off` means the classifier found neither marker — read the section.\n\n'
             '⚠ **The `§` column routes; the text does not adjudicate.** Both are heuristic excerpts taken\n'
             'from the nearest `★` banner in the source, and where two gates share a comment block the text\n'
             'can belong to the neighbour. Use this table to find the section, then read the section.\n' % dm)
    #  ★ §168: an unarmed bit is NOT one state.  "off because REFUTED" says stop;
    #  "off because UNTESTED" says this is owed a run.  The index could not tell them
    #  apart, and bit 18 sat testable-but-invisible for weeks as a result.
    UNTESTED = ('NOT VALIDLY TESTED', 'never tested', 'UNTESTED', 'never been evaluated',
                'has never been', 'not yet been tested', 'awaiting a run', 'owed a run')
    REFUTED  = ('REFUTED', 'REVERTED', 'bit-identical', 'measurably destroys', 'FALSIFIED',
                'refutation', 'did not fire', 'changed nothing', 'DEAD END')
    def classify(b):
        if (dm >> b) & 1: return '**ON**'
        blk = bits[b]['blk']
        #  ★ REFUTED WINS when both markers are present.  A block that once said
        #  "never tested" and later says "refuted" has been superseded in that
        #  order, never the reverse -- and the asymmetry is deliberate: mis-filing
        #  a refuted bit as UNTESTED costs a wasted run, mis-filing an untested one
        #  as REFUTED costs an idea that is never revisited.  Prefer the cheap error.
        if any(k in blk for k in REFUTED):  return 'REFUTED'
        if any(k in blk for k in UNTESTED): return '⚠ UNTESTED'
        return 'off'
    owed = [b for b in sorted(bits) if classify(b) == '⚠ UNTESTED']
    if owed:
        w.append('★ **OWED A RUN** (implemented, unarmed, and the comment block says it was never'
                 ' validly tested — these are opportunities, not dead ends): **bit %s**.\n'
                 % ', '.join(str(b) for b in owed))
    w.append('| bit | state | § | what it does |')
    w.append('|----:|:-----:|--:|---|')
    for b in sorted(bits):
        s = bits[b]
        state = classify(b)
        sec = ', '.join('§%d' % x for x in sorted(s['sec'])[:2]) or '—'
        d = sorted(s['desc'], key=len)[-1] if s['desc'] else ''
        d = d[:150]
        d = d.replace('|', '\\|')
        w.append('| %d | %s | %s | %s |' % (b, state, sec, d))
    w.append('\n---\n')
    w.append('## TIER 2 — the section index  (generated from the register headings)\n')
    w.append('%d sections, §%d..§%d.  **Read the tail first** — later sections retract earlier ones *in place*.\n'
             % (len(secs), secs[0][0], secs[-1][0]))
    w.append('| § | verdict | claim | grade |')
    w.append('|--:|---|---|---|')
    for num, title, verdict, grade in secs:
        w.append('| §%d | %s | %s | %s |' % (num, verdict, title.replace('|', '\\|')[:120],
                                             grade.replace('|', '\\|')[:110]))
    w.append('')
    open(OUT, 'w').write('\n'.join(w) + '\n')
    print('wrote %s: %d mask bits, %d sections, default 0x%X' % (OUT, len(bits), len(secs), dm))

main()
