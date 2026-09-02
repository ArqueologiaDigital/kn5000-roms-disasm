#!/usr/bin/env python3
"""japanese_text_census.py -- IS THERE ANY JAPANESE TEXT IN THE WSA1R FIRMWARE?

WHY THIS EXISTS.  prom_b ships five Japanese character generators (hiragana,
katakana, half-width katakana and two ideograph sets, 21,120 bytes) and
notes/FINDINGS-fonts.md section 6 records that NOTHING calls their SWI7
services with a literal service number.  Two readings survived that census: the
script is chosen at run time from a variable, or the Japanese faces are simply
unused by this firmware revision.  The faces themselves cannot decide it.  The
TEXT can: if the firmware ever draws a Japanese sentence, the bytes of that
sentence are in a ROM somewhere, and -- unlike the ideographs -- the KANA
encoding is fully known.

WHAT MAKES THIS A MEASUREMENT AND NOT A GREP.  The kana faces are indexed by a
private encoding, but its layout is established (FINDINGS-fonts.md section 4.2,
re-derived by notes/font_layout_check.py): 46 gojuon at 0x10-0x3D in dictionary
order, 9 small kana, the prolonged mark at 0x47, 20 dakuten, 5 handakuten, 5
punctuation -- and services 0x19 and 0x1D share exactly the six cells that
belong to neither script, which is what ties the layout down.  So every byte in
0x10-0x66 HAS a reading, and a run of them is a candidate sentence that can be
decoded and then judged by JAPANESE ORTHOGRAPHY, which most byte runs violate:

  * a run may not begin with っ, ー, ん or a small vowel;
  * ゃゅょ may only follow the i-column (き し ち に ひ み り ぎ じ ぢ び ぴ);
  * a run of >= 6 consecutive ASCENDING codes is a counter or an index table,
    not a word -- it decodes as あいうえおか;
  * one code covering more than half a long run is padding.

★ THE POSITIVE CONTROL IS THE POINT.  A scan that finds nothing proves nothing
unless it can be shown to find something.  --selftest PLANTS real Japanese
sentences, encoded in this ROM's own private encoding, inside a buffer of ROM
bytes and asserts the census recovers them at the right offsets -- and asserts
that the decoys around them (ascending tables, constant padding, a yoon in an
impossible place) are all rejected.  If the planted sentence is not found, the
instrument is broken and no absence it reports means anything.

    python3 scripts/analysis/japanese_text_census.py --selftest
    python3 scripts/analysis/japanese_text_census.py original_ROMs/*.ic12 ...
    python3 scripts/analysis/japanese_text_census.py --all      # the four images
"""
import argparse
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent                       # .../wsa1

# The private kana layout.  Order is the ROM's, per FINDINGS-fonts.md 4.2.
GOJUON = ('あいうえお かきくけこ さしすせそ たちつてと なにぬねの '
          'はひふへほ まみむめも やゆよ らりるれろ わをん').replace(' ', '')
SMALL = 'ぁぃぅぇぉゃゅょっ'
DAKUTEN = 'がぎぐげござじずぜぞだぢづでどばびぶべぼ'
HANDAKUTEN = 'ぱぴぷぺぽ'
PUNCT = '。、「」〜'
KATA = str.maketrans(
    'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん'
    'ぁぃぅぇぉゃゅょっがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽ',
    'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン'
    'ァィゥェォャュョッガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポ')

CODE_LO, CODE_HI = 0x10, 0x66
I_COLUMN = {0x11, 0x15, 0x1A, 0x1F, 0x24, 0x29, 0x2D, 0x32, 0x37,   # い き し ち に ひ み り
            0x49, 0x4D, 0x51, 0x59, 0x5D}                           # ぎ じ ぢ び ぴ
SMALL_VOWEL = set(range(0x3E, 0x43))          # ぁぃぅぇぉ
SMALL_YA = set(range(0x43, 0x46))             # ゃゅょ
SOKUON, CHOON, N_KANA = 0x46, 0x47, 0x3D      # っ ー ん


def _map():
    m = {}
    for i, c in enumerate(GOJUON):
        m[0x10 + i] = c
    for i, c in enumerate(SMALL):
        m[0x3E + i] = c
    m[0x47] = 'ー'
    for i, c in enumerate(DAKUTEN):
        m[0x48 + i] = c
    for i, c in enumerate(HANDAKUTEN):
        m[0x5C + i] = c
    for i, c in enumerate(PUNCT):
        m[0x61 + i] = c
    m[0x66] = '◆'                            # katakana face only
    return m


HIRA = _map()
ENCODE = {v: k for k, v in HIRA.items()}
ENCODE.update({v.translate(KATA): k for k, v in HIRA.items() if v.translate(KATA) != v})


def encode(text):
    """A Japanese kana string -> the bytes this firmware would need.  Used by
    the positive control, and by anyone who wants to plant a string."""
    return bytes(ENCODE[c] for c in text)


def decode(run, katakana=False):
    s = ''.join(HIRA.get(b, '.') for b in run)
    return s.translate(KATA) if katakana else s


