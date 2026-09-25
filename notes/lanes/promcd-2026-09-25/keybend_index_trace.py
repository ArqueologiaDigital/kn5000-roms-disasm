#!/usr/bin/env python3
r"""Does prom_c ever index Voice_KeyBend_Curve_0 as far as its wrapped top rows?

QUESTION THIS ANSWERS
    wsa1/prom_c/data_tables/voice_dsp_tables.s: curve 0 (0xFDD3AB) is the low
    byte of the KN5000's Voice_KeyBend_Type41_Table, whose values pass +127 from
    key 115; read back signed, those rows are -122..-88 here.  The header left
    open "whether the WSA1 simply never indexes that far ... it needs the caller
    of 0xFA8016 traced".  Traced: in Voice_ComputePitch the index is the high
    byte of the voice's pitch word, which is built as
        (note << 8) & 0x7F00 | + 0x80           0xFA7F3A..0xFA7F48
        + master tune (0x1505) + part transpose + fine + octave shift
    and at 0xFA8016..0xFA8023 it is `sra 0x08` then `add XBC,<curve 0>` with no
    clamp between.  So an untransposed note n >= 115 reads a wrapped row.

    Asserts the cited encodings and prints which rows wrap.

RUN
    python3 notes/lanes/promcd-2026-09-25/keybend_index_trace.py [--apply]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
C = open(os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
SRC = os.path.join(ROOT, "wsa1", "prom_c", "data_tables", "voice_dsp_tables.s")
CODE = [(0xFA7F3A, "8c 05 21", "ld A,(XIX+0x05) -- the note"), (0xFA7F3F, "d8 ee 08", "sll 0x08,WA"),
        (0xFA7F42, "d8 cc 00 7f", "and WA,0x7f00"), (0xFA7F48, "db c8 80 00", "add HL,0x0080"),
        (0xFA8016, "da 89", "ld BC,DE -- the pitch word"), (0xFA8018, "d9 ed 08", "sra 0x08,BC"),
        (0xFA801D, "e9 c8 ab d3 fd 00", "add XBC,Voice_KeyBend_Curve_0 -- no clamp between"),
        (0xFA8023, "81 21", "ld A,(XBC)")]
ANCHOR = "; is NOT ESTABLISHED -- it needs the caller of 0xFA8016 traced.\n"
ADD = ("; ★ TRACED 2026-09-25 (lane promcd): the index is the high byte of the voice's pitch\n"
       "; word, which Voice_ComputePitch builds as (note << 8) + 0x80 plus master tune, part\n"
       "; transpose, fine tune and octave shift (0xFA7F3A-0xFA7F7F), and 0xFA8016-0xFA8023\n"
       "; shift it and add this table with NO clamp between.  So an untransposed note of 115\n"
       "; or above does read the wrapped rows (0x86 .. 0xA8 = -122 .. -88); the WSA1 does\n"
       "; index that far.  Whether the narrowing was intended stays open.\n"
       ";   python3 notes/lanes/promcd-2026-09-25/keybend_index_trace.py\n")

if __name__ == "__main__":
    for a, enc, what in CODE:
        want = bytes.fromhex(enc.replace(" ", ""))
        assert C[a - 0xF80000:a - 0xF80000 + len(want)] == want, (hex(a), what)
    t = C[0xFDD3AB - 0xF80000:0xFDD3AB - 0xF80000 + 128]
    wrapped = [k for k in range(96, 128) if t[k] >= 0x80]
    assert wrapped == list(range(115, 128)), wrapped
    print("  %d encodings hold; rows %d..%d are >= 0x80 (read back %d..%d)"
          % (len(CODE), wrapped[0], wrapped[-1], t[115] - 256, t[127] - 256))
    if "--apply" in sys.argv:
        s = open(SRC, "rb").read().decode("utf-8")
        assert s.count(ANCHOR) == 1 and "TRACED 2026-09-25 (lane promcd)" not in s
        data = s.replace(ANCHOR, ANCHOR + ADD).encode("utf-8")
        open(SRC, "wb").write(data)
        print("applied")
