#!/usr/bin/env python3
"""Is the transcribed NORMAL SOUND layout self-consistent, and does it match the decode?

QUESTION IT ANSWERS
  `sound_layout.json` is a TRANSCRIPTION, read by eye off rendered scans of
  Technics' Reference Guide (pages 48-51, which carry no text layer).  A
  transcription from a scan is exactly the kind of artefact that looks right and
  is wrong: a `253` misread as `256` changes nothing on the page and everything
  in a librarian.

  So the transcription is not trusted, it is CHECKED, by two things it cannot
  satisfy by accident:

  1. THE AREA MUST TILE.  Every parameter number from the first to the last of a
     group must be covered exactly once -- no gap, no overlap.  A misread digit
     almost always breaks this, because it leaves a hole somewhere and a
     collision somewhere else.
  2. THE TOTAL MUST MATCH THE FIRMWARE.  The three groups, with their repeat
     counts, must come to the size of the NORMAL SOUND area as established
     independently from the program: 713 bytes.  That number was not used to
     build the transcription, and nothing in the guide states it.

  Those two together pin every group boundary and both strides.  They do NOT
  check a parameter's NAME, its bit field or its range; a misread there survives,
  and the chapter says the transcription is what it is.

SIGNAL BEING READ
  `sound_layout.json` only.  The 713-byte figure is from the separate decode of
  the parameter dispatch, recorded in the reference.

RUN
  python3 wsa1/notes/sysex-probes/sysex_sound_layout.py
  python3 wsa1/notes/sysex-probes/sysex_sound_layout.py --tex <file>

PASS CRITERION
  Each group tiles its own extent, the four repeats of each repeating group land
  where the stride says, the whole area totals 713 bytes, and OK.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
LAYOUT = os.path.join(HERE, "sound_layout.json")

AREA_SIZE = 713          # from the decode, not from the guide
ADR_BASE = 0x040000      # ADR 10 00 00


def h(s):
    return int(s, 16)


def bitfield(s):
    """The guide writes a bit range as BP7~0. A bare ~ is a non-breaking space
    in LaTeX, so it must be turned into a dash, not escaped away."""
    if not s or s == "-":
        return ""
    return s.replace("BP", "").replace("~", "--")


def tex_escape(s):
    # braces must go first: they are the ones that break the build, and the
    # guide uses them in prose ("space to }")
    return (s.replace("\\", "").replace("{", "\\{").replace("}", "\\}")
             .replace("&", "\\&").replace("_", "\\_")
             .replace("%", "\\%").replace("#", "\\#"))


def main():
    doc = json.load(open(LAYOUT))
    groups = doc["groups"]

    total = 0
    print("\nNORMAL SOUND LAYOUT, as transcribed")
    for g in groups:
        lo, hi = h(g["at"]), h(g["to"])
        span = hi - lo + 1

        # (1) the entries must tile [lo, hi] exactly
        covered = {}
        for e in g["entries"]:
            a = h(e["at"])
            b = h(e["to"]) if e.get("to") else a
            assert lo <= a <= b <= hi, \
                "%s: entry %s-%s is outside %s-%s" % (g["name"], e["at"],
                                                      e.get("to"), g["at"], g["to"])
            for n in range(a, b + 1):
                assert n not in covered, \
                    "%s: parameter %03X covered twice (%s and %s)" % (
                        g["name"], n, covered[n], e["name"])
                covered[n] = e["name"]
        missing = [n for n in range(lo, hi + 1) if n not in covered]
        assert not missing, \
            "%s: %d parameter numbers uncovered, first %03X" % (
                g["name"], len(missing), missing[0])

        # (2) the repeats must land where the stride says
        if g["count"] > 1:
            assert g["stride"] == span, \
                "%s: stride %d but the group spans %d" % (g["name"], g["stride"], span)
        total += span * g["count"]
        print("  %-14s %s-%s  %3d bytes  x%d  stride %d"
              % (g["name"], g["at"], g["to"], span, g["count"], g["stride"] or span))

    print("  %-14s %s" % ("", "-" * 40))
    print("  %-14s %d bytes" % ("TOTAL", total))

    # (3) the total must match the figure the firmware decode produced
    assert total == AREA_SIZE, \
        "the transcription totals %d bytes; the decode says the area is %d" % (
            total, AREA_SIZE)
    print("\n  matches the %d-byte NORMAL SOUND area found in the program" % AREA_SIZE)

    # the repeats' base addresses, which the chapter prints
    print("\n  repeat bases:")
    for g in groups:
        if g["count"] > 1:
            bases = [h(g["at"]) + i * g["stride"] for i in range(g["count"])]
            print("    %-14s %s" % (g["name"],
                                    "  ".join("%03X" % b for b in bases)))
    last = max(h(g["to"]) + (g["count"] - 1) * g["stride"] for g in groups)
    assert last == AREA_SIZE - 1, "the area ends at %03X, expected %03X" % (
        last, AREA_SIZE - 1)
    print("    area runs 000 to %03X" % last)

    if "--tex" in sys.argv:
        out = ["%% GENERATED by notes/sysex-probes/sysex_sound_layout.py --tex",
               "%% Source: sound_layout.json. Do not edit.", ""]
        for g in groups:
            out += ["\\subsection*{%s}" % tex_escape(g["name"]),
                    "{\\small", "\\begin{longtable}{l>{\\raggedright\\arraybackslash}p{24mm}>{\\raggedright\\arraybackslash}p{58mm}"
                    ">{\\raggedright\\arraybackslash}p{36mm}}",
                    "\\toprule", "no. & bits & parameter & values \\\\",
                    "\\midrule\\endfirsthead",
                    "\\toprule no. & bits & parameter & values \\\\",
                    "\\midrule\\endhead"]
            for e in g["entries"]:
                num = ("\\bytes{%s--%s}" % (e["at"], e["to"])) if e.get("to") \
                    else "\\bytes{%s}" % e["at"]
                vals = e.get("range", "-")
                vals = "" if vals in ("-", "") else "\\bytes{%s}" % vals
                note = tex_escape(e.get("note", ""))
                if note:
                    vals = (vals + " --- " if vals else "") + note
                bits = bitfield(e.get("bits", "-"))
                out.append("%s & %s & %s & %s \\\\"
                           % (num, bits, tex_escape(e["name"]), vals))
            out += ["\\bottomrule", "\\end{longtable}", "}", ""]
        target = sys.argv[sys.argv.index("--tex") + 1]
        open(target, "w").write("\n".join(out) + "\n")
        print("\n  wrote %s" % target)

    print("OK")


if __name__ == "__main__":
    main()
