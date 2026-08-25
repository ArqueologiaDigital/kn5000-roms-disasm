#!/usr/bin/env python3
"""Emit prom_a 0xF830C6-0xF855FF as assembly: the ring-buffer class and its bank.

QUESTION IT ANSWERS
  "What source text goes into prom_a/wsa1_prom_a.s for the whole of the .incbin
  span at file offset 0x0030C6?"  The span is 9,530 bytes and holds three things:

    0xF830C6-0xF83215   336 bytes  the sequencer event append, the alternate
                                   INTTR4 tail, and the 0x7F0000 slot driver
    0xF83216-0xF83FFF  3562 bytes  0x0E (RET) pad -- checked, not sampled
    0xF84000-0xF84C6B  3180 bytes  the byte-ring CLASS and its 15 instance banks
    0xF84C6C-0xF855FF  2452 bytes  0x0E (RET) pad -- checked, not sampled

  Every instruction comes from prom_a/roundtrip.py, which assembles and byte-
  compares each candidate spelling before printing it, and re-assembles the whole
  labelled block; this script only adds NAMES and HEADERS on top of that, plus the
  two .fill runs whose uniformity it re-checks here rather than trusting.

  The names come from notes/prom_a_ringbuf_map.py, which reads the class and the
  bank out of the ROM and cross-checks them; nothing here is hand-tabulated.

RUN
  python3 notes/gen_prom_a_ringbuf_module.py > /tmp/region.s
  python3 prom_a/insert_region.py 0xF830C6 0xF85600 /tmp/region.s
  python3 scripts/analysis/assert_byte_identical.py
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "prom_a"))
sys.path.insert(0, os.path.join(ROOT, "notes"))
import roundtrip as RT                                          # noqa: E402
import prom_a_ringbuf_map as MAP                                # noqa: E402

BASE = 0xF80000
ROM = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12"), "rb").read()

KINDS = ["Get", "Put", "PutBlock", "IsEmpty", "Init", "ScanRewind", "Scan",
         None, "ScanToPut", None, "GetCommit"]


def build_names():
    """{address: label} for every routine in 0xF830C6-0xF84C6B."""
    cls = MAP.class_routines()
    ven = MAP.bank_veneers(cls)
    grp = MAP.instances(ven)
    names = {}
    for a, fam, cap, _ in cls:
        names[a] = "Ring_%s_%04X" % (fam, cap)
    seen = {}
    for g in grp:
        objs = {v[3] for v in g if v[2] not in ("ret", "CursorCopy")}
        obj = sorted(objs)[0]
        n = seen.get(obj, 0)
        seen[obj] = n + 1
        tag = "Ring%06X" % obj + ("_Copy" if n else "")
        for v, kind in zip(g, KINDS):
            if kind:
                names[v[0]] = "%s_%s" % (tag, kind)
    names.update({
        0xF830C6: "SeqBuf_AppendEvent",
        0xF830FE: "SeqBuf_AppendEvent__drop",
        0xF83103: "SeqBuf_AppendEvent__trace",
        0xF83120: "INTTR4_SequencerTick_Alt",
        0xF83171: "Dev7F_WriteSlot8_Slot0",
        0xF83179: "Dev7F_WriteSlot8_Slot1",
        0xF83181: "Dev7F_WriteSlot8_Slot2",
        0xF83189: "Dev7F_WriteSlot8_Slot3",
        0xF8318F: "Dev7F_WriteSlot8__enter",
        0xF83197: "Dev7F_WriteSlot8",
        0xF831B3: "sub_F831B3",
    })
    return names, cls, grp


def block(lo, hi, names, headers):
    """roundtrip's verified lines for [lo,hi), with our labels and headers."""
    lines, ok, stats = RT.emit_block(lo, hi)
    if not ok:
        sys.exit("REFUSED: 0x%06X-0x%06X did not re-assemble to the ROM" % (lo, hi))
    out, emitted = [], set()

    def label_at(a):
        if a in headers:
            out.append(headers[a])
        out.append("%s:" % names[a])
        emitted.add(a)

    for text, addr, bs, why in lines:
        if addr is None:                      # a `.LF8xxxx:` label line
            a = int(text.strip().rstrip(":")[2:], 16)
            if a in names:
                label_at(a)
            else:
                out.append(text)
            continue
        t = text
        for a, nm in names.items():           # branch operands roundtrip labelled
            t = t.replace(".L%06X" % a, nm)
        for kw in ("call ", "jp "):           # absolute transfers into this module
            if t.strip().startswith(kw):
                op = t.strip()[len(kw):].strip()
                if op.startswith("0x"):
                    a = int(op, 16)
                    if a in names:
                        t = "\t%s%s" % (kw, names[a])
        if addr in names and addr not in emitted:
            label_at(addr)
        out.append("%-53s ; %06X  %s" % (t, addr,
                                         " ".join("%02x" % b for b in bs)))
    return out, stats


