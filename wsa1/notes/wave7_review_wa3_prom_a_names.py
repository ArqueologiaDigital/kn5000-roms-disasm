#!/usr/bin/env python3
"""wave 7 round 3, lane REVIEW-WA3 -- are prom_a's twenty round-9 names carried
by their evidence?

QUESTION THIS SCRIPT ANSWERS
    For each of the twenty routines the prom_a lane promoted out of sub_XXXXXX
    this round, does the Evidence: line's arithmetic reproduce?  Every number
    quoted in the review report is computed here, so a later reader can rerun
    it instead of trusting the prose.

    Run:  python3 notes/wave7_review_wa3_prom_a_names.py
          python3 notes/wave7_review_wa3_prom_a_names.py --selftest

WHAT IT READS
    prom_a/wsa1_prom_a.s and prom_b/wsa1_prom_b.s -- the LISTINGS, not the ROM
    images.  Every instruction line carries `; ADDR  bytes`, so the listing is
    a sufficient oracle for "is this address an instruction start" and for
    resolving `calr` displacements by hand.

WHAT IT FOUND (2026-08-30, working tree, gate green)
    17 of 20 names hold.  Three headers carry a number the listing refutes:
      * Ring600C1E_InitIfPanelMode79 says the listing tests (0x207A) against
        FIVE values.  It tests TWENTY-FOUR, at 57 sites.  (The name itself is
        fine: the 0x79 gate is exact, and `mode` for (0x207A) is carried by the
        Msg0716 module banner -- just not by the header this one cites.)
      * SoundCode_FromGroupMember_ByteGroup says the RAM arm compares 127
        entries.  The loop compares 128 (offsets 0,2,..,254).
      * SoundGroup_MaxMemberIndex_GetToneCopy says its ladder has FOUR fewer
        tests than SoundGroup_MaxMemberIndex_Get's.  11 comparisons vs 6 is
        five fewer; four is only right if `cps w,0x01` is not counted, and no
        stated rule excludes it.
    None of the three touches the byte gate; all three are gate-clean prose,
    which is the only kind of error this tree has ever shipped.
"""
import re, sys, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
PA = image_path(ROOT, "prom_a/wsa1_prom_a.s")
PB = image_path(ROOT, "prom_b/wsa1_prom_b.s")

INS = re.compile(r'^\t(.*?)\s*;\s*([0-9A-F]{6})\s+((?:[0-9a-f]{2} ?)+?)(?:\s{2,}.*)?$')
LAB = re.compile(r'^([A-Za-z_.][A-Za-z0-9_.]*):')


def load(path):
    """-> (rows, labaddr).  rows = [(addr, text, [bytes], enclosing_top_label)]."""
    rows, labaddr, pend, top = [], {}, [], None
    for ln in open(path, encoding='utf-8', errors='replace'):
        ln = ln.rstrip('\n')
        m = LAB.match(ln)
        if m:
            pend.append(m.group(1))
            if not m.group(1).startswith('.'):
                top = m.group(1)
            continue
        m = INS.match(ln)
        if m:
            a = int(m.group(2), 16)
            for p in pend:
                labaddr.setdefault(p, a)
            pend = []
            rows.append((a, m.group(1).strip(), m.group(3).split(), top))
    return rows, labaddr


def calr_target(a, b):
    """`calr d16` (opcode 0x1e) -> absolute target.  3-byte instruction."""
    if not b or b[0] != '1e' or len(b) < 3:
        return None
    d = int(b[2], 16) * 256 + int(b[1], 16)
    if d >= 0x8000:
        d -= 0x10000
    return (a + 3 + d) & 0xFFFFFF


# ---------------------------------------------------------------- the checks
def q_207a_values(rows):
    """How many DISTINCT immediates does prom_a compare (0x207A) against?
    Ring600C1E_InitIfPanelMode79's header names five: 0x0D 0x13 0x79 0xB7 0xDB."""
    vals = set()
    n = 0
    for a, t, b, o in rows:
        m = re.search(r'cp_mi8\s+\w+,\s*0x207a,\s*0x([0-9a-f]{2})', t)
        if m:
            vals.add(int(m.group(1), 16))
            n += 1
    return sorted(vals), n


def q_bytegroup_entries():
    """The .LFC243B loop: WA=0; compare (XIX+WA); WA+=2; loop while WA<=0xFE.
    `jr ule` is opcode 0x63 = 0x60|cc3, ULE = C or Z, so the bound is inclusive."""
    wa, n = 0, 0
    while True:
        n += 1
        wa = (wa + 2) & 0xFFFF
        if not wa <= 0x00FE:
            break
    return n


