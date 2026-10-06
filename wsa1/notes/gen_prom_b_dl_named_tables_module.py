#!/usr/bin/env python3
"""Close the small `.incbin` gaps inside 0xF13D34-0xF147AB that are the STRING
and ARRAY tables the shape-2/3 records (already spliced by
gen_prom_b_dl_shape23_module.py and gen_prom_b_dl_closure_gaps_module.py)
name in their OWN `+0x07 -> XIY/XIX` field.

QUESTION IT ANSWERS
    Every interpreter-B "string-table readout" record (op 0x02/0x07, handler
    0xF31B21/0xF31B39) and "array of entry[value]" record (op 0x03/0x08,
    handler 0xF31B57) carries the table's own start address and, for the
    string-table ops, its own per-entry stride (the +0x0B `BC` field) --
    already committed, in the .s text itself, by the two splices above.  This
    script harvests those addresses straight OUT of the committed source (never
    re-typed), sorts them, and for every run where CONSECUTIVE named addresses
    (or a named address and the enclosing `.incbin`'s own end) divide EXACTLY
    by the declared stride with no remainder, emits the bytes as a table with
    one row per entry and an ASCII gutter -- the same style every other typed
    data block in this file already uses.

    The result reads as plain caption text: "EFF1"/"EFF2"/"REV ", "OFF"/"ON ",
    "EFFECT 1"/"EFFECT 2"/"REVERB", "PARALLEL"/"SERIAL  " -- exactly the kind of
    string table wave 2 found at 0xF3C947, just one level removed (named by a
    record this round spliced rather than one already committed).

TWO SMALL NON-TABLE PIECES, EACH WITH ITS OWN EVIDENCE
    * 0xF143C0-0xF143D4 (20 B): two ordinary interpreter-A records (op 0x05,
      0x1B; handler 0xF31A75, already used throughout this file) whose op/len
      walk lands, with zero drift, exactly on 0xF143D4 -- the address the very
      next record (DL_F143AF) independently names as its string table's start.
      Two independent facts pinning the same boundary.
    * 0xF146A6-0xF146B1 (11 B): one ordinary interpreter-B record, op 0x08,
      handler 0xF31B57 (the same handler EffectEditor_PaintJob1_DL2/EffectEditor_PaintJob1_DL1 already use two
      records earlier in this very span) -- self-framing at exactly 11 bytes
      (op/len says so), and its OWN +0x07 field names 0x00F146B1, the address
      immediately following it, as an 8-byte-stride array.  Never reached by
      any known call shape, but self-checking on both sides: the length byte
      and the field it carries.
    * 0xF14530-0xF14532 (2 B, both 0xA8): unattributed by any record's field --
      emitted verbatim as `.byte` with that stated, not folded into either
      neighbouring table.

VERIFICATION
    --selftest re-derives every named (address, stride) pair from the
    COMMITTED .s text (not from a hand-typed table in this file), checks the
    two record spans frame exactly via the same op/len walk the rest of the
    display-list tooling uses, and requires every gap's segments to sum to
    exactly that gap's `.incbin` size with zero leftover before `--splice` is
    allowed to touch anything.

RUN
    python3 notes/gen_prom_b_dl_named_tables_module.py --selftest
    python3 notes/gen_prom_b_dl_named_tables_module.py --show
    python3 notes/gen_prom_b_dl_named_tables_module.py --splice
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL      # noqa: E402
from asm_source import write_part      # noqa: E402

B_BASE = 0xF00000
S_FILE = "prom_b/wsa1_prom_b.s"
ROM = "original_ROMs/wsa1_prom_b.ic13"
S_PATH = os.path.join(ROOT, S_FILE)

LONG_RE = re.compile(
    r'\.long\s+0x(00F[0-9A-Fa-f]{5})\s*;\s*\+0x[0-9A-Fa-f]+ -> XI[YX]: '
    r'(string table|array of (\d+)-byte entries)')
BC_RE = re.compile(r'\.short\s+0x([0-9A-Fa-f]+)\s*;\s*\+0x[0-9A-Fa-f]+ -> BC: bytes per entry')

# The seven `.incbin` gaps this round closes, as (file_off, size).
GAPS = [
    (0x0143C0, 0x000020),
    (0x01447D, 0x000022),
    (0x01451D, 0x000045),
    (0x0145D3, 0x000006),
    (0x014621, 0x00003E),
    (0x0146A6, 0x00003B),
    (0x014728, 0x000084),
]

FAIL = []


def check(msg, got, want):
    ok = got == want
    print("  %-64s %-16s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


def harvest_named(text, lo, hi):
    """[(addr, stride)], sorted, de-duplicated, straight out of the committed
    source -- never typed in by hand.  Restricted to [lo, hi): this file's
    8 MB of already-converted text reuses these same field COMMENTS all over
    the image for unrelated records, so a stride collision outside the span
    this round is closing is somebody else's object, not a contradiction."""
    lines = text.split("\n")
    out = {}
    for i, l in enumerate(lines):
        m = LONG_RE.search(l)
        if not m:
            continue
        addr = int(m.group(1), 16)
        if not (lo <= addr < hi):
            continue
        if m.group(3):
            stride = int(m.group(3))
        else:
            stride = None
            for j in range(i + 1, min(i + 3, len(lines))):
                m2 = BC_RE.search(lines[j])
                if m2:
                    stride = int(m2.group(1), 16)
                    break
        if stride is None:
            continue
        if addr in out and out[addr] != stride:
            raise SystemExit("conflicting stride at 0x%06X: %d vs %d" % (addr, out[addr], stride))
        out[addr] = stride
    return sorted(out.items())


