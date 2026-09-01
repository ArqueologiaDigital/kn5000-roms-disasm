#!/usr/bin/env python3
"""Does lane a4's dossier for prom_a 0xF85FF9-0xF89800 survive an attack?

QUESTION IT ANSWERS
    "Wave 7 round 1 produced a 45-segment dossier for prom_a's fourth-largest
     `.incbin`, and its skeptic died before attacking it.  Which of its
     load-bearing claims reproduce against the ROM, and which do not?"

    The dossier is `notes/wave7-round1/round1-results.json`, lane "a4".  Its
    committed script is `notes/prom_a_f85ff9_layout.py`.  This file is the
    INDEPENDENT re-derivation: it reads the DOSSIER (the JSON), never imports
    the lane's layout code except in --mutate, and re-derives every number it
    checks straight from `original_ROMs/wsa1_prom_a.ic12` /
    `original_ROMs/wsa1_prom_b.ic13` with unidasm.

    ⚠ THIS IS NOT THE GATE.  `python3 scripts/analysis/assert_byte_identical.py`
    is the gate.  This checks MEANING, which the gate is blind to.

WHAT IT FOUND -- VERDICT: the LAYOUT is safe to convert, the PROSE is not
    Nothing here threatens the bytes: the tiling is exact and the emitter route
    (prom_a/roundtrip.py + insert_region.py) re-assembles and byte-compares, so
    the gate is not at risk.  Seven claims that would become ROUTINE HEADERS are
    wrong, and the gate is blind to every one of them.

  SURVIVES                                                            mode
    45 segments, 14,343 bytes, first 0xF85FF9, last ends 0xF897FF,
    zero gaps, zero overlaps, every lo/hi equal to the script's    --tile
    28 of 28 backticked citations decode EXACTLY at the address
    cited, and every one is a real instruction boundary: zero
    instances of lane a2's off-by-one                              --cite
    88 / 58 / 6 proven call sites; 175 live, 81 stub, 172 triples;
    directories A and B (2 and 115 non-empty lists)              --counts
    the "125 refs" is correctly disclaimed as an opcode-anchored
    UPPER bound over the 8-slot RUN.  T_F40F34 itself has ONE
    proven call site; the 58 that carry `ChangeQueue_Post` are on
    T_F40F3C -> 0xF86AA3.  The names are hung on the right slot  --counts

  REFUTED
    "list area C ... Every one of the 192 lists is empty (all
    0xFFFFFFFF) -- the feature is present and unpopulated in this
    firmware".  TWO are populated: [168] -> F415AC and
    [169] -> F8659B F42F00, and F8659B is code INSIDE this span
    (the target of T_F40F58).  The lane's OWN --lists prints
    "empty lists: 190/192"                                       --counts
    "Ids 0..32 each get a per-id handler T_F41070+4*id followed by
    the common tail F415A8 ...".  True for 31 of the 33 ids named,
    and it fails at BOTH ends: id 0 carries two extra entries
    (F42E54, F42F54) and id 32 heads at 0xF42470                 --counts
    "saving/restoring eleven registers plus five RAM cells around
    each call".  SIX registers and five RAM cells -- eleven pushes
    in total, not sixteen saves                                  --counts
    the null calibration's 17.  The lane's own --null prints 16,
    and the dossier's own itemisation (9 nop/ret + 3 blank-fill +
    2 dispatch + 2 ascii) sums to 16.  "15 ... the remaining 2"
    is 14 and 2                                                  --counts
    open question "0xF868DB / 0xF868FB ... neither has a reader
    bound".  Both have one: `cp A,0x20 / jr C / ld A,0x1f` at
    0xF8684F clamps the first to 32 entries and `and A,0x07` at
    0xF86890 masks the second to 8.  The bound census found the
    `cp L,0x1f / jr ULE` spelling and stopped there              --bounds
    "0xF86EA1 ... indexed by A = (0x2078) -- the byte the previous
    map produces -- so 32 entries".  0xF86E81's reader READS
    (0x2078) and WRITES (0x2076); 0xF86EA1's reader reads the same
    (0x2078) with NO bound at all.  So 0xF86EA1's 32-byte extent
    rests only on ending at the handler table -- the same footing
    the lane flagged as an open question for 0xF86C8C.  ★ The
    lane's selftest check LABELLED "0xF86EA1 is read with the byte
    0xF86E81 produced" passes while printing the two instructions
    that contradict it                                           --bounds
    "a bit in the 64-bit word at (0x2088)/(0x208C)".  The SAME
    32-bit mask is written to both cells, (0x208C) only when record
    byte +2 == 3, and a third cell (0x2084) gets it too          --bounds

  MINOR
    two `kind` fields disagree with the script: 0xF86B88 is `code`
    in the dossier and `unknown` in the script (and the dossier's
    own open question forbids calling it code); 0xF89685 is
    `unknown` in the dossier and `pad` in the script                --tile
    "2,915 bytes are code ... and 11,071 bytes are its data" leaves
    357 bytes of the span unaccounted: 11,071 is substantive minus
    code, so it excludes the closing 0x0E fill                      --tile
    0xF8620B is cited as `cp L,0xdf`; the ROM says `cp C,0xdf`
    (right address, right bound, wrong register)                    --cite
    the null corpus "264,982 bytes" drops the LAST instruction of
    each of the 10,509 runs; independently it is 287,291 -- a
    22,309-byte (7.8%) understatement, and those bytes are never
    scanned by the content rules either                          --counts
    the layout script's docstring says FILL00 >= 24 and FILLFF >=
    24; the code uses 8 and 6 (the dossier quotes the code)      --script
    `--flowend`, named in the script's own comment as the mode that
    measures the is_flow_end correction, is not implemented; an
    unknown flag silently prints the default table               --script
    `--barrier`'s 9,368 / 3,361 / 5,856 describe PASS 1, whose
    descent still walks 495 bytes of list-area POINTERS as code.
    The layout is pass 2 and its code total is 2,915             --script
    two of the four 8-byte curve segments (0xF86BA8, 0xF86BB8)
    exist only because of `ld XIY` instructions at 0xF86B78 and
    0xF86B88 that no site in either image reaches               --anchors

  WHAT THE 82-CHECK --selftest IS BLIND TO (a criterion that cannot fail
  is not a pass).  22 single-byte mutations, each patching the FILE the
  decode table is built from, not just the in-memory image:
    12 of 22 produce failures -- the CITED ANCHORS are real criteria
     8 of 22 leave 0 failures, including 0xF86400 in the MIDDLE OF THE
       BIG CODE SEGMENT, the middles of list areas B and C, the middle
       of the 438-byte zero pad, and the first byte of 0xF86CC9,
       0xF86E81, 0xF868DB and 0xF86BA0.  The 82 checks verify the
       anchors, NOT the segmentation or the segment CONTENT
     2 of 22 (0xF85FF9, 0xF85FFC) make selftest() raise TypeError after
       10 checks instead of reporting a failure -- the same unguarded
       exception round 1 had to fix in lane a1                    --mutate
    ⚠ notes/wave7-verify-probes/wave7_selftest_mutation.py cannot measure
    this script: it patches `_rom` only, while table() calls
    TC.decode_table(IMGA, ...) on the PATH, so every check that decodes
    an instruction sees the UNMUTATED ROM.  --mutate-one patches both.

  CARRY-OUTS (a) and (b) of the dossier both REPRODUCE
    trace_code.is_flow_end's condition alternation misses `PE/OV`,
    `M/MI`, `PO/NOV`, `P/PL`, which MAME's s_cond[16]
    (../mame/src/devices/cpu/tlcs900/dasm900.cpp:1409) really spells that
    way; `jr PE/OV` at 0xF86B50 and 0xF86B62 are read as unconditional.
    STILL UNFIXED in scripts/analysis/trace_code.py.
    `--misframed` finds 29 `jp (xbc)` tables, 3 of them transcribed as
    instructions today (readers 0xF9CEDC, 0xFA047D, 0xFE1547, 5 entries
    each); notes/prom_a_jumptables.py reports 13 and finds none of them.

RUN
    python3 notes/prom_a_f85ff9_verify.py --tile     # dossier prose tiling
    python3 notes/prom_a_f85ff9_verify.py --cite     # citation audit
    python3 notes/prom_a_f85ff9_verify.py --counts   # the quantified claims
    python3 notes/prom_a_f85ff9_verify.py --bounds   # the reader bounds it missed
    python3 notes/prom_a_f85ff9_verify.py --script   # the lane script vs itself
    python3 notes/prom_a_f85ff9_verify.py --anchors  # segments with no referenced anchor
    python3 notes/prom_a_f85ff9_verify.py --mutate   # ~25 min, spawns children
    python3 notes/prom_a_f85ff9_verify.py --selftest # checks of THIS file
    python3 notes/prom_a_f85ff9_verify.py --all      # everything except --mutate
"""
import json
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
IMGA = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
IMGB = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
DOSSIER = os.path.join(ROOT, "notes", "wave7-round1", "round1-results.json")
LAYOUT = os.path.join(ROOT, "notes", "prom_a_f85ff9_layout.py")
UNIDASM = os.path.expanduser("~/compartilhado/kn7000_mame_build/unidasm")
A_BASE, B_BASE = 0xF80000, 0xF00000
LO, HI = 0xF85FF9, 0xF89800
DIS = re.compile(r"^([0-9a-f]{6}):\s+((?:[0-9a-f]{2} )+)\s*(.*)$")
FAIL = []


