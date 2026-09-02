#!/usr/bin/env python3
r"""HOW MUCH OF THE "CODE-SHAPED LABEL" FLAG IS WORTH DISASSEMBLING?

QUESTION THIS ANSWERS
---------------------
`notes/DATA-CENSUS-2026-09-02.md` §6 flags 26,853 data regions / 542,405 B
because the label governing them carries a routine-ish token (`_Loop`,
`_Dispatch`, `Initialize*`, ...).  The census reports that flag WITH its null --
47.2% of proven-CODE regions trip it against 4.7% of regions in the three
pure-data images -- and is explicit that it is a lead, not a verdict.  On
542,405 B a 4.7% floor is ~25 KB of data that looks like code to this
instrument, so a bulk conversion is not available.

This script produces a RANKED SHORTLIST instead, with per-region evidence, and
one structural finding that removes a third of the byte total up front.

THE STRUCTURAL FINDING: THE FLAG'S BIGGEST BYTE CONTRIBUTORS ARE SELF-LABELLED
TABLES.  `dispatch` and `handler` are in the census's CODE_NAME_TOKENS, so
`SoundEffect_Dispatch_Table`, `Naka_MainDispatch_Table`,
`TuningSystem_Handler_Table` and `SoundProgram_DispatchTable` all trip a
CODE-shaped flag while their own names say TABLE.  That matters because the
project's standing trap is exactly this one: `notes/DEBT-INVENTORY-2026-09-02.md`
records six jump-table conversions reverted by hand because a table round-trips
as code.  Measured here: labels that carry a data noun as well as a code token
are **33.7% of the flagged literal bytes** and are de-ranked, not converted.

    NOTE THE STANDING EXCEPTION, which is why this is a de-rank and not a
    dismissal: one lane found a routine that is address-taken nine times from a
    handler table and is perfectly real code.  A table-shaped name lowers the
    rank; only the decode plus a reference decides.

WHAT IS RANKED, AND HOW
-----------------------
Rank key, strongest first:
  1. `targeted`  -- a control transfer names this label.  Null for that flag:
     0 of 11,179 C-compiled (externally certified DATA) regions in the same
     three images (`code_suspect_adjudicate.py --null`).  These sites are
     handed to `code_suspect_adjudicate.py`, which grades them properly; they
     appear here only so the two populations reconcile.
  2. `clean`     -- the whole run decodes AND every instruction round-trips
     byte-exact through llvm-mc.  Random-byte null at these lengths: 0.8%.
  3. not table-named (see above).
  4. size.

SCOPE -- STATED HONESTLY
------------------------
Decoding needs a real address, which needs a linked image, so `--decode` runs
only for `v7`/`v9`/`v10`, and only for the top `--top N` runs by size.
Everything else in the table is screened by NAME and SIZE only and is marked
`screen-only`.  The report prints how many bytes of the flagged population were
actually decoded, so the coverage claim cannot be rounded up.

RUN
    python3 scripts/analysis/code_shape_shortlist.py                # census only
    python3 scripts/analysis/code_shape_shortlist.py --refkind
    python3 scripts/analysis/code_shape_shortlist.py --decode --top 150

TOOLCHAIN.  `--decode` uses the shared, mutable llvm build; this lane's figures
were taken at tlcs900_backend@6f456a19f05b.  The name/size census does not.
"""
import bisect
import importlib.util
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "scripts", "converters"))
import code_suspect_sites as C            # noqa: E402
import code_suspect_adjudicate as A       # noqa: E402
import convert_code_bytes as CCB          # noqa: E402

_spec = importlib.util.spec_from_file_location(
    "drc", os.path.join(HERE, "data_range_census.py"))
DRC = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(DRC)

# Nouns that name a DATA object.  A label carrying one of these AND a
# CODE_NAME_TOKEN is de-ranked, because the census's token set contains
# `dispatch` and `handler`, which is how `..._Dispatch_Table` trips a code flag.
DATA_NOUN = re.compile(r'table|tbl|array|_list|_data\b|params|preset|string'
                       r'|text|names|bitmap|glyph|font|palette|coeff|map\b',
                       re.I)

MIRRORS = [("v7", "v7/maincpu"), ("v9", "v9/maincpu"), ("v10", "v10/maincpu"),
           ("hdae5000", "hdae5000"), ("v142", "v142/subcpu"),
           ("subboot", "subcpu/boot"), ("wsa1", "wsa1"),
           ("tabledata", "table_data"), ("customdata", "custom_data")]


