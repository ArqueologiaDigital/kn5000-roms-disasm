#!/usr/bin/env python3
r"""name_dsp_param_value_formats.py -- name the DSP parameter value formatter and its 16 value-text tables (v10/v9/v7).

QUESTION IT ANSWERS / WHAT IT DOES
  FormatParamValueStr (sequencer/sequencer_ui.s) writes the value cell of one row of the DSP effect editor.  The
  row's parameter id is the byte at RAM 0x29AC + row -- the same id that DspItem0_DisplayParamNames and
  DspItem0_DisplayParamValues use to index DspParamName_Table (86 x 17) and DspParamUnit_Table (86 x 2) -- and
  the id alone picks the value format:
      id 0x00, 0x55                 blank (5 spaces)
      id 0x40, 0x41, 0x47           tested directly -> the LFO-speed text table
      id 0x49                       tested directly -> the rotor-speed text table
      id 0x08-0x19 / 0x20-0x39      byte [id - 8] / [id - 14] of a 44-byte table -> case of an 18-entry switch
      any other id                  sprintf "%5d"
  The switch cases either pass one 5-character-cell text table to the copy routine (Strncpy(dst, table + 5*value,
  5)), print "%5d", or print a signed " -%3d" / " +%3d" / "  %3d".  The older names called this an "Equalizer"
  formatter and named the tables after whatever routine sat before them (Equalizer_FormatDefault_Data_5,
  EntertainerGridCheck_Data_3, NakaData_WidgetDescriptors ...); the C members were DspValueText_<offset>.

  This script re-derives the id -> format map from each tree's own code and bytes, and asserts it equals the
  EXPECTED map below; it never names from a guess.  It parses:
    - the id tests and range checks in FormatParamValueStr,
    - the 44-byte table's bytes, from the tree's naka_widget_descriptors.bin,
    - the case table (`.short Case - Base`) in widget_descriptors.s,
    - the `ld xwa, <table>` in each case body.
  Each table is then named after the parameters whose ids select it (names from DspParamName_Table, units from
  DspParamUnit_Table):
      DspValueText_ReverbTime   0x22 REVERB TIME (s)            DspValueText_HighDampGain 0x24 HIGH DAMP GAIN
      DspValueText_GateTime     0x2E/0x2F GATE/MASK TIME (ms)   DspValueText_ReleaseRate  0x2D RELEASE RATE (s)
      DspValueText_AttackRate   0x2C ATTACK RATE (s)            DspValueText_SensTime     0x2A/0x2B ATTACK/RELEASE SENS. (s)
      DspValueText_Pitch        0x26/0x27 PITCH L/R             DspValueText_SlowFast     0x0D SLOW/FAST
      DspValueText_WindTime     0x10/0x11 WIND UP/DOWN (s)      DspValueText_RotorSpeed   0x0E 0x0F 0x12 0x13 0x49 (Hz)
      DspValueText_OscSpeed     0x15 OSC SPEED (Hz)             DspValueText_Waveform     0x31/0x32 LFO/OSC WAVEFORM
      DspValueText_LfoSpeed     0x08 0x09 0x40 0x41 0x47 (Hz)   DspValueText_EqGain       0x35 BAND EMPHASIS G
      DspValueText_EqQ          0x34 BAND EMPHASIS Q            DspValueText_EqFreq       0x20/0x33 HIGH/BAND EMPHASIS FC (Hz)
  EqGain and EqFreq are also the gain and frequency texts of the master equalizer screen (EqualizerCngFunc).
  The switch cases get the matching DspParamFmt_<same> names; the rest of the formatter gets DspParamFmt_* names.

  Steps:
    1. Writes scripts/renaming/rename_dsp_param_formats.sed and runs it (`sed -i -f`) on every
       v10/v9/v7 maincpu .s/.c/.ld file that holds an old name.
    2. In widget_descriptors.s: heads each table slice, rewrites the generated headers of the format strings, the
       44-byte table and the case table, and rebases `.equ DspEffectName_Strings` on NakaInst_FxReservedSlot_00
       (the same address, blob +0x1E1A).  The base was the blob's first label, which is now DspValueText_ReverbTime.
    3. In sequencer_ui.s: puts a header on FormatParamValueStr and replaces the one-line comments
       "Equalizer format dispatch/default".
    4. In naka_widget_descriptors.c: replaces the generated comments of those members (they credited each table to
       the label just before it).  It splits the 12-byte EqFormat_PositiveValue_Str into the two strings the code
       uses ("  %3d" and the 5-space blank), which have the same bytes.
  The C comment gate then needs this waiver for the generated comments it replaced (22 per file; the old text
  names the old labels):
      python3 scripts/analysis/assert_c_comments_preserved.py --base HEAD --allow \
        '/\* -+ \* (\[typed\] by build_value_text .*)?(DspValueText_\w+|Equalizer_FormatDefault_Str|EqFormat_NegativeValue_Str|EqFormat_PositiveValue_Str|PrepareAudioParam_Str|Equalizer_FormatDispatch_Table|Equalizer_FormatDispatch_CaseTable) -- .*' \
        v10/maincpu/ui_widgets/naka_widget_descriptors.c v9/... v7/...

RUN (repository root; idempotent: a second run finds nothing to rename and leaves headers alone)
  python3 scripts/tools/name_dsp_param_value_formats.py            # check only: derive + assert the map, print it
  python3 scripts/tools/name_dsp_param_value_formats.py --apply
  then: scripts/build/regenerate_v7_c_divergence.py --apply BEFORE make; make all; make gate-all
"""
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
APPLY = "--apply" in sys.argv
SED = os.path.join(REPO, "scripts/renaming/rename_dsp_param_formats.sed")
BLOB = "naka_widget_descriptors"