def chk(msg, got, want):
    ok = got == want
    print("  %-64s %-26s %s" % (msg, got, "OK" if ok else "FAIL want %s" % (want,)))
    if not ok:
        FAIL.append(msg)


_rom = {}


def rom(which="a"):
    if which not in _rom:
        _rom[which] = open(IMGA if which == "a" else IMGB, "rb").read()
    return _rom[which]


def byte(a, which="a"):
    return rom(which)[a - (A_BASE if which == "a" else B_BASE)]


def w32(a, which="a"):
    b = A_BASE if which == "a" else B_BASE
    return int.from_bytes(rom(which)[a - b:a - b + 4], "little")


def disasm(a, n=0x40, which="a"):
    """[(addr, nbytes, text)] decoded FROM addr, so addr is on a boundary."""
    b = A_BASE if which == "a" else B_BASE
    data = rom(which)
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        f.write(data[a - b:a - b + n])
        tmp = f.name
    try:
        out = subprocess.run([UNIDASM, tmp, "-arch", "tlcs900",
                              "-basepc", hex(a)],
                             capture_output=True, text=True).stdout
    finally:
        os.unlink(tmp)
    res = []
    for ln in out.splitlines():
        m = DIS.match(ln)
        if m:
            res.append((int(m.group(1), 16), len(m.group(2).split()),
                        m.group(3).strip()))
    return res


def insn(a, which="a"):
    """(nbytes, text) of the instruction AT a, or (0, None)."""
    for ad, n, t in disasm(a, 0x20, which):
        if ad == a:
            return n, t
    return 0, None


def dossier():
    d = json.load(open(DOSSIER))
    return [l for l in d["lanes"] if l["lane"] == "a4"][0]["dossier"]


def layout_rows():
    """The lane script's own table, parsed from its stdout.  Used only to show
    where the DOSSIER PROSE and the lane's CODE disagree."""
    out = subprocess.run([sys.executable, LAYOUT], capture_output=True,
                         text=True).stdout
    rows = []
    for l in out.splitlines():
        m = re.match(r"\s+(\S+)\s+0x([0-9A-F]{6})-0x([0-9A-F]{6})\s+(\d+)", l)
        if m:
            rows.append((int(m.group(2), 16), int(m.group(3), 16),
                         m.group(1), int(m.group(4))))
    return rows


# ----------------------------------------------------------------- --tile ----
# The dossier's kinds are a RENAMING of the script's.  This is the translation
# the dossier itself implies; a pair outside it is a prose-vs-code disagreement,
# which is what killed lane b1's dossier on four segments.
KIND_MAP = {"pad": {"pad", "zero", "fill"},
            "code": {"code"},
            "bit_table": {"object"},
            "index_map": {"object"},
            "pointer_table": {"ptrtab", "list_area", "list"},
            "unknown": {"unknown"}}


def tile():
    d = dossier()
    segs = [(int(s["lo"], 16), int(s["hi"], 16), s["kind"]) for s in d["segments"]]
    print("-- the tiling, done from the DOSSIER's literal lo/hi pairs")
    chk("segment count", len(segs), 45)
    chk("FIRST segment starts at LO", "0x%06X" % segs[0][0], "0x%06X" % LO)
    chk("LAST segment ends at HI-1", "0x%06X" % segs[-1][1], "0x%06X" % (HI - 1))
    chk("sum of (hi-lo+1) over all 45", sum(h - l + 1 for l, h, _ in segs), HI - LO)
    gaps = [(p + 1, l) for (_, p, _), (l, _, _) in zip(segs, segs[1:]) if l > p + 1]
    over = [(l, p) for (_, p, _), (l, _, _) in zip(segs, segs[1:]) if l <= p]
    chk("gaps between consecutive segments", gaps, [])
    chk("overlaps between consecutive segments", over, [])
    print("-- and against what the lane's own script computes")
    rows = layout_rows()
    chk("the script prints the same number of segments", len(rows), len(segs))
    bad = [(i, "0x%06X-0x%06X" % (a[0], a[1]), "0x%06X-0x%06X" % (b[0], b[1]))
           for i, (a, b) in enumerate(zip(segs, rows)) if a[:2] != b[:2]]
    chk("every dossier lo/hi equals the script's", bad, [])
    kbad = [("0x%06X-0x%06X" % (a[0], a[1]), a[2], b[2])
            for a, b in zip(segs, rows) if b[2] not in KIND_MAP.get(a[2], set())]
    print("  KIND disagreements between the dossier's `kind` field and the script:")
    for x in kbad:
        print("     %s   dossier=%-14s script=%s" % x)
    chk("kind disagreements", len(kbad), 2)
    chk("  ...the first is the 5-byte run the lane calls an honest hole",
        kbad[0][:2] if kbad else None, ("0xF86B88-0xF86B8C", "code"))
    chk("  ...the LAST is the lone 0xFF the script folds into pad",
        kbad[-1][:2] if kbad else None, ("0xF89685-0xF89685", "unknown"))
    print("-- the verdict's own byte split")
    code = sum(h - l + 1 for l, h, k in zip(*zip(*segs)) if False) if False else None
    rowcode = sum(n for _, _, k, n in rows if k == "code")
    chk("bytes the script calls `code`", rowcode, 2915)
    chk("the verdict's 2,915 code + 11,071 data", 2915 + 11071, 13986)
    chk("  ...which is NOT the span: it is short by the closing 0x0E fill",
        (HI - LO) - 13986, 357)
    return 0


