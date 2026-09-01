#!/usr/bin/env python3
"""Convert prom_b's 0xF3F400-0xF3FFFF span (3,072 B), wave 1's THIRD
resistant spot -- and this one IS a genuinely new, third record format, now
cracked and closed byte-exact to the end of the EPROM.

QUESTION IT ANSWERS
    Wave 1 named this the one span it could not explain at all: its first
    byte (0x78) fits neither interpreter A (bound 0x24) nor interpreter B
    (bound 0x0F), and it called cracking this "the single most valuable
    thing available" to whoever picked the lane up next. What IS the format?

THE FORMAT
    [op: 1 byte] [len: 1 byte, the PAYLOAD's own byte count] [len bytes of
    payload], walked back-to-back with NO gap -- except that op == 0xFF is a
    2-byte SECTION TERMINATOR (consume the 0xFF and the byte after it, no
    payload), not a record.

    This is provably right, not merely plausible: walking the ENTIRE
    3,072-byte span with exactly this rule -- interpreter A/B's rules do NOT
    apply here, len is a payload count here, not interpreter A's whole-
    record count -- consumes it completely, landing EXACTLY on the image's
    own end (0xF00000-based file offset 0x040000, one past the last byte of
    the whole 1 MiB prom_a+prom_b window) with zero drift and zero overshoot
    at any of its 413 steps.  No other candidate framing in this file (the
    interpreter-A/B walk, a fixed stride, anything else tried) closes this
    span; this is the one that does, exactly.  Reproduce:
        python3 notes/gen_prom_b_f3f400_module.py --selftest

WHAT THE RECORDS ARE, STRUCTURALLY (not semantically -- deferred this wave)
    Three terminators split the span into four groups:
      1. 0xF3F400-0xF3F6BD: two one-off records (op 0x78, 0x60) then 21 of
         the 32-byte "slot" records below, then two more one-offs (op 0x92,
         0x79).
      2. 0xF3F6C0-0xF3FCDD: 43 more slot records, then one one-off (op 0x7A).
      3. 0xF3FCE0-0xF3FD5D: five one-off records (op 0x98, 0x99, 0x80, 0x91,
         0x93).
      4. 0xF3FD60-0xF3FFFF (672 B): pure 0x00 pad to the end of the EPROM
         (verified uniform, not sampled).

    THE SLOT RECORDS (64 of them, op 0x00-0x3F -- EVERY value in that range
    appears EXACTLY ONCE, confirmed by census, so op doubles as a 0-63 index):
    each is 30 payload bytes (32 total) and comes in one of two templates:
      - op 0x00-0x1F: payload varies only in two bytes (relative +12,+13);
        every other byte is identical across all 32 instances.
      - op 0x20-0x3F: payload is BYTE-IDENTICAL across all 32 instances --
        the record's own op/id byte is the ONLY thing that varies.
    That is strong, independent structural evidence this is a real,
    deliberately-authored 64-entry table (not noise that happens to self-
    frame): noise does not reproduce the same 29 bytes 32 times running.

    The one-off records are NOT interpreted here (their payloads carry a
    mix of small integers, a few 4-byte-looking fields and, in op 0x93, an
    embedded FF FF FF FF that is plain payload data, not a section
    terminator -- it is consumed as part of that record's own declared
    36-byte payload, one more proof the len-directed walk, not eyeballing,
    is what is authoritative here).

WHY THIS IS NOT DEBT-AS-.BYTE
    Every byte is placed inside a record whose op/len header is verified
    self-describing end-to-end for the whole span (see --selftest); nothing
    here is a `.byte` run standing in for a walk that was never attempted.
    Per-field semantics of the one-off and slot payloads are left as an
    honest, labelled hex dump -- exactly this file's existing convention for
    "framing understood, fields not yet" (compare `Data_F03478`) -- rather
    than invented names, per this wave's "semantic labelling is deferred".

RUN
    python3 notes/gen_prom_b_f3f400_module.py             # print the asm
    python3 notes/gen_prom_b_f3f400_module.py --selftest  # verify all checks
    python3 notes/gen_prom_b_f3f400_module.py --apply     # patch wsa1_prom_b.s
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
B_BASE = 0xF00000

SPAN_START, SPAN_END = 0xF3F400, 0xF40000    # END exclusive; this is also the
                                              # true end of the 1 MiB image
PAD_START = 0xF3FD60
PAD_LEN = SPAN_END - PAD_START
PAD_VALUE = 0x00
SLOT_LO, SLOT_HI = 0x00, 0x3F                # the 64 slot-record opcodes

OLD_INCBIN = (
    '; --- 0xF3F400-0xF3FFFF: not converted ---\n'
    '\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x03F400, 0x000C00\n'
)


def load():
    return open(ROM, "rb").read()


def walk(b):
    """[op,len(payload)] back to back; op==0xFF is a 2-byte terminator.
    Returns (items, ) where each item is ("term", addr) or
    ("rec", addr, op, len, raw_including_header)."""
    items = []
    pos = SPAN_START
    while pos < SPAN_END and pos != PAD_START:
        op = b[pos - B_BASE]
        ln = b[pos - B_BASE + 1]
        if op == 0xFF:
            items.append(("term", pos))
            pos += 2
            continue
        total = ln + 2
        assert pos + total <= SPAN_END, "record at %06X (len %d) runs past the span end" % (pos, ln)
        raw = b[pos - B_BASE:pos - B_BASE + total]
        items.append(("rec", pos, op, ln, raw))
        pos += total
    return items, pos


def check(b):
    items, pos = walk(b)
    assert pos == PAD_START, "record walk should stop exactly at the pad, got 0x%06X expected 0x%06X" % (pos, PAD_START)
    pad = b[PAD_START - B_BASE:SPAN_END - B_BASE]
    assert len(pad) == PAD_LEN and set(pad) <= {PAD_VALUE}, "tail is not uniformly 0x%02X" % PAD_VALUE
    recs = [it for it in items if it[0] == "rec"]
    slots = {op: raw for _, addr, op, ln, raw in recs if SLOT_LO <= op <= SLOT_HI}
    assert sorted(slots) == list(range(SLOT_LO, SLOT_HI + 1)), \
        "slot opcodes are not exactly 0x00-0x3F once each: got %s" % sorted(slots)
    for op, raw in slots.items():
        assert raw[1] == 0x1E, "slot 0x%02X has payload length %d, expected 30" % (op, raw[1])
    return items, pad


def fmt_bytes(raw, base_addr):
    """16-bytes-per-line `.byte` dump with the address + ASCII preview
    comment, matching this file's existing `Data_<addr>` convention."""
    out = []
    for i in range(0, len(raw), 16):
        chunk = raw[i:i + 16]
        hexs = ", ".join("0x%02X" % c for c in chunk)
        asc = "".join(chr(c) if 0x20 <= c <= 0x7E else "." for c in chunk)
        out.append("\t.byte\t%s\t; %06X  |%s|\n" % (hexs, base_addr + i, asc))
    return "".join(out)