# table blob offset -> (new name, cells, unit, ids, description of the ids)
EXPECTED = {
    0x0000: ("ReverbTime", 100, "s", [0x22], "REVERB TIME"),
    0x01F4: ("HighDampGain", 25, "", [0x24], "HIGH DAMP GAIN"),
    0x0272: ("GateTime", 100, "ms", [0x2E, 0x2F], "GATE TIME, MASK TIME"),
    0x0466: ("ReleaseRate", 100, "s", [0x2D], "RELEASE RATE"),
    0x065A: ("AttackRate", 100, "s", [0x2C], "ATTACK RATE"),
    0x084E: ("SensTime", 100, "s", [0x2A, 0x2B], "ATTACK SENS., RELEASE SENS."),
    0x0A42: ("Pitch", 73, "", [0x26, 0x27], "PITCH L, PITCH R"),
    0x0BB0: ("SlowFast", 2, "", [0x0D], "SLOW/FAST"),
    0x0BBA: ("WindTime", 100, "s", [0x10, 0x11], "rotor WIND UP, WIND DOWN"),
    0x0DAE: ("RotorSpeed", 100, "Hz", [0x0E, 0x0F, 0x12, 0x13, 0x49],
             "TREBLE FAST, (treble) SLOW, BASS FAST, BASS SLOW, (treble) FAST"),
    0x0FA2: ("OscSpeed", 100, "Hz", [0x15], "OSC SPEED"),
    0x1196: ("Waveform", 3, "", [0x31, 0x32], "LFO WAVEFORM, OSC WAVEFORM"),
    0x11A6: ("LfoSpeed", 100, "Hz", [0x08, 0x09, 0x40, 0x41, 0x47],
             "LFO SPEED, SLOW LFO SPEED, FAST LFO SPEED L, FAST LFO SPEED R, FAST LFO SPEED"),
    0x139A: ("EqGain", 49, "", [0x35], "BAND EMPHASIS G"),
    0x1490: ("EqQ", 32, "", [0x34], "BAND EMPHASIS Q"),
    0x1530: ("EqFreq", 27, "Hz", [0x20, 0x33], "HIGH EMPHASIS FC, BAND EMPHASIS FC"),
}
EXPECTED_DECIMAL = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x0A, 0x0C, 0x14, 0x16, 0x17, 0x1A, 0x1B, 0x1C, 0x1D,
                    0x1E, 0x1F, 0x21, 0x23, 0x25, 0x28, 0x29, 0x30, 0x36, 0x37, 0x38, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E,
                    0x3F, 0x42, 0x43, 0x44, 0x45, 0x46, 0x48, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, 0x50, 0x51, 0x52,
                    0x53, 0x54]