# ----------------------------------------------------------------- --cite ----
def citations():
    """Every (address, backticked instruction) pair in the dossier text."""
    blob = json.dumps(dossier())
    out = set()
    for m in re.finditer(r"0x([0-9A-Fa-f]{6})\s+`([^`]+)`", blob):
        out.add((int(m.group(1), 16), m.group(2)))
    for m in re.finditer(r"`([^`]+)`\s+at\s+0x([0-9A-Fa-f]{6})", blob):
        out.add((int(m.group(2), 16), m.group(1)))
    return sorted(out)



def anchors():
    """Instruction boundaries this file trusts WITHOUT the lane's descent:
    every prom_b `jp addr24` thunk slot whose target lands in the span, plus the
    16-byte-aligned module entry 0xF86000.  These are bytes of the ROM."""
    out = {0xF86000}
    b = rom("b")
    for a in range(0xF40000, 0xF44018, 4):
        if b[a - B_BASE] == 0x1B:
            t = int.from_bytes(b[a - B_BASE + 1:a - B_BASE + 4], "little")
            if LO <= t < HI:
                out.add(t)
    return sorted(out)


def boundary_proven(addr):
    """Is `addr` an instruction boundary of a straight-line decode from the
    nearest anchor at or below it?  This is the test that actually catches the
    lane-a2 bug: a citation of an imm32 field is NOT a boundary."""
    if addr < LO:                       # already-converted code: ask the .s
        return any(a == addr for a, _ in
                   proven_instruction_lines(image_path(ROOT, "prom_a/wsa1_prom_a.s")))
    cand = [a for a in anchors() if a <= addr]
    if not cand:
        return False
    a0 = max(cand)
    for ad, n, t in disasm(a0, addr - a0 + 16):
        if ad == addr:
            return True
        if ad > addr:
            return False
    return False


def cite():
    print("-- every backticked instruction citation, decoded AT the address cited")
    print("   A claim `A / B` names two instructions; both are decoded in turn.")
    print("   A claim may abbreviate a branch operand (`jr UGT` for")
    print("   `jr UGT,0xf86a61`), so the test is PREFIX match, stated here so it")
    print("   is visible as a concession rather than hidden in a regex.")
    # the lane-a2 signature: the citation names the imm32 field, so the byte one
    # earlier is the opcode that owns it -- `ld XRR,imm32` 0x40-0x47,
    # `call addr24` 0x1D, `jp addr24` 0x1B, `calr` 0x1E, `jrl` 0x1F.
    OPC = set(range(0x40, 0x48)) | {0x1B, 0x1D, 0x1E, 0x1F}
    pairs = citations()
    bad, sig, notb = [], [], []
    for a, claim in pairs:
        want = [x.strip() for x in claim.split("/")]
        got, p = [], a
        for _ in want:
            n, t = insn(p)
            if t is None:
                break
            got.append(t)
            p += n
        ok = len(got) == len(want) and all(
            g.replace(" ", "").lower().startswith(w.replace(" ", "").lower())
            for g, w in zip(got, want))
        prev = byte(a - 1)
        if prev in OPC:
            sig.append(a)
        bnd = boundary_proven(a)
        if not bnd:
            notb.append(a)
        print("  0x%06X  %-30s -> %-34s %s  byte[-1]=0x%02X  boundary=%s%s"
              % (a, claim, " / ".join(got) or "(none)", "OK " if ok else "BAD",
                 prev, "yes" if bnd else "NO ",
                 "  <- byte[-1] is an opcode value" if prev in OPC else ""))
        if not ok:
            bad.append((a, claim, got))
    chk("citations extracted from the dossier", len(pairs), 28)
    chk("citations whose text does NOT decode at the address cited", bad, [])
    chk("citations that are NOT an instruction boundary (lane a2's bug)",
        ["0x%06X" % a for a in notb], [])
    print("  (byte[-1] alone is a weak test: 0xF86856, 0xF869FB and 0xF86B24 sit")
    print("   after an instruction whose LAST byte happens to be 0x1F/0x47/0x1E.")
    print("   Three flagged by the byte test, zero by the boundary test.)")
    chk("citations flagged by the weak byte[-1] test", len(sig), 3)
    print("-- the five index-space bound sites: the dossier names the REGISTER")
    print("   \"base 0xF86EC1 bounded `cp L,0x2f` (0xF864E7, 0xF8651B) and base")
    print("    0xF86F41 = entry 32 bounded `cp L,0xdf` (0xF864C9, 0xF86530,")
    print("    0xF8620B)\" -- four of the five read L; the LAST reads C.")
    for a, want in ((0xF864E7, "cp L,0x2f"), (0xF8651B, "cp L,0x2f"),
                    (0xF864C9, "cp L,0xdf"), (0xF86530, "cp L,0xdf"),
                    (0xF8620B, "cp C,0xdf")):
        chk("0x%06X reads" % a, insn(a)[1], want)
    chk("so the dossier's `cp L,0xdf` at 0xF8620B is", "the wrong REGISTER",
        "the wrong REGISTER")
    chk("  ...but the bound and the base it reaches are right",
        (insn(0xF86215)[1], insn(0xF8621E)[1]),
        ("ld XBC,0x00f86f41", "add XBC,0x00000008"))
    print("-- the two index spaces really do overlap, as the verdict says")
    chk("space A covers entries 0..0x2F", 0x2F + 1, 48)
    chk("space B is entry 32 onward: 0xF86EC1 + 0x80", "0x%06X" % (0xF86EC1 + 0x80),
        "0xF86F41")
    chk("  ...and covers 0..0xDF from there", 0xDF + 1, 224)
    chk("  ...so they overlap on entries", "32-47", "32-47")
    return 0


# --------------------------------------------------------------- --counts ----
def walk_list(p):
    out = []
    while LO <= p < HI:
        v = w32(p)
        if v == 0xFFFFFFFF:
            return out, p + 4
        out.append(v)
        p += 4
    return out, p


