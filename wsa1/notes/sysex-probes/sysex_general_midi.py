#!/usr/bin/env python3
"""GENERAL MIDI mode and System Exclusive: what turning GM on actually changes.

QUESTION THIS ANSWERS
    `F0 7E 7F 09 01 F7` and `F0 7E 7F 09 02 F7` are the only two Universal
    messages the SX-WSA1R honours, and the published reference says no more
    than "turning General MIDI on restricts the sounds and operations
    available".  A librarian needs the rest:

      * does GM mode change which System Exclusive messages are accepted,
        or make any of them behave differently?
      * are bulk dump or the 2B/2C parameter families affected?
      * does the instrument TRANSMIT anything when GM goes on or off?
      * does a bulk dump taken in GM mode differ from one taken out of it,
        and if so WHERE in the dump?
      * what does GM System On change internally?

WHAT IT ESTABLISHES (all of it recomputed from the instruction bytes)

  1. The two messages reach commands 0x20 and 0x21 of the trie, and both
     OUTER dispatch tables -- 0xF4F800 (interrupt-side ring) and 0xF4F888
     (foreground ring) -- carry a real handler for them, 0xFB51E7 and
     0xFB520C.  The IN-SESSION table 0xF4F916 carries a bare `ret` for
     both, and the in-session collector refuses any identifier but 0x50
     anyway (status 0x02 -> ERROR 41!).  So GM On/Off works from either
     MIDI parser, and never during a bulk-dump session.

  2. GM mode is ONE BIT: bit 2 (0x04) of RAM 0x7F4D.  The receive handlers
     do exactly three things -- set the echo lock, set/clear that bit, and
     post one internal parameter-change event {0x91, 0x03, value, 0x04}.
     GM Off returns without doing any of it when the bit is already clear;
     GM On has no such guard and is acted on every time it arrives.

  3. THE INSTRUMENT TRANSMITS.  `sub_FB5F2E` builds the 4-byte record
     {0xB0, 0x11|0x10, 0x00, 0x7F} and hands it to `sub_FB4CAE`, which puts
     the 6-byte literal at 0xF4FEE6 (GM System On) or 0xF4FEEC (GM System
     Off) on the wire.  It is called from `sub_FB590A`, the sole handler of
     internal event class 0x91 -- i.e. from every GM state change, whatever
     caused it.  It is NOT gated by the EXCLUSIVE transmit filter
     ((0x7F38) bit 3), which gates only the OTHER parameter-change
     transmitter, `sub_FB4B7D`.

  4. ...except that a change that came FROM the wire is not echoed: the two
     receive handlers set bit 7 of (0x60F020) and `sub_FB5F2E` returns at
     once when that bit is set.  Bit 7 of that cell is SET at exactly two
     sites, READ at exactly one, and CLEARED NOWHERE in either CPU-1 image.
     RESET zeroes it (the 0x604000..0x610000 clear covers it), so the lock
     arms on the first GM message received and holds until power-off.

  5. No System Exclusive message is accepted, refused or answered
     differently because GM is on.  Inside the whole SysEx engine span
     (0xFB2000-0xFB8200) the GM bit is touched at exactly three addresses:
     the two receive handlers and one display/state refresh (0xFB2026).
     And NO data table in either CPU-1 image names the address 0x7F4D --
     every occurrence of the byte pair `4D 7F` is an instruction operand --
     so no 2B/2C parameter descriptor can reach the GM bit either.

  6. BUT THE DUMP DIFFERS.  SYSTEM,PART & MIDI part 2 is a verbatim copy of
     CPU-1 RAM 0x7620..0x7F80, and 0x7F4D is inside it.  That block is a
     list of {id, length, payload} records: walking the factory default
     image at prom_b 0xF3F400 yields 77 records ending EXACTLY on 0x7F7E,
     which is the same constant `SysExXfer_SetPart_SystemPart2` uses to size the transfer.
     The GM bit is payload byte 3 of the record whose id is 0x91 -- the
     same 0x91/0x03 pair the internal event carries -- at block offset
     2349 (0x92D) of 2400.  Factory default: 0x00, GM off.

RUN
    python3 wsa1/notes/sysex-probes/sysex_general_midi.py
    python3 wsa1/notes/sysex-probes/sysex_general_midi.py --records

    --records additionally prints all 77 records of the SYSTEM,PART & MIDI
    part-2 default image with their block offsets.

PASS
    Every assert is silent and the script prints OK.  Headline numbers:
    commands 0x20/0x21; flag bit 0x04 of 0x7F4D; echo lock (0x60F020) bit 7
    set 2x / read 1x / cleared 0x; transmit literals 0xF4FEE6 and 0xF4FEEC;
    77 TLV records ending on 0x7F7E; GM at block offset 2349, record id
    0x91, payload byte 3; 0 data-table references to 0x7F4D.
"""
import collections
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROMS = os.path.abspath(os.path.join(HERE, "..", "..", "original_ROMs"))

