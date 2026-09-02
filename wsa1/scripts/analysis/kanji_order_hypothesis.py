#!/usr/bin/env python3
"""kanji_order_hypothesis.py -- is the WSA1R's private kanji encoding ORDERED BY
THE TEXT IT WAS COLLECTED FROM?

THE QUESTION.  prom_b carries two ideograph faces whose encoding is private:
224 contiguous codes from 0x10 (service 0x1A, "set A") and 43 (service 0x1F,
"set B").  prom_a's own headers say it cannot tell which ideograph a code is.
prom_b/images/fonts/README.md then noticed, by eye, that ADJACENT cells keep
forming compound words -- 状態, 心配, 故障, 工場, 出荷, 電源, 鍵盤 -- and
proposed that the encoding numbers the kanji IN THE ORDER SOME TEXT FIRST
NEEDED THEM.  That was a hypothesis with no test attached.  This is the test.

THE PREDICTION, STATED SO IT CAN FAIL.  If the codes were assigned by walking a
Japanese text and giving each new ideograph the next free number, then a
two-kanji word in that text donates its two characters to CONSECUTIVE codes
whenever both are new.  So: pairs of ADJACENT codes should be real Japanese
words far more often than chance allows.  If the order were alphabetical, by
radical, by stroke count, by frequency, or arbitrary, adjacency carries no such
signal and the count sits on the null.

THE NULL, WHICH IS COMPUTED AND NOT ASSUMED.  Shuffle the SAME characters into
a random order and count again, 10,000 times.  That controls for everything
about the character inventory -- these are 224 words-of-a-technical-manual
kanji, which pair up more readily than random kanji would -- and leaves only
the ORDER as the variable.  A second, within-data control counts pairs at
distance 2, 3, ... which the hypothesis predicts nothing about.

THE ORACLE.  EDICT2 (Electronic Dictionary Research and Development Group,
Monash University; CC BY-SA 4.0), reduced to every headword that is exactly two
kanji drawn from our 267-character alphabet.  It knows nothing about this ROM,
and it is applied identically to the real order, to the distance controls and
to all 10,000 shuffles.

    # regenerate the word list (7.8 MB download, not committed):
    curl -o /tmp/edict2.gz https://ftp.edrdg.org/pub/Nihongo/edict2.gz
    python3 scripts/analysis/kanji_order_hypothesis.py --build-wordlist /tmp/edict2.gz
    # run the test:
    python3 scripts/analysis/kanji_order_hypothesis.py
    python3 scripts/analysis/kanji_order_hypothesis.py --selftest

⚠ THE WEAK LINK IS THE TRANSCRIPTION, and it is weak in the SAFE direction.
notes/fonts-kanji/kanji_transcription.txt was read off the contact sheets by
eye at 16x16.  A misread character breaks a word that is really there; it
cannot manufacture one.  Every count below is therefore a LOWER BOUND, and the
null is affected identically, so the comparison stays honest.
"""
import argparse
import gzip
import re
import pathlib
import random
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent                       # .../wsa1
TRANS = ROOT / 'notes' / 'fonts-kanji' / 'kanji_transcription.txt'
WORDS = ROOT / 'notes' / 'fonts-kanji' / 'wordlist_2char.txt'
UNKNOWN = '〓'                              # 〓, an unsettled cell


def load_transcription(path=TRANS):
    """-> {'A': {code: char}, 'B': {...}}, straight from the committed table."""
    sets = {}
    for line in path.read_text(encoding='utf-8').splitlines():
        if not line or line.startswith('#'):
            continue
        name, base, chars = line.split()
        d = sets.setdefault(name, {})
        for i, c in enumerate(chars):
            d[int(base, 16) + i] = c
    return sets


def ordered(seq):
    """The characters in ascending code order, with unsettled cells kept in
    place (they simply never match)."""
    return [seq[k] for k in sorted(seq)]


def build_wordlist(edict_gz, out=WORDS):
    alphabet = set()
    for d in load_transcription().values():
        alphabet |= set(d.values())
    alphabet.discard(UNKNOWN)
    found = set()
    with gzip.open(edict_gz, 'rb') as f:
        for raw in f:
            line = raw.decode('euc-jp', 'replace')
            head = line.split('/', 1)[0].split('[', 1)[0]
            for form in head.split(';'):
                # EDICT2 tags a form with (P), (oK), (rK), (sK), (ateji) ...
                form = re.sub(r'\(.*?\)', '', form).strip()
                if len(form) == 2 and form[0] in alphabet and form[1] in alphabet:
                    found.add(form)
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, 'w', encoding='utf-8') as fh:
        fh.write('# Every EDICT2 headword that is exactly two kanji, both drawn\n'
                 '# from the %d transcribed WSA1R ideographs.  Regenerate:\n'
                 '#   python3 scripts/analysis/kanji_order_hypothesis.py'
                 ' --build-wordlist edict2.gz\n' % len(alphabet))
        for w in sorted(found):
            fh.write(w + '\n')
    return found