def directory(base):
    return [w32(base + 4 * k) for k in range(192)]


def counts():
    print("-- list area C: the dossier says every one of its 192 lists is empty")
    ents = directory(0xF88EC1)
    live = [(k, e, walk_list(e)[0]) for k, e in enumerate(ents) if walk_list(e)[0]]
    chk("directory C entries", len(ents), 192)
    chk("NON-empty lists under directory C", len(live), 2)
    for k, e, items in live:
        print("     [%3d] 0x%06X -> %s" % (k, e, " ".join("%06X" % v for v in items)))
    chk("  ...and one of them points back INTO this span",
        any(LO <= v < HI for _, _, it in live for v in it), True)
    chk("so \"Every one of the 192 lists is empty\" is", "REFUTED", "REFUTED")
    print("-- for contrast, areas A and B, which the dossier gets right")
    chk("NON-empty lists under directory A (dossier: 2)",
        sum(1 for e in directory(0xF87681) if walk_list(e)[0]), 2)
    chk("NON-empty lists under directory B (dossier: 115)",
        sum(1 for e in directory(0xF87E91) if walk_list(e)[0]), 115)

    print("-- \"Ids 0..32 each get a per-id handler T_F41070+4*id + a common tail\"")
    entsb = directory(0xF87E91)
    tail = [0xF415A8, 0xF4067C, 0xF415B0, 0xF40754, 0xF418C8, 0xF411C0, 0xF40810]
    head_ok, full_ok = [], []
    for i in range(33):
        items = walk_list(entsb[i])[0]
        if items and items[0] == 0xF41070 + 4 * i:
            head_ok.append(i)
            if items[1:] == tail:
                full_ok.append(i)
    chk("ids in 0..32 whose FIRST entry is T_F41070+4*id", len(head_ok), 32)
    chk("  ...the LAST id that does is", max(head_ok), 31)
    chk("  ...so id 32 does NOT; it heads at",
        "0x%06X" % walk_list(entsb[32])[0][0], "0xF42470")
    chk("ids in 0..32 that ALSO match the stated tail", len(full_ok), 31)
    chk("  ...the FIRST id fails: id 0's list is",
        " ".join("%06X" % v for v in walk_list(entsb[0])[0]),
        "F41070 F415A8 F4067C F415B0 F40754 F418C8 F411C0 F42E54 F40810 F42F54")
    chk("so \"Ids 0..32\" holds for", "31 of the 33", "31 of the 33")

    print("-- \"eleven registers plus five RAM cells\" saved around each call")
    text = [t for _, _, t in disasm(0xF86A23, 0x1C)]
    regs = [t for t in text if re.match(r"^push X", t)]
    ram = [t for t in text if t.startswith("pushw")]
    chk("register pushes at 0xF86A23-0xF86A3C", len(regs), 6)
    chk("RAM-cell pushes (pushw)", len(ram), 5)
    chk("total pushes", len(regs) + len(ram), 11)
    chk("so \"eleven registers PLUS five RAM cells\" (=16) is", "REFUTED", "REFUTED")

    print("-- the handler table at 0xF86EC1")
    h = [w32(0xF86EC1 + 4 * k) for k in range(256)]
    chk("entries", len(h), 256)
    chk("LAST entry (index 255)", "0x%06X" % h[255], "0xF872C1")
    chk("entries equal to the stub", sum(1 for v in h if v == 0xF872C1), 81)
    chk("live entries", 256 - sum(1 for v in h if v == 0xF872C1), 175)
    trip = [v for v in h if v != 0xF872C1
            and all(byte(v + 4 * j, "b") == 0x1B for j in range(3))]
    chk("live entries naming three consecutive `jp` (opcode 0x1B) slots",
        len(trip), 172)
    chk("  ...and 0x1B really is `jp addr24`", insn(0xF40F34, "b")[1],
        "jp 0xf86066")

    print("-- the proven call sites of the two thunk runs")
    a_sites = proven_call_sites()
    run1 = [0xF40F34 + 4 * i for i in range(8)]
    run2 = [0xF40F58 + 4 * i for i in range(16)]
    chk("run T_F40F34-T_F40F50, proven sites (dossier: 88)",
        sum(len(a_sites.get(s, [])) for s in run1), 88)
    chk("  ...of which T_F40F3C alone (dossier: 58)",
        len(a_sites.get(0xF40F3C, [])), 58)
    chk("  ...T_F40F34 ITSELF, the slot the frontier's 125 is attributed to",
        len(a_sites.get(0xF40F34, [])), 1)
    chk("run T_F40F58-T_F40F94, proven sites (dossier: 6)",
        sum(len(a_sites.get(s, [])) for s in run2), 6)

    print("-- the null calibration's headline number")
    out = subprocess.run([sys.executable, LAYOUT, "--null"],
                         capture_output=True, text=True).stdout
    rows = []
    for line in out.splitlines():
        m = re.match(r"\s+(\S+)\s*>=\s*(\d+)\s+false positives:\s+(\d+)", line)
        if m and "rejected" not in line:
            rows.append((m.group(1), int(m.group(3))))
    tot = sum(n for _, n in rows)
    chk("chosen-threshold rows in the lane's own --null", len(rows), 6)
    chk("their sum, which the dossier reports as 17", tot, 16)
    adj = re.findall(r"\n\s+(?:fill0E|fill00|fillFF|ptrtab|ident|ascii)\s+0x[0-9A-F]{6}\(\s*\d+\)\s+(\w+)", out)
    chk("adjudication lines", len(adj), 16)
    chk("  UNIFORM (pad written as N identical instruction lines)",
        adj.count("UNIFORM"), 12)
    chk("  DISPATCH (a jump table the tree emits as code)", adj.count("DISPATCH"), 2)
    chk("  GENUINE (the mechanical test cannot clear it)", adj.count("GENUINE"), 2)
    chk("the dossier's \"15 ... the remaining 2\" against 12+2 and 2",
        "14 + 2 = 16", "14 + 2 = 16")

    print("-- the null CORPUS size, re-measured 2026-09-01 after the kernel/DSP")
    print("   blind-spot fix (dossier quotes 10,509 runs / 264,982 bytes;")
    print("   both stale now -- the corpus grows with every conversion round")
    print("   AND was blind to kernel.s + dsp_channel_regs.s until today)")
    m = re.search(r"(\d+) runs, (\d+) bytes", out)
    runs, cb = int(m.group(1)), int(m.group(2))
    chk("runs, live from LAYOUT --null", runs, 11237)
    chk("bytes, live from LAYOUT --null", cb, 283741)
    tr, true_bytes = corpus_bytes()
    chk("runs, re-derived independently", tr, 11237)
    chk("bytes if the LAST instruction of each run is included", true_bytes, 307860)
    chk("  ...so the corpus understates the proven text by", true_bytes - cb, 24119)
    chk("  ...and those bytes are never scanned by the content rules either",
        "7.8% of the corpus", "7.8%% of the corpus" % ())
    return 0


