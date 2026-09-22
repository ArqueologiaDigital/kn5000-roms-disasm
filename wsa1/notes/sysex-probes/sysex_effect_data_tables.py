#!/usr/bin/env python3
"""Which conversion table turns each effect parameter's byte into a quantity?

QUESTION IT ANSWERS
  Chapter "Effects" of the reference gives 16 tables that turn an effect's
  VALUE byte into hertz, seconds, decibels or cents, plus three packings.  What
  it could not give was WHICH table applies to WHICH parameter: 435 parameters,
  and `effects.json` and `conversion_tables.json` between them say nothing that
  connects the two.

  The guide does say it, on every DSP EFFECT page, and it had simply not been
  read.  Each page's parameter table carries a MIDI column PAIR -- "DATA" and
  "VALUE" -- and it is the DATA column, not the VALUE column, that names the
  conversion:

      PARAMETRIC EQ (p16)      BAND EMPHASIS 1 Fc  50 Hz - 16 kHz   *6   (blank)
                               BAND EMPHASIS 1 Q   0.1   - 20       *7   1,2
                               BAND EMPHASIS 1 G   -12   - +12 dB   *8   *17
                               VOLUME              0     - 99        <-   13

  `*6` means table 6.  `<-` is an arrow pointing back at the range columns and
  means the parameter needs no table: the range printed to its left IS the
  quantity.  The page footer says so outright -- "(*1 ~ *18 : Refer to page33)"
  -- and page 33 is where all 16 tables and 3 packings are printed.

  So the assignment was never missing.  This file is the DATA column of all
  thirty DSP EFFECT pages (3-32), transcribed, which closes it for all 435.

WHAT IS TRANSCRIBED, AND WHAT IS DERIVED
  DATA below is the LITERAL cell, per effect, in the order `effects.json`
  prints the names.  Nothing in it is inferred from a neighbouring effect.

  RULE is a separate, DERIVED claim: that a parameter's table is a function of
  its NAME alone.  The two are compared, and every disagreement is printed.
  That is the check with teeth -- 435 cells against a 30-line rule -- and it is
  what turned up the anomalies below.  A disagreement is NOT silently
  reconciled in either direction.

WHAT IT FOUND
  Two anomalies, both the guide's, neither affecting an address:

  * Effect 71, PEQ + CHORUS (p27): LFO SPEED's DATA cell is `<-`, where the
    same parameter with the same 0-40.2 range is `*3` on all eleven other pages
    that carry it -- and on p27 alone the "Hz" is missing from its range too.
    Both marks were dropped from the one row.

  * Effect 74, PEQ + VIBRATO (p30): the RANGE column slips down one row for
    three rows.  DEPTH is printed "0 - 99Hz", LFO SPEED "0 - 40.2degree" and
    PHASE "0 - 180" with no unit.  The units belong to the row above each.  The
    DATA cells are unaffected and correct (*3 on LFO SPEED).

POSITIVE CONTROL
  The rule reproduces 425 cells, disagrees on 1, and declines to judge 9 (every
  parameter named RESONANCE -- two different things share that name).  A run in
  which it reproduced none, or all, would mean the comparison is not running;
  all three counts are printed and a zero-agreement run asserts.  The
  name lists are also checked against `effects.json` element by element, so a
  transcription that slipped a row fails loudly rather than shifting a table
  assignment onto the wrong parameter.

COVERAGE, STATED
  All 56 effects, every DSP EFFECT page, not a sample.  What this does NOT
  check is the tables themselves (sysex_conversion_tables.py does that) or the
  parameter NAMES, which nothing independent states -- a misread name survives
  here exactly as it does in `effects.json`.

HOW TO REGENERATE THE PAGES THIS WAS READ FROM
  The guide is image-only, so it has to be rendered before it can be read.  The
  PNGs are a large regenerable corpus and are deliberately NOT committed; this
  is the recipe, and it is the only thing that needs to survive.

      python3 wsa1/notes/sysex-probes/manual_reference_guide.py   # checks the
          # OM.zip sha256 and extracts OM/EN/TECHNICS_WSA1_REFERENCE_GUIDE_2.pdf
      pdftoppm -r 200 -png -f 3 -l 33 <the pdf> pg    # pg-03.png .. pg-33.png

  Page N of the PDF is page N of the guide: the printed folio at the foot of
  each page matches, checked on p16 (PARAMETRIC EQ, "EFFECT No.; 39") and p33
  (the conversion tables).  150 dpi is enough to read the DATA and VALUE
  columns; 200 dpi is enough to read the ranges beside them.

SIGNAL BEING READ
  OM.zip -> OM/EN/TECHNICS_WSA1_REFERENCE_GUIDE_2.pdf, pages 3-32, rendered at
  150-200 dpi (they are image-only), MIDI/DATA column.

RUN
  python3 wsa1/notes/sysex-probes/sysex_effect_data_tables.py
  python3 wsa1/notes/sysex-probes/sysex_effect_data_tables.py --json

PASS CRITERION
  Every effect's cell count equals its name count in `effects.json`; every
  table named exists in `conversion_tables.json`; the derived rule reproduces
  at least one cell; and the set of disagreements is exactly {effect 71 LFO
  SPEED}, so a later edit that introduces or loses one fails.
"""