EXPECTED_SIGNED = [0x0B, 0x18, 0x19, 0x39]          # RESONANCE, FEEDBACK L, FEEDBACK R, FEEDBACK
EXPECTED_BLANK = [0x00, 0x55]

# the formatter's own labels (not table-specific)
STATIC = [
    ("Equalizer_FormatDispatch_CaseTable", "DspParamFmt_CaseTable"),
    ("Equalizer_FormatDispatch_Table", "DspParamFmt_CaseByParamId"),
    ("Equalizer_FormatDispatch", "DspParamFmt_BySwitch"),
    ("Equalizer_FormatDispatch_Case12", "DspParamFmt_Signed"),
    ("EqFormat_NegativeValue", "DspParamFmt_SignedNonNegative"),
    ("EqFormat_PositiveValue", "DspParamFmt_SignedZero"),
    ("Equalizer_FormatDefault_Str", "DspParamFmt_NegativeFmt"),
    ("EqFormat_NegativeValue_Str", "DspParamFmt_PositiveFmt"),
    ("EqFormat_PositiveValue_Str", "DspParamFmt_ZeroFmt"),
    ("Equalizer_CopyFixedString_Str_Blank5", "DspParamFmt_BlankText"),
    ("Equalizer_CopyFixedString", "DspParamFmt_Blank"),
    ("PrepareAudioParam_Str", "DspParamFmt_DecimalFmt"),
    ("PrepareAudioParam", "DspParamFmt_Decimal"),
    ("SendAudioCommand", "DspParamFmt_Sprintf"),
    ("FormatParamStr_CopyEnumName", "DspParamFmt_CopyValueText"),
    ("Equalizer_PadSpaceAndReturn", "DspParamFmt_PadAndReturn"),
]


def lines_of(p):
    return open(p, "rb").read().decode("latin-1").split("\n")


def write(p, L):
    data = "\n".join(L).encode("latin-1")
    open(p + ".tmp", "wb").write(data)
    os.replace(p + ".tmp", p)


def code(line):
    return line.split(";", 1)[0].strip()


def label_line(L, name):
    return next(i for i, x in enumerate(L) if re.match(r'^%s:' % re.escape(name), x))


