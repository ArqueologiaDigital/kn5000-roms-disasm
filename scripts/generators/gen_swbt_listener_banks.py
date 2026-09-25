#!/usr/bin/env python3
r"""SwbtWr EVENT-LISTENER BANKS (maincpu 0xEE7786-0xEE8C7D): prove, emit, apply.

QUESTION ANSWERED
-----------------
What are the 5,368 bytes after the DSP record-list table that the tree called
Naka_DisplayMode_Table+0x10 / UIState_ConfigA_000..127 / UIState_DefaultConfig_A /
Naka_RenderMode_A_Table / Naka_RenderMode_B_Table / UIState_HandlerTable_* /
UIState_ConfigB_* / UIState_SeqInit_Table / UIState_EventHandler_Table /
UIState_DefaultConfig_B / Naka_EventHandler_Table / UIState_ConfigC_* /
UIState_DefaultConfig_C?  (Partly decoded as `swi 7` and `.fill`, partly
romslices in v7.)

They are three EVENT-LISTENER BANKS of the SwbtWr dispatcher, each
    table   192 x u32, indexed by event code 0x00..0xBF -> listener list
    0xFF    one separator byte
    lists   u32 callback addresses, each list ended by 0xFFFFFFFF
    post    one more list, called once after the queue drains

THE READERS (audio/dsp_config_sysex.s, v10 addresses)
  SwbtWr_InitBank1/2/3  0xFDB2CB/0xFDB2EA/0xFDB309  store (table, post list,
      queue) at RAM 0xC081 / 0xC085 / 0xC089: bank 1 = (0xEE7786,
      UIState_DefaultConfig_A+4, 0xBD3C), bank 2 = (Naka_RenderMode_A_Table,
      UIState_DefaultConfig_B+4, 0xBD3C), bank 3 = (Naka_EventHandler_Table,
      UIState_DefaultConfig_C+4, 0xC039).
  SwbtWr_DispatchLoop   0xFDB32E  walks the 4-byte queue entries until 0xFF:
      code = byte 0 (-> RAM 0xC080; `cp l,0xbf / jr ugt` skips codes > 0xBF),
      list = table[code] (`sla hl,2` + 32-bit indexed load), wa = bytes 1-2
      (-> 0xC07D), c = byte 3 (-> 0xC07F); every u32 of the list is
      `call (xde)`'d until `cpw (xhl),0xffff` and `cpw (xhl+2),0xffff` both hit.
  SwbtWr_PostCallback_Loop 0xFDB3BC  calls each u32 of the post list until
      0xFFFF.
  Callbacks read the event back from those RAM cells, e.g.
      BitMapOut_ByteData_RenderD (0xFB4168, bank-2 list of code 0x90) starts
      `cp (0xc080),0x90`.

WHAT --probe ASSERTS (per version; any failure exits non-zero)
  1. every list reached from a table entry or a post pointer ends in
     0xFFFFFFFF;
  2. table + separator + lists + trailing pad PARTITION 0xEE7786..0xEE8C7E;
  3. every callback address is inside the ROM's code range (0xE00000-0xFFFFFF);
  4. v9 is byte-identical to v10 over the span; v7 differs only inside
     callback addresses (the layout, tables and list lengths are equal).

RUN
    python3 scripts/generators/gen_swbt_listener_banks.py --probe
    python3 scripts/generators/gen_swbt_listener_banks.py --emit v10 > out.s
    python3 scripts/generators/gen_swbt_listener_banks.py --apply v10 v9 v7
  --apply needs rebuilt_ROMs/kn5000_<v>_program.llvm.elf (for callback
  names) and replaces, in <v>/maincpu/ui_widgets/widget_dispatch.s, the lines
  after the `; 99 PEQ+OVERDR+DELAY` DSP table entry up to
  `SystemConfig_PointerTable:` (latin-1 byte-exact I/O; refuses if that block
  holds a comment).  Then `make gate`.
"""
import argparse
import bisect
import os
import re
import struct
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
B = 0xE00000
SPAN_LO, SPAN_HI = 0xEE7786, 0xEE8C7E
NCODES = 192
# (bank, table, post list, queue) -- from SwbtWr_InitBank1/2/3
BANKS = [(1, 0xEE7786, 0xEE7CA3, 0xBD3C),
         (2, 0xEE7CA7, 0xEE86B4, 0xBD3C),
         (3, 0xEE86D0, 0xEE8C79, 0xC039)]
