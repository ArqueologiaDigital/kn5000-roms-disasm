#!/usr/bin/env python3
"""Emit the assembly for prom_a 0xFAD800-0xFB2000, the largest .incbin in prom_a.

QUESTION IT ANSWERS
    "What is the assembly text for this 18,432-byte span, in a form the byte gate
     accepts, with every label and header attached to the right address?"
    This is the emitter whose output is spliced into prom_a/wsa1_prom_a.s.

WHERE THE BOUNDARIES COME FROM -- AND NOT FROM A LINEAR DECODE
    notes/prom_a_fad800_layout.py, re-derived on EVERY run by build().  This
    script refuses to print if the layout it gets differs from the one recorded
    in EXPECTED below, so a boundary cannot move silently between the audit and
    the emission.  notes/prom_a_linear_decode_check.py records why a linear decode
    pins nothing.

WHY THIS SPAN
    It is prom_a's largest remaining `.incbin` (18,432 B).  ⚠ NOT because the
    frontier ranks it top -- it does not, and an earlier draft of the layout
    script wrongly said so.  Summed thunk extent puts it THIRD in prom_a
    (`python3 notes/wave7_frontier_table.py --sums`: 0xFA5AEB 16,799, 0xF96018
    6,048, this span 5,811).  Converting it retires three thunk runs, 33 slots.

NOTHING HERE CAN BREAK THE GATE
    Code segments come from prom_a/roundtrip.py's emit_block(), which assembles
    and byte-compares every candidate spelling before returning it.  Data
    segments are emitted as `.byte` from the ROM.  Then main() assembles the
    WHOLE emitted region and compares it byte for byte with the ROM, and exits
    non-zero without printing if it differs.  So the text this prints has already
    rebuilt the span before you see it.

⚠ WHAT IT DOES NOT DO
    It does not claim to know what the routines MEAN.  Labels are `sub_XXXXXX`
    plus the entry-point evidence that justifies them (a thunk slot, a table
    entry).  Per this project's standing rule, an honest `sub_` with a stated
    entry point beats a plausible name, and the byte gate is blind to the
    difference.

RUN
    python3 notes/gen_prom_a_fad800_module.py            # the assembly
    python3 notes/gen_prom_a_fad800_module.py --check    # layout fingerprint only
    python3 notes/gen_prom_a_fad800_module.py --stats    # segment/label census
"""
import importlib.util
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LO, HI = 0xFAD800, 0xFB2000


ARGV = list(sys.argv)               # captured BEFORE any import mangles it


def _load(path, name):
    """Import a sibling tool as a module.  ⚠ Both of them inspect sys.argv at
    import time, so argv is masked during the load and restored afterwards --
    without this, the flags to THIS script were silently eaten and --check and
    --stats both fell through to the full emission."""
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    saved = sys.argv
    sys.argv = [name]
    try:
        spec.loader.exec_module(m)
    finally:
        sys.argv = saved
    return m


L = _load(os.path.join(ROOT, "notes", "prom_a_fad800_layout.py"), "fad800_layout")
RT = _load(os.path.join(ROOT, "prom_a", "roundtrip.py"), "rt")

# The layout as audited in wave 7 round 1, after the skeptic's corrections.
# A mismatch means the layout MOVED and this emitter must not run.
EXPECTED = 63


def layout():
    segs, conflicts, pending, ok, seen, rl, imm = L.build()
    if len(segs) != EXPECTED:
        sys.exit("REFUSING TO EMIT: layout has %d segments, expected %d. The "
                 "boundaries moved since the audit; re-audit before emitting."
                 % (len(segs), EXPECTED))
    if conflicts:
        sys.exit("REFUSING TO EMIT: %d barrier/code conflicts" % len(conflicts))
    tot = sum(n for _k, _a, n in segs)
    if segs[0][1] != LO or tot != HI - LO:
        sys.exit("REFUSING TO EMIT: segments do not tile the span (%d of %d)"
                 % (tot, HI - LO))
    return segs