def derive(tree):
    """-> (id -> ('T', table label) | ('decimal',) | ('signed',) | ('blank',), table label -> blob offset,
           case labels in table order, dispatch-table label, case-table label, direct targets)"""
    root = os.path.join(REPO, tree, "maincpu")
    seq = lines_of(os.path.join(root, "sequencer/sequencer_ui.s"))
    wd = lines_of(os.path.join(root, "ui_widgets/widget_descriptors.s"))
    b = open(os.path.join(root, "includes/generated", BLOB + ".bin"), "rb").read()
    slices = {}
    for i, x in enumerate(wd):                  # `Label: .incbin` on one line, or `Label:` then `.incbin`
        m = re.match(r'^([A-Za-z_]\w*):\s*\.incbin\s+"includes/generated/%s\.bin",\s*(0x[0-9A-Fa-f]+),' % BLOB, x)
        if not m and re.match(r'^[A-Za-z_]\w*:\s*$', x) and i + 1 < len(wd):
            m = re.match(r'^([A-Za-z_]\w*):\s*\n\s*\.incbin\s+"includes/generated/%s\.bin",\s*(0x[0-9A-Fa-f]+),' % BLOB,
                         x + "\n" + wd[i + 1])
        if m:
            slices[m.group(1)] = int(m.group(2), 16)
    k = label_line(seq, "FormatParamValueStr")
    body = []
    j = k + 1
    while len(body) < 40:
        c = code(seq[j])
        if c and not re.match(r'^[A-Za-z_]\w*:$', c):
            body.append(re.sub(r'\s+', ' ', c))
        j += 1
    # the direct id tests: `cp w, N` followed by `jr(l) z, T`
    direct = {}
    for a, c in zip(body, body[1:]):
        m, n = re.match(r'^cp w, (0x[0-9a-f]+|0:i3)$', a), re.match(r'^jrl? z, (\w+)$', c)
        if m and n:
            direct[0 if m.group(1) == "0:i3" else int(m.group(1), 16)] = n.group(1)
    seqtxt = " | ".join(body)
    for frag in ("ld a, w | extz wa | dec 8, wa | cp wa, 0:i3 | jrl lt, ",
                 "cp wa, 0x11 | jr le, ", "dec 6, wa | cp wa, 0x12 | jrl lt, ", "cp wa, 0x2b | jrl gt, "):
        assert frag in seqtxt, (tree, frag)
    dflt = re.search(r'cp wa, 0x2b \| jrl gt, (\w+)', seqtxt).group(1)
    sw = re.search(r'cp wa, 0x11 \| jr le, (\w+)', seqtxt).group(1)
    ks = label_line(seq, sw)
    sw_code = [re.sub(r'\s+', ' ', code(x)) for x in seq[ks + 1:ks + 8] if code(x)]
    dt = re.match(r'^lda xix, \((\w+):24\)$', sw_code[0]).group(1)
    ct = re.match(r'^ld xix, (\w+)$', sw_code[4]).group(1)
    base = re.match(r'^lda xix, \((\w+):24\)$', sw_code[6]).group(1)
    kc = label_line(wd, ct)
    cases = []
    for x in wd[kc + 1:]:
        m = re.match(r'^\s*\.short\s+(\w+) - (\w+)\s*$', x)
        if not m:
            break
        assert m.group(2) == base, (tree, x)
        cases.append(m.group(1))
    assert len(cases) == 18, (tree, len(cases))

    def what(lab):
        i = label_line(seq, lab)
        cc = [re.sub(r'\s+', ' ', code(x)) for x in seq[i + 1:i + 4] if code(x)]
        if cc[0] in ("pushw 0x0005", "pushw 0x5") and re.match(r'^ld xwa, \w+$', cc[1]):
            return ("T", cc[1].split()[-1])
        if lab == dflt:
            return ("decimal",)
        if cc[:2] == ["add bc, bc", "ld wa, (xde+bc)"] and cc[2] == "cp wa, 0:i3":
            return ("signed",)
        if cc[0].startswith("pushw ") and "@hi16" in cc[0]:
            return ("blank",)
        raise SystemExit("%s: case %s not understood: %s" % (tree, lab, cc))

    dbytes = b[slices[dt]:slices[dt] + 44]
    fmt = {}
    for pid in range(86):
        if pid in direct:
            fmt[pid] = what(direct[pid])
            continue
        i = pid - 8
        if not 0 <= i <= 0x11:
            i = pid - 14
            if not 0x12 <= i <= 0x2B:
                fmt[pid] = ("decimal",)
                continue
        fmt[pid] = what(cases[dbytes[i]])
    return fmt, slices, cases, dt, ct, direct, b, what


def check(tree):
    fmt, slices, cases, dt, ct, direct, b, what = derive(tree)
    got = {}
    for pid, f in fmt.items():
        got.setdefault(f[0] if f[0] != "T" else slices[f[1]], []).append(pid)
    assert got.pop("decimal") == EXPECTED_DECIMAL, (tree, "decimal")
    assert got.pop("signed") == EXPECTED_SIGNED, (tree, "signed")
    assert got.pop("blank") == EXPECTED_BLANK, (tree, "blank")
    assert {o: v for o, v in got.items()} == {o: e[3] for o, e in EXPECTED.items()}, (tree, got)
    units = b[0x15B8:0x15B8 + 172]
    for o, (nm, n, unit, ids, _) in EXPECTED.items():
        for pid in ids:
            assert units[2 * pid:2 * pid + 2].decode("latin-1").strip() == unit, (tree, nm, hex(pid))
    # table label -> case label (each table is passed by exactly one case body, or by a direct target)
    case_of = {}
    for lab in set(cases) | set(direct.values()):
        w = what(lab)
        if w[0] == "T":
            assert slices[w[1]] not in case_of, (tree, w)
            case_of[slices[w[1]]] = lab
    return slices, case_of