def load_wordlist(path=WORDS):
    return {l.strip() for l in path.read_text(encoding='utf-8').splitlines()
            if l.strip() and not l.startswith('#')}


def hits(chars, words, d, reverse=False):
    out = []
    for i in range(len(chars) - d):
        a, b = chars[i], chars[i + d]
        w = (b + a) if reverse else (a + b)
        if w in words:
            out.append((i, w))
    return out


def null_distribution(chars, words, trials, seed=20260902):
    rng = random.Random(seed)
    pool = list(chars)
    counts = []
    for _ in range(trials):
        rng.shuffle(pool)
        counts.append(len(hits(pool, words, 1)) + len(hits(pool, words, 1, True)))
    return counts


def report(name, codes, words, trials):
    chars = ordered(codes)
    base = sorted(codes)[0]
    print('=' * 72)
    print('SET %s -- %d cells, codes 0x%02X-0x%02X' % (name, len(chars), base,
                                                       base + len(chars) - 1))
    fwd = hits(chars, words, 1)
    rev = hits(chars, words, 1, True)
    obs = len(fwd) + len(rev)
    print('\n  adjacent (d=1) forward  %3d : %s'
          % (len(fwd), ' '.join('%02X:%s' % (base + i, w) for i, w in fwd)))
    print('  adjacent (d=1) reversed %3d : %s'
          % (len(rev), ' '.join('%02X:%s' % (base + i, w) for i, w in rev)))
    print('  ---> OBSERVED (either direction) = %d' % obs)
    print('\n  within-data controls, same characters, same oracle:')
    for d in range(2, 9):
        f, r = len(hits(chars, words, d)), len(hits(chars, words, d, True))
        print('    d=%d  forward %2d  reversed %2d  total %2d' % (d, f, r, f + r))
    null = null_distribution(chars, words, trials)
    mean = sum(null) / len(null)
    sd = (sum((c - mean) ** 2 for c in null) / len(null)) ** 0.5
    ge = sum(1 for c in null if c >= obs)
    print('\n  SHUFFLE NULL, %d random permutations of the same %d characters:'
          % (trials, len(chars)))
    print('    mean %.2f   sd %.2f   max %d' % (mean, sd, max(null)))
    print('    permutations reaching the observed %d: %d / %d   (p %s %.4f)'
          % (obs, ge, trials, '=' if ge else '<', (ge or 1) / trials))
    if sd:
        print('    observed is %.1f sd above the null mean' % ((obs - mean) / sd))
    return obs, mean, sd, ge


def selftest():
    sets = load_transcription()
    assert len(sets['A']) == 224, len(sets['A'])
    assert len(sets['B']) == 43, len(sets['B'])
    assert sorted(sets['A']) == list(range(0x10, 0xF0))
    assert sorted(sets['B']) == list(range(0x10, 0x3B))
    # the two faces are disjoint sets of BITMAPS in the ROM; the transcription
    # must not claim a character in both
    assert not (set(sets['A'].values()) & set(sets['B'].values()) - {UNKNOWN}), \
        'a character was transcribed into both faces -- one reading is wrong'
    words = load_wordlist()
    # the oracle must contain the words the README quoted by eye, or it is not
    # measuring what this test claims
    for w in ('状態', '心配', '故障', '工場', '出荷', '電源', '鍵盤', '説明'):
        assert w in words, w
    # and it must NOT contain a non-word made of our own characters
    assert '節杯' not in words
    # hits() must find a planted pair and miss a planted non-pair
    assert hits(list('状態杯'), words, 1) == [(0, '状態')]
    assert hits(list('杯状態'), words, 1) == [(1, '状態')]
    assert hits(list('状杯態'), words, 1) == []
    assert hits(list('状杯態'), words, 2) == [(0, '状態')]
    assert hits(list('態状'), words, 1, True) == [(0, '状態')]
    print('selftest: 14 checks pass')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build-wordlist', metavar='EDICT2_GZ')
    ap.add_argument('--trials', type=int, default=10000)
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.build_wordlist:
        f = build_wordlist(a.build_wordlist)
        print('wrote %s: %d two-kanji headwords' % (WORDS, len(f)))
        return
    if a.selftest:
        selftest()
        return
    sets = load_transcription()
    words = load_wordlist()
    print('oracle: %d two-kanji EDICT2 headwords over the transcribed alphabet'
          % len(words))
    for name in sorted(sets):
        report(name, sets[name], words, a.trials)


if __name__ == '__main__':
    sys.exit(main())
