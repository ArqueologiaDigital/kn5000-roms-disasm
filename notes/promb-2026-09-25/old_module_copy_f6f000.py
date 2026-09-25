#!/usr/bin/env python3
r"""prom_b 0xF6F000-0xF6F3FF is an older build's copy of the module whose live copy is 0xF7AA00-0xF7ADFF.

QUESTION THIS ANSWERS
    After sub_F6EC6A's last instruction the source has 865 bytes of 0x0E fill
    (0xF6EC9F-0xF6EFFF) and then, at the 4 KB boundary 0xF6F000, 1,024 bytes it
    framed as more of sub_F6EC6A (structural labels `sub_F6EC6A_Join3` ...),
    two routines `sub_F6F05E` / `sub_F6F13F` ("Unknown: what the routine is
    FOR") and 612 bytes of `Data_F6F19C` ("Unknown: everything about it except
    its bytes").  Nothing outside those 1,024 bytes names any address in them.

    They are byte-for-byte the module at 0xF7AA00-0xF7ADFF -- the one this
    build enters through the routine-directory slots T_F428B0.. (sub_F7AA00,
    sub_F7AA02, sub_F7AA29, SongStore_LoadSongHeaderToDisplay, sub_F7AB3F,
    sub_F7AB9C, ...) -- except at nine bytes, and those are exactly what
    RELOCATION changes:
      * four `call` operands inside the block (to SongStore_LoadSongHeaderToDisplay
        and sub_F7AB3F) that read the live target - 0xBA00;
      * one `calr` at 0xF6F3E4 to a routine OUTSIDE the block, whose
        displacement differs: the old copy calls 0xF7127B where the live one
        calls sub_F7CCDB = 0xF7127B + 0xBA60 -- that routine moved 0x60 further.
    Branches inside the block are relative and identical.  So this is the module
    as an EARLIER BUILD placed it, 0xBA00 lower: the same phenomenon as
    0xF0ED50-0xF0EFFF and 0xF17A5F-0xF17BFF (stale_dl_tables_f0ed50.py,
    stale_value_glyphs_f17a5f.py).  This build's code resumes at 0xF6F400
    (sub_F6F400, a directory target), which cuts the old copy's last
    instruction -- `and (0x2075),0xf6`, 5 bytes -- after 4.

    With --apply this script
      * converts `Data_F6F19C` to code, mirroring the live copy's own lines for
        0xF7AB9C-0xF7ADFB (so the instruction boundaries are the live ones -
        0xBA00; the gate proves the bytes) and leaves 0xF6F3FC-0xF6F3FF as the
        4 `.byte`s of the cut instruction;
      * names the old copy's labels after their live twins: `OldCopy_<live
        label>` for an entry point, `OldCopy_<live address>` for a branch
        label (the live copy's own branch labels are parented to
        BStore_AppendBytes, a routine BEFORE its fill, so their names are not
        carried over);
      * spells a branch to OUTSIDE the block as `<live target> - <delta>`
        (`calr sub_F7CCDB - 0xBA60`, `jr nz, sub_F7ADDC_Return - 0xBA00`) -- in
        this build those addresses hold unrelated code;
      * answers the two routines' "what the routine is FOR" lines, and corrects
        sub_F6EC6A's header, whose `Calls:`/`Touches:` counted this copy.

RUN
    python3 notes/promb-2026-09-25/old_module_copy_f6f000.py            # checks
    python3 notes/promb-2026-09-25/old_module_copy_f6f000.py --apply    # write the source
    make gate-wsa1
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, "wsa1", "prom_b", "wsa1_prom_b.s")
ROMB = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_b.ic13")
ROMA = os.path.join(ROOT, "wsa1", "original_ROMs", "wsa1_prom_a.ic12")
BASE = 0xF00000
D = 0xBA00
OLO, OHI = 0xF6F000, 0xF6F400
LLO, LHI = OLO + D, OHI + D
DATA = 0xF6F19C
STRUCT = re.compile(r'_(Skip|Join|Loop|Sub|Return|Epilogue|Entry|Helper|Arm)\d*$')
FAIL = []


def check(msg, cond):
    print("  %-4s %s" % ("ok" if cond else "FAIL", msg))
    if not cond:
        FAIL.append(msg)


def parse(L):
    """[(line_index, addr)] of instruction/data lines; {label: addr}; {addr: [labels]}."""
    rows, lab_at, pending = [], {}, []
    for i, t in enumerate(L):
        m = re.match(r'^([A-Za-z_]\w*):', t)
        if m:
            pending.append(m.group(1))
            continue
        m = re.search(r';\s*([0-9A-F]{6})\b', t)
        if m and t.startswith("\t") and not t.startswith("\t;"):
            a = int(m.group(1), 16)
            rows.append((i, a))
            for p in pending:
                lab_at[p] = a
            pending = []
    at = {}
    for k, a in lab_at.items():
        at.setdefault(a, []).append(k)
    return rows, lab_at, at


def target_of(b, a):
    """Branch/call target of the instruction at a, from the ROM bytes (None if not one)."""
    o = b[a - BASE]
    if o in (0x1D, 0x1B):                                   # call / jp imm24
        return int.from_bytes(b[a - BASE + 1:a - BASE + 4], "little")
    if o == 0x1E:                                           # calr d16
        return (a + 3 + int.from_bytes(b[a - BASE + 1:a - BASE + 3], "little", signed=True)) & 0xFFFFFF
    if 0x60 <= o <= 0x6F:                                   # jr cc,d8
        return (a + 2 + int.from_bytes(b[a - BASE + 1:a - BASE + 2], "little", signed=True)) & 0xFFFFFF
    if 0x70 <= o <= 0x7F:                                   # jrl cc,d16
        return (a + 3 + int.from_bytes(b[a - BASE + 1:a - BASE + 3], "little", signed=True)) & 0xFFFFFF
    return None


def derive():
    b = open(ROMB, "rb").read()
    ba = open(ROMA, "rb").read()
    at = lambda a, n: b[a - BASE:a - BASE + n]
    txt = open(SRC, "rb").read().decode("latin-1")
    L = txt.split("\n")
    rows, lab_at, labs_at = parse(L)
    addrs = sorted(set(a for _, a in rows))
    live_ins = [a for a in addrs if LLO <= a < LHI]
    old_ins = [a for a in addrs if OLO <= a < DATA]
    check("the existing old-copy instruction lines 0xF6F000-0xF6F19B start exactly where the live "
          "copy's do, - 0xBA00 (%d lines)" % len(old_ins),
          [a + D for a in old_ins] == [a for a in live_ins if a < DATA + D])
    diffs = [a for a in range(OLO, OHI) if at(a, 1) != at(a + D, 1)]
    check("0xF6F000-0xF6F3FF differs from 0xF7AA00-0xF7ADFF at %d bytes" % len(diffs), len(diffs) == 9)
    # every differing byte lies in a call/calr operand
    owners = {}
    for x in diffs:
        own = max(a for a in live_ins if a <= x + D) - D
        owners.setdefault(own, []).append(x)
    rel = {}
    for own in owners:
        lt, ot = target_of(b, own + D), target_of(b, own)
        rel[own] = (lt, ot)
    inblock = [o for o, (lt, ot) in rel.items() if LLO <= lt < LHI]
    outside = [o for o, (lt, ot) in rel.items() if not LLO <= lt < LHI]
    check("  %d of the differing instructions are `call`s inside the block whose old target = live "
          "target - 0xBA00" % len(inblock),
          len(inblock) == 4 and all(at(o, 1) == b"\x1d" and rel[o][1] == rel[o][0] - D for o in inblock))
    check("  the other is `calr` at 0xF6F3E4: old target 0xF7127B, live target 0xF7CCDB = old + 0xBA60",
          outside == [0xF6F3E4] and rel[0xF6F3E4] == (0xF7CCDB, 0xF7127B))
    check("0xF6F000 is 4 KB aligned and 0xF6F400 1 KB aligned; the old block is exactly 1,024 bytes",
          OLO % 0x1000 == 0 and OHI % 0x400 == 0)
    check("0x0E fill before both copies: 0xF6EC9F-0xF6EFFF and 0xF7A7EB-0xF7A9FF",
          set(at(0xF6EC9F, OLO - 0xF6EC9F)) == {0x0E} and set(at(0xF7A7EB, LLO - 0xF7A7EB)) == {0x0E})
    # the live copy is entered through the routine directory; the old one is named by nothing
    slots = [0xF428B0 + 4 * k for k in range(0, 60)]
    live_ent = sorted(set(int.from_bytes(at(s + 1, 3), "little") for s in slots
                          if at(s, 1) == b"\x1b" and LLO <= int.from_bytes(at(s + 1, 3), "little") < LHI))
    check("%d routine-directory `jp` slots at 0xF428B0.. enter the LIVE copy (first 0x%06X)"
          % (len(live_ent), live_ent[0] if live_ent else 0), len(live_ent) >= 10)
    ext = []
    for img, r, base in (("prom_b", b, BASE), ("prom_a", ba, 0xF80000)):
        for i in range(len(r) - 4):
            v3 = int.from_bytes(r[i:i + 3], "little")
            if OLO <= v3 < OHI and not (img == "prom_b" and OLO <= base + i < OHI):
                if (i >= 1 and r[i - 1] in (0x1D, 0x1B)) or (r[i + 3] == 0):
                    ext.append((img, base + i, v3))
    check("no `call`/`jp` imm24 and no 32-bit word outside the block names an address in it %s"
          % ext[:4], not ext)
    old_labels = [k for k, a in lab_at.items() if OLO <= a < OHI]
    used_out = []
    for i, t in enumerate(L):
        m = re.search(r';\s*([0-9A-F]{6})\b', t)
        if not (t.startswith("\t") and m):
            continue
        a = int(m.group(1), 16)
        if OLO <= a < OHI:
            continue
        for k in old_labels:
            if re.search(r'\b%s\b' % k, t.split(";")[0]):
                used_out.append((a, k))
    check("no instruction outside the block uses a label defined inside it %s" % used_out[:4],
          not used_out)
    last = max(a for a in live_ins if a < LHI)
    nxt = min(a for a in addrs if a > last)
    lt = L[[i for i, a in rows if a == last][0]]
    check("the live instruction at 0x%06X (`%s`) ends at 0x%06X, one byte past the block, so the old copy's "
          "last %d bytes are a cut instruction" % (last, lt.split(";")[-1].strip()[8:], nxt - 1, LHI - last),
          last == 0xF7ADFC and nxt == 0xF7AE01 and "and (0x2075),0xf6" in lt)
    return dict(b=b, L=L, rows=rows, lab_at=lab_at, labs_at=labs_at, live_ins=live_ins, rel=rel,
                live_ent=live_ent, old_labels=old_labels)


def oldname(live_label, live_addr):
    if STRUCT.search(live_label):
        return "OldCopy_%06X" % live_addr
    return "OldCopy_" + live_label


BANNER = r"""; ==========================================================================
; 0xF6F000-0xF6F3FF -- AN OLDER BUILD'S COPY OF THE MODULE AT 0xF7AA00-0xF7ADFF
;   Byte for byte the live module this build enters through the routine-
;   directory slots T_F428B0.. (sub_F7AA00, sub_F7AA02, sub_F7AA29,
;   SongStore_LoadSongHeaderToDisplay, sub_F7AB3F, sub_F7AB9C ...), 0xBA00
;   lower, except at the nine bytes relocation changes: four `call`s inside
;   the block read the live target - 0xBA00, and the `calr` at 0xF6F3E4 calls
;   0xF7127B where the live copy calls sub_F7CCDB (0xBA60 higher -- that
;   routine moved 0x60 further between the builds).  It starts on the 4 KB
;   boundary after 0x0E fill (the live copy is preceded by fill too) and ends
;   on the 1 KB boundary 0xF6F400, where this build's sub_F6F400 cuts the old
;   copy's last instruction after 4 of its 5 bytes.  Nothing outside these
;   1,024 bytes names an address in them: DEAD in this build.  The same
;   phenomenon as OldBuild_DLHandlerTables_Tail (0xF0ED50) and
;   OldBuild2_ValueGlyph_* (0xF17A5F).
;   Labels are `OldCopy_<live label>` for an entry, `OldCopy_<live address>`
;   for a branch target; a branch to outside the block is spelled
;   `<live target> - <delta>`, since what sits at the old address now is
;   unrelated.  notes/promb-2026-09-25/old_module_copy_f6f000.py checks all of
;   it.
; =========================================================================="""


def apply(d):
    b, L, lab_at, labs_at = d["b"], d["L"], d["lab_at"], d["labs_at"]
    live_ins = d["live_ins"]
    # label names for every old address that a live label names
    newname = {}                                   # old addr -> new label
    for a in sorted(labs_at):
        if LLO <= a < LHI:
            ls = labs_at[a]
            ent = [x for x in ls if not STRUCT.search(x)]
            newname[a - D] = oldname(ent[0] if ent else ls[0], a)
    # 1. mirror the live lines for 0xF7AB9C-0xF7ADFB
    li = {a: i for i, a in d["rows"]}
    mirrored = []
    for a in [x for x in live_ins if DATA + D <= x < 0xF7ADFC]:
        if a - D in newname:
            mirrored.append("%s:" % newname[a - D])
        t = L[li[a]]
        code, _, com = t.partition(";")
        m = re.match(r'\s*([0-9A-F]{6})(\s.*)$', com)
        assert m, t
        tail = m.group(2)
        tgt = target_of(b, a)
        otg = target_of(b, a - D)
        for lab in re.findall(r'\b[A-Za-z_]\w*\b', code):
            if lab not in lab_at:
                continue
            la = lab_at[lab]
            if LLO <= la < LHI:
                code = re.sub(r'\b%s\b' % lab, newname[la - D], code)
            elif tgt is not None and la == tgt and otg != tgt:
                code = re.sub(r'\b%s\b' % lab, "%s - 0x%X" % (lab, tgt - otg), code)
        tail = re.sub(r'0x([0-9a-f]{6})\b',
                      lambda mm: "0x%06x" % (int(mm.group(1), 16) - D
                                             if LLO <= int(mm.group(1), 16) < LHI else
                                             (otg if tgt == int(mm.group(1), 16) and otg is not None
                                              else int(mm.group(1), 16))), tail)
        mirrored.append("%s; %06X%s" % (code, a - D, tail))
    cut = b[0xF6F3FC - BASE:0xF6F400 - BASE]
    mirrored.append("\t.byte\t%s\t; F6F3FC  the first 4 of the 5 bytes of `and (0x2075),0xf6` "
                    "(live 0xF7ADFC); this build's sub_F6F400 begins at 0xF6F400"
                    % ", ".join("0x%02X" % x for x in cut))
    # 2. replace Data_F6F19C (header + rows) by the mirrored code
    i = [k for k, t in enumerate(L) if t.startswith("Data_F6F19C:")][0]
    h = i
    while L[h - 1].startswith(";"):
        h -= 1
    e = i + 1
    while L[e].startswith("\t.byte"):
        e += 1
    hdr = ["; ⚠ ANSWERED 2026-09-25 (the \"nothing but its bytes\" verdict that stood",
           ";   here): 0xF6F19C-0xF6F3FF is CODE, the older build's copy of",
           ";   0xF7AB9C-0xF7ADFF -- see the banner at 0xF6F000.  The label",
           ";   `Data_F6F19C` is retired; the lines below mirror the live copy's."]
    hdr = [x.encode("utf-8").decode("latin-1") for x in hdr]
    old_hdr = L[h:i]
    u = [k for k, t in enumerate(old_hdr) if t == "; Unknown: everything about it except its bytes."]
    assert len(u) == 1
    old_hdr[u[0]:u[0] + 1] = hdr
    L = L[:h] + old_hdr + mirrored + L[e:]
    # 3. rename / add labels in 0xF6F000-0xF6F19B, and the banner
    rows, lab_at2, labs_at2 = parse(L)
    ren = {}
    for k, a in lab_at2.items():
        if OLO <= a < DATA and a in newname and k != newname[a]:
            ren[k] = newname[a]
    have = set(v for k, v in ren.items())
    out = []
    for idx, t in enumerate(L):
        m = re.search(r';\s*([0-9A-F]{6})\b', t)
        if m and t.startswith("\t") and not t.startswith("\t;"):
            a = int(m.group(1), 16)
            if OLO <= a < DATA and a in newname and newname[a] not in have:
                prev = out[-1] if out else ""
                if not prev.startswith(newname[a] + ":"):
                    out.append("%s:" % newname[a])
                    have.add(newname[a])
        out.append(t)
    L = out
    j = [k for k, t in enumerate(L) if re.search(r';\s*F6F000\s', t) and t.startswith("\t")][0]
    while re.match(r'^[A-Za-z_]\w*:', L[j - 1]):
        j -= 1
    L[j:j] = [x.encode("utf-8").decode("latin-1") for x in BANNER.split("\n")]
    txt = "\n".join(L)
    for k, v in sorted(ren.items(), key=lambda kv: -len(kv[0])):
        txt = re.sub(r'\b%s\b' % k, v, txt)
    # 4. the two routines' open question, and sub_F6EC6A's header
    for old, live in (("OldCopy_SongStore_LoadSongHeaderToDisplay",
                       "SongStore_LoadSongHeaderToDisplay\n;   (0xF7AA5E); was `sub_F6F05E`"),
                      ("OldCopy_sub_F7AB3F", "sub_F7AB3F\n;   (0xF7AB3F); was `sub_F6F13F`")):
        pat = (r'(; %s\n(?:;.*\n)*?)'
               r'; Unknown: what the routine is FOR\.  Left as sub_XXXXXX with the gap stated,\n'
               r';          per this tree\'s rule that a stated gap beats a plausible guess\.\n' % old)
        rep = ("; ⚠ ANSWERED 2026-09-25: the older build's copy of %s, a name that\n"
               ";   was the address.  See the banner at 0xF6F000: its callers are inside\n"
               ";   that copy, which is dead here.\n"
               % live).encode("utf-8").decode("latin-1")
        txt, n = re.subn(pat, lambda m: m.group(1) + rep, txt)
        assert n == 1, old
    pat = r'(; sub_F6EC6A\n(?:;.*\n)*?)(; Evidence \(PROVEN\))'
    corr = ("; ⚠ CORRECTED 2026-09-25: this routine ends with the `ret` at 0xF6EC9F (the\n"
            ";   first byte of the 0x0E fill that its two jumps target).  The `Calls:`\n"
            ";   and part of the `Touches:` above counted 0xF6F000-0xF6F3FF, which is an\n"
            ";   older build's copy of another module (banner there).\n")
    txt, n = re.subn(pat, lambda m: m.group(1) + corr.encode("utf-8").decode("latin-1") + m.group(2), txt)
    assert n == 1
    open(SRC, "wb").write(txt.encode("latin-1"))
    print("wrote", SRC, "renamed", len(ren))
    return ren


def main():
    d = derive()
    if FAIL:
        print("\nVERDICT: FAIL (%d)" % len(FAIL))
        return 1
    if "--apply" in sys.argv:
        apply(d)
    print("\nVERDICT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
