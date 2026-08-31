#!/usr/bin/env python3
"""Emit prom_b's display lists with EACH RECORD RENDERED BY ITS OWN INTERPRETER.

QUESTION ANSWERED
  The committed emitter, scripts/analysis/prom_b_display_lists.py --asm, renders
  every record with interpreter A's field layout.  494 of the 4,097 records are
  never run by interpreter A -- they are run by interpreter B at 0xF31AF0, whose
  handler table (0xF31DB1) and field layout are different.  Rendering those with
  A's layout produced field boundaries in the wrong places and, for the two text
  handlers, invented `.ascii` runs out of pointer bytes.

  This emitter attributes each record to an interpreter first (see
  notes/prom_b_dl_length_audit.py for the attribution and the proof that every
  record then satisfies its own interpreter's implied length, 0 exceptions on
  both sides) and renders it accordingly.

  A-record output is byte-for-byte the same TEXT the committed emitter produced,
  so the diff against the current .s is exactly the B records.

RUN
  python3 notes/gen_prom_b_display_lists_v2.py --lo 0x00000 --hi 0x31800
  python3 notes/gen_prom_b_display_lists_v2.py --lo 0x32709 --hi 0x40000
  python3 notes/gen_prom_b_display_lists_v2.py --diffstat     # A-record text unchanged?
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL

B_BASE = 0xF00000

# Interpreter B, handler -> (fields, comment).  fields = (offset, width, name).
# Every field is one the handler's own instructions read; see
# notes/FINDINGS-ui-display-list-interpreter-b.md for the disassembly of each.
BF_HEAD = [(2, 2, "source variable, 16-bit address"),
           (4, 1, "AND mask"),
           (5, 1, "right shift, low 3 bits")]
B_LAYOUT = {
    0xF31BA1: (BF_HEAD + [(6, 1, "swi 7 function"), (7, 2, "-> IX"),
                          (9, 1, "digit count: 3 -> 0x2661, 2 -> 0x2662, else 0x2663")],
               "decimal readout, unsigned (0xF8BCAF via T_F41AF0)"),
    0xF31B21: (BF_HEAD + [(6, 1, "swi 7 function"), (7, 4, "-> XIY: string table"),
                          (11, 2, "-> BC: bytes per entry"), (13, 2, "-> IX")],
               "string-table readout: HL = extracted value = entry index"),
    0xF31B39: (BF_HEAD + [(6, 1, "swi 7 function"), (7, 4, "-> XIY: string table"),
                          (11, 2, "-> BC: bytes per entry"), (13, 2, "-> (0x2530)"),
                          (15, 2, "-> (0x2532)")],
               "string-table readout with two extra words"),
    0xF31B57: (BF_HEAD + [(6, 1, "swi 7 function"),
                          (7, 4, "-> XIX: array of 8-byte entries, indexed by the value")],
               "four words of entry[value] -> (0x2530..0x2536)"),
    0xF31B86: (BF_HEAD + [(6, 1, "swi 7 function"),
                          (7, 4, "-> XIX: array of 6-byte entries, indexed by the value")],
               "entry[value] -> IY, BC, HL"),
    0xF31BD7: (BF_HEAD + [(6, 1, "swi 7 function"), (7, 2, "-> IX"),
                          (9, 1, "digit count"), (10, 1, "bit 7 set = unsigned, clear = signed")],
               "decimal readout, signed (0xF8BCC9 via T_F41AF8), buffer 0x2660"),
    0xF31C14: (BF_HEAD + [(6, 1, "swi 7 function"), (7, 2, "-> (0x2530)"),
                          (9, 2, "-> (0x2532)"), (11, 1, "digit count")],
               "decimal readout, unsigned, two extra words"),
    0xF31C56: (BF_HEAD + [(6, 1, "swi 7 function"), (7, 2, "-> (0x2530)"),
                          (9, 2, "-> (0x2532)"), (11, 1, "digit count"),
                          (12, 1, "bit 7 set = unsigned, clear = signed")],
               "decimal readout, signed, two extra words"),
    0xF31C9E: (BF_HEAD + [(6, 2, "-> (0x2530)"), (8, 2, "-> (0x2534)"),
                          (10, 2, "-> (0x2536); (0x2532) = it minus value/2")],
               "centred bar: function is hard-coded 0x0A"),
    0xF31D20: ([], "bare `ret` -- record skipped, only the length matters"),
}


def ownership(b, sites):
    own = {}
    for s, e, t in sorted(sites):
        if not (B_BASE <= s < 0xF80000):
            continue
        r = DL.walk(b, s, e)
        if r is None:
            continue
        for p, op, ln in r:
            own.setdefault(p, set()).add(t)
    return own


def render_b(b, p, op, ln, htb):
    h = htb[op]
    fields, note = B_LAYOUT[h]
    raw = b[p - B_BASE:p - B_BASE + ln]
    out = ["\t.byte 0x%02X, 0x%02X\t; B op %02X, %d bytes -> handler 0x%06X -- %s\n"
           % (op, ln, op, ln, h, note)]
    used = 2
    for off, w, name in fields:
        if off + w > ln:
            break
        v = int.from_bytes(raw[off:off + w], "little")
        out.append("\t%s 0x%0*X\t; +0x%02X %s\n"
                   % ({1: ".byte", 2: ".short", 4: ".long"}[w], w * 2, v, off, name))
        used = max(used, off + w)
    if used < ln:
        out.append("\t.byte %s\t; +0x%02X.. bytes no handler instruction reads\n"
                   % (", ".join("0x%02X" % c for c in raw[used:ln]), used))
    return out


def render(b, recs, hta, htb, starts, own):
    out = []
    for p, op, ln in recs:
        if p in starts:
            out.append("DL_%06X:\n" % p)
        if own.get(p) == {DL.RUN_B}:
            out += render_b(b, p, op, ln, htb)
        else:
            out += DL.render(b, [(p, op, ln)], hta, set())
    return out


def main():
    a, b = DL.load()
    sites = DL.call_sites(a, b)
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    htb = [int.from_bytes(b[0x31DB1 + i * 4:0x31DB1 + i * 4 + 4], "little") for i in range(15)]
    own = ownership(b, sites)
    starts = {s for s, e, t in sites}
    ok = []
    for s, e in DL.spans(sites):
        r = DL.walk(b, s, e)
        if r:
            ok.append((s, e, r))

    def opt(flag, dflt):
        return int(sys.argv[sys.argv.index(flag) + 1], 0) if flag in sys.argv else dflt
    lo, hi = opt("--lo", 0x00000), opt("--hi", 0x80000)
    out, cur = [], lo
    for s, e, r in ok:
        fs, fe = s - B_BASE, e - B_BASE
        if fs < lo or fe > hi:
            continue
        if fs > cur:
            out.append("\n; --- 0x%06X-0x%06X: not converted ---\n" % (B_BASE + cur, B_BASE + fs - 1))
            out.append('\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x%06X, 0x%06X\n' % (cur, fs - cur))
        ends = sorted({x[1] for x in sites if s <= x[0] < e})
        na = sum(1 for p, op, ln in r if own.get(p) != {DL.RUN_B})
        nb = len(r) - na
        which = ("interpreter A" if nb == 0 else
                 "interpreter B" if na == 0 else
                 "interpreter A (%d records) and B (%d)" % (na, nb))
        out.append("\n; ------------------------------------------------------------------\n")
        out.append("; 0x%06X-0x%06X -- %d display-list records, %d bytes -- %s\n"
                   % (s, e - 1, len(r), e - s, which))
        out.append(";   entered at: %s\n" % ", ".join("0x%06X" % x for x in sorted({y[0] for y in sites if s <= y[0] < e})))
        out.append(";   ends used:  %s\n" % ", ".join("0x%06X" % x for x in ends))
        out.append("; ------------------------------------------------------------------\n")
        out += render(b, r, hta, htb, starts, own)
        cur = fe
    if cur < hi:
        out.append("\n; --- 0x%06X-0x%06X: not converted ---\n" % (B_BASE + cur, B_BASE + hi - 1))
        out.append('\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x%06X, 0x%06X\n' % (cur, hi - cur))
    sys.stdout.write("".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