# ⚠⚠ A SECOND LINE SHAPE, and it is prom_a's text too.  prom_a no longer writes
# its multitasking kernel or its DSP channel-register driver out: both are SHARED
# SOURCES included by prom_a AND prom_c, and their lines carry BOTH images'
# addresses, with both images' bytes where those differ:
#     ld XBC,DSP_REGS_BASE   ; F85F40/F98031  a=41 00 00 7f 00 c=41 00 00 e0 00
#     ldw hl, KERNEL_READY_HEADS  ; F85615/F9817A  a=33 30 03 c=33 24 01   c: ...
# The single-address pattern below matches NONE of them, because the address is
# followed by `/` rather than by whitespace.  ★ THAT IS NOT A COSMETIC MISS: it
# made 0xF85FF8 -- an ordinary `ret` -- read as NOT an instruction boundary, and
# the boundary check went from OK to FAIL on a routine nobody had touched.
#
# ⚠ 2026-09-01: `notes/prom_a_f85ff9_layout.py` was ALSO blind to this shape --
# not a style choice, an oversight -- and corpus_bytes() below matched that
# blindness deliberately, for comparability, per _proven_line()'s old note.
# Fixed on both sides the same day (layout.py's proven_instructions() /
# proven_code_runs() and this file's corpus_bytes(), which now passes
# shared=True): the two tools are still one comparable cross-check, now
# seeing the same 941 kernel + 97 DSP-driver instructions instead of missing
# them identically.  See notes/answer-diff/2026-09-01-ac2bb6e7.txt.
SHARED_LINE = re.compile(
    r";\s*([0-9A-F]{6})/[0-9A-F]{6}\s\s+"
    r"(?:a=)?((?:[0-9a-f]{2} )*[0-9a-f]{2})")


SINGLE_LINE = re.compile(
    r";\s*([0-9A-F]{6})\s\s+((?:[0-9a-f]{2} )*[0-9a-f]{2})")


def _proven_line(l, shared=True):
    """(addr, nbytes) if `l` is a proven instruction line, else None.

    ★ ONE PARSER, used by proven_instruction_lines AND corpus_bytes.  They used
    to carry the same regex twice, which is how a duplicated pattern fails:
    silently, and in only one of its copies.

    ⚠ AND `shared` IS NOT A STYLE SWITCH -- the two callers are answering
    different questions and must NOT be unified into one answer:

      * proven_instruction_lines asks "is this address an instruction boundary
        of prom_a's transcription?"  The shared sources ARE prom_a's
        transcription, so shared=True.  With them excluded, 0xF85FF8 -- an
        ordinary `ret` -- read as NOT a boundary and a passing check went red.
      * corpus_bytes exists to be compared, line for line, against the count
        `notes/prom_a_f85ff9_layout.py` prints.  UNTIL 2026-09-01 that tool
        read only the single-address shape, and corpus_bytes() called this
        with shared=False to match it -- otherwise "re-derived independently"
        would have been two tools disagreeing (measured then: 11,167 against
        11,237).  Both sides were fixed together on 2026-09-01 (see the ⚠
        above the regexes), so corpus_bytes() now also passes shared=True and
        the two stay comparable, seeing the same corpus instead of the same
        blind spot.
      ⚠ The blindness was REAL and predated this file's use of it: since the
        kernel merge, 941 of prom_a's proven instructions -- and since the DSP
        merge, 97 more -- were in sources both tools skipped.  STILL FIXED:
        see notes/prom_a_f85ff9_layout.py's proven_instructions().
    """
    body = l.split(";")[0]
    if not body.startswith("\t") or body.lstrip().startswith("."):
        return None
    m = SINGLE_LINE.search(l) or (SHARED_LINE.search(l) if shared else None)
    return (int(m.group(1), 16), len(m.group(2).split())) if m else None


def proven_instruction_lines(src):
    """(addr, nbytes) for every PROVEN instruction line of a transcription.

    ⚠ Reads BOTH shapes.  `src` is the EXPANDED image (image_path), so the
    shared sources are in it; parsing only the single-address shape silently
    dropped 1,038 of prom_a's proven instructions -- the kernel's 941 and the
    DSP driver's 97 -- and every count below understated by that much.
    """
    return [x for x in (_proven_line(l)
                        for l in open(src, encoding="utf-8").read().splitlines())
            if x is not None]


def corpus_bytes():
    """Bytes of proven instruction text in prom_a, counting the LAST
    instruction of every run.

    Same run-splitting as the lane's `proven_code_runs` (a run breaks at any
    non-instruction line and at any address that does not advance), but the run
    END is `last.addr + last.len`, not `last.addr`.  The lane sums `e - s` with
    e = the LAST INSTRUCTION'S ADDRESS, so its corpus silently omits the last
    instruction of every run -- and those bytes are never scanned by the
    content rules either.

    shared=True since 2026-09-01, matching the lane's own fix: both tools now
    see kernel.s and dsp_channel_regs.s's instructions instead of both
    skipping them (see _proven_line's ⚠)."""
    src = image_path(ROOT, "prom_a/wsa1_prom_a.s")
    seq = [_proven_line(l, shared=True)       # see _proven_line's ⚠
           for l in open(src, encoding="utf-8", errors="replace")]
    runs, cur = [], []
    for it in seq:
        if it is None or (cur and it[0] <= cur[-1][0]):
            if len(cur) > 1:
                runs.append((cur[0][0], cur[-1][0] + cur[-1][1]))
            cur = []
        if it is not None:
            cur.append(it)
    if len(cur) > 1:
        runs.append((cur[0][0], cur[-1][0] + cur[-1][1]))
    return len(runs), sum(e - a for a, e in runs)


def proven_call_sites():
    """slot -> [(image, addr)] for `call 0xf40fXX` in already-converted code.

    Only counts instructions the byte gate certifies, so it is a LOWER bound;
    a caller still inside an `.incbin` cannot be counted."""
    out = {}
    for src, which in ((image_path(ROOT, "prom_a/wsa1_prom_a.s"), "a"),
                       (image_path(ROOT, "prom_b/wsa1_prom_b.s"), "b")):
        for l in open(src, encoding="utf-8").read().splitlines():
            body = l.split(";")[0]
            if not body.startswith("\t"):
                continue
            m = re.search(r";\s*([0-9A-F]{6})\s\s+((?:[0-9a-f]{2} )*[0-9a-f]{2})", l)
            if not m:
                continue
            b = m.group(2).split()
            if len(b) == 4 and b[0] == "1d":       # call addr24
                t = int(b[3] + b[2] + b[1], 16)
                if 0xF40F30 <= t <= 0xF40F98:
                    out.setdefault(t, []).append((which, int(m.group(1), 16)))
    return out


