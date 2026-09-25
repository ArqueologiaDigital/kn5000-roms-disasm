#!/usr/bin/env python3
r"""What RAM 0x2252 / 0x2256 hold: two 32-bit sets of HELD panel event codes.

QUESTION THIS ANSWERS
    PanelButton_InterlockMask32's header ended "Unknown: what (0x2252)/(0x2256)
    hold.  The bit space is NOT the button index space of the table above; it
    is offset by 17."  The only writers are four action handlers of
    PanelGroupActionListPool, and their bodies answer both halves.

CHECKS (against wsa1/original_ROMs)
    S1  the only instructions touching (0x2252)/(0x2256) outside
        PanelButton_Accept are in sub_F8AE68, sub_F8AEDB, sub_F8AF4E and
        sub_F8AF81 (scan of the 16-bit operand forms e1 52 22 / e1 56 22)
    S2  each handler: E = (XIX-1) + 1 -> IndexToBitMask32 (bit = the event
        CODE); on press (C != 0) `or (set),XDE`, on release `and (set),~XDE`;
        sub_F8AE68/sub_F8AF4E use (0x2252), sub_F8AEDB/sub_F8AF81 (0x2256)
    S3  sub_F8AE68/sub_F8AEDB: a press whose bit is already set is rewritten
        `add (XIX-1),0x11` and its mask shifted `sla 16 / sla 1` (17 places)
    S4  the event codes the pool routes to them (via the v1/v2 event lists)
        are class A9 codes 0x00..0x10 only

RUN
    python3 notes/proma-2026-09-25/gen_held_sets.py
    python3 notes/proma-2026-09-25/gen_held_sets.py --apply   # ran once
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import srcmap  # noqa: E402

B = srcmap.BASE
HANDLERS = {0xF8AE68: 0x52, 0xF8AEDB: 0x56, 0xF8AF4E: 0x52, 0xF8AF81: 0x56}


def seg(r, a, n):
    return r[a - B:a - B + n]


def l32(r, a):
    return int.from_bytes(seg(r, a, 4), "little")


def checks(r):
    sites = [B + i for i in range(len(r) - 3) if r[i] == 0xE1 and r[i + 1] in (0x52, 0x56) and r[i + 2] == 0x22]
    inside = lambda a: any(h <= a < h + 0x73 for h in HANDLERS) or 0xF8669F <= a <= 0xF866A7  # noqa: E731
    assert all(inside(a) for a in sites), [hex(a) for a in sites if not inside(a)]
    print("S1 ok: %d operand sites, all in the four handlers or PanelButton_Accept" % len(sites))
    for h, lo in HANDLERS.items():
        b = seg(r, h, 0x33)
        assert b.startswith(bytes.fromhex("da898cff25cd611e")), hex(h)          # ld BC,DE / ld E,(XIX-1) / inc E / calr
        tgt = h + 10 + int.from_bytes(seg(r, h + 8, 2), "little", signed=True)   # calr at h+7
        assert tgt == 0xF8A97D, hex(h)                                          # IndexToBitMask32
        assert bytes([0xE1, lo, 0x22, 0xEA]) in seg(r, h, 0x72), hex(h)        # or (set),XDE
        assert bytes([0xE1, lo, 0x22, 0xCA]) in seg(r, h, 0x72), hex(h)        # and (set),XDE
    for h in (0xF8AE68, 0xF8AEDB):
        assert bytes.fromhex("8cff3811eaec00eaec01") in seg(r, h, 0x40), hex(h)
    print("S2/S3 ok: set on press, clear on release; a repeat press is code + 0x11 at bit + 17")
    H = {}
    for v, t in ((1, 0xF8B74A), (2, 0xF8B7AE)):
        for g in range(25):
            p = l32(r, t + 4 * g)
            while seg(r, p, 2) != b"\xff\xff":
                q = seg(r, p, 6)
                H.setdefault(int.from_bytes(q[2:], "little"), []).append((v, q[0], q[1]))
                p += 6
    codes = set()
    for h in HANDLERS:
        for v, g, mk in H[h]:
            p = l32(r, (0xF8B446, 0xF8B4B2)[v - 1] + 4 * g)
            while seg(r, p, 1)[0] != 0xFF:
                rec = seg(r, p, 4)
                if rec[3] == mk:
                    codes.add((rec[0], rec[1]))
                p += 4
    assert {c for _, c in codes} <= set(range(0x11)) and {k for k, _ in codes} == {0xA9}
    print("S4 ok: codes routed there: A9/%s" % " ".join("%02X" % c for c in sorted({c for _, c in codes})))


def apply():
    m = srcmap.load()
    L = m.lines
    u8 = lambda s: s.encode("utf-8").decode("latin-1")  # noqa: E731
    old = [";; Unknown:  what (0x2252)/(0x2256) hold.  The bit space is NOT the button"[1:],
           ";          index space of the table above; it is offset by 17."]
    i = L.index(old[0])
    assert L[i + 1] == old[1]
    L[i:i + 2] = [u8(x) for x in [
        "; What (0x2252)/(0x2256) hold -- established 2026-09-25 (lane proma),",
        ";          notes/proma-2026-09-25/gen_held_sets.py S1-S4: two 32-bit sets of",
        ";          HELD panel event codes, bit c for code c.  Their only writers are",
        ";          the action handlers sub_F8AE68 / sub_F8AF4E ((0x2252)) and",
        ";          sub_F8AEDB / sub_F8AF81 ((0x2256)): mask = IndexToBitMask32(code",
        ";          + 1), `or` on press, `and ~` on release, and the event value",
        ";          becomes 0x0303 when the code is in both sets.  The pool routes",
        ";          different switches of one code to the two sets; the codes are A9",
        ";          0x00-0x10 (the soft keys, LCD rows, -1/+1, EXIT, PAGE of",
        ";          Dispatch_FF3D39's legend).",
        "; The 17: sub_F8AE68/sub_F8AEDB rewrite a press whose bit is ALREADY set",
        ";          to code + 0x11 and record it at bit + 17 (`add (XIX-1),0x11 /",
        ";          sla 16 / sla 1`).  So bits 17..24 are codes 0..7 pressed again",
        ";          while held -- exactly the bits this table tests for buttons",
        ";          0..7, which is the offset the old line noted.",
        "; ★ CORRECTED: this paragraph recorded both as open.",
    ]]
    open(srcmap.SRC, "wb").write("\n".join(L).encode("latin-1"))
    print("applied")


if __name__ == "__main__":
    checks(open(srcmap.ROM, "rb").read())
    if "--apply" in sys.argv:
        apply()