def rejects(run):
    """Every reason this run cannot be kana text.  Empty list = a candidate."""
    why = []
    if run[0] in (SOKUON, CHOON, N_KANA) or run[0] in SMALL_YA or run[0] in SMALL_VOWEL:
        why.append('starts %02X' % run[0])
    if run[-1] == SOKUON:
        why.append('ends sokuon')
    for a, b in zip(run, run[1:]):
        if b in SMALL_YA and a not in I_COLUMN:
            why.append('yoon %02X%02X' % (a, b))
        if a == SOKUON and b == SOKUON:
            why.append('double sokuon')
    ramp = best = 1
    for a, b in zip(run, run[1:]):
        ramp = ramp + 1 if b == a + 1 else 1
        best = max(best, ramp)
    if best >= 6:
        why.append('ascending run of %d' % best)
    top = max(run.count(b) for b in set(run))
    if top * 2 > len(run):
        why.append('one code is %d/%d' % (top, len(run)))
    if len(set(run)) < 5:
        why.append('only %d distinct' % len(set(run)))
    return why


def census(data, minlen=6, maxlen=400):
    """-> [(offset, run)] for every maximal in-range run that survives."""
    out, i, n = [], 0, len(data)
    while i < n:
        if CODE_LO <= data[i] <= CODE_HI:
            j = i
            while j < n and CODE_LO <= data[j] <= CODE_HI:
                j += 1
            run = data[i:j]
            if minlen <= len(run) <= maxlen and not rejects(run):
                out.append((i, run))
            i = j
        else:
            i += 1
    return out


KANA_DICT = ROOT / 'notes' / 'fonts-kanji' / 'kana_words.txt'   # built, not committed


def build_kana_dict(edict_gz, out=KANA_DICT):
    """Every EDICT2 form or reading that is 4-8 pure kana.  ~152k words, 2.7 MB
    -- REGENERABLE, so it is built here and not committed:

        curl -o /tmp/edict2.gz https://ftp.edrdg.org/pub/Nihongo/edict2.gz
        python3 scripts/analysis/japanese_text_census.py --build-dict /tmp/edict2.gz

    The notes record its SHA256 beside the numbers taken with it."""
    import gzip
    import re
    hira = set(HIRA.values()) | {'ー'}
    kata = {c.translate(KATA) for c in hira}
    words = set()
    with gzip.open(edict_gz, 'rb') as f:
        for raw in f:
            head = raw.decode('euc-jp', 'replace').split('/', 1)[0]
            m = re.search(r'\[(.*?)\]', head)
            forms = (m.group(1).split(';') if m else []) + head.split('[')[0].split(';')
            for form in forms:
                form = re.sub(r'\(.*?\)', '', form).strip()
                if 4 <= len(form) <= 8 and (set(form) <= hira or set(form) <= kata):
                    words.add(form)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text('\n'.join(sorted(words)), encoding='utf-8')
    return words


def dict_score(runs, mapping, words):
    """How many dictionary kana words does this decoding contain?"""
    n = 0
    for _off, run in runs:
        s = ''.join(mapping.get(b, '.') for b in run)
        s2 = s.translate(KATA)
        for i in range(len(s)):
            for L in range(4, 9):
                if i + L <= len(s):
                    if s[i:i + L] in words:
                        n += 1
                    if s2[i:i + L] in words:
                        n += 1
    return n


def dict_test(roms, trials=200, seed=20260902, minlen=6, plant=0):
    """★ THE DECISIVE CONTROL.  The census's candidate runs are fixed; only the
    MAPPING varies.  Score them with the real kana layout, then with `trials`
    random bijections of the same 87 codes onto the same 87 kana.  Real text
    scores far above the permuted maps; noise scores the same either way, and
    that is a null this ROM's own structure cannot fake."""
    import random
    words = set(KANA_DICT.read_text(encoding='utf-8').split())
    rng = random.Random(seed)
    codes = sorted(HIRA)
    glyphs = [HIRA[c] for c in codes]
    for r in roms:
        data = pathlib.Path(r).read_bytes()
        if plant:
            # ★ POSITIVE CONTROL: the same image with `plant` real Japanese
            # sentences written into it.  If this does not separate from the
            # null, the test cannot detect text and its silence means nothing.
            b = bytearray(data)
            for i in range(plant):
                s_ = PLANTS[i % len(PLANTS)]
                at = 0x100 + i * 0x400
                b[at] = 0x00
                b[at + 1:at + 1 + len(s_)] = encode(s_)
                b[at + 1 + len(s_)] = 0x00
            data = bytes(b)
        runs = census(data, minlen)
        real = dict_score(runs, HIRA, words)
        null = []
        for _ in range(trials):
            g = glyphs[:]
            rng.shuffle(g)
            null.append(dict_score(runs, dict(zip(codes, g)), words))
        mean = sum(null) / len(null)
        sd = (sum((x - mean) ** 2 for x in null) / len(null)) ** 0.5
        ge = sum(1 for x in null if x >= real)
        print('%-22s %5d runs  real %4d   permuted-map null mean %6.1f sd %5.1f '
              'max %4d   perms >= real: %d/%d'
              % (pathlib.Path(r).name, len(runs), real, mean, sd, max(null),
                 ge, trials))


