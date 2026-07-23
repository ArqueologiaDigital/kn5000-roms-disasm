#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""gen_dsp_disasm.py -- regenerate the KN5000 effects-DSP disassembly tree.

NEC uPD6383GF (Technics SX-KN5000 IC311).  This is the single deliverable that
keeps the dsp/ tree UP TO DATE: it extracts every distinct microprogram from the
Sub CPU ROM, disassembles each 36-bit word through the Python ISA mirror
(dsp/tools/dsp_disasm.py), overlays the semantic annotations that the reverse
engineering has established -- named coefficient per class-A multiply, decoded
hi12 flags, control-flow / header landmarks, absolute C-RAM cursor addresses,
effect name -- and merges hand-curated labels/comments from dsp/sym/*.sym.  It
then emits the per-program listings, the shared kernel, the manifest table and
programs.tsv.  It is deterministic and idempotent:

    python3 dsp/tools/gen_dsp_disasm.py            # regenerate everything
    git diff --exit-code dsp/disasm dsp/programs.tsv   # doubles as a drift check

WHY IT STAYS UPDATED.  The instruction-level rendering comes from
dsp/tools/dsp_disasm.py (vendored, self-contained) -- teach it a new form and
every listing re-decodes.  The NAMED-COEFFICIENT overlay is pulled LIVE from the
research tools in the kn7000_mame tree (kn5000_dsp_namedcoeff / _params), so
when those name more of the ~822 multiplies a re-run picks it up with no edits
here.  Put analysis in dsp/sym/*.sym and in those upstream tools -- never in the
generated .dsm.

Inputs (override with flags):
    --sub    original_ROMs/kn5000_subprogram_v142.rom   (the DSP programs, base 0xEF00)
    --main   original_ROMs/kn5000_v10_program.rom       (effect NAME + T1 coeff maps)
    --tools  ~/compartilhado/kn7000_mame/tools          (the reused RE tools)
    --out    dsp/                                        (the tree to (re)write)

The raw per-image binaries are NOT written into the repo (derived ROM data,
regenerable) -- only the annotated listings + manifest, matching the host repo's
"derived data is never committed" policy.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                     # the vendored ISA mirror

ROM_BASE   = 0xEF00
ALGO_TABLE = 0x0001ED7C                    # 100 x u32 -> microprogram streams
N_ALGOS    = 100
HEADER_ROM = 0x01E496                      # common 60-word header (op-3 record)
MALFORMED  = {79, 88, 89, 90, 91}          # streams with no valid I-RAM image
REVERB_BASE = 0x90                         # unit-1 coefficient bank base

# --------------------------------------------------------------------------
#  Per-image METADATA (family / confidence / role).  Keyed by the representative
#  (lowest) algo slot of each distinct image.  The effect NAME is read live from
#  the main ROM; only the analyst's family/role/confidence live here.  Sources:
#  notes/kn5000-dsp-effect-map.md (per-effect confidence), -semantics.md and
#  -reverb.md (the two SOLVED families).  Confidence labels are copied faithfully
#  and NOT upgraded: SOLVED = decoded to the bit; high/medium = structural map.
# --------------------------------------------------------------------------
META = {
    0:  ("dynamics",   "medium", "dry pass-through that still runs a level detector (2/pi env, one-pole smoothers); shared by 42 effect slots"),
    1:  ("modulation", "high",   "quadrature 2-voice chorus (LFO-swept delay, wet 0.25/0.15)"),
    2:  ("modulation", "high",   "modulated chorus: dual-rate ensemble"),
    3:  ("filter",     "medium", "enhancer: phase/emphasis shaping"),
    4:  ("modulation", "medium", "flanger: swept all-pass chain, 0.3 feedback, wet mix"),
    5:  ("modulation", "medium", "phaser: LFO-swept first-order all-pass chain (~0.438 +/-0.025), 0.3 feedback"),
    6:  ("modulation", "medium", "ensemble: multi-voice chorus"),
    8:  ("reverb",     "medium", "gated reverb: all-pass ring + hold gate"),
    9:  ("delay",      "high",   "single delay: 0.5 mix, 0.15/0.3 feedback"),
    10: ("delay",      "high",   "multi-tap delay: panning taps (partial-cursor-rewind idiom, effect-map 5.1)"),
    15: ("rotary",     "high",   "rock rotary / rotary speaker (shared with algo 53)"),
    16: ("reverb",     "SOLVED", "reverb tank: two ladders of 5 all-pass diffusers + damping (decoded to the bit); the ONLY unit-1 image, shared by the 12 reverb presets algos 16-27"),
    32: ("distortion", "high",   "distortion: AGC waveshaper, curve A"),
    33: ("distortion", "high",   "overdrive: waveshaper + smoother + 4kHz Butterworth tone"),
    34: ("distortion", "high",   "fuzz: rail-clip waveshaper"),
    35: ("exciter",    "high",   "harmonic exciter: LUT -> band-pass -> +dry"),
    36: ("dynamics",   "medium", "compressor: envelope detector (C40) + gain-computer (THRESHOLD/RATIO)"),
    39: ("eq",         "SOLVED", "parametric EQ: 5 bands x 2 channels, Direct-Form-I bilinear biquad (decoded to the bit); the reference program"),
    48: ("am",         "high",   "auto pan: quadrature LFO amplitude panner"),
    50: ("modulation", "high",   "vibrato: wet-only modulated delay"),
    52: ("filter",     "medium", "auto wah: envelope-swept resonator"),
    54: ("am",         "high",   "ring modulator: audio-rate quadrature AM"),
    56: ("modulation", "medium", "mix up: burst vibrato (sin.sin product modulators)"),
    64: ("combi",      "high",   "single delay + chorus"),
    65: ("delay",      "high",   "single delay + single delay (dual mono)"),
    66: ("combi",      "medium", "single delay + flanger"),
    67: ("combi",      "high",   "single delay + vibrato"),
    68: ("combi",      "medium", "single delay + phaser (keeps the two all-pass markers)"),
    70: ("combi",      "medium", "auto wah + single delay"),
    71: ("combi",      "high",   "1-band flat PEQ + chorus"),
    72: ("combi",      "high",   "1-band flat PEQ + single delay"),
    73: ("combi",      "high",   "1-band flat PEQ + flanger"),
    74: ("combi",      "high",   "1-band flat PEQ + vibrato"),
    75: ("combi",      "high",   "1-band flat PEQ + compressor (+4 cursor/host offset, effect-map 5.2)"),
    96: ("combi",      "high",   "PEQ + compressor + distortion"),
    97: ("combi",      "high",   "PEQ + compressor + overdrive (overdrive tone biquad present)"),
    98: ("combi",      "high",   "PEQ + distortion + delay"),
    99: ("combi",      "high",   "PEQ + overdrive + delay (4 biquad sections: 2 flat PEQ + 2 copies of OVERDRIVE, byte-for-byte)"),
}


# --------------------------------------------------------------------------
#  ROM access + extraction (REUSED from the research tree -- no re-parsing here)
# --------------------------------------------------------------------------
def import_research_tools(tools_dir):
    if not os.path.isdir(tools_dir):
        sys.exit("ERROR: research tools dir not found: %s\n"
                 "  Pass --tools <path to kn7000_mame/tools>.  It supplies the ROM\n"
                 "  parser (kn5000_dsp_extract) and the named-coefficient overlay\n"
                 "  (kn5000_dsp_namedcoeff / kn5000_dsp_params)." % tools_dir)
    sys.path.insert(0, tools_dir)
    import kn5000_dsp_extract as E
    import kn5000_dsp_params as P
    import kn5000_dsp_namedcoeff as NC
    return E, P, NC


def extract_all(E, sub_path):
    """-> (header_words, {algo: words}).  header is the shared 60-word kernel."""
    rom = E.Rom(sub_path)
    # shared header
    iram, _c, _o = E.parse_stream(rom, HEADER_ROM, limit=40)
    header = [int.from_bytes(bytes(w), "big") for w in iram[0][1]] if iram else []
    # every algorithm stream
    progs = {}
    loadaddr = {}
    for i in range(N_ALGOS):
        ptr = rom.u32le(ALGO_TABLE + 4 * i)
        try:
            iram, _c, _o = E.parse_stream(rom, ptr)
        except Exception:
            continue
        if not iram:
            continue
        words = [int.from_bytes(bytes(w), "big") for w in
                 (wd for _a, ws, _l in iram for wd in ws)]
        progs[i] = words
        loadaddr[i] = iram[0][0]
    return header, progs, loadaddr


def group_images(progs):
    """-> ordered list of (rep_algo, [slots], words), collapsing byte-identical
    images and excluding the malformed streams.  Deterministic (sorted)."""
    groups = {}
    for a in sorted(progs):
        if a in MALFORMED:
            continue
        groups.setdefault(tuple(progs[a]), []).append(a)
    out = [(algos[0], algos, list(words)) for words, algos in groups.items()]
    out.sort(key=lambda t: t[0])
    return out


# --------------------------------------------------------------------------
#  sym overlay -- hand-curated labels/comments, repo style "0xADDR Name ; note"
#  but keyed here by WORD INDEX: "wNN  Label   ; comment".  Loss-free across
#  regeneration because the .dsm is generated and the .sym is the source.
# --------------------------------------------------------------------------
def load_sym(path):
    labels, comments = {}, {}
    if not os.path.exists(path):
        return labels, comments
    for raw in open(path):
        line = raw.rstrip("\n")
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        body, _, comment = line.partition(";")
        toks = body.split()
        if not toks:
            if comment.strip():
                pass
            continue
        idx = toks[0]
        if not idx.startswith("w"):
            continue
        try:
            wi = int(idx[1:])
        except ValueError:
            continue
        if len(toks) >= 2:
            labels[wi] = toks[1]
        if comment.strip():
            comments[wi] = comment.strip()
    return labels, comments


# --------------------------------------------------------------------------
#  named-coefficient overlay (pulled LIVE from the research tools)
# --------------------------------------------------------------------------
def coeff_overlay(P, NC, sub_rom, algo, words):
    """-> list over word indices of a short 'coeff' note string or None, using
    the CURRENT named-coefficient join.  Degrades to bare C-RAM addresses (which
    dsp_disasm already prints) if the host map is empty."""
    base = REVERB_BASE if algo in set(range(16, 28)) else 0x00
    cmap = NC.host_coeff_map(sub_rom, algo)
    ann = NC.annotate_image(words, base, cmap, base == REVERB_BASE)
    out = [None] * len(words)
    for i, x in enumerate(ann):
        if x is None:
            continue
        k, haddr, op, role, ev, name = x
        if op is None:
            continue
        out[i] = "coeff C-RAM[0x%02X] = %s (role %s, %s)" % (haddr, name, role, ev)
    return out


# --------------------------------------------------------------------------
#  emit one listing
# --------------------------------------------------------------------------
LICENSE = ["; license:BSD-3-Clause", "; copyright-holders:Felipe Sanches"]


def emit_listing(path, title_lines, words, cur_base, sym_labels, sym_comments,
                 coeff_notes):
    lines = list(LICENSE)
    lines += title_lines
    lines.append(";")
    lines.append("; GENERATED by dsp/tools/gen_dsp_disasm.py -- DO NOT EDIT.")
    lines.append("; Put labels/comments in the matching dsp/sym/*.sym; analysis in dsp/algorithms/.")
    lines.append("")
    curs = D.cursor_addresses(words)
    for i, w in enumerate(words):
        # optional label line (sym), repo style
        if i in sym_labels:
            lines.append("%s:" % sym_labels[i])
        body = "  w%-3d  %010X   %s" % (i, w & D.WORD_MASK, D.text(w))
        lines.append(body)
        # absolute C-RAM address for class-A words, with the unit base applied
        if curs[i] is not None:
            addr = (cur_base + curs[i]) & 0xFF
            note = "        ; C-RAM[0x%02X] (coeff, base 0x%02X MEASURED)" % (addr, cur_base)
            lines.append(note)
        if coeff_notes and coeff_notes[i]:
            lines.append("        ; %s" % coeff_notes[i])
        if i in sym_comments:
            lines.append("        ; %s" % sym_comments[i])
    lines.append("")
    with open(path, "w") as f:
        f.write("\n".join(lines))


# --------------------------------------------------------------------------
def main():
    repo = os.path.abspath(os.path.join(HERE, "..", ".."))
    ap = argparse.ArgumentParser()
    ap.add_argument("--sub",  default=os.path.join(repo, "original_ROMs", "kn5000_subprogram_v142.rom"))
    ap.add_argument("--main", default=os.path.join(repo, "original_ROMs", "kn5000_v10_program.rom"))
    ap.add_argument("--tools", default=os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
    ap.add_argument("--out",  default=os.path.join(repo, "dsp"))
    args = ap.parse_args()

    E, P, NC = import_research_tools(args.tools)
    sub_rom = P.Rom(args.sub, P.SUB_BASE)
    main_rom = P.Rom(args.main, 0) if os.path.exists(args.main) else None

    header, progs, loadaddr = extract_all(E, args.sub)
    images = group_images(progs)

    disdir = os.path.join(args.out, "disasm")
    symdir = os.path.join(args.out, "sym")
    os.makedirs(disdir, exist_ok=True)
    os.makedirs(symdir, exist_ok=True)

    def name_of(a):
        return P.effect_name(main_rom, a) if main_rom else ("algo%d" % a)

    # ---- shared kernel (the common header) ----
    ksl, ksc = load_sym(os.path.join(symdir, "kernel.sym"))
    emit_listing(
        os.path.join(disdir, "kernel.dsm"),
        ["; KN5000 effects-DSP SHARED KERNEL -- common header, I-RAM 0..59 (60 words)",
         "; Uploaded once at boot from Sub CPU ROM 0x%06X (op-3 record, EFF_WriteHeader" % HEADER_ROM,
         "; @subcpu 0x0380C1).  Runs every frame; CALLs unit-0 body (I-RAM 84) then unit-1",
         "; body (I-RAM 200) and returns -- see dsp/instruction-set.md 'Control flow'.",
         "; The 23-word algorithm-change stub (I-RAM 60..82) is host-patched per effect and",
         "; is not part of this stream."],
        header, 0x00, ksl, ksc, None)

    # ---- per-image listings + manifest rows ----
    rows = []
    for rep, slots, words in images:
        fam, conf, role = META.get(rep, ("?", "?", ""))
        nm = name_of(rep)
        la = loadaddr.get(rep, 0)
        unit = 0 if la == 84 else (1 if la == 200 else -1)
        base = REVERB_BASE if unit == 1 else 0x00
        safe = "".join(c if c.isalnum() else "_" for c in nm.lower()).strip("_")
        fn = "prog%02d_%s.dsm" % (rep, safe)
        symfn = "prog%02d.sym" % rep
        sl, sc = load_sym(os.path.join(symdir, symfn))
        cnotes = coeff_overlay(P, NC, sub_rom, rep, words) if main_rom else None
        na = sum(1 for w in words if D.coeff_consumer(w))
        named = sum(1 for n in (cnotes or []) if n)
        emit_listing(
            os.path.join(disdir, fn),
            ["; KN5000 effects-DSP program -- %s" % nm,
             "; image rep algo %d  |  slots %s  |  unit %d (I-RAM load %d)" %
                (rep, ",".join(map(str, slots)), unit, la),
             "; family %s  |  confidence %s  |  %d words, %d class-A multiplies (%d named)" %
                (fam, conf, len(words), na, named),
             "; role: %s" % role,
             "; coefficient cursor base 0x%02X" % base],
            words, base, sl, sc, cnotes)
        rows.append((rep, nm, unit, la, len(words), na, named, len(slots), fam, conf, role, fn))

    # ---- programs.tsv ----
    tsv = os.path.join(args.out, "programs.tsv")
    with open(tsv, "w") as f:
        f.write("# KN5000 effects-DSP (NEC uPD6383GF) distinct-program manifest -- GENERATED by dsp/tools/gen_dsp_disasm.py\n")
        f.write("# rep\teffect_name\tunit\tload\twords\tclassA\tnamed\tslots\tfamily\tconfidence\tlisting\trole\n")
        for (rep, nm, unit, la, nw, na, named, ns, fam, conf, role, fn) in rows:
            f.write("%d\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%s\t%s\t%s\t%s\n" %
                    (rep, nm, unit, la, nw, na, named, ns, fam, conf, fn, role))

    # ---- index.dsm (rendered manifest) ----
    idx = os.path.join(disdir, "index.dsm")
    with open(idx, "w") as f:
        f.write("\n".join(LICENSE) + "\n")
        f.write("; KN5000 effects-DSP disassembly INDEX -- GENERATED by dsp/tools/gen_dsp_disasm.py\n;\n")
        f.write("; NEC uPD6383GF (IC311).  %d distinct microprogram images serve ~100 effect\n" % len(rows))
        f.write("; slots; 5 malformed streams excluded (algos %s).  The shared kernel (common\n"
                % ",".join(map(str, sorted(MALFORMED))))
        f.write("; 60-word header) is kernel.dsm.\n;\n")
        f.write("; %-4s %-20s %-4s %-5s %-6s %-7s %-6s %-8s %-10s %s\n" %
                ("rep", "effect", "unit", "load", "words", "classA", "named", "slots", "conf", "listing"))
        for (rep, nm, unit, la, nw, na, named, ns, fam, conf, role, fn) in rows:
            f.write("; %-4d %-20s %-4d %-5d %-6d %-7d %-6d %-8d %-10s %s\n" %
                    (rep, nm[:20], unit, la, nw, na, named, ns, conf, fn))
        tot_na = sum(r[5] for r in rows)
        tot_named = sum(r[6] for r in rows)
        f.write(";\n; totals: %d images, %d class-A multiplies, %d named (%.1f%%)\n" %
                (len(rows), tot_na, tot_named, 100.0 * tot_named / tot_na if tot_na else 0.0))

    print("wrote %d program listings + kernel.dsm + index.dsm + programs.tsv" % len(rows))
    print("named coefficients: %d / %d class-A multiplies" %
          (sum(r[6] for r in rows), sum(r[5] for r in rows)))


if __name__ == "__main__":
    main()
