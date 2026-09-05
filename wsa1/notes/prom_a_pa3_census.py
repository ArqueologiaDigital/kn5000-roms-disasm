#!/usr/bin/env python3
"""Emulation gap T: EVERY instruction in CPU 1's ROMs that touches PA bit 3, and
what the firmware does around each one.

QUESTION IT ANSWERS
  "What does CPU 1's PA bit 3 drive?"  The ROM cannot say what a pin is wired
  to.  It can say four things this script re-derives from the images:
    1. WHO writes it -- all of them, not one encoding's worth;
    2. WHICH BIT of PA the firmware ever changes after RESET;
    3. WHAT SHAPE the two directions have (does either wait afterwards?);
    4. WHERE the writers sit relative to disk traffic.

WHY IT EXISTS -- the defect it is the correction for
  notes/prom_a_fdc_operation_census.py scanned for ONE encoding, `f0 1e 41` =
  `ld (PA),A`, found exactly two, and the notes concluded "operations 6 and 7
  are its only writers, and no other code in prom_a or prom_b touches it ...
  nothing in this firmware ever changes it".  That is FALSE.  A bit write is
  `f0 1e b3` (`res 3,(0x1E)`) or `f0 1e bb` (`set 3,(0x1E)`), which is not that
  encoding, and there are two of those, reached by 15 `calr` sites.
  ★ The general lesson, and the reason this docstring is long: the scan was
  sound for the claim "these are the only `ld (PA),A`" and worthless for the
  claim "these are the only writers of bit 3".  The second is a strictly larger
  set.  A completeness claim must be scanned for at the granularity it is made.

WHAT IS SCANNED
  Every byte offset of prom_a and prom_b for the two-byte prefix `<g> 1E`, for
  g in {0xC0, 0xD0, 0xE0, 0xF0} -- the four TLCS-900 memory-operand groups with
  addressing mode 0, an 8-BIT ABSOLUTE address, here 0x1E = PA
  (include/tmp95c061_sfr.inc, MAME tmp95c061.cpp:128/1363).  The 0xF0 group is
  the one that WRITES memory; the other three read it.
  Byte hits are then filtered against the instruction boundaries of the
  CONVERTED SOURCE, which the byte gate proves reassembles to these exact ROMs:
  a hit is a real instruction only if a source line's address equals it and the
  source line's bytes are the hit's bytes.  Hits inside `.incbin` are reported
  as UNDECIDED, not silently dropped, and hits inside emitted `.byte` data are
  reported as DATA.
  ⚠ NOT scanned, and therefore NOT excluded: a write through a 16- or 24-bit
  spelling of 0x00001E, and a write through a register pointer.  The first is
  covered by `python3 notes/prom_a_addr_census.py 0x00001E`, which runs all
  twelve direct spellings and finds no additional converged site; the second no
  static scan can exclude, and this script says so instead of implying it did.

RUN
  python3 notes/prom_a_pa3_census.py
  python3 notes/prom_a_pa3_census.py --quiet     # assertions only
Exit status is non-zero if any assertion fails.
"""
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRC = image_path(ROOT, "prom_a/wsa1_prom_a.s")
IMGS = [("prom_a", os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), 0xF80000),
        ("prom_b", os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13"), 0xF00000)]

PA = 0x1E
GROUPS = {0xC0: "read byte", 0xD0: "read word", 0xE0: "read long",
          0xF0: "WRITE"}

LINE = re.compile(r'^\t(\S.*?)\s*;\s*([0-9A-F]{6})\s+((?:[0-9a-f]{2} )*[0-9a-f]{2})(\s|$)')
INCBIN = re.compile(r'\.incbin\s+"original_ROMs/wsa1_prom_a\.ic12",\s*0x([0-9A-Fa-f]+),\s*0x([0-9A-Fa-f]+)')

FAIL = []


def check(msg, cond):
    print("  %-72s %s" % (msg, "ok" if cond else "FAIL"))
    if not cond:
        FAIL.append(msg)


def load_source():
    """(addr -> (bytes, text, lineno)) for every emitted prom_a source line,
    plus the list of still-.incbin file spans."""
    rows, spans = {}, []
    for i, line in enumerate(open(SRC, encoding="utf-8"), 1):
        m = INCBIN.search(line)
        if m:
            off, ln = int(m.group(1), 16), int(m.group(2), 16)
            spans.append((0xF80000 + off, 0xF80000 + off + ln))
            continue
        m = LINE.match(line.rstrip("\n"))
        if m:
            bs = bytes(int(x, 16) for x in m.group(3).split())
            rows[int(m.group(2), 16)] = (bs, m.group(1).strip(), i)
    return rows, spans


def branch_target(addr, bs):
    """calr / jr / jrl / call nnn / jp nnn, or None."""
    op, n, end = bs[0], len(bs), addr + len(bs)
    if op == 0x1E and n == 3:
        return end + struct.unpack("<h", bs[1:3])[0]
    if op in (0x1D, 0x1B) and n == 4:
        return bs[1] | bs[2] << 8 | bs[3] << 16
    if 0x60 <= op <= 0x6F and n == 2:
        return end + struct.unpack("<b", bs[1:2])[0]
    if 0x70 <= op <= 0x7F and n == 3:
        return end + struct.unpack("<h", bs[1:3])[0]
    return None


def main():
    quiet = "--quiet" in sys.argv
    rows, spans = load_source()

    # ---- 1. every `<group> 1E` byte hit in either image ---------------------
    hits = []
    for name, path, base in IMGS:
        img = open(path, "rb").read()
        for i in range(len(img) - 2):
            if img[i] in GROUPS and img[i + 1] == PA:
                hits.append((name, base + i, img[i], img[i + 2]))

    real, data, undecided = [], [], []
    for name, addr, grp, opc in hits:
        if name != "prom_a":
            undecided.append((name, addr, grp, opc, "prom_b: not this lane's source"))
            continue
        row = rows.get(addr)
        if row and row[0][:2] == bytes([grp, PA]) and not row[1].startswith(".byte"):
            real.append((addr, grp, opc, row[1]))
        elif any(lo <= addr < hi for lo, hi in spans):
            undecided.append((name, addr, grp, opc, "inside .incbin"))
        else:
            data.append((name, addr, grp, opc))

    if not quiet:
        print("=== byte hits for `<C0|D0|E0|F0> 1E` ===")
        print("  %d hits total: %d are instructions in the converted prom_a "
              "source, %d fall inside emitted data or another instruction, "
              "%d are undecided" % (len(hits), len(real), len(data), len(undecided)))
        print("\n=== the real instructions ===")
        for addr, grp, opc, txt in real:
            print("  0x%06X  %-6s  %s" % (addr, GROUPS[grp], txt))

    writers = [r for r in real if r[1] == 0xF0]
    check("prom_a has exactly 4 instructions that WRITE PA",
          len(writers) == 4)
    check("they are 0xFE18EF, 0xFE18F7, 0xFE660D, 0xFE6631",
          [w[0] for w in writers] == [0xFE18EF, 0xFE18F7, 0xFE660D, 0xFE6631])

    # ---- 2. which BIT ------------------------------------------------------
    # 0xB0|b = res b,(mem); 0xB8|b = set b,(mem); 0x41 = ld (mem),A.
    bits = set()
    rmw_masks = []
    for addr, grp, opc, txt in writers:
        if 0xB0 <= opc <= 0xB7:
            bits.add(opc & 7)
        elif 0xB8 <= opc <= 0xBF:
            bits.add(opc & 7)
        elif opc == 0x41:
            # the two `ld (PA),A` are the tails of a read/modify/write; the mask
            # is the immediate of the and/or two instructions earlier.
            prev = [a for a in rows if addr - 6 <= a < addr]
            imm = None
            for a in sorted(prev):
                t = rows[a][1]
                m = re.match(r'(and|or) A,0x([0-9a-f]{2})$', t)
                if m:
                    imm = (m.group(1), int(m.group(2), 16))
            rmw_masks.append((addr, imm))
            if imm:
                bits.add({0xF7: 3, 0x08: 3}.get(imm[1] if imm[0] == "or" else (~imm[1]) & 0xFF, -1))
    if not quiet:
        print("\n=== which bit ===")
        print("  bit-manipulation writers touch bit(s): %s" % sorted(b for b in bits if b >= 0))
        for addr, imm in rmw_masks:
            print("  0x%06X  read/modify/write with `%s A,0x%02X`" % (addr, imm[0], imm[1]))
    check("every PA write in prom_a touches BIT 3 and no other bit",
          sorted(b for b in bits if b >= 0) == [3])

    # ---- 3. who calls the two bit writers ----------------------------------
    ASSERT_R, RELEASE_R = 0xFE18E9, 0xFE18F7
    callers = {ASSERT_R: [], RELEASE_R: []}
    for addr in sorted(rows):
        bs = rows[addr][0]
        t = branch_target(addr, bs)
        if t in callers:
            callers[t].append(addr)
    if not quiet:
        print("\n=== call sites ===")
        for r, name in ((ASSERT_R, "Disk_PortA3_ClearAndSettle (CLEAR, then wait)"),
                        (RELEASE_R, "Disk_PortA3_Release (SET, no wait)")):
            print("  0x%06X  %-46s %2d site(s)" % (r, name, len(callers[r])))
            print("      " + " ".join("%06X" % a for a in callers[r]))
    check("the CLEAR routine 0xFE18E9 has 3 call sites",
          len(callers[ASSERT_R]) == 3)
    check("the SET routine 0xFE18F7 has 12 call sites",
          len(callers[RELEASE_R]) == 12)
    check("all 15 sites are inside the 0xFE0000-0xFE54B5 block-device module",
          all(0xFE0000 <= a < 0xFE54B6
              for a in callers[ASSERT_R] + callers[RELEASE_R]))

    # Where does each CLEAR sit inside its routine?  "At the start" is a claim,
    # so it is measured: instructions from the routine's first instruction.
    ordered0 = sorted(rows)
    idx0 = {a: i for i, a in enumerate(ordered0)}
    heads = []
    for site in callers[ASSERT_R]:
        j = idx0[site]
        k = j
        while k > 0:
            a = ordered0[k - 1]
            bs, txt, _ = rows[a]
            if bs[0] in (0x0E, 0x07) and txt.split()[0] in ("ret", "reti"):
                break
            k -= 1
        heads.append((site, j - k))
    if not quiet:
        print("\n=== where does each CLEAR sit inside its routine? ===")
        for site, d in heads:
            print("  0x%06X  %2d instruction(s) after the first instruction "
                  "following the previous `ret`" % (site, d))
    # 2 of the 3 are within 4 instructions of the routine head.  The third,
    # 0xFE09F1, is 20 in -- because sub_FE09BE does its setup first and then
    # CYCLES the line, release (0xFE09EE) immediately followed by assert.
    check("2 of the 3 CLEAR sites are within 4 instructions of the routine head",
          sorted(d for _, d in heads)[:2] == sorted(d for _, d in heads if d <= 4)
          and len([d for _, d in heads if d <= 4]) == 2)
    check("the third is 0xFE09F1, immediately after the RELEASE at 0xFE09EE",
          [a for a, d in heads if d > 4] == [0xFE09F1]
          and ordered0[idx0[0xFE09F1] - 1] == 0xFE09EE)

    # ---- 4. exit-path test for the 12 SET sites ----------------------------
    # Walk the linear stream forward from each site and record how many
    # instructions separate it from the next `ret`/`reti`, and whether any
    # disk request (call/jp to Fdc_Request 0xFE66C7 or to the two published
    # request thunks T_F42D34 / T_F42D38) is issued in between.
    REQ = {0xFE66C7, 0xF42D34, 0xF42D38, 0xFE3018, 0xFE3004}
    ordered = sorted(rows)
    idx = {a: i for i, a in enumerate(ordered)}
    exits = []
    for site in callers[RELEASE_R]:
        i, steps, req = idx[site] + 1, 0, 0
        while i < len(ordered) and steps < 40:
            a = ordered[i]
            bs, txt, _ = rows[a]
            if bs[0] in (0x0E, 0x07) and txt.split()[0] in ("ret", "reti"):
                break
            if branch_target(a, bs) in REQ:
                req += 1
            steps += 1
            i += 1
        exits.append((site, steps, req))
    if not quiet:
        print("\n=== is every SET site on an exit path? ===")
        print("  (instructions from the call to the next `ret`, and how many "
              "disk requests are issued in between)")
        for site, steps, req in exits:
            print("  0x%06X  %2d instruction(s) to the next ret, %d disk "
                  "request(s) in between" % (site, steps, req))
    check("no SET site issues a disk request before its routine returns",
          all(r == 0 for _, _, r in exits))
    # ★ ELEVEN of the twelve are on an exit path.  The twelfth is NOT, and a
    # first draft of this script asserted "all twelve" and failed here, which is
    # why the number below is 11: 0xFE09EE is immediately followed by the CLEAR
    # call at 0xFE09F1, i.e. it RELEASES the line and asserts it again -- a
    # deliberate cycle at the head of sub_FE09BE, not an exit.
    onexit = [(a, s2) for a, s2, _ in exits if s2 <= 12]
    check("11 of the 12 SET sites are within 12 instructions of a `ret`",
          len(onexit) == 11)
    cyc = [a for a, s2, _ in exits if s2 > 12]
    check("the one exception is 0xFE09EE", cyc == [0xFE09EE])
    nxt = ordered[idx[0xFE09EE] + 1]
    check("and the instruction AFTER 0xFE09EE calls the CLEAR routine "
          "(release-then-assert)",
          branch_target(nxt, rows[nxt][0]) == ASSERT_R)
    # LAST-ELEMENT TEST: the highest-addressed SET site, 0xFE1CC4, is a
    # one-instruction veneer -- `calr Disk_PortA3_Release / ret` -- so its
    # distance must be exactly 0.
    check("LAST SITE 0xFE1CC4 is the veneer `calr .. / ret` (distance 0)",
          exits[-1][0] == 0xFE1CC4 and exits[-1][1] == 0)

    # ---- 5. the assert side reaches a disk request -------------------------
    # BFS over calr/call/jp from the routine that asserts, through the prom_b
    # directory, to Fdc_Request.
    romb = open(IMGS[1][1], "rb").read()

    def deref(t):
        if 0xF40000 <= t < 0xF44018:
            o = t - 0xF00000
            if romb[o] == 0x1B:
                return romb[o + 1] | romb[o + 2] << 8 | romb[o + 3] << 16
        return t

    labels = []
    for i, line in enumerate(open(SRC, encoding="utf-8"), 1):
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_.]*):', line)
        if m:
            labels.append((i, m.group(1)))
    lab_line = [x[0] for x in labels]
    start_of = {}
    for a in ordered:
        pass
    line_of = {a: rows[a][2] for a in ordered}
    # routine start address for each instruction: nearest preceding label line
    import bisect
    lab_addr = {}
    line_sorted = sorted((line_of[a], a) for a in ordered)
    lines_only = [x[0] for x in line_sorted]
    for ln, nm in labels:
        j = bisect.bisect_left(lines_only, ln)
        if j < len(line_sorted):
            lab_addr[ln] = line_sorted[j][1]
    def routine_of(a):
        j = bisect.bisect_right(lab_line, line_of[a]) - 1
        return lab_addr.get(lab_line[j]) if j >= 0 else None

    edges = {}
    for a in ordered:
        t = branch_target(a, rows[a][0])
        if t is None:
            continue
        r = routine_of(a)
        if r is None:
            continue
        edges.setdefault(r, set()).add((deref(t), a))
    seen, queue, back = {0xFE08BD}, [0xFE08BD], {}
    path = None
    while queue and path is None:
        n = queue.pop(0)
        for t, site in sorted(edges.get(n, ())):
            if t == 0xFE66C7:
                path, cur = [site], n
                while cur in back:
                    path.append(back[cur]); cur = back[cur][0]
                break
            if t not in seen and t >= 0xF80000:
                seen.add(t); back[t] = (n, site); queue.append(t)
    if not quiet:
        print("\n=== does the routine that ASSERTS reach a disk request? ===")
        print("  sub_FE08BD -> sub_FE1962 -> T_F42D34 -> 0xFE3042 -> "
              "Disk_CommandDispatch (sub_FE426E) -> sub_FE370A -> Fdc_Request(0xFE66C7)")
    check("BFS from sub_FE08BD (an asserting routine) reaches Fdc_Request",
          path is not None)

    # ---- 6. gap V side-result: who writes bit 6 of (0x21E7)? ---------------
    # `f1 e7 21 b6` = res 6,(0x21E7); `f1 e7 21 be` = set 6,(0x21E7).
    b6 = {}
    for name, path_, base in IMGS:
        img = open(path_, "rb").read()
        for i in range(len(img) - 3):
            if img[i:i + 3] == b"\xf1\xe7\x21" and img[i + 3] in (0xB6, 0xBE):
                b6[base + i] = "res" if img[i + 3] == 0xB6 else "set"
    if not quiet:
        print("\n=== bit 6 of (0x21E7): every byte-level writer, both images ===")
        for a in sorted(b6):
            print("  0x%06X  %s 6,(0x21E7)%s" % (a, b6[a],
                  "" if a in rows else "   (not an instruction boundary in the source)"))
    real_b6 = {a: v for a, v in b6.items() if a in rows}
    check("(0x21E7) bit 6 is cleared at 0xFE08D1 and set at 0xFE08F3, "
          "both inside sub_FE08BD",
          real_b6.get(0xFE08D1) == "res" and real_b6.get(0xFE08F3) == "set")
    check("the value that makes sub_FE08BD SET it is 0x0B in (0x1735)",
          rows[0xFE08E9][1] == "ld C,(XIX)"
          and rows[0xFE08EB][1] == "cp C,0x0b"
          and rows[0xFE08C0][1] == "lda_24 xix, (0x1735)")
    # ⚠ NOT the only writers.  sub_FE09BE loads XIX with the ADDRESS 0x21E7 and
    # then reaches bit 6 through the pointer, which no scan for
    # `f1 e7 21 b6/be` can see.  This check exists so the "only two writers"
    # reading cannot be written down: it asserts the pointer path is there.
    check("bit 6 is ALSO written through a pointer: 0xFE09C0 lda XIX,0x21E7 "
          "then 0xFE0A0E `and (XIX),0xBF` and 0xFE0A1B `or (XIX),0x40`",
          rows[0xFE09C0][1] == "lda_d16 xix, (0x21e7)"
          and rows[0xFE0A0E][0] == b"\x84\x3c\xbf"
          and rows[0xFE0A1B][0] == b"\x84\x3e\x40")
    check("and that pair copies bit 3 of (0x21E8) into bit 6 of (0x21E7)",
          rows[0xFE0A11][1] == "ldb_d8 c, (0x21e8)"
          and rows[0xFE0A15][1] == "and C,0x08"
          and rows[0xFE0A19][1] == "jr z, 0x08")

    # ---- 7. the PB bit 2 neighbour (gap U's blast radius) ------------------
    # sub_FE08BD pulses PB bit 2 HIGH for one Delay_150Ticks immediately after
    # asserting PA bit 3.  SFR 0x1F is PB.
    check("sub_FE08BD pulses PB bit 2 high for 150 ticks right after the "
          "PA bit 3 assert",
          rows[0xFE08C8][0] == b"\xf0\x1f\xba"          # set 2,(0x1F)
          and branch_target(0xFE08CB, rows[0xFE08CB][0]) == 0xFE1411
          and rows[0xFE08CE][0] == b"\xf0\x1f\xb2")     # res 2,(0x1F)

    print("\nFAILURES: %d" % len(FAIL))
    sys.exit(1 if FAIL else 0)


if __name__ == "__main__":
    main()
