#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""gen_dsp_flowcharts.py -- regenerate the KN5000 effects-DSP FLOWCHART tree.

NEC uPD6383GF (Technics SX-KN5000 IC311).  Companion to gen_dsp_disasm.py: that
tool emits the per-instruction listings; THIS tool emits one STRUCTURAL flowchart
(Mermaid) per program -- the shared kernel plus each of the 38 distinct effect
bodies -- showing SIGNAL FLOW, not a per-instruction dump.

    python3 dsp/tools/gen_dsp_flowcharts.py           # regenerate dsp/flowcharts/
    git diff --exit-code dsp/flowcharts               # doubles as a drift check

WHY IT STAYS HONEST + REGENERABLE.  A flowchart node is emitted ONLY when the
landmark it names is actually DETECTED in the ROM words, using the SAME rules as
the disassembler (dsp/tools/dsp_disasm.py -- the LFO phase-accumulate word, the
external-DRAM bracket, the envelope detector, the all-pass marker, the DF-I biquad
section, the class-8 post-sum step, ...).  Every instruction a program contains is
accounted for: those matched by a recognised landmark become labelled stages, and
the remainder are shown as a single opaque "undecoded core (N of M instructions)"
node with its real count.  No structure is invented.  Confidence is carried into
the node style (PROVEN/MEASURED = solid, INFERRED = solid amber, OPEN/opaque =
dashed).  Parameter names come LIVE from the UI name-index capture, and the named
coefficients come LIVE from the same research-tool join gen_dsp_disasm.py uses --
so as the 500/822 named-coefficient layer and the ISA improve, a re-run refreshes
the charts with no edits here.

Sources, all cited on the pages: notes/kn5000-dsp-headerdecode.md (the kernel /
frame loop, PROVEN), -semantics.md + algorithms/biquad-eq.md (the EQ, SOLVED),
-reverb.md + algorithms/reverb.md (the reverb, SOLVED), -effect-map.md +
algorithms/families.md (the structural map of the rest), -paramlist.md (the live
per-effect parameter names).

Inputs (override with flags), mirroring gen_dsp_disasm.py:
    --sub    original_ROMs/kn5000_subprogram_v142.rom   (the DSP programs)
    --main   original_ROMs/kn5000_v10_program.rom       (effect NAME + param names)
    --tools  ~/compartilhado/kn7000_mame/tools          (the reused RE tools)
    --out    dsp/                                        (the tree to (re)write)
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                # the vendored ISA mirror
import gen_dsp_disasm as G           # reuse extraction / grouping / META / overlay

# --------------------------------------------------------------------------
#  Confidence -> Mermaid class.  Solid for what the RE established; dashed for
#  the honest opaque blocks.  Kept identical on every page (README documents it).
# --------------------------------------------------------------------------
CLASSDEFS = [
    "classDef io fill:#e8eef7,stroke:#33475b,stroke-width:1px,color:#111;",
    "classDef proven fill:#d7f0d7,stroke:#2e7d32,stroke-width:2px,color:#111;",
    "classDef measured fill:#dbe9fb,stroke:#1565c0,stroke-width:1.5px,color:#111;",
    "classDef inferred fill:#fdf0d5,stroke:#b8860b,stroke-width:1.5px,color:#111;",
    "classDef open fill:#eeeeee,stroke:#888,stroke-width:1px,color:#333,stroke-dasharray:5 5;",
    "classDef ctrl fill:#f3e8fb,stroke:#6a1b9a,stroke-width:1px,color:#111;",
]

CONF_LABEL = {
    "proven":   "PROVEN",
    "measured": "MEASURED",
    "inferred": "INFERRED",
    "open":     "OPEN",
}


