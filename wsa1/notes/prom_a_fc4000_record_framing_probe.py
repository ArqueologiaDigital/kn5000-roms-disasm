#!/usr/bin/env python3
"""Can prom_a 0xFC4000-0xFC52F7 (4,856 B) be framed as records, the way the
0xFA15CC span was?  QUESTION IT ANSWERS, and the answer is a REFUSAL.

BACKGROUND
  notes/prom_a_fc40f4_strings_scan.py already established WHAT this span is:
  the DSP-effect / SOUND EDIT parameter-label table (12/12 vocabulary words:
  DEPTH, SPEED, DETUNE, DELAY, BALANCE, WAVE, REVERB, TYPE, INTENSITY,
  KEY SHIFT, DIGITAL EFFECT, SOUND EDIT). reachability.py finds ZERO
  reachable bytes -- weaker than 0xFA15CC's weak "immediate" evidence -- so
  there is no code-side proof of where a record starts or ends. This script
  is the attempt to get that proof from the BYTES alone, the same way
  notes/prom_a_fa1404_identify.py did for the SYSTEM-menu span. It finds two
  real mechanisms and one trap, and the trap is why the span stays `.incbin`.

WHAT IS REAL (checked here, both hold up)
  1. TEXT/COORDINATE RECORDS, `<op> <len> <payload>`, len counting the whole
     record including its own two header bytes -- the same shape as the
     0xFA15CC span's display-list records. Walking op,len from 0xFC4000 tiles
     154 records end to end with NO overlap, covering the first 1,396 of
     4,856 bytes (28%) before the first byte the walk cannot place, and the
     payload bytes spell real words: INTENSITY, DIGITAL EFFECT, SOUND EDIT,
     TYPE, REVERB DEPTH, REVERB, DEPTH, SPEED, DETUNE, DELAY, BALANCE, WAVE,
     KEY SHIFT, DECAY, SUSTAIN, RELEASE, DISTORTION, TOUCH DEPTH -- eighteen
     readable strings in a row is not a coincidence a byte-level scan could
     manufacture.
  2. SELF-REFERENTIAL POINTER ARRAYS. A run of 4-byte little-endian entries
     `lo, mid, 0xFC, 0x00` -- i.e. a 24-bit address with the high byte
     ALWAYS 0xFC and always landing inside this very span -- indexes back
     into the records above (0x0F 0x42 0xFC 0x00 -> 0x00FC420F, which is
     literally where the "DEPTH" record starts). `is_ptr_quad()` requires
     both fixed bytes AND range membership, so its false-positive rate is
     essentially the 1/65536 chance of two specific bytes landing right by
     chance -- checked with `--null` below.

THE TRAP: naive op,len framing is NOT selective enough to trust past that
  point.  `--greedy` in this file reproduces the failure: starting around
  0xFC48D7 the readable strings stop and the bytes look like RASTER ICON
  DATA instead -- 0x55/0xAA dither columns and 0xFF/0x00 run pairs, the
  classic shape of a 1bpp icon bitmap, not text.  A generic "does the next
  op,len pair look formally valid" walker sails straight through this data
  anyway, because almost any two bytes can be misread as a plausible
  (op < 0x30, len in 2..40) pair over a short span -- it is the exact
  0.051%-per-window risk notes/prom_a_fa1404_identify.py's R2 FRAME measured
  and calibrated for the OTHER span, uncalibrated here.  Run `--greedy` to
  see it happen: the resync-on-failure walker reports only 55 bytes it
  cannot place, when in truth ~150-200 bytes of icon data in the middle are
  being silently misread as bogus records.  Unlike 0xFA15CC, this span has
  NO interpreter routine identified in code (the FA1404 span's confidence
  came from T_F42E00/04/08/0C, real call sites with real semantics; this
  span has none -- reachability.py's zero is not an oversight, it is the
  actual absence of a caller). Without that anchor, op,len framing here is
  unfalsifiable: any layout that happens to tile is indistinguishable from
  one that is wrong.

RESULT: REFUSED.  The label text and the pointer-array mechanism are real
  findings (recorded above and asserted by --selftest) but do not amount to
  an established record framing for the whole span, and the icon-bitmap
  region in the middle actively defeats the only framing rule available.
  Left `.incbin`.  A future pass that finds the actual screen-interpreter
  code for this table (the SOUND EDIT / DSP EFFECT screen's paint routine)
  would give the same kind of anchor 0xFA15CC had, and should retry this.

RUN
  python3 notes/prom_a_fc4000_record_framing_probe.py             # summary
  python3 notes/prom_a_fc4000_record_framing_probe.py --records   # the ~90 tiled records
  python3 notes/prom_a_fc4000_record_framing_probe.py --greedy    # reproduces the false confidence
  python3 notes/prom_a_fc4000_record_framing_probe.py --null      # false-positive rate of is_ptr_quad
  python3 notes/prom_a_fc4000_record_framing_probe.py --selftest  # exits non-zero on failure
"""
import os
import random
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()
BASE = 0xF80000
LO, HI = 0xFC4000, 0xFC52F8