IMAGES = {
    "prom_a": ("wsa1_prom_a.ic12", 0xF80000),
    "prom_b": ("wsa1_prom_b.ic13", 0xF00000),
    "prom_c": ("wsa1_prom_c.ic28", 0xF80000),
}

# ---- the addresses this probe reads, each named by one instruction -------
ROOT            = 0xF5115B   # trie root, `add XBC,0x00f5115b` at 0xFB63FC
TBL_IRQ         = 0xF4F800   # `add XWA,0x00f4f800` at 0xFB21AF
TBL_FG          = 0xF4F888   # `add XWA,0x00f4f888` at 0xFB22AC
TBL_SESSION     = 0xF4F916   # `add XWA,0x00f4f916` at 0xFB28A1
GM_ON_HANDLER   = 0xFB51E7
GM_OFF_HANDLER  = 0xFB520C
GM_FLAG         = 0x7F4D     # bit 2
ECHO_LOCK       = 0x60F020   # bit 7
MSG_GM_ON       = 0xF4FEE6
MSG_GM_OFF      = 0xF4FEEC
TX_CLASS_TABLE  = 0xF4FB38   # `add XWA,0x00f4fb38` at 0xFB4BC5, 192 entries
TX_BUILDER      = 0xFB5F2E
TX_EMITTER      = 0xFB4CAE
CLASS91_LIST    = 0xF87B02   # UiEventClass_ListTable_A[0x91]
SYSPART2_DEFAULT = 0xF3F400  # `lda XBC,0x00f3f400` at 0xFAAB31
SYSPART2_START  = 0x7620     # `lda XIX,(0x7620)` at 0xFAAAD4 and 0xFAAB2D
SYSPART2_LAST   = 0x7F7E     # `lda XBC,(0x7f7e)` at 0xFAAADA
STATUS_MAP      = 0xF511C7   # `add XWA,0x00f511c7` at 0xFB7E54
ENGINE_LO, ENGINE_HI = 0xFB2000, 0xFB8200


def load():
    out = {}
    for name, (fn, base) in IMAGES.items():
        out[name] = (open(os.path.join(ROMS, fn), "rb").read(), base)
    return out


def rd(img, addr, n):
    d, base = img
    return d[addr - base:addr - base + n]


def find_all(img, pat, limit=None):
    d, base = img
    out, i = [], d.find(pat)
    while i >= 0:
        out.append(base + i)
        if limit and len(out) >= limit:
            break
        i = d.find(pat, i + 1)
    return out


def trie_node(b, addr):
    """Yield (match, cmd, next) until the 0xFF terminator record."""
    out = []
    while True:
        rec = rd(b, addr, 6)
        out.append((rec[0], rec[1], struct.unpack("<I", rec[2:6])[0]))
        if rec[0] == 0xFF:
            return out
        addr += 6


