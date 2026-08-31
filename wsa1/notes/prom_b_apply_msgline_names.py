#!/usr/bin/env python3
"""Apply the MsgLine_* names to prom_b -- the round's rename, written down.

WHAT QUESTION THIS ANSWERS
    "Which 36 labels changed, to what, and on what evidence?"  It is the
    reproducibility artefact for the rename itself: the table below IS the
    change, and re-running with --check re-derives every literal in it from the
    ROM and fails if one has moved.

    Each entry is (address, new name, offset into the line, source address,
    width, "literal" or "table", the note that goes in the header).  The
    derivation those notes rest on is notes/prom_b_msgline.py; the write-up is
    notes/FINDINGS-prom_b-message-line.md.

RUN
    python3 notes/prom_b_apply_msgline_names.py --check   # re-derive, change nothing
    python3 notes/prom_b_apply_msgline_names.py --apply   # edit prom_b/wsa1_prom_b.s

⚠ --apply IS IDEMPOTENT ONLY IN THE SENSE THAT IT REFUSES A SECOND RUN: once a
  label is renamed the old token is gone and the script reports it missing.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
B_BASE = 0xF00000

# addr, new name, ("literal"|"table"), caption addr, caption width, what it says
RENAMES = [
    (0xF67D8C, "MsgLine_Volume",            "literal", 0xF67DC6,  9, "VOLUME = "),
    (0xF6C9C7, "MsgLine_PanKeyShiftTuningBendSens", "table", 0xF6CA3B, 10, "PAN      :"),
    (0xF6D410, "MsgLine_Control_Cleared",   "literal", 0xF6D464,  7, "CONTROL"),
    (0xF6D447, "MsgLine_Control",           "literal", 0xF6D464,  7, "CONTROL"),
    (0xF6D4C6, "MsgLine_TransportState_Plus14", "table", 0xF6D66D, 8, "        "),
    (0xF6D4E4, "MsgLine_Rhythm",            "literal", 0xF6D46D,  9, " RHYTHM  "),
    (0xF6D505, "MsgLine_Tempo",             "literal", 0xF6D527, 25, "  TEMPO  \x15=              "),
    (0xF6D540, "MsgLine_Tempo_Repaint",     "literal", 0xF6D561, 25, "  TEMPO  \x15=              "),
    (0xF6D57E, "MsgLine_Blank",             "literal", 0xF6D59C, 25, " " * 25),
    (0xF6D608, "MsgLine_TransportState_Plus4",  "table", 0xF6D66D, 8, "        "),
    (0xF6D642, "MsgLine_TransportState_Plus10", "table", 0xF6D66D, 8, "        "),
    (0xF6D9CB, "MsgLine_Tempo_F6D9CB",      "literal", 0xF6D9E2, 26, " TEMPO   \x15=              1"),
    (0xF6DDB7, "MsgLine_PartVolume",        "literal", 0xF6DE10,  7, "VOLUME="),
    (0xF6DEF7, "MsgLine_PartPanpot",        "literal", 0xF6DF50,  7, "PANPOT="),
    (0xF6DF57, "MsgLine_PartKeyShift",      "literal", 0xF6DFBA, 10, "KEY SHIFT="),
    (0xF6DFC4, "MsgLine_PartTuning",        "literal", 0xF6E027,  7, "TUNING="),
    (0xF6E02E, "MsgLine_PartBendSens",      "literal", 0xF6E087, 10, "BEND SENS="),
    (0xF6E091, "MsgLine_PartSustain",       "literal", 0xF6E0EB,  8, "SUSTAIN "),
    (0xF6E152, "MsgLine_PartDspEffect",     "literal", 0xF6E1A6, 11, "DSP EFFECT "),
    (0xF6E1B1, "MsgLine_PartEffect",        "literal", 0xF6E20B,  7, "EFFECT "),
    (0xF6E212, "MsgLine_PartEffect1",       "literal", 0xF6E259,  8, "EFFECT1="),
    (0xF6E261, "MsgLine_PartEffect2",       "literal", 0xF6E2AC,  8, "EFFECT2 "),
    (0xF6E2BA, "MsgLine_PartReverb",        "literal", 0xF6E2FF,  7, "REVERB="),
    (0xF6E306, "MsgLine_PanelMemory",       "literal", 0xF6E33F, 13, "PANEL MEMORY="),
    (0xF6E4F2, "MsgLine_AccompVolume",      "table",   0xF6E542, 16, "ACC. TOTAL VOL.="),
    (0xF6E5A5, "MsgLine_PartTremolo",       "literal", 0xF6E5FF,  8, "TREMOLO "),
    (0xF6E62A, "MsgLine_TotalReverb",       "literal", 0xF6E66A, 13, "TOTAL REVERB "),
    (0xF6E678, "MsgLine_PartMellowNormalBright", "table", 0xF6E6D4, 6, "      "),
    (0xF6E706, "MsgLine_TimeSignature",     "literal", 0xF6E728, 18, "TIME SIGNATURE: /4"),
    (0xF6E73A, "MsgLine_PartModulation2",   "literal", 0xF6E78B, 12, "MODULATION2="),
    (0xF6E797, "MsgLine_PartCtrlPedal",     "literal", 0xF6E7E8, 11, "CTRL.PEDAL="),
    (0xF6E7F3, "MsgLine_PartHold",          "literal", 0xF6E844,  5, "HOLD="),
    (0xF6E849, "MsgLine_PartRtCreateX",     "literal", 0xF6E89A, 12, "R.T.CREAT.X="),
    (0xF6E8A6, "MsgLine_PartRtCreateY",     "literal", 0xF6E8F7, 12, "R.T.CREAT.Y="),
    (0xF6E903, "MsgLine_PartRtCtrlX",       "literal", 0xF6E954, 11, "R.T.CTRL.X="),
    (0xF6E95F, "MsgLine_PartRtCtrlY",       "literal", 0xF6E9B0, 11, "R.T.CTRL.Y="),
]

# The two blank-out helpers.  They copy no caption, so they are not in the table
# above and get their own header text: their evidence is entirely INTERNAL --
# the destination and the count are immediates in the routine itself, and both
# runs end exactly on the line's last byte, 0x1001.
CLEARERS = [
    (0xF6D9FB, "MsgLine_Clear", 0x0FE4, 15, 2,
     "blanks the WHOLE 30-character line: `ld BC,0x000F` / `ld XIX,0x00000FE4` /"
     " `ld WA,0x2020` / `ld (XIX+),WA` / `djnz` -- fifteen 16-bit stores of two"
     " spaces, 0x0FE4 through 0x1001 inclusive"),
    (0xF6D5F1, "MsgLine_ClearTail", 0x0FE7, 27, 1,
     "blanks the line from +3 on: `ld XIX,0x00000FE7` / `ld BC,0x001B` /"
     " `ld A,0x20` / `ld (XIX+),A` / `djnz` -- twenty-seven byte stores of a"
     " space, 0x0FE7 through 0x1001 inclusive, and it saves and restores WA, BC"
     " and XIX around the loop"),
]

# 0xF6E4F2 has no label at all in the tree: the 64-byte note-name table above it
# ends at 0xF6E4F1 and the code that follows was never given one.  It is ADDED,
# with a full header, rather than renamed.
NEW_LABEL = 0xF6E4F2

class _Sep:
    """The `; -----` rule that opens every header block, matched by shape."""
    import re as _re
    _RE = _re.compile(r"^; -{10,}\n", _re.M)

    def block_start(self, s, lo, hi):
        """Start of the header BLOCK that ends just before `hi`.

        A header is `; ----` <prose> `; ----` <label>, so the separator nearest
        the label is the block's CLOSE; the one before it is its open.
        """
        starts = [m.start() for m in self._RE.finditer(s, lo, hi)]
        return starts[-2] if len(starts) >= 2 else (starts[-1] if starts else lo)


SEP = _Sep()

OLD_UNKNOWN = (
    "; Unknown: what the routine is FOR.  Left as sub_XXXXXX with the gap stated,\n"
    ";          per this tree's rule that a stated gap beats a plausible guess.\n"
)


def rom_text(addr, n):
    with open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), "rb") as f:
        b = f.read()
    o = addr - B_BASE
    return "".join(chr(c) for c in b[o:o + n])


def clearer_note(addr, name, dst, count, unit, what):
    end = dst + count * unit - 1
    return (
        f"; Name:    {name} -- named 2026-08-31 for what it writes.\n"
        f"; Evidence (DEVICE-FREE, INTERNAL): it {what}.\n"
        f";          0x{dst:04X}-0x{end:04X} is inside the 30-character on-screen text\n"
        f";          line at RAM 0x00000FE4, whose extent the interpreter-B record at\n"
        f";          0xF3D38A independently states as 30 characters; the run ends on\n"
        f";          the line's last byte and not one byte either side.  Derived by\n"
        f";          `python3 notes/prom_b_msgline.py`; write-up in\n"
        f";          notes/FINDINGS-prom_b-message-line.md.\n"
        f"; ⚠ CORRECTED 2026-08-31: this header used to end `Unknown: what the routine\n"
        f";          is FOR.  Left as sub_XXXXXX with the gap stated, per this tree's\n"
        f";          rule that a stated gap beats a plausible guess.`\n"
        f"; Unknown: nothing about the blanking; the line's own consumers are the open\n"
        f";          question, not this.\n"
    )


def check():
    bad = 0
    for addr, name, kind, src, w, want in RENAMES:
        got = rom_text(src, w)
        ok = got == want
        bad += not ok
        print(("  ok   " if ok else "  FAIL ") +
              f"0x{addr:06X} {name:36s} 0x{src:06X} x{w:<3d} {got!r}")
    print(f"\n{len(RENAMES) - bad}/{len(RENAMES)} captions still read as recorded")
    return 1 if bad else 0


def header_note(addr, name, kind, src, w, text):
    disp = text.replace("\x15", "<glyph 0x15>")
    what = ("entry 0 of the table at" if kind == "table" else "the literal at")
    return (
        f"; Name:    {name} -- named 2026-08-31 from the text it copies.\n"
        f"; Evidence (STRING): this routine copies {w} characters from {what}\n"
        f";          0x{src:06X} -- `{disp}` -- into the 30-character on-screen text\n"
        f";          line at RAM 0x00000FE4, and then calls the painter through slot\n"
        f";          0xF431B4.  That line is 30 characters of the 8x14 font drawn at\n"
        f";          x=8, y=180 of the 320x240 panel -- the bottom line -- which is\n"
        f";          derived from the ROM by `python3 notes/prom_b_msgline.py`; the\n"
        f";          write-up is notes/FINDINGS-prom_b-message-line.md.  The name\n"
        f";          claims the CAPTION and nothing else.\n"
        f"; ⚠ CORRECTED 2026-08-31: this header used to end `Unknown: what the routine\n"
        f";          is FOR.  Left as sub_XXXXXX with the gap stated, per this tree's\n"
        f";          rule that a stated gap beats a plausible guess.`  The gap is now\n"
        f";          closed for the caption only, and the `The name IS the address`\n"
        f";          line above it is superseded: the name is now the caption.\n"
        f"; Unknown: which RAM variable supplies the value drawn after the caption, and\n"
        f";          what screen id 0x0E -- the only screen prom_a will paint this line\n"
        f";          on -- is called.\n"
    )


NEW_HEADER = """
; --------------------------------------------------------------------------
; MsgLine_AccompVolume -- 0xF6E4F2
; ★ LABEL ADDED 2026-08-31, not renamed: this routine had none.  The 64-byte
;   note-name table Text_GAbABbBCDbDEbEFF ends at 0xF6E4F1 and the code that
;   follows it was emitted with no label of its own, so every tool that walks
;   this file by label attributed these 86 bytes to the DATA object above them.
; Called from: not established -- no thunk slot and no decoded branch in this
;          transcription names 0xF6E4F2.
; Extent:  0xF6E4F2-0xF6E541, 80 bytes, ends `ret`.  Both ends are pinned by
;          objects this file already frames: the 64-byte `.ascii`
;          Text_GAbABbBCDbDEbEFF ends exactly at 0xF6E4F1, and the caption table
;          Text_AccTotalVolBassVolumeDrumsVolumeAccmp1Volume begins exactly at
;          0xF6E542, one byte after the `ret`.
; Touches: (0x0EF5) (0x2661)
; Calls:   T_F431B0 sub_F6D5F1 T_F41AF0 T_F431B4
; Name:    named 2026-08-31 from the text it copies.
; Evidence (STRING): it copies 16 characters of entry HL of the table at
;          0xF6E542 -- `ACC. TOTAL VOL.=`, `   BASS VOLUME =`,
;          `  DRUMS VOLUME =`, ` ACCMP1 VOLUME =`, ` ACCMP2 VOLUME =`,
;          ` ACCMP3 VOLUME =`, six entries of 16 that end exactly where the next
;          routine begins -- into the 30-character on-screen text line at RAM
;          0x00000FE4+5, follows them with the three ASCII digits
;          Value_ToAsciiDigits3 leaves at (0x2661), and calls the painter
;          through slot 0xF431B4.  See notes/prom_b_msgline.py.
; Unknown: which RAM variable selects the entry.
; --------------------------------------------------------------------------
"""


def apply():
    with open(SRC) as f:
        s = f.read()
    n_lab = n_hdr = n_ref = 0
    todo = ([(a, n, k, sr, w, t, None) for a, n, k, sr, w, t in RENAMES] +
            [(a, n, None, None, None, None, (d, c, u, wh)) for a, n, d, c, u, wh in CLEARERS])
    for addr, name, kind, src, w, text, clr in todo:
        old = "sub_%06X" % addr
        if addr == NEW_LABEL:
            continue
        if old + ":" not in s:
            print(f"  MISSING {old}: -- nothing done for it")
            continue
        # 1. the header's title line and its Unknown stanza
        i = s.index("\n" + old + ":") + 1
        head = SEP.block_start(s, 0, i)
        blk = s[head:i]
        if OLD_UNKNOWN in blk:
            note = clearer_note(addr, name, *clr) if clr else header_note(addr, name, kind, src, w, text)
            blk = blk.replace(OLD_UNKNOWN, note)
            n_hdr += 1
        else:
            print(f"  NOTE {old}: no standard Unknown stanza; header title only")
        blk = blk.replace(f"; {old}\n", f"; {name} -- 0x{addr:06X}\n", 1)
        s = s[:head] + blk + s[i:]
        # 2. every occurrence of the token, definition and citations alike
        n_ref += len(re.findall(r"\b" + old + r"\b", s)) - 1
        s = re.sub(r"\b" + old + r"\b", name, s)
        n_lab += 1
    # 3. the added label
    anchor = '\t.ascii\t"<G ><Ab><A ><Bb><B ><C ><Db><D ><Eb><E ><F ><F#>                "\t; F6E4B2  64 bytes\n'
    if anchor in s and "MsgLine_AccompVolume:" not in s:
        s = s.replace(anchor, anchor + NEW_HEADER + "MsgLine_AccompVolume:\n", 1)
        n_lab += 1
    with open(SRC, "w") as f:
        f.write(s)
    print(f"labels changed/added: {n_lab}   headers rewritten: {n_hdr}   other citations updated: {n_ref}")
    return 0


if __name__ == "__main__":
    if "--apply" in sys.argv:
        sys.exit(apply())
    sys.exit(check())