def q_ladder_tests(rows, lo, hi):
    """Count comparison instructions against W in [lo,hi]: `cp W,imm` and `cps w,imm`."""
    cp = cps = 0
    for a, t, b, o in rows:
        if lo <= a <= hi:
            if re.match(r'^cp W,0x', t):
                cp += 1
            elif re.match(r'^cps w, ?0x', t):
                cps += 1
    return cp, cps


def q_ring_init_slots(rows_b):
    """Every T_Ring*_Init slot in prom_b -> the SLOT's own address (not its jp
    target).  A caller in prom_a reaches the ring through the slot, so it is
    the slot address that appears in `call 0xF41xxx`.  prom_b writes the slot
    address in the line comment: `T_X: jp 0xF8433C  ; F41CE0 (was T_F41CE0)`."""
    out = {}
    for ln in open(PB, encoding='utf-8', errors='replace'):
        m = re.match(r'^(T_Ring([0-9A-F]+)_Init):\s*jp 0x([0-9A-F]+)\s*;\s*([0-9A-F]{6})', ln)
        if m:
            out[m.group(1)] = int(m.group(4), 16)
    return out


def q_calls_from(rows, lo, hi):
    """Absolute `call 0xNNNNNN` (opcode 0x1d) targets emitted in [lo,hi], in order."""
    out = []
    for a, t, b, o in rows:
        if lo <= a <= hi and b and b[0] == '1d' and len(b) >= 4:
            out.append((int(b[3], 16) << 16) | (int(b[2], 16) << 8) | int(b[1], 16))
    return out


def q_callers(rows, name):
    return [(a, o) for a, t, b, o in rows
            if re.match(r'^(call|calr|jp|jr)\b', t) and name in t]


def q_slot_calls(rows, slot):
    return [a for a, t, b, o in rows if ('0x%06x' % slot) in t.lower()]


def q_imm_sites(rows, imm):
    return [(a, o) for a, t, b, o in rows if ('0x%08x' % imm) in t.lower()]