# names other files reference -- kept at their addresses
KEEP = {0xEE7CA7: "Naka_RenderMode_A_Table",   # audio/dsp_config_sysex.s SwbtWr_InitBank2
        0xEE86D0: "Naka_EventHandler_Table",   # audio/dsp_config_sysex.s SwbtWr_InitBank3
        0xEE7C9F: "UIState_DefaultConfig_A",   # shared/positional_labels.s: +4 = post list
        0xEE86B0: "UIState_DefaultConfig_B",
        0xEE8C75: "UIState_DefaultConfig_C"}
TABLE_NAME = {1: "SwbtBank1_ListenerTable", 2: "Naka_RenderMode_A_Table",
              3: "Naka_EventHandler_Table"}


def rom(v):
    return open(os.path.join(ROOT, "original_ROMs/kn5000_%s_program.rom" % v), "rb").read()


def u32(d, a):
    return struct.unpack_from("<I", d, a - B)[0]


def symbols(v):
    elf = os.path.join(ROOT, "rebuilt_ROMs/kn5000_%s_program.llvm.elf" % v)
    out = subprocess.run([NM, "--defined-only", elf], capture_output=True, text=True, check=True).stdout
    by = {}
    for ln in out.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] in "tT":
            a = int(p[0], 16)
            if SPAN_LO <= a < SPAN_HI:
                continue                    # our own labels: regenerated
            by.setdefault(a, []).append(p[2])
    for a in by:
        by[a].sort(key=lambda n: (n.startswith("."), "_0x" in n, len(n)))
    return by


def analyse(d):
    banks = []
    owner = {}

    def claim(lo, hi, what):
        for a in range(lo, hi):
            assert a not in owner, ("byte claimed twice", hex(a), what, owner[a])
            owner[a] = what
    for b, tab, post, q in BANKS:
        ptrs = [u32(d, tab + 4 * i) for i in range(NCODES)]
        claim(tab, tab + 4 * NCODES, "table%d" % b)
        lists = {}
        for p in sorted(set(ptrs) | {post}):
            a, fns = p, []
            while u32(d, a) != 0xFFFFFFFF:
                f = u32(d, a)
                assert 0xE00000 <= f <= 0xFFFFFF, ("callback outside ROM", b, hex(p), hex(f))
                fns.append(f)
                a += 4
            lists[p] = fns
            claim(p, a + 4, "list%d@%x" % (b, p))
        banks.append((b, tab, post, q, ptrs, lists))
    pads = [a for a in range(SPAN_LO, SPAN_HI) if a not in owner]
    for a in pads:
        assert d[a - B] == 0xFF, ("unexplained non-0xFF byte", hex(a))
    return banks, pads


def probe():
    ds = {v: rom(v) for v in ("v10", "v9", "v7")}
    lay = {}
    for v, d in ds.items():
        banks, pads = analyse(d)
        lay[v] = [(b, tab, post, ptrs, [(p, len(f)) for p, f in sorted(l.items())])
                  for b, tab, post, q, ptrs, l in banks]
        print("%s: 3 banks; lists %s; pad bytes %s" % (
            v, [len(l) for *_, l in banks], [hex(a) for a in pads]))
    assert ds["v9"][SPAN_LO - B:SPAN_HI - B] == ds["v10"][SPAN_LO - B:SPAN_HI - B]
    print("4. v9 == v10 byte-for-byte over 0x%06X..0x%06X" % (SPAN_LO, SPAN_HI))
    assert lay["v7"] == lay["v10"]
    print("4. v7 has the same tables, list addresses and list lengths as v10")
    banks, _ = analyse(ds["v10"])
    for b, tab, post, q, ptrs, lists in banks:
        ne = {p: f for p, f in lists.items() if f}
        print("bank %d table 0x%06X: %d distinct lists, %d non-empty, post list %d callbacks"
              % (b, tab, len(lists), len(ne), len(lists[post])))
    return 0