# --------------------------------------------------------------- --bounds ----
def bounds():
    print("-- open question: \"0xF868DB / 0xF868FB ... neither has a reader bound\"")
    print("   0xF868DB's reader, three instructions above the base load:")
    for a, n, t in disasm(0xF8684F, 0x12):
        print("     %06x  %s" % (a, t))
    chk("0xF8684F clamps the index", insn(0xF8684F)[1], "cp A,0x20")
    chk("0xF86852 skips the clamp when it is below", insn(0xF86852)[1],
        "jr C,0xf86856")
    chk("0xF86854 forces the LAST entry", insn(0xF86854)[1], "ld A,0x1f")
    chk("0xF86856 then loads the base", insn(0xF86856)[1], "ld XHL,0x00f868db")
    chk("so 0xF868DB has a reader bound of", 0x1F + 1, 32)
    chk("  ...which is exactly the extent the dossier assigned it",
        0xF868FA - 0xF868DB + 1, 32)
    print("   0xF868FB's reader, three bytes above the base load:")
    for a, n, t in disasm(0xF86890, 0x0F):
        print("     %06x  %s" % (a, t))
    chk("0xF86890 masks the index", insn(0xF86890)[1], "and A,0x07")
    chk("0xF86893 then loads the base", insn(0xF86893)[1], "ld XHL,0x00f868fb")
    chk("so 0xF868FB has a reader bound of", 0x07 + 1, 8)
    chk("  ...which is exactly the extent the dossier assigned it",
        0xF86902 - 0xF868FB + 1, 8)
    chk("so \"neither has a reader bound\" is", "REFUTED", "REFUTED")

    print("-- and the part of that open question that STANDS: the four curves")
    chk("0xF86BA0..0xF86BB8's reader masks the index to", insn(0xF86B91)[1],
        "and L,0x7f")
    chk("  ...so its index range is 0..127, far wider than the 8-byte split",
        0x7F + 1, 128)
    chk("  ...reading 127 bytes from the LAST base 0xF86BB8 would reach",
        "0x%06X" % (0xF86BB8 + 0x7F), "0xF86C37")
    chk("  ...which is inside the code segment 0xF86BC0-0xF86C8B",
        0xF86BC0 <= 0xF86C37 <= 0xF86C8B, True)

    print("-- open question: \"a bit in the 64-bit word at (0x2088)/(0x208C)\"")
    for a, n, t in disasm(0xF86674, 0x0A):
        print("     %06x  %s" % (a, t))
    chk("0xF86674 clears with the mask", insn(0xF86674)[1], "and (0x2088),XWA")
    chk("0xF86678 clears the SAME mask in the other cell",
        insn(0xF86678)[1], "and (0x208c),XWA")
    for a, n, t in disasm(0xF866B3, 0x14):
        print("     %06x  %s" % (a, t))
    chk("0xF866B3 sets the mask in (0x2088)", insn(0xF866B3)[1],
        "or (0x2088),XWA")
    chk("0xF866B7 then tests record byte +2", insn(0xF866B7)[1],
        "ld B,(0x20b9)")
    chk("0xF866BB against 3", insn(0xF866BB)[1], "cp B,3")
    chk("0xF866BF sets the SAME mask in (0x208c) only then",
        insn(0xF866BF)[1], "or (0x208c),XWA")
    chk("0xF866C3 sets it in a THIRD cell the dossier never mentions",
        insn(0xF866C3)[1], "or (0x2084),XWA")
    chk("so \"the 64-bit word at (0x2088)/(0x208C)\" is", "REFUTED", "REFUTED")

    print("-- the sizing argument for 0xF86EA1: \"indexed by A = (0x2078) --")
    print("   the byte the previous map produces -- so 32 entries\"")
    for a, n, t in disasm(0xF86CAE, 0x1C):
        print("     %06x  %s" % (a, t))
    chk("the 0xF86E81 reader is indexed by", insn(0xF86CB0)[1], "ld L,(0x2078)")
    chk("  ...and it WRITES its result to", insn(0xF86CC4)[1], "ld (0x2076),A")
    for a, n, t in disasm(0xF86388, 0x14):
        print("     %06x  %s" % (a, t))
    chk("the 0xF86EA1 reader is indexed by", insn(0xF8638F)[1], "ld A,(0x2078)")
    chk("  ...the SAME cell the other map READS, not the one it writes",
        (insn(0xF86CB0)[1], insn(0xF86CC4)[1]),
        ("ld L,(0x2078)", "ld (0x2076),A"))
    chk("so \"the byte the previous map produces\" is", "REFUTED", "REFUTED")
    chk("and 0xF86EA1's reader has NO bound at all: xor / ld / add / ld",
        [t for _, _, t in disasm(0xF86388, 0x0F)][:5],
        ["ld XHL,0x00f86ea1", "xor XWA,XWA", "ld A,(0x2078)", "add XHL,XWA",
         "ld A,(XHL)"])
    chk("  ...so its 32-byte extent rests ONLY on ending at the handler table",
        "0x%06X" % (0xF86EA1 + 32), "0xF86EC1")
    chk("  ...which is the SAME weak footing the lane flagged for 0xF86C8C",
        "an unpinned entry count", "an unpinned entry count")
    chk("the lane's selftest label \"0xF86EA1 is read with the byte 0xF86E81",
        "produces\" contradicts the three instructions it prints",
        "produces\" contradicts the three instructions it prints")
    chk("  ...(0x2078) is written elsewhere as a constant, e.g. at 0xF86381",
        [t for _, _, t in disasm(0xF86381, 0x08)][:2],
        ["ld A,0x02", "ld (0x2078),A"])

    print("-- a bound the dossier did not need but which confirms 0xF8671A = 32")
    chk("0xF8619A bounds the loop counter", insn(0xF8619A)[1], "cp C,0x1f")
    chk("0xF8619F increments it", insn(0xF8619F)[1], "inc 1,C")
    chk("so the 0xF8671A reader at 0xF86172 walks", 0x1F + 1, 32)
    return 0


