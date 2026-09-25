#!/usr/bin/env python3
r"""Evidence headers for two tables inside code files: CPANEL_STATE_MACHINE_TABLE, SetWall_SlotOrderTable.

QUESTION ANSWERED
    Both are typed and named but carry no statement of who reads them and how
    (census: "descriptive name only", embedded in code).  The readers sit in
    the same file; this script finds them in each version's source, pulls the
    RAM address of the index byte out of the reader (it differs in v7), and
    writes a header above the label.

    CPANEL_STATE_MACHINE_TABLE (ui/cpanel_routines.s): INTTX1_HANDLER and
      INTRX1_HANDLER both run `ld l,(<state>); xor h,h; extz xhl;
      add xhl,CPANEL_STATE_MACHINE_TABLE; ld xhl,(xhl); jp (xhl)` -- the state
      byte is used directly as a byte offset, so the states are 0, 4, ... 40
      for the 11 entries.
    SetWall_SlotOrderTable (ui/setwall_routines.s): SetWall_WriteSingleSlot,
      SetWall_WriteAllSlots and SetWall_LocalWriteAll run `ld l,(<row>);
      dec 1,l; sla l,4; ld xde,SetWall_SlotOrderTable; lda xiy,(xde+hl)` --
      3 rows of 16 slot numbers, row = (byte at <row>) - 1.

RUN
    python3 scripts/generators/gen_small_table_headers.py --check
    python3 scripts/generators/gen_small_table_headers.py --apply v10 v9 v7
    make gate
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LD_L = re.compile(r"^\s*ld\s+l\s*,\s*\((0x[0-9a-fA-F]+|\d+):16\)")
LAB = re.compile(r"^([A-Za-z_.$][\w.$]*):")


def readers(lines, use_re):
    """-> [(routine label, index RAM address)] for each line matching use_re"""
    out = []
    for i, l in enumerate(lines):
        if not use_re.search(l.split(";")[0]):
            continue
        ram = None
        for j in range(i - 1, max(i - 6, -1), -1):
            m = LD_L.match(lines[j])
            if m:
                ram = int(m.group(1), 0)
                break
        lab = None
        for j in range(i, -1, -1):
            m = LAB.match(lines[j])
            if m:
                lab = m.group(1)
                break
        out.append((lab, ram))
    return out


SPECS = [
    ("ui/cpanel_routines.s", "CPANEL_STATE_MACHINE_TABLE",
     re.compile(r"\badd\s+xhl\s*,\s*CPANEL_STATE_MACHINE_TABLE\b"),
     lambda rd, ram: [
         "; 11 routine pointers, one per state of the control-panel serial link.  %s and" % rd[0],
         "; %s both run `ld l,(0x%04X); xor h,h; extz xhl; add xhl,<this>; ld xhl,(xhl);" % (rd[1], ram),
         "; jp (xhl)`: the state byte at RAM 0x%04X is the byte offset (0, 4, ... 40)." % ram]),
    ("ui/setwall_routines.s", "SetWall_SlotOrderTable",
     re.compile(r"\bld\s+xde\s*,\s*SetWall_SlotOrderTable\b"),
     lambda rd, ram: [
         "; 3 rows x 16 slot numbers.  %s, %s and %s" % tuple(rd[:3]),
         "; run `ld l,(0x%04X); dec 1,l; sla l,4; ld xde,<this>; lda xiy,(xde+hl)`:" % ram,
         "; row = (byte at RAM 0x%04X) - 1, 16 bytes per row." % ram]),
]


def run(v, apply_it):
    for rel, label, use_re, mk in SPECS:
        path = os.path.join(ROOT, v, "maincpu", rel)
        lines = open(path, "rb").read().decode("latin-1").split("\n")
        rds = readers(lines, use_re)
        rams = {r for _, r in rds}
        assert len(rams) == 1 and None not in rams, (v, rel, rds)
        ram = rams.pop()
        hdr = mk([r for r, _ in rds], ram)
        k = next(i for i, l in enumerate(lines) if l.startswith(label + ":"))
        assert not lines[k - 1].startswith(";"), (v, rel, "already has a comment above")
        print("%s %s: readers %s, index RAM 0x%04X" % (v, label, ", ".join(r for r, _ in rds), ram))
        if apply_it:
            lines[k:k] = hdr
            open(path, "wb").write("\n".join(lines).encode("latin-1"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--apply", nargs="+")
    a = ap.parse_args()
    for v in (a.apply or ["v10", "v9", "v7"]):
        run(v, bool(a.apply))
    return 0


if __name__ == "__main__":
    sys.exit(main())