def list_label(b, p, codes, post):
    if p in KEEP:
        return KEEP[p]
    if p == post:
        return "SwbtBank%d_PostCallbacks" % b
    return "SwbtB%d_Code%02X_Listeners" % (b, codes[0])


POSITIONAL = re.compile(r"_0x[0-9A-Fa-f]+$")


def callback_name(f, syms, alt=None, altsyms=None):
    """Exact label if one exists; else `Nearest + N` (the form the v7 tree
    already used) with a comment saying no label marks this entry yet."""
    if f in syms:
        return syms[f][0], None
    addrs = [a for a in sorted(syms) if any(not POSITIONAL.search(n) for n in syms[a])]
    i = bisect.bisect_right(addrs, f) - 1
    base = next(n for n in syms[addrs[i]] if not POSITIONAL.search(n))
    note = "no label at this callback entry yet"
    if alt is not None and altsyms and alt in altsyms:
        note += "; v10: %s" % altsyms[alt][0]
    return "%s + %d" % (base, f - addrs[i]), note


def emit(v):
    d = rom(v)
    syms = symbols(v)
    banks, pads = analyse(d)
    alt = altsyms = None
    if v != "v10":
        d10 = rom("v10")
        banks10, _ = analyse(d10)
        altsyms = symbols("v10")
        alt = {}
        for (b, tab, post, q, ptrs, lists), (_, _, _, _, _, l10) in zip(banks, banks10):
            for p in lists:
                for f, f10 in zip(lists[p], l10[p]):
                    alt[f] = f10
    padset = set(pads)
    L = []
    w = L.append
    w("; =============================================================================")
    w("; SwbtWr EVENT-LISTENER BANKS  (0xEE7786-0xEE8C7D, 3 banks)")
    w("; =============================================================================")
    w("; Each bank: a 192 x u32 table indexed by event code 0x00..0xBF, one 0xFF")
    w("; separator byte, then the listener lists it points at -- u32 callback")
    w("; addresses ended by 0xFFFFFFFF -- and one post list.")
    w(";")
    w("; Readers (audio/dsp_config_sysex.s):")
    w(";   SwbtWr_InitBank1/2/3 (0xFDB2CB/0xFDB2EA/0xFDB309) store (table, post")
    w(";     list, queue) at RAM 0xC081/0xC085/0xC089:")
    w(";       bank 1  SwbtBank1_ListenerTable  post UIState_DefaultConfig_A+4  queue 0xBD3C")
    w(";       bank 2  Naka_RenderMode_A_Table  post UIState_DefaultConfig_B+4  queue 0xBD3C")
    w(";       bank 3  Naka_EventHandler_Table  post UIState_DefaultConfig_C+4  queue 0xC039")
    w(";   SwbtWr_DispatchLoop (0xFDB32E) walks the queue's 4-byte entries: byte 0")
    w(";     is the code (-> RAM 0xC080; codes > 0xBF are skipped by `cp l,0xbf`),")
    w(";     bytes 1-2 -> RAM 0xC07D, byte 3 -> RAM 0xC07F; list = table[code*4];")
    w(";     each u32 is `call (xde)`'d until both halves read 0xFFFF.")
    w(";   SwbtWr_PostCallback_Loop (0xFDB3BC) then calls every entry of the post")
    w(";     list.  AssswbWr / SwbtWr_QueueMainEvent / SwbtWr fill the queues.")
    w(";   Callbacks read the event back from RAM: BitMapOut_ByteData_RenderD")
    w(";     (bank 2, code 0x90) begins `cp (0xc080),0x90`.")
    w("; Pinned by scripts/generators/gen_swbt_listener_banks.py --probe: every list")
    w("; ends in 0xFFFFFFFF; tables + separators + lists + one trailing 0xFF")
    w("; partition the span; v9 == v10 byte-for-byte; v7 has the same layout with")
    w("; relocated callback addresses.  Lists are named after the lowest event")
    w("; code that selects them.  Open question: what most codes stand for -- only")
    w("; 0x61 and 0x63-0x66 are tied down (DSP blocks, see DspBlock_ObjectCode_Table).")
    w("; The old names UIState_Config{A,B,C}_NNN, UIState_HandlerTable_*,")
    w("; UIState_SeqInit_Table and UIState_EventHandler_Table (a label in the")
    w("; middle of a list) did not match the table index and are retired;")
    w("; UIState_DefaultConfig_A/B/C, Naka_RenderMode_A_Table and")
    w("; Naka_EventHandler_Table are kept because other files load them by name.")
    w("; =============================================================================")
    for b, tab, post, q, ptrs, lists in banks:
        codes = {}
        for k, p in enumerate(ptrs):
            codes.setdefault(p, []).append(k)
        codes.setdefault(post, [])
        tname = TABLE_NAME[b]
        w("")
        w("; ---- bank %d: 192 x u32, entry = event code 0x00..0xBF -> listener list;" % b)
        w(";      installed by SwbtWr_InitBank%d, read by SwbtWr_DispatchLoop (queue 0x%04X)" % (b, q))
        if tname in KEEP.values():
            w("; (name kept: SwbtWr_InitBank%d in audio/dsp_config_sysex.s loads it;" % b)
            w(";  it is SwbtWr bank %d, not the table its name suggests)" % b)
        w("%s:" % tname)
        for k, p in enumerate(ptrs):
            w("\t.long %s\t; 0x%02X" % (list_label(b, p, codes[p], post), k))
        a = tab + 4 * NCODES
        while a in padset:
            w("\t.byte 0xff\t\t\t\t; separator (read by nothing)")
            a += 1
        for p in sorted(lists):
            fns = lists[p]
            lab = list_label(b, p, codes[p], post)
            cs = codes[p]
            if p == post:
                what = ("bank %d post list: SwbtWr_PostCallback_Loop calls each entry"
                        " once the queue drains" % b)
            elif len(cs) > 1:
                what = "codes " + ", ".join("0x%02X" % c for c in cs)
            elif fns:
                what = "code 0x%02X: callbacks SwbtWr_DispatchLoop calls for it" % cs[0]
            else:
                what = None
            if p in KEEP and p != post:
                what = (what + "; " if what else "") + "name kept: its +4 is the post list"
            if not fns:
                w("%s:\t.long 0xffffffff" % lab + ("\t; " + what if what else ""))
            else:
                if what:
                    w("; %s" % what)
                w("%s:" % lab)
                for f in fns:
                    nm, note = callback_name(f, syms, alt.get(f) if alt else None, altsyms)
                    w("\t.long %s" % nm + ("\t; " + note if note else ""))
                w("\t.long 0xffffffff")
            end = p + 4 * len(fns) + 4
            while end in padset:
                w("\t.byte 0xff\t\t\t\t; pad (read by nothing)")
                end += 1
    return "\n".join(L) + "\n"


