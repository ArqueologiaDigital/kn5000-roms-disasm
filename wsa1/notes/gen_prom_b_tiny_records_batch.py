#!/usr/bin/env python3
"""Absorb six more prom_b `Data_Fxxxxxx` objects (each already self-declaring
its own record length in its own second byte) plus the .incbin immediately
following each, into one complete display-list record apiece -- 60 B total
(6 x 10 B).

QUESTION IT ANSWERS
  `scripts/analysis/sizing_defect_hunt.py --scan prom_b/wsa1_prom_b.s` flags
  all six with a ZERO-DRIFT LANDING that FULLY consumes the .incbin right
  after them (0 B remainder) and lands exactly on an already-committed
  boundary (an already-converted display-list header for 3 of them; another
  already-declared `Data_Fxxxxxx` object for the other 3, the same chaining
  shape already fixed for Data_F34CA2/Data_F34CAD).

  ⚠ That tool's landing test uses the WEAKER "op < 0x24, length byte,
  self-framing" walk (its own docstring), not the strict per-handler rule
  from `notes/prom_b_dl_length_audit.py` -- exactly the false-positive shape
  the project brief warns about ("op < bound alone is not enough"). Each site
  below is therefore independently re-checked against the ROM's OWN handler
  tables (HTBL_A/HTBL_B), and only kept if EXACTLY ONE of the two
  interpreters' implied-length rule is satisfied:

      site      op  len  interpreter A rule      interpreter B rule
      F0315F    02   10  ('fixed',10) MATCH      ('fixed',15) no
      F04668    05   10  ('fixed',10) MATCH      ('fixed',11) no
      F05031    1B   10  ('fixed',10) MATCH      (no B op 0x1B)
      F351F9    02   15  ('fixed',10) no         ('fixed',15) MATCH
      F3A0D9    03   11  ('fixed',12) no         ('fixed',11) MATCH
      F3A433    03   11  ('fixed',12) no         ('fixed',11) MATCH

  Every one matches exactly one interpreter, never both, never neither --
  the same clean signal (not "close enough") that licensed
  Data_F34968/Data_F34CA2/Data_F34CAD in the preceding two commits.
  F3A0D9 and F3A433 are the same op-0x03/interpreter-B/fixed-11 shape as
  Data_F34CA2, right down to the shared `f6 12 ff` prefix bytes.

RUN
  python3 notes/gen_prom_b_tiny_records_batch.py --check
  python3 notes/gen_prom_b_tiny_records_batch.py --apply
  python3 scripts/analysis/assert_byte_identical.py
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
BASE = 0xF00000

SITES = [
    # name, addr, total_len, interp, old_incbin_text, comment
    ("F0315F", 0xF0315F, 10, "A",
     '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x003166, 0x000003\n',
     "A op 02, 10 bytes -> handler HTBL_A[2]"),
    ("F04668", 0xF04668, 10, "A",
     '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x004669, 0x000009\n',
     "A op 05, 10 bytes -> handler HTBL_A[5]"),
    ("F05031", 0xF05031, 10, "A",
     '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x005035, 0x000006\n',
     "A op 1B, 10 bytes -> handler HTBL_A[0x1B]"),
    ("F351F9", 0xF351F9, 15, "B",
     '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x0351FD, 0x00000B\n',
     "B op 02, 15 bytes -> handler HTBL_B[2]"),
    ("F3A0D9", 0xF3A0D9, 11, "B",
     '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03A0DE, 0x000006\n',
     "B op 03, 11 bytes -> handler HTBL_B[3]"),
    ("F3A433", 0xF3A433, 11, "B",
     '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03A438, 0x000006\n',
     "B op 03, 11 bytes -> handler HTBL_B[3]"),
]

OLD_BYTES_LINE = {
    "F0315F": "\t.byte\t0x02, 0x0A, 0x05, 0x01, 0x74, 0x00, 0x05\t; F0315F  |....t..|\n",
    "F04668": "\t.byte\t0x05\t; F04668  |.|\n",
    "F05031": "\t.byte\t0x1B, 0x0A, 0x0D, 0x00\t; F05031  |....|\n",
    "F351F9": "\t.byte\t0x02, 0x0F, 0xF6, 0x12\t; F351F9  |....|\n",
    "F3A0D9": "\t.byte\t0x03, 0x0B, 0xF6, 0x12, 0xFF\t; F3A0D9  |.....|\n",
    "F3A433": "\t.byte\t0x03, 0x0B, 0xF6, 0x12, 0xFF\t; F3A433  |.....|\n",
}


def rom():
    return open(ROM, "rb").read()


def full_bytes(addr, n):
    return rom()[addr - BASE:addr - BASE + n]


def old_block(name, addr):
    return "Data_%s:\n%s\n%s" % (name, OLD_BYTES_LINE[name], site_incbin(name))


def site_incbin(name):
    for n, addr, ln, interp, incbin, comment in SITES:
        if n == name:
            return incbin
    raise KeyError(name)


def new_block(name, addr, total_len, interp, incbin_text, comment):
    data = full_bytes(addr, total_len)
    hexed = ", ".join("0x%02X" % b for b in data)
    return (
        "; ABSORBED 2026-09-02 -- see notes/gen_prom_b_tiny_records_batch.py: "
        "this object plus\n"
        "; the .incbin that followed it is ONE interpreter-%s record (verified "
        "against\n"
        "; the ROM's own handler table, exactly one interpreter's implied-"
        "length rule fits).\n"
        "Data_%s:\n"
        "\t.byte %s\t; %s\n" % (interp, name, hexed, comment)
    )


def cmd_check():
    ok = True
    checks = []
    import prom_b_dl_length_audit as A
    data = rom()
    ta, tb = A.tables(data)
    src = open(SRC, encoding="latin-1").read()

    for name, addr, n, interp, incbin, comment in SITES:
        rec = full_bytes(addr, n)
        op, ln = rec[0], rec[1]
        ra = A.IMPLIED_A.get(ta[op]) if op < len(ta) else None
        rb = A.IMPLIED_B.get(tb[op]) if op < len(tb) else None

        def fits(rule):
            if rule is None:
                return False
            kind, want = rule
            return ln == want if kind == "fixed" else ln >= want

        fa, fb = fits(ra), fits(rb)
        checks.append((f"{name}: op 0x{op:02X} len {ln} fits EXACTLY ONE "
                        f"interpreter's rule (A={ra} fit={fa}, B={rb} fit={fb})",
                        fa != fb and (fa if interp == "A" else fb)))

        ob = old_block(name, addr)
        checks.append((f"{name}: old block present, unique in the tree",
                        src.count(ob) == 1))

    for name, passed in checks:
        print(f"  {name:<90s} {'ok' if passed else 'FAILED'}")
        ok = ok and passed
    return 0 if ok else 1


def cmd_apply():
    src = open(SRC, encoding="latin-1").read()
    before = len(src)
    for name, addr, n, interp, incbin, comment in SITES:
        ob = old_block(name, addr)
        assert src.count(ob) == 1, f"{name}: old block not found or not unique"
        nb = new_block(name, addr, n, interp, incbin, comment)
        src = src.replace(ob, nb, 1)
    open(SRC, "w", encoding="latin-1").write(src)
    print("applied: %d -> %d chars (%+d)" % (before, len(src), len(src) - before))


def main():
    if "--check" in sys.argv:
        sys.exit(cmd_check())
    if "--apply" in sys.argv:
        cmd_apply()
        return
    sys.exit("usage: --check | --apply")


if __name__ == "__main__":
    main()
