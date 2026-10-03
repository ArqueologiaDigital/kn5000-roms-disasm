#!/usr/bin/env python3
"""sync_gui_format_strings_head.py -- give v9's and v7's includes/gui_format_strings.s head the form v10's has.

QUESTION THIS ANSWERS / JOB IT DOES
  scripts/converters/gui_format_strings_cells.py typed the head of v10's GUI_FormatStrings
  (pointers, inline "%Nd" format strings, zero cells), and later passes named its pointers.  It
  was never run on v9 or v7, which still hold the same bytes as `Label:\t.byte ...` lines -- the
  multi-version sync policy says they must follow.  This rewrites, up to `Scoop_ClassTable_166:`:
    * a 4-byte `.byte` cell that is three printable characters and a NUL  -> `.asciz "..."`
      (exactly 4 bytes, as in v10);
    * the 8-byte record 00 00 00 00 3F 01 EF 00 that Scoop_EventLoop_12Entry_Alt_Data_Target10
      copies with `ld bc,4 / ldirw` -> `.short 0, 0, 319, 239`, the 320x240 screen's corner
      coordinates (in v10 too, where it was `.long 0x00000000` / `.long 0x00EF013F`);
    * the 12 LE32 words after Scoop_EventLoop_12Entry_Alt_Data, and Scoop_ApFunctionTable_126/426,
      -> `.long <label>` when that tree's ELF has a `t` label at the value, a zero as `.long 0`;
      Scoop_ApFunctionTable_426's word points at its own last two bytes, which get the label
      Scoop_ApFunctionTable_426_EndName, as in v10.
  A value with no label stays a number, and the count is reported.  Same bytes: make gate-all.

USAGE
  make all
  python3 scripts/tools/sync_gui_format_strings_head.py --tree v9 [--apply]
"""
import argparse
import os
import re
import subprocess

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
RECT = [0x00, 0x00, 0x00, 0x00, 0x3F, 0x01, 0xEF, 0x00]
RECT_TEXT = ".short\t0, 0, 319, 239\t; copied as 4 words by Scoop_EventLoop_12Entry_Alt_Data_Target10: the 320x240 screen's corners"


def labels(tree):
    elf = os.path.join(REPO, "rebuilt_ROMs", "kn5000_%s_program.llvm.elf" % tree)
    out = {}
    for l in subprocess.run([NM, "--defined-only", elf], capture_output=True, text=True, check=True).stdout.split("\n"):
        p = l.split()
        if len(p) == 3 and p[1] == "t":
            out.setdefault(int(p[0], 16), []).append(p[2])
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True, choices=("v10", "v9", "v7"))
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    p = os.path.join(REPO, a.tree, "maincpu", "includes", "gui_format_strings.s")
    L = open(p, "rb").read().decode("latin-1").split("\n")
    end = next(i for i, l in enumerate(L) if l.startswith("Scoop_ClassTable_166:"))
    lab = labels(a.tree)
    byname = {n: v for v, ns in lab.items() for n in ns}
    out, stats, numeric = [], {"asciz": 0, "rect": 0, "long-label": 0, "long-zero": 0}, []
    i = 0
    BYTES = re.compile(r'^(?P<lab>[A-Za-z_]\w*:)?(?P<ws>\s*)\.byte\s+(?P<ops>[^;]*?)\s*$')
    while i < end:
        l = L[i]
        m = BYTES.match(l)
        if not m:
            # v10's .long pair spelling of the record
            if l.strip() == ".long 0x00000000" and i + 1 < end and L[i + 1].strip() == ".long 0x00EF013F":
                out.append("\t" + RECT_TEXT)
                stats["rect"] += 1
                i += 2
                continue
            out.append(l)
            i += 1
            continue
        ops = [int(x, 0) for x in m["ops"].split(",") if x.strip()]
        lead = (m["lab"] + "\t") if m["lab"] else "\t"
        if ops == RECT:
            out.append(lead + RECT_TEXT)
            stats["rect"] += 1
        elif len(ops) == 4 and ops[3] == 0 and all(0x20 <= x <= 0x7E for x in ops[:3]):
            out.append(lead + '.asciz "%s"' % bytes(ops[:3]).decode("latin-1"))
            stats["asciz"] += 1
        elif len(ops) % 4 == 0 or (m["lab"] == "Scoop_ApFunctionTable_426:" and len(ops) == 6):
            words = [int.from_bytes(bytes(ops[k:k + 4]), "little") for k in range(0, len(ops) - len(ops) % 4, 4)]
            rest = ops[len(words) * 4:]
            first = True
            for w in words:
                if w == 0:
                    text = ".long 0x00000000"
                    stats["long-zero"] += 1
                elif w in lab:
                    text = ".long " + lab[w][0]
                    stats["long-label"] += 1
                else:
                    text = ".long 0x%08x" % w
                    numeric.append(w)
                out.append((lead if first else "\t") + text)
                first = False
            if rest:
                if m["lab"] == "Scoop_ApFunctionTable_426:":
                    # its word points at these two bytes: give them v10's label
                    tgt = words[0]
                    here = byname.get("Scoop_ApFunctionTable_426", 0) + 4
                    assert tgt == here, (hex(tgt), hex(here))
                    out[-1] = out[-1].replace(".long 0x%08x" % tgt, ".long Scoop_ApFunctionTable_426_EndName")
                    if tgt in numeric:
                        numeric.remove(tgt)
                        stats["long-label"] += 1
                    out.append("Scoop_ApFunctionTable_426_EndName:")
                out.append("\t.byte\t" + ", ".join("0x%02x" % x for x in rest))
        else:
            out.append(l)
        i += 1
    out += L[end:]
    print("%s: %s; words left numeric: %s%s" % (a.tree, stats, [hex(w) for w in numeric],
                                                 "" if a.apply else " (dry run)"))
    if a.apply:
        data = "\n".join(out).encode("latin-1")
        with open(p + ".tmp", "wb") as fh:
            fh.write(data)
        os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
