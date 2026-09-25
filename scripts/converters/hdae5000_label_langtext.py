#!/usr/bin/env python3
r"""hdae5000_label_langtext.py -- the trilingual message block and its reader.

QUESTION ANSWERED / JOB IT DOES
-------------------------------
What reads HDAE5000_Multilingual_Messages (0x2E3704-0x2E5ADF), and how?

  HDAE5000_AcLanguageText1Proc (0x28B554; the class procedure of UI class
  016A:000A, HDAE5000_RECORD_TABLE record 10) takes a message number N from
  its object (`ld wa,(xhl+26)`), makes WA = N-1, accepts 0..0x42 directly and
  0xC7..0xD3 after `sub wa,0x84` (so N = 1..67 and 200..212), and switches:
      lda xix,(0x2E5AE0) ; ld WA,(XIX+WA) ; lda xix,(0x28B6DC) ; jp T,XIX+WA
  Every case then compares the language word (xsp+4) with 1, 2, 3 and copies
  one string with HDAE5000_StrCpy, the pointer pushed as two halves
  (`pushw 0x002e` / `pushw 0xLLLL`).  Out-of-range numbers go to the same
  default case three table entries use.

With no argument this prints and ASSERTS those facts from the ROM and the
current source (80 table entries, every target an instruction start, every
string of the block pushed by exactly the cases found).  With --apply it:
  * labels every case target HDAE5000_AcLanguageText1Proc_Msg<NNN> (the
    default: _NoMessage, renaming the local label already there),
  * retypes the table at 0x2E5AE0 as 80 `.short <case> - <case for N=1>`
    under HDAE5000_LangText_CaseTable and makes both `lda xix` operands
    symbolic,
  * labels every string HDAE5000_LangMsg_<NNN>_<EN|DE|FR> (keeping the
    existing directive lines and their comments), with a one-line note, and
    notes the label on each `pushw` low half that points at it.

RUN (repo root, after a build of the hdae5000 image)
    python3 scripts/converters/hdae5000_label_langtext.py            # facts
    python3 scripts/converters/hdae5000_label_langtext.py --apply
--apply re-links through scripts/analysis/hdae5000_line_map.py, which refuses
unless the modified tree is byte-identical to the dump.
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import hdae5000_line_map as hlm  # noqa: E402

B = 0x280000
TAB, NTAB, CASE0 = 0x2E5AE0, 80, 0x28B6DC
TXT0, TXT1 = 0x2E3704, 0x2E5AE0
LANG = {1: "EN", 2: "DE", 3: "FR"}
LABEL = re.compile(r'^([.A-Za-z_][\w.]*):')


def fail(m):
    sys.exit("REFUSED: " + m)


def msgno(i):
    return i + 1 if i <= 0x42 else i + 0x84 + 1


def analyse(rows, rom):
    u16 = lambda a: int.from_bytes(rom[a - B:a - B + 2], "little")
    at = collections.defaultdict(list)
    for a, rel, n, t in rows:
        at[a].append((rel, n, t))
    tab = [u16(TAB + 2 * i) for i in range(NTAB)]
    targets = sorted(set(CASE0 + o for o in tab))
    for t in targets:
        if not any(not LABEL.match(x[2]) for x in at.get(t, [])):
            fail("case target 0x%06X is not an instruction start" % t)
    first = {}
    for i, o in enumerate(tab):
        first.setdefault(CASE0 + o, msgno(i))
    default = CASE0 + max(set(tab), key=tab.count)
    if tab.count(default - CASE0) < 2:
        fail("no shared default case")
    code = [(a, t) for a, rel, n, t in rows if rel == "hdae5000_ui_display.s" and CASE0 <= a < 0x28CE00]
    strings, pushes = collections.defaultdict(dict), []
    cur = lang = hi = None
    tset = set(targets)
    for a, t in code:
        if a in tset:
            cur, lang = a, None
        m = re.search(r'cpw\s*\(xsp\+4\),\s*0x000([123])', t)
        if m:
            lang = int(m.group(1))
        m = re.match(r'\s*pushw\s+0x([0-9a-fA-F]{4})\s*$', t)
        if m and int(m.group(1), 16) == 0x002E:
            hi = a
            continue
        if m and hi is not None and cur is not None:
            addr = 0x2E0000 | int(m.group(1), 16)
            if TXT0 <= addr < TXT1:
                if cur == default:
                    strings[cur][lang or 0] = addr
                else:
                    if lang is None:
                        fail("push at 0x%06X before any language compare" % a)
                    strings[cur][lang] = addr
                pushes.append((a, addr))
        hi = None
    # every string of the block is pushed
    pushed = {v for d in strings.values() for v in d.values()}
    a, allstr = TXT0, []
    while a < TXT1 - 1:
        z = rom.index(0, a - B) + B
        allstr.append(a)
        a = z + 1
        if a % 2 and rom[a - B] == 0 and a < TXT1:
            a += 1
    unref = [x for x in allstr if x not in pushed]
    if unref or a != TXT1:
        fail("%d unreferenced strings / block end 0x%06X" % (len(unref), a))
    return tab, targets, first, default, strings, pushes, allstr


def names(first, default, strings):
    case_name, str_name = {}, {}
    for t, n in first.items():
        case_name[t] = "HDAE5000_AcLanguageText1Proc_" + ("NoMessage" if t == default else "Msg%03d" % n)
    for t in sorted(strings, key=lambda t: first[t]):
        for lg, addr in sorted(strings[t].items()):
            if addr in str_name:
                continue
            str_name[addr] = ("HDAE5000_LangMsg_NoMessage" if t == default
                              else "HDAE5000_LangMsg_%03d_%s" % (first[t], LANG[lg]))
    return case_name, str_name


def main(apply):
    rows, rom = hlm.build_map()
    tab, targets, first, default, strings, pushes, allstr = analyse(rows, rom)
    case_name, str_name = names(first, default, strings)
    print("table entries %d, distinct case targets %d (default 0x%06X used by %d entries)"
          % (len(tab), len(targets), default, tab.count(default - CASE0)))
    print("strings in 0x%06X-0x%06X: %d, all pushed by a case; %d pushw sites"
          % (TXT0, TXT1 - 1, len(allstr), len(pushes)))
    if not apply:
        return
    lines = {rel: open(os.path.join(hlm.HDAE, rel), encoding="latin-1").read().split("\n")
             for rel in ("hdae5000_ui_display.s", "hdae5000_data_tables.s")}
    at = collections.defaultdict(list)
    for a, rel, n, t in rows:
        at[a].append((rel, n, t))
    U, D = lines["hdae5000_ui_display.s"], lines["hdae5000_data_tables.s"]
    ins = collections.defaultdict(list)            # rel -> [(line_no, [text...])]
    renames = {}
    for t in targets:
        labs = [x for x in at[t] if LABEL.match(x[2])]
        if labs:
            renames[LABEL.match(labs[0][2]).group(1)] = case_name[t]
        else:
            code = [x for x in at[t] if not LABEL.match(x[2])][0]
            ins[code[0]].append((code[1], [case_name[t] + ":"]))
    for a, addr in pushes:
        rel, n, t = [x for x in at[a] if not LABEL.match(x[2])][0]
        U[n - 1] = U[n - 1].rstrip() + "\t\t; low half of " + str_name[addr]
    for addr in allstr:
        rel, n, t = [x for x in at[addr] if not LABEL.match(x[2])][0]
        owner = [c for c in strings if addr in strings[c].values()][0]
        lg = [k for k, v in strings[owner].items() if v == addr][0]
        what = ("the default text, all three languages" if owner == default else
                "message %d, language %d (%s)" % (first[owner], lg, {1: "English", 2: "German", 3: "French"}[lg]))
        ins[rel].append((n, ["\t; %s: read by HDAE5000_AcLanguageText1Proc" % what,
                             str_name[addr] + ":"]))
    # the case table: replace the lines emitting 0x2E5ADF-0x2E5B7F
    tl = sorted({n for a, rel, n, t in rows if rel == "hdae5000_data_tables.s" and 0x2E5ADF <= a < 0x2E5B80
                 and not LABEL.match(t)})
    if [a for a, rel, n, t in rows if rel == "hdae5000_data_tables.s" and n == tl[0]][0] != 0x2E5ADF:
        fail("table replacement does not start at 0x2E5ADF")
    new_tab = ["\t.balign 2, 0x00\t\t\t\t\t; pad after \"No Message\"",
               ";",
               "; HDAE5000_LangText_CaseTable (0x2E5AE0, 80 x u16): the message switch of",
               "; HDAE5000_AcLanguageText1Proc.  Entry i serves message i+1 (i <= 0x42) or",
               "; i+0x85 (i >= 0x43, the `sub wa,0x84` range); each value is an offset",
               "; from HDAE5000_AcLanguageText1Proc_Msg001, the first case, and the reader",
               "; jumps there (`jp T,XIX+WA`).  Three entries (messages 63, 204, 205) and",
               "; every out-of-range number share the _NoMessage case.  Evidence and the",
               "; extraction: scripts/converters/hdae5000_label_langtext.py.",
               ";",
               "HDAE5000_LangText_CaseTable:"]
    for i, o in enumerate(tab):
        new_tab.append("\t.short\t%s - HDAE5000_AcLanguageText1Proc_Msg001\t; message %d"
                       % (case_name[CASE0 + o], msgno(i)))
    for rel, L in (("hdae5000_ui_display.s", U), ("hdae5000_data_tables.s", D)):
        items = sorted(ins[rel], reverse=True)
        if rel == "hdae5000_data_tables.s":
            first_l, last_l = tl[0], tl[-1]
            # table first (it is below every string), then the string inserts
            L[first_l - 1:last_l] = new_tab
        for n, texts in items:
            L[n - 1:n - 1] = texts
    text = "\n".join(U)
    for old, new in renames.items():
        text = re.sub(re.escape(old) + r'\b', new, text)
    text = text.replace("lda xix, (0x2e5ae0:24)", "lda xix, (HDAE5000_LangText_CaseTable:24)", 1)
    text = text.replace("lda xix, (0x28b6dc:24)", "lda xix, (HDAE5000_AcLanguageText1Proc_Msg001:24)", 1)
    open(os.path.join(hlm.HDAE, "hdae5000_ui_display.s"), "w", encoding="latin-1").write(text)
    open(os.path.join(hlm.HDAE, "hdae5000_data_tables.s"), "w", encoding="latin-1").write("\n".join(D))
    hlm.build_map()
    print("applied; relinked mirror byte-identical (renamed %s)" % renames)


if __name__ == "__main__":
    main("--apply" in sys.argv[1:])