def main():
    show_records = "--records" in sys.argv
    imgs = load()
    a, b, c = imgs["prom_a"], imgs["prom_b"], imgs["prom_c"]

    # --- 0. load bases, asserted by content -------------------------------
    assert rd(b, 0xF4FEB4, 5) == b"\xF0\x50\x23\x7E\xF7", "prom_b base"
    assert rd(a, 0xF99AE3, 5) == b"\x00\x03\x05\x04\x02", "prom_a base"
    print("base check OK: prom_a @0xF80000, prom_b @0xF00000")

    # --- 1. the two messages, walked out of the trie ----------------------
    # The parse pointer skips TWO bytes -- the 0xF0 and the identifier --
    # before the root is consulted:  sub XWA,XWA / inc 2,XWA / add (XBC+2),XWA
    assert rd(a, 0xFB63DD, 7) == bytes.fromhex("e8a0e862a90288"), "parse skip"

    root = trie_node(b, ROOT)
    dev = [r for r in root if r[0] == 0x7F]
    assert len(dev) == 1 and dev[0][1] == 0x00, "root 0x7F record"
    sub = [r for r in trie_node(b, dev[0][2]) if r[0] == 0x09]
    assert len(sub) == 1 and sub[0][1] == 0x00, "0x7F -> 0x09"
    leaf = {r[0]: r[1] for r in trie_node(b, sub[0][2])}
    assert leaf.get(0x01) == 0x20, leaf
    assert leaf.get(0x02) == 0x21, leaf

    print()
    print("Universal messages, as the trie accepts them")
    print("  F0 7E 7F 09 01 F7   General MIDI System On    -> command 0x20")
    print("  F0 7E 7F 09 02 F7   General MIDI System Off   -> command 0x21")
    print("  (the root is applied to message byte 2; the identifier is checked")
    print("   only while the message is collected, and never re-examined)")

    # --- 2. where each command is dispatched ------------------------------
    def entry(tbl, i):
        return struct.unpack("<I", rd(b, tbl + 4 * i, 4))[0]

    for tbl, name in ((TBL_IRQ, "0xF4F800 interrupt-side"),
                      (TBL_FG, "0xF4F888 foreground")):
        assert entry(tbl, 0x20) == GM_ON_HANDLER, (name, hex(entry(tbl, 0x20)))
        assert entry(tbl, 0x21) == GM_OFF_HANDLER, name
    sess_on, sess_off = entry(TBL_SESSION, 0x20), entry(TBL_SESSION, 0x21)
    assert sess_on == sess_off, "session slots differ"
    assert rd(a, sess_on, 1) == b"\x0e", "session slot is not a bare ret"

    print()
    print("dispatch of commands 0x20 / 0x21")
    print("  0xF4F800 interrupt-side   0x%06X / 0x%06X   real handlers"
          % (entry(TBL_IRQ, 0x20), entry(TBL_IRQ, 0x21)))
    print("  0xF4F888 foreground       0x%06X / 0x%06X   real handlers"
          % (entry(TBL_FG, 0x20), entry(TBL_FG, 0x21)))
    print("  0xF4F916 in-session       0x%06X / 0x%06X   `ret`, a no-op"
          % (sess_on, sess_off))

    # --- 3. what the two handlers do, byte for byte -----------------------
    on = rd(a, GM_ON_HANDLER, 37)
    off = rd(a, GM_OFF_HANDLER, 53)
    #   GM ON:  pushw hl / set 7,(0x60F020) / or (0x7F4D),0x04 / ld H,(0x7F4D)
    assert on[:6] == bytes.fromhex("2b") + bytes.fromhex("f220f060bf"), on[:6].hex()
    assert on[6:11] == bytes.fromhex("c14d7f3e04"), on[6:11].hex()
    #   ...and the posted event, {0x91, 0x03, value, 0x04}
    post = bytes.fromhex("0b0400") + bytes.fromhex("ce8bd91229") + \
        bytes.fromhex("0b0300") + bytes.fromhex("0b9100") + bytes.fromhex("1d181bf4")
    assert on[15:15 + len(post)] == post, on[15:].hex()
    #   GM OFF: the guard -- lda XIX,(0x7F4A) / ld C,(XIX+3) / and C,4 / jr Z,+0x22
    assert off[:16] == bytes.fromhex("2b3cf14a7f34ec128c0323cbcc046622"), off[:16].hex()
    assert off[16:21] == bytes.fromhex("f220f060bf"), off[16:21].hex()
    assert off[21:27] == bytes.fromhex("ec128c033cfb"), off[21:27].hex()
    assert off.count(post) == 1 and off.index(post) == 30, off.hex()
    #   0x7F4A + 3 == 0x7F4D: the off handler reaches the same bit indirectly
    assert 0x7F4A + 3 == GM_FLAG
    #   GM ON has NO guard: nothing between the pushw and the set/or
    assert on[1] != 0x66 and on[6] != 0x66

    print()
    print("what a received General MIDI message does")
    print("  0x%06X  GM System On   set 7,(0x%06X) ; or (0x%04X),0x04 ;"
          % (GM_ON_HANDLER, ECHO_LOCK, GM_FLAG))
    print("                          post {0x91, 0x03, 0x04, 0x04}")
    print("  0x%06X  GM System Off  RETURNS AT ONCE if bit 2 of (0x%04X) is"
          % (GM_OFF_HANDLER, GM_FLAG))
    print("                          already clear; otherwise the same three")
    print("                          steps with 0x00")
    print("  GM System On has no such guard -- it is acted on every time.")

    # --- 4. the echo lock -------------------------------------------------
    set7 = find_all(a, bytes.fromhex("f220f060bf"))
    res7 = find_all(a, bytes.fromhex("f220f060b7"))
    assert set7 == [GM_ON_HANDLER + 1, GM_OFF_HANDLER + 16], [hex(x) for x in set7]
    assert res7 == [], [hex(x) for x in res7]
    #   every byte read of the cell, and which mask it applies
    reads = [(s, rd(a, s + 5, 3)) for s in find_all(a, bytes.fromhex("c220f06023"))]
    read = [s for s, m in reads if m == bytes.fromhex("cbcc80")]
    assert read == [TX_BUILDER + 8], [hex(x) for x in read]
    #   no `bit 7,(cell)` form exists either
    assert find_all(a, bytes.fromhex("f220f060cf")) == []
    #   no byte-wide AND of that cell can clear bit 7
    for site in find_all(a, bytes.fromhex("c220f0603c")):
        assert rd(a, site + 5, 1)[0] & 0x80, "an AND clears bit 7 at %#x" % site
    #   ...and neither of the other two images touches the cell at all
    for img, nm in ((b, "prom_b"), (c, "prom_c")):
        assert find_all(img, bytes.fromhex("c220f060")) == [], nm
        assert find_all(img, bytes.fromhex("f220f060")) == [], nm
    #   RESET zeroes it: ld XBC,0x3000 / ld XIX,0x00604000, 0x3000 longs
    clr = find_all(a, bytes.fromhex("410030000044004060 00".replace(" ", "")))
    assert len(clr) == 1, [hex(x) for x in clr]
    assert 0x604000 <= ECHO_LOCK < 0x604000 + 0x3000 * 4

    print()
    print("the echo lock, bit 7 of (0x%06X)" % ECHO_LOCK)
    print("  set at   %s" % ", ".join("0x%06X" % x for x in set7))
    print("  read at  %s (the only read that masks with 0x80; the cell's"
          % ", ".join("0x%06X" % x for x in read))
    print("           other bits are read elsewhere)")
    print("  cleared  nowhere in prom_a, and not touched in prom_b or prom_c")
    print("  zeroed at RESET by the 0x604000..0x610000 clear (0x%06X)" % clr[0])

    # --- 5. the transmit side ---------------------------------------------
    assert rd(b, MSG_GM_ON, 6) == b"\xF0\x7E\x7F\x09\x01\xF7"
    assert rd(b, MSG_GM_OFF, 6) == b"\xF0\x7E\x7F\x09\x02\xF7"
    tx = rd(a, TX_BUILDER, 47)
    #   bit 7 test, then the record {0xB0, 0x11|0x10, 0x00, 0x7F}
    assert tx[8:18] == bytes.fromhex("c220f06023cbcc806e21"), tx[8:18].hex()
    assert tx[18:21] == bytes.fromhex("b400b0"), tx[18:21].hex()       # +0 = 0xB0
    assert tx[21:25] == bytes.fromhex("bc020000"), tx[21:25].hex()     # +2 = 0x00
    assert tx[25:29] == bytes.fromhex("bc03007f"), tx[25:29].hex()     # +3 = 0x7F
    assert tx[29:33] == bytes.fromhex("bc010011"), tx[29:33].hex()     # +1 = 0x11
    assert tx[33:41] == bytes.fromhex("8e0823cbcc046e04"), tx[33:41].hex()
    assert tx[41:45] == bytes.fromhex("bc010010"), tx[41:45].hex()     # +1 = 0x10
    assert rd(a, TX_BUILDER + 46, 4) == bytes.fromhex("1dae4cfb"), "call sub_FB4CAE"
    #   class 0xB0 of the parameter-change transmit table is the same emitter
    assert struct.unpack("<I", rd(b, TX_CLASS_TABLE + 4 * 0xB0, 4))[0] == TX_EMITTER
    #   the emitter picks the literal by the record's byte +1
    em = rd(a, TX_EMITTER, 46)
    assert em[12:20] == bytes.fromhex("890126cecf116e0b"), em[12:20].hex()
    assert struct.unpack("<I", em[24:27] + b"\0")[0] == MSG_GM_ON, em[24:27].hex()
    assert em[31:36] == bytes.fromhex("cecf106e21"), em[31:36].hex()
    assert struct.unpack("<I", em[40:43] + b"\0")[0] == MSG_GM_OFF, em[40:43].hex()
    #   who calls the builder: the sole handler of internal event class 0x91
    assert struct.unpack("<I", rd(a, CLASS91_LIST, 4))[0] == 0xF408F0
    assert struct.unpack("<I", rd(a, CLASS91_LIST + 4, 4))[0] == 0xFFFFFFFF
    assert rd(b, 0xF408F0, 4) == bytes.fromhex("1b0a59fb"), "T_F408F0 -> 0xFB590A"
    h = rd(a, 0xFB590A, 30)
    assert h[1:5] == bytes.fromhex("f1b92034"), h[1:5].hex()       # XIX = 0x20B9
    assert h[5:10] == bytes.fromhex("c1b820 3f03".replace(" ", "")), h[5:10].hex()
    assert h[12:19] == bytes.fromhex("c1ba2023cbcc04"), h[12:19].hex()
    #   ...and its re-entrancy guard, bit 0 of (0x60F01F)
    assert h[21:29] == bytes.fromhex("c21ff06023cbcc01"), h[21:29].hex()
    assert rd(a, 0xFB5929, 5) == bytes.fromhex("f21ff060b8"), "guard is not set"
    assert rd(a, 0xFB5958, 5) == bytes.fromhex("f21ff060b0"), "guard is not cleared"
    #   the EXCLUSIVE transmit filter gates the OTHER transmitter, not this one
    g = rd(a, 0xFB4B7D, 11)
    assert g[2:9] == bytes.fromhex("c1387f23cbcc08"), g[2:9].hex()
    assert find_all(a, bytes.fromhex("387f"))  # sanity: the address exists
    for site in find_all(a, bytes.fromhex("c1387f")) + find_all(a, bytes.fromhex("f1387f")):
        assert not (TX_BUILDER <= site < TX_BUILDER + 47), site
        assert not (TX_EMITTER <= site < TX_EMITTER + 0x50), site

    print()
    print("what the instrument TRANSMITS when GM changes")
    print("  0x%06X  builds {0xB0, 0x11, 0x00, 0x7F} on GM ON," % TX_BUILDER)
    print("              {0xB0, 0x10, 0x00, 0x7F} on GM OFF,")
    print("              and returns without building anything when the echo")
    print("              lock is set")
    print("  0x%06X  puts the 6-byte literal on the wire:" % TX_EMITTER)
    print("              0x%06X  %s" % (MSG_GM_ON, rd(b, MSG_GM_ON, 6).hex(" ").upper()))
    print("              0x%06X  %s" % (MSG_GM_OFF, rd(b, MSG_GM_OFF, 6).hex(" ").upper()))
    print("  reached from 0x%06X, the ONLY handler of internal event class 0x91"
          % 0xFB590A)
    print("  NOT gated by the EXCLUSIVE transmit filter ((0x7F38) bit 3), which")
    print("  gates only the other parameter-change transmitter at 0xFB4B7D")

    # --- 5b. every producer of internal event class 0x91 -------------------
    #   two idioms: registers (ld E,0x91 / ld D,0x03) and stack
    #   (pushw 0x03 / pushw 0x91).  Both end in the same 4-byte record.
    prod = {}
    for img, nm in ((a, "prom_a"), (b, "prom_b")):
        prod[nm] = sorted(find_all(img, bytes.fromhex("25912403")) +
                          find_all(img, bytes.fromhex("0b03000b9100")))
    total = len(prod["prom_a"]) + len(prod["prom_b"])
    assert total == 20, total
    #   the two receive handlers are among them...
    assert GM_ON_HANDLER + 23 in prod["prom_a"], [hex(x) for x in prod["prom_a"]]
    assert GM_OFF_HANDLER + 38 in prod["prom_a"]
    #   ...and so is the panel's own GM soft key, which does NOT set the lock
    assert 0xF99EB3 in prod["prom_a"]
    assert find_all(a, bytes.fromhex("f220f060bf"),
                    limit=None) == [GM_ON_HANDLER + 1, GM_OFF_HANDLER + 16]

    print()
    print("every producer of internal event class 0x91 (%d)" % total)
    for nm in ("prom_a", "prom_b"):
        print("  %s  %s" % (nm, ", ".join("0x%06X" % x for x in prod[nm])))
    print("  all 20 carry the SAME record id 0x91 and byte index 0x03, which is")
    print("  the General MIDI byte; only the two receive handlers arm the echo")
    print("  lock, so a change made anywhere else -- the panel soft key, the")
    print("  boot restore, a song or Standard MIDI File load -- is not")
    print("  suppressed. 0x%06X still drops it if it is already inside one"
          % 0xFB590A)
    print("  (bit 0 of (0x60F01F)).")

    # --- 6. the dump -------------------------------------------------------
    #   SysExXfer_SetPart_SystemPart2 sizes SYSTEM,PART & MIDI part 2 from 0x7620 and 0x7F7E
    desc = rd(a, 0xFB75E4, 0x45)
    assert bytes.fromhex("330076") in desc and bytes.fromhex("322076") in desc
    assert bytes.fromhex("317e7f") in desc, "0x7F7E not in SysExXfer_SetPart_SystemPart2"
    size = (SYSPART2_LAST - SYSPART2_START) + 2
    assert size == 2400, size
    #   the same two constants bound the record walk at 0xFAAAD4/0xFAAADA
    assert rd(a, 0xFAAAD4, 4) == bytes.fromhex("f1207634")
    assert rd(a, 0xFAAADA, 4) == bytes.fromhex("f17e7f31")
    assert rd(a, 0xFAAB01, 11) == bytes.fromhex("8c0123d912e912e962e984")
    #   walk the factory default image as {id, length, payload}
    recs, ram, p = [], SYSPART2_START, SYSPART2_DEFAULT
    while ram < SYSPART2_LAST:
        rid = rd(b, p, 1)[0]
        if rid == 0xFF:
            ram += 2
            p += 2
            continue
        ln = rd(b, p + 1, 1)[0]
        recs.append((ram, rid, ln, rd(b, p + 2, ln)))
        ram += 2 + ln
        p += 2 + ln
    assert ram == SYSPART2_LAST, "the walk ended at %#x, not %#x" % (ram, SYSPART2_LAST)
    assert len(recs) == 77, len(recs)
    assert recs[0][1] == 0x78 and recs[0][2] == 0x10, recs[0][:3]
    hit = [r for r in recs if r[0] <= GM_FLAG < r[0] + 2 + r[2]]
    assert len(hit) == 1
    gram, gid, glen, gpay = hit[0]
    gidx = GM_FLAG - gram - 2
    assert gid == 0x91 and gidx == 0x03, (hex(gid), gidx)
    assert gpay[gidx] == 0x00, "factory default is not GM off"
    blk_off = GM_FLAG - SYSPART2_START
    assert blk_off == 2349, blk_off

    print()
    print("where General MIDI sits in a bulk dump")
    print("  SYSTEM,PART & MIDI part 2 = CPU1 0x%04X..0x%04X, %d bytes,"
          % (SYSPART2_START, SYSPART2_START + size, size))
    print("    header 40 00 20 / 00 12 60")
    print("  the block is %d records of {id, length, payload}, ending exactly"
          % len(recs))
    print("    on 0x%04X -- the same constant the transfer is sized from"
          % SYSPART2_LAST)
    print("  General MIDI = bit 2 of payload byte %d of record id 0x%02X"
          % (gidx, gid))
    print("    block offset %d (0x%03X), factory default 0x%02X = OFF"
          % (blk_off, blk_off, gpay[gidx]))
    print("  the record id and the byte index are the SAME 0x91 / 0x03 the")
    print("    internal event carries")

    if show_records:
        print()
        print("  SYSTEM,PART & MIDI part 2 -- the factory default image")
        print("    blk off  RAM     id  len")
        for ram_, rid, ln, _ in recs:
            mark = "  <- General MIDI" if rid == gid and ram_ == gram else ""
            print("    %6d   0x%04X  %02X  %3d%s" % (ram_ - SYSPART2_START,
                                                     ram_, rid, ln, mark))

    # --- 7. during a bulk-dump session ------------------------------------
    #   the in-session collector demands 0x50 as the identifier
    coll = rd(a, 0xFB60EE, 10)
    assert coll[:5] == bytes.fromhex("cecf506e04"), coll.hex()
    assert rd(a, 0xFB60F7, 3) == bytes.fromhex("0b0200"), "status 0x02"
    smap = rd(b, STATUS_MAP, 34)
    assert smap[0x02] == 0x21, hex(smap[0x02])   # 0x21 = the ERROR 41! screen
    assert smap[0x00] == 0x23                    # 0x23 = COMPLETED!

    print()
    print("during a bulk-dump session")
    print("  the in-session collector accepts identifier 0x50 only (0xFB60EE);")
    print("  anything else raises status 0x02, which STATUS_MAP sends to the")
    print("  ERROR 41! screen -- so a GM message arriving mid-dump does not")
    print("  change GM mode, it kills the transfer")

    # --- 8. GM changes nothing about SysEx --------------------------------
    eng = []
    for pat in (bytes.fromhex("f14d7f"), bytes.fromhex("c14d7f")):
        eng += [s for s in find_all(a, pat) if ENGINE_LO <= s < ENGINE_HI]
    eng.sort()
    assert eng == [0xFB2026, 0xFB51ED, 0xFB51F2], [hex(x) for x in eng]
    #   and no DATA anywhere names the flag byte
    operand_prefixes = collections.Counter()
    for img, nm in ((a, "prom_a"), (b, "prom_b")):
        d, base = img
        i = d.find(b"\x4D\x7F")
        while i >= 0:
            operand_prefixes[d[i - 1]] += 1
            assert d[i - 1] in (0x0B, 0xC1, 0xF1), \
                "%s: 0x%06X is not an instruction operand" % (nm, base + i)
            i = d.find(b"\x4D\x7F", i + 1)
    assert find_all(c, b"\x4D\x7F") == []

    print()
    print("does GM mode change System Exclusive behaviour?  NO")
    print("  inside the engine span 0x%06X-0x%06X the GM bit is touched at"
          % (ENGINE_LO, ENGINE_HI))
    print("  exactly three addresses: 0xFB51ED and 0xFB51F2 (the receive")
    print("  handler itself) and 0xFB2026, a state refresh that sends no")
    print("  message.  Every message family, the checksum, the handshake,")
    print("  the error map and the 2B/2C parameter space are untouched.")
    print("  All %d occurrences of the address 0x7F4D in prom_a+prom_b are"
          % sum(operand_prefixes.values()))
    print("  instruction operands (prefixes %s) -- no descriptor table names"
          % ", ".join("0x%02X" % k for k in sorted(operand_prefixes)))
    print("  it, so no 2B/2C parameter message can reach the GM bit.")

    # --- 9. Standard MIDI Files -------------------------------------------
    smf_on = b"\x00\xF0\x05\x7E\x7F\x09\x01\xF7"
    smf_off = b"\x00\xF0\x05\x7E\x7F\x09\x02\xF7"
    pairs = [s for s in find_all(b, smf_on) if rd(b, s + 8, 8) == smf_off]
    assert len(pairs) == 3, [hex(x) for x in pairs]
    #   the writer chooses by the same bit
    assert rd(b, 0xF76F4A, 5) == bytes.fromhex("45646ef700"), rd(b, 0xF76F4A, 5).hex()
    assert rd(b, 0xF76F4F, 6) == bytes.fromhex("f14d7fca6e0a"), rd(b, 0xF76F4F, 6).hex()
    assert rd(b, 0xF76F55, 5) == bytes.fromhex("456c6ef700")

    print()
    print("Standard MIDI Files")
    print("  three copies of the pair {GM On, GM Off} as 8-byte delta-0 events:")
    print("    %s" % ", ".join("0x%06X" % x for x in pairs))
    print("  the writer picks On when bit 2 of (0x7F4D) is set, Off when clear")
    print("  (0xF76F4A-0xF76F5A), and it is the track's first event")

    print()
    print("OK")


if __name__ == "__main__":
    main()