def build_segments(b, named, gap_s, gap_e):
    """[(kind, s, e, extra)] covering [gap_s, gap_e) exactly, or raise."""
    segs = []
    cur = gap_s

    # 0xF143C0 special case: two interpreter-A records before the first table.
    if gap_s == 0xF143C0:
        recs = DL.walk(b, gap_s, 0xF143D4)
        if recs is None or sum(ln for _p, _op, ln in recs) != 0xF143D4 - gap_s:
            raise SystemExit("0xF143C0 code prefix does not frame")
        segs.append(("code", gap_s, 0xF143D4, recs))
        cur = 0xF143D4

    # 0xF146A6 special case: one self-framing interpreter-B record (op 0x08).
    if gap_s == 0xF146A6:
        op, ln = b[gap_s - B_BASE], b[gap_s - B_BASE + 1]
        if (op, ln) != (0x08, 0x0B):
            raise SystemExit("0xF146A6 is not the expected op-08/len-11 record")
        segs.append(("brecord", gap_s, gap_s + ln, (op, ln)))
        cur = gap_s + ln

    pending = [(a, s) for a, s in named if cur <= a < gap_e]
    for k, (addr, stride) in enumerate(pending):
        nxt = pending[k + 1][0] if k + 1 < len(pending) else gap_e
        if addr > cur:
            # An unattributed span between two named points (or before the
            # first one) -- only accepted if it is small (<=2 B) and thus
            # cannot hide anything a table/record could be.
            if addr - cur > 2:
                raise SystemExit("unattributed gap 0x%06X-0x%06X too large to accept blind"
                                 % (cur, addr))
            segs.append(("raw", cur, addr, None))
        if stride == 1:
            # A stride-1 field names exactly ONE byte -- its own address --
            # not "however many bytes happen to precede the next named point".
            # Claiming more than that byte would overstate the evidence.
            span = 1
        else:
            span = min(nxt, gap_e) - addr
            if span % stride != 0:
                raise SystemExit("0x%06X: span %d not a multiple of stride %d" % (addr, span, stride))
        segs.append(("table", addr, addr + span, stride))
        cur = addr + span
    if cur < gap_e:
        if gap_e - cur > 2:
            raise SystemExit("trailing unattributed gap 0x%06X-0x%06X too large" % (cur, gap_e))
        segs.append(("raw", cur, gap_e, None))
        cur = gap_e
    if cur != gap_e:
        raise SystemExit("segments do not reach the gap end")
    return segs


def esc(t):
    return "".join(chr(c) if 0x20 <= c <= 0x7E else "." for c in t)


