#!/usr/bin/env python3
r"""naka_byte_tables_retype.py -- type byte tables of the NAKA C blobs whose readers explain them (v10/v9/v7).

QUESTION ANSWERED
-----------------
Each entry of SPECS is a slice of a naka_*.bin that a [nakarest] note left as "purpose not established".  Its
reader in the code shows what it is (cited in the entry).  The script asserts the property the reading
rests on, types the slice in the tree's C file as a `uint8_t <name>[n]` array (each tree's own bytes, 16 per
row), and replaces the [nakarest] note above the asm label with the header.
  PanelInput_EventIndexByHeader (naka_extension_device +0x3870, 128 B).  PanelInput_EventIndexOfHeader
    (audio/audio_control_engine.s) reads [(h & 0xC0) >> 1 | (h & 0x1F)] for a control-panel packet header h.
    The value is the panel event index: 0-10 left segments (headers 0xC0-0xCA), 11-21 right segments
    (0x00-0x0A), 22-24 headers 0xD1-0xD3, 25 the data wheel 0xD7; 0x1F = none.  Asserted: every value is
    <= 25 or 0x1F, and those headers give those indices.

RUN (repository root, built tree)
    python3 scripts/converters/naka_byte_tables_retype.py [--apply]
    then (v7): scripts/build/regenerate_v7_c_divergence.py --apply BEFORE make; make all; gate
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import nakarest_c_model as M      # noqa: E402


def check_header_index(v):
    idx = lambda h: (h & 0xC0) >> 1 | (h & 0x1F)
    assert all(x <= 25 or x == 0x1F for x in v), "value range"
    assert [v[idx(0xC0 + k)] for k in range(11)] == list(range(0, 11)), "left segments"
    assert [v[idx(0x00 + k)] for k in range(11)] == list(range(11, 22)), "right segments"
    assert [v[idx(h)] for h in (0xD1, 0xD2, 0xD3, 0xD7)] == [22, 23, 24, 25], "headers"


SPECS = [
    dict(blob="naka_extension_device", asm="ui_widgets/extension_device_screens.s", label="PanelInput_EventIndexByHeader",
         off=0x3870, size=0x80, check=check_header_index,
         cdoc="PanelInput_EventIndexByHeader: [(h & 0xC0) >> 1 | (h & 0x1F)] of a control-panel packet header h ->"
              " panel event index (0-10 left segments, 11-21 right, 22-24 headers D1-D3, 25 the data wheel D7,"
              " 0x1F none); read by PanelInput_EventIndexOfHeader",
         header=["; PanelInput_EventIndexByHeader -- 128 x u8: [(h & 0xC0) >> 1 | (h & 0x1F)] of a control-panel packet",
                 "; header h -> the panel event index (0-10 left segments for headers 0xC0-0xCA, 11-21 right for",
                 "; 0x00-0x0A, 22-24 headers 0xD1-0xD3, 25 the data wheel 0xD7; 0x1F = none).  Read by",
                 "; PanelInput_EventIndexOfHeader (audio/audio_control_engine.s).  Typed in",
                 "; ui_widgets/naka_extension_device.c (scripts/converters/naka_byte_tables_retype.py)."]),
]


def main():
    apply = "--apply" in sys.argv
    for tree in ("v10", "v9", "v7"):
        for sp in SPECS:
            c = os.path.join(ROOT, tree, "maincpu", "ui_widgets", sp["blob"] + ".c")
            b = open(os.path.join(ROOT, tree, "maincpu", "includes", "generated", sp["blob"] + ".bin"), "rb").read()
            v = list(b[sp["off"]:sp["off"] + sp["size"]])
            sp["check"](v)
            if sp["label"] not in open(c, encoding="latin-1").read():
                cb = M.CBlob(c)
                sym = [mb.name for mb in cb.members if sp["off"] <= mb.offset < sp["off"] + sp["size"]
                       and M.SYMBOLIC_RE.search(cb.entries[cb.by_name[mb.name]].expr)]
                assert not sym, (tree, sp["label"], sym)
                rows = ["        " + " ".join("0x%02X," % x for x in v[r:r + 16]) + "  /* [0x%02X..] */" % r
                        for r in range(0, len(v), 16)]
                cb.retype(sp["off"], sp["off"] + sp["size"],
                          [M.NewMember("uint8_t", sp["label"], "[%d]" % sp["size"], sp["size"],
                                       "{\n" + "\n".join(rows) + "\n    }", ["    /* %s */" % sp["cdoc"]])], b)
                print(tree, sp["label"], "C typed")
                if apply:
                    data = cb.render().encode("latin-1")
                    open(c + ".tmp", "wb").write(data)
                    os.replace(c + ".tmp", c)
            p = os.path.join(ROOT, tree, "maincpu", sp["asm"])
            L = open(p, "rb").read().decode("latin-1").split("\n")
            k = next(i for i, x in enumerate(L) if x.startswith(sp["label"] + ":"))
            j = k
            while L[j - 1].startswith("; [nakarest]"):
                j -= 1
            if k - j >= 3:
                L[j:k] = sp["header"]
                print(tree, sp["label"], "asm headed")
                if apply:
                    data = "\n".join(L).encode("latin-1")
                    open(p + ".tmp", "wb").write(data)
                    os.replace(p + ".tmp", p)


if __name__ == "__main__":
    main()
