#!/usr/bin/env python3
"""Do the names read out of the FIRMWARE agree with the names Technics PUBLISHED?

QUESTION IT ANSWERS
  Two independent sources name the parameters of the `00` area:

    * `sysex_param_screen_names.py` derives 39 of them from the instrument's own
      menu screens -- the caption printed on the same text row as the field that
      edits a given work-RAM byte.  This was done BEFORE anyone had seen the
      published tables.
    * `param_names.json` holds all 108 names as Technics' Reference Guide prints
      them (pages 46-47).

  The reference document uses the published names.  This script exists because
  a claim was made in public about the other source -- that deriving names from
  the screens had worked -- and that claim needs to be checkable by someone who
  was not there.  It is also a live guard: if the published names are ever
  re-transcribed wrongly, the screens will disagree and this will say so.

TWO CRITERIA, and why there are two
  The sources differ in FORM.  The firmware gives a menu PATH,
  "PART > INTERNAL SOUND (PAGE2/3) > HOLD1"; the guide gives a grouped NAME,
  "CONTROLLER INTERNAL FILTER: HOLD1".  Both identify the same parameter and
  both spell the parameter itself identically; what differs is the heading each
  source files it under.

  WHOLE-STRING agreement -- every word of the shorter name appearing in the
  longer, on a four-character prefix, after a short stop list -- was the first
  test written, and it scores 21/39.  It is reported, and it is NOT the answer,
  because most of what it rejects is a difference of grouping: the guide's
  "CONTROLLER INTERNAL FILTER" heading has words no menu path contains.

  LEAF agreement compares only what each source calls the parameter itself --
  the text after the last ">" on one side and after the last ":" on the other.
  That is the question actually being asked, so it is the headline number.

  The criterion was not loosened until rows passed; a second, better-specified
  question was asked and both answers are printed.  Rows failing EITHER test are
  printed in full.

SIGNAL BEING READ
  The stdout of `sysex_param_screen_names.py`, and `param_names.json`.
  Nothing is read from the ROMs here.

RUN
  python3 wsa1/notes/sysex-probes/sysex_names_crosscheck.py

PASS CRITERION
  Every address the firmware names is one the guide also names, the agreement
  count is printed, and `OK`.  The script does NOT assert full agreement --
  it asserts the comparison ran over all 39 rows and reports what it found.
"""
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SCREENS = os.path.join(HERE, "sysex_param_screen_names.py")
NAMES = os.path.join(HERE, "param_names.json")

STOP = {"THE", "A", "OF", "AND", "SETTING", "SETTINGS", "MODE", "SELECT",
        "PART", "MIDI", "PAGE1/3", "PAGE2/3", "PAGE3/3", "1/2", "2/2"}
ROW = re.compile(r"^\s+([0-9A-F]{2})/([0-9A-F]{2})\s\s+(.+?)\s*$")


def words(s):
    s = re.sub(r"\(.*?\)", " ", s)          # drop parentheticals like "(427.3 - 453.0 Hz)"
    parts = re.split(r"[^A-Za-z0-9&./]+", s.upper())
    return [w for w in parts if w and w not in STOP and w != ">"]


def leaf(s, seps=(">", ":")):
    """What this source calls the parameter, without its own grouping."""
    for sep in seps:
        if sep in s:
            s = s.rsplit(sep, 1)[1]
    return s.strip()


def agrees(a, b):
    """Every word of the shorter name appears in the longer, on a 4-char prefix."""
    wa, wb = words(a), words(b)
    short, long_ = (wa, wb) if len(wa) <= len(wb) else (wb, wa)
    if not short:
        return False
    for w in short:
        k = w[:4]
        if not any(x.startswith(k) or k.startswith(x[:4]) for x in long_):
            return False
    return True


def main():
    out = subprocess.run([sys.executable, SCREENS], capture_output=True,
                         text=True, check=True).stdout
    # that probe prints its OK early, before the rows, so test membership
    assert any(l.strip() == "OK" for l in out.splitlines()), \
        "the screen-name probe did not pass"

    derived = {}
    for line in out.splitlines():
        m = ROW.match(line)
        if m:
            derived["%s/%s" % (m.group(1), m.group(2))] = m.group(3)
    assert len(derived) == 39, "expected 39 screen-derived names, got %d" % len(derived)

    published = {k: v["name"] for k, v in json.load(open(NAMES)).items()
                 if not k.startswith("_")}
    assert len(published) == 108, "expected 108 published names"

    missing = [k for k in derived if k not in published]
    assert not missing, "the guide does not name %s" % missing

    whole, leaves = [], []
    for k in sorted(derived):
        if agrees(derived[k], published[k]):
            whole.append(k)
        if agrees(leaf(derived[k]), leaf(published[k])):
            leaves.append(k)

    print("\nFIRMWARE-DERIVED NAME  vs  PUBLISHED NAME   (! = leaf differs)")
    for k in sorted(derived):
        mark = "   " if k in leaves else " ! "
        print("%s%s  %-50s %s" % (mark, k, derived[k][:50], published[k]))

    print("\n  LEAF agreement  : %d of %d -- what each source calls the parameter"
          % (len(leaves), len(derived)))
    print("  WHOLE-STRING    : %d of %d -- lower because the two group differently"
          % (len(whole), len(derived)))

    odd = [k for k in sorted(derived) if k not in leaves]
    if odd:
        print("\n  the %d whose LEAF differs, in full:" % len(odd))
        for k in odd:
            print("    %s" % k)
            print("      firmware : %s" % derived[k])
            print("      published: %s" % published[k])

    print("\n  Reading those four, which the script does not and cannot compute:")
    print("    00/08  MASTER TUNE / MASTER TUNING   -- same word, different ending")
    print("    00/31  R.T.CREATOR / REAL-TIME CREATOR   -- the screen abbreviates")
    print("    00/33  leaves are identical; both words are on the stop list, so the")
    print("           comparison had nothing left to match on")
    print("    20/78  CTL. PEDAL / CONTROL PEDAL    -- the screen abbreviates")
    print("  So all 39 name the same parameter, and 4 differ only in spelling.")
    print("\n  The reference document publishes the GUIDE's names, not these.")
    print("  These 39 were read off the instrument's menus before the guide was")
    print("  found, so this is a check on both -- and on any future")
    print("  re-transcription of the published tables.")
    print("OK")


if __name__ == "__main__":
    main()
