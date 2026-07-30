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
    bits = collections.defaultdict(lambda: {'sec': set(), 'desc': set()})
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
            for b in hit:
                if secs: bits[b]['sec'].add(int(secs[-1]))
                if desc: bits[b]['desc'].add(desc[:120])
    return bits

def sections():
    out = []
    lines = open(REG).read().split('\n')
    idx = [(i, l) for i, l in enumerate(lines)]
    for i, l in idx:
        m = re.match(r'^## §(\d+)\s*[-—–]*\s*(.*)$', l)
        if not m: continue
        num, title = int(m.group(1)), m.group(2).strip()
        body = '\n'.join(lines[i:i + 200])
        grade = ''
        g = re.search(r'Evidence grade:\s*(.+)', body)
        if g: grade = re.sub(r'\s+', ' ', g.group(1))[:160]
        verdict = 'OPEN'
        t = title.upper()
        if 'REFUT' in t or 'RETRACT' in t or '⛔' in title: verdict = 'REFUTED/RETRACTED'
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
             'but not armed, which usually means **tried and refuted** — read the section before re-arming.\n\n'
             '⚠ **The `§` column routes; the text does not adjudicate.** Both are heuristic excerpts taken\n'
             'from the nearest `★` banner in the source, and where two gates share a comment block the text\n'
             'can belong to the neighbour. Use this table to find the section, then read the section.\n' % dm)
    w.append('| bit | state | § | what it does |')
    w.append('|----:|:-----:|--:|---|')
    for b in sorted(bits):
        s = bits[b]
        state = '**ON**' if (dm >> b) & 1 else 'off'
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