def main(argv):
    rows_a, lab_a = load(PA)
    rows_b, lab_b = load(PB)
    R = []

    def say(fmt, *a):
        print(fmt % a if a else fmt)

    say("prom_a round-9 name review -- every number the report quotes\n")

    vals, n = q_207a_values(rows_a)
    named = [0x0D, 0x13, 0x79, 0xB7, 0xDB]
    say("1. (0x207A) compare-immediates in prom_a")
    say("     distinct values: %d at %d sites", len(vals), n)
    say("     values: %s", " ".join("0x%02X" % v for v in vals))
    say("     the header names %d: %s", len(named), " ".join("0x%02X" % v for v in named))
    say("     OMITTED by the header: %s",
        " ".join("0x%02X" % v for v in vals if v not in named))
    say("     -> header claim REFUTED\n" if len(vals) != len(named) else "     -> holds\n")
    R.append(("207a_distinct", len(vals)))

    e = q_bytegroup_entries()
    say("2. SoundCode_FromGroupMember_ByteGroup RAM-arm loop .LFC243B")
    say("     entries compared: %d   (header says 127)", e)
    say("     -> header claim REFUTED (off by one)\n" if e != 127 else "     -> holds\n")
    R.append(("bytegroup_entries", e))

    g_cp, g_cps = q_ladder_tests(rows_a, 0xFC2226, 0xFC225A)
    t_cp, t_cps = q_ladder_tests(rows_a, 0xFC2285, 0xFC229E)
    say("3. the two selector ladders")
    say("     MaxMemberIndex_Get      : %d `cp W,` + %d `cps w,` = %d comparisons",
        g_cp, g_cps, g_cp + g_cps)
    say("     ...GetToneCopy          : %d `cp W,` + %d `cps w,` = %d comparisons",
        t_cp, t_cps, t_cp + t_cps)
    say("     difference: %d counting every comparison, %d counting only `cp W,`",
        (g_cp + g_cps) - (t_cp + t_cps), g_cp - t_cp)
    say("     the header says FOUR fewer -> right only under the second rule,")
    say("     and no stated rule excludes `cps w,0x01`\n")
    R.append(("ladder_diff_all", (g_cp + g_cps) - (t_cp + t_cps)))
    R.append(("ladder_diff_cponly", g_cp - t_cp))

    slots = q_ring_init_slots(rows_b)
    all14 = q_calls_from(rows_a, 0xF825E5, 0xF82619)
    ten = q_calls_from(rows_a, 0xFE1D29, 0xFE1D4D)
    inv = {v: k for k, v in slots.items()}
    say("4. the two ring-init runs")
    say("     T_Ring*_Init slots in prom_b: %d", len(slots))
    say("     Ring_InitAllFourteen calls  : %d distinct, all Init slots: %s",
        len(set(all14)), set(all14) <= set(slots.values()))
    say("     Ring_InitTenOfFourteen calls: %d distinct", len(set(ten)))
    missing = sorted(inv[v] for v in set(slots.values()) - set(ten))
    say("     the four it omits: %s", ", ".join(missing))
    say("     header's four    : T_Ring60000C_Init, T_Ring601B64_Init, "
        "T_Ring60480A_Init, T_Ring608A0A_Init")
    say("     -> %s\n", "MATCH" if missing == sorted(
        ["T_Ring60000C_Init", "T_Ring601B64_Init", "T_Ring60480A_Init",
         "T_Ring608A0A_Init"]) else "MISMATCH")
    R.append(("init14", len(set(all14))))
    R.append(("init10", len(set(ten))))

    say("5. call-site counts the headers quote")
    for nm, want in [("Ring60000C_GetWithRetry", 7),
                     ("SoundCode_FromGroupMember_ModeOffset", 1),
                     ("SoundCode_FromGroupMember_ByteGroup", 1),
                     ("Ring601432_SpinUntilEmpty", 2),
                     ("Ring600C1E_InitIfPanelMode79", 4),
                     ("Ring601646_InitIrqMasked", 1),
                     ("DLB_Handler_StringTable_Veneer", 7),
                     ("DLB_Handler_Decimal_Veneer", 10),
                     ("RecordNameSource_Select", 1),
                     ("Ring_InitAllFourteen", 1)]:
        got = len(q_callers(rows_a, nm))
        say("     %-38s claimed %2d  actual %2d  %s", nm, want, got,
            "ok" if got == want else "MISMATCH")
        R.append((nm, got))
    for slot, nm, want in [(0xF4101C, "T_F4101C  (MaxMemberIndex_Get)", 11),
                           (0xF41034, "T_F41034  (...GetToneCopy)", 7)]:
        got = len(q_slot_calls(rows_a, slot))
        say("     %-38s claimed %2d  actual %2d  %s", nm, want, got,
            "ok" if got == want else "MISMATCH")
        R.append((nm, got))
    say("")

    say("6. the lane's correction to prom_b's ToneGroupsCopy header")
    s = q_imm_sites(rows_a, 0x00F06EE4)
    say("     0x00F06EE4 loaded in prom_a at: %s",
        ", ".join("0x%06X in %s" % (a, o) for a, o in s))
    say("     prom_b's header says sub_FC2222 loads it; sub_FC2222 ends 0xFC2281")
    say("     -> the correction is CORRECT\n")
    R.append(("f06ee4_sites", len(s)))

    say("7. the three cited `calr` veneer sites, displacements resolved")
    for a in (0xFE0A29, 0xFE0A59, 0xFE201F, 0xFE2022):
        r = [x for x in rows_a if x[0] == a][0]
        t = calr_target(a, r[2])
        nm = {v: k for k, v in lab_a.items()}.get(t, "(no label)")
        say("     %06X -> %06X  %-32s in %s", a, t, nm, r[3])
    say("")

    say("8. is (0x207A) EVER called a mode for THAT cell?")
    q = [l for l in open(PA, encoding='utf-8', errors='replace')
         if l.startswith(';') and '0x207A' in l and 'mode' in l.lower()]
    say("     prom_a prose lines pairing 0x207A with the word 'mode': %d", len(q))
    for l in q[:4]:
        say("       %s", l.rstrip())
    say("     VERDICT: the morpheme IS carried, but NOT by the citation chosen.")
    say("       - the header cites PanelState_Update207A, whose 'the mode' names")
    say("         the (0x2078)/(0x2079) test -- a DIFFERENT cell pair;")
    say("       - the real support is prom_a's Msg0716 module banner, which says")
    say("         `0x207A  a mode byte, named at 3 sites, all three inside")
    say("         Msg0716_BiasOpcodeByMode` -- an existing label built on the")
    say("         same reading.  So this is a weak-citation nit, NOT an")
    say("         invented concept of the 'Home' kind.\n")
    R.append(("207a_mode_prose", len(q)))
    return R


