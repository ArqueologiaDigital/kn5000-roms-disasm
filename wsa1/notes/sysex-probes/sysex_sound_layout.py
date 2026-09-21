#!/usr/bin/env python3
"""Are the transcribed sound layouts self-consistent, and do they match the decode?

QUESTION IT ANSWERS
  `sound_layout.json` is a TRANSCRIPTION, read by eye off rendered scans of
  Technics' Reference Guide (pages 48-55, which carry no text layer).  A
  transcription from a scan is exactly the kind of artefact that looks right and
  is wrong: a `253` misread as `256` changes nothing on the page and everything
  in a librarian.

  So the transcription is not trusted, it is CHECKED, by two things it cannot
  satisfy by accident:

  1. EVERY BLOCK MUST TILE ITS PARENT.  Each parameter number from a block's
     first to its last is covered exactly once -- no gap, no overlap -- and a
     block's children must tile the block.  A misread digit almost always leaves
     a hole somewhere and a collision somewhere else, and the assertion names
     both.
  2. EACH AREA'S TOTAL MUST MATCH THE FIRMWARE.  NORMAL SOUND must come to 713
     bytes and DRUM SOUND to 19608.  Both figures come from the separate decode
     of the parameter dispatch; the guide prints neither, and neither was used
     to build the transcription.

  Those two pin every block boundary and every stride.  They do NOT check a
  parameter's NAME, its bit field or its range; a misread there survives, and
  the chapter says so rather than letting a validator imply otherwise.

  A NOTE ON METHOD.  Where the guide gives a repeating block as several columns
  side by side, only the FIRST column is transcribed and the others are derived
  from the stride.  The columns are vertically offset on the page, and reading
  them in parallel is precisely how this transcription first went wrong.

SIGNAL BEING READ
  `sound_layout.json` only.

RUN
  python3 wsa1/notes/sysex-probes/sysex_sound_layout.py
  python3 wsa1/notes/sysex-probes/sysex_sound_layout.py --tex <file>

PASS CRITERION
  Every block tiles, both areas hit their declared size, and OK.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
LAYOUT = os.path.join(HERE, "sound_layout.json")


def h(s):
    return int(s, 16)


def bitfield(s):
    """The guide writes a bit range as BP7~0. A bare ~ is a non-breaking space
    in LaTeX, so it must become a dash, not be escaped away."""
    if not s or s == "-":
        return ""
    return s.replace("BP", "").replace("~", "--")


def tex_escape(s):
    return (s.replace("\\", "").replace("{", "\\{").replace("}", "\\}")
             .replace("&", "\\&").replace("_", "\\_")
             .replace("%", "\\%").replace("#", "\\#"))


def check_block(b, path):
    """A block's children -- entries or sub-blocks -- must tile it exactly."""
    lo, hi = h(b["at"]), h(b["to"])
    span = hi - lo + 1
    name = "%s/%s" % (path, b["name"]) if path else b["name"]

    pieces = []
    for sub in b.get("blocks", []):
        s_lo, s_hi = h(sub["at"]), h(sub["to"])
        s_span = s_hi - s_lo + 1
        if sub["count"] > 1:
            assert sub["stride"] == s_span, \
                "%s: %s has stride %d but spans %d" % (name, sub["name"],
                                                       sub["stride"], s_span)
        for i in range(sub["count"]):
            base = s_lo + i * (sub["stride"] or s_span)
            pieces.append((base, base + s_span - 1, "%s[%d]" % (sub["name"], i)))
        check_block(sub, name)
    for e in b.get("entries", []):
        a = h(e["at"])
        z = h(e["to"]) if e.get("to") else a
        pieces.append((a, z, e["name"]))

    covered = {}
    for a, z, who in pieces:
        assert lo <= a <= z <= hi, \
            "%s: %s (%03X-%03X) is outside %03X-%03X" % (name, who, a, z, lo, hi)
        for n in range(a, z + 1):
            assert n not in covered, \
                "%s: %03X covered twice (%s and %s)" % (name, n, covered[n], who)
            covered[n] = who
    missing = [n for n in range(lo, hi + 1) if n not in covered]
    assert not missing, \
        "%s: %d numbers uncovered, first %03X" % (name, len(missing), missing[0])
    return span


