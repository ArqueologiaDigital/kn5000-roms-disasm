#!/usr/bin/env python3
r"""The SMF reader's SysEx handler (0xF71525-0xF71766) and its 118-entry target table `Data_F71767`.

QUESTION THIS ANSWERS
    `Data_F71767` (472 bytes) was "Unknown: everything about it except its
    bytes", and the five routines around it (`sub_F71525`, `sub_F71697`,
    `sub_F716CD`, `sub_F716E5`, `sub_F71730`) "what the routine is FOR".  Their
    own bytes say:

      sub_F71525 -- called from the SMF reader (0xF6F733, 0xF71CF1); reads the
        event bytes through InputStream_GetByte, counting (0x1198) down:
          * (0x1198) = 5: 7E 7F 09 01 or 7E 7F 09 02 -- the universal GM
            System On / Off messages -- set bit 0 of (0x124B), (0x1239) = 0xFF
            (On) or 0x00 (Off), and call sub_F71417;
          * (0x1198) = 16: 50 2C 04 00 11 00, then an address byte pair --
            (0x137B) = 0x00 with (0x137C) = 0x30/0x31, 0x01 with 0x04, or 0x11
            with (0x137C) <= 0x75 -- then 00 00 01, then two data NIBBLES into
            (0x137E) (high) and (0x137D) (low), then sub_F71697.
      sub_F71697 -- dispatches on (0x137B): 0x00 -> sub_F716CD + sub_F71730;
        0x01 -> sub_F716CD then (0x1380) = the value; else -> sub_F716CD +
        sub_F716E5.
      sub_F716CD -- (0x137F) = (0x137E & 0x0F) << 4 | (0x137D & 0x0F): joins
        the two nibbles into the value.
      sub_F716E5 -- XDE = Data_F71767 + 4 * (0x137C) (`ld XDE,0x00F71767` at
        0xF716EE), then the byte at the entry's address gets the value:
        address lo 1 writes the low nibble only, lo 2 the high nibble (from the
        value's low nibble), anything else the whole byte.
      sub_F71730 -- address 0x00:0x30 / 0x00:0x31 write the low / high nibble
        of the byte at 0x603EE4.
    So `Data_F71767` is the address map for SysEx address-hi 0x11: entry lo is
    the RAM byte that `50 2C 04 00 11 00 11 lo 00 00 01 nh nl` sets, and the
    `cp A,0x75 / jrl UGT` at 0xF71637 bounds lo at 0x75 -- exactly 118 entries,
    472 bytes, the object's size.  0xFFFFFFFF marks a lo with no target.
    ⚠ `cp XDE,0xffffffff` (0xF716F8) runs BEFORE `ld XDE,(XDE)` (0xF71700):
    it compares the entry's ADDRESS, which cannot be 0xFFFFFFFF, so as the
    instructions stand the marker is not skipped -- a write through it goes to
    0xFFFFFF.  Read from the bytes; not run on hardware.

RUN
    python3 notes/promb-2026-09-25/smf_sysex_param_change.py            # checks
    python3 notes/promb-2026-09-25/smf_sysex_param_change.py --apply    # write the source
    make gate-wsa1
"""
import os
import re
import sys
import textwrap

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, "wsa1", "prom_b", "wsa1_prom_b.s")
ROMB = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
BASE = 0xF00000
TAB, N = 0xF71767, 118
FAIL = []
RENAMES = [("sub_F71525", "SmfEvent_SysEx"), ("sub_F71697", "SmfSysEx_ApplyParamChange"),
           ("sub_F716CD", "SmfSysEx_JoinNibbles"), ("sub_F716E5", "SmfSysEx_WriteAddr11"),
           ("sub_F71730", "SmfSysEx_WriteAddr00"), ("Data_F71767", "SmfSysEx_Addr11_Targets")]