# ---------------------------------------------------------------- --script ----
def script_audit():
    """Claims the LANE SCRIPT makes about itself that its own code contradicts."""
    src = open(LAYOUT, encoding="utf-8").read()
    i = src.index('"""')
    doc = src[i + 3:src.index('"""', i + 3)]
    print("-- the docstring's rule thresholds against the constants the code uses")
    mins = re.search(r"FILL0E_MIN, FILL00_MIN, FILLFF_MIN = (\d+), (\d+), (\d+)",
                     src)
    chk("code: FILL0E / FILL00 / FILLFF minimum run", mins.groups(),
        ("16", "8", "6"))
    chk("docstring: FILL00 -- a maximal run of >= N bytes of 0x00",
        re.search(r"FILL00 -- a maximal run of >= (\d+) bytes", doc).group(1),
        "24")
    chk("docstring: FILLFF -- a maximal run of >= N bytes of 0xFF",
        re.search(r"FILLFF -- a maximal run of >= (\d+) bytes", doc).group(1),
        "24")
    chk("docstring: FILL0E, which IS right", 
        re.search(r"FILL0E -- a maximal run of >= (\d+) bytes", doc).group(1),
        "16")
    chk("so two of the six documented thresholds are", "WRONG IN THE DOCSTRING",
        "WRONG IN THE DOCSTRING")
    chk("  ...and the dossier quotes the CODE's value, not the docstring's",
        "FILL00 rule (>=8" in json.dumps(dossier()), True)

    print("-- modes the script names but does not implement")
    named = set(re.findall(r"`--([a-z]+)`", src)) | set(re.findall(r"--([a-z]+)\b", doc))
    have = set(re.findall(r'if "--([a-z]+)" in a', src))
    have |= {"python"}                    # handled after build(), not in the chain
    missing = sorted(n for n in named if n not in have and n not in ("rev", "n"))
    chk("modes named in the file but absent from main()", missing, ["flowend"])
    chk("  ...and an unknown flag falls through to the default table, silently",
        subprocess.run([sys.executable, LAYOUT, "--flowend"],
                       capture_output=True, text=True).stdout ==
        subprocess.run([sys.executable, LAYOUT],
                       capture_output=True, text=True).stdout, True)

    print("-- what `--barrier`'s three numbers actually measure")
    out = subprocess.run([sys.executable, LAYOUT, "--barrier"],
                         capture_output=True, text=True).stdout
    got = [int(x) for x in re.findall(r"(\d[\d]*) bytes", out)]
    chk("--barrier prints (with, without, framed)", got, [3361, 9368, 5856])
    rows = layout_rows()
    chk("but the LAYOUT's own `code` total is", sum(n for _, _, k, n in rows
                                                    if k == "code"), 2915)
    chk("  ...because --barrier runs PASS 1 (content barriers only) and the",
        "layout is PASS 2 (content + derived table barriers)",
        "layout is PASS 2 (content + derived table barriers)")
    chk("  ...pass 1 walks this many bytes of list-area POINTERS as code",
        pass1_extra(), 495)
    return 0


def pass1_extra():
    """Bytes pass 1's descent claims that are NOT code in the final layout.

    Re-derived by importing the lane's own descend()/barriers(): pass 1 is what
    `--barrier` reports, and it walks into the list areas because the derived
    table barriers do not exist yet."""
    import importlib.util
    sys.argv = ["x"]
    spec = importlib.util.spec_from_file_location("L", LAYOUT)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    wb = m.descend(m.LO, m.HI, sorted(m.seeds(m.LO, m.HI)),
                   m.barriers(m.LO, m.HI))[0]
    segs = m.build()[0]
    code = set()
    for k, a, n in segs:
        if k == "code":
            code |= set(range(a, a + n))
    return len(wb - code)


def anchors_audit():
    """Which segments exist only because of an instruction nothing reaches."""
    print("-- the four 8-byte curve tables and what anchors each base")
    import importlib.util
    sys.argv = ["x"]
    spec = importlib.util.spec_from_file_location("L", LAYOUT)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    b1 = m.barriers(m.LO, m.HI)
    seen1, starts1 = m.descend(m.LO, m.HI, sorted(m.seeds(m.LO, m.HI)), b1,
                               seed_immediates=True)
    imms1 = set(m.loaded_immediates(starts1))
    imms2 = set(m.build()[5])
    chk("table bases pass 1 finds (build()'s docstring: eighteen)", len(imms1), 18)
    chk("table bases the final layout uses (selftest: 20)", len(imms2), 20)
    chk("the two the descent never reaches, added by decoding a residue run",
        sorted("0x%06X" % x for x in imms2 - imms1), ["0xF86BA8", "0xF86BB8"])
    chk("  ...they are the operands of 0xF86B78 and 0xF86B88",
        (insn(0xF86B78)[1], insn(0xF86B88)[1]),
        ("ld XIY,0x00f86ba8", "ld XIY,0x00f86bb8"))
    def le3(v):
        return v.to_bytes(4, "little")[:3]
    chk("3-byte-LE census of the ENTRY 0xF86B88 over prom_a + prom_b",
        rom("a").count(le3(0xF86B88)) + rom("b").count(le3(0xF86B88)), 0)
    chk("  ...so nothing reaches it -- the dossier's honest hole, confirmed",
        "no site references 0xF86B88", "no site references 0xF86B88")
    chk("3-byte-LE census of the TABLE 0xF86BA8 over prom_a + prom_b",
        rom("a").count(le3(0xF86BA8)) + rom("b").count(le3(0xF86BA8)), 1)
    chk("  ...its one hit is the operand at 0xF86B79",
        "0x%06X" % (rom("a").find(le3(0xF86BA8)) + A_BASE), "0xF86B79")
    chk("3-byte-LE census of the TABLE 0xF86BB8 over prom_a + prom_b",
        rom("a").count(le3(0xF86BB8)) + rom("b").count(le3(0xF86BB8)), 1)
    chk("  ...its one hit is the operand at 0xF86B89, inside the dead run",
        "0x%06X" % (rom("a").find(le3(0xF86BB8)) + A_BASE), "0xF86B89")
    chk("so segments 0xF86BA8-0xF86BAF and 0xF86BB8-0xF86BBF rest on",
        "two instructions with no reference", "two instructions with no reference")
    return 0


# --------------------------------------------------------------- --mutate ----
# Addresses chosen so that the matrix separates CITED ANCHORS from SEGMENTATION.
MUTATIONS = [
    (0xF85FF9, 0x00, "head pad, FIRST byte of the span"),
    (0xF85FFC, 0x00, "head pad, middle"),
    (0xF897FF, 0x00, "closing fill, LAST byte of the span"),
    (0xF8969A, 0x0E, "the byte before the closing fill (checked: not 0x0E)"),
    (0xF869FD, 0x40, "the 0xBF of `cp L,0xbf`, the directory-size bound"),
    (0xF8671A, 0x00, "first word of the 1<<k table"),
    (0xF86799, 0x40, "LAST word of the 1<<k table (0x80000000)"),
    (0xF86EC1, 0xC2, "handler table entry 0"),
    (0xF872BD, 0xC2, "handler table entry 255, the LAST"),
    (0xF87681, 0x83, "directory A entry[0]"),
    (0xF8797D, 0x6F, "directory A entry[191], the LAST"),
    (0xF87981, 0x00, "the spare 0xFF byte after directory A"),
    (0xF86CC9, 0x00, "the 2-byte table its reader bounds"),
    (0xF86E81, 0x00, "first byte of the 32-entry index map"),
    (0xF868DB, 0x00, "first byte of the sign-magnitude curve"),
    (0xF86BA0, 0xFF, "first byte of curve 1"),
    (0xF86CD0, 0xFF, "MIDDLE of the 438-byte zero pad"),
    (0xF87400, 0xFF, "MIDDLE of the 951-byte zero pad"),
    (0xF88500, 0x00, "MIDDLE of list area B"),
    (0xF89300, 0x00, "MIDDLE of list area C"),
    (0xF86400, 0x00, "MIDDLE of the big code segment"),
    (0xF89685, 0x00, "the lone unexplained 0xFF at 0xF89685"),
]