def fill(lo, hi, why):
    n = hi - lo
    seen = set(ROM[lo - BASE:hi - BASE])
    if seen != {0x0E}:
        sys.exit("REFUSED: 0x%06X-0x%06X is not uniform 0x0E (%r)" % (lo, hi, seen))
    return ["", "; 0x%06X-0x%06X -- %d bytes of 0x0E, the encoding of RET.  %s"
            % (lo, hi - 1, n, why),
            "; EVERY byte of the run is checked, not sampled:",
            "; notes/gen_prom_a_ringbuf_module.py refuses to emit this directive",
            "; unless set(ROM[lo:hi]) == {0x0E}.",
            "\t.fill %d, 1, 0x0E" % n, ""]


def load_headers():
    """notes/prom_a_ringbuf_headers.txt -> {'KEY': text}."""
    path = os.path.join(ROOT, "notes", "prom_a_ringbuf_headers.txt")
    out = {}
    for part in open(path, encoding="utf-8").read().split("@@")[1:]:
        k, _, body = part.partition("\n")
        out[k.strip()] = body.rstrip("\n")
    return out


def main():
    names, cls, grp = build_names()
    H = load_headers()
    headers = {}
    for key, addr in (("SEQBUF", 0xF830C6), ("ALTTAIL", 0xF83120),
                      ("SLOTDRV", 0xF83171), ("SUB_F831B3", 0xF831B3)):
        headers[addr] = H[key]
    for fam in ("Get", "Scan", "ScanToPut", "Put", "Init"):
        a = [x[0] for x in cls if x[1] == fam][0]
        tbl = "\n".join(";   0x%X%s0x%06X" % (c, " " * (10 - len("0x%X" % c)), x)
                         for x, f, c, _ in cls if f == fam)
        headers[a] = H["CLASS_" + fam].replace("%TABLE%", tbl)

    for g in grp:
        obj = sorted({v[3] for v in g if v[2] not in ("ret", "CursorCopy")})[0]
        cap = sorted({c for a, f, c, _ in cls if a in {v[4] for v in g}})[0]
        lo, hi = g[0][0], g[-1][0] + g[-1][1]
        first = names[g[0][0]]
        dup = ("" if not first.endswith("_Copy") else
               "\n;          \u26a0 BYTE-FOR-BYTE COPY of the group before it, and no\n"
               ";          directory slot names any of its eleven entries.  Both facts\n"
               ";          are checks in notes/prom_a_ringbuf_map.py.")
        headers[g[0][0]] = (H["GROUP"]
                            .replace("%LABEL%", first)
                            .replace("%OBJ%", "0x%06X" % obj)
                            .replace("%CAP%", "0x%X" % cap)
                            .replace("%LO%", "0x%06X" % lo)
                            .replace("%HI%", "0x%06X" % (hi - 1))
                            .replace("%CTRL%", "0x%06X" % (obj - 10))
                            .replace("%END%", "0x%06X" % (obj + cap - 1))
                            .replace("%DUP%", dup))

    out = [H["MODULE"]]
    b, _ = block(0xF830C6, 0xF83216, names, headers)
    out += b
    out += fill(0xF83216, 0xF84000,
                "padding between the 0xF83000 and 0xF84000 link groups")
    out.append(H["CLASS"])
    b, _ = block(0xF84000, 0xF842DF, names, headers)
    out += b
    out.append(H["BANK"])
    for g in grp:
        lo, hi = g[0][0], g[-1][0] + g[-1][1]
        b, _ = block(lo, hi, names, headers)
        out += b
    out += fill(0xF84C6C, 0xF85600, "padding up to the kernel at 0xF85600")
    print("\n".join(out))


if __name__ == "__main__":
    main()
