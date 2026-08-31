#!/usr/bin/env python3
"""Emit a prom_b display-list module that notes/prom_b_anchored_tiler.py tiles.

QUESTION IT ANSWERS
    "...and what is the assembly for that tiling?"  Records are rendered by the
    interpreter the tiling attributes them to, reusing the same two renderers the
    rest of the .s uses.  Tables are rendered at the width and entry count the
    tiling derived, with the record that fixed them named in the header.

    It REFUSES to emit anything if the tiling leaves a byte untiled.

RUN
    python3 notes/gen_prom_b_anchored_module.py 0xF0C800 0xF0D061
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL                                 # noqa: E402
import prom_b_dl_length_audit as LA                               # noqa: E402
import gen_prom_b_display_lists_v2 as V2                          # noqa: E402
import prom_b_anchored_tiler as AT                                # noqa: E402

B_BASE = 0xF00000
BAR = "; " + "-" * 66 + "\n"


def render_table(b, s, e, w, src, why):
    n = (e - s) // w
    out = [BAR,
           "; 0x%06X-0x%06X -- %d entries of %d bytes\n" % (s, e - 1, n, w),
           ";   Width from the %s.  The COUNT is the extent divided by that\n" % why,
           ";   width -- %d / %d = %d -- and the extent is fixed by the anchors on\n"
           % (e - s, w, n),
           ";   both sides, not by the record's AND mask, which bounds the index\n",
           ";   only.\n", BAR,
           "DLTable_%06X:\n" % s]
    for i in range(n):
        raw = b[s - B_BASE + i * w:s - B_BASE + (i + 1) * w]
        if all(0x20 <= c < 0x7F for c in raw):
            out.append("\t.ascii \"%s\"\t; [%d]\n" % (DL.esc(raw.decode("ascii")), i))
        elif w % 2 == 0:
            words = [int.from_bytes(raw[k:k + 2], "little") for k in range(0, w, 2)]
            out.append("\t.short %s\t; [%d]\n" % (", ".join("0x%04X" % x for x in words), i))
        else:
            out.append("\t.byte %s\t; [%d]\n" % (", ".join("0x%02X" % c for c in raw), i))
    return out


def emit(lo, hi):
    m = AT.Module(lo, hi)
    objs = m.tile()
    if any(o[2] != "list" and o[2] != "table" for o in objs):
        raise SystemExit("refusing to emit: the tiling is incomplete")
    b = m.b
    hta, htb = m.ta, m.tb
    nrec = sum(len(d[1]) for _s, _e, k, d in objs if k == "list")
    ntab = sum(1 for o in objs if o[2] == "table")
    out = ["\n", "; " + "=" * 76 + "\n",
           "; 0x%06X-0x%06X -- a UI SCREEN MODULE: %d display-list records in %d\n"
           % (lo, hi - 1, nrec, sum(1 for o in objs if o[2] == "list")),
           ";                     lists, and the %d operand tables they point at\n" % ntab,
           "; " + "=" * 76 + "\n", ";\n",
           "; Reached by the `lda XBC,<end> / push XBC / lda XWA,<start> / push XWA /\n",
           "; call {0xF42E00, 0xF42E04}` shape and by `lda XBC,<record> / push XBC /\n",
           "; call 0xF42E0C`, neither of which the committed call-site scanner looks\n",
           "; for -- see notes/prom_b_dl_call_shapes.py.  Every list's extent is a call\n",
           "; site's own two immediates and its records walk exactly onto the end; every\n",
           "; table's start is a pointer field of a record and its width that record's\n",
           "; width field or its handler's fixed stride.\n",
           ";\n",
           "; ⚠ The entry counts below come from the EXTENTS, never from the records'\n",
           "; AND masks: a mask bounds the INDEX, and masks of 0xFF are everywhere here.\n",
           "; python3 notes/prom_b_anchored_tiler.py 0x%06X 0x%06X\n" % (lo, hi),
           "; " + "=" * 76 + "\n"]
    for s, e, kind, det in objs:
        if kind == "list":
            which, recs = det
            out.append("\n" + BAR)
            out.append("; 0x%06X-0x%06X -- %d records, %d bytes -- interpreter %s\n"
                       % (s, e - 1, len(recs), e - s,
                          which if which in "AB" else
                          "A or B: NO SITE NAMES THIS LIST and both implied lengths fit"))
            out.append(BAR)
            out.append("DL_%06X:\n" % s)
            for p, op, ln in recs:
                if which == "B":
                    out += V2.render_b(b, p, op, ln, htb)
                else:
                    out += DL.render(b, [(p, op, ln)], hta, set())
        else:
            w, src, why = det
            out.append("\n")
            out += render_table(b, s, e, w, src, "%s at 0x%06X" % (why, src))
    return "".join(out)


def main():
    args = [x for x in sys.argv[1:] if not x.startswith("--")]
    if len(args) != 2:
        print(__doc__)
        return 2
    sys.stdout.write(emit(int(args[0], 0), int(args[1], 0)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