BYTES = [  # (address, hex, what)
    (0xF71544, "d198113f0500", "cp (0x1198),0x0005"),
    (0xF71558, "c9cf7e", "cp A,0x7e"), (0xF71565, "c9cf7f", "cp A,0x7f"),
    (0xF71572, "c9cf09", "cp A,0x09"), (0xF7157F, "c9d9", "cp A,1"), (0xF71594, "c9da", "cp A,2"),
    (0xF715AD, "d198113f1000", "cp (0x1198),0x0010"),
    (0xF715C1, "c9cf50", "cp A,0x50"), (0xF715CE, "c9cf2c", "cp A,0x2c"), (0xF715DB, "c9dc", "cp A,4"),
    (0xF715E7, "c9d8", "cp A,0"), (0xF715F3, "c9cf11", "cp A,0x11"), (0xF71600, "c9d8", "cp A,0"),
    (0xF7160C, "f17b1341", "ld (0x137b),A"), (0xF71625, "f17c1341", "ld (0x137c),A"),
    (0xF71637, "c9cf75", "cp A,0x75"), (0xF7163A, "7b69ff", "jrl UGT,.."),
    (0xF7163F, "c9cf30", "cp A,0x30"), (0xF71645, "c9cf31", "cp A,0x31"), (0xF7164D, "c9dc", "cp A,4"),
    (0xF71659, "c9d8", "cp A,0"), (0xF71665, "c9d8", "cp A,0"), (0xF71671, "c9d9", "cp A,1"),
    (0xF7167D, "f17e1341", "ld (0x137e),A"), (0xF71688, "f17d1341", "ld (0x137d),A"),
    (0xF716E7, "c17c1327", "ld L,(0x137c)"), (0xF716EB, "dbec02", "sla 2,HL"),
    (0xF716EE, "426717f700", "ld XDE,0x00f71767"), (0xF716F8, "eacfffffffff", "cp XDE,0xffffffff"),
    (0xF71700, "a222", "ld XDE,(XDE)"),
]


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