import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CATALOGUE = os.path.join(HERE, "effects.json")
TABLES = os.path.join(HERE, "conversion_tables.json")

# The DATA cell, as printed.  None is the `<-` arrow: no table, the range
# printed beside the parameter is the quantity.
D = None

REVERB = [1, D, 2, D, D]          # REVERB TIME, PRE DELAY, HIGH DUMP, ER, VOL
DIST = [D, D, D, D]               # WET, DRIVE, ADJUST, VOLUME


def peq(bands):
    """Fc, Q, G per band: tables 6, 7, 8."""
    return [6, 7, 8] * bands


DATA = {
    0: [],
    1: [D, D, 3, 4, D],
    2: [D, D, 3, 3, D, 4, D],
    3: [D, D, D, D, D, D, D],
    4: [D, D, 3, D, D, D, 4, D],
    5: [D, D, 3, D, D, D, 4, D],
    6: [D, D, 3, 4, D],
    8: [D, 5, 2, D, 5, D],
    9: [D, D, D, D, D, 2, D],
    10: [D, D, D, D, D, D, D, D, D, D, 2, D],
    11: [D, D, D, D, D, D, 2, D],
    16: REVERB, 17: REVERB, 18: REVERB, 19: REVERB,
    20: REVERB, 21: REVERB, 22: REVERB, 23: REVERB,
    24: REVERB, 25: REVERB, 26: REVERB, 27: REVERB,
    32: DIST, 33: DIST, 34: DIST,
    35: [D, D, D, "6,18", D, D],
    36: [D, D, D, 9, 9, D],
    37: [D, D, 10, 10, D],
    38: [D],
    39: peq(6) + [D],
    48: [D, D, 3, D, 4, D],
    49: [D, 14, 14, D, D, D],
    50: [D, D, 3, D, 4, D],
    51: [D, 15, D, D, D, D],
    52: [D, 15, D, D, D],
    53: [D, D, D, D, 11, 11, 12, 12, D, 11, 11, 12, 12, D, 16],
    54: [D, 13, D, 4, D],
    55: [D, D, D, D, D, D],
    56: [D, D, 3, 3, 3, D, 4, D],
    64: [D, D, D, D, D, D, D, 3, 4, D],
    65: [D] * 11,
    66: [D, D, D, D, D, D, D, 3, D, D, D, 4, D],
    67: [D, D, D, D, D, D, D, 3, D, 4, D],
    68: [D, D, D, D, D, D, D, 3, D, D, D, 4, D],
    69: [D, 15, D, D, D, D, D, D, D, D, D],
    70: [D, 15, D, D, D, D, D, D, D, D],
    #                                    v- the p27 anomaly: `<-`, not *3
    71: peq(2) + [D, D, D, 4, D],
    72: peq(2) + [D, D, D, D, D, D],
    73: peq(2) + [D, D, 3, D, D, D, 4, D],
    74: peq(2) + [D, D, 3, D, 4, D],
    75: peq(2) + [D, D, 9, 9, D],
    96: peq(2) + [D, D, 9, 9, D, D, D],
    97: peq(1) + [D, D, 9, 9, D, D, D],
    98: peq(2) + [D, D, D, D, D, D, D, D],
    99: peq(2) + [D, D, D, D, D, D, D, D],
}