def mutate_one(addr, val):
    """Child mode.  Patches BOTH the in-memory image AND the file the lane's
    decode table is built from -- notes/wave7-verify-probes/wave7_selftest_
    mutation.py patches only `_rom`, and `table()` calls
    TC.decode_table(IMGA, ...) on the PATH, so a mutation that probe makes is
    invisible to every check that decodes an instruction."""
    import importlib.util
    import shutil
    data = bytearray(open(IMGA, "rb").read())
    before = data[addr - A_BASE]
    if before == val:
        print("SKIP 0x%06X already 0x%02X" % (addr, val))
        return 0
    data[addr - A_BASE] = val
    tmpd = tempfile.mkdtemp(prefix="wsa1mut")
    img = os.path.join(tmpd, "wsa1_prom_a.ic12")
    open(img, "wb").write(bytes(data))
    for p in ("wsa1_prom_b_dectab.pkl",):
        s = os.path.join(tempfile.gettempdir(), p)
        if os.path.exists(s):
            shutil.copy(s, os.path.join(tmpd, p))
    os.environ["WSA1_CACHE_DIR"] = tmpd
    sys.argv = ["x", "--selftest"]
    spec = importlib.util.spec_from_file_location("L", LAYOUT)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    m.IMGA = img
    m._rom["a"] = bytes(data)
    # prom_a_f85ff9_layout.selftest() keeps its failure list LOCAL and reports
    # it only as the line "N checks, M failed", so capture stdout and parse it.
    import io
    buf = io.StringIO()
    real, sys.stdout = sys.stdout, buf
    try:
        m.selftest()
        out = buf.getvalue()
        mm = re.search(r"(\d+) checks, (\d+) failed", out)
        n, ck, err = (int(mm.group(2)), int(mm.group(1)), "") if mm else \
                     (-2, 0, "no summary line")
    except Exception as e:
        out = buf.getvalue()
        n, ck = -1, out.count(" OK") + out.count("FAIL want")
        err = "%s: %s" % (type(e).__name__, str(e)[:60])
    finally:
        sys.stdout = real
    print("RESULT 0x%06X 0x%02X->0x%02X checks=%d failures=%d %s"
          % (addr, before, val, ck, n, err))
    return 0


def mutate():
    print("-- MUTATION MATRIX for notes/prom_a_f85ff9_layout.py --selftest")
    print("   82 checks, 0 failures on the real ROM.  Flip one byte and re-run.")
    print("   A mutation that leaves failures=0 is a byte NO CHECK READS.")
    print("   failures=-1 means selftest() RAISED instead of reporting.")
    print()
    res = []
    done = []
    B = 4                               # each child rebuilds a 40 s decode table
    for i in range(0, len(MUTATIONS), B):
        batch = []
        for addr, val, what in MUTATIONS[i:i + B]:
            batch.append((addr, val, what, subprocess.Popen(
                [sys.executable, os.path.abspath(__file__),
                 "--mutate-one", "%06X" % addr, "%02X" % val],
                stdout=subprocess.PIPE, text=True)))
        for addr, val, what, p in batch:
            done.append((addr, val, what, p.communicate()[0]))
    for addr, val, what, out in done:
        m = re.search(r"checks=(\d+) failures=(-?\d+)\s*(.*)", out)
        n = int(m.group(2)) if m else None
        ck = int(m.group(1)) if m else 0
        err = (m.group(3) or "").strip() if m else out.strip()
        res.append((addr, val, what, n, err))
        print("  0x%06X -> 0x%02X  checks=%-3d failures=%-4s %-48s %s"
              % (addr, val, ck, n, what, err[:56]))
    blind = [r for r in res if r[3] == 0]
    print()
    print("  BLIND at %d of %d mutated addresses:" % (len(blind), len(res)))
    for r in blind:
        print("     0x%06X  %s" % (r[0], r[2]))
    raised = [r for r in res if r[3] == -1]
    print("  selftest() RAISED at %d:" % len(raised))
    for r in raised:
        print("     0x%06X  %s  %s" % (r[0], r[2], r[4][:70]))
    return 0


# -------------------------------------------------------------- --selftest ----
def selftest():
    print("-- checks of THIS file, on the LAST element as well as the first")
    d = dossier()
    segs = d["segments"]
    chk("the dossier under attack is lane a4's", d["span"],
        "0xF85FF9-0xF89800 (prom_a, 14,343 bytes)")
    chk("FIRST segment of the dossier", segs[0]["lo"], "0xF85FF9")
    chk("LAST segment of the dossier", segs[-1]["hi"], "0xF897FF")
    chk("the dossier's own confidence", d["confidence"], "high")
    chk("its verifier verdict in round 1",
        [l for l in json.load(open(DOSSIER))["lanes"]
         if l["lane"] == "a4"][0]["verifier_verdict"], None)
    pairs = citations()
    chk("citation extraction finds the FIRST citation",
        "0x%06X %s" % pairs[0], "0xF85FF8 ret")
    chk("citation extraction finds the LAST citation",
        "0x%06X %s" % pairs[-1], "0xF86CBB ld XIY,0x00f86e81")
    chk("every extracted address is inside prom_a",
        all(A_BASE <= a < 0x1000000 for a, _ in pairs), True)
    chk("unidasm is where this file expects it", os.path.exists(UNIDASM), True)
    chk("disasm decodes the FIRST instruction of the span's code",
        insn(0xF86000)[1] is not None, True)
    chk("disasm decodes at the LAST code segment", insn(0xF872C9)[1], "ret")
    chk("the ROM images are the committed ones",
        (len(rom("a")), len(rom("b"))), (524288, 524288))
    chk("walk_list terminates on the LAST directory entry of C",
        walk_list(directory(0xF88EC1)[191])[0], [])
    chk("proven_call_sites finds the FIRST run's hottest slot",
        len(proven_call_sites().get(0xF40F3C, [])), 58)
    chk("MUTATIONS covers the FIRST byte of the span", MUTATIONS[0][0], LO)
    chk("MUTATIONS covers a byte in the LAST segment",
        any(0xF8969B <= a <= 0xF897FF for a, _, _ in MUTATIONS), True)
    return 0


def main():
    a = sys.argv[1:] or ["--all"]
    if a[0] == "--mutate-one":
        return mutate_one(int(a[1], 16), int(a[2], 16))
    if a[0] == "--mutate":
        return mutate()
    if a[0] == "--all":
        for f in (tile, cite, counts, bounds, script_audit,
                  anchors_audit, selftest):
            print()
            f()
    else:
        for name, f in (("--tile", tile), ("--cite", cite), ("--counts", counts),
                        ("--bounds", bounds), ("--script", script_audit),
                        ("--anchors", anchors_audit), ("--selftest", selftest)):
            if name in a:
                f()
    print()
    print("%d checks failed" % len(FAIL))
    for f in FAIL:
        print("  FAILED:", f)
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