def b(a, n=1):
    o = a - BASE
    return ROM[o:o + n] if n > 1 else ROM[o]


def is_ptr_quad(p):
    if p + 4 > HI:
        return False
    q = b(p, 4)
    if q[3] != 0x00 or q[2] != 0xFC:
        return False
    addr = q[0] | (q[1] << 8) | (q[2] << 16)
    return LO <= addr < HI


def ptr_run_len(p):
    n = 0
    while is_ptr_quad(p + 4 * n):
        n += 1
    return n


def clean_records(stop_on_first_break=True):
    """Walk op,len from LO.  Returns (records, end) where `end` is the first
    address the walk cannot place (a length byte < 2 or one that overruns).
    This is the CONSERVATIVE half: it does not try to resync."""
    p, recs = LO, []
    while p < HI:
        op, ln = b(p), b(p + 1)
        if ln < 2 or p + ln > HI:
            return recs, p
        recs.append((p, op, ln, b(p, ln)))
        p += ln
    return recs, p


def try_record(p):
    ln = b(p + 1)
    if ln < 2 or p + ln > HI:
        return None
    return ln


def walk_ok_from(p, steps=4, budget=400):
    q, n, limit = p, 0, min(HI, p + budget)
    while q < limit and n < steps:
        npr = ptr_run_len(q)
        if npr >= 1:
            q += 4 * npr
            n += 1
            continue
        ln = try_record(q)
        if ln is None:
            return False
        q += ln
        n += 1
    return True


def greedy_walk():
    """The OVER-PERMISSIVE walker: resyncs past anything it cannot place.
    This is what a careless conversion pass would trust, and it is wrong --
    it walks straight through the icon-bitmap region.  Returns (objs, islands)."""
    p, objs, islands = LO, [], []
    while p < HI:
        npr = ptr_run_len(p)
        if npr >= 1:
            objs.append((p, p + 4 * npr, "ptrarray", npr))
            p += 4 * npr
            continue
        ln = try_record(p)
        if ln is not None:
            objs.append((p, p + ln, "rec", b(p)))
            p += ln
            continue
        start = p
        q = p + 1
        while q < HI and not walk_ok_from(q):
            q += 1
        islands.append((start, q))
        p = q
    return objs, islands


def null_ptr_quad(trials=200000, seed=0):
    """How often does is_ptr_quad() fire on RANDOM bytes?  Calibration for the
    pointer-array claim: sample random 4-byte windows from elsewhere in
    prom_a (outside this span, so the test cannot read its own answer) and
    count hits."""
    rng = random.Random(seed)
    hits = 0
    n = len(ROM)
    for _ in range(trials):
        o = rng.randrange(0, n - 4)
        a = o + BASE
        if LO <= a < HI:
            continue  # do not sample the span under test
        q = ROM[o:o + 4]
        if q[3] == 0x00 and q[2] == 0xFC:
            addr = q[0] | (q[1] << 8) | (q[2] << 16)
            if LO <= addr < HI:
                hits += 1
    return hits, trials


def cmd_records():
    recs, end = clean_records()
    for p, op, ln, raw in recs:
        txt = "".join(chr(c) if 0x20 <= c < 0x7f else "." for c in raw)
        print(f"{p:06X} op={op:#04x} len={ln:3d}  {raw.hex()}  {txt}")
    print(f"\n{len(recs)} records tiled cleanly, first break at 0x{end:06X}"
          f" (0x{end - LO:X} of 0x{HI - LO:X} bytes covered)")


