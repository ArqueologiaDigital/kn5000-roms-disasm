#!/usr/bin/env python3
r"""panel_button_actions_retype.py -- the control-panel button -> action lists: decode, label, name, type in C.

QUESTION ANSWERED
-----------------
A front-panel button change reaches the firmware as a 3-byte record {event index, old byte, new byte}
(PanelButton_QueueChange's queue at RAM 0x8E94).  The event index is the panel segment: 0..10 = left panel (CPL)
segments 0..10, 11..21 = right panel (CPR) segments 0..10 (technics-docs control-panel-protocol.md, the lookup at
0xEDA03C), 22..30 other inputs.  PanelButton_DispatchChange (audio/tonegen_fileio_handlers.s) looks the index up in
PanelButton_ActionLists -- or PanelButton_HelpModeActionLists in mode 20, MD_HELP -- and walks that list of 8-byte
actions, ended by an id of 0xFF:

    +0 event_id   +1 event_arg   +2 shift   +3 mask   +4 handler (u32)

For each action it takes old & mask and new & mask, shifts both by `shift & 0x0F` (left when bit 4 is set,
else right), and when the new value is not 0 calls `handler` with a frame {event_id, event_arg, old, new} followed
by the raw {0xAA, index, old byte, new byte}.  Most handlers filter (mode, a panel parameter) and post one or both
4-byte events with PanelEvent_Post (the queue at RAM 0xC039, 16 deep).

The masks fall exactly on the buttons the MAME driver names per segment and bit
(mame_driver/src/mame/matsushita/kn5000.cpp, PORT_START("CPL_SEGn") / ("CPR_SEGn")): VARIATION 1-4 is one action
with mask 0x0F, the eight sound-group buttons one with 0xFF, UP n / DOWN n / LEFT n / RIGHT n one each.  That
agreement is the evidence for the reading, and it names the handlers: a handler used by one button group is named
after it (PanelButton_Variation), a generic one by what it does (PanelAction_PostUnlessDemo), the ones behind
events 22..30, which have no MAME button, by event index (PanelAction_Event26).

This script, for v10/v9/v7 (each tree's own handler addresses, read from its own blob):
  --labels   places a label at each handler (39, two of which already had one), renames the handler-local
             FileIO_BytecodeData_Code_{Skip,Join,Epilogue,Loop}N labels after their handler
             (scripts/renaming/rename_panel_button_locals_<tree>.sed, written here, then run), and writes headers;
  (default)  types +0x2E72..+0x3552 of naka_extension_device.c: 53 lists of panel_button_action_t with
             NAKA_ADDR(handler) and the two 32-entry pointer tables as SELF(list); adds the handler symbols to
             each tree's link script at that tree's address.
Run scripts/renaming/rename_panel_button_actions.sed over the trees first (the global names).

RUN (repository root, built tree, census maps built: scripts/analysis/dispatch_table_census/build_maps.py)
    sed -i -f scripts/renaming/rename_panel_button_actions.sed <files>
    python3 scripts/converters/panel_button_actions_retype.py --labels [--apply]
    python3 scripts/converters/panel_button_actions_retype.py [--apply]
    python3 scripts/converters/panel_button_actions_retype.py --asm-headers [--apply]
    python3 scripts/converters/panel_button_actions_retype.py --report     # the markdown table on the website
    python3 scripts/build/regenerate_v7_c_divergence.py --apply ; make all ; make gate-all
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis", "dispatch_table_census"))
import nakarest_c_model as M      # noqa: E402

TREES = ("v10", "v9", "v7")
BASE = 0xED67CC
LISTS, TABLE1, TABLE2, END = 0x2E72, 0x3452, 0x34D2, 0x3552

# handler names, keyed by the v10 (= v9) address; v7's addresses are matched by list position
NAMES = {
    0xFC5760: "Encoder_AlignByte",            # the list terminator's handler: a bare ret (existing name)
    0xFC5874: "PanelEvent_Post",              # renamed from FileIO_BytecodeData by the .sed
    0xFC58A5: "PanelAction_PostUnlessDemo",
    0xFC58C2: "PanelAction_PostUnlessDemoOrParamC0",
    0xFC58EC: "PanelButton_PanelMemorySet",
    0xFC591F: "PanelButton_AcousticIllusion",
    0xFC5930: "PanelButton_ModeKey",
    0xFC5A58: "PanelButton_SequencerPlay",
    0xFC5AE0: "PanelButton_PairDown",
    0xFC5B29: "PanelButton_PairUp",
    0xFC5B72: "PanelButton_StartStop",
    0xFC5B91: "PanelButton_SynchroBreak",
    0xFC5BB0: "PanelButton_SoundGroup",
    0xFC5CD2: "PanelButton_RhythmGroup",
    0xFC5D78: "PanelButton_PanelMemoryNumber",
    0xFC5DF2: "PanelButton_PanelMemoryNextBank",
    0xFC5E49: "PanelButton_SplitPoint",
    0xFC5E61: "PanelButton_Octave",
    0xFC5E9C: "PanelButton_AutoPlayChord",
    0xFC5EF2: "PanelButton_PartSelect",
    0xFC5F54: "PanelButton_Conductor",
    0xFC5F81: "PanelButton_DigitalEffect",
    0xFC5FAB: "PanelButton_DspEffect",
    0xFC602E: "PanelButton_DigitalReverb",
    0xFC604D: "PanelButton_Sustain",
    0xFC6085: "PanelButton_MusicStyleArranger",
    0xFC60B4: "PanelButton_MspNumber",
    0xFC6152: "PanelButton_Variation",
    0xFC6215: "PanelAction_Event28Bit0",
    0xFC6233: "PanelAction_Event28Bit1",
    0xFC6251: "PanelAction_Event29Bit0",
    0xFC626F: "PanelAction_Event29Bit1",
    0xFC628D: "PanelAction_Event29Bit2",
    0xFC62AB: "PanelAction_Event29Bit3",
    0xFC62C9: "PanelAction_Event22",
    0xFC62F7: "PanelAction_Event26",
    0xFC6328: "PanelAction_Event23",
    0xFC6332: "PanelAction_Event27",
    0xFC68F6: "PanelButton_HelpMode",
}
HEADERS = {
    "PanelAction_PostUnlessDemo": "unless MD_DEMO: FileIO_BytecodeData_Code_Helper2 on the frame, then post both events",
    "PanelAction_PostUnlessDemoOrParamC0": "unless MD_DEMO or panel parameter 0xC0 (tag 0x91 +3 bit 2) is 1: post both",
    "PanelAction_Event28Bit0": "event 28 bit 0: per panel parameter 0x2886 (tag 0x99 payload byte 4)",
    "PanelAction_Event28Bit1": "event 28 bit 1: per panel parameter 0x2888 (tag 0x99 payload byte 5)",
    "PanelAction_Event29Bit0": "event 29 bit 0: per panel parameter 0x288A (tag 0x99 payload byte 6)",
    "PanelAction_Event29Bit1": "event 29 bit 1: per panel parameter 0x288C (tag 0x99 payload byte 7)",
    "PanelAction_Event29Bit2": "event 29 bit 2: per panel parameter 0x288E (tag 0x99 payload byte 8)",
    "PanelAction_Event29Bit3": "event 29 bit 3: per panel parameter 0x2890 (tag 0x99 payload byte 9)",
    "PanelAction_Event22": "event 22 (left-panel header 0xD1): the byte as two 7-bit values ((b & 1) << 6, b >> 1)",
    "PanelAction_Event26": "event 26: depends on panel parameter 0x2880 (tag 0x99 payload byte 2) being 182 or 183",
    "PanelAction_Event23": "event 23 (left-panel header 0xD2): post unless MD_DEMO",
    "PanelAction_Event27": "event 27: post when panel parameter 0x104 (tag 0x93 payload byte 6 bit 7) is set",
    "PanelButton_HelpMode": "every button but the LCD ones and HELP, in MD_HELP (PanelButton_HelpModeActionLists)",
}
LOCAL = re.compile(r'^FileIO_BytecodeData_Code_(Skip|Join|Epilogue|Loop)(\d*):')
KEEP_OWNER = re.compile(r'^FileIO_BytecodeData_Code_(Helper|Entry)\d*:')


def le(b, o, n=4):
    return int.from_bytes(b[o:o + n], "little")


def mame_buttons():
    src = open(os.path.join(ROOT, "mame_driver", "src", "mame", "matsushita", "kn5000.cpp")).read()
    names = {}
    for m in re.finditer(r'PORT_START\("(CP[LR])_SEG(\d+)"\)(.*?)(?=PORT_START|\Z)', src, re.S):
        for bm in re.finditer(r'PORT_BIT\(\s*(0x[0-9a-fA-F]+)[^)]*\)\s*(?:PORT_NAME\("([^"]+)"\))?', m.group(3)):
            if bm.group(2):
                names[(m.group(1), int(m.group(2)), int(bm.group(1), 16))] = bm.group(2)
    return names


def segment(i):
    return ("CPL", i) if i <= 10 else ("CPR", i - 11) if i <= 21 else None


def decode(b):
    """-> tables {1: [list start]*32, 2: [...]}, lists {start: [(id, arg, shift, mask, handler)]} (incl. end)."""
    tables = {t: [le(b, off + 4 * i) - BASE for i in range(32)] for t, off in ((1, TABLE1), (2, TABLE2))}
    lists = {}
    for s in sorted({x for v in tables.values() for x in v}):
        o, ents = s, []
        while True:
            e = b[o:o + 8]
            ents.append((e[0], e[1], e[2], e[3], le(e, 4)))
            o += 8
            if e[0] == 0xFF:
                break
        lists[s] = ents
    starts = sorted(lists)
    assert starts[0] == LISTS and all(starts[k] + 8 * len(lists[starts[k]]) == (starts[k + 1] if k + 1 < len(starts)
                                                                               else TABLE1) for k in range(len(starts)))
    return tables, lists


def tree_names(tree):
    """handler address in this tree -> name (v7 by list position against v10)."""
    ref_t, ref_l = decode(blob("v10"))
    t, l = decode(blob(tree))
    out = {}
    for tb in (1, 2):
        for i in range(32):
            a, r = l[t[tb][i]], ref_l[ref_t[tb][i]]
            assert len(a) == len(r), (tree, tb, i)
            for x, y in zip(a, r):
                assert x[:4] == y[:4], (tree, tb, i, x, y)
                nm = NAMES[y[4]]
                assert out.setdefault(x[4], nm) == nm, (tree, hex(x[4]), nm)
    return out


def blob(tree):
    return open(os.path.join(ROOT, tree, "maincpu", "includes", "generated", "naka_extension_device.bin"), "rb").read()


def list_names(tables):
    """list start -> member name, from its first user: LeftSegN / RightSegN / EventN, Help* in table 2 only."""
    out = {}
    for tb in (1, 2):
        for i, s in enumerate(tables[tb]):
            if s in out:
                continue
            seg = segment(i)
            stem = ("LeftSeg%d" % seg[1] if seg and seg[0] == "CPL" else "RightSeg%d" % seg[1] if seg
                    else "Event%d" % i)
            out[s] = "PanelActions_%s%s" % ("Help" if tb == 2 else "", stem)
    assert len(set(out.values())) == len(out)
    return out


# ---------------------------------------------------------------------------------------------- .s labels
def apply_labels(tree, apply):
    import census
    m = census.load(tree)
    names = tree_names(tree)
    root = os.path.join(ROOT, tree, "maincpu")
    edits = {}
    for addr, nm in names.items():
        r = census.find(m, addr)
        assert r and r[0] == addr, (tree, hex(addr))
        if r[7]:
            continue                       # Encoder_AlignByte, PanelEvent_Post (FileIO_BytecodeData before the sed)
        edits.setdefault(r[2], []).append((r[3], nm))
    rename = {}
    for rel, ops in edits.items():
        path = os.path.join(root, rel)
        L = open(path, "rb").read().decode("latin-1").split("\n")
        for li, nm in sorted(ops, reverse=True):
            hdr = HEADERS.get(nm)
            L[li:li] = (["; " + hdr] if hdr else []) + [nm + ":"]
        # locals after a handler label take its name
        new_names = set(names.values()) | {"PanelEvent_Post", "FileIO_BytecodeData"}
        owner, count = None, {}
        for line in L:
            lab = re.match(r'^([A-Za-z_][\w]*):', line)
            if not lab:
                continue
            if lab.group(1) in new_names:
                owner = "PanelEvent_Post" if lab.group(1) == "FileIO_BytecodeData" else lab.group(1)
                count = {}
            elif KEEP_OWNER.match(line):
                owner = None
            else:
                mm = LOCAL.match(line)
                if mm and owner:
                    kind = mm.group(1)
                    count[kind] = count.get(kind, 0) + 1
                    rename[lab.group(1)] = "%s_%s%s" % (owner, kind, "" if count[kind] == 1 else count[kind])
        if apply:
            data = "\n".join(L).encode("latin-1")
            open(path + ".tmp", "wb").write(data)
            os.replace(path + ".tmp", path)
    sed = os.path.join(ROOT, "scripts", "renaming", "rename_panel_button_locals_%s.sed" % tree)
    lines = ["# %s: FileIO_BytecodeData_Code_{Skip,Join,Epilogue,Loop}N labels renamed after the panel action handler"
             % tree, "# they sit in (scripts/converters/panel_button_actions_retype.py --labels)."]
    lines += ["s/\\b%s\\b/%s/g" % (a, b) for a, b in sorted(rename.items())]
    print("%s: %d handler labels placed, %d local labels to rename" % (tree, sum(len(v) for v in edits.values()),
                                                                       len(rename)))
    if apply:
        open(sed, "w").write("\n".join(lines) + "\n")
        files = subprocess.run(["grep", "-rlE", r"\bFileIO_BytecodeData_Code_", root, "--include=*.s",
                                "--include=*.c", "--include=*.ld"], capture_output=True, text=True).stdout.split()
        subprocess.run(["sed", "-i", "-f", sed] + files, check=True)


# ---------------------------------------------------------------------------------------------- C
TYPEDEF = r'''/* One control-panel button action (8 bytes; scripts/converters/panel_button_actions_retype.py).  For a change of
 * panel segment byte old -> new, PanelButton_DispatchChange takes (old & mask) and (new & mask), shifts both by
 * shift & 0x0F (left when bit 4 of shift is set, else right) and, when the new value is not 0, calls handler with
 * the frame {event_id, event_arg, old, new} + {0xAA, segment index, old byte, new byte}.  A list ends with
 * event_id 0xFF. */
typedef struct __attribute__((packed)) {
    uint8_t  event_id;
    uint8_t  event_arg;
    uint8_t  shift;
    uint8_t  mask;
    uint32_t handler;
} panel_button_action_t;
'''


def retype_c(tree, apply):
    path = os.path.join(ROOT, tree, "maincpu", "ui_widgets", "naka_extension_device.c")
    ld = os.path.join(ROOT, tree, "maincpu", "ui_widgets", "naka_extension_device_link.ld")
    if "PanelButton_ActionLists" in open(path, encoding="latin-1").read():
        return "already typed"
    M.TYPE_SIZES.update({"panel_tlv_layout_t": 10, "panel_reset_mask_t": 5, "snd_param_base_entry_t": 6,
                         "snd_param_mask_entry_t": 6, "panel_button_action_t": 8})
    b = blob(tree)
    tables, lists = decode(b)
    names = tree_names(tree)
    lname = list_names(tables)
    buttons = mame_buttons()
    users = {}
    for tb in (1, 2):
        for i, s in enumerate(tables[tb]):
            users.setdefault(s, []).append((tb, i))
    cb = M.CBlob(path)
    sym = {mb.name: cb.entries[cb.by_name[mb.name]].expr for mb in cb.members
           if LISTS <= mb.offset < END and M.SYMBOLIC_RE.search(cb.entries[cb.by_name[mb.name]].expr)}
    new = []
    first = True
    for s in sorted(lists):
        rows = []
        tb0, i0 = users[s][0]
        seg = segment(i0)
        for (eid, arg, sh, mask, h) in lists[s]:
            if eid == 0xFF:
                rows.append("        { 0xFF, 0x%02X, 0x%02X, 0x%02X, NAKA_ADDR(%s) },  /* end */"
                            % (arg, sh, mask, names[h]))
                continue
            btn = [buttons.get((seg[0], seg[1], 1 << k)) for k in range(8) if mask >> k & 1] if seg else []
            what = ", ".join(x for x in btn if x) or ("event %d" % i0)
            rows.append("        { 0x%02X, 0x%02X, 0x%02X, 0x%02X, NAKA_ADDR(%s) },  /* %s */"
                        % (eid, arg, sh, mask, names[h], what))
        who = ", ".join(("%sindex %d" % ("help " if tb == 2 else "", i)) for tb, i in users[s])
        pre = []
        if first:
            pre += M.comment_block(
                "The 53 control-panel action lists (panel_button_action_t, defined above), in ROM order.\n"
                "Each is named after its first user: PanelActions_LeftSegN / RightSegN = panel segment N (event\n"
                "index N / N + 11), EventN = event index N, Help* = used only by PanelButton_HelpModeActionLists.\n"
                "Button names per mask bit are the MAME driver's (kn5000.cpp, PORT_START(\"CPL_SEGn\"/\"CPR_SEGn\")).")
            first = False
        pre.append("    /* %s: %s */" % (lname[s], who))
        new.append(M.NewMember("panel_button_action_t", lname[s], "[%d]" % len(lists[s]), 8 * len(lists[s]),
                               "{\n" + "\n".join(rows) + "\n    }", pre))
    for tb, nm, note in ((1, "PanelButton_ActionLists", "read by PanelButton_DispatchChange"),
                         (2, "PanelButton_HelpModeActionLists", "used instead in mode 20, MD_HELP")):
        rows = []
        for i, s in enumerate(tables[tb]):
            seg = segment(i)
            rows.append("        SELF(%s),  /* %2d %s */" % (lname[s], i, "%s segment %d" % seg if seg else "event"))
        new.append(M.NewMember("uint32_t", nm, "[32]", 128, "{\n" + "\n".join(rows) + "\n    }",
                               ["    /* %s: one action list per event index (0..31), %s */" % (nm, note)]))
    # the generator's last pointer array runs past the tables into SoundParam_EncoderMappingData: carry its
    # words at >= END over verbatim as their own member, and end the retyped region with it
    last = cb.members[cb.index_at(END - 1)]
    end = last.offset + last.size
    tail = []
    if end > END:
        elems = [x.strip() for x in M.split_top_level(cb.entries[cb.by_name[last.name]].expr.strip()[1:-1])
                 if x.strip()]
        assert last.ctype == "uint32_t" and len(elems) == last.size // 4, last.name
        tail = elems[(END - last.offset) // 4:]
        new.append(M.NewMember("uint32_t", "SoundParam_EncoderMappingData_Head", "[%d]" % len(tail), 4 * len(tail),
                               "{\n" + "".join("        %s,\n" % x for x in tail) + "    }",
                               ["    /* the first %d words of SoundParam_EncoderMappingData"
                                " (ui_widgets/extension_device_screens.s), as the generator had them */" % len(tail)]))
    handler_names = set(names.values())
    for n, e in sym.items():                   # every NAKA_ADDR in the region is a handler or one of the tail's
        for x in re.findall(r'NAKA_ADDR\((\w+)\)', e):
            assert x in handler_names or "NAKA_ADDR(%s)" % x in tail, (n, x)
    keeps = list(sym)
    for nm in new:
        nm._keeps.update(keeps)
    cb.retype(LISTS, end, new, b)
    k = next(i for i, l in enumerate(cb.lines) if l.startswith("/* -- Panel TLV schema"))
    lines = TYPEDEF.rstrip("\n").split("\n") + [""]
    cb.lines[k:k] = lines
    for att in ("s0", "s1", "i0", "i1"):
        setattr(cb, att, getattr(cb, att) + len(lines))
    # every handler symbol: an extern in the C, a line in this tree's link script
    text = cb.render()
    have_ext = set(re.findall(r'^extern const char (\w+);', text, re.M))
    ld_text = open(ld, encoding="latin-1").read()
    have_ld = set(re.findall(r'^(\w+) = 0x', ld_text, re.M))
    add_ext = sorted({n for n in names.values()} - have_ext)
    add_ld = sorted((n, a) for a, n in names.items() if n not in have_ld)
    k = text.index("\nextern const char ") + 1
    out = text[:k] + "".join("extern const char %s;\n" % n for n in add_ext) + text[k:]
    ld_out = ld_text.rstrip("\n") + "\n" + "".join("%s = 0x%08X;\n" % (n, a) for n, a in add_ld)
    if apply:
        data = out.encode("latin-1")
        open(path + ".tmp", "wb").write(data)
        os.replace(path + ".tmp", path)
        data = ld_out.encode("latin-1")
        open(ld + ".tmp", "wb").write(data)
        os.replace(ld + ".tmp", ld)
    return "%d lists + 2 tables typed; %d externs, %d link-script symbols added" % (len(lists), len(add_ext),
                                                                                  len(add_ld))


INC = '.incbin "includes/generated/naka_extension_device.bin", 0x%s, 0x%s'
SLICES = (
    ("PanelButton_ActionListPool", INC % ("2e72", "5e0"), [
        "; PanelButton_ActionListPool -- the 53 control-panel action lists: 8-byte actions {event_id, event_arg,",
        "; shift, mask, u32 handler}, each list ended by event_id 0xFF.  PanelButton_ActionLists and",
        "; PanelButton_HelpModeActionLists point into it, one list per panel event index; PanelButton_DispatchChange",
        "; (audio/tonegen_fileio_handlers.s) walks them.  Typed in ui_widgets/naka_extension_device.c",
        "; (panel_button_action_t, PanelActions_*), each action commented with the buttons its mask selects",
        "; (MAME kn5000.cpp names); scripts/converters/panel_button_actions_retype.py."]),
    ("PanelButton_ActionLists", INC % ("3452", "80"), [
        "; PanelButton_ActionLists -- 32 list pointers, one per panel event index: 0..10 = left-panel segments",
        "; 0..10, 11..21 = right-panel segments 0..10, 22..30 = other inputs, 31 = an empty list.  Read by",
        "; PanelButton_DispatchChange (`ld xwa, PanelButton_ActionLists`)."]),
    ("PanelButton_HelpModeActionLists", INC % ("34D2", "80"), [
        "; PanelButton_HelpModeActionLists -- the same, used instead in mode 20 (MD_HELP): every button but the LCD",
        "; ones and HELP goes to PanelButton_HelpMode."]),
)
ROUTINE_HEADERS = {
    ("audio/tonegen_fileio_handlers.s", "PanelButton_DispatchChange"): [
        "; One queued panel change {event index, old byte, new byte} (RAM 0x8E78, the index also at 0x8E90): walk",
        "; PanelButton_ActionLists[index] (PanelButton_HelpModeActionLists in mode 20, MD_HELP).  The frame at",
        "; (0x8E7C) gets {0xAA, index, old, new} at +4; per action, +0..+3 = {event_id, event_arg, old & mask,",
        "; new & mask} shifted by the action's shift, and the handler is called when the new value is not 0."],
    ("audio/audio_control_engine.s", "PanelEvent_Post"): [
        "; xwa -> a 4-byte panel event; an id of 0xFF is no event.  Append it to the event queue at (0xC039),",
        "; count at RAM 0x8E8E, 16 deep; when full, mark the event 0xFF instead."],
}


def apply_asm_headers(tree, apply):
    root = os.path.join(ROOT, tree, "maincpu")
    notes = []
    path = os.path.join(root, "ui_widgets", "extension_device_screens.s")
    L = open(path, "rb").read().decode("latin-1").split("\n")
    for lab, inc, hdr in SLICES:
        if any(l.startswith(lab + ":\t") for l in L) and hdr[0] in L:
            continue
        k = next(i for i, l in enumerate(L) if ("\t" + inc) in l and (l.startswith("\t") or l.startswith(lab + ":")))
        j = k
        while L[j - 1].startswith("; [nakarest]"):
            j -= 1
        L[j:k + 1] = hdr + ["%s:\t%s" % (lab, inc)]
        notes.append(lab)
    files = {path: L}
    for (rel, lab), hdr in ROUTINE_HEADERS.items():
        pth = os.path.join(root, rel)
        L = files.setdefault(pth, open(pth, "rb").read().decode("latin-1").split("\n"))
        k = L.index(lab + ":")
        if L[k - len(hdr):k] != hdr:
            L[k:k] = hdr
            notes.append(lab)
    print(tree, ", ".join(notes) or "nothing to do")
    if apply:
        for pth, L in files.items():
            data = "\n".join(L).encode("latin-1")
            if data != open(pth, "rb").read():
                open(pth + ".tmp", "wb").write(data)
                os.replace(pth + ".tmp", pth)


def report():
    """Markdown: per event index, the actions -- buttons, event id/arg, handler (v10 names; read-only)."""
    tables, lists = decode(blob("v10"))
    buttons = mame_buttons()
    print("| index | segment | buttons (mask) | event id, arg | handler |")
    print("|---:|:---|:---|:---|:---|")
    for i, s in enumerate(tables[1]):
        seg = segment(i)
        for (eid, arg, sh, mask, h) in lists[s]:
            if eid == 0xFF:
                continue
            btn = [buttons.get((seg[0], seg[1], 1 << k)) for k in range(8) if mask >> k & 1] if seg else []
            print("| %d | %s | %s (`0x%02X`) | `0x%02X`, `0x%02X` | `%s` |" % (
                i, "%s %d" % seg if seg else "--", ", ".join(x for x in btn if x) or "--", mask, eid, arg, NAMES[h]))


def main():
    if "--report" in sys.argv:
        report()
        return
    apply = "--apply" in sys.argv
    labels = "--labels" in sys.argv
    flags = list(sys.argv)
    sys.argv = sys.argv[:1]                   # census parses sys.argv when imported
    for tree in TREES:
        if "--asm-headers" in flags:
            apply_asm_headers(tree, apply)
            continue
        if labels:
            apply_labels(tree, apply)
        else:
            print(tree, retype_c(tree, apply))


if __name__ == "__main__":
    main()
