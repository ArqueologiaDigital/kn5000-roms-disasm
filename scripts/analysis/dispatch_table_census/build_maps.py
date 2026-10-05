#!/usr/bin/env python3
"""Stage 1 of the jump/call-table census: an exact address -> source-line map per image.

QUESTION IT ANSWERS
  "For every byte of image X, which source line emits it, what kind of line is it
   (instruction / data directive / fill), and which ELF symbols sit at which
   addresses?"  Stage 2 (jt_census.py) classifies table entries against this map.

HOW
  Reuses scripts/analysis/data_range_census.py's instrument UNCHANGED (imported, not
  copied): mirror the image's source tree into SCRATCH with a marker label before
  every byte-emitting line, assemble + link the mirror with the real linker script,
  read marker addresses from the ELF.  census_image() also proves the mirror inert
  (objcopy of the marked mirror == the original dump); this script refuses to save a
  map for an image whose mirror is not inert.

  Nothing is written inside the repository: the mirror, objects, ELFs and the
  pickles all live under OUT ($DISPATCH_CENSUS_DIR, else $TMPDIR/dispatch-table-census).

RUN
  python3 scripts/analysis/dispatch_table_census/build_maps.py [keys...]   # default: all 11 images, ~2 min
"""
import importlib.util
import os
import pickle
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
# scratch, never the repository: $DISPATCH_CENSUS_DIR, else $TMPDIR/dispatch-table-census
OUT = os.environ.get("DISPATCH_CENSUS_DIR") or os.path.join(os.environ.get("TMPDIR") or os.path.expanduser("~/compartilhado/tmp"),
                                                            "dispatch-table-census")
os.makedirs(OUT, exist_ok=True)
spec = importlib.util.spec_from_file_location(
    "drc", os.path.join(REPO, "scripts/analysis/data_range_census.py"))
drc = importlib.util.module_from_spec(spec)
spec.loader.exec_module(drc)

KEYS = ["v10", "v9", "v7", "v142", "subboot", "tabledata", "customdata", "hdae5000",
        "prom_a", "prom_b", "prom_c"]


def nm_symbols(elf):
    out = subprocess.run([drc.NM, "--defined-only", elf], capture_output=True,
                         text=True, check=True).stdout
    syms = []
    for ln in out.splitlines():
        p = ln.split()
        if len(p) == 3 and not p[2].startswith(drc.MARK):
            syms.append((int(p[0], 16), p[1], p[2]))
    return syms


def main(keys):
    tmp = os.path.join(OUT, "work")
    os.makedirs(tmp, exist_ok=True)
    for img in drc.IMAGES:
        if img["key"] not in keys:
            continue
        print("%-10s building map ..." % img["key"], flush=True)
        c = drc.census_image(img, tmp)
        if not c["inert"]:
            print("   NOT INERT -- refusing to save a map", flush=True)
            continue
        src, macros = c["src"], c["macros"]
        rows = []
        prev_by_file = {}
        for (a, b, rel, li) in c["spans"]:
            text = src.text(rel, li)
            kind, detail = drc.classify_line(text, macros)
            # was a label defined on this line, or on a non-emitting line between the
            # previous emitting line of the SAME file and this one?
            L = src.lines(rel)
            p = prev_by_file.get(rel, -1)
            lab = None
            for k in range(p + 1, li + 1):
                cc = drc.strip_comment(L[k]).strip()
                m = drc.LABEL_RE.match(cc)
                if m and not m.group(1).startswith(drc.MARK):
                    lab = m.group(1)
            if kind in ("code", "data", "fill"):
                prev_by_file[rel] = li
            rows.append((a, b, rel, li, kind, detail, text, lab))
        raw = open(os.path.join(tmp, img["key"] + ".bin"), "rb").read()
        syms = nm_symbols(os.path.join(tmp, img["key"] + ".elf"))
        pickle.dump(dict(key=img["key"], base=img["base"], size=img["size"],
                         split=img.get("split"), rows=rows, raw=raw, syms=syms),
                    open(os.path.join(OUT, "map_%s.pkl" % img["key"]), "wb"))
        print("   spans %d  syms %d  raw %d B" % (len(rows), len(syms), len(raw)),
              flush=True)


if __name__ == "__main__":
    main(sys.argv[1:] or KEYS)