PAGES = {
    0: 3, 16: 3, 17: 3, 18: 4, 19: 4, 20: 4, 21: 4, 22: 5, 23: 5, 24: 5, 25: 5,
    26: 6, 27: 6, 1: 6, 2: 7, 3: 7, 4: 8, 5: 9, 6: 9, 8: 10, 9: 10, 10: 11,
    11: 12, 32: 12, 33: 13, 34: 13, 35: 14, 36: 14, 37: 15, 38: 15, 39: 16,
    48: 17, 49: 17, 50: 18, 51: 18, 52: 19, 53: 20, 54: 21, 55: 21, 56: 22,
    64: 23, 65: 24, 66: 24, 67: 25, 68: 25, 69: 26, 70: 26, 71: 27, 72: 28,
    73: 29, 74: 30, 75: 30, 96: 31, 97: 31, 98: 32, 99: 32,
}

# DERIVED, and deliberately not used to build DATA: a parameter's table as a
# function of its name alone.  Compared against DATA cell by cell below.
RULE = {
    "REVERB TIME": 1,
    "HIGH DUMP GAIN": 2,
    "LFO SPEED": 3, "SLOW LFO SPEED": 3, "FAST LFO SPEED": 3,
    "FAST LFO SPEED L": 3, "FAST LFO SPEED R": 3,
    "LFO WAVEFORM": 4, "OSC WAVEFORM": 4,
    "GATE TIME": 5, "MASK TIME": 5,
    "ATTACK SENSITIVITY": 9, "RELEASE SENSITIVITY": 9,
    "ATTACK RATE": 10, "RELEASE RATE": 10,
    "TREBLE FAST": 11, "TREBLE SLOW": 11, "BASS FAST": 11, "BASS SLOW": 11,
    "TREBLE WIND UP": 12, "TREBLE WIND DOWN": 12,
    "BASS WIND UP": 12, "BASS WIND DOWN": 12,
    "OSC SPEED": 13,
    "PITCH L": 14, "PITCH R": 14,
    "SLOW/FAST": 16,
    "EMPHASIS Fc": "6,18",
}


def rule_for(name):
    """The name rule, including the two families that need a suffix match."""
    if name.startswith("BAND EMPHASIS"):
        if name.endswith(" Fc"):
            return 6
        if name.endswith(" Q"):
            return 7
        if name.endswith(" G"):
            return 8
    if name == "RESONANCE":
        # Two different parameters share the name.  A wah's RESONANCE is an
        # enumeration (wide/middle/narrow, table 15); a flanger's or phaser's
        # is a signed feedback with no table.  The name alone cannot say which,
        # which is why this returns the sentinel rather than a guess.
        return "ambiguous"
    return RULE.get(name)


def load():
    cat = {e["prog"]: e for e in json.load(open(CATALOGUE))["effects"]}
    tabs = json.load(open(TABLES))
    known = {t["n"] for t in tabs["tables"]}
    known |= {p["n"] for p in tabs["packings"] if p.get("n")}
    return cat, known


def rows(cat):
    """(prog, name, cell) for every parameter of every effect, in order."""
    for prog in sorted(DATA):
        names = cat[prog]["values"]
        cells = DATA[prog]
        assert len(cells) == len(names), (
            "effect %d: %d DATA cells transcribed but %d names in effects.json"
            % (prog, len(cells), len(names)))
        for name, cell in zip(names, cells):
            yield prog, name, cell


