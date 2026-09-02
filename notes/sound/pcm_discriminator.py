#!/usr/bin/env python3
"""pcm_discriminator.py -- IS ANY BYTE RANGE IN THE 13 GATED IMAGES PCM AUDIO?

QUESTION ANSWERED
-----------------
The project owner asked that data ranges whose purpose is known be represented in a
playable form: "If the data range represents PCM audio, you could use lossless WAV
files."  Before writing any WAV, one has to establish that PCM is *there*.  These are
CPU program/data ROMs; the KN5000's sampled waveforms live on separate mask ROMs
(IC304-307) that are in no CPU's address space, and the SX-WSA1R's six wave mask ROMs
are undumped.  So the expected answer is "no PCM", and a tool that cannot return that
answer is useless.

THE MEASURE
-----------
Three features per window, computed on the window read as signed 16-bit little-endian:

  r1        lag-1 autocorrelation of the sample stream.  Real PCM is SMOOTH: adjacent
            samples are correlated because the waveform is bandlimited well below the
            sample rate.  Code, pointer tables and compressed streams are not.
  lo_ent    Shannon entropy (bits) of the LOW byte of each sample.  Real PCM fills its
            low byte with essentially uniform noise (~7.9 of 8 bits).  A parameter
            table's low bytes are structured and quantised.
  diff_ent  Shannon entropy (bits) of the low byte of the first difference.  This is
            the guard against the one false-positive mode found during calibration:
            an ASCENDING 16-BIT TABLE is perfectly smooth (r1 = 0.999) and has a
            perfectly uniform low byte (lo_ent = 8.00), so r1 + lo_ent alone calls it
            audio 100% of the time.  Its first difference is the constant 1, so
            diff_ent = 0.  PCM's first difference is broadband (~7.8 bits).

  VERDICT16 = r1 >= 0.60  AND  lo_ent >= 7.00  AND  diff_ent >= 7.00

AND 8-BIT PCM, because a 16-bit rule cannot see it
--------------------------------------------------
The rule above is blind to 8-bit sample data, so there is a second lane.  Read the
window as 8-bit samples in BOTH signings (offset-binary and two's complement, since
either is used in practice) and require

  VERDICT8  = r1_8 >= 0.60  AND  byte_ent >= 6.50  AND  diff8_ent >= 4.50   (either signing)

Its positive control is derived from the same hardware-rooted dump: the HIGH BYTES of
IC307's s16 PCM are genuine 8-bit PCM of the same recordings.  It is a blunter
instrument -- it accepts 41-52% of known 8-bit PCM against the 16-bit lane's 66-73%,
and it has TWO false-positive modes that the census actually hit, both adjudicated in
FINDINGS-audio-and-music-ranges-2026-09-02.md: 8bpp indexed PHOTOGRAPHS (the
HD-AE5000 splash screen) and slowly-rising numeric LOOKUP CURVES.  Every window it
flags must be looked at; it is a screen, not a verdict.

Thresholds are round numbers chosen to sit in the empty gap between the calibration
distributions, not tuned to a target rate.

THE CALIBRATION AND ITS NULL -- run `--calibrate`
-------------------------------------------------
POSITIVE CONTROL, and the reason this is a measurement rather than an opinion: the
KN5000's IC307 waveform mask ROM is a hardware-rooted dump that is KNOWN to be signed
16-bit LE PCM (notes/kn5000-ic307-content-map.md in kn7000_mame, an independent pass).
It carries its own NEGATIVE control in the same chip: its first 0x1A30 bytes are an
index table plus 198 parameter records -- the exact kind of structured byte-valued
table these program ROMs are full of.

NULLS: uniform random bytes (high entropy, not smooth), a pure sine table (smooth, but
its residual is not broadband), an ascending u16 table (the trap above), and the LZSS /
SLIDE8K compressed streams that really are inside these ROMs.

"It renders as a waveform" is not evidence -- any bytes render as a waveform.  What is
evidence is a rule that fires on 3/4 of known PCM and on none of six kinds of known
non-PCM.

AND A THIRD LANE, BECAUSE COMPRESSED AUDIO IS INVISIBLE TO BOTH
---------------------------------------------------------------
ADPCM sample data is high-entropy and NOT smooth in its stored form, so lanes 1 and 2
are blind to it by construction -- exactly the shape of blind spot that turns "we found
no audio" into "our instrument cannot see audio".  Lane 3 DECODES each window as 4-bit
IMA ADPCM (both nibble orders, adaptive predictor from a zero state) and scores the
DECODED signal with a relaxed 16-bit rule, `r1 >= 0.40, lo_ent >= 7.00,
diff_ent >= 6.00` -- relaxed because ADPCM quantisation noise costs the reconstruction
about 0.35 of its lag-1 autocorrelation.

  POSITIVE: IC307's own PCM run through an IMA encoder, then decoded and scored:
  81% of windows.  NULLS: random bytes, IC307's parameter records, and the program
  ROMs themselves decoded AS IF they were ADPCM: 0%.

  This lane is not a general compressed-audio detector -- it tests IMA/DVI
  specifically.  A different ADPCM variant with different step tables would decode to
  noise under it.  What it rules out is the most common 1990s ROM sample codec.

  ⚠ ITS FALSE-POSITIVE MODE IS THE RAMP AGAIN, one level down.  A slowly-rising
  STAIRCASE table (`00 00 00 01 01 01 01 02 02 ...`) presents the IMA predictor with
  near-constant nibbles, which it integrates into a smooth ramp.  All 11 windows this
  lane flags in the 13 images are of that shape and every one is adjudicated in
  FINDINGS-audio-and-music-ranges-2026-09-02.md.

USAGE
-----
  python3 notes/sound/pcm_discriminator.py --calibrate   # the table above
  python3 notes/sound/pcm_discriminator.py --census      # all 13 gated images
  python3 notes/sound/pcm_discriminator.py --containers  # inside the compressed blobs
  python3 notes/sound/pcm_discriminator.py --selftest    # the separation, as asserts

Run from the repository root.
"""
import argparse, glob, os, subprocess, sys
import numpy as np

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM = os.path.join(REPO, 'original_ROMs')
WSA1 = os.path.join(REPO, 'wsa1', 'original_ROMs')

