#!/usr/bin/env python3
"""Generate the manual's reference appendices from the decode findings.

QUESTION IT ANSWERS
    "Where in the firmware does each statement in this manual come from?"

    The narrative chapters are written by hand; these appendices are generated, so the
    traceability table cannot drift from the findings it was built on.

USAGE
    ./gen_appendix.py decode-findings.json   -> appendix-evidence.tex, appendix-open.tex
"""
import json, re, sys, pathlib

def esc(s):
    s = (s.replace('\\', r'\textbackslash{}').replace('&', r'\&').replace('%', r'\%')
          .replace('$', r'\$').replace('#', r'\#').replace('_', r'\_')
          .replace('{', r'\{').replace('}', r'\}').replace('~', r'\textasciitilde{}')
          .replace('^', r'\textasciicircum{}'))
    s = s.replace('★', '').replace('⚠', '').replace('→', r'$\rightarrow$')
    s = s.replace('↔', r'$\leftrightarrow$').replace('←', r'$\leftarrow$')
    s = s.replace('≥', r'$\geq$').replace('≤', r'$\leq$').replace('≠', r'$\neq$')
    s = s.replace('×', r'$\times$').replace('·', r'$\cdot$').replace('±', r'$\pm$')
    s = s.replace('°', r'$^\circ$').replace('…', '...').replace('\u2011', '-')
    # anything still outside Latin-1 becomes a marker rather than a build failure
    s = ''.join(ch if ord(ch) < 0x100 or ch in '$\\{}^_' else '?' for ch in s)
    s = s.replace('—', '---').replace('–', '--').replace('’', "'").replace('“', "``").replace('”', "''")
    return s

MARK = {'established': r'\estab', 'likely': r'\likely', 'unverified': r'\unver'}

src = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'decode-findings.json')
areas = json.loads(src.read_text())

ev = [r'\chapter{Evidence index}',
      r'Every finding behind this manual, with the firmware symbols that establish it.',
      r'\small']
for a in areas:
    ev.append(r'\section{%s}' % esc(a.get('area', 'unnamed')[:110]))
    ev.append(r'\begin{longtable}{p{0.30\textwidth}p{0.12\textwidth}p{0.48\textwidth}}')
    ev.append(r'\toprule topic & certainty & symbols \\ \midrule \endhead')
    for f in a.get('findings', []):
        ev.append('%s & %s & %s \\\\' % (esc(f['topic'][:90]),
                                         MARK.get(f['certainty'], ''),
                                         esc(f['symbols'][:170])))
        ev.append(r'\addlinespace')
    ev.append(r'\bottomrule\end{longtable}')

op = [r'\chapter{Open questions}',
      r'What this edition does not establish. These are recorded so a later pass knows '
      r'where the evidence stopped.', r'\small', r'\begin{itemize}']
n = 0
for a in areas:
    for q in a.get('openQuestions', []):
        op.append(r'\item %s' % esc(q[:400])); n += 1
op.append(r'\end{itemize}')

pathlib.Path('appendix-evidence.tex').write_text('\n'.join(ev) + '\n')
pathlib.Path('appendix-open.tex').write_text('\n'.join(op) + '\n')
print('evidence rows:', sum(len(a.get('findings', [])) for a in areas), ' open questions:', n)