def cells(b, off, n):
    return [b[off + 5 * j:off + 5 * j + 5].decode("latin-1") for j in range(n)]


def main():
    rules, per_tree = [], {}
    for tree in ("v10", "v9", "v7"):
        slices, case_of = check(tree)
        inv = {o: l for l, o in slices.items()}
        r = list(STATIC)
        for o, (nm, *_rest) in sorted(EXPECTED.items()):
            r.append((inv[o], "DspValueText_" + nm))
            r.append((case_of[o], "DspParamFmt_" + nm))
            r.append(("DspValueText_%04X" % o, "DspValueText_" + nm))          # C member names
            r.append(("DspValueText_%04X_Pad" % o, "DspValueText_%s_Pad" % nm))
        r = [(a, z) for a, z in r if a != z]
        per_tree[tree] = r
        print("%s: id -> format map derived from the tree's code and bytes == EXPECTED" % tree)
    rules = per_tree["v10"]
    assert all(sorted(per_tree[t]) == sorted(rules) for t in per_tree), "trees disagree on the old names"
    if not rules or all(a == z for a, z in rules):
        print("nothing to rename")
    rules.sort(key=lambda x: -len(x[0]))                       # longer old names first
    sed = ["# rename_dsp_param_formats.sed -- written by scripts/tools/name_dsp_param_value_formats.py",
           "# the DSP parameter value formatter (FormatParamValueStr) and its value-text tables, named by the",
           "# parameter ids that select them (derived and asserted by that script)."]
    sed += ["s/\\b%s\\b/%s/g" % (a, z) for a, z in rules]
    seq10 = open(os.path.join(REPO, "v10/maincpu/sequencer/sequencer_ui.s"), "rb").read().decode("latin-1")
    renamed = any(re.search(r'\b%s\b' % a, seq10) for a, _ in STATIC)
    if not APPLY:
        for a, z in sorted(rules):
            print("  %-40s -> %s" % (a, z))
        return
    if renamed:
        open(SED, "w").write("\n".join(sed) + "\n")
        files = []
        for t in ("v10", "v9", "v7"):
            for dp, _, fs in os.walk(os.path.join(REPO, t, "maincpu")):
                for f in fs:
                    if f.endswith((".s", ".c", ".ld")):
                        p = os.path.join(dp, f)
                        s = open(p, "rb").read().decode("latin-1")
                        if any(re.search(r'\b%s\b' % a, s) for a, _ in rules):
                            files.append(p)
        subprocess.run(["sed", "-i", "-f", SED] + files, check=True)
        print("sed applied to %d files" % len(files))
    for tree in ("v10", "v9", "v7"):
        edit_tree(tree)


def wrap_asm(rows, width=110):
    """`; ` comment rows -> one paragraph re-wrapped at `width` columns."""
    words = " ".join(r[2:] for r in rows).split(" ")
    out, cur = [], ""
    for w in words:
        if cur and len(cur) + 1 + len(w) > width - 2:
            out.append("; " + cur)
            cur = w
        else:
            cur = (cur + " " + w) if cur else w
    out.append("; " + cur)
    return out


def ids_text(ids):
    return " ".join("0x%02X" % i for i in ids)