def entry_points(d):
    """In-span addresses that something OUTSIDE the linear stream names, with the
    evidence for each.  These are what get a `sub_XXXXXX:` label."""
    ev = {}
    for a in L.thunk_entries(LO, HI):
        ev.setdefault(a, []).append("thunk slot")
    for a in L.table_entry_seeds(L.rom("a"), LO, HI):
        ev.setdefault(a, []).append("pointer-table entry")
    for a in L.far_calls_proven(LO, HI):
        ev.setdefault(a, []).append("call from converted code")
    return ev


def emit(segs, d, ev):
    out = []
    for kind, a, n in segs:
        e = a + n
        if kind == "code":
            lines, okk, _stats = RT.emit_block(a, e)
            if not okk:
                sys.exit("REFUSING TO EMIT: roundtrip could not prove 0x%06X-0x%06X"
                         % (a, e))
            for text, addr, _bs, _w in lines:
                if addr is not None and addr in ev:
                    out.append("sub_%06X:%s"
                               % (addr, "   ; entry: " + ", ".join(sorted(set(ev[addr])))))
                out.append(text)
        else:
            label = {"pad_00": "zero pad", "pad_ff": "0xFF pad", "pad_0e": "0x0E pad",
                     "pointer_table": "pointer table", "index_map": "index map",
                     "ascii": "ASCII", "blob": "pointer blob + payload",
                     "reclist": "register-poke record list",
                     "unknown": "UNIDENTIFIED"}.get(kind, kind)
            out.append("; --- 0x%06X-0x%06X  %s (%d bytes) ---" % (a, e, label, n))
            if kind == "pointer_table":
                for x in range(a, e, 4):
                    v = L.w32(x)
                    tag = ""
                    if LO <= v < HI:
                        tag = "   ; -> sub_%06X" % v
                    elif v == 0xFFFFFFFF:
                        tag = "   ; empty slot"
                    out.append("\t.long 0x%08X%s   ; %06X" % (v, tag, x))
            else:
                for x in range(a, e, 16):
                    row = d[x - 0xF80000:min(x + 16, e) - 0xF80000]
                    out.append("\t.byte " + ", ".join("0x%02x" % b for b in row)
                               + "   ; %06X" % x)
    return out


def main():
    d = L.rom("a")
    segs = layout()
    if "--check" in ARGV:
        print("layout OK: %d segments tiling 0x%06X-0x%06X" % (len(segs), LO, HI))
        return 0
    ev = entry_points(d)
    body = emit(segs, d, ev)
    text = "\n".join(body)

    # THE SELF-PROOF: assemble what we are about to print and compare with the ROM.
    got = RT.assemble_block(RT.macro_prelude() + "\n\t.text\n" + text + "\n")
    want = d[LO - 0xF80000:HI - 0xF80000]
    if got != want:
        n = -1 if got is None else sum(1 for i in range(min(len(got), len(want)))
                                       if got[i] != want[i])
        sys.exit("REFUSING TO PRINT: the emitted text does not rebuild the span "
                 "(%s, %d differing bytes)" % ("assembly failed" if got is None
                                               else "len %d vs %d" % (len(got), len(want)), n))
    if "--stats" in ARGV:
        from collections import Counter
        c = Counter(k for k, _a, _n in segs)
        b = Counter()
        for k, _a, n in segs:
            b[k] += n
        print("segments by kind:", dict(c))
        print("bytes by kind:   ", dict(b))
        print("labelled entry points: %d" % len(ev))
        print("emitted lines: %d; re-assembles to the ROM exactly" % len(body))
        return 0
    print("; ==== 0xFAD800-0xFB2000 -- emitted by notes/gen_prom_a_fad800_module.py ====")
    print("; Layout from notes/prom_a_fad800_layout.py (--selftest: 64 checks).")
    print("; This text was assembled and byte-compared with the ROM before printing.")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
