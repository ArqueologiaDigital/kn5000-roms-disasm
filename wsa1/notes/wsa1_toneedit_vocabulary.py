#!/usr/bin/env python3
"""
QUESTION THIS ANSWERS
=====================
"What does the WSA1R's TONE EDITOR call its parameters, and where do those
names live?"  -- i.e. the user-facing vocabulary of the SOUND EDIT screens,
enumerated from the ROM rather than from expectation, plus the two nulls that
say how much of the enumeration is structure and how much is chance.

RUN
===
    cd <tree>/wsa1
    python3 notes/wsa1_toneedit_vocabulary.py            # the screens
    python3 notes/wsa1_toneedit_vocabulary.py --nulls    # the two nulls
    python3 notes/wsa1_toneedit_vocabulary.py --selftest # assertions, 0 = OK

WHAT IT READS
=============
original_ROMs/wsa1_prom_{a.ic12,b.ic13,c.ic28} and wsa1_prom_d.bin only.  No
.s file is consulted, so nothing here can be an artefact of a label someone
typed.

METHOD, AND WHY IT IS NOT "STRINGS NEAR A ROUTINE"
=================================================
The WSA1R has no string table.  Every caption is a byte-run INSIDE a
display-list record, and a display list is executed start-to-end by the
interpreter at 0xF31A09 (notes/FINDINGS-ui-display-list.md).  So a caption
found inside a walked record is not "near" the screen that shows it -- it IS
the screen, because the interpreter draws every record of the list it is
handed.  This script re-uses the call-site discovery and record walker of
scripts/analysis/prom_b_display_lists.py so that the framing check documented
there (the length bytes must land exactly on the call site's end address)
still governs every record it prints.
"""
import importlib.util
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
B_BASE = 0xF00000


def load_dl_module():
    p = os.path.join(ROOT, "scripts", "analysis", "prom_b_display_lists.py")
    spec = importlib.util.spec_from_file_location("dlmod", p)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def rom(name):
    with open(os.path.join(ROOT, "original_ROMs", name), "rb") as f:
        return f.read()


def text_of(raw, txt_off, ln):
    """The printable-ASCII part of one text record's payload."""
    out = []
    for c in raw[txt_off:ln]:
        out.append(chr(c) if 0x20 <= c <= 0x7E else "\x00")
    return "".join(out)


def screens():
    """[(list_start, list_end, [captions in draw order], [high-code counts])]"""
    m = load_dl_module()
    a, b = m.load()
    sites = m.call_sites(a, b)
    htab = [int.from_bytes(b[m.HTBL + i * 4:m.HTBL + i * 4 + 4], "little")
            for i in range(36)]
    out = []
    for s, e, _t in sorted(sites):
        if not (B_BASE <= s < e <= B_BASE + len(b)):
            continue
        recs = m.walk(b, s, e)
        if recs is None:
            continue
        caps, hi, tot = [], 0, 0
        for p, op, ln in recs:
            raw = b[p - B_BASE:p - B_BASE + ln]
            h = htab[op]
            fields, txt = m.HANDLERS.get(h, ([], None))
            if txt is None or ln <= txt:
                continue
            for c in raw[txt:ln]:
                tot += 1
                if c >= 0x7F:
                    hi += 1
            t = text_of(raw, txt, ln).replace("\x00", " ").strip()
            if t:
                caps.append((p, t))
        out.append((s, e, caps, hi, tot))
    return out


SOUND_EDIT_KEYS = ("SOUND EDIT", "M0DELING", "MODELING", "RESONATOR",
                   "DRIVER", "ENVELOPE", "FILTER:", "TONE TEMPLATE",
                   "P0SITI0N", "PAGE1/3", "PAGE2/3", "PAGE3/3")


def is_sound_edit(caps):
    joined = " ".join(t for _, t in caps)
    return any(k in joined for k in SOUND_EDIT_KEYS)


def cmd_screens():
    sc = screens()
    n = 0
    for s, e, caps, hi, tot in sc:
        if not caps or not is_sound_edit(caps):
            continue
        n += 1
        print("=== display list 0x%06X-0x%06X   %d text records" % (s, e, len(caps)))
        for p, t in caps:
            print("    0x%06X  %r" % (p, t))
    print()
    print("sound-edit display lists: %d of %d walked lists" % (n, len(sc)))