def edit_tree(tree):
    root = os.path.join(REPO, tree, "maincpu")
    b = open(os.path.join(root, "includes/generated", BLOB + ".bin"), "rb").read()
    # ---- widget_descriptors.s
    p = os.path.join(root, "ui_widgets/widget_descriptors.s")
    L = lines_of(p)
    changed = False
    for o, (nm, n, unit, ids, desc) in sorted(EXPECTED.items()):
        k = label_line(L, "DspValueText_" + nm)
        if any(x.startswith("; DspValueText_%s -- " % nm) for x in L[k - 5:k]):
            continue
        cl = cells(b, o, n)
        first, last = cl[0].strip(), cl[-1].strip()
        extra = ""
        if nm == "ReverbTime":
            last = cl[-3].strip()
            extra = ", then two \"  .  \" cells"
        size = int(re.search(r',\s*(0x[0-9A-Fa-f]+)\s*$', L[k].split(";")[0]).group(1), 16)
        assert size in (5 * n, 5 * n + 1), (tree, nm, size)
        if size == 5 * n + 1:
            assert b[o + 5 * n] == 0xFF, (tree, nm)
        pad = ", then one 0xFF alignment byte" if size == 5 * n + 1 else ""
        hdr = ["; DspValueText_%s -- %d cells x 5 characters (no terminator): \"%s\" .. \"%s\"%s%s%s." % (
                   nm, n, first, last, extra, (" (unit \"%s\")" % unit) if unit else "", pad),
               "; Value text of DSP parameter id%s %s (%s), read by DspParamFmt_%s: cell [value] is copied." % (
                   "s" if len(ids) > 1 else "", ids_text(ids), desc, nm)]
        if nm in ("EqGain", "EqFreq"):
            hdr.append("; The master equalizer screen (EqualizerCngFunc) reads it for its band %s too." % (
                "gains" if nm == "EqGain" else "frequencies"))
        if nm in ("ReverbTime", "EqGain", "EqFreq"):
            hdr.append("; EntertainerGridCheck also loads its address.")
        L[k:k] = wrap_asm(hdr)
        changed = True
    k = next(i for i, x in enumerate(L) if x.startswith("\t.equ DspEffectName_Strings, "))
    if "DspValueText_ReverbTime" in L[k]:
        assert re.search(r'^NakaInst_FxReservedSlot_00:', "\n".join(L), re.M)
        L[k] = re.sub(r'DspValueText_ReverbTime \+ 0x01e1a', 'NakaInst_FxReservedSlot_00', L[k])
        changed = True
    hdrs = {
        "DspParamFmt_NegativeFmt": ["; DspParamFmt_NegativeFmt -- \" -%3d\": DspParamFmt_Signed prints a negative value's",
                                    "; magnitude with it (ids 0x0B RESONANCE, 0x18/0x19 FEEDBACK L/R, 0x39 FEEDBACK)."],
        "DspParamFmt_PositiveFmt": ["; DspParamFmt_PositiveFmt -- \" +%3d\": DspParamFmt_SignedNonNegative prints a",
                                    "; positive value with it."],
        "DspParamFmt_ZeroFmt": ["; DspParamFmt_ZeroFmt -- \"  %3d\" (the value 0, from DspParamFmt_SignedZero), then",
                                "; DspParamFmt_BlankText, the 5 spaces DspParamFmt_Blank copies for ids 0x00 and 0x55."],
        "DspParamFmt_DecimalFmt": ["; DspParamFmt_DecimalFmt -- \"%5d\": DspParamFmt_Decimal prints the raw value with",
                                   "; it, for every parameter id that has no value-text table and is not signed."],
        "DspParamFmt_CaseByParamId": [
            "; DspParamFmt_CaseByParamId -- 44 x u8, read by DspParamFmt_BySwitch: the case of DspParamFmt_CaseTable",
            "; for DSP parameter id 0x08-0x19 (index id - 8) and 0x20-0x39 (index id - 14).  Case 1 is \"%5d\",",
            "; case 12 the signed format, every other case one DspValueText_* table (FormatParamValueStr's header",
            "; lists them)."],
        "DspParamFmt_CaseTable": [
            "; DspParamFmt_CaseTable -- jump table of the compiled `switch` in DspParamFmt_BySwitch",
            "; (`ld xix, DspParamFmt_CaseTable`): 18 u16 case offsets from DspParamFmt_EqFreq, indexed by",
            "; DspParamFmt_CaseByParamId[]."],
    }
    for lab, h in hdrs.items():
        k = label_line(L, lab)
        if h[0] in L[k - 8:k]:
            continue
        j = k
        # replace a generated [naka_s_headers] block directly above, keep the dashed rules
        if L[k - 1].startswith("; ----"):
            top = k - 2
            while not L[top].startswith("; ----"):
                top -= 1
            old = L[top + 1:k - 1]
            assert any("[naka_s_headers]" in x for x in old), (tree, lab, old[:2])
            L[top + 1:k - 1] = h
        else:
            L[j:j] = h
        changed = True
    if changed:
        write(p, L)
        print(tree, "widget_descriptors.s headed")
    # ---- sequencer_ui.s
    p = os.path.join(root, "sequencer/sequencer_ui.s")
    L = lines_of(p)
    changed = False
    k = label_line(L, "FormatParamValueStr")
    if not L[k - 1].startswith("; ---"):
        rows = []
        for o, (nm, n, unit, ids, desc) in sorted(EXPECTED.items(), key=lambda x: x[1][3][0]):
            rows.append(";   %-28s DspValueText_%s" % (ids_text(ids), nm))
        h = ["; -----------------------------------------------------------------------------",
             "; FormatParamValueStr -- the value cell of one DSP effect editor row.  A = row, XBC = cell buffer:",
             "; writes \" \", 5 value characters, \" \" (buf[0] and buf[6]).  The row's DSP parameter id is the byte at",
             "; RAM 0x29AC + row (the id that indexes DspParamName_Table / DspParamUnit_Table), its value the word",
             "; at RAM 0x2978 + 2*row.  The id alone picks the format:",
             ";   0x00, 0x55                   5 spaces (DspParamFmt_Blank)",
             ";   0x40 0x41 0x47, 0x49         tested here: DspParamFmt_LfoSpeed, DspParamFmt_RotorSpeed",
             ";   0x08-0x19, 0x20-0x39         DspParamFmt_BySwitch: DspParamFmt_CaseByParamId[id - 8 / id - 14]",
             ";   any other id                 \"%5d\" (DspParamFmt_Decimal)",
             "; Cell [value] of a DspValueText_* table (Strncpy 5, DspParamFmt_CopyValueText), by id:"]
        h += rows
        h += [";   0x0B 0x18 0x19 0x39          \" -%3d\" / \" +%3d\" / \"  %3d\" (DspParamFmt_Signed)",
              "; Names and units of the ids: technics-docs dsp-name-tables.md (Value formats).  Derived and asserted",
              "; by scripts/tools/name_dsp_param_value_formats.py.",
              "; -----------------------------------------------------------------------------"]
        L[k:k] = h
        changed = True
    for old, new in (("; Equalizer format dispatch", "; the 18-case switch on DspParamFmt_CaseByParamId[]"),
                     ("; Equalizer format default", "; id 0x49 (\"FAST\" of the treble rotor) joins case 15 here")):
        if old in L:
            L[L.index(old)] = new
            changed = True
    if changed:
        write(p, L)
        print(tree, "sequencer_ui.s headed")
    # ---- naka_widget_descriptors.c
    edit_c(tree, root, b)