def apply(v):
    path = os.path.join(ROOT, v, "maincpu/ui_widgets/widget_dispatch.s")
    raw = open(path, "rb").read()
    lines = raw.split(b"\n")
    t = next(i for i, l in enumerate(lines) if l == b"DspFxRecListPtrTable:")
    s = next(i for i in range(t, len(lines)) if lines[i].endswith(b"; 99 PEQ+OVERDR+DELAY")) + 1
    e = next(i for i, l in enumerate(lines) if l == b"SystemConfig_PointerTable:")
    assert e > s
    regen = any(l.startswith(b"; SwbtWr EVENT-LISTENER BANKS") for l in lines[s:e])
    if not regen:             # first application: the old block held no comment
        for l in lines[s:e]:
            assert b";" not in l, ("comment inside replaced block", l)
    new = emit(v).encode("latin-1").split(b"\n")
    out = lines[:s] + new + lines[e:]
    open(path, "wb").write(b"\n".join(out))
    print("%s: replaced lines %d..%d (%d) with %d lines" % (path, s + 1, e, e - s, len(new)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--probe", action="store_true")
    ap.add_argument("--emit")
    ap.add_argument("--apply", nargs="+")
    a = ap.parse_args()
    if a.probe:
        return probe()
    if a.emit:
        sys.stdout.write(emit(a.emit))
        return 0
    if a.apply:
        for v in a.apply:
            apply(v)
        return 0
    ap.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