def derive():
    b = open(ROMB, "rb").read()
    at = lambda a, n: b[a - BASE:a - BASE + n]
    bad = [(hex(a), w) for a, h, w in BYTES if at(a, len(h) // 2).hex() != h]
    check("%d instruction byte strings of the handler, parser and writer match the ROM" % len(BYTES),
          not bad)
    ents = [int.from_bytes(at(TAB + 4 * k, 4), "little") for k in range(N)]
    check("0xF71767: 118 LE32 words, each 0xFFFFFFFF or a RAM address 0x6036xx-0x6038xx",
          all(e == 0xFFFFFFFF or 0x603600 <= e <= 0x6038FF for e in ents))
    check("  118 x 4 = 472 bytes ends at 0xF7193E; 0xF7193F is sub_F7193F (code)",
          TAB + 4 * N == 0xF7193F)
    check("  entries 1 and 2 (the two nibble-only addresses) name the same byte, 0x6038B7",
          ents[1] == ents[2] == 0x6038B7)
    used = [k for k, e in enumerate(ents) if e != 0xFFFFFFFF]
    check("  %d of 118 have a target; runs 0x20-0x36, 0x40-0x56, 0x60-0x75 plus 0x00-0x02" % len(used),
          used == [0, 1, 2] + list(range(0x20, 0x37)) + list(range(0x40, 0x57)) + list(range(0x60, 0x76)))
    return ents


def answer(name, text):
    return [x.encode("utf-8").decode("latin-1") for x in
            textwrap.wrap("⚠ ANSWERED 2026-09-25 (%s, was a name that was the address): %s  "
                          "notes/promb-2026-09-25/smf_sysex_param_change.py." % (name, text),
                          width=78, initial_indent="; ", subsequent_indent=";   ")]


ANSWERS = {
    "sub_F71525": ("SmfEvent_SysEx", "the SMF reader's SysEx-event handler.  With (0x1198), the bytes "
                   "left in the event, = 5 it matches 7E 7F 09 01 / 02 -- GM System On / Off -- and records "
                   "it (bit 0 of (0x124B); (0x1239) = 0xFF / 0x00; sub_F71417).  With (0x1198) = 16 it "
                   "matches 50 2C 04 00 11 00, an address pair into (0x137B)/(0x137C) (0x00:0x30-0x31, "
                   "0x01:0x04, or 0x11:<=0x75 -- `cp A,0x75` at 0xF71637), 00 00 01, two data nibbles into "
                   "(0x137E)/(0x137D), and calls SmfSysEx_ApplyParamChange."),
    "sub_F71697": ("SmfSysEx_ApplyParamChange", "joins the nibbles (SmfSysEx_JoinNibbles) and stores the "
                   "value by address-hi (0x137B): 0x00 -> SmfSysEx_WriteAddr00, 0x01 -> (0x1380), else "
                   "(0x11) -> SmfSysEx_WriteAddr11."),
    "sub_F716CD": ("SmfSysEx_JoinNibbles", "(0x137F) = (0x137E & 0x0F) << 4 | (0x137D & 0x0F), the "
                   "SysEx value from its two data nibbles."),
    "sub_F716E5": ("SmfSysEx_WriteAddr11", "writes the value to the RAM byte "
                   "SmfSysEx_Addr11_Targets[(0x137C)] names: lo 1 its low nibble, lo 2 its high nibble "
                   "(from the value's low nibble), any other lo the whole byte.  ⚠ `cp XDE,0xffffffff` "
                   "(0xF716F8) runs before `ld XDE,(XDE)` (0xF71700), so it tests the entry's ADDRESS and "
                   "never matches: as the bytes stand, a 0xFFFFFFFF entry is written through."),
    "sub_F71730": ("SmfSysEx_WriteAddr00", "address 0x00:0x30 writes the value's low nibble into the "
                   "low nibble of the byte at 0x603EE4, 0x00:0x31 into its high nibble."),
}

TABLE_HDR = """; --------------------------------------------------------------------------
; SmfSysEx_Addr11_Targets -- 118 LE32 RAM addresses, one per SysEx address
;   `11 lo` (lo 0x00-0x75): the byte that the SMF SysEx message
;   `50 2C 04 00 11 00 11 lo 00 00 01 nh nl` sets (SmfEvent_SysEx parses it,
;   SmfSysEx_WriteAddr11 writes it: `ld XDE,this` at 0xF716EE, then
;   `lda XDE,XDE+4*lo`).  Entry count: SmfEvent_SysEx drops lo > 0x75
;   (`cp A,0x75 / jrl UGT` at 0xF71637), so 118 entries = 472 bytes, the whole
;   object.  0xFFFFFFFF = no target (lo 0x03-0x1F, 0x37-0x3F, 0x57-0x5F);
;   lo 1 and lo 2 both name 0x6038B7, whose low / high nibble they write.
; --------------------------------------------------------------------------"""


def apply(ents):
    txt = open(SRC, "rb").read().decode("latin-1")
    L = txt.split("\n")
    # 1. the table: its old header kept (the "Unknown:" line answered), rows typed
    i = [k for k, t in enumerate(L) if t == "Data_F71767:"][0]
    k = i - 1
    while not L[k].startswith("; Unknown: everything about it except its bytes."):
        k -= 1
    L[k:k + 1] = [("; ⚠ ANSWERED 2026-09-25 (the \"nothing but its bytes\" verdict that stood "
                   "here): the").encode("utf-8").decode("latin-1"),
                  ";   header below says what it is; `Data_F71767` is retired."]
    k2 = [x for x in range(k - 40, k) if L[x].startswith("; Data_F71767 -- 472 bytes")]
    assert len(k2) == 1
    L[k2[0]] = L[k2[0]].replace("; Data_F71767 -- 472 bytes", "; 0xF71767 -- 472 bytes")
    i = [k for k, t in enumerate(L) if t == "Data_F71767:"][0]
    e = i + 1
    while L[e].startswith("\t.byte"):
        e += 1
    rows = []
    for n, v in enumerate(ents):
        rows.append("\t.long\t0x%08X\t; %06X  [0x%02X]%s" % (v, TAB + 4 * n, n,
                                                          "  no target" if v == 0xFFFFFFFF else ""))
    L = L[:i] + TABLE_HDR.split("\n") + ["Data_F71767:"] + rows + L[e:]
    # 2. the routines' open question
    txt = "\n".join(L)
    for old, (new, text) in ANSWERS.items():
        pat = (r'(; %s\n(?:;.*\n)*?)'
               r'; Unknown: what the routine is FOR\.  Left as sub_XXXXXX with the gap stated,\n'
               r';          per this tree\'s rule that a stated gap beats a plausible guess\.\n' % old)
        rep = "\n".join(answer(new, text)) + "\n"
        txt, n = re.subn(pat, lambda m: m.group(1) + rep, txt)
        assert n == 1, old
    # 3. names (and the structural labels under them)
    for old, new in RENAMES:
        txt = re.sub(r'\b%s(_\w+)?\b' % old, lambda m: new + (m.group(1) or ""), txt)
    open(SRC, "wb").write(txt.encode("latin-1"))
    print("wrote", SRC)


def main():
    ents = derive()
    if FAIL:
        print("\nVERDICT: FAIL (%d)" % len(FAIL))
        return 1
    if "--apply" in sys.argv:
        apply(ents)
    print("\nVERDICT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