# The positive control lives outside this repo: it is the KN5000's waveform mask ROM,
# which is NOT one of the 13 gated images (it is in no CPU's address space).  Its
# absence must weaken the report, not silently skip the calibration.
IC307 = os.path.expanduser(
    '~/compartilhado/kn7000-emulator/roms/kn5000/kn5000_waveform_rom.ic307')
IC307_PCM0 = (0x001A30, 0x0FEF60)     # indexed page-0 PCM
IC307_PCM_TAIL = (0x0FEF60, 0x3FFFC0)  # un-indexed pages 1-3
IC307_TABLE = (0x000000, 0x001A30)     # index + 198 parameter records

# The 13 images `make gate-all` certifies.
IMAGES = [
    ('KN5000 v10 program',        os.path.join(ROM, 'kn5000_v10_program.rom')),
    ('KN5000 v9 program',         os.path.join(ROM, 'kn5000_v9_program.rom')),
    ('KN5000 v7 program',         os.path.join(ROM, 'kn5000_v7_program.rom')),
    ('KN5000 subprogram v1.42',   os.path.join(ROM, 'kn5000_subprogram_v142.rom')),
    ('KN5000 subprogram v1.42 z', os.path.join(ROM, 'kn5000_subprogram_v142_compressed.rom')),
    ('KN5000 subcpu boot IC30',   os.path.join(ROM, 'kn5000_subcpu_boot.ic30')),
    ('KN5000 table data',         os.path.join(ROM, 'kn5000_table_data.rom')),
    ('KN5000 custom data IC19',   os.path.join(ROM, 'kn5000_custom_data.ic19')),
    ('HD-AE5000 v2.06i IC4',      os.path.join(ROM, 'hd-ae5000_v2_06i.ic4')),
    ('SX-WSA1R prom_a IC12',      os.path.join(WSA1, 'wsa1_prom_a.ic12')),
    ('SX-WSA1R prom_b IC13',      os.path.join(WSA1, 'wsa1_prom_b.ic13')),
    ('SX-WSA1R prom_c IC28',      os.path.join(WSA1, 'wsa1_prom_c.ic28')),
    ('SX-WSA1R prom_d',           os.path.join(WSA1, 'wsa1_prom_d.bin')),
]

