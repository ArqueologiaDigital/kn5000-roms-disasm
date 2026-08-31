#!/usr/bin/env python3
"""Emit prom_b 0xF57D4F-0xF5A7FF -- the DISK / FILE MENU module -- as assembly.

QUESTION IT ANSWERS
  What is in the 10,929-byte `.incbin` between INTT2's handler and the SC1 link
  module?  It is the machine's DISK and FILE user interface: 12 display lists (431
  records), 16 further record runs entered one record at a time (45 records),
  the 18 operand and string tables those records index, and the two pad runs
  that bracket them.  Gap V of
  `kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md` -- "how does a user reach
  Fdc_Request at all" -- names this module's two variant display lists,
  0xF580B0 and 0xF58127, as where to look.

  It was invisible to `scripts/analysis/prom_b_display_lists.py` because NOT ONE
  of its lists is entered by the `ld XIY / ld XIX / call` shape that scanner
  looks for.  Every entry is a STACK VENEER; see notes/prom_b_dl_stack_sites.py,
  which is where the call-site census and its 21 checks live.

WHAT IS PROVEN, PER SEGMENT KIND
  dl    a display list whose START and END are both operands of a located call
        site, and whose record length bytes walk from start to end EXACTLY.
        431 records over 12 spans, 61 (start, end) pairs, 109 call sites.
  recs  records that FRAME but whose enclosing span has no located two-ended
        entry.  Each is either (a) named directly by a ONE-PUSH call site that
        runs a single record through one interpreter-B handler -- 25 such
        records here, each with its site listed -- or (b) part of a run that
        walks exactly from the end of one proven object to the start of the
        next.  Which of the two is stated per segment.
  rows  N rows of W bytes.  W comes from the handler of the record that points
        at the table (8 for 0xF31B57, 6 for 0xF31B86, the +0x0B word for
        0xF31B21/0xF31B39); N comes from the EXTENT, never from the record's AND
        mask.  ⚠ The mask gives an upper bound on the INDEX, and in this module
        it is routinely far larger than the table: the record at 0xF583F0 allows
        64 entries and its table holds 43.  Every N here divides its extent
        exactly, and the extent runs to the next object that something else
        names -- that is the whole proof.
  raw   bytes whose structure is NOT established.  Three segments, 110 bytes.

RUN
  python3 notes/gen_prom_b_f58000_module.py --selftest   # 73 checks
  python3 notes/gen_prom_b_f58000_module.py --asm        # the assembly
  python3 notes/gen_prom_b_f58000_module.py --map        # the segment map only
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL
import prom_b_dl_stack_sites as SS
import gen_prom_b_display_lists_v2 as V2

B_BASE = 0xF00000
LO, HI = 0xF57D4F, 0xF5A800              # the whole .incbin this replaces
MOD_LO, MOD_HI = 0xF58000, 0xF59C5B      # the module proper

# ---------------------------------------------------------------- the gap map
# Every entry: (start, kind, args, label, why).  `why` is printed into the .s.
# Derived by hand from the ROM and re-checked by --selftest; the tiling test
# below is what stops a wrong boundary from shipping.
GAPS = [
 # --- gap after 0xF58000-0xF5841E -------------------------------------------
 (0xF5841F, "rows", (8, 4), "DLTab_F5841F",
  "4 rows x 8 bytes.  Extent 0xF5841F-0xF5843E runs to the record below, which "
  "is the next thing anything names.  Pointed at by the record at 0xF5840A "
  "(handler 0xF31B57 => 8-byte entries); that record's mask allows ONE entry "
  "and the table holds four, so the mask is not the count."),
 (0xF5843F, "recs", (0xF5844A, "B"), None,
  "one interpreter-B op-08 record, run ON ITS OWN by five one-push call sites: "
  "prom_a 0xFF4A55, 0xFF4A9E, 0xFF4D39, 0xFF4FBB, 0xFF5A7F, each "
  "`lda XBC,0xf5843f / push XBC / call 0xFF7623`, and 0xFF7623 sets (0x2540)=1 "
  "and jumps to thunk T_F41820 -> 0xF31B57, interpreter B's op-03/08 handler."),
 # --- gap after 0xF5844A-0xF58454 -------------------------------------------
 (0xF58455, "rows", (8, 43), "DLTab_F58455",
  "43 rows x 8 bytes, 0xF58455-0xF585AC.  Named by the records at 0xF583E5 "
  "(mask: 4 entries) and 0xF583F0 / 0xF5844A (mask: 64), both handler 0xF31B57. "
  "43 is the EXTENT / 8 and divides exactly; the two masks are upper bounds on "
  "the index and neither is 43."),
 (0xF585AD, "rows", (12, 10), "DLText_F585AD",
  "10 rows x 12 characters -- the DISK SAVE / LOAD CONTENT list: ALL, "
  "SEQUENCER, COMBINATION, SOUND, PANEL, MIDI SETTING, SOUND RE-MAP, "
  "COMBI RE-MAP, DRUM MAP, and one blank row.  Named by the record at 0xF58402 "
  "(handler 0xF31B21, entry width from its +0x0B word = 12).  The count is the "
  "extent: 0xF585AD + 10*12 = 0xF58625, exactly where the parallel 4-character "
  "table below starts."),
 (0xF58625, "rows", (4, 10), "DLText_F58625",
  "10 rows x 4 characters -- the FILE EXTENSION for each row of the table "
  "above: .ALL .SEQ .CMB .SND .PNL .MDS .SRM .CRM .DRM and one blank.  ★ The "
  "reader is prom_a 0xFF76DA: `ld BC,0x0004 / ld XIY,0x00F58625 / "
  "add IX,0x0006 / call sub_FF76FE`, i.e. FOUR bytes appended at offset 6 of a "
  "six-character name.  Its `and L,0x0f / cp L,0x09 / jr Z` sends index 9 "
  "somewhere else entirely, so slot 9 here is never used -- which is why it is "
  "blank."),
 (0xF5864D, "raw", (9,), "DLText_F5864D_Blank9",
  "nine spaces.  prom_a 0xFF76ED -- the index-9 arm of the reader above -- does "
  "`ld HL,0x0000 / ld BC,0x0009 / ld XIY,0x00F5864D`, so this is a 9-byte "
  "blanking constant, not a table.  9 + 10*4 = 49 = the bytes left in this gap."),
 # --- gap after 0xF58656-0xF587B1 -------------------------------------------
 (0xF587B2, "raw", (37,), "CharPalette_F587B2",
  "the 37 characters `_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789` -- an alphabet of "
  "the shape a name-entry screen needs.  ⚠⚠ NO READER LOCATED, and the six "
  "prom_a sites that spell this address are NOT readers: 0xFF577E, 0xFF57D6, "
  "0xFF58B9, 0xFF5F3A, 0xFF5FBA and 0xFF6016 are all `lda XBC,0xf587b2`, i.e. "
  "the END operand of the display list that stops here.  Both the 37 and the "
  "purpose are therefore EXTENTS AND APPEARANCE ONLY: 37 is where the run of "
  "printable bytes stops and the 8-byte table below begins."),
 (0xF587D7, "rows", (8, 9), "DLTab_F587D7",
  "9 rows x 8 bytes.  Named by the records at 0xF5878D and 0xF587A3 (handler "
  "0xF31B57).  Extent runs to 0xF5881F, the next named table."),
 (0xF5881F, "rows", (8, 37), "DLTab_F5881F",
  "37 rows x 8 bytes, 0xF5881F-0xF58946.  Named by 0xF58798 and 0xF587AE, whose "
  "mask allows 64.  The extent ends at 0xF58947, which is where a record chain "
  "starts that walks EXACTLY to the end of this gap -- so the boundary is fixed "
  "from both sides, and 296 / 8 = 37 divides."),
 (0xF58947, "recs", (0xF589BD, "auto"), None,
  "a display list with no located entry point.  Its records frame from 0xF58947 "
  "and the chain reaches the gap end at 0xF58A21 through the two operand tables "
  "below.  Text: `Please set the PASSWORD`, `DISK SAVE:PASSWORD`, `SAVE`."),
 (0xF589BD, "rows", (8, 2), "DLTab_F589BD",
  "2 rows x 8 bytes; named by the record at 0xF589B2 immediately above, whose "
  "mask allows exactly 2.  Mask and extent agree here."),
 (0xF589CD, "recs", (0xF589D8, "auto"), None,
  "one interpreter-B op-04 record; its pointer names the 6-byte table below."),
 (0xF589D8, "rows", (6, 2), "DLTab_F589D8",
  "2 rows x 6 bytes -- handler 0xF31B86 multiplies the index by 6.  Named by "
  "0xF589CD; mask allows 2 and the extent is 12."),
 (0xF589E4, "recs", (0xF58A21, "auto"), None,
  "two more records of the same unentered list: `PASSWORD is already set.` and "
  "`Please set the same PASSWORD`.  The second ends EXACTLY on 0xF58A21, the "
  "start of the next proven span."),
 # --- gap after 0xF58A21-0xF58A40 -------------------------------------------
 (0xF58A41, "recs", (0xF58AA5, "auto"), None,
  "nine records that frame from the end of one proven span to the start of the "
  "next, with no located entry point of their own.  ★ This is the MIDI FILE "
  "SAVE file-selection screen: `SAVE`, `MIDI FILE SAVE : FILE SELECTION`, "
  "`DEL`.  prom_a 0xFF5CDC names 0xF58A41 as the END of the span above it."),
 # --- gap after 0xF58AA5-0xF59127 -------------------------------------------
 (0xF59128, "rows", (10, 4), "DLText_F59128",
  "4 rows x 10 characters: `USER 1    `, `USER 2    `, `USER1 DRUM`, "
  "`USER2 DRUM`.  Named by the records at 0xF590F1 and 0xF59100 (handler "
  "0xF31B21, entry width 10 from their +0x0B word), whose mask allows exactly 4. "
  "Mask, extent and content all agree, and 10 is the same field width prom_a "
  "0xFF76D1 copies before appending a 4-character extension."),
 (0xF59150, "recs", (0xF59166, "B"), None,
  "two interpreter-B records, each run ON ITS OWN: 0xF59150 from prom_a "
  "0xFF68AF, 0xFF69A7, 0xFF6AEF, 0xFF6EF9 (`call 0xFF763F` -> T_F4181C -> "
  "0xF31B57) and 0xF5915B from 0xFF697A, 0xFF6A86 (`call 0xFF7623`).  Both "
  "point at the table below."),
 (0xF59166, "rows", (8, 8), "DLTab_F59166",
  "8 rows x 8 bytes; the extent to the next record is 64 and divides."),
 (0xF591A6, "recs", (0xF591BC, "B"), None,
  "the same pair one screen further on: 0xF591A6 from 0xFF6819, 0xFF6BA6, "
  "0xFF6D50, 0xFF6E7A, 0xFF701D; 0xF591B1 from 0xFF6B8D, 0xFF6D26, 0xFF6FF6."),
 (0xF591BC, "rows", (8, 8), "DLTab_F591BC",
  "8 rows x 8 bytes, 0xF591BC-0xF591FB, ending exactly on the next proven span."),
 # --- gap after 0xF591FC-0xF593F2 -------------------------------------------
 (0xF593F3, "recs", (0xF59414, "B"), None,
  "three interpreter-B records, each with its own one-push callers: 0xF593F3 "
  "from prom_a 0xFF53B7, 0xFF5460; 0xF593FE from 0xFF526D, 0xFF52EF, 0xFF533C, "
  "0xFF53A7, 0xFF5450; 0xF59409 from seven sites 0xFF6163-0xFF6369."),
 (0xF59414, "rows", (8, 7), "DLTab_F59414",
  "7 rows x 8 bytes, 0xF59414-0xF5944B.  ⚠ The records above allow 4 and 8 "
  "entries and point at 0xF59414 and 0xF5942C -- overlapping views of the same "
  "run, 3 rows apart.  56 / 8 = 7 is the extent; neither mask is 7."),
 # --- gap after 0xF5944C-0xF59516 -------------------------------------------
 (0xF59517, "recs", (0xF5952D, "B"), None,
  "two interpreter-B records; 0xF59517 is run alone from prom_a 0xFF4512 and "
  "0xFF4733, 0xF59522 from 0xFF4506, 0xFF4603, 0xFF4623."),
 (0xF5952D, "rows", (8, 1), "DLTab_F5952D",
  "one row of 8 bytes; both records above allow exactly one entry."),
 (0xF59535, "rows", (3, 2), "DLText_F59535",
  "2 rows x 3 characters: `OFF`, `ON `.  Named by the records at 0xF59915 and "
  "0xF59924 (handler 0xF31B21, +0x0B word = 3), whose mask allows exactly 2."),
 (0xF5953B, "recs", (0xF5957D, "B"), None,
  "six interpreter-B records in three pairs, each pair naming one 8-byte table; "
  "0xF5953B, 0xF59546, 0xF59567 and 0xF59572 all have their own one-push "
  "callers in prom_a (0xFF5098, 0xFF5DA6, 0xFF5346, 0xFF53F2, 0xFF6218, "
  "0xFF62F0, 0xFF44EF, 0xFF4681, 0xFF466E, 0xFF46EC)."),
 (0xF5957D, "rows", (8, 10), "DLTab_F5957D",
  "10 rows x 8 bytes; extent runs to the numbered label table below."),
 (0xF595CD, "rows", (4, 100), "DLText_F595CD",
  "★ 100 rows x 4 characters: ` 01:` ` 02:` ... ` 99:` `100:`.  The count is "
  "not a guess and not a mask: the rows are literally numbered, the hundredth "
  "reads `100:`, and 0xF595CD + 100*4 = 0xF5975D, exactly the base the record "
  "at 0xF5953B points at."),
 (0xF5975D, "rows", (8, 30), "DLTab_F5975D",
  "30 rows x 8 bytes, 0xF5975D-0xF5984C.  ⚠ Its naming record allows 16 and "
  "another record points at 0xF597D5, 10 rows in.  240 / 8 = 30 is the extent."),
 (0xF5984D, "recs", (0xF59857, "A"), None,
  "one interpreter-A op-0A record (handler 0xF31A75, four words, 10 bytes -- "
  "the declared length exactly).  No located entry point."),
 (0xF59857, "raw", (4,), "DLText_F59857_MID",
  "the four characters `.MID`.  It abuts the next proven span and is the same "
  "shape as the nine extensions at 0xF58625; ⚠ no instruction that reads it has "
  "been located, so `the MIDI file extension` is the obvious reading and is NOT "
  "asserted."),
 # --- gap after 0xF5985B-0xF59903 -------------------------------------------
 (0xF59904, "recs", (0xF59915, "A"), None,
  "one interpreter-A text record, `COMPOSER LOAD` -- 17 declared bytes, 4 of "
  "header and operand and 13 of text, which is the length rule exactly.  prom_a "
  "0xFF6521 names 0xF59904 as the END of the span above it."),
 # --- gap after 0xF59915-0xF5993D -------------------------------------------
 (0xF5993E, "recs", (0xF59952, "B"), None,
  "two interpreter-B op-00 records (decimal readout, 10 bytes each).  ★ Both "
  "are run ON THEIR OWN and the sites say by WHICH handler: 0xF5993E from "
  "prom_a 0xFF5DBA, 0xFF624D, 0xFF6325 and 0xF59948 from 0xFF50AC, 0xFF5376, "
  "0xFF541F, all `push / call 0xFF7668`, and 0xFF7668 jumps to thunk T_F41800 "
  "-> 0xF31BA1, which IS interpreter B's op-00 handler."),
 # --- gap after 0xF59952-0xF5995B -------------------------------------------
 (0xF5995C, "recs", (0xF59966, "A"), None,
  "one interpreter-A op-1B record (handler 0xF31A75, 10 bytes).  Opcode 0x1B is "
  "above interpreter B's bound of 0x0F, so B could not dispatch it at all."),
 # --- gap after 0xF59966-0xF599F4 -------------------------------------------
 (0xF599F5, "raw", (64,), "CharTable_F599F5",
  "64 bytes of character codes -- `\\x20\\x11\\x13\\x14\\x12\\x16`, then "
  "`MOPQRSTUVWX`, then `!` through `L`, `N`, and a trailing 0x0F.  It looks "
  "like a keyboard-order to character-code map for a name-entry screen, and "
  "that is NOT asserted: the only prom_a site that names 0xF599F5 (0xFF56A8) "
  "names it as the END of the display list above it, not as a table base.  ⚠ NO "
  "READER LOCATED."),
 # --- gap after 0xF59A35-0xF59C2B -------------------------------------------
 (0xF59C2C, "raw", (4,), "DLText_F59C2C",
  "the four characters `1-10`.  prom_a 0xFF5601 and 0xFF5E2B name 0xF59C2C as "
  "the END of the display list above it, so this is a separate object; the same "
  "four characters appear again as the payload of the record at 0xF59C4B."),
 (0xF59C30, "recs", (0xF59C3B, "B"), None,
  "one interpreter-B op-03 record naming the table below.  No located entry."),
 (0xF59C3B, "rows", (8, 2), "DLTab_F59C3B",
  "2 rows x 8 bytes; the record above allows exactly 2 and the extent is 16."),
 (0xF59C4B, "recs", (0xF59C5B, "A"), None,
  "two interpreter-A records: op 06 with the text `1-10`, then op 0E, whose "
  "handler 0xF31A9F reads three words and so implies 8 bytes -- the declared "
  "length.  ★ Its LAST operand byte is the 0x00 at 0xF59C5A, so the module ends "
  "at 0xF59C5B and the zero pad below is 2,981 bytes, not the 2,982 the SC1 "
  "module's header states.  Both readings agree about the bytes."),
]


def load():
    a, b = DL.load()
    sites = set(DL.call_sites(a, b)) | SS.sites(a, b)
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    htb = [int.from_bytes(b[0x31DB1 + i * 4:0x31DB1 + i * 4 + 4], "little") for i in range(15)]
    return a, b, sites, hta, htb


def spans(b, sites):
    return [(s, e) for s, e in DL.spans(sites) if MOD_LO <= s < MOD_HI and DL.walk(b, s, e)]


def segments(b, sites):
    """The whole 0xF57D4F-0xF5A7FF as a tiling list of (start, end, kind, args, label, why)."""
    segs = [(LO, LO + 32, "sel", (), "LinkSelector1_Table",
             "eight 32-bit little-endian addresses.  The interprocessor link's "
             "selector-1 dispatch table: prom_a's INT0 path indexes it with the "
             "command's top three bits (notes/FINDINGS-interprocessor-link.md sec.1; "
             "re-derived by notes/prom_a_byte_checks.py)."),
            (LO + 32, 0xF58000, "fill", (0x0E,), None, "pad")]
    marks = sorted([(s, "dl", (e,), None, None) for s, e in spans(b, sites)]
                   + [(g[0], g[1], g[2], g[3], g[4]) for g in GAPS])
    for i, (s, kind, args, label, why) in enumerate(marks):
        end = args[0] if kind in ("dl", "recs") else (
            s + args[0] * args[1] if kind == "rows" else s + args[0])
        segs.append((s, end, kind, args, label, why))
    segs.append((MOD_HI, HI, "fill", (0x00,), None, "pad"))
    return segs


def attribute(b, p, hta, htb, hint):
    """Which interpreter does the record at p belong to?  A, B, or a stated reason."""
    if hint in ("A", "B"):
        return hint
    op, ln = b[p - B_BASE], b[p - B_BASE + 1]
    if op >= 0x0F:
        return "A"                      # above interpreter B's bound
    ha, hb = hta[op], htb[op]
    imply_a = {0xF31A75: 10, 0xF31A9F: 8, 0xF31AAC: 6, 0xF31ABE: 12, 0xF31ACE: 5}.get(ha)
    imply_b = {0xF31BA1: 10, 0xF31B21: 15, 0xF31B39: 17, 0xF31B57: 11, 0xF31B86: 11,
               0xF31BD7: 11, 0xF31C14: 12, 0xF31C56: 13, 0xF31C9E: 12}.get(hb)
    if ha in (0xF31A3A, 0xF31A52) and imply_b != ln:
        return "A"                      # a text record only A has
    if imply_b == ln and imply_a != ln:
        return "B"
    if imply_a == ln and imply_b != ln:
        return "A"
    return "A"


def emit(b, segs, hta, htb, sites):
    own = V2.ownership(b, sites)
    starts = {s for s, e, t in sites}
    out = []
    for s, e, kind, args, label, why in segs:
        if kind == "fill":
            n = e - s
            out.append("\n; --- 0x%06X-0x%06X: %d bytes of 0x%02X pad ---\n" % (s, e - 1, n, args[0]))
            out.append("\t.fill\t%d, 1, 0x%02X\n" % (n, args[0]))
            continue
        out.append("\n; " + "-" * 74 + "\n")
        if kind == "sel":
            out.append("; %s -- 0x%06X-0x%06X, 8 x 32-bit\n" % (label, s, e - 1))
            out += wrap(why)
            out.append("; " + "-" * 74 + "\n%s:\n" % label)
            for k in range(8):
                v = int.from_bytes(b[s - B_BASE + 4 * k:s - B_BASE + 4 * k + 4], "little")
                out.append("\t.long\t0x%08X\t; [%d] -> 0x%06X\n" % (v, k, v))
        elif kind in ("dl", "recs"):
            r = DL.walk(b, s, e)
            which = ("interpreter A" if kind == "recs" and args[1] == "A" else
                     "interpreter B" if kind == "recs" and args[1] == "B" else None)
            if kind == "dl":
                ends = sorted({y[1] for y in sites if s <= y[0] < e})
                ent = sorted({y[0] for y in sites if s <= y[0] < e})
                na = sum(1 for p, op, ln in r if own.get(p) != {DL.RUN_B})
                which = ("interpreter A" if na == len(r) else "interpreter B" if na == 0
                         else "interpreter A (%d records) and B (%d)" % (na, len(r) - na))
                out.append("; 0x%06X-0x%06X -- %d display-list records, %d bytes -- %s\n"
                           % (s, e - 1, len(r), e - s, which))
                out.append(";   entered at: %s\n" % ", ".join("0x%06X" % x for x in ent))
                out.append(";   ends used:  %s\n" % ", ".join("0x%06X" % x for x in ends))
                out.append(";   Evidence: every entry above is a STACK-VENEER call site "
                           "(notes/prom_b_dl_stack_sites.py);\n"
                           ";     the record length bytes walk from the start to the end exactly.\n")
            else:
                out.append("; 0x%06X-0x%06X -- %d display-list record(s), %d bytes -- %s\n"
                           % (s, e - 1, len(r), e - s, which or "attributed per record"))
                out += wrap("Evidence: " + why)
            out.append("; " + "-" * 74 + "\n")
            for p, op, ln in r:
                if kind == "dl":
                    out += V2.render(b, [(p, op, ln)], hta, htb, starts, own)
                else:
                    lbl = "DL_%06X:\n" % p
                    who = attribute(b, p, hta, htb, args[1] if len(args) > 1 else "auto")
                    o2 = (V2.render_b(b, p, op, ln, htb) if who == "B"
                          else DL.render(b, [(p, op, ln)], hta, set()))
                    out.append(lbl)
                    out += o2
        elif kind == "rows":
            w, n = args
            out.append("; %s -- 0x%06X-0x%06X, %d rows x %d bytes\n" % (label, s, e - 1, n, w))
            out += wrap(why)
            out.append("; Entry count: %d = (0x%06X - 0x%06X) / %d, exact.\n" % (n, e, s, w))
            out.append("; " + "-" * 74 + "\n%s:\n" % label)
            for k in range(n):
                d = b[s - B_BASE + k * w:s - B_BASE + (k + 1) * w]
                txt = "".join(chr(c) if 0x20 <= c < 0x7F else "." for c in d)
                out.append("\t.byte\t%s\t; [%3d] 0x%06X |%s|\n"
                           % (", ".join("0x%02X" % c for c in d), k, s + k * w, txt))
        elif kind == "raw":
            n = e - s
            out.append("; %s -- 0x%06X-0x%06X, %d bytes, STRUCTURE NOT ESTABLISHED\n"
                       % (label, s, e - 1, n))
            out += wrap(why)
            out.append("; " + "-" * 74 + "\n%s:\n" % label)
            for o in range(0, n, 16):
                d = b[s - B_BASE + o:s - B_BASE + min(o + 16, n)]
                txt = "".join(chr(c) if 0x20 <= c < 0x7F else "." for c in d)
                out.append("\t.byte\t%s\t; 0x%06X |%s|\n"
                           % (", ".join("0x%02X" % c for c in d), s + o, txt))
    return out


def wrap(text, width=74):
    words, line, out = text.split(), ";  ", []
    for w in words:
        if len(line) + len(w) + 1 > width:
            out.append(line + "\n")
            line = ";    " + w
        else:
            line += " " + w
    out.append(line + "\n")
    return out


# --------------------------------------------------------------------- checks
def selftest():
    a, b, sites, hta, htb = load()
    fail, n = [0], [0]

    def check(msg, got, want):
        n[0] += 1
        ok = got == want
        print("  %-68s %-20s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
        if not ok:
            fail[0] += 1

    print("gen_prom_b_f58000_module selftest")
    segs = segments(b, sites)
    # 1. the segments tile [LO, HI) with no gap and no overlap
    cur, holes, overlaps = LO, [], []
    for s, e, *_ in segs:
        if s > cur:
            holes.append((cur, s))
        if s < cur:
            overlaps.append((s, cur))
        cur = max(cur, e)
    check("segments: holes", holes, [])
    check("segments: overlaps", overlaps, [])
    check("segments: last end", "0x%06X" % cur, "0x%06X" % HI)
    check("segment count", len(segs), 54)
    # 2. every `rows` extent divides exactly, and every `dl`/`recs` frames
    for s, e, kind, args, label, why in segs:
        if kind == "rows":
            check("0x%06X %s: %d x %d fills its extent" % (s, label, args[1], args[0]),
                  args[0] * args[1], e - s)
        elif kind in ("dl", "recs"):
            r = DL.walk(b, s, e)
            check("0x%06X: %s frames" % (s, kind), r is not None and
                  r[-1][0] + r[-1][2] == e, True)
    # 3. the emitted text assembles back to the ROM -- the only test that cannot lie
    txt = "".join(emit(b, segs, hta, htb, sites))
    got = assemble(txt)
    check("emitted bytes == ROM 0x%06X-0x%06X" % (LO, HI - 1),
          got == b[LO - B_BASE:HI - B_BASE], True)
    check("emitted length", len(got), HI - LO)
    # 4. the headline numbers
    dls = [x for x in segs if x[2] == "dl"]
    recs = [x for x in segs if x[2] == "recs"]
    check("display-list spans", len(dls), 12)
    check("records in them", sum(len(DL.walk(b, s, e)) for s, e, *_ in dls), 431)
    check("orphan record segments", len(recs), 16)
    check("records in them", sum(len(DL.walk(b, s, e)) for s, e, *_ in recs), 45)
    check("table segments", len([x for x in segs if x[2] == "rows"]), 18)
    check("raw (structure not established) bytes",
          sum(e - s for s, e, k, *_ in segs if k == "raw"), 118)
    check("substantive bytes emitted (all but the two pads)",
          sum(e - s for s, e, k, *_ in segs if k != "fill"), 7291)
    check("filler emitted", sum(e - s for s, e, k, *_ in segs if k == "fill"), 3638)
    # 4z. THE MASK IS NOT THE COUNT.  Every `rows` count here comes from the
    # EXTENT.  This measures how often the record's AND mask would have given a
    # different answer -- i.e. how often the cheap method would have been wrong.
    ptrs = {}
    for s2, e2, k2, a2, l2, w2 in segs:
        if k2 not in ("dl", "recs"):
            continue
        for p2, op2, ln2 in DL.walk(b, s2, e2):
            if op2 >= 15 or ln2 < 11:
                continue
            h2 = htb[op2]
            if h2 not in (0xF31B21, 0xF31B39, 0xF31B57, 0xF31B86):
                continue
            d2 = b[p2 - B_BASE:p2 - B_BASE + ln2]
            t2 = int.from_bytes(d2[7:11], "little")
            if MOD_LO <= t2 < MOD_HI:
                ptrs.setdefault(t2, set()).add((d2[4] >> (d2[5] & 7)) + 1)
    rows = [(s2, a2[1], l2) for s2, e2, k2, a2, l2, w2 in segs if k2 == "rows"]
    check("tables whose naming record's MASK disagrees with the extent count",
          sum(1 for s2, n2, l2 in rows if ptrs.get(s2) and n2 not in ptrs[s2]), 10)
    check("tables whose mask agrees", sum(1 for s2, n2, l2 in rows
                                          if ptrs.get(s2) and n2 in ptrs[s2]), 6)
    check("tables with no naming record at all (proven another way)",
          sorted(l2 for s2, n2, l2 in rows if not ptrs.get(s2)),
          ["DLText_F58625", "DLText_F595CD"])
    # 4a. The module's labels spell capital O with character code 0x30.  The
    # banner in the .s says the FONT is why; that is a byte claim, so check it.
    f = lambda c: b[0xF1B400 - B_BASE + c * 14:0xF1B400 - B_BASE + (c + 1) * 14]
    check("Font_Svc06_8x14 cell 0x30 == cell 0x4F, byte for byte", f(0x30) == f(0x4F), True)
    check("  ...and they are not both blank", f(0x30) != bytes(14), True)
    check("`DISK L0AD` really is in the ROM with a 0x30",
          b[0xF58022 - B_BASE:0xF5802B - B_BASE], b"DISK L0AD")
    txt2 = "".join(chr(c) if 0x20 <= c < 0x7F else "\n"
                   for c in b[MOD_LO - B_BASE:MOD_HI - B_BASE])
    runs = re.findall(r"[A-Za-z0-9 .:\-]{3,}", txt2)
    check("...and the module uses BOTH codes: 0x30 count, 0x4F count",
          (sum(r.count("0") for r in runs), sum(r.count("O") for r in runs)), (67, 71))
    check("...the SAME phrase appears both ways",
          (b[0xF58A66 - B_BASE:0xF58A85 - B_BASE], b[0xF59226 - B_BASE:0xF59245 - B_BASE]),
          (b"MIDI FILE SAVE : FILE SELECTION", b"MIDI FILE SAVE : FILE SELECTI0N"))
    # 4b. EVERY prom_a address quoted in a GAPS note must START an instruction.
    # The first draft of this file had ELEVEN that did not -- all of them taken
    # from a raw byte scan, which finds the OPERAND.  This is the check that
    # would have caught them, so it runs on every emit.
    asrc = open(image_path(ROOT, "prom_a/wsa1_prom_a.s"), encoding="utf-8").read()
    istart = {int(m, 16) for m in re.findall(r";\s+([0-9A-F]{6})\s+[0-9a-f]{2}", asrc)}
    quoted = sorted({int(m, 16) for g in GAPS
                     for m in re.findall(r"0x(F[0-9A-F]{5})\b", g[4] or "")
                     if 0xF80000 <= int(m, 16)})
    check("prom_a addresses quoted in the segment notes", len(quoted), 66)
    check("  ...that do NOT start an instruction in prom_a/wsa1_prom_a.s",
          [hex(x) for x in quoted if x not in istart], [])
    # 5. the LAST segment, on its own
    s, e, kind, args, label, why = segs[-2]
    check("LAST content segment is 0x%06X-0x%06X" % (s, e - 1),
          (s, e, kind), (0xF59C4B, 0xF59C5B, "recs"))
    r = DL.walk(b, s, e)
    check("  ...its last record ends exactly on the module end",
          r[-1][0] + r[-1][2], MOD_HI)
    check("  ...and the byte after it starts the zero pad",
          set(b[MOD_HI - B_BASE:HI - B_BASE]), {0})
    print("\n%d checks ran, %d failed" % (n[0], fail[0]))
    return 1 if fail[0] else 0


def assemble(txt):
    """Assemble the emitted directives back to bytes, with this tree's toolchain."""
    import subprocess
    import tempfile
    llvm = os.environ.get("LLVM_BIN", "/home/fsanches/compartilhado/llvm-project/build/bin")
    with tempfile.TemporaryDirectory() as d:
        src = os.path.join(d, "t.s")
        open(src, "w").write('.text\n' + txt)
        o = os.path.join(d, "t.o")
        subprocess.run([os.path.join(llvm, "llvm-mc"), "-triple=tlcs900", "-filetype=obj",
                        "-o", o, src], check=True, cwd=ROOT)
        out = os.path.join(d, "t.bin")
        subprocess.run([os.path.join(llvm, "llvm-objcopy"), "-O", "binary",
                        "--only-section=.text", o, out], check=True)
        raw = open(out, "rb").read()
    return raw


def main():
    a, b, sites, hta, htb = load()
    if "--selftest" in sys.argv:
        return selftest()
    segs = segments(b, sites)
    if "--map" in sys.argv:
        for s, e, kind, args, label, why in segs:
            print("  0x%06X-0x%06X  %-5s %6d  %s" % (s, e - 1, kind, e - s, label or ""))
        return 0
    sys.stdout.write("".join(emit(b, segs, hta, htb, sites)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