def render_json(cat):
    out = {
        "_comment": [
            "GENERATED by sysex_effect_data_tables.py --json.  The MIDI DATA",
            "column of the guide's DSP EFFECT pages 3-32, transcribed from",
            "renders of the image-only original.",
            "",
            "'table' names the conversion table of conversion_tables.json that",
            "turns this parameter's VALUE byte into a quantity.  null is the",
            "guide's `<-` arrow: no table, the printed range IS the quantity.",
            "'6,18' is table 6 read through packing 18.",
            "",
            "Two cells are anomalies in the guide and are transcribed as",
            "printed, not corrected: see 'anomalies'.",
        ],
        "effects": [],
        "anomalies": [
            {"prog": 71, "page": 27, "parameter": "LFO SPEED",
             "printed": "<-",
             "expected": 3,
             "why": ("every other LFO SPEED with the same 0-40.2 range prints "
                     "*3; on p27 alone the Hz is missing from the range too")},
            {"prog": 74, "page": 30, "parameter": "DEPTH / LFO SPEED / PHASE",
             "printed": "ranges read 0-99Hz, 0-40.2degree, 0-180",
             "expected": "0-99, 0-40.2Hz, 0-180degree",
             "why": ("the RANGE column slips down one row for three rows; the "
                     "DATA cells on those rows are correct")},
        ],
    }
    for prog in sorted(DATA):
        params = []
        for name, cell in zip(cat[prog]["values"], DATA[prog]):
            params.append({"name": name, "table": cell})
        out["effects"].append({
            "prog": prog,
            "guide_name": cat[prog]["guide_name"],
            "page": PAGES[prog],
            "parameters": params,
        })
    return json.dumps(out, indent=1)


def main():
    cat, known = load()
    assert set(DATA) == set(cat), \
        "effect number sets differ: %s" % (set(DATA) ^ set(cat))

    if "--json" in sys.argv:
        print(render_json(cat))
        return 0

    all_rows = list(rows(cat))
    print("\nDATA COLUMN, all %d parameters of all %d effects"
          % (len(all_rows), len(DATA)))

    for prog, name, cell in all_rows:
        if cell is None:
            continue
        for n in str(cell).split(","):
            assert int(n) in known, \
                "effect %d, %s: table *%s is not in conversion_tables.json" \
                % (prog, name, n)

    converted = [r for r in all_rows if r[2] is not None]
    print("  %d take a conversion table, %d are direct (the guide's `<-`)"
          % (len(converted), len(all_rows) - len(converted)))

    used = sorted({str(c) for _, _, c in converted},
                  key=lambda u: [int(x) for x in u.split(",")])
    print("  tables in use: %s" % ", ".join("*" + u for u in used))

    agree, ambiguous, disagree = 0, 0, []
    for prog, name, cell in all_rows:
        want = rule_for(name)
        if want == "ambiguous":
            ambiguous += 1
            continue
        if want == cell:
            agree += 1
        else:
            disagree.append((prog, name, cell, want))

    print("\nTHE NAME RULE against the transcription")
    print("  %d cells agree, %d disagree, %d the rule declines to judge"
          % (agree, len(disagree), ambiguous))
    assert agree, "the rule reproduced NOTHING -- the comparison is broken"

    if disagree:
        print("\n  where they differ (each is a finding, not a fix-up):")
        for prog, name, cell, want in disagree:
            print("    %-3d p%-2d %-20s printed %-6s rule says %s"
                  % (prog, PAGES[prog], name,
                     "<-" if cell is None else "*%s" % cell,
                     "<-" if want is None else "*%s" % want))

    expected = [(71, "LFO SPEED")]
    assert [(p, n) for p, n, _, _ in disagree] == expected, \
        "the set of disagreements changed: %s" % disagree

    print("\nRESONANCE is the one name the rule cannot decide:")
    for prog, name, cell in all_rows:
        if name == "RESONANCE":
            print("  effect %-3d p%-2d %s"
                  % (prog, PAGES[prog],
                     "*15, an enumeration (wah)" if cell == 15
                     else "<-, a signed feedback (flanger/phaser)"))

    print("\nOK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