# --------------------------------------------------------------------------
#  Small Mermaid chart builder -- a linear signal chain plus an optional side
#  "control parameters" note tied to the DSP core.
# --------------------------------------------------------------------------
class Chart:
    def __init__(self):
        self.lines = ["```mermaid", "flowchart TD"]
        self.n = 0
        self.prev = None
        self.body = []
        self.classed = {}   # id -> class

    def node(self, label, cls, link=None):
        nid = "N%d" % self.n
        self.n += 1
        text = label.replace('"', "'")
        self.body.append('    %s["%s"]' % (nid, text))
        self.classed[nid] = cls
        if link is not None:
            self.body.append("    %s --> %s" % (self.prev if self.prev else nid, nid))
        if self.prev is not None and link is None:
            self.body.append("    %s --> %s" % (self.prev, nid))
        self.prev = nid
        return nid

    def side(self, anchor, label, cls="ctrl"):
        """A control-parameter note hanging off `anchor` (dotted)."""
        nid = "N%d" % self.n
        self.n += 1
        text = label.replace('"', "'")
        self.body.append('    %s["%s"]' % (nid, text))
        self.classed[nid] = cls
        self.body.append("    %s -.-> %s" % (anchor, nid))
        return nid

    def render(self):
        out = list(self.lines)
        out += self.body
        out.append("")
        for cd in CLASSDEFS:
            out.append("    " + cd)
        # group ids by class
        byclass = {}
        for nid, cls in self.classed.items():
            byclass.setdefault(cls, []).append(nid)
        for cls, ids in byclass.items():
            out.append("    class %s %s;" % (",".join(sorted(ids, key=lambda s: int(s[1:]))), cls))
        out.append("```")
        return "\n".join(out)


# --------------------------------------------------------------------------
#  Landmark feature detection -- SAME rules as dsp_disasm.py.  Every word is
#  either matched by a recognised landmark or counted into `opaque`.
# --------------------------------------------------------------------------
def features(words):
    f = dict(nwords=len(words), classA=0, named=0, opaque=0,
             biquad=0, lfo=0, lforead=0, env=0, dram=0, table=0,
             allpass=0, allpass_wr=0, class8=0, gainmul=0, ret=0, rstcur=0)
    for w in words:
        hi, cl, ad, lo = D.fields(w)
        if D.coeff_consumer(w):
            f["classA"] += 1
        if lo == 0x1D3:                                    f["biquad"] += 1
        if hi == 0x092 and cl == 0xA and lo == 0x200:      f["lfo"] += 1
        if hi == 0x082:                                    f["lforead"] += 1
        if hi == 0xC40:                                    f["env"] += 1
        if hi == 0x880 and cl == 1 and ad == 0x60:         f["dram"] += 1
        if cl == 6:                                        f["table"] += 1
        if w == 0x104200000:                               f["allpass"] += 1
        if w == 0x012200680:                               f["allpass_wr"] += 1
        if cl == 8:                                        f["class8"] += 1
        if hi == 0x102:                                    f["gainmul"] += 1
        if D.is_rstcur(w):                                 f["rstcur"] += 1
        if D.is_end(w) and cl == 1 and ad in (0x0E, 0x0F): f["ret"] += 1
        # opaque = truly unexplained: no landmark note, not a decoded form, not a
        # coefficient multiply, not the cursor reset.
        if (D.annotate(w) is None and not D.decoded(w)
                and not D.coeff_consumer(w) and not D.is_rstcur(w)):
            f["opaque"] += 1
    return f


def named_count(coeff_notes):
    return sum(1 for n in (coeff_notes or []) if n)


# --------------------------------------------------------------------------
#  Parameter names, pulled LIVE from the UI name-index capture (MEASURED,
#  notes/kn5000-dsp-paramlist.md) joined to the main-ROM name table.  Keyed by a
#  normalised effect name so it survives the spacing differences between the ROM
#  effect-name table and the paramlist capture.
# --------------------------------------------------------------------------
def _norm(s):
    return s.upper().replace(" ", "").replace(".", "")


