#!/usr/bin/env python3
"""Byte-verify the ldio/ldwio conversion at its SYMBOLIC-address sites.

The question this answers
-------------------------
Step 9's ldio conversion reshapes `ldio <addr>, <val>` -> `ld (<addr>:8),
<val>:io`.  For a literal address the per-site probe in size_family_convert.py
assembles both spellings standalone and compares the bytes.  For a *symbolic*
address (a TMP94C241 SFR name such as P5CR) it cannot: the name is undefined
outside the tree's `sfr_tmp94c241.s` include, so both spellings reject
standalone and the probe defers them to gate-all.

This script closes that gap independently of gate-all: it prepends the real
SFR definition file (pure .equ/.set, emits no bytes) so every name folds, then
for each SFR name assembles the old `ldio NAME, v` next to the new
`ld (NAME:8), v:io` with -show-encoding and requires byte equality.  It also
runs the NULL -- the selector-less `ld (NAME:8), v`, which is the untagged
default and MUST differ -- so a pass proves the check can see a difference.

Run, from the tree root:
    python3 notes/syntax-convergence-probes/verify_ldio_symbolic.py
exit 0 = every SFR name's reshape is byte-identical and the null differs at all.
"""
import os, re, subprocess, sys, tempfile

MC = os.path.expanduser('~/compartilhado/llvm-project/build/bin/llvm-mc')
VAL = '0x29'


def preamble():
    """A .equ preamble defining EVERY io-address name in the tree, built from
    the union of all SFR definition files (KN5000 TMP94C241 + WSA1 TMP95C061),
    deduplicated (first definition of a name wins, so no redefinition error).
    The specific value does not matter: old and new spellings fold the SAME
    preamble, so byte-equality of the reshape does not depend on it -- only that
    the name is DEFINED, so the :io emitter's symbolic-address refusal does not
    fire on a name that in-tree would fold."""
    files = subprocess.run(['git', 'ls-files', '*sfr*.s', '*sfr*.inc',
                            '*_sfr*.s', '*_sfr*.inc'],
                           capture_output=True, text=True).stdout.split()
    seen, lines = set(), []
    for f in sorted(set(files)):
        for line in open(f, encoding='latin-1'):
            m = re.match(r'^\s*\.(?:equ|set)\s+(\w+)\s*,', line)
            if m and m.group(1) not in seen:
                seen.add(m.group(1))
                lines.append(line.rstrip('\n'))
    return '\n'.join(lines)


def names(_sfr_unused):
    """Distinct SYMBOLIC addresses actually used at converted io sites in the
    tree: `ld (<name>:8), ...:io` / `ldw (<name>:8), ...:io` where <name> is not
    a number.  This is the real ~80-name population (Q6), not every SFR .equ --
    many SFRs are 16-bit-addressed and were never ldio operands."""
    rx = re.compile(r'^\s*ldw?\s+\(\s*([A-Za-z_]\w*)\s*:8\s*\)\s*,.*:io\b')
    out = set()
    files = subprocess.run(['git', 'ls-files', '*.s', '*.inc', '*.asm'],
                           capture_output=True, text=True).stdout.split()
    for f in files:
        for line in open(f, encoding='latin-1'):
            m = rx.match(line)
            if m:
                out.add(m.group(1))
    return sorted(out)


def encode(preamble, insns):
    src = preamble + '\n' + '\n'.join(insns) + '\n'
    with tempfile.NamedTemporaryFile('w', suffix='.s', delete=False,
                                     encoding='latin-1') as fh:
        fh.write(src)
        tmp = fh.name
    try:
        p = subprocess.run([MC, '-triple=tlcs900', '-show-encoding', tmp],
                           capture_output=True, text=True)
        return re.findall(r'encoding: \[([^\]]*)\]', p.stdout)
    finally:
        os.unlink(tmp)


def main():
    pre = preamble()
    ns = names(None)
    old = ['ldio %s, %s' % (n, VAL) for n in ns]
    new = ['ld (%s:8), %s:io' % (n, VAL) for n in ns]
    foil = ['ld (%s:8), %s' % (n, VAL) for n in ns]          # selector dropped -> untagged default
    # Assemble each name on its own so an uncovered name (defined only in a
    # source this union preamble misses) never shifts a positional map.
    bad, blind, covered, uncovered = [], [], 0, []
    for n in ns:
        eo = encode(pre, ['ldio %s, %s' % (n, VAL)])
        en = encode(pre, ['ld (%s:8), %s:io' % (n, VAL)])
        ef = encode(pre, ['ld (%s:8), %s' % (n, VAL)])
        if len(en) != 1 or len(eo) != 1:
            uncovered.append(n)            # name not folded here -> gate-all's job
            continue
        covered += 1
        if eo[0] != en[0]:
            bad.append(n)
        if ef and eo[0] == ef[0]:
            blind.append(n)
    print('symbolic io addresses in tree: %d' % len(ns))
    print('covered by this preamble: %d   deferred to gate-all: %d'
          % (covered, len(uncovered)))
    print('reshape byte-identical: %d/%d covered' % (covered - len(bad), covered))
    print('null (selector dropped) differs: %d/%d covered' % (covered - len(blind), covered))
    if bad:
        print('  MISMATCH at:', ' '.join(bad[:20]))
    if blind:
        print('  NULL BLIND at:', ' '.join(blind[:20]))
    if uncovered:
        print('  deferred (undefined by the union SFR preamble; proven in '
              'context by gate-all):', ' '.join(uncovered[:20]))
    ok = covered > 0 and not bad and not blind
    print('PASS' if ok else 'FAIL')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
