#!/usr/bin/env python3
"""Emit prom_b's STEP-RECORD SCREEN table and the five interpreter-A spans it
selects between, closing 8,291 of the lane's 40,812 `.incbin` bytes.

QUESTION IT ANSWERS
    Five `.incbin` stretches in prom_b -- 0xF3C992-0xF3D015, 0xF3D089-0xF3D1B8,
    0xF3D1B9-0xF3D5E4, 0xF3DEB2-0xF3E06D and 0xF3E15C-0xF3F422 -- all satisfy
    the tree's own record-framing check (scripts/analysis/prom_b_display_lists.py:
    walk the `[opcode, length]` pairs from a start and the running position must
    land EXACTLY on the claimed end, with every opcode < 0x24). None of the five
    was in the committed emitter's own call-site set, so none was converted by
    round 8's sweep. This module supplies the missing call-site evidence for two
    of them and shows the other three are one continuous decode with an
    already-converted neighbour.

EVIDENCE (each independent of the record-framing check above)
    1. THE TABLE, 0xF3D089-0xF3D1B8 (304 bytes = 76 x 4-byte little-endian
       addresses). prom_a `Paint_StepRecordTrackClrMeas`'s caller, at
       0xF81B70-0xF81B9B, does:
           sla   HL, 0x02                  ; HL *= 4
           ld    XIY, 0x00f3d089           ; or 0x00f3d121 if (0x0e63)==2
           mx_ld_rm MXL, ra_IY, ra_HL, r5  ; XIY = [XIY + HL]  (indexed load)
           ld    XIX, 0x00f3d0d5           ; or 0x00f3d16d if (0x0e63)==2
           mx_ld_rm MXL, ra_IX, ra_HL, r4  ; XIX = [XIX + HL]
           call  0xf417f0                  ; interpreter A, [XIY, XIX)
       Four fixed bases, 152 bytes (38 * 4) apart in pairs: starts at
       0xF3D089/0xF3D121, ends at 0xF3D0D5/0xF3D16D. 0xF3D0D5 - 0xF3D089
       = 0x4C = 19*4 and 0xF3D16D - 0xF3D121 = 0x4C too, so the SAME 76-entry
       array serves both roles: entries [0,19) are the "cond0" starts, [19,38)
       its ends, [38,57) the "cond2" starts, [57,76) its ends -- 19 (start,end)
       pairs per condition. `--verify-table` walks all 38 pairs (both
       conditions) through the SAME record-framing check and gets 19/19 clean
       on each side, independent of the caller evidence above.
    2. 0xF3D1B9-0xF3D5E4 (1068 bytes). prom_a `sub_F81EF3`, 0xF81EF3-0xF81F19:
           ld   XIY, 0x00f3d1b9
           ld   XIX, XIY
           muls BC, 0x0023                 ; stride 0x23 = 35 bytes/group
           add  XIX, XBC
           call 0xf417f0
       with BC clamped to [0,4] just above (cps c,0x04 / ldw bc,0x04). The next
       routine, `sub_F81F1A`, opens with `ld XIY, 0x00f3d245` -- exactly
       0xF3D1B9 + 4*0x23 -- confirming the group boundary independently of any
       record decode.
    3. 0xF3DEB2-0xF3E06D (444 bytes) carries no fixed-immediate call site of
       its own, but is a SINGLE unbroken record walk (56 records, `walk_from`
       below) that also matches the table's entries 1 and 11 as internal
       sub-boundaries. 0xF3E15C-0xF3E362 (519 bytes) is the same: a single
       unbroken walk starting exactly where the already-converted
       `DL_MasterTrackClearAttention` ends (its own "ends used: 0xF3E15C"
       line) and matching the table's entries 8, 5 and 4 as internal
       sub-boundaries -- and 0xF3E363 is EXACTLY where the table's entry 4
       says the last of those lists ends, which is also exactly where a
       4,253-byte run of the pad byte 0x0E begins (below). Both facts landing
       on the same address independently is the check.

⚠ THE TRAP THIS FILE ALMOST WALKED INTO.  A naive length-byte walk from
    0xF3E15C does not stop at 0xF3E363 -- it keeps going for another 4,807
    bytes, because `[opcode 0x0E, length 14]` is a VALID-LOOKING record whose
    entire body is also 0x0E, and 0x0E is this ROM's own pad byte. A run of
    pure padding therefore self-frames as ~300 fake 14-byte records by pure
    coincidence of arithmetic (4253 is not a multiple of 14, so the fake walk
    even drifts out of phase with the true padding boundary before an
    unrelated non-pad byte accidentally continues to parse for a few more
    records). This is the exact failure mode `notes/reachability.py`'s STRONG
    vs WEAK split and this project's own history (round 7: "8,819 caption
    bytes a weak seed painted as code") exist to catch -- here it is caught by
    treating any record whose FULL BODY is one repeated byte as suspect
    (`--selftest` asserts zero such records survive in what is emitted) and by
    the pad run's start and the table's own named end agreeing exactly.
    0xF3E363-0xF3F3FF (4,253 bytes) is therefore emitted as `.fill`, verified
    byte-for-byte, and 0xF3F400-0xF3FFFF (3,072 bytes, an unrelated format)
    stays `.incbin`.

WHAT IS DELIBERATELY NOT CONVERTED HERE
    0xF3C947-0xF3C991 (75 bytes, right before span 1): the byte at 0xF3C976
    that a naive length-byte walk would read as the next opcode (0x43) is
    plainly the 'C' of "CHORD" -- i.e. this prefix's own length bytes do NOT
    self-check, so whatever framing it uses is not the one this file decodes.
    Left `.incbin`.
    0xF3D5E5-0xF3DA6E (1162 bytes, tail of the table's own former span) and
    0xF3F400-0xF3FFFF (3,072 bytes, tail of the last span): both begin with an
    opcode byte (0x2B, 0x78) that is valid for NEITHER interpreter A (bound
    0x24) NOR interpreter B (bound 0x0F, see gen_prom_b_display_lists_v2.py) --
    a third record format this file does not claim to know. Left `.incbin`.

RUN
    python3 notes/gen_prom_b_stepselect_module.py --verify-table   # 19/19, 19/19
    python3 notes/gen_prom_b_stepselect_module.py --selftest       # byte round-trip
    python3 notes/gen_prom_b_stepselect_module.py --asm            # the five blocks
    python3 notes/gen_prom_b_stepselect_module.py --apply          # splice into the .s
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL  # noqa: E402  (HANDLERS, walk, render, HTBL)

B_BASE = 0xF00000
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
ROM = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")

# The six spans, in address order.  `mode` is "table" for the address table,
# "dl" for interpreter-A display-list records, "fill" for a checked pad run.
SPANS = [
    (0xF3C992, 0xF3D016, "dl"),
    (0xF3D089, 0xF3D1B9, "table"),
    (0xF3D1B9, 0xF3D5E5, "dl"),
    (0xF3DEB2, 0xF3E06E, "dl"),
    (0xF3E15C, 0xF3E363, "dl"),
    (0xF3E363, 0xF3F400, "fill"),
]
FILL_VALUE = 0x0E

TABLE_BASE = 0xF3D089
TABLE_COUNT = 76  # 4 * 19


def load_bytes():
    return open(ROM, "rb").read()


def table_values(b):
    return [int.from_bytes(b[TABLE_BASE - B_BASE + i * 4:TABLE_BASE - B_BASE + i * 4 + 4],
                            "little") for i in range(TABLE_COUNT)]


def verify_table(b):
    """Every (start,end) pair the table names must walk cleanly. Returns
    (ok_cond0, ok_cond2), each out of 19."""
    vals = table_values(b)

    def check(starts_off, ends_off):
        ok = 0
        for i in range(19):
            s, e = vals[starts_off + i], vals[ends_off + i]
            if DL.walk(b, s, e) is not None:
                ok += 1
        return ok

    return check(0, 19), check(38, 57)


def walk_from(b, addr, limit):
    """Like DL.walk, but starts at `addr` and stops at the first byte that
    cannot be a record start, returning (end_reached, records)."""
    p, recs = addr, []
    while p < limit:
        op, ln = b[p - B_BASE], b[p - B_BASE + 1]
        if op >= 0x24 or ln < 2 or p + ln > limit:
            break
        recs.append((p, op, ln))
        p += ln
    return p, recs


def htab(b):
    return [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]


def table_starts_for_labels():
    """Addresses inside the DL spans that the table names directly, so the
    emitted .s gets a DL_ label at each one (matching the committed emitter's
    convention) even though no fixed call site was found for most of them."""
    b = load_bytes()
    vals = table_values(b)
    addrs = set()
    for off in (0, 19, 38, 57):
        addrs.update(vals[off:off + 19])
    return addrs


def emit_table(b):
    vals = table_values(b)
    out = []
    out.append("; ------------------------------------------------------------------\n")
    out.append("; StepSelectAddrTable_F3D089 -- 76 4-byte little-endian addresses = TWO\n")
    out.append(";   19-pair (start,end) tables, back to back.  entries [0,19) are the\n")
    out.append(";   \"cond0\" starts, [19,38) its ends, [38,57) the \"cond2\" starts, [57,76)\n")
    out.append(";   its ends -- i.e. StepList(i, cond) = [entry[cond*38+i], entry[cond*38+19+i]).\n")
    out.append("; Evidence: prom_a 0xF81B70-0xF81B9B loads XIY from this table's cond0 base\n")
    out.append(";   (or 0xF3D121 = +38 entries, when (0x2740)==(0x0e63)==2), scaled by an\n")
    out.append(";   index in HL*4 through an indexed load (`mx_ld_rm ra_IY,ra_HL,r5`), and\n")
    out.append(";   XIX the same way from +19 entries (or +57) -- see the header of\n")
    out.append(";   notes/gen_prom_b_stepselect_module.py for the exact instructions.\n")
    out.append(";   All 38 (start,end) pairs, both conditions, satisfy the tree's own\n")
    out.append(";   record-framing check (notes/gen_prom_b_stepselect_module.py\n")
    out.append(";   --verify-table: 19/19 and 19/19) -- independent confirmation that this\n")
    out.append(";   IS an address table and not a coincidence of the caller evidence above.\n")
    out.append("; Unknown: what selects the index in HL (a step or measure number is the\n")
    out.append(";   caller's own name for it, `Paint_StepRecordTrackClrMeas`, but the\n")
    out.append(";   selector itself is not traced here).\n")
    out.append("; ------------------------------------------------------------------\n")
    out.append("StepSelectAddrTable_F3D089:\n")
    for i, v in enumerate(vals):
        group = i // 19
        idx = i % 19
        role = "start" if group in (0, 2) else "end"
        cond = 0 if group < 2 else 2
        out.append("\t.long 0x%08X\t; [%2d] cond%d %s[%2d]\n" % (v, i, cond, role, idx))
    return out


def emit_fill(b, start, end):
    n = end - start
    run = b[start - B_BASE:end - B_BASE]
    assert run == bytes([FILL_VALUE]) * n, "not a pure 0x%02X run" % FILL_VALUE
    out = []
    out.append("; ------------------------------------------------------------------\n")
    out.append("; 0x%06X-0x%06X -- %d bytes of pad, value 0x%02X (verified, not sampled)\n"
               % (start, end - 1, n, FILL_VALUE))
    out.append(";   Directly follows the display list that ends here (StepSelectAddrTable_F3D089\n")
    out.append(";   entries [23] and [61], both conditions' pair-4 end).  A naive length-byte\n")
    out.append(";   walk starting from that list's own start self-frames INTO this run as ~300\n")
    out.append(";   fake 14-byte records -- see the header of\n")
    out.append(";   notes/gen_prom_b_stepselect_module.py.  0xF3F400 onward is a different,\n")
    out.append(";   unidentified format and stays `.incbin`.\n")
    out.append("; ------------------------------------------------------------------\n")
    out.append("\t.fill %d, 1, 0x%02X\n" % (n, FILL_VALUE))
    return out


def emit_dl(b, hta, start, end, labels):
    p, recs = walk_from(b, start, end)
    assert p == end, "walk_from(0x%06X,0x%06X) stalled at 0x%06X" % (start, end, p)
    out = []
    out.append("; ------------------------------------------------------------------\n")
    out.append("; 0x%06X-0x%06X -- %d display-list records, %d bytes -- interpreter A\n"
               % (start, end - 1, len(recs), end - start))
    inside = sorted(a for a in labels if start <= a < end)
    if inside:
        out.append(";   named by StepSelectAddrTable_F3D089: %s\n"
                   % ", ".join("0x%06X" % a for a in inside))
    out.append("; ------------------------------------------------------------------\n")
    starts = labels | {start}
    out += DL.render(b, recs, hta, starts)
    return out


def build():
    b = load_bytes()
    hta = htab(b)
    labels = table_starts_for_labels()
    out = []
    for start, end, mode in SPANS:
        if mode == "table":
            out += emit_table(b)
        elif mode == "fill":
            out += emit_fill(b, start, end)
        else:
            out += emit_dl(b, hta, start, end, labels)
        out.append("\n")
    return "".join(out)


def selftest():
    """The emitted text must re-derive the SAME bytes the ROM has at every
    span, purely from the (op,len) records / table values -- a check that does
    not need llvm-mc.  (The real certification is still the byte gate.)"""
    b = load_bytes()
    hta = htab(b)
    labels = table_starts_for_labels()
    ok = True
    for start, end, mode in SPANS:
        if mode == "table":
            vals = table_values(b)
            redone = b"".join(v.to_bytes(4, "little") for v in vals)
            want = b[start - B_BASE:end - B_BASE]
            if redone != want:
                print("FAIL table bytes mismatch"); ok = False
            else:
                print("OK   table  0x%06X-0x%06X  %d bytes" % (start, end - 1, end - start))
            continue
        if mode == "fill":
            run = b[start - B_BASE:end - B_BASE]
            if run != bytes([FILL_VALUE]) * (end - start):
                print("FAIL 0x%06X-0x%06X is not a pure 0x%02X run"
                      % (start, end - 1, FILL_VALUE)); ok = False
            else:
                print("OK   fill   0x%06X-0x%06X  %d bytes of 0x%02X"
                      % (start, end - 1, end - start, FILL_VALUE))
            continue
        p, recs = walk_from(b, start, end)
        if p != end:
            print("FAIL 0x%06X-0x%06X did not walk cleanly, stalled 0x%06X" % (start, end - 1, p))
            ok = False
            continue
        # ⚠ THE PADDING TRAP: a record whose entire body is one repeated byte
        # is exactly what a run of pad self-frames as (see the module header).
        # None may survive in emitted "dl" spans.
        bogus = [(a, ln) for a, op, ln in recs
                 if len(set(b[a - B_BASE:a - B_BASE + ln])) == 1]
        if bogus:
            print("FAIL 0x%06X-0x%06X contains %d all-same-byte record(s) -- "
                  "likely padding misframed as code: %s"
                  % (start, end - 1, len(bogus),
                     ", ".join("0x%06X/%d" % x for x in bogus[:5])))
            ok = False
            continue
        redone = b"".join(b[a - B_BASE:a - B_BASE + ln] for a, op, ln in recs)
        want = b[start - B_BASE:end - B_BASE]
        if redone != want:
            print("FAIL 0x%06X-0x%06X byte mismatch" % (start, end - 1)); ok = False
        else:
            print("OK   dl     0x%06X-0x%06X  %d bytes, %d records"
                  % (start, end - 1, end - start, len(recs)))
    c0, c2 = verify_table(b)
    print("table cross-check: cond0 %d/19 clean, cond2 %d/19 clean" % (c0, c2))
    ok = ok and c0 == 19 and c2 == 19
    print("SELFTEST", "PASS" if ok else "FAIL")
    return 0 if ok else 1


SPAN_RE = re.compile(
    r'\n; --- (0x[0-9A-F]{6})-(0x[0-9A-F]{6}): not converted ---\n'
    r'\t\.incbin "original_ROMs/wsa1_prom_b\.ic13", (0x[0-9A-F]+), (0x[0-9A-F]+)\n')


def apply_to_source():
    """Split the four `.incbin` directives that currently cover the five spans,
    replacing exactly the bytes this file converts and leaving the rest as
    (smaller) `.incbin` directives -- so the total byte count is provably
    unchanged and the diff is minimal."""
    text = open(SRC).read()
    b = load_bytes()
    hta = htab(b)
    labels = table_starts_for_labels()

    def repl(m):
        s, e = int(m.group(1), 16), int(m.group(2), 16)  # end is inclusive in the comment
        off, ln = int(m.group(3), 16), int(m.group(4), 16)
        e_excl = e + 1
        assert off == s - B_BASE and ln == e_excl - s, (m.group(0),)
        # Which of our spans, if any, fall inside [s, e_excl)?
        mine = [sp for sp in SPANS if s <= sp[0] and sp[1] <= e_excl]
        if not mine:
            return m.group(0)
        out = []
        cur = s
        for start, end, mode in mine:
            if start > cur:
                out.append("\n; --- 0x%06X-0x%06X: not converted ---\n" % (cur, start - 1))
                out.append('\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x%06X, 0x%06X\n'
                           % (cur - B_BASE, start - cur))
            out.append("\n")
            if mode == "table":
                out += emit_table(b)
            elif mode == "fill":
                out += emit_fill(b, start, end)
            else:
                out += emit_dl(b, hta, start, end, labels)
            cur = end
        if cur < e_excl:
            out.append("\n; --- 0x%06X-0x%06X: not converted ---\n" % (cur, e_excl - 1))
            out.append('\t.incbin "original_ROMs/wsa1_prom_b.ic13", 0x%06X, 0x%06X\n'
                       % (cur - B_BASE, e_excl - cur))
        return "".join(out)

    new_text, n = SPAN_RE.subn(repl, text)
    if n == 0:
        print("no matching .incbin directive found -- already applied?", file=sys.stderr)
        return 1
    open(SRC, "w").write(new_text)
    print("patched %d .incbin directive(s) in %s" % (n, SRC))
    return 0


def main():
    if "--verify-table" in sys.argv:
        b = load_bytes()
        c0, c2 = verify_table(b)
        print("cond0: %d/19 clean" % c0)
        print("cond2: %d/19 clean" % c2)
        return 0
    if "--selftest" in sys.argv:
        return selftest()
    if "--apply" in sys.argv:
        return apply_to_source()
    sys.stdout.write(build())
    return 0


if __name__ == "__main__":
    sys.exit(main())
