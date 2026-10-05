#!/usr/bin/env python3
"""Frame the sound editor's title-function method tables and DirmdEmulator's event cases (one maincpu tree).

QUESTION IT ANSWERS / WHAT IT DOES
  Each sound-editor title SeXxxTitleFunc copies a 16-byte method table to the stack and calls DirmdEmulator
  (audio/presentation_sound_nav.s), which looks the event up in a 16-entry offset table (EVT_NONE .. +15)
  and calls one of the methods:
      method 0 (+0)  EVT_ALL_PAINT and EVT_PARA_DRAW  -> <Title>_OnDraw      (`jp` to the page painter)
      method 1 (+4)  EVT_HIDE                         -> <Title>_OnHide      (`jp` to SetCurrentStep(0) + ResetSubIndex)
      method 2 (+8)  EVT_SW_IN, switch <= 255         -> <Title>_OnSwitchIn  (row = switch & 31, bank = bit 7)
      method 3 (+18) never called by DirmdEmulator    -> <Title>_Nop         (`jp` to a bare `ret`)
  The tables spelled these as <stub>+0x4 / +0x8 / +0x12, or held them inside the gui_display_struct_data.bin
  .incbin (SeMenu, SeEasy, half of SeTonTon1).  This script:
    1. places the three missing method labels in every stub (32 titles; SeWrtSnd's stub is the
       old Scoop_SoundEditorData);
    2. respells every method table as four `.long <Title>_On...` lines (dropping the .incbin slices);
    3. respells DirmdEmulator's `.ascii ":;<>"` (v10/v9) as the four pushes it is, labels the three other
       event cases, and replaces the DirmdEmulator_Data .incbin slice with 16 `.short Case - Base` lines.
  Renames (stub -> _OnDraw, table -> _Methods / _SwitchHandlers, dispatcher -> _DispatchSwitch) are NOT done
  here; they are sed files in scripts/renaming/rename_semenu_titlefunc_*.sed, run after this script.
  Byte-identity is the check: every new label is used by a table whose bytes must not change.

RUN (from the repository root, once per tree, before the sed renames)
  python3 scripts/tools/frame_semenu_title_methods.py v10
"""
import glob
import os
import re
import sys

tree = sys.argv[1]
src = {}
for f in glob.glob("%s/maincpu/**/*.s" % tree, recursive=True):
    src[f] = open(f, "rb").read().decode("latin-1").split("\n")


def find_def(name):
    hits = [(f, i) for f, L in src.items() for i, l in enumerate(L) if re.match(r"^%s:" % re.escape(name), l)]
    assert len(hits) == 1, (name, hits)
    return hits[0]


def code(f, i):
    return re.sub(r"\s+", " ", src[f][i].split(";")[0]).strip()


def lines_after(f, i, n):
    """Indices of the first n lines after i that hold an instruction (comment-only and blank lines skipped)."""
    out, k = [], i + 1
    while len(out) < n:
        if code(f, k):
            out.append(k)
        k += 1
    return out


inserts = {}      # (file, line index) -> [label lines to insert before it]
replace = {}      # (file, first line, last line) -> new lines


def put_label(f, i, label):
    inserts.setdefault((f, i), []).append(label + ":")


# ---- 1. method labels in every stub
titles = sorted(re.match(r"^(Se\w*TitleFunc):", l).group(1) for L in src.values() for l in L
                if re.match(r"^Se\w*TitleFunc:", l))
assert len(titles) == 32, len(titles)
methods = {}
for t in titles:
    f, i = find_def(t)
    tab = [m.group(1) for k in range(i + 1, i + 6) for m in [re.match(r"ld xiy, (\w+)$", code(f, k))] if m]
    assert len(tab) == 1, t
    if t == "SeWrtSndTitleFunc":
        stub = "Scoop_SoundEditorData"
        g, j = find_def(stub)
        n = lines_after(g, j, 4)
        assert code(g, n[2]) == "ld wa, (xsp+4)" and code(g, n[3]) == "ld bc, (xsp+6)", stub
        s, k = find_def("Scoop_SoundEditorData_Skip")
        m = lines_after(g, k, 4)
        assert s == g and [code(g, d) for d in m[:3]] == ["ld xwa, 0:i3", "ld xbc, EVT_SW_IN", "jp DeleteEvent"]
        nop = (g, m[3])
        old = ["Scoop_SoundEditorData", "Scoop_SoundEditorData+0x4", "Scoop_SoundEditorData+0x8",
               "Scoop_SoundEditorData_Skip+0xB"]
    else:
        stub = t + "_DisplayData"
        g, j = find_def(stub)
        n = lines_after(g, j, 6)
        assert code(g, n[2]) == "ld wa, (xsp+4)" and code(g, n[3]) == "ld bc, (xsp+6)", stub
        assert all(code(g, n[d]).startswith("jp ") for d in (0, 1, 4, 5)), stub
        nop = (g, n[5])
        old = [stub, stub + "+0x4", stub + "+0x8", stub + "+0x12"]
    put_label(g, n[1], t + "_OnHide")
    put_label(g, n[2], t + "_OnSwitchIn")
    put_label(*nop, t + "_Nop")
    methods[tab[0]] = (t, stub, old)

