#!/usr/bin/env python3
"""Emit the LaTeX tables for the reference's parameter chapter.

QUESTION IT ANSWERS
  `sysex_param_addresses.py` resolves every `00`-area parameter to a work-RAM
  byte and therefore to a position inside the SYSTEM,PART & MIDI bulk dump.
  That is the raw material of chapter 6 of
  `wsa1/docs/system-exclusive-reference/`, but the reference is a PROTOCOL
  document: it may state only what is visible on the wire, never a work-RAM
  address or a firmware symbol.

  This script is the bridge.  It runs the probe, keeps the three columns a
  reader of the protocol can act on -- accepted values, data length, position
  in the bulk dump -- discards the internal ones, merges in the curated names
  from `param_names.json`, and writes the chapter's tables.

  Regenerating the tables is therefore a single command, and no number in the
  document is typed by hand.

SIGNAL BEING READ
  The probe's own stdout in `--dump` and `--lists` modes.  Nothing is parsed
  out of the ROM here; if the probe's assertions fail this script fails with
  it, which is the intent.

  Dump position is the one derived quantity: for a COMMON parameter it is the
  probe's dump address verbatim; for a PART parameter the probe's addresses
  are those of part 0, so the byte offset WITHIN a part record is
  (dump address - PART0_BASE) and the reader adds the record base for the part
  they want.

NAMES
  `param_names.json` is curated by hand, one entry per "<block>/<parameter>",
  each carrying a `confidence` of ESTABLISHED or LIKELY and a `basis`.  Only
  those two confidences are emitted; anything weaker is left blank on the page
  rather than printed with a hedge.  An entry whose address is not in the
  probe's output is a hard error -- that is how a stale name gets caught.

RUN
  python3 wsa1/notes/sysex-probes/sysex_param_table_tex.py \
      wsa1/docs/system-exclusive-reference/tbl-parameters.tex

PASS CRITERION
  Prints the row counts and OK.  108 parameters in, 108 rows out.
"""
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROBE = os.path.join(HERE, "sysex_param_addresses.py")
NAMES = os.path.join(HERE, "param_names.json")

DUMP_BASE = 0x100000            # the address the dump puts on the wire
PART0_BASE = 0x1000A2           # dump address of part 0's record
PART_STRIDE = 0x40              # record size, and the stride within each run
PART_RUN2_BASE = 0x1002E2       # parts 8..31 resume here, NOT at PART0+8*0x40


def probe(*args):
    out = subprocess.run([sys.executable, PROBE] + list(args),
                         capture_output=True, text=True, check=True).stdout
    assert out.rstrip().endswith("OK"), "the probe did not pass"
    return out


ROW = re.compile(r"^\s+([0-9A-F]{2})\s+([0-9A-F]{2})\s+(\d)\s+[0-9A-F]{2}\s+"
                 r"[0-9A-F]{2}\s+0x([0-9A-F]{2})\s+(\d+)\s+(\d+)\s+(\S+)"
                 r"(?:\s+(0x[0-9A-F]{6}))?(.*)$")


def parse():
    rows = []
    for line in probe("--dump").splitlines():
        m = ROW.match(line)
        if not m:
            continue
        blk, par, size, mask, lo, hi, ram, dump, note = m.groups()
        rows.append(dict(block=int(blk, 16), param=int(par, 16), size=int(size),
                         mask=int(mask, 16), lo=int(lo), hi=int(hi),
                         dump=int(dump, 16) if dump else None,
                         note=(note or "").strip()))
    return rows


WHITELIST = re.compile(r"^\s+([0-9A-F]{2}) ([0-9A-F]{2}) ([0-9A-F]{2})\s+list (\d)\s+-> \[(.*)\]")


def whitelists():
    out = {}
    for line in probe("--lists").splitlines():
        m = WHITELIST.match(line)
        if m:
            r, blk, par, _idx, vals = m.groups()
            assert r == "00", "a white-list moved out of the 00 area"
            out[(int(blk, 16), int(par, 16))] = [
                v.strip().strip("'") for v in vals.split(",")]
    return out


def check_record_bases(text):
    """The two record bases are constants HERE; make the probe confirm them."""
    m = re.search(r"parts 0-7 at 0x([0-9A-F]{4})\+0x40\*p, parts 8-31 at "
                  r"0x([0-9A-F]{4})\+0x40\*\(p-8\)", text)
    assert m, "the probe no longer states the part record bases"
    lo, hi = int(m.group(1), 16), int(m.group(2), 16)
    ram_lo = DUMP_BASE - 0x7600          # the probe's own offset between the two
    assert lo + ram_lo == PART0_BASE, "part 0 moved to 0x%04X" % lo
    assert hi + ram_lo == PART_RUN2_BASE, "the second run moved to 0x%04X" % hi


def bits(mask):
    return bin(mask).count("1")


def maskcol(row):
    """Which bits of the shared dump byte this parameter owns."""
    if not row["mask"]:
        return "---"
    if row["mask"] == 0xFF:
        return "all"
    return "\\bytes{%02X}" % row["mask"]