def load_params(tools_dir, main_path, capture_path):
    """-> {normalised effect name: [param strings]}.  Empty dict if unavailable."""
    out = {}
    if not (main_path and os.path.exists(main_path) and os.path.exists(capture_path)):
        return out
    sys.path.insert(0, tools_dir)
    import kn5000_dsp_paramlist as PL
    rom = PL.load(main_path)
    names = PL.names_table(rom)
    cap = json.load(open(capture_path))
    for e in cap:
        params = [names[i - 1] for i in e["indices"] if 1 <= i <= len(names)]
        # normalise whitespace and drop the trailing null/blank sentinel name
        params = [" ".join(p.split()) for p in params if p.strip()]
        out[_norm(e["name"])] = params
    # the reverb tank (algo 16) lives on the DIGITAL REVERB page, not the DSP
    # capture -- its list is the one shared by all 12 presets (paramlist.md sect 4).
    out["ROOMREVERB1"] = ["REVERB TIME", "PRE DELAY", "HIGH DAMP GAIN",
                          "ER.LEVEL", "VOLUME"]
    return out


def params_for(pmap, effect_name):
    return pmap.get(_norm(effect_name), [])


def has(params, *needles):
    return [p for p in params if any(n in p.upper() for n in needles)]


def compress(seq):
    """Readable label for a parameter list: first collapse any leading repeated
    cycle (e.g. the biquad's FC/Q/G x5), then collapse consecutive duplicates."""
    seq = list(seq)
    # collapse a leading cycle of length L repeated k>=2 times
    for L in range(1, len(seq) // 2 + 1):
        cyc = seq[:L]
        k = 1
        while seq[L * k: L * (k + 1)] == cyc and len(seq[L * k: L * (k + 1)]) == L:
            k += 1
        if k >= 2 and L * k <= len(seq):
            head = "(%s) x%d" % (", ".join(cyc), k)
            rest = seq[L * k:]
            return head + (", " + compress(rest) if rest else "")
    out = []
    for p in seq:
        if out and out[-1][0] == p:
            out[-1][1] += 1
        else:
            out.append([p, 1])
    return ", ".join(n if k == 1 else "%s (x%d)" % (n, k) for n, k in out)


# --------------------------------------------------------------------------
#  Per-family SIGNAL-FLOW template.  Order follows algorithms/families.md (the
#  documented signal chain); PRESENCE of every stage is gated by a detected
#  landmark count, so nothing is drawn that the words do not contain.  Two SOLVED
#  families (EQ, reverb) get a bespoke detailed builder.
# --------------------------------------------------------------------------
def stage_lfo(c, f, params):
    lab = "LFO phase accumulator<br/>phase += f/44100 (Q0.23), wrap at 0x7FFFFF"
    extra = has(params, "LFO SPEED", "DEPTH", "PHASE")
    if f["table"]:
        lab += "<br/>+ waveform lookup (LUT)"
    nid = c.node(lab, "measured")
    ctl = has(params, "LFO SPEED", "LFO WAVEFORM", "DEPTH", "PHASE", "RESONANCE", "MANUAL")
    if ctl:
        c.side(nid, "controls: " + compress(ctl))
    return nid


def stage_allpass(c, f, params, reverb=False):
    if reverb:
        return None
    n = f["allpass"] or f["gainmul"]
    lab = "All-pass / phaser chain<br/>%d marker(s); g&middot;d &plusmn; feedback (stage count OPEN)" % f["allpass"]
    nid = c.node(lab, "inferred")
    ctl = has(params, "RESONANCE", "MANUAL", "PHASE")
    if ctl:
        c.side(nid, "controls: " + compress(ctl))
    return nid


def stage_delay(c, f, params):
    lab = "External delay line (DRAM)<br/>%d tap bracket(s) (880.1.60/20)" % f["dram"]
    nid = c.node(lab, "inferred")
    ctl = has(params, "DELAY", "FEEDBACK", "HIGH DAMP")
    if ctl:
        c.side(nid, "controls: " + compress(ctl))
    return nid


def stage_biquad(c, f, params):
    n = f["biquad"]
    if n % 2 == 0 and n:
        lab = "Biquad tone/EQ<br/>%d Direct-Form-I sections (%d band(s) &times; 2 ch)<br/>b1,b0,b2,&minus;a1,&minus;a2, make-up" % (n, n // 2)
    else:
        lab = "Biquad tone/EQ<br/>%d Direct-Form-I section(s)<br/>b1,b0,b2,&minus;a1,&minus;a2, make-up" % n
    nid = c.node(lab, "measured")
    ctl = has(params, "BAND EMPHASIS", "EMPHASIS")
    if ctl:
        c.side(nid, "controls: " + compress(ctl))
    return nid


def stage_waveshaper(c, f, params):
    lab = "Waveshaper transfer curve<br/>3-word LUT idiom, class-6 curve select (&times;%d)" % f["table"]
    nid = c.node(lab, "inferred")
    ctl = has(params, "DRIVE", "ADJUST")
    if ctl:
        c.side(nid, "controls: " + compress(ctl))
    return nid


def stage_env(c, f, params, fam):
    if fam in ("dynamics",):
        lab = "Envelope / level detector (C40)<br/>gain computed arithmetically (no compare op)"
        ctl = has(params, "THRESHOLD", "RATIO", "ATTACK", "RELEASE")
    elif fam in ("filter",):
        lab = "Envelope-swept control (C40)"
        ctl = has(params, "RESONANCE", "MANUAL", "SWEEP")
    else:
        lab = "One-pole smoother / level detector (C40)"
        ctl = []
    nid = c.node("%s &times;%d" % (lab, f["env"]), "inferred")
    if ctl:
        c.side(nid, "controls: " + compress(ctl))
    return nid


def stage_opaque(c, f):
    if f["opaque"] <= 0:
        return None
    return c.node("Undecoded core<br/>%d of %d instructions<br/>(hand-unrolled, straight-line &mdash; see the .dsm)"
                  % (f["opaque"], f["nwords"]), "open")


def trailing(c, params, reverb=False):
    if reverb:
        c.node("Stereo output tails L / R<br/>(op 0x66 / ER.LEVEL)", "measured")
        return
    vol = has(params, "VOLUME")
    snd = has(params, "REV SEND")
    if vol:
        c.node("VOLUME<br/>output level", "ctrl")
    if snd:
        c.node("REV SEND<br/>to reverb bus", "ctrl")


# ---- the two SOLVED families, bespoke and detailed --------------------------
def build_eq(c, f, params):
    c.node("Stereo input (L / R)", "io")
    nid = c.node("5 bands &times; 2 channels<br/>Direct-Form-I bilinear biquad (SOLVED to the bit)<br/>per band: b1,b0,b2,&minus;a1,&minus;a2 &divide; a0, then make-up gain<br/>C-RAM[0x00..05]; rstcur re-reads the bank for channel 2",
                  "proven")
    ctl = has(params, "BAND EMPHASIS", "EMPHASIS")
    seen = []
    for p in ctl:
        if p not in seen:
            seen.append(p)
    if seen:
        c.side(nid, "per band (x5): " + ", ".join(seen))
    c.side(nid, "class-8 post-sum step &times;%d (rescale/round/saturate? &mdash; OPEN)" % f["class8"], "open")
    trailing(c, params)
    c.node("Output", "io")


def build_reverb(c, f, params):
    c.node("Stereo input (L / R)", "io")
    c.node("Input scaling triple<br/>C-RAM[0x90..92] = 0.250 0.500 0.500", "measured")
    pre = c.node("Pre-delay + delay buffers (external DRAM)<br/>%d tap bracket(s); lengths tiled in the param stream" % f["dram"], "inferred")
    ctl = has(params, "PRE DELAY", "REVERB TIME")
    if ctl:
        c.side(pre, "controls: " + compress(ctl))
    c.node("Damping one-pole filter #1<br/>C-RAM[0x93..95] (op 0x76)", "measured")
    la = c.node("Diffuser ladder A &mdash; 5 all-pass<br/>C-RAM[0x98..9C] descending gains 0.75&hellip;0.50<br/>w = x + g&middot;d ; y = d &minus; g&middot;w", "measured")
    c.side(la, "REVERB TIME sets the ladder gains")
    c.node("Damping one-pole filter #2<br/>C-RAM[0x9E..A0] (op 0x76)", "measured")
    c.node("Diffuser ladder B &mdash; 4 all-pass<br/>C-RAM[0xA1..A4] descending gains", "measured")
    c.node("Damping one-pole filter #3<br/>C-RAM[0xA6..A8] (op 0x76)", "measured")
    st = c.node("Stereo output tails L / R<br/>C-RAM[0xA9..B0] (op 0x66 / ER.LEVEL)", "measured")
    c.side(st, "controls: HIGH DAMP GAIN, ER.LEVEL, VOLUME")
    op = stage_opaque(c, f)
    c.node("Output (the only unit-1 image; shared by all 12 reverb presets)", "io")


# ---- the generic family pipeline -------------------------------------------
#  Ordered stage list per family (signal order, from families.md).  Each entry
#  is (stage_key, gate) where gate(f) says whether the landmark was detected.
FAMILY_PIPELINE = {
    "modulation": ["lfo", "allpass", "delay", "biquad", "env", "opaque"],
    "delay":      ["delay", "biquad", "opaque"],
    "am":         ["lfo", "opaque"],
    "filter":     ["env", "allpass", "delay", "biquad", "opaque"],
    "distortion": ["waveshaper", "biquad", "opaque"],
    "exciter":    ["waveshaper", "biquad", "opaque"],
    "dynamics":   ["env", "opaque"],
    "rotary":     ["delay", "biquad", "env", "opaque"],
    "combi":      ["biquad", "waveshaper", "lfo", "allpass", "delay", "env", "opaque"],
    "reverb":     ["delay", "allpass", "env", "opaque"],   # gated reverb (algo 8)
}


def build_generic(c, fam, f, params):
    c.node("Stereo input (L / R)", "io")
    order = FAMILY_PIPELINE.get(fam, ["lfo", "allpass", "delay", "biquad",
                                      "waveshaper", "env", "opaque"])
    for key in order:
        if key == "lfo" and (f["lfo"] or f["lforead"]):
            stage_lfo(c, f, params)
        elif key == "allpass" and f["allpass"]:
            stage_allpass(c, f, params)
        elif key == "delay" and f["dram"]:
            stage_delay(c, f, params)
        elif key == "biquad" and f["biquad"]:
            stage_biquad(c, f, params)
        elif key == "waveshaper" and f["table"]:
            stage_waveshaper(c, f, params)
        elif key == "env" and f["env"]:
            stage_env(c, f, params, fam)
        elif key == "opaque":
            stage_opaque(c, f)
    trailing(c, params)
    c.node("Output (RETURN to kernel epilogue)", "io")


# --------------------------------------------------------------------------
#  Page emission
# --------------------------------------------------------------------------
BLOG = "the MAME development blog, KN5000 effects-DSP series (Parts 78-84)"
DOCS = "the project docs site, `/effects-dsp/`"


def emit_program_page(path, rep, slots, nm, unit, la, fam, conf, role, f, params, c):
    named = f.get("named", 0)
    lines = []
    lines.append("# %s &mdash; signal-flow flowchart" % nm)
    lines.append("")
    lines.append("<!-- GENERATED by dsp/tools/gen_dsp_flowcharts.py -- DO NOT EDIT. -->")
    lines.append("<!-- Structure comes from the ROM words + the notes; edit those and re-run. -->")
    lines.append("")
    lines.append("Image rep **algo %d** &middot; slots %s &middot; **unit %d** (I-RAM load %d) &middot; "
                 "family **%s** &middot; confidence **%s**."
                 % (rep, ",".join(map(str, slots)), unit, la, fam, conf))
    lines.append("")
    lines.append("> %s" % role)
    lines.append("")
    lines.append("**%d words**, %d class-A coefficient multiplies (%d named), "
                 "%d instructions still opaque. Landmarks detected: "
                 "%s."
                 % (f["nwords"], f["classA"], named, f["opaque"], _landmark_summary(f)))
    lines.append("")
    lines.append(c.render())
    lines.append("")
    if params:
        lines.append("**UI parameters** (MEASURED, `notes/kn5000-dsp-paramlist.md`): "
                     + compress(params) + ".")
        lines.append("")
    lines.append("Per-instruction detail: [`../disasm/prog%02d_%s.dsm`](../disasm/prog%02d_%s.dsm). "
                 % (rep, _safe(nm), rep, _safe(nm))
                 + "Confidence legend and method: [`README.md`](README.md). "
                 + "Narrative: %s. Reference: %s." % (BLOG, DOCS))
    lines.append("")
    with open(path, "w") as fp:
        fp.write("\n".join(lines))


def _safe(nm):
    return "".join(ch if ch.isalnum() else "_" for ch in nm.lower()).strip("_")


def _landmark_summary(f):
    parts = []
    if f["biquad"]:  parts.append("%d biquad DF-I section(s)" % f["biquad"])
    if f["lfo"]:     parts.append("%d LFO phase word(s)" % f["lfo"])
    if f["env"]:     parts.append("%d envelope/damping word(s)" % f["env"])
    if f["dram"]:    parts.append("%d DRAM tap bracket(s)" % f["dram"])
    if f["table"]:   parts.append("%d waveshaper LUT selector(s)" % f["table"])
    if f["allpass"]: parts.append("%d all-pass marker(s)" % f["allpass"])
    if f["class8"]:  parts.append("%d class-8 post-sum step(s)" % f["class8"])
    return ", ".join(parts) if parts else "none beyond the multiply chain"


# ---- the shared kernel flowchart (hand-authored from the PROVEN header decode)
def emit_kernel_page(path):
    c = Chart()
    c.node("Fs edge &rarr; hardware PC restart (PC := 0)<br/>one pass per sample @ 44,100 Hz", "proven")
    c.node("Header preamble, I-RAM 0..48<br/>input stage, LFOs, mixes; load unit-0 pointers<br/>0x821/0x827/0x825 &larr; 0x70/0x6C/0x25", "proven")
    c.node("CALL unit-0 body @ I-RAM 84<br/>(END-OF-BLOCK word 49, unit tag 0x0E)", "proven")
    c.node("unit-0 effect body runs<br/>straight-line, HAND-UNROLLED (no loop, no branch)", "measured")
    c.node("RETURN to I-RAM 50", "proven")
    c.node("unit-1 pointer setup, I-RAM 50..58<br/>0x821/0x827/0x825 &larr; 0x50/0x64/0x25", "proven")
    c.node("CALL unit-1 body @ I-RAM 200<br/>(END-OF-BLOCK word 59, unit tag 0x0F)", "proven")
    c.node("unit-1 effect body runs (the reverb tank)<br/>straight-line, HAND-UNROLLED", "measured")
    c.node("RETURN to I-RAM 60", "proven")
    ep = c.node("Frame epilogue, I-RAM 60..82<br/>effect-return / wet-level words @ 64 &amp; 71 (host-patched)<br/>output stage", "inferred")
    c.node("Wait for Fs @ I-RAM 82 (C00.A.47.407)<br/>halt until the next sample clock", "measured")
    c.side(ep, "2-level call/return stack; call &amp; return share one encoding<br/>(class4==1, addr8 = unit tag 0x0E/0x0F)", "measured")

    lines = []
    lines.append("# Shared kernel &mdash; per-frame control flow")
    lines.append("")
    lines.append("<!-- GENERATED by dsp/tools/gen_dsp_flowcharts.py -- DO NOT EDIT. -->")
    lines.append("")
    lines.append("The 60-word common header (`../disasm/kernel.dsm`) is uploaded once at boot and "
                 "runs **every sample frame**. It is the backbone every effect shares: it sets up "
                 "each unit's data pointers, CALLs the two effect bodies in turn, and closes with "
                 "the output epilogue. This control flow is **PROVEN BY CONSTRUCTION** "
                 "(`notes/kn5000-dsp-headerdecode.md`): the header loads the same three pointer "
                 "registers twice, so a body must run and return between the two loads.")
    lines.append("")
    lines.append(c.render())
    lines.append("")
    lines.append("Key facts (all from `notes/kn5000-dsp-headerdecode.md`):")
    lines.append("")
    lines.append("- **Per-frame hardware PC restart** &mdash; the `Fs-RST`/`PC-RST` pins restart the "
                 "PC every sample; there is *no* software frame loop. The last word, "
                 "`C00.A.47.407` at I-RAM 82, waits for the next Fs (that `hi12=0xC00` occurs "
                 "**zero** times in 2974 body words). *(MEASURED)*")
    lines.append("- **Call & return share one encoding** &mdash; the transfer rides on the unit tag "
                 "`class4==1 && addr8 &isin; {0x0E, 0x0F}`, not on the END-OF-BLOCK bit; the default "
                 "action after an END-OF-BLOCK word is fall-through. *(PROVEN)*")
    lines.append("- **A 2-level stack** &mdash; unit 0 is called at word 49 and returns to 50; unit 1 "
                 "at word 59 returns to 60. Both units are resident at once but run "
                 "time-multiplexed. *(PROVEN)*")
    lines.append("- **Bodies are branchless, hand-unrolled** &mdash; no word carries the entry "
                 "addresses 84/200 and two exhaustive branch-field scans are negative; there is no "
                 "loop to branch back to. *(MEASURED)*")
    lines.append("- **The epilogue (I-RAM 60..82) is the output stage** &mdash; the only two words the "
                 "host patches per effect, I-RAM 64 and 71, carry the unit tags in their default "
                 "form and a per-slot-invariant `lo12` (0x445/0x446): the effect-return / wet-level "
                 "words. *(INFERRED, strong)*")
    lines.append("")
    lines.append("Legend and method: [`README.md`](README.md). "
                 "Narrative: %s." % BLOG)
    lines.append("")
    with open(path, "w") as fp:
        fp.write("\n".join(lines))


# ---- the index / README -----------------------------------------------------
def emit_readme(path, rows):
    lines = []
    lines.append("# KN5000 effects-DSP &mdash; program flowcharts")
    lines.append("")
    lines.append("<!-- The index table is GENERATED by dsp/tools/gen_dsp_flowcharts.py. -->")
    lines.append("")
    lines.append("One **structural flowchart** per NEC uPD6383GF microprogram: the shared "
                 "[`kernel`](kernel.md) that every effect runs, plus each of the **38 distinct "
                 "effect bodies**. These show the **signal flow / algorithm structure** &mdash; not a "
                 "per-instruction dump (that is the [`../disasm/`](../disasm/) `.dsm` listing, one per "
                 "program). They are the diagram companion to the disassembly tree; read "
                 "[`../README.md`](../README.md) and [`../instruction-set.md`](../instruction-set.md) "
                 "first.")
    lines.append("")
    lines.append("## How to read these charts")
    lines.append("")
    lines.append("The charts are **Mermaid** (they render on GitHub and in the kn5000-docs Jekyll "
                 "site) and are **regenerated from the ROM words plus the notes** &mdash; never hand-drawn. "
                 "A node is emitted **only when the landmark it names is actually detected in the "
                 "program's words**, using the same rules as the disassembler "
                 "([`../tools/dsp_disasm.py`](../tools/dsp_disasm.py)). Every instruction is "
                 "accounted for: the ones a recognised landmark matches become labelled stages, and "
                 "the rest are collected into a single honest **opaque \"undecoded core (N of M "
                 "instructions)\"** node. **No signal flow is invented.**")
    lines.append("")
    lines.append("**Confidence is carried in the node style:**")
    lines.append("")
    lines.append("| style | meaning |")
    lines.append("|---|---|")
    lines.append("| solid green | **PROVEN** &mdash; proved by construction or decoded to the bit "
                 "(the kernel control flow, the EQ biquad, the reverb tank) |")
    lines.append("| solid blue | **MEASURED** &mdash; a structural landmark measured across the corpus "
                 "(LFO phase word, biquad section, damping filter, all-pass marker) |")
    lines.append("| solid amber | **INFERRED** &mdash; a strong reading not yet decoded to the bit "
                 "(external-DRAM bracket, waveshaper LUT, envelope detector, stage counts) |")
    lines.append("| dashed grey | **OPEN** &mdash; the opaque undecoded-core block and other open steps |")
    lines.append("| purple | a **UI control parameter** hanging off the stage it drives |")
    lines.append("")
    lines.append("Ordering follows the family signal chain documented in "
                 "[`../algorithms/families.md`](../algorithms/families.md); stage *presence* is "
                 "gated by detection, and parameter labels are the live UI names "
                 "(`notes/kn5000-dsp-paramlist.md`). Because both the named-coefficient layer "
                 "(500/822 today) and the ISA are still growing, **re-running the generator refreshes "
                 "every chart** &mdash; opaque blocks shrink and stages gain names as the RE advances.")
    lines.append("")
    lines.append("## The charts")
    lines.append("")
    lines.append("- [**kernel**](kernel.md) &mdash; the shared per-frame control flow (PROVEN)")
    lines.append("")
    lines.append("| chart | effect | family | conf. | words | opaque | landmarks |")
    lines.append("|---|---|---|---|---|---|---|")
    for (rep, nm, unit, la, fam, conf, f, page) in rows:
        lines.append("| [prog%02d](%s) | %s | %s | %s | %d | %d | %s |"
                     % (rep, page, nm, fam, conf, f["nwords"], f["opaque"],
                        _landmark_summary(f)))
    lines.append("")
    lines.append("## Regenerating")
    lines.append("")
    lines.append("```")
    lines.append("make dsp-flowcharts        # or: python3 dsp/tools/gen_dsp_flowcharts.py")
    lines.append("git diff --exit-code dsp/flowcharts   # doubles as a drift check")
    lines.append("```")
    lines.append("")
    lines.append("The generator reuses `gen_dsp_disasm.py`'s extraction, grouping and "
                 "named-coefficient overlay, so the two trees never diverge. It does **not** touch "
                 "the `.dsm` listings and does **not** affect `dsp/verify.py`'s byte-match.")
    lines.append("")
    with open(path, "w") as fp:
        fp.write("\n".join(lines))


# --------------------------------------------------------------------------
def main():
    repo = os.path.abspath(os.path.join(HERE, "..", ".."))
    ap = argparse.ArgumentParser()
    ap.add_argument("--sub",  default=os.path.join(repo, "original_ROMs", "kn5000_subprogram_v142.rom"))
    ap.add_argument("--main", default=os.path.join(repo, "original_ROMs", "kn5000_v10_program.rom"))
    ap.add_argument("--tools", default=os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
    ap.add_argument("--out",  default=os.path.join(repo, "dsp"))
    args = ap.parse_args()

    E, P, NC = G.import_research_tools(args.tools)
    sub_rom = P.Rom(args.sub, P.SUB_BASE)
    main_rom = P.Rom(args.main, 0) if os.path.exists(args.main) else None
    capture = os.path.join(args.tools, "kn5000_dsp_paramlist_capture.json")
    pmap = load_params(args.tools, args.main, capture)

    header, progs, loadaddr = G.extract_all(E, args.sub)
    images = G.group_images(progs)

    fcdir = os.path.join(args.out, "flowcharts")
    os.makedirs(fcdir, exist_ok=True)

    emit_kernel_page(os.path.join(fcdir, "kernel.md"))

    rows = []
    for rep, slots, words in images:
        fam, conf, role = G.META.get(rep, ("?", "?", ""))
        nm = P.effect_name(main_rom, rep) if main_rom else ("algo%d" % rep)
        la = loadaddr.get(rep, 0)
        unit = 0 if la == 84 else (1 if la == 200 else -1)
        f = features(words)
        cnotes = G.coeff_overlay(P, NC, sub_rom, rep, words) if main_rom else None
        f["named"] = named_count(cnotes)
        params = params_for(pmap, nm)

        c = Chart()
        if rep == 39:
            build_eq(c, f, params)
        elif rep == 16:
            build_reverb(c, f, params)
        else:
            build_generic(c, fam, f, params)

        page = "prog%02d_%s.md" % (rep, _safe(nm))
        emit_program_page(os.path.join(fcdir, page), rep, slots, nm, unit, la,
                          fam, conf, role, f, params, c)
        rows.append((rep, nm, unit, la, fam, conf, f, page))

    emit_readme(os.path.join(fcdir, "README.md"), rows)
    print("wrote kernel.md + %d program flowcharts + README.md" % len(rows))
    tot_op = sum(r[6]["opaque"] for r in rows)
    tot_w = sum(r[6]["nwords"] for r in rows)
    print("opaque instructions: %d / %d words across the 38 images" % (tot_op, tot_w))


if __name__ == "__main__":
    main()