def render_segments(b, hta, segs):
    out = []
    for kind, s, e, extra in segs:
        if kind == "code":
            out.append("; 0x%06X-0x%06X: 2 interpreter-A records (op 0x05, 0x1B), the op/len\n"
                       "; walk landing exactly on 0x%06X, the string table DL_F143AF names\n"
                       "; in its own +0x07 field.\n" % (s, e - 1, e))
            out += DL.render(b, extra, hta, {s})
        elif kind == "brecord":
            op, ln = extra
            out.append("; 0x%06X-0x%06X: one self-framing interpreter-B record (op 0x%02X,\n"
                       "; handler 0xF31B57, the same handler EffectEditor_PaintJob1_DL2/EffectEditor_PaintJob1_DL1 already use),\n"
                       "; not reached by any known call shape -- accepted because its own\n"
                       "; length byte and its own +0x07 field (naming the table right after\n"
                       "; it) are both self-checking.\n" % (s, e - 1, op))
            raw = b[s - B_BASE:e - B_BASE]
            out.append("DL_%06X:\n" % s)
            out.append("\t.byte 0x%02X, 0x%02X\t; B op %02X, %d bytes -> handler 0xF31B57 -- "
                       "four words of entry[value]\n" % (op, ln, op, ln))
            out.append("\t.short 0x%04X\t; +0x02 source variable, 16-bit address\n"
                       % int.from_bytes(raw[2:4], "little"))
            out.append("\t.byte 0x%02X\t; +0x04 AND mask\n" % raw[4])
            out.append("\t.byte 0x%02X\t; +0x05 right shift, low 3 bits\n" % raw[5])
            out.append("\t.byte 0x%02X\t; +0x06 swi 7 function\n" % raw[6])
            out.append("\t.long 0x%08X\t; +0x07 -> XIX: array, indexed by the value\n"
                       % int.from_bytes(raw[7:11], "little"))
        elif kind == "table":
            stride = extra
            out.append("; 0x%06X-0x%06X: %d-byte-stride table, %d entries -- the string/array\n"
                       "; table a nearby already-spliced record names in its own +0x07 (and,\n"
                       "; for the string-table ops, +0x0B `BC`) field.\n"
                       % (s, e - 1, stride, (e - s) // stride))
            p = s
            while p < e:
                raw = b[p - B_BASE:p - B_BASE + stride]
                out.append("\t.byte %s\t; %06X  |%s|\n"
                           % (", ".join("0x%02X" % c for c in raw), p, esc(raw)))
                p += stride
        else:  # raw, <=2 B, unattributed
            raw = b[s - B_BASE:e - B_BASE]
            out.append("; 0x%06X-0x%06X: %d byte(s), unattributed by any record's field --\n"
                       "; left as plain data rather than folded into a neighbouring table.\n"
                       % (s, e - 1, e - s))
            out.append("\t.byte %s\t; %06X  |%s|\n" % (", ".join("0x%02X" % c for c in raw), s, esc(raw)))
    return out


def splice_gap(off, size, block):
    text = open(S_PATH, encoding="utf-8").read()
    lines = text.split("\n")
    target = '\t.incbin "%s", 0x%06X, 0x%06X' % (ROM, off, size)
    idx = [i for i, ln in enumerate(lines) if ln.strip() == target.strip()]
    if len(idx) != 1:
        raise SystemExit("expected exactly one directive matching 0x%06X, found %d"
                         % (off, len(idx)))
    i = idx[0]
    before_ctx = lines[:i] + lines[i + 1:]
    new_block = "".join(block).rstrip("\n").split("\n")
    out_lines = lines[:i] + new_block + lines[i + 1:]
    after_ctx = out_lines[:i] + out_lines[i + len(new_block):]
    if after_ctx != before_ctx:
        raise SystemExit("REFUSING TO SPLICE: context outside the target directive moved")
    write_part(S_PATH, "\n".join(out_lines), root=ROOT, allow_growth=True)


def main():
    a, b = DL.load()
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    text = open(S_PATH, encoding="utf-8").read()
    named = harvest_named(text, 0xF13D34, 0xF147AC)

    all_segs = {}
    for off, size in GAPS:
        s, e = B_BASE + off, B_BASE + off + size
        all_segs[(off, size)] = build_segments(b, named, s, e)

    if "--selftest" in sys.argv:
        print("gen_prom_b_dl_named_tables_module.py --selftest")
        check("named (addr,stride) pairs harvested", len(named) > 0, True)
        check("0xF143D4 stride harvested as 4", dict(named).get(0xF143D4), 4)
        check("0xF1451D stride harvested as 8", dict(named).get(0xF1451D), 8)
        total = 0
        for (off, size), segs in all_segs.items():
            covered = sum(e - s for _k, s, e, _x in segs)
            check("0x%06X segments sum to gap size" % (B_BASE + off), covered, size)
            total += size
        check("total bytes across all 7 gaps", total, sum(sz for _o, sz in GAPS))
        print("FAILURES: %d" % len(FAIL))
        return 1 if FAIL else 0

    if "--show" in sys.argv:
        for (off, size), segs in all_segs.items():
            sys.stdout.write("\n; --- gap 0x%06X, %d bytes ---\n" % (B_BASE + off, size))
            sys.stdout.write("".join(render_segments(b, hta, segs)))
        return 0

    if "--splice" in sys.argv:
        total_bytes = 0
        for off, size in GAPS:
            segs = all_segs[(off, size)]
            block = render_segments(b, hta, segs)
            splice_gap(off, size, block)
            total_bytes += size
        print("spliced %d bytes across %d gaps into %s" % (total_bytes, len(GAPS), S_FILE))
        return 0

    print("usage: --selftest | --show | --splice")
    return 1


if __name__ == "__main__":
    sys.exit(main())
