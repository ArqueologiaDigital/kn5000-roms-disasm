#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""pat_corpus.py -- shared corpus loader for the pat_* speculative-pattern tools.

NEC uPD6383GF (Technics SX-KN5000 IC311).  Loads the 3057-word static corpus
(60-word header + 23-word output stage + 38 distinct body images) straight out
of the Sub CPU ROM via the research tree's own parser, so nothing here can drift
away from dsp/disasm/*.dsm.

    from pat_corpus import load, F      # F(w) -> the field decode

stdlib only (plus the research tree's kn5000_dsp_extract).
"""
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SUB = os.path.join(REPO, "original_ROMs", "kn5000_subprogram_v142.rom")
TOOLS = os.path.expanduser("~/compartilhado/kn7000_mame/tools")

ALGO_TABLE = 0x0001ED7C
HEADER_ROM = 0x01E496
EPILOGUE_ROM = 0x01E63C
N_ALGOS = 100
MALFORMED = {79, 88, 89, 90, 91}          # programs for the OTHER DSP (IC310)


# --------------------------------------------------------------------------
#  the field decode -- the one place the 36-bit layout is written down here
# --------------------------------------------------------------------------
class F:
    """hi12[35:24] . class4[23:20] . addr8[19:12] . lo12[11:0]"""
    __slots__ = ("w", "hi12", "class4", "addr8", "lo12", "src", "act",
                 "f98", "f31", "b4", "b7", "b10", "b11", "cfmt", "imm13")

    def __init__(self, w):
        self.w = w
        self.hi12 = (w >> 24) & 0xFFF
        self.class4 = (w >> 20) & 0xF
        self.addr8 = (w >> 12) & 0xFF
        self.lo12 = w & 0xFFF
        self.src = (self.lo12 >> 6) & 0x1F
        self.act = self.lo12 & 0x1F
        self.f98 = (self.hi12 >> 8) & 3
        self.f31 = (self.hi12 >> 1) & 7
        self.b4 = (self.hi12 >> 4) & 1
        self.b7 = (self.hi12 >> 7) & 1
        self.b10 = (self.hi12 >> 10) & 1
        self.b11 = (self.hi12 >> 11) & 1
        self.cfmt = ((self.hi12 >> 8) & 0xF) == 0xC
        self.imm13 = (w >> 12) & 0x1FFF          # bits[24:12], C-format only

    def mode(self):
        return None if self.cfmt else (self.class4 & 7)

    def is_dram(self):
        """mode 1 + FORMAT ESCAPE, C-format excluded (R2's predicate)."""
        return (not self.cfmt) and self.class4 == 1 and self.b11

    def txt(self):
        return "%03X.%X.%02X.%03X" % (self.hi12, self.class4, self.addr8,
                                      self.lo12)


def fmt(w):
    return "%03X.%X.%02X.%03X" % ((w >> 24) & 0xFFF, (w >> 20) & 0xF,
                                  (w >> 12) & 0xFF, w & 0xFFF)


def decode_str(w):
    """One-line human field decode, for report tables."""
    f = F(w)
    if f.cfmt:
        return ("%s  C-FMT imm13=%d (A=%d B=%d) lo12=%03X"
                % (f.txt(), f.imm13, f.imm13 >> 5, f.imm13 & 31, f.lo12))
    bits = []
    if f.b11:
        bits.append("ESC")
    if f.b10:
        bits.append("END")
    if f.b7:
        bits.append("b7")
    if f.b4:
        bits.append("ST")
    return ("%s  cls%X %s addr8=%02X SRC=%02X ACT=%02X f98=%d f31=%d%s"
            % (f.txt(), f.class4, "mode%d" % (f.class4 & 7), f.addr8,
               f.src, f.act, f.f98, f.f31,
               (" " + "|".join(bits)) if bits else ""))


# --------------------------------------------------------------------------
#  loading
# --------------------------------------------------------------------------
def _import_extract():
    if not os.path.isdir(TOOLS):
        sys.exit("ERROR: research tools dir not found: %s" % TOOLS)
    sys.path.insert(0, TOOLS)
    import kn5000_dsp_extract as E
    return E


def load(sub=SUB):
    """-> (progs, meta)

    progs : ordered dict name -> [36-bit words]
            "KERNEL", "EPILOGUE", then one entry per distinct body image,
            named "aNN NAME".
    meta  : name -> dict(algo, algos, family, unit, effect, region)
    """
    E = _import_extract()
    rom = E.Rom(sub)

    def blk(addr):
        iram, _c, _o = E.parse_stream(rom, addr, limit=40)
        return [int.from_bytes(bytes(w), "big") for w in iram[0][1]]

    raw = {}
    for a in range(N_ALGOS):
        ptr = rom.u32le(ALGO_TABLE + 4 * a)
        try:
            ir, _c, _o = E.parse_stream(rom, ptr)
        except Exception:
            continue
        if not ir:
            continue
        raw[a] = ([int.from_bytes(bytes(w), "big")
                   for _ad, ws, _l in ir for w in ws], ir[0][0])

    groups = {}
    for a in sorted(raw):
        if a in MALFORMED:
            continue
        groups.setdefault(tuple(raw[a][0]), []).append(a)

    tsv = _load_tsv()
    progs = {"KERNEL": blk(HEADER_ROM), "EPILOGUE": blk(EPILOGUE_ROM)}
    meta = {"KERNEL": dict(algo=-1, algos=[], family="kernel", unit=-1,
                           effect="KERNEL (I-RAM 0..59)", region="kernel"),
            "EPILOGUE": dict(algo=-2, algos=[], family="kernel", unit=-1,
                             effect="OUTPUT STAGE (I-RAM 60..82)",
                             region="kernel")}
    items = sorted(((algos[0], algos, list(ws)) for ws, algos in groups.items()),
                   key=lambda t: t[0])
    for rep, algos, ws in items:
        info = tsv.get(rep, {})
        nm = "a%02d %s" % (rep, info.get("effect_name", "?"))
        progs[nm] = ws
        meta[nm] = dict(algo=rep, algos=algos,
                        family=info.get("family", "?"),
                        unit=int(info.get("unit", 0) or 0),
                        effect=info.get("effect_name", "?"), region="body")
    return progs, meta


def _load_tsv():
    path = os.path.join(REPO, "dsp", "programs.tsv")
    out = {}
    if not os.path.exists(path):
        return out
    hdr = None
    for line in open(path):
        line = line.rstrip("\n")
        if line.startswith("#"):
            if hdr is None and "effect_name" in line:
                hdr = line.lstrip("# ").split("\t")
            continue
        if not line.strip():
            continue
        toks = line.split("\t")
        d = dict(zip(hdr, toks)) if hdr else {}
        try:
            out[int(toks[0])] = d
        except ValueError:
            pass
    return out


def bodies(progs):
    return {k: v for k, v in progs.items() if k not in ("KERNEL", "EPILOGUE")}


if __name__ == "__main__":
    p, m = load()
    tot = sum(len(v) for v in p.values())
    print("programs: %d   words: %d" % (len(p), tot))
    for k in p:
        print("  %-28s %4d words  family=%-10s unit=%d slots=%d"
              % (k, len(p[k]), m[k]["family"], m[k]["unit"],
                 len(m[k]["algos"])))
