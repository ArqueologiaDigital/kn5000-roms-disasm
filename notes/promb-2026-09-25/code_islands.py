#!/usr/bin/env python3
r"""prom_b: eleven small objects in the 0xF65000-0xF77FFF layers that are code, not data.

QUESTION THIS ANSWERS
    The 2026-09-25 worklist's "code-suspect data regions" and the labels the
    branch symboliser hung under data names (`Data_F71126_Code_Skip`, ...) point
    at objects the module layouts framed as bytes.  For each one this script
    re-derives, from the ROM, the evidence that the bytes are instructions:

      FALLTHROUGH  the instruction before it is a CONDITIONAL branch, so the
                   CPU runs into these bytes whenever the condition fails;
      CALLED       a `calr` targets the object's first byte, and the source's
                   framing splits a real instruction there (a MISFRAME);
      SIBLING      nothing branches or points to it (all of prom_b searched:
                   jr/jrl/calr displacements, jp/call/24-bit operands), but the
                   decode ends exactly on the instruction boundary the source
                   already has after it, and its operands match the code
                   beside it -- recorded as unreached code, with that stated.

    Every island must decode (notes/llvm_roundtrip_autoforce.py, an llvm-mc
    round trip against the ROM) to instructions that END exactly where the
    source's next instruction line starts, and unidasm's rendering is kept in
    each line's comment.

RUN
    python3 notes/promb-2026-09-25/code_islands.py            # checks
    python3 notes/promb-2026-09-25/code_islands.py --apply    # write the source
    python3 scripts/converters/symbolize_numeric_branches.py --image prom_b \
        --only prom_b/wsa1_prom_b.s --apply --verify
    python3 scripts/converters/symbolize_wsa1_rom_addresses.py --arms --offsets --apply --verify
    make gate-wsa1
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import effect_paint_jobs as EPJ     # noqa: E402  (transcription, respelling, assembly check)

SRC, Rom, check, FAIL = EPJ.SRC, EPJ.Rom, EPJ.check, EPJ.FAIL
BASE = 0xF00000
STRUCT = re.compile(r'_(Skip|Join|Loop|Sub|Return|Epilogue|Entry|Helper|Resume)\d*$')

# (lo, hi, old data label or None, kind, parent routine, note)
ISLANDS = [
    (0xF71126, 0xF7113D, "Data_F71126", "FALLTHROUGH", "sub_F710E7",
     "the overflow arm of `jr nov` at 0xF71124: `push WA / ld WA,DE / ld DE,1 / ld HL,(0x107C) "
     "/ ld QWA,DE / div XWA,HL / ld DE,QWA / add (0x1086),WA / pop WA` -- the same divide-and-"
     "accumulate the routine runs just above it"),
    (0xF712D7, 0xF712DD, "Data_F712D7", "FALLTHROUGH", "sub_F712B6",
     "the no-overflow arm of `jr ov` at 0xF712D5: `cp WA,0x2FFF / jr ...`"),
    (0xF765FA, 0xF765FC, "Data_F765FA", "FALLTHROUGH", "sub_F765E6",
     "the overflow arm of `jr nov` at 0xF765F8"),
    (0xF77D5F, 0xF77D61, "Data_F77D5F", "FALLTHROUGH", "sub_F77D4B",
     "the overflow arm of `jr nov` at 0xF77D5D; the same two bytes as 0xF765FA"),
    (0xF7208D, 0xF72092, None, "CALLED", "sub_F7208D",
     "`calr sub_F7208D` at 0xF71E09 lands on `ld XIY,0x0000305A` (45 5A 30 00 00); the source "
     "had `.byte 0x45, 0x5A` and a `ld WA,0` framed from 0xF7208F, inside it.  The loop below "
     "walks XIY from 0x305A in 7-byte steps to 0x313A"),
    (0xF731FB, 0xF731FD, None, "CALLED", "sub_F731FB",
     "`calr sub_F731FB` at 0xF73004 lands on `xor C,C` (CB D3), which the source carried as "
     "`.byte`"),
    (0xF72074, 0xF7207C, "Data_F72074", "SIBLING", None,
     "`cp (0x1239),0xFF / jrl Z,0xF71EB1` -- the jrl lands on an instruction start of this "
     "source (0xF71EB1), and the decode ends on the `ret` the jr above targets"),
    (0xF701E8, 0xF701F0, "Data_F701E8", "SIBLING", None,
     "`cp (0x1239),0xFF / jrl Z,0xF70031` -- the same shape as 0xF72074; 0xF70031 is an "
     "instruction start of this source"),
    (0xF6D8EE, 0xF6D8F3, "Data_F6D8EE", "SIBLING", None,
     "`ld XIY,0x00F6D960` -- Text_PBendMod1ExpPMemAftOnoff + 0x4B, three bytes past the + 0x48 "
     "the parallel arm loads at 0xF6D8E7, and the decode ends on the join both arms reach"),
    (0xF65DCC, 0xF65DD2, "Data_F65DCC", "SIBLING", None,
     "`ld A,0x55 / ld W,(0x0C03)` beside the arm that sets A = 0xAA; (0x0C03) is the cell the "
     "routine compares A with at its entry (0xF65DAE); the decode ends on the `ret` the jr "
     "above targets"),
    (0xF65DF1, 0xF65DF7, "Data_F65DF1", "SIBLING", None,
     "the same six bytes as 0xF65DCC, in the next routine"),
]


def branch_refs(rom, t):
    """Every jr/jrl/calr/jp/call in prom_b whose target is t, and every 24-bit spelling of t."""
    b = rom.b
    hits = []
    for i in range(len(b) - 4):
        op, a = b[i], BASE + i
        if 0x60 <= op <= 0x6F:
            d = b[i + 1] - 256 if b[i + 1] > 127 else b[i + 1]
            if a + 2 + d == t:
                hits.append(a)
        elif 0x70 <= op <= 0x7F or op == 0x1E:
            d = b[i + 1] | b[i + 2] << 8
            d = d - 65536 if d > 32767 else d
            if a + 3 + d == t:
                hits.append(a)
        elif op in (0x1B, 0x1D) and (b[i + 1] | b[i + 2] << 8 | b[i + 3] << 16) == t:
            hits.append(a)
    return hits, len(rom.find_all(t.to_bytes(3, "little")))


def source_lines():
    L = open(SRC, "rb").read().decode("latin-1").split("\n")
    addr = {}
    for i, t in enumerate(L):
        m = re.search(r'; ([0-9A-F]{6})  ', t)
        if m and not t.startswith(";"):
            addr[i] = int(m.group(1), 16)
    return L, addr


def derive(rom):
    L, addr = source_lines()
    starts = set(addr.values())
    out = []
    for lo, hi, old, kind, parent, note in ISLANDS:
        rows = EPJ.house_island(rom, lo, hi)          # asserts the round trip line by line
        check("0x%06X-0x%06X decodes to %d instructions ending exactly at 0x%06X, an instruction "
              "line of the source" % (lo, hi - 1, len(rows), hi), hi in starts)
        refs, n24 = branch_refs(rom, lo)
        if kind == "FALLTHROUGH":
            prev = max(a for a in starts if a < lo)
            op = rom.at(prev, 1)[0]
            check("  0x%06X is reached by fallthrough: the instruction before it (0x%06X) is a "
                  "conditional jr (%02X) that ends at 0x%06X" % (lo, prev, op, prev + 2),
                  0x61 <= op <= 0x6F and op != 0x68 and prev + 2 == lo)
        elif kind == "CALLED":
            check("  0x%06X is a calr target (%s)" % (lo, ", ".join("0x%06X" % r for r in refs)),
                  bool(refs))
        else:
            check("  0x%06X is referenced by nothing: no jr/jrl/calr/jp/call targets it and its "
                  "24-bit spelling occurs %d times" % (lo, n24), not refs and n24 == 0)
        out.append(dict(lo=lo, hi=hi, old=old, kind=kind, parent=parent, note=note, rows=rows))
    # the SIBLING notes' specific claims
    for jrl_at, tgt in ((0xF72079, 0xF71EB1), (0xF701ED, 0xF70031)):
        d = rom.at(jrl_at + 1, 2)
        d = int.from_bytes(d, "little", signed=True)
        check("  jrl at 0x%06X targets 0x%06X, an instruction line of the source"
              % (jrl_at, jrl_at + 3 + d), jrl_at + 3 + d == tgt and tgt in starts
              and rom.at(jrl_at, 1)[0] == 0x76)
    a1 = int.from_bytes(rom.at(0xF6D8E8, 4), "little")
    a2 = int.from_bytes(rom.at(0xF6D8EF, 4), "little")
    check("  0xF6D8E7 loads XIY = 0x%06X and 0xF6D8EE XIY = 0x%06X: three bytes apart" % (a1, a2),
          rom.at(0xF6D8E7, 1) == b"\x45" and rom.at(0xF6D8EE, 1) == b"\x45" and a2 - a1 == 3)
    check("  0xF65DAE starts `cp A,(0x0C03)` (c1 03 0c f1) -- the cell the 0xF65DCC arm reads",
          rom.at(0xF65DAE, 4).hex() == "c1030cf1" and rom.at(0xF65DCE, 4).hex() == "c1030c20")
    return out


def enclosing(L, i):
    j = i
    while j >= 0:
        m = re.match(r'^([A-Za-z_]\w*):', L[j])
        if m and not STRUCT.search(m.group(1)) and "_Code_" not in m.group(1) \
                and not m.group(1).startswith(("Data_", "ByteMap_")):
            return m.group(1)
        j -= 1
    return None


def wrap(text, first=";   ", cont=";   ", width=96):
    import textwrap
    return textwrap.wrap(text, width=width, initial_indent=first, subsequent_indent=cont,
                         break_long_words=False, break_on_hyphens=False)


def apply(isl):
    L, addr = source_lines()
    renames = {}
    for it in reversed(isl):
        lo, hi = it["lo"], it["hi"]
        idx = sorted(i for i, a in addr.items() if lo <= a < hi)
        first, last = idx[0], idx[-1]
        s = first
        # swallow the old data label and its header block, but keep a CALLED routine's label
        while s > 0 and (L[s - 1].startswith(";") or not L[s - 1].strip() or
                         (it["old"] and L[s - 1].startswith(it["old"] + ":"))):
            s -= 1
        while s < first and not L[s].strip():
            s += 1
        parent = it["parent"] or enclosing(L, s - 1)
        it["parent"] = parent
        new = []
        if it["old"]:
            new += ["; " + "-" * 74,
                    "; %s CODE, not data (was `OLD<<%s>>`), part of %s:" % (
                        {"FALLTHROUGH": "REACHED", "CALLED": "CALLED",
                         "SIBLING": "UNREACHED"}[it["kind"]], it["old"].replace("_", "@"), parent)]
            new += wrap(it["note"] + ".")
            if it["kind"] == "SIBLING":
                new += wrap("Nothing in prom_b branches to, calls or spells 0x%06X "
                            "(code_islands.py searches every jr/jrl/calr displacement and "
                            "jp/call/24-bit operand); it is recorded as code because it decodes "
                            "as such and fits the code beside it, not because it runs." % lo)
            new += ["; " + "-" * 74]
        else:
            new += wrap(it["note"] + ".", first="; ", cont=";   ")
        for a, h, text in it["rows"]:
            new.append("\t%s\t; %06X  %s" % (h, a, text))
        # lines between `first` and `last` that are labels at instruction starts inside the island
        for k in range(first, last + 1):
            m = re.match(r'^([A-Za-z_]\w*):', L[k])
            if m and m.group(1) != it["old"] and m.group(1) != parent:
                raise SystemExit("label %s inside island 0x%06X" % (m.group(1), lo))
        new = [x.encode("utf-8").decode("latin-1") for x in new]
        if it["old"] is None:
            # keep the routine label line (it is directly above `first`)
            assert L[first - 1].startswith(parent + ":"), (parent, L[first - 1])
        L = L[:s] + new + L[last + 1:]
        L, addr = L, None
        txt = "\n".join(L)
        L, addr = [x for x in txt.split("\n")], {}
        for i, t in enumerate(L):
            m = re.search(r'; ([0-9A-F]{6})  ', t)
            if m and not t.startswith(";"):
                addr[i] = int(m.group(1), 16)
        prefix = (it["old"] or {"sub_F7208D": "ByteMap_F7207D", "sub_F731FB": "ByteMap_F731DB"}
                  [parent]) + "_Code_"
        renames[prefix] = parent
    txt = "\n".join(L)
    existing = set(re.findall(r'^([A-Za-z_]\w*):', txt, re.M))
    for prefix, parent in renames.items():
        for lab in sorted(set(re.findall(r'\b(%s\w+)\b' % re.escape(prefix), txt))):
            base = re.sub(r'\d+$', '', lab[len(prefix):])
            k = 1
            while True:
                cand = "%s_%s%s" % (parent, base, "" if k == 1 else k)
                if cand not in existing:
                    break
                k += 1
            existing.add(cand)
            txt = re.sub(r'\b%s\b' % re.escape(lab), cand, txt)
            print("  %-34s -> %s" % (lab, cand))
    txt = re.sub(r'OLD<<(\w+?)@(\w+)>>', lambda m: m.group(1) + "_" + m.group(2), txt)
    data = txt.encode("latin-1")
    open(SRC, "wb").write(data)
    print("wrote", SRC)


def main():
    rom = Rom()
    isl = derive(rom)
    if FAIL:
        print("\nVERDICT: FAIL (%d)" % len(FAIL))
        return 1
    if "--apply" in sys.argv:
        apply(isl)
    print("\nVERDICT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