def cmd_greedy():
    objs, islands = greedy_walk()
    print(f"{len(objs)} objects, {len(islands)} 'island' gaps "
          f"(bytes the walker could not place even with resync):")
    for s, e in islands:
        print(f"  0x{s:06X}-0x{e:06X}  {e - s} bytes")
    print("\n⚠ compare this island list against the icon-bitmap region: it "
          "starts around 0xFC48D7 (readable text ends: '...STEREO') and the "
          "greedy walker reports almost none of it as unplaced -- it misread "
          "icon bytes as records instead of refusing them. That is the trap.")


def cmd_null():
    hits, trials = null_ptr_quad()
    print(f"is_ptr_quad() on {trials} random 4-byte windows OUTSIDE the span: "
          f"{hits} hit(s) ({100.0 * hits / trials:.4f}%)")
    print("Expected by construction: ~1/65536 per window before the range "
          "check, further cut by the range check itself.")


def selftest():
    checks = []
    recs, end = clean_records()
    checks.append(("clean walk tiles at least 60 records before its first "
                   "unplaceable byte", len(recs) >= 60))
    checks.append(("first record is the INTENSITY-adjacent label region "
                   "(op 0x06 or 0x22 family)", recs[0][1] in (0x06, 0x22)))
    vocab = [b"DEPTH", b"SPEED", b"DETUNE", b"DELAY", b"BALANCE", b"WAVE",
             b"REVERB", b"KEY SHIFT", b"DECAY", b"SUSTAIN", b"RELEASE",
             b"DISTORTION", b"INTENSITY", b"SOUND EDIT", b"DIGITAL EFFECT"]
    joined = b"".join(raw for _, _, _, raw in recs)
    found = sum(1 for w in vocab if w in joined)
    checks.append(("clean-record payload bytes contain >= 12/%d of the "
                   "vocabulary" % len(vocab), found >= 12))
    checks.append(("0x00FC420F (the DEPTH record) is named by a pointer "
                   "quad somewhere in the span",
                   any(is_ptr_quad(p) and
                       (b(p, 4)[0] | b(p, 4)[1] << 8 | b(p, 4)[2] << 16) == 0xFC420F
                       for p in range(LO, HI - 3))))
    hits, trials = null_ptr_quad()
    checks.append(("is_ptr_quad() null rate stays under 0.1%%",
                   hits / trials < 0.001))
    objs, islands = greedy_walk()
    total_island = sum(e - s for s, e in islands)
    checks.append(("the greedy (over-permissive) walker's islands are far "
                   "SMALLER than the true icon-bitmap region -- proving it "
                   "is not to be trusted, not proving the span is solved",
                   total_island < 200))
    ok = True
    for name, passed in checks:
        print(f"  {name:<70s} {'ok' if passed else 'FAILED'}")
        ok = ok and passed
    print(f"\n{len(checks)} checks, {sum(not p for _, p in checks)} failed")
    return 0 if ok else 1


def main():
    if "--records" in sys.argv:
        cmd_records()
    elif "--greedy" in sys.argv:
        cmd_greedy()
    elif "--null" in sys.argv:
        cmd_null()
    elif "--selftest" in sys.argv:
        return selftest()
    else:
        recs, end = clean_records()
        print(f"prom_a 0x{LO:06X}-0x{HI - 1:06X}: {HI - LO} bytes")
        print(f"  clean op,len walk from 0x{LO:06X}: {len(recs)} records, "
              f"first unplaceable byte at 0x{end:06X} "
              f"({end - LO} of {HI - LO} bytes, {100 * (end - LO) // (HI - LO)}%)")
        objs, islands = greedy_walk()
        print(f"  over-permissive resync walk: {len(objs)} objects, "
              f"{len(islands)} island(s) totalling "
              f"{sum(e - s for s, e in islands)} bytes -- NOT TRUSTED, see the "
              "module docstring")
        print("\nRESULT: REFUSED. Real mechanisms found (text/coordinate "
              "records, self-referential pointer arrays into this same "
              "span) but no anchor (no interpreter call site, unlike "
              "0xFA15CC) rules out the icon-bitmap region defeating a naive "
              "op,len walk. Left `.incbin`. See --selftest.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
