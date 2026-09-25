#!/usr/bin/env python3
r"""gen_hdae5000_ui_pool.py -- the HD-AE5000 UI object descriptor pool as typed records.

QUESTION ANSWERED / JOB IT DOES
-------------------------------
The 33,050-byte pool at 0x29DC12-0x2A5D2B (header "HD-AE5000 UI OBJECT
DESCRIPTOR POOL" in hdae5000/hdae5000_data_tables.s) is 769 variable-length UI
object descriptors, located by the .long entries of HDAE5000_UiObject_PtrTable
(read at boot by RegisterObjectTable, "Handler 10").  Until this script it was
written as byte noise -- `.asciz "("`, `.byte 0xb9 ; "¹"`, `.balign` "pads"
that were really the high bytes of u16 fields.  This script re-expresses it
record by record, from the ROM, with every field typed as far as it is
established:

  +0x00 .long  class id                      (header block, "class id")
  +0x04 .short parent, first child, next sibling, previous sibling (indices)
  +0x0C .short attribute word                 (undecoded)
  +0x0E .short x1, y1, x2, y2                  (bounding box, screen pixels)
  +0x16 ...    class body: .short words (undecoded), except
               - caption slots (13 classes; 329 slots, every one pointing into
                 its own record) -> `.long HdaeUiObj_NNN_CapXX`, and
               - RAM slots: body offsets where EVERY record of the class holds
                 a 0x200000-0x23FFFF address -> `.long 0x...` (RAM address)
  tail         the captions, `.asciz`, labelled, each word-aligned with at
               most one 0x00 pad byte (between two captions or at the end)

and rewrites HDAE5000_UiObject_PtrTable's 769 pool entries as
`.long HdaeUiObj_NNN`.  The layout facts are the pool header's, each printed by
analysis/wave7-probes/verify_hdae5000_ui_pool.py; this script re-derives the
ones it relies on and REFUSES (exit 1) unless they still hold:
  * the 769 pool pointers ascend and tile 0x29DC12-0x2A5D2B exactly;
  * every caption slot points inside its own record, at a NUL-terminated run;
  * the generated records, byte-modelled here, equal the ROM byte for byte.

RUN (from the repo root)
    python3 scripts/generators/gen_hdae5000_ui_pool.py            # check only
    python3 scripts/generators/gen_hdae5000_ui_pool.py --write    # rewrite the source
Then `make gate` -- the assembler, not this model, is the final word.
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "hdae5000", "hdae5000_data_tables.s")
ROM = open(os.path.join(ROOT, "original_ROMs", "hd-ae5000_v2_06i.ic4"), "rb").read()
BASE = 0x280000
POOL, POOL_END = 0x29DC12, 0x2A5D2C
PTRTAB, NAMETAB, CLASSTAB = 0x2A5D2C, 0x2A6984, 0x2F9832
NOBJ = 789

u16 = lambda a: int.from_bytes(ROM[a - BASE:a - BASE + 2], "little")
u32 = lambda a: int.from_bytes(ROM[a - BASE:a - BASE + 4], "little")


def cstr(a):
    b = ROM[a - BASE:]
    return b[:b.index(0)]


# F = 22-byte header + class body, from the pool header's per-class table
F = {(0x0160, 0x10): 22, (0x0160, 0x12): 36, (0x0160, 0x1B): 58, (0x0160, 0x1C): 42,
     (0x0160, 0x1F): 40, (0x0160, 0x20): 44, (0x0160, 0x22): 42, (0x0160, 0x26): 40,
     (0x0160, 0x28): 28, (0x0160, 0x29): 26, (0x0160, 0x2B): 32, (0x0160, 0x2D): 26,
     (0x0160, 0x2E): 26, (0x0160, 0x30): 40, (0x0160, 0x33): 34, (0x0160, 0x35): 36,
     (0x0160, 0x36): 40, (0x0160, 0x37): 38, (0x0160, 0x3D): 50, (0x0160, 0x3E): 44,
     (0x0160, 0x3F): 46, (0x0160, 0x41): 54, (0x0160, 0x46): 22, (0x0160, 0x49): 26,
     (0x0160, 0x4B): 36, (0x0160, 0x4C): 64, (0x0160, 0x4D): 26, (0x0160, 0x52): 26,
     (0x0160, 0x69): 26, (0x016A, 0x0): 60, (0x016A, 0x1): 26, (0x016A, 0x2): 42,
     (0x016A, 0x3): 36, (0x016A, 0x4): 26, (0x016A, 0x6): 42, (0x016A, 0x7): 42,
     (0x016A, 0x8): 36, (0x016A, 0x9): 34, (0x016A, 0xA): 42, (0x016A, 0xB): 46,
     (0x016A, 0xC): 32}
CAP = {(0x0160, 0x1B): [0x1C], (0x0160, 0x26): [0x1E, 0x1A], (0x0160, 0x2B): [0x16],
       (0x0160, 0x30): [0x16], (0x0160, 0x36): [0x1A], (0x0160, 0x37): [0x1A],
       (0x0160, 0x3D): [0x2A], (0x0160, 0x3E): [0x28], (0x0160, 0x3F): [0x2A],
       (0x0160, 0x41): [0x2A], (0x016A, 0x2): [0x22], (0x016A, 0x6): [0x22],
       (0x016A, 0x7): [0x22]}
# labels that init_data.s's .set lines and the five misnomers need, by address
EXTRA_NOTE = {}


def fail(msg):
    sys.exit("REFUSED: " + msg)


def esc(bs):
    out = []
    for c in bs:
        if c == 0x22:
            out.append('\\"')
        elif c == 0x5C:
            out.append("\\\\")
        elif 0x20 <= c < 0x7F:
            out.append(chr(c))
        else:
            out.append("\\%03o" % c)
    return "".join(out)


def model():
    ptr = [u32(PTRTAB + 4 * i) for i in range(NOBJ)]
    if u32(PTRTAB + 4 * NOBJ) != 0:
        fail("pointer table terminator")
    names = [cstr(u32(NAMETAB + 4 * i)).decode("latin-1") if u32(NAMETAB + 4 * i) else ""
             for i in range(NOBJ)]
    idx = [i for i, p in enumerate(ptr) if POOL <= p < POOL_END]
    S = [ptr[i] for i in idx]
    if len(S) != 769 or S[0] != POOL or any(S[k] >= S[k + 1] for k in range(len(S) - 1)):
        fail("pool pointers do not ascend from 0x%06X" % POOL)
    E = S[1:] + [POOL_END]
    cls = {}
    for k in range(13):
        a = u32(CLASSTAB + 4 * k)
        cls[k] = cstr(a).decode("latin-1") if a else ""
    recs = []
    for i, s, e in zip(idx, S, E):
        c = (u16(s + 2), u16(s))
        if c not in F:
            fail("record #%d class %04X:%04X not in the class table" % (i, c[0], c[1]))
        recs.append(dict(i=i, s=s, e=e, c=c, n=e - s))
    # RAM slots: offsets where EVERY record of a class holds a RAM address
    bycls = collections.defaultdict(list)
    for r in recs:
        bycls[r["c"]].append(r)
    ram = {}
    for c, L in bycls.items():
        f = F[c]
        slots = []
        off = 0x16
        while off + 4 <= f:
            if off in CAP.get(c, []):
                off += 4
                continue
            if all(0x200000 <= u32(r["s"] + off) < 0x240000 for r in L):
                slots.append(off)
                off += 4
            else:
                off += 2
        ram[c] = slots
    return recs, names, cls, ram, ptr


def gen():
    recs, names, cls, ram, ptr = model()
    out = []
    emitted = bytearray()
    ncap = 0
    for r in recs:
        s, e, c, i = r["s"], r["e"], r["c"], r["i"]
        f = F[c]
        rec = ROM[s - BASE:e - BASE]
        lab = "HdaeUiObj_%03d" % i
        par = u16(s + 4)
        cname = ("ClassName_Table[%d] \"%s\"" % (c[1], cls.get(c[1], "?"))) if c[0] == 0x016A \
            else "KN5000 widget type 0x%02X" % c[1]
        nm = ('"%s"' % names[i]) if names[i] else "(unnamed)"
        pn = ("#%d%s" % (par, (" " + names[par]) if par < len(names) and names[par] else "")) \
            if par != 0xFFFF else "none (root)"
        out.append("\t; [#%d] %s  class %04X:%04X = %s, %d bytes, parent %s,"
                   % (i, nm, c[0], c[1], cname, e - s, pn))
        out.append("\t; box %d,%d-%d,%d.  Record layout and evidence: pool header above."
                   % (u16(s + 0x0E), u16(s + 0x10), u16(s + 0x12), u16(s + 0x14)))
        out.append(lab + ":")
        out.append("\t.long\t0x%08x\t\t\t\t; +0x00 class id" % u32(s))
        out.append("\t.short\t%s\t; +0x04 parent, first child, next, previous"
                   % ", ".join(("0xffff" if u16(s + o) == 0xFFFF else "%d" % u16(s + o))
                               for o in (4, 6, 8, 10)))
        out.append("\t.short\t0x%04x\t\t\t\t\t; +0x0C attribute word" % u16(s + 0x0C))
        out.append("\t.short\t%d, %d, %d, %d\t\t\t; +0x0E box x1, y1, x2, y2"
                   % tuple(u16(s + o) for o in (0x0E, 0x10, 0x12, 0x14)))
        caps = {}
        for off in CAP.get(c, []):
            t = u32(s + off)
            if not (s + f <= t < e):
                fail("#%d caption slot +0x%02X -> 0x%06X outside its caption arena" % (i, off, t))
            caps[off] = t
        body_end = f
        # the two documented exceptions: #127 carries a string past its class body,
        # #442 carries six 4-byte literals inside it (pool header notes 1 and 2)
        special = {}
        if i == 127:
            special["tail_labels"] = {s + 0x1A: "%s_Str1A" % lab}
        if i == 442:
            special["body_strings"] = {0x28: "HDAE5000_Str_CharSet_Upper_1", 0x2C: "HDAE5000_Str_CharSet_Upper_2",
                                       0x30: "HDAE5000_Str_CharSet_Lower_1", 0x34: "HDAE5000_Str_CharSet_Lower_2",
                                       0x38: "HDAE5000_Str_CharSet_Symbol_1", 0x3C: "HDAE5000_Str_CharSet_Symbol_2"}
        off = 0x16
        words = []

        def flush():
            if words:
                out.append("\t.short\t%s\t; +0x%02X class body" % (", ".join(w[1] for w in words), words[0][0]))
                words.clear()
        while off < body_end:
            if off in caps:
                flush()
                out.append("\t.long\t%s_Cap%02X\t\t\t; +0x%02X caption pointer" % (lab, off, off))
                off += 4
            elif off in ram[c]:
                flush()
                out.append("\t.long\t0x%08x\t\t\t\t; +0x%02X RAM address (every %04X:%04X record)"
                           % (u32(s + off), off, c[0], c[1]))
                off += 4
            elif off in special.get("body_strings", {}):
                flush()
                b4 = rec[off:off + 4]
                out.append("\t.ascii\t\"%s\"\t\t\t\t; +0x%02X %s (hdae5000_init_data.s)"
                           % (esc(b4), off, special["body_strings"][off]))
                off += 4
            else:
                words.append((off, "0x%04x" % u16(s + off)))
                if len(words) == 8:
                    flush()
                off += 2
        flush()
        # caption arena: NUL-terminated strings, then at most one pad byte
        a = s + body_end
        targets = {t: o for o, t in caps.items()}
        targets.update(special.get("tail_labels", {}))
        while a < e:
            if a % 2:
                if ROM[a - BASE] != 0:
                    fail("#%d odd-address pad byte not 0" % i)
                out.append("\t.balign\t2, 0x00\t\t\t\t\t; word-align pad (proven: see convert_align_pads.py header)")
                a += 1
                continue
            z = ROM.index(0, a - BASE) + BASE
            if z >= e:
                fail("#%d caption arena not NUL-terminated" % i)
            txt = ROM[a - BASE:z - BASE]
            if a in targets and isinstance(targets[a], int):
                name = "%s_Cap%02X" % (lab, targets[a])
                ncap += 1
                out.append("\t; caption of %s: the record's +0x%02X caption pointer names this string"
                           % (lab, targets[a]))
            elif a in targets:
                name = targets[a]
            else:
                fail("#%d arena string at +0x%02X is pointed to by nothing" % (i, a - s))
            out.append("%s:\t.asciz\t\"%s\"" % (name, esc(txt)))
            a = z + 1
        out.append("")
    return out, recs, names, ncap


def ptr_table(recs, old_rows):
    """Replace only the operand of each pool entry; the row comments stay."""
    by = {r["i"]: r for r in recs}
    rows = []
    for i, old in enumerate(old_rows):
        m = re.match(r'^(\t\.long\t)(?:0x([0-9A-Fa-f]{8})|HdaeUiObj_(\d{3}))(\s*;.*)$', old)
        ok = m and ((m.group(2) and int(m.group(2), 16) == u32(PTRTAB + 4 * i)) or
                    (m.group(3) and int(m.group(3)) == i))
        if not ok:
            fail("pointer table row %d is not `.long 0x%08X ; ...`: %r" % (i, u32(PTRTAB + 4 * i), old))
        rows.append(m.group(1) + ("HdaeUiObj_%03d" % i if i in by else "0x%08X" % u32(PTRTAB + 4 * i))
                    + m.group(4))
    return rows


def assemble_model(lines):
    """Byte model of the generated directives (only the forms gen() emits)."""
    labels, pend, out = {}, [], bytearray()
    for ln in lines:
        if ln.strip().startswith(";"):
            continue
        code = ln.split(";")[0] if '"' not in ln else ln
        m = re.match(r'^([A-Za-z_][\w]*):', code)
        if m:
            labels[m.group(1)] = POOL + len(out)
            code = code[m.end():]
        code = code.strip()
        if not code:
            continue
        if code.startswith(".long"):
            v = code.split(None, 1)[1].split(";")[0].strip()
            if v.startswith("0x"):
                out += int(v, 16).to_bytes(4, "little")
            else:
                pend.append((len(out), v))
                out += b"\0\0\0\0"
        elif code.startswith(".short"):
            for v in code.split(None, 1)[1].split(";")[0].split(","):
                out += int(v.strip(), 0).to_bytes(2, "little")
        elif code.startswith(".asciz") or code.startswith(".ascii"):
            s = re.search(r'"((?:[^"\\]|\\.)*)"', code).group(1)
            b = bytearray()
            k = 0
            while k < len(s):
                if s[k] == "\\":
                    if s[k + 1] in "01234567":
                        b.append(int(s[k + 1:k + 4], 8))
                        k += 4
                    else:
                        b.append(ord(s[k + 1]))
                        k += 2
                else:
                    b.append(ord(s[k]))
                    k += 1
            if code.startswith(".asciz"):
                b.append(0)
            out += b
        elif code.startswith(".balign"):
            if len(out) % 2:
                out.append(0)
        else:
            fail("model cannot size: %r" % ln)
    for at, name in pend:
        out[at:at + 4] = labels[name].to_bytes(4, "little")
    return bytes(out)


def main():
    lines, recs, names, ncap = gen()
    at = {r["i"]: r["s"] for r in recs}
    for k, v in {"HdaeUiObj_018": 0x29DF62, "HdaeUiObj_177": 0x29F978, "HdaeUiObj_645": 0x2A475C,
                 "HdaeUiObj_743": 0x2A560C, "HdaeUiObj_127": 0x29F15A}.items():
        if at[int(k[-3:])] != v:
            fail("%s is at 0x%06X, the notes say 0x%06X" % (k, at[int(k[-3:])], v))
    got = assemble_model(lines)
    want = ROM[POOL - BASE:POOL_END - BASE]
    if got != want:
        k = next(j for j in range(min(len(got), len(want))) if got[j] != want[j]) \
            if len(got) == len(want) else min(len(got), len(want))
        fail("byte model differs from the ROM at 0x%06X (len %d vs %d)" % (POOL + k, len(got), len(want)))
    nram = sum(1 for ln in lines if "RAM address (every" in ln)
    print("pool model == ROM: 769 records, %d bytes, %d caption labels, %d RAM-address slots"
          % (len(got), ncap, nram))
    if "--write" not in sys.argv[1:]:
        return
    src = open(SRC, encoding="latin-1").read().split("\n")
    s = next(k for k, l in enumerate(src) if l.startswith("\t; 0x29DC12  POOL START"))
    e = next(k for k, l in enumerate(src) if l.startswith("; HD-AE5000 UI OBJECT TABLE (0x2A5D2C"))
    e -= 1                                  # the '; ====' rule above that title
    while src[e - 1].strip() == "":
        e -= 1
    old = src[s:e]
    keep_notes = extract_notes(old)
    new = weave(lines, keep_notes)
    while new and new[-1] == "":
        new.pop()
    t0 = next(k for k, l in enumerate(src) if l.startswith("HDAE5000_UiObject_PtrTable:"))
    t1 = t0 + 1 + NOBJ                      # 789 .long rows, then the NULL row
    if not all(src[k].lstrip().startswith(".long") for k in range(t0 + 1, t1 + 1)):
        fail("pointer table rows are not where expected")
    ptr_rows = ptr_table(recs, src[t0 + 1:t1])
    src = src[:t0 + 1] + ptr_rows + src[t1:]
    src = src[:s] + new + src[e:]
    open(SRC, "w", encoding="latin-1").write("\n".join(src))
    print("wrote %s: pool %d -> %d lines, pointer table symbolic" % (SRC, len(old), len(new)))


def extract_notes(old):
    """The substantive comments of the old pool text: the POOL START note and
    the five misnomer retraction notes, keyed by the label they follow."""
    notes = collections.OrderedDict()
    cur = None
    started = False
    for l in old:
        m = re.match(r'^(HDAE5000_\w+):', l) or re.match(r'^\t\.set\t(HDAE5000_\w+),', l)
        if m:
            cur = m.group(1)
            notes[cur] = [l.split(";", 1)[1].strip() if ";" in l else ""]
            continue
        t = l.strip()
        if t.startswith("; [#") or re.match(r'^(HdaeUiObj_\d{3}|\.long|\.short|\.byte|\.ascii)', t):
            started = True       # generated text begins: the POOL note is complete
            if t.startswith("; [#"):
                cur = None       # a record header ends any misnomer note
                continue
        if cur is None and t.startswith(";") and not started:
            notes.setdefault("POOL", []).append(l)
        elif cur and t.startswith(";") and "word-align pad" not in t and not re.match(r'^;\s*".*"$', t):
            notes[cur].append(l)
        elif t and not t.startswith(";"):
            if cur:
                cur = None if len(notes[cur]) > 1 else cur
    return notes


MISNOMER_AT = {"HDAE5000_UI_Descriptors": "HdaeUiObj_000 + 0x02",
               "HDAE5000_UI_Page_Titles": "HdaeUiObj_018_Cap1A",
               "HDAE5000_Panel_Save_UI": "HdaeUiObj_177_Cap1C",
               "HDAE5000_Credits": "HdaeUiObj_645_Cap16",
               "HDAE5000_Demo_Data": "HdaeUiObj_743_Cap1A"}
MISNOMER_AFTER = {"HDAE5000_UI_Descriptors": "HdaeUiObj_000", "HDAE5000_UI_Page_Titles": "HdaeUiObj_018",
                  "HDAE5000_Panel_Save_UI": "HdaeUiObj_177", "HDAE5000_Credits": "HdaeUiObj_645",
                  "HDAE5000_Demo_Data": "HdaeUiObj_743"}


def weave(lines, notes):
    out = list(notes.get("POOL", []))
    after = {v: k for k, v in MISNOMER_AFTER.items()}
    cur = None
    for l in lines:
        m = re.match(r'^(HdaeUiObj_\d{3}):', l)
        if l == "" and cur in after:
            k = after[cur]
            out.append("\t.set\t%s, %s\t; %s" % (k, MISNOMER_AT[k], notes[k][0]))
            out.extend(notes[k][1:])
            cur = None
        if m:
            cur = m.group(1)
        out.append(l)
    return out


if __name__ == "__main__":
    main()