def values(row, wl):
    """What a sender may legally put in the data byte."""
    if (row["block"], row["param"]) in wl:
        return "enumerated, %d values" % len(wl[(row["block"], row["param"])])
    return "%d--%d" % (row["lo"], row["hi"])


def tex_escape(s):
    return s.replace("&", "\\&").replace("_", "\\_").replace("#", "\\#")


def named(names, row):
    key = "%02X/%02X" % (row["block"], row["param"])
    e = names.get(key)
    if not e or e["confidence"] not in ("ESTABLISHED", "LIKELY"):
        return ""
    n = tex_escape(e["name"])
    return n + ("\\dag" if e["confidence"] == "LIKELY" else "")


def main():
    rows = parse()
    check_record_bases(probe("--dump"))
    wl = whitelists()
    names = json.load(open(NAMES)) if os.path.exists(NAMES) else {}
    names = {k: v for k, v in names.items() if not k.startswith("_")}

    keys = {"%02X/%02X" % (r["block"], r["param"]) for r in rows}
    for k in names:
        assert k in keys, "param_names.json names %s, which is not a parameter" % k

    part = [r for r in rows if r["block"] == 0x20]
    common = [r for r in rows if r["block"] != 0x20]
    assert len(part) == 57, "the part block has %d parameters" % len(part)
    assert len(part) + len(common) == 108, "expected 108 parameters"

    out = []
    w = out.append
    w("%% GENERATED by notes/sysex-probes/sysex_param_table_tex.py -- do not edit")
    w("%% Regenerate after any change to sysex_param_addresses.py or param_names.json")
    w("")

    w("{\\small")
    w("\\begin{longtable}{lllll>{\\raggedright\\arraybackslash}p{38mm}}")
    w("\\caption{The 57 parameters of a part block. \\bytes{\\textit{p}} is the third")
    w("address byte; the offset is the byte's position inside that part's record in")
    w("a \\textsc{system, part \\& midi} bulk dump.}\\label{tbl:partparams}\\\\")
    w("\\toprule")
    w("\\bytes{\\textit{p}} & data & offset & bits & values & name \\\\")
    w("\\midrule\\endfirsthead")
    w("\\toprule \\bytes{\\textit{p}} & data & offset & bits & values & name \\\\")
    w("\\midrule\\endhead")
    for r in sorted(part, key=lambda r: r["param"]):
        off = ("\\bytes{%02X}" % (r["dump"] - PART0_BASE)) if r["dump"] else "---"
        w("\\bytes{%02X} & %d & %s & %s & %s & %s \\\\" %
          (r["param"], r["size"], off, maskcol(r), values(r, wl), named(names, r)))
    w("\\bottomrule")
    w("\\end{longtable}")
    w("}")
    w("")

    w("{\\small")
    w("\\begin{longtable}{llllll>{\\raggedright\\arraybackslash}p{29mm}}")
    w("\\caption{The parameters of the common blocks. The address is the one a")
    w("\\textsc{system, part \\& midi} bulk dump carries for the same")
    w("byte.}\\label{tbl:commonparams}\\\\")
    w("\\toprule")
    w("\\bytes{\\textit{s}} & \\bytes{\\textit{p}} & data & address & bits & values & name \\\\")
    w("\\midrule\\endfirsthead")
    w("\\toprule \\bytes{\\textit{s}} & \\bytes{\\textit{p}} & data & address & bits & values & name \\\\")
    w("\\midrule\\endhead")
    for r in sorted(common, key=lambda r: (r["block"], r["param"])):
        if "OUTSIDE" in r["note"]:
            addr = "outside"            # the byte itself lies outside the block
        elif r["dump"] is None:
            addr = "---"                 # position not established
        else:
            addr = "\\bytes{%06X}" % r["dump"]
        w("\\bytes{%02X} & \\bytes{%02X} & %d & %s & %s & %s & %s \\\\" %
          (r["block"], r["param"], r["size"], addr, maskcol(r),
           values(r, wl), named(names, r)))
    w("\\bottomrule")
    w("\\end{longtable}")
    w("}")
    w("")

    w("\\begin{center}")
    w("\\begin{tabular}{lp{62mm}l}")
    w("\\toprule")
    w("parameter & accepted values & count \\\\")
    w("\\midrule")
    for (blk, par), vals in sorted(wl.items()):
        w("\\bytes{00 %02X %02X} & \\bytes{%s} & %d \\\\" %
          (blk, par, " ".join(v[2:].upper() for v in vals), len(vals)))
    w("\\bottomrule")
    w("\\end{tabular}")
    w("\\end{center}")

    text = "\n".join(out) + "\n"
    if len(sys.argv) > 1:
        open(sys.argv[1], "w").write(text)
        print("wrote %s" % sys.argv[1])
    else:
        sys.stdout.write(text)

    print("  %d part parameters, %d common, %d named, %d white-listed"
          % (len(part), len(common),
             sum(1 for r in rows if named(names, r)), len(wl)))
    print("  part 0 record at dump 0x%06X, parts 8-31 resume at 0x%06X"
          % (PART0_BASE, PART_RUN2_BASE))
    print("OK")


if __name__ == "__main__":
    main()