def selftest():
    rows_a, lab_a = load(PA)
    rows_b, lab_b = load(PB)
    ok = fail = 0

    def chk(desc, cond, extra=""):
        nonlocal ok, fail
        if cond:
            ok += 1
            print("  ok    %-72s %s" % (desc, extra))
        else:
            fail += 1
            print("  FAIL  %-72s %s" % (desc, extra))

    vals, n = q_207a_values(rows_a)
    chk("(0x207A) is compared against more than the five values the header names",
        len(vals) > 5, "%d values, %d sites" % (len(vals), n))
    chk("...and 0x79, the value the name uses, IS among them", 0x79 in vals)
    chk("the ByteGroup loop compares 128 entries, not the 127 the header says",
        q_bytegroup_entries() == 128, str(q_bytegroup_entries()))
    g = q_ladder_tests(rows_a, 0xFC2226, 0xFC225A)
    t = q_ladder_tests(rows_a, 0xFC2285, 0xFC229E)
    chk("Get's ladder has 11 comparisons and GetToneCopy's 6",
        sum(g) == 11 and sum(t) == 6, "%s vs %s" % (g, t))
    slots = q_ring_init_slots(rows_b)
    chk("prom_b has exactly fourteen T_Ring*_Init slots", len(slots) == 14, len(slots))
    a14 = set(q_calls_from(rows_a, 0xF825E5, 0xF82619))
    chk("Ring_InitAllFourteen calls all fourteen, each once",
        a14 == set(slots.values()) and
        len(q_calls_from(rows_a, 0xF825E5, 0xF82619)) == 14)
    t10 = set(q_calls_from(rows_a, 0xFE1D29, 0xFE1D4D))
    chk("Ring_InitTenOfFourteen calls ten of them", len(t10) == 10, len(t10))
    chk("the four omitted are the four the header names",
        sorted({v: k for k, v in slots.items()}[v]
               for v in set(slots.values()) - t10) ==
        ["T_Ring60000C_Init", "T_Ring601B64_Init", "T_Ring60480A_Init",
         "T_Ring608A0A_Init"])
    chk("0x00F06EE4 is loaded exactly once in prom_a", len(q_imm_sites(rows_a, 0x00F06EE4)) == 1)
    chk("...and that site is inside SoundGroup_MaxMemberIndex_GetToneCopy",
        q_imm_sites(rows_a, 0x00F06EE4)[0][1] == "SoundGroup_MaxMemberIndex_GetToneCopy")
    inv = {v: k for k, v in lab_a.items()}
    for a, want in [(0xFE0A29, "Disk_FormatSelectedMedia_Veneer"),
                    (0xFE0A59, "Disk_FormatSelectedMedia_Veneer"),
                    (0xFE201F, "MidiIn_ServiceDeferred_Veneer"),
                    (0xFE2022, "UiEventList_Publish_Veneer")]:
        r = [x for x in rows_a if x[0] == a][0]
        chk("calr at 0x%06X resolves to %s" % (a, want),
            inv.get(calr_target(a, r[2])) == want)
    # LAST element of the twenty, in address order -- the brief requires testing it
    last = "DLB_Handler_Decimal_Veneer"
    chk("the LAST round-9 name in address order (%s) exists" % last, last in lab_a,
        "0x%06X" % lab_a.get(last, 0))
    chk("...and it has the 10 call sites its header claims",
        len(q_callers(rows_a, last)) == 10)
    chk("...and it clears (0x2540) at 0xFF766E as its header says",
        any(a == 0xFF766E and '0x2540' in t for a, t, b, o in rows_a))
    chk("...and (0x2540) IS established as a layer selector in prom_b prose",
        any('(0x2540) IS A LAYER SELECTOR' in l
            for l in open(PB, encoding='utf-8', errors='replace')))
    # the three IsEmpty routines return 0 when the ring IS empty -- the polarity
    # three of the twenty names depend on
    for nm, rd, wr in [("Ring601850_IsEmpty", 0x601848, 0x60184C),
                       ("Ring601432_IsEmpty", 0x60142A, 0x60142E),
                       ("Ring608A0A_IsEmpty", 0x608A02, 0x608A06)]:
        base = lab_a[nm]
        body = [t for a, t, b, o in rows_a if base <= a < base + 0x20]
        chk("%s: WA:=0, then 0xFFFF only when the cursors DIFFER" % nm,
            any('ldw wa, 0x00' in x for x in body) and
            any('ldw wa, 0xffff' in x for x in body) and
            any('0x%06x' % wr in x for x in body) and
            any('0x%06x' % rd in x for x in body))
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    main(sys.argv)
