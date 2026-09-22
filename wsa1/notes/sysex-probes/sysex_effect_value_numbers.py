#!/usr/bin/env python3
"""Is an effect's VALUE list the same thing as its list of parameter NAMES?

QUESTION IT ANSWERS
  `effects.json` says of its `values` list: "the order of the VALUE1..VALUEn
  bytes of an effect block", and the chapter repeats it -- "the first name is
  VALUE1, the second VALUE2, and so on".  `conversion_tables.json` says
  something that cannot both be true: its packings 17 and 18 have three named
  PEQ fields sharing TWO bytes.

  The guide settles it, because every DSP EFFECT page prints the answer.  Each
  page's parameter table has a MIDI column pair, "DATA" and "VALUE", and the
  VALUE column gives each row's byte number outright.  It is not 1:1 with the
  names in either direction:

    PARAMETRIC EQ (p16)       BAND EMPHASIS 1 Fc  ...  *6   (blank)
                              BAND EMPHASIS 1 Q   ...  *7   1,2
                              BAND EMPHASIS 1 G   ...  *8   *17
                              ... six bands the same way ...
                              VOLUME              ...  <-   13
      -> three names per band, TWO bytes per band, and `*17` naming the
         packing.  PARAMETRIC EQ is 13 VALUE bytes, not 19.

    SINGLE DELAY (p10)        DELAY L  0 - 350ms  <-  2,3
                              DELAY R  0 - 350ms  <-  4,5
      -> one name, TWO bytes.  SINGLE DELAY is 9 VALUE bytes, not 7.

  So `conversion_tables.json` is right and `effects.json`'s sentence is wrong,
  and the error is wider than the PEQ: any parameter the guide numbers "a,b"
  spans two bytes, and every VALUE number after it shifts.

WHAT THIS SCRIPT IS
  The VALUE column, transcribed off all thirty DSP EFFECT pages (3-32, rendered
  at 200 dpi -- they are image-only), held here beside `effects.json` so the two
  can be compared mechanically.  Each row is (name, as-printed VALUE text):

      ""      the guide leaves the cell blank (the first row of a packed group)
      "13"    one byte
      "2,3"   this one name occupies two bytes
      "*17"   this row shares the bytes above, per the guide's table 17

SELF-CHECK
  The transcription is not trusted either.  For each effect the numbers
  mentioned must be exactly 1..N, each used once, in ascending order.  A digit
  misread almost always breaks that, and the assertion names the effect.

COVERAGE, STATED
  All 56 effects, every DSP EFFECT page in the guide -- not a sample.  What is
  NOT checked is the NAMES: nothing independent states them (see
  sysex_effects.py), so a misread name survives here exactly as it does there.
  This compares the two files' name lists to each other and reports where they
  differ; it cannot say which is right.

SIGNAL BEING READ
  `effects.json` (names and order) against the table below (names and printed
  VALUE numbers).  The pages each row came from are named in PAGES.

RUN
  python3 wsa1/notes/sysex-probes/sysex_effect_value_numbers.py
  python3 wsa1/notes/sysex-probes/sysex_effect_value_numbers.py --all

PASS CRITERION
  Every effect's numbering is 1..N with no gap or repeat, every effect fits in
  the twenty VALUE bytes a block carries, and the two files' name lists agree.
  Exits non-zero while `effects.json` still equates names with bytes.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CATALOGUE = os.path.join(HERE, "effects.json")

MAX_VALUES = 20        # an effect block carries VALUE1..VALUE20

# Which guide page each effect's table was read from.
PAGES = {
    0: 3, 16: 3, 17: 3, 18: 4, 19: 4, 20: 4, 21: 4, 22: 5, 23: 5, 24: 5, 25: 5,
    26: 6, 27: 6, 1: 6, 2: 7, 3: 7, 4: 8, 5: 9, 6: 9, 8: 10, 9: 10, 10: 11,
    11: 12, 32: 12, 33: 13, 34: 13, 35: 14, 36: 14, 37: 15, 38: 15, 39: 16,
    48: 17, 49: 17, 50: 18, 51: 18, 52: 19, 53: 20, 54: 21, 55: 21, 56: 22,
    64: 23, 65: 24, 66: 24, 67: 25, 68: 25, 69: 26, 70: 26, 71: 27, 72: 28,
    73: 29, 74: 30, 75: 30, 96: 31, 97: 31, 98: 32, 99: 32,
}


def seq(names, first=1):
    """The common case: one byte per name, numbered consecutively."""
    return [(n, str(first + i)) for i, n in enumerate(names)]


def peq(bands, first_byte=1):
    """A PEQ block of `bands` bands, as the guide prints it: per band a blank
    cell, then a pair, then *17.  Returns the rows and the next free byte."""
    rows, b = [], first_byte
    for i in range(bands):
        tag = "" if bands == 1 else " %d" % (i + 1)
        rows += [("BAND EMPHASIS%s Fc" % tag, ""),
                 ("BAND EMPHASIS%s Q" % tag, "%d,%d" % (b, b + 1)),
                 ("BAND EMPHASIS%s G" % tag, "*17")]
        b += 2
    return rows, b


def delay_pair(name, b):
    return [(name, "%d,%d" % (b, b + 1))], b + 2


REVERB = seq(["REVERB TIME", "PRE DELAY", "HIGH DUMP GAIN",
              "EARLY REFL LEVEL", "VOLUME"])
DIST = seq(["WET", "DRIVE", "ADJUST", "VOLUME"])


def single_delay(first_name, b, stereo_pairs=True):
    """DELAY WET, DELAY L, DELAY R, FEEDBACK L, FEEDBACK R as the guide numbers
    them.  `stereo_pairs` is False only for effect 65, whose two delays are
    0-180ms and take one byte each."""
    rows = [(first_name, str(b))]
    b += 1
    for nm in ("DELAY L", "DELAY R"):
        if stereo_pairs:
            more, b = delay_pair(nm, b)
            rows += more
        else:
            rows.append((nm, str(b)))
            b += 1
    for nm in ("FEEDBACK L", "FEEDBACK R"):
        rows.append((nm, str(b)))
        b += 1
    return rows, b


def build():
    t = {}
    t[0] = []
    t[1] = seq(["WET", "DEPTH", "LFO SPEED", "LFO WAVEFORM", "VOLUME"])
    t[2] = seq(["WET", "DEPTH", "SLOW LFO SPEED", "FAST LFO SPEED",
                "FAST LFO BALANCE", "LFO WAVEFORM", "VOLUME"])
    rows = seq(["WET", "MANUAL", "LOW MIX", "HIGH MIX"])
    b = 5
    for nm in ("DELAY TIME L", "DELAY TIME R"):
        more, b = delay_pair(nm, b)
        rows += more
    t[3] = rows + [("VOLUME", str(b))]
    t[4] = seq(["WET", "DEPTH", "LFO SPEED", "RESONANCE", "MANUAL", "PHASE",
                "LFO WAVEFORM", "VOLUME"])
    t[5] = list(t[4])
    t[6] = seq(["WET", "DEPTH", "LFO SPEED", "LFO WAVEFORM", "VOLUME"])
    t[8] = seq(["WET", "GATE TIME", "HIGH DUMP GAIN", "THRESHOLD", "MASK TIME",
                "VOLUME"])
    rows, b = single_delay("WET", 1)
    t[9] = rows + seq(["HIGH DUMP GAIN", "VOLUME"], b)
    rows, b = [("WET", "1")], 2
    for i in range(1, 5):
        more, b = delay_pair("DELAY %d" % i, b)
        rows += more
    t[10] = rows + seq(["PAN 1", "PAN 2", "PAN 3", "PAN 4", "FEED BACK",
                        "HIGH DUMP GAIN", "VOLUME"], b)
    rows, b = [("WET", "1"), ("MODULATION DEPTH", "2")], 3
    for nm in ("DELAY L", "DELAY R"):
        more, b = delay_pair(nm, b)
        rows += more
    t[11] = rows + seq(["FEEDBACK L", "FEEDBACK R", "HIGH DUMP GAIN",
                        "VOLUME"], b)
    for n in range(16, 28):
        t[n] = list(REVERB)
    t[32] = list(DIST)
    t[33] = list(DIST)
    t[34] = list(DIST)
    rows, b = seq(["WET", "DRIVE", "ADJUST"]), 4
    more, b = delay_pair("EMPHASIS Fc", b)          # guide's table 18
    t[35] = rows + more + seq(["EMPHASIS GAIN", "VOLUME"], b)
    t[36] = seq(["WET", "THRESHOLD", "RATIO", "ATTACK SENSITIVITY",
                 "RELEASE SENSITIVITY", "VOLUME"])
    t[37] = seq(["WET", "THRESHOLD", "ATTACK RATE", "RELEASE RATE", "VOLUME"])
    t[38] = [("VOLUME", "1")]
    rows, b = peq(6)
    t[39] = rows + [("VOLUME", str(b))]
    t[48] = seq(["WET", "DEPTH", "LFO SPEED", "PHASE", "LFO WAVEFORM",
                 "VOLUME"])
    t[49] = seq(["WET", "PITCH L", "PITCH R", "PRE DELAY", "FEEDBACK",
                 "VOLUME"])
    t[50] = list(t[48])
    t[51] = seq(["WET", "RESONANCE", "MANUAL", "SWEEP RANGE", "WAH CENTER Fc",
                 "VOLUME"])
    t[52] = seq(["WET", "RESONANCE", "MANUAL", "SWEEP RANGE", "VOLUME"])
    t[53] = seq(["WET", "DRIVE", "VOLUME ADJUST", "TREBLE DEPTH", "TREBLE FAST",
                 "TREBLE SLOW", "TREBLE WIND UP", "TREBLE WIND DOWN",
                 "BASS DEPTH", "BASS FAST", "BASS SLOW", "BASS WIND UP",
                 "BASS WIND DOWN", "VOLUME", "SLOW/FAST"])
    t[54] = seq(["WET", "OSC SPEED", "PHASE", "OSC WAVEFORM", "VOLUME"])
    rows, b = [("WET", "1")], 2
    for nm in ("DELAY TIME L", "DELAY TIME R"):
        more, b = delay_pair(nm, b)
        rows += more
    t[55] = rows + seq(["BALANCE L", "BALANCE R", "VOLUME"], b)
    t[56] = seq(["WET", "DEPTH", "SLOW LFO SPEED", "FAST LFO SPEED L",
                 "FAST LFO SPEED R", "PHASE", "LFO WAVEFORM", "VOLUME"])

    rows, b = single_delay("DELAY WET", 1)
    t[64] = rows + seq(["CHORUS DRY/WET", "DEPTH", "LFO SPEED", "LFO WAVEFORM",
                        "VOLUME"], b)
    rows, b = single_delay("DELAY 1 WET", 1, stereo_pairs=False)
    more, b = single_delay("DELAY 2 DRY/WET", b, stereo_pairs=False)
    t[65] = rows + more + [("VOLUME", str(b))]
    rows, b = single_delay("DELAY WET", 1)
    t[66] = rows + seq(["FLANGER DRY/WET", "DEPTH", "LFO SPEED", "RESONANCE",
                        "MANUAL", "PHASE", "LFO WAVEFORM", "VOLUME"], b)
    rows, b = single_delay("DELAY WET", 1)
    t[67] = rows + seq(["VIBRATO DRY/WET", "DEPTH", "LFO SPEED", "PHASE",
                        "LFO WAVEFORM", "VOLUME"], b)
    rows, b = single_delay("DELAY WET", 1)
    t[68] = rows + seq(["PHASER DRY/WET", "DEPTH", "LFO SPEED", "RESONANCE",
                        "MANUAL", "PHASE", "LFO WAVEFORM", "VOLUME"], b)
    rows = seq(["WAH WET", "RESONANCE", "MANUAL", "SWEEP RANGE",
                "WAH CENTER Fc"])
    more, b = single_delay("DELAY DRY/WET", 6)
    t[69] = rows + more + [("VOLUME", str(b))]
    rows = seq(["WAH WET", "RESONANCE", "MANUAL", "SWEEP RANGE"])
    more, b = single_delay("DELAY DRY/WET", 5)
    t[70] = rows + more + [("VOLUME", str(b))]

    rows, b = peq(2)
    t[71] = rows + seq(["CHORUS DRY/WET", "DEPTH", "LFO SPEED", "LFO WAVEFORM",
                        "VOLUME"], b)
    rows, b = peq(2)
    more, b = single_delay("DELAY DRY/WET", b)
    t[72] = rows + more + [("VOLUME", str(b))]
    rows, b = peq(2)
    t[73] = rows + seq(["FLANGER DRY/WET", "DEPTH", "LFO SPEED", "RESONANCE",
                        "MANUAL", "PHASE", "LFO WAVEFORM", "VOLUME"], b)
    rows, b = peq(2)
    t[74] = rows + seq(["VIBRATO DRY/WET", "DEPTH", "LFO SPEED", "PHASE",
                        "LFO WAVEFORM", "VOLUME"], b)
    rows, b = peq(2)
    t[75] = rows + seq(["THRESHOLD", "RATIO", "ATTACK SENSITIVITY",
                        "RELEASE SENSITIVITY", "VOLUME"], b)
    rows, b = peq(2)
    t[96] = rows + seq(["THRESHOLD", "RATIO", "ATTACK SENSITIVITY",
                        "RELEASE SENSITIVITY", "DRIVE", "ADJUST", "VOLUME"], b)
    rows, b = peq(1)
    t[97] = rows + seq(["THRESHOLD", "RATIO", "ATTACK SENSITIVITY",
                        "RELEASE SENSITIVITY", "DRIVE", "ADJUST", "VOLUME"], b)
    rows, b = peq(2)
    rows += seq(["DRIVE", "ADJUST"], b)
    more, b = single_delay("DELAY DRY/WET", b + 2)
    t[98] = rows + more + [("VOLUME", str(b))]
    rows, b = peq(2)
    rows += seq(["DRIVE", "ADJUST"], b)
    more, b = single_delay("DELAY DRY/WET", b + 2)
    t[99] = rows + more + [("VOLUME", str(b))]
    return t


def numbers(rows):
    out = []
    for _, text in rows:
        out += [int(x) for x in re.findall(r"\d+", text) if not text.startswith("*")]
    return out


def main():
    show_all = "--all" in sys.argv
    guide = build()
    cat = {e["prog"]: e for e in json.load(open(CATALOGUE))["effects"]}

    assert set(guide) == set(cat), \
        "effect number sets differ: %s" % (set(guide) ^ set(cat))

    bad = []
    print("\nVALUE NUMBERING, as the guide's MIDI VALUE column prints it")
    print("  %-4s %-30s %5s %5s  %s" % ("no.", "effect", "names", "bytes", "page"))
    for prog in sorted(guide):
        rows = guide[prog]
        nums = numbers(rows)
        assert nums == list(range(1, len(nums) + 1)), \
            "effect %d: VALUE numbers are %s, not 1..N" % (prog, nums)
        n_bytes = len(nums)
        assert n_bytes <= MAX_VALUES, \
            "effect %d needs %d VALUE bytes, a block carries %d" \
            % (prog, n_bytes, MAX_VALUES)

        names_guide = [n for n, _ in rows]
        names_json = cat[prog]["values"]
        n_names = len(names_guide)
        # The claim under test: name i is VALUEi.  It fails whenever a row is
        # blank, is a pair, or is a *17 -- and the counts can still coincide.
        one_to_one = all(text == str(i + 1) for i, (_, text) in enumerate(rows))
        differs = n_bytes != n_names
        name_clash = names_guide != names_json
        if not one_to_one or name_clash:
            bad.append((prog, cat[prog]["guide_name"], n_names, n_bytes,
                        names_guide, names_json))
        if show_all or not one_to_one or name_clash:
            note = ""
            if differs:
                note = "   <-- differ"
            elif not one_to_one:
                note = "   <-- same count, different mapping"
            print("  %-4d %-30s %5d %5d  p%d%s"
                  % (prog, cat[prog]["guide_name"], n_names, n_bytes,
                     PAGES[prog], note))

    print("\n%d of %d effects have more VALUE bytes or fewer than they have "
          "names; %d more have the same count but a different mapping."
          % (sum(1 for b in bad if b[2] != b[3]), len(guide),
             sum(1 for b in bad if b[2] == b[3])))

    clashes = [b for b in bad if b[4] != b[5]]
    if clashes:
        print("\nNAME LISTS THAT DIFFER (neither source is checked; see the "
              "docstring)")
        for prog, name, _, _, g, j in clashes:
            print("  %d %s" % (prog, name))
            print("      guide p%d : %s" % (PAGES[prog], ", ".join(g)))
            print("      effects  : %s" % ", ".join(j))

    if bad:
        print("\neffects.json's \"values is the order of the VALUE1..VALUEn "
              "bytes\" does not hold.")
        return 1
    print("\nOK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