def enumerate_sites():
    out = {}
    for key, mirror in MIRRORS:
        files, labels, refs = C.scan(mirror)
        sites = []
        for name, places in labels.items():
            if not DRC.label_is_code_shaped(name):
                continue
            for (rel, li) in places:
                fe = C.first_emitting(files[rel], li)
                if not fe or fe[1] != "data":
                    continue
                txt = fe[2]
                kind = ("cc" if (".incbin" in txt and "includes/generated" in txt)
                        else "slice" if ".incbin" in txt else "lit")
                nb, _end = C.run_extent(files[rel], fe[0])
                sites.append(dict(image=key, label=name, rel=rel, line=li + 1,
                                  dataline=fe[0] + 1, bytes=nb, kind=kind,
                                  targeted=name in refs,
                                  tablename=bool(DATA_NOUN.search(name)),
                                  first=txt.strip()[:90]))
        out[key] = sites
    return out


def decode_rank(sites, key, top):
    """Decode the largest `top` literal runs of one image and attach the
    clean/round-trip verdict.  Address from the linked image's symbol table,
    guarded against the source's own stated bytes exactly as
    code_suspect_adjudicate.grade() does."""
    syms, R, base = A.symtab(key), A.rom(key), A.IMG[key]["base"]
    addrs = sorted(set(syms.values()))
    files = {}
    root = os.path.join(ROOT, A.IMG[key]["mirror"])
    cand = sorted([s for s in sites if s["kind"] == "lit"],
                  key=lambda s: -s["bytes"])[:top]
    done = 0
    for s in cand:
        p = os.path.join(root, s["rel"])
        if p not in files:
            files[p] = open(p, encoding="latin-1").read().split("\n")
        L = files[p]
        if s["label"] not in syms:
            s["verdict"] = "no-symbol"
            continue
        a = syms[s["label"]]
        sb = A.stated_bytes(L[s["dataline"] - 1])
        if sb is not None and list(R[a - base:a - base + len(sb)]) != sb:
            s["verdict"] = "ADDRESS-GUARD-FAILED"
            continue
        i = bisect.bisect_right(addrs, a)
        end = min(addrs[i] if i < len(addrs) else a + s["bytes"], a + s["bytes"])
        n = end - a
        if n <= 0 or n > 65536:
            s["verdict"] = "extent?"
            continue
        res = CCB.convert_block(list(R[a - base:a - base + n]), base_pc=a)
        ok = sum(nb for (m, _o, nb) in res if m is not None)
        s["addr"] = a
        s["extent"] = n
        s["rtpct"] = 100.0 * ok / n
        s["clean"] = all(m is not None for (m, _o, _n) in res)
        s["verdict"] = "clean" if s["clean"] else "blocked"
        done += n
    return done



def refkind():
    """PARTITION THE FLAGGED BYTES BY WHAT KIND OF REFERENCE THEY HAVE.

    The project's standing rule, from six jump-table conversions reverted by
    hand: *if every reference LOADS AN ADDRESS and nothing calls or jumps in,
    it is data.*  This applies it to the whole code-shaped population, which
    turns out to be the single strongest de-rating signal available -- stronger
    than the name, and free.

    Three classes, in descending evidential value:

      CTRL-TARGETED          a control transfer names the label.  Null: 0 of
                             11,179 C-compiled data regions
                             (code_suspect_adjudicate.py --null).  These are
                             population 2 and are graded there.
      address-taken only     the label is used elsewhere, but never as the
                             operand of a call/jp/jr/jrl/djnz.  The
                             jump-table shape.
      no reference anywhere  no evidence in either direction.

    Worked check on the largest non-table-named members of the middle class:
    WndEvt_EventCodeDispatch, CmpNcpTtl_Dispatch2, Sqedt_ParamDispatch,
    Data_InOutGridDispatch, VocalistGrid_CheckDispData, NameGetFuncCall_Dispatch,
    Data_ParaLoadOptDispatch, CstmCpTtl_Dispatch2, SeqAccomp_SubHandlerA --
    every one is referenced EXACTLY ONCE, by `lda_24`, and the instruction after
    that load is `jp_ind`.  They are jump-table bases."""
    from collections import Counter
    IDENT = re.compile(r'\b([A-Za-z_][\w.$]{2,})\b')
    allsites = enumerate_sites()
    grand = Counter()
    print("CODE-SHAPED LITERAL BYTES, BY REFERENCE KIND")
    for key, mirror in MIRRORS:
        files, labels, refs = C.scan(mirror)
        used = set()
        for _rel, L in files.items():
            for ln in L:
                c = C.strip_comment(ln).strip()
                m = C.LABEL_RE.match(c)
                body = c[m.end():].strip() if m else c
                if body:
                    used.update(IDENT.findall(body))
        t = Counter()
        for x in allsites[key]:
            if x["kind"] != "lit":
                continue
            k = ("CTRL-TARGETED" if x["targeted"]
                 else "address-taken only" if x["label"] in used
                 else "no reference anywhere")
            t[k] += x["bytes"]
            grand[k] += x["bytes"]
        print("  %-11s %s" % (key, dict(sorted(t.items()))))
    tot = sum(grand.values())
    print("\n  %-24s %10s %7s" % ("class", "bytes", "share"))
    for k in ("CTRL-TARGETED", "address-taken only", "no reference anywhere"):
        print("  %-24s %10d %6.1f%%" % (k, grand[k], 100.0 * grand[k] / tot))