PLANTS = ['でんげんをきってください', 'ふろっぴーでぃすくをいれてください',
          'メモリーがいっぱいです', 'しばらくおまちください']


def selftest():
    import random
    rng = random.Random(20260902)
    # a haystack of plausible non-text: ascending tables, padding, code-ish bytes
    hay = bytearray()
    marks = {}
    hay += bytes(range(0x10, 0x30))                 # an ascending index table
    hay += bytes([0x24]) * 40                       # constant padding
    hay += bytes(rng.randrange(256) for _ in range(500))
    hay += encode('あっ') + bytes([0x43])           # an impossible yoon (あっゃ)
    for s in PLANTS:
        hay += bytes([0x00, 0xFF])
        marks[len(hay)] = s
        hay += encode(s)
    hay += bytes([0x00])
    hay += bytes(rng.randrange(256) for _ in range(500))
    found = {off: bytes(r) for off, r in census(bytes(hay))}
    for off, s in marks.items():
        assert off in found, 'PLANTED %r NOT FOUND -- the instrument is blind' % s
        got = decode(found[off])
        want = ''.join(c if c in HIRA.values() else c for c in s)
        assert encode(s) == found[off], (s, got)
    # ...and the decoys are all rejected
    assert len(found) == len(marks), \
        'the census also accepted %d decoy runs' % (len(found) - len(marks))
    assert rejects(bytes(range(0x10, 0x20)))
    assert rejects(bytes([0x24]) * 20)
    assert rejects(encode('あっ') + bytes([0x43]))
    assert not rejects(encode(PLANTS[0]))
    assert decode(encode('でんげん')) == 'でんげん'
    assert decode(encode('メモリー'), katakana=True) == 'メモリー'
    print('selftest: %d planted sentences recovered, %d decoy shapes refused, '
          '%d checks pass' % (len(marks), 3, len(marks) + 8))


def sweep(roms, trials=5, seed=20260902):
    """A WEAK control, kept because its failure is instructive.  It reruns the
    census over the ROM's own bytes SHUFFLED.  Every image comes out far ABOVE
    that null at every threshold -- and that means nothing, because shuffling
    destroys ALL structure, not just text: font bitmaps, tables and padding all
    produce long in-range runs that a shuffle cannot.  ⚠ Do not read this as
    evidence of text.  The control that can actually decide is --dict-test,
    which holds the runs fixed and varies only the MAPPING."""
    import random
    rng = random.Random(seed)
    print('%-22s %-6s %8s %8s   %s' % ('image', 'minlen', 'real', 'null mean',
                                       'verdict'))
    for r in roms:
        data = pathlib.Path(r).read_bytes()
        name = pathlib.Path(r).name
        for m in (6, 8, 10, 12, 16):
            real = len(census(data, m))
            nulls = []
            for _ in range(trials):
                b = bytearray(data)
                rng.shuffle(b)
                nulls.append(len(census(bytes(b), m)))
            mean = sum(nulls) / len(nulls)
            print('%-22s %-6d %8d %8.1f   %s'
                  % (name, m, real, mean,
                     'ABOVE NULL' if real > max(nulls) else 'at/below null'))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('roms', nargs='*')
    ap.add_argument('--all', action='store_true', help='the four WSA1R images')
    ap.add_argument('--min', type=int, default=6)
    ap.add_argument('--sweep', action='store_true',
                    help='count vs a byte-shuffle null, at five thresholds')
    ap.add_argument('--build-dict', metavar='EDICT2_GZ')
    ap.add_argument('--plant', type=int, default=0,
                    help='positive control: write N real sentences into the image first')
    ap.add_argument('--dict-test', action='store_true',
                    help='score the census with the real map vs permuted maps')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        selftest()
        return
    roms = a.roms
    if a.all:
        roms = [str(ROOT / 'original_ROMs' / n) for n in
                ('wsa1_prom_a.ic12', 'wsa1_prom_b.ic13',
                 'wsa1_prom_c.ic28', 'wsa1_prom_d.bin')]
    if a.build_dict:
        w = build_kana_dict(a.build_dict)
        print('wrote %s: %d kana words' % (KANA_DICT, len(w)))
        return
    if a.sweep:
        sweep(roms)
        return
    if a.dict_test:
        dict_test(roms, plant=a.plant)
        return
    total = 0
    for r in roms:
        data = pathlib.Path(r).read_bytes()
        hits = census(data, a.min)
        total += len(hits)
        print('%-40s %7d bytes   %d candidate kana runs (min %d)'
              % (pathlib.Path(r).name, len(data), len(hits), a.min))
        for off, run in hits:
            print('    %06X %3d  %s | %s'
                  % (off, len(run), decode(run), decode(run, True)))
    print('TOTAL candidate Japanese kana runs: %d' % total)


if __name__ == '__main__':
    sys.exit(main())