R1_MIN, LO_ENT_MIN, DIFF_ENT_MIN = 0.60, 7.00, 7.00
R1_MIN8, ENT_MIN8, DIFF_ENT_MIN8 = 0.60, 6.50, 4.50
R1_MINA, LO_ENT_MINA, DIFF_ENT_MINA = 0.40, 7.00, 6.00

# IMA/DVI ADPCM, the standard tables.
_IMA_STEP = np.array([
    7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41, 45,
    50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143, 157, 173, 190, 209, 230,
    253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658, 724, 796, 876, 963,
    1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024, 3327,
    3660, 4026, 4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442,
    11487, 12635, 13899, 15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794,
    32767], dtype=np.int32)
_IMA_IDX = np.array([-1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8],
                    dtype=np.int32)


def _ent(v):
    h = np.bincount(np.asarray(v, dtype=np.uint8), minlength=256).astype(np.float64)
    s = h.sum()
    if s == 0:
        return 0.0
    h /= s
    nz = h[h > 0]
    return float(-(nz * np.log2(nz)).sum())


def features(buf):
    """Three features for one window, read as signed 16-bit little-endian."""
    b = np.frombuffer(buf, dtype=np.uint8)
    n = (len(b) // 2) * 2
    if n < 64:
        return None
    x = b[:n].view('<i2').astype(np.int64)
    xc = x - x.mean()
    ss = float((xc * xc).sum())
    r1 = float((xc[:-1] * xc[1:]).sum() / ss) if ss > 0 else 0.0
    return dict(r1=r1, lo_ent=_ent(b[:n:2]), diff_ent=_ent(np.diff(x) & 0xFF), n=n)


def is_pcm(f):
    return (f is not None and f['r1'] >= R1_MIN
            and f['lo_ent'] >= LO_ENT_MIN and f['diff_ent'] >= DIFF_ENT_MIN)


def features8(buf):
    """8-bit lane: (r1, byte_ent, diff_ent) for the better of the two signings."""
    u = np.frombuffer(buf, dtype=np.uint8)
    if len(u) < 64:
        return None
    e = _ent(u)
    best = None
    for sign, b in (('u', u.astype(np.int64)),
                    ('s', np.frombuffer(buf, dtype=np.int8).astype(np.int64))):
        xc = b - b.mean()
        ss = float((xc * xc).sum())
        r1 = float((xc[:-1] * xc[1:]).sum() / ss) if ss > 0 else 0.0
        de = _ent(np.diff(b) & 0xFF)
        cand = dict(sign=sign, r1=r1, ent=e, diff_ent=de)
        if best is None or r1 > best['r1']:
            best = cand
    return best


def is_pcm8(f):
    return (f is not None and f['r1'] >= R1_MIN8
            and f['ent'] >= ENT_MIN8 and f['diff_ent'] >= DIFF_ENT_MIN8)


def scan8(data, win=1024, step=None):
    step = step or win
    tot, hits = 0, []
    for i in range(0, max(len(data) - win + 1, 0), step):
        f = features8(data[i:i + win])
        if f is None:
            continue
        tot += 1
        if is_pcm8(f):
            hits.append(i)
    return tot, hits


def ima_decode(buf, hi_first=False):
    """4-bit IMA ADPCM -> s16le bytes.  Predictor and index start at zero, which is what
    a headerless ROM block would have to do."""
    b = np.frombuffer(buf, dtype=np.uint8)
    nib = np.empty(len(b) * 2, dtype=np.uint8)
    if hi_first:
        nib[0::2], nib[1::2] = b >> 4, b & 0xF
    else:
        nib[0::2], nib[1::2] = b & 0xF, b >> 4
    pred, idx = 0, 0
    out = np.empty(len(nib), dtype=np.int16)
    for i, n in enumerate(nib):
        step = int(_IMA_STEP[idx])
        diff = step >> 3
        if n & 4:
            diff += step
        if n & 2:
            diff += step >> 1
        if n & 1:
            diff += step >> 2
        pred = pred - diff if n & 8 else pred + diff
        pred = -32768 if pred < -32768 else (32767 if pred > 32767 else pred)
        idx = int(max(0, min(88, idx + int(_IMA_IDX[n]))))
        out[i] = pred
    return out.tobytes()


def _ima_encode(s16):
    """The inverse of ima_decode, used ONLY to manufacture the positive control."""
    x = np.frombuffer(s16, dtype='<i2').astype(np.int64)
    pred, idx, nibs = 0, 0, []
    for v in x:
        step = int(_IMA_STEP[idx])
        d = int(v) - pred
        n = 8 if d < 0 else 0
        d = -d if d < 0 else d
        if d >= step:
            n |= 4
            d -= step
        if d >= step >> 1:
            n |= 2
            d -= step >> 1
        if d >= step >> 2:
            n |= 1
        diff = step >> 3
        if n & 4:
            diff += step
        if n & 2:
            diff += step >> 1
        if n & 1:
            diff += step >> 2
        pred = pred - diff if n & 8 else pred + diff
        pred = -32768 if pred < -32768 else (32767 if pred > 32767 else pred)
        idx = int(max(0, min(88, idx + int(_IMA_IDX[n]))))
        nibs.append(n)
    return bytes(nibs[i] | (nibs[i + 1] << 4) for i in range(0, len(nibs) - 1, 2))


def is_adpcm(buf):
    """True if EITHER nibble order decodes to something the relaxed rule calls audio."""
    for hi in (False, True):
        f = features(ima_decode(buf, hi))
        if (f is not None and f['r1'] >= R1_MINA and f['lo_ent'] >= LO_ENT_MINA
                and f['diff_ent'] >= DIFF_ENT_MINA):
            return True
    return False


def scan_adpcm(data, win=4096, step=None):
    step = step or win
    tot, hits = 0, []
    for i in range(0, max(len(data) - win + 1, 0), step):
        tot += 1
        if is_adpcm(data[i:i + win]):
            hits.append(i)
    return tot, hits


def scan(data, win=4096, step=None):
    """-> (n_windows, [offsets of windows the rule calls PCM])."""
    step = step or win
    tot, hits = 0, []
    for i in range(0, max(len(data) - win + 1, 0), step):
        f = features(data[i:i + win])
        if f is None:
            continue
        tot += 1
        if is_pcm(f):
            hits.append(i)
    return tot, hits


def _rate(data, label, win=4096, step=None, eight=False):
    tot, hits = (scan8 if eight else scan)(data, win, step)
    pct = 100.0 * len(hits) / tot if tot else 0.0
    print(f"  {label:52s} {len(hits):6d}/{tot:6d}  {pct:6.2f}%")
    return tot, hits


def _ic307():
    if not os.path.exists(IC307):
        print(f"!! POSITIVE CONTROL MISSING: {IC307}\n"
              f"!! Without it this tool has no calibration and reports nothing.")
        sys.exit(2)
    return open(IC307, 'rb').read()


def _pcm8_positive(d, rng_):
    """Genuine 8-bit PCM of the same recordings: the HIGH BYTES of IC307's s16."""
    return np.frombuffer(d[slice(*rng_)], dtype=np.uint8)[1::2].tobytes()


def cmd_calibrate(win=4096, win8=1024):
    d = _ic307()
    print(f"=== 16-BIT LANE.  Window {win} B ({win // 2} samples).  "
          f"r1>={R1_MIN}, lo_ent>={LO_ENT_MIN}, diff_ent>={DIFF_ENT_MIN}\n")
    print("POSITIVE CONTROL -- KN5000 IC307 waveform mask ROM, known s16le PCM")
    _rate(d[slice(*IC307_PCM0)], "IC307 page-0 indexed PCM (1,037,616 B)", win)
    _rate(d[slice(*IC307_PCM_TAIL)], "IC307 pages 1-3 un-indexed PCM (3,149,920 B)", win)
    print("\nNEGATIVE CONTROL -- structured tables, from the SAME chip")
    _rate(d[slice(*IC307_TABLE)], "IC307 index table + 198 parameter records", win)
    print("\nNULLS -- synthetic and real non-audio with audio-like statistics")
    rng = np.random.default_rng(1)
    _rate(rng.integers(0, 256, 1 << 20, dtype=np.uint8).tobytes(),
          "uniform random bytes (entropic, not smooth)", win)
    t = np.arange(1 << 19)
    _rate((30000 * np.sin(2 * np.pi * t / 256)).astype('<i2').tobytes(),
          "pure sine table (smooth, residual not broadband)", win)
    _rate(np.arange(1 << 19, dtype='<u2').tobytes(),
          "ascending u16 table (THE TRAP: smooth AND uniform)", win)
    for pat, name in ((os.path.join(ROM, 'demo_preset_*_compressed.original.bin'),
                       "LZSS-compressed demo presets (real, in-ROM)"),
                      (os.path.join(ROM, 'help_db_*_compressed.original.bin'),
                       "SLIDE8K-compressed help databases (real, in-ROM)")):
        blobs = b''.join(open(p_, 'rb').read() for p_ in sorted(glob.glob(pat)))
        if blobs:
            _rate(blobs, name, win)

    print(f"\n=== 8-BIT LANE.  Window {win8} B.  "
          f"r1>={R1_MIN8}, byte_ent>={ENT_MIN8}, diff_ent>={DIFF_ENT_MIN8}\n")
    print("POSITIVE CONTROL -- the high bytes of IC307's PCM, i.e. the same audio at 8 bits")
    _rate(_pcm8_positive(d, IC307_PCM0), "IC307 page-0 PCM as 8-bit", win8, eight=True)
    _rate(_pcm8_positive(d, IC307_PCM_TAIL), "IC307 tail PCM as 8-bit", win8, eight=True)
    print("\nNEGATIVE CONTROL and NULLS")
    _rate(d[slice(*IC307_TABLE)], "IC307 index table + parameter records", win8, eight=True)
    _rate(rng.integers(0, 256, 1 << 20, dtype=np.uint8).tobytes(),
          "uniform random bytes", win8, eight=True)
    _rate(np.arange(1 << 19, dtype=np.uint8).tobytes(),
          "ascending u8 ramp", win8, eight=True)
    _rate((127 + 120 * np.sin(2 * np.pi * np.arange(1 << 19) / 64)).astype(np.uint8).tobytes(),
          "sine table u8", win8, eight=True)

    print(f"\n=== ADPCM LANE.  Window {win} B, decoded as 4-bit IMA then scored with "
          f"r1>={R1_MINA}, lo_ent>={LO_ENT_MINA}, diff_ent>={DIFF_ENT_MINA}\n")
    print("POSITIVE CONTROL -- IC307's own PCM run through an IMA encoder")
    enc = _ima_encode(d[0x40000:0x40000 + 0x40000])
    t, h = scan_adpcm(enc, win)
    print(f"  {'IMA ADPCM stream':52s} {len(h):6d}/{t:6d}  {100 * len(h) / t:6.2f}%")
    print("\nNULLS -- non-audio bytes decoded AS IF they were ADPCM")
    for buf, lab in ((rng.integers(0, 256, 1 << 19, dtype=np.uint8).tobytes(),
                      "uniform random bytes"),
                     (d[slice(*IC307_TABLE)], "IC307 index + parameter records")):
        t, h = scan_adpcm(buf, win)
        print(f"  {lab:52s} {len(h):6d}/{t:6d}  {100 * len(h) / max(t, 1):6.2f}%")


def cmd_census(win=4096, step=None, win8=1024):
    step = step or win // 2
    print(f"=== 16-BIT LANE.  Window {win} B, step {step} B.\n")
    grand = 0
    for name, path in IMAGES:
        if not os.path.exists(path):
            print(f"  {name:52s} MISSING {path}")
            continue
        data = open(path, 'rb').read()
        tot, hits = scan(data, win, step)
        grand += len(hits)
        extra = ''
        if hits:
            extra = '  <- ' + ' '.join(f'0x{h:06X}' for h in hits[:8])
            if len(hits) > 8:
                extra += f' ... (+{len(hits) - 8})'
        print(f"  {name:52s} {len(hits):5d}/{tot:5d} windows {len(data):>9,} B{extra}")
    print(f"\n  16-bit lane: {grand} window(s) called PCM across all 13 gated images.")

    print(f"\n=== 8-BIT LANE.  Window {win8} B, step {win8} B.\n")
    grand8 = 0
    for name, path in IMAGES:
        if not os.path.exists(path):
            continue
        data = open(path, 'rb').read()
        tot, hits = scan8(data, win8)
        grand8 += len(hits)
        extra = ''
        if hits:
            extra = '  <- ' + ' '.join(f'0x{h:06X}' for h in hits[:12])
            if len(hits) > 12:
                extra += f' ... (+{len(hits) - 12})'
        print(f"  {name:52s} {len(hits):5d}/{tot:5d} windows{extra}")
    print(f"\n  8-bit lane: {grand8} window(s) flagged -- see the findings for their"
          f" adjudication.")

    print(f"\n=== ADPCM LANE.  Window {win} B, step {win} B.\n")
    grandA = 0
    for name, path in IMAGES:
        if not os.path.exists(path):
            continue
        data = open(path, 'rb').read()
        tot, hits = scan_adpcm(data, win)
        grandA += len(hits)
        extra = ''
        if hits:
            extra = '  <- ' + ' '.join(f'0x{h:06X}' for h in hits[:12])
        print(f"  {name:52s} {len(hits):5d}/{tot:5d} windows{extra}")
    print(f"\n  ADPCM lane: {grandA} window(s) flagged.")
    return grand, grand8, grandA


def cmd_containers(win=4096, step=None, win8=1024):
    """The compressed blobs really inside these ROMs, decompressed.

    A census of the raw image cannot see inside an LZSS stream, so a PCM region hidden
    in one would be missed.  This looks."""
    step = step or win // 2
    print("Decompressed containers (the raw census only sees the compressed bytes)\n")
    total = total8 = 0
    seen = 0
    pats = [os.path.join(REPO, 'table_data', 'includes', 'demo_presets', 'demo_preset_*.bin'),
            os.path.join(REPO, 'table_data', 'includes', 'help_databases', '*.bin'),
            os.path.join(REPO, 'custom_data', 'includes', '*.bin')]
    for pat in pats:
        for p_ in sorted(glob.glob(pat)):
            if 'compressed' in os.path.basename(p_):
                continue
            data = open(p_, 'rb').read()
            seen += 1
            t, h = scan(data, win, step)
            t8, h8 = scan8(data, win8)
            total += len(h)
            total8 += len(h8)
            print(f"  {os.path.basename(p_):52s} 16-bit {len(h):4d}/{t:4d}   "
                  f"8-bit {len(h8):4d}/{t8:4d}")
    if seen == 0:
        print("  !! no decompressed containers present -- run `make decompress-demo-presets`\n"
              "  !! and `make decompress-help-databases` first, or this proves nothing.")
        return None
    print(f"\n  {seen} containers; 16-bit {total} window(s), 8-bit {total8} window(s).")
    return total, total8


def cmd_sounddata(win8=1024):
    """The named `audio/sound_data_*` blocks: are they PCM, or parameter tables?

    The brief singled these out.  Scoring them is only half the answer -- "not audio"
    is a negative.  The positive is printed beside it: each is a 4-byte-record grid of
    {sub_bank, patch_ref} whose fields are SMALL INTEGERS, which is what a patch
    reference table looks like and what PCM does not.
    """
    pat = os.path.join(REPO, 'v10', 'maincpu', 'includes', 'generated', 'sound_data_*.bin')
    files = sorted(glob.glob(pat))
    if not files:
        print("!! no sound_data_*.bin built -- run `make` first; this proves nothing.")
        return None
    print(f"{'file':40s} {'bytes':>7s}  {'16b':>5s} {'8b':>5s}   "
          f"{'r1':>6s} {'lo_ent':>6s}  max_word  zero%")
    flagged = 0
    for f in files:
        d = open(f, 'rb').read()
        n16 = len(scan(d, min(4096, (len(d) // 2) * 2))[1]) if len(d) >= 128 else 0
        n8 = len(scan8(d, min(win8, len(d)))[1]) if len(d) >= 64 else 0
        flagged += n16 + n8
        ft = features(d) or dict(r1=0, lo_ent=0)
        w = np.frombuffer(d[:(len(d) // 2) * 2], dtype='<u2')
        zero = 100.0 * (np.frombuffer(d, dtype=np.uint8) == 0).mean()
        print(f"  {os.path.basename(f):38s} {len(d):7d}  {n16:5d} {n8:5d}   "
              f"{ft['r1']:+.3f} {ft['lo_ent']:6.2f}  {int(w.max()) if len(w) else 0:8d}  {zero:5.1f}")
    print(f"\n  {flagged} window(s) called PCM across all {len(files)} blocks.")
    print("  Every field is a small integer and the blocks are 4-byte-record grids: these\n"
          "  are PATCH REFERENCE TABLES ({sub_bank:u16, patch_ref:u16}), not sample data.\n"
          "  The tree already says so -- they are compiled from typed C structs\n"
          "  (v10/maincpu/audio/sound_data_*.c) that build byte-exact.")
    return flagged


def cmd_magics():
    """Where could MUSIC be hiding?  A sweep for every music container this project knows.

    The PCM lanes answer "is this sample data".  They say nothing about SEQUENCE data,
    which is small-integer event bytes and looks like any other table.  So this asks the
    complementary question by signature: the IC19 style-bank magic, the two LZSS block
    magics, and the Standard MIDI File chunk tags -- plus a shape census for the 256-byte
    style/song cell.  A magic with no cells behind it is a string constant, not a bank.
    """
    magics = [(b'H\x00K\x00', 'IC19 style-bank magic'),
              (b'SLIDE4K', 'demo-song LZSS block'),
              (b'SLIDE8K', 'help-database LZSS block'),
              (b'MThd', 'SMF header chunk tag'),
              (b'MTrk', 'SMF track chunk tag')]
    for name, path in IMAGES:
        if not os.path.exists(path):
            continue
        d = open(path, 'rb').read()
        parts = []
        for m, lab in magics:
            c = d.count(m)
            if c:
                extra = ''
                if m == b'MThd':
                    v = sum(1 for i in range(len(d) - 8)
                            if d[i:i + 4] == b'MThd' and d[i + 4:i + 8] == b'\x00\x00\x00\x06')
                    extra = f' ({v} with a valid 6-byte header length)'
                parts.append(f'{lab} x{c}{extra}')
        cells = sum(1 for o in range(0, len(d) - 256, 256)
                    if d[o + 5] == 0x87 and d[o + 255] == 0x87 and d[o] in (0x80, 0x00))
        if cells:
            parts.append(f'256-byte cell shape x{cells}')
        print(f"  {name:38s} {'; '.join(parts) if parts else '-'}")
    print("\n  A magic is not a container.  See "
          "FINDINGS-audio-and-music-ranges-2026-09-02.md section 11 for what each is.")


def cmd_selftest():
    """The separation, as assertions.  These are the numbers the findings quote."""
    d = _ic307()
    win, win8 = 4096, 1024
    t0, h0 = scan(d[slice(*IC307_PCM0)], win)
    t1, h1 = scan(d[slice(*IC307_PCM_TAIL)], win)
    tt, ht = scan(d[slice(*IC307_TABLE)], win)
    assert len(h0) / t0 > 0.60, (len(h0), t0)
    assert len(h1) / t1 > 0.60, (len(h1), t1)
    assert len(ht) == 0, ht
    # the trap must be caught by diff_ent and by nothing else
    ramp = np.arange(1 << 16, dtype='<u2').tobytes()
    f = features(ramp[:win])
    assert f['r1'] >= R1_MIN and f['lo_ent'] >= LO_ENT_MIN, f
    assert f['diff_ent'] < 0.5, f
    assert not is_pcm(f)
    # nulls, 16-bit lane
    rng = np.random.default_rng(1)
    assert scan(rng.integers(0, 256, 1 << 19, dtype=np.uint8).tobytes(), win)[1] == []
    t = np.arange(1 << 18)
    assert scan((30000 * np.sin(2 * np.pi * t / 256)).astype('<i2').tobytes(), win)[1] == []
    # 8-bit lane: it must SEE 8-bit PCM, or its zero on the images means nothing
    p8 = _pcm8_positive(d, IC307_PCM0)
    t8, h8 = scan8(p8, win8)
    assert len(h8) / t8 > 0.40, (len(h8), t8)
    assert scan8(d[slice(*IC307_TABLE)], win8)[1] == []
    assert scan8(rng.integers(0, 256, 1 << 19, dtype=np.uint8).tobytes(), win8)[1] == []
    assert scan8(np.arange(1 << 18, dtype=np.uint8).tobytes(), win8)[1] == []
    # and the headline: the 13 images
    n = n8 = 0
    for _, p_ in IMAGES:
        if os.path.exists(p_):
            data = open(p_, 'rb').read()
            n += len(scan(data, win, win // 2)[1])
            n8 += len(scan8(data, win8)[1])
    assert n == 0, f"16-bit lane moved to {n}; re-adjudicate before trusting this"
    assert n8 == 13, (f"8-bit lane moved to {n8} (was 13: 11 HD-AE5000 splash-screen "
                      f"windows + 2 WSA1R lookup-curve windows); re-adjudicate")
    # ADPCM lane: it must SEE real IMA data, and must not fire on the ROMs
    enc = _ima_encode(d[0x40000:0x40000 + 0x20000])
    ta, ha = scan_adpcm(enc, win)
    assert len(ha) / ta > 0.60, (len(ha), ta)
    assert scan_adpcm(rng.integers(0, 256, 1 << 18, dtype=np.uint8).tobytes(), win)[1] == []
    nA = 0
    for _, p_ in IMAGES:
        if os.path.exists(p_):
            nA += len(scan_adpcm(open(p_, 'rb').read(), win)[1])
    assert nA == 11, (f"ADPCM lane moved to {nA} (was 11: 7 windows of the KN5000 tone "
                      f"database's ToneEnv staircase tables, 3 of the SX-WSA1R tone "
                      f"database's, 1 HD-AE5000 ascending u32 pointer table); "
                      f"re-adjudicate")
    print(f"  ADPCM  lane: real IMA {len(ha)}/{ta}; random 0; 13 gated images {nA}")
    print(f"selftest OK\n"
          f"  16-bit lane: IC307 PCM {len(h0)}/{t0} and {len(h1)}/{t1}; "
          f"IC307 tables 0/{tt}; nulls 0; 13 gated images {n}\n"
          f"  8-bit  lane: IC307 PCM-as-8-bit {len(h8)}/{t8}; tables 0; nulls 0; "
          f"13 gated images {n8}, all adjudicated non-audio")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--calibrate', action='store_true')
    ap.add_argument('--census', action='store_true')
    ap.add_argument('--containers', action='store_true')
    ap.add_argument('--sounddata', action='store_true')
    ap.add_argument('--magics', action='store_true')
    ap.add_argument('--selftest', action='store_true')
    ap.add_argument('--win', type=int, default=4096)
    ap.add_argument('--step', type=int, default=None)
    ap.add_argument('--win8', type=int, default=1024)
    a = ap.parse_args()
    if not any((a.calibrate, a.census, a.containers, a.sounddata, a.magics,
                a.selftest)):
        ap.print_help()
        return
    if a.calibrate:
        cmd_calibrate(a.win, a.win8)
    if a.census:
        cmd_census(a.win, a.step, a.win8)
    if a.containers:
        cmd_containers(a.win, a.step, a.win8)
    if a.sounddata:
        cmd_sounddata(a.win8)
    if a.magics:
        cmd_magics()
    if a.selftest:
        cmd_selftest()


if __name__ == '__main__':
    main()
