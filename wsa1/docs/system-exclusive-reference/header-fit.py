#!/usr/bin/env python3
"""Will any chapter's running head collide with the fixed string on the left?

The head puts "Technics SX-WSA1R -- System Exclusive Reference" on the left and the current
chapter on the right, on ONE line. If the two together exceed the head's width they print on
top of each other, which is what Felipe reported on pages 11, 12, 53, 55 and 61 of the draft.

    python3 header-fit.py [--form current|numtitle|titleonly]

It reads the chapter titles out of the .toc, measures each candidate head in LaTeX at the
document's own size and geometry, and prints the width against what is available. `current` is
report's default (\\MakeUppercase, "CHAPTER n." prefix); `titleonly` is what the document uses.

style.tex also carries a guard that warns at build time -- grep the log for HEADER OVERFLOW --
so this script is for choosing a form, and the guard is for catching a regression. The guard
was itself checked by lengthening a chapter title until it fired.
"""
import os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
DOC = 'wsa1r-system-exclusive-reference'
LEFT = r'\small Technics SX-WSA1R \textendash{} System Exclusive Reference'
FORMS = {
    'current':   lambda n, t: r'\small CHAPTER %s. %s' % (n, t.upper()),
    'numtitle':  lambda n, t: r'\small %s. %s' % (n, t),
    'titleonly': lambda n, t: r'\small %s' % t,
}


def chapters():
    toc = open(os.path.join(HERE, DOC + '.toc')).read()
    return [(m.group(1), m.group(2), int(m.group(3))) for m in re.finditer(
        r'\\contentsline \{chapter\}\{\\numberline \{(\d+)\}(.*?)\}\{(\d+)\}', toc)]


def main():
    form = sys.argv[sys.argv.index('--form') + 1] if '--form' in sys.argv else None
    forms = [form] if form else list(FORMS)
    ch = chapters()
    body = [r'\documentclass[11pt,a4paper]{report}',
            r'\usepackage[T1]{fontenc}\usepackage[utf8]{inputenc}',
            r'\usepackage[margin=28mm]{geometry}\usepackage{fancyhdr}\pagestyle{fancy}',
            r'\newlength{\w}', r'\begin{document}',
            r'\typeout{FIT headwidth . \the\headwidth}',
            r'\settowidth{\w}{%s}\typeout{FIT left . \the\w}' % LEFT]
    for n, title, _ in ch:
        for f in forms:
            body.append(r'\settowidth{\w}{%s}\typeout{FIT %s %s \the\w}'
                        % (FORMS[f](n, title), f, n))
    body += ['x', r'\end{document}']
    with tempfile.TemporaryDirectory() as d:
        src = os.path.join(d, 'fit.tex')
        open(src, 'w').write('\n'.join(body))
        subprocess.run(['pdflatex', '-interaction=nonstopmode', 'fit.tex'],
                       cwd=d, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        log = open(os.path.join(d, 'fit.log'), errors='replace').read()
    w = {}
    for m in re.finditer(r'FIT (\S+) (\S+) ([\d.]+)pt', log):
        w.setdefault(m.group(1), {})[m.group(2)] = float(m.group(3))
    head, left = w['headwidth']['.'], w['left']['.']
    avail = head - left
    print("head %.2fpt, left string %.2fpt -> the right has %.2fpt\n" % (head, left, avail))
    print("%-4s %-46s %s" % ("ch", "title", "  ".join("%12s" % f for f in forms)))
    bad = {f: [] for f in forms}
    worst = {f: 0.0 for f in forms}
    for n, title, page in ch:
        cells = []
        for f in forms:
            v = w[f][n]
            worst[f] = max(worst[f], v)
            if v > avail:
                bad[f].append((n, page))
            cells.append("%11.2f%s" % (v, '*' if v > avail else ' '))
        print("%-4s %-46s %s" % (n, title[:46], "  ".join(cells)))
    print()
    for f in forms:
        print("  %-10s worst %7.2fpt, clearance %+7.2fpt, %d chapter(s) overflow %s"
              % (f, worst[f], avail - worst[f], len(bad[f]),
                 [n for n, _ in bad[f]] if bad[f] else ''))
    return 1 if any(bad[f] for f in forms if f == 'titleonly') else 0


if __name__ == '__main__':
    sys.exit(main())
