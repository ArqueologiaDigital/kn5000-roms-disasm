#!/usr/bin/env python3
"""Emit, as assembly, the display-list OPERAND TABLES whose size is proven.

Companion emitter to notes/prom_b_dl_operand_tables.py, which is where the
argument lives.  Only the gaps that script grades EXACT or TILED are emitted;
everything else stays .incbin, because for those the entry count taken from the
record's AND mask is an upper bound on the index and nothing has confirmed it.

RUN
  python3 notes/gen_prom_b_dl_operand_tables.py            # asm for every proven gap
  python3 notes/gen_prom_b_dl_operand_tables.py --list     # just the gap list
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL
import prom_b_dl_operand_tables as OT

B_BASE = 0xF00000


def proven(b, sites):
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    htb = [int.from_bytes(b[0x31DB1 + i * 4:0x31DB1 + i * 4 + 4], "little") for i in range(15)]
    own = {}
    for s, e, t in sorted(sites):
        if not (B_BASE <= s < 0xF80000):
            continue
        r = DL.walk(b, s, e)
        if r is None:
            continue
        for p, op, ln in r:
            own.setdefault(p, set()).add(t)
    objs = OT.objects(b, sites, own, hta, htb)
    out = []
    for gs, ge in OT.gaps(b, sites):
        inside = sorted((p, v) for p, v in objs.items() if gs <= p < ge)
        if not inside or inside[0][0] != gs:
            continue
        starts = [p for p, v in inside]
        ext = [(starts[i + 1] if i + 1 < len(starts) else ge) - starts[i] for i in range(len(starts))]
        if any(ext[i] % OT.entry_size(v[1]) for i, (p, v) in enumerate(inside)):
            continue
        if inside[-1][1][0] != ext[-1]:
            continue
        out.append((gs, ge, [(p, ext[i], v[1], v[2]) for i, (p, v) in enumerate(inside)]))
    return out


def emit(b, gs, ge, objs):
    o = ["\n; ==================================================================\n",
         "; 0x%06X-0x%06X -- display-list OPERAND TABLES (%d bytes, %d objects)\n"
         % (gs, ge - 1, ge - gs, len(objs)),
         "; ==================================================================\n",
         ";\n",
         "; Every object here is named by a display-list record that points at it, and\n",
         "; its SIZE is proven by tiling: the objects start at the first byte of this\n",
         "; gap, each extent is a whole number of entries, and the last object's\n",
         "; handler-implied size ends exactly on the first byte of the next display\n",
         "; list.  Reproduce with `python3 notes/prom_b_dl_operand_tables.py --exact`.\n",
         ";\n"]
    for p, ext, kind, refs in objs:
        esz = OT.entry_size(kind)
        n = ext // esz
        o.append("; ------------------------------------------------------------------\n")
        if "string table" in kind:
            o.append("; DLTable_%06X -- %d entries of %d characters\n" % (p, n, esz))
        elif "byte-entry array" in kind:
            o.append("; DLTable_%06X -- %d entries of %d bytes\n" % (p, n, esz))
        else:
            o.append("; DLTable_%06X -- %d bytes\n" % (p, ext))
        o.append("; Referenced by: display-list record%s %s\n"
                 % ("s" if len(refs) > 1 else "", ", ".join("0x%06X" % x for x in sorted(refs))))
        if "string table" in kind:
            ev = ("the record's +7 pointer lands here and its +0x0B word is %d, so the\n"
                  ";           entries are %d bytes wide (handler 0xF31B21/0xF31B39 loads the\n"
                  ";           extracted bit-field into HL as the index)" % (esz, esz))
        elif "byte-entry array" in kind:
            ev = ("the record's +7 pointer lands here and its handler scales the\n"
                  ";           extracted bit-field by %d before adding it (0xF31B57 `sla 3,HL`,\n"
                  ";           0xF31B86 `mul HL,6`)" % esz)
        else:
            ev = "the record's +2 pointer lands here and +8 x +0x0A = %d bytes" % ext
        o.append("; Evidence: %s.\n" % ev)
        o.append(";           %d entries is the EXTENT (%d bytes / %d), not the (mask >> shift) + 1\n"
                 ";           = %s the record would allow.\n"
                 % (n, ext, esz, kind.rsplit(",", 1)[1].strip().split()[0]))
        o.append("; ------------------------------------------------------------------\n")
        o.append("DLTable_%06X:\n" % p)
        for i in range(n):
            raw = b[p - B_BASE + i * esz:p - B_BASE + (i + 1) * esz]
            if esz == 8 and "byte-entry array" in kind:
                w = [int.from_bytes(raw[k * 2:k * 2 + 2], "little") for k in range(4)]
                o.append("\t.short 0x%04X, 0x%04X, 0x%04X, 0x%04X\t; [%d]\n" % (*w, i))
            elif esz == 6 and "byte-entry array" in kind:
                w = [int.from_bytes(raw[k * 2:k * 2 + 2], "little") for k in range(3)]
                o.append("\t.short 0x%04X, 0x%04X, 0x%04X\t; [%d]\n" % (*w, i))
            elif all(0x20 <= c <= 0x7E for c in raw):
                o.append('\t.ascii "%s"\t; [%d]\n' % (raw.decode("ascii").replace("\\", "\\\\").replace('"', '\\"'), i))
            else:
                o.append("\t.byte %s\t; [%d] |%s|\n"
                         % (", ".join("0x%02X" % c for c in raw), i,
                            "".join(chr(c) if 0x20 <= c <= 0x7E else "." for c in raw)))
    return o


def main():
    a, b = DL.load()
    sites = DL.call_sites(a, b)
    pr = proven(b, sites)
    if "--list" in sys.argv:
        for gs, ge, objs in pr:
            print("0x%06X-0x%06X  %4d B  %d objects" % (gs, ge - 1, ge - gs, len(objs)))
        print("total %d bytes in %d gaps" % (sum(ge - gs for gs, ge, _ in pr), len(pr)))
        return 0
    for gs, ge, objs in pr:
        sys.stdout.write("".join(emit(b, gs, ge, objs)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