# Note bases the guide PRINTS, spot-checked against the ones the stride implies.
# Two of these were read off different pages, and the last is the final row of
# the table -- so agreeing with all four pins the 0x198 base and the 150-byte
# stride independently of the tiling arithmetic.
GUIDE_NOTE_BASES = {0x13: 0x0CBA, 0x14: 0x0D50, 0x20: 0x1458, 0x7F: 0x4C02}


def check_note_bases(area):
    note = [b for b in area["blocks"] if b["name"] == "NOTE DATA"][0]
    base, stride = h(note["at"]), note["stride"]
    for n, printed in sorted(GUIDE_NOTE_BASES.items()):
        got = base + n * stride
        assert got == printed, \
            "NOTE:%02X computes to %03X, the guide prints %03X" % (n, got, printed)
    print("  note bases agree with the four the guide prints (%s)"
          % ", ".join("NOTE:%02X" % n for n in sorted(GUIDE_NOTE_BASES)))


def main():
    doc = json.load(open(LAYOUT))

    for area in doc["areas"]:
        print("\n%s  --  ADR %s, %d bytes" % (area["name"], area["adr"], area["size"]))
        total = 0
        for b in area["blocks"]:
            span = check_block(b, area["name"])
            count = b["count"]
            total += span * count
            bases = [h(b["at"]) + i * (b["stride"] or span) for i in range(count)]
            shown = "  ".join("%03X" % x for x in bases[:4])
            if count > 4:
                shown += "  ... %03X" % bases[-1]
            print("  %-20s %4d bytes  x%-4d %s" % (b["name"], span, count, shown))
        print("  %-20s %4d bytes" % ("TOTAL", total))
        assert total == area["size"], \
            "%s totals %d bytes; the decode says %d" % (area["name"], total, area["size"])
        last = max(h(b["to"]) + (b["count"] - 1) * (b["stride"] or 0)
                   for b in area["blocks"])
        assert last == area["size"] - 1, \
            "%s ends at %03X, expected %03X" % (area["name"], last, area["size"] - 1)
        print("  matches the decode, and the area ends at %03X" % last)
        if any(b["name"] == "NOTE DATA" for b in area["blocks"]):
            check_note_bases(area)

    if "--tex" in sys.argv:
        out = ["%% GENERATED by notes/sysex-probes/sysex_sound_layout.py --tex",
               "%% Source: sound_layout.json. Do not edit.", ""]

        def emit(b, depth):
            if b.get("blocks"):
                for sub in b["blocks"]:
                    emit(sub, depth)
                return
            out.append("\\subsection*{%s}" % tex_escape(b["name"]))
            out.extend(["{\\small",
                    "\\begin{longtable}{l>{\\raggedright\\arraybackslash}p{24mm}"
                    ">{\\raggedright\\arraybackslash}p{58mm}"
                    ">{\\raggedright\\arraybackslash}p{36mm}}",
                    "\\toprule", "no. & bits & parameter & values \\\\",
                    "\\midrule\\endfirsthead",
                    "\\toprule no. & bits & parameter & values \\\\",
                    "\\midrule\\endhead"])
            for e in b["entries"]:
                num = ("\\bytes{%s--%s}" % (e["at"], e["to"])) if e.get("to") \
                    else "\\bytes{%s}" % e["at"]
                vals = e.get("range", "-")
                vals = "" if vals in ("-", "") else "\\bytes{%s}" % vals
                note = tex_escape(e.get("note", ""))
                if note:
                    vals = (vals + " --- " if vals else "") + note
                out.append("%s & %s & %s & %s \\\\"
                           % (num, bitfield(e.get("bits", "-")),
                              tex_escape(e["name"]), vals))
            out.extend(["\\bottomrule", "\\end{longtable}", "}", ""])

        for area in doc["areas"]:
            out.append("\\section{%s parameters}" % tex_escape(area["name"].title()))
            for b in area["blocks"]:
                emit(b, 0)
        target = sys.argv[sys.argv.index("--tex") + 1]
        open(target, "w").write("\n".join(out) + "\n")
        print("\n  wrote %s" % target)

    print("OK")


if __name__ == "__main__":
    main()