# ---- 2. method tables
P = "%s/maincpu/kn5000_%s_program.s" % (tree, tree)
L = src[P]
for tab, (t, stub, old) in methods.items():
    f, i = find_def(tab)
    assert f == P
    k = i + 1
    body = []
    while len(body) < 4:
        c = code(P, k)
        m = re.match(r'\.incbin "includes/generated/gui_display_struct_data\.bin", (0x[0-9A-Fa-f]+), (0x[0-9A-Fa-f]+)$', c)
        if m:
            body += ["<incbin>"] * (int(m.group(2), 16) // 4)
        elif c.startswith(".long "):
            body.append(c[6:])
        else:
            assert c == "", (tab, c)
        k += 1
    real = [x for x in body if x != "<incbin>"]
    assert real == old[len(old) - len(real):], (tab, body, old)
    new = ["\t.long %s_%s" % (t, m) for m in ("OnDraw", "OnHide", "OnSwitchIn", "Nop")]
    # the stub's first label is renamed later by sed; spell it with its current name so this step builds alone
    new[0] = "\t.long %s" % stub
    replace[(P, i + 1, k - 1)] = new

# ---- 3. DirmdEmulator
f, i = find_def("DirmdEmulator_Dispatch")
if src[f][i] == 'DirmdEmulator_Dispatch:\t.ascii ":;<>"':
    replace[(f, i, i)] = ["DirmdEmulator_Dispatch:\t; EVT_HIDE: method 1",
                          "\tpush\txde", "\tpush\txhl", "\tpush\txix", "\tpush\txiz"]
else:
    assert src[f][i] == "DirmdEmulator_Dispatch:" and code(f, i + 1) == "push xde", src[f][i]
    replace[(f, i, i)] = ["DirmdEmulator_Dispatch:\t; EVT_HIDE: method 1"]
k = i + 1
cases = []
while not src[f][k].startswith("DirmdEmu_DefaultCase") and not src[f][k].startswith("; DirmdEmulator default"):
    c = code(f, k)
    if re.match(r"ld \(\d+:16\), 0$", c) and not cases:
        cases.append(("DirmdEmu_OnAllPaint", k, "EVT_ALL_PAINT: clear the redraw mode, reset the drawing state, method 0"))
    elif re.match(r"ld \(\d+:16\), 16$", c) and len(cases) == 1:
        cases.append(("DirmdEmu_OnParaDraw", k, "EVT_PARA_DRAW: method 0 with the redraw mode at 16"))
    elif c == "cp xde, 255" and len(cases) == 2:
        cases.append(("DirmdEmu_OnSwitchIn", k, "EVT_SW_IN: switches 0..255 only; method 2 (switch & 31, bit 7)"))
    k += 1
assert [c[0] for c in cases] == ["DirmdEmu_OnAllPaint", "DirmdEmu_OnParaDraw", "DirmdEmu_OnSwitchIn"], cases
for name, k, why in cases:
    inserts.setdefault((f, k), []).append("%s:\t; %s" % (name, why))

g, j = find_def("DirmdEmulator_Data")
assert re.match(r'\s*\.incbin "includes/generated/naka_disk_warning\.bin", 0xF12, 0x20$', src[g][j + 1]), src[g][j + 1]
a = j
while src[g][a - 1].startswith("; [nakarest]") and "0xf12" not in src[g][a].lower():
    a -= 1
assert "+0xf12" in src[g][a].lower(), src[g][a]
EV = ["EVT_NONE", "EVT_SHOW", "EVT_HIDE", "EVT_NONE+3", "EVT_NONE+4", "EVT_NONE+5", "EVT_ACTION", "EVT_SW_IN",
      "EVT_SW_ON", "EVT_SW_OFF", "EVT_ALL_PAINT", "EVT_PAINT", "EVT_REPAINT", "EVT_DRAW", "EVT_SELE_DRAW",
      "EVT_PARA_DRAW"]
CASE = {2: "DirmdEmulator_Dispatch", 7: "DirmdEmu_OnSwitchIn", 10: "DirmdEmu_OnAllPaint", 15: "DirmdEmu_OnParaDraw"}
block = ["; DirmdEmulator's case table: one 16-bit offset from DirmdEmulator_Dispatch per event EVT_NONE .. EVT_NONE+15",
         "; (DirmdEmulator subtracts EVT_NONE, rejects anything outside 0..15, then `jp t, (xix+bc)`).  Four events",
         "; have cases; the rest go straight to DirmdEmu_DefaultCase.  Was a 32-byte slice of naka_disk_warning.bin.",
         "DirmdEmulator_Data:"]
for n, ev in enumerate(EV):
    block.append("\t.short %s - DirmdEmulator_Dispatch\t; %s" % (CASE.get(n, "DirmdEmu_DefaultCase"), ev))
replace[(g, a, j + 1)] = block

# ---- apply, bottom-up per file
for fn in src:
    L = src[fn]
    edits = sorted([(a, b, new) for (ff, a, b), new in replace.items() if ff == fn] +
                   [(i, i - 1, labs) for (ff, i), labs in inserts.items() if ff == fn], key=lambda e: -e[0])
    if not edits:
        continue
    for a, b, new in edits:
        L[a:b + 1] = new
    data = "\n".join(L).encode("latin-1")
    open(fn + ".tmp", "wb").write(data)
    os.replace(fn + ".tmp", fn)
print("%s: %d method stubs labelled, %d method tables respelled, DirmdEmulator framed" % (tree, len(titles), len(methods)))