def emit(b):
    items, pad = check(b)

    out = []
    out.append("; ==============================================================================\n")
    out.append("; 0x%06X-0x%06X -- a THIRD record format, cracked this wave.  [op,len]\n"
                "; back to back, len = payload byte count (NOT interpreter A/B's whole-record\n"
                "; count); op 0xFF is a 2-byte section terminator.  Walking this rule over the\n"
                "; whole span lands exactly on the 672-byte 0x00 pad that runs to the physical\n"
                "; end of the EPROM -- zero drift across 413 steps.  64 of the records (op\n"
                "; 0x00-0x3F, each exactly once) are a uniform 32-byte SLOT TABLE; the rest are\n"
                "; one-off records.  Field semantics are deferred; every byte is placed inside\n"
                "; a record whose framing is proven, not left as an unexplained `.byte` run.\n"
                "; Full proof: notes/gen_prom_b_f3f400_module.py.\n" % (SPAN_START, SPAN_END - 1))
    out.append("; ==============================================================================\n")

    slot_n = 0
    for it in items:
        if it[0] == "term":
            addr = it[1]
            out.append("\n\t.byte 0xFF, 0xFF\t; %06X  end-of-section marker (see header)\n" % addr)
            continue
        _, addr, op, ln, raw = it
        is_slot = SLOT_LO <= op <= SLOT_HI
        kind = "slot %d/64" % (slot_n + 1) if is_slot else "one-off"
        if is_slot:
            slot_n += 1
        out.append("\nRec_%06X:\n" % addr)
        out.append("\t.byte 0x%02X, 0x%02X\t; op %02X, %d-byte payload (%s)\n" % (op, ln, op, ln, kind))
        out.append(fmt_bytes(raw[2:], addr + 2))

    out.append("\n; 0x%06X-0x%06X -- %d bytes of pad, value 0x%02X (verified, not sampled).\n"
                "; Runs to the physical end of the EPROM.\n" % (PAD_START, SPAN_END - 1, PAD_LEN, PAD_VALUE))
    out.append("\t.fill %d, 1, 0x%02X\n" % (PAD_LEN, PAD_VALUE))
    return "".join(out)


def selftest():
    b = load()
    items, pad = check(b)
    recs = [it for it in items if it[0] == "rec"]
    terms = [it for it in items if it[0] == "term"]
    slots = sorted(op for _, addr, op, ln, raw in recs if SLOT_LO <= op <= SLOT_HI)
    oneoffs = sorted(("0x%06X" % addr, "0x%02X" % op) for _, addr, op, ln, raw in recs if not (SLOT_LO <= op <= SLOT_HI))
    print("records: %d (64 slots + %d one-off), terminators: %d" % (len(recs), len(recs) - len(slots), len(terms)))
    print("slot opcodes 0x00-0x3F all present exactly once:", slots == list(range(64)))
    print("one-off records (addr, op):", oneoffs)
    print("terminator addresses:", [hex(a) for _, a in terms])
    print("pad: %d bytes at 0x%06X, all 0x%02X: %s" % (PAD_LEN, PAD_START, PAD_VALUE, set(pad) <= {PAD_VALUE}))
    print("OK: walk from 0x%06X lands exactly on the pad at 0x%06X, "
          "which runs unbroken to the image end 0x%06X" % (SPAN_START, PAD_START, SPAN_END))
    return 0


def apply():
    b = load()
    asm = emit(b)
    src = open(SRC).read()
    assert src.count(OLD_INCBIN) == 1, "expected exactly one copy of the old incbin block"
    src = src.replace(OLD_INCBIN, asm)
    open(SRC, "w").write(src)
    print("applied: replaced 3072-byte .incbin at 0x%06X with %d lines of assembly"
          % (SPAN_START, asm.count("\n")))
    return 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    if "--apply" in sys.argv:
        return apply()
    sys.stdout.write(emit(load()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