CRULE = "     * ---------------------------------------------------------------------"


def c_comment_above(L, k):
    """(start, end) line indexes of the /* */ block directly above line k (end exclusive), or None."""
    if not L[k - 1].rstrip().endswith("*/"):
        return None
    j = k - 1
    while "/*" not in L[j]:
        j -= 1
    return j, k


def edit_c(tree, root, b):
    p = os.path.join(root, "ui_widgets", BLOB + ".c")
    L = lines_of(p)
    replaced = 0
    for o, (nm, n, unit, ids, desc) in sorted(EXPECTED.items()):
        k = next(i for i, x in enumerate(L) if re.match(r'^    char DspValueText_%s\[' % nm, x))
        blk = c_comment_above(L, k)
        if blk and any("read by DspParamFmt_%s" % nm in x for x in L[blk[0]:blk[1]]):
            continue
        cl = cells(b, o, n)
        first, last = cl[0].strip(), (cl[-3] if nm == "ReverbTime" else cl[-1]).strip()
        new = ["    /* ---------------------------------------------------------------------"]
        if o == 0:
            new += ["     * [typed] by build_value_text",
                    "     * Parameter-value display texts, blob +0x0..+0x15B8: one table per",
                    "     * DSP parameter scale, cells of exactly 5 characters, space-padded,",
                    "     * no terminator.  FormatParamValueStr (sequencer/sequencer_ui.s) picks",
                    "     * the table from the row's DSP parameter id and copies cell [value]",
                    "     * with Strncpy(dst, table + 5*value, 5) (DspParamFmt_CopyValueText).",
                    "     *"]
        new += ["     * DspValueText_%s -- %d cells: \"%s\" .. \"%s\"%s%s." % (
                    nm, n, first, last, ", then two \"  .  \" cells" if nm == "ReverbTime" else "",
                    (" (unit \"%s\")" % unit) if unit else ""),
                "     * DSP parameter id%s %s (%s), read by DspParamFmt_%s." % (
                    "s" if len(ids) > 1 else "", ids_text(ids), desc, nm)]
        if nm in ("EqGain", "EqFreq"):
            new.append("     * Also the band %s of the master equalizer screen (EqualizerCngFunc)." % (
                "gains" if nm == "EqGain" else "frequencies"))
        new.append("     * --------------------------------------------------------------------- */")
        if blk:
            L[blk[0]:blk[1]] = new
        else:
            L[k:k] = new
        replaced += 1
    cdoc = {
        "DspParamFmt_NegativeFmt": "\" -%3d\": DspParamFmt_Signed prints a negative value's magnitude with it",
        "DspParamFmt_PositiveFmt": "\" +%3d\": DspParamFmt_SignedNonNegative prints a positive value with it",
        "DspParamFmt_ZeroFmt": "\"  %3d\": DspParamFmt_SignedZero prints the value 0 with it",
        "DspParamFmt_DecimalFmt": "\"%5d\": DspParamFmt_Decimal prints the raw value of an id with no value-text table",
        "DspParamFmt_CaseByParamId": "case of DspParamFmt_CaseTable for DSP parameter id 0x08-0x19 ([id - 8]) and"
                                     " 0x20-0x39 ([id - 14]); read by DspParamFmt_BySwitch",
        "DspParamFmt_CaseTable": "jump table of the compiled `switch` in DspParamFmt_BySwitch: 18 u16 case offsets"
                                 " from DspParamFmt_EqFreq, indexed by DspParamFmt_CaseByParamId[]",
    }
    # split the 12-byte "  %3d\0     \0" member into the two strings the code uses
    for i, x in enumerate(L):
        if x == "    char DspParamFmt_ZeroFmt[12];":
            L[i:i + 1] = ["    char DspParamFmt_ZeroFmt[6];",
                          "    /* DspParamFmt_BlankText -- 5 spaces: DspParamFmt_Blank copies them (Strcpy) for ids"
                          " 0x00 and 0x55 */",
                          "    char DspParamFmt_BlankText[6];"]
            break
    for i, x in enumerate(L):
        if x == '    .DspParamFmt_ZeroFmt = "  %3d\\0"':
            assert L[i + 1] == '        "     ",', (tree, L[i + 1])
            L[i:i + 2] = ['    .DspParamFmt_ZeroFmt = "  %3d",', "", '    .DspParamFmt_BlankText = "     ",']
            break
    for nm, d in cdoc.items():
        k = next(i for i, x in enumerate(L) if re.match(r'^    \w+ %s\[' % nm, x))
        blk = c_comment_above(L, k)
        assert blk, (tree, nm)
        if any(d[:30] in x for x in L[blk[0]:blk[1]]):
            continue
        words, rows, cur = ("%s -- %s." % (nm, d)).split(" "), [], ""
        for w in words:
            if cur and len(cur) + len(w) + 1 > 70:
                rows.append(cur)
                cur = w
            else:
                cur = (cur + " " + w) if cur else w
        rows.append(cur)
        L[blk[0]:blk[1]] = (["    /* ---------------------------------------------------------------------"] +
                            ["     * " + r for r in rows] +
                            ["     * --------------------------------------------------------------------- */"])
        replaced += 1
    if replaced:
        write(p, L)
    print(tree, BLOB + ".c: %d generated comments replaced" % replaced)


if __name__ == "__main__":
    main()