def cmd_nulls():
    m = load_dl_module()
    a, b = m.load()
    sites = m.call_sites(a, b)
    htab = [int.from_bytes(b[m.HTBL + i * 4:m.HTBL + i * 4 + 4], "little")
            for i in range(36)]

    # ---- NULL 1 -------------------------------------------------------
    # Claim under test: "an ASCII run in prom_b that reads like an
    # upper-case UI label IS a UI label".  Null: how many such runs exist
    # OUTSIDE any walked display-list text payload?
    inside = bytearray(len(b))
    for s, e, _t in sites:
        if not (B_BASE <= s < e <= B_BASE + len(b)):
            continue
        recs = m.walk(b, s, e)
        if recs is None:
            continue
        for p, op, ln in recs:
            h = htab[op]
            _f, txt = m.HANDLERS.get(h, ([], None))
            if txt is None:
                continue
            for i in range(p - B_BASE + txt, p - B_BASE + ln):
                inside[i] = 1

    def runs(pred, minlen):
        out, cur, st = [], 0, 0
        for i, c in enumerate(b):
            if pred(c):
                if cur == 0:
                    st = i
                cur += 1
            else:
                if cur >= minlen:
                    out.append((st, cur))
                cur = 0
        if cur >= minlen:
            out.append((st, cur))
        return out

    up = runs(lambda c: 0x41 <= c <= 0x5A or c == 0x20, 4)
    tot = len(up)
    ins = sum(1 for st, n in up if inside[st])
    print("NULL 1 -- 'an upper-case ASCII run of >=4 chars is a UI label'")
    print("  runs of >=4 bytes drawn only from [A-Z ] in prom_b : %d" % tot)
    print("  of those, starting inside a walked display-list text payload: %d (%.1f%%)"
          % (ins, 100.0 * ins / tot))
    print("  outside                                            : %d (%.1f%%)"
          % (tot - ins, 100.0 * (tot - ins) / tot))
    print("  -> the predicate alone is %s; membership of a walked record is the"
          % ("NOT sufficient" if (tot - ins) > 0.05 * tot else "nearly sufficient"))
    print("     discriminator, and it is what this script reports.")
    print()

    # ---- NULL 2 -------------------------------------------------------
    # Claim under test: "the tone editor's captions are ASCII, i.e. this
    # screen set is English".  Null/positive control: the image HAS kana
    # fonts, so if any screen were Japanese its text payload would carry
    # codes >= 0x7F.  Count them over ALL walked text payloads.
    hi = tot2 = 0
    hi_lists = 0
    for s, e, _t in sorted(sites):
        if not (B_BASE <= s < e <= B_BASE + len(b)):
            continue
        recs = m.walk(b, s, e)
        if recs is None:
            continue
        lhi = 0
        for p, op, ln in recs:
            raw = b[p - B_BASE:p - B_BASE + ln]
            h = htab[op]
            _f, txt = m.HANDLERS.get(h, ([], None))
            if txt is None or ln <= txt:
                continue
            for c in raw[txt:ln]:
                tot2 += 1
                if c >= 0x7F:
                    hi += 1
                    lhi += 1
        if lhi:
            hi_lists += 1
    print("NULL 2 -- 'the tone-editor captions are ASCII, not the private/kana encoding'")
    print("  bytes in walked display-list text payloads: %d" % tot2)
    print("  of those >= 0x7F (i.e. outside ASCII)     : %d (%.2f%%)"
          % (hi, 100.0 * hi / tot2))
    print("  walked lists containing at least one      : %d" % hi_lists)
    print("  -> prom_b carries three kana faces and two kanji faces")
    print("     (notes/FINDINGS-fonts.md), so a Japanese screen set WOULD show")
    print("     up here.  This is a positive control, not an absence of test.")


def cmd_selftest():
    fails = []
    sc = screens()
    # 1. the four anchors this note's argument rests on are inside walked
    #    display-list text records, not merely somewhere in the image.
    want = {"MODELING": 0, "RESONATOR": 0, "DRIVER WAVEFORM": 0,
            "TONE TEMPLATE": 0, "ENVELOPE": 0}
    for _s, _e, caps, _hi, _t in sc:
        for _p, t in caps:
            for k in want:
                if k in t:
                    want[k] += 1
    for k, v in want.items():
        if v == 0:
            fails.append("caption %r not found in any walked display list" % k)
    # 2. the 64-entry resonator name table is exactly 64 x 8 ASCII bytes
    b = rom("wsa1_prom_b.ic13")
    tab = b[0x3241:0x3241 + 64 * 8]
    if len(tab) != 512 or any(not (0x20 <= c <= 0x7E) for c in tab):
        fails.append("resonator name table 0xF03241 is not 64 x 8 printable ASCII")
    if tab[0:8] != b"ORIGINAL":
        fails.append("resonator name table entry 0 is not 'ORIGINAL'")
    if tab[63 * 8:64 * 8] != b"SPECIAL2":
        fails.append("resonator name table entry 63 is not 'SPECIAL2'")
    # 3. the element-parameter write arm's shape, read from prom_c bytes.
    #    0xFBC3A3 `ld C,0x51` (81 = the element-block stride) and
    #    0xFBC5C8 `cp BC,0x0050` (80 = the last parameter number).
    c = rom("wsa1_prom_c.ic28")
    def at(addr):
        return addr - 0xF80000
    if c[at(0xFBC3A3):at(0xFBC3A3) + 2] != bytes([0x23, 0x51]):
        fails.append("0xFBC3A3 is not `ld C,0x51`")
    if c[at(0xFBC5C8):at(0xFBC5C8) + 4] != bytes([0xD9, 0xCF, 0x50, 0x00]):
        fails.append("0xFBC5C8 is not `cp BC,0x0050`")
    # the 81-entry computed-goto table at 0xFBC5DC: every entry must be a
    # plausible code address inside this routine's own body.
    ents = [int.from_bytes(c[at(0xFBC5DC) + 4 * i:at(0xFBC5DC) + 4 * i + 4], "little")
            for i in range(81)]
    if not all(0xFBC3EC <= v <= 0xFBC5B2 for v in ents):
        fails.append("the 81 computed-goto entries are not all inside 0xFBC3EC-0xFBC5B2")
    nxt = int.from_bytes(c[at(0xFBC5DC) + 4 * 81:at(0xFBC5DC) + 4 * 81 + 4], "little")
    if 0xFBC3EC <= nxt <= 0xFBC5B2:
        fails.append("the word after entry 80 is also a plausible entry: the table "
                     "may be longer than 81")
    print("wsa1_toneedit_vocabulary.py --selftest")
    print("  walked display lists: %d" % len(sc))
    print("  anchor captions found: %s" % want)
    print("  FAILURES: %d" % len(fails))
    for f in fails:
        print("    " + f)
    return 1 if fails else 0


if __name__ == "__main__":
    if "--nulls" in sys.argv:
        cmd_nulls()
    elif "--selftest" in sys.argv:
        sys.exit(cmd_selftest())
    else:
        cmd_screens()