def main():
    if "--refkind" in sys.argv:
        refkind()
        return
    top = int(sys.argv[sys.argv.index("--top") + 1]) if "--top" in sys.argv else 150
    allsites = enumerate_sites()
    print("CODE-SHAPED LABELS HEADING A DATA RUN")
    print("  %-11s %6s %10s | %6s %10s  (literal runs only)" %
          ("image", "runs", "bytes", "table-named", "bytes"))
    tot = tb = 0
    for key, _m in MIRRORS:
        lit = [s for s in allsites[key] if s["kind"] == "lit"]
        b = sum(s["bytes"] for s in lit)
        t = [s for s in lit if s["tablename"]]
        tot += b
        tb += sum(s["bytes"] for s in t)
        print("  %-11s %6d %10d | %11d %10d" %
              (key, len(lit), b, len(t), sum(s["bytes"] for s in t)))
    print("  %-11s %6s %10d | %11s %10d  (%.1f%% of bytes are table-named)" %
          ("TOTAL", "", tot, "", tb, 100.0 * tb / max(1, tot)))
    print("\n  `.incbin` of a C-compiled bin is excluded from the literal count:")
    print("  it is DATA on an authority independent of this tree's framing, and")
    print("  the flag firing on it is a pure false positive by construction.")
    for key, _m in MIRRORS:
        cc = [s for s in allsites[key] if s["kind"] == "cc"]
        if cc:
            print("    %-11s %5d code-shaped labels on C-compiled regions" % (key, len(cc)))

    if "--decode" not in sys.argv:
        return
    decoded = 0
    for key in ("v7", "v9", "v10"):
        decoded += decode_rank(allsites[key], key, top)
    rows = [s for key in ("v7", "v9", "v10") for s in allsites[key]
            if s.get("verdict")]
    rows.sort(key=lambda s: (not s["targeted"], s.get("verdict") != "clean",
                             s["tablename"], -s["bytes"]))
    print("\nRANKED SHORTLIST (top %d literal runs per image, decoded)" % top)
    print("  %-5s %-34s %8s %7s %6s %5s %5s %5s" %
          ("img", "label", "addr", "extent", "rt%", "clean", "tgtd", "table"))
    for s in rows:
        print("  %-5s %-34s %8s %7s %5s%% %5s %5s %5s" %
              (s["image"], s["label"][:34],
               ("%08X" % s["addr"]) if "addr" in s else "-",
               s.get("extent", "-"),
               ("%.1f" % s["rtpct"]) if "rtpct" in s else "-",
               "yes" if s.get("clean") else "no",
               "YES" if s["targeted"] else "-",
               "tbl" if s["tablename"] else "-"))
    clean = [s for s in rows if s.get("clean")]
    print("\n  decoded %d B of the flagged literal population (%.1f%% of %d B)"
          % (decoded, 100.0 * decoded / max(1, tot), tot))
    print("  clean+round-trip: %d runs, %d B  (random-byte null at these "
          "lengths: 0.8%%)" % (len(clean), sum(s["extent"] for s in clean)))
    json.dump(allsites, open(os.path.join(ROOT, "code_shape_shortlist.json"), "w"),
              indent=1)
    print("  wrote code_shape_shortlist.json")


if __name__ == "__main__":
    main()
